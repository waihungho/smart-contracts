Okay, let's design a smart contract that embodies some advanced, creative concepts, moving beyond standard token or simple NFT mechanics. We'll build a system around mutable, state-dependent digital assets that can be combined ("fused") to create new, unique assets, inspired by abstract "quantum" principles like superposition, entanglement, and decoherence (simulated, of course, as true quantum computing isn't on-chain).

This contract will manage a single ERC-721 collection, where each token represents either a base "Quanta" particle or a composite "Entanglement". Quanta have dynamic properties (state, energy, spin), while Entanglements are the results of successful fusions.

**Outline & Function Summary:**

**Contract Name:** `QuantumFusion`

**Core Concept:** Manage a collection of ERC-721 tokens representing "Quanta" (mutable state, energy, spin) and "Entanglements" (immutable result of fusion). Users can generate Quanta, attempt to fuse them based on recipes, stake Quanta to stabilize them, observe Quanta to fix their state, and experience simulated "decoherence" which can alter unstaked/unobserved Quanta states.

**Modules:**
1.  **ERC-721 Standard:** Basic NFT ownership, transfer, approval functions.
2.  **Quanta Management:** Functions to generate, query properties, stake, unstake, observe, increase energy, and transfer state of Quanta tokens.
3.  **Entanglement Management:** Functions to query properties and potentially disentangle (break down) Entanglement tokens.
4.  **Fusion Mechanics:** Function to attempt fusing multiple Quanta into an Entanglement based on predefined recipes. Includes probabilistic success/failure.
5.  **Decoherence Mechanic:** A function (potentially permissioned or callable by anyone with a reward) that simulates state decay for unstaked/unobserved Quanta.
6.  **Batch Operations:** Convenient functions for performing actions on multiple tokens at once.
7.  **Governance/Admin:** Functions for setting parameters, pausing, and managing permissions.
8.  **Query Functions:** View functions to retrieve contract state and token properties.

**Function Summary (>= 20 Functions):**

1.  `constructor()`: Initializes the contract with base parameters and ownership.
2.  `pause()`: Pauses core contract mechanics (minting, fusion, staking, state changes). (Admin)
3.  `unpause()`: Unpauses the contract. (Admin)
4.  `withdrawETH()`: Withdraws collected ETH (from generation fees). (Admin)
5.  `setQuantaGenerationCost(uint8 quantaType, uint256 cost)`: Sets the ETH cost to generate a specific type of Quanta. (Admin)
6.  `setFusionRecipe(uint8[] calldata inputQuantaTypes, uint8 outputEntanglementType, uint16 successRate, uint256 failureEnergyLoss)`: Defines or updates a fusion recipe. (Admin)
7.  `removeFusionRecipe(uint8[] calldata inputQuantaTypes)`: Removes a fusion recipe. (Admin)
8.  `setDecoherenceParameters(uint16 probability, uint8 maxStateChange)`: Sets the parameters for the decoherence mechanic. (Admin)
9.  `grantDecoherencePermission(address user, bool permission)`: Grants or revokes permission to call `applyDecoherenceToQuanta`. (Admin)
10. `setBaseURI(string calldata baseURI)`: Sets the base URI for token metadata. (Admin)
11. `setEntanglementPrefix(string calldata prefix)`: Sets a distinct prefix for Entanglement tokenURIs. (Admin)
12. `generateQuanta(uint8 quantaType) payable`: Mints a new Quanta token of a specific type, costs ETH.
13. `attemptFusion(uint256[] calldata quantaTokenIds)`: Attempts to fuse owned Quanta tokens based on matching a recipe. Probabilistic success. Burns inputs on success (minting Entanglement) or modifies inputs on failure.
14. `disentangle(uint256 entanglementTokenId)`: Attempts to break down an Entanglement back into component-like Quanta. Probabilistic success/failure. Burns Entanglement.
15. `stakeQuanta(uint256 quantaTokenId)`: Stakes an owned Quanta token, making it immune to decoherence and potentially boosting energy over time (simulated by `increaseQuantaEnergy`).
16. `unstakeQuanta(uint256 quantaTokenId)`: Unstakes a previously staked Quanta token.
17. `observeQuanta(uint256 quantaTokenId)`: "Observes" an owned Quanta token, fixing its state permanently but preventing staking or further state changes (except disentanglement).
18. `applyDecoherenceToQuanta(uint256 quantaTokenId)`: Attempts to apply simulated decoherence to a *single* unstaked, unobserved Quanta token. State might change based on probability/parameters. (Permissioned)
19. `increaseQuantaEnergy(uint256 quantaTokenId) payable`: Increases the energy of an owned, unobserved Quanta token, costing ETH.
20. `transferQuantaState(uint256 fromTokenId, uint256 toTokenId)`: Transfers the state property from one owned Quanta to another owned Quanta, potentially costing energy from the source. Both must be unstaked and unobserved.
21. `batchGenerateQuanta(uint8[] calldata quantaTypes) payable`: Generates multiple Quanta tokens in a single transaction.
22. `batchStakeQuanta(uint256[] calldata quantaTokenIds)`: Stakes multiple Quanta tokens.
23. `batchUnstakeQuanta(uint256[] calldata quantaTokenIds)`: Unstakes multiple Quanta tokens.
24. `batchObserveQuanta(uint256[] calldata quantaTokenIds)`: Observes multiple Quanta tokens.
25. `batchIncreaseQuantaEnergy(uint256[] calldata quantaTokenIds) payable`: Increases energy for multiple Quanta tokens.
26. `balanceOf(address owner) view returns (uint256)`: ERC721 standard.
27. `ownerOf(uint256 tokenId) view returns (address)`: ERC721 standard.
28. `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
29. `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard.
30. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: ERC721 standard.
31. `approve(address to, uint256 tokenId)`: ERC721 standard.
32. `getApproved(uint256 tokenId) view returns (address)`: ERC721 standard.
33. `setApprovalForAll(address operator, bool approved)`: ERC721 standard.
34. `isApprovedForAll(address owner, address operator) view returns (bool)`: ERC721 standard.
35. `tokenURI(uint256 tokenId) view returns (string memory)`: ERC721 standard, generates URI based on token type (Quanta/Entanglement) and properties.
36. `getQuantaProperties(uint256 tokenId) view returns (QuantaProperties memory)`: Queries all properties of a Quanta token.
37. `getEntanglementProperties(uint256 tokenId) view returns (EntanglementProperties memory)`: Queries all properties of an Entanglement token.
38. `isEntanglement(uint256 tokenId) view returns (bool)`: Helper to check if a token ID represents an Entanglement.
39. `getFusionRecipe(uint8[] calldata inputQuantaTypes) view returns (FusionRecipe memory)`: Queries a specific fusion recipe.
40. `getDecoherenceParameters() view returns (uint16 probability, uint8 maxStateChange)`: Queries current decoherence parameters.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol"; // Example import, might not be strictly used in final code structure but shows potential advanced concept integration
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ handles overflow, explicit SafeMath can clarify intent in complex arithmetic. Let's stick to native checks where possible in 0.8+.

// Note on Randomness: Using block.timestamp and block.difficulty (coinbase) is NOT secure
// or truly random for on-chain logic susceptible to miner manipulation. For production,
// use Chainlink VRF or a similar decentralized oracle for secure randomness.
// This contract uses block.timestamp/block.number for simulation purposes only.

/**
 * @title QuantumFusion
 * @dev An advanced ERC721 contract managing dynamic "Quanta" tokens and fused "Entanglement" tokens.
 * Quanta have mutable states (State, Energy, Spin) that can be affected by staking, observation,
 * fusion attempts, and simulated decoherence. Entanglements are the results of successful fusion.
 * Includes complex mechanics like state transfer, probabilistic fusion, and batch operations.
 */
contract QuantumFusion is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // Using for clarity in calculations

    // --- Outline & Function Summary ---
    // Modules: ERC721, Quanta Management, Entanglement Management, Fusion Mechanics,
    // Decoherence Mechanic, Batch Operations, Governance/Admin, Query Functions.

    // Functions:
    // 1. constructor()
    // 2. pause() (Admin)
    // 3. unpause() (Admin)
    // 4. withdrawETH() (Admin)
    // 5. setQuantaGenerationCost(uint8 quantaType, uint256 cost) (Admin)
    // 6. setFusionRecipe(uint8[] calldata inputQuantaTypes, uint8 outputEntanglementType, uint16 successRate, uint256 failureEnergyLoss) (Admin)
    // 7. removeFusionRecipe(uint8[] calldata inputQuantaTypes) (Admin)
    // 8. setDecoherenceParameters(uint16 probability, uint8 maxStateChange) (Admin)
    // 9. grantDecoherencePermission(address user, bool permission) (Admin)
    // 10. setBaseURI(string calldata baseURI) (Admin)
    // 11. setEntanglementPrefix(string calldata prefix) (Admin)
    // 12. generateQuanta(uint8 quantaType) payable
    // 13. attemptFusion(uint256[] calldata quantaTokenIds)
    // 14. disentangle(uint256 entanglementTokenId)
    // 15. stakeQuanta(uint256 quantaTokenId)
    // 16. unstakeQuanta(uint256 quantaTokenId)
    // 17. observeQuanta(uint256 quantaTokenId)
    // 18. applyDecoherenceToQuanta(uint256 quantaTokenId) (Permissioned)
    // 19. increaseQuantaEnergy(uint256 quantaTokenId) payable
    // 20. transferQuantaState(uint256 fromTokenId, uint256 toTokenId)
    // 21. batchGenerateQuanta(uint8[] calldata quantaTypes) payable
    // 22. batchStakeQuanta(uint256[] calldata quantaTokenIds)
    // 23. batchUnstakeQuanta(uint256[] calldata quantaTokenIds)
    // 24. batchObserveQuanta(uint256[] calldata quantaTokenIds)
    // 25. batchIncreaseQuantaEnergy(uint256[] calldata quantaTokenIds) payable
    // 26. balanceOf(address owner) view returns (uint256) (ERC721)
    // 27. ownerOf(uint256 tokenId) view returns (address) (ERC721)
    // 28. transferFrom(address from, address to, uint256 tokenId) (ERC721)
    // 29. safeTransferFrom(address from, address to, uint256 tokenId) (ERC721)
    // 30. safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) (ERC721)
    // 31. approve(address to, uint256 tokenId) (ERC721)
    // 32. getApproved(uint256 tokenId) view returns (address) (ERC721)
    // 33. setApprovalForAll(address operator, bool approved) (ERC721)
    // 34. isApprovedForAll(address owner, address operator) view returns (bool) (ERC721)
    // 35. tokenURI(uint256 tokenId) view returns (string memory) (ERC721)
    // 36. getQuantaProperties(uint256 tokenId) view returns (QuantaProperties memory)
    // 37. getEntanglementProperties(uint256 tokenId) view returns (EntanglementProperties memory)
    // 38. isEntanglement(uint256 tokenId) view returns (bool)
    // 39. getFusionRecipe(uint8[] calldata inputQuantaTypes) view returns (FusionRecipe memory)
    // 40. getDecoherenceParameters() view returns (uint16 probability, uint8 maxStateChange)

    // --- Error Handling ---
    error InvalidQuantaType();
    error InsufficientPayment(uint256 required, uint256 provided);
    error NotOwnerOfToken(uint256 tokenId);
    error NotEnoughQuantaForFusion();
    error OnlyQuantaCanBeFused(uint256 tokenId);
    error FusionRecipeNotFound();
    error FusionFailed(uint256[] inputIds, string reason);
    error TokenDoesNotExist(uint256 tokenId);
    error NotAnEntanglement(uint256 tokenId);
    error OnlyEntanglementCanBeDisentangled(uint256 tokenId);
    error QuantaIsStaked(uint256 tokenId);
    error QuantaIsNotStaked(uint256 tokenId);
    error QuantaIsObserved(uint256 tokenId);
    error QuantaIsNotObserved(uint256 tokenId);
    error DecoherencePermissionDenied();
    error QuantaEnergyTooLow(uint256 tokenId, uint16 currentEnergy, uint16 required);
    error CannotTransferStateToSelf();
    error InvalidBatchSize();
    error InputArrayLengthMismatch();
    error OnlyQuantaCanHaveStateTransferred(uint256 tokenId);
    error DecoherenceConditionsNotMet(uint256 tokenId); // For applyDecoherenceToQuanta when conditions fail

    // --- Data Structures ---

    enum QuantaState { Stable, Excited, Superposition, Decayed }
    enum QuantaSpin { Up, Down, Polarized } // Example Spin states

    struct QuantaProperties {
        uint8 quantaType; // e.g., 1 for Electron, 2 for Proton, 3 for Neutron, etc.
        QuantaState state;
        uint16 energy; // e.g., 0-1000
        QuantaSpin spin;
        bool observed; // State is fixed if observed
        uint64 stakeEndTime; // 0 if not staked, timestamp if staked
    }

    struct EntanglementProperties {
        uint8 entanglementType; // e.g., 1 for Hydrogen, 2 for Helium, etc.
        // Storing fusedQuantaIds can get expensive. Maybe store a hash or root?
        // For demo, let's store a reduced set or just the type.
        // uint256[] fusedQuantaIds; // Potentially expensive
    }

    struct FusionRecipe {
        uint8[] inputQuantaTypes; // Sorted array of types required
        uint8 outputEntanglementType;
        uint16 successRate; // Rate out of 10000 (e.g., 7500 for 75%)
        uint256 failureEnergyLoss; // Energy lost by input Quanta on failure
    }

    // --- State Variables ---

    // Token ID Management:
    // We'll use a single ERC721 collection. Token IDs below a threshold are Quanta, above are Entanglements.
    uint256 private constant QUANTA_ID_THRESHOLD = 1_000_000_000;
    Counters.Counter private _nextTokenId; // Starts at 1

    // Token Data Storage:
    mapping(uint256 => QuantaProperties) private _quantaData;
    mapping(uint256 => EntanglementProperties) private _entanglementData; // Minimal data for Entanglements

    // Governance Parameters:
    mapping(uint8 => uint256) private _quantaGenerationCosts; // quantaType => cost in wei
    mapping(bytes32 => FusionRecipe) private _fusionRecipes; // hash(sorted input types) => recipe
    uint16 private _decoherenceProbability; // Probability out of 10000
    uint8 private _decoherenceMaxStateChange; // Max steps state can change (Stable->Excited->Superposition->Decayed)

    // Decoherence Permissions
    mapping(address => bool) private _decoherencePermissions;

    // Metadata
    string private _baseURI;
    string private _entanglementPrefix;

    // --- Events ---

    event QuantaGenerated(address indexed owner, uint256 indexed tokenId, uint8 quantaType, QuantaState initialState, uint16 initialEnergy, QuantaSpin initialSpin);
    event FusionAttempted(address indexed smoother, uint256[] indexed inputTokenIds);
    event FusionSuccessful(address indexed smoother, uint256[] inputTokenIds, uint256 indexed newTokenId, uint8 entanglementType);
    event FusionFailed(address indexed smoother, uint256[] inputTokenIds, string reason);
    event EntanglementDisentangled(address indexed owner, uint256 indexed entanglementTokenId, uint256[] generatedQuantaIds);
    event QuantaStaked(address indexed owner, uint256 indexed tokenId, uint64 stakeUntil);
    event QuantaUnstaked(address indexed owner, uint256 indexed tokenId);
    event QuantaObserved(address indexed owner, uint256 indexed tokenId);
    event QuantaStateChanged(uint256 indexed tokenId, QuantaState oldState, QuantaState newState, string reason);
    event QuantaEnergyChanged(uint256 indexed tokenId, uint16 oldEnergy, uint16 newEnergy, string reason);
    event QuantaSpinChanged(uint256 indexed tokenId, QuantaSpin oldSpin, QuantaSpin newSpin, string reason);
    event QuantaStateTransferred(address indexed owner, uint256 indexed fromTokenId, uint256 indexed toTokenId, QuantaState transferredState);
    event DecoherenceApplied(uint256 indexed tokenId, QuantaState newState, string reason);
    event FusionRecipeUpdated(bytes32 indexed recipeHash, uint8[] inputQuantaTypes, uint8 outputEntanglementType, uint16 successRate);

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Modifiers ---

    modifier onlyQuanta(uint256 tokenId) {
        if (isEntanglement(tokenId)) revert OnlyQuantaCanBeFused(tokenId);
        _;
    }

     modifier onlyEntanglement(uint256 tokenId) {
        if (!isEntanglement(tokenId)) revert OnlyEntanglementCanBeDisentangled(tokenId);
        _;
    }

    modifier onlyDecoherencePermissioned() {
        if (!_decoherencePermissions[msg.sender] && msg.sender != owner()) revert DecoherencePermissionDenied();
        _;
    }

    // --- Admin/Governance Functions ---

    /**
     * @dev Pauses core contract actions. Only callable by the owner.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses core contract actions. Only callable by the owner.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev Allows the owner to withdraw accumulated ETH (e.g., from generation fees).
     */
    function withdrawETH() external onlyOwner {
        (bool success,) = owner().call{value: address(this).balance}("");
        require(success, "ETH withdrawal failed");
    }

    /**
     * @dev Sets the required ETH cost for generating a specific Quanta type.
     * @param quantaType The type identifier of the Quanta.
     * @param cost The cost in wei.
     */
    function setQuantaGenerationCost(uint8 quantaType, uint256 cost) external onlyOwner {
        _quantaGenerationCosts[quantaType] = cost;
    }

    /**
     * @dev Defines or updates a fusion recipe. Input types must be sorted before hashing.
     * @param inputQuantaTypes Array of required Quanta types (must be sorted ascending).
     * @param outputEntanglementType The type identifier of the resulting Entanglement.
     * @param successRate Probability of success (out of 10000).
     * @param failureEnergyLoss Energy lost by input Quanta on failure.
     */
    function setFusionRecipe(uint8[] calldata inputQuantaTypes, uint8 outputEntanglementType, uint16 successRate, uint256 failureEnergyLoss) external onlyOwner {
        require(inputQuantaTypes.length > 0, "Input types cannot be empty");
        // In a real scenario, you'd sort inputQuantaTypes here before hashing
        // For simplicity in this example, assume admin provides sorted types.
        bytes32 recipeHash = keccak256(abi.encodePacked(inputQuantaTypes));
        _fusionRecipes[recipeHash] = FusionRecipe(inputQuantaTypes, outputEntanglementType, successRate, failureEnergyLoss);
        emit FusionRecipeUpdated(recipeHash, inputQuantaTypes, outputEntanglementType, successRate);
    }

     /**
     * @dev Removes a fusion recipe based on its input types.
     * @param inputQuantaTypes Array of required Quanta types (must be sorted ascending) identifying the recipe.
     */
    function removeFusionRecipe(uint8[] calldata inputQuantaTypes) external onlyOwner {
         require(inputQuantaTypes.length > 0, "Input types cannot be empty");
         bytes32 recipeHash = keccak256(abi.encodePacked(inputQuantaTypes));
         delete _fusionRecipes[recipeHash];
    }


    /**
     * @dev Sets the parameters for the simulated decoherence mechanic.
     * @param probability Probability of state change (out of 10000) per application.
     * @param maxStateChange Maximum steps a state can change (e.g., 1 = Stable to Excited, 2 = Stable to Superposition).
     */
    function setDecoherenceParameters(uint16 probability, uint8 maxStateChange) external onlyOwner {
        _decoherenceProbability = probability;
        _decoherenceMaxStateChange = maxStateChange;
    }

    /**
     * @dev Grants or revokes permission for an address to call applyDecoherenceToQuanta.
     * @param user The address to grant/revoke permission.
     * @param permission True to grant, false to revoke.
     */
    function grantDecoherencePermission(address user, bool permission) external onlyOwner {
        _decoherencePermissions[user] = permission;
    }

    /**
     * @dev Sets the base URI for token metadata. ERC721 standard extension.
     * @param baseURI_ The base URI string.
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

     /**
     * @dev Sets a specific prefix for Entanglement token URIs, differentiating them from Quanta.
     * @param prefix The prefix string.
     */
    function setEntanglementPrefix(string calldata prefix) external onlyOwner {
        _entanglementPrefix = prefix;
    }


    // --- Core Mechanics Functions ---

    /**
     * @dev Generates a new Quanta token of a specified type. Requires payment.
     * @param quantaType The type identifier of the Quanta to generate.
     */
    function generateQuanta(uint8 quantaType) external payable whenNotPaused {
        uint256 requiredCost = _quantaGenerationCosts[quantaType];
        if (msg.value < requiredCost) {
            revert InsufficientPayment(requiredCost, msg.value);
        }

        uint256 newTokenId = _nextTokenId.current();
        _nextTokenId.increment();

        // Basic initialization - could be randomized or type-dependent
        _quantaData[newTokenId] = QuantaProperties({
            quantaType: quantaType,
            state: QuantaState.Stable, // Initial state
            energy: 100, // Initial energy
            spin: QuantaSpin.Up, // Initial spin
            observed: false,
            stakeEndTime: 0
        });

        _safeMint(msg.sender, newTokenId);

        emit QuantaGenerated(msg.sender, newTokenId, quantaType, QuantaState.Stable, 100, QuantaSpin.Up);
    }

    /**
     * @dev Attempts to fuse a set of owned Quanta tokens into an Entanglement based on recipes.
     * Probabilistic success. Consumes input Quanta on success.
     * @param quantaTokenIds Array of token IDs of the Quanta to attempt fusing.
     */
    function attemptFusion(uint256[] calldata quantaTokenIds) external whenNotPaused {
        uint256 numInputs = quantaTokenIds.length;
        if (numInputs < 2) revert NotEnoughQuantaForFusion(); // Minimum 2 for fusion

        uint8[] memory inputTypes = new uint8[](numInputs);
        address smoother = msg.sender;

        for (uint i = 0; i < numInputs; i++) {
            uint256 tokenId = quantaTokenIds[i];
            if (ownerOf(tokenId) != smoother) revert NotOwnerOfToken(tokenId);
            if (isEntanglement(tokenId)) revert OnlyQuantaCanBeFused(tokenId);
            // Check if token exists implicitly via ownerOf or explicitly
            if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

            inputTypes[i] = _quantaData[tokenId].quantaType;
            // Could add checks here for state, energy, etc. required by recipe implicitly
            // For simplicity, recipe matching is based only on types.
        }

        // Sort input types to match recipe hash
        for (uint i = 0; i < numInputs; i++) {
            for (uint j = i + 1; j < numInputs; j++) {
                if (inputTypes[i] > inputTypes[j]) {
                    uint8 temp = inputTypes[i];
                    inputTypes[i] = inputTypes[j];
                    inputTypes[j] = temp;
                }
            }
        }

        bytes32 recipeHash = keccak256(abi.encodePacked(inputTypes));
        FusionRecipe storage recipe = _fusionRecipes[recipeHash];

        if (recipe.inputQuantaTypes.length == 0) revert FusionRecipeNotFound(); // Check if recipe exists

        emit FusionAttempted(smoother, quantaTokenIds);

        // Simulate probabilistic success
        // WARNING: block.timestamp % 10000 is NOT secure random. Use VRF in production.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, smoother))) % 10000;

        if (randomNumber < recipe.successRate) {
            // Fusion Success
            uint256 newEntanglementId = _nextTokenId.current();
            _nextTokenId.increment();

            _entanglementData[newEntanglementId] = EntanglementProperties({
                entanglementType: recipe.outputEntanglementType
                // Not storing fusedQuantaIds list for gas efficiency
            });

            // Burn or modify input Quanta
            for (uint i = 0; i < numInputs; i++) {
                 // Simplification: Burn input Quanta
                 _burn(quantaTokenIds[i]);
                 delete _quantaData[quantaTokenIds[i]];
            }

            _safeMint(smoother, newEntanglementId);
            emit FusionSuccessful(smoother, quantaTokenIds, newEntanglementId, recipe.outputEntanglementType);

        } else {
            // Fusion Failure
            // Modify input Quanta (e.g., reduce energy)
            for (uint i = 0; i < numInputs; i++) {
                uint256 inputId = quantaTokenIds[i];
                QuantaProperties storage quanta = _quantaData[inputId];
                uint16 oldEnergy = quanta.energy;
                // Ensure energy doesn't go below 0
                quanta.energy = oldEnergy > recipe.failureEnergyLoss ? uint16(oldEnergy - recipe.failureEnergyLoss) : 0;
                 emit QuantaEnergyChanged(inputId, oldEnergy, quanta.energy, "Fusion Failure");
            }
            revert FusionFailed(quantaTokenIds, "Probabilistic failure");
        }
    }

    /**
     * @dev Attempts to disentangle an owned Entanglement token back into component-like Quanta.
     * Probabilistic success. Burns the Entanglement.
     * @param entanglementTokenId The token ID of the Entanglement to disentangle.
     */
    function disentangle(uint256 entanglementTokenId) external onlyEntanglement(entanglementTokenId) whenNotPaused {
        address owner = ownerOf(entanglementTokenId);
        if (owner != msg.sender) revert NotOwnerOfToken(entanglementTokenId);
         if (!_exists(entanglementTokenId)) revert TokenDoesNotExist(entanglementTokenId);


        EntanglementProperties storage entanglement = _entanglementData[entanglementTokenId];
        uint8 entType = entanglement.entanglementType;

        // Simulate probabilistic success for disentanglement
         // WARNING: block.timestamp % 10000 is NOT secure random. Use VRF in production.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender))) % 10000;
        bool success = randomNumber < 5000; // 50% chance for demo

        _burn(entanglementTokenId);
        delete _entanglementData[entanglementTokenId];

        uint256[] memory generatedIds;

        if (success) {
             // On success, generate new Quanta based on the Entanglement type
             // This is a simplification; a real system might reverse engineer from fusedQuantaIds
             uint numToGenerate = entType % 3 + 2; // Example: 2-4 quanta generated based on type
             generatedIds = new uint256[](numToGenerate);

             for(uint i = 0; i < numToGenerate; i++) {
                 uint256 newTokenId = _nextTokenId.current();
                 _nextTokenId.increment();
                  // Basic initialization for disentangled quanta - could be varied
                  _quantaData[newTokenId] = QuantaProperties({
                      quantaType: (entType + i) % 5 + 1, // Example derived type
                      state: QuantaState.Decayed, // Start in a less ideal state
                      energy: 50,
                      spin: QuantaSpin.Polarized,
                      observed: false,
                      stakeEndTime: 0
                  });
                 _safeMint(msg.sender, newTokenId);
                 generatedIds[i] = newTokenId;
             }
            emit EntanglementDisentangled(msg.sender, entanglementTokenId, generatedIds);

        } else {
             // On failure, no Quanta are recovered.
             emit EntanglementDisentangled(msg.sender, entanglementTokenId, new uint256[](0)); // Empty array on failure
        }
    }


    /**
     * @dev Stakes an owned Quanta token. Makes it immune to decoherence and potentially boosts energy over time.
     * @param quantaTokenId The token ID of the Quanta to stake.
     */
    function stakeQuanta(uint256 quantaTokenId) external onlyQuanta(quantaTokenId) whenNotPaused {
        if (ownerOf(quantaTokenId) != msg.sender) revert NotOwnerOfToken(quantaTokenId);
        QuantaProperties storage quanta = _quantaData[quantaTokenId];

        if (quanta.stakeEndTime > block.timestamp) revert QuantaIsStaked(quantaTokenId);
        if (quanta.observed) revert QuantaIsObserved(quantaTokenId);

        // Stake for a fixed duration (e.g., 30 days)
        uint64 stakeDuration = 30 days; // Example duration
        quanta.stakeEndTime = uint64(block.timestamp + stakeDuration);

        emit QuantaStaked(msg.sender, quantaTokenId, quanta.stakeEndTime);
    }

    /**
     * @dev Unstakes a previously staked Quanta token.
     * @param quantaTokenId The token ID of the Quanta to unstake.
     */
    function unstakeQuanta(uint256 quantaTokenId) external onlyQuanta(quantaTokenId) whenNotPaused {
        if (ownerOf(quantaTokenId) != msg.sender) revert NotOwnerOfToken(quantaTokenId);
        QuantaProperties storage quanta = _quantaData[quantaTokenId];

        if (quanta.stakeEndTime == 0 || quanta.stakeEndTime > block.timestamp) revert QuantaIsNotStaked(quantaTokenId); // Not staked or still staked

        quanta.stakeEndTime = 0;

        // Could add energy boost based on staked duration here
        // uint256 stakedTime = block.timestamp - (quanta.stakeEndTime - stakeDuration); // Careful with this calc

        emit QuantaUnstaked(msg.sender, quantaTokenId);
    }

     /**
     * @dev "Observes" an owned Quanta token, fixing its state, energy, and spin permanently.
     * Prevents staking, decoherence, or further state/energy changes.
     * @param quantaTokenId The token ID of the Quanta to observe.
     */
    function observeQuanta(uint256 quantaTokenId) external onlyQuanta(quantaTokenId) whenNotPaused {
        if (ownerOf(quantaTokenId) != msg.sender) revert NotOwnerOfToken(quantaTokenId);
        QuantaProperties storage quanta = _quantaData[quantaTokenId];

        if (quanta.observed) revert QuantaIsObserved(quantaTokenId);
        if (quanta.stakeEndTime > block.timestamp) revert QuantaIsStaked(quantaTokenId);

        quanta.observed = true;

        emit QuantaObserved(msg.sender, quantaTokenId);
    }

    /**
     * @dev Attempts to apply simulated decoherence to a *single* unstaked, unobserved Quanta token.
     * State might change based on probability/parameters. Can be called by permissioned users.
     * Includes a minimal gas reward (send 1 wei) to incentivize calls (highly experimental pattern).
     * @param quantaTokenId The token ID of the Quanta to apply decoherence to.
     */
    function applyDecoherenceToQuanta(uint256 quantaTokenId) external payable onlyQuanta(quantaTokenId) onlyDecoherencePermissioned whenNotPaused {
         // Ensure the token exists and is Quanta
         if (!_exists(quantaTokenId)) revert TokenDoesNotExist(quantaTokenId);
         QuantaProperties storage quanta = _quantaData[quantaTokenId];

         // Decoherence only affects unstaked and unobserved Quanta
         if (quanta.stakeEndTime > block.timestamp || quanta.observed) {
             revert DecoherenceConditionsNotMet(quantaTokenId);
         }

         // Simulate probabilistic state change
         // WARNING: block.timestamp/number are not secure random. Use VRF in production.
         uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, quantaTokenId))) % 10000;

         if (randomNumber < _decoherenceProbability) {
             // Apply state change
             QuantaState oldState = quanta.state;
             // Change state by up to _decoherenceMaxStateChange steps downwards
             uint8 currentStateIndex = uint8(oldState);
             uint8 newStateIndex = currentStateIndex + uint8(randomNumber % (_decoherenceMaxStateChange + 1)); // Random steps up to max
             if (newStateIndex >= uint8(QuantaState.Decayed)) {
                 quanta.state = QuantaState.Decayed;
             } else {
                  // Ensure index doesn't exceed enum bounds - using 4 states (0-3)
                 quanta.state = QuantaState(Math.min(uint8(oldState) + uint8(randomNumber % (_decoherenceMaxStateChange + 1)), uint8(QuantaState.Decayed)));
             }


             // Could also affect energy or spin
             uint16 oldEnergy = quanta.energy;
             quanta.energy = quanta.energy > 10 ? uint16(quanta.energy - 10) : 0; // Example energy decay

             emit QuantaStateChanged(quantaTokenId, oldState, quanta.state, "Decoherence");
             emit QuantaEnergyChanged(quantaTokenId, oldEnergy, quanta.energy, "Decoherence");
             emit DecoherenceApplied(quantaTokenId, quanta.state, "State changed due to decoherence");
         }

         // Optional: Reward caller with a tiny amount of ETH for running decoherence
         // This pattern is experimental and needs careful gas analysis.
         // (bool success, ) = msg.sender.call{value: 1 wei}("");
         // require(success, "Reward transfer failed"); // Consider if failure should revert the state change

    }


    /**
     * @dev Increases the energy of an owned, unobserved Quanta token. Requires payment.
     * @param quantaTokenId The token ID of the Quanta.
     */
    function increaseQuantaEnergy(uint256 quantaTokenId) external payable onlyQuanta(quantaTokenId) whenNotPaused {
        if (ownerOf(quantaTokenId) != msg.sender) revert NotOwnerOfToken(quantaTokenId);
        QuantaProperties storage quanta = _quantaData[quantaTokenId];

        if (quanta.observed) revert QuantaIsObserved(quantaTokenId);
        // Could require a minimum payment or scale energy increase with payment
        uint16 energyBoost = uint16(msg.value.div(1 ether).mul(50)); // Example: 1 ETH = 50 energy
        require(energyBoost > 0, "Minimum payment required for energy increase");

        uint16 oldEnergy = quanta.energy;
        quanta.energy = quanta.energy.add(energyBoost) > 1000 ? 1000 : uint16(quanta.energy.add(energyBoost)); // Cap energy at 1000

        emit QuantaEnergyChanged(quantaTokenId, oldEnergy, quanta.energy, "Manual Increase");
    }

    /**
     * @dev Transfers the state property from one owned Quanta to another. Costs energy from the source.
     * Both Quanta must be unstaked and unobserved.
     * @param fromTokenId The token ID of the source Quanta.
     * @param toTokenId The token ID of the destination Quanta.
     */
    function transferQuantaState(uint256 fromTokenId, uint256 toTokenId) external onlyQuanta(fromTokenId) onlyQuanta(toTokenId) whenNotPaused {
        if (fromTokenId == toTokenId) revert CannotTransferStateToSelf();
        address owner = msg.sender;
        if (ownerOf(fromTokenId) != owner) revert NotOwnerOfToken(fromTokenId);
        if (ownerOf(toTokenId) != owner) revert NotOwnerOfToken(toTokenId);

        QuantaProperties storage fromQuanta = _quantaData[fromTokenId];
        QuantaProperties storage toQuanta = _quantaData[toTokenId];

        if (fromQuanta.observed || fromQuanta.stakeEndTime > block.timestamp) revert QuantaIsObserved(fromTokenId); // Source cannot be observed/staked
        if (toQuanta.observed || toQuanta.stakeEndTime > block.timestamp) revert QuantaIsObserved(toTokenId); // Destination cannot be observed/staked

        uint16 energyCost = 50; // Example energy cost for transfer
        if (fromQuanta.energy < energyCost) revert QuantaEnergyTooLow(fromTokenId, fromQuanta.energy, energyCost);

        // Perform the state transfer
        QuantaState transferredState = fromQuanta.state;
        QuantaState oldToState = toQuanta.state;
        QuantaState oldFromState = fromQuanta.state;

        toQuanta.state = transferredState;
        // Optionally reset source state or set to Decayed
        fromQuanta.state = QuantaState.Decayed; // Source state "collapses"

        // Deduct energy from source
        uint16 oldFromEnergy = fromQuanta.energy;
        fromQuanta.energy = fromQuanta.energy.sub(energyCost);

        emit QuantaStateTransferred(owner, fromTokenId, toTokenId, transferredState);
        emit QuantaStateChanged(fromTokenId, oldFromState, fromQuanta.state, "State Transfer Source");
        emit QuantaStateChanged(toTokenId, oldToState, toQuanta.state, "State Transfer Destination");
        emit QuantaEnergyChanged(fromTokenId, oldFromEnergy, fromQuanta.energy, "State Transfer Cost");
    }

    // --- Batch Operations ---

    /**
     * @dev Generates multiple Quanta tokens in a single transaction. Requires payment.
     * @param quantaTypes Array of type identifiers for the Quanta to generate.
     */
    function batchGenerateQuanta(uint8[] calldata quantaTypes) external payable whenNotPaused {
        require(quantaTypes.length > 0 && quantaTypes.length <= 20, "Invalid batch size"); // Limit batch size
        uint256 totalCost = 0;
        for(uint i = 0; i < quantaTypes.length; i++) {
            totalCost = totalCost.add(_quantaGenerationCosts[quantaTypes[i]]);
        }
        if (msg.value < totalCost) {
             revert InsufficientPayment(totalCost, msg.value);
        }

        for(uint i = 0; i < quantaTypes.length; i++) {
            uint8 quantaType = quantaTypes[i];
            uint256 newTokenId = _nextTokenId.current();
            _nextTokenId.increment();

            _quantaData[newTokenId] = QuantaProperties({
                quantaType: quantaType,
                state: QuantaState.Stable, // Initial state
                energy: 100, // Initial energy
                spin: QuantaSpin.Up, // Initial spin
                observed: false,
                stakeEndTime: 0
            });

            _safeMint(msg.sender, newTokenId);
            emit QuantaGenerated(msg.sender, newTokenId, quantaType, QuantaState.Stable, 100, QuantaSpin.Up);
        }
    }

    /**
     * @dev Stakes multiple owned Quanta tokens.
     * @param quantaTokenIds Array of token IDs of the Quanta to stake.
     */
     function batchStakeQuanta(uint256[] calldata quantaTokenIds) external whenNotPaused {
         require(quantaTokenIds.length > 0 && quantaTokenIds.length <= 50, "Invalid batch size"); // Limit batch size
         address owner = msg.sender;
         uint64 stakeDuration = 30 days; // Example duration

         for(uint i = 0; i < quantaTokenIds.length; i++) {
             uint256 tokenId = quantaTokenIds[i];
             if (!_exists(tokenId)) continue; // Skip non-existent tokens in batch
             if (ownerOf(tokenId) != owner) continue; // Skip tokens not owned by sender
             if (isEntanglement(tokenId)) continue; // Skip Entanglements

             QuantaProperties storage quanta = _quantaData[tokenId];
             if (quanta.stakeEndTime > block.timestamp) continue; // Skip already staked
             if (quanta.observed) continue; // Skip observed

             quanta.stakeEndTime = uint64(block.timestamp + stakeDuration);
             emit QuantaStaked(owner, tokenId, quanta.stakeEndTime);
         }
     }

     /**
     * @dev Unstakes multiple previously staked Quanta tokens.
     * @param quantaTokenIds Array of token IDs of the Quanta to unstake.
     */
     function batchUnstakeQuanta(uint256[] calldata quantaTokenIds) external whenNotPaused {
        require(quantaTokenIds.length > 0 && quantaTokenIds.length <= 50, "Invalid batch size"); // Limit batch size
         address owner = msg.sender;

         for(uint i = 0; i < quantaTokenIds.length; i++) {
             uint256 tokenId = quantaTokenIds[i];
             if (!_exists(tokenId)) continue; // Skip non-existent tokens
             if (ownerOf(tokenId) != owner) continue; // Skip tokens not owned by sender
             if (isEntanglement(tokenId)) continue; // Skip Entanglements

             QuantaProperties storage quanta = _quantaData[tokenId];
             if (quanta.stakeEndTime == 0 || quanta.stakeEndTime > block.timestamp) continue; // Skip not staked or still staked

             quanta.stakeEndTime = 0;
             emit QuantaUnstaked(owner, tokenId);
         }
     }

     /**
     * @dev Observes multiple owned Quanta tokens, fixing their state.
     * @param quantaTokenIds Array of token IDs of the Quanta to observe.
     */
     function batchObserveQuanta(uint256[] calldata quantaTokenIds) external whenNotPaused {
         require(quantaTokenIds.length > 0 && quantaTokenIds.length <= 50, "Invalid batch size"); // Limit batch size
         address owner = msg.sender;

         for(uint i = 0; i < quantaTokenIds.length; i++) {
             uint256 tokenId = quantaTokenIds[i];
             if (!_exists(tokenId)) continue; // Skip non-existent tokens
             if (ownerOf(tokenId) != owner) continue; // Skip tokens not owned by sender
             if (isEntanglement(tokenId)) continue; // Skip Entanglements

             QuantaProperties storage quanta = _quantaData[tokenId];
             if (quanta.observed) continue; // Skip already observed
             if (quanta.stakeEndTime > block.timestamp) continue; // Skip staked

             quanta.observed = true;
             emit QuantaObserved(owner, tokenId);
         }
     }

    /**
     * @dev Increases energy for multiple owned, unobserved Quanta tokens. Requires payment.
     * Payment is distributed equally among tokens (or capped).
     * @param quantaTokenIds Array of token IDs of the Quanta.
     */
     function batchIncreaseQuantaEnergy(uint256[] calldata quantaTokenIds) external payable whenNotPaused {
        require(quantaTokenIds.length > 0 && quantaTokenIds.length <= 50, "Invalid batch size"); // Limit batch size
        address owner = msg.sender;
        uint256 totalValue = msg.value;
        uint256 tokensEligible = 0;
        for(uint i = 0; i < quantaTokenIds.length; i++) {
            uint256 tokenId = quantaTokenIds[i];
            if (_exists(tokenId) && ownerOf(tokenId) == owner && !isEntanglement(tokenId) && !_quantaData[tokenId].observed) {
                tokensEligible++;
            }
        }
        if (tokensEligible == 0) {
             if(totalValue > 0) { // Refund if paid but no eligible tokens
                 (bool success, ) = owner.call{value: totalValue}("");
                 require(success, "Refund failed");
             }
             return; // No eligible tokens to process
        }

        uint256 valuePerToken = totalValue.div(tokensEligible);
        uint16 energyBoostPerToken = uint16(valuePerToken.div(1 ether).mul(50)); // Example: 1 ETH = 50 energy per token

        require(energyBoostPerToken > 0, "Minimum payment required for energy increase");

        uint256 remainingValue = totalValue;

        for(uint i = 0; i < quantaTokenIds.length; i++) {
             uint256 tokenId = quantaTokenIds[i];
             if (_exists(tokenId) && ownerOf(tokenId) == owner && !isEntanglement(tokenId) && !_quantaData[tokenId].observed) {
                QuantaProperties storage quanta = _quantaData[tokenId];
                uint16 oldEnergy = quanta.energy;
                 // Use Math.min to handle potential rounding or uneven distribution from valuePerToken
                uint16 actualBoost = Math.min(energyBoostPerToken, uint16((remainingValue > valuePerToken ? valuePerToken : remainingValue).div(1 ether).mul(50)));
                if (actualBoost == 0 && remainingValue > 0) actualBoost = 1; // Ensure minimal boost if value > 0 but less than 1 ether/50
                if (actualBoost == 0) continue; // Skip if no boost possible

                quanta.energy = quanta.energy.add(actualBoost) > 1000 ? 1000 : uint16(quanta.energy.add(actualBoost)); // Cap energy at 1000
                remainingValue = remainingValue.sub(valuePerToken); // Account for distributed value

                emit QuantaEnergyChanged(tokenId, oldEnergy, quanta.energy, "Batch Increase");
            }
         }

         // Return any leftover ETH due to division/rounding
         if (remainingValue > 0) {
              (bool success, ) = owner.call{value: remainingValue}("");
              require(success, "Refund leftover failed");
         }
     }

    // --- ERC721 Overrides and Helpers ---

    // Internal helper to check if a token ID represents an Entanglement
    function isEntanglement(uint256 tokenId) public view returns (bool) {
        return tokenId >= QUANTA_ID_THRESHOLD;
    }

     // Internal helper to check if a token ID exists
    function _exists(uint256 tokenId) internal view override returns (bool) {
        if (isEntanglement(tokenId)) {
            // Check if Entanglement data exists (implies token exists)
             // This relies on _entanglementData entries only existing for minted Entanglements
            return _entanglementData[tokenId].entanglementType != 0; // Assuming type 0 is invalid
        } else {
            // Check if Quanta data exists (implies token exists)
            // This relies on _quantaData entries only existing for minted Quanta
            return _quantaData[tokenId].quantaType != 0; // Assuming type 0 is invalid
        }
         // Note: A more robust system might track token existence in a separate map or rely purely on ERC721 internal state.
         // For this design, checking the data mappings acts as the existence check.
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}. Generates URI based on token type and properties.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        string memory base = _baseURI;
        string memory prefix = "";
        string memory tokenDataJson; // Simplified placeholder JSON

        if (isEntanglement(tokenId)) {
             prefix = _entanglementPrefix;
             EntanglementProperties memory entanglement = _entanglementData[tokenId];
             // Example Entanglement JSON structure
             tokenDataJson = string(abi.encodePacked(
                 '{"name": "Entanglement #',
                 Strings.toString(tokenId),
                 '", "description": "A fused quantum entanglement.", "attributes": [{"trait_type": "Entanglement Type", "value": ',
                 Strings.toString(entanglement.entanglementType),
                 '}]}'
             ));
        } else {
             QuantaProperties memory quanta = _quantaData[tokenId];
             // Example Quanta JSON structure
             tokenDataJson = string(abi.encodePacked(
                 '{"name": "Quanta #',
                 Strings.toString(tokenId),
                 '", "description": "A base quantum particle.", "attributes": [',
                 '{"trait_type": "Quanta Type", "value": ', Strings.toString(quanta.quantaType), '},',
                 '{"trait_type": "State", "value": "', _stateToString(quanta.state), '"},',
                 '{"trait_type": "Energy", "value": ', Strings.toString(quanta.energy), '},',
                 '{"trait_type": "Spin", "value": "', _spinToString(quanta.spin), '"},',
                 '{"trait_type": "Observed", "value": ', (quanta.observed ? "true" : "false"), '},',
                 '{"trait_type": "Staked", "value": ', (quanta.stakeEndTime > block.timestamp ? "true" : "false"), '}',
                 ']}'
             ));
        }

        // Simple base64 encoding (requires link to Bytes library if not using OpenZeppelin's internal one)
        // For this example, let's just return the path + JSON, assuming the base URI handles it.
        // A common pattern is `data:application/json;base64,...` or just returning the path.
        // Let's return a path like baseURI/prefix/tokenId.json

        return string(abi.encodePacked(base, prefix, Strings.toString(tokenId), ".json"));
         // Or for data URI (requires more helper code):
         // string memory jsonURI = string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(tokenDataJson))));
         // return jsonURI; // Uncomment if Base64 is available
    }

     // Helper functions for tokenURI (Enums to String)
    function _stateToString(QuantaState state) internal pure returns (string memory) {
        if (state == QuantaState.Stable) return "Stable";
        if (state == QuantaState.Excited) return "Excited";
        if (state == QuantaState.Superposition) return "Superposition";
        if (state == QuantaState.Decayed) return "Decayed";
        return "Unknown";
    }

    function _spinToString(QuantaSpin spin) internal pure returns (string memory) {
        if (spin == QuantaSpin.Up) return "Up";
        if (spin == QuantaSpin.Down) return "Down";
        if (spin == QuantaSpin.Polarized) return "Polarized";
        return "Unknown";
    }


    // --- Query Functions ---

    /**
     * @dev Returns the properties of a Quanta token.
     * @param tokenId The token ID.
     */
    function getQuantaProperties(uint256 tokenId) public view onlyQuanta(tokenId) returns (QuantaProperties memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _quantaData[tokenId];
    }

     /**
     * @dev Returns the properties of an Entanglement token.
     * @param tokenId The token ID.
     */
    function getEntanglementProperties(uint256 tokenId) public view onlyEntanglement(tokenId) returns (EntanglementProperties memory) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _entanglementData[tokenId];
    }


    /**
     * @dev Returns the current state of a Quanta token.
     * @param tokenId The token ID.
     */
    function getQuantaState(uint256 tokenId) public view onlyQuanta(tokenId) returns (QuantaState) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _quantaData[tokenId].state;
    }

    /**
     * @dev Returns the current energy of a Quanta token.
     * @param tokenId The token ID.
     */
    function getQuantaEnergy(uint256 tokenId) public view onlyQuanta(tokenId) returns (uint16) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _quantaData[tokenId].energy;
    }

    /**
     * @dev Returns the current spin of a Quanta token.
     * @param tokenId The token ID.
     */
    function getQuantaSpin(uint256 tokenId) public view onlyQuanta(tokenId) returns (QuantaSpin) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _quantaData[tokenId].spin;
    }

    /**
     * @dev Returns whether a Quanta token has been observed.
     * @param tokenId The token ID.
     */
    function isQuantaObserved(uint256 tokenId) public view onlyQuanta(tokenId) returns (bool) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _quantaData[tokenId].observed;
    }

     /**
     * @dev Returns the stake end time of a Quanta token (0 if not staked).
     * @param tokenId The token ID.
     */
    function getQuantaStakeEndTime(uint256 tokenId) public view onlyQuanta(tokenId) returns (uint64) {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _quantaData[tokenId].stakeEndTime;
    }


     /**
     * @dev Returns the details of a fusion recipe.
     * @param inputQuantaTypes Array of required Quanta types (must be sorted ascending) identifying the recipe.
     */
    function getFusionRecipe(uint8[] calldata inputQuantaTypes) public view returns (FusionRecipe memory) {
         require(inputQuantaTypes.length > 0, "Input types cannot be empty");
         // Need to sort locally to generate the correct hash key
         uint8[] memory sortedTypes = new uint8[](inputQuantaTypes.length);
         for(uint i=0; i < inputQuantaTypes.length; i++) sortedTypes[i] = inputQuantaTypes[i];

         for (uint i = 0; i < sortedTypes.length; i++) {
            for (uint j = i + 1; j < sortedTypes.length; j++) {
                if (sortedTypes[i] > sortedTypes[j]) {
                    uint8 temp = sortedTypes[i];
                    sortedTypes[i] = sortedTypes[j];
                    sortedTypes[j] = temp;
                }
            }
        }
         bytes32 recipeHash = keccak256(abi.encodePacked(sortedTypes));
         return _fusionRecipes[recipeHash]; // Returns empty struct if not found
    }

     /**
     * @dev Returns the current decoherence parameters.
     */
    function getDecoherenceParameters() public view returns (uint16 probability, uint8 maxStateChange) {
        return (_decoherenceProbability, _decoherenceMaxStateChange);
    }

}

// Simple Math library if needed (can also rely on OpenZeppelin or native)
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
     function min(uint8 a, uint8 b) internal pure returns (uint8) {
        return a < b ? a : b;
    }
     function min(uint16 a, uint16 b) internal pure returns (uint16) {
        return a < b ? a : b;
    }
}

// OpenZeppelin Strings and Base64 are often linked via inheriting a base contract that imports them,
// or by manually including their code if not using hardhat/foundry imports that handle linking.
// For this example, assuming standard setup allows access to Bytes and Strings.
// If using Base64.encode, you'd need:
// import "@openzeppelin/contracts/utils/Base64.sol";
// And update tokenURI function accordingly.
// import "@openzeppelin/contracts/utils/Strings.sol"; // Already imported by ERC721Metadata
```