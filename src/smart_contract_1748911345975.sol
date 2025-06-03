Okay, here is a Solidity smart contract incorporating several advanced and creative concepts beyond typical ERC-721 or DeFi patterns. This contract, "QuantumChronicles," simulates a universe where unique digital entities ("Chronicles") can evolve, synthesize, undertake challenges, gain aspects, and interact with temporal and dimensional concepts, influenced by changing "Epochs."

It uses:
*   **State Evolution:** Chronicles change properties over time and interaction.
*   **Resource Management:** An internal 'Essence' token is required for actions.
*   **Aspects:** Non-transferable traits attached to NFTs, influencing capabilities.
*   **Recipe-Based Synthesis:** Combining NFTs based on predefined (and governable) recipes.
*   **Epochs:** Global state changes influencing game rules and interactions.
*   **Challenges:** On-chain events with probabilistic outcomes (simulated via admin resolution for this example, could integrate VRF).
*   **Temporal Anchoring:** Recording a specific historical state block.
*   **Dimensional Shifting:** A rare, complex action with uncertain outcomes.
*   **Fragmentation/Reconstitution:** Dismantling NFTs into resources and potentially rebuilding.

---

**QuantumChronicles Smart Contract**

**Outline:**

1.  **Contract Information & SPDX License**
2.  **Imports (OpenZeppelin for ERC721Enumerable, Ownable)**
3.  **Events**
4.  **Error Handling**
5.  **Struct Definitions:**
    *   `Chronicle`: Represents the core NFT entity with dynamic properties.
    *   `Aspect`: Defines a potential trait a Chronicle can possess.
    *   `SynthesisRecipe`: Defines how Chronicles can be combined.
    *   `Challenge`: Defines a potential interaction/task for a Chronicle.
    *   `ActiveChallengeState`: Tracks an ongoing challenge instance.
    *   `EpochRules`: Defines parameters specific to an Epoch.
6.  **State Variables:**
    *   Mappings for Chronicles, Essence balances, registered Aspects, Synthesis Recipes, Challenges, Active Challenges, Epoch rules.
    *   Counters for token IDs, Aspect IDs, Recipe IDs, Challenge IDs.
    *   Current Epoch number.
    *   Admin addresses (using Ownable).
7.  **Constructor:** Initializes Epoch 0 and basic parameters.
8.  **Modifiers:** Access control (`onlyEpochAdmin`, etc.).
9.  **Internal/Helper Functions:**
    *   `_payEssence`: Handles Essence deduction.
    *   `_grantEssence`: Handles Essence addition.
    *   `_addAspectToChronicleInternal`: Adds an Aspect to a Chronicle's state.
    *   `_removeAspectFromChronicleInternal`: Removes an Aspect from a Chronicle's state.
10. **Core NFT Functions (Inherited from ERC721Enumerable):**
    *   `balanceOf`
    *   `ownerOf`
    *   `safeTransferFrom` (overloaded)
    *   `transferFrom`
    *   `approve`
    *   `setApprovalForAll`
    *   `getApproved`
    *   `isApprovedForAll`
    *   `tokenOfOwnerByIndex`
    *   `totalSupply`
    *   `tokenByIndex`
    *   `tokenURI`
    *   `supportsInterface`
11. **Chronicle Lifecycle & State Functions (Unique):**
    *   `mintChronicle`: Creates a new Chronicle NFT.
    *   `getChronicleDetails`: Retrieves full details of a Chronicle.
    *   `renameChronicle`: Allows owner to rename.
    *   `setChronicleMetadataURI`: Allows owner to update metadata URI.
    *   `evolveChronicle`: Triggers an evolution process based on current state/epoch.
    *   `fragmentChronicle`: Destroys a Chronicle for Essence/Aspects.
    *   `reconstituteChronicle`: Attempts to create a Chronicle from Essence/Aspects (probabilistic).
    *   `registerTemporalAnchor`: Records the block number as a historical anchor.
    *   `retrievePastChronicleState`: (View) Simulates fetching a Chronicle's state *as it was* at a temporal anchor (simplified implementation).
    *   `initiateDimensionalShift`: Attempts a rare, high-cost, uncertain state transformation.
    *   `getChronicleCoherence`: Gets a Chronicle's current coherence level.
12. **Aspect Functions:**
    *   `registerAspectType`: Admin registers a new Aspect type.
    *   `getAspectDetails`: View details of a registered Aspect type.
    *   `getChronicleAspects`: Lists all Aspects a Chronicle possesses.
    *   `hasAspect`: Checks if a Chronicle has a specific Aspect.
13. **Essence Functions (Internal Token):**
    *   `getEssenceBalance`: Checks a user's Essence balance.
    *   `distributeEssence`: Admin distributes Essence.
    *   `burnEssence`: Admin burns Essence.
14. **Synthesis Functions:**
    *   `proposeSynthesisRecipe`: Admin proposes a new recipe.
    *   `approveSynthesisRecipe`: Admin approves a proposed recipe.
    *   `getSynthesisRecipes`: View all active Synthesis recipes.
    *   `synthesizeChronicles`: Executes a synthesis recipe, consuming inputs and producing output/rewards.
    *   `queryPotentialSynthesizeOutcome`: (View) Predicts the outcome of a synthesis without execution (simplified).
15. **Challenge Functions:**
    *   `registerChallengeType`: Admin registers a new Challenge type.
    *   `getChallengeDetails`: View details of a registered Challenge type.
    *   `initiateChallenge`: Owner starts a Challenge for a Chronicle.
    *   `resolveChallenge`: Admin resolves a pending Challenge (simulated outcome).
    *   `getActiveChallenge`: View the state of an active challenge for a Chronicle.
16. **Epoch & Rule Functions:**
    *   `advanceEpoch`: Admin moves the contract to the next Epoch.
    *   `getCurrentEpoch`: View the current Epoch number.
    *   `setEpochRules`: Admin sets/updates rules for a specific Epoch.
    *   `getEpochRules`: View rules for a specific Epoch.
17. **Admin Functions (Using Ownable):**
    *   `setEpochAdmin`: Grant/revoke Epoch admin role (can set epoch rules, advance epoch, resolve challenges).
    *   `getEpochAdmin`: Check if an address is an Epoch admin. (Or just use the base `owner` role for simplicity if preferred, but adding a specific role is more advanced). Let's use `onlyOwner` for simplicity unless a dedicated admin structure is requested. Sticking with `onlyOwner` for now, but mention the possibility of dedicated roles. Let's make a dedicated role `epochAdmin` controlled by `owner`.
    *   Other admin functions integrated into other sections (registering types, approving recipes, resolving challenges).

**Function Summary:**

