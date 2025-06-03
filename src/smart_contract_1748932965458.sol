Okay, here is a Solidity smart contract (`QuantumFluxForge`) designed with advanced, interconnected concepts around dynamic state, algorithmic NFT generation, and asset interaction, aiming for uniqueness and creativity beyond typical open-source patterns.

It features:

1.  **Crucibles (NFTs):** ERC721 tokens representing individual crafting/synthesis stations owned by users.
2.  **Synthesis:** A multi-step, time-locked process within Crucibles that consumes tokens and potentially generates Quantum Fragment NFTs.
3.  **Quantum Fragments (NFTs):** ERC721 tokens with procedurally generated properties based on synthesis inputs, contract state, and pseudo-randomness.
4.  **Dynamic Global State:** Two key parameters (`fluxEquilibrium` and `entropyLevel`) that drift over time and are influenced by user actions, impacting synthesis outcomes globally.
5.  **Asset Utility:** Fragments and other assets can be used in subsequent operations (combining fragments, influencing global state).
6.  **Algorithmic Generation:** Fragment properties are determined by on-chain logic, not external metadata JSON files.

---

### QuantumFluxForge Contract Outline & Function Summary

**Contract Name:** `QuantumFluxForge`

**Core Concepts:**
*   ERC-20 based ingredients (`FLUX`, `CATALYST_A`, `CATALYST_B`).
*   ERC-721 Crucible NFTs for synthesis.
*   ERC-721 Quantum Fragment NFTs with algorithmic properties.
*   Time-locked synthesis process.
*   Dynamic global contract state (`fluxEquilibrium`, `entropyLevel`) influenced by actions.
*   Fragment utility beyond collection (combination, state influence).

**Function Categories:**

1.  **Admin & Setup:** (Functions 1-4)
    *   Initialize contract, set token addresses, parameters, withdraw fees.
2.  **Crucible Management:** (Functions 5-12)
    *   Create, deposit into, withdraw from, get state/status/ingredients of, upgrade Crucibles.
3.  **Synthesis Process:** (Functions 13-18)
    *   Initiate, finalize, cancel synthesis; estimate outcome; get progress/completion time.
4.  **Quantum Fragment Interaction:** (Functions 19-22)
    *   Get properties of Fragments; combine, dissolve Fragments; use Fragments to catalyze global state.
5.  **Global State Interaction & Info:** (Functions 23-26)
    *   Get current global state values; perform rituals or trigger events to influence global state.
6.  **View & Utility:** (Functions 27-31)
    *   Get total supply of assets; get required synthesis ingredients; get synthesis recipe details.

**Function Summary (20+ functions):**

1.  `constructor`: Initializes contract, deploys/sets token addresses, sets initial parameters.
2.  `setCatalystAddresses`: Admin sets the addresses of catalyst ERC20 tokens.
3.  `setSynthesisParameters`: Admin adjusts synthesis costs, durations, success probabilities modifiers.
4.  `withdrawAdminFees`: Admin withdraws accumulated fees (e.g., from crucible creation) in various tokens.
5.  `createCrucible`: Allows a user to mint a new Crucible NFT (may require `FLUX` payment).
6.  `depositToCrucible`: Transfers specified ERC20 tokens (`FLUX` or Catalysts) from user to a Crucible's balance within the contract. Requires Crucible ownership.
7.  `withdrawFromCrucible`: Transfers specified ERC20 tokens from a Crucible's balance back to the owner. Requires Crucible ownership and Crucible not synthesizing.
8.  `getCrucibleIngredients`: Views the current balance of `FLUX` and Catalysts held within a specific Crucible.
9.  `getCrucibleStatus`: Views the current state of a Crucible (Idle, Synthesizing, Cooldown).
10. `getCrucibleSynthesisProgress`: Views the completion timestamp and time remaining for synthesis in a Crucible.
11. `upgradeCrucible`: Allows a user to upgrade a Crucible (improving its synthesis potential, potentially requiring inputs like `FLUX` or Fragments). Increases Crucible level/stats.
12. `getCrucibleData`: Gets all key data about a specific Crucible (owner, level, status, ingredients, synthesis details).
13. `initiateSynthesis`: Starts the synthesis process in an owned, idle Crucible. Requires specific ingredient amounts and user-provided parameters. Locks Crucible and starts timer.
14. `finalizeSynthesis`: Completes a synthesis process after the required time has passed. Calculates outcome based on inputs, state, parameters, and pseudo-randomness. Consumes ingredients, potentially mints Fragment NFT, updates Crucible state (e.g., cooldown).
15. `cancelSynthesis`: Allows cancellation of an active synthesis before completion. May penalize the user (e.g., partial loss of ingredients).
16. `estimateSynthesisOutcome`: A view function to estimate the *likely* outcome of synthesis given inputs and current state (cannot use future block data for true prediction).
17. `getFragmentProperties`: Views the unique, algorithmically generated properties of a specific Quantum Fragment NFT.
18. `combineFragments`: Allows burning multiple Quantum Fragment NFTs to attempt minting a new, potentially rarer/more powerful Fragment based on the properties of the combined inputs.
19. `dissolveFragment`: Allows burning a Quantum Fragment to recover a small amount of `FLUX` or influence the global state slightly.
20. `catalyzeGlobalState`: Allows burning specific Fragments (or using their properties) to attempt a direct, but possibly temporary, shift in the global `fluxEquilibrium` or `entropyLevel`.
21. `getCurrentFluxEquilibrium`: Views the current global `fluxEquilibrium` value.
22. `getCurrentEntropyLevel`: Views the current global `entropyLevel` value.
23. `performStabilizationRitual`: A function requiring specific conditions/inputs to attempt to move `fluxEquilibrium` closer to a target value.
24. `triggerFluxCascade`: A high-risk, high-reward function requiring rare inputs to cause a significant, potentially chaotic shift in both `fluxEquilibrium` and `entropyLevel`.
25. `getTotalCrucibles`: Views the total number of Crucible NFTs minted.
26. `getTotalFragments`: Views the total number of Quantum Fragment NFTs minted.
27. `getRequiredSynthesisIngredients`: Views the base required ingredients and costs for initiating synthesis at a given Crucible level.
28. `getSynthesisRecipeDetails`: Views the specific parameters and state variables used in a completed synthesis for a given Crucible or Fragment ID.
29. `getLastGlobalStateUpdate`: Views the timestamp of the last significant update to the global `fluxEquilibrium` or `entropyLevel`.
30. `getEstimatedNextGlobalState`: Estimates the natural drift of global state based on time elapsed since the last update.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Standard Libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// Custom Error Definitions (Solidity 0.8.4+)
error QuantumFluxForge__NotCrucibleOwner(address owner, uint256 crucibleId);
error QuantumFluxForge__CrucibleNotIdle(uint256 crucibleId);
error QuantumFluxForge__CrucibleNotSynthesizing(uint256 crucibleId);
error QuantumFluxForge__SynthesisNotComplete(uint256 crucibleId);
error QuantumFluxForge__SynthesisAlreadyComplete(uint256 crucibleId);
error QuantumFluxForge__InsufficientCrucibleIngredients(uint256 crucibleId, address tokenAddress, uint256 required, uint256 available);
error QuantumFluxForge__InsufficientUserTokens(address tokenAddress, uint256 required, uint256 available);
error QuantumFluxForge__InvalidCatalystAddress(address tokenAddress);
error QuantumFluxForge__NotEnoughFragmentsToCombine(uint256 provided, uint256 required);
error QuantumFluxForge__FragmentPropertiesMismatch();
error QuantumFluxForge__InvalidCrucibleLevel(uint256 crucibleId, uint256 requiredLevel);
error QuantumFluxForge__SynthesisCancellationFailed();
error QuantumFluxForge__CannotWithdrawSynthesizingIngredients();
error QuantumFluxForge__GlobalStateCannotBeCatalyzedYet();
error QuantumFluxForge__StabilizationRitualFailed();
error QuantumFluxForge__FluxCascadeFailed();

