```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
    Outline and Function Summary:

    This contract, **Chronosynths**, represents an advanced ecosystem of evolving, dynamic ERC-721 digital entities.
    Each Chronosynth possesses unique, mutable attributes and traits that evolve based on owner interactions,
    resource consumption (Essence & Knowledge tokens), and participation in Synaptic Challenges.
    The system incorporates elements of gamified progression, inter-entity dynamics, and conceptual environmental influences.

    I. Core ERC-721 & Management
    1.  `constructor()`: Initializes the contract, sets the `EssenceToken` and `KnowledgeToken` addresses,
        and assigns the deployer as owner/admin.
    2.  `mintChronosynth(address _to, uint8[4] memory _initialAttributes)`: Allows a designated Minter role to
        create a new Chronosynth NFT for `_to`, with predefined base attributes.
    3.  `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for a given Chronosynth. The metadata is
        intended to reflect the Chronosynth's current attributes and traits.
    4.  `setBaseURI(string memory _newBaseURI)`: Admin function to update the base URI used for `tokenURI`.
    5.  `pause()`: Admin function to pause core interaction functionalities, e.g., during upgrades or maintenance.
    6.  `unpause()`: Admin function to unpause functionalities.
    *(Standard ERC-721 functions like `balanceOf`, `ownerOf`, `approve`, `getApproved`, `setApprovalForAll`,
    `isApprovedForAll`, `transferFrom`, `safeTransferFrom` are inherited from OpenZeppelin's `ERC721` and are
    assumed to be part of the core functionality count).*

    II. Chronosynth Attribute & Trait Management
    7.  `getSynthAttributes(uint256 tokenId)`: Retrieves the current Agility, Resilience, Intellect, and Empathy attributes,
        along with Wisdom Level and XP, for a specified Chronosynth.
    8.  `getSynthTraits(uint256 tokenId)`: Returns a list of active `TraitType` enums for a given Chronosynth.
    9.  `getSynthEvolutionStatus(uint256 tokenId)`: Provides an overview of a Chronosynth's current evolution state,
        including its accumulated Essence and Knowledge (held by the contract on behalf of the Synth), XP, and progress
        towards the next Wisdom Level.
    10. `trainAttribute(uint256 tokenId, uint8 attributeIndex)`: Allows a Chronosynth owner to spend `Essence` and `Knowledge`
        to directly increase a specific attribute (Agility=0, Resilience=1, etc.). Less efficient than challenges but direct.
    11. `setInitialSynthAttributes(uint8[4] memory _baseAttributes)`: Admin function to configure the default base attributes
        for newly minted Chronosynths.

    III. Synaptic Challenges & Progression
    12. `initiateSynapticChallenge(uint256 tokenId, uint8 challengeId)`: Commits a Chronosynth to a specified Synaptic Challenge,
        burning required Essence and Knowledge resources from the Synth's internal balance.
    13. `completeSynapticChallenge(uint256 tokenId, uint8 challengeId, bytes32 _challengeProof)`: User submits proof of challenge
        completion (e.g., a hash meeting certain criteria). If successful, the Synth gains XP, potentially rewards, and may
        see attribute boosts or trait unlocks. Simulates on-chain mini-games.
    14. `setChallengeConfig(uint8 challengeId, string memory name, uint256 essenceCost, uint256 knowledgeCost, uint256 xpReward,
        uint8 successChancePercent, TraitType[] memory possibleTraitRewards, uint8[4] memory minAttributeBoosts,
        uint8[4] memory maxAttributeBoosts)`: Admin function to define or update parameters for different types of Synaptic Challenges.
    15. `getChallengeConfig(uint8 challengeId)`: Retrieves the configuration details for a specific challenge.
    16. `_unlockTrait(uint256 tokenId, TraitType trait)`: (Internal) Logic to activate a specific trait for a Chronosynth,
        triggered by attribute thresholds or challenge completion.
    17. `_degradeTrait(uint256 tokenId, TraitType trait)`: (Internal) Logic to potentially deactivate or reduce the effectiveness
        of a trait, possibly due to inactivity or negative events.

    IV. Inter-Synth Dynamics & Resources
    18. `synthesizeResources(uint256 tokenIdA, uint256 tokenIdB, uint256 essenceAmount, uint256 knowledgeAmount)`: Allows owners of
        two Chronosynths (`tokenIdA`, `tokenIdB`) to combine their internal Essence and Knowledge pools for a shared purpose
        (e.g., a more difficult challenge), requiring approval for transfer between their internal balances.
    19. `probeForKnowledge(uint256 proverSynthId, uint256 targetSynthId)`: Allows `proverSynthId` to attempt to gain Knowledge
        from `targetSynthId`; requires `targetSynthId` owner's approval and consumes resources from `targetSynthId` as a "tax."
    20. `claimDailyEssence(uint256 tokenId)`: Enables a Chronosynth owner to claim a small, daily allowance of Essence for their
        Synth, encouraging regular interaction.
    21. `replicateSynth(uint256 parentSynthId, address _to)`: A highly advanced function where a high-Wisdom Chronosynth can
        "replicate" itself, burning significant Essence and Knowledge, to mint a new Chronosynth that inherits some base attributes,
        initiating a new generation.

    V. System & Environmental Influence
    22. `registerOracleObservation(uint256 _observationValue)`: Allows a designated Oracle role to submit external data (e.g., a block hash,
        a simulated market index) that can influence the ecosystem's dynamics.
    23. `assessEnvironmentalInfluence()`: Triggers a system-wide recalculation or adjustment of challenge difficulties or attribute boost
        potential based on the latest `_observationValue` submitted by the Oracle, simulating dynamic "seasons" or environmental changes.
        This can be called by anyone but requires the latest observation.
