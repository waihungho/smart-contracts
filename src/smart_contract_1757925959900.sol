This smart contract, **AetherMindCollective**, creates a decentralized network for AI-assisted creative and analytical tasks. It uniquely combines AI oracle integration, a dynamic reputation system, competitive human refinement of AI outputs, DAO governance, and dynamic Soulbound Tokens (SBTs) as proof of skill.

The core idea is that "Taskers" submit tasks (e.g., summarize, generate, analyze). An AI oracle provides an initial output, which "CognitoRefiners" then review, refine, and improve. Refiners commit to their work and later reveal it, competing for a bounty. A reputation system tracks Refiner performance, and top Refiners can earn dynamic "CognitoMark" SBTs that evolve with their contributions. The entire system is governed by a DAO, allowing participants to vote on parameters and resolve disputes.

---

### **AetherMindCollective Smart Contract**

---

### **I. Contract Outline**

1.  **State Variables & Constants**: Definitions for tasks, refiners, proposals, disputes, and system-wide parameters.
2.  **Events**: Logs for major contract actions.
3.  **Custom Errors**: Defined at the top for clarity and gas efficiency.
4.  **Helper Contracts**: Simplified `CognitoToken` (ERC20) and `CognitoMarkSBT` (ERC721-like) for demonstration purposes, deployed by the main contract.
5.  **Constructor & Initial Setup**: Initializes core components and sets initial administrative roles.
6.  **Configuration (DAO-Governed)**: Functions to update key system parameters, intended for DAO execution.
7.  **Task Management**: Core logic for submitting tasks, AI processing, human refinement, selection, and finalization.
8.  **Refiner Staking & Reputation**: Mechanisms for Refiners to participate, manage their stake, and track reputation.
9.  **DAO Governance**: Framework for proposing, voting on, and executing system changes.
10. **Dynamic Soulbound Tokens (CognitoMarks)**: Logic for minting and updating unique, non-transferable skill proofs.
11. **Dispute Resolution**: Process for users to raise disputes and for the DAO to resolve them.
12. **View Functions**: Read-only functions to query contract state.

---

### **II. Function Summary (24 Functions)**

**I. Setup & Configuration (4 functions)**
1.  `constructor()`: Initializes the `AetherMindCollective` contract, deploys `CognitoToken` (COG) and `CognitoMarkSBT` (CGM) internal contracts, and sets initial owner.
2.  `setAIDataFeedOracle(address _oracle)`: Sets the trusted AI data feed oracle address. (Initially `onlyOwner`, later DAO)
3.  `setDisputeResolutionPeriod(uint256 _period)`: Sets the duration for dispute voting. (Initially `onlyOwner`, later DAO)
4.  `setMinRefinerStake(uint256 _minStake)`: Sets the minimum COG tokens required to stake as a Refiner. (Initially `onlyOwner`, later DAO)
5.  `setProposalVotingPeriod(uint256 _period)`: Sets the duration for governance proposal voting. (Initially `onlyOwner`, later DAO)

**II. Task Management (7 functions)**
6.  `submitTask(bytes32 _inputHash, string calldata _aiInputPrompt, uint256 _bounty, uint256 _taskerStake, uint256 _aiSubmissionOffset, uint256 _refinementCommitmentOffset, uint256 _refinementRevealOffset, uint256 _selectionOffset)`: Tasker creates a new task, deposits bounty and stake.
7.  `submitAIOutput(uint256 _taskId, string calldata _aiOutputURL)`: AI Oracle submits its initial processing result for a task.
8.  `commitRefinement(uint256 _taskId, bytes32 _hashedRefinement)`: Refiner commits a hash of their refined output (and a secret salt) to participate.
9.  `revealRefinement(uint256 _taskId, string calldata _revealedRefinementURL, bytes32 _salt)`: Refiner reveals their actual refined output and salt to prove their commitment.
10. `selectBestRefinement(uint256 _taskId, address _selectedRefiner)`: The designated selector (e.g., DAO or automated) chooses the best refinement.
11. `finalizeTask(uint256 _taskId)`: Completes a task, distributes rewards, updates refiner reputations, and potentially mints/updates CognitoMarks.
12. `claimTaskOutput(uint256 _taskId)`: Tasker retrieves the final refined output's URL after task finalization.
13. `cancelTask(uint256 _taskId)`: Allows a Tasker to cancel their task before significant Refiner engagement, refunding stakes.

**III. Refiner Staking & Reputation (3 functions)**
14. `stakeAsRefiner(uint256 _amount)`: Refiner stakes COG tokens to become an active participant and earn reputation.
15. `unstakeRefiner(uint256 _amount)`: Refiner unstakes COG tokens.
16. `getRefinerReputation(address _refiner)`: Queries a refiner's current reputation score.

