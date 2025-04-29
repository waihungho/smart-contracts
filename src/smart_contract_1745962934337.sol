Okay, here is a Solidity smart contract demonstrating a concept I call "Generative Digital Flora". It combines generative art principles with NFT ownership, state evolution (growth/mutation), and a simple on-chain governance mechanism, interacting with an external ERC-20 "Nutrient" token.

It's designed to be complex and illustrate several concepts beyond basic token standards:

1.  **Procedural Content Generation:** Traits are generated deterministically based on a seed and global parameters.
2.  **Dynamic State:** Tokens (flora) can change properties (growth stage, traits) over time or with user interaction.
3.  **Resource Interaction:** Requires an external ERC-20 token ("Nutrients") to perform actions like planting or attempting mutation.
4.  **On-Chain Governance:** A basic system for users to propose and vote on changes to global parameters affecting generation and mutation.
5.  **Deterministic Pseudo-Randomness:** Using block data and seeds for trait generation and mutation outcomes in a predictable (on-chain) way.
6.  **DataURI Metadata:** Generating dynamic NFT metadata including traits and descriptions directly on-chain.

It is *not* a copy of standard ERC-20/721 implementations or simple protocols. It builds custom logic on top of ERC-721.

**Outline:**

1.  **Contract Name:** GenerativeDigitalFlora
2.  **Description:** An ERC-721 contract where tokens represent unique, procedurally generated digital flora. Flora can grow, mutate, and traits are influenced by global "soil" parameters managed via on-chain governance.
3.  **Key Concepts:** ERC-721 NFT, Procedural Generation, State Evolution, Resource Consumption (ERC-20), On-Chain Governance, Deterministic Pseudo-Randomness, DataURI Metadata.
4.  **Inheritances:** ERC721, Ownable, ReentrancyGuard (simple check).
5.  **Dependencies:** An external ERC-20 token (FloraNutrients).
6.  **Core Data Structures:**
    *   `FloraTraits`: Struct holding generated and dynamic traits (stem, leaf, color, rarity, growth, mutationFactor).
    *   `Proposal`: Struct for governance proposals (parameter key, new value, state, votes, etc.).
7.  **Main Function Categories:**
    *   Minting & Generation (`plantFlora`, internal generation helpers)
    *   Flora State Interaction (`provideNutrients`, `requestMutation`)
    *   Data Retrieval (`getFloraTraits`, `getTraitDescription`, `tokenURI`, etc.)
    *   Governance (`submitParameterChangeProposal`, `voteOnProposal`, `executeProposal`, etc.)
    *   Configuration & Admin (`setNutrientContract`, `setPlantingCost`, `pausePlanting`, etc.)

**Function Summary:**

1.  `constructor()`: Initializes ERC721 name/symbol, sets initial owner and default parameters.
2.  `setNutrientContract(IERC20 nutrientTokenAddress)`: (Admin) Sets the address of the FloraNutrients ERC-20 token.
3.  `setPlantingCost(uint256 cost)`: (Admin/Governance) Sets the cost in Nutrients to plant new flora.
4.  `setMutationCost(uint256 cost)`: (Admin/Governance) Sets the cost in Nutrients to attempt mutation.
5.  `setGrowthNutrientThreshold(uint256 threshold)`: (Admin/Governance) Sets Nutrients required to increase growth stage.
6.  `plantFlora(string memory _userSeed)`: Mints a new flora NFT. Generates traits based on a seed derived from user input, sender, block data, and global parameters. Requires Nutrient token payment.
7.  `getFloraTraits(uint256 tokenId)`: Returns the `FloraTraits` struct for a given token ID.
8.  `getFloraSeed(uint256 tokenId)`: Returns the unique seed used to generate the flora's initial traits.
9.  `getGrowthStage(uint256 tokenId)`: Returns the current growth stage of the flora.
10. `provideNutrients(uint256 tokenId, uint256 amount)`: Allows the owner of a flora to provide Nutrients to it. Increases growth potential. Requires Nutrient token transfer from the user.
11. `requestMutation(uint256 tokenId)`: Attempts to mutate the flora. Consumes Nutrients. Outcome (success/failure, trait changes) is determined pseudo-randomly based on seed, block data, growth stage, and mutation rules.
12. `canMutate(uint256 tokenId)`: Checks if a flora meets the minimum requirements to attempt mutation (e.g., sufficient growth stage).
13. `getTraitDescription(uint256 tokenId)`: Generates a human-readable string description of the flora based on its current traits.
14. `submitParameterChangeProposal(bytes32 parameterKey, int256 newValue)`: (Users) Submits a proposal to change a global "soil" parameter.
15. `voteOnProposal(uint256 proposalId, bool support)`: (Users) Casts a vote (for/against) on an active proposal. Voting power could be based on owned flora or other factors (simple 1-person-1-vote here).
16. `executeProposal(uint256 proposalId)`: Executes a proposal if it has passed the voting period and threshold. Applies the new parameter value.
17. `getProposalState(uint256 proposalId)`: Returns the current state (Pending, Active, Succeeded, Failed, Executed) of a proposal.
18. `getProposal(uint256 proposalId)`: Returns the details of a specific proposal.
19. `getCurrentSoilParameters()`: Returns the currently active global "soil" parameters affecting generation and mutation.
20. `withdrawNutrients(uint256 amount)`: (Admin/Governance) Allows withdrawal of accumulated Nutrient tokens from the contract.
21. `pausePlanting()`: (Admin) Pauses the `plantFlora` function.
22. `unpausePlanting()`: (Admin) Unpauses the `plantFlora` function.
23. `tokenURI(uint256 tokenId)`: (ERC721 Standard) Returns a data URI containing JSON metadata for the token, including its generated traits and description.
24. `_generateTraits(bytes32 seed, Parameters memory currentParameters)`: (Internal Helper) Generates initial flora traits from a given seed and parameters.
25. `_applyMutation(uint256 tokenId, bytes32 mutationSeed)`: (Internal Helper) Applies potential trait changes during mutation based on the flora's state and a mutation seed.

