Okay, let's create a smart contract system that embodies a creative, advanced, and somewhat trendy concept: a factory that creates dynamic, time-sensitive, multi-participant "Rifts" or opportunities, possibly linked or having conditional outcomes. This avoids standard ERC-type tokens and focuses on dynamic state and inter-contract relationships.

We'll create two contracts:
1.  `IDimensionalRift`: An interface for the Rifts.
2.  `DimensionalRift`: The actual contract deployed by the factory.
3.  `QuantumLeapFactory`: The factory contract that deploys and manages the `DimensionalRift` instances.

The core idea is that the `QuantumLeapFactory` allows users to create `DimensionalRift` instances, each representing a unique challenge or collaboration window with defined parameters (goal, duration, participants needed, cost, potential rewards, and *dynamic* resolution conditions). Participants join Rifts, and the Rifts progress through states until a resolution (success or failure) is reached based on internal state and potentially external factors (simulated here via data encoded in parameters).

This incorporates:
*   **Factory Pattern:** Contract creating other contracts.
*   **Dynamic State:** Rifts have a lifecycle (Created, Open, Active, Resolved).
*   **Inter-Contract Interaction:** Factory tracks Rifts; users interact directly with Rifts; Rifts' resolution logic can be complex.
*   **Conditional Logic:** Resolution depends on parameters and time.
*   **Time Sensitivity:** Rifts have durations and deadlines.
*   **Coordination Mechanism:** Rifts facilitate multi-participant engagement towards a shared goal (even if simulated).
*   **Novel Asset/Right:** Participation in a Rift is a dynamic right/state.
*   **Advanced Parameterization:** Rifts are highly configurable via the factory.

We will ensure the total public/external function count across both the Factory and Rift contracts exceeds 20.

---

## QuantumLeapFactory & DimensionalRift System

**Outline:**

1.  **IDimensionalRift Interface:** Defines the public functions available on any deployed DimensionalRift contract. Necessary for the Factory to interact safely (if needed) and for users/frontends to understand the Rift's capabilities.
2.  **DimensionalRift Contract:**
    *   Defines the state, lifecycle, and logic for a single Rift instance.
    *   Manages participant entry, state transitions, resolution conditions, and outcome claims.
    *   Parameters are set upon creation by the factory.
    *   Resolution logic is flexible based on `ResolutionConditionType` enum.
3.  **QuantumLeapFactory Contract:**
    *   Deploys new `DimensionalRift` instances based on user-provided parameters and a creation fee.
    *   Keeps track of all deployed Rift instances.
    *   Provides view functions to query basic information about deployed Rifts (often by calling the Rift contracts).
    *   Includes basic factory management (ownership, pausing, fee withdrawal).

**Function Summary:**

*   **`IDimensionalRift`:**
    *   `enterRift()`: Participate in the rift (payable).
    *   `activateRift()`: Transition rift from OpenForEntry to Active state.
    *   `checkAndResolveRift()`: Check resolution conditions and transition to Resolved state.
    *   `claimOutcome()`: Claim stake/rewards after resolution.
    *   `getCurrentState()`: Get the current state of the rift.
    *   `getParameters()`: Get the creation parameters.
    *   `isParticipant(address account)`: Check if address is a participant.
    *   `getParticipantCount()`: Get current participant count.
    *   `getTimeRemaining()`: Get remaining time until expected end.
    *   `getResolutionData()`: Get data about how the rift was resolved.
    *   `canEnter()`: Check if entry is currently possible.
    *   `canActivate()`: Check if activation is currently possible.
    *   `canResolve()`: Check if resolution check is currently possible/relevant.
    *   `canClaim(address account)`: Check if a specific account can claim.
    *(Total: 14 functions)*

*   **`DimensionalRift`:** Implements `IDimensionalRift` and internal logic. Includes all functions from the interface. *(Total: 14 implemented + internal logic)*

