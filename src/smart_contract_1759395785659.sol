I'm excited to present `MuseMind`, a smart contract designed to be a decentralized hub for AI-assisted generative content creation and curation, incorporating advanced concepts like dynamic soulbound reputation and a request-for-generation marketplace.

---

# MuseMind - Decentralized AI-Assisted Generative Content Oracle & Reputation System

**Author:** Your Name / AI
**License:** MIT

## Outline

I.  **Interfaces**
    *   `IMuseMindToken`: Interface for the native utility token.
II. **Error Definitions**
    *   Custom errors for various failure conditions.
III. **Contract `MuseMind`**
    A.  **State Variables**
        *   `i_owner`: Contract deployer, initial admin.
        *   `museMindToken`: Address of the native utility token.
        *   `agentMinStake`: Minimum tokens an AI agent must stake.
        *   `requestFeeBps`, `curationFeeBps`: Fees in basis points.
        *   `disputeResolutionFee`: Fixed fee for raising a dispute.
        *   `nextAgentId`, `nextRequestId`, `nextContentId`, `nextDisputeId`: Unique ID counters.
        *   `AIAgent` struct & `aiAgents` mapping: Details for registered AI agents.
        *   `aiAgentAddressToId`: Mapping from agent address to their ID.
        *   `SeedRequest` struct & `seedRequests` mapping: Details for generative seed requests.
        *   `CurationContent` struct & `contents` mapping: Details for user-submitted content for curation.
        *   `Dispute` struct & `disputes` mapping: Details for ongoing and resolved disputes.
        *   `userReputation`, `aiAgentReputation`: Mappings for soulbound reputation scores.
        *   `STAKE_WITHDRAWAL_COOLDOWN`, `agentPendingStakeWithdrawalTimestamp`: For stake management.
    B.  **Events**
        *   Notifications for key actions (registration, requests, approvals, disputes, etc.).
    C.  **Modifiers**
        *   `onlyOwner`: Restricts access to the contract owner.
        *   `onlyAIAgent`, `onlyActiveAgent`, `onlyRequestRecipient`, `onlySeedRequester`: Access controls based on roles and request specifics.
        *   `sufficientStake`: Ensures an AI agent meets minimum stake.
    D.  **Constructor**
        *   Initializes the contract with token address, min stake, and fees.
    E.  **Admin & Governance Functions** (25% of functions)
        *   `setMuseMindTokenAddress`: Sets the utility token address (one-time).
        *   `setAgentMinStake`: Updates the minimum stake for AI agents.
        *   `setFees`: Updates request and curation fees.
        *   `setDisputeResolutionFee`: Updates the dispute fee.
        *   `withdrawFromTreasury`: Allows owner to withdraw treasury funds.
        *   `slashAIAgent`: Penalizes an AI agent by reducing their stake.
        *   `updateUserReputationScore`: Admin-controlled reputation update for users.
        *   `updateAIAgentReputationScore`: Admin-controlled reputation update for AI agents.
    F.  **AI Agent Management** (18% of functions)
        *   `registerAIAgent`: Allows an address to register as an AI agent by staking tokens.
        *   `updateAIAgentProfile`: AI agents can update their profile.
        *   `deactivateAIAgent`: AI agent temporarily deactivates their service.
        *   `reactivateAIAgent`: AI agent reactivates their service.
        *   `withdrawAIAgentStake`: AI agent withdraws stake after deactivation and cooldown.
    G.  **Generative Seed Request & Fulfillment** (14% of functions)
        *   `requestGenerativeSeed`: Users request a seed from an AI agent, paying a reward.
        *   `submitGenerativeSeedResult`: AI agent submits the generated seed hash and metadata.
        *   `approveGenerativeSeedResult`: Requester approves, releases reward, updates reputation.
        *   `rejectGenerativeSeedResult`: Requester rejects, potentially leading to dispute.
    H.  **Content Curation & Reputation** (7% of functions)
        *   `submitContentForCuration`: Users submit generated content for public review.
        *   `rateContent`: Users rate submitted content.
    I.  **Dispute Resolution** (7% of functions)
        *   `raiseDispute`: Either party can raise a dispute over a request.
        *   `resolveDispute`: Owner/governance resolves a dispute, distributing funds/slashing.
    J.  **Treasury & Fees** (3% of functions)
        *   `depositToTreasury`: Allows anyone to deposit tokens into the treasury.
    K.  **View Functions** (26% of functions)
        *   `getAIAgentInfo`: Retrieves details of an AI agent.
        *   `getUserReputation`: Retrieves a user's reputation score.
        *   `getAIAgentReputation`: Retrieves an AI agent's reputation score.
        *   `getSeedRequestDetails`: Retrieves details of a seed request.
        *   `getContentDetails`: Retrieves details of curated content.
        *   `getDisputeDetails`: Retrieves details of a dispute.
        *   `getAgentIdByAddress`: Gets agent ID from address.
        *   `getAgentStake`: Gets an agent's current staked amount.

---

## Function Summary (29 Functions)

**I. Interfaces:**

*   `IMuseMindToken`: Standard ERC-20 like interface for the contract's native utility token.

**II. Error Definitions:**

*   **Custom Errors:** `MuseMind__InvalidZeroAddress`, `MuseMind__TokenAddressAlreadySet`, `MuseMind__AgentNotRegistered`, `MuseMind__AgentAlreadyRegistered`, `MuseMind__AgentNotActive`, `MuseMind__AgentAlreadyActive`, `MuseMind__InsufficientStake`, `MuseMind__AgentStakeTooLow`, `MuseMind__RequestNotFound`, `MuseMind__RequestNotPending`, `MuseMind__RequestNotApproved`, `MuseMind__RequestNotRejected`, `MuseMind__NotRequestRecipient`, `MuseMind__NotSeedRequester`, `MuseMind__AlreadySubmitted`, `MuseMind__ContentNotFound`, `MuseMind__DisputeNotFound`, `MuseMind__DisputeAlreadyResolved`, `MuseMind__InsufficientBalance`, `MuseMind__Unauthorized`, `MuseMind__InvalidRating`, `MuseMind__StakeWithdrawalNotAllowedYet`, `MuseMind__NoStakeToWithdraw`, `MuseMind__StakeWithdrawalInProgress`, `MuseMind__InvalidAgentId`, `MuseMind__InvalidContentId`, `MuseMind__InvalidDisputeId`, `MuseMind__CannotSlashSelf`.

**III. Contract `MuseMind`:**

**A. Admin & Governance Functions (8 functions):**
1.  `setMuseMindTokenAddress(address _tokenAddress)`: Sets the address of the `IMuseMindToken` (callable once by `owner`).
2.  `setAgentMinStake(uint256 _newMinStake)`: Updates the minimum token stake required for AI agents.
3.  `setFees(uint256 _requestFeeBps, uint256 _curationFeeBps)`: Updates the fees charged for seed requests and content curation.
4.  `setDisputeResolutionFee(uint256 _newFee)`: Updates the fee required to raise a dispute.
5.  `withdrawFromTreasury(address _to, uint256 _amount)`: Allows the owner to withdraw `MuseMindToken` from the contract's treasury.
6.  `slashAIAgent(address _agentAddress, uint256 _amount)`: Admin function to penalize an AI agent by reducing their staked tokens.
7.  `updateUserReputationScore(address _user, uint256 _newScore)`: (Admin/System-triggered) Manually updates a user's soulbound reputation score.
8.  `updateAIAgentReputationScore(address _agentAddress, uint256 _newScore)`: (Admin/System-triggered) Manually updates an AI agent's soulbound reputation score.

