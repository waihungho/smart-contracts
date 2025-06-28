Okay, here is a Solidity smart contract concept called `QuantumVault`. It uses a metaphor of quantum states and measurement to create a dynamic, state-dependent distribution mechanism for ERC20 tokens. Users commit to potential "quantum states" and the final outcome is determined by a "measurement" event triggered by external factors (simulated here). Entangled commitments influence the distribution.

This concept combines elements of prediction markets (committing to outcomes) with a unique state-transition and entanglement-like modifier, aiming for originality outside common DeFi/NFT patterns.

---

**Smart Contract: QuantumVault**

**Outline:**

1.  **License & Pragmas**
2.  **Imports (ERC20)**
3.  **Error Definitions (Custom Errors)**
4.  **Enums:** Defines the possible states of the vault (Superposition, StateA, StateB, StateC, Measured).
5.  **Structs:**
    *   `Commitment`: Details of a user's stake associated with a potential state.
    *   `VaultPosition`: Aggregated view of a user's activity in the vault (committed, claimed, potential state).
    *   `EntanglementPair`: Links two commitments.
6.  **Events:** To log key actions (Commitment, Measurement, Claim, Entanglement).
7.  **State Variables:** Contract state, ERC20 address, measurement parameters, user data, commitment data, entanglement data, state totals.
8.  **Modifiers:** `onlyOwner`, `whenInState`, `whenNotInState`.
9.  **Constructor:** Initializes contract state, sets owner and ERC20 token.
10. **Admin Functions (Owner-only):**
    *   Set allowed potential states.
    *   Set measurement block and oracle address (simulated).
    *   Set claim unlock block.
    *   Simulate oracle data (for demo).
    *   Create/Remove Entanglement Pairs.
11. **User Functions:**
    *   `commitToState`: Deposit tokens, choose a potential state.
    *   `increaseCommitment`: Add tokens to existing commitment.
    *   `decreaseCommitment`: Withdraw *some* tokens from commitment before measurement (with potential penalty/lock).
    *   `revokeCommitment`: Withdraw *all* tokens from commitment before measurement (with penalty/lock).
    *   `triggerMeasurement`: Initiate the state measurement process after the designated block.
    *   `claimAssets`: Withdraw calculated share after measurement and unlock time.
12. **Internal/Pure Helper Functions:**
    *   `_calculateClaimableAmount`: Core logic to determine user share based on measured state, commitment, and entanglement.
    *   `_isValidPotentialState`: Check if a state is allowed for commitment.
13. **View Functions (Read-only):**
    *   Get current/measured state.
    *   Get measurement/claim unlock blocks.
    *   Get oracle address.
    *   Get commitment details.
    *   Get vault position details.
    *   Get total committed amounts (overall and per state).
    *   Get entanglement pair details.
    *   Get allowed potential states.
    *   Get estimated claimable amount *before* claiming (pure/view calculation).

**Function Summary:**

1.  `constructor(address _tokenAddress)`: Deploys the contract, sets owner and ERC20 token address.
2.  `setAllowedPotentialStates(VaultState[] memory _states)`: Owner sets which states users can commit to.
3.  `setMeasurementParameters(uint256 _measurementBlock, address _oracleAddress, uint256 _claimUnlockDelay)`: Owner sets measurement trigger block, oracle source (address placeholder), and claim delay post-measurement.
4.  `simulateOracleData(uint256 _simulatedValue)`: Owner sets a value to simulate external oracle data for measurement. For demo/testing.
5.  `createEntanglementPair(uint256 _commitmentId1, uint256 _commitmentId2)`: Owner links two commitments.
6.  `removeEntanglementPair(uint256 _pairId)`: Owner removes an entanglement link.
7.  `commitToState(VaultState _potentialState, uint256 _amount)`: User deposits `_amount` of ERC20 tokens, committing to `_potentialState`. Requires token approval beforehand.
8.  `increaseCommitment(uint256 _commitmentId, uint256 _amount)`: User adds more tokens to an existing commitment. Requires token approval.
9.  `decreaseCommitment(uint256 _commitmentId, uint256 _amount)`: User withdraws `_amount` from their commitment *before* measurement. May incur a penalty or lock remainder. (Implementation: Simple withdrawal for this example, no penalty).
10. `revokeCommitment(uint256 _commitmentId)`: User withdraws the full amount of a commitment *before* measurement. (Implementation: Simple withdrawal for this example, no penalty).
11. `triggerMeasurement()`: Any user can call this after `measurementBlock`. Uses simulated oracle data to determine `measuredState` and transitions vault state.
12. `_calculateClaimableAmount(address _user)`: Internal helper to compute the user's share based on `measuredState`, their commitment, and entanglement status.
13. `claimAssets()`: User withdraws their calculated share *after* measurement and `claimUnlockBlock`.
14. `getCurrentState()`: View function returning the current state of the vault.
15. `getMeasuredState()`: View function returning the state determined after measurement.
16. `getMeasurementBlock()`: View function returning the block number when measurement can be triggered.
17. `getClaimUnlockBlock()`: View function returning the block number when claims are possible.
18. `getOracleAddress()`: View function returning the address intended as the oracle source.
19. `getCommitmentDetails(uint256 _commitmentId)`: View function returning details of a specific commitment.
20. `getVaultPosition(address _user)`: View function returning the aggregated vault position details for a user.
21. `getTotalCommitted()`: View function returning the total amount of tokens committed in Superposition.
22. `getTotalCommittedPerState(VaultState _state)`: View function returning the total amount committed specifically to a potential state (before measurement).
23. `getEntanglementPair(uint256 _pairId)`: View function returning details of an entanglement pair.
24. `getAllowedPotentialStates()`: View function returning the list of states users can commit to.
25. `getEstimatedClaimableAmount(address _user)`: View function returning the *potential* amount a user could claim if measurement has occurred (calls internal calculation helper).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Smart Contract: QuantumVault

