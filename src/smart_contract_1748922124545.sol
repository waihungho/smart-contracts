Okay, let's create a smart contract called `QuantumVault`. The core concept is a vault where users can deposit tokens into different "dimensions," each with varying lock-up periods, yield rates, and risk factors. The vault introduces "quantum-inspired" concepts like "harmonic resonance" required for withdrawal, "entanglement" between deposits, and a probabilistic "observer effect" fee.

This contract goes beyond standard staking or vault patterns by introducing state-dependent withdrawal conditions (`harmonic resonance`), linking mechanisms (`entanglement`), and a unique probabilistic fee model.

---

## QuantumVault Smart Contract

**Description:**

The `QuantumVault` is a novel smart contract designed for depositing ERC-20 tokens across different "dimensions." Each dimension offers unique yield characteristics and lock-up periods. Withdrawals are contingent not only on elapsed time but also on the presence of a network-wide "harmonic resonance" state. Users can also "entangle" their deposits, linking their withdrawal conditions. A probabilistic "observer effect" fee may apply to interactions.

**Core Concepts:**

1.  **Dimensions:** Different deposit configurations (lock duration, base yield, risk multiplier).
2.  **Harmonic Resonance:** A state, determined by block timing and a global frequency, required for withdrawal.
3.  **Dimension Entanglement:** Linking two deposits, potentially affecting their withdrawal conditions.
4.  **Observer Effect Fee:** A small, probabilistic fee applied to certain interactions.
5.  **Time-based Yield:** Yield accrues based on deposit amount, dimension rate, risk factor, and global resonance frequency.

**Outline:**

1.  SPDX License and Pragma
2.  Imports (Ownable, Pausable, IERC20, SafeMath)
3.  Error Definitions
4.  Events
5.  Struct Definitions (`Dimension`, `Deposit`)
6.  State Variables
    *   Admin/Configuration (`owner`, `paused`, `dimensions`, `supportedTokens`, `globalResonanceFrequency`, `resonanceWindow`, `observerEffectFeeRateBasisPoints`, `collectedFees`)
    *   User Data (`deposits`, `userDepositIds`, `depositCounter`, `entangledPairs`)
7.  Modifiers (`onlyOwner`, `whenNotPaused`, `whenPaused`)
8.  Constructor
9.  Admin Functions (Create/Update Dimensions, Set Frequencies/Rates, Manage Tokens, Pause, Sweep Fees)
10. User Deposit Functions
11. User Withdrawal/Claim Functions (Requires Resonance, Handles Entanglement)
12. User Entanglement Functions
13. User Query Functions (Get Details, Check Conditions, Calculate Yield)
14. Internal Helper Functions (Yield Calculation, Resonance Check, Fee Application)

**Function Summary:**

