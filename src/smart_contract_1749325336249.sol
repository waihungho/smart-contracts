Okay, let's design a smart contract around the concept of "Programmable Digital Artifacts". These artifacts will be NFTs (ERC721-like), but with dynamic properties, internal state, and the ability to perform actions or grant benefits based on resources locked within them or bonded to them.

We'll incorporate concepts like:
1.  **Dynamic NFTs:** Properties change based on interactions.
2.  **Multi-Resource Management:** Holding different ERC20 tokens ("Essence") within the artifact.
3.  **Token Bonding/Staking:** Locking specific ERC20 tokens to activate states or abilities.
4.  **Time-Based Mechanics:** Bond duration, time locks for abilities.
5.  **State Transitions:** Artifacts can be in different states influencing their behavior.
6.  **Conditional Abilities:** Functions that can only be called if the artifact meets certain criteria (level, state, held essence, bond).
7.  **Evolution/Progression:** Artifacts can level up or evolve, permanently changing properties.
8.  **Admin Configuration:** Whitelisting allowed tokens, setting costs/parameters.

This avoids directly copying standard ERC20/ERC721 or simple DeFi vaults/farms. We'll implement the core logic for the dynamic state and abilities, assuming standard ERC721 interfaces for transferability (though we'll list the standard ERC721 functions as part of the count and structure).

---

**Outline and Function Summary**

This contract, `ProgrammableArtifacts`, manages dynamic digital assets (Artifacts) which function as enhanced NFTs.

**Core Concepts:**

*   **Artifacts:** Unique tokens (like ERC721) with mutable properties.
*   **Essence:** ERC20 tokens held *within* an Artifact, used for consumption (leveling, abilities).
*   **Bonding:** Locking specific ERC20 tokens *to* an Artifact for a set duration to activate states and abilities.
*   **States:** Artifacts can be in `Idle`, `Bonded`, or `Evolved` states, affecting available actions.
*   **Abilities:** Special functions callable by the Artifact's owner if state, level, and resource requirements are met.
*   **Progression:** Artifacts can level up and potentially Evolve by consuming Essence or meeting conditions.

**Data Structures:**

*   `ArtifactState`: Enum (`Idle`, `Bonded`, `Evolved`)
*   `BondInfo`: Struct storing details of a current token bond (`token`, `amount`, `endTime`).
*   `ArtifactData`: Struct holding all dynamic properties (`state`, `level`, `affinityScore`, `essence`, `bond`).

**Functions (Total: 30+)**

*   **Admin/Configuration (5):**
    1.  `constructor`: Deploys the contract, sets owner.
    2.  `addWhitelistedEssenceToken`: Allows owner to whitelist ERC20s usable as Essence.
    3.  `removeWhitelistedEssenceToken`: Allows owner to delist Essence tokens.
    4.  `addWhitelistedBondToken`: Allows owner to whitelist ERC20s usable for Bonding.
    5.  `removeWhitelistedBondToken`: Allows owner to delist Bond tokens.
    6.  `setBaseLevelUpCost`: Sets the base amount of Essence required to level up.
    7.  `setAbilityCost`: Sets the Essence cost for a specific ability type.
    8.  `setEvolutionCost`: Sets parameters required for evolution (e.g., Essence amount, minimum level).
*   **Artifact Management (4):**
    9.  `mintArtifact`: Creates a new Artifact NFT, assigns initial properties.
    10. `burnArtifact`: Destroys an Artifact (only by owner/approved).
    11. `transferFrom` (Standard ERC721): Transfers ownership of an Artifact.
    12. `safeTransferFrom` (Standard ERC721): Transfers ownership safely.
*   **Resource Management (4):**
    13. `chargeEssence`: Deposit whitelisted ERC20 Essence into an Artifact (requires prior approval).
    14. `drainEssence`: Withdraw whitelisted ERC20 Essence from an Artifact (by owner).
    15. `bondToken`: Lock a whitelisted ERC20 token to an Artifact for a duration (requires prior approval).
    16. `unbondToken`: Release bonded token *after* the lock period ends.
*   **Progression & State (3):**
    17. `levelUpArtifact`: Increase Artifact level by consuming Essence, improves effectiveness.
    18. `evolveArtifact`: Transform Artifact state permanently to Evolved, requires specific conditions (level, essence, maybe bond).
    19. `updateAffinity`: Simple function to manually adjust affinity (could be triggered by other actions).
*   **Abilities (3+):**
    20. `activateShieldAbility`: Consumes Essence/Bond time, provides hypothetical "shield" benefit (represented by event/state). Requires Bonded state.
    21. `generateResourceAbility`: Consumes Essence, provides hypothetical "resource" benefit (represented by event). Requires Evolved state.
    22. `scanEnvironmentAbility`: View function, provides information based on Artifact state/level (no cost). Available in any non-Evolving state.
    23. `checkAbilityEligibility`: View function, checks if an artifact *can* use a specific ability now.
