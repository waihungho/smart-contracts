Okay, this is an exciting challenge! Creating a sophisticated, non-duplicative, and trendy smart contract with at least 20 functions requires combining several advanced concepts.

I'll propose a contract for a "Decentralized Autonomous Research & Development Network" (DARDN). This contract aims to foster collaborative innovation by leveraging reputation, dynamic NFTs, AI agent integration, and on-chain governance for managing research tasks and distributing rewards.

---

## Contract Name: DARDN (Decentralized Autonomous Research & Development Network)

### Outline:
1.  **Core Concepts & Vision:**
    *   **Gamified Research & Development:** Incentivizes individuals and AI agents to solve complex problems.
    *   **Reputation System:** Builds trust and assigns influence based on performance and contributions.
    *   **Dynamic NFTs (DARDN-Agents):** Unique NFTs representing participants, whose metadata evolves with their on-chain reputation and activity.
    *   **AI Agent Integration:** Designed to interact with and reward autonomous AI entities (represented by specific agent types).
    *   **Decentralized Task Management:** Proposing, assigning, solving, and verifying tasks.
    *   **Reputation-Weighted Governance:** Community-driven decision-making where influence scales with reputation.
    *   **Token Economics:** Utilizes an associated `DARDNToken` for staking, rewards, and collateral.

2.  **Actors/Roles:**
    *   **Network Admin (Owner):** Initial setup, emergency pause.
    *   **DARDN-Agent:** Any participant (human or AI) registered with an NFT.
    *   **Task Proposer:** Submits research/development tasks.
    *   **Task Solver:** Claims and completes tasks.
    *   **Task Verifier:** Reviews and approves solutions.
    *   **Community:** Votes on proposals, disputes.

3.  **Key Flows:**
    *   Agent Registration -> Task Proposal -> Task Assignment -> Solution Submission -> Verification -> Reward/Reputation Update -> Governance (e.g., parameter changes, grant approvals).

---

### Function Summary (25+ Functions):

**I. Core Infrastructure & Access Control:**
1.  `constructor`: Initializes the contract, sets the DARDN Token address and owner.
2.  `emergencyPause`: Allows the owner or high-reputation governance to pause critical functions.
3.  `unpause`: Unpauses the contract.
4.  `setDARDNTokenAddress`: Updates the associated DARDN Token address (governance-controlled).
5.  `withdrawContractBalance`: Allows DARDN governance to withdraw excess funds from the contract to treasury.

**II. Agent Management (Dynamic NFTs):**
6.  `registerAgent`: Mints a unique DARDN-Agent NFT for a new participant.
7.  `updateAgentProfile`: Allows an agent to update their public profile metadata (e.g., expertise tags).
8.  `transferAgentOwnership`: Standard ERC721 transfer of an agent NFT.
9.  `setAgentType`: Classifies an agent as Human, AI, or Hybrid (governance-controlled for verification).
10. `tokenURI`: Generates the dynamic metadata URI for an agent NFT based on their reputation.

**III. Reputation System:**
11. `grantReputationScore`: Awards reputation points for successful task completion, verification, etc.
12. `slashReputationScore`: Deducts reputation points for malicious activity or failed verifications/disputes.
13. `getReputationScore`: Retrieves the current reputation score of an agent.
14. `getAgentRank`: Determines an agent's tier (e.g., Novice, Journeyman, Master, Grandmaster) based on reputation.

**IV. Task Management:**
15. `proposeTask`: Allows an agent to propose a new R&D task, requiring a DARDN Token collateral stake.
16. `voteOnTaskProposal`: Community votes on the validity and necessity of a proposed task (reputation-weighted).
17. `assignTask`: An eligible agent claims an approved task, potentially requiring a collateral stake.
18. `submitTaskSolution`: The assigned agent submits their solution (e.g., IPFS hash of results).
19. `verifyTaskSolution`: Eligible verifiers assess a submitted solution, requiring a stake.
20. `disputeTaskSolution`: Allows an agent to dispute a verification result.
21. `resolveDispute`: A governance-approved arbitrator or a community vote resolves disputes.
22. `claimTaskReward`: Allows the solver and verifiers to claim their rewards after successful completion/verification.
23. `cancelTask`: Cancels a task and refunds collateral if it's unassigned or stuck for too long.

**V. Governance & Treasury:**
24. `proposeGovernanceChange`: Initiates a proposal for contract parameter changes or upgrades (high reputation required).
25. `voteOnGovernanceProposal`: Agents vote on governance proposals (reputation and stake-weighted).
26. `executeGovernanceProposal`: Executes an approved governance proposal.
27. `requestGrant`: An agent can request a grant from the DARDN treasury for general R&D.
28. `voteOnGrantProposal`: Community votes on grant requests.
29. `executeGrant`: Disburses funds for an approved grant.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline: DARDN (Decentralized Autonomous Research & Development Network) ---
// I. Core Infrastructure & Access Control
// II. Agent Management (Dynamic NFTs)
// III. Reputation System
// IV. Task Management
// V. Governance & Treasury

// --- Function Summary: ---
// I. Core Infrastructure & Access Control:
// 1. constructor: Initializes contract, sets DARDN Token address and owner.
// 2. emergencyPause: Pauses critical functions by owner/governance.
// 3. unpause: Unpauses the contract.
// 4. setDARDNTokenAddress: Updates DARDN Token address (governance-controlled).
// 5. withdrawContractBalance: Allows DARDN governance to withdraw funds to treasury.

