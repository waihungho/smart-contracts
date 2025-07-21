Okay, this is an exciting challenge! Combining advanced concepts, creativity, and avoiding duplication of existing open-source projects requires a unique approach.

I'll propose a concept called **"AetherFlow: Decentralized Intelligence Catalyst"**.

**Core Idea:** AetherFlow is a decentralized platform where users can propose "computation challenges" (e.g., asking for an AI model to be trained, complex data analysis, generative art based on prompts) that require off-chain computation. Other users, called "Agents," can pick up these challenges, perform the computation, and submit results. The contract orchestrates challenge lifecycle, reward distribution, and, crucially, builds on-chain reputation for Agents. It incorporates a unique **Dynamic Soulbound Token (SBT)** for reputation tiers and a simplified **Zero-Knowledge Proof (ZKP) reference verification** mechanism to add an advanced touch without requiring a full ZKP implementation on-chain (which is too complex for a single contract demonstration). A micro-DAO governs protocol parameters and disputes.

---

## AetherFlow: Decentralized Intelligence Catalyst

This smart contract facilitates a decentralized marketplace for off-chain computational tasks. It allows users to propose challenges, agents to fulfill them, and incorporates a reputation system backed by dynamic Soulbound Tokens (SBTs) and a lightweight governance mechanism.

### Outline

1.  **Contract Information & Standard Imports:** Pragma, SPDX, Version, ERC20 & ERC721 imports.
2.  **Error Definitions:** Custom errors for specific failure conditions.
3.  **Events:** Log significant actions on the blockchain.
4.  **Enums:** Define various states for challenges and proposals.
5.  **Structs:**
    *   `Challenge`: Defines the structure for each computational task.
    *   `AgentProfile`: Stores an agent's on-chain reputation and activity.
    *   `ReputationTier`: Defines the thresholds and properties for different agent tiers.
    *   `GovernanceProposal`: Structure for protocol-level proposals.
6.  **State Variables:** Global variables, counters, mappings for data storage.
7.  **Modifiers:** Access control and condition checks.
8.  **Constructor:** Initializes the contract with an owner and the reward token address.
9.  **Core Challenge Management Functions:**
    *   `proposeChallenge`: Create a new computational challenge.
    *   `assignAgentToChallenge`: Agent accepts or is assigned a challenge.
    *   `submitChallengeResult`: Agent submits the result of the challenge.
    *   `verifyChallengeResult`: Proposer or a committee verifies the submitted result.
    *   `claimChallengeReward`: Agent claims rewards upon successful verification.
    *   `reportAgentFailure`: Proposer reports agent failure or unresponsiveness.
    *   `revokeChallenge`: Proposer cancels an unassigned challenge.
    *   `disputeChallengeResult`: Agent disputes a negative verification.
10. **Agent & Reputation System Functions:**
    *   `registerAgent`: Allow users to register as computational agents.
    *   `updateAgentProfile`: Agents can update their public profile hash.
    *   `getAgentProfile`: View an agent's detailed profile.
    *   `getAgentReputationTier`: Check an agent's current reputation tier.
    *   `updateAgentReputationInternal`: Internal function to update reputation scores.
    *   `_mintReputationSBT`: Internal function to mint a non-transferable SBT.
    *   `_updateReputationSBTURI`: Internal function to update SBT metadata based on tier.
    *   `_burnReputationSBT`: Internal function to burn an SBT (e.g., on severe penalty).
11. **Micro-DAO / Governance Functions:**
    *   `submitGovernanceProposal`: Agents (with sufficient reputation) propose changes.
    *   `voteOnProposal`: Agents vote for or against a proposal.
    *   `executeProposal`: Execute a proposal if it passes and the deadline is met.
    *   `getProposalDetails`: View details of a specific governance proposal.
    *   `delegateVotingPower`: Agents can delegate their voting power.
    *   `revokeVotingPowerDelegation`: Revoke previously delegated voting power.
12. **Treasury & Fee Management Functions:**
    *   `depositFundsForChallenges`: Users deposit reward tokens into the contract's treasury.
    *   `setProtocolFee`: Owner/DAO sets the fee percentage for challenge rewards.
    *   `withdrawProtocolFees`: Owner/DAO withdraws accumulated protocol fees.
13. **Utility & View Functions:**
    *   `getChallengeDetails`: Retrieve details of a specific challenge.
    *   `getChallengesByAgent`: Get all challenges assigned to or completed by an agent.
    *   `getTotalChallenges`: Get the total number of challenges created.
    *   `getTotalAgents`: Get the total number of registered agents.
    *   `getReputationTierInfo`: Get details about a specific reputation tier.
    *   `getContractBalance`: Check the balance of the reward token in the contract.
    *   `getProtocolFee`: Get the current protocol fee.

---

### Function Summary (29 Functions)

**I. Core Challenge Management:**
1.  `proposeChallenge(string calldata _descriptionHash, uint256 _rewardAmount, uint256 _deadline, bytes32 _verificationProofType)`: Allows a user to create a new computational challenge, specifying a description hash (e.g., IPFS CID of the task details), reward, and deadline. `_verificationProofType` indicates the expected verification method (e.g., 'ZKP_SNARK', 'SIMPLE_HASH').
2.  `assignAgentToChallenge(uint256 _challengeId, address _agent)`: Proposer assigns a specific agent, or an agent self-assigns an open challenge.
3.  `submitChallengeResult(uint256 _challengeId, bytes32 _resultHash, string calldata _proofReference)`: The assigned agent submits the computed result hash and a reference to an off-chain proof (e.g., IPFS CID of a ZKP, or a data file).
4.  `verifyChallengeResult(uint256 _challengeId, bool _isSuccessful)`: The challenge proposer (or a designated verifier) marks the submitted result as successful or failed. This function conceptually triggers internal ZKP verification logic if specified.
5.  `claimChallengeReward(uint256 _challengeId)`: Allows the agent to claim their reward token once the challenge has been successfully verified.
6.  `reportAgentFailure(uint256 _challengeId)`: Proposer can report an agent's failure to submit results by the deadline, or if the result was invalid and no dispute was raised.
7.  `revokeChallenge(uint256 _challengeId)`: Proposer can cancel their challenge if it hasn't been assigned yet, refunding any attached funds.
8.  `disputeChallengeResult(uint256 _challengeId, string calldata _disputeReasonHash)`: Allows an agent to dispute a `failed` verification. This triggers a governance proposal for arbitration.

