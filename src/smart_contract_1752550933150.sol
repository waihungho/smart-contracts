Okay, let's create a smart contract with advanced, creative, and numerous functionalities, conceptualizing something unique without directly duplicating common patterns. We'll design a contract called `QuantumVault` that manages conditional releases of funds based on a unique "state collapse" mechanism inspired by quantum superposition and entanglement, triggered by external data (oracles) and verifiable randomness.

**Concept:** Users deposit funds into a "Quantum Deposit". This deposit is initially in a state of "Superposition", meaning it has multiple predefined potential outcomes (different recipients, different conditions). The contract needs to be "observed" (a specific function called) to trigger a "State Collapse". This collapse resolves the superposition into one definitive outcome. The specific outcome chosen depends probabilistically on a combination of factors: the initial setup, external oracle data, verifiable randomness, and potentially the state of other linked ("entangled") deposits within the contract. Once collapsed, funds can only be claimed according to the rules of the resolved outcome state.

This involves managing complex states, handling external data triggers, probabilistic selection logic, and multi-stage conditional releases.

---

**Outline:**

1.  **State Management:** Enums for deposit states, structs for deposits and potential outcomes.
2.  **Configuration:** Admin functions to set parameters (fees, oracle addresses, entanglement factors).
3.  **Deposit Creation:** Users create deposits, defining multiple potential outcomes and their initial weights. Support for ETH and ERC20.
4.  **Deposit Modification (Pre-Collapse):** Users can potentially modify outcomes or weights before collapse.
5.  **Deposit Linking (Entanglement):** Allow linking deposits to influence their collapse probabilities.
6.  **Collapse Triggering:** Functions to request external data (simulated Oracle/VRF) and the main function to trigger the state collapse based on available data and internal state.
7.  **State Resolution:** Internal logic for calculating outcome probabilities based on all factors and selecting one via randomness.
8.  **Post-Collapse Actions:** Claiming funds based on the resolved outcome's conditions.
9.  **Querying:** View functions to inspect deposit states, potential outcomes, and collapse readiness.
10. **Admin/Maintenance:** Pause, withdraw fees, emergency actions.

---

**Function Summary:**

*   `constructor`: Deploys the contract, sets initial owner.
*   `pauseContract`: Owner function to pause certain actions.
*   `unpauseContract`: Owner function to unpause.
*   `transferOwnership`: Transfers contract ownership.
*   `renounceOwnership`: Renounces contract ownership.
*   `setFeeRecipient`: Sets the address receiving contract fees.
*   `setCollapseFee`: Sets the fee charged to trigger a state collapse.
*   `setEntanglementFactor`: Sets a parameter influencing entanglement calculation.
*   `setObservationWindow`: Sets a time window requirement for collapse triggers.
*   `setERC20Token`: Sets the ERC20 token address this vault handles.
*   `setMinimumDeposit`: Sets minimum required deposit amount (for ETH/ERC20).
*   `createQuantumDeposit`: Allows user to deposit ETH or ERC20 and define multiple potential outcomes with initial weights/conditions.
*   `addPotentialOutcomeState`: Adds a new potential outcome to a deposit in Superposition.
*   `updateOutcomeStateWeights`: Adjusts weights of potential outcomes for a deposit in Superposition.
*   `linkDepositsForEntanglement`: Links two Superposition deposits for mutual probabilistic influence during collapse.
*   `unlinkDeposits`: Removes an entanglement link between deposits.
*   `cancelDepositPreCollapse`: Allows depositor to cancel and withdraw before collapse, possibly with a penalty.
*   `fulfillOracleData`: (Simulated Oracle Callback) Receives external data needed for collapse calculations for a specific deposit.
*   `fulfillRandomWord`: (Simulated VRF Callback) Receives verifiable randomness needed for outcome selection for a specific deposit.
*   `triggerStateCollapse`: Callable function that checks conditions, calculates final outcome probabilities based on weights, oracle data, entanglement, and randomness, and resolves the deposit's state to one outcome.
*   `claimCollapsedDeposit`: Allows the recipient of the resolved outcome to claim funds if the outcome's specific conditions are met.
*   `getDepositState`: View function returning the current state (Superposition, Collapsed, etc.) and resolved outcome ID if collapsed.
*   `getDepositDetails`: View function returning detailed information about a deposit, including all potential outcomes.
*   `getOracleDataStatus`: View function returning the status of required oracle data for a deposit's collapse.
*   `getRandomnessStatus`: View function returning the status of required randomness for a deposit's collapse.
*   `getLinkedDeposits`: View function returning the IDs of deposits linked for entanglement to a given deposit.
*   `checkCollapseReadiness`: View function indicating if all external data and time requirements are met to potentially trigger collapse for a deposit.
*   `withdrawFees`: Owner function to withdraw accumulated fees.
*   `emergencyWithdraw`: Owner function for emergency fund retrieval (caution needed).
*   `getDepositIdsByUser`: View function returning all deposit IDs created by a specific address.
*   `getTotalDeposits`: View function returning the total number of deposits created.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Outline ---
// 1. State Management: Enums, Structs
// 2. Configuration: Admin Setters
// 3. Deposit Creation: ETH/ERC20 deposit with multiple outcomes
// 4. Deposit Modification (Pre-Collapse)
// 5. Deposit Linking (Entanglement)
// 6. Collapse Triggering: Oracle/VRF simulation & main trigger
// 7. State Resolution: Internal probabilistic logic
// 8. Post-Collapse Actions: Claiming
// 9. Querying: View Functions
// 10. Admin/Maintenance: Pause, Withdrawals

