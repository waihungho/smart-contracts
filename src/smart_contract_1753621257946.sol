Okay, this is an exciting challenge! Let's craft a sophisticated Solidity smart contract that leverages advanced concepts beyond typical open-source patterns.

I present **ChronoForge**, a contract that manages "Temporal Artifacts" (NFTs) which dynamically evolve, spawn new artifacts, and enter "Covenants" based on time, environmental factors (via oracles), and user interaction. It blends concepts of dynamic NFTs, on-chain generative art principles, conditional logic, time-locked features, and a touch of environmental data integration.

---

## ChronoForge Smart Contract

**Contract Name:** `ChronoForge`

**Description:**
ChronoForge is a cutting-edge ERC-721 compliant smart contract that creates and manages "Temporal Artifacts" (NFTs). These artifacts are not static; they possess an inherent life cycle, evolving through various states (Seed, Sapling, Mature, Ancient, Corrupted) based on time elapsed, specific user interactions, and external environmental factors fetched via Chainlink Oracles. ChronoForge also introduces a "Spawning" mechanism, allowing mature artifacts to generate new, unique child artifacts, and a "Covenant" system where artifacts can be pledged for future benefits or consequences, influenced by their state and the passage of time.

**Key Advanced Concepts:**
1.  **Algorithmic Dynamic NFTs:** NFT metadata and properties are not static but derived algorithmically based on on-chain conditions (time, oracle data, interaction history).
2.  **Generative Spawning:** Mature NFTs can "spawn" new, unique child NFTs, with their characteristics influenced by the parent and environmental factors at the time of creation.
3.  **Time-Series Dependent Evolution:** Artifacts change their state/properties over predefined time intervals, or immediately upon user interaction if conditions are met.
4.  **Oracle-Driven Conditional Logic:** External, real-world data (e.g., an abstract "environmental factor" representing conditions like ecological health, energy prices, etc.) influences evolution paths, spawning costs, or covenant outcomes.
5.  **Covenant/Pledge Mechanism:** NFTs can be locked for a duration, with rewards or penalties applied upon covenant fulfillment, influencing the NFT's future state.
6.  **Deterministic Randomness (via VRF hints):** While Chainlink VRF provides robust randomness, the internal "birth signature" for spawned artifacts uses a deterministic blend of parent properties and environmental data, giving a "pseudo-random" feel while being auditable.

---

### Outline and Function Summary

**I. Core NFT & ChronoForge Mechanics**
*   `constructor`: Initializes the contract, sets up oracle addresses and initial parameters.
*   `mintInitialFragment`: Mints the very first generation of Temporal Artifacts.
*   `evolveFragment`: Triggers the evolution of a Temporal Artifact based on time and environmental data.
*   `spawnNewFragment`: Allows a mature Temporal Artifact to generate a new child artifact.
*   `getFragmentMetadataURI`: Generates a dynamic URI for the NFT's metadata based on its current state.
*   `getFragmentEvolutionState`: Returns the current evolution state of a specific artifact.
*   `getFragmentSpawnEligibility`: Checks if an artifact is eligible to spawn a new one.
*   `getFragmentMaturityTimestamp`: Returns the timestamp when an artifact will reach its next evolution state.
*   `getFragmentBirthSignature`: Returns the unique birth signature of an artifact.

**II. Oracle Integration & Data Handling**
*   `requestEnvironmentalData`: Initiates a request to the Chainlink oracle for environmental data.
*   `fulfillEnvironmentalData`: The Chainlink VRF callback function to receive and store the requested environmental data.
*   `getLatestEnvironmentalFactor`: Returns the last fetched environmental factor.
*   `setEnvironmentalOracleAddress`: Admin function to update the environmental data oracle address.
*   `setChainlinkFee`: Admin function to set the Chainlink request fee.