**B. AI Agent Management (5 functions):**
9.  `registerAIAgent(string memory _name, string memory _description, string memory _oracleEndpoint)`: Allows an entity to register as an AI agent by staking `agentMinStake` tokens.
10. `updateAIAgentProfile(string memory _newName, string memory _newDescription, string memory _newOracleEndpoint)`: Allows a registered AI agent to update their public profile.
11. `deactivateAIAgent()`: Allows an AI agent to temporarily make their service inactive, preventing new requests.
12. `reactivateAIAgent()`: Allows an inactive AI agent to reactivate their service if their stake meets the minimum.
13. `withdrawAIAgentStake()`: Allows a deactivated AI agent to withdraw their staked tokens after a cooldown period, effectively deregistering.

**C. Generative Seed Request & Fulfillment (4 functions):**
14. `requestGenerativeSeed(uint256 _aiAgentId, string memory _prompt, uint256 _rewardAmount)`: A user requests a generative AI seed from a specific active AI agent, paying a reward plus a fee.
15. `submitGenerativeSeedResult(uint256 _requestId, bytes32 _seedHash, string memory _metadataURI)`: The designated AI agent submits the result (e.g., hash of the generated content/seed) for a pending request.
16. `approveGenerativeSeedResult(uint256 _requestId)`: The original requester approves the submitted result, releasing the reward to the AI agent and updating reputations.
17. `rejectGenerativeSeedResult(uint256 _requestId, string memory _reason)`: The original requester rejects the submitted result, marking it for potential dispute.

**D. Content Curation & Reputation (2 functions):**
18. `submitContentForCuration(string memory _contentURI, string memory _contentType, uint256 _originalSeedRequestId)`: A user submits content (presumably generated from a seed) for community curation and rating.
19. `rateContent(uint256 _contentId, uint8 _rating)`: Any user can rate submitted content, contributing to its average score and potentially updating the rater's reputation.

**E. Dispute Resolution (2 functions):**
20. `raiseDispute(uint256 _requestId, string memory _reason)`: Either the requester or AI agent can initiate a dispute for a rejected or unfulfilled request, paying a fee.
21. `resolveDispute(uint256 _disputeId, bool _aiAgentWins, uint256 _slashAmount)`: (Admin/Governance) Resolves an open dispute, distributing funds, updating reputations, and potentially slashing stake based on the outcome.

**F. Treasury & Fees (1 function):**
22. `depositToTreasury(uint256 _amount)`: Allows any user to deposit `MuseMindToken` into the contract's general treasury.

**G. View Functions (7 functions):**
23. `getAIAgentInfo(uint256 _agentId)`: Returns comprehensive details about a registered AI agent.
24. `getUserReputation(address _user)`: Returns the soulbound reputation score for a specific user.
25. `getAIAgentReputation(address _agent)`: Returns the soulbound reputation score for a specific AI agent.
26. `getSeedRequestDetails(uint256 _requestId)`: Returns all details pertaining to a generative seed request.
27. `getContentDetails(uint256 _contentId)`: Returns details about a piece of content submitted for curation, including its average rating.
28. `getDisputeDetails(uint256 _disputeId)`: Returns information about a specific dispute.
29. `getAgentIdByAddress(address _agentAddress)`: Returns the AI agent ID for a given address, or 0 if not registered.
30. `getAgentStake(uint256 _agentId)`: Returns the current staked amount for an AI agent.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MuseMind - Decentralized AI-Assisted Generative Content Oracle & Reputation System
 * @author Your Name/AI
 * @notice This contract creates a decentralized framework for requesting generative AI content seeds,
 *         curating submitted content, and building soulbound reputation for both AI agents and users.
 *         It integrates concepts of AI model registration, token-gated requests, content rating,
 *         dynamic non-transferable (soulbound) reputation, and a basic dispute resolution mechanism.
 *         The aim is to foster a community-driven ecosystem for high-quality AI-generated content.
 *
 * @dev This is an advanced concept contract with many intertwined features. Some aspects, like
 *      true off-chain AI inference or robust decentralized dispute resolution, are simplified
 *      or abstracted for on-chain implementation.
 */

// --- OUTLINE ---
// I. Interfaces
// II. Error Definitions
// III. Contract MuseMind
//     A. State Variables
//     B. Events
//     C. Modifiers
//     D. Constructor
//     E. Admin & Governance Functions
//     F. AI Agent Management
//     G. Generative Seed Request & Fulfillment
//     H. Content Curation & Reputation
//     I. Dispute Resolution
//     J. Treasury & Fees
//     K. View Functions

// --- FUNCTION SUMMARY ---

// I. Interfaces:
//    - IMuseMindToken: Interface for the native utility token used for staking, rewards, and fees.

// II. Error Definitions:
//    - Custom errors for various failure conditions.

// III. Contract MuseMind:
//    A. State Variables:
//       - owner: The contract deployer, initial admin.
//       - museMindToken: Address of the native utility token.
//       - agentMinStake: Minimum tokens an AI agent must stake.
//       - requestFeeBps: Fee taken from seed requests (in basis points).
//       - curationFeeBps: Fee taken from content curation rewards (in basis points).
//       - disputeResolutionFee: Fixed fee for raising a dispute.
//       - nextAgentId, nextRequestId, nextContentId, nextDisputeId: Unique ID counters.
//       - aiAgents: Mapping of agent ID to `AIAgent` struct.
//       - aiAgentAddressToId: Mapping of agent address to agent ID.
//       - seedRequests: Mapping of request ID to `SeedRequest` struct.
//       - contents: Mapping of content ID to `CurationContent` struct.
//       - disputes: Mapping of dispute ID to `Dispute` struct.
//       - userReputation: Mapping of user address to their reputation score (soulbound concept).
//       - aiAgentReputation: Mapping of AI agent address to their reputation score (soulbound concept).
//       - agentPendingStakeWithdrawalTimestamp: Mapping for agents who initiated stake withdrawal.

//    B. Events:
//       - AIAgentRegistered, AIAgentProfileUpdated, AIAgentStatusChanged, AIAgentStakeWithdrawn, AIAgentSlashed
//       - SeedRequestInitiated, SeedResultSubmitted, SeedRequestApproved, SeedRequestRejected
//       - ContentSubmitted, ContentRated, ReputationUpdated
//       - DisputeRaised, DisputeResolved
//       - FeesUpdated, MinStakeUpdated, DisputeFeeUpdated, TreasuryDeposit, TreasuryWithdrawal

