This smart contract, "Aetherial Genesis Protocol (AGP)," introduces a novel concept of **Dynamic SoulBound Tokens (SBTs)** that evolve and gain "Aetheric Power" based on owner interaction, on-chain activities, and collective community decisions. Unlike traditional NFTs, these "Digital Souls" are non-transferable (with specific exceptions for advanced mechanics) and embody a unique blend of reputation, utility, and autonomous growth within a decentralized ecosystem.

---

### **Aetherial Genesis Protocol (AGP) - Evolvable Digital Souls**

**Core Concept:**
AGP creates "Digital Souls" as dynamic SoulBound Tokens (SBTs). These Souls evolve, gain unique traits, and increase "Aetheric Power" based on owner interaction, on-chain activities, and collective community decisions. They embody a unique blend of reputation, utility, and autonomous growth within a decentralized ecosystem.

**Key Innovations:**
1.  **Dynamic SBTs:** Souls are non-transferable by default (ERC-4973 like), but evolve through on-chain actions, modifying their inherent properties and metadata.
2.  **Reputational Traits:** Specific traits (e.g., `SocialAffinity`, `Intellect`, `Adaptability`) are dynamically assigned or improved based on the owner's active participation or the soul's interactions.
3.  **Resonance Bonding:** Souls can "resonate" (lock) with other souls, fostering collaboration by potentially unlocking synergistic traits, shared Aetheric Power, or collective benefits.
4.  **Essence Delegation:** Owners can delegate a portion of their soul's Aetheric Power (AP) for specific, permissioned uses to another address without transferring ownership of the Soul itself. This enables proxy participation or feature unlocking.
5.  **Autonomous Evolution Triggers:** Souls can internally trigger evolution or trait changes based on elapsed time, cumulative interactions, or reaching specific Aetheric Power thresholds.
6.  **Decentralized Transmutation:** A unique mechanism to "transmute" (burn) multiple souls, yielding new components (e.g., "Aetheric Fragments") or transforming existing souls, creating a dynamic resource economy.
7.  **Adaptive Genesis:** Initial soul creation has a dynamic minting price and can be influenced by network conditions or global Aetheric Power levels, encouraging strategic entry.
8.  **On-chain History & Proof-of-Behavior:** Each soul maintains a concise, on-chain record of significant evolutionary events and milestone achievements.

---

### **Contract Outline:**

1.  **Imports & Interfaces:** OpenZeppelin ERC721, Context, Ownable.
2.  **Custom Errors & Events:** Clear, gas-efficient error messages and comprehensive event logging.
3.  **Enums & Structs:**
    *   `SoulTraitType`: Defines various quantifiable traits.
    *   `EvolutionEventType`: Categorizes historical events.
    *   `Soul`: Main data structure for each Digital Soul, including its traits, power, and history.
    *   `ResonancePair`: Stores details of active Resonance bonds.
    *   `EssenceDelegation`: Details for delegated Aetheric Power.
    *   `Proposal`: Structure for on-chain governance proposals.
4.  **State Variables:** Mappings to store souls, active resonances, delegations, governance data, and various counters.
5.  **Constructor:** Initializes the contract, sets initial parameters, and defines the base metadata URI.
6.  **Core ERC721 & SBT Functions:** Standard ERC721 functionalities, with an override for `_transfer` to enforce the SoulBound nature.
7.  **Soul Management & Query Functions:** Functions to retrieve detailed soul data, calculate Aetheric Power, and access historical events.
8.  **Evolution & Interaction Mechanics:** Functions enabling soul creation, bonding (Resonance), burning (Transmutation), and external influence (Catalyst).
9.  **Delegation Functions:** Managing the delegation and consumption of a Soul's "Essence" (Aetheric Power).
10. **Governance Functions:** A simplified on-chain voting mechanism for protocol evolution.
11. **Internal Helper Functions:** Private functions for common calculations, trait updates, and state management.

---

### **Function Summary (24 Functions):**

