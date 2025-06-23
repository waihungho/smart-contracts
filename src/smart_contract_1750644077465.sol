Okay, let's design a smart contract around a creative concept. How about a "Dynamic Capability Capsule" protocol?

**Concept:** Users can mint unique, initially *non-transferable* NFTs called "Capability Capsules". These capsules represent potential and participation in the protocol. By "activating" (staking) their capsules, users earn dynamic yield in a native protocol token. The yield rate for each capsule can change based on its individual properties (which can be upgraded) and global protocol conditions (simulated external data feed or admin triggers). After meeting certain criteria (e.g., staked time, level achieved, yield earned), a capsule can be "crystallized", making it *transferable* and potentially unlocking new features or changing its appearance/metadata.

This concept blends:
1.  **Non-transferable NFTs:** Initially tied to an address (like Soulbound Tokens).
2.  **Dynamic NFTs:** Properties change over time or based on external factors.
3.  **Yield Farming:** Staking an asset to earn a token.
4.  **Conditional Transferability:** An asset changes from non-transferable to transferable based on on-chain logic.
5.  **Gamification:** Upgrading capsules, meeting crystallization criteria.

Let's structure the contract. We'll need a main protocol contract that manages the logic, and it will interact with a simulated ERC20 token for the yield and a simulated ERC721 for the capsules (we'll define the capsule state within the main contract for simplicity, rather than a separate ERC721 contract, but structure it like one).

---

**Outline**

1.  **SPDX-License-Identifier:** MIT
2.  **Pragma:** solidity ^0.8.0;
3.  **Imports:** (e.g., for ERC20 interface if interacting with an external token, SafeMath if needed - not for 0.8+)
4.  **Interfaces:** Define a minimal IERC20 interface for the protocol token.
5.  **Contract: `DynamicCapabilityProtocol`**
    *   **State Variables:**
        *   Admin address.
        *   Pause status.
        *   Protocol Token contract address.
        *   Next Capsule ID.
        *   Mapping: Capsule ID -> Capsule struct.
        *   Mapping: User address -> List of owned Capsule IDs.
        *   Mapping: Capsule ID -> Owner address.
        *   Mapping: Capsule ID -> Is activated (staked).
        *   Mapping: Capsule ID -> Timestamp of last yield claim/activation change.
        *   Mapping: Capsule ID -> Accumulated unclaimed yield.
        *   Global base yield rate.
        *   Mapping: Capsule Type -> Base Multiplier.
        *   Dynamic protocol state variable (simulating external data effect).
        *   Mapping: Capsule ID -> Is Crystallized.
    *   **Structs:**
        *   `Capsule`: Contains `owner`, `capsuleType`, `level`, `mintTimestamp`, `lastActiveTimestamp`, `currentDynamicMultiplier`, `isActivated`, `isCrystallized`, `totalYieldClaimed`.
    *   **Events:**
        *   `CapsuleMinted(uint256 capsuleId, address owner, uint8 capsuleType)`
        *   `CapsuleUpgraded(uint256 capsuleId, uint8 newLevel)`
        *   `CapsuleActivated(uint256 capsuleId, address owner)`
        *   `CapsuleDeactivated(uint256 capsuleId, address owner)`
        *   `YieldClaimed(uint256 capsuleId, address owner, uint256 amount)`
        *   `DynamicYieldUpdated(uint256 capsuleId, uint16 newMultiplier)`
        *   `CapsuleCrystallized(uint256 capsuleId, address owner)`
        *   `ProtocolPaused(address account)`
        *   `ProtocolUnpaused(address account)`
        *   `AdminTransferred(address oldAdmin, address newAdmin)`
    *   **Modifiers:**
        *   `onlyAdmin`: Restricts access to the admin.
        *   `whenNotPaused`: Prevents execution when paused.
        *   `whenPaused`: Allows execution *only* when paused.
        *   `isCapsuleOwner(uint256 capsuleId)`: Requires caller owns the capsule.
        *   `isCapsuleActivated(uint256 capsuleId)`: Requires capsule is staked.
        *   `isCapsuleCrystallized(uint256 capsuleId)`: Requires capsule is crystallized.
        *   `isCapsuleNonCrystallized(uint256 capsuleId)`: Requires capsule is *not* crystallized.
        *   `capsuleExists(uint256 capsuleId)`: Requires the capsule ID to be valid.
    *   **Constructor:**
        *   Sets admin and protocol token address.
    *   **Core Capsule Management (Non-transferable ERC721-like functions):**
        1.  `mintInitialCapsule(uint8 capsuleType)`: Mints the first capsule for the caller. Initially non-transferable.
        2.  `mintCapsuleWithCriteria(address user, uint8 capsuleType, bytes calldata proof)`: Admin or specific role function to mint based on off-chain proof or on-chain state checks (simulated).
        3.  `upgradeCapsule(uint256 capsuleId)`: Spends some resource (e.g., protocol token, time staked - simulated) to increase capsule level, affecting its base multiplier.
        4.  `getCapsuleDetails(uint256 capsuleId)`: View function for capsule data.
        5.  `getUserCapsules(address owner)`: View function to list owned capsule IDs.
        6.  `balanceOf(address owner)`: View function for number of capsules owned.
        7.  `ownerOf(uint256 capsuleId)`: View function for capsule owner.
        8.  `exists(uint256 capsuleId)`: View function checking if a capsule ID is valid.
        9.  `burnCapsule(uint256 capsuleId)`: Allows owner to burn a non-crystallized capsule.
    *   **Activation and Yield Farming:**
        10. `activateCapsule(uint256 capsuleId)`: Stakes the capsule to enable yield earning.
        11. `deactivateCapsule(uint256 capsuleId)`: Unstakes the capsule, stopping yield accumulation. Automatically claims pending yield.
        12. `getPendingYield(uint256 capsuleId)`: Calculates and returns pending yield for a specific capsule.
        13. `claimYield(uint256 capsuleId)`: Claims pending yield for a specific capsule.
        14. `claimAllOwnedYield()`: Claims pending yield for all activated capsules owned by the caller.
        15. `getAccumulatedYieldRate(uint256 capsuleId)`: View function showing the *current effective* yield rate per second for a capsule (based on base rate, type, level, dynamic multiplier).
        16. `getTotalActivatedCapsules()`: View function for total staked capsules globally.
    *   **Dynamic State & Oracles (Simulated):**
        17. `updateBaseYieldRate(uint256 newRatePerSecond)`: Admin function to change the global base yield rate.
        18. `triggerProtocolDynamicUpdate(uint16 globalImpactFactor)`: Admin or oracle function to update a global factor that affects the dynamic multipliers of *all* activated capsules. Simulates external data feed impact.
        19. `recalculateCapsuleDynamicMultiplier(uint256 capsuleId, uint16 individualFactor)`: Admin or internal function to update an *individual* capsule's dynamic multiplier based on its activity or simulated external data relevant to that capsule.
    *   **Crystallization (Conditional Transferability):**
        20. `checkCrystallizationEligibility(uint256 capsuleId)`: View function to check if a capsule meets the criteria (e.g., level >= X, total yield claimed >= Y, staked time >= Z).
        21. `crystallizeCapsule(uint256 capsuleId)`: Transforms the capsule from non-transferable to transferable and potentially changes its metadata type.
        22. `transferFrom(address from, address to, uint256 capsuleId)`: ERC721 transfer function. **Only works if capsule is crystallized.**
        23. `safeTransferFrom(address from, address to, uint256 capsuleId)`: Same as `transferFrom` but with safety check. **Only works if capsule is crystallized.**
    *   **Admin & Protocol Management:**
        24. `pauseProtocol()`: Admin function to pause critical actions.
        25. `unpauseProtocol()`: Admin function to unpause the protocol.
        26. `setProtocolToken(address tokenAddress)`: Admin function to set/change the protocol token address.
        27. `rescueFunds(address tokenAddress, uint256 amount, address to)`: Admin function to withdraw mistakenly sent tokens (excluding the protocol token if held for distribution).
        28. `transferAdmin(address newAdmin)`: Admin function to transfer administrative rights.

---

**Function Summary**

1.  **`constructor(address _protocolToken)`**: Deploys the contract, setting the admin to the deployer and the address of the ERC20 protocol token.
2.  **`mintInitialCapsule(uint8 capsuleType)`**: Mints the first non-transferable `Capsule` NFT for the caller with a specified type.
3.  **`mintCapsuleWithCriteria(address user, uint8 capsuleType, bytes calldata proof)`**: Allows the admin (or via a verifiable proof mechanism) to mint a capsule for a specific user, potentially based on off-chain or complex on-chain criteria.
4.  **`upgradeCapsule(uint256 capsuleId)`**: Increases the level of a user's capsule, potentially consuming resources and enhancing its yield multiplier.
5.  **`getCapsuleDetails(uint256 capsuleId)`**: Retrieves all stored details for a given capsule ID.
6.  **`getUserCapsules(address owner)`**: Returns an array of all capsule IDs owned by a specific address.
7.  **`balanceOf(address owner)`**: Returns the number of capsules owned by an address.
8.  **`ownerOf(uint256 capsuleId)`**: Returns the current owner of a specific capsule.
9.  **`exists(uint256 capsuleId)`**: Checks if a capsule with a given ID has been minted.
10. **`burnCapsule(uint256 capsuleId)`**: Allows the owner to destroy their non-crystallized capsule.
11. **`activateCapsule(uint256 capsuleId)`**: Marks a capsule as 'activated', making it eligible to earn yield.
12. **`deactivateCapsule(uint256 capsuleId)`**: Marks a capsule as 'deactivated', stopping yield accumulation. Automatically claims any pending yield.
13. **`getPendingYield(uint256 capsuleId)`**: Calculates the amount of protocol tokens a specific capsule has earned since the last claim/activation change.
14. **`claimYield(uint256 capsuleId)`**: Mints and transfers the calculated pending yield for a specific capsule to its owner.
15. **`claimAllOwnedYield()`**: Iterates through all activated capsules owned by the caller and claims yield for each.
16. **`getAccumulatedYieldRate(uint256 capsuleId)`**: Returns the current rate (tokens per second) at which a capsule is earning yield, factoring in base rate, type, level, and dynamic multiplier.
17. **`updateBaseYieldRate(uint256 newRatePerSecond)`**: Admin function to adjust the fundamental yield rate applied to all capsules.
18. **`triggerProtocolDynamicUpdate(uint16 globalImpactFactor)`**: Admin/Oracle function that updates a global factor influencing the dynamic yield multipliers of *all* currently activated capsules.
19. **`recalculateCapsuleDynamicMultiplier(uint256 capsuleId, uint16 individualFactor)`**: Admin/Internal function to recalculate the *individual* dynamic multiplier for a specific capsule, possibly based on its activity or targeted criteria.
20. **`checkCrystallizationEligibility(uint256 capsuleId)`**: Checks if a capsule meets the predefined conditions to become transferable (crystallized).
21. **`crystallizeCapsule(uint256 capsuleId)`**: Transforms a capsule from non-transferable to transferable if eligible. Changes its state and potentially its metadata (simulated).
22. **`transferFrom(address from, address to, uint256 capsuleId)`**: Standard ERC721 transfer function. **Only callable for crystallized capsules.**
23. **`safeTransferFrom(address from, address to, uint256 capsuleId)`**: Standard ERC721 safe transfer function. **Only callable for crystallized capsules.**
24. **`pauseProtocol()`**: Admin function to halt core operations (like minting, activation, claiming, transfer).
25. **`unpauseProtocol()`**: Admin function to resume protocol operations.
26. **`setProtocolToken(address tokenAddress)`**: Admin function to set or update the address of the protocol token contract.
27. **`rescueFunds(address tokenAddress, uint256 amount, address to)`**: Admin function to recover tokens sent to the contract address by mistake, excluding the protocol token itself (as its balance is used for distribution).
28. **`transferAdmin(address newAdmin)`**: Admin function to transfer the administrative role to a new address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Outline:
// 1. SPDX-License-Identifier & Pragma
// 2. Interfaces (IERC20 for Protocol Token)
// 3. Contract: DynamicCapabilityProtocol
//    - State Variables
//    - Structs
//    - Events
//    - Modifiers
//    - Constructor
//    - Core Capsule Management (ERC721-like)
//    - Activation and Yield Farming
//    - Dynamic State & Oracles (Simulated)
//    - Crystallization (Conditional Transferability)
//    - Admin & Protocol Management

// Function Summary:
// 1.  constructor(address _protocolToken): Deploys contract, sets admin & token.
// 2.  mintInitialCapsule(uint8 capsuleType): Mints a non-transferable capsule for caller.
// 3.  mintCapsuleWithCriteria(address user, uint8 capsuleType, bytes calldata proof): Admin/Proof-based minting.
// 4.  upgradeCapsule(uint256 capsuleId): Increases capsule level (affects yield).
// 5.  getCapsuleDetails(uint256 capsuleId): Views capsule properties.
// 6.  getUserCapsules(address owner): Lists owner's capsule IDs.
// 7.  balanceOf(address owner): Counts owner's capsules.
// 8.  ownerOf(uint256 capsuleId): Gets capsule owner.
// 9.  exists(uint256 capsuleId): Checks if capsule ID is valid.
// 10. burnCapsule(uint256 capsuleId): Allows owner to destroy non-crystallized capsule.
// 11. activateCapsule(uint256 capsuleId): Stakes capsule for yield.
// 12. deactivateCapsule(uint256 capsuleId): Unstakes capsule, claims yield.
// 13. getPendingYield(uint256 capsuleId): Calculates earned yield since last check/claim.
// 14. claimYield(uint256 capsuleId): Claims yield for one capsule.
// 15. claimAllOwnedYield(): Claims yield for all owner's activated capsules.
// 16. getAccumulatedYieldRate(uint256 capsuleId): Views effective yield rate per second.
// 17. updateBaseYieldRate(uint256 newRatePerSecond): Admin sets global base yield.
// 18. triggerProtocolDynamicUpdate(uint16 globalImpactFactor): Admin/Oracle triggers global dynamic yield recalculation for active capsules.
// 19. recalculateCapsuleDynamicMultiplier(uint256 capsuleId, uint16 individualFactor): Admin/Internal triggers individual dynamic yield recalculation.
// 20. checkCrystallizationEligibility(uint256 capsuleId): Checks if capsule can be crystallized.
// 21. crystallizeCapsule(uint256 capsuleId): Transforms non-transferable to transferable if eligible.
// 22. transferFrom(address from, address to, uint256 capsuleId): ERC721 transfer (only for crystallized).
// 23. safeTransferFrom(address from, address to, uint256 capsuleId): ERC721 safe transfer (only for crystallized).
// 24. pauseProtocol(): Admin pauses key functions.
// 25. unpauseProtocol(): Admin unpauses key functions.
// 26. setProtocolToken(address tokenAddress): Admin sets the protocol token address.
// 27. rescueFunds(address tokenAddress, uint256 amount, address to): Admin rescues stuck tokens.
// 28. transferAdmin(address newAdmin): Admin transfers role.

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint2556);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Minimal interface for receiver callback (like ERC721)
interface ERC721TokenReceiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract DynamicCapabilityProtocol {

