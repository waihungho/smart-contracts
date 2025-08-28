This smart contract, **CognitoNexus**, is designed as a decentralized expertise and collective intelligence network. It empowers users, "Cognito Agents," to propose challenges, submit knowledge, and validate contributions through a peer-review system. A core element is the "Cognito Score" – an on-chain reputation metric that influences voting power, rewards, and the evolution of dynamic Agent NFTs. The system is governed by a DAO, allowing agents to collectively steer the platform's parameters and resolve disputes.

---

## CognitoNexus Smart Contract Outline & Function Summary

**Contract Name:** `CognitoNexus`

**Core Concepts:**
1.  **Cognito Agent NFTs:** ERC-721 tokens representing unique agent identities. Their metadata dynamically reflects an agent's `CognitoScore` and expertise.
2.  **Cognito Score (Reputation):** An on-chain metric that grows with valuable contributions and accurate validations. It determines voting weight in the DAO and validation rounds.
3.  **Expertise Modules:** Categories for agents to declare and prove their specialization.
4.  **Challenges & Knowledge Submissions:** A system where problems can be proposed (Challenges) and solutions/information submitted (Knowledge Submissions).
5.  **Validation Rounds:** A peer-review mechanism where agents stake tokens and vote on the quality and accuracy of Knowledge Submissions.
6.  **Staking & Slashing:** Incentivizes honest participation and penalizes malicious or inaccurate actions.
7.  **Decentralized Autonomous Organization (DAO):** Governs protocol parameters, dispute resolution, and expertise module creation, with voting power weighted by `CognitoScore`.
8.  **Adaptive Incentives (via DAO):** Parameters like stake amounts and reward ratios can be adjusted through DAO proposals.

---

### Function Summary (Total: 23 Functions)

**I. Core Agent Interaction & Reputation (5 functions)**
1.  `registerAgent(string memory _agentProfileURI)`: Mints a new `CognitoAgentNFT` for the caller, initializes their profile, and assigns a base `CognitoScore`.
2.  `updateAgentProfileURI(uint256 _agentId, string memory _newProfileURI)`: Allows an agent to update the off-chain metadata URI linked to their NFT.
3.  `getAgentCognitoScore(uint256 _agentId) view returns (uint256)`: Retrieves the `CognitoScore` for a specific agent.
4.  `delegateCognitoScore(uint256 _agentId, address _delegatee)`: Enables an agent to delegate their `CognitoScore` (voting power) to another address.
5.  `undelegateCognitoScore(uint256 _agentId)`: Revokes any existing `CognitoScore` delegation for an agent.

**II. Expertise Modules & Specialization (4 functions)**
6.  `proposeExpertiseModule(string memory _name, string memory _description, uint256 _stakeAmount)`: Initiates a DAO proposal to establish a new recognized expertise module, requiring a stake.
7.  `addAgentExpertise(uint256 _agentId, uint256 _moduleId)`: An agent declares their intention to specialize in an `ExpertiseModule`. (Actual proof/validation is handled through submissions/challenges.)
8.  `removeAgentExpertise(uint256 _agentId, uint256 _moduleId)`: Allows an agent to remove a declared expertise from their profile.
9.  `getAgentExpertiseModules(uint256 _agentId) view returns (uint256[] memory)`: Returns a list of `ExpertiseModule` IDs an agent has declared.

**III. Challenge & Knowledge Submission Lifecycle (8 functions)**
10. `proposeChallenge(string memory _title, string memory _descriptionURI, uint256 _rewardAmount, uint256[] memory _requiredExpertiseModules, uint256 _stakeAmount)`: Allows an agent to propose a new challenge, staking tokens and defining potential rewards and required expertise.
11. `submitKnowledge(uint256 _challengeId, string memory _submissionURI, uint256[] memory _expertisesUsed, uint256 _stakeAmount)`: An agent submits a solution or knowledge piece for a given challenge (or as independent knowledge), requiring a stake.
12. `acceptChallengeSubmission(uint256 _challengeId, uint256 _submissionId)`: The creator of a challenge can perform an initial acceptance of a submission. This partially rewards the submitter and marks it for potential formal validation.
13. `requestValidationRound(uint256 _submissionId, uint256 _stakeAmount)`: Initiates a formal validation round for a `KnowledgeSubmission`, requiring a stake from the requestor.
14. `submitValidationVote(uint256 _validationRoundId, bool _isAccepted, string memory _commentURI, uint256 _stakeAmount)`: Agents participate in a validation round by staking and voting on the submission's accuracy. `CognitoScore` influences vote weight.
15. `finalizeValidationRound(uint256 _validationRoundId)`: Calculates the final outcome of a validation round, distributing rewards to honest voters/submitters and slashing those who voted incorrectly or submitted poor quality content. Updates `CognitoScore`.
16. `disputeValidationResult(uint256 _validationRoundId, uint256 _stakeAmount)`: Allows an agent to dispute the outcome of a `ValidationRound`, initiating a DAO proposal for review.
17. `getChallengeDetails(uint256 _challengeId) view returns (...)`: Retrieves all details for a specific challenge.
18. `getSubmissionDetails(uint256 _submissionId) view returns (...)`: Retrieves all details for a specific knowledge submission.

