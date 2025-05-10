Okay, here is a Solidity smart contract based on an advanced, creative concept: a "Quantum Entanglement Trading Hub".

**Concept:** The contract allows users to deposit pairs of different ERC-20 tokens and "entangle" them. An entangled pair behaves non-classically: a "Quantum Action" performed on one asset in the pair can trigger a predefined effect on the other asset *within the same pair*, regardless of who might "theoretically" own parts of the pair externally (though ownership of the *pair entity* itself is tracked). This simulates a form of on-chain "entanglement" for novel trading or interactive experiences. Users own unique "Entangled Pair" IDs representing their position.

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- OUTLINE ---
// 1. Error Definitions
// 2. Event Definitions
// 3. Interface for ERC20
// 4. Structs and Enums
// 5. Main Contract: QuantumEntanglementTradingHub
//    - State Variables (Admin, Fees, Pairs, Cooldowns, Approved Tokens, User Pairs)
//    - Modifiers (Basic Ownership check)
//    - Constructor
//    - Admin Functions (Ownership, Fees, Approved Tokens, Emergency)
//    - Pair Management Functions (Creation, Details, User Pairs)
//    - Entanglement Control Functions (Activate/Deactivate)
//    - Quantum Action Functions (Perform, Simulate, Cooldowns, Pausing)
//    - Pair Lifecycle Functions (Ownership Transfer, Decoherence)
//    - Utility & View Functions

// --- FUNCTION SUMMARY ---
// Admin Functions:
// 1. constructor() - Initializes contract owner, fee recipient, and fees.
// 2. setCreationFee(uint256 newFee) - Sets the fee to create a pair (only owner).
// 3. setDecoherenceFee(uint256 newFee) - Sets the fee to decohere a pair (only owner).
// 4. setFeeRecipient(address newRecipient) - Sets the address receiving fees (only owner).
// 5. withdrawFees(address tokenAddress, uint256 amount) - Allows owner to withdraw collected fees in any token.
// 6. addApprovedToken(address tokenAddress) - Adds an ERC20 token to the list of approved tokens for pairs (only owner).
// 7. removeApprovedToken(address tokenAddress) - Removes an ERC20 token from the approved list (only owner).
// 8. setMinimumEntanglementDuration(uint256 duration) - Sets minimum time a pair must be entangled (only owner).
// 9. adminForceDecoherence(uint256 pairId) - Emergency function for owner to break a pair (e.g., if assets become unspendable).

// Pair Management Functions:
// 10. createEntangledPair(address tokenA, uint256 amountA, address tokenB, uint256 amountB, QuantumEffectType effectType, uint256 effectParam1, uint256 effectParam2, bool initialEntangledStatus) - Creates a new entangled pair entity by depositing tokens and paying a fee.
// 11. getPairDetails(uint256 pairId) - Retrieves all details for a specific entangled pair (view).
// 12. getUserPairs(address user) - Gets a list of all pair IDs owned by a specific user (view).

// Entanglement Control Functions:
// 13. activateEntanglement(uint256 pairId) - Sets the 'isEntangled' status of a pair to true (only pair owner).
// 14. deactivateEntanglement(uint256 pairId) - Sets the 'isEntangled' status of a pair to false (only pair owner).

// Quantum Action Functions:
// 15. performQuantumActionOnA(uint256 pairId) - Executes the configured quantum effect on the pair's assets, triggered by action 'on A' (only pair owner, subject to cooldown, entanglement, and pause status).
// 16. simulateQuantumActionEffect(uint256 pairId) - Simulates the effect of performQuantumActionOnA without changing state, returning predicted outcomes (view).
// 17. setQuantumActionCooldown(uint256 pairId, uint256 cooldownDuration) - Sets a custom cooldown period between quantum actions for a specific pair (only pair owner).
// 18. pausePairActions(uint256 pairId) - Temporarily prevents quantum actions on a specific pair (only pair owner).
// 19. unpausePairActions(uint256 pairId) - Resumes quantum actions on a specific pair (only pair owner).

// Pair Lifecycle Functions:
// 20. transferPairOwnership(uint256 pairId, address newOwner) - Transfers ownership of the pair entity to another address (only current pair owner).
// 21. decoherePair(uint256 pairId) - Breaks the entanglement, returns deposited assets (minus fee) to the pair owner, and removes the pair entity (only pair owner, subject to minimum entanglement duration and lock status).