*   `constructor()`: Initializes contract state, including Epoch 0.
*   `mintChronicle(address to, string memory name, string memory metadataURI)`: Creates and assigns a new Chronicle NFT to an address.
*   `getChronicleDetails(uint256 chronicleId)`: Retrieves the comprehensive state (name, owner, epoch data, coherence, aspects, anchor) of a Chronicle.
*   `renameChronicle(uint256 chronicleId, string memory newName)`: Allows the owner to change their Chronicle's name (potentially requires Essence).
*   `setChronicleMetadataURI(uint256 chronicleId, string memory newURI)`: Allows the owner to update their Chronicle's metadata URI.
*   `evolveChronicle(uint256 chronicleId)`: Triggers an internal process for a Chronicle to evolve, potentially altering its state based on Epoch, Aspects, or other factors (requires Essence).
*   `fragmentChronicle(uint256 chronicleId)`: Burns a Chronicle NFT, awarding the owner Essence and potentially specific Aspects based on the Chronicle's traits.
*   `reconstituteChronicle(uint256[] memory aspectsToUse, uint256 essenceToUse)`: Attempts to create a new Chronicle NFT by consuming Essence and specific Aspects (probabilistic success).
*   `registerTemporalAnchor(uint256 chronicleId)`: Records the current block number associated with a Chronicle's state, allowing for potential historical queries (requires Essence).
*   `retrievePastChronicleState(uint256 chronicleId)`: (View) Simulates retrieving details of a Chronicle as they were when `registerTemporalAnchor` was last called (simplified implementation showing concept).
*   `initiateDimensionalShift(uint256 chronicleId)`: Attempts a complex, high-risk transformation on a Chronicle, potentially granting unique Aspects or changing its core type (requires high Essence, probabilistic, can fail).
*   `getChronicleCoherence(uint256 chronicleId)`: (View) Returns the current "coherence" level of a Chronicle, influencing success rates of actions.
*   `registerAspectType(uint256 aspectId, string memory name, string memory description, uint8 aspectType)`: (Admin) Defines a new type of Aspect that can be added to Chronicles.
*   `getAspectDetails(uint256 aspectId)`: (View) Retrieves the definition of a registered Aspect type.
*   `getChronicleAspects(uint256 chronicleId)`: (View) Lists the IDs of all Aspects currently held by a specific Chronicle.
*   `hasAspect(uint256 chronicleId, uint256 aspectId)`: (View) Checks if a Chronicle possesses a specific Aspect.
*   `getEssenceBalance(address account)`: (View) Returns the Essence balance for a given address.
*   `distributeEssence(address[] memory accounts, uint256[] memory amounts)`: (Admin) Mints and distributes Essence to multiple accounts.
*   `burnEssence(address account, uint256 amount)`: (Admin) Burns Essence from an account.
*   `proposeSynthesisRecipe(uint256 input1Type, uint256 input2Type, uint256 requiredEssence, uint256 outputChronicleType, uint256[] memory grantedAspects)`: (Admin) Creates a new Synthesis Recipe in a pending state.
*   `approveSynthesisRecipe(uint256 recipeId)`: (Admin) Activates a proposed Synthesis Recipe.
*   `getSynthesisRecipes()`: (View) Lists all currently active Synthesis Recipes.
*   `synthesizeChronicles(uint256 chronicleId1, uint256 chronicleId2, uint256 recipeId)`: Executes a Synthesis Recipe using two input Chronicles, consuming them and generating output/rewards (requires Essence, checks recipe conditions).
*   `queryPotentialSynthesizeOutcome(uint256 chronicleId1, uint256 chronicleId2)`: (View) Analyzes two Chronicles and potential recipes to indicate possible synthesis outcomes without execution (simplified probabilistic check).
*   `registerChallengeType(uint256 challengeId, string memory name, string memory description, uint256 requiredEssence, uint256 requiredCoherence, uint256 successEssenceReward, uint256[] memory successAspectRewards, uint256 failurePenaltyEssence, uint256 failurePenaltyCoherence)`: (Admin) Defines a new type of Challenge.
*   `getChallengeDetails(uint256 challengeId)`: (View) Retrieves the definition of a registered Challenge type.
*   `initiateChallenge(uint256 chronicleId, uint256 challengeId)`: Allows the owner to start a specific Challenge for their Chronicle (requires Essence, checks Chronicle state).
*   `resolveChallenge(uint256 chronicleId, uint256 challengeId, bool success)`: (Epoch Admin) Determines the outcome of a pending Challenge for a Chronicle, applying rewards or penalties.
*   `getActiveChallenge(uint256 chronicleId)`: (View) Returns the state of any currently active Challenge for a Chronicle.
*   `advanceEpoch()`: (Epoch Admin) Increments the contract's global Epoch counter, potentially altering game dynamics.
*   `getCurrentEpoch()`: (View) Returns the current global Epoch number.
*   `setEpochRules(uint64 epoch, uint256 evolutionEssenceCost, uint256 synthesisBaseEssenceCost, uint256 challengeBaseEssenceCost, uint256 temporalAnchorCost, uint256 dimensionalShiftCost)`: (Epoch Admin) Configures specific rule parameters for a given Epoch.
*   `getEpochRules(uint64 epoch)`: (View) Retrieves the rules set for a specific Epoch.
*   `setEpochAdmin(address admin, bool isEpochAdmin)`: (Owner) Grants or revokes the Epoch Admin role.
*   `isEpochAdmin(address account)`: (View) Checks if an address has the Epoch Admin role.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ handles overflow, explicit use can clarify intent for critical ops.
import "@openzeppelin/contracts/utils/Arrays.sol"; // For array checks

// --- QuantumChronicles Smart Contract ---
//
// Outline:
// 1. Contract Information & SPDX License
// 2. Imports (OpenZeppelin for ERC721Enumerable, Ownable)
// 3. Events
// 4. Error Handling
// 5. Struct Definitions: Chronicle, Aspect, SynthesisRecipe, Challenge, ActiveChallengeState, EpochRules
// 6. State Variables: Mappings, Counters, Epoch data, Admin roles
// 7. Constructor
// 8. Modifiers: Access control (onlyEpochAdmin)
// 9. Internal/Helper Functions: Essence management, Aspect management
// 10. Core NFT Functions (Inherited from ERC721Enumerable - not explicitly listed in summary but present)
// 11. Chronicle Lifecycle & State Functions (Unique): mint, getDetails, rename, setURI, evolve, fragment, reconstitute, temporalAnchor, retrievePastState (simulated), dimensionalShift, getCoherence
// 12. Aspect Functions: registerType, getDetails, getChronicleAspects, hasAspect
// 13. Essence Functions (Internal Token): getBalance, distribute, burn
// 14. Synthesis Functions: proposeRecipe, approveRecipe, getRecipes, synthesize, queryPotentialOutcome (simulated)
// 15. Challenge Functions: registerType, getDetails, initiate, resolve, getActiveChallenge
// 16. Epoch & Rule Functions: advance, getCurrent, setRules, getRules
// 17. Admin Functions (Using Ownable + custom role): setEpochAdmin, isEpochAdmin
//
// Function Summary:
// constructor()
// mintChronicle(address to, string memory name, string memory metadataURI)
// getChronicleDetails(uint256 chronicleId)
// renameChronicle(uint256 chronicleId, string memory newName)
// setChronicleMetadataURI(uint256 chronicleId, string memory newURI)
// evolveChronicle(uint256 chronicleId)
// fragmentChronicle(uint256 chronicleId)
// reconstituteChronicle(uint256[] memory aspectsToUse, uint256 essenceToUse)
// registerTemporalAnchor(uint256 chronicleId)
// retrievePastChronicleState(uint256 chronicleId) - View (Simulated)
// initiateDimensionalShift(uint256 chronicleId)
// getChronicleCoherence(uint256 chronicleId) - View
// registerAspectType(uint256 aspectId, string memory name, string memory description, uint8 aspectType) - Admin
// getAspectDetails(uint256 aspectId) - View
// getChronicleAspects(uint256 chronicleId) - View
// hasAspect(uint256 chronicleId, uint256 aspectId) - View
// getEssenceBalance(address account) - View
// distributeEssence(address[] memory accounts, uint256[] memory amounts) - Admin
// burnEssence(address account, uint256 amount) - Admin
// proposeSynthesisRecipe(uint256 input1Type, uint256 input2Type, uint256 requiredEssence, uint256 outputChronicleType, uint256[] memory grantedAspects) - Admin
// approveSynthesisRecipe(uint256 recipeId) - Admin
// getSynthesisRecipes() - View
// synthesizeChronicles(uint256 chronicleId1, uint256 chronicleId2, uint256 recipeId)
// queryPotentialSynthesizeOutcome(uint256 chronicleId1, uint256 chronicleId2) - View (Simulated)
// registerChallengeType(uint256 challengeId, string memory name, string memory description, uint256 requiredEssence, uint256 requiredCoherence, uint256 successEssenceReward, uint256[] memory successAspectRewards, uint256 failurePenaltyEssence, uint256 failurePenaltyCoherence) - Admin
// getChallengeDetails(uint256 challengeId) - View
// initiateChallenge(uint256 chronicleId, uint256 challengeId)
// resolveChallenge(uint256 chronicleId, uint256 challengeId, bool success) - Epoch Admin
// getActiveChallenge(uint256 chronicleId) - View
// advanceEpoch() - Epoch Admin
// getCurrentEpoch() - View
// setEpochRules(uint64 epoch, uint256 evolutionEssenceCost, uint256 synthesisBaseEssenceCost, uint256 challengeBaseEssenceCost, uint256 temporalAnchorCost, uint256 dimensionalShiftCost) - Epoch Admin
// getEpochRules(uint64 epoch) - View
// setEpochAdmin(address admin, bool isEpochAdmin) - Owner
// isEpochAdmin(address account) - View

