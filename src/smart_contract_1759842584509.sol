Here's a smart contract in Solidity called "ChronoLegion," designed around the concept of sentient, evolving NFTs with dynamic attributes, simulated oracle integration, time-gated mechanics, and a touch of internal governance. It aims to combine several advanced concepts into a cohesive ecosystem.

---

## ChronoLegion: Sentient NFT Legions - Smart Contract Outline & Function Summary

**Concept:**
ChronoLegion introduces dynamic ERC-721 NFTs called "ChronoFighters" that evolve and gain "sentience" based on on-chain interactions, consumption of a custom "Essence" token, simulated oracle data, and time-based events. Each ChronoFighter possesses core attributes (Strength, Agility, Wisdom, Empathy), a unique "lineage," and a "sentience level" that unlocks more complex actions and governance participation.

**Key Advanced Concepts:**
1.  **Dynamic On-Chain NFT Metadata:** Core attributes and "sentience" are stored and updated directly on-chain.
2.  **Internal ERC-20-like Token ("Essence"):** Used for evolutions, rituals, and training. Integrated directly into the contract.
3.  **Simulated Oracle Integration:** An external, trusted address can update "environmental factors" that influence fighter attributes or events.
4.  **Time-Based Mechanics:** Rituals, staking, and battle cooldowns are time-sensitive.
5.  **NFT Staking:** Lock ChronoFighters to passively accumulate "Essence."
6.  **NFT-to-NFT Interaction ("Battles"):** Fighters can challenge each other, affecting attributes.
7.  **Progressive Sentience & Abilities:** Sentience level gates access to advanced functions, including proposing evolutionary paths.
8.  **"Catalyst" Integration (Conceptual):** Implies interaction with other NFT types to unlock unique abilities.
9.  **Simulated Cross-Chain Influence:** A function to represent external chain events impacting a fighter's attributes.
10. **Simplified Internal Governance:** High-sentience fighters can propose changes to evolutionary paths.

---

### Function Summary:

**I. Core ChronoFighter NFT Management (ERC-721 Standard & Extensions)**
1.  `constructor()`: Initializes the contract, sets the deployer as owner.
2.  `mintChronoFighter(address to, bytes32 lineageHash)`: Mints a new ChronoFighter for `to` with a base `lineageHash`.
3.  `tokenURI(uint256 tokenId)`: Returns a dynamically generated metadata URI for a ChronoFighter.
4.  `getChronoFighterDetails(uint256 tokenId)`: Retrieves all current on-chain dynamic attributes of a ChronoFighter.
5.  `setApprovedCreator(address creator, bool approved)`: Grants/revokes an address the permission to mint new ChronoFighters.
6.  `toggleMintingLock(bool locked)`: Locks or unlocks the ability to mint new ChronoFighters.

**II. Essence Token (Internal ERC-20-like)**
7.  `balanceOfEssence(address account)`: Returns the Essence balance for a given address.
8.  `transferEssence(address recipient, uint256 amount)`: Transfers Essence between addresses (internal to ChronoLegion, not a standalone ERC-20).
9.  `distributeEssenceToFighterHolders(uint256 amountPerFighter)`: Distributes Essence to all current ChronoFighter owners (admin function).

**III. Dynamic Attribute Evolution & Interaction**
10. `evolveChronoFighter(uint256 tokenId, EvolutionType evolutionType)`: Spends Essence to increase a specific attribute (Strength, Agility, Wisdom, Empathy). Requires certain conditions (age, sentience).
11. `imprintCatalyst(uint256 tokenId, uint256 catalystId)`: Simulates using a "Catalyst" NFT (not implemented as a separate ERC-1155, but its effect) to unlock a special ability for a fighter.
12. `challengeChronoFighter(uint256 attackerId, uint256 defenderId)`: Initiates a battle between two fighters. Outcome affects attributes, Essence, or sentience.
13. `conductRitual(uint256 tokenId)`: A time-gated function that, when called, might boost an attribute based on the current `environmentalFactor` (oracle data).
14. `attuneAffinity(uint256 tokenId, AffinityType newAffinity)`: Allows a fighter to switch its elemental/faction affinity by spending Essence.
15. `upgradeSentience(uint256 tokenId)`: Spends Essence to increase the fighter's `sentienceLevel`, unlocking advanced capabilities.

**IV. NFT Staking Mechanics**
16. `stakeChronoFighterForEssence(uint256 tokenId)`: Locks a ChronoFighter to earn passive Essence over time.
17. `unstakeChronoFighter(uint256 tokenId)`: Unlocks a staked ChronoFighter and claims accumulated Essence.

**V. Oracle Integration (Simulated)**
18. `updateEnvironmentalFactor(uint256 newFactor)`: Callable only by the designated oracle address, updates the internal `environmentalFactor`.
19. `getCurrentEnvironmentalFactor()`: Retrieves the current oracle-reported environmental factor.