**II. Agent & Reputation System (incl. Dynamic SBT logic):**
9.  `registerAgent(string calldata _profileHash)`: Allows any address to register as an Agent, creating their initial profile.
10. `updateAgentProfile(string calldata _newProfileHash)`: Agents can update their public profile hash (e.g., linking to updated off-chain profiles).
11. `getAgentProfile(address _agent)`: View function to retrieve an agent's profile details.
12. `getAgentReputationTier(address _agent)`: View function to get the name of the current reputation tier for an agent.
13. `updateAgentReputationInternal(address _agent, int256 _reputationDelta)`: INTERNAL function to adjust an agent's reputation score. Triggers SBT minting/burning/URI updates.
14. `_mintReputationSBT(address _agent, uint256 _tierId, string memory _tokenURI)`: INTERNAL function to mint a new non-transferable Soulbound Token (SBT) representing an agent's reputation tier.
15. `_updateReputationSBTURI(address _agent, string memory _newTokenURI)`: INTERNAL function to update the URI (metadata) of an existing reputation SBT, reflecting changes in status or tier.
16. `_burnReputationSBT(address _agent)`: INTERNAL function to burn an agent's SBT, e.g., for severe protocol violations or unregistration.

**III. Micro-DAO / Governance:**
17. `submitGovernanceProposal(string calldata _descriptionHash, uint256 _voteDuration)`: Agents with sufficient reputation can propose changes (e.g., new reputation tiers, fee adjustments, dispute resolutions).
18. `voteOnProposal(uint256 _proposalId, bool _for)`: Registered agents can vote for or against an active proposal. Voting power is based on reputation score.
19. `executeProposal(uint256 _proposalId)`: Any agent can call this to execute a proposal if it has passed, met quorum, and the voting period has ended.
20. `getProposalDetails(uint256 _proposalId)`: View function to get details about a specific governance proposal.
21. `delegateVotingPower(address _delegatee)`: Allows an agent to delegate their voting power to another agent.
22. `revokeVotingPowerDelegation()`: Allows an agent to revoke any active voting power delegation.

**IV. Treasury & Fee Management:**
23. `depositFundsForChallenges(uint256 _challengeId, uint256 _amount)`: Users deposit the reward token to fund a specific challenge.
24. `setProtocolFee(uint256 _newFeeBps)`: Owner/DAO sets the percentage (in basis points) of challenge rewards taken as protocol fees. This can be subject to governance.
25. `withdrawProtocolFees(address _to, uint256 _amount)`: Owner/DAO can withdraw accumulated protocol fees from the contract's balance.

**V. Utility & View Functions:**
26. `getChallengeDetails(uint256 _challengeId)`: Get all details of a specific challenge.
27. `getChallengesByAgent(address _agent)`: Returns an array of challenge IDs associated with a specific agent.
28. `getTotalChallenges()`: Returns the total number of challenges created on the platform.
29. `getTotalAgents()`: Returns the total number of registered agents.
30. `getReputationTierInfo(uint256 _tierId)`: Returns the details for a specific reputation tier.
31. `getContractBalance()`: Returns the current balance of the reward token held by the contract.
32. `getProtocolFee()`: Returns the current protocol fee in basis points.

---
**Note on "No Open Source Duplication":** This contract avoids direct copy-pasting of large, pre-existing open-source protocols (like Uniswap, Compound, Aave, standard DAO implementations, etc.). While it uses standard interfaces (ERC20, ERC721) for interoperability, the unique combination of decentralized computation challenges, a custom dynamic reputation system with conceptual SBTs, and a built-in lightweight dispute resolution via governance, aims to be novel. The "ZKP reference verification" is a conceptual integration, simulating the on-chain verification of an off-chain ZKP by consuming a hash/reference, rather than a full, complex ZKP circuit verification which would require specialized precompiles or separate, massive libraries.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For ReputationSBT concept
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; // For ReputationSBT metadata

// --- AetherFlow: Decentralized Intelligence Catalyst ---
// This contract facilitates a decentralized marketplace for off-chain computational tasks.
// It allows users to propose challenges, agents to fulfill them, and incorporates a reputation
// system backed by dynamic Soulbound Tokens (SBTs) and a lightweight governance mechanism.

// --- Outline ---
// 1. Contract Information & Standard Imports
// 2. Error Definitions
// 3. Events
// 4. Enums
// 5. Structs: Challenge, AgentProfile, ReputationTier, GovernanceProposal
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Core Challenge Management Functions
// 10. Agent & Reputation System Functions (including conceptual SBT logic)
// 11. Micro-DAO / Governance Functions
// 12. Treasury & Fee Management Functions
// 13. Utility & View Functions

// --- Function Summary (29 distinct functions + 3 internal SBT helpers) ---

// I. Core Challenge Management:
// 1. proposeChallenge(string calldata _descriptionHash, uint256 _rewardAmount, uint256 _deadline, bytes32 _verificationProofType)
// 2. assignAgentToChallenge(uint256 _challengeId, address _agent)
// 3. submitChallengeResult(uint256 _challengeId, bytes32 _resultHash, string calldata _proofReference)
// 4. verifyChallengeResult(uint256 _challengeId, bool _isSuccessful)
// 5. claimChallengeReward(uint256 _challengeId)
// 6. reportAgentFailure(uint256 _challengeId)
// 7. revokeChallenge(uint256 _challengeId)
// 8. disputeChallengeResult(uint256 _challengeId, string calldata _disputeReasonHash)

// II. Agent & Reputation System (incl. Dynamic SBT logic):
// 9. registerAgent(string calldata _profileHash)
// 10. updateAgentProfile(string calldata _newProfileHash)
// 11. getAgentProfile(address _agent)
// 12. getAgentReputationTier(address _agent)
// 13. updateAgentReputationInternal(address _agent, int256 _reputationDelta) // Internal
// 14. _mintReputationSBT(address _agent, uint256 _tierId, string memory _tokenURI) // Internal
// 15. _updateReputationSBTURI(address _agent, string memory _newTokenURI) // Internal
// 16. _burnReputationSBT(address _agent) // Internal

