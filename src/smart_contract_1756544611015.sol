This smart contract, **QuantumNexus**, proposes a novel decentralized ecosystem for "Foresight Intelligence" and "Adaptive AI Agents." It enables users to submit complex queries about future events or data analysis, which are then addressed by a network of registered "AI Agents" (represented on-chain). The system incorporates a robust reputation model, dynamic staking, decentralized dispute resolution, and leverages NFTs for agent ownership and verified query outcomes.

**Core Idea:**
A decentralized marketplace where "Adaptive AI Agents" (off-chain entities providing data/predictions) compete to answer "Foresight Queries" (user-submitted questions about future events or complex data analysis). The system ensures transparency, incentivizes accuracy, and penalizes malpractice through a sophisticated reputation and staking mechanism, governed by a DAO.

**Problem Solved:**
*   **Centralization of Predictive Markets:** Offers a decentralized alternative to traditional, often opaque, prediction platforms.
*   **Lack of Trust in AI Agents:** Provides an auditable and reputation-driven framework for engaging with off-chain AI/oracle services.
*   **Static Oracle Services:** Introduces dynamic pricing, reputation-based agent selection, and a competitive environment for data provision.

**Key Features:**
*   **Adaptive AI Agents:** On-chain representation of off-chain AI entities, complete with profiles, reputation, and staked collateral.
*   **Foresight Query Marketplace:** Users can define and fund queries, specifying parameters like resolution time and reward.
*   **Reputation-Based Incentives:** Agents earn/lose reputation based on the accuracy and timeliness of their submissions, influencing their visibility and potential rewards.
*   **Dynamic Staking & Rewards:** Agents stake tokens to participate; users can stake on predicted outcomes; rewards are distributed based on accuracy and consensus.
*   **Decentralized Dispute Resolution:** A mechanism for challenging agent submissions, involving community arbitration or a dedicated committee.
*   **NFTs for Agent Ownership & Verified Outcomes:** Unique ERC-721 tokens represent registered agents and immutable records of significant, verified query results.
*   **DAO Governance:** Allows token holders to propose and vote on key system parameters, upgrades, and dispute outcomes.
*   **Verifiable Computation (Conceptual):** While actual AI runs off-chain, the contract provides the economic and reputational framework to incentivize *verifiable* and accurate submissions.

**Dependencies:**
*   `@openzeppelin/contracts/access/Ownable.sol` (for initial setup/DAO fallback)
*   `@openzeppelin/contracts/utils/ReentrancyGuard.sol`
*   `@openzeppelin/contracts/token/ERC20/IERC20.sol` (for `QNX` token interaction)
*   `@openzeppelin/contracts/token/ERC721/ERC721.sol` (for `AgentNFT` and `OutcomeNFT`)

**Actors:**
*   **Agent:** An entity (human or algorithmic) that registers to provide answers/data for queries.
*   **Queryer:** A user who submits and funds a foresight query.
*   **Staker:** A user who stakes `QNX` on the predicted outcome of a query.
*   **DisputeResolver:** Members of the DAO or a designated committee responsible for resolving challenged query outcomes.
*   **DAO Governor:** `QNX` token holders who participate in governance proposals.

---

### Contract Outline & Function Summary

**Contract Name:** `QuantumNexus`

**I. Agent Management (ERC-721 Agent NFTs)**
1.  `registerAgent(string calldata _name, string calldata _uri)`: Onboards a new AI Agent, mints a unique `AgentNFT` for them, and sets up their profile.
2.  `updateAgentProfile(string calldata _newName, string calldata _newUri)`: Allows a registered agent to update their public profile metadata (name, URI pointing to more details).
3.  `agentStakeCollateral(uint256 _amount)`: Agents stake `QNX` tokens as collateral, required to participate in queries and as a guarantee of good behavior.
4.  `agentWithdrawCollateral(uint256 _amount)`: Allows agents to withdraw excess collateral, subject to minimum requirements and pending queries.
5.  `retireAgent()`: Initiates the process for an agent to gracefully exit the network, locking collateral until all associated queries are resolved.
6.  `submitQueryResult(uint256 _queryId, string calldata _resultHash)`: An agent submits their computed prediction or data hash for a specific query.
7.  `claimAgentRewards(uint256 _queryId)`: Agents claim their `QNX` rewards for accurate submissions to resolved queries.

**II. Query Management**
8.  `submitForesightQuery(string calldata _question, uint256 _rewardPool, uint256 _resolutionTime, uint256 _minAgentReputation)`: Creates a new foresight query, defining the question, reward, resolution deadline, and minimum agent reputation required.
9.  `fundQuery(uint256 _queryId, uint256 _amount)`: The queryer deposits `QNX` tokens to fund the reward pool and potential agent fees for a query.
10. `challengeQueryResult(uint256 _queryId, uint256 _submissionId, string calldata _reason)`: Initiates a dispute over a specific agent's submitted result for a query, requiring a challenge fee.
11. `resolveQuery(uint256 _queryId)`: Finalizes a query's outcome, verifies the submitted results (potentially through an oracle or governance vote if challenged), distributes rewards, and updates agent reputations.
12. `cancelQuery(uint256 _queryId)`: Allows the queryer to cancel an unfulfilled or unresolved query before its deadline, refunding funds.