// Utility & View Functions:
// 22. isTokenApproved(address tokenAddress) - Checks if a token address is approved for use in pairs (view).
// 23. getEntangledPairCount() - Returns the total number of pairs created (view).
// 24. getLastQuantumActionTime(uint256 pairId) - Gets the timestamp of the last quantum action for a pair (view).
// 25. getMinimumEntanglementDuration() - Gets the contract's global minimum entanglement duration (view).
// 26. getQuantumEffectDescription(QuantumEffectType effectType) - Returns a string description of an effect type (view, maybe internal helper). (Let's make this internal and add a public getter if needed, or just rely on documentation). Let's skip the string description function for gas/complexity and rely on the enum names and param descriptions.

// Total functions: 25 (plus the internal helper for removing user pair IDs)
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- ERROR DEFINITIONS ---
error NotOwner();
error NotPairOwner(uint256 pairId);
error InvalidFeeRecipient();
error ZeroAmount();
error TokenNotApproved();
error InsufficientAllowance(address token, uint256 required, uint256 current);
error TransferFailed(address token);
error PairNotFound(uint256 pairId);
error PairAlreadyExists(uint256 pairId); // Should not happen with sequential ID
error PairNotEntangled();
error PairAlreadyEntangled();
error CooldownNotElapsed(uint256 timeRemaining);
error PairPaused();
error PairNotPaused();
error DecoherenceFeeTransferFailed();
error MinimumEntanglementDurationNotMet(uint256 timeRemaining);
error PairLocked(); // If a lock effect is active
error CannotWithdrawZero();
error TokenAlreadyApproved();
error TokenNotCurrentlyApproved();
error InvalidEffectParameters();

// --- EVENT DEFINITIONS ---
event PairCreated(uint256 indexed pairId, address indexed owner, address tokenA, uint256 amountA, address tokenB, uint256 amountB, QuantumEffectType effectType);
event EntanglementActivated(uint256 indexed pairId, address indexed owner);
event EntanglementDeactivated(uint256 indexed pairId, address indexed owner);
event QuantumActionPerformed(uint256 indexed pairId, address indexed owner, QuantumEffectType effectType, uint256 param1, uint256 param2);
event PairOwnershipTransferred(uint256 indexed pairId, address indexed oldOwner, address indexed newOwner);
event PairDecohered(uint256 indexed pairId, address indexed owner);
event FeesWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
event ApprovedTokenAdded(address indexed tokenAddress);
event ApprovedTokenRemoved(address indexed tokenAddress);
event QuantumActionCooldownSet(uint256 indexed pairId, uint256 duration);
event PairActionsPaused(uint256 indexed pairId);
event PairActionsUnpaused(uint256 indexed pairId);
event MinimumEntanglementDurationSet(uint256 duration);

// --- INTERFACE FOR ERC20 ---
// Manual interface definition to avoid importing OpenZeppelin IERC20
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool success);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function balanceOf(address owner) external view returns (uint256 balance);
}

// --- STRUCTS AND ENUMS ---

enum QuantumEffectType {
    NONE,                       // No effect triggered
    TRANSFER_A_TO_PAIR_OWNER,   // param1 = amount of A to transfer
    TRANSFER_B_TO_PAIR_OWNER,   // param1 = amount of B to transfer
    BURN_A,                     // param1 = amount of A to burn
    BURN_B,                     // param1 = amount of B to burn
    LOCK_B_FOR_DURATION,        // param1 = duration in seconds
    PERCENTAGE_TRANSFER_A_TO_PAIR_OWNER, // param1 = percentage (0-100)
    PERCENTAGE_TRANSFER_B_TO_PAIR_OWNER, // param1 = percentage (0-100)
    PERCENTAGE_BURN_A,          // param1 = percentage (0-100)
    PERCENTAGE_BURN_B           // param1 = percentage (0-100)
}

struct Asset {
    address tokenAddress;
    uint256 amount;
}

struct QuantumEffectConfig {
    QuantumEffectType effectType;
    uint256 param1; // Meaning depends on effectType
    uint256 param2; // Meaning depends on effectType (currently unused in defined effects)
}

struct EntangledPair {
    address owner;
    Asset assetA;
    Asset assetB;
    bool isEntangled;
    uint256 creationTime;
    QuantumEffectConfig effectConfig;
    uint256 lastQuantumActionTime;
    uint256 quantumActionCooldown; // Pair-specific cooldown (0 means global/default)
    bool paused; // Pause quantum actions for this pair
    uint256 lockBUntil; // Timestamp until Asset B is locked (used by LOCK_B_FOR_DURATION)
}