*/

contract Chronosynths is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // --- Error Definitions ---
    error NotOwnerOfSynth(uint256 tokenId);
    error InvalidAttributeIndex();
    error InsufficientResources(uint256 tokenId, uint256 requiredEssence, uint256 requiredKnowledge);
    error ChallengeDoesNotExist(uint8 challengeId);
    error ChallengeNotInitiated(uint256 tokenId, uint8 challengeId);
    error UnauthorizedMinter();
    error UnauthorizedOracle();
    error NotEnoughWisdom(uint256 requiredWisdom);
    error ReplicationNotPossible();
    error AlreadyClaimedDailyEssence();
    error CannotProbeSelf();
    error SynthNotFound(uint256 tokenId);
    error InsufficientApprovedAmount(address tokenAddress, uint256 amount);

    // --- Enums ---
    enum TraitType {
        None, // Default or placeholder
        Adaptability,
        ResilienceBoost,
        IntellectFocus,
        EmpathyLink,
        Swiftness,
        DeepLearning,
        ProtectiveAura,
        CommunalLink,
        SelfRepair,
        Foresight
    }

    // --- Structs ---
    struct SynthAttributes {
        uint8 agility;     // Speed, reaction time, evasiveness
        uint8 resilience;  // Durability, resistance to decay
        uint8 intellect;   // Problem-solving, learning rate
        uint8 empathy;     // Connection, collaboration, social influence
        uint16 wisdomLevel; // Overall progression, unlocks higher-tier abilities
        uint32 currentXP;   // Experience points towards next wisdomLevel
        uint32 nextLevelXP; // XP needed for the next wisdomLevel
    }

    struct ChallengeConfig {
        string name;
        uint256 essenceCost;
        uint256 knowledgeCost;
        uint256 xpReward;
        uint8 successChancePercent; // 0-100%
        TraitType[] possibleTraitRewards; // Traits that can be unlocked upon success
        uint8[4] minAttributeBoosts;  // Min boost for [agility, resilience, intellect, empathy]
        uint8[4] maxAttributeBoosts;  // Max boost for [agility, resilience, intellect, empathy]
    }

    // --- State Variables ---
    IERC20 public immutable essenceToken;
    IERC20 public immutable knowledgeToken;

    mapping(uint256 => SynthAttributes) public synthAttributes;
    mapping(uint256 => mapping(TraitType => bool)) public synthTraits; // tokenId => trait => isActive

    mapping(uint256 => uint256) public synthEssenceBalance;    // Essence held by the contract for each Synth
    mapping(uint256 => uint256) public synthKnowledgeBalance;  // Knowledge held by the contract for each Synth

    mapping(uint256 => uint48) public lastDailyEssenceClaim; // tokenId => last claim timestamp (packed for gas)
    uint256 public constant DAILY_ESSENCE_CLAIM_AMOUNT = 100 * 10**18; // 100 Essence
    uint48 public constant DAILY_CLAIM_COOLDOWN = 24 hours;

    mapping(uint8 => ChallengeConfig) public challengeConfigs;
    uint8 public nextChallengeId = 1; // Start from 1 for easier management

    mapping(uint256 => mapping(uint8 => bool)) public activeChallenges; // tokenId => challengeId => isActive

    address public minterRole;
    address public oracleRole;

    uint8[4] public defaultInitialSynthAttributes = [10, 10, 10, 10]; // Default for new Synths

    uint256 public lastOracleObservation; // Stores the last value provided by the oracle
    uint256 public lastEnvironmentalAssessmentTimestamp;

    // --- Events ---
    event SynthMinted(uint256 indexed tokenId, address indexed owner, uint8[4] initialAttributes);
    event AttributesTrained(uint256 indexed tokenId, uint8 attributeIndex, uint8 newAttributeValue);
    event TraitUnlocked(uint256 indexed tokenId, TraitType trait);
    event ChallengeInitiated(uint256 indexed tokenId, uint8 indexed challengeId);
    event ChallengeCompleted(uint256 indexed tokenId, uint8 indexed challengeId, bool success, uint256 xpGained);
    event ResourcesSynthesized(uint256 indexed tokenIdA, uint256 indexed tokenIdB, uint256 essenceAmount, uint256 knowledgeAmount);
    event KnowledgeProbed(uint256 indexed proverSynthId, uint256 indexed targetSynthId, uint256 knowledgeGained);
    event DailyEssenceClaimed(uint256 indexed tokenId, uint256 amount);
    event SynthReplicated(uint256 indexed parentSynthId, uint256 indexed childSynthId, address childOwner);
    event OracleObservationRegistered(uint256 indexed observationValue, uint256 timestamp);
    event EnvironmentalInfluenceAssessed(uint256 latestObservation, uint256 timestamp);

    // --- Modifiers ---
    modifier onlyMinter() {
        if (msg.sender != minterRole) {
            revert UnauthorizedMinter();
        }
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleRole) {
            revert UnauthorizedOracle();
        }
        _;
    }

    // --- Constructor ---
    constructor(address _essenceToken, address _knowledgeToken)
        ERC721("Chronosynth", "CSYNTH")
        Ownable(msg.sender)
    {
        essenceToken = IERC20(_essenceToken);
        knowledgeToken = IERC20(_knowledgeToken);
        minterRole = msg.sender; // Deployer is also the initial minter
        oracleRole = msg.sender; // Deployer is also the initial oracle
    }

    // --- I. Core ERC-721 & Management ---

    function setMinterRole(address _minter) external onlyOwner {
        minterRole = _minter;
    }

    function setOracleRole(address _oracle) external onlyOwner {
        oracleRole = _oracle;
    }

    function mintChronosynth(address _to, uint8[4] memory _initialAttributes)
        external
        onlyMinter
        whenNotPaused
    {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();
        _safeMint(_to, newItemId);

        require(_initialAttributes.length == 4, "Initial attributes must be 4 elements.");
        synthAttributes[newItemId] = SynthAttributes({
            agility: _initialAttributes[0],
            resilience: _initialAttributes[1],
            intellect: _initialAttributes[2],
            empathy: _initialAttributes[3],
            wisdomLevel: 1,
            currentXP: 0,
            nextLevelXP: 1000 // Initial XP for Level 2
        });
        emit SynthMinted(newItemId, _to, _initialAttributes);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        _requireOwned(tokenId); // Ensure tokenId exists and is owned

        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return ""; // No base URI set
        }
        // This is a placeholder. In a real dApp, this would point to a server/gateway
        // that dynamically generates JSON metadata based on the on-chain state of the Chronosynth.
        return string(abi.encodePacked(base, Strings.toString(tokenId), ".json"));
    }

    function _baseURI() internal view override returns (string memory) {
        return "https://chronosynths.io/metadata/"; // Example base URI
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // --- II. Chronosynth Attribute & Trait Management ---

    function getSynthAttributes(uint256 tokenId)
        public
        view
        returns (SynthAttributes memory)
    {
        _requireOwned(tokenId);
        return synthAttributes[tokenId];
    }

    function getSynthTraits(uint256 tokenId)
        public
        view
        returns (TraitType[] memory)
    {
        _requireOwned(tokenId);
        // This is a simplified way. A more complex system might iterate through all possible traits
        // or store active traits in a dynamic array.
        TraitType[] memory activeTraits = new TraitType[](10); // Max 10 traits for example
        uint256 count = 0;
        for (uint8 i = 0; i < uint8(TraitType.Foresight) + 1; i++) {
            if (synthTraits[tokenId][TraitType(i)]) {
                activeTraits[count] = TraitType(i);
                count++;
            }
        }
        TraitType[] memory result = new TraitType[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeTraits[i];
        }
        return result;
    }

    function getSynthEvolutionStatus(uint256 tokenId)
        public
        view
        returns (uint256 essence, uint256 knowledge, uint32 xp, uint16 wisdomLevel, uint32 nextLevelXP)
    {
        _requireOwned(tokenId);
        SynthAttributes memory attrs = synthAttributes[tokenId];
        return (
            synthEssenceBalance[tokenId],
            synthKnowledgeBalance[tokenId],
            attrs.currentXP,
            attrs.wisdomLevel,
            attrs.nextLevelXP
        );
    }

    function trainAttribute(uint256 tokenId, uint8 attributeIndex)
        external
        whenNotPaused
    {
        _requireOwned(tokenId);
        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwnerOfSynth(tokenId);
        }

        uint256 essenceCost = 50 * 10**18;
        uint256 knowledgeCost = 20 * 10**18;

        if (synthEssenceBalance[tokenId] < essenceCost || synthKnowledgeBalance[tokenId] < knowledgeCost) {
            revert InsufficientResources(tokenId, essenceCost, knowledgeCost);
        }

        _burnSynthResources(tokenId, essenceCost, knowledgeCost);

        SynthAttributes storage attrs = synthAttributes[tokenId];
        uint8 oldVal;
        if (attributeIndex == 0) {
            oldVal = attrs.agility;
            attrs.agility += 1; // Example: increase by 1
        } else if (attributeIndex == 1) {
            oldVal = attrs.resilience;
            attrs.resilience += 1;
        } else if (attributeIndex == 2) {
            oldVal = attrs.intellect;
            attrs.intellect += 1;
        } else if (attributeIndex == 3) {
            oldVal = attrs.empathy;
            attrs.empathy += 1;
        } else {
            revert InvalidAttributeIndex();
        }

        // Check for trait unlocks based on new attribute values
        _checkAndUnlockTraits(tokenId);

        emit AttributesTrained(tokenId, attributeIndex, (attributeIndex == 0 ? attrs.agility : (attributeIndex == 1 ? attrs.resilience : (attributeIndex == 2 ? attrs.intellect : attrs.empathy))));
    }

    function setInitialSynthAttributes(uint8[4] memory _baseAttributes) external onlyOwner {
        require(_baseAttributes.length == 4, "Base attributes must be 4 elements.");
        defaultInitialSynthAttributes = _baseAttributes;
    }

    // --- III. Synaptic Challenges & Progression ---

    function initiateSynapticChallenge(uint256 tokenId, uint8 challengeId)
        external
        whenNotPaused
    {
        _requireOwned(tokenId);
        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwnerOfSynth(tokenId);
        }
        ChallengeConfig storage config = challengeConfigs[challengeId];
        if (bytes(config.name).length == 0) {
            revert ChallengeDoesNotExist(challengeId);
        }

        if (synthEssenceBalance[tokenId] < config.essenceCost || synthKnowledgeBalance[tokenId] < config.knowledgeCost) {
            revert InsufficientResources(tokenId, config.essenceCost, config.knowledgeCost);
        }

        _burnSynthResources(tokenId, config.essenceCost, config.knowledgeCost);
        activeChallenges[tokenId][challengeId] = true;

        emit ChallengeInitiated(tokenId, challengeId);
    }

    function completeSynapticChallenge(uint256 tokenId, uint8 challengeId, bytes32 _challengeProof)
        external
        whenNotPaused
    {
        _requireOwned(tokenId);
        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwnerOfSynth(tokenId);
        }
        ChallengeConfig storage config = challengeConfigs[challengeId];
        if (bytes(config.name).length == 0) {
            revert ChallengeDoesNotExist(challengeId);
        }
        if (!activeChallenges[tokenId][challengeId]) {
            revert ChallengeNotInitiated(tokenId, challengeId);
        }

        bool success = false;
        // Simple on-chain "proof" verification for demonstration:
        // A real system might involve more complex computations, ZK-proofs, or oracle interactions.
        // Here, we simulate a probabilistic success based on a hash and the challenge's difficulty.
        uint256 hashValue = uint256(keccak256(abi.encodePacked(_challengeProof, block.timestamp, tokenId)));
        if (hashValue % 100 < config.successChancePercent) {
            success = true;
        }

        activeChallenges[tokenId][challengeId] = false; // Challenge is completed regardless of success

        SynthAttributes storage attrs = synthAttributes[tokenId];
        uint256 xpGained = 0;
        if (success) {
            xpGained = config.xpReward;
            _addXP(tokenId, uint32(xpGained));

            // Randomly boost attributes within the configured range
            for (uint8 i = 0; i < 4; i++) {
                uint8 boost = _randomRange(hashValue, config.minAttributeBoosts[i], config.maxAttributeBoosts[i], i);
                if (i == 0) attrs.agility += boost;
                else if (i == 1) attrs.resilience += boost;
                else if (i == 2) attrs.intellect += boost;
                else if (i == 3) attrs.empathy += boost;
            }

            // Unlock traits
            for (uint256 i = 0; i < config.possibleTraitRewards.length; i++) {
                _unlockTrait(tokenId, config.possibleTraitRewards[i]);
            }
        } else {
            // Optional: Penalty for failure, e.g., XP loss, temporary attribute decrease.
            // For now, no penalty.
        }

        emit ChallengeCompleted(tokenId, challengeId, success, xpGained);
    }

    function setChallengeConfig(
        uint8 challengeId,
        string memory name,
        uint256 essenceCost,
        uint256 knowledgeCost,
        uint256 xpReward,
        uint8 successChancePercent,
        TraitType[] memory possibleTraitRewards,
        uint8[4] memory minAttributeBoosts,
        uint8[4] memory maxAttributeBoosts
    ) external onlyOwner {
        // Enforce max 10 traits for simplicity in getSynthTraits
        require(possibleTraitRewards.length <= 10, "Max 10 possible traits per challenge.");
        require(minAttributeBoosts.length == 4 && maxAttributeBoosts.length == 4, "Attribute boosts must be 4 elements.");
        for(uint8 i=0; i<4; i++) {
            require(minAttributeBoosts[i] <= maxAttributeBoosts[i], "Min boost cannot be greater than max boost.");
        }

        if (challengeId == 0) { // Auto-assign new ID if 0 is provided
            challengeId = nextChallengeId++;
        }
        challengeConfigs[challengeId] = ChallengeConfig({
            name: name,
            essenceCost: essenceCost,
            knowledgeCost: knowledgeCost,
            xpReward: xpReward,
            successChancePercent: successChancePercent,
            possibleTraitRewards: possibleTraitRewards,
            minAttributeBoosts: minAttributeBoosts,
            maxAttributeBoosts: maxAttributeBoosts
        });
    }

    function getChallengeConfig(uint8 challengeId) public view returns (ChallengeConfig memory) {
        return challengeConfigs[challengeId];
    }

    // --- IV. Inter-Synth Dynamics & Resources ---

    function synthesizeResources(uint256 tokenIdA, uint256 tokenIdB, uint256 essenceAmount, uint256 knowledgeAmount)
        external
        whenNotPaused
    {
        _requireOwned(tokenIdA);
        _requireOwned(tokenIdB);

        if (msg.sender != ownerOf(tokenIdA) && msg.sender != ownerOf(tokenIdB)) {
            revert NotOwnerOfSynth(tokenIdA); // Simplified: If not owner of either, revert.
        }

        require(essenceAmount > 0 || knowledgeAmount > 0, "Amounts must be positive.");

        // For simplicity, we assume the resources are transferred from A to B.
        // A more complex system might create a shared pool or require explicit approvals.
        // Here, we transfer from A's internal balance to B's internal balance.
        // Both owners must approve this transaction if it were an external transfer.
        // Given internal balances, we require the owner calling this function to own one of the Synths.
        // And the other Synth owner would need to approve this action or call it themselves.
        // For this example, we assume `msg.sender` holds authority over at least one synth and aims to centralize resources.
        // A proper P2P interaction would involve `permit` or two-step approval.
        // Let's assume `msg.sender` is owner of tokenIdA and wants to send to tokenIdB
        if (msg.sender == ownerOf(tokenIdA)) {
            if (synthEssenceBalance[tokenIdA] < essenceAmount || synthKnowledgeBalance[tokenIdA] < knowledgeAmount) {
                revert InsufficientResources(tokenIdA, essenceAmount, knowledgeAmount);
            }
            synthEssenceBalance[tokenIdA] -= essenceAmount;
            synthKnowledgeBalance[tokenIdA] -= knowledgeAmount;

            synthEssenceBalance[tokenIdB] += essenceAmount;
            synthKnowledgeBalance[tokenIdB] += knowledgeAmount;
        } else if (msg.sender == ownerOf(tokenIdB)) {
             // If msg.sender is owner of B, they pull from A (assuming A's owner approved off-chain or via a different mechanism)
             // For simplicity, this function is designed for owner of A to push to B, or owner of B to pull from A if A gives allowance.
             // This implementation will assume caller is owner of A. A more robust system would involve `approve` for internal balances.
             revert("To pull, targetSynthId owner must initiate, or tokenIdA owner must push.");
        } else {
            revert NotOwnerOfSynth(tokenIdA); // Should be unreachable with prior check, but good for clarity.
        }


        emit ResourcesSynthesized(tokenIdA, tokenIdB, essenceAmount, knowledgeAmount);
    }

    function probeForKnowledge(uint256 proverSynthId, uint256 targetSynthId)
        external
        whenNotPaused
    {
        _requireOwned(proverSynthId);
        _requireOwned(targetSynthId);

        if (msg.sender != ownerOf(proverSynthId)) {
            revert NotOwnerOfSynth(proverSynthId);
        }
        if (proverSynthId == targetSynthId) {
            revert CannotProbeSelf();
        }

        // Simulating a cost for probing the target, and a gain for the prover.
        uint256 knowledgeTax = 50 * 10**18;
        uint256 knowledgeGain = 40 * 10**18; // Gained by prover is less than tax for sink.

        if (synthKnowledgeBalance[targetSynthId] < knowledgeTax) {
            revert InsufficientResources(targetSynthId, 0, knowledgeTax);
        }

        synthKnowledgeBalance[targetSynthId] -= knowledgeTax;
        synthKnowledgeBalance[proverSynthId] += knowledgeGain;

        emit KnowledgeProbed(proverSynthId, targetSynthId, knowledgeGain);
    }

    function claimDailyEssence(uint256 tokenId)
        external
        whenNotPaused
    {
        _requireOwned(tokenId);
        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwnerOfSynth(tokenId);
        }
        if (lastDailyEssenceClaim[tokenId] != 0 && block.timestamp < lastDailyEssenceClaim[tokenId] + DAILY_CLAIM_COOLDOWN) {
            revert AlreadyClaimedDailyEssence();
        }

        synthEssenceBalance[tokenId] += DAILY_ESSENCE_CLAIM_AMOUNT;
        lastDailyEssenceClaim[tokenId] = uint48(block.timestamp);

        emit DailyEssenceClaimed(tokenId, DAILY_ESSENCE_CLAIM_AMOUNT);
    }

    function replicateSynth(uint256 parentSynthId, address _to)
        external
        whenNotPaused
    {
        _requireOwned(parentSynthId);
        if (msg.sender != ownerOf(parentSynthId)) {
            revert NotOwnerOfSynth(parentSynthId);
        }

        SynthAttributes memory parentAttrs = synthAttributes[parentSynthId];
        if (parentAttrs.wisdomLevel < 10) { // Example: Parent needs Wisdom Level 10+
            revert NotEnoughWisdom(10);
        }

        uint256 replicationEssenceCost = 5000 * 10**18;
        uint256 replicationKnowledgeCost = 2000 * 10**18;

        if (synthEssenceBalance[parentSynthId] < replicationEssenceCost || synthKnowledgeBalance[parentSynthId] < replicationKnowledgeCost) {
            revert ReplicationNotPossible(); // Or a more specific error
        }

        _burnSynthResources(parentSynthId, replicationEssenceCost, replicationKnowledgeCost);

        // Inherit some attributes from parent, with some randomness
        uint8[4] memory childInitialAttributes;
        childInitialAttributes[0] = parentAttrs.agility / 2 + uint8(uint256(keccak256(abi.encodePacked(block.timestamp, parentSynthId, 0))) % 5);
        childInitialAttributes[1] = parentAttrs.resilience / 2 + uint8(uint256(keccak256(abi.encodePacked(block.timestamp, parentSynthId, 1))) % 5);
        childInitialAttributes[2] = parentAttrs.intellect / 2 + uint8(uint256(keccak256(abi.encodePacked(block.timestamp, parentSynthId, 2))) % 5);
        childInitialAttributes[3] = parentAttrs.empathy / 2 + uint8(uint256(keccak256(abi.encodePacked(block.timestamp, parentSynthId, 3))) % 5);

        // Ensure attributes are within a reasonable range (e.g., min 1)
        for(uint8 i=0; i<4; i++) {
            if(childInitialAttributes[i] == 0) childInitialAttributes[i] = 1;
        }

        _tokenIdCounter.increment();
        uint256 childSynthId = _tokenIdCounter.current();
        _safeMint(_to, childSynthId);

        synthAttributes[childSynthId] = SynthAttributes({
            agility: childInitialAttributes[0],
            resilience: childInitialAttributes[1],
            intellect: childInitialAttributes[2],
            empathy: childInitialAttributes[3],
            wisdomLevel: 1,
            currentXP: 0,
            nextLevelXP: 1000
        });

        emit SynthReplicated(parentSynthId, childSynthId, _to);
    }

    // --- V. System & Environmental Influence ---

    function registerOracleObservation(uint256 _observationValue)
        external
        onlyOracle
    {
        lastOracleObservation = _observationValue;
        emit OracleObservationRegistered(_observationValue, block.timestamp);
    }

    function assessEnvironmentalInfluence()
        public
        whenNotPaused
    {
        // This function is public, allowing anyone to trigger the assessment
        // It relies on the latest oracle observation
        require(lastOracleObservation > 0, "No oracle observation available.");
        require(block.timestamp > lastEnvironmentalAssessmentTimestamp + 1 days, "Environmental assessment cooldown."); // Cooldown: 1 day

        // Example: The oracle observation could influence global challenge difficulties,
        // or attribute growth rates, or even unlock temporary global traits.
        // For simplicity, let's say it influences the base success chance of all challenges.
        // This would require iterating through all challenge configs, or adjusting a global multiplier.
        // Let's implement a dynamic adjustment to challenge difficulty:
        // If lastOracleObservation is even, challenges are slightly easier, odd, slightly harder.
        // This is a placeholder for complex environmental mechanics.

        // Example: Adjust XP reward for a specific challenge (e.g., challengeId 1)
        uint8 exampleChallengeId = 1;
        ChallengeConfig storage config = challengeConfigs[exampleChallengeId];
        if (bytes(config.name).length > 0) {
            if (lastOracleObservation % 2 == 0) {
                config.xpReward = config.xpReward + (config.xpReward / 10); // +10% XP if observation is even
            } else {
                config.xpReward = config.xpReward - (config.xpReward / 20); // -5% XP if observation is odd
            }
        }
        lastEnvironmentalAssessmentTimestamp = block.timestamp;
        emit EnvironmentalInfluenceAssessed(lastOracleObservation, block.timestamp);
    }

    // --- Internal & Private Helper Functions ---

    function _requireOwned(uint256 tokenId) internal view {
        if (!_exists(tokenId)) {
            revert SynthNotFound(tokenId);
        }
        // ERC721's _exists already checks if ownerOf(tokenId) returns address(0)
    }

    function _addXP(uint256 tokenId, uint32 xpAmount) internal {
        SynthAttributes storage attrs = synthAttributes[tokenId];
        attrs.currentXP += xpAmount;

        while (attrs.currentXP >= attrs.nextLevelXP) {
            attrs.currentXP -= attrs.nextLevelXP;
            attrs.wisdomLevel += 1;
            attrs.nextLevelXP = attrs.nextLevelXP * 12 / 10; // Increase next level XP by 20%
            // Automatically boost a random attribute on level up
            uint8 randomAttrIndex = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId, attrs.wisdomLevel))) % 4);
            if (randomAttrIndex == 0) attrs.agility += 1;
            else if (randomAttrIndex == 1) attrs.resilience += 1;
            else if (randomAttrIndex == 2) attrs.intellect += 1;
            else if (randomAttrIndex == 3) attrs.empathy += 1;

            _checkAndUnlockTraits(tokenId); // Check for new trait unlocks
        }
    }

    function _checkAndUnlockTraits(uint256 tokenId) internal {
        SynthAttributes memory attrs = synthAttributes[tokenId];
        // Example trait unlocking logic:
        // 1. Adaptability: If Agility + Intellect >= 100
        if (attrs.agility + attrs.intellect >= 100 && !synthTraits[tokenId][TraitType.Adaptability]) {
            _unlockTrait(tokenId, TraitType.Adaptability);
        }
        // 2. ResilienceBoost: If Resilience >= 50
        if (attrs.resilience >= 50 && !synthTraits[tokenId][TraitType.ResilienceBoost]) {
            _unlockTrait(tokenId, TraitType.ResilienceBoost);
        }
        // Add more complex trait unlocking conditions here
    }

    function _unlockTrait(uint256 tokenId, TraitType trait) internal {
        if (trait == TraitType.None) return; // Prevent unlocking placeholder
        if (!synthTraits[tokenId][trait]) {
            synthTraits[tokenId][trait] = true;
            emit TraitUnlocked(tokenId, trait);
        }
    }

    function _degradeTrait(uint256 tokenId, TraitType trait) internal {
        // Example: Could be called if a Synth is inactive for too long, or fails too many challenges.
        if (synthTraits[tokenId][trait]) {
            synthTraits[tokenId][trait] = false;
            // Emit a TraitDegraded event
        }
    }

    function _burnSynthResources(uint256 tokenId, uint256 essenceAmount, uint256 knowledgeAmount) internal {
        synthEssenceBalance[tokenId] -= essenceAmount;
        synthKnowledgeBalance[tokenId] -= knowledgeAmount;
        // In a real system, these would likely be burned or transferred to a treasury via the ERC20 contracts.
        // For simplicity, here they are removed from the synth's internal balance.
        // To interact with external ERC20s, the contract would need the tokens:
        // essenceToken.transferFrom(ownerOf(tokenId), address(this), essenceAmount);
        // knowledgeToken.transferFrom(ownerOf(tokenId), address(this), knowledgeAmount);
        // Then, optionally, transfer from this contract to a burn address or treasury.
    }

    function _randomRange(uint256 seed, uint8 min, uint8 max, uint8 offset) internal pure returns (uint8) {
        if (min >= max) return min;
        return min + uint8(uint256(keccak256(abi.encodePacked(seed, block.number, block.timestamp, msg.sender, offset))) % (max - min + 1));
    }

    // --- External resource deposit functions (assumes tokens are given to contract) ---
    // These functions allow users to deposit external Essence/Knowledge tokens into their Synth's internal balance.
    function depositEssence(uint256 tokenId, uint256 amount) external whenNotPaused {
        _requireOwned(tokenId);
        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwnerOfSynth(tokenId);
        }
        require(essenceToken.transferFrom(msg.sender, address(this), amount), "Essence transfer failed.");
        synthEssenceBalance[tokenId] += amount;
    }

    function depositKnowledge(uint256 tokenId, uint256 amount) external whenNotPaused {
        _requireOwned(tokenId);
        if (msg.sender != ownerOf(tokenId)) {
            revert NotOwnerOfSynth(tokenId);
        }
        require(knowledgeToken.transferFrom(msg.sender, address(this), amount), "Knowledge transfer failed.");
        synthKnowledgeBalance[tokenId] += amount;
    }

    // For simplicity, no withdraw functions for Synth's internal balances, they are meant to be consumed.
    // A more complete system would have them or allow owners to transfer.

    // Fallback and Receive functions (optional, but good practice if expecting ETH)
    receive() external payable {
        // Optionally handle received ETH, perhaps converting to Essence/Knowledge or for future fees
    }

    fallback() external payable {
        // Optionally handle arbitrary calls
    }
}
```