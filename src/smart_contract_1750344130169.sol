Okay, let's design a smart contract that manages dynamic, evolving digital entities with interactive capabilities, incorporating concepts like on-chain state changes, resource management, pseudo-random outcomes, and administrative configuration. We will call this contract `OmniGenesisNexus`.

It represents unique digital beings or artifacts (Nexuses) that are born with initial attributes, can gather a simulated on-chain resource ("Essence"), use Essence for rituals or infusions to potentially change their attributes or state, engage in simulated challenges with other Nexuses, and evolve based on cumulative interactions and state. It also includes admin controls for tuning parameters and a mechanism for external entities ("Attuners") to potentially influence a Nexus for a fee.

**Disclaimer:** This is a complex example for demonstration purposes. On-chain pseudo-randomness is exploitable. Gas costs for complex state changes can be high. Thorough testing and security audits would be essential for a production deployment.

---

**Outline:**

1.  **Contract Name:** `OmniGenesisNexus`
2.  **Inheritance:** ERC721Enumerable, Ownable, Pausable
3.  **Core Concept:** Dynamic, evolving, interactive digital entities (Nexuses).
4.  **State:** Each Nexus has mutable attributes, state, essence, and interaction cooldowns.
5.  **Resources:** Simulated "Essence" resource gathered by Nexuses.
6.  **Interactions:**
    *   Gathering Essence (time-based).
    *   Infusing Essence (attempts attribute boost).
    *   Conducting Rituals (major state change potential).
    *   Challenging another Nexus (simulated combat/interaction).
    *   Attunement (external influence for a fee).
7.  **Evolution:** Nexuses evolve based on state, attributes, and actions.
8.  **Configuration:** Admin functions to set parameters for minting, interactions, and evolution.
9.  **Metadata:** Dynamic `tokenURI` reflecting current state (points to off-chain resolver).
10. **Access Control:** Owner for config, Nexus owner for most interactions, specific role for Attuners.

**Function Summary:**

1.  `constructor`: Initializes the contract, sets owner, sets initial parameters.
2.  `balanceOf(address owner) view returns (uint256)`: ERC721 standard - Returns number of tokens owned by an address.
3.  `ownerOf(uint256 tokenId) view returns (address)`: ERC721 standard - Returns the owner of a specific token.
4.  `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - Safe transfer of token ownership.
5.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard - Safe transfer with data.
6.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard - Transfer of token ownership.
7.  `approve(address to, uint256 tokenId)`: ERC721 standard - Approves an address to manage a token.
8.  `setApprovalForAll(address operator, bool approved)`: ERC721 standard - Approves or revokes approval for an operator for all tokens.
9.  `getApproved(uint256 tokenId) view returns (address)`: ERC721 standard - Returns the approved address for a token.
10. `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC721 standard - Returns if an operator is approved for all tokens of an owner.
11. `totalSupply() view returns (uint256)`: ERC721Enumerable standard - Returns total number of tokens.
12. `tokenByIndex(uint256 index) view returns (uint256)`: ERC721Enumerable standard - Returns token ID by index.
13. `tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)`: ERC721Enumerable standard - Returns token ID of owner by index.
14. `tokenURI(uint256 tokenId) view returns (string memory)`: ERC721 standard extension - Returns metadata URI (dynamic).
15. `mintGenesisNexus(bytes32 seed) payable`: Mints a new Nexus token. Requires mint fee. Initial attributes influenced by seed and contract parameters.
16. `getNexusAttributes(uint256 tokenId) view returns (NexusAttributes memory)`: Returns the current dynamic attributes of a Nexus.
17. `getNexusState(uint256 tokenId) view returns (NexusState)`: Returns the current state of a Nexus.
18. `getNexusEssence(uint256 tokenId) view returns (uint256)`: Returns the current Essence stored in a Nexus.
19. `getNexusCooldowns(uint256 tokenId) view returns (uint256 lastEssenceGather, uint256 lastChallengeTime)`: Returns cooldown timestamps for a Nexus.
20. `gatherEssence(uint256 tokenId)`: Allows the Nexus owner to gather simulated Essence based on time passed since last gather. Requires cooldown.
21. `infuseEssence(uint256 tokenId, uint256 essenceAmount)`: Allows the owner to spend Essence to attempt boosting a random attribute. Outcome is pseudo-random and depends on amount/state.
22. `conductRitual(uint256 tokenId)`: Allows the owner to perform a ritual requiring significant Essence and potentially triggering a major state change or evolution based on current state and attributes.
23. `challengeNexus(uint256 challengerTokenId, uint256 targetTokenId)`: Initiates a simulated challenge between two Nexuses (owned by sender and another address, potentially). Outcome affects both based on attributes and state. Requires cooldown.
24. `attuneWithNexus(uint256 tokenId) payable`: Allows an *approved attuner* to send Ether/fee to potentially influence a Nexus's future outcomes (e.g., slightly boost probabilities in rituals/challenges, or add a temporary modifier).
25. `evolveNexus(uint256 tokenId)`: Allows the owner to trigger an evolution check. Evolution occurs if specific conditions (state, attributes, actions completed) are met, changing state and attributes permanently.
26. `setMintParameters(uint256 price, uint256 maxSupply)`: Owner function to set mint fee and supply cap.
27. `setEssenceParameters(uint256 gatherCooldown, uint256 gatherRatePerSecond)`: Owner function to configure Essence gathering.
28. `setRitualParameters(uint256 essenceCost, uint256 successRateModifier)`: Owner function to configure Ritual costs and base success chance.
29. `setChallengeParameters(uint256 challengeCooldown, uint256 baseWinChance, uint256 essenceReward)`: Owner function to configure challenges.
30. `setAttunementParameters(uint255 fee, uint256 influenceDuration)`: Owner function to configure Attunement.
31. `addAllowedAttuner(address attuner)`: Owner function to whitelist an address for using `attuneWithNexus`.
32. `removeAllowedAttuner(address attuner)`: Owner function to remove an address from the attuner whitelist.
33. `setBaseURI(string memory baseURI)`: Owner function to set the base URI for metadata.
34. `withdrawFees()`: Owner function to withdraw collected Ether fees.
35. `pause()`: Owner function to pause contract interactions (uses Pausable).
36. `unpause()`: Owner function to unpause contract interactions (uses Pausable).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Use SafeMath if dealing with Solidity versions prior to 0.8.0 or for clarity with potentially large numbers. For 0.8+, overflow/underflow checked by default.