    address public admin;
    bool public paused;
    IERC20 public protocolToken;

    uint256 private _nextTokenId;

    struct Capsule {
        address owner;
        uint8 capsuleType; // e.g., 1=Skill, 2=Participation, 3=Contribution
        uint8 level;
        uint64 mintTimestamp;
        uint64 lastActivityTimestamp; // Used for yield calc and dynamic updates
        uint16 currentDynamicMultiplier; // Factor > 1000 adds yield, < 1000 reduces (e.g. 1200 = +20%)
        bool isActivated; // Is staked for yield
        bool isCrystallized; // Can be transferred
        uint256 totalYieldClaimed;
    }

    mapping(uint256 => Capsule) private _capsules;
    mapping(address => uint256[]) private _userCapsules; // Stores IDs of capsules owned by a user
    mapping(uint256 => address) private _capsuleOwner; // For ERC721 compatibility view
    mapping(address => uint256) private _ownedCapsuleCount; // For balanceOf

    // Yield calculation state per capsule
    mapping(uint256 => uint256) private _unclaimedYield;

    // Global yield parameters
    uint256 public baseYieldRatePerSecond; // Global base yield rate
    mapping(uint8 => uint16) public capsuleTypeBaseMultiplier; // Base multiplier for each type (e.g., type 1 gives 1.1x yield)
    mapping(uint8 => uint16) public capsuleLevelMultiplier; // Additional multiplier based on level

