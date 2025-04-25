Okay, here is a Solidity smart contract implementing a complex, dynamic NFT system with concepts like time-based decay, energy harvesting, state changes influenced by randomness, and internal mechanics. It's certainly not a standard ERC-721 or common DeFi protocol.

It includes an outline and function summary as requested.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/SharedTypes.sol";

// Outline:
// 1. Smart Contract Definition: QuantumFluctuations inherits ERC721Enumerable, Ownable, VRFConsumerBaseV2.
// 2. Error Handling: Custom errors for specific failure conditions.
// 3. Events: Log significant contract actions.
// 4. Data Structures: Enum for Fluctuation states, Struct for Fluctuation properties.
// 5. State Variables: Store contract configuration, NFT data, VRF details, user harvestable energy.
// 6. Modifiers: Custom modifiers for access control and state checks.
// 7. Constructor: Initialize base ERC721, VRF, and initial contract parameters.
// 8. ERC721 Standard Functions: Implement required ERC721Enumerable functions (already mostly handled by inheritance).
//    - balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
//    - transferFrom, safeTransferFrom
//    - supportsInterface
//    - totalSupply, tokenByIndex, tokenOfOwnerByIndex, tokenURI
// 9. Core Quantum Fluctuation Logic:
//    - captureFluctuation: Create a new fluctuation NFT (cost involved).
//    - getFluctuationDetails: Retrieve current details of a fluctuation, applying decay/state changes on read.
//    - harvestEnergy: Extract 'energy' from a fluctuation, adding to user's harvestable balance (cooldown, state dependencies).
//    - stabilizeFluctuation: Attempt to stabilize a fluctuation (reduce decay, cost, relies on randomness).
// 10. Harvestable Energy Management:
//     - withdrawHarvestedEnergy: Allow users to withdraw their accumulated harvestable energy.
//     - getHarvestableEnergy: Check a user's current harvestable energy balance.
// 11. Chainlink VRF Integration:
//     - requestRandomness: Trigger a VRF request (internal helper).
//     - rawFulfillRandomness: VRF callback to process random result and apply effects (e.g., stabilization outcome).
// 12. Admin/Owner Functions: Configure contract parameters, manage VRF subscription, emergency withdrawal.
//     - setCaptureCost
//     - setStabilizationCost
//     - setBaseDecayRate
//     - setHarvestRate
//     - setHarvestCooldown
//     - setVrfConfig
//     - withdrawContractETH (Emergency)
//     - triggerPhaseShift (Admin initiated, uses randomness to affect all fluctuations)
//     - fulfillPhaseShift (VRF callback handler for phase shift)
// 13. Internal Helper Functions:
//     - _updateFluctuationState: Calculates current energy and updates state based on time/rules.
//     - _transfer: ERC721 internal transfer hook (basic implementation).

