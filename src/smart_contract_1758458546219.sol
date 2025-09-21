This smart contract, `AetherMindForge`, proposes a novel decentralized protocol for **AI-powered content creation, curation, and dynamic ownership**, integrated with a **reputation system** and **decentralized governance**. It enables users to submit content, leverage registered AI agents for analysis and generation, and manage content ownership as dynamic NFTs (dNFTs) with evolving metadata and royalty structures. A Soulbound Token (SBT) system tracks user and AI agent reputation, influencing participation and voting power within the protocol's governance.

---

## Smart Contract: AetherMindForge

**Outline:**

*   **I. Core Infrastructure & Configuration:** Handles contract initialization, fee settings, and emergency controls.
*   **II. User & Reputation Profiles (CreatorID SBTs):** Manages user registration, non-transferable identity tokens, and reputation tracking.
*   **III. AI Agent Registry & Management (AIAgentID NFTs):** Allows registration, configuration, and status management of AI service providers (agents) as NFTs.
*   **IV. Content Creation & Dynamic Ownership (ContentPiece dNFTs):** Facilitates content submission, minting of dynamic NFTs, ownership transfers, and flexible royalty distribution.
*   **V. AI Task Orchestration & Analysis:** Manages requests for AI services on content, submission of results, and a bounty system for specific AI tasks.
*   **VI. Value Flow & Royalties:** Handles deposits, withdrawals of earnings, and distribution of protocol funds.
*   **VII. Decentralized Governance:** Implements a basic proposal and voting mechanism for protocol upgrades and parameter changes.
*   **VIII. Dispute Resolution & Challenges:** Provides a mechanism for users to challenge AI agent outputs and resolve disputes.

---

**Function Summary:**

**I. Core Infrastructure & Configuration**
1.  `constructor()`: Initializes the contract, setting the deployer as owner and a default oracle.
2.  `updateOracleAddress(address _newOracle)`: Allows owner/governance to change the trusted oracle address for AI result submissions.
3.  `setFee(bytes32 _feeType, uint256 _amount)`: Configures various protocol fees (e.g., agent registration, analysis, bounties).
4.  `pauseContract()`: Emergency stop functionality by owner/governance.

**II. User & Reputation Profiles (CreatorID SBTs)**
5.  `registerUserProfile(string memory _metadataURI)`: Creates a user profile, minting a non-transferable `CreatorID` SBT to represent their identity and reputation.
6.  `updateProfileMetadata(uint256 _profileId, string memory _newMetadataURI)`: Allows a user to update the metadata associated with their `CreatorID` SBT.
7.  `getProfileReputation(uint256 _profileId)`: Retrieves the current reputation score of a `CreatorID` profile.

**III. AI Agent Registry & Management (AIAgentID NFTs)**
8.  `registerAIAgent(string memory _metadataURI, bytes32[] memory _capabilities)`: Registers an AI service, minting an `AIAgentID` NFT, defining its capabilities. Requires a fee.
9.  `updateAIAgentCapabilities(uint256 _agentId, bytes32[] memory _newCapabilities)`: Allows an AI agent owner to update the services their agent offers.
10. `setAIAgentStatus(uint256 _agentId, bool _isActive)`: Activates or deactivates an AI agent for taking on new tasks.
11. `getAIAgentReputation(uint256 _agentId)`: Retrieves the current reputation score of an `AIAgentID` NFT.

**IV. Content Creation & Dynamic Ownership (ContentPiece dNFTs)**
12. `submitContent(string memory _contentHash, string memory _metadataURI)`: Submits content, minting a `ContentPiece` dNFT, assigning initial ownership.
13. `transferContentOwnership(uint256 _contentId, address _to)`: Allows the owner of a `ContentPiece` dNFT to transfer it.
14. `setDynamicRoyaltySplit(uint256 _contentId, address[] memory _recipients, uint256[] memory _shares)`: Defines a dynamic royalty distribution for a `ContentPiece` dNFT, including creators, AI agents, and curators.
15. `updateContentMetadata(uint256 _contentId, string memory _newMetadataURI)`: Allows the content owner to update the `ContentPiece` dNFT's metadata URI.

**V. AI Task Orchestration & Analysis**
16. `requestContentAnalysis(uint256 _contentId, uint256[] memory _agentIds, bytes32 _analysisType)`: Requests specific analysis (e.g., plagiarism, quality) for a `ContentPiece` from selected AI agents. Requires a fee.
17. `submitAnalysisResult(uint256 _analysisRequestId, uint256 _agentId, bytes memory _resultHash, int256 _score)`: *Oracle/AI Agent* submits a verifiable analysis result. This updates the `ContentPiece` dNFT's internal state and potentially the agent's reputation.
18. `createAIBounty(string memory _taskDescription, bytes32 _requiredCapability, uint256 _rewardAmount)`: Users post a bounty for a specific AI task with an attached reward.
19. `submitBountySolution(uint256 _bountyId, uint256 _agentId, string memory _solutionURI)`: An AI agent submits a solution to an active bounty.

**VI. Value Flow & Royalties**
20. `withdrawEarnings(address _recipient)`: Allows users (creators, agents, recipients) to withdraw accumulated fees, royalties, or bounty rewards.
21. `depositFunds()`: Allows users to deposit funds into the contract to pay for fees, bounties, etc.

