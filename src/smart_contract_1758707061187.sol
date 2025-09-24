Here's a smart contract in Solidity called `EvoMindNexus` that implements an AI-enhanced, dynamic NFT-driven, gamified decentralized research and discovery platform. It features evolving "Knowledge Fragment" NFTs, integration with a simulated AI Oracle, a reputation system, collaborative funding, and a "Proof of Discovery" NFT for validated research.

---

## EvoMindNexus Smart Contract

This contract establishes a decentralized platform for collaborative research and knowledge discovery. Users can propose research topics as "Knowledge Fragments" (KFs), which are dynamic NFTs. These KFs evolve through various stages (e.g., PENDING, FUNDED, IN_PROGRESS, VALIDATED) based on community interaction and funding. An integrated (simulated) AI Oracle provides insights, and a reputation system rewards participants. Successfully validated KFs lead to the minting of "Proof of Discovery" NFTs.

**Core Concepts:**

*   **Dynamic Knowledge Fragment NFTs (KF-NFTs):** Represent research topics. Their metadata and status change based on platform activities, funding, and AI analysis.
*   **AI Oracle Integration:** A simulated external AI service provides scores and insights for KF-NFTs, influencing their visibility and progression.
*   **Collaborative Funding:** Users stake `EVMND` tokens to fund promising KFs.
*   **Reputation System (Cognition Points - CP):** Users earn CP for creating, funding, collaborating on, and validating KFs, unlocking potential future benefits.
*   **Proof of Discovery NFTs (PoD-NFTs):** Awarded upon successful validation of a KF, serving as verifiable credentials of completed research.
*   **Decentralized Validation:** A committee (or community-driven vote) reviews KFs for validation.

---

### Outline & Function Summary:

**I. Core Platform Management (Owner/Admin Controlled)**

1.  `constructor()`: Initializes the contract, sets the deployer as owner, and deploys the associated `KnowledgeFragmentNFT` and `ProofOfDiscoveryNFT` contracts.
2.  `pause()`: Allows the owner to pause all critical operations in case of emergency.
3.  `unpause()`: Allows the owner to unpause the contract operations.
4.  `setEVMNDTokenAddress(address _token)`: Sets the address of the ERC-20 token used for funding and rewards.
5.  `setAIOracleAddress(address _oracle)`: Sets the address of the `IAIOracle` contract for AI analysis requests.
6.  `setValidationCommittee(address[] calldata _committee)`: Sets the list of addresses comprising the validation committee.
7.  `setValidationThreshold(uint256 _threshold)`: Configures the percentage of 'for' votes required from the committee to validate a KF.

**II. Knowledge Fragment (KF) NFT Management (ERC721)**

8.  `createKnowledgeFragment(string memory _title, string memory _ipfsHash, uint256 _requiredFunding)`: Mints a new `KnowledgeFragmentNFT`, initializing its title, IPFS hash (for detailed proposal), and required funding goal.
9.  `updateKnowledgeFragmentMetadataHash(uint256 _tokenId, string memory _newIpfsHash)`: Allows the KF creator/owner to update the IPFS hash linked to their KF, reflecting updated research details.
10. `proposeKFStatusChange(uint256 _tokenId, KFStatus _newStatus)`: Enables controlled transitions of a KF's status (e.g., from `FUNDED` to `IN_PROGRESS`), with specific permissions for each transition.
11. `getKnowledgeFragmentDetails(uint256 _tokenId)`: Retrieves comprehensive details about a specific Knowledge Fragment.
12. `getKnowledgeFragmentStatus(uint256 _tokenId)`: Returns the current `KFStatus` of a Knowledge Fragment.
13. `addCollaborator(uint256 _tokenId, address _collaborator)`: Allows the KF creator to add other addresses as collaborators on their research.

**III. Funding & Staking (using EVMND token)**

14. `fundKnowledgeFragment(uint256 _tokenId, uint256 _amount)`: Allows users to stake `EVMND` tokens to fund a KF, contributing to its funding goal and earning Cognition Points.
15. `withdrawKFStake(uint256 _tokenId, uint256 _amount)`: Enables funders to withdraw their staked `EVMND` under certain conditions, potentially with a penalty.
16. `distributeKF_EVMND_Rewards(uint256 _tokenId)`: Distributes the collected `EVMND` funds (minus platform fees) to the creator and funders of a successfully `VALIDATED` KF.

**IV. AI Oracle Interaction (External Interface)**

17. `requestAIAnalysis(uint256 _tokenId, string memory _dataToAnalyze)`: Sends a request to the configured `IAIOracle` for analysis of a KF's content (e.g., title, proposal summary).
18. `receiveAIAnalysisResult(uint256 _tokenId, uint256 _aiScore, string memory _insightHash)`: A callback function, callable only by the `IAIOracle`, to receive and store the AI's analysis score and insights for a KF.
19. `getAIAnalysisData(uint256 _tokenId)`: Retrieves the latest AI analysis score and insight hash for a given KF.

