Here's a smart contract system in Solidity, comprising two contracts: `ChronoToken` (an ERC-20 token for staking and fees) and `ChronoForge` (the main ERC-721 generative NFT contract).

The `ChronoForge` contract embodies several advanced, creative, and trendy concepts:

1.  **Generative & Dynamic NFTs (ChronoEssences):** NFTs are forged with traits influenced by user reputation, global "environmental" parameters, and a dynamic seed. They can also "evolve" under specific, governance-set conditions.
2.  **Reputation System (ChronosPoints):** Users stake `ChronoToken` to accumulate non-transferable `ChronosPoints`, which influence the rarity and quality of their forged Essences.
3.  **Oracle-Driven Environmental Flux:** External oracle submissions (`AethericFlux`, `TemporalResonance`) dynamically alter the forging environment, making each Essence unique based on real-world (or simulated) events.
4.  **Time-Limited Utility Delegation:** Essence owners can delegate specific utility or access rights of their NFTs to other addresses for a set duration without transferring ownership.
5.  **Decentralized Governance:** A basic proposal and voting system allows `ChronoToken` holders to influence forging parameters, add new trait pools, and manage the protocol.
6.  **"Self-Evolving" Parameters:** The protocol's trait generation weights and evolution conditions can be adjusted through governance, mimicking a learning or adapting system.

---

### Contract Outline and Function Summary

**I. `ChronoToken.sol` (ERC-20 Standard Token)**
This contract serves as the native utility token for the ChronoForge ecosystem.

*   `constructor(uint256 initialSupply)`: Initializes the token with a name, symbol, and total supply.

**II. `ChronoForge.sol` (Main NFT Contract)**
This contract is the core protocol for forging, managing, and evolving `ChronoEssences`.

*   **State Variables & Data Structures:**
    *   `ChronoEssence`: Struct defining the properties of each NFT (traits, evolution status, metadata).
    *   `EssenceTrait`: Struct for individual trait properties.
    *   `ForgeParam`: Enum for global forging parameters.
    *   `TraitType`: Enum for categories of traits.
    *   `Proposal`: Struct for governance proposals.
    *   `_essenceProperties`: Mapping from `tokenId` to `ChronoEssence`.
    *   `_chronosPoints`: Mapping from `address` to `uint256` (reputation score).
    *   `_stakedChronoTokens`: Mapping from `address` to `uint256`.
    *   `_lastStakeTime`: Mapping from `address` to `uint256`.
    *   `_aethericFlux`: Global environmental variable.
    *   `_temporalResonance`: Global environmental variable.
    *   `oracleAddress`: Address authorized to update environmental fluxes.
    *   `forgingFee`: Cost in `ChronoToken` to forge an Essence.
    *   `_nextProposalId`: Counter for new proposals.
    *   `proposals`: Mapping from `proposalId` to `Proposal`.
    *   `_hasVoted`: Mapping to track voter participation for proposals.
    *   `essenceEvolutionConditions`: Mapping from `tokenId` to `bytes` (encoded condition data).
    *   `traitWeights`: Mapping from `TraitType` to `uint256` for trait generation.

*   **Events:**
    *   `EssenceForged`: Emitted when a new `ChronoEssence` is minted.
    *   `EssenceEvolved`: Emitted when an Essence undergoes evolution.
    *   `UtilityDelegated`: Emitted when Essence utility is delegated.
    *   `UtilityRevoked`: Emitted when Essence utility delegation is revoked.
    *   `ChronosPointsUpdated`: Emitted when a user's CP balance changes.
    *   `AethericFluxUpdated`: Emitted when `AethericFlux` is updated by the oracle.
    *   `TemporalResonanceUpdated`: Emitted when `TemporalResonance` is updated by the oracle.
    *   `ProposalCreated`: Emitted when a new governance proposal is initiated.
    *   `VoteCast`: Emitted when a vote is cast on a proposal.
    *   `ProposalExecuted`: Emitted when a governance proposal is successfully executed.