*   **`QuantumLeapFactory`:**
    *   `constructor()`: Initializes owner and fees.
    *   `createRift()`: Deploys a new `DimensionalRift` instance (payable, requires fee).
    *   `getRiftAddress(uint256 riftId)`: Get address of a rift by its ID.
    *   `getRiftCount()`: Get the total number of rifts created.
    *   `getRiftState(uint256 riftId)`: Query the state of a specific rift.
    *   `getRiftParticipantCount(uint256 riftId)`: Query participant count of a specific rift.
    *   `getRiftTimeRemaining(uint256 riftId)`: Query time remaining for a specific rift.
    *   `pauseFactory()`: Owner can pause rift creation.
    *   `unpauseFactory()`: Owner can unpause rift creation.
    *   `setCreationFee(uint256 fee)`: Owner sets creation fee.
    *   `withdrawFees()`: Owner withdraws accumulated fees.
    *   `getCreationFee()`: Get current creation fee.
    *   `isPaused()`: Check if factory is paused.
    *   `getOwner()`: Get factory owner address.
    *   `transferOwnership(address newOwner)`: Transfer ownership.
    *   `renounceOwnership()`: Renounce ownership.
    *(Total: 16 functions)*

**Total Public/External Functions:** 14 (Rift interface/implementation) + 16 (Factory) = **30 functions**, meeting the requirement of at least 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Minimal library for address checks (optional, but good practice)
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on `extcodehash`. If the account has code, it's a contract.
        // Exception: contracts under construction (inside their constructor) will return hash of zeros.
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470; // Equivalent to keccak256("")
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != bytes32(0));
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        require(success, "Address: low-level call failed");
        return returndata;
    }
}


// Define the interface for the DimensionalRift contract
interface IDimensionalRift {
    enum RiftState { Created, OpenForEntry, Active, ResolvedSuccess, ResolvedFailure }
    enum ResolutionConditionType { MinParticipantsAndTime, SpecificTime, LinkedRiftSuccess } // Define types of resolution

    struct RiftParameters {
        string goal;                      // Description of the rift's objective
        uint256 duration;                 // Duration of the Active state in seconds
        uint256 maxParticipants;          // Maximum number of participants
        uint256 entryFee;                 // Fee to enter the rift (in wei)
        uint256 rewardPool;               // Amount to be distributed on success (in wei, can be 0)
        ResolutionConditionType conditionType; // How the rift resolves
        uint256 minParticipantsForSuccess; // Used with MinParticipantsAndTime
        uint256 linkedRiftIdForSuccess;   // Used with LinkedRiftSuccess (0 if not applicable)
        uint256 linkedRiftMinState;       // Used with LinkedRiftSuccess (e.g., ResolvedSuccess = 3)
    }

    // --- State Transition & Core Logic ---
    function enterRift() external payable;
    function activateRift() external; // Can only be called after entry period ends or max participants reached
    function checkAndResolveRift() external; // Callable by anyone after Active state starts
    function claimOutcome() external; // Participants claim based on resolution

    // --- View Functions ---
    function getCurrentState() external view returns (RiftState);
    function getParameters() external view returns (RiftParameters memory);
    function isParticipant(address account) external view returns (bool);
    function getParticipantCount() external view returns (uint256);
    function getTimeRemaining() external view returns (uint256); // Time until expected end of Active phase
    function getResolutionData() external view returns (bytes32 successData, bytes32 failureData); // Data about resolution (e.g., hash of winning state)
    function canEnter() external view returns (bool);
    function canActivate() external view returns (bool);
    function canResolve() external view returns (bool);
    function canClaim(address account) external view returns (bool);
}