contract QuantumFluxForge is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- State Variables ---

    // Admin & Tokens
    address public fluxToken; // Primary ERC20 token
    address public catalystA; // Secondary ERC20 token 1
    address public catalystB; // Secondary ERC20 token 2
    address[] private catalystAddresses; // Array of catalyst addresses for easy iteration

    // Counters
    Counters.Counter private _crucibleIds;
    Counters.Counter private _fragmentIds;

    // Crucible Data (ERC721 token for Crucibles)
    struct Crucible {
        uint256 level; // Affects synthesis potential, ingredient capacity, cooldowns
        mapping(address => uint256) ingredients; // ERC20 tokens held in this crucible
        CrucibleStatus status; // Current state: Idle, Synthesizing, Cooldown
        uint64 synthesisStartTime; // Timestamp when synthesis began
        uint64 synthesisCompletionTime; // Timestamp when synthesis is expected to complete
        bytes32 synthesisRecipeHash; // Hash of parameters used in the synthesis
        // Note: Owner and token URI handled by ERC721 base
    }
    mapping(uint256 => Crucible) private _crucibles;

    enum CrucibleStatus { Idle, Synthesizing, Cooldown }

    // Quantum Fragment Data (ERC721 token for Fragments)
    struct QuantumFragment {
        uint256 creationBlock; // Block number when created (for randomness/provenance)
        address creator; // Address that initiated the synthesis
        uint256 createdInCrucibleId; // The Crucible used for creation
        uint256 resonance; // A core, algorithmically generated property
        uint256 stability; // Another core property
        uint256 rarityScore; // Calculated score based on properties
        bytes32 creationSeed; // The seed/hash used for generating properties
        // Note: More dynamic properties could be added here
        // Note: Owner and token URI handled by ERC721 base
    }
    mapping(uint256 => QuantumFragment) private _fragments;

    // Global Contract State
    int256 public fluxEquilibrium; // Global balance influencing synthesis outcomes (e.g., -1000 to 1000)
    uint256 public entropyLevel; // Global chaos level influencing synthesis variance (e.g., 0 to 100)
    uint64 public lastGlobalStateUpdate; // Timestamp of the last update to equilibrium/entropy

    // Synthesis Parameters (Adjustable by Admin)
    uint256 public crucibleCreationCostFlux;
    mapping(uint256 => SynthesisParameters) public synthesisParamsByCrucibleLevel; // Base params per level

    struct SynthesisParameters {
        uint256 durationSeconds;
        uint256 baseFluxCost;
        uint256 baseCatalystACost;
        uint256 baseCatalystBCost;
        uint256 baseSuccessChancePercent; // e.g., 70 for 70%
        int256 equilibriumInfluencePerSynthesize; // How much synthesis shifts equilibrium
        uint256 entropyIncreasePerSynthesize; // How much synthesis increases entropy
    }

    // Admin Fees
    mapping(address => uint256) private adminFees; // Fees accumulated per token

    // --- Events ---

    event CrucibleCreated(uint256 indexed crucibleId, address indexed owner, uint256 level);
    event CrucibleIngredientsDeposited(uint256 indexed crucibleId, address indexed tokenAddress, uint256 amount);
    event CrucibleIngredientsWithdrawn(uint256 indexed crucibleId, address indexed tokenAddress, uint256 amount);
    event CrucibleUpgraded(uint256 indexed crucibleId, uint256 newLevel);
    event SynthesisInitiated(uint256 indexed crucibleId, address indexed owner, bytes32 recipeHash, uint64 completionTime);
    event SynthesisFinalized(uint256 indexed crucibleId, address indexed owner, bool success, uint256 indexed fragmentId);
    event SynthesisCancelled(uint256 indexed crucibleId, address indexed owner, uint256 penaltyAmount);
    event QuantumFragmentMinted(uint256 indexed fragmentId, address indexed owner, uint256 indexed createdInCrucibleId, uint256 rarityScore);
    event QuantumFragmentCombined(uint256[] indexed burnedFragmentIds, uint256 indexed newFragmentId, address indexed owner);
    event QuantumFragmentDissolved(uint256 indexed fragmentId, address indexed owner, uint256 recoveredFlux);
    event GlobalStateEquilibriumUpdated(int256 newEquilibrium, int256 delta);
    event GlobalStateEntropyUpdated(uint256 newEntropy, int256 delta);
    event StabilizationRitualPerformed(int256 equilibriumShift);
    event FluxCascadeTriggered(int256 equilibriumShift, int256 entropyShift);

    // --- Modifiers ---

    modifier onlyCrucibleOwner(uint256 _crucibleId) {
        if (ownerOf(_crucibleId) != msg.sender) {
            revert QuantumFluxForge__NotCrucibleOwner(ownerOf(_crucibleId), _crucibleId);
        }
        _;
    }

    modifier whenCrucibleIdle(uint256 _crucibleId) {
        if (_crucibles[_crucibleId].status != CrucibleStatus.Idle) {
            revert QuantumFluxForge__CrucibleNotIdle(_crucibleId);
        }
        _;
    }

    modifier whenCrucibleSynthesizing(uint256 _crucibleId) {
        if (_crucibles[_crucibleId].status != CrucibleStatus.Synthesizing) {
            revert QuantumFluxForge__CrucibleNotSynthesizing(_crucibleId);
        }
        _;
    }

    modifier whenSynthesisComplete(uint256 _crucibleId) {
        if (_crucibles[_crucibleId].status != CrucibleStatus.Synthesizing) {
            revert QuantumFluxForge__CrucibleNotSynthesizing(_crucibleId);
        }
        if (block.timestamp < _crucibles[_crucibleId].synthesisCompletionTime) {
            revert QuantumFluxForge__SynthesisNotComplete(_crucibleId);
        }
        _;
    }

    modifier whenCrucibleReadyForAction(uint256 _crucibleId) {
         if (_crucibles[_crucibleId].status == CrucibleStatus.Synthesizing) {
            revert QuantumFluxForge__CrucibleNotSynthesizing(_crucibleId);
        }
        // Optional: Add check for Cooldown if actions blocked during cooldown
         if (_crucibles[_crucibleId].status == CrucibleStatus.Cooldown && block.timestamp < _crucibles[_crucibleId].synthesisCompletionTime) {
             revert QuantumFluxForge__CrucibleNotIdle(_crucibleId); // Re-use error or create specific
         }
        _;
    }


    // --- Constructor ---

    constructor(address _fluxToken, string memory _crucibleName, string memory _crucibleSymbol, string memory _fragmentName, string memory _fragmentSymbol)
        ERC721(_crucibleName, _crucibleSymbol) // Use base ERC721 for Crucibles
        Ownable(msg.sender)
    {
        fluxToken = _fluxToken;
        // Initial dummy addresses for catalysts, must be set via setCatalystAddresses
        catalystAddresses = new address[](2);
        catalystAddresses[0] = address(0); // Placeholder for Catalyst A
        catalystAddresses[1] = address(0); // Placeholder for Catalyst B

        // Set initial global state
        fluxEquilibrium = 0; // Start at neutral
        entropyLevel = 50; // Start at moderate
        lastGlobalStateUpdate = uint64(block.timestamp);

        // Set default initial synthesis parameters for level 1
        synthesisParamsByCrucibleLevel[1] = SynthesisParameters({
            durationSeconds: 1 hours,
            baseFluxCost: 100 ether, // Example: 100 tokens
            baseCatalystACost: 10 ether, // Example: 10 tokens
            baseCatalystBCost: 5 ether, // Example: 5 tokens
            baseSuccessChancePercent: 70,
            equilibriumInfluencePerSynthesize: -5, // Each synthesis slightly reduces equilibrium
            entropyIncreasePerSynthesize: 2 // Each synthesis slightly increases entropy
        });

        crucibleCreationCostFlux = 50 ether; // Example cost to create a crucible

         // Note: Fragment ERC721 is managed internally, not inherited directly
        // A separate ERC721 contract could be deployed and its address stored, or manage metadata manually.
        // For this example, we manage Fragment data in this contract and assume a separate ERC721 deployment
        // whose address will be set later (or hardcoded if deploying together).
        // We'll simulate fragment ownership/minting here using an internal mapping if no separate contract is used.
        // **Correction:** The prompt implies *this* contract *is* the forge, it should likely handle *both* NFT types.
        // Let's make this contract handle Crucible NFTs (inherited) and add internal logic/mapping for Fragment NFTs.
        // This is slightly unusual (one contract for two NFT types not ideal usually) but fits the "forge" concept where one entity creates different things.
        // Let's assume a separate ERC721 contract for Fragments for better practice, and store its address.
        // We need to deploy the Fragment ERC721 contract separately and set its address.
        // For simplicity in *this* single file example, let's *simulate* Fragment NFT management using mappings,
        // acknowledging this isn't a standard ERC721 deployment pattern for the Fragment NFTs.
        // A better pattern would be to deploy ERC721(Crucibles) and ERC721(Fragments) as separate contracts,
        // and this Forge contract interacts with both via their interfaces.
        // To meet the request within a single code block, we'll map Fragment IDs to data here.
        // **Re-correction:** Let's define Fragment struct here and map it, but rely on a *separate* ERC721 contract *instance* for the standard ERC721 functions (transfer, ownerOf etc.). This requires deploying two contracts. Okay, simplifying again for the single contract request: We'll mint *Crucibles* as ERC721s (inherited), and the *Fragments* will be represented by the `QuantumFragment` struct and owned via a mapping `_fragmentOwners` and their existence tracked by `_fragments`. This avoids needing two ERC721 implementations in one file but is still non-standard for Fragment ownership.

        // Let's adjust: Crucibles are inherited ERC721. Fragments are also ERC721, but let's simulate their data here and require a separate Fragment NFT contract address.
        // This requires a separate ERC721 for fragments. Let's mock it within this contract for demonstration purposes, but acknowledge the real-world need for a separate contract.

        // To achieve the function count and complexity in ONE contract:
        // - Crucibles are ERC721 (inherited).
        // - Fragments are *also* ERC721, but this contract will *internally* manage their data and rely on basic `_safeMint`/`_transfer` on *itself* using a different ID counter. This is confusing and bad practice (mixing two unrelated NFT types in one ERC721 implementation), but fulfills the "single contract, lots of functions" request.
        // Let's revert to the better design: Crucibles inherited ERC721. Fragments data stored here, rely on *external* Fragment ERC721 contract for actual minting/transfer. This requires admin to set the Fragment contract address.

         // Let's stick to the *best* approach: two distinct ERC721 implementations, but provide the code for *both* within this single file structure for demonstration, understanding that in deployment they would be separate files/contracts.

        // Okay, final decision for *this specific request*:
        // 1. `QuantumFluxForge` inherits `ERC721` for **Crucibles**.
        // 2. `QuantumFragmentNFT` will be defined as a separate internal contract/struct, and we'll simulate its minting/burning. This means Fragments are *not* standard ERC721s in *this* contract, but their properties and ownership *within the forge system* are tracked. This simplifies the code to one file and allows complex internal logic for fragments. This is creative but deviates from standard ERC721 for fragments. Let's go with this for maximum "novelty" within one file.
        // This means Fragment ownership is just a mapping `uint256 => address`. Transfers would be internal function calls updating this mapping.

        // Re-re-adjustment: The request is for 20+ functions in *the* smart contract. It doesn't strictly require the Fragments *themselves* to be ERC721 *implemented within this specific contract*. It's better practice to interact with a separate ERC721 contract for Fragments. Let's define the Fragment data here, and have admin set the Fragment ERC721 contract address. Functions like `combineFragments` will then call methods on that *external* contract.

        // **Final Plan:**
        // - Inherit ERC721 for Crucibles.
        // - Define Fragment data struct here.
        // - Add state variable for `fragmentNFTContract`.
        // - Functions like `finalizeSynthesis` will call `mint` on `fragmentNFTContract`.
        // - Functions like `combineFragments` will call `transferFrom` (to burn), then `mint` on `fragmentNFTContract`.
        // - Add a dummy ERC721 implementation for Fragments within this file for completeness, acknowledging it would be separate.

        // Okay, let's try integrating a *minimal* Fragment ERC721 within this file for demonstration, though deployment would separate. Or maybe just focus on the Forge's logic and assume the Fragment NFT contract exists and its address is set. Yes, let's do the latter for cleaner code focused on the Forge's mechanics.

        // We need to be able to interact with the Fragment NFT contract.
        // We'll need an interface for the Fragment ERC721.
        // Let's define a minimal interface and assume the full ERC721 is deployed elsewhere.

    }

    // --- Admin & Setup ---

    // @notice Sets the addresses for Catalyst A and Catalyst B ERC20 tokens.
    // @param _catalystA The address of the Catalyst A ERC20 token.
    // @param _catalystB The address of the Catalyst B ERC20 token.
    function setCatalystAddresses(address _catalystA, address _catalystB) public onlyOwner {
        catalystA = _catalystA;
        catalystB = _catalystB;
        catalystAddresses[0] = _catalystA;
        catalystAddresses[1] = _catalystB;
        // Note: Can add more catalysts if needed, update catalystAddresses array
    }

    // @notice Sets the synthesis parameters for a specific Crucible level.
    // @param _level The Crucible level for which parameters are being set.
    // @param _params The SynthesisParameters struct containing new values.
    function setSynthesisParameters(uint256 _level, SynthesisParameters calldata _params) public onlyOwner {
        synthesisParamsByCrucibleLevel[_level] = _params;
    }

     // @notice Sets the cost to create a new Crucible.
     // @param _costFlux The amount of FLUX tokens required to create a crucible.
    function setCrucibleCreationCost(uint256 _costFlux) public onlyOwner {
        crucibleCreationCostFlux = _costFlux;
    }

    // @notice Allows admin to withdraw accumulated fees from the contract.
    // @param tokenAddress The address of the token to withdraw.
    // @param amount The amount of the token to withdraw.
    function withdrawAdminFees(address tokenAddress, uint256 amount) public onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Invalid token address");
        require(adminFees[tokenAddress] >= amount, "Insufficient accumulated fees");

        adminFees[tokenAddress] -= amount;
        IERC20(tokenAddress).transfer(owner(), amount);
    }

    // --- Crucible Management (ERC721 + State) ---

    // @notice Creates a new Crucible NFT for the caller. Requires FLUX payment.
    function createCrucible() public nonReentrant {
        uint256 nextId = _crucibleIds.current();
        _crucibleIds.increment();

        // Require FLUX payment
        if (crucibleCreationCostFlux > 0) {
            IERC20(fluxToken).transferFrom(msg.sender, address(this), crucibleCreationCostFlux);
            adminFees[fluxToken] += crucibleCreationCostFlux; // Collect fee
        }

        // Mint the Crucible NFT
        _safeMint(msg.sender, nextId);

        // Initialize Crucible state
        _crucibles[nextId].level = 1;
        _crucibles[nextId].status = CrucibleStatus.Idle;
        // Ingredients mapping is initialized empty by default

        emit CrucibleCreated(nextId, msg.sender, 1);
    }

    // @notice Deposits ERC20 tokens (FLUX or Catalysts) into a specific Crucible.
    // @param _crucibleId The ID of the Crucible.
    // @param tokenAddress The address of the ERC20 token to deposit.
    // @param amount The amount of tokens to deposit.
    function depositToCrucible(uint256 _crucibleId, address tokenAddress, uint256 amount)
        public
        onlyCrucibleOwner(_crucibleId)
        whenCrucibleReadyForAction(_crucibleId) // Cannot deposit if actively synthesizing
        nonReentrant
    {
        require(tokenAddress == fluxToken || tokenAddress == catalystA || tokenAddress == catalystB, "Invalid token for deposit");
        require(amount > 0, "Deposit amount must be greater than zero");

        // Transfer tokens from sender to the contract (holding for the crucible)
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        _crucibles[_crucibleId].ingredients[tokenAddress] += amount;

        emit CrucibleIngredientsDeposited(_crucibleId, tokenAddress, amount);
    }

    // @notice Withdraws ERC20 tokens from a specific Crucible back to the owner.
    // @param _crucibleId The ID of the Crucible.
    // @param tokenAddress The address of the ERC20 token to withdraw.
    // @param amount The amount of tokens to withdraw.
    function withdrawFromCrucible(uint256 _crucibleId, address tokenAddress, uint256 amount)
        public
        onlyCrucibleOwner(_crucibleId)
        whenCrucibleReadyForAction(_crucibleId) // Cannot withdraw if actively synthesizing
        nonReentrant
    {
        require(tokenAddress == fluxToken || tokenAddress == catalystA || tokenAddress == catalystB, "Invalid token for withdrawal");
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(_crucibles[_crucibleId].ingredients[tokenAddress] >= amount, "Insufficient balance in crucible");

        _crucibles[_crucibleId].ingredients[tokenAddress] -= amount;

        // Transfer tokens from contract to sender
        IERC20(tokenAddress).transfer(msg.sender, amount);

        emit CrucibleIngredientsWithdrawn(_crucibleId, tokenAddress, amount);
    }

     // @notice Views the current balance of ingredients within a specific Crucible.
    // @param _crucibleId The ID of the Crucible.
    // @param tokenAddress The address of the ERC20 token to check.
    // @return The amount of the specified token held in the crucible.
    function getCrucibleIngredients(uint256 _crucibleId, address tokenAddress) public view returns (uint256) {
        // No ownership check needed for view functions
        return _crucibles[_crucibleId].ingredients[tokenAddress];
    }

     // @notice Views the current status of a Crucible (Idle, Synthesizing, Cooldown).
    // @param _crucibleId The ID of the Crucible.
    // @return The current status of the Crucible.
    function getCrucibleStatus(uint256 _crucibleId) public view returns (CrucibleStatus) {
        // No ownership check needed for view functions
         if (_crucibles[_crucibleId].status == CrucibleStatus.Cooldown && block.timestamp >= _crucibles[_crucibleId].synthesisCompletionTime) {
             return CrucibleStatus.Idle; // Cooldown finished, effectively idle
         }
        return _crucibles[_crucibleId].status;
    }

    // @notice Views the synthesis progress for a Crucible that is synthesizing.
    // @param _crucibleId The ID of the Crucible.
    // @return completionTime The timestamp when synthesis is expected to finish.
    // @return timeLeftSeconds The time remaining in seconds until completion (0 if not synthesizing or complete).
    function getCrucibleSynthesisProgress(uint256 _crucibleId) public view returns (uint64 completionTime, uint256 timeLeftSeconds) {
         if (_crucibles[_crucibleId].status != CrucibleStatus.Synthesizing) {
             return (0, 0);
         }
         completionTime = _crucibles[_crucibleId].synthesisCompletionTime;
         if (block.timestamp >= completionTime) {
             return (completionTime, 0); // Already completed
         }
         timeLeftSeconds = completionTime - uint64(block.timestamp);
         return (completionTime, timeLeftSeconds);
    }

    // @notice Upgrades a Crucible to the next level. May require ingredients/fragments.
    // @param _crucibleId The ID of the Crucible to upgrade.
    // @dev Example upgrade logic: requires more FLUX and maybe a specific Fragment type.
    function upgradeCrucible(uint256 _crucibleId) public onlyCrucibleOwner(_crucibleId) whenCrucibleReadyForAction(_crucibleId) nonReentrant {
        uint256 currentLevel = _crucibles[_crucibleId].level;
        uint256 nextLevel = currentLevel + 1;

        // Define upgrade costs/requirements (Example logic)
        uint256 fluxCost = nextLevel * 100 ether; // Cost increases with level
        // Add requirements for catalysts or fragments here if desired
        // e.g., require(getCrucibleIngredients(_crucibleId, catalystA) >= nextLevel * 5 ether, "Need more CatalystA");
        // e.g., require(userHoldsFragmentOfType(msg.sender, FragmentType.Stability), "Need Stability Fragment");

        // Check and consume ingredients from crucible
        require(_crucibles[_crucibleId].ingredients[fluxToken] >= fluxCost, "Insufficient FLUX in crucible for upgrade");
        _crucibles[_crucibleId].ingredients[fluxToken] -= fluxCost;

        // If using fragments for upgrade, need to burn them (interact with fragment NFT contract)
        // Example: require(IERC721(fragmentNFTContract).balanceOf(msg.sender) >= 1, "Need a Fragment");
        // Call IERC721(fragmentNFTContract).burn(fragmentId);

        // Perform upgrade
        _crucibles[_crucibleId].level = nextLevel;
        // New synthesis parameters for this level should be set by admin via setSynthesisParameters

        emit CrucibleUpgraded(_crucibleId, nextLevel);
    }

    // @notice Gets all key data about a specific Crucible.
    // @param _crucibleId The ID of the Crucible.
    // @return level The crucible's level.
    // @return status The crucible's status.
    // @return synthesisCompletionTime The timestamp synthesis completes (0 if not synthesizing/cooldown finished).
    // @return fluxAmount The amount of FLUX in the crucible.
    // @return catalystAAmount The amount of Catalyst A in the crucible.
    // @return catalystBAmount The amount of Catalyst B in the crucible.
    function getCrucibleData(uint256 _crucibleId) public view returns (
        uint256 level,
        CrucibleStatus status,
        uint64 synthesisCompletionTime,
        uint256 fluxAmount,
        uint256 catalystAAmount,
        uint256 catalystBAmount
    ) {
        Crucible storage crucible = _crucibles[_crucibleId];
        level = crucible.level;
        // Check for cooldown expiration
        status = (crucible.status == CrucibleStatus.Cooldown && block.timestamp >= crucible.synthesisCompletionTime)
                 ? CrucibleStatus.Idle : crucible.status;
        synthesisCompletionTime = crucible.synthesisCompletionTime;
        fluxAmount = crucible.ingredients[fluxToken];
        catalystAAmount = crucible.ingredients[catalystA];
        catalystBAAmount = crucible.ingredients[catalystB];
    }


    // --- Synthesis Process ---

    // @notice Initiates a synthesis process in an owned, idle Crucible.
    // @param _crucibleId The ID of the Crucible.
    // @param _userParam1 Example user-provided parameter influencing outcome (e.g., desired resonance focus)
    // @param _userParam2 Example user-provided parameter (e.g., desired stability focus)
    function initiateSynthesis(uint256 _crucibleId, uint256 _userParam1, uint256 _userParam2)
        public
        onlyCrucibleOwner(_crucibleId)
        whenCrucibleIdle(_crucibleId)
        nonReentrant
    {
        uint256 level = _crucibles[_crucibleId].level;
        SynthesisParameters memory params = synthesisParamsByCrucibleLevel[level];

        // Check required ingredients based on level parameters
        require(_crucibles[_crucibleId].ingredients[fluxToken] >= params.baseFluxCost,
            QuantumFluxForge__InsufficientCrucibleIngredients(_crucibleId, fluxToken, params.baseFluxCost, _crucibles[_crucibleId].ingredients[fluxToken]));
        require(_crucibles[_crucibleId].ingredients[catalystA] >= params.baseCatalystACost,
             QuantumFluxForge__InsufficientCrucibleIngredients(_crucibleId, catalystA, params.baseCatalystACost, _crucibles[_crucibleId].ingredients[catalystA]));
         require(_crucibles[_crucibleId].ingredients[catalystB] >= params.baseCatalystBCost,
             QuantumFluxForge__InsufficientCrucibleIngredients(_crucibleId, catalystB, params.baseCatalystBCost, _crucibles[_crucibleId].ingredients[catalystB]));

        // Consume ingredients immediately upon initiation
        _crucibles[_crucibleId].ingredients[fluxToken] -= params.baseFluxCost;
        _crucibles[_crucibleId].ingredients[catalystA] -= params.baseCatalystACost;
        _crucibles[_crucibleId].ingredients[catalystB] -= params.baseCatalystBCost;

        // Update Crucible state
        _crucibles[_crucibleId].status = CrucibleStatus.Synthesizing;
        _crucibles[_crucibleId].synthesisStartTime = uint64(block.timestamp);
        _crucibles[_crucibleId].synthesisCompletionTime = uint64(block.timestamp + params.durationSeconds);

        // Store recipe hash for later verification/analysis (example includes params, state, ingredients)
        _crucibles[_crucibleId].synthesisRecipeHash = keccak256(abi.encodePacked(
            block.timestamp,
            _crucibleId,
            level,
            params.baseFluxCost,
            params.baseCatalystACost,
            params.baseCatalystBCost,
            _userParam1,
            _userParam2,
            fluxEquilibrium, // Include current global state
            entropyLevel
        ));

        emit SynthesisInitiated(_crucibleId, msg.sender, _crucibles[_crucibleId].synthesisRecipeHash, _crucibles[_crucibleId].synthesisCompletionTime);
    }

    // @notice Finalizes a synthesis process that has completed its duration.
    // @param _crucibleId The ID of the Crucible.
    // @dev This function calculates the outcome, potentially mints a Fragment NFT, and updates state.
    function finalizeSynthesis(uint256 _crucibleId)
        public
        onlyCrucibleOwner(_crucibleId)
        whenSynthesisComplete(_crucibleId)
        nonReentrant
    {
        Crucible storage crucible = _crucibles[_crucibleId];
        uint256 level = crucible.level;
        SynthesisParameters memory params = synthesisParamsByCrucibleLevel[level];

        // --- Outcome Calculation Logic ---
        // Use synthesisRecipeHash, block data (with caution), global state, and possibly user params stored implicitly in hash

        // Pseudo-randomness seed (mix block data and recipe hash)
        // WARNING: blockhash is only available for the last 256 blocks and is manipulable by miners.
        // For production, use a Chainlink VRF or similar secure randomness source.
        bytes32 seed = keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // Or block.basefee in PoS
            block.number,
            blockhash(block.number - 1), // Use hash of previous block
            crucible.synthesisRecipeHash // Incorporate original inputs
        ));

        uint256 randomness = uint256(seed);

        // Base success chance modified by global state and possibly user parameters
        int256 successChanceModifier = fluxEquilibrium / 20; // Example: Equilibrium affects chance
        uint256 currentSuccessChance = uint256(int256(params.baseSuccessChancePercent) + successChanceModifier);
        currentSuccessChance = Math.max(0, currentSuccessChance); // Clamp minimum chance
        currentSuccessChance = Math.min(100, currentSuccessChance); // Clamp maximum chance

        bool synthesisSuccessful = (randomness % 100) < currentSuccessChance;

        uint256 mintedFragmentId = 0;

        if (synthesisSuccessful) {
            // --- Mint Quantum Fragment NFT ---
            uint256 nextFragmentId = _fragmentIds.current();
            _fragmentIds.increment();

            // Simulate minting an external Fragment ERC721 (replace with actual call)
            // IERC721(fragmentNFTContract).safeMint(msg.sender, nextFragmentId);
             // For this example, we track ownership internally:
             _fragmentOwners[nextFragmentId] = msg.sender;


            // Generate Fragment Properties Algorithmically
            QuantumFragment memory newFragment;
            newFragment.creationBlock = block.number;
            newFragment.creator = msg.sender;
            newFragment.createdInCrucibleId = _crucibleId;
            newFragment.creationSeed = seed; // Store seed for reproducibility/verification

            // Generate properties based on seed, global state, crucible level, user params (from hash)
            newFragment.resonance = (uint256(keccak256(abi.encodePacked(seed, "resonance"))) % 1000) + 1; // 1-1000
            newFragment.stability = (uint256(keccak256(abi.encodePacked(seed, "stability"))) % 1000) + 1; // 1-1000

            // Example: Global state influences property distribution
            newFragment.resonance = newFragment.resonance + uint256(Math.max(0, fluxEquilibrium / 10));
            newFragment.stability = newFragment.stability + uint256(Math.max(0, -fluxEquilibrium / 10));

            // Example: Entropy increases property variance
            if (entropyLevel > 0) {
                 uint256 variance = (randomness % entropyLevel);
                 newFragment.resonance = newFragment.resonance + variance;
                 newFragment.stability = newFragment.stability + variance;
            }

            // Example: Crucible level influences average property value
            newFragment.resonance = newFragment.resonance + (level * 10);
            newFragment.stability = newFragment.stability + (level * 10);


            // Clamp properties to a range (e.g., 1-2000)
            newFragment.resonance = Math.min(2000, newFragment.resonance);
            newFragment.stability = Math.min(2000, newFragment.stability);

            // Calculate a rarity score (example: based on sum of properties)
            newFragment.rarityScore = (newFragment.resonance + newFragment.stability) / 2; // Simple average

            _fragments[nextFragmentId] = newFragment;
            mintedFragmentId = nextFragmentId;

            emit QuantumFragmentMinted(mintedFragmentId, msg.sender, _crucibleId, newFragment.rarityScore);

        } else {
            // Synthesis failed - ingredients already consumed, maybe add small FLUX back or nothing
            // For simplicity, ingredients are lost on failure in this example.
        }

        // Update Global State based on Synthesis Parameters
        _updateGlobalState(
            params.equilibriumInfluencePerSynthesize,
            int256(params.entropyIncreasePerSynthesize) // Cast to signed for delta
        );


        // Put Crucible on Cooldown
        uint256 cooldownDuration = params.durationSeconds / 2; // Example: Cooldown is half synthesis time
        crucible.status = CrucibleStatus.Cooldown;
        crucible.synthesisCompletionTime = uint64(block.timestamp + cooldownDuration); // Cooldown ends after this time

        // Reset synthesis start time and recipe hash after completion/failure
        crucible.synthesisStartTime = 0;
        crucible.synthesisRecipeHash = bytes32(0);

        emit SynthesisFinalized(_crucibleId, msg.sender, synthesisSuccessful, mintedFragmentId);
    }

    // @notice Allows cancellation of an active synthesis process. May incur a penalty.
    // @param _crucibleId The ID of the Crucible.
    // @dev Example: Returns a percentage of FLUX but loses catalysts and time.
    function cancelSynthesis(uint256 _crucibleId)
        public
        onlyCrucibleOwner(_crucibleId)
        whenCrucibleSynthesizing(_crucibleId)
        nonReentrant
    {
        Crucible storage crucible = _crucibles[_crucibleId];
        uint256 level = crucible.level;
        SynthesisParameters memory params = synthesisParamsByCrucibleLevel[level];

        uint64 durationElapsed = uint64(block.timestamp) - crucible.synthesisStartTime;
        // Calculate penalty/return based on time elapsed or fixed amount
        uint256 fluxReturned = (params.baseFluxCost * (params.durationSeconds - durationElapsed)) / params.durationSeconds; // Return proportional to time left

        // Ensure some minimum return or fixed penalty
        if (fluxReturned == 0 && durationElapsed < params.durationSeconds) {
             // If duration is very short and calculation rounds to 0, enforce minimum return or just lose everything based on policy.
             // Let's say if initiated, catalysts are always lost, some flux returned.
             fluxReturned = params.baseFluxCost / 10; // Example: minimum 10% returned regardless of time
        }
         if (durationElapsed >= params.durationSeconds) {
              // Should not happen with whenCrucibleSynthesizing, but safety: if somehow here after completion, no return.
             fluxReturned = 0;
         }


        // Return proportional FLUX
        if (fluxReturned > 0) {
             _crucibles[_crucibleId].ingredients[fluxToken] += fluxReturned;
        }

        // Catalysts are lost (already consumed on initiate)

        // Reset Crucible state to Idle immediately (no cooldown on cancel)
        crucible.status = CrucibleStatus.Idle;
        crucible.synthesisStartTime = 0;
        crucible.synthesisCompletionTime = 0;
        crucible.synthesisRecipeHash = bytes32(0);


        emit SynthesisCancelled(_crucibleId, msg.sender, params.baseFluxCost - fluxReturned);
    }

     // @notice Estimates the likely outcome of synthesis given current inputs and state.
     // @dev This is a *view* function and cannot use future block data, so it's an estimate.
     // @param _crucibleId The ID of the Crucible.
     // @param _userParam1 Example user-provided parameter.
     // @param _userParam2 Example user-provided parameter.
     // @return estimatedSuccessChancePercent The estimated chance of success (0-100).
     // @return estimatedMinRarity The estimated minimum rarity score if successful.
     // @return estimatedMaxRarity The estimated maximum rarity score if successful.
    function estimateSynthesisOutcome(uint256 _crucibleId, uint256 _userParam1, uint256 _userParam2)
         public
         view
         returns (uint256 estimatedSuccessChancePercent, uint256 estimatedMinRarity, uint256 estimatedMaxRarity)
    {
         // Cannot check ownership or status in a pure view function if it modifies state access slightly.
         // Let's make it view, assuming _crucibleId is valid.
        uint256 level = _crucibles[_crucibleId].level;
        SynthesisParameters memory params = synthesisParamsByCrucibleLevel[level];

        // Check required ingredients (optional in view, but good for UX)
        // require(_crucibles[_crucibleId].ingredients[fluxToken] >= params.baseFluxCost, "Insufficient FLUX in crucible");
        // ... similar checks for catalysts ...

        // Estimate success chance (using current global state)
        int256 successChanceModifier = fluxEquilibrium / 20;
        estimatedSuccessChancePercent = uint256(int256(params.baseSuccessChancePercent) + successChanceModifier);
        estimatedSuccessChancePercent = Math.max(0, estimatedSuccessChancePercent);
        estimatedSuccessChancePercent = Math.min(100, estimatedSuccessChancePercent);

        // Estimate rarity range (this is a simplified example)
        // True rarity depends on a seed including future block data, which we can't predict.
        // Provide a range based on level and maybe user params, ignoring randomness.
        uint256 baseRarity = (level * 10) + 50; // Example base
        uint256 paramInfluence = (_userParam1 + _userParam2) / 10; // Example param influence

        // Simulate entropy influence on range (cannot use real randomness)
        uint256 estimatedVariance = entropyLevel / 5; // Example: higher entropy = wider range

        estimatedMinRarity = Math.max(0, baseRarity + paramInfluence - estimatedVariance);
        estimatedMaxRarity = baseRarity + paramInfluence + estimatedVariance;

        // Note: This is a very rough estimate. The actual outcome calculation in finalizeSynthesis is the source of truth.
    }

    // --- Quantum Fragment Interaction (Requires external Fragment NFT Contract) ---
    // NOTE: This section assumes a separate ERC721 contract is deployed for Quantum Fragments,
    // and its address is set via an admin function (omitted for brevity in this example file).
    // All interactions like minting, burning, transferring fragments happen on that contract.
    // We store Fragment *data* here mapped by Fragment ID.

    // Interface for the Fragment NFT contract (assuming it's a standard ERC721 with mint/burn/transferFrom)
    interface IQuantumFragmentNFT {
        function safeTransferFrom(address from, address to, uint256 tokenId) external;
        function transferFrom(address from, address to, uint256 tokenId) external; // For burning (transfer to address(0) or a burn address)
        function safeMint(address to, uint256 tokenId) external; // Example mint function
        function ownerOf(uint256 tokenId) external view returns (address);
        function isApprovedForAll(address owner, address operator) external view returns (bool);
        function setApprovalForAll(address operator, bool approved) external;
         function approve(address to, uint256 tokenId) external;
         function balanceOf(address owner) external view returns (uint256);

         // Optional: Add functions to get properties from the NFT contract if stored there
         // function getFragmentProperties(uint256 tokenId) external view returns (...);
    }

    // We need to set this address via admin function
    address public fragmentNFTContract;

    // @notice Admin sets the address of the deployed Quantum Fragment NFT contract.
    // @param _fragmentNFTContract The address of the Fragment NFT contract.
    function setFragmentNFTContract(address _fragmentNFTContract) public onlyOwner {
        fragmentNFTContract = _fragmentNFTContract;
        // Ensure it's not address(0) if needed
    }


     // Internal helper to get fragment data
     function _getFragmentData(uint256 _fragmentId) internal view returns (QuantumFragment storage) {
         require(_fragments[_fragmentId].creationBlock > 0, "Fragment does not exist"); // Check if fragment data exists
         return _fragments[_fragmentId];
     }

    // @notice Views the properties of a specific Quantum Fragment NFT.
    // @param _fragmentId The ID of the Quantum Fragment NFT.
    // @return resonance The resonance property.
    // @return stability The stability property.
    // @return rarityScore The rarity score.
    // @return creationBlock The block number it was created.
    function getFragmentProperties(uint256 _fragmentId)
        public
        view
        returns (uint256 resonance, uint256 stability, uint256 rarityScore, uint256 creationBlock)
    {
         // Check if fragment exists (could also check ownerOf from Fragment NFT contract)
         require(_fragments[_fragmentId].creationBlock > 0, "Fragment does not exist or data not found");

        QuantumFragment storage fragment = _fragments[_fragmentId];
        return (fragment.resonance, fragment.stability, fragment.rarityScore, fragment.creationBlock);
    }

    // @notice Attempts to combine multiple Quantum Fragment NFTs to create a new one.
    // @param _fragmentIds The IDs of the Fragments to combine (will be burned).
    // @dev This is a complex function. Example: Burns 3 fragments to get 1 new one.
    function combineFragments(uint256[] calldata _fragmentIds) public nonReentrant {
        // Example: Requires exactly 3 fragments
        uint256 requiredFragments = 3;
        require(_fragmentIds.length == requiredFragments, QuantumFluxForge__NotEnoughFragmentsToCombine(_fragmentIds.length, requiredFragments));
        require(fragmentNFTContract != address(0), "Fragment NFT contract address not set");

        IQuantumFragmentNFT fragmentNFT = IQuantumFragmentNFT(fragmentNFTContract);

        // Check ownership and get total properties
        uint256 totalResonance = 0;
        uint256 totalStability = 0;
        bytes32 combinedSeed = bytes32(0);

        for (uint256 i = 0; i < requiredFragments; i++) {
            uint256 fragmentId = _fragmentIds[i];
            // Check if sender owns the fragment using the external NFT contract
            require(fragmentNFT.ownerOf(fragmentId) == msg.sender, "Sender does not own all fragments");

            // Get internal fragment data
             QuantumFragment storage fragment = _getFragmentData(fragmentId); // Check if data exists
            totalResonance += fragment.resonance;
            totalStability += fragment.stability;
            combinedSeed = keccak256(abi.encodePacked(combinedSeed, fragment.creationSeed)); // Combine seeds
        }

        // Burn the input fragments (requires allowance or operator status on the Fragment NFT contract)
        // User needs to approve the Forge contract to manage their fragments *before* calling this.
        for (uint256 i = 0; i < requiredFragments; i++) {
             uint256 fragmentId = _fragmentIds[i];
             // Transfer to address(0) or a dedicated burn address
             // In ERC721, transfer to address(0) triggers _burn logic usually
             fragmentNFT.transferFrom(msg.sender, address(0), fragmentId);

             // Mark internal fragment data as invalid/burned (optional, but good practice)
             _fragments[fragmentId].creationBlock = 0; // Invalidate data
        }


        // --- Generate New Fragment ---
        uint256 nextFragmentId = _fragmentIds.current();
        _fragmentIds.increment();

        // Simulate minting the new Fragment NFT
        fragmentNFT.safeMint(msg.sender, nextFragmentId);
         _fragmentOwners[nextFragmentId] = msg.sender; // Internal tracking

        QuantumFragment memory newFragment;
        newFragment.creationBlock = block.number;
        newFragment.creator = msg.sender;
        newFragment.createdInCrucibleId = 0; // Created by combination, not a crucible
        newFragment.creationSeed = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), combinedSeed)); // New seed

        // Generate new properties based on combined inputs, seed, and global state
        newFragment.resonance = (totalResonance / requiredFragments) + (uint256(keccak256(abi.encodePacked(newFragment.creationSeed, "comb_res"))) % 500); // Average + bonus
        newFragment.stability = (totalStability / requiredFragments) + (uint256(keccak256(abi.encodePacked(newFragment.creationSeed, "comb_stab"))) % 500); // Average + bonus

        // Clamp properties
        newFragment.resonance = Math.min(3000, newFragment.resonance); // Higher max for combined?
        newFragment.stability = Math.min(3000, newFragment.stability);

        newFragment.rarityScore = ((newFragment.resonance + newFragment.stability) / 2) + 100; // Higher base rarity

        _fragments[nextFragmentId] = newFragment;

        emit QuantumFragmentCombined(_fragmentIds, nextFragmentId, msg.sender);

        // Optional: Influence global state based on combination result
        _updateGlobalState(
            int256(newFragment.rarityScore / 50), // High rarity combination shifts equilibrium positive
            -int256(newFragment.rarityScore / 100) // Reduces entropy
        );

    }

    // @notice Dissolves a Quantum Fragment NFT to recover some FLUX or influence state.
    // @param _fragmentId The ID of the Fragment to dissolve.
    function dissolveFragment(uint256 _fragmentId) public nonReentrant {
         require(fragmentNFTContract != address(0), "Fragment NFT contract address not set");
         IQuantumFragmentNFT fragmentNFT = IQuantumFragmentNFT(fragmentNFTContract);

         // Check ownership using the external NFT contract
         require(fragmentNFT.ownerOf(_fragmentId) == msg.sender, "Sender does not own fragment");

         // Get internal fragment data
         QuantumFragment storage fragment = _getFragmentData(_fragmentId);

        // Calculate recovered FLUX or state influence based on properties
        uint256 recoveredFluxAmount = fragment.rarityScore * 5 ether; // Example: Rarity gives FLUX

        // Burn the fragment via the external NFT contract
        fragmentNFT.transferFrom(msg.sender, address(0), _fragmentId); // Burn

        // Invalidate internal data
         _fragments[_fragmentId].creationBlock = 0;

        // Transfer recovered FLUX to sender
        if (recoveredFluxAmount > 0) {
             IERC20(fluxToken).transfer(msg.sender, recoveredFluxAmount);
        }

        emit QuantumFragmentDissolved(_fragmentId, msg.sender, recoveredFluxAmount);

        // Optional: Influence global state
        _updateGlobalState(
            -int256(fragment.rarityScore / 200), // Dissolving high rarity slightly reduces equilibrium
            int256(fragment.rarityScore / 50) // Increases entropy
        );
    }

    // @notice Allows a user to use a Fragment (or its properties) to attempt to catalyze the global state.
    // @param _fragmentId The ID of the Fragment to use (consumed in the process).
    // @dev This function consumes the fragment and shifts the global state based on its properties.
    function catalyzeGlobalState(uint256 _fragmentId) public nonReentrant {
        require(fragmentNFTContract != address(0), "Fragment NFT contract address not set");
        IQuantumFragmentNFT fragmentNFT = IQuantumFragmentNFT(fragmentNFTContract);

        // Check ownership using the external NFT contract
        require(fragmentNFT.ownerOf(_fragmentId) == msg.sender, "Sender does not own fragment");

        // Get internal fragment data
        QuantumFragment storage fragment = _getFragmentData(_fragmentId);

        // Define influence based on fragment properties (example: higher resonance/stability shift equilibrium)
        int256 equilibriumShift = int256(fragment.resonance / 50) - int256(fragment.stability / 50);
        int256 entropyShift = -int256(fragment.rarityScore / 100); // High rarity reduces entropy

        // Burn the fragment via the external NFT contract
        fragmentNFT.transferFrom(msg.sender, address(0), _fragmentId); // Burn

        // Invalidate internal data
        _fragments[_fragmentId].creationBlock = 0;

        // Apply state shift
        _updateGlobalState(equilibriumShift, entropyShift);

        emit GlobalStateEquilibriumUpdated(fluxEquilibrium, equilibriumShift);
        emit GlobalStateEntropyUpdated(entropyLevel, entropyShift);
        emit QuantumFragmentDissolved(_fragmentId, msg.sender, 0); // Treat as dissolution without recovery

         // Optional: Add a cooldown or cost to this action
         // require(block.timestamp > lastGlobalStateCatalyzeTime + catalyzeCooldown, QuantumFluxForge__GlobalStateCannotBeCatalyzedYet());
         // lastGlobalStateCatalyzeTime = block.timestamp;
    }


    // --- Global State Interaction & Info ---

    // @notice Internal function to update global state based on delta values and natural drift.
    // @param equilibriumDelta Change to equilibrium.
    // @param entropyDelta Change to entropy.
    function _updateGlobalState(int256 equilibriumDelta, int256 entropyDelta) internal {
        uint64 timeElapsed = uint64(block.timestamp) - lastGlobalStateUpdate;

        // --- Apply Natural Drift ---
        // Example drift: Equilibrium naturally drifts towards 0 over time. Entropy naturally increases.
        int256 naturalEquilibriumDrift = (fluxEquilibrium > 0 ? -1 : 1) * int256(timeElapsed / 600); // Drifts 1 unit every 10 minutes towards 0
        uint256 naturalEntropyIncrease = timeElapsed / 1800; // Increases 1 unit every 30 minutes

        fluxEquilibrium += naturalEquilibriumDrift + equilibriumDelta;
        entropyLevel += naturalEntropyIncrease;

        // Clamp values (example ranges)
        fluxEquilibrium = Math.max(-1000, fluxEquilibrium);
        fluxEquilibrium = Math.min(1000, fluxEquilibrium);
        entropyLevel = Math.min(200, entropyLevel); // Entropy max cap

        lastGlobalStateUpdate = uint64(block.timestamp);

        // Emit events for drift + delta combined effect
        // It might be better to emit separate events for natural drift and action delta if needed for tracking
    }


     // @notice Views the current global Flux Equilibrium value.
     // @return The current fluxEquilibrium.
     function getCurrentFluxEquilibrium() public view returns (int256) {
         // Apply potential drift since last update for accurate *current* view
         uint64 timeElapsed = uint64(block.timestamp) - lastGlobalStateUpdate;
         int256 naturalDrift = (fluxEquilibrium > 0 ? -1 : 1) * int256(timeElapsed / 600);
         return fluxEquilibrium + naturalDrift;
     }

     // @notice Views the current global Entropy Level value.
     // @return The current entropyLevel.
     function getCurrentEntropyLevel() public view returns (uint256) {
         // Apply potential drift since last update
          uint64 timeElapsed = uint64(block.timestamp) - lastGlobalStateUpdate;
          uint256 naturalIncrease = timeElapsed / 1800;
          uint256 currentEntropy = entropyLevel + naturalIncrease;
          return Math.min(200, currentEntropy); // Apply max cap
     }

    // @notice Performs a stabilization ritual to push fluxEquilibrium towards zero. Requires FLUX.
    // @dev Example: Consumes a large amount of FLUX and significantly reduces equilibrium deviation.
    function performStabilizationRitual(uint256 _amountFlux) public nonReentrant {
         uint256 requiredFlux = _amountFlux; // User specifies amount to burn
         require(requiredFlux > 0, "Must use a non-zero amount of FLUX");

         // Transfer and burn the FLUX
         IERC20(fluxToken).transferFrom(msg.sender, address(this), requiredFlux);
         // Optionally send to a burn address: IERC20(fluxToken).transfer(address(0xdead), requiredFlux);
         adminFees[fluxToken] += requiredFlux; // Or just burn it entirely

         // Calculate equilibrium shift based on FLUX amount and current deviation
         // More FLUX needed if further from zero
         int256 deviation = fluxEquilibrium;
         uint256 requiredBase = uint256(Math.abs(deviation)) * 100 ether; // More FLUX needed if further
         require(requiredFlux >= requiredBase, "Insufficient FLUX for stabilization at current deviation");

         int256 equilibriumShift = (deviation > 0 ? -1 : 1) * int256(requiredFlux / 100 ether); // Shift is proportional to FLUX used

         // Apply state shift
         _updateGlobalState(equilibriumShift, -int256(requiredFlux / 1000 ether)); // Stabilization slightly reduces entropy

         emit StabilizationRitualPerformed(equilibriumShift);
    }

    // @notice Triggers a flux cascade, causing a large, semi-random shift in global state. Requires rare inputs (e.g., high rarity fragments or specific catalyst combinations).
    // @dev This is a risky action with unpredictable outcomes. Example: requires burning a very high rarity fragment.
    // @param _fragmentId High rarity fragment to consume.
    function triggerFluxCascade(uint256 _fragmentId) public nonReentrant {
         require(fragmentNFTContract != address(0), "Fragment NFT contract address not set");
         IQuantumFragmentNFT fragmentNFT = IQuantumFragmentNFT(fragmentNFTContract);

         require(fragmentNFT.ownerOf(_fragmentId) == msg.sender, "Sender does not own fragment");
         QuantumFragment storage fragment = _getFragmentData(_fragmentId);

         // Require a minimum rarity score for this action
         uint256 minRarityForCascade = 1500; // Example threshold
         require(fragment.rarityScore >= minRarityForCascade, "Fragment rarity too low to trigger cascade");

         // Burn the required fragment
         fragmentNFT.transferFrom(msg.sender, address(0), _fragmentId);
         _fragments[_fragmentId].creationBlock = 0;

         // Calculate large, semi-random state shifts based on fragment seed and current state
         bytes32 cascadeSeed = keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), fragment.creationSeed, fluxEquilibrium, entropyLevel));
         uint256 randomness = uint256(cascadeSeed);

         int256 equilibriumShift = int256((randomness % 2001) - 1000); // Shift between -1000 and 1000
         int256 entropyShift = int256((randomness % 101) - 50); // Shift between -50 and 50

         // Apply state shift
         _updateGlobalState(equilibriumShift, entropyShift);

         emit FluxCascadeTriggered(equilibriumShift, entropyShift);
    }


    // --- View & Utility ---

    // @notice Gets the total number of Crucible NFTs minted.
    // @return The total count of Crucibles.
    function getTotalCrucibles() public view returns (uint256) {
        return _crucibleIds.current();
    }

    // @notice Gets the total number of Quantum Fragment NFTs minted.
    // @return The total count of Fragments.
    function getTotalFragments() public view returns (uint256) {
        return _fragmentIds.current();
    }

     // @notice Views the base required ingredients for initiating synthesis at a given Crucible level.
     // @param _level The Crucible level.
     // @return fluxCost Base FLUX required.
     // @return catalystACost Base Catalyst A required.
     // @return catalystBCost Base Catalyst B required.
     function getRequiredSynthesisIngredients(uint256 _level) public view returns (uint256 fluxCost, uint256 catalystACost, uint256 catalystBCost) {
          SynthesisParameters memory params = synthesisParamsByCrucibleLevel[_level];
          return (params.baseFluxCost, params.baseCatalystACost, params.baseCatalystBCost);
     }

     // @notice Views the specific recipe hash used for a completed synthesis in a Crucible.
     // @param _crucibleId The ID of the Crucible.
     // @return The recipe hash (0 if not synthesizing or never synthesized).
     function getSynthesisRecipeDetails(uint256 _crucibleId) public view returns (bytes32) {
          // No ownership check, anyone can view past recipes for analysis
          return _crucibles[_crucibleId].synthesisRecipeHash; // Returns 0 if not set
     }

     // @notice Views the timestamp of the last update to the global state (equilibrium or entropy).
     // @return The timestamp of the last global state update.
     function getLastGlobalStateUpdate() public view returns (uint64) {
         return lastGlobalStateUpdate;
     }

    // @notice Estimates the natural drift component of the global state based on time elapsed.
    // @return estimatedEquilibriumDrift The estimated change in equilibrium due to drift.
    // @return estimatedEntropyIncrease The estimated increase in entropy due to drift.
     function getEstimatedNaturalGlobalStateDrift() public view returns (int256 estimatedEquilibriumDrift, uint256 estimatedEntropyIncrease) {
         uint64 timeElapsed = uint64(block.timestamp) - lastGlobalStateUpdate;
         estimatedEquilibriumDrift = (fluxEquilibrium > 0 ? -1 : 1) * int256(timeElapsed / 600); // Drifts 1 unit every 10 minutes towards 0
         estimatedEntropyIncrease = timeElapsed / 1800; // Increases 1 unit every 30 minutes
     }

    // --- Internal Fragment Ownership Tracking (Simulated) ---
    // Since we are simulating Fragment NFTs internally for this single contract example,
    // we need a way to track ownership for the Fragment interaction functions.
    mapping(uint256 => address) private _fragmentOwners; // Maps fragment ID to owner address

    // Helper to get fragment owner (simulated)
    function _getFragmentOwner(uint256 _fragmentId) internal view returns (address) {
        require(_fragments[_fragmentId].creationBlock > 0, "Fragment does not exist"); // Check if fragment data exists
        return _fragmentOwners[_fragmentId];
    }

    // Helper to check fragment ownership (simulated) - used by public functions
    function getFragmentOwner(uint256 _fragmentId) public view returns (address) {
         return _getFragmentOwner(_fragmentId);
    }

    // Basic internal transfer simulation (used by combine/dissolve/catalyze)
    // NOT a full ERC721 transfer
    // function _transferFragmentOwnership(address from, address to, uint256 tokenId) internal {
    //     require(_fragmentOwners[tokenId] == from, "Fragment transfer: Not owner");
    //     _fragmentOwners[tokenId] = to;
    //      // Emit Transfer event? Requires defining event IERC721 compatible
    // }

    // Note: For a real system, the Fragment NFT contract would handle actual transfers,
    // and this Forge contract would interact with it using `transferFrom` etc.
    // The `combineFragments`, `dissolveFragment`, `catalyzeGlobalState` functions already
    // include the intended calls to the external `fragmentNFTContract` for actual burning.

    // --- Required ERC721 overrides for Crucible NFTs ---

     function supportsInterface(bytes4 interfaceId) public view override(ERC721, Ownable) returns (bool) {
         return interfaceId == type(IERC721).interfaceId ||
                interfaceId == type(IERC165).interfaceId || // ERC165 support
                interfaceId == type(IOwnable).interfaceId; // Ownable support
     }

    // The rest of ERC721 functions (ownerOf, balanceOf, approve, setApprovalForAll, getApproved, isApprovedForAll, transferFrom, safeTransferFrom)
    // are inherited and work directly for Crucible NFTs using the internal ERC721 state.

}
```

**Explanation of Concepts and Design Choices:**

1.  **Crucibles as NFTs:** Represents ownership of a stateful "slot" within the Forge. This allows users to have personal crafting stations whose attributes (like level) can evolve. Using ERC721 makes these slots tradable assets.
2.  **Time-Locked Synthesis:** The `initiateSynthesis` and `finalizeSynthesis` pattern is common for processes that take time. `initiate` locks resources and starts the timer, `finalize` executes the outcome logic *after* the time passes. This prevents instant crafting and adds a strategic element (timing, potential front-running risks mitigated by relying on future blocks in `finalize`).
3.  **Algorithmic Fragment Properties:** Instead of static metadata, Fragment properties (`resonance`, `stability`) are calculated directly on-chain during `finalizeSynthesis`. The inputs include:
    *   Synthesis ingredients and user parameters (implicit via the `synthesisRecipeHash`).
    *   Crucible level.
    *   The global state (`fluxEquilibrium`, `entropyLevel`).
    *   A "seed" derived from block data and the recipe hash. This makes each fragment unique and ties its properties to the specific conditions of its creation. **Crucially, relying solely on `blockhash` and `block.timestamp`/`difficulty` is vulnerable to miner manipulation, especially for high-value outcomes. A production system would use a secure oracle like Chainlink VRF for true unpredictable randomness.** This code uses basic block data for demonstration.
4.  **Dynamic Global State:** `fluxEquilibrium` and `entropyLevel` introduce a system-wide state that isn't static. They represent abstract concepts that influence the Forge's behavior.
    *   `fluxEquilibrium`: Could affect success chance, property ranges, or required inputs. Drifts naturally towards zero.
    *   `entropyLevel`: Could affect variance in outcomes, success/failure distribution, or side effects. Naturally increases.
    *   User actions (`finalizeSynthesis`, `performStabilizationRitual`, `triggerFluxCascade`, `catalyzeGlobalState`) actively push or pull these values, creating system-wide incentives/disincentives and a meta-game around managing the Forge's environment. The `_updateGlobalState` internal function handles both the action-based delta and the natural time-based drift.
5.  **Fragment Utility:** Fragments are not just passive collectibles.
    *   They can be combined (`combineFragments`) to potentially create rarer fragments (a resource sink and upgrade path). The combined properties and a new seed determine the outcome.
    *   They can be dissolved (`dissolveFragment`) to reclaim some value (a resource faucet, utility for unwanted fragments).
    *   They can be used to directly influence the global state (`catalyzeGlobalState`), tying the generated assets back into the core system mechanics.
6.  **Distinct Asset Management:** The code models two distinct NFT types (`Crucibles` and `QuantumFragments`). While the ERC721 implementation is only inherited for Crucibles for simplicity in this single-file example, the intention (and better practice) is that Quantum Fragments would be a separate ERC721 contract, and this Forge contract interacts with it via an interface (`IQuantumFragmentNFT`). The current code simulates Fragment data tracking (`_fragments` mapping) and ownership (`_fragmentOwners`) internally for demonstration purposes, but the functions (`combineFragments`, `dissolveFragment`, `catalyzeGlobalState`) include calls to the assumed external `fragmentNFTContract`.
7.  **Parameterization:** `setSynthesisParameters` allows the admin to tune the core economic and probabilistic aspects of the system per Crucible level, enabling balancing and evolution of the game/protocol. User-provided parameters (`_userParam1`, `_userParam2` in `initiateSynthesis`) allow for player input influencing the generation algorithm (though the current implementation primarily uses them in the recipe hash).
8.  **Gas Considerations:** Complex calculations, especially property generation, happen during `finalizeSynthesis`. While this function is called externally, it's a single transaction per synthesis completion. View functions are computationally lighter. The dynamic state updates and drift calculations are relatively simple arithmetic.
9.  **Error Handling:** Uses custom errors for better gas efficiency and clarity in Solidity 0.8.4+.

This contract goes beyond standard token or NFT implementations by introducing dynamic state, algorithmic generation tied to that state, and circular utility loops where generated assets feed back into the system. Remember that for production use, the randomness source needs to be secure, and managing two distinct NFT collections (Crucibles and Fragments) is best done with two separate ERC721 contracts interacting via interfaces.