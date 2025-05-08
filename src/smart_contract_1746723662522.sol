```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementRegistry
 * @author Your Name/Alias
 * @notice A smart contract simulating abstract quantum concepts like superposition, entanglement,
 *         and observation collapse for unique digital entities (QEUs).
 *         This contract is designed to be creative and explore complex state
 *         interactions beyond typical token standards. It is NOT production-ready
 *         and serves as a conceptual demonstration.
 *
 * Outline:
 * 1. Data Structure: Defines the structure of a Quantum Entangled Unit (QEU).
 * 2. State Variables: Mappings and counters to track QEUs and ownership.
 * 3. Events: Announce key state changes and interactions.
 * 4. Modifiers: Enforce access control and state conditions.
 * 5. Core Logic (Internal): Helper functions for entanglement resolution and ID management.
 * 6. Public Functions:
 *    - Creation: Minting new QEUs, including entangled pairs.
 *    - Querying: Retrieving QEU data and status.
 *    - State Manipulation: Changing potential state, observing (collapsing), entanglement, fluctuations, etc.
 *    - Ownership: Transferring QEUs.
 *    - Advanced Interactions: Catalyzing observation, state tunneling, merging/splitting.
 *
 * Function Summary (20+ functions):
 * - Constructor: Initializes the contract owner.
 * - createQEU: Mints a new non-entangled QEU.
 * - createEntangledPair: Mints two new QEUs that are initially entangled.
 * - getQEU: Retrieves the full data structure for a given QEU ID.
 * - getOwner: Gets the current owner of a QEU.
 * - getPotentialState: Gets the potential state of a QEU.
 * - getObservedState: Gets the observed state of a QEU.
 * - isEntangled: Checks if a QEU is currently entangled.
 * - getEntanglementPartner: Gets the ID of the QEU's entanglement partner.
 * - isObserved: Checks if a QEU's superposition has collapsed (is observed).
 * - getTotalQEUs: Returns the total number of QEUs minted.
 * - getQEUCountByOwner: Returns the number of QEUs owned by an address.
 * - getQEUIdByIndexForOwner: Gets a QEU ID owned by an address at a specific index (utility for listing).
 * - getDataPayload: Retrieves the generic data payload for a QEU.
 * - getEntropy: Retrieves the current entropy value of a QEU.
 * - getCreationBlock: Gets the block number when a QEU was created.
 * - observeQEU: Collapses the QEU's superposition, setting observedState and triggering potential effects on an entangled partner.
 * - setPotentialState: Allows the owner to change the potential state before observation.
 * - transferOwnership: Transfers a QEU to a new owner.
 * - entangleQEUs: Attempts to entangle two existing, non-observed, non-entangled QEUs.
 * - disentangleQEU: Breaks the entanglement between a QEU and its partner, potentially costing entropy.
 * - applyQuantumFlucation: Introduces a simulated random change to a QEU's potentialState and/or entropy based on block data.
 * - catalyzeObservation: Allows anyone to force the observation of a high-entropy QEU, potentially earning a reward (conceptual).
 * - tunnelStateChange: Allows an owner to change the observedState *after* observation under extreme conditions (high entropy cost).
 * - mergeQEUs: Merges two QEUs into a new one, potentially combining properties and consuming the originals.
 * - splitQEU: Splits a QEU into two new ones, distributing properties and consuming the original.
 * - updateDataPayload: Allows the owner to update the generic data attached to a QEU.
 * - incrementEntropy: Directly increases a QEU's entropy (internal use or specific interactions).
 * - triggerEntropyDecay: Allows a minimal entropy decay based on time since creation (conceptual, requires call).
 * - recalibratePotential: Resets the potential state based on the current observed state or other factors.
 * - predictPotentialState: A read-only function simulating the potential outcome of an observation based on current inputs.
 * - calculateQuantumPotential: A read-only function calculating a composite score based on QEU properties.
 */

contract QuantumEntanglementRegistry {

    struct QEU {
        uint256 id;
        address owner;
        uint256 potentialState; // Represents the state before observation/collapse
        uint256 observedState;  // Represents the fixed state after observation/collapse (initially 0 or default)
        uint256 entropy;        // A measure of instability or potential for change
        uint256 entanglementPartnerId; // 0 if not entangled
        bool isObserved;        // True after observation (superposition collapsed)
        uint64 creationBlock;   // Block number at creation
        bytes dataPayload;      // Flexible data storage
    }

    // State Variables
    uint256 private _nextTokenId;
    mapping(uint256 => QEU) private _qeUs;
    mapping(address => uint256[]) private _ownerQEUs; // Simple array for ownership tracking
    mapping(uint256 => uint256) private _qeuIdToIndexInOwnerArray; // Helper for removing from _ownerQEUs
    address public owner;

    // Constants (Conceptual values)
    uint256 constant ENTROPY_DECAY_RATE = 1; // Entropy lost per block since last decay trigger (simplified)
    uint256 constant ENTROPY_FLUCTUATION_BASE = 10; // Base entropy added by fluctuation
    uint256 constant ENTROPY_ENTANGLEMENT_COST = 50; // Entropy cost to disentangle
    uint256 constant ENTROPY_TUNNEL_THRESHOLD = 1000; // Entropy needed for tunneling
    uint256 constant CATALYZE_OBSERVE_THRESHOLD = 500; // Entropy threshold for catalyzed observation
    uint256 constant CATALYZE_OBSERVE_REWARD = 0.001 ether; // Reward for catalyzed observation (conceptual)

    // Events
    event QEUCreated(uint256 indexed tokenId, address indexed owner, uint256 initialPotentialState);
    event QEUSuperpositionCollapsed(uint256 indexed tokenId, uint256 observedState);
    event QEUStateChanged(uint256 indexed tokenId, uint256 newPotentialState, uint256 newObservedState, uint256 newEntropy);
    event QEUTransfer(uint256 indexed tokenId, address indexed from, address indexed to);
    event QEUEntangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event QEUDisentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event QEUQuantumFluctuation(uint256 indexed tokenId, uint256 entropyChange);
    event QEUCatalyzedObservation(uint256 indexed tokenId, address indexed catalyzer);
    event QEUTunnelStateChange(uint256 indexed tokenId, uint256 newObservedState, uint256 entropyCost);
    event QEUMerged(uint256 indexed newTokenId, uint256 indexed oldTokenId1, uint256 indexed oldTokenId2);
    event QEUSplit(uint256 indexed oldTokenId, uint256 indexed newTokenId1, uint256 indexed newTokenId2);
    event QEUDataUpdated(uint256 indexed tokenId);
    event QEUEntropyDecayed(uint256 indexed tokenId, uint256 decayedAmount);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier onlyQEUEntityOwner(uint256 _tokenId) {
        require(_qeUs[_tokenId].owner == msg.sender, "Only QEU owner can call this function");
        _;
    }

    modifier qeuExists(uint256 _tokenId) {
        require(_qeUs[_tokenId].id != 0, "QEU does not exist");
        _;
    }

    modifier whenNotObserved(uint256 _tokenId) {
        require(!_qeUs[_tokenId].isObserved, "QEU is already observed");
        _;
    }

    modifier whenObserved(uint256 _tokenId) {
        require(_qeUs[_tokenId].isObserved, "QEU is not observed");
        _;
    }

    modifier whenEntangled(uint256 _tokenId) {
        require(_qeUs[_tokenId].entanglementPartnerId != 0, "QEU is not entangled");
        _;
    }

    modifier whenNotEntangled(uint256 _tokenId) {
        require(_qeUs[_tokenId].entanglementPartnerId == 0, "QEU is already entangled");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        _nextTokenId = 1;
    }

    // --- Internal Helpers ---

    // Manages adding a QEU to the owner's array
    function _addQEUToOwner(address _to, uint256 _tokenId) internal {
        _ownerQEUs[_to].push(_tokenId);
        _qeuIdToIndexInOwnerArray[_tokenId] = _ownerQEUs[_to].length - 1;
    }

    // Manages removing a QEU from the owner's array
    function _removeQEUFromOwner(address _from, uint256 _tokenId) internal {
        uint256 index = _qeuIdToIndexInOwnerArray[_tokenId];
        uint256 lastIndex = _ownerQEUs[_from].length - 1;
        uint256 lastTokenId = _ownerQEUs[_from][lastIndex];

        // Move the last QEU to the place of the one to delete
        _ownerQEUs[_from][index] = lastTokenId;
        _qeuIdToIndexInOwnerArray[lastTokenId] = index;

        // Remove the last QEU (which is now duplicated)
        _ownerQEUs[_from].pop();
        delete _qeuIdToIndexInOwnerArray[_tokenId];
    }

    // Resolves potential entanglement state changes after one partner is observed
    function _resolveEntanglementState(uint256 _observingQeuId, uint256 _partnerQeuId) internal {
        QEU storage observingQEU = _qeUs[_observingQeuId];
        QEU storage partnerQEU = _qeUs[_partnerQeuId];

        // If partner is NOT observed, its potential state is influenced by the observer's new state
        if (!partnerQEU.isObserved) {
             // Simple influence: partner's potential state becomes a hash mixing its original potential and the observer's observed state
            partnerQEU.potentialState = uint256(keccak256(abi.encodePacked(partnerQEU.potentialState, observingQEU.observedState, block.timestamp)));
            // Entanglement adds complexity -> increase entropy
            partnerQEU.entropy += ENTROPY_FLUCTUATION_BASE; // Entanglement flux adds entropy
            emit QEUStateChanged(_partnerQeuId, partnerQEU.potentialState, partnerQEU.observedState, partnerQEU.entropy);

        } else {
            // If partner IS observed, entanglement causes stress -> increase entropy on BOTH
            observingQEU.entropy += ENTROPY_FLUCTUATION_BASE / 2;
            partnerQEU.entropy += ENTROPY_FLUCTUATION_BASE / 2;
             emit QEUStateChanged(_observingQeuId, observingQEU.potentialState, observingQEU.observedState, observingQEU.entropy);
             emit QEUStateChanged(_partnerQeuId, partnerQEU.potentialState, partnerQEU.observedState, partnerQEU.entropy);
        }
    }

    // --- Creation Functions ---

    /**
     * @dev Mints a new Quantum Entangled Unit (QEU).
     * @param _initialPotentialState The initial potential state value.
     * @param _dataPayload Optional initial data payload.
     */
    function createQEU(uint256 _initialPotentialState, bytes memory _dataPayload) external onlyOwner {
        uint256 newTokenId = _nextTokenId++;
        address creator = msg.sender; // In this case, the contract owner

        QEU storage newQEU = _qeUs[newTokenId];
        newQEU.id = newTokenId;
        newQEU.owner = creator;
        newQEU.potentialState = _initialPotentialState;
        newQEU.observedState = 0; // Initially unobserved
        newQEU.entropy = 0;      // Starts with low entropy
        newQEU.entanglementPartnerId = 0; // Not entangled initially
        newQEU.isObserved = false;
        newQEU.creationBlock = uint64(block.number);
        newQEU.dataPayload = _dataPayload;

        _addQEUToOwner(creator, newTokenId);

        emit QEUCreated(newTokenId, creator, _initialPotentialState);
    }

     /**
     * @dev Mints two new Quantum Entangled Units (QEUs) that are initially entangled.
     * @param _initialPotentialState1 The initial potential state for the first QEU.
     * @param _initialPotentialState2 The initial potential state for the second QEU.
     * @param _dataPayload1 Optional initial data payload for the first QEU.
     * @param _dataPayload2 Optional initial data payload for the second QEU.
     * @return The IDs of the two new entangled QEUs.
     */
    function createEntangledPair(
        uint256 _initialPotentialState1,
        uint256 _initialPotentialState2,
        bytes memory _dataPayload1,
        bytes memory _dataPayload2
    ) external onlyOwner returns (uint256 tokenId1, uint256 tokenId2) {
        tokenId1 = _nextTokenId++;
        tokenId2 = _nextTokenId++;
        address creator = msg.sender;

        QEU storage qeu1 = _qeUs[tokenId1];
        qeu1.id = tokenId1;
        qeu1.owner = creator;
        qeu1.potentialState = _initialPotentialState1;
        qeu1.observedState = 0;
        qeu1.entropy = 0;
        qeu1.entanglementPartnerId = tokenId2;
        qeu1.isObserved = false;
        qeu1.creationBlock = uint64(block.number);
        qeu1.dataPayload = _dataPayload1;

        QEU storage qeu2 = _qeUs[tokenId2];
        qeu2.id = tokenId2;
        qeu2.owner = creator;
        qeu2.potentialState = _initialPotentialState2;
        qeu2.observedState = 0;
        qeu2.entropy = 0;
        qeu2.entanglementPartnerId = tokenId1; // Link back
        qeu2.isObserved = false;
        qeu2.creationBlock = uint64(block.number);
        qeu2.dataPayload = _dataPayload2;

        _addQEUToOwner(creator, tokenId1);
        _addQEUToOwner(creator, tokenId2);

        emit QEUCreated(tokenId1, creator, _initialPotentialState1);
        emit QEUCreated(tokenId2, creator, _initialPotentialState2);
        emit QEUEntangled(tokenId1, tokenId2);

        return (tokenId1, tokenId2);
    }

    // --- Querying Functions ---

    /**
     * @dev Gets the full QEU structure data.
     * @param _tokenId The ID of the QEU.
     * @return The QEU struct.
     */
    function getQEU(uint256 _tokenId) external view qeuExists(_tokenId) returns (QEU memory) {
        return _qeUs[_tokenId];
    }

    /**
     * @dev Gets the owner of a QEU.
     * @param _tokenId The ID of the QEU.
     * @return The owner's address.
     */
    function getOwner(uint256 _tokenId) external view qeuExists(_tokenId) returns (address) {
        return _qeUs[_tokenId].owner;
    }

    /**
     * @dev Gets the potential state of a QEU.
     * @param _tokenId The ID of the QEU.
     * @return The potential state value.
     */
    function getPotentialState(uint256 _tokenId) external view qeuExists(_tokenId) returns (uint256) {
        return _qeUs[_tokenId].potentialState;
    }

    /**
     * @dev Gets the observed state of a QEU.
     * @param _tokenId The ID of the QEU.
     * @return The observed state value.
     */
    function getObservedState(uint256 _tokenId) external view qeuExists(_tokenId) returns (uint256) {
        return _qeUs[_tokenId].observedState;
    }

    /**
     * @dev Checks if a QEU is currently entangled.
     * @param _tokenId The ID of the QEU.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 _tokenId) external view qeuExists(_tokenId) returns (bool) {
        return _qeUs[_tokenId].entanglementPartnerId != 0;
    }

    /**
     * @dev Gets the entanglement partner's ID.
     * @param _tokenId The ID of the QEU.
     * @return The partner's ID, or 0 if not entangled.
     */
    function getEntanglementPartner(uint256 _tokenId) external view qeuExists(_tokenId) returns (uint256) {
        return _qeUs[_tokenId].entanglementPartnerId;
    }

    /**
     * @dev Checks if a QEU's superposition has collapsed (is observed).
     * @param _tokenId The ID of the QEU.
     * @return True if observed, false otherwise.
     */
    function isObserved(uint256 _tokenId) external view qeuExists(_tokenId) returns (bool) {
        return _qeUs[_tokenId].isObserved;
    }

    /**
     * @dev Gets the total number of QEUs that have been minted.
     * @return The total count of QEUs.
     */
    function getTotalQEUs() external view returns (uint256) {
        return _nextTokenId - 1; // _nextTokenId is the ID for the *next* QEU
    }

    /**
     * @dev Gets the number of QEUs owned by a specific address.
     * @param _owner The address to check.
     * @return The count of QEUs owned by the address.
     */
    function getQEUCountByOwner(address _owner) external view returns (uint256) {
        return _ownerQEUs[_owner].length;
    }

     /**
     * @dev Gets the ID of a QEU owned by an address at a specific index in their ownership array.
     *      Useful for iterating or listing owned QEUs off-chain.
     * @param _owner The address to check.
     * @param _index The index in the owner's QEU array.
     * @return The QEU ID.
     */
    function getQEUIdByIndexForOwner(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < _ownerQEUs[_owner].length, "Index out of bounds for owner");
        return _ownerQEUs[_owner][_index];
    }


    /**
     * @dev Retrieves the generic data payload for a QEU.
     * @param _tokenId The ID of the QEU.
     * @return The bytes data payload.
     */
    function getDataPayload(uint256 _tokenId) external view qeuExists(_tokenId) returns (bytes memory) {
        return _qeUs[_tokenId].dataPayload;
    }

    /**
     * @dev Retrieves the current entropy value of a QEU.
     * @param _tokenId The ID of the QEU.
     * @return The entropy value.
     */
    function getEntropy(uint256 _tokenId) external view qeuExists(_tokenId) returns (uint256) {
        // Note: Entropy decay might not be reflected here if triggerEntropyDecay hasn't been called.
        return _qeUs[_tokenId].entropy;
    }

    /**
     * @dev Gets the creation block number of a QEU.
     * @param _tokenId The ID of the QEU.
     * @return The creation block number.
     */
    function getCreationBlock(uint256 _tokenId) external view qeuExists(_tokenId) returns (uint64) {
        return _qeUs[_tokenId].creationBlock;
    }

    // --- State Manipulation Functions ---

    /**
     * @dev Collapses the superposition of a QEU, fixing its state.
     *      If entangled, it may affect the partner's state.
     * @param _tokenId The ID of the QEU to observe.
     */
    function observeQEU(uint256 _tokenId) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) whenNotObserved(_tokenId) {
        QEU storage qeu = _qeUs[_tokenId];
        qeu.observedState = qeu.potentialState; // Collapse: observed becomes potential
        qeu.isObserved = true;

        emit QEUSuperpositionCollapsed(_tokenId, qeu.observedState);
        emit QEUStateChanged(_tokenId, qeu.potentialState, qeu.observedState, qeu.entropy);

        // If entangled, resolve the partner's state
        if (qeu.entanglementPartnerId != 0) {
            _resolveEntanglementState(_tokenId, qeu.entanglementPartnerId);
        }
    }

    /**
     * @dev Sets the potential state of a QEU before it is observed.
     * @param _tokenId The ID of the QEU.
     * @param _newPotentialState The new potential state value.
     */
    function setPotentialState(uint256 _tokenId, uint256 _newPotentialState) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) whenNotObserved(_tokenId) {
        QEU storage qeu = _qeUs[_tokenId];
        qeu.potentialState = _newPotentialState;
        emit QEUStateChanged(_tokenId, qeu.potentialState, qeu.observedState, qeu.entropy);
    }

    /**
     * @dev Transfers ownership of a QEU.
     * @param _to The address to transfer ownership to.
     * @param _tokenId The ID of the QEU to transfer.
     */
    function transferOwnership(address _to, uint256 _tokenId) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) {
        require(_to != address(0), "Cannot transfer to zero address");

        address from = _qeUs[_tokenId].owner;
        _qeUs[_tokenId].owner = _to;

        _removeQEUFromOwner(from, _tokenId);
        _addQEUToOwner(_to, _tokenId);

        emit QEUTransfer(_tokenId, from, _to);
    }

    /**
     * @dev Attempts to entangle two existing QEUs.
     *      Requires both to be unobserved and not already entangled.
     * @param _tokenId1 The ID of the first QEU.
     * @param _tokenId2 The ID of the second QEU.
     */
    function entangleQEUs(uint256 _tokenId1, uint256 _tokenId2) external qeuExists(_tokenId1) qeuExists(_tokenId2) whenNotObserved(_tokenId1) whenNotObserved(_tokenId2) whenNotEntangled(_tokenId1) whenNotEntangled(_tokenId2) {
         require(_tokenId1 != _tokenId2, "Cannot entangle a QEU with itself");
         require(_qeUs[_tokenId1].owner == msg.sender || _qeUs[_tokenId2].owner == msg.sender, "Caller must own at least one QEU");
         // Optional: require same owner for both
         // require(_qeUs[_tokenId1].owner == _qeUs[_tokenId2].owner, "Entangled QEUs must have the same owner");

        _qeUs[_tokenId1].entanglementPartnerId = _tokenId2;
        _qeUs[_tokenId2].entanglementPartnerId = _tokenId1;

        emit QEUEntangled(_tokenId1, _tokenId2);
    }

    /**
     * @dev Breaks the entanglement between a QEU and its partner.
     *      Costs entropy on the QEU being disentangled.
     * @param _tokenId The ID of the QEU to disentangle.
     */
    function disentangleQEU(uint256 _tokenId) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) whenEntangled(_tokenId) {
        uint256 partnerId = _qeUs[_tokenId].entanglementPartnerId;
        require(partnerId != 0, "QEU is not entangled"); // Redundant with modifier, but safe

        // Break links
        _qeUs[_tokenId].entanglementPartnerId = 0;
        _qeUs[partnerId].entanglementPartnerId = 0;

        // Pay entropy cost (simulated)
        if (_qeUs[_tokenId].entropy >= ENTROPY_ENTANGLEMENT_COST) {
             _qeUs[_tokenId].entropy -= ENTROPY_ENTANGLEMENT_COST;
        } else {
            _qeUs[_tokenId].entropy = 0;
        }

        emit QEUDisentangled(_tokenId, partnerId);
        emit QEUStateChanged(_tokenId, _qeUs[_tokenId].potentialState, _qeUs[_tokenId].observedState, _qeUs[_tokenId].entropy);
    }


    /**
     * @dev Applies a simulated quantum fluctuation to a QEU.
     *      Can change potentialState and increase entropy based on block data.
     * @param _tokenId The ID of the QEU.
     */
    function applyQuantumFlucation(uint256 _tokenId) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) whenNotObserved(_tokenId) {
        QEU storage qeu = _qeUs[_tokenId];

        // Use block data for pseudo-randomness
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.basefee, block.number, msg.sender, _tokenId, qeu.entropy)));

        // Apply fluctuation to potential state
        qeu.potentialState = uint256(keccak256(abi.encodePacked(qeu.potentialState, seed)));

        // Increase entropy
        uint256 entropyIncrease = ENTROPY_FLUCTUATION_BASE + (seed % 50); // Base + small random addition
        qeu.entropy += entropyIncrease;

        emit QEUQuantumFluctuation(_tokenId, entropyIncrease);
        emit QEUStateChanged(_tokenId, qeu.potentialState, qeu.observedState, qeu.entropy);
    }

    /**
     * @dev Allows any address to catalyze the observation (collapse) of a high-entropy QEU.
     *      Conceptually, this represents an external interaction forcing a state change.
     *      Caller receives a small reward (conceptual, would need ETH transfer in reality).
     * @param _tokenId The ID of the QEU to observe.
     */
    function catalyzeObservation(uint256 _tokenId) external qeuExists(_tokenId) whenNotObserved(_tokenId) {
        QEU storage qeu = _qeUs[_tokenId];
        require(qeu.entropy >= CATALYZE_OBSERVE_THRESHOLD, "QEU entropy is not high enough to be catalyzed");

        // Collapse the state
        qeu.observedState = qeu.potentialState;
        qeu.isObserved = true;

        // Reward the catalyzer (conceptual - add transfer logic for real ETH)
        // payable(msg.sender).transfer(CATALYZE_OBSERVE_REWARD);
        // log reward:
        emit QEUCatalyzedObservation(_tokenId, msg.sender);

        emit QEUSuperpositionCollapsed(_tokenId, qeu.observedState);
        emit QEUStateChanged(_tokenId, qeu.potentialState, qeu.observedState, qeu.entropy);

        // If entangled, resolve the partner's state
        if (qeu.entanglementPartnerId != 0) {
            _resolveEntanglementState(_tokenId, qeu.entanglementPartnerId);
        }
    }

    /**
     * @dev Allows the owner to 'tunnel' a state change, directly setting the observed state
     *      even after observation. This is a rare event costing significant entropy.
     * @param _tokenId The ID of the QEU.
     * @param _newObservedState The new observed state value.
     */
    function tunnelStateChange(uint256 _tokenId, uint256 _newObservedState) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) whenObserved(_tokenId) {
        QEU storage qeu = _qeUs[_tokenId];
        require(qeu.entropy >= ENTROPY_TUNNEL_THRESHOLD, "QEU entropy is not high enough for tunneling");

        uint256 entropyCost = qeu.entropy; // Tunnelling consumes all current entropy
        qeu.entropy = 0;

        qeu.observedState = _newObservedState;
        // Potential state might also be affected, maybe reset? Let's link it for simplicity.
        qeu.potentialState = _newObservedState;


        emit QEUTunnelStateChange(_tokenId, _newObservedState, entropyCost);
        emit QEUStateChanged(_tokenId, qeu.potentialState, qeu.observedState, qeu.entropy);

        // Tunneling is a fundamental state change, maybe it disentangles? Let's say it does.
        if (qeu.entanglementPartnerId != 0) {
             uint256 partnerId = qeu.entanglementPartnerId;
             _qeUs[_tokenId].entanglementPartnerId = 0;
            _qeUs[partnerId].entanglementPartnerId = 0;
            emit QEUDisentangled(_tokenId, partnerId);
             // Tunneling might cause stress on partner too
            _qeUs[partnerId].entropy += ENTROPY_FLUCTUATION_BASE * 2; // Significant stress
             emit QEUStateChanged(partnerId, _qeUs[partnerId].potentialState, _qeUs[partnerId].observedState, _qeUs[partnerId].entropy);
        }
    }

    /**
     * @dev Merges two QEUs into a new one, consuming the originals.
     *      The new QEU's properties are derived from the merged ones.
     * @param _tokenId1 The ID of the first QEU to merge.
     * @param _tokenId2 The ID of the second QEU to merge.
     * @return The ID of the newly created merged QEU.
     */
    function mergeQEUs(uint256 _tokenId1, uint256 _tokenId2) external qeuExists(_tokenId1) qeuExists(_tokenId2) returns (uint256 newTokenId) {
        require(_tokenId1 != _tokenId2, "Cannot merge a QEU with itself");
        require(_qeUs[_tokenId1].owner == msg.sender && _qeUs[_tokenId2].owner == msg.sender, "Caller must own both QEUs to merge");
        require(!_qeUs[_tokenId1].isEntangled && !_qeUs[_tokenId2].isEntangled, "Cannot merge entangled QEUs"); // Simplify: no entangled merges

        QEU storage qeu1 = _qeUs[_tokenId1];
        QEU storage qeu2 = _qeUs[_tokenId2];

        // Properties of the new QEU (simplified merging logic)
        uint256 mergedPotentialState = uint256(keccak256(abi.encodePacked(qeu1.potentialState, qeu2.potentialState)));
        uint256 mergedObservedState = uint256(keccak256(abi.encodePacked(qeu1.observedState, qeu2.observedState)));
        uint256 mergedEntropy = qeu1.entropy + qeu2.entropy;
        bytes memory mergedDataPayload = abi.encodePacked(qeu1.dataPayload, qeu2.dataPayload); // Simple concatenation

        // Create the new QEU
        newTokenId = _nextTokenId++;
        address newOwner = msg.sender;

        QEU storage newQEU = _qeUs[newTokenId];
        newQEU.id = newTokenId;
        newQEU.owner = newOwner;
        newQEU.potentialState = mergedPotentialState;
        newQEU.observedState = mergedObservedState; // New QEU's observed state is determined by merged originals
        newQEU.entropy = mergedEntropy;
        newQEU.entanglementPartnerId = 0;
        newQEU.isObserved = (qeu1.isObserved || qeu2.isObserved); // If either was observed, the merged one is
        newQEU.creationBlock = uint64(block.number);
        newQEU.dataPayload = mergedDataPayload;

        _addQEUToOwner(newOwner, newTokenId);

        // Consume the old QEUs (transfer to zero address and delete from mapping)
        address oldOwner = msg.sender; // We already checked sender owns both
        _removeQEUFromOwner(oldOwner, _tokenId1);
        _removeQEUFromOwner(oldOwner, _tokenId2);
        delete _qeUs[_tokenId1];
        delete _qeUs[_tokenId2];

        emit QEUMerged(newTokenId, _tokenId1, _tokenId2);
        emit QEUTransfer(_tokenId1, oldOwner, address(0)); // Indicate consumption
        emit QEUTransfer(_tokenId2, oldOwner, address(0));
        emit QEUCreated(newTokenId, newOwner, mergedPotentialState);
        emit QEUStateChanged(newTokenId, newQEU.potentialState, newQEU.observedState, newQEU.entropy);


        return newTokenId;
    }

    /**
     * @dev Splits a single QEU into two new ones, consuming the original.
     *      Properties of the new QEUs are derived from the original.
     * @param _tokenId The ID of the QEU to split.
     * @param _initialPotentialState1 The initial potential state for the first new QEU.
     * @param _initialPotentialState2 The initial potential state for the second new QEU.
     * @return The IDs of the two newly created QEUs.
     */
    function splitQEU(uint256 _tokenId, uint256 _initialPotentialState1, uint256 _initialPotentialState2) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) returns (uint256 newTokenId1, uint256 newTokenId2) {
         QEU storage originalQEU = _qeUs[_tokenId];
         require(!originalQEU.isEntangled, "Cannot split an entangled QEU"); // Simplify: no splitting entangled units

         address originalOwner = msg.sender;

         // Create the two new QEUs
         newTokenId1 = _nextTokenId++;
         newTokenId2 = _nextTokenId++;

        QEU storage newQEU1 = _qeUs[newTokenId1];
        newQEU1.id = newTokenId1;
        newQEU1.owner = originalOwner;
        newQEU1.potentialState = _initialPotentialState1;
        newQEU1.observedState = 0; // Split QEUs start unobserved
        newQEU1.entropy = originalQEU.entropy / 2; // Entropy is split
        newQEU1.entanglementPartnerId = 0; // Start unentangled
        newQEU1.isObserved = false;
        newQEU1.creationBlock = uint64(block.number);
        // Data payload logic (simplified): split or duplicate? Let's duplicate or keep original? Let's keep a reference or small part.
        // Using originalQEU.dataPayload could be expensive if large. Let's just allow setting new data.
        // newQEU1.dataPayload = originalQEU.dataPayload; // Might be too expensive
        newQEU1.dataPayload = bytes(''); // Start empty, can be updated

        QEU storage newQEU2 = _qeUs[newTokenId2];
        newQEU2.id = newTokenId2;
        newQEU2.owner = originalOwner;
        newQEU2.potentialState = _initialPotentialState2;
        newQEU2.observedState = 0;
        newQEU2.entropy = originalQEU.entropy - newQEU1.entropy; // Remaining entropy goes to the second one
        newQEU2.entanglementPartnerId = 0;
        newQEU2.isObserved = false;
        newQEU2.creationBlock = uint64(block.number);
        // newQEU2.dataPayload = originalQEU.dataPayload; // Might be too expensive
        newQEU2.dataPayload = bytes(''); // Start empty

        _addQEUToOwner(originalOwner, newTokenId1);
        _addQEUToOwner(originalOwner, newTokenId2);

        // Consume the original QEU
        _removeQEUFromOwner(originalOwner, _tokenId);
        delete _qeUs[_tokenId];

        emit QEUSplit(_tokenId, newTokenId1, newTokenId2);
        emit QEUTransfer(_tokenId, originalOwner, address(0)); // Indicate consumption
        emit QEUCreated(newTokenId1, originalOwner, newQEU1.potentialState);
        emit QEUCreated(newTokenId2, originalOwner, newQEU2.potentialState);
        emit QEUStateChanged(newTokenId1, newQEU1.potentialState, newQEU1.observedState, newQEU1.entropy);
        emit QEUStateChanged(newTokenId2, newQEU2.potentialState, newQEU2.observedState, newQEU2.entropy);


         return (newTokenId1, newTokenId2);
    }

    /**
     * @dev Allows the owner to update the generic data payload of a QEU.
     * @param _tokenId The ID of the QEU.
     * @param _newDataPayload The new data payload.
     */
    function updateDataPayload(uint256 _tokenId, bytes memory _newDataPayload) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) {
        _qeUs[_tokenId].dataPayload = _newDataPayload;
        emit QEUDataUpdated(_tokenId);
    }

     /**
     * @dev Directly increments the entropy of a QEU.
     *      Could be used by complex interactions or contract logic.
     * @param _tokenId The ID of the QEU.
     * @param _amount The amount to increment entropy by.
     */
    function incrementEntropy(uint256 _tokenId, uint256 _amount) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) {
        _qeUs[_tokenId].entropy += _amount;
        emit QEUStateChanged(_tokenId, _qeUs[_tokenId].potentialState, _qeUs[_tokenId].observedState, _qeUs[_tokenId].entropy);
    }

    /**
     * @dev Triggers a conceptual entropy decay based on blocks passed since creation.
     *      This is not automatic per block but must be called.
     * @param _tokenId The ID of the QEU.
     */
    function triggerEntropyDecay(uint256 _tokenId) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) {
         QEU storage qeu = _qeUs[_tokenId];
         uint256 blocksSinceCreation = block.number - qeu.creationBlock;
         // Simple decay: subtract decay rate per block, capped at current entropy
         uint256 decayAmount = blocksSinceCreation * ENTROPY_DECAY_RATE;
         if (decayAmount > qeu.entropy) {
             decayAmount = qeu.entropy;
             qeu.entropy = 0;
         } else {
             qeu.entropy -= decayAmount;
         }
         // Reset creation block or add a 'lastDecayBlock' to prevent rapid decay?
         // Let's keep creation block static and entropy is just a value that can be changed.
         // The 'decay' here is just one method to reduce it.
         emit QEUEntropyDecayed(_tokenId, decayAmount);
         emit QEUStateChanged(_tokenId, qeu.potentialState, qeu.observedState, qeu.entropy);
    }

    /**
     * @dev Recalibrates the potential state of a QEU.
     *      If observed, potentialState is set to observedState.
     *      If not observed, potentialState might be reset to a default or derived value.
     * @param _tokenId The ID of the QEU.
     */
    function recalibratePotential(uint256 _tokenId) external onlyQEUEntityOwner(_tokenId) qeuExists(_tokenId) {
        QEU storage qeu = _qeUs[_tokenId];
        if (qeu.isObserved) {
            qeu.potentialState = qeu.observedState; // Potential aligns with observed
        } else {
            // Not observed: Reset potential based on some factor, e.g., current block hash and ID
            qeu.potentialState = uint256(keccak256(abi.encodePacked(block.number, block.basefee, _tokenId)));
            // Recalibration might slightly increase entropy due to state change
            qeu.entropy += ENTROPY_FLUCTUATION_BASE / 4;
        }
        emit QEUStateChanged(_tokenId, qeu.potentialState, qeu.observedState, qeu.entropy);
    }


    // --- Advanced/Simulation Functions (Read-Only) ---

    /**
     * @dev Pure function attempting to simulate/predict the outcome of observing a QEU.
     *      Note: On-chain "randomness" for actual observation outcome might differ based on future block data.
     *      This provides a deterministic prediction based on current known state.
     * @param _tokenId The ID of the QEU.
     * @return The potential observed state if observed at this moment.
     */
    function predictPotentialState(uint256 _tokenId) external view qeuExists(_tokenId) returns (uint256) {
        QEU storage qeu = _qeUs[_tokenId];
        // In a real scenario with block-dependent randomness, this is tricky.
        // Here, the 'potentialState' IS the outcome before it's fixed.
        // If the real 'collapse' used blockhash(block.number - 1) or similar,
        // a true prediction function would need that future blockhash, which is impossible.
        // This function simply returns the current potential state as the prediction.
        // Add a conceptual twist: maybe factor in entropy?
         if (qeu.entropy > 500) { // High entropy -> prediction might be 'fuzzier' or derived differently
            return uint256(keccak256(abi.encodePacked(qeu.potentialState, qeu.entropy, block.timestamp)));
         } else {
             return qeu.potentialState;
         }
    }

    /**
     * @dev Calculates a conceptual "Quantum Potential" score for a QEU.
     *      Score is higher with higher entropy and difference between states, lower when observed.
     * @param _tokenId The ID of the QEU.
     * @return The calculated potential score.
     */
    function calculateQuantumPotential(uint256 _tokenId) external view qeuExists(_tokenId) returns (uint256) {
         QEU storage qeu = _qeUs[_tokenId];
         uint256 stateDifference = (qeu.potentialState > qeu.observedState) ? (qeu.potentialState - qeu.observedState) : (qeu.observedState - qeu.potentialState);

         uint256 score = qeu.entropy + stateDifference;

         if (qeu.isObserved) {
             // Observed QEUs have collapsed potential, reduce score significantly
             score = score / 10; // Example reduction
         }

         if (qeu.entanglementPartnerId != 0) {
              // Entanglement adds complexity/potential
             score += ENTROPY_FLUCTUATION_BASE * 2; // Example boost for entanglement
         }

         return score;
    }
}
```