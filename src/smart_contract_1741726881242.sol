```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a decentralized autonomous art gallery.
 * It allows artists to submit art (represented by NFTs from external contracts),
 * curators to vote on submissions, users to support artists and the gallery,
 * and implements a basic governance mechanism for gallery parameters.
 *
 * **Outline:**
 *
 * **1. Gallery Management:**
 *    - `initializeGallery(string _galleryName, string _galleryDescription)`: Initializes the gallery with name and description (only once).
 *    - `setGalleryOwner(address _newOwner)`:  Sets a new gallery owner (only by current owner).
 *    - `setCuratorFee(uint256 _newFeePercentage)`: Sets the percentage of sales going to curators (owner only).
 *    - `setGallerySupportFee(uint256 _newFeePercentage)`: Sets the percentage of sales going to gallery support (owner only).
 *    - `setVotingDuration(uint256 _newDuration)`: Sets the duration of voting periods for art submissions (owner only).
 *
 * **2. Artist Management:**
 *    - `registerArtist()`: Allows users to register as artists.
 *    - `submitArt(address _nftContractAddress, uint256 _tokenId, string _metadataURI)`: Artists submit their NFT art pieces for gallery consideration.
 *    - `withdrawArtistEarnings()`: Artists can withdraw their accumulated earnings.
 *
 * **3. Curator Management:**
 *    - `applyToBeCurator(string _applicationDetails)`: Users can apply to become curators.
 *    - `approveCuratorApplication(address _applicant)`: Gallery owner approves curator applications.
 *    - `revokeCuratorStatus(address _curator)`: Gallery owner revokes curator status.
 *    - `voteOnArtSubmission(uint256 _submissionId, bool _vote)`: Curators vote on art submissions.
 *    - `withdrawCuratorEarnings()`: Curators can withdraw their accumulated earnings.
 *
 * **4. Art Interaction & Support:**
 *    - `viewArtSubmission(uint256 _submissionId)`: View details of an art submission.
 *    - `supportArtist(uint256 _submissionId)`: Users can support an artist (and the gallery) for a submitted artwork.
 *    - `purchaseArtSupportToken(uint256 _submissionId)`: Users can purchase a special "support token" for a submitted artwork, directly supporting the artist and gallery.
 *    - `redeemArtSupportToken(uint256 _submissionId)`: Users can redeem their support tokens for potential future benefits (e.g., discounts, early access - concept).
 *
 * **5. Governance (Basic):**
 *    - `proposeGalleryParameterChange(string _parameterName, string _newValue)`: Curators can propose changes to gallery parameters.
 *    - `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: Curators vote on parameter change proposals.
 *
 * **6. Utility & View Functions:**
 *    - `getGalleryName()`: Returns the gallery name.
 *    - `getGalleryDescription()`: Returns the gallery description.
 *    - `isArtist(address _address)`: Checks if an address is a registered artist.
 *    - `isCurator(address _address)`: Checks if an address is a registered curator.
 *    - `getSubmissionStatus(uint256 _submissionId)`: Returns the status of an art submission.
 *    - `getArtistEarnings(address _artist)`: Returns the earnings of an artist.
 *    - `getCuratorEarnings(address _curator)`: Returns the earnings of a curator.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtGallery is Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Gallery Metadata
    string public galleryName;
    string public galleryDescription;

    // Fees (in percentage, e.g., 100 = 1%)
    uint256 public curatorFeePercentage = 500; // Default 5%
    uint256 public gallerySupportFeePercentage = 1000; // Default 10%

    // Voting Duration (in seconds)
    uint256 public votingDuration = 7 days;

    // Artist Management
    mapping(address => bool) public isRegisteredArtist;
    mapping(address => uint256) public artistEarnings;

    // Curator Management
    mapping(address => bool) public isRegisteredCurator;
    mapping(address => bool) public isCuratorApplicant;
    mapping(address => string) public curatorApplications;
    mapping(address => uint256) public curatorEarnings;
    address[] public curators; // List of curators for iteration

    // Art Submission Management
    struct ArtSubmission {
        uint256 submissionId;
        address artistAddress;
        address nftContractAddress;
        uint256 tokenId;
        string metadataURI;
        SubmissionStatus status;
        uint256 submissionTimestamp;
        uint256 votingEndTime;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) curatorVotes; // To prevent double voting
        uint256 supportTokenPrice; // Price to support this artwork
        uint256 supportTokenSupply; // Supply of support tokens for this artwork
    }

    enum SubmissionStatus {
        Pending,
        Voting,
        Approved,
        Rejected,
        Listed // Approved and listed for support/purchase
    }

    mapping(uint256 => ArtSubmission) public artSubmissions;
    Counters.Counter private _submissionCounter;
    uint256 public supportTokenBasePrice = 0.01 ether; // Base price for support tokens

    // Governance Proposals
    struct ParameterChangeProposal {
        uint256 proposalId;
        string parameterName;
        string newValue;
        uint256 proposalTimestamp;
        uint256 votingEndTime;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) curatorVotes;
        bool executed;
    }
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    Counters.Counter private _proposalCounter;

    // Events
    event GalleryInitialized(string galleryName, string galleryDescription, address owner);
    event GalleryOwnerChanged(address newOwner, address previousOwner);
    event CuratorFeePercentageChanged(uint256 newPercentage);
    event GallerySupportFeePercentageChanged(uint256 newPercentage);
    event VotingDurationChanged(uint256 newDuration);

    event ArtistRegistered(address artistAddress);
    event ArtSubmitted(uint256 submissionId, address artistAddress, address nftContractAddress, uint256 tokenId);
    event ArtistEarningsWithdrawn(address artistAddress, uint256 amount);

    event CuratorApplicationSubmitted(address applicantAddress, string applicationDetails);
    event CuratorApplicationApproved(address curatorAddress);
    event CuratorStatusRevoked(address curatorAddress);
    event CuratorVotedOnArt(uint256 submissionId, address curatorAddress, bool vote);
    event CuratorEarningsWithdrawn(address curatorAddress, uint256 amount);

    event ArtSubmissionStatusUpdated(uint256 submissionId, SubmissionStatus newStatus);
    event ArtSupported(uint256 submissionId, address supporterAddress, uint256 amount);
    event ArtSupportTokenPurchased(uint256 submissionId, address purchaserAddress, uint256 amount);
    event ArtSupportTokenRedeemed(uint256 submissionId, address redeemerAddress);

    event ParameterChangeProposed(uint256 proposalId, string parameterName, string newValue);
    event ParameterChangeProposalVoted(uint256 proposalId, address curatorAddress, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, string newValue);


    // Modifiers
    modifier onlyGalleryOwner() {
        require(msg.sender == owner(), "Only gallery owner can perform this action.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(isRegisteredArtist[msg.sender], "Only registered artists can perform this action.");
        _;
    }

    modifier onlyRegisteredCurator() {
        require(isRegisteredCurator[msg.sender], "Only registered curators can perform this action.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= _submissionCounter.current(), "Invalid submission ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalCounter.current(), "Invalid proposal ID.");
        _;
    }

    // ------------------------ Gallery Management Functions ------------------------

    /**
     * @dev Initializes the gallery with a name and description. Can only be called once.
     * @param _galleryName The name of the art gallery.
     * @param _galleryDescription A brief description of the art gallery.
     */
    function initializeGallery(string memory _galleryName, string memory _galleryDescription) public onlyOwner {
        require(bytes(galleryName).length == 0, "Gallery already initialized.");
        galleryName = _galleryName;
        galleryDescription = _galleryDescription;
        emit GalleryInitialized(_galleryName, _galleryDescription, owner());
    }

    /**
     * @dev Sets a new gallery owner. Only callable by the current owner.
     * @param _newOwner The address of the new gallery owner.
     */
    function setGalleryOwner(address _newOwner) public onlyOwner {
        address previousOwner = owner();
        transferOwnership(_newOwner);
        emit GalleryOwnerChanged(_newOwner, previousOwner);
    }

    /**
     * @dev Sets the percentage of sales revenue that goes to curators. Only callable by the gallery owner.
     * @param _newFeePercentage The new curator fee percentage (e.g., 500 for 5%).
     */
    function setCuratorFee(uint256 _newFeePercentage) public onlyOwner {
        curatorFeePercentage = _newFeePercentage;
        emit CuratorFeePercentageChanged(_newFeePercentage);
    }

    /**
     * @dev Sets the percentage of sales revenue that goes to gallery support. Only callable by the gallery owner.
     * @param _newFeePercentage The new gallery support fee percentage (e.g., 1000 for 10%).
     */
    function setGallerySupportFee(uint256 _newFeePercentage) public onlyOwner {
        gallerySupportFeePercentage = _newFeePercentage;
        emit GallerySupportFeePercentageChanged(_newFeePercentage);
    }

    /**
     * @dev Sets the duration of the voting period for art submissions. Only callable by the gallery owner.
     * @param _newDuration The new voting duration in seconds.
     */
    function setVotingDuration(uint256 _newDuration) public onlyOwner {
        votingDuration = _newDuration;
        emit VotingDurationChanged(_newDuration);
    }

    // ------------------------ Artist Management Functions ------------------------

    /**
     * @dev Allows a user to register as an artist in the gallery.
     */
    function registerArtist() public {
        require(!isRegisteredArtist[msg.sender], "Already registered as an artist.");
        isRegisteredArtist[msg.sender] = true;
        emit ArtistRegistered(msg.sender);
    }

    /**
     * @dev Allows a registered artist to submit their art to the gallery for consideration.
     * Art is represented by an NFT from an external contract.
     * @param _nftContractAddress The address of the NFT contract.
     * @param _tokenId The token ID of the NFT.
     * @param _metadataURI URI pointing to the metadata of the artwork.
     */
    function submitArt(address _nftContractAddress, uint256 _tokenId, string memory _metadataURI) public onlyRegisteredArtist {
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "Artist is not the owner of the NFT.");

        _submissionCounter.increment();
        uint256 submissionId = _submissionCounter.current();

        artSubmissions[submissionId] = ArtSubmission({
            submissionId: submissionId,
            artistAddress: msg.sender,
            nftContractAddress: _nftContractAddress,
            tokenId: _tokenId,
            metadataURI: _metadataURI,
            status: SubmissionStatus.Pending,
            submissionTimestamp: block.timestamp,
            votingEndTime: 0,
            upvotes: 0,
            downvotes: 0,
            supportTokenPrice: supportTokenBasePrice,
            supportTokenSupply: 100 // Initial supply of support tokens, can be adjusted
        });

        emit ArtSubmitted(submissionId, msg.sender, _nftContractAddress, _tokenId);
    }

    /**
     * @dev Allows artists to withdraw their accumulated earnings from art support.
     */
    function withdrawArtistEarnings() public onlyRegisteredArtist {
        uint256 amount = artistEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw.");
        artistEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit ArtistEarningsWithdrawn(msg.sender, amount);
    }

    // ------------------------ Curator Management Functions ------------------------

    /**
     * @dev Allows users to apply to become curators.
     * @param _applicationDetails Details about why the user wants to be a curator.
     */
    function applyToBeCurator(string memory _applicationDetails) public {
        require(!isRegisteredCurator[msg.sender], "Already a curator.");
        require(!isCuratorApplicant[msg.sender], "Already applied to be a curator.");
        isCuratorApplicant[msg.sender] = true;
        curatorApplications[msg.sender] = _applicationDetails;
        emit CuratorApplicationSubmitted(msg.sender, _applicationDetails);
    }

    /**
     * @dev Gallery owner approves a curator application.
     * @param _applicant The address of the applicant to be approved as a curator.
     */
    function approveCuratorApplication(address _applicant) public onlyGalleryOwner {
        require(isCuratorApplicant[_applicant], "Applicant has not applied or is already a curator.");
        require(!isRegisteredCurator[_applicant], "Applicant is already a curator.");
        isRegisteredCurator[_applicant] = true;
        isCuratorApplicant[_applicant] = false;
        delete curatorApplications[_applicant];
        curators.push(_applicant); // Add to curator list
        emit CuratorApplicationApproved(_applicant);
    }

    /**
     * @dev Gallery owner revokes curator status from a curator.
     * @param _curator The address of the curator to revoke status from.
     */
    function revokeCuratorStatus(address _curator) public onlyGalleryOwner {
        require(isRegisteredCurator[_curator], "Address is not a curator.");
        isRegisteredCurator[_curator] = false;
        // Remove from curator list (inefficient, but curators list is expected to be small)
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _curator) {
                curators[i] = curators[curators.length - 1];
                curators.pop();
                break;
            }
        }
        emit CuratorStatusRevoked(_curator);
    }

    /**
     * @dev Curators can vote on art submissions. Voting is for approval or rejection.
     * @param _submissionId The ID of the art submission.
     * @param _vote 'true' for approval, 'false' for rejection.
     */
    function voteOnArtSubmission(uint256 _submissionId, bool _vote) public onlyRegisteredCurator validSubmissionId(_submissionId) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Voting || submission.status == SubmissionStatus.Pending, "Voting is not active for this submission.");
        require(!submission.curatorVotes[msg.sender], "Curator has already voted.");

        submission.curatorVotes[msg.sender] = true;
        if (_vote) {
            submission.upvotes++;
        } else {
            submission.downvotes++;
        }
        emit CuratorVotedOnArt(_submissionId, msg.sender, _vote);

        // Check if voting period just started and set end time if pending
        if (submission.status == SubmissionStatus.Pending) {
            submission.status = SubmissionStatus.Voting;
            submission.votingEndTime = block.timestamp + votingDuration;
            emit ArtSubmissionStatusUpdated(_submissionId, SubmissionStatus.Voting);
        }

        // Check if voting period ended or quorum reached (basic example, can be improved)
        if (block.timestamp >= submission.votingEndTime || (submission.upvotes + submission.downvotes) >= curators.length) {
            _finalizeArtSubmissionVote(_submissionId);
        }
    }

    /**
     * @dev Allows curators to withdraw their accumulated earnings from gallery support contributions.
     */
    function withdrawCuratorEarnings() public onlyRegisteredCurator {
        uint256 amount = curatorEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw.");
        curatorEarnings[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit CuratorEarningsWithdrawn(msg.sender, amount);
    }


    // ------------------------ Art Interaction & Support Functions ------------------------

    /**
     * @dev Allows anyone to view the details of an art submission.
     * @param _submissionId The ID of the art submission.
     * @return ArtSubmission struct containing the submission details.
     */
    function viewArtSubmission(uint256 _submissionId) public view validSubmissionId(_submissionId) returns (ArtSubmission memory) {
        return artSubmissions[_submissionId];
    }

    /**
     * @dev Allows users to support an artist and the gallery by sending ETH for a submitted artwork.
     * @param _submissionId The ID of the art submission being supported.
     */
    function supportArtist(uint256 _submissionId) public payable validSubmissionId(_submissionId) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Listed, "Art submission is not currently listed for support.");
        require(msg.value > 0, "Support amount must be greater than zero.");

        uint256 curatorCut = (msg.value * curatorFeePercentage) / 10000;
        uint256 gallerySupportCut = (msg.value * gallerySupportFeePercentage) / 10000;
        uint256 artistCut = msg.value - curatorCut - gallerySupportCut;

        artistEarnings[submission.artistAddress] += artistCut;
        for (uint256 i = 0; i < curators.length; i++) {
            curatorEarnings[curators[i]] += (curatorCut / curators.length); // Distribute curator cut evenly
        }
        payable(owner()).transfer(gallerySupportCut); // Gallery support goes to owner

        emit ArtSupported(_submissionId, msg.sender, msg.value);
    }

    /**
     * @dev Allows users to purchase a special "support token" for a submitted artwork.
     * This is a conceptual feature - support tokens could be used for future gallery features.
     * @param _submissionId The ID of the art submission.
     */
    function purchaseArtSupportToken(uint256 _submissionId) public payable validSubmissionId(_submissionId) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == SubmissionStatus.Listed, "Art submission is not currently listed for support tokens.");
        require(msg.value >= submission.supportTokenPrice, "Insufficient payment for support token.");
        require(submission.supportTokenSupply > 0, "Support tokens are sold out for this artwork.");

        uint256 curatorCut = (submission.supportTokenPrice * curatorFeePercentage) / 10000;
        uint256 gallerySupportCut = (submission.supportTokenPrice * gallerySupportFeePercentage) / 10000;
        uint256 artistCut = submission.supportTokenPrice - curatorCut - gallerySupportCut;

        artistEarnings[submission.artistAddress] += artistCut;
        for (uint256 i = 0; i < curators.length; i++) {
            curatorEarnings[curators[i]] += (curatorCut / curators.length); // Distribute curator cut evenly
        }
        payable(owner()).transfer(gallerySupportCut); // Gallery support goes to owner

        submission.supportTokenSupply--; // Decrease supply
        emit ArtSupportTokenPurchased(_submissionId, msg.sender, submission.supportTokenPrice);

        // (Optional) Here you could implement logic to transfer a custom token to the purchaser.
        // For simplicity, this example only tracks the purchase.
    }

    /**
     * @dev Allows users to redeem their purchased support tokens.
     * This is a conceptual function - redemption logic would need to be defined based on gallery features.
     * @param _submissionId The ID of the art submission.
     */
    function redeemArtSupportToken(uint256 _submissionId) public validSubmissionId(_submissionId) {
        // (Conceptual) Implement redemption logic here.
        // For example, check if the user owns a support token (if you implemented token transfer in purchaseArtSupportToken)
        // and provide some benefit (discount, early access, etc.).
        emit ArtSupportTokenRedeemed(_submissionId, msg.sender);
        // For this example, it just emits an event.
    }

    // ------------------------ Governance (Basic) Functions ------------------------

    /**
     * @dev Allows curators to propose changes to gallery parameters (e.g., fees, voting duration).
     * @param _parameterName The name of the parameter to change.
     * @param _newValue The new value for the parameter (as a string).
     */
    function proposeGalleryParameterChange(string memory _parameterName, string memory _newValue) public onlyRegisteredCurator {
        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();

        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingDuration,
            upvotes: 0,
            downvotes: 0,
            executed: false
        });

        emit ParameterChangeProposed(proposalId, _parameterName, _newValue);
    }

    /**
     * @dev Curators vote on parameter change proposals.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _vote 'true' for approval, 'false' for rejection.
     */
    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) public onlyRegisteredCurator validProposalId(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended.");
        require(!proposal.curatorVotes[msg.sender], "Curator has already voted.");

        proposal.curatorVotes[msg.sender] = true;
        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended or quorum reached (basic example)
        if (block.timestamp >= proposal.votingEndTime || (proposal.upvotes + proposal.downvotes) >= curators.length) {
            _executeParameterChangeProposal(_proposalId);
        }
    }

    // ------------------------ Utility & View Functions ------------------------

    /**
     * @dev Returns the name of the gallery.
     * @return The gallery name string.
     */
    function getGalleryName() public view returns (string memory) {
        return galleryName;
    }

    /**
     * @dev Returns the description of the gallery.
     * @return The gallery description string.
     */
    function getGalleryDescription() public view returns (string memory) {
        return galleryDescription;
    }

    /**
     * @dev Checks if an address is a registered artist.
     * @param _address The address to check.
     * @return True if the address is a registered artist, false otherwise.
     */
    function isArtist(address _address) public view returns (bool) {
        return isRegisteredArtist[_address];
    }

    /**
     * @dev Checks if an address is a registered curator.
     * @param _address The address to check.
     * @return True if the address is a registered curator, false otherwise.
     */
    function isCurator(address _address) public view returns (bool) {
        return isRegisteredCurator[_address];
    }

    /**
     * @dev Gets the status of an art submission.
     * @param _submissionId The ID of the art submission.
     * @return The SubmissionStatus enum value.
     */
    function getSubmissionStatus(uint256 _submissionId) public view validSubmissionId(_submissionId) returns (SubmissionStatus) {
        return artSubmissions[_submissionId].status;
    }

    /**
     * @dev Gets the current earnings of an artist.
     * @param _artist The address of the artist.
     * @return The artist's earnings in wei.
     */
    function getArtistEarnings(address _artist) public view onlyRegisteredArtist returns (uint256) {
        return artistEarnings[_artist];
    }

    /**
     * @dev Gets the current earnings of a curator.
     * @param _curator The address of the curator.
     * @return The curator's earnings in wei.
     */
    function getCuratorEarnings(address _curator) public view onlyRegisteredCurator returns (uint256) {
        return curatorEarnings[_curator];
    }

    // ------------------------ Internal Functions ------------------------

    /**
     * @dev Internal function to finalize the voting process for an art submission and update its status.
     * @param _submissionId The ID of the art submission.
     */
    function _finalizeArtSubmissionVote(uint256 _submissionId) internal {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        if (submission.status != SubmissionStatus.Voting) return; // Avoid re-execution if already finalized

        if (submission.upvotes > submission.downvotes) {
            submission.status = SubmissionStatus.Approved;
        } else {
            submission.status = SubmissionStatus.Rejected;
        }
        emit ArtSubmissionStatusUpdated(_submissionId, submission.status);

        if (submission.status == SubmissionStatus.Approved) {
            submission.status = SubmissionStatus.Listed; // Move to listed status after approval
            emit ArtSubmissionStatusUpdated(_submissionId, SubmissionStatus.Listed);
        }
    }

    /**
     * @dev Internal function to execute a parameter change proposal if approved.
     * @param _proposalId The ID of the parameter change proposal.
     */
    function _executeParameterChangeProposal(uint256 _proposalId) internal {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        if (proposal.executed || block.timestamp < proposal.votingEndTime) return; // Avoid re-execution or execution before voting ends

        proposal.executed = true;
        if (proposal.upvotes > proposal.downvotes) {
            if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("curatorFeePercentage"))) {
                curatorFeePercentage = Strings.parseInt(proposal.newValue);
                emit CuratorFeePercentageChanged(curatorFeePercentage);
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("gallerySupportFeePercentage"))) {
                gallerySupportFeePercentage = Strings.parseInt(proposal.newValue);
                emit GallerySupportFeePercentageChanged(gallerySupportFeePercentage);
            } else if (keccak256(bytes(proposal.parameterName)) == keccak256(bytes("votingDuration"))) {
                votingDuration = Strings.parseInt(proposal.newValue);
                emit VotingDurationChanged(votingDuration);
            }
            // Add more parameter changes here as needed

            emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue);
        } else {
            emit ParameterChangeExecuted(_proposalId, proposal.parameterName, "Rejected"); // Indicate rejection
        }
    }
}
```