1.  **`constructor(string memory baseURI_ `**: Initializes contract settings, including the base URI for soul metadata.
2.  **`supportsInterface(bytes4 interfaceId)`**: Standard ERC721 and potential ERC-4973 (SBT) interface support.
3.  **`ownerOf(uint256 tokenId)`**: Returns the current owner of a specific Soul.
4.  **`balanceOf(address owner)`**: Returns the total number of Souls owned by an address.
5.  **`tokenURI(uint256 tokenId)`**: Dynamically generates the JSON metadata URI for a Soul, reflecting its current evolving state and traits.
6.  **`_transfer(address from, address to, uint256 tokenId)`**: **(Internal Override)** Enforces the SoulBound nature; reverts transfers unless explicit dissolution/replication logic is triggered.
7.  **`initiateGenesis(address recipient)`**: Mints a new Digital Soul for the specified recipient, assigning initial randomized traits and consuming ETH as a dynamic minting fee.
8.  **`getSoulData(uint256 tokenId)`**: Retrieves a comprehensive snapshot of a Soul's current state, including its owner, genesis time, and all traits.
9.  **`getAethericPower(uint256 tokenId)`**: Calculates and returns the current Aetheric Power of a Soul based on its unique combination of traits and accumulated evolution events.
10. **`performResonance(uint256 tokenIdA, uint256 tokenIdB)`**: Initiates a "Resonance" bond between two Souls, provided they meet specific criteria, potentially unlocking shared benefits or new traits.
11. **`dissolveResonance(uint256 tokenId)`**: Breaks an active Resonance bond involving the specified Soul, with potential consequences for both participating Souls (e.g., cooldowns, temporary trait debuffs).
12. **`transmuteSouls(uint256[] calldata tokenIdsToBurn, uint256 targetSoulId)`**: Allows burning multiple Souls to "transmute" their essence into boosting the traits or Aetheric Power of a designated `targetSoulId`.
13. **`injectCatalyst(uint256 tokenId)`**: Allows depositing ETH to a Soul as "Catalyst," accelerating its evolution, gaining specific traits, or providing a temporary Aetheric Power boost.
14. **`triggerEvolution(uint256 tokenId)`**: Publicly callable function that triggers a Soul's evolution check, applying any accumulated changes (e.g., time-based decay/growth of traits, reaction to catalyst).
15. **`delegateEssence(uint256 tokenId, address delegatee, uint256 percentage)`**: Allows a Soul owner to delegate a specific percentage of their Soul's Aetheric Power to another address for a defined duration.
16. **`revokeEssenceDelegation(uint256 tokenId, address delegatee)`**: Revokes a previously granted essence delegation, terminating the delegatee's access to the Soul's power.
17. **`consumeDelegatedEssence(uint256 tokenId, address delegatee, uint256 amount)`**: An example function (intended for external contracts to call) demonstrating how a delegatee can consume a portion of the delegated essence for a permissioned action (e.g., voting in an external DAO, accessing a privileged feature).
18. **`proposeTraitAddition(string calldata traitName, uint256 initialValue, uint256 proposalDuration)`**: Allows a Soul owner (with sufficient Aetheric Power) to propose adding a new universal trait type or modifying core evolution rules for all Souls.
19. **`voteOnProposal(uint256 proposalId, bool support)`**: Allows Soul owners to vote on active proposals, with their vote weight dynamically scaled by their Soul's current Aetheric Power.
20. **`executeProposal(uint256 proposalId)`**: Executes a successfully voted-on proposal, enacting the proposed changes to the protocol's parameters or available traits.
21. **`getSoulHistory(uint256 tokenId)`**: Retrieves the chronological record of significant evolutionary events and milestones for a given Soul.
22. **`updateBaseURI(string calldata newBaseURI)`**: (Owner-only) Allows the contract owner to update the base URI from which Soul metadata JSONs are served.
23. **`calculateDynamicMintPrice()`**: Pure function to calculate the current dynamic price required to `initiateGenesis`, potentially based on total minted souls or a global Aetheric Power index.
24. **`setGovernanceParameters(uint256 minAPForProposal_, uint256 quorumPercentage_, uint256 votingDuration_)`**: (Owner-only) Allows adjusting the parameters for the on-chain governance system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Aetherial Genesis Protocol (AGP) - Evolvable Digital Souls
 * @dev This contract creates dynamic, non-transferable (SoulBound) NFTs called "Digital Souls".
 *      Souls evolve based on owner interaction, on-chain activities, and community governance.
 *      They possess "Aetheric Power" derived from unique traits, which dictates utility and influence.
 */