// Outline:
// 1. License & Pragmas
// 2. Imports (ERC20, Ownable, ReentrancyGuard)
// 3. Error Definitions (Custom Errors)
// 4. Enums: VaultState
// 5. Structs: Commitment, VaultPosition, EntanglementPair
// 6. Events: CommitmentMade, CommitmentIncreased, CommitmentDecreased, CommitmentRevoked,
//            Entangled, Disentangled, MeasurementTriggered, StateMeasured, AssetsClaimed
// 7. State Variables: Owner, ERC20 token, current state, measurement parameters, user data, commitment data,
//                     entanglement data, state totals, simulated oracle value.
// 8. Modifiers: onlyOwner, whenInState, whenNotInState
// 9. Constructor: Initializes contract
// 10. Admin Functions (Owner-only): Set states, measurement params, simulate oracle, manage entanglement.
// 11. User Functions: Commit, increase/decrease/revoke commitment, trigger measurement, claim assets.
// 12. Internal/Pure Helper Functions: Calculate claimable amount, check valid state.
// 13. View Functions (Read-only): Get state, params, data, totals.

// Function Summary:
// 1. constructor(address _tokenAddress): Deploys contract, sets owner & ERC20 token.
// 2. setAllowedPotentialStates(VaultState[] memory _states): Owner sets states available for commitment.
// 3. setMeasurementParameters(uint256 _measurementBlock, address _oracleAddress, uint256 _claimUnlockDelay): Owner sets measurement trigger block, oracle placeholder, and claim delay.
// 4. simulateOracleData(uint256 _simulatedValue): Owner sets a value simulating external oracle data for measurement.
// 5. createEntanglementPair(uint256 _commitmentId1, uint256 _commitmentId2): Owner links two commitments.
// 6. removeEntanglementPair(uint256 _pairId): Owner removes an entanglement link.
// 7. commitToState(VaultState _potentialState, uint256 _amount): User commits tokens to a potential state. Requires approval.
// 8. increaseCommitment(uint256 _commitmentId, uint256 _amount): User adds tokens to existing commitment. Requires approval.
// 9. decreaseCommitment(uint256 _commitmentId, uint256 _amount): User withdraws some tokens from commitment before measurement.
// 10. revokeCommitment(uint256 _commitmentId): User withdraws all tokens from commitment before measurement.
// 11. triggerMeasurement(): Any user triggers measurement after the designated block, determining measuredState.
// 12. _calculateClaimableAmount(address _user): Internal helper to compute user's claim based on measured state, commitment, and entanglement.
// 13. claimAssets(): User claims calculated share after measurement and unlock time.
// 14. getCurrentState(): Gets the current vault state.
// 15. getMeasuredState(): Gets the determined state after measurement.
// 16. getMeasurementBlock(): Gets the measurement trigger block.
// 17. getClaimUnlockBlock(): Gets the claim unlock block.
// 18. getOracleAddress(): Gets the oracle placeholder address.
// 19. getCommitmentDetails(uint256 _commitmentId): Gets details for a specific commitment ID.
// 20. getVaultPosition(address _user): Gets the aggregated vault position for a user.
// 21. getTotalCommitted(): Gets the total tokens committed in Superposition.
// 22. getTotalCommittedPerState(VaultState _state): Gets total committed for a specific potential state.
// 23. getEntanglementPair(uint256 _pairId): Gets details for an entanglement pair ID.
// 24. getAllowedPotentialStates(): Gets the list of states allowed for commitment.
// 25. getEstimatedClaimableAmount(address _user): View calculates the potential claimable amount if measured.

