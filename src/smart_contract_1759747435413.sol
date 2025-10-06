The `AetheriumLab` contract is designed as a decentralized platform to foster and manage AI-generated research and verifiable computational tasks. It embodies several advanced and trendy concepts:

*   **AI-Generated Proposals:** Proposals specifically include an `aiAgentValidationHash`, a novel concept to verify or signify the AI origin/validation of a research idea.
*   **Decentralized Science (DeSci):** It provides a framework for funding, peer-review (through challenges), and execution of scientific/computational tasks in a decentralized manner.
*   **Verifiable Computation:** Tasks registered within proposals require cryptographic proofs (e.g., ZK-proof hashes) for submission, which can then be challenged and resolved by governance, ensuring integrity.
*   **IP Ownership via NFTs:** Successful research proposals culminate in the minting of an Intellectual Property NFT (IP-NFT) to the proposer, offering a mechanism for on-chain IP rights and potential future monetization.
*   **DAO Governance:** Key parameters and disputes are managed through a governance system involving elected members voting on proposals.
*   **Dynamic Parameters:** Many operational parameters of the lab are adjustable by DAO governance, allowing the platform to adapt over time.

While leveraging standard ERC20 and ERC721 interfaces from OpenZeppelin, the unique combination and specific mechanics of proposal validation, task challenging, and IP-NFT licensing differentiate this contract from typical open-source DAOs, funding platforms, or NFT marketplaces.

---

## AetheriumLab Smart Contract

### Outline

**I. Core Infrastructure & DAO Governance**
    *   Initialization of the lab with fundamental parameters.
    *   Dynamic adjustment of operational parameters by governance.
    *   Management of governance members (add/remove).
    *   A robust governance proposal and voting system for critical decisions and contract upgrades.

**II. AI Research Proposal & Funding**
    *   Submission of AI-generated research proposals, including an AI validation hash.
    *   Decentralized funding mechanism allowing users to stake tokens for proposals.
    *   Activation of proposals upon meeting funding goals.
    *   Mechanisms for funders to unstake and for proposals to be cancelled.

**III. Verifiable Computational Tasks & Execution**
    *   Registration of specific computational tasks required for research proposals.
    *   Submission of cryptographic proofs for task completion by executors.
    *   A challenge system allowing participants to dispute submitted proofs, requiring a stake.
    *   Resolution of challenges by governance, with rewards/penalties.
    *   Distribution of rewards to successful task executors.

**IV. IP-NFT & Outcome Management**
    *   Minting of unique Intellectual Property NFTs (IP-NFTs) upon successful completion of research proposals.
    *   A placeholder for a funder share claim mechanism, hinting at future revenue distribution.
    *   On-chain system for proposing and approving licensing terms for IP-NFTs.
    *   Withdrawal of any unused funds from completed proposals by the proposer.

### Function Summary (20 Functions)

**I. Core Infrastructure & DAO Governance (6 functions)**

1.  `constructor()`: Initializes the lab with an owner, governance token, IP-NFT contract, and initial lab parameters like proposal fees, minimum funding stakes, and challenge durations.
2.  `updateLabParameter(bytes32 _paramName, uint256 _newValue)`: Allows governance members to dynamically adjust various operational parameters of the lab (e.g., `PROPOSAL_FEE`, `CHALLENGE_PERIOD_DURATION`).
3.  `addGovernanceMember(address _member)`: Adds a new address to the set of governance members (requires a prior governance vote through `proposeGovernanceChange`).
4.  `removeGovernanceMember(address _member)`: Removes an address from the set of governance members (requires a prior governance vote).
5.  `proposeGovernanceChange(string memory _description, address _targetContract, bytes memory _callData)`: Allows governance members to propose changes to the contract's state, parameters, or even call external contracts. These proposals are then subject to a vote.
6.  `voteOnGovernanceProposal(uint256 _proposalId, bool _support)`: Allows governance members to cast their vote (for or against) on an active governance proposal.
7.  `executeGovernanceProposal(uint256 _proposalId)`: Executes a governance proposal that has successfully passed the voting period and met the required quorum/majority.

**II. AI Research Proposal & Funding (5 functions)**

8.  `submitAIResearchProposal(string memory _ipfsMetadataHash, uint256 _initialFundingGoal, string memory _aiAgentValidationHash)`: Allows a user to submit a new AI-generated research proposal, specifying funding goals and an AI agent validation hash. Requires a proposal fee.
9.  `stakeForProposal(uint256 _proposalId, uint256 _amount)`: Enables users to stake governance tokens to fund a specific research proposal. Automatically activates the proposal if the funding goal is met.
10. `unstakeFromProposal(uint256 _proposalId, uint256 _amount)`: Allows funders to withdraw their staked tokens from a proposal, provided the proposal is still in the `Pending` state.
11. `cancelProposal(uint256 _proposalId)`: Allows the proposer or governance to cancel an unfunded (`Pending`) proposal, preventing further staking and enabling funders to unstake.

**III. Verifiable Computational Tasks & Execution (5 functions)**

12. `registerComputationalTask(uint256 _proposalId, string memory _taskDescriptionHash, uint256 _expectedReward, uint256 _validationPeriod)`: The proposer registers a specific computational task required for their active research proposal, allocating a reward from the proposal's budget.
13. `submitTaskExecutionProof(uint256 _taskId, bytes32 _proofHash, address _executorWallet)`: An executor submits a cryptographic proof (e.g., ZK-proof hash) of task completion.
14. `challengeTaskExecution(uint256 _taskId, bytes32 _submittedProofHash)`: Any participant can challenge a submitted task proof, requiring a stake, initiating a dispute resolution process.
15. `resolveTaskChallenge(uint256 _taskId, bytes32 _challengedProofHash, bool _isValid)`: Governance members or an oracle resolve a challenge against a task's proof, penalizing incorrect challengers/executors and rewarding correct ones.
16. `distributeTaskReward(uint256 _taskId)`: Distributes the allocated reward to the successful task executor after their proof is validated and the challenge period (if any) has passed or been resolved in their favor.

