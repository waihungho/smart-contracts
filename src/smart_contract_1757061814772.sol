```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// ChronoSphere: An Advanced Evolutionary Soulbound NFT System
// This contract introduces a dynamic, non-transferable NFT (Soulbound Token-like)
// that represents an individual's evolving on-chain identity and reputation.
// It leverages a novel combination of attestations, AI oracle insights, and
// gamified evolutionary paths to create a rich, personalized digital identity.

// Core Concepts:
// - Soulbound Identity: NFTs are non-transferable, tied to a user's address, ensuring persistent, non-speculative identity.
// - Dynamic Traits: NFT metadata and underlying parameters evolve in real-time based on a user's on-chain actions,
//   verifiable attestations from other entities, and insights provided by AI oracles.
// - Attestation System: Authorized "Attesters" can vouch for specific qualities or actions of a ChronoSphere identity,
//   adding verifiable layers of trust and social proof to its traits.
// - AI Oracle Integration: An interface for trusted off-chain AI models to contribute data-driven insights
//   (e.g., impact scores, activity assessments, behavioral analytics) directly influencing ChronoSphere traits.
// - Evolutionary Paths: Identities can "evolve" through different tiers or stages by accumulating traits and
//   meeting specific reputation and trait-based criteria, unlocking new functionalities or visual representations.
// - Reputation Scoring: A composite, weighted score derived from various dynamic traits, designed to reflect
//   the identity's trustworthiness, activity, and impact, potentially influencing access or privileges in external dApps.
// - Time-based Decay: Some traits are configured to naturally decay over time, incentivizing continuous engagement
//   and ensuring the identity remains reflective of recent activity and relevance.

// --- Contract Outline & Function Summary ---

// 1. Core ChronoSphere NFT Management
//    - `mintChronoSphere(address _to)`: Mints a new ChronoSphere NFT for the specified address. Each address can only own one ChronoSphere.
//    - `getTokenURI(uint256 _tokenId)`: Generates and returns a dynamic, Base64-encoded metadata URI (JSON) for a ChronoSphere NFT,
//      reflecting its current traits, evolution tier, and reputation score. The metadata is generated on-chain.
//    - `getChronoSphereOwner(uint256 _tokenId)`: Returns the owner's address of a specific ChronoSphere NFT.
//    - `isChronoSphereMinted(address _owner)`: Checks if a given address already owns a ChronoSphere NFT.

// 2. Trait Management & Evolution
//    - `updateTraitValue(uint256 _tokenId, string calldata _traitName, int256 _valueChange)`: Updates a specific numerical trait
//      of a ChronoSphere by a given positive or negative change amount. Can be called by the owner or a delegated address.
//    - `getTraitValue(uint256 _tokenId, string calldata _traitName)`: Retrieves the current numerical value of a specified trait for a ChronoSphere,
//      factoring in any configured time-based decay.
//    - `evolveChronoSphere(uint256 _tokenId)`: Triggers an attempt to evolve the ChronoSphere to its next predefined tier.
//      Requires the NFT to meet specific criteria, including a minimum reputation score and certain trait values.
//    - `getCurrentEvolutionTier(uint256 _tokenId)`: Returns the current evolution tier ID of a ChronoSphere.
//    - `setEvolutionTierData(uint256 _tierId, string calldata _name, uint256 _minReputationScore, string[] calldata _requiredTraitNames, int256[] calldata _requiredTraitValues, string calldata _baseURIFragment)`: (Admin)
//      Configures or updates the criteria (reputation, specific traits) and metadata fragment for a specific evolution tier.

// 3. Attestation System
//    - `attestToIdentity(uint256 _tokenId, string calldata _traitName, int256 _value)`: Allows an authorized Attester to issue a verifiable claim
//      (attestation) about a specific trait of a ChronoSphere, directly influencing its value.
//    - `revokeAttestation(uint256 _tokenId, string calldata _traitName, uint256 _attestationId)`: Allows the original Attester to revoke a
//      previously made attestation, reversing its effect on the trait value.
//    - `getAttestationCount(uint256 _tokenId, string calldata _traitName)`: Returns the total number of attestations (active or revoked)
//      made for a specific trait of a ChronoSphere.
//    - `registerAttester(address _attesterAddress)`: (Admin) Grants the `Attester` role to a specified address, authorizing them to make attestations.
//    - `removeAttester(address _attesterAddress)`: (Admin) Revokes the `Attester` role from an address.

// 4. AI Oracle Integration
//    - `submitAIAssessment(uint256 _tokenId, string calldata _traitName, int256 _value)`: Allows an authorized `AI Oracle` to submit an
//      AI-driven assessment for a ChronoSphere's trait, directly updating its value.
//    - `registerAIOracle(address _oracleAddress)`: (Admin) Grants the `AI Oracle` role to a specified address.
//    - `removeAIOracle(address _oracleAddress)`: (Admin) Revokes the `AI Oracle` role from an address.

// 5. Reputation & Utility
//    - `calculateReputationScore(uint256 _tokenId)`: Calculates and returns a composite reputation score for a ChronoSphere based on its
//      various traits, applying predefined weightings and factoring in trait decay.
//    - `stakeForActivation(uint256 _tokenId, uint256 _amount)`: Allows a ChronoSphere owner to stake native tokens (e.g., ETH) to activate
//      certain premium features or signal commitment within the ecosystem.
//    - `withdrawStakedTokens(uint256 _tokenId, uint256 _amount)`: Allows a ChronoSphere owner to withdraw a specified amount of previously
//      staked native tokens.
//    - `delegateAction(uint256 _tokenId, address _delegatee, string calldata _actionType)`: Allows a ChronoSphere owner to delegate specific
//      management actions (e.g., updating certain traits) to another address.
//    - `getDelegatedAddress(uint256 _tokenId, string calldata _actionType)`: Retrieves the address currently delegated for a specific action type for a ChronoSphere.

// 6. Admin & Configuration
//    - `setTraitDecayRatePerDay(string calldata _traitName, uint256 _rate)`: (Admin) Sets the daily decay rate for a specific trait.
//    - `setTraitWeighting(string calldata _traitName, uint256 _weight)`: (Admin) Sets the weighting of a specific trait for reputation score calculation.
//    - `pauseContract()`: (Admin) Pauses critical contract functions, preventing most state-changing operations.
//    - `unpauseContract()`: (Admin) Unpauses the contract, allowing operations to resume.
//    - `transferOwnership(address newOwner)`: (Admin) Transfers ownership of the contract to a new address. (Inherited from Ownable)

contract ChronoSphere is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Events ---
    event ChronoSphereMinted(uint256 indexed tokenId, address indexed owner, uint256 mintTime);
    event TraitUpdated(uint256 indexed tokenId, string indexed traitName, int256 oldValue, int256 newValue, address indexed updater);
    event ChronoSphereEvolved(uint256 indexed tokenId, uint256 oldTier, uint256 newTier);
    event AttestationMade(uint256 indexed tokenId, uint256 indexed attestationId, address indexed attester, string traitName, int256 value);
    event AttestationRevoked(uint256 indexed tokenId, uint256 indexed attestationId, address indexed revoker);
    event AIAssessmentSubmitted(uint256 indexed tokenId, string indexed traitName, int256 value, address indexed oracle);
    event TokensStaked(uint256 indexed tokenId, address indexed staker, uint256 amount);
    event TokensWithdrawn(uint256 indexed tokenId, address indexed withdrawer, uint256 amount);
    event ActionDelegated(uint256 indexed tokenId, address indexed owner, address indexed delegatee, string actionType);
    event TraitDecayRateUpdated(string indexed traitName, uint256 newRate);
    event TraitWeightingUpdated(string indexed traitName, uint256 newWeight);


    // --- Structs ---
    struct ChronoSphereData {
        address owner;
        uint256 mintTime;
        uint256 lastEvolutionTime;
        uint256 currentEvolutionTier;
        mapping(bytes32 => int256) traits; // Hashed trait name to its current value
        mapping(bytes32 => uint256) traitLastUpdate; // Hashed trait name to last update timestamp for decay calculation
        mapping(bytes32 => mapping(uint256 => Attestation)) attestations; // TraitHash -> AttestationId -> Attestation
        mapping(bytes32 => Counters.Counter) attestationCounters; // TraitHash -> Counter for attestation IDs
        mapping(bytes32 => address) delegatedActions; // ActionTypeHash -> Delegated Address
    }

    struct Attestation {
        address attester;
        int256 value;
        uint256 timestamp;
        bool isActive;
    }

    struct EvolutionTier {
        string name;
        uint256 minReputationScore;
        // To iterate over required traits, we need an array of trait names (hashes).
        // Storing dynamic arrays in mappings can be tricky. For simplicity,
        // we'll store mapping of traitHash -> requiredValue. When setting,
        // _requiredTraitNames array is used to populate this.
        mapping(bytes32 => int256) requiredTraits;
        bytes32[] requiredTraitHashes; // Stores hashes of traits that need to be checked for evolution.
        string baseURIFragment; // A fragment to be included in the tokenURI for this tier's image
    }

    // --- State Variables ---
    mapping(uint256 => ChronoSphereData) private _chronoSpheres;
    mapping(address => uint256) private _ownerToTokenId; // Inverse mapping for quick lookup: owner -> tokenId
    mapping(address => bool) private _isAttester;
    mapping(address => bool) private _isAIOracle;
    mapping(uint256 => EvolutionTier) public evolutionTiers;
    uint256 public nextEvolutionTierId = 1; // Counter for next available evolution tier ID

    // Staking balances for ChronoSpheres
    mapping(uint256 => uint256) private _stakedBalances; // tokenId => staked amount

    // Configuration for trait decay (decay rate per day, in value units)
    mapping(bytes32 => uint256) private _traitDecayRatePerDay;
    // Configuration for trait weightings in reputation score calculation
    mapping(bytes32 => uint256) private _traitWeightings;

    // --- Constructor ---
    constructor(address initialOwner) ERC721("ChronoSphere", "CHRONO") Ownable(initialOwner) {}

    // --- Modifiers ---
    modifier onlyAttester() {
        require(_isAttester[msg.sender], "ChronoSphere: Caller is not an attester");
        _;
    }

    modifier onlyAIOracle() {
        require(_isAIOracle[msg.sender], "ChronoSphere: Caller is not an AI Oracle");
        _;
    }

    modifier onlyChronoSphereOwnerOrDelegate(uint256 _tokenId, string calldata _actionType) {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        address owner = ownerOf(_tokenId);
        bytes32 actionTypeHash = keccak256(abi.encodePacked(_actionType));
        require(
            msg.sender == owner || _chronoSpheres[_tokenId].delegatedActions[actionTypeHash] == msg.sender,
            "ChronoSphere: Caller is not owner or authorized delegatee for this action"
        );
        _;
    }

    // --- Internal Helpers ---
    function _hashTraitName(string calldata _traitName) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_traitName));
    }

    function _hashActionType(string calldata _actionType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_actionType));
    }

    // Calculates effective trait value, applying decay if configured
    function _getEffectiveTraitValue(uint256 _tokenId, bytes32 _traitNameHash) internal view returns (int256) {
        int256 currentValue = _chronoSpheres[_tokenId].traits[_traitNameHash];
        uint256 lastUpdate = _chronoSpheres[_tokenId].traitLastUpdate[_traitNameHash];
        uint256 decayRate = _traitDecayRatePerDay[_traitNameHash];

        if (decayRate > 0 && lastUpdate > 0 && currentValue > 0) {
            uint256 timeElapsed = block.timestamp - lastUpdate;
            uint256 daysElapsed = timeElapsed / 1 days;
            int256 decayAmount = int256(daysElapsed * decayRate);
            currentValue = currentValue - decayAmount;
            if (currentValue < 0) {
                currentValue = 0; // Traits generally don't go negative due to decay
            }
        }
        return currentValue;
    }

    // --- 1. Core ChronoSphere NFT Management ---

    function mintChronoSphere(address _to) public virtual whenNotPaused returns (uint256) {
        require(_ownerToTokenId[_to] == 0, "ChronoSphere: Address already owns a ChronoSphere");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(_to, newTokenId);
        _ownerToTokenId[_to] = newTokenId;

        ChronoSphereData storage newSphere = _chronoSpheres[newTokenId];
        newSphere.owner = _to;
        newSphere.mintTime = block.timestamp;
        newSphere.lastEvolutionTime = block.timestamp;
        newSphere.currentEvolutionTier = 0; // Starting tier (or un-evolved)

        emit ChronoSphereMinted(newTokenId, _to, block.timestamp);
        return newTokenId;
    }

    function getTokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");

        ChronoSphereData storage sphere = _chronoSpheres[_tokenId];
        uint256 reputation = calculateReputationScore(_tokenId);
        uint256 currentTierId = sphere.currentEvolutionTier;
        EvolutionTier storage currentTier = evolutionTiers[currentTierId];

        string memory name = string(abi.encodePacked("ChronoSphere #", _tokenId.toString(), " - Tier ", currentTier.name));
        string memory description = "An evolving, soulbound digital identity representing on-chain reputation and activity.";
        string memory imageUri = string(abi.encodePacked("ipfs://QmT_Your_Base_Image_CID/", currentTier.baseURIFragment, ".png")); // Placeholder base image URI

        // Start building JSON string
        string memory json = string(abi.encodePacked(
            '{"name":"', name, '",',
            '"description":"', description, '",',
            '"image":"', imageUri, '",',
            '"attributes":['
        ));

        // Add core attributes
        json = string(abi.encodePacked(
            json,
            '{"trait_type":"Mint Time","value":"', sphere.mintTime.toString(), '"},',
            '{"trait_type":"Current Tier","value":"', currentTier.name, '"},',
            '{"trait_type":"Reputation Score","value":"', reputation.toString(), '"}'
        ));

        // Dynamically add all relevant traits for display.
        // For production, we'd have a configurable list of display traits
        // or a more sophisticated way to iterate all existing traits.
        // For this example, we'll display a few key traits.
        string[] memory displayTraits = new string[](3);
        displayTraits[0] = "ActivityScore";
        displayTraits[1] = "TrustScore";
        displayTraits[2] = "ImpactScore";

        for (uint i = 0; i < displayTraits.length; i++) {
            bytes32 traitHash = _hashTraitName(displayTraits[i]);
            int256 traitValue = _getEffectiveTraitValue(_tokenId, traitHash);
            json = string(abi.encodePacked(
                json,
                ',{"trait_type":"', displayTraits[i], '","value":"', traitValue.toString(), '"}'
            ));
        }

        json = string(abi.encodePacked(json, ']}'));

        string memory baseURI = "data:application/json;base64,";
        return string(abi.encodePacked(baseURI, Base64.encode(bytes(json))));
    }

    function getChronoSphereOwner(uint256 _tokenId) public view virtual returns (address) {
        return ownerOf(_tokenId);
    }

    function isChronoSphereMinted(address _owner) public view returns (bool) {
        return _ownerToTokenId[_owner] != 0;
    }

    // --- ERC721 Overrides for Soulbound ---
    // Make tokens non-transferable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        if (from != address(0) && to != address(0)) {
            revert("ChronoSphere: NFTs are non-transferable (Soulbound)");
        }
    }

    // --- 2. Trait Management & Evolution ---

    function updateTraitValue(uint256 _tokenId, string calldata _traitName, int256 _valueChange)
        public
        virtual
        whenNotPaused
        onlyChronoSphereOwnerOrDelegate(_tokenId, "updateTrait") // Can be updated by owner or delegatee
    {
        bytes32 traitHash = _hashTraitName(_traitName);
        int256 oldValue = _getEffectiveTraitValue(_tokenId, traitHash); // Get current effective value before update
        int256 newValue = oldValue + _valueChange;

        // Update stored value and reset last update timestamp to reflect new state for decay calculation
        _chronoSpheres[_tokenId].traits[traitHash] = newValue;
        _chronoSpheres[_tokenId].traitLastUpdate[traitHash] = block.timestamp;

        emit TraitUpdated(_tokenId, _traitName, oldValue, newValue, msg.sender);
    }

    function getTraitValue(uint256 _tokenId, string calldata _traitName) public view returns (int256) {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        bytes32 traitHash = _hashTraitName(_traitName);
        return _getEffectiveTraitValue(_tokenId, traitHash);
    }

    function evolveChronoSphere(uint256 _tokenId) public virtual whenNotPaused {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        require(msg.sender == ownerOf(_tokenId), "ChronoSphere: Only ChronoSphere owner can trigger evolution");

        ChronoSphereData storage sphere = _chronoSpheres[_tokenId];
        uint256 currentTierId = sphere.currentEvolutionTier;
        uint256 potentialNextTierId = currentTierId + 1;

        // Check if a next tier is configured
        require(potentialNextTierId < nextEvolutionTierId, "ChronoSphere: No higher evolution tier configured");
        EvolutionTier storage nextTier = evolutionTiers[potentialNextTierId];
        require(bytes(nextTier.name).length > 0, "ChronoSphere: Next evolution tier is not fully configured");

        // Check reputation score requirement
        uint256 currentReputation = calculateReputationScore(_tokenId);
        require(currentReputation >= nextTier.minReputationScore, "ChronoSphere: Not enough reputation for next tier");

        // Check specific required traits
        for (uint i = 0; i < nextTier.requiredTraitHashes.length; i++) {
            bytes32 requiredTraitHash = nextTier.requiredTraitHashes[i];
            int256 requiredValue = nextTier.requiredTraits[requiredTraitHash];
            int256 currentTraitValue = _getEffectiveTraitValue(_tokenId, requiredTraitHash);
            require(currentTraitValue >= requiredValue, string(abi.encodePacked("ChronoSphere: Trait '", Strings.toHexString(uint256(requiredTraitHash)), "' value too low for next tier")));
        }

        // Perform evolution
        sphere.currentEvolutionTier = potentialNextTierId;
        sphere.lastEvolutionTime = block.timestamp;
        emit ChronoSphereEvolved(_tokenId, currentTierId, potentialNextTierId);
    }

    function setEvolutionTierData(
        uint256 _tierId,
        string calldata _name,
        uint256 _minReputationScore,
        string[] calldata _requiredTraitNames, // Names of traits required for this tier
        int256[] calldata _requiredTraitValues, // Minimum values for those traits
        string calldata _baseURIFragment
    ) public onlyOwner whenNotPaused {
        require(_tierId > 0, "ChronoSphere: Tier ID must be greater than 0");
        require(bytes(_name).length > 0, "ChronoSphere: Tier name cannot be empty");
        require(_requiredTraitNames.length == _requiredTraitValues.length, "ChronoSphere: Trait names and values count mismatch");

        EvolutionTier storage tier = evolutionTiers[_tierId];
        tier.name = _name;
        tier.minReputationScore = _minReputationScore;
        tier.baseURIFragment = _baseURIFragment;

        // Clear previous required traits before setting new ones
        for (uint i = 0; i < tier.requiredTraitHashes.length; i++) {
            delete tier.requiredTraits[tier.requiredTraitHashes[i]];
        }
        delete tier.requiredTraitHashes; // Reset array

        // Set new required traits
        for (uint i = 0; i < _requiredTraitNames.length; i++) {
            bytes32 traitHash = _hashTraitName(_requiredTraitNames[i]);
            tier.requiredTraits[traitHash] = _requiredTraitValues[i];
            tier.requiredTraitHashes.push(traitHash); // Store hash to enable iteration during evolution check
        }

        if (_tierId >= nextEvolutionTierId) {
            nextEvolutionTierId = _tierId + 1; // Update next available tier ID
        }
    }

    // --- 3. Attestation System ---

    function attestToIdentity(uint256 _tokenId, string calldata _traitName, int256 _value)
        public
        virtual
        whenNotPaused
        onlyAttester
    {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        require(_value > 0, "ChronoSphere: Attestation value must be positive");

        bytes32 traitHash = _hashTraitName(_traitName);
        Counters.Counter storage attCounter = _chronoSpheres[_tokenId].attestationCounters[traitHash];
        attCounter.increment();
        uint256 newAttestationId = attCounter.current();

        Attestation storage newAttestation = _chronoSpheres[_tokenId].attestations[traitHash][newAttestationId];
        newAttestation.attester = msg.sender;
        newAttestation.value = _value;
        newAttestation.timestamp = block.timestamp;
        newAttestation.isActive = true;

        // Immediately update trait based on attestation
        updateTraitValue(_tokenId, _traitName, _value);

        emit AttestationMade(_tokenId, newAttestationId, msg.sender, _traitName, _value);
    }

    function revokeAttestation(uint256 _tokenId, string calldata _traitName, uint256 _attestationId)
        public
        virtual
        whenNotPaused
        onlyAttester
    {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        bytes32 traitHash = _hashTraitName(_traitName);
        Attestation storage attestation = _chronoSpheres[_tokenId].attestations[traitHash][_attestationId];

        require(attestation.isActive, "ChronoSphere: Attestation is not active");
        require(attestation.attester == msg.sender, "ChronoSphere: Only original attester can revoke");

        attestation.isActive = false;

        // Revert the trait value by subtracting the attestation's value
        updateTraitValue(_tokenId, _traitName, -attestation.value);

        emit AttestationRevoked(_tokenId, _attestationId, msg.sender);
    }

    function getAttestationCount(uint256 _tokenId, string calldata _traitName) public view returns (uint256) {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        bytes32 traitHash = _hashTraitName(_traitName);
        // Returns the total number of attestations ever made for the trait (active or revoked).
        return _chronoSpheres[_tokenId].attestationCounters[traitHash].current();
    }

    function registerAttester(address _attesterAddress) public onlyOwner whenNotPaused {
        require(!_isAttester[_attesterAddress], "ChronoSphere: Address is already an attester");
        _isAttester[_attesterAddress] = true;
    }

    function removeAttester(address _attesterAddress) public onlyOwner whenNotPaused {
        require(_isAttester[_attesterAddress], "ChronoSphere: Address is not an attester");
        _isAttester[_attesterAddress] = false;
    }

    // --- 4. AI Oracle Integration ---

    function submitAIAssessment(uint256 _tokenId, string calldata _traitName, int256 _value)
        public
        virtual
        whenNotPaused
        onlyAIOracle
    {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");

        // AI assessments can directly update traits
        updateTraitValue(_tokenId, _traitName, _value);

        emit AIAssessmentSubmitted(_tokenId, _traitName, _value, msg.sender);
    }

    function registerAIOracle(address _oracleAddress) public onlyOwner whenNotPaused {
        require(!_isAIOracle[_oracleAddress], "ChronoSphere: Address is already an AI Oracle");
        _isAIOracle[_oracleAddress] = true;
    }

    function removeAIOracle(address _oracleAddress) public onlyOwner whenNotPaused {
        require(_isAIOracle[_oracleAddress], "ChronoSphere: Address is not an AI Oracle");
        _isAIOracle[_oracleAddress] = false;
    }

    // --- 5. Reputation & Utility ---

    function calculateReputationScore(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");

        uint256 totalWeightedScore = 0;
        uint256 totalWeight = 0;

        // Iterate over a predefined list of traits that contribute to reputation
        // In a real system, `_traitWeightings` could track all relevant traits and their weights dynamically.
        string[] memory reputationTraitNames = new string[](3);
        reputationTraitNames[0] = "ActivityScore";
        reputationTraitNames[1] = "TrustScore";
        reputationTraitNames[2] = "ImpactScore";

        for (uint i = 0; i < reputationTraitNames.length; i++) {
            bytes32 traitHash = _hashTraitName(reputationTraitNames[i]);
            uint256 weighting = _traitWeightings[traitHash];
            if (weighting > 0) {
                int256 traitValue = _getEffectiveTraitValue(_tokenId, traitHash);
                if (traitValue > 0) { // Only positive trait values contribute to reputation
                    totalWeightedScore += uint256(traitValue) * weighting;
                }
                totalWeight += weighting;
            }
        }

        if (totalWeight == 0) {
            return 0; // Avoid division by zero
        }
        return totalWeightedScore / totalWeight; // Normalized score
    }

    function stakeForActivation(uint256 _tokenId, uint256 _amount) public payable whenNotPaused nonReentrant {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        require(msg.sender == ownerOf(_tokenId), "ChronoSphere: Only ChronoSphere owner can stake");
        require(msg.value == _amount, "ChronoSphere: Staked amount must match sent value");
        require(_amount > 0, "ChronoSphere: Cannot stake zero amount");

        _stakedBalances[_tokenId] += _amount;
        emit TokensStaked(_tokenId, msg.sender, _amount);
    }

    function withdrawStakedTokens(uint256 _tokenId, uint256 _amount) public whenNotPaused nonReentrant {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        require(msg.sender == ownerOf(_tokenId), "ChronoSphere: Only ChronoSphere owner can withdraw");
        require(_stakedBalances[_tokenId] >= _amount, "ChronoSphere: Insufficient staked balance");
        require(_amount > 0, "ChronoSphere: Cannot withdraw zero amount");

        _stakedBalances[_tokenId] -= _amount;
        payable(msg.sender).transfer(_amount); // transfer native token
        emit TokensWithdrawn(_tokenId, msg.sender, _amount);
    }

    function delegateAction(uint256 _tokenId, address _delegatee, string calldata _actionType)
        public
        whenNotPaused
    {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        require(msg.sender == ownerOf(_tokenId), "ChronoSphere: Only ChronoSphere owner can delegate actions");
        require(_delegatee != address(0), "ChronoSphere: Delegatee cannot be zero address");
        // Restrict delegation to specific, whitelisted action types
        bytes32 actionTypeHash = _hashActionType(_actionType);
        require(
            actionTypeHash == _hashActionType("updateTrait") ||
            actionTypeHash == _hashActionType("manageAttestations"), // Example action types
            "ChronoSphere: Invalid or unauthorized action type for delegation"
        );

        _chronoSpheres[_tokenId].delegatedActions[actionTypeHash] = _delegatee;
        emit ActionDelegated(_tokenId, msg.sender, _delegatee, _actionType);
    }

    function getDelegatedAddress(uint256 _tokenId, string calldata _actionType) public view returns (address) {
        require(_exists(_tokenId), "ChronoSphere: Token does not exist");
        bytes32 actionTypeHash = _hashActionType(_actionType);
        return _chronoSpheres[_tokenId].delegatedActions[actionTypeHash];
    }

    // --- 6. Admin & Configuration ---

    function setTraitDecayRatePerDay(string calldata _traitName, uint256 _rate) public onlyOwner whenNotPaused {
        bytes32 traitHash = _hashTraitName(_traitName);
        _traitDecayRatePerDay[traitHash] = _rate;
        emit TraitDecayRateUpdated(_traitName, _rate);
    }

    function setTraitWeighting(string calldata _traitName, uint256 _weight) public onlyOwner whenNotPaused {
        bytes32 traitHash = _hashTraitName(_traitName);
        _traitWeightings[traitHash] = _weight;
        emit TraitWeightingUpdated(_traitName, _weight);
    }

    function pauseContract() public onlyOwner whenNotPaused {
        _pause();
    }

    function unpauseContract() public onlyOwner whenNotPaused {
        _unpause();
    }

    // `transferOwnership` is inherited from Ownable.

    // --- Internal Library for Base64 Encoding ---
    // A simplified, internal Base64 encoder for on-chain JSON metadata.
    // In a production environment, consider using a well-audited, external library for robustness.
    library Base64 {
        string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        function encode(bytes memory data) internal pure returns (string memory) {
            if (data.length == 0) return "";
            
            // Allocate output buffer large enough for worst case (3 bytes -> 4 chars).
            uint256 encodedLen = 4 * ((data.length + 2) / 3);
            bytes memory buffer = new bytes(encodedLen);
            
            uint256 ptr = 0;
            for (uint256 i = 0; i < data.length; i += 3) {
                uint256 b1 = data[i];
                uint256 b2 = i + 1 < data.length ? data[i + 1] : 0;
                uint256 b3 = i + 2 < data.length ? data[i + 2] : 0;

                uint256 val = (b1 << 16) | (b2 << 8) | b3; // Combine 3 bytes into a 24-bit integer

                // Extract 6-bit chunks and map to Base64 table
                buffer[ptr++] = bytes(TABLE)[(val >> 18) & 0x3F];
                buffer[ptr++] = bytes(TABLE)[(val >> 12) & 0x3F];
                buffer[ptr++] = bytes(TABLE)[(val >> 6) & 0x3F];
                buffer[ptr++] = bytes(TABLE)[val & 0x3F];
            }

            // Handle padding characters if input length is not a multiple of 3
            if (data.length % 3 == 1) {
                buffer[buffer.length - 1] = "=";
                buffer[buffer.length - 2] = "=";
            } else if (data.length % 3 == 2) {
                buffer[buffer.length - 1] = "=";
            }

            return string(buffer);
        }
    }
}

```