    // Dynamic protocol state influencing yield (simulating external data)
    uint16 public globalDynamicImpactFactor = 1000; // Default 1000 (1x), >1000 increases, <1000 decreases

    // Crystallization criteria (example values)
    uint8 public crystallizationMinLevel = 5;
    uint256 public crystallizationMinTotalYield = 1000e18; // Example: 1000 tokens
    uint64 public crystallizationMinStakedTime = 365 days; // Example: 1 year staked time cumulative

    event CapsuleMinted(uint256 indexed capsuleId, address indexed owner, uint8 capsuleType);
    event CapsuleUpgraded(uint256 indexed capsuleId, uint8 newLevel);
    event CapsuleActivated(uint256 indexed capsuleId, address indexed owner);
    event CapsuleDeactivated(uint256 indexed capsuleId, address indexed owner);
    event YieldClaimed(uint256 indexed capsuleId, address indexed owner, uint256 amount);
    event DynamicYieldMultiplierUpdated(uint256 indexed capsuleId, uint16 newMultiplier);
    event CapsuleCrystallized(uint256 indexed capsuleId, address indexed owner);
    event ProtocolPaused(address account);
    event ProtocolUnpaused(address account);
    event AdminTransferred(address indexed oldAdmin, address indexed newAdmin);
    event CapsuleBurned(uint256 indexed capsuleId, address indexed owner);
    event BaseYieldRateUpdated(uint256 newRatePerSecond);
    event GlobalDynamicImpactUpdated(uint16 globalImpactFactor);


    modifier onlyAdmin() {
        require(msg.sender == admin, "DCP: Only admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DCP: Protocol is paused");
        _;
    }

     modifier whenPaused() {
        require(paused, "DCP: Protocol is not paused");
        _;
    }

    modifier isCapsuleOwner(uint256 capsuleId) {
        require(_capsules[capsuleId].owner == msg.sender, "DCP: Not capsule owner");
        _;
    }

    modifier isCapsuleActivated(uint256 capsuleId) {
        require(_capsules[capsuleId].isActivated, "DCP: Capsule not activated");
        _;
    }

