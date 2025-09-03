This smart contract, named **AetherWeaveNexus**, is designed as a self-optimizing, reputation-driven ecosystem for funding and coordinating specialized on-chain agents or projects. It combines several advanced and trendy concepts:

*   **Dynamic, Evolving Agent Profiles (NFTs)**: Projects or "agents" are represented by ERC721 tokens whose attributes (like reputation, status, specialization tags) evolve on-chain based on their performance and community interaction.
*   **Adaptive Funding Pools**: Funding pools are not static; their allocation weights can be dynamically adjusted by governance (potentially influenced by external oracle data on project success or market trends), guiding resources to the most impactful areas.
*   **Multi-Dimensional Reputation System**: Reputation is a core currency, built through token staking, successful project milestone completion, and active, effective participation in governance. It directly influences funding eligibility and voting power, with mechanisms for decay and slashing.
*   **Decentralized Milestone Verification & Dispute Resolution**: A community-driven process to verify project progress, trigger fund releases, and resolve disagreements or fraudulent activities.
*   **Emergent Governance**: The community can propose and vote on not just individual funding requests, but also the fundamental parameters and strategies that govern the entire Nexus, allowing it to adapt and evolve over time.
*   **Incentivized Participation**: Rewards for active stakers and voters, promoting continuous engagement.

This design aims to foster a resilient, self-improving decentralized network for innovation and collaboration.

---

### Outline:

1.  **Interfaces & Mocks**: Definitions for `INexusToken` (ERC20) and `IOracle` (mock), representing external contracts the Nexus interacts with.
2.  **State Variables & Constants**:
    *   References to the Nexus Token (ERC20) and an Oracle.
    *   `Counters` for unique IDs (`AgentProfile`, `FundingRequest`, `Milestone`, `NexusProposal`, `Dispute`).
    *   Structs: `AgentProfile`, `FundingPool`, `FundingRequest`, `Milestone`, `NexusProposal`, `Voter`, `Dispute`.
    *   Mappings to store instances of these structs.
    *   Global system parameters (e.g., `MIN_STAKE_FOR_REPUTATION`, `VOTING_QUORUM_PERCENT`, `REPUTATION_DECAY_PERIOD`).
3.  **Events**: For transparent logging of all significant actions.
4.  **Modifiers**: For access control and state validation.
5.  **Constructor**: Initializes the contract, linking to external token and oracle contracts, and setting up initial parameters.
6.  **Agent Profile Management (ERC721-based)**: Functions for creating, updating, retiring, and querying agent profiles.
7.  **Funding & Resource Allocation**: Functions for agents to request funds, community members to vote on requests, distribution of funds, reporting of project milestones, and their verification/payment release.
8.  **Reputation System**: Functions for staking tokens to gain reputation, unstaking, delegating voting power, a governance-controlled slashing mechanism, and dynamic reputation recalculation.
9.  **Nexus Governance & Evolution**: Functions for creating, voting on, and executing governance proposals (e.g., for parameter changes or specific actions), and a system for submitting and resolving disputes.
10. **Advanced/Adaptive Features**: Functions for dynamic adjustment of funding pool weights (via governance), a mechanism to address stagnant funds (e.g., by penalizing or reallocating), and claiming epoch-based rewards for participants.
11. **Admin/Governance Handover**: A function to transfer core administrative control to a DAO or a more complex governance contract.

---

### Function Summary (26 Functions):

**I. Core & Utility Functions:**

1.  `constructor(address _nexusTokenAddress, address _oracleAddress)`: Initializes the contract with the Nexus Token and Oracle addresses, and sets up a default funding pool.
2.  `setGovernanceAddress(address _newGovernance)`: Allows the current governance entity (initially `Ownable` owner) to transfer core administrative ownership to a new address, typically a DAO contract.

**II. Agent Profile Management (ERC721-based):**

3.  `registerAgentProfile(address agentController, string calldata profileURI)`: Creates a new unique AgentProfile (ERC721 token) for a given controller address, assigning an initial reputation.
4.  `updateAgentProfileURI(uint256 agentId, string calldata newProfileURI)`: Allows the owner of an AgentProfile NFT to update its associated metadata URI.
5.  `updateAgentSpecializationTags(uint256 agentId, string[] calldata newTags)`: Allows an agent controller to update their agent's specialization tags, which can influence funding pool eligibility.
6.  `retireAgentProfile(uint256 agentId)`: Deactivates an agent's profile, making it ineligible for new funding, but preserving its historical data and completed milestones.
7.  `getAgentProfile(uint256 agentId) view returns (...)`: Retrieves comprehensive details of an agent's profile.

**III. Funding & Resource Allocation:**

8.  `submitFundingRequest(uint256 agentId, uint256 poolId, uint256 amount, string calldata description, uint256 votingDuration)`: Allows an active agent to request funds from a specific `FundingPool`, initiating a community vote based on reputation.
9.  `voteOnFundingRequest(uint256 requestId, bool support)`: Allows stakers/reputation holders to cast their vote (for/against) on a funding request, with voting power proportional to their staked tokens/delegated power.
10. `distributeFunds(uint256 requestId)`: Executes a funding request, transferring Nexus Tokens to the agent's controller if the vote passes quorum and threshold requirements.
11. `reportMilestoneCompletion(uint256 requestId, string calldata description)`: An agent reports the completion of a specific milestone for a project that received funding.
12. `verifyMilestoneCompletion(uint256 milestoneId, bool support)`: Community members vote to verify whether a reported milestone has genuinely been completed.
13. `releaseMilestonePayment(uint256 milestoneId)`: Releases a partial payment to the agent for a milestone if it is successfully verified by the community vote.

**IV. Reputation System:**

14. `stakeForReputation(uint256 amount)`: Locks Nexus Tokens within the contract, increasing the caller's reputation score and voting power.
15. `unstakeFromReputation(uint256 amount)`: Unlocks staked Nexus Tokens, reducing the caller's reputation, subject to a cool-down period after any reputation slashing.
16. `delegateReputation(address delegatee)`: Allows a voter to delegate their accumulated voting power to another address.
17. `slashReputation(address targetVoter, uint256 amount)`: A governance-controlled function to penalize a voter's reputation score, typically initiated after a successful dispute or malicious activity.
18. `triggerReputationRecalculation(uint256 agentId)`: Triggers a dynamic re-evaluation of an agent's reputation score, factoring in staked tokens, successful milestones, inactivity decay, and potentially external oracle data.

**V. Nexus Governance & Evolution:**

19. `proposeNexusParameterChange(NexusProposal.ProposalType propType, bytes calldata callData, address target, string calldata description, uint256 votingDuration)`: Creates a new governance proposal for a wide range of actions, including system parameter changes, reputation slashing, or dispute resolution.
20. `voteOnNexusProposal(uint256 proposalId, bool support)`: Allows stakers/reputation holders to vote on general governance proposals.
21. `executeNexusProposal(uint256 proposalId)`: Executes a passed governance proposal, applying the proposed parameter changes or actions through a low-level call.
22. `submitDispute(uint256 disputedEntityId, DisputeType dType, string calldata reason)`: Allows any reputation holder to formally dispute an agent's milestone, reputation score, or a proposal outcome.
23. `resolveDispute(uint256 disputeId, bool decision)`: A governance-controlled function to formally resolve an open dispute, leading to specific consequences based on the dispute type and decision.

**VI. Advanced & Adaptive Features:**