// --- Function Summary ---
// constructor: Deploys contract, sets owner.
// pauseContract: Owner pauses transfers/critical actions.
// unpauseContract: Owner unpauses.
// transferOwnership: Transfers contract ownership.
// renounceOwnership: Renounces contract ownership.
// setFeeRecipient: Sets address for fees.
// setCollapseFee: Sets fee for triggerStateCollapse.
// setEntanglementFactor: Sets param for entanglement influence.
// setObservationWindow: Sets minimum time for collapse trigger readiness.
// setERC20Token: Sets the ERC20 token address handled by the vault.
// setMinimumDeposit: Sets min deposit amount.
// createQuantumDeposit: Creates a new deposit with potential outcomes.
// addPotentialOutcomeState: Adds outcome to deposit in Superposition.
// updateOutcomeStateWeights: Updates outcome weights in Superposition.
// linkDepositsForEntanglement: Links deposits for collapse influence.
// unlinkDeposits: Removes entanglement link.
// cancelDepositPreCollapse: Cancels deposit before collapse.
// fulfillOracleData: (Simulated) Receives oracle data.
// fulfillRandomWord: (Simulated) Receives randomness.
// triggerStateCollapse: Triggers state resolution/collapse.
// claimCollapsedDeposit: Claims funds based on resolved outcome.
// getDepositState: Gets current state of a deposit.
// getDepositDetails: Gets full details of a deposit.
// getOracleDataStatus: Gets oracle data status for collapse.
// getRandomnessStatus: Gets randomness status for collapse.
// getLinkedDeposits: Gets linked deposit IDs.
// checkCollapseReadiness: Checks if deposit is ready for collapse trigger.
// withdrawFees: Owner withdraws fees.
// emergencyWithdraw: Owner withdraws funds in emergency.
// getDepositIdsByUser: Gets all deposit IDs for a user.
// getTotalDeposits: Gets total number of deposits.

