Okay, here is a Solidity smart contract concept called `QuantumLeapFinance`. It combines several advanced concepts:

1.  **Time-Locked State Transitions (Dimensions):** Users stake assets into different "dimensions," each with varying yield rates and lockup periods.
2.  **Dynamic Parameters (Epochs & Oracle):** Key contract parameters (yields, leap chances, lockups) change over time based on defined epochs and potentially external data via an oracle.
3.  **Probabilistic State Change (Quantum Leap):** Users can attempt a "Quantum Leap" to move to a different dimension. This involves a pseudo-random outcome based on current state and contract parameters.
4.  **Soulbound Access Token (`QuantumKey`):** A non-transferable ERC721-like token (`QuantumKey`) is required to access certain dimensions or trigger specific actions (like a Leap).
5.  **Time-Weighted Yield & Penalties:** Yield accrues based on time spent in a dimension and its specific multiplier. Early unstaking incurs penalties.

This contract is *not* a simple stake/unstake. It introduces strategic elements based on time, state, and chance, managed by dynamic rules.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumLeapFinance
 * @author YourNameHere (or a pseudonym)
 * @notice A complex financial contract involving dynamic state transitions (Dimensions),
 *         time-locked staking, probabilistic 'Quantum Leaps', a Soulbound Access Key NFT,
 *         and parameters that evolve based on time (Epochs) and potentially external data (Oracle).
 *
 * Outline:
 * 1. Contract Description and Core Concepts
 * 2. Imports (Interfaces for ERC20, ERC721)
 * 3. Error Definitions
 * 4. Events
 * 5. State Variables
 * 6. Structs (UserPosition, DimensionConfig)
 * 7. Modifiers (Owner, Pausable)
 * 8. Constructor
 * 9. Admin/Setup Functions (Owner only)
 * 10. User Interaction Functions (Staking, Unstaking, Claiming)
 * 11. Dimension & Leap Functions (Entering dimensions, Attempting leaps)
 * 12. QuantumKey NFT Functions (Minting, Burning, Upgrading - interacts with external contract)
 * 13. Parameter Management Functions (Epoch updates, Oracle integration trigger)
 * 14. Query Functions (View contract/user state)
 * 15. Internal Helper Functions
 *
 * Function Summary:
 * - constructor: Initializes the contract with token addresses and base parameters.
 * - setStakingToken: Sets the ERC20 token accepted for staking (Admin).
 * - setQuantumKeyNFTContract: Sets the address of the QuantumKey ERC721 contract (Admin).
 * - setOracleAddress: Sets the address of the price oracle for external data feeds (Admin).
 * - addDimension: Adds a new staking dimension with its properties (Admin).
 * - updateDimensionConfig: Updates parameters for an existing dimension (Admin).
 * - withdrawFeesAndPenalties: Allows the owner to withdraw accumulated contract balance from penalties etc (Admin).
 * - pauseContract: Pauses key contract functions in emergency (Admin).
 * - unpauseContract: Unpauses the contract (Admin).
 * - stake: Stakes ERC20 tokens into a specified dimension. Requires approval first.
 * - unstake: Withdraws staked tokens. Subject to lockup periods and potential penalties/bonuses.
 * - claimYield: Claims accumulated yield for the user's current position.
 * - enterDimension: Moves a user's existing stake from their current dimension to another. May have requirements (e.g., Key NFT).
 * - attemptQuantumLeap: Triggers an attempt to randomly move to a different dimension based on probability. Consumes 'leap fuel' or has a cooldown.
 * - mintQuantumKey: Allows users to mint a Soulbound QuantumKey NFT under specific conditions.
 * - burnQuantumKey: Allows users to burn their Key NFT for a potential benefit (e.g., reduced penalty).
 * - upgradeQuantumKey: Allows upgrading a Key NFT level based on criteria (e.g., time staked, amount staked).
 * - triggerEpochUpdate: External call (e.g., by a Keeper bot) to advance the contract's internal epoch and update parameters.
 * - updateParametersFromOracle: External call (e.g., by Keeper) to fetch data from oracle and update parameters based on it.
 * - getUserPosition: Returns the staking details for a specific user.
 * - getDimensionConfig: Returns the configuration parameters for a specific dimension ID.
 * - getTotalStaked: Returns the total amount of the staking token staked in the contract.
 * - getCurrentEpoch: Returns the current active epoch number.
 * - calculatePendingYield: Calculates the estimated yield a user is eligible to claim *at the current time*.
 * - getDimensionList: Returns a list of all available dimension IDs.
 * - getQuantumKeyDetails: Returns details about a user's QuantumKey NFT (if they have one).
 * - calculateUnstakePenalty: Calculates the penalty amount for early unstaking from a specific dimension.
 * - getMinimumStakeAmount: Returns the minimum required amount to stake initially.
 * - getLeapCooldownEndTime: Returns the timestamp when a user can attempt the next leap.
 * - getLeapAttemptCost: Returns the cost (in staking tokens or other fuel) for attempting a leap.
 */

// Dummy interfaces - replace with actual implementations or standard interfaces
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

// Assuming QuantumKey is a custom Soulbound (non-transferable) ERC721 variant
interface IQuantumKeyNFT {
    function mint(address to, uint256 keyId, uint256 level) external;
    function burn(uint256 keyId) external;
    function exists(uint256 keyId) external view returns (bool);
    function ownerOf(uint256 keyId) external view returns (address); // ownerOf should revert if soulbound
    function getTokenIdByAddress(address owner) external view returns(uint256); // Added helper for Soulbound lookup
    function getKeyLevel(uint256 keyId) external view returns(uint256);
    // Note: Standard transfer functions would be disabled or overridden in a Soulbound implementation
}

// Dummy Oracle Interface - replace with Chainlink or similar
interface IOracle {
    function getValue(string calldata key) external view returns (uint256);
    function getLatestData(string calldata key) external view returns (uint256 value, uint256 timestamp);
}