//    C. Modifiers:
//       - onlyOwner: Restricts access to the contract owner.
//       - onlyAIAgent: Restricts access to a registered and active AI agent.
//       - onlyRequestRecipient: Restricts access to the specific AI agent meant to fulfill a request.
//       - onlySeedRequester: Restricts access to the user who made a seed request.
//       - onlyActiveAgent: Checks if an AI agent is active.
//       - sufficientStake: Checks if an AI agent has sufficient stake.

//    D. Constructor:
//       - Initializes the contract with the `IMuseMindToken` address, initial min stake, and fees.

//    E. Admin & Governance Functions (can be upgraded to a full DAO in a real project):
//       - setMuseMindTokenAddress(address _tokenAddress): Sets the address of the utility token.
//       - setAgentMinStake(uint256 _newMinStake): Updates the minimum stake required for AI agents.
//       - setFees(uint256 _requestFeeBps, uint256 _curationFeeBps): Updates the request and curation fees.
//       - setDisputeResolutionFee(uint256 _newFee): Updates the fee for raising disputes.
//       - withdrawFromTreasury(address _to, uint256 _amount): Allows owner to withdraw funds from the contract treasury.
//       - slashAIAgent(address _agentAddress, uint256 _amount): Slashes an AI agent's stake due to malicious activity or dispute. (Simulates governance action)
//       - updateUserReputationScore(address _user, uint256 _newScore): Manually updates a user's reputation score. (For testing/admin oversight; in production, this would be system-triggered)
//       - updateAIAgentReputationScore(address _agent, uint256 _newScore): Manually updates an AI agent's reputation score. (For testing/admin oversight; in production, this would be system-triggered)

//    F. AI Agent Management:
//       - registerAIAgent(string memory _name, string memory _description, string memory _oracleEndpoint): Allows an address to register as an AI agent by staking tokens.
//       - updateAIAgentProfile(string memory _newName, string memory _newDescription, string memory _newOracleEndpoint): AI agents can update their profile information.
//       - deactivateAIAgent(): AI agent temporarily deactivates, making them unable to receive new requests.
//       - reactivateAIAgent(): AI agent reactivates their service.
//       - withdrawAIAgentStake(): AI agent can withdraw their stake after deactivation and a cooldown period.

//    G. Generative Seed Request & Fulfillment:
//       - requestGenerativeSeed(uint256 _aiAgentId, string memory _prompt, uint256 _rewardAmount): Users request a generative seed from a specific AI agent, paying a reward.
//       - submitGenerativeSeedResult(uint256 _requestId, bytes32 _seedHash, string memory _metadataURI): AI agent submits the generated seed hash and metadata.
//       - approveGenerativeSeedResult(uint256 _requestId): Seed requester approves the result, releasing the reward to the AI agent and triggering reputation update.
//       - rejectGenerativeSeedResult(uint256 _requestId, string memory _reason): Seed requester rejects the result, initiating a refund or dispute.

//    H. Content Curation & Reputation:
//       - submitContentForCuration(string memory _contentURI, string memory _contentType, uint256 _originalSeedRequestId): Users submit generated content for community curation.
//       - rateContent(uint256 _contentId, uint8 _rating): Users rate submitted content. Good ratings contribute to content creator's and possibly the AI agent's reputation.
//         (Internal logic for reputation updates upon certain thresholds/events could be added here).

//    I. Dispute Resolution:
//       - raiseDispute(uint256 _requestId, string memory _reason): Either the seed requester or the AI agent can raise a dispute over a rejected/unpaid request. Requires a fee.
//       - resolveDispute(uint256 _disputeId, bool _aiAgentWins, uint256 _slashAmount): Owner/governance resolves a dispute, distributing funds and updating reputation/stakes.

//    J. Treasury & Fees:
//       - depositToTreasury(uint256 _amount): Allows anyone to deposit tokens into the contract's treasury.

//    K. View Functions:
//       - getAIAgentInfo(uint256 _agentId): Retrieves details of a specific AI agent.
//       - getUserReputation(address _user): Retrieves the reputation score of a user.
//       - getAIAgentReputation(address _agent): Retrieves the reputation score of an AI agent.
//       - getSeedRequestDetails(uint256 _requestId): Retrieves details of a specific seed request.
//       - getContentDetails(uint256 _contentId): Retrieves details of a specific curated content.
//       - getDisputeDetails(uint256 _disputeId): Retrieves details of a specific dispute.
//       - getAgentIdByAddress(address _agentAddress): Retrieves the agent ID for a given address.
//       - getAgentStake(uint256 _agentId): Retrieves the current staked amount for an AI agent.

interface IMuseMindToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// --- ERROR DEFINITIONS ---
error MuseMind__InvalidZeroAddress();
error MuseMind__TokenAddressAlreadySet();
error MuseMind__AgentNotRegistered();
error MuseMind__AgentAlreadyRegistered();
error MuseMind__AgentNotActive();
error MuseMind__AgentAlreadyActive();
error MuseMind__InsufficientStake();
error MuseMind__AgentStakeTooLow(uint256 currentStake, uint256 requiredStake);
error MuseMind__RequestNotFound();
error MuseMind__RequestNotPending();
// error MuseMind__RequestNotApproved(); // Not currently used, but kept for potential future logic
// error MuseMind__RequestNotRejected(); // Not currently used, but kept for potential future logic
error MuseMind__NotRequestRecipient();
error MuseMind__NotSeedRequester();
error MuseMind__AlreadySubmitted(); // Not currently used, but kept for potential future logic
error MuseMind__ContentNotFound();
error MuseMind__DisputeNotFound();
error MuseMind__DisputeAlreadyResolved();
error MuseMind__InsufficientBalance();
error MuseMind__Unauthorized();
error MuseMind__InvalidRating();
error MuseMind__StakeWithdrawalNotAllowedYet();
error MuseMind__NoStakeToWithdraw();
error MuseMind__StakeWithdrawalInProgress();
error MuseMind__InvalidAgentId();
error MuseMind__InvalidContentId();
error MuseMind__InvalidDisputeId();
error MuseMind__CannotSlashSelf();


