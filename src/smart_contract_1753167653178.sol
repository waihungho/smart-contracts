This smart contract, "ChronoForge," introduces a novel concept of **Dynamic, AI-Driven Evolving NFTs** where the NFTs (called "EpochEssences") don't just represent static art but are living, growing entities whose traits and evolution paths can be influenced by owner interaction, time, and verifiable outputs from a decentralized AI Oracle.

---

## ChronoForge: Dynamic NFT Evolution & Decentralized AI Oracle

### Outline:

1.  **Introduction:**
    *   Overview of EpochEssences as living NFTs.
    *   Core mechanics: Evolution stages, AI influence, owner interaction (staking, feeding).
2.  **Core Concepts:**
    *   **EpochEssence:** The ERC721 NFT, possessing unique, dynamic attributes.
    *   **Evolution Stages:** NFTs progress through defined stages, unlocking new abilities or visual states.
    *   **Affinity Mask:** A bitmask representing various intrinsic traits influenced by evolution and AI.
    *   **AI Oracle Integration:** A mechanism for EpochEssences to query and receive validated, complex data (e.g., sentiment analysis, generative parameters) from an off-chain AI network, influencing their traits.
    *   **Interaction Mechanics:**
        *   **Staking:** Locking ChronoTokens (a hypothetical native token) on an individual EpochEssence to accelerate passive evolution.
        *   **Feeding:** Burning/donating ChronoTokens directly to an EpochEssence for immediate trait boosts or evolution progress.
        *   **Active Evolution:** Owners can manually trigger an evolution step if conditions (time, cost) are met.
3.  **Features & Innovations:**
    *   **Dynamic Metadata URI:** The NFT's metadata (image, traits) updates on-chain with every significant change, pointing to a dynamic off-chain rendering service.
    *   **Verifiable AI Oracle Interaction:** A robust system for requesting AI computations and verifying their results on-chain via commitment hashes before applying effects.
    *   **NFT-Specific Staking:** Tokens are staked directly on an NFT, not a pool, tying value and utility to the individual asset.
    *   **Progressive Evolution Cost:** The cost to evolve increases with each stage, balancing progression.
    *   **Modular AI Oracle:** Designed to interact with any compliant AI Oracle contract, allowing for future upgrades or multiple oracle providers.
4.  **Technical Details:**
    *   Built on OpenZeppelin's ERC721, Ownable, and ReentrancyGuard for security and best practices.
    *   Uses a hypothetical `IChronoToken` interface for native token interactions.
    *   Implements a custom `IAIOracle` interface for decentralized AI integration.

### Function Summary:

**I. NFT Management & Core Mechanics (ERC721 & ChronoForge Specific):**

1.  `constructor()`: Initializes the contract with NFT name, symbol, and dependencies (ChronoToken, AI Oracle).
2.  `mintEpochEssence(address owner_)`: Allows users to mint a new EpochEssence NFT, paying a base cost in ChronoTokens.
3.  `evolveEpochEssence(uint256 tokenId)`: Triggers an evolution step for a specific EpochEssence, if the time interval and cost conditions are met. Updates stage, affinity mask, and metadata.
4.  `stakeForEssenceEvolution(uint256 tokenId, uint256 amount)`: Allows owners to stake ChronoTokens on their EpochEssence, increasing its passive evolution rate or providing a bonus.
5.  `unstakeFromEssence(uint256 tokenId, uint256 amount)`: Allows owners to withdraw staked ChronoTokens from their EpochEssence.
6.  `feedEpochEssence(uint256 tokenId, uint256 amount)`: Allows owners to 'feed' their EpochEssence by burning/donating ChronoTokens, providing an immediate boost to specific traits or progress towards evolution.
7.  `getEpochEssenceDetails(uint256 tokenId)`: Returns all current state details of a specific EpochEssence NFT.
8.  `tokenURI(uint256 tokenId)`: Overrides ERC721 `tokenURI` to provide a dynamic URI based on the EpochEssence's current on-chain state.
9.  `_calculateEvolutionCost(uint8 currentStage)` (Internal): Determines the ChronoToken cost for the next evolution based on the current stage.
10. `_applyEvolutionEffects(uint256 tokenId)` (Internal): Applies the changes to an EpochEssence's traits and stage during evolution.
11. `_updateMetadataURI(uint256 tokenId)` (Internal): Internal helper to update the stored metadata URI for the given token.