// Function Summary:
// - constructor(string memory name, string memory symbol, address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit): Initializes contract, ERC721, VRF.
// - supportsInterface(bytes4 interfaceId): Checks if contract supports an interface (ERC721, Enumerable).
// - balanceOf(address owner): Returns the number of fluctuations owned by an address.
// - ownerOf(uint256 tokenId): Returns the owner of a fluctuation.
// - approve(address to, uint256 tokenId): Approves an address to transfer a specific fluctuation.
// - getApproved(uint256 tokenId): Gets the approved address for a fluctuation.
// - setApprovalForAll(address operator, bool approved): Approves/disapproves an operator for all owner's fluctuations.
// - isApprovedForAll(address owner, address operator): Checks if an operator is approved for an owner.
// - transferFrom(address from, address to, uint256 tokenId): Transfers a fluctuation (standard).
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Transfers a fluctuation safely (standard).
// - safeTransferFrom(address from, address to, uint256 tokenId): Transfers a fluctuation safely (standard).
// - totalSupply(): Returns the total number of fluctuations minted.
// - tokenByIndex(uint256 index): Returns the token ID at an index (Enumerable).
// - tokenOfOwnerByIndex(address owner, uint256 index): Returns token ID of owner at index (Enumerable).
// - tokenURI(uint256 tokenId): Returns URI for token metadata (placeholder).
// - captureFluctuation() payable: Mints a new fluctuation for the sender, costs ether, randomizes initial decay.
// - getFluctuationDetails(uint256 tokenId): Returns detailed information about a fluctuation after updating its state.
// - harvestEnergy(uint256 tokenId): Allows owner to harvest energy, reduces fluctuation energy, adds to user balance.
// - estimateHarvestAmount(uint256 tokenId) view: Estimates potential harvest from a fluctuation.
// - stabilizeFluctuation(uint256 tokenId) payable: Attempts to stabilize a fluctuation (reduce decay), costs ether, triggers randomness request.
// - estimateStabilizationCost(uint256 tokenId) view: Returns the cost to attempt stabilization.
// - rawFulfillRandomness(uint256 requestId, uint256[] memory randomWords): VRF callback, processes random results for stabilization/phase shift.
// - withdrawHarvestedEnergy(): Allows a user to withdraw their accumulated harvestable energy balance (as ETH).
// - getHarvestableEnergy(address user) view: Gets the harvestable energy balance for a user.
// - setCaptureCost(uint256 _cost): Admin sets the cost to capture a new fluctuation.
// - setStabilizationCost(uint256 _cost): Admin sets the cost to attempt stabilization.
// - setBaseDecayRate(uint256 _rate): Admin sets the base energy decay rate.
// - setHarvestRate(uint256 _rate): Admin sets the rate of energy conversion to harvestable balance.
// - setHarvestCooldown(uint256 _duration): Admin sets the harvest cooldown duration.
// - setVrfConfig(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId, uint32 callbackGasLimit): Admin sets VRF parameters.
// - withdrawContractETH(address payable to): Admin withdraws ETH from the contract (emergency/fee collection).
// - triggerPhaseShift() onlyOwner: Admin initiates a contract-wide phase shift event (uses randomness).
// - fulfillPhaseShift(uint256[] memory randomWords) internal: Handles the VRF callback for a phase shift event.
// - _updateFluctuationState(uint256 tokenId) internal: Internal helper to calculate current energy and update fluctuation state.
// - _transfer(address from, address to, uint256 tokenId) internal: ERC721 internal transfer override (basic).

error InvalidFluctuationId();
error NotFluctuationOwner();
error NotApprovedOrOwner();
error CannotHarvestAnnihilated();
error HarvestCooldownActive(uint256 timeRemaining);
error InsufficientEnergyForHarvest();
error RandomnessRequestFailed();
error CannotFulfillRandomness();
error NothingToWithdraw();
error InvalidPhaseShiftRequest();
error PhaseShiftNotTriggered();

enum FluctuationState {
    Stable,
    Volatile,
    Decaying,
    Annihilated
}

struct Fluctuation {
    uint256 creationTime;
    uint256 decayRate; // Energy units lost per second
    uint256 currentEnergyLevel;
    FluctuationState state;
    uint256 lastHarvestTime;
    uint256 lastStateUpdateTime; // Timestamp when state was last explicitly updated/calculated
    bool needsStateUpdate; // Flag to indicate if state should be updated before returning details/acting
}

mapping(uint256 => Fluctuation) private _fluctuations;
uint256 private _tokenIdCounter;

// Contract Configuration
uint256 public captureCost = 0.01 ether;
uint256 public stabilizationCost = 0.005 ether;
uint256 public baseDecayRate = 1e15; // Base energy lost per second (adjust based on desired total energy units)
uint256 public initialEnergy = 1e21; // Initial energy level
uint256 public harvestRate = 1e17; // Energy units harvested per call (can be dynamic)
uint256 public harvestCooldown = 1 days; // Cooldown for harvesting

// Harvestable energy balance for users (stored in contract)
mapping(address => uint256) public harvestableEnergy;

// Chainlink VRF V2
bytes32 public keyHash;
uint64 public subscriptionId;
uint32 public callbackGasLimit;
uint16 constant requestConfirmations = 3;
uint32 constant numWords = 1;

// State for VRF requests
mapping(uint256 => uint256) private s_requests; // Stores the token ID for stabilization requests
uint256 private s_phaseShiftRequestId; // Stores the request ID for a triggered phase shift