contract MuseMind {
    // --- A. STATE VARIABLES ---

    address public immutable i_owner;
    IMuseMindToken public museMindToken;

    uint256 public agentMinStake;
    uint256 public requestFeeBps;  // Basis points (e.g., 100 = 1%)
    uint256 public curationFeeBps; // Basis points
    uint256 public disputeResolutionFee;

    uint256 public nextAgentId;
    uint256 public nextRequestId;
    uint256 public nextContentId;
    uint256 public nextDisputeId;

    // AI Agent Status
    enum AgentStatus { Inactive, Active }

    // Struct for an AI Agent
    struct AIAgent {
        uint256 id;
        address agentAddress;
        string name;
        string description;
        string oracleEndpoint;
        uint256 stake;
        AgentStatus status;
        uint256 deactivationTimestamp; // For cooldown period before withdrawing stake
    }

    mapping(uint256 => AIAgent) public aiAgents;
    mapping(address => uint256) public aiAgentAddressToId; // Maps agent address to their ID

    // Seed Request Status
    enum SeedRequestStatus { Pending, Submitted, Approved, Rejected, Disputed, Resolved }

    // Struct for a Generative Seed Request
    struct SeedRequest {
        uint256 id;
        address requester;
        uint256 aiAgentId;
        string prompt;
        uint256 rewardAmount; // Amount to be paid to AI agent upon approval
        SeedRequestStatus status;
        bytes32 seedHash;     // Hash of the generated seed (e.g., IPFS hash, content hash)
        string metadataURI;   // URI for additional metadata or link to generated content
        uint256 submissionTimestamp;
        uint256 approvalTimestamp;
    }

    mapping(uint256 => SeedRequest) public seedRequests;

    // Struct for Curation Content (generated from a seed)
    struct CurationContent {
        uint256 id;
        string contentURI;      // URI to the generated content (e.g., IPFS)
        string contentType;     // e.g., "Image", "Text", "Audio", "Code"
        address originalSubmitter; // User who submitted this content for curation
        uint256 originalSeedRequestId; // Link back to the seed request
        uint256 creationTimestamp;
        uint256 totalRating;    // Sum of all ratings
        uint256 numRatings;     // Number of ratings received
    }

    mapping(uint256 => CurationContent) public contents;

    // Struct for Disputes
    enum DisputeStatus { Open, Resolved }

    struct Dispute {
        uint256 id;
        uint256 requestId;
        address initiator;
        string reason;
        DisputeStatus status;
        bool aiAgentWins; // True if AI agent wins, False if requester wins (after resolution)
        uint256 resolutionTimestamp;
        address resolver;
    }

    mapping(uint256 => Dispute) public disputes;

    // Soulbound Reputation (non-transferable, managed internally)
    mapping(address => uint252) public userReputation; // Using uint252 to save a tiny bit of gas/storage, still massive
    mapping(address => uint252) public aiAgentReputation; // Using uint252 to save a tiny bit of gas/storage, still massive

    // For stake withdrawal cooldown
    uint256 public constant STAKE_WITHDRAWAL_COOLDOWN = 7 days;
    mapping(address => uint256) public agentPendingStakeWithdrawalTimestamp;


    // --- B. EVENTS ---

    event AIAgentRegistered(uint256 indexed agentId, address indexed agentAddress, string name, uint256 stake);
    event AIAgentProfileUpdated(uint256 indexed agentId, address indexed agentAddress, string newName);
    event AIAgentStatusChanged(uint256 indexed agentId, address indexed agentAddress, AgentStatus newStatus);
    event AIAgentStakeWithdrawn(uint256 indexed agentId, address indexed agentAddress, uint256 amount);
    event AIAgentSlashed(uint256 indexed agentId, address indexed agentAddress, uint256 amount);

    event SeedRequestInitiated(uint256 indexed requestId, address indexed requester, uint256 indexed aiAgentId, uint256 rewardAmount, string prompt);
    event SeedResultSubmitted(uint256 indexed requestId, uint256 indexed aiAgentId, bytes32 seedHash, string metadataURI);
    event SeedRequestApproved(uint256 indexed requestId, address indexed requester, uint256 indexed aiAgentId, uint256 rewardAmount);
    event SeedRequestRejected(uint256 indexed requestId, address indexed requester, string reason);

    event ContentSubmitted(uint256 indexed contentId, address indexed originalSubmitter, string contentURI, uint256 originalSeedRequestId);
    event ContentRated(uint256 indexed contentId, address indexed rater, uint8 rating);
    event ReputationUpdated(address indexed target, uint252 newScore, string reason);

    event DisputeRaised(uint256 indexed disputeId, uint256 indexed requestId, address indexed initiator, string reason);
    event DisputeResolved(uint256 indexed disputeId, uint256 indexed requestId, bool aiAgentWins, uint256 slashAmount, address resolver);

    event FeesUpdated(uint256 newRequestFeeBps, uint256 newCurationFeeBps);
    event MinStakeUpdated(uint256 newMinStake);
    event DisputeFeeUpdated(uint256 newDisputeFee);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed to, uint256 amount);


    // --- C. MODIFIERS ---

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert MuseMind__Unauthorized();
        _;
    }

    modifier onlyAIAgent(uint256 _agentId) {
        if (aiAgentAddressToId[msg.sender] != _agentId || _agentId == 0) revert MuseMind__AgentNotRegistered();
        _;
    }

    modifier onlyActiveAgent(uint256 _agentId) {
        if (aiAgents[_agentId].status != AgentStatus.Active) revert MuseMind__AgentNotActive();
        _;
    }

    modifier onlyRequestRecipient(uint256 _requestId) {
        if (_requestId == 0 || _requestId >= nextRequestId) revert MuseMind__RequestNotFound();
        if (seedRequests[_requestId].aiAgentId != aiAgentAddressToId[msg.sender]) revert MuseMind__NotRequestRecipient();
        _;
    }

    modifier onlySeedRequester(uint256 _requestId) {
        if (_requestId == 0 || _requestId >= nextRequestId) revert MuseMind__RequestNotFound();
        if (seedRequests[_requestId].requester != msg.sender) revert MuseMind__NotSeedRequester();
        _;
    }

    modifier sufficientStake(uint256 _agentId) {
        if (aiAgents[_agentId].stake < agentMinStake) revert MuseMind__AgentStakeTooLow(aiAgents[_agentId].stake, agentMinStake);
        _;
    }


    // --- D. CONSTRUCTOR ---

    constructor(address _museMindTokenAddress, uint256 _initialMinStake, uint256 _initialRequestFeeBps, uint256 _initialCurationFeeBps, uint256 _initialDisputeFee) {
        if (_museMindTokenAddress == address(0)) revert MuseMind__InvalidZeroAddress();
        i_owner = msg.sender;
        museMindToken = IMuseMindToken(_museMindTokenAddress);
        agentMinStake = _initialMinStake;
        requestFeeBps = _initialRequestFeeBps;
        curationFeeBps = _initialCurationFeeBps;
        disputeResolutionFee = _initialDisputeFee;

        nextAgentId = 1; // Start IDs from 1
        nextRequestId = 1;
        nextContentId = 1;
        nextDisputeId = 1;
    }


    // --- E. ADMIN & GOVERNANCE FUNCTIONS ---

    /**
     * @notice Allows the owner to set the address of the MuseMind utility token.
     * @dev Can only be called once after deployment for initialization, or by governance.
     * @param _tokenAddress The address of the IMuseMindToken contract.
     */
    function setMuseMindTokenAddress(address _tokenAddress) external onlyOwner {
        if (address(museMindToken) != address(0)) revert MuseMind__TokenAddressAlreadySet();
        if (_tokenAddress == address(0)) revert MuseMind__InvalidZeroAddress();
        museMindToken = IMuseMindToken(_tokenAddress);
    }

    /**
     * @notice Updates the minimum stake required for AI agents.
     * @param _newMinStake The new minimum stake amount.
     */
    function setAgentMinStake(uint256 _newMinStake) external onlyOwner {
        agentMinStake = _newMinStake;
        emit MinStakeUpdated(_newMinStake);
    }

    /**
     * @notice Updates the fees applied to seed requests and content curation.
     * @param _requestFeeBps The new request fee in basis points (e.g., 100 for 1%).
     * @param _curationFeeBps The new curation fee in basis points.
     */
    function setFees(uint256 _requestFeeBps, uint256 _curationFeeBps) external onlyOwner {
        requestFeeBps = _requestFeeBps;
        curationFeeBps = _curationFeeBps;
        emit FeesUpdated(_requestFeeBps, _curationFeeBps);
    }

    /**
     * @notice Updates the fee for raising disputes.
     * @param _newFee The new dispute resolution fee.
     */
    function setDisputeResolutionFee(uint256 _newFee) external onlyOwner {
        disputeResolutionFee = _newFee;
        emit DisputeFeeUpdated(_newFee);
    }

    /**
     * @notice Allows the owner to withdraw funds from the contract treasury.
     * @param _to The recipient address.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawFromTreasury(address _to, uint256 _amount) external onlyOwner {
        if (_to == address(0)) revert MuseMind__InvalidZeroAddress();
        if (museMindToken.balanceOf(address(this)) < _amount) revert MuseMind__InsufficientBalance();
        
        bool success = museMindToken.transfer(_to, _amount);
        if (!success) revert MuseMind__InsufficientBalance(); // Should not happen if balance check passes

        emit TreasuryWithdrawal(_to, _amount);
    }

    /**
     * @notice Slashes an AI agent's stake due to malicious activity or dispute resolution.
     * @dev This is a powerful administrative function, ideally controlled by a robust governance mechanism.
     * @param _agentAddress The address of the AI agent to slash.
     * @param _amount The amount of tokens to slash from their stake.
     */
    function slashAIAgent(address _agentAddress, uint256 _amount) external onlyOwner {
        uint256 agentId = aiAgentAddressToId[_agentAddress];
        if (agentId == 0) revert MuseMind__AgentNotRegistered();
        if (aiAgents[agentId].stake < _amount) revert MuseMind__InsufficientStake();
        if (_agentAddress == msg.sender) revert MuseMind__CannotSlashSelf(); // Prevent accidental self-slash

        aiAgents[agentId].stake -= _amount;
        // Slashed funds remain in the contract treasury
        emit AIAgentSlashed(agentId, _agentAddress, _amount);
    }

    /**
     * @notice (Admin/System) Manually updates a user's reputation score.
     * @dev In a fully automated system, this would be triggered by content rating outcomes, etc.
     *      Provided here for demonstration and potential administrative oversight.
     * @param _user The address of the user.
     * @param _newScore The new reputation score.
     */
    function updateUserReputationScore(address _user, uint252 _newScore) external onlyOwner {
        if (_user == address(0)) revert MuseMind__InvalidZeroAddress();
        userReputation[_user] = _newScore;
        emit ReputationUpdated(_user, _newScore, "Admin update");
    }

    /**
     * @notice (Admin/System) Manually updates an AI agent's reputation score.
     * @dev Similar to user reputation, this would be system-triggered by successful fulfillments, etc.
     * @param _agentAddress The address of the AI agent.
     * @param _newScore The new reputation score.
     */
    function updateAIAgentReputationScore(address _agentAddress, uint252 _newScore) external onlyOwner {
        if (_agentAddress == address(0)) revert MuseMind__InvalidZeroAddress();
        aiAgentReputation[_agentAddress] = _newScore;
        emit ReputationUpdated(_agentAddress, _newScore, "Admin update");
    }


    // --- F. AI AGENT MANAGEMENT ---

    /**
     * @notice Allows an address to register as an AI agent by staking the minimum required tokens.
     * @param _name The name of the AI agent.
     * @param _description A description of the AI agent's capabilities.
     * @param _oracleEndpoint An endpoint or identifier for the off-chain AI model/oracle.
     */
    function registerAIAgent(
        string memory _name,
        string memory _description,
        string memory _oracleEndpoint
    ) external {
        if (aiAgentAddressToId[msg.sender] != 0) revert MuseMind__AgentAlreadyRegistered();
        
        // Transfer min stake from agent to contract
        bool success = museMindToken.transferFrom(msg.sender, address(this), agentMinStake);
        if (!success) revert MuseMind__InsufficientBalance();

        uint256 newId = nextAgentId++;
        aiAgents[newId] = AIAgent({
            id: newId,
            agentAddress: msg.sender,
            name: _name,
            description: _description,
            oracleEndpoint: _oracleEndpoint,
            stake: agentMinStake,
            status: AgentStatus.Active,
            deactivationTimestamp: 0 // Not applicable until deactivated
        });
        aiAgentAddressToId[msg.sender] = newId;

        emit AIAgentRegistered(newId, msg.sender, _name, agentMinStake);
    }

    /**
     * @notice Allows an AI agent to update their profile information.
     * @param _newName The new name for the AI agent.
     * @param _newDescription The new description.
     * @param _newOracleEndpoint The new oracle endpoint.
     */
    function updateAIAgentProfile(
        string memory _newName,
        string memory _newDescription,
        string memory _newOracleEndpoint
    ) external {
        uint256 agentId = aiAgentAddressToId[msg.sender];
        if (agentId == 0) revert MuseMind__AgentNotRegistered();

        aiAgents[agentId].name = _newName;
        aiAgents[agentId].description = _newDescription;
        aiAgents[agentId].oracleEndpoint = _newOracleEndpoint;

        emit AIAgentProfileUpdated(agentId, msg.sender, _newName);
    }

    /**
     * @notice Allows an AI agent to temporarily deactivate their service.
     * @dev Deactivated agents cannot receive new requests. Stake withdrawal can only happen after a cooldown.
     */
    function deactivateAIAgent() external {
        uint256 agentId = aiAgentAddressToId[msg.sender];
        if (agentId == 0) revert MuseMind__AgentNotRegistered();
        if (aiAgents[agentId].status == AgentStatus.Inactive) revert MuseMind__AgentAlreadyActive(); // Already inactive logic, re-using error

        aiAgents[agentId].status = AgentStatus.Inactive;
        aiAgents[agentId].deactivationTimestamp = block.timestamp; // Start cooldown
        emit AIAgentStatusChanged(agentId, msg.sender, AgentStatus.Inactive);
    }

    /**
     * @notice Allows a deactivated AI agent to reactivate their service.
     * @dev Requires the agent to still meet the minimum stake requirement.
     */
    function reactivateAIAgent() external {
        uint256 agentId = aiAgentAddressToId[msg.sender];
        if (agentId == 0) revert MuseMind__AgentNotRegistered();
        if (aiAgents[agentId].status == AgentStatus.Active) revert MuseMind__AgentAlreadyActive();
        
        // Ensure agent still meets min stake
        if (aiAgents[agentId].stake < agentMinStake) revert MuseMind__AgentStakeTooLow(aiAgents[agentId].stake, agentMinStake);

        aiAgents[agentId].status = AgentStatus.Active;
        aiAgents[agentId].deactivationTimestamp = 0; // Reset cooldown
        emit AIAgentStatusChanged(agentId, msg.sender, AgentStatus.Active);
    }

    /**
     * @notice Allows a deactivated AI agent to withdraw their staked tokens after a cooldown period.
     */
    function withdrawAIAgentStake() external {
        uint256 agentId = aiAgentAddressToId[msg.sender];
        if (agentId == 0) revert MuseMind__AgentNotRegistered();
        if (aiAgents[agentId].status == AgentStatus.Active) revert MuseMind__AgentAlreadyActive(); // Cannot withdraw if active
        if (aiAgents[agentId].stake == 0) revert MuseMind__NoStakeToWithdraw();
        if (aiAgents[agentId].deactivationTimestamp == 0 || block.timestamp < aiAgents[agentId].deactivationTimestamp + STAKE_WITHDRAWAL_COOLDOWN) {
            revert MuseMind__StakeWithdrawalNotAllowedYet();
        }
        
        // Prevent re-entry if a withdrawal is in progress (though not explicitly shown here, good practice)
        if (agentPendingStakeWithdrawalTimestamp[msg.sender] != 0) revert MuseMind__StakeWithdrawalInProgress();
        agentPendingStakeWithdrawalTimestamp[msg.sender] = block.timestamp; // Mark withdrawal in progress

        uint256 amount = aiAgents[agentId].stake;
        aiAgents[agentId].stake = 0; // Clear stake
        aiAgentAddressToId[msg.sender] = 0; // Deregister agent
        
        bool success = museMindToken.transfer(msg.sender, amount);
        if (!success) revert MuseMind__InsufficientBalance(); // Funds should be there

        agentPendingStakeWithdrawalTimestamp[msg.sender] = 0; // Clear withdrawal flag
        emit AIAgentStakeWithdrawn(agentId, msg.sender, amount);
    }


    // --- G. GENERATIVE SEED REQUEST & FULFILLMENT ---

    /**
     * @notice Allows a user to request a generative seed from a specific AI agent.
     * @param _aiAgentId The ID of the target AI agent.
     * @param _prompt The prompt or instructions for the AI model.
     * @param _rewardAmount The amount of tokens to reward the AI agent upon successful fulfillment.
     */
    function requestGenerativeSeed(
        uint256 _aiAgentId,
        string memory _prompt,
        uint256 _rewardAmount
    ) external {
        if (_aiAgentId == 0 || _aiAgentId >= nextAgentId) revert MuseMind__InvalidAgentId();
        AIAgent storage agent = aiAgents[_aiAgentId];
        if (agent.status != AgentStatus.Active) revert MuseMind__AgentNotActive();
        if (agent.stake < agentMinStake) revert MuseMind__AgentStakeTooLow(agent.stake, agentMinStake);
        if (_rewardAmount == 0) revert MuseMind__InsufficientBalance(); // Reward cannot be zero

        uint256 fee = (_rewardAmount * requestFeeBps) / 10000; // Calculate fee based on reward
        uint256 totalPayment = _rewardAmount + fee;

        bool success = museMindToken.transferFrom(msg.sender, address(this), totalPayment);
        if (!success) revert MuseMind__InsufficientBalance();

        uint256 newId = nextRequestId++;
        seedRequests[newId] = SeedRequest({
            id: newId,
            requester: msg.sender,
            aiAgentId: _aiAgentId,
            prompt: _prompt,
            rewardAmount: _rewardAmount,
            status: SeedRequestStatus.Pending,
            seedHash: 0,
            metadataURI: "",
            submissionTimestamp: 0,
            approvalTimestamp: 0
        });

        emit SeedRequestInitiated(newId, msg.sender, _aiAgentId, _rewardAmount, _prompt);
    }

    /**
     * @notice Allows the designated AI agent to submit the generated seed result.
     * @param _requestId The ID of the original seed request.
     * @param _seedHash A hash identifying the generated seed (e.g., content hash, IPFS CID).
     * @param _metadataURI A URI pointing to additional metadata or the generated content itself.
     */
    function submitGenerativeSeedResult(
        uint256 _requestId,
        bytes32 _seedHash,
        string memory _metadataURI
    ) external onlyRequestRecipient(_requestId) {
        // Request ID validation moved into modifier
        SeedRequest storage request = seedRequests[_requestId];
        if (request.status != SeedRequestStatus.Pending) revert MuseMind__RequestNotPending();

        request.seedHash = _seedHash;
        request.metadataURI = _metadataURI;
        request.status = SeedRequestStatus.Submitted;
        request.submissionTimestamp = block.timestamp;

        emit SeedResultSubmitted(_requestId, request.aiAgentId, _seedHash, _metadataURI);
    }

    /**
     * @notice Allows the original seed requester to approve a submitted result.
     * @dev This transfers the reward to the AI agent and updates their reputation.
     * @param _requestId The ID of the seed request.
     */
    function approveGenerativeSeedResult(uint256 _requestId) external onlySeedRequester(_requestId) {
        // Request ID validation moved into modifier
        SeedRequest storage request = seedRequests[_requestId];
        if (request.status != SeedRequestStatus.Submitted) revert MuseMind__RequestNotPending(); // Can only approve if submitted

        uint256 aiAgentId = request.aiAgentId;
        address aiAgentAddress = aiAgents[aiAgentId].agentAddress;
        uint252 rewardAmount = uint252(request.rewardAmount); // Cast to uint252 for reputation update

        // Transfer reward to AI agent (after deducting request fee, which already went to treasury)
        bool success = museMindToken.transfer(aiAgentAddress, rewardAmount);
        if (!success) revert MuseMind__InsufficientBalance(); // Should not happen if funds are held

        request.status = SeedRequestStatus.Approved;
        request.approvalTimestamp = block.timestamp;

        // Update AI agent reputation (simplified: +1 for each approval)
        aiAgentReputation[aiAgentAddress]++;
        emit ReputationUpdated(aiAgentAddress, aiAgentReputation[aiAgentAddress], "Approved seed result");

        // Update user reputation (simplified: +1 for each successful approval)
        userReputation[msg.sender]++;
        emit ReputationUpdated(msg.sender, userReputation[msg.sender], "Approved seed result");

        emit SeedRequestApproved(_requestId, msg.sender, aiAgentId, request.rewardAmount);
    }

    /**
     * @notice Allows the original seed requester to reject a submitted result.
     * @dev This moves the request to 'Rejected' status, allowing for a potential dispute.
     * @param _requestId The ID of the seed request.
     * @param _reason A brief explanation for the rejection.
     */
    function rejectGenerativeSeedResult(uint256 _requestId, string memory _reason) external onlySeedRequester(_requestId) {
        // Request ID validation moved into modifier
        SeedRequest storage request = seedRequests[_requestId];
        if (request.status != SeedRequestStatus.Submitted) revert MuseMind__RequestNotPending(); // Only submitted requests can be rejected

        request.status = SeedRequestStatus.Rejected;
        // The funds remain in the contract until a dispute is resolved or requester withdraws
        emit SeedRequestRejected(_requestId, msg.sender, _reason);
    }


    // --- H. CONTENT CURATION & REPUTATION ---

    /**
     * @notice Allows any user to submit content generated from a seed for public curation.
     * @param _contentURI URI to the generated content (e.g., IPFS hash).
     * @param _contentType A string describing the type of content (e.g., "Image", "Text").
     * @param _originalSeedRequestId The ID of the seed request from which this content was generated.
     */
    function submitContentForCuration(
        string memory _contentURI,
        string memory _contentType,
        uint256 _originalSeedRequestId
    ) external {
        if (_originalSeedRequestId == 0 || _originalSeedRequestId >= nextRequestId) revert MuseMind__RequestNotFound();
        
        uint256 newId = nextContentId++;
        contents[newId] = CurationContent({
            id: newId,
            contentURI: _contentURI,
            contentType: _contentType,
            originalSubmitter: msg.sender,
            originalSeedRequestId: _originalSeedRequestId,
            creationTimestamp: block.timestamp,
            totalRating: 0,
            numRatings: 0
        });

        // Simplified: User reputation gains from submitting content
        userReputation[msg.sender]++;
        emit ReputationUpdated(msg.sender, userReputation[msg.sender], "Submitted content for curation");

        emit ContentSubmitted(newId, msg.sender, _contentURI, _originalSeedRequestId);
    }

    /**
     * @notice Allows users to rate submitted content.
     * @dev A user's reputation could influence their rating weight in a more complex system.
     * @param _contentId The ID of the content to rate.
     * @param _rating The rating (e.g., 1-5 stars).
     */
    function rateContent(uint256 _contentId, uint8 _rating) external {
        if (_contentId == 0 || _contentId >= nextContentId) revert MuseMind__InvalidContentId();
        if (_rating < 1 || _rating > 5) revert MuseMind__InvalidRating();

        CurationContent storage content = contents[_contentId];
        
        // Prevent self-rating (optional, but good for fairness)
        if (content.originalSubmitter == msg.sender) revert MuseMind__Unauthorized(); 

        content.totalRating += _rating;
        content.numRatings++;

        // Simplified: rater's reputation increases for active participation
        userReputation[msg.sender]++;
        emit ReputationUpdated(msg.sender, userReputation[msg.sender], "Rated content");

        // In a more advanced system, content creators reputation would update based on average ratings.
        // For simplicity, this is done via admin in updateAIAgentReputationScore and updateUserReputationScore

        emit ContentRated(_contentId, msg.sender, _rating);
    }


    // --- I. DISPUTE RESOLUTION ---

    /**
     * @notice Allows either the seed requester or the AI agent to raise a dispute over a request.
     * @dev Requires a dispute resolution fee.
     * @param _requestId The ID of the seed request in dispute.
     * @param _reason A brief explanation for raising the dispute.
     */
    function raiseDispute(uint256 _requestId, string memory _reason) external {
        if (_requestId == 0 || _requestId >= nextRequestId) revert MuseMind__RequestNotFound();
        SeedRequest storage request = seedRequests[_requestId];

        bool isRequester = (msg.sender == request.requester);
        bool isAIAgent = (msg.sender == aiAgents[request.aiAgentId].agentAddress);

        if (!isRequester && !isAIAgent) revert MuseMind__Unauthorized(); // Only requester or AI agent can dispute
        
        // Can only dispute if it's submitted (AI agent disputes non-payment) or rejected (requester disputes result)
        if (request.status != SeedRequestStatus.Rejected && request.status != SeedRequestStatus.Submitted) {
             revert MuseMind__RequestNotPending();
        }

        // Pay dispute fee
        bool success = museMindToken.transferFrom(msg.sender, address(this), disputeResolutionFee);
        if (!success) revert MuseMind__InsufficientBalance();

        uint256 newId = nextDisputeId++;
        disputes[newId] = Dispute({
            id: newId,
            requestId: _requestId,
            initiator: msg.sender,
            reason: _reason,
            status: DisputeStatus.Open,
            aiAgentWins: false, // Default, updated upon resolution
            resolutionTimestamp: 0,
            resolver: address(0)
        });

        request.status = SeedRequestStatus.Disputed; // Mark request as disputed

        emit DisputeRaised(newId, _requestId, msg.sender, _reason);
    }

    /**
     * @notice (Admin/Governance) Resolves an open dispute.
     * @dev This function determines the outcome of the dispute, distributes funds, and potentially slashes stakes.
     *      In a real system, this would be determined by a DAO vote, arbitration, or oracle.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _aiAgentWins True if the AI agent wins the dispute, false if the requester wins.
     * @param _slashAmount The amount of tokens to slash from the losing party's stake (if applicable).
     */
    function resolveDispute(
        uint256 _disputeId,
        bool _aiAgentWins,
        uint256 _slashAmount
    ) external onlyOwner {
        if (_disputeId == 0 || _disputeId >= nextDisputeId) revert MuseMind__InvalidDisputeId();
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.status != DisputeStatus.Open) revert MuseMind__DisputeAlreadyResolved();
        
        SeedRequest storage request = seedRequests[dispute.requestId];
        address aiAgentAddress = aiAgents[request.aiAgentId].agentAddress;

        if (_aiAgentWins) {
            // AI agent wins: Reward AI agent, potentially slash requester's reputation or future deposits
            bool success = museMindToken.transfer(aiAgentAddress, request.rewardAmount);
            if (!success) revert MuseMind__InsufficientBalance(); // Funds should be held in contract
            request.status = SeedRequestStatus.Resolved;
            aiAgentReputation[aiAgentAddress] += 2; // Boost reputation for winning dispute
            userReputation[request.requester] = userReputation[request.requester] > 0 ? userReputation[request.requester] - 1 : 0; // Reduce requester reputation
            emit ReputationUpdated(aiAgentAddress, aiAgentReputation[aiAgentAddress], "Won dispute");
            emit ReputationUpdated(request.requester, userReputation[request.requester], "Lost dispute");
        } else {
            // Requester wins: Refund requester, potentially slash AI agent's stake/reputation
            uint256 totalPayment = request.rewardAmount + (request.rewardAmount * requestFeeBps / 10000); // Original total payment
            bool success = museMindToken.transfer(request.requester, totalPayment);
            if (!success) revert MuseMind__InsufficientBalance(); // Funds should be held in contract
            request.status = SeedRequestStatus.Resolved;
            userReputation[request.requester] += 2; // Boost reputation for winning dispute
            aiAgentReputation[aiAgentAddress] = aiAgentReputation[aiAgentAddress] > 0 ? aiAgentReputation[aiAgentAddress] - 1 : 0; // Reduce agent reputation
            emit ReputationUpdated(request.requester, userReputation[request.requester], "Won dispute");
            emit ReputationUpdated(aiAgentAddress, aiAgentReputation[aiAgentAddress], "Lost dispute");

            if (_slashAmount > 0) {
                // Slash AI agent's stake
                uint256 agentId = aiAgentAddressToId[aiAgentAddress];
                if (aiAgents[agentId].stake < _slashAmount) {
                     _slashAmount = aiAgents[agentId].stake; // Slash all if less than requested
                }
                aiAgents[agentId].stake -= _slashAmount;
                emit AIAgentSlashed(agentId, aiAgentAddress, _slashAmount);
            }
        }

        dispute.status = DisputeStatus.Resolved;
        dispute.aiAgentWins = _aiAgentWins;
        dispute.resolutionTimestamp = block.timestamp;
        dispute.resolver = msg.sender;

        emit DisputeResolved(_disputeId, dispute.requestId, _aiAgentWins, _slashAmount, msg.sender);
    }


    // --- J. TREASURY & FEES ---

    /**
     * @notice Allows anyone to deposit MuseMind tokens into the contract's treasury.
     * @dev These funds can be used for various purposes, e.g., funding curation rewards,
     *      protocol development, or increasing the `agentMinStake`.
     * @param _amount The amount of tokens to deposit.
     */
    function depositToTreasury(uint256 _amount) external {
        if (_amount == 0) revert MuseMind__InsufficientBalance();
        bool success = museMindToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert MuseMind__InsufficientBalance();
        emit TreasuryDeposit(msg.sender, _amount);
    }


    // --- K. VIEW FUNCTIONS ---

    /**
     * @notice Retrieves information about a specific AI agent.
     * @param _agentId The ID of the AI agent.
     * @return id The agent's ID.
     * @return agentAddress The agent's wallet address.
     * @return name The agent's name.
     * @return description The agent's description.
     * @return oracleEndpoint The agent's oracle endpoint.
     * @return stake The current staked amount of the agent.
     * @return status The agent's current status (Active/Inactive).
     * @return deactivationTimestamp The timestamp when the agent was deactivated (0 if active).
     */
    function getAIAgentInfo(uint256 _agentId)
        external
        view
        returns (
            uint256 id,
            address agentAddress,
            string memory name,
            string memory description,
            string memory oracleEndpoint,
            uint256 stake,
            AgentStatus status,
            uint256 deactivationTimestamp
        )
    {
        if (_agentId == 0 || _agentId >= nextAgentId) revert MuseMind__InvalidAgentId();
        AIAgent storage agent = aiAgents[_agentId];
        return (
            agent.id,
            agent.agentAddress,
            agent.name,
            agent.description,
            agent.oracleEndpoint,
            agent.stake,
            agent.status,
            agent.deactivationTimestamp
        );
    }

    /**
     * @notice Retrieves the current reputation score of a user.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint252) {
        return userReputation[_user];
    }

    /**
     * @notice Retrieves the current reputation score of an AI agent.
     * @param _agent The address of the AI agent.
     * @return The AI agent's reputation score.
     */
    function getAIAgentReputation(address _agent) external view returns (uint252) {
        return aiAgentReputation[_agent];
    }

    /**
     * @notice Retrieves details of a specific generative seed request.
     * @param _requestId The ID of the seed request.
     * @return id The request's ID.
     * @return requester The address of the requester.
     * @return aiAgentId The ID of the AI agent.
     * @return prompt The original prompt.
     * @return rewardAmount The reward amount for the AI agent.
     * @return status The current status of the request.
     * @return seedHash The hash of the submitted seed (0 if not submitted).
     * @return metadataURI The URI for submitted metadata (empty if not submitted).
     * @return submissionTimestamp The timestamp of result submission (0 if not submitted).
     * @return approvalTimestamp The timestamp of approval (0 if not approved).
     */
    function getSeedRequestDetails(uint256 _requestId)
        external
        view
        returns (
            uint256 id,
            address requester,
            uint256 aiAgentId,
            string memory prompt,
            uint256 rewardAmount,
            SeedRequestStatus status,
            bytes32 seedHash,
            string memory metadataURI,
            uint256 submissionTimestamp,
            uint256 approvalTimestamp
        )
    {
        if (_requestId == 0 || _requestId >= nextRequestId) revert MuseMind__RequestNotFound();
        SeedRequest storage request = seedRequests[_requestId];
        return (
            request.id,
            request.requester,
            request.aiAgentId,
            request.prompt,
            request.rewardAmount,
            request.status,
            request.seedHash,
            request.metadataURI,
            request.submissionTimestamp,
            request.approvalTimestamp
        );
    }

    /**
     * @notice Retrieves details of a specific curated content.
     * @param _contentId The ID of the content.
     * @return id The content's ID.
     * @return contentURI The URI to the content.
     * @return contentType The type of content.
     * @return originalSubmitter The address of the user who submitted the content for curation.
     * @return originalSeedRequestId The ID of the seed request it originated from.
     * @return creationTimestamp The timestamp of content submission.
     * @return averageRating The average rating of the content (0 if no ratings).
     * @return numRatings The number of ratings received.
     */
    function getContentDetails(uint256 _contentId)
        external
        view
        returns (
            uint256 id,
            string memory contentURI,
            string memory contentType,
            address originalSubmitter,
            uint256 originalSeedRequestId,
            uint256 creationTimestamp,
            uint256 averageRating,
            uint256 numRatings
        )
    {
        if (_contentId == 0 || _contentId >= nextContentId) revert MuseMind__InvalidContentId();
        CurationContent storage content = contents[_contentId];
        averageRating = content.numRatings > 0 ? content.totalRating / content.numRatings : 0;
        return (
            content.id,
            content.contentURI,
            content.contentType,
            content.originalSubmitter,
            content.originalSeedRequestId,
            content.creationTimestamp,
            averageRating,
            content.numRatings
        );
    }

    /**
     * @notice Retrieves details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return id The dispute's ID.
     * @return requestId The ID of the seed request under dispute.
     * @return initiator The address of the dispute initiator.
     * @return reason The reason for the dispute.
     * @return status The current status of the dispute.
     * @return aiAgentWins True if AI agent won, false otherwise (only valid if resolved).
     * @return resolutionTimestamp The timestamp of resolution (0 if not resolved).
     * @return resolver The address of the resolver (e.g., owner/governance).
     */
    function getDisputeDetails(uint256 _disputeId)
        external
        view
        returns (
            uint256 id,
            uint256 requestId,
            address initiator,
            string memory reason,
            DisputeStatus status,
            bool aiAgentWins,
            uint256 resolutionTimestamp,
            address resolver
        )
    {
        if (_disputeId == 0 || _disputeId >= nextDisputeId) revert MuseMind__InvalidDisputeId();
        Dispute storage dispute = disputes[_disputeId];
        return (
            dispute.id,
            dispute.requestId,
            dispute.initiator,
            dispute.reason,
            dispute.status,
            dispute.aiAgentWins,
            dispute.resolutionTimestamp,
            dispute.resolver
        );
    }

    /**
     * @notice Retrieves the AI agent ID associated with a given address.
     * @param _agentAddress The address of the AI agent.
     * @return The agent's ID, or 0 if not registered.
     */
    function getAgentIdByAddress(address _agentAddress) external view returns (uint256) {
        return aiAgentAddressToId[_agentAddress];
    }

    /**
     * @notice Retrieves the current staked amount for an AI agent.
     * @param _agentId The ID of the AI agent.
     * @return The staked amount.
     */
    function getAgentStake(uint256 _agentId) external view returns (uint256) {
        if (_agentId == 0 || _agentId >= nextAgentId) revert MuseMind__InvalidAgentId();
        return aiAgents[_agentId].stake;
    }
}
```