**II. AI Oracle Integration:**

12. `requestAIOracleParameter(uint256 tokenId, bytes memory query)`: Allows an EpochEssence owner to request a specific AI computation/parameter from the registered AI Oracle for their NFT, paying a fee.
13. `fulfillAIOracleParameter(uint256 tokenId, bytes32 queryHash, bytes32 resultHash, bytes memory resultData)`: Callback function for the AI Oracle to deliver the verified result of a query. Restricted to the registered AI Oracle address. This function applies the AI's influence to the NFT's traits.
14. `verifyAIParamCommitment(uint256 tokenId, bytes32 resultHash)`: Allows anyone to verify if a submitted AI result matches the committed hash for a given request.

**III. Access Control & Configuration (Owner/Governance):**

15. `setChronoTokenAddress(address _chronoTokenAddress)`: Sets the address of the ERC20 ChronoToken contract used for fees and staking.
16. `setAIOracleContract(address _aiOracleContract)`: Sets the address of the compliant AI Oracle contract.
17. `setBaseMintCost(uint256 _newCost)`: Sets the base cost for minting a new EpochEssence.
18. `setEvolutionInterval(uint64 _newInterval)`: Sets the minimum time interval required between evolutions.
19. `setBaseEvolutionCost(uint256 _newCost)`: Sets the initial base cost for an EpochEssence to evolve.
20. `setAIOracleFee(uint256 _newFee)`: Sets the fee required to request an AI Oracle parameter.
21. `withdrawProtocolFees(address recipient)`: Allows the contract owner to withdraw accumulated protocol fees in ChronoTokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Interfaces ---

// Hypothetical ChronoToken Interface
interface IChronoToken is IERC20 {
    // No additional functions needed for this contract, IERC20 is sufficient.
}

// Interface for a Decentralized AI Oracle Contract
interface IAIOracle {
    // Request AI computation, oracle will call back 'fulfillAIOracleParameter' on this contract
    function requestAIComputation(
        address callbackContract,
        uint256 callbackId, // Used to identify the request in callback (e.g., tokenId)
        bytes memory query, // Specific query for the AI (e.g., "analyze sentiment on Ethereum")
        uint256 fee,
        bytes32 commitmentHash // Optional: commitment hash of expected result for verification
    ) external payable returns (uint256 requestId);
}

// --- Custom Errors ---
error ChronoForge__InvalidTokenId();
error ChronoForge__NotEpochEssenceOwner();
error ChronoForge__EvolutionNotReady();
error ChronoForge__InsufficientFundsForEvolution();
error ChronoForge__StakingAmountTooLow();
error ChronoForge__UnstakeAmountExceedsStaked();
error ChronoForge__AIOracleNotSet();
error ChronoForge__InvalidAIOracleCallback();
error ChronoForge__AIResultMismatch();
error ChronoForge__TokenTransferFailed();

/**
 * @title ChronoForge: Dynamic NFT Evolution & Decentralized AI Oracle
 * @dev This contract creates "EpochEssence" NFTs that evolve over time,
 *      through owner interaction (staking, feeding), and dynamically
 *      based on verified outputs from a decentralized AI Oracle.
 *      Each EpochEssence has evolving traits, reflected in its metadata.
 */