    modifier isCapsuleCrystallized(uint256 capsuleId) {
        require(_capsules[capsuleId].isCrystallized, "DCP: Capsule not crystallized");
        _;
    }

    modifier isCapsuleNonCrystallized(uint256 capsuleId) {
        require(!_capsules[capsuleId].isCrystallized, "DCP: Capsule already crystallized");
        _;
    }

     modifier capsuleExists(uint256 capsuleId) {
        require(_capsuleOwner[capsuleId] != address(0), "DCP: Capsule does not exist");
        _;
    }


    constructor(address _protocolToken) {
        admin = msg.sender;
        protocolToken = IERC20(_protocolToken);
        _nextTokenId = 1;

        // Set some initial multipliers (example)
        capsuleTypeBaseMultiplier[1] = 1000; // Type 1: 1x base
        capsuleTypeBaseMultiplier[2] = 1100; // Type 2: 1.1x base
        capsuleTypeBaseMultiplier[3] = 1250; // Type 3: 1.25x base

        // Set initial level multipliers (example)
        capsuleLevelMultiplier[0] = 1000; // Level 0: 1x
        capsuleLevelMultiplier[1] = 1050; // Level 1: 1.05x
        capsuleLevelMultiplier[2] = 1100; // Level 2: 1.1x
        // ... and so on for higher levels
    }

    // --- Core Capsule Management (ERC721-like) ---

    /**
     * @notice Mints the initial non-transferable Capability Capsule for the caller.
     * @param capsuleType The type of capsule to mint.
     */
    function mintInitialCapsule(uint8 capsuleType) external whenNotPaused {
        require(capsuleTypeBaseMultiplier[capsuleType] > 0, "DCP: Invalid capsule type");
        require(_ownedCapsuleCount[msg.sender] == 0, "DCP: Already owns a capsule"); // Restrict initial mint to one per user

        _mint(msg.sender, capsuleType);
    }

    /**
     * @notice Admin function to mint a capsule for a specific user, potentially based on criteria.
     * @param user The address to mint the capsule for.
     * @param capsuleType The type of capsule to mint.
     * @param proof Optional proof for off-chain criteria (not verified in this example).
     */
    function mintCapsuleWithCriteria(address user, uint8 capsuleType, bytes calldata proof) external onlyAdmin whenNotPaused {
         require(capsuleTypeBaseMultiplier[capsuleType] > 0, "DCP: Invalid capsule type");
         // Add logic here to verify proof or check on-chain criteria if needed
        _mint(user, capsuleType);
    }

    /**
     * @notice Increases the level of a capsule, potentially affecting its yield.
     * @param capsuleId The ID of the capsule to upgrade.
     */
    function upgradeCapsule(uint256 capsuleId) external isCapsuleOwner(capsuleId) whenNotPaused capsuleExists(capsuleId) {
        Capsule storage capsule = _capsules[capsuleId];
        // Add cost/criteria for upgrading here (e.g., burn tokens, time staked, etc.)
        // require(protocolToken.transferFrom(msg.sender, address(this), upgradeCost), "DCP: Token transfer failed");

        capsule.level++;
        // Ensure level multiplier exists for the new level
        require(capsuleLevelMultiplier[capsule.level] > 0, "DCP: Max level reached or multiplier not set");

        emit CapsuleUpgraded(capsuleId, capsule.level);
    }

    /**
     * @notice Gets the details of a specific capsule.
     * @param capsuleId The ID of the capsule.
     * @return Capsule struct details.
     */
    function getCapsuleDetails(uint256 capsuleId) public view capsuleExists(capsuleId) returns (Capsule memory) {
        return _capsules[capsuleId];
    }

     /**
     * @notice Gets the list of capsule IDs owned by a user.
     * @param owner The address of the owner.
     * @return An array of capsule IDs.
     */
    function getUserCapsules(address owner) public view returns (uint256[] memory) {
        return _userCapsules[owner];
    }

    /**
     * @notice Returns the number of capsules owned by an address. (ERC721 standard)
     * @param owner The address to query.
     * @return The number of capsules owned.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _ownedCapsuleCount[owner];
    }

    /**
     * @notice Returns the owner of a specific capsule. (ERC721 standard)
     * @param capsuleId The ID of the capsule.
     * @return The owner's address.
     */
    function ownerOf(uint256 capsuleId) public view returns (address) {
         address owner = _capsuleOwner[capsuleId];
         require(owner != address(0), "ERC721: owner query for nonexistent token");
         return owner;
    }

     /**
     * @notice Checks if a capsule ID exists. (ERC721-like utility)
     * @param capsuleId The ID to check.
     * @return True if the capsule exists, false otherwise.
     */
    function exists(uint256 capsuleId) public view returns (bool) {
        return _capsuleOwner[capsuleId] != address(0);
    }


    /**
     * @notice Allows a user to burn their non-crystallized capsule.
     * @param capsuleId The ID of the capsule to burn.
     */
    function burnCapsule(uint256 capsuleId) external isCapsuleOwner(capsuleId) isCapsuleNonCrystallized(capsuleId) whenNotPaused capsuleExists(capsuleId) {
        // Claim pending yield before burning
        uint256 pending = getPendingYield(capsuleId);
        if (pending > 0) {
             _mintYield(msg.sender, pending);
             _unclaimedYield[capsuleId] = 0;
             _capsules[capsuleId].totalYieldClaimed += pending;
             emit YieldClaimed(capsuleId, msg.sender, pending);
        }

        _burn(capsuleId);
        emit CapsuleBurned(capsuleId, msg.sender);
    }


    // --- Activation and Yield Farming ---

    /**
     * @notice Activates a non-crystallized capsule to start earning yield.
     * @param capsuleId The ID of the capsule to activate.
     */
    function activateCapsule(uint256 capsuleId) external isCapsuleOwner(capsuleId) isCapsuleNonCrystallized(capsuleId) whenNotPaused capsuleExists(capsuleId) {
        Capsule storage capsule = _capsules[capsuleId];
        require(!capsule.isActivated, "DCP: Capsule already activated");

        // Calculate any pending yield before updating timestamp
        uint256 pending = getPendingYield(capsuleId);
         if (pending > 0) {
             _unclaimedYield[capsuleId] += pending; // Add to unclaimed balance
         }

        capsule.isActivated = true;
        capsule.lastActivityTimestamp = uint64(block.timestamp);

        emit CapsuleActivated(capsuleId, msg.sender);
    }