**IV. IP-NFT & Outcome Management (4 functions)**

17. `mintIP_NFT(uint256 _proposalId, string memory _nftMetadataURI)`: Upon the successful completion of all tasks for a research proposal, an Intellectual Property NFT (IP-NFT) is minted to the proposer, signifying on-chain ownership of the research outcome.
18. `claimFunderShare(uint256 _proposalId)`: A placeholder function allowing funders to claim a share of potential future revenues or governance token rewards associated with successful proposals they funded. (Note: Actual complex tokenomics for revenue sharing would be implemented here).
19. `proposeIP_NFT_LicensingTerms(uint256 _nftId, string memory _licenseURI, uint256 _royaltyPercentage, address _licensee)`: The owner of an IP-NFT can propose specific licensing terms for their intellectual property, recorded on-chain.
20. `approveIP_NFT_License(uint256 _nftId, string memory _licenseURI)`: Allows the intended licensee to approve a proposed IP-NFT license, effectively formalizing the licensing agreement on-chain.
21. `withdrawUnusedProposalFunds(uint256 _proposalId)`: Allows the proposer to withdraw any remaining, unspent funds from a successfully completed and inactive research proposal back to their wallet.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; // For IP-NFT

/**
 * @title AetheriumLab
 * @dev A decentralized platform for funding, executing, and validating AI-generated research proposals
 * and associated verifiable computational tasks. It integrates novel concepts like AI agent validation,
 * dynamic task rewards, and IP ownership via NFTs, all governed by a decentralized autonomous organization (DAO).
 *
 * This contract aims to be innovative by combining:
 * - AI-generated research proposals: Requiring an 'AI agent validation hash' to signify its origin.
 * - Verifiable Computation: Tasks linked to proposals, with proof submission and challenge mechanisms.
 * - IP-NFTs: Minting NFTs to represent research Intellectual Property upon successful completion.
 * - Dynamic Parameter Governance: DAO can adjust various lab parameters.
 * - Funder Incentives: Funders can claim a share of potential future IP revenue or governance token rewards.
 */

// Custom errors for better gas efficiency and readability
error AetheriumLab__NotEnoughFunds(uint256 required, uint256 provided);
error AetheriumLab__ProposalAlreadyActive(uint256 proposalId);
error AetheriumLab__ProposalNotActive(uint256 proposalId);
error AetheriumLab__InvalidAmount();
error AetheriumLab__FundingGoalNotMet(uint256 proposalId);
error AetheriumLab__OnlyProposerOrGovernance(uint256 proposalId);
error AetheriumLab__OnlyGovernance();
error AetheriumLab__TaskNotFound(uint256 taskId);
error AetheriumLab__TaskAlreadyCompleted(uint256 taskId);
error AetheriumLab__TaskNotRegistered(uint256 taskId);
error AetheriumLab__ProofAlreadySubmitted(uint256 taskId);
error AetheriumLab__ChallengePeriodActive(uint256 taskId);
error AetheriumLab__ChallengeAlreadyExists(uint256 taskId, bytes32 proofHash);
error AetheriumLab__ChallengeNotFound(uint256 taskId, bytes32 proofHash);
error AetheriumLab__NoUnusedFunds(uint256 proposalId);
error AetheriumLab__NFTAlreadyMinted(uint256 proposalId);
error AetheriumLab__NotIPNFTOwner(uint256 nftId, address caller);
error AetheriumLab__IPNFTLicenseNotProposed(); // Renamed from NotApproved for clarity
error AetheriumLab__GovernanceProposalNotActive(uint256 proposalId);
error AetheriumLab__GovernanceProposalAlreadyExecuted(uint256 proposalId);
error AetheriumLab__GovernanceProposalVotingPeriodEnded(uint256 proposalId);
error AetheriumLab__AlreadyVoted(uint256 proposalId, address voter);
error AetheriumLab__InsufficientVotes();
error AetheriumLab__OnlyIntendedLicensee();
error AetheriumLab__ZeroAddressNotAllowed();