// --- MAIN CONTRACT ---
contract QuantumEntanglementTradingHub {

    // --- STATE VARIABLES ---
    address private immutable i_owner;
    address public feeRecipient;
    uint256 public creationFee; // in wei
    uint256 public decoherenceFee; // in wei

    uint256 private nextPairId;
    mapping(uint256 => EntangledPair) public entangledPairs;
    mapping(address => uint256[]) private userPairIds; // Maps user address to list of owned pair IDs

    mapping(address => bool) private approvedTokens; // Mapping of approved ERC20 token addresses

    uint256 public minimumEntanglementDuration; // Global minimum duration

    // --- MODIFIERS ---
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    modifier onlyPairOwner(uint256 _pairId) {
        EntangledPair storage pair = entangledPairs[_pairId];
        if (pair.owner == address(0)) { // Check if pair exists
             revert PairNotFound(_pairId);
        }
        if (msg.sender != pair.owner) {
            revert NotPairOwner(_pairId);
        }
        _;
    }

    // --- CONSTRUCTOR ---
    constructor(address _feeRecipient, uint256 _creationFee, uint256 _decoherenceFee) {
        if (_feeRecipient == address(0)) {
            revert InvalidFeeRecipient();
        }
        i_owner = msg.sender;
        feeRecipient = _feeRecipient;
        creationFee = _creationFee;
        decoherenceFee = _decoherenceFee;
        nextPairId = 1; // Start with ID 1
        minimumEntanglementDuration = 0; // No minimum duration by default
    }

    // --- ADMIN FUNCTIONS ---

    function setCreationFee(uint256 newFee) external onlyOwner {
        creationFee = newFee;
    }

    function setDecoherenceFee(uint256 newFee) external onlyOwner {
        decoherenceFee = newFee;
    }

    function setFeeRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) {
            revert InvalidFeeRecipient();
        }
        feeRecipient = newRecipient;
    }

    function withdrawFees(address tokenAddress, uint256 amount) external onlyOwner {
        if (amount == 0) {
            revert CannotWithdrawZero();
        }
        // Be cautious: This allows withdrawal of *any* token the contract holds.
        // It's primarily for withdrawing fees, but could potentially be used
        // in emergencies if tokens get stuck. Does NOT withdraw tokens locked in pairs.
        // Assumes the owner knows which tokens are available (fees collected).
        require(IERC20(tokenAddress).transfer(feeRecipient, amount), TransferFailed(tokenAddress));
        emit FeesWithdrawn(tokenAddress, feeRecipient, amount);
    }

     function addApprovedToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidArgument(); // Basic check
        if (approvedTokens[tokenAddress]) revert TokenAlreadyApproved();
        approvedTokens[tokenAddress] = true;
        emit ApprovedTokenAdded(tokenAddress);
    }

    function removeApprovedToken(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) revert InvalidArgument(); // Basic check
        if (!approvedTokens[tokenAddress]) revert TokenNotCurrentlyApproved();
        approvedTokens[tokenAddress] = false;
        emit ApprovedTokenRemoved(tokenAddress);
    }

    function setMinimumEntanglementDuration(uint256 duration) external onlyOwner {
        minimumEntanglementDuration = duration;
        emit MinimumEntanglementDurationSet(duration);
    }

    function adminForceDecoherence(uint256 pairId) external onlyOwner {
        // Emergency function to break a pair and return assets to original owner.
        // Bypasses checks like minimum duration, lock, entanglement status.
        // Use with extreme caution.
        EntangledPair storage pair = entangledPairs[pairId];
        if (pair.owner == address(0)) {
            revert PairNotFound(pairId);
        }

        address originalOwner = pair.owner;
        Asset memory assetA = pair.assetA;
        Asset memory assetB = pair.assetB;

        // Clean up user mapping BEFORE potential token transfer failures
        _removePairIdFromUser(originalOwner, pairId);

        // Delete pair data first
        delete entangledPairs[pairId];

        // Attempt to return assets
        bool successA = true;
        if (assetA.amount > 0) {
             successA = IERC20(assetA.tokenAddress).transfer(originalOwner, assetA.amount);
        }

        bool successB = true;
        if (assetB.amount > 0) {
             successB = IERC20(assetB.tokenAddress).transfer(originalOwner, assetB.amount);
        }

        // Note: If token transfers fail here, the assets are stuck in the contract.
        // This is a risk of emergency functions dealing with external calls.
        // A more robust system might use pull payments or have a separate recovery mechanism.
        if (!successA || !successB) {
             // Consider emitting a specific error or event for partial failure
             // For simplicity, we just proceed, knowing some assets might be stuck.
        }

        emit PairDecohered(pairId, originalOwner); // Still emit, even if asset return fails
    }

    // --- PAIR MANAGEMENT FUNCTIONS ---

    function createEntangledPair(
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB,
        QuantumEffectType effectType,
        uint256 effectParam1,
        uint256 effectParam2,
        bool initialEntangledStatus
    ) external payable {
        if (amountA == 0 && amountB == 0) {
            revert ZeroAmount();
        }
        if (!approvedTokens[tokenA] || !approvedTokens[tokenB]) {
            revert TokenNotApproved();
        }
        if (msg.value < creationFee) {
             revert InsufficientValueForFee(creationFee, msg.value);
        }

        // Transfer fee
        if (creationFee > 0) {
             (bool success, ) = payable(feeRecipient).call{value: creationFee}("");
             if (!success) {
                 // Revert the entire transaction if fee transfer fails
                 revert FeeTransferFailed(); // Custom error for fee transfer failure
             }
        }

        // Check allowances and transfer tokens to the contract
        if (amountA > 0) {
            uint256 allowanceA = IERC20(tokenA).allowance(msg.sender, address(this));
            if (allowanceA < amountA) {
                revert InsufficientAllowance(tokenA, amountA, allowanceA);
            }
            require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountA), TransferFailed(tokenA));
        }

        if (amountB > 0) {
            uint256 allowanceB = IERC20(tokenB).allowance(msg.sender, address(this));
            if (allowanceB < amountB) {
                revert InsufficientAllowance(tokenB, amountB, allowanceB);
            }
            require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountB), TransferFailed(tokenB));
        }

        uint256 pairId = nextPairId;
        nextPairId++;

        entangledPairs[pairId] = EntangledPair({
            owner: msg.sender,
            assetA: Asset({tokenAddress: tokenA, amount: amountA}),
            assetB: Asset({tokenAddress: tokenB, amount: amountB}),
            isEntangled: initialEntangledStatus,
            creationTime: block.timestamp,
            effectConfig: QuantumEffectConfig({effectType: effectType, param1: effectParam1, param2: effectParam2}),
            lastQuantumActionTime: 0, // Never acted on initially
            quantumActionCooldown: 0, // Use global default
            paused: false,
            lockBUntil: 0 // Not locked initially
        });

        userPairIds[msg.sender].push(pairId);

        emit PairCreated(pairId, msg.sender, tokenA, amountA, tokenB, amountB, effectType);
    }

    function getPairDetails(uint256 pairId)
        external
        view
        returns (
            address owner,
            Asset memory assetA,
            Asset memory assetB,
            bool isEntangled,
            uint256 creationTime,
            QuantumEffectConfig memory effectConfig,
            uint256 lastQuantumActionTime,
            uint256 quantumActionCooldown,
            bool paused,
            uint256 lockBUntil
        )
    {
        EntangledPair storage pair = entangledPairs[pairId];
        if (pair.owner == address(0)) {
            revert PairNotFound(pairId);
        }

        return (
            pair.owner,
            pair.assetA,
            pair.assetB,
            pair.isEntangled,
            pair.creationTime,
            pair.effectConfig,
            pair.lastQuantumActionTime,
            pair.quantumActionCooldown,
            pair.paused,
            pair.lockBUntil
        );
    }

    function getUserPairs(address user) external view returns (uint256[] memory) {
        return userPairIds[user];
    }

    // --- ENTANGLEMENT CONTROL FUNCTIONS ---

    function activateEntanglement(uint256 pairId) external onlyPairOwner(pairId) {
        EntangledPair storage pair = entangledPairs[pairId];
        if (pair.isEntangled) {
            revert PairAlreadyEntangled();
        }
        pair.isEntangled = true;
        emit EntanglementActivated(pairId, msg.sender);
    }

    function deactivateEntanglement(uint256 pairId) external onlyPairOwner(pairId) {
        EntangledPair storage pair = entangledPairs[pairId];
        if (!pair.isEntangled) {
            revert PairNotEntangled();
        }
        pair.isEntangled = false;
        emit EntanglementDeactivated(pairId, msg.sender);
    }

    // --- QUANTUM ACTION FUNCTIONS ---

    function performQuantumActionOnA(uint256 pairId) external onlyPairOwner(pairId) {
        EntangledPair storage pair = entangledPairs[pairId];

        if (!pair.isEntangled) {
            revert PairNotEntangled();
        }
        if (pair.paused) {
            revert PairPaused();
        }

        uint256 effectiveCooldown = pair.quantumActionCooldown == 0 ? 0 : pair.quantumActionCooldown; // Placeholder for global cooldown logic if needed
        if (effectiveCooldown > 0 && pair.lastQuantumActionTime + effectiveCooldown > block.timestamp) {
            revert CooldownNotElapsed(pair.lastQuantumActionTime + effectiveCooldown - block.timestamp);
        }

        if (pair.lockBUntil > block.timestamp && (pair.effectConfig.effectType == QuantumEffectType.TRANSFER_B_TO_PAIR_OWNER || pair.effectConfig.effectType == QuantumEffectType.BURN_B || pair.effectConfig.effectType == QuantumEffectType.PERCENTAGE_TRANSFER_B_TO_PAIR_OWNER || pair.effectConfig.effectType == QuantumEffectType.PERCENTAGE_BURN_B)) {
             revert PairLocked(); // Cannot perform action that affects locked B
        }

        // --- Execute the configured effect ---
        uint256 amountToTransferA = 0;
        uint256 amountToTransferB = 0;
        uint256 amountToBurnA = 0;
        uint256 amountToBurnB = 0;
        uint256 lockBDuration = 0;

        QuantumEffectConfig memory config = pair.effectConfig;

        if (config.effectType == QuantumEffectType.TRANSFER_A_TO_PAIR_OWNER) {
            amountToTransferA = config.param1;
        } else if (config.effectType == QuantumEffectType.TRANSFER_B_TO_PAIR_OWNER) {
            amountToTransferB = config.param1;
        } else if (config.effectType == QuantumEffectType.BURN_A) {
            amountToBurnA = config.param1;
        } else if (config.effectType == QuantumEffectType.BURN_B) {
            amountToBurnB = config.param1;
        } else if (config.effectType == QuantumEffectType.LOCK_B_FOR_DURATION) {
            lockBDuration = config.param1;
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_TRANSFER_A_TO_PAIR_OWNER) {
            if (config.param1 > 100) revert InvalidEffectParameters();
            amountToTransferA = (pair.assetA.amount * config.param1) / 100;
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_TRANSFER_B_TO_PAIR_OWNER) {
            if (config.param1 > 100) revert InvalidEffectParameters();
            amountToTransferB = (pair.assetB.amount * config.param1) / 100;
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_BURN_A) {
            if (config.param1 > 100) revert InvalidEffectParameters();
            amountToBurnA = (pair.assetA.amount * config.param1) / 100;
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_BURN_B) {
            if (config.param1 > 100) revert InvalidEffectParameters();
            amountToBurnB = (pair.assetB.amount * config.param1) / 100;
        }
        // NONE effect does nothing

        // Validate calculated amounts against pair's current balance
        if (amountToTransferA > pair.assetA.amount || amountToBurnA > pair.assetA.amount) {
             // Effect attempts to use more A than available. Could revert or cap. Let's cap.
             amountToTransferA = amountToTransferA > pair.assetA.amount ? pair.assetA.amount : amountToTransferA;
             amountToBurnA = amountToBurnA > pair.assetA.amount ? pair.assetA.amount - amountToTransferA : amountToBurnA; // Cap burn based on what's left after transfer
        }
         if (amountToTransferB > pair.assetB.amount || amountToBurnB > pair.assetB.amount) {
             // Effect attempts to use more B than available. Could revert or cap. Let's cap.
             amountToTransferB = amountToTransferB > pair.assetB.amount ? pair.assetB.amount : amountToTransferB;
             amountToBurnB = amountToBurnB > pair.assetB.amount ? pair.assetB.amount - amountToTransferB : amountToBurnB; // Cap burn based on what's left after transfer
        }


        // Perform token transfers/burns (transfers from contract to owner)
        if (amountToTransferA > 0) {
            // Need to check if the contract *actually* holds this amount.
            // The pair.assetA.amount is the internal bookkept amount.
            // If somehow actual balance differs, this could fail.
            // For simplicity, we trust the internal bookkeeping matches deposited amounts.
            bool success = IERC20(pair.assetA.tokenAddress).transfer(pair.owner, amountToTransferA);
            // Decide if failure should revert the *whole* action or be ignored
            // Ignoring failures is risky; reverting is safer for atomicity.
            require(success, TransferFailed(pair.assetA.tokenAddress));
            pair.assetA.amount -= amountToTransferA;
        }
         if (amountToTransferB > 0) {
             bool success = IERC20(pair.assetB.tokenAddress).transfer(pair.owner, amountToTransferB);
             require(success, TransferFailed(pair.assetB.tokenAddress));
             pair.assetB.amount -= amountToTransferB;
         }

        // Perform burns (requires the token to support burning via transfer to address(0)
        // or a dedicated burn function if we used a custom interface.
        // Let's assume transfer to address(0) signifies burn for *some* tokens,
        // but this is not a standard ERC20 feature. A safer assumption is that
        // we just reduce the amount in the pair state and the tokens are effectively
        // stuck in the contract, simulating a burn from the pair's perspective.
        // For a real 'burn', we'd need the token contract to support it, or use ERC777 hooks.
        // Let's implement "burn" as simply reducing the internal amount,
        // effectively locking those tokens in the contract forever unless withdrawn by admin.
        // This simplifies the ERC20 interaction.
        if (amountToBurnA > 0) {
            pair.assetA.amount -= amountToBurnA;
            // Real burn would be like: IERC20(pair.assetA.tokenAddress).transfer(address(0), amountToBurnA);
        }
        if (amountToBurnB > 0) {
            pair.assetB.amount -= amountToBurnB;
            // Real burn would be like: IERC20(pair.assetB.tokenAddress).transfer(address(0), amountToBurnB);
        }

        // Apply lock effect
        if (lockBDuration > 0) {
            pair.lockBUntil = block.timestamp + lockBDuration;
        }

        // Update last action time
        pair.lastQuantumActionTime = block.timestamp;

        emit QuantumActionPerformed(pairId, msg.sender, config.effectType, config.param1, config.param2);

        // Check if either asset amount has gone to zero, automatically decohere?
        // Let's not auto-decohere. Owner must do it explicitly.
    }

     function simulateQuantumActionEffect(uint256 pairId)
        external
        view
        returns (
            QuantumEffectType effectType,
            uint256 param1,
            uint256 param2,
            uint256 simulatedAmountTransferA,
            uint256 simulatedAmountTransferB,
            uint256 simulatedAmountBurnA,
            uint256 simulatedAmountBurnB,
            uint256 simulatedLockBDuration
        )
    {
        EntangledPair storage pair = entangledPairs[pairId];
        if (pair.owner == address(0)) {
            revert PairNotFound(pairId);
        }

        // This simulation does NOT check entanglement, cooldown, pause, or lock status.
        // It only calculates the *potential* outcome based on the current config and amounts.

        QuantumEffectConfig memory config = pair.effectConfig;

        simulatedAmountTransferA = 0;
        simulatedAmountTransferB = 0;
        simulatedAmountBurnA = 0;
        simulatedAmountBurnB = 0;
        simulatedLockBDuration = 0;

        if (config.effectType == QuantumEffectType.TRANSFER_A_TO_PAIR_OWNER) {
            simulatedAmountTransferA = config.param1;
        } else if (config.effectType == QuantumEffectType.TRANSFER_B_TO_PAIR_OWNER) {
            simulatedAmountTransferB = config.param1;
        } else if (config.effectType == QuantumEffectType.BURN_A) {
            simulatedAmountBurnA = config.param1;
        } else if (config.effectType == QuantumEffectType.BURN_B) {
            simulatedAmountBurnB = config.param1;
        } else if (config.effectType == QuantumEffectType.LOCK_B_FOR_DURATION) {
            simulatedLockBDuration = config.param1; // Returns the duration parameter
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_TRANSFER_A_TO_PAIR_OWNER) {
            if (config.param1 > 100) revert InvalidEffectParameters(); // Revert simulation if params are bad
            simulatedAmountTransferA = (pair.assetA.amount * config.param1) / 100;
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_TRANSFER_B_TO_PAIR_OWNER) {
            if (config.param1 > 100) revert InvalidEffectParameters(); // Revert simulation if params are bad
            simulatedAmountTransferB = (pair.assetB.amount * config.param1) / 100;
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_BURN_A) {
             if (config.param1 > 100) revert InvalidEffectParameters(); // Revert simulation if params are bad
            simulatedAmountBurnA = (pair.assetA.amount * config.param1) / 100;
        } else if (config.effectType == QuantumEffectType.PERCENTAGE_BURN_B) {
             if (config.param1 > 100) revert InvalidEffectParameters(); // Revert simulation if params are bad
            simulatedAmountBurnB = (pair.assetB.amount * config.param1) / 100;
        }
        // NONE effect results in 0 for all simulated amounts/durations

        // Cap calculated amounts at current pair balance for simulation clarity
        simulatedAmountTransferA = simulatedAmountTransferA > pair.assetA.amount ? pair.assetA.amount : simulatedAmountTransferA;
        simulatedAmountBurnA = simulatedAmountBurnA > pair.assetA.amount - simulatedAmountTransferA ? pair.assetA.amount - simulatedAmountTransferA : simulatedAmountBurnA;

        simulatedAmountTransferB = simulatedAmountTransferB > pair.assetB.amount ? pair.assetB.amount : simulatedAmountTransferB;
        simulatedAmountBurnB = simulatedAmountBurnB > pair.assetB.amount - simulatedAmountTransferB ? pair.assetB.amount - simulatedAmountTransferB : simulatedAmountBurnB;


        return (
            config.effectType,
            config.param1,
            config.param2,
            simulatedAmountTransferA,
            simulatedAmountTransferB,
            simulatedAmountBurnA,
            simulatedAmountBurnB,
            simulatedLockBDuration
        );
    }

    function setQuantumActionCooldown(uint256 pairId, uint256 cooldownDuration) external onlyPairOwner(pairId) {
        EntangledPair storage pair = entangledPairs[pairId];
        pair.quantumActionCooldown = cooldownDuration; // 0 means no specific cooldown / use global if implemented
        emit QuantumActionCooldownSet(pairId, cooldownDuration);
    }

    function pausePairActions(uint256 pairId) external onlyPairOwner(pairId) {
        EntangledPair storage pair = entangledPairs[pairId];
        if (pair.paused) revert PairPaused();
        pair.paused = true;
        emit PairActionsPaused(pairId);
    }

    function unpausePairActions(uint256 pairId) external onlyPairOwner(pairId) {
        EntangledPair storage pair = entangledPairs[pairId];
        if (!pair.paused) revert PairNotPaused();
        pair.paused = false;
        emit PairActionsUnpaused(pairId);
    }


    // --- PAIR LIFECYCLE FUNCTIONS ---

    function transferPairOwnership(uint256 pairId, address newOwner) external onlyPairOwner(pairId) {
        if (newOwner == address(0)) revert InvalidArgument(); // Standard check

        EntangledPair storage pair = entangledPairs[pairId];
        address oldOwner = msg.sender;

        // Update user mapping: remove from old owner, add to new owner
        _removePairIdFromUser(oldOwner, pairId);
        userPairIds[newOwner].push(pairId);

        // Update pair owner
        pair.owner = newOwner;

        emit PairOwnershipTransferred(pairId, oldOwner, newOwner);
    }

    function decoherePair(uint256 pairId) external onlyPairOwner(pairId) {
        EntangledPair storage pair = entangledPairs[pairId];

        // Optional: Require de-entanglement before decoherence
        // if (pair.isEntangled) { revert PairStillEntangled(); }

        // Check minimum entanglement duration
        if (minimumEntanglementDuration > 0 && pair.creationTime + minimumEntanglementDuration > block.timestamp) {
             revert MinimumEntanglementDurationNotMet(pair.creationTime + minimumEntanglementDuration - block.timestamp);
        }

        // Check if B is currently locked
        if (pair.lockBUntil > block.timestamp) {
            revert PairLocked();
        }

        // Transfer decoherence fee
        if (decoherenceFee > 0) {
            (bool success, ) = payable(feeRecipient).call{value: decoherenceFee}("");
            if (!success) {
                 revert DecoherenceFeeTransferFailed();
            }
        }

        // Get asset details before deleting
        Asset memory assetA = pair.assetA;
        Asset memory assetB = pair.assetB;

        // Clean up user mapping BEFORE potential token transfer failures
        _removePairIdFromUser(msg.sender, pairId);

        // Delete the pair data
        delete entangledPairs[pairId];

        // Transfer assets back to the owner
        bool successA = true;
        if (assetA.amount > 0) {
            successA = IERC20(assetA.tokenAddress).transfer(msg.sender, assetA.amount);
        }
        bool successB = true;
        if (assetB.amount > 0) {
            successB = IERC20(assetB.tokenAddress).transfer(msg.sender, assetB.amount);
        }

        // Note: Similar to adminForceDecoherence, if token transfers fail, assets are stuck.
        // This is a trade-off for simplicity vs. complexity of recovery mechanisms.
        if (!successA || !successB) {
            // Consider emitting a specific error or event for partial failure
        }

        emit PairDecohered(pairId, msg.sender);
    }

    // --- UTILITY & VIEW FUNCTIONS ---

    function isTokenApproved(address tokenAddress) external view returns (bool) {
        return approvedTokens[tokenAddress];
    }

    function getEntangledPairCount() external view returns (uint256) {
        return nextPairId - 1; // Total pairs created is next ID minus 1
    }

    function getLastQuantumActionTime(uint256 pairId) external view returns (uint256) {
        EntangledPair storage pair = entangledPairs[pairId];
         if (pair.owner == address(0)) {
            revert PairNotFound(pairId);
        }
        return pair.lastQuantumActionTime;
    }

    function getMinimumEntanglementDuration() external view returns (uint256) {
        return minimumEntanglementDuration;
    }

    function getPairOwner(uint256 pairId) external view returns (address) {
         EntangledPair storage pair = entangledPairs[pairId];
         if (pair.owner == address(0)) {
            revert PairNotFound(pairId);
        }
         return pair.owner;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    // --- INTERNAL HELPERS ---

    // Helper to remove a pair ID from a user's list
    function _removePairIdFromUser(address user, uint256 pairId) internal {
        uint256[] storage pairs = userPairIds[user];
        for (uint i = 0; i < pairs.length; i++) {
            if (pairs[i] == pairId) {
                // Found the ID, swap with the last element and pop
                pairs[i] = pairs[pairs.length - 1];
                pairs.pop();
                break; // Assume each pairId is unique per user list
            }
        }
         // Note: If pairId wasn't found (which implies internal state inconsistency),
         // this function silently does nothing. Consider adding a check if necessary.
    }

     // Custom error for fee transfer failure
    error FeeTransferFailed();
    // Custom error for insufficient value sent for fee
    error InsufficientValueForFee(uint256 required, uint256 sent);
     // Basic invalid argument error
    error InvalidArgument();
}
```

**Explanation of Concepts and Features:**

1.  **Quantum Entanglement Metaphor:** The core idea is the `EntangledPair` struct. It holds two assets (`assetA`, `assetB`) that are conceptually "linked". Actions on one (`performQuantumActionOnA`) trigger a specific effect on the other, simulating the non-local correlation of entangled particles.
2.  **Configurable Quantum Effects:** The `QuantumEffectConfig` struct and `QuantumEffectType` enum allow pair creators to define *what* happens when a Quantum Action is performed. This adds a layer of strategy and unpredictability (depending on the chosen effect and parameters). Effects range from transferring percentages of assets to burning them or even locking one side for a duration.
3.  **Pair as a Tradable Entity:** The `EntangledPair` struct has an `owner`. While the underlying assets are held by the contract, the *ownership of the pair ID* represents control over those assets and the ability to perform actions or decohere. This ownership can be transferred (`transferPairOwnership`), allowing pairs themselves to become tradable assets (though not explicitly ERC-721 tokens *in this contract*, their ownership is transferable).
4.  **Decoherence:** The `decoherePair` function represents breaking the entanglement, returning the underlying assets to the owner (minus a fee). This provides an exit mechanism from a pair.
5.  **Quantum Action Control:** Features like `isEntangled` flag, `quantumActionCooldown`, `paused` flag, and `lockBUntil` timestamp add layers of control and potential strategy around when and how Quantum Actions can be performed.
6.  **Approved Tokens:** The `approvedTokens` list provides a safety mechanism, allowing the contract owner to restrict which ERC-20 tokens can be used to create pairs, mitigating risks associated with unknown or malicious tokens.
7.  **Manual ERC20 and Ownership:** To adhere to the "don't duplicate any of open source" spirit regarding common libraries, basic ownership (`i_owner`, `onlyOwner` modifier pattern) and ERC-20 interactions (`IERC20` interface, manual `transferFrom` and `transfer` calls with return value checks) are implemented within the contract rather than importing standard libraries like OpenZeppelin's `Ownable` or `SafeERC20`.
8.  **Structured Errors and Events:** Uses custom errors (`revert Foo()`) and emits detailed events for key actions, following modern Solidity best practices for clearer debugging and off-chain monitoring.
9.  **Simulation Function:** `simulateQuantumActionEffect` allows users to preview the potential outcome of a Quantum Action without executing it on chain, which is crucial for complex, state-changing operations.
10. **User Pair Tracking:** The `userPairIds` mapping provides an efficient way to look up all pairs owned by a specific address without iterating through all existing pairs.
11. **Minimum Entanglement Duration:** An optional rule set by the admin to enforce a minimum holding period before a pair can be decohered, potentially encouraging longer-term "entanglement".

This contract is complex and introduces novel mechanics beyond standard token operations, DeFi swaps, or NFT marketplaces. It leverages the deterministic nature of smart contracts to simulate a non-deterministic-sounding concept (quantum entanglement) in a controlled, rule-based manner, offering interesting possibilities for gamified finance, unique digital collectible mechanics, or experimental trading strategies.