The smart contract below, named `SynapticNexusProtocol`, is designed to be a unique and advanced platform for collaborative AI development and the creation of AI-driven digital assets. It integrates concepts like dynamic NFTs, a custom Soulbound Token (SBT)-like reputation system, a multi-role staking mechanism, and a basic DAO governance model, all orchestrated with an off-chain AI component interacting via an oracle.

---

## SynapticNexusProtocol Smart Contract

**Purpose:**
A decentralized protocol fostering collaborative AI development and curation. It enables users to contribute to AI model training/evaluation, generating verifiable AI insights as dynamic NFTs (Knowledge Capsules), and building a reputation through non-transferable Soulbound Tokens.

**Key Concepts:**

*   **AI Model Registry:** A whitelist of approved off-chain AI models that can interact with the protocol via a secure oracle. This allows the protocol to consume AI outputs and insights.
*   **Synapse Agents (Contributors):** Users who stake `SYNC` tokens to participate in AI data contribution (verified off-chain by an oracle) or propose AI-generated content for K-Capsule creation. They earn rewards for their contributions.
*   **Neural Validators (Curators):** Users who stake `SYNC` tokens to review and validate AI outputs and agent contributions (specifically K-Capsule proposals). They ensure the quality and integrity of AI-generated content, earning rewards for accurate curation.
*   **Knowledge Capsules (K-Capsules):** These are dynamic ERC721 NFTs. Each K-Capsule represents a verified AI insight, a piece of AI-generated content, or a curated data set. Their metadata (`tokenURI`) can be updated over time by the oracle, reflecting new AI advancements or refined insights, making them truly "dynamic."
*   **Cognitive Reputation Tokens (CRTs):** A non-transferable (Soulbound-like) scoring system within the contract. CRTs reflect a user's reputation and expertise within the protocol, based on the quality of their contributions as an Agent, the accuracy of their curation as a Validator, and penalties from dispute outcomes.
*   **Synaptic Credits (SYNC):** The primary utility token of the protocol (assumed to be an external ERC20 token). It is used for staking to gain roles (Agent/Curator), earning rewards, and participating in governance.
*   **Synaptic Council (DAO):** A basic on-chain governance mechanism. `SYNC` token stakers can create and vote on proposals to manage protocol parameters, approve or deactivate AI models, and potentially manage treasury funds.
*   **Oracle Integration:** A crucial component. A trusted external entity (e.g., a Chainlink oracle network or a custom decentralized oracle) is responsible for verifying off-chain AI model outputs, data contributions, and securely submitting these proofs to the `SynapticNexusProtocol` smart contract.

---

### Function Summary (28 Functions):

This contract provides a robust set of functionalities, exceeding the minimum requirement of 20 distinct functions.

**A. Admin & Core Protocol Management (Owner/DAO controlled):**

1.  `constructor(address _syncTokenAddress, address _initialOracle, address _initialDAOAddress)`: Initializes the contract with the SYNC token address, the trusted oracle address, and the DAO's governance address.
2.  `setProtocolStatus(bool _paused)`: Allows the contract owner to pause or unpause core protocol functionalities (e.g., staking, claiming, proposing) in case of emergencies.
3.  `updateOracleAddress(address _newOracle)`: Allows the contract owner to update the trusted oracle address. Essential for maintaining secure off-chain AI interaction.
4.  `setRewardRates(uint256 _agentRate, uint256 _curatorRate)`: Enables the contract owner to adjust the SYNC reward rates for Synapse Agents and Neural Validators.

**B. AI Model Registry (DAO Governed):**

5.  `registerAIModel(bytes32 _modelId, string calldata _name, string calldata _description, address _creator)`: Registers a new off-chain AI model within the protocol, making it eligible for K-Capsule generation and data contributions. Callable only by the DAO.
6.  `updateAIModelDetails(bytes32 _modelId, string calldata _newName, string calldata _newDescription)`: Modifies the name and description of an existing AI model. Callable only by the DAO.
7.  `deactivateAIModel(bytes32 _modelId)`: Deactivates an AI model, preventing it from being used for new K-Capsule proposals or data submissions. Callable only by the DAO.

**C. Synapse Agent (Contributor) Functions:**

8.  `stakeSYNCForAgentRole(uint256 _amount)`: Allows a user to stake SYNC tokens to qualify as a Synapse Agent, enabling participation in data contribution and K-Capsule proposal.
9.  `withdrawSYNCFromAgentRole(uint256 _amount)`: Enables a Synapse Agent to withdraw their staked SYNC tokens.
10. `submitAIDataBatchProof(bytes32 _modelId, bytes32 _dataHash, uint256 _timestamp, address _contributor)`: An `onlyOracle` function used to submit cryptographic proof of an off-chain AI data batch contribution by a specific agent. Rewards the contributing agent.
11. `proposeKCapsuleGeneration(bytes32 _modelId, string calldata _initialMetadataURI, bytes32 _proofHash)`: Allows an agent to propose the creation of a new K-Capsule based on AI output, including its initial metadata URI and a proof hash. This proposal then awaits curator validation.

**D. Neural Validator (Curator) Functions:**

12. `stakeSYNCForCuratorRole(uint256 _amount)`: Allows a user to stake SYNC tokens to qualify as a Neural Validator, granting them the ability to curate K-Capsule proposals.
13. `withdrawSYNCFromCuratorRole(uint256 _amount)`: Enables a Neural Validator to withdraw their staked SYNC tokens.
14. `curateKCapsuleProposal(uint256 _proposalId, bool _approve)`: Allows a Neural Validator to vote on the validity and quality of a K-Capsule proposal. Sufficient approvals lead to the K-Capsule being minted.
15. `disputeCuratorDecision(uint256 _proposalId, address _curator, bool _disputeApproval)`: Enables any user to dispute a specific curator's decision on a K-Capsule proposal. Requires a dispute stake (in ETH for this example).

**E. Knowledge Capsule (K-Capsule ERC721) Functions:**