// Note on Randomness: On-chain randomness (using block.timestamp, block.difficulty, etc.) is predictable and exploitable.
// For any serious application requiring secure randomness, an oracle like Chainlink VRF should be used.
// This example uses simple block data for illustration only.

// Outline:
// 1. Contract Name: OmniGenesisNexus
// 2. Inheritance: ERC721Enumerable, Ownable, Pausable
// 3. Core Concept: Dynamic, evolving, interactive digital entities (Nexuses).
// 4. State: Each Nexus has mutable attributes, state, essence, and interaction cooldowns.
// 5. Resources: Simulated "Essence" resource gathered by Nexuses.
// 6. Interactions: Gather Essence, Infuse Essence, Conduct Rituals, Challenge another Nexus, Attunement (external).
// 7. Evolution: Nexuses evolve based on state, attributes, and actions.
// 8. Configuration: Admin functions to set parameters for minting, interactions, and evolution.
// 9. Metadata: Dynamic tokenURI reflecting current state (points to off-chain resolver).
// 10. Access Control: Owner for config, Nexus owner for most interactions, specific role for Attuners.

// Function Summary:
// 1. constructor: Initializes the contract, sets owner, sets initial parameters.
// 2-10. Standard ERC721 functions (balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll).
// 11-13. Standard ERC721Enumerable functions (totalSupply, tokenByIndex, tokenOfOwnerByIndex).
// 14. tokenURI(uint256 tokenId): Returns metadata URI (dynamic).
// 15. mintGenesisNexus(bytes32 seed): Mints a new Nexus token. Requires mint fee.
// 16. getNexusAttributes(uint256 tokenId): Returns the current dynamic attributes of a Nexus.
// 17. getNexusState(uint256 tokenId): Returns the current state of a Nexus.
// 18. getNexusEssence(uint256 tokenId): Returns the current Essence stored.
// 19. getNexusCooldowns(uint256 tokenId): Returns cooldown timestamps.
// 20. gatherEssence(uint256 tokenId): Owner gathers Essence based on time/cooldown.
// 21. infuseEssence(uint256 tokenId, uint256 essenceAmount): Owner spends Essence to attempt attribute boost.
// 22. conductRitual(uint256 tokenId): Owner performs ritual for major state change/evolution attempt.
// 23. challengeNexus(uint256 challengerTokenId, uint256 targetTokenId): Simulates challenge between two Nexuses.
// 24. attuneWithNexus(uint256 tokenId): Approved attuner pays fee to influence Nexus outcomes.
// 25. evolveNexus(uint256 tokenId): Owner triggers evolution check based on conditions.
// 26. setMintParameters(uint256 price, uint256 maxSupply): Admin sets mint fee and supply cap.
// 27. setEssenceParameters(uint256 gatherCooldown, uint256 gatherRatePerSecond): Admin sets Essence parameters.
// 28. setRitualParameters(uint256 essenceCost, uint256 successRateModifier): Admin sets Ritual parameters.
// 29. setChallengeParameters(uint256 challengeCooldown, uint256 baseWinChance, uint256 essenceReward): Admin sets Challenge parameters.
// 30. setAttunementParameters(uint256 fee, uint256 influenceDuration): Admin sets Attunement parameters.
// 31. addAllowedAttuner(address attuner): Admin whitelists attuner.
// 32. removeAllowedAttuner(address attuner): Admin removes attuner from whitelist.
// 33. setBaseURI(string memory baseURI): Admin sets metadata base URI.
// 34. withdrawFees(): Admin withdraws collected Ether fees.
// 35. pause(): Admin pauses contract.
// 36. unpause(): Admin unpauses contract.

