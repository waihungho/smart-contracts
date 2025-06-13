Okay, let's design a smart contract that incorporates several advanced, creative, and somewhat trendy concepts, using a metaphorical theme. We'll call it the "Quantum Vault".

The theme is inspired by quantum mechanics concepts:
*   **Superposition:** Assets in the vault exist in a locked state whose availability is uncertain until "observed" (conditions are met).
*   **Entanglement:** Release might depend on multiple independent parties or external events acting in conjunction.
*   **Observation/State Collapse:** Checking specific conditions triggers the "collapse" into a determinate state (available or not).
*   **Quantum Noise/Randomness:** External, unpredictable data (like from a VRF or oracle) can influence the state.
*   **Quantum Decay:** Time can change the probability or conditions of release.

**Disclaimer:** This contract uses "Quantum" as a metaphor for complex, conditional states and dependencies. It does *not* involve actual quantum computing principles or security, which are beyond the scope of current smart contract technology. It relies on standard cryptographic security provided by the blockchain.

---

**Smart Contract: QuantumVault**

**Theme:** A secure vault where asset release depends on fulfilling complex, multi-party, time-based, and external-data-dependent "quantum conditions," simulating concepts like superposition, entanglement, and observation.

**Outline:**

1.  **State Variables:** Store assets (ETH, ERC20, ERC721), define "quantum locks" with conditions, track entangled parties, manage oracle/VRF interaction states, user balances per lock.
2.  **Structs & Enums:** Define types for conditions, locks, and different condition behaviors.
3.  **Events:** Log key actions like deposits, withdrawals, lock creation, condition setting, observation requests/results, state collapse.
4.  **Modifiers:** Restrict access based on roles (owner, entangled party, oracle).
5.  **Core Vault Functionality:** Deposit and track various asset types.
6.  **Quantum Lock & Condition Management:** Create unique lock IDs, add/remove complex conditions (time, external data, party consent) to these locks. Define involved "entangled parties".
7.  **Observation & State Collapse:** Request external data ("quantum noise") via oracle/VRF, process the result via callback, check if all conditions for a specific lock ID are met ("state collapse").
8.  **Conditional Release:** Allow withdrawals only when the "quantum state has collapsed" (all conditions for the relevant lock ID are true).
9.  **Advanced Concepts:**
    *   Multi-dimensional locking based on complex condition combinations.
    *   Simulated Entanglement: Requiring consent from multiple *specific* parties, not just M-of-N generic.
    *   Time-based condition changes ("Quantum Decay").
    *   Re-Entanglement: Ability to relock assets under new conditions.
    *   Emergency Unravel: A time-gated or threshold-based escape hatch.
    *   Delegated Observation: Allowing a trusted party to trigger external data requests.
    *   Conditional Fees: Charging fees based on the complexity of the withdrawal or data involved.
    *   Partial Release: Allowing withdrawal of only a portion under certain states.
10. **Utility Functions:** View state, list locks, check party consent status, etc.

**Function Summary (at least 20):**

1.  `constructor`: Initializes contract, sets owner, oracle/VRF address.
2.  `depositEther`: Receives Ether into the vault, associating it with a specified lock ID for the sender.
3.  `depositERC20`: Receives ERC20 tokens, associating them with a specified lock ID for the sender (requires prior `approve`).
4.  `depositERC721`: Receives ERC721 tokens, associating them with a specified lock ID for the sender (requires prior `approve` or `setApprovalForAll`).
5.  `createQuantumLock`: Creates a new unique lock configuration (returns lock ID/index).
6.  `addConditionToLock`: Adds a specific `Condition` (type, value, target party/address) to an existing lock ID.
7.  `removeConditionFromLock`: Removes a specific `Condition` from a lock ID (potentially complex state management, handled with care).
8.  `setEntangledPartiesForLock`: Defines the specific addresses considered "entangled parties" relevant to a particular lock ID.
9.  `recordPartyConsent`: An entangled party explicitly records their consent for a specific condition within a lock ID.
10. `requestQuantumObservation`: Initiates a request to the oracle/VRF for external data needed for a condition in a lock ID.
11. `fulfillQuantumObservation`: Callback function (only callable by the designated oracle/VRF) that provides the external data result for a requested observation, updating the lock's state.
12. `checkQuantumStateCollapse`: A pure/view function to evaluate if *all* conditions for a given lock ID are currently met based on current contract state, time, and received oracle data/consents.
13. `withdrawEther`: Attempts to withdraw Ether for the caller from a specific lock ID. Succeeds only if `checkQuantumStateCollapse` for that lock ID is true for the caller's conditions.
14. `withdrawERC20`: Attempts to withdraw ERC20 tokens for the caller from a specific lock ID. Succeeds only if `checkQuantumStateCollapse` is true.
15. `withdrawERC721`: Attempts to withdraw ERC721 tokens for the caller from a specific lock ID. Succeeds only if `checkQuantumStateCollapse` is true.
16. `reEntangleAssets`: Allows the owner or possibly a designated manager to move unlocked (or potentially specific locked) assets from one lock ID to another set of conditions.
17. `initiateEmergencyUnravel`: Starts a potentially irreversible process (e.g., after a long delay) that might bypass standard conditions, possibly requiring a secondary step or minimal consensus.
18. `executeEmergencyUnravel`: Completes the emergency unlock initiated by `initiateEmergencyUnravel` if timer/secondary conditions are met.
19. `delegateObservationTrigger`: An entangled party can delegate the right to call `requestQuantumObservation` for their relevant locks to another address.
20. `getLockDetails`: View function to retrieve the configuration (conditions, parties) for a given lock ID.
21. `getUserAssetBalanceByLock`: View function to see a user's balance of a specific token within a specific lock ID.
22. `getPartyConsentStatus`: View function to check which entangled parties have consented for a specific condition or lock.
23. `setQuantumNoiseSource`: Owner function to update the oracle/VRF contract address.
24. `updateTimeDecayFactor`: Owner function to adjust parameters related to time-based conditions (e.g., how quickly a time-lock expires or security degrades).
25. `setConditionalFeeRate`: Owner function to set a fee percentage or fixed amount applied on successful withdrawals based on the complexity or type of conditions met (requires tracking condition types).
26. `claimConditionalFees`: Owner function to withdraw accumulated fees.
27. `getConditionStatus`: View function to check the current state (met/not met) for a *single* specific condition within a lock.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // Using for entangled parties might be useful

