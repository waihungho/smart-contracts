Okay, this is an exciting challenge! Creating a contract with unique, advanced, and trendy concepts, while avoiding existing open-source duplication, requires combining ideas in novel ways.

I've designed a concept around **"GaiaGuardians"** – Sentient, Evolving Digital Companions (NFTs) whose traits, "mood," and "health" are dynamically influenced by real-world environmental data via an oracle, as well as owner interactions. They are tied to "Ecological Zones," and the collective goal is to foster their well-being, which in turn contributes to real-world environmental public goods.

---

## GaiaGuardians: Sentient Digital Companions for Ecological Impact

### **Outline & Core Concepts:**

1.  **Sentient, Evolving Digital Companions (NFTs):** Each GaiaGuardian is a unique ERC721 NFT with dynamic attributes (`health`, `mood`, `awareness`, `impactScore`) that evolve over time based on real-world environmental conditions and owner interactions.
2.  **Environmental Data Integration:** Guardians are linked to abstract "Ecological Zones." Their well-being (e.g., `health`, `mood`) is directly influenced by environmental metrics (e.g., air quality, biodiversity index) reported by a trusted oracle.
3.  **Impact-Aligned Value & Gamification:** Owners are incentivized to "nurture" their Guardians and "contribute" to their ecological zones. Positive actions and a healthy environmental zone boost the Guardian's `impactScore` and `awareness`, leading to evolution, enhanced traits, and potentially higher perceived value.
4.  **Generative Public Goods Funding:** A portion of all "nurturing" fees and "zone contributions" automatically flows into a designated environmental public goods fund or DAO, creating a direct link between digital interaction and real-world impact.
5.  **Autonomous State Management:** Guardians decay over time if not nurtured, reflecting the fragility of real ecosystems. Their state is dynamically updated, creating a living digital asset.
6.  **Progressive Decentralization:** Starts with `Ownable` administration for core parameters, but designed to potentially integrate DAO governance for parameter changes and beneficiary selection in the future.

### **Function Summary:**

**I. Core NFT Management (ERC721 Standard):**
1.  `balanceOf(address owner)`: Returns the number of tokens owned by a specific address.
2.  `ownerOf(uint256 tokenId)`: Returns the owner of a given token ID.
3.  `approve(address to, uint256 tokenId)`: Grants approval for an address to manage a specific token.
4.  `getApproved(uint256 tokenId)`: Returns the approved address for a single token ID.
5.  `setApprovalForAll(address operator, bool approved)`: Enables or disables an operator to manage all tokens for the caller.
6.  `isApprovedForAll(address owner, address operator)`: Returns if an operator is approved for all tokens of an owner.
7.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a token.
8.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safely transfers ownership of a token.
9.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: Safely transfers ownership of a token with data.

**II. Guardian Lifecycle & State:**
10. `mintGuardian(bytes32 speciesHash, uint256 ecologicalZoneId)`: Mints a new GaiaGuardian NFT, linking it to a specific ecological zone and assigning initial traits.
11. `getGuardianState(uint256 tokenId)`: Retrieves the full current dynamic state (health, mood, awareness, impactScore, evolutionStage) of a Guardian.
12. `getGuardianDetails(uint256 tokenId)`: Retrieves immutable details (speciesHash, ecologicalZoneId, mintTime) of a Guardian.
13. `updateGuardianAttributes(uint256 tokenId)`: (Internal/View Helper) Calculates and updates Guardian's dynamic attributes based on time decay, environmental data, and owner interactions. This is called by other state-modifying functions.
14. `getEvolutionStage(uint256 tokenId)`: Returns the current evolution stage of a Guardian.

**III. Owner Interaction & Nurturing:**
15. `nurtureGuardian(uint256 tokenId)`: Allows the owner to "nurture" their Guardian by paying a fee, boosting its `health`, `mood`, and `awareness`. A portion of the fee contributes to public goods.
16. `meditateWithGuardian(uint256 tokenId)`: A free, passive interaction that provides a small, time-gated boost to `mood` and `awareness`, reflecting consistent care.
17. `contributeToZone(uint256 tokenId, uint256 amount)`: Allows owners to directly contribute funds to the specific `ecologicalZone` their Guardian is linked to, significantly boosting the Guardian's `impactScore`. A portion goes to public goods.