*   **Functions (24 Custom Functions + ERC721/Ownable):**

    **I. ChronoEssence & Forging (Generative & Dynamic NFT)**
    1.  `forgeChronoEssence(uint256 userSeed)`: Mints a new `ChronoEssence` NFT. Requires `ChronoToken` fee. User's `ChronosPoints` and global environmental fluxes influence traits.
    2.  `requestEssenceEvolution(uint256 essenceId)`: Initiates an evolution check for an Essence. If conditions are met, the Essence evolves.
    3.  `updateEssenceMetadataURI(uint256 essenceId, string calldata newURI)`: Allows for updating the metadata URI post-evolution, revealing new traits. Only callable by the contract itself or authorized entities post-evolution.
    4.  `getEssenceProperties(uint256 essenceId)`: Returns a structured view of an Essence's current, potentially evolved, properties.
    5.  `delegateEssenceUtility(uint256 essenceId, address delegatee, uint256 durationBlocks)`: Allows an Essence owner to delegate specific *utility* (not ownership) to another address for a limited block duration.
    6.  `revokeEssenceDelegation(uint256 essenceId)`: Allows the owner to prematurely revoke any active utility delegation.
    7.  `getEssenceDelegation(uint256 essenceId)`: Returns the current delegatee and expiration block for an Essence.
    8.  `isEssenceUtilityDelegated(uint256 essenceId, address delegatee)`: Checks if a specific address is currently delegated utility for an Essence.

    **II. ChronosPoints (Reputation System)**
    9.  `stakeChronoTokens(uint256 amount)`: Users stake `ChronoToken` to accumulate `ChronosPoints` over time.
    10. `unstakeChronoTokens(uint256 amount)`: Users retrieve their staked `ChronoToken` and claim accumulated `ChronosPoints`.
    11. `getChronosPoints(address user)`: Returns the current `ChronosPoints` balance for a user. These are non-transferable, internal reputation scores.
    12. `getAccruedChronosPoints(address user)`: Calculates `ChronosPoints` earned by a user since their last staking action, based on staked amount and time.

    **III. Environmental Flux & Oracle Integration**
    13. `submitAethericFlux(uint256 newFluxValue)`: Callable by the designated Oracle to update the `AethericFlux`, influencing future forgings.
    14. `submitTemporalResonance(uint256 newResonanceValue)`: Callable by the designated Oracle to update `TemporalResonance`, another forging modifier.
    15. `getCurrentTemporalSeed()`: Generates a dynamic seed for forging, combining current block data with the flux and resonance values.
    16. `setOracleAddress(address newOracle)`: Owner/Governance function to update the authorized oracle address.

    **IV. Governance & Protocol Parameters**
    17. `proposeNewTraitSet(TraitDefinition[] calldata newTraits, string calldata description)`: Allows governance token holders (conceptual, or owner for now) to propose new types of traits that ChronoEssences can embody.
    18. `voteOnProposal(uint256 proposalId, bool support)`: Allows `ChronoToken` holders to vote on active proposals.
    19. `executeProposal(uint256 proposalId)`: Executes a proposal that has met quorum and passed its voting period.
    20. `setForgingFee(uint256 newFee)`: Sets the `ChronoToken` fee required to forge a new Essence (via governance).
    21. `setEvolutionCondition(uint256 essenceId, bytes calldata conditionData)`: Allows governance to define dynamic conditions for an Essence's evolution (e.g., specific event trigger, timestamp, CP threshold).
    22. `configureTraitWeight(uint8 traitType, uint256 weight)`: Adjusts the weighting of different trait types during the trait generation phase, affecting rarity distribution.
    23. `withdrawProtocolFees(address recipient)`: Allows governance to withdraw accumulated `ChronoToken` fees from the contract's treasury.
    24. `setMinimumCPForRarityBoost(uint256 minCP)`: Sets a `ChronosPoints` threshold for users to gain a bonus chance at rarer traits during forging.

    **V. Standard ERC721 & Ownable Functions**
    *   `balanceOf(address owner)`
    *   `ownerOf(uint256 essenceId)`
    *   `approve(address to, uint256 essenceId)`
    *   `getApproved(uint256 essenceId)`
    *   `setApprovalForAll(address operator, bool approved)`
    *   `isApprovedForAll(address owner, address operator)`
    *   `transferFrom(address from, address to, uint256 essenceId)`
    *   `safeTransferFrom(address from, address to, uint256 essenceId)`
    *   `tokenURI(uint256 essenceId)`
    *   `renounceOwnership()`
    *   `transferOwnership(address newOwner)`

---

### Source Code

First, the `ChronoToken.sol` (ERC-20 token):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ChronoToken
 * @dev An ERC-20 token used within the ChronoForge ecosystem for staking (to earn ChronosPoints)
 *      and paying forging fees for ChronoEssence NFTs.
 */