**III. Covenant & Pledge System**
*   `pledgeFragmentForCovenant`: Locks a Temporal Artifact into a time-bound "Covenant".
*   `fulfillCovenant`: Allows the owner to claim or complete a pledged covenant, applying outcomes.
*   `rescindPledge`: Allows early termination of a covenant with potential penalties.
*   `getCovenantDetails`: Returns the details of an active covenant for a given artifact.

**IV. Governance & Admin Functions**
*   `setEvolutionInterval`: Sets the time interval required for artifacts to evolve.
*   `setSpawnCost`: Sets the cost (in native currency) to spawn a new artifact.
*   `setEvolutionRequirements`: Sets the environmental factor thresholds for evolution.
*   `pauseChronoForge`: Pauses core functionalities in emergencies.
*   `unpauseChronoForge`: Unpauses the contract.
*   `transferOwnership`: Transfers contract ownership.
*   `withdrawFunds`: Allows the owner to withdraw collected native currency fees.

**V. ERC-721 Overrides & Utilities**
*   `tokenURI`: Overrides the standard ERC-721 tokenURI to point to the dynamic metadata generator.
*   `supportsInterface`: Implements ERC-165 for interface discovery.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // For environmental data
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol"; // For future pseudo-random mutations (not fully implemented in this example for brevity but the concept is here)
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol"; // Consumer base for VRF

error ChronoForge__NotOwnerOfFragment(uint256 tokenId, address caller);
error ChronoForge__FragmentNotReadyToEvolve(uint256 tokenId, uint256 timeRemaining);
error ChronoForge__FragmentNotReadyToSpawn(uint256 tokenId, string reason);
error ChronoForge__InvalidEnvironmentalFactor(uint256 factor, string requirement);
error ChronoForge__FragmentAlreadyPledged(uint256 tokenId);
error ChronoForge__FragmentNotPledged(uint256 tokenId);
error ChronoForge__CovenantNotYetExpired(uint256 tokenId, uint256 timeRemaining);
error ChronoForge__CovenantExpiredTooSoon(uint256 tokenId);
error ChronoForge__InsufficientSpawnCost(uint256 required, uint256 provided);
error ChronoForge__NoFundsToWithdraw();
error ChronoForge__InvalidEvolutionState(uint8 state);


