Okay, here is a Solidity smart contract designed around the concept of a "Meta-Asset Forge & Community Hub". It combines elements of decentralized governance, asset management (ERC-20 & ERC-721), a simple reputation system, dynamic parameters, a unique "forging" mechanic for creating new assets, and the concept of temporary "catalyst" effects based on participation.

It aims to be interesting, advanced (using governance patterns, dynamic state, inter-asset logic), creative (the forge and catalyst concepts), and trendy (DAO-like elements, NFTs, dynamic utility). It has well over 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721s safely
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial setup, will transfer governance later

/**
 * @title MetaAssetForgeHub
 * @dev A dynamic, community-governed hub for managing diverse digital assets (ERC20, ERC721),
 *      facilitating the creation of new "Meta-Assets", managing strategies, and fostering
 *      community participation via a reputation system and temporary effects (Catalysts).
 *      It acts as a vault, a governance module, and a crafting mechanism.
 *
 * Outline:
 * 1. State Variables & Data Structures: Storage for assets, reputation, proposals, strategies, recipes, parameters.
 * 2. Events: Log key actions like deposits, proposals, votes, executions, forging, etc.
 * 3. Errors: Custom errors for clarity.
 * 4. Modifiers: Access control and state checks.
 * 5. Constructor: Initial setup.
 * 6. Asset Management (Vault): Deposit/Withdraw ERC20/ERC721.
 * 7. Governance: Create, vote on, and execute proposals for various actions (withdrawals, parameter changes, strategy definitions).
 * 8. Reputation System: Track and update user reputation (driven by governance/activity).
 * 9. Meta-Asset Forge: Define recipes and allow users to combine assets to forge new Meta-Asset NFTs.
 * 10. Dynamic Strategies: Define and execute community-approved strategies using vault assets (simulated interaction).
 * 11. Catalyst Effects: Grant temporary, reputation-based benefits.
 * 12. Dynamic Parameters: Community-governed system settings.
 * 13. Query Functions: Read state variables.
 * 14. Emergency Controls: Pause system.
 *
 * Function Summary:
 * - Management & State:
 *   - constructor: Initializes contract, sets owner.
 *   - pauseSystem: Pauses contract (emergency council/governance).
 *   - unpauseSystem: Unpauses contract (emergency council/governance).
 *   - onERC721Received: Required by ERC721Holder for safe transfers.
 *
 * - Asset Management (Vault):
 *   - depositERC20: Allows users to deposit approved ERC20 tokens.
 *   - withdrawERC20: Allows withdrawal of ERC20s via successful proposal execution.
 *   - depositERC721: Allows users to deposit approved ERC721 tokens.
 *   - withdrawERC721: Allows withdrawal of ERC721s via successful proposal execution.
 *   - getVaultHoldingsERC20: Query the hub's ERC20 balance for a specific token.
 *   - getVaultHoldingsERC721: Query the owner of a specific ERC721 token ID held by the hub.
 *
 * - Governance:
 *   - createProposal: Users with sufficient reputation can create various types of proposals.
 *   - voteOnProposal: Users with voting power can vote Yes or No on a proposal.
 *   - executeProposal: Executes a proposal if it has passed the threshold and quorum.
 *   - delegateVote: Users can delegate their voting power to another address.
 *   - updateReputationScore: Updates a user's reputation score (intended to be called by governance execution).
 *   - getCurrentVotingPower: Calculates user's current voting power based on reputation and potentially stake.
 *   - getProposalState: Query the current state of a proposal.
 *   - getProposalDetails: Query all details of a proposal.
 *   - getUserVote: Query how a user voted on a specific proposal.
 *
 * - Meta-Asset Forge:
 *   - defineForgeRecipe: Governance defines or updates a recipe for forging a specific Meta-Asset type.
 *   - forgeMetaAsset: Allows a user to combine required input assets (ERC20/ERC721) from their balance
 *                     or their deposited vault assets to mint a new Meta-Asset NFT based on an active recipe.
 *   - getForgeRecipe: Query the details of a specific Meta-Asset forging recipe.
 *   - getMetaAssetOwner: Query the owner of a specific Meta-Asset NFT ID forged by this contract.
 *   - getMetaAssetType: Query the type of a specific Meta-Asset NFT ID forged by this contract.
 *
 * - Dynamic Strategies:
 *   - defineStrategy: Governance defines or updates a strategy for the hub to potentially execute (e.g., yield farming simulation).
 *   - executeStrategy: Executes a defined strategy using vault assets (simulated external interaction/state change). Requires governance approval.
 *   - claimStrategyRewards: Allows claiming rewards generated by executed strategies (simulated).
 *   - getStrategyDetails: Query details of a specific strategy.
 *   - getActiveStrategies: Query the list of currently defined strategy IDs.
 *
 * - Catalyst Effects:
 *   - activateCatalystToken: Allows a user meeting reputation/stake requirements to activate a temporary catalyst effect (simulated by an internal flag/timer).
 *   - deactivateCatalystToken: Allows a user to end their active catalyst effect.
 *   - isCatalystEffectActive: Checks if a user's catalyst effect is currently active.
 *
 * - Dynamic Parameters:
 *   - setParameter: Governance function to update various system parameters (e.g., proposal threshold, voting period, forge costs).
 *   - getParameter: Query the current value of a specific system parameter.
 *
 * - Utility/Queries:
 *   - getUserReputation: Query a user's current reputation score.
 *
 */
