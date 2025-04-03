```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery.
 *
 * **Outline & Function Summary:**
 *
 * **I. Gallery Management & Governance:**
 *   1. `constructor(string _galleryName, address _governanceToken)`: Initializes the gallery with a name and governance token address.
 *   2. `setGalleryName(string _newName)`: Allows governance to change the gallery name.
 *   3. `setCurator(address _curator, bool _isActive)`: Allows governance to add/remove curators.
 *   4. `proposeParameterChange(string _parameterName, uint256 _newValue)`:  Allows governance token holders to propose changes to gallery parameters (e.g., curation fee, commission rate).
 *   5. `voteOnParameterChange(uint256 _proposalId, bool _support)`: Allows governance token holders to vote on parameter change proposals.
 *   6. `executeParameterChange(uint256 _proposalId)`: Executes a passed parameter change proposal after voting period.
 *   7. `emergencyShutdown()`: Allows governance to temporarily halt core functionalities in case of critical issues.
 *   8. `recoverERC20(address _tokenAddress, address _recipient, uint256 _amount)`: Allows governance to recover accidentally sent ERC20 tokens.
 *   9. `getGalleryInfo()`: Returns basic gallery information (name, governance token, etc.).
 *
 * **II. Art Submission & Curation:**
 *   10. `submitArt(address _nftContract, uint256 _tokenId, string _metadataURI)`: Allows anyone to submit an NFT for gallery consideration.
 *   11. `curateArt(uint256 _submissionId, bool _isApproved)`: Allows curators to approve or reject submitted art.
 *   12. `getCurationStatus(uint256 _submissionId)`: Returns the curation status of a submission.
 *   13. `getApprovedArt()`: Returns a list of IDs of currently approved artworks in the gallery.
 *
 * **III. Exhibition Management:**
 *   14. `createExhibition(string _exhibitionName, uint256 _startTime, uint256 _endTime)`: Allows curators to create a new exhibition.
 *   15. `addArtToExhibition(uint256 _exhibitionId, uint256 _artId)`: Allows curators to add approved art to an exhibition.
 *   16. `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId)`: Allows curators to remove art from an exhibition.
 *   17. `getExhibitionDetails(uint256 _exhibitionId)`: Returns details of a specific exhibition.
 *   18. `getActiveExhibitions()`: Returns a list of IDs of currently active exhibitions.
 *
 * **IV.  Art Interaction & Features:**
 *   19. `likeArt(uint256 _artId)`: Allows users to "like" an artwork (on-chain social interaction).
 *   20. `getArtLikes(uint256 _artId)`: Returns the like count for a specific artwork.
 *   21. `sponsorArt(uint256 _artId) payable`: Allows users to sponsor an artwork, sending funds to the gallery (potentially for artist rewards or gallery maintenance).
 *   22. `getArtSponsorshipBalance(uint256 _artId)`: Returns the total sponsorship balance for a specific artwork.
 *   23. `withdrawArtSponsorship(uint256 _artId)`: Allows governance to withdraw sponsorship funds for a specific artwork (governance decides how to distribute these funds).
 *   24. `reportArt(uint256 _artId, string _reportReason)`: Allows users to report potentially inappropriate or problematic art for curator review.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousArtGallery {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // -------- Structs & Enums --------

    enum CurationStatus { Pending, Approved, Rejected }
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }

    struct ArtSubmission {
        address submitter;
        address nftContract;
        uint256 tokenId;
        string metadataURI;
        CurationStatus status;
        uint256 submissionTime;
    }

    struct Exhibition {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256[] artIds;
        bool isActive;
    }

    struct ParameterChangeProposal {
        string parameterName;
        uint256 newValue;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
    }


    // -------- State Variables --------

    string public galleryName;
    address public governanceTokenAddress;
    address public governanceAdmin; // Address that can perform admin governance functions

    mapping(address => bool) public isCurator;
    bool public galleryActive = true; // Emergency shutdown toggle

    Counters.Counter private _submissionCounter;
    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => uint256) public artLikes;
    mapping(uint256 => uint256) public artSponsorshipBalance;
    mapping(uint256 => string) public artReports; // For storing reports, could be expanded

    Counters.Counter private _exhibitionCounter;
    mapping(uint256 => Exhibition) public exhibitions;

    Counters.Counter private _proposalCounter;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    uint256 public proposalVoteDuration = 7 days; // Default vote duration, governable parameter
    uint256 public parameterChangeQuorum = 50; // Percentage of governance tokens needed for quorum, governable parameter


    // -------- Events --------

    event GalleryNameChanged(string newName, address indexed changedBy);
    event CuratorUpdated(address indexed curator, bool isActive, address indexed updatedBy);
    event ArtSubmitted(uint256 submissionId, address submitter, address nftContract, uint256 tokenId);
    event ArtCurated(uint256 submissionId, uint256 artId, CurationStatus status, address indexed curator);
    event ArtLiked(uint256 artId, address indexed liker);
    event ArtSponsored(uint256 artId, address indexed sponsor, uint256 amount);
    event ArtReported(uint256 artId, address indexed reporter, string reason);
    event ExhibitionCreated(uint256 exhibitionId, string name, uint256 startTime, uint256 endTime);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId, address indexed curator);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artId, address indexed curator);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterVoteCast(uint256 proposalId, address voter, bool support);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue, address executor);
    event EmergencyShutdownTriggered(address admin);
    event EmergencyShutdownLifted(address admin);
    event ERC20Recovered(address tokenAddress, address recipient, uint256 amount, address recoveredBy);


    // -------- Modifiers --------

    modifier onlyCurator() {
        require(galleryActive, "Gallery is currently inactive.");
        require(isCurator[msg.sender], "Only curators can perform this action.");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAdmin, "Only governance admin can perform this action.");
        _;
    }

    modifier galleryIsActive() {
        require(galleryActive, "Gallery is currently inactive.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= _submissionCounter.current(), "Invalid submission ID.");
        _;
    }

    modifier validArtId(uint256 _artId) {
        require(_artId > 0 && _artId <= _submissionCounter.current(), "Invalid art ID."); // Art ID is same as submission ID for approved art.
        require(artSubmissions[_artId].status == CurationStatus.Approved, "Art ID is not approved or invalid.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(_exhibitionId > 0 && _exhibitionId <= _exhibitionCounter.current(), "Invalid exhibition ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalCounter.current(), "Invalid proposal ID.");
        _;
    }

    modifier proposalIsActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active.");
        _;
    }

    modifier proposalIsPassed(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Passed, "Proposal is not passed.");
        _;
    }

    modifier proposalIsExecutable(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].status == ProposalStatus.Passed && block.timestamp > parameterChangeProposals[_proposalId].endTime, "Proposal is not executable yet.");
        _;
    }


    // -------- Constructor --------

    constructor(string memory _galleryName, address _governanceToken) {
        galleryName = _galleryName;
        governanceTokenAddress = _governanceToken;
        governanceAdmin = msg.sender; // Initial admin is the deployer
    }


    // -------- I. Gallery Management & Governance --------

    /**
     * @dev Sets the gallery name. Only callable by governance admin.
     * @param _newName The new name for the gallery.
     */
    function setGalleryName(string memory _newName) external onlyGovernance {
        galleryName = _newName;
        emit GalleryNameChanged(_newName, msg.sender);
    }

    /**
     * @dev Sets a curator status (active or inactive). Only callable by governance admin.
     * @param _curator The address of the curator.
     * @param _isActive True to activate, false to deactivate.
     */
    function setCurator(address _curator, bool _isActive) external onlyGovernance {
        isCurator[_curator] = _isActive;
        emit CuratorUpdated(_curator, _isActive, msg.sender);
    }

    /**
     * @dev Proposes a change to a gallery parameter. Requires governance token holding.
     * @param _parameterName The name of the parameter to change.
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external galleryIsActive {
        require(IERC20(governanceTokenAddress).balanceOf(msg.sender) > 0, "Must hold governance tokens to propose.");

        _proposalCounter.increment();
        uint256 proposalId = _proposalCounter.current();

        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            startTime: block.timestamp,
            endTime: block.timestamp + proposalVoteDuration,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Active
        });

        emit ParameterChangeProposed(proposalId, _parameterName, _newValue, msg.sender);
    }

    /**
     * @dev Allows governance token holders to vote on a parameter change proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote yes, false to vote no.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) external galleryIsActive validProposalId(_proposalId) proposalIsActive(_proposalId) {
        require(IERC20(governanceTokenAddress).balanceOf(msg.sender) > 0, "Must hold governance tokens to vote.");
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(block.timestamp < proposal.endTime, "Voting period has ended.");

        // TODO: Implement voting weight based on governance token balance if desired.
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit ParameterVoteCast(_proposalId, msg.sender, _support);

        // Check if quorum is reached and proposal passes
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 totalGovernanceSupply = IERC20(governanceTokenAddress).totalSupply();
        if (totalVotes * 100 >= parameterChangeQuorum * totalGovernanceSupply / 100) { // Quorum reached (example: 50% of total supply voted)
            if (proposal.yesVotes > proposal.noVotes) {
                proposal.status = ProposalStatus.Passed;
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
        }
    }

    /**
     * @dev Executes a passed parameter change proposal. Only executable after voting period.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeParameterChange(uint256 _proposalId) external onlyGovernance galleryIsActive validProposalId(_proposalId) proposalIsPassed(_proposalId) proposalIsExecutable(_proposalId) {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.status == ProposalStatus.Passed, "Proposal did not pass.");
        require(block.timestamp > proposal.endTime, "Voting period not yet ended.");
        require(proposal.status != ProposalStatus.Executed, "Proposal already executed.");

        if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("proposalVoteDuration"))) {
            proposalVoteDuration = proposal.newValue;
        } else if (keccak256(abi.encodePacked(proposal.parameterName)) == keccak256(abi.encodePacked("parameterChangeQuorum"))) {
            parameterChangeQuorum = proposal.newValue;
        }
        // Add more parameter change logic here as needed for other governable parameters
        else {
            revert("Unknown parameter to change."); // Or handle unknown parameter changes differently
        }

        proposal.status = ProposalStatus.Executed;
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue, msg.sender);
    }


    /**
     * @dev Emergency shutdown function to halt critical functionalities. Only governance admin.
     */
    function emergencyShutdown() external onlyGovernance {
        galleryActive = false;
        emit EmergencyShutdownTriggered(msg.sender);
    }

    /**
     * @dev Lifts the emergency shutdown and reactivates gallery functionalities. Only governance admin.
     */
    function liftEmergencyShutdown() external onlyGovernance {
        galleryActive = true;
        emit EmergencyShutdownLifted(msg.sender);
    }

    /**
     * @dev Recovers accidentally sent ERC20 tokens to the contract. Only governance admin.
     * @param _tokenAddress The address of the ERC20 token contract.
     * @param _recipient The address to send the recovered tokens to.
     * @param _amount The amount of tokens to recover.
     */
    function recoverERC20(address _tokenAddress, address _recipient, uint256 _amount) external onlyGovernance {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Insufficient token balance in contract.");
        token.transfer(_recipient, _amount);
        emit ERC20Recovered(_tokenAddress, _recipient, _amount, msg.sender);
    }

    /**
     * @dev Returns basic gallery information.
     * @return gallery information (name, governance token address, activity status).
     */
    function getGalleryInfo() external view returns (string memory, address, bool) {
        return (galleryName, governanceTokenAddress, galleryActive);
    }


    // -------- II. Art Submission & Curation --------

    /**
     * @dev Allows anyone to submit an NFT for gallery consideration.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The token ID of the NFT.
     * @param _metadataURI URI pointing to the NFT's metadata.
     */
    function submitArt(address _nftContract, uint256 _tokenId, string memory _metadataURI) external galleryIsActive {
        _submissionCounter.increment();
        uint256 submissionId = _submissionCounter.current();

        artSubmissions[submissionId] = ArtSubmission({
            submitter: msg.sender,
            nftContract: _nftContract,
            tokenId: _tokenId,
            metadataURI: _metadataURI,
            status: CurationStatus.Pending,
            submissionTime: block.timestamp
        });

        emit ArtSubmitted(submissionId, msg.sender, _nftContract, _tokenId);
    }

    /**
     * @dev Allows curators to approve or reject a submitted artwork.
     * @param _submissionId The ID of the art submission.
     * @param _isApproved True to approve, false to reject.
     */
    function curateArt(uint256 _submissionId, bool _isApproved) external onlyCurator galleryIsActive validSubmissionId(_submissionId) {
        ArtSubmission storage submission = artSubmissions[_submissionId];
        require(submission.status == CurationStatus.Pending, "Submission is not pending curation.");

        if (_isApproved) {
            submission.status = CurationStatus.Approved;
            // Consider assigning artId to be the same as submissionId for simplicity, or use a separate counter if needed.
            // In this example, artId will be the same as submissionId upon approval.
            emit ArtCurated(_submissionId, _submissionId, CurationStatus.Approved, msg.sender); // Art ID is submission ID here
        } else {
            submission.status = CurationStatus.Rejected;
            emit ArtCurated(_submissionId, _submissionId, CurationStatus.Rejected, msg.sender); // Art ID is submission ID here
        }
    }

    /**
     * @dev Returns the curation status of a submission.
     * @param _submissionId The ID of the art submission.
     * @return The curation status (Pending, Approved, Rejected).
     */
    function getCurationStatus(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (CurationStatus) {
        return artSubmissions[_submissionId].status;
    }

    /**
     * @dev Returns a list of IDs of currently approved artworks in the gallery.
     * @return An array of art IDs.
     */
    function getApprovedArt() external view returns (uint256[] memory) {
        uint256 approvedArtCount = 0;
        for (uint256 i = 1; i <= _submissionCounter.current(); i++) {
            if (artSubmissions[i].status == CurationStatus.Approved) {
                approvedArtCount++;
            }
        }

        uint256[] memory approvedArtIds = new uint256[](approvedArtCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _submissionCounter.current(); i++) {
            if (artSubmissions[i].status == CurationStatus.Approved) {
                approvedArtIds[index] = i; // Art ID is submission ID
                index++;
            }
        }
        return approvedArtIds;
    }


    // -------- III. Exhibition Management --------

    /**
     * @dev Creates a new exhibition. Only curators can create exhibitions.
     * @param _exhibitionName The name of the exhibition.
     * @param _startTime Unix timestamp for exhibition start time.
     * @param _endTime Unix timestamp for exhibition end time.
     */
    function createExhibition(string memory _exhibitionName, uint256 _startTime, uint256 _endTime) external onlyCurator galleryIsActive {
        require(_startTime < _endTime, "Exhibition start time must be before end time.");
        _exhibitionCounter.increment();
        uint256 exhibitionId = _exhibitionCounter.current();

        exhibitions[exhibitionId] = Exhibition({
            name: _exhibitionName,
            startTime: _startTime,
            endTime: _endTime,
            artIds: new uint256[](0), // Initialize with empty art IDs array
            isActive: true // Exhibitions are active upon creation
        });

        emit ExhibitionCreated(exhibitionId, _exhibitionName, _startTime, _endTime);
    }

    /**
     * @dev Adds approved art to an exhibition. Only curators can add art.
     * @param _exhibitionId The ID of the exhibition.
     * @param _artId The ID of the approved artwork to add.
     */
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artId) external onlyCurator galleryIsActive validExhibitionId(_exhibitionId) validArtId(_artId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isActive, "Exhibition is not active.");

        // Check if art is already in the exhibition (prevent duplicates)
        bool alreadyInExhibition = false;
        for (uint256 i = 0; i < exhibition.artIds.length; i++) {
            if (exhibition.artIds[i] == _artId) {
                alreadyInExhibition = true;
                break;
            }
        }
        require(!alreadyInExhibition, "Art is already in this exhibition.");

        exhibition.artIds.push(_artId);
        emit ArtAddedToExhibition(_exhibitionId, _artId, msg.sender);
    }

    /**
     * @dev Removes art from an exhibition. Only curators can remove art.
     * @param _exhibitionId The ID of the exhibition.
     * @param _artId The ID of the artwork to remove.
     */
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artId) external onlyCurator galleryIsActive validExhibitionId(_exhibitionId) validArtId(_artId) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        require(exhibition.isActive, "Exhibition is not active.");

        uint256 artIndexToRemove;
        bool foundArt = false;
        for (uint256 i = 0; i < exhibition.artIds.length; i++) {
            if (exhibition.artIds[i] == _artId) {
                artIndexToRemove = i;
                foundArt = true;
                break;
            }
        }
        require(foundArt, "Art is not in this exhibition.");

        // Remove art from the array (efficiently by swapping with last element and popping)
        if (exhibition.artIds.length > 1) {
            exhibition.artIds[artIndexToRemove] = exhibition.artIds[exhibition.artIds.length - 1];
        }
        exhibition.artIds.pop();

        emit ArtRemovedFromExhibition(_exhibitionId, _artId, msg.sender);
    }

    /**
     * @dev Returns details of a specific exhibition.
     * @param _exhibitionId The ID of the exhibition.
     * @return Exhibition details (name, start/end times, array of art IDs, activity status).
     */
    function getExhibitionDetails(uint256 _exhibitionId) external view validExhibitionId(_exhibitionId) returns (string memory, uint256, uint256, uint256[] memory, bool) {
        Exhibition storage exhibition = exhibitions[_exhibitionId];
        return (exhibition.name, exhibition.startTime, exhibition.endTime, exhibition.artIds, exhibition.isActive);
    }

    /**
     * @dev Returns a list of IDs of currently active exhibitions.
     * @return An array of exhibition IDs.
     */
    function getActiveExhibitions() external view returns (uint256[] memory) {
        uint256 activeExhibitionCount = 0;
        for (uint256 i = 1; i <= _exhibitionCounter.current(); i++) {
            if (exhibitions[i].isActive && block.timestamp >= exhibitions[i].startTime && block.timestamp <= exhibitions[i].endTime) {
                activeExhibitionCount++;
            }
        }

        uint256[] memory activeExhibitionIds = new uint256[](activeExhibitionCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _exhibitionCounter.current(); i++) {
            if (exhibitions[i].isActive && block.timestamp >= exhibitions[i].startTime && block.timestamp <= exhibitions[i].endTime) {
                activeExhibitionIds[index] = i;
                index++;
            }
        }
        return activeExhibitionIds;
    }


    // -------- IV. Art Interaction & Features --------

    /**
     * @dev Allows users to "like" an artwork.
     * @param _artId The ID of the artwork to like.
     */
    function likeArt(uint256 _artId) external galleryIsActive validArtId(_artId) {
        artLikes[_artId]++;
        emit ArtLiked(_artId, msg.sender);
    }

    /**
     * @dev Returns the like count for a specific artwork.
     * @param _artId The ID of the artwork.
     * @return The number of likes for the artwork.
     */
    function getArtLikes(uint256 _artId) external view validArtId(_artId) returns (uint256) {
        return artLikes[_artId];
    }

    /**
     * @dev Allows users to sponsor an artwork, sending funds to the gallery.
     * @param _artId The ID of the artwork to sponsor.
     */
    function sponsorArt(uint256 _artId) external payable galleryIsActive validArtId(_artId) {
        require(msg.value > 0, "Sponsorship amount must be greater than zero.");
        artSponsorshipBalance[_artId] += msg.value;
        emit ArtSponsored(_artId, msg.sender, msg.value);
    }

    /**
     * @dev Returns the total sponsorship balance for a specific artwork.
     * @param _artId The ID of the artwork.
     * @return The sponsorship balance in wei.
     */
    function getArtSponsorshipBalance(uint256 _artId) external view validArtId(_artId) returns (uint256) {
        return artSponsorshipBalance[_artId];
    }

    /**
     * @dev Allows governance to withdraw sponsorship funds for a specific artwork.
     * @param _artId The ID of the artwork to withdraw funds for.
     */
    function withdrawArtSponsorship(uint256 _artId) external onlyGovernance validArtId(_artId) {
        uint256 balance = artSponsorshipBalance[_artId];
        require(balance > 0, "No sponsorship balance to withdraw.");
        artSponsorshipBalance[_artId] = 0; // Reset balance after withdrawal
        payable(governanceAdmin).transfer(balance); // Governance decides how to distribute funds
    }

    /**
     * @dev Allows users to report an artwork for review.
     * @param _artId The ID of the artwork being reported.
     * @param _reportReason The reason for reporting the artwork.
     */
    function reportArt(uint256 _artId, string memory _reportReason) external galleryIsActive validArtId(_artId) {
        artReports[_artId] = _reportReason; // Simple report storage, can be expanded
        emit ArtReported(_artId, msg.sender, _reportReason);
        // In a real application, you'd likely trigger off-chain processes for curator review based on this event.
    }

    // Fallback function to reject direct ETH sends to the contract (except for sponsorship)
    receive() external payable {
        if (msg.sig != bytes4(keccak256("sponsorArt(uint256)"))) { // Only allow ETH for sponsorArt function
            revert("Direct ETH send not allowed (except for sponsorship).");
        }
    }
}
```