constructor(string memory name, string memory symbol, address vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId, uint32 _callbackGasLimit)
    ERC721(name, symbol)
    ERC721Enumerable()
    Ownable(msg.sender)
    VRFConsumerBaseV2(vrfCoordinator)
{
    keyHash = _keyHash;
    subscriptionId = _subscriptionId;
    callbackGasLimit = _callbackGasLimit;
    _tokenIdCounter = 0; // Start with token ID 1 or 0? Let's use 1 for simplicity with counter
}

// --- ERC721Enumerable Overrides ---

function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
}

function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
    return super._update(to, tokenId, auth);
}

function _increaseBalance(address account, uint256 amount) internal override(ERC721, ERC721Enumerable) {
    super._increaseBalance(account, amount);
}

function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal override(ERC721, ERC721Enumerable) {
    super._safeTransfer(from, to, tokenId, data);
}

// Standard ERC721 functions inherited or implemented by ERC721Enumerable:
// - balanceOf(address owner)
// - ownerOf(uint256 tokenId)
// - approve(address to, uint256 tokenId)
// - getApproved(uint256 tokenId)
// - setApprovalForAll(address operator, bool approved)
// - isApprovedForAll(address owner, address operator)
// - transferFrom(address from, address to, uint256 tokenId)
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
// - safeTransferFrom(address from, address to, uint256 tokenId)
// - totalSupply()
// - tokenByIndex(uint256 index)
// - tokenOfOwnerByIndex(address owner, uint256 index)

// --- Custom Quantum Fluctuation Logic ---

function tokenURI(uint256 tokenId) public view override returns (string memory) {
    if (!_exists(tokenId)) {
        revert InvalidFluctuationId();
    }
    // Placeholder: In a real app, this would return a URL to JSON metadata
    // that might describe the fluctuation's current state (fetched via getFluctuationDetails off-chain).
    return string(abi.encodePacked("ipfs://your_metadata_base_uri/", Strings.toString(tokenId)));
}

/// @notice Allows a user to capture a new Quantum Fluctuation.
/// @dev Requires sending `captureCost` ETH. Randomizes initial decay rate.
function captureFluctuation() external payable {
    if (msg.value < captureCost) {
        revert InsufficientFunds();
    }

    uint256 newTokenId = _tokenIdCounter + 1;
    _tokenIdCounter = newTokenId;

    // Basic randomness for initial decay rate (better with VRF if possible, but costs)
    uint256 initialDecayJitter = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newTokenId, block.difficulty))) % (baseDecayRate / 2);
    uint256 initialDecay = baseDecayRate + initialDecayJitter;

    _fluctuations[newTokenId] = Fluctuation({
        creationTime: block.timestamp,
        decayRate: initialDecay,
        currentEnergyLevel: initialEnergy,
        state: FluctuationState.Stable, // Starts stable
        lastHarvestTime: 0,
        lastStateUpdateTime: block.timestamp,
        needsStateUpdate: false // Just minted, state is current
    });

    _safeMint(msg.sender, newTokenId);

    emit FluctuationCaptured(newTokenId, msg.sender, initialEnergy, initialDecay);
}

/// @notice Gets the current state and details of a fluctuation, applying decay and state changes if needed.
/// @param tokenId The ID of the fluctuation.
/// @return Fluctuation struct containing the updated details.
function getFluctuationDetails(uint256 tokenId) public returns (Fluctuation memory) {
    if (!_exists(tokenId)) {
        revert InvalidFluctuationId();
    }
    // Update state before returning details
    _updateFluctuationState(tokenId);
    return _fluctuations[tokenId];
}

/// @notice Allows the owner to harvest energy from a fluctuation.
/// @dev Adds harvested energy to the owner's harvestable balance. Reduces fluctuation energy. Subject to cooldown.
/// @param tokenId The ID of the fluctuation to harvest from.
function harvestEnergy(uint256 tokenId) public {
    if (ownerOf(tokenId) != msg.sender) {
        revert NotFluctuationOwner();
    }

    _updateFluctuationState(tokenId); // Ensure state is current before harvesting

    Fluctuation storage fluctuation = _fluctuations[tokenId];

    if (fluctuation.state == FluctuationState.Annihilated) {
        revert CannotHarvestAnnihilated();
    }
    if (block.timestamp < fluctuation.lastHarvestTime + harvestCooldown) {
        revert HarvestCooldownActive(fluctuation.lastHarvestTime + harvestCooldown - block.timestamp);
    }
    if (fluctuation.currentEnergyLevel < harvestRate) {
         revert InsufficientEnergyForHarvest(); // Or harvest remaining energy
    }

    uint256 harvestedAmount = harvestRate; // Or could be proportional to current energy

    fluctuation.currentEnergyLevel -= harvestedAmount;
    fluctuation.lastHarvestTime = block.timestamp;
    fluctuation.needsStateUpdate = true; // State likely changed after harvesting

    harvestableEnergy[msg.sender] += harvestedAmount;

    emit EnergyHarvested(tokenId, msg.sender, harvestedAmount, fluctuation.currentEnergyLevel);
}

