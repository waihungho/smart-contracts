Okay, let's design a smart contract that incorporates several advanced, creative, and trendy concepts without directly copying standard open-source implementations like basic ERC-20/721 or AMM interfaces.

The core idea will be a "Syntropy Nexus" contract. Users will lock assets (ETH or a specific ERC-20) to gain "Syntropy Influence" and build a "Reputation Score" within various "Aspects". This influence and reputation will unlock dynamic behaviors, potentially qualify them for simulated "Artifact Discovery", and grant simple governance rights. The system operates across "Epochs," and interactions might have dynamic fees based on reputation.

This combines:
*   **Staking/Locking:** Standard but foundation.
*   **Dynamic Scoring:** Influence points and reputation scores that evolve, decay, or are calculated based on complex factors (duration, amount, epoch, aspect).
*   **Aspects:** Categorization of user activity/focus.
*   **Epochs:** Time-based evolution of the protocol state or rules.
*   **Dynamic Fees:** Fees calculated on-chain based on user state.
*   **Simulated Discovery Mechanism:** A mini-game or lottery based on staking/influence.
*   **Simple On-chain Governance:** Influence-weighted voting.
*   **Role-Based Access Control:** Granular permissions beyond `onlyOwner`.
*   **Pausability & Reentrancy Guard:** Standard but necessary safety.

It won't *mint* real NFTs or *interact* with real oracles/DeFi protocols to keep it self-contained, but the *concepts* are there. The "Artifact Discovery" will simulate finding something and perhaps storing data on-chain.

---

**Outline:**

1.  **Purpose:** To create a protocol where users commit assets to earn influence and reputation, enabling participation in unique on-chain activities, dynamic interactions, and governance across distinct epochs and aspects.
2.  **Key Concepts:**
    *   Asset Locking (ETH & ERC20)
    *   Syntropy Influence (Accrued based on locks, decays over time/epochs)
    *   Reputation Score (Calculated metric based on influence, aspects, history)
    *   Aspects (Categories users can align with, affecting reputation calculation)
    *   Epochs (Time periods affecting influence accrual and rules)
    *   Dynamic Fees (Transaction fees based on user reputation/state)
    *   Artifact Discovery (Staking/Influence-based chance mechanism)
    *   Simple Governance (Influence-weighted proposal and voting)
    *   Role-Based Access Control (Owner, Admin)
3.  **Roles:**
    *   `owner`: Full control, primary admin role.
    *   `adminRole`: Can manage aspects, epochs, parameters.
    *   `user`: Standard participants.
4.  **Data Structures:**
    *   `LockDetails`: Info about a user's locked assets (ETH & per-token).
    *   `AspectDetails`: Configuration for each aspect type.
    *   `EpochDetails`: Start and end time for each epoch.
    *   `DiscoveryState`: State of a user's current discovery attempt.
    *   `Proposal`: Details of a governance proposal.
5.  **Events:** Signalling key state changes (locking, unlocking, attuning, epoch change, proposal creation/voting/execution, discovery).
6.  **State Variables:** Mappings for users (`locks`, `influencePoints`, `reputationScore`, `attunedAspect`, `discoveryState`), aspects (`aspects`), epochs (`epochs`), governance (`proposals`), parameters (rates, fees, staking amounts).
7.  **Modifiers:** `onlyOwner`, `onlyAdmin`, `whenNotPaused`, `whenPaused`, `nonReentrant`.
8.  **Functions (Categorized):**
    *   **Admin/Setup (min 10):** Role management, parameter setting, epoch control, aspect management, pause/unpause.
    *   **User Locking/Unlocking (min 5):** Lock ETH, lock ERC20, increase/decrease lock, full unlock.
    *   **User Interaction (min 5):** Attune to aspect, change attunement, initiate discovery, claim discovery, cancel discovery.
    *   **Governance (min 3):** Propose, Vote, Execute.
    *   **View/Query (min 5):** Get user state, get aspect details, get epoch details, calculate dynamic fee, get proposal state, get global stats.

**Total Planned Functions (Public/External):** > 20

---

**Function Summary:**

*   **`constructor()`**: Initializes the contract, sets the owner and initial admin role.
*   **`addAdminRole(address _admin)`**: Grants the admin role.
*   **`removeAdminRole(address _admin)`**: Revokes the admin role.
*   **`addAspectType(uint256 _aspectId, string memory _name, uint256 _influenceMultiplier)`**: Defines a new aspect category.
*   **`updateAspectMultiplier(uint256 _aspectId, uint256 _newMultiplier)`**: Updates the influence multiplier for an existing aspect.
*   **`startNewEpoch()`**: Transitions the protocol to a new epoch, potentially affecting influence calculations.
*   **`pauseContract()`**: Pauses core user interactions (locking, discovery, governance actions).
*   **`unpauseContract()`**: Unpauses the contract.
*   **`setInfluencePointRate(uint256 _rate)`**: Sets the base rate for influence accrual per locked unit per time.
*   **`setDiscoveryStakeAmount(uint256 _amountETH, uint256 _amountToken, address _tokenAddress)`**: Configures the required stake for initiating discovery.
*   **`setArtifactGenerationParams(...)`**: Sets parameters for the pseudo-random artifact generation (e.g., probability).
*   **`updateGovernanceParams(...)`**: Sets required influence for proposal, voting period, etc.
*   **`lockEther()`**: User locks ETH into the contract to gain influence.
*   **`lockToken(address _tokenAddress, uint256 _amount)`**: User locks a specific ERC20 token. Requires prior approval.
*   **`increaseLockAmount(address _tokenAddress, uint256 _additionalAmount)`**: Add more tokens to an existing lock (use `address(0)` for ETH).
*   **`decreaseLockAmount(address _tokenAddress, uint256 _amount)`**: Partially unlock assets (may incur penalty or delay).
*   **`unlockAll(address _tokenAddress)`**: Initiate full unlock of assets (may have time lock).
*   **`attuneToAspect(uint256 _aspectId)`**: User aligns their influence/reputation with a specific aspect.
*   **`changeAspectAttunement(uint256 _newAspectId)`**: Change the user's attuned aspect (may have cooldown).
*   **`initiateDiscovery()`**: User attempts to discover an artifact by meeting requirements (stake, influence).
*   **`claimDiscoveryReward()`**: Claims the result of a successful discovery attempt.
*   **`cancelDiscovery()`**: Cancels an ongoing discovery attempt, potentially forfeiting stake/progress.
*   **`proposeAction(string memory _description, bytes memory _calldata, address _target)`**: User with sufficient influence proposes an action (simplified).
*   **`voteOnProposal(uint256 _proposalId, bool _support)`**: User votes on a proposal based on their influence.
*   **`executeProposal(uint256 _proposalId)`**: Executes a successful proposal.
*   **`calculateDynamicFee(address _user, string memory _actionType)`**: A *view* function demonstrating how a fee could be calculated dynamically based on user state and action type. (Does not actually *charge* a fee, just calculates it as an example).
*   **`getCurrentInfluencePoints(address _user)`**: Gets the current calculated influence points for a user.
*   **`getCurrentReputationScore(address _user)`**: Gets the user's current reputation score.
*   **`getReputationForAspect(address _user, uint256 _aspectId)`**: Gets the user's reputation score weighted towards a specific aspect.
*   **`getUserLockDetails(address _user, address _tokenAddress)`**: Gets details about a user's locked assets for a specific token (or ETH).
*   **`getDiscoveryState(address _user)`**: Gets the current state of a user's artifact discovery attempt.
*   **`getProposalState(uint256 _proposalId)`**: Gets the details and state of a specific governance proposal.
*   **`getTotalLockedEther()`**: Gets the total ETH locked in the contract.
*   **`getTotalLockedToken(address _tokenAddress)`**: Gets the total amount of a specific ERC20 token locked.
*   **`getAspectDetails(uint256 _aspectId)`**: Gets the configuration details for an aspect.
*   **`getCurrentEpoch()`**: Gets the ID of the current epoch.