**V. Reputation System (Cognition Points - CP)**

20. `getCognitionPoints(address _user)`: Returns the total Cognition Points accumulated by a specific user.
21. `claimKFParticipationReward(uint256 _tokenId)`: Allows registered collaborators of a `VALIDATED` KF to claim additional Cognition Points for their contributions.

**VI. Validation & Proof of Discovery (PoD) NFT Management (ERC721)**

22. `submitForValidation(uint256 _tokenId)`: Moves a KF to the `UNDER_REVIEW` status, making it eligible for validation by the committee.
23. `voteOnValidation(uint256 _tokenId, bool _approve)`: Allows members of the validation committee to cast their vote (approve or reject) on a KF under review, earning them Cognition Points.
24. `finalizeValidation(uint256 _tokenId)`: The owner or a committee member finalizes the validation process based on committee votes. If approved, a `ProofOfDiscoveryNFT` is minted.
25. `getProofOfDiscoveryDetails(uint256 _podTokenId)`: Retrieves the owner and URI of a `ProofOfDiscoveryNFT`.

**VII. Utility Functions (Public Views/Admin)**

26. `isCommitteeMember(address _addr)`: Checks if a given address is part of the validation committee.
27. `withdrawAccidentalEVMND(uint256 _amount)`: Allows the owner to recover `EVMND` tokens accidentally sent to the contract that are not part of active KF funding.
28. `getEVMNDContractBalance()`: Returns the total `EVMND` token balance held by the contract.
29. `currentKFTokenId()`: Returns the current counter for `KnowledgeFragmentNFT` IDs.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Interfaces & Internal NFT Contracts ---

/// @title IAIOracle
/// @dev Interface for an external AI Oracle service.
///      This contract is expected to call `receiveAIAnalysisResult` on EvoMindNexus
///      after processing a request.
interface IAIOracle {
    /// @notice Requests an AI analysis for a specific data string related to a KF.
    /// @param _callbackContract The address of the EvoMindNexus contract to call back.
    /// @param _tokenId The ID of the Knowledge Fragment NFT.
    /// @param _dataToAnalyze The string data (e.g., KF title, IPFS hash) for AI to analyze.
    function requestAnalysis(address _callbackContract, uint256 _tokenId, string memory _dataToAnalyze) external;
}

