Okay, here is a Solidity smart contract concept focusing on dynamic, evolving NFTs that require resources (simulated via an external ERC20 token) to transform and maintain their state. This concept combines elements of resource management, time-based mechanics, and conditional state changes within the NFT itself. It's distinct from standard ERC721s and common staking/farming contracts.

**Concept Name:** MetaMorph

**Concept Summary:**
MetaMorph is an ERC721 token where each NFT represents a digital entity capable of changing its "Form" or "State". These transformations are not merely metadata updates; they are governed by on-chain rules, requiring the consumption of an external ERC20 "Essence" token, potentially subject to time-based cooldowns, dependencies on previous forms, or external "catalyst" conditions. MetaMorphs can also "decay" back to a previous form if not maintained with sufficient bonded Essence over time.

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and import necessary libraries (ERC721, Ownable, IERC20).
2.  **Interfaces:** Define an interface for the external Essence ERC20 token.
3.  **Events:** Define events for key actions (Minting, Transformation, Decay, Essence Bonding/Unbonding, Configuration changes, Catalyst state changes).
4.  **Errors:** Define custom errors for clarity.
5.  **Structs:**
    *   `FormProperties`: Defines the rules and costs for each possible Form.
    *   `MetaMorphState`: Stores the current state of a specific MetaMorph token.
6.  **State Variables:**
    *   Mapping for Form properties.
    *   Mapping for each MetaMorph token's state.
    *   Counter for total minted tokens.
    *   Address of the external Essence token contract.
    *   Mapping for external Catalyst states.
    *   Default values (e.g., initial form ID, decay interval).