// II. Agent Management (Dynamic NFTs):
// 6. registerAgent: Mints a DARDN-Agent NFT for a new participant.
// 7. updateAgentProfile: Allows agent to update profile metadata.
// 8. transferAgentOwnership: Standard ERC721 transfer.
// 9. setAgentType: Classifies agent as Human/AI/Hybrid (governance-controlled).
// 10. tokenURI: Generates dynamic NFT metadata URI based on reputation.

// III. Reputation System:
// 11. grantReputationScore: Awards reputation points.
// 12. slashReputationScore: Deducts reputation points.
// 13. getReputationScore: Retrieves an agent's reputation.
// 14. getAgentRank: Determines an agent's tier based on reputation.

// IV. Task Management:
// 15. proposeTask: Agent proposes a task with DARDN Token collateral.
// 16. voteOnTaskProposal: Community votes on task validity (reputation-weighted).
// 17. assignTask: Eligible agent claims an approved task, potentially staking collateral.
// 18. submitTaskSolution: Assigned agent submits solution (e.g., IPFS hash).
// 19. verifyTaskSolution: Eligible verifiers assess solution, staking collateral.
// 20. disputeTaskSolution: Agent disputes a verification result.
// 21. resolveDispute: Governance/arbitrator resolves disputes.
// 22. claimTaskReward: Solver/verifiers claim rewards after successful completion/verification.
// 23. cancelTask: Cancels a task and refunds collateral if stuck.

// V. Governance & Treasury:
// 24. proposeGovernanceChange: Initiates proposal for contract changes (high reputation required).
// 25. voteOnGovernanceProposal: Agents vote on governance proposals (reputation/stake-weighted).
// 26. executeGovernanceProposal: Executes an approved governance proposal.
// 27. requestGrant: Agent requests grant from DARDN treasury.
// 28. voteOnGrantProposal: Community votes on grant requests.
// 29. executeGrant: Disburses funds for an approved grant.


