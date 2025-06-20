Okay, here is a Solidity smart contract concept for a "Dynamic Asset Forge".

This contract introduces a type of digital asset (let's call them "Essences") that have properties which dynamically change over time and through interactions. It incorporates concepts like timed decay/growth, state changes based on actions, staking with dynamic yield, oracle interaction for external influence, asset fusion/refinement, and even a predictive function.

This design is intended to be creative and advanced by combining several distinct mechanics into a single asset type, moving beyond static tokens or simple NFTs. It's not a direct copy of standard ERCs or common DeFi protocols but integrates *elements* of these ideas in a novel way.

**Note:** This is a complex concept. Some parts, like the oracle interaction, are simplified (e.g., assuming a trusted oracle or callback mechanism structure) for demonstration purposes within a single contract file. A real-world implementation might use Chainlink or other decentralized oracle networks, which involve specific request-and-receive patterns. Staking rewards are also simplified to avoid needing a full token economic model.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DynamicAssetForge
 * @dev A contract for forging, managing, and interacting with dynamic digital assets ("Essences").
 * Essences have properties (Purity, Power) that change over time and based on actions.
 * Features: Forging, Fusion, Refinement, Staking, Oracle Attunement, Time-based Decay/Growth, Prediction.
 * This contract is designed to showcase advanced concepts beyond standard token interfaces.
 */

/*
Outline & Function Summary

1.  **Data Structures:**
    *   `Essence`: Stores core data for each dynamic asset (owner, properties, state flags, timestamps).
    *   `StakingInfo`: Stores staking-specific data for an Essence.

2.  **State Variables:**
    *   Mappings to store `Essence` and `StakingInfo` data by ID.
    *   Counters for total essences.
    *   Configuration parameters (costs, rates, modifiers).
    *   Addresses for owner, oracle, and potentially a rewards receiver.
    *   Pause state.

3.  **Events:**
    *   Signaling key actions: Forging, Fusion, Refinement, Staking, Unstaking, Attunement, Transfer, Burn, Parameter Changes, Fee Withdrawal.

4.  **Modifiers:**
    *   `onlyOwner`: Restricts access to the contract owner.
    *   `whenNotPaused`: Prevents execution if the contract is paused.
    *   `whenPaused`: Allows execution only if the contract is paused.
    *   `onlyEssenceOwner`: Restricts access to the owner of a specific Essence.
    *   `onlyOracle`: Restricts access to the designated oracle address for callbacks.

5.  **Core Logic Functions:**
    *   `calculateDynamicProperties`: Internal view function to determine the current effective properties of an Essence based on decay/growth and staking effects since the last interaction.

6.  **Functions (Total: 27):**

    *   **Admin & Configuration (9 functions):**
        *   `constructor()`: Initializes the contract with the deployer as owner.
        *   `pause()`: Pauses core contract functionality (only owner).
        *   `unpause()`: Unpauses core contract functionality (only owner).
        *   `renounceOwnership()`: Relinquishes ownership (only owner).
        *   `setForgePrice(uint256 _price)`: Sets the ETH price to forge a new Essence (only owner).
        *   `setDecayRatePerBlock(uint256 _rate)`: Sets the base decay/growth rate per block (only owner).
        *   `setFusionModifier(uint256 _modifier)`: Sets a modifier affecting fusion outcomes (only owner).
        *   `setOracleAddress(address _oracle)`: Sets the address of the trusted oracle contract (only owner).
        *   `withdrawProtocolFees()`: Withdraws accumulated ETH fees to the owner (only owner).

    *   **Asset Lifecycle (4 functions):**
        *   `forgeEssence(uint256 _puritySeed, uint256 _powerSeed)`: Mints a new Essence. Requires ETH payment. Initial properties based on seeds and current block data, incorporating randomness concepts.
        *   `fuseEssences(uint256 _essenceId1, uint256 _essenceId2)`: Combines two existing Essences, burning them and creating a new one with combined/modified properties. Complex logic based on input properties and fusion modifier.
        *   `refineEssence(uint256 _essenceId)`: Modifies an Essence's properties (e.g., increases Purity, decreases Power). State change based on internal logic.
        *   `burnEssence(uint256 _essenceId)`: Destroys an Essence owned by the caller.

    *   **Dynamic Interaction (5 functions):**
        *   `attuneEssenceWithOracle(uint256 _essenceId)`: Initiates an oracle request to attune an Essence's properties based on external data. Requires a trusted oracle setup.
        *   `_fulfillAttunement(uint256 _essenceId, int256 _attunementDelta)`: Callback function *only* callable by the trusted oracle address to apply attunement data.
        *   `stakeEssence(uint256 _essenceId)`: Stakes an Essence, potentially boosting its power and enabling yield accumulation (conceptually, yield claiming needs a separate mechanism/token in a real dApp).
        *   `unstakeEssence(uint256 _essenceId)`: Unstakes an Essence.
        *   `claimStakingYield(uint256 _essenceId)`: Allows claiming accumulated yield for a staked Essence (simplified: might just update internal state or log, actual yield mechanism is complex).

    *   **View & Query (8 functions):**
        *   `getEssenceDetails(uint256 _essenceId)`: Returns the current dynamic properties and state of an Essence.
        *   `getUserEssences(address _user)`: Returns a list of Essence IDs owned by a user (might be gas-intensive for many assets).
        *   `getEssenceCount()`: Returns the total number of Essences forged.
        *   `getForgePrice()`: Returns the current price to forge an Essence.
        *   `getDecayRatePerBlock()`: Returns the current base decay/growth rate.
        *   `getFusionModifier()`: Returns the current fusion modifier.
        *   `checkFusionCompatibility(uint256 _essenceId1, uint256 _essenceId2)`: Checks if two Essences meet criteria for fusion (view function).
        *   `predictFusionOutcome(uint256 _essenceId1, uint256 _essenceId2)`: Predicts the properties of the resulting Essence *if* two inputs were fused (view function).

    *   **Transfer (1 function):**
        *   `transferEssence(address _to, uint256 _essenceId)`: Transfers ownership of an Essence.

    *   **Helper/Internal (private/internal functions not exposed externally count towards complexity but not the 20+ *external* function requirement. `calculateDynamicProperties` is key internal logic.)**

*/


// Simple interface definition for the Attunement Oracle
// In a real scenario, this would match a specific oracle contract's interface
interface IAttunementOracle {
    function requestAttunementData(uint256 _essenceId, address _callbackContract) external;
    // Assumes the oracle contract knows to call _callbackContract with the result
}


contract DynamicAssetForge {
    address private _owner;
    bool private _paused;

    // --- Data Structures ---

    struct Essence {
        uint256 id;
        address owner;
        uint256 creationBlock; // Block when forged
        uint256 lastInteractionBlock; // Block when properties were last calculated/updated
        int256 basePurity; // Can be positive or negative, base value
        int256 basePower;  // Can be positive or negative, base value
        uint256 decayFactor; // Individual factor affecting decay/growth (higher = more volatile)
        string metadataURI; // Link to off-chain data
    }

     struct StakingInfo {
        uint256 stakeStartTime; // Block when staked
        bool isStaked;
        // Note: Actual yield tracking is complex and omitted for simplicity here.
        // A real system might track accumulated yield balance here or in another mapping.
    }


    // --- State Variables ---

    mapping(uint256 => Essence) private _essences;
    mapping(uint256 => StakingInfo) private _stakingInfo;
    mapping(address => uint256[]) private _ownedEssences; // Simple array to track owned IDs

    uint256 private _essenceCount; // Counter for unique Essence IDs

    uint256 private _forgePrice = 0.01 ether; // Price to forge an Essence
    uint256 private _decayRatePerBlock = 1; // Base rate of property change per block
    uint256 private _fusionModifier = 10; // Modifier affecting fusion outcome calculations

    address private _oracleAddress; // Address of the trusted oracle contract
    address private _oracleCallerAddress; // Address allowed to call _fulfillAttunement (should be _oracleAddress)

    // For fee collection
    uint256 private _accumulatedProtocolEth;


    // --- Events ---

    event EssenceForged(uint256 indexed id, address indexed owner, uint256 purity, uint256 power, uint256 creationBlock);
    event EssenceFused(uint256 indexed newId, uint256 indexed oldId1, uint256 indexed oldId2, address indexed owner, uint256 purity, uint256 power);
    event EssenceRefined(uint256 indexed id, uint256 purity, uint256 power, uint256 blockNumber);
    event EssenceBurned(uint256 indexed id, address indexed owner);
    event EssenceTransferred(uint256 indexed id, address indexed from, address indexed to);
    event EssenceStaked(uint256 indexed id, address indexed owner, uint256 stakeBlock);
    event EssenceUnstaked(uint256 indexed id, address indexed owner, uint256 unstakeBlock);
    event EssenceAttuned(uint256 indexed id, address indexed owner, int256 attunementDelta, uint256 blockNumber);

    event ForgePriceUpdated(uint256 newPrice);
    event DecayRateUpdated(uint256 newRate);
    event FusionModifierUpdated(uint256 newModifier);
    event OracleAddressUpdated(address indexed newOracle);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    event Paused(address account);
    event Unpaused(address account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyEssenceOwner(uint256 _essenceId) {
        require(_essences[_essenceId].owner != address(0), "Essence does not exist");
        require(_essences[_essenceId].owner == msg.sender, "Not essence owner");
        _;
    }

     modifier onlyOracle() {
        require(msg.sender == _oracleCallerAddress, "Not oracle caller");
        _;
    }


    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        _paused = false;
         emit OwnershipTransferred(address(0), _owner);
    }


    // --- Internal Helper Functions ---

    // Internal function to calculate the current dynamic properties considering decay/growth
    // This is a core piece of the "dynamic" concept.
    function calculateDynamicProperties(uint256 _essenceId) internal view returns (int256 currentPurity, int256 currentPower) {
        Essence storage essence = _essences[_essenceId];
        require(essence.owner != address(0), "Essence does not exist");

        uint256 blocksSinceLastInteraction = block.number - essence.lastInteractionBlock;

        // Decay/Growth logic: Simple example - properties drift towards 0 over time
        // Decay amount proportional to time, decay factor, and potentially current value (regressive decay)
        int256 purityDecay = (int256(blocksSinceLastInteraction) * int256(essence.decayFactor) * int256(_decayRatePerBlock)) / 1000; // Scaled calculation
        int256 powerDecay = (int256(blocksSinceLastInteraction) * int256(essence.decayFactor) * int256(_decayRatePerBlock)) / 1000;

        currentPurity = essence.basePurity - purityDecay;
        currentPower = essence.basePower - powerDecay;

        // Example: Staking could boost power temporarily
        StakingInfo storage stakeInfo = _stakingInfo[_essenceId];
        if (stakeInfo.isStaked) {
             // Example boost: +1 power per 10 blocks staked
            uint256 blocksStaked = block.number - stakeInfo.stakeStartTime;
            currentPower += int256(blocksStaked / 10);
        }

        // Add more complex dynamic rules here:
        // - Properties changing based on Purity/Power ratio
        // - External oracle data applied
        // - Interaction history affecting rates
    }

    // Helper to add Essence ID to user's owned list
    function _addEssenceToOwner(address _owner, uint256 _essenceId) internal {
        _ownedEssences[_owner].push(_essenceId);
    }

    // Helper to remove Essence ID from user's owned list
    function _removeEssenceFromOwner(address _owner, uint256 _essenceId) internal {
        uint256[] storage owned = _ownedEssences[_owner];
        for (uint i = 0; i < owned.length; i++) {
            if (owned[i] == _essenceId) {
                owned[i] = owned[owned.length - 1];
                owned.pop();
                break;
            }
        }
    }

    // Internal function to update an essence's base properties and reset the interaction block
    function _updateEssenceProperties(uint256 _essenceId, int256 _newBasePurity, int256 _newBasePower) internal {
         Essence storage essence = _essences[_essenceId];
         essence.basePurity = _newBasePurity;
         essence.basePower = _newBasePower;
         essence.lastInteractionBlock = block.number; // Reset interaction block to apply decay from now
    }


    // --- Admin & Configuration Functions ---

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     function setForgePrice(uint256 _price) external onlyOwner {
        _forgePrice = _price;
        emit ForgePriceUpdated(_price);
    }

    function setDecayRatePerBlock(uint256 _rate) external onlyOwner {
        _decayRatePerBlock = _rate;
        emit DecayRateUpdated(_rate);
    }

    function setFusionModifier(uint256 _modifier) external onlyOwner {
        _fusionModifier = _modifier;
        emit FusionModifierUpdated(_modifier);
    }

    function setOracleAddress(address _oracle) external onlyOwner {
        _oracleAddress = _oracle;
        // The address allowed to call _fulfillAttunement should match the oracle
        _oracleCallerAddress = _oracle;
        emit OracleAddressUpdated(_oracle);
    }

    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = _accumulatedProtocolEth;
        _accumulatedProtocolEth = 0;
        // Use call to avoid issues with recipient contract
        (bool success, ) = payable(_owner).call{value: amount}("");
        require(success, "Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_owner, amount);
    }


    // --- Asset Lifecycle Functions ---

    /**
     * @dev Forges a new Essence, requiring ETH payment.
     * Properties are determined semi-randomly based on seeds and block data.
     * @param _puritySeed A seed value influencing initial purity.
     * @param _powerSeed A seed value influencing initial power.
     */
    function forgeEssence(uint256 _puritySeed, uint256 _powerSeed) external payable whenNotPaused {
        require(msg.value >= _forgePrice, "Insufficient ETH to forge");

        _accumulatedProtocolEth += msg.value; // Collect forge price as protocol fee

        uint256 newId = _essenceCount + 1;

        // Simplified "randomness" using seeds and block data (not truly random on-chain)
        uint256 initialPurity = (_puritySeed + block.number + uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)))) % 1000; // Scale 0-999
        uint256 initialPower = (_powerSeed + block.timestamp + uint256(keccak256(abi.encodePacked(block.number, _puritySeed)))) % 1000; // Scale 0-999
        uint256 initialDecayFactor = (newId % 10) + 1; // Simple decay factor based on ID

        _essences[newId] = Essence({
            id: newId,
            owner: msg.sender,
            creationBlock: block.number,
            lastInteractionBlock: block.number,
            basePurity: int256(initialPurity),
            basePower: int256(initialPower),
            decayFactor: initialDecayFactor,
            metadataURI: "" // Can be set later
        });

        _stakingInfo[newId] = StakingInfo({
            stakeStartTime: 0,
            isStaked: false
        });

        _addEssenceToOwner(msg.sender, newId);
        _essenceCount = newId;

        emit EssenceForged(newId, msg.sender, uint256(initialPurity), uint256(initialPower), block.number);
    }

    /**
     * @dev Fuses two Essences into a new one. Burns the originals.
     * Properties of the new Essence are derived from the inputs with a modifier.
     * Requires the caller to own both essences.
     * @param _essenceId1 The ID of the first Essence.
     * @param _essenceId2 The ID of the second Essence.
     */
    function fuseEssences(uint256 _essenceId1, uint256 _essenceId2) external whenNotPaused {
        require(_essenceId1 != _essenceId2, "Cannot fuse an essence with itself");
        require(_essences[_essenceId1].owner != address(0) && _essences[_essenceId2].owner != address(0), "One or both essences do not exist");
        require(_essences[_essenceId1].owner == msg.sender && _essences[_essenceId2].owner == msg.sender, "Caller must own both essences");
        require(!_stakingInfo[_essenceId1].isStaked && !_stakingInfo[_essenceId2].isStaked, "Cannot fuse staked essences");

        // Calculate current dynamic properties before burning
        (int256 purity1, int256 power1) = calculateDynamicProperties(_essenceId1);
        (int256 purity2, int256 power2) = calculateDynamicProperties(_essenceId2);

        // Fusion Logic Example: Average base properties, add a modifier bonus
        int256 newBasePurity = (purity1 + purity2) / 2 + int256(_fusionModifier);
        int256 newBasePower = (power1 + power2) / 2 + int256(_fusionModifier);
        uint256 newDecayFactor = (_essences[_essenceId1].decayFactor + _essences[_essenceId2].decayFactor) / 2;

        // Create new Essence
        uint256 newId = _essenceCount + 1;
        _essences[newId] = Essence({
             id: newId,
            owner: msg.sender,
            creationBlock: block.number,
            lastInteractionBlock: block.number,
            basePurity: newBasePurity,
            basePower: newBasePower,
            decayFactor: newDecayFactor,
            metadataURI: "" // Can be set later
        });

         _stakingInfo[newId] = StakingInfo({
            stakeStartTime: 0,
            isStaked: false
        });

        _addEssenceToOwner(msg.sender, newId);
        _essenceCount = newId;

        // Burn original Essences
        _burnEssence(_essenceId1);
        _burnEssence(_essenceId2);

        emit EssenceFused(newId, _essenceId1, _essenceId2, msg.sender, uint256(newBasePurity), uint256(newBasePower)); // Note: Casting potentially negative ints to uint for event might show large numbers, use with care
    }


    /**
     * @dev Refines an Essence, changing its properties based on internal logic.
     * Example: increases Purity while decreasing Power.
     * Requires the caller to own the essence and it not be staked.
     * @param _essenceId The ID of the Essence to refine.
     */
    function refineEssence(uint256 _essenceId) external onlyEssenceOwner(_essenceId) whenNotPaused {
        require(!_stakingInfo[_essenceId].isStaked, "Cannot refine a staked essence");

        Essence storage essence = _essences[_essenceId];
        (int256 currentPurity, int256 currentPower) = calculateDynamicProperties(_essenceId);

        // Refinement Logic Example: Purity +10, Power -5
        int256 newBasePurity = currentPurity + 10;
        int256 newBasePower = currentPower - 5;

        _updateEssenceProperties(_essenceId, newBasePurity, newBasePower);

        emit EssenceRefined(_essenceId, uint256(newBasePurity), uint256(newBasePower), block.number); // Note: Casting potential negatives
    }

    /**
     * @dev Burns (destroys) an Essence.
     * Requires the caller to own the essence and it not be staked.
     * @param _essenceId The ID of the Essence to burn.
     */
    function burnEssence(uint256 _essenceId) external onlyEssenceOwner(_essenceId) whenNotPaused {
        require(!_stakingInfo[_essenceId].isStaked, "Cannot burn a staked essence");
        _burnEssence(_essenceId);
        emit EssenceBurned(_essenceId, msg.sender);
    }

    // Internal burn function
    function _burnEssence(uint256 _essenceId) internal {
         Essence storage essence = _essences[_essenceId];
        _removeEssenceFromOwner(essence.owner, _essenceId);

        // Clear the essence data
        delete _essences[_essenceId];
         // Also delete staking info if it exists (though check before calling _burnEssence)
        delete _stakingInfo[_essenceId];
    }


    // --- Dynamic Interaction Functions ---

    /**
     * @dev Initiates a request to the designated oracle to attune an Essence.
     * This requires a trusted oracle contract that will call back `_fulfillAttunement`.
     * @param _essenceId The ID of the Essence to attune.
     */
    function attuneEssenceWithOracle(uint256 _essenceId) external onlyEssenceOwner(_essenceId) whenNotPaused {
         require(_oracleAddress != address(0), "Oracle address not set");
        // In a real Chainlink scenario, this would be link.transferAndCall(...)
        // Here, we just signal the intent and expect the oracle to call back
        IAttunementOracle oracle = IAttunementOracle(_oracleAddress);
        oracle.requestAttunementData(_essenceId, address(this));
        // Note: Oracle calls are asynchronous. The properties won't change immediately.
        // The actual property update happens in _fulfillAttunement.
    }

    /**
     * @dev Callback function executed by the trusted oracle contract to fulfill an attunement request.
     * Applies the attunement delta to the Essence's base properties.
     * @param _essenceId The ID of the Essence being attuned.
     * @param _attunementDelta The delta value provided by the oracle.
     */
    function _fulfillAttunement(uint256 _essenceId, int256 _attunementDelta) external onlyOracle whenNotPaused {
         // Ensure essence exists before applying delta
         require(_essences[_essenceId].owner != address(0), "Essence does not exist for attunement");

        (int256 currentPurity, int256 currentPower) = calculateDynamicProperties(_essenceId);

        // Apply delta to base properties
        int256 newBasePurity = currentPurity + (_attunementDelta / 2); // Split delta between properties
        int256 newBasePower = currentPower + (_attunementDelta - (_attunementDelta / 2));

        _updateEssenceProperties(_essenceId, newBasePurity, newBasePower);

        emit EssenceAttuned(_essenceId, _essences[_essenceId].owner, _attunementDelta, block.number);
    }

    /**
     * @dev Stakes an Essence. Prevents transfer/burn/refine/fuse while staked.
     * Staking potentially influences dynamic properties or enables yield (conceptually).
     * @param _essenceId The ID of the Essence to stake.
     */
    function stakeEssence(uint256 _essenceId) external onlyEssenceOwner(_essenceId) whenNotPaused {
        StakingInfo storage stakeInfo = _stakingInfo[_essenceId];
        require(!stakeInfo.isStaked, "Essence is already staked");

        stakeInfo.isStaked = true;
        stakeInfo.stakeStartTime = block.number;

        // Update essence last interaction block to record staking start for decay calculation
        _essences[_essenceId].lastInteractionBlock = block.number;

        emit EssenceStaked(_essenceId, msg.sender, block.number);
    }

     /**
     * @dev Unstakes an Essence.
     * @param _essenceId The ID of the Essence to unstake.
     */
    function unstakeEssence(uint256 _essenceId) external onlyEssenceOwner(_essenceId) whenNotPaused {
        StakingInfo storage stakeInfo = _stakingInfo[_essenceId];
        require(stakeInfo.isStaked, "Essence is not staked");

        stakeInfo.isStaked = false;
        stakeInfo.stakeStartTime = 0; // Reset start time

        // Update essence last interaction block when unstaked
         _essences[_essenceId].lastInteractionBlock = block.number;

        emit EssenceUnstaked(_essenceId, msg.sender, block.number);
    }

    /**
     * @dev Placeholder function for claiming staking yield.
     * In a real dApp, this would calculate and distribute yield based on
     * staked duration and potentially Essence properties (e.g., Power).
     * Simplified here: just updates internal state and emits event.
     * @param _essenceId The ID of the Essence to claim yield for.
     */
    function claimStakingYield(uint256 _essenceId) external onlyEssenceOwner(_essenceId) whenNotPaused {
         StakingInfo storage stakeInfo = _stakingInfo[_essenceId];
         require(stakeInfo.isStaked, "Essence is not staked");

         // --- Complex Yield Calculation Logic Here ---
         // Example concept: Calculate yield based on block.number - stakeInfo.stakeStartTime
         // and the Essence's current dynamic Power.
         // (int256 currentPurity, int256 currentPower) = calculateDynamicProperties(_essenceId);
         // uint256 blocksSinceLastClaim = block.number - lastClaimBlock[_essenceId]; // Need to track last claim
         // uint256 yieldAmount = (uint256(currentPower) * blocksSinceLastClaim * yieldRate) / someDenominator;
         // --- End Yield Calculation ---

         // For demonstration, just update interaction block as if yield was calculated/claimed
         // A real implementation would transfer tokens or ETH here.
         _essences[_essenceId].lastInteractionBlock = block.number;

        // emit YieldClaimed(_essenceId, msg.sender, yieldAmount); // Need YieldClaimed event
        // Add an event here once yield mechanism is defined
         emit EssenceRefined(_essenceId, _essences[_essenceId].basePurity, _essences[_essenceId].basePower, block.number); // Re-using refine event as a placeholder for state change
    }


    // --- View & Query Functions ---

    /**
     * @dev Gets the current dynamic properties and state of an Essence.
     * The Purity and Power returned are calculated based on decay/growth since the last interaction.
     * @param _essenceId The ID of the Essence.
     * @return id The essence ID.
     * @return owner The current owner's address.
     * @return currentPurity The calculated dynamic Purity.
     * @return currentPower The calculated dynamic Power.
     * @return basePurity The base Purity value.
     * @return basePower The base Power value.
     * @return decayFactor The individual decay factor.
     * @return creationBlock The block the essence was created.
     * @return lastInteractionBlock The block properties were last updated.
     * @return isStaked Whether the essence is currently staked.
     * @return metadataURI The metadata URI.
     */
    function getEssenceDetails(uint256 _essenceId) public view returns (
        uint256 id,
        address owner,
        int256 currentPurity,
        int256 currentPower,
        int256 basePurity,
        int256 basePower,
        uint256 decayFactor,
        uint256 creationBlock,
        uint256 lastInteractionBlock,
        bool isStaked,
        string memory metadataURI
    ) {
        Essence storage essence = _essences[_essenceId];
        require(essence.owner != address(0), "Essence does not exist");

        (currentPurity, currentPower) = calculateDynamicProperties(_essenceId);

        return (
            essence.id,
            essence.owner,
            currentPurity,
            currentPower,
            essence.basePurity,
            essence.basePower,
            essence.decayFactor,
            essence.creationBlock,
            essence.lastInteractionBlock,
            _stakingInfo[_essenceId].isStaked,
            essence.metadataURI
        );
    }

    /**
     * @dev Gets the list of Essence IDs owned by a specific address.
     * Note: This can be gas-intensive for users with many Essences.
     * @param _user The address of the owner.
     * @return An array of Essence IDs.
     */
    function getUserEssences(address _user) external view returns (uint256[] memory) {
        return _ownedEssences[_user];
    }

    /**
     * @dev Gets the total number of Essences that have ever been forged.
     * @return The total count.
     */
    function getEssenceCount() external view returns (uint256) {
        return _essenceCount;
    }

    /**
     * @dev Gets the current price to forge an Essence in Wei.
     * @return The forge price.
     */
    function getForgePrice() external view returns (uint256) {
        return _forgePrice;
    }

    /**
     * @dev Gets the base decay/growth rate per block.
     * @return The decay rate.
     */
    function getDecayRatePerBlock() external view returns (uint256) {
        return _decayRatePerBlock;
    }

    /**
     * @dev Gets the current modifier used in fusion calculations.
     * @return The fusion modifier.
     */
    function getFusionModifier() external view returns (uint256) {
        return _fusionModifier;
    }

    /**
     * @dev Checks if two Essences are compatible for fusion based on arbitrary criteria (example).
     * This is a view function that doesn't change state.
     * @param _essenceId1 The ID of the first Essence.
     * @param _essenceId2 The ID of the second Essence.
     * @return True if compatible, false otherwise.
     */
    function checkFusionCompatibility(uint256 _essenceId1, uint256 _essenceId2) external view returns (bool) {
         if (_essenceId1 == _essenceId2 || _essences[_essenceId1].owner == address(0) || _essences[_essenceId2].owner == address(0)) {
            return false; // Cannot fuse with self or non-existent
        }
        // Example Compatibility Rule: Both must have positive Purity or both must have positive Power
        (int256 purity1, int256 power1) = calculateDynamicProperties(_essenceId1);
        (int256 purity2, int256 power2) = calculateDynamicProperties(_essenceId2);

        bool compatibility = (purity1 > 0 && purity2 > 0) || (power1 > 0 && power2 > 0);

        return compatibility;
    }

     /**
     * @dev Predicts the properties of the resulting Essence if two inputs were fused.
     * This simulates the fusion logic without executing it.
     * @param _essenceId1 The ID of the first Essence.
     * @param _essenceId2 The ID of the second Essence.
     * @return predictedPurity The predicted base Purity of the fused Essence.
     * @return predictedPower The predicted base Power of the fused Essence.
     * @return predictedDecayFactor The predicted individual decay factor.
     */
    function predictFusionOutcome(uint256 _essenceId1, uint256 _essenceId2) external view returns (int256 predictedPurity, int256 predictedPower, uint256 predictedDecayFactor) {
        require(_essenceId1 != _essenceId2, "Cannot predict fusion with self");
        require(_essences[_essenceId1].owner != address(0) && _essences[_essenceId2].owner != address(0), "One or both essences do not exist");
         require(!_stakingInfo[_essenceId1].isStaked && !_stakingInfo[_essenceId2].isStaked, "Cannot predict fusion of staked essences");
        // Note: Compatibility check is optional before prediction, depending on desired UX.
        // If not compatible, prediction might return properties representing failure or just 0s.
        // Here, we predict the theoretical outcome regardless of compatibility.

        (int256 purity1, int256 power1) = calculateDynamicProperties(_essenceId1);
        (int256 purity2, int256 power2) = calculateDynamicProperties(_essenceId2);

        // Fusion Prediction Logic (matches actual fusion logic)
        predictedPurity = (purity1 + purity2) / 2 + int256(_fusionModifier);
        predictedPower = (power1 + power2) / 2 + int256(_fusionModifier);
        predictedDecayFactor = (_essences[_essenceId1].decayFactor + _essences[_essenceId2].decayFactor) / 2;

        return (predictedPurity, predictedPower, predictedDecayFactor);
    }


    // --- Transfer Function ---

    /**
     * @dev Transfers ownership of an Essence to another address.
     * Requires the caller to be the current owner and the essence not to be staked.
     * @param _to The recipient address.
     * @param _essenceId The ID of the Essence to transfer.
     */
    function transferEssence(address _to, uint256 _essenceId) external onlyEssenceOwner(_essenceId) whenNotPaused {
        require(_to != address(0), "Transfer to zero address");
        require(_to != msg.sender, "Cannot transfer to self");
        require(!_stakingInfo[_essenceId].isStaked, "Cannot transfer a staked essence");

        address currentOwner = msg.sender;
        Essence storage essence = _essences[_essenceId];

        _removeEssenceFromOwner(currentOwner, _essenceId);
        essence.owner = _to;
        _addEssenceToOwner(_to, _essenceId);

        // Update interaction block on transfer to record the state at transfer time
        essence.lastInteractionBlock = block.number;


        emit EssenceTransferred(_essenceId, currentOwner, _to);
    }

     /**
     * @dev Allows setting/updating the metadata URI for an Essence.
     * Standard for linking off-chain asset data.
     * @param _essenceId The ID of the Essence.
     * @param _newMetadataUri The new URI string.
     */
    function setEssenceMetadata(uint256 _essenceId, string memory _newMetadataUri) external onlyEssenceOwner(_essenceId) {
         Essence storage essence = _essences[_essenceId];
         essence.metadataURI = _newMetadataUri;
         // Maybe add an event for metadata updates
    }

     /**
     * @dev Gets the metadata URI for an Essence.
     * @param _essenceId The ID of the Essence.
     * @return The metadata URI.
     */
    function getEssenceMetadata(uint256 _essenceId) external view returns (string memory) {
        require(_essences[_essenceId].owner != address(0), "Essence does not exist");
        return _essences[_essenceId].metadataURI;
    }
}
```