// III. Micro-DAO / Governance:
// 17. submitGovernanceProposal(string calldata _descriptionHash, uint256 _voteDuration)
// 18. voteOnProposal(uint256 _proposalId, bool _for)
// 19. executeProposal(uint256 _proposalId)
// 20. getProposalDetails(uint256 _proposalId)
// 21. delegateVotingPower(address _delegatee)
// 22. revokeVotingPowerDelegation()

// IV. Treasury & Fee Management:
// 23. depositFundsForChallenges(uint256 _challengeId, uint256 _amount)
// 24. setProtocolFee(uint256 _newFeeBps)
// 25. withdrawProtocolFees(address _to, uint256 _amount)

// V. Utility & View Functions:
// 26. getChallengeDetails(uint256 _challengeId)
// 27. getChallengesByAgent(address _agent)
// 28. getTotalChallenges()
// 29. getTotalAgents()
// 30. getReputationTierInfo(uint256 _tierId)
// 31. getContractBalance()
// 32. getProtocolFee()

// --- End Function Summary ---


// Custom SBT Contract (non-transferable ERC721)
contract ReputationSBT is ERC721URIStorage {
    address public aetherFlowContract;
    uint256 private _nextTokenId;

    constructor(address _aetherFlowContract) ERC721("AgentReputationSBT", "AR-SBT") {
        aetherFlowContract = _aetherFlowContract;
    }

    // Only the AetherFlow contract can mint or burn SBTs
    modifier onlyAetherFlow() {
        require(msg.sender == aetherFlowContract, "ReputationSBT: Not AetherFlow contract");
        _;
    }

    function _baseURI() internal view override returns (string memory) {
        return "https://aetherflow.io/sbt/metadata/"; // Base URI for all SBTs
    }

    // Function to mint a new SBT
    function mint(address to, uint256 tierId, string memory tokenURI) external onlyAetherFlow returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

    // Function to update an existing SBT's URI
    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external onlyAetherFlow {
        require(_exists(tokenId), "ERC721URIStorage: URI update of nonexistent token");
        _setTokenURI(tokenId, newTokenURI);
    }

    // Function to burn an SBT
    function burn(uint256 tokenId) external onlyAetherFlow {
        _burn(tokenId);
    }

    // Override _beforeTokenTransfer to prevent transfers (make it soulbound)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && to != address(0)) { // Allow minting and burning, but not transfers
            revert("ReputationSBT: SBTs are non-transferable");
        }
    }
}