1.  `constructor()`: Initializes the contract owner and sets initial parameters like global resonance frequency and window.
2.  `createDimension()`: Allows the owner to create a new deposit dimension with specified parameters (lock duration, base yield rate in basis points, risk factor multiplier).
3.  `updateDimensionParameters()`: Allows the owner to modify the parameters of an existing dimension.
4.  `setGlobalResonanceFrequency()`: Allows the owner to set the global frequency used to determine harmonic resonance windows.
5.  `setResonanceWindow()`: Allows the owner to set the duration around frequency multiples during which resonance is active.
6.  `setObserverEffectFeeRateBasisPoints()`: Allows the owner to set the probabilistic fee rate (in basis points) for the observer effect.
7.  `setSupportedToken()`: Allows the owner to add or remove supported ERC-20 tokens that can be deposited.
8.  `depositIntoDimension()`: Allows a user to deposit a supported ERC-20 token into a specified dimension. Requires token approval beforehand. Applies observer effect fee probabilistically.
9.  `calculateDepositYield()`: Calculates the estimated accrued yield for a specific user deposit up to the current block timestamp. Takes into account dimension parameters, resonance, and time.
10. `calculateUserTotalYield()`: Calculates the total estimated accrued yield for all deposits belonging to a user.
11. `withdrawDeposit()`: Allows a user to withdraw their principal and accrued yield for a specific deposit. Requires the lock duration to be over, harmonic resonance to be active, and any entangled partner deposit to also be ready for withdrawal/already withdrawn. Applies observer effect fee probabilistically.
12. `claimYieldOnly()`: Allows a user to claim only the accrued yield for a specific deposit without withdrawing the principal. Requires the lock duration to be over and harmonic resonance to be active.
13. `entangleDeposits()`: Allows a user to link two of their existing deposits. Both deposits must meet entanglement prerequisites (e.g., not already entangled).
14. `disentangleDeposits()`: Allows a user to break the link between two entangled deposits.
15. `getDepositDetails()`: Returns detailed information about a specific deposit ID.
16. `getUserDepositIds()`: Returns an array of all deposit IDs belonging to a specific user.
17. `getDimensionDetails()`: Returns the parameters of a specific dimension.
18. `getTotalDepositedByDimension()`: Returns the total amount of a specific token deposited across all deposits in a given dimension.
19. `getTotalDepositedByUser()`: Returns the total amount of a specific token deposited across all deposits belonging to a user.
20. `isHarmonicResonanceActive()`: Pure function to check if harmonic resonance is currently active based on the global frequency and window.
21. `getObserverEffectFeesCollected()`: Returns the total amount of observer effect fees collected for a specific token.
22. `sweepObserverEffectFees()`: Allows the owner to withdraw the collected observer effect fees for a specific token.
23. `pause()`: Allows the owner to pause core functionality (deposit, withdraw, claim, entangle, disentangle).
24. `unpause()`: Allows the owner to unpause the contract.
25. `transferOwnership()`: Standard Ownable function to transfer contract ownership.
26. `renounceOwnership()`: Standard Ownable function to renounce ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Keep one if needed, or remove

// Using SafeMath just for example, v0.8+ has built-in overflow checks
// but it can be useful for clarity in complex arithmetic.
// Let's rely on v0.8+ checked arithmetic for simplicity where possible.

error InvalidDimension();
error DepositNotFound();
error UnauthorizedWithdrawal();
error LockDurationNotOver();
error HarmonicResonanceNotActive();
error InvalidEntanglement();
error DepositsNotOwnedByCaller();
error DepositsAlreadyEntangled();
error DepositsNotEntangled();
error TokenNotSupported();
error InsufficientBalance();
error ZeroAmount();
error TransferFailed();
error CannotEntangleSameDeposit();
error PartnerDepositNotReady();