contract QuantumVault is Ownable, ReentrancyGuard, Pausable {

    enum DepositState {
        Superposition,           // Initial state, multiple potential outcomes
        OracleDataRequested,     // Waiting for external data
        RandomnessRequested,     // Waiting for randomness
        Resolving,               // Oracle data and randomness received, awaiting trigger
        Collapsed,               // State resolved to a single outcome
        Claimed,                 // Funds for collapsed outcome claimed
        Cancelled                // Deposit cancelled pre-collapse
    }

    struct OutcomeState {
        uint128 id;               // Unique ID within the deposit's outcomes
        address recipient;        // Address receiving funds if this outcome is chosen
        uint256 amount;           // Amount allocated to this outcome
        uint128 initialWeight;    // Initial probabilistic weight (relative)
        uint40 claimableAfterTimestamp; // Timestamp when this outcome becomes claimable
        // Future potential: bytes dataCondition; // Arbitrary data for external validation checks
        // Future potential: address validationContract; // Address of contract to call for validation
    }

    struct QuantumDeposit {
        uint256 id;               // Unique deposit ID
        address payable depositor; // The user who created the deposit
        bool isERC20;             // True if deposit is ERC20, false if ETH
        uint256 totalDepositAmount; // Total amount deposited
        DepositState state;       // Current state of the deposit
        OutcomeState[] potentialOutcomes; // All possible outcomes
        uint128 resolvedOutcomeId; // The ID of the outcome chosen during collapse
        uint64 creationTimestamp; // Timestamp of deposit creation
        uint64 collapseTimestamp; // Timestamp when state collapse occurred

        // External data dependencies for collapse
        int256 oracleDataValue;   // Placeholder for data received from oracle (e.g., price, weather index)
        bool oracleDataReceived;
        bytes32 oracleRequestId;

        uint256 randomnessValue;  // Placeholder for verifiable randomness
        bool randomnessReceived;
        bytes32 randomnessRequestId;

        // Entanglement
        uint256[] linkedDepositIds; // Other deposit IDs this one is entangled with
    }

    uint256 private _nextDepositId = 1;
    mapping(uint256 => QuantumDeposit) public deposits;
    mapping(address => uint256[]) private _depositsByUser;

    address payable public feeRecipient;
    uint256 public collapseFee = 0; // Fee in wei to trigger collapse
    uint256 public entanglementFactor = 100; // Factor influencing entanglement (e.g., multiplier for linked weights)

    // Time window requirement for collapse trigger readiness (e.g., deposit must be >= observationWindow old)
    uint40 public observationWindow = 0;

    IERC20 public erc20Token; // The single ERC20 token supported
    uint256 public minimumDeposit = 0;

    // Simulated External Oracles (for demonstration)
    // In a real dApp, these would be interfaces to Chainlink or other oracle networks
    address public simulatedOracleAddress;
    address public simulatedVRFCoordinator;

    event DepositCreated(uint256 indexed depositId, address indexed depositor, uint256 amount, bool isERC20, uint64 creationTimestamp);
    event OutcomeAdded(uint256 indexed depositId, uint128 outcomeId, address recipient, uint256 amount, uint128 initialWeight);
    event WeightsUpdated(uint256 indexed depositId);
    event DepositsLinked(uint256 indexed depositId1, uint256 indexed depositId2);
    event DepositsUnlinked(uint256 indexed depositId1, uint256 indexed depositId2);
    event DepositCancelled(uint256 indexed depositId);
    event OracleDataFulfilled(uint256 indexed depositId, int256 data);
    event RandomWordFulfilled(uint256 indexed depositId, uint256 randomWord);
    event StateCollapsed(uint256 indexed depositId, uint128 indexed resolvedOutcomeId, uint64 collapseTimestamp);
    event DepositClaimed(uint256 indexed depositId, uint128 indexed outcomeId, address indexed recipient, uint256 amount);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);

    modifier whenDepositExists(uint256 _depositId) {
        require(_depositId > 0 && _depositId < _nextDepositId, "Invalid deposit ID");
        _;
    }

    modifier whenStateIs(uint256 _depositId, DepositState _state) {
        require(deposits[_depositId].state == _state, "Deposit is not in required state");
        _;
    }

    modifier whenStateIsNot(uint256 _depositId, DepositState _state) {
        require(deposits[_depositId].state != _state, "Deposit is in an incompatible state");
        _;
    }

    constructor(address _erc20TokenAddress) Ownable(msg.sender) {
        erc20Token = IERC20(_erc20TokenAddress);
        feeRecipient = payable(msg.sender); // Default fee recipient is owner
        // simulatedOracleAddress and simulatedVRFCoordinator would be set after deployment
    }

    // --- 2. Configuration ---

    function setFeeRecipient(address payable _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function setCollapseFee(uint256 _fee) external onlyOwner {
        collapseFee = _fee;
    }

    function setEntanglementFactor(uint256 _factor) external onlyOwner {
        entanglementFactor = _factor;
    }

    function setObservationWindow(uint40 _window) external onlyOwner {
        observationWindow = _window;
    }

    function setERC20Token(address _erc20TokenAddress) external onlyOwner {
        require(_nextDepositId == 1, "Cannot change ERC20 token after first deposit");
        erc20Token = IERC20(_erc20TokenAddress);
    }

    function setMinimumDeposit(uint256 _minAmount) external onlyOwner {
        minimumDeposit = _minAmount;
    }

    // Simulated Oracle/VRF Setters (In a real contract, these might link to Chainlink interfaces)
    function setSimulatedOracleAddress(address _oracleAddress) external onlyOwner {
        simulatedOracleAddress = _oracleAddress;
    }

     function setSimulatedVRFCoordinator(address _vrfCoordinator) external onlyOwner {
        simulatedVRFCoordinator = _vrfCoordinator;
    }


    // --- 3. Deposit Creation ---

    /// @notice Creates a new Quantum Deposit with potential outcomes.
    /// @param _outcomes Array of potential outcomes for the deposit.
    /// @param _isERC20 True if depositing the configured ERC20 token, false for ETH.
    /// @param _totalDepositAmount The total amount being deposited.
    /// @dev For ERC20, the user must have approved this contract beforehand.
    function createQuantumDeposit(
        OutcomeState[] calldata _outcomes,
        bool _isERC20,
        uint256 _totalDepositAmount
    )
        external
        payable
        whenNotPaused
        nonReentrant
    {
        require(_totalDepositAmount >= minimumDeposit, "Deposit amount too low");
        require(_outcomes.length > 0, "Must define at least one potential outcome");

        uint256 totalInitialWeight = 0;
        uint256 outcomeAmountSum = 0;
        require(_outcomes.length <= 10, "Too many outcomes"); // Limit outcomes to prevent abuse/gas issues

        // Validate outcomes and calculate sums
        for (uint i = 0; i < _outcomes.length; i++) {
            require(_outcomes[i].recipient != address(0), "Outcome recipient cannot be zero address");
            require(_outcomes[i].amount <= _totalDepositAmount, "Outcome amount exceeds total deposit"); // An outcome can be less than total
            totalInitialWeight += _outcomes[i].initialWeight;
            outcomeAmountSum += _outcomes[i].amount; // Sum of allocated amounts in outcomes
        }
        // Note: Sum of outcome amounts can be less than totalDepositAmount.
        // The 'leftover' amount could be implicitly allocated to the depositor or a fee/burn outcome,
        // but for simplicity, let's ensure amounts don't exceed total. If sum < total, the extra
        // isn't explicitly handled in this version's outcomes. A more complex version could add a default outcome.

        uint256 currentDepositId = _nextDepositId++;
        address payable depositorAddress = payable(msg.sender);

        // Handle payment (ETH or ERC20)
        if (_isERC20) {
            require(msg.value == 0, "Send 0 ETH for ERC20 deposit");
            require(address(erc20Token) != address(0), "ERC20 token not set");
            IERC20(erc20Token).transferFrom(depositorAddress, address(this), _totalDepositAmount);
        } else {
            require(msg.value == _totalDepositAmount, "Sent ETH does not match specified amount");
            // ETH is already sent via payable
        }

        // Store potential outcomes with unique IDs
        OutcomeState[] memory potentialOutcomesMemory = new OutcomeState[](_outcomes.length);
         for (uint i = 0; i < _outcomes.length; i++) {
            potentialOutcomesMemory[i] = _outcomes[i];
            potentialOutcomesMemory[i].id = uint128(i + 1); // Assign sequential IDs starting from 1
        }


        deposits[currentDepositId] = QuantumDeposit({
            id: currentDepositId,
            depositor: depositorAddress,
            isERC20: _isERC20,
            totalDepositAmount: _totalDepositAmount,
            state: DepositState.Superposition,
            potentialOutcomes: potentialOutcomesMemory,
            resolvedOutcomeId: 0, // Not resolved yet
            creationTimestamp: uint64(block.timestamp),
            collapseTimestamp: 0, // Not collapsed yet

            // External data init
            oracleDataValue: 0,
            oracleDataReceived: false,
            oracleRequestId: bytes32(0),

            randomnessValue: 0,
            randomnessReceived: false,
            randomnessRequestId: bytes32(0),

            linkedDepositIds: new uint256[](0) // No links initially
        });

        _depositsByUser[depositorAddress].push(currentDepositId);

        emit DepositCreated(currentDepositId, depositorAddress, _totalDepositAmount, _isERC20, uint64(block.timestamp));
    }

    // --- 4. Deposit Modification (Pre-Collapse) ---

     /// @notice Adds a new potential outcome state to a deposit in Superposition.
     /// @param _depositId The ID of the deposit to modify.
     /// @param _outcome The new outcome state to add.
     function addPotentialOutcomeState(uint256 _depositId, OutcomeState calldata _outcome)
         external
         whenNotPaused
         whenDepositExists(_depositId)
         whenStateIs(_depositId, DepositState.Superposition)
         nonReentrant
     {
         QuantumDeposit storage deposit = deposits[_depositId];
         require(msg.sender == deposit.depositor, "Only depositor can add outcomes");
         require(_outcome.recipient != address(0), "Outcome recipient cannot be zero address");
         require(_outcome.amount <= deposit.totalDepositAmount, "Outcome amount exceeds total deposit");
         require(deposit.potentialOutcomes.length < 10, "Too many outcomes already");

         // Assign a new unique ID
         uint128 newOutcomeId = uint128(deposit.potentialOutcomes.length + 1);
         deposit.potentialOutcomes.push(_outcome);
         deposit.potentialOutcomes[deposit.potentialOutcomes.length - 1].id = newOutcomeId; // Assign ID

         emit OutcomeAdded(_depositId, newOutcomeId, _outcome.recipient, _outcome.amount, _outcome.initialWeight);
     }

    /// @notice Updates the initial weights of potential outcomes for a deposit in Superposition.
    /// @param _depositId The ID of the deposit to modify.
    /// @param _outcomeIds Array of outcome IDs to update.
    /// @param _newWeights Array of new weights corresponding to the IDs.
    function updateOutcomeStateWeights(
        uint256 _depositId,
        uint128[] calldata _outcomeIds,
        uint128[] calldata _newWeights
    )
        external
        whenNotPaused
        whenDepositExists(_depositId)
        whenStateIs(_depositId, DepositState.Superposition)
    {
        QuantumDeposit storage deposit = deposits[_depositId];
        require(msg.sender == deposit.depositor, "Only depositor can update weights");
        require(_outcomeIds.length == _newWeights.length, "ID and weight arrays must match length");

        for (uint i = 0; i < _outcomeIds.length; i++) {
            bool found = false;
            for (uint j = 0; j < deposit.potentialOutcomes.length; j++) {
                if (deposit.potentialOutcomes[j].id == _outcomeIds[i]) {
                    deposit.potentialOutcomes[j].initialWeight = _newWeights[i];
                    found = true;
                    break;
                }
            }
            require(found, string(abi.encodePacked("Outcome ID ", Strings.toString(_outcomeIds[i]), " not found")));
        }

        emit WeightsUpdated(_depositId);
    }


    // --- 5. Deposit Linking (Entanglement) ---

    /// @notice Links two Superposition deposits for mutual probabilistic influence during collapse.
    /// @param _depositId1 The ID of the first deposit.
    /// @param _depositId2 The ID of the second deposit.
    /// @dev Deposits must be in Superposition and not already linked.
    function linkDepositsForEntanglement(uint256 _depositId1, uint256 _depositId2)
        external
        whenNotPaused
        whenDepositExists(_depositId1)
        whenDepositExists(_depositId2)
        whenStateIs(_depositId1, DepositState.Superposition)
        whenStateIs(_depositId2, DepositState.Superposition)
    {
        require(_depositId1 != _depositId2, "Cannot link a deposit to itself");
        // Require approval from BOTH depositors? Or just one can propose, the other accepts?
        // For simplicity, let's allow depositor of deposit1 to propose, if they also own deposit2, it links.
        // More complex: require consent from both addresses.
        require(msg.sender == deposits[_depositId1].depositor, "Must be depositor of deposit 1");
        // Optional: require msg.sender == deposits[_depositId2].depositor, "Must also be depositor of deposit 2";

        // Check if already linked
        bool alreadyLinked = false;
        for (uint i = 0; i < deposits[_depositId1].linkedDepositIds.length; i++) {
            if (deposits[_depositId1].linkedDepositIds[i] == _depositId2) {
                alreadyLinked = true;
                break;
            }
        }
        require(!alreadyLinked, "Deposits are already linked");

        deposits[_depositId1].linkedDepositIds.push(_depositId2);
        deposits[_depositId2].linkedDepositIds.push(_depositId1); // Link in both directions

        emit DepositsLinked(_depositId1, _depositId2);
    }

     /// @notice Removes an entanglement link between two deposits.
     /// @param _depositId1 The ID of the first deposit.
     /// @param _depositId2 The ID of the second deposit.
     function unlinkDeposits(uint256 _depositId1, uint256 _depositId2)
        external
        whenNotPaused
        whenDepositExists(_depositId1)
        whenDepositExists(_depositId2)
     {
         require(_depositId1 != _depositId2, "Cannot unlink from itself");
         // Allow either depositor or the contract owner to unlink? Owner for simplicity.
         require(msg.sender == deposits[_depositId1].depositor || msg.sender == deposits[_depositId2].depositor || msg.sender == owner(), "Must be a depositor or owner to unlink");

         _removeLinkedDeposit(deposits[_depositId1].linkedDepositIds, _depositId2);
         _removeLinkedDeposit(deposits[_depositId2].linkedDepositIds, _depositId1);

         emit DepositsUnlinked(_depositId1, _depositId2);
     }

     function _removeLinkedDeposit(uint256[] storage _linkedDepositIds, uint256 _depositIdToRemove) internal {
         for (uint i = 0; i < _linkedDepositIds.length; i++) {
             if (_linkedDepositIds[i] == _depositIdToRemove) {
                 // Replace with last element and pop
                 _linkedDepositIds[i] = _linkedDepositIds[_linkedDepositIds.length - 1];
                 _linkedDepositIds.pop();
                 break; // Assuming no duplicate links
             }
         }
         // Note: If the ID wasn't found, this is a no-op. Consider adding a check if link must exist.
     }


    // --- 6. Collapse Triggering (Simulated Oracle/VRF & Main Trigger) ---

    // In a real Chainlink integration, these would be methods called by the Chainlink node.
    // For this example, we simulate them being called externally (e.g., by a test script or relayer)

    /// @notice (Simulated) Called by external oracle service to provide data.
    /// @param _requestId The ID of the oracle request.
    /// @param _data The data received from the oracle.
    function fulfillOracleData(bytes32 _requestId, int256 _data)
        external
        whenNotPaused
    {
        // In a real contract, this would verify the caller is the authorized oracle contract.
        // require(msg.sender == simulatedOracleAddress, "Caller is not the authorized oracle");

        uint256 depositId = 0; // Find the deposit waiting for this request ID
        bool found = false;
        // This search is inefficient for many deposits; a mapping from requestId to depositId is better.
        // For simplicity here:
        for (uint256 i = 1; i < _nextDepositId; i++) {
            if (deposits[i].oracleRequestId == _requestId && deposits[i].state == DepositState.OracleDataRequested) {
                depositId = i;
                found = true;
                break;
            }
        }
        require(found, "Oracle request ID not found or deposit not in OracleDataRequested state");

        QuantumDeposit storage deposit = deposits[depositId];
        deposit.oracleDataValue = _data;
        deposit.oracleDataReceived = true;
        deposit.state = DepositState.Resolving; // Ready for randomness or trigger

        emit OracleDataFulfilled(depositId, _data);
    }

    /// @notice (Simulated) Called by external VRF service to provide randomness.
    /// @param _requestId The ID of the VRF request.
    /// @param _randomWord The random number received.
    function fulfillRandomWord(bytes32 _requestId, uint256 _randomWord)
        external
        whenNotPaused
    {
        // In a real contract, this would verify the caller is the authorized VRF coordinator.
        // require(msg.sender == simulatedVRFCoordinator, "Caller is not the authorized VRF coordinator");

         uint256 depositId = 0; // Find the deposit waiting for this request ID
        bool found = false;
         // This search is inefficient for many deposits; a mapping from requestId to depositId is better.
        // For simplicity here:
        for (uint256 i = 1; i < _nextDepositId; i++) {
            if (deposits[i].randomnessRequestId == _requestId && (deposits[i].state == DepositState.RandomnessRequested || deposits[i].state == DepositState.Resolving)) {
                depositId = i;
                found = true;
                break;
            }
        }
        require(found, "Randomness request ID not found or deposit not awaiting randomness");

        QuantumDeposit storage deposit = deposits[depositId];
        deposit.randomnessValue = _randomWord;
        deposit.randomnessReceived = true;
        deposit.state = DepositState.Resolving; // Ready for trigger

        emit RandomWordFulfilled(depositId, _randomWord);
    }

    /// @notice Triggers the state collapse for a deposit.
    /// Requires oracle data and randomness to be received, and observation window passed.
    /// @param _depositId The ID of the deposit to collapse.
    function triggerStateCollapse(uint256 _depositId)
        external
        payable
        whenNotPaused
        whenDepositExists(_depositId)
        whenStateIsNot(_depositId, DepositState.Collapsed)
        whenStateIsNot(_depositId, DepositState.Claimed)
        whenStateIsNot(_depositId, DepositState.Cancelled)
        nonReentrant
    {
        QuantumDeposit storage deposit = deposits[_depositId];

        // Check readiness criteria
        require(checkCollapseReadiness(_depositId), "Deposit not ready for collapse trigger");
        require(msg.value >= collapseFee, "Insufficient fee to trigger collapse");

        // Transfer collapse fee
        if (collapseFee > 0) {
             (bool success, ) = feeRecipient.call{value: collapseFee}("");
             require(success, "Fee transfer failed");
        }


        // --- State Resolution Logic (The "Quantum" part) ---
        // This is a simplified conceptual model of probabilistic selection.
        // In reality, entanglement calculations and oracle influence would be more complex.

        uint256 totalEffectiveWeight = 0;
        uint256[] memory effectiveWeights = new uint256[](deposit.potentialOutcomes.length);

        // Calculate effective weights considering initial weights, oracle data, and entanglement
        for (uint i = 0; i < deposit.potentialOutcomes.length; i++) {
            uint256 effectiveWeight = deposit.potentialOutcomes[i].initialWeight;

            // Influence by Oracle Data (Conceptual)
            // Example: If oracleDataValue is positive, slightly increase weight of outcome 1; if negative, decrease.
            // This part is highly arbitrary and depends on the oracle data's meaning.
            if (deposit.oracleDataReceived) {
                 // Simple example: Add or subtract based on oracle data sign and magnitude
                 if (deposit.oracleDataValue > 0) {
                     effectiveWeight += uint256(deposit.oracleDataValue) / 100; // Scale oracle data
                 } else if (deposit.oracleDataValue < 0) {
                      // Ensure weight doesn't go below zero
                      effectiveWeight = effectiveWeight >= uint256(-deposit.oracleDataValue) / 100 ? effectiveWeight - uint256(-deposit.oracleDataValue) / 100 : 0;
                 }
                 // More complex: Map oracle value range to influence outcome weights differently
             }

            // Influence by Entanglement (Conceptual)
            // Example: Iterate through linked deposits. If a linked deposit has collapsed,
            // influence this deposit's outcome weights based on the linked deposit's *resolved* outcome.
            // If linked deposits are still in Superposition, influence based on *their current probability distribution* (complex!).
            // For simplicity: Let's say if ANY linked deposit has collapsed, it slightly skews the weights here.
            // A more advanced model might involve complex state interaction functions.
            uint256 entanglementInfluence = 0;
            for (uint j = 0; j < deposit.linkedDepositIds.length; j++) {
                uint256 linkedId = deposit.linkedDepositIds[j];
                if (linkedId > 0 && linkedId < _nextDepositId && deposits[linkedId].state == DepositState.Collapsed) {
                    // Example: Add entanglementFactor if linked deposit collapsed to outcome 1
                    // This logic is highly conceptual.
                    if (deposits[linkedId].resolvedOutcomeId == 1) { // Arbitrary condition based on linked outcome ID
                         entanglementInfluence += entanglementFactor;
                    } else {
                         entanglementInfluence = entanglementInfluence >= entanglementFactor / 2 ? entanglementInfluence - entanglementFactor / 2 : 0;
                    }
                 } else if (linkedId > 0 && linkedId < _nextDepositId && deposits[linkedId].state == DepositState.Superposition) {
                     // Influence based on linked superposition? Very complex. Skip for this example.
                 }
            }
            effectiveWeight += entanglementInfluence;

            // Ensure effective weight is not zero unless explicitly set to zero initialWeight
            if (effectiveWeight == 0 && deposit.potentialOutcomes[i].initialWeight > 0) {
                 effectiveWeight = 1; // Minimum weight if initially non-zero
            }

            effectiveWeights[i] = effectiveWeight;
            totalEffectiveWeight += effectiveWeight;
        }

        require(totalEffectiveWeight > 0, "Total effective weight is zero, cannot select outcome");

        // Select outcome based on random word and effective weights
        uint256 randomValue = deposit.randomnessValue; // Use the fulfilled randomness
        uint256 choice = randomValue % totalEffectiveWeight;

        uint128 chosenOutcomeId = 0;
        uint256 cumulativeWeight = 0;

        for (uint i = 0; i < effectiveWeights.length; i++) {
            cumulativeWeight += effectiveWeights[i];
            if (choice < cumulativeWeight) {
                chosenOutcomeId = deposit.potentialOutcomes[i].id;
                break;
            }
        }

        require(chosenOutcomeId != 0, "Failed to select an outcome"); // Should not happen if totalEffectiveWeight > 0

        // --- Apply Collapse ---
        deposit.resolvedOutcomeId = chosenOutcomeId;
        deposit.state = DepositState.Collapsed;
        deposit.collapseTimestamp = uint64(block.timestamp);

        emit StateCollapsed(_depositId, chosenOutcomeId, uint64(block.timestamp));
    }

    // --- 8. Post-Collapse Actions ---

    /// @notice Allows the recipient of the resolved outcome to claim the funds.
    /// @param _depositId The ID of the collapsed deposit.
    /// @dev Checks if the deposit is collapsed, the caller is the correct recipient,
    /// and any outcome-specific conditions (like timestamp) are met.
    function claimCollapsedDeposit(uint256 _depositId)
        external
        nonReentrant
        whenNotPaused
        whenDepositExists(_depositId)
        whenStateIs(_depositId, DepositState.Collapsed)
    {
        QuantumDeposit storage deposit = deposits[_depositId];
        uint128 resolvedOutcomeId = deposit.resolvedOutcomeId;

        // Find the resolved outcome details
        OutcomeState storage resolvedOutcome;
        bool found = false;
        for (uint i = 0; i < deposit.potentialOutcomes.length; i++) {
            if (deposit.potentialOutcomes[i].id == resolvedOutcomeId) {
                resolvedOutcome = deposit.potentialOutcomes[i];
                found = true;
                break;
            }
        }
        require(found, "Resolved outcome not found (internal error)"); // Should not happen

        require(msg.sender == resolvedOutcome.recipient, "Only the resolved outcome recipient can claim");
        require(block.timestamp >= resolvedOutcome.claimableAfterTimestamp, "Funds not claimable yet");

        // Transfer the resolved amount
        if (deposit.isERC20) {
            require(address(erc20Token) != address(0), "ERC20 token not set");
            IERC20(erc20Token).transfer(resolvedOutcome.recipient, resolvedOutcome.amount);
        } else {
            (bool success, ) = resolvedOutcome.recipient.call{value: resolvedOutcome.amount}("");
            require(success, "ETH transfer failed");
        }

        // Update state and clean up (optional: clear outcome data to save gas)
        deposit.state = DepositState.Claimed;
        // deposit.potentialOutcomes = new OutcomeState[](0); // Clearing array saves state gas on future reads but complicates history

        emit DepositClaimed(_depositId, resolvedOutcomeId, resolvedOutcome.recipient, resolvedOutcome.amount);
    }

    /// @notice Allows the depositor to cancel a deposit if it's still in Superposition.
    /// @param _depositId The ID of the deposit to cancel.
    /// @param _penaltyPercentage Optional: percentage of total deposit to keep as penalty.
    function cancelDepositPreCollapse(uint256 _depositId, uint256 _penaltyPercentage)
        external
        whenNotPaused
        whenDepositExists(_depositId)
        whenStateIs(_depositId, DepositState.Superposition)
        nonReentrant
    {
        QuantumDeposit storage deposit = deposits[_depositId];
        require(msg.sender == deposit.depositor, "Only depositor can cancel");
        require(_penaltyPercentage <= 100, "Penalty percentage invalid");

        deposit.state = DepositState.Cancelled;

        uint256 penaltyAmount = (deposit.totalDepositAmount * _penaltyPercentage) / 100;
        uint256 refundAmount = deposit.totalDepositAmount - penaltyAmount;

        // Transfer refund
        if (refundAmount > 0) {
            if (deposit.isERC20) {
                 require(address(erc20Token) != address(0), "ERC20 token not set");
                 IERC20(erc20Token).transfer(deposit.depositor, refundAmount);
            } else {
                (bool success, ) = deposit.depositor.call{value: refundAmount}("");
                require(success, "Refund transfer failed");
            }
        }

        // Transfer penalty to fee recipient
        if (penaltyAmount > 0) {
             if (deposit.isERC20) {
                 require(address(erc20Token) != address(0), "ERC20 token not set");
                 IERC20(erc20Token).transfer(feeRecipient, penaltyAmount);
            } else {
                (bool success, ) = feeRecipient.call{value: penaltyAmount}("");
                require(success, "Penalty transfer failed");
            }
        }

        // Clean up entanglement links involving this deposit
         for(uint i = 0; i < deposit.linkedDepositIds.length; i++) {
             uint256 linkedId = deposit.linkedDepositIds[i];
             if (linkedId > 0 && linkedId < _nextDepositId) {
                  _removeLinkedDeposit(deposits[linkedId].linkedDepositIds, _depositId);
             }
         }
        deposit.linkedDepositIds = new uint256[](0); // Clear links from cancelled deposit


        emit DepositCancelled(_depositId);
    }


    // --- 9. Querying (View Functions) ---

    /// @notice Gets the current state and resolved outcome of a deposit.
    /// @param _depositId The ID of the deposit.
    /// @return state The current state of the deposit.
    /// @return resolvedOutcomeId The ID of the resolved outcome (0 if not collapsed).
    function getDepositState(uint256 _depositId)
        external
        view
        whenDepositExists(_depositId)
        returns (DepositState state, uint128 resolvedOutcomeId)
    {
        QuantumDeposit storage deposit = deposits[_depositId];
        return (deposit.state, deposit.resolvedOutcomeId);
    }

    /// @notice Gets detailed information about a deposit.
    /// @param _depositId The ID of the deposit.
    /// @return details Struct containing all deposit information.
    function getDepositDetails(uint256 _depositId)
        external
        view
        whenDepositExists(_depositId)
        returns (QuantumDeposit memory details)
    {
        // Need to copy to memory for returning structs with dynamic arrays
        details = deposits[_depositId];
        return details;
    }

    /// @notice Gets the status of required oracle data for a deposit's collapse.
    /// @param _depositId The ID of the deposit.
    /// @return oracleDataValue The value received (0 if not received).
    /// @return oracleDataReceived True if data has been received.
    /// @return oracleRequestId The request ID used.
     function getOracleDataStatus(uint256 _depositId)
        external
        view
        whenDepositExists(_depositId)
        returns (int256 oracleDataValue, bool oracleDataReceived, bytes32 oracleRequestId)
    {
        QuantumDeposit storage deposit = deposits[_depositId];
        return (deposit.oracleDataValue, deposit.oracleDataReceived, deposit.oracleRequestId);
    }

    /// @notice Gets the status of required randomness for a deposit's collapse.
    /// @param _depositId The ID of the deposit.
    /// @return randomnessValue The value received (0 if not received).
    /// @return randomnessReceived True if randomness has been received.
    /// @return randomnessRequestId The request ID used.
    function getRandomnessStatus(uint256 _depositId)
        external
        view
        whenDepositExists(_depositId)
        returns (uint256 randomnessValue, bool randomnessReceived, bytes32 randomnessRequestId)
    {
         QuantumDeposit storage deposit = deposits[_depositId];
        return (deposit.randomnessValue, deposit.randomnessReceived, deposit.randomnessRequestId);
    }

    /// @notice Gets the IDs of deposits linked for entanglement to a given deposit.
    /// @param _depositId The ID of the deposit.
    /// @return linkedDepositIds Array of linked deposit IDs.
    function getLinkedDeposits(uint256 _depositId)
         external
         view
         whenDepositExists(_depositId)
         returns (uint256[] memory linkedDepositIds)
    {
        linkedDepositIds = deposits[_depositId].linkedDepositIds;
        return linkedDepositIds;
    }

    /// @notice Checks if all external data and time requirements are met to potentially trigger collapse for a deposit.
    /// @param _depositId The ID of the deposit.
    /// @return isReady True if the deposit is in a state where collapse *could* be triggered.
    function checkCollapseReadiness(uint256 _depositId)
        public
        view
        whenDepositExists(_depositId)
        returns (bool isReady)
    {
        QuantumDeposit storage deposit = deposits[_depositId];
        // Deposit must be in Superposition, OracleDataRequested, RandomnessRequested, or Resolving state
        if (deposit.state != DepositState.Superposition &&
            deposit.state != DepositState.OracleDataRequested &&
            deposit.state != DepositState.RandomnessRequested &&
            deposit.state != DepositState.Resolving)
        {
            return false;
        }

        // Must have received oracle data if a request was made (simulated)
        // In a real contract, you'd check if oracleRequestId is non-zero and oracleDataReceived is true.
        // For this simulation: assume oracleDataReceived is true if needed.
        if (simulatedOracleAddress != address(0) && !deposit.oracleDataReceived) {
             // If oracle simulation is active and data is missing
             // Note: This simplistic check assumes a request was made if address is set.
             // A real impl would need to track if a request was actually initiated.
             return false;
        }


        // Must have received randomness if a request was made (simulated)
         // In a real contract, you'd check if randomnessRequestId is non-zero and randomnessReceived is true.
        // For this simulation: assume randomnessReceived is true if needed.
        if (simulatedVRFCoordinator != address(0) && !deposit.randomnessReceived) {
            // If VRF simulation is active and data is missing
             // Note: This simplistic check assumes a request was made if address is set.
             // A real impl would need to track if a request was actually initiated.
             return false;
        }

        // Must have passed the observation window
        if (block.timestamp < deposit.creationTimestamp + observationWindow) {
            return false;
        }

        // If we reach here, it's conceptually ready from external data/time perspective.
        return true;
    }

    /// @notice Gets all deposit IDs associated with a specific user address.
    /// @param _user The address to query.
    /// @return depositIds Array of deposit IDs.
    function getDepositIdsByUser(address _user) external view returns (uint256[] memory) {
        return _depositsByUser[_user];
    }

    /// @notice Gets the total number of deposits ever created.
    /// @return totalDeposits The count of all deposits.
    function getTotalDeposits() external view returns (uint256) {
        return _nextDepositId - 1; // _nextDepositId is 1-based counter
    }

    // --- 10. Admin/Maintenance ---

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Owner can withdraw accumulated ETH fees.
    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance - totalERC20Balance();
        require(balance > 0, "No ETH fees to withdraw");
        (bool success, ) = feeRecipient.call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(feeRecipient, balance);
    }

     /// @notice Owner can withdraw accumulated ERC20 fees.
     function withdrawERC20Fees() external onlyOwner nonReentrant {
        require(address(erc20Token) != address(0), "ERC20 token not set");
        uint256 feeBalance = erc20Token.balanceOf(address(this)) - totalERC20Balance();
        require(feeBalance > 0, "No ERC20 fees to withdraw");
         erc20Token.transfer(feeRecipient, feeBalance);
     }

    /// @notice Owner can withdraw all funds in case of emergency. Use with extreme caution.
    /// @dev This bypasses all deposit states and conditions.
    function emergencyWithdraw(address recipient) external onlyOwner nonReentrancy {
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            (bool success, ) = payable(recipient).call{value: ethBalance}("");
            require(success, "ETH emergency withdrawal failed");
            emit EmergencyWithdrawal(payable(recipient), ethBalance);
        }

        if (address(erc20Token) != address(0)) {
            uint256 tokenBalance = erc20Token.balanceOf(address(this));
             if (tokenBalance > 0) {
                erc20Token.transfer(recipient, tokenBalance);
             }
        }
        // Note: This function does not update individual deposit states to 'Claimed' or 'Cancelled'.
        // State remains as is, but funds are gone.
    }

    // --- Internal/Helper Functions ---

    /// @notice Calculates the total amount of ERC20 tokens held for active deposits.
    /// Excludes potential ERC20 fees.
    function totalERC20Balance() internal view returns (uint256 total) {
        total = 0;
        // This is inefficient for many deposits. Better to track separately or iterate limited set.
        for (uint256 i = 1; i < _nextDepositId; i++) {
             if (deposits[i].isERC20 &&
                 (deposits[i].state == DepositState.Superposition ||
                 deposits[i].state == DepositState.OracleDataRequested ||
                 deposits[i].state == DepositState.RandomnessRequested ||
                 deposits[i].state == DepositState.Resolving ||
                 deposits[i].state == DepositState.Collapsed)) // Funds still held if collapsed, until claimed
            {
                total += deposits[i].totalDepositAmount;
            }
        }
    }

     // Minimal Strings library for error messages if needed (using OpenZeppelin's internally usually)
     // This is just for demonstration purposes if not importing OZ full library
    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            // Simple implementation, replace with OZ SafeCast/Strings if needed
            if (value == 0) return "0";
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
         function toString(uint128 value) internal pure returns (string memory) {
            return toString(uint256(value));
        }
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **Superposition State (`DepositState.Superposition`):** A core concept. Funds are deposited, but their final destination is indeterminate, residing in a state with multiple *potential* outcomes, analogous to quantum superposition.
2.  **Potential Outcomes (`OutcomeState[] potentialOutcomes`):** Each deposit explicitly defines an array of different ways the deposit *could* resolve. These can have different recipients, amounts, and even future claim conditions (`claimableAfterTimestamp`).
3.  **State Collapse (`triggerStateCollapse` function):** This function acts as the "observer". Calling it transitions the deposit from a indeterminate state (Superposition/Resolving) to a single, definite `Collapsed` state. This action is the core unique mechanism.
4.  **Probabilistic Resolution:** The outcome is not simply chosen sequentially or by a fixed rule. The selection is based on a weighted probability distribution (`effectiveWeights`).
5.  **Dynamic Influence on Probability:** The weights aren't static initial values. They are dynamically adjusted *at the time of collapse* based on:
    *   Initial weights set by the depositor.
    *   External data received via oracles (`oracleDataValue`).
    *   The state of other linked deposits (`entanglementInfluence`).