*Note:* ERC721 standard functions like `ownerOf`, `balanceOf`, `transferFrom`, etc., are included via inheritance but not explicitly listed in the summary above to focus on the *unique* functions. Including these brings the total well over 20.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline:
// 1. Contract Name: GenerativeDigitalFlora
// 2. Description: An ERC-721 contract where tokens represent unique, procedurally generated digital flora.
//                 Flora can grow, mutate, and traits are influenced by global "soil" parameters
//                 managed via on-chain governance.
// 3. Key Concepts: ERC-721 NFT, Procedural Generation, State Evolution, Resource Consumption (ERC-20),
//                  On-Chain Governance, Deterministic Pseudo-Randomness, DataURI Metadata.
// 4. Inheritances: ERC721, Ownable, ReentrancyGuard (simple check).
// 5. Dependencies: An external ERC-20 token (FloraNutrients).
// 6. Core Data Structures: FloraTraits, Proposal, Parameters.
// 7. Main Function Categories: Minting/Generation, State Interaction, Data Retrieval, Governance, Admin.

// Function Summary:
// 1. constructor(): Initializes ERC721, sets owner/defaults.
// 2. setNutrientContract(IERC20 nutrientTokenAddress): Admin - Sets Nutrients ERC-20 address.
// 3. setPlantingCost(uint256 cost): Admin/Governance - Sets Nutrient cost for planting.
// 4. setMutationCost(uint256 cost): Admin/Governance - Sets Nutrient cost for mutation attempt.
// 5. setGrowthNutrientThreshold(uint256 threshold): Admin/Governance - Sets Nutrients needed per growth stage.
// 6. plantFlora(string memory _userSeed): Mints new flora, generates traits from seed/params, requires Nutrients.
// 7. getFloraTraits(uint256 tokenId): Returns FloraTraits struct.
// 8. getFloraSeed(uint256 tokenId): Returns the seed used for generation.
// 9. getGrowthStage(uint256 tokenId): Returns current growth stage.
// 10. provideNutrients(uint256 tokenId, uint256 amount): Adds Nutrients to flora, boosts growth potential. Requires user ERC20 approval.
// 11. requestMutation(uint256 tokenId): Attempts to mutate flora, potentially changes traits, consumes Nutrients. Deterministic outcome.
// 12. canMutate(uint256 tokenId): Checks if flora is ready for mutation attempt.
// 13. getTraitDescription(uint256 tokenId): Generates a human-readable description string.
// 14. submitParameterChangeProposal(bytes32 parameterKey, int256 newValue): Users submit governance proposal.
// 15. voteOnProposal(uint256 proposalId, bool support): Users vote on proposal.
// 16. executeProposal(uint256 proposalId): Executes passed proposal.
// 17. getProposalState(uint256 proposalId): Gets proposal lifecycle state.
// 18. getProposal(uint256 proposalId): Gets full proposal details.
// 19. getCurrentSoilParameters(): Returns current global parameters.
// 20. withdrawNutrients(uint256 amount): Admin - Withdraws accumulated Nutrients.
// 21. pausePlanting(): Admin - Pauses new flora minting.
// 22. unpausePlanting(): Admin - Unpauses new flora minting.
// 23. tokenURI(uint256 tokenId): ERC721 Standard - Returns DataURI metadata.
// 24. (Internal) _generateTraits(bytes32 seed, Parameters memory currentParameters): Generates initial traits.
// 25. (Internal) _applyMutation(uint256 tokenId, bytes32 mutationSeed): Applies mutation logic.