**IV. DAO Governance (3 functions)**
17. `proposeParameterChange(address _target, bytes calldata _callData, string calldata _description, uint256 _votingPeriod)`: Creates a new governance proposal for system changes.
18. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows staked Refiners (DAO members) to vote on an active proposal.
19. `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal, enacting the proposed changes.

**V. Dynamic Soulbound Tokens (CognitoMarks) (3 functions)**
20. `_handleCognitoMarkForRefiner(address _refiner)`: Internal helper function to manage CognitoMark SBTs (mint or update) based on refiner performance.
21. `updateCognitoMarkAttributes(uint256 _tokenId, string calldata _newURI)`: Dynamically updates an SBT's metadata URI based on ongoing performance.
22. `getRefinerCognitoMark(address _refiner)`: Gets the token ID of a refiner's CognitoMark SBT.

**VI. Dispute Resolution (3 functions)**
23. `raiseDispute(uint256 _taskId)`: Tasker or Refiner raises a dispute against a task outcome.
24. `voteOnDispute(uint256 _taskId, bool _supportTasker, string calldata _reasonHash)`: DAO members vote on a raised dispute.
25. `resolveDispute(uint256 _taskId)`: Finalizes a dispute based on DAO vote, redistributing funds and updating reputations accordingly.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // For URI
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI
import "@openzeppelin/contracts/utils/Counters.sol"; // For task IDs, proposal IDs

// --- Custom Errors ---
// Defined here for better code organization and clarity.
error AetherMind__InvalidTaskStatus();
error AetherMind__Unauthorized();
error AetherMind__TaskNotFound();
error AetherMind__RefinerNotFound(); // While a struct exists, this implies an active staker
error AetherMind__StakeTooLow();
error AetherMind__AlreadyStaking();
error AetherMind__NotStaking();
error AetherMind__DeadlineNotMet();
error AetherMind__InvalidCommitment();
error AetherMind__RefinementAlreadySubmitted();
error AetherMind__NoCommitmentFound();
error AetherMind__RevealDeadlinePassed();
error AetherMind__SelectionDeadlinePassed();
error AetherMind__InsufficientFunds();
error AetherMind__VotingNotActive();
error AetherMind__AlreadyVoted();
error AetherMind__ProposalNotFound();
error AetherMind__ProposalNotExecutable();
error AetherMind__ProposalAlreadyExecuted();
error AetherMind__NoCognitoMarkToUpdate();
error AetherMind__InvalidDisputeResolution(); // e.g., trying to vote on resolved dispute
error AetherMind__TaskerCannotBeRefiner();
error AetherMind__RefinerCannotBeTasker();
error AetherMind__NoRefinementsSubmitted();
error AetherMind__CannotSelectBeforeRevealDeadline();
error AetherMind__TaskAlreadyRewarded();
error AetherMind__CannotDisputeCancelledTask();
error AetherMind__VotingPeriodNotOver();


// --- Helper Contracts (Simplified for demonstration) ---
// In a production environment, these would typically be full OpenZeppelin contracts
// deployed separately for robustness and security.

// 1. CognitoToken: A simplified ERC20 token for staking and rewards.
contract CognitoToken is IERC20 {
    string public name = "Cognito Token";
    string public symbol = "COG";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply; // Mints all to deployer
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        if (currentAllowance < amount) revert AetherMind__InsufficientFunds();
        allowance[sender][msg.sender] = currentAllowance - amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        if (balanceOf[sender] < amount) revert AetherMind__InsufficientFunds();
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// 2. CognitoMarkSBT: A simplified ERC721-like Soulbound Token (SBT).
// It's non-transferable and one per address, and its metadata URI can be dynamically updated.
contract CognitoMarkSBT is IERC721, IERC721Metadata {
    using Strings for uint256;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances; // For balanceOf compatibility (will be 0 or 1)
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) private _tokenIds; // Maps owner address to their single SBT token ID
    uint256 private _nextTokenId;

    string public name = "CognitoMark SBT";
    string public symbol = "CGM";
    address public minter; // Address of the AetherMindCollective contract

    constructor(address _minter) {
        _nextTokenId = 1;
        minter = _minter;
    }

    modifier onlyMinter() {
        if (msg.sender != minter) revert("CognitoMarkSBT: Only minter can call this function");
        _;
    }

    // ERC721 Standard Functions (read-only relevant ones)
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert("ERC721: address zero is not a valid owner");
        return _balances[owner]; // Will be 0 or 1 for SBT
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert("ERC721: invalid token ID");
        return owner;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert("ERC721Metadata: URI query for nonexistent token");
        // No base URI, so just return the specific token's URI.
        return _tokenURIs[tokenId];
    }

    // SBT-specific: Non-transferable, no approvals
    function approve(address, uint256) public pure override { revert("CognitoMarkSBT: SBTs are non-transferable"); }
    function getApproved(uint256) public pure override returns (address) { revert("CognitoMarkSBT: SBTs are non-transferable"); }
    function setApprovalForAll(address, bool) public pure override { revert("CognitoMarkSBT: SBTs are non-transferable"); }
    function isApprovedForAll(address, address) public pure override returns (bool) { revert("CognitoMarkSBT: SBTs are non-transferable"); }
    function transferFrom(address, address, uint256) public pure override { revert("CognitoMarkSBT: SBTs are non-transferable"); }
    function safeTransferFrom(address, address, uint256) public pure override { revert("CognitoMarkSBT: SBTs are non-transferable"); }
    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override { revert("CognitoMarkSBT: SBTs are non-transferable"); }

    // Internal helper for checking token existence
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Internal minting logic
    function _mint(address to, uint256 tokenId, string memory uri) internal {
        if (to == address(0)) revert("ERC721: mint to the zero address");
        if (_exists(tokenId)) revert("ERC721: token already minted");
        if (_tokenIds[to] != 0) revert("CognitoMarkSBT: address already has an SBT"); // SBT specific: one per address

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = uri;
        _tokenIds[to] = tokenId; // Map owner address to its token ID

        emit Transfer(address(0), to, tokenId);
    }

    // Internal URI update logic
    function _setTokenURI(uint256 tokenId, string memory _uri) internal {
        if (!_exists(tokenId)) revert("ERC721Metadata: URI set for nonexistent token");
        _tokenURIs[tokenId] = _uri;
    }

    // External function callable by the AetherMindCollective to mint
    function mint(address to, string memory uri) external onlyMinter returns (uint256) {
        uint256 newTokenId = _nextTokenId;
        _nextTokenId++;
        _mint(to, newTokenId, uri);
        return newTokenId;
    }

    // External function callable by the AetherMindCollective to update URI
    function updateURI(uint256 tokenId, string memory newUri) external onlyMinter {
        _setTokenURI(tokenId, newUri);
    }

    // Helper to get token ID by owner (SBT specific)
    function getTokenIdByOwner(address owner) external view returns (uint256) {
        return _tokenIds[owner];
    }

    event Transfer(address indexed from, address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 tokenId); // Not used, but part of interface
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); // Not used, but part of interface
}


// --- Main AetherMindCollective Contract ---
contract AetherMindCollective is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- I. State Variables & Constants ---

    // Token instances
    CognitoToken public immutable COG_TOKEN; // Cognito Token for staking and rewards
    CognitoMarkSBT public immutable COGNITO_MARK_SBT; // Soulbound Token for reputation proof

    // System parameters
    address public aiDataFeedOracle; // Address of the trusted AI data feed oracle
    uint256 public minRefinerStake = 1000 * (10**18); // Minimum COG required to stake as a Refiner (1000 COG)
    uint256 public constant REPUTATION_MULTIPLIER = 100; // Multiplier for reputation points gained per COG bounty

    // Task Management
    Counters.Counter private _taskIdCounter;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256[]) public userTasks; // Stores task IDs per user, for easy lookup

    // Default time windows for task phases (can be adjusted via DAO)
    uint256 public constant DEFAULT_AI_SUBMISSION_WINDOW = 1 days; // For AI submission after task creation
    uint256 public constant DEFAULT_REFINEMENT_COMMITMENT_WINDOW = 3 days; // For refiner commitments after AI output
    uint256 public constant DEFAULT_REFINEMENT_REVEAL_WINDOW = 2 days; // For refiner reveals after commitment deadline
    uint256 public constant DEFAULT_SELECTION_WINDOW = 1 days; // For selecting best refinement after reveal deadline

    enum TaskStatus {
        PendingAI, // Task submitted, waiting for AI oracle
        PendingRefinementCommitment, // AI output received, waiting for refiner commitments
        PendingRefinementReveal, // Commitments received, waiting for refiner reveals
        PendingSelection, // Reveals received, waiting for best refinement selection
        Finalized, // Task completed, rewards distributed
        Disputed, // Task is under dispute resolution
        Canceled // Task cancelled by tasker
    }

    struct Task {
        uint256 taskId;
        address tasker;
        bytes32 inputHash; // Hash of the task description/input data
        string aiInputPrompt; // Prompt sent to AI for initial output
        string aiOutputURL; // URL/identifier for AI's initial output
        uint256 bounty; // Reward for the best refinement
        uint256 taskerStake; // Stake from the tasker, released upon finalization or used for dispute
        uint256 aiSubmissionDeadline;
        uint256 refinementCommitmentDeadline;
        uint256 refinementRevealDeadline;
        uint256 selectionDeadline;
        address selectedRefiner; // Address of the refiner whose output was chosen
        // bytes32 finalOutputHash; // Hash of the final refined output (if relevant, off-chain check)
        string finalOutputURL; // URL/identifier for the final refined output
        TaskStatus status;
        bool rewarded;
        mapping(address => bytes32) refinerCommitments; // refiner => hash of (refinement + salt)
        mapping(address => string) refinerReveals; // refiner => actual refinement output URL/identifier
        address[] committedRefiners; // List of refiners who committed (for iteration)
    }

    // Refiner Management
    mapping(address => Refiner) public refiners;

    struct Refiner {
        uint256 stake;
        uint256 reputation; // Reputation score
        bool isStaking; // True if current stake >= minRefinerStake
    }

    // DAO Governance
    Counters.Counter private _proposalIdCounter;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalVotingPeriod = 7 days; // Default voting period for proposals
    uint256 public minReputationForProposal = 500; // Minimum reputation to create a proposal

    enum ProposalState {
        Pending, // Not yet started (if there's a delay logic)
        Active,
        Succeeded,
        Defeated,
        Executed
    }

    struct Proposal {
        uint256 proposalId;
        address proposer;
        address targetContract; // Contract address to call
        bytes callData; // Encoded function call for parameter change
        string description;
        uint256 creationTime;
        uint256 deadline;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted; // Refiner address => hasVoted
        ProposalState state;
        bool executed;
    }

    // Dispute Resolution
    uint256 public disputeResolutionPeriod = 3 days; // Period for DAO members to vote on a dispute
    mapping(uint256 => Dispute) public disputes; // taskId => Dispute

    enum DisputeStatus {
        Pending,
        ResolvedTasker, // Resolved in favor of tasker
        ResolvedRefiner, // Resolved in favor of refiner
        ResolvedDraw // No clear winner, funds split/returned
    }

    struct Dispute {
        uint256 taskId;
        address disputer; // Address who raised the dispute
        uint256 creationTime;
        uint256 deadline;
        uint256 taskerVotes; // Votes in favor of tasker
        uint256 refinerVotes; // Votes in favor of refiner
        mapping(address => bool) hasVoted; // DAO member address => hasVoted
        DisputeStatus status;
    }

    // --- II. Events ---

    event TaskSubmitted(uint256 indexed taskId, address indexed tasker, uint256 bounty, uint256 taskerStake);
    event AIOutputSubmitted(uint256 indexed taskId, string aiOutputURL);
    event RefinementCommitted(uint256 indexed taskId, address indexed refiner);
    event RefinementRevealed(uint256 indexed taskId, address indexed refiner, string revealedRefinementURL);
    event BestRefinementSelected(uint256 indexed taskId, address indexed selectedRefiner, string finalOutputURL, uint256 reward);
    event TaskFinalized(uint256 indexed taskId, TaskStatus finalStatus);
    event TaskCanceled(uint256 indexed taskId, address indexed tasker);

    event RefinerStaked(address indexed refiner, uint256 amount, uint256 totalStake);
    event RefinerUnstaked(address indexed refiner, uint256 amount, uint256 totalStake);
    event ReputationUpdated(address indexed refiner, uint256 newReputation);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 yesVotes, uint256 noVotes);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    event CognitoMarkMinted(address indexed owner, uint256 indexed tokenId, string initialURI);
    event CognitoMarkAttributesUpdated(uint256 indexed tokenId, string newURI);

    event DisputeRaised(uint256 indexed taskId, address indexed disputer);
    event DisputeVoteCast(uint256 indexed taskId, address indexed voter, bool supportTasker);
    event DisputeResolved(uint256 indexed taskId, DisputeStatus status);


    // --- IV. Constructor & Initial Setup ---

    constructor() Ownable(msg.sender) {
        // Deploy COG_TOKEN and mint initial supply to msg.sender
        COG_TOKEN = new CognitoToken(1_000_000_000 * (10**18)); // Example: 1 Billion COG tokens

        // Deploy CognitoMarkSBT, passing this contract's address as the minter
        COGNITO_MARK_SBT = new CognitoMarkSBT(address(this));

        // Initial setup for the owner (can be transitioned to DAO later via proposals)
        aiDataFeedOracle = msg.sender; // Placeholder: contract deployer is initial oracle
        // minRefinerStake and proposalVotingPeriod are already set to default constants.
    }

    // --- V. Configuration (DAO-Governed) ---

    modifier onlyAIDataFeedOracle() {
        if (msg.sender != aiDataFeedOracle) revert AetherMind__Unauthorized();
        _;
    }

    // 2. setAIDataFeedOracle(address _oracle): Sets the trusted AI data feed oracle address.
    // In a full DAO, this would be callable only via an executed proposal.
    function setAIDataFeedOracle(address _oracle) public onlyOwner {
        if (_oracle == address(0)) revert("AetherMind: Invalid AI Oracle address");
        aiDataFeedOracle = _oracle;
    }

    // 3. setDisputeResolutionPeriod(uint256 _period): Sets the duration for dispute voting.
    // In a full DAO, this would be callable only via an executed proposal.
    function setDisputeResolutionPeriod(uint256 _period) public onlyOwner {
        if (_period == 0) revert("AetherMind: Period cannot be zero");
        disputeResolutionPeriod = _period;
    }

    // 4. setMinRefinerStake(uint256 _minStake): Sets the minimum COG tokens required to stake as a Refiner.
    // In a full DAO, this would be callable only via an executed proposal.
    function setMinRefinerStake(uint256 _minStake) public onlyOwner {
        minRefinerStake = _minStake;
    }

    // 5. setProposalVotingPeriod(uint256 _period): Sets the duration for governance proposal voting.
    // In a full DAO, this would be callable only via an executed proposal.
    function setProposalVotingPeriod(uint256 _period) public onlyOwner {
        if (_period == 0) revert("AetherMind: Period cannot be zero");
        proposalVotingPeriod = _period;
    }

    // --- VI. Task Management ---

    // 6. submitTask(...): Tasker creates a new task, deposits bounty and stake.
    function submitTask(
        bytes32 _inputHash,
        string calldata _aiInputPrompt,
        uint256 _bounty,
        uint256 _taskerStake,
        uint256 _aiSubmissionOffset, // e.g., 1 days
        uint256 _refinementCommitmentOffset, // e.g., 3 days AFTER AI submission
        uint256 _refinementRevealOffset, // e.g., 2 days AFTER commitment deadline
        uint256 _selectionOffset // e.g., 1 day AFTER reveal deadline
    ) public nonReentrant returns (uint256) {
        if (_bounty == 0) revert("AetherMind: Bounty must be greater than zero");
        if (_taskerStake == 0) revert("AetherMind: Tasker stake must be greater than zero");
        if (COG_TOKEN.balanceOf(msg.sender) < _bounty + _taskerStake) revert(AetherMind__InsufficientFunds());
        if (!COG_TOKEN.transferFrom(msg.sender, address(this), _bounty + _taskerStake)) revert("AetherMind: Token transfer failed");

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        uint256 aiSubmitDeadline = block.timestamp + _aiSubmissionOffset;
        uint256 commitmentDeadline = aiSubmitDeadline + _refinementCommitmentOffset;
        uint256 revealDeadline = commitmentDeadline + _refinementRevealOffset;
        uint256 selectionDeadline = revealDeadline + _selectionOffset;

        tasks[newTaskId] = Task({
            taskId: newTaskId,
            tasker: msg.sender,
            inputHash: _inputHash,
            aiInputPrompt: _aiInputPrompt,
            aiOutputURL: "",
            bounty: _bounty,
            taskerStake: _taskerStake,
            aiSubmissionDeadline: aiSubmitDeadline,
            refinementCommitmentDeadline: commitmentDeadline,
            refinementRevealDeadline: revealDeadline,
            selectionDeadline: selectionDeadline,
            selectedRefiner: address(0),
            finalOutputURL: "",
            status: TaskStatus.PendingAI,
            rewarded: false,
            committedRefiners: new address[](0)
        });

        userTasks[msg.sender].push(newTaskId);

        emit TaskSubmitted(newTaskId, msg.sender, _bounty, _taskerStake);
        return newTaskId;
    }

    // 7. submitAIOutput(uint256 _taskId, string calldata _aiOutputURL): AI Oracle submits its initial processing result.
    function submitAIOutput(uint256 _taskId, string calldata _aiOutputURL) public onlyAIDataFeedOracle nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.status != TaskStatus.PendingAI) revert(AetherMind__InvalidTaskStatus());
        if (block.timestamp > task.aiSubmissionDeadline) revert(AetherMind__DeadlineNotMet());
        if (bytes(_aiOutputURL).length == 0) revert("AetherMind: AI Output URL cannot be empty");

        task.aiOutputURL = _aiOutputURL;
        task.status = TaskStatus.PendingRefinementCommitment;
        emit AIOutputSubmitted(_taskId, _aiOutputURL);
    }

    // 8. commitRefinement(uint256 _taskId, bytes32 _hashedRefinement): Refiner commits a hash of their refined output (and a secret salt).
    function commitRefinement(uint256 _taskId, bytes32 _hashedRefinement) public nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.status != TaskStatus.PendingRefinementCommitment) revert(AetherMind__InvalidTaskStatus());
        if (block.timestamp > task.refinementCommitmentDeadline) revert(AetherMind__DeadlineNotMet());
        if (refiners[msg.sender].stake < minRefinerStake || !refiners[msg.sender].isStaking) revert(AetherMind__StakeTooLow());
        if (task.tasker == msg.sender) revert(AetherMind__RefinerCannotBeTasker()); // Tasker cannot refine their own task
        if (task.refinerCommitments[msg.sender] != bytes32(0)) revert(AetherMind__RefinementAlreadySubmitted());

        task.refinerCommitments[msg.sender] = _hashedRefinement;
        task.committedRefiners.push(msg.sender);
        emit RefinementCommitted(_taskId, msg.sender);
    }

    // 9. revealRefinement(uint256 _taskId, string calldata _revealedRefinementURL, bytes32 _salt): Refiner reveals their actual refined output and salt.
    function revealRefinement(uint256 _taskId, string calldata _revealedRefinementURL, bytes32 _salt) public nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.status != TaskStatus.PendingRefinementCommitment && task.status != TaskStatus.PendingRefinementReveal) {
            revert(AetherMind__InvalidTaskStatus());
        }
        if (block.timestamp > task.refinementRevealDeadline) revert(AetherMind__RevealDeadlinePassed());
        if (task.refinerCommitments[msg.sender] == bytes32(0)) revert(AetherMind__NoCommitmentFound());
        if (bytes(task.refinerReveals[msg.sender]).length > 0) revert(AetherMind__RefinementAlreadySubmitted());

        bytes32 computedHash = keccak256(abi.encodePacked(_revealedRefinementURL, _salt));
        if (computedHash != task.refinerCommitments[msg.sender]) revert(AetherMind__InvalidCommitment());

        task.refinerReveals[msg.sender] = _revealedRefinementURL;

        // Transition status if enough reveals are in or deadline is met for reveals
        if (task.status == TaskStatus.PendingRefinementCommitment) {
            task.status = TaskStatus.PendingRefinementReveal;
        }

        // Optional: Immediately transition to PendingSelection if all committed refiners have revealed early
        // For simplicity, let's allow this to be triggered by the selection deadline or manual selection.

        emit RefinementRevealed(_taskId, msg.sender, _revealedRefinementURL);
    }

    // 10. selectBestRefinement(uint256 _taskId, address _selectedRefiner): DAO or an automated process selects the best refinement.
    // This function can be called by the DAO (via proposal execution) or by a designated "selector" role.
    function selectBestRefinement(uint256 _taskId, address _selectedRefiner) public nonReentrant onlyOwner { // Simplified to onlyOwner for now
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.status != TaskStatus.PendingRefinementReveal && task.status != TaskStatus.PendingSelection) revert(AetherMind__InvalidTaskStatus());
        if (block.timestamp < task.refinementRevealDeadline) revert(AetherMind__CannotSelectBeforeRevealDeadline()); // Give refiners time to reveal
        if (block.timestamp > task.selectionDeadline) revert(AetherMind__SelectionDeadlinePassed());
        if (task.selectedRefiner != address(0)) revert("AetherMind: Refiner already selected for this task");
        if (bytes(task.refinerReveals[_selectedRefiner]).length == 0) revert("AetherMind: Selected refiner did not reveal");
        if (!refiners[_selectedRefiner].isStaking) revert("AetherMind: Selected refiner is not an active staker");

        task.selectedRefiner = _selectedRefiner;
        task.finalOutputURL = task.refinerReveals[_selectedRefiner];
        task.status = TaskStatus.PendingSelection; // Stays in PendingSelection until `finalizeTask` is called
        emit BestRefinementSelected(_taskId, _selectedRefiner, task.finalOutputURL, task.bounty);
    }

    // 11. finalizeTask(uint256 _taskId): Completes task, distributes rewards, updates reputation. Can be called by anyone after selection deadline.
    function finalizeTask(uint256 _taskId) public nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.status == TaskStatus.Finalized || task.status == TaskStatus.Disputed || task.status == TaskStatus.Canceled) revert(AetherMind__InvalidTaskStatus());
        if (task.rewarded) revert(AetherMind__TaskAlreadyRewarded());

        // Ensure selection deadline has passed OR a refiner has been manually selected
        if (block.timestamp < task.selectionDeadline && task.selectedRefiner == address(0)) {
            revert("AetherMind: Cannot finalize before selection deadline or manual selection");
        }

        address tasker = task.tasker;
        address selectedRefiner = task.selectedRefiner;

        if (selectedRefiner != address(0)) {
            // Reward the selected refiner with the bounty
            if (!COG_TOKEN.transfer(selectedRefiner, task.bounty)) revert("AetherMind: Reward transfer failed");
            
            // Update reputation for selected refiner
            refiners[selectedRefiner].reputation += (task.bounty / (10**decimals)) * REPUTATION_MULTIPLIER; // Adjust for decimals
            emit ReputationUpdated(selectedRefiner, refiners[selectedRefiner].reputation);

            // Penalize refiners who committed but failed to reveal
            for(uint i=0; i < task.committedRefiners.length; i++) {
                address currentRefiner = task.committedRefiners[i];
                if (currentRefiner != selectedRefiner && task.refinerCommitments[currentRefiner] != bytes32(0) && bytes(task.refinerReveals[currentRefiner]).length == 0) {
                     if (refiners[currentRefiner].reputation > 50) refiners[currentRefiner].reputation -= 50; // Example penalty
                     emit ReputationUpdated(currentRefiner, refiners[currentRefuner].reputation);
                }
            }

            // Mint/update CognitoMark for the best refiner if conditions met
            _handleCognitoMarkForRefiner(selectedRefiner);

            // Return tasker's initial stake (since task was successful)
            if (task.taskerStake > 0) {
                 if (!COG_TOKEN.transfer(tasker, task.taskerStake)) revert("AetherMind: Tasker stake return failed");
            }
        } else {
            // No refiner selected or no valid reveals, refund bounty AND stake to tasker
            if (task.committedRefiners.length == 0) {
                 if (!COG_TOKEN.transfer(tasker, task.bounty + task.taskerStake)) revert("AetherMind: Bounty+Stake refund failed");
            } else { // Some refiners committed, but none selected or revealed correctly.
                     // Bounty remains in contract as protocol fee (or burnt). Tasker stake is returned.
                if (!COG_TOKEN.transfer(tasker, task.taskerStake)) revert("AetherMind: Tasker stake refund failed");
            }
        }

        task.rewarded = true;
        task.status = TaskStatus.Finalized;
        emit TaskFinalized(_taskId, TaskStatus.Finalized);
    }

    // Internal function to handle CognitoMark minting/updating
    // 20. _handleCognitoMarkForRefiner(address _refiner): Internal helper function to manage CognitoMark SBTs.
    function _handleCognitoMarkForRefiner(address _refiner) internal {
        // Example logic: Mint a CognitoMark if reputation is high enough and they don't have one
        // Or update attributes if they already have one.
        // A specific minimum reputation (e.g., 1000) for initial minting could be a parameter.
        if (refiners[_refiner].reputation >= 1000 && COGNITO_MARK_SBT.getTokenIdByOwner(_refiner) == 0) {
            string memory initialURI = string(abi.encodePacked("ipfs://cogmark/", _refiner.toHexString(), "/initial_rep_", refiners[_refiner].reputation.toString(), ".json"));
            mintCognitoMark(_refiner, initialURI); // Call external mint function of SBT
        } else if (COGNITO_MARK_SBT.getTokenIdByOwner(_refiner) != 0) {
            // Update existing CognitoMark attributes based on new reputation/performance
            uint256 tokenId = COGNITO_MARK_SBT.getTokenIdByOwner(_refiner);
            string memory updatedURI = string(abi.encodePacked("ipfs://cogmark/", _refiner.toHexString(), "/updated_rep_", refiners[_refiner].reputation.toString(), ".json"));
            updateCognitoMarkAttributes(tokenId, updatedURI); // Call external update function of SBT
        }
    }

    // 12. claimTaskOutput(uint256 _taskId): Tasker retrieves the final refined output's URL.
    function claimTaskOutput(uint256 _taskId) public view returns (string memory) {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.tasker != msg.sender) revert(AetherMind__Unauthorized());
        if (task.status != TaskStatus.Finalized && task.status != TaskStatus.Disputed) revert(AetherMind__InvalidTaskStatus()); // Disputed could also yield an output

        return task.finalOutputURL;
    }

    // 13. cancelTask(uint256 _taskId): Allows tasker to cancel before AI processing if no refiners have committed.
    function cancelTask(uint256 _taskId) public nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.tasker != msg.sender) revert(AetherMind__Unauthorized());
        if (task.status != TaskStatus.PendingAI && task.status != TaskStatus.PendingRefinementCommitment) revert(AetherMind__InvalidTaskStatus());
        if (task.committedRefiners.length > 0) revert("AetherMind: Cannot cancel, refiners have already committed.");
        if (block.timestamp > task.aiSubmissionDeadline) revert("AetherMind: Cannot cancel after AI submission deadline");

        // Refund tasker's stake and bounty
        if (!COG_TOKEN.transfer(msg.sender, task.bounty + task.taskerStake)) revert("AetherMind: Refund failed");

        task.status = TaskStatus.Canceled;
        emit TaskCanceled(_taskId, msg.sender);
    }

    // --- VII. Refiner Staking & Reputation ---

    // 14. stakeAsRefiner(uint256 _amount): Refiner stakes COG tokens to participate and earn reputation.
    function stakeAsRefiner(uint256 _amount) public nonReentrant {
        if (_amount < minRefinerStake) revert(AetherMind__StakeTooLow());
        if (refiners[msg.sender].isStaking) revert(AetherMind__AlreadyStaking()); // Only one active stake for simplicity

        if (!COG_TOKEN.transferFrom(msg.sender, address(this), _amount)) revert("AetherMind: Token transfer failed");

        refiners[msg.sender].stake = _amount;
        refiners[msg.sender].isStaking = true;
        emit RefinerStaked(msg.sender, _amount, refiners[msg.sender].stake);
    }

    // 15. unstakeRefiner(uint256 _amount): Refiner unstakes COG tokens.
    function unstakeRefiner(uint256 _amount) public nonReentrant {
        if (!refiners[msg.sender].isStaking) revert(AetherMind__NotStaking());
        if (refiners[msg.sender].stake < _amount) revert(AetherMind__InsufficientFunds());

        refiners[msg.sender].stake -= _amount;
        if (refiners[msg.sender].stake < minRefinerStake) {
            refiners[msg.sender].isStaking = false; // Below min stake, no longer considered active staker
        }

        if (!COG_TOKEN.transfer(msg.sender, _amount)) revert("AetherMind: Token transfer failed");
        emit RefinerUnstaked(msg.sender, _amount, refiners[msg.sender].stake);
    }

    // 16. getRefinerReputation(address _refiner): Queries a refiner's current reputation score.
    function getRefinerReputation(address _refiner) public view returns (uint256) {
        return refiners[_refiner].reputation;
    }

    // --- VIII. DAO Governance ---

    // 17. proposeParameterChange(...): Create a new governance proposal.
    function proposeParameterChange(address _target, bytes calldata _callData, string calldata _description, uint256 _votingPeriod) public nonReentrant returns (uint256) {
        if (refiners[msg.sender].reputation < minReputationForProposal) revert(AetherMind__Unauthorized());
        if (_votingPeriod == 0) revert("AetherMind: Voting period cannot be zero");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = Proposal({
            proposalId: newProposalId,
            proposer: msg.sender,
            targetContract: _target,
            callData: _callData,
            description: _description,
            creationTime: block.timestamp,
            deadline: block.timestamp + _votingPeriod,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active,
            executed: false
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, proposals[newProposalId].deadline);
        return newProposalId;
    }

    // 18. voteOnProposal(uint256 _proposalId, bool _support): Vote on an active proposal.
    function voteOnProposal(uint256 _proposalId, bool _support) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) revert(AetherMind__ProposalNotFound());
        if (proposal.state != ProposalState.Active) revert(AetherMind__VotingNotActive());
        if (block.timestamp > proposal.deadline) {
            proposal.state = (proposal.yesVotes > proposal.noVotes) ? ProposalState.Succeeded : ProposalState.Defeated;
            revert(AetherMind__VotingNotActive()); // Revert after updating state if deadline passed
        }
        if (proposal.hasVoted[msg.sender]) revert(AetherMind__AlreadyVoted());
        if (!refiners[msg.sender].isStaking) revert("AetherMind: Only staked refiners can vote"); // Only active stakers can vote

        // Votes are weighted by stake for simplicity. A more complex system might factor in reputation.
        uint256 voteWeight = refiners[msg.sender].stake; // Using stake as vote weight
        if (_support) {
            proposal.yesVotes += voteWeight;
        } else {
            proposal.noVotes += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;
        emit VoteCast(_proposalId, msg.sender, _support, proposal.yesVotes, proposal.noVotes);
    }

    // 19. executeProposal(uint256 _proposalId): Execute a passed proposal.
    function executeProposal(uint256 _proposalId) public nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposalId == 0) revert(AetherMind__ProposalNotFound());
        if (block.timestamp < proposal.deadline) revert(AetherMind__VotingPeriodNotOver());
        if (proposal.executed) revert(AetherMind__ProposalAlreadyExecuted());

        if (proposal.yesVotes <= proposal.noVotes) { // Simple majority for now
            proposal.state = ProposalState.Defeated;
            revert(AetherMind__ProposalNotExecutable());
        }

        // Execute the call
        (bool success, ) = proposal.targetContract.call(proposal.callData);
        if (!success) revert("AetherMind: Proposal execution failed");

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, true);
    }

    // --- IX. Dynamic Soulbound Tokens (CognitoMarks) ---

    // 20. mintCognitoMark(address _recipient, string calldata _initialURI): Mint a CognitoMark SBT.
    // This is an internal function, called by `_handleCognitoMarkForRefiner`.
    function mintCognitoMark(address _recipient, string calldata _initialURI) internal {
        if (_recipient == address(0)) revert("AetherMind: Cannot mint to zero address");
        // CognitoMarkSBT contract itself enforces one per address.
        // It's safe to call its external mint function as this contract is the minter.
        uint256 tokenId = COGNITO_MARK_SBT.mint(_recipient, _initialURI);
        emit CognitoMarkMinted(_recipient, tokenId, _initialURI);
    }

    // 21. updateCognitoMarkAttributes(uint256 _tokenId, string calldata _newURI): Dynamically updates an SBT's metadata URI.
    // This is typically called by `_handleCognitoMarkForRefiner` after reputation changes.
    function updateCognitoMarkAttributes(uint256 _tokenId, string calldata _newURI) public nonReentrant {
        // Only the AetherMindCollective contract (or its owner for direct actions) can call this.
        // The call to COGNITO_MARK_SBT.updateURI will ensure msg.sender is the minter (this contract).
        if (COGNITO_MARK_SBT.ownerOf(_tokenId) == address(0)) revert(AetherMind__NoCognitoMarkToUpdate());

        COGNITO_MARK_SBT.updateURI(_tokenId, _newURI); // This will succeed as msg.sender is this contract
        emit CognitoMarkAttributesUpdated(_tokenId, _newURI);
    }

    // 22. getRefinerCognitoMark(address _refiner): Gets the token ID of a refiner's CognitoMark SBT.
    function getRefinerCognitoMark(address _refiner) public view returns (uint256) {
        return COGNITO_MARK_SBT.getTokenIdByOwner(_refiner);
    }

    // --- X. Dispute Resolution ---

    // 23. raiseDispute(uint256 _taskId): Tasker or Refiner raises a dispute against a task outcome.
    function raiseDispute(uint256 _taskId) public nonReentrant {
        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound());
        if (task.status == TaskStatus.Disputed) revert("AetherMind: Task already under dispute");
        if (task.tasker != msg.sender && task.selectedRefiner != msg.sender) revert(AetherMind__Unauthorized());
        if (task.status == TaskStatus.Canceled) revert(AetherMind__CannotDisputeCancelledTask());

        task.status = TaskStatus.Disputed;

        disputes[_taskId] = Dispute({
            taskId: _taskId,
            disputer: msg.sender,
            creationTime: block.timestamp,
            deadline: block.timestamp + disputeResolutionPeriod,
            taskerVotes: 0,
            refinerVotes: 0,
            status: DisputeStatus.Pending
        });

        emit DisputeRaised(_taskId, msg.sender);
    }

    // 24. voteOnDispute(uint256 _taskId, bool _supportTasker, string calldata _reasonHash): DAO members vote on a raised dispute.
    function voteOnDispute(uint256 _taskId, bool _supportTasker, string calldata _reasonHash) public nonReentrant {
        Dispute storage dispute = disputes[_taskId];
        if (dispute.taskId == 0) revert("AetherMind: No active dispute for this task");
        if (dispute.status != DisputeStatus.Pending) revert(AetherMind__InvalidDisputeResolution());
        if (block.timestamp > dispute.deadline) revert("AetherMind: Dispute voting period ended");
        if (dispute.hasVoted[msg.sender]) revert(AetherMind__AlreadyVoted());
        if (!refiners[msg.sender].isStaking) revert("AetherMind: Only staked refiners can vote on disputes"); // Only active stakers can vote

        // Weight votes by stake, similar to governance proposals
        uint256 voteWeight = refiners[msg.sender].stake;
        if (_supportTasker) {
            dispute.taskerVotes += voteWeight;
        } else {
            dispute.refinerVotes += voteWeight;
        }
        dispute.hasVoted[msg.sender] = true;
        emit DisputeVoteCast(_taskId, msg.sender, _supportTasker);
    }

    // 25. resolveDispute(uint256 _taskId): Finalize dispute based on DAO vote.
    function resolveDispute(uint256 _taskId) public nonReentrant {
        Dispute storage dispute = disputes[_taskId];
        if (dispute.taskId == 0) revert("AetherMind: No active dispute for this task");
        if (dispute.status != DisputeStatus.Pending) revert(AetherMind__InvalidDisputeResolution());
        if (block.timestamp < dispute.deadline) revert(AetherMind__VotingPeriodNotOver());

        Task storage task = tasks[_taskId];
        if (task.taskId == 0) revert(AetherMind__TaskNotFound()); // Should not happen if dispute exists
        if (task.rewarded) revert(AetherMind__TaskAlreadyRewarded()); // Ensure funds haven't been paid out

        if (dispute.taskerVotes > dispute.refinerVotes) {
            // Tasker wins: Tasker gets stake + bounty back. Selected refiner (if any) is penalized.
            dispute.status = DisputeStatus.ResolvedTasker;

            if (!COG_TOKEN.transfer(task.tasker, task.bounty + task.taskerStake)) revert("AetherMind: Tasker refund failed");

            // Optionally penalize the selected refiner who was disputed against
            if (task.selectedRefiner != address(0) && refiners[task.selectedRefiner].reputation >= 100) {
                refiners[task.selectedRefiner].reputation -= 100; // Example penalty
                emit ReputationUpdated(task.selectedRefiner, refiners[task.selectedRefiner].reputation);
            }
            task.selectedRefiner = address(0); // Output deemed invalid
            task.finalOutputURL = "";
        } else if (dispute.refinerVotes > dispute.taskerVotes) {
            // Refiner wins: Selected refiner (if any) gets bounty + tasker's stake. Tasker loses stake.
            dispute.status = DisputeStatus.ResolvedRefiner;

            if (task.selectedRefiner != address(0)) {
                if (!COG_TOKEN.transfer(task.selectedRefiner, task.bounty + task.taskerStake)) revert("AetherMind: Refiner reward failed");
                refiners[task.selectedRefiner].reputation += ((task.bounty + task.taskerStake) / (10**decimals)) * REPUTATION_MULTIPLIER;
                emit ReputationUpdated(task.selectedRefiner, refiners[task.selectedRefiner].reputation);
                _handleCognitoMarkForRefiner(task.selectedRefiner);
            } else { // No refiner was selected, but dispute ruled against tasker (e.g. tasker cancelled unfairly).
                     // Bounty and stake remain in contract (or burned).
            }
            task.taskerStake = 0; // Stake is reallocated
        } else {
            // Draw: Refund tasker stake and bounty (if not already paid to refiner)
            dispute.status = DisputeStatus.ResolvedDraw;
            if (!COG_TOKEN.transfer(task.tasker, task.bounty + task.taskerStake)) revert("AetherMind: Tasker full refund failed on draw");
            task.selectedRefiner = address(0);
        }

        task.rewarded = true; // Mark as resolved/rewarded
        task.status = TaskStatus.Finalized; // Dispute resolution marks task as finalized
        emit DisputeResolved(_taskId, dispute.status);
        emit TaskFinalized(_taskId, TaskStatus.Disputed); // Emit finalized event after dispute
    }

    // --- XI. View Functions ---

    function getTask(uint256 _taskId) public view returns (Task memory) {
        return tasks[_taskId];
    }

    function getRefiner(address _refiner) public view returns (Refiner memory) {
        return refiners[_refiner];
    }

    function getProposal(uint256 _proposalId) public view returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function getDispute(uint256 _taskId) public view returns (Dispute memory) {
        return disputes[_taskId];
    }

    function getTaskCommittedRefiners(uint256 _taskId) public view returns (address[] memory) {
        return tasks[_taskId].committedRefiners;
    }

    function getUserTasks(address _user) public view returns (uint256[] memory) {
        return userTasks[_user];
    }

    // Helper to get CognitoToken decimals
    function decimals() public view returns (uint8) {
        return COG_TOKEN.decimals();
    }
}
```