**IV. DAO Governance & Protocol Adaptation (6 functions)**
19. `proposeDAOParameterChange(string memory _description, bytes memory _calldata, address _targetContract, uint256 _stakeAmount)`: Agents can propose changes to core protocol parameters (e.g., stake amounts, reward multipliers) via a DAO vote.
20. `proposeDAOAdminAction(string memory _description, bytes memory _calldata, address _targetContract, uint256 _stakeAmount)`: Agents can propose administrative actions, such as revoking an agent for severe misconduct, subject to DAO approval.
21. `voteOnProposal(uint256 _proposalId, bool _approve)`: Agents vote on active DAO proposals, with their vote weight determined by their `CognitoScore`.
22. `executeProposal(uint256 _proposalId)`: Executes a DAO proposal if it has passed, met quorum, and its voting period has ended.
23. `depositFunds() payable`: Allows anyone to contribute funds to the `CognitoNexus` rewards pool.
24. `withdrawRewards(uint256 _agentId)`: Allows an agent to withdraw their accumulated and available rewards.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title CognitoNexus
 * @dev Decentralized Expertise & Collective Intelligence Network
 * This contract enables users (Cognito Agents, represented by NFTs) to propose challenges,
 * submit knowledge, and validate contributions through a peer-review system.
 * It features an on-chain reputation system (Cognito Score), dynamic NFTs,
 * staking/slashing for quality control, and DAO governance.
 *
 * Outline & Function Summary:
 *
 * Core Concepts:
 * 1.  Cognito Agent NFTs: ERC-721 tokens representing unique agent identities. Their metadata dynamically reflects an agent's `CognitoScore` and expertise.
 * 2.  Cognito Score (Reputation): An on-chain metric that grows with valuable contributions and accurate validations. It determines voting weight in the DAO and validation rounds.
 * 3.  Expertise Modules: Categories for agents to declare and prove their specialization.
 * 4.  Challenges & Knowledge Submissions: A system where problems can be proposed (Challenges) and solutions/information submitted (Knowledge Submissions).
 * 5.  Validation Rounds: A peer-review mechanism where agents stake tokens and vote on the quality and accuracy of Knowledge Submissions.
 * 6.  Staking & Slashing: Incentivizes honest participation and penalizes malicious or inaccurate actions.
 * 7.  Decentralized Autonomous Organization (DAO): Governs protocol parameters, dispute resolution, and expertise module creation, with voting power weighted by `CognitoScore`.
 * 8.  Adaptive Incentives (via DAO): Parameters like stake amounts and reward ratios can be adjusted through DAO proposals.
 *
 * Function Summary (Total: 24 Functions)
 *
 * I. Core Agent Interaction & Reputation (5 functions)
 * 1.  registerAgent(string memory _agentProfileURI): Mints a new `CognitoAgentNFT` for the caller, initializes their profile, and assigns a base `CognitoScore`.
 * 2.  updateAgentProfileURI(uint256 _agentId, string memory _newProfileURI): Allows an agent to update the off-chain metadata URI linked to their NFT.
 * 3.  getAgentCognitoScore(uint256 _agentId) view returns (uint256): Retrieves the `CognitoScore` for a specific agent.
 * 4.  delegateCognitoScore(uint256 _agentId, address _delegatee): Enables an agent to delegate their `CognitoScore` (voting power) to another address.
 * 5.  undelegateCognitoScore(uint256 _agentId): Revokes any existing `CognitoScore` delegation for an agent.
 *
 * II. Expertise Modules & Specialization (4 functions)
 * 6.  proposeExpertiseModule(string memory _name, string memory _description, uint256 _stakeAmount): Initiates a DAO proposal to establish a new recognized expertise module, requiring a stake.
 * 7.  addAgentExpertise(uint256 _agentId, uint256 _moduleId): An agent declares their intention to specialize in an `ExpertiseModule`. (Actual proof/validation is handled through submissions/challenges.)
 * 8.  removeAgentExpertise(uint256 _agentId, uint256 _moduleId): Allows an agent to remove a declared expertise from their profile.
 * 9.  getAgentExpertiseModules(uint256 _agentId) view returns (uint256[] memory): Returns a list of `ExpertiseModule` IDs an agent has declared.
 *
 * III. Challenge & Knowledge Submission Lifecycle (8 functions)
 * 10. proposeChallenge(string memory _title, string memory _descriptionURI, uint256 _rewardAmount, uint256[] memory _requiredExpertiseModules, uint256 _stakeAmount): Allows an agent to propose a new challenge, staking tokens and defining potential rewards and required expertise.
 * 11. submitKnowledge(uint256 _challengeId, string memory _submissionURI, uint256[] memory _expertisesUsed, uint256 _stakeAmount): An agent submits a solution or knowledge piece for a given challenge (or as independent knowledge), requiring a stake.
 * 12. acceptChallengeSubmission(uint256 _challengeId, uint256 _submissionId): The creator of a challenge can perform an initial acceptance of a submission. This partially rewards the submitter and marks it for potential formal validation.
 * 13. requestValidationRound(uint256 _submissionId, uint256 _stakeAmount): Initiates a formal validation round for a `KnowledgeSubmission`, requiring a stake from the requestor.
 * 14. submitValidationVote(uint256 _validationRoundId, bool _isAccepted, string memory _commentURI, uint256 _stakeAmount): Agents participate in a validation round by staking and voting on the submission's accuracy. `CognitoScore` influences vote weight.
 * 15. finalizeValidationRound(uint256 _validationRoundId): Calculates the final outcome of a validation round, distributing rewards to honest voters/submitters and slashing those who voted incorrectly or submitted poor quality content. Updates `CognitoScore`.
 * 16. disputeValidationResult(uint256 _validationRoundId, uint256 _stakeAmount): Allows an agent to dispute the outcome of a `ValidationRound`, initiating a DAO proposal for review.
 * 17. getChallengeDetails(uint256 _challengeId) view returns (...): Retrieves all details for a specific challenge.
 * 18. getSubmissionDetails(uint256 _submissionId) view returns (...): Retrieves all details for a specific knowledge submission.
 *
 * IV. DAO Governance & Protocol Adaptation (6 functions)
 * 19. proposeDAOParameterChange(string memory _description, bytes memory _calldata, address _targetContract, uint256 _stakeAmount): Agents can propose changes to core protocol parameters (e.g., stake amounts, reward multipliers) via a DAO vote.
 * 20. proposeDAOAdminAction(string memory _description, bytes memory _calldata, address _targetContract, uint256 _stakeAmount): Agents can propose administrative actions, such as revoking an agent for severe misconduct, subject to DAO approval.
 * 21. voteOnProposal(uint256 _proposalId, bool _approve): Agents vote on active DAO proposals, with their vote weight determined by their `CognitoScore`.
 * 22. executeProposal(uint256 _proposalId): Executes a DAO proposal if it has passed, met quorum, and its voting period has ended.
 * 23. depositFunds() payable: Allows anyone to contribute funds to the `CognitoNexus` rewards pool.
 * 24. withdrawRewards(uint256 _agentId): Allows an agent to withdraw their accumulated and available rewards.
 */