/// @title KnowledgeFragmentNFT
/// @dev An ERC721URIStorage contract for Knowledge Fragment NFTs.
///      EvoMindNexus acts as the exclusive minter and URI setter.
contract KnowledgeFragmentNFT is ERC721URIStorage {
    address public minter;

    constructor() ERC721("KnowledgeFragment", "KF") {
        minter = msg.sender; // The EvoMindNexus contract address will be set as minter
    }

    /// @notice Mints a new KF NFT. Callable only by the designated minter.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the NFT.
    /// @param tokenURI The URI for the NFT's metadata (e.g., IPFS hash).
    /// @return The ID of the minted NFT.
    function mint(address to, uint256 tokenId, string memory tokenURI) external returns (uint256) {
        require(msg.sender == minter, "KF: Only minter can mint");
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    /// @notice Sets/updates the token URI for an existing KF NFT. Callable only by the minter.
    /// @param tokenId The ID of the NFT.
    /// @param tokenURI The new URI for the NFT's metadata.
    function setTokenURI(uint256 tokenId, string memory tokenURI) external {
        require(msg.sender == minter, "KF: Only minter can set URI");
        _setTokenURI(tokenId, tokenURI);
    }
}

/// @title ProofOfDiscoveryNFT
/// @dev An ERC721URIStorage contract for Proof of Discovery NFTs.
///      EvoMindNexus acts as the exclusive minter.
contract ProofOfDiscoveryNFT is ERC721URIStorage {
    address public minter;

    constructor() ERC721("ProofOfDiscovery", "PoD") {
        minter = msg.sender; // The EvoMindNexus contract address will be set as minter
    }

    /// @notice Mints a new PoD NFT. Callable only by the designated minter.
    /// @param to The recipient of the NFT.
    /// @param tokenId The ID of the NFT.
    /// @param tokenURI The URI for the NFT's metadata.
    /// @return The ID of the minted NFT.
    function mint(address to, uint256 tokenId, string memory tokenURI) external returns (uint256) {
        require(msg.sender == minter, "PoD: Only minter can mint");
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }
}

/// @title EvoMindNexus
/// @dev The main contract for the AI-Enhanced Collaborative Research & Dynamic NFT Platform.
contract EvoMindNexus is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    // --- State Variables ---
    KnowledgeFragmentNFT public knowledgeFragmentNFT;
    ProofOfDiscoveryNFT public proofOfDiscoveryNFT;

    IERC20 public EVMND_Token;
    IAIOracle public aiOracle;

    Counters.Counter private _kfTokenIds; // Counter for Knowledge Fragment NFT IDs
    Counters.Counter private _podTokenIds; // Counter for Proof of Discovery NFT IDs

    /// @dev Enum representing the various lifecycle stages of a Knowledge Fragment.
    enum KFStatus {
        PENDING,          // Newly created, awaiting initial funding/review
        FUNDED,           // Has met initial funding goal
        IN_PROGRESS,      // Research actively being conducted
        UNDER_REVIEW,     // Submitted for community/committee validation
        VALIDATED,        // Successfully validated, Proof of Discovery minted
        REJECTED,         // Rejected during review or validation
        ARCHIVED          // Old/inactive topics, post-resolution
    }

    /// @dev Struct storing detailed information about each Knowledge Fragment.
    struct KnowledgeFragment {
        uint256 id;
        address creator;
        string title;
        string ipfsHash;        // IPFS hash pointing to detailed research proposal/data
        uint256 creationTime;
        KFStatus status;
        uint256 requiredFunding;
        uint256 currentFunding; // Total EVMND currently staked for this KF
        address[] fundersList;  // List of unique addresses that have funded this KF
        mapping(address => uint256) funderStakes; // How much each funder staked
        address[] collaborators; // List of additional addresses collaborating on this KF
        uint256 aiAnalysisScore; // Score from AI oracle (e.g., 0-100 for quality/impact)
        string aiInsightHash;    // IPFS hash or summary of AI-generated insights
        uint256 validationVotesFor; // Number of 'for' votes during validation
        uint256 validationVotesAgainst; // Number of 'against' votes during validation
        mapping(address => bool) hasVoted; // Tracks if a committee member has voted
        uint256 podTokenId;     // If validated, ID of the minted ProofOfDiscoveryNFT
    }

    mapping(uint256 => KnowledgeFragment) public knowledgeFragments;
    mapping(address => uint256) public cognitionPoints; // User reputation system

    address[] public validationCommittee;
    uint256 public validationThreshold; // Minimum percentage of 'for' votes required for validation
    uint256 public constant MIN_VALIDATION_COMMITTEE_MEMBERS = 3;

    // --- Events ---
    event KFCreated(uint256 indexed tokenId, address indexed creator, string title, uint256 requiredFunding);
    event KFStatusChanged(uint256 indexed tokenId, KFStatus oldStatus, KFStatus newStatus);
    event KFFunded(uint256 indexed tokenId, address indexed funder, uint256 amount, uint256 totalFunding);
    event KFStakeWithdrawn(uint256 indexed tokenId, address indexed funder, uint256 amount, uint256 remainingStake);
    event KFRewardsDistributed(uint256 indexed tokenId, uint256 totalDistributed);
    event AIAnalysisRequested(uint256 indexed tokenId, string dataToAnalyze);
    event AIAnalysisReceived(uint256 indexed tokenId, uint256 aiScore, string insightHash);
    event CognitionPointsAwarded(address indexed user, uint256 amount, uint256 totalCP);
    event KFSubmittedForValidation(uint256 indexed tokenId);
    event KFValidationVoted(uint256 indexed tokenId, address indexed voter, bool approved);
    event KFValidationFinalized(uint256 indexed tokenId, KFStatus finalStatus, uint256 podTokenId);
    event ProofOfDiscoveryMinted(uint256 indexed podTokenId, uint256 indexed kfTokenId, address indexed recipient);
    event KFMetadataUpdated(uint256 indexed tokenId, string newIpfsHash);
    event CollaboratorAdded(uint256 indexed tokenId, address indexed collaborator);

    // --- Modifiers ---
    /// @dev Restricts function execution to members of the `validationCommittee`.
    modifier onlyValidationCommittee() {
        require(isCommitteeMember(msg.sender), "EvoMindNexus: Only validation committee members can call this function");
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        knowledgeFragmentNFT = new KnowledgeFragmentNFT();
        proofOfDiscoveryNFT = new ProofOfDiscoveryNFT();
        validationThreshold = 60; // Default: 60% approval from committee votes
    }

    // --- I. Core Platform Management (Owner/Admin Controlled) ---

    /// @notice Pauses contract operations (emergency).
    /// @dev Callable only by the contract owner.
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract operations.
    /// @dev Callable only by the contract owner.
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice Sets the address of the EVMND ERC-20 token.
    /// @dev Callable only by the contract owner. Required for funding and rewards.
    /// @param _token The address of the EVMND token contract.
    function setEVMNDTokenAddress(address _token) public onlyOwner {
        require(_token != address(0), "EvoMindNexus: Invalid token address");
        EVMND_Token = IERC20(_token);
    }

    /// @notice Sets the address of the IAIOracle contract.
    /// @dev Callable only by the contract owner. Required for AI analysis features.
    /// @param _oracle The address of the AI Oracle contract.
    function setAIOracleAddress(address _oracle) public onlyOwner {
        require(_oracle != address(0), "EvoMindNexus: Invalid oracle address");
        aiOracle = IAIOracle(_oracle);
    }

    /// @notice Sets the list of addresses for the validation committee.
    /// @dev Callable only by the contract owner. Replaces the entire committee.
    /// @param _committee An array of addresses to be part of the committee.
    function setValidationCommittee(address[] calldata _committee) public onlyOwner {
        require(_committee.length >= MIN_VALIDATION_COMMITTEE_MEMBERS, "EvoMindNexus: Not enough committee members");
        validationCommittee = _committee;
        // Optionally, clear existing votes if committee changes mid-review
        // For simplicity, existing votes are not cleared here.
    }

    /// @notice Sets the required percentage of 'for' votes for KF validation.
    /// @dev Callable only by the contract owner.
    /// @param _threshold The new threshold value (0-100, representing percentage).
    function setValidationThreshold(uint256 _threshold) public onlyOwner {
        require(_threshold > 0 && _threshold <= 100, "EvoMindNexus: Threshold must be between 1 and 100");
        validationThreshold = _threshold;
    }

    // --- II. Knowledge Fragment (KF) NFT Management (ERC721) ---

    /// @notice Mints a new Knowledge Fragment NFT.
    /// @dev The new KF starts in `PENDING` status.
    /// @param _title The title of the research topic.
    /// @param _ipfsHash IPFS hash pointing to detailed research proposal/data (used as tokenURI).
    /// @param _requiredFunding The initial funding target in EVMND tokens.
    /// @return The ID of the newly minted KF NFT.
    function createKnowledgeFragment(
        string memory _title,
        string memory _ipfsHash,
        uint256 _requiredFunding
    ) public whenNotPaused returns (uint256) {
        _kfTokenIds.increment();
        uint256 newId = _kfTokenIds.current();

        knowledgeFragments[newId] = KnowledgeFragment({
            id: newId,
            creator: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            creationTime: block.timestamp,
            status: KFStatus.PENDING,
            requiredFunding: _requiredFunding,
            currentFunding: 0,
            fundersList: new address[](0),
            fundersStakes: new mapping(address => uint256), // Initialized mapping
            collaborators: new address[](0),
            aiAnalysisScore: 0,
            aiInsightHash: "",
            validationVotesFor: 0,
            validationVotesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialized mapping
            podTokenId: 0
        });

        knowledgeFragmentNFT.mint(msg.sender, newId, _ipfsHash); // Mint the KF NFT to the creator

        emit KFCreated(newId, msg.sender, _title, _requiredFunding);
        return newId;
    }

    /// @notice Updates the IPFS hash for a KF's detailed metadata.
    /// @dev Only the KF creator or current owner can update. Not allowed for `VALIDATED` KFs.
    /// @param _tokenId The ID of the KF NFT.
    /// @param _newIpfsHash The new IPFS hash.
    function updateKnowledgeFragmentMetadataHash(uint256 _tokenId, string memory _newIpfsHash) public whenNotPaused {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.creator == msg.sender || knowledgeFragmentNFT.ownerOf(_tokenId) == msg.sender, "EvoMindNexus: Only KF creator or owner can update metadata");
        require(kf.status < KFStatus.VALIDATED, "EvoMindNexus: Cannot update metadata for validated KF");

        kf.ipfsHash = _newIpfsHash;
        knowledgeFragmentNFT.setTokenURI(_tokenId, _newIpfsHash); // Update NFT token URI as well
        emit KFMetadataUpdated(_tokenId, _newIpfsHash);
    }

    /// @notice Proposes a new status for a KF. This function acts as a gate for status transitions.
    /// @dev Only the creator or a committee member can propose certain status changes.
    ///      Specific transitions are explicitly defined and restricted.
    /// @param _tokenId The ID of the KF NFT.
    /// @param _newStatus The proposed new status.
    function proposeKFStatusChange(uint256 _tokenId, KFStatus _newStatus) public whenNotPaused {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.status != KFStatus.VALIDATED && kf.status != KFStatus.REJECTED && kf.status != KFStatus.ARCHIVED, "EvoMindNexus: KF is already resolved or archived");

        KFStatus oldStatus = kf.status;
        bool isCreator = (msg.sender == kf.creator);
        bool isCommittee = isCommitteeMember(msg.sender);

        if (_newStatus == KFStatus.IN_PROGRESS) {
            require(isCreator, "EvoMindNexus: Only creator can mark IN_PROGRESS");
            require(kf.status == KFStatus.FUNDED, "EvoMindNexus: KF must be FUNDED to be IN_PROGRESS");
        } else if (_newStatus == KFStatus.ARCHIVED) {
            require(isCommittee, "EvoMindNexus: Only committee can archive KFs");
            require(kf.status == KFStatus.REJECTED || kf.status == KFStatus.VALIDATED, "EvoMindNexus: Only resolved KFs can be archived");
        } else if (_newStatus == KFStatus.REJECTED) {
            // Creator can reject if no funding, committee can reject anytime before validation
            require(isCommittee || (isCreator && kf.currentFunding == 0), "EvoMindNexus: Only committee, or creator (if unfunded), can reject");
            require(kf.status != KFStatus.UNDER_REVIEW, "EvoMindNexus: Use validation process to reject KFs under review");
        } else if (_newStatus == KFStatus.UNDER_REVIEW) {
            revert("EvoMindNexus: Use submitForValidation for UNDER_REVIEW transition");
        } else {
            revert("EvoMindNexus: Invalid or unsupported status transition");
        }

        kf.status = _newStatus;
        emit KFStatusChanged(_tokenId, oldStatus, kf.status);
    }

    /// @notice Retrieves all public details of a Knowledge Fragment.
    /// @param _tokenId The ID of the KF NFT.
    /// @return A tuple containing all KF details.
    function getKnowledgeFragmentDetails(
        uint256 _tokenId
    ) public view returns (
        uint256 id,
        address creator,
        string memory title,
        string memory ipfsHash,
        uint256 creationTime,
        KFStatus status,
        uint256 requiredFunding,
        uint256 currentFunding,
        address[] memory funders,
        address[] memory collaborators,
        uint256 aiAnalysisScore,
        string memory aiInsightHash,
        uint256 validationVotesFor,
        uint256 validationVotesAgainst,
        uint256 podTokenId
    ) {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");

        // Copy dynamic arrays to memory for return
        address[] memory _funders = new address[](kf.fundersList.length);
        for (uint256 i = 0; i < kf.fundersList.length; i++) {
            _funders[i] = kf.fundersList[i];
        }

        address[] memory _collaborators = new address[](kf.collaborators.length);
        for (uint256 i = 0; i < kf.collaborators.length; i++) {
            _collaborators[i] = kf.collaborators[i];
        }

        return (
            kf.id,
            kf.creator,
            kf.title,
            kf.ipfsHash,
            kf.creationTime,
            kf.status,
            kf.requiredFunding,
            kf.currentFunding,
            _funders,
            _collaborators,
            kf.aiAnalysisScore,
            kf.aiInsightHash,
            kf.validationVotesFor,
            kf.validationVotesAgainst,
            kf.podTokenId
        );
    }

    /// @notice Returns the current status of a Knowledge Fragment.
    /// @param _tokenId The ID of the KF NFT.
    /// @return The current KFStatus.
    function getKnowledgeFragmentStatus(uint256 _tokenId) public view returns (KFStatus) {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        return kf.status;
    }

    /// @notice Adds a collaborator to a Knowledge Fragment.
    /// @dev Only the KF creator can add collaborators. Collaborators receive CP for validated KFs.
    /// @param _tokenId The ID of the KF NFT.
    /// @param _collaborator The address of the new collaborator.
    function addCollaborator(uint256 _tokenId, address _collaborator) public whenNotPaused {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.creator == msg.sender, "EvoMindNexus: Only KF creator can add collaborators");
        require(_collaborator != address(0), "EvoMindNexus: Invalid collaborator address");
        require(kf.status < KFStatus.VALIDATED, "EvoMindNexus: Cannot add collaborators to validated KF");

        // Check if already a collaborator
        for (uint256 i = 0; i < kf.collaborators.length; i++) {
            require(kf.collaborators[i] != _collaborator, "EvoMindNexus: Address is already a collaborator");
        }

        kf.collaborators.push(_collaborator);
        emit CollaboratorAdded(_tokenId, _collaborator);
    }

    // --- III. Funding & Staking (using EVMND token) ---

    /// @notice Stakes EVMND tokens to fund a specific Knowledge Fragment.
    /// @dev Updates KF's current funding and potentially changes its status to `FUNDED`.
    ///      Awards Cognition Points to the funder.
    /// @param _tokenId The ID of the KF NFT to fund.
    /// @param _amount The amount of EVMND tokens to stake.
    function fundKnowledgeFragment(uint256 _tokenId, uint256 _amount) public whenNotPaused nonReentrant {
        require(address(EVMND_Token) != address(0), "EvoMindNexus: EVMND token not set");
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.status <= KFStatus.FUNDED, "EvoMindNexus: KF is no longer accepting direct funding");
        require(_amount > 0, "EvoMindNexus: Funding amount must be positive");

        EVMND_Token.safeTransferFrom(msg.sender, address(this), _amount);

        // Add funder to list if new
        if (kf.funderStakes[msg.sender] == 0) {
            kf.fundersList.push(msg.sender);
        }
        kf.funderStakes[msg.sender] += _amount;
        kf.currentFunding += _amount;

        if (kf.currentFunding >= kf.requiredFunding && kf.status == KFStatus.PENDING) {
            KFStatus oldStatus = kf.status;
            kf.status = KFStatus.FUNDED;
            emit KFStatusChanged(_tokenId, oldStatus, KFStatus.FUNDED);
        }

        _mintCognitionPoints(msg.sender, _amount / 100); // Award 1 CP per 100 EVMND funded (example rate)
        emit KFFunded(_tokenId, msg.sender, _amount, kf.currentFunding);
    }

    /// @notice Allows users to withdraw their staked EVMND if conditions allow.
    /// @dev Withdrawal is allowed if KF is rejected, or with a penalty if withdrawing prematurely.
    /// @param _tokenId The ID of the KF NFT.
    /// @param _amount The amount of EVMND tokens to withdraw.
    function withdrawKFStake(uint256 _tokenId, uint256 _amount) public whenNotPaused nonReentrant {
        require(address(EVMND_Token) != address(0), "EvoMindNexus: EVMND token not set");
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.funderStakes[msg.sender] > 0, "EvoMindNexus: No stake for this KF");
        require(kf.funderStakes[msg.sender] >= _amount, "EvoMindNexus: Insufficient stake");
        require(_amount > 0, "EvoMindNexus: Amount must be positive");
        require(kf.status < KFStatus.VALIDATED, "EvoMindNexus: Cannot withdraw stake from validated KF (rewards distributed separately)");

        uint256 withdrawalAmount = _amount;
        if (kf.status < KFStatus.REJECTED) { // Apply penalty if withdrawing before final resolution
            uint256 penalty = (_amount * 5) / 100; // 5% penalty
            withdrawalAmount -= penalty;
            // The penalty amount is retained by the contract as platform fee or burned
        }

        kf.funderStakes[msg.sender] -= _amount;
        kf.currentFunding -= _amount;

        EVMND_Token.safeTransfer(msg.sender, withdrawalAmount);
        emit KFStakeWithdrawn(_tokenId, msg.sender, withdrawalAmount, kf.funderStakes[msg.sender]);
    }

    /// @notice Distributes staked funds + platform rewards to validated KF creators and funders.
    /// @dev Callable only by the contract owner after a KF is `VALIDATED`.
    /// @param _tokenId The ID of the KF NFT.
    function distributeKF_EVMND_Rewards(uint256 _tokenId) public onlyOwner whenNotPaused nonReentrant {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.status == KFStatus.VALIDATED, "EvoMindNexus: KF is not validated yet");
        require(kf.currentFunding > 0, "EvoMindNexus: No funds to distribute or already distributed");
        require(kf.podTokenId != 0, "EvoMindNexus: PoD NFT not minted for this KF");

        uint256 totalFundBeforeDistribution = kf.currentFunding; // All staked funds for the KF
        uint256 creatorReward = (totalFundBeforeDistribution * 10) / 100; // 10% to creator
        uint256 platformFee = (totalFundBeforeDistribution * 5) / 100;    // 5% to platform treasury (owner)
        uint256 remainingForFunders = totalFundBeforeDistribution - creatorReward - platformFee;

        // Transfer creator's reward
        if (creatorReward > 0) {
            EVMND_Token.safeTransfer(kf.creator, creatorReward);
            _mintCognitionPoints(kf.creator, creatorReward / 50); // Higher CP for creators
        }

        // Transfer platform fee to owner
        if (platformFee > 0) {
            EVMND_Token.safeTransfer(owner(), platformFee);
        }

        // Distribute remaining funds to funders proportionally based on their original stake
        for (uint256 i = 0; i < kf.fundersList.length; i++) {
            address funder = kf.fundersList[i];
            uint256 stake = kf.funderStakes[funder];
            if (stake > 0) {
                uint256 funderShare = (stake * remainingForFunders) / totalFundBeforeDistribution;
                EVMND_Token.safeTransfer(funder, funderShare);
            }
        }

        kf.currentFunding = 0; // All funds distributed
        emit KFRewardsDistributed(_tokenId, totalFundBeforeDistribution);
    }

    // --- IV. AI Oracle Interaction (External Interface) ---

    /// @notice Sends a request to the AI oracle for analysis on KF data.
    /// @dev Can be called by creator or committee member. Requires `aiOracle` to be set.
    /// @param _tokenId The ID of the KF NFT.
    /// @param _dataToAnalyze The data string to send to the AI oracle (e.g., KF title, IPFS hash, abstract).
    function requestAIAnalysis(uint256 _tokenId, string memory _dataToAnalyze) public whenNotPaused {
        require(address(aiOracle) != address(0), "EvoMindNexus: AI Oracle not set");
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.creator == msg.sender || isCommitteeMember(msg.sender), "EvoMindNexus: Only KF creator or committee can request AI analysis");
        require(kf.status < KFStatus.VALIDATED, "EvoMindNexus: Cannot request analysis for validated KF");

        aiOracle.requestAnalysis(address(this), _tokenId, _dataToAnalyze);
        emit AIAnalysisRequested(_tokenId, _dataToAnalyze);
    }

    /// @notice Callback function for the AI oracle to deliver analysis results.
    /// @dev Only callable by the registered AI oracle contract. Updates KF's AI data.
    /// @param _tokenId The ID of the KF NFT.
    /// @param _aiScore The numerical score from AI (e.g., 0-100).
    /// @param _insightHash IPFS hash or summary string of AI insights.
    function receiveAIAnalysisResult(uint256 _tokenId, uint256 _aiScore, string memory _insightHash) external whenNotPaused {
        require(msg.sender == address(aiOracle), "EvoMindNexus: Only AI Oracle can call this function");
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.status < KFStatus.VALIDATED, "EvoMindNexus: Cannot update analysis for validated KF");

        kf.aiAnalysisScore = _aiScore;
        kf.aiInsightHash = _insightHash;
        emit AIAnalysisReceived(_tokenId, _aiScore, _insightHash);
    }

    /// @notice Retrieves the latest AI analysis for a Knowledge Fragment.
    /// @param _tokenId The ID of the KF NFT.
    /// @return A tuple containing the AI score and insight hash.
    function getAIAnalysisData(uint256 _tokenId) public view returns (uint256 aiScore, string memory insightHash) {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        return (kf.aiAnalysisScore, kf.aiInsightHash);
    }

    // --- V. Reputation System (Cognition Points - CP) ---

    /// @notice Returns the current Cognition Points for a user.
    /// @param _user The address of the user.
    /// @return The total Cognition Points for the user.
    function getCognitionPoints(address _user) public view returns (uint256) {
        return cognitionPoints[_user];
    }

    /// @dev Internal helper function to mint Cognition Points.
    /// @param _user The recipient of the CPs.
    /// @param _amount The amount of CPs to mint.
    function _mintCognitionPoints(address _user, uint256 _amount) internal {
        if (_amount > 0) {
            cognitionPoints[_user] += _amount;
            emit CognitionPointsAwarded(_user, _amount, cognitionPoints[_user]);
        }
    }

    /// @notice Allows collaborators on a validated KF to claim their share of rewards and CPs.
    /// @dev This function currently focuses on CP for collaborative efforts.
    /// @param _tokenId The ID of the KF NFT.
    function claimKFParticipationReward(uint256 _tokenId) public whenNotPaused {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.status == KFStatus.VALIDATED, "EvoMindNexus: KF is not validated");

        bool isCollaborator = false;
        for (uint256 i = 0; i < kf.collaborators.length; i++) {
            if (kf.collaborators[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "EvoMindNexus: Not a recognized collaborator for this KF");

        // Simple mechanism to prevent multiple CP claims for collaboration for the same KF.
        // This could be enhanced with a more robust mapping if needed.
        if (kf.hasVoted[msg.sender]) { // Re-using hasVoted mapping for simplicity to track if collaborator already claimed
            revert("EvoMindNexus: Collaborator already claimed rewards for this KF");
        }
        kf.hasVoted[msg.sender] = true; // Mark as claimed

        uint256 cpReward = 50; // Example CP reward for collaborators
        _mintCognitionPoints(msg.sender, cpReward);
    }

    // --- VI. Validation & Proof of Discovery (PoD) NFT Management (ERC721) ---

    /// @notice Moves a KF to the "UNDER_REVIEW" status, making it eligible for validation votes.
    /// @dev Only the creator or a committee member can submit for validation.
    /// @param _tokenId The ID of the KF NFT.
    function submitForValidation(uint256 _tokenId) public whenNotPaused {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.creator == msg.sender || isCommitteeMember(msg.sender), "EvoMindNexus: Only KF creator or committee can submit for validation");
        require(kf.status == KFStatus.IN_PROGRESS || kf.status == KFStatus.FUNDED, "EvoMindNexus: KF must be IN_PROGRESS or FUNDED to submit for validation");

        KFStatus oldStatus = kf.status;
        kf.status = KFStatus.UNDER_REVIEW;
        // Reset vote counts for a fresh review
        kf.validationVotesFor = 0;
        kf.validationVotesAgainst = 0;
        // Clear hasVoted mapping for new voting round
        for (uint256 i = 0; i < validationCommittee.length; i++) {
            delete kf.hasVoted[validationCommittee[i]];
        }
        emit KFSubmittedForValidation(_tokenId);
        emit KFStatusChanged(_tokenId, oldStatus, KFStatus.UNDER_REVIEW);
    }

    /// @notice Committee members vote on the validity of a Knowledge Fragment.
    /// @dev Each committee member can vote once per `UNDER_REVIEW` phase.
    /// @param _tokenId The ID of the KF NFT.
    /// @param _approve True for approval, false for rejection.
    function voteOnValidation(uint256 _tokenId, bool _approve) public onlyValidationCommittee whenNotPaused {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.status == KFStatus.UNDER_REVIEW, "EvoMindNexus: KF is not under review");
        require(!kf.hasVoted[msg.sender], "EvoMindNexus: You have already voted on this KF");

        if (_approve) {
            kf.validationVotesFor++;
        } else {
            kf.validationVotesAgainst++;
        }
        kf.hasVoted[msg.sender] = true; // Mark voter as having voted
        _mintCognitionPoints(msg.sender, 5); // Award CP for active participation
        emit KFValidationVoted(_tokenId, msg.sender, _approve);
    }

    /// @notice Owner/committee member finalizes the validation process based on votes.
    /// @dev Requires the majority (based on `validationThreshold`) of committee votes.
    /// @param _tokenId The ID of the KF NFT.
    function finalizeValidation(uint256 _tokenId) public onlyValidationCommittee whenNotPaused nonReentrant {
        KnowledgeFragment storage kf = knowledgeFragments[_tokenId];
        require(kf.id != 0, "EvoMindNexus: KF does not exist");
        require(kf.status == KFStatus.UNDER_REVIEW, "EvoMindNexus: KF is not under review");
        require(validationCommittee.length > 0, "EvoMindNexus: Validation committee not set up");

        uint256 totalVotesCast = kf.validationVotesFor + kf.validationVotesAgainst;
        // Ensure at least a majority of committee members have voted (e.g., more than half)
        require(totalVotesCast >= (validationCommittee.length / 2) + 1, "EvoMindNexus: Not enough committee votes cast to finalize");

        KFStatus finalStatus;
        uint256 podId = 0;

        uint256 approvalPercentage = (kf.validationVotesFor * 100) / totalVotesCast;
        if (approvalPercentage >= validationThreshold) {
            finalStatus = KFStatus.VALIDATED;
            podId = _mintProofOfDiscoveryNFT(kf.creator, _tokenId); // Mint PoD to the creator
            _mintCognitionPoints(kf.creator, 200); // High CP for successful validation
        } else {
            finalStatus = KFStatus.REJECTED;
            _mintCognitionPoints(kf.creator, 50); // Small CP for effort, even if rejected
        }

        KFStatus oldStatus = kf.status;
        kf.status = finalStatus;
        kf.podTokenId = podId; // Store PoD ID if minted

        emit KFValidationFinalized(_tokenId, finalStatus, podId);
        emit KFStatusChanged(_tokenId, oldStatus, finalStatus);
    }

    /// @dev Internal function to mint a Proof of Discovery NFT.
    /// @param _recipient The address to mint the PoD NFT to.
    /// @param _kfTokenId The ID of the associated Knowledge Fragment NFT.
    /// @return The ID of the newly minted PoD NFT.
    function _mintProofOfDiscoveryNFT(address _recipient, uint256 _kfTokenId) internal returns (uint256) {
        _podTokenIds.increment();
        uint256 newPodId = _podTokenIds.current();
        // Construct a simple token URI for the PoD, referencing the KF's IPFS hash
        string memory podURI = string(abi.encodePacked("ipfs://", knowledgeFragments[_kfTokenId].ipfsHash, "/pod"));
        proofOfDiscoveryNFT.mint(_recipient, newPodId, podURI);
        emit ProofOfDiscoveryMinted(newPodId, _kfTokenId, _recipient);
        return newPodId;
    }

    /// @notice Retrieves details of a Proof of Discovery NFT.
    /// @param _podTokenId The ID of the PoD NFT.
    /// @return The owner and token URI of the PoD NFT.
    function getProofOfDiscoveryDetails(uint256 _podTokenId) public view returns (address owner, string memory tokenURI) {
        require(proofOfDiscoveryNFT.exists(_podTokenId), "EvoMindNexus: PoD NFT does not exist");
        return (proofOfDiscoveryNFT.ownerOf(_podTokenId), proofOfDiscoveryNFT.tokenURI(_podTokenId));
    }

    // --- VII. Utility Functions ---

    /// @dev Checks if an address is a member of the validation committee.
    /// @param _addr The address to check.
    /// @return True if the address is a committee member, false otherwise.
    function isCommitteeMember(address _addr) public view returns (bool) {
        for (uint256 i = 0; i < validationCommittee.length; i++) {
            if (validationCommittee[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    /// @notice Allows the owner to recover accidental EVMND tokens sent to the contract (not part of KF funding).
    /// @param _amount The amount of EVMND to withdraw.
    function withdrawAccidentalEVMND(uint256 _amount) public onlyOwner {
        require(address(EVMND_Token) != address(0), "EvoMindNexus: EVMND token not set");
        require(EVMND_Token.balanceOf(address(this)) - _getTotalStakedEVMND() >= _amount, "EvoMindNexus: Cannot withdraw staked funds or insufficient balance");
        EVMND_Token.safeTransfer(owner(), _amount);
    }

    /// @dev Helper to calculate total staked EVMND across all KFs.
    /// @return The total amount of EVMND tokens currently staked in all KFs.
    function _getTotalStakedEVMND() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= _kfTokenIds.current(); i++) {
            total += knowledgeFragments[i].currentFunding;
        }
        return total;
    }

    /// @notice Returns the contract balance of EVMND.
    /// @return The total EVMND balance of this contract.
    function getEVMNDContractBalance() public view returns (uint256) {
        require(address(EVMND_Token) != address(0), "EvoMindNexus: EVMND token not set");
        return EVMND_Token.balanceOf(address(this));
    }

    /// @notice Returns the current KF ID counter value.
    /// @return The current maximum ID assigned to a Knowledge Fragment NFT.
    function currentKFTokenId() public view returns (uint256) {
        return _kfTokenIds.current();
    }
}
```