contract MetaAssetForgeHub is Ownable, ERC721Holder, ReentrancyGuard {

    // --- State Variables & Data Structures ---

    // Asset Holdings (simplified storage, assumes ownership via contract balance)
    mapping(address => uint256) private erc20VaultBalances; // Token address -> Balance in vault
    mapping(address => mapping(uint256 => address)) private erc721VaultOwnership; // Token address -> Token ID -> Owner (conceptually, who deposited it)
    mapping(address => mapping(address => uint256)) private userERC20VaultBalances; // User -> Token Address -> Balance deposited by user
    mapping(address => mapping(address => uint256[])) private userERC721VaultTokenIds; // User -> Token Address -> List of Token IDs deposited by user

    // Reputation System
    mapping(address => uint256) public userReputation;
    mapping(address => address) private voteDelegates; // User -> Delegatee address
    mapping(address => uint256) private delegatedVotingPower; // Delegatee -> Total delegated power

    // Governance System
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed, Expired }
    struct Proposal {
        uint256 id;
        address proposer;
        string description; // Short description of the proposal
        bytes data; // Encoded call data for execution (if applicable)
        uint256 startBlock;
        uint256 endBlock;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 executionDelayBlocks; // Blocks after success until executable
        bool executed;
        bool canceled; // Canceled by proposer or governance
        ProposalState state;
        mapping(address => bool) voters; // User -> Has Voted
    }
    uint255 public proposalCounter = 0;
    mapping(uint256 => Proposal) public proposals;
    address public governanceCouncilAddress; // Address authorized to execute sensitive initial setups or emergency pause

    // Meta-Asset Forge System
    struct ForgeInput {
        address assetAddress;
        bool isERC721; // true for ERC721, false for ERC20
        uint256 amountOrId; // Amount for ERC20, specific ID for ERC721
    }
    struct ForgeRecipe {
        uint256 recipeId; // Unique ID for the recipe
        bool isActive;
        string name; // e.g., "Basic Meta-Asset", "Advanced Catalyst Generator"
        ForgeInput[] requiredInputs; // List of assets needed
        uint256 outputMetaAssetType; // Integer ID representing the type of Meta-Asset NFT produced
        uint256 forgeFee; // Fee in a specific ERC20 token (governable parameter)
        address feeTokenAddress;
    }
    uint256 public metaAssetRecipeCounter = 0;
    mapping(uint256 => ForgeRecipe) public forgeRecipes;
    mapping(uint256 => uint256) private metaAssetIdToType; // Meta-Asset Token ID -> Type ID
    mapping(uint256 => address) private metaAssetIdToOwner; // Meta-Asset Token ID -> Owner
    uint256 private metaAssetTokenIdCounter = 0; // Counter for minted Meta-Asset NFT IDs

    // Dynamic Strategy System
    struct Strategy {
        uint256 strategyId; // Unique ID
        bool isActive;
        string name; // e.g., "Vault Staking Strategy", "Lending Protocol Interaction"
        address targetProtocol; // Address of external protocol (simulated)
        bytes executionCallData; // Encoded call data for the strategy action (governable)
        uint256 yieldPerExecution; // Simulated yield generated
        address yieldTokenAddress; // Token in which yield is paid (governable parameter)
    }
    uint256 public strategyCounter = 0;
    mapping(uint256 => Strategy) public strategies;

    // Catalyst System
    mapping(address => uint256) private catalystExpiryTimestamp; // User -> Timestamp when catalyst expires

    // Dynamic Parameters
    mapping(bytes32 => uint256) public uintParameters; // Key -> Value
    mapping(bytes32 => address) public addressParameters; // Key -> Value
    mapping(bytes32 => bool) public boolParameters; // Key -> Value

    // Parameter Keys (hashed strings for gas efficiency)
    bytes32 public constant PARAM_MIN_REPUTATION_CREATE_PROPOSAL = keccak256("MIN_REPUTATION_CREATE_PROPOSAL");
    bytes32 public constant PARAM_VOTING_PERIOD_BLOCKS = keccak256("VOTING_PERIOD_BLOCKS");
    bytes32 public constant PARAM_PROPOSAL_THRESHOLD_BPS = keccak256("PROPOSAL_THRESHOLD_BPS"); // Basis points (e.g., 500 = 5%)
    bytes32 public constant PARAM_QUORUM_BPS = keccak256("QUORUM_BPS"); // Basis points
    bytes32 public constant PARAM_PROPOSAL_EXECUTION_DELAY_BLOCKS = keccak256("PROPOSAL_EXECUTION_DELAY_BLOCKS");
    bytes32 public constant PARAM_VOTING_POWER_PER_REPUTATION = keccak256("VOTING_POWER_PER_REPUTATION"); // Multiplier
    bytes32 public constant PARAM_CATALYST_REPUTATION_THRESHOLD = keccak256("CATALYST_REPUTATION_THRESHOLD");
    bytes32 public constant PARAM_CATALYST_DURATION_SECONDS = keccak256("CATALYST_DURATION_SECONDS");
    bytes32 public constant PARAM_FORGE_FEE_TOKEN = keccak256("FORGE_FEE_TOKEN"); // Address of the fee token
    bytes32 public constant PARAM_FORGE_DEFAULT_FEE = keccak256("FORGE_DEFAULT_FEE"); // Default fee amount

    // Pausability
    bool public paused = false;
    address[] public emergencyCouncil; // Addresses authorized to pause/unpause

    // --- Events ---

    event ERC20Deposited(address indexed user, address indexed token, uint256 amount);
    event ERC20Withdrawn(address indexed user, address indexed token, uint256 amount, uint256 indexed proposalId);
    event ERC721Deposited(address indexed user, address indexed token, uint256 indexed tokenId);
    event ERC721Withdrawn(address indexed user, address indexed token, uint256 indexed tokenId, uint256 indexed proposalId);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startBlock, uint256 endBlock);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    event ReputationUpdated(address indexed user, uint256 newReputation);
    event VoteDelegated(address indexed delegator, address indexed delegatee);

    event RecipeDefined(uint256 indexed recipeId, string name, bool isActive);
    event MetaAssetForged(address indexed owner, uint256 indexed metaAssetId, uint256 indexed recipeId, uint256 metaAssetType);

    event StrategyDefined(uint256 indexed strategyId, string name, bool isActive, address targetProtocol);
    event StrategyExecuted(uint256 indexed strategyId, uint256 indexed proposalId, bytes executionData);
    event StrategyRewardsClaimed(address indexed user, uint256 indexed strategyId, uint256 amount, address token);

    event CatalystActivated(address indexed user, uint256 expiryTimestamp);
    event CatalystDeactivated(address indexed user);

    event ParameterUpdated(bytes32 indexed key, uint256 value); // For uint parameters
    event ParameterUpdatedAddr(bytes32 indexed key, address value); // For address parameters
    event ParameterUpdatedBool(bytes32 indexed key, bool value); // For bool parameters

    event Paused(address account);
    event Unpaused(address account);

    // --- Errors ---

    error Unauthorized();
    error PausedSystem();
    error NotPausedSystem();
    error InvalidInput();
    error TransferFailed();
    error ERC721TransferFailed();
    error InsufficientBalance();
    error InsufficientAllowance();
    error InsufficientVaultBalance();
    error TokenNotFoundInVault();

    error ProposalNotFound();
    error ProposalNotActive();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error AlreadyVoted();
    error InsufficientVotingPower();
    error QuorumNotReached();
    error ThresholdNotReached();
    error ProposalExpired();

    error InsufficientReputation();
    error SelfDelegation();

    error RecipeNotFound();
    error RecipeNotActive();
    error InsufficientForgeInputs();
    error InvalidMetaAssetId();

    error StrategyNotFound();
    error StrategyNotActive();
    error StrategyExecutionFailed();
    error NoRewardsToClaim();

    error CatalystNotActive();
    error CatalystAlreadyActive();
    error InsufficientReputationForCatalyst();

    error ParameterNotFound();

    // --- Modifiers ---

    modifier whenNotPaused() {
        if (paused) revert PausedSystem();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPausedSystem();
        _;
    }

    modifier onlyGovOrEmergencyCouncil() {
        bool isGov = governanceCouncilAddress != address(0) && msg.sender == governanceCouncilAddress;
        bool isEmergency = false;
        for (uint i = 0; i < emergencyCouncil.length; i++) {
            if (emergencyCouncil[i] == msg.sender) {
                isEmergency = true;
                break;
            }
        }
        if (!isGov && !isEmergency) revert Unauthorized();
        _;
    }

    modifier onlyGovernance() {
        if (governanceCouncilAddress == address(0) || msg.sender != governanceCouncilAddress) revert Unauthorized();
        _;
    }


    // --- Constructor ---

    constructor(address _governanceCouncil, address[] memory _emergencyCouncil) Ownable(msg.sender) {
        governanceCouncilAddress = _governanceCouncil;
        emergencyCouncil = _emergencyCouncil;

        // Set initial parameters (can be changed by governance later)
        uintParameters[PARAM_MIN_REPUTATION_CREATE_PROPOSAL] = 10; // Needs 10 reputation to propose
        uintParameters[PARAM_VOTING_PERIOD_BLOCKS] = 100; // Voting open for 100 blocks
        uintParameters[PARAM_PROPOSAL_THRESHOLD_BPS] = 500; // 5% of total voting power must vote Yes
        uintParameters[PARAM_QUORUM_BPS] = 1000; // 10% of total voting power must participate
        uintParameters[PARAM_PROPOSAL_EXECUTION_DELAY_BLOCKS] = 20; // 20 blocks delay after success
        uintParameters[PARAM_VOTING_POWER_PER_REPUTATION] = 1; // 1 voting power per 1 reputation point
        uintParameters[PARAM_CATALYST_REPUTATION_THRESHOLD] = 50; // Needs 50 reputation for catalyst
        uintParameters[PARAM_CATALYST_DURATION_SECONDS] = 86400; // Catalyst lasts 1 day (86400 seconds)

        // Example default forge fee parameter
        addressParameters[PARAM_FORGE_FEE_TOKEN] = address(0); // Default: No fee token required initially
        uintParameters[PARAM_FORGE_DEFAULT_FEE] = 0; // Default: No fee initially
    }

    // --- Management & State ---

    /// @dev Pauses the contract functions. Only callable by governance or emergency council.
    function pauseSystem() public onlyGovOrEmergencyCouncil whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @dev Unpauses the contract functions. Only callable by governance or emergency council.
    function unpauseSystem() public onlyGovOrEmergencyCouncil whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    /// @dev Required for ERC721Holder compatibility. Accepts all ERC721 transfers.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Optional: Add checks here if you only want to accept certain ERC721 tokens
        return this.onERC721Received.selector;
    }

    // --- Asset Management (Vault) ---

    /// @dev Deposits ERC20 tokens into the hub's vault. Requires prior approval.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to deposit.
    function depositERC20(address token, uint256 amount) public whenNotPaused nonReentrant {
        if (amount == 0) revert InvalidInput();

        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        if (allowance < amount) revert InsufficientAllowance();

        if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        erc20VaultBalances[token] += amount;
        userERC20VaultBalances[msg.sender][token] += amount;

        emit ERC20Deposited(msg.sender, token, amount);
    }

    /// @dev Withdraws ERC20 tokens from the vault. This function is *only* executable
    ///      via a successful governance proposal.
    /// @param token The address of the ERC20 token.
    /// @param amount The amount of tokens to withdraw.
    /// @param recipient The address to send the tokens to.
    /// @param proposalId The ID of the governance proposal authorizing this withdrawal.
    function withdrawERC20(address token, uint256 amount, address recipient, uint256 proposalId) external whenNotPaused nonReentrant onlyGovernance {
         Proposal storage proposal = proposals[proposalId];
         if (proposal.state != ProposalState.Executed) revert ProposalNotExecutable(); // Ensure called within executeProposal context

        if (erc20VaultBalances[token] < amount) revert InsufficientVaultBalance();
        // Note: This simple withdrawal function doesn't track user deposits vs governance withdrawals
        // A more complex system would track which user can withdraw which amount or if withdrawals are collective.
        // This example assumes governance withdrawals from the collective pool.

        erc20VaultBalances[token] -= amount;

        if (!IERC20(token).transfer(recipient, amount)) revert TransferFailed();

        emit ERC20Withdrawn(recipient, token, amount, proposalId);
    }

    /// @dev Deposits ERC721 tokens into the hub's vault. Requires prior approval or safe transfer.
    /// @param token The address of the ERC721 token.
    /// @param tokenId The ID of the ERC721 token to deposit.
    function depositERC721(address token, uint256 tokenId) public whenNotPaused nonReentrant {
        // Requires the user to have approved the hub contract or use safeTransferFrom
        IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);

        erc721VaultOwnership[token][tokenId] = msg.sender; // Record who deposited it
        userERC721VaultTokenIds[msg.sender][token].push(tokenId);

        emit ERC721Deposited(msg.sender, token, tokenId);
    }

    /// @dev Withdraws ERC721 tokens from the vault. This function is *only* executable
    ///      via a successful governance proposal.
    /// @param token The address of the ERC721 token.
    /// @param tokenId The ID of the ERC721 token to withdraw.
    /// @param recipient The address to send the token to.
    /// @param proposalId The ID of the governance proposal authorizing this withdrawal.
    function withdrawERC721(address token, uint256 tokenId, address recipient, uint256 proposalId) external whenNotPaused nonReentrant onlyGovernance {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Executed) revert ProposalNotExecutable(); // Ensure called within executeProposal context

        // Check if the hub owns the token
        if (IERC721(token).ownerOf(tokenId) != address(this)) revert TokenNotFoundInVault();

        // Note: This simple withdrawal function doesn't track user deposits vs governance withdrawals
        // A more complex system would track which user can withdraw which token or if withdrawals are collective.
        // This example assumes governance withdrawals from the collective pool.
        // Also, doesn't update internal user list (userERC721VaultTokenIds) for simplicity in this example.

        try IERC721(token).safeTransferFrom(address(this), recipient, tokenId) {
             erc721VaultOwnership[token][tokenId] = address(0); // Clear deposit record conceptually
        } catch {
             revert ERC721TransferFailed();
        }

        emit ERC721Withdrawn(recipient, token, tokenId, proposalId);
    }

    /// @dev Queries the ERC20 balance of a specific token held in the vault.
    /// @param token The address of the ERC20 token.
    /// @return The amount of tokens held in the vault.
    function getVaultHoldingsERC20(address token) public view returns (uint256) {
        return erc20VaultBalances[token];
    }

     /// @dev Queries the conceptual owner (depositor) of a specific ERC721 token ID held by the hub.
     ///      Note: The actual owner is the hub contract address. This tracks who deposited it.
     /// @param token The address of the ERC721 token.
     /// @param tokenId The ID of the ERC721 token.
     /// @return The address that conceptually "owns" (deposited) the token in the vault, or address(0) if not tracked.
    function getVaultHoldingsERC721(address token, uint256 tokenId) public view returns (address) {
        return erc721VaultOwnership[token][tokenId];
    }


    // --- Governance ---

    /// @dev Allows a user to create a new proposal.
    /// @param description Short description of the proposal.
    /// @param target Address of the contract to call (can be self for internal actions).
    /// @param value ETH value to send with the call (usually 0).
    /// @param callData Encoded function call data.
    /// @param executionDelayBlocks Blocks after success before execution is possible.
    function createProposal(
        string calldata description,
        address target,
        uint256 value,
        bytes calldata callData,
        uint256 executionDelayBlocks
    ) external whenNotPaused returns (uint256 proposalId) {
        if (userReputation[msg.sender] < uintParameters[PARAM_MIN_REPUTATION_CREATE_PROPOSAL]) {
            revert InsufficientReputation();
        }

        proposalCounter++;
        proposalId = proposalCounter;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        // Note: Storing target, value, callData directly in struct for simplicity.
        // In a real system, this data might be external or hashed and verified on execution.
        // For this example, we'll store it in the `data` field as a tuple encoding.
        // Example encoding: abi.encode(target, value, callData)
        proposal.data = abi.encode(target, value, callData);
        proposal.startBlock = block.number;
        proposal.endBlock = block.number + uintParameters[PARAM_VOTING_PERIOD_BLOCKS];
        proposal.executionDelayBlocks = executionDelayBlocks;
        proposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, description, proposal.startBlock, proposal.endBlock);
    }

    /// @dev Allows a user to vote on an active proposal.
    /// @param proposalId The ID of the proposal.
    /// @param support True for Yes, False for No.
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.id == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.number > proposal.endBlock) { // Voting period ended
             _updateProposalState(proposal); // Transition to expired/defeated/succeeded
             revert ProposalExpired(); // Revert and inform the user it's too late
        }
        if (proposal.voters[msg.sender]) revert AlreadyVoted();

        uint256 votingPower = getCurrentVotingPower(msg.sender);
        if (votingPower == 0) revert InsufficientVotingPower();

        proposal.voters[msg.sender] = true;
        if (support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        emit VoteCast(msg.sender, proposalId, support, votingPower);
    }

     /// @dev Allows a user to delegate their voting power to another address.
     /// @param delegatee The address to delegate voting power to.
    function delegateVote(address delegatee) public whenNotPaused nonReentrant {
        if (delegatee == msg.sender) revert SelfDelegation();

        address currentDelegatee = voteDelegates[msg.sender];
        uint256 currentPower = getCurrentVotingPower(msg.sender); // Calculate based on reputation *before* changing delegatee

        // Deduct current power from old delegatee
        if (currentDelegatee != address(0)) {
             delegatedVotingPower[currentDelegatee] -= currentPower;
        }

        voteDelegates[msg.sender] = delegatee;
        delegatedVotingPower[delegatee] += currentPower;

        emit VoteDelegated(msg.sender, delegatee);
    }

    /// @dev Calculates the current voting power of a user.
    /// @param user The address to check.
    /// @return The calculated voting power.
    function getCurrentVotingPower(address user) public view returns (uint256) {
        // Simple model: Voting power = User's reputation * Voting Power Multiplier
        // Could be extended to include staked tokens, NFT ownership, etc.
        uint256 basePower = userReputation[user] * uintParameters[PARAM_VOTING_POWER_PER_REPUTATION];

        // If user has delegated, their direct power is 0, delegatee gets the sum
        // If user is a delegatee, they have their own power + delegated power
        // The `voteDelegates` mapping tracks who *delegated out*.
        // The `delegatedVotingPower` mapping tracks who *received delegations*.
        // A user's effective voting power is their own base power IF they haven't delegated,
        // PLUS any delegated power they have received.
        address delegatorOfUser = address(0);
        // Find if user is a delegator (simple check, doesn't traverse chains)
        // A more robust system would use checkpoints or recursion/iteration.
        // For simplicity, this just checks if the user has delegated *out*.
        if(voteDelegates[user] != address(0)) {
             basePower = 0; // If user delegates out, their direct power is zero.
        }

        return basePower + delegatedVotingPower[user];
    }


     /// @dev Executes a successfully passed and eligible proposal.
     ///      Only callable by the configured governanceCouncilAddress.
     /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public whenNotPaused nonReentrant onlyGovernance {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.id == 0 || proposal.state == ProposalState.Pending) revert ProposalNotFound(); // Ensure proposal exists

        // Ensure the state is updated based on current block
        _updateProposalState(proposal);

        if (proposal.state != ProposalState.Succeeded) revert ProposalNotExecutable();
        if (proposal.executed) revert ProposalAlreadyExecuted();
        if (block.number < proposal.endBlock + proposal.executionDelayBlocks) revert ProposalNotExecutable(); // Wait for delay

        // Decode execution data
        (address target, uint256 value, bytes memory callData) = abi.decode(proposal.data, (address, uint256, bytes));

        // Execute the proposal logic
        (bool success, ) = target.call{value: value}(callData);
        if (!success) {
            // Important: In a real DAO, failed execution might transition to a new state
            // or allow re-execution attempt. Simple model just reverts.
            revert StrategyExecutionFailed(); // Using a generic error for simplicity
        }

        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId);
    }

     /// @dev Updates a user's reputation score. Intended to be triggered by governance
     ///      proposals related to contributions or activity.
     /// @param user The address whose reputation to update.
     /// @param newReputation The new reputation score for the user.
    function updateReputationScore(address user, uint256 newReputation) external whenNotPaused onlyGovernance {
        // Potential governance action: A proposal could be created to call this function
        // with a specific user and score change based on off-chain activity or vault contributions.

        // Adjust delegated voting power if user has delegated
        address currentDelegatee = voteDelegates[user];
        if (currentDelegatee != address(0)) {
             uint256 oldVotingPower = userReputation[user] * uintParameters[PARAM_VOTING_POWER_PER_REPUTATION];
             uint256 newVotingPower = newReputation * uintParameters[PARAM_VOTING_POWER_PER_REPUTATION];
             if (oldVotingPower > newVotingPower) {
                 delegatedVotingPower[currentDelegatee] -= (oldVotingPower - newVotingPower);
             } else {
                 delegatedVotingPower[currentDelegatee] += (newVotingPower - oldVotingPower);
             }
        }

        userReputation[user] = newReputation;

        emit ReputationUpdated(user, newReputation);
    }

    /// @dev Internal helper to update proposal state based on current block.
    function _updateProposalState(Proposal storage proposal) internal {
        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
            uint256 totalVotingPower = 0; // In a real system, this would track total supply of governance token / total reputation that existed at the start block
            // For this example, let's simulate total power based on total reputation or assume a fixed value for threshold/quorum checks.
            // A simple approach: sum all reputation as total power. This is gas inefficient for large systems.
            // Better: Use a checkpoint system for total power at startBlock or define total power as a gov parameter.
            // Let's use a configurable total voting power parameter for threshold/quorum checks.
             uint256 totalPossibleVotingPower = uintParameters[keccak256("TOTAL_POSSIBLE_VOTING_POWER")]; // Need to set this via governance

            uint256 minYesVotes = (totalPossibleVotingPower * uintParameters[PARAM_PROPOSAL_THRESHOLD_BPS]) / 10000;
            uint256 minTotalVotes = (totalPossibleVotingPower * uintParameters[PARAM_QUORUM_BPS]) / 10000;
            uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;

            if (totalVotesCast < minTotalVotes || proposal.yesVotes < minYesVotes) {
                proposal.state = ProposalState.Defeated;
            } else {
                proposal.state = ProposalState.Succeeded;
            }
        }
        // No state change if already past Active or Pending
    }

    /// @dev Gets the current state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The ProposalState enum value.
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) return ProposalState.Pending; // Indicate not found or pending creation

        if (proposal.state == ProposalState.Active && block.number > proposal.endBlock) {
             // Recalculate state if voting period is over but state is still Active
            uint256 totalPossibleVotingPower = uintParameters[keccak256("TOTAL_POSSIBLE_VOTING_POWER")];
            uint256 minYesVotes = (totalPossibleVotingPower * uintParameters[PARAM_PROPOSAL_THRESHOLD_BPS]) / 10000;
            uint256 minTotalVotes = (totalPossibleVotingPower * uintParameters[PARAM_QUORUM_BPS]) / 10000;
            uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;

            if (totalVotesCast < minTotalVotes || proposal.yesVotes < minYesVotes) {
                return ProposalState.Defeated;
            } else {
                return ProposalState.Succeeded;
            }
        }

        return proposal.state;
    }

     /// @dev Gets the details of a proposal (excluding the votes mapping).
     /// @param proposalId The ID of the proposal.
     /// @return Tuple containing proposal details.
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        address proposer,
        string memory description,
        uint256 startBlock,
        uint256 endBlock,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 executionDelayBlocks,
        bool executed,
        bool canceled,
        ProposalState state
    ) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound();

        return (
            proposal.id,
            proposal.proposer,
            proposal.description,
            proposal.startBlock,
            proposal.endBlock,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.executionDelayBlocks,
            proposal.executed,
            proposal.canceled,
            getProposalState(proposalId) // Use the state-checking getter
        );
    }

     /// @dev Checks if a user has voted on a specific proposal.
     /// @param proposalId The ID of the proposal.
     /// @param user The address of the user.
     /// @return True if the user has voted, false otherwise.
    function getUserVote(uint256 proposalId, address user) public view returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) revert ProposalNotFound();
        return proposal.voters[user]; // Returns false if not in map (default)
    }


    // --- Meta-Asset Forge ---

    /// @dev Defines or updates a recipe for forging a Meta-Asset. Only callable by governance.
    ///      Requires the output Meta-Asset type ID to be specified.
    /// @param recipeId The ID of the recipe (0 to create a new one, existing ID to update).
    /// @param isActive Whether the recipe is active for forging.
    /// @param name The name of the recipe.
    /// @param requiredInputs Array of required input assets (ERC20 or ERC721).
    /// @param outputMetaAssetType The integer type ID of the Meta-Asset NFT produced.
    /// @param forgeFee The fee amount required for forging.
    /// @param feeTokenAddress The address of the token required for the fee.
    function defineForgeRecipe(
        uint256 recipeId,
        bool isActive,
        string calldata name,
        ForgeInput[] calldata requiredInputs,
        uint256 outputMetaAssetType,
        uint256 forgeFee,
        address feeTokenAddress
    ) external whenNotPaused onlyGovernance {
        uint256 currentRecipeId = recipeId;
        if (currentRecipeId == 0) {
            metaAssetRecipeCounter++;
            currentRecipeId = metaAssetRecipeCounter;
        } else {
             if (forgeRecipes[currentRecipeId].recipeId == 0) revert RecipeNotFound(); // Cannot update non-existent recipe
        }

        ForgeRecipe storage recipe = forgeRecipes[currentRecipeId];
        recipe.recipeId = currentRecipeId;
        recipe.isActive = isActive;
        recipe.name = name;
        recipe.requiredInputs = requiredInputs; // Copies the array
        recipe.outputMetaAssetType = outputMetaAssetType;
        recipe.forgeFee = forgeFee;
        recipe.feeTokenAddress = feeTokenAddress;

        emit RecipeDefined(currentRecipeId, name, isActive);
    }

    /// @dev Allows a user to forge a new Meta-Asset NFT by providing the required input assets
    ///      and paying the forging fee. Inputs can come from user's wallet or their vault deposits.
    /// @param recipeId The ID of the recipe to use.
    /// @param inputTokens ERC20 tokens to use as inputs (needs approval).
    /// @param inputNfts ERC721 tokens to use as inputs (needs approval/safe transfer).
    /// @param payFeeWithVault Whether to pay the forge fee using vault balance (if available) instead of user's wallet.
    function forgeMetaAsset(
        uint256 recipeId,
        // A flexible input mechanism might pass token addresses and amounts/ids directly,
        // rather than pre-listing in arrays, and let the function match against the recipe.
        // For simplicity, let's assume inputs are provided explicitly based on recipe requirements.
        // A more complex version would involve matching the provided inputs to the required inputs.
        // This simplified version assumes the user provides exactly what's needed.
        address[] calldata inputTokenAddresses, // ERC20 addresses for forging inputs
        uint256[] calldata inputTokenAmounts, // Amounts for ERC20 inputs
        address[] calldata inputNftAddresses, // ERC721 addresses for forging inputs
        uint256[] calldata inputNftTokenIds, // Token IDs for ERC721 inputs
        bool payFeeWithVault
    ) external whenNotPaused nonReentrant returns (uint256 newMetaAssetId) {
        ForgeRecipe storage recipe = forgeRecipes[recipeId];
        if (recipe.recipeId == 0) revert RecipeNotFound();
        if (!recipe.isActive) revert RecipeNotActive();

        // --- Check and Collect Inputs ---
        // This part is simplified. A real implementation needs careful validation:
        // 1. Match provided inputs against recipe.
        // 2. Check ownership/vault status for each input.
        // 3. Transfer/burn/lock inputs.

        // Example: Forcing transfer of specified ERC20/ERC721 inputs from user's wallet
        // A more complex system would allow using assets deposited *in the vault*
        // by the user (tracked via userERC20VaultBalances/userERC721VaultTokenIds).
        // For demonstration, let's require inputs directly from msg.sender's wallet.
        if (inputTokenAddresses.length != inputTokenAmounts.length ||
            inputNftAddresses.length != inputNftTokenIds.length) {
             revert InvalidInput();
        }
        // TODO: Add logic to match these inputs against recipe.requiredInputs

        // Collect required ERC20 inputs from user's wallet
        for (uint i = 0; i < inputTokenAddresses.length; i++) {
            address token = inputTokenAddresses[i];
            uint256 amount = inputTokenAmounts[i];
            if (amount > 0) {
                uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
                if (allowance < amount) revert InsufficientAllowance();
                if (!IERC20(token).transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
                // ERC20 inputs are transferred to the hub's vault
                 erc20VaultBalances[token] += amount;
            }
        }

        // Collect required ERC721 inputs from user's wallet
        for (uint i = 0; i < inputNftAddresses.length; i++) {
            address token = inputNftAddresses[i];
            uint256 tokenId = inputNftTokenIds[i];
            // Safe transfer assumes approval or operator status
            IERC721(token).safeTransferFrom(msg.sender, address(this), tokenId);
            // ERC721 inputs are transferred to the hub's vault
             erc721VaultOwnership[token][tokenId] = address(this); // Hub owns it now conceptually
             // Note: These transferred ERC721s are now "consumed" for forging. A real system might burn them or flag them as consumed.
        }

        // --- Pay Forging Fee ---
        uint256 fee = recipe.forgeFee > 0 ? recipe.forgeFee : uintParameters[PARAM_FORGE_DEFAULT_FEE]; // Use recipe fee if set, else default
        address feeToken = recipe.feeTokenAddress != address(0) ? recipe.feeTokenAddress : addressParameters[PARAM_FORGE_FEE_TOKEN]; // Use recipe token if set, else default

        if (fee > 0 && feeToken != address(0)) {
            if (payFeeWithVault) {
                 // Pay from user's deposited vault balance
                 if (userERC20VaultBalances[msg.sender][feeToken] < fee) revert InsufficientVaultBalance();
                 userERC20VaultBalances[msg.sender][feeToken] -= fee;
                 // Note: The fee token is conceptually transferred from user's *vault balance* to the *collective vault balance*
                 // No actual token transfer needed as it stays within the contract.
            } else {
                 // Pay from user's external wallet
                 uint256 allowance = IERC20(feeToken).allowance(msg.sender, address(this));
                 if (allowance < fee) revert InsufficientAllowance();
                 if (!IERC20(feeToken).transferFrom(msg.sender, address(this), fee)) revert TransferFailed();
                 erc20VaultBalances[feeToken] += fee; // Fee token goes to the hub's vault
            }
        }

        // --- Mint New Meta-Asset ---
        metaAssetTokenIdCounter++;
        newMetaAssetId = metaAssetTokenIdCounter;
        metaAssetIdToType[newMetaAssetId] = recipe.outputMetaAssetType;
        metaAssetIdToOwner[newMetaAssetId] = msg.sender; // Minter is the owner

        // In a real system, you'd interact with an external ERC721 contract here to mint the token
        // call IERC721(metaAssetContractAddress).mint(msg.sender, newMetaAssetId);
        // For this example, we track ownership internally via mappings.

        emit MetaAssetForged(msg.sender, newMetaAssetId, recipeId, recipe.outputMetaAssetType);
    }

     /// @dev Allows claiming yield potentially generated from Meta-Asset ownership or forging activity.
     ///      This is a simulated function. Real yield would come from strategies or external protocols.
     /// @param token Address of the token to claim as yield.
    function claimForgingYield(address token) public whenNotPaused nonReentrant {
        // This function is a placeholder. In a real scenario, yield would be tracked
        // based on Meta-Asset ownership or forging volume.
        // Example: uint256 yieldAmount = calculateYield(msg.sender, token);
        // if (yieldAmount == 0) revert NoRewardsToClaim();
        //
        // // Transfer yield token from vault balance to user
        // if (erc20VaultBalances[token] < yieldAmount) revert InsufficientVaultBalance();
        // erc20VaultBalances[token] -= yieldAmount;
        // if (!IERC20(token).transfer(msg.sender, yieldAmount)) revert TransferFailed();
        //
        // emit StrategyRewardsClaimed(msg.sender, 0, yieldAmount, token); // Using 0 as strategy ID for forge yield

         revert NoRewardsToClaim(); // Placeholder: No yield implemented in this example
    }


    /// @dev Queries the details of a specific Meta-Asset forging recipe.
    /// @param recipeId The ID of the recipe.
    /// @return Tuple containing recipe details.
    function getForgeRecipe(uint256 recipeId) public view returns (
        uint256 id,
        bool isActive,
        string memory name,
        ForgeInput[] memory requiredInputs,
        uint256 outputMetaAssetType,
        uint256 forgeFee,
        address feeTokenAddress
    ) {
        ForgeRecipe storage recipe = forgeRecipes[recipeId];
        if (recipe.recipeId == 0) revert RecipeNotFound();

        return (
            recipe.recipeId,
            recipe.isActive,
            recipe.name,
            recipe.requiredInputs,
            recipe.outputMetaAssetType,
            recipe.forgeFee,
            recipe.feeTokenAddress
        );
    }

     /// @dev Queries the conceptual owner of a minted Meta-Asset NFT ID.
     ///      (Internal tracking, assumes this contract manages ownership or mints via external contract).
     /// @param metaAssetId The ID of the Meta-Asset NFT.
     /// @return The owner's address.
    function getMetaAssetOwner(uint256 metaAssetId) public view returns (address) {
         if (metaAssetId == 0 || metaAssetId > metaAssetTokenIdCounter) revert InvalidMetaAssetId();
         return metaAssetIdToOwner[metaAssetId];
    }

     /// @dev Queries the type of a minted Meta-Asset NFT ID.
     ///      (Internal tracking, assumes this contract defines types).
     /// @param metaAssetId The ID of the Meta-Asset NFT.
     /// @return The type ID.
    function getMetaAssetType(uint256 metaAssetId) public view returns (uint256) {
         if (metaAssetId == 0 || metaAssetId > metaAssetTokenIdCounter) revert InvalidMetaAssetId();
         return metaAssetIdToType[metaAssetId];
    }


    // --- Dynamic Strategies ---

    /// @dev Defines or updates a strategy that the hub can potentially execute. Only callable by governance.
    /// @param strategyId The ID of the strategy (0 to create new, existing ID to update).
    /// @param isActive Whether the strategy is active for execution.
    /// @param name The name of the strategy.
    /// @param targetProtocol Address of the external protocol the strategy interacts with (simulated).
    /// @param executionCallData Encoded data for the strategy's main action.
    /// @param yieldPerExecution Simulated yield amount generated each time strategy is 'executed'.
    /// @param yieldTokenAddress Address of the token for simulated yield.
    function defineStrategy(
        uint256 strategyId,
        bool isActive,
        string calldata name,
        address targetProtocol,
        bytes calldata executionCallData,
        uint256 yieldPerExecution,
        address yieldTokenAddress
    ) external whenNotPaused onlyGovernance {
        uint256 currentStrategyId = strategyId;
        if (currentStrategyId == 0) {
            strategyCounter++;
            currentStrategyId = strategyCounter;
        } else {
             if (strategies[currentStrategyId].strategyId == 0) revert StrategyNotFound(); // Cannot update non-existent strategy
        }

        Strategy storage strategy = strategies[currentStrategyId];
        strategy.strategyId = currentStrategyId;
        strategy.isActive = isActive;
        strategy.name = name;
        strategy.targetProtocol = targetProtocol;
        strategy.executionCallData = executionCallData; // Stores the call data
        strategy.yieldPerExecution = yieldPerExecution;
        strategy.yieldTokenAddress = yieldTokenAddress;

        emit StrategyDefined(currentStrategyId, name, isActive, targetProtocol);
    }

    /// @dev Executes a defined strategy using assets from the vault.
    ///      This function is *only* executable via a successful governance proposal.
    ///      Simulates interaction with external protocol using `executionCallData`.
    /// @param strategyId The ID of the strategy to execute.
    /// @param proposalId The ID of the governance proposal authorizing this execution.
    function executeStrategy(uint256 strategyId, uint256 proposalId) external whenNotPaused nonReentrant onlyGovernance {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Executed) revert ProposalNotExecutable(); // Ensure called within executeProposal context

        Strategy storage strategy = strategies[strategyId];
        if (strategy.strategyId == 0) revert StrategyNotFound();
        if (!strategy.isActive) revert StrategyNotActive();

        // --- Simulate Strategy Execution ---
        // In a real system, this would involve:
        // 1. Transferring assets from vault to targetProtocol.
        // 2. Calling targetProtocol with strategy.executionCallData.
        // 3. Handling potential returns or state changes.
        // 4. Tracking simulated yield generated.

        // For this example, we simply log the execution and add simulated yield to the vault.
        // The actual interaction is bypassed.
        emit StrategyExecuted(strategyId, proposalId, strategy.executionCallData);

        // Simulate adding yield to the vault (using the defined yield token)
        if (strategy.yieldPerExecution > 0 && strategy.yieldTokenAddress != address(0)) {
            erc20VaultBalances[strategy.yieldTokenAddress] += strategy.yieldPerExecution;
            // Note: In a real system, this yield would likely be received *from* the targetProtocol.
        }
    }

    /// @dev Allows users to claim rewards generated by executed strategies.
    ///      This is a simulated function; reward distribution logic would be complex
    ///      (e.g., based on user's share of vault assets, participation, reputation, catalyst status).
     /// @param strategyId The ID of the strategy from which to claim rewards.
     /// @param token Address of the token to claim.
     /// @param amount Amount of token to claim.
    function claimStrategyRewards(uint256 strategyId, address token, uint256 amount) external whenNotPaused nonReentrant {
        // This function is a placeholder. Reward distribution logic is complex.
        // Example: uint256 availableRewards = calculateUserRewards(msg.sender, strategyId, token);
        // if (availableRewards == 0 || amount == 0 || amount > availableRewards) revert NoRewardsToClaim();
        //
        // // Transfer reward token from vault balance to user
        // if (erc20VaultBalances[token] < amount) revert InsufficientVaultBalance();
        // erc20VaultBalances[token] -= amount;
        // if (!IERC20(token).transfer(msg.sender, amount)) revert TransferFailed();
        //
        // // Decrement user's claimable amount in internal tracking (not shown here)
        //
        // emit StrategyRewardsClaimed(msg.sender, strategyId, amount, token);

         revert NoRewardsToClaim(); // Placeholder: No claimable rewards implemented in this example
    }

    /// @dev Queries the details of a specific strategy.
    /// @param strategyId The ID of the strategy.
    /// @return Tuple containing strategy details.
    function getStrategyDetails(uint256 strategyId) public view returns (
        uint256 id,
        bool isActive,
        string memory name,
        address targetProtocol,
        bytes memory executionCallData,
        uint256 yieldPerExecution,
        address yieldTokenAddress
    ) {
        Strategy storage strategy = strategies[strategyId];
        if (strategy.strategyId == 0) revert StrategyNotFound();

        return (
            strategy.strategyId,
            strategy.isActive,
            strategy.name,
            strategy.targetProtocol,
            strategy.executionCallData,
            strategy.yieldPerExecution,
            strategy.yieldTokenAddress
        );
    }

    /// @dev Returns the list of currently defined strategy IDs.
    /// @return An array of strategy IDs.
    function getActiveStrategies() public view returns (uint256[] memory) {
         uint256[] memory activeStrategyIds = new uint256[](strategyCounter);
         uint256 count = 0;
         for (uint i = 1; i <= strategyCounter; i++) {
             if (strategies[i].strategyId != 0 && strategies[i].isActive) {
                 activeStrategyIds[count] = i;
                 count++;
             }
         }
         bytes memory buffer = new bytes(32 * count);
         for(uint i = 0; i < count; i++) {
             assembly {
                 mstore(add(buffer, mul(i, 32)), mload(add(activeStrategyIds, add(32, mul(i, 32)))))
             }
         }
         return abi.decode(buffer, (uint256[])); // Return packed array
    }


    // --- Catalyst Effects ---

     /// @dev Allows a user meeting the reputation threshold to activate a temporary catalyst effect.
    function activateCatalystToken() public whenNotPaused nonReentrant {
        if (isCatalystEffectActive(msg.sender)) revert CatalystAlreadyActive();
        if (userReputation[msg.sender] < uintParameters[PARAM_CATALYST_REPUTATION_THRESHOLD]) revert InsufficientReputationForCatalyst();

        uint256 expiry = block.timestamp + uintParameters[PARAM_CATALYST_DURATION_SECONDS];
        catalystExpiryTimestamp[msg.sender] = expiry;

        emit CatalystActivated(msg.sender, expiry);
    }

     /// @dev Allows a user to deactivate their active catalyst effect early.
    function deactivateCatalystToken() public whenNotPaused {
        if (!isCatalystEffectActive(msg.sender)) revert CatalystNotActive();

        catalystExpiryTimestamp[msg.sender] = 0; // Set expiry to 0 or block.timestamp

        emit CatalystDeactivated(msg.sender);
    }

     /// @dev Checks if a user's catalyst effect is currently active.
     /// @param user The address to check.
     /// @return True if the catalyst is active and not expired, false otherwise.
    function isCatalystEffectActive(address user) public view returns (bool) {
        return catalystExpiryTimestamp[user] > block.timestamp;
    }

    // --- Dynamic Parameters ---

    /// @dev Sets a uint256 system parameter. Only callable by governance via proposal execution.
    /// @param key The keccak256 hash of the parameter name string.
    /// @param value The new value for the parameter.
    function setParameter(bytes32 key, uint256 value) external whenNotPaused onlyGovernance {
         uintParameters[key] = value;
         emit ParameterUpdated(key, value);
    }

     /// @dev Sets an address system parameter. Only callable by governance via proposal execution.
     /// @param key The keccak256 hash of the parameter name string.
     /// @param value The new value for the parameter.
    function setParameterAddr(bytes32 key, address value) external whenNotPaused onlyGovernance {
        addressParameters[key] = value;
        emit ParameterUpdatedAddr(key, value);
    }

     /// @dev Sets a bool system parameter. Only callable by governance via proposal execution.
     /// @param key The keccak256 hash of the parameter name string.
     /// @param value The new value for the parameter.
    function setParameterBool(bytes32 key, bool value) external whenNotPaused onlyGovernance {
        boolParameters[key] = value;
        emit ParameterUpdatedBool(key, value);
    }

    /// @dev Gets the value of a uint256 system parameter.
    /// @param key The keccak256 hash of the parameter name string.
    /// @return The current value of the parameter.
    function getParameter(bytes32 key) public view returns (uint256) {
        // Note: Returns 0 if key not found. Consider a mapping to track if a key has been set.
        return uintParameters[key];
    }

     /// @dev Gets the value of an address system parameter.
     /// @param key The keccak256 hash of the parameter name string.
     /// @return The current value of the parameter.
    function getParameterAddr(bytes32 key) public view returns (address) {
         return addressParameters[key];
    }

     /// @dev Gets the value of a bool system parameter.
     /// @param key The keccak256 hash of the parameter name string.
     /// @return The current value of the parameter.
    function getParameterBool(bytes32 key) public view returns (bool) {
         return boolParameters[key];
    }


    // --- Utility/Queries ---

    /// @dev Gets a user's current reputation score.
    /// @param user The address to check.
    /// @return The user's reputation score.
    function getUserReputation(address user) public view returns (uint256) {
        return userReputation[user];
    }

    // Optional: Add more query functions as needed for deposited balances per user, etc.
    // function getUserERC20VaultBalance(address user, address token) public view returns (uint256) { return userERC20VaultBalances[user][token]; }
    // function getUserERC721VaultTokenIds(address user, address token) public view returns (uint256[] memory) { return userERC721VaultTokenIds[user][token]; }


    // The following are standard Ownable functions, kept for initial deployment control.
    // Ownership should ideally be transferred to the governanceCouncilAddress or a multisig.
    // function transferOwnership(address newOwner) public virtual override onlyOwner {}
    // function renounceOwnership() public virtual override onlyOwner {}

    // Functions to manage the emergency council
    function setEmergencyCouncil(address[] calldata _emergencyCouncil) external onlyOwner {
        emergencyCouncil = _emergencyCouncil;
    }
}
```

---

**Explanation of Advanced/Interesting Concepts Used:**

1.  **Decentralized Governance:** The core functionality of controlling key actions (withdrawals, parameter changes, strategy execution, recipe definition) is shifted from a single owner to a proposal-based system requiring community votes.
2.  **Reputation System:** A basic on-chain reputation score influences voting power and eligibility for certain actions (like creating proposals or activating catalysts). This moves beyond simple token-weighted governance.
3.  **Dynamic Parameters:** Key system settings (voting periods, thresholds, fees, required reputation) are not hardcoded constants but are stored in mappings and can be changed via governance. This allows the protocol to adapt over time without requiring a full contract redeployment (assuming the core logic doesn't change fundamentally).
4.  **Meta-Asset Forging:** A unique mechanism (`forgeMetaAsset`) allows users to "craft" a new type of NFT ("Meta-Asset") by combining specific existing assets (ERC-20s and ERC-721s). This creates utility for held assets and introduces a crafting/collection layer.
5.  **Dynamic Strategies (Simulated):** The contract can define and "execute" various "strategies" using the pooled vault assets. While the external interaction is simulated here (`executeStrategy` just logs and adds simulated yield), the *structure* allows for defining complex, governable investment or interaction strategies.
6.  **Temporary Catalyst Effects:** A concept (`activateCatalystToken`) granting short-term benefits (simulated by a boolean/timer check) based on reaching a reputation threshold. This encourages participation and rewards active users.
7.  **Vault Management:** Handles multiple types of assets (ERC-20 and ERC-721) in a single contract, with clear separation of deposits and governance-controlled withdrawals. Uses `ERC721Holder` for safe ERC721 handling.
8.  **Modular Execution:** Proposals encode target address, value, and call data (`bytes data`), allowing governance to trigger arbitrary function calls (within safety constraints, like `onlyGovernance` modifier) on the hub contract itself or other approved contracts.
9.  **Voting Delegation:** Includes basic voting delegation (`delegateVote`), a standard pattern in more advanced DAO systems.
10. **Internal ERC721 Tracking:** While simplified (no external ERC721 contract interface shown for the Meta-Assets themselves), the contract tracks the owner and type of internally managed NFT IDs created by the forge.

This contract is complex and showcases how multiple concepts can be integrated. Please remember that this is an *example* for demonstration. A production-ready version would require extensive security audits, more robust handling of complex state transitions, potentially external interfaces for actual protocol interactions, and more sophisticated storage/gas optimizations. The reputation system is also very basic and could be improved with on-chain activity tracking or verifiable credentials.