contract QuantumChronicles is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Events ---
    event ChronicleMinted(uint256 indexed chronicleId, address indexed owner, string name, uint64 mintEpoch);
    event ChronicleRenamed(uint256 indexed chronicleId, string newName);
    event ChronicleMetadataUpdated(uint256 indexed chronicleId, string newURI);
    event ChronicleEvolved(uint256 indexed chronicleId, uint64 currentEpoch);
    event ChronicleFragmented(uint256 indexed chronicleId, address indexed owner, uint256 essenceReturned);
    event ChronicleReconstituted(uint256 indexed newChronicleId, address indexed owner, uint256 essenceUsed);
    event TemporalAnchorRegistered(uint256 indexed chronicleId, uint256 blockNumber);
    event DimensionalShiftInitiated(uint256 indexed chronicleId, bool success);
    event AspectRegistered(uint256 indexed aspectId, string name);
    event AspectAddedToChronicle(uint256 indexed chronicleId, uint256 indexed aspectId);
    event AspectRemovedFromChronicle(uint256 indexed chronicleId, uint256 indexed aspectId);
    event EssenceDistributed(address[] accounts, uint256[] amounts);
    event EssenceBurned(address indexed account, uint256 amount);
    event SynthesisRecipeProposed(uint256 indexed recipeId, uint256 input1Type, uint256 input2Type);
    event SynthesisRecipeApproved(uint256 indexed recipeId);
    event SynthesisCompleted(uint256 indexed outputChronicleId, uint256 indexed inputChronicleId1, uint256 indexed inputChronicleId2, uint256 indexed recipeId);
    event ChallengeTypeRegistered(uint256 indexed challengeId, string name);
    event ChallengeInitiated(uint256 indexed chronicleId, uint256 indexed challengeId);
    event ChallengeResolved(uint256 indexed chronicleId, uint256 indexed challengeId, bool success);
    event EpochAdvanced(uint64 newEpoch);
    event EpochRulesSet(uint64 epoch);
    event EpochAdminSet(address indexed account, bool isAdmin);

    // --- Error Handling ---
    error ChronicleNotFound(uint256 chronicleId);
    error NotChronicleOwner(uint256 chronicleId, address caller);
    error InsufficientEssence(address account, uint256 required, uint256 available);
    error AspectNotFound(uint256 aspectId);
    error AspectAlreadyPresent(uint256 chronicleId, uint256 aspectId);
    error AspectNotPresent(uint256 chronicleId, uint256 aspectId);
    error RecipeNotFound(uint256 recipeId);
    error RecipeNotActive(uint256 recipeId);
    error InvalidSynthesisInputs(uint256 chronicleId1, uint256 chronicleId2); // Simplified error
    error ChallengeNotFound(uint256 challengeId);
    error ChallengeAlreadyActive(uint256 chronicleId, uint256 challengeId);
    error ChallengeNotActive(uint256 chronicleId, uint256 challengeId);
    error NotEpochAdmin(address caller);
    error SynthesisRequiresTwoChronicles();
    error FragmentationRequiresChronicle();
    error ReconstitutionFailed();
    error NoTemporalAnchorSet(uint256 chronicleId);
    error InvalidEpoch(uint64 epoch);

    // --- Struct Definitions ---

    struct Chronicle {
        string name;
        string metadataURI;
        address owner; // Stored here for quick lookup, canonical owner is via ERC721
        uint64 mintEpoch;
        uint64 currentEpoch; // Represents the epoch they last significantly interacted or evolved
        uint256 coherenceLevel; // A metric affecting success probabilities
        uint256[] aspects; // List of Aspect IDs the Chronicle possesses
        uint256 temporalAnchorBlock; // Block number for temporal anchoring
        // Add type identifier if needed for synthesis/challenges:
        // uint256 chronicleType;
    }

    struct Aspect {
        string name;
        string description;
        uint8 aspectType; // Categorization (e.g., 1=Elemental, 2=Temporal, 3=Skill)
        bool isTransferable; // Can this aspect be transferred/fragmented? (Conceptual, not fully implemented transfer)
    }

    struct SynthesisRecipe {
        uint256 recipeId; // Redundant but helpful
        uint256 inputChronicle1Type; // 0 for any type, otherwise specific type ID
        uint256 inputChronicle2Type; // 0 for any type, otherwise specific type ID
        uint256 requiredEssence;
        uint256 outputChronicleType; // 0 for random or type derived from inputs, otherwise specific type ID
        uint256[] grantedAspects; // Aspects added to the output Chronicle
        bool isActive; // Must be approved by admin
    }

    struct Challenge {
        uint256 challengeId; // Redundant but helpful
        string name;
        string description;
        uint256 requiredEssence;
        uint256 requiredCoherence; // Minimum coherence required to attempt
        uint256 successEssenceReward;
        uint256[] successAspectRewards;
        uint256 failurePenaltyEssence;
        uint256 failurePenaltyCoherence;
    }

    struct ActiveChallengeState {
        uint256 challengeId;
        uint256 chronicleId;
        uint64 initiatedEpoch;
        uint64 resolutionEpoch; // Epoch when it *can* be resolved
        bool isPending;
    }

    struct EpochRules {
        uint256 evolutionEssenceCost;
        uint256 synthesisBaseEssenceCost;
        uint256 challengeBaseEssenceCost;
        uint256 temporalAnchorCost;
        uint256 dimensionalShiftCost;
        // Add other epoch-specific parameters here
        bool exists; // To check if rules for an epoch have been set
    }

    // --- State Variables ---

    Counters.Counter private _chronicleIds;
    mapping(uint256 => Chronicle) private _chronicles;
    mapping(address => uint256) private _essenceBalances;

    Counters.Counter private _aspectTypeIds;
    mapping(uint256 => Aspect) private _aspectTypes;

    Counters.Counter private _recipeIds;
    mapping(uint256 => SynthesisRecipe) private _synthesisRecipes;

    Counters.Counter private _challengeIds;
    mapping(uint256 => Challenge) private _challengeTypes;
    mapping(uint256 => ActiveChallengeState) private _activeChallenges; // chronicleId => ActiveChallengeState

    uint64 private _currentEpoch;
    mapping(uint64 => EpochRules) private _epochRules;

    mapping(address => bool) private _isEpochAdmin;

    // --- Constructor ---

    constructor() ERC721Enumerable("Quantum Chronicles", "QCHR") Ownable(msg.sender) {
        _currentEpoch = 0;
        // Set initial rules for Epoch 0
        _epochRules[0] = EpochRules({
            evolutionEssenceCost: 100,
            synthesisBaseEssenceCost: 200,
            challengeBaseEssenceCost: 50,
            temporalAnchorCost: 150,
            dimensionalShiftCost: 1000,
            exists: true
        });
        _isEpochAdmin[msg.sender] = true; // Owner is also Epoch Admin initially
    }

    // --- Modifiers ---

    modifier onlyEpochAdmin() {
        if (!_isEpochAdmin[msg.sender] && msg.sender != owner()) {
             revert NotEpochAdmin(msg.sender);
        }
        _;
    }

    modifier onlyChronicleOwner(uint256 chronicleId) {
        if (_chronicles[chronicleId].owner != msg.sender) {
             revert NotChronicleOwner(chronicleId, msg.sender);
        }
        _;
    }

    // --- Internal/Helper Functions ---

    function _payEssence(address account, uint256 amount) internal {
        if (_essenceBalances[account] < amount) {
            revert InsufficientEssence(account, amount, _essenceBalances[account]);
        }
        _essenceBalances[account] = _essenceBalances[account].sub(amount);
    }

    function _grantEssence(address account, uint256 amount) internal {
        _essenceBalances[account] = _essenceBalances[account].add(amount);
    }

    function _addAspectToChronicleInternal(uint256 chronicleId, uint256 aspectId) internal {
        for (uint i = 0; i < _chronicles[chronicleId].aspects.length; i++) {
            if (_chronicles[chronicleId].aspects[i] == aspectId) {
                revert AspectAlreadyPresent(chronicleId, aspectId);
            }
        }
        _chronicles[chronicleId].aspects.push(aspectId);
        emit AspectAddedToChronicle(chronicleId, aspectId);
    }

    function _removeAspectFromChronicleInternal(uint256 chronicleId, uint256 aspectId) internal {
         uint256 aspectIndex = type(uint256).max;
         for (uint i = 0; i < _chronicles[chronicleId].aspects.length; i++) {
             if (_chronicles[chronicleId].aspects[i] == aspectId) {
                 aspectIndex = i;
                 break;
             }
         }

         if (aspectIndex == type(uint256).max) {
             revert AspectNotPresent(chronicleId, aspectId);
         }

         // Replace the aspect to remove with the last aspect
         _chronicles[chronicleId].aspects[aspectIndex] = _chronicles[chronicleId].aspects[_chronicles[chronicleId].aspects.length - 1];
         // Remove the last element
         _chronicles[chronicleId].aspects.pop();

         emit AspectRemovedFromChronicle(chronicleId, aspectId);
     }

    // --- Core NFT Functions (Inherited ERC721Enumerable) ---
    // These are standard and provided by OpenZeppelin.
    // balanceOf(address owner) view returns (uint256)
    // ownerOf(uint256 tokenId) view returns (address)
    // safeTransferFrom(address from, address to, uint256 tokenId, bytes data) payable
    // safeTransferFrom(address from, address to, uint256 tokenId) payable
    // transferFrom(address from, address to, uint256 tokenId) payable
    // approve(address to, uint256 tokenId) payable
    // setApprovalForAll(address operator, bool approved)
    // getApproved(uint256 tokenId) view returns (address)
    // isApprovedForAll(address owner, address operator) view returns (bool)
    // tokenOfOwnerByIndex(address owner, uint256 index) view returns (uint256)
    // totalSupply() view returns (uint256)
    // tokenByIndex(uint256 index) view returns (uint256)
    // tokenURI(uint256 tokenId) view returns (string memory)
    // supportsInterface(bytes4 interfaceId) view returns (bool)

    // Override _beforeTokenTransfer to update Chronicle owner mapping
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from == address(0)) {
            // Minting - owner is set during mintChronicle
        } else if (to == address(0)) {
            // Burning - Remove from mapping
             delete _chronicles[tokenId].owner;
        } else {
             // Transferring
            _chronicles[tokenId].owner = to;
        }
    }


    // --- Chronicle Lifecycle & State Functions (Unique) ---

    /// @notice Creates a new Chronicle NFT.
    /// @param to The address to mint the Chronicle to.
    /// @param name The initial name of the Chronicle.
    /// @param metadataURI The initial metadata URI for the Chronicle.
    /// @return The ID of the newly minted Chronicle.
    function mintChronicle(address to, string memory name, string memory metadataURI) public onlyOwner returns (uint256) {
        _chronicleIds.increment();
        uint256 newId = _chronicleIds.current();

        _chronicles[newId] = Chronicle({
            name: name,
            metadataURI: metadataURI,
            owner: to, // Will be updated by _beforeTokenTransfer
            mintEpoch: _currentEpoch,
            currentEpoch: _currentEpoch,
            coherenceLevel: 100, // Initial coherence
            aspects: new uint256[](0),
            temporalAnchorBlock: 0
            // chronicleType: 1 // Example initial type
        });

        _safeMint(to, newId);

        emit ChronicleMinted(newId, to, name, _currentEpoch);
        return newId;
    }

    /// @notice Retrieves the detailed state of a Chronicle.
    /// @param chronicleId The ID of the Chronicle.
    /// @return Chronicle struct containing all details.
    function getChronicleDetails(uint256 chronicleId) public view returns (Chronicle memory) {
        _requireChronicleExists(chronicleId);
        return _chronicles[chronicleId];
    }

    /// @notice Allows the owner to rename their Chronicle.
    /// @param chronicleId The ID of the Chronicle.
    /// @param newName The new name for the Chronicle.
    function renameChronicle(uint256 chronicleId, string memory newName) public onlyChronicleOwner(chronicleId) {
        _requireChronicleExists(chronicleId);
        // require(bytes(newName).length > 0, "Name cannot be empty"); // Basic validation

        // Optional: Require Essence cost
        // uint256 cost = 50; // Example cost
        // _payEssence(msg.sender, cost);

        _chronicles[chronicleId].name = newName;
        emit ChronicleRenamed(chronicleId, newName);
    }

    /// @notice Allows the owner to update their Chronicle's metadata URI.
    /// @param chronicleId The ID of the Chronicle.
    /// @param newURI The new metadata URI.
    function setChronicleMetadataURI(uint256 chronicleId, string memory newURI) public onlyChronicleOwner(chronicleId) {
        _requireChronicleExists(chronicleId);
        _chronicles[chronicleId].metadataURI = newURI;
        emit ChronicleMetadataUpdated(chronicleId, newURI);
    }

    /// @notice Triggers an evolutionary step for a Chronicle based on current conditions.
    /// @dev This function's effects would depend on Epoch rules, Aspects, Coherence, etc.
    /// @param chronicleId The ID of the Chronicle to evolve.
    function evolveChronicle(uint256 chronicleId) public onlyChronicleOwner(chronicleId) {
        _requireChronicleExists(chronicleId);
        EpochRules storage rules = _getEpochRules(_currentEpoch);
        _payEssence(msg.sender, rules.evolutionEssenceCost);

        // --- Evolution Logic (Simplified Example) ---
        // Based on epoch, aspects, coherence, etc., modify the chronicle state.
        // e.g., Increase coherence, add/remove aspects, change 'currentEpoch' state, maybe even 'chronicleType'

        _chronicles[chronicleId].currentEpoch = _currentEpoch; // Update last active epoch state
        _chronicles[chronicleId].coherenceLevel = _chronicles[chronicleId].coherenceLevel.add(5).min(200); // Example: Coherence increases slightly

        // Example: Grant a specific aspect based on current epoch if not already present
        uint256 epochAspectId = _currentEpoch + 1000; // Placeholder for epoch-specific aspect
        // In a real scenario, you'd map epoch to specific aspect IDs
        // if (!_aspectTypes[epochAspectId].exists) { register it first or handle }
        // if (!hasAspect(chronicleId, epochAspectId)) {
        //     _addAspectToChronicleInternal(chronicleId, epochAspectId);
        // }
        // --- End Evolution Logic ---

        emit ChronicleEvolved(chronicleId, _currentEpoch);
    }

    /// @notice Destroys a Chronicle NFT, returning Essence and certain Aspects.
    /// @param chronicleId The ID of the Chronicle to fragment.
    function fragmentChronicle(uint256 chronicleId) public onlyChronicleOwner(chronicleId) {
        _requireChronicleExists(chronicleId);
        address ownerAddress = _chronicles[chronicleId].owner; // Use stored owner for fragmentation logic
        uint256 essenceReturn = _chronicles[chronicleId].coherenceLevel.mul(10); // Example: return essence based on coherence

        // Example: Grant specific aspects back based on aspectType or other logic
        // for (uint256 aspectId : _chronicles[chronicleId].aspects) {
        //    if (_aspectTypes[aspectId].isTransferable) { // Conceptual check
        //        // Grant the aspect back to the user somehow (e.g., as a separate token, or increase a counter)
        //        // For this example, we'll just grant Essence and potentially remove some aspects
        //    }
        // }

        // Simplified: Remove all aspects upon fragmentation
         _chronicles[chronicleId].aspects = new uint256[](0);

        _grantEssence(ownerAddress, essenceReturn);
        _burn(chronicleId); // Burns the NFT, also clears the chronicle mapping entry via _beforeTokenTransfer

        emit ChronicleFragmented(chronicleId, ownerAddress, essenceReturn);
    }

    /// @notice Attempts to create a new Chronicle from Essence and collected Aspects.
    /// @dev This is a probabilistic function. Success and output depend on inputs and potentially Epoch.
    /// @param aspectsToUse Array of Aspect IDs to consume in the reconstitution attempt.
    /// @param essenceToUse Amount of Essence to consume.
    /// @return The ID of the newly created Chronicle if successful, otherwise 0.
    function reconstituteChronicle(uint256[] memory aspectsToUse, uint256 essenceToUse) public returns (uint256) {
        // This is a highly conceptual function. A real implementation would need a complex
        // probability model, potential use of Chainlink VRF for randomness,
        // and defined outcomes based on the specific aspects and essence used.

        _payEssence(msg.sender, essenceToUse);

        // Example logic:
        // 1. Validate aspectsToUse (ensure user possesses them - would need a user_aspects mapping)
        // 2. Consume aspects (remove from user_aspects mapping)
        // 3. Calculate success chance based on essenceToUse, aspectsToUse, current epoch, etc.
        // 4. Use VRF or other randomness source (or simplified admin resolution) to determine success.

        bool success = essenceToUse >= 500 && aspectsToUse.length >= 2; // Very simplified success condition

        if (success) {
             // Example: Determine output Chronicle type/properties based on consumed aspects
             // uint256 newChronicleType = _determineReconstitutionOutcome(aspectsToUse);

             _chronicleIds.increment();
             uint256 newId = _chronicleIds.current();

            _chronicles[newId] = Chronicle({
                 name: "Reconstituted Chronicle", // Or generated name
                 metadataURI: "", // Or generated URI
                 owner: msg.sender,
                 mintEpoch: _currentEpoch,
                 currentEpoch: _currentEpoch,
                 coherenceLevel: 80, // Example initial coherence
                 aspects: new uint256[](0), // Start with no aspects, or grant specific ones based on outcome
                 temporalAnchorBlock: 0
                 // chronicleType: newChronicleType
             });

             // Grant initial aspects based on outcome or consumed aspects
             // for (uint256 aspectId : _getAspectsFromReconstitution(aspectsToUse)) {
             //     _addAspectToChronicleInternal(newId, aspectId);
             // }

            _safeMint(msg.sender, newId);
            emit ChronicleReconstituted(newId, msg.sender, essenceToUse);
             return newId;
        } else {
            // Handle failure: Maybe partial Essence return, or grant failure aspects
            // _grantEssence(msg.sender, essenceToUse / 2); // Example partial refund
            revert ReconstitutionFailed(); // Simplest failure handling
        }
    }

    /// @notice Records the current block number as a historical anchor for a Chronicle.
    /// @dev This allows querying the Chronicle's state *as it was* at this block number.
    ///      (Note: `retrievePastChronicleState` is a simplified simulation).
    /// @param chronicleId The ID of the Chronicle.
    function registerTemporalAnchor(uint256 chronicleId) public onlyChronicleOwner(chronicleId) {
        _requireChronicleExists(chronicleId);
        EpochRules storage rules = _getEpochRules(_currentEpoch);
        _payEssence(msg.sender, rules.temporalAnchorCost);

        _chronicles[chronicleId].temporalAnchorBlock = block.number;
        emit TemporalAnchorRegistered(chronicleId, block.number);
    }

    /// @notice Simulates retrieving the state of a Chronicle as it was at its last temporal anchor.
    /// @dev IMPORTANT: This is a simplified simulation. Retrieving complex historical state
    ///      on-chain is difficult and gas-prohibitive. A real implementation would likely
    ///      require off-chain indexing or state snapshots recorded on-chain at anchors.
    /// @param chronicleId The ID of the Chronicle.
    /// @return Chronicle struct representing the state at the anchor block.
    function retrievePastChronicleState(uint256 chronicleId) public view returns (Chronicle memory) {
        _requireChronicleExists(chronicleId);
        uint256 anchorBlock = _chronicles[chronicleId].temporalAnchorBlock;

        if (anchorBlock == 0) {
            revert NoTemporalAnchorSet(chronicleId);
        }

        // --- Simplified Simulation ---
        // In a real dApp, you would use an archive node or off-chain indexer
        // to query the actual contract state at the historical block number.
        // For the contract itself, we can only return the *current* state,
        // perhaps with a flag indicating it's a "simulated" historical view.
        // Or, we could store key state snapshots alongside the anchor block.

        Chronicle memory currentState = _chronicles[chronicleId];
        // Pretend this is the state from `anchorBlock`
        // In reality, currentState *is* the state at block.number
        // To make it slightly more illustrative of the *concept*, we can:
        Chronicle memory simulatedPastState = currentState;
        simulatedPastState.name = string.concat("Past(", currentState.name, ")");
        simulatedPastState.metadataURI = string.concat("past_uri/", currentState.metadataURI);
        simulatedPastState.currentEpoch = currentState.mintEpoch; // Simulate state before evolution
        simulatedPastState.coherenceLevel = 100; // Assume base coherence at mint/anchor
        // Aspects and other dynamic data would need historical storage
        // This simplified version just uses current aspects, which is incorrect for historical state
        // simulatedPastState.aspects = _getChronicleAspectsAtBlock(chronicleId, anchorBlock); // Conceptual function

        return simulatedPastState; // Returns current state, labeled as simulated past
    }

     /// @notice Attempts a complex, rare, high-cost transformation on a Chronicle.
     /// @dev This action is intended to be unpredictable, potentially granting unique
     ///      "Dimensional" aspects or significantly altering core properties. Probabilistic.
     /// @param chronicleId The ID of the Chronicle.
    function initiateDimensionalShift(uint256 chronicleId) public onlyChronicleOwner(chronicleId) {
         _requireChronicleExists(chronicleId);
         EpochRules storage rules = _getEpochRules(_currentEpoch);
         _payEssence(msg.sender, rules.dimensionalShiftCost);

         // --- Dimensional Shift Logic (Highly Simplified/Conceptual) ---
         // 1. Check pre-conditions (e.g., high coherence, specific aspects)
         // bool preconditionsMet = _chronicles[chronicleId].coherenceLevel >= 180 && hasAspect(chronicleId, 500); // Example

         // 2. Determine success probabilistically (would need VRF or similar)
         bool success = _chronicles[chronicleId].coherenceLevel > 150; // Simplified success chance based on coherence

         if (success) {
             // Apply success effects: Grant a unique dimensional aspect, boost stats, etc.
             uint256 dimensionalAspectId = 999; // Example Dimensional Aspect ID (must be registered)
             // if (!_aspectTypes[dimensionalAspectId].exists) { register it first or handle }
             // _addAspectToChronicleInternal(chronicleId, dimensionalAspectId);
             _chronicles[chronicleId].coherenceLevel = _chronicles[chronicleId].coherenceLevel.add(50).min(300); // Massive boost

             emit DimensionalShiftInitiated(chronicleId, true);

         } else {
             // Apply failure effects: Reduce coherence, remove aspects, penalty essence
             _chronicles[chronicleId].coherenceLevel = _chronicles[chronicleId].coherenceLevel.sub(30).max(10); // Significant penalty
             // _payEssence(msg.sender, rules.dimensionalShiftCost / 2); // Extra penalty
             // Remove a random aspect?

             emit DimensionalShiftInitiated(chronicleId, false);
         }
         // --- End Dimensional Shift Logic ---
    }

    /// @notice Gets the current coherence level of a Chronicle.
    /// @param chronicleId The ID of the Chronicle.
    /// @return The coherence level.
    function getChronicleCoherence(uint256 chronicleId) public view returns (uint256) {
        _requireChronicleExists(chronicleId);
        return _chronicles[chronicleId].coherenceLevel;
    }

    // --- Aspect Functions ---

    /// @notice Registers a new type of Aspect that can be added to Chronicles.
    /// @param aspectId The ID for the new Aspect type.
    /// @param name The name of the Aspect.
    /// @param description A description of the Aspect.
    /// @param aspectType Categorization type (e.g., 1=Elemental).
    /// @param isTransferable Can this aspect be involved in fragmentation/reconstitution?
    function registerAspectType(uint256 aspectId, string memory name, string memory description, uint8 aspectType, bool isTransferable) public onlyOwner {
         // Optional: Use _aspectTypeIds counter if you want auto-incrementing IDs
         // _aspectTypeIds.increment();
         // uint256 newId = _aspectTypeIds.current();
        require(!_aspectTypes[aspectId].name.length > 0, "Aspect ID already registered"); // Basic check

        _aspectTypes[aspectId] = Aspect({
            name: name,
            description: description,
            aspectType: aspectType,
            isTransferable: isTransferable
        });
        emit AspectRegistered(aspectId, name);
    }

    /// @notice Retrieves the details of a registered Aspect type.
    /// @param aspectId The ID of the Aspect type.
    /// @return Aspect struct containing details.
    function getAspectDetails(uint256 aspectId) public view returns (Aspect memory) {
        require(_aspectTypes[aspectId].name.length > 0, "Aspect type not found");
        return _aspectTypes[aspectId];
    }

    /// @notice Lists all Aspect IDs currently possessed by a Chronicle.
    /// @param chronicleId The ID of the Chronicle.
    /// @return An array of Aspect IDs.
    function getChronicleAspects(uint256 chronicleId) public view returns (uint256[] memory) {
        _requireChronicleExists(chronicleId);
        return _chronicles[chronicleId].aspects;
    }

    /// @notice Checks if a Chronicle possesses a specific Aspect.
    /// @param chronicleId The ID of the Chronicle.
    /// @param aspectId The ID of the Aspect.
    /// @return True if the Chronicle has the Aspect, false otherwise.
    function hasAspect(uint256 chronicleId, uint256 aspectId) public view returns (bool) {
        _requireChronicleExists(chronicleId);
        for (uint i = 0; i < _chronicles[chronicleId].aspects.length; i++) {
            if (_chronicles[chronicleId].aspects[i] == aspectId) {
                return true;
            }
        }
        return false;
    }

    // --- Essence Functions (Internal Token) ---

    /// @notice Gets the Essence balance for an account.
    /// @param account The address to query.
    /// @return The Essence balance.
    function getEssenceBalance(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    /// @notice Distributes Essence to multiple accounts.
    /// @dev Only callable by the contract owner.
    /// @param accounts Array of addresses to distribute to.
    /// @param amounts Array of amounts corresponding to each address. Must have same length.
    function distributeEssence(address[] memory accounts, uint256[] memory amounts) public onlyOwner {
        require(accounts.length == amounts.length, "Arrays must have same length");
        for (uint i = 0; i < accounts.length; i++) {
            _grantEssence(accounts[i], amounts[i]);
        }
        emit EssenceDistributed(accounts, amounts);
    }

    /// @notice Burns Essence from an account.
    /// @dev Only callable by the contract owner.
    /// @param account The address to burn from.
    /// @param amount The amount to burn.
    function burnEssence(address account, uint256 amount) public onlyOwner {
        _payEssence(account, amount); // _payEssence includes balance check
        emit EssenceBurned(account, amount);
    }


    // --- Synthesis Functions ---

    /// @notice Proposes a new Synthesis Recipe.
    /// @dev Recipes need to be approved by admin before being active.
    /// @param input1Type Required type for input Chronicle 1 (0 for any).
    /// @param input2Type Required type for input Chronicle 2 (0 for any).
    /// @param requiredEssence Essence cost for this synthesis.
    /// @param outputChronicleType Resulting Chronicle type (0 for random/derived).
    /// @param grantedAspects Aspects granted to the output Chronicle.
    /// @return The ID of the proposed recipe.
    function proposeSynthesisRecipe(uint256 input1Type, uint256 input2Type, uint256 requiredEssence, uint256 outputChronicleType, uint256[] memory grantedAspects) public onlyOwner returns (uint256) {
        _recipeIds.increment();
        uint256 newId = _recipeIds.current();

        _synthesisRecipes[newId] = SynthesisRecipe({
            recipeId: newId,
            inputChronicle1Type: input1Type,
            inputChronicle2Type: input2Type,
            requiredEssence: requiredEssence,
            outputChronicleType: outputChronicleType,
            grantedAspects: grantedAspects,
            isActive: false // Requires approval
        });
        emit SynthesisRecipeProposed(newId, input1Type, input2Type);
        return newId;
    }

    /// @notice Approves a proposed Synthesis Recipe, making it active.
    /// @param recipeId The ID of the recipe to approve.
    function approveSynthesisRecipe(uint256 recipeId) public onlyOwner {
        require(_synthesisRecipes[recipeId].recipeId != 0, "Recipe does not exist"); // Check if recipe was proposed
        require(!_synthesisRecipes[recipeId].isActive, "Recipe is already active");
        _synthesisRecipes[recipeId].isActive = true;
        emit SynthesisRecipeApproved(recipeId);
    }

    /// @notice Retrieves all currently active Synthesis Recipes.
    /// @return An array of active SynthesisRecipe structs.
    function getSynthesisRecipes() public view returns (SynthesisRecipe[] memory) {
        uint256 totalRecipes = _recipeIds.current();
        SynthesisRecipe[] memory activeRecipes = new SynthesisRecipe[](totalRecipes); // Max possible size
        uint256 count = 0;
        for (uint i = 1; i <= totalRecipes; i++) {
            if (_synthesisRecipes[i].isActive) {
                activeRecipes[count] = _synthesisRecipes[i];
                count++;
            }
        }
        // Resize the array to actual count
        SynthesisRecipe[] memory result = new SynthesisRecipe[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeRecipes[i];
        }
        return result;
    }

    /// @notice Executes a Synthesis Recipe, consuming two input Chronicles and creating/modifying an output.
    /// @param chronicleId1 The ID of the first input Chronicle.
    /// @param chronicleId2 The ID of the second input Chronicle.
    /// @param recipeId The ID of the active recipe to use.
    function synthesizeChronicles(uint256 chronicleId1, uint256 chronicleId2, uint256 recipeId) public {
        // Ensure the caller owns both chronicles
        _requireChronicleExists(chronicleId1);
        _requireChronicleExists(chronicleId2);
        if (ownerOf(chronicleId1) != msg.sender || ownerOf(chronicleId2) != msg.sender) {
             revert NotChronicleOwner(chronicleId1, msg.sender); // Or a more specific error
        }

        // Ensure recipe exists and is active
        SynthesisRecipe storage recipe = _synthesisRecipes[recipeId];
        if (recipe.recipeId == 0) revert RecipeNotFound(recipeId);
        if (!recipe.isActive) revert RecipeNotActive(recipeId);

        // Check input chronicle types match recipe (simplified - would need chronicleType field)
        // if (recipe.inputChronicle1Type != 0 && _chronicles[chronicleId1].chronicleType != recipe.inputChronicle1Type) revert InvalidSynthesisInputs(chronicleId1, chronicleId2);
        // if (recipe.inputChronicle2Type != 0 && _chronicles[chronicleId2].chronicleType != recipe.inputChronicle2Type) revert InvalidSynthesisInputs(chronicleId1, chronicleId2);

        // Pay Essence cost
        EpochRules storage rules = _getEpochRules(_currentEpoch);
        uint256 totalCost = recipe.requiredEssence.add(rules.synthesisBaseEssenceCost);
        _payEssence(msg.sender, totalCost);

        // --- Synthesis Logic ---
        // 1. Burn input chronicles
        _burn(chronicleId1); // _beforeTokenTransfer handles map cleanup
        _burn(chronicleId2);

        // 2. Create new output chronicle (or modify one of the inputs?)
        _chronicleIds.increment();
        uint256 outputId = _chronicleIds.current();

         _chronicles[outputId] = Chronicle({
              name: string.concat("Synthesized ", _chronicles[chronicleId1].name, "-", _chronicles[chronicleId2].name), // Or derived name
              metadataURI: "", // Or derived URI
              owner: msg.sender,
              mintEpoch: _currentEpoch,
              currentEpoch: _currentEpoch,
              coherenceLevel: 100, // Or calculated coherence
              aspects: new uint256[](0), // Start fresh or inherit/combine
              temporalAnchorBlock: 0
             // chronicleType: recipe.outputChronicleType == 0 ? _deriveOutputType(chronicleId1, chronicleId2) : recipe.outputChronicleType // Or derived type
          });

         // 3. Grant aspects from recipe
         for (uint i = 0; i < recipe.grantedAspects.length; i++) {
             _addAspectToChronicleInternal(outputId, recipe.grantedAspects[i]);
         }

         // 4. Mint output chronicle
         _safeMint(msg.sender, outputId);

        emit SynthesisCompleted(outputId, chronicleId1, chronicleId2, recipeId);
    }

    /// @notice Simulates predicting the outcome of a synthesis without executing it.
    /// @dev This is a view function and doesn't change state. A real implementation
    ///      might involve complex lookups based on Chronicle types and active recipes.
    /// @param chronicleId1 The ID of the first input Chronicle.
    /// @param chronicleId2 The ID of the second input Chronicle.
    /// @return An array of potential output Chronicle Type IDs (0 for any, or specific IDs).
    function queryPotentialSynthesizeOutcome(uint256 chronicleId1, uint256 chronicleId2) public view returns (uint256[] memory potentialOutputTypes) {
        _requireChronicleExists(chronicleId1);
        _requireChronicleExists(chronicleId2);
        // Note: This simplified version doesn't check ownership or essence cost, just potential recipes.

        SynthesisRecipe[] memory activeRecipes = getSynthesisRecipes();
        uint256[] memory possibleOutcomes = new uint256[](activeRecipes.length); // Max possible size
        uint256 count = 0;

        // Simplified check: Iterate active recipes and see if inputs *could* match
        // This would need to use the `chronicleType` field if implemented.
        // For now, just list outcomes of recipes that accept *any* type (0).
        for (uint i = 0; i < activeRecipes.length; i++) {
            bool inputsMatch = (activeRecipes[i].inputChronicle1Type == 0) && (activeRecipes[i].inputChronicle2Type == 0);
            // Add more complex matching logic if chronicleType exists:
            // bool inputsMatchSpecific = (activeRecipes[i].inputChronicle1Type == _chronicles[chronicleId1].chronicleType && activeRecipes[i].inputChronicle2Type == _chronicles[chronicleId2].chronicleType) || ... (handle order)
            // if (inputsMatch || inputsMatchSpecific) { ... }

            if (inputsMatch) { // Simplified: only check for 'any' type recipes
                 possibleOutcomes[count] = activeRecipes[i].outputChronicleType;
                 count++;
            }
        }

        // Resize the array to actual count
        potentialOutputTypes = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            potentialOutputTypes[i] = possibleOutcomes[i];
        }
        return potentialOutputTypes;
    }

    // --- Challenge Functions ---

    /// @notice Registers a new type of Challenge.
    /// @param challengeId The ID for the new Challenge type.
    /// @param name The name of the Challenge.
    /// @param description A description of the Challenge.
    /// @param requiredEssence Essence cost to initiate.
    /// @param requiredCoherence Minimum coherence needed to attempt.
    /// @param successEssenceReward Essence awarded on success.
    /// @param successAspectRewards Aspect IDs awarded on success.
    /// @param failurePenaltyEssence Essence lost on failure.
    /// @param failurePenaltyCoherence Coherence lost on failure.
    function registerChallengeType(uint256 challengeId, string memory name, string memory description, uint256 requiredEssence, uint256 requiredCoherence, uint256 successEssenceReward, uint256[] memory successAspectRewards, uint256 failurePenaltyEssence, uint256 failurePenaltyCoherence) public onlyOwner {
        // Optional: Use _challengeIds counter if you want auto-incrementing IDs
        // _challengeIds.increment();
        // uint256 newId = _challengeIds.current();
        require(!_challengeTypes[challengeId].name.length > 0, "Challenge ID already registered"); // Basic check

        _challengeTypes[challengeId] = Challenge({
            challengeId: challengeId,
            name: name,
            description: description,
            requiredEssence: requiredEssence,
            requiredCoherence: requiredCoherence,
            successEssenceReward: successEssenceReward,
            successAspectRewards: successAspectRewards,
            failurePenaltyEssence: failurePenaltyEssence,
            failurePenaltyCoherence: failurePenaltyCoherence
        });
        emit ChallengeTypeRegistered(challengeId, name);
    }

    /// @notice Retrieves the details of a registered Challenge type.
    /// @param challengeId The ID of the Challenge type.
    /// @return Challenge struct containing details.
    function getChallengeDetails(uint256 challengeId) public view returns (Challenge memory) {
        require(_challengeTypes[challengeId].name.length > 0, "Challenge type not found");
        return _challengeTypes[challengeId];
    }

    /// @notice Allows a Chronicle owner to initiate a Challenge.
    /// @dev The Challenge becomes 'pending' and needs admin resolution.
    /// @param chronicleId The ID of the Chronicle undertaking the Challenge.
    /// @param challengeId The ID of the Challenge type.
    function initiateChallenge(uint256 chronicleId, uint256 challengeId) public onlyChronicleOwner(chronicleId) {
        _requireChronicleExists(chronicleId);
        Challenge storage challenge = _challengeTypes[challengeId];
        if (challenge.challengeId == 0) revert ChallengeNotFound(challengeId);

        if (_activeChallenges[chronicleId].isPending) {
             revert ChallengeAlreadyActive(chronicleId, _activeChallenges[chronicleId].challengeId);
        }

        // Check requirements
        EpochRules storage rules = _getEpochRules(_currentEpoch);
        uint256 totalEssenceCost = challenge.requiredEssence.add(rules.challengeBaseEssenceCost);
        _payEssence(msg.sender, totalEssenceCost);

        if (_chronicles[chronicleId].coherenceLevel < challenge.requiredCoherence) {
             // Could revert, or make it a lower success chance. Reverting for simplicity.
             revert("Chronicle coherence too low for this challenge");
        }

        // Record active challenge state
        _activeChallenges[chronicleId] = ActiveChallengeState({
            challengeId: challengeId,
            chronicleId: chronicleId, // Redundant, but clear
            initiatedEpoch: _currentEpoch,
            resolutionEpoch: _currentEpoch.add(1), // Can be resolved in the next epoch or later
            isPending: true
        });

        emit ChallengeInitiated(chronicleId, challengeId);
    }

    /// @notice Resolves a pending Challenge for a Chronicle.
    /// @dev This function would ideally be called by an Oracle (like Chainlink VRF for randomness)
    ///      or a dedicated game backend. Here, it's an admin function for demonstration.
    /// @param chronicleId The ID of the Chronicle whose challenge is being resolved.
    /// @param success Whether the challenge was successful.
    function resolveChallenge(uint256 chronicleId, bool success) public onlyEpochAdmin {
        _requireChronicleExists(chronicleId);
        ActiveChallengeState storage activeState = _activeChallenges[chronicleId];

        if (!activeState.isPending) {
             revert ChallengeNotActive(chronicleId, 0); // 0 indicates no active challenge
        }
        // Optional: Check if resolutionEpoch has been reached
        // if (_currentEpoch < activeState.resolutionEpoch) revert("Challenge not yet ready for resolution");

        Challenge storage challenge = _challengeTypes[activeState.challengeId];
        if (challenge.challengeId == 0) revert ChallengeNotFound(activeState.challengeId); // Should not happen if activeState is valid

        address chronicleOwner = ownerOf(chronicleId); // Get current owner

        if (success) {
            // Apply success effects
            _grantEssence(chronicleOwner, challenge.successEssenceReward);
            for (uint i = 0; i < challenge.successAspectRewards.length; i++) {
                // Check if aspect type exists before adding
                if (_aspectTypes[challenge.successAspectRewards[i]].name.length > 0) {
                    _addAspectToChronicleInternal(chronicleId, challenge.successAspectRewards[i]);
                }
            }
            _chronicles[chronicleId].coherenceLevel = _chronicles[chronicleId].coherenceLevel.add(10).min(200); // Small coherence boost

        } else {
            // Apply failure effects
            _payEssence(chronicleOwner, challenge.failurePenaltyEssence); // Penalize the owner's Essence
            _chronicles[chronicleId].coherenceLevel = _chronicles[chronicleId].coherenceLevel.sub(challenge.failurePenaltyCoherence).max(10); // Penalize coherence
             // Optional: remove aspects or other negative effects
        }

        // Clear active challenge state
        delete _activeChallenges[chronicleId];

        emit ChallengeResolved(chronicleId, activeState.challengeId, success);
    }

     /// @notice Gets the current state of a pending Challenge for a Chronicle.
     /// @param chronicleId The ID of the Chronicle.
     /// @return ActiveChallengeState struct.
    function getActiveChallenge(uint256 chronicleId) public view returns (ActiveChallengeState memory) {
        _requireChronicleExists(chronicleId);
        return _activeChallenges[chronicleId];
    }


    // --- Epoch & Rule Functions ---

    /// @notice Advances the contract's global Epoch counter.
    /// @dev This can trigger game state changes and alter rules.
    function advanceEpoch() public onlyEpochAdmin {
        _currentEpoch = _currentEpoch.add(1);
        // Ensure rules exist for the new epoch, or fall back to defaults/previous epoch rules
        if (!_epochRules[_currentEpoch].exists && _currentEpoch > 0) {
             // Inherit rules from previous epoch if new ones aren't explicitly set
             _epochRules[_currentEpoch] = _epochRules[_currentEpoch - 1];
             _epochRules[_currentEpoch].exists = true; // Mark as existing after copying
        }
        emit EpochAdvanced(_currentEpoch);
    }

    /// @notice Gets the current global Epoch number.
    /// @return The current epoch.
    function getCurrentEpoch() public view returns (uint64) {
        return _currentEpoch;
    }

    /// @notice Sets or updates the rules for a specific Epoch.
    /// @param epoch The epoch number to set rules for.
    /// @param evolutionEssenceCost Cost for evolution in this epoch.
    /// @param synthesisBaseEssenceCost Base essence cost for synthesis in this epoch.
    /// @param challengeBaseEssenceCost Base essence cost for challenges in this epoch.
    /// @param temporalAnchorCost Cost for setting a temporal anchor.
    /// @param dimensionalShiftCost Cost for initiating a dimensional shift.
    function setEpochRules(uint64 epoch, uint256 evolutionEssenceCost, uint256 synthesisBaseEssenceCost, uint256 challengeBaseEssenceCost, uint256 temporalAnchorCost, uint256 dimensionalShiftCost) public onlyEpochAdmin {
        // Cannot set rules for epochs already passed the current one (unless enabling future planning)
        // require(epoch >= _currentEpoch, "Cannot set rules for past epochs"); // Or allow setting for future epochs?
        // Let's allow setting future rules for planning
        _epochRules[epoch] = EpochRules({
            evolutionEssenceCost: evolutionEssenceCost,
            synthesisBaseEssenceCost: synthesisBaseEssenceCost,
            challengeBaseEssenceCost: challengeBaseEssenceCost,
            temporalAnchorCost: temporalAnchorCost,
            dimensionalShiftCost: dimensionalShiftCost,
            exists: true
        });
        emit EpochRulesSet(epoch);
    }

    /// @notice Retrieves the rules for a specific Epoch.
    /// @param epoch The epoch number.
    /// @return EpochRules struct.
    function getEpochRules(uint64 epoch) public view returns (EpochRules memory) {
        // Return empty struct or specific error if rules don't exist
        if (!_epochRules[epoch].exists) {
             revert InvalidEpoch(epoch);
        }
        return _epochRules[epoch];
    }

    function _getEpochRules(uint64 epoch) internal view returns (EpochRules storage) {
        // Internal helper, assumes rules exist or will use zero values
         return _epochRules[epoch];
    }


    // --- Admin Functions ---

    /// @notice Grants or revokes the Epoch Admin role.
    /// @dev Epoch Admins can advance epochs and resolve challenges.
    /// @param admin The address to modify.
    /// @param isEpochAdmin True to grant role, false to revoke.
    function setEpochAdmin(address admin, bool isEpochAdmin) public onlyOwner {
        _isEpochAdmin[admin] = isEpochAdmin;
        emit EpochAdminSet(admin, isEpochAdmin);
    }

    /// @notice Checks if an account has the Epoch Admin role.
    /// @param account The address to check.
    /// @return True if the account is an Epoch Admin, false otherwise.
    function isEpochAdmin(address account) public view returns (bool) {
        return _isEpochAdmin[account];
    }

    // --- Internal Helpers ---

    function _requireChronicleExists(uint256 chronicleId) internal view {
         // Check ERC721 existence AND our internal mapping state
         if (!_exists(chronicleId) || _chronicles[chronicleId].owner == address(0)) {
             revert ChronicleNotFound(chronicleId);
         }
     }

    // --- Override ERC721Enumerable functions to use our data ---
    // ERC721Enumerable requires tokenURI, which we handle.
    // ERC721Enumerable also uses _beforeTokenTransfer which we overrode.

}
```