/// @notice Estimates the amount of energy that would be harvested from a fluctuation.
/// @dev Does NOT apply state changes or checks like cooldown. Use `getFluctuationDetails` for current state.
/// @param tokenId The ID of the fluctuation.
/// @return Estimated harvest amount.
function estimateHarvestAmount(uint256 tokenId) public view returns (uint256) {
     if (!_exists(tokenId)) {
        revert InvalidFluctuationId();
    }
    // This is a simple estimate based on config, doesn't factor in current state or cooldown
    return harvestRate;
}

/// @notice Attempts to stabilize a fluctuation, potentially reducing its decay rate.
/// @dev Costs `stabilizationCost` ETH. Requires a VRF request for the outcome.
/// @param tokenId The ID of the fluctuation to stabilize.
function stabilizeFluctuation(uint256 tokenId) public payable {
    if (ownerOf(tokenId) != msg.sender) {
        revert NotFluctuationOwner();
    }
    if (msg.value < stabilizationCost) {
        revert InsufficientFunds();
    }
    if (_fluctuations[tokenId].state == FluctuationState.Annihilated) {
         revert CannotStabilizeAnnihilated();
    }

    // Request randomness for the outcome of stabilization
    uint256 requestId = requestRandomness(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);

    s_requests[requestId] = tokenId; // Map request ID to token ID

    emit StabilizationAttempt(tokenId, msg.sender, requestId);
}

/// @notice Estimates the cost to attempt stabilization of a fluctuation.
/// @param tokenId The ID of the fluctuation (only checks existence).
/// @return The stabilization cost.
function estimateStabilizationCost(uint256 tokenId) public view returns (uint256) {
     if (!_exists(tokenId)) {
        revert InvalidFluctuationId();
    }
    return stabilizationCost;
}

/// @notice Chainlink VRF callback function. Processes random results.
/// @dev This function is called by the VRF Coordinator after a request is fulfilled.
/// @param requestId The ID of the VRF request.
/// @param randomWords The array of random words generated.
function rawFulfillRandomness(uint256 requestId, uint256[] memory randomWords) internal override {
    if (randomWords.length == 0) {
         revert CannotFulfillRandomness();
    }
    uint256 randomness = randomWords[0];

    // Check if this request was for stabilization
    uint256 tokenId = s_requests[requestId];
    if (tokenId != 0 && _exists(tokenId)) { // Check if token exists and was a valid request
        delete s_requests[requestId]; // Clean up request mapping

        Fluctuation storage fluctuation = _fluctuations[tokenId];

        // Apply stabilization outcome based on randomness
        // Example logic: 50% chance to reduce decay, 10% chance to slightly increase energy
        uint256 outcome = randomness % 100; // Scale randomness to 0-99

        if (outcome < 50) { // 50% chance of decay reduction
            uint256 reduction = fluctuation.decayRate / 4; // Reduce decay by 25%
            fluctuation.decayRate = fluctuation.decayRate > reduction ? fluctuation.decayRate - reduction : 0;
            emit FluctuationStabilized(tokenId, true, fluctuation.decayRate, "Decay Reduced");
        } else if (outcome < 60) { // 10% chance of energy boost
            uint256 boost = initialEnergy / 100; // Add 1% of initial energy
            fluctuation.currentEnergyLevel += boost;
             emit FluctuationStabilized(tokenId, true, fluctuation.decayRate, "Energy Boosted");
        } else { // 40% chance of failure or minor effect
             emit FluctuationStabilized(tokenId, false, fluctuation.decayRate, "Stabilization Failed");
        }
        fluctuation.needsStateUpdate = true; // State might need re-evaluation

    } else if (s_phaseShiftRequestId == requestId) { // Check if this request was for a phase shift
        delete s_phaseShiftRequestId; // Clean up phase shift request

        fulfillPhaseShift(randomWords);

    } else {
        // Unrecognized request ID - could log or ignore
        emit UnrecognizedRandomnessRequest(requestId);
    }
}