// Assuming an interface for your hypothetical Oracle/VRF contract
interface IQuantumNoiseOracle {
    function requestNoise(bytes32 _requestId, bytes calldata _params) external returns (bytes32);
    // Oracle calls back fulfillNoise(bytes32 _requestId, bytes calldata _result)
}

/// @title QuantumVault
/// @dev A conceptual smart contract modeling complex conditional asset release
///      using metaphors from quantum mechanics (superposition, entanglement, observation).
///      Assets are locked under "Quantum Locks" with multiple conditions
///      that must all be met ("state collapse") for withdrawal.
///      Includes multi-party consent, time-based elements, and external data dependencies.
contract QuantumVault is Ownable, ERC721Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Enum defining different types of conditions for a Quantum Lock.
    enum ConditionType {
        TimeLockUntil,           // Becomes true after a specific timestamp
        BlockNumberLockUntil,    // Becomes true after a specific block number (less reliable due to block time variance)
        MinimumBalanceERC20,     // Caller must have a minimum balance of a specific ERC20 outside the vault
        MinimumBalanceETH,       // Caller must have a minimum ETH balance outside the vault
        ExternalOracleData,      // Requires a specific result from an oracle request (linked by requestId)
        PartyConsent,            // Requires consent from a specific "entangled party" address
        VaultStateValueGreater   // A variable within the contract must be > a value (e.g., total deposits)
    }

    /// @dev Struct representing a single condition within a Quantum Lock.
    struct Condition {
        ConditionType conditionType;
        uint256 value;           // e.g., timestamp, block number, minimum balance, state value threshold
        address targetAddress;   // e.g., ERC20 token address, party address for consent
        bytes32 oracleRequestId; // Identifier for ExternalOracleData requests
        bytes32 oracleExpectedResult; // Expected hash/value from the oracle
    }

    /// @dev Struct representing a complete Quantum Lock configuration.
    struct QuantumLock {
        Condition[] conditions;
        EnumerableSet.AddressSet entangledParties; // Parties specifically relevant to this lock's conditions
        mapping(address => mapping(uint256 => bool)) partyConditionConsents; // partyAddress => conditionIndex => consented?
        mapping(bytes32 => bytes32) oracleResults; // requestId => actualResult
        mapping(bytes32 => bool) oracleRequestPending; // requestId => pending?
        bool emergencyUnravelInitiated;
        uint256 emergencyUnravelTimestamp;
    }

    // --- State Variables ---

    // Stores the configurations for each quantum lock. lockId starts from 1.
    QuantumLock[] public quantumLocks;

    // Maps user address => token address => lock ID => amount for ERC20
    mapping(address => mapping(address => mapping(uint255 => uint256))) public userERC20BalancesByLock;

    // Maps user address => lock ID => amount for Ether
    mapping(address => mapping(uint255 => uint256)) public userEtherBalancesByLock;

    // Maps user address => token address => lock ID => tokenId => exists? for ERC721
    mapping(address => mapping(address => mapping(uint255 => mapping(uint256 => bool)))) public userERC721HoldingsByLock;
    // To easily list ERC721s per lock, potentially need another mapping or struct
    // mapping(address => mapping(address => mapping(uint255 => uint256[]))) public userERC721TokenIdsByLock; // More complex to manage add/remove

    // Address of the oracle/VRF contract
    IQuantumNoiseOracle public quantumNoiseOracle;

    // Mapping to track delegated observation rights
    mapping(address => address) public delegatedObservationRights; // delegatee => partyAddress

    // Contract variable that can be used in VaultStateValueGreater condition
    uint256 public vaultGlobalStateValue = 0; // Owner can update this

    // Fee parameters
    uint256 public conditionalFeeBps = 0; // Basis points (1/100 of a percent)
    uint256 private totalConditionalFeesETH;

    // Emergency Unravel Parameters
    uint256 public emergencyUnravelDelay = 365 days; // Time delay after initiation

    // --- Events ---

    event EtherDeposited(address indexed user, uint255 indexed lockId, uint256 amount);
    event ERC20Deposited(address indexed user, address indexed token, uint255 indexed lockId, uint256 amount);
    event ERC721Deposited(address indexed user, address indexed token, uint255 indexed lockId, uint256 tokenId);

    event EtherWithdrawn(address indexed user, uint255 indexed lockId, uint256 amount);
    event ERC20Withdrawn(address indexed user, address indexed token, uint255 indexed lockId, uint256 amount);
    event ERC721Withdrawn(address indexed user, address indexed token, uint255 indexed lockId, uint256 tokenId);

    event QuantumLockCreated(uint255 indexed lockId, address indexed creator);
    event ConditionAddedToLock(uint255 indexed lockId, uint256 conditionIndex, ConditionType conditionType);
    event ConditionRemovedFromLock(uint255 indexed lockId, uint256 conditionIndex); // Careful with index validity after removal

    event EntangledPartySet(uint255 indexed lockId, address indexed party, bool isEntangled);
    event PartyConsentRecorded(uint255 indexed lockId, uint256 conditionIndex, address indexed party);

    event ObservationRequested(uint255 indexed lockId, uint256 conditionIndex, bytes32 indexed requestId);
    event ObservationFulfilled(bytes32 indexed requestId, bytes32 result);

    event StateCollapsed(uint255 indexed lockId, address indexed user); // Indicates conditions are met for a user/lock

    event ReEntangled(address indexed user, uint255 indexed oldLockId, uint255 indexed newLockId, uint256 amount); // For partial release or re-locking
    event EmergencyUnravelInitiated(uint255 indexed lockId, address indexed initiator);
    event EmergencyUnravelExecuted(uint255 indexed lockId);

    event DelegationSet(address indexed party, address indexed delegatee);
    event ConditionalFeeCollected(uint256 amount);

    /// @dev Constructor initializes the owner and the oracle/VRF address.
    /// @param _quantumNoiseOracle The address of the oracle/VRF contract.
    constructor(address _quantumNoiseOracle) Ownable(msg.sender) {
        quantumNoiseOracle = IQuantumNoiseOracle(_quantumNoiseOracle);
    }

    // --- Fallback/Receive ---
    receive() external payable {}
    fallback() external payable {} // Standard practice for receiving ETH

    // --- Core Vault Functionality ---

    /// @dev Deposits Ether into the vault under a specific lock ID for the caller.
    /// @param _lockId The ID of the quantum lock to associate the deposit with.
    function depositEther(uint255 _lockId) external payable nonReentrant {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        require(msg.value > 0, "Deposit amount must be greater than 0");

        userEtherBalancesByLock[msg.sender][_lockId] += msg.value;
        emit EtherDeposited(msg.sender, _lockId, msg.value);
    }

    /// @dev Deposits ERC20 tokens into the vault under a specific lock ID for the caller.
    ///      Requires caller to have pre-approved this contract to spend the tokens.
    /// @param _token The address of the ERC20 token.
    /// @param _lockId The ID of the quantum lock to associate the deposit with.
    /// @param _amount The amount of tokens to deposit.
    function depositERC20(IERC20 _token, uint255 _lockId, uint256 _amount) external nonReentrant {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        require(_amount > 0, "Deposit amount must be greater than 0");

        _token.safeTransferFrom(msg.sender, address(this), _amount);
        userERC20BalancesByLock[msg.sender][address(_token)][_lockId] += _amount;
        emit ERC20Deposited(msg.sender, address(_token), _lockId, _amount);
    }

    /// @dev Deposits ERC721 tokens into the vault under a specific lock ID for the caller.
    ///      Requires caller to have pre-approved this contract to transfer the token ID.
    /// @param _token The address of the ERC721 token.
    /// @param _lockId The ID of the quantum lock to associate the deposit with.
    /// @param _tokenId The ID of the ERC721 token to deposit.
    function depositERC721(IERC721 _token, uint255 _lockId, uint256 _tokenId) external nonReentrant {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        require(!userERC721HoldingsByLock[msg.sender][address(_token)][_lockId][_tokenId], "ERC721 already held under this lock");

        _token.safeTransferFrom(msg.sender, address(this), _tokenId);
        userERC721HoldingsByLock[msg.sender][address(_token)][_lockId][_tokenId] = true;
        // Potentially manage a list of tokenIds if needed for easier listing, but adds complexity
        emit ERC721Deposited(msg.sender, address(_token), _lockId, _tokenId);
    }

    // --- Quantum Lock & Condition Management ---

    /// @dev Creates a new, empty quantum lock configuration.
    /// @return The ID of the newly created lock.
    function createQuantumLock() external onlyOwner returns (uint255) {
        // lockId 0 is reserved or unused, starting from 1
        uint255 newLockId = quantumLocks.length + 1;
        quantumLocks.push(); // Creates a new empty QuantumLock at the end
        emit QuantumLockCreated(newLockId, msg.sender);
        return newLockId;
    }

    /// @dev Adds a specific condition to an existing quantum lock.
    /// @param _lockId The ID of the lock to add the condition to.
    /// @param _condition The Condition struct defining the new requirement.
    function addConditionToLock(uint255 _lockId, Condition calldata _condition) external onlyOwner {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1]; // Use 0-based index for array

        // Add validation based on ConditionType if needed (e.g., targetAddress required for PartyConsent)
        if (_condition.conditionType == ConditionType.PartyConsent) {
             require(_condition.targetAddress != address(0), "PartyConsent requires a target address");
        } else if (_condition.conditionType == ConditionType.ExternalOracleData) {
             require(_condition.oracleRequestId != bytes32(0), "ExternalOracleData requires a request ID");
             require(_condition.oracleExpectedResult != bytes32(0), "ExternalOracleData requires an expected result");
        }


        lock.conditions.push(_condition);
        emit ConditionAddedToLock(_lockId, lock.conditions.length - 1, _condition.conditionType);
    }

    /// @dev Removes a condition from a quantum lock by its index.
    ///      WARNING: Removing from the middle of an array can shift indices.
    ///      Users should be aware of the condition indices.
    /// @param _lockId The ID of the lock.
    /// @param _conditionIndex The index of the condition to remove.
    function removeConditionFromLock(uint255 _lockId, uint256 _conditionIndex) external onlyOwner {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1];
        require(_conditionIndex < lock.conditions.length, "Invalid condition index");

        // A simple way to remove from array is swap-and-pop, but it changes order
        // A more robust way is to mark as inactive or use a more complex data structure
        // For simplicity, we'll use swap-and-pop, warning about index changes.
        uint256 lastIndex = lock.conditions.length - 1;
        if (_conditionIndex != lastIndex) {
            lock.conditions[_conditionIndex] = lock.conditions[lastIndex];
            // Clean up mappings associated with the moved condition if any (e.g., consent for the moved condition)
            // This swap-and-pop approach makes mapping cleanup tricky if conditions are directly mapped.
            // A better approach for conditions with mappings would be to use a struct with an 'active' flag or an array of pointers/indices.
            // Given the complexity, let's simplify: removing invalidates previous consents for the *new* condition at this index.
            // For this contract's complexity, we'll proceed with swap-and-pop and its index-shifting implication for external calls checking indices.
        }
        lock.conditions.pop();

        // Clean up consents associated with the condition index being removed
        // This is complex if parties have consented to specific *indices*.
        // If consent is tied to condition *content* (hash of struct) or just a simple boolean per party per lock, it's easier.
        // Let's assume consents are per party per condition *index*. After removing condition `i`, index `lastIndex` is now at `i`.
        // Consents previously for `lastIndex` are now implicitly for index `i`. Consents previously for `i` are lost or need complex remapping.
        // For this example, we'll accept the complexity or warn users. A production system would need a more robust approach (e.g., linked list or inactive flag).
        // Example cleanup (simplified):
        // Iterate through all entangled parties for this lock
        // For each party, if they consented to `lastIndex`, mark them as having consented to `_conditionIndex` now.
        // delete lock.partyConditionConsents[party][lastIndex]; // This part is tricky without knowing all parties easily.
        // A mapping like `mapping(address => mapping(uint256 => bool))` where uint256 is the *original* condition index would be more robust but requires tracking original indices.

        emit ConditionRemovedFromLock(_lockId, _conditionIndex);
    }


    /// @dev Sets or unsets an address as an entangled party for a specific lock.
    /// @param _lockId The ID of the lock.
    /// @param _partyAddress The address to manage.
    /// @param _isEntangled True to add, false to remove.
    function setEntangledPartyForLock(uint255 _lockId, address _partyAddress, bool _isEntangled) external onlyOwner {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        require(_partyAddress != address(0), "Invalid party address");
        QuantumLock storage lock = quantumLocks[_lockId - 1];

        bool changed;
        if (_isEntangled) {
            changed = lock.entangledParties.add(_partyAddress);
        } else {
            changed = lock.entangledParties.remove(_partyAddress);
        }

        if (changed) {
            emit EntangledPartySet(_lockId, _partyAddress, _isEntangled);
        }
    }

    /// @dev Allows an entangled party to record their consent for a specific condition within a lock.
    /// @param _lockId The ID of the lock.
    /// @param _conditionIndex The index of the condition requiring consent.
    function recordPartyConsent(uint255 _lockId, uint256 _conditionIndex) external {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1];
        require(lock.entangledParties.contains(msg.sender), "Caller is not an entangled party for this lock");
        require(_conditionIndex < lock.conditions.length, "Invalid condition index");
        require(lock.conditions[_conditionIndex].conditionType == ConditionType.PartyConsent, "Condition does not require party consent");
        require(lock.conditions[_conditionIndex].targetAddress == msg.sender, "Condition requires consent from a different party");

        lock.partyConditionConsents[msg.sender][_conditionIndex] = true;
        emit PartyConsentRecorded(_lockId, _conditionIndex, msg.sender);
    }

    // --- Observation & State Collapse ---

    /// @dev Requests external data ("quantum noise") from the oracle for a specific condition.
    ///      Requires the condition to be of type ExternalOracleData and a request ID to be set.
    ///      Only callable by owner or a delegated party.
    /// @param _lockId The ID of the lock containing the condition.
    /// @param _conditionIndex The index of the condition requiring oracle data.
    /// @param _oracleParams Parameters to pass to the oracle for the request.
    function requestQuantumObservation(uint255 _lockId, uint256 _conditionIndex, bytes calldata _oracleParams) external {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1];
        require(_conditionIndex < lock.conditions.length, "Invalid condition index");
        Condition storage condition = lock.conditions[_conditionIndex];

        require(condition.conditionType == ConditionType.ExternalOracleData, "Condition is not for external oracle data");
        require(condition.oracleRequestId != bytes32(0), "Condition does not have a request ID set");
        require(!lock.oracleRequestPending[condition.oracleRequestId], "Observation request already pending for this ID");

        // Check if caller is authorized: owner, entangled party, or delegated address
        require(msg.sender == owner() ||
                lock.entangledParties.contains(msg.sender) ||
                delegatedObservationRights[msg.sender] == msg.sender, // Or delegatedObservationRights[msg.sender] == specific party for this lock? Let's use the general delegation mapping for simplicity
                "Caller is not authorized to request observation");

        // Potentially require ETH/fee payment to the oracle here depending on oracle implementation
        // Assuming IQuantumNoiseOracle handles its own payment/callback mechanism

        bytes32 requestId = quantumNoiseOracle.requestNoise(condition.oracleRequestId, _oracleParams); // Oracle might return a confirmation ID, or use the provided ID
        // For simplicity, let's assume the oracle uses the provided ID or returns it.
        lock.oracleRequestPending[requestId] = true; // Mark request as pending using the ID that will be used in the callback
        emit ObservationRequested(_lockId, _conditionIndex, requestId);
    }

    /// @dev Callback function intended to be called only by the designated QuantumNoiseOracle.
    ///      Provides the result for a requested observation, updating the lock state.
    /// @param _requestId The request ID previously sent to the oracle.
    /// @param _result The result returned by the oracle (e.g., hash, value encoded).
    function fulfillQuantumObservation(bytes32 _requestId, bytes32 _result) external {
        require(msg.sender == address(quantumNoiseOracle), "Only the quantum noise oracle can fulfill requests");

        // Find which lock and condition this requestId belongs to. This requires iterating or a lookup map.
        // A lookup map `mapping(bytes32 => struct { uint255 lockId; uint256 conditionIndex; })` would be more efficient, but adds complexity to `addConditionToLock`.
        // For this example, we'll iterate (less gas efficient for many locks/conditions). A production system would use a lookup.

        uint255 foundLockId = 0;
        uint256 foundConditionIndex = 0;
        bool found = false;

        // Potentially optimize this loop if performance is critical (e.g., limit search space, use a lookup map)
        for (uint255 i = 0; i < quantumLocks.length; i++) {
            QuantumLock storage lock = quantumLocks[i];
            for (uint256 j = 0; j < lock.conditions.length; j++) {
                if (lock.conditions[j].conditionType == ConditionType.ExternalOracleData && lock.conditions[j].oracleRequestId == _requestId) {
                    foundLockId = i + 1; // Store 1-based ID
                    foundConditionIndex = j;
                    found = true;
                    break;
                }
            }
            if (found) break;
        }

        require(found, "Unknown oracle request ID");
        QuantumLock storage lock = quantumLocks[foundLockId - 1]; // Use 0-based index

        // Mark request as no longer pending and store result
        lock.oracleRequestPending[_requestId] = false;
        lock.oracleResults[_requestId] = _result;

        emit ObservationFulfilled(_requestId, _result);
        // Note: State collapse event is emitted by withdrawal functions, not here.
    }

    /// @dev Pure/View function to check if all conditions for a specific lock are currently met for a given user.
    ///      This is the "state collapse" check.
    /// @param _lockId The ID of the lock to check.
    /// @param _user The address of the user whose conditions (e.g., balances, consents) should be checked.
    /// @return True if all conditions are met, false otherwise.
    function checkQuantumStateCollapse(uint255 _lockId, address _user) public view returns (bool) {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1]; // Use 0-based index

        if (lock.conditions.length == 0) {
            // No conditions means it's always met (or is a misconfigured lock?)
            // Let's assume 0 conditions means it's "collapsed" by default.
            return true;
        }

        for (uint265 i = 0; i < lock.conditions.length; i++) {
            Condition storage condition = lock.conditions[i];
            bool conditionMet = false;

            if (condition.conditionType == ConditionType.TimeLockUntil) {
                conditionMet = block.timestamp >= condition.value;
            } else if (condition.conditionType == ConditionType.BlockNumberLockUntil) {
                 conditionMet = block.number >= condition.value;
            } else if (condition.conditionType == ConditionType.MinimumBalanceERC20) {
                 // Check user's external balance
                 require(condition.targetAddress != address(0), "MinimumBalanceERC20 condition requires token address");
                 // Assuming the user has approved this contract to check balance? No, check the user's own balance directly
                 // This might require a view function on the ERC20 contract or trusting the user's reported balance off-chain.
                 // Direct balance check in Solidity:
                 try IERC20(condition.targetAddress).balanceOf(_user) returns (uint256 balance) {
                     conditionMet = balance >= condition.value;
                 } catch {
                     // Handle token contract errors or non-standard tokens gracefully
                     conditionMet = false; // Assume condition not met if check fails
                 }
            } else if (condition.conditionType == ConditionType.MinimumBalanceETH) {
                 // Check user's external ETH balance
                 conditionMet = _user.balance >= condition.value;
            } else if (condition.conditionType == ConditionType.ExternalOracleData) {
                 require(condition.oracleRequestId != bytes32(0), "ExternalOracleData condition has no request ID");
                 // Check if oracle result has been received and matches the expected result
                 bytes32 receivedResult = lock.oracleResults[condition.oracleRequestId];
                 conditionMet = (receivedResult != bytes32(0) && receivedResult == condition.oracleExpectedResult);
            } else if (condition.conditionType == ConditionType.PartyConsent) {
                 // Check if the required party has consented for this specific condition index
                 require(condition.targetAddress != address(0), "PartyConsent condition requires target address");
                 conditionMet = lock.partyConditionConsents[condition.targetAddress][i]; // Check consent for this index
            } else if (condition.conditionType == ConditionType.VaultStateValueGreater) {
                 conditionMet = vaultGlobalStateValue > condition.value;
            }
            // Add checks for other ConditionTypes here

            if (!conditionMet) {
                return false; // If any single condition is NOT met, the state has not collapsed
            }
        }

        // If loop completes, all conditions were met
        return true;
    }

    /// @dev View function to check the status of a single condition within a lock.
    /// @param _lockId The ID of the lock.
    /// @param _conditionIndex The index of the condition to check.
    /// @param _user The user context for checking user-specific conditions (like balances).
    /// @return True if the specific condition is met, false otherwise.
    function getConditionStatus(uint255 _lockId, uint256 _conditionIndex, address _user) public view returns (bool) {
         require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
         QuantumLock storage lock = quantumLocks[_lockId - 1];
         require(_conditionIndex < lock.conditions.length, "Invalid condition index");

         Condition storage condition = lock.conditions[_conditionIndex];

         if (condition.conditionType == ConditionType.TimeLockUntil) {
             return block.timestamp >= condition.value;
         } else if (condition.conditionType == ConditionType.BlockNumberLockUntil) {
             return block.number >= condition.value;
         } else if (condition.conditionType == ConditionType.MinimumBalanceERC20) {
             require(condition.targetAddress != address(0), "MinimumBalanceERC20 condition requires token address");
             try IERC20(condition.targetAddress).balanceOf(_user) returns (uint256 balance) {
                 return balance >= condition.value;
             } catch {
                 return false;
             }
         } else if (condition.conditionType == ConditionType.MinimumBalanceETH) {
              return _user.balance >= condition.value;
         } else if (condition.conditionType == ConditionType.ExternalOracleData) {
              require(condition.oracleRequestId != bytes32(0), "ExternalOracleData condition has no request ID");
              bytes32 receivedResult = lock.oracleResults[condition.oracleRequestId];
              return (receivedResult != bytes32(0) && receivedResult == condition.oracleExpectedResult);
         } else if (condition.conditionType == ConditionType.PartyConsent) {
              require(condition.targetAddress != address(0), "PartyConsent condition requires target address");
              return lock.partyConditionConsents[condition.targetAddress][_conditionIndex];
         } else if (condition.conditionType == ConditionType.VaultStateValueGreater) {
              return vaultGlobalStateValue > condition.value;
         }
         // Add checks for other ConditionTypes here
         return false; // Unknown condition type
    }


    // --- Conditional Release ---

    /// @dev Allows a user to withdraw Ether from a specific lock if the state has collapsed.
    /// @param _lockId The ID of the lock.
    /// @param _amount The amount of Ether to withdraw.
    function withdrawEther(uint255 _lockId, uint256 _amount) external nonReentrant {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        require(_amount > 0, "Withdraw amount must be greater than 0");
        require(userEtherBalancesByLock[msg.sender][_lockId] >= _amount, "Insufficient balance in this lock");

        // Check if the 'quantum state' for this lock has collapsed (all conditions met)
        require(checkQuantumStateCollapse(_lockId, msg.sender), "Quantum state has not collapsed for this lock");

        userEtherBalancesByLock[msg.sender][_lockId] -= _amount;

        uint256 feeAmount = (_amount * conditionalFeeBps) / 10000; // Calculate fee in wei
        uint256 amountToSend = _amount - feeAmount;
        totalConditionalFeesETH += feeAmount;

        (bool success,) = msg.sender.call{value: amountToSend}("");
        require(success, "ETH transfer failed");

        emit EtherWithdrawn(msg.sender, _lockId, amountToSend);
        if(feeAmount > 0) emit ConditionalFeeCollected(feeAmount);
        emit StateCollapsed(_lockId, msg.sender); // Event indicating conditions were met for withdrawal
    }

    /// @dev Allows a user to withdraw ERC20 tokens from a specific lock if the state has collapsed.
    /// @param _token The address of the ERC20 token.
    /// @param _lockId The ID of the lock.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawERC20(IERC20 _token, uint255 _lockId, uint256 _amount) external nonReentrant {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        require(_amount > 0, "Withdraw amount must be greater than 0");
        require(userERC20BalancesByLock[msg.sender][address(_token)][_lockId] >= _amount, "Insufficient token balance in this lock");

        // Check if the 'quantum state' for this lock has collapsed
        require(checkQuantumStateCollapse(_lockId, msg.sender), "Quantum state has not collapsed for this lock");

        userERC20BalancesByLock[msg.sender][address(_token)][_lockId] -= _amount;

        // Fee calculation for ERC20 is tricky. Charging a percentage of ERC20 might require sending a different token (ETH fee)
        // Or having a fee in the same token (requires sending two transfers).
        // For simplicity, let's charge fees only in ETH or make it owner's responsibility off-chain.
        // Or, apply the fee to the *amount* transferred:
         uint256 feeAmount = (_amount * conditionalFeeBps) / 10000; // Calculate fee in tokens
         uint256 amountToSend = _amount - feeAmount;
         // Where do these ERC20 fees go? Owner address? Another contract? Let's burn/lock them in contract for simplicity
         // Or, add to owner's balance mapping for this token?

        _token.safeTransfer(msg.sender, amountToSend);
        // Fee amount tokens remain in the contract, potentially claimable by owner via a dedicated function.
        // For now, they just stay in the contract's balance.

        emit ERC20Withdrawn(msg.sender, address(_token), _lockId, amountToSend);
        // Note: No specific event for ERC20 fees collected for simplicity, they just accumulate in contract.
        emit StateCollapsed(_lockId, msg.sender); // Event indicating conditions were met for withdrawal
    }

    /// @dev Allows a user to withdraw an ERC721 token from a specific lock if the state has collapsed.
    /// @param _token The address of the ERC721 token.
    /// @param _lockId The ID of the lock.
    /// @param _tokenId The ID of the ERC721 token to withdraw.
    function withdrawERC721(IERC721 _token, uint255 _lockId, uint256 _tokenId) external nonReentrant {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        require(userERC721HoldingsByLock[msg.sender][address(_token)][_lockId][_tokenId], "ERC721 not held under this lock for user");

        // Check if the 'quantum state' for this lock has collapsed
        require(checkQuantumStateCollapse(_lockId, msg.sender), "Quantum state has not collapsed for this lock");

        userERC721HoldingsByLock[msg.sender][address(_token)][_lockId][_tokenId] = false;
        // Remove from token list if managed

        _token.safeTransfer(msg.sender, _tokenId);

        // Fee for ERC721 withdrawal? Could be a fixed ETH fee or percentage of some value?
        // Let's skip ERC721 specific fees for simplicity in this example.

        emit ERC721Withdrawn(msg.sender, address(_token), _lockId, _tokenId);
        emit StateCollapsed(_lockId, msg.sender); // Event indicating conditions were met for withdrawal
    }


    // --- Advanced Concepts ---

    /// @dev Allows a user to move *their* assets from one lock ID to another.
    ///      Can be used to apply new conditions after old ones are met (re-entanglement)
    ///      or potentially move assets between different sets of rules they control.
    ///      Requires the assets to *currently* be available under the old lock.
    /// @param _oldLockId The current lock ID the assets are under.
    /// @param _newLockId The lock ID to move the assets to.
    /// @param _token The address of the token (address(0) for ETH).
    /// @param _amountOrTokenId The amount for ERC20/ETH, or the tokenId for ERC721.
    /// @param _isERC721 Flag indicating if it's an ERC721 transfer.
    function reEntangleAssets(
        uint255 _oldLockId,
        uint255 _newLockId,
        address _token,
        uint256 _amountOrTokenId,
        bool _isERC721
    ) external nonReentrant {
        require(_oldLockId > 0 && _oldLockId <= quantumLocks.length, "Invalid old lock ID");
        require(_newLockId > 0 && _newLockId <= quantumLocks.length, "Invalid new lock ID");
        require(_oldLockId != _newLockId, "Cannot re-entangle to the same lock");

        // Assets must be available under the old lock's conditions *for this user*
        // This means either `checkQuantumStateCollapse(_oldLockId, msg.sender)` is true, OR
        // the user explicitly controls this relocking based on some other rule (e.g., owner of asset)
        // Let's require state collapse on the old lock for security/simplicity.
        require(checkQuantumStateCollapse(_oldLockId, msg.sender), "Assets not available under old lock conditions");


        if (_token == address(0)) { // ETH
            require(!_isERC721, "ETH cannot be ERC721");
            uint256 amount = _amountOrTokenId;
            require(userEtherBalancesByLock[msg.sender][_oldLockId] >= amount, "Insufficient ETH balance in old lock");
            userEtherBalancesByLock[msg.sender][_oldLockId] -= amount;
            userEtherBalancesByLock[msg.sender][_newLockId] += amount;
            emit ReEntangled(msg.sender, _oldLockId, _newLockId, amount);

        } else if (!_isERC721) { // ERC20
            IERC20 token = IERC20(_token);
            uint256 amount = _amountOrTokenId;
            require(userERC20BalancesByLock[msg.sender][address(token)][_oldLockId] >= amount, "Insufficient ERC20 balance in old lock");
            userERC20BalancesByLock[msg.sender][address(token)][_oldLockId] -= amount;
            userERC20BalancesByLock[msg.sender][address(token)][_newLockId] += amount;
            emit ReEntangled(msg.sender, _oldLockId, _newLockId, amount);

        } else { // ERC721
            IERC721 token = IERC721(_token);
            uint256 tokenId = _amountOrTokenId;
             require(userERC721HoldingsByLock[msg.sender][address(token)][_oldLockId][tokenId], "ERC721 not held in old lock");
             userERC721HoldingsByLock[msg.sender][address(token)][_oldLockId][tokenId] = false;
             userERC721HoldingsByLock[msg.sender][address(token)][_newLockId][tokenId] = true;
             // ERC721 transfer doesn't have an amount, just the tokenId. We'll use tokenId in the event amount field.
             emit ReEntangled(msg.sender, _oldLockId, _newLockId, tokenId);
        }
         // Note: This function only changes internal mappings, not actual token transfers.
         // The tokens stay within the QuantumVault contract address.
    }

    /// @dev Initiates the emergency unravel process for a specific lock.
    ///      This starts a timer after which assets under this lock may be claimable
    ///      by the original depositor, potentially bypassing standard conditions.
    ///      Only callable by owner initially, or perhaps after a very long time, any entangled party?
    ///      Let's make it owner-only to keep it simple.
    /// @param _lockId The ID of the lock to initiate unraveling.
    function initiateEmergencyUnravel(uint255 _lockId) external onlyOwner {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1];
        require(!lock.emergencyUnravelInitiated, "Emergency unravel already initiated");

        lock.emergencyUnravelInitiated = true;
        lock.emergencyUnravelTimestamp = block.timestamp;
        emit EmergencyUnravelInitiated(_lockId, msg.sender);
    }

    /// @dev Executes the emergency unravel for a lock after the delay has passed.
    ///      Allows the *original depositor* to claim their assets under this lock.
    ///      This completely bypasses the standard conditions check.
    /// @param _lockId The ID of the lock.
    /// @param _token The address of the token (address(0) for ETH).
    /// @param _isERC721 Flag indicating if it's an ERC721 (requires tokenId).
    /// @param _amountOrTokenId Amount for ETH/ERC20, or tokenId for ERC721.
    function executeEmergencyUnravel(
         uint255 _lockId,
         address _token,
         bool _isERC721,
         uint256 _amountOrTokenId
    ) external nonReentrant {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1];
        require(lock.emergencyUnravelInitiated, "Emergency unravel not initiated");
        require(block.timestamp >= lock.emergencyUnravelTimestamp + emergencyUnravelDelay, "Emergency unravel delay not passed");

        // The caller must be the original depositor for these specific assets under this lock.
        // This check requires tracking depositors per asset per lock, which isn't directly stored in our current mappings.
        // Our mappings only store balances/holdings per *user* per lock.
        // To implement this properly, deposits would need to map lockId => assetType => amount/tokenId => depositor.
        // For simplicity in this example, we'll allow the user who *currently holds* the balance/NFT under this lock to execute the unravel.
        // This is a security simplification for the example; a real contract needs depositor tracking.
        address currentUser = msg.sender; // Assuming current holder = original depositor for simplicity here

        if (_token == address(0)) { // ETH
            require(!_isERC721, "ETH cannot be ERC721");
            uint256 amount = _amountOrTokenId;
            require(userEtherBalancesByLock[currentUser][_lockId] >= amount, "Insufficient ETH balance for user in this lock");
            userEtherBalancesByLock[currentUser][_lockId] -= amount;
            (bool success,) = payable(currentUser).call{value: amount}("");
            require(success, "ETH transfer failed");

        } else if (!_isERC721) { // ERC20
            IERC20 token = IERC20(_token);
            uint256 amount = _amountOrTokenId;
             require(userERC20BalancesByLock[currentUser][address(token)][_lockId] >= amount, "Insufficient ERC20 balance for user in this lock");
             userERC20BalancesByLock[currentUser][address(token)][_lockId] -= amount;
            token.safeTransfer(currentUser, amount);

        } else { // ERC721
             IERC721 token = IERC721(_token);
             uint256 tokenId = _amountOrTokenId;
             require(userERC721HoldingsByLock[currentUser][address(token)][_lockId][tokenId], "ERC721 not held for user in this lock");
             userERC721HoldingsByLock[currentUser][address(token)][_lockId][tokenId] = false;
             token.safeTransfer(currentUser, tokenId);
        }

        emit EmergencyUnravelExecuted(_lockId);
        // Note: Consider state updates on the lock itself (e.g., mark as unraveled, prevent further operations)
        // For simplicity, we don't explicitly mark the lock, but zeroing out balances/holdings prevents re-claiming.
    }

    /// @dev Allows an entangled party to delegate the right to trigger `requestQuantumObservation`
    ///      for their relevant locks to another address.
    /// @param _delegatee The address that will be allowed to trigger observations on behalf of the caller.
    function delegateObservationTrigger(address _delegatee) external {
         // Check if the caller is an entangled party in *any* lock to qualify for delegation?
         // Or allow anyone to delegate? Allowing anyone is simpler. The check happens in requestQuantumObservation.
         delegatedObservationRights[msg.sender] = _delegatee;
         emit DelegationSet(msg.sender, _delegatee);
    }


    // --- Utility Functions (View/Pure) ---

    /// @dev Gets the details of a specific quantum lock.
    /// @param _lockId The ID of the lock.
    /// @return The QuantumLock struct.
    // Note: Returning the full struct with mappings is not possible.
    // Need to return relevant parts or provide specific getter functions.
    // Let's return the conditions and list entangled parties separately.
    function getLockDetails(uint255 _lockId) public view returns (Condition[] memory conditions, address[] memory entangledPartiesList) {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1];

        conditions = lock.conditions;
        entangledPartiesList = lock.entangledParties.values(); // Get all entangled parties

        return (conditions, entangledPartiesList);
    }

    /// @dev Gets a user's balance of a specific token within a specific lock.
    /// @param _user The address of the user.
    /// @param _token The address of the token (address(0) for ETH).
    /// @param _lockId The ID of the lock.
    /// @return The balance amount.
    function getUserAssetBalanceByLock(address _user, address _token, uint255 _lockId) public view returns (uint256) {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        if (_token == address(0)) {
            return userEtherBalancesByLock[_user][_lockId];
        } else {
            return userERC20BalancesByLock[_user][_token][_lockId];
        }
        // ERC721 doesn't have a sum balance, just existence. Need a different getter for ERC721.
    }

     /// @dev Checks if a user holds a specific ERC721 token under a specific lock.
     /// @param _user The address of the user.
     /// @param _token The address of the ERC721 token.
     /// @param _lockId The ID of the lock.
     /// @param _tokenId The ID of the ERC721 token.
     /// @return True if the user holds the NFT under this lock, false otherwise.
    function getUserERC721HoldingByLock(address _user, address _token, uint255 _lockId, uint256 _tokenId) public view returns (bool) {
         require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
         require(_token != address(0), "Token must be non-zero address for ERC721");
         return userERC721HoldingsByLock[_user][address(_token)][_lockId][_tokenId];
    }


    /// @dev Checks if a specific party has consented to a specific condition within a lock.
    /// @param _lockId The ID of the lock.
    /// @param _partyAddress The address of the party.
    /// @param _conditionIndex The index of the condition.
    /// @return True if the party has consented, false otherwise.
    function getPartyConsentStatus(uint255 _lockId, address _partyAddress, uint256 _conditionIndex) public view returns (bool) {
        require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
        QuantumLock storage lock = quantumLocks[_lockId - 1];
        require(_conditionIndex < lock.conditions.length, "Invalid condition index");
        require(lock.conditions[_conditionIndex].conditionType == ConditionType.PartyConsent, "Condition is not a PartyConsent type");
        require(lock.conditions[_conditionIndex].targetAddress == _partyAddress, "Consent check is for a different party");

        return lock.partyConditionConsents[_partyAddress][_conditionIndex];
    }

    /// @dev Owner function to update the global contract state value.
    /// @param _newValue The new value for vaultGlobalStateValue.
    function updateVaultGlobalStateValue(uint256 _newValue) external onlyOwner {
        vaultGlobalStateValue = _newValue;
    }

    /// @dev Owner function to set the basis points for conditional withdrawal fees.
    /// @param _bps Basis points (e.g., 100 for 1%). Max 10000 (100%).
    function setConditionalFeeRate(uint256 _bps) external onlyOwner {
        require(_bps <= 10000, "Fee rate cannot exceed 100%");
        conditionalFeeBps = _bps;
    }

    /// @dev Owner function to claim accumulated conditional ETH fees.
    function claimConditionalFees() external onlyOwner nonReentrant {
        uint256 fees = totalConditionalFeesETH;
        require(fees > 0, "No fees to claim");
        totalConditionalFeesETH = 0;
        (bool success,) = msg.sender.call{value: fees}("");
        require(success, "Fee transfer failed");
        emit ConditionalFeeCollected(fees); // Re-emit for transparency of withdrawal
    }

     /// @dev Owner function to update the emergency unravel delay period.
     /// @param _delaySeconds The new delay in seconds.
     function setEmergencyUnravelDelay(uint256 _delaySeconds) external onlyOwner {
         emergencyUnravelDelay = _delaySeconds;
     }

     /// @dev Gets the total number of quantum locks created.
     /// @return The number of locks.
     function getTotalLocks() external view returns (uint255) {
         return quantumLocks.length;
     }

     /// @dev Check if an observation request for a specific ID is pending.
     /// @param _lockId The lock ID.
     /// @param _requestId The oracle request ID.
     /// @return True if the request is pending, false otherwise.
     function isObservationPending(uint255 _lockId, bytes32 _requestId) external view returns (bool) {
         require(_lockId > 0 && _lockId <= quantumLocks.length, "Invalid lock ID");
         return quantumLocks[_lockId - 1].oracleRequestPending[_requestId];
     }
}
```