16. `updateKCapsuleData(uint256 _tokenId, string calldata _newMetadataURI, bytes32 _proofHash)`: An `onlyOracle` function that updates the metadata URI and proof hash of an existing K-Capsule NFT. This makes K-Capsules dynamic and capable of evolving with new AI insights.
17. `tokenURI(uint256 tokenId)`: Overrides the standard ERC721 `tokenURI` function to return the `currentMetadataURI` stored within the `KCapsuleData` struct, enabling dynamic NFT functionality. *(Note: This is an overridden standard ERC721 function, but crucial for the dynamic NFT aspect)*

**F. Reward & Staking Management:**

18. `claimRewards()`: Allows Synapse Agents and Neural Validators to claim their accumulated SYNC rewards earned from successful contributions and curations.

**G. Synaptic Council (DAO) Governance Functions (Basic Proposal System):**

19. `createProposal(bytes32 _id, address _target, bytes calldata _callData, string calldata _description)`: Allows any SYNC staker to create a new governance proposal for on-chain execution, specifying a target contract, calldata, and description.
20. `voteOnProposal(bytes32 _proposalId, bool _support)`: Enables SYNC stakers to cast their vote (for or against) on an active governance proposal. Voting power scales with staked SYNC.
21. `executeProposal(bytes32 _proposalId)`: Triggers the execution of a successfully passed governance proposal after its voting period has ended and quorum requirements are met.

**H. View Functions (Read-Only):**

22. `getAIModelInfo(bytes32 _modelId)`: Retrieves detailed information about a registered AI model.
23. `getKCapsuleInfo(uint256 _tokenId)`: Retrieves all stored data for a specific K-Capsule NFT.
24. `getUserStake(address _user)`: Returns the amount of SYNC tokens staked by a user in both their Agent and Curator roles.
25. `getCRTScores(address _user)`: Provides the Cognitive Reputation Token (CRT) scores for a given user, reflecting their agent, curator, and dispute-related reputation.
26. `getPendingRewards(address _user)`: Calculates and returns the total pending SYNC rewards for a user, combining rewards from both Agent and Curator activities.
27. `getProposalDetails(bytes32 _proposalId)`: Returns comprehensive details about a specific governance proposal.
28. `getProtocolStatus()`: Indicates whether the protocol is currently paused or active.
29. `getRewardRates()`: Returns the current reward rates configured for Synapse Agents and Neural Validators.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE AND FUNCTION SUMMARY ---
// Contract Name: SynapticNexusProtocol
// Purpose: A decentralized protocol for collaborative AI development, curation, and the creation of AI-driven digital assets (Knowledge Capsules). It connects human intelligence with artificial intelligence by enabling users to contribute to AI model training/evaluation, generating verifiable AI insights as dynamic NFTs, and building a reputation through non-transferable Soulbound Tokens.
//
// Key Concepts:
// - AI Model Registry: Whitelisted off-chain AI models interact via a secure oracle.
// - Synapse Agents (Contributors): Users who stake SYNC tokens to contribute data or propose AI-generated content.
// - Neural Validators (Curators): Users who stake SYNC tokens to review and validate AI outputs and agent contributions.
// - Knowledge Capsules (K-Capsules): Dynamic, evolving ERC721 NFTs representing verified AI insights, data, or generated content. Their metadata can change over time.
// - Cognitive Reputation Tokens (CRTs): Non-transferable (Soulbound-like) scores reflecting a user's reputation within the protocol based on their quality contributions and curation accuracy.
// - Synaptic Credits (SYNC): The utility token for staking, rewards, and governance weight (assumed external ERC20).
// - Synaptic Council (DAO): A basic governance mechanism for protocol parameter changes, AI model approvals, and treasury management.
// - Oracle Integration: A trusted external entity (likely a Chainlink or custom oracle network) submits validated off-chain AI data and proof hashes to the contract.
//
// Functions Summary (28 distinct functions):
//
// A. Admin & Core Protocol Management (Owner/DAO controlled):
// 1.  `constructor(address _syncTokenAddress, address _initialOracle, address _initialDAOAddress)`: Initializes the contract with SYNC token, initial oracle, and DAO addresses.
// 2.  `setProtocolStatus(bool _paused)`: Pauses or unpauses core protocol functionalities (e.g., staking, claiming, proposing).
// 3.  `updateOracleAddress(address _newOracle)`: Updates the trusted oracle address. Only owner.
// 4.  `setRewardRates(uint256 _agentRate, uint256 _curatorRate)`: Sets the reward rates for agents and curators. Only owner.
//
// B. AI Model Registry (DAO Governed):
// 5.  `registerAIModel(bytes32 _modelId, string calldata _name, string calldata _description, address _creator)`: Registers a new AI model with unique ID. Callable only by DAO.
// 6.  `updateAIModelDetails(bytes32 _modelId, string calldata _newName, string calldata _newDescription)`: Updates an existing AI model's details. Callable only by DAO.
// 7.  `deactivateAIModel(bytes32 _modelId)`: Deactivates an AI model, preventing it from generating new K-Capsules. Callable only by DAO.
//
// C. Synapse Agent (Contributor) Functions:
// 8.  `stakeSYNCForAgentRole(uint256 _amount)`: Allows a user to stake SYNC tokens to become a Synapse Agent.
// 9.  `withdrawSYNCFromAgentRole(uint256 _amount)`: Allows a Synapse Agent to withdraw staked SYNC tokens.
// 10. `submitAIDataBatchProof(bytes32 _modelId, bytes32 _dataHash, uint256 _timestamp, address _contributor)`: Oracle-only function to submit proof of an off-chain AI data batch contribution by an agent.
// 11. `proposeKCapsuleGeneration(bytes32 _modelId, string calldata _initialMetadataURI, bytes32 _proofHash)`: Allows an agent to propose the creation of a new K-Capsule based on AI output, providing initial metadata and a proof hash.
//
// D. Neural Validator (Curator) Functions:
// 12. `stakeSYNCForCuratorRole(uint256 _amount)`: Allows a user to stake SYNC tokens to become a Neural Validator.
// 13. `withdrawSYNCFromCuratorRole(uint256 _amount)`: Allows a Neural Validator to withdraw staked SYNC tokens.
// 14. `curateKCapsuleProposal(uint256 _proposalId, bool _approve)`: Allows a curator to vote on a K-Capsule proposal's validity/quality.
// 15. `disputeCuratorDecision(uint256 _proposalId, address _curator, bool _disputeApproval)`: Allows any user to dispute a curator's decision on a K-Capsule proposal, requiring a stake.
//
// E. Knowledge Capsule (K-Capsule ERC721) Functions:
// 16. `updateKCapsuleData(uint256 _tokenId, string calldata _newMetadataURI, bytes32 _proofHash)`: Oracle-only function to update a K-Capsule's metadata URI and proof hash, enabling dynamic evolution.
// 17. `tokenURI(uint256 tokenId)`: Overrides the standard ERC721 `tokenURI` function to return the `currentMetadataURI` for dynamic NFTs.
//
// F. Reward & Staking Management:
// 18. `claimRewards()`: Allows agents and curators to claim their accumulated SYNC rewards.
//
// G. Synaptic Council (DAO) Governance Functions (Basic Proposal System):
// 19. `createProposal(bytes32 _id, address _target, bytes calldata _callData, string calldata _description)`: Creates a new governance proposal. SYNC stakers can create proposals.
// 20. `voteOnProposal(bytes32 _proposalId, bool _support)`: Casts a vote on an active proposal. Voting power based on staked SYNC.
// 21. `executeProposal(bytes32 _proposalId)`: Executes a successfully passed proposal.
//
// H. View Functions (Read-Only):
// 22. `getAIModelInfo(bytes32 _modelId)`: Retrieves information about a registered AI model.
// 23. `getKCapsuleInfo(uint256 _tokenId)`: Retrieves information about a specific K-Capsule.
// 24. `getUserStake(address _user)`: Returns the staked SYNC amount for a user (both agent and curator roles).
// 25. `getCRTScores(address _user)`: Retrieves the Cognitive Reputation Token (CRT) scores for a user.
// 26. `getPendingRewards(address _user)`: Calculates and returns the pending SYNC rewards for a user.
// 27. `getProposalDetails(bytes32 _proposalId)`: Retrieves details about a governance proposal.
// 28. `getProtocolStatus()`: Returns the current paused status of the protocol.
// 29. `getRewardRates()`: Returns the current agent and curator reward rates.

