Okay, let's design a smart contract around a creative concept. How about a system representing "Quantum Entangled Assets"? This isn't real quantum physics, but a metaphorical interpretation where the state of two assets is linked programmatically while they are "entangled," and can be "disentangled" or "observed" to collapse their state.

This allows for interesting mechanics: properties of one asset could directly influence the other only when entangled, certain actions might only be possible in one state (entangled or disentangled), and external "observations" (e.g., oracle calls) could affect the entanglement or properties.

We'll build a contract that manages pairs of these simulated "entangled assets" and provides various functions to interact with them.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledAsset
 * @dev A metaphorical representation of assets with linked states (entanglement).
 *      This contract manages pairs of simulated assets (Asset A and Asset B)
 *      whose properties and behavior are interdependent while they are "entangled".
 *      It explores concepts of linked state changes, conditional actions based
 *      on entanglement status, simulated external 'observations' or 'flux',
 *      and probabilistic 'decay'. This is not related to actual quantum computing
 *      or physics, but uses the terminology for creative contract mechanics.
 */

/**
 * @dev Outline and Function Summary:
 *
 * 1. Data Structures:
 *    - struct AssetProperties: Defines properties like 'energyLevel', 'stability', 'colorHash'.
 *    - struct EntangledPair: Defines a pair of assets (A and B), their states, owner, timestamps, etc.
 *
 * 2. State Variables:
 *    - pairs: Mapping from unique pair ID to EntangledPair struct.
 *    - owner: Contract deployer/admin.
 *    - nextPairId: Counter for unique pair IDs.
 *    - oracleAddress: Address authorized to simulate external 'flux' or 'observation'.
 *    - entanglementCooldown: Minimum time required before a pair can be disentangled after entanglement.
 *    - globalFluxLevel: A global parameter simulating external environmental influence.
 *    - spontaneousDecayBaseProbability: Base chance for spontaneous decay.
 *
 * 3. Events:
 *    - PairCreated: Signals creation of a new pair.
 *    - PairEntangled: Signals a pair becoming entangled.
 *    - PairDisentangled: Signals a pair becoming disentangled.
 *    - PropertiesUpdated: Signals properties change for a pair.
 *    - PairTransferred: Signals ownership transfer of a pair.
 *    - ObservationTriggered: Signals an external observation attempt.
 *    - QuantumFluxApplied: Signals update of the global flux level.
 *    - SpontaneousDecayTriggered: Signals a spontaneous decay event.
 *
 * 4. Modifiers:
 *    - onlyOwner: Restricts access to the contract owner.
 *    - onlyOracle: Restricts access to the configured oracle address.
 *    - pairExists: Checks if a pair ID is valid.
 *    - whenEntangled: Restricts access only when the pair is entangled.
 *    - whenDisentangled: Restricts access only when the pair is disentangled.
 *
 * 5. Functions (>20):
 *    - constructor: Initializes the contract owner. (1)
 *    - createEntangledPair: Creates a new pair with initial properties, starts disentangled. (2)
 *    - entanglePair: Attempts to entangle a disentangled pair. (3)
 *    - disentanglePair: Attempts to disentangle an entangled pair (respects cooldown). (4)
 *    - modifyPropertyA_WhenEntangled: Modifies Asset A's property, affecting Asset B *while entangled*. (5)
 *    - modifyPropertyB_WhenEntangled: Modifies Asset B's property, affecting Asset A *while entangled*. (6)
 *    - modifyPropertyA_WhenDisentangled: Modifies Asset A's property *only* when disentangled. (7)
 *    - modifyPropertyB_WhenDisentangled: Modifies Asset B's property *only* when disentangled. (8)
 *    - applyQuantumFluxToPair: Applies the global flux level's effect to a specific pair's properties (admin/oracle). (9)
 *    - observePairState: Simulates an external observation, potentially forcing disentanglement or state change (admin/oracle). (10)
 *    - triggerSpontaneousDecay: Attempts to trigger a spontaneous decay based on probability, potentially disentangling or altering state. (11)
 *    - transferPairOwnership: Transfers the entire pair to a new address. (12)
 *    - transferAssetA_IfDisentangled: Allows transferring Asset A out of the pair *only* if disentangled. (Simulated). (13)
 *    - transferAssetB_IfDisentangled: Allows transferring Asset B out of the pair *only* if disentangled. (Simulated). (14)
 *    - getPairState: Returns the current state of a pair (entangled status, properties). (15)
 *    - getPairOwner: Returns the owner of a specific pair. (16)
 *    - getGlobalFluxLevel: Returns the current global flux level. (17)
 *    - setOracleAddress: Sets the address authorized as the oracle (owner only). (18)
 *    - setEntanglementCooldown: Sets the cooldown period for disentanglement (owner only). (19)
 *    - setSpontaneousDecayBaseProbability: Sets the base probability for spontaneous decay (owner only). (20)
 *    - increaseGlobalFlux: Increases the global flux level (oracle only). (21)
 *    - decreaseGlobalFlux: Decreases the global flux level (oracle only). (22)
 *    - calculateEntanglementStabilityScore: Calculates a score based on entanglement duration and properties. (23)
 *    - syncPropertiesIfEntangled: Re-synchronizes properties of A and B if they are entangled (internal helper). (Not counted in public functions).
 *    - calculateSpontaneousDecayChance: Calculates the decay chance based on state and global flux (internal helper). (Not counted in public functions).
 *    - getAssetAProperties: Returns properties of Asset A for a pair. (24)
 *    - getAssetBProperties: Returns properties of Asset B for a pair. (25)
 *    - listOwnedPairIds: Returns a list of pair IDs owned by an address (simple implementation). (26)
 *    - withdrawAssetAFromPair: A more concrete simulation of taking Asset A out (if disentangled). (27)
 *    - withdrawAssetBFromPair: A more concrete simulation of taking Asset B out (if disentangled). (28)
 *    - depositAssetAIntoPair: A conceptual function to add an external Asset A back (if needed and pair structure allows). (Conceptual/simulated for now). (29)
 *    - depositAssetBIntoPair: A conceptual function to add an external Asset B back. (Conceptual/simulated for now). (30)
 */