contract AetherFlow is Ownable {
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error NotProposer();
    error NotAgent();
    error NotRegisteredAgent();
    error InvalidStatus(uint8 _expected, uint8 _actual);
    error AlreadyAssigned();
    error DeadlinePassed();
    error InsufficientFunds();
    error ChallengeNotFound();
    error AgentNotFound();
    error ResultNotSubmitted();
    error NotVerified();
    error AlreadyVerified();
    error AlreadyClaimed();
    error NotEligibleForTier();
    error ProposalNotFound();
    error NotActiveProposal();
    error AlreadyVoted();
    error QuorumNotMet();
    error ProposalNotPassed();
    error ProposalNotExecutable();
    error InvalidDelegatee();
    error NoDelegationActive();
    error InvalidFeeBps();
    error NoFundsToWithdraw();
    error SelfAssignmentNotAllowed();

    // --- Events ---
    event ChallengeCreated(uint256 indexed challengeId, address indexed proposer, uint256 rewardAmount, uint256 deadline);
    event AgentAssigned(uint256 indexed challengeId, address indexed agent);
    event ResultSubmitted(uint256 indexed challengeId, address indexed agent, bytes32 resultHash, string proofReference);
    event ChallengeVerified(uint256 indexed challengeId, address indexed verifier, bool isSuccessful);
    event RewardClaimed(uint256 indexed challengeId, address indexed agent, uint256 amount);
    event AgentFailed(uint256 indexed challengeId, address indexed agent);
    event ChallengeRevoked(uint256 indexed challengeId, address indexed proposer);
    event ChallengeDisputed(uint256 indexed challengeId, address indexed agent, string disputeReasonHash);

    event AgentRegistered(address indexed agent, string profileHash);
    event AgentProfileUpdated(address indexed agent, string newProfileHash);
    event ReputationUpdated(address indexed agent, int256 delta, uint256 newScore, uint256 newTierId);
    event ReputationSBTMinted(address indexed agent, uint256 indexed tokenId, uint256 tierId);
    event ReputationSBTURIUpdated(address indexed agent, uint256 indexed tokenId, string newURI);
    event ReputationSBTBurned(address indexed agent, uint256 indexed tokenId);

    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string descriptionHash, uint256 voteDuration);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event VotingPowerRevoked(address indexed delegator);

    event FundsDeposited(address indexed depositor, uint256 indexed challengeId, uint256 amount);
    event ProtocolFeeSet(uint256 oldFeeBps, uint256 newFeeBps);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);

    // --- Enums ---
    enum ChallengeStatus {
        Open,           // Created, waiting for agent
        Assigned,       // Agent assigned, work in progress
        ResultSubmitted,// Result submitted, awaiting verification
        Verified,       // Verified successfully
        Failed,         // Verified failed, or agent failed to submit
        Revoked,        // Proposer revoked
        Disputed        // Result disputed, awaiting governance arbitration
    }

    enum ProposalStatus {
        Pending,        // Just created
        Active,         // Open for voting
        Succeeded,      // Passed voting, can be executed
        Failed,         // Did not pass voting or quorum
        Executed        // Successfully executed
    }

    // --- Structs ---
    struct Challenge {
        uint256 id;
        address proposer;
        uint256 rewardAmount;
        uint256 stakedAmount; // Funds held for this challenge
        string descriptionHash; // IPFS hash or similar for challenge details
        address agentAssigned;
        uint256 deadline;
        bytes32 resultHash;     // Hash of the computed result
        string proofReference;  // IPFS CID of ZKP proof or other verification data
        bytes32 verificationProofType; // e.g., "ZKP_SNARK", "SIMPLE_HASH", "AI_VALIDATION"
        ChallengeStatus status;
        bool resultVerifiedSuccessful; // True if verified successfully, false otherwise
        bool rewardClaimed;
    }

    struct AgentProfile {
        address agentAddress;
        string profileHash; // IPFS hash or similar for agent's profile details
        int256 reputationScore;
        uint256 currentTierId;
        uint256 sbtTokenId; // Token ID of their ReputationSBT
        address delegatedTo; // Address to whom this agent has delegated voting power
    }

    struct ReputationTier {
        uint256 id;
        string name;
        uint256 minScore;
        uint256 maxScore; // Max score for this tier, or type(uint256).max for highest tier
        string tokenURI; // Base URI for SBT for this tier
        uint256 votingPowerMultiplier; // How many votes per reputation point for this tier
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string descriptionHash; // IPFS hash for proposal details
        uint256 creationTime;
        uint256 voteDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted
        uint256 requiredQuorum; // Minimum total reputation score required for proposal to pass
        ProposalStatus status;
        bool executed;
    }

    // --- State Variables ---
    Counters.Counter private _challengeIds;
    Counters.Counter private _agentCount; // Keep track of registered agents
    Counters.Counter private _proposalIds;

    IERC20 public immutable rewardToken;
    ReputationSBT public immutable reputationSBT;

    mapping(uint256 => Challenge) public challenges;
    mapping(address => AgentProfile) public agents;
    mapping(address => bool) public isRegisteredAgent; // Quick lookup for registration status
    mapping(uint256 => ReputationTier) public reputationTiers; // Tier ID => Tier details
    uint256 public nextTierId = 1; // Counter for reputation tiers

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => uint256[]) public agentChallenges; // Track challenges for each agent
    mapping(address => uint256[]) public proposerChallenges; // Track challenges for each proposer

    uint256 public protocolFeeBps; // Protocol fee in basis points (e.g., 100 for 1%)
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 1000; // Example: agents need 1000 score to propose

    // --- Modifiers ---
    modifier onlyProposer(uint256 _challengeId) {
        require(challenges[_challengeId].proposer == msg.sender, "AetherFlow: Not the challenge proposer");
        _;
    }

    modifier onlyAgent(address _agent) {
        require(isRegisteredAgent[_agent], "AetherFlow: Address is not a registered agent");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId > 0 && _challengeId <= _challengeIds.current(), "AetherFlow: Challenge does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "AetherFlow: Proposal does not exist");
        _;
    }

    modifier canVote(address _voter, uint256 _proposalId) {
        require(isRegisteredAgent[_voter], "AetherFlow: Only registered agents can vote");
        require(governanceProposals[_proposalId].status == ProposalStatus.Active, "AetherFlow: Proposal is not active for voting");
        require(!governanceProposals[_proposalId].hasVoted[_voter], "AetherFlow: Already voted on this proposal");
        _;
    }

    // --- Constructor ---
    constructor(address _rewardTokenAddress) Ownable(msg.sender) {
        require(_rewardTokenAddress != address(0), "AetherFlow: Reward token address cannot be zero");
        rewardToken = IERC20(_rewardTokenAddress);
        reputationSBT = new ReputationSBT(address(this));

        // Initialize default reputation tiers
        // Tier 1: Novice
        reputationTiers[nextTierId] = ReputationTier(nextTierId, "Novice", 0, 999, "ipfs://QmNoviceTierMetadata", 1);
        nextTierId++;
        // Tier 2: Explorer
        reputationTiers[nextTierId] = ReputationTier(nextTierId, "Explorer", 1000, 4999, "ipfs://QmExplorerTierMetadata", 2);
        nextTierId++;
        // Tier 3: Catalyst
        reputationTiers[nextTierId] = ReputationTier(nextTierId, "Catalyst", 5000, 9999, "ipfs://QmCatalystTierMetadata", 5);
        nextTierId++;
        // Tier 4: Aether Master (Highest tier, no upper bound)
        reputationTiers[nextTierId] = ReputationTier(nextTierId, "Aether Master", 10000, type(uint256).max, "ipfs://QmAetherMasterTierMetadata", 10);
        nextTierId++;

        // Default protocol fee (e.g., 5% = 500 basis points)
        protocolFeeBps = 500;
    }

    // --- Core Challenge Management Functions ---

    /// @notice Proposes a new computational challenge. Funds must be deposited separately.
    /// @param _descriptionHash IPFS hash or similar reference to the challenge details.
    /// @param _rewardAmount The amount of reward tokens for successful completion.
    /// @param _deadline Timestamp by which the challenge must be completed.
    /// @param _verificationProofType Identifier for the expected proof type (e.g., "ZKP_SNARK", "SIMPLE_HASH").
    function proposeChallenge(
        string calldata _descriptionHash,
        uint256 _rewardAmount,
        uint256 _deadline,
        bytes32 _verificationProofType
    ) external {
        require(_rewardAmount > 0, "AetherFlow: Reward must be greater than zero");
        require(_deadline > block.timestamp, "AetherFlow: Deadline must be in the future");
        require(bytes(_descriptionHash).length > 0, "AetherFlow: Description hash cannot be empty");
        require(_verificationProofType != bytes32(0), "AetherFlow: Verification proof type must be specified");

        _challengeIds.increment();
        uint256 newId = _challengeIds.current();

        challenges[newId] = Challenge({
            id: newId,
            proposer: msg.sender,
            rewardAmount: _rewardAmount,
            stakedAmount: 0, // Will be updated on deposit
            descriptionHash: _descriptionHash,
            agentAssigned: address(0),
            deadline: _deadline,
            resultHash: bytes32(0),
            proofReference: "",
            verificationProofType: _verificationProofType,
            status: ChallengeStatus.Open,
            resultVerifiedSuccessful: false,
            rewardClaimed: false
        });

        proposerChallenges[msg.sender].push(newId);
        emit ChallengeCreated(newId, msg.sender, _rewardAmount, _deadline);
    }

    /// @notice Allows a proposer to assign an agent, or an agent to self-assign an open challenge.
    /// @param _challengeId The ID of the challenge to assign.
    /// @param _agent The agent's address to assign. Set to msg.sender for self-assignment.
    function assignAgentToChallenge(uint256 _challengeId, address _agent)
        external
        challengeExists(_challengeId)
        onlyAgent(_agent)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "AetherFlow: Challenge is not open");
        require(challenge.stakedAmount >= challenge.rewardAmount, "AetherFlow: Challenge not fully funded yet");
        require(block.timestamp < challenge.deadline, "AetherFlow: Challenge deadline has passed");

        if (msg.sender != challenge.proposer) { // If not proposer, must be self-assigning agent
            require(msg.sender == _agent, "AetherFlow: Only proposer can assign other agents");
            require(_agent != address(0), "AetherFlow: Self-assignment requires msg.sender to be agent");
        } else { // Proposer assigns
            require(_agent != address(0), "AetherFlow: Agent address cannot be zero");
            require(isRegisteredAgent[_agent], "AetherFlow: Assigned address is not a registered agent");
            require(msg.sender != _agent, "AetherFlow: Proposer cannot assign themselves (use self-assignment if allowed)");
        }

        challenge.agentAssigned = _agent;
        challenge.status = ChallengeStatus.Assigned;
        agentChallenges[_agent].push(_challengeId); // Add to agent's list of challenges
        emit AgentAssigned(_challengeId, _agent);
    }

    /// @notice Allows the assigned agent to submit the result and proof reference for a challenge.
    /// @param _challengeId The ID of the challenge.
    /// @param _resultHash The hash of the computed result.
    /// @param _proofReference IPFS CID or similar reference to the off-chain proof (e.g., ZKP proof data).
    function submitChallengeResult(uint256 _challengeId, bytes32 _resultHash, string calldata _proofReference)
        external
        challengeExists(_challengeId)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(msg.sender == challenge.agentAssigned, "AetherFlow: Not the assigned agent");
        require(challenge.status == ChallengeStatus.Assigned, "AetherFlow: Challenge not in 'Assigned' status");
        require(block.timestamp < challenge.deadline, "AetherFlow: Submission deadline has passed");
        require(_resultHash != bytes32(0), "AetherFlow: Result hash cannot be empty");
        require(bytes(_proofReference).length > 0, "AetherFlow: Proof reference cannot be empty");

        challenge.resultHash = _resultHash;
        challenge.proofReference = _proofReference;
        challenge.status = ChallengeStatus.ResultSubmitted;

        emit ResultSubmitted(_challengeId, msg.sender, _resultHash, _proofReference);
    }

    /// @notice Allows the challenge proposer (or designated verifier) to verify the submitted result.
    /// This function simulates on-chain verification of off-chain computation (e.g., a ZKP).
    /// @param _challengeId The ID of the challenge.
    /// @param _isSuccessful True if the result is verified as correct, false otherwise.
    function verifyChallengeResult(uint256 _challengeId, bool _isSuccessful)
        external
        challengeExists(_challengeId)
        onlyProposer(_challengeId) // In a more complex system, this might be a verifier committee
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.ResultSubmitted, "AetherFlow: Result not submitted for this challenge");
        require(!challenge.resultVerifiedSuccessful, "AetherFlow: Result already verified");

        // Conceptual ZKP or complex verification. In a real scenario, this would involve:
        // 1. Calling an external ZKP Verifier contract:
        //    `bool isValidZKP = IVerifierContract(ZKP_VERIFIER_ADDRESS).verify(challenge.proofReference, challenge.resultHash);`
        // 2. Or, for AI model verification, a decentralized oracle network.
        // For this example, we'll simulate the outcome based on `_isSuccessful`.

        // If _verificationProofType is "ZKP_SNARK", you might add a conceptual check:
        // if (challenge.verificationProofType == "ZKP_SNARK") {
        //     bool zkpValid = _verifyZKPReference(challenge.proofReference, challenge.resultHash);
        //     if (!zkpValid && _isSuccessful) {
        //         // Proposer tries to mark as successful but ZKP failed
        //         revert("AetherFlow: ZKP verification failed, cannot mark as successful");
        //     }
        //     _isSuccessful = zkpValid; // Or just proceed with ZKP outcome
        // }

        challenge.resultVerifiedSuccessful = _isSuccessful;
        if (_isSuccessful) {
            challenge.status = ChallengeStatus.Verified;
            // Reputation increase for agent
            updateAgentReputationInternal(challenge.agentAssigned, 100); // Example: +100 score for success
        } else {
            challenge.status = ChallengeStatus.Failed;
            // Reputation decrease for agent (if not disputed)
            updateAgentReputationInternal(challenge.agentAssigned, -50); // Example: -50 score for failure
        }

        emit ChallengeVerified(_challengeId, msg.sender, _isSuccessful);
    }

    // Internal conceptual ZKP verification. In a real scenario, this would interact with a dedicated ZKP verifier contract.
    function _verifyZKPReference(string memory _proofReference, bytes32 _publicInputsHash) internal view returns (bool) {
        // This is a placeholder for actual ZKP verification.
        // In a real dApp, this might:
        // 1. Parse `_proofReference` to get the actual ZKP data.
        // 2. Call a precompiled contract (like `pairing` for BN254) or an external verifier contract.
        // Example: `VerifierContract(ZKP_VERIFIER_ADDRESS).verify(_proofReference, _publicInputsHash);`
        // For this demo, we just return true.
        _proofReference; // suppress unused variable warning
        _publicInputsHash; // suppress unused variable warning
        return true; // Assume ZKP verification always passes for this conceptual example
    }

    /// @notice Allows the assigned agent to claim their reward after successful verification.
    /// @param _challengeId The ID of the challenge.
    function claimChallengeReward(uint256 _challengeId)
        external
        challengeExists(_challengeId)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(msg.sender == challenge.agentAssigned, "AetherFlow: Not the assigned agent");
        require(challenge.status == ChallengeStatus.Verified, "AetherFlow: Challenge not successfully verified");
        require(!challenge.rewardClaimed, "AetherFlow: Reward already claimed");

        uint256 reward = challenge.rewardAmount;
        uint256 protocolFee = (reward * protocolFeeBps) / 10000; // Calculate fee
        uint256 agentShare = reward - protocolFee;

        // Transfer agent's share
        require(rewardToken.transfer(msg.sender, agentShare), "AetherFlow: Reward transfer failed");
        // Keep protocol fee in contract, will be withdrawn by owner/DAO
        // The remaining `protocolFee` amount from `challenge.stakedAmount` stays in the contract.
        challenge.stakedAmount -= reward; // Reduce staked amount by the total reward + fee taken

        challenge.rewardClaimed = true;
        emit RewardClaimed(_challengeId, msg.sender, agentShare);

        // If any remaining staked amount (e.g., proposer overfunded), refund to proposer
        if (challenge.stakedAmount > 0) {
            require(rewardToken.transfer(challenge.proposer, challenge.stakedAmount), "AetherFlow: Refund to proposer failed");
            challenge.stakedAmount = 0;
        }
    }

    /// @notice Allows the proposer to report an agent's failure to complete a challenge.
    /// @param _challengeId The ID of the challenge.
    function reportAgentFailure(uint256 _challengeId)
        external
        challengeExists(_challengeId)
        onlyProposer(_challengeId)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Assigned, "AetherFlow: Challenge not in 'Assigned' status");
        require(block.timestamp >= challenge.deadline, "AetherFlow: Deadline not passed yet");
        require(challenge.agentAssigned != address(0), "AetherFlow: No agent assigned to report failure");

        // If result was submitted but not verified yet, proposer might still dispute
        if (challenge.status == ChallengeStatus.ResultSubmitted) {
            // Awaiting verification, not necessarily a failure yet
            // Proposer should use verifyChallengeResult(false) instead of reporting failure if result is submitted
            revert("AetherFlow: Result submitted, use verifyChallengeResult(false) instead");
        }

        challenge.status = ChallengeStatus.Failed;
        // Deduct reputation from agent
        updateAgentReputationInternal(challenge.agentAssigned, -100); // Example: -100 score for failure

        // Refund remaining staked amount to proposer
        if (challenge.stakedAmount > 0) {
            require(rewardToken.transfer(challenge.proposer, challenge.stakedAmount), "AetherFlow: Refund to proposer failed");
            challenge.stakedAmount = 0;
        }

        emit AgentFailed(_challengeId, challenge.agentAssigned);
    }

    /// @notice Allows a proposer to revoke an unassigned challenge.
    /// @param _challengeId The ID of the challenge to revoke.
    function revokeChallenge(uint256 _challengeId)
        external
        challengeExists(_challengeId)
        onlyProposer(_challengeId)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open, "AetherFlow: Challenge is not open for revocation");
        require(challenge.agentAssigned == address(0), "AetherFlow: Cannot revoke an assigned challenge");
        
        // Refund staked amount to proposer
        if (challenge.stakedAmount > 0) {
            require(rewardToken.transfer(challenge.proposer, challenge.stakedAmount), "AetherFlow: Refund on revoke failed");
            challenge.stakedAmount = 0;
        }

        challenge.status = ChallengeStatus.Revoked;
        emit ChallengeRevoked(_challengeId, msg.sender);
    }

    /// @notice Allows an agent to dispute a 'failed' challenge verification, triggering a governance proposal for arbitration.
    /// @param _challengeId The ID of the challenge to dispute.
    /// @param _disputeReasonHash IPFS hash or similar reference for the detailed reason for the dispute.
    function disputeChallengeResult(uint256 _challengeId, string calldata _disputeReasonHash)
        external
        challengeExists(_challengeId)
    {
        Challenge storage challenge = challenges[_challengeId];
        require(msg.sender == challenge.agentAssigned, "AetherFlow: Only the assigned agent can dispute");
        require(challenge.status == ChallengeStatus.Failed, "AetherFlow: Challenge not in 'Failed' status to dispute");
        require(bytes(_disputeReasonHash).length > 0, "AetherFlow: Dispute reason hash cannot be empty");
        
        // Change challenge status to Disputed
        challenge.status = ChallengeStatus.Disputed;

        // Automatically create a governance proposal for dispute resolution
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();
        uint256 disputeVoteDuration = 7 days; // Example duration for dispute voting

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            proposer: msg.sender, // Agent is the proposer of the dispute
            descriptionHash: _disputeReasonHash,
            creationTime: block.timestamp,
            voteDeadline: block.timestamp + disputeVoteDuration,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize
            requiredQuorum: 0, // Will be calculated dynamically or set by tier config
            status: ProposalStatus.Active,
            executed: false
        });

        // Link proposal to challenge (optional, but good for traceability)
        // You might have a mapping(uint256 => uint256) for challengeId to disputeProposalId

        emit ChallengeDisputed(_challengeId, msg.sender, _disputeReasonHash);
        emit GovernanceProposalSubmitted(newProposalId, msg.sender, _disputeReasonHash, disputeVoteDuration);
    }

    // --- Agent & Reputation System Functions ---

    /// @notice Allows a user to register as a computational agent.
    /// @param _profileHash IPFS hash or similar reference for the agent's public profile.
    function registerAgent(string calldata _profileHash) external {
        require(!isRegisteredAgent[msg.sender], "AetherFlow: Agent already registered");
        require(bytes(_profileHash).length > 0, "AetherFlow: Profile hash cannot be empty");

        _agentCount.increment();
        agents[msg.sender] = AgentProfile({
            agentAddress: msg.sender,
            profileHash: _profileHash,
            reputationScore: 0, // Start with 0 score
            currentTierId: reputationTiers[1].id, // Assign to the first tier (Novice)
            sbtTokenId: 0, // Will be minted when reputation changes
            delegatedTo: address(0) // No delegation initially
        });
        isRegisteredAgent[msg.sender] = true;

        // Mint initial SBT for the Novice tier
        uint256 tokenId = reputationSBT.mint(msg.sender, reputationTiers[1].id, reputationTiers[1].tokenURI);
        agents[msg.sender].sbtTokenId = tokenId;

        emit AgentRegistered(msg.sender, _profileHash);
        emit ReputationSBTMinted(msg.sender, tokenId, reputationTiers[1].id);
    }

    /// @notice Allows a registered agent to update their public profile hash.
    /// @param _newProfileHash The new IPFS hash for the agent's profile.
    function updateAgentProfile(string calldata _newProfileHash)
        external
        onlyAgent(msg.sender)
    {
        require(bytes(_newProfileHash).length > 0, "AetherFlow: New profile hash cannot be empty");
        agents[msg.sender].profileHash = _newProfileHash;
        emit AgentProfileUpdated(msg.sender, _newProfileHash);
    }

    /// @notice Retrieves an agent's full profile details.
    /// @param _agent The address of the agent.
    /// @return agentProfile The AgentProfile struct.
    function getAgentProfile(address _agent)
        external
        view
        onlyAgent(_agent)
        returns (AgentProfile memory)
    {
        return agents[_agent];
    }

    /// @notice Retrieves the name of an agent's current reputation tier.
    /// @param _agent The address of the agent.
    /// @return tierName The name of the current tier.
    function getAgentReputationTier(address _agent)
        external
        view
        onlyAgent(_agent)
        returns (string memory tierName)
    {
        return reputationTiers[agents[_agent].currentTierId].name;
    }

    /// @notice Internal function to update an agent's reputation score and manage their SBT.
    /// @param _agent The address of the agent whose reputation is being updated.
    /// @param _reputationDelta The change in reputation score (can be positive or negative).
    function updateAgentReputationInternal(address _agent, int256 _reputationDelta) internal {
        require(isRegisteredAgent[_agent], "AetherFlow: Agent not registered for reputation update");

        AgentProfile storage agent = agents[_agent];
        int256 newScore = agent.reputationScore + _reputationDelta;

        // Ensure score doesn't go below zero (or a defined minimum)
        if (newScore < 0) {
            newScore = 0;
        }

        agent.reputationScore = newScore;
        uint256 oldTierId = agent.currentTierId;
        uint256 newTierId = oldTierId;

        // Determine new tier based on score
        for (uint256 i = 1; i < nextTierId; i++) { // Iterate through tiers
            ReputationTier memory tier = reputationTiers[i];
            if (newScore >= int256(tier.minScore) && newScore <= int256(tier.maxScore)) {
                newTierId = tier.id;
                break;
            }
        }

        if (newTierId != oldTierId) {
            agent.currentTierId = newTierId;
            // Update SBT URI to reflect new tier's metadata
            reputationSBT.updateTokenURI(agent.sbtTokenId, reputationTiers[newTierId].tokenURI);
            emit ReputationSBTURIUpdated(_agent, agent.sbtTokenId, reputationTiers[newTierId].tokenURI);
        }

        emit ReputationUpdated(_agent, _reputationDelta, uint256(newScore), newTierId);
    }

    /// @notice Internal function to mint a new non-transferable Soulbound Token (SBT) representing an agent's reputation tier.
    /// @param _agent The address of the agent to mint the SBT for.
    /// @param _tierId The ID of the reputation tier.
    /// @param _tokenURI The URI pointing to the SBT's metadata.
    /// @return The tokenId of the newly minted SBT.
    function _mintReputationSBT(address _agent, uint256 _tierId, string memory _tokenURI) internal returns (uint256) {
        uint256 tokenId = reputationSBT.mint(_agent, _tierId, _tokenURI);
        emit ReputationSBTMinted(_agent, tokenId, _tierId);
        return tokenId;
    }

    /// @notice Internal function to update the URI (metadata) of an existing reputation SBT.
    /// @param _agent The address of the agent.
    /// @param _newTokenURI The new URI pointing to the SBT's metadata.
    function _updateReputationSBTURI(address _agent, string memory _newTokenURI) internal {
        // Retrieve the tokenId for the agent's SBT
        uint256 tokenId = agents[_agent].sbtTokenId;
        require(tokenId != 0, "AetherFlow: Agent does not have an SBT to update");
        reputationSBT.updateTokenURI(tokenId, _newTokenURI);
        emit ReputationSBTURIUpdated(_agent, tokenId, _newTokenURI);
    }

    /// @notice Internal function to burn an agent's SBT.
    /// @param _agent The address of the agent whose SBT is to be burned.
    function _burnReputationSBT(address _agent) internal {
        uint256 tokenId = agents[_agent].sbtTokenId;
        require(tokenId != 0, "AetherFlow: Agent does not have an SBT to burn");
        reputationSBT.burn(tokenId);
        agents[_agent].sbtTokenId = 0; // Reset
        emit ReputationSBTBurned(_agent, tokenId);
    }

    // --- Micro-DAO / Governance Functions ---

    /// @notice Allows agents with sufficient reputation to propose system changes or dispute resolutions.
    /// @param _descriptionHash IPFS hash or similar reference for the proposal details.
    /// @param _voteDuration The duration in seconds for which the proposal will be open for voting.
    function submitGovernanceProposal(string calldata _descriptionHash, uint256 _voteDuration)
        external
        onlyAgent(msg.sender)
    {
        require(agents[msg.sender].reputationScore >= int256(MIN_REPUTATION_FOR_PROPOSAL), "AetherFlow: Insufficient reputation to propose");
        require(bytes(_descriptionHash).length > 0, "AetherFlow: Proposal description hash cannot be empty");
        require(_voteDuration > 0, "AetherFlow: Vote duration must be greater than zero");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        governanceProposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            creationTime: block.timestamp,
            voteDeadline: block.timestamp + _voteDuration,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize
            requiredQuorum: 0, // Will be calculated dynamically based on total reputation or a fixed value
            status: ProposalStatus.Active,
            executed: false
        });

        emit GovernanceProposalSubmitted(newProposalId, msg.sender, _descriptionHash, _voteDuration);
    }

    /// @notice Allows registered agents to vote on an active governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _for True for 'for', false for 'against'.
    function voteOnProposal(uint256 _proposalId, bool _for)
        external
        proposalExists(_proposalId)
        canVote(msg.sender, _proposalId)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        address voter = msg.sender;
        AgentProfile storage agent = agents[voter];

        // If delegated, actual voter is the delegatee
        if (agent.delegatedTo != address(0)) {
            voter = agent.delegatedTo;
            agent = agents[voter]; // Update agent to the delegatee's profile
        }
        
        require(isRegisteredAgent[voter], "AetherFlow: Delegatee is not a registered agent"); // Redundant check, but safe

        // Calculate voting power based on agent's reputation and tier multiplier
        ReputationTier memory tier = reputationTiers[agent.currentTierId];
        uint256 votingPower = uint256(agent.reputationScore) * tier.votingPowerMultiplier;
        
        require(votingPower > 0, "AetherFlow: Agent has no voting power");

        if (_for) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        proposal.hasVoted[msg.sender] = true; // Mark original sender as voted

        emit VoteCast(_proposalId, msg.sender, _for);
    }

    /// @notice Executes a governance proposal if it has passed voting and met quorum.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId)
        external
        proposalExists(_proposalId)
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "AetherFlow: Proposal not active");
        require(block.timestamp >= proposal.voteDeadline, "AetherFlow: Voting period not ended");
        require(!proposal.executed, "AetherFlow: Proposal already executed");

        // Simple quorum: e.g., 50% of current total active agent reputation score
        // Or a fixed threshold, or calculated based on proposal type.
        // For simplicity, let's assume `requiredQuorum` is set when proposal is created or dynamically here.
        // Example: minimum 1000 votes total AND 60% approval for now.
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = 1000; // Example: Minimum 1000 total voting power
        uint256 requiredApprovalPercentage = 60; // 60% approval

        bool quorumMet = (totalVotes >= requiredQuorum);
        bool passed = (proposal.votesFor * 100) / totalVotes >= requiredApprovalPercentage;

        if (quorumMet && passed) {
            proposal.status = ProposalStatus.Succeeded;
            // Execute the proposal's effect here based on its `descriptionHash`
            // In a real DAO, this would involve a complex switch statement or
            // a separate executable contract/interface to call based on proposal type.
            // For example:
            // if (proposal.descriptionHash == "HASH_TO_SET_FEE") {
            //     // parse data from hash and call setProtocolFee(newFee);
            // } else if (proposal.descriptionHash == "HASH_TO_ADD_TIER") {
            //     // add new tier based on data
            // }

            // Since this is a conceptual contract, we'll mark it as executed.
            proposal.executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            revert("AetherFlow: Proposal failed to meet quorum or approval threshold");
        }
    }

    /// @notice Retrieves details of a specific governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return The GovernanceProposal struct.
    function getProposalDetails(uint256 _proposalId)
        external
        view
        proposalExists(_proposalId)
        returns (GovernanceProposal memory)
    {
        return governanceProposals[_proposalId];
    }

    /// @notice Allows an agent to delegate their voting power to another registered agent.
    /// @param _delegatee The address of the agent to delegate voting power to.
    function delegateVotingPower(address _delegatee)
        external
        onlyAgent(msg.sender)
    {
        require(_delegatee != address(0), "AetherFlow: Delegatee cannot be the zero address");
        require(_delegatee != msg.sender, "AetherFlow: Cannot delegate to self");
        require(isRegisteredAgent[_delegatee], "AetherFlow: Delegatee is not a registered agent");

        agents[msg.sender].delegatedTo = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /// @notice Allows an agent to revoke their current voting power delegation.
    function revokeVotingPowerDelegation()
        external
        onlyAgent(msg.sender)
    {
        require(agents[msg.sender].delegatedTo != address(0), "AetherFlow: No active delegation to revoke");
        agents[msg.sender].delegatedTo = address(0);
        emit VotingPowerRevoked(msg.sender);
    }

    // --- Treasury & Fee Management Functions ---

    /// @notice Allows users to deposit reward tokens to fund a specific challenge.
    /// @param _challengeId The ID of the challenge to fund.
    /// @param _amount The amount of reward tokens to deposit.
    function depositFundsForChallenges(uint256 _challengeId, uint256 _amount)
        external
        challengeExists(_challengeId)
    {
        require(_amount > 0, "AetherFlow: Deposit amount must be greater than zero");
        Challenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Open || challenge.status == ChallengeStatus.Assigned,
                "AetherFlow: Challenge not in open or assigned status for funding");
        require(msg.sender == challenge.proposer, "AetherFlow: Only proposer can fund their challenge");

        require(rewardToken.transferFrom(msg.sender, address(this), _amount), "AetherFlow: Token transfer failed");
        challenge.stakedAmount += _amount;

        emit FundsDeposited(msg.sender, _challengeId, _amount);
    }

    /// @notice Allows the owner (or eventually DAO via governance) to set the protocol fee.
    /// @param _newFeeBps The new fee percentage in basis points (e.g., 100 for 1%).
    function setProtocolFee(uint256 _newFeeBps) external onlyOwner {
        require(_newFeeBps <= 1000, "AetherFlow: Fee cannot exceed 10%"); // Max 10% example
        emit ProtocolFeeSet(protocolFeeBps, _newFeeBps);
        protocolFeeBps = _newFeeBps;
    }

    /// @notice Allows the owner (or eventually DAO via governance) to withdraw accumulated protocol fees.
    /// @param _to The address to send the fees to.
    /// @param _amount The amount of fees to withdraw.
    function withdrawProtocolFees(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "AetherFlow: Target address cannot be zero");
        require(_amount > 0, "AetherFlow: Amount to withdraw must be greater than zero");
        require(rewardToken.balanceOf(address(this)) >= _amount, "AetherFlow: Insufficient balance for withdrawal");

        // Subtract staked amounts from total balance to get available fees.
        // This is a simplification. A more robust system would track fees in a separate variable.
        // For now, it withdraws from the total contract balance, assuming valid management.
        uint255 availableFees = rewardToken.balanceOf(address(this));
        // This requires a more precise fee tracking mechanism. For this example, we assume fees are available.
        // A better approach would be to track `totalProtocolFeesAccumulated` separately.
        // For now, this is a conceptual withdrawal.

        require(availableFees >= _amount, "AetherFlow: Not enough accumulated fees to withdraw");

        require(rewardToken.transfer(_to, _amount), "AetherFlow: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    // --- Utility & View Functions ---

    /// @notice Retrieves the full details of a specific challenge.
    /// @param _challengeId The ID of the challenge.
    /// @return challenge The Challenge struct.
    function getChallengeDetails(uint256 _challengeId)
        external
        view
        challengeExists(_challengeId)
        returns (Challenge memory)
    {
        return challenges[_challengeId];
    }

    /// @notice Retrieves a list of challenge IDs associated with a specific agent.
    /// @param _agent The address of the agent.
    /// @return challengeIds An array of challenge IDs.
    function getChallengesByAgent(address _agent) external view returns (uint256[] memory) {
        return agentChallenges[_agent];
    }

    /// @notice Returns the total number of challenges created on the platform.
    /// @return The total count of challenges.
    function getTotalChallenges() external view returns (uint256) {
        return _challengeIds.current();
    }

    /// @notice Returns the total number of registered agents.
    /// @return The total count of registered agents.
    function getTotalAgents() external view returns (uint256) {
        return _agentCount.current();
    }

    /// @notice Returns the details for a specific reputation tier.
    /// @param _tierId The ID of the reputation tier.
    /// @return The ReputationTier struct.
    function getReputationTierInfo(uint256 _tierId) external view returns (ReputationTier memory) {
        require(_tierId > 0 && _tierId < nextTierId, "AetherFlow: Invalid tier ID");
        return reputationTiers[_tierId];
    }

    /// @notice Returns the current balance of the reward token held by the contract.
    /// @return The contract's reward token balance.
    function getContractBalance() external view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    /// @notice Returns the current protocol fee in basis points.
    /// @return The protocol fee (bps).
    function getProtocolFee() external view returns (uint256) {
        return protocolFeeBps;
    }
}
```