7.  **Modifiers:** Custom modifiers for access control (e.g., `onlyOwnerOfToken`, `canTransform`).
8.  **Constructor:** Initializes the contract (ERC721 name/symbol, sets owner).
9.  **ERC721 Standard Functions (Inherited):**
    *   `balanceOf(address owner)`
    *   `ownerOf(uint256 tokenId)`
    *   `approve(address to, uint256 tokenId)`
    *   `getApproved(uint256 tokenId)`
    *   `setApprovalForAll(address operator, bool approved)`
    *   `isApprovedForAll(address owner, address operator)`
    *   `transferFrom(address from, address to, uint256 tokenId)`
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`
10. **Custom Functions:**
    *   **Minting:**
        *   `mint()`: Mints a new MetaMorph in the initial form (restricted).
        *   `batchMint(address[] recipients)`: Mints multiple MetaMorphs (restricted).
    *   **State & Information (View/Pure):**
        *   `getMetaMorphState(uint256 tokenId)`: Retrieve the full state struct for a token.
        *   `getFormProperties(uint8 formId)`: Retrieve the configuration for a specific form.
        *   `getTotalSupply()`: Get the total number of MetaMorphs minted.
        *   `getBondedEssence(uint256 tokenId)`: Get the amount of Essence bonded to a token.
        *   `getCurrentFormId(uint256 tokenId)`: Get the current form ID of a token.
        *   `getDecayStatus(uint256 tokenId)`: Check if a token is currently eligible for decay.
        *   `getCooldownStatus(uint256 tokenId)`: Check if a token is currently on a transformation cooldown.
        *   `getPotentialTransforms(uint256 tokenId)`: List forms a token *could* potentially transform into (based on current form and properties, not checking time/essence/catalysts).
        *   `checkTransformConditions(uint256 tokenId, uint8 targetFormId)`: Detailed check of *all* conditions for a specific transformation.
        *   `getCurrentCatalystState(uint8 catalystId)`: Check if a specific external catalyst is active.
    *   **Core Mechanics (State Changing):**
        *   `transform(uint256 tokenId, uint8 targetFormId)`: Attempt to transform a MetaMorph to a target form, consuming Essence and applying rules.
        *   `decay(uint256 tokenId)`: Trigger decay for a token if decay conditions (time/bonded essence) are met.
        *   `bondEssence(uint256 tokenId, uint256 amount)`: Bond Essence tokens to a MetaMorph (requires ERC20 approval beforehand).
        *   `unbondEssence(uint256 tokenId, uint256 amount)`: Unbond Essence from a MetaMorph.
        *   `lockForm(uint256 tokenId, uint256 duration)`: Temporarily prevent decay/transformation by locking the form (might cost Essence).
        *   `unlockForm(uint256 tokenId)`: Remove a form lock.
    *   **Configuration (Owner Only):**
        *   `setEssenceTokenAddress(address _essenceToken)`: Set the address of the Essence ERC20 contract.
        *   `addFormProperty(uint8 formId, uint256 essenceCost, uint256 cooldownDuration, uint8 requiredPrevFormId, bool requiresCatalystId, uint8 catalystId)`: Define a new possible form and its properties.
        *   `updateFormProperty(uint8 formId, uint256 essenceCost, uint256 cooldownDuration, uint8 requiredPrevFormId, bool requiresCatalystId, uint8 catalystId)`: Modify properties of an existing form.
        *   `setDecayParameters(uint256 decayInterval, uint256 essenceDecayThreshold)`: Set the time interval for decay check and the minimum bonded essence to prevent it.
        *   `triggerCatalystEvent(uint8 catalystId, bool isActive)`: Simulate an external catalyst becoming active or inactive.
    *   **Maintenance/Advanced (Owner Only):**
        *   `withdrawEssence(uint256 amount)`: Withdraw accumulated Essence revenue (from transformations).

**Function Summary:**

*   **Inherited (9):** Standard ERC721 functions for token ownership, balance, and transfers.
*   **`mint()` (1):** Mints a single new MetaMorph token.
*   **`batchMint()` (1):** Mints multiple new MetaMorph tokens to specified recipients.
*   **`getMetaMorphState()` (1):** Returns the full custom state data for a given token ID.
*   **`getFormProperties()` (1):** Returns the configuration details for a specific form ID.
*   **`getTotalSupply()` (1):** Returns the total number of MetaMorph tokens that have been minted.
*   **`getBondedEssence()` (1):** Returns the amount of Essence token bonded to a given MetaMorph.
*   **`getCurrentFormId()` (1):** Returns the current form ID of a MetaMorph.
*   **`getDecayStatus()` (1):** Returns true if a MetaMorph is currently eligible to decay based on time and bonded essence.
*   **`getCooldownStatus()` (1):** Returns true if a MetaMorph is currently within its transformation cooldown period.
*   **`getPotentialTransforms()` (1):** Returns an array of form IDs that a MetaMorph *could* transform into, based on its current form and defined properties.
*   **`checkTransformConditions()` (1):** Provides a detailed boolean check if a specific transformation is currently possible, considering all factors (cooldown, essence, previous form, catalyst).
*   **`getCurrentCatalystState()` (1):** Returns the active/inactive status of a specific catalyst ID.
*   **`transform()` (1):** The core function. Attempts to change a MetaMorph's form, consuming Essence, respecting cooldowns, dependencies, and catalyst states.
*   **`decay()` (1):** Executes the decay logic for a MetaMorph if its decay conditions are met, reverting it to a previous or default form.
*   **`bondEssence()` (1):** Allows a token owner to transfer Essence tokens into the MetaMorph contract and associate them with a specific token ID.
*   **`unbondEssence()` (1):** Allows a token owner to withdraw bonded Essence from their MetaMorph.
*   **`lockForm()` (1):** Prevents a MetaMorph from decaying or transforming for a set duration, potentially costing Essence.
*   **`unlockForm()` (1):** Removes a form lock.
*   **`setEssenceTokenAddress()` (1):** (Owner) Sets the address of the external Essence ERC20 contract.
*   **`addFormProperty()` (1):** (Owner) Defines a new valid form ID and its associated transformation rules.
*   **`updateFormProperty()` (1):** (Owner) Modifies the rules for an existing form ID.
*   **`setDecayParameters()` (1):** (Owner) Configures the parameters that govern the decay mechanism.
*   **`triggerCatalystEvent()` (1):** (Owner) Toggles the active state of a specific external catalyst ID, affecting transformations that require it.
*   **`withdrawEssence()` (1):** (Owner) Withdraws Essence tokens collected by the contract (e.g., from transformation costs).

**Total Custom Functions:** 25
**Total Functions (Custom + Inherited):** 9 + 25 = 34 (Meets the >20 requirement easily)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline ---
// 1. Pragma and Imports
// 2. Interfaces
// 3. Events
// 4. Errors
// 5. Structs
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. ERC721 Standard Functions (Inherited via OpenZeppelin)
// 10. Custom Functions:
//    - Minting
//    - State & Information (View/Pure)
//    - Core Mechanics (Transformation, Decay, Essence Bonding/Unbonding)
//    - Configuration (Owner Only)
//    - Maintenance/Advanced (Owner Only)

// --- Function Summary ---
// Inherited (9): Standard ERC721 functions for ownership, balance, transfers, approvals.
// mint(): Mints a single new MetaMorph token.
// batchMint(): Mints multiple new MetaMorph tokens to specified recipients.
// getMetaMorphState(): Returns the full custom state data for a given token ID.
// getFormProperties(): Returns the configuration details for a specific form ID.
// getTotalSupply(): Returns the total number of MetaMorph tokens minted.
// getBondedEssence(): Returns the amount of Essence token bonded to a given MetaMorph.
// getCurrentFormId(): Returns the current form ID of a MetaMorph.
// getDecayStatus(): Returns true if a token is eligible for decay.
// getCooldownStatus(): Returns true if a token is on transformation cooldown.
// getPotentialTransforms(): Lists forms a token could potentially transform into (based on properties).
// checkTransformConditions(): Detailed check of all conditions for a specific transformation.
// getCurrentCatalystState(): Checks the active state of a catalyst.
// transform(): Attempts to change a MetaMorph's form, consuming Essence and applying rules.
// decay(): Executes decay logic for a token if conditions met.
// bondEssence(): Bonds Essence tokens to a MetaMorph (requires prior ERC20 approval).
// unbondEssence(): Unbonds Essence from a MetaMorph.
// lockForm(): Temporarily prevents decay/transformation (potentially costs Essence).
// unlockForm(): Removes a form lock.
// setEssenceTokenAddress(): (Owner) Sets the Essence ERC20 contract address.
// addFormProperty(): (Owner) Defines a new form ID and its transformation rules.
// updateFormProperty(): (Owner) Modifies rules for an existing form ID.
// setDecayParameters(): (Owner) Configures decay parameters.
// triggerCatalystEvent(): (Owner) Toggles catalyst active state.
// withdrawEssence(): (Owner) Withdraws accumulated Essence from the contract.

contract MetaMorph is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- Interfaces ---
    // Assuming Essence is a standard ERC20 token
    IERC20 private essenceToken;

    // --- Events ---
    event MetaMorphMinted(address indexed owner, uint256 indexed tokenId, uint8 initialFormId);
    event FormTransformed(uint256 indexed tokenId, uint8 fromFormId, uint8 toFormId, uint256 essenceConsumed);
    event MetaMorphDecayed(uint256 indexed tokenId, uint8 fromFormId, uint8 toFormId);
    event EssenceBonded(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event EssenceUnbonded(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event FormLocked(uint256 indexed tokenId, uint256 unlockTime);
    event FormUnlocked(uint256 indexed tokenId);
    event CatalystStateChanged(uint8 indexed catalystId, bool isActive);
    event EssenceTokenAddressUpdated(address indexed newAddress);
    event FormPropertyAdded(uint8 indexed formId);
    event FormPropertyUpdated(uint8 indexed formId);
    event DecayParametersUpdated(uint256 decayInterval, uint256 essenceDecayThreshold);
    event EssenceWithdrawn(address indexed owner, uint256 amount);

    // --- Errors ---
    error InvalidFormId();
    error TransformationNotPossible(string reason);
    error DecayNotApplicable();
    error InsufficientBondedEssence();
    error CannotUnbondLockedEssence(); // Maybe Essence is locked during form lock?
    error FormIsLocked();
    error NotEnoughTimePassed();
    error EssenceTokenNotSet();
    error InvalidCatalyst();
    error CatalystRequired();
    error EssenceTransferFailed();
    error OnlyApprovedOrOwner();
    error NotOwnerOfToken();
    error TransferDeniedWhileLocked(); // Prevent standard ERC721 transfer while locked? Or only core functions? Let's deny standard transfer too.

    // --- Structs ---
    struct FormProperties {
        uint256 essenceCost;          // Essence required to transform INTO this form
        uint256 cooldownDuration;     // Time required AFTER transforming OUT of this form
        uint8 requiredPrevFormId;     // Required previous form to transform INTO this form (0 for initial)
        bool requiresCatalyst;        // Does transforming INTO this form require a specific catalyst?
        uint8 catalystId;             // Which catalyst is required (if requiresCatalyst is true)
        // Future expansion: passive essence generation rate, specific abilities, etc.
    }

    struct MetaMorphState {
        uint8 currentFormId;
        uint256 lastTransformTime;    // Timestamp of the last transformation
        uint256 bondedEssence;        // Amount of Essence bonded to this specific token
        uint256 formLockUntil;        // Timestamp until the form is locked (0 if not locked)
        // Future expansion: lifetime stats, specific random traits, etc.
    }

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Maps form ID to its properties
    mapping(uint8 => FormProperties) public formProperties;
    uint8[] public availableFormIds; // Keep track of existing forms

    // Maps tokenId to its current state
    mapping(uint256 => MetaMorphState) private _metaMorphState;

    // Essence token address
    address public essenceTokenAddress;

    // Decay parameters
    uint256 public decayInterval = 7 days;       // How often decay check is relevant
    uint256 public essenceDecayThreshold = 100e18; // Min bonded essence to prevent decay

    // Catalyst states (e.g., external events)
    mapping(uint8 => bool) public catalystActive; // Maps catalyst ID to its active state

    // Initial form ID when minting
    uint8 public initialFormId = 1; // Assume 1 is the basic form

    // --- Modifiers ---
    modifier onlyOwnerOfToken(uint256 tokenId) {
        if (_ownerOf(tokenId) != _msgSender()) revert NotOwnerOfToken();
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
         if (_isApprovedOrOwner(_msgSender(), tokenId) == false) revert OnlyApprovedOrOwner();
        _;
    }

     // Override _beforeTokenTransfer to add lock check
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (_metaMorphState[tokenId].formLockUntil > block.timestamp) {
            // Allow transfers from address(0) (minting) and to address(0) (burning)
            if (from != address(0) && to != address(0)) {
                 revert TransferDeniedWhileLocked();
            }
        }
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {}

    // --- Custom Functions ---

    // --- Minting ---

    function mint(address to) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(to, newTokenId);

        // Initialize state for the new token
        _metaMorphState[newTokenId] = MetaMorphState({
            currentFormId: initialFormId,
            lastTransformTime: block.timestamp,
            bondedEssence: 0,
            formLockUntil: 0
        });

        emit MetaMorphMinted(to, newTokenId, initialFormId);
    }

    function batchMint(address[] memory recipients) public onlyOwner {
        require(recipients.length > 0, "Recipients array cannot be empty");
        for (uint i = 0; i < recipients.length; i++) {
            mint(recipients[i]);
        }
    }

    // --- State & Information (View/Pure) ---

    function getMetaMorphState(uint256 tokenId) public view returns (MetaMorphState memory) {
        _requireOwned(tokenId); // Ensure token exists and caller is authorized (or check specific need) - simplified to just check existence implicitly by state mapping access, assuming tokenId comes from a valid source or require _exists(tokenId)
        require(_exists(tokenId), "ERC721: owner query for nonexistent token"); // Explicit existence check
        return _metaMorphState[tokenId];
    }

    function getFormProperties(uint8 formId) public view returns (FormProperties memory) {
        require(formProperties[formId].cooldownDuration > 0 || formId == initialFormId, "MetaMorph: Invalid form ID requested"); // Check if form exists (simple check)
        return formProperties[formId];
    }

    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function getBondedEssence(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _metaMorphState[tokenId].bondedEssence;
    }

     function getCurrentFormId(uint256 tokenId) public view returns (uint8) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _metaMorphState[tokenId].currentFormId;
    }

    function getDecayStatus(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        MetaMorphState storage state = _metaMorphState[tokenId];
        if (state.formLockUntil > block.timestamp) return false; // Locked forms don't decay

        // Check if time has passed since last transformation/decay check
        bool timeElapsed = block.timestamp >= state.lastTransformTime + decayInterval;

        // Check if bonded essence is below threshold
        bool insufficientEssence = state.bondedEssence < essenceDecayThreshold;

        return timeElapsed && insufficientEssence;
    }

    function getCooldownStatus(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        MetaMorphState storage state = _metaMorphState[tokenId];
        uint8 currentForm = state.currentFormId;
        if (formProperties[currentForm].cooldownDuration == 0) return false; // No cooldown for this form
        return block.timestamp < state.lastTransformTime + formProperties[currentForm].cooldownDuration;
    }


    function getPotentialTransforms(uint256 tokenId) public view returns (uint8[] memory) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        uint8 currentForm = _metaMorphState[tokenId].currentFormId;
        uint8[] memory potentialForms = new uint8[](0);

        // Iterate through all defined forms to see which ones the current form can transform into
        for (uint i = 0; i < availableFormIds.length; i++) {
            uint8 targetFormId = availableFormIds[i];
            if (formProperties[targetFormId].requiredPrevFormId == currentForm) {
                // This form is a potential target from the current form
                uint8[] memory temp = new uint8[](potentialForms.length + 1);
                for(uint j = 0; j < potentialForms.length; j++) {
                    temp[j] = potentialForms[j];
                }
                temp[potentialForms.length] = targetFormId;
                potentialForms = temp;
            }
        }

        return potentialForms;
    }

    function checkTransformConditions(uint256 tokenId, uint8 targetFormId) public view returns (bool isPossible, string memory reason) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        MetaMorphState storage state = _metaMorphState[tokenId];
        FormProperties memory targetProps = formProperties[targetFormId];

        // Basic checks
        if (targetProps.cooldownDuration == 0 && targetFormId != initialFormId) { // check if targetFormId exists (rough check)
             return (false, "Invalid target form ID");
        }
        if (state.currentFormId == targetFormId) {
             return (false, "Already in target form");
        }
         if (state.formLockUntil > block.timestamp) {
             return (false, "Form is locked");
         }

        // Check previous form requirement
        if (targetProps.requiredPrevFormId != 0 && targetProps.requiredPrevFormId != state.currentFormId) {
            return (false, "Requires different previous form");
        }
         if (targetProps.requiredPrevFormId == 0 && state.currentFormId != initialFormId) {
             // If requiredPrevFormId is 0, it means this form can only be reached from the initial form (or is the initial form itself)
             return (false, "Can only transform from initial form"); // Or adjust logic based on desired rules
         }


        // Check cooldown
        if (getCooldownStatus(tokenId)) {
            return (false, "Cooldown in effect");
        }

        // Check Essence cost
        if (state.bondedEssence < targetProps.essenceCost) {
            return (false, "Insufficient bonded Essence");
        }

        // Check Catalyst requirement
        if (targetProps.requiresCatalyst) {
            if (targetProps.catalystId == 0) { // Catalyst ID 0 might be reserved or invalid
                 return (false, "Invalid catalyst ID required by target form");
            }
            if (!catalystActive[targetProps.catalystId]) {
                return (false, "Required catalyst is not active");
            }
        }

        // If all checks pass
        return (true, "Conditions met");
    }

    function getCurrentCatalystState(uint8 catalystId) public view returns (bool) {
        return catalystActive[catalystId];
    }


    // --- Core Mechanics ---

    function transform(uint256 tokenId, uint8 targetFormId) public nonReentrant onlyOwnerOfToken(tokenId) {
        require(essenceTokenAddress != address(0), EssenceTokenNotSet());

        MetaMorphState storage state = _metaMorphState[tokenId];
        FormProperties memory targetProps = formProperties[targetFormId];

        // Use the detailed check function
        (bool isPossible, string memory reason) = checkTransformConditions(tokenId, targetFormId);
        if (!isPossible) {
             revert TransformationNotPossible(reason);
        }

        // Conditions met, perform transformation
        uint8 oldFormId = state.currentFormId;
        uint256 essenceCost = targetProps.essenceCost;

        // Consume bonded Essence first
        if (state.bondedEssence >= essenceCost) {
            state.bondedEssence -= essenceCost;
        } else {
            // This case should technically be caught by checkTransformConditions, but good to be safe.
            // If bonded is not enough, the remainder must come from msg.sender's balance.
            // This design assumes cost *must* be covered by bonded essence. If not, adjust logic.
             revert InsufficientBondedEssence();
        }

        // Update state
        state.currentFormId = targetFormId;
        state.lastTransformTime = block.timestamp; // Reset cooldown/decay timer
        state.formLockUntil = 0; // Transformation removes any lock

        emit FormTransformed(tokenId, oldFormId, targetFormId, essenceCost);
    }

    function decay(uint256 tokenId) public nonReentrant { // Can be called by anyone to trigger if conditions met
        require(_exists(tokenId), "ERC721: decay query for nonexistent token");
        MetaMorphState storage state = _metaMorphState[tokenId];

        if (!getDecayStatus(tokenId)) {
            revert DecayNotApplicable();
        }

        uint8 oldFormId = state.currentFormId;
        uint8 newFormId; // The form it decays into

        // Determine the decay form. Simple: decay to the 'requiredPrevFormId' if exists, otherwise initialFormId
        FormProperties memory currentFormProps = formProperties[oldFormId];
        if (currentFormProps.requiredPrevFormId != 0) {
            newFormId = currentFormProps.requiredPrevFormId;
        } else {
            newFormId = initialFormId;
        }

        // Decay reduces bonded essence (as it wasn't enough to prevent decay)
        state.bondedEssence = 0; // Or a percentage reduction

        // Update state
        state.currentFormId = newFormId;
        state.lastTransformTime = block.timestamp; // Reset timer for next check
        state.formLockUntil = 0; // Decay removes any lock

        emit MetaMorphDecayed(tokenId, oldFormId, newFormId);
    }

    function bondEssence(uint256 tokenId, uint256 amount) public nonReentrant onlyOwnerOfToken(tokenId) {
        require(essenceTokenAddress != address(0), EssenceTokenNotSet());
        require(amount > 0, "Amount must be positive");

        // Transfer Essence from the owner to the contract
        IERC20 essence = IERC20(essenceTokenAddress);
        bool success = essence.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert EssenceTransferFailed();
        }

        // Add to bonded essence
        _metaMorphState[tokenId].bondedEssence += amount;

        emit EssenceBonded(tokenId, msg.sender, amount);
    }

    function unbondEssence(uint256 tokenId, uint256 amount) public nonReentrant onlyOwnerOfToken(tokenId) {
        require(essenceTokenAddress != address(0), EssenceTokenNotSet());
        require(amount > 0, "Amount must be positive");
        MetaMorphState storage state = _metaMorphState[tokenId];

        // Cannot unbond while form is locked (optional rule)
        // if (state.formLockUntil > block.timestamp) revert CannotUnbondLockedEssence();

        require(state.bondedEssence >= amount, InsufficientBondedEssence());

        // Transfer Essence from the contract back to the owner
        state.bondedEssence -= amount;

        IERC20 essence = IERC20(essenceTokenAddress);
         bool success = essence.transfer(msg.sender, amount);
        if (!success) {
             // This is a critical error, might need emergency withdrawal or re-adding bonded essence
             // For simplicity here, we just revert.
             state.bondedEssence += amount; // Revert state change
             revert EssenceTransferFailed();
        }

        emit EssenceUnbonded(tokenId, msg.sender, amount);
    }

    function lockForm(uint256 tokenId, uint256 duration) public nonReentrant onlyOwnerOfToken(tokenId) {
        require(duration > 0, "Lock duration must be positive");
        // Optional: Require Essence cost to lock the form
        // uint256 lockCost = calculateLockCost(tokenId, duration);
        // bondEssence(tokenId, lockCost); // Requires approval beforehand, simpler to just consume bonded?
        // Or: require user to approve Essence and transferFrom here?
        // For simplicity, let's just set the lock for now without cost.

        _metaMorphState[tokenId].formLockUntil = block.timestamp + duration;
        emit FormLocked(tokenId, block.timestamp + duration);
    }

    function unlockForm(uint256 tokenId) public nonReentrant onlyOwnerOfToken(tokenId) {
        require(_metaMorphState[tokenId].formLockUntil > block.timestamp, FormIsLocked()); // Can only unlock if currently locked
        _metaMorphState[tokenId].formLockUntil = 0;
        emit FormUnlocked(tokenId);
    }


    // --- Configuration (Owner Only) ---

    function setEssenceTokenAddress(address _essenceToken) public onlyOwner {
        require(_essenceToken != address(0), "Essence token address cannot be zero");
        essenceTokenAddress = _essenceToken;
        emit EssenceTokenAddressUpdated(_essenceToken);
    }

    function addFormProperty(uint8 formId, uint256 essenceCost, uint256 cooldownDuration, uint8 requiredPrevFormId, bool requiresCatalyst, uint8 catalystId) public onlyOwner {
        // Basic validation
        require(formId != 0, "Form ID cannot be zero"); // Assuming 0 is invalid or reserved
        require(formProperties[formId].cooldownDuration == 0 && formId != initialFormId, "Form ID already exists"); // Check if formId is already used (simple check)
         if (requiredPrevFormId != 0) {
             require(formProperties[requiredPrevFormId].cooldownDuration > 0 || requiredPrevFormId == initialFormId, "Required previous form ID must exist");
         }
         if(requiresCatalyst) {
             require(catalystId != 0, "Catalyst ID must be non-zero if required");
         } else {
             require(catalystId == 0, "Catalyst ID must be zero if not required");
         }


        formProperties[formId] = FormProperties({
            essenceCost: essenceCost,
            cooldownDuration: cooldownDuration,
            requiredPrevFormId: requiredPrevFormId,
            requiresCatalyst: requiresCatalyst,
            catalystId: catalystId
        });
        availableFormIds.push(formId); // Add to the list of available forms
        emit FormPropertyAdded(formId);
    }

    function updateFormProperty(uint8 formId, uint256 essenceCost, uint256 cooldownDuration, uint8 requiredPrevFormId, bool requiresCatalyst, uint8 catalystId) public onlyOwner {
        require(formId != 0 && (formProperties[formId].cooldownDuration > 0 || formId == initialFormId), InvalidFormId()); // Ensure form exists
         if (requiredPrevFormId != 0) {
             require(formProperties[requiredPrevFormId].cooldownDuration > 0 || requiredPrevFormId == initialFormId, "Required previous form ID must exist");
         }
         if(requiresCatalyst) {
             require(catalystId != 0, "Catalyst ID must be non-zero if required");
         } else {
             require(catalystId == 0, "Catalyst ID must be zero if not required");
         }

        formProperties[formId] = FormProperties({
            essenceCost: essenceCost,
            cooldownDuration: cooldownDuration,
            requiredPrevFormId: requiredPrevFormId,
            requiresCatalyst: requiresCatalyst,
            catalystId: catalystId
        });
        emit FormPropertyUpdated(formId);
    }

     function setDecayParameters(uint256 _decayInterval, uint256 _essenceDecayThreshold) public onlyOwner {
        require(_decayInterval > 0, "Decay interval must be positive");
        decayInterval = _decayInterval;
        essenceDecayThreshold = _essenceDecayThreshold;
        emit DecayParametersUpdated(decayInterval, essenceDecayThreshold);
    }

    function triggerCatalystEvent(uint8 catalystId, bool isActive) public onlyOwner {
        require(catalystId != 0, InvalidCatalyst());
        catalystActive[catalystId] = isActive;
        emit CatalystStateChanged(catalystId, isActive);
    }


    // --- Maintenance/Advanced (Owner Only) ---

    function withdrawEssence(uint256 amount) public onlyOwner {
        require(essenceTokenAddress != address(0), EssenceTokenNotSet());
        require(amount > 0, "Amount must be positive");

        IERC20 essence = IERC20(essenceTokenAddress);
        require(essence.balanceOf(address(this)) >= amount, "Insufficient Essence balance in contract");

        bool success = essence.transfer(msg.sender, amount);
        if (!success) {
             revert EssenceTransferFailed(); // This shouldn't fail if balance is sufficient, but good practice
        }
        emit EssenceWithdrawn(msg.sender, amount);
    }


    // Fallback/Receive (Optional, if you want to receive ETH, but this contract is focused on ERC20)
    // receive() external payable {}
    // fallback() external payable {}
}
```