*   **Query Functions (7+):**
    24. `getArtifactProperties`: Get core mutable properties of an Artifact.
    25. `getArtifactEssence`: Get the amount of a specific Essence token held by an Artifact.
    26. `getArtifactBondInfo`: Get details of the active bond on an Artifact.
    27. `getArtifactState`: Get the current state of an Artifact.
    28. `balanceOf` (Standard ERC721): Get the number of Artifacts owned by an address.
    29. `ownerOf` (Standard ERC721): Get the owner of an Artifact.
    30. `getApproved` (Standard ERC721): Get the address approved for a single Artifact.
    31. `isApprovedForAll` (Standard ERC721): Check if an operator is approved for all of an owner's Artifacts.
    32. `calculateLevelUpCost`: View function to calculate the current cost to level up.
    33. `getEvolutionCost`: View function to retrieve evolution requirements.
    34. `getAbilityCost`: View function to retrieve the Essence cost for a specific ability type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although uint256 largely handles this, good practice

// Note: This contract manually implements core ERC721 state management
// (ownerOf, balanceOf, approved, approvedForAll) and functions (transferFrom, safeTransferFrom, etc.)
// instead of inheriting a full standard library implementation like OpenZeppelin's ERC721
// to demonstrate the core mechanics counting towards the 20+ functions without being a direct duplicate.
// A production contract would typically inherit from a standard library for safety and compliance.

/**
 * @title ProgrammableArtifacts
 * @dev Manages dynamic, stateful digital artifacts with resource management and conditional abilities.
 *
 * Outline:
 * - Admin/Configuration functions (Whitelist tokens, set costs)
 * - Artifact Management (Mint, Burn, Transfer - ERC721 core)
 * - Resource Management (Charge/Drain Essence, Bond/Unbond Tokens)
 * - Progression & State (Level Up, Evolve, Affinity)
 * - Abilities (Conditional actions tied to state, level, resources)
 * - Query Functions (Retrieve artifact data, costs, eligibility)
 *
 * Concepts: Dynamic NFTs, Multi-resource management (Essence), Token Bonding, Time-based mechanics,
 * State transitions, Conditional logic for abilities, Progression/Evolution.
 */