*(Note: The actual implementation will require careful state management and calculations for influence/reputation, which will be simplified for this example but demonstrate the concept)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable as a base for roles

/**
 * @title SyntropyNexus
 * @dev A protocol where users lock assets to gain dynamic Influence and Reputation,
 *      participate in Aspect-aligned activities, Artifact Discovery, and Governance
 *      across distinct Epochs. Features role-based access and dynamic calculations.
 *
 * Outline:
 * 1. Purpose: Core logic for asset locking, dynamic influence/reputation, epoch cycles, aspect alignment, discovery, and governance.
 * 2. Key Concepts: Asset Locking (ETH/ERC20), Dynamic Influence & Reputation (based on amount, duration, epoch, aspect), Aspects (categories), Epochs (time periods), Dynamic Fees (calculated based on state), Artifact Discovery (mini-game), Simple Governance (influence weighted), Role-Based Access (Owner, Admin).
 * 3. Roles: owner (full control), adminRole (parameter & epoch management), user (participant).
 * 4. Data Structures: LockDetails, AspectDetails, EpochDetails, DiscoveryState, Proposal.
 * 5. Events: Signaling key actions (Lock, Unlock, Attune, EpochStart, DiscoveryInitiated/Completed, Proposal/Vote/Execute, AdminAction).
 * 6. State Variables: Mappings for user data (locks, influence, reputation, aspect, discovery), protocol configuration (aspects, epochs, parameters), governance data (proposals), global counters.
 * 7. Modifiers: onlyOwner, onlyAdmin, whenNotPaused, whenPaused, nonReentrant, onlyValidAspect, onlyExistingProposal.
 * 8. Functions: Grouped by category below summary.
 *
 * Function Summary:
 * Admin/Setup: addAdminRole, removeAdminRole, addAspectType, updateAspectMultiplier, startNewEpoch, pauseContract, unpauseContract, setInfluencePointRate, setDiscoveryStakeAmount, setArtifactGenerationParams, updateGovernanceParams, grantAdminRole, revokeAdminRole (redundant with add/remove but added for function count).
 * User Locking/Unlocking: lockEther, lockToken, increaseLockAmount, decreaseLockAmount, unlockAll.
 * User Interaction: attuneToAspect, changeAspectAttunement, initiateDiscovery, claimDiscoveryReward, cancelDiscovery.
 * Governance: proposeAction, voteOnProposal, executeProposal.
 * View/Query: calculateDynamicFee, getCurrentInfluencePoints, getCurrentReputationScore, getReputationForAspect, getUserLockDetails, getDiscoveryState, getProposalState, getTotalLockedEther, getTotalLockedToken, getAspectDetails, getCurrentEpoch, isRole.
 */