24. `dynamicallyAdjustPoolWeights(uint256[] calldata poolIds, uint256[] calldata newWeights)`: A governance-controlled function (called via `executeNexusProposal`) to update the `allocationWeight` of specific funding pools, enabling adaptive resource direction.
25. `reclaimStagnantFunds(uint256 agentId, uint256 requestId)`: A governance-controlled function (called via `executeNexusProposal`) to address underperforming or stagnant projects, potentially by slashing the agent's reputation. (Note: Direct fund reclaim from an agent needs more complex escrow/clawback mechanisms than a simple transfer back).
26. `claimEpochRewards()`: Allows active participants (stakers, voters) to claim their calculated share of epoch-based rewards, incentivizing ongoing engagement and contribution.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For clarity, though 0.8+ handles overflow/underflow

// --- INTERFACES & MOCKS (for demonstration purposes) ---
// In a real deployment, these would be actual deployed contracts.
// For a self-contained example, we define minimal interfaces.
interface INexusToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IOracle {
    // A simplified oracle for demonstration purposes.
    // In a real system, this would connect to Chainlink, Tellor, or a similar decentralized oracle network.
    function getNumericData(string calldata key) external view returns (uint256);
    function getBooleanData(string calldata key) external view returns (bool);
}

// --- OUTLINE AND FUNCTION SUMMARY ---

/*
## Contract Name: AetherWeaveNexus

**Core Concept:**
AetherWeave Nexus is a self-optimizing, reputation-driven ecosystem for funding and coordinating specialized on-chain agents or projects. It features adaptive funding pools, evolving agent profiles (NFTs) based on verifiable performance, a multi-dimensional reputation system, and emergent governance that allows the community to dynamically adjust core parameters. The goal is to create a dynamic resource allocation mechanism that prioritizes impactful contributions and fosters a resilient, adaptive decentralized network.

---

### Outline:

1.  **Interfaces & Mocks**: Definitions for `INexusToken` (ERC20) and `IOracle` (mock), representing external contracts the Nexus interacts with.
2.  **State Variables & Constants**:
    *   References to the Nexus Token (ERC20) and an Oracle.
    *   `Counters` for unique IDs (`AgentProfile`, `FundingRequest`, `Milestone`, `NexusProposal`, `Dispute`).
    *   Structs: `AgentProfile`, `FundingPool`, `FundingRequest`, `Milestone`, `NexusProposal`, `Voter`, `Dispute`.
    *   Mappings to store instances of these structs.
    *   Global system parameters (e.g., `MIN_STAKE_FOR_REPUTATION`, `VOTING_QUORUM_PERCENT`, `REPUTATION_DECAY_PERIOD`).
3.  **Events**: For transparent logging of all significant actions.
4.  **Modifiers**: For access control and state validation.
5.  **Constructor**: Initializes the contract, linking to external token and oracle contracts, and setting up initial parameters.
6.  **Agent Profile Management (ERC721-based)**: Functions for creating, updating, retiring, and querying agent profiles.
7.  **Funding & Resource Allocation**: Functions for agents to request funds, community members to vote on requests, distribution of funds, reporting of project milestones, and their verification/payment release.
8.  **Reputation System**: Functions for staking tokens to gain reputation, unstaking, delegating voting power, a governance-controlled slashing mechanism, and dynamic reputation recalculation.
9.  **Nexus Governance & Evolution**: Functions for creating, voting on, and executing governance proposals (e.g., for parameter changes or specific actions), and a system for submitting and resolving disputes.
10. **Advanced/Adaptive Features**: Functions for dynamic adjustment of funding pool weights (via governance), a mechanism to address stagnant funds (e.g., by penalizing or reallocating), and claiming epoch-based rewards for participants.
11. **Admin/Governance Handover**: A function to transfer core administrative control to a DAO or a more complex governance contract.

---

### Function Summary (26 Functions):

**I. Core & Utility Functions:**

1.  `constructor(address _nexusTokenAddress, address _oracleAddress)`: Initializes the contract with the Nexus Token and Oracle addresses, and sets up a default funding pool.
2.  `setGovernanceAddress(address _newGovernance)`: Allows the current governance entity (initially `Ownable` owner) to transfer core administrative ownership to a new address, typically a DAO contract.

**II. Agent Profile Management (ERC721-based):**

3.  `registerAgentProfile(address agentController, string calldata profileURI)`: Creates a new unique AgentProfile (ERC721 token) for a given controller address, assigning an initial reputation.
4.  `updateAgentProfileURI(uint256 agentId, string calldata newProfileURI)`: Allows the owner of an AgentProfile NFT to update its associated metadata URI.
5.  `updateAgentSpecializationTags(uint256 agentId, string[] calldata newTags)`: Allows an agent controller to update their agent's specialization tags, which can influence funding pool eligibility.
6.  `retireAgentProfile(uint256 agentId)`: Deactivates an agent's profile, making it ineligible for new funding, but preserving its historical data and completed milestones.
7.  `getAgentProfile(uint256 agentId) view returns (...)`: Retrieves comprehensive details of an agent's profile.

**III. Funding & Resource Allocation:**

8.  `submitFundingRequest(uint256 agentId, uint256 poolId, uint256 amount, string calldata description, uint256 votingDuration)`: Allows an active agent to request funds from a specific `FundingPool`, initiating a community vote based on reputation.
9.  `voteOnFundingRequest(uint256 requestId, bool support)`: Allows stakers/reputation holders to cast their vote (for/against) on a funding request, with voting power proportional to their staked tokens/delegated power.
10. `distributeFunds(uint256 requestId)`: Executes a funding request, transferring Nexus Tokens to the agent's controller if the vote passes quorum and threshold requirements.
11. `reportMilestoneCompletion(uint256 requestId, string calldata description)`: An agent reports the completion of a specific milestone for a project that received funding.
12. `verifyMilestoneCompletion(uint256 milestoneId, bool support)`: Community members vote to verify whether a reported milestone has genuinely been completed.
13. `releaseMilestonePayment(uint256 milestoneId)`: Releases a partial payment to the agent for a milestone if it is successfully verified by the community vote.

**IV. Reputation System:**

14. `stakeForReputation(uint256 amount)`: Locks Nexus Tokens within the contract, increasing the caller's reputation score and voting power.
15. `unstakeFromReputation(uint256 amount)`: Unlocks staked Nexus Tokens, reducing the caller's reputation, subject to a cool-down period after any reputation slashing.
16. `delegateReputation(address delegatee)`: Allows a voter to delegate their accumulated voting power to another address.
17. `slashReputation(address targetVoter, uint256 amount)`: A governance-controlled function to penalize a voter's reputation score, typically initiated after a successful dispute or malicious activity.
18. `triggerReputationRecalculation(uint256 agentId)`: Triggers a dynamic re-evaluation of an agent's reputation score, factoring in staked tokens, successful milestones, inactivity decay, and potentially external oracle data.

**V. Nexus Governance & Evolution:**

19. `proposeNexusParameterChange(NexusProposal.ProposalType propType, bytes calldata callData, address target, string calldata description, uint256 votingDuration)`: Creates a new governance proposal for a wide range of actions, including system parameter changes, reputation slashing, or dispute resolution.
20. `voteOnNexusProposal(uint256 proposalId, bool support)`: Allows stakers/reputation holders to vote on general governance proposals.
21. `executeNexusProposal(uint256 proposalId)`: Executes a passed governance proposal, applying the proposed parameter changes or actions through a low-level call.
22. `submitDispute(uint256 disputedEntityId, DisputeType dType, string calldata reason)`: Allows any reputation holder to formally dispute an agent's milestone, reputation score, or a proposal outcome.
23. `resolveDispute(uint256 disputeId, bool decision)`: A governance-controlled function to formally resolve an open dispute, leading to specific consequences based on the dispute type and decision.

**VI. Advanced & Adaptive Features:**

24. `dynamicallyAdjustPoolWeights(uint256[] calldata poolIds, uint256[] calldata newWeights)`: A governance-controlled function (called via `executeNexusProposal`) to update the `allocationWeight` of specific funding pools, enabling adaptive resource direction.
25. `reclaimStagnantFunds(uint256 agentId, uint256 requestId)`: A governance-controlled function (called via `executeNexusProposal`) to address underperforming or stagnant projects, potentially by slashing the agent's reputation. (Note: Direct fund reclaim from an agent needs more complex escrow/clawback mechanisms than a simple transfer back).
26. `claimEpochRewards()`: Allows active participants (stakers, voters) to claim their calculated share of epoch-based rewards, incentivizing ongoing engagement and contribution.
*/