contract GenerativeDigitalFlora is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    // --- Constants & Enums ---
    uint256 private constant MAX_GROWTH_STAGE = 10;
    uint256 private constant MAX_MUTATION_FACTOR = 100; // 0-100 percentage like value
    uint256 private constant MAX_RARITY_SCORE = 1000;

    // Trait possibilities (simplified example)
    string[] private stemTypes = ["Slender", "Thick", "Segmented", "Twisted"];
    string[] private leafShapes = ["Oval", "Pointed", "Lobed", "Needle-like"];
    string[] private colorPalettes = ["Forest Green", "Vibrant Red", "Azure Blue", "Golden Yellow", "Deep Purple", "Mystic Grey"];

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---

    struct FloraTraits {
        bytes32 seed; // Seed used for initial generation
        uint8 stemTypeIndex;
        uint8 leafShapeIndex;
        uint8 colorPaletteIndex;
        uint16 rarityScore; // 0-1000, indicates initial trait rarity
        uint8 growthStage; // 0-MAX_GROWTH_STAGE
        uint8 mutationFactor; // Influences mutation chance/impact
        uint256 accumulatedNutrients; // Nutrients provided directly to this plant
    }

    struct Proposal {
        bytes32 parameterKey;
        int256 newValue; // Using int256 to allow for negative values if needed (e.g., temperature offset)
        uint256 expirationBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    struct Parameters {
        // Global parameters influencing generation and mutation
        int256 temperatureInfluence; // e.g., influences color palette shifts
        int256 soilCompositionInfluence; // e.g., influences stem/leaf types
        uint256 baseMutationChance; // e.g., 1-100, base chance per attempt
        uint256 growthNutrientThreshold; // Nutrients required to increase growth stage
        uint256 plantingCost; // Cost in Nutrient tokens to plant
        uint256 mutationCost; // Cost in Nutrient tokens to attempt mutation
        uint256 proposalVotingPeriodBlocks; // How long voting is open
        uint256 proposalQuorum; // Minimum votes needed
        uint256 proposalThreshold; // Percentage of votes needed to pass (e.g., 5100 for 51%)
    }

    // --- State Variables ---

    mapping(uint256 => FloraTraits) private _floraTraits;
    Parameters public soilParameters;
    IERC20 public nutrientToken;

    bool private _plantingPaused = false;

    uint256 private _nextTokenId; // Counter for unique token IDs

    mapping(uint256 => Proposal) private _proposals;
    uint256 private _nextProposalId; // Counter for unique proposal IDs

    // --- Events ---

    event FloraPlanted(uint256 indexed tokenId, address indexed owner, bytes32 seed);
    event NutrientsProvided(uint256 indexed tokenId, uint256 amount, uint256 totalAccumulated);
    event MutationAttempted(uint256 indexed tokenId, bool success, string outcomeDescription);
    event ParametersUpdated(bytes32 indexed parameterKey, int256 newValue);
    event ProposalCreated(uint256 indexed proposalId, bytes32 indexed parameterKey, int256 newValue, uint256 expirationBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event NutrientsWithdrawn(address indexed recipient, uint256 amount);
    event PlantingPaused(bool isPaused);


    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!_plantingPaused, "Planting is paused");
        _;
    }

    modifier onlyOwnerOrGovernance() {
         // In a real system, governance would likely have its own contract
         // or a more complex permissioning system. Here, it's admin + proposal execution.
        require(owner() == msg.sender || _isProposalExecutor(msg.sender), "Not authorized");
        _;
    }

    // Dummy function to represent proposal execution privilege
    // In reality, proposal execution would be done by a specific contract or account
    function _isProposalExecutor(address account) internal pure returns (bool) {
        // For this example, only the owner can 'execute' proposals after they pass
        // In a real DAO, this might be a permission granted to a specific multisig
        // or the DAO executor contract itself.
        return account == owner();
    }


    // --- Constructor ---

    constructor() ERC721("Generative Digital Flora", "FLORA") Ownable(msg.sender) ReentrancyGuard() {
        _nextTokenId = 1;
        _nextProposalId = 1;

        // Initialize default parameters
        soilParameters = Parameters({
            temperatureInfluence: 50, // Default positive influence
            soilCompositionInfluence: 30, // Default positive influence
            baseMutationChance: 20, // 20% base chance
            growthNutrientThreshold: 1000e18, // 1000 tokens per growth stage (assuming 18 decimals)
            plantingCost: 500e18, // 500 tokens to plant
            mutationCost: 200e18, // 200 tokens per mutation attempt
            proposalVotingPeriodBlocks: 100, // ~30-45 minutes
            proposalQuorum: 5, // Minimum 5 votes
            proposalThreshold: 5100 // 51% support
        });
    }

    // --- Admin & Configuration Functions ---

    /**
     * @notice Sets the address of the FloraNutrients ERC-20 token contract.
     * @param nutrientTokenAddress The address of the deployed Nutrient token contract.
     */
    function setNutrientContract(IERC20 nutrientTokenAddress) external onlyOwner {
        require(address(nutrientTokenAddress) != address(0), "Invalid address");
        nutrientToken = nutrientTokenAddress;
    }

    /**
     * @notice Sets the cost in Nutrient tokens required to plant new flora.
     * @param cost The new cost.
     */
    function setPlantingCost(uint256 cost) external onlyOwnerOrGovernance {
        soilParameters.plantingCost = cost;
        emit ParametersUpdated("plantingCost", int256(cost));
    }

    /**
     * @notice Sets the cost in Nutrient tokens required to attempt a mutation.
     * @param cost The new cost.
     */
    function setMutationCost(uint256 cost) external onlyOwnerOrGovernance {
        soilParameters.mutationCost = cost;
         emit ParametersUpdated("mutationCost", int256(cost));
    }

    /**
     * @notice Sets the threshold of accumulated Nutrients required to increase a flora's growth stage.
     * @param threshold The new threshold.
     */
    function setGrowthNutrientThreshold(uint256 threshold) external onlyOwnerOrGovernance {
        soilParameters.growthNutrientThreshold = threshold;
         emit ParametersUpdated("growthNutrientThreshold", int256(threshold));
    }

    /**
     * @notice Allows the owner to withdraw accumulated Nutrient tokens from the contract.
     *         In a real DAO, this might be controlled by governance.
     * @param amount The amount of Nutrients to withdraw.
     */
    function withdrawNutrients(uint256 amount) external onlyOwner {
        require(address(nutrientToken) != address(0), "Nutrient token not set");
        require(nutrientToken.balanceOf(address(this)) >= amount, "Insufficient balance in contract");
        // Use call to avoid reentrancy issues with external transfer
        (bool success, ) = address(nutrientToken).call(abi.encodeWithSelector(nutrientToken.transfer.selector, msg.sender, amount));
        require(success, "Nutrient withdrawal failed");
        emit NutrientsWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Pauses the ability to plant new flora.
     */
    function pausePlanting() external onlyOwner {
        _plantingPaused = true;
        emit PlantingPaused(true);
    }

    /**
     * @notice Unpauses the ability to plant new flora.
     */
    function unpausePlanting() external onlyOwner {
        _plantingPaused = false;
        emit PlantingPaused(false);
    }

    /**
     * @notice Returns the address of the configured Nutrient token contract.
     */
    function getNutrientContract() external view returns (IERC20) {
        return nutrientToken;
    }

    /**
     * @notice Returns the current cost in Nutrients to plant new flora.
     */
    function getPlantingCost() external view returns (uint256) {
        return soilParameters.plantingCost;
    }

    /**
     * @notice Returns the current cost in Nutrients to attempt a mutation.
     */
    function getMutationCost() external view returns (uint256) {
        return soilParameters.mutationCost;
    }

     /**
     * @notice Returns the current Nutrient threshold needed to increase growth stage.
     */
    function getGrowthNutrientThreshold() external view returns (uint256) {
        return soilParameters.growthNutrientThreshold;
    }

    // --- Minting & Generation ---

    /**
     * @notice Plants a new unique digital flora NFT.
     * @param _userSeed A user-provided string to influence the generation seed (optional).
     * @dev Requires the sender to have approved this contract to spend the planting cost in Nutrient tokens.
     */
    function plantFlora(string memory _userSeed) external payable nonReentrant whenNotPaused {
        require(address(nutrientToken) != address(0), "Nutrient token not set");
        require(soilParameters.plantingCost > 0, "Planting is not enabled (cost is zero)");
        require(nutrientToken.transferFrom(msg.sender, address(this), soilParameters.plantingCost), "Nutrient transfer failed");

        uint256 currentTokenId = _nextTokenId++;
        bytes32 seed = keccak256(abi.encodePacked(
            currentTokenId,
            msg.sender,
            block.timestamp,
            block.difficulty, // block.difficulty is deprecated, but useful for example seed input. Use block.randao_mix in newer versions.
            _userSeed,
            soilParameters.temperatureInfluence,
            soilParameters.soilCompositionInfluence
        ));

        FloraTraits memory newTraits = _generateTraits(seed, soilParameters);
        newTraits.seed = seed; // Store the seed for this specific plant
        newTraits.growthStage = 0; // Starts at stage 0
        newTraits.mutationFactor = uint8((uint256(keccak256(abi.encodePacked(seed, "mutationFactor"))) % (MAX_MUTATION_FACTOR + 1)));
        newTraits.accumulatedNutrients = 0; // Starts with 0 accumulated nutrients

        _floraTraits[currentTokenId] = newTraits;
        _safeMint(msg.sender, currentTokenId);

        emit FloraPlanted(currentTokenId, msg.sender, seed);
    }

    /**
     * @dev Internal helper to generate initial flora traits based on a seed and current parameters.
     * @param seed The unique seed for this flora.
     * @param currentParameters The global soil parameters at the time of planting.
     * @return A FloraTraits struct with initial traits.
     */
    function _generateTraits(bytes32 seed, Parameters memory currentParameters) internal view returns (FloraTraits memory) {
        FloraTraits memory traits;

        // Use parts of the seed and parameters for deterministic trait selection
        bytes32 traitHash = keccak256(abi.encodePacked(seed, "traits"));

        // Apply parameter influence (simplified)
        // e.g., higher tempInfluence shifts colors towards warmer palettes
        int256 adjustedTemperature = int256(uint256(traitHash) % 100) + currentParameters.temperatureInfluence;
        int256 adjustedSoilComposition = int256(uint256(keccak256(abi.encodePacked(traitHash, "soil"))) % 100) + currentParameters.soilCompositionInfluence;

        // Deterministically select traits based on adjusted values and seed
        uint256 stemIndex = (uint256(keccak256(abi.encodePacked(seed, "stem"))) + uint256(uint160(adjustedSoilComposition))) % stemTypes.length;
        uint256 leafIndex = (uint256(keccak256(abi.encodePacked(seed, "leaf"))) + uint256(uint160(adjustedSoilComposition / 2))) % leafShapes.length;
        uint256 colorIndex = (uint256(keccak256(abi.encodePacked(seed, "color"))) + uint256(uint160(adjustedTemperature))) % colorPalettes.length;

        traits.stemTypeIndex = uint8(stemIndex);
        traits.leafShapeIndex = uint8(leafIndex);
        traits.colorPaletteIndex = uint8(colorIndex);

        // Calculate a simple rarity score (example: based on trait indices)
        traits.rarityScore = uint16(
            (stemIndex * leafShapes.length * colorPalettes.length +
             leafIndex * colorPalettes.length +
             colorIndex) % (MAX_RARITY_SCORE + 1)
        );


        return traits;
    }

    // --- Flora State Interaction ---

    /**
     * @notice Provides Nutrient tokens to a specific flora, contributing to its growth potential.
     * @param tokenId The ID of the flora token.
     * @param amount The amount of Nutrient tokens to provide.
     * @dev Requires the sender to be the owner of the flora and have approved this contract
     *      to spend the amount in Nutrient tokens.
     */
    function provideNutrients(uint256 tokenId, uint256 amount) external nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not flora owner");
        require(address(nutrientToken) != address(0), "Nutrient token not set");
        require(amount > 0, "Amount must be greater than zero");

        require(nutrientToken.transferFrom(msg.sender, address(this), amount), "Nutrient transfer failed");

        FloraTraits storage traits = _floraTraits[tokenId];
        traits.accumulatedNutrients += amount;

        // Check if enough nutrients accumulated for next growth stage
        if (traits.growthStage < MAX_GROWTH_STAGE) {
             uint256 stagesToGrow = traits.accumulatedNutrients / soilParameters.growthNutrientThreshold;
             if (stagesToGrow > 0) {
                 traits.growthStage = uint8(Math.min(traits.growthStage + stagesToGrow, MAX_GROWTH_STAGE));
                 traits.accumulatedNutrients %= soilParameters.growthNutrientThreshold; // Keep remainder
             }
        }


        emit NutrientsProvided(tokenId, amount, traits.accumulatedNutrients);
    }

    /**
     * @notice Attempts to mutate a flora. This can potentially change its traits.
     * @param tokenId The ID of the flora token.
     * @dev Requires the sender to be the owner, the flora to be ready for mutation,
     *      and payment in Nutrient tokens. Outcome is deterministic pseudo-random.
     */
    function requestMutation(uint256 tokenId) external nonReentrant {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not flora owner");
        require(address(nutrientToken) != address(0), "Nutrient token not set");
        require(soilParameters.mutationCost > 0, "Mutation is not enabled (cost is zero)");
        require(canMutate(tokenId), "Flora not ready for mutation"); // Requires sufficient growth/state

        require(nutrientToken.transferFrom(msg.sender, address(this), soilParameters.mutationCost), "Nutrient transfer failed");

        FloraTraits storage traits = _floraTraits[tokenId];

        // Consume a portion of accumulated nutrients upon mutation attempt
        uint256 nutrientsConsumed = traits.accumulatedNutrients / 2; // Example: consume half
        traits.accumulatedNutrients -= nutrientsConsumed;

        // Deterministic pseudo-randomness for mutation outcome
        bytes32 mutationSeed = keccak256(abi.encodePacked(
            tokenId,
            block.timestamp,
            block.difficulty, // Use block.randao_mix
            msg.sender,
            traits.seed, // Incorporate original seed
            traits.growthStage, // Incorporate current state
            traits.mutationFactor,
            nutrientsConsumed
        ));

        // --- Mutation Logic ---
        bool mutationSuccess = false;
        string memory outcomeDescription = "No significant change.";

        uint256 randomValue = uint256(mutationSeed);
        uint256 mutationRoll = randomValue % 10000; // 0-9999 for percentage with 2 decimals

        // Base chance + influence from growth stage and mutation factor
        uint256 effectiveMutationChance = soilParameters.baseMutationChance * 100; // Convert base to 0-9999 scale
        effectiveMutationChance += (traits.growthStage * 500); // +5% chance per growth stage
        effectiveMutationChance += (traits.mutationFactor * 10); // +1% chance per mutation factor point

        if (mutationRoll < effectiveMutationChance) {
            mutationSuccess = true;
             outcomeDescription = "Mutation successful!";
            _applyMutation(tokenId, mutationSeed);
        } else {
            outcomeDescription = "Mutation attempt failed.";
        }

        // Reduce growth stage or mutation factor regardless of success (example: adds risk)
         traits.growthStage = uint8(Math.max(0, int256(traits.growthStage) - 1)); // Decrement stage
         traits.mutationFactor = uint8(Math.max(0, int256(traits.mutationFactor) - int256(mutationRoll % 10))); // Decrease factor slightly


        emit MutationAttempted(tokenId, mutationSuccess, outcomeDescription);
    }

    /**
     * @dev Internal helper to apply trait changes during a successful mutation.
     *      This is where complex mutation rules based on parameters and state would go.
     * @param tokenId The ID of the flora token.
     * @param mutationSeed A seed specific to this mutation attempt.
     */
    function _applyMutation(uint256 tokenId, bytes32 mutationSeed) internal {
        FloraTraits storage traits = _floraTraits[tokenId];
        uint256 mutationRoll = uint256(mutationSeed);

        // Example Mutation Logic:
        // Slightly shift trait indices based on mutation seed and mutation factor
        uint256 shiftAmount = (uint256(traits.mutationFactor) + 1) / 10; // Higher factor = bigger shift

        // Ensure shifts wrap around within trait bounds
        traits.stemTypeIndex = uint8((uint256(traits.stemTypeIndex) + (mutationRoll % (shiftAmount + 1))) % stemTypes.length);
        traits.leafShapeIndex = uint8((uint256(traits.leafShapeIndex) + (uint256(keccak256(abi.encodePacked(mutationSeed, "leafShift"))) % (shiftAmount + 1)))) % leafShapes.length;
        traits.colorPaletteIndex = uint8((uint256(traits.colorPaletteIndex) + (uint256(keccak256(abi.encodePacked(mutationSeed, "colorShift"))) % (shiftAmount + 1)))) % colorPalettes.length;

        // Mutation might also slightly change rarity or mutationFactor itself
        traits.rarityScore = uint16(Math.min(uint256(traits.rarityScore) + (mutationRoll % 100) - 50, MAX_RARITY_SCORE)); // +/- 50 rarity
        traits.mutationFactor = uint8(Math.min(uint256(traits.mutationFactor) + (uint256(keccak256(abi.encodePacked(mutationSeed, "mfShift"))) % 20) - 10, MAX_MUTATION_FACTOR)); // +/- 10 factor
    }

    /**
     * @notice Checks if a flora token is currently eligible to attempt mutation.
     * @param tokenId The ID of the flora token.
     * @return True if mutation is possible, false otherwise.
     */
    function canMutate(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        FloraTraits storage traits = _floraTraits[tokenId];
        // Example condition: Must be at least stage 1 and have some accumulated nutrients
        return traits.growthStage >= 1 && traits.accumulatedNutrients > 0;
    }

    // --- Data Retrieval ---

    /**
     * @notice Returns the current traits of a specific flora token.
     * @param tokenId The ID of the flora token.
     * @return A FloraTraits struct.
     */
    function getFloraTraits(uint256 tokenId) public view returns (FloraTraits memory) {
        require(_exists(tokenId), "Token does not exist");
        return _floraTraits[tokenId];
    }

     /**
     * @notice Returns the original generation seed for a specific flora token.
     * @param tokenId The ID of the flora token.
     * @return The bytes32 seed.
     */
    function getFloraSeed(uint256 tokenId) public view returns (bytes32) {
         require(_exists(tokenId), "Token does not exist");
         return _floraTraits[tokenId].seed;
     }

    /**
     * @notice Returns the current growth stage of a specific flora token.
     * @param tokenId The ID of the flora token.
     * @return The growth stage (0 to MAX_GROWTH_STAGE).
     */
    function getGrowthStage(uint256 tokenId) public view returns (uint8) {
        require(_exists(tokenId), "Token does not exist");
        return _floraTraits[tokenId].growthStage;
    }


    /**
     * @notice Generates a human-readable description string for a flora based on its traits.
     * @param tokenId The ID of the flora token.
     * @return A string description.
     */
    function getTraitDescription(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        FloraTraits memory traits = _floraTraits[tokenId];

        string memory stem = stemTypes[traits.stemTypeIndex % stemTypes.length];
        string memory leaf = leafShapes[traits.leafShapeIndex % leafShapes.length];
        string memory color = colorPalettes[traits.colorPaletteIndex % colorPalettes.length];
        string memory growth = traits.growthStage.toString();
        string memory rarity = traits.rarityScore.toString();

        return string(abi.encodePacked(
            "A digital flora with a ", stem, " stem, ", leaf, " leaves, and a ", color, " palette. ",
            "Growth Stage: ", growth, ". Rarity Score: ", rarity, "."
        ));
    }


    /**
     * @notice Returns the metadata for a token as a Data URI (ERC721 Metadata JSON Schema).
     * @dev Includes generated traits and description.
     * @param tokenId The ID of the flora token.
     * @return A string containing the Data URI.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        FloraTraits memory traits = _floraTraits[tokenId];
        string memory description = getTraitDescription(tokenId);

        // Construct the JSON string
        string memory json = string(abi.encodePacked(
            '{',
                '"name": "Digital Flora #', tokenId.toString(), '",',
                '"description": "', description, '",',
                '"image": "ipfs://REPLACE_WITH_IMAGE_CID",', // Placeholder - image would be generated off-chain
                '"attributes": [',
                    '{', '"trait_type": "Stem Type", "value": "', stemTypes[traits.stemTypeIndex % stemTypes.length], '" },',
                    '{', '"trait_type": "Leaf Shape", "value": "', leafShapes[traits.leafShapeIndex % leafShapes.length], '" },',
                    '{', '"trait_type": "Color Palette", "value": "', colorPalettes[traits.colorPaletteIndex % colorPalettes.length], '" },',
                    '{', '"trait_type": "Growth Stage", "value": ', traits.growthStage.toString(), ' },',
                    '{', '"trait_type": "Mutation Factor", "value": ', traits.mutationFactor.toString(), ' },',
                    '{', '"trait_type": "Rarity Score", "value": ', traits.rarityScore.toString(), ' }',
                    // Add more attributes based on traits...
                ']',
            '}'
        ));

        // Return as Data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // --- Governance Functions ---

    /**
     * @notice Allows users to submit a proposal to change a global soil parameter.
     * @param parameterKey A bytes32 identifier for the parameter (e.g., keccak256("temperatureInfluence")).
     * @param newValue The proposed new integer value for the parameter.
     * @dev Simple voting based on block number duration.
     */
    function submitParameterChangeProposal(bytes32 parameterKey, int256 newValue) external {
        // In a real system, could require owning minimum number of flora or have voting power token
        // require(balanceOf(msg.sender) > 0, "Must own flora to submit proposal"); // Example gate

        uint256 proposalId = _nextProposalId++;
        _proposals[proposalId] = Proposal({
            parameterKey: parameterKey,
            newValue: newValue,
            expirationBlock: block.number + soilParameters.proposalVotingPeriodBlocks,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, parameterKey, newValue, _proposals[proposalId].expirationBlock);
    }

    /**
     * @notice Allows users to vote on an active proposal.
     * @param proposalId The ID of the proposal.
     * @param support True to vote for the proposal, false to vote against.
     * @dev Simple 1-address-1-vote per proposal.
     */
    function voteOnProposal(uint256 proposalId, bool support) external {
         require(_proposals[proposalId].expirationBlock > 0, "Proposal does not exist"); // Checks if proposal exists
         require(_proposals[proposalId].state == ProposalState.Active, "Proposal not in active state");
         require(_proposals[proposalId].expirationBlock > block.number, "Voting period has ended");
         require(!_proposals[proposalId].hasVoted[msg.sender], "Already voted on this proposal");
         // require(balanceOf(msg.sender) > 0, "Must own flora to vote"); // Example gate

        Proposal storage proposal = _proposals[proposalId];
        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @notice Allows anyone to execute a proposal if its voting period has ended and it passed.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.expirationBlock > 0, "Proposal does not exist");
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.number >= proposal.expirationBlock, "Voting period not ended");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        // Check quorum and threshold
        if (totalVotes >= soilParameters.proposalQuorum &&
            proposal.votesFor * 10000 / totalVotes >= soilParameters.proposalThreshold) {
            // Proposal succeeded, apply the change
            bytes32 key = proposal.parameterKey;
            int256 newValue = proposal.newValue;

            // Using keccak256 strings as keys for simplicity.
            // In a real system, map keys to specific storage slots or setters.
            // This requires knowing the string representation of the key.
            if (key == keccak256("temperatureInfluence")) {
                soilParameters.temperatureInfluence = newValue;
            } else if (key == keccak256("soilCompositionInfluence")) {
                 soilParameters.soilCompositionInfluence = newValue;
            } else if (key == keccak256("baseMutationChance")) {
                 require(newValue >= 0 && newValue <= 100, "Invalid baseMutationChance value");
                 soilParameters.baseMutationChance = uint256(newValue);
            } else if (key == keccak256("growthNutrientThreshold")) {
                 require(newValue >= 0, "Invalid growthNutrientThreshold value");
                 soilParameters.growthNutrientThreshold = uint256(newValue);
            } else if (key == keccak256("plantingCost")) {
                 require(newValue >= 0, "Invalid plantingCost value");
                 soilParameters.plantingCost = uint256(newValue);
            } else if (key == keccak256("mutationCost")) {
                 require(newValue >= 0, "Invalid mutationCost value");
                 soilParameters.mutationCost = uint256(newValue);
            } else if (key == keccak256("proposalVotingPeriodBlocks")) {
                 require(newValue > 0, "Invalid voting period value");
                 soilParameters.proposalVotingPeriodBlocks = uint256(newValue);
            } else if (key == keccak256("proposalQuorum")) {
                 require(newValue >= 0, "Invalid quorum value");
                 soilParameters.proposalQuorum = uint256(newValue);
            } else if (key == keccak256("proposalThreshold")) {
                 require(newValue >= 0 && newValue <= 10000, "Invalid threshold value"); // 0-10000 for 0-100%
                 soilParameters.proposalThreshold = uint256(newValue);
            } else {
                 // Unknown parameter key - mark as failed? Or ignore and proceed?
                 // For this example, we'll just mark the proposal as failed if key is unknown
                 proposal.state = ProposalState.Failed;
                 emit ProposalStateChanged(proposalId, ProposalState.Failed);
                 revert("Unknown parameter key"); // Or just return false
            }

            proposal.state = ProposalState.Executed;
            emit ParametersUpdated(key, newValue);
            emit ProposalStateChanged(proposalId, ProposalState.Executed);

        } else {
            // Proposal failed
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
        }
    }

    /**
     * @notice Gets the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The state of the proposal (Pending, Active, Succeeded, Failed, Executed).
     */
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        require(_proposals[proposalId].expirationBlock > 0, "Proposal does not exist");
        Proposal storage proposal = _proposals[proposalId];

        // Update state if voting period ended and state is still active
        if (proposal.state == ProposalState.Active && block.number >= proposal.expirationBlock) {
             uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
             if (totalVotes >= soilParameters.proposalQuorum &&
                proposal.votesFor * 10000 / totalVotes >= soilParameters.proposalThreshold) {
                return ProposalState.Succeeded; // Succeeded but not yet Executed
             } else {
                return ProposalState.Failed; // Failed
             }
        }

        return proposal.state; // Pending, Active, Executed, or already Failed/Succeeded manually set
    }

     /**
     * @notice Gets the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return parameterKey, newValue, expirationBlock, votesFor, votesAgainst, state.
     */
    function getProposal(uint256 proposalId) public view returns (bytes32 parameterKey, int256 newValue, uint256 expirationBlock, uint256 votesFor, uint256 votesAgainst, ProposalState state) {
         require(_proposals[proposalId].expirationBlock > 0, "Proposal does not exist");
         Proposal storage proposal = _proposals[proposalId];
         return (proposal.parameterKey, proposal.newValue, proposal.expirationBlock, proposal.votesFor, proposal.votesAgainst, getProposalState(proposalId));
     }


    /**
     * @notice Returns the currently active global soil parameters.
     * @return The Parameters struct.
     */
    function getCurrentSoilParameters() public view returns (Parameters memory) {
        return soilParameters;
    }

    // --- Override ERC721 internal functions ---

    // Required for ERC721 standard implementation
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // Optional: Hook into transfers to handle potential future logic (e.g., trait changes on transfer)
    // function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
    //     super._beforeTokenTransfer(from, to, tokenId, batchSize);
    //     // Add custom logic here if needed before transfer
    // }
}

// Dummy ERC20 contract for local testing (replace with actual deployed contract address)
/*
contract FloraNutrients is ERC20 {
    constructor() ERC20("Flora Nutrients", "NUTRI") {
        // Mint some initial tokens to the deployer for testing
        _mint(msg.sender, 1000000e18); // Example: 1 million tokens
    }
}
*/
```