contract AetherialGenesisProtocol is ERC721, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;

    // --- Custom Errors ---
    error InvalidSoulId();
    error NotSoulOwner();
    error SoulAlreadyResonating();
    error SoulsAreSame();
    error ResonanceNotActive();
    error NotEnoughAethericPower();
    error InvalidPercentage();
    error DelegationNotFound();
    error DelegationExpired();
    error ProposalNotFound();
    error ProposalAlreadyVoted();
    error ProposalNotActive();
    error ProposalAlreadyExecuted();
    error ProposalQuorumNotMet();
    error ProposalVoteFailed();
    error NotEnoughSoulsForTransmutation();
    error TargetSoulCannotBeBurned();
    error MinimumMintPriceNotMet();
    error SoulBoundTokenCannotTransfer();


    // --- Enums ---
    enum SoulTraitType {
        Intellect,       // Affects governance weight, complex evolution calculations
        Adaptability,    // Influences resistance to negative events, speed of change
        ResonanceAffinity, // Boosts benefits from Resonance, likelihood of successful bonding
        SocialAffinity,  // Improves rewards from participation in collective events
        EntropyResistance // Reduces natural decay of traits over time
    }

    enum EvolutionEventType {
        Genesis,
        ResonanceInitiated,
        ResonanceDissolved,
        Transmuted,
        CatalystInjected,
        TraitEvolved,
        DelegationGranted,
        DelegationRevoked
    }

    // --- Structs ---
    struct Soul {
        uint256 id;
        address owner;
        uint256 genesisTime;
        mapping(SoulTraitType => uint256) traits; // Value from 0 to 100
        uint256 lastEvolutionCheck;
        uint256 accumulatedCatalystEth; // ETH amount
        EvolutionEvent[] history;
    }

    struct EvolutionEvent {
        EvolutionEventType eventType;
        uint256 timestamp;
        string description;
    }

    struct ResonancePair {
        uint256 soulId1;
        uint256 soulId2;
        uint256 startTime;
        uint256 duration; // 0 for indefinite
        uint256 sharedAPMultiplier; // e.g., 100 for 1x, 150 for 1.5x
    }

    struct EssenceDelegation {
        uint256 percentage; // e.g., 50 for 50%
        uint256 startTime;
        uint256 duration; // 0 for indefinite, max uint256 for effectively permanent
    }

    struct Proposal {
        uint256 id;
        string description;
        bool executed;
        bool passed;
        uint256 startTime;
        uint256 votingDuration;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks unique voters by soul owner
        uint256 totalAethericPowerAtStart; // For quorum calculation
        bytes data; // Encoded function call for execution (e.g., updateGovernanceParams)
    }

    // --- State Variables ---
    uint256 private _nextTokenId;
    string private _baseTokenURI;

    mapping(uint256 => Soul) public souls;
    mapping(uint256 => ResonancePair) public activeResonances; // soulId => ResonancePair
    mapping(uint256 => mapping(address => EssenceDelegation)) public soulEssenceDelegations; // soulId => delegatee => delegation

    // Governance
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    uint256 public minAPForProposal;      // Minimum Aetheric Power required to create a proposal
    uint256 public quorumPercentage;      // Percentage of total AP needed for a proposal to pass (e.g., 5000 for 50%)
    uint256 public votingDuration;        // Default duration for voting periods in seconds

    uint256 public constant MIN_MINT_PRICE = 0.01 ether; // Minimum ETH for genesis
    uint256 public constant BASE_AP_CALC_DIVISOR = 1000; // Divisor for AP calculation
    uint256 public constant EVOLUTION_COOLDOWN = 1 hours; // Cooldown for manual evolution trigger
    uint256 public constant RESONANCE_COOLDOWN = 1 days; // Cooldown after dissolving resonance for same soul to re-resonate

    // --- Events ---
    event GenesisInitiated(uint256 indexed tokenId, address indexed owner, uint256 genesisTime, uint256 mintPrice);
    event SoulTraitUpdated(uint256 indexed tokenId, SoulTraitType traitType, uint256 oldValue, uint256 newValue);
    event AethericPowerCalculated(uint256 indexed tokenId, uint256 aethericPower);
    event ResonanceStarted(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 startTime);
    event ResonanceEnded(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 endTime);
    event SoulsTransmuted(uint256[] indexed burnedTokenIds, uint256 indexed targetSoulId, uint256 timestamp);
    event CatalystInjectedEvent(uint256 indexed tokenId, address indexed injector, uint256 amount);
    event SoulEvolutionTriggered(uint256 indexed tokenId, uint256 timestamp);
    event EssenceDelegated(uint256 indexed tokenId, address indexed delegatee, uint256 percentage, uint256 duration);
    event EssenceRevoked(uint256 indexed tokenId, address indexed delegatee);
    event EssenceConsumed(uint256 indexed tokenId, address indexed delegatee, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description, uint256 startTime, uint256 votingDuration);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bool passed);
    event BaseURIUpdated(string newBaseURI);
    event GovernanceParametersUpdated(uint256 minAPForProposal, uint256 quorumPercentage, uint256 votingDuration);

    // --- Constructor ---
    constructor(string memory baseURI_) ERC721("Aetherial Soul", "AGS") Ownable(msg.sender) {
        _baseTokenURI = baseURI_;
        _nextTokenId = 1; // Start token IDs from 1

        // Default governance parameters
        minAPForProposal = 500; // 500 AP required to propose
        quorumPercentage = 5000; // 50% quorum
        votingDuration = 3 days; // 3 days for voting
    }

    // --- Core ERC721 & SBT Functions ---

    /**
     * @dev See {IERC721-supportsInterface}.
     *      Overrides to also support ERC-4973 like SoulBound Tokens.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // ERC-4973 interface ID for SoulBound Tokens
        bytes4 ERC4973_INTERFACE_ID = 0x8674d9e5;
        return interfaceId == type(IERC721).interfaceId || interfaceId == ERC4973_INTERFACE_ID || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the base URI for the Souls.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     *      Dynamically generates a URI for each Soul, reflecting its current state.
     *      In a production environment, this would likely point to an IPFS gateway
     *      that serves dynamically generated JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidSoulId();
        // In a real dApp, this would trigger an off-chain service or a more complex on-chain URI generation.
        // For demonstration, it points to a baseURI + token ID.
        // The off-chain service would then query getSoulData to construct the JSON.
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), ".json"));
    }

    /**
     * @dev Overrides ERC721's _transfer to make tokens non-transferable (SoulBound).
     *      Only allows transfers in very specific, internal, and controlled scenarios if implemented.
     */
    function _transfer(address from, address to, uint256 tokenId) internal override {
        // Revert all direct transfers, enforcing SoulBound nature.
        // Specific 'dissolution' or 'replication' functions could be added to bypass this,
        // but they would involve burning the original and minting a new one, or complex mechanics.
        if (from != address(0) && to != address(0)) { // Allow minting/burning
            revert SoulBoundTokenCannotTransfer();
        }
        super._transfer(from, to, tokenId);
    }

    // --- Soul Management & Query Functions ---

    /**
     * @dev Mints a new Digital Soul, assigning initial traits and charging a dynamic fee.
     * @param recipient The address to mint the Soul to.
     */
    function initiateGenesis(address recipient) public payable returns (uint256) {
        uint256 currentMintPrice = calculateDynamicMintPrice();
        if (msg.value < currentMintPrice) revert MinimumMintPriceNotMet();

        uint256 newSoulId = _nextTokenId;
        _nextTokenId++;

        _safeMint(recipient, newSoulId);

        Soul storage newSoul = souls[newSoulId];
        newSoul.id = newSoulId;
        newSoul.owner = recipient;
        newSoul.genesisTime = block.timestamp;
        newSoul.lastEvolutionCheck = block.timestamp;

        // Initialize traits with pseudo-randomness based on block data and ID
        uint256 initialSeed = uint256(keccak256(abi.encodePacked(block.timestamp, newSoulId, msg.sender, block.difficulty)));
        newSoul.traits[SoulTraitType.Intellect] = (initialSeed % 50) + 1; // 1-50
        newSoul.traits[SoulTraitType.Adaptability] = ((initialSeed / 100) % 50) + 1; // 1-50
        newSoul.traits[SoulTraitType.ResonanceAffinity] = ((initialSeed / 10000) % 50) + 1; // 1-50
        newSoul.traits[SoulTraitType.SocialAffinity] = ((initialSeed / 1000000) % 50) + 1; // 1-50
        newSoul.traits[SoulTraitType.EntropyResistance] = ((initialSeed / 100000000) % 50) + 1; // 1-50

        _addEvolutionEvent(newSoulId, EvolutionEventType.Genesis, "Soul created.");

        emit GenesisInitiated(newSoulId, recipient, newSoul.genesisTime, currentMintPrice);
        return newSoulId;
    }

    /**
     * @dev Retrieves a comprehensive snapshot of a Soul's current state.
     * @param tokenId The ID of the Soul.
     * @return A tuple containing soul properties.
     */
    function getSoulData(uint256 tokenId) public view returns (
        uint256 id,
        address owner,
        uint256 genesisTime,
        uint256 intellect,
        uint256 adaptability,
        uint256 resonanceAffinity,
        uint256 socialAffinity,
        uint256 entropyResistance,
        uint256 lastEvolutionCheck,
        uint256 accumulatedCatalystEth,
        uint256 aethericPower
    ) {
        if (!_exists(tokenId)) revert InvalidSoulId();
        Soul storage s = souls[tokenId];
        id = s.id;
        owner = s.owner;
        genesisTime = s.genesisTime;
        intellect = s.traits[SoulTraitType.Intellect];
        adaptability = s.traits[SoulTraitType.Adaptability];
        resonanceAffinity = s.traits[SoulTraitType.ResonanceAffinity];
        socialAffinity = s.traits[SoulTraitType.SocialAffinity];
        entropyResistance = s.traits[SoulTraitType.EntropyResistance];
        lastEvolutionCheck = s.lastEvolutionCheck;
        accumulatedCatalystEth = s.accumulatedCatalystEth;
        aethericPower = getAethericPower(tokenId);
    }

    /**
     * @dev Calculates and returns the current Aetheric Power of a Soul.
     *      AP is derived from a combination of its traits and accumulated catalyst.
     * @param tokenId The ID of the Soul.
     * @return The calculated Aetheric Power.
     */
    function getAethericPower(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert InvalidSoulId();
        Soul storage s = souls[tokenId];

        uint256 basePower = s.traits[SoulTraitType.Intellect]
            .add(s.traits[SoulTraitType.Adaptability])
            .add(s.traits[SoulTraitType.ResonanceAffinity])
            .add(s.traits[SoulTraitType.SocialAffinity])
            .add(s.traits[SoulTraitType.EntropyResistance]);

        // Add power from catalyst (e.g., 1 ETH = 100 AP)
        uint256 catalystPower = s.accumulatedCatalystEth.div(1e16); // 0.01 ETH per AP

        // Resonance bonus (if active)
        uint256 resonanceBonus = 0;
        if (activeResonances[tokenId].soulId1 == tokenId || activeResonances[tokenId].soulId2 == tokenId) {
            ResonancePair storage r = activeResonances[tokenId];
            if (r.duration == 0 || block.timestamp < r.startTime.add(r.duration)) {
                 resonanceBonus = basePower.mul(r.sharedAPMultiplier).div(100); // 100 = 1x
            }
        }
        
        uint256 totalAP = basePower.add(catalystPower).add(resonanceBonus);
        emit AethericPowerCalculated(tokenId, totalAP);
        return totalAP;
    }

    // --- Evolution & Interaction Mechanics ---

    /**
     * @dev Initiates a "Resonance" bond between two Souls.
     *      Requires ownership of both Souls by the caller.
     *      Resonance can unlock shared traits or AP bonuses.
     * @param tokenIdA The ID of the first Soul.
     * @param tokenIdB The ID of the second Soul.
     */
    function performResonance(uint256 tokenIdA, uint256 tokenIdB) public {
        if (msg.sender != ownerOf(tokenIdA) || msg.sender != ownerOf(tokenIdB)) revert NotSoulOwner();
        if (tokenIdA == tokenIdB) revert SoulsAreSame();
        if (activeResonances[tokenIdA].soulId1 != 0 || activeResonances[tokenIdB].soulId1 != 0) revert SoulAlreadyResonating();

        // Check for cooldown on recently dissolved souls
        // This would require storing last dissolved time per soul, omitted for brevity.

        activeResonances[tokenIdA] = ResonancePair(tokenIdA, tokenIdB, block.timestamp, 7 days, 120); // 7 days, 1.2x AP
        activeResonances[tokenIdB] = activeResonances[tokenIdA]; // Link both entries

        _addEvolutionEvent(tokenIdA, EvolutionEventType.ResonanceInitiated, string(abi.encodePacked("Resonating with Soul #", tokenIdB.toString())));
        _addEvolutionEvent(tokenIdB, EvolutionEventType.ResonanceInitiated, string(abi.encodePacked("Resonating with Soul #", tokenIdA.toString())));

        emit ResonanceStarted(tokenIdA, tokenIdB, block.timestamp);
    }

    /**
     * @dev Dissolves an active Resonance bond for a given Soul.
     * @param tokenId The ID of the Soul involved in the Resonance.
     */
    function dissolveResonance(uint256 tokenId) public {
        if (msg.sender != ownerOf(tokenId)) revert NotSoulOwner();
        if (activeResonances[tokenId].soulId1 == 0) revert ResonanceNotActive();

        uint256 partnerId = (activeResonances[tokenId].soulId1 == tokenId) ? activeResonances[tokenId].soulId2 : activeResonances[tokenId].soulId1;

        delete activeResonances[tokenId];
        delete activeResonances[partnerId]; // Ensure partner's entry is also cleared

        _addEvolutionEvent(tokenId, EvolutionEventType.ResonanceDissolved, string(abi.encodePacked("Resonance dissolved with Soul #", partnerId.toString())));
        _addEvolutionEvent(partnerId, EvolutionEventType.ResonanceDissolved, string(abi.encodePacked("Resonance dissolved with Soul #", tokenId.toString())));

        emit ResonanceEnded(tokenId, partnerId, block.timestamp);
    }

    /**
     * @dev Burns multiple Souls to "transmute" their essence into boosting a target Soul's traits.
     *      This acts as a "sacrifice" mechanic for stronger evolution.
     * @param tokenIdsToBurn An array of Soul IDs to be burned.
     * @param targetSoulId The ID of the Soul to be enhanced.
     */
    function transmuteSouls(uint256[] calldata tokenIdsToBurn, uint256 targetSoulId) public {
        if (tokenIdsToBurn.length < 1) revert NotEnoughSoulsForTransmutation();
        if (msg.sender != ownerOf(targetSoulId)) revert NotSoulOwner();
        
        // Ensure the target soul is not among those to be burned
        for (uint256 i = 0; i < tokenIdsToBurn.length; i++) {
            if (tokenIdsToBurn[i] == targetSoulId) revert TargetSoulCannotBeBurned();
            if (msg.sender != ownerOf(tokenIdsToBurn[i])) revert NotSoulOwner(); // All souls must be owned by caller
        }

        Soul storage targetSoul = souls[targetSoulId];
        uint256 totalBurnedAP = 0;

        for (uint256 i = 0; i < tokenIdsToBurn.length; i++) {
            uint256 burnedSoulId = tokenIdsToBurn[i];
            totalBurnedAP = totalBurnedAP.add(getAethericPower(burnedSoulId));
            _burn(burnedSoulId); // ERC721 burn
            delete souls[burnedSoulId]; // Remove soul data
        }

        // Apply AP to traits (e.g., 100 AP = 1 trait point, distributed based on current traits)
        uint256 availableTraitPoints = totalBurnedAP.div(100);
        
        // Distribute points proportionally or randomly for more complex logic
        // For simplicity, add to all traits evenly up to a cap of 100
        for (uint256 i = 0; i < 5; i++) { // Iterate through all 5 SoulTraitType enums
            SoulTraitType traitType = SoulTraitType(i);
            uint256 currentTrait = targetSoul.traits[traitType];
            uint256 pointsToAdd = availableTraitPoints.div(5); // Distribute evenly

            uint256 newTrait = currentTrait.add(pointsToAdd);
            if (newTrait > 100) newTrait = 100; // Cap traits at 100

            if (newTrait != currentTrait) {
                targetSoul.traits[traitType] = newTrait;
                emit SoulTraitUpdated(targetSoulId, traitType, currentTrait, newTrait);
            }
        }
        _addEvolutionEvent(targetSoulId, EvolutionEventType.Transmuted, string(abi.encodePacked("Enhanced by transmutation of ", tokenIdsToBurn.length.toString(), " souls.")));
        emit SoulsTransmuted(tokenIdsToBurn, targetSoulId, block.timestamp);
    }

    /**
     * @dev Allows depositing ETH as "Catalyst" to a Soul.
     *      Catalyst can accelerate evolution or provide temporary boosts.
     * @param tokenId The ID of the Soul to inject catalyst into.
     */
    function injectCatalyst(uint256 tokenId) public payable {
        if (!_exists(tokenId)) revert InvalidSoulId();
        if (msg.value == 0) return;

        souls[tokenId].accumulatedCatalystEth = souls[tokenId].accumulatedCatalystEth.add(msg.value);
        _addEvolutionEvent(tokenId, EvolutionEventType.CatalystInjected, string(abi.encodePacked("Injected ", msg.value.toString(), " wei catalyst.")));
        emit CatalystInjectedEvent(tokenId, msg.sender, msg.value);
    }

    /**
     * @dev Triggers an evolution check for a Soul.
     *      This function can be called by anyone to prompt a Soul's growth or decay.
     *      Includes a cooldown to prevent spamming.
     * @param tokenId The ID of the Soul to evolve.
     */
    function triggerEvolution(uint256 tokenId) public {
        if (!_exists(tokenId)) revert InvalidSoulId();
        Soul storage s = souls[tokenId];

        if (block.timestamp < s.lastEvolutionCheck.add(EVOLUTION_COOLDOWN)) {
            // No error, just return if not enough time has passed.
            // Could add an event if desired.
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(s.lastEvolutionCheck);

        // Apply time-based decay/growth (simplified example)
        // Traits with EntropyResistance decay slower.
        for (uint256 i = 0; i < 5; i++) {
            SoulTraitType traitType = SoulTraitType(i);
            uint256 currentTrait = s.traits[traitType];

            // Decay: 1 point per day, reduced by EntropyResistance
            uint256 decayRate = (1 days).div(timeElapsed); // Example: 1 point per day
            uint256 effectiveDecay = decayRate.mul(100 - s.traits[SoulTraitType.EntropyResistance]).div(100);
            
            uint256 newTrait = currentTrait;
            if (effectiveDecay > 0 && newTrait > effectiveDecay) {
                newTrait = newTrait.sub(effectiveDecay);
            } else if (effectiveDecay > 0) {
                newTrait = 0; // Don't go below zero
            }

            // Simple growth based on accumulated catalyst (e.g., 10 wei per trait point)
            uint256 catalystGain = s.accumulatedCatalystEth.div(1e17); // 0.1 ETH per trait point
            if (catalystGain > 0) {
                newTrait = newTrait.add(catalystGain);
                s.accumulatedCatalystEth = 0; // Reset catalyst after use
            }

            if (newTrait > 100) newTrait = 100; // Cap traits at 100

            if (newTrait != currentTrait) {
                s.traits[traitType] = newTrait;
                emit SoulTraitUpdated(tokenId, traitType, currentTrait, newTrait);
            }
        }
        s.lastEvolutionCheck = block.timestamp;
        _addEvolutionEvent(tokenId, EvolutionEventType.TraitEvolved, "Soul traits updated through evolution cycle.");
        emit SoulEvolutionTriggered(tokenId, block.timestamp);
    }

    // --- Delegation Functions ---

    /**
     * @dev Allows a Soul owner to delegate a percentage of their Soul's Aetheric Power.
     *      The delegatee can then "consume" this essence for specific actions.
     * @param tokenId The ID of the Soul.
     * @param delegatee The address to delegate essence to.
     * @param percentage The percentage of AP to delegate (e.g., 50 for 50%).
     * @param duration The duration of the delegation in seconds (0 for indefinite).
     */
    function delegateEssence(uint256 tokenId, address delegatee, uint256 percentage, uint256 duration) public {
        if (msg.sender != ownerOf(tokenId)) revert NotSoulOwner();
        if (percentage > 100) revert InvalidPercentage();

        soulEssenceDelegations[tokenId][delegatee] = EssenceDelegation(percentage, block.timestamp, duration);
        _addEvolutionEvent(tokenId, EvolutionEventType.DelegationGranted, string(abi.encodePacked("Delegated ", percentage.toString(), "% essence to ", Strings.toHexString(uint160(delegatee)))));
        emit EssenceDelegated(tokenId, delegatee, percentage, duration);
    }

    /**
     * @dev Revokes a previously granted essence delegation.
     * @param tokenId The ID of the Soul.
     * @param delegatee The address whose delegation to revoke.
     */
    function revokeEssenceDelegation(uint256 tokenId, address delegatee) public {
        if (msg.sender != ownerOf(tokenId)) revert NotSoulOwner();
        if (soulEssenceDelegations[tokenId][delegatee].percentage == 0) revert DelegationNotFound();

        delete soulEssenceDelegations[tokenId][delegatee];
        _addEvolutionEvent(tokenId, EvolutionEventType.DelegationRevoked, string(abi.encodePacked("Revoked essence delegation from ", Strings.toHexString(uint160(delegatee)))));
        emit EssenceRevoked(tokenId, delegatee);
    }

    /**
     * @dev An example function demonstrating how a delegatee might consume delegated essence.
     *      This would typically be called by another contract (e.g., a DAO or game).
     * @param tokenId The ID of the Soul.
     * @param delegatee The address attempting to consume essence (must be msg.sender).
     * @param amount The amount of Aetheric Power to consume.
     */
    function consumeDelegatedEssence(uint256 tokenId, address delegatee, uint256 amount) public {
        if (msg.sender != delegatee) revert NotSoulOwner(); // Only the delegatee can consume
        if (!_exists(tokenId)) revert InvalidSoulId();

        EssenceDelegation storage delegation = soulEssenceDelegations[tokenId][delegatee];
        if (delegation.percentage == 0) revert DelegationNotFound();
        if (delegation.duration != 0 && block.timestamp > delegation.startTime.add(delegation.duration)) revert DelegationExpired();

        uint256 availableAP = getAethericPower(tokenId).mul(delegation.percentage).div(100);
        if (availableAP < amount) revert NotEnoughAethericPower();

        // In a real scenario, this would *do something* based on `amount`
        // e.g., register a vote, unlock a feature, pay a fee.
        // For this example, we'll just log it.
        // Important: This doesn't *reduce* the Soul's AP, it merely uses its delegated power.
        // A more complex system could implement AP decay on consumption.

        emit EssenceConsumed(tokenId, delegatee, amount);
    }

    // --- Governance Functions (Simplified) ---

    /**
     * @dev Allows a Soul owner (with sufficient Aetheric Power) to propose a change.
     *      The `data` field should be an encoded function call to be executed on success.
     * @param description A brief description of the proposal.
     * @param votingDuration The duration for voting on this specific proposal.
     * @param data Encoded function call to execute (e.g., `abi.encodeWithSelector(this.updateGovernanceParameters.selector, ...)`)
     */
    function proposeTraitAddition(string calldata description, uint256 votingDuration, bytes calldata data) public {
        if (getAethericPower(ownerOf(msg.sender)) < minAPForProposal) revert NotEnoughAethericPower();

        uint256 proposalId = nextProposalId;
        nextProposalId++;

        proposals[proposalId] = Proposal(
            proposalId,
            description,
            false, // not executed
            false, // not passed
            block.timestamp,
            votingDuration,
            0, // votesFor
            0, // votesAgainst
            address(0), // Placeholder for hasVoted mapping, not direct struct member
            _getTotalAethericPower(), // Snapshot total AP for quorum
            data
        );

        emit ProposalCreated(proposalId, msg.sender, description, block.timestamp, votingDuration);
    }

    /**
     * @dev Allows Soul owners to vote on active proposals. Vote weight is scaled by Soul's Aetheric Power.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'for', false for 'against'.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage p = proposals[proposalId];
        if (p.id == 0 && proposalId != 0) revert ProposalNotFound(); // Check if proposal exists
        if (p.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp > p.startTime.add(p.votingDuration)) revert ProposalNotActive();
        if (p.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 voterAP = getAethericPower(ownerOf(msg.sender)); // Assumes msg.sender owns a soul
        if (voterAP == 0) revert NotEnoughAethericPower(); // Or specific error for non-soul-owner

        p.hasVoted[msg.sender] = true;

        if (support) {
            p.votesFor = p.votesFor.add(voterAP);
        } else {
            p.votesAgainst = p.votesAgainst.add(voterAP);
        }

        emit VoteCast(proposalId, msg.sender, support, voterAP);
    }

    /**
     * @dev Executes a successfully voted-on proposal.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage p = proposals[proposalId];
        if (p.id == 0 && proposalId != 0) revert ProposalNotFound();
        if (p.executed) revert ProposalAlreadyExecuted();
        if (block.timestamp <= p.startTime.add(p.votingDuration)) revert ProposalNotActive(); // Voting period must be over

        uint256 totalVotes = p.votesFor.add(p.votesAgainst);
        uint256 requiredQuorum = p.totalAethericPowerAtStart.mul(quorumPercentage).div(10000);

        if (totalVotes < requiredQuorum) {
            p.passed = false; // Mark as failed due to quorum
            p.executed = true;
            emit ProposalExecuted(proposalId, false);
            revert ProposalQuorumNotMet();
        }

        if (p.votesFor > p.votesAgainst) {
            // Execute the proposal's encoded data
            (bool success, ) = address(this).call(p.data);
            if (!success) {
                p.passed = false; // Mark as failed due to execution
                p.executed = true;
                emit ProposalExecuted(proposalId, false);
                revert ProposalVoteFailed();
            }
            p.passed = true;
        } else {
            p.passed = false; // Votes against, or tie
        }

        p.executed = true;
        emit ProposalExecuted(proposalId, p.passed);
    }

    // --- Utility & Admin Functions ---

    /**
     * @dev Retrieves the chronological record of significant evolutionary events for a given Soul.
     * @param tokenId The ID of the Soul.
     * @return An array of EvolutionEvent structs.
     */
    function getSoulHistory(uint256 tokenId) public view returns (EvolutionEvent[] memory) {
        if (!_exists(tokenId)) revert InvalidSoulId();
        return souls[tokenId].history;
    }

    /**
     * @dev Allows the contract owner to update the base URI for Soul metadata.
     * @param newBaseURI The new base URI string.
     */
    function updateBaseURI(string calldata newBaseURI) public onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @dev Calculates the current dynamic price for initiating a new Genesis.
     *      Example: price scales with total minted souls.
     * @return The current minting price in wei.
     */
    function calculateDynamicMintPrice() public view returns (uint256) {
        uint256 basePrice = MIN_MINT_PRICE;
        uint256 numSouls = totalSupply();
        // Simple linear scaling: +0.001 ETH per 100 souls
        uint256 scalingFactor = numSouls.div(100).mul(0.001 ether);
        return basePrice.add(scalingFactor);
    }

    /**
     * @dev Allows the contract owner to adjust governance parameters.
     *      This is the function that would be called by `executeProposal`.
     * @param minAPForProposal_ New minimum AP for proposals.
     * @param quorumPercentage_ New quorum percentage.
     * @param votingDuration_ New default voting duration.
     */
    function setGovernanceParameters(uint256 minAPForProposal_, uint256 quorumPercentage_, uint256 votingDuration_) public onlyOwner {
        minAPForProposal = minAPForProposal_;
        quorumPercentage = quorumPercentage_;
        votingDuration = votingDuration_;
        emit GovernanceParametersUpdated(minAPForProposal_, quorumPercentage_, votingDuration_);
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Adds an evolution event to a Soul's history.
     * @param tokenId The ID of the Soul.
     * @param eventType The type of event.
     * @param description A description of the event.
     */
    function _addEvolutionEvent(uint256 tokenId, EvolutionEventType eventType, string memory description) internal {
        souls[tokenId].history.push(EvolutionEvent(eventType, block.timestamp, description));
        // Cap history length if needed to save gas (e.g., max 20 events)
        if (souls[tokenId].history.length > 20) {
            for (uint256 i = 0; i < 10; i++) { // Remove oldest 10 to keep it manageable
                souls[tokenId].history[i] = souls[tokenId].history[i + 10];
            }
            assembly {
                mstore(
                    add(souls[tokenId].history.offset, 0x20), // Point to the new start of the dynamic array
                    sub(mload(add(souls[tokenId].history.offset, 0x20)), 10) // Update length
                )
            }
        }
    }

    /**
     * @dev Calculates the total Aetheric Power of all existing Souls.
     *      Used for quorum calculations in governance.
     * @return The total Aetheric Power.
     */
    function _getTotalAethericPower() internal view returns (uint256) {
        uint256 totalAP = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (_exists(i)) {
                totalAP = totalAP.add(getAethericPower(i));
            }
        }
        return totalAP;
    }
}
```