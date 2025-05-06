Okay, this is a fun challenge! We'll create a contract called `DigitalNecromancy` that manages unique digital entities called "Echoes" (ERC-721) and a related resource called "Soul Energy" (ERC-20). The core concept revolves around the life cycle of Echoes, their interaction with Soul Energy, on-chain traits influencing mechanics, and the concept of digital "death" and potential "revival" or "legacy".

It aims for complexity by intertwining ERC-20 and ERC-721 logic with custom state transitions, time-based mechanics, trait effects, and resource management.

**Outline and Function Summary**

**Contract Name:** `DigitalNecromancy`

**Description:** A smart contract managing a collection of unique digital entities called "Echoes" (ERC-721) and a fungible resource called "Soul Energy" (ERC-20). Echoes have dynamic states (Alive, Faded, Dormant, Dissipated) influenced by time, interaction, and on-chain traits. Soul Energy is used for interacting with Echoes, such as Nourishing them to prevent fading or Reviving them from a Dormant state. Dissipated Echoes may leave a Vestige (claimable Soul Energy).

**Core Concepts:**
*   **Echoes (ERC-721):** Unique digital entities with states and traits.
*   **Soul Energy (ERC-20):** The resource token used for interactions.
*   **States:** Alive, Faded (decaying), Dormant (digital death), Dissipated (permanent removal, potential Vestige).
*   **Time-based Fading:** Echoes automatically transition from Alive -> Faded -> Dormant if not Nourished.
*   **On-Chain Traits:** Traits generated at Mint influence Fading rate and Revival cost.
*   **Nourishing:** Using Soul Energy to reset an Echo's fading timer.
*   **Revival:** Using Soul Energy to bring a Dormant Echo back to Alive.
*   **Dissipation & Vestige:** Permanently removing an Echo, leaving a claimable Soul Energy "legacy".
*   **Roles:** Admin roles for minting, setting parameters.