contract QuantumVault is Ownable, Pausable {
    using SafeMath for uint256; // Use SafeMath for clarity on calculations

    struct Dimension {
        bool exists; // To check if dimensionId is valid
        uint256 lockDuration; // seconds
        uint256 baseYieldRateBps; // Basis points (e.g., 100 = 1%)
        uint256 riskFactorMultiplierBps; // Multiplier for yield based on perceived risk (e.g., 120 = 1.2x)
    }

    struct Deposit {
        uint256 id;
        address user;
        address token; // Token contract address
        uint256 amount; // Principal amount
        uint256 dimensionId;
        uint256 depositTime;
        uint256 yieldClaimed; // Amount of yield already claimed
        bool principalWithdrawn; // Flag if principal has been withdrawn
        uint256 entangledPartnerId; // 0 if not entangled, otherwise ID of partner
    }

    // --- State Variables ---

    // Admin & Configuration
    mapping(uint256 => Dimension) public dimensions;
    uint256 public dimensionCounter;

    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public collectedObserverEffectFees; // Token address => collected fees

    uint256 public globalResonanceFrequency; // seconds (blocks won't be perfectly timed, but we use block.timestamp)
    uint256 public resonanceWindow; // seconds - window around resonance frequency when it's active

    // Observer effect fee: basis points chance (e.g., 50 = 0.5% chance)
    uint256 public observerEffectFeeRateBasisPoints;
    uint256 constant internal BASIS_POINT_DENOMINATOR = 10000;

    // User Data
    mapping(uint256 => Deposit) public deposits;
    mapping(address => uint256[]) internal userDepositIds; // User address => array of deposit IDs
    uint256 public depositCounter;

    // Entanglement mapping: deposit ID => entangled partner deposit ID
    mapping(uint256 => uint256) internal entangledPairs; // Redundant with Deposit struct, but maybe useful for quick lookup? Let's rely on struct.

    // --- Events ---
    event DimensionCreated(uint256 indexed dimensionId, uint256 lockDuration, uint256 baseYieldRateBps, uint256 riskFactorMultiplierBps);
    event DimensionUpdated(uint256 indexed dimensionId, uint256 lockDuration, uint256 baseYieldRateBps, uint256 riskFactorMultiplierBps);
    event GlobalResonanceParametersSet(uint256 frequency, uint256 window);
    event ObserverEffectFeeRateSet(uint256 rateBps);
    event TokenSupportUpdated(address indexed token, bool supported);
    event Deposited(uint256 indexed depositId, address indexed user, address indexed token, uint256 amount, uint256 dimensionId, uint256 depositTime);
    event YieldClaimed(uint256 indexed depositId, address indexed user, address indexed token, uint256 amountClaimed);
    event PrincipalWithdrawn(uint256 indexed depositId, address indexed user, address indexed token, uint256 principalAmount, uint256 totalYieldEarned);
    event DepositsEntangled(uint256 indexed deposit1Id, uint256 indexed deposit2Id);
    event DepositsDisentangled(uint256 indexed deposit1Id, uint256 indexed deposit2Id);
    event ObserverEffectFeeCollected(address indexed token, uint256 amount);
    event FeesSwept(address indexed token, uint256 amount, address indexed owner);

    // --- Constructor ---
    constructor(uint256 _initialResonanceFrequency, uint256 _initialResonanceWindow) Pausable(false) {
        // Ownable is initialized automatically
        globalResonanceFrequency = _initialResonanceFrequency;
        resonanceWindow = _initialResonanceWindow;
        // Default observer fee rate to 0
        observerEffectFeeRateBasisPoints = 0;
    }

    // --- Admin Functions ---

    /// @notice Creates a new deposit dimension with specified parameters.
    /// @param _lockDuration The duration in seconds the principal is locked.
    /// @param _baseYieldRateBps The base annual yield rate in basis points (e.g., 100 for 1%).
    /// @param _riskFactorMultiplierBps A multiplier for the yield based on perceived risk (e.g., 120 for 1.2x).
    function createDimension(uint256 _lockDuration, uint256 _baseYieldRateBps, uint256 _riskFactorMultiplierBps) external onlyOwner {
        dimensionCounter = dimensionCounter.add(1);
        dimensions[dimensionCounter] = Dimension({
            exists: true,
            lockDuration: _lockDuration,
            baseYieldRateBps: _baseYieldRateBps,
            riskFactorMultiplierBps: _riskFactorMultiplierBps
        });
        emit DimensionCreated(dimensionCounter, _lockDuration, _baseYieldRateBps, _riskFactorMultiplierBps);
    }

    /// @notice Updates the parameters of an existing deposit dimension.
    /// @param _dimensionId The ID of the dimension to update.
    /// @param _lockDuration The new lock duration in seconds.
    /// @param _baseYieldRateBps The new base annual yield rate in basis points.
    /// @param _riskFactorMultiplierBps The new risk factor multiplier in basis points.
    function updateDimensionParameters(uint256 _dimensionId, uint256 _lockDuration, uint256 _baseYieldRateBps, uint256 _riskFactorMultiplierBps) external onlyOwner {
        if (!dimensions[_dimensionId].exists) revert InvalidDimension();
        dimensions[_dimensionId].lockDuration = _lockDuration;
        dimensions[_dimensionId].baseYieldRateBps = _baseYieldRateBps;
        dimensions[_dimensionId].riskFactorMultiplierBps = _riskFactorMultiplierBps;
        emit DimensionUpdated(_dimensionId, _lockDuration, _baseYieldRateBps, _riskFactorMultiplierBps);
    }

    /// @notice Sets the global resonance frequency and window.
    /// @param _frequency The new resonance frequency in seconds.
    /// @param _window The new resonance window in seconds.
    function setGlobalResonanceFrequency(uint256 _frequency, uint256 _window) external onlyOwner {
        globalResonanceFrequency = _frequency;
        resonanceWindow = _window;
        emit GlobalResonanceParametersSet(_frequency, _window);
    }

    /// @notice Sets the observer effect fee rate in basis points.
    /// @param _rateBps The new fee rate in basis points (0-10000).
    function setObserverEffectFeeRateBasisPoints(uint256 _rateBps) external onlyOwner {
        require(_rateBps <= BASIS_POINT_DENOMINATOR, "Rate cannot exceed 100%");
        observerEffectFeeRateBasisPoints = _rateBps;
        emit ObserverEffectFeeRateSet(_rateBps);
    }

    /// @notice Sets whether a specific token is supported for deposits.
    /// @param _token The address of the token.
    /// @param _supported True to support, false to unsupport.
    function setSupportedToken(address _token, bool _supported) external onlyOwner {
        supportedTokens[_token] = _supported;
        emit TokenSupportUpdated(_token, _supported);
    }

    /// @notice Sweeps collected observer effect fees for a specific token to the owner.
    /// @param _token The address of the token to sweep fees for.
    function sweepObserverEffectFees(address _token) external onlyOwner {
        uint256 fees = collectedObserverEffectFees[_token];
        if (fees == 0) return;

        collectedObserverEffectFees[_token] = 0;
        bool success = IERC20(_token).transfer(owner(), fees);
        if (!success) {
            // Revert collectedFees state change if transfer fails
             collectedObserverEffectFees[_token] = fees; // Revert state change
             revert TransferFailed();
        }
        emit FeesSwept(_token, fees, owner());
    }

    /// @notice Pauses core contract functionality.
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses core contract functionality.
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- User Deposit Functions ---

    /// @notice Deposits a supported token into a specified dimension.
    /// @param _token The address of the ERC-20 token to deposit.
    /// @param _amount The amount of tokens to deposit.
    /// @param _dimensionId The ID of the dimension to deposit into.
    function depositIntoDimension(address _token, uint256 _amount, uint256 _dimensionId) external whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        if (!supportedTokens[_token]) revert TokenNotSupported();
        if (!dimensions[_dimensionId].exists) revert InvalidDimension();

        // Check caller's balance and allowance
        require(IERC20(_token).balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");

        // Apply observer effect fee probabilistically
        uint256 amountToDeposit = _applyObserverEffectFee(msg.sender, _token, _amount);

        // Transfer tokens to the contract
        bool success = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TransferFailed();

        depositCounter = depositCounter.add(1);
        uint256 currentDepositId = depositCounter;

        deposits[currentDepositId] = Deposit({
            id: currentDepositId,
            user: msg.sender,
            token: _token,
            amount: amountToDeposit, // Store amount *after* potential fee
            dimensionId: _dimensionId,
            depositTime: block.timestamp,
            yieldClaimed: 0,
            principalWithdrawn: false,
            entangledPartnerId: 0 // Initially not entangled
        });

        userDepositIds[msg.sender].push(currentDepositId);

        emit Deposited(currentDepositId, msg.sender, _token, amountToDeposit, _dimensionId, block.timestamp);
    }

    // --- User Withdrawal/Claim Functions ---

    /// @notice Calculates the estimated accrued yield for a specific deposit up to a given timestamp.
    /// @param _depositId The ID of the deposit.
    /// @param _timestamp The timestamp to calculate yield up to.
    /// @return The calculated yield amount.
    function calculateDepositYield(uint256 _depositId, uint256 _timestamp) public view returns (uint256) {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.user == address(0)) revert DepositNotFound();

        // Only calculate yield on the active principal
        uint256 currentPrincipal = deposit.principalWithdrawn ? 0 : deposit.amount;
        if (currentPrincipal == 0) return 0;

        Dimension storage dimension = dimensions[deposit.dimensionId];
        if (!dimension.exists) return 0; // Should not happen if deposit is valid

        // Time elapsed since deposit or last yield claim
        // For simplicity, let's calculate yield from depositTime or last claim time.
        // A more complex model might track claim timestamps.
        // Here, we calculate total potential yield and subtract claimed yield.
        uint256 timeElapsed = _timestamp.sub(deposit.depositTime);

        // Avoid division by zero if yield rate is 0 or time is 0
        if (dimension.baseYieldRateBps == 0 || timeElapsed == 0) return 0;

        // Yield calculation: principal * rate * time * risk / time_unit
        // Let's assume annual rate, so time_unit is 1 year in seconds (approx 31,536,000)
        uint256 annualRateMultiplier = dimension.baseYieldRateBps.mul(dimension.riskFactorMultiplierBps).div(BASIS_POINT_DENOMINATOR); // combined multiplier (rate * risk_factor)
        uint256 yield = currentPrincipal.mul(annualRateMultiplier).mul(timeElapsed).div(BASIS_POINT_DENOMINATOR).div(31536000); // divide by 10000 for bps, then by seconds in a year

        // Yield also depends on how much time was spent in Harmonic Resonance
        // This requires tracking resonance periods, which is complex.
        // Alternative: Yield calculation is BOOSTED when resonance IS active *now*.
        // Let's use the simpler model: yield is calculated based on total time,
        // BUT withdrawal/claim is only possible during resonance.
        // A more advanced model would require external resonance state tracking or more complex in-contract logic.
        // For this example, we use the simple time-based yield, gated by the resonance check for withdrawal.

        // Ensure calculated yield is non-negative (should be true with SafeMath on uint)
        // Ensure total calculated yield is >= yieldClaimed before returning (yield cannot decrease)
        return yield.sub(deposit.yieldClaimed);
    }

    /// @notice Calculates the total estimated accrued yield for all deposits belonging to a user.
    /// @param _user The address of the user.
    /// @return The total calculated yield amount for all user deposits (per token).
    function calculateUserTotalYield(address _user) public view returns (mapping(address => uint256) totalYields) {
        totalYields = new mapping(address => uint256); // Initialize return map

        uint256[] storage dIds = userDepositIds[_user];
        for (uint i = 0; i < dIds.length; i++) {
            uint256 depositId = dIds[i];
            Deposit storage deposit = deposits[depositId];
            // Ensure deposit exists and belongs to the user (redundant check given userDepositIds mapping)
            if (deposit.user != _user) continue;

            uint256 currentYield = calculateDepositYield(depositId, block.timestamp);
            totalYields[deposit.token] = totalYields[deposit.token].add(currentYield);
        }
        // Note: Solidity doesn't allow returning mappings directly, this requires a getter function
        // or returning a list of structs/tuples.
        // For demonstration, let's simulate returning the map. In a real contract, you'd
        // likely need a separate function to query yield per token for a user.
        // Let's change this to return a list of token addresses and their total yields.
    }

    /// @notice (Revised) Calculates the total estimated accrued yield for all deposits belonging to a user.
    /// @param _user The address of the user.
    /// @return tokens_ An array of token addresses with accrued yield.
    /// @return totalYields_ An array of corresponding total yield amounts.
    function calculateUserTotalYieldPerToken(address _user) public view returns (address[] memory tokens_, uint256[] memory totalYields_) {
         mapping(address => uint256) private totalYieldsMap;

        uint256[] storage dIds = userDepositIds[_user];
        for (uint i = 0; i < dIds.length; i++) {
            uint256 depositId = dIds[i];
            Deposit storage deposit = deposits[depositId];
             if (deposit.user != _user || deposit.principalWithdrawn) continue; // Only calculate for active deposits

            uint256 currentYield = calculateDepositYield(depositId, block.timestamp);
            totalYieldsMap[deposit.token] = totalYieldsMap[deposit.token].add(currentYield);
        }

        // Convert map to arrays for return
        address[] memory tokens = new address[](0);
        uint256[] memory yields = new uint256[](0);
        for (uint i = 0; i < dIds.length; i++) {
             uint256 depositId = dIds[i];
             Deposit storage deposit = deposits[depositId];
             // Check if this token was added to the map and hasn't been processed
             if (totalYieldsMap[deposit.token] > 0) {
                 tokens = _appendAddress(tokens, deposit.token);
                 yields = _appendUint(yields, totalYieldsMap[deposit.token]);
                 delete totalYieldsMap[deposit.token]; // Mark as processed
             }
        }
        return (tokens, yields);
    }

    // Helper to append to dynamic array (inefficient for large arrays, consider alternative patterns for many tokens)
    function _appendAddress(address[] memory arr, address value) private pure returns (address[] memory) {
        address[] memory newArr = new address[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = value;
        return newArr;
    }
     function _appendUint(uint256[] memory arr, uint256 value) private pure returns (uint256[] memory) {
        uint256[] memory newArr = new uint256[](arr.length + 1);
        for (uint i = 0; i < arr.length; i++) {
            newArr[i] = arr[i];
        }
        newArr[arr.length] = value;
        return newArr;
    }


    /// @notice Allows a user to withdraw their principal and accrued yield for a specific deposit.
    /// @param _depositId The ID of the deposit to withdraw.
    function withdrawDeposit(uint256 _depositId) external whenNotPaused {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.user == address(0)) revert DepositNotFound();
        if (deposit.user != msg.sender) revert UnauthorizedWithdrawal();
        if (deposit.principalWithdrawn) revert PrincipalWithdrawn();

        Dimension storage dimension = dimensions[deposit.dimensionId];
        if (!dimension.exists) revert InvalidDimension(); // Should not happen

        // Check lock duration
        if (block.timestamp < deposit.depositTime.add(dimension.lockDuration)) {
            revert LockDurationNotOver();
        }

        // Check harmonic resonance
        if (!isHarmonicResonanceActive()) {
            revert HarmonicResonanceNotActive();
        }

        // Check entanglement status
        if (deposit.entangledPartnerId != 0) {
            Deposit storage partnerDeposit = deposits[deposit.entangledPartnerId];
            // Partner must also be ready for withdrawal (lock over, resonance active - implicit)
            // OR partner principal must already be withdrawn.
            // This creates a dependency: you can't withdraw if your entangled partner is *stuck* but not yet withdrawn.
            if (!partnerDeposit.principalWithdrawn && block.timestamp < partnerDeposit.depositTime.add(dimensions[partnerDeposit.dimensionId].lockDuration)) {
                 revert PartnerDepositNotReady();
            }
             if (!partnerDeposit.principalWithdrawn && !isHarmonicResonanceActive()) {
                  revert PartnerDepositNotReady(); // Partner also needs resonance if not already withdrawn
             }
        }

        // Calculate and record yield
        uint256 currentYield = calculateDepositYield(_depositId, block.timestamp);
        uint256 totalEarnedYield = deposit.yieldClaimed.add(currentYield);
        deposit.yieldClaimed = totalEarnedYield; // Update claimed yield

        // Mark principal as withdrawn
        deposit.principalWithdrawn = true;

        // Calculate total amount to send (principal + yield)
        uint256 totalAmount = deposit.amount.add(currentYield);

        // Apply observer effect fee probabilistically
        uint256 amountToSend = _applyObserverEffectFee(msg.sender, deposit.token, totalAmount);

        // Transfer tokens to the user
        bool success = IERC20(deposit.token).transfer(msg.sender, amountToSend);
         if (!success) {
             // Revert state changes if transfer fails (this is complex, ideally use a withdrawal queue or re-throw)
             // For simplicity in this example, we just revert.
             deposit.principalWithdrawn = false; // Revert flag
             deposit.yieldClaimed = deposit.yieldClaimed.sub(currentYield); // Revert yield claim
             // Note: Fee collection is NOT reverted by this simple revert
             revert TransferFailed();
         }


        emit PrincipalWithdrawn(_depositId, msg.sender, deposit.token, deposit.amount, totalEarnedYield);
    }

     /// @notice Allows a user to claim only the accrued yield for a specific deposit.
    /// @param _depositId The ID of the deposit to claim yield for.
    function claimYieldOnly(uint256 _depositId) external whenNotPaused {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.user == address(0)) revert DepositNotFound();
        if (deposit.user != msg.sender) revert UnauthorizedWithdrawal();
        if (deposit.principalWithdrawn) revert PrincipalWithdrawn(); // Cannot claim yield if principal is gone

        Dimension storage dimension = dimensions[deposit.dimensionId];
        if (!dimension.exists) revert InvalidDimension();

        // Check lock duration (optional for yield claim, depending on desired logic. Let's require it for consistency with withdrawal)
        if (block.timestamp < deposit.depositTime.add(dimension.lockDuration)) {
            revert LockDurationNotOver();
        }

        // Check harmonic resonance
        if (!isHarmonicResonanceActive()) {
            revert HarmonicResonanceNotActive();
        }

        // Entanglement check for yield claim?
        // Let's make yield claim independent of entanglement state for simplicity.
        // Entanglement primarily affects principal withdrawal.

        // Calculate and claim yield
        uint256 currentYield = calculateDepositYield(_depositId, block.timestamp);
        if (currentYield == 0) return; // Nothing to claim

        deposit.yieldClaimed = deposit.yieldClaimed.add(currentYield); // Update claimed yield

        // No observer effect fee on yield claim for this example

        // Transfer yield to the user
        bool success = IERC20(deposit.token).transfer(msg.sender, currentYield);
         if (!success) {
             // Revert state change if transfer fails
             deposit.yieldClaimed = deposit.yieldClaimed.sub(currentYield);
             revert TransferFailed();
         }

        emit YieldClaimed(_depositId, msg.sender, deposit.token, currentYield);
    }


    // --- User Entanglement Functions ---

    /// @notice Allows a user to link two of their deposits.
    /// @param _deposit1Id The ID of the first deposit.
    /// @param _deposit2Id The ID of the second deposit.
    function entangleDeposits(uint256 _deposit1Id, uint256 _deposit2Id) external whenNotPaused {
        if (_deposit1Id == _deposit2Id) revert CannotEntangleSameDeposit();

        Deposit storage deposit1 = deposits[_deposit1Id];
        Deposit storage deposit2 = deposits[_deposit2Id];

        if (deposit1.user == address(0) || deposit2.user == address(0)) revert DepositNotFound();
        if (deposit1.user != msg.sender || deposit2.user != msg.sender) revert DepositsNotOwnedByCaller();
        if (deposit1.entangledPartnerId != 0 || deposit2.entangledPartnerId != 0) revert DepositsAlreadyEntangled();
        // Decide if tokens must be same, or dimension? Let's allow different tokens/dimensions for complexity.

        deposit1.entangledPartnerId = _deposit2Id;
        deposit2.entangledPartnerId = _deposit1Id;

        emit DepositsEntangled(_deposit1Id, _deposit2Id);
    }

    /// @notice Allows a user to break the link between two entangled deposits.
    /// @param _deposit1Id The ID of the first deposit (partner ID is inferred).
    function disentangleDeposits(uint256 _deposit1Id) external whenNotPaused {
        Deposit storage deposit1 = deposits[_deposit1Id];

        if (deposit1.user == address(0)) revert DepositNotFound();
        if (deposit1.user != msg.sender) revert UnauthorizedWithdrawal(); // User must own deposit1
        if (deposit1.entangledPartnerId == 0) revert DepositsNotEntangled();

        uint256 deposit2Id = deposit1.entangledPartnerId;
        Deposit storage deposit2 = deposits[deposit2Id];

        // Additional check: ensure deposit2 still points back to deposit1
        if (deposit2.entangledPartnerId != _deposit1Id) revert DepositsNotEntangled(); // Consistency check

        deposit1.entangledPartnerId = 0;
        deposit2.entangledPartnerId = 0;

        emit DepositsDisentangled(_deposit1Id, deposit2Id);
    }


    // --- User Query Functions ---

    /// @notice Gets the details of a specific deposit.
    /// @param _depositId The ID of the deposit.
    /// @return A tuple containing deposit details.
    function getDepositDetails(uint256 _depositId) public view returns (
        uint256 id,
        address user,
        address token,
        uint256 amount,
        uint256 dimensionId,
        uint256 depositTime,
        uint256 yieldClaimed,
        bool principalWithdrawn,
        uint256 entangledPartnerId
    ) {
        Deposit storage deposit = deposits[_depositId];
        if (deposit.user == address(0)) revert DepositNotFound();

        return (
            deposit.id,
            deposit.user,
            deposit.token,
            deposit.amount,
            deposit.dimensionId,
            deposit.depositTime,
            deposit.yieldClaimed,
            deposit.principalWithdrawn,
            deposit.entangledPartnerId
        );
    }

    /// @notice Gets the IDs of all deposits belonging to a specific user.
    /// @param _user The address of the user.
    /// @return An array of deposit IDs.
    function getUserDepositIds(address _user) public view returns (uint256[] memory) {
        return userDepositIds[_user];
    }

    /// @notice Gets the parameters of a specific dimension.
    /// @param _dimensionId The ID of the dimension.
    /// @return A tuple containing dimension parameters.
    function getDimensionDetails(uint256 _dimensionId) public view returns (
        bool exists,
        uint256 lockDuration,
        uint256 baseYieldRateBps,
        uint256 riskFactorMultiplierBps
    ) {
        Dimension storage dimension = dimensions[_dimensionId];
        if (!dimension.exists && _dimensionId != 0) revert InvalidDimension(); // Allow query for non-existent dimension 0

        return (
            dimension.exists,
            dimension.lockDuration,
            dimension.baseYieldRateBps,
            dimension.riskFactorMultiplierBps
        );
    }

    /// @notice Gets the total amount of a specific token deposited across all deposits in a given dimension.
    /// @param _dimensionId The ID of the dimension.
    /// @param _token The address of the token.
    /// @return The total deposited amount.
    function getTotalDepositedByDimension(uint256 _dimensionId, address _token) public view returns (uint256) {
        if (!dimensions[_dimensionId].exists) revert InvalidDimension();

        uint256 totalAmount = 0;
        // Iterating through all deposits is inefficient for large numbers.
        // A better design would track this aggregate value.
        // For this example, we iterate:
        for (uint i = 1; i <= depositCounter; i++) {
            Deposit storage dep = deposits[i];
            if (dep.user != address(0) && dep.dimensionId == _dimensionId && dep.token == _token && !dep.principalWithdrawn) {
                totalAmount = totalAmount.add(dep.amount);
            }
        }
        return totalAmount;
    }

    /// @notice Gets the total amount of a specific token deposited across all active deposits belonging to a user.
    /// @param _user The address of the user.
    /// @param _token The address of the token.
    /// @return The total deposited amount.
    function getTotalDepositedByUser(address _user, address _token) public view returns (uint256) {
        uint256 totalAmount = 0;
        uint256[] storage dIds = userDepositIds[_user];
        for (uint i = 0; i < dIds.length; i++) {
            uint256 depositId = dIds[i];
            Deposit storage deposit = deposits[depositId];
             // Check user, token, and if principal is still active
            if (deposit.user == _user && deposit.token == _token && !deposit.principalWithdrawn) {
                 totalAmount = totalAmount.add(deposit.amount);
            }
        }
        return totalAmount;
    }

    /// @notice Checks if harmonic resonance is currently active.
    /// @return True if resonance is active, false otherwise.
    function isHarmonicResonanceActive() public view returns (bool) {
        if (globalResonanceFrequency == 0) return false; // No frequency set
        if (resonanceWindow == 0) { // Instantaneous resonance
             return block.timestamp % globalResonanceFrequency == 0;
        }

        uint256 timeOffset = block.timestamp % globalResonanceFrequency;

        // Resonance is active if current time is within the window around a frequency multiple
        return timeOffset < resonanceWindow || (globalResonanceFrequency - timeOffset < resonanceWindow && timeOffset != 0);
    }

    /// @notice Gets the total observer effect fees collected for a specific token.
    /// @param _token The address of the token.
    /// @return The total collected fees.
    function getObserverEffectFeesCollected(address _token) public view returns (uint256) {
        return collectedObserverEffectFees[_token];
    }

    // --- Internal Helper Functions ---

    /// @dev Applies the observer effect fee probabilistically to an amount.
    /// @param _user The user performing the action.
    /// @param _token The token involved.
    /// @param _amount The base amount before fee.
    /// @return The amount remaining after a potential fee is deducted.
    function _applyObserverEffectFee(address _user, address _token, uint256 _amount) internal returns (uint256) {
        if (observerEffectFeeRateBasisPoints == 0 || _amount == 0) {
            return _amount;
        }

        // Generate a pseudo-random number based on block data and user address
        // NOTE: This is NOT cryptographically secure and is vulnerable to miner manipulation.
        // For a real-world contract requiring secure randomness, use Chainlink VRF or similar.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _user, _token, _amount))) % BASIS_POINT_DENOMINATOR;

        if (randomNumber < observerEffectFeeRateBasisPoints) {
            // Fee is applied
            uint256 feeAmount = _amount.mul(observerEffectFeeRateBasisPoints).div(BASIS_POINT_DENOMINATOR);
            collectedObserverEffectFees[_token] = collectedObserverEffectFees[_token].add(feeAmount);
            emit ObserverEffectFeeCollected(_token, feeAmount);
            return _amount.sub(feeAmount);
        } else {
            // No fee applied
            return _amount;
        }
    }
}
```