**VII. Decentralized Governance**
22. `proposeProtocolUpgrade(string memory _proposalURI)`: `CreatorID` holders (with sufficient reputation) can propose protocol upgrades or parameter changes.
23. `voteOnProposal(uint256 _proposalId, bool _support)`: Registered profiles (`CreatorID` holders) can vote on active proposals; voting power tied to reputation.
24. `executeProposal(uint256 _proposalId)`: Executes a passed proposal after a timelock.

**VIII. Dispute Resolution & Challenges**
25. `challengeAIAgentOutput(uint256 _analysisRequestId, string memory _reasonURI)`: Users can formally challenge the output or behavior of an AI agent, triggering a dispute process. Requires a bond.
26. `resolveDispute(uint256 _disputeId, address _winner, int256 _reputationPenalty, int256 _reputationAward)`: An authorized entity (e.g., governance, elected jurors) resolves a dispute, distributing bonds and adjusting reputations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom error definitions for better UX and gas efficiency
error NotOwner();
error NotOracle();
error Paused();
error NotCreatorIDOwner(uint256 profileId);
error NotAIAgentOwner(uint256 agentId);
error NotContentPieceOwner(uint256 contentId);
error InsufficientFunds();
error InvalidFeeType();
error InvalidCapabilities();
error AgentNotActive();
error AnalysisNotFound();
error BountyNotFound();
error BountyAlreadySolved();
error BountyNotYetSolved();
error BountyExpired();
error ProposalNotFound();
error ProposalAlreadyVoted();
error ProposalAlreadyExecuted();
error ProposalNotPassed();
error ProposalTooEarly();
error ProposalNotExpired();
error InvalidShareDistribution();
error DisputeNotFound();
error DisputeAlreadyResolved();
error InvalidProfileId();
error InvalidAIAgentId();
error InvalidContentId();

/**
 * @title AetherMindForge
 * @dev A decentralized protocol for AI-powered content creation, curation, and dynamic ownership.
 *      Integrates Soulbound Tokens for reputation, Dynamic NFTs for content, and AI agent orchestration.
 */
