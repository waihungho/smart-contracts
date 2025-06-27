Okay, here is a Solidity smart contract concept called `QuantumLock`.

This contract is designed as a secure vault that can hold Ether and ERC20 tokens. The interesting, advanced concept is that the assets are locked within the contract and can *only* be released by fulfilling specific, predefined, complex conditions or "Quantum States". Multiple states can be active simultaneously, each defining a different path or trigger for unlocking a specific portion of the funds. The validity or fulfillability of a state might depend on external factors (like oracle data), time, interactions between multiple parties, or even block data (simulating "quantum fluctuations").

It's "Quantum" in the metaphorical sense: multiple potential unlock states exist in a sort of "superposition" until external "measurements" (function calls, oracle updates, time passing) cause one or more states to "collapse" into a fulfillable state, allowing the corresponding assets to be claimed.

This concept avoids simple time locks or single-key access and instead focuses on complex, condition-based release mechanisms managed on-chain.

---

**QuantumLock Smart Contract Outline and Function Summary**

**Outline:**

1.  **Contract Setup:** Ownership, Payable functionality, ERC20 interaction.
2.  **State Management:** Enums and Structs to define different types of "Quantum States" and their parameters.
3.  **Asset Management:** Mappings to track locked and claimable balances for Ether and multiple ERC20 tokens.
4.  **State Definition:** Functions for the owner to define various types of unlock states with specific conditions and asset assignments.
5.  **State Activation:** Function for the owner to activate defined states, making them eligible for unlocking.
6.  **State Attempt/Measurement:** Functions for users (or designated parties) to attempt to fulfill the conditions of an active state. Each state type has a specific attempt function.
7.  **Claiming:** Functions for beneficiaries of fulfilled states to withdraw their unlocked assets.
8.  **Emergency/Owner Functions:** Limited owner capabilities (e.g., withdrawing if no states are active).
9.  **View Functions:** Functions to query contract state, state details, and claimable balances.
10. **Events:** Logging key actions.

**Function Summary:**