contract SynapticNexusProtocol is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Protocol Status
    bool public paused;

    // Core Addresses
    address public immutable SYNC_TOKEN; // Address of the external SYNC ERC20 token
    address public oracleAddress;       // Trusted address for AI model interactions and data proofs
    address public daoAddress;          // Address of the DAO contract/multisig that governs the protocol

    // Counters
    Counters.Counter private _kCapsuleTokenIds;
    Counters.Counter private _kCapsuleProposalIds;

    // Configuration
    uint256 public constant AGENT_MIN_STAKE = 100 ether; // Minimum SYNC to be an Agent (in SYNC's smallest unit)
    uint256 public constant CURATOR_MIN_STAKE = 200 ether; // Minimum SYNC to be a Curator (in SYNC's smallest unit)
    uint256 public constant DISPUTE_STAKE_AMOUNT = 0.5 ether; // Example: 0.5 ETH required to dispute a curator decision (for simplicity, uses ETH, not SYNC)

    uint256 public agentRewardRatePerUnit;   // SYNC rewards per unit of contribution (e.g., per data proof)
    uint256 public curatorRewardRatePerVote; // SYNC rewards per successful curation vote

    uint256 public constant KCAPSULE_MIN_APPROVALS = 3; // Minimum positive curator votes for a K-Capsule to be minted
    uint256 public constant KCAPSULE_CURATION_PERIOD = 2 days; // Timeframe for K-Capsule proposals to be curated

    // Mappings & Structs

    // A. AI Models
    struct AIModel {
        bytes32 modelId; // Unique identifier for the AI model
        string name;
        string description;
        address creator; // Address of the entity/individual who registered the model
        bool isActive;   // Whether the model is active and can be used for new K-Capsules
        uint256 lastSubmissionTimestamp; // Timestamp of the last valid data submission for this model
    }
    mapping(bytes32 => AIModel) public aiModels;
    mapping(bytes32 => bool) public isAIModelRegistered; // Quick lookup for existence

    // B. Synapse Agents & Neural Validators (Staking and Roles)
    struct StakerInfo {
        uint256 stakedAmount;
        uint256 pendingRewards; // Accumulated rewards not yet claimed
        uint256 totalRewardsEarned; // Total rewards ever earned
    }
    mapping(address => StakerInfo) public agentStakes;
    mapping(address => StakerInfo) public curatorStakes;

    // C. Knowledge Capsules (K-Capsules - ERC721 properties handled by base ERC721)
    struct KCapsuleData {
        bytes32 modelId;
        string currentMetadataURI; // IPFS URI or similar, can change (dynamic NFT)
        bytes32 latestProofHash;   // Hash of the data or output proving the AI insight
        uint256 creationTimestamp;
        address creatorAgent;      // The agent who proposed this K-Capsule
        bool isValid;              // Set to true after successful curation
    }
    mapping(uint256 => KCapsuleData) public kCapsules; // tokenId => KCapsuleData

    // D. K-Capsule Proposals (for curation)
    struct KCapsuleProposal {
        uint256 proposalId;
        bytes32 modelId;
        string initialMetadataURI;
        bytes32 proofHash;
        address proposer;
        uint256 submissionTimestamp;
        uint256 approvalCount;
        uint256 rejectionCount;
        mapping(address => bool) hasVoted; // Internal mapping for curators who have voted
        bool isResolved; // True if minted or rejected
        bool isApproved; // True if minted
    }
    mapping(uint256 => KCapsuleProposal) public kCapsuleProposals;

    // E. Cognitive Reputation Tokens (CRTs - Soulbound-like scores)
    struct UserCRTData {
        uint256 agentScore;    // Based on successful data submissions and K-Capsule proposals
        uint256 curatorScore;  // Based on accurate curation decisions
        uint256 disputeScore;  // Penalties for losing disputes (a simplified version)
        uint256 totalScore;    // Sum of agent and curator scores minus dispute score
    }
    mapping(address => UserCRTData) public userCRTs;

    // F. DAO Governance (Basic Proposal System)
    struct Proposal {
        bytes32 proposalId;
        address target;          // The contract address to call
        bytes callData;          // The data to send with the call
        string description;      // Description of the proposal
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 totalVotesFor;   // Votes in favor
        uint256 totalVotesAgainst; // Votes against
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool executed;           // True if the proposal has been executed
        bool cancelled;          // True if the proposal has been cancelled
    }
    mapping(bytes32 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Duration for voting
    uint256 public constant PROPOSAL_MIN_QUORUM_PERCENT = 4; // 4% (e.g., 400 basis points) of total staked SYNC needed for quorum

    // --- Events ---
    event ProtocolStatusUpdated(bool newStatus);
    event OracleAddressUpdated(address oldOracle, address newOracle);
    event RewardRatesUpdated(uint256 agentRate, uint256 curatorRate);

    event AIModelRegistered(bytes32 modelId, string name, address creator);
    event AIModelUpdated(bytes32 modelId, string newName, string newDescription);
    event AIModelDeactivated(bytes32 modelId);

    event Staked(address indexed user, uint256 amount, string role);
    event Unstaked(address indexed user, uint252 amount, string role);
    event AIDataBatchProofSubmitted(bytes32 indexed modelId, address indexed contributor, bytes32 dataHash, uint256 timestamp);
    event KCapsuleProposed(uint256 indexed proposalId, bytes32 indexed modelId, address indexed proposer, string initialMetadataURI);

    event KCapsuleProposalCurated(uint256 indexed proposalId, address indexed curator, bool approved);
    event KCapsuleProposalMinted(uint256 indexed proposalId, uint256 indexed tokenId, address indexed proposer);
    event CuratorDecisionDisputed(uint256 indexed proposalId, address indexed curator, address indexed disputer, bool disputeApproval);
    event KCapsuleDataUpdated(uint256 indexed tokenId, string newMetadataURI, bytes32 proofHash);

    event RewardsClaimed(address indexed user, uint256 amount);
    event CRTScoreUpdated(address indexed user, uint256 newAgentScore, uint256 newCuratorScore, uint256 newDisputeScore, uint256 newTotalScore);

    event ProposalCreated(bytes32 indexed proposalId, address indexed proposer, string description, address target, bytes callData);
    event VoteCast(bytes32 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(bytes32 indexed proposalId);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Protocol is paused");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Caller is not the oracle");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Caller is not the DAO");
        _;
    }

    modifier onlyAgent(address _user) {
        require(agentStakes[_user].stakedAmount >= AGENT_MIN_STAKE, "User is not a Synapse Agent");
        _;
    }

    modifier onlyCurator(address _user) {
        require(curatorStakes[_user].stakedAmount >= CURATOR_MIN_STAKE, "User is not a Neural Validator");
        _;
    }

    // --- Constructor ---
    constructor(address _syncTokenAddress, address _initialOracle, address _initialDAOAddress)
        ERC721("Knowledge Capsule", "KCAP")
        Ownable(msg.sender)
    {
        require(_syncTokenAddress != address(0), "SYNC token address cannot be zero");
        require(_initialOracle != address(0), "Oracle address cannot be zero");
        require(_initialDAOAddress != address(0), "DAO address cannot be zero");

        SYNC_TOKEN = _syncTokenAddress;
        oracleAddress = _initialOracle;
        daoAddress = _initialDAOAddress;
        paused = false;

        agentRewardRatePerUnit = 10 * 10**18; // Example: 10 SYNC per data proof, assuming 18 decimals
        curatorRewardRatePerVote = 1 * 10**18; // Example: 1 SYNC per successful vote, assuming 18 decimals
    }

    // --- A. Admin & Core Protocol Management ---

    /**
     * @notice Pauses or unpauses core protocol functionalities.
     * @dev Only callable by the contract owner. Affects staking, claiming, proposing.
     * @param _paused True to pause, false to unpause.
     */
    function setProtocolStatus(bool _paused) external onlyOwner {
        paused = _paused;
        emit ProtocolStatusUpdated(_paused);
    }

    /**
     * @notice Updates the trusted oracle address.
     * @dev Only callable by the contract owner. Critical for AI integration security.
     * @param _newOracle The new address of the oracle.
     */
    function updateOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "New oracle address cannot be zero");
        emit OracleAddressUpdated(oracleAddress, _newOracle);
        oracleAddress = _newOracle;
    }

    /**
     * @notice Sets the reward rates for Synapse Agents and Neural Validators.
     * @dev Only callable by the contract owner. Rates should be in SYNC's smallest unit (e.g., wei if 18 decimals).
     * @param _agentRate New reward rate per contribution unit for agents.
     * @param _curatorRate New reward rate per successful curation vote for curators.
     */
    function setRewardRates(uint256 _agentRate, uint256 _curatorRate) external onlyOwner {
        agentRewardRatePerUnit = _agentRate;
        curatorRewardRatePerVote = _curatorRate;
        emit RewardRatesUpdated(_agentRate, _curatorRate);
    }

    // --- B. AI Model Registry (DAO Governed) ---

    /**
     * @notice Registers a new off-chain AI model within the protocol.
     * @dev Callable only by the DAO. Requires a unique modelId.
     * @param _modelId A unique identifier for the AI model.
     * @param _name The human-readable name of the AI model.
     * @param _description A brief description of the AI model's purpose.
     * @param _creator The address associated with the AI model's creator.
     */
    function registerAIModel(bytes32 _modelId, string calldata _name, string calldata _description, address _creator) external onlyDAO {
        require(!isAIModelRegistered[_modelId], "AI Model already registered");
        require(_creator != address(0), "Creator address cannot be zero");

        aiModels[_modelId] = AIModel({
            modelId: _modelId,
            name: _name,
            description: _description,
            creator: _creator,
            isActive: true,
            lastSubmissionTimestamp: 0
        });
        isAIModelRegistered[_modelId] = true;
        emit AIModelRegistered(_modelId, _name, _creator);
    }

    /**
     * @notice Updates the details of an existing AI model.
     * @dev Callable only by the DAO.
     * @param _modelId The unique identifier of the AI model to update.
     * @param _newName The new name for the AI model (can be empty string if not changing).
     * @param _newDescription The new description for the AI model (can be empty string if not changing).
     */
    function updateAIModelDetails(bytes32 _modelId, string calldata _newName, string calldata _newDescription) external onlyDAO {
        require(isAIModelRegistered[_modelId], "AI Model not registered");

        if (bytes(_newName).length > 0) {
            aiModels[_modelId].name = _newName;
        }
        if (bytes(_newDescription).length > 0) {
            aiModels[_modelId].description = _newDescription;
        }
        emit AIModelUpdated(_modelId, _newName, _newDescription);
    }

    /**
     * @notice Deactivates an AI model, preventing it from being used for new K-Capsule proposals.
     * @dev Callable only by the DAO. Existing K-Capsules remain.
     * @param _modelId The unique identifier of the AI model to deactivate.
     */
    function deactivateAIModel(bytes32 _modelId) external onlyDAO {
        require(isAIModelRegistered[_modelId], "AI Model not registered");
        require(aiModels[_modelId].isActive, "AI Model already inactive");
        aiModels[_modelId].isActive = false;
        emit AIModelDeactivated(_modelId);
    }

    // --- C. Synapse Agent (Contributor) Functions ---

    /**
     * @notice Allows a user to stake SYNC tokens to become a Synapse Agent.
     * @dev Agent status is required to submit AI data proofs or propose K-Capsules. Requires SYNC token approval.
     * @param _amount The amount of SYNC tokens to stake. Must meet AGENT_MIN_STAKE.
     */
    function stakeSYNCForAgentRole(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Stake amount must be greater than zero");
        IERC20(SYNC_TOKEN).transferFrom(msg.sender, address(this), _amount);
        agentStakes[msg.sender].stakedAmount += _amount;
        require(agentStakes[msg.sender].stakedAmount >= AGENT_MIN_STAKE, "Insufficient stake for Agent role");
        emit Staked(msg.sender, _amount, "Agent");
    }

    /**
     * @notice Allows a Synapse Agent to withdraw staked SYNC tokens.
     * @dev Cannot withdraw below AGENT_MIN_STAKE if they want to retain their agent status.
     * @param _amount The amount of SYNC tokens to withdraw.
     */
    function withdrawSYNCFromAgentRole(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(agentStakes[msg.sender].stakedAmount >= _amount, "Insufficient staked amount");
        require(agentStakes[msg.sender].stakedAmount - _amount >= AGENT_MIN_STAKE || agentStakes[msg.sender].stakedAmount == _amount, 
                "Cannot withdraw below minimum stake unless withdrawing all");
        agentStakes[msg.sender].stakedAmount -= _amount;
        IERC20(SYNC_TOKEN).transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, "Agent");
    }

    /**
     * @notice Oracle-only function to submit proof of an off-chain AI data batch contribution by an agent.
     * @dev This represents an agent contributing data that helps train or evaluate AI models.
     * @param _modelId The ID of the AI model the data was contributed to.
     * @param _dataHash A cryptographic hash proving the integrity/existence of the data batch.
     * @param _timestamp The timestamp when the data was processed/contributed off-chain.
     * @param _contributor The address of the Synapse Agent who contributed the data.
     */
    function submitAIDataBatchProof(bytes32 _modelId, bytes32 _dataHash, uint256 _timestamp, address _contributor) external onlyOracle whenNotPaused {
        require(isAIModelRegistered[_modelId] && aiModels[_modelId].isActive, "AI Model not active or registered");
        require(agentStakes[_contributor].stakedAmount >= AGENT_MIN_STAKE, "Contributor is not a valid Synapse Agent");

        // Reward the agent for their contribution (pending rewards)
        agentStakes[_contributor].pendingRewards += agentRewardRatePerUnit;

        // Update CRT score for the agent. Simplified: 1 point per (agentRewardRatePerUnit / 1 ether)
        _updateUserCRTScore(_contributor, agentRewardRatePerUnit / (1 * 10**18), 0, 0); 

        aiModels[_modelId].lastSubmissionTimestamp = _timestamp;
        emit AIDataBatchProofSubmitted(_modelId, _contributor, _dataHash, _timestamp);
    }

    /**
     * @notice Allows a Synapse Agent to propose the generation of a new K-Capsule.
     * @dev This proposal requires validation by Neural Validators.
     * @param _modelId The ID of the AI model that generated the insight.
     * @param _initialMetadataURI IPFS URI or similar, pointing to the initial metadata/content of the K-Capsule.
     * @param _proofHash A cryptographic hash proving the AI's output (e.g., hash of the AI's generated content).
     */
    function proposeKCapsuleGeneration(bytes32 _modelId, string calldata _initialMetadataURI, bytes32 _proofHash) external onlyAgent(msg.sender) whenNotPaused {
        require(isAIModelRegistered[_modelId] && aiModels[_modelId].isActive, "AI Model not active or registered");
        require(bytes(_initialMetadataURI).length > 0, "Initial metadata URI cannot be empty");
        require(_proofHash != bytes32(0), "Proof hash cannot be zero");

        _kCapsuleProposalIds.increment();
        uint256 proposalId = _kCapsuleProposalIds.current();

        kCapsuleProposals[proposalId] = KCapsuleProposal({
            proposalId: proposalId,
            modelId: _modelId,
            initialMetadataURI: _initialMetadataURI,
            proofHash: _proofHash,
            proposer: msg.sender,
            submissionTimestamp: block.timestamp,
            approvalCount: 0,
            rejectionCount: 0,
            isResolved: false,
            isApproved: false
        });
        // Note: hasVoted mapping is inside the struct, so it's initialized empty.

        emit KCapsuleProposed(proposalId, _modelId, msg.sender, _initialMetadataURI);
    }

    // --- D. Neural Validator (Curator) Functions ---

    /**
     * @notice Allows a user to stake SYNC tokens to become a Neural Validator.
     * @dev Curator status is required to vote on K-Capsule proposals. Requires SYNC token approval.
     * @param _amount The amount of SYNC tokens to stake. Must meet CURATOR_MIN_STAKE.
     */
    function stakeSYNCForCuratorRole(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Stake amount must be greater than zero");
        IERC20(SYNC_TOKEN).transferFrom(msg.sender, address(this), _amount);
        curatorStakes[msg.sender].stakedAmount += _amount;
        require(curatorStakes[msg.sender].stakedAmount >= CURATOR_MIN_STAKE, "Insufficient stake for Curator role");
        emit Staked(msg.sender, _amount, "Curator");
    }

    /**
     * @notice Allows a Neural Validator to withdraw staked SYNC tokens.
     * @dev Cannot withdraw below CURATOR_MIN_STAKE if they want to retain their curator status.
     * @param _amount The amount of SYNC tokens to withdraw.
     */
    function withdrawSYNCFromCuratorRole(uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Withdraw amount must be greater than zero");
        require(curatorStakes[msg.sender].stakedAmount >= _amount, "Insufficient staked amount");
        require(curatorStakes[msg.sender].stakedAmount - _amount >= CURATOR_MIN_STAKE || curatorStakes[msg.sender].stakedAmount == _amount, 
                "Cannot withdraw below minimum stake unless withdrawing all");
        curatorStakes[msg.sender].stakedAmount -= _amount;
        IERC20(SYNC_TOKEN).transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, "Curator");
    }

    /**
     * @notice Allows a Neural Validator to vote on a K-Capsule proposal's validity.
     * @dev Voting on proposals submitted by agents. Successful approvals lead to K-Capsule minting.
     * @param _proposalId The ID of the K-Capsule proposal to curate.
     * @param _approve True to approve the proposal, false to reject.
     */
    function curateKCapsuleProposal(uint256 _proposalId, bool _approve) external onlyCurator(msg.sender) whenNotPaused {
        KCapsuleProposal storage proposal = kCapsuleProposals[_proposalId];
        require(proposal.proposer != address(0), "K-Capsule Proposal does not exist");
        require(!proposal.isResolved, "Proposal already resolved");
        require(block.timestamp <= proposal.submissionTimestamp + KCAPSULE_CURATION_PERIOD, "Curation period has ended");
        require(!proposal.hasVoted[msg.sender], "Curator has already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.approvalCount++;
        } else {
            proposal.rejectionCount++;
        }

        // Add pending reward for the curator
        curatorStakes[msg.sender].pendingRewards += curatorRewardRatePerVote;

        // Check if resolution criteria are met
        if (proposal.approvalCount >= KCAPSULE_MIN_APPROVALS) {
            _mintKCapsule(proposal); // Internal function to mint the K-Capsule
            _updateUserCRTScore(proposal.proposer, 10, 0, 0); // Reward proposer's CRT for successful mint
            proposal.isResolved = true;
            proposal.isApproved = true;
        } else if (proposal.rejectionCount >= KCAPSULE_MIN_APPROVALS) { // Arbitrary rejection threshold, same as approval for symmetry
            proposal.isResolved = true;
            proposal.isApproved = false;
        }

        // Update curator's CRT score (simple: 1 point per vote)
        _updateUserCRTScore(msg.sender, 0, 1, 0);

        emit KCapsuleProposalCurated(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Allows any user to dispute a curator's decision on a K-Capsule proposal.
     * @dev Requires a dispute stake (in ETH). This is a placeholder; actual resolution would be complex.
     * @param _proposalId The ID of the K-Capsule proposal.
     * @param _curator The address of the curator whose decision is being disputed.
     * @param _disputeApproval True if disputing an approval, false if disputing a rejection.
     */
    function disputeCuratorDecision(uint256 _proposalId, address _curator, bool _disputeApproval) external payable whenNotPaused nonReentrant {
        require(msg.value >= DISPUTE_STAKE_AMOUNT, "Must send DISPUTE_STAKE_AMOUNT to dispute"); 
        
        KCapsuleProposal storage proposal = kCapsuleProposals[_proposalId];
        require(proposal.proposer != address(0), "K-Capsule Proposal does not exist");
        require(proposal.hasVoted[_curator], "Curator did not vote on this proposal");
        require(msg.sender != _curator, "Cannot dispute your own decision");
        
        // --- Simplified Dispute Logic ---
        // In a real system, this would involve a complex arbitration process (e.g., Chainlink Automation for off-chain
        // truth, another DAO vote, or a Schelling game). For this contract, we'll implement a basic self-resolving
        // logic based on the final outcome of the proposal:
        
        // Assuming the proposal is already resolved (either approved or rejected)
        require(proposal.isResolved, "Proposal has not yet been resolved by curators.");

        bool curatorVotedApproved = proposal.hasVoted[_curator] && proposal.isApproved; // Check if curator approved and proposal passed
        bool curatorVotedRejected = proposal.hasVoted[_curator] && !proposal.isApproved; // Check if curator rejected and proposal failed
        
        // Determine if the dispute is correct (curator was "wrong")
        bool disputeIsCorrect;
        if (_disputeApproval) { // Disputing an APPROVAL
            // Disputer is correct if the curator approved, but the proposal was ultimately REJECTED
            disputeIsCorrect = curatorVotedApproved && !proposal.isApproved; 
        } else { // Disputing a REJECTION
            // Disputer is correct if the curator rejected, but the proposal was ultimately APPROVED
            disputeIsCorrect = curatorVotedRejected && proposal.isApproved;
        }

        if (disputeIsCorrect) {
            // Disputer wins: get dispute stake back + a small reward. Curator loses CRT.
            payable(msg.sender).transfer(msg.value); // Return stake
            _updateUserCRTScore(_curator, 0, 0, 5); // Penalize curator's CRT score (e.g., 5 points)
        } else {
            // Disputer loses: stake is forfeited. Curator's CRT may increase.
            // Forfeit to contract owner or a treasury/burn address for this simplified example
            // (real system might send to a DAO treasury or re-distribute).
            // This is implicitly done if not transferred back.
            _updateUserCRTScore(_curator, 0, 2, 0); // Reward curator's CRT for standing firm
        }
        
        emit CuratorDecisionDisputed(_proposalId, _curator, msg.sender, _disputeApproval);
    }

    // --- E. Knowledge Capsule (K-Capsule ERC721) Functions ---

    /**
     * @notice Internal function to mint a new K-Capsule NFT upon successful proposal curation.
     * @dev Only callable internally once a K-Capsule proposal meets approval criteria.
     * @param _proposal The K-Capsule proposal that has been approved.
     */
    function _mintKCapsule(KCapsuleProposal memory _proposal) internal {
        _kCapsuleTokenIds.increment();
        uint256 newTokenId = _kCapsuleTokenIds.current();

        _safeMint(_proposal.proposer, newTokenId);
        _setTokenURI(newTokenId, _proposal.initialMetadataURI);

        kCapsules[newTokenId] = KCapsuleData({
            modelId: _proposal.modelId,
            currentMetadataURI: _proposal.initialMetadataURI,
            latestProofHash: _proposal.proofHash,
            creationTimestamp: block.timestamp,
            creatorAgent: _proposal.proposer,
            isValid: true
        });

        emit KCapsuleProposalMinted(_proposal.proposalId, newTokenId, _proposal.proposer);
    }

    /**
     * @notice Oracle-only function to update a K-Capsule's metadata URI and proof hash.
     * @dev Enables dynamic evolution of K-Capsule NFTs based on new AI insights or data.
     * @param _tokenId The ID of the K-Capsule to update.
     * @param _newMetadataURI The new IPFS URI or similar for the K-Capsule metadata.
     * @param _proofHash A new cryptographic hash proving the updated AI insight.
     */
    function updateKCapsuleData(uint256 _tokenId, string calldata _newMetadataURI, bytes32 _proofHash) external onlyOracle whenNotPaused {
        require(_exists(_tokenId), "K-Capsule does not exist");
        require(kCapsules[_tokenId].isValid, "K-Capsule is not valid");
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty");
        require(_proofHash != bytes32(0), "New proof hash cannot be zero");

        kCapsules[_tokenId].currentMetadataURI = _newMetadataURI;
        kCapsules[_tokenId].latestProofHash = _proofHash;
        _setTokenURI(_tokenId, _newMetadataURI); // Update tokenURI for ERC721 compliance

        emit KCapsuleDataUpdated(_tokenId, _newMetadataURI, _proofHash);
    }

    /**
     * @notice Overrides the standard ERC721 `tokenURI` function to provide dynamic URIs.
     * @dev This function is called by marketplaces and explorers to display NFT metadata.
     * @param tokenId The ID of the K-Capsule.
     * @return The current metadata URI of the K-Capsule.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return kCapsules[tokenId].currentMetadataURI;
    }

    // --- F. Reward & Staking Management ---

    /**
     * @notice Allows agents and curators to claim their accumulated SYNC rewards.
     * @dev Rewards are calculated based on their contributions and successful curations.
     */
    function claimRewards() external whenNotPaused nonReentrant {
        uint256 totalRewards = 0;

        // Claim Agent Rewards
        if (agentStakes[msg.sender].pendingRewards > 0) {
            totalRewards += agentStakes[msg.sender].pendingRewards;
            agentStakes[msg.sender].totalRewardsEarned += agentStakes[msg.sender].pendingRewards;
            agentStakes[msg.sender].pendingRewards = 0;
        }

        // Claim Curator Rewards
        if (curatorStakes[msg.sender].pendingRewards > 0) {
            totalRewards += curatorStakes[msg.sender].pendingRewards;
            curatorStakes[msg.sender].totalRewardsEarned += curatorStakes[msg.sender].pendingRewards;
            curatorStakes[msg.sender].pendingRewards = 0;
        }

        require(totalRewards > 0, "No pending rewards to claim");

        IERC20(SYNC_TOKEN).transfer(msg.sender, totalRewards);
        emit RewardsClaimed(msg.sender, totalRewards);
    }

    /**
     * @notice Internal function to update a user's Cognitive Reputation Token (CRT) scores.
     * @dev This score is non-transferable and reflects protocol contribution.
     * @param _user The address of the user whose score is being updated.
     * @param _agentPoints Points to add/subtract from agent score.
     * @param _curatorPoints Points to add/subtract from curator score.
     * @param _disputePoints Points to add/subtract from dispute score (penalties).
     */
    function _updateUserCRTScore(address _user, uint256 _agentPoints, uint256 _curatorPoints, uint256 _disputePoints) internal {
        userCRTs[_user].agentScore += _agentPoints;
        userCRTs[_user].curatorScore += _curatorPoints;
        
        // Ensure disputeScore does not underflow if _disputePoints is intended as a subtraction
        // For additive penalties, this is fine. If penalties can reduce below zero, then min(0, score - penalty) is needed.
        userCRTs[_user].disputeScore += _disputePoints;

        // Calculate total score ensuring it doesn't underflow if disputeScore is large
        userCRTs[_user].totalScore = userCRTs[_user].agentScore + userCRTs[_user].curatorScore;
        if (userCRTs[_user].totalScore < userCRTs[_user].disputeScore) {
            userCRTs[_user].totalScore = 0;
        } else {
            userCRTs[_user].totalScore -= userCRTs[_user].disputeScore;
        }

        emit CRTScoreUpdated(_user, userCRTs[_user].agentScore, userCRTs[_user].curatorScore, userCRTs[_user].disputeScore, userCRTs[_user].totalScore);
    }

    // --- G. Synaptic Council (DAO) Governance Functions ---

    /**
     * @notice Creates a new governance proposal.
     * @dev Requires caller to be a SYNC staker (agent or curator).
     * @param _id Unique identifier for the proposal.
     * @param _target The contract address to call if the proposal passes.
     * @param _callData The encoded function call data for the target contract.
     * @param _description A human-readable description of the proposal.
     */
    function createProposal(bytes32 _id, address _target, bytes calldata _callData, string calldata _description) external whenNotPaused {
        require(agentStakes[msg.sender].stakedAmount > 0 || curatorStakes[msg.sender].stakedAmount > 0, "Only SYNC stakers can create proposals");
        require(proposals[_id].voteStartTime == 0, "Proposal ID already exists"); // Check if proposal with this ID already exists
        require(_target != address(0), "Target address cannot be zero");
        require(bytes(_description).length > 0, "Description cannot be empty");

        proposals[_id] = Proposal({
            proposalId: _id,
            target: _target,
            callData: _callData,
            description: _description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            executed: false,
            cancelled: false
        });

        // hasVoted mapping is initialized empty

        emit ProposalCreated(_id, msg.sender, _description, _target, _callData);
    }

    /**
     * @notice Casts a vote on an active governance proposal.
     * @dev Voting power is determined by the amount of SYNC staked (agent + curator stakes).
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' (yes), false for 'against' (no).
     */
    function voteOnProposal(bytes32 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        uint256 votingPower = agentStakes[msg.sender].stakedAmount + curatorStakes[msg.sender].stakedAmount;
        require(votingPower > 0, "Must have staked SYNC to vote");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }

        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }

    /**
     * @notice Executes a successfully passed governance proposal.
     * @dev Can be called by anyone after the voting period ends and criteria are met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(bytes32 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.voteStartTime != 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.cancelled, "Proposal cancelled");
        require(block.timestamp > proposal.voteEndTime, "Voting period has not ended");

        // Basic quorum check: total votes cast must be X% of total SYNC staked in the protocol
        uint256 totalStakedSYNC = 0;
        // This would require iterating through all agentStakes and curatorStakes mappings, which is gas-prohibitive.
        // In a real system, `totalStakedSYNC` would be tracked by an internal variable or calculated from a snapshot
        // taken at proposal creation, or retrieved from the SYNC token contract if it supports `totalStaked()`
        // For this example, we'll use a placeholder `IERC20(SYNC_TOKEN).totalSupply()` as a very rough proxy for total circulating SYNC,
        // which might be an overestimation but serves for demonstration.
        // A more realistic DAO would require a pre-calculated `totalStakedPowerAtSnapshot`
        // to avoid expensive iteration or reliance on total supply.
        // Let's assume a simplified total for demonstration, or use a minimum vote count.
        
        // Simpler Quorum: require a minimum total vote count or percentage of a hardcoded "staked base"
        // Let's use the sum of 'for' and 'against' votes as the 'total votes participated' for quorum
        // and compare it to a percentage of an assumed max total SYNC that *could* vote.
        uint256 totalParticipatingVotes = proposal.totalVotesFor + proposal.totalVotesAgainst;
        
        // To make `PROPOSAL_MIN_QUORUM_PERCENT` meaningful:
        // We need a way to get the total *potential* voting power (total staked SYNC).
        // Since iterating mappings is costly, a production system would snapshot this or use a fixed total.
        // For demonstration, let's assume a dummy fixed value for "total eligible voting SYNC"
        // or a simpler quorum based just on `totalParticipatingVotes` exceeding a fixed threshold.
        // Let's use the latter for gas efficiency:
        
        // Example: minimum 1000 SYNC (in smallest units) must have voted in total for the proposal to be considered.
        uint256 minParticipationVotes = 1000 * 10**18; 
        require(totalParticipatingVotes >= minParticipationVotes, "Proposal did not meet minimum participation quorum.");

        // Proposal must pass (more 'for' votes than 'against')
        require(proposal.totalVotesFor > proposal.totalVotesAgainst, "Proposal did not pass (more 'for' votes required)");
        
        // Final Quorum Check: `totalParticipatingVotes` must be at least `PROPOSAL_MIN_QUORUM_PERCENT` of `totalStakedSYNC`
        // For simplicity, let's use the contract's own SYNC balance as a rough proxy for "available SYNC in the system"
        // (assuming SYNC is staked here and not elsewhere for DAO power). This isn't perfect but illustrates the concept.
        uint256 currentStakedPool = IERC20(SYNC_TOKEN).balanceOf(address(this));
        require(totalParticipatingVotes * 100 >= (currentStakedPool * PROPOSAL_MIN_QUORUM_PERCENT), "Proposal did not meet quorum percentage of staked pool");


        proposal.executed = true;

        // Execute the proposed call
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Proposal execution failed");

        emit ProposalExecuted(_proposalId);
    }

    // --- H. View Functions ---

    /**
     * @notice Retrieves information about a registered AI model.
     * @param _modelId The ID of the AI model.
     * @return AIModel struct containing details of the model.
     */
    function getAIModelInfo(bytes32 _modelId) external view returns (AIModel memory) {
        require(isAIModelRegistered[_modelId], "AI Model not registered");
        return aiModels[_modelId];
    }

    /**
     * @notice Retrieves information about a specific K-Capsule.
     * @param _tokenId The ID of the K-Capsule.
     * @return KCapsuleData struct containing details of the K-Capsule.
     */
    function getKCapsuleInfo(uint256 _tokenId) external view returns (KCapsuleData memory) {
        require(_exists(_tokenId), "K-Capsule does not exist");
        return kCapsules[_tokenId];
    }

    /**
     * @notice Returns the staked SYNC amount for a user in both agent and curator roles.
     * @param _user The address of the user.
     * @return agentStake The amount staked as an agent.
     * @return curatorStake The amount staked as a curator.
     */
    function getUserStake(address _user) external view returns (uint256 agentStake, uint256 curatorStake) {
        return (agentStakes[_user].stakedAmount, curatorStakes[_user].stakedAmount);
    }

    /**
     * @notice Retrieves the Cognitive Reputation Token (CRT) scores for a user.
     * @param _user The address of the user.
     * @return agentScore The user's agent reputation score.
     * @return curatorScore The user's curator reputation score.
     * @return disputeScore The user's dispute penalty score.
     * @return totalScore The user's total combined reputation score.
     */
    function getCRTScores(address _user) external view returns (uint256 agentScore, uint256 curatorScore, uint256 disputeScore, uint256 totalScore) {
        UserCRTData storage crt = userCRTs[_user];
        return (crt.agentScore, crt.curatorScore, crt.disputeScore, crt.totalScore);
    }

    /**
     * @notice Calculates and returns the pending SYNC rewards for a user.
     * @param _user The address of the user.
     * @return rewards The total pending SYNC rewards.
     */
    function getPendingRewards(address _user) external view returns (uint256 rewards) {
        return agentStakes[_user].pendingRewards + curatorStakes[_user].pendingRewards;
    }

    /**
     * @notice Retrieves details about a governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal struct containing all proposal details.
     */
    function getProposalDetails(bytes32 _proposalId) external view returns (Proposal memory) {
        require(proposals[_proposalId].voteStartTime != 0, "Proposal does not exist");
        return proposals[_proposalId];
    }

    /**
     * @notice Returns the current paused status of the protocol.
     */
    function getProtocolStatus() external view returns (bool) {
        return paused;
    }

    /**
     * @notice Returns the current agent and curator reward rates.
     */
    function getRewardRates() external view returns (uint256 agentRate, uint256 curatorRate) {
        return (agentRewardRatePerUnit, curatorRewardRatePerVote);
    }
}
```