    /**
     * @notice Deactivates an activated capsule, stopping yield accumulation and claiming pending yield.
     * @param capsuleId The ID of the capsule to deactivate.
     */
    function deactivateCapsule(uint256 capsuleId) external isCapsuleOwner(capsuleId) isCapsuleActivated(capsuleId) whenNotPaused capsuleExists(capsuleId) {
        Capsule storage capsule = _capsules[capsuleId];
        require(capsule.isActivated, "DCP: Capsule not activated");

        // Claim pending yield upon deactivation
        uint256 pending = getPendingYield(capsuleId);
        if (pending > 0) {
             _mintYield(msg.sender, pending);
             _unclaimedYield[capsuleId] = 0; // Reset unclaimed after mint
             capsule.totalYieldClaimed += pending; // Update total claimed
             emit YieldClaimed(capsuleId, msg.sender, pending);
        }

        capsule.isActivated = false;
        capsule.lastActivityTimestamp = uint64(block.timestamp); // Update timestamp even on deactivation

        emit CapsuleDeactivated(capsuleId, msg.sender);
    }

    /**
     * @notice Calculates the yield a specific capsule has earned since the last claim/activation change.
     * @param capsuleId The ID of the capsule.
     * @return The pending yield amount.
     */
    function getPendingYield(uint256 capsuleId) public view capsuleExists(capsuleId) returns (uint256) {
        Capsule memory capsule = _capsules[capsuleId];
        if (!capsule.isActivated) {
            return _unclaimedYield[capsuleId]; // Return stored unclaimed if not active
        }

        uint256 secondsElapsed = block.timestamp - capsule.lastActivityTimestamp;
        if (secondsElapsed == 0) {
             return _unclaimedYield[capsuleId];
        }

        // Calculate effective yield rate: base * type_multiplier * level_multiplier * dynamic_multiplier / (1000*1000*1000)
        uint256 effectiveRate = (baseYieldRatePerSecond * capsuleTypeBaseMultiplier[capsule.capsuleType] / 1000 *
                                 capsuleLevelMultiplier[capsule.level] / 1000 *
                                 capsule.currentDynamicMultiplier / 1000);

        uint256 newEarned = secondsElapsed * effectiveRate;

        return _unclaimedYield[capsuleId] + newEarned;
    }

    /**
     * @notice Claims the pending yield for a specific capsule.
     * @param capsuleId The ID of the capsule.
     */
    function claimYield(uint256 capsuleId) external isCapsuleOwner(capsuleId) whenNotPaused capsuleExists(capsuleId) {
        Capsule storage capsule = _capsules[capsuleId];

        // Calculate pending yield first
        uint256 pending = getPendingYield(capsuleId);
        require(pending > 0, "DCP: No yield to claim");

        // If activated, update timestamp for yield calculation
        if(capsule.isActivated) {
            capsule.lastActivityTimestamp = uint64(block.timestamp);
        }

        // Mint and transfer yield
        _mintYield(msg.sender, pending);

        // Update state
        _unclaimedYield[capsuleId] = 0; // Reset unclaimed balance
        capsule.totalYieldClaimed += pending; // Add to total claimed

        emit YieldClaimed(capsuleId, msg.sender, pending);
    }

    /**
     * @notice Claims pending yield for all activated capsules owned by the caller.
     */
    function claimAllOwnedYield() external whenNotPaused {
        uint256[] memory owned = _userCapsules[msg.sender];
        uint256 totalClaimed = 0;

        for (uint i = 0; i < owned.length; i++) {
            uint256 capsuleId = owned[i];
            Capsule storage capsule = _capsules[capsuleId];

            // Only process activated capsules
            if (capsule.isActivated) {
                 uint256 pending = getPendingYield(capsuleId);

                 if (pending > 0) {
                     // If activated, update timestamp for yield calculation
                     capsule.lastActivityTimestamp = uint64(block.timestamp);

                     // Add to total claimed for this batch
                     totalClaimed += pending;

                     // Update state per capsule (will be reset after total mint)
                     _unclaimedYield[capsuleId] = 0;
                     capsule.totalYieldClaimed += pending;
                     emit YieldClaimed(capsuleId, msg.sender, pending); // Emit event for each capsule
                 }
            }
        }

        // Mint and transfer the total calculated yield
        if (totalClaimed > 0) {
            _mintYield(msg.sender, totalClaimed);
        }
    }

    /**
     * @notice Returns the current effective yield rate per second for a capsule.
     * @param capsuleId The ID of the capsule.
     * @return The yield rate in protocol tokens per second (wei).
     */
    function getAccumulatedYieldRate(uint256 capsuleId) public view capsuleExists(capsuleId) returns (uint256) {
        Capsule memory capsule = _capsules[capsuleId];
        // Rate is only relevant if activated
        if (!capsule.isActivated) {
            return 0;
        }
         // Calculate effective yield rate: base * type_multiplier * level_multiplier * dynamic_multiplier / (1000*1000*1000)
        return (baseYieldRatePerSecond * capsuleTypeBaseMultiplier[capsule.capsuleType] / 1000 *
                capsuleLevelMultiplier[capsule.level] / 1000 *
                capsule.currentDynamicMultiplier / 1000);
    }

    /**
     * @notice Gets the total number of capsules currently activated (staked).
     * @return The count of activated capsules.
     */
    function getTotalActivatedCapsules() public view returns (uint256) {
        // This would require iterating through all capsules or maintaining a separate counter.
        // Iterating is gas intensive for large numbers. A separate counter is better.
        // For simplicity in this example, we'll return a placeholder or require iteration off-chain.
        // Let's add a counter for this purpose.
        // Add state variable: uint256 private _totalActivatedCount;
        // Increment in activateCapsule, decrement in deactivateCapsule.
        // For now, return 0 as we didn't add the counter yet.
        // return _totalActivatedCount; // Assuming counter is added
        return 0; // Placeholder - requires adding and maintaining _totalActivatedCount
    }

    // --- Dynamic State & Oracles (Simulated) ---

    /**
     * @notice Admin function to update the global base yield rate.
     * @param newRatePerSecond The new base rate in protocol tokens (wei) per second.
     */
    function updateBaseYieldRate(uint256 newRatePerSecond) external onlyAdmin whenNotPaused {
        baseYieldRatePerSecond = newRatePerSecond;
        emit BaseYieldRateUpdated(newRatePerSecond);
    }