contract ChronoForge is ERC721Enumerable, Ownable, Pausable, VRFConsumerBaseV2, IERC721Receiver {
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    // --- Enums ---
    enum EvolutionState {
        Seed,       // Newly minted, initial stage
        Sapling,    // First evolution, growing
        Mature,     // Can spawn new fragments, stable
        Ancient,    // Highly evolved, rare, potential for unique abilities
        Corrupted   // Negative evolution path due to adverse environmental conditions or covenant failure
    }

    enum CovenantStatus {
        None,
        Active,
        Fulfilled,
        Rescinded
    }

    // --- Structs ---
    struct TemporalArtifact {
        uint256 genesisTimestamp;       // When the fragment was first minted
        uint256 lastEvolvedTimestamp;   // When it last changed its state
        EvolutionState evolutionState;  // Current evolutionary state
        uint256 birthSignature;         // A unique, deterministically generated signature for spawning/mutations
        uint256 parentTokenId;          // 0 if genesis fragment, otherwise the ID of its parent
        uint256 environmentalInfluenceFactor; // The environmental factor that last influenced its evolution
    }

    struct Covenant {
        CovenantStatus status;
        uint256 pledgeTimestamp;        // When the fragment was pledged
        uint256 expiryTimestamp;        // When the covenant expires
        uint256 pledgeDuration;         // Original duration for the covenant
        uint256 rewardAmount;           // Potential reward if fulfilled (e.g., native currency or future custom token)
        uint256 penaltyAmount;          // Potential penalty if rescinded (e.g., native currency)
    }

    // --- Mappings ---
    mapping(uint256 => TemporalArtifact) public temporalArtifacts;
    mapping(uint256 => Covenant) public covenants; // tokenId => Covenant details

    // --- Global Parameters ---
    uint256 public nextTokenId;
    uint256 public evolutionInterval;           // Time in seconds required between evolutions
    uint256 public spawnCost;                   // Cost in native currency to spawn a new fragment
    uint256 public initialMintCost;             // Cost to mint initial fragments
    uint256 public minEnvironmentalFactorForEvolution; // Minimum environmental factor for positive evolution
    uint256 public maxEnvironmentalFactorForCorruption; // Max environmental factor for corruption

    // --- Chainlink Oracle Configuration ---
    AggregatorV3Interface internal s_environmentalOracle; // For fetching external environmental data
    bytes32 public s_oracleJobId; // Job ID for Chainlink VRF or Any-API
    uint256 public s_chainlinkFee; // Link token fee for oracle requests

    // VRF Specific (for potential future mutations/random events)
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_keyHash; // Key Hash for VRF
    mapping(uint256 => address) public s_requests; // requestId -> msg.sender for VRF callbacks

    // --- Events ---
    event FragmentMinted(uint256 indexed tokenId, address indexed owner, uint256 genesisTimestamp, EvolutionState initialState);
    event FragmentEvolved(uint256 indexed tokenId, EvolutionState oldState, EvolutionState newState, uint256 influenceFactor);
    event FragmentSpawned(uint256 indexed parentTokenId, uint256 indexed childTokenId, address indexed owner, uint256 influenceFactor);
    event EnvironmentalDataRequested(uint256 indexed requestId, address indexed requester, uint256 timestamp);
    event EnvironmentalDataFulfilled(uint256 indexed requestId, int256 environmentalFactor, uint256 timestamp);
    event FragmentPledged(uint256 indexed tokenId, address indexed pledger, uint256 expiryTimestamp, uint256 reward, uint256 penalty);
    event CovenantFulfilled(uint256 indexed tokenId, address indexed fulfiller, uint256 actualDuration, bool success);
    event CovenantRescinded(uint256 indexed tokenId, address indexed rescinder, uint256 actualDuration, bool penaltyApplied);

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address initialOwner,
        address environmentalOracleAddress,
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash,
        uint256 initialEvolutionInterval,
        uint256 initialSpawnCost,
        uint256 initialMintCost_,
        uint256 minEnvFactorForEvo,
        uint256 maxEnvFactorForCorruption_
    )
        ERC721("ChronoForge Temporal Artifact", "CHRONO")
        Ownable(initialOwner)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator) // VRFCoordinatorV2Interface address
    {
        nextTokenId = 1; // Token IDs start from 1
        evolutionInterval = initialEvolutionInterval; // e.g., 1 days in seconds
        spawnCost = initialSpawnCost; // e.g., 0.1 ETH
        initialMintCost = initialMintCost_; // e.g., 0.05 ETH
        minEnvironmentalFactorForEvolution = minEnvFactorForEvo;
        maxEnvironmentalFactorForCorruption = maxEnvFactorForCorruption_;

        s_environmentalOracle = AggregatorV3Interface(environmentalOracleAddress);
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;
        s_chainlinkFee = 1e18; // Default to 1 LINK, can be updated by owner
    }

    /*///////////////////////////////////////////////////////////////
                        I. CORE NFT & CHRONOFORGE MECHANICS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Mints a new initial Temporal Artifact. This is the genesis point for artifacts not spawned by others.
     * @param to The address to mint the artifact to.
     */
    function mintInitialFragment(address to) public payable whenNotPaused {
        if (msg.value < initialMintCost) {
            revert ChronoForge__InsufficientSpawnCost(initialMintCost, msg.value);
        }

        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);

        // Get latest environmental factor at genesis
        (, int256 latestAnswer, , ,) = s_environmentalOracle.latestRoundData();
        uint256 genesisEnvFactor = uint256(latestAnswer); // Assuming non-negative factor for initial influence

        temporalArtifacts[tokenId] = TemporalArtifact({
            genesisTimestamp: block.timestamp,
            lastEvolvedTimestamp: block.timestamp,
            evolutionState: EvolutionState.Seed,
            birthSignature: _generateBirthSignature(0, block.timestamp, genesisEnvFactor), // Parent 0 for genesis
            parentTokenId: 0,
            environmentalInfluenceFactor: genesisEnvFactor
        });

        emit FragmentMinted(tokenId, to, block.timestamp, EvolutionState.Seed);
    }

    /**
     * @dev Triggers the evolution of a Temporal Artifact.
     *      Evolution is based on time elapsed since last evolution and environmental factors.
     * @param tokenId The ID of the Temporal Artifact to evolve.
     */
    function evolveFragment(uint256 tokenId) public whenNotPaused {
        TemporalArtifact storage fragment = temporalArtifacts[tokenId];
        if (ownerOf(tokenId) != msg.sender) {
            revert ChronoForge__NotOwnerOfFragment(tokenId, msg.sender);
        }

        if (block.timestamp < fragment.lastEvolvedTimestamp + evolutionInterval) {
            revert ChronoForge__FragmentNotReadyToEvolve(tokenId, (fragment.lastEvolvedTimestamp + evolutionInterval) - block.timestamp);
        }

        // Fetch latest environmental factor for evolution
        (, int256 latestAnswer, , ,) = s_environmentalOracle.latestRoundData();
        uint256 currentEnvFactor = uint256(latestAnswer); // Assuming non-negative factor

        EvolutionState oldState = fragment.evolutionState;
        EvolutionState newState = _calculateNextEvolutionState(oldState, currentEnvFactor);

        if (newState == oldState) {
            // No actual evolution occurred due to environmental conditions or already at max state
            // Optionally, could still update lastEvolvedTimestamp here if desired to reset timer
            return;
        }

        fragment.evolutionState = newState;
        fragment.lastEvolvedTimestamp = block.timestamp;
        fragment.environmentalInfluenceFactor = currentEnvFactor;

        emit FragmentEvolved(tokenId, oldState, newState, currentEnvFactor);
    }

    /**
     * @dev Allows a Mature or Ancient Temporal Artifact to spawn a new child artifact.
     *      Requires a native currency cost. Child's birth signature is deterministic.
     * @param parentTokenId The ID of the parent Temporal Artifact.
     * @param to The address to mint the new child artifact to.
     */
    function spawnNewFragment(uint256 parentTokenId, address to) public payable whenNotPaused {
        TemporalArtifact storage parentFragment = temporalArtifacts[parentTokenId];
        if (ownerOf(parentTokenId) != msg.sender) {
            revert ChronoForge__NotOwnerOfFragment(parentTokenId, msg.sender);
        }

        if (msg.value < spawnCost) {
            revert ChronoForge__InsufficientSpawnCost(spawnCost, msg.value);
        }

        if (parentFragment.evolutionState != EvolutionState.Mature && parentFragment.evolutionState != EvolutionState.Ancient) {
            revert ChronoForge__FragmentNotReadyToSpawn(parentTokenId, "Parent not mature or ancient enough");
        }

        // Get latest environmental factor for child's birth signature
        (, int256 latestAnswer, , ,) = s_environmentalOracle.latestRoundData();
        uint256 currentEnvFactor = uint256(latestAnswer); // Assuming non-negative factor

        uint256 childTokenId = nextTokenId++;
        _safeMint(to, childTokenId);

        // Deterministically generate child's birth signature
        uint256 childBirthSig = _generateBirthSignature(
            parentFragment.birthSignature,
            block.timestamp,
            currentEnvFactor
        );

        temporalArtifacts[childTokenId] = TemporalArtifact({
            genesisTimestamp: block.timestamp,
            lastEvolvedTimestamp: block.timestamp,
            evolutionState: EvolutionState.Seed, // New fragments always start as Seed
            birthSignature: childBirthSig,
            parentTokenId: parentTokenId,
            environmentalInfluenceFactor: currentEnvFactor
        });

        emit FragmentSpawned(parentTokenId, childTokenId, to, currentEnvFactor);
    }

    /**
     * @dev Returns the dynamic metadata URI for a given Temporal Artifact.
     *      This URI would point to an off-chain service that generates JSON based on the artifact's current state.
     * @param tokenId The ID of the Temporal Artifact.
     * @return The URI string for the metadata.
     */
    function getFragmentMetadataURI(uint256 tokenId) public view returns (string memory) {
        TemporalArtifact storage fragment = temporalArtifacts[tokenId];
        // In a real application, this would point to an API endpoint that serves
        // dynamic JSON metadata based on the tokenId and its current state.
        // Example: `https://api.chronoforge.xyz/metadata/{tokenId}`
        // The API would query the contract for `temporalArtifacts[tokenId]` details
        // and dynamically generate a metadata JSON, including an image URL reflecting its state.
        string memory baseURI = "https://api.chronoforge.xyz/metadata/";
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @dev Internal helper function to calculate the next evolution state.
     *      This is where the core algorithmic evolution logic resides.
     * @param currentState The current evolution state of the fragment.
     * @param environmentalFactor The current environmental influence.
     * @return The calculated next evolution state.
     */
    function _calculateNextEvolutionState(EvolutionState currentState, uint256 environmentalFactor)
        internal view returns (EvolutionState)
    {
        if (environmentalFactor < maxEnvironmentalFactorForCorruption) {
            return EvolutionState.Corrupted; // Negative environmental influence can lead to corruption
        }

        if (environmentalFactor < minEnvironmentalFactorForEvolution) {
            return currentState; // Not enough positive influence to evolve
        }

        // Positive evolution path
        if (currentState == EvolutionState.Seed) {
            return EvolutionState.Sapling;
        } else if (currentState == EvolutionState.Sapling) {
            return EvolutionState.Mature;
        } else if (currentState == EvolutionState.Mature) {
            return EvolutionState.Ancient;
        } else if (currentState == EvolutionState.Ancient) {
            // Ancient fragments might not evolve further, or could evolve into unique "legendary" states
            // For now, they remain Ancient once they reach it, unless corrupted.
            return EvolutionState.Ancient;
        } else if (currentState == EvolutionState.Corrupted) {
            // Corrupted artifacts need specific actions to 'heal' or they stay corrupted
            // For now, they remain Corrupted.
            return EvolutionState.Corrupted;
        }
        return currentState; // Should not happen
    }

    /**
     * @dev Returns the current evolution state of a specific artifact.
     * @param tokenId The ID of the Temporal Artifact.
     * @return The evolution state as an enum.
     */
    function getFragmentEvolutionState(uint256 tokenId) public view returns (EvolutionState) {
        return temporalArtifacts[tokenId].evolutionState;
    }

    /**
     * @dev Checks if an artifact is eligible to spawn a new one.
     * @param tokenId The ID of the Temporal Artifact.
     * @return A boolean indicating eligibility.
     */
    function getFragmentSpawnEligibility(uint256 tokenId) public view returns (bool) {
        EvolutionState state = temporalArtifacts[tokenId].evolutionState;
        return (state == EvolutionState.Mature || state == EvolutionState.Ancient);
    }

    /**
     * @dev Returns the timestamp when an artifact will be ready for its next evolution.
     * @param tokenId The ID of the Temporal Artifact.
     * @return The timestamp.
     */
    function getFragmentMaturityTimestamp(uint256 tokenId) public view returns (uint256) {
        return temporalArtifacts[tokenId].lastEvolvedTimestamp + evolutionInterval;
    }

    /**
     * @dev Internal helper function to generate a unique "birth signature" for fragments.
     *      This provides a form of deterministic "genetic code" based on parentage and environmental factors.
     * @param parentSignature The birth signature of the parent artifact (0 for genesis).
     * @param timestamp The timestamp of birth/spawn.
     * @param environmentalFactor The environmental factor at the time of birth/spawn.
     * @return A unique hash representing the artifact's birth signature.
     */
    function _generateBirthSignature(uint256 parentSignature, uint256 timestamp, uint256 environmentalFactor) internal pure returns (uint256) {
        // A simple deterministic hash. Can be made more complex.
        return uint256(keccak256(abi.encodePacked(parentSignature, timestamp, environmentalFactor, block.difficulty)));
    }

    /**
     * @dev Returns the unique birth signature of an artifact.
     * @param tokenId The ID of the Temporal Artifact.
     * @return The artifact's birth signature.
     */
    function getFragmentBirthSignature(uint256 tokenId) public view returns (uint256) {
        return temporalArtifacts[tokenId].birthSignature;
    }

    /*///////////////////////////////////////////////////////////////
                        II. ORACLE INTEGRATION & DATA HANDLING
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Requests the latest environmental data from the Chainlink oracle.
     *      This could be triggered by anyone, but updates are only useful for evolution if done periodically.
     */
    function requestEnvironmentalData() public returns (uint256 requestId) {
        // Chainlink AggregatorV3Interface provides `latestRoundData()` which is synchronous.
        // For a true "request" with a callback (e.g., for data that isn't always available or
        // requires more complex computation), Chainlink Any-API would be used, requiring Link tokens.
        // For this example, we assume `latestRoundData()` is sufficient for "requesting" latest data.
        // If a request needs a callback, implement ChainlinkClient.
        (
            /*uint80 roundID*/,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = s_environmentalOracle.latestRoundData();

        // If you were using Chainlink Any-API, this would look like:
        // requestId = ChainlinkClient.request(s_oracleJobId, s_chainlinkFee);
        // s_requests[requestId] = msg.sender;
        // emit EnvironmentalDataRequested(requestId, msg.sender, block.timestamp);

        // For this example, we'll just emit an event showing the "latest" data was "requested"
        // (as it's immediately available from AggregatorV3Interface)
        emit EnvironmentalDataFulfilled(0, answer, block.timestamp); // Use 0 for requestID as it's not truly async

        return 0; // Return 0 as no async request ID is generated for AggregatorV3Interface
    }

    /**
     * @dev This function would be the callback for Chainlink VRF or Any-API,
     *      receiving the environmental data.
     *      (Note: For AggregatorV3Interface, data is synchronous, so this is illustrative for complex oracles)
     * @param requestId The ID of the Chainlink request.
     * @param randomWords (For VRF) or the parsed data from Any-API.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        // In a real scenario, this is where you'd process VRF results.
        // For environmental data from AggregatorV3Interface, this specific callback is not used directly.
        // It's here to show the VRFConsumerBaseV2 integration if random elements were added.
        // E.g., a "mutation" roll during evolution.
        require(s_requests[requestId] != address(0), "ChronoForge: Request not found");
        // Process randomWords[0] for mutation probability or other random event
        delete s_requests[requestId];
        // emit EnvironmentalDataFulfilled(requestId, int256(randomWords[0] % 1000), block.timestamp); // Example
    }


    /**
     * @dev Returns the last known environmental factor from the oracle.
     * @return The environmental factor as an integer.
     */
    function getLatestEnvironmentalFactor() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = s_environmentalOracle.latestRoundData();
        return answer;
    }

    /**
     * @dev Admin function to update the environmental data oracle address.
     * @param _environmentalOracleAddress The new address of the environmental data oracle.
     */
    function setEnvironmentalOracleAddress(address _environmentalOracleAddress) public onlyOwner {
        s_environmentalOracle = AggregatorV3Interface(_environmentalOracleAddress);
    }

    /**
     * @dev Admin function to set the Chainlink LINK token fee for oracle requests.
     *      (Relevant for Chainlink Any-API or VRF, not AggregatorV3Interface)
     * @param _fee The new fee amount in LINK wei.
     */
    function setChainlinkFee(uint256 _fee) public onlyOwner {
        s_chainlinkFee = _fee;
    }

    /*///////////////////////////////////////////////////////////////
                        III. COVENANT & PLEDGE SYSTEM
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows an owner to pledge a Temporal Artifact for a fixed duration, locking it.
     *      During the covenant, the artifact cannot be transferred, evolved, or spawned.
     * @param tokenId The ID of the Temporal Artifact to pledge.
     * @param duration The duration (in seconds) of the covenant.
     * @param rewardAmount The potential native currency reward upon successful fulfillment.
     * @param penaltyAmount The native currency penalty upon early rescission.
     */
    function pledgeFragmentForCovenant(uint256 tokenId, uint256 duration, uint256 rewardAmount, uint256 penaltyAmount) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) {
            revert ChronoForge__NotOwnerOfFragment(tokenId, msg.sender);
        }
        if (covenants[tokenId].status != CovenantStatus.None) {
            revert ChronoForge__FragmentAlreadyPledged(tokenId);
        }
        if (duration == 0) revert("ChronoForge: Covenant duration cannot be zero");

        // Transfer the NFT to the contract
        _transfer(msg.sender, address(this), tokenId);

        covenants[tokenId] = Covenant({
            status: CovenantStatus.Active,
            pledgeTimestamp: block.timestamp,
            expiryTimestamp: block.timestamp + duration,
            pledgeDuration: duration,
            rewardAmount: rewardAmount,
            penaltyAmount: penaltyAmount
        });

        emit FragmentPledged(tokenId, msg.sender, block.timestamp + duration, rewardAmount, penaltyAmount);
    }

    /**
     * @dev Allows the original pledger to fulfill a covenant after its expiry.
     *      Transfers the artifact back and distributes rewards/penalties.
     * @param tokenId The ID of the Temporal Artifact with an active covenant.
     */
    function fulfillCovenant(uint256 tokenId) public {
        Covenant storage covenant = covenants[tokenId];
        address originalPledger = ownerOf(tokenId); // Who sent it to the contract

        if (covenant.status != CovenantStatus.Active) {
            revert ChronoForge__FragmentNotPledged(tokenId);
        }
        if (block.timestamp < covenant.expiryTimestamp) {
            revert ChronoForge__CovenantNotYetExpired(tokenId, covenant.expiryTimestamp - block.timestamp);
        }

        // Transfer NFT back to original owner
        _transfer(address(this), originalPledger, tokenId);

        // Apply rewards (if any)
        if (covenant.rewardAmount > 0) {
            // In a real scenario, funds for rewards would need to be pre-funded or come from external source.
            // For now, let's assume the contract has the funds or it's a symbolic reward.
            // transfer(originalPledger, covenant.rewardAmount); // This would require ETH balance in contract.
        }

        covenant.status = CovenantStatus.Fulfilled;
        emit CovenantFulfilled(tokenId, originalPledger, block.timestamp - covenant.pledgeTimestamp, true);
    }

    /**
     * @dev Allows the original pledger to rescind an active covenant before its expiry.
     *      May incur a penalty and potentially corrupt the artifact.
     * @param tokenId The ID of the Temporal Artifact with an active covenant.
     */
    function rescindPledge(uint256 tokenId) public {
        Covenant storage covenant = covenants[tokenId];
        address originalPledger = ownerOf(tokenId); // Who sent it to the contract

        if (covenant.status != CovenantStatus.Active) {
            revert ChronoForge__FragmentNotPledged(tokenId);
        }
        if (block.timestamp >= covenant.expiryTimestamp) {
            revert ChronoForge__CovenantExpiredTooSoon(tokenId);
        }

        // Apply penalty (if any)
        bool penaltyApplied = false;
        if (covenant.penaltyAmount > 0) {
            // E.g., burn penaltyAmount from their balance, or update artifact's state.
            // For this example, let's say the penalty affects the artifact directly.
            penaltyApplied = true;
            // Corrupt the artifact if rescinded early
            temporalArtifacts[tokenId].evolutionState = EvolutionState.Corrupted;
        }

        // Transfer NFT back to original owner
        _transfer(address(this), originalPledger, tokenId);

        covenant.status = CovenantStatus.Rescinded;
        emit CovenantRescinded(tokenId, originalPledger, block.timestamp - covenant.pledgeTimestamp, penaltyApplied);
    }

    /**
     * @dev Returns the details of an active covenant for a given artifact.
     * @param tokenId The ID of the Temporal Artifact.
     * @return A tuple containing covenant status, pledge timestamp, expiry timestamp, and reward/penalty.
     */
    function getCovenantDetails(uint256 tokenId) public view returns (CovenantStatus, uint256, uint256, uint256, uint256) {
        Covenant storage covenant = covenants[tokenId];
        return (covenant.status, covenant.pledgeTimestamp, covenant.expiryTimestamp, covenant.rewardAmount, covenant.penaltyAmount);
    }

    /*///////////////////////////////////////////////////////////////
                        IV. GOVERNANCE & ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Sets the time interval (in seconds) required for artifacts to evolve.
     *      Only callable by the contract owner.
     * @param _interval The new evolution interval.
     */
    function setEvolutionInterval(uint256 _interval) public onlyOwner {
        evolutionInterval = _interval;
    }

    /**
     * @dev Sets the cost in native currency (e.g., wei) to spawn a new artifact.
     *      Only callable by the contract owner.
     * @param _cost The new spawn cost.
     */
    function setSpawnCost(uint256 _cost) public onlyOwner {
        spawnCost = _cost;
    }

    /**
     * @dev Sets the initial mint cost in native currency.
     * @param _cost The new initial mint cost.
     */
    function setInitialMintCost(uint256 _cost) public onlyOwner {
        initialMintCost = _cost;
    }

    /**
     * @dev Sets the environmental factor thresholds for evolution and corruption.
     * @param minForEvo Minimum factor for positive evolution.
     * @param maxForCor Maximum factor below which corruption occurs.
     */
    function setEvolutionRequirements(uint256 minForEvo, uint256 maxForCor) public onlyOwner {
        minEnvironmentalFactorForEvolution = minForEvo;
        maxEnvironmentalFactorForCorruption = maxForCor;
    }

    /**
     * @dev Pauses core functionalities of the ChronoForge in emergencies.
     *      Prevents new mints, evolutions, spawns, and covenant pledges.
     *      Only callable by the contract owner.
     */
    function pauseChronoForge() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses core functionalities of the ChronoForge.
     *      Only callable by the contract owner.
     */
    function unpauseChronoForge() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the contract owner to withdraw any collected native currency (ETH) fees.
     *      This includes spawn costs and initial mint costs.
     */
    function withdrawFunds() public onlyOwner {
        if (address(this).balance == 0) {
            revert ChronoForge__NoFundsToWithdraw();
        }
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "ChronoForge: Failed to withdraw funds");
    }

    /*///////////////////////////////////////////////////////////////
                    V. ERC-721 OVERRIDES & UTILITIES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Overrides the standard ERC-721 tokenURI function.
     *      Returns the dynamic metadata URI generated by `getFragmentMetadataURI`.
     * @param tokenId The ID of the Temporal Artifact.
     * @return The URI string for the metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists and is valid
        return getFragmentMetadataURI(tokenId);
    }

    /**
     * @dev Hook that is called by the `_transfer` function to check if `to` is a contract,
     *      and if so, if it accepts ERC721 tokens.
     *      Used for the covenant system where tokens are transferred to the contract.
     */
    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        // Only allow transfers into the contract for pledging
        require(from == msg.sender, "ChronoForge: Only owner can transfer to contract for pledge");
        require(covenants[tokenId].status == CovenantStatus.None, "ChronoForge: Token already pledged or invalid state");
        return this.onERC721Received.selector;
    }

    /**
     * @dev Returns if this contract implements a given interface.
     * @param interfaceId The interface identifier.
     * @return True if this contract implements `interfaceId`, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```