contract ChronoForge is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // --- State Variables ---

    // Struct to define the properties of an EpochEssence NFT
    struct EpochEssence {
        uint64 genesisTimestamp;    // Time of minting
        uint64 lastEvolveTimestamp; // Last time the essence evolved
        uint8 evolutionStage;       // Current stage of evolution (e.g., 0=seed, 1=sprout, etc.)
        uint256 affinityMask;       // Bitmask representing various traits/affinities (e.g., elemental, personality)
        uint256 stakedTokens;       // Amount of ChronoTokens staked on this specific NFT for passive evolution
        uint256 nextEvolutionCost;  // Dynamic cost for the next manual evolution
        string metadataURI;         // Dynamic URI pointing to the metadata JSON (IPFS or centralized API)
        uint256 aiQueryFeePaid;     // Fee paid for the last AI oracle query (for refund/accounting)
        bytes32 aiParamCommitmentHash; // Hash of the expected AI result, for verification
        uint64 aiParamProcessedBlock; // Block number when AI data was processed
    }

    // Mapping from tokenId to EpochEssence struct
    mapping(uint256 => EpochEssence) public epochEssences;

    // Mapping for AI Oracle requests pending fulfillment
    mapping(uint256 => bytes32) public pendingAIOracleRequests; // tokenId => queryHash

    // Contract addresses
    address public chronoTokenAddress;
    address public aiOracleContract;

    // Configuration parameters
    uint256 public baseMintCost;              // Cost to mint a new EpochEssence
    uint64 public minEvolutionInterval;       // Minimum time (seconds) between evolutions
    uint256 public baseEvolutionCost;         // Base cost for manual evolution (scales with stage)
    uint256 public aiOracleFee;               // Fee to request AI oracle computation

    // Counter for unique token IDs
    uint256 private _nextTokenId;

    // --- Events ---
    event EpochEssenceMinted(uint256 indexed tokenId, address indexed owner, uint64 genesisTimestamp);
    event EpochEssenceEvolved(uint256 indexed tokenId, uint8 newStage, uint256 newAffinityMask);
    event TokensStaked(uint256 indexed tokenId, address indexed staker, uint256 amount, uint256 newTotalStaked);
    event TokensUnstaked(uint256 indexed tokenId, address indexed staker, uint256 amount, uint256 newTotalStaked);
    event EpochEssenceFed(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint256 newAffinityMask);
    event AIOracleRequestSent(uint256 indexed tokenId, bytes indexed query, uint256 requestId);
    event AIOracleResultFulfilled(uint256 indexed tokenId, bytes32 queryHash, bytes32 resultHash, bytes resultData);
    event MetadataURIUpdate(uint256 indexed tokenId, string newURI);

    // --- Constructor ---

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialChronoTokenAddress,
        address _initialAIOracleContract
    ) ERC721(_name, _symbol) Ownable(msg.sender) {
        require(_initialChronoTokenAddress != address(0), "ChronoForge: Invalid ChronoToken address");
        require(_initialAIOracleContract != address(0), "ChronoForge: Invalid AI Oracle address");

        chronoTokenAddress = _initialChronoTokenAddress;
        aiOracleContract = _initialAIOracleContract;
        baseMintCost = 100 * (10 ** 18); // Example: 100 ChronoTokens
        minEvolutionInterval = 7 days;   // Example: 7 days
        baseEvolutionCost = 50 * (10 ** 18); // Example: 50 ChronoTokens
        aiOracleFee = 20 * (10 ** 18);   // Example: 20 ChronoTokens
        _nextTokenId = 0; // Token IDs start from 0
    }

    // --- Modifiers ---

    modifier onlyEpochEssenceOwner(uint256 _tokenId) {
        if (ownerOf(_tokenId) != msg.sender) {
            revert ChronoForge__NotEpochEssenceOwner();
        }
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleContract) {
            revert ChronoForge__InvalidAIOracleCallback();
        }
        _;
    }

    // --- I. NFT Management & Core Mechanics ---

    /**
     * @dev Mints a new EpochEssence NFT. Requires payment in ChronoTokens.
     * @param owner_ The address to mint the NFT to.
     */
    function mintEpochEssence(address owner_) public nonReentrant {
        if (IERC20(chronoTokenAddress).balanceOf(msg.sender) < baseMintCost) {
            revert ChronoForge__InsufficientFundsForEvolution();
        }

        // Transfer mint cost
        bool success = IERC20(chronoTokenAddress).transferFrom(msg.sender, address(this), baseMintCost);
        if (!success) {
            revert ChronoForge__TokenTransferFailed();
        }

        uint256 tokenId = _nextTokenId++;
        _safeMint(owner_, tokenId);

        EpochEssence storage essence = epochEssences[tokenId];
        essence.genesisTimestamp = uint64(block.timestamp);
        essence.lastEvolveTimestamp = uint64(block.timestamp); // Can evolve immediately after mint
        essence.evolutionStage = 0; // Start at stage 0 (seed)
        essence.affinityMask = 0x00; // Initial empty affinity mask
        essence.stakedTokens = 0;
        essence.nextEvolutionCost = _calculateEvolutionCost(0); // Cost for stage 1
        _updateMetadataURI(tokenId); // Set initial metadata URI

        emit EpochEssenceMinted(tokenId, owner_, essence.genesisTimestamp);
    }

    /**
     * @dev Triggers an evolution step for a specific EpochEssence.
     *      Requires time interval and ChronoToken cost to be met.
     *      Updates stage, affinity mask, and metadata.
     * @param tokenId The ID of the EpochEssence to evolve.
     */
    function evolveEpochEssence(uint256 tokenId) public nonReentrant onlyEpochEssenceOwner(tokenId) {
        EpochEssence storage essence = epochEssences[tokenId];

        if (block.timestamp < essence.lastEvolveTimestamp + minEvolutionInterval) {
            revert ChronoForge__EvolutionNotReady();
        }

        if (IERC20(chronoTokenAddress).balanceOf(msg.sender) < essence.nextEvolutionCost) {
            revert ChronoForge__InsufficientFundsForEvolution();
        }

        // Transfer evolution cost
        bool success = IERC20(chronoTokenAddress).transferFrom(msg.sender, address(this), essence.nextEvolutionCost);
        if (!success) {
            revert ChronoForge__TokenTransferFailed();
        }

        _applyEvolutionEffects(tokenId);

        essence.lastEvolveTimestamp = uint64(block.timestamp);
        essence.nextEvolutionCost = _calculateEvolutionCost(essence.evolutionStage); // Update cost for next stage
        _updateMetadataURI(tokenId);

        emit EpochEssenceEvolved(tokenId, essence.evolutionStage, essence.affinityMask);
    }

    /**
     * @dev Allows owners to stake ChronoTokens on their EpochEssence.
     *      Staked tokens can passively influence evolution or unlock benefits.
     * @param tokenId The ID of the EpochEssence.
     * @param amount The amount of ChronoTokens to stake.
     */
    function stakeForEssenceEvolution(uint256 tokenId, uint256 amount) public nonReentrant onlyEpochEssenceOwner(tokenId) {
        if (amount == 0) {
            revert ChronoForge__StakingAmountTooLow();
        }

        // Check allowance and transfer tokens
        bool success = IERC20(chronoTokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert ChronoForge__TokenTransferFailed();
        }

        EpochEssence storage essence = epochEssences[tokenId];
        essence.stakedTokens += amount;

        emit TokensStaked(tokenId, msg.sender, amount, essence.stakedTokens);
    }

    /**
     * @dev Allows owners to unstake ChronoTokens from their EpochEssence.
     * @param tokenId The ID of the EpochEssence.
     * @param amount The amount of ChronoTokens to unstake.
     */
    function unstakeFromEssence(uint256 tokenId, uint256 amount) public nonReentrant onlyEpochEssenceOwner(tokenId) {
        if (amount == 0) {
            revert ChronoForge__StakingAmountTooLow(); // Reuse error
        }

        EpochEssence storage essence = epochEssences[tokenId];
        if (essence.stakedTokens < amount) {
            revert ChronoForge__UnstakeAmountExceedsStaked();
        }

        essence.stakedTokens -= amount;

        // Transfer tokens back to owner
        bool success = IERC20(chronoTokenAddress).transfer(msg.sender, amount);
        if (!success) {
            revert ChronoForge__TokenTransferFailed();
        }

        emit TokensUnstaked(tokenId, msg.sender, amount, essence.stakedTokens);
    }

    /**
     * @dev Allows owners to 'feed' their EpochEssence by burning/donating ChronoTokens.
     *      This can provide immediate trait boosts or accelerate progress.
     * @param tokenId The ID of the EpochEssence.
     * @param amount The amount of ChronoTokens to feed.
     */
    function feedEpochEssence(uint256 tokenId, uint256 amount) public nonReentrant onlyEpochEssenceOwner(tokenId) {
        if (amount == 0) {
            revert ChronoForge__StakingAmountTooLow(); // Reuse error
        }

        // Transfer tokens to contract for 'burning' (or accumulation for protocol)
        bool success = IERC20(chronoTokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert ChronoForge__TokenTransferFailed();
        }

        EpochEssence storage essence = epochEssences[tokenId];
        // Example: Add a new trait based on feeding amount, or boost existing ones
        // For simplicity, let's say feeding increases a 'resilience' affinity (e.g., bit 0)
        if (amount > 0) {
            essence.affinityMask |= 0x01; // Set the first bit for 'resilience'
            // More complex logic could modify based on amount, existing traits, etc.
        }

        _updateMetadataURI(tokenId);
        emit EpochEssenceFed(tokenId, msg.sender, amount, essence.affinityMask);
    }

    /**
     * @dev Retrieves all current state details of a specific EpochEssence NFT.
     * @param tokenId The ID of the EpochEssence.
     * @return A tuple containing all properties of the EpochEssence.
     */
    function getEpochEssenceDetails(uint256 tokenId) public view returns (EpochEssence memory) {
        if (!_exists(tokenId)) {
            revert ChronoForge__InvalidTokenId();
        }
        return epochEssences[tokenId];
    }

    /**
     * @dev Overrides ERC721's tokenURI to provide a dynamic URI based on the EpochEssence's state.
     *      This URI should point to an API that renders the JSON metadata based on the on-chain data.
     * @param tokenId The ID of the EpochEssence.
     * @return The URI pointing to the metadata JSON.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ChronoForge__InvalidTokenId();
        }
        // In a real scenario, this would point to a service that dynamically generates metadata:
        // E.g., "https://your-dynamic-nft-api.com/metadata/" + tokenId.toString()
        // For this example, we store and retrieve it from the struct.
        return epochEssences[tokenId].metadataURI;
    }

    /**
     * @dev Internal function to calculate the ChronoToken cost for the next evolution.
     *      Cost increases with higher evolution stages.
     * @param currentStage The current evolution stage.
     * @return The calculated cost for the next evolution.
     */
    function _calculateEvolutionCost(uint8 currentStage) internal view returns (uint256) {
        // Example: Cost doubles every stage, or a linear increase
        return baseEvolutionCost + (baseEvolutionCost * currentStage / 2); // Simple scaling
    }

    /**
     * @dev Internal function to apply the changes to an EpochEssence's traits and stage during evolution.
     * @param tokenId The ID of the EpochEssence.
     */
    function _applyEvolutionEffects(uint256 tokenId) internal {
        EpochEssence storage essence = epochEssences[tokenId];

        essence.evolutionStage += 1; // Increment stage
        // Example: Unlock new affinity bits at certain stages
        if (essence.evolutionStage == 1) {
            essence.affinityMask |= 0x02; // Unlock "Growth" affinity
        } else if (essence.evolutionStage == 2) {
            essence.affinityMask |= 0x04; // Unlock "Insight" affinity
        }
        // More complex logic could involve randomness, staked tokens influence, etc.
    }

    /**
     * @dev Internal helper to update the stored metadata URI for the given token.
     *      In a real application, this would call an off-chain service or pin to IPFS.
     *      For this example, we simply construct a placeholder.
     * @param tokenId The ID of the EpochEssence.
     */
    function _updateMetadataURI(uint256 tokenId) internal {
        EpochEssence storage essence = epochEssences[tokenId];
        // Placeholder: In a real dApp, this would be an API call or IPFS hash
        essence.metadataURI = string(abi.encodePacked(
            "ipfs://QmVQ2v", tokenId.toString(),
            "/stage", essence.evolutionStage.toString(),
            "/affinity", essence.affinityMask.toString(),
            ".json"
        ));
        emit MetadataURIUpdate(tokenId, essence.metadataURI);
    }

    // --- II. AI Oracle Integration ---

    /**
     * @dev Allows an EpochEssence owner to request a specific AI computation/parameter
     *      from the registered AI Oracle for their NFT.
     * @param tokenId The ID of the EpochEssence for which to request AI data.
     * @param query The specific query string or bytes for the AI.
     */
    function requestAIOracleParameter(uint256 tokenId, bytes memory query) public nonReentrant onlyEpochEssenceOwner(tokenId) {
        if (aiOracleContract == address(0)) {
            revert ChronoForge__AIOracleNotSet();
        }

        // Transfer AI oracle fee
        bool success = IERC20(chronoTokenAddress).transferFrom(msg.sender, address(this), aiOracleFee);
        if (!success) {
            revert ChronoForge__TokenTransferFailed();
        }

        // Store the query hash to ensure correct fulfillment
        bytes32 queryHash = keccak256(abi.encodePacked(tokenId, query));
        pendingAIOracleRequests[tokenId] = queryHash;

        // Optionally, an owner could commit to an *expected* result hash, if they have an off-chain prediction.
        // For simplicity here, we don't require pre-commitment from the user side.
        // However, the oracle itself might commit to its result before revealing it.

        IAIOracle(aiOracleContract).requestAIComputation(
            address(this),
            tokenId, // callbackId maps to tokenId
            query,
            aiOracleFee,
            bytes32(0) // No commitment hash from ChronoForge in this example
        );

        EpochEssence storage essence = epochEssences[tokenId];
        essence.aiQueryFeePaid = aiOracleFee; // Store fee for potential future refunds/accounting
        essence.aiParamCommitmentHash = bytes32(0); // Clear previous commitment
        essence.aiParamProcessedBlock = 0; // Reset processed block

        emit AIOracleRequestSent(tokenId, query, tokenId); // tokenId used as request ID for callback
    }

    /**
     * @dev Callback function for the AI Oracle to deliver the verified result of a query.
     *      This function is only callable by the registered AI Oracle contract.
     *      It applies the AI's influence to the NFT's traits and updates metadata.
     * @param tokenId The ID of the EpochEssence that requested the AI data.
     * @param queryHash The hash of the original query, for verification against pending requests.
     * @param resultHash A hash of the AI's actual result data, for on-chain verification.
     * @param resultData The actual data returned by the AI Oracle.
     */
    function fulfillAIOracleParameter(
        uint256 tokenId,
        bytes32 queryHash,
        bytes32 resultHash,
        bytes memory resultData
    ) external nonReentrant onlyAIOracle {
        if (!_exists(tokenId)) {
            revert ChronoForge__InvalidTokenId();
        }

        // Verify that this fulfillment matches a pending request
        if (pendingAIOracleRequests[tokenId] != queryHash) {
            revert ChronoForge__AIResultMismatch(); // Or specific error for mismatching query hash
        }
        delete pendingAIOracleRequests[tokenId]; // Request fulfilled

        // Verify the resultData against the resultHash provided by the oracle (important for integrity)
        if (keccak256(resultData) != resultHash) {
            revert ChronoForge__AIResultMismatch();
        }

        EpochEssence storage essence = epochEssences[tokenId];

        // Example AI data processing:
        // Assume `resultData` contains a uint256 representing a new affinity mask or a delta.
        // This part would be highly dependent on the AI's output structure.
        uint256 aiInfluenceValue = abi.decode(resultData, (uint256));

        // Apply AI influence to the EpochEssence's affinityMask
        // Example: XORing the current affinity with AI influence, or adding specific bits
        essence.affinityMask ^= aiInfluenceValue; // Example: Flip bits based on AI output

        essence.aiParamCommitmentHash = resultHash; // Store the verified result hash
        essence.aiParamProcessedBlock = uint64(block.number); // Record when it was processed

        _updateMetadataURI(tokenId); // Update metadata to reflect AI-driven changes

        emit AIOracleResultFulfilled(tokenId, queryHash, resultHash, resultData);
    }

    /**
     * @dev Allows anyone to verify if a submitted AI result matches the committed hash for a given request.
     *      This can be used by off-chain services or other contracts to trust the on-chain AI data.
     * @param tokenId The ID of the EpochEssence.
     * @param resultHash The hash of the result data to verify.
     * @return True if the result hash matches the last processed AI parameter commitment.
     */
    function verifyAIParamCommitment(uint256 tokenId, bytes32 resultHash) public view returns (bool) {
        if (!_exists(tokenId)) {
            revert ChronoForge__InvalidTokenId();
        }
        return epochEssences[tokenId].aiParamCommitmentHash == resultHash;
    }

    // --- III. Access Control & Configuration (Owner/Governance) ---

    /**
     * @dev Sets the address of the ERC20 ChronoToken contract.
     *      Only callable by the contract owner.
     * @param _chronoTokenAddress The new address for the ChronoToken.
     */
    function setChronoTokenAddress(address _chronoTokenAddress) public onlyOwner {
        require(_chronoTokenAddress != address(0), "ChronoForge: Invalid ChronoToken address");
        chronoTokenAddress = _chronoTokenAddress;
    }

    /**
     * @dev Sets the address of the compliant AI Oracle contract.
     *      Only callable by the contract owner.
     * @param _aiOracleContract The new address for the AI Oracle contract.
     */
    function setAIOracleContract(address _aiOracleContract) public onlyOwner {
        require(_aiOracleContract != address(0), "ChronoForge: Invalid AI Oracle address");
        aiOracleContract = _aiOracleContract;
    }

    /**
     * @dev Sets the base cost for minting a new EpochEssence.
     *      Only callable by the contract owner.
     * @param _newCost The new base minting cost in ChronoTokens (with decimals).
     */
    function setBaseMintCost(uint256 _newCost) public onlyOwner {
        baseMintCost = _newCost;
    }

    /**
     * @dev Sets the minimum time interval required between evolutions (in seconds).
     *      Only callable by the contract owner.
     * @param _newInterval The new minimum evolution interval in seconds.
     */
    function setEvolutionInterval(uint64 _newInterval) public onlyOwner {
        minEvolutionInterval = _newInterval;
    }

    /**
     * @dev Sets the initial base cost for an EpochEssence to evolve.
     *      This value scales with the evolution stage.
     *      Only callable by the contract owner.
     * @param _newCost The new base evolution cost in ChronoTokens (with decimals).
     */
    function setBaseEvolutionCost(uint256 _newCost) public onlyOwner {
        baseEvolutionCost = _newCost;
    }

    /**
     * @dev Sets the fee required to request an AI Oracle parameter.
     *      Only callable by the contract owner.
     * @param _newFee The new AI Oracle fee in ChronoTokens (with decimals).
     */
    function setAIOracleFee(uint256 _newFee) public onlyOwner {
        aiOracleFee = _newFee;
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees in ChronoTokens.
     *      Fees accumulate from minting, evolution, and AI oracle requests.
     * @param recipient The address to send the withdrawn fees to.
     */
    function withdrawProtocolFees(address recipient) public onlyOwner nonReentrant {
        require(recipient != address(0), "ChronoForge: Invalid recipient address");
        uint256 balance = IERC20(chronoTokenAddress).balanceOf(address(this));
        require(balance > 0, "ChronoForge: No fees to withdraw");

        bool success = IERC20(chronoTokenAddress).transfer(recipient, balance);
        if (!success) {
            revert ChronoForge__TokenTransferFailed();
        }
    }
}
```