contract CognitoNexus is Ownable, ReentrancyGuard {
    // --- State Variables ---
    IERC721 public immutable cognitoAgentNFT; // Address of the CognitoAgentNFT contract

    uint256 public constant INITIAL_COGNITO_SCORE = 1000;
    uint256 public constant MIN_VALIDATION_DURATION = 1 days; // Minimum time for a validation round
    uint256 public constant MAX_VALIDATION_DURATION = 7 days;  // Maximum time
    uint256 public constant MIN_DAO_VOTING_DURATION = 3 days;  // Minimum time for DAO proposals
    uint256 public constant MAX_DAO_VOTING_DURATION = 14 days; // Maximum time

    // Dynamic DAO parameters (can be changed via proposals)
    uint256 public proposalStakeMultiplier = 1e16; // 0.01 ETH for typical stakes
    uint256 public validationRewardMultiplier = 50; // 50% of stake as reward for correct validation
    uint256 public challengeCreatorAcceptanceRewardRatio = 1000; // 10% (1000/10000) of challenge reward for initial acceptance
    uint256 public cognitoScoreMultiplier = 10; // How much score changes per successful action
    uint256 public minProposalQuorumCognitoScore = 100000; // Minimum total CognitoScore needed to pass a DAO proposal
    uint256 public minProposalApprovalCognitoScoreRatio = 5100; // 51% (5100/10000) of total vote weight for approval

    uint256 private _nextAgentId = 1;
    uint256 private _nextChallengeId = 1;
    uint256 private _nextSubmissionId = 1;
    uint256 private _nextValidationRoundId = 1;
    uint256 private _nextExpertiseModuleId = 1;
    uint256 private _nextDAOProposalId = 1;

    // --- Mappings & Data Structures ---

    // Agent Data
    struct Agent {
        address walletAddress;
        uint256 cognitoScore;
        address delegatedTo; // Address to whom voting power is delegated
        mapping(uint256 => bool) expertiseModules; // module ID => true if agent has this expertise
        uint256[] expertiseModuleList; // To iterate through expertise modules
        uint256 accumulatedRewards; // Rewards available for withdrawal
    }
    mapping(uint256 => Agent) public agents; // Agent ID => Agent details
    mapping(address => uint256) public agentIdByAddress; // Wallet address => Agent ID

    // Enums for clarity
    enum ChallengeStatus { Active, Resolved, Disputed }
    enum SubmissionStatus { PendingValidation, AcceptedByChallengeCreator, AcceptedByValidation, RejectedByValidation, Disputed }
    enum ValidationStatus { Pending, Finalized, Disputed }
    enum ProposalStatus { Pending, Approved, Rejected, Executed }

    // Challenge Data
    struct Challenge {
        uint256 id;
        uint256 creatorAgentId;
        string title;
        string descriptionURI; // IPFS hash for full description
        uint256 rewardAmount; // Total reward if challenge is solved
        uint256[] requiredExpertiseModules;
        uint256 stakeAmount; // Stake required to propose
        ChallengeStatus status;
        uint255 creationTime;
    }
    mapping(uint256 => Challenge) public challenges;

    // Knowledge Submission Data
    struct KnowledgeSubmission {
        uint256 id;
        uint256 challengeId; // Can be 0 if independent knowledge
        uint256 submitterAgentId;
        string submissionURI; // IPFS hash for the knowledge content
        uint256[] expertisesUsed;
        uint256 stakeAmount; // Stake required to submit
        SubmissionStatus status;
        uint255 creationTime;
        uint255 acceptedByChallengeCreatorTime; // Timestamp if accepted by challenge creator
        uint256 validationRoundId; // If validated, ID of the final validation round
    }
    mapping(uint256 => KnowledgeSubmission) public submissions;

    // Validation Round Data
    struct ValidationRound {
        uint256 id;
        uint256 submissionId;
        uint252 proposerAgentId;
        uint252 stakeAmountPerVoter; // How much each voter stakes
        uint255 startTime;
        uint255 endTime;
        uint256 totalYesVotesCount; // Number of distinct voters
        uint256 totalNoVotesCount; // Number of distinct voters
        uint256 totalYesCognitoScoreWeight; // Sum of CognitoScores of 'yes' voters
        uint256 totalNoCognitoScoreWeight; // Sum of CognitoScores of 'no' voters
        mapping(uint256 => bool) hasVoted; // agentId => true if voted
        mapping(uint256 => bool) voteResult; // agentId => true (yes) / false (no)
        ValidationStatus status;
        bool outcomeAccepted; // True if submission was accepted, false if rejected
        address[] votersAddresses; // To iterate through voters for rewards/slashing
        uint256[] votersAgentIds; // Corresponding agent IDs
    }
    mapping(uint256 => ValidationRound) public validationRounds;

    // Expertise Module Data
    struct ExpertiseModule {
        uint256 id;
        string name;
        string description;
        uint255 creationTime;
        uint252 proposedByAgentId;
        ProposalStatus proposalStatus; // For the DAO proposal to create it
    }
    mapping(uint256 => ExpertiseModule) public expertiseModules;

    // DAO Proposal Data
    struct DAOProposal {
        uint256 id;
        uint252 proposerAgentId;
        string description;
        bytes calldataToExecute; // Function call to execute if proposal passes
        address targetContract; // Contract to call the function on
        uint256 stakeAmount; // Stake required to propose
        uint255 creationTime;
        uint255 votingEndTime;
        uint256 totalYesCognitoScoreWeight;
        uint256 totalNoCognitoScoreWeight;
        mapping(uint256 => bool) hasVoted; // agentId => voted
        ProposalStatus status;
        bool executed;
    }
    mapping(uint256 => DAOProposal) public daoProposals;


    // --- Events ---
    event AgentRegistered(uint256 indexed agentId, address indexed agentAddress, string profileURI);
    event AgentProfileUpdated(uint252 indexed agentId, string newProfileURI);
    event CognitoScoreUpdated(uint252 indexed agentId, uint256 newScore, string reason);
    event ScoreDelegated(uint252 indexed agentId, address indexed delegatee);
    event ScoreUndelegated(uint252 indexed agentId);

    event ExpertiseModuleProposed(uint252 indexed moduleId, uint252 indexed proposerAgentId, string name);
    event AgentExpertiseAdded(uint252 indexed agentId, uint252 indexed moduleId);
    event AgentExpertiseRemoved(uint252 indexed agentId, uint252 indexed moduleId);

    event ChallengeProposed(uint252 indexed challengeId, uint252 indexed creatorAgentId, uint256 rewardAmount);
    event KnowledgeSubmitted(uint252 indexed submissionId, uint252 indexed challengeId, uint252 indexed submitterAgentId);
    event ChallengeSubmissionAccepted(uint252 indexed challengeId, uint252 indexed submissionId, uint252 indexed acceptorAgentId);

    event ValidationRoundRequested(uint252 indexed validationRoundId, uint252 indexed submissionId, uint252 indexed proposerAgentId);
    event ValidationVoteSubmitted(uint252 indexed validationRoundId, uint252 indexed voterAgentId, bool isAccepted);
    event ValidationRoundFinalized(uint252 indexed validationRoundId, bool outcomeAccepted, uint256 rewardsDistributed, uint256 slashedAmount);
    event ValidationResultDisputed(uint252 indexed validationRoundId, uint252 indexed disputerAgentId);

    event DAOProposalCreated(uint252 indexed proposalId, uint252 indexed proposerAgentId, string description);
    event DAOVoteSubmitted(uint252 indexed proposalId, uint252 indexed voterAgentId, bool approved);
    event DAOProposalExecuted(uint252 indexed proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event RewardsWithdrawn(uint252 indexed agentId, address indexed receiver, uint256 amount);

    // --- Constructor ---
    constructor(address _cognitoAgentNFT) Ownable(msg.sender) {
        require(_cognitoAgentNFT != address(0), "Invalid NFT contract address");
        cognitoAgentNFT = IERC721(_cognitoAgentNFT);
    }

    // --- Modifiers ---
    modifier onlyAgent(uint256 _agentId) {
        require(agentIdByAddress[msg.sender] == _agentId, "CognitoNexus: Caller is not the agent owner");
        _;
    }

    modifier onlyAgentOrDelegate(uint256 _agentId) {
        require(agentIdByAddress[msg.sender] == _agentId || agents[_agentId].delegatedTo == msg.sender, "CognitoNexus: Caller is not agent or delegate");
        _;
    }

    modifier agentExists(uint256 _agentId) {
        require(_agentId > 0 && agents[_agentId].walletAddress != address(0), "CognitoNexus: Agent does not exist");
        _;
    }

    modifier checkMinStake(uint256 _stakeAmount) {
        require(msg.value >= _stakeAmount, "CognitoNexus: Insufficient stake provided");
        _;
    }

    // --- I. Core Agent Interaction & Reputation ---

    /**
     * @dev Registers a new Cognito Agent. Mints a new NFT and initializes agent data.
     * @param _agentProfileURI IPFS hash or URL for the agent's initial profile metadata.
     */
    function registerAgent(string memory _agentProfileURI) public payable nonReentrant {
        require(agentIdByAddress[msg.sender] == 0, "CognitoNexus: Address already registered as an agent");

        uint256 newAgentId = _nextAgentId++;
        cognitoAgentNFT.safeMint(msg.sender, newAgentId); // Mints the NFT

        agents[newAgentId].walletAddress = msg.sender;
        agents[newAgentId].cognitoScore = INITIAL_COGNITO_SCORE;
        agents[newAgentId].accumulatedRewards = 0;
        agentIdByAddress[msg.sender] = newAgentId;

        emit AgentRegistered(newAgentId, msg.sender, _agentProfileURI);
        // Note: The actual _agentProfileURI is handled by the NFT's setTokenURI or a metadata service
        // that queries CognitoNexus for agent state. This URI can be used as a hint.
    }

    /**
     * @dev Allows an agent to update the off-chain metadata URI for their profile.
     * @param _agentId The ID of the agent.
     * @param _newProfileURI The new IPFS hash or URL for the agent's profile metadata.
     */
    function updateAgentProfileURI(uint256 _agentId, string memory _newProfileURI) public onlyAgent(_agentId) agentExists(_agentId) {
        // This function doesn't directly update the NFT's tokenURI as that's often managed by the NFT contract.
        // Instead, it can trigger an event or store this URI in a separate struct if needed.
        // For dynamic NFTs, the NFT's tokenURI logic would query this contract's state.
        emit AgentProfileUpdated(_agentId, _newProfileURI);
    }

    /**
     * @dev Retrieves the Cognito Score for a specific agent.
     * @param _agentId The ID of the agent.
     * @return The current Cognito Score of the agent.
     */
    function getAgentCognitoScore(uint256 _agentId) public view agentExists(_agentId) returns (uint256) {
        return agents[_agentId].cognitoScore;
    }

    /**
     * @dev Allows an agent to delegate their voting power (Cognito Score) to another address.
     * @param _agentId The ID of the agent delegating their score.
     * @param _delegatee The address to which the score will be delegated.
     */
    function delegateCognitoScore(uint256 _agentId, address _delegatee) public onlyAgent(_agentId) agentExists(_agentId) {
        require(_delegatee != address(0), "CognitoNexus: Delegatee cannot be zero address");
        require(_delegatee != agents[_agentId].walletAddress, "CognitoNexus: Cannot delegate to self");

        agents[_agentId].delegatedTo = _delegatee;
        emit ScoreDelegated(_agentId, _delegatee);
    }

    /**
     * @dev Revokes any existing Cognito Score delegation for an agent.
     * @param _agentId The ID of the agent.
     */
    function undelegateCognitoScore(uint256 _agentId) public onlyAgent(_agentId) agentExists(_agentId) {
        require(agents[_agentId].delegatedTo != address(0), "CognitoNexus: No active delegation to undelegate");

        agents[_agentId].delegatedTo = address(0);
        emit ScoreUndelegated(_agentId);
    }

    // --- II. Expertise Modules & Specialization ---

    /**
     * @dev Initiates a DAO proposal to establish a new recognized expertise module.
     * @param _name The name of the expertise module (e.g., "ZK-Rollup Research").
     * @param _description A brief description of the expertise.
     * @param _stakeAmount The stake required to propose this module.
     */
    function proposeExpertiseModule(string memory _name, string memory _description, uint256 _stakeAmount) public payable nonReentrant {
        uint256 proposerAgentId = agentIdByAddress[msg.sender];
        require(proposerAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);

        // Store stake in contract
        // The DAO proposal system will manage the stake.
        // This is a special DAO proposal type.

        uint256 newModuleId = _nextExpertiseModuleId++;
        expertiseModules[newModuleId] = ExpertiseModule({
            id: newModuleId,
            name: _name,
            description: _description,
            creationTime: uint255(block.timestamp),
            proposedByAgentId: uint252(proposerAgentId),
            proposalStatus: ProposalStatus.Pending
        });

        // Create a DAO proposal for this expertise module
        uint256 proposalId = _nextDAOProposalId++;
        daoProposals[proposalId] = DAOProposal({
            id: proposalId,
            proposerAgentId: uint252(proposerAgentId),
            description: string(abi.encodePacked("Propose new expertise module: ", _name)),
            calldataToExecute: abi.encodeCall(this.finalizeNewExpertiseModule, (newModuleId, true)), // A dummy call that will be executed if passed
            targetContract: address(this),
            stakeAmount: _stakeAmount,
            creationTime: uint255(block.timestamp),
            votingEndTime: uint255(block.timestamp + MIN_DAO_VOTING_DURATION), // Use min duration for now, DAO can adjust
            totalYesCognitoScoreWeight: 0,
            totalNoCognitoScoreWeight: 0,
            status: ProposalStatus.Pending,
            executed: false
        });
        daoProposals[proposalId].hasVoted[proposerAgentId] = true; // Proposer auto-votes yes
        daoProposals[proposalId].totalYesCognitoScoreWeight += agents[proposerAgentId].cognitoScore;

        emit ExpertiseModuleProposed(newModuleId, proposerAgentId, _name);
        emit DAOProposalCreated(proposalId, proposerAgentId, daoProposals[proposalId].description);
    }

    /**
     * @dev Internal function to finalize expertise module creation based on DAO vote.
     * Only callable by `executeProposal`.
     */
    function finalizeNewExpertiseModule(uint256 _moduleId, bool _approved) external onlySelf {
        require(expertiseModules[_moduleId].id != 0, "CognitoNexus: Module does not exist");
        require(expertiseModules[_moduleId].proposalStatus == ProposalStatus.Pending, "CognitoNexus: Module proposal already finalized");

        if (_approved) {
            expertiseModules[_moduleId].proposalStatus = ProposalStatus.Approved;
        } else {
            expertiseModules[_moduleId].proposalStatus = ProposalStatus.Rejected;
            // Optionally, refund stake to proposer if rejected, or slash if proposal was malicious.
            // For now, assume stake is part of DAO proposal cost.
        }
    }

    /**
     * @dev Allows an agent to declare their intention to specialize in an ExpertiseModule.
     * This doesn't automatically grant expertise but indicates interest for future proof.
     * @param _agentId The ID of the agent.
     * @param _moduleId The ID of the expertise module.
     */
    function addAgentExpertise(uint256 _agentId, uint256 _moduleId) public onlyAgent(_agentId) agentExists(_agentId) {
        require(expertiseModules[_moduleId].id != 0 && expertiseModules[_moduleId].proposalStatus == ProposalStatus.Approved, "CognitoNexus: Expertise module not approved or does not exist");
        require(!agents[_agentId].expertiseModules[_moduleId], "CognitoNexus: Agent already declared this expertise");

        agents[_agentId].expertiseModules[_moduleId] = true;
        agents[_agentId].expertiseModuleList.push(_moduleId);
        emit AgentExpertiseAdded(_agentId, _moduleId);
    }

    /**
     * @dev Allows an agent to remove a declared expertise from their profile.
     * @param _agentId The ID of the agent.
     * @param _moduleId The ID of the expertise module to remove.
     */
    function removeAgentExpertise(uint256 _agentId, uint256 _moduleId) public onlyAgent(_agentId) agentExists(_agentId) {
        require(agents[_agentId].expertiseModules[_moduleId], "CognitoNexus: Agent does not have this expertise declared");

        agents[_agentId].expertiseModules[_moduleId] = false;
        // Efficiently remove from the dynamic array
        uint256[] storage expertiseList = agents[_agentId].expertiseModuleList;
        for (uint256 i = 0; i < expertiseList.length; i++) {
            if (expertiseList[i] == _moduleId) {
                expertiseList[i] = expertiseList[expertiseList.length - 1];
                expertiseList.pop();
                break;
            }
        }
        emit AgentExpertiseRemoved(_agentId, _moduleId);
    }

    /**
     * @dev Returns a list of ExpertiseModule IDs an agent has declared.
     * @param _agentId The ID of the agent.
     * @return An array of ExpertiseModule IDs.
     */
    function getAgentExpertiseModules(uint256 _agentId) public view agentExists(_agentId) returns (uint256[] memory) {
        return agents[_agentId].expertiseModuleList;
    }

    // --- III. Challenge & Knowledge Submission Lifecycle ---

    /**
     * @dev Allows an agent to propose a new challenge.
     * Requires staking and defines potential rewards and required expertise for solutions.
     * @param _title The title of the challenge.
     * @param _descriptionURI IPFS hash or URL for the full challenge description.
     * @param _rewardAmount The total reward amount for successfully solving this challenge.
     * @param _requiredExpertiseModules An array of expertise module IDs required for solutions.
     * @param _stakeAmount The stake required to propose this challenge.
     */
    function proposeChallenge(
        string memory _title,
        string memory _descriptionURI,
        uint256 _rewardAmount,
        uint256[] memory _requiredExpertiseModules,
        uint256 _stakeAmount
    ) public payable nonReentrant {
        uint256 creatorAgentId = agentIdByAddress[msg.sender];
        require(creatorAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);
        require(_rewardAmount > 0, "CognitoNexus: Reward amount must be greater than zero");

        uint256 newChallengeId = _nextChallengeId++;
        challenges[newChallengeId] = Challenge({
            id: newChallengeId,
            creatorAgentId: creatorAgentId,
            title: _title,
            descriptionURI: _descriptionURI,
            rewardAmount: _rewardAmount,
            requiredExpertiseModules: _requiredExpertiseModules,
            stakeAmount: _stakeAmount,
            status: ChallengeStatus.Active,
            creationTime: uint255(block.timestamp)
        });

        // Transfer funds from msg.value (stake and reward) to contract
        // For simplicity, rewards are assumed to be paid by the proposer or from the pool.
        // Here, _stakeAmount is explicitly from msg.value, rewardAmount needs separate funding or DAO approval.
        // For now, assume reward is part of the contract balance, challenge creator adds stake.
        if (msg.value > _stakeAmount) {
            // Refund any excess beyond the stake
            (bool success, ) = msg.sender.call{value: msg.value - _stakeAmount}("");
            require(success, "Failed to refund excess stake");
        }


        emit ChallengeProposed(newChallengeId, creatorAgentId, _rewardAmount);
    }

    /**
     * @dev Allows an agent to submit a solution or knowledge piece for a given challenge.
     * Can also be used for independent knowledge submissions (challengeId = 0).
     * @param _challengeId The ID of the challenge this submission addresses (0 for independent knowledge).
     * @param _submissionURI IPFS hash or URL for the knowledge content.
     * @param _expertisesUsed An array of expertise module IDs relevant to this submission.
     * @param _stakeAmount The stake required to submit this knowledge.
     */
    function submitKnowledge(
        uint256 _challengeId,
        string memory _submissionURI,
        uint256[] memory _expertisesUsed,
        uint256 _stakeAmount
    ) public payable nonReentrant {
        uint256 submitterAgentId = agentIdByAddress[msg.sender];
        require(submitterAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);

        if (_challengeId != 0) {
            require(challenges[_challengeId].id != 0, "CognitoNexus: Challenge does not exist");
            require(challenges[_challengeId].status == ChallengeStatus.Active, "CognitoNexus: Challenge is not active");
            // Check if submitter has declared required expertise (optional, can be enforced by DAO)
        }

        uint256 newSubmissionId = _nextSubmissionId++;
        submissions[newSubmissionId] = KnowledgeSubmission({
            id: newSubmissionId,
            challengeId: _challengeId,
            submitterAgentId: submitterAgentId,
            submissionURI: _submissionURI,
            expertisesUsed: _expertisesUsed,
            stakeAmount: _stakeAmount,
            status: SubmissionStatus.PendingValidation,
            creationTime: uint255(block.timestamp),
            acceptedByChallengeCreatorTime: 0,
            validationRoundId: 0
        });

        if (msg.value > _stakeAmount) {
            (bool success, ) = msg.sender.call{value: msg.value - _stakeAmount}("");
            require(success, "Failed to refund excess stake");
        }

        emit KnowledgeSubmitted(newSubmissionId, _challengeId, submitterAgentId);
    }

    /**
     * @dev The creator of a challenge can perform an initial acceptance of a submission.
     * This acts as a first-pass review, potentially awarding a partial reward, and marks the submission
     * for potential formal validation.
     * @param _challengeId The ID of the challenge.
     * @param _submissionId The ID of the submission to accept.
     */
    function acceptChallengeSubmission(uint256 _challengeId, uint256 _submissionId) public nonReentrant {
        require(challenges[_challengeId].id != 0, "CognitoNexus: Challenge does not exist");
        require(challenges[_challengeId].creatorAgentId == agentIdByAddress[msg.sender], "CognitoNexus: Only challenge creator can accept submission");
        require(submissions[_submissionId].id != 0, "CognitoNexus: Submission does not exist");
        require(submissions[_submissionId].challengeId == _challengeId, "CognitoNexus: Submission does not belong to this challenge");
        require(submissions[_submissionId].status == SubmissionStatus.PendingValidation, "CognitoNexus: Submission not in pending validation status");

        submissions[_submissionId].status = SubmissionStatus.AcceptedByChallengeCreator;
        submissions[_submissionId].acceptedByChallengeCreatorTime = uint255(block.timestamp);

        // Award a partial reward to the submitter and adjust Cognito Score
        uint256 partialReward = (challenges[_challengeId].rewardAmount * challengeCreatorAcceptanceRewardRatio) / 10000;
        agents[submissions[_submissionId].submitterAgentId].accumulatedRewards += partialReward;
        _updateCognitoScore(submissions[_submissionId].submitterAgentId, cognitoScoreMultiplier, "Accepted by challenge creator");

        emit ChallengeSubmissionAccepted(_challengeId, _submissionId, challenges[_challengeId].creatorAgentId);
        emit RewardsWithdrawn(submissions[_submissionId].submitterAgentId, agents[submissions[_submissionId].submitterAgentId].walletAddress, partialReward); // Simulate reward
    }

    /**
     * @dev Initiates a formal validation round for a Knowledge Submission.
     * @param _submissionId The ID of the submission to validate.
     * @param _stakeAmount The stake required from the proposer of the validation round.
     */
    function requestValidationRound(uint256 _submissionId, uint256 _stakeAmount) public payable nonReentrant {
        uint256 proposerAgentId = agentIdByAddress[msg.sender];
        require(proposerAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);
        require(submissions[_submissionId].id != 0, "CognitoNexus: Submission does not exist");
        require(submissions[_submissionId].status == SubmissionStatus.PendingValidation || submissions[_submissionId].status == SubmissionStatus.AcceptedByChallengeCreator, "CognitoNexus: Submission not in a state to be validated");
        require(submissions[_submissionId].validationRoundId == 0, "CognitoNexus: Submission already has an active or final validation round");

        uint256 newValidationRoundId = _nextValidationRoundId++;
        validationRounds[newValidationRoundId] = ValidationRound({
            id: newValidationRoundId,
            submissionId: _submissionId,
            proposerAgentId: uint252(proposerAgentId),
            stakeAmountPerVoter: proposalStakeMultiplier, // Example, DAO can set specific
            startTime: uint255(block.timestamp),
            endTime: uint255(block.timestamp + MIN_VALIDATION_DURATION), // Default duration
            totalYesVotesCount: 0,
            totalNoVotesCount: 0,
            totalYesCognitoScoreWeight: 0,
            totalNoCognitoScoreWeight: 0,
            status: ValidationStatus.Pending,
            outcomeAccepted: false,
            votersAddresses: new address[](0),
            votersAgentIds: new uint256[](0)
        });

        submissions[_submissionId].validationRoundId = newValidationRoundId;
        if (msg.value > _stakeAmount) {
            (bool success, ) = msg.sender.call{value: msg.value - _stakeAmount}("");
            require(success, "Failed to refund excess stake");
        }
        emit ValidationRoundRequested(newValidationRoundId, _submissionId, proposerAgentId);
    }

    /**
     * @dev Agents participate in a validation round by staking and voting on the submission's accuracy.
     * Cognito Score influences vote weight.
     * @param _validationRoundId The ID of the validation round.
     * @param _isAccepted True if the agent believes the submission is valid, false otherwise.
     * @param _commentURI IPFS hash or URL for any additional comments/justification for the vote.
     * @param _stakeAmount The stake provided by the voter.
     */
    function submitValidationVote(uint256 _validationRoundId, bool _isAccepted, string memory _commentURI, uint256 _stakeAmount) public payable nonReentrant {
        uint256 voterAgentId = agentIdByAddress[msg.sender];
        require(voterAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);

        ValidationRound storage round = validationRounds[_validationRoundId];
        require(round.id != 0, "CognitoNexus: Validation round does not exist");
        require(round.status == ValidationStatus.Pending, "CognitoNexus: Validation round is not active");
        require(block.timestamp <= round.endTime, "CognitoNexus: Validation round has ended");
        require(!round.hasVoted[voterAgentId], "CognitoNexus: Agent has already voted in this round");
        require(msg.value >= round.stakeAmountPerVoter, "CognitoNexus: Insufficient stake for voting");

        // Refund any excess stake
        if (msg.value > round.stakeAmountPerVoter) {
            (bool success, ) = msg.sender.call{value: msg.value - round.stakeAmountPerVoter}("");
            require(success, "Failed to refund excess stake");
        }

        uint256 actualVoterAgentId = (agents[voterAgentId].delegatedTo != address(0) && agentIdByAddress[agents[voterAgentId].delegatedTo] != 0) ? agentIdByAddress[agents[voterAgentId].delegatedTo] : voterAgentId;

        round.hasVoted[actualVoterAgentId] = true;
        round.voteResult[actualVoterAgentId] = _isAccepted;

        uint256 voteWeight = agents[actualVoterAgentId].cognitoScore;
        if (_isAccepted) {
            round.totalYesVotesCount++;
            round.totalYesCognitoScoreWeight += voteWeight;
        } else {
            round.totalNoVotesCount++;
            round.totalNoCognitoScoreWeight += voteWeight;
        }

        round.votersAddresses.push(msg.sender); // Store actual voter address
        round.votersAgentIds.push(actualVoterAgentId); // Store agent ID for later processing

        emit ValidationVoteSubmitted(_validationRoundId, actualVoterAgentId, _isAccepted);
    }

    /**
     * @dev Computes the outcome of a validation round, distributes rewards, slashes incorrect voters/submitters,
     * and updates Cognito Scores. Can be called by anyone after the voting period ends.
     * @param _validationRoundId The ID of the validation round to finalize.
     */
    function finalizeValidationRound(uint256 _validationRoundId) public nonReentrant {
        ValidationRound storage round = validationRounds[_validationRoundId];
        require(round.id != 0, "CognitoNexus: Validation round does not exist");
        require(round.status == ValidationStatus.Pending, "CognitoNexus: Validation round already finalized or disputed");
        require(block.timestamp > round.endTime, "CognitoNexus: Validation round has not ended yet");
        require(round.totalYesVotesCount + round.totalNoVotesCount > 0, "CognitoNexus: No votes were cast in this round");

        SubmissionStatus finalSubmissionStatus;
        uint256 totalCognitoScoreWeight = round.totalYesCognitoScoreWeight + round.totalNoCognitoScoreWeight;
        bool outcomeAccepted = false;

        if (totalCognitoScoreWeight == 0) { // Edge case: no voters with score, but has votes
            outcomeAccepted = round.totalYesVotesCount >= round.totalNoVotesCount; // Simple majority if no score weight
        } else {
            outcomeAccepted = round.totalYesCognitoScoreWeight >= round.totalNoCognitoScoreWeight; // Weighted majority
        }
        round.outcomeAccepted = outcomeAccepted;
        round.status = ValidationStatus.Finalized;

        KnowledgeSubmission storage submission = submissions[round.submissionId];
        uint256 submitterAgentId = submission.submitterAgentId;
        uint256 totalRewardsDistributed = 0;
        uint256 totalSlashedAmount = 0;

        if (outcomeAccepted) {
            finalSubmissionStatus = SubmissionStatus.AcceptedByValidation;
            // Reward submitter
            if (submission.challengeId != 0) {
                uint256 challengeReward = challenges[submission.challengeId].rewardAmount;
                agents[submitterAgentId].accumulatedRewards += challengeReward;
                totalRewardsDistributed += challengeReward;
                _updateCognitoScore(submitterAgentId, cognitoScoreMultiplier * 5, "Successful knowledge submission");
                challenges[submission.challengeId].status = ChallengeStatus.Resolved; // Mark challenge as resolved
            } else { // Independent knowledge, small score boost
                 _updateCognitoScore(submitterAgentId, cognitoScoreMultiplier, "Successful independent knowledge submission");
            }

            // Reward correct voters and return stake
            for (uint256 i = 0; i < round.votersAgentIds.length; i++) {
                uint256 voterAgentId = round.votersAgentIds[i];
                if (round.voteResult[voterAgentId] == true) { // Voted 'Yes' and submission was accepted
                    agents[voterAgentId].accumulatedRewards += round.stakeAmountPerVoter + (round.stakeAmountPerVoter * validationRewardMultiplier / 100);
                    totalRewardsDistributed += (round.stakeAmountPerVoter * validationRewardMultiplier / 100);
                    _updateCognitoScore(voterAgentId, cognitoScoreMultiplier, "Correct validation vote");
                } else { // Voted 'No' and submission was accepted, slash stake
                    totalSlashedAmount += round.stakeAmountPerVoter;
                    _updateCognitoScore(voterAgentId, cognitoScoreMultiplier * 2, "Incorrect validation vote (slashed)", true);
                }
            }
        } else { // Submission was rejected
            finalSubmissionStatus = SubmissionStatus.RejectedByValidation;
            // Slash submitter's stake
            totalSlashedAmount += submission.stakeAmount;
            _updateCognitoScore(submitterAgentId, cognitoScoreMultiplier * 5, "Rejected knowledge submission (slashed)", true);

            // Reward correct voters and return stake
            for (uint256 i = 0; i < round.votersAgentIds.length; i++) {
                uint256 voterAgentId = round.votersAgentIds[i];
                if (round.voteResult[voterAgentId] == false) { // Voted 'No' and submission was rejected
                    agents[voterAgentId].accumulatedRewards += round.stakeAmountPerVoter + (round.stakeAmountPerVoter * validationRewardMultiplier / 100);
                    totalRewardsDistributed += (round.stakeAmountPerVoter * validationRewardMultiplier / 100);
                    _updateCognitoScore(voterAgentId, cognitoScoreMultiplier, "Correct validation vote");
                } else { // Voted 'Yes' and submission was rejected, slash stake
                    totalSlashedAmount += round.stakeAmountPerVoter;
                    _updateCognitoScore(voterAgentId, cognitoScoreMultiplier * 2, "Incorrect validation vote (slashed)", true);
                }
            }
        }

        submission.status = finalSubmissionStatus;
        // Total slashed amount remains in the contract, can be distributed to rewards pool or DAO treasury.
        // For simplicity, it stays in the contract balance.

        emit ValidationRoundFinalized(_validationRoundId, outcomeAccepted, totalRewardsDistributed, totalSlashedAmount);
    }

    /**
     * @dev Allows an agent to dispute the outcome of a ValidationRound.
     * This initiates a DAO proposal for review.
     * @param _validationRoundId The ID of the validation round to dispute.
     * @param _stakeAmount The stake required to propose the dispute.
     */
    function disputeValidationResult(uint256 _validationRoundId, uint256 _stakeAmount) public payable nonReentrant {
        uint256 disputerAgentId = agentIdByAddress[msg.sender];
        require(disputerAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);

        ValidationRound storage round = validationRounds[_validationRoundId];
        require(round.id != 0, "CognitoNexus: Validation round does not exist");
        require(round.status == ValidationStatus.Finalized, "CognitoNexus: Validation round not finalized");
        require(submissions[round.submissionId].status != SubmissionStatus.Disputed, "CognitoNexus: Submission already under dispute");

        // Create a DAO proposal to review this validation round
        uint256 proposalId = _nextDAOProposalId++;
        daoProposals[proposalId] = DAOProposal({
            id: proposalId,
            proposerAgentId: uint252(disputerAgentId),
            description: string(abi.encodePacked("Dispute validation round #", Strings.toString(_validationRoundId))),
            calldataToExecute: abi.encodeCall(this.revertValidationRound, (_validationRoundId)), // If DAO approves, revert
            targetContract: address(this),
            stakeAmount: _stakeAmount,
            creationTime: uint255(block.timestamp),
            votingEndTime: uint255(block.timestamp + MIN_DAO_VOTING_DURATION),
            totalYesCognitoScoreWeight: 0,
            totalNoCognitoScoreWeight: 0,
            status: ProposalStatus.Pending,
            executed: false
        });
        daoProposals[proposalId].hasVoted[disputerAgentId] = true; // Proposer auto-votes yes
        daoProposals[proposalId].totalYesCognitoScoreWeight += agents[disputerAgentId].cognitoScore;

        submissions[round.submissionId].status = SubmissionStatus.Disputed;
        round.status = ValidationStatus.Disputed;

        emit ValidationResultDisputed(_validationRoundId, disputerAgentId);
        emit DAOProposalCreated(proposalId, disputerAgentId, daoProposals[proposalId].description);
    }

    /**
     * @dev Internal function to revert a validation round's outcome if a DAO dispute passes.
     * @param _validationRoundId The ID of the validation round to revert.
     */
    function revertValidationRound(uint256 _validationRoundId) external onlySelf {
        ValidationRound storage round = validationRounds[_validationRoundId];
        require(round.id != 0, "CognitoNexus: Validation round does not exist");
        require(round.status == ValidationStatus.Disputed, "CognitoNexus: Validation round not in disputed state");

        // Reset submission status and potentially revert score/reward changes
        KnowledgeSubmission storage submission = submissions[round.submissionId];
        submission.status = SubmissionStatus.PendingValidation; // Back to square one
        round.status = ValidationStatus.Pending;

        // More complex logic needed here to reverse all score/reward changes precisely.
        // For simplicity, we just reset status and allow a new validation round.
        // In a real system, this would involve detailed logging of changes or a snapshot system.
        _updateCognitoScore(submission.submitterAgentId, cognitoScoreMultiplier * 5, "Validation result reverted", true); // Penalize submitter again for requiring a dispute
        // Also need to reverse rewards/slashes for voters. This is very complex.
        // For now, focus on reverting the state and not individual rewards/slashes which would require more advanced event logging/state tracking.
    }

    /**
     * @dev Retrieves details for a specific challenge.
     * @param _challengeId The ID of the challenge.
     * @return All relevant details of the challenge.
     */
    function getChallengeDetails(uint256 _challengeId) public view returns (Challenge memory) {
        require(challenges[_challengeId].id != 0, "CognitoNexus: Challenge does not exist");
        return challenges[_challengeId];
    }

    /**
     * @dev Retrieves details for a specific knowledge submission.
     * @param _submissionId The ID of the submission.
     * @return All relevant details of the submission.
     */
    function getSubmissionDetails(uint256 _submissionId) public view returns (KnowledgeSubmission memory) {
        require(submissions[_submissionId].id != 0, "CognitoNexus: Submission does not exist");
        return submissions[_submissionId];
    }


    // --- IV. DAO Governance & Protocol Adaptation ---

    /**
     * @dev Agents can propose changes to core protocol parameters (e.g., stake amounts, reward multipliers)
     * via a DAO vote.
     * @param _description A description of the proposed change.
     * @param _calldata The encoded function call to execute if the proposal passes.
     * @param _targetContract The address of the contract to call the function on (can be `this`).
     * @param _stakeAmount The stake required to propose.
     */
    function proposeDAOParameterChange(
        string memory _description,
        bytes memory _calldata,
        address _targetContract,
        uint256 _stakeAmount
    ) public payable nonReentrant {
        uint256 proposerAgentId = agentIdByAddress[msg.sender];
        require(proposerAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);

        uint256 proposalId = _nextDAOProposalId++;
        daoProposals[proposalId] = DAOProposal({
            id: proposalId,
            proposerAgentId: uint252(proposerAgentId),
            description: _description,
            calldataToExecute: _calldata,
            targetContract: _targetContract,
            stakeAmount: _stakeAmount,
            creationTime: uint255(block.timestamp),
            votingEndTime: uint255(block.timestamp + MIN_DAO_VOTING_DURATION),
            totalYesCognitoScoreWeight: 0,
            totalNoCognitoScoreWeight: 0,
            status: ProposalStatus.Pending,
            executed: false
        });
        daoProposals[proposalId].hasVoted[proposerAgentId] = true; // Proposer auto-votes yes
        daoProposals[proposalId].totalYesCognitoScoreWeight += agents[proposerAgentId].cognitoScore;

        emit DAOProposalCreated(proposalId, proposerAgentId, _description);
    }

    /**
     * @dev Agents can propose administrative actions, such as revoking an agent for severe misconduct,
     * subject to DAO approval.
     * @param _description A description of the proposed action.
     * @param _calldata The encoded function call to execute if the proposal passes (e.g., to slash/ban an agent).
     * @param _targetContract The address of the contract to call the function on (can be `this`).
     * @param _stakeAmount The stake required to propose.
     */
    function proposeDAOAdminAction(
        string memory _description,
        bytes memory _calldata,
        address _targetContract,
        uint256 _stakeAmount
    ) public payable nonReentrant {
        uint256 proposerAgentId = agentIdByAddress[msg.sender];
        require(proposerAgentId != 0, "CognitoNexus: Caller is not a registered agent");
        checkMinStake(_stakeAmount);

        uint256 proposalId = _nextDAOProposalId++;
        daoProposals[proposalId] = DAOProposal({
            id: proposalId,
            proposerAgentId: uint252(proposerAgentId),
            description: _description,
            calldataToExecute: _calldata,
            targetContract: _targetContract,
            stakeAmount: _stakeAmount,
            creationTime: uint255(block.timestamp),
            votingEndTime: uint255(block.timestamp + MIN_DAO_VOTING_DURATION),
            totalYesCognitoScoreWeight: 0,
            totalNoCognitoScoreWeight: 0,
            status: ProposalStatus.Pending,
            executed: false
        });
        daoProposals[proposalId].hasVoted[proposerAgentId] = true; // Proposer auto-votes yes
        daoProposals[proposalId].totalYesCognitoScoreWeight += agents[proposerAgentId].cognitoScore;

        emit DAOProposalCreated(proposalId, proposerAgentId, _description);
    }

    /**
     * @dev Agents vote on active DAO proposals, with their vote weight determined by their Cognito Score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _approve True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _approve) public nonReentrant {
        uint256 voterAgentId = agentIdByAddress[msg.sender];
        require(voterAgentId != 0, "CognitoNexus: Caller is not a registered agent");

        DAOProposal storage proposal = daoProposals[_proposalId];
        require(proposal.id != 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "CognitoNexus: Proposal is not active for voting");
        require(block.timestamp <= proposal.votingEndTime, "CognitoNexus: Voting period has ended");

        uint256 actualVoterAgentId = (agents[voterAgentId].delegatedTo != address(0) && agentIdByAddress[agents[voterAgentId].delegatedTo] != 0) ? agentIdByAddress[agents[voterAgentId].delegatedTo] : voterAgentId;
        require(!proposal.hasVoted[actualVoterAgentId], "CognitoNexus: Agent has already voted on this proposal");

        uint256 voteWeight = agents[actualVoterAgentId].cognitoScore;
        require(voteWeight > 0, "CognitoNexus: Agent must have a positive Cognito Score to vote");

        proposal.hasVoted[actualVoterAgentId] = true;
        if (_approve) {
            proposal.totalYesCognitoScoreWeight += voteWeight;
        } else {
            proposal.totalNoCognitoScoreWeight += voteWeight;
        }

        emit DAOVoteSubmitted(_proposalId, actualVoterAgentId, _approve);
    }

    /**
     * @dev Executes a DAO proposal if it has passed, met quorum, and its voting period has ended.
     * Can be called by anyone.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public nonReentrant {
        DAOProposal storage proposal = daoProposals[_proposalId];
        require(proposal.id != 0, "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Pending, "CognitoNexus: Proposal not in pending status");
        require(block.timestamp > proposal.votingEndTime, "CognitoNexus: Voting period has not ended yet");
        require(!proposal.executed, "CognitoNexus: Proposal already executed");

        uint256 totalVoteWeight = proposal.totalYesCognitoScoreWeight + proposal.totalNoCognitoScoreWeight;

        // Check quorum and approval ratio
        bool passed = totalVoteWeight >= minProposalQuorumCognitoScore &&
                      (proposal.totalYesCognitoScoreWeight * 10000 / totalVoteWeight) >= minProposalApprovalCognitoScoreRatio;

        if (passed) {
            proposal.status = ProposalStatus.Approved;
            proposal.executed = true;

            // Execute the proposed action
            (bool success, bytes memory result) = proposal.targetContract.call(proposal.calldataToExecute);
            require(success, string(abi.encodePacked("CognitoNexus: Proposal execution failed: ", result)));

            // Return stake to proposer if proposal passed
            payable(agents[proposal.proposerAgentId].walletAddress).transfer(proposal.stakeAmount);

            emit DAOProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Rejected;
            // Optionally, slash proposer stake if rejected and threshold not met, or return if it was a good faith effort.
            // For now, assume stake is part of DAO proposal cost and not refunded on rejection.
        }
    }


    /**
     * @dev Allows anyone to contribute funds to the CognitoNexus rewards pool.
     */
    function depositFunds() public payable {
        require(msg.value > 0, "CognitoNexus: Must send positive amount");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows an agent to withdraw their accumulated and available rewards.
     * @param _agentId The ID of the agent withdrawing rewards.
     */
    function withdrawRewards(uint256 _agentId) public onlyAgent(_agentId) agentExists(_agentId) nonReentrant {
        uint256 rewards = agents[_agentId].accumulatedRewards;
        require(rewards > 0, "CognitoNexus: No rewards to withdraw");

        agents[_agentId].accumulatedRewards = 0;
        (bool success, ) = payable(agents[_agentId].walletAddress).call{value: rewards}("");
        require(success, "CognitoNexus: Failed to withdraw rewards");

        emit RewardsWithdrawn(_agentId, agents[_agentId].walletAddress, rewards);
    }

    // --- Internal/Private Functions ---

    /**
     * @dev Internal function to update an agent's Cognito Score.
     * @param _agentId The ID of the agent whose score is to be updated.
     * @param _amount The amount to adjust the score by.
     * @param _reason A string describing the reason for the score change.
     * @param _isNegative If true, the amount is subtracted; otherwise, it's added.
     */
    function _updateCognitoScore(uint256 _agentId, uint256 _amount, string memory _reason, bool _isNegative) internal {
        if (_isNegative) {
            if (agents[_agentId].cognitoScore > _amount) {
                agents[_agentId].cognitoScore -= _amount;
            } else {
                agents[_agentId].cognitoScore = 1; // Minimum score to prevent zero
            }
        } else {
            agents[_agentId].cognitoScore += _amount;
        }
        emit CognitoScoreUpdated(_agentId, agents[_agentId].cognitoScore, _reason);
    }

    /**
     * @dev Modifier to restrict calls to only this contract itself.
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "CognitoNexus: Only this contract can call this function");
        _;
    }

    // Fallback function to receive Ether for deposits
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}

// Dummy ERC721 contract for demonstration. In a real scenario, this would be a separate, deployed contract.
// It would contain logic for `tokenURI` to dynamically fetch metadata based on CognitoNexus state.
contract CognitoAgentNFT is IERC721, Ownable {
    string public name;
    string public symbol;
    string private _baseTokenURI;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(string memory _name, string memory _symbol) Ownable(msg.sender) {
        name = _name;
        symbol = _symbol;
    }

    function balanceOf(address owner) public view override returns (uint255) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal pure returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer (no revert reason)");
                }
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId;
    }

    // Custom functions for dynamic NFTs
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    // In a real implementation, this would query the CognitoNexus contract for agent data
    // to construct a dynamic URI that points to metadata reflecting score, expertise, etc.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_owners[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        string memory base = _baseURI();
        return bytes(base).length > 0 ? string(abi.encodePacked(base, Strings.toString(tokenId), ".json")) : "";
    }

    function safeMint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(_owners[tokenId] == address(0), "ERC721: token already minted");
        _balances[to]++;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
}

// OpenZeppelin's IERC721Receiver and Strings
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4 selector);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = _HEX_SYMBOLS[value % 10];
            value /= 10;
        }
        return string(buffer);
    }
}
```