contract OmniGenesisNexus is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Definitions ---
    enum NexusState {
        Seed,
        Growth,
        Mature,
        Dormant,
        Corrupted,
        Ascended,
        Unknown // Default state before minting
    }

    struct NexusAttributes {
        uint256 power;
        uint256 resilience;
        uint256 wisdom;
        uint256 essenceStored;
        uint256 lastEssenceGatherTime;
        uint256 lastChallengeTime;
        uint256 lastRitualTime;
        uint256 evolutionStage; // Starts at 0
        // Additive attribute modifiers from attunement, rituals, etc.
        uint256 temporaryAttunementBoostExpiry; // Unix timestamp
        uint256 temporaryAttunementBoostAmount;
        uint256 permanentModifierPower;
        uint256 permanentModifierResilience;
        uint256 permanentModifierWisdom;
    }

    mapping(uint256 => NexusAttributes) private _nexusAttributes;
    mapping(uint256 => NexusState) private _nexusState;
    mapping(uint256 => bytes32) private _nexusSeed; // Store seed for potential future use (e.g., deterministic attribute reveal)

    // --- Configuration Parameters ---
    uint256 public mintPrice;
    uint256 public maxSupply;
    string private _baseTokenURI;

    uint256 public essenceGatherCooldown; // Seconds
    uint256 public essenceGatherRatePerSecond; // Units per second

    uint256 public ritualEssenceCost;
    uint256 public ritualBaseSuccessRate; // Basis points (0-10000)

    uint256 public challengeCooldown; // Seconds
    uint256 public challengeBaseWinChance; // Basis points (0-10000)
    uint256 public challengeEssenceReward; // Reward for winner

    uint256 public attunementFee; // Fee in Ether
    uint256 public attunementInfluenceDuration; // Seconds

    mapping(address => bool) public allowedAttuners;

    // --- Events ---
    event NexusMinted(uint256 indexed tokenId, address indexed owner, bytes32 seed, NexusAttributes initialAttributes);
    event EssenceGathered(uint256 indexed tokenId, uint256 amount);
    event EssenceInfused(uint256 indexed tokenId, uint256 amountSpent, bool success, string boostedAttribute);
    event RitualConducted(uint256 indexed tokenId, bool success, NexusState newState, uint256 newEvolutionStage);
    event NexusChallenged(uint256 indexed challengerTokenId, uint256 indexed targetTokenId, uint256 winnerTokenId);
    event AttunedWithNexus(uint256 indexed tokenId, address indexed attuner, uint256 amountPaid, uint256 influenceDuration);
    event NexusEvolved(uint256 indexed tokenId, uint256 newEvolutionStage, NexusState newState);
    event AttributesModified(uint256 indexed tokenId, NexusAttributes newAttributes);
    event BaseURIUpdated(string newURI);
    event AllowedAttunerAdded(address indexed attuner);
    event AllowedAttunerRemoved(address indexed attuner);
    event FeesWithdrawn(address indexed recipient, uint256 amount);
    event MintParametersUpdated(uint256 newPrice, uint256 newMaxSupply);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        string memory __baseTokenURI,
        uint256 _essenceGatherCooldown,
        uint256 _essenceGatherRatePerSecond,
        uint256 _ritualEssenceCost,
        uint256 _ritualBaseSuccessRate,
        uint256 _challengeCooldown,
        uint256 _challengeBaseWinChance,
        uint256 _challengeEssenceReward,
        uint256 _attunementFee,
        uint256 _attunementInfluenceDuration
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        _baseTokenURI = __baseTokenURI;
        essenceGatherCooldown = _essenceGatherCooldown;
        essenceGatherRatePerSecond = _essenceGatherRatePerSecond;
        ritualEssenceCost = _ritualEssenceCost;
        ritualBaseSuccessRate = _ritualBaseSuccessRate;
        challengeCooldown = _challengeCooldown;
        challengeBaseWinChance = _challengeBaseWinChance;
        challengeEssenceReward = _challengeEssenceReward;
        attunementFee = _attunementFee;
        attunementInfluenceDuration = _attunementInfluenceDuration;
        _nexusState[0] = NexusState.Unknown; // Sentinel value for unminted tokenIds
    }

    // --- Standard ERC721/Enumerable Overrides ---
    // These are included in the function count as they are part of the contract interface.
    // 2. balanceOf
    // 3. ownerOf
    // 4. safeTransferFrom (address, address, uint256)
    // 5. safeTransferFrom (address, address, uint256, bytes)
    // 6. transferFrom
    // 7. approve
    // 8. setApprovalForAll
    // 9. getApproved
    // 10. isApprovedForAll
    // 11. totalSupply
    // 12. tokenByIndex
    // 13. tokenOfOwnerByIndex
    // All handled by inheritance from OpenZeppelin contracts.

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 14. tokenURI - Dynamic metadata reflecting state
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // The actual metadata JSON would be served off-chain by a service
        // that reads the state of the Nexus (attributes, state, evolutionStage)
        // from this contract and formats it.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    // --- Core Minting ---
    // 15. mintGenesisNexus
    function mintGenesisNexus(bytes32 seed) public payable whenNotPaused {
        uint256 newTokenId = _tokenIdCounter.current();
        require(newTokenId < maxSupply, "Nexus: Max supply reached");
        require(msg.value >= mintPrice, "Nexus: Insufficient mint price");

        _tokenIdCounter.increment();

        // Pseudo-random initial attributes based on seed and block data
        // WARNING: Highly insecure randomness for production.
        uint256 entropy = uint256(keccak256(abi.encodePacked(seed, block.timestamp, block.difficulty, msg.sender, newTokenId)));

        NexusAttributes memory initialAttributes;
        initialAttributes.power = (entropy % 100) + 1; // 1-100
        initialAttributes.resilience = ((entropy >> 8) % 100) + 1; // 1-100
        initialAttributes.wisdom = ((entropy >> 16) % 100) + 1; // 1-100
        initialAttributes.essenceStored = 0;
        initialAttributes.lastEssenceGatherTime = block.timestamp; // Start cooldown
        initialAttributes.lastChallengeTime = 0;
        initialAttributes.lastRitualTime = 0;
        initialAttributes.evolutionStage = 0;
        initialAttributes.temporaryAttunementBoostExpiry = 0;
        initialAttributes.temporaryAttunementBoostAmount = 0;
        initialAttributes.permanentModifierPower = 0;
        initialAttributes.permanentModifierResilience = 0;
        initialAttributes.permanentModifierWisdom = 0;

        _nexusAttributes[newTokenId] = initialAttributes;
        _nexusState[newTokenId] = NexusState.Seed;
        _nexusSeed[newTokenId] = seed;

        _safeMint(msg.sender, newTokenId);

        emit NexusMinted(newTokenId, msg.sender, seed, initialAttributes);
    }

    // --- Get State Functions ---
    // 16. getNexusAttributes
    function getNexusAttributes(uint256 tokenId) public view returns (NexusAttributes memory) {
        require(_exists(tokenId), "Nexus: Token does not exist");
        return _nexusAttributes[tokenId];
    }

    // 17. getNexusState
    function getNexusState(uint256 tokenId) public view returns (NexusState) {
        require(_exists(tokenId), "Nexus: Token does not exist");
        return _nexusState[tokenId];
    }

    // 18. getNexusEssence
    function getNexusEssence(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Nexus: Token does not exist");
        return _nexusAttributes[tokenId].essenceStored;
    }

     // 19. getNexusCooldowns
    function getNexusCooldowns(uint256 tokenId) public view returns (uint256 lastEssenceGather, uint256 lastChallengeTime) {
        require(_exists(tokenId), "Nexus: Token does not exist");
        NexusAttributes storage attrs = _nexusAttributes[tokenId];
        return (attrs.lastEssenceGatherTime, attrs.lastChallengeTime);
    }

    // --- Interactive Functions ---

    // Modifier to ensure only token owner or approved can call
    modifier onlyOwnerOrApproved(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Nexus: Not authorized to interact with this token");
        _;
    }

    // 20. gatherEssence
    function gatherEssence(uint256 tokenId) public whenNotPaused onlyOwnerOrApproved(tokenId) {
        NexusAttributes storage attrs = _nexusAttributes[tokenId];
        uint256 timePassed = block.timestamp - attrs.lastEssenceGatherTime;
        require(timePassed >= essenceGatherCooldown, "Nexus: Essence gathering on cooldown");

        uint256 amountGathered = (timePassed / essenceGatherCooldown) * (essenceGatherRatePerSecond * essenceGatherCooldown); // Calculate based on cooldown periods passed
         if (amountGathered == 0 && timePassed >= essenceGatherCooldown) {
             // Ensure at least one unit is gathered if cooldown is met, even if ratePerSecond is low
             amountGathered = essenceGatherRatePerSecond * essenceGatherCooldown;
         }
         if (amountGathered == 0 && essenceGatherRatePerSecond > 0) amountGathered = essenceGatherRatePerSecond; // Gather at least rate/sec if any time passed after cooldown

        require(amountGathered > 0, "Nexus: No essence to gather yet");

        attrs.essenceStored += amountGathered;
        attrs.lastEssenceGatherTime = block.timestamp; // Reset cooldown

        emit EssenceGathered(tokenId, amountGathered);
    }

    // 21. infuseEssence
    function infuseEssence(uint256 tokenId, uint256 essenceAmount) public whenNotPaused onlyOwnerOrApproved(tokenId) {
        NexusAttributes storage attrs = _nexusAttributes[tokenId];
        require(attrs.essenceStored >= essenceAmount, "Nexus: Not enough Essence");
        require(essenceAmount > 0, "Nexus: Cannot infuse zero Essence");

        attrs.essenceStored -= essenceAmount;

        // Pseudo-random outcome for attribute boost
        bytes32 randomnessSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, essenceAmount));
        uint256 outcome = uint256(randomnessSeed) % 10000; // Basis points (0-9999)
        uint256 successThreshold = essenceAmount; // Simple scaling: more essence, higher chance (cap? log scale?)
        if (successThreshold > 5000) successThreshold = 5000; // Cap success influence

        bool success = outcome < (ritualBaseSuccessRate + successThreshold); // Combine base rate and essence influence

        string memory boostedAttributeName = "None";

        if (success) {
            uint256 attributeChoice = uint256(keccak256(abi.encodePacked(randomnessSeed, "attribute"))) % 3; // 0: Power, 1: Resilience, 2: Wisdom
            uint256 boostAmount = (essenceAmount / 10) + 1; // Simple boost amount

            if (attributeChoice == 0) {
                attrs.power += boostAmount;
                boostedAttributeName = "Power";
            } else if (attributeChoice == 1) {
                attrs.resilience += boostAmount;
                 boostedAttributeName = "Resilience";
            } else {
                attrs.wisdom += boostAmount;
                 boostedAttributeName = "Wisdom";
            }
        }

        emit EssenceInfused(tokenId, essenceAmount, success, boostedAttributeName);
        emit AttributesModified(tokenId, attrs);
    }

    // 22. conductRitual
    function conductRitual(uint256 tokenId) public whenNotPaused onlyOwnerOrApproved(tokenId) {
        NexusAttributes storage attrs = _nexusAttributes[tokenId];
        require(attrs.essenceStored >= ritualEssenceCost, "Nexus: Not enough Essence for ritual");
        require(block.timestamp >= attrs.lastRitualTime + (ritualEssenceCost / 10), "Nexus: Rituals too frequent"); // Simple cooldown based on cost

        attrs.essenceStored -= ritualEssenceCost;
        attrs.lastRitualTime = block.timestamp;

        // Pseudo-random outcome for ritual success and effect
        bytes32 randomnessSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, "ritual"));
        uint256 outcome = uint256(randomnessSeed) % 10000; // Basis points (0-9999)

        // Ritual success chance can depend on Wisdom or State
        uint256 successChance = ritualBaseSuccessRate;
        if (_nexusState[tokenId] == NexusState.Growth) successChance += 500; // Bonus for Growth state
        if (_nexusState[tokenId] == NexusState.Mature) successChance += 1000; // Bonus for Mature state
        successChance += attrs.wisdom / 5; // Wisdom influence

        bool success = outcome < successChance;

        NexusState oldState = _nexusState[tokenId];
        NexusState newState = oldState;
        uint256 oldEvolutionStage = attrs.evolutionStage;
        uint256 newEvolutionStage = oldEvolutionStage;

        if (success) {
            // Determine effect based on current state
            if (oldState == NexusState.Seed) {
                newState = NexusState.Growth;
                newEvolutionStage = 1;
                 attrs.power += 10; // Base boost on state change
            } else if (oldState == NexusState.Growth) {
                 // Chance to become Mature or Dormant
                 if (uint256(keccak256(abi.encodePacked(randomnessSeed, "growthOutcome"))) % 10 < 8) { // 80% chance Mature
                     newState = NexusState.Mature;
                     newEvolutionStage = 2;
                     attrs.resilience += 10;
                 } else { // 20% chance Dormant
                     newState = NexusState.Dormant;
                      attrs.wisdom += 10; // Dormant focuses wisdom?
                 }
            } else if (oldState == NexusState.Mature) {
                 // Chance to become Ascended or Corrupted
                 if (uint256(keccak256(abi.encodePacked(randomnessSeed, "matureOutcome"))) % 10 < 7) { // 70% chance Ascended
                     newState = NexusState.Ascended;
                     newEvolutionStage = 3;
                     attrs.power += 20; attrs.resilience += 20; attrs.wisdom += 20; // Significant boost
                 } else { // 30% chance Corrupted
                     newState = NexusState.Corrupted;
                     attrs.power += 30; attrs.resilience -= 15; // High power, low resilience?
                      if (attrs.resilience > 15) attrs.resilience -= 15; else attrs.resilience = 1;
                 }
            } else {
                // Ritual in other states might just give attribute boosts or have other effects
                 uint256 attributeChoice = uint256(keccak256(abi.encodePacked(randomnessSeed, "attributeBoost"))) % 3;
                 uint256 boostAmount = ritualEssenceCost / 5;
                 if (attributeChoice == 0) attrs.power += boostAmount;
                 else if (attributeChoice == 1) attrs.resilience += boostAmount;
                 else attrs.wisdom += boostAmount;
                 newEvolutionStage = attrs.evolutionStage + 1; // Increment stage even if state doesn't change
            }
             attrs.evolutionStage = newEvolutionStage; // Update stage if it changed

        } else {
            // Ritual failed, maybe slight attribute decrease or status effect?
            uint256 penaltyAmount = ritualEssenceCost / 20;
             // Randomly penalize one attribute slightly
            uint256 attributeChoice = uint256(keccak256(abi.encodePacked(randomnessSeed, "penalty"))) % 3;
             if (attributeChoice == 0 && attrs.power > penaltyAmount) attrs.power -= penaltyAmount;
             else if (attributeChoice == 1 && attrs.resilience > penaltyAmount) attrs.resilience -= penaltyAmount;
             else if (attributeChoice == 2 && attrs.wisdom > penaltyAmount) attrs.wisdom -= penaltyAmount;
        }

        // Apply temporary attunement boost if active
        if (attrs.temporaryAttunementBoostExpiry > block.timestamp) {
             uint256 boost = attrs.temporaryAttunementBoostAmount;
             // Boost affects success chance or outcome values? Let's boost success chance.
             if (success) {
                 // If already successful, maybe boost the amount gained?
                 uint256 bonusBoost = boost / 10; // 10% of attunement amount
                 attrs.power += bonusBoost; attrs.resilience += bonusBoost; attrs.wisdom += bonusBoost;
             } else {
                 // If failed, attunement increases success chance for next ritual?
                 // Or reduces penalty? Let's say reduces penalty.
                 // Penalty logic is simple now, maybe just prevent state regression if we add that.
             }
             // Attunement boost is consumed by a major action like ritual or challenge
             attrs.temporaryAttunementBoostExpiry = 0;
             attrs.temporaryAttunementBoostAmount = 0; // Reset boost
        }


        if (newState != oldState) {
            _nexusState[tokenId] = newState;
        }

        emit RitualConducted(tokenId, success, newState, newEvolutionStage);
        emit AttributesModified(tokenId, attrs);
        if (newState != oldState || newEvolutionStage != oldEvolutionStage) {
             emit NexusEvolved(tokenId, newEvolutionStage, newState);
        }
    }

    // 23. challengeNexus
    function challengeNexus(uint256 challengerTokenId, uint256 targetTokenId) public whenNotPaused {
        require(_exists(challengerTokenId), "Nexus: Challenger token does not exist");
        require(_exists(targetTokenId), "Nexus: Target token does not exist");
        require(challengerTokenId != targetTokenId, "Nexus: Cannot challenge self");
        require(_isApprovedOrOwner(msg.sender, challengerTokenId), "Nexus: Not authorized to use challenger token");

        address targetOwner = ownerOf(targetTokenId);
        // Decide challenge rules: PvP? PvE? Let's make it PvP for simplicity here.
        require(targetOwner != address(0), "Nexus: Target token has no owner?"); // Should not happen with ERC721
        require(_isApprovedOrOwner(msg.sender, targetTokenId), "Nexus: Not authorized to challenge target token (must own or be approved for both)");

        NexusAttributes storage challengerAttrs = _nexusAttributes[challengerTokenId];
        NexusAttributes storage targetAttrs = _nexusAttributes[targetTokenId];

        require(block.timestamp >= challengerAttrs.lastChallengeTime + challengeCooldown, "Nexus: Challenger on cooldown");
        require(block.timestamp >= targetAttrs.lastChallengeTime + challengeCooldown, "Nexus: Target on cooldown");

        challengerAttrs.lastChallengeTime = block.timestamp;
        targetAttrs.lastChallengeTime = block.timestamp;

        // Simulate challenge outcome based on attributes
        // WARNING: Insecure randomness
        bytes32 randomnessSeed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, challengerTokenId, targetTokenId));
        uint256 outcome = uint256(randomnessSeed) % 10000; // Basis points

        uint256 challengerScore = challengerAttrs.power + challengerAttrs.wisdom + challengerAttrs.permanentModifierPower + challengerAttrs.permanentModifierWisdom;
        uint256 targetScore = targetAttrs.resilience + targetAttrs.wisdom + targetAttrs.permanentModifierResilience + targetAttrs.permanentModifierWisdom;

        // Apply temporary attunement boost if active
        if (challengerAttrs.temporaryAttunementBoostExpiry > block.timestamp) {
            challengerScore += challengerAttrs.temporaryAttunementBoostAmount / 2; // Half boost amount adds to score
            // Boost is consumed
            challengerAttrs.temporaryAttunementBoostExpiry = 0;
            challengerAttrs.temporaryAttunementBoostAmount = 0;
             emit AttributesModified(challengerTokenId, challengerAttrs);
        }
         if (targetAttrs.temporaryAttunementBoostExpiry > block.timestamp) {
            targetScore += targetAttrs.temporaryAttunementBoostAmount / 2;
             // Boost is consumed
             targetAttrs.temporaryAttunementBoostExpiry = 0;
            targetAttrs.temporaryAttunementBoostAmount = 0;
             emit AttributesModified(targetTokenId, targetAttrs);
         }


        // Win chance calculation: Base chance + relative score
        uint256 challengerWinChance = challengeBaseWinChance;
        if (challengerScore > targetScore) {
            uint256 scoreDiff = challengerScore - targetScore;
             challengerWinChance += (scoreDiff / 10); // +1% chance per 10 score difference
        } else if (targetScore > challengerScore) {
             uint256 scoreDiff = targetScore - challengerScore;
            if (challengerWinChance > (scoreDiff / 10)) { // Prevent underflow
                challengerWinChance -= (scoreDiff / 10);
            } else {
                challengerWinChance = 0; // Minimum 0 chance
            }
        }
        // Cap win chance
        if (challengerWinChance > 9500) challengerWinChance = 9500; // Max 95%

        uint256 winnerTokenId;
        if (outcome < challengerWinChance) {
            winnerTokenId = challengerTokenId;
            // Winner gets Essence reward
            challengerAttrs.essenceStored += challengeEssenceReward;
            // Loser might lose a small amount of Essence or attributes?
            if (targetAttrs.essenceStored > challengeEssenceReward / 2) targetAttrs.essenceStored -= challengeEssenceReward / 2; else targetAttrs.essenceStored = 0;

        } else {
            winnerTokenId = targetTokenId;
             // Winner gets Essence reward
            targetAttrs.essenceStored += challengeEssenceReward;
             // Loser penalty
             if (challengerAttrs.essenceStored > challengeEssenceReward / 2) challengerAttrs.essenceStored -= challengeEssenceReward / 2; else challengerAttrs.essenceStored = 0;
        }

        emit NexusChallenged(challengerTokenId, targetTokenId, winnerTokenId);
        emit AttributesModified(challengerTokenId, challengerAttrs);
        emit AttributesModified(targetTokenId, targetAttrs);
    }

    // 24. attuneWithNexus
    function attuneWithNexus(uint256 tokenId) public payable whenNotPaused {
        require(_exists(tokenId), "Nexus: Token does not exist");
        require(allowedAttuners[msg.sender], "Nexus: Sender is not an allowed attuner");
        require(msg.value >= attunementFee, "Nexus: Insufficient attunement fee");

        // Ether is sent to the contract. It can be withdrawn by the owner.
        // The amount paid influences the boost duration/strength
        uint256 actualInfluenceDuration = attunementInfluenceDuration;
        uint256 influenceAmount = msg.value / attunementFee; // How many 'units' of influence based on fee paid

        NexusAttributes storage attrs = _nexusAttributes[tokenId];

        // Apply the influence. If an old boost is active, the new one replaces or adds? Let's replace.
        // The boost amount could scale with msg.value
        attrs.temporaryAttunementBoostExpiry = block.timestamp + actualInfluenceDuration;
        attrs.temporaryAttunementBoostAmount = influenceAmount * 100; // Simple scaling, 100 per influence unit

        emit AttunedWithNexus(tokenId, msg.sender, msg.value, actualInfluenceDuration);
        emit AttributesModified(tokenId, attrs); // Attributes struct includes boost info
    }

    // 25. evolveNexus
     function evolveNexus(uint256 tokenId) public whenNotPaused onlyOwnerOrApproved(tokenId) {
        NexusAttributes storage attrs = _nexusAttributes[tokenId];
        NexusState currentState = _nexusState[tokenId];

        // Evolution conditions are based on current state, evolution stage, attributes, and cumulative actions (e.g., Essence gathered total? Rituals completed total?)
        // This requires tracking more cumulative data or making conditions simpler.
        // Let's make conditions based on state, stage, and attribute thresholds for this example.

        uint256 oldEvolutionStage = attrs.evolutionStage;
        NexusState oldState = currentState;
        bool evolved = false;

        if (currentState == NexusState.Seed && attrs.evolutionStage == 0 && attrs.essenceStored >= 100 && (attrs.power >= 20 || attrs.resilience >= 20 || attrs.wisdom >= 20)) {
            _nexusState[tokenId] = NexusState.Growth;
            attrs.evolutionStage = 1;
             attrs.power += 5; attrs.resilience += 5; attrs.wisdom += 5; // Small stat boost on evo
            evolved = true;
        } else if (currentState == NexusState.Growth && attrs.evolutionStage == 1 && attrs.essenceStored >= 300 && (attrs.power >= 50 || attrs.resilience >= 50 || attrs.wisdom >= 50) && attrs.lastRitualTime > 0) {
             // Requires a ritual was performed
            if (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenId, "evo2"))) % 10 < 8) { // 80% chance to go to Mature
                 _nexusState[tokenId] = NexusState.Mature;
                 attrs.evolutionStage = 2;
                 attrs.power += 10; attrs.resilience += 10; attrs.wisdom += 10;
             } else { // 20% chance to go to Dormant
                 _nexusState[tokenId] = NexusState.Dormant;
                 // Evolution stage might not change or get a special stage number
                 attrs.power += 5; attrs.resilience += 5; attrs.wisdom += 15; // Wisdom focus
             }
            evolved = true;
        }
         // Add more evolution paths based on states (Mature -> Ascended/Corrupted, Dormant -> ?)
         // Add conditions for higher stages...

        if (evolved) {
            emit NexusEvolved(tokenId, attrs.evolutionStage, _nexusState[tokenId]);
            emit AttributesModified(tokenId, attrs);
        } else {
            // Maybe a slight penalty or just a log that evolution check failed?
            // For now, just require doesn't block other actions.
            // Consider adding a specific event for failed evolution checks.
            // require(false, "Nexus: Evolution conditions not met"); // Or handle failure state
        }
         require(evolved, "Nexus: Evolution conditions not met for current state and stage");

    }


    // --- Admin Configuration Functions ---
    // All onlyOwner and whenPaused/whenNotPaused as appropriate

    // 26. setMintParameters
    function setMintParameters(uint256 price, uint256 maxCap) public onlyOwner {
        mintPrice = price;
        maxSupply = maxCap;
        emit MintParametersUpdated(price, maxCap);
    }

    // 27. setEssenceParameters
    function setEssenceParameters(uint256 gatherCD, uint256 gatherRate) public onlyOwner {
        essenceGatherCooldown = gatherCD;
        essenceGatherRatePerSecond = gatherRate;
    }

    // 28. setRitualParameters
    function setRitualParameters(uint256 essenceCost, uint256 successRateBP) public onlyOwner {
        ritualEssenceCost = essenceCost;
        ritualBaseSuccessRate = successRateBP; // Basis points (0-10000)
    }

    // 29. setChallengeParameters
    function setChallengeParameters(uint256 challengeCD, uint256 baseWinChanceBP, uint256 essenceReward) public onlyOwner {
        challengeCooldown = challengeCD;
        challengeBaseWinChance = baseWinChanceBP; // Basis points (0-10000)
        challengeEssenceReward = essenceReward;
    }

    // 30. setAttunementParameters
    function setAttunementParameters(uint256 fee, uint256 influenceDuration) public onlyOwner {
        attunementFee = fee;
        attunementInfluenceDuration = influenceDuration;
    }

    // 31. addAllowedAttuner
    function addAllowedAttuner(address attuner) public onlyOwner {
        require(attuner != address(0), "Nexus: Cannot add zero address");
        allowedAttuners[attuner] = true;
        emit AllowedAttunerAdded(attuner);
    }

    // 32. removeAllowedAttuner
    function removeAllowedAttuner(address attuner) public onlyOwner {
         require(attuner != address(0), "Nexus: Cannot remove zero address");
        allowedAttuners[attuner] = false;
        emit AllowedAttunerRemoved(attuner);
    }

    // 33. setBaseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
        emit BaseURIUpdated(baseURI);
    }

    // 34. withdrawFees
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nexus: No fees to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Nexus: Fee withdrawal failed");
        emit FeesWithdrawn(owner(), balance);
    }

    // 35. pause
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    // 36. unpause
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Internal/Helper Functions (Not counted in the 20+ function requirement as they are not part of the external API) ---

    // _beforeTokenTransfer is automatically called by ERC721 transfers
    // Can add logic here, e.g., check if transferable based on state, reset temporary effects on transfer, etc.
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //      // Example: Reset temporary boost on transfer
    //     if (_nexusAttributes[tokenId].temporaryAttunementBoostExpiry > block.timestamp) {
    //         _nexusAttributes[tokenId].temporaryAttunementBoostExpiry = 0;
    //         _nexusAttributes[tokenId].temporaryAttunementBoostAmount = 0;
    //          emit AttributesModified(tokenId, _nexusAttributes[tokenId]);
    //     }
    // }

    // Example of adding an internal helper for randomness (still insecure)
    // function _generateRandomness(uint256 seedInput) internal view returns (uint256) {
    //     return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seedInput, block.number)));
    // }

    // The `_isApprovedOrOwner` used in the onlyOwnerOrApproved modifier is inherited from ERC721.

}
```