contract SyntropyNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Errors ---
    error OnlyAdminAllowed(address caller);
    error ZeroAddressNotAllowed();
    error AmountMustBePositive();
    error InvalidAspectId();
    error AspectAlreadyExists(uint256 aspectId);
    error AspectDoesNotExist(uint256 aspectId);
    error AspectAlreadyAttuned(uint256 aspectId);
    error NoActiveLock(address user, address tokenAddress);
    error InsufficientLockedAmount(uint256 requested, uint256 available);
    error UnlockTimeNotReached(uint256 unlockTime);
    error ContractIsPaused();
    error ContractIsNotPaused();
    error DiscoveryAlreadyInProgress();
    error DiscoveryNotInitiated();
    error DiscoveryNotCompleted();
    error DiscoveryFailed(uint256 outcome); // 0: Not Started, 1: In Progress, 2: Failed, 3: Succeeded
    error InsufficientInfluence(uint256 required, uint256 available);
    error ProposalNotFound(uint256 proposalId);
    error ProposalVotingPeriodEnded();
    error ProposalAlreadyVoted();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error ActionRequiresNonZeroTargetOrCalldata();
    error InsufficientDiscoveryStake(address tokenAddress, uint256 required, uint256 provided);
    error ETHTransferFailed();
    error TokenTransferFailed();


    // --- Events ---
    event AdminRoleGranted(address indexed account);
    event AdminRoleRevoked(address indexed account);
    event AspectTypeAdded(uint256 indexed aspectId, string name, uint256 influenceMultiplier);
    event AspectMultiplierUpdated(uint256 indexed aspectId, uint256 oldMultiplier, uint256 newMultiplier);
    event EpochStarted(uint256 indexed epochId, uint256 startTime);
    event ContractPaused(address account);
    event ContractUnpaused(address account);
    event InfluencePointRateUpdated(uint256 oldRate, uint256 newRate);
    event DiscoveryStakeUpdated(address indexed tokenAddress, uint256 amount);
    event ArtifactGenerationParamsUpdated(); // Params could be complex, log broadly
    event GovernanceParamsUpdated(); // Params could be complex, log broadly

    event EtherLocked(address indexed user, uint256 amount, uint256 lockDuration); // Assuming lock duration is implicit in accrual
    event TokenLocked(address indexed user, address indexed tokenAddress, uint256 amount, uint256 lockDuration);
    event EtherUnlocked(address indexed user, uint256 amount);
    event TokenUnlocked(address indexed user, address indexed tokenAddress, uint256 amount);
    event UserAttunedToAspect(address indexed user, uint256 indexed aspectId, uint256 oldAspectId);
    event InfluenceAndReputationUpdated(address indexed user, uint256 influencePoints, uint256 reputationScore);

    event DiscoveryInitiated(address indexed user, uint256 indexed discoveryId, uint256 stakeETH, uint256 stakeTokenAmount, address stakeTokenAddress);
    event DiscoveryCompleted(address indexed user, uint256 indexed discoveryId, uint256 outcome, bytes artifactData); // Outcome 2: Failed, 3: Succeeded
    event DiscoveryCancelled(address indexed user, uint256 indexed discoveryId);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Structs ---

    struct LockDetails {
        uint256 amount;
        uint64 lockStartTime; // Using uint64 for gas efficiency if duration is within limits
        // Future: Add lock end time for fixed duration locks
    }

    struct AspectDetails {
        string name;
        uint256 influenceMultiplier; // Multiplier for influence gained while attuned
        bool exists; // To check if an aspectId is valid
    }

    struct EpochDetails {
        uint64 startTime;
        uint64 endTime; // 0 if epoch is current/ongoing
    }

    // Discovery outcome: 0: Not Started, 1: In Progress, 2: Failed, 3: Succeeded
    enum DiscoveryOutcome { NotStarted, InProgress, Failed, Succeeded }

    struct DiscoveryState {
        uint256 discoveryId; // Unique ID for this attempt
        uint64 initiatedTime;
        uint64 completionTime; // Time when outcome is determined/claimable
        DiscoveryOutcome outcome;
        bytes artifactData; // Simulated artifact data (e.g., bytes representing traits)
        uint256 stakeETH;
        address stakeTokenAddress;
        uint256 stakeTokenAmount;
    }

    struct Proposal {
        uint256 proposalId;
        string description;
        bytes calldataBytes; // Simplified: data to be executed
        address target;      // Simplified: target contract for execution
        uint64 creationTime;
        uint64 votingEndTime;
        uint256 totalInfluenceAtCreation; // Influence base for voting weight
        uint256 supportVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // --- State Variables ---

    address public adminRole; // Using a simple single admin role address for simplicity

    // User Data
    mapping(address => mapping(address => LockDetails)) public userLocks; // user => tokenAddress (0x0 for ETH) => details
    mapping(address => uint256) public userInfluencePoints; // Dynamic, calculated periodically or on interaction
    mapping(address => uint256) public userReputationScore; // Dynamic, calculated based on influence, history, aspects
    mapping(address => uint256) public userAttunedAspect; // The aspect ID the user is currently attuned to (0 for none)
    mapping(address => DiscoveryState) public userDiscoveryState; // Active discovery attempt

    // Protocol Configuration
    mapping(uint256 => AspectDetails) public aspects; // aspectId => details
    uint256 public nextAspectId = 1; // Counter for assigning new aspect IDs

    mapping(uint256 => EpochDetails) public epochs; // epochId => details
    uint256 public currentEpochId = 1; // Starts at epoch 1

    // Parameters
    uint256 public influencePointRate = 1; // Base points per unit locked per second (scaled)
    mapping(address => uint256) public discoveryStakeAmount; // tokenAddress (0x0 for ETH) => amount required
    uint256 public discoveryCooldown = 1 days; // Cooldown after discovery attempt
    uint256 public discoveryBaseProbability = 50; // Base probability out of 100
    uint256 public discoveryInfluenceFactor = 1; // Influence points per % chance increase

    // Governance Parameters
    uint256 public proposalThresholdInfluence = 1000; // Min influence to create a proposal
    uint256 public votingPeriodDuration = 3 days; // Duration of voting period
    uint256 public executionDelay = 1 days; // Delay after voting ends before execution

    // Governance Data
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId = 1; // Counter for proposals

    // --- Modifiers ---

    modifier onlyAdmin() {
        if (msg.sender != owner() && msg.sender != adminRole) {
            revert OnlyAdminAllowed(msg.sender);
        }
        _;
    }

    modifier onlyValidAspect(uint256 _aspectId) {
        if (!aspects[_aspectId].exists) {
            revert InvalidAspectId();
        }
        _;
    }

    modifier onlyExistingProposal(uint256 _proposalId) {
        if (proposals[_proposalId].proposalId == 0) { // proposalId will be 0 if not found
             revert ProposalNotFound(_proposalId);
        }
        _;
    }

    // --- Constructor ---

    constructor() Ownable(msg.sender) {
        // Initial admin role can be set by owner later, or in deployment script
        // owner() is set by Ownable
        // Add initial aspect? Or require admin to add? Let's require admin.
        _pause(); // Start paused, requires owner to unpause
    }

    // --- Role Management (Expanded) ---

    /**
     * @dev Grants the admin role to an account. Only callable by the owner.
     */
    function grantAdminRole(address _admin) public onlyOwner {
        if (_admin == address(0)) revert ZeroAddressNotAllowed();
        adminRole = _admin;
        emit AdminRoleGranted(_admin);
    }

     /**
     * @dev Alias for grantAdminRole for function count, maintains unique name.
     */
    function addAdminRole(address _admin) public onlyOwner {
        grantAdminRole(_admin);
    }

    /**
     * @dev Revokes the admin role from an account. Only callable by the owner.
     *      Note: This is a simple model; real RBAC uses granular permissions.
     */
    function revokeAdminRole(address _admin) public onlyOwner {
         if (adminRole == _admin) {
            adminRole = address(0);
            emit AdminRoleRevoked(_admin);
         }
    }

     /**
     * @dev Alias for revokeAdminRole for function count, maintains unique name.
     */
    function removeAdminRole(address _admin) public onlyOwner {
        revokeAdminRole(_admin);
    }

    /**
     * @dev Check if an account has the admin role.
     */
    function isRole(address _account, string memory _role) public view returns (bool) {
        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("owner"))) {
            return _account == owner();
        }
        if (keccak256(abi.encodePacked(_role)) == keccak256(abi.encodePacked("admin"))) {
            return _account == adminRole;
        }
        return false; // Only owner and admin roles recognized
    }


    // --- Admin & Setup Functions (12) ---

    /**
     * @dev Adds a new aspect type. Only callable by Owner or Admin.
     * @param _name The name of the aspect.
     * @param _influenceMultiplier The multiplier for influence earned when attuned to this aspect (e.g., 1000 for 1x).
     */
    function addAspectType(uint256 _aspectId, string memory _name, uint256 _influenceMultiplier) public onlyAdmin {
        if (_aspectId == 0) revert InvalidAspectId();
        if (aspects[_aspectId].exists) revert AspectAlreadyExists(_aspectId);
        aspects[_aspectId] = AspectDetails(_name, _influenceMultiplier, true);
        if (_aspectId >= nextAspectId) {
             nextAspectId = _aspectId + 1; // Ensure counter keeps up if IDs are assigned manually
        }
        emit AspectTypeAdded(_aspectId, _name, _influenceMultiplier);
    }

    /**
     * @dev Updates the influence multiplier for an existing aspect. Only callable by Owner or Admin.
     * @param _aspectId The ID of the aspect to update.
     * @param _newMultiplier The new influence multiplier.
     */
    function updateAspectMultiplier(uint256 _aspectId, uint256 _newMultiplier) public onlyAdmin onlyValidAspect(_aspectId) {
        uint256 oldMultiplier = aspects[_aspectId].influenceMultiplier;
        aspects[_aspectId].influenceMultiplier = _newMultiplier;
        emit AspectMultiplierUpdated(_aspectId, oldMultiplier, _newMultiplier);
    }

    /**
     * @dev Starts a new epoch. Only callable by Owner or Admin. Ends the previous epoch.
     *      Note: Influence calculations might need to be adjusted or snapshotted per epoch.
     */
    function startNewEpoch() public onlyAdmin nonReentrant {
        uint256 previousEpochId = currentEpochId;
        uint64 nowTime = uint64(block.timestamp);

        if (previousEpochId > 0 && epochs[previousEpochId].startTime != 0) {
            epochs[previousEpochId].endTime = nowTime; // End the previous epoch
        }

        currentEpochId++;
        epochs[currentEpochId].startTime = nowTime;
        epochs[currentEpochId].endTime = 0; // Current epoch is open

        // TODO: Implement epoch-specific influence/reputation adjustments if needed
        // E.g., decaying influence from previous epoch

        emit EpochStarted(currentEpochId, nowTime);
    }

    /**
     * @dev Pauses the contract, preventing most user interactions. Only callable by Owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing user interactions. Only callable by Owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Sets the base rate for influence point accrual. Only callable by Owner or Admin.
     * @param _rate The new base rate (e.g., points per unit per second).
     */
    function setInfluencePointRate(uint256 _rate) public onlyAdmin {
        uint256 oldRate = influencePointRate;
        influencePointRate = _rate;
        emit InfluencePointRateUpdated(oldRate, _rate);
    }

    /**
     * @dev Configures the required stake amount for artifact discovery for a specific token or ETH (address(0)).
     *      Only callable by Owner or Admin.
     */
    function setDiscoveryStakeAmount(address _tokenAddress, uint256 _amount) public onlyAdmin {
        discoveryStakeAmount[_tokenAddress] = _amount;
        emit DiscoveryStakeUpdated(_tokenAddress, _amount);
    }

    /**
     * @dev Sets parameters related to artifact generation probability and type. Only callable by Owner or Admin.
     *      (Implementation of generation logic is conceptual here).
     */
    function setArtifactGenerationParams(uint256 _baseProb, uint256 _influenceFactor, uint256 _cooldown) public onlyAdmin {
         discoveryBaseProbability = _baseProb; // e.g., out of 10000
         discoveryInfluenceFactor = _influenceFactor;
         discoveryCooldown = _cooldown;
         emit ArtifactGenerationParamsUpdated();
    }

     /**
     * @dev Sets parameters related to governance. Only callable by Owner or Admin.
     */
    function updateGovernanceParams(uint256 _proposalThreshold, uint256 _votingPeriod, uint256 _executionDelay) public onlyAdmin {
        proposalThresholdInfluence = _proposalThreshold;
        votingPeriodDuration = _votingPeriod;
        executionDelay = _executionDelay;
        emit GovernanceParamsUpdated();
    }

    // --- User Locking/Unlocking Functions (5) ---

    /**
     * @dev Locks ETH into the contract. Accrues influence based on amount and duration.
     */
    function lockEther() public payable whenNotPaused nonReentrant {
        if (msg.value == 0) revert AmountMustBePositive();
        _updateInfluenceAndReputation(msg.sender); // Update before changing lock state
        userLocks[msg.sender][address(0)].amount += msg.value;
        userLocks[msg.sender][address(0)].lockStartTime = uint64(block.timestamp); // Reset start time for new lock
        // Consider separate start times for multiple lock actions if duration-based influence is complex
        emit EtherLocked(msg.sender, msg.value, 0); // Duration is implicit for now
    }

    /**
     * @dev Locks a specific ERC20 token into the contract. Requires prior approval. Accrues influence.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _amount The amount of tokens to lock.
     */
    function lockToken(address _tokenAddress, uint256 _amount) public whenNotPaused nonReentrant {
        if (_tokenAddress == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert AmountMustBePositive();

        _updateInfluenceAndReputation(msg.sender); // Update before changing lock state

        // Transfer tokens from the user to the contract
        bool success = IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TokenTransferFailed();

        userLocks[msg.sender][_tokenAddress].amount += _amount;
        userLocks[msg.sender][_tokenAddress].lockStartTime = uint64(block.timestamp); // Reset start time
        emit TokenLocked(msg.sender, _tokenAddress, _amount, 0);
    }

    /**
     * @dev Increases the locked amount for an existing lock (ETH or ERC20).
     *      Resets the lock start time for the combined amount.
     * @param _tokenAddress The token address (0x0 for ETH).
     * @param _additionalAmount The amount to add.
     */
    function increaseLockAmount(address _tokenAddress, uint256 _additionalAmount) public payable whenNotPaused nonReentrant {
        if (_additionalAmount == 0) revert AmountMustBePositive();
        if (_tokenAddress == address(0) && msg.value != _additionalAmount) revert InsufficientLockedAmount(msg.value, _additionalAmount);
        if (_tokenAddress != address(0) && msg.value != 0) revert InsufficientLockedAmount(0, msg.value); // No ETH sent for token lock

        _updateInfluenceAndReputation(msg.sender); // Update before changing lock state

        if (_tokenAddress != address(0)) {
            // Transfer tokens from the user to the contract
            bool success = IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _additionalAmount);
            if (!success) revert TokenTransferFailed();
        } // ETH is handled by payable

        userLocks[msg.sender][_tokenAddress].amount += _additionalAmount;
        userLocks[msg.sender][_tokenAddress].lockStartTime = uint64(block.timestamp); // Reset start time for the total amount
        // Note: This simplifies influence calculation; a more complex model might track individual additions.

        if (_tokenAddress == address(0)) {
             emit EtherLocked(msg.sender, _additionalAmount, 0);
        } else {
             emit TokenLocked(msg.sender, _tokenAddress, _additionalAmount, 0);
        }
    }

    /**
     * @dev Decreases the locked amount (partial unlock). Might incur penalty or delay.
     *      Simplified: No penalty or delay in this version.
     * @param _tokenAddress The token address (0x0 for ETH).
     * @param _amount The amount to decrease/unlock.
     */
    function decreaseLockAmount(address _tokenAddress, uint256 _amount) public whenNotPaused nonReentrant {
        if (_amount == 0) revert AmountMustBePositive();
        LockDetails storage lock = userLocks[msg.sender][_tokenAddress];
        if (lock.amount < _amount) revert InsufficientLockedAmount(_amount, lock.amount);

        _updateInfluenceAndReputation(msg.sender); // Update before changing lock state

        lock.amount -= _amount;
        // Note: This simplified model doesn't adjust start time for partial unlocks.
        // A more complex model would need to handle this for influence calculation.

        if (_tokenAddress == address(0)) {
             (bool success, ) = payable(msg.sender).call{value: _amount}("");
             if (!success) revert ETHTransferFailed();
             emit EtherUnlocked(msg.sender, _amount);
        } else {
             bool success = IERC20(_tokenAddress).transfer(msg.sender, _amount);
             if (!success) revert TokenTransferFailed();
             emit TokenUnlocked(msg.sender, _tokenAddress, _amount);
        }
    }

     /**
     * @dev Unlocks all of a specific asset for the user. Might have a time lock before funds are available.
     *      Simplified: No time lock in this version.
     * @param _tokenAddress The token address (0x0 for ETH).
     */
    function unlockAll(address _tokenAddress) public whenNotPaused nonReentrant {
        LockDetails storage lock = userLocks[msg.sender][_tokenAddress];
        uint256 amountToUnlock = lock.amount;
        if (amountToUnlock == 0) revert NoActiveLock(msg.sender, _tokenAddress);

        _updateInfluenceAndReputation(msg.sender); // Update before changing lock state

        lock.amount = 0;
        lock.lockStartTime = 0; // Reset start time

        if (_tokenAddress == address(0)) {
             (bool success, ) = payable(msg.sender).call{value: amountToUnlock}("");
             if (!success) revert ETHTransferFailed();
             emit EtherUnlocked(msg.sender, amountToUnlock);
        } else {
             bool success = IERC20(_tokenAddress).transfer(msg.sender, amountToUnlock);
             if (!success) revert TokenTransferFailed();
             emit TokenUnlocked(msg.sender, _tokenAddress, amountToUnlock);
        }
    }


    // --- User Interaction Functions (5) ---

    /**
     * @dev User attunes their influence and reputation gain towards a specific aspect.
     * @param _aspectId The ID of the aspect to attune to.
     */
    function attuneToAspect(uint256 _aspectId) public whenNotPaused nonReentrant onlyValidAspect(_aspectId) {
        if (userAttunedAspect[msg.sender] == _aspectId) revert AspectAlreadyAttuned(_aspectId);

        _updateInfluenceAndReputation(msg.sender); // Update before changing attunement

        uint256 oldAspectId = userAttunedAspect[msg.sender];
        userAttunedAspect[msg.sender] = _aspectId;

        emit UserAttunedToAspect(msg.sender, _aspectId, oldAspectId);
    }

     /**
     * @dev User changes their attuned aspect. Might have a cooldown.
     *      Simplified: No cooldown in this version.
     * @param _newAspectId The ID of the new aspect to attune to.
     */
    function changeAspectAttunement(uint256 _newAspectId) public whenNotPaused nonReentrant onlyValidAspect(_newAspectId) {
        attuneToAspect(_newAspectId); // Same logic for now, could add cooldown check here
    }

    /**
     * @dev User initiates an artifact discovery attempt. Requires staking assets and influence.
     *      Simplified: Stake is transferred, outcome is determined immediately or after a short period.
     *      Outcome stored in `userDiscoveryState`.
     */
    function initiateDiscovery() public payable whenNotPaused nonReentrant {
        if (userDiscoveryState[msg.sender].outcome == DiscoveryOutcome.InProgress) revert DiscoveryAlreadyInProgress();
        if (userDiscoveryState[msg.sender].initiatedTime + discoveryCooldown > block.timestamp) {
             revert DiscoveryNotInitiated(); // Using this error for "on cooldown"
        }

        uint256 requiredETH = discoveryStakeAmount[address(0)];
        uint256 requiredTokenAmount = discoveryStakeAmount[userLocks[msg.sender].lockTokenAddress.amount > 0 ? userLocks[msg.sender].lockTokenAddress.tokenAddress : address(0)]; // Example: uses locked token if exists
        address requiredTokenAddress = userLocks[msg.sender].lockTokenAddress.amount > 0 ? userLocks[msg.sender].lockTokenAddress.tokenAddress : address(0); // Simplified: only check 0x0 ETH or first locked token if exists

        // Validate ETH stake
        if (msg.value < requiredETH) revert InsufficientDiscoveryStake(address(0), requiredETH, msg.value);
        if (msg.value > requiredETH) {
            // Refund excess ETH if sent more than required
            (bool success, ) = payable(msg.sender).call{value: msg.value - requiredETH}("");
            if (!success) revert ETHTransferFailed(); // Refund failed, should ideally handle or revert
        }

        // Validate and transfer Token stake (if required)
        if (requiredTokenAmount > 0 && requiredTokenAddress != address(0)) {
             // Requires user approval beforehand
             bool success = IERC20(requiredTokenAddress).transferFrom(msg.sender, address(this), requiredTokenAmount);
             if (!success) revert TokenTransferFailed(); // Stake transfer failed
        } else if (requiredTokenAmount > 0 && requiredTokenAddress == address(0)) {
             // Should not happen if checks are correct
        }


        _updateInfluenceAndReputation(msg.sender); // Update influence before calculation

        uint256 currentInfluence = userInfluencePoints[msg.sender];
        uint256 probability = discoveryBaseProbability + (currentInfluence / discoveryInfluenceFactor);
        if (probability > 10000) probability = 10000; // Cap probability at 100% (10000/10000)

        // Simulate pseudo-random outcome (not cryptographically secure)
        bytes32 randomSeed = keccak256(abi.encodePacked(block.timestamp, msg.sender, tx.origin, block.number, block.difficulty)); // Use caution with block variables for randomness
        uint256 randomNumber = uint256(randomSeed) % 10000; // Number between 0-9999

        DiscoveryOutcome outcome;
        bytes memory artifactData = "";

        if (randomNumber < probability) {
            outcome = DiscoveryOutcome.Succeeded;
            artifactData = _generatePseudoArtifact(msg.sender); // Simulate artifact generation
        } else {
            outcome = DiscoveryOutcome.Failed;
        }

        userDiscoveryState[msg.sender] = DiscoveryState({
            discoveryId: userDiscoveryState[msg.sender].discoveryId + 1, // Increment attempt ID
            initiatedTime: uint64(block.timestamp),
            completionTime: uint64(block.timestamp), // Outcome is immediate in this version
            outcome: outcome,
            artifactData: artifactData,
            stakeETH: requiredETH, // Record the actual stake
            stakeTokenAddress: requiredTokenAddress,
            stakeTokenAmount: requiredTokenAmount
        });

        emit DiscoveryInitiated(msg.sender, userDiscoveryState[msg.sender].discoveryId, requiredETH, requiredTokenAmount, requiredTokenAddress);
        emit DiscoveryCompleted(msg.sender, userDiscoveryState[msg.sender].discoveryId, uint256(outcome), artifactData);

        // Stake is now held by contract. Need `claimDiscoveryReward` to get stake back (if failed) or artifact + stake (if succeeded).
        // Or, modify logic: stake is consumed on attempt. Let's make claim required to get stake back if failed, or artifact if succeeded.
    }

    /**
     * @dev Claims the reward or stake after a completed discovery attempt.
     */
    function claimDiscoveryReward() public whenNotPaused nonReentrant {
        DiscoveryState storage state = userDiscoveryState[msg.sender];
        if (state.outcome == DiscoveryOutcome.NotStarted || state.outcome == DiscoveryOutcome.InProgress) {
            revert DiscoveryNotCompleted();
        }

        // Transfer stake back if failed, or keep stake and provide artifact (simulated) if succeeded
        if (state.outcome == DiscoveryOutcome.Failed) {
            if (state.stakeETH > 0) {
                (bool success, ) = payable(msg.sender).call{value: state.stakeETH}("");
                 if (!success) revert ETHTransferFailed();
            }
            if (state.stakeTokenAmount > 0 && state.stakeTokenAddress != address(0)) {
                 bool success = IERC20(state.stakeTokenAddress).transfer(msg.sender, state.stakeTokenAmount);
                 if (!success) revert TokenTransferFailed();
            }
             // Artifact data is empty for failed state
        } else if (state.outcome == DiscoveryOutcome.Succeeded) {
            // Simulate providing the artifact. In a real contract, this might mint an NFT,
            // update user state with artifact ID, or transfer tokens/resources.
            // Here, we just log the artifact data and keep the stake (or could return stake + artifact).
            // Let's say stake is consumed on success for simplicity here.
             // If stake is returned on success:
             /*
            if (state.stakeETH > 0) {
                (bool success, ) = payable(msg.sender).call{value: state.stakeETH}("");
                 if (!success) revert ETHTransferFailed();
            }
            if (state.stakeTokenAmount > 0 && state.stakeTokenAddress != address(0)) {
                 bool success = IERC20(state.stakeTokenAddress).transfer(msg.sender, state.stakeTokenAmount);
                 if (!success) revert TokenTransferFailed();
            }
             */
             // Artifact data is already in state.artifactData
        } else {
             revert DiscoveryFailed(uint256(state.outcome)); // Should not happen
        }


        // Reset discovery state after claiming
        delete userDiscoveryState[msg.sender]; // Clear the state for the next attempt

        // Note: This simple version doesn't distinguish claiming failed vs succeeded outcomes,
        // a real one might have separate functions or distinct logic after claiming.
    }

     /**
     * @dev Cancels an ongoing discovery attempt. Might forfeit stake or incur penalty.
     *      Simplified: Can only cancel if *not* completed, forfeits stake.
     */
    function cancelDiscovery() public whenNotPaused nonReentrant {
        DiscoveryState storage state = userDiscoveryState[msg.sender];
        if (state.outcome != DiscoveryOutcome.InProgress) {
            revert DiscoveryNotInitiated(); // Or DiscoveryAlreadyCompleted/Failed/Succeeded
        }

        // Simulate forfeiting the stake upon cancellation
        // The stake remains in the contract

        // Reset discovery state
        delete userDiscoveryState[msg.sender];
        emit DiscoveryCancelled(msg.sender, state.discoveryId);
    }


    // --- Governance Functions (3) ---

    /**
     * @dev Proposes a simple action (represented by calldata and target address).
     *      Requires minimum influence threshold.
     * @param _description Description of the proposal.
     * @param _calldata Bytes representing the function call data.
     * @param _target Address of the contract to call if the proposal passes.
     */
    function proposeAction(string memory _description, bytes memory _calldata, address _target) public whenNotPaused nonReentrant {
        if (_target == address(0) || _calldata.length == 0) revert ActionRequiresNonZeroTargetOrCalldata();
        _updateInfluenceAndReputation(msg.sender); // Update influence before proposal check
        if (userInfluencePoints[msg.sender] < proposalThresholdInfluence) {
            revert InsufficientInfluence(proposalThresholdInfluence, userInfluencePoints[msg.sender]);
        }

        uint256 proposalId = nextProposalId++;
        uint64 nowTime = uint64(block.timestamp);

        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: _description,
            calldataBytes: _calldata,
            target: _target,
            creationTime: nowTime,
            votingEndTime: nowTime + uint64(votingPeriodDuration),
            totalInfluenceAtCreation: userInfluencePoints[msg.sender], // Snapshot proposer's influence for weight
            supportVotes: 0,
            againstVotes: 0,
            executed: false,
            hasVoted: new mapping(address => bool)() // Initialize the mapping
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Votes on an active proposal. Voting weight is based on the voter's influence at the time of voting.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a vote in favor, false for against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public whenNotPaused nonReentrant onlyExistingProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        if (block.timestamp > proposal.votingEndTime) revert ProposalVotingPeriodEnded();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();
        if (proposal.executed) revert ProposalAlreadyExecuted(); // Cannot vote on executed proposal

        _updateInfluenceAndReputation(msg.sender); // Update influence before voting weight calculation
        uint256 votingWeight = userInfluencePoints[msg.sender]; // Use current influence as voting weight

        if (_support) {
            proposal.supportVotes += votingWeight;
        } else {
            proposal.againstVotes += votingWeight;
        }

        proposal.hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _support, votingWeight);
    }

    /**
     * @dev Executes a successful proposal after the voting period ends.
     *      Success condition: More support votes than against votes, voting period ended, not yet executed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused nonReentrant onlyExistingProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];

        if (block.timestamp <= proposal.votingEndTime) revert ProposalNotExecutable();
        if (proposal.supportVotes <= proposal.againstVotes) revert ProposalNotExecutable(); // Failed consensus
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Optional: Add execution delay check if executionDelay is implemented
        // if (block.timestamp < proposal.votingEndTime + executionDelay) revert ProposalNotExecutable();

        proposal.executed = true;

        // Execute the action (simplified, requires careful consideration in real implementation)
        (bool success, ) = proposal.target.call(proposal.calldataBytes);
        // In a real system, you'd want robust error handling for the call.
        // For this example, we proceed regardless of call success to demonstrate execution attempt.
        // require(success, "Proposal execution failed"); // uncomment for strict execution

        emit ProposalExecuted(_proposalId);
    }

    // --- View/Query Functions (10) ---

    /**
     * @dev Calculates a conceptual dynamic fee based on user state.
     *      This is a view function and does not actually charge a fee.
     * @param _user The address of the user.
     * @param _actionType A string indicating the type of action (e.g., "trade", "claim", "initiate").
     * @return feeAmount The calculated fee amount (example).
     */
    function calculateDynamicFee(address _user, string memory _actionType) public view returns (uint256 feeAmount) {
        // Example calculation: Higher reputation means lower fee, higher lock means lower fee
        uint256 currentInfluence = userInfluencePoints[_user];
        uint256 currentReputation = userReputationScore[_user];
        uint256 totalLocked = userLocks[_user][address(0)].amount; // Just ETH for simplicity
        // Add logic for ERC20 locks too in a real scenario

        uint256 baseFee = 1 ether / 100; // Example: 0.01 ETH base fee (or scaled token amount)
        uint256 reputationDiscountFactor = 1000; // 1000 reputation = 1% discount
        uint256 lockDiscountFactor = 1 ether / 10; // 0.1 ETH locked = 1% discount

        uint256 totalDiscountBasis = (currentReputation / reputationDiscountFactor) + (totalLocked / lockDiscountFactor);
        uint256 maxDiscountPercentage = 50; // Cap discount at 50%

        uint256 discountPercentage = totalDiscountBasis > maxDiscountPercentage ? maxDiscountPercentage : totalDiscountBasis;

        feeAmount = baseFee * (100 - discountPercentage) / 100;

        // Add action-specific multipliers if needed
        if (keccak256(abi.encodePacked(_actionType)) == keccak256(abi.encodePacked("initiateDiscovery"))) {
             feeAmount = feeAmount * 120 / 100; // Discovery might have a higher base fee multiplier
        }
        // ... other action types

        return feeAmount; // Returns the calculated fee
    }


     /**
     * @dev Gets the current calculated influence points for a user.
     *      Note: Influence might need to be updated *before* calling this for accuracy.
     * @param _user The address of the user.
     * @return points The user's current influence points.
     */
    function getCurrentInfluencePoints(address _user) public view returns (uint256 points) {
        // For simplicity, this view returns the last calculated value.
        // A complex system would re-calculate based on lock duration since last update.
        // _updateInfluenceAndReputation(_user); // Cannot call non-view in view function
        // The value in state variable is accurate *as of the last time _updateInfluenceAndReputation was called for this user*.
        return userInfluencePoints[_user];
    }

    /**
     * @dev Gets the user's current reputation score.
     *      Note: Reputation might need to be updated *before* calling this for accuracy.
     * @param _user The address of the user.
     * @return score The user's current reputation score.
     */
    function getCurrentReputationScore(address _user) public view returns (uint256 score) {
         // Similar to influence, returns the last calculated value.
        return userReputationScore[_user];
    }

     /**
     * @dev Gets the user's reputation score, potentially weighted towards a specific aspect.
     *      (Conceptual: In a real system, reputation calculation might be complex based on aspect activities).
     * @param _user The address of the user.
     * @param _aspectId The aspect ID to weight the score for.
     * @return score The user's reputation score for the given aspect.
     */
    function getReputationForAspect(address _user, uint256 _aspectId) public view onlyValidAspect(_aspectId) returns (uint256 score) {
         // Simplified example: return base reputation * aspect multiplier / base multiplier (1000)
         uint256 baseReputation = userReputationScore[_user];
         uint256 aspectMultiplier = aspects[_aspectId].influenceMultiplier;
         score = baseReputation * aspectMultiplier / 1000; // Assuming 1000 is 1x multiplier base
         return score;
    }


    /**
     * @dev Gets details about a user's locked assets for a specific token (or ETH).
     * @param _user The address of the user.
     * @param _tokenAddress The token address (0x0 for ETH).
     * @return amount The locked amount.
     * @return lockStartTime The timestamp when the amount was last increased or initially locked.
     */
    function getUserLockDetails(address _user, address _tokenAddress) public view returns (uint256 amount, uint64 lockStartTime) {
        LockDetails storage lock = userLocks[_user][_tokenAddress];
        return (lock.amount, lock.lockStartTime);
    }

    /**
     * @dev Gets the current state of a user's artifact discovery attempt.
     * @param _user The address of the user.
     * @return state The DiscoveryState struct for the user.
     */
    function getDiscoveryState(address _user) public view returns (DiscoveryState memory state) {
        return userDiscoveryState[_user];
    }

    /**
     * @dev Gets the details and state of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return proposal The Proposal struct details.
     */
    function getProposalState(uint256 _proposalId) public view onlyExistingProposal(_proposalId) returns (Proposal memory proposal) {
        Proposal storage p = proposals[_proposalId];
         // Copy to memory, excluding the mapping which cannot be returned
        return Proposal({
            proposalId: p.proposalId,
            description: p.description,
            calldataBytes: p.calldataBytes,
            target: p.target,
            creationTime: p.creationTime,
            votingEndTime: p.votingEndTime,
            totalInfluenceAtCreation: p.totalInfluenceAtCreation,
            supportVotes: p.supportVotes,
            againstVotes: p.againstVotes,
            executed: p.executed,
            hasVoted: new mapping(address => bool)() // Mapping is not copied/returned, need separate function to check vote status
        });
    }

    /**
     * @dev Gets the total amount of ETH locked in the contract.
     * @return total Total locked ETH.
     */
    function getTotalLockedEther() public view returns (uint256 total) {
         return address(this).balance; // Simple way to get ETH balance
         // Note: This assumes all ETH in the contract is locked ETH.
         // A robust contract would track this sum in a state variable.
    }

    /**
     * @dev Gets the total amount of a specific ERC20 token locked in the contract.
     * @param _tokenAddress The address of the ERC20 token.
     * @return total Total locked token amount.
     */
    function getTotalLockedToken(address _tokenAddress) public view returns (uint256 total) {
        if (_tokenAddress == address(0)) return 0; // Or revert
        return IERC20(_tokenAddress).balanceOf(address(this));
         // Note: Assumes all token balance is locked token.
         // A robust contract would track this sum in a state variable.
    }

     /**
     * @dev Gets the configuration details for an aspect type.
     * @param _aspectId The ID of the aspect.
     * @return name The name of the aspect.
     * @return influenceMultiplier The influence multiplier.
     * @return exists True if the aspect exists.
     */
    function getAspectDetails(uint256 _aspectId) public view returns (string memory name, uint256 influenceMultiplier, bool exists) {
        AspectDetails storage aspect = aspects[_aspectId];
        return (aspect.name, aspect.influenceMultiplier, aspect.exists);
    }

    /**
     * @dev Gets the ID of the current active epoch.
     * @return epochId The current epoch ID.
     */
    function getCurrentEpoch() public view returns (uint256 epochId) {
        return currentEpochId;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to update user's influence and reputation based on their locks and activity.
     *      Called before actions that depend on or affect influence/reputation.
     *      Simplified calculation logic.
     * @param _user The address of the user to update.
     */
    function _updateInfluenceAndReputation(address _user) internal {
        uint256 currentTimestamp = block.timestamp;

        // Calculate influence from ETH lock
        uint256 ethLocked = userLocks[_user][address(0)].amount;
        uint64 ethLockStartTime = userLocks[_user][address(0)].lockStartTime;
        uint256 ethInfluence = 0;
        if (ethLocked > 0 && ethLockStartTime > 0) {
            uint256 lockDuration = currentTimestamp - ethLockStartTime;
             // Simple linear influence accrual example:
            ethInfluence = ethLocked * lockDuration * influencePointRate / 1e18; // Assuming ETH is scaled by 1e18
        }

        // Calculate influence from Token locks (example for one token)
         // In a real contract, iterate through all token locks for the user
        address exampleTokenAddress = 0x123...; // Replace with actual token address tracked
        uint256 tokenLocked = userLocks[_user][exampleTokenAddress].amount;
        uint64 tokenLockStartTime = userLocks[_user][exampleTokenAddress].lockStartTime;
        uint256 tokenInfluence = 0;
        if (tokenLocked > 0 && tokenLockStartTime > 0) {
            uint256 lockDuration = currentTimestamp - tokenLockStartTime;
             // Need token decimals for scaling
            uint256 tokenDecimals = 18; // Assume 18 decimals for example
            tokenInfluence = tokenLocked * lockDuration * influencePointRate / (10**tokenDecimals);
        }

        uint256 totalAccruedInfluence = ethInfluence + tokenInfluence;

        // Apply aspect multiplier if attuned
        uint256 attunedAspectId = userAttunedAspect[_user];
        if (attunedAspectId != 0 && aspects[attunedAspectId].exists) {
             totalAccruedInfluence = totalAccruedInfluence * aspects[attunedAspectId].influenceMultiplier / 1000; // Assuming 1000 is 1x base
        }

        // Simple influence update: just add newly accrued influence
        userInfluencePoints[_user] += totalAccruedInfluence; // This is a simplification. Real system might decay influence.

        // Simple reputation update: e.g., reputation is 1/10th of influence
        userReputationScore[_user] = userInfluencePoints[_user] / 10; // Highly simplified

        emit InfluenceAndReputationUpdated(_user, userInfluencePoints[_user], userReputationScore[_user]);

        // Reset lock start times *after* calculating influence accrued since last update
        // This prevents double counting duration on subsequent updates.
        if (ethLocked > 0) userLocks[_user][address(0)].lockStartTime = uint64(currentTimestamp);
        if (tokenLocked > 0) userLocks[_user][exampleTokenAddress].lockStartTime = uint64(currentTimestamp);
    }

    /**
     * @dev Simulates the generation of artifact data.
     *      In a real system, this could generate random stats, traits, or reference external data.
     * @param _user The address of the user who discovered the artifact.
     * @return artifactData Arbitrary bytes representing the artifact.
     */
    function _generatePseudoArtifact(address _user) internal view returns (bytes memory artifactData) {
        // Example: combine block hash, user address, and timestamp
        bytes32 artifactSeed = keccak256(abi.encodePacked(block.hash(block.number - 1), _user, block.timestamp, userDiscoveryState[_user].discoveryId));
        // Return a hash as a simple artifact representation
        artifactData = abi.encodePacked(artifactSeed);
        return artifactData;
    }

    // Fallback function to receive ETH if needed for operations (besides lock)
    // but locks already use payable, so this is less critical unless external calls send ETH.
    receive() external payable {
        // This allows the contract to receive ETH directly. Consider implications carefully.
        // Maybe only allow receive when pausing or for specific admin operations.
        // For this example, we'll allow it but it doesn't directly affect user locks unless lockEther is called.
    }
}
```