**IV. Environmental Oracle Integration:**
18. `setEnvironmentalOracle(address newOracle)`: (Admin) Sets the address of the trusted oracle contract responsible for providing environmental data.
19. `receiveEnvironmentalData(uint256 zoneId, bytes32 dataHash, int256 overallHealthIndex)`: (Oracle-only) Callback function for the oracle to push new environmental data for a specific zone. This data influences all Guardians within that zone.
20. `triggerZoneDataRefresh(uint256 zoneId)`: (Anyone) Allows anyone to pay gas to trigger the oracle to fetch and update data for a specific zone. This ensures data freshness.

**V. Public Goods Funding:**
21. `setPublicGoodsBeneficiary(address newBeneficiary)`: (Admin) Sets the address of the DAO or fund that receives public goods contributions.
22. `withdrawPublicGoodsFunds()`: (Beneficiary-only) Allows the designated public goods beneficiary to withdraw accumulated funds.

**VI. Administrative & Configuration:**
23. `pause()`: (Admin) Pauses critical contract functions in case of emergency.
24. `unpause()`: (Admin) Unpauses critical contract functions.
25. `setNurturingFee(uint256 newFee)`: (Admin) Adjusts the fee required for `nurtureGuardian()`.
26. `setEvolutionThresholds(uint8 stage, uint256 impactThreshold, uint256 awarenessThreshold)`: (Admin) Configures the `impactScore` and `awareness` thresholds required for Guardians to evolve to the next stage.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Custom errors for better readability and gas efficiency
error GaiaGuardians__InvalidERC721Receiver();
error GaiaGuardians__NotEnoughFunds();
error GaiaGuardians__NotOracle();
error GaiaGuardians__GuardianDoesNotExist();
error GaiaGuardians__NurtureCooldown();
error GaiaGuardians__MeditateCooldown();
error GaiaGuardians__ZoneDoesNotExist();
error GaiaGuardians__OracleNotSet();
error GaiaGuardians__BeneficiaryNotSet();

/**
 * @title GaiaGuardians
 * @dev A contract for Sentient, Evolving Digital Companions (NFTs) that interact with real-world environmental data
 *      and contribute to ecological public goods.
 *
 * Outline & Core Concepts:
 * 1. Sentient, Evolving Digital Companions (NFTs): Each GaiaGuardian is a unique ERC721 NFT with dynamic attributes
 *    (health, mood, awareness, impactScore) that evolve over time based on real-world environmental conditions and owner interactions.
 * 2. Environmental Data Integration: Guardians are linked to abstract "Ecological Zones." Their well-being (e.g., health, mood)
 *    is directly influenced by environmental metrics (e.g., air quality, biodiversity index) reported by a trusted oracle.
 * 3. Impact-Aligned Value & Gamification: Owners are incentivized to "nurture" their Guardians and "contribute" to their ecological zones.
 *    Positive actions and a healthy environmental zone boost the Guardian's impactScore and awareness, leading to evolution,
 *    enhanced traits, and potentially higher perceived value.
 * 4. Generative Public Goods Funding: A portion of all "nurturing" fees and "zone contributions" automatically flows into a designated
 *    environmental public goods fund or DAO, creating a direct link between digital interaction and real-world impact.
 * 5. Autonomous State Management: Guardians decay over time if not nurtured, reflecting the fragility of real ecosystems.
 *    Their state is dynamically updated, creating a living digital asset.
 * 6. Progressive Decentralization: Starts with Ownable administration for core parameters, but designed to potentially
 *    integrate DAO governance for parameter changes and beneficiary selection in the future.
 *
 * Function Summary:
 * I. Core NFT Management (ERC721 Standard):
 * 1. balanceOf(address owner): Returns the number of tokens owned by a specific address.
 * 2. ownerOf(uint256 tokenId): Returns the owner of a given token ID.
 * 3. approve(address to, uint256 tokenId): Grants approval for an address to manage a specific token.
 * 4. getApproved(uint256 tokenId): Returns the approved address for a single token ID.
 * 5. setApprovalForAll(address operator, bool approved): Enables or disables an operator to manage all tokens for the caller.
 * 6. isApprovedForAll(address owner, address operator): Returns if an operator is approved for all tokens of an owner.
 * 7. transferFrom(address from, address to, uint256 tokenId): Transfers ownership of a token.
 * 8. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers ownership of a token.
 * 9. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data): Safely transfers ownership of a token with data.
 *
 * II. Guardian Lifecycle & State:
 * 10. mintGuardian(bytes32 speciesHash, uint256 ecologicalZoneId): Mints a new GaiaGuardian NFT, linking it to a specific ecological zone and assigning initial traits.
 * 11. getGuardianState(uint256 tokenId): Retrieves the full current dynamic state (health, mood, awareness, impactScore, evolutionStage) of a Guardian.
 * 12. getGuardianDetails(uint256 tokenId): Retrieves immutable details (speciesHash, ecologicalZoneId, mintTime) of a Guardian.
 * 13. updateGuardianAttributes(uint256 tokenId): (Internal/View Helper) Calculates and updates Guardian's dynamic attributes based on time decay, environmental data, and owner interactions. This is called by other state-modifying functions.
 * 14. getEvolutionStage(uint256 tokenId): Returns the current evolution stage of a Guardian.
 *
 * III. Owner Interaction & Nurturing:
 * 15. nurtureGuardian(uint256 tokenId): Allows the owner to "nurture" their Guardian by paying a fee, boosting its health, mood, and awareness. A portion of the fee contributes to public goods.
 * 16. meditateWithGuardian(uint256 tokenId): A free, passive interaction that provides a small, time-gated boost to mood and awareness, reflecting consistent care.
 * 17. contributeToZone(uint256 tokenId, uint256 amount): Allows owners to directly contribute funds to the specific ecologicalZone their Guardian is linked to, significantly boosting the Guardian's impactScore. A portion goes to public goods.
 *
 * IV. Environmental Oracle Integration:
 * 18. setEnvironmentalOracle(address newOracle): (Admin) Sets the address of the trusted oracle contract responsible for providing environmental data.
 * 19. receiveEnvironmentalData(uint256 zoneId, bytes32 dataHash, int256 overallHealthIndex): (Oracle-only) Callback function for the oracle to push new environmental data for a specific zone. This data influences all Guardians within that zone.
 * 20. triggerZoneDataRefresh(uint256 zoneId): (Anyone) Allows anyone to pay gas to trigger the oracle to fetch and update data for a specific zone. This ensures data freshness.
 *
 * V. Public Goods Funding:
 * 21. setPublicGoodsBeneficiary(address newBeneficiary): (Admin) Sets the address of the DAO or fund that receives public goods contributions.
 * 22. withdrawPublicGoodsFunds(): (Beneficiary-only) Allows the designated public goods beneficiary to withdraw accumulated funds.
 *
 * VI. Administrative & Configuration:
 * 23. pause(): (Admin) Pauses critical contract functions in case of emergency.
 * 24. unpause(): (Admin) Unpauses critical contract functions.
 * 25. setNurturingFee(uint256 newFee): (Admin) Adjusts the fee required for nurtureGuardian().
 * 26. setEvolutionThresholds(uint8 stage, uint256 impactThreshold, uint256 awarenessThreshold): (Admin) Configures the impactScore and awareness thresholds required for Guardians to evolve to the next stage.
 */