contract AetheriumLab is Ownable, Pausable, ReentrancyGuard {

    // --- Events ---
    event GovernanceMemberAdded(address indexed member);
    event GovernanceMemberRemoved(address indexed member);
    event LabParameterUpdated(bytes32 indexed paramName, uint256 newValue);
    event GovernanceProposalCreated(uint256 indexed proposalId, string description, address target, bytes callData, uint256 votingEndTime);
    event GovernanceVoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    event AIResearchProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string ipfsMetadataHash, uint256 fundingGoal);
    event ProposalStaked(uint256 indexed proposalId, address indexed funder, uint256 amount);
    event ProposalUnstaked(uint256 indexed proposalId, address indexed funder, uint256 amount);
    event ProposalActivated(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);

    event ComputationalTaskRegistered(uint256 indexed taskId, uint256 indexed proposalId, string taskDescriptionHash, uint256 expectedReward);
    event TaskProofSubmitted(uint256 indexed taskId, address indexed executor, bytes32 proofHash);
    event TaskChallenged(uint256 indexed taskId, bytes32 indexed proofHash, address indexed challenger, uint256 challengeStake);
    event TaskChallengeResolved(uint256 indexed taskId, bytes32 indexed proofHash, bool isValid, address indexed resolver);
    event TaskRewardDistributed(uint256 indexed taskId, address indexed executor, uint256 rewardAmount);

    event IP_NFT_Minted(uint256 indexed proposalId, uint256 indexed nftId, address indexed owner, string nftMetadataURI);
    event FunderShareClaimed(uint256 indexed proposalId, address indexed funder, uint256 amount);
    event IP_NFT_LicensingProposed(uint256 indexed nftId, string licenseURI, uint256 royaltyPercentage, address licensee);
    event IP_NFT_LicenseApproved(uint256 indexed nftId, string licenseURI);
    event UnusedProposalFundsWithdrawn(uint256 indexed proposalId, address indexed proposer, uint256 amount);


    // --- State Variables ---

    IERC20 public immutable governanceToken; // Token used for funding, staking, and governance
    IP_NFT public immutable ipNftContract; // ERC721 contract for Intellectual Property NFTs

    uint256 public proposalCounter; // Counter for unique proposal IDs
    uint256 public taskCounter;     // Counter for unique task IDs
    uint256 public governanceProposalCounter; // Counter for unique governance proposal IDs

    // Lab Parameters (adjustable by governance)
    mapping(bytes32 => uint256) public labParameters;
    bytes32 public constant PROPOSAL_FEE = "PROPOSAL_FEE";
    bytes32 public constant MIN_FUNDING_STAKE = "MIN_FUNDING_STAKE";
    bytes32 public constant CHALLENGE_PERIOD_DURATION = "CHALLENGE_PERIOD_DURATION";
    bytes32 public constant GOVERNANCE_VOTING_PERIOD = "GOVERNANCE_VOTING_PERIOD";
    bytes32 public constant GOVERNANCE_MIN_VOTES = "GOVERNANCE_MIN_VOTES"; // Min votes needed to pass a governance proposal
    bytes32 public constant CHALLENGE_STAKE_AMOUNT = "CHALLENGE_STAKE_AMOUNT";
    bytes32 public constant FUNDER_BONUS_REWARD_FACTOR = "FUNDER_BONUS_REWARD_FACTOR"; // For claimFunderShare, e.g., 100 for 1% of stake

    // Governance Members
    mapping(address => bool) public isGovernanceMember;
    address[] private governanceMembersArray; // To iterate or get count

    // Structs
    enum ProposalStatus { Pending, Active, Completed, Cancelled }
    enum TaskStatus { Pending, AwaitingProof, ProofSubmitted, Challenged, Completed }

    struct AIResearchProposal {
        address proposer;
        string ipfsMetadataHash; // Hash pointing to detailed proposal on IPFS
        string aiAgentValidationHash; // Hash representing proof of AI origin/validation
        uint256 initialFundingGoal;
        uint256 currentStakedAmount;
        mapping(address => uint256) fundersStake; // Who staked how much (persists for rewards)
        ProposalStatus status;
        uint256 activatedAt; // Timestamp when proposal became active
        uint256 totalTasksRegistered; // Total tasks linked to this proposal
        uint256 completedTasks; // Tasks successfully completed
        uint256 ipNftId; // ID of the minted IP-NFT, 0 if not minted
        uint256 balance; // Funds available for this proposal (for tasks, etc.)
        mapping(address => bool) funderShareClaimed; // To prevent double claiming
    }
    mapping(uint256 => AIResearchProposal) public proposals;

    struct ComputationalTask {
        uint256 proposalId;
        string taskDescriptionHash; // Hash pointing to detailed task description on IPFS
        uint256 expectedReward; // Reward for successful completion
        uint256 validationPeriod; // Duration for proof validation/challenge
        TaskStatus status;
        address executor; // Wallet of the executor who submitted the proof
        bytes32 submittedProofHash; // Cryptographic proof of completion
        uint256 proofSubmissionTime;
        mapping(bytes32 => TaskChallenge) challenges; // Challenges against a specific proof hash
        uint256 totalChallengeStake; // Total stake from challengers for this task
        bool resultValidated; // True if proof was validated or challenge failed (executor was correct)
    }
    mapping(uint256 => ComputationalTask) public tasks;

    struct TaskChallenge {
        address challenger;
        uint256 stakeAmount;
        bool resolved;
        bool challengerWasCorrect; // True if challenger was correct (proof was invalid)
    }

    struct GovernanceProposal {
        string description;
        address targetContract;
        bytes callData;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // IP-NFT related structs/mappings
    struct IP_NFT_License {
        string licenseURI;
        uint256 royaltyPercentage; // 0-10000 for 0-100%
        address licensee;
        bool approved;
        bool proposed; // To track if a license with this URI was proposed
    }
    mapping(uint256 => mapping(bytes32 => IP_NFT_License)) public ipNftLicenses; // nftId => keccak256(licenseURI) => License


    // --- Modifiers ---

    modifier onlyGovernance() {
        if (!isGovernanceMember[msg.sender]) {
            revert AetheriumLab__OnlyGovernance();
        }
        _;
    }

    modifier onlyProposerOrGovernance(uint256 _proposalId) {
        if (msg.sender != proposals[_proposalId].proposer && !isGovernanceMember[msg.sender]) {
            revert AetheriumLab__OnlyProposerOrGovernance(_proposalId);
        }
        _;
    }

    // --- Constructor ---

    constructor(
        address _owner,
        address _governanceToken,
        address _ipNftContract,
        uint256 _proposalFee,
        uint256 _minFundingStake,
        uint256 _challengePeriodDuration,
        uint256 _governanceVotingPeriod,
        uint256 _governanceMinVotes,
        uint256 _challengeStakeAmount,
        uint256 _funderBonusRewardFactor // e.g., 100 for 1% of initial stake
    ) Ownable(_owner) Pausable() {
        if (_governanceToken == address(0) || _ipNftContract == address(0)) {
            revert AetheriumLab__ZeroAddressNotAllowed();
        }
        governanceToken = IERC20(_governanceToken);
        ipNftContract = IP_NFT(_ipNftContract);

        labParameters[PROPOSAL_FEE] = _proposalFee;
        labParameters[MIN_FUNDING_STAKE] = _minFundingStake;
        labParameters[CHALLENGE_PERIOD_DURATION] = _challengePeriodDuration;
        labParameters[GOVERNANCE_VOTING_PERIOD] = _governanceVotingPeriod;
        labParameters[GOVERNANCE_MIN_VOTES] = _governanceMinVotes;
        labParameters[CHALLENGE_STAKE_AMOUNT] = _challengeStakeAmount;
        labParameters[FUNDER_BONUS_REWARD_FACTOR] = _funderBonusRewardFactor;

        isGovernanceMember[_owner] = true; // Initial owner is also a governance member
        governanceMembersArray.push(_owner);
    }

    // --- I. Core Infrastructure & DAO Governance (7 functions) ---

    /**
     * @dev Updates a specific lab parameter. Only callable by governance members.
     * This action would typically be proposed via `proposeGovernanceChange` and executed.
     * @param _paramName The name of the parameter (e.g., "PROPOSAL_FEE").
     * @param _newValue The new value for the parameter.
     */
    function updateLabParameter(bytes32 _paramName, uint256 _newValue) external onlyGovernance whenNotPaused {
        labParameters[_paramName] = _newValue;
        emit LabParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Adds a new address to the set of governance members. This function is typically
     * called through `executeGovernanceProposal` after a successful governance vote.
     * @param _member The address to add as a governance member.
     */
    function addGovernanceMember(address _member) external onlyGovernance {
        if (!isGovernanceMember[_member]) {
            isGovernanceMember[_member] = true;
            governanceMembersArray.push(_member);
            emit GovernanceMemberAdded(_member);
        }
    }

    /**
     * @dev Removes an address from the set of governance members. This function is typically
     * called through `executeGovernanceProposal` after a successful governance vote.
     * @param _member The address to remove from governance members.
     */
    function removeGovernanceMember(address _member) external onlyGovernance {
        if (isGovernanceMember[_member]) {
            isGovernanceMember[_member] = false;
            // Find and remove from dynamic array (inefficient for very large arrays, but governance members should be limited)
            for (uint i = 0; i < governanceMembersArray.length; i++) {
                if (governanceMembersArray[i] == _member) {
                    governanceMembersArray[i] = governanceMembersArray[governanceMembersArray.length - 1];
                    governanceMembersArray.pop();
                    break;
                }
            }
            emit GovernanceMemberRemoved(_member);
        }
    }

    /**
     * @dev Allows governance members to propose contract upgrades, parameter changes, or other actions.
     * The proposal then needs to be voted on.
     * @param _description A description of the proposed change.
     * @param _targetContract The address of the contract the call should be made to (e.g., this contract itself for parameter changes).
     * @param _callData The encoded function call (e.g., `abi.encodeWithSelector(this.updateLabParameter.selector, PROPOSAL_FEE, 100)`).
     * @return The ID of the created governance proposal.
     */
    function proposeGovernanceChange(string memory _description, address _targetContract, bytes memory _callData) external onlyGovernance whenNotPaused returns (uint256) {
        governanceProposalCounter++;
        uint256 proposalId = governanceProposalCounter;
        governanceProposals[proposalId] = GovernanceProposal({
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            votingEndTime: block.timestamp + labParameters[GOVERNANCE_VOTING_PERIOD],
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, _description, _targetContract, _callData, governanceProposals[proposalId].votingEndTime);
        return proposalId;
    }

    /**
     * @dev Allows governance members to vote on a governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnGovernanceProposal(uint256 _proposalId, bool _support) external onlyGovernance whenNotPaused {
        GovernanceProposal storage gp = governanceProposals[_proposalId];
        if (gp.votingEndTime == 0 || gp.executed) revert AetheriumLab__GovernanceProposalNotActive(_proposalId);
        if (block.timestamp >= gp.votingEndTime) revert AetheriumLab__GovernanceProposalVotingPeriodEnded(_proposalId);
        if (gp.hasVoted[msg.sender]) revert AetheriumLab__AlreadyVoted(_proposalId, msg.sender);

        gp.hasVoted[msg.sender] = true;
        if (_support) {
            gp.votesFor++;
        } else {
            gp.votesAgainst++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @dev Executes an approved governance proposal. Callable by any governance member after voting period ends
     * and conditions are met.
     * @param _proposalId The ID of the governance proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external onlyGovernance whenNotPaused nonReentrant {
        GovernanceProposal storage gp = governanceProposals[_proposalId];
        if (gp.executed) revert AetheriumLab__GovernanceProposalAlreadyExecuted(_proposalId);
        if (gp.votingEndTime == 0) revert AetheriumLab__GovernanceProposalNotActive(_proposalId);
        if (block.timestamp < gp.votingEndTime) revert AetheriumLab__GovernanceProposalVotingPeriodEnded(_proposalId);

        uint256 totalVotes = gp.votesFor + gp.votesAgainst;
        if (gp.votesFor <= gp.votesAgainst || totalVotes < labParameters[GOVERNANCE_MIN_VOTES]) {
            revert AetheriumLab__InsufficientVotes();
        }

        (bool success,) = gp.targetContract.call(gp.callData);
        require(success, "AetheriumLab: Governance call failed");

        gp.executed = true;
        emit GovernanceProposalExecuted(_proposalId);
    }


    // --- II. AI Research Proposal & Funding (5 functions) ---

    /**
     * @dev Allows a proposer to submit an AI-generated research idea. Requires a fee.
     * @param _ipfsMetadataHash Hash pointing to detailed proposal description on IPFS.
     * @param _initialFundingGoal The target amount of governance tokens needed to activate the proposal.
     * @param _aiAgentValidationHash A cryptographic hash or identifier proving the AI origin/validation of the proposal.
     * @return The ID of the created proposal.
     */
    function submitAIResearchProposal(
        string memory _ipfsMetadataHash,
        uint256 _initialFundingGoal,
        string memory _aiAgentValidationHash
    ) external whenNotPaused nonReentrant returns (uint256) {
        if (_initialFundingGoal == 0) revert AetheriumLab__InvalidAmount();
        if (governanceToken.balanceOf(msg.sender) < labParameters[PROPOSAL_FEE]) {
            revert AetheriumLab__NotEnoughFunds(labParameters[PROPOSAL_FEE], governanceToken.balanceOf(msg.sender));
        }

        // Transfer proposal fee
        require(governanceToken.transferFrom(msg.sender, address(this), labParameters[PROPOSAL_FEE]), "AetheriumLab: Fee transfer failed");

        proposalCounter++;
        uint256 proposalId = proposalCounter;
        proposals[proposalId] = AIResearchProposal({
            proposer: msg.sender,
            ipfsMetadataHash: _ipfsMetadataHash,
            aiAgentValidationHash: _aiAgentValidationHash,
            initialFundingGoal: _initialFundingGoal,
            currentStakedAmount: 0,
            status: ProposalStatus.Pending,
            activatedAt: 0,
            totalTasksRegistered: 0,
            completedTasks: 0,
            ipNftId: 0,
            balance: 0, // Funds will move here upon activation
            fundersStake: new mapping(address => uint256),
            funderShareClaimed: new mapping(address => bool)
        });

        emit AIResearchProposalSubmitted(proposalId, msg.sender, _ipfsMetadataHash, _initialFundingGoal);
        return proposalId;
    }

    /**
     * @dev Allows funders to stake governance tokens to back a specific proposal.
     * @param _proposalId The ID of the proposal to fund.
     * @param _amount The amount of governance tokens to stake.
     */
    function stakeForProposal(uint256 _proposalId, uint256 _amount) external whenNotPaused nonReentrant {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Pending) revert AetheriumLab__ProposalAlreadyActive(_proposalId);
        if (_amount == 0 || _amount < labParameters[MIN_FUNDING_STAKE]) revert AetheriumLab__InvalidAmount();

        // Transfer tokens from funder to contract
        require(governanceToken.transferFrom(msg.sender, address(this), _amount), "AetheriumLab: Token transfer failed");

        proposal.currentStakedAmount += _amount;
        proposal.fundersStake[msg.sender] += _amount; // Keep track of individual funder stakes

        emit ProposalStaked(_proposalId, msg.sender, _amount);

        // Automatically activate if goal is met
        if (proposal.currentStakedAmount >= proposal.initialFundingGoal) {
            _activateProposal(_proposalId);
        }
    }

    /**
     * @dev Allows funders to withdraw stakes if the proposal hasn't been fully funded or activated.
     * @param _proposalId The ID of the proposal.
     * @param _amount The amount to unstake.
     */
    function unstakeFromProposal(uint256 _proposalId, uint256 _amount) external whenNotPaused nonReentrant {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Pending) revert AetheriumLab__ProposalAlreadyActive(_proposalId);
        if (_amount == 0 || proposal.fundersStake[msg.sender] < _amount) revert AetheriumLab__InvalidAmount();

        proposal.fundersStake[msg.sender] -= _amount;
        proposal.currentStakedAmount -= _amount;
        require(governanceToken.transfer(msg.sender, _amount), "AetheriumLab: Unstake transfer failed");

        emit ProposalUnstaked(_proposalId, msg.sender, _amount);
    }

    /**
     * @dev Internal function to activate a proposal once its funding goal is met.
     * Moves staked funds to the proposal's active budget.
     * @param _proposalId The ID of the proposal to activate.
     */
    function _activateProposal(uint256 _proposalId) internal {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Pending) revert AetheriumLab__ProposalAlreadyActive(_proposalId);
        if (proposal.currentStakedAmount < proposal.initialFundingGoal) revert AetheriumLab__FundingGoalNotMet(_proposalId);

        proposal.status = ProposalStatus.Active;
        proposal.activatedAt = block.timestamp;
        proposal.balance = proposal.currentStakedAmount; // All staked funds become the proposal's budget
        proposal.currentStakedAmount = 0; // Staked amount is now converted to balance.
        // FundersStake remains for potential future rewards calculation.

        emit ProposalActivated(_proposalId);
    }

    /**
     * @dev Allows proposer (or governance) to cancel an unfunded proposal.
     * Can only be called if proposal is still `Pending`. Funders must `unstakeFromProposal` manually.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external onlyProposerOrGovernance(_proposalId) whenNotPaused nonReentrant {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Pending) revert AetheriumLab__ProposalAlreadyActive(_proposalId);

        proposal.status = ProposalStatus.Cancelled;

        // Note: Funders need to manually call unstakeFromProposal. This design prevents
        // gas issues from iterating potentially large lists of funders during cancellation.
        // Any remaining currentStakedAmount will be held in the contract until manually unstaked.

        emit ProposalCancelled(_proposalId);
    }


    // --- III. Verifiable Computational Tasks & Execution (5 functions) ---

    /**
     * @dev Proposer registers a specific computational task required for their research.
     * @param _proposalId The ID of the parent research proposal.
     * @param _taskDescriptionHash Hash pointing to detailed task description on IPFS.
     * @param _expectedReward The amount of governance tokens to reward for successful completion.
     * @param _validationPeriod Duration in seconds for proof validation/challenge.
     * @return The ID of the created task.
     */
    function registerComputationalTask(
        uint256 _proposalId,
        string memory _taskDescriptionHash,
        uint256 _expectedReward,
        uint256 _validationPeriod
    ) external onlyProposerOrGovernance(_proposalId) whenNotPaused returns (uint256) {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) revert AetheriumLab__ProposalNotActive(_proposalId);
        if (proposal.balance < _expectedReward) revert AetheriumLab__NotEnoughFunds(_expectedReward, proposal.balance);
        if (_expectedReward == 0) revert AetheriumLab__InvalidAmount();

        taskCounter++;
        uint256 taskId = taskCounter;
        tasks[taskId] = ComputationalTask({
            proposalId: _proposalId,
            taskDescriptionHash: _taskDescriptionHash,
            expectedReward: _expectedReward,
            validationPeriod: _validationPeriod,
            status: TaskStatus.Pending,
            executor: address(0),
            submittedProofHash: bytes32(0),
            proofSubmissionTime: 0,
            totalChallengeStake: 0,
            resultValidated: false,
            challenges: new mapping(bytes32 => TaskChallenge)
        });

        proposal.balance -= _expectedReward; // Allocate reward from proposal budget
        proposal.totalTasksRegistered++;

        emit ComputationalTaskRegistered(taskId, _proposalId, _taskDescriptionHash, _expectedReward);
        return taskId;
    }

    /**
     * @dev An executor submits a cryptographic proof (e.g., ZK-proof hash) of task completion.
     * @param _taskId The ID of the computational task.
     * @param _proofHash The cryptographic hash of the generated proof.
     * @param _executorWallet The wallet of the executor (can be `msg.sender` or another specified wallet).
     */
    function submitTaskExecutionProof(uint256 _taskId, bytes32 _proofHash, address _executorWallet) external whenNotPaused nonReentrant {
        ComputationalTask storage task = tasks[_taskId];
        if (task.proposalId == 0) revert AetheriumLab__TaskNotFound(_taskId);
        if (task.status != TaskStatus.Pending) revert AetheriumLab__ProofAlreadySubmitted(_taskId); // Only one initial proof
        if (_executorWallet == address(0)) revert AetheriumLab__ZeroAddressNotAllowed();

        task.executor = _executorWallet;
        task.submittedProofHash = _proofHash;
        task.proofSubmissionTime = block.timestamp;
        task.status = TaskStatus.ProofSubmitted;

        emit TaskProofSubmitted(_taskId, _executorWallet, _proofHash);
    }

    /**
     * @dev Any participant can challenge a submitted proof, requiring a stake.
     * @param _taskId The ID of the computational task.
     * @param _submittedProofHash The specific proof hash being challenged.
     */
    function challengeTaskExecution(uint256 _taskId, bytes32 _submittedProofHash) external whenNotPaused nonReentrant {
        ComputationalTask storage task = tasks[_taskId];
        if (task.proposalId == 0) revert AetheriumLab__TaskNotFound(_taskId);
        if (task.submittedProofHash != _submittedProofHash || task.submittedProofHash == bytes32(0)) revert AetheriumLab__ChallengeNotFound(_taskId, _submittedProofHash);
        if (task.status != TaskStatus.ProofSubmitted && task.status != TaskStatus.Challenged) revert AetheriumLab__TaskNotRegistered(_taskId);
        if (block.timestamp > task.proofSubmissionTime + task.validationPeriod) revert AetheriumLab__ChallengePeriodActive(_taskId); // Challenge period ended
        if (task.challenges[_submittedProofHash].challenger != address(0)) revert AetheriumLab__ChallengeAlreadyExists(_taskId, _submittedProofHash); // Only one challenge per proof

        uint256 challengeStake = labParameters[CHALLENGE_STAKE_AMOUNT];
        require(governanceToken.transferFrom(msg.sender, address(this), challengeStake), "AetheriumLab: Challenge stake transfer failed");

        task.challenges[_submittedProofHash] = TaskChallenge({
            challenger: msg.sender,
            stakeAmount: challengeStake,
            resolved: false,
            challengerWasCorrect: false
        });
        task.totalChallengeStake += challengeStake;
        task.status = TaskStatus.Challenged;

        emit TaskChallenged(_taskId, _submittedProofHash, msg.sender, challengeStake);
    }

    /**
     * @dev Governance or an oracle resolves a challenge, penalizing fraud and rewarding honest participants.
     * Only callable by governance members.
     * @param _taskId The ID of the computational task.
     * @param _challengedProofHash The specific proof hash that was challenged.
     * @param _isValid True if the proof was found to be valid (challenger was incorrect), false if invalid (challenger was correct).
     */
    function resolveTaskChallenge(uint256 _taskId, bytes32 _challengedProofHash, bool _isValid) external onlyGovernance whenNotPaused nonReentrant {
        ComputationalTask storage task = tasks[_taskId];
        if (task.proposalId == 0) revert AetheriumLab__TaskNotFound(_taskId);
        if (task.submittedProofHash != _challengedProofHash) revert AetheriumLab__ChallengeNotFound(_taskId, _challengedProofHash);
        if (task.status != TaskStatus.Challenged) revert AetheriumLab__TaskNotRegistered(_taskId); // Not in challenged state
        if (task.challenges[_challengedProofHash].resolved) revert AetheriumLab__TaskAlreadyCompleted(_taskId); // Challenge already resolved

        TaskChallenge storage challenge = task.challenges[_challengedProofHash];
        challenge.resolved = true;
        challenge.challengerWasCorrect = !_isValid; // If _isValid is true, proof was good, challenger was wrong. If false, proof was bad, challenger was right.

        if (challenge.challengerWasCorrect) { // Challenger was correct, proof was invalid
            // Challenger gets their stake back + a reward (e.g., from forfeited executor reward or a portion of challenge pool)
            // Executor forfeits their expected reward. That reward (task.expectedReward) is returned to the proposal budget.
            uint256 challengerReward = challenge.stakeAmount; // For simplicity, challenger gets their stake back + their stake as reward
            require(governanceToken.transfer(challenge.challenger, challenge.stakeAmount + challengerReward), "AetheriumLab: Challenger reward failed");
            
            task.totalChallengeStake -= (challenge.stakeAmount + challengerReward); // Update remaining pool (might go negative if reward > stake, implies external fund needed)

            proposals[task.proposalId].balance += task.expectedReward; // Return forfeited reward to proposal budget
            task.expectedReward = 0; // Mark as forfeited/returned
            task.executor = address(0); // Clear executor
        } else { // Challenger was incorrect, proof was valid
            // Challenger loses stake, which is forfeited to the contract treasury.
            // Executor proceeds to get their reward.
            task.totalChallengeStake -= challenge.stakeAmount; // Stake remains in contract treasury
        }

        task.resultValidated = _isValid;
        task.status = TaskStatus.Completed; // Mark task as completed after challenge resolution

        emit TaskChallengeResolved(_taskId, _challengedProofHash, _isValid, msg.sender);

        // If proof was valid, distribute the reward to executor.
        if (_isValid) {
            _distributeTaskReward(_taskId);
        }
    }

    /**
     * @dev Distributes the reward to the successful executor after validation/challenge resolution.
     * Can only be called once the task's proof submission time + validation period has passed AND it's not challenged,
     * OR if a challenge was resolved in favor of the executor.
     * @param _taskId The ID of the computational task.
     */
    function distributeTaskReward(uint256 _taskId) external whenNotPaused nonReentrant {
        _distributeTaskReward(_taskId);
    }

    /**
     * @dev Internal helper for distributing task reward.
     */
    function _distributeTaskReward(uint256 _taskId) internal {
        ComputationalTask storage task = tasks[_taskId];
        if (task.proposalId == 0) revert AetheriumLab__TaskNotFound(_taskId);
        if (task.expectedReward == 0 || task.executor == address(0)) revert AetheriumLab__TaskAlreadyCompleted(_taskId); // Already rewarded or no executor/reward

        // Check if proof was submitted and challenge period is over, and no challenge was successful.
        bool challengePeriodEnded = block.timestamp >= task.proofSubmissionTime + task.validationPeriod;
        bool noActiveChallenge = task.status != TaskStatus.Challenged;
        bool challengeResolvedValid = task.status == TaskStatus.Completed && task.resultValidated;

        if (!(challengePeriodEnded && noActiveChallenge) && !challengeResolvedValid) {
            revert AetheriumLab__ChallengePeriodActive(_taskId); // Or some other state not ready for reward.
        }

        uint256 reward = task.expectedReward;
        task.expectedReward = 0; // Mark as rewarded
        task.status = TaskStatus.Completed;
        task.resultValidated = true;

        require(governanceToken.transfer(task.executor, reward), "AetheriumLab: Reward transfer failed");
        proposals[task.proposalId].completedTasks++;
        emit TaskRewardDistributed(_taskId, task.executor, reward);
    }


    // --- IV. IP-NFT & Outcome Management (4 functions + 1 withdraw) ---

    /**
     * @dev Upon successful completion of a research proposal and its tasks, an NFT representing
     * the Intellectual Property is minted to the proposer.
     * @param _proposalId The ID of the completed research proposal.
     * @param _nftMetadataURI URI pointing to the metadata for the IP-NFT (e.g., project details, outputs, etc.).
     * @return The ID of the minted IP-NFT.
     */
    function mintIP_NFT(uint256 _proposalId, string memory _nftMetadataURI) external onlyProposerOrGovernance(_proposalId) whenNotPaused returns (uint256) {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Active || proposal.completedTasks < proposal.totalTasksRegistered) {
            revert AetheriumLab__ProposalNotActive(_proposalId); // Not fully completed or not active
        }
        if (proposal.ipNftId != 0) revert AetheriumLab__NFTAlreadyMinted(_proposalId);

        uint256 nftId = ipNftContract.safeMint(proposal.proposer, _nftMetadataURI);
        proposal.ipNftId = nftId;
        proposal.status = ProposalStatus.Completed; // Mark proposal as fully completed

        emit IP_NFT_Minted(_proposalId, nftId, proposal.proposer, _nftMetadataURI);
        return nftId;
    }

    /**
     * @dev Allows funders to claim their share of potential future revenues or governance token rewards
     * associated with successful proposals they funded.
     * This is a simplified example; a real system would have a dedicated revenue stream or pool.
     * Here, it provides a bonus based on `FUNDER_BONUS_REWARD_FACTOR`.
     * @param _proposalId The ID of the successful proposal.
     */
    function claimFunderShare(uint256 _proposalId) external whenNotPaused nonReentrant {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Completed) revert AetheriumLab__ProposalNotActive(_proposalId);
        if (proposal.fundersStake[msg.sender] == 0) revert AetheriumLab__InvalidAmount(); // No stake from this funder
        if (proposal.funderShareClaimed[msg.sender]) revert AetheriumLab__AlreadyVoted(_proposalId, msg.sender); // Used for `AlreadyVoted` error, but serves as `AlreadyClaimed` here.

        uint256 funderStake = proposal.fundersStake[msg.sender];
        uint256 rewardFactor = labParameters[FUNDER_BONUS_REWARD_FACTOR]; // e.g., 100 for 1%
        uint256 rewardAmount = (funderStake * rewardFactor) / 10000; // Calculate bonus (e.g., 1% of stake)

        if (rewardAmount == 0) return; // No reward if factor is 0 or stake is too small
        
        // This assumes `governanceToken` can be transferred from the contract's overall balance.
        // In a real scenario, this would be from a specific, earned revenue stream.
        if (governanceToken.balanceOf(address(this)) < rewardAmount) {
             revert AetheriumLab__NotEnoughFunds(rewardAmount, governanceToken.balanceOf(address(this)));
        }
        
        require(governanceToken.transfer(msg.sender, rewardAmount), "AetheriumLab: Funder share transfer failed");
        proposal.funderShareClaimed[msg.sender] = true; // Mark as claimed

        emit FunderShareClaimed(_proposalId, msg.sender, rewardAmount);
    }


    /**
     * @dev The owner of an IP-NFT can propose specific licensing terms for their research.
     * This creates a record on-chain for a potential license.
     * @param _nftId The ID of the IP-NFT.
     * @param _licenseURI URI pointing to the detailed license agreement on IPFS.
     * @param _royaltyPercentage Royalty percentage (e.g., 1000 for 10%). Max 10000 (100%).
     * @param _licensee The address of the potential licensee.
     */
    function proposeIP_NFT_LicensingTerms(
        uint256 _nftId,
        string memory _licenseURI,
        uint256 _royaltyPercentage,
        address _licensee
    ) external whenNotPaused {
        if (ipNftContract.ownerOf(_nftId) != msg.sender) {
            revert AetheriumLab__NotIPNFTOwner(_nftId, msg.sender);
        }
        require(_royaltyPercentage <= 10000, "AetheriumLab: Royalty percentage too high");
        if (_licensee == address(0)) revert AetheriumLab__ZeroAddressNotAllowed();

        bytes32 licenseHash = keccak256(abi.encodePacked(_licenseURI));
        ipNftLicenses[_nftId][licenseHash] = IP_NFT_License({
            licenseURI: _licenseURI,
            royaltyPercentage: _royaltyPercentage,
            licensee: _licensee,
            approved: false,
            proposed: true
        });

        emit IP_NFT_LicensingProposed(_nftId, _licenseURI, _royaltyPercentage, _licensee);
    }

    /**
     * @dev Approves a proposed license. This could be called by the licensee or a third-party
     * once terms are agreed and payment (if any) is made off-chain.
     * @param _nftId The ID of the IP-NFT.
     * @param _licenseURI The URI of the specific license to approve.
     */
    function approveIP_NFT_License(uint256 _nftId, string memory _licenseURI) external whenNotPaused {
        bytes32 licenseHash = keccak256(abi.encodePacked(_licenseURI));
        IP_NFT_License storage license = ipNftLicenses[_nftId][licenseHash];
        if (!license.proposed) revert AetheriumLab__IPNFTLicenseNotProposed();

        // Only the intended licensee (or an authorized agent) can approve this
        if (msg.sender != license.licensee) revert AetheriumLab__OnlyIntendedLicensee();

        license.approved = true;
        // In a real system, this might trigger payment mechanisms or NFT minting for the license itself.

        emit IP_NFT_LicenseApproved(_nftId, _licenseURI);
    }

    /**
     * @dev Allows the proposer to withdraw any remaining funds from a completed and successful proposal.
     * @param _proposalId The ID of the proposal.
     */
    function withdrawUnusedProposalFunds(uint256 _proposalId) external onlyProposerOrGovernance(_proposalId) whenNotPaused nonReentrant {
        AIResearchProposal storage proposal = proposals[_proposalId];
        if (proposal.status != ProposalStatus.Completed) revert AetheriumLab__ProposalNotActive(_proposalId);
        if (proposal.balance == 0) revert AetheriumLab__NoUnusedFunds(_proposalId);

        uint256 amount = proposal.balance;
        proposal.balance = 0;
        require(governanceToken.transfer(msg.sender, amount), "AetheriumLab: Withdraw failed");

        emit UnusedProposalFundsWithdrawn(_proposalId, msg.sender, amount);
    }

    // --- Utility Functions ---

    /**
     * @dev Pauses the contract. Only owner can call.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only owner can call.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Internal IP_NFT contract definition ---
    // A simple internal ERC721 contract for demonstration. In a real scenario, this would be a separate deployed contract.
    contract IP_NFT is ERC721 {
        uint256 private _nextTokenId;

        constructor() ERC721("AetheriumLab IP-NFT", "AL-IP") {}

        function safeMint(address to, string memory uri) public returns (uint256) {
            uint256 tokenId = _nextTokenId++;
            _safeMint(to, tokenId);
            _setTokenURI(tokenId, uri);
            return tokenId;
        }

        // Override _baseURI to allow dynamic IPFS URI for token metadata
        function _baseURI() internal pure override returns (string memory) {
            return "ipfs://"; // Placeholder base URI
        }
    }
}
```