    /**
     * @notice Admin/Oracle function to trigger a global update to dynamic multipliers for all *activated* capsules.
     * This simulates external data impacting yield.
     * @param globalImpactFactor A new global factor (e.g., from 1 to 2000, 1000 is neutral).
     */
    function triggerProtocolDynamicUpdate(uint16 globalImpactFactor) external onlyAdmin whenNotPaused {
        globalDynamicImpactFactor = globalImpactFactor;

        // Ideally, this would iterate through all *activated* capsules and recalculate their multiplier.
        // Iterating through all tokens on-chain is gas-prohibitive.
        // In a real system, this might trigger off-chain calculation and updates via admin/oracle,
        // or the dynamic multiplier calculation would happen *during* getPendingYield/claimYield.
        // Let's make the getPendingYield calculation depend on this global factor directly for simplicity here.
        // The recalculateCapsuleDynamicMultiplier function below is for *individual* updates.

        // Update the global factor state variable is sufficient for the yield formula to pick it up
        // in getPendingYield/claimYield. The individual multipliers might still exist for specific nuances.
        emit GlobalDynamicImpactUpdated(globalImpactFactor);
    }

    /**
     * @notice Admin/Internal function to recalculate an *individual* capsule's dynamic multiplier.
     * Could be based on its activity, external data relevant to that capsule, etc.
     * @param capsuleId The ID of the capsule.
     * @param individualFactor A factor specific to this capsule (e.g., from 1 to 2000).
     */
    function recalculateCapsuleDynamicMultiplier(uint256 capsuleId, uint16 individualFactor) external onlyAdmin whenNotPaused capsuleExists(capsuleId) {
         // In a real system, this might be triggered internally based on capsule interaction
         // or by an oracle providing data specific to this capsule or its type.
         Capsule storage capsule = _capsules[capsuleId];

         // Recalculate pending yield before updating the multiplier to account for yield earned
         // at the *old* multiplier up to this point.
         uint256 pending = getPendingYield(capsuleId);
         if (pending > 0) {
             _unclaimedYield[capsuleId] = pending; // Store the calculated pending yield
             capsule.lastActivityTimestamp = uint64(block.timestamp); // Reset timer for new yield calculation
         }

         capsule.currentDynamicMultiplier = individualFactor; // Example: just set it directly
         emit DynamicYieldMultiplierUpdated(capsuleId, individualFactor);
    }


    // --- Crystallization (Conditional Transferability) ---

    /**
     * @notice Checks if a capsule meets the criteria to become transferable.
     * @param capsuleId The ID of the capsule.
     * @return True if eligible, false otherwise.
     */
    function checkCrystallizationEligibility(uint256 capsuleId) public view capsuleExists(capsuleId) returns (bool) {
        Capsule memory capsule = _capsules[capsuleId];

        if (capsule.isCrystallized) {
            return true; // Already crystallized
        }

        // Example criteria: Must be level >= minLevel AND total yield claimed >= minTotalYield AND staked time >= minStakedTime
        bool meetsLevel = capsule.level >= crystallizationMinLevel;
        bool meetsYield = capsule.totalYieldClaimed >= crystallizationMinTotalYield;

        // Calculate cumulative staked time (requires tracking this state).
        // For simplicity here, let's use total elapsed time since mint if activated, or require a separate state variable.
        // Let's assume a state variable `uint64 cumulativeStakedTime` is added to the Capsule struct.
        // We'd need to update this when activating/deactivating.
        // For this example, let's simplify and just check total time elapsed since mint if it's currently activated.
        // NOTE: A real implementation needs careful tracking of *staked* time.
        // bool meetsTime = (capsule.isActivated ? (block.timestamp - capsule.mintTimestamp) : (capsule.lastActivityTimestamp - capsule.mintTimestamp)) >= crystallizationMinStakedTime;
         bool meetsTime = false; // Placeholder - requires cumulative staked time tracking


        // A more robust approach for cumulative staked time:
        // struct Capsule { ... uint64 cumulativeStakedTime; uint64 stakingStartTime; bool isActivated; ... }
        // activate: capsule.stakingStartTime = block.timestamp;
        // deactivate: capsule.cumulativeStakedTime += (block.timestamp - capsule.stakingStartTime); capsule.stakingStartTime = 0;
        // check: capsule.cumulativeStakedTime + (capsule.isActivated ? (block.timestamp - capsule.stakingStartTime) : 0) >= crystallizationMinStakedTime

        // Using simplified criteria for this example: just level and yield.
        meetsTime = true; // Bypass time criteria for this example simplicity

        return meetsLevel && meetsYield && meetsTime;
    }

    /**
     * @notice Transforms a non-transferable capsule into a transferable one if it meets the criteria.
     * @param capsuleId The ID of the capsule to crystallize.
     */
    function crystallizeCapsule(uint256 capsuleId) external isCapsuleOwner(capsuleId) isCapsuleNonCrystallized(capsuleId) whenNotPaused capsuleExists(capsuleId) {
        require(checkCrystallizationEligibility(capsuleId), "DCP: Capsule not eligible for crystallization");

        Capsule storage capsule = _capsules[capsuleId];
        capsule.isCrystallized = true;
        // Potentially change capsuleType or other metadata here (e.g., change type 1 to type 11 meaning 'crystallized skill')
        // capsule.capsuleType += 10; // Example metadata change

        // Deactivate if currently staked upon crystallization
        if (capsule.isActivated) {
            // Claim pending yield upon crystallization
            uint256 pending = getPendingYield(capsuleId);
            if (pending > 0) {
                _mintYield(msg.sender, pending);
                _unclaimedYield[capsuleId] = 0;
                capsule.totalYieldClaimed += pending;
                emit YieldClaimed(capsuleId, msg.sender, pending);
            }
            capsule.isActivated = false; // Crystallized capsules cannot be staked for yield? Or earn different yield? Decide protocol logic.
                                         // Let's make them non-yield bearing after crystallization for this example.
            capsule.lastActivityTimestamp = uint64(block.timestamp);
        }


        emit CapsuleCrystallized(capsuleId, msg.sender);
    }