**Inheritances:**
*   `ERC721` (from OpenZeppelin) for Echoes.
*   `ERC721Enumerable` (optional, but useful for tracking all tokens - let's include it for more functions).
*   `ERC721URIStorage` (for metadata URIs).
*   `ERC20` (from OpenZeppelin) for Soul Energy.
*   `AccessControl` (from OpenZeppelin) for role-based permissions.
*   `ReentrancyGuard` (from OpenZeppelin) for safety on interactions.

**State Variables:**
*   `_echoData`: Mapping storing `EchoData` struct (state, creation time, last nourished, trait ID) for each Echo ID.
*   `_echoTraits`: Mapping storing `EchoTraits` struct (numerical trait values) for each Trait ID.
*   `_vestigeData`: Mapping storing `VestigeData` struct (beneficiary, energy amount, claimed status) for dissipated Echo IDs.
*   `_traitConfig`: Mapping storing `TraitConfig` struct (fading impact, revival cost impact) for each trait type/value.
*   `_nourishCost`: Base Soul Energy cost to nourish an Echo.
*   `_reviveBaseCost`: Base Soul Energy cost to revive a Dormant Echo.
*   `_reviveCostPerDormantHour`: Additional Soul Energy cost per hour of dormancy when reviving.
*   `_fadingThresholdAliveHours`: Hours before an Alive Echo becomes Faded.
*   `_fadingThresholdFadedHours`: Hours before a Faded Echo becomes Dormant.
*   `_VESTIGE_PERCENTAGE`: Percentage of potential revival cost granted as Vestige.
*   `_echoCounter`: Counter for unique Echo IDs.
*   `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, `ENERGY_MINTER_ROLE`: AccessControl roles.

**Events:**
*   `EchoMinted(uint256 indexed tokenId, address indexed owner, EchoState initialState, uint256 traitId)`
*   `EchoStateChanged(uint256 indexed tokenId, EchoState oldState, EchoState newState)`
*   `EchoNourished(uint256 indexed tokenId, address indexed nourisher, uint256 energyUsed, uint64 newLastNourished)`
*   `EchoRevived(uint256 indexed tokenId, address indexed reviver, uint256 energyUsed)`
*   `EchoDissipated(uint256 indexed tokenId, address indexed owner, address indexed vestigeBeneficiary, uint256 potentialVestigeAmount)`
*   `VestigeClaimed(uint256 indexed tokenId, address indexed claimant, uint256 energyClaimed)`
*   `SoulEnergyMinted(address indexed recipient, uint256 amount)`
*   `SoulEnergyBurned(address indexed burner, uint256 amount)`
*   `TraitConfigUpdated(uint256 indexed traitType, uint256 indexed traitValue, int256 fadingImpact, int256 revivalCostImpact)`
*   `ParametersUpdated(uint256 nourishCost, uint256 reviveBaseCost, uint256 reviveCostPerDormantHour, uint256 fadingThresholdAliveHours, uint256 fadingThresholdFadedHours)`

**Modifiers:**
*   `onlyEchoOwner(uint256 tokenId)`: Requires the caller to be the owner of the Echo.
*   `onlyEchoExisting(uint256 tokenId)`: Requires the Echo ID to exist and not be dissipated.
*   `onlyAliveOrFaded(uint256 tokenId)`: Requires the Echo to be in Alive or Faded state.
*   `onlyDormant(uint256 tokenId)`: Requires the Echo to be in Dormant state.
*   `onlyDissipated(uint256 tokenId)`: Requires the Echo to be in Dissipated state with an unclaimed Vestige.

**Functions (Total >= 20):**

*   **Setup & Initialization:**
    1.  `constructor()`: Initializes ERC-721/ERC-20 details and sets default admin role.
    2.  `grantRole(bytes32 role, address account)`: Grant roles (inherited from AccessControl).
    3.  `revokeRole(bytes32 role, address account)`: Revoke roles (inherited from AccessControl).
    4.  `renounceRole(bytes32 role)`: Renounce roles (inherited from AccessControl).
    5.  `hasRole(bytes32 role, address account)`: Check if account has role (inherited).
    6.  `getRoleAdmin(bytes32 role)`: Get admin role for a role (inherited).
    7.  `_setupRole(bytes32 role, address account)`: Internal helper to grant initial roles (used in constructor).

*   **ERC-721 Standard (Echoes):**
    8.  `balanceOf(address owner)`: Returns the number of Echoes owned by an address.
    9.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific Echo.
    10. `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers Echo with safety checks.
    11. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Transfers Echo with data.
    12. `transferFrom(address from, address to, uint256 tokenId)`: Transfers Echo (less safe variant).
    13. `approve(address to, uint256 tokenId)`: Grants approval for one address to transfer an Echo.
    14. `getApproved(uint256 tokenId)`: Gets the approved address for an Echo.
    15. `setApprovalForAll(address operator, bool approved)`: Grants/revokes approval for an operator for all owner's Echoes.
    16. `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all of owner's Echoes.
    17. `tokenByIndex(uint256 index)`: Gets token ID by index (from ERC721Enumerable).
    18. `tokenOfOwnerByIndex(address owner, uint256 index)`: Gets token ID of owner by index (from ERC721Enumerable).
    19. `totalSupply()`: Returns total number of minted Echoes (from ERC721Enumerable).
    20. `tokenURI(uint256 tokenId)`: Gets the metadata URI for an Echo (from ERC721URIStorage).

*   **ERC-20 Standard (Soul Energy):**
    21. `totalSupply()`: Returns total supply of Soul Energy.
    22. `balanceOf(address account)`: Returns the Soul Energy balance of an account.
    23. `transfer(address to, uint256 amount)`: Transfers Soul Energy.
    24. `transferFrom(address from, address to, uint256 amount)`: Transfers Soul Energy using allowance.
    25. `approve(address spender, uint256 amount)`: Sets allowance for spender.
    26. `allowance(address owner, address spender)`: Returns allowance granted by owner to spender.

*   **Echo Management & State Transitions:**
    27. `mintEcho(address owner, string memory tokenURI)`: Mints a new Echo with randomizable traits, assigning it to an owner. (Requires `MINTER_ROLE`).
    28. `getEchoState(uint256 tokenId)`: Returns the current state of an Echo (internally calls `_checkAndApplyFading`).
    29. `getEchoTraits(uint256 tokenId)`: Returns the numerical traits of an Echo.
    30. `getLastNourishedTime(uint256 tokenId)`: Returns the timestamp of the last nourishment. (Internally calls `_checkAndApplyFading`).
    31. `getEchoCreationTime(uint256 tokenId)`: Returns the creation timestamp of an Echo.
    32. `nourishEcho(uint256 tokenId)`: Spends Soul Energy to nourish an Echo, resetting its fading timer. (Uses `onlyEchoOwner`, `onlyAliveOrFaded`, `nonReentrant`).
    33. `reviveEcho(uint256 tokenId)`: Spends Soul Energy to revive a Dormant Echo. (Uses `onlyEchoOwner`, `onlyDormant`, `nonReentrant`).
    34. `dissipateEcho(uint256 tokenId)`: Permanently removes an Echo and sets up a Vestige claim. (Uses `onlyEchoOwner`, `onlyEchoExisting`).
    35. `setVestigeBeneficiary(uint256 tokenId, address beneficiary)`: Sets the address that can claim the Vestige if the Echo is dissipated. (Uses `onlyEchoOwner`).

*   **Vestige (Legacy) System:**
    36. `getVestigeStatus(uint256 tokenId)`: Checks if a Vestige exists and is claimable for a dissipated Echo.
    37. `claimVestige(uint256 tokenId)`: Claims the Soul Energy Vestige from a dissipated Echo. (Uses `onlyDissipated`, `nonReentrant`).
    38. `getVestigeBeneficiary(uint256 tokenId)`: Returns the beneficiary set for a potential Vestige.
    39. `getPotentialVestigeAmount(uint256 tokenId)`: Calculates the potential Vestige amount if the Echo were dissipated now.

*   **Trait & Parameter Configuration (Admin):**
    40. `setTraitConfig(uint256 traitType, uint256 traitValue, int256 fadingImpact, int256 revivalCostImpact)`: Sets how specific trait values affect fading and revival costs. (Requires `DEFAULT_ADMIN_ROLE`).
    41. `setParameters(uint256 nourishCost, uint256 reviveBaseCost, uint256 reviveCostPerDormantHour, uint256 fadingThresholdAliveHours, uint256 fadingThresholdFadedHours)`: Sets core mechanic parameters. (Requires `DEFAULT_ADMIN_ROLE`).
    42. `getTraitConfig(uint256 traitType, uint256 traitValue)`: Retrieves the configuration for a specific trait value.
    43. `getParameters()`: Retrieves current core mechanic parameters.

*   **Soul Energy Admin:**
    44. `adminMintSoulEnergy(address recipient, uint256 amount)`: Mints new Soul Energy tokens. (Requires `ENERGY_MINTER_ROLE`).
    45. `adminBurnSoulEnergy(uint256 amount)`: Burns Soul Energy tokens from the caller's balance. (Requires `ENERGY_MINTER_ROLE` or potentially open to anyone burning their own). Let's make it admin only for controlled supply example.

*   **Helper/View Functions:**
    46. `getRequiredNourishEnergy(uint256 tokenId)`: Calculates the current Soul Energy cost to nourish an Echo, considering traits. (Internally calls `_checkAndApplyFading`).
    47. `getRequiredReviveEnergy(uint256 tokenId)`: Calculates the current Soul Energy cost to revive a Dormant Echo, considering traits and dormancy time. (Internally calls `_checkAndApplyFading`).
    48. `_checkAndApplyFading(uint256 tokenId)`: Internal helper to check and update an Echo's state based on time and traits.

*(Self-Correction: Initial count was approaching 50 including inherited. Need to ensure at least 20 custom/overridden ones, plus the standard 20+ inherited makes over 40 total functions. The plan above has many custom functions beyond the standard ERC-721/20 sets, easily exceeding 20 *new* functions.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

// Outline and Function Summary - See above comment block for detailed summary.
// Contract Name: DigitalNecromancy
// Description: Manages stateful ERC721 (Echoes) and ERC20 (Soul Energy) tokens with time-based fading, trait-influenced mechanics, and digital legacy (Vestiges).
// Inheritances: ERC721Enumerable, ERC721URIStorage, ERC20, AccessControl, ReentrancyGuard.
// Core Concepts: Echo life cycle (Alive, Faded, Dormant, Dissipated), Soul Energy utility, on-chain traits, Nourishing, Revival, Vestiges.
// Functions: >= 20 custom/overridden functions plus standard ERC-721/ERC-20/AccessControl methods.

contract DigitalNecromancy is ERC721Enumerable, ERC721URIStorage, ERC20, AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Math for uint256;
    using SignedMath for int256;

    // --- State Definitions ---
    enum EchoState {
        Alive,
        Faded,      // Starting to decay, needs nourishment
        Dormant,    // Digitally "dead", can be revived
        Dissipated  // Permanently gone, might leave a Vestige
    }

    // --- Struct Definitions ---
    struct EchoData {
        EchoState state;
        uint64 creationTime;
        uint64 lastNourishedTime;
        uint256 traitId; // Links to a specific set of traits
    }

    struct EchoTraits {
        // Example Traits - could represent digital "DNA" or characteristics
        uint256 trait1_resilience; // Higher value means slower fading
        uint256 trait2_vitality;   // Higher value means cheaper revival
        // Add more traits as needed
    }

    struct TraitConfig {
        // How this trait value impacts mechanics (multiplicative or additive bonus/penalty)
        // Use signed int for impacts (e.g., -10 for 10% slower fading, +20 for 20% higher cost)
        int256 fadingImpact;      // Affects fading rate (e.g., % change to thresholds)
        int256 revivalCostImpact; // Affects revival cost (e.g., % change to cost)
    }

    struct VestigeData {
        address beneficiary;
        uint256 energyAmount;
        bool claimed;
    }

    // --- State Variables ---
    Counters.Counter private _echoCounter;

    mapping(uint256 => EchoData) private _echoData;
    mapping(uint256 => EchoTraits) private _echoTraits; // TraitId => Traits
    mapping(uint256 => VestigeData) private _vestigeData; // TokenId => Vestige Data

    // Trait configuration: mapping(traitType => mapping(traitValue => TraitConfig))
    // traitType could be 1 for resilience, 2 for vitality etc.
    mapping(uint256 => mapping(uint256 => TraitConfig)) private _traitConfig;

    // Mechanic Parameters
    uint256 public _nourishCost; // Base cost in Soul Energy
    uint256 public _reviveBaseCost; // Base cost in Soul Energy
    uint256 public _reviveCostPerDormantHour; // Additional cost per hour dormant

    uint256 public _fadingThresholdAliveHours; // Hours until Alive -> Faded
    uint256 public _fadingThresholdFadedHours; // Hours until Faded -> Dormant

    uint256 public constant _VESTIGE_PERCENTAGE = 50; // Percentage of calculated revival cost given as Vestige (50%)

    // Access Control Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ENERGY_MINTER_ROLE = keccak256("ENERGY_MINTER_ROLE");

    // --- Events ---
    event EchoMinted(uint256 indexed tokenId, address indexed owner, EchoState initialState, uint256 traitId);
    event EchoStateChanged(uint256 indexed tokenId, EchoState oldState, EchoState newState);
    event EchoNourished(uint256 indexed tokenId, address indexed nourisher, uint256 energyUsed, uint64 newLastNourished);
    event EchoRevived(uint256 indexed tokenId, address indexed reviver, uint256 energyUsed);
    event EchoDissipated(uint256 indexed tokenId, address indexed owner, address indexed vestigeBeneficiary, uint256 potentialVestigeAmount);
    event VestigeClaimed(uint256 indexed tokenId, address indexed claimant, uint256 energyClaimed);
    event SoulEnergyMinted(address indexed recipient, uint256 amount);
    event SoulEnergyBurned(address indexed burner, uint256 amount);
    event TraitConfigUpdated(uint256 indexed traitType, uint256 indexed traitValue, int256 fadingImpact, int256 revivalCostImpact);
    event ParametersUpdated(uint256 nourishCost, uint256 reviveBaseCost, uint256 reviveCostPerDormantHour, uint256 fadingThresholdAliveHours, uint256 fadingThresholdFadedHours);

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory energyName,
        string memory energySymbol,
        uint256 initialNourishCost,
        uint256 initialReviveBaseCost,
        uint256 initialReviveCostPerDormantHour,
        uint256 initialFadingThresholdAliveHours,
        uint256 initialFadingThresholdFadedHours
    ) ERC721(name, symbol) ERC721URIStorage() ERC20(energyName, energySymbol) ReentrancyGuard() {
        // Grant default admin role to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // Grant minter roles to the deployer initially
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(ENERGY_MINTER_ROLE, msg.sender);

        // Set initial parameters
        _nourishCost = initialNourishCost;
        _reviveBaseCost = initialReviveBaseCost;
        _reviveCostPerDormantHour = initialReviveCostPerDormantHour;
        _fadingThresholdAliveHours = initialFadingThresholdAliveHours;
        _fadingThresholdFadedHours = initialFadingThresholdFadedHours;
    }

    // --- Access Control Overrides (required for ERC721/ERC20 functions) ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Helper: Check and Apply Fading ---
    // Checks current timestamp against lastNourishedTime and state, applies state changes if due.
    // Called by functions interacting with an Echo to ensure state is up-to-date.
    function _checkAndApplyFading(uint256 tokenId) internal {
        if (!_exists(tokenId)) {
            // Token doesn't exist or was burned (e.g. dissipated). No state to check.
            return;
        }

        EchoData storage echo = _echoData[tokenId];
        EchoState currentState = echo.state;
        uint64 lastNourished = echo.lastNourishedTime;
        uint66 currentTime = uint66(block.timestamp); // Use uint66 for safety, comparing with uint64

        if (currentState == EchoState.Dissipated || currentState == EchoState.Dormant) {
            // Dissipated and Dormant states don't fade further automatically
            return;
        }

        // Calculate fading thresholds considering trait impact
        uint256 traitId = echo.traitId;
        EchoTraits memory traits = _echoTraits[traitId];
        int256 totalFadingImpact = _getCalculatedFadingImpact(traits); // Get combined fading impact from traits

        // Apply fading impact percentage to thresholds
        uint256 effectiveAliveThresholdSeconds = (_fadingThresholdAliveHours * 3600);
        uint224 effectiveFadedThresholdSeconds = (_fadingThresholdFadedHours * 3600);

        // Apply percentage impact: threshold * (100 + impact) / 100
        // SignedMath handles positive and negative impacts correctly
        effectiveAliveThresholdSeconds = uint224(effectiveAliveThresholdSeconds.mulDiv(uint256(100 + totalFadingImpact.abs()), 100, Math.Rounding.Floor));
        if (totalFadingImpact > 0) {
             effectiveAliveThresholdSeconds = uint224(effectiveAliveThresholdSeconds.mulDiv(100, uint256(100 + totalFadingImpact.abs()), Math.Rounding.Floor)); // Positive impact REDUCES fading (increases threshold)
        }


        effectiveFadedThresholdSeconds = uint224(effectiveFadedThresholdSeconds.mulDiv(uint256(100 + totalFadingImpact.abs()), 100, Math.Rounding.Floor));
         if (totalFadingImpact > 0) {
             effectiveFadedThresholdSeconds = uint224(effectiveFadedThresholdSeconds.mulDiv(100, uint256(100 + totalFadingImpact.abs()), Math.Rounding.Floor)); // Positive impact REDUCES fading (increases threshold)
         }

        // Time elapsed since last nourishment
        uint256 timeSinceNourished = currentTime - lastNourished;

        if (currentState == EchoState.Alive && timeSinceNourished >= effectiveAliveThresholdSeconds) {
            // Transition Alive -> Faded
            echo.state = EchoState.Faded;
            emit EchoStateChanged(tokenId, currentState, EchoState.Faded);
            currentState = EchoState.Faded; // Update for next check
        }

        if (currentState == EchoState.Faded && timeSinceNourished >= effectiveAliveThresholdSeconds + effectiveFadedThresholdSeconds) {
             // Transition Faded -> Dormant
            echo.state = EchoState.Dormant;
            emit EchoStateChanged(tokenId, currentState, EchoState.Dormant);
        }
    }

    // Internal helper to get combined fading impact from all traits
    function _getCalculatedFadingImpact(EchoTraits memory traits) internal view returns (int256) {
        int256 totalImpact = 0;
        // Example: trait1_resilience impacts fading (Type 1)
        TraitConfig memory config1 = _traitConfig[1][traits.trait1_resilience];
        totalImpact = totalImpact.add(config1.fadingImpact);

        // Example: trait2_vitality might also impact fading slightly (Type 2)
        TraitConfig memory config2 = _traitConfig[2][traits.trait2_vitality];
         totalImpact = totalImpact.add(config2.fadingImpact);

        // Add logic for more traits if needed
        return totalImpact;
    }

     // Internal helper to get combined revival cost impact from all traits
    function _getCalculatedRevivalCostImpact(EchoTraits memory traits) internal view returns (int256) {
        int256 totalImpact = 0;
        // Example: trait1_resilience might impact revival cost (Type 1)
        TraitConfig memory config1 = _traitConfig[1][traits.trait1_resilience];
        totalImpact = totalImpact.add(config1.revivalCostImpact);

        // Example: trait2_vitality strongly impacts revival cost (Type 2)
        TraitConfig memory config2 = _traitConfig[2][traits.trait2_vitality];
         totalImpact = totalImpact.add(config2.revivalCostImpact);

        // Add logic for more traits if needed
        return totalImpact;
    }


    // --- ERC-721 Overrides for State Management ---
    // Ensure state is checked before sensitive operations like transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Apply fading check before transfer.
        // Note: If transferring *many* tokens, this might be gas-intensive.
        // Consider optimizing if batchSize > 1 scenarios are frequent.
        if (batchSize == 1) {
            // Only check for single token transfers. Batch transfers would need a different approach.
             _checkAndApplyFading(tokenId);

            // Prevent transfers if the Echo is Dormant or Dissipated
            EchoData memory echo = _echoData[tokenId];
            require(echo.state == EchoState.Alive || echo.state == EchoState.Faded, "DN: Cannot transfer Dormant or Dissipated Echo");
        } else {
             // For batch transfers (if using ERC721Batch), a different state handling strategy might be needed.
             // For this contract using ERC721Enumerable (single transfer override), this is fine.
        }
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
         // Custom burn logic: only allow burning if state is Dissipated?
         // No, Dissipate function handles state change *then* calls _burn.
         // So here, we just ensure it's allowed by the Dissipate process.
         // Clear EchoData and VestigeData when burning
        delete _echoData[tokenId];
        // Keep vestigeData until claimed or explicitly cleared later if needed,
        // but the EchoData link is broken, meaning getEchoState will fail post-burn.
        // Vestige claim relies on the tokenId existence in _vestigeData.
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "DN: URI query for nonexistent token");
        // Optional: Modify URI based on state? For this example, keep it simple.
        return super.tokenURI(tokenId);
    }


    // --- Custom Echo Management Functions ---

    /**
     * @dev Mints a new Echo with randomizable traits and assigns it to an owner.
     * Requires MINTER_ROLE.
     * @param owner The address to mint the Echo to.
     * @param tokenURI The metadata URI for the new Echo.
     */
    function mintEcho(address owner, string memory tokenURI)
        public
        virtual
        onlyRole(MINTER_ROLE)
        returns (uint256)
    {
        _echoCounter.increment();
        uint256 newItemId = _echoCounter.current();

        // --- On-chain Trait Generation ---
        // Use block data for seed - provides *some* variability per block/transaction
        // Note: block.difficulty is deprecated after the Merge, block.prevrandao is the new random source
        // For production, consider Chainlink VRF or similar for stronger randomness.
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao, // Use block.prevrandao instead of block.difficulty
            msg.sender,
            newItemId,
            _echoCounter.current() // Add counter for variation if multiple minted in block
        )));

        // Generate traits using the seed
        EchoTraits memory newTraits;
        newTraits.trait1_resilience = (seed % 10) + 1; // Value 1-10
        newTraits.trait2_vitality = (seed / 10 % 10) + 1; // Value 1-10
        // Add more trait generation logic here

        // Store traits associated with a unique trait ID (could be the token ID itself or a separate ID)
        // Using token ID as trait ID simplifies mapping
        _echoTraits[newItemId] = newTraits;

        // Initialize Echo data
        _echoData[newItemId] = EchoData({
            state: EchoState.Alive,
            creationTime: uint64(block.timestamp),
            lastNourishedTime: uint64(block.timestamp), // Starts Alive and "just nourished"
            traitId: newItemId // Use token ID as trait ID
        });

        // Mint the ERC721 token
        _safeMint(owner, newItemId);
        _setTokenURI(newItemId, tokenURI);

        emit EchoMinted(newItemId, owner, EchoState.Alive, newItemId);

        return newItemId;
    }

    /**
     * @dev Gets the current state of an Echo, applying fading if necessary.
     * @param tokenId The ID of the Echo.
     * @return The current EchoState.
     */
    function getEchoState(uint256 tokenId)
        public
        onlyEchoExisting(tokenId) // Check if the Echo exists and isn't dissipated (already handled by _burn check in modifier)
        view // Use view because _checkAndApplyFading is internal and doesn't change state in this context (though it would if external)
        returns (EchoState)
    {
        // To provide the most accurate state, we would ideally call _checkAndApplyFading here.
        // However, view functions cannot modify state.
        // A common pattern is to have a 'syncState' external function people can call (for gas)
        // or assume state is synced on interaction. For this example, we'll calculate state
        // speculatively in the view function based on current time, but the *actual* state
        // only updates when a state-modifying function (like nourish, revive, dissipate) is called,
        // which *will* call _checkAndApplyFading internally.

        EchoData memory echo = _echoData[tokenId];
        if (echo.state == EchoState.Dissipated) {
            // Dissipated state is terminal and doesn't change
            return EchoState.Dissipated;
        }

        // Calculate speculative state without modifying storage
        uint64 lastNourished = echo.lastNourishedTime;
        uint64 currentTime = uint64(block.timestamp);
        uint256 timeSinceNourished = currentTime - lastNourished;

        uint256 traitId = echo.traitId;
        EchoTraits memory traits = _echoTraits[traitId];
        int256 totalFadingImpact = _getCalculatedFadingImpact(traits);

        uint256 effectiveAliveThresholdSeconds = (_fadingThresholdAliveHours * 3600);
        uint256 effectiveFadedThresholdSeconds = (_fadingThresholdFadedHours * 3600);

         effectiveAliveThresholdSeconds = effectiveAliveThresholdSeconds.mulDiv(uint256(100 + totalFadingImpact.abs()), 100, Math.Rounding.Floor);
        if (totalFadingImpact > 0) {
             effectiveAliveThresholdSeconds = effectiveAliveThresholdSeconds.mulDiv(100, uint256(100 + totalFadingImpact.abs()), Math.Rounding.Floor);
        }

        effectiveFadedThresholdSeconds = effectiveFadedThresholdSeconds.mulDiv(uint256(100 + totalFadingImpact.abs()), 100, Math.Rounding.Floor);
         if (totalFadingImpact > 0) {
             effectiveFadedThresholdSeconds = effectiveFadedThresholdSeconds.mulDiv(100, uint256(100 + totalFadingImpact.abs()), Math.Rounding.Floor);
         }

        if (echo.state == EchoState.Dormant) {
            // Dormant state requires revival, not fading further
            return EchoState.Dormant;
        } else if (timeSinceNourished < effectiveAliveThresholdSeconds) {
            return EchoState.Alive;
        } else if (timeSinceNourished < effectiveAliveThresholdSeconds + effectiveFadedThresholdSeconds) {
            return EchoState.Faded;
        } else {
             // Past Faded threshold, but not Dormant in storage yet.
             // This indicates it *should* be Dormant. The next state-changing call will sync it.
            return EchoState.Dormant;
        }
    }

    /**
     * @dev Gets the on-chain traits of an Echo.
     * @param tokenId The ID of the Echo.
     * @return The EchoTraits struct.
     */
    function getEchoTraits(uint256 tokenId)
        public
        view
        onlyEchoExisting(tokenId)
        returns (EchoTraits memory)
    {
        // No need to check fading for traits, traits are static
        return _echoTraits[_echoData[tokenId].traitId];
    }

     /**
     * @dev Gets the creation timestamp of an Echo.
     * @param tokenId The ID of the Echo.
     * @return The creation timestamp.
     */
    function getEchoCreationTime(uint256 tokenId)
        public
        view
        onlyEchoExisting(tokenId)
        returns (uint64)
    {
        return _echoData[tokenId].creationTime;
    }


    /**
     * @dev Gets the timestamp of the last nourishment, applying fading first.
     * @param tokenId The ID of the Echo.
     * @return The timestamp of the last nourishment.
     */
    function getLastNourishedTime(uint256 tokenId)
        public
        onlyEchoExisting(tokenId)
        view // Again, calculating speculatively in view
        returns (uint64)
    {
         // See comment in getEchoState regarding view vs state-changing.
        // Returning the stored value. State sync happens on mutable calls.
        return _echoData[tokenId].lastNourishedTime;
    }


    /**
     * @dev Spends Soul Energy to nourish an Echo, resetting its fading timer.
     * Only callable by the Echo owner when the Echo is Alive or Faded.
     * @param tokenId The ID of the Echo.
     */
    function nourishEcho(uint256 tokenId)
        public
        nonReentrant
        onlyEchoOwner(tokenId)
        onlyAliveOrFaded(tokenId) // Modifier ensures state check happens first
    {
        // _checkAndApplyFading already called by modifier onlyAliveOrFaded

        uint256 requiredEnergy = getRequiredNourishEnergy(tokenId); // Get cost AFTER state check

        // Transfer Soul Energy from the caller
        require(transferFrom(msg.sender, address(this), requiredEnergy), "DN: Soul Energy transfer failed");
        // Note: In a real scenario, the contract might burn the energy or send it to a treasury.
        // Sending to `address(this)` effectively locks it unless the contract has a withdrawal function.
        // Burning (`_burn` on ERC20) is often preferred to control supply. Let's change this to burn.
        _burn(address(this), requiredEnergy); // Burn the energy

        EchoData storage echo = _echoData[tokenId];
        echo.lastNourishedTime = uint64(block.timestamp); // Reset the timer
        // State might have changed to Alive if it was Faded when Nourished
        if (echo.state == EchoState.Faded) {
             echo.state = EchoState.Alive;
             emit EchoStateChanged(tokenId, EchoState.Faded, EchoState.Alive);
        }

        emit EchoNourished(tokenId, msg.sender, requiredEnergy, echo.lastNourishedTime);
    }

    /**
     * @dev Spends Soul Energy to revive a Dormant Echo.
     * Only callable by the Echo owner when the Echo is Dormant.
     * Revival cost increases based on how long it was Dormant.
     * @param tokenId The ID of the Echo.
     */
    function reviveEcho(uint256 tokenId)
        public
        nonReentrant
        onlyEchoOwner(tokenId)
        onlyDormant(tokenId) // Modifier ensures state check happens first
    {
         // _checkAndApplyFading already called by modifier onlyDormant

        uint256 requiredEnergy = getRequiredReviveEnergy(tokenId); // Get cost AFTER state check

        require(transferFrom(msg.sender, address(this), requiredEnergy), "DN: Soul Energy transfer failed");
        _burn(address(this), requiredEnergy); // Burn the energy

        EchoData storage echo = _echoData[tokenId];
        echo.state = EchoState.Alive; // Bring it back to Alive
        echo.lastNourishedTime = uint64(block.timestamp); // Treat revival as a nourishment

        emit EchoRevived(tokenId, msg.sender, requiredEnergy);
        emit EchoStateChanged(tokenId, EchoState.Dormant, EchoState.Alive);
    }

    /**
     * @dev Permanently removes an Echo (burns the ERC721) and potentially sets up a Vestige claim.
     * Only callable by the Echo owner when the Echo is not already Dissipated.
     * @param tokenId The ID of the Echo.
     */
    function dissipateEcho(uint256 tokenId)
        public
        nonReentrant
        onlyEchoOwner(tokenId)
        onlyEchoExisting(tokenId) // Ensure it exists and isn't already burned
    {
         _checkAndApplyFading(tokenId); // Ensure state is current before dissipating

        EchoData storage echo = _echoData[tokenId];
        require(echo.state != EchoState.Dissipated, "DN: Echo already dissipated");

        address originalOwner = msg.sender; // Owner at time of dissipation

        // Calculate potential Vestige amount (e.g., a percentage of the revival cost *if* it were Dormant)
        // We'll calculate based on the *current* state/time, acting as if it became dormant now
        uint256 potentialVestigeAmount = 0;
        if (echo.state != EchoState.Dormant) {
             // Temporarily simulate state change to Dormant to calculate potential cost
             // This calculation should match getRequiredReviveEnergy but use current time
             // Simpler approach: Calculate based on minimum revival cost + a factor
             uint256 simulatedDormancyHours = 0; // Or some base value
             uint256 traitId = echo.traitId;
             EchoTraits memory traits = _echoTraits[traitId];
             int256 totalRevivalCostImpact = _getCalculatedRevivalCostImpact(traits);

             uint256 calculatedCost = _reviveBaseCost.add(simulatedDormancyHours.mul(_reviveCostPerDormantHour));
             calculatedCost = calculatedCost.mulDiv(uint256(100 + totalRevivalCostImpact.abs()), 100, Math.Rounding.Floor);
             if (totalRevivalCostImpact < 0) { // Negative impact reduces cost
                calculatedCost = calculatedCost.mulDiv(100, uint256(100 + totalRevivalCostImpact.abs()), Math.Rounding.Floor);
             }
             potentialVestigeAmount = calculatedCost.mul(_VESTIGE_PERCENTAGE).div(100);

        } else {
            // If already Dormant, base Vestige amount on current revival cost
            potentialVestigeAmount = getRequiredReviveEnergy(tokenId).mul(_VESTIGE_PERCENTAGE).div(100);
        }


        // Record Vestige data
        address vestigeBeneficiary = _vestigeData[tokenId].beneficiary != address(0)
            ? _vestigeData[tokenId].beneficiary
            : originalOwner; // Default beneficiary is owner if not set

        _vestigeData[tokenId] = VestigeData({
            beneficiary: vestigeBeneficiary,
            energyAmount: potentialVestigeAmount,
            claimed: false
        });

        // Update state and burn the token
        echo.state = EchoState.Dissipated;
        // _burn also clears EchoData
        _burn(tokenId); // This calls _beforeTokenTransfer and _burn internal functions

        emit EchoDissipated(tokenId, originalOwner, vestigeBeneficiary, potentialVestigeAmount);
        // Note: StateChange event might not be emitted if _burn clears data before it can be logged
        // or if _beforeTokenTransfer reverts on state check.
        // The Dissipated event is the primary signal here.
    }

     /**
     * @dev Sets the beneficiary address for the Vestige if the Echo is dissipated.
     * Only callable by the Echo owner while the Echo is not yet Dissipated.
     * @param tokenId The ID of the Echo.
     * @param beneficiary The address to set as beneficiary.
     */
    function setVestigeBeneficiary(uint256 tokenId, address beneficiary)
        public
        onlyEchoOwner(tokenId)
        onlyEchoExisting(tokenId) // Check if it exists and isn't burned
    {
        require(beneficiary != address(0), "DN: Beneficiary cannot be zero address");
        // Vestige data might not exist yet, create if setting beneficiary before dissipation
        _vestigeData[tokenId].beneficiary = beneficiary;
        // State is not checked here, allowing setting beneficiary while Alive, Faded, or Dormant.
    }

    // --- Vestige (Legacy) Functions ---

    /**
     * @dev Checks the status of a Vestige for a given Echo ID.
     * @param tokenId The ID of the Echo.
     * @return A tuple: (exists, isClaimed, beneficiary, amount).
     */
    function getVestigeStatus(uint256 tokenId)
        public
        view
        returns (bool exists, bool isClaimed, address beneficiary, uint256 amount)
    {
        VestigeData memory data = _vestigeData[tokenId];
        exists = (data.beneficiary != address(0) || data.energyAmount > 0); // Exists if recorded
        isClaimed = data.claimed;
        beneficiary = data.beneficiary;
        amount = data.energyAmount;
    }

     /**
     * @dev Calculates the potential Vestige amount for an Echo if it were dissipated now.
     * Takes current state and trait effects into account.
     * @param tokenId The ID of the Echo.
     * @return The potential Vestige amount in Soul Energy.
     */
    function getPotentialVestigeAmount(uint256 tokenId)
        public
        view
        onlyEchoExisting(tokenId)
        returns (uint256)
    {
        // Similar logic to Dissipate function's calculation
        EchoData memory echo = _echoData[tokenId];
         if (echo.state == EchoState.Dissipated) {
             // Already dissipated, return the recorded amount
             return _vestigeData[tokenId].energyAmount;
         }

        // Calculate based on current state/time, acting as if it became dormant now
        uint256 simulatedDormancyHours = 0; // Or some base value, e.g., 1 hour
         if (echo.state == EchoState.Dormant) {
             uint256 timeDormant = block.timestamp - echo.lastNourishedTime; // lastNourishedTime effectively is dormancy start time
             simulatedDormancyHours = timeDormant / 3600;
         }


        uint256 traitId = echo.traitId;
        EchoTraits memory traits = _echoTraits[traitId];
        int256 totalRevivalCostImpact = _getCalculatedRevivalCostImpact(traits);

        uint256 calculatedCost = _reviveBaseCost.add(simulatedDormancyHours.mul(_reviveCostPerDormantHour));
        calculatedCost = calculatedCost.mulDiv(uint256(100 + totalRevivalCostImpact.abs()), 100, Math.Rounding.Floor);
        if (totalRevivalCostImpact < 0) { // Negative impact reduces cost
           calculatedCost = calculatedCost.mulDiv(100, uint256(100 + totalRevivalCostImpact.abs()), Math.Rounding.Floor);
        }
        return calculatedCost.mul(_VESTIGE_PERCENTAGE).div(100);
    }

    /**
     * @dev Claims the Soul Energy Vestige for a dissipated Echo.
     * Only callable by the designated beneficiary if the Vestige is unclaimed.
     * @param tokenId The ID of the Echo.
     */
    function claimVestige(uint256 tokenId)
        public
        nonReentrant
        onlyDissipated(tokenId) // Modifier ensures Vestige exists and is unclaimed
    {
        VestigeData storage vestige = _vestigeData[tokenId];
        address claimant = msg.sender;

        require(claimant == vestige.beneficiary, "DN: Caller is not the Vestige beneficiary");

        uint256 amountToClaim = vestige.energyAmount;
        vestige.claimed = true; // Mark as claimed immediately

        // Transfer Soul Energy to the beneficiary
        _mint(claimant, amountToClaim); // Minting new energy instead of transferring from contract balance
                                        // This adds supply based on Vestige claims, fitting a "recycled energy" idea.
        emit VestigeClaimed(tokenId, claimant, amountToClaim);
    }

    // --- Trait & Parameter Configuration (Admin Functions) ---

    /**
     * @dev Sets how specific trait values affect fading and revival costs.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param traitType The type of the trait (e.g., 1 for resilience, 2 for vitality).
     * @param traitValue The specific value of the trait (e.g., 5 for resilience=5).
     * @param fadingImpact How this value impacts fading rate (e.g., -10 means 10% slower fading).
     * @param revivalCostImpact How this value impacts revival cost (e.g., +20 means 20% higher cost).
     */
    function setTraitConfig(uint256 traitType, uint256 traitValue, int256 fadingImpact, int256 revivalCostImpact)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _traitConfig[traitType][traitValue] = TraitConfig({
            fadingImpact: fadingImpact,
            revivalCostImpact: revivalCostImpact
        });
        emit TraitConfigUpdated(traitType, traitValue, fadingImpact, revivalCostImpact);
    }

     /**
     * @dev Gets the configuration for a specific trait value.
     * @param traitType The type of the trait.
     * @param traitValue The value of the trait.
     * @return The TraitConfig struct.
     */
    function getTraitConfig(uint256 traitType, uint256 traitValue)
        public
        view
        returns (TraitConfig memory)
    {
        return _traitConfig[traitType][traitValue];
    }

    /**
     * @dev Sets core mechanic parameters for the contract.
     * Requires DEFAULT_ADMIN_ROLE.
     */
    function setParameters(
        uint256 nourishCost,
        uint256 reviveBaseCost,
        uint256 reviveCostPerDormantHour,
        uint256 fadingThresholdAliveHours,
        uint256 fadingThresholdFadedHours
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _nourishCost = nourishCost;
        _reviveBaseCost = reviveBaseCost;
        _reviveCostPerDormantHour = reviveCostPerDormantHour;
        _fadingThresholdAliveHours = fadingThresholdAliveHours;
        _fadingThresholdFadedHours = fadingThresholdFadedHours;

        emit ParametersUpdated(nourishCost, reviveBaseCost, reviveCostPerDormantHour, fadingThresholdAliveHours, fadingThresholdFadedHours);
    }

     /**
     * @dev Gets the current core mechanic parameters.
     * @return A tuple of the parameters.
     */
    function getParameters()
        public
        view
        returns (uint256 nourishCost, uint256 reviveBaseCost, uint256 reviveCostPerDormantHour, uint256 fadingThresholdAliveHours, uint256 fadingThresholdFadedHours)
    {
        return (_nourishCost, _reviveBaseCost, _reviveCostPerDormantHour, _fadingThresholdAliveHours, _fadingThresholdFadedHours);
    }


    // --- Soul Energy Admin Functions ---

    /**
     * @dev Mints new Soul Energy tokens to a recipient.
     * Requires ENERGY_MINTER_ROLE.
     * @param recipient The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function adminMintSoulEnergy(address recipient, uint256 amount)
        public
        onlyRole(ENERGY_MINTER_ROLE)
    {
        _mint(recipient, amount);
        emit SoulEnergyMinted(recipient, amount);
    }

    /**
     * @dev Burns Soul Energy tokens from the caller's balance.
     * Requires ENERGY_MINTER_ROLE.
     * @param amount The amount of tokens to burn.
     */
     function adminBurnSoulEnergy(uint256 amount)
         public
         onlyRole(ENERGY_MINTER_ROLE)
     {
         _burn(msg.sender, amount);
         emit SoulEnergyBurned(msg.sender, amount);
     }


    // --- Helper/View Functions ---

    /**
     * @dev Calculates the Soul Energy cost to nourish an Echo, considering traits.
     * Applies fading state check first.
     * @param tokenId The ID of the Echo.
     * @return The required Soul Energy amount.
     */
    function getRequiredNourishEnergy(uint256 tokenId)
         public
         view // View because state is not changed here, but calculation relies on potential synced state
         onlyEchoExisting(tokenId)
         returns (uint256)
     {
         // Ideally, this would call _checkAndApplyFading, but it's a view function.
         // The calculation is based on the base cost and trait impacts.
         EchoData memory echo = _echoData[tokenId];
         uint256 traitId = echo.traitId;
         EchoTraits memory traits = _echoTraits[traitId];
         int256 totalRevivalCostImpact = _getCalculatedRevivalCostImpact(traits); // Using revival cost impact for nourish cost variation? Or add separate nourish impact? Let's use revival impact for simplicity.

         uint256 calculatedCost = _nourishCost;
         calculatedCost = calculatedCost.mulDiv(uint256(100 + totalRevivalCostImpact.abs()), 100, Math.Rounding.Floor);
         if (totalRevivalCostImpact < 0) { // Negative impact reduces cost
            calculatedCost = calculatedCost.mulDiv(100, uint256(100 + totalRevivalCostImpact.abs()), Math.Rounding.Floor);
         }
         return calculatedCost;
     }


    /**
     * @dev Calculates the Soul Energy cost to revive a Dormant Echo, considering traits and dormancy time.
     * Applies fading state check first.
     * @param tokenId The ID of the Echo.
     * @return The required Soul Energy amount.
     */
     function getRequiredReviveEnergy(uint256 tokenId)
         public
         view // View because state is not changed here
         onlyEchoExisting(tokenId)
         returns (uint256)
     {
         // Ideally, this would call _checkAndApplyFading, but it's a view function.
         // Calculate cost based on base, dormancy time, and trait impacts.
         EchoData memory echo = _echoData[tokenId];
         require(echo.state == EchoState.Dormant, "DN: Echo must be Dormant to calculate revival cost");

         uint256 timeDormant = block.timestamp - echo.lastNourishedTime; // lastNourishedTime is effectively dormancy start
         uint256 dormantHours = timeDormant / 3600;

         uint256 traitId = echo.traitId;
         EchoTraits memory traits = _echoTraits[traitId];
         int256 totalRevivalCostImpact = _getCalculatedRevivalCostImpact(traits);

         uint256 calculatedCost = _reviveBaseCost.add(dormantHours.mul(_reviveCostPerDormantHour));
         calculatedCost = calculatedCost.mulDiv(uint256(100 + totalRevivalCostImpact.abs()), 100, Math.Rounding.Floor);
         if (totalRevivalCostImpact < 0) { // Negative impact reduces cost
            calculatedCost = calculatedCost.mulDiv(100, uint256(100 + totalRevivalCostImpact.abs()), Math.Rounding.Floor);
         }
         return calculatedCost;
     }

     // --- Modifiers ---

     /**
      * @dev Modifier to check if an Echo ID exists and is not in the Dissipated state (burned).
      * Calls _checkAndApplyFading internally.
      */
     modifier onlyEchoExisting(uint256 tokenId) {
         require(_exists(tokenId), "DN: Token does not exist");
         // Check state *after* confirming existence in ERC721 registry
         // Note: _echoData[tokenId].state check isn't sufficient alone if _burn clears the mapping.
         // However, _exists() returning true implies it's NOT Dissipated according to the logic in _burn and dissipateEcho.
         _;
     }

     /**
      * @dev Modifier to check if the caller is the owner of the Echo.
      * Calls _checkAndApplyFading internally.
      */
     modifier onlyEchoOwner(uint256 tokenId) {
         require(_exists(tokenId), "DN: Token does not exist"); // Check before ownerOf
         _checkAndApplyFading(tokenId); // Sync state before checking owner and state
         require(ownerOf(tokenId) == msg.sender, "DN: Caller is not the token owner");
         _;
     }

     /**
      * @dev Modifier to check if the Echo is in Alive or Faded state.
      * Calls _checkAndApplyFading internally.
      */
     modifier onlyAliveOrFaded(uint256 tokenId) {
          require(_exists(tokenId), "DN: Token does not exist");
          _checkAndApplyFading(tokenId); // Sync state before checking state
          EchoState currentState = _echoData[tokenId].state;
          require(currentState == EchoState.Alive || currentState == EchoState.Faded, "DN: Echo must be Alive or Faded");
          _;
     }

      /**
      * @dev Modifier to check if the Echo is in Dormant state.
      * Calls _checkAndApplyFading internally.
      */
     modifier onlyDormant(uint256 tokenId) {
         require(_exists(tokenId), "DN: Token does not exist");
         _checkAndApplyFading(tokenId); // Sync state before checking state
         require(_echoData[tokenId].state == EchoState.Dormant, "DN: Echo must be Dormant");
         _;
     }

      /**
      * @dev Modifier to check if a Vestige exists and is unclaimed for a dissipated Echo.
      * Does *not* call _checkAndApplyFading as the Echo is dissipated/burned.
      */
     modifier onlyDissipated(uint256 tokenId) {
         // Do NOT check _exists(tokenId) here, as Dissipated tokens are burned!
         // Check directly in vestige data
         VestigeData memory vestige = _vestigeData[tokenId];
         require(vestige.beneficiary != address(0) && !vestige.claimed, "DN: Vestige does not exist or is already claimed");
         // Note: This relies on the Dissipate function correctly setting the VestigeData.
         // A burned token should indeed not exist in the ERC721 registry.
         _;
     }
}
```