contract ProgrammableArtifacts is Ownable, ReentrancyGuard, IERC721, IERC721Receiver {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // ERC721 State (Manually implemented for demonstration, use OpenZeppelin in prod)
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Artifact Specific Data
    enum ArtifactState { Idle, Bonded, Evolved }

    struct BondInfo {
        IERC20 token;
        uint256 amount;
        uint66 lockEndTime; // Using uint66 for timestamp is gas efficient
        bool isActive;
    }

    struct ArtifactData {
        ArtifactState state;
        uint16 level; // Max level ~65535
        int32 affinityScore; // Can be positive or negative
        mapping(address => uint256) essence; // ERC20 address => amount
        BondInfo bond;
        bool hasEvolved; // Flag to prevent multiple evolutions
    }

    mapping(uint256 => ArtifactData) private _artifacts;

    // Configuration
    mapping(address => bool) private _whitelistedEssenceTokens;
    mapping(address => bool) private _whitelistedBondTokens;
    uint256 public baseLevelUpCost = 100; // Base cost (in some unit of Essence)
    mapping(uint8 => uint256) private _abilityCosts; // AbilityType => cost
    struct EvolutionRequirements {
        uint16 minLevel;
        uint256 requiredEssenceAmount; // Total sum of specified essence types
        // Add specific required essence types if needed, e.g. mapping(address => uint256) requiredEssenceBreakdown;
    }
    EvolutionRequirements public evolutionReqs;

    // Ability Types (Using uint8 as identifier for mapping)
    uint8 constant public ABILITY_SHIELD = 1;
    uint8 constant public ABILITY_GENERATE = 2;
    uint8 constant public ABILITY_SCAN = 3; // Mostly view/pure, but included for structure

    // --- Events ---
    event ArtifactMinted(address indexed owner, uint256 indexed tokenId, ArtifactState initialState);
    event EssenceCharged(uint256 indexed tokenId, address indexed token, uint256 amount);
    event EssenceDrained(uint256 indexed tokenId, address indexed token, uint256 amount);
    event TokenBonded(uint256 indexed tokenId, address indexed token, uint256 amount, uint66 lockEndTime);
    event TokenUnbonded(uint256 indexed tokenId, address indexed token, uint256 amount);
    event ArtifactLeveledUp(uint256 indexed tokenId, uint16 newLevel, uint256 costPaid);
    event ArtifactEvolved(uint256 indexed tokenId, uint16 finalLevel, int32 finalAffinity);
    event AffinityUpdated(uint256 indexed tokenId, int32 newAffinity);
    event AbilityActivated(uint256 indexed tokenId, uint8 abilityType, uint256 costPaid);

    // ERC721 Events (Standard)
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Errors ---
    error NotOwnerOrApproved(uint256 tokenId);
    error InvalidTokenId();
    error NotWhitelistedEssenceToken(address token);
    error NotWhitelistedBondToken(address token);
    error InsufficientEssence(address token, uint256 required, uint256 available);
    error InsufficientBondedTimeRemaining(uint64 required, uint64 available);
    error BondingActive(uint256 tokenId);
    error BondingNotActive(uint256 tokenId);
    error BondLockStillActive(uint66 lockEndTime);
    error ArtifactNotIdle(uint256 tokenId);
    error ArtifactNotBonded(uint256 tokenId);
    error ArtifactNotEvolved(uint256 tokenId);
    error ArtifactAlreadyEvolved(uint256 tokenId);
    error EvolutionRequirementsNotMet(string reason);
    error InvalidAbilityType(uint8 abilityType);
    error AbilityConditionsNotMet(string reason);

    // --- Modifiers ---
    modifier onlyArtifactOwner(uint256 tokenId) {
        if (msg.sender != _tokenOwners[tokenId]) {
            revert NotOwnerOrApproved(tokenId); // Simplified check, standard includes approved addresses/operators
        }
        _;
    }

    // --- Constructor ---
    constructor(address ownerAddress) Ownable(ownerAddress) {
        // Initial evolution requirements example
        evolutionReqs = EvolutionRequirements({
            minLevel: 5,
            requiredEssenceAmount: 500 // Example total essence needed
            // Add specific token breakdown if needed
        });
         // Example base ability costs
        _abilityCosts[ABILITY_SHIELD] = 50; // Cost in a predefined essence unit
        _abilityCosts[ABILITY_GENERATE] = 100;
         _abilityCosts[ABILITY_SCAN] = 0; // Scan is free view function
    }

    // --- Admin/Configuration Functions ---

    /**
     * @dev Adds a token address to the list of allowed Essence tokens.
     * @param tokenAddress The address of the ERC20 token.
     */
    function addWhitelistedEssenceToken(address tokenAddress) external onlyOwner {
        _whitelistedEssenceTokens[tokenAddress] = true;
    }

    /**
     * @dev Removes a token address from the list of allowed Essence tokens.
     * @param tokenAddress The address of the ERC20 token.
     */
    function removeWhitelistedEssenceToken(address tokenAddress) external onlyOwner {
        _whitelistedEssenceTokens[tokenAddress] = false;
    }

    /**
     * @dev Adds a token address to the list of allowed Bond tokens.
     * @param tokenAddress The address of the ERC20 token.
     */
    function addWhitelistedBondToken(address tokenAddress) external onlyOwner {
        _whitelistedBondTokens[tokenAddress] = true;
    }

    /**
     * @dev Removes a token address from the list of allowed Bond tokens.
     * @param tokenAddress The address of the ERC20 token.
     */
    function removeWhitelistedBondToken(address tokenAddress) external onlyOwner {
        _whitelistedBondTokens[tokenAddress] = false;
    }

    /**
     * @dev Sets the base cost for leveling up an artifact. Cost scales with level.
     * @param _baseCost The new base level up cost.
     */
    function setBaseLevelUpCost(uint256 _baseCost) external onlyOwner {
        baseLevelUpCost = _baseCost;
    }

     /**
     * @dev Sets the Essence cost for a specific ability type.
     * @param abilityType The identifier for the ability (e.g., ABILITY_SHIELD).
     * @param cost The new Essence cost for the ability.
     */
    function setAbilityCost(uint8 abilityType, uint256 cost) external onlyOwner {
         require(abilityType > 0 && abilityType <= ABILITY_SCAN, "Invalid ability type");
        _abilityCosts[abilityType] = cost;
    }

     /**
     * @dev Sets the requirements for artifact evolution.
     * @param minLevel The minimum level required to evolve.
     * @param requiredEssenceAmount The total amount of essence required (sum across types).
     */
    function setEvolutionCost(uint16 minLevel, uint256 requiredEssenceAmount) external onlyOwner {
        evolutionReqs = EvolutionRequirements({
            minLevel: minLevel,
            requiredEssenceAmount: requiredEssenceAmount
        });
    }


    // --- Artifact Management (Core ERC721 Functions - Logic sketched) ---

    /**
     * @dev Mints a new artifact and assigns it to an owner.
     * @param to The address to mint the artifact to.
     */
    function mintArtifact(address to) external onlyOwner nonReentrant {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(to, newItemId);

        _artifacts[newItemId] = ArtifactData({
            state: ArtifactState.Idle,
            level: 1,
            affinityScore: 0,
            essence: new mapping(address => uint256)(), // Initialize empty mapping
            bond: BondInfo({
                token: IERC20(address(0)), // Zero address indicates no bond
                amount: 0,
                lockEndTime: 0,
                isActive: false
            }),
            hasEvolved: false
        });

        emit ArtifactMinted(to, newItemId, ArtifactState.Idle);
    }

    /**
     * @dev Burns an artifact, removing it from existence.
     * @param tokenId The ID of the artifact to burn.
     */
    function burnArtifact(uint256 tokenId) external nonReentrant {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || getApproved(tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "ERC721: caller is not token owner or approved");

        // Refund any bonded tokens or essence before burning (example - could also be lost)
        _safeDrainEssence(tokenId);
        _safeUnbondToken(tokenId); // Attempt to unbond first

        _burn(tokenId);
    }


    // ERC721 standard transfer functions (Logic sketched, rely on mappings)
    // In a real contract, inherit OpenZeppelin's ERC721 or implement fully.

    function transferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrant {
        // Check permissions (owner, approved, operator)
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override nonReentrant {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override nonReentrant {
         // Check permissions (owner, approved, operator)
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transfer(from, to, tokenId);

        // Check if receiver is a smart contract and implements ERC721Receiver
        if (to.code.length > 0) {
            require(
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    // ERC721 standard approval functions (Logic sketched)
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _setApprovalForAll(msg.sender, operator, approved);
    }


    // --- Resource Management Functions ---

    /**
     * @dev Charges Essence (ERC20) into an artifact. Requires prior ERC20 approval.
     * @param tokenId The ID of the artifact.
     * @param tokenAddress The address of the Essence token.
     * @param amount The amount of Essence to charge.
     */
    function chargeEssence(uint256 tokenId, address tokenAddress, uint256 amount)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        require(_whitelistedEssenceTokens[tokenAddress], NotWhitelistedEssenceToken(tokenAddress));
        require(amount > 0, "Amount must be greater than 0");

        // Transfer tokens from sender to this contract
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "ERC20 transfer failed"); // Standard ERC20 check

        // Verify the transfer occurred
        uint256 transferredAmount = token.balanceOf(address(this)).sub(balanceBefore);
        require(transferredAmount == amount, "ERC20 transfer amount mismatch");


        _artifacts[tokenId].essence[tokenAddress] = _artifacts[tokenId].essence[tokenAddress].add(amount);

        emit EssenceCharged(tokenId, tokenAddress, amount);
    }

    /**
     * @dev Drains Essence (ERC20) from an artifact back to the owner.
     * @param tokenId The ID of the artifact.
     * @param tokenAddress The address of the Essence token.
     * @param amount The amount of Essence to drain.
     */
    function drainEssence(uint256 tokenId, address tokenAddress, uint256 amount)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        require(_whitelistedEssenceTokens[tokenAddress], NotWhitelistedEssenceToken(tokenAddress));
        require(amount > 0, "Amount must be greater than 0");
        require(_artifacts[tokenId].essence[tokenAddress] >= amount, InsufficientEssence(tokenAddress, amount, _artifacts[tokenId].essence[tokenAddress]));

        _artifacts[tokenId].essence[tokenAddress] = _artifacts[tokenId].essence[tokenAddress].sub(amount);

        // Transfer tokens from this contract to sender
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(msg.sender, amount);
        require(success, "ERC20 transfer back failed"); // Standard ERC20 check

        emit EssenceDrained(tokenId, tokenAddress, amount);
    }

    /**
     * @dev Bonds a whitelisted ERC20 token to an artifact for a duration, activating Bonded state.
     * Requires prior ERC20 approval. Cannot bond if already bonded.
     * @param tokenId The ID of the artifact.
     * @param tokenAddress The address of the Bond token.
     * @param amount The amount of token to bond.
     * @param duration Seconds the token will be locked.
     */
    function bondToken(uint256 tokenId, address tokenAddress, uint256 amount, uint64 duration)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        require(_whitelistedBondTokens[tokenAddress], NotWhitelistedBondToken(tokenAddress));
        require(amount > 0, "Amount must be greater than 0");
        require(duration > 0, "Duration must be greater than 0");
        require(_artifacts[tokenId].state != ArtifactState.Bonded, BondingActive(tokenId));
        require(_artifacts[tokenId].state != ArtifactState.Evolved, "Cannot bond to evolved artifact"); // Example constraint

        // Transfer tokens from sender to this contract
        IERC20 token = IERC20(tokenAddress);
        uint256 balanceBefore = token.balanceOf(address(this));
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "ERC20 transfer failed");

        uint256 transferredAmount = token.balanceOf(address(this)).sub(balanceBefore);
        require(transferredAmount == amount, "ERC20 transfer amount mismatch");

        uint66 lockEndTime = uint66(block.timestamp.add(duration));

        _artifacts[tokenId].bond = BondInfo({
            token: token,
            amount: amount,
            lockEndTime: lockEndTime,
            isActive: true
        });
        _artifacts[tokenId].state = ArtifactState.Bonded;

        emit TokenBonded(tokenId, tokenAddress, amount, lockEndTime);
    }

    /**
     * @dev Unbonds the token from an artifact after the lock period has ended.
     * @param tokenId The ID of the artifact.
     */
    function unbondToken(uint256 tokenId)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];
        require(artifact.state == ArtifactState.Bonded, BondingNotActive(tokenId));
        require(block.timestamp >= artifact.bond.lockEndTime, BondLockStillActive(artifact.bond.lockEndTime));

        BondInfo memory currentBond = artifact.bond;

        // Reset bond info
        artifact.bond.isActive = false;
        artifact.bond.amount = 0;
        artifact.bond.lockEndTime = 0;
        artifact.bond.token = IERC20(address(0));

        // Revert state based on evolution status
        artifact.state = artifact.hasEvolved ? ArtifactState.Evolved : ArtifactState.Idle;

        // Transfer tokens back to owner
        IERC20 token = currentBond.token;
        bool success = token.transfer(msg.sender, currentBond.amount);
        require(success, "ERC20 transfer back failed");

        emit TokenUnbonded(tokenId, address(token), currentBond.amount);
    }

    // Helper function to safely drain all essence (used before burn/unbond if applicable)
    function _safeDrainEssence(uint256 tokenId) internal {
         require(_exists(tokenId), InvalidTokenId());
         // Iterate through whitelisted tokens and drain available essence
         // (Requires storing list of active essence types per artifact or iterating global list)
         // Simplified for this example: requires explicit token address
         // A better implementation would track which tokens are held per artifact.
         // For this example, we'll emit a warning or skip if essence isn't drained explicitly first.
    }

     // Helper function to safely unbond token (used before burn)
    function _safeUnbondToken(uint256 tokenId) internal {
         require(_exists(tokenId), InvalidTokenId());
         ArtifactData storage artifact = _artifacts[tokenId];
         if (artifact.state == ArtifactState.Bonded && block.timestamp >= artifact.bond.lockEndTime) {
             // If bond is active and expired, unbond
             BondInfo memory currentBond = artifact.bond;
             artifact.bond.isActive = false;
             artifact.bond.amount = 0;
             artifact.bond.lockEndTime = 0;
             artifact.bond.token = IERC20(address(0));
             artifact.state = artifact.hasEvolved ? ArtifactState.Evolved : ArtifactState.Idle;
             // Transfer tokens back (assuming owner is msg.sender in burn, which it is checked before calling _burn)
             bool success = currentBond.token.transfer(ownerOf(tokenId), currentBond.amount);
             require(success, "ERC20 transfer back failed during burn");
             emit TokenUnbonded(tokenId, address(currentBond.token), currentBond.amount);
         } else if (artifact.state == ArtifactState.Bonded) {
             // If bond is active but not expired, tokens might be lost or need admin recovery
             emit TokenUnbonded(tokenId, address(artifact.bond.token), 0); // Indicate bond was active but not released
         }
    }

    // --- Progression & State Functions ---

    /**
     * @dev Levels up the artifact by consuming Essence. Cost scales with level.
     * Requires the artifact to be Idle or Bonded (not Evolved).
     * @param tokenId The ID of the artifact.
     * @param essenceToken Address of the essence token to consume.
     */
    function levelUpArtifact(uint256 tokenId, address essenceToken)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];
        require(artifact.state != ArtifactState.Evolved, "Evolved artifacts cannot level up further"); // Or allow different progression

        uint256 currentCost = calculateLevelUpCost(tokenId);
        require(_artifacts[tokenId].essence[essenceToken] >= currentCost, InsufficientEssence(essenceToken, currentCost, _artifacts[tokenId].essence[essenceToken]));

        _artifacts[tokenId].essence[essenceToken] = _artifacts[tokenId].essence[essenceToken].sub(currentCost);
        _artifacts[tokenId].level = _artifacts[tokenId].level.add(1);

        emit ArtifactLeveledUp(tokenId, artifact.level, currentCost);
    }

    /**
     * @dev Evolves the artifact permanently, changing its state and potentially properties.
     * Requires specific conditions (level, essence, maybe state). Can only evolve once.
     * @param tokenId The ID of the artifact.
     */
    function evolveArtifact(uint256 tokenId)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];
        require(!artifact.hasEvolved, ArtifactAlreadyEvolved(tokenId));

        // Check evolution requirements
        require(artifact.level >= evolutionReqs.minLevel, EvolutionRequirementsNotMet("Min level not met"));
        // Simplified essence check: sum all essence types and compare to total required amount
        // A more complex check would require specific amounts of specific essence types
        uint256 totalEssence = 0;
        // Need to iterate through whitelisted essence tokens to sum up.
        // This iteration might be gas-intensive if the whitelist is very large.
        // A better design tracks essence types actually held by the artifact.
        // For demonstration, we'll assume we can somehow get the list or check a few main ones.
        // Let's skip the explicit iteration here for simplicity and assume totalEssence is calculated
        // based on predefined "primary" essence types or a system knows which ones are relevant.
        // For a proper check, you'd need a state variable listing the essence types held by the artifact.
        // E.g., `address[] internal _heldEssenceTypes[uint256 tokenId];`
        // And update this list in chargeEssence/drainEssence.
        // Then iterate `_heldEssenceTypes[tokenId]` here.

        // For this example, let's assume a simplified check that sums up a couple of specific essence types
        // (replace with actual logic iterating _heldEssenceTypes if implemented)
        address exampleEssence1 = address(0x...); // Replace with actual token addresses
        address exampleEssence2 = address(0x...); // Replace with actual token addresses
        totalEssence = artifact.essence[exampleEssence1].add(artifact.essence[exampleEssence2]); // Example

        require(totalEssence >= evolutionReqs.requiredEssenceAmount, EvolutionRequirementsNotMet("Insufficient total essence"));
        // Add other potential evolution conditions (e.g., must be Bonded for X time, must have specific affinity)
        // Example: require(artifact.state == ArtifactState.Bonded && block.timestamp - artifact.bond.lockEndTime >= 1 days, "Must be bonded and bond ended recently"); // Example

        // Consume required essence (simplified: consumes the total amount from *any* held essence)
        // A proper implementation would specify which essence types are consumed.
        // Let's consume from exampleEssence1 first, then exampleEssence2 if needed.
         if (totalEssence > 0) {
             uint256 consumed = 0;
             uint256 toConsume = evolutionReqs.requiredEssenceAmount;
             uint256 available1 = artifact.essence[exampleEssence1];
             uint256 consume1 = available1 > toConsume ? toConsume : available1;
             artifact.essence[exampleEssence1] = available1.sub(consume1);
             consumed = consumed.add(consume1);
             toConsume = toConsume.sub(consume1);

             if (toConsume > 0) {
                uint256 available2 = artifact.essence[exampleEssence2];
                uint256 consume2 = available2 > toConsume ? toConsume : available2;
                artifact.essence[exampleEssence2] = available2.sub(consume2);
                consumed = consumed.add(consume2);
                toConsume = toConsume.sub(consume2);
             }
             require(consumed == evolutionReqs.requiredEssenceAmount, "Failed to consume exact evolution essence"); // Should be guaranteed by totalEssence check
         }


        // Transition state and mark as evolved
        artifact.state = ArtifactState.Evolved;
        artifact.hasEvolved = true;
        // Optionally reset level/affinity or apply modifiers
        // artifact.level = 1; // Start new progression tier
        // artifact.affinityScore = artifact.affinityScore.add(100); // Boost affinity

        emit ArtifactEvolved(tokenId, artifact.level, artifact.affinityScore);
    }

     /**
     * @dev Updates the affinity score of an artifact.
     * Can be positive or negative, influencing future actions or costs (conceptually).
     * @param tokenId The ID of the artifact.
     * @param scoreChange The amount to add (positive) or subtract (negative) from affinity.
     */
    function updateAffinity(uint256 tokenId, int32 scoreChange)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        // Note: handling signed/unsigned integer addition/subtraction carefully is important.
        // `int32` arithmetic needs care. Simple addition is shown.
        _artifacts[tokenId].affinityScore = _artifacts[tokenId].affinityScore + scoreChange; // direct add/sub for int32

        emit AffinityUpdated(tokenId, _artifacts[tokenId].affinityScore);
    }

    // --- Ability Functions ---

    /**
     * @dev Attempts to activate the Shield ability. Requires Bonded state and consumes Essence.
     * @param tokenId The ID of the artifact.
     * @param essenceToken Address of the essence token to consume for cost.
     */
    function activateShieldAbility(uint256 tokenId, address essenceToken)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];
        require(artifact.state == ArtifactState.Bonded, ArtifactNotBonded(tokenId));

        uint256 requiredCost = getAbilityCost(ABILITY_SHIELD);
         require(_artifacts[tokenId].essence[essenceToken] >= requiredCost, InsufficientEssence(essenceToken, requiredCost, _artifacts[tokenId].essence[essenceToken]));

        // Consume cost
        _artifacts[tokenId].essence[essenceToken] = _artifacts[tokenId].essence[essenceToken].sub(requiredCost);

        // --- Apply Ability Effect ---
        // In a real system, this might trigger an effect in another contract,
        // update artifact state temporarily, or simply emit an event used off-chain.
        // For this example, we emit an event and could potentially add a temporary state flag.
        // Example: artifact.isShieldedUntil = uint66(block.timestamp.add(1 hours));

        emit AbilityActivated(tokenId, ABILITY_SHIELD, requiredCost);
    }

     /**
     * @dev Attempts to activate the Resource Generation ability. Requires Evolved state and consumes Essence.
     * @param tokenId The ID of the artifact.
     * @param essenceToken Address of the essence token to consume for cost.
     */
    function generateResourceAbility(uint256 tokenId, address essenceToken)
        external
        onlyArtifactOwner(tokenId)
        nonReentrant
    {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];
        require(artifact.state == ArtifactState.Evolved, ArtifactNotEvolved(tokenId));

        uint256 requiredCost = getAbilityCost(ABILITY_GENERATE);
        require(_artifacts[tokenId].essence[essenceToken] >= requiredCost, InsufficientEssence(essenceToken, requiredCost, _artifacts[tokenId].essence[essenceToken]));

        // Consume cost
        _artifacts[tokenId].essence[essenceToken] = _artifacts[tokenId].essence[essenceToken].sub(requiredCost);

        // --- Apply Ability Effect ---
        // This could mint a new ERC20, distribute rewards, or update state.
        // Example: Mint 100 units of a specific reward token to the owner.
        // IERC20 rewardToken = IERC20(address(0x...)); // Address of a reward token
        // bool success = rewardToken.transfer(ownerOf(tokenId), 100);
        // require(success, "Failed to transfer reward token");

        emit AbilityActivated(tokenId, ABILITY_GENERATE, requiredCost);
    }

     /**
     * @dev Pure/View function: Performs a hypothetical "Scan" and returns info based on level/state.
     * Costs no resources.
     * @param tokenId The ID of the artifact.
     * @return string A description or data string based on the artifact's properties.
     */
    function scanEnvironmentAbility(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];
        require(artifact.state != ArtifactState.Bonded, "Cannot scan while bonding"); // Example restriction

        string memory baseInfo = string(abi.encodePacked("Artifact ", Strings.toString(tokenId), " Level: ", Strings.toString(artifact.level), ", Affinity: ", Strings.toString(artifact.affinityScore)));

        if (artifact.state == ArtifactState.Evolved) {
             return string(abi.encodePacked(baseInfo, " - Evolved, deep scan capabilities."));
        } else {
             return string(abi.encodePacked(baseInfo, " - Standard scan initiated."));
        }
        // More complex logic based on level, affinity, etc. could be here.
    }


     /**
     * @dev Checks if an artifact is eligible to use a specific ability based on its current state and level.
     * Does *not* check resource costs.
     * @param tokenId The ID of the artifact.
     * @param abilityType The identifier for the ability.
     * @return bool True if eligible based on state/level, false otherwise.
     */
    function checkAbilityEligibility(uint256 tokenId, uint8 abilityType) external view returns (bool) {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];

        if (abilityType == ABILITY_SHIELD) {
            // Requires Bonded state
            return artifact.state == ArtifactState.Bonded;
        } else if (abilityType == ABILITY_GENERATE) {
            // Requires Evolved state and potentially min level
            return artifact.state == ArtifactState.Evolved && artifact.level >= 10; // Example min level for generation
        } else if (abilityType == ABILITY_SCAN) {
            // Example: Scan available unless Evolving or Bonded (can change logic)
            return artifact.state != ArtifactState.Bonded; // Cannot scan while Bonded in this example
        } else {
            revert InvalidAbilityType(abilityType);
        }
    }


    // --- Query Functions ---

     /**
     * @dev Gets the dynamic properties of an artifact.
     * @param tokenId The ID of the artifact.
     * @return state The current state.
     * @return level The current level.
     * @return affinityScore The current affinity score.
     * @return hasEvolved Whether the artifact has evolved.
     */
    function getArtifactProperties(uint256 tokenId)
        external
        view
        returns (ArtifactState state, uint16 level, int32 affinityScore, bool hasEvolved)
    {
        require(_exists(tokenId), InvalidTokenId());
        ArtifactData storage artifact = _artifacts[tokenId];
        return (artifact.state, artifact.level, artifact.affinityScore, artifact.hasEvolved);
    }

    /**
     * @dev Gets the amount of a specific Essence token held by an artifact.
     * @param tokenId The ID of the artifact.
     * @param tokenAddress The address of the Essence token.
     * @return uint256 The amount of the token held.
     */
    function getArtifactEssence(uint256 tokenId, address tokenAddress)
        external
        view
        returns (uint256)
    {
        require(_exists(tokenId), InvalidTokenId());
        return _artifacts[tokenId].essence[tokenAddress];
    }

     /**
     * @dev Gets the current bond information for an artifact.
     * @param tokenId The ID of the artifact.
     * @return token The address of the bonded token (address(0) if none).
     * @return amount The amount of the bonded token.
     * @return lockEndTime The timestamp when the bond can be released.
     * @return isActive Whether a bond is currently active.
     */
    function getArtifactBondInfo(uint256 tokenId)
        external
        view
        returns (address token, uint256 amount, uint66 lockEndTime, bool isActive)
    {
        require(_exists(tokenId), InvalidTokenId());
        BondInfo storage bond = _artifacts[tokenId].bond;
        return (address(bond.token), bond.amount, bond.lockEndTime, bond.isActive);
    }

    /**
     * @dev Gets the current state of an artifact.
     * @param tokenId The ID of the artifact.
     * @return ArtifactState The current state.
     */
    function getArtifactState(uint256 tokenId) external view returns (ArtifactState) {
        require(_exists(tokenId), InvalidTokenId());
        return _artifacts[tokenId].state;
    }

    /**
     * @dev Calculates the current Essence cost to level up an artifact.
     * Cost scales with level.
     * @param tokenId The ID of the artifact.
     * @return uint256 The required Essence amount.
     */
    function calculateLevelUpCost(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), InvalidTokenId());
        uint16 currentLevel = _artifacts[tokenId].level;
        // Example scaling: baseCost * currentLevel
        return baseLevelUpCost.mul(currentLevel);
    }

     /**
     * @dev Gets the evolution requirements for artifacts.
     * @return minLevel Minimum level required.
     * @return requiredEssenceAmount Total essence amount required.
     */
    function getEvolutionCost() external view returns (uint16 minLevel, uint256 requiredEssenceAmount) {
         return (evolutionReqs.minLevel, evolutionReqs.requiredEssenceAmount);
    }

    /**
     * @dev Gets the Essence cost for a specific ability type.
     * @param abilityType The identifier for the ability.
     * @return uint256 The required Essence amount.
     */
    function getAbilityCost(uint8 abilityType) public view returns (uint256) {
         require(abilityType > 0 && abilityType <= ABILITY_SCAN, "Invalid ability type");
        return _abilityCosts[abilityType];
    }


    // --- Standard ERC721 Required View Functions (Logic sketched) ---

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // Implement standard ERC721 interface checks
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId || // Assuming Metadata extension
               interfaceId == type(IERC721Enumerable).interfaceId || // Assuming Enumerable extension
               interfaceId == type(IERC721Receiver).interfaceId || // For onERC721Received
               super.supportsInterface(interfaceId); // Include Ownable or other inherited
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _tokenOwners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
         require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
         return _operatorApprovals[owner][operator];
    }

    // ERC721Enumerable extensions (Optional but common, sketch logic)
    // uint256[] private _allTokens;
    // mapping(uint256 => uint256) private _allTokensIndex;
    // mapping(address => uint256[]) private _ownedTokens;
    // mapping(uint256 => uint256) private _ownedTokensIndex;

    // function totalSupply() public view returns (uint256) { return _allTokens.length; }
    // function tokenByIndex(uint256 index) public view returns (uint256) { ... }
    // function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) { ... }


    // ERC721Metadata extensions (Optional but common, sketch logic)
    // string private _name;
    // string private _symbol;
    // mapping(uint256 => string) private _tokenURIs;

    // function name() public view returns (string memory) { return _name; }
    // function symbol() public view returns (string memory) { return _symbol; }
    // function tokenURI(uint256 tokenId) public view returns (string memory) { ... }


    // --- Internal/Helper Functions (for ERC721 state management) ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwners[tokenId] = to;
        _balances[to] = _balances[to].add(1);

        // Add to enumerable structures if implemented
        // _allTokens.push(tokenId); _allTokensIndex[tokenId] = _allTokens.length - 1;
        // _ownedTokens[to].push(tokenId); _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;

        emit Transfer(address(0), to, tokenId);

        // Check if receiver is ERC721Receiver
        if (to.code.length > 0) {
             require(
                IERC721Receiver(to).onERC721Received(msg.sender, address(0), tokenId, "") == IERC721Receiver.onERC721Received.selector,
                "ERC721: transfer to non ERC721Receiver implementer"
            );
        }
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId); // Will revert if token doesn't exist

        // Clear approvals
        _approve(address(0), tokenId);

        // Remove from enumerable structures if implemented
        // _removeTokenFromAllTokensEnumeration(tokenId);
        // _removeTokenFromOwnerEnumeration(owner, tokenId);

        _balances[owner] = _balances[owner].sub(1);
        _tokenOwners[tokenId] = address(0);
        delete _artifacts[tokenId]; // Remove artifact specific data

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        // Require checks for permissions, from/to addresses, token existence are done in public wrappers

        _approve(address(0), tokenId); // Clear approval for the transferred token

        // Update enumerable structures if implemented
        // _removeTokenFromOwnerEnumeration(from, tokenId);
        // _addTokenToOwnerEnumeration(to, tokenId);

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _tokenOwners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
         _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    // Internal helper for IERC721Receiver
     function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external virtual override returns (bytes4) {
         // This contract doesn't *receive* NFTs, it *is* an NFT.
         // This function is only relevant if the contract itself needs to hold NFTs from *other* contracts.
         // Including it as part of the IERC721Receiver interface implementation.
         revert("This contract does not accept incoming ERC721 tokens.");
         // return this.onERC721Received.selector; // Uncomment if you want it to be able to receive
     }


    // Placeholder for String conversions (using OpenZeppelin's internal Strings)
    // In a real contract, you'd import and use `import "@openzeppelin/contracts/utils/Strings.sol";`
     library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
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
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
            return string(buffer);
        }
         function toString(int256 value) internal pure returns (string memory) {
            if (value == 0) {
                return "0";
            }
            int256 temp = value;
            uint256 digits;
            bool negative = value < 0;
            if (negative) temp = -value;
             while (temp != 0) {
                digits++;
                temp /= 10;
            }
             if (negative) digits++; // For the '-' sign
             bytes memory buffer = new bytes(digits);
             uint256 i = digits;
             temp = negative ? -value : value;
             while (temp != 0) {
                i--;
                buffer[i] = bytes1(uint8(48 + temp % 10));
                temp /= 10;
            }
             if (negative) buffer[0] = '-';
            return string(buffer);
        }
         function toString(uint16 value) internal pure returns (string memory) { return toString(uint256(value)); }
          function toString(int32 value) internal pure returns (string memory) { return toString(int256(value)); }
    }

}
```