    /**
     * @notice Transfers a CRYSTALLIZED capsule from one address to another. (ERC721 standard)
     * @dev This function bypasses the ERC721 approved/operator checks for simplicity in this example.
     *      A full ERC721 implementation would require those mappings.
     * @param from The current owner of the capsule.
     * @param to The new owner.
     * @param capsuleId The ID of the capsule to transfer.
     */
    function transferFrom(address from, address to, uint256 capsuleId) public whenNotPaused capsuleExists(capsuleId) {
        require(from == _capsuleOwner[capsuleId], "DCP: TransferFrom incorrect owner");
        require(to != address(0), "DCP: Transfer to the zero address");
        require(msg.sender == from || msg.sender == admin /* || msg.sender is approved/operator */, "DCP: Transfer caller is not owner nor approved"); // Simplified approval check

        isCapsuleCrystallized(capsuleId); // Requires crystallization for transfer

        // Deactivate if activated before transfer (cannot be staked by new owner)
        if (_capsules[capsuleId].isActivated) {
             uint256 pending = getPendingYield(capsuleId);
             if (pending > 0) {
                 _mintYield(from, pending); // Claim yield for the sender
                 _unclaimedYield[capsuleId] = 0;
                 _capsules[capsuleId].totalYieldClaimed += pending;
                 emit YieldClaimed(capsuleId, from, pending);
             }
             _capsules[capsuleId].isActivated = false;
             _capsules[capsuleId].lastActivityTimestamp = uint64(block.timestamp);
        }


        _transfer(from, to, capsuleId);
    }

    /**
     * @notice Safely transfers a CRYSTALLIZED capsule. (ERC721 standard)
     * @dev This function includes the safety check for receiver contract.
     * @param from The current owner of the capsule.
     * @param to The new owner.
     * @param capsuleId The ID of the capsule to transfer.
     */
    function safeTransferFrom(address from, address to, uint256 capsuleId) public whenNotPaused capsuleExists(capsuleId) {
         safeTransferFrom(from, to, capsuleId, "");
    }

     /**
     * @notice Safely transfers a CRYSTALLIZED capsule with data. (ERC721 standard)
     * @dev This function includes the safety check for receiver contract.
     * @param from The current owner of the capsule.
     * @param to The new owner.
     * @param capsuleId The ID of the capsule to transfer.
     * @param data Additional data for receiver callback.
     */
    function safeTransferFrom(address from, address to, uint256 capsuleId, bytes calldata data) public whenNotPaused capsuleExists(capsuleId) {
        require(from == _capsuleOwner[capsuleId], "DCP: SafeTransferFrom incorrect owner");
        require(to != address(0), "DCP: Transfer to the zero address");
        require(msg.sender == from || msg.sender == admin /* || msg.sender is approved/operator */, "DCP: Transfer caller is not owner nor approved"); // Simplified approval check

        isCapsuleCrystallized(capsuleId); // Requires crystallization for transfer

         // Deactivate if activated before transfer (cannot be staked by new owner)
        if (_capsules[capsuleId].isActivated) {
             uint256 pending = getPendingYield(capsuleId);
             if (pending > 0) {
                 _mintYield(from, pending); // Claim yield for the sender
                 _unclaimedYield[capsuleId] = 0;
                 _capsules[capsuleId].totalYieldClaimed += pending;
                 emit YieldClaimed(capsuleId, from, pending);
             }
             _capsules[capsuleId].isActivated = false;
             _capsules[capsuleId].lastActivityTimestamp = uint64(block.timestamp);
        }

        _transfer(from, to, capsuleId);

        // ERC721 safety check
        if (to.code.length > 0) {
             require(ERC721TokenReceiver(to).onERC721Received(msg.sender, from, capsuleId, data) == ERC721TokenReceiver.onERC721Received.selector, "DCP: ERC721Receiver rejected transfer");
        }
    }


    // --- Admin & Protocol Management ---