contract AetherWeaveNexus is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For Solidity < 0.8.0, but good practice for clarity

    // --- STATE VARIABLES ---

    // External Contracts
    INexusToken public immutable nexusToken;
    IOracle public immutable oracle;

    // Counters for unique IDs
    Counters.Counter private _agentIdCounter;
    Counters.Counter private _requestIdCounter;
    Counters.Counter private _milestoneIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _disputeIdCounter;

    // --- STRUCTS ---

    enum ProposalType {
        FUNDING_REQUEST,
        PARAMETER_CHANGE,
        AGENT_ONBOARDING, // Future expansion
        REPUTATION_SLASH,
        DISPUTE_RESOLUTION
    }

    enum DisputeType {
        MILESTONE_VERIFICATION,
        REPUTATION_SCORE,
        PROPOSAL_OUTCOME
    }

    struct AgentProfile {
        address owner; // The EOA or contract controlling the agent
        string profileURI; // IPFS/HTTP URI for metadata (e.g., evolving NFT image/data)
        uint256 reputationScore; // Dynamic score based on performance & staking
        uint256[] completedMilestones; // References to milestone IDs
        string[] specializationTags; // Keywords describing the agent's focus
        uint256 totalFundsReceived;
        bool isActive; // Can be retired by owner or governance
        uint256 createdAt;
        uint256 lastActivity; // Timestamp of last significant action (e.g., report, request, vote)
    }

    struct FundingPool {
        string name;
        uint256 currentBalance; // Actual Nexus Token balance held by this specific pool within the Nexus contract
        uint256 minReputationRequired; // Min reputation for an agent to request from this pool
        uint256 allocationWeight; // Weight in overall resource distribution (governable, sums to 100 across active pools)
        bool isActive; // Can be activated/deactivated by governance
    }

    struct FundingRequest {
        uint252 agentId;
        uint252 poolId;
        uint252 amount;
        string description;
        uint252 createdAt;
        uint252 votingDeadline;
        uint252 votesFor;
        uint252 votesAgainst;
        bool executed;
        bool successful; // True if vote passed
        address proposer;
    }

    struct Milestone {
        uint252 milestoneId; // Unique ID for this milestone
        uint252 requestId; // Associated funding request ID
        uint252 agentId; // Agent who reported it
        string description;
        uint252 submittedAt;
        uint252 verificationDeadline;
        bool verified; // True if community/oracle verifies
        uint252 verificationVotesFor;
        uint252 verificationVotesAgainst;
        bool paymentReleased;
        uint252 allocatedPayment; // Amount of Nexus Token allocated for this milestone
    }

    struct NexusProposal {
        uint252 proposalId;
        address proposer;
        string description;
        ProposalType proposalType;
        bytes callData; // Encoded function call for execution if passed (e.g., setMinStakeForReputation)
        address targetContract; // Contract to call for execution (e.g., `address(this)` for internal calls)
        uint252 deadline;
        uint252 votesFor;
        uint252 votesAgainst;
        bool executed;
        bool passed; // True if vote passed
    }

    struct Voter {
        uint252 stakedTokens;
        address delegatedTo; // Address to which voting power is delegated (0x0 for no delegation)
        uint252 lastSlashTimestamp; // For cool-down period after a reputation slash
        mapping(uint252 => bool) hasVotedOnRequest; // requestId => voted
        mapping(uint252 => bool) hasVotedOnMilestone; // milestoneId => voted
        mapping(uint252 => bool) hasVotedOnProposal; // proposalId => voted
    }

    struct Dispute {
        uint252 disputeId;
        address reporter;
        DisputeType disputeType;
        uint252 disputedEntityId; // ID of the milestone, agent, or proposal being disputed
        string reason;
        uint252 submittedAt;
        uint252 resolutionDeadline;
        bool resolved;
        bool decision; // True if dispute resolved in favor of reporter (e.g., milestone found invalid)
        uint252 resolutionVotesFor;
        uint252 resolutionVotesAgainst;
    }

    // --- MAPPINGS ---
    mapping(uint252 => AgentProfile) public agentProfiles; // agentId => AgentProfile
    mapping(address => uint252) public agentAddressToId; // agentController => agentId (0 if no profile)
    mapping(uint252 => FundingPool) public fundingPools; // poolId => FundingPool
    mapping(uint224 => FundingRequest) public fundingRequests; // requestId => FundingRequest
    mapping(uint252 => Milestone) public milestones; // milestoneId => Milestone
    mapping(uint252 => NexusProposal) public nexusProposals; // proposalId => NexusProposal
    mapping(address => Voter) public voters; // voterAddress => Voter
    mapping(uint252 => Dispute) public disputes; // disputeId => Dispute

    // Global parameters (governable via NexusProposals)
    uint252 public MIN_STAKE_FOR_REPUTATION = 100e18; // 100 Nexus Tokens (wei)
    uint252 public VOTING_QUORUM_PERCENT = 40; // 40% of total staked tokens must participate
    uint252 public VOTE_PASS_THRESHOLD_PERCENT = 60; // 60% of votes cast must be 'for'
    uint252 public MILESTONE_VERIFICATION_PERIOD = 7 days; // Duration for milestone verification vote
    uint252 public REPUTATION_SLASH_COOLDOWN = 30 days; // Time before unstaking is allowed after a slash
    uint252 public REPUTATION_BOOST_PER_SUCCESSFUL_MILESTONE = 100; // Reputation points per milestone
    uint252 public REPUTATION_DECAY_PERIOD = 365 days; // Period after which agent reputation might decay if inactive
    uint252 public REPUTATION_STAKE_RATIO_DIVISOR = 10e18; // Example: 1 rep point per 10 tokens staked
    uint252 public REWARD_CLAIM_COOLDOWN = 7 days; // Cooldown for claiming epoch rewards

    uint252 public totalStakedTokens; // Track total staked tokens for quorum calculation

    // --- EVENTS ---
    event AgentProfileRegistered(uint252 indexed agentId, address indexed owner, string profileURI);
    event AgentProfileUpdated(uint252 indexed agentId, string newProfileURI);
    event AgentProfileRetired(uint252 indexed agentId);
    event AgentSpecializationTagsUpdated(uint252 indexed agentId, string[] newTags);

    event FundingRequestSubmitted(uint252 indexed requestId, uint252 indexed agentId, uint252 amount);
    event FundingRequestVoted(uint252 indexed requestId, address indexed voter, bool support);
    event FundsDistributed(uint252 indexed requestId, uint252 indexed agentId, uint252 amount);
    event MilestoneReported(uint252 indexed milestoneId, uint252 indexed requestId, uint252 indexed agentId);
    event MilestoneVerified(uint252 indexed milestoneId, bool decision);
    event MilestonePaymentReleased(uint252 indexed milestoneId, uint252 amount);

    event ReputationStaked(address indexed staker, uint252 amount, uint252 newTotalStake);
    event ReputationUnstaked(address indexed staker, uint252 amount, uint224 newTotalStake);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationSlashed(address indexed target, uint252 amount);
    event ReputationRecalculated(uint252 indexed agentId, uint252 oldScore, uint252 newScore);

    event NexusProposalCreated(uint252 indexed proposalId, address indexed proposer, ProposalType propType);
    event NexusProposalVoted(uint252 indexed proposalId, address indexed voter, bool support);
    event NexusProposalExecuted(uint252 indexed proposalId, bool successful);
    event NexusParameterChanged(string parameterName, uint252 oldValue, uint252 newValue);

    event DisputeSubmitted(uint252 indexed disputeId, address indexed reporter, DisputeType dType, uint252 disputedEntityId);
    event DisputeResolved(uint252 indexed disputeId, bool decision);

    event PoolWeightsAdjusted(uint252[] poolIds, uint252[] newWeights);
    event StagnantFundsReclaimed(uint252 indexed agentId, uint252 indexed requestId, uint252 amount);
    event EpochRewardsClaimed(address indexed claimant, uint252 amount);

    // --- MODIFIERS ---
    modifier onlyAgentController(uint252 _agentId) {
        require(agentProfiles[_agentId].owner == msg.sender, "AWN: Not agent controller");
        _;
    }

    modifier onlyActiveAgent(uint252 _agentId) {
        require(agentProfiles[_agentId].isActive, "AWN: Agent not active");
        _;
    }

    modifier onlyReputationHolder() {
        require(voters[msg.sender].stakedTokens >= MIN_STAKE_FOR_REPUTATION || agentProfiles[agentAddressToId[msg.sender]].reputationScore > 0, "AWN: Insufficient reputation or stake");
        _;
    }

    modifier onlyProposalCreator(uint252 _proposalId) {
        require(nexusProposals[_proposalId].proposer == msg.sender, "AWN: Not proposal creator");
        _;
    }

    // --- CONSTRUCTOR ---
    /// @notice Initializes the contract, setting up the Nexus Token and Oracle references.
    /// @param _nexusTokenAddress The address of the deployed Nexus ERC20 token contract.
    /// @param _oracleAddress The address of the deployed IOracle contract.
    constructor(address _nexusTokenAddress, address _oracleAddress) ERC721("AetherWeave Agent Profile", "AWN-AGENT") Ownable(msg.sender) {
        require(_nexusTokenAddress != address(0), "AWN: Nexus Token address cannot be zero");
        require(_oracleAddress != address(0), "AWN: Oracle address cannot be zero");
        nexusToken = INexusToken(_nexusTokenAddress);
        oracle = IOracle(_oracleAddress);

        _requestIdCounter.increment(); // Consume 0 to ensure IDs start from 1
        // Initialize a default funding pool
        fundingPools[1] = FundingPool({
            name: "General Innovation Pool",
            currentBalance: 0, // Funds will be added via transfer or staking
            minReputationRequired: 0,
            allocationWeight: 100, // Initial 100% weight to the first pool
            isActive: true
        });
    }

    // --- II. Agent Profile Management (ERC721-based) ---

    /// @notice Registers a new unique AgentProfile (ERC721 token) for a given controller address.
    /// @param agentController The address that will control this agent profile (can be an EOA or another contract).
    /// @param profileURI The IPFS or HTTP URI for the agent's metadata (e.g., description, image, links).
    /// @return The newly created agent ID.
    function registerAgentProfile(address agentController, string calldata profileURI) external returns (uint252) {
        require(agentAddressToId[agentController] == 0, "AWN: Agent controller already has a profile");
        
        _agentIdCounter.increment();
        uint252 newAgentId = _agentIdCounter.current();

        agentProfiles[newAgentId] = AgentProfile({
            owner: agentController,
            profileURI: profileURI,
            reputationScore: 0, // Starts with 0, built through staking, milestones, and participation
            completedMilestones: new uint252[](0),
            specializationTags: new string[](0),
            totalFundsReceived: 0,
            isActive: true,
            createdAt: block.timestamp,
            lastActivity: block.timestamp
        });
        agentAddressToId[agentController] = newAgentId;

        _safeMint(agentController, newAgentId); // Mints the NFT to the controller address
        emit AgentProfileRegistered(newAgentId, agentController, profileURI);
        return newAgentId;
    }

    /// @notice Allows the owner of an AgentProfile NFT to update its associated metadata URI.
    /// @param agentId The ID of the agent profile to update.
    /// @param newProfileURI The new URI for the agent's metadata.
    function updateAgentProfileURI(uint252 agentId, string calldata newProfileURI) external onlyAgentController(agentId) {
        require(_exists(agentId), "AWN: Agent profile does not exist");
        agentProfiles[agentId].profileURI = newProfileURI;
        agentProfiles[agentId].lastActivity = block.timestamp;
        emit AgentProfileUpdated(agentId, newProfileURI);
    }

    /// @notice Allows an agent controller to update their agent's specialization tags.
    /// @param agentId The ID of the agent profile to update.
    /// @param newTags An array of new specialization tags.
    function updateAgentSpecializationTags(uint252 agentId, string[] calldata newTags) external onlyAgentController(agentId) {
        agentProfiles[agentId].specializationTags = newTags;
        agentProfiles[agentId].lastActivity = block.timestamp;
        emit AgentSpecializationTagsUpdated(agentId, newTags);
    }

    /// @notice Deactivates an agent's profile, making it ineligible for new funding, but preserving its history.
    ///         A retired agent's NFT remains, but its `isActive` status prevents new requests.
    /// @param agentId The ID of the agent profile to retire.
    function retireAgentProfile(uint252 agentId) external onlyAgentController(agentId) {
        require(agentProfiles[agentId].isActive, "AWN: Agent already retired");
        agentProfiles[agentId].isActive = false;
        agentProfiles[agentId].lastActivity = block.timestamp;
        emit AgentProfileRetired(agentId);
    }

    /// @notice Retrieves the detailed information of an agent's profile.
    /// @param agentId The ID of the agent profile.
    /// @return A tuple containing all agent profile details.
    function getAgentProfile(uint252 agentId) external view returns (
        address owner, string memory profileURI, uint252 reputationScore,
        uint252[] memory completedMilestones, string[] memory specializationTags,
        uint252 totalFundsReceived, bool isActive, uint252 createdAt, uint252 lastActivity
    ) {
        AgentProfile storage profile = agentProfiles[agentId];
        return (
            profile.owner,
            profile.profileURI,
            profile.reputationScore,
            profile.completedMilestones,
            profile.specializationTags,
            profile.totalFundsReceived,
            profile.isActive,
            profile.createdAt,
            profile.lastActivity
        );
    }

    // --- III. Funding & Resource Allocation ---

    /// @notice Allows an active agent to request funds from a specific pool, initiating a community vote.
    /// @param agentId The ID of the agent requesting funds.
    /// @param poolId The ID of the funding pool to request from.
    /// @param amount The amount of Nexus Tokens requested (in wei).
    /// @param description A description of the project/request.
    /// @param votingDuration The duration for which the voting will be open (in seconds).
    /// @return The ID of the newly created funding request.
    function submitFundingRequest(
        uint252 agentId,
        uint252 poolId,
        uint252 amount,
        string calldata description,
        uint252 votingDuration
    ) external onlyAgentController(agentId) onlyActiveAgent(agentId) returns (uint252) {
        require(fundingPools[poolId].isActive, "AWN: Funding pool not active");
        require(agentProfiles[agentId].reputationScore >= fundingPools[poolId].minReputationRequired, "AWN: Insufficient reputation for this pool");
        require(amount > 0, "AWN: Request amount must be greater than zero");
        require(votingDuration > 0, "AWN: Voting duration must be greater than zero");

        _requestIdCounter.increment();
        uint252 newRequestId = _requestIdCounter.current();

        fundingRequests[newRequestId] = FundingRequest({
            agentId: agentId,
            poolId: poolId,
            amount: amount,
            description: description,
            createdAt: block.timestamp,
            votingDeadline: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            successful: false,
            proposer: msg.sender
        });
        agentProfiles[agentId].lastActivity = block.timestamp;
        emit FundingRequestSubmitted(newRequestId, agentId, amount);
        return newRequestId;
    }

    /// @notice Allows stakers/reputation holders to vote on a funding request.
    /// @param requestId The ID of the funding request.
    /// @param support True for 'yes' (approve funding), false for 'no' (reject funding).
    function voteOnFundingRequest(uint252 requestId, bool support) external onlyReputationHolder {
        FundingRequest storage request = fundingRequests[requestId];
        require(request.agentId != 0, "AWN: Request does not exist");
        require(block.timestamp <= request.votingDeadline, "AWN: Voting period has ended");
        require(!request.executed, "AWN: Request already executed");
        require(!voters[msg.sender].hasVotedOnRequest[requestId], "AWN: Already voted on this request");

        uint252 votingPower = voters[msg.sender].stakedTokens;
        if (voters[msg.sender].delegatedTo != address(0)) {
            votingPower = voters[voters[msg.sender].delegatedTo].stakedTokens;
        }

        require(votingPower > 0, "AWN: Caller has no voting power");

        if (support) {
            request.votesFor = request.votesFor.add(votingPower);
        } else {
            request.votesAgainst = request.votesAgainst.add(votingPower);
        }
        voters[msg.sender].hasVotedOnRequest[requestId] = true;
        emit FundingRequestVoted(requestId, msg.sender, support);
    }

    /// @notice Executes a funding request, transferring Nexus Tokens to the agent if the vote passes and conditions are met.
    ///         Checks for quorum and pass threshold.
    /// @param requestId The ID of the funding request.
    function distributeFunds(uint252 requestId) external {
        FundingRequest storage request = fundingRequests[requestId];
        require(request.agentId != 0, "AWN: Request does not exist");
        require(block.timestamp > request.votingDeadline, "AWN: Voting period not ended");
        require(!request.executed, "AWN: Request already executed");

        uint252 totalVotes = request.votesFor.add(request.votesAgainst);
        require(totalVotes > 0, "AWN: No votes cast");
        require(totalStakedTokens > 0, "AWN: No tokens staked for quorum calculation");

        // Quorum check: Total votes cast must exceed a percentage of total staked tokens
        require(totalVotes.mul(100) >= totalStakedTokens.mul(VOTING_QUORUM_PERCENT), "AWN: Quorum not met");

        // Pass threshold check: Votes For must exceed a percentage of total votes cast
        if (request.votesFor.mul(100) >= totalVotes.mul(VOTE_PASS_THRESHOLD_PERCENT)) {
            require(nexusToken.balanceOf(address(this)) >= request.amount, "AWN: Insufficient funds in Nexus pool");
            require(nexusToken.transfer(agentProfiles[request.agentId].owner, request.amount), "AWN: Token transfer failed");

            agentProfiles[request.agentId].totalFundsReceived = agentProfiles[request.agentId].totalFundsReceived.add(request.amount);
            fundingPools[request.poolId].currentBalance = fundingPools[request.poolId].currentBalance.sub(request.amount);
            request.successful = true;
            emit FundsDistributed(requestId, request.agentId, request.amount);
        } else {
            request.successful = false; // Vote failed
        }
        request.executed = true;
    }

    /// @notice An agent reports the completion of a specific milestone for a funded project.
    ///         This initiates a community verification process.
    /// @param requestId The funding request ID the milestone belongs to.
    /// @param description A description of the completed milestone.
    /// @return The ID of the newly created milestone.
    function reportMilestoneCompletion(uint252 requestId, string calldata description) external onlyAgentController(fundingRequests[requestId].agentId) returns (uint252) {
        FundingRequest storage request = fundingRequests[requestId];
        require(request.executed && request.successful, "AWN: Funding request not successfully executed");
        
        _milestoneIdCounter.increment();
        uint252 newMilestoneId = _milestoneIdCounter.current();

        // For simplicity, let's assume milestone payment is a fraction of the total request, e.g., 20%
        // In a real system, this would be defined in the funding request or proposal.
        uint252 milestonePayment = request.amount.div(5); // Assumes 5 milestones per request

        milestones[newMilestoneId] = Milestone({
            milestoneId: newMilestoneId,
            requestId: requestId,
            agentId: request.agentId,
            description: description,
            submittedAt: block.timestamp,
            verificationDeadline: block.timestamp + MILESTONE_VERIFICATION_PERIOD,
            verified: false,
            verificationVotesFor: 0,
            verificationVotesAgainst: 0,
            paymentReleased: false,
            allocatedPayment: milestonePayment
        });
        agentProfiles[request.agentId].lastActivity = block.timestamp;
        emit MilestoneReported(newMilestoneId, requestId, request.agentId);
        return newMilestoneId;
    }

    /// @notice Community members vote on the verification of a reported milestone.
    /// @param milestoneId The ID of the milestone to verify.
    /// @param support True if the milestone is verified, false otherwise.
    function verifyMilestoneCompletion(uint252 milestoneId, bool support) external onlyReputationHolder {
        Milestone storage milestone = milestones[milestoneId];
        require(milestone.requestId != 0, "AWN: Milestone does not exist");
        require(block.timestamp <= milestone.verificationDeadline, "AWN: Verification period has ended");
        require(!milestone.verified && !milestone.paymentReleased, "AWN: Milestone already verified or payment released");
        require(!voters[msg.sender].hasVotedOnMilestone[milestoneId], "AWN: Already voted on this milestone");

        uint252 votingPower = voters[msg.sender].stakedTokens;
        if (voters[msg.sender].delegatedTo != address(0)) {
            votingPower = voters[voters[msg.sender].delegatedTo].stakedTokens;
        }
        require(votingPower > 0, "AWN: Caller has no voting power");

        if (support) {
            milestone.verificationVotesFor = milestone.verificationVotesFor.add(votingPower);
        } else {
            milestone.verificationVotesAgainst = milestone.verificationVotesAgainst.add(votingPower);
        }
        voters[msg.sender].hasVotedOnMilestone[milestoneId] = true;
    }

    /// @notice Releases a partial payment for a milestone if verification passes.
    ///         Also boosts the agent's reputation.
    /// @param milestoneId The ID of the milestone for which to release payment.
    function releaseMilestonePayment(uint252 milestoneId) external {
        Milestone storage milestone = milestones[milestoneId];
        require(milestone.requestId != 0, "AWN: Milestone does not exist");
        require(block.timestamp > milestone.verificationDeadline, "AWN: Verification period not ended");
        require(!milestone.paymentReleased, "AWN: Payment already released for this milestone");

        uint252 totalVotes = milestone.verificationVotesFor.add(milestone.verificationVotesAgainst);
        if (totalVotes == 0) { // If no one voted, consider it failed or require a governance override.
            revert("AWN: No votes cast for milestone verification.");
        }

        if (milestone.verificationVotesFor.mul(100) >= totalVotes.mul(VOTE_PASS_THRESHOLD_PERCENT)) {
            // Milestone verified
            milestone.verified = true;
            agentProfiles[milestone.agentId].completedMilestones.push(milestoneId);
            agentProfiles[milestone.agentId].reputationScore = agentProfiles[milestone.agentId].reputationScore.add(REPUTATION_BOOST_PER_SUCCESSFUL_MILESTONE);
            agentProfiles[milestone.agentId].lastActivity = block.timestamp;

            require(nexusToken.balanceOf(address(this)) >= milestone.allocatedPayment, "AWN: Insufficient funds in Nexus for milestone payment");
            require(nexusToken.transfer(agentProfiles[milestone.agentId].owner, milestone.allocatedPayment), "AWN: Milestone payment transfer failed");

            milestone.paymentReleased = true;
            emit MilestoneVerified(milestoneId, true);
            emit MilestonePaymentReleased(milestoneId, milestone.allocatedPayment);
        } else {
            // Milestone not verified
            milestone.verified = false;
            emit MilestoneVerified(milestoneId, false);
        }
    }


    // --- IV. Reputation System ---

    /// @notice Locks Nexus Tokens from the caller, increasing their reputation score and voting power.
    /// @param amount The amount of Nexus Tokens to stake (in wei).
    function stakeForReputation(uint252 amount) external {
        require(amount > 0, "AWN: Stake amount must be greater than zero");
        require(nexusToken.transferFrom(msg.sender, address(this), amount), "AWN: Token transfer failed for staking");

        Voter storage voter = voters[msg.sender];
        voter.stakedTokens = voter.stakedTokens.add(amount);
        totalStakedTokens = totalStakedTokens.add(amount);
        
        // Initial reputation boost from staking (or re-evaluating if already has profile)
        uint252 agentId = agentAddressToId[msg.sender];
        if (agentId != 0) {
            agentProfiles[agentId].reputationScore = agentProfiles[agentId].reputationScore.add(amount.div(REPUTATION_STAKE_RATIO_DIVISOR));
            agentProfiles[agentId].lastActivity = block.timestamp;
        }
        emit ReputationStaked(msg.sender, amount, totalStakedTokens);
    }

    /// @notice Unlocks staked Nexus Tokens, decreasing reputation after a cool-down period.
    /// @param amount The amount of Nexus Tokens to unstake (in wei).
    function unstakeFromReputation(uint252 amount) external {
        Voter storage voter = voters[msg.sender];
        require(voter.stakedTokens >= amount, "AWN: Insufficient staked tokens");
        require(block.timestamp > voter.lastSlashTimestamp.add(REPUTATION_SLASH_COOLDOWN), "AWN: Cannot unstake during slash cooldown");

        voter.stakedTokens = voter.stakedTokens.sub(amount);
        totalStakedTokens = totalStakedTokens.sub(amount);
        
        // Decay reputation upon unstaking (e.g., proportional to unstaked amount)
        uint252 agentId = agentAddressToId[msg.sender];
        if (agentId != 0) {
            uint252 repDecay = amount.div(REPUTATION_STAKE_RATIO_DIVISOR);
            agentProfiles[agentId].reputationScore = agentProfiles[agentId].reputationScore.sub(repDecay);
            if (agentProfiles[agentId].reputationScore < 0) agentProfiles[agentId].reputationScore = 0; // Ensure non-negative
            agentProfiles[agentId].lastActivity = block.timestamp;
        }
        
        require(nexusToken.transfer(msg.sender, amount), "AWN: Token transfer failed for unstaking");
        emit ReputationUnstaked(msg.sender, amount, totalStakedTokens);
    }

    /// @notice Allows a voter to delegate their voting power to another address.
    ///         Delegation is dynamic and can be changed at any time.
    /// @param delegatee The address to which voting power will be delegated (0x0 to undelegate).
    function delegateReputation(address delegatee) external {
        require(msg.sender != delegatee, "AWN: Cannot delegate to self");
        voters[msg.sender].delegatedTo = delegatee;
        emit ReputationDelegated(msg.sender, delegatee);
    }

    /// @notice Initiates a process to penalize a voter's reputation, typically after a dispute or governance decision.
    ///         This function is `onlyOwner` for direct calls, but is expected to be called via a successful `REPUTATION_SLASH` governance proposal.
    /// @param targetVoter The address whose reputation will be slashed.
    /// @param amount The amount of reputation points to slash.
    function slashReputation(address targetVoter, uint252 amount) public onlyOwner { // Owner access here for direct calls, expected to be via DAO
        uint252 agentId = agentAddressToId[targetVoter];
        require(agentId != 0, "AWN: Target voter does not have an agent profile");
        require(agentProfiles[agentId].reputationScore >= amount, "AWN: Insufficient reputation to slash");
        
        agentProfiles[agentId].reputationScore = agentProfiles[agentId].reputationScore.sub(amount);
        voters[targetVoter].lastSlashTimestamp = block.timestamp; // Start cooldown for unstaking
        agentProfiles[agentId].lastActivity = block.timestamp;
        emit ReputationSlashed(targetVoter, amount);
    }

    /// @notice Triggers a re-evaluation of an agent's reputation score based on their recent performance metrics and verified milestones.
    ///         Can be called by anyone to update an agent's public score, but recalculation logic uses internal and oracle data.
    /// @param agentId The ID of the agent whose reputation will be recalculated.
    function triggerReputationRecalculation(uint252 agentId) external {
        AgentProfile storage agent = agentProfiles[agentId];
        require(agent.owner != address(0), "AWN: Agent does not exist");
        
        uint252 oldScore = agent.reputationScore;
        uint252 newScore = 0;

        // 1. Base reputation from staked tokens
        newScore = newScore.add(voters[agent.owner].stakedTokens.div(REPUTATION_STAKE_RATIO_DIVISOR));
        
        // 2. Boost from successfully completed milestones
        newScore = newScore.add(agent.completedMilestones.length.mul(REPUTATION_BOOST_PER_SUCCESSFUL_MILESTONE));

        // 3. Decay for inactivity (simple example: decay if no activity for REPUTATION_DECAY_PERIOD)
        if (block.timestamp.sub(agent.lastActivity) > REPUTATION_DECAY_PERIOD) {
            newScore = newScore.mul(9).div(10); // 10% decay
        }

        // 4. (Advanced/Oracle Integration) Factor in external performance metrics
        // Example: If an oracle provides a 'success_rate' metric for this agent's specialization
        // For demonstration, let's assume a generic key or derive from tags.
        // string memory specializationKey = agent.specializationTags.length > 0 ? agent.specializationTags[0] : "general";
        // uint252 oraclePerformance = oracle.getNumericData(string.concat("agent_success_rate_", specializationKey));
        // newScore = newScore.mul(oraclePerformance).div(100); // Assume oracle gives 0-100% percentage

        // Ensure reputation doesn't go below minimum (e.g., from staking alone)
        uint252 minRepFromStake = voters[agent.owner].stakedTokens.div(REPUTATION_STAKE_RATIO_DIVISOR);
        if (newScore < minRepFromStake) {
            newScore = minRepFromStake;
        }

        agent.reputationScore = newScore;
        agent.lastActivity = block.timestamp; // Recalculation is also a form of activity
        emit ReputationRecalculated(agentId, oldScore, agent.reputationScore);
    }

    // --- V. Nexus Governance & Evolution ---

    /// @notice Creates a new governance proposal to change a core Nexus parameter or execute an action.
    ///         Requires reputation to propose.
    /// @param propType The type of proposal (e.g., PARAMETER_CHANGE, REPUTATION_SLASH, DISPUTE_RESOLUTION).
    /// @param callData Encoded function call for execution if the proposal passes.
    /// @param target The target contract for the callData (e.g., `address(this)` for internal Nexus functions).
    /// @param description A detailed description of the proposal.
    /// @param votingDuration The duration for which the voting will be open (in seconds).
    /// @return The ID of the newly created proposal.
    function proposeNexusParameterChange(
        ProposalType propType,
        bytes calldata callData,
        address target,
        string calldata description,
        uint252 votingDuration
    ) external onlyReputationHolder returns (uint252) {
        _proposalIdCounter.increment();
        uint252 newProposalId = _proposalIdCounter.current();

        nexusProposals[newProposalId] = NexusProposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            description: description,
            proposalType: propType,
            callData: callData,
            targetContract: target,
            deadline: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            passed: false
        });
        emit NexusProposalCreated(newProposalId, msg.sender, propType);
        return newProposalId;
    }

    /// @notice Allows stakers/reputation holders to vote on a governance proposal.
    /// @param proposalId The ID of the governance proposal.
    /// @param support True for 'yes' (approve proposal), false for 'no' (reject proposal).
    function voteOnNexusProposal(uint252 proposalId, bool support) external onlyReputationHolder {
        NexusProposal storage proposal = nexusProposals[proposalId];
        require(proposal.proposalId != 0, "AWN: Proposal does not exist");
        require(block.timestamp <= proposal.deadline, "AWN: Voting period has ended");
        require(!proposal.executed, "AWN: Proposal already executed");
        require(!voters[msg.sender].hasVotedOnProposal[proposalId], "AWN: Already voted on this proposal");

        uint252 votingPower = voters[msg.sender].stakedTokens;
        if (voters[msg.sender].delegatedTo != address(0)) {
            votingPower = voters[voters[msg.sender].delegatedTo].stakedTokens;
        }
        require(votingPower > 0, "AWN: Caller has no voting power");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }
        voters[msg.sender].hasVotedOnProposal[proposalId] = true;
        emit NexusProposalVoted(proposalId, msg.sender, support);
    }

    /// @notice Executes a passed governance proposal, applying the proposed parameter changes or actions.
    ///         Checks for quorum and pass threshold.
    /// @param proposalId The ID of the governance proposal to execute.
    function executeNexusProposal(uint252 proposalId) external {
        NexusProposal storage proposal = nexusProposals[proposalId];
        require(proposal.proposalId != 0, "AWN: Proposal does not exist");
        require(block.timestamp > proposal.deadline, "AWN: Voting period not ended");
        require(!proposal.executed, "AWN: Proposal already executed");

        uint252 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        require(totalVotes > 0, "AWN: No votes cast");
        require(totalStakedTokens > 0, "AWN: No tokens staked for quorum calculation");

        // Quorum check
        require(totalVotes.mul(100) >= totalStakedTokens.mul(VOTING_QUORUM_PERCENT), "AWN: Quorum not met");

        if (proposal.votesFor.mul(100) >= totalVotes.mul(VOTE_PASS_THRESHOLD_PERCENT)) {
            proposal.passed = true;
            // Execute the proposal's callData
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "AWN: Proposal execution failed");
            emit NexusProposalExecuted(proposalId, true);
        } else {
            proposal.passed = false;
            emit NexusProposalExecuted(proposalId, false);
        }
        proposal.executed = true;
    }

    /// @notice Allows a user to formally dispute an agent's milestone, reputation, or proposal outcome.
    /// @param disputedEntityId The ID of the entity being disputed (milestoneId, agentId, or proposalId).
    /// @param dType The type of dispute.
    /// @param reason A detailed reason for the dispute.
    /// @return The ID of the new dispute.
    function submitDispute(uint252 disputedEntityId, DisputeType dType, string calldata reason) external onlyReputationHolder returns (uint252) {
        // Basic checks: ensure the disputed entity exists. More sophisticated checks would vary by dispute type.
        if (dType == DisputeType.MILESTONE_VERIFICATION) {
            require(milestones[disputedEntityId].requestId != 0, "AWN: Milestone not found for dispute");
        } else if (dType == DisputeType.REPUTATION_SCORE) {
            require(agentProfiles[disputedEntityId].owner != address(0), "AWN: Agent not found for dispute");
        } else if (dType == DisputeType.PROPOSAL_OUTCOME) {
            require(nexusProposals[disputedEntityId].proposalId != 0, "AWN: Proposal not found for dispute");
        } else {
            revert("AWN: Invalid dispute type");
        }

        _disputeIdCounter.increment();
        uint252 newDisputeId = _disputeIdCounter.current();

        disputes[newDisputeId] = Dispute({
            disputeId: newDisputeId,
            reporter: msg.sender,
            disputeType: dType,
            disputedEntityId: disputedEntityId,
            reason: reason,
            submittedAt: block.timestamp,
            resolutionDeadline: block.timestamp + 14 days, // Example: 14 days for resolution
            resolved: false,
            decision: false, // Default to false
            resolutionVotesFor: 0, // In a full DAO, this would be voted on similar to proposals
            resolutionVotesAgainst: 0
        });
        emit DisputeSubmitted(newDisputeId, msg.sender, dType, disputedEntityId);
        return newDisputeId;
    }

    /// @notice Allows designated arbiters (or DAO vote) to resolve an open dispute.
    ///         This function is `onlyOwner` for direct calls, but is expected to be called via a successful `DISPUTE_RESOLUTION` governance proposal.
    /// @param disputeId The ID of the dispute to resolve.
    /// @param decision The resolution outcome (true if dispute is upheld, false otherwise).
    function resolveDispute(uint252 disputeId, bool decision) external onlyOwner { // Owner access here for direct calls, expected to be via DAO
        Dispute storage dispute = disputes[disputeId];
        require(dispute.disputeId != 0, "AWN: Dispute does not exist");
        require(!dispute.resolved, "AWN: Dispute already resolved");
        // Dispute can still be resolved by governance even after deadline if deemed necessary
        // require(block.timestamp < dispute.resolutionDeadline, "AWN: Dispute resolution period ended");

        dispute.resolved = true;
        dispute.decision = decision;

        // Apply consequences based on dispute type and decision
        if (dispute.disputeType == DisputeType.MILESTONE_VERIFICATION && decision == true) {
            // If milestone was disputed and found invalid: reverse verification, potentially slash agent reputation.
            Milestone storage m = milestones[dispute.disputedEntityId];
            if (m.requestId != 0 && m.verified) { // Only act if milestone was actually verified
                // Revert milestone status
                m.verified = false;
                m.paymentReleased = false; // If payment was released, it would require a complex clawback/burn.
                // Remove from agent's completed milestones (more complex as it's an array)
                // For simplicity, just mark as unverified.

                // Slash agent reputation
                slashReputation(agentProfiles[m.agentId].owner, REPUTATION_BOOST_PER_SUCCESSFUL_MILESTONE); // Example slash amount
            }
        }
        // Add more logic for other dispute types (REPUTATION_SCORE, PROPOSAL_OUTCOME)

        emit DisputeResolved(disputeId, decision);
    }

    // --- VI. Advanced & Adaptive Features ---

    /// @notice A governance-controlled function to update the allocation weights of funding pools.
    ///         This function should be called via `executeNexusProposal` to ensure community consensus.
    /// @param poolIds An array of funding pool IDs to update.
    /// @param newWeights An array of new allocation weights corresponding to `poolIds`. Weights must sum to 100.
    function dynamicallyAdjustPoolWeights(uint252[] calldata poolIds, uint252[] calldata newWeights) external onlyOwner { // Owner access here for direct calls, expected to be via DAO
        require(poolIds.length == newWeights.length, "AWN: Array length mismatch");
        uint252 totalWeight = 0;
        for (uint252 i = 0; i < newWeights.length; i++) {
            totalWeight = totalWeight.add(newWeights[i]);
        }
        require(totalWeight == 100, "AWN: Total new weights must sum to 100");

        for (uint252 i = 0; i < poolIds.length; i++) {
            require(fundingPools[poolIds[i]].isActive, "AWN: Pool must be active to adjust weight");
            fundingPools[poolIds[i]].allocationWeight = newWeights[i];
        }
        emit PoolWeightsAdjusted(poolIds, newWeights);
    }

    /// @notice Allows the governance or system to address underperforming or stagnant projects.
    ///         This function should be called via `executeNexusProposal` after a governance decision.
    ///         In this simplified example, it primarily results in a reputation slash.
    ///         A more complex system could implement escrow for funds and actual clawbacks.
    /// @param agentId The ID of the agent whose project is stagnant.
    /// @param requestId The ID of the funding request associated with the stagnant project.
    function reclaimStagnantFunds(uint252 agentId, uint252 requestId) external onlyOwner { // Owner access here for direct calls, expected to be via DAO
        FundingRequest storage request = fundingRequests[requestId];
        require(request.agentId == agentId, "AWN: Request does not belong to agent");
        require(request.executed && request.successful, "AWN: Request not successfully executed");
        
        // This logic assumes funds were initially sent to the agent.
        // Reclaiming funds directly from the agent would require a separate mechanism (e.g., token lock-up, bonding curve).
        // Here, "reclaim" represents accountability and a penalty.
        uint252 estimatedStagnantValue = request.amount.div(2); // Example: Estimate 50% of funds as stagnant/under-delivered

        if (estimatedStagnantValue > 0) {
            slashReputation(agentProfiles[agentId].owner, estimatedStagnantValue.div(REPUTATION_STAKE_RATIO_DIVISOR)); // Slash rep proportional to estimated value
            emit StagnantFundsReclaimed(agentId, requestId, estimatedStagnantValue); // Funds not literally reclaimed, but accountability enforced.
        }
    }

    /// @notice Allows active participants (stakers, voters) to claim their share of epoch-based rewards.
    ///         The reward calculation logic can be complex and depends on participation metrics.
    ///         This is a placeholder for a more sophisticated reward distribution system.
    function claimEpochRewards() external {
        Voter storage voter = voters[msg.sender];
        require(voter.stakedTokens > 0, "AWN: No staked tokens to claim rewards");
        // require(block.timestamp > voter.lastRewardClaimed.add(REWARD_CLAIM_COOLDOWN), "AWN: Reward cooldown not over");

        // Example reward calculation: a small fixed amount per unit of staked tokens.
        // A real system would track voting activity, delegation, and distribute from a dedicated reward pool.
        uint252 rewardAmount = voter.stakedTokens.div(100e18).mul(1e18); // Example: 1 Nexus Token reward per 100 staked

        if (rewardAmount > 0) {
            require(nexusToken.balanceOf(address(this)) >= rewardAmount, "AWN: Insufficient reward pool balance");
            require(nexusToken.transfer(msg.sender, rewardAmount), "AWN: Reward transfer failed");
            // voter.lastRewardClaimed = block.timestamp; // Update last claim timestamp
            emit EpochRewardsClaimed(msg.sender, rewardAmount);
        } else {
            revert("AWN: No rewards to claim or minimum stake not met for rewards");
        }
    }

    // --- Governance Parameter Adjustments (called via executeNexusProposal) ---
    // These functions allow the DAO to change core parameters. They are marked `onlyOwner`
    // because `executeNexusProposal` (which requires `onlyOwner` for the low-level call)
    // will be the ultimate caller. In a production DAO, these might be internal or have different access.

    function setMinStakeForReputation(uint252 newAmount) external onlyOwner {
        uint252 oldAmount = MIN_STAKE_FOR_REPUTATION;
        MIN_STAKE_FOR_REPUTATION = newAmount;
        emit NexusParameterChanged("MIN_STAKE_FOR_REPUTATION", oldAmount, newAmount);
    }

    function setVotingQuorumPercent(uint252 newPercent) external onlyOwner {
        require(newPercent <= 100, "AWN: Percent cannot exceed 100");
        uint252 oldPercent = VOTING_QUORUM_PERCENT;
        VOTING_QUORUM_PERCENT = newPercent;
        emit NexusParameterChanged("VOTING_QUORUM_PERCENT", oldPercent, newPercent);
    }

    function setVotePassThresholdPercent(uint252 newPercent) external onlyOwner {
        require(newPercent <= 100, "AWN: Percent cannot exceed 100");
        uint252 oldPercent = VOTE_PASS_THRESHOLD_PERCENT;
        VOTE_PASS_THRESHOLD_PERCENT = newPercent;
        emit NexusParameterChanged("VOTE_PASS_THRESHOLD_PERCENT", oldPercent, newPercent);
    }

    function setMilestoneVerificationPeriod(uint252 newDuration) external onlyOwner {
        uint252 oldDuration = MILESTONE_VERIFICATION_PERIOD;
        MILESTONE_VERIFICATION_PERIOD = newDuration;
        emit NexusParameterChanged("MILESTONE_VERIFICATION_PERIOD", oldDuration, newDuration);
    }

    function setReputationSlashCooldown(uint252 newDuration) external onlyOwner {
        uint252 oldDuration = REPUTATION_SLASH_COOLDOWN;
        REPUTATION_SLASH_COOLDOWN = newDuration;
        emit NexusParameterChanged("REPUTATION_SLASH_COOLDOWN", oldDuration, newDuration);
    }

    function setReputationBoostPerMilestone(uint252 newAmount) external onlyOwner {
        uint252 oldAmount = REPUTATION_BOOST_PER_SUCCESSFUL_MILESTONE;
        REPUTATION_BOOST_PER_SUCCESSFUL_MILESTONE = newAmount;
        emit NexusParameterChanged("REPUTATION_BOOST_PER_SUCCESSFUL_MILESTONE", oldAmount, newAmount);
    }

    function setReputationDecayPeriod(uint252 newDuration) external onlyOwner {
        uint252 oldDuration = REPUTATION_DECAY_PERIOD;
        REPUTATION_DECAY_PERIOD = newDuration;
        emit NexusParameterChanged("REPUTATION_DECAY_PERIOD", oldDuration, newDuration);
    }

    function setReputationStakeRatioDivisor(uint252 newDivisor) external onlyOwner {
        require(newDivisor > 0, "AWN: Divisor must be greater than zero");
        uint252 oldDivisor = REPUTATION_STAKE_RATIO_DIVISOR;
        REPUTATION_STAKE_RATIO_DIVISOR = newDivisor;
        emit NexusParameterChanged("REPUTATION_STAKE_RATIO_DIVISOR", oldDivisor, newDivisor);
    }
    
    // --- Admin/Governance Handover ---
    /// @notice Allows the current governance (initially contract owner) to transfer core ownership to a new address, typically a DAO contract.
    /// @param _newGovernance The address of the new governance contract/EOA that will assume ownership.
    function setGovernanceAddress(address _newGovernance) external onlyOwner {
        transferOwnership(_newGovernance); // Utilizes Ownable's transferOwnership
    }

    // Fallback and Receive for potential Ether transfers (though Nexus is token-centric)
    // Ether sent directly to the contract will be rejected as this contract is token-based.
    receive() external payable {
        revert("AWN: Ether not accepted, send Nexus Tokens instead.");
    }
    fallback() external payable {
        revert("AWN: Call to unknown function or Ether sent directly.");
    }
}
```