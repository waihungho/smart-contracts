This smart contract, `EvolvingDigitalGenesis`, presents a novel approach to dynamic NFTs (dNFTs) by integrating multiple influencing factors, a unique "influence" token mechanic, and a lightweight on-chain governance system. It aims to create digital assets that truly "evolve" based on user interaction, consumable items, and external, oracle-driven "global trends."

---

## EvolvingDigitalGenesis (EDG) Smart Contract

**Outline & Function Summary:**

This contract implements a system for "Genesis Shards," which are dynamic ERC721 NFTs. These shards possess mutable properties (aura, stability, entropy, resilience) that evolve through a unique combination of user "deeds," consumable "catalyst" items, and epoch-based, oracle-driven "mutation vectors." A lightweight on-chain governance mechanism allows the community to influence the global rules of evolution.

**I. Core Genesis Shard Management (ERC721-like)**
*   Manages the creation, ownership, and retrieval of Genesis Shard NFTs.
*   Each Shard possesses dynamic properties that change over time.

1.  `mintGenesisShard()`: Mints a new Genesis Shard NFT with initial properties for the caller.
2.  `getShardProperties(uint256 tokenId)`: Retrieves the current evolving properties (aura, stability, entropy, resilience, creation/last evolution epoch) of a specific Shard.
3.  `getCurrentEpoch()`: Returns the current global evolution epoch number, which dictates periods of change.
4.  `getShardEvolutionHistory(uint256 tokenId)`: Provides a concise log (as event hashes) of significant evolution events for a specific Shard across epochs.

**II. Influence & Catalyst Management (ERC1155-like + SBT-like Infusion)**
*   Defines two types of ERC1155 tokens: "Influence Essences" (non-transferable, awarded for specific deeds) and "Catalyst Cores" (consumable items that grant specific effects).
*   Mechanisms for users to apply these to their Shards to guide or accelerate evolution.

5.  `awardInfluenceEssence(address recipient, uint256 essenceType, uint256 amount)`: Admin function to award Soulbound-Token (SBT)-like Influence Essences to a user, potentially via a delegatee.
6.  `infuseInfluence(uint256 tokenId, uint256 essenceType, uint256 amount)`: Allows a Shard owner to consume (burn) Influence Essences to apply their effects, queuing them for the next evolution cycle.
7.  `mintCatalystCore(uint256 catalystType, address recipient, uint256 amount)`: Admin function to mint consumable Catalyst Cores, which provide immediate or powerful effects.
8.  `applyCatalyst(uint256 tokenId, uint256 catalystType)`: Allows a Shard owner to consume a Catalyst Core to immediately apply its unique evolutionary effect to their Shard.

**III. Evolution Mechanisms (Core Dynamic Logic)**
*   Implements the complex, multi-faceted logic for how Genesis Shards evolve.
*   Involves epoch transitions, integration of external oracle data, and property calculation.

9.  `requestEpochalMutationData()`: (Callable by Owner/Oracle System) Initiates a request for external "mutation data" (e.g., AI-generated prompts, global trends) for the next evolution epoch.
10. `fulfillEpochalMutation(uint256 epoch, bytes32 oracleDataHash, bytes memory data)`: (Callable by Oracle) Receives and processes the external mutation data for a specific epoch, which will influence all Shards.
11. `triggerShardEvolution(uint256 tokenId)`: User-initiated function to calculate and apply all pending evolutionary changes to their Shard, including infused influences and accumulated epochal mutations.
12. `calculateShardResonance(uint256 tokenId1, uint256 tokenId2)`: Calculates a "resonance score" between two Shards based on their current property similarity, useful for potential future social or gamified interactions.
13. `_evolveShardProperties(uint256 tokenId)`: Internal function encapsulating the core property evolution logic, applying both general decay/growth and oracle-driven mutations.

**IV. Community & Governance (Lightweight Decentralization)**
*   Allows community members to participate in the direction of the system, specifically by influencing the global evolution rules, not just a treasury.

14. `delegateInfluence(uint256 essenceType, address delegatee)`: Allows users to delegate future awarded Influence Essences to another address, enabling simple meta-governance or proxy participation.
15. `revokeInfluenceDelegation(uint256 essenceType)`: Revokes a previously set delegation for a specific Influence Essence type.
16. `proposeCollectiveEvolutionParameter(string memory parameterName, uint256 newValue, string memory description)`: Allows users with sufficient influence to propose changes to core global evolution parameters (e.g., decay rates, mutation chances).
17. `voteOnProposal(uint256 proposalId, bool support)`: Allows users with any Influence Essence to cast their vote on active proposals.
18. `executeProposal(uint256 proposalId)`: Executes a passed proposal if it has met the voting threshold and its voting period has ended, applying the new global evolution parameter.

**V. Information & Utility Functions**
*   Provides various getter functions for querying contract state and simulating effects, enhancing transparency and user experience.

19. `getPendingShardInfluences(uint256 tokenId)`: Returns a list of Influence Essences that have been infused into a Shard but not yet applied via `triggerShardEvolution`.
20. `getExpectedMutationEffect(uint256 tokenId, bytes memory simulatedOracleData)`: Simulates the potential effect of a given hypothetical oracle mutation on a specific Shard, without altering its state.
21. `getAvailableCatalysts(address owner)`: Lists all Catalyst Cores currently held by a specific owner and their respective amounts.
22. `getCurrentGlobalMutationVector()`: Returns the hash and raw data of the currently active global mutation vector provided by the oracle.
23. `getEpochDetails(uint256 epoch)`: Provides comprehensive details about a specific epoch, including its mutation data, timestamps, and fulfillment status.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // For URI generation