// Custom Errors (Optional, but good practice in >=0.8.4)
error NotOwner();
error Paused();
error NotPaused();
error ZeroAddress();
error StakingTokenNotSet();
error InvalidAmount();
error InsufficientAllowance();
error InsufficientBalance();
error InvalidDimension();
error NotStakingInDimension();
error DimensionLocked();
error LockupPeriodActive(uint256 unlockTime);
error CannotUnstakeZeroAmount();
error YieldCalculationError(); // Generic error for yield
error KeyNFTContractNotSet();
error KeyAlreadyExists();
error KeyNotFound();
error KeyUpgradeConditionsNotMet();
error NotEnoughStakedForMint();
error StakeDurationTooShortForMint();
error QuantumLeapCooldownActive(uint256 cooldownEnd);
error OracleNotSet();
error EpochUpdateCooldownActive(uint256 nextUpdateTime);


contract QuantumLeapFinance {
    // --- State Variables ---
    address public owner;
    bool public paused;

    IERC20 public stakingToken;
    IQuantumKeyNFT public quantumKeyNFT;
    IOracle public oracle; // Address of an oracle contract

    uint256 public totalStaked;

    // User position data: address => UserPosition
    mapping(address => UserPosition) public userPositions;

    // Dimension configurations: dimensionId => DimensionConfig
    mapping(uint256 => DimensionConfig) public dimensionConfigs;
    uint256[] public dimensionIds; // Array to list available dimension IDs

    uint256 public currentEpoch = 1;
    uint256 public epochDuration = 7 days; // How long an epoch lasts
    uint256 public lastEpochUpdateTime;

    uint256 public minimumStakeAmount = 1 ether; // Minimum stake for initial entry
    uint256 public constant SECONDS_PER_YEAR = 31536000; // Approx. seconds in a year

    // Quantum Leap specific state
    uint256 public leapCooldown = 1 days; // Cooldown between leap attempts per user
    mapping(address => uint256) public lastLeapAttemptTime;
    uint256 public leapAttemptCost = 0.01 ether; // Cost to attempt a leap (in staking token)


    // --- Structs ---

    // Represents a user's staking position
    struct UserPosition {
        uint256 amount;            // Amount staked
        uint256 dimensionId;       // ID of the dimension currently in
        uint256 enterTime;         // Timestamp when entered the current dimension
        uint256 accruedYield;      // Accumulated yield waiting to be claimed
        bool isStaking;            // Flag to indicate if the user has an active stake
    }

    // Configuration for a specific dimension
    struct DimensionConfig {
        uint256 yieldMultiplier;   // Yield rate (e.g., 100 for 1x, 150 for 1.5x)
        uint256 lockupDuration;    // Minimum time tokens must remain in this dimension
        uint256 leapSuccessChance; // Chance of successful leap *from* this dimension (0-100)
        uint256 earlyUnstakePenalty; // Penalty percentage for unstaking before lockup (0-100)
        uint256 requiredKeyLevel;  // Minimum Key NFT level required to enter this dimension (0 for none)
        bool isActive;             // Is this dimension currently active and usable
    }


    // --- Events ---
    event Staked(address indexed user, uint256 amount, uint256 dimensionId, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 dimensionId, uint256 penaltyAmount, uint256 bonusAmount, uint256 timestamp);
    event YieldClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event DimensionEntered(address indexed user, uint256 fromDimensionId, uint256 toDimensionId, uint256 timestamp);
    event QuantumLeapAttempted(address indexed user, uint256 fromDimensionId, uint256 timestamp);
    event QuantumLeapSuccessful(address indexed user, uint256 fromDimensionId, uint256 toDimensionId, uint256 timestamp);
    event ParametersUpdated(uint256 epoch, uint256 timestamp);
    event QuantumKeyMinted(address indexed user, uint256 keyId, uint256 level, uint256 timestamp);
    event QuantumKeyBurned(address indexed user, uint256 keyId, uint256 timestamp);
    event QuantumKeyUpgraded(address indexed user, uint256 keyId, uint256 newLevel, uint256 timestamp);
    event DimensionAdded(uint256 dimensionId, uint256 timestamp);
    event DimensionUpdated(uint256 dimensionId, uint256 timestamp);
    event FeesWithdrawn(address indexed recipient, uint256 amount, uint256 timestamp);
    event Paused(uint256 timestamp);
    event Unpaused(uint256 timestamp);


    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }


    // --- Constructor ---
    constructor(address _stakingToken, address _quantumKeyNFT, address _oracle) {
        if (_stakingToken == address(0)) revert ZeroAddress();
        // KeyNFT and Oracle can be set later, not strictly required at deployment

        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        quantumKeyNFT = IQuantumKeyNFT(_quantumKeyNFT); // Can be address(0) initially
        oracle = IOracle(_oracle); // Can be address(0) initially
        paused = false;
        lastEpochUpdateTime = block.timestamp;

        // Add a default "Base Dimension" (Dimension 0)
        uint256 baseDimensionId = 0;
        dimensionConfigs[baseDimensionId] = DimensionConfig({
            yieldMultiplier: 100, // 1x yield
            lockupDuration: 0,    // No initial lockup
            leapSuccessChance: 0, // Cannot leap *from* the base dimension initially
            earlyUnstakePenalty: 0, // No penalty
            requiredKeyLevel: 0,  // No key required
            isActive: true
        });
        dimensionIds.push(baseDimensionId);
        emit DimensionAdded(baseDimensionId, block.timestamp);
    }


    // --- Admin/Setup Functions ---

    function setStakingToken(address _stakingToken) external onlyOwner {
        if (_stakingToken == address(0)) revert ZeroAddress();
        stakingToken = IERC20(_stakingToken);
    }

    function setQuantumKeyNFTContract(address _quantumKeyNFT) external onlyOwner {
        if (_quantumKeyNFT == address(0)) revert ZeroAddress();
        quantumKeyNFT = IQuantumKeyNFT(_quantumKeyNFT);
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        if (_oracle == address(0)) revert ZeroAddress();
        oracle = IOracle(_oracle);
    }

    function addDimension(
        uint256 _dimensionId,
        uint256 _yieldMultiplier,
        uint256 _lockupDuration,
        uint256 _leapSuccessChance,
        uint256 _earlyUnstakePenalty,
        uint256 _requiredKeyLevel
    ) external onlyOwner {
        require(_dimensionId != 0, "Cannot overwrite base dimension with this function");
        require(dimensionConfigs[_dimensionId].isActive == false, "Dimension ID already exists");
        require(_yieldMultiplier > 0, "Yield multiplier must be positive");
        require(_leapSuccessChance <= 100, "Leap chance must be 0-100");
         require(_earlyUnstakePenalty <= 100, "Penalty must be 0-100");

        dimensionConfigs[_dimensionId] = DimensionConfig({
            yieldMultiplier: _yieldMultiplier,
            lockupDuration: _lockupDuration,
            leapSuccessChance: _leapSuccessChance,
            earlyUnstakePenalty: _earlyUnstakePenalty,
            requiredKeyLevel: _requiredKeyLevel,
            isActive: true
        });
        dimensionIds.push(_dimensionId);
        emit DimensionAdded(_dimensionId, block.timestamp);
    }

    function updateDimensionConfig(
        uint256 _dimensionId,
        uint256 _yieldMultiplier,
        uint256 _lockupDuration,
        uint256 _leapSuccessChance,
        uint256 _earlyUnstakePenalty,
        uint256 _requiredKeyLevel,
        bool _isActive
    ) external onlyOwner {
        require(dimensionConfigs[_dimensionId].isActive == true || _dimensionId == 0, "Dimension ID does not exist"); // Allow updating base dim
        require(_yieldMultiplier > 0, "Yield multiplier must be positive");
        require(_leapSuccessChance <= 100, "Leap chance must be 0-100");
        require(_earlyUnstakePenalty <= 100, "Penalty must be 0-100");

        DimensionConfig storage dim = dimensionConfigs[_dimensionId];
        dim.yieldMultiplier = _yieldMultiplier;
        dim.lockupDuration = _lockupDuration;
        dim.leapSuccessChance = _leapSuccessChance;
        dim.earlyUnstakePenalty = _earlyUnstakePenalty;
        dim.requiredKeyLevel = _requiredKeyLevel;
        dim.isActive = _isActive;

        emit DimensionUpdated(_dimensionId, block.timestamp);
    }

    function withdrawFeesAndPenalties(address _recipient) external onlyOwner {
        if (_recipient == address(0)) revert ZeroAddress();
        uint256 balance = stakingToken.balanceOf(address(this));
        uint256 stakedAmount = totalStaked;
        // The withdrawable amount is the total balance minus the sum of all user stakes.
        // This difference represents accumulated penalties, fees, etc.
        uint256 withdrawable = balance > stakedAmount ? balance - stakedAmount : 0;

        if (withdrawable > 0) {
            stakingToken.transfer(_recipient, withdrawable);
            emit FeesWithdrawn(_recipient, withdrawable, block.timestamp);
        }
    }

    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(block.timestamp);
    }

    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(block.timestamp);
    }


    // --- User Interaction Functions ---

    function stake(uint256 _amount, uint256 _initialDimensionId) external whenNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (address(stakingToken) == address(0)) revert StakingTokenNotSet();
        if (_amount < minimumStakeAmount && !userPositions[msg.sender].isStaking) revert InsufficientAmount(); // Apply min stake only for initial entry

        DimensionConfig storage initialDim = dimensionConfigs[_initialDimensionId];
        if (!initialDim.isActive) revert InvalidDimension();
        if (initialDim.requiredKeyLevel > 0) {
             if (address(quantumKeyNFT) == address(0)) revert KeyNFTContractNotSet();
             uint256 userKeyLevel = getQuantumKeyDetails(msg.sender); // 0 if no key
             if (userKeyLevel < initialDim.requiredKeyLevel) revert KeyUpgradeConditionsNotMet(); // Re-using error for key level req
        }

        // Transfer tokens first (Pull pattern requires approval)
        if (stakingToken.allowance(msg.sender, address(this)) < _amount) revert InsufficientAllowance();
        if (stakingToken.balanceOf(msg.sender) < _amount) revert InsufficientBalance();
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        UserPosition storage pos = userPositions[msg.sender];

        // If user already staking, calculate pending yield before updating position
        if (pos.isStaking) {
           _calculateAndAddYield(msg.sender);
           pos.amount += _amount; // Add new stake to existing amount
           // Dimension doesn't change unless `enterDimension` or `attemptQuantumLeap` is called
           // enterTime remains the same as the *last* dimension entry time
        } else {
            // Initial stake
            pos.amount = _amount;
            pos.dimensionId = _initialDimensionId;
            pos.enterTime = block.timestamp;
            pos.accruedYield = 0;
            pos.isStaking = true;
        }

        totalStaked += _amount;

        emit Staked(msg.sender, _amount, pos.dimensionId, block.timestamp);
    }

    function unstake(uint256 _amount) external whenNotPaused {
        UserPosition storage pos = userPositions[msg.sender];
        if (!pos.isStaking) revert NotStakingInDimension();
        if (_amount == 0) revert CannotUnstakeZeroAmount();
        if (_amount > pos.amount) revert InvalidAmount();

        // Calculate yield before unstaking
        _calculateAndAddYield(msg.sender);

        uint256 amountToUnstake = _amount;
        uint256 penaltyAmount = 0;
        uint256 bonusAmount = 0; // Could add bonuses for long stakes etc.

        DimensionConfig storage currentDim = dimensionConfigs[pos.dimensionId];

        // Check lockup
        uint256 unlockTime = pos.enterTime + currentDim.lockupDuration;
        if (block.timestamp < unlockTime) {
            // Apply penalty for early withdrawal
            penaltyAmount = (amountToUnstake * currentDim.earlyUnstakePenalty) / 100;
            amountToUnstake = amountToUnstake > penaltyAmount ? amountToUnstake - penaltyAmount : 0; // Ensure result is not negative
            // Note: The penalty amount stays in the contract, contributing to fees/penalties pool.
            // Revert if amount becomes 0 after penalty? Or allow partial withdrawal? Let's allow 0 withdrawal if penalty is 100%.
             if (amountToUnstake == 0 && _amount > 0) {
                  // Optionally, revert entirely if penalty is 100% and it's an early exit
                  // revert LockupPeriodActive(unlockTime);
                  // Allowing 0 withdrawal might be confusing, let's revert if penalty eats everything.
                  if (currentDim.earlyUnstakePenalty == 100) revert LockupPeriodActive(unlockTime);
             }
        }

        pos.amount -= _amount; // Deduct original requested amount from stake

        if (pos.amount == 0) {
            // Fully unstaked
            pos.isStaking = false;
            pos.dimensionId = 0; // Reset dimension
            pos.enterTime = 0;
             // Note: accruedYield remains until claimed explicitly, or could be auto-claimed here.
             // Let's leave it to `claimYield` for clarity, though auto-claiming might be better UX.
        }

        totalStaked -= _amount - amountToUnstake; // Subtract original amount MINUS the penalty portion from total staked

        // Transfer the unstaked amount after penalty
        if (amountToUnstake > 0) {
             stakingToken.transfer(msg.sender, amountToUnstake);
        }


        emit Unstaked(msg.sender, _amount, pos.dimensionId, penaltyAmount, bonusAmount, block.timestamp);

        // Optional: If pos.isStaking becomes false, check if any accruedYield is left. If so, maybe auto-claim it?
        // For simplicity, we let the user call claimYield separately.
    }

    function claimYield() external whenNotPaused {
        UserPosition storage pos = userPositions[msg.sender];
        if (!pos.isStaking && pos.accruedYield == 0) {
             // No active stake and no pending yield from previous stakes
             revert YieldCalculationError(); // Use a more specific error if possible
        }

        // Calculate and add yield for the current period first
        _calculateAndAddYield(msg.sender);

        uint256 amountToClaim = pos.accruedYield;
        if (amountToClaim == 0) revert YieldCalculationError(); // No yield to claim

        pos.accruedYield = 0; // Reset accrued yield

        stakingToken.transfer(msg.sender, amountToClaim);

        emit YieldClaimed(msg.sender, amountToClaim, block.timestamp);
    }


    // --- Dimension & Leap Functions ---

    function enterDimension(uint256 _targetDimensionId) external whenNotPaused {
        UserPosition storage pos = userPositions[msg.sender];
        if (!pos.isStaking) revert NotStakingInDimension();
        if (pos.dimensionId == _targetDimensionId) return; // Already in this dimension

        DimensionConfig storage targetDim = dimensionConfigs[_targetDimensionId];
        if (!targetDim.isActive) revert InvalidDimension();

        // Check key requirements for the target dimension
        if (targetDim.requiredKeyLevel > 0) {
             if (address(quantumKeyNFT) == address(0)) revert KeyNFTContractNotSet();
             uint256 userKeyLevel = getQuantumKeyDetails(msg.sender); // 0 if no key or contract not set
             if (userKeyLevel < targetDim.requiredKeyLevel) revert KeyUpgradeConditionsNotMet();
        }

        // Calculate pending yield before changing dimension
        _calculateAndAddYield(msg.sender);

        uint256 oldDimensionId = pos.dimensionId;
        pos.dimensionId = _targetDimensionId;
        pos.enterTime = block.timestamp; // Reset entry time for new lockup/yield calculation

        emit DimensionEntered(msg.sender, oldDimensionId, _targetDimensionId, block.timestamp);
    }

    function attemptQuantumLeap() external payable whenNotPaused {
        UserPosition storage pos = userPositions[msg.sender];
        if (!pos.isStaking) revert NotStakingInDimension();

        // Check leap cooldown
        if (block.timestamp < lastLeapAttemptTime[msg.sender] + leapCooldown) {
            revert QuantumLeapCooldownActive(lastLeapAttemptTime[msg.sender] + leapCooldown);
        }

        // Check Key requirement for Leap attempt (optional, configurable)
        // Example: Require Key Level 1+ to attempt a leap from any dimension > 0
        if (pos.dimensionId > 0) {
             if (address(quantumKeyNFT) == address(0)) revert KeyNFTContractNotSet();
             uint256 userKeyLevel = getQuantumKeyDetails(msg.sender);
             if (userKeyLevel == 0) revert KeyUpgradeConditionsNotMet(); // Using this error to indicate Key is needed
        }

         // Handle leap attempt cost (if any) - could be ETH or staking token transfer
         // For simplicity, let's assume staking token transfer (pull pattern)
         // If msg.value is used, need to handle ETH transfer and potentially refund change
         // For this example, let's stick to token cost, assuming it's approved beforehand
         if (leapAttemptCost > 0) {
             if (address(stakingToken) == address(0)) revert StakingTokenNotSet();
             if (stakingToken.allowance(msg.sender, address(this)) < leapAttemptCost) revert InsufficientAllowance();
             if (stakingToken.balanceOf(msg.sender) < leapAttemptCost) revert InsufficientBalance();
             stakingToken.transferFrom(msg.sender, address(this), leapAttemptCost);
         }


        // Calculate pending yield *before* the leap attempt (or before state change)
        _calculateAndAddYield(msg.sender);

        lastLeapAttemptTime[msg.sender] = block.timestamp;
        emit QuantumLeapAttempted(msg.sender, pos.dimensionId, block.timestamp);

        // --- Pseudo-randomness for Leap Outcome ---
        // WARNING: block.timestamp, block.difficulty (deprecated), blockhash are NOT secure
        // for determining outcomes that have significant financial value and could be
        // influenced by miners/validators. For a production system, use Chainlink VRF
        // or a similar verifiable random function.
        uint256 randomness = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            msg.sender,
            pos.amount,
            pos.enterTime,
            tx.origin // Using tx.origin adds slight unpredictability but has other issues (phishing) - safer to omit or use msg.sender
        )));

        DimensionConfig storage currentDim = dimensionConfigs[pos.dimensionId];
        uint256 chance = currentDim.leapSuccessChance; // Chance of success (0-100)

        // Determine success
        if (randomness % 100 < chance) {
            // --- Leap Successful ---
            // Determine target dimension - could be random, sequential, based on key level, etc.
            // Simple random selection among *active* dimensions (excluding current one)
            uint256 activeDimensionCount = 0;
            for(uint i = 0; i < dimensionIds.length; i++) {
                 if (dimensionConfigs[dimensionIds[i]].isActive && dimensionIds[i] != pos.dimensionId) {
                      activeDimensionCount++;
                 }
            }

            if (activeDimensionCount > 0) {
                uint256 targetDimensionId;
                 uint256 randomIndex = randomness / 100 % activeDimensionCount; // Use remaining randomness
                 uint256 currentIndex = 0;
                 for(uint i = 0; i < dimensionIds.length; i++) {
                      if (dimensionConfigs[dimensionIds[i]].isActive && dimensionIds[i] != pos.dimensionId) {
                           if (currentIndex == randomIndex) {
                                targetDimensionId = dimensionIds[i];
                                break;
                           }
                           currentIndex++;
                      }
                 }

                // If a target dimension is found
                if (targetDimensionId != 0) { // Should always be found if activeCount > 0
                    // Additional logic: Check if user meets *target* dimension's key requirements?
                    // Decide whether Leap bypasses Key requirements or needs them.
                    // Let's say Leap *can* land you anywhere, but you might need a Key to *stay* or benefit fully?
                    // Or simply, a successful leap lands you there regardless of Key - adds unpredictability.
                    // Let's go with the latter for simplicity in this example.

                    uint256 oldDimensionId = pos.dimensionId;
                    pos.dimensionId = targetDimensionId;
                    pos.enterTime = block.timestamp; // Reset entry time

                    emit QuantumLeapSuccessful(msg.sender, oldDimensionId, targetDimensionId, block.timestamp);
                    emit DimensionEntered(msg.sender, oldDimensionId, targetDimensionId, block.timestamp); // Also signal dimension change
                } else {
                     // This case should ideally not happen if activeCount > 0 and loop is correct,
                     // but handle as a failed leap outcome if no suitable target is found randomly.
                      // No state change, just logged as attempted.
                      // No successful leap event.
                }

            } else {
                 // No other active dimensions to leap into. Leap fails.
                 // No state change.
                 // No successful leap event.
            }

        } else {
            // --- Leap Failed ---
            // No state change.
            // No successful leap event.
        }
    }


    // --- QuantumKey NFT Functions (Interacts with external Soulbound ERC721) ---
    // NOTE: These functions assume a specific interface/logic for the QuantumKey NFT contract.
    // A full implementation of a Soulbound NFT requires careful consideration of transfer restrictions.

    function mintQuantumKey(uint256 _initialLevel) external whenNotPaused {
        if (address(quantumKeyNFT) == address(0)) revert KeyNFTContractNotSet();
        UserPosition storage pos = userPositions[msg.sender];
        if (!pos.isStaking) revert NotStakingInDimension();
        if (getQuantumKeyDetails(msg.sender) != 0) revert KeyAlreadyExists(); // Check if user already has a key

        // Example Minting Conditions: Must have minimum stake amount and staked for a minimum duration
        if (pos.amount < minimumStakeAmount * 2) revert NotEnoughStakedForMint(); // Example: double minimum stake
        if (block.timestamp < pos.enterTime + 30 days) revert StakeDurationTooShortForMint(); // Example: staked for 30 days

        // Generate a unique keyId for the user. For a soulbound key tied to address,
        // the user's address itself could be used, or a hash derived from it.
        // Or the NFT contract could manage mapping address to tokenId internally.
        // Let's assume the NFT contract handles ID assignment or takes address directly.
        // If the NFT contract uses sequential IDs or needs a suggestion, you'd need different logic.
        // Assuming `mint` function takes the recipient address and level.
        // If keyId is required here, you'd need a method to get the user's potential keyId or assign one.
        // Let's assume the NFT contract maps address -> keyId and mints a new ID if needed.
        // The `mint` function on IQuantumKeyNFT might look like `mint(address to, uint256 level)`
        // and the NFT contract internally assigns/manages the keyId associated with that address.
        // For this example, let's pass a dummy keyId (e.g., hash of address) but rely on NFT contract logic.

        uint256 potentialKeyId = uint256(keccak256(abi.encodePacked(msg.sender)));
        uint256 level = _initialLevel > 0 ? _initialLevel : 1; // Default to level 1 if 0 requested

        quantumKeyNFT.mint(msg.sender, potentialKeyId, level); // Assume NFT contract handles actual ID

        emit QuantumKeyMinted(msg.sender, potentialKeyId, level, block.timestamp); // Emit with potential ID
    }

    function burnQuantumKey() external whenNotPaused {
        if (address(quantumKeyNFT) == address(0)) revert KeyNFTContractNotSet();
        uint256 userKeyId = getQuantumKeyDetails(msg.sender); // Returns 0 if no key
        if (userKeyId == 0) revert KeyNotFound();

        // Optional: Add conditions for burning (e.g., stake must be > 0, certain dimension)
        // UserPosition storage pos = userPositions[msg.sender];
        // if (!pos.isStaking) revert NotStakingInDimension();

        quantumKeyNFT.burn(userKeyId);

        // Optional: Provide a benefit for burning (e.g., reduced early unstake penalty once)
        // if (pos.isStaking) {
        //    // Apply a temporary or permanent modifier to user's position
        // }

        emit QuantumKeyBurned(msg.sender, userKeyId, block.timestamp);
    }

    function upgradeQuantumKey() external whenNotPaused {
         if (address(quantumKeyNFT) == address(0)) revert KeyNFTContractNotSet();
         uint256 userKeyId = getQuantumKeyDetails(msg.sender); // Returns 0 if no key
         if (userKeyId == 0) revert KeyNotFound();

         uint256 currentLevel = quantumKeyNFT.getKeyLevel(userKeyId);
         // Example Upgrade Conditions: Must meet staking criteria (amount, duration) AND have current key
         UserPosition storage pos = userPositions[msg.sender];
         if (!pos.isStaking) revert NotStakingInDimension();
         if (pos.amount < minimumStakeAmount * (currentLevel + 1)) revert KeyUpgradeConditionsNotMet(); // Example: stake scales with level
         if (block.timestamp < pos.enterTime + 60 days * currentLevel) revert KeyUpgradeConditionsNotMet(); // Example: duration scales with level

         // Pass the call to the NFT contract to handle the actual upgrade logic and state change
         quantumKeyNFT.upgradeKeyLevel(userKeyId, currentLevel + 1); // Assuming NFT contract has this function

         emit QuantumKeyUpgraded(msg.sender, userKeyId, currentLevel + 1, block.timestamp);
    }


    // --- Parameter Management Functions ---

    function triggerEpochUpdate() external whenNotPaused {
        // Allow anyone to call this, but add a cooldown or check if enough time passed
        // This is a simple time-based epoch advancement
        if (block.timestamp < lastEpochUpdateTime + epochDuration) {
             revert EpochUpdateCooldownActive(lastEpochUpdateTime + epochDuration);
        }

        currentEpoch++;
        lastEpochUpdateTime = block.timestamp;

        // --- Dynamic Parameter Logic based on Epoch ---
        // This is where you'd implement rules like:
        // - Increase yield multipliers for certain dimensions in certain epochs
        // - Decrease leap chances over time
        // - Modify lockup periods
        // This logic is highly specific to the desired game/financial model.
        // Example: Boost Dimension 1 yield every 5 epochs.
        // if (currentEpoch % 5 == 0) {
        //     if (dimensionConfigs[1].isActive) {
        //         dimensionConfigs[1].yieldMultiplier += 10; // Add 10% yield
        //         emit DimensionUpdated(1, block.timestamp);
        //     }
        // }
        // Add more complex logic here... based on epoch, total staked, etc.
        // This could involve iterating through dimensions or having specific rules per dimension.

        emit ParametersUpdated(currentEpoch, block.timestamp);
    }

    function updateParametersFromOracle() external whenNotPaused {
        // This function should ideally be called by a trusted Oracle Keeper address
        // or via a decentralized network like Chainlink Keepers.
        // For this example, let's just allow the owner to trigger it, but note the intent.
        // A proper implementation would require access control or a dedicated Keeper pattern.
        // if (msg.sender != keeperAddress) revert NotKeeper(); // Example Keeper check

        if (address(oracle) == address(0)) revert OracleNotSet();

        // Example: Fetch a value from the oracle (e.g., price of staking token, external market volatility index)
        // Use this value to adjust parameters dynamically.
        // Example: Higher volatility index might decrease leap chance but increase a specific dimension's yield.
        try oracle.getLatestData("VOLATILITY_INDEX") returns (uint256 indexValue, uint256 oracleTimestamp) {
            // Check if data is recent enough (optional but recommended)
            // require(block.timestamp - oracleTimestamp < 3600, "Oracle data too old");

            // Implement logic to adjust parameters based on indexValue
            // Example: Adjust global leap cooldown based on indexValue
            // leapCooldown = 1 days + (indexValue * 1 ether / 1000); // Example scaling

            // Example: Adjust a specific dimension's yield based on index
            // uint256 dimToAdjust = 2; // Example dimension ID
            // if (dimensionConfigs[dimToAdjust].isActive) {
            //     dimensionConfigs[dimToAdjust].yieldMultiplier = 100 + (indexValue / 50); // Example scaling
            //     emit DimensionUpdated(dimToAdjust, block.timestamp);
            // }

            // This section is placeholder logic. Real implementation needs defined rules.

            emit ParametersUpdated(currentEpoch, block.timestamp); // Signal parameters changed
        } catch {
            // Handle oracle call failure
            // Option 1: Revert
            // Option 2: Log error and continue with existing parameters
            // For a critical parameter update, reverting might be safer.
             revert OracleCalculationFailed(); // Custom error for oracle issues
        }
    }
     error OracleCalculationFailed(); // Define custom error for oracle issues


    // --- Query Functions (View) ---

    function getUserPosition(address _user) external view returns (
        uint256 amount,
        uint256 dimensionId,
        uint256 enterTime,
        uint256 accruedYield,
        bool isStaking
    ) {
        UserPosition storage pos = userPositions[_user];
        return (
            pos.amount,
            pos.dimensionId,
            pos.enterTime,
            pos.accruedYield,
            pos.isStaking
        );
    }

    function getDimensionConfig(uint256 _dimensionId) external view returns (
        uint256 yieldMultiplier,
        uint256 lockupDuration,
        uint256 leapSuccessChance,
        uint256 earlyUnstakePenalty,
        uint256 requiredKeyLevel,
        bool isActive
    ) {
        DimensionConfig storage dim = dimensionConfigs[_dimensionId];
        if (!dim.isActive && _dimensionId != 0) revert InvalidDimension(); // Allow querying base dim even if not explicitly 'active'
        return (
            dim.yieldMultiplier,
            dim.lockupDuration,
            dim.leapSuccessChance,
            dim.earlyUnstakePenalty,
            dim.requiredKeyLevel,
            dim.isActive
        );
    }

    function getTotalStaked() external view returns (uint256) {
        return totalStaked;
    }

    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    function calculatePendingYield(address _user) external view returns (uint256) {
        UserPosition storage pos = userPositions[_user];
        if (!pos.isStaking) return pos.accruedYield; // Return already accrued if not actively staking

        DimensionConfig storage currentDim = dimensionConfigs[pos.dimensionId];
        if (!currentDim.isActive) return pos.accruedYield; // Cannot earn yield in an inactive dimension

        uint256 timeStaked = block.timestamp - pos.enterTime;
        // Yield calculation: amount * multiplier * time / time_unit
        // Example: Daily yield rate = (multiplier / 100) * (yield_rate / 365)
        // Let's assume yieldMultiplier is already scaled, e.g., 100 = 1x, 150 = 1.5x
        // We need a base APY or APR that gets multiplied. Let's assume a global BASE_APY.
        // Or, each dimension could have a base RATE in addition to the multiplier.
        // Simpler: Yield is just amount * multiplier * time_in_seconds / SECONDS_PER_YEAR / 100 (if multiplier is percent)
        // Let's define yieldMultiplier as Basis Points (e.g., 10000 for 100%, 15000 for 150%)
        // And yield is calculated per second or per block. Let's use per second for simplicity.
        // Yield = amount * (yieldMultiplier / 10000) / SECONDS_PER_YEAR * timeStaked
        // Integer math: Yield = (amount * yieldMultiplier * timeStaked) / (10000 * SECONDS_PER_YEAR)
        // This assumes yieldMultiplier is in basis points (e.g., 10000 for 100% APY)
        // Let's redefine DimensionConfig.yieldMultiplier as APY in Basis Points (e.g. 5000 for 50% APY)

        // Recalculate struct and constructor/setter with this assumption. Let's use the previous multiplier logic (100 for 1x)
        // and assume a BASE_APY_BP global variable in basis points (e.g., 5000 for 50%)
        uint256 BASE_APY_BP = 5000; // 50% APY base rate
        uint256 currentYieldRateBP = (BASE_APY_BP * currentDim.yieldMultiplier) / 100; // Apply dimension multiplier

        // This can overflow for large amounts/times/multipliers. Need safe math or checked arithmetic (default in 0.8+)
        uint256 earned = (pos.amount * currentYieldRateBP) / 10000; // Apply APY rate to amount
        earned = (earned * timeStaked) / SECONDS_PER_YEAR; // Scale by time staked per year

        return pos.accruedYield + earned;
    }

    function getDimensionList() external view returns (uint256[] memory) {
        // Filter out inactive dimensions if needed, or return all.
        // Returning all for simplicity here.
        return dimensionIds;
    }

    function getQuantumKeyDetails(address _user) public view returns (uint256 keyLevel) {
        if (address(quantumKeyNFT) == address(0)) return 0; // No key contract set

        try quantumKeyNFT.getTokenIdByAddress(_user) returns (uint256 keyId) {
             // Check if the key exists and is owned by the user (essential for soulbound concept)
             if (keyId != 0 && quantumKeyNFT.exists(keyId)) { // exists() might be redundant for soulbound by address lookup
                 // The keyId should theoretically only be callable by the owner in a soulbound contract
                 // But relying on getTokenIdByAddress is the most direct way here.
                 // A robust Soulbound NFT would ensure ownerOf(keyId) == _user or similar internally.
                 try quantumKeyNFT.getKeyLevel(keyId) returns (uint256 level) {
                     return level;
                 } catch {
                     return 1; // Default level 1 if level lookup fails
                 }
             } else {
                 return 0; // No key found for this address
             }
        } catch {
             // Call to getTokenIdByAddress failed (e.g., function doesn't exist, or reverts for non-owners)
             // Assume no key exists or the NFT contract doesn't support this lookup method
             return 0;
        }
    }

    function calculateUnstakePenalty(address _user, uint256 _amount) external view returns (uint256 penaltyAmount, uint256 unlockTime) {
        UserPosition storage pos = userPositions[_user];
        if (!pos.isStaking) {
            return (0, 0); // Not staking, no penalty/lockup
        }
        if (_amount == 0) return (0, 0);
         if (_amount > pos.amount) _amount = pos.amount; // Calculate based on available stake

        DimensionConfig storage currentDim = dimensionConfigs[pos.dimensionId];
        unlockTime = pos.enterTime + currentDim.lockupDuration;

        if (block.timestamp < unlockTime) {
            penaltyAmount = (_amount * currentDim.earlyUnstakePenalty) / 100;
            return (penaltyAmount, unlockTime);
        } else {
            return (0, unlockTime); // Lockup period expired, no penalty
        }
    }

    function getMinimumStakeAmount() external view returns (uint256) {
        return minimumStakeAmount;
    }

    function getLeapCooldownEndTime(address _user) external view returns (uint256) {
         return lastLeapAttemptTime[_user] + leapCooldown;
    }

    function getLeapAttemptCost() external view returns (uint256) {
        return leapAttemptCost;
    }


    // --- Internal Helper Functions ---

    // Calculates yield earned since last update/entry and adds to accruedYield
    function _calculateAndAddYield(address _user) internal {
        UserPosition storage pos = userPositions[_user];
        if (!pos.isStaking || pos.amount == 0) return; // Only calculate for active, non-zero stakes

        DimensionConfig storage currentDim = dimensionConfigs[pos.dimensionId];
        if (!currentDim.isActive) return; // Cannot earn yield in an inactive dimension

        uint256 timeStaked = block.timestamp - pos.enterTime;
        if (timeStaked == 0) return; // No time passed since last update

        // Recalculate based on new assumed yieldMultiplier as APY BP and BASE_APY_BP
         uint256 BASE_APY_BP = 5000; // 50% APY base rate
         uint256 currentYieldRateBP = (BASE_APY_BP * currentDim.yieldMultiplier) / 100; // Apply dimension multiplier

         // Ensure yieldMultiplier from config is treated correctly.
         // If dimensionConfig.yieldMultiplier=150 means 150% of BASE_APY_BP.
         // Yield per second BP = (BASE_APY_BP * currentDim.yieldMultiplier / 100) / SECONDS_PER_YEAR
         // Let's simplify and assume yieldMultiplier is already the per-year multiplier (e.g. 1.5 for 150%)
         // Yield per second = (amount * yieldMultiplier / 100) / SECONDS_PER_YEAR
         // Integer Math: Yield = (amount * yieldMultiplier * timeStaked) / (100 * SECONDS_PER_YEAR)
         // Example: 100 staked, dim.yieldMultiplier=150, 1 year (31536000s)
         // Yield = (100 * 150 * 31536000) / (100 * 31536000) = 150. Correct.
         // Let's use this simpler calculation: yieldMultiplier = % relative to staked amount PER YEAR
         // So, if yieldMultiplier = 50, it means 50% APY. If = 150, it's 150% APY.

        uint256 yieldEarned = (pos.amount * currentDim.yieldMultiplier); // amount * % per year
        yieldEarned = (yieldEarned * timeStaked) / (100 * SECONDS_PER_YEAR); // Scale by time and divide by 100%

        pos.accruedYield += yieldEarned;
        pos.enterTime = block.timestamp; // Reset entry time to calculate yield from now for next period
    }

     // Dummy function definition assuming it exists on IQuantumKeyNFT
     // For a real contract, replace with the actual function signature
     function upgradeKeyLevel(uint256 keyId, uint256 newLevel) external {
          // This is a placeholder definition to allow the contract to compile.
          // The actual logic must be in the IQuantumKeyNFT contract.
          revert("upgradeKeyLevel not implemented on mock interface");
     }
}
```

---

**Explanation of Key Concepts and Functions:**

1.  **Dimensions (State):** Represented by `DimensionConfig` struct. Each dimension (`dimensionId`) has distinct properties like `yieldMultiplier`, `lockupDuration`, `leapSuccessChance`, `earlyUnstakePenalty`, and `requiredKeyLevel`. Dimension 0 is the base/default dimension.
2.  **Staking (`stake`, `unstake`):** Users stake the designated `stakingToken`. `stake` adds tokens to a user's position, either creating a new one or adding to an existing one. `unstake` removes tokens, applying `earlyUnstakePenalty` if within the `lockupDuration`.
3.  **Yield (`claimYield`, `calculatePendingYield`, `_calculateAndAddYield`):** Yield is calculated based on the staked `amount`, the dimension's `yieldMultiplier`, and the `timeStaked` since the last yield calculation or dimension entry. `_calculateAndAddYield` is an internal helper called before state changes (staking, unstaking, dimension entry, leap attempt) to "snapshot" and add earned yield up to that point. Users can then call `claimYield` to withdraw their accrued yield.
4.  **Dimension Entry (`enterDimension`):** Allows a user to manually move their stake to a different dimension if they meet the requirements (e.g., holding a sufficient `QuantumKey` level). Resets the `enterTime` for the new dimension.
5.  **Quantum Leap (`attemptQuantumLeap`):** The core complex function. Users pay a `leapAttemptCost` (in staking token) and attempt to move dimensions. The success is determined pseudo-randomly based on the current dimension's `leapSuccessChance` and various on-chain variables (nonce, timestamp, sender, etc. - **warning: not truly secure randomness**). A successful leap moves the user to a randomly selected *other* active dimension and resets their `enterTime`. There's a `leapCooldown` to prevent spamming attempts.
6.  **QuantumKey NFT (`mintQuantumKey`, `burnQuantumKey`, `upgradeQuantumKey`, `getQuantumKeyDetails`):** Assumes an external `IQuantumKeyNFT` contract implementing a Soulbound (non-transferable) ERC721-like token.
    *   `mintQuantumKey`: Allows users meeting certain criteria (e.g., minimum stake amount/duration) to mint a Key NFT.
    *   `burnQuantumKey`: Allows users to destroy their Key NFT (potentially for a benefit).
    *   `upgradeQuantumKey`: Allows users meeting criteria (e.g., more stake/duration) to upgrade their Key's level via the NFT contract. Key level can unlock access to higher dimensions or improve leap chances (though the latter isn't explicitly coded, it's a design possibility).
    *   `getQuantumKeyDetails`: A view function to check if a user has a Key and its level. Uses `try/catch` as interaction with external contracts can fail.
7.  **Dynamic Parameters (`triggerEpochUpdate`, `updateParametersFromOracle`, `currentEpoch`, `epochDuration`, `lastEpochUpdateTime`):**
    *   `triggerEpochUpdate`: Advances the `currentEpoch` after `epochDuration` has passed. Placeholder logic is included to show *where* you'd implement parameter changes based on the epoch number (e.g., increasing yield on specific dimensions over time).
    *   `updateParametersFromOracle`: Shows how to integrate with an `IOracle` contract (like Chainlink) to fetch external data (e.g., market price, volatility) and use it to dynamically adjust contract parameters (e.g., yield rates, leap chances). This function should be secured (e.g., only callable by a trusted Keeper or oracle service).
8.  **Access Control & Pause (`owner`, `onlyOwner`, `paused`, `whenNotPaused`, `whenPaused`, `pauseContract`, `unpauseContract`):** Basic ownership pattern for administrative functions and a pause mechanism for emergencies.
9.  **Error Handling:** Uses custom errors (Solidity 0.8.4+) and `require` statements for input validation and state checks.
10. **Views (`getUserPosition`, `getDimensionConfig`, etc.):** Functions to query the state of the contract and user positions without sending a transaction.

This contract provides a framework for a staking system with engaging, dynamic, and slightly unpredictable elements driven by time, state changes, and token gating via a non-transferable NFT. Remember that the pseudo-randomness using block details is suitable only for demonstration or low-value outcomes; production systems require robust VRF solutions.