// Custom Errors
error InvalidState();
error AlreadyInState(VaultState requiredState);
error NotInState(VaultState requiredState);
error MeasurementNotTriggered();
error ClaimingNotUnlocked();
error InsufficientCommitmentAmount();
error InvalidPotentialState();
error CommitmentNotFound();
error ZeroAmount();
error AlreadyClaimed();
error MeasurementBlockNotReached();
error AlreadyMeasured();
error NotOwner(); // Replaced by Ownable, but good for consistency if not using Ownable
error CommitmentAlreadyEntangled();
error CannotEntangleSameCommitment();
error EntanglementNotFound();

contract QuantumVault is Ownable, ReentrancyGuard {
    IERC20 public immutable token;

    enum VaultState {
        Superposition, // Initial state, users can commit
        StateA,        // Possible measured state A
        StateB,        // Possible measured state B
        StateC,        // Possible measured state C
        Measured       // Final state after measurement
    }

    VaultState public currentState;
    VaultState public measuredState; // Only set when state becomes Measured

    // Measurement Parameters
    uint256 public measurementBlock;
    address public oracleAddress; // Placeholder for an actual oracle address
    uint256 public claimUnlockBlock; // Block number after measurement when claims are possible

    // --- Data Structures ---

    struct Commitment {
        address user;
        uint256 amount;
        VaultState potentialStateChosen;
        bool isEntangled;
        uint256 entanglementPairId; // ID of the pair this commitment belongs to
    }

    struct VaultPosition {
        uint256 committedAmount; // Total amount committed by the user across all their commitments
        uint256 claimedAmount;   // Total amount claimed by the user
        // Note: A user can have multiple commitments, but their Position aggregates amounts.
        // Potential state chosen for a user is less relevant than their individual commitments.
        uint256[] commitmentIds; // List of commitment IDs owned by this user
    }

    struct EntanglementPair {
        uint256 commitmentId1;
        uint256 commitmentId2;
        // Maybe add a type or modifier for entanglement effect later
    }

    // --- State Mappings & Variables ---

    mapping(address => VaultPosition) public vaultPositions;
    mapping(uint256 => Commitment) public commitments;
    uint256 private nextCommitmentId = 1;

    mapping(uint256 => EntanglementPair) public entanglementPairs;
    uint256 private nextEntanglementPairId = 1;

    // Keep track of total committed amounts per potential state (before measurement)
    mapping(VaultState => uint256) public totalCommittedPerState;
    uint256 public totalCommittedOverall; // Sum of all commitments

    // Configuration
    mapping(VaultState => bool) private isAllowedPotentialState;
    VaultState[] public allowedPotentialStates;

    // Simulation variable for oracle data (owner controlled for demo)
    uint256 private simulatedOracleValue;

    // --- Events ---

    event CommitmentMade(address indexed user, uint256 commitmentId, VaultState potentialState, uint256 amount);
    event CommitmentIncreased(address indexed user, uint256 commitmentId, uint256 newAmount);
    event CommitmentDecreased(address indexed user, uint256 commitmentId, uint256 newAmount);
    event CommitmentRevoked(address indexed user, uint256 commitmentId, uint256 returnedAmount);
    event Entangled(uint256 indexed pairId, uint256 indexed commitmentId1, uint256 indexed commitmentId2);
    event Disentangled(uint256 indexed pairId, uint256 indexed commitmentId1, uint256 indexed commitmentId2);
    event MeasurementTriggered(uint256 indexed triggerBlock, uint256 oracleSimValue);
    event StateMeasured(VaultState indexed measuredState, uint256 claimUnlockBlock);
    event AssetsClaimed(address indexed user, uint256 amountClaimed);

    // --- Modifiers ---

    modifier whenInState(VaultState _state) {
        if (currentState != _state) revert NotInState(_state);
        _;
    }

    modifier whenNotInState(VaultState _state) {
        if (currentState == _state) revert AlreadyInState(_state);
        _;
    }

    // --- Constructor ---

    constructor(address _tokenAddress) Ownable(msg.sender) {
        token = IERC20(_tokenAddress);
        currentState = VaultState.Superposition;
        // By default, no states are allowed for commitment until set by owner
    }

    // --- Admin Functions ---

    /**
     * @notice Owner sets the states users can commit to. Can only be called in Superposition.
     * @param _states Array of VaultState enums allowed for commitment.
     */
    function setAllowedPotentialStates(VaultState[] memory _states) external onlyOwner whenInState(VaultState.Superposition) {
        // Clear previous allowed states
        for (uint i = 0; i < allowedPotentialStates.length; i++) {
            isAllowedPotentialState[allowedPotentialStates[i]] = false;
        }
        delete allowedPotentialStates;

        // Set new allowed states
        for (uint i = 0; i < _states.length; i++) {
            VaultState state = _states[i];
            // Ensure states are valid commitment states (not Superposition or Measured)
            if (state == VaultState.Superposition || state == VaultState.Measured) {
                revert InvalidPotentialState();
            }
            if (!isAllowedPotentialState[state]) { // Prevent duplicates
                isAllowedPotentialState[state] = true;
                allowedPotentialStates.push(state);
            }
        }
    }

    /**
     * @notice Owner sets the block for measurement trigger, oracle address placeholder, and claim unlock delay.
     * @param _measurementBlock Block number when triggerMeasurement becomes callable.
     * @param _oracleAddress Address of the oracle contract (placeholder).
     * @param _claimUnlockDelay Number of blocks after measurement block when claims are unlocked.
     */
    function setMeasurementParameters(
        uint256 _measurementBlock,
        address _oracleAddress,
        uint256 _claimUnlockDelay
    ) external onlyOwner whenInState(VaultState.Superposition) {
        // require(_measurementBlock > block.number, "Measurement block must be in the future"); // Optional, maybe owner sets past block to trigger immediately?
        measurementBlock = _measurementBlock;
        oracleAddress = _oracleAddress;
        // Claim unlock block will be set when measurement is triggered: block.number + _claimUnlockDelay
    }

    /**
     * @notice Owner sets a simulated value for oracle data. For testing/demo purposes.
     *         An actual contract would fetch this from a real oracle.
     * @param _simulatedValue The value to simulate from the oracle.
     */
    function simulateOracleData(uint256 _simulatedValue) external onlyOwner {
        // Can be set anytime, but only used during triggerMeasurement.
        simulatedOracleValue = _simulatedValue;
    }

    /**
     * @notice Owner creates an entanglement link between two existing commitments.
     *         Can only be done in Superposition.
     * @param _commitmentId1 ID of the first commitment.
     * @param _commitmentId2 ID of the second commitment.
     */
    function createEntanglementPair(uint256 _commitmentId1, uint256 _commitmentId2) external onlyOwner whenInState(VaultState.Superposition) {
        Commitment storage c1 = commitments[_commitmentId1];
        Commitment storage c2 = commitments[_commitmentId2];

        if (c1.user == address(0) || c2.user == address(0)) revert CommitmentNotFound();
        if (_commitmentId1 == _commitmentId2) revert CannotEntangleSameCommitment();
        if (c1.isEntangled) revert CommitmentAlreadyEntangled();
        if (c2.isEntangled) revert CommitmentAlreadyEntangled();

        uint256 pairId = nextEntanglementPairId++;
        entanglementPairs[pairId] = EntanglementPair(_commitmentId1, _commitmentId2);

        c1.isEntangled = true;
        c1.entanglementPairId = pairId;
        c2.isEntangled = true;
        c2.entanglementPairId = pairId;

        emit Entangled(pairId, _commitmentId1, _commitmentId2);
    }

    /**
     * @notice Owner removes an entanglement link. Can only be done in Superposition.
     * @param _pairId ID of the entanglement pair.
     */
    function removeEntanglementPair(uint256 _pairId) external onlyOwner whenInState(VaultState.Superposition) {
        EntanglementPair storage pair = entanglementPairs[_pairId];
        if (pair.commitmentId1 == 0 && pair.commitmentId2 == 0) revert EntanglementNotFound();

        Commitment storage c1 = commitments[pair.commitmentId1];
        Commitment storage c2 = commitments[pair.commitmentId2];

        c1.isEntangled = false;
        c1.entanglementPairId = 0;
        c2.isEntangled = false;
        c2.entanglementPairId = 0;

        delete entanglementPairs[_pairId];

        emit Disentangled(_pairId, pair.commitmentId1, pair.commitmentId2);
    }

    // --- User Functions ---

    /**
     * @notice Allows a user to commit tokens to a potential vault state.
     *         Can only be called in Superposition.
     * @param _potentialState The state the user is committing to. Must be allowed.
     * @param _amount The amount of ERC20 tokens to commit. Requires prior approval.
     */
    function commitToState(VaultState _potentialState, uint256 _amount) external nonReentrant whenInState(VaultState.Superposition) {
        if (_amount == 0) revert ZeroAmount();
        if (!_isValidPotentialState(_potentialState)) revert InvalidPotentialState();

        // Transfer tokens from user to contract
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientCommitmentAmount(); // Or handle token transfer error specifically

        uint256 commitmentId = nextCommitmentId++;
        commitments[commitmentId] = Commitment({
            user: msg.sender,
            amount: _amount,
            potentialStateChosen: _potentialState,
            isEntangled: false,
            entanglementPairId: 0
        });

        VaultPosition storage pos = vaultPositions[msg.sender];
        pos.committedAmount += _amount;
        pos.commitmentIds.push(commitmentId);

        totalCommittedPerState[_potentialState] += _amount;
        totalCommittedOverall += _amount;

        emit CommitmentMade(msg.sender, commitmentId, _potentialState, _amount);
    }

    /**
     * @notice Allows a user to add more tokens to an existing commitment.
     *         Can only be called in Superposition.
     * @param _commitmentId The ID of the commitment to increase.
     * @param _amount The additional amount of ERC20 tokens to commit. Requires prior approval.
     */
    function increaseCommitment(uint256 _commitmentId, uint256 _amount) external nonReentrant whenInState(VaultState.Superposition) {
        if (_amount == 0) revert ZeroAmount();
        Commitment storage commitment = commitments[_commitmentId];
        if (commitment.user != msg.sender) revert CommitmentNotFound();

        // Transfer tokens from user to contract
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert InsufficientCommitmentAmount(); // Or handle token transfer error specifically

        commitment.amount += _amount;
        vaultPositions[msg.sender].committedAmount += _amount;
        totalCommittedPerState[commitment.potentialStateChosen] += _amount;
        totalCommittedOverall += _amount;

        emit CommitmentIncreased(msg.sender, _commitmentId, commitment.amount);
    }

    /**
     * @notice Allows a user to withdraw a portion of their commitment before measurement.
     *         Can only be called in Superposition. No penalty for simplicity in this example.
     * @param _commitmentId The ID of the commitment to decrease.
     * @param _amount The amount to withdraw.
     */
    function decreaseCommitment(uint256 _commitmentId, uint256 _amount) external nonReentrant whenInState(VaultState.Superposition) {
        if (_amount == 0) revert ZeroAmount();
        Commitment storage commitment = commitments[_commitmentId];
        if (commitment.user != msg.sender) revert CommitmentNotFound();
        if (commitment.amount < _amount) revert InsufficientCommitmentAmount();

        commitment.amount -= _amount;
        vaultPositions[msg.sender].committedAmount -= _amount;
        totalCommittedPerState[commitment.potentialStateChosen] -= _amount;
        totalCommittedOverall -= _amount;

        // Transfer tokens back to user
        bool success = token.transfer(msg.sender, _amount);
        if (!success) {
            // Handle token transfer failure - ideally re-add amount or use a pull pattern
            // For this example, we assume transfer succeeds or revert
            revert();
        }

        emit CommitmentDecreased(msg.sender, _commitmentId, commitment.amount);
    }

    /**
     * @notice Allows a user to fully revoke an existing commitment before measurement.
     *         Can only be called in Superposition. No penalty for simplicity in this example.
     * @param _commitmentId The ID of the commitment to revoke.
     */
    function revokeCommitment(uint256 _commitmentId) external nonReentrant whenInState(VaultState.Superposition) {
        Commitment storage commitment = commitments[_commitmentId];
        if (commitment.user != msg.sender) revert CommitmentNotFound();

        uint256 amountToReturn = commitment.amount;
        VaultState stateRevoked = commitment.potentialStateChosen;

        // Update state totals immediately
        vaultPositions[msg.sender].committedAmount -= amountToReturn;
        totalCommittedPerState[stateRevoked] -= amountToReturn;
        totalCommittedOverall -= amountToReturn;

        // Remove from user's commitment list (simple loop, optimize for large arrays if needed)
        uint256[] storage commitmentIds = vaultPositions[msg.sender].commitmentIds;
        for (uint i = 0; i < commitmentIds.length; i++) {
            if (commitmentIds[i] == _commitmentId) {
                commitmentIds[i] = commitmentIds[commitmentIds.length - 1];
                commitmentIds.pop();
                break;
            }
        }

        // Remove entanglement if any
        if (commitment.isEntangled) {
            uint256 pairId = commitment.entanglementPairId;
            EntanglementPair storage pair = entanglementPairs[pairId];
            uint256 otherCommitmentId = (pair.commitmentId1 == _commitmentId) ? pair.commitmentId2 : pair.commitmentId1;
            Commitment storage otherCommitment = commitments[otherCommitmentId];

            otherCommitment.isEntangled = false;
            otherCommitment.entanglementPairId = 0;

            delete entanglementPairs[pairId];
            emit Disentangled(pairId, _commitmentId, otherCommitmentId);
        }

        // Delete the commitment data
        delete commitments[_commitmentId];

        // Transfer tokens back to user
        bool success = token.transfer(msg.sender, amountToReturn);
        if (!success) {
             // Handle token transfer failure - ideally re-add amount or use a pull pattern
            // For this example, we assume transfer succeeds or revert
            revert();
        }


        emit CommitmentRevoked(msg.sender, _commitmentId, amountToReturn);
    }


    /**
     * @notice Triggers the state measurement process. Can be called by anyone after the measurement block.
     *         Transitions state from Superposition to Measured. Determines measuredState based on oracle data.
     */
    function triggerMeasurement() external nonReentrant whenInState(VaultState.Superposition) {
        if (block.number < measurementBlock) revert MeasurementBlockNotReached();
        if (measuredState != VaultState.Superposition) revert AlreadyMeasured(); // Should not happen due to state check, but extra safety

        // --- Quantum Measurement Simulation Logic ---
        // This is where the "oracle" data influences the outcome.
        // In a real scenario, this would securely fetch data from oracleAddress.
        // Here, we use the pre-set simulatedOracleValue.

        uint256 outcomeIndicator = simulatedOracleValue;

        // Example deterministic mapping based on simulated value:
        if (outcomeIndicator % 3 == 0) {
            measuredState = VaultState.StateA;
        } else if (outcomeIndicator % 3 == 1) {
            measuredState = VaultState.StateB;
        } else {
            measuredState = VaultState.StateC;
        }
        // --- End Simulation Logic ---

        currentState = VaultState.Measured;
        claimUnlockBlock = block.number + (measurementBlock > 0 ? (claimUnlockBlock - measurementBlock) : 0); // Calculate unlock block based on delay
        if (measurementBlock == 0) { // Handle case where measurementBlock was set to 0 or current block
            claimUnlockBlock = block.number + (claimUnlockBlock > 0 ? claimUnlockBlock : 0); // Just use the delay
        }


        emit MeasurementTriggered(block.number, simulatedOracleValue);
        emit StateMeasured(measuredState, claimUnlockBlock);
    }


    /**
     * @notice Allows a user to claim their share of the vault assets after measurement and unlock.
     *         Can only be called in Measured state after claimUnlockBlock.
     */
    function claimAssets() external nonReentrant whenInState(VaultState.Measured) {
        if (block.number < claimUnlockBlock) revert ClaimingNotUnlocked();

        VaultPosition storage pos = vaultPositions[msg.sender];
        if (pos.committedAmount == 0) {
             // User had no commitments or revoked them all
             // Although claimableAmount will be 0, this check is faster
             revert InsufficientCommitmentAmount();
        }
        if (pos.committedAmount == pos.claimedAmount) revert AlreadyClaimed(); // Check if the total committed amount for this user has been claimed

        uint256 claimableAmount = _calculateClaimableAmount(msg.sender);

        if (claimableAmount == 0) {
            // User is not eligible for payout in the measured state
             pos.claimedAmount = pos.committedAmount; // Mark as fully processed/claimed 0
             return; // Exit without transferring tokens
        }


        // Ensure user doesn't claim more than once across all commitments
        // We track claimedAmount in VaultPosition
        uint256 previouslyClaimed = pos.claimedAmount;
        uint256 amountToTransfer = claimableAmount - previouslyClaimed; // Deduct already claimed if any (should be 0 first time)

        if (amountToTransfer == 0) revert AlreadyClaimed();

        pos.claimedAmount = claimableAmount; // Update claimed amount to the *total* calculated entitlement

        // Transfer tokens to user
        bool success = token.transfer(msg.sender, amountToTransfer);
        if (!success) {
            // Handle token transfer failure - maybe revert or emit event for manual intervention
            // For this example, we assume transfer succeeds or revert
            pos.claimedAmount = previouslyClaimed; // Revert state change if transfer fails
            revert();
        }

        emit AssetsClaimed(msg.sender, amountToTransfer);
    }

    // --- Internal/Pure Helper Functions ---

    /**
     * @notice Internal pure function to check if a state is allowed for user commitment.
     * @param _state The state to check.
     * @return bool True if the state is allowed for commitment.
     */
    function _isValidPotentialState(VaultState _state) internal view returns (bool) {
        return isAllowedPotentialState[_state];
    }


    /**
     * @notice Pure function to calculate the amount of tokens a user is eligible to claim
     *         based on the measured state, their commitments, and any entanglement.
     *         This function contains the core distribution logic.
     *         **Note:** This calculation logic is simplified and illustrative.
     *         Complex real-world distribution rules might require more sophisticated logic,
     *         potentially iterating over all commitments or using pre-calculated values.
     *         This version calculates based on the user's total committed amount and specific rules.
     * @param _user The address of the user.
     * @return uint256 The calculated claimable amount for the user.
     */
    function _calculateClaimableAmount(address _user) internal view returns (uint256) {
        VaultPosition storage pos = vaultPositions[_user];
        if (pos.committedAmount == 0) return 0; // User has no stake

        uint256 totalCommittedForMeasuredState = totalCommittedPerState[measuredState]; // Total committed *to* the measured state

        uint256 userTotalCommitted = pos.committedAmount;
        uint256 userCommittedToMeasuredState = 0;
        uint256 userCommittedToOtherStates = 0;
        bool isAnyCommitmentEntangledMatchingMeasured = false; // Does any user commitment match the measured state *and* is entangled?
        bool isAnyCommitmentEntangledNotMatchingMeasured = false; // Does any user commitment *not* match measured *and* is entangled?


        // Iterate over user's commitments to get more granular data
        // This loop can become gas-intensive with many commitments per user.
        // In a production system, pre-calculating these or using a pull pattern with per-commitment claiming might be better.
        for(uint i = 0; i < pos.commitmentIds.length; i++) {
            uint256 commitmentId = pos.commitmentIds[i];
            Commitment storage commitment = commitments[commitmentId]; // Use storage to avoid copying large struct if needed elsewhere

            if (commitment.potentialStateChosen == measuredState) {
                userCommittedToMeasuredState += commitment.amount;
                 if (commitment.isEntangled) {
                     // Check entanglement rule: If an entangled commitment matches the measured state,
                     // does its pair also match? This could add a bonus.
                     // Simplified: Just flag if any matching commitment is entangled.
                     isAnyCommitmentEntangledMatchingMeasured = true;
                 }
            } else {
                userCommittedToOtherStates += commitment.amount;
                if (commitment.isEntangled) {
                    isAnyCommitmentEntangledNotMatchingMeasured = true;
                }
            }
        }

        // --- Distribution Logic Based on Measured State ---
        uint256 totalVaultBalance = token.balanceOf(address(this));
        uint256 totalDistributable = totalCommittedOverall; // Distribute only what was committed for simplicity

        if (totalDistributable == 0) return 0; // Avoid division by zero

        if (measuredState == VaultState.StateA) {
            // StateA: Distribute equally among *all* users who committed anything.
            // Total unique users who committed: Need to count unique addresses in vaultPositions.
            // Counting unique users on-chain is gas-intensive.
            // Alternative: Distribute based on total committed proportionally.
            // Let's use proportional distribution based on *any* commitment for simplicity.
            // Each user gets (userTotalCommitted / totalCommittedOverall) * totalDistributable
            // Simplified: Payout is simply their committed amount if StateA is measured? No, that's too simple.
            // Let's make StateA split `totalDistributable` proportionally among `totalCommittedOverall` regardless of chosen state.
            // This means everyone gets a share proportional to their total stake.
             return (userTotalCommitted * totalDistributable) / totalCommittedOverall;

        } else if (measuredState == VaultState.StateB) {
            // StateB: Primarily benefits those who committed to StateB, with a bonus for entanglement.
            // Distribute `totalDistributable` among those who committed to StateB.
            // A bonus pool or multiplier could be added for entangled StateB commitments.

            uint256 baseShare = 0;
            if (totalCommittedPerState[VaultState.StateB] > 0) {
                 // Base share is proportional to their commitment *specifically* to StateB
                 baseShare = (userCommittedToMeasuredState * totalDistributable) / totalCommittedPerState[VaultState.StateB];
            }

            uint256 entanglementBonus = 0;
            if (isAnyCommitmentEntangledMatchingMeasured) {
                // Example bonus: 10% of their base share if any of their matching commitments were entangled
                 entanglementBonus = (baseShare * 10) / 100;
            }

            return baseShare + entanglementBonus;

        } else if (measuredState == VaultState.StateC) {
            // StateC: Benefits those who *didn't* commit to StateB, and penalizes entangled non-StateB commitments.
             uint256 totalCommittedNotToStateB = totalCommittedOverall - totalCommittedPerState[VaultState.StateB];

             uint256 shareFromOthersPool = 0;
             if (totalCommittedNotToStateB > 0) {
                // Share is proportional to their commitment *not* to StateB
                 shareFromOthersPool = (userCommittedToOtherStates * totalDistributable) / totalCommittedNotToStateB;
             }

             uint256 entanglementPenalty = 0;
             if (isAnyCommitmentEntangledNotMatchingMeasured) {
                 // Example penalty: 20% penalty on their potential share if any of their non-matching commitments were entangled
                 entanglementPenalty = (shareFromOthersPool * 20) / 100;
             }

            // Ensure penalty doesn't exceed share
             if (entanglementPenalty > shareFromOthersPool) entanglementPenalty = shareFromOthersPool;


             return shareFromOthersPool - entanglementPenalty;

        } else {
            // Should not happen if measuredState is one of A, B, or C
             return 0;
        }
    }

    // --- View Functions ---

    /**
     * @notice Returns the current state of the vault.
     */
    function getCurrentState() external view returns (VaultState) {
        return currentState;
    }

     /**
     * @notice Returns the measured state after measurement has occurred.
     */
    function getMeasuredState() external view returns (VaultState) {
        if (currentState != VaultState.Measured) revert MeasurementNotTriggered();
        return measuredState;
    }

     /**
     * @notice Returns the block number when `triggerMeasurement` can be called.
     */
    function getMeasurementBlock() external view returns (uint256) {
        return measurementBlock;
    }

     /**
     * @notice Returns the block number when `claimAssets` can be called after measurement.
     */
    function getClaimUnlockBlock() external view returns (uint256) {
        if (currentState != VaultState.Measured) revert MeasurementNotTriggered();
        return claimUnlockBlock;
    }

     /**
     * @notice Returns the placeholder address for the oracle.
     */
    function getOracleAddress() external view returns (address) {
        return oracleAddress;
    }

    /**
     * @notice Returns the details of a specific commitment by its ID.
     * @param _commitmentId The ID of the commitment.
     */
    function getCommitmentDetails(uint256 _commitmentId) external view returns (Commitment memory) {
        if (commitments[_commitmentId].user == address(0)) revert CommitmentNotFound();
        return commitments[_commitmentId];
    }

    /**
     * @notice Returns the aggregated vault position details for a user.
     * @param _user The address of the user.
     */
    function getVaultPosition(address _user) external view returns (VaultPosition memory) {
        return vaultPositions[_user];
    }

     /**
     * @notice Returns the total amount of tokens committed across all users before measurement.
     */
    function getTotalCommitted() external view returns (uint256) {
        return totalCommittedOverall;
    }

     /**
     * @notice Returns the total amount of tokens committed specifically to a potential state (before measurement).
     * @param _state The potential state.
     */
    function getTotalCommittedPerState(VaultState _state) external view returns (uint256) {
         if (_state == VaultState.Superposition || _state == VaultState.Measured) revert InvalidPotentialState();
        return totalCommittedPerState[_state];
    }

    /**
     * @notice Returns the details of an entanglement pair by its ID.
     * @param _pairId The ID of the entanglement pair.
     */
    function getEntanglementPair(uint256 _pairId) external view returns (EntanglementPair memory) {
        if (entanglementPairs[_pairId].commitmentId1 == 0 && entanglementPairs[_pairId].commitmentId2 == 0) revert EntanglementNotFound();
        return entanglementPairs[_pairId];
    }

    /**
     * @notice Returns the list of states that are currently allowed for user commitment.
     */
    function getAllowedPotentialStates() external view returns (VaultState[] memory) {
        return allowedPotentialStates;
    }

     /**
     * @notice Estimates the amount a user could claim if the vault has been measured.
     *         Calls the internal calculation logic. This amount is not guaranteed until claimAssets is successful.
     * @param _user The address of the user.
     * @return uint256 The estimated claimable amount.
     */
    function getEstimatedClaimableAmount(address _user) external view returns (uint256) {
        if (currentState != VaultState.Measured) {
             // Can't estimate claim until measured state is known
             return 0;
        }
        // Note: This view function calls the internal logic, which is safe for gas
        // as it doesn't modify state. However, the internal logic itself might
        // be gas-intensive if the user has many commitments.
        return _calculateClaimableAmount(_user);
    }

    // Fallback/Receive functions are not strictly necessary for this design
    // as all interactions are via explicit functions.
    // receive() external payable {}
    // fallback() external payable {}
}
```