// --- OUTLINE & FUNCTION SUMMARY IS ABOVE THE CODE ---

contract EvolvingDigitalGenesis is ERC721URIStorage, ERC1155, Ownable {
    using Counters for Counters.Counter;

    // --- Helper Functions (to avoid duplicating OpenZeppelin's SafeMath for min/max/abs) ---
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function _abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    // --- State Variables ---

    // ERC721 Counters for Genesis Shards
    Counters.Counter private _genesisShardTokenIds;

    // --- Structs ---

    struct ShardProperties {
        uint256 aura;        // Represents spiritual energy, creativity (0-1000)
        uint256 stability;   // Represents resilience, resistance to entropy (0-1000)
        uint256 entropy;     // Represents decay, chaos, unpredictability (0-1000)
        uint256 resilience;  // Represents adaptability, recovery from change (0-1000)
        uint256 creationEpoch;
        uint256 lastEvolutionEpoch;
    }

    struct EpochData {
        bytes32 mutationVectorHash; // Hash of the raw oracle data for integrity
        bytes oracleData;           // The raw oracle data (e.g., AI-generated prompt, sentiment vector)
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool dataFulfilled;
    }

    struct Proposal {
        address proposer;
        string description;
        string parameterName;
        uint256 newValue;
        uint256 voteCountYes;
        uint256 voteCountNo;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
    }

    // --- Mappings & Storage ---

    // Genesis Shards
    mapping(uint256 => ShardProperties) private _genesisShardProperties;
    // History log: tokenId -> epoch -> event hash (for on-chain summary, full details from events)
    mapping(uint256 => mapping(uint256 => bytes32[])) private _shardEvolutionHistory;

    // Epoch Management
    uint256 public currentEpoch;
    uint256 public immutable epochDuration; // E.g., 7 days in seconds
    mapping(uint256 => EpochData) public epochDetails;
    address public immutable oracleAddress; // Address authorized to fulfill oracle data

    // Influence Essences (ERC1155 IDs, SBT-like)
    uint256 public constant INFLUENCE_ESSENCE_CURATOR = 1;
    uint256 public constant INFLUENCE_ESSENCE_INNOVATOR = 2;
    uint256 public constant INFLUENCE_ESSENCE_PHILANTHROPIST = 3;

    // Catalyst Cores (ERC1155 IDs, consumable)
    uint256 public constant CATALYST_CORE_STABILITY_BOOST = 101;
    uint256 public constant CATALYST_CORE_AURA_MUTATION = 102;

    // Pending influences for shards before they are applied via `triggerShardEvolution`
    mapping(uint256 => mapping(uint256 => uint256)) private _pendingShardInfluences; // tokenId -> essenceType -> amount

    // Delegation of Influence Essences for future awards
    mapping(address => mapping(uint256 => address)) private _delegatedInfluence; // delegator -> essenceType -> delegatee

    // Global Evolution Parameters (governed by community)
    mapping(string => uint256) private _globalEvolutionParameters;
    // Default parameters (example values)
    uint256 private constant GLOBAL_PARAM_AURA_INFLUENCE_FACTOR_DEFAULT = 10;
    uint256 private constant GLOBAL_PARAM_STABILITY_DECAY_RATE_DEFAULT = 5;
    uint256 private constant GLOBAL_PARAM_ENTROPY_MUTATION_CHANCE_DEFAULT = 20; // % chance

    // Proposals for governance
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    uint256 public constant PROPOSAL_VOTING_PERIOD = 3 days;
    uint256 public constant PROPOSAL_QUORUM_PERCENT = 5; // 5% of total influence (simplified: total essence minted)
    uint256 public constant PROPOSAL_APPROVAL_PERCENT = 60; // 60% of votes must be 'yes'

    // --- Events ---

    event ShardMinted(uint256 indexed tokenId, address indexed owner, uint256 creationEpoch);
    event InfluenceEssenceAwarded(address indexed recipient, uint256 indexed essenceType, uint256 amount);
    event InfluenceInfused(uint256 indexed tokenId, address indexed infuser, uint256 essenceType, uint256 amount);
    event CatalystApplied(uint256 indexed tokenId, address indexed applicant, uint256 catalystType);
    event EpochMutationRequested(uint256 indexed epoch, address indexed requester);
    event EpochMutationFulfilled(uint256 indexed epoch, bytes32 indexed mutationVectorHash);
    event ShardEvolved(uint256 indexed tokenId, uint256 newAura, uint256 newStability, uint256 newEntropy, uint256 newResilience, uint256 evolutionEpoch);
    event InfluenceDelegated(address indexed delegator, uint256 indexed essenceType, address indexed delegatee);
    event InfluenceDelegationRevoked(address indexed delegator, uint256 indexed essenceType);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string parameterName, uint256 newValue, uint256 endTime);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId, bool success);

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == oracleAddress, "EDG: Only oracle can call this function");
        _;
    }

    // --- Constructor ---

    constructor(
        address _oracleAddress,
        uint256 _epochDurationSeconds,
        string memory _erc721Name,
        string memory _erc721Symbol,
        string memory _erc1155Uri
    ) ERC721(_erc721Name, _erc721Symbol) ERC1155(_erc1155Uri) Ownable(msg.sender) {
        require(_oracleAddress != address(0), "EDG: Invalid oracle address");
        require(_epochDurationSeconds > 0, "EDG: Epoch duration must be positive");
        oracleAddress = _oracleAddress;
        epochDuration = _epochDurationSeconds;
        currentEpoch = 1; // Start from epoch 1
        epochDetails[currentEpoch].startTimestamp = block.timestamp;
        epochDetails[currentEpoch].endTimestamp = block.timestamp + epochDuration;

        // Set initial global evolution parameters
        _globalEvolutionParameters["auraInfluenceFactor"] = GLOBAL_PARAM_AURA_INFLUENCE_FACTOR_DEFAULT;
        _globalEvolutionParameters["stabilityDecayRate"] = GLOBAL_PARAM_STABILITY_DECAY_RATE_DEFAULT;
        _globalEvolutionParameters["entropyMutationChance"] = GLOBAL_PARAM_ENTROPY_MUTATION_CHANCE_DEFAULT;
    }

    // --- I. Core Genesis Shard Management ---

    /// @notice Mints a new Genesis Shard NFT.
    /// @dev Initial properties are set to a base value.
    /// @return The tokenId of the newly minted Shard.
    function mintGenesisShard() public returns (uint256) {
        _genesisShardTokenIds.increment();
        uint256 newTokenId = _genesisShardTokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, string.concat("ipfs://genesis_shard/", Strings.toString(newTokenId))); // Example URI

        _genesisShardProperties[newTokenId] = ShardProperties({
            aura: 500,
            stability: 500,
            entropy: 100, // Starts low, increases with chaos/mutations
            resilience: 200, // Starts with some ability to adapt
            creationEpoch: currentEpoch,
            lastEvolutionEpoch: currentEpoch
        });

        emit ShardMinted(newTokenId, msg.sender, currentEpoch);
        return newTokenId;
    }

    /// @notice Retrieves the current evolving properties of a specific Genesis Shard.
    /// @param tokenId The ID of the Shard.
    /// @return A tuple containing aura, stability, entropy, resilience, creationEpoch, and lastEvolutionEpoch.
    function getShardProperties(uint256 tokenId) public view returns (uint256 aura, uint256 stability, uint256 entropy, uint256 resilience, uint256 creationEpoch, uint256 lastEvolutionEpoch) {
        require(_exists(tokenId), "EDG: Shard does not exist");
        ShardProperties storage props = _genesisShardProperties[tokenId];
        return (props.aura, props.stability, props.entropy, props.resilience, props.creationEpoch, props.lastEvolutionEpoch);
    }

    /// @notice Returns the current global evolution epoch number.
    /// @return The current epoch ID.
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /// @notice Provides a concise log of significant evolution events for a specific Shard.
    /// @dev This returns hashes of events. Full event data can be retrieved from blockchain logs.
    /// @param tokenId The ID of the Shard.
    /// @return An array of arrays of bytes32 hashes, representing evolution events per epoch.
    function getShardEvolutionHistory(uint256 tokenId) public view returns (bytes32[][] memory) {
        require(_exists(tokenId), "EDG: Shard does not exist");
        
        ShardProperties storage props = _genesisShardProperties[tokenId];
        uint256 historyLength = currentEpoch - props.creationEpoch + 1;
        bytes32[][] memory fullHistory = new bytes32[][](historyLength);

        uint256 arrayIndex = 0;
        for (uint256 i = props.creationEpoch; i <= currentEpoch; i++) {
            // Check if there are specific events logged for this epoch
            if (_shardEvolutionHistory[tokenId][i].length > 0) {
                fullHistory[arrayIndex] = _shardEvolutionHistory[tokenId][i];
            } else {
                // If no specific internal logs, provide a placeholder for the epoch
                fullHistory[arrayIndex] = new bytes32[](1);
                fullHistory[arrayIndex][0] = keccak256(abi.encodePacked("No specific internal logs for epoch ", Strings.toString(i)));
            }
            arrayIndex++;
        }
        return fullHistory;
    }

    // --- II. Influence & Catalyst Management ---

    /// @notice Admin function to award Influence Essences to a user.
    /// @dev These essences are ERC1155 tokens, enforced as non-transferable (SBT-like) after minting.
    ///      Awards are directed to a delegatee if one is set.
    /// @param recipient The address to award the essence to (or whose delegation to follow).
    /// @param essenceType The type of Influence Essence (e.g., INFLUENCE_ESSENCE_CURATOR).
    /// @param amount The quantity of essence to award.
    function awardInfluenceEssence(address recipient, uint256 essenceType, uint256 amount) public onlyOwner {
        require(recipient != address(0), "EDG: Invalid recipient address");
        require(essenceType > 0 && essenceType < 100, "EDG: Invalid essence type"); // Essences 1-99
        require(amount > 0, "EDG: Amount must be positive");

        // Apply delegation if any
        address finalRecipient = _delegatedInfluence[recipient][essenceType] != address(0) ? _delegatedInfluence[recipient][essenceType] : recipient;

        _mint(finalRecipient, essenceType, amount, ""); // Minting ERC1155
        emit InfluenceEssenceAwarded(finalRecipient, essenceType, amount);
    }

    /// @notice User consumes Influence Essences to modify their Genesis Shard.
    /// @dev The actual property changes are applied when `triggerShardEvolution` is called.
    /// @param tokenId The ID of the Shard to infuse.
    /// @param essenceType The type of Influence Essence to infuse.
    /// @param amount The quantity of essence to infuse.
    function infuseInfluence(uint256 tokenId, uint256 essenceType, uint256 amount) public {
        require(_exists(tokenId), "EDG: Shard does not exist");
        require(ownerOf(tokenId) == msg.sender, "EDG: Not shard owner");
        require(balanceOf(msg.sender, essenceType) >= amount, "EDG: Not enough essence");
        require(essenceType > 0 && essenceType < 100, "EDG: Invalid essence type");

        _burn(msg.sender, essenceType, amount); // Consume ERC1155 essence
        _pendingShardInfluences[tokenId][essenceType] += amount;

        emit InfluenceInfused(tokenId, msg.sender, essenceType, amount);
    }

    /// @notice Admin function to mint Catalyst Cores.
    /// @dev Catalyst Cores are consumable ERC1155 items.
    /// @param catalystType The type of Catalyst Core (e.g., CATALYST_CORE_STABILITY_BOOST).
    /// @param recipient The address to receive the catalyst.
    /// @param amount The quantity of catalyst to mint.
    function mintCatalystCore(uint256 catalystType, address recipient, uint256 amount) public onlyOwner {
        require(recipient != address(0), "EDG: Invalid recipient address");
        require(catalystType >= 100, "EDG: Invalid catalyst type"); // Catalysts 100+
        require(amount > 0, "EDG: Amount must be positive");

        _mint(recipient, catalystType, amount, ""); // Minting ERC1155
    }

    /// @notice User consumes a Catalyst Core to apply a specific effect on their Shard.
    /// @dev The effect is applied immediately or queued for the next evolution cycle.
    /// @param tokenId The ID of the Shard to apply the catalyst to.
    /// @param catalystType The type of Catalyst Core to apply.
    function applyCatalyst(uint256 tokenId, uint256 catalystType) public {
        require(_exists(tokenId), "EDG: Shard does not exist");
        require(ownerOf(tokenId) == msg.sender, "EDG: Not shard owner");
        require(balanceOf(msg.sender, catalystType) >= 1, "EDG: Not enough catalyst");
        require(catalystType >= 100, "EDG: Invalid catalyst type");

        _burn(msg.sender, catalystType, 1); // Consume one ERC1155 catalyst

        ShardProperties storage props = _genesisShardProperties[tokenId];

        // Apply immediate effects of catalysts
        if (catalystType == CATALYST_CORE_STABILITY_BOOST) {
            props.stability = _min(props.stability + 50, 1000); // Boost stability, max 1000
        } else if (catalystType == CATALYST_CORE_AURA_MUTATION) {
            // A catalyst that causes a more drastic mutation in aura
            uint256 randomFactor = uint256(keccak256(abi.encodePacked(tokenId, block.timestamp))) % 200;
            // Add a random component, then ensure bounds
            if (props.aura + randomFactor > 1000) {
                 props.aura = _min(props.aura + randomFactor, 1000); // Move towards 1000
            } else {
                 props.aura = _max(props.aura - (randomFactor / 2), 0); // Or move towards 0, with a floor
            }
            props.entropy = _min(props.entropy + 20, 1000); // Mutation adds to entropy
        } else {
            revert("EDG: Unknown catalyst type");
        }
        
        // Record this event for history
        bytes32 eventHash = keccak256(abi.encodePacked("Catalyst Applied", catalystType, props.aura, props.stability, props.entropy, props.resilience));
        _shardEvolutionHistory[tokenId][currentEpoch].push(eventHash);

        emit CatalystApplied(tokenId, msg.sender, catalystType);
        emit ShardEvolved(tokenId, props.aura, props.stability, props.entropy, props.resilience, currentEpoch);
    }

    // --- III. Evolution Mechanisms ---

    /// @notice (Callable by Oracle/Admin) Initiates a request for external mutation data for the next epoch.
    /// @dev In a real Chainlink integration, this would call Chainlink.request().
    function requestEpochalMutationData() public onlyOwner { // Owner can initiate the request
        // Only allow request if current epoch's data hasn't been fulfilled and epoch has ended
        require(block.timestamp >= epochDetails[currentEpoch].endTimestamp || !epochDetails[currentEpoch].dataFulfilled, "EDG: Epoch not ended yet or data already fulfilled for this epoch.");
        
        // If the data for the current epoch is already fulfilled and the epoch has ended, move to the next.
        // Otherwise, if data is not fulfilled for current epoch, the oracle must fulfill for current epoch.
        if (block.timestamp >= epochDetails[currentEpoch].endTimestamp && epochDetails[currentEpoch].dataFulfilled) {
            currentEpoch++;
            epochDetails[currentEpoch].startTimestamp = block.timestamp;
            epochDetails[currentEpoch].endTimestamp = block.timestamp + epochDuration;
        }

        // Simulate sending a request to an off-chain oracle (e.g., Chainlink)
        // This is where Chainlink request logic would go. For simulation, we just emit.
        emit EpochMutationRequested(currentEpoch, msg.sender);
    }

    /// @notice (Callable by Oracle) Receives and processes mutation data for an epoch.
    /// @dev This function would be a Chainlink fulfill callback.
    /// @param epoch The epoch for which data is being fulfilled.
    /// @param oracleDataHash A hash of the raw oracle data for integrity verification.
    /// @param data The raw oracle data (e.g., a byte array representing a vector or seed).
    function fulfillEpochalMutation(uint256 epoch, bytes32 oracleDataHash, bytes memory data) public onlyOracle {
        require(epoch == currentEpoch, "EDG: Data for incorrect epoch.");
        require(!epochDetails[epoch].dataFulfilled, "EDG: Epoch data already fulfilled.");
        require(keccak256(data) == oracleDataHash, "EDG: Oracle data hash mismatch.");

        epochDetails[epoch].oracleData = data;
        epochDetails[epoch].mutationVectorHash = oracleDataHash;
        epochDetails[epoch].dataFulfilled = true;

        emit EpochMutationFulfilled(epoch, oracleDataHash);
    }

    /// @notice User-initiated function to calculate and apply all pending evolutionary changes to their Shard.
    /// @dev This function is critical for evolving a Shard. It processes pending influences and applies global epochal mutations.
    /// @param tokenId The ID of the Shard to evolve.
    function triggerShardEvolution(uint256 tokenId) public {
        require(_exists(tokenId), "EDG: Shard does not exist");
        require(ownerOf(tokenId) == msg.sender, "EDG: Not shard owner");
        
        ShardProperties storage props = _genesisShardProperties[tokenId];
        uint256 lastEvoEpoch = props.lastEvolutionEpoch;

        // Apply all pending influences
        for (uint256 essenceType = 1; essenceType < 100; essenceType++) {
            uint256 influenceAmount = _pendingShardInfluences[tokenId][essenceType];
            if (influenceAmount > 0) {
                // Apply influence based on type
                if (essenceType == INFLUENCE_ESSENCE_CURATOR) {
                    props.stability = _min(props.stability + (influenceAmount * 2), 1000);
                    props.entropy = _max(props.entropy - influenceAmount, 0);
                } else if (essenceType == INFLUENCE_ESSENCE_INNOVATOR) {
                    props.aura = _min(props.aura + (influenceAmount * 3), 1000);
                    props.resilience = _min(props.resilience + influenceAmount, 1000);
                } else if (essenceType == INFLUENCE_ESSENCE_PHILANTHROPIST) {
                    props.resilience = _min(props.resilience + (influenceAmount * 2), 1000);
                    props.stability = _min(props.stability + influenceAmount, 1000);
                }
                _pendingShardInfluences[tokenId][essenceType] = 0; // Reset pending influence
            }
        }

        // Apply epochal mutations for all epochs since last evolution
        // This loop ensures that even if a user doesn't call triggerShardEvolution for a while,
        // their shard catches up on all missed epochal mutations.
        for (uint256 epoch = lastEvoEpoch + 1; epoch <= currentEpoch; epoch++) {
            if (epochDetails[epoch].dataFulfilled) {
                _evolveShardProperties(tokenId); // Apply mutation logic based on epoch data
                // Record this epoch's mutation effect
                bytes32 eventHash = keccak256(abi.encodePacked("Epochal Mutation", epoch, epochDetails[epoch].mutationVectorHash));
                _shardEvolutionHistory[tokenId][epoch].push(eventHash);
            }
        }
        props.lastEvolutionEpoch = currentEpoch; // Update last evolution epoch

        emit ShardEvolved(tokenId, props.aura, props.stability, props.entropy, props.resilience, currentEpoch);
    }

    /// @notice Calculates a "resonance score" between two Shards based on their current properties.
    /// @dev Higher score means more similar properties. Could be used for pairing or shared events.
    /// @param tokenId1 The ID of the first Shard.
    /// @param tokenId2 The ID of the second Shard.
    /// @return A uint256 representing the resonance score (e.g., sum of inverse differences, normalized). Max 1000.
    function calculateShardResonance(uint256 tokenId1, uint256 tokenId2) public view returns (uint256) {
        require(_exists(tokenId1) && _exists(tokenId2), "EDG: One or both shards do not exist");
        require(tokenId1 != tokenId2, "EDG: Cannot calculate resonance with self");

        ShardProperties storage props1 = _genesisShardProperties[tokenId1];
        ShardProperties storage props2 = _genesisShardProperties[tokenId2];

        uint256 maxPropVal = 1000; // Max value for aura, stability, entropy, resilience

        uint256 diffAura = _abs(props1.aura, props2.aura);
        uint256 diffStability = _abs(props1.stability, props2.stability);
        uint256 diffEntropy = _abs(props1.entropy, props2.entropy);
        uint256 diffResilience = _abs(props1.resilience, props2.resilience);

        // Contribution of each property to resonance (higher for smaller diff)
        // Using (maxPropVal - diff)^2 to heavily penalize large differences
        uint256 resonanceAura = (maxPropVal - diffAura) * (maxPropVal - diffAura);
        uint256 resonanceStability = (maxPropVal - diffStability) * (maxPropVal - diffStability);
        uint256 resonanceEntropy = (maxPropVal - diffEntropy) * (maxPropVal - diffEntropy);
        uint256 resonanceResilience = (maxPropVal - diffResilience) * (maxPropVal - diffResilience);

        // Sum contributions. Normalize to max possible resonance (4 * (maxPropVal^2)) and scale to 1000
        uint256 totalRawResonance = resonanceAura + resonanceStability + resonanceEntropy + resonanceResilience;
        uint256 maxPossibleRawResonance = (maxPropVal * maxPropVal) * 4;
        
        // Normalize to 1000 (avoid division by zero as maxPossibleRawResonance is non-zero)
        return (totalRawResonance * 1000) / maxPossibleRawResonance;
    }

    /// @notice Internal function encapsulating the core property evolution logic.
    /// @dev Called by `triggerShardEvolution` to apply epochal mutations and other internal evolution rules.
    /// @param tokenId The ID of the Shard to evolve.
    function _evolveShardProperties(uint256 tokenId) internal {
        ShardProperties storage props = _genesisShardProperties[tokenId];
        EpochData storage currentEpochData = epochDetails[currentEpoch];

        // Apply general decay/growth based on global parameters
        props.stability = _max(props.stability - _globalEvolutionParameters["stabilityDecayRate"], 0);
        props.entropy = _min(props.entropy + 2, 1000); // Entropy generally increases

        // Interpret oracle data for mutation (simulated logic)
        // For real-world use, `currentEpochData.oracleData` would be parsed into meaningful values
        uint256 oracleSeed = uint256(currentEpochData.mutationVectorHash);

        // Pseudo-random mutation based on oracle data and entropy
        if (uint256(keccak256(abi.encodePacked(tokenId, oracleSeed, "mutation_check"))) % 100 < _globalEvolutionParameters["entropyMutationChance"]) {
            // High entropy and specific oracle data lead to more drastic mutations
            props.aura = _min(_max(props.aura + (oracleSeed % 100) - 50, 0), 1000);
            props.resilience = _min(_max(props.resilience + (oracleSeed % 50) - 25, 0), 1000);
            props.entropy = _min(props.entropy + 50, 1000); // Mutation adds to entropy
        } else {
            // Subtler influence based on oracle data
            props.aura = _min(_max(props.aura + (oracleSeed % 10) - 5, 0), 1000);
        }
    }

    // --- IV. Community & Governance ---

    /// @notice Allows users to delegate their future awarded Influence Essences to another address.
    /// @dev The delegatee will receive any future `awardInfluenceEssence` calls for that essence type directed to the delegator.
    /// @param essenceType The type of Influence Essence to delegate.
    /// @param delegatee The address to delegate to. Set to address(0) to revoke delegation.
    function delegateInfluence(uint256 essenceType, address delegatee) public {
        require(essenceType > 0 && essenceType < 100, "EDG: Invalid essence type");
        require(delegatee != msg.sender, "EDG: Cannot delegate to self");

        _delegatedInfluence[msg.sender][essenceType] = delegatee;

        if (delegatee == address(0)) {
            emit InfluenceDelegationRevoked(msg.sender, essenceType);
        } else {
            emit InfluenceDelegated(msg.sender, essenceType, delegatee);
        }
    }

    /// @notice Revokes a previously set delegation for a specific Influence Essence type.
    /// @param essenceType The type of Influence Essence for which to revoke delegation.
    function revokeInfluenceDelegation(uint256 essenceType) public {
        require(essenceType > 0 && essenceType < 100, "EDG: Invalid essence type");
        require(_delegatedInfluence[msg.sender][essenceType] != address(0), "EDG: No active delegation to revoke");

        _delegatedInfluence[msg.sender][essenceType] = address(0);
        emit InfluenceDelegationRevoked(msg.sender, essenceType);
    }

    /// @notice Allows users to propose changes to global evolution rules.
    /// @dev Requires a minimum amount of 'Curator Influence' to propose (e.g., 1).
    /// @param parameterName The name of the parameter to change (e.g., "stabilityDecayRate").
    /// @param newValue The new value for the parameter.
    /// @param description A description of the proposal.
    /// @return The ID of the newly created proposal.
    function proposeCollectiveEvolutionParameter(string memory parameterName, uint256 newValue, string memory description) public returns (uint256) {
        require(balanceOf(msg.sender, INFLUENCE_ESSENCE_CURATOR) >= 1, "EDG: Requires 1 Curator Influence to propose");
        require(bytes(parameterName).length > 0, "EDG: Parameter name cannot be empty");
        
        // Ensure the parameter name is one of the whitelisted/known global parameters
        bytes32 paramHash = keccak256(abi.encodePacked(parameterName));
        require(paramHash == keccak256(abi.encodePacked("auraInfluenceFactor")) ||
                paramHash == keccak256(abi.encodePacked("stabilityDecayRate")) ||
                paramHash == keccak256(abi.encodePacked("entropyMutationChance")), "EDG: Unknown or unmodifiable parameter");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            description: description,
            parameterName: parameterName,
            newValue: newValue,
            voteCountYes: 0,
            voteCountNo: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + PROPOSAL_VOTING_PERIOD,
            executed: false
        });

        emit ProposalCreated(proposalId, msg.sender, parameterName, newValue, proposals[proposalId].endTime);
        return proposalId;
    }

    /// @notice Allows users to cast their vote on active proposals.
    /// @dev Requires at least 1 influence essence of any type to vote. Voting power is 1 vote per unique address.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'yes', false for 'no'.
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EDG: Proposal does not exist");
        require(block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime, "EDG: Voting period not active");
        require(!proposal.executed, "EDG: Proposal already executed");
        require(!proposal.hasVoted[msg.sender], "EDG: Already voted on this proposal");
        
        // Simple voting power: any influence essence grants 1 vote for now
        require(balanceOf(msg.sender, INFLUENCE_ESSENCE_CURATOR) > 0 ||
                balanceOf(msg.sender, INFLUENCE_ESSENCE_INNOVATOR) > 0 ||
                balanceOf(msg.sender, INFLUENCE_ESSENCE_PHILANTHROPIST) > 0, "EDG: Requires any Influence Essence to vote");

        if (support) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes a proposal if it has met the voting threshold and period.
    /// @dev Anyone can call this after the voting period ends.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), "EDG: Proposal does not exist");
        require(block.timestamp > proposal.endTime, "EDG: Voting period not ended");
        require(!proposal.executed, "EDG: Proposal already executed");

        uint256 totalVotes = proposal.voteCountYes + proposal.voteCountNo;
        uint256 totalEssences = _totalEssencesMinted(); // Simplified total influence for quorum

        // Check quorum: simplified to total essences minted. A more robust system would track active essence holders.
        // Prevent division by zero if totalEssences is 0 (unlikely but good practice)
        require(totalEssences > 0, "EDG: No essences minted for quorum calculation.");
        require((totalVotes * 100) >= (totalEssences * PROPOSAL_QUORUM_PERCENT), "EDG: Quorum not met");

        bool success = false;
        if ((proposal.voteCountYes * 100) >= (totalVotes * PROPOSAL_APPROVAL_PERCENT)) {
            _globalEvolutionParameters[proposal.parameterName] = proposal.newValue;
            success = true;
        }

        proposal.executed = true;
        emit ProposalExecuted(proposalId, success);
    }

    /// @dev Internal helper to get a simplified "total influence" for quorum calculation.
    /// @return The sum of all minted Influence Essences across all types.
    function _totalEssencesMinted() internal view returns (uint256) {
        uint256 total = 0;
        total += totalSupply(INFLUENCE_ESSENCE_CURATOR);
        total += totalSupply(INFLUENCE_ESSENCE_INNOVATOR);
        total += totalSupply(INFLUENCE_ESSENCE_PHILANTHROPIST);
        return total;
    }

    // --- V. Information & Utility Functions ---

    /// @notice Shows Influence Essences accumulated for a Shard but not yet infused.
    /// @param tokenId The ID of the Shard.
    /// @return An array of tuples, each containing essenceType and amount.
    function getPendingShardInfluences(uint256 tokenId) public view returns (uint256[] memory essenceTypes, uint256[] memory amounts) {
        require(_exists(tokenId), "EDG: Shard does not exist");
        
        uint256[] memory tempTypes = new uint256[](3); // Max 3 hardcoded types
        uint256[] memory tempAmounts = new uint256[](3);
        uint256 count = 0;

        if (_pendingShardInfluences[tokenId][INFLUENCE_ESSENCE_CURATOR] > 0) {
            tempTypes[count] = INFLUENCE_ESSENCE_CURATOR;
            tempAmounts[count] = _pendingShardInfluences[tokenId][INFLUENCE_ESSENCE_CURATOR];
            count++;
        }
        if (_pendingShardInfluences[tokenId][INFLUENCE_ESSENCE_INNOVATOR] > 0) {
            tempTypes[count] = INFLUENCE_ESSENCE_INNOVATOR;
            tempAmounts[count] = _pendingShardInfluences[tokenId][INFLUENCE_ESSENCE_INNOVATOR];
            count++;
        }
        if (_pendingShardInfluences[tokenId][INFLUENCE_ESSENCE_PHILANTHROPIST] > 0) {
            tempTypes[count] = INFLUENCE_ESSENCE_PHILANTHROPIST;
            tempAmounts[count] = _pendingShardInfluences[tokenId][INFLUENCE_ESSENCE_PHILANTHROPIST];
            count++;
        }

        essenceTypes = new uint256[](count);
        amounts = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            essenceTypes[i] = tempTypes[i];
            amounts[i] = tempAmounts[i];
        }
        return (essenceTypes, amounts);
    }

    /// @notice Simulates the effect of a potential oracle mutation on a Shard without changing its state.
    /// @dev Useful for users to anticipate how their Shard might change.
    /// @param tokenId The ID of the Shard to simulate for.
    /// @param simulatedOracleData Hypothetical oracle data (e.g., a bytes32 hash representation).
    /// @return The expected new aura, stability, entropy, and resilience.
    function getExpectedMutationEffect(uint256 tokenId, bytes memory simulatedOracleData) public view returns (uint256 aura, uint256 stability, uint256 entropy, uint256 resilience) {
        require(_exists(tokenId), "EDG: Shard does not exist");
        ShardProperties storage props = _genesisShardProperties[tokenId];

        // Create a temporary copy of properties for simulation
        ShardProperties memory tempProps = ShardProperties({
            aura: props.aura,
            stability: props.stability,
            entropy: props.entropy,
            resilience: props.resilience,
            creationEpoch: props.creationEpoch,
            lastEvolutionEpoch: props.lastEvolutionEpoch
        });

        // Apply general decay/growth based on current global parameters
        tempProps.stability = _max(tempProps.stability - _globalEvolutionParameters["stabilityDecayRate"], 0);
        tempProps.entropy = _min(tempProps.entropy + 2, 1000);

        uint256 oracleSeed = uint256(keccak256(simulatedOracleData));

        // Apply pseudo-random mutation based on oracle data and entropy
        if (uint256(keccak256(abi.encodePacked(tokenId, oracleSeed, "mutation_check"))) % 100 < _globalEvolutionParameters["entropyMutationChance"]) {
            tempProps.aura = _min(_max(tempProps.aura + (oracleSeed % 100) - 50, 0), 1000);
            tempProps.resilience = _min(_max(tempProps.resilience + (oracleSeed % 50) - 25, 0), 1000);
            tempProps.entropy = _min(tempProps.entropy + 50, 1000);
        } else {
            tempProps.aura = _min(_max(tempProps.aura + (oracleSeed % 10) - 5, 0), 1000);
        }
        
        return (tempProps.aura, tempProps.stability, tempProps.entropy, tempProps.resilience);
    }

    /// @notice Lists Catalyst Cores currently held by an owner.
    /// @param owner The address of the owner.
    /// @return An array of catalystType IDs and their corresponding amounts.
    function getAvailableCatalysts(address owner) public view returns (uint256[] memory catalystTypes, uint256[] memory amounts) {
        uint256[] memory tempTypes = new uint256[](2); // Max 2 hardcoded types
        uint256[] memory tempAmounts = new uint256[](2);
        uint256 count = 0;

        if (balanceOf(owner, CATALYST_CORE_STABILITY_BOOST) > 0) {
            tempTypes[count] = CATALYST_CORE_STABILITY_BOOST;
            tempAmounts[count] = balanceOf(owner, CATALYST_CORE_STABILITY_BOOST);
            count++;
        }
        if (balanceOf(owner, CATALYST_CORE_AURA_MUTATION) > 0) {
            tempTypes[count] = CATALYST_CORE_AURA_MUTATION;
            tempAmounts[count] = balanceOf(owner, CATALYST_CORE_AURA_MUTATION);
            count++;
        }

        catalystTypes = new uint256[](count);
        amounts = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            catalystTypes[i] = tempTypes[i];
            amounts[i] = tempAmounts[i];
        }
        return (catalystTypes, amounts);
    }

    /// @notice Returns the active mutation data influencing current evolutions.
    /// @return The bytes32 hash of the oracle data, and the raw bytes data.
    function getCurrentGlobalMutationVector() public view returns (bytes32 mutationHash, bytes memory oracleData) {
        EpochData storage data = epochDetails[currentEpoch];
        return (data.mutationVectorHash, data.oracleData);
    }

    /// @notice Provides details about a specific epoch, including its mutation data.
    /// @param epoch The epoch ID.
    /// @return A tuple containing the mutationVectorHash, raw oracleData, startTimestamp, endTimestamp, and dataFulfilled status.
    function getEpochDetails(uint256 epoch) public view returns (bytes32 mutationVectorHash, bytes memory oracleData, uint256 startTimestamp, uint256 endTimestamp, bool dataFulfilled) {
        EpochData storage data = epochDetails[epoch];
        return (data.mutationVectorHash, data.oracleData, data.startTimestamp, data.endTimestamp, data.dataFulfilled);
    }

    // --- ERC1155 Overrides for Custom Behavior ---

    /// @dev ERC1155 hook to enforce non-transferability of Influence Essences (SBT-like).
    ///      Only minting (from `address(0)`) or burning (to `address(0)`) of essences is permitted.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            // If the token ID is within the range for Influence Essences (1-99)
            if (id > 0 && id < 100) { 
                // Allow minting (from zero address) and burning (to zero address)
                // Disallow all other direct transfers (P2P transfers)
                require(from == address(0) || to == address(0), "EDG: Influence Essences are non-transferable (SBT-like).");
            }
        }
    }
    
    // The following function is required by ERC1155 to return the URI for a given token ID.
    // This provides a generic URI based on the token type.
    function uri(uint256 tokenId) public view override returns (string memory) {
        if (tokenId > 0 && tokenId < 100) {
            // Influence Essences
            if (tokenId == INFLUENCE_ESSENCE_CURATOR) return "ipfs://essence/curator_influence";
            if (tokenId == INFLUENCE_ESSENCE_INNOVATOR) return "ipfs://essence/innovator_influence";
            if (tokenId == INFLUENCE_ESSENCE_PHILANTHROPIST) return "ipfs://essence/philanthropist_influence";
        } else if (tokenId >= 100) {
            // Catalyst Cores
            if (tokenId == CATALYST_CORE_STABILITY_BOOST) return "ipfs://catalyst/stability_boost_core";
            if (tokenId == CATALYST_CORE_AURA_MUTATION) return "ipfs://catalyst/aura_mutation_core";
        }
        // Fallback or specific URI for other token IDs, e.g., for ERC721 Genesis Shards
        return super.uri(tokenId);
    }
}
```