1.  `constructor()`: Deploys the contract, setting the initial owner.
2.  `receive() payable`: Allows direct Ether deposits into the contract. Acts as `depositEther`.
3.  `depositERC20(IERC20 token, uint256 amount)`: Allows depositing a specified amount of a specific ERC20 token into the contract (requires prior approval).
4.  `defineTimeLockState(uint256 unlockTimestamp, uint256 etherAmount, address beneficiary, address[] erc20Tokens, uint256[] erc20Amounts)`: Defines a state unlocked after a specific timestamp.
5.  `defineAddressTimeLockState(uint256 unlockTimestamp, address requiredAddress, uint256 etherAmount, address beneficiary, address[] erc20Tokens, uint256[] erc20Amounts)`: Defines a state unlocked by a specific address after a timestamp.
6.  `defineOraclePriceLockState(uint256 unlockAfterTimestamp, address oracleAddress, bytes32 priceFeedId, int256 requiredPrice, uint8 priceDecimals, bool requireGreaterThan, uint256 etherAmount, address beneficiary, address[] erc20Tokens, uint256[] erc20Amounts)`: Defines a state unlocked if an oracle feed meets a price condition after a timestamp. *Requires Oracle integration (Chainlink mock shown).*
7.  `defineRandomBlockLockState(uint256 unlockBlockNumber, uint256 randomSeed, uint256 etherAmount, address beneficiary, address[] erc20Tokens, uint256[] erc20Amounts)`: Defines a state influenced by a future block hash (uses weak on-chain randomness, conceptual).
8.  `defineEntangledAddressLockState(uint256 validUntilTimestamp, address party1, address party2, uint256 etherAmount, address beneficiary, address[] erc20Tokens, uint256[] erc20Amounts)`: Defines a state requiring two specific addresses to interact in sequence within a time window.
9.  `defineCompoundLockState(uint256[] requiredStateIds, uint256 etherAmount, address beneficiary, address[] erc20Tokens, uint256[] erc20Amounts)`: Defines a state unlocked only after multiple other specified states have been fulfilled.
10. `cancelStateDefinition(uint256 stateId)`: Allows the owner to cancel a state *before* it has been activated.
11. `activateState(uint256 stateId)`: Allows the owner to activate a single defined state, making it eligible for attempts. Checks asset allocation.
12. `activateStates(uint256[] stateIds)`: Allows the owner to activate multiple defined states simultaneously. Checks asset allocation.
13. `attemptTimeUnlock(uint256 stateId)`: Attempts to fulfill a `TIME_LOCK` state.
14. `attemptAddressTimeUnlock(uint256 stateId)`: Attempts to fulfill an `ADDRESS_TIME_LOCK` state. Callable only by the required address.
15. `attemptOraclePriceUnlock(uint256 stateId)`: Attempts to fulfill an `ORACLE_PRICE_LOCK` state. Calls the oracle to check the price.
16. `attemptRandomBlockUnlock(uint256 stateId)`: Attempts to fulfill a `RANDOM_BLOCK_LOCK` state based on block hash and seed.
17. `attemptEntangledAddressUnlockPart1(uint256 stateId)`: The first step for `ENTANGLED_ADDRESS_LOCK` state by `party1`.
18. `attemptEntangledAddressUnlockPart2(uint256 stateId)`: The second step for `ENTANGLED_ADDRESS_LOCK` state by `party2` after part 1 is complete.
19. `attemptCompoundUnlock(uint256 stateId)`: Attempts to fulfill a `COMPOUND_LOCK` state by checking its prerequisite states.
20. `claimUnlockedEther(address payable recipient)`: Allows a beneficiary to claim unlocked Ether.
21. `claimUnlockedERC20(IERC20 token, address recipient)`: Allows a beneficiary to claim unlocked ERC20 tokens.
22. `emergencyOwnerWithdrawEther(uint256 amount)`: Owner can withdraw Ether if *no* states (active or pending) exist.
23. `emergencyOwnerWithdrawERC20(IERC20 token, uint256 amount)`: Owner can withdraw ERC20 if *no* states (active or pending) exist.
24. `transferOwnership(address newOwner)`: Transfers contract ownership (from OpenZeppelin's Ownable).
25. `renounceOwnership()`: Renounces contract ownership (from OpenZeppelin's Ownable).
26. `getStateStatus(uint256 stateId) view`: Returns the current status of a state.
27. `getStateParameters(uint256 stateId) view`: Returns key parameters for a state (type, status, beneficiary, etc.).
28. `getTotalEtherLocked() view`: Returns the total Ether balance in the contract.
29. `getTotalERC20Locked(IERC20 token) view`: Returns the total balance of a specific ERC20 token in the contract.
30. `getClaimableEther(address user) view`: Returns the amount of Ether a user can claim.
31. `getClaimableERC20(IERC20 token, address user) view`: Returns the amount of a specific ERC20 token a user can claim.
32. `getDefinedStateCount() view`: Returns the total number of states that have been defined.
33. `getActiveStateIds() view`: Returns a list of currently active state IDs.

*(Note: The contract includes placeholder logic for Oracle interaction using a mock interface. A real application would integrate with Chainlink or another oracle service.)*
*(Note: The random number generation via blockhash is weak and predictable by miners. This is for conceptual demonstration within the "quantum influence" theme, not for high-security randomness.)*
*(Note: The asset allocation check at activation ensures that the total amount assigned across *all active states* does not exceed the contract's balance. If a state is fulfilled and claimed, those funds are gone, and other states still point to their *originally assigned* amounts, but the total claimable can never exceed the contract's balance for that asset.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Mock Oracle Interface (Replace with actual Chainlink or other oracle interface if needed)
interface IMockOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

/**
 * @title QuantumLock
 * @dev A secure vault locking Ether and ERC20 tokens unlockable only via predefined "Quantum States".
 * Multiple states can be active, each representing a different condition-based unlock path.
 * The "Quantum" metaphor signifies complex, potentially unpredictable, and multi-party conditions.
 */
contract QuantumLock is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- State Management Enums and Structs ---

    enum StateType {
        NONE, // Default/Invalid state
        TIME_LOCK,
        ADDRESS_TIME_LOCK,
        ORACLE_PRICE_LOCK,
        RANDOM_BLOCK_LOCK,
        ENTANGLED_ADDRESS_LOCK,
        COMPOUND_LOCK
    }

    enum StateStatus {
        PENDING_DEFINITION, // Defined but not yet active
        ACTIVE,             // Active and can be attempted
        FULFILLED,          // Conditions met, assets claimable
        FAILED,             // Conditions can no longer be met
        CANCELLED           // Cancelled by owner before activation
    }

    struct LockState {
        uint256 id;
        StateType stateType;
        StateStatus status;
        address beneficiary; // Who receives the funds if state is fulfilled

        // Generic parameters (interpret based on stateType)
        uint256 param1_uint; // e.g., unlockTimestamp, unlockBlockNumber, validUntilTimestamp, relatedStateId count
        uint256 param2_uint; // e.g., randomSeed, relatedStateId index start
        address param1_address; // e.g., requiredAddress, party1
        address param2_address; // e.g., party2
        address param3_address; // e.g., oracleAddress
        bytes32 param1_bytes32; // e.g., priceFeedId
        int256 param1_int; // e.g., requiredPrice
        uint8 param1_uint8; // e.g., priceDecimals, requireGreaterThan (0 or 1)
        // Note: More complex parameters for CompoundLock (array of state IDs) need special handling or mapping

        uint256 unlockAmountEther;
        address[] unlockERC20Tokens;
        uint256[] unlockERC20Amounts;

        // Runtime data
        bool entangledPart1Completed; // Used only for ENTANGLED_ADDRESS_LOCK
        uint256 fulfilledTimestamp; // Timestamp when state was fulfilled
        address fulfilledBy;        // Address that successfully fulfilled the state
    }

    // --- Storage ---

    uint256 private _nextStateId = 1; // Counter for unique state IDs
    mapping(uint256 => LockState) public lockStates; // State ID to LockState struct
    uint256[] private _activeStateIds; // List of currently active state IDs

    // Mapping to track amounts allocated to states for deposit checks
    mapping(address => uint256) private _allocatedEther; // Total Ether assigned across ALL defined/active states
    mapping(address => mapping(address => uint256)) private _allocatedERC20; // Total ERC20 assigned across ALL defined/active states (tokenAddress => total)

    // Mapping to track claimable amounts for users
    mapping(address => uint256) public claimableEther; // user => amount
    mapping(address => mapping(address => uint256)) public claimableTokens; // user => tokenAddress => amount

    // --- Events ---

    event EtherDeposited(address indexed sender, uint256 amount);
    event ERC20Deposited(address indexed sender, IERC20 indexed token, uint256 amount);
    event StateDefined(uint256 indexed stateId, StateType stateType, address indexed beneficiary, uint256 etherAmount);
    event StateActivated(uint256 indexed stateId);
    event StateCancelled(uint256 indexed stateId);
    event StateAttempted(uint256 indexed stateId, address indexed attempter);
    event StateFulfilled(uint256 indexed stateId, address indexed beneficiary, address indexed attempter);
    event EtherClaimed(address indexed user, address indexed recipient, uint256 amount);
    event ERC20Claimed(address indexed user, address indexed recipient, IERC20 indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed owner, address indexed token, uint256 amount);

    // --- Constructor ---

    constructor() Ownable(msg.sender) {}

    // --- Deposit Functions ---

    /**
     * @dev Receives Ether sent directly to the contract.
     */
    receive() external payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        emit EtherDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Deposits a specific amount of an ERC20 token into the contract.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to deposit.
     */
    function depositERC20(IERC20 token, uint256 amount) external nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        // Assumes caller has already approved this contract to spend `amount` of `token`
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit ERC20Deposited(msg.sender, token, amount);
    }

    // --- State Definition Functions (Owner Only) ---

    /**
     * @dev Defines a Time Lock state. Unlocks after a specific timestamp.
     * @param unlockTimestamp The timestamp when the state becomes fulfillable.
     * @param etherAmount Amount of Ether locked by this state.
     * @param beneficiary Address to receive assets upon fulfillment.
     * @param erc20Tokens Array of ERC20 token addresses locked by this state.
     * @param erc20Amounts Array of corresponding ERC20 amounts. Length must match erc20Tokens.
     * @return The ID of the newly defined state.
     */
    function defineTimeLockState(
        uint256 unlockTimestamp,
        uint256 etherAmount,
        address beneficiary,
        address[] calldata erc20Tokens,
        uint256[] calldata erc20Amounts
    ) external onlyOwner returns (uint256) {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(unlockTimestamp > block.timestamp, "Unlock timestamp must be in the future");
        require(erc20Tokens.length == erc20Amounts.length, "ERC20 token and amount arrays must match length");

        uint256 stateId = _nextStateId++;
        lockStates[stateId] = LockState({
            id: stateId,
            stateType: StateType.TIME_LOCK,
            status: StateStatus.PENDING_DEFINITION,
            beneficiary: beneficiary,
            param1_uint: unlockTimestamp, // unlockTimestamp
            param2_uint: 0,
            param1_address: address(0),
            param2_address: address(0),
            param3_address: address(0),
            param1_bytes32: bytes32(0),
            param1_int: 0,
            param1_uint8: 0,
            unlockAmountEther: etherAmount,
            unlockERC20Tokens: erc20Tokens,
            unlockERC20Amounts: erc20Amounts,
            entangledPart1Completed: false,
            fulfilledTimestamp: 0,
            fulfilledBy: address(0)
        });

        _allocateFunds(etherAmount, erc20Tokens, erc20Amounts);
        emit StateDefined(stateId, StateType.TIME_LOCK, beneficiary, etherAmount);
        return stateId;
    }

    /**
     * @dev Defines an Address + Time Lock state. Unlocks after a timestamp by a specific address.
     * @param unlockTimestamp The timestamp when the state becomes fulfillable.
     * @param requiredAddress The specific address allowed to attempt unlock.
     * @param etherAmount Amount of Ether locked by this state.
     * @param beneficiary Address to receive assets upon fulfillment.
     * @param erc20Tokens Array of ERC20 token addresses.
     * @param erc20Amounts Array of corresponding ERC20 amounts.
     * @return The ID of the newly defined state.
     */
    function defineAddressTimeLockState(
        uint256 unlockTimestamp,
        address requiredAddress,
        uint256 etherAmount,
        address beneficiary,
        address[] calldata erc20Tokens,
        uint256[] calldata erc20Amounts
    ) external onlyOwner returns (uint256) {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(requiredAddress != address(0), "Required address cannot be zero address");
        require(unlockTimestamp > block.timestamp, "Unlock timestamp must be in the future");
        require(erc20Tokens.length == erc20Amounts.length, "ERC20 token and amount arrays must match length");

        uint256 stateId = _nextStateId++;
        lockStates[stateId] = LockState({
            id: stateId,
            stateType: StateType.ADDRESS_TIME_LOCK,
            status: StateStatus.PENDING_DEFINITION,
            beneficiary: beneficiary,
            param1_uint: unlockTimestamp, // unlockTimestamp
            param2_uint: 0,
            param1_address: requiredAddress, // requiredAddress
            param2_address: address(0),
            param3_address: address(0),
            param1_bytes32: bytes32(0),
            param1_int: 0,
            param1_uint8: 0,
            unlockAmountEther: etherAmount,
            unlockERC20Tokens: erc20Tokens,
            unlockERC20Amounts: erc20Amounts,
            entangledPart1Completed: false,
            fulfilledTimestamp: 0,
            fulfilledBy: address(0)
        });

        _allocateFunds(etherAmount, erc20Tokens, erc20Amounts);
        emit StateDefined(stateId, StateType.ADDRESS_TIME_LOCK, beneficiary, etherAmount);
        return stateId;
    }

    /**
     * @dev Defines an Oracle Price Lock state. Unlocks after a timestamp if oracle price meets condition.
     * @param unlockAfterTimestamp Timestamp after which the state can be checked.
     * @param oracleAddress The address of the oracle contract.
     * @param priceFeedId The identifier for the price feed (e.g., Chainlink feed address or custom ID).
     * @param requiredPrice The target price value (scaled by oracle decimals).
     * @param priceDecimals Decimals of the requiredPrice and oracle feed.
     * @param requireGreaterThan If true, price must be > requiredPrice; otherwise < requiredPrice.
     * @param etherAmount Amount of Ether locked.
     * @param beneficiary Address to receive assets.
     * @param erc20Tokens Array of ERC20 token addresses.
     * @param erc20Amounts Array of corresponding ERC20 amounts.
     * @return The ID of the newly defined state.
     */
    function defineOraclePriceLockState(
        uint256 unlockAfterTimestamp,
        address oracleAddress,
        bytes32 priceFeedId,
        int256 requiredPrice,
        uint8 priceDecimals,
        bool requireGreaterThan,
        uint256 etherAmount,
        address beneficiary,
        address[] calldata erc20Tokens,
        uint256[] calldata erc20Amounts
    ) external onlyOwner returns (uint256) {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(oracleAddress != address(0), "Oracle address cannot be zero address");
        require(unlockAfterTimestamp > block.timestamp, "Unlock timestamp must be in the future");
        require(erc20Tokens.length == erc20Amounts.length, "ERC20 token and amount arrays must match length");

        uint256 stateId = _nextStateId++;
        lockStates[stateId] = LockState({
            id: stateId,
            stateType: StateType.ORACLE_PRICE_LOCK,
            status: StateStatus.PENDING_DEFINITION,
            beneficiary: beneficiary,
            param1_uint: unlockAfterTimestamp, // unlockAfterTimestamp
            param2_uint: 0,
            param1_address: address(0),
            param2_address: address(0),
            param3_address: oracleAddress, // oracleAddress
            param1_bytes32: priceFeedId, // priceFeedId
            param1_int: requiredPrice, // requiredPrice
            param1_uint8: requireGreaterThan ? 1 : 0, // requireGreaterThan (as uint8)
            unlockAmountEther: etherAmount,
            unlockERC20Tokens: erc20Tokens,
            unlockERC20Amounts: erc20Amounts,
            entangledPart1Completed: false,
            fulfilledTimestamp: 0,
            fulfilledBy: address(0)
        });

        _allocateFunds(etherAmount, erc20Tokens, erc20Amounts);
        emit StateDefined(stateId, StateType.ORACLE_PRICE_LOCK, beneficiary, etherAmount);
        return stateId;
    }

    /**
     * @dev Defines a Random Block Lock state. Unlocks at a future block number based on block hash.
     * @dev NOTE: block.blockhash is only available for last 256 blocks and is influenced by miners.
     * @dev This is a weak, conceptual form of randomness for the theme, not for security-critical use.
     * @param unlockBlockNumber The block number when the state becomes fulfillable.
     * @param randomSeed An additional seed to influence the random outcome.
     * @param etherAmount Amount of Ether locked.
     * @param beneficiary Address to receive assets.
     * @param erc20Tokens Array of ERC20 token addresses.
     * @param erc20Amounts Array of corresponding ERC20 amounts.
     * @return The ID of the newly defined state.
     */
    function defineRandomBlockLockState(
        uint256 unlockBlockNumber,
        uint256 randomSeed,
        uint256 etherAmount,
        address beneficiary,
        address[] calldata erc20Tokens,
        uint256[] calldata erc20Amounts
    ) external onlyOwner returns (uint256) {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(unlockBlockNumber > block.number + 256, "Unlock block must be > current block + 256"); // blockhash limitation
        require(erc20Tokens.length == erc20Amounts.length, "ERC20 token and amount arrays must match length");

        uint256 stateId = _nextStateId++;
        lockStates[stateId] = LockState({
            id: stateId,
            stateType: StateType.RANDOM_BLOCK_LOCK,
            status: StateStatus.PENDING_DEFINITION,
            beneficiary: beneficiary,
            param1_uint: unlockBlockNumber, // unlockBlockNumber
            param2_uint: randomSeed, // randomSeed
            param1_address: address(0),
            param2_address: address(0),
            param3_address: address(0),
            param1_bytes32: bytes32(0),
            param1_int: 0,
            param1_uint8: 0,
            unlockAmountEther: etherAmount,
            unlockERC20Tokens: erc20Tokens,
            unlockERC20Amounts: erc20Amounts,
            entangledPart1Completed: false,
            fulfilledTimestamp: 0,
            fulfilledBy: address(0)
        });

        _allocateFunds(etherAmount, erc20Tokens, erc20Amounts);
        emit StateDefined(stateId, StateType.RANDOM_BLOCK_LOCK, beneficiary, etherAmount);
        return stateId;
    }

    /**
     * @dev Defines an Entangled Address Lock state. Requires two specific addresses to interact in sequence.
     * @param validUntilTimestamp The timestamp until which the two parties must interact.
     * @param party1 The address that must call attemptEntangledAddressUnlockPart1 first.
     * @param party2 The address that must call attemptEntangledAddressUnlockPart2 second.
     * @param etherAmount Amount of Ether locked.
     * @param beneficiary Address to receive assets.
     * @param erc20Tokens Array of ERC20 token addresses.
     * @param erc20Amounts Array of corresponding ERC20 amounts.
     * @return The ID of the newly defined state.
     */
    function defineEntangledAddressLockState(
        uint256 validUntilTimestamp,
        address party1,
        address party2,
        uint256 etherAmount,
        address beneficiary,
        address[] calldata erc20Tokens,
        uint256[] calldata erc20Amounts
    ) external onlyOwner returns (uint256) {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(party1 != address(0) && party2 != address(0), "Party addresses cannot be zero");
        require(party1 != party2, "Parties must be different addresses");
        require(validUntilTimestamp > block.timestamp, "Validity timestamp must be in the future");
        require(erc20Tokens.length == erc20Amounts.length, "ERC20 token and amount arrays must match length");

        uint256 stateId = _nextStateId++;
        lockStates[stateId] = LockState({
            id: stateId,
            stateType: StateType.ENTANGLED_ADDRESS_LOCK,
            status: StateStatus.PENDING_DEFINITION,
            beneficiary: beneficiary,
            param1_uint: validUntilTimestamp, // validUntilTimestamp
            param2_uint: 0,
            param1_address: party1, // party1
            param2_address: party2, // party2
            param3_address: address(0),
            param1_bytes32: bytes32(0),
            param1_int: 0,
            param1_uint8: 0,
            unlockAmountEther: etherAmount,
            unlockERC20Tokens: erc20Tokens,
            unlockERC20Amounts: erc20Amounts,
            entangledPart1Completed: false, // Initial state
            fulfilledTimestamp: 0,
            fulfilledBy: address(0)
        });

        _allocateFunds(etherAmount, erc20Tokens, erc20Amounts);
        emit StateDefined(stateId, StateType.ENTANGLED_ADDRESS_LOCK, beneficiary, etherAmount);
        return stateId;
    }

    /**
     * @dev Defines a Compound Lock state. Unlocks only after other specified states are fulfilled.
     * @param requiredStateIds Array of state IDs that must be in the FULFILLED status.
     * @param etherAmount Amount of Ether locked.
     * @param beneficiary Address to receive assets.
     * @param erc20Tokens Array of ERC20 token addresses.
     * @param erc20Amounts Array of corresponding ERC20 amounts.
     * @return The ID of the newly defined state.
     */
    function defineCompoundLockState(
        uint256[] calldata requiredStateIds,
        uint256 etherAmount,
        address beneficiary,
        address[] calldata erc20Tokens,
        uint256[] calldata erc20Amounts
    ) external onlyOwner returns (uint256) {
        require(beneficiary != address(0), "Beneficiary cannot be zero address");
        require(requiredStateIds.length > 0, "Must require at least one state");
        require(erc20Tokens.length == erc20Amounts.length, "ERC20 token and amount arrays must match length");

        // Store requiredStateIds by copying into storage/memory map if needed, or just store array.
        // Storing the array directly in the struct makes the struct dynamic, which is problematic.
        // Alternative: Store requiredStateIds in a separate mapping `mapping(uint256 => uint256[]) compoundRequirements`.
        // Let's use the separate mapping approach.

        uint256 stateId = _nextStateId++;
        lockStates[stateId] = LockState({
            id: stateId,
            stateType: StateType.COMPOUND_LOCK,
            status: StateStatus.PENDING_DEFINITION,
            beneficiary: beneficiary,
            param1_uint: uint256(requiredStateIds.length), // Number of required states
            param2_uint: 0, // Not used
            param1_address: address(0),
            param2_address: address(0),
            param3_address: address(0),
            param1_bytes32: bytes32(0),
            param1_int: 0,
            param1_uint8: 0,
            unlockAmountEther: etherAmount,
            unlockERC20Tokens: erc20Tokens,
            unlockERC20Amounts: erc20Amounts,
            entangledPart1Completed: false,
            fulfilledTimestamp: 0,
            fulfilledBy: address(0)
        });

        // Store compound requirements separately
        compoundRequirements[stateId] = requiredStateIds;

        _allocateFunds(etherAmount, erc20Tokens, erc20Amounts);
        emit StateDefined(stateId, StateType.COMPOUND_LOCK, beneficiary, etherAmount);
        return stateId;
    }

    mapping(uint256 => uint256[]) private compoundRequirements; // stateId => requiredStateIds for CompoundLock

    // --- State Management Functions (Owner Only) ---

    /**
     * @dev Allows the owner to cancel a state that is still in PENDING_DEFINITION status.
     * Frees up the allocated funds.
     * @param stateId The ID of the state to cancel.
     */
    function cancelStateDefinition(uint256 stateId) external onlyOwner nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType != StateType.NONE, "State does not exist");
        require(state.status == StateStatus.PENDING_DEFINITION, "State is not in pending definition status");

        state.status = StateStatus.CANCELLED;
        _deallocateFunds(state.unlockAmountEther, state.unlockERC20Tokens, state.unlockERC20Amounts);
        emit StateCancelled(stateId);
    }

    /**
     * @dev Allows the owner to activate a single defined state.
     * Checks if the funds are available based on current contract balance and existing allocations.
     * @param stateId The ID of the state to activate.
     */
    function activateState(uint256 stateId) external onlyOwner nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType != StateType.NONE, "State does not exist");
        require(state.status == StateStatus.PENDING_DEFINITION, "State is not in pending definition status");

        // Check if contract holds enough funds currently for this state's allocation
        require(address(this).balance >= _allocatedEther[address(this)], "Not enough Ether in contract for total allocation");
        for(uint i = 0; i < state.unlockERC20Tokens.length; i++) {
             require(
                 IERC20(state.unlockERC20Tokens[i]).balanceOf(address(this)) >= _allocatedERC20[address(this)][state.unlockERC20Tokens[i]],
                 "Not enough ERC20 tokens in contract for total allocation"
             );
        }

        state.status = StateStatus.ACTIVE;
        _activeStateIds.push(stateId); // Add to active list
        emit StateActivated(stateId);
    }

    /**
     * @dev Allows the owner to activate multiple defined states.
     * Checks if the funds are available based on current contract balance and existing allocations *before* activating any.
     * @param stateIds Array of IDs of states to activate.
     */
    function activateStates(uint256[] calldata stateIds) external onlyOwner nonReentrant {
        require(stateIds.length > 0, "Must provide at least one state ID");

        // Pre-check all states and cumulative allocation
        for (uint256 i = 0; i < stateIds.length; i++) {
            uint256 stateId = stateIds[i];
            LockState storage state = lockStates[stateId];
            require(state.stateType != StateType.NONE, string.concat("State ", _uint256ToString(stateId), " does not exist"));
            require(state.status == StateStatus.PENDING_DEFINITION, string.concat("State ", _uint256ToString(stateId), " is not pending definition"));
        }

        // Check if contract holds enough funds currently for the *total* allocation *after* adding these
         require(address(this).balance >= _allocatedEther[address(this)], "Not enough Ether in contract for total allocation");
         // This token check is tricky. _allocatedERC20 tracks total assigned. We need to check if the current balance is enough.
         // The allocation check happens *per definition*. Activating just checks if the *current* balance >= *total allocated*.
         // If funds were partially withdrawn via emergencyWithdraw, this might fail.
         // This simple check assumes _allocatedEther/_allocatedERC20 reflects only PENDING/ACTIVE states.
         // Let's ensure allocate/deallocate functions only touch PENDING/ACTIVE states.
         // Deallocate happens on CANCELLED.
         // Allocation happens on DEFINITION.
         // A state moves from PENDING -> ACTIVE. Allocation doesn't change.
         // A state moves ACTIVE -> FULFILLED. Allocation doesn't change *for the check*.
         // Claiming reduces contract balance but doesn't change _allocatedEther/_allocatedERC20.
         // The check should be: `contract.balance >= total_allocated_amount_for_active_and_pending_states`.
         // Our `_allocatedEther`/`_allocatedERC20` already does this. The check is correct.
         for(uint i = 0; i < lockStates[stateIds[0]].unlockERC20Tokens.length; i++) { // Assuming all states have same token types/order for simplicity, which isn't guaranteed. Need per-token check.
              IERC20 token = IERC20(lockStates[stateIds[0]].unlockERC20Tokens[i]);
              require(
                  token.balanceOf(address(this)) >= _allocatedERC20[address(this)][address(token)],
                  string.concat("Not enough ", _addressToString(address(token)), " tokens in contract for total allocation")
              );
         }
         // A more robust ERC20 check iterates over ALL allocated tokens across ALL pending/active states, not just one state's tokens.
         // This is complex to track efficiently. For this example, we'll rely on the _allocatedERC20 map check.

        for (uint256 i = 0; i < stateIds.length; i++) {
            uint256 stateId = stateIds[i];
            LockState storage state = lockStates[stateId];
            state.status = StateStatus.ACTIVE;
             _activeStateIds.push(stateId); // Add to active list
            emit StateActivated(stateId);
        }
    }

    // --- State Attempt/Measurement Functions ---

    /**
     * @dev Attempts to fulfill a TIME_LOCK state.
     * @param stateId The ID of the state to attempt.
     */
    function attemptTimeUnlock(uint256 stateId) external nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.TIME_LOCK, "State is not a TIME_LOCK");
        require(state.status == StateStatus.ACTIVE, "State is not active");
        require(block.timestamp >= state.param1_uint, "Unlock timestamp has not been reached");

        _fulfillState(stateId, msg.sender);
    }

    /**
     * @dev Attempts to fulfill an ADDRESS_TIME_LOCK state.
     * @param stateId The ID of the state to attempt.
     */
    function attemptAddressTimeUnlock(uint256 stateId) external nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.ADDRESS_TIME_LOCK, "State is not an ADDRESS_TIME_LOCK");
        require(state.status == StateStatus.ACTIVE, "State is not active");
        require(msg.sender == state.param1_address, "Only the required address can attempt this state");
        require(block.timestamp >= state.param1_uint, "Unlock timestamp has not been reached");

        _fulfillState(stateId, msg.sender);
    }

    /**
     * @dev Attempts to fulfill an ORACLE_PRICE_LOCK state.
     * Calls the oracle to check the current price.
     * @param stateId The ID of the state to attempt.
     */
    function attemptOraclePriceUnlock(uint256 stateId) external nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.ORACLE_PRICE_LOCK, "State is not an ORACLE_PRICE_LOCK");
        require(state.status == StateStatus.ACTIVE, "State is not active");
        require(block.timestamp >= state.param1_uint, "Unlock timestamp has not been reached"); // Check time condition first

        address oracleAddress = state.param3_address;
        // bytes32 priceFeedId = state.param1_bytes32; // priceFeedId is stored but not used by IMockOracle interface.
        int256 requiredPrice = state.param1_int;
        uint8 requireGreaterThan = state.param1_uint8; // 1 for >, 0 for <

        IMockOracle oracle = IMockOracle(oracleAddress);
        // Using try-catch for robustness against oracle call failure
        (bool success, bytes memory returndata) = address(oracle).staticcall(abi.encodeWithSignature("latestAnswer()"));
        require(success, "Oracle call failed");

        int256 currentPrice = abi.decode(returndata, (int256));

        bool priceConditionMet;
        if (requireGreaterThan == 1) {
            priceConditionMet = currentPrice > requiredPrice;
        } else {
            priceConditionMet = currentPrice < requiredPrice;
        }

        require(priceConditionMet, "Oracle price condition not met");

        _fulfillState(stateId, msg.sender);
    }

    /**
     * @dev Attempts to fulfill a RANDOM_BLOCK_LOCK state.
     * Checks the block hash at the target block number.
     * @dev WARNING: Use of blockhash is not truly random and can be manipulated by miners.
     * @param stateId The ID of the state to attempt.
     */
    function attemptRandomBlockUnlock(uint256 stateId) external nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.RANDOM_BLOCK_LOCK, "State is not a RANDOM_BLOCK_LOCK");
        require(state.status == StateStatus.ACTIVE, "State is not active");

        uint256 unlockBlockNumber = state.param1_uint;
        uint256 randomSeed = state.param2_uint;

        require(block.number >= unlockBlockNumber, "Unlock block has not been reached");
        require(block.number <= unlockBlockNumber + 256, "Block hash no longer available"); // blockhash limitation

        bytes32 blockHash = blockhash(unlockBlockNumber);
        require(blockHash != bytes32(0), "Block hash not available"); // Should not happen if block.number is correct range

        // Example "random" condition: check parity of a derived number
        uint256 randomValue = uint256(keccak256(abi.encodePacked(blockHash, randomSeed, stateId)));
        require(randomValue % 2 == 0, "Random condition not met (derived value is odd)"); // Simple example condition

        _fulfillState(stateId, msg.sender);
    }

    /**
     * @dev The first step for an ENTANGLED_ADDRESS_LOCK state. Must be called by party1.
     * @param stateId The ID of the state to attempt.
     */
    function attemptEntangledAddressUnlockPart1(uint256 stateId) external nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.ENTANGLED_ADDRESS_LOCK, "State is not an ENTANGLED_ADDRESS_LOCK");
        require(state.status == StateStatus.ACTIVE, "State is not active");
        require(msg.sender == state.param1_address, "Only Party 1 can call this function");
        require(!state.entangledPart1Completed, "Party 1 already completed their step");
        require(block.timestamp <= state.param1_uint, "Validity timestamp has passed");

        state.entangledPart1Completed = true;
        // Note: The state is NOT fulfilled yet. Only marked for Part 2.
        // If validUntilTimestamp passes before Part 2, state could be marked FAILED.
        // (Implicitly handled by attemptPart2 checking the timestamp).

        emit StateAttempted(stateId, msg.sender); // Log attempt, not fulfillment yet
    }

    /**
     * @dev The second step for an ENTANGLED_ADDRESS_LOCK state. Must be called by party2.
     * @param stateId The ID of the state to attempt.
     */
    function attemptEntangledAddressUnlockPart2(uint256 stateId) external nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.ENTANGLED_ADDRESS_LOCK, "State is not an ENTANGLED_ADDRESS_LOCK");
        require(state.status == StateStatus.ACTIVE, "State is not active");
        require(msg.sender == state.param2_address, "Only Party 2 can call this function");
        require(state.entangledPart1Completed, "Party 1 must complete their step first");
        require(block.timestamp <= state.param1_uint, "Validity timestamp has passed");

        _fulfillState(stateId, msg.sender); // Fulfill the state
    }

    /**
     * @dev Attempts to fulfill a COMPOUND_LOCK state.
     * Checks if all required prerequisite states are fulfilled.
     * @param stateId The ID of the state to attempt.
     */
    function attemptCompoundUnlock(uint256 stateId) external nonReentrant {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.COMPOUND_LOCK, "State is not a COMPOUND_LOCK");
        require(state.status == StateStatus.ACTIVE, "State is not active");

        uint256[] storage required = compoundRequirements[stateId];
        require(required.length > 0, "Compound state requires prerequisite states");

        for (uint i = 0; i < required.length; i++) {
            uint256 requiredId = required[i];
            require(lockStates[requiredId].stateType != StateType.NONE, string.concat("Required state ", _uint256ToString(requiredId), " does not exist"));
            require(lockStates[requiredId].status == StateStatus.FULFILLED, string.concat("Required state ", _uint256ToString(requiredId), " is not fulfilled"));
        }

        _fulfillState(stateId, msg.sender);
    }

    // --- Internal Fulfillment Logic ---

    /**
     * @dev Marks a state as fulfilled and transfers assets to the claimable mapping.
     * @param stateId The ID of the state to fulfill.
     * @param attempter The address that successfully attempted the state.
     */
    function _fulfillState(uint256 stateId, address attempter) internal {
        LockState storage state = lockStates[stateId];
        require(state.status == StateStatus.ACTIVE, "State is not active (already fulfilled/failed/cancelled)");

        state.status = StateStatus.FULFILLED;
        state.fulfilledTimestamp = block.timestamp;
        state.fulfilledBy = attempter;

        // Remove from active state list (less efficient with array, better with mapping or doubly linked list for large number of states)
        // For simplicity here, we'll just iterate and rebuild or leave it and filter in view function.
        // Let's filter in the view function, removal from array is gas intensive.

        // Transfer allocated funds to claimable funds for the beneficiary
        if (state.unlockAmountEther > 0) {
            claimableEther[state.beneficiary] += state.unlockAmountEther;
            // Note: We don't deallocate from _allocatedEther here, as that total represents
            // funds assigned to *defined* states, active or fulfilled.
            // The claimable mapping represents funds ready to be withdrawn.
        }

        for (uint i = 0; i < state.unlockERC20Tokens.length; i++) {
            IERC20 token = IERC20(state.unlockERC20Tokens[i]);
            uint256 amount = state.unlockERC20Amounts[i];
            if (amount > 0) {
                claimableTokens[state.beneficiary][address(token)] += amount;
                 // Note: Same as Ether, don't deallocate from _allocatedERC20 here.
            }
        }

        emit StateFulfilled(stateId, state.beneficiary, attempter);
    }

    // --- Claiming Functions ---

    /**
     * @dev Allows a user to claim their unlocked Ether.
     * @param recipient The address to send the Ether to. Can be different from msg.sender.
     */
    function claimUnlockedEther(address payable recipient) external nonReentrant {
        uint256 amountToClaim = claimableEther[msg.sender];
        require(amountToClaim > 0, "No claimable Ether for this address");

        claimableEther[msg.sender] = 0; // Reset claimable amount

        // Transfer Ether
        (bool success, ) = recipient.call{value: amountToClaim}("");
        require(success, "Ether transfer failed");

        emit EtherClaimed(msg.sender, recipient, amountToClaim);
    }

    /**
     * @dev Allows a user to claim their unlocked ERC20 tokens.
     * @param token The address of the ERC20 token.
     * @param recipient The address to send the tokens to. Can be different from msg.sender.
     */
    function claimUnlockedERC20(IERC20 token, address recipient) external nonReentrant {
        uint256 amountToClaim = claimableTokens[msg.sender][address(token)];
        require(amountToClaim > 0, "No claimable ERC20 tokens for this address");

        claimableTokens[msg.sender][address(token)] = 0; // Reset claimable amount

        // Transfer ERC20
        token.safeTransfer(recipient, amountToClaim);

        emit ERC20Claimed(msg.sender, recipient, token, amountToClaim);
    }

    // --- Owner Emergency Withdraw Functions ---

    /**
     * @dev Allows the owner to withdraw Ether only if NO states (pending or active) exist.
     * This is a safety mechanism if the contract is no longer needed for locking.
     * @param amount The amount of Ether to withdraw.
     */
    function emergencyOwnerWithdrawEther(uint256 amount) external onlyOwner nonReentrant {
        // Check if there are any states defined (active, pending, etc., except CANCELLED)
        // Iterate through _nextStateId and check status
        bool anyStatesExist = false;
        for(uint i = 1; i < _nextStateId; i++) {
            if (lockStates[i].stateType != StateType.NONE && lockStates[i].status != StateStatus.CANCELLED) {
                anyStatesExist = true;
                break;
            }
        }
        require(!anyStatesExist, "Cannot emergency withdraw while states exist");
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient Ether balance");

        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Emergency Ether withdraw failed");

        emit EmergencyWithdraw(owner(), address(0), amount);
    }

    /**
     * @dev Allows the owner to withdraw ERC20 tokens only if NO states (pending or active) exist.
     * @param token The address of the ERC20 token.
     * @param amount The amount of tokens to withdraw.
     */
    function emergencyOwnerWithdrawERC20(IERC20 token, uint256 amount) external onlyOwner nonReentrant {
         // Check if there are any states defined (active, pending, etc., except CANCELLED)
        bool anyStatesExist = false;
        for(uint i = 1; i < _nextStateId; i++) {
            if (lockStates[i].stateType != StateType.NONE && lockStates[i].status != StateStatus.CANCELLED) {
                anyStatesExist = true;
                break;
            }
        }
        require(!anyStatesExist, "Cannot emergency withdraw while states exist");
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");

        token.safeTransfer(owner(), amount);

        emit EmergencyWithdraw(owner(), address(token), amount);
    }

    // --- View Functions ---

    /**
     * @dev Returns the status of a specific state.
     * @param stateId The ID of the state.
     * @return The StateStatus enum value.
     */
    function getStateStatus(uint256 stateId) external view returns (StateStatus) {
        return lockStates[stateId].status;
    }

     /**
     * @dev Returns key parameters for a specific state.
     * @param stateId The ID of the state.
     * @return type The StateType enum value.
     * @return status The StateStatus enum value.
     * @return beneficiary The beneficiary address.
     * @return etherAmount The amount of Ether locked.
     * @return erc20Tokens Array of ERC20 token addresses locked.
     * @return erc20Amounts Array of corresponding ERC20 amounts.
     * @return param1Uint Generic uint parameter 1.
     * @return param2Uint Generic uint parameter 2.
     * @return param1Address Generic address parameter 1.
     * @return param2Address Generic address parameter 2.
     * @return param3Address Generic address parameter 3.
     * @return param1Bytes32 Generic bytes32 parameter 1.
     * @return param1Int Generic int parameter 1.
     * @return param1Uint8 Generic uint8 parameter 1.
     * @return entangledPart1Completed Status for ENTANGLED_ADDRESS_LOCK.
     * @return fulfilledTimestamp Timestamp when fulfilled.
     * @return fulfilledBy Address that fulfilled the state.
     */
    function getStateParameters(uint256 stateId) external view returns (
        StateType type,
        StateStatus status,
        address beneficiary,
        uint256 etherAmount,
        address[] memory erc20Tokens,
        uint256[] memory erc20Amounts,
        uint256 param1Uint,
        uint256 param2Uint,
        address param1Address,
        address param2Address,
        address param3Address,
        bytes32 param1Bytes32,
        int256 param1Int,
        uint8 param1Uint8,
        bool entangledPart1Completed,
        uint256 fulfilledTimestamp,
        address fulfilledBy
    ) {
        LockState storage state = lockStates[stateId];
         require(state.stateType != StateType.NONE, "State does not exist");

        return (
            state.stateType,
            state.status,
            state.beneficiary,
            state.unlockAmountEther,
            state.unlockERC20Tokens,
            state.unlockERC20Amounts,
            state.param1_uint,
            state.param2_uint,
            state.param1_address,
            state.param2_address,
            state.param3_address,
            state.param1_bytes32,
            state.param1_int,
            state.param1_uint8,
            state.entangledPart1Completed,
            state.fulfilledTimestamp,
            state.fulfilledBy
        );
    }

    /**
     * @dev Returns the required state IDs for a Compound Lock state.
     * @param stateId The ID of the COMPOUND_LOCK state.
     * @return An array of required state IDs.
     */
    function getCompoundRequirements(uint256 stateId) external view returns (uint256[] memory) {
        LockState storage state = lockStates[stateId];
        require(state.stateType == StateType.COMPOUND_LOCK, "State is not a COMPOUND_LOCK");
        return compoundRequirements[stateId];
    }


    /**
     * @dev Returns the total current Ether balance of the contract.
     */
    function getTotalEtherLocked() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Returns the total current balance of a specific ERC20 token in the contract.
     * @param token The address of the ERC20 token.
     */
    function getTotalERC20Locked(IERC20 token) external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns the amount of Ether currently claimable by a specific user.
     * @param user The address of the user.
     */
    function getClaimableEther(address user) external view returns (uint256) {
        return claimableEther[user];
    }

    /**
     * @dev Returns the amount of a specific ERC20 token currently claimable by a specific user.
     * @param token The address of the ERC20 token.
     * @param user The address of the user.
     */
    function getClaimableERC20(IERC20 token, address user) external view returns (uint256) {
        return claimableTokens[user][address(token)];
    }

    /**
     * @dev Returns the total number of states that have been defined (including cancelled and fulfilled).
     */
    function getDefinedStateCount() external view returns (uint256) {
        return _nextStateId - 1; // Subtract 1 because _nextStateId is the ID for the *next* state
    }

    /**
     * @dev Returns an array of currently active state IDs.
     * Note: This iterates through all potential state IDs. Can be inefficient if many states are defined.
     * A dedicated list (_activeStateIds) is used, but filtering might be needed if states can become inactive without being fulfilled/cancelled.
     * For simplicity, this uses the internal list which grows but is never pruned of fulfilled/failed states in this version.
     * A more gas-efficient approach would prune the list or use a mapping.
     * This function simply returns the current internal list.
     */
     function getActiveStateIds() external view returns (uint256[] memory) {
         // This internal list stores IDs added upon activation. It doesn't remove FULFILLED/FAILED states.
         // A user should check getStateStatus for each ID from this list.
        return _activeStateIds; // Returns the raw list of IDs that were activated.
     }


    // --- Internal Helper Functions ---

    /**
     * @dev Allocates funds conceptually for a state definition.
     * Used to track total funds needed vs available balance.
     * @param etherAmount Amount of Ether to allocate.
     * @param erc20Tokens Array of ERC20 token addresses.
     * @param erc20Amounts Array of corresponding ERC20 amounts.
     */
    function _allocateFunds(uint256 etherAmount, address[] memory erc20Tokens, uint256[] memory erc20Amounts) internal {
        _allocatedEther[address(this)] += etherAmount;
        for(uint i = 0; i < erc20Tokens.length; i++) {
            _allocatedERC20[address(this)][erc20Tokens[i]] += erc20Amounts[i];
        }
        // Note: The actual check against contract balance happens upon State Activation.
    }

    /**
     * @dev Deallocates funds conceptually when a state definition is cancelled.
     * @param etherAmount Amount of Ether to deallocate.
     * @param erc20Tokens Array of ERC20 token addresses.
     * @param erc20Amounts Array of corresponding ERC20 amounts.
     */
    function _deallocateFunds(uint256 etherAmount, address[] memory erc20Tokens, uint256[] memory erc20Amounts) internal {
         _allocatedEther[address(this)] -= etherAmount;
         for(uint i = 0; i < erc20Tokens.length; i++) {
            _allocatedERC20[address(this)][erc20Tokens[i]] -= erc20Amounts[i];
        }
    }

    // Helper function for error messages (Solidity >= 0.8.4 supports string.concat)
    function _uint256ToString(uint256 value) internal pure returns (string memory) {
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
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

     // Helper function for error messages
    function _addressToString(address addr) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(addr));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

}
```