contract QuantumEntangledAsset {

    struct AssetProperties {
        uint256 energyLevel; // e.g., 0-100
        uint256 stability;   // e.g., 0-100
        uint256 colorHash;   // e.g., a simple uint representing color/type
    }

    struct EntangledPair {
        uint256 pairId;
        address owner;
        bool isEntangled;
        AssetProperties assetA;
        AssetProperties assetB;
        uint256 lastEntanglementTime;
        uint256 createdAt;
    }

    mapping(uint256 => EntangledPair) public pairs;
    mapping(address => uint256[]) private ownedPairs; // Simple list for owned pairs

    address public owner;
    uint256 private nextPairId;
    address public oracleAddress;

    uint256 public entanglementCooldown; // Minimum seconds pair must be entangled before disentanglement is possible
    uint256 public globalFluxLevel; // Represents external environmental noise/energy, affects stability/decay
    uint256 public spontaneousDecayBaseProbability; // Base probability (per million)

    event PairCreated(uint256 indexed pairId, address indexed owner);
    event PairEntangled(uint256 indexed pairId);
    event PairDisentangled(uint256 indexed pairId);
    event PropertiesUpdated(uint256 indexed pairId, AssetProperties assetA, AssetProperties assetB);
    event PairTransferred(uint256 indexed pairId, address indexed from, address indexed to);
    event ObservationTriggered(uint256 indexed pairId, bool forcedDisentanglement);
    event QuantumFluxApplied(uint256 indexed pairId, uint256 newFluxLevel);
    event GlobalFluxLevelUpdated(uint256 newFluxLevel);
    event SpontaneousDecayTriggered(uint256 indexed pairId, bool wasDisentangled);
    event AssetWithdrawn(uint256 indexed pairId, string assetType, address indexed recipient);


    modifier onlyOwner() {
        require(msg.sender == owner, "Not contract owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "Not authorized oracle");
        _;
    }

    modifier pairExists(uint256 _pairId) {
        require(pairs[_pairId].pairId != 0, "Pair does not exist");
        _;
    }

    modifier whenEntangled(uint256 _pairId) {
        require(pairs[_pairId].isEntangled, "Pair is not entangled");
        _;
    }

    modifier whenDisentangled(uint256 _pairId) {
        require(!pairs[_pairId].isEntangled, "Pair is entangled");
        _;
    }

    constructor() {
        owner = msg.sender;
        nextPairId = 1;
        entanglementCooldown = 1 days; // Default cooldown
        globalFluxLevel = 0; // Default flux
        spontaneousDecayBaseProbability = 500; // 0.05% base chance per check
    }

    /**
     * @dev Creates a new pair of entangled assets. Starts in a disentangled state.
     * @param _initialPropertiesA Initial properties for Asset A.
     * @param _initialPropertiesB Initial properties for Asset B.
     * @return The ID of the newly created pair.
     */
    function createEntangledPair(AssetProperties memory _initialPropertiesA, AssetProperties memory _initialPropertiesB) external returns (uint256) {
        uint256 newPairId = nextPairId++;
        pairs[newPairId] = EntangledPair({
            pairId: newPairId,
            owner: msg.sender,
            isEntangled: false, // Initially disentangled
            assetA: _initialPropertiesA,
            assetB: _initialPropertiesB,
            lastEntanglementTime: 0, // Not yet entangled
            createdAt: block.timestamp
        });

        ownedPairs[msg.sender].push(newPairId);

        emit PairCreated(newPairId, msg.sender);
        return newPairId;
    }

    /**
     * @dev Attempts to entangle a disentangled pair.
     * @param _pairId The ID of the pair to entangle.
     */
    function entanglePair(uint256 _pairId) external pairExists(_pairId) whenDisentangled(_pairId) {
        require(pairs[_pairId].owner == msg.sender, "Not pair owner");

        // Optional: Add cost or other conditions here
        // require(msg.value >= entanglementCost, "Insufficient funds");

        pairs[_pairId].isEntangled = true;
        pairs[_pairId].lastEntanglementTime = block.timestamp;

        // When entangling, states could become linked/averaged/synchronized
        _syncPropertiesIfEntangled(_pairId);

        emit PairEntangled(_pairId);
        // If including cost, transfer funds to owner or burn:
        // payable(owner).transfer(msg.value);
    }

    /**
     * @dev Attempts to disentangle an entangled pair. Requires meeting the cooldown.
     * @param _pairId The ID of the pair to disentangle.
     */
    function disentanglePair(uint256 _pairId) external pairExists(_pairId) whenEntangled(_pairId) {
        require(pairs[_pairId].owner == msg.sender, "Not pair owner");
        require(block.timestamp >= pairs[_pairId].lastEntanglementTime + entanglementCooldown, "Entanglement cooldown not met");

        pairs[_pairId].isEntangled = false;
        pairs[_pairId].lastEntanglementTime = 0; // Reset entanglement time

        // When disentangling, states might diverge or be 'fixed' by observation
        // Current state remains, but they can now be modified independently.

        emit PairDisentangled(_pairId);
    }

     /**
     * @dev Modifies Asset A's properties. Affects Asset B significantly IF entangled.
     * @param _pairId The ID of the pair.
     * @param _newEnergy New energy level for Asset A.
     * @param _newStability New stability for Asset A.
     * @param _newColorHash New color hash for Asset A.
     */
    function modifyPropertyA_WhenEntangled(
        uint256 _pairId,
        uint256 _newEnergy,
        uint256 _newStability,
        uint256 _newColorHash
    ) external pairExists(_pairId) whenEntangled(_pairId) {
        require(pairs[_pairId].owner == msg.sender, "Not pair owner");

        // Apply change to A
        pairs[_pairId].assetA.energyLevel = _newEnergy;
        pairs[_pairId].assetA.stability = _newStability;
        pairs[_pairId].assetA.colorHash = _newColorHash;

        // Due to entanglement, B is also affected. Let's say B partially adopts A's new state.
        pairs[_pairId].assetB.energyLevel = (pairs[_pairId].assetB.energyLevel + _newEnergy) / 2;
        pairs[_pairId].assetB.stability = (_newStability + pairs[_pairId].assetB.stability) / 2;
        pairs[_pairId].assetB.colorHash = (_newColorHash + pairs[_pairId].assetB.colorHash) / 2; // Simple average

        emit PropertiesUpdated(_pairId, pairs[_pairId].assetA, pairs[_pairId].assetB);
    }

     /**
     * @dev Modifies Asset B's properties. Affects Asset A significantly IF entangled.
     * @param _pairId The ID of the pair.
     * @param _newEnergy New energy level for Asset B.
     * @param _newStability New stability for Asset B.
     * @param _newColorHash New color hash for Asset B.
     */
     function modifyPropertyB_WhenEntangled(
        uint256 _pairId,
        uint256 _newEnergy,
        uint256 _newStability,
        uint256 _newColorHash
    ) external pairExists(_pairId) whenEntangled(_pairId) {
        require(pairs[_pairId].owner == msg.sender, "Not pair owner");

        // Apply change to B
        pairs[_pairId].assetB.energyLevel = _newEnergy;
        pairs[_pairId].assetB.stability = _newStability;
        pairs[_pairId].assetB.colorHash = _newColorHash;

        // Due to entanglement, A is also affected. A partially adopts B's new state.
        pairs[_pairId].assetA.energyLevel = (_newEnergy + pairs[_pairId].assetA.energyLevel) / 2;
        pairs[_pairId].assetA.stability = (_newStability + pairs[_pairId].assetA.stability) / 2;
        pairs[_pairId].assetA.colorHash = (_newColorHash + pairs[_pairId].assetA.colorHash) / 2; // Simple average

        emit PropertiesUpdated(_pairId, pairs[_pairId].assetA, pairs[_pairId].assetB);
    }

    /**
     * @dev Modifies Asset A's properties ONLY when disentangled. No effect on B.
     * @param _pairId The ID of the pair.
     * @param _newEnergy New energy level for Asset A.
     * @param _newStability New stability for Asset A.
     * @param _newColorHash New color hash for Asset A.
     */
    function modifyPropertyA_WhenDisentangled(
        uint256 _pairId,
        uint256 _newEnergy,
        uint256 _newStability,
        uint256 _newColorHash
    ) external pairExists(_pairId) whenDisentangled(_pairId) {
        require(pairs[_pairId].owner == msg.sender, "Not pair owner");

        pairs[_pairId].assetA.energyLevel = _newEnergy;
        pairs[_pairId].assetA.stability = _newStability;
        pairs[_pairId].assetA.colorHash = _newColorHash;

        // No effect on Asset B when disentangled
        emit PropertiesUpdated(_pairId, pairs[_pairId].assetA, pairs[_pairId].assetB);
    }

    /**
     * @dev Modifies Asset B's properties ONLY when disentangled. No effect on A.
     * @param _pairId The ID of the pair.
     * @param _newEnergy New energy level for Asset B.
     * @param _newStability New stability for Asset B.
     * @param _newColorHash New color hash for Asset B.
     */
    function modifyPropertyB_WhenDisentangled(
        uint256 _pairId,
        uint256 _newEnergy,
        uint256 _newStability,
        uint256 _newColorHash
    ) external pairExists(_pairId) whenDisentangled(_pairId) {
        require(pairs[_pairId].owner == msg.sender, "Not pair owner");

        pairs[_pairId].assetB.energyLevel = _newEnergy;
        pairs[_pairId].assetB.stability = _newStability;
        pairs[_pairId].assetB.colorHash = _newColorHash;

        // No effect on Asset A when disentangled
        emit PropertiesUpdated(_pairId, pairs[_pairId].assetA, pairs[_pairId].assetB);
    }

    /**
     * @dev Applies the global flux level's potential effect to a pair.
     *      Can be called by the oracle. The effect depends on the flux level
     *      and the pair's current state/properties.
     * @param _pairId The ID of the pair to affect.
     */
    function applyQuantumFluxToPair(uint256 _pairId) external onlyOracle pairExists(_pairId) {
        // Example effect: Higher flux reduces stability, especially if entangled
        if (pairs[_pairId].isEntangled) {
            pairs[_pairId].assetA.stability = pairs[_pairId].assetA.stability > globalFluxLevel / 10 ? pairs[_pairId].assetA.stability - globalFluxLevel / 10 : 0;
            pairs[_pairId].assetB.stability = pairs[_pairId].assetB.stability > globalFluxLevel / 10 ? pairs[_pairId].assetB.stability - globalFluxLevel / 10 : 0;
            // Entangled properties stay synced or react together
             _syncPropertiesIfEntangled(_pairId);
        } else {
             // Less effect when disentangled
            pairs[_pairId].assetA.stability = pairs[_pairId].assetA.stability > globalFluxLevel / 20 ? pairs[_pairId].assetA.stability - globalFluxLevel / 20 : 0;
            pairs[_pairId].assetB.stability = pairs[_pairId].assetB.stability > globalFluxLevel / 20 ? pairs[_pairId].assetB.stability - globalFluxLevel / 20 : 0;
        }

        emit QuantumFluxApplied(_pairId, globalFluxLevel);
        emit PropertiesUpdated(_pairId, pairs[_pairId].assetA, pairs[_pairId].assetB);
    }

    /**
     * @dev Simulates an external observation. Can force disentanglement or state collapse.
     *      Callable by the oracle.
     * @param _pairId The ID of the pair being observed.
     */
    function observePairState(uint256 _pairId) external onlyOracle pairExists(_pairId) {
        bool forcedDisentanglement = false;
        if (pairs[_pairId].isEntangled) {
            // Observation often causes state 'collapse' or disentanglement in the metaphor
            pairs[_pairId].isEntangled = false;
            pairs[_pairId].lastEntanglementTime = 0; // Reset

            // Optional: Randomize which property 'wins' upon disentanglement
            // For simplicity here, just force disentanglement.
            forcedDisentanglement = true;

            emit PairDisentangled(_pairId);
        }
        // State remains what it was immediately before observation/disentanglement

        emit ObservationTriggered(_pairId, forcedDisentanglement);
    }

     /**
     * @dev Attempts to trigger a spontaneous decay event for a pair.
     *      The chance depends on state (stability, energy) and global flux.
     *      Simulates a probabilistic event.
     *      Note: Using block data for randomness is insecure for high-value applications.
     *            This is for demonstration. A Chainlink VRF or similar should be used in production.
     * @param _pairId The ID of the pair.
     */
    function triggerSpontaneousDecay(uint256 _pairId) external pairExists(_pairId) {
        uint256 decayChance = calculateSpontaneousDecayChance(_pairId); // Probability per million

        // Simulate randomness - use block hash + pair ID + timestamp for variation
        uint256 randomness = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _pairId, msg.sender))) % 1_000_000; // Range 0 to 999,999

        bool wasDisentangled = false;
        if (randomness < decayChance) {
            // Decay happens!
            if (pairs[_pairId].isEntangled) {
                pairs[_pairId].isEntangled = false;
                pairs[_pairId].lastEntanglementTime = 0; // Reset
                wasDisentangled = true;
                 emit PairDisentangled(_pairId);
            }
             // Decay also affects properties - e.g., reduces energy/stability significantly
             pairs[_pairId].assetA.energyLevel = pairs[_pairId].assetA.energyLevel > 20 ? pairs[_pairId].assetA.energyLevel - 20 : 0;
             pairs[_pairId].assetA.stability = pairs[_pairId].assetA.stability > 30 ? pairs[_pairId].assetA.stability - 30 : 0;
             pairs[_pairId].assetB.energyLevel = pairs[_pairId].assetB.energyLevel > 20 ? pairs[_pairId].assetB.energyLevel - 20 : 0;
             pairs[_pairId].assetB.stability = pairs[_pairId].assetB.stability > 30 ? pairs[_pairId].assetB.stability - 30 : 0;

             emit SpontaneousDecayTriggered(_pairId, wasDisentangled);
             emit PropertiesUpdated(_pairId, pairs[_pairId].assetA, pairs[_pairId].assetB);
        }
        // If randomness >= decayChance, nothing happens this time.
    }

    /**
     * @dev Transfers the ownership of the entire pair to a new address.
     * @param _pairId The ID of the pair to transfer.
     * @param _to The recipient address.
     */
    function transferPairOwnership(uint256 _pairId, address _to) external pairExists(_pairId) {
        require(pairs[_pairId].owner == msg.sender, "Not pair owner");
        require(_to != address(0), "Invalid recipient address");

        address from = msg.sender;
        pairs[_pairId].owner = _to;

        // Update ownedPairs mapping (simple list update - O(n) complexity)
        uint256[] storage senderOwnedPairs = ownedPairs[from];
        for (uint i = 0; i < senderOwnedPairs.length; i++) {
            if (senderOwnedPairs[i] == _pairId) {
                // Remove from sender's list by swapping with last and popping
                senderOwnedPairs[i] = senderOwnedPairs[senderOwnedPairs.length - 1];
                senderOwnedPairs.pop();
                break; // Found and removed
            }
        }
        ownedPairs[_to].push(_pairId);

        emit PairTransferred(_pairId, from, _to);
    }

    /**
     * @dev CONCEPTUAL: Simulates transferring Asset A *out* of the pair if disentangled.
     *      In a real scenario, this might involve transferring an ERC-721 or ERC-1155 token.
     *      Here, it just logs the event and conceptually removes/flags the asset.
     *      The AssetProperties struct remains for historical state, but it's marked as 'withdrawn' conceptually.
     * @param _pairId The ID of the pair.
     * @param _recipient The address receiving Asset A.
     */
    function transferAssetA_IfDisentangled(uint256 _pairId, address _recipient) external pairExists(_pairId) whenDisentangled(_pairId) {
         require(pairs[_pairId].owner == msg.sender, "Not pair owner");
         require(_recipient != address(0), "Invalid recipient address");

         // In a real contract:
         // require(assetA_token_contract.transferFrom(address(this), _recipient, pairs[_pairId].assetA_tokenId), "Asset A transfer failed");

         // Simulation: Mark asset as conceptually withdrawn
         // We could add a boolean flag `isWithdrawnA` to the struct if needed for state tracking.
         // For this example, the event is the primary signal.

         emit AssetWithdrawn(_pairId, "Asset A", _recipient);
         // Note: This leaves the pair struct with only Asset B conceptually.
         // A more robust implementation would need to handle the pair becoming a single asset or dissolving.
    }

    /**
     * @dev CONCEPTUAL: Simulates transferring Asset B *out* of the pair if disentangled.
     * @param _pairId The ID of the pair.
     * @param _recipient The address receiving Asset B.
     */
     function transferAssetB_IfDisentangled(uint256 _pairId, address _recipient) external pairExists(_pairId) whenDisentangled(_pairId) {
         require(pairs[_pairId].owner == msg.sender, "Not pair owner");
         require(_recipient != address(0), "Invalid recipient address");

         // In a real contract:
         // require(assetB_token_contract.transferFrom(address(this), _recipient, pairs[_pairId].assetB_tokenId), "Asset B transfer failed");

         // Simulation: Mark asset as conceptually withdrawn
         emit AssetWithdrawn(_pairId, "Asset B", _recipient);
         // Note: This leaves the pair struct with only Asset A conceptually.
     }


    /**
     * @dev Returns the current state of a pair (entangled status and properties).
     * @param _pairId The ID of the pair.
     * @return isEntangled The entanglement status.
     * @return assetA Properties of Asset A.
     * @return assetB Properties of Asset B.
     */
    function getPairState(uint256 _pairId) external view pairExists(_pairId) returns (bool isEntangled, AssetProperties memory assetA, AssetProperties memory assetB) {
        EntangledPair storage pair = pairs[_pairId];
        return (pair.isEntangled, pair.assetA, pair.assetB);
    }

    /**
     * @dev Returns the owner address of a specific pair.
     * @param _pairId The ID of the pair.
     * @return The owner address.
     */
    function getPairOwner(uint256 _pairId) external view pairExists(_pairId) returns (address) {
        return pairs[_pairId].owner;
    }

    /**
     * @dev Returns the current global quantum flux level.
     * @return The global flux level.
     */
    function getGlobalFluxLevel() external view returns (uint256) {
        return globalFluxLevel;
    }

    /**
     * @dev Sets the address authorized to act as the oracle.
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        oracleAddress = _oracleAddress;
    }

    /**
     * @dev Sets the minimum cooldown period required after entanglement before disentanglement is possible.
     * @param _cooldownInSeconds The new cooldown in seconds.
     */
    function setEntanglementCooldown(uint256 _cooldownInSeconds) external onlyOwner {
        entanglementCooldown = _cooldownInSeconds;
    }

    /**
     * @dev Sets the base probability for spontaneous decay (per million).
     * @param _probabilityPerMillion The new base probability (e.g., 1000 for 0.1%). Max 1,000,000.
     */
    function setSpontaneousDecayBaseProbability(uint256 _probabilityPerMillion) external onlyOwner {
        require(_probabilityPerMillion <= 1_000_000, "Probability exceeds 100%");
        spontaneousDecayBaseProbability = _probabilityPerMillion;
    }

    /**
     * @dev Increases the global quantum flux level. Callable by the oracle.
     * @param _amount The amount to increase the flux by.
     */
    function increaseGlobalFlux(uint256 _amount) external onlyOracle {
        globalFluxLevel += _amount;
        emit GlobalFluxLevelUpdated(globalFluxLevel);
    }

    /**
     * @dev Decreases the global quantum flux level. Callable by the oracle.
     * @param _amount The amount to decrease the flux by. Flux cannot go below 0.
     */
    function decreaseGlobalFlux(uint256 _amount) external onlyOracle {
        if (globalFluxLevel > _amount) {
            globalFluxLevel -= _amount;
        } else {
            globalFluxLevel = 0;
        }
        emit GlobalFluxLevelUpdated(globalFluxLevel);
    }

    /**
     * @dev Calculates a conceptual 'Entanglement Stability Score' for a pair.
     *      Score might increase with duration of entanglement and asset stability,
     *      and decrease with high energy or flux.
     * @param _pairId The ID of the pair.
     * @return The calculated stability score.
     */
    function calculateEntanglementStabilityScore(uint256 _pairId) public view pairExists(_pairId) returns (uint256) {
        EntangledPair storage pair = pairs[_pairId];
        uint256 score = 0;

        // Base score from stability
        score += pair.assetA.stability;
        score += pair.assetB.stability;

        // Deduct for high energy (makes them less stable?)
        score = score > pair.assetA.energyLevel ? score - pair.assetA.energyLevel : 0;
        score = score > pair.assetB.energyLevel ? score - pair.assetB.energyLevel : 0;

        if (pair.isEntangled) {
            // Bonus for being entangled, increases with duration
            uint256 entanglementDuration = block.timestamp - pair.lastEntanglementTime;
            score += entanglementDuration / 100; // 1 point per 100 seconds entangled (example scale)
             // Entangled stability is more affected by global flux
             score = score > globalFluxLevel ? score - globalFluxLevel : 0;
        } else {
             // Disentangled stability is less affected by global flux
             score = score > globalFluxLevel / 2 ? score - globalFluxLevel / 2 : 0;
        }

        // Simple scoring formula, can be made more complex
        return score;
    }

     /**
      * @dev Internal helper to synchronize properties if the pair is entangled.
      *      Called after actions that might cause divergence while entangled.
      * @param _pairId The ID of the pair.
      */
     function _syncPropertiesIfEntangled(uint256 _pairId) internal {
         if (pairs[_pairId].isEntangled) {
             // Simple sync: average properties
             pairs[_pairId].assetA.energyLevel = (pairs[_pairId].assetA.energyLevel + pairs[_pairId].assetB.energyLevel) / 2;
             pairs[_pairId].assetB.energyLevel = pairs[_pairId].assetA.energyLevel; // B mirrors A
             pairs[_pairId].assetA.stability = (pairs[_pairId].assetA.stability + pairs[_pairId].assetB.stability) / 2;
             pairs[_pairId].assetB.stability = pairs[_pairId].assetA.stability; // B mirrors A
             pairs[_pairId].assetA.colorHash = (pairs[_pairId].assetA.colorHash + pairs[_pairId].assetB.colorHash) / 2;
             pairs[_pairId].assetB.colorHash = pairs[_pairId].assetA.colorHash; // B mirrors A

             // Could add more complex sync logic here
         }
     }

     /**
      * @dev Internal helper to calculate the current spontaneous decay chance (per million) for a pair.
      *      Higher energy, lower stability, and higher global flux increase the chance.
      * @param _pairId The ID of the pair.
      * @return The decay chance per million.
      */
     function calculateSpontaneousDecayChance(uint256 _pairId) internal view returns (uint256) {
         EntangledPair storage pair = pairs[_pairId];
         uint256 base = spontaneousDecayBaseProbability; // e.g., 500 (0.05%)

         // Add bonus for high energy (max 100 energy -> +100 bonus)
         base += (pair.assetA.energyLevel + pair.assetB.energyLevel) / 2;

         // Deduct for high stability (max 100 stability -> -100 deduction)
         uint256 avgStability = (pair.assetA.stability + pair.assetB.stability) / 2;
         base = base > avgStability ? base - avgStability : 0;

         // Add bonus for high global flux
         base += globalFluxLevel / 10; // 10 flux -> +1 bonus

         // Clamp result
         return base > 1_000_000 ? 1_000_000 : base;
     }

     /**
      * @dev Returns the properties of Asset A for a specific pair.
      * @param _pairId The ID of the pair.
      * @return Properties of Asset A.
      */
     function getAssetAProperties(uint256 _pairId) external view pairExists(_pairId) returns (AssetProperties memory) {
         return pairs[_pairId].assetA;
     }

     /**
      * @dev Returns the properties of Asset B for a specific pair.
      * @param _pairId The ID of the pair.
      * @return Properties of Asset B.
      */
     function getAssetBProperties(uint256 _pairId) external view pairExists(_pairId) returns (AssetProperties memory) {
         return pairs[_pairId].assetB;
     }

     /**
      * @dev Returns a simple list of pair IDs owned by a specific address.
      *      Note: For a large number of pairs, this might exceed gas limits.
      *      A more scalable solution would use a different pattern (e.g., iterable mapping or off-chain indexing).
      * @param _owner The address to query.
      * @return An array of pair IDs owned by the address.
      */
     function listOwnedPairIds(address _owner) external view returns (uint256[] memory) {
         return ownedPairs[_owner];
     }

     /**
      * @dev More concrete simulation of withdrawing Asset A. Conceptually removes it from the pair.
      *      Leaves a placeholder or alters the pair state to reflect one asset is gone.
      *      Could destroy the pair or turn it into a single-asset entity.
      *      Here, we'll update the pair state to signify Asset A is removed.
      *      A more complex version might adjust future interactions with the pair.
      * @param _pairId The ID of the pair.
      * @param _recipient The address to send the asset to (simulated).
      */
     function withdrawAssetAFromPair(uint256 _pairId, address _recipient) external pairExists(_pairId) whenDisentangled(_pairId) {
          require(pairs[_pairId].owner == msg.sender, "Not pair owner");
          require(_recipient != address(0), "Invalid recipient address");

          // Simulate asset removal - e.g., set properties to zero or add a flag
          pairs[_pairId].assetA = AssetProperties(0, 0, 0); // Conceptually gone

          emit AssetWithdrawn(_pairId, "Asset A", _recipient);

          // Future logic might check if both are withdrawn and delete the pair:
          // if (pairs[_pairId].assetA.energyLevel == 0 && pairs[_pairId].assetB.energyLevel == 0) {
          //     delete pairs[_pairId]; // Requires handling ownedPairs mapping removal
          // }
     }

     /**
      * @dev More concrete simulation of withdrawing Asset B. Conceptually removes it from the pair.
      * @param _pairId The ID of the pair.
      * @param _recipient The address to send the asset to (simulated).
      */
     function withdrawAssetBFromPair(uint256 _pairId, address _recipient) external pairExists(_pairId) whenDisentangled(_pairId) {
          require(pairs[_pairId].owner == msg.sender, "Not pair owner");
          require(_recipient != address(0), "Invalid recipient address");

          // Simulate asset removal
          pairs[_pairId].assetB = AssetProperties(0, 0, 0); // Conceptually gone

          emit AssetWithdrawn(_pairId, "Asset B", _recipient);

          // Future logic might check if both are withdrawn and delete the pair
     }

     /**
      * @dev CONCEPTUAL: Simulates depositing an external Asset A *back* into a pair
      *      where Asset A was previously withdrawn. This would require logic to match
      *      the incoming asset to the placeholder/expected state within the pair.
      *      This is complex and highly dependent on how assets are represented/tracked.
      *      For this example, it's a placeholder function.
      * @param _pairId The ID of the pair.
      * @param _externalAssetAId Identifier for the external asset being deposited.
      */
     function depositAssetAIntoPair(uint256 _pairId, uint256 _externalAssetAId) external pairExists(_pairId) whenDisentangled(_pairId) {
         require(pairs[_pairId].owner == msg.sender, "Not pair owner");
         // require(pairs[_pairId].assetA.energyLevel == 0, "Asset A is already in the pair"); // Check if placeholder is empty

         // In a real contract:
         // require(external_assetA_contract.transferFrom(msg.sender, address(this), _externalAssetAId), "External Asset A transfer failed");

         // Simulation: Update placeholder properties (e.g., based on _externalAssetAId or provided properties)
         // For simplicity, just mark it as 'present' with default/dummy properties or based on a lookup
         pairs[_pairId].assetA = AssetProperties(50, 50, _externalAssetAId); // Assigning external ID to colorHash for demo

         // Logic to handle state transition - maybe the pair becomes 'complete' again.
         // This might allow future re-entanglement if both assets are present.

         // emit AssetDeposited(_pairId, "Asset A", msg.sender); // Need a new event
     }

      /**
      * @dev CONCEPTUAL: Simulates depositing an external Asset B *back* into a pair.
      * @param _pairId The ID of the pair.
      * @param _externalAssetBId Identifier for the external asset being deposited.
      */
     function depositAssetBIntoPair(uint256 _pairId, uint256 _externalAssetBId) external pairExists(_pairId) whenDisentangled(_pairId) {
         require(pairs[_pairId].owner == msg.sender, "Not pair owner");
         // require(pairs[_pairId].assetB.energyLevel == 0, "Asset B is already in the pair"); // Check if placeholder is empty

         // In a real contract:
         // require(external_assetB_contract.transferFrom(msg.sender, address(this), _externalAssetBId), "External Asset B transfer failed");

         // Simulation: Update placeholder properties
         pairs[_pairId].assetB = AssetProperties(50, 50, _externalAssetBId); // Assigning external ID to colorHash for demo

         // Logic to handle state transition

         // emit AssetDeposited(_pairId, "Asset B", msg.sender); // Need a new event
     }

    // --- Owner/Admin Functions ---

    /**
     * @dev Transfers ownership of the contract.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is the zero address");
        owner = _newOwner;
    }
}
```