/// @notice Allows a user to withdraw their accumulated harvestable energy as ETH.
function withdrawHarvestedEnergy() public {
    uint256 amount = harvestableEnergy[msg.sender];
    if (amount == 0) {
        revert NothingToWithdraw();
    }

    harvestableEnergy[msg.sender] = 0;

    // Convert harvestable energy units to ETH (example conversion)
    // This conversion rate is crucial and should be carefully considered.
    // Here, 1e18 energy units = 1 ETH for simplicity, but could be different.
    uint256 ethAmount = amount / 1e18;

    if (ethAmount == 0) {
         // Amount was less than 1e18 energy units, don't send 0 ETH.
         // Return the energy units to the user's balance or keep track of dust.
         // For simplicity here, let's just require a minimum withdrawal or lose dust.
         // Reverting is safer if conversion is intended to be exact.
         // Let's send if > 0 or revert.
        if (amount > 0) harvestableEnergy[msg.sender] = amount; // return dust
         revert NothingToWithdraw(); // Or custom error InsufficientHarvestableEnergyForWithdrawal
    }

    (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
    if (!success) {
        // If send fails, return the energy to the user's balance
        harvestableEnergy[msg.sender] += amount;
        revert EthTransferFailed(); // Custom error
    }

    emit HarvestableEnergyWithdrawn(msg.sender, amount, ethAmount);
}

/// @notice Gets the harvestable energy balance for a specific user.
/// @param user The address of the user.
/// @return The harvestable energy balance.
function getHarvestableEnergy(address user) public view returns (uint256) {
    return harvestableEnergy[user];
}

// --- Admin/Owner Functions ---

/// @notice Sets the cost to capture a new fluctuation.
/// @param _cost The new capture cost in wei.
function setCaptureCost(uint256 _cost) public onlyOwner {
    captureCost = _cost;
    emit CaptureCostUpdated(_cost);
}

/// @notice Sets the cost to attempt stabilization.
/// @param _cost The new stabilization cost in wei.
function setStabilizationCost(uint256 _cost) public onlyOwner {
    stabilizationCost = _cost;
    emit StabilizationCostUpdated(_cost);
}

/// @notice Sets the base energy decay rate.
/// @param _rate The new base decay rate (energy units per second).
function setBaseDecayRate(uint256 _rate) public onlyOwner {
    baseDecayRate = _rate;
     emit BaseDecayRateUpdated(_rate);
}

/// @notice Sets the rate at which energy is converted to harvestable energy.
/// @param _rate The new harvest rate (energy units harvested per call).
function setHarvestRate(uint256 _rate) public onlyOwner {
    harvestRate = _rate;
     emit HarvestRateUpdated(_rate);
}

/// @notice Sets the cooldown duration for harvesting.
/// @param _duration The new cooldown duration in seconds.
function setHarvestCooldown(uint256 _duration) public onlyOwner {
    harvestCooldown = _duration;
     emit HarvestCooldownUpdated(_duration);
}


/// @notice Sets Chainlink VRF configuration parameters.
/// @param vrfCoordinator The address of the VRF coordinator contract.
/// @param _keyHash The VRF key hash.
/// @param _subscriptionId The VRF subscription ID.
/// @param _callbackGasLimit The callback gas limit for fulfillments.
function setVrfConfig(address vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId, uint32 _callbackGasLimit) public onlyOwner {
    COORDINATOR = IVRFCoordinatorV2Plus(vrfCoordinator); // Update the base VRFConsumerV2Plus coordinator address
    keyHash = _keyHash;
    subscriptionId = _subscriptionId;
    callbackGasLimit = _callbackGasLimit;
     emit VrfConfigUpdated(vrfCoordinator, _keyHash, _subscriptionId, _callbackGasLimit);
}


/// @notice Allows owner to withdraw ETH from the contract (e.g., collected fees).
/// @param to The address to send the ETH to.
function withdrawContractETH(address payable to) public onlyOwner {
    uint256 balance = address(this).balance;
    if (balance == 0) {
        revert NothingToWithdraw();
    }
    (bool success, ) = to.call{value: balance}("");
    if (!success) {
        revert EthTransferFailed();
    }
    emit ContractETHWithdrawn(to, balance);
}

/// @notice Admin can trigger a contract-wide phase shift event.
/// @dev This requests randomness which, when fulfilled, will affect all fluctuations.
function triggerPhaseShift() public onlyOwner {
    if (s_phaseShiftRequestId != 0) {
        revert PhaseShiftAlreadyTriggered(); // Prevent multiple requests
    }

    uint256 requestId = requestRandomness(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    s_phaseShiftRequestId = requestId;

    emit PhaseShiftTriggered(requestId);
}

/// @notice Internal function to handle the outcome of a phase shift VRF request.
/// @dev Applies effects to all fluctuations based on the random result.
/// @param randomWords The random words from the VRF callback.
function fulfillPhaseShift(uint256[] memory randomWords) internal {
    if (randomWords.length == 0) {
         revert CannotFulfillRandomness();
    }
    uint256 randomness = randomWords[0];

    // Apply a random effect to ALL fluctuations
    // Example: A small chance to boost energy, or increase decay globally, or change state probabilities
    uint256 outcome = randomness % 100; // Scale randomness to 0-99

    if (outcome < 10) { // 10% chance: Global energy boost
        uint256 boostPerFluctuation = initialEnergy / 50; // Boost each by 2% of initial
         uint256 totalFluctuations = totalSupply();
        for (uint256 i = 0; i < totalFluctuations; i++) {
            uint256 tokenId = tokenByIndex(i);
            if (_exists(tokenId) && _fluctuations[tokenId].state != FluctuationState.Annihilated) {
                 _fluctuations[tokenId].currentEnergyLevel += boostPerFluctuation;
                 _fluctuations[tokenId].needsStateUpdate = true; // State might change
            }
        }
        emit GlobalPhaseShiftEffect("Global Energy Boost", boostPerFluctuation);

    } else if (outcome < 20) { // 10% chance: Global decay acceleration
        uint255 acceleration = baseDecayRate / 10; // Increase decay by 10%
         uint256 totalFluctuations = totalSupply();
        for (uint256 i = 0; i < totalFluctuations; i++) {
            uint256 tokenId = tokenByIndex(i);
             if (_exists(tokenId) && _fluctuations[tokenId].state != FluctuationState.Annihilated) {
                _fluctuations[tokenId].decayRate += acceleration;
                 _fluctuations[tokenId].needsStateUpdate = true; // State might change
             }
        }
        emit GlobalPhaseShiftEffect("Global Decay Acceleration", acceleration);

    } else if (outcome < 30) { // 10% chance: Random state change for a few
        uint256 totalFluctuations = totalSupply();
        uint256 numToAffect = totalFluctuations > 5 ? 5 : totalFluctuations; // Affect up to 5
        for (uint256 i = 0; i < numToAffect; i++) {
             uint256 randomIndex = (randomness + i) % totalFluctuations; // Use randomness to pick different ones
             uint256 tokenId = tokenByIndex(randomIndex);
             if (_exists(tokenId) && _fluctuations[tokenId].state != FluctuationState.Annihilated) {
                uint256 randomStateIndex = (randomness + i) % 3; // Pick Stable, Volatile, Decaying (0, 1, 2)
                 if (randomStateIndex == 0) _fluctuations[tokenId].state = FluctuationState.Stable;
                 else if (randomStateIndex == 1) _fluctuations[tokenId].state = FluctuationState.Volatile;
                 else _fluctuations[tokenId].state = FluctuationState.Decaying;
                 _fluctuations[tokenId].needsStateUpdate = false; // State is now set
                 emit FluctuationStateChanged(tokenId, _fluctuations[tokenId].state);
            }
        }
        emit GlobalPhaseShiftEffect("Random State Jitter", numToAffect);

    } else {
        // 70% chance: Minor or no global effect
        emit GlobalPhaseShiftEffect("Minor/No Effect", 0);
    }

    emit PhaseShiftFulfilled(randomness);
}


// --- Internal Helpers ---

/// @dev Calculates the current energy level and updates the state of a fluctuation based on time and decay rate.
/// @param tokenId The ID of the fluctuation to update.
function _updateFluctuationState(uint256 tokenId) internal {
    Fluctuation storage fluctuation = _fluctuations[tokenId];

    // Only update if needed or if state is Annihilated (already final)
    if (!fluctuation.needsStateUpdate || fluctuation.state == FluctuationState.Annihilated) {
        return;
    }

    uint256 timeElapsed = block.timestamp - fluctuation.lastStateUpdateTime;
    uint256 energyLoss = timeElapsed * fluctuation.decayRate;

    if (energyLoss >= fluctuation.currentEnergyLevel) {
        fluctuation.currentEnergyLevel = 0;
        fluctuation.state = FluctuationState.Annihilated;
    } else {
        fluctuation.currentEnergyLevel -= energyLoss;
        // State transitions based on energy level (example thresholds)
        if (fluctuation.currentEnergyLevel == 0) {
            fluctuation.state = FluctuationState.Annihilated;
        } else if (fluctuation.currentEnergyLevel < initialEnergy / 10) { // Below 10% energy
            fluctuation.state = FluctuationState.Decaying;
        } else if (fluctuation.decayRate > baseDecayRate * 1.5) { // High decay rate relative to base
             fluctuation.state = FluctuationState.Volatile;
        } else { // Default to Stable if not Annihilated, Decaying, or Volatile based on simple rules
             fluctuation.state = FluctuationState.Stable;
        }
        // Note: Volatile state based *purely* on decay rate here. Could add randomness check.
    }

    fluctuation.lastStateUpdateTime = block.timestamp;
    fluctuation.needsStateUpdate = false; // State is now current

    // Log state change if it happened
    if (fluctuation.state != getFluctuationDetails(tokenId).state) { // Compare with state BEFORE update
         emit FluctuationStateChanged(tokenId, fluctuation.state);
    }
}

// Override base _transfer to potentially add hooks or state checks if needed
function _transfer(address from, address to, uint256 tokenId) internal override {
     // You could add checks here, e.g., prevent transfer if state is Annihilated, but for
     // this example, we'll keep transfers standard ERC721.
    super._transfer(from, to, tokenId);
    // Note: State is updated on read/action, not automatically on transfer.
    // The recipient should call getFluctuationDetails to see the true state.
}

// --- Events ---
event FluctuationCaptured(uint256 indexed tokenId, address indexed owner, uint256 initialEnergy, uint256 initialDecayRate);
event FluctuationStateChanged(uint256 indexed tokenId, FluctuationState newState);
event EnergyHarvested(uint256 indexed tokenId, address indexed harvester, uint256 amount, uint256 remainingEnergy);
event StabilizationAttempt(uint256 indexed tokenId, address indexed owner, uint256 indexed requestId);
event FluctuationStabilized(uint256 indexed tokenId, bool success, uint256 newDecayRate, string message);
event HarvestableEnergyWithdrawn(address indexed user, uint256 amountEnergy, uint256 amountETH);
event CaptureCostUpdated(uint256 newCost);
event StabilizationCostUpdated(uint256 newCost);
event BaseDecayRateUpdated(uint256 newRate);
event HarvestRateUpdated(uint256 newRate);
event HarvestCooldownUpdated(uint256 newDuration);
event VrfConfigUpdated(address indexed vrfCoordinator, bytes32 indexed keyHash, uint64 subscriptionId, uint32 callbackGasLimit);
event ContractETHWithdrawn(address indexed to, uint256 amount);
event PhaseShiftTriggered(uint256 indexed requestId);
event PhaseShiftFulfilled(uint256 indexed randomness);
event GlobalPhaseShiftEffect(string effectType, uint256 value);
event UnrecognizedRandomnessRequest(uint256 indexed requestId);


// --- Custom Errors ---
// Already defined at the top for clarity.
error InsufficientFunds();
error EthTransferFailed();
error CannotStabilizeAnnihilated();
error PhaseShiftAlreadyTriggered();


}
```