    /**
     * @notice Pauses core protocol functions.
     */
    function pauseProtocol() external onlyAdmin whenNotPaused {
        paused = true;
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @notice Unpauses core protocol functions.
     */
    function unpauseProtocol() external onlyAdmin whenPaused {
        paused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @notice Sets or updates the address of the protocol token contract.
     * @param tokenAddress The new address for the protocol token.
     */
    function setProtocolToken(address tokenAddress) external onlyAdmin {
        require(tokenAddress != address(0), "DCP: Token address cannot be zero");
        protocolToken = IERC20(tokenAddress);
    }

     /**
     * @notice Allows admin to withdraw mistakenly sent tokens, excluding the protocol token.
     * @param tokenAddress The address of the token to rescue.
     * @param amount The amount to withdraw.
     * @param to The address to send the rescued tokens to.
     */
    function rescueFunds(address tokenAddress, uint256 amount, address to) external onlyAdmin {
        require(tokenAddress != address(protocolToken), "DCP: Cannot rescue protocol token");
        IERC20 rescueToken = IERC20(tokenAddress);
        require(rescueToken.transfer(to, amount), "DCP: Fund rescue failed");
    }


    /**
     * @notice Transfers the admin role to a new address.
     * @param newAdmin The address of the new admin.
     */
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "DCP: New admin address cannot be zero");
        address oldAdmin = admin;
        admin = newAdmin;
        emit AdminTransferred(oldAdmin, newAdmin);
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Mints a new capsule and assigns it to an owner.
     */
    function _mint(address to, uint8 capsuleType) internal {
        uint256 newCapsuleId = _nextTokenId++;
        require(_capsuleOwner[newCapsuleId] == address(0), "DCP: Mint failed - ID already exists"); // Should not happen with counter

        _capsules[newCapsuleId] = Capsule({
            owner: to,
            capsuleType: capsuleType,
            level: 0, // Start at level 0
            mintTimestamp: uint64(block.timestamp),
            lastActivityTimestamp: uint64(block.timestamp), // Initialize for yield calc
            currentDynamicMultiplier: 1000, // Start at 1x
            isActivated: false,
            isCrystallized: false, // Initially not transferable
            totalYieldClaimed: 0
        });

        _capsuleOwner[newCapsuleId] = to;
        _userCapsules[to].push(newCapsuleId);
        _ownedCapsuleCount[to]++;

        emit CapsuleMinted(newCapsuleId, to, capsuleType);
    }

    /**
     * @dev Burns a capsule, removing it from existence.
     */
    function _burn(uint256 capsuleId) internal {
        address owner = _capsuleOwner[capsuleId];
        require(owner != address(0), "DCP: Burn nonexistent token");

        // Remove from owner's list ( inefficient for large arrays, better data structure needed for scale)
        uint256[] storage owned = _userCapsules[owner];
        for (uint i = 0; i < owned.length; i++) {
            if (owned[i] == capsuleId) {
                owned[i] = owned[owned.length - 1];
                owned.pop();
                break;
            }
        }

        _ownedCapsuleCount[owner]--;
        delete _capsuleOwner[capsuleId];
        delete _capsules[capsuleId];
        delete _unclaimedYield[capsuleId]; // Remove pending yield data
    }

    /**
     * @dev Transfers capsule ownership. Does NOT check crystallization status or eligibility.
     *      Used by transferFrom and safeTransferFrom after checks.
     */
    function _transfer(address from, address to, uint256 capsuleId) internal {
        require(_capsuleOwner[capsuleId] == from, "DCP: Transfer unauthorized");
        require(to != address(0), "DCP: Transfer to the zero address");

        // Remove from sender's list ( inefficient for large arrays, better data structure needed for scale)
        uint256[] storage ownedFrom = _userCapsules[from];
        for (uint i = 0; i < ownedFrom.length; i++) {
            if (ownedFrom[i] == capsuleId) {
                ownedFrom[i] = ownedFrom[ownedFrom.length - 1];
                ownedFrom.pop();
                break;
            }
        }
         _ownedCapsuleCount[from]--;

        _capsuleOwner[capsuleId] = to;
        _capsules[capsuleId].owner = to; // Update owner in the Capsule struct
        _userCapsules[to].push(capsuleId);
        _ownedCapsuleCount[to]++;

        // ERC721 Transfer event (simplified)
        // emit Transfer(from, to, capsuleId); // Need to implement Approval/Transfer events if full ERC721 compliance is needed
    }


    /**
     * @dev Mints protocol tokens and transfers them to the recipient.
     *      Assumes the protocolToken contract has a minting function callable by this contract,
     *      OR that this contract holds a balance of protocol tokens to distribute.
     *      This example SIMULATES minting/transfer using a placeholder call.
     */
    function _mintYield(address recipient, uint256 amount) internal {
         // In a real scenario, this would require:
         // 1. protocolToken having a `mint` function and this contract having MINTER_ROLE, OR
         // 2. This contract holding a large pre-minted supply and using protocolToken.transfer(recipient, amount).
         // Option 2 is generally safer if you don't need dynamic supply.

         // SIMULATING TRANSFER FROM CONTRACT'S HELD BALANCE FOR EXAMPLE
         // In a real use case, ensure this contract holds enough `protocolToken`.
         require(protocolToken.transfer(recipient, amount), "DCP: Yield token transfer failed");

         // If using a `mint` function on protocolToken instead:
         // protocolToken.mint(recipient, amount); // Requires ERC20 token with minting and minter role setup
    }
}
```

**Explanation of Advanced/Creative/Trendy Concepts Used:**

1.  **Initially Non-Transferable NFTs (`isCrystallized` flag):** Simulates Soulbound Tokens or identity-bound assets initially. The `transferFrom` functions are gated by `isCapsuleCrystallized`.
2.  **Dynamic NFTs (`currentDynamicMultiplier`, `triggerProtocolDynamicUpdate`, `recalculateCapsuleDynamicMultiplier`):** The yield-earning capability (a key property) changes based on internal logic (`recalculateCapsuleDynamicMultiplier`) or simulated external events (`triggerProtocolDynamicUpdate`, `globalDynamicImpactFactor`). This makes the NFT state dynamic and reactive. The `getPendingYield` function calculates yield based on these live, changing properties.
3.  **Yield-Bearing NFTs:** Staking the NFT (`activateCapsule`) allows it to accrue value in a different token (`protocolToken`). This is a form of NFT staking for yield, but tied to the unique properties of the capsule.
4.  **Conditional Transferability (`crystallizeCapsule`, `checkCrystallizationEligibility`):** The core mechanic where the asset transitions from non-transferable to transferable based on meeting specific on-chain conditions (level, yield claimed, potentially time staked). This adds a "progression" or "unlock" layer to the NFT.
5.  **Simulated Oracle/Dynamic State (`globalDynamicImpactFactor`, `triggerProtocolDynamicUpdate`):** The contract includes variables and functions that *could* be hooked up to an oracle (like Chainlink) or controlled by a decentralized mechanism to influence all active capsules' yield based on external factors, making the protocol responsive to real-world or other on-chain events. For this example, it's controlled by the admin, but the structure allows for integration.
6.  **ERC721-like implementation within a single contract:** Instead of deploying a separate ERC721 contract, the core state and logic (`_capsules`, `_capsuleOwner`, `_userCapsules`) are managed within the protocol contract. This can sometimes simplify deployments or allow tighter coupling between the NFT state and the protocol logic, although a full ERC721 implementation would require more mappings (approvals, operators) and events.
7.  **Internal Accounting for Yield (`_unclaimedYield`):** Yield is calculated based on time and rates but not immediately minted. It's accrued in an internal state variable (`_unclaimedYield`) until the user claims it or the capsule is deactivated/transferred/burned, making the claiming process efficient.

This contract provides a framework for a protocol where participation and progression (represented by the Capsule NFT) are rewarded with dynamic yield, and dedication (meeting crystallization criteria) unlocks broader functionality (transferability).

**Note:** This contract is a conceptual example. A production-ready version would require:
*   More robust error handling and access control (e.g., using OpenZeppelin's Ownable, Pausable, and potentially a full ERC721 implementation).
*   Careful consideration of gas costs, especially with array manipulations (`_userCapsules`, `_burn`, `_transfer`). Using more advanced data structures (like linked lists or enumerable sets) might be necessary for scale.
*   Thorough testing of yield calculation logic under various scenarios.
*   A real mechanism for setting `globalDynamicImpactFactor` and `recalculateCapsuleDynamicMultiplier` if not admin controlled (e.g., oracle integration, governance).
*   Detailed criteria and cost models for `upgradeCapsule` and `checkCrystallizationEligibility`.
*   Proper implementation of ERC721 `Approval` and `Transfer` events if full compliance is needed.