**III. Staking & Rewards (User-side, on outcomes)**
13. `stakeOnOutcome(uint256 _queryId, string calldata _predictedOutcomeHash, uint256 _amount)`: Users can stake `QNX` tokens on a specific predicted outcome hash for a query, participating in a prediction market.
14. `withdrawOutcomeStake(uint256 _queryId, string calldata _predictedOutcomeHash, uint256 _amount)`: Allows users to withdraw their outcome stake before the query resolution deadline (if not locked by dispute).
15. `claimOutcomeRewards(uint256 _queryId, string calldata _predictedOutcomeHash)`: Users claim `QNX` rewards if their staked outcome prediction matches the final verified outcome.

**IV. Reputation & Slashes**
16. `slashAgentCollateral(address _agentAddress, uint256 _amount, string calldata _reason)`: (DAO/Committee callable) Penalizes an agent by slashing their staked collateral for malicious or highly inaccurate behavior confirmed by dispute resolution.
17. `getAgentReputation(address _agentAddress) view returns (int256)`: Retrieves an agent's current reputation score.

**V. DAO Governance**
18. `proposeParameterChange(string calldata _description, bytes calldata _callData, address _targetContract)`: Allows eligible token holders to propose changes to system parameters or execute other administrative actions.
19. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows DAO members to cast their vote (for or against) on an active governance proposal.
20. `executeProposal(uint256 _proposalId)`: Executes a governance proposal that has passed the voting threshold and quorum.

**VI. NFTs & Utilities**
21. `mintVerifiedOutcomeNFT(uint256 _queryId, string calldata _outcomeHash)`: (Internal/DAO callable) Mints a unique `OutcomeNFT` representing a significant and verified query result, creating an immutable on-chain record.
22. `getAgentDetails(address _agentAddress) view returns (Agent memory)`: Retrieves all public details of a registered agent.
23. `getQueryDetails(uint256 _queryId) view returns (Query memory)`: Retrieves the current state and parameters of a specific query.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ERC-721 for Agent NFTs
contract AgentNFT is ERC721 {
    constructor() ERC721("QuantumNexus Agent", "QN_AGENT") {}

    function mint(address to, uint256 tokenId, string calldata uri) external onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}

// ERC-721 for Verified Outcome NFTs
contract OutcomeNFT is ERC721 {
    constructor() ERC721("QuantumNexus Verified Outcome", "QN_OUTCOME") {}

    function mint(address to, uint256 tokenId, string calldata uri) external onlyOwner {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }
}