// The contract deployed for each individual rift instance
contract DimensionalRift is IDimensionalRift {
    using Address for address;

    // --- State Variables ---
    IDimensionalRift.RiftParameters public immutable parameters;
    RiftState public currentState;
    address public immutable creator;
    address public immutable factoryAddress;
    mapping(address => bool) private participants;
    uint256 private participantCount;
    uint256 private creationTime;
    uint256 private entryEndTime; // Time when entry phase automatically ends
    uint256 private activeEndTime; // Time when Active phase automatically ends

    bytes32 private resolutionSuccessData; // Data recorded on success
    bytes32 private resolutionFailureData; // Data recorded on failure

    // Reentrancy guard
    uint private _guardCounter;
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }

    // State check modifier
    modifier inState(RiftState _state) {
        require(currentState == _state, "Rift: Invalid state");
        _;
    }

    // --- Events ---
    event EnteredRift(address indexed participant);
    event RiftActivated(uint256 activationTime);
    event RiftResolved(RiftState indexed state, bytes32 successData, bytes32 failureData);
    event OutcomeClaimed(address indexed claimant, uint256 amount, RiftState indexed resolvedState);

    // --- Constructor ---
    // Deployed by the factory
    constructor(
        address _factoryAddress,
        address _creator,
        RiftParameters memory _parameters
    ) {
        require(_factoryAddress != address(0), "Rift: Invalid factory address");
        require(_creator != address(0), "Rift: Invalid creator address");
        // Basic parameter validation (more comprehensive checks can be in factory)
        require(_parameters.duration > 0, "Rift: Duration must be > 0");
        require(_parameters.maxParticipants > 0, "Rift: Max participants must be > 0");
        if (_parameters.conditionType == ResolutionConditionType.MinParticipantsAndTime) {
            require(_parameters.minParticipantsForSuccess > 0 && _parameters.minParticipantsForSuccess <= _parameters.maxParticipants, "Rift: Invalid min participants for success");
        }
        if (_parameters.conditionType == ResolutionConditionType.LinkedRiftSuccess) {
             require(_parameters.linkedRiftIdForSuccess > 0, "Rift: Invalid linked rift ID"); // Assume rift ID 0 is invalid/unused
             // Can add more checks for linkedRiftMinState if specific values are required
        }

        factoryAddress = _factoryAddress;
        creator = _creator;
        parameters = _parameters;

        currentState = RiftState.Created; // Initial state upon creation
        creationTime = block.timestamp;
        entryEndTime = creationTime + 1 days; // Example: Entry phase lasts 1 day
        _guardCounter = 1; // Initialize reentrancy guard
    }

    // --- State Transition & Core Logic Implementations ---

    // Participants enter the rift
    function enterRift() external payable inState(RiftState.OpenForEntry) nonReentrant {
        require(msg.value == parameters.entryFee, "Rift: Incorrect entry fee");
        require(!participants[msg.sender], "Rift: Already a participant");
        require(participantCount < parameters.maxParticipants, "Rift: Rift is full");

        participants[msg.sender] = true;
        participantCount++;

        emit EnteredRift(msg.sender);

        // Automatically activate if max participants reached early
        if (participantCount == parameters.maxParticipants) {
            _activateRift();
        }
    }

    // Activate the rift, starting the active phase
    function activateRift() external inState(RiftState.OpenForEntry) {
        // Only allow activation if entry period is over or max participants reached (handled in enterRift)
        require(block.timestamp >= entryEndTime, "Rift: Entry period not over");
        _activateRift();
    }

    // Internal activation logic
    function _activateRift() internal {
         // Can only transition from OpenForEntry
        require(currentState == RiftState.OpenForEntry, "Rift: Not in OpenForEntry state");
        // Only activate if at least one participant joined (or define minimum based on parameters)
        require(participantCount > 0, "Rift: Cannot activate without participants");

        currentState = RiftState.Active;
        activeEndTime = block.timestamp + parameters.duration; // Active phase duration starts now
        emit RiftActivated(block.timestamp);
    }

    // Check resolution conditions and transition to Resolved state
    function checkAndResolveRift() external {
        require(currentState == RiftState.Active || currentState == RiftState.OpenForEntry, "Rift: Not in Active or OpenForEntry state for resolution check");

        // Only check resolution conditions if Active phase has started and potentially ended,
        // or if checking in OpenForEntry and linked rift condition is met.

        bool resolutionCheckRelevant = false;
        if (currentState == RiftState.Active) {
            resolutionCheckRelevant = (block.timestamp >= activeEndTime); // Standard time-based check
        } else if (currentState == RiftState.OpenForEntry) {
             // Allow checking linked rift condition even in OpenForEntry
             if (parameters.conditionType == ResolutionConditionType.LinkedRiftSuccess) {
                  resolutionCheckRelevant = true;
             }
        }


        if (!resolutionCheckRelevant) {
            revert("Rift: Resolution conditions not yet relevant");
        }


        bool success = false;
        bytes32 sData = bytes32(0);
        bytes32 fData = bytes32(0);

        if (parameters.conditionType == ResolutionConditionType.MinParticipantsAndTime) {
            // Success if minimum participants joined AND active duration is over
            if (currentState == RiftState.Active && participantCount >= parameters.minParticipantsForSuccess && block.timestamp >= activeEndTime) {
                 success = true;
                 sData = keccak256(abi.encodePacked("MinParticipantsAndTime_Success", participantCount, block.timestamp));
            } else if (currentState == RiftState.Active && block.timestamp >= activeEndTime) {
                 // Failure if active duration is over but minimum participants not met
                 success = false;
                 fData = keccak256(abi.encodePacked("MinParticipantsAndTime_Failure_MinParticipantsNotMet", participantCount, parameters.minParticipantsForSuccess));
            } else if (currentState == RiftState.OpenForEntry && block.timestamp >= entryEndTime) {
                // Failure if entry period ends and no participants or not enough to ever meet min
                 if (participantCount < parameters.minParticipantsForSuccess) {
                      success = false;
                      fData = keccak256(abi.encodePacked("MinParticipantsAndTime_Failure_EntryPeriodEnded", participantCount));
                 } else {
                     // If enough joined during entry, it must transition to active first
                     revert("Rift: Still in OpenForEntry but enough participants joined. Activate first.");
                 }
            } else {
                 revert("Rift: MinParticipantsAndTime conditions not met for resolution yet");
            }

        } else if (parameters.conditionType == ResolutionConditionType.SpecificTime) {
            // Success always if active duration is over (regardless of participants for this type)
             if (currentState == RiftState.Active && block.timestamp >= activeEndTime) {
                success = true; // Or define failure conditions for this type? Keeping it simple.
                sData = keccak256(abi.encodePacked("SpecificTime_Success", block.timestamp));
             } else if (currentState == RiftState.OpenForEntry && block.timestamp >= entryEndTime) {
                 // If entry ends, and it's specific time resolution, but active phase didn't start (no participants)
                 if (participantCount == 0) {
                      success = false;
                      fData = keccak256(abi.encodePacked("SpecificTime_Failure_NoParticipantsEntered"));
                 } else {
                      // Should have activated, force activation if needed? Or fail? Let's fail if didn't activate.
                       revert("Rift: Entry period ended with participants. Expected Active state.");
                 }
             }
             else {
                 revert("Rift: SpecificTime conditions not met for resolution yet");
            }

        } else if (parameters.conditionType == ResolutionConditionType.LinkedRiftSuccess) {
            // Requires interaction with another rift via the factory
            // Call the factory to get the state of the linked rift
            address linkedRiftAddress;
            try IDimensionalRift(factoryAddress).getRiftAddress(parameters.linkedRiftIdForSuccess) returns (address addr) {
                 linkedRiftAddress = addr;
            } catch {
                 revert("Rift: Cannot get address of linked rift");
            }
            require(linkedRiftAddress != address(0) && linkedRiftAddress != address(this), "Rift: Invalid or self-referencing linked rift address");

            IDimensionalRift.RiftState linkedRiftState;
             try IDimensionalRift(linkedRiftAddress).getCurrentState() returns (IDimensionalRift.RiftState state) {
                 linkedRiftState = state;
            } catch {
                 revert("Rift: Cannot get state of linked rift");
            }

            if (linkedRiftState == parameters.linkedRiftMinState) { // Check if linked rift is in the required state
                 success = true;
                 sData = keccak256(abi.encodePacked("LinkedRift_Success", parameters.linkedRiftIdForSuccess, linkedRiftState));
            } else if (linkedRiftState == RiftState.ResolvedFailure) { // If linked rift failed, this one fails too
                 success = false;
                 fData = keccak256(abi.encodePacked("LinkedRift_Failure_LinkedRiftFailed", parameters.linkedRiftIdForSuccess));
            }
            // Note: This linked check can happen anytime the linked rift reaches the target state, even if this rift is still OpenForEntry or Active.
            // If it resolves successfully based on the linked rift, it skips its own duration/participant checks.
            // If it resolves based on the linked rift failing, it also skips its own checks.

            // Add a fallback failure condition based on this rift's own duration/entry time if the linked rift never resolves correctly in time?
            // For simplicity, we'll assume the linked rift *will* resolve eventually.
             if (!success && linkedRiftState != RiftState.ResolvedFailure) {
                 revert("Rift: Linked rift condition not met for resolution yet");
             }

        } else {
            revert("Rift: Unknown resolution condition type");
        }

        // If we reached here, a resolution decision was made
        if (success) {
            currentState = RiftState.ResolvedSuccess;
            resolutionSuccessData = sData;
        } else {
            currentState = RiftState.ResolvedFailure;
            resolutionFailureData = fData;
        }

        emit RiftResolved(currentState, resolutionSuccessData, resolutionFailureData);
    }


    // Participants claim outcome based on resolution
    function claimOutcome() external nonReentrant {
        require(currentState == RiftState.ResolvedSuccess || currentState == RiftState.ResolvedFailure, "Rift: Rift not resolved");
        require(participants[msg.sender], "Rift: Not a participant");
        // Prevent double claiming (basic implementation: remove from participants map)
        require(participants[msg.sender], "Rift: Outcome already claimed"); // Check again in case of re-entrancy issues despite guard

        delete participants[msg.sender]; // Mark as claimed

        uint256 amountToSend = 0;
        if (currentState == RiftState.ResolvedFailure) {
            // Return entry fee on failure
            amountToSend = parameters.entryFee;
        } else if (currentState == RiftState.ResolvedSuccess) {
            // Distribute rewards proportional to stake (here, everyone staked the same, so distribute evenly)
            // Or simply return stake + a share of reward pool
            // Let's return stake + (rewardPool / total participants)
             if (participantCount > 0) { // Avoid division by zero
                 amountToSend = parameters.entryFee + (parameters.rewardPool / participantCount);
             } else {
                 amountToSend = parameters.entryFee; // Should not happen if activated, but safe check
             }
             // Ensure we don't try to send more than the contract holds
             amountToSend = amountToSend > address(this).balance ? address(this).balance : amountToSend;
        }

        if (amountToSend > 0) {
            // Using Address.sendValue is safer than transfer or call
            address(payable(msg.sender)).sendValue(amountToSend);
        }

        emit OutcomeClaimed(msg.sender, amountToSend, currentState);
    }


    // --- View Functions ---

    function getCurrentState() external view returns (RiftState) {
        return currentState;
    }

    function getParameters() external view returns (RiftParameters memory) {
        return parameters;
    }

    function isParticipant(address account) external view returns (bool) {
        return participants[account];
    }

    function getParticipantCount() external view returns (uint256) {
        return participantCount;
    }

    function getTimeRemaining() external view returns (uint256) {
        if (currentState == RiftState.Active && block.timestamp < activeEndTime) {
            return activeEndTime - block.timestamp;
        }
        if (currentState == RiftState.OpenForEntry && block.timestamp < entryEndTime) {
             return entryEndTime - block.timestamp; // Time until entry ends
        }
        return 0; // Rift not active or time is up
    }

    function getResolutionData() external view returns (bytes32 successData, bytes32 failureData) {
        require(currentState == RiftState.ResolvedSuccess || currentState == RiftState.ResolvedFailure, "Rift: Not resolved yet");
        return (resolutionSuccessData, resolutionFailureData);
    }

    function canEnter() external view returns (bool) {
        return currentState == RiftState.OpenForEntry && participantCount < parameters.maxParticipants;
    }

    function canActivate() external view returns (bool) {
        return currentState == RiftState.OpenForEntry && block.timestamp >= entryEndTime && participantCount > 0; // Must have participants
    }

    function canResolve() external view returns (bool) {
        if (currentState != RiftState.Active && currentState != RiftState.OpenForEntry) return false;

        if (parameters.conditionType == ResolutionConditionType.MinParticipantsAndTime || parameters.conditionType == ResolutionConditionType.SpecificTime) {
             return currentState == RiftState.Active && block.timestamp >= activeEndTime;
        } else if (parameters.conditionType == ResolutionConditionType.LinkedRiftSuccess) {
             // This one is tricky to check purely passively without calling the linked rift
             // A simple check: return true if in a state where resolution is theoretically possible.
             // The actual check happens in checkAndResolveRift
             return true;
        }
        return false; // Unknown type
    }

     function canClaim(address account) external view returns (bool) {
        return (currentState == RiftState.ResolvedSuccess || currentState == RiftState.ResolvedFailure) && participants[account];
    }

    // Fallback to receive entry fees and reward pool funds
    receive() external payable {
        // Only allow receiving ETH when entering the rift (handled by enterRift)
        // or receiving reward pool funds (sent by factory upon creation)
        // It's safer to handle reward pool internally in the factory and pass to constructor,
        // but allowing receive here for flexibility (e.g., funding after creation).
        // Adding basic state checks for received funds purpose
        require(msg.sender == factoryAddress || currentState == RiftState.OpenForEntry, "Rift: Unexpected ETH received");
        // If state is OpenForEntry, it must be the entryFee amount, handled by enterRift.
        // If sender is factory, assume it's reward pool funds.
    }

    // Prevent sending ETH out accidentally
    fallback() external payable {
        revert("Rift: Unexpected fallback call");
    }
}