**VI. Simplified Internal Governance (for advanced Sentient Fighters)**
20. `proposeEvolutionPath(string memory description, EvolutionType affectedType, uint256 boostAmount)`: Fighters with high sentience can propose new evolutionary paths or attribute boosts.
21. `voteOnProposal(uint256 proposalId, bool support)`: Allows high-sentience fighters to vote on active proposals.
22. `executeProposal(uint256 proposalId)`: Executes a passed proposal (e.g., applies a global boost to an attribute type).

**VII. Administrative & Utility**
23. `setOracleAddress(address _oracleAddress)`: Sets the address authorized to update oracle data.
24. `configureEvolutionCost(EvolutionType evolutionType, uint256 cost)`: Adjusts the Essence cost for various evolution types.
25. `registerCrossChainInfluence(uint256 tokenId, uint256 influenceScore)`: Simulates receiving influence from another chain, boosting a fighter's internal `crossChainInfluenceScore`.
26. `withdrawFunds()`: Allows the contract owner to withdraw accumulated ETH (from minting or other fees).
27. `pause()`: Pauses all dynamic interactions with the contract (emergency stop).
28. `unpause()`: Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ChronoLegion: Sentient NFT Legions
/// @author YourName (simulated for advanced concepts)
/// @notice This contract implements dynamic ERC-721 NFTs (ChronoFighters) that evolve based on interactions, time, and oracle data.
/// It includes an internal 'Essence' token, staking, battling, and a simplified governance mechanism.
contract ChronoLegion is ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;

    // Custom "Essence" Token (internal ERC-20-like implementation)
    mapping(address => uint256) private _essenceBalances;
    event EssenceTransferred(address indexed from, address indexed to, uint256 amount);
    event EssenceMinted(address indexed to, uint256 amount);

    // ChronoFighter Data Structure
    struct ChronoFighter {
        uint256 id;
        address owner; // Redundant but useful for quick lookups in struct
        uint256 birthTime;
        uint256 strength;
        uint256 agility;
        uint256 wisdom;
        uint256 empathy;
        uint256 sentienceLevel; // 0-100, higher unlocks more capabilities
        AffinityType affinity;
        uint256 lastRitualTime;
        uint256 lastBattleTime;
        bool isStaked;
        bytes32 lineageHash; // Unique genetic code
        uint256 activeAbilities; // Bitmask for abilities unlocked by catalysts
        uint256 crossChainInfluenceScore; // Simulated influence from other chains
    }
    mapping(uint256 => ChronoFighter) public chronoFighters;

    // Staking Data
    struct StakingData {
        uint256 stakeTime;
        uint256 accumulatedEssence;
    }
    mapping(uint256 => StakingData) public stakingInfo; // tokenId => StakingData

    // Oracle Integration
    address public oracleAddress;
    uint256 public environmentalFactor; // Updated by oracle, influences rituals/evolutions
    uint256 public constant RITUAL_COOLDOWN = 1 days;
    uint256 public constant BATTLE_COOLDOWN = 1 hours;

    // Minting Control
    mapping(address => bool) public approvedCreators;
    bool public mintingLocked;
    uint256 public mintingPrice = 0.05 ether;

    // Evolution Costs & Parameters
    enum EvolutionType { Strength, Agility, Wisdom, Empathy, Sentience }
    mapping(EvolutionType => uint256) public evolutionCosts; // EvolutionType => Essence cost
    uint256 public constant BASE_EVOLUTION_COST = 100 * (10 ** 18); // 100 Essence

    // Affinity Types
    enum AffinityType { None, Fire, Water, Earth, Air, Light, Shadow }
    uint256 public constant AFFINITY_CHANGE_COST = 50 * (10 ** 18); // 50 Essence

    // Simplified Governance (Proposals for Evolution Paths)
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        EvolutionType affectedType;
        uint256 boostAmount;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 creationTime;
        uint256 endTime;
        bool executed;
        mapping(uint256 => bool) hasVoted; // tokenId => voted
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant MIN_SENTIENCE_FOR_PROPOSAL = 50;
    uint256 public constant MIN_SENTIENCE_FOR_VOTE = 20;

    // Events
    event ChronoFighterMinted(uint256 indexed tokenId, address indexed owner, bytes32 lineageHash);
    event ChronoFighterEvolved(uint256 indexed tokenId, EvolutionType indexed evolutionType, uint256 oldStat, uint256 newStat);
    event ChronoFighterChallenged(uint256 indexed attackerId, uint256 indexed defenderId, address indexed winner, uint256 essenceReward);
    event ChronoFighterStaked(uint256 indexed tokenId, uint256 stakeTime);
    event ChronoFighterUnstaked(uint256 indexed tokenId, uint256 earnedEssence);
    event RitualConducted(uint256 indexed tokenId, uint256 environmentalFactor, uint256 boostedStat);
    event AffinityAttuned(uint256 indexed tokenId, AffinityType oldAffinity, AffinityType newAffinity);
    event SentienceUpgraded(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event CatalystImprinted(uint256 indexed tokenId, uint256 indexed catalystId, uint256 newAbilitiesMask);
    event OracleDataUpdated(uint256 newEnvironmentalFactor);
    event EvolutionCostConfigured(EvolutionType indexed evolutionType, uint256 newCost);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event ProposalVoted(uint256 indexed proposalId, uint256 indexed voterTokenId, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event CrossChainInfluenceRegistered(uint256 indexed tokenId, uint256 influenceScore);

    // --- Modifiers ---
    modifier onlyApprovedCreator() {
        require(approvedCreators[msg.sender], "ChronoLegion: Not an approved creator");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoLegion: Only oracle can call this function");
        _;
    }

    modifier onlyChronoFighterOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ChronoLegion: Not ChronoFighter owner or approved");
        _;
    }

    modifier whenChronoFighterNotStaked(uint256 tokenId) {
        require(!chronoFighters[tokenId].isStaked, "ChronoLegion: ChronoFighter is currently staked");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("ChronoFighter", "CRNO") Ownable(msg.sender) Pausable() {
        _nextProposalId = 1;
        oracleAddress = msg.sender; // Deployer is initial oracle
        approvedCreators[msg.sender] = true; // Deployer is initial creator

        // Set initial evolution costs
        evolutionCosts[EvolutionType.Strength] = BASE_EVOLUTION_COST;
        evolutionCosts[EvolutionType.Agility] = BASE_EVOLUTION_COST;
        evolutionCosts[EvolutionType.Wisdom] = BASE_EVOLUTION_COST;
        evolutionCosts[EvolutionType.Empathy] = BASE_EVOLUTION_COST;
        evolutionCosts[EvolutionType.Sentience] = BASE_EVOLUTION_COST * 2; // Sentience is harder
    }

    // --- I. Core ChronoFighter NFT Management ---

    /// @notice Mints a new ChronoFighter NFT.
    /// @param to The address to mint the NFT to.
    /// @param lineageHash A unique identifier representing the fighter's base genetics/lineage.
    function mintChronoFighter(address to, bytes32 lineageHash)
        public
        payable
        whenNotPaused
        onlyApprovedCreator
    {
        require(!mintingLocked, "ChronoLegion: Minting is currently locked.");
        require(msg.value >= mintingPrice, "ChronoLegion: Insufficient ETH for minting.");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);
        _setTokenURI(newItemId, ""); // URI will be generated dynamically

        chronoFighters[newItemId] = ChronoFighter({
            id: newItemId,
            owner: to, // Storing owner directly for convenience
            birthTime: block.timestamp,
            strength: 10 + (uint256(lineageHash) % 10), // Base stats influenced by lineage
            agility: 10 + (uint256(lineageHash) % 10),
            wisdom: 10 + (uint256(lineageHash) % 10),
            empathy: 10 + (uint256(lineageHash) % 10),
            sentienceLevel: 1, // Starts low
            affinity: AffinityType.None,
            lastRitualTime: 0,
            lastBattleTime: 0,
            isStaked: false,
            lineageHash: lineageHash,
            activeAbilities: 0,
            crossChainInfluenceScore: 0
        });

        emit ChronoFighterMinted(newItemId, to, lineageHash);
    }

    /// @notice Returns a dynamically generated metadata URI for a ChronoFighter.
    /// @param tokenId The ID of the ChronoFighter.
    /// @return string The URI pointing to the metadata.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        _requireOwned(tokenId); // Ensure tokenId exists and is owned
        ChronoFighter storage fighter = chronoFighters[tokenId];

        // This is a simplified dynamic URI. In a real dApp, this would point to an API
        // that generates JSON based on the on-chain data.
        string memory baseURI = "ipfs://QmYourBaseURI/";
        string memory json = string.concat(
            '{"name": "ChronoFighter #', tokenId.toString(),
            '", "description": "A sentient NFT evolving through time and interactions.",',
            '"image": "ipfs://QmYourImageURI/', tokenId.toString(), '.png",',
            '"attributes": [',
                '{"trait_type": "Strength", "value": "', fighter.strength.toString(), '"},',
                '{"trait_type": "Agility", "value": "', fighter.agility.toString(), '"},',
                '{"trait_type": "Wisdom", "value": "', fighter.wisdom.toString(), '"},',
                '{"trait_type": "Empathy", "value": "', fighter.empathy.toString(), '"},',
                '{"trait_type": "Sentience Level", "value": "', fighter.sentienceLevel.toString(), '"},',
                '{"trait_type": "Affinity", "value": "', _getAffinityName(fighter.affinity), '"},',
                '{"trait_type": "Age (Days)", "value": "', ((block.timestamp - fighter.birthTime) / 1 days).toString(), '"},',
                '{"trait_type": "Lineage Hash", "value": "', Strings.toHexString(uint256(fighter.lineageHash)), '"}',
            ']}'
        );
        // This would typically return a base URI + tokenId, and an off-chain server would handle the dynamic JSON.
        // For simplicity, we just return a placeholder.
        return string.concat(baseURI, tokenId.toString(), ".json");
    }

    /// @notice Helper to get string name of affinity.
    function _getAffinityName(AffinityType _affinity) internal pure returns (string memory) {
        if (_affinity == AffinityType.Fire) return "Fire";
        if (_affinity == AffinityType.Water) return "Water";
        if (_affinity == AffinityType.Earth) return "Earth";
        if (_affinity == AffinityType.Air) return "Air";
        if (_affinity == AffinityType.Light) return "Light";
        if (_affinity == AffinityType.Shadow) return "Shadow";
        return "None";
    }

    /// @notice Retrieves all on-chain dynamic attributes of a ChronoFighter.
    /// @param tokenId The ID of the ChronoFighter.
    /// @return ChronoFighter struct containing all details.
    function getChronoFighterDetails(uint256 tokenId) public view returns (ChronoFighter memory) {
        _requireOwned(tokenId);
        return chronoFighters[tokenId];
    }

    /// @notice Grants or revokes an address the permission to mint new ChronoFighters.
    /// @param creator The address to set creator status for.
    /// @param approved Whether the address should be approved.
    function setApprovedCreator(address creator, bool approved) public onlyOwner {
        approvedCreators[creator] = approved;
    }

    /// @notice Locks or unlocks the ability to mint new ChronoFighters.
    /// @param locked True to lock minting, false to unlock.
    function toggleMintingLock(bool locked) public onlyOwner {
        mintingLocked = locked;
    }

    // --- II. Essence Token (Internal ERC-20-like) ---

    /// @notice Returns the Essence balance for a given account.
    /// @param account The address to query.
    /// @return uint256 The Essence balance.
    function balanceOfEssence(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    /// @notice Transfers Essence between addresses.
    /// @param recipient The address to send Essence to.
    /// @param amount The amount of Essence to send.
    function transferEssence(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "ChronoLegion: Transfer to the zero address");
        require(_essenceBalances[msg.sender] >= amount, "ChronoLegion: Insufficient Essence balance");

        _essenceBalances[msg.sender] -= amount;
        _essenceBalances[recipient] += amount;
        emit EssenceTransferred(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Internal function to mint Essence. Only callable by contract logic.
    function _mintEssence(address to, uint256 amount) internal {
        require(to != address(0), "ChronoLegion: Mint to the zero address");
        _essenceBalances[to] += amount;
        emit EssenceMinted(to, amount);
    }

    /// @notice Distributes Essence to all current ChronoFighter owners. Admin function.
    /// @param amountPerFighter The amount of Essence each fighter owner receives per fighter.
    function distributeEssenceToFighterHolders(uint256 amountPerFighter) public onlyOwner whenNotPaused {
        require(amountPerFighter > 0, "ChronoLegion: Amount must be greater than zero");
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i)) { // Check if token exists (not burned)
                address ownerOfFighter = ownerOf(i);
                _mintEssence(ownerOfFighter, amountPerFighter);
            }
        }
    }

    // --- III. Dynamic Attribute Evolution & Interaction ---

    /// @notice Spends Essence to increase a specific attribute of a ChronoFighter.
    /// @param tokenId The ID of the ChronoFighter.
    /// @param evolutionType The type of attribute to evolve.
    function evolveChronoFighter(uint256 tokenId, EvolutionType evolutionType)
        public
        whenNotPaused
        onlyChronoFighterOwner(tokenId)
        whenChronoFighterNotStaked(tokenId)
    {
        ChronoFighter storage fighter = chronoFighters[tokenId];
        uint256 cost = evolutionCosts[evolutionType];
        require(_essenceBalances[msg.sender] >= cost, "ChronoLegion: Insufficient Essence to evolve");
        require(fighter.sentienceLevel > 0, "ChronoLegion: Fighter needs some sentience to evolve");

        _essenceBalances[msg.sender] -= cost;

        uint256 oldStat;
        uint256 newStat;

        if (evolutionType == EvolutionType.Strength) {
            oldStat = fighter.strength;
            fighter.strength += (1 + (fighter.sentienceLevel / 10)); // Higher sentience gives more boost
            newStat = fighter.strength;
        } else if (evolutionType == EvolutionType.Agility) {
            oldStat = fighter.agility;
            fighter.agility += (1 + (fighter.sentienceLevel / 10));
            newStat = fighter.agility;
        } else if (evolutionType == EvolutionType.Wisdom) {
            oldStat = fighter.wisdom;
            fighter.wisdom += (1 + (fighter.sentienceLevel / 10));
            newStat = fighter.wisdom;
        } else if (evolutionType == EvolutionType.Empathy) {
            oldStat = fighter.empathy;
            fighter.empathy += (1 + (fighter.sentienceLevel / 10));
            newStat = fighter.empathy;
        } else {
            revert("ChronoLegion: Invalid evolution type");
        }

        emit ChronoFighterEvolved(tokenId, evolutionType, oldStat, newStat);
    }

    /// @notice Simulates using a "Catalyst" NFT to unlock a special ability for a fighter.
    /// @dev In a full implementation, this would involve burning or locking an ERC-1155 Catalyst.
    /// @param tokenId The ID of the ChronoFighter.
    /// @param catalystId The ID of the catalyst being used (placeholder for different types).
    function imprintCatalyst(uint256 tokenId, uint256 catalystId)
        public
        whenNotPaused
        onlyChronoFighterOwner(tokenId)
        whenChronoFighterNotStaked(tokenId)
    {
        ChronoFighter storage fighter = chronoFighters[tokenId];
        // Simulate catalyst effect: e.g., catalystId 1 unlocks ability A, 2 unlocks B.
        // For demonstration, we just set a bit in activeAbilities.
        require(catalystId > 0 && catalystId <= 64, "ChronoLegion: Invalid catalyst ID (must be 1-64)");
        uint256 abilityMask = 1 << (catalystId - 1);
        require((fighter.activeAbilities & abilityMask) == 0, "ChronoLegion: Ability already unlocked by this catalyst");

        fighter.activeAbilities |= abilityMask;

        // In a real scenario, you'd burn the catalyst token here.
        // IERC1155(catalystCollectionAddress).burn(msg.sender, catalystId, 1);

        emit CatalystImprinted(tokenId, catalystId, fighter.activeAbilities);
    }

    /// @notice Initiates a battle between two ChronoFighters.
    /// @param attackerId The ID of the attacking ChronoFighter.
    /// @param defenderId The ID of the defending ChronoFighter.
    function challengeChronoFighter(uint256 attackerId, uint256 defenderId)
        public
        whenNotPaused
    {
        _requireOwned(attackerId);
        _requireOwned(defenderId);

        ChronoFighter storage attacker = chronoFighters[attackerId];
        ChronoFighter storage defender = chronoFighters[defenderId];

        require(msg.sender == ownerOf(attackerId), "ChronoLegion: Only attacker's owner can initiate battle");
        require(attackerId != defenderId, "ChronoLegion: Cannot battle self");
        require(block.timestamp >= attacker.lastBattleTime + BATTLE_COOLDOWN, "ChronoLegion: Attacker is on battle cooldown");
        require(block.timestamp >= defender.lastBattleTime + BATTLE_COOLDOWN, "ChronoLegion: Defender is on battle cooldown");
        require(!attacker.isStaked, "ChronoLegion: Attacker is staked and cannot battle");
        require(!defender.isStaked, "ChronoLegion: Defender is staked and cannot battle");

        // Simple battle logic: highest effective strength wins
        uint256 attackerPower = attacker.strength + attacker.agility + (attacker.wisdom / 2);
        uint256 defenderPower = defender.strength + defender.agility + (defender.wisdom / 2);

        address winnerAddress;
        uint256 essenceReward = 0;

        // Add some randomness, potentially influenced by lineage or environmental factors
        if (attackerPower + (environmentalFactor % 10) > defenderPower + (uint256(defender.lineageHash) % 10)) {
            // Attacker wins
            winnerAddress = ownerOf(attackerId);
            essenceReward = 20 * (10 ** 18); // 20 Essence
            _mintEssence(winnerAddress, essenceReward);
            attacker.strength += 1; // Small boost for winning
            defender.empathy -= (defender.empathy > 0 ? 1 : 0); // Small penalty for losing
            if (defender.sentienceLevel > 1) defender.sentienceLevel -= 1; // Sentience might drop
        } else {
            // Defender wins or draw
            winnerAddress = ownerOf(defenderId);
            essenceReward = 10 * (10 ** 18); // 10 Essence
            _mintEssence(winnerAddress, essenceReward);
            defender.agility += 1;
            attacker.empathy -= (attacker.empathy > 0 ? 1 : 0);
            if (attacker.sentienceLevel > 1) attacker.sentienceLevel -= 1;
        }

        attacker.lastBattleTime = block.timestamp;
        defender.lastBattleTime = block.timestamp;

        emit ChronoFighterChallenged(attackerId, defenderId, winnerAddress, essenceReward);
    }

    /// @notice A time-gated function that, when called, might boost a specific attribute based on an oracle (simulated environmental factor).
    /// @param tokenId The ID of the ChronoFighter.
    function conductRitual(uint256 tokenId)
        public
        whenNotPaused
        onlyChronoFighterOwner(tokenId)
        whenChronoFighterNotStaked(tokenId)
    {
        ChronoFighter storage fighter = chronoFighters[tokenId];
        require(block.timestamp >= fighter.lastRitualTime + RITUAL_COOLDOWN, "ChronoLegion: Ritual is on cooldown");
        require(fighter.sentienceLevel >= 5, "ChronoLegion: Fighter sentience too low for ritual (min 5)");

        fighter.lastRitualTime = block.timestamp;

        uint256 oldStat = 0;
        uint256 newStat = 0;
        EvolutionType boostedType = EvolutionType.Strength; // Default

        // Simulate how environmental factor boosts an attribute
        if (environmentalFactor % 4 == 0) { // Example: If factor is even, boost strength
            oldStat = fighter.strength;
            fighter.strength += (environmentalFactor / 10 + 1);
            newStat = fighter.strength;
            boostedType = EvolutionType.Strength;
        } else if (environmentalFactor % 4 == 1) {
            oldStat = fighter.agility;
            fighter.agility += (environmentalFactor / 10 + 1);
            newStat = fighter.agility;
            boostedType = EvolutionType.Agility;
        } else if (environmentalFactor % 4 == 2) {
            oldStat = fighter.wisdom;
            fighter.wisdom += (environmentalFactor / 10 + 1);
            newStat = fighter.wisdom;
            boostedType = EvolutionType.Wisdom;
        } else { // environmentalFactor % 4 == 3
            oldStat = fighter.empathy;
            fighter.empathy += (environmentalFactor / 10 + 1);
            newStat = fighter.empathy;
            boostedType = EvolutionType.Empathy;
        }

        // Small sentience boost for conducting rituals
        if (fighter.sentienceLevel < 100) fighter.sentienceLevel += 1;

        emit RitualConducted(tokenId, environmentalFactor, newStat);
        emit ChronoFighterEvolved(tokenId, boostedType, oldStat, newStat);
    }

    /// @notice Allows a fighter to switch its elemental/faction affinity by spending Essence.
    /// @param tokenId The ID of the ChronoFighter.
    /// @param newAffinity The desired new affinity.
    function attuneAffinity(uint256 tokenId, AffinityType newAffinity)
        public
        whenNotPaused
        onlyChronoFighterOwner(tokenId)
        whenChronoFighterNotStaked(tokenId)
    {
        ChronoFighter storage fighter = chronoFighters[tokenId];
        require(fighter.affinity != newAffinity, "ChronoLegion: Fighter already has this affinity");
        require(newAffinity != AffinityType.None, "ChronoLegion: Cannot attune to 'None' affinity");
        require(_essenceBalances[msg.sender] >= AFFINITY_CHANGE_COST, "ChronoLegion: Insufficient Essence for attunement");
        require(fighter.sentienceLevel >= 10, "ChronoLegion: Fighter sentience too low for affinity attunement (min 10)");


        _essenceBalances[msg.sender] -= AFFINITY_CHANGE_COST;
        AffinityType oldAffinity = fighter.affinity;
        fighter.affinity = newAffinity;

        emit AffinityAttuned(tokenId, oldAffinity, newAffinity);
    }

    /// @notice Spends Essence to increase the fighter's `sentienceLevel`, unlocking advanced capabilities.
    /// @param tokenId The ID of the ChronoFighter.
    function upgradeSentience(uint256 tokenId)
        public
        whenNotPaused
        onlyChronoFighterOwner(tokenId)
        whenChronoFighterNotStaked(tokenId)
    {
        ChronoFighter storage fighter = chronoFighters[tokenId];
        require(fighter.sentienceLevel < 100, "ChronoLegion: Fighter already at max sentience");
        uint256 cost = evolutionCosts[EvolutionType.Sentience] * (fighter.sentienceLevel / 10 + 1); // Cost increases with sentience
        require(_essenceBalances[msg.sender] >= cost, "ChronoLegion: Insufficient Essence to upgrade sentience");

        _essenceBalances[msg.sender] -= cost;
        uint256 oldLevel = fighter.sentienceLevel;
        fighter.sentienceLevel += 1; // Increase by one level
        emit SentienceUpgraded(tokenId, oldLevel, fighter.sentienceLevel);
    }

    // --- IV. NFT Staking Mechanics ---

    /// @notice Locks a ChronoFighter to earn passive Essence over time.
    /// @param tokenId The ID of the ChronoFighter to stake.
    function stakeChronoFighterForEssence(uint256 tokenId)
        public
        whenNotPaused
        onlyChronoFighterOwner(tokenId)
    {
        ChronoFighter storage fighter = chronoFighters[tokenId];
        require(!fighter.isStaked, "ChronoLegion: ChronoFighter is already staked");

        fighter.isStaked = true;
        stakingInfo[tokenId] = StakingData({
            stakeTime: block.timestamp,
            accumulatedEssence: 0
        });

        emit ChronoFighterStaked(tokenId, block.timestamp);
    }

    /// @notice Unlocks a staked ChronoFighter and claims accumulated Essence.
    /// @param tokenId The ID of the ChronoFighter to unstake.
    function unstakeChronoFighter(uint256 tokenId)
        public
        whenNotPaused
        onlyChronoFighterOwner(tokenId)
    {
        ChronoFighter storage fighter = chronoFighters[tokenId];
        StakingData storage stakeData = stakingInfo[tokenId];
        require(fighter.isStaked, "ChronoLegion: ChronoFighter is not staked");

        uint256 elapsedDays = (block.timestamp - stakeData.stakeTime) / 1 days;
        uint256 earnedEssence = elapsedDays * (10 * (10 ** 18)) * (fighter.sentienceLevel / 10 + 1); // 10 Essence per day + sentience bonus
        // Add any previously accumulated essence
        earnedEssence += stakeData.accumulatedEssence;

        fighter.isStaked = false;
        delete stakingInfo[tokenId]; // Reset staking info

        if (earnedEssence > 0) {
            _mintEssence(msg.sender, earnedEssence);
        }

        emit ChronoFighterUnstaked(tokenId, earnedEssence);
    }

    // --- V. Oracle Integration (Simulated) ---

    /// @notice Callable only by the designated oracle address, updates the internal `environmentalFactor`.
    /// @param newFactor The new environmental factor value.
    function updateEnvironmentalFactor(uint256 newFactor) public onlyOracle whenNotPaused {
        environmentalFactor = newFactor;
        emit OracleDataUpdated(newFactor);
    }

    /// @notice Retrieves the current oracle-reported environmental factor.
    /// @return uint256 The current environmental factor.
    function getCurrentEnvironmentalFactor() public view returns (uint256) {
        return environmentalFactor;
    }

    // --- VI. Simplified Internal Governance (for advanced Sentient Fighters) ---

    /// @notice Fighters with high sentience can propose new evolutionary paths or attribute boosts.
    /// @param description A description of the proposal.
    /// @param affectedType The attribute type to be affected.
    /// @param boostAmount The amount of boost to apply if executed.
    function proposeEvolutionPath(string memory description, EvolutionType affectedType, uint256 boostAmount)
        public
        whenNotPaused
    {
        // Require a fighter to propose
        require(_tokenIdsOfOwner(msg.sender).length > 0, "ChronoLegion: Proposer must own a ChronoFighter");
        uint256 proposerTokenId = _tokenIdsOfOwner(msg.sender)[0]; // Use the first token as proposer

        require(chronoFighters[proposerTokenId].sentienceLevel >= MIN_SENTIENCE_FOR_PROPOSAL,
            "ChronoLegion: ChronoFighter sentience too low to propose (min 50)");
        require(boostAmount > 0, "ChronoLegion: Boost amount must be positive");

        uint256 proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: description,
            affectedType: affectedType,
            boostAmount: boostAmount,
            votesFor: 0,
            votesAgainst: 0,
            creationTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            executed: false,
            hasVoted: new mapping(uint256 => bool) // Initialize the mapping
        });

        emit ProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice Allows high-sentience fighters to vote on active proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for', false for 'against'.
    function voteOnProposal(uint256 proposalId, bool support)
        public
        whenNotPaused
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ChronoLegion: Proposal does not exist");
        require(block.timestamp < proposal.endTime, "ChronoLegion: Voting period has ended");

        // Use a fighter to vote. Each fighter gets one vote.
        require(_tokenIdsOfOwner(msg.sender).length > 0, "ChronoLegion: Voter must own a ChronoFighter");
        uint256 voterTokenId = _tokenIdsOfOwner(msg.sender)[0]; // Use the first token as voter

        require(chronoFighters[voterTokenId].sentienceLevel >= MIN_SENTIENCE_FOR_VOTE,
            "ChronoLegion: ChronoFighter sentience too low to vote (min 20)");
        require(!proposal.hasVoted[voterTokenId], "ChronoLegion: ChronoFighter has already voted on this proposal");

        proposal.hasVoted[voterTokenId] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit ProposalVoted(proposalId, voterTokenId, support);
    }

    /// @notice Executes a passed proposal (e.g., applies a global boost to an attribute type).
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId)
        public
        whenNotPaused
        onlyOwner // Only owner can execute, after votes are in. In a full DAO, this would be automated.
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "ChronoLegion: Proposal does not exist");
        require(block.timestamp >= proposal.endTime, "ChronoLegion: Voting period is still active");
        require(!proposal.executed, "ChronoLegion: Proposal already executed");

        if (proposal.votesFor > proposal.votesAgainst) {
            // Proposal passed! Apply the effect.
            // Example: Globally boost the affected attribute for all existing fighters.
            for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
                if (_exists(i)) {
                    ChronoFighter storage fighter = chronoFighters[i];
                    uint256 oldStat;
                    uint256 newStat;

                    if (proposal.affectedType == EvolutionType.Strength) {
                        oldStat = fighter.strength;
                        fighter.strength += proposal.boostAmount;
                        newStat = fighter.strength;
                    } else if (proposal.affectedType == EvolutionType.Agility) {
                        oldStat = fighter.agility;
                        fighter.agility += proposal.boostAmount;
                        newStat = fighter.agility;
                    } else if (proposal.affectedType == EvolutionType.Wisdom) {
                        oldStat = fighter.wisdom;
                        fighter.wisdom += proposal.boostAmount;
                        newStat = fighter.wisdom;
                    } else if (proposal.affectedType == EvolutionType.Empathy) {
                        oldStat = fighter.empathy;
                        fighter.empathy += proposal.boostAmount;
                        newStat = fighter.empathy;
                    } else if (proposal.affectedType == EvolutionType.Sentience) {
                        oldStat = fighter.sentienceLevel;
                        fighter.sentienceLevel += proposal.boostAmount;
                        if (fighter.sentienceLevel > 100) fighter.sentienceLevel = 100;
                        newStat = fighter.sentienceLevel;
                    }
                    emit ChronoFighterEvolved(i, proposal.affectedType, oldStat, newStat);
                }
            }
            proposal.executed = true;
            emit ProposalExecuted(proposalId);
        } else {
            // Proposal failed or tied.
            // No action needed other than marking as executed.
            proposal.executed = true;
            emit ProposalExecuted(proposalId); // Still emit to indicate resolution
        }
    }

    /// @notice Helper function to get all token IDs owned by an address.
    function _tokenIdsOfOwner(address _owner) internal view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(_owner));
        uint256 counter = 0;
        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            if (_exists(i) && ownerOf(i) == _owner) {
                tokens[counter] = i;
                counter++;
            }
        }
        return tokens;
    }


    // --- VII. Administrative & Utility ---

    /// @notice Sets the address authorized to update oracle data.
    /// @param _oracleAddress The new oracle address.
    function setOracleAddress(address _oracleAddress) public onlyOwner {
        require(_oracleAddress != address(0), "ChronoLegion: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }

    /// @notice Adjusts the Essence cost for various evolution types.
    /// @param evolutionType The type of evolution to configure.
    /// @param cost The new Essence cost.
    function configureEvolutionCost(EvolutionType evolutionType, uint256 cost) public onlyOwner {
        evolutionCosts[evolutionType] = cost;
        emit EvolutionCostConfigured(evolutionType, cost);
    }

    /// @notice Simulates receiving influence from another chain, boosting a fighter's internal `crossChainInfluenceScore`.
    /// @dev In a real scenario, this would be called by a trusted bridge or cross-chain messaging protocol.
    /// @param tokenId The ID of the ChronoFighter to influence.
    /// @param influenceScore The score representing the cross-chain influence.
    function registerCrossChainInfluence(uint256 tokenId, uint256 influenceScore)
        public
        onlyOwner // For demonstration, owner acts as the trusted bridge
        whenNotPaused
    {
        _requireOwned(tokenId); // Ensure the token exists
        ChronoFighter storage fighter = chronoFighters[tokenId];
        fighter.crossChainInfluenceScore += influenceScore;
        // Optionally, influence could boost other stats or sentience
        fighter.sentienceLevel += (influenceScore / 1000); // Small sentience boost per 1000 influence
        if (fighter.sentienceLevel > 100) fighter.sentienceLevel = 100;

        emit CrossChainInfluenceRegistered(tokenId, fighter.crossChainInfluenceScore);
    }

    /// @notice Allows the contract owner to withdraw accumulated ETH.
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ChronoLegion: ETH withdrawal failed");
    }

    /// @notice Pauses all dynamic interactions with the contract (emergency stop).
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are required for ERC721URIStorage
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Update owner in custom struct if transferred
        if (chronoFighters[tokenId].id != 0) { // Check if fighter exists
            chronoFighters[tokenId].owner = to;
        }
    }

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721URIStorage)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }
}
```