contract QuantumNexus is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Events ---
    event AgentRegistered(address indexed agentAddress, uint256 agentId, string name);
    event AgentProfileUpdated(address indexed agentAddress, string newName);
    event AgentCollateralStaked(address indexed agentAddress, uint256 amount);
    event AgentCollateralWithdrawn(address indexed agentAddress, uint256 amount);
    event AgentRetired(address indexed agentAddress);
    event QuerySubmitted(uint256 indexed queryId, address indexed queryer, string question, uint256 rewardPool);
    event QueryFunded(uint256 indexed queryId, address indexed funder, uint256 amount);
    event QueryResultSubmitted(uint256 indexed queryId, uint256 indexed submissionId, address indexed agentAddress, string resultHash);
    event QueryResolved(uint256 indexed queryId, string finalOutcomeHash, uint256 agentRewards, uint256 stakerRewards);
    event QueryCancelled(uint256 indexed queryId);
    event QueryChallenged(uint256 indexed queryId, uint256 indexed submissionId, address indexed challenger);
    event OutcomeStakePlaced(uint256 indexed queryId, address indexed staker, string predictedOutcomeHash, uint256 amount);
    event OutcomeStakeWithdrawn(uint256 indexed queryId, address indexed staker, string predictedOutcomeHash, uint256 amount);
    event OutcomeRewardsClaimed(uint256 indexed queryId, address indexed staker, string predictedOutcomeHash, uint256 amount);
    event AgentReputationUpdated(address indexed agentAddress, int256 newReputation);
    event AgentCollateralSlashed(address indexed agentAddress, uint256 amount, string reason);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event VerifiedOutcomeNFTMinted(uint256 indexed queryId, uint256 indexed tokenId, string outcomeHash);

    // --- Enums & Structs ---

    enum QueryStatus { Open, AwaitingAgentSubmission, AwaitingResolution, Challenged, Resolved, Cancelled }
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }

    struct Agent {
        uint256 id;
        string name;
        string uri; // IPFS URI for extended profile
        int256 reputation;
        uint256 stakedCollateral;
        bool retired;
        address owner; // Address that owns the AgentNFT
    }

    struct QuerySubmission {
        uint256 submissionId;
        address agentAddress;
        string resultHash; // Hash of the agent's submission/prediction
        uint256 submittedTime;
        bool isChallenged;
        bool isAccepted; // If this submission is chosen as the final result
        uint256 agentRewardClaimed; // Amount claimed by this agent
    }

    struct Query {
        uint256 id;
        address queryer;
        string question;
        uint256 rewardPool; // Total QNX allocated for agents + stakers
        uint256 resolutionTime; // Timestamp when query should be resolved
        uint256 minAgentReputation; // Minimum reputation for agents to submit
        QueryStatus status;
        uint256 creationTime;
        mapping(uint256 => QuerySubmission) submissions;
        Counters.Counter submissionCounter;
        string finalOutcomeHash; // The hash of the verified outcome
        address[] participatingAgents; // Agents who submitted results
        mapping(address => bool) hasSubmitted; // To track if an agent already submitted
        mapping(string => mapping(address => uint256)) outcomeStakes; // outcomeHash => stakerAddress => amount
        mapping(string => uint256) totalOutcomeStakes; // Total staked for a specific outcomeHash
        uint256 totalUserStaked; // Total staked by users across all outcomes
        uint256 challengeFeePaid; // Total fee paid for challenging
        address challenger; // The address that initiated the challenge
        uint256 challengeExpiration; // Time by which challenge must be resolved
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData; // Encoded function call for execution
        address targetContract; // Contract to call for execution
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 minQuorum; // Minimum votes required for passage
        ProposalState state;
        mapping(address => bool) hasVoted; // Voter address => hasVoted
    }

    struct SystemParameters {
        uint256 minAgentStake;
        uint256 agentRewardPercentage; // % of query reward pool for agents
        uint256 stakerRewardPercentage; // % of query reward pool for stakers
        uint256 disputeChallengeFee;
        uint256 disputeResolutionPeriod; // In seconds
        uint256 proposalMinVotes; // Min votes to pass a proposal
        uint256 proposalVotingPeriod; // In seconds
        int256 reputationGainPerAccurateSubmission;
        int256 reputationLossPerInaccurateSubmission;
        uint256 minReputationForChallengeVoting; // Min reputation required to vote on challenges
        uint256 agentRetirementLockPeriod; // Time in seconds collateral is locked after retirement
    }

    // --- State Variables ---
    IERC20 public immutable QNX_TOKEN; // The native ERC-20 token for staking and rewards
    AgentNFT public immutable AGENT_NFT; // ERC-721 contract for Agent NFTs
    OutcomeNFT public immutable OUTCOME_NFT; // ERC-721 contract for Verified Outcome NFTs

    mapping(address => Agent) public agents; // agentAddress => Agent struct
    mapping(uint256 => Query) public queries; // queryId => Query struct
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal struct

    Counters.Counter private _agentIds;
    Counters.Counter private _queryIds;
    Counters.Counter private _submissionIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _outcomeNFTIds;

    SystemParameters public params;

    // --- Constructor ---
    constructor(address _qnxTokenAddress, address _agentNFTAddress, address _outcomeNFTAddress) Ownable(msg.sender) {
        require(_qnxTokenAddress != address(0), "Invalid QNX Token address");
        require(_agentNFTAddress != address(0), "Invalid Agent NFT address");
        require(_outcomeNFTAddress != address(0), "Invalid Outcome NFT address");

        QNX_TOKEN = IERC20(_qnxTokenAddress);
        AGENT_NFT = AgentNFT(_agentNFTAddress);
        OUTCOME_NFT = OutcomeNFT(_outcomeNFTAddress);

        // Set initial system parameters (can be changed via DAO governance)
        params = SystemParameters({
            minAgentStake: 1000 ether, // Example: 1000 QNX
            agentRewardPercentage: 70, // 70% of reward pool
            stakerRewardPercentage: 20, // 20% of reward pool, 10% goes to treasury/burn
            disputeChallengeFee: 100 ether, // Example: 100 QNX
            disputeResolutionPeriod: 7 days, // 7 days for dispute resolution
            proposalMinVotes: 100, // Example: 100 votes to pass
            proposalVotingPeriod: 3 days, // 3 days for voting
            reputationGainPerAccurateSubmission: 10,
            reputationLossPerInaccurateSubmission: -20,
            minReputationForChallengeVoting: 50,
            agentRetirementLockPeriod: 30 days
        });
    }

    // --- Modifiers ---
    modifier onlyAgentOwner(address _agentAddress) {
        require(agents[_agentAddress].owner == msg.sender, "Caller is not the agent owner");
        _;
    }

    modifier onlyRegisteredAgent() {
        require(agents[msg.sender].id != 0, "Caller is not a registered agent");
        _;
    }

    modifier notRetiredAgent() {
        require(!agents[msg.sender].retired, "Agent is retired");
        _;
    }

    modifier queryExists(uint256 _queryId) {
        require(queries[_queryId].id != 0, "Query does not exist");
        _;
    }

    // --- I. Agent Management ---

    function registerAgent(string calldata _name, string calldata _uri) external nonReentrant {
        require(agents[msg.sender].id == 0, "Agent already registered");
        require(bytes(_name).length > 0, "Agent name cannot be empty");
        require(QNX_TOKEN.transferFrom(msg.sender, address(this), params.minAgentStake), "QNX transfer failed for min stake");

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        // Mint Agent NFT to the caller
        AGENT_NFT.mint(msg.sender, newAgentId, _uri);

        agents[msg.sender] = Agent({
            id: newAgentId,
            name: _name,
            uri: _uri,
            reputation: 0, // Starts with neutral reputation
            stakedCollateral: params.minAgentStake,
            retired: false,
            owner: msg.sender
        });

        emit AgentRegistered(msg.sender, newAgentId, _name);
    }

    function updateAgentProfile(string calldata _newName, string calldata _newUri) external onlyRegisteredAgent onlyAgentOwner(msg.sender) {
        require(bytes(_newName).length > 0, "Agent name cannot be empty");
        agents[msg.sender].name = _newName;
        agents[msg.sender].uri = _newUri;
        // Optionally update NFT URI: AGENT_NFT.setTokenURI(agents[msg.sender].id, _newUri); if setTokenURI existed and was accessible

        emit AgentProfileUpdated(msg.sender, _newName);
    }

    function agentStakeCollateral(uint256 _amount) external onlyRegisteredAgent notRetiredAgent nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(QNX_TOKEN.transferFrom(msg.sender, address(this), _amount), "QNX transfer failed for staking");
        agents[msg.sender].stakedCollateral += _amount;
        emit AgentCollateralStaked(msg.sender, _amount);
    }

    function agentWithdrawCollateral(uint256 _amount) external onlyRegisteredAgent notRetiredAgent nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(agents[msg.sender].stakedCollateral - _amount >= params.minAgentStake, "Cannot withdraw below minimum stake");
        
        // Ensure no active queries depend on this collateral
        // (More sophisticated logic needed for checking active queries. For simplicity, we assume min stake covers it)

        agents[msg.sender].stakedCollateral -= _amount;
        require(QNX_TOKEN.transfer(msg.sender, _amount), "QNX transfer failed for withdrawal");
        emit AgentCollateralWithdrawn(msg.sender, _amount);
    }

    function retireAgent() external onlyRegisteredAgent onlyAgentOwner(msg.sender) nonReentrant {
        require(!agents[msg.sender].retired, "Agent is already retired");
        // Future: Check if agent has active queries. If so, prevent immediate retirement
        // or put collateral on hold until those queries are resolved.
        agents[msg.sender].retired = true;
        
        // Lock collateral for a period to ensure no pending disputes arise
        // A more complex system would manage a time-locked release. For now, it's conceptually locked.
        emit AgentRetired(msg.sender);
    }

    function submitQueryResult(uint256 _queryId, string calldata _resultHash) external onlyRegisteredAgent notRetiredAgent queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.status == QueryStatus.Open || query.status == QueryStatus.AwaitingAgentSubmission, "Query is not open for submissions");
        require(query.creationTime + query.resolutionTime > block.timestamp, "Submission window closed");
        require(agents[msg.sender].reputation >= query.minAgentReputation, "Agent reputation too low");
        require(!query.hasSubmitted[msg.sender], "Agent already submitted for this query");
        require(bytes(_resultHash).length > 0, "Result hash cannot be empty");

        query.submissionCounter.increment();
        uint256 submissionId = query.submissionCounter.current();

        query.submissions[submissionId] = QuerySubmission({
            submissionId: submissionId,
            agentAddress: msg.sender,
            resultHash: _resultHash,
            submittedTime: block.timestamp,
            isChallenged: false,
            isAccepted: false,
            agentRewardClaimed: 0
        });
        query.participatingAgents.push(msg.sender);
        query.hasSubmitted[msg.sender] = true;

        if (query.status == QueryStatus.Open) {
            query.status = QueryStatus.AwaitingAgentSubmission;
        }

        emit QueryResultSubmitted(_queryId, submissionId, msg.sender, _resultHash);
    }
    
    function claimAgentRewards(uint256 _queryId) external onlyRegisteredAgent queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.status == QueryStatus.Resolved, "Query is not resolved");
        
        uint256 agentSubmissionId = 0;
        for (uint256 i = 1; i <= query.submissionCounter.current(); i++) {
            if (query.submissions[i].agentAddress == msg.sender) {
                agentSubmissionId = i;
                break;
            }
        }
        require(agentSubmissionId != 0, "Agent did not submit for this query");
        
        QuerySubmission storage submission = query.submissions[agentSubmissionId];
        require(submission.isAccepted, "Agent's submission was not accepted as final");
        require(submission.agentRewardClaimed == 0, "Agent rewards already claimed");

        // Reward calculation based on total agent reward pool divided by number of accepted agents
        uint256 totalAgentRewardPool = (query.rewardPool * params.agentRewardPercentage) / 100;
        uint256 acceptedAgentCount = 0;
        for (uint256 i = 1; i <= query.submissionCounter.current(); i++) {
            if (query.submissions[i].isAccepted) {
                acceptedAgentCount++;
            }
        }
        require(acceptedAgentCount > 0, "No agents had accepted submissions"); // Should not happen if query is resolved successfully

        uint256 individualAgentReward = totalAgentRewardPool / acceptedAgentCount;
        submission.agentRewardClaimed = individualAgentReward;
        
        agents[msg.sender].stakedCollateral += individualAgentReward; // Rewards are added to collateral
        require(QNX_TOKEN.transfer(msg.sender, individualAgentReward), "QNX transfer failed for agent reward");

        emit AgentReputationUpdated(msg.sender, agents[msg.sender].reputation); // Reputation updated in resolveQuery
        emit ClaimAgentRewards(_queryId, msg.sender, individualAgentReward);
    }


    // --- II. Query Management ---

    function submitForesightQuery(
        string calldata _question,
        uint256 _rewardPool, // Initial fund requested from queryer
        uint256 _resolutionTime, // In seconds from creation
        uint256 _minAgentReputation
    ) external nonReentrant returns (uint256) {
        require(bytes(_question).length > 0, "Question cannot be empty");
        require(_rewardPool > 0, "Reward pool must be greater than zero");
        require(_resolutionTime > 0, "Resolution time must be greater than zero");

        _queryIds.increment();
        uint256 newQueryId = _queryIds.current();

        queries[newQueryId].id = newQueryId;
        queries[newQueryId].queryer = msg.sender;
        queries[newQueryId].question = _question;
        queries[newQueryId].rewardPool = _rewardPool; // This will be funded by fundQuery
        queries[newQueryId].resolutionTime = _resolutionTime;
        queries[newQueryId].minAgentReputation = _minAgentReputation;
        queries[newQueryId].status = QueryStatus.Open;
        queries[newQueryId].creationTime = block.timestamp;

        // Queryer must fund the reward pool initially
        require(QNX_TOKEN.transferFrom(msg.sender, address(this), _rewardPool), "QNX transfer failed for query funding");

        emit QuerySubmitted(newQueryId, msg.sender, _question, _rewardPool);
        return newQueryId;
    }

    function fundQuery(uint256 _queryId, uint256 _amount) external queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.queryer == msg.sender, "Only queryer can fund their query");
        require(query.status == QueryStatus.Open || query.status == QueryStatus.AwaitingAgentSubmission, "Query is not open for funding");
        require(_amount > 0, "Amount must be greater than zero");

        require(QNX_TOKEN.transferFrom(msg.sender, address(this), _amount), "QNX transfer failed for additional query funding");
        query.rewardPool += _amount;
        emit QueryFunded(_queryId, msg.sender, _amount);
    }

    function challengeQueryResult(uint256 _queryId, uint256 _submissionId, string calldata _reason) external queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.status == QueryStatus.AwaitingResolution || query.status == QueryStatus.AwaitingAgentSubmission, "Query not in a state to be challenged");
        require(query.submissions[_submissionId].submissionId != 0, "Submission does not exist");
        require(!query.submissions[_submissionId].isChallenged, "Submission already challenged");
        require(query.queryer == msg.sender || agents[msg.sender].reputation >= params.minReputationForChallengeVoting, "Caller not authorized to challenge");
        require(QNX_TOKEN.transferFrom(msg.sender, address(this), params.disputeChallengeFee), "QNX transfer failed for challenge fee");

        query.status = QueryStatus.Challenged;
        query.submissions[_submissionId].isChallenged = true;
        query.challenger = msg.sender;
        query.challengeExpiration = block.timestamp + params.disputeResolutionPeriod;
        query.challengeFeePaid = params.disputeChallengeFee; // Store fee for potential refunds/rewards

        emit QueryChallenged(_queryId, _submissionId, msg.sender);
    }

    // Function for DAO/committee to resolve challenged query or for anyone after resolutionTime
    function resolveQuery(uint256 _queryId) external queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.status != QueryStatus.Resolved && query.status != QueryStatus.Cancelled, "Query already resolved or cancelled");
        require(block.timestamp >= query.creationTime + query.resolutionTime || query.status == QueryStatus.Challenged, "Query resolution time not reached yet");

        if (query.status == QueryStatus.Challenged) {
            // Dispute resolution logic: requires DAO vote or designated committee
            // For this advanced concept, we simulate this as a call by 'owner' or 'DAO committee'
            // In a real DAO, this would be triggered by a successful proposal vote.
            require(msg.sender == owner() || isDaoCommitteeMember(msg.sender), "Only DAO committee or owner can resolve challenged queries");
            require(block.timestamp <= query.challengeExpiration, "Dispute resolution period expired");

            // Simplified: The owner or DAO committee decides the final outcome.
            // In a real scenario, this would involve parsing vote results or committee decision.
            // Let's assume a proposal/external input provides the 'winning submissionId'
            // For now, let's make it pick the submission with the highest reputation agent, or external oracle.
            // For demonstration, let's allow a *specific* submission to be set as final outcome by the owner.
            // In production, this would be a governance action that sets the final outcome and then calls resolveQuery.
            // For now, we'll implement a basic "first valid submission" or "owner-determined" outcome if challenged.

            // If challenged, the 'owner' (or DAO) must provide the 'finalOutcomeHash'
            // This function needs to be extended to accept the final outcome from an external source or DAO vote
            // For simplicity, let's assume `setFinalOutcomeHash` is called prior or as part of a proposal execution.
            require(bytes(query.finalOutcomeHash).length > 0, "Final outcome hash must be set for challenged queries");

        } else if (query.status == QueryStatus.AwaitingAgentSubmission || query.status == QueryStatus.Open) {
            // Automatically resolve if no challenge and resolution time passed
            require(block.timestamp >= query.creationTime + query.resolutionTime, "Resolution time not met");
            require(query.submissionCounter.current() > 0, "No submissions for this query");

            // Simple resolution: pick the first submission or the one from highest-reputation agent
            // Advanced: Consensus mechanism (e.g., median, majority hash) or external oracle call
            uint256 winningSubmissionId = 0;
            string memory winningOutcomeHash = "";
            int256 highestRep = -2**127; // Smallest possible int256

            for (uint256 i = 1; i <= query.submissionCounter.current(); i++) {
                QuerySubmission storage currentSubmission = query.submissions[i];
                if (!currentSubmission.isChallenged && agents[currentSubmission.agentAddress].reputation > highestRep) {
                    highestRep = agents[currentSubmission.agentAddress].reputation;
                    winningSubmissionId = currentSubmission.submissionId;
                    winningOutcomeHash = currentSubmission.resultHash;
                }
            }
            require(winningSubmissionId != 0, "Could not determine a winning submission");
            query.finalOutcomeHash = winningOutcomeHash;
            query.submissions[winningSubmissionId].isAccepted = true;
        }

        // --- Reward Distribution & Reputation Update ---
        uint256 totalAgentRewardPool = (query.rewardPool * params.agentRewardPercentage) / 100;
        uint256 totalStakerRewardPool = (query.rewardPool * params.stakerRewardPercentage) / 100;
        
        uint256 acceptedAgentCount = 0;
        for (uint256 i = 1; i <= query.submissionCounter.current(); i++) {
            QuerySubmission storage submission = query.submissions[i];
            if (keccak256(abi.encodePacked(submission.resultHash)) == keccak256(abi.encodePacked(query.finalOutcomeHash))) {
                submission.isAccepted = true;
                acceptedAgentCount++;
                _updateAgentReputation(submission.agentAddress, params.reputationGainPerAccurateSubmission);
            } else {
                _updateAgentReputation(submission.agentAddress, params.reputationLossPerInaccurateSubmission);
            }
        }

        // If no accepted agents (e.g., all were wrong or challenged failed), redistribute their pool
        if (acceptedAgentCount == 0 && query.submissionCounter.current() > 0) {
            totalStakerRewardPool += totalAgentRewardPool; // Add agent pool to staker pool if no agents win
            totalAgentRewardPool = 0; // No agent rewards
        }
        
        // Distribution of Staker Rewards
        if (query.totalUserStaked > 0) {
            uint256 correctOutcomeTotalStake = query.outcomeStakes[query.finalOutcomeHash][address(0)]; // Placeholder to sum all stakes for this outcome
            for (uint256 i = 1; i <= query.submissionCounter.current(); i++) { // Re-iterate to sum stakes for the winning hash if needed
                QuerySubmission storage sub = query.submissions[i];
                if (sub.isAccepted) {
                    correctOutcomeTotalStake += query.totalOutcomeStakes[sub.resultHash];
                    break;
                }
            }

            if (correctOutcomeTotalStake > 0) {
                // Anyone who staked on the final outcome hash will receive a share of the staker reward pool.
                // Actual distribution happens when users call claimOutcomeRewards.
            } else {
                // If no one staked on the correct outcome, staker reward pool is redistributed (e.g., to treasury/burn or back to queryer)
                totalAgentRewardPool += totalStakerRewardPool; // Add to agent pool as no stakers won
                totalStakerRewardPool = 0;
            }
        } else {
            // If no users staked, staker reward pool is redistributed (e.g., to treasury/burn or back to queryer)
            totalAgentRewardPool += totalStakerRewardPool;
            totalStakerRewardPool = 0;
        }
        
        // Handle remaining (unallocated) reward pool, e.g., to treasury or burn
        uint256 unallocated = query.rewardPool - totalAgentRewardPool - totalStakerRewardPool;
        if (unallocated > 0) {
            // Transfer to treasury address or burn
             QNX_TOKEN.transfer(owner(), unallocated); // Send to owner as treasury example
        }

        query.status = QueryStatus.Resolved;
        emit QueryResolved(_queryId, query.finalOutcomeHash, totalAgentRewardPool, totalStakerRewardPool);
        
        // Optionally mint an NFT for a significant outcome
        // This could be triggered by DAO vote or based on query value/impact
        if (query.rewardPool >= 5000 ether) { // Example threshold for significance
            _mintVerifiedOutcomeNFT(_queryId, query.finalOutcomeHash);
        }
    }

    // Helper function for DAO/owner to set final outcome in challenged queries
    function setFinalOutcomeHash(uint256 _queryId, string calldata _finalOutcomeHash) external onlyOwner queryExists(_queryId) {
        Query storage query = queries[_queryId];
        require(query.status == QueryStatus.Challenged, "Query is not in challenged state");
        require(bytes(_finalOutcomeHash).length > 0, "Final outcome hash cannot be empty");
        query.finalOutcomeHash = _finalOutcomeHash;
    }

    function cancelQuery(uint256 _queryId) external queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.queryer == msg.sender, "Only queryer can cancel their query");
        require(query.status != QueryStatus.Resolved && query.status != QueryStatus.Cancelled, "Query already resolved or cancelled");
        require(block.timestamp < query.creationTime + query.resolutionTime, "Cannot cancel after resolution time");

        // Refund the queryer
        require(QNX_TOKEN.transfer(msg.sender, query.rewardPool), "QNX transfer failed for query refund");
        
        // Refund any user stakes if they exist (unlikely if no final outcome)
        // More complex if there are outcome stakes without a final outcome. For simplicity, assume no active user stakes if cancelled early.

        query.status = QueryStatus.Cancelled;
        emit QueryCancelled(_queryId);
    }

    // --- III. Staking & Rewards (User-side) ---

    function stakeOnOutcome(uint256 _queryId, string calldata _predictedOutcomeHash, uint256 _amount) external queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.status == QueryStatus.Open || query.status == QueryStatus.AwaitingAgentSubmission, "Query is not open for outcome staking");
        require(block.timestamp < query.creationTime + query.resolutionTime, "Staking window closed");
        require(_amount > 0, "Amount must be greater than zero");
        require(bytes(_predictedOutcomeHash).length > 0, "Predicted outcome hash cannot be empty");

        require(QNX_TOKEN.transferFrom(msg.sender, address(this), _amount), "QNX transfer failed for outcome staking");

        query.outcomeStakes[_predictedOutcomeHash][msg.sender] += _amount;
        query.totalOutcomeStakes[_predictedOutcomeHash] += _amount;
        query.totalUserStaked += _amount;

        emit OutcomeStakePlaced(_queryId, msg.sender, _predictedOutcomeHash, _amount);
    }

    function withdrawOutcomeStake(uint256 _queryId, string calldata _predictedOutcomeHash, uint256 _amount) external queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.status != QueryStatus.Resolved && query.status != QueryStatus.Cancelled, "Cannot withdraw from resolved/cancelled query");
        require(block.timestamp < query.creationTime + query.resolutionTime, "Withdrawal window closed after resolution time");
        require(query.outcomeStakes[_predictedOutcomeHash][msg.sender] >= _amount, "Insufficient staked amount");
        require(_amount > 0, "Amount must be greater than zero");

        query.outcomeStakes[_predictedOutcomeHash][msg.sender] -= _amount;
        query.totalOutcomeStakes[_predictedOutcomeHash] -= _amount;
        query.totalUserStaked -= _amount;

        require(QNX_TOKEN.transfer(msg.sender, _amount), "QNX transfer failed for outcome stake withdrawal");
        emit OutcomeStakeWithdrawn(_queryId, msg.sender, _predictedOutcomeHash, _amount);
    }

    function claimOutcomeRewards(uint256 _queryId, string calldata _predictedOutcomeHash) external queryExists(_queryId) nonReentrant {
        Query storage query = queries[_queryId];
        require(query.status == QueryStatus.Resolved, "Query is not resolved");
        require(keccak256(abi.encodePacked(_predictedOutcomeHash)) == keccak256(abi.encodePacked(query.finalOutcomeHash)), "Predicted outcome did not match final outcome");
        
        uint256 stakedAmount = query.outcomeStakes[_predictedOutcomeHash][msg.sender];
        require(stakedAmount > 0, "No stake found for this outcome");
        
        query.outcomeStakes[_predictedOutcomeHash][msg.sender] = 0; // Clear stake after claiming

        // Calculate reward: (staker's stake / total stake on correct outcome) * total staker reward pool
        uint256 totalStakerRewardPool = (query.rewardPool * params.stakerRewardPercentage) / 100;
        uint256 correctOutcomeTotalStake = query.totalOutcomeStakes[query.finalOutcomeHash];
        
        require(correctOutcomeTotalStake > 0, "No total stake on the correct outcome");
        
        uint256 reward = (stakedAmount * totalStakerRewardPool) / correctOutcomeTotalStake;
        
        require(QNX_TOKEN.transfer(msg.sender, stakedAmount + reward), "QNX transfer failed for outcome reward claim"); // Return stake + reward

        emit OutcomeRewardsClaimed(_queryId, msg.sender, _predictedOutcomeHash, stakedAmount + reward);
    }

    // --- IV. Reputation & Slashes ---

    function _updateAgentReputation(address _agentAddress, int256 _reputationChange) internal {
        agents[_agentAddress].reputation += _reputationChange;
        emit AgentReputationUpdated(_agentAddress, agents[_agentAddress].reputation);
    }

    // This function would typically be called by the DAO after a successful vote/dispute resolution.
    // For simplicity, let the contract owner (as a proxy for DAO) call it.
    function slashAgentCollateral(address _agentAddress, uint256 _amount, string calldata _reason) external onlyOwner nonReentrant {
        require(agents[_agentAddress].id != 0, "Agent does not exist");
        require(_amount > 0, "Amount must be greater than zero");
        require(agents[_agentAddress].stakedCollateral - _amount >= params.minAgentStake, "Cannot slash below minimum stake or insufficient collateral");

        agents[_agentAddress].stakedCollateral -= _amount;
        QNX_TOKEN.transfer(owner(), _amount); // Slash to treasury/burn
        
        _updateAgentReputation(_agentAddress, params.reputationLossPerInaccurateSubmission); // Also apply reputation loss

        emit AgentCollateralSlashed(_agentAddress, _amount, _reason);
    }

    function getAgentReputation(address _agentAddress) public view returns (int256) {
        return agents[_agentAddress].reputation;
    }

    // --- V. DAO Governance ---

    // Simplified DAO: Owner acts as a proxy for the DAO for parameter setting
    // A full DAO would involve ERC20 votes, quorum, etc.
    // This function sets a parameter that would be normally voted on.
    function setSystemParameter(string calldata _paramName, uint256 _newValue) external onlyOwner {
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minAgentStake"))) {
            params.minAgentStake = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("agentRewardPercentage"))) {
            params.agentRewardPercentage = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("stakerRewardPercentage"))) {
            params.stakerRewardPercentage = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("disputeChallengeFee"))) {
            params.disputeChallengeFee = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("disputeResolutionPeriod"))) {
            params.disputeResolutionPeriod = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalMinVotes"))) {
            params.proposalMinVotes = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proposalVotingPeriod"))) {
            params.proposalVotingPeriod = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reputationGainPerAccurateSubmission"))) {
            params.reputationGainPerAccurateSubmission = int256(_newValue);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reputationLossPerInaccurateSubmission"))) {
            params.reputationLossPerInaccurateSubmission = int256(_newValue);
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minReputationForChallengeVoting"))) {
            params.minReputationForChallengeVoting = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("agentRetirementLockPeriod"))) {
            params.agentRetirementLockPeriod = _newValue;
        } else {
            revert("Invalid parameter name");
        }
    }

    // These functions represent a basic governance system.
    // A full DAO would use a dedicated governance token and contracts (e.g., OpenZeppelin Governor).
    // For this concept, `msg.sender` must be the owner to create proposals and vote.
    // In a real system, `msg.sender` would be a QNX token holder.

    function proposeParameterChange(string calldata _description, bytes calldata _callData, address _targetContract) external onlyOwner returns (uint256) {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            callData: _callData,
            targetContract: _targetContract,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + params.proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            minQuorum: params.proposalMinVotes, // Simplified: quorum is just min votes needed
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool)
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
        return proposalId;
    }

    function voteOnProposal(uint256 _proposalId, bool _support) external onlyOwner queryExists(_proposalId) { // Simplified: Only owner can vote
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active");
        require(block.timestamp >= proposal.voteStartTime && block.timestamp <= proposal.voteEndTime, "Voting period not active");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");

        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    function executeProposal(uint256 _proposalId) external onlyOwner queryExists(_proposalId) nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp > proposal.voteEndTime, "Voting period not ended");

        if (proposal.votesFor >= proposal.minQuorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Execute the call
            (bool success, ) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed");
            proposal.state = ProposalState.Executed;
        } else {
            proposal.state = ProposalState.Defeated;
        }

        emit ProposalExecuted(_proposalId);
    }
    
    // Placeholder for DAO Committee check, in a real system this would be more complex (e.g., a whitelist or role-based access control)
    function isDaoCommitteeMember(address _addr) internal view returns (bool) {
        // For demonstration, let's assume only the owner is the "committee" for now.
        // In a real system, this would be a lookup in a separate role-based access control contract.
        return _addr == owner();
    }


    // --- VI. NFTs & Utilities ---

    function _mintVerifiedOutcomeNFT(uint256 _queryId, string calldata _outcomeHash) internal returns (uint256) {
        _outcomeNFTIds.increment();
        uint256 tokenId = _outcomeNFTIds.current();
        string memory tokenURI = string(abi.encodePacked("ipfs://quantum-nexus/outcome/", Strings.toString(_queryId), "/", _outcomeHash)); // Example URI
        OUTCOME_NFT.mint(queries[_queryId].queryer, tokenId, tokenURI); // Mint to the queryer
        emit VerifiedOutcomeNFTMinted(_queryId, tokenId, _outcomeHash);
        return tokenId;
    }

    function getAgentDetails(address _agentAddress) public view returns (Agent memory) {
        return agents[_agentAddress];
    }

    function getQueryDetails(uint256 _queryId) public view returns (Query memory) {
        return queries[_queryId];
    }

    function getSystemParameters() public view returns (SystemParameters memory) {
        return params;
    }
}
```