contract DARDN is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables & Constants ---
    IERC20 public DARDNToken;

    Counters.Counter private _agentIds;
    Counters.Counter private _taskIds;
    Counters.Counter private _proposalIds;

    uint256 public minReputationForTaskProposal = 50;
    uint256 public minReputationForSolver = 20;
    uint256 public minReputationForVerifier = 30;
    uint256 public minReputationForGovernanceProposal = 100;
    uint256 public verificationQuorum = 2; // Min verifiers needed
    uint256 public taskProposalVoteQuorumPercent = 51; // % of total reputation
    uint256 public governanceProposalVoteQuorumPercent = 60; // % of total reputation

    uint256 public taskProposalCollateralAmount;
    uint256 public taskSolverStakeAmount;
    uint256 public taskVerifierStakeAmount;

    uint256 public taskRewardBaseAmount; // Base reward for solvers
    uint256 public verifierRewardPercent = 10; // % of taskRewardBaseAmount for verifiers

    // Pause state
    bool public paused = false;

    // --- Enums ---
    enum AgentType { Human, AI, Hybrid }
    enum TaskStatus { Proposed, Approved, Assigned, SolutionSubmitted, Verified, Disputed, Completed, Cancelled }
    enum ProposalType { GovernanceChange, GrantRequest, TaskApproval }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum DisputeStatus { Pending, ResolvedAccepted, ResolvedRejected }

    // --- Structs ---
    struct Agent {
        uint256 id;
        address owner;
        AgentType agentType;
        uint256 reputationScore;
        string profileURI; // IPFS hash or similar for more detailed agent profile
    }

    struct Task {
        uint256 id;
        uint256 proposerAgentId;
        string title;
        string descriptionURI; // IPFS hash for detailed task description
        uint256 collateralAmount; // DARDNToken collateral from proposer
        address proposerCollateralReturnAddress; // Address to return collateral if cancelled

        uint256 assignedSolverAgentId;
        uint256 solverStakeAmount; // DARDNToken stake from solver

        string solutionURI; // IPFS hash for submitted solution
        uint256 submissionTime;

        mapping(uint256 => bool) verifiedBy; // agentId => isVerified
        mapping(uint256 => uint256) verifierStakes; // agentId => stakeAmount
        uint256 successfulVerifiersCount;

        TaskStatus status;
        uint256 creationTime;
        uint256 completionTime;
    }

    struct Proposal {
        uint256 id;
        uint256 proposerAgentId;
        ProposalType pType;
        bytes data; // Encoded function call for GovernanceChange, or details for Grant/Task
        uint256 creationTime;
        uint256 votingEndTime;
        
        mapping(uint256 => bool) hasVoted; // agentId => voted
        uint256 totalReputationFor;
        uint256 totalReputationAgainst;
        uint256 totalStakeFor;
        uint256 totalStakeAgainst; // For stake-weighted votes
        
        ProposalStatus status;
        uint256 associatedEntityId; // task ID for TaskApproval, or 0 for others
    }

    // --- Mappings ---
    mapping(uint256 => Agent) public agents; // agentId => Agent struct
    mapping(address => uint256) public agentAddressToId; // address => agentId (0 if not registered)
    mapping(uint256 => Task) public tasks; // taskId => Task struct
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal struct

    // For dynamic NFT metadata
    string public baseTokenURI;

    // --- Events ---
    event Paused(address account);
    event Unpaused(address account);
    event AgentRegistered(uint256 indexed agentId, address indexed owner, AgentType agentType, string profileURI);
    event AgentProfileUpdated(uint256 indexed agentId, string newProfileURI);
    event AgentTypeSet(uint256 indexed agentId, AgentType newType);
    event ReputationGranted(uint256 indexed agentId, uint256 amount);
    event ReputationSlashed(uint256 indexed agentId, uint256 amount);
    event TaskProposed(uint256 indexed taskId, uint256 indexed proposerAgentId, string title, uint256 collateral);
    event TaskApproved(uint256 indexed taskId);
    event TaskAssigned(uint256 indexed taskId, uint256 indexed solverAgentId);
    event TaskSolutionSubmitted(uint256 indexed taskId, uint256 indexed solverAgentId, string solutionURI);
    event TaskVerified(uint256 indexed taskId, uint256 indexed verifierAgentId);
    event TaskDisputed(uint256 indexed taskId, uint256 indexed disputerAgentId);
    event TaskDisputeResolved(uint256 indexed taskId, DisputeStatus status);
    event TaskCompleted(uint256 indexed taskId, uint256 indexed solverAgentId, uint256 rewardAmount);
    event TaskCancelled(uint256 indexed taskId);
    event RewardClaimed(uint256 indexed agentId, uint256 amount);
    event GovernanceProposalProposed(uint256 indexed proposalId, uint256 indexed proposerAgentId, ProposalType pType, bytes data);
    event ProposalVoted(uint256 indexed proposalId, uint256 indexed voterAgentId, bool support, uint256 reputationWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event GrantRequested(uint256 indexed proposalId, uint256 indexed requesterAgentId, uint256 amount);
    event GrantExecuted(uint256 indexed proposalId, uint256 indexed recipientAgentId, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyAgent(address _addr) {
        require(agentAddressToId[_addr] != 0, "Caller is not a registered agent");
        _;
    }

    modifier onlyRegisteredAgent(uint256 _agentId) {
        require(agents[_agentId].id != 0, "Agent ID does not exist");
        _;
    }

    modifier sufficientReputation(uint256 _minReputation) {
        require(agents[agentAddressToId[msg.sender]].reputationScore >= _minReputation, "Insufficient reputation");
        _;
    }

    modifier onlyGovernanceOrOwner() {
        // More sophisticated governance would be a multi-sig or timelock for these actions
        require(msg.sender == owner() || isGovernanceApproved(), "Only governance or owner");
        _;
    }

    // --- Constructor ---
    constructor(address _DARDNTokenAddress, string memory _baseTokenURI)
        ERC721("DARDN Agent NFT", "DARDN-A")
        Ownable(msg.sender)
    {
        DARDNToken = IERC20(_DARDNTokenAddress);
        baseTokenURI = _baseTokenURI;

        // Set initial parameters (can be changed by governance)
        taskProposalCollateralAmount = 100 * (10 ** DARDNToken.decimals());
        taskSolverStakeAmount = 50 * (10 ** DARDNToken.decimals());
        taskVerifierStakeAmount = 25 * (10 ** DARDNToken.decimals());
        taskRewardBaseAmount = 200 * (10 ** DARDNToken.decimals());
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @dev Pauses the contract in case of emergency. Callable by owner or via governance.
     */
    function emergencyPause() public onlyGovernanceOrOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Callable by owner or via governance.
     */
    function unpause() public onlyGovernanceOrOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Allows governance to set the DARDNToken address.
     * @param _newTokenAddress The address of the new DARDN ERC20 token.
     */
    function setDARDNTokenAddress(address _newTokenAddress) public onlyGovernanceOrOwner {
        require(_newTokenAddress != address(0), "Invalid token address");
        DARDNToken = IERC20(_newTokenAddress);
    }

    /**
     * @dev Allows DARDN governance to withdraw excess DARDN tokens from the contract to the main treasury.
     *      This would typically send to a dedicated Treasury contract. For simplicity, we send to the owner.
     *      In a real DAO, this would be a multi-sig or timelock treasury contract.
     * @param _amount The amount of DARDN tokens to withdraw.
     */
    function withdrawContractBalance(uint256 _amount) public onlyGovernanceOrOwner whenNotPaused nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(DARDNToken.balanceOf(address(this)) >= _amount, "Insufficient contract balance");
        DARDNToken.transfer(owner(), _amount); // Or a dedicated treasury address
    }

    // Placeholder for more complex governance approval check (e.g., proposal passed)
    function isGovernanceApproved() internal view returns (bool) {
        // In a real DAO, this would check if a specific proposal ID has passed
        // For simplicity, we assume an owner-controlled governance for this exercise.
        return msg.sender == owner();
    }


    // --- II. Agent Management (Dynamic NFTs) ---

    /**
     * @dev Mints a unique DARDN-Agent NFT for a new participant.
     * @param _profileURI IPFS hash or URL for initial agent profile metadata.
     * @param _agentType Initial classification of the agent (Human, AI, Hybrid).
     */
    function registerAgent(string memory _profileURI, AgentType _agentType) public whenNotPaused {
        require(agentAddressToId[msg.sender] == 0, "Address already registered as an agent");

        _agentIds.increment();
        uint256 newAgentId = _agentIds.current();

        _mint(msg.sender, newAgentId);
        _setTokenURI(newAgentId, _baseTokenURI); // Base URI, then dynamic part later

        agents[newAgentId] = Agent({
            id: newAgentId,
            owner: msg.sender,
            agentType: _agentType,
            reputationScore: 0, // Starts with 0 reputation
            profileURI: _profileURI
        });
        agentAddressToId[msg.sender] = newAgentId;

        emit AgentRegistered(newAgentId, msg.sender, _agentType, _profileURI);
    }

    /**
     * @dev Allows an agent to update their public profile URI.
     * @param _newProfileURI The new IPFS hash or URL for agent profile metadata.
     */
    function updateAgentProfile(string memory _newProfileURI) public whenNotPaused onlyAgent(msg.sender) {
        uint256 agentId = agentAddressToId[msg.sender];
        agents[agentId].profileURI = _newProfileURI;
        emit AgentProfileUpdated(agentId, _newProfileURI);
    }

    /**
     * @dev Standard ERC721 transfer of an agent NFT.
     *      Overrides the base ERC721 transfer to update internal agent mapping.
     * @param from The address of the current owner.
     * @param to The address of the new owner.
     * @param tokenId The ID of the agent NFT to transfer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        super.transferFrom(from, to, tokenId);
        // Update internal mapping for the new owner
        agentAddressToId[to] = tokenId;
        agentAddressToId[from] = 0; // Clear old owner's mapping
        agents[tokenId].owner = to; // Update agent struct's owner
    }
    
    // Additional standard ERC721 functions that are inherited directly:
    // approve, getApproved, setApprovalForAll, isApprovedForAll, balanceOf, ownerOf

    /**
     * @dev Allows governance to classify or re-classify an agent's type (Human, AI, Hybrid).
     *      This could be based on a verification process.
     * @param _agentId The ID of the agent to classify.
     * @param _newType The new AgentType.
     */
    function setAgentType(uint256 _agentId, AgentType _newType) public onlyGovernanceOrOwner onlyRegisteredAgent(_agentId) {
        agents[_agentId].agentType = _newType;
        emit AgentTypeSet(_agentId, _newType);
    }

    /**
     * @dev Overrides ERC721's _baseURI to provide dynamic tokenURI.
     *      The actual tokenURI will point to an off-chain server that generates metadata
     *      based on the agent's on-chain reputation and other attributes.
     * @param tokenId The ID of the NFT.
     * @return A URL pointing to the JSON metadata for the NFT.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 reputation = agents[tokenId].reputationScore;
        // In a real system, this would point to a server:
        // return string(abi.encodePacked(baseTokenURI, "/", Strings.toString(tokenId), "?reputation=", Strings.toString(reputation)));
        // For demonstration, a simplified mock:
        return string(abi.encodePacked(baseTokenURI, "agent/", uint256ToString(tokenId), "/metadata?reputation=", uint256ToString(reputation)));
    }

    // Helper for tokenURI - basic uint256 to string
    function uint256ToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // --- III. Reputation System ---

    /**
     * @dev Grants reputation points to an agent.
     *      This would be called internally by task completion, successful verification, etc.
     *      Can also be called by governance for special contributions.
     * @param _agentId The ID of the agent to reward.
     * @param _amount The amount of reputation to grant.
     */
    function grantReputationScore(uint256 _agentId, uint256 _amount) public onlyGovernanceOrOwner onlyRegisteredAgent(_agentId) {
        agents[_agentId].reputationScore = agents[_agentId].reputationScore.add(_amount);
        emit ReputationGranted(_agentId, _amount);
    }

    /**
     * @dev Slashes reputation points from an agent.
     *      Called internally for failed verifications, malicious disputes, or by governance for misconduct.
     * @param _agentId The ID of the agent to penalize.
     * @param _amount The amount of reputation to slash.
     */
    function slashReputationScore(uint256 _agentId, uint256 _amount) public onlyGovernanceOrOwner onlyRegisteredAgent(_agentId) {
        agents[_agentId].reputationScore = agents[_agentId].reputationScore.sub(_amount);
        emit ReputationSlashed(_agentId, _amount);
    }

    /**
     * @dev Retrieves the current reputation score of an agent.
     * @param _agentId The ID of the agent.
     * @return The agent's current reputation score.
     */
    function getReputationScore(uint256 _agentId) public view onlyRegisteredAgent(_agentId) returns (uint256) {
        return agents[_agentId].reputationScore;
    }

    /**
     * @dev Determines an agent's rank based on their reputation score.
     *      This can be used for UI display or for tiered access.
     * @param _agentId The ID of the agent.
     * @return A string representing the agent's rank.
     */
    function getAgentRank(uint256 _agentId) public view onlyRegisteredAgent(_agentId) returns (string memory) {
        uint256 reputation = agents[_agentId].reputationScore;
        if (reputation >= 1000) return "Grandmaster";
        if (reputation >= 500) return "Master";
        if (reputation >= 200) return "Journeyman";
        if (reputation >= 50) return "Apprentice";
        return "Novice";
    }

    // --- IV. Task Management ---

    /**
     * @dev Allows an agent to propose a new R&D task.
     *      Requires a reputation threshold and DARDN Token collateral.
     * @param _title The title of the task.
     * @param _descriptionURI IPFS hash or URL for detailed task description.
     */
    function proposeTask(string memory _title, string memory _descriptionURI)
        public
        whenNotPaused
        onlyAgent(msg.sender)
        sufficientReputation(minReputationForTaskProposal)
        nonReentrant
    {
        uint256 proposerAgentId = agentAddressToId[msg.sender];
        require(DARDNToken.transferFrom(msg.sender, address(this), taskProposalCollateralAmount), "Collateral transfer failed");

        _taskIds.increment();
        uint256 newTaskId = _taskIds.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            proposerAgentId: proposerAgentId,
            title: _title,
            descriptionURI: _descriptionURI,
            collateralAmount: taskProposalCollateralAmount,
            proposerCollateralReturnAddress: msg.sender,
            assignedSolverAgentId: 0,
            solverStakeAmount: 0,
            solutionURI: "",
            submissionTime: 0,
            successfulVerifiersCount: 0,
            status: TaskStatus.Proposed,
            creationTime: block.timestamp,
            completionTime: 0
        });

        // Create a proposal for the community to approve this task
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposerAgentId: proposerAgentId,
            pType: ProposalType.TaskApproval,
            data: abi.encode(newTaskId), // Store task ID in data
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + 3 days, // 3 days for voting
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            totalStakeFor: 0,
            totalStakeAgainst: 0,
            status: ProposalStatus.Pending,
            associatedEntityId: newTaskId
        });

        emit TaskProposed(newTaskId, proposerAgentId, _title, taskProposalCollateralAmount);
        emit GovernanceProposalProposed(proposalId, proposerAgentId, ProposalType.TaskApproval, abi.encode(newTaskId));
    }

    /**
     * @dev Allows agents to vote on a proposed task (a TaskApproval proposal).
     *      Vote weight is determined by reputation score.
     * @param _proposalId The ID of the task approval proposal.
     * @param _support True if voting for approval, false for rejection.
     */
    function voteOnTaskProposal(uint256 _proposalId, bool _support) public whenNotPaused onlyAgent(msg.sender) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.pType == ProposalType.TaskApproval, "Not a task approval proposal");
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");

        uint256 voterAgentId = agentAddressToId[msg.sender];
        require(!proposal.hasVoted[voterAgentId], "Agent has already voted on this proposal");

        uint256 voterReputation = agents[voterAgentId].reputationScore;
        require(voterReputation > 0, "Agent must have reputation to vote");

        proposal.hasVoted[voterAgentId] = true;
        if (_support) {
            proposal.totalReputationFor = proposal.totalReputationFor.add(voterReputation);
        } else {
            proposal.totalReputationAgainst = proposal.totalReputationAgainst.add(voterReputation);
        }
        emit ProposalVoted(_proposalId, voterAgentId, _support, voterReputation);
    }

    /**
     * @dev Called to execute a TaskApproval proposal, changing the task status.
     *      Can be called by any agent once voting period ends.
     * @param _proposalId The ID of the task approval proposal.
     */
    function executeTaskApproval(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.pType == ProposalType.TaskApproval, "Not a task approval proposal");
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");

        uint256 totalReputation = proposal.totalReputationFor.add(proposal.totalReputationAgainst);
        require(totalReputation > 0, "No votes cast on proposal"); // Ensure some votes were cast

        uint256 totalPossibleReputation = 0; // In a real system, you'd track total active reputation
        for (uint256 i = 1; i <= _agentIds.current(); i++) {
            // This loop is for illustrative purposes; in a large system, this is expensive.
            // A better way is to sum total active reputation at proposal start or use a snapshot.
            if(agents[i].id != 0) totalPossibleReputation = totalPossibleReputation.add(agents[i].reputationScore);
        }
        
        uint256 minQuorumReputation = totalPossibleReputation.mul(taskProposalVoteQuorumPercent).div(100);
        require(totalReputation >= minQuorumReputation, "Quorum not met for task approval");


        Task storage task = tasks[proposal.associatedEntityId];
        if (proposal.totalReputationFor > proposal.totalReputationAgainst) {
            proposal.status = ProposalStatus.Approved;
            task.status = TaskStatus.Approved;
            emit TaskApproved(task.id);
        } else {
            proposal.status = ProposalStatus.Rejected;
            task.status = TaskStatus.Cancelled; // If rejected, it's cancelled
            // Refund proposer's collateral
            DARDNToken.transfer(task.proposerCollateralReturnAddress, task.collateralAmount);
            emit TaskCancelled(task.id);
            emit TaskApproved(task.id); // This event is only emitted for approved, maybe a TaskRejected event instead
        }
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows an approved task to be assigned to an eligible agent.
     *      Requires the solver to stake DARDN Tokens.
     * @param _taskId The ID of the task to assign.
     */
    function assignTask(uint256 _taskId)
        public
        whenNotPaused
        onlyAgent(msg.sender)
        sufficientReputation(minReputationForSolver)
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Approved, "Task is not in approved state");
        require(task.assignedSolverAgentId == 0, "Task is already assigned");

        uint256 solverAgentId = agentAddressToId[msg.sender];
        require(DARDNToken.transferFrom(msg.sender, address(this), taskSolverStakeAmount), "Solver stake transfer failed");

        task.assignedSolverAgentId = solverAgentId;
        task.solverStakeAmount = taskSolverStakeAmount;
        task.status = TaskStatus.Assigned;

        emit TaskAssigned(_taskId, solverAgentId);
    }

    /**
     * @dev Allows the assigned agent to submit their solution for a task.
     * @param _taskId The ID of the task.
     * @param _solutionURI IPFS hash or URL for the solution artifacts/results.
     */
    function submitTaskSolution(uint256 _taskId, string memory _solutionURI) public whenNotPaused onlyAgent(msg.sender) {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Assigned, "Task is not assigned");
        require(agentAddressToId[msg.sender] == task.assignedSolverAgentId, "Only the assigned solver can submit a solution");
        require(bytes(_solutionURI).length > 0, "Solution URI cannot be empty");

        task.solutionURI = _solutionURI;
        task.submissionTime = block.timestamp;
        task.status = TaskStatus.SolutionSubmitted;

        emit TaskSolutionSubmitted(_taskId, agentAddressToId[msg.sender], _solutionURI);
    }

    /**
     * @dev Allows eligible verifiers to assess a submitted solution.
     *      Verifiers must stake DARDN Tokens and have sufficient reputation.
     * @param _taskId The ID of the task.
     * @param _isCorrect Boolean indicating if the solution is deemed correct.
     */
    function verifyTaskSolution(uint256 _taskId, bool _isCorrect)
        public
        whenNotPaused
        onlyAgent(msg.sender)
        sufficientReputation(minReputationForVerifier)
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.SolutionSubmitted, "Task is not in solution submitted state");

        uint256 verifierAgentId = agentAddressToId[msg.sender];
        require(!task.verifiedBy[verifierAgentId], "Agent has already verified this task");

        require(DARDNToken.transferFrom(msg.sender, address(this), taskVerifierStakeAmount), "Verifier stake transfer failed");
        task.verifierStakes[verifierAgentId] = taskVerifierStakeAmount;

        task.verifiedBy[verifierAgentId] = _isCorrect; // Store their assessment

        // If _isCorrect, increment successful verifiers count.
        // A more complex system would have weighted verification or majority consensus.
        if (_isCorrect) {
            task.successfulVerifiersCount++;
        }

        emit TaskVerified(_taskId, verifierAgentId);

        // If enough successful verifiers, mark as verified and proceed
        if (task.successfulVerifiersCount >= verificationQuorum) {
            task.status = TaskStatus.Verified;
            task.completionTime = block.timestamp;
            // Now, anyone can call claimTaskReward
            emit TaskCompleted(_taskId, task.assignedSolverAgentId, taskRewardBaseAmount);
        }
    }

    /**
     * @dev Allows an agent to dispute a verification result, typically by staking more collateral.
     *      This initiates a dispute resolution process.
     * @param _taskId The ID of the task to dispute.
     * @param _reasonURI IPFS hash or URL for the dispute reason/evidence.
     */
    function disputeTaskSolution(uint256 _taskId, string memory _reasonURI)
        public
        whenNotPaused
        onlyAgent(msg.sender)
        nonReentrant
    {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.SolutionSubmitted || task.status == TaskStatus.Verified, "Task not in disputable state");
        // Only the solver or a verifier (or proposer) can dispute.
        uint256 disputerAgentId = agentAddressToId[msg.sender];
        require(disputerAgentId == task.assignedSolverAgentId || task.verifiedBy[disputerAgentId], "Only solver or verifier can dispute");

        // This would transition to a DisputeStatus.Pending and create a governance proposal for resolution.
        // For simplicity, we directly set to disputed.
        task.status = TaskStatus.Disputed;

        // Optionally, require dispute collateral here
        // DARDNToken.transferFrom(msg.sender, address(this), disputeCollateralAmount);

        // In a real system, this would create a new proposal of type DisputeResolution.
        emit TaskDisputed(_taskId, disputerAgentId);
    }

    /**
     * @dev Resolves a disputed task. Callable by governance or a designated arbitrator.
     *      This function would be called after a governance vote or external arbitration.
     * @param _taskId The ID of the task to resolve.
     * @param _acceptSolution If true, the solution is deemed correct; otherwise, incorrect.
     */
    function resolveDispute(uint256 _taskId, bool _acceptSolution) public onlyGovernanceOrOwner whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Disputed, "Task is not in disputed state");

        if (_acceptSolution) {
            task.status = TaskStatus.Verified;
            task.completionTime = block.timestamp;
            emit TaskDisputeResolved(_taskId, DisputeStatus.ResolvedAccepted);
            emit TaskCompleted(_taskId, task.assignedSolverAgentId, taskRewardBaseAmount);
            // Distribute rewards and reputation as if successfully verified
            // Also, penalize disputer if the dispute was unfounded
            // Example: grantReputationScore(task.assignedSolverAgentId, 10);
        } else {
            task.status = TaskStatus.Cancelled;
            emit TaskDisputeResolved(_taskId, DisputeStatus.ResolvedRejected);
            // Penalize solver, refund verifiers, potentially slash reputation
            // Example: slashReputationScore(task.assignedSolverAgentId, 20);
            // Refund proposer collateral.
            DARDNToken.transfer(task.proposerCollateralReturnAddress, task.collateralAmount);
        }
        // In either case, handle stakes: release correct verifier stakes, slash incorrect ones.
        _releaseStakesAndHandlePenalties(_taskId, _acceptSolution);
    }

    /**
     * @dev Internal helper function to handle verifier stakes and potential penalties.
     * @param _taskId The ID of the task.
     * @param _solutionAccepted Whether the solution was ultimately accepted.
     */
    function _releaseStakesAndHandlePenalties(uint256 _taskId, bool _solutionAccepted) internal {
        Task storage task = tasks[_taskId];
        uint256 totalVerifiers = 0; // For iteration, not a count.

        // This is a simplified iteration. In a large system, this would need to be gas-optimized
        // or a different data structure to avoid iterating over many verifiers.
        // For example, store verifier IDs in a dynamic array.
        // Assuming agent IDs are somewhat sequential for this example.
        for (uint256 i = 1; i <= _agentIds.current(); i++) {
            if (task.verifierStakes[i] > 0) {
                totalVerifiers++;
                bool verifierAssessment = task.verifiedBy[i];
                if ((verifierAssessment && _solutionAccepted) || (!verifierAssessment && !_solutionAccepted)) {
                    // Verifier was correct, return stake and reward them
                    DARDNToken.transfer(agents[i].owner, task.verifierStakes[i].add(taskRewardBaseAmount.mul(verifierRewardPercent).div(100)));
                    grantReputationScore(i, 5); // Reward reputation for correct assessment
                } else {
                    // Verifier was incorrect, slash their stake (send to treasury or burn)
                    // DARDNToken.transfer(owner(), task.verifierStakes[i]); // Send to treasury
                    // Or simply keep it in the contract to be withdrawn via withdrawContractBalance
                    slashReputationScore(i, 5); // Slash reputation for incorrect assessment
                }
                task.verifierStakes[i] = 0; // Clear stake
            }
        }
    }


    /**
     * @dev Allows the solver and successful verifiers to claim their rewards after a task is completed/verified.
     *      Only callable once per task.
     * @param _taskId The ID of the task.
     */
    function claimTaskReward(uint256 _taskId) public whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Verified, "Task is not in verified state");
        require(task.completionTime > 0, "Task not yet completed");

        // Transfer rewards to solver
        DARDNToken.transfer(agents[task.assignedSolverAgentId].owner, taskRewardBaseAmount);
        grantReputationScore(task.assignedSolverAgentId, 20); // Reward reputation to solver

        // Refund solver's stake
        DARDNToken.transfer(agents[task.assignedSolverAgentId].owner, task.solverStakeAmount);
        task.solverStakeAmount = 0; // Clear stake

        // Refund proposer's collateral
        DARDNToken.transfer(task.proposerCollateralReturnAddress, task.collateralAmount);
        task.collateralAmount = 0; // Clear collateral

        task.status = TaskStatus.Completed; // Mark as completed and rewards distributed
        emit RewardClaimed(task.assignedSolverAgentId, taskRewardBaseAmount);
    }

    /**
     * @dev Allows an owner or governance to cancel a task and refund collateral if it's unassigned or stuck.
     * @param _taskId The ID of the task to cancel.
     */
    function cancelTask(uint256 _taskId) public onlyGovernanceOrOwner whenNotPaused nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(task.status == TaskStatus.Proposed || task.status == TaskStatus.Approved || task.status == TaskStatus.Assigned, "Task cannot be cancelled in current state");

        // If assigned, slash solver's stake, otherwise just refund proposer.
        if (task.assignedSolverAgentId != 0 && task.solverStakeAmount > 0) {
            // Optionally, slash solver's stake for not completing (send to treasury)
            // DARDNToken.transfer(owner(), task.solverStakeAmount);
            slashReputationScore(task.assignedSolverAgentId, 10);
            task.solverStakeAmount = 0;
        }

        // Refund proposer's collateral
        if (task.collateralAmount > 0) {
            DARDNToken.transfer(task.proposerCollateralReturnAddress, task.collateralAmount);
            task.collateralAmount = 0;
        }

        task.status = TaskStatus.Cancelled;
        emit TaskCancelled(_taskId);
    }


    // --- V. Governance & Treasury ---

    /**
     * @dev Initiates a governance proposal for contract parameter changes or grants.
     *      Requires a high reputation threshold.
     * @param _pType The type of proposal (GovernanceChange, GrantRequest).
     * @param _data Encoded function call for GovernanceChange, or amount for GrantRequest.
     * @param _votingDuration The duration in seconds for the voting period.
     * @param _associatedEntityId Optional: For tying a proposal to an existing entity (e.g., specific task dispute).
     */
    function proposeGovernanceChange(ProposalType _pType, bytes memory _data, uint256 _votingDuration, uint256 _associatedEntityId)
        public
        whenNotPaused
        onlyAgent(msg.sender)
        sufficientReputation(minReputationForGovernanceProposal)
    {
        uint256 proposerAgentId = agentAddressToId[msg.sender];
        require(_pType != ProposalType.TaskApproval, "TaskApproval proposals are initiated by proposeTask");
        
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposerAgentId: proposerAgentId,
            pType: _pType,
            data: _data,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + _votingDuration,
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            totalStakeFor: 0, // Could add stake-weighted voting
            totalStakeAgainst: 0,
            status: ProposalStatus.Pending,
            associatedEntityId: _associatedEntityId
        });

        emit GovernanceProposalProposed(newProposalId, proposerAgentId, _pType, _data);
    }

    /**
     * @dev Allows agents to vote on governance proposals.
     *      Vote weight is determined by reputation score.
     * @param _proposalId The ID of the proposal.
     * @param _support True if voting for approval, false for rejection.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) public whenNotPaused onlyAgent(msg.sender) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.pType != ProposalType.TaskApproval, "Use voteOnTaskProposal for task approvals");
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp <= proposal.votingEndTime, "Voting period has ended");

        uint256 voterAgentId = agentAddressToId[msg.sender];
        require(!proposal.hasVoted[voterAgentId], "Agent has already voted on this proposal");

        uint256 voterReputation = agents[voterAgentId].reputationScore;
        require(voterReputation > 0, "Agent must have reputation to vote");

        proposal.hasVoted[voterAgentId] = true;
        if (_support) {
            proposal.totalReputationFor = proposal.totalReputationFor.add(voterReputation);
        } else {
            proposal.totalReputationAgainst = proposal.totalReputationAgainst.sub(voterReputation); // Subtracting here
        }
        emit ProposalVoted(_proposalId, voterAgentId, _support, voterReputation);
    }

    /**
     * @dev Executes an approved governance proposal. Callable by anyone once voting period ends and quorum is met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.pType != ProposalType.TaskApproval, "Use executeTaskApproval for task approvals");
        require(proposal.status == ProposalStatus.Pending, "Proposal not in pending state");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");

        uint256 totalReputation = proposal.totalReputationFor.add(proposal.totalReputationAgainst);
        require(totalReputation > 0, "No votes cast on proposal"); // Ensure some votes were cast

        uint256 totalPossibleReputation = 0;
        for (uint256 i = 1; i <= _agentIds.current(); i++) {
            if(agents[i].id != 0) totalPossibleReputation = totalPossibleReputation.add(agents[i].reputationScore);
        }
        
        uint256 minQuorumReputation = totalPossibleReputation.mul(governanceProposalVoteQuorumPercent).div(100);
        require(totalReputation >= minQuorumReputation, "Quorum not met for governance proposal");


        if (proposal.totalReputationFor > proposal.totalReputationAgainst) {
            proposal.status = ProposalStatus.Approved;
            if (proposal.pType == ProposalType.GovernanceChange) {
                // Execute the encoded function call
                (bool success,) = address(this).call(proposal.data);
                require(success, "Governance change execution failed");
            } else if (proposal.pType == ProposalType.GrantRequest) {
                // Grant requests are handled by executeGrant separately, this just approves it
                // We'll update the status to approved, and the actual transfer happens in executeGrant.
            }
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows an agent to request a grant from the DARDN treasury for general R&D or project funding.
     *      This creates a 'GrantRequest' proposal that the community votes on.
     * @param _amount The amount of DARDN Tokens requested.
     * @param _reasonURI IPFS hash or URL for the grant proposal details.
     */
    function requestGrant(uint256 _amount, string memory _reasonURI)
        public
        whenNotPaused
        onlyAgent(msg.sender)
        sufficientReputation(minReputationForGovernanceProposal)
    {
        require(_amount > 0, "Grant amount must be positive");
        
        uint256 proposerAgentId = agentAddressToId[msg.sender];
        
        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposerAgentId: proposerAgentId,
            pType: ProposalType.GrantRequest,
            data: abi.encode(_amount, _reasonURI), // Encode amount and reason
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // 7 days for voting on grants
            totalReputationFor: 0,
            totalReputationAgainst: 0,
            totalStakeFor: 0,
            totalStakeAgainst: 0,
            status: ProposalStatus.Pending,
            associatedEntityId: proposerAgentId // Grant is for the proposer
        });

        emit GrantRequested(newProposalId, proposerAgentId, _amount);
        emit GovernanceProposalProposed(newProposalId, proposerAgentId, ProposalType.GrantRequest, abi.encode(_amount));
    }

    /**
     * @dev Allows anyone to execute an approved grant proposal, transferring funds from the contract to the recipient.
     * @param _proposalId The ID of the grant proposal.
     */
    function executeGrant(uint256 _proposalId) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        require(proposal.pType == ProposalType.GrantRequest, "Not a grant request proposal");
        require(proposal.status == ProposalStatus.Approved, "Grant proposal not approved");
        require(block.timestamp > proposal.votingEndTime, "Voting period has not ended");

        uint256 grantAmount;
        string memory reasonURI;
        (grantAmount, reasonURI) = abi.decode(proposal.data, (uint256, string));

        address recipientAddress = agents[proposal.associatedEntityId].owner;
        require(DARDNToken.balanceOf(address(this)) >= grantAmount, "Insufficient treasury balance for grant");
        DARDNToken.transfer(recipientAddress, grantAmount);

        proposal.status = ProposalStatus.Executed;
        emit GrantExecuted(_proposalId, proposal.associatedEntityId, grantAmount);
    }

    // --- Getter functions for external data queries ---

    function getAgentDetails(uint256 _agentId) public view returns (uint256 id, address ownerAddr, AgentType agentType, uint256 reputationScore, string memory profileURI) {
        Agent storage agent = agents[_agentId];
        require(agent.id != 0, "Agent does not exist");
        return (agent.id, agent.owner, agent.agentType, agent.reputationScore, agent.profileURI);
    }

    function getTaskDetails(uint256 _taskId) public view returns (uint256 id, uint256 proposerAgentId, string memory title, TaskStatus status, uint256 assignedSolverAgentId, string memory solutionURI) {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        return (task.id, task.proposerAgentId, task.title, task.status, task.assignedSolverAgentId, task.solutionURI);
    }

    function getProposalDetails(uint256 _proposalId) public view returns (uint256 id, uint256 proposerAgentId, ProposalType pType, ProposalStatus status, uint256 totalFor, uint256 totalAgainst, uint256 votingEnd) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.id != 0, "Proposal does not exist");
        return (proposal.id, proposal.proposerAgentId, proposal.pType, proposal.status, proposal.totalReputationFor, proposal.totalReputationAgainst, proposal.votingEndTime);
    }

    // Helper to get contract's DARDN token balance (treasury)
    function getTreasuryBalance() public view returns (uint256) {
        return DARDNToken.balanceOf(address(this));
    }

    // Fallback and Receive functions (for direct token transfers)
    receive() external payable {
        // Allow ETH to be sent to the contract, if needed for future features
        // In this DARDNToken-focused contract, this would typically not be used.
    }
    fallback() external payable {
        // Fallback for unexpected calls
    }
}
```