// The factory contract that deploys DimensionalRift instances
contract QuantumLeapFactory {
    using Address for address;

    // --- State Variables ---
    uint256 private riftCount;
    mapping(uint256 => address) public rifts; // riftId => riftAddress

    address private _owner;
    bool private _paused;
    uint256 private _creationFee;

    // --- Events ---
    event RiftCreated(uint256 indexed riftId, address indexed riftAddress, address indexed creator, IDimensionalRift.RiftParameters parameters);
    event FactoryPaused(address indexed account);
    event FactoryUnpaused(address indexed account);
    event CreationFeeSet(uint256 fee);
    event FeesWithdrawn(address indexed account, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        riftCount = 0;
        _paused = false;
        _creationFee = 0.01 ether; // Example default fee
    }

    // --- Factory Core Logic ---

    // Create a new DimensionalRift instance
    function createRift(IDimensionalRift.RiftParameters memory parameters) external payable whenNotPaused returns (uint256 riftId) {
        require(msg.value >= _creationFee, "Factory: Insufficient creation fee");
        // Deduct fee before creating contract
        uint256 feeToKeep = _creationFee;
        uint256 rewardPoolAmount = msg.value - _creationFee; // Remaining ETH is considered reward pool for the rift

        // Basic parameter validation before deployment
        require(parameters.duration > 0, "Factory: Invalid duration");
        require(parameters.maxParticipants > 0, "Factory: Invalid max participants");
        // Add more validation matching the Rift contract's constructor requirements
        if (parameters.conditionType == IDimensionalRift.ResolutionConditionType.MinParticipantsAndTime) {
            require(parameters.minParticipantsForSuccess > 0 && parameters.minParticipantsForSuccess <= parameters.maxParticipants, "Factory: Invalid min participants for success");
        }
         if (parameters.conditionType == IDimensionalRift.ResolutionConditionType.LinkedRiftSuccess) {
             require(parameters.linkedRiftIdForSuccess > 0, "Factory: Invalid linked rift ID (must be > 0)");
             // Optional: Check if linkedRiftIdForSuccess actually corresponds to an existing rift
             // This would require calling getRiftAddress which adds complexity.
             // For simplicity, the validation happens in the Rift contract's checkAndResolve function.
        }
        parameters.rewardPool = rewardPoolAmount; // Set the reward pool amount from the received ETH

        uint256 currentId = ++riftCount;
        DimensionalRift newRift = new DimensionalRift(address(this), msg.sender, parameters);
        rifts[currentId] = address(newRift);

        // Send the collected reward pool ETH to the new rift contract
        if (rewardPoolAmount > 0) {
             // Use low-level call with address library for safety
             address(newRift).sendValue(rewardPoolAmount);
        }

        // Transfer the creation fee to the factory
        // Note: The fee is already part of msg.value received by the factory
        // No separate transfer needed here, just ensure the factory holds it.

        emit RiftCreated(currentId, address(newRift), msg.sender, parameters);

        return currentId;
    }

    // --- Management Functions ---

    function pauseFactory() external onlyOwner whenNotPaused {
        _paused = true;
        emit FactoryPaused(msg.sender);
    }

    function unpauseFactory() external onlyOwner whenPaused {
        _paused = false;
        emit FactoryUnpaused(msg.sender);
    }

    function setCreationFee(uint256 fee) external onlyOwner {
        require(fee >= 0, "Factory: Fee cannot be negative"); // Redundant due to uint, but good practice
        _creationFee = fee;
        emit CreationFeeSet(fee);
    }

    function withdrawFees() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "Factory: No fees to withdraw");
        address payable ownerAddress = payable(_owner);
        ownerAddress.sendValue(balance);
        emit FeesWithdrawn(msg.sender, balance);
    }

    // --- View Functions (Querying Rifts & Factory State) ---

    function getRiftAddress(uint256 riftId) public view returns (address) {
        require(riftId > 0 && riftId <= riftCount, "Factory: Invalid rift ID");
        return rifts[riftId];
    }

    function getRiftCount() external view returns (uint256) {
        return riftCount;
    }

    // Example of querying a rift's state by calling its contract
    function getRiftState(uint256 riftId) external view returns (IDimensionalRift.RiftState) {
        address riftAddr = getRiftAddress(riftId); // Validates riftId
        IDimensionalRift rift = IDimensionalRift(riftAddr);
        return rift.getCurrentState();
    }

    // Example of querying a rift's participant count
    function getRiftParticipantCount(uint256 riftId) external view returns (uint256) {
        address riftAddr = getRiftAddress(riftId); // Validates riftId
        IDimensionalRift rift = IDimensionalRift(riftAddr);
        return rift.getParticipantCount();
    }

     // Example of querying a rift's time remaining
    function getRiftTimeRemaining(uint256 riftId) external view returns (uint256) {
        address riftAddr = getRiftAddress(riftId); // Validates riftId
        IDimensionalRift rift = IDimensionalRift(riftAddr);
        return rift.getTimeRemaining();
    }

    function getCreationFee() external view returns (uint256) {
        return _creationFee;
    }

    function isPaused() external view returns (bool) {
        return _paused;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    // --- Ownership Functions (standard) ---

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0); // Owner becomes zero address, effectively making contract unowned
    }

    // Fallback to receive creation fees
    receive() external payable {
        // ETH sent directly to the factory without calling createRift will just increase its balance.
        // withdrawFees can collect this.
    }

    // Prevent accidental calls
    fallback() external payable {
         revert("Factory: Unexpected fallback call");
    }
}
```