6.  **Entanglement (`linkedDepositIds`, `linkDepositsForEntanglement`, `unlinkDeposits`):** Deposits can be explicitly linked. The state (specifically, the resolved outcome if collapsed) of a linked deposit can influence the *probability distribution* of the current deposit's collapse. This adds a layer of interconnectedness not found in typical escrows. The `entanglementFactor` provides a configurable parameter for this influence strength.
7.  **External Observation Dependency (Simulated Oracles/VRF):** The collapse mechanism requires external data (`oracleDataReceived`, `randomnessReceived`) and potentially a time window (`observationWindow`) to have passed. This ensures the "observation" is based on external, potentially unpredictable factors, and prevents immediate, deterministic resolution by the depositor. We use simulated fulfillment functions (`fulfillOracleData`, `fulfillRandomWord`) to represent this.
8.  **Multi-Stage Conditions (`claimableAfterTimestamp`):** Even after the state collapses, the funds might not be immediately claimable. The specific resolved `OutcomeState` can have its own unlock conditions, adding another layer of time-based control *after* the primary probabilistic resolution.
9.  **Explicit States Machine:** The use of `DepositState` enum and transitions between states (`Superposition` -> `OracleDataRequested`/`RandomnessRequested` -> `Resolving` -> `Collapsed` -> `Claimed`/`Cancelled`) provides a clear structure for the complex lifecycle of a deposit.
10. **Role Separation:** The contract differentiates between the depositor (who sets up the potential states), the caller who triggers collapse (could be anyone, paying a fee), and the recipient (who claims the collapsed outcome).
11. **Modular Influence:** The collapse logic is designed to allow different factors (initial weights, oracle, entanglement) to contribute to the final probabilistic outcome calculation.

This contract goes beyond basic escrow or time-locks by introducing non-deterministic (from the perspective of the depositor at creation time), probabilistically influenced outcomes dependent on dynamic external and internal factors, managed through a conceptual "state collapse" mechanism. It incorporates state tracking, external data dependencies, and interconnected deposit logic (entanglement) to create a novel type of conditional fund release.