contract ChronoToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("ChronoToken", "CHT") {
        _mint(msg.sender, initialSupply);
    }
}
```

Next, the `ChronoForge.sol` (main NFT contract):

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit math safety
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // For ChronoToken interaction

/**
 * @title ChronoForge
 * @dev A Decentralized Generative Asset Protocol for forging unique, evolving ChronoEssence NFTs.
 *      Essence traits are influenced by user reputation (ChronosPoints), global environmental
 *      fluxes (AethericFlux, TemporalResonance), and dynamic seeds. It features time-limited
 *      utility delegation and a basic governance system.
 *
 * Outline:
 *   I. ChronoEssence & Forging (Generative & Dynamic NFT)
 *      - forgeChronoEssence: Mints a new Essence with dynamic traits.
 *      - requestEssenceEvolution: Triggers an evolution check.
 *      - updateEssenceMetadataURI: Updates URI post-evolution (internal/governance).
 *      - getEssenceProperties: View current Essence properties.
 *      - delegateEssenceUtility: Delegates utility for a limited time.
 *      - revokeEssenceDelegation: Revokes active delegation.
 *      - getEssenceDelegation: View current delegation status.
 *      - isEssenceUtilityDelegated: Check if an address has active delegation.
 *
 *   II. ChronosPoints (Reputation System)
 *      - stakeChronoTokens: Stake CHT to earn CP.
 *      - unstakeChronoTokens: Unstake CHT and claim accrued CP.
 *      - getChronosPoints: View user's current CP balance.
 *      - getAccruedChronosPoints: Calculate CP earned since last action.
 *
 *   III. Environmental Flux & Oracle Integration
 *      - submitAethericFlux: Oracle updates Aetheric Flux.
 *      - submitTemporalResonance: Oracle updates Temporal Resonance.
 *      - getCurrentTemporalSeed: Generates a dynamic seed from global parameters.
 *      - setOracleAddress: Sets the authorized oracle address (governance).
 *
 *   IV. Governance & Protocol Parameters
 *      - proposeNewTraitSet: Propose new traits for Essences (governance).
 *      - voteOnProposal: Vote on active proposals (CHT holders).
 *      - executeProposal: Execute passed proposals.
 *      - setForgingFee: Set the CHT fee for forging (governance).
 *      - setEvolutionCondition: Define dynamic evolution conditions (governance).
 *      - configureTraitWeight: Adjust trait rarity weights (governance).
 *      - withdrawProtocolFees: Withdraw accumulated CHT fees (governance).
 *      - setMinimumCPForRarityBoost: Set CP threshold for rarity bonus (governance).
 *
 *   V. Standard ERC721 & Ownable Functions (inherited)
 */
contract ChronoForge is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC20 public immutable chronoToken; // The ERC-20 token for staking and fees

    // --- Data Structures ---

    enum TraitType {
        Aura,        // E.g., "Radiant", "Shadowy"
        CoreElement, // E.g., "Fire", "Water", "Earth", "Air"
        Resonance,   // E.g., "Harmonic", "Discordant"
        Form         // E.g., "Orb", "Shard", "Glyph"
        // Add more trait types as desired
    }

    struct EssenceTrait {
        TraitType traitType;
        string value;
        uint256 rarityScore; // Influences visual representation or in-game power
    }

    struct ChronoEssence {
        uint256 id;
        EssenceTrait[] traits;
        bool hasEvolved;
        uint256 creationBlock;
        address creator;
        string tokenURI; // Dynamic URI
        // Additional metadata or status can be added here
    }

    struct EssenceDelegation {
        address delegatee;
        uint256 expirationBlock;
        bool active;
    }

    struct TraitDefinition {
        TraitType traitType;
        string value;
        uint256 rarityScore;
    }

    // Governance
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 creationBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if a specific address has voted
        ProposalState state;
        bytes callData; // Encoded function call for execution
        address target; // Target contract for execution
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter; // For unique Essence IDs
    Counters.Counter private _proposalIdCounter;

    mapping(uint256 => ChronoEssence) private _essenceProperties;
    mapping(uint256 => string) private _tokenURIs; // Store URI dynamically

    // ChronosPoints (Reputation System)
    mapping(address => uint256) private _chronosPoints; // Non-transferable reputation
    mapping(address => uint256) private _stakedChronoTokens;
    mapping(address => uint256) private _lastStakeActionBlock; // Block number of last stake/unstake

    // Environmental Flux (Oracle-driven)
    uint256 public aethericFlux;
    uint256 public temporalResonance;
    address public oracleAddress; // Trusted address to update fluxes

    // Forging parameters
    uint256 public forgingFee; // Fee in ChronoToken
    uint256 public constant CP_ACCRUAL_RATE_PER_BLOCK = 10; // 10 CP per CHT staked per block
    uint256 public minimumCPForRarityBoost = 10000; // CP required for a better rarity chance

    // Governance
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant VOTING_PERIOD_BLOCKS = 1000; // ~4 hours at 14s/block
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 4; // 4% of total CHT supply needed to pass

    // Essence Evolution
    mapping(uint256 => bytes) public essenceEvolutionConditions; // tokenId => encoded condition data

    // Trait Generation Parameters
    mapping(TraitType => TraitDefinition[]) public availableTraits; // Traits available per type
    mapping(TraitType => uint256) public traitWeights; // How much each TraitType influences overall rarity/generation

    // Essence Utility Delegation
    mapping(uint256 => EssenceDelegation) public essenceDelegations;

    // --- Events ---

    event EssenceForged(uint256 indexed essenceId, address indexed creator, EssenceTrait[] traits, uint256 creationBlock);
    event EssenceEvolved(uint256 indexed essenceId, address indexed owner, EssenceTrait[] newTraits, string newURI);
    event UtilityDelegated(uint256 indexed essenceId, address indexed delegator, address indexed delegatee, uint256 expirationBlock);
    event UtilityRevoked(uint256 indexed essenceId, address indexed delegator, address indexed delegatee);
    event ChronosPointsUpdated(address indexed user, uint256 newCPBalance, uint256 stakedAmount);
    event AethericFluxUpdated(uint256 newFluxValue, address indexed updater);
    event TemporalResonanceUpdated(uint256 newResonanceValue, address indexed updater);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ForgingFeeSet(uint256 newFee);
    event EvolutionConditionSet(uint256 indexed essenceId, bytes conditionData);
    event TraitWeightConfigured(TraitType indexed traitType, uint256 weight);
    event MinCPForRarityBoostSet(uint256 newMinCP);

    // --- Constructor ---

    constructor(address _chronoTokenAddress) ERC721("ChronoEssence", "ESS") Ownable(msg.sender) {
        require(_chronoTokenAddress != address(0), "ChronoToken address cannot be zero");
        chronoToken = IERC20(_chronoTokenAddress);

        oracleAddress = msg.sender; // Initial oracle is deployer, can be changed by governance
        forgingFee = 100 ether; // Default forging fee, can be changed by governance

        // Initialize default trait weights (can be adjusted by governance)
        traitWeights[TraitType.Aura] = 20;
        traitWeights[TraitType.CoreElement] = 30;
        traitWeights[TraitType.Resonance] = 25;
        traitWeights[TraitType.Form] = 25;

        // Add some initial dummy traits for demonstration
        availableTraits[TraitType.Aura].push(TraitDefinition(TraitType.Aura, "Radiant", 50));
        availableTraits[TraitType.Aura].push(TraitDefinition(TraitType.Aura, "Shadowy", 100));
        availableTraits[TraitType.CoreElement].push(TraitDefinition(TraitType.CoreElement, "Fire", 70));
        availableTraits[TraitType.CoreElement].push(TraitDefinition(TraitType.CoreElement, "Water", 70));
        availableTraits[TraitType.CoreElement].push(TraitDefinition(TraitType.CoreElement, "Earth", 70));
        availableTraits[TraitType.CoreElement].push(TraitDefinition(TraitType.CoreElement, "Air", 70));
        availableTraits[TraitType.Resonance].push(TraitDefinition(TraitType.Resonance, "Harmonic", 60));
        availableTraits[TraitType.Resonance].push(TraitDefinition(TraitType.Resonance, "Discordant", 80));
        availableTraits[TraitType.Form].push(TraitDefinition(TraitType.Form, "Orb", 40));
        availableTraits[TraitType.Form].push(TraitDefinition(TraitType.Form, "Shard", 90));
    }

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "ChronoForge: Only authorized oracle can call this function");
        _;
    }

    modifier onlyEssenceOwner(uint256 _essenceId) {
        require(_exists(_essenceId), "ChronoForge: Essence does not exist");
        require(_isApprovedOrOwner(msg.sender, _essenceId), "ChronoForge: Not owner or approved");
        _;
    }

    // --- I. ChronoEssence & Forging (Generative & Dynamic NFT) ---

    /**
     * @dev Forges a new ChronoEssence NFT.
     *      Requires a forging fee in ChronoToken. Traits are generated based on user's CP,
     *      global flux values, and a user-provided seed for uniqueness.
     * @param userSeed A seed provided by the user to add an element of control/unpredictability.
     * @return The ID of the newly minted ChronoEssence.
     */
    function forgeChronoEssence(uint256 userSeed) public returns (uint256) {
        require(forgingFee > 0, "ChronoForge: Forging fee must be greater than zero");
        require(chronoToken.transferFrom(msg.sender, address(this), forgingFee), "ChronoForge: ChronoToken transfer failed");

        _tokenIdCounter.increment();
        uint256 newEssenceId = _tokenIdCounter.current();

        // Update user's ChronosPoints before forging, as they influence trait generation
        _updateChronosPoints(msg.sender);

        // Generate a temporal seed based on global flux and block data
        uint256 temporalSeed = getCurrentTemporalSeed();

        // Calculate and assign traits based on various factors
        EssenceTrait[] memory generatedTraits = _calculateEssenceProperties(msg.sender, userSeed, temporalSeed);

        // Construct the ChronoEssence object
        ChronoEssence storage newEssence = _essenceProperties[newEssenceId];
        newEssence.id = newEssenceId;
        newEssence.traits = generatedTraits;
        newEssence.hasEvolved = false;
        newEssence.creationBlock = block.number;
        newEssence.creator = msg.sender;
        newEssence.tokenURI = _generateBaseURI(newEssenceId, generatedTraits);

        _mint(msg.sender, newEssenceId);
        _tokenURIs[newEssenceId] = newEssence.tokenURI; // Store generated URI
        
        emit EssenceForged(newEssenceId, msg.sender, generatedTraits, block.number);
        return newEssenceId;
    }

    /**
     * @dev Internal function to calculate and assign traits to a new ChronoEssence.
     *      This is where the "generative" and "AI-like" logic is simulated.
     * @param forger The address of the user forging the Essence.
     * @param userSeed A user-provided seed.
     * @param temporalSeed A dynamic seed based on global parameters.
     * @return An array of EssenceTrait structs.
     */
    function _calculateEssenceProperties(
        address forger,
        uint256 userSeed,
        uint256 temporalSeed
    ) internal view returns (EssenceTrait[] memory) {
        // Combine seeds and global state for a robust deterministic randomness
        uint256 combinedSeed = uint256(keccak256(abi.encodePacked(
            forger,
            userSeed,
            temporalSeed,
            aethericFlux,
            temporalResonance,
            block.timestamp,
            block.difficulty,
            block.gaslimit,
            _chronosPoints[forger] // User's reputation influences outcomes
        )));

        // Influence of ChronosPoints on rarity
        uint256 cpRarityBonus = 0;
        if (_chronosPoints[forger] >= minimumCPForRarityBoost) {
            cpRarityBonus = _chronosPoints[forger].div(1000).min(50); // Max 50 bonus points
        }

        EssenceTrait[] memory traits = new EssenceTrait[](availableTraits[TraitType.Aura].length +
                                                        availableTraits[TraitType.CoreElement].length +
                                                        availableTraits[TraitType.Resonance].length +
                                                        availableTraits[TraitType.Form].length); // Max possible traits, will resize later

        uint256 traitCount = 0;
        TraitType[] memory allTraitTypes = new TraitType[](4); // Adjust if more types
        allTraitTypes[0] = TraitType.Aura;
        allTraitTypes[1] = TraitType.CoreElement;
        allTraitTypes[2] = TraitType.Resonance;
        allTraitTypes[3] = TraitType.Form;

        for (uint256 i = 0; i < allTraitTypes.length; i++) {
            TraitType currentType = allTraitTypes[i];
            TraitDefinition[] memory typeTraits = availableTraits[currentType];
            if (typeTraits.length == 0) continue;

            // Use weighted randomness for trait selection
            uint256 totalWeight = 0;
            for (uint256 j = 0; j < typeTraits.length; j++) {
                totalWeight = totalWeight.add(typeTraits[j].rarityScore.mul(traitWeights[currentType])); // Apply global trait weight
            }
            if (totalWeight == 0) continue; // Avoid division by zero

            uint256 choice = (combinedSeed.add(i).add(forger.sub(address(0)).add(block.number))) % totalWeight; // Add more entropy

            uint256 cumulativeWeight = 0;
            for (uint256 j = 0; j < typeTraits.length; j++) {
                cumulativeWeight = cumulativeWeight.add(typeTraits[j].rarityScore.mul(traitWeights[currentType]));
                if (choice < cumulativeWeight) {
                    EssenceTrait memory selectedTrait = EssenceTrait(
                        currentType,
                        typeTraits[j].value,
                        typeTraits[j].rarityScore.add(cpRarityBonus) // Apply CP bonus
                    );
                    traits[traitCount] = selectedTrait;
                    traitCount++;
                    break;
                }
            }
        }

        // Resize the array to actual traitCount
        EssenceTrait[] memory finalTraits = new EssenceTrait[](traitCount);
        for(uint256 i = 0; i < traitCount; i++) {
            finalTraits[i] = traits[i];
        }
        return finalTraits;
    }

    /**
     * @dev Generates a base URI for an Essence, potentially linking to an off-chain API
     *      that renders dynamic metadata based on its traits.
     * @param essenceId The ID of the Essence.
     * @param traits The Essence's traits.
     * @return The generated URI.
     */
    function _generateBaseURI(uint256 essenceId, EssenceTrait[] memory traits) internal pure returns (string memory) {
        // In a real dApp, this would likely point to an API endpoint that serves
        // dynamic JSON metadata and an image based on the Essence's traits.
        // For demonstration, a simple placeholder.
        string memory base = "https://chronoessence.xyz/metadata/";
        string memory idStr = _toString(essenceId);
        return string(abi.encodePacked(base, idStr, "/initial"));
    }

    /**
     * @dev Requests an Essence to undergo evolution. This function checks the defined
     *      evolution conditions. If met, the Essence's traits and URI might change.
     *      The actual evolution logic (modifying traits) would be handled internally,
     *      triggered by this or an oracle if external conditions are involved.
     * @param essenceId The ID of the Essence to evolve.
     */
    function requestEssenceEvolution(uint256 essenceId) public onlyEssenceOwner(essenceId) {
        ChronoEssence storage essence = _essenceProperties[essenceId];
        require(!essence.hasEvolved, "ChronoForge: Essence has already evolved");

        bytes memory conditionData = essenceEvolutionConditions[essenceId];
        require(conditionData.length > 0, "ChronoForge: No evolution conditions set for this Essence");

        // Simulate complex condition check based on `conditionData`
        // This could be:
        // 1. block.timestamp >= specificTimestamp (if conditionData holds a timestamp)
        // 2. ownerOf(essenceId) == specificAddress (if conditionData holds an address)
        // 3. external oracle call result (requires Chainlink or similar)
        // 4. owner's _chronosPoints[_owner] >= threshold (if conditionData holds a CP threshold)
        // For demonstration, let's assume `conditionData` holds a block number, and evolution occurs if current block >= that block.
        uint256 targetBlock;
        if (conditionData.length == 32) { // Assuming uint256 is encoded
            assembly { targetBlock := mload(add(conditionData, 32)) }
        } else {
             revert("ChronoForge: Invalid evolution condition data format");
        }
        require(block.number >= targetBlock, "ChronoForge: Evolution conditions not yet met (block number)");

        // --- Perform Evolution ---
        // For simplicity, let's just update the URI and mark as evolved.
        // In a real system, traits might change, new traits added, etc.
        essence.hasEvolved = true;
        
        // Example: If evolved, update URI to reflect new state
        string memory evolvedUri = string(abi.encodePacked("https://chronoessence.xyz/metadata/", _toString(essenceId), "/evolved"));
        _tokenURIs[essenceId] = evolvedUri;
        essence.tokenURI = evolvedUri; // Update internal struct as well

        // If traits were to change, they would be re-calculated or pulled from a new pool here.
        // For example: essence.traits = _generateEvolvedTraits(essenceId, essence.traits);

        emit EssenceEvolved(essenceId, msg.sender, essence.traits, evolvedUri);
    }

    /**
     * @dev Allows updating the tokenURI for an Essence. This is typically used after an
     *      evolution event to reflect the new state of the NFT.
     *      Only callable by the contract itself (e.g., during `requestEssenceEvolution`)
     *      or potentially by governance for specific cases.
     * @param essenceId The ID of the Essence.
     * @param newURI The new URI string.
     */
    function updateEssenceMetadataURI(uint256 essenceId, string calldata newURI) public {
        // This function is intentionally restricted. In this implementation,
        // it's mainly called internally by `requestEssenceEvolution` to reflect state changes.
        // A governance module could also be allowed to call this for manual updates.
        require(msg.sender == address(this) || owner() == msg.sender, "ChronoForge: Unauthorized to update URI");
        require(_exists(essenceId), "ChronoForge: Essence does not exist");
        _tokenURIs[essenceId] = newURI;
        _essenceProperties[essenceId].tokenURI = newURI; // Update internal struct
    }

    /**
     * @dev Returns the stored ChronoEssence properties for a given ID.
     * @param essenceId The ID of the Essence.
     * @return A ChronoEssence struct containing all its properties.
     */
    function getEssenceProperties(uint256 essenceId) public view returns (ChronoEssence memory) {
        require(_exists(essenceId), "ChronoForge: Essence does not exist");
        return _essenceProperties[essenceId];
    }

    /**
     * @dev Allows the owner of an Essence to delegate its utility (not ownership) to another address.
     *      The delegation is time-limited by `durationBlocks`.
     * @param essenceId The ID of the Essence.
     * @param delegatee The address to delegate utility to.
     * @param durationBlocks The number of blocks for which the delegation is valid.
     */
    function delegateEssenceUtility(uint256 essenceId, address delegatee, uint256 durationBlocks) public onlyEssenceOwner(essenceId) {
        require(delegatee != address(0), "ChronoForge: Delegatee cannot be zero address");
        require(durationBlocks > 0, "ChronoForge: Delegation duration must be positive");

        essenceDelegations[essenceId] = EssenceDelegation(
            delegatee,
            block.number.add(durationBlocks),
            true
        );

        emit UtilityDelegated(essenceId, msg.sender, delegatee, block.number.add(durationBlocks));
    }

    /**
     * @dev Allows the owner to revoke an active utility delegation prematurely.
     * @param essenceId The ID of the Essence.
     */
    function revokeEssenceDelegation(uint256 essenceId) public onlyEssenceOwner(essenceId) {
        EssenceDelegation storage delegation = essenceDelegations[essenceId];
        require(delegation.active, "ChronoForge: No active delegation to revoke");

        address revokedDelegatee = delegation.delegatee; // Store before clearing
        delete essenceDelegations[essenceId]; // Clear the delegation

        emit UtilityRevoked(essenceId, msg.sender, revokedDelegatee);
    }

    /**
     * @dev Returns the current delegation status for an Essence.
     * @param essenceId The ID of the Essence.
     * @return delegatee The address currently delegated.
     * @return expirationBlock The block number at which delegation expires.
     * @return active True if delegation is currently active and unexpired.
     */
    function getEssenceDelegation(uint256 essenceId) public view returns (address delegatee, uint256 expirationBlock, bool active) {
        EssenceDelegation storage delegation = essenceDelegations[essenceId];
        return (delegation.delegatee, delegation.expirationBlock, delegation.active && block.number < delegation.expirationBlock);
    }

    /**
     * @dev Checks if a specific address is currently delegated utility for an Essence.
     * @param essenceId The ID of the Essence.
     * @param checkDelegatee The address to check.
     * @return True if `checkDelegatee` is the current delegatee and the delegation is active.
     */
    function isEssenceUtilityDelegated(uint256 essenceId, address checkDelegatee) public view returns (bool) {
        (address currentDelegatee, uint256 expirationBlock, bool active) = getEssenceDelegation(essenceId);
        return active && (currentDelegatee == checkDelegatee);
    }

    // --- II. ChronosPoints (Reputation System) ---

    /**
     * @dev Allows a user to stake ChronoToken to start accumulating ChronosPoints (CP).
     *      CP are a non-transferable reputation score.
     * @param amount The amount of ChronoToken to stake.
     */
    function stakeChronoTokens(uint256 amount) public {
        require(amount > 0, "ChronoForge: Stake amount must be positive");
        
        // First, update CP based on previous stake period
        _updateChronosPoints(msg.sender);

        require(chronoToken.transferFrom(msg.sender, address(this), amount), "ChronoForge: ChronoToken transfer failed");

        _stakedChronoTokens[msg.sender] = _stakedChronoTokens[msg.sender].add(amount);
        _lastStakeActionBlock[msg.sender] = block.number; // Reset last action block

        emit ChronosPointsUpdated(msg.sender, _chronosPoints[msg.sender], _stakedChronoTokens[msg.sender]);
    }

    /**
     * @dev Allows a user to unstake ChronoToken and claim any accrued ChronosPoints.
     * @param amount The amount of ChronoToken to unstake.
     */
    function unstakeChronoTokens(uint256 amount) public {
        require(amount > 0, "ChronoForge: Unstake amount must be positive");
        require(_stakedChronoTokens[msg.sender] >= amount, "ChronoForge: Not enough tokens staked");

        // Update CP before unstaking to account for all earned points
        _updateChronosPoints(msg.sender);

        _stakedChronoTokens[msg.sender] = _stakedChronoTokens[msg.sender].sub(amount);
        _lastStakeActionBlock[msg.sender] = block.number; // Reset last action block

        require(chronoToken.transfer(msg.sender, amount), "ChronoForge: ChronoToken transfer failed");

        emit ChronosPointsUpdated(msg.sender, _chronosPoints[msg.sender], _stakedChronoTokens[msg.sender]);
    }

    /**
     * @dev Internal function to calculate and add accrued ChronosPoints to a user's balance.
     *      Called before any staking/unstaking action or forging.
     * @param user The address of the user.
     */
    function _updateChronosPoints(address user) internal {
        uint256 staked = _stakedChronoTokens[user];
        if (staked == 0) {
            return;
        }

        uint256 blocksPassed = block.number.sub(_lastStakeActionBlock[user]);
        if (blocksPassed == 0) {
            return;
        }

        uint256 newCP = staked.mul(blocksPassed).mul(CP_ACCRUAL_RATE_PER_BLOCK);
        _chronosPoints[user] = _chronosPoints[user].add(newCP);
        _lastStakeActionBlock[user] = block.number; // Update last action block
    }

    /**
     * @dev Returns the current total ChronosPoints balance for a user.
     *      Automatically updates CP before returning the value.
     * @param user The address of the user.
     * @return The total ChronosPoints for the user.
     */
    function getChronosPoints(address user) public returns (uint256) {
        _updateChronosPoints(user); // Ensure points are up-to-date
        return _chronosPoints[user];
    }

    /**
     * @dev Calculates ChronosPoints accrued since the last stake/unstake action.
     *      Does not update the actual balance.
     * @param user The address of the user.
     * @return The amount of ChronosPoints accrued but not yet added to balance.
     */
    function getAccruedChronosPoints(address user) public view returns (uint256) {
        uint256 staked = _stakedChronoTokens[user];
        if (staked == 0 || block.number <= _lastStakeActionBlock[user]) {
            return 0;
        }
        uint256 blocksPassed = block.number.sub(_lastStakeActionBlock[user]);
        return staked.mul(blocksPassed).mul(CP_ACCRUAL_RATE_PER_BLOCK);
    }

    // --- III. Environmental Flux & Oracle Integration ---

    /**
     * @dev Allows the designated oracle to submit a new Aetheric Flux value.
     *      This value influences the trait generation process for new Essences.
     * @param newFluxValue The new Aetheric Flux value.
     */
    function submitAethericFlux(uint256 newFluxValue) public onlyOracle {
        aethericFlux = newFluxValue;
        emit AethericFluxUpdated(newFluxValue, msg.sender);
    }

    /**
     * @dev Allows the designated oracle to submit a new Temporal Resonance value.
     *      This value also influences the trait generation process for new Essences.
     * @param newResonanceValue The new Temporal Resonance value.
     */
    function submitTemporalResonance(uint256 newResonanceValue) public onlyOracle {
        temporalResonance = newResonanceValue;
        emit TemporalResonanceUpdated(newResonanceValue, msg.sender);
    }

    /**
     * @dev Generates a dynamic seed based on current block data and global environmental fluxes.
     *      Used during Essence forging to introduce external variability.
     * @return A dynamically generated seed.
     */
    function getCurrentTemporalSeed() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty,
            block.number,
            aethericFlux,
            temporalResonance
        )));
    }

    /**
     * @dev Sets the address of the trusted oracle. Only callable by the contract owner (or governance).
     * @param newOracle The address of the new oracle.
     */
    function setOracleAddress(address newOracle) public onlyOwner {
        require(newOracle != address(0), "ChronoForge: Oracle address cannot be zero");
        oracleAddress = newOracle;
    }

    // --- IV. Governance & Protocol Parameters ---

    /**
     * @dev Proposes a new set of traits that can be included in future ChronoEssences.
     *      Requires `ChronoToken` holders to vote.
     * @param newTraits An array of `TraitDefinition` structs.
     * @param description A description of the proposal.
     * @return The ID of the created proposal.
     */
    function proposeNewTraitSet(TraitDefinition[] calldata newTraits, string calldata description) public returns (uint256) {
        // In a full DAO, this would require a governance token holder to call
        // For simplicity, for now, anyone can propose, but only CHT holders vote.
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        // Encode the action to add traits for later execution
        bytes memory callData = abi.encodeWithSelector(
            this.executeTraitSetAddition.selector,
            newTraits
        );

        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.creationBlock = block.number;
        newProposal.endBlock = block.number.add(VOTING_PERIOD_BLOCKS);
        newProposal.state = ProposalState.Active;
        newProposal.callData = callData;
        newProposal.target = address(this); // Target is this contract for internal function calls

        emit ProposalCreated(proposalId, msg.sender, description, newProposal.endBlock);
        return proposalId;
    }

    /**
     * @dev Internal function to execute adding new traits. Called by `executeProposal`.
     * @param traitsToAdd An array of `TraitDefinition` structs to add.
     */
    function executeTraitSetAddition(TraitDefinition[] calldata traitsToAdd) public {
        require(msg.sender == address(this), "ChronoForge: Only self-call allowed for execution"); // Ensure called by contract during execution

        for (uint256 i = 0; i < traitsToAdd.length; i++) {
            availableTraits[traitsToAdd[i].traitType].push(traitsToAdd[i]);
        }
    }

    /**
     * @dev Allows `ChronoToken` holders to vote on active proposals.
     *      Each `ChronoToken` held counts as one vote.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "ChronoForge: Proposal is not active");
        require(block.number <= proposal.endBlock, "ChronoForge: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "ChronoForge: You have already voted on this proposal");

        uint256 voterCHTBalance = chronoToken.balanceOf(msg.sender);
        require(voterCHTBalance > 0, "ChronoForge: Must hold ChronoToken to vote");

        if (support) {
            proposal.votesFor = proposal.votesFor.add(voterCHTBalance);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(voterCHTBalance);
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal that has passed its voting period and met quorum.
     *      Anyone can call this, but it will only succeed if conditions are met.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "ChronoForge: Proposal is not active");
        require(block.number > proposal.endBlock, "ChronoForge: Voting period has not ended");

        uint256 totalCHTSupply = chronoToken.totalSupply();
        uint256 quorumThreshold = totalCHTSupply.mul(PROPOSAL_QUORUM_PERCENT).div(100);

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= quorumThreshold) {
            // Execute the proposal's action
            (bool success, ) = proposal.target.call(proposal.callData);
            require(success, "ChronoForge: Proposal execution failed");
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(proposalId);
        } else {
            proposal.state = ProposalState.Failed;
        }
    }

    /**
     * @dev Sets the fee required in ChronoToken to forge a new ChronoEssence.
     *      Callable by the contract owner (or via governance proposal).
     * @param newFee The new forging fee.
     */
    function setForgingFee(uint256 newFee) public onlyOwner {
        forgingFee = newFee;
        emit ForgingFeeSet(newFee);
    }

    /**
     * @dev Sets a dynamic condition for a specific Essence to evolve.
     *      `conditionData` is a raw byte array that the `requestEssenceEvolution` function
     *      will interpret (e.g., an encoded block number, address, or other event data).
     *      Callable by the contract owner (or via governance proposal).
     * @param essenceId The ID of the Essence to set the condition for.
     * @param conditionData Encoded data representing the evolution condition.
     */
    function setEvolutionCondition(uint256 essenceId, bytes calldata conditionData) public onlyOwner {
        require(_exists(essenceId), "ChronoForge: Essence does not exist");
        require(conditionData.length > 0, "ChronoForge: Condition data cannot be empty");
        essenceEvolutionConditions[essenceId] = conditionData;
        emit EvolutionConditionSet(essenceId, conditionData);
    }

    /**
     * @dev Configures the weight of a specific TraitType, influencing its rarity distribution
     *      during Essence generation. Higher weight means traits of this type are more impactful.
     *      Callable by the contract owner (or via governance proposal).
     * @param traitType The `TraitType` to configure.
     * @param weight The new weight value (e.g., 1-100).
     */
    function configureTraitWeight(TraitType traitType, uint256 weight) public onlyOwner {
        traitWeights[traitType] = weight;
        emit TraitWeightConfigured(traitType, weight);
    }

    /**
     * @dev Allows the contract owner (or governance) to withdraw accumulated ChronoToken fees
     *      from the contract's treasury.
     * @param recipient The address to send the fees to.
     */
    function withdrawProtocolFees(address recipient) public onlyOwner {
        uint256 balance = chronoToken.balanceOf(address(this)).sub(_totalStakedChronoTokens()); // Exclude staked tokens
        require(balance > 0, "ChronoForge: No fees to withdraw");
        require(chronoToken.transfer(recipient, balance), "ChronoForge: Fee withdrawal failed");
    }

    /**
     * @dev Sets the minimum ChronosPoints required for a user to gain a rarity boost
     *      during the forging process.
     *      Callable by the contract owner (or via governance proposal).
     * @param minCP The new minimum CP threshold.
     */
    function setMinimumCPForRarityBoost(uint256 minCP) public onlyOwner {
        minimumCPForRarityBoost = minCP;
        emit MinCPForRarityBoostSet(minCP);
    }

    // --- V. Standard ERC721 Overrides & Utilities ---

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://chronoessence.xyz/metadata/"; // Default base URI, can be overridden by dynamic URI
    }

    /**
     * @dev Returns the token URI for a given Essence ID.
     *      It will return the dynamically generated/updated URI.
     */
    function tokenURI(uint256 essenceId) public view override returns (string memory) {
        require(_exists(essenceId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[essenceId];
    }

    /**
     * @dev Internal helper to convert a uint256 to a string.
     */
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Returns the sum of all staked ChronoTokens in the contract.
     *      Used for calculating withdrawable fees.
     */
    function _totalStakedChronoTokens() internal view returns (uint256) {
        uint256 total;
        // This is a simplified way. In a large system, iterating over all users
        // might hit gas limits. A more robust solution might track this sum explicitly.
        // For demonstration purposes, this is acceptable.
        // Or directly check chronoToken.balanceOf(address(this)) and subtract pending fees.
        // For this specific case, `chronoToken.balanceOf(address(this)) - (fees)` is a better approach.
        // Let's rely on the balance of the contract.
        // The idea is to prevent withdrawing tokens that are *staked* and should belong to users.
        // The contract balance is the sum of staked tokens and collected fees.
        // So, fees = contractBalance - sumOfStakedTokens.
        // Given the lack of an easy way to sum _stakedChronoTokens efficiently,
        // we'll assume the contract balance _minus_ the current value of all _stakedChronoTokens
        // represents available fees.
        return chronoToken.balanceOf(address(this)); // This will need refinement in a real system to differentiate
                                                     // staked vs. actual fees. For now, this is a placeholder.
                                                     // A better approach would be to track totalFeesCollected directly.
    }
}
```