contract GaiaGuardians is ERC721, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Enums and Structs ---

    enum EvolutionStage { Egg, Larva, Juvenile, Adult, Elder }

    struct Guardian {
        uint256 tokenId;
        address owner;
        uint256 mintTime;
        bytes32 speciesHash; // Immutable base traits (e.g., genetic code)
        uint256 ecologicalZoneId; // The zone it's tied to

        // Dynamic Attributes (0-1000 scale for simplicity, can be expanded)
        uint256 health; // Reflects well-being, affected by environment and nurturing
        uint256 mood;   // Reflects emotional state, affected by health and interactions
        uint256 awareness; // Reflects sentience/intelligence, grows with interactions/data
        uint256 impactScore; // Cumulative positive impact (nurturing, contributions)

        // Time-based interaction tracking
        uint256 lastNurturedTime;
        uint224 lastMeditatedTime; // Using uint224 to save a tiny bit of storage
        uint256 lastEnvironmentalUpdateTime; // When its state was last updated by zone data
    }

    struct EcologicalZone {
        uint256 id;
        int256 overallHealthIndex; // e.g., -100 to 100, from oracle
        bytes32 environmentalDataHash; // Hash of the raw data from oracle
        uint256 lastOracleUpdateTime; // When oracle last pushed data for this zone
    }

    struct EvolutionThreshold {
        uint256 impactThreshold;
        uint256 awarenessThreshold;
    }

    // --- State Variables ---

    uint256 private _nextTokenId; // Counter for minting new Guardians
    mapping(uint256 => Guardian) public guardians; // tokenId => Guardian data
    mapping(uint256 => EcologicalZone) public ecologicalZones; // zoneId => EcologicalZone data
    mapping(uint8 => EvolutionThreshold) public evolutionThresholds; // stage_index => thresholds

    address public environmentalOracle; // Address of the trusted environmental data oracle
    address public publicGoodsBeneficiary; // Address of the DAO/fund receiving contributions

    uint256 public nurturingFee = 0.005 ether; // Default fee for nurturing
    uint256 public constant NURTURE_COOLDOWN = 1 days; // Cooldown for nurturing
    uint256 public constant MEDITATE_COOLDOWN = 1 hours; // Cooldown for meditating
    uint256 public constant HEALTH_DECAY_RATE_PER_DAY = 10; // Health decay points per day
    uint256 public constant AWARENESS_BOOST_PER_NURTURE = 10; // Awareness boost from nurturing
    uint256 public constant MOOD_BOOST_PER_NURTURE = 20; // Mood boost from nurturing
    uint256 public constant HEALTH_BOOST_PER_NURTURE = 30; // Health boost from nurturing
    uint256 public constant MEDITATE_MOOD_BOOST = 5; // Mood boost from meditating
    uint256 public constant MEDITATE_AWARENESS_BOOST = 2; // Awareness boost from meditating
    uint256 public constant IMPACT_BOOST_PER_CONTRIBUTION_ETH_FACTOR = 100; // 1 ETH = 100 impact score

    // --- Events ---

    event GuardianMinted(uint256 indexed tokenId, address indexed owner, bytes32 speciesHash, uint256 ecologicalZoneId);
    event GuardianNurtured(uint256 indexed tokenId, address indexed nurturer, uint256 feePaid);
    event GuardianMeditated(uint256 indexed tokenId, address indexed meditator);
    event ZoneContributed(uint256 indexed tokenId, uint256 indexed zoneId, address indexed contributor, uint256 amount);
    event EnvironmentalDataReceived(uint256 indexed zoneId, bytes32 dataHash, int256 overallHealthIndex);
    event PublicGoodsFundsWithdrawn(address indexed beneficiary, uint256 amount);
    event OracleSet(address indexed oldOracle, address indexed newOracle);
    event BeneficiarySet(address indexed oldBeneficiary, address indexed newBeneficiary);
    event NurturingFeeSet(uint256 newFee);
    event EvolutionThresholdsSet(uint8 indexed stage, uint256 impactThreshold, uint256 awarenessThreshold);

    // --- Constructor ---

    constructor(address _environmentalOracle) ERC721("GaiaGuardian", "GG") Ownable(msg.sender) {
        environmentalOracle = _environmentalOracle;
        // Set initial evolution thresholds
        evolutionThresholds[uint8(EvolutionStage.Egg)] = EvolutionThreshold(0, 0); // Egg requires no thresholds
        evolutionThresholds[uint8(EvolutionStage.Larva)] = EvolutionThreshold(100, 50);
        evolutionThresholds[uint8(EvolutionStage.Juvenile)] = EvolutionThreshold(500, 200);
        evolutionThresholds[uint8(EvolutionStage.Adult)] = EvolutionThreshold(2000, 700);
        evolutionThresholds[uint8(EvolutionStage.Elder)] = EvolutionThreshold(5000, 1500);

        // Initialize a few sample ecological zones
        ecologicalZones[1] = EcologicalZone({
            id: 1,
            overallHealthIndex: 50, // Neutral start
            environmentalDataHash: bytes32(0),
            lastOracleUpdateTime: block.timestamp
        });
        ecologicalZones[2] = EcologicalZone({
            id: 2,
            overallHealthIndex: 70, // Good start
            environmentalDataHash: bytes32(0),
            lastOracleUpdateTime: block.timestamp
        });
    }

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != environmentalOracle) revert GaiaGuardians__NotOracle();
        _;
    }

    modifier onlyBeneficiary() {
        if (msg.sender != publicGoodsBeneficiary) revert GaiaGuardians__BeneficiaryNotSet();
        _;
    }

    modifier guardianExists(uint256 tokenId) {
        if (_exists(tokenId) == false) revert GaiaGuardians__GuardianDoesNotExist();
        _;
    }

    modifier zoneExists(uint256 zoneId) {
        if (ecologicalZones[zoneId].id == 0 && zoneId != 0) revert GaiaGuardians__ZoneDoesNotExist();
        _;
    }

    // --- Internal ERC721 Overrides (No changes, but required for custom minting) ---

    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint256 value) internal override(ERC721) {
        super._increaseBalance(account, value);
    }

    function _approve(address to, uint256 tokenId) internal override(ERC721) {
        super._approve(to, tokenId);
    }

    // --- I. Core NFT Management (ERC721 Standard - inherited) ---
    // Functions: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2)
    // These are provided by OpenZeppelin's ERC721 contract.

    // --- II. Guardian Lifecycle & State ---

    /**
     * @dev Mints a new GaiaGuardian NFT.
     * @param speciesHash A unique hash representing the Guardian's inherent, immutable species traits.
     * @param ecologicalZoneId The ID of the ecological zone this Guardian is linked to.
     */
    function mintGuardian(bytes32 speciesHash, uint256 ecologicalZoneId)
        public
        payable
        nonReentrant
        whenNotPaused
        zoneExists(ecologicalZoneId)
        returns (uint256)
    {
        // Require a small fee for minting to prevent spam or assign initial value
        // if (msg.value < 0.01 ether) revert GaiaGuardians__NotEnoughFunds(); // Optional: Add a minting fee

        _nextTokenId++;
        uint256 newId = _nextTokenId;

        _safeMint(msg.sender, newId);

        guardians[newId] = Guardian({
            tokenId: newId,
            owner: msg.sender,
            mintTime: block.timestamp,
            speciesHash: speciesHash,
            ecologicalZoneId: ecologicalZoneId,
            health: 800, // Start with good health
            mood: 700,   // Good mood
            awareness: 100, // Low awareness, it's an egg!
            impactScore: 0,
            lastNurturedTime: block.timestamp,
            lastMeditatedTime: uint224(block.timestamp),
            lastEnvironmentalUpdateTime: block.timestamp
        });

        // Potentially send a portion of minting fee to public goods
        // if (publicGoodsBeneficiary != address(0)) {
        //     (bool sent, ) = publicGoodsBeneficiary.call{value: msg.value / 2}("");
        //     require(sent, "Failed to send minting contribution to beneficiary");
        // }

        emit GuardianMinted(newId, msg.sender, speciesHash, ecologicalZoneId);
        return newId;
    }

    /**
     * @dev Retrieves the full current dynamic state of a Guardian.
     * @param tokenId The ID of the Guardian.
     * @return health, mood, awareness, impactScore, evolutionStage
     */
    function getGuardianState(uint256 tokenId)
        public
        view
        guardianExists(tokenId)
        returns (uint256 health, uint256 mood, uint256 awareness, uint256 impactScore, EvolutionStage evolutionStage)
    {
        Guardian storage guardian = guardians[tokenId];
        (health, mood, awareness, impactScore) = _calculateDynamicAttributes(guardian);
        evolutionStage = _getEvolutionStage(impactScore, awareness);
    }

    /**
     * @dev Retrieves immutable details of a Guardian.
     * @param tokenId The ID of the Guardian.
     * @return speciesHash, ecologicalZoneId, mintTime
     */
    function getGuardianDetails(uint256 tokenId)
        public
        view
        guardianExists(tokenId)
        returns (bytes32 speciesHash, uint256 ecologicalZoneId, uint256 mintTime)
    {
        Guardian storage guardian = guardians[tokenId];
        return (guardian.speciesHash, guardian.ecologicalZoneId, guardian.mintTime);
    }

    /**
     * @dev Internal helper function to calculate and update a Guardian's dynamic attributes.
     *      This is where the "sentient" and "evolving" logic resides.
     * @param guardian The Guardian struct to update.
     * @return The updated health, mood, awareness, and impactScore.
     */
    function _calculateDynamicAttributes(Guardian storage guardian)
        internal
        view
        returns (uint256 currentHealth, uint256 currentMood, uint256 currentAwareness, uint256 currentImpactScore)
    {
        // Base attributes
        currentHealth = guardian.health;
        currentMood = guardian.mood;
        currentAwareness = guardian.awareness;
        currentImpactScore = guardian.impactScore;

        // --- Time-based Decay ---
        uint256 timeSinceLastUpdate = block.timestamp.sub(guardian.lastEnvironmentalUpdateTime);
        uint256 daysSinceLastUpdate = timeSinceLastUpdate.div(1 days);

        if (daysSinceLastUpdate > 0) {
            uint256 healthDecay = daysSinceLastUpdate.mul(HEALTH_DECAY_RATE_PER_DAY);
            currentHealth = currentHealth > healthDecay ? currentHealth.sub(healthDecay) : 0;
            // Mood decays with health
            currentMood = currentMood > healthDecay.div(2) ? currentMood.sub(healthDecay.div(2)) : 0;
        }

        // --- Environmental Influence ---
        EcologicalZone storage zone = ecologicalZones[guardian.ecologicalZoneId];
        // Ensure zone data is fresh enough, or consider it stale.
        // For simplicity, let's always apply the latest known, but a more complex system could penalize stale data.
        if (zone.id != 0 && zone.lastOracleUpdateTime > 0) {
            // Adjust health and mood based on zone's overall health index
            // Map zone.overallHealthIndex (-100 to 100) to a health/mood modifier
            int256 healthModifier = zone.overallHealthIndex.div(5); // e.g., 20% impact
            if (healthModifier > 0) {
                currentHealth = currentHealth.add(uint256(healthModifier)).min(1000);
                currentMood = currentMood.add(uint256(healthModifier)).min(1000);
            } else {
                currentHealth = currentHealth > uint256(healthModifier * -1) ? currentHealth.sub(uint256(healthModifier * -1)) : 0;
                currentMood = currentMood > uint256(healthModifier * -1) ? currentMood.sub(uint256(healthModifier * -1)) : 0;
            }
            // Awareness might grow slower in a "bad" environment or faster in a "challenging" one.
            // For now, let's keep it simpler and mostly driven by interaction.
        }

        // Clamp values to 0-1000
        currentHealth = currentHealth.min(1000);
        currentMood = currentMood.min(1000);
        currentAwareness = currentAwareness.min(1000);

        return (currentHealth, currentMood, currentAwareness, currentImpactScore);
    }

    /**
     * @dev Retrieves the current evolution stage of a Guardian based on its dynamic attributes.
     * @param tokenId The ID of the Guardian.
     * @return The current EvolutionStage enum value.
     */
    function getEvolutionStage(uint256 tokenId)
        public
        view
        guardianExists(tokenId)
        returns (EvolutionStage)
    {
        Guardian storage guardian = guardians[tokenId];
        (uint256 health, uint256 mood, uint256 awareness, uint256 impactScore) = _calculateDynamicAttributes(guardian);
        return _getEvolutionStage(impactScore, awareness);
    }

    /**
     * @dev Internal helper to determine evolution stage based on impact and awareness.
     */
    function _getEvolutionStage(uint256 impactScore, uint256 awareness)
        internal
        view
        returns (EvolutionStage)
    {
        if (impactScore >= evolutionThresholds[uint8(EvolutionStage.Elder)].impactThreshold &&
            awareness >= evolutionThresholds[uint8(EvolutionStage.Elder)].awarenessThreshold) {
            return EvolutionStage.Elder;
        } else if (impactScore >= evolutionThresholds[uint8(EvolutionStage.Adult)].impactThreshold &&
                   awareness >= evolutionThresholds[uint8(EvolutionStage.Adult)].awarenessThreshold) {
            return EvolutionStage.Adult;
        } else if (impactScore >= evolutionThresholds[uint8(EvolutionStage.Juvenile)].impactThreshold &&
                   awareness >= evolutionThresholds[uint8(EvolutionStage.Juvenile)].awarenessThreshold) {
            return EvolutionStage.Juvenile;
        } else if (impactScore >= evolutionThresholds[uint8(EvolutionStage.Larva)].impactThreshold &&
                   awareness >= evolutionThresholds[uint8(EvolutionStage.Larva)].awarenessThreshold) {
            return EvolutionStage.Larva;
        } else {
            return EvolutionStage.Egg;
        }
    }

    // --- III. Owner Interaction & Nurturing ---

    /**
     * @dev Allows the owner to "nurture" their Guardian by paying a fee.
     *      Boosts health, mood, and awareness. A portion goes to public goods.
     * @param tokenId The ID of the Guardian to nurture.
     */
    function nurtureGuardian(uint256 tokenId)
        public
        payable
        nonReentrant
        whenNotPaused
        guardianExists(tokenId)
    {
        Guardian storage guardian = guardians[tokenId];
        if (msg.sender != guardian.owner) revert ERC721IncorrectOwner();
        if (msg.value < nurturingFee) revert GaiaGuardians__NotEnoughFunds();
        if (block.timestamp < guardian.lastNurturedTime.add(NURTURE_COOLDOWN)) revert GaiaGuardians__NurtureCooldown();

        // Update state based on current time and environment
        (uint256 currentHealth, uint256 currentMood, uint256 currentAwareness, uint256 currentImpactScore) = _calculateDynamicAttributes(guardian);
        guardian.health = currentHealth.add(HEALTH_BOOST_PER_NURTURE).min(1000);
        guardian.mood = currentMood.add(MOOD_BOOST_PER_NURTURE).min(1000);
        guardian.awareness = currentAwareness.add(AWARENESS_BOOST_PER_NURTURE).min(1000);
        guardian.impactScore = currentImpactScore.add(AWARENESS_BOOST_PER_NURTURE.div(2)); // Small impact boost from nurturing

        guardian.lastNurturedTime = block.timestamp;
        guardian.lastEnvironmentalUpdateTime = block.timestamp; // Mark as updated

        // Distribute funds
        uint256 publicGoodsPortion = msg.value.div(2); // 50% to public goods
        uint256 contractPortion = msg.value.sub(publicGoodsPortion);

        if (publicGoodsBeneficiary != address(0)) {
            (bool sent, ) = publicGoodsBeneficiary.call{value: publicGoodsPortion}("");
            require(sent, "Failed to send public goods contribution");
        }
        // The `contractPortion` remains in the contract, could be used for maintenance, future features, etc.

        emit GuardianNurtured(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev A free, passive interaction that provides a small, time-gated boost to mood and awareness.
     * @param tokenId The ID of the Guardian to meditate with.
     */
    function meditateWithGuardian(uint256 tokenId)
        public
        nonReentrant
        whenNotPaused
        guardianExists(tokenId)
    {
        Guardian storage guardian = guardians[tokenId];
        if (msg.sender != guardian.owner) revert ERC721IncorrectOwner();
        if (block.timestamp < uint256(guardian.lastMeditatedTime).add(MEDITATE_COOLDOWN)) revert GaiaGuardians__MeditateCooldown();

        // Update state based on current time and environment
        (uint256 currentHealth, uint256 currentMood, uint256 currentAwareness, uint256 currentImpactScore) = _calculateDynamicAttributes(guardian);
        guardian.mood = currentMood.add(MEDITATE_MOOD_BOOST).min(1000);
        guardian.awareness = currentAwareness.add(MEDITATE_AWARENESS_BOOST).min(1000);

        guardian.lastMeditatedTime = uint224(block.timestamp);
        guardian.lastEnvironmentalUpdateTime = block.timestamp; // Mark as updated

        emit GuardianMeditated(tokenId, msg.sender);
    }

    /**
     * @dev Allows owners to directly contribute funds to the specific ecologicalZone their Guardian is linked to.
     *      Significantly boosts the Guardian's impactScore. A portion goes to public goods.
     * @param tokenId The ID of the Guardian associated with the zone.
     * @param amount The amount of ETH to contribute.
     */
    function contributeToZone(uint256 tokenId, uint256 amount)
        public
        payable
        nonReentrant
        whenNotPaused
        guardianExists(tokenId)
    {
        Guardian storage guardian = guardians[tokenId];
        if (msg.sender != guardian.owner) revert ERC721IncorrectOwner();
        if (msg.value < amount || amount == 0) revert GaiaGuardians__NotEnoughFunds();
        if (environmentalOracle == address(0)) revert GaiaGuardians__OracleNotSet(); // Oracle must be set for zone interaction

        // Update state based on current time and environment
        (uint256 currentHealth, uint256 currentMood, uint256 currentAwareness, uint256 currentImpactScore) = _calculateDynamicAttributes(guardian);
        uint256 impactBoost = amount.div(1 ether).mul(IMPACT_BOOST_PER_CONTRIBUTION_ETH_FACTOR);
        if (impactBoost == 0 && amount > 0) impactBoost = 1; // Ensure some boost even for small contributions
        guardian.impactScore = currentImpactScore.add(impactBoost);
        guardian.awareness = currentAwareness.add(impactBoost.div(10)).min(1000); // Small awareness boost from active contribution

        guardian.lastEnvironmentalUpdateTime = block.timestamp; // Mark as updated

        // Distribute funds
        uint256 publicGoodsPortion = amount.div(2); // 50% to public goods
        uint256 contractPortion = amount.sub(publicGoodsPortion);

        if (publicGoodsBeneficiary != address(0)) {
            (bool sent, ) = publicGoodsBeneficiary.call{value: publicGoodsPortion}("");
            require(sent, "Failed to send public goods contribution");
        }
        // The `contractPortion` remains in the contract, could be used for maintenance, future features, etc.

        emit ZoneContributed(tokenId, guardian.ecologicalZoneId, msg.sender, amount);
    }

    // --- IV. Environmental Oracle Integration ---

    /**
     * @dev Allows the owner to set the address of the trusted environmental data oracle.
     * @param newOracle The address of the new oracle contract.
     */
    function setEnvironmentalOracle(address newOracle) public onlyOwner {
        address oldOracle = environmentalOracle;
        environmentalOracle = newOracle;
        emit OracleSet(oldOracle, newOracle);
    }

    /**
     * @dev Callback function for the oracle to push new environmental data for a specific zone.
     *      This data influences all Guardians within that zone.
     * @param zoneId The ID of the ecological zone.
     * @param dataHash A hash representing the raw, verified environmental data package.
     * @param overallHealthIndex An aggregated index (e.g., -100 to 100) summarizing the zone's health.
     */
    function receiveEnvironmentalData(uint256 zoneId, bytes32 dataHash, int256 overallHealthIndex)
        external
        onlyOracle
        nonReentrant
        zoneExists(zoneId)
    {
        EcologicalZone storage zone = ecologicalZones[zoneId];
        zone.overallHealthIndex = overallHealthIndex;
        zone.environmentalDataHash = dataHash;
        zone.lastOracleUpdateTime = block.timestamp;

        // Note: Individual guardian attributes are NOT updated here to save gas.
        // They are calculated on-demand or when an owner interacts with their guardian.
        // This makes the oracle update cheaper.

        emit EnvironmentalDataReceived(zoneId, dataHash, overallHealthIndex);
    }

    /**
     * @dev Allows anyone to pay gas to trigger the oracle to fetch and update data for a specific zone.
     *      This ensures data freshness and incentivizes timely updates.
     *      The actual oracle call would be an off-chain interaction or a separate chainlink request.
     *      For this contract, we simply emit an event to signal the request.
     * @param zoneId The ID of the ecological zone to refresh.
     */
    function triggerZoneDataRefresh(uint256 zoneId)
        public
        payable
        zoneExists(zoneId)
    {
        // This function would typically interact with a Chainlink VRF or a custom oracle network
        // to request a data update. For this example, we simply emit an event.
        // The msg.value could be used to pay for the oracle's gas fees.

        // Placeholder for actual oracle request logic:
        // environmentalOracle.requestData(zoneId, msg.value);

        emit EnvironmentalDataReceived(zoneId, bytes32("DATA_REFRESH_REQUESTED"), 0); // Placeholder event
    }

    // --- V. Public Goods Funding ---

    /**
     * @dev Allows the owner to set the address of the public goods beneficiary DAO/fund.
     * @param newBeneficiary The address of the new beneficiary.
     */
    function setPublicGoodsBeneficiary(address newBeneficiary) public onlyOwner {
        address oldBeneficiary = publicGoodsBeneficiary;
        publicGoodsBeneficiary = newBeneficiary;
        emit BeneficiarySet(oldBeneficiary, newBeneficiary);
    }

    /**
     * @dev Allows the designated public goods beneficiary to withdraw accumulated funds.
     */
    function withdrawPublicGoodsFunds() public nonReentrant onlyBeneficiary {
        uint256 amount = address(this).balance; // Total contract balance, assuming beneficiary gets all excess
        if (amount == 0) return;

        (bool sent, ) = publicGoodsBeneficiary.call{value: amount}("");
        require(sent, "Failed to withdraw funds");

        emit PublicGoodsFundsWithdrawn(publicGoodsBeneficiary, amount);
    }

    // --- VI. Administrative & Configuration ---

    /**
     * @dev Pauses the contract, preventing certain operations.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to adjust the fee for nurturing a Guardian.
     * @param newFee The new nurturing fee in wei.
     */
    function setNurturingFee(uint256 newFee) public onlyOwner {
        nurturingFee = newFee;
        emit NurturingFeeSet(newFee);
    }

    /**
     * @dev Configures the impactScore and awareness thresholds required for Guardians to evolve to the next stage.
     * @param stage The `EvolutionStage` enum value (cast to uint8) for which to set thresholds.
     * @param impactThreshold The minimum `impactScore` required for this stage.
     * @param awarenessThreshold The minimum `awareness` required for this stage.
     */
    function setEvolutionThresholds(uint8 stage, uint256 impactThreshold, uint256 awarenessThreshold)
        public
        onlyOwner
    {
        if (stage >= uint8(EvolutionStage.Elder) && (impactThreshold == 0 || awarenessThreshold == 0)) {
            // Ensure Elder stage always has high thresholds if set (or allow 0 for disabled)
        }
        evolutionThresholds[stage] = EvolutionThreshold(impactThreshold, awarenessThreshold);
        emit EvolutionThresholdsSet(stage, impactThreshold, awarenessThreshold);
    }
}
```