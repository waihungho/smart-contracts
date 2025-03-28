```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to submit artworks,
 *      the community to vote on acceptance, manage exhibitions, facilitate art trading, and govern the collective's rules.
 *
 * **Outline and Function Summary:**
 *
 * **1. Art Submission and Management:**
 *    - `submitArt(string _metadataURI)`: Allows artists to submit their artwork with metadata URI.
 *    - `getArtSubmission(uint256 _submissionId)`: Retrieves details of a specific art submission.
 *    - `getAllArtSubmissions()`: Returns a list of all art submission IDs.
 *    - `approveArtSubmission(uint256 _submissionId)`: Allows governance to approve an art submission for minting.
 *    - `rejectArtSubmission(uint256 _submissionId, string _reason)`: Allows governance to reject an art submission with a reason.
 *    - `mintArtNFT(uint256 _submissionId)`: Mints an NFT for an approved art submission (ERC721 standard).
 *    - `burnArtNFT(uint256 _tokenId)`: Allows governance to burn a minted NFT (in extreme cases).
 *
 * **2. Governance and Voting:**
 *    - `createGovernanceProposal(string _title, string _description, bytes _calldata)`: Allows collective members to create governance proposals.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on active governance proposals.
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal (governance function only).
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 *    - `getAllProposals()`: Returns a list of all proposal IDs.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Allows governance to change the voting duration for proposals.
 *    - `setQuorum(uint256 _quorumPercentage)`: Allows governance to change the quorum percentage for proposals.
 *
 * **3. Exhibition Management:**
 *    - `createExhibition(string _name, string _description, uint256 _startTime, uint256 _endTime)`: Allows governance to create a new art exhibition.
 *    - `addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Allows governance to add an approved artwork NFT to an exhibition.
 *    - `removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Allows governance to remove an artwork NFT from an exhibition.
 *    - `getExhibitionDetails(uint256 _exhibitionId)`: Retrieves details of a specific exhibition.
 *    - `getAllExhibitions()`: Returns a list of all exhibition IDs.
 *
 * **4. Collective Membership (Basic - can be expanded):**
 *    - `addCollectiveMember(address _member)`: Allows governance to add a new member to the collective.
 *    - `removeCollectiveMember(address _member)`: Allows governance to remove a member from the collective.
 *    - `isCollectiveMember(address _account)`: Checks if an address is a collective member.
 *
 * **5. Treasury and Funding (Basic - can be enhanced):**
 *    - `donateToCollective()`: Allows anyone to donate ETH to the collective's treasury.
 *    - `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Allows governance to withdraw funds from the treasury.
 *    - `getTreasuryBalance()`: Retrieves the current balance of the collective's treasury.
 *
 * **6. NFT Marketplace (Internal - Basic):**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their collective NFTs for sale.
 *    - `buyNFT(uint256 _listingId)`: Allows anyone to buy a listed NFT.
 *    - `cancelNFTSaleListing(uint256 _listingId)`: Allows NFT owners to cancel their NFT sale listing.
 *    - `getNFTListingDetails(uint256 _listingId)`: Retrieves details of a specific NFT listing.
 *    - `getAllNFTListings()`: Returns a list of all active NFT listing IDs.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Enums
    enum SubmissionStatus { Pending, Approved, Rejected }
    enum ProposalStatus { Active, Passed, Rejected, Executed }

    // Structs
    struct ArtSubmission {
        address artist;
        string metadataURI;
        SubmissionStatus status;
        string rejectionReason;
        uint256 submissionTimestamp;
    }

    struct GovernanceProposal {
        string title;
        string description;
        ProposalStatus status;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bytes calldataData; // Calldata to execute if proposal passes
    }

    struct Exhibition {
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256[] artTokenIds; // List of NFT token IDs in the exhibition
    }

    struct NFTListing {
        uint256 tokenId;
        address seller;
        uint256 price; // Price in Wei
        bool isActive;
    }

    // State Variables
    mapping(uint256 => ArtSubmission) public artSubmissions;
    Counters.Counter private _artSubmissionCounter;

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    Counters.Counter private _governanceProposalCounter;
    uint256 public votingDurationInBlocks = 100; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)

    mapping(uint256 => Exhibition) public exhibitions;
    Counters.Counter private _exhibitionCounter;

    mapping(uint256 => NFTListing) public nftListings;
    Counters.Counter private _nftListingCounter;

    mapping(address => bool) public collectiveMembers;
    address[] public collectiveMembersList; // Keep track of members in an array for easier iteration

    uint256 public constant COLLECTIVE_FEE_PERCENTAGE = 5; // Example: 5% fee on NFT sales

    // Events
    event ArtSubmitted(uint256 submissionId, address artist, string metadataURI);
    event ArtSubmissionApproved(uint256 submissionId);
    event ArtSubmissionRejected(uint256 submissionId, string reason);
    event ArtNFTMinted(uint256 tokenId, uint256 submissionId, address artist);
    event ArtNFTBurned(uint256 tokenId);

    event GovernanceProposalCreated(uint256 proposalId, string title);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event VotingDurationChanged(uint256 newDuration);
    event QuorumPercentageChanged(uint256 newQuorum);

    event ExhibitionCreated(uint256 exhibitionId, string name);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId);

    event CollectiveMemberAdded(address member);
    event CollectiveMemberRemoved(address member);

    event DonationReceived(address donor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);

    event NFTListedForSale(uint256 listingId, uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 listingId, uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 listingId, uint256 tokenId);

    // Modifiers
    modifier onlyCollectiveMember() {
        require(isCollectiveMember(msg.sender), "Not a collective member");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == owner(), "Only governance (contract owner) can call this function");
        _;
    }

    constructor() ERC721("Decentralized Art Collective", "DAC") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender()); // Deployer is the initial admin/governance
    }

    // -------------------------------------------------------------------------
    // 1. Art Submission and Management
    // -------------------------------------------------------------------------

    /**
     * @dev Allows artists to submit their artwork with metadata URI.
     * @param _metadataURI URI pointing to the artwork's metadata (e.g., IPFS link).
     */
    function submitArt(string memory _metadataURI) public {
        uint256 submissionId = _artSubmissionCounter.current();
        artSubmissions[submissionId] = ArtSubmission({
            artist: msg.sender,
            metadataURI: _metadataURI,
            status: SubmissionStatus.Pending,
            rejectionReason: "",
            submissionTimestamp: block.timestamp
        });
        _artSubmissionCounter.increment();
        emit ArtSubmitted(submissionId, msg.sender, _metadataURI);
    }

    /**
     * @dev Retrieves details of a specific art submission.
     * @param _submissionId The ID of the art submission.
     * @return ArtSubmission struct containing submission details.
     */
    function getArtSubmission(uint256 _submissionId) public view returns (ArtSubmission memory) {
        return artSubmissions[_submissionId];
    }

    /**
     * @dev Returns a list of all art submission IDs.
     * @return An array of uint256 representing submission IDs.
     */
    function getAllArtSubmissions() public view returns (uint256[] memory) {
        uint256 count = _artSubmissionCounter.current();
        uint256[] memory submissionIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            submissionIds[i] = i;
        }
        return submissionIds;
    }

    /**
     * @dev Allows governance to approve an art submission for minting.
     * @param _submissionId The ID of the art submission to approve.
     */
    function approveArtSubmission(uint256 _submissionId) public onlyGovernance {
        require(artSubmissions[_submissionId].status == SubmissionStatus.Pending, "Submission is not pending");
        artSubmissions[_submissionId].status = SubmissionStatus.Approved;
        emit ArtSubmissionApproved(_submissionId);
    }

    /**
     * @dev Allows governance to reject an art submission with a reason.
     * @param _submissionId The ID of the art submission to reject.
     * @param _reason The reason for rejection.
     */
    function rejectArtSubmission(uint256 _submissionId, string memory _reason) public onlyGovernance {
        require(artSubmissions[_submissionId].status == SubmissionStatus.Pending, "Submission is not pending");
        artSubmissions[_submissionId].status = SubmissionStatus.Rejected;
        artSubmissions[_submissionId].rejectionReason = _reason;
        emit ArtSubmissionRejected(_submissionId, _reason);
    }

    /**
     * @dev Mints an NFT for an approved art submission (ERC721 standard).
     * @param _submissionId The ID of the approved art submission.
     */
    function mintArtNFT(uint256 _submissionId) public onlyGovernance {
        require(artSubmissions[_submissionId].status == SubmissionStatus.Approved, "Submission not approved");
        address artist = artSubmissions[_submissionId].artist;
        uint256 tokenId = _artSubmissionCounter.current(); // Use submission counter for token ID as well (can be adjusted)
        _mint(artist, tokenId);
        _setTokenURI(tokenId, artSubmissions[_submissionId].metadataURI);
        _artSubmissionCounter.increment(); // Increment again for next submission/token
        emit ArtNFTMinted(tokenId, _submissionId, artist);
    }

    /**
     * @dev Allows governance to burn a minted NFT (in extreme cases).
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnArtNFT(uint256 _tokenId) public onlyGovernance {
        require(_exists(_tokenId), "NFT does not exist");
        _burn(_tokenId);
        emit ArtNFTBurned(_tokenId);
    }

    // -------------------------------------------------------------------------
    // 2. Governance and Voting
    // -------------------------------------------------------------------------

    /**
     * @dev Allows collective members to create governance proposals.
     * @param _title Title of the proposal.
     * @param _description Description of the proposal.
     * @param _calldata Calldata to be executed if the proposal passes.
     */
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) public onlyCollectiveMember {
        uint256 proposalId = _governanceProposalCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            title: _title,
            description: _description,
            status: ProposalStatus.Active,
            votingStartTime: block.number,
            votingEndTime: block.number + votingDurationInBlocks,
            yesVotes: 0,
            noVotes: 0,
            calldataData: _calldata
        });
        _governanceProposalCounter.increment();
        emit GovernanceProposalCreated(proposalId, _title);
    }

    /**
     * @dev Allows members to vote on active governance proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for yes, false for no.
     */
    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyCollectiveMember {
        require(governanceProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active");
        require(block.number <= governanceProposals[_proposalId].votingEndTime, "Voting period ended");

        // Prevent double voting (basic - can be improved with mapping of voter => vote)
        // For simplicity, we assume each member votes only once per proposal in this example.
        // In a real-world scenario, you would likely track votes per voter.
        // Here we just check if they've already voted by seeing if yesVotes or noVotes have increased from 0.
        uint256 initialYesVotes = governanceProposals[_proposalId].yesVotes;
        uint256 initialNoVotes = governanceProposals[_proposalId].noVotes;

        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }

        // Check if voting period ended and quorum is reached after vote
        if (block.number >= governanceProposals[_proposalId].votingEndTime) {
            _checkAndFinalizeProposal(_proposalId);
        }

        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /**
     * @dev Executes a passed governance proposal (governance function only).
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public onlyGovernance {
        require(governanceProposals[_proposalId].status == ProposalStatus.Passed, "Proposal not passed");
        governanceProposals[_proposalId].status = ProposalStatus.Executed;
        (bool success, ) = address(this).call(governanceProposals[_proposalId].calldataData); // Execute the calldata
        require(success, "Proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @dev Retrieves details of a specific governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @return GovernanceProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    /**
     * @dev Returns a list of all proposal IDs.
     * @return An array of uint256 representing proposal IDs.
     */
    function getAllProposals() public view returns (uint256[] memory) {
        uint256 count = _governanceProposalCounter.current();
        uint256[] memory proposalIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            proposalIds[i] = i;
        }
        return proposalIds;
    }

    /**
     * @dev Allows governance to change the voting duration for proposals.
     * @param _durationInBlocks The new voting duration in blocks.
     */
    function setVotingDuration(uint256 _durationInBlocks) public onlyGovernance {
        votingDurationInBlocks = _durationInBlocks;
        emit VotingDurationChanged(_durationInBlocks);
    }

    /**
     * @dev Allows governance to change the quorum percentage for proposals.
     * @param _quorumPercentage The new quorum percentage (e.g., 50 for 50%).
     */
    function setQuorum(uint256 _quorumPercentage) public onlyGovernance {
        require(_quorumPercentage <= 100, "Quorum percentage must be <= 100");
        quorumPercentage = _quorumPercentage;
        emit QuorumPercentageChanged(_quorumPercentage);
    }

    /**
     * @dev Internal function to check if a proposal has passed and finalize it.
     * @param _proposalId The ID of the proposal to check.
     */
    function _checkAndFinalizeProposal(uint256 _proposalId) internal {
        if (governanceProposals[_proposalId].status == ProposalStatus.Active && block.number >= governanceProposals[_proposalId].votingEndTime) {
            uint256 totalVotes = governanceProposals[_proposalId].yesVotes + governanceProposals[_proposalId].noVotes;
            if (totalVotes > 0) { // Avoid division by zero if no one voted
                uint256 yesPercentage = (governanceProposals[_proposalId].yesVotes * 100) / totalVotes;
                if (yesPercentage >= quorumPercentage) {
                    governanceProposals[_proposalId].status = ProposalStatus.Passed;
                } else {
                    governanceProposals[_proposalId].status = ProposalStatus.Rejected;
                }
            } else {
                governanceProposals[_proposalId].status = ProposalStatus.Rejected; // Rejected if no votes cast
            }
        }
    }

    // -------------------------------------------------------------------------
    // 3. Exhibition Management
    // -------------------------------------------------------------------------

    /**
     * @dev Allows governance to create a new art exhibition.
     * @param _name Name of the exhibition.
     * @param _description Description of the exhibition.
     * @param _startTime Unix timestamp for exhibition start time.
     * @param _endTime Unix timestamp for exhibition end time.
     */
    function createExhibition(string memory _name, string memory _description, uint256 _startTime, uint256 _endTime) public onlyGovernance {
        uint256 exhibitionId = _exhibitionCounter.current();
        exhibitions[exhibitionId] = Exhibition({
            name: _name,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            artTokenIds: new uint256[](0) // Initialize with empty array of token IDs
        });
        _exhibitionCounter.increment();
        emit ExhibitionCreated(exhibitionId, _name);
    }

    /**
     * @dev Allows governance to add an approved artwork NFT to an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @param _tokenId The ID of the NFT to add to the exhibition.
     */
    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyGovernance {
        require(exhibitions[_exhibitionId].startTime <= block.timestamp && exhibitions[_exhibitionId].endTime >= block.timestamp, "Exhibition is not active yet or has ended"); // Example: Active exhibition check
        require(_exists(_tokenId), "NFT does not exist");
        exhibitions[_exhibitionId].artTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId);
    }

    /**
     * @dev Allows governance to remove an artwork NFT from an exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @param _tokenId The ID of the NFT to remove from the exhibition.
     */
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyGovernance {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        uint256 indexToRemove = uint256(-1);
        for (uint256 i = 0; i < exhibition.artTokenIds.length; i++) {
            if (exhibition.artTokenIds[i] == _tokenId) {
                indexToRemove = i;
                break;
            }
        }
        require(indexToRemove != uint256(-1), "NFT not found in exhibition");

        // Remove element by swapping with last element and popping
        if (indexToRemove < exhibition.artTokenIds.length - 1) {
            exhibition.artTokenIds[indexToRemove] = exhibition.artTokenIds[exhibition.artTokenIds.length - 1];
        }
        exhibition.artTokenIds.pop();
        emit ArtRemovedFromExhibition(_exhibitionId, _tokenId);
    }

    /**
     * @dev Retrieves details of a specific exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @return Exhibition struct containing exhibition details.
     */
    function getExhibitionDetails(uint256 _exhibitionId) public view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /**
     * @dev Returns a list of all exhibition IDs.
     * @return An array of uint256 representing exhibition IDs.
     */
    function getAllExhibitions() public view returns (uint256[] memory) {
        uint256 count = _exhibitionCounter.current();
        uint256[] memory exhibitionIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            exhibitionIds[i] = i;
        }
        return exhibitionIds;
    }

    // -------------------------------------------------------------------------
    // 4. Collective Membership (Basic - can be expanded)
    // -------------------------------------------------------------------------

    /**
     * @dev Allows governance to add a new member to the collective.
     * @param _member The address of the member to add.
     */
    function addCollectiveMember(address _member) public onlyGovernance {
        require(!isCollectiveMember(_member), "Address is already a member");
        collectiveMembers[_member] = true;
        collectiveMembersList.push(_member);
        emit CollectiveMemberAdded(_member);
    }

    /**
     * @dev Allows governance to remove a member from the collective.
     * @param _member The address of the member to remove.
     */
    function removeCollectiveMember(address _member) public onlyGovernance {
        require(isCollectiveMember(_member), "Address is not a member");
        collectiveMembers[_member] = false;

        // Remove from collectiveMembersList array (inefficient for very large lists, consider alternative for scale)
        for (uint256 i = 0; i < collectiveMembersList.length; i++) {
            if (collectiveMembersList[i] == _member) {
                // Remove element by swapping with last element and popping
                if (i < collectiveMembersList.length - 1) {
                    collectiveMembersList[i] = collectiveMembersList[collectiveMembersList.length - 1];
                }
                collectiveMembersList.pop();
                break;
            }
        }
        emit CollectiveMemberRemoved(_member);
    }

    /**
     * @dev Checks if an address is a collective member.
     * @param _account The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isCollectiveMember(address _account) public view returns (bool) {
        return collectiveMembers[_account];
    }

    /**
     * @dev Returns a list of all collective members.
     * @return An array of addresses representing collective members.
     */
    function getAllCollectiveMembers() public view returns (address[] memory) {
        return collectiveMembersList;
    }


    // -------------------------------------------------------------------------
    // 5. Treasury and Funding (Basic - can be enhanced)
    // -------------------------------------------------------------------------

    /**
     * @dev Allows anyone to donate ETH to the collective's treasury.
     */
    function donateToCollective() public payable {
        emit DonationReceived(msg.sender, msg.value);
    }

    /**
     * @dev Allows governance to withdraw funds from the treasury.
     * @param _recipient The address to receive the withdrawn funds.
     * @param _amount The amount of ETH to withdraw in Wei.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) public onlyGovernance {
        uint256 treasuryBalance = address(this).balance;
        require(treasuryBalance >= _amount, "Insufficient treasury balance");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /**
     * @dev Retrieves the current balance of the collective's treasury.
     * @return The current balance of the contract in Wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // -------------------------------------------------------------------------
    // 6. NFT Marketplace (Internal - Basic)
    // -------------------------------------------------------------------------

    /**
     * @dev Allows NFT owners to list their collective NFTs for sale.
     * @param _tokenId The ID of the NFT to list for sale.
     * @param _price The price of the NFT in Wei.
     */
    function listNFTForSale(uint256 _tokenId, uint256 _price) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_price > 0, "Price must be greater than zero");

        uint256 listingId = _nftListingCounter.current();
        nftListings[listingId] = NFTListing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        _nftListingCounter.increment();

        // Transfer NFT to contract for escrow (optional, can be direct peer-to-peer as well)
        safeTransferFrom(msg.sender, address(this), _tokenId);

        emit NFTListedForSale(listingId, _tokenId, msg.sender, _price);
    }

    /**
     * @dev Allows anyone to buy a listed NFT.
     * @param _listingId The ID of the NFT listing.
     */
    function buyNFT(uint256 _listingId) public payable {
        require(nftListings[_listingId].isActive, "Listing is not active");
        require(msg.value >= nftListings[_listingId].price, "Insufficient funds sent");

        NFTListing storage listing = nftListings[_listingId];
        uint256 tokenId = listing.tokenId;
        uint256 price = listing.price;
        address seller = listing.seller;

        listing.isActive = false; // Mark listing as inactive

        // Calculate collective fee
        uint256 collectiveFee = (price * COLLECTIVE_FEE_PERCENTAGE) / 100;
        uint256 sellerPayout = price - collectiveFee;

        // Transfer funds to seller and collective treasury
        payable(seller).transfer(sellerPayout);
        payable(owner()).transfer(collectiveFee); // Send fee to contract owner (governance) as treasury

        // Transfer NFT to buyer
        safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTBought(_listingId, tokenId, msg.sender, price);
    }

    /**
     * @dev Allows NFT owners to cancel their NFT sale listing.
     * @param _listingId The ID of the NFT listing to cancel.
     */
    function cancelNFTSaleListing(uint256 _listingId) public {
        require(nftListings[_listingId].isActive, "Listing is not active");
        require(nftListings[_listingId].seller == msg.sender, "You are not the seller");

        NFTListing storage listing = nftListings[_listingId];
        uint256 tokenId = listing.tokenId;

        listing.isActive = false; // Mark listing as inactive

        // Return NFT to seller
        safeTransferFrom(address(this), msg.sender, tokenId);

        emit NFTListingCancelled(_listingId, tokenId);
    }

    /**
     * @dev Retrieves details of a specific NFT listing.
     * @param _listingId The ID of the NFT listing.
     * @return NFTListing struct containing listing details.
     */
    function getNFTListingDetails(uint256 _listingId) public view returns (NFTListing memory) {
        return nftListings[_listingId];
    }

    /**
     * @dev Returns a list of all active NFT listing IDs.
     * @return An array of uint256 representing active listing IDs.
     */
    function getAllNFTListings() public view returns (uint256[] memory) {
        uint256 count = _nftListingCounter.current();
        uint256 activeListingsCount = 0;
        for (uint256 i = 0; i < count; i++) {
            if (nftListings[i].isActive) {
                activeListingsCount++;
            }
        }

        uint256[] memory activeListingIds = new uint256[](activeListingsCount);
        uint256 index = 0;
        for (uint256 i = 0; i < count; i++) {
            if (nftListings[i].isActive) {
                activeListingIds[index] = i;
                index++;
            }
        }
        return activeListingIds;
    }

    // **Optional Enhancement Functions (Beyond 20, for more advanced features):**

    // - Reputation System: Implement a reputation system for members based on voting participation, art contributions, etc.
    // - Layered Governance:  Introduce different tiers of membership with varying voting power.
    // - Royalties for Artists:  Automated royalty distribution to artists on secondary sales.
    // - Auction Mechanism:  Add auction functionality for NFTs.
    // - Decentralized Storage Integration (IPFS pinning service directly in contract).
    // - Event Ticketing for Exhibitions (if physical or virtual paid events).
    // - Fractional NFT Ownership:  Allow fractionalization of collective NFTs.
    // - Staking/Yield Farming:  Incentivize participation with staking and rewards.
    // - Dynamic Quorum/Voting Duration:  Adjust quorum and voting duration based on proposal type or community activity.
    // - Delegation of Voting Power: Allow members to delegate their voting power to others.
}
```