contract AetherMindForge is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- State Variables ---

    address public oracleAddress; // Address of the trusted oracle for AI result submissions
    bool public paused; // Global pause switch

    // Mapping for various protocol fees
    mapping(bytes32 => uint256) public fees; // e.g., fees["agent_registration"], fees["analysis_request"]

    // --- Token ID Counters (simple custom minting) ---
    uint256 private _nextCreatorId;
    uint256 private _nextAIAgentId;
    uint256 private _nextContentId;
    uint256 private _nextAnalysisRequestId;
    uint256 private _nextBountyId;
    uint256 private _nextProposalId;
    uint256 private _nextDisputeId;

    // --- I. User & Reputation Profiles (CreatorID SBTs) ---
    struct UserProfile {
        address owner;
        string metadataURI;
        int256 reputation; // Can be positive or negative
    }
    mapping(uint256 => UserProfile) public userProfiles;
    mapping(address => EnumerableSet.UintSet) private _userOwnedCreatorIDs; // A single address can have multiple profiles if needed

    // --- II. AI Agent Registry & Management (AIAgentID NFTs) ---
    struct AIAgent {
        address owner;
        string metadataURI;
        EnumerableSet.Bytes32Set capabilities; // e.g., "PLAGIARISM_DETECTION", "TEXT_SUMMARIZATION"
        bool isActive;
        int256 reputation;
    }
    mapping(uint256 => AIAgent) public aiAgents;
    mapping(address => EnumerableSet.UintSet) private _agentOwnedAIAgentIDs;

    // --- III. Content Creation & Dynamic Ownership (ContentPiece dNFTs) ---
    struct ContentPiece {
        address owner; // Current owner of the dNFT
        string contentHash; // IPFS/Arweave hash of the actual content
        string metadataURI; // URI for the dNFT metadata (can be dynamic)
        uint256 creationTime;
        int256 qualityScore; // Aggregated score from analysis
        mapping(address => uint256) royaltyShares; // Dynamic royalty split
        EnumerableSet.UintSet analysisRequests; // Track analysis requests associated with this content
    }
    mapping(uint256 => ContentPiece) public contentPieces;
    mapping(address => EnumerableSet.UintSet) private _contentOwnedContentIDs; // Tracks which content NFTs an address owns

    // --- IV. AI Task Orchestration & Analysis ---
    struct AnalysisRequest {
        uint256 contentId;
        uint256 agentId;
        bytes32 analysisType;
        bytes resultHash; // Hash of the analysis output (e.g., IPFS hash of a report)
        int256 score; // Score provided by the agent (e.g., plagiarism % negative, quality positive)
        bool isSubmitted;
        uint256 requestTime;
        uint256 submissionTime;
    }
    mapping(uint256 => AnalysisRequest) public analysisRequests;

    struct AIBounty {
        address creator;
        string taskDescription;
        bytes32 requiredCapability;
        uint256 rewardAmount;
        uint256 creationTime;
        uint256 expiryTime;
        uint256 solverAgentId;
        string solutionURI;
        bool isSolved;
        bool isClaimed;
    }
    mapping(uint256 => AIBounty) public aiBounties;

    // --- V. Value Flow & Royalties ---
    mapping(address => uint256) public pendingEarnings; // Funds awaiting withdrawal

    // --- VI. Decentralized Governance ---
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct ProtocolProposal {
        string proposalURI; // Link to detailed proposal document
        uint256 proposerProfileId;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 timelockEndTime; // For execution
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(uint256 => bool) hasVoted; // profileId => bool
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => ProtocolProposal) public proposals;
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant TIMELOCK_PERIOD = 2 days;
    uint256 public constant MIN_REP_FOR_PROPOSAL = 100; // Minimum reputation to propose

    // --- VII. Dispute Resolution & Challenges ---
    enum DisputeState { Pending, Resolved }
    struct Dispute {
        uint256 challengeProfileId; // Profile ID of the challenger
        uint256 analysisRequestId;
        string reasonURI;
        uint256 bondAmount; // Challenger's bond
        address winningParty; // address(0) if not resolved, or challenger/agent address
        int256 reputationPenalty;
        int256 reputationAward;
        DisputeState state;
    }
    mapping(uint256 => Dispute) public disputes;

    // --- Events ---
    event OracleUpdated(address indexed newOracle);
    event FeeSet(bytes32 indexed feeType, uint256 amount);
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);

    event UserProfileRegistered(uint256 indexed profileId, address indexed owner, string metadataURI);
    event UserProfileMetadataUpdated(uint256 indexed profileId, string newMetadataURI);
    event AIAgentRegistered(uint256 indexed agentId, address indexed owner, string metadataURI, bytes32[] capabilities);
    event AIAgentCapabilitiesUpdated(uint256 indexed agentId, bytes32[] newCapabilities);
    event AIAgentStatusChanged(uint256 indexed agentId, bool isActive);

    event ContentSubmitted(uint256 indexed contentId, address indexed creator, string contentHash, string metadataURI);
    event ContentOwnershipTransferred(uint256 indexed contentId, address indexed from, address indexed to);
    event DynamicRoyaltySplitSet(uint256 indexed contentId, address[] recipients, uint256[] shares);
    event ContentMetadataUpdated(uint256 indexed contentId, string newMetadataURI);

    event AnalysisRequested(uint256 indexed analysisRequestId, uint256 indexed contentId, uint256[] agentIds, bytes32 analysisType);
    event AnalysisResultSubmitted(uint256 indexed analysisRequestId, uint256 indexed contentId, uint256 indexed agentId, bytes32 analysisType, bytes resultHash, int256 score);
    event AIBountyCreated(uint256 indexed bountyId, address indexed creator, bytes32 requiredCapability, uint256 rewardAmount);
    event BountySolutionSubmitted(uint256 indexed bountyId, uint256 indexed solverAgentId, string solutionURI);
    event BountyClaimed(uint256 indexed bountyId, uint256 indexed solverAgentId, uint256 rewardAmount);

    event FundsDeposited(address indexed depositor, uint256 amount);
    event EarningsWithdrawn(address indexed recipient, uint256 amount);

    event ProtocolUpgradeProposed(uint256 indexed proposalId, uint256 indexed proposerProfileId, string proposalURI);
    event VotedOnProposal(uint256 indexed proposalId, uint256 indexed voterProfileId, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);

    event AIAgentOutputChallenged(uint256 indexed disputeId, uint256 indexed challengeProfileId, uint256 indexed analysisRequestId, string reasonURI, uint256 bondAmount);
    event DisputeResolved(uint256 indexed disputeId, address indexed winner, int256 reputationPenalty, int256 reputationAward);

    // --- Modifiers ---
    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAddress) revert NotOracle();
        _;
    }

    modifier onlyCreatorIDOwner(uint256 _profileId) {
        if (userProfiles[_profileId].owner != msg.sender) revert NotCreatorIDOwner(_profileId);
        _;
    }

    modifier onlyAIAgentOwner(uint256 _agentId) {
        if (aiAgents[_agentId].owner != msg.sender) revert NotAIAgentOwner(_agentId);
        _;
    }

    modifier onlyContentPieceOwner(uint256 _contentId) {
        if (contentPieces[_contentId].owner != msg.sender) revert NotContentPieceOwner(_contentId);
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        oracleAddress = msg.sender; // Initial oracle is the deployer
        _nextCreatorId = 1;
        _nextAIAgentId = 1;
        _nextContentId = 1;
        _nextAnalysisRequestId = 1;
        _nextBountyId = 1;
        _nextProposalId = 1;
        _nextDisputeId = 1;

        // Set some default fees (can be updated later by owner/governance)
        fees["agent_registration"] = 0.01 ether;
        fees["analysis_request"] = 0.001 ether;
        fees["bounty_creation"] = 0.005 ether;
        fees["dispute_bond"] = 0.05 ether;
    }

    // --- I. Core Infrastructure & Configuration ---

    /**
     * @dev Allows the owner or governance to change the trusted oracle address.
     * @param _newOracle The new address for the oracle.
     */
    function updateOracleAddress(address _newOracle) public onlyOwner {
        oracleAddress = _newOracle;
        emit OracleUpdated(_newOracle);
    }

    /**
     * @dev Allows the owner or governance to configure various protocol fees.
     * @param _feeType Identifier for the fee (e.g., "agent_registration").
     * @param _amount The new fee amount in wei.
     */
    function setFee(bytes32 _feeType, uint256 _amount) public onlyOwner {
        fees[_feeType] = _amount;
        emit FeeSet(_feeType, _amount);
    }

    /**
     * @dev Pauses the contract in case of an emergency.
     *      Only callable by the owner or governance.
     */
    function pauseContract() public onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract.
     *      Only callable by the owner or governance.
     */
    function unpauseContract() public onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- II. User & Reputation Profiles (CreatorID SBTs) ---

    /**
     * @dev Allows a user to create a profile and mints a non-transferable CreatorID Soulbound Token (SBT).
     *      This token represents their on-chain identity and reputation within the AetherMindForge.
     * @param _metadataURI URI pointing to the profile's metadata (e.g., bio, avatar).
     * @return The ID of the newly minted CreatorID.
     */
    function registerUserProfile(string memory _metadataURI) public whenNotPaused returns (uint256) {
        uint256 profileId = _nextCreatorId++;
        userProfiles[profileId] = UserProfile({
            owner: msg.sender,
            metadataURI: _metadataURI,
            reputation: 0 // Start with neutral reputation
        });
        _userOwnedCreatorIDs[msg.sender].add(profileId);
        emit UserProfileRegistered(profileId, msg.sender, _metadataURI);
        return profileId;
    }

    /**
     * @dev Allows a user to update the metadata associated with their CreatorID SBT.
     * @param _profileId The ID of the CreatorID SBT to update.
     * @param _newMetadataURI The new URI pointing to the updated metadata.
     */
    function updateProfileMetadata(uint256 _profileId, string memory _newMetadataURI) public whenNotPaused onlyCreatorIDOwner(_profileId) {
        if (_profileId == 0 || _profileId >= _nextCreatorId) revert InvalidProfileId();
        userProfiles[_profileId].metadataURI = _newMetadataURI;
        emit UserProfileMetadataUpdated(_profileId, _newMetadataURI);
    }

    /**
     * @dev Retrieves the current reputation score of a user profile.
     * @param _profileId The ID of the CreatorID SBT.
     * @return The reputation score.
     */
    function getProfileReputation(uint256 _profileId) public view returns (int256) {
        if (_profileId == 0 || _profileId >= _nextCreatorId) revert InvalidProfileId();
        return userProfiles[_profileId].reputation;
    }

    // --- III. AI Agent Registry & Management (AIAgentID NFTs) ---

    /**
     * @dev Registers an AI service as an AIAgentID NFT. Defines its capabilities.
     *      Requires a registration fee.
     * @param _metadataURI URI pointing to the AI agent's metadata (e.g., service description, API endpoint).
     * @param _capabilities An array of bytes32 representing the agent's capabilities (e.g., keccak256("PLAGIARISM_DETECTION")).
     * @return The ID of the newly minted AIAgentID NFT.
     */
    function registerAIAgent(string memory _metadataURI, bytes32[] memory _capabilities) public payable whenNotPaused returns (uint256) {
        uint256 fee = fees["agent_registration"];
        if (msg.value < fee) revert InsufficientFunds();

        if (_capabilities.length == 0) revert InvalidCapabilities();

        uint256 agentId = _nextAIAgentId++;
        AIAgent storage newAgent = aiAgents[agentId];
        newAgent.owner = msg.sender;
        newAgent.metadataURI = _metadataURI;
        for (uint256 i = 0; i < _capabilities.length; i++) {
            newAgent.capabilities.add(_capabilities[i]);
        }
        newAgent.isActive = true; // Active by default
        newAgent.reputation = 0; // Start with neutral reputation

        _agentOwnedAIAgentIDs[msg.sender].add(agentId);
        pendingEarnings[address(this)] = pendingEarnings[address(this)].add(fee); // Send fee to contract treasury

        emit AIAgentRegistered(agentId, msg.sender, _metadataURI, _capabilities);
        return agentId;
    }

    /**
     * @dev Allows an AI agent owner to update the services their agent offers.
     * @param _agentId The ID of the AIAgentID NFT.
     * @param _newCapabilities An array of bytes32 representing the agent's updated capabilities.
     */
    function updateAIAgentCapabilities(uint256 _agentId, bytes32[] memory _newCapabilities) public whenNotPaused onlyAIAgentOwner(_agentId) {
        if (_agentId == 0 || _agentId >= _nextAIAgentId) revert InvalidAIAgentId();
        if (_newCapabilities.length == 0) revert InvalidCapabilities();

        AIAgent storage agent = aiAgents[_agentId];
        agent.capabilities.clear(); // Clear existing capabilities
        for (uint256 i = 0; i < _newCapabilities.length; i++) {
            agent.capabilities.add(_newCapabilities[i]);
        }
        emit AIAgentCapabilitiesUpdated(_agentId, _newCapabilities);
    }

    /**
     * @dev Activates or deactivates an AI agent for taking on new tasks.
     * @param _agentId The ID of the AIAgentID NFT.
     * @param _isActive True to activate, false to deactivate.
     */
    function setAIAgentStatus(uint256 _agentId, bool _isActive) public whenNotPaused onlyAIAgentOwner(_agentId) {
        if (_agentId == 0 || _agentId >= _nextAIAgentId) revert InvalidAIAgentId();
        aiAgents[_agentId].isActive = _isActive;
        emit AIAgentStatusChanged(_agentId, _isActive);
    }

    /**
     * @dev Retrieves the current reputation score of an AI agent.
     * @param _agentId The ID of the AIAgentID NFT.
     * @return The reputation score.
     */
    function getAIAgentReputation(uint256 _agentId) public view returns (int256) {
        if (_agentId == 0 || _agentId >= _nextAIAgentId) revert InvalidAIAgentId();
        return aiAgents[_agentId].reputation;
    }

    // --- IV. Content Creation & Dynamic Ownership (ContentPiece dNFTs) ---

    /**
     * @dev Submits content and mints a ContentPiece dNFT, assigning initial ownership to the creator.
     *      The dNFT's metadata can evolve based on analysis and curation.
     * @param _contentHash IPFS/Arweave hash of the actual content data.
     * @param _metadataURI URI pointing to the dNFT's initial metadata.
     * @return The ID of the newly minted ContentPiece dNFT.
     */
    function submitContent(string memory _contentHash, string memory _metadataURI) public whenNotPaused returns (uint256) {
        uint256 contentId = _nextContentId++;
        contentPieces[contentId] = ContentPiece({
            owner: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            creationTime: block.timestamp,
            qualityScore: 0 // Initial quality score
        });
        _contentOwnedContentIDs[msg.sender].add(contentId);
        emit ContentSubmitted(contentId, msg.sender, _contentHash, _metadataURI);
        return contentId;
    }

    /**
     * @dev Allows the owner of a ContentPiece dNFT to transfer it, similar to standard ERC721.
     * @param _contentId The ID of the ContentPiece dNFT.
     * @param _to The address to transfer ownership to.
     */
    function transferContentOwnership(uint256 _contentId, address _to) public whenNotPaused onlyContentPieceOwner(_contentId) {
        if (_contentId == 0 || _contentId >= _nextContentId) revert InvalidContentId();
        address from = contentPieces[_contentId].owner;
        contentPieces[_contentId].owner = _to;
        _contentOwnedContentIDs[from].remove(_contentId);
        _contentOwnedContentIDs[_to].add(_contentId);
        emit ContentOwnershipTransferred(_contentId, from, _to);
    }

    /**
     * @dev Defines a dynamic royalty distribution for a ContentPiece dNFT.
     *      Shares are based on percentage (e.g., 10000 for 100%).
     * @param _contentId The ID of the ContentPiece dNFT.
     * @param _recipients An array of addresses to receive royalties.
     * @param _shares An array of corresponding shares (e.g., 5000 for 50%). Sum must be 10000.
     */
    function setDynamicRoyaltySplit(uint256 _contentId, address[] memory _recipients, uint256[] memory _shares) public whenNotPaused onlyContentPieceOwner(_contentId) {
        if (_contentId == 0 || _contentId >= _nextContentId) revert InvalidContentId();
        if (_recipients.length != _shares.length || _recipients.length == 0) revert InvalidShareDistribution();

        uint256 totalShares = 0;
        ContentPiece storage content = contentPieces[_contentId];
        // Clear previous royalty split
        for(uint256 i=0; i<_recipients.length; i++) { // Simplified clearing. In a real system, would iterate and clear old recipients.
            content.royaltyShares[_recipients[i]] = 0;
        }

        for (uint256 i = 0; i < _recipients.length; i++) {
            totalShares = totalShares.add(_shares[i]);
            content.royaltyShares[_recipients[i]] = _shares[i];
        }

        if (totalShares != 10000) revert InvalidShareDistribution(); // 100% represented by 10000

        emit DynamicRoyaltySplitSet(_contentId, _recipients, _shares);
    }

    /**
     * @dev Allows the content owner to update the dNFT's metadata URI.
     *      This allows the dNFT's representation to evolve.
     * @param _contentId The ID of the ContentPiece dNFT.
     * @param _newMetadataURI The new URI pointing to the updated metadata.
     */
    function updateContentMetadata(uint256 _contentId, string memory _newMetadataURI) public whenNotPaused onlyContentPieceOwner(_contentId) {
        if (_contentId == 0 || _contentId >= _nextContentId) revert InvalidContentId();
        contentPieces[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    // --- V. AI Task Orchestration & Analysis ---

    /**
     * @dev Requests specific analysis for a ContentPiece from selected AI agents.
     *      Requires a fee for each agent selected.
     * @param _contentId The ID of the ContentPiece dNFT to analyze.
     * @param _agentIds An array of AIAgentID NFTs selected for the analysis.
     * @param _analysisType The type of analysis requested (e.g., keccak256("PLAGIARISM_DETECTION")).
     * @return The ID of the analysis request.
     */
    function requestContentAnalysis(uint256 _contentId, uint256[] memory _agentIds, bytes32 _analysisType) public payable whenNotPaused returns (uint256) {
        if (_contentId == 0 || _contentId >= _nextContentId) revert InvalidContentId();
        uint256 feePerAgent = fees["analysis_request"];
        if (msg.value < feePerAgent.mul(_agentIds.length)) revert InsufficientFunds();

        for (uint256 i = 0; i < _agentIds.length; i++) {
            uint256 agentId = _agentIds[i];
            if (agentId == 0 || agentId >= _nextAIAgentId) revert InvalidAIAgentId();
            if (!aiAgents[agentId].isActive) revert AgentNotActive();

            uint256 analysisRequestId = _nextAnalysisRequestId++;
            analysisRequests[analysisRequestId] = AnalysisRequest({
                contentId: _contentId,
                agentId: agentId,
                analysisType: _analysisType,
                resultHash: "", // To be filled by oracle
                score: 0, // To be filled by oracle
                isSubmitted: false,
                requestTime: block.timestamp,
                submissionTime: 0
            });
            contentPieces[_contentId].analysisRequests.add(analysisRequestId);
            pendingEarnings[aiAgents[agentId].owner] = pendingEarnings[aiAgents[agentId].owner].add(feePerAgent);
        }
        emit AnalysisRequested(_nextAnalysisRequestId - _agentIds.length, _contentId, _agentIds, _analysisType);
        return _nextAnalysisRequestId - _agentIds.length; // Return the first ID if multiple
    }

    /**
     * @dev Oracle/AI Agent submits the verifiable result of an analysis task.
     *      This updates the ContentPiece dNFT's internal state and potentially the agent's reputation.
     * @param _analysisRequestId The ID of the original analysis request.
     * @param _agentId The ID of the AI agent submitting the result.
     * @param _resultHash Hash of the analysis output (e.g., IPFS hash of a detailed report).
     * @param _score The score provided by the agent (e.g., plagiarism percentage, quality rating).
     */
    function submitAnalysisResult(
        uint256 _analysisRequestId,
        uint256 _agentId,
        bytes memory _resultHash,
        int256 _score
    ) public onlyOracle whenNotPaused {
        if (_analysisRequestId == 0 || _analysisRequestId >= _nextAnalysisRequestId) revert AnalysisNotFound();
        AnalysisRequest storage req = analysisRequests[_analysisRequestId];
        if (req.isSubmitted) return; // Idempotent
        if (req.agentId != _agentId) revert NotAIAgentOwner(_agentId); // Ensure correct agent

        req.resultHash = _resultHash;
        req.score = _score;
        req.isSubmitted = true;
        req.submissionTime = block.timestamp;

        // Update content's quality score (simple average/sum for now, could be more complex)
        contentPieces[req.contentId].qualityScore = contentPieces[req.contentId].qualityScore.add(_score);

        // Update AI agent reputation based on score (e.g., higher score -> positive rep, lower -> negative)
        // This is a simplified linear update. Real systems use more nuanced models.
        if (_score > 0) {
            aiAgents[_agentId].reputation = aiAgents[_agentId].reputation.add(_score);
        } else {
            aiAgents[_agentId].reputation = aiAgents[_agentId].reputation.sub(_score); // Subtracting a negative increases.
        }

        // Update creator's reputation (if good score, creator gets reputation)
        uint256 creatorProfileId = _userOwnedCreatorIDs[contentPieces[req.contentId].owner].at(0); // Assuming one profile per address for simplicity here
        if (creatorProfileId != 0) {
             if (_score > 0) userProfiles[creatorProfileId].reputation = userProfiles[creatorProfileId].reputation.add(_score / 10);
        }

        emit AnalysisResultSubmitted(_analysisRequestId, req.contentId, _agentId, req.analysisType, _resultHash, _score);
    }

    /**
     * @dev Users can post a bounty for a specific AI task with an attached reward.
     * @param _taskDescription URI pointing to the detailed task description.
     * @param _requiredCapability The capability required from the AI agent (e.g., keccak256("IMAGE_GENERATION")).
     * @param _rewardAmount The reward amount for successfully completing the bounty.
     * @return The ID of the newly created bounty.
     */
    function createAIBounty(
        string memory _taskDescription,
        bytes32 _requiredCapability,
        uint256 _rewardAmount
    ) public payable whenNotPaused returns (uint256) {
        uint256 creationFee = fees["bounty_creation"];
        if (msg.value < _rewardAmount.add(creationFee)) revert InsufficientFunds();

        uint256 bountyId = _nextBountyId++;
        aiBounties[bountyId] = AIBounty({
            creator: msg.sender,
            taskDescription: _taskDescription,
            requiredCapability: _requiredCapability,
            rewardAmount: _rewardAmount,
            creationTime: block.timestamp,
            expiryTime: block.timestamp.add(7 days), // Bounties expire in 7 days
            solverAgentId: 0,
            solutionURI: "",
            isSolved: false,
            isClaimed: false
        });
        pendingEarnings[address(this)] = pendingEarnings[address(this)].add(creationFee); // Fee to treasury
        pendingEarnings[msg.sender] = pendingEarnings[msg.sender].sub(_rewardAmount.add(creationFee)); // Deduct from sender's balance
        pendingEarnings[address(this)] = pendingEarnings[address(this)].add(_rewardAmount.add(creationFee)); // Hold reward in contract

        emit AIBountyCreated(bountyId, msg.sender, _requiredCapability, _rewardAmount);
        return bountyId;
    }

    /**
     * @dev An AI agent submits a solution to an active bounty.
     * @param _bountyId The ID of the bounty.
     * @param _agentId The ID of the AI agent submitting the solution.
     * @param _solutionURI URI pointing to the bounty solution (e.g., generated image, summarized text).
     */
    function submitBountySolution(uint256 _bountyId, uint256 _agentId, string memory _solutionURI) public whenNotPaused onlyAIAgentOwner(_agentId) {
        if (_bountyId == 0 || _bountyId >= _nextBountyId) revert BountyNotFound();
        AIBounty storage bounty = aiBounties[_bountyId];
        if (bounty.isSolved) revert BountyAlreadySolved();
        if (block.timestamp > bounty.expiryTime) revert BountyExpired();
        if (!aiAgents[_agentId].capabilities.contains(bounty.requiredCapability)) revert InvalidCapabilities();

        bounty.solverAgentId = _agentId;
        bounty.solutionURI = _solutionURI;
        bounty.isSolved = true;

        emit BountySolutionSubmitted(_bountyId, _agentId, _solutionURI);
    }

    /**
     * @dev Allows the bounty creator to claim the bounty after an agent has submitted a solution.
     *      This implicitly means the creator accepts the solution. The reward is transferred to the solver.
     * @param _bountyId The ID of the bounty.
     */
    function claimBounty(uint256 _bountyId) public whenNotPaused {
        if (_bountyId == 0 || _bountyId >= _nextBountyId) revert BountyNotFound();
        AIBounty storage bounty = aiBounties[_bountyId];
        if (msg.sender != bounty.creator) revert NotOwner(); // Only bounty creator can claim (accept solution)
        if (!bounty.isSolved) revert BountyNotYetSolved();
        if (bounty.isClaimed) revert BountyAlreadySolved();

        bounty.isClaimed = true;
        uint256 reward = bounty.rewardAmount;

        // Transfer reward from contract balance to solver agent's pending earnings
        pendingEarnings[aiAgents[bounty.solverAgentId].owner] = pendingEarnings[aiAgents[bounty.solverAgentId].owner].add(reward);
        pendingEarnings[address(this)] = pendingEarnings[address(this)].sub(reward); // Deduct from contract treasury

        // Increase solver's reputation
        aiAgents[bounty.solverAgentId].reputation = aiAgents[bounty.solverAgentId].reputation.add(reward.div(1 ether).mul(10)); // Simplified rep calc

        emit BountyClaimed(_bountyId, bounty.solverAgentId, reward);
    }

    // --- VI. Value Flow & Royalties ---

    /**
     * @dev Allows users to deposit funds into the contract, e.g., for fees or bounties.
     */
    function depositFunds() public payable whenNotPaused {
        if (msg.value == 0) revert InsufficientFunds();
        pendingEarnings[msg.sender] = pendingEarnings[msg.sender].add(msg.value);
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows users (creators, agents, royalty recipients) to withdraw their accumulated earnings.
     * @param _recipient The address to send the funds to.
     */
    function withdrawEarnings(address _recipient) public whenNotPaused {
        uint256 amount = pendingEarnings[msg.sender];
        if (amount == 0) revert InsufficientFunds();

        pendingEarnings[msg.sender] = 0;
        (bool success,) = _recipient.call{value: amount}("");
        if (!success) {
            pendingEarnings[msg.sender] = amount; // Refund on failure
            revert InsufficientFunds(); // Or a more specific error
        }
        emit EarningsWithdrawn(msg.sender, amount);
    }

    // --- VII. Decentralized Governance ---

    /**
     * @dev Allows users with sufficient CreatorID reputation to propose protocol upgrades or parameter changes.
     * @param _proposalURI URI pointing to the detailed proposal document.
     * @return The ID of the newly created proposal.
     */
    function proposeProtocolUpgrade(string memory _proposalURI) public whenNotPaused returns (uint256) {
        // Find the user's profile ID
        EnumerableSet.UintSet storage creatorIDs = _userOwnedCreatorIDs[msg.sender];
        if (creatorIDs.length() == 0) revert InvalidProfileId();
        uint256 proposerProfileId = creatorIDs.at(0); // Assuming first profile for simplicity

        if (userProfiles[proposerProfileId].reputation < MIN_REP_FOR_PROPOSAL) revert InsufficientFunds(); // Using InsufficientFunds as a generic error here

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = ProtocolProposal({
            proposalURI: _proposalURI,
            proposerProfileId: proposerProfileId,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp.add(VOTING_PERIOD),
            timelockEndTime: 0, // Set after voting ends if succeeded
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProtocolUpgradeProposed(proposalId, proposerProfileId, _proposalURI);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
        return proposalId;
    }

    /**
     * @dev Registered profiles (CreatorID holders) can vote on active proposals.
     *      Voting power could be tied to reputation (1 rep unit = 1 vote).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for "for", false for "against".
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused {
        if (_proposalId == 0 || _proposalId >= _nextProposalId) revert ProposalNotFound();
        ProtocolProposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Active) revert ProposalNotFound(); // Using ProposalNotFound for now
        if (block.timestamp > proposal.voteEndTime) revert ProposalTooEarly(); // Using ProposalTooEarly to mean voting period ended

        EnumerableSet.UintSet storage voterCreatorIDs = _userOwnedCreatorIDs[msg.sender];
        if (voterCreatorIDs.length() == 0) revert InvalidProfileId();
        uint256 voterProfileId = voterCreatorIDs.at(0); // Assuming first profile for simplicity

        if (proposal.hasVoted[voterProfileId]) revert ProposalAlreadyVoted();

        int256 votingPower = userProfiles[voterProfileId].reputation;
        if (votingPower <= 0) votingPower = 1; // Minimum 1 vote for any registered user

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(uint256(votingPower));
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(uint256(votingPower));
        }
        proposal.hasVoted[voterProfileId] = true;

        // Check if voting period ended right after this vote
        if (block.timestamp >= proposal.voteEndTime) {
            if (proposal.votesFor > proposal.votesAgainst) {
                proposal.state = ProposalState.Succeeded;
                proposal.timelockEndTime = block.timestamp.add(TIMELOCK_PERIOD);
                emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);
            } else {
                proposal.state = ProposalState.Failed;
                emit ProposalStateChanged(_proposalId, ProposalState.Failed);
            }
        }
        emit VotedOnProposal(_proposalId, voterProfileId, _support);
    }

    /**
     * @dev Once a proposal passes and the timelock expires, it can be executed.
     *      (This is a placeholder for actual execution logic, which would involve calling other functions or changing parameters.)
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        if (_proposalId == 0 || _proposalId >= _nextProposalId) revert ProposalNotFound();
        ProtocolProposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.Succeeded) revert ProposalNotPassed();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp < proposal.timelockEndTime) revert ProposalTooEarly(); // Timelock not expired

        // Placeholder for actual execution logic.
        // In a real DAO, this would involve a multi-sig or specific contract calls
        // specified within the proposal, e.g., changing fees, updating oracle,
        // or calling other contract functions.
        // For this example, we just mark it as executed.
        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    // --- VIII. Dispute Resolution & Challenges ---

    /**
     * @dev A user can formally challenge the output or behavior of an AI agent based on a specific analysis request.
     *      Requires a bond from the challenger.
     * @param _analysisRequestId The ID of the analysis request whose result is being challenged.
     * @param _reasonURI URI pointing to the detailed reason for the challenge.
     * @return The ID of the newly created dispute.
     */
    function challengeAIAgentOutput(uint256 _analysisRequestId, string memory _reasonURI) public payable whenNotPaused returns (uint256) {
        if (_analysisRequestId == 0 || _analysisRequestId >= _nextAnalysisRequestId) revert AnalysisNotFound();
        AnalysisRequest storage req = analysisRequests[_analysisRequestId];
        if (!req.isSubmitted) revert BountyNotYetSolved(); // Using BountyNotYetSolved to mean not submitted

        uint256 bond = fees["dispute_bond"];
        if (msg.value < bond) revert InsufficientFunds();

        EnumerableSet.UintSet storage challengerCreatorIDs = _userOwnedCreatorIDs[msg.sender];
        if (challengerCreatorIDs.length() == 0) revert InvalidProfileId();
        uint256 challengeProfileId = challengerCreatorIDs.at(0); // Assuming first profile for simplicity

        uint256 disputeId = _nextDisputeId++;
        disputes[disputeId] = Dispute({
            challengeProfileId: challengeProfileId,
            analysisRequestId: _analysisRequestId,
            reasonURI: _reasonURI,
            bondAmount: bond,
            winningParty: address(0),
            reputationPenalty: 0,
            reputationAward: 0,
            state: DisputeState.Pending
        });

        // Funds are held in pendingEarnings of the contract itself until resolution
        pendingEarnings[address(this)] = pendingEarnings[address(this)].add(bond);
        pendingEarnings[msg.sender] = pendingEarnings[msg.sender].sub(bond); // Deduct from challenger's balance

        emit AIAgentOutputChallenged(disputeId, challengeProfileId, _analysisRequestId, _reasonURI, bond);
        return disputeId;
    }

    /**
     * @dev An authorized entity (e.g., governance, elected jurors, owner) resolves a dispute.
     *      Distributes bonds and adjusts reputations based on the resolution.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _winner The address determined to be the winner of the dispute (challenger or agent owner).
     * @param _reputationPenalty Amount of reputation to penalize the losing party.
     * @param _reputationAward Amount of reputation to award the winning party.
     */
    function resolveDispute(
        uint256 _disputeId,
        address _winner,
        int256 _reputationPenalty,
        int256 _reputationAward
    ) public onlyOwner whenNotPaused { // For simplicity, only owner resolves. In advanced setup, this would be DAO/jurors.
        if (_disputeId == 0 || _disputeId >= _nextDisputeId) revert DisputeNotFound();
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.state == DisputeState.Resolved) revert DisputeAlreadyResolved();

        AnalysisRequest storage req = analysisRequests[dispute.analysisRequestId];
        address challengerAddress = userProfiles[dispute.challengeProfileId].owner;
        address agentOwnerAddress = aiAgents[req.agentId].owner;

        address loserAddress;
        uint256 winnerProfileId;
        uint256 loserProfileId;
        uint256 winnerAgentId;
        uint256 loserAgentId;

        if (_winner == challengerAddress) {
            loserAddress = agentOwnerAddress;
            winnerProfileId = dispute.challengeProfileId;
            loserAgentId = req.agentId;

            // Return challenger's bond
            pendingEarnings[challengerAddress] = pendingEarnings[challengerAddress].add(dispute.bondAmount);
            pendingEarnings[address(this)] = pendingEarnings[address(this)].sub(dispute.bondAmount);

            // Award reputation to challenger, penalize agent
            userProfiles[winnerProfileId].reputation = userProfiles[winnerProfileId].reputation.add(_reputationAward);
            aiAgents[loserAgentId].reputation = aiAgents[loserAgentId].reputation.sub(_reputationPenalty);
        } else if (_winner == agentOwnerAddress) {
            loserAddress = challengerAddress;
            winnerAgentId = req.agentId;
            loserProfileId = dispute.challengeProfileId;

            // Challenger loses bond, bond goes to agent owner
            pendingEarnings[agentOwnerAddress] = pendingEarnings[agentOwnerAddress].add(dispute.bondAmount);
            pendingEarnings[address(this)] = pendingEarnings[address(this)].sub(dispute.bondAmount);

            // Award reputation to agent, penalize challenger
            aiAgents[winnerAgentId].reputation = aiAgents[winnerAgentId].reputation.add(_reputationAward);
            userProfiles[loserProfileId].reputation = userProfiles[loserProfileId].reputation.sub(_reputationPenalty);
        } else {
            // No clear winner, or specific logic for other scenarios (e.g., split bond, burn bond)
            // For now, if _winner is neither, bond remains in treasury.
            revert InvalidShareDistribution(); // Generic error
        }

        dispute.winningParty = _winner;
        dispute.reputationPenalty = _reputationPenalty;
        dispute.reputationAward = _reputationAward;
        dispute.state = DisputeState.Resolved;

        emit DisputeResolved(_disputeId, _winner, _reputationPenalty, _reputationAward);
    }

    // --- Fallback & Receive ---
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    fallback() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```