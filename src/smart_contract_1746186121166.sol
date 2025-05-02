Okay, let's design a smart contract around the concept of an evolving, on-chain digital artifact or narrative influenced by user actions and time. We'll call it the "Ethereal Chronicle". Users will own "Fragments" (NFTs) that they can use to influence the Chronicle's state, progressing through different "Eras" and unlocking new properties for their Fragments.

This incorporates:
*   **Dynamic NFTs:** Fragment properties change based on interactions and Chronicle state.
*   **Collective State Influence:** User actions cumulatively affect the main contract's state.
*   **Time/Event-Based Progression:** The Chronicle moves through distinct Eras.
*   **Complex State Management:** Tracking influence, fragment properties, era data.
*   **Role-Based/Timed Access:** Using modifiers for specific actions.

It aims to be unique by tying individual NFT utility directly into a shared, evolving contract state narrative, where NFTs aren't just static collectibles but active participants in a larger, dynamic system.

---

### **Ethereal Chronicle: Contract Outline and Function Summary**

**Contract Name:** `EtherealChronicle`

**Core Concepts:**
1.  **Fragments:** ERC721 tokens representing pieces of the Ethereal Chronicle. Each has dynamic properties like Power, Affinity, and a history of Eras participated in.
2.  **The Chronicle:** The main contract state, progressing through distinct Eras. Each Era has a target Influence level.
3.  **Influence:** Users contribute Influence to the current Era by using their Fragments. This cumulative Influence drives the Chronicle's progression.
4.  **Eras:** Sequential stages of the Chronicle. Each Era might have unique rules, effects on Fragments, or unlock new functionalities. Era transitions can be triggered by reaching influence goals (confirmed by admin for stability).

**State Variables:**
*   Basic ERC721 state (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`)
*   Chronicle State (`currentEra`, `currentEraTotalInfluence`, `nextEraInfluenceTarget`)
*   Fragment Data (`FragmentData` struct: `power`, `affinity`, `lastUsedEra`, `eraHistory`) mapped by token ID.
*   User Data (`userInfluenceInEra` mapped by era -> user -> influence)
*   Administrative (`_owner`, `pausedState`)
*   Constants/Parameters (`INFLUENCE_COOLDOWN_ERAS`, `BASE_MINT_POWER`)

**Events:**
*   `FragmentMinted`
*   `InfluenceGained`
*   `EraTransitioned`
*   `FragmentAttuned`
*   `ChroniclePaused`
*   `ChronicleUnpaused`
*   `InfluenceTargetUpdated`
*   `AdminAction`

**Modifiers:**
*   `whenNotPaused`: Requires the contract is not paused.
*   `onlyOwner`: Restricts access to the contract owner.
*   `onlyFragmentOwner`: Restricts access to the owner of a specific fragment.
*   `onlyInCurrentEra`: Restricts action to the current era.

**Functions Summary (29 functions):**

**ERC721 Core (Inherited/Standard Overrides - 8 functions):**
1.  `balanceOf(address owner) public view returns (uint256)`: Returns the number of tokens owned by an address.
2.  `ownerOf(uint256 tokenId) public view returns (address)`: Returns the owner of a specific token.
3.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes data) public nonpayable`: Safely transfers a token with data.
4.  `safeTransferFrom(address from, address to, uint256 tokenId) public nonpayable`: Safely transfers a token without data.
5.  `transferFrom(address from, address to, uint256 tokenId) public nonpayable`: Transfers a token.
6.  `approve(address to, uint256 tokenId) public nonpayable`: Grants approval for another address to transfer a specific token.
7.  `setApprovalForAll(address operator, bool approved) public nonpayable`: Grants or revokes approval for an operator to manage all tokens.
8.  `getApproved(uint256 tokenId) public view returns (address)`: Returns the approved address for a single token.
9.  `isApprovedForAll(address owner, address operator) public view returns (bool)`: Checks if an operator is approved for all tokens of an owner.

**Fragment Management & Acquisition (4 functions):**
10. `mintFragment(address to) public onlyOwner returns (uint256 tokenId)`: Mints a new Fragment token and assigns it to an address with base properties.
11. `batchMintFragments(address[] calldata tos) public onlyOwner returns (uint256[] memory tokenIds)`: Mints multiple Fragments to different addresses efficiently.
12. `attuneFragment(uint256 tokenId) public nonpayable onlyFragmentOwner(tokenId) whenNotPaused`: Allows a fragment owner to 'attune' their fragment, potentially altering its properties based on the current Era state (e.g., slight power boost, affinity shift).
13. `queryFragmentData(uint256 tokenId) public view returns (uint256 power, uint8 affinity, uint256 lastUsedEra)`: Retrieves the core dynamic properties of a specific Fragment.

**Chronicle Interaction (5 functions):**
14. `useFragmentForInfluence(uint256 tokenId) public nonpayable onlyFragmentOwner(tokenId) whenNotPaused onlyInCurrentEra`: The core action. Uses a fragment to contribute Influence to the current Era, updates fragment state (last used era), and records user influence. Requires fragment not used in `INFLUENCE_COOLDOWN_ERAS`.
15. `queryUserInfluenceInEra(uint256 era, address user) public view returns (uint256)`: Checks how much influence a specific user contributed in a given Era.
16. `witnessEraTransition(uint256 tokenId) public nonpayable onlyFragmentOwner(tokenId)`: Allows a fragment owner who *didn't* use their fragment in the *last* era to register it for the new era and potentially receive a minor passive update or record their presence without active contribution.
17. `contributeEraEvent(uint256 tokenId, uint8 eventType, bytes data) public nonpayable onlyFragmentOwner(tokenId) whenNotPaused onlyInCurrentEra`: A more complex interaction where specific fragment types/properties might be needed to contribute to mini-events within an Era, potentially yielding special influence or fragment property changes. (Requires more complex internal logic).
18. `queryFragmentEraHistory(uint256 tokenId) public view returns (uint256[] memory)`: Retrieves the list of Eras a fragment has participated in.

**Chronicle State Queries (4 functions):**
19. `queryCurrentEra() public view returns (uint256)`: Returns the index of the current Chronicle Era.
20. `queryCurrentEraTotalInfluence() public view returns (uint256)`: Returns the total influence contributed to the *currently active* Era.
21. `queryNextEraInfluenceTarget() public view returns (uint256)`: Returns the influence needed to potentially transition to the next Era.
22. `getTotalSupply() public view returns (uint256)`: Returns the total number of Fragments minted (standard ERC721 query).

**Administration & Progression (8 functions):**
23. `initiateNextEra() public onlyOwner whenNotPaused`: Allows the owner to trigger the transition to the next Era, *only if* the current Era's influence target is met. Resets era-specific state, updates fragment cooldowns conceptually.
24. `setNextEraInfluenceTarget(uint256 target) public onlyOwner`: Allows the owner to set the influence threshold for the *upcoming* Era transition.
25. `pauseChronicleInteractions() public onlyOwner`: Pauses all interactions that modify Chronicle or Fragment state (minting might remain active).
26. `unpauseChronicleInteractions() public onlyOwner`: Unpauses the Chronicle interactions.
27. `setFragmentBasePower(uint256 newPower) public onlyOwner`: Sets the base power assigned to newly minted Fragments.
28. `setInfluenceCooldownEras(uint256 cooldown) public onlyOwner`: Sets how many Eras a Fragment must wait after being used before it can be used again for influence.
29. `updateFragmentPower(uint256 tokenId, uint256 newPower) public onlyOwner`: Allows the owner to manually adjust a fragment's power (e.g., for events, rewards, or penalties).
30. `withdrawEth(uint256 amount) public onlyOwner`: Allows the owner to withdraw any accumulated ETH (if contract receives funds, e.g., from minting fees - though not planned in this free mint example, good practice).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// 1. Contract Imports and Header
// 2. Events
// 3. State Variables
//    - ERC721 Core state (handled by inheritance)
//    - Chronicle State (Era progression, influence)
//    - Fragment Data (Dynamic properties per token)
//    - User/Fragment Interaction State (Cooldowns, specific influence)
//    - Administrative State (Owner, Paused)
//    - Constants & Parameters
// 4. Structs
//    - FragmentData
// 5. Modifiers
//    - whenNotPaused, onlyOwner, onlyFragmentOwner, onlyInCurrentEra
// 6. Constructor
// 7. ERC721 Core Functions (Inherited or Standard Overrides)
//    - balanceOf, ownerOf, safeTransferFrom, transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, supportsInterface
// 8. Fragment Management & Acquisition
//    - mintFragment, batchMintFragments, attuneFragment, queryFragmentData
// 9. Chronicle Interaction
//    - useFragmentForInfluence, queryUserInfluenceInEra, witnessEraTransition, contributeEraEvent, queryFragmentEraHistory
// 10. Chronicle State Queries
//    - queryCurrentEra, queryCurrentEraTotalInfluence, queryNextEraInfluenceTarget, getTotalSupply (from ERC721Enumerable)
// 11. Administration & Progression
//    - initiateNextEra, setNextEraInfluenceTarget, pauseChronicleInteractions, unpauseChronicleInteractions,
//    - setFragmentBasePower, setInfluenceCooldownEras, updateFragmentPower, withdrawEth
// 12. Internal Helpers (Optional but good practice)

// Function Summary:
// See detailed list above outline. Provides ERC721 standard functionality plus complex logic for:
// - Dynamic NFT property management (power, affinity, history).
// - Collective influence contribution towards a shared goal (Era progression).
// - Era-based mechanics affecting interactions and fragment state.
// - Administrative control over Chronicle parameters and progression triggers.

contract EtherealChronicle is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Events ---
    event FragmentMinted(uint256 indexed tokenId, address indexed owner, uint256 initialPower, uint8 initialAffinity);
    event InfluenceGained(uint256 indexed era, address indexed user, uint256 indexed tokenId, uint256 influenceAmount, uint256 newTotalInfluence);
    event EraTransitioned(uint256 indexed oldEra, uint256 indexed newEra, uint256 influenceAchieved);
    event FragmentAttuned(uint256 indexed tokenId, uint256 indexed era, uint256 newPower, uint8 newAffinity);
    event ChroniclePaused(address indexed account);
    event ChronicleUnpaused(address indexed account);
    event InfluenceTargetUpdated(uint256 indexed era, uint256 oldTarget, uint256 newTarget);
    event AdminAction(string action, bytes data); // Generic admin action log

    // --- Structs ---
    struct FragmentData {
        uint256 power;         // Base influence power
        uint8 affinity;        // e.g., 0: None, 1: Fire, 2: Water, 3: Earth, 4: Air, etc.
        uint256 lastUsedEra;   // Era fragment was last used for influence (0 if never)
        uint256[] eraHistory;  // List of eras this fragment participated in (used/witnessed)
    }

    // --- State Variables ---
    mapping(uint256 => FragmentData) private _fragmentData;

    uint256 public currentEra = 1;
    uint256 public currentEraTotalInfluence = 0;
    uint256 public nextEraInfluenceTarget; // Target for currentEra+1

    // userInfluenceInEra[era][user] => influence amount
    mapping(uint256 => mapping(address => uint256)) private _userInfluenceInEra;

    // fragmentUseCooldown[tokenId] => era it can be used again
    // Simplified: Using lastUsedEra + INFLUENCE_COOLDOWN_ERAS determines availability
    uint256 public INFLUENCE_COOLDOWN_ERAS = 2; // Fragment can be used every X eras (e.g., every 2 eras)

    bool public paused = false;

    uint256 public BASE_MINT_POWER = 100; // Initial power for new fragments

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Chronicle: Paused");
        _;
    }

    modifier onlyFragmentOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Chronicle: Not fragment owner or approved");
        _;
    }

    modifier onlyInCurrentEra() {
        // Add checks here if certain functions are only allowed AT specific points in an era
        // For useFragmentForInfluence, we just check the fragment's cooldown *relative* to the current era
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol, uint256 initialInfluenceTarget)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        nextEraInfluenceTarget = initialInfluenceTarget;
        emit AdminAction("ContractInitialised", abi.encode(initialInfluenceTarget));
    }

    // --- ERC721 Core Functions (Standard & Overrides) ---
    // All standard ERC721 functions like balanceOf, ownerOf,
    // safeTransferFrom, transferFrom, approve, setApprovalForAll,
    // getApproved, isApprovedForAll, supportsInterface are inherited
    // and work with the internal _owners, _balances, _tokenApprovals, _operatorApprovals mappings.

    // Override tokenURI to reflect dynamic properties (Conceptual)
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real scenario, this would point to a dynamic service
        // that retrieves the fragment's data from this contract
        // (queryFragmentData) and generates metadata JSON including
        // power, affinity, era history, etc.
        // For this example, we return a placeholder or base URI + ID.
        string memory base = "ipfs://your_base_uri/";
        string memory fragmentData = string(abi.encodePacked(
            "{\"name\": \"Ethereal Chronicle Fragment #",
            _toString(tokenId),
            "\", \"description\": \"A piece of the evolving Ethereal Chronicle.\", \"attributes\": [",
            "{\"trait_type\": \"Era\", \"value\": ", _toString(currentEra), "},",
            "{\"trait_type\": \"Power\", \"value\": ", _toString(_fragmentData[tokenId].power), "},",
            "{\"trait_type\": \"Affinity\", \"value\": ", _toString(_fragmentData[tokenId].affinity), "},",
            "{\"trait_type\": \"Last Used Era\", \"value\": ", _toString(_fragmentData[tokenId].lastUsedEra), "}",
             // Add eraHistory array representation if desired
            "]}"
        ));
         // A real implementation would likely upload this JSON to IPFS or use an API
         // and return the IPFS hash or API endpoint URL.
         // For simplicity, concatenating a basic JSON structure here (not production ready).
         // You would typically use a library like Base64 or a service to handle this.
        return string(abi.encodePacked(base, _toString(tokenId), ".json"));
    }


    // --- Fragment Management & Acquisition ---

    /// @notice Mints a new Fragment token to the specified address. Only callable by owner.
    /// @param to The address to mint the token to.
    /// @return The ID of the newly minted token.
    function mintFragment(address to) public onlyOwner returns (uint256 tokenId) {
        _tokenIdCounter.increment();
        tokenId = _tokenIdCounter.current();
        _safeMint(to, tokenId);

        // Assign initial dynamic properties
        _fragmentData[tokenId] = FragmentData({
            power: BASE_MINT_POWER,
            affinity: uint8(tokenId % 5), // Example: assign affinity based on ID
            lastUsedEra: 0,
            eraHistory: new uint256[](0)
        });

        emit FragmentMinted(tokenId, to, BASE_MINT_POWER, uint8(tokenId % 5));
    }

    /// @notice Mints multiple Fragment tokens to a list of addresses. Only callable by owner.
    /// @param tos An array of addresses to mint tokens to.
    /// @return An array of the IDs of the newly minted tokens.
    function batchMintFragments(address[] calldata tos) public onlyOwner returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](tos.length);
        for (uint i = 0; i < tos.length; i++) {
            tokenIds[i] = mintFragment(tos[i]); // Reuse single mint logic
        }
    }

    /// @notice Allows a fragment owner to 'attune' their fragment, potentially altering properties.
    /// @dev This function could incorporate complex logic based on the current era,
    ///      fragment properties, or even require spending another resource.
    ///      Here, it provides a minor power boost and potentially shifts affinity.
    /// @param tokenId The ID of the fragment to attune.
    function attuneFragment(uint256 tokenId) public nonpayable onlyFragmentOwner(tokenId) whenNotPaused {
        FragmentData storage fragment = _fragmentData[tokenId];

        // Example attunement logic:
        // Gain 1% of current power, rounded down
        uint256 powerBoost = fragment.power / 100;
        if (powerBoost < 1) powerBoost = 1; // Minimum boost
        fragment.power += powerBoost;

        // Slight chance to shift affinity
        // This would ideally use a more robust random source than tokenId % value
        // For demonstration, let's just cycle affinity
        fragment.affinity = (fragment.affinity + 1) % 5; // Cycle through 0,1,2,3,4

        // Record attunement in history? Or special attunement history?
        // For simplicity, not adding a separate history type here.

        emit FragmentAttuned(tokenId, currentEra, fragment.power, fragment.affinity);
    }

    /// @notice Retrieves the core dynamic properties of a specific Fragment.
    /// @param tokenId The ID of the fragment to query.
    /// @return power The current power level of the fragment.
    /// @return affinity The current affinity value of the fragment.
    /// @return lastUsedEra The last era the fragment was used for influence (0 if never).
    function queryFragmentData(uint256 tokenId) public view returns (uint256 power, uint8 affinity, uint256 lastUsedEra) {
        require(_exists(tokenId), "Chronicle: Token does not exist");
        FragmentData storage fragment = _fragmentData[tokenId];
        return (fragment.power, fragment.affinity, fragment.lastUsedEra);
    }


    // --- Chronicle Interaction ---

    /// @notice Uses a fragment to contribute Influence to the current Era.
    /// @dev Requires the fragment not be on cooldown. Updates fragment history and cooldown.
    /// @param tokenId The ID of the fragment to use.
    function useFragmentForInfluence(uint256 tokenId) public nonpayable onlyFragmentOwner(tokenId) whenNotPaused onlyInCurrentEra nonReentrant {
        FragmentData storage fragment = _fragmentData[tokenId];
        address fragmentOwner = ownerOf(tokenId);

        // Check cooldown based on eras
        require(currentEra >= fragment.lastUsedEra + INFLUENCE_COOLDOWN_ERAS, "Chronicle: Fragment on cooldown");

        // Calculate influence gained (can be modified by era, affinity, etc.)
        uint256 influenceGained = fragment.power; // Simple: Influence equals power

        // Update fragment state
        fragment.lastUsedEra = currentEra;
        // Add current era to fragment's history if not already there for this era
        if (fragment.eraHistory.length == 0 || fragment.eraHistory[fragment.eraHistory.length - 1] != currentEra) {
             fragment.eraHistory.push(currentEra);
        }


        // Update Chronicle and user state
        currentEraTotalInfluence += influenceGained;
        _userInfluenceInEra[currentEra][fragmentOwner] += influenceGained;

        emit InfluenceGained(currentEra, fragmentOwner, tokenId, influenceGained, currentEraTotalInfluence);
    }

    /// @notice Checks how much influence a specific user contributed in a given Era.
    /// @param era The era to query influence for.
    /// @param user The address of the user to query.
    /// @return The total influence contributed by the user in that era.
    function queryUserInfluenceInEra(uint256 era, address user) public view returns (uint256) {
        return _userInfluenceInEra[era][user];
    }

    /// @notice Allows a fragment owner who *didn't* use their fragment for influence in the *last* era
    ///         to register its presence in the *new* era, recording its participation.
    /// @dev This is for fragments that were "passive" during the last influence phase.
    ///      Could have minor effects, like adding era to history without influence gain.
    /// @param tokenId The ID of the fragment to register.
    function witnessEraTransition(uint256 tokenId) public nonpayable onlyFragmentOwner(tokenId) whenNotPaused {
        FragmentData storage fragment = _fragmentData[tokenId];
        // Check if fragment was NOT used for influence in the *previous* era
        require(fragment.lastUsedEra < currentEra, "Chronicle: Fragment was used in the previous era influence round");
        // Check if fragment hasn't already registered for this era
        require(fragment.eraHistory.length == 0 || fragment.eraHistory[fragment.eraHistory.length - 1] != currentEra, "Chronicle: Fragment already witnessed this era");

        // Record presence in the new era's history
        fragment.eraHistory.push(currentEra);

        // Could add minor passive effects here, e.g., very small power increase, or record a specific trait for this era.
        // For simplicity, just updating history here.

        // Emit a specific event if needed, or log via AdminAction if it triggers admin review
        // emit FragmentWitnessed(tokenId, currentEra); // Example custom event if desired
        emit AdminAction("FragmentWitnessed", abi.encode(tokenId, currentEra, ownerOf(tokenId)));
    }


    /// @notice A more complex interaction where specific fragment types might be needed to contribute to Era-specific events.
    /// @dev This is a placeholder for a potentially complex game mechanic.
    ///      Requires custom logic based on `eventType` and `data`, potentially checking fragment properties.
    /// @param tokenId The ID of the fragment used.
    /// @param eventType An identifier for the type of event being contributed to.
    /// @param data Additional data relevant to the event contribution.
    function contributeEraEvent(uint256 tokenId, uint8 eventType, bytes data) public nonpayable onlyFragmentOwner(tokenId) whenNotPaused onlyInCurrentEra {
         FragmentData storage fragment = _fragmentData[tokenId];
         // Example: require a specific affinity for eventType 1
         if (eventType == 1) {
             require(fragment.affinity == 3, "Chronicle: Fragment needs Earth affinity for this event");
             // Process data, potentially give special influence or property change
             // ... complex event specific logic ...
             emit AdminAction("EraEventContribution", abi.encode(currentEra, tokenId, eventType, data));
         } else if (eventType == 2) {
              // Another event type logic
              emit AdminAction("EraEventContribution", abi.encode(currentEra, tokenId, eventType, data));
         } else {
             revert("Chronicle: Unknown event type");
         }
        // Mark fragment as used for *something* in this era if needed, distinct from influence use?
        // Or maybe event contribution is a *type* of influence use, subject to same cooldown?
        // Depends on game design. Let's assume it's a separate action for now.
         if (fragment.eraHistory.length == 0 || fragment.eraHistory[fragment.eraHistory.length - 1] != currentEra) {
             fragment.eraHistory.push(currentEra);
         }
    }

    /// @notice Retrieves the list of Eras a fragment has participated in (used for influence or witnessed).
    /// @param tokenId The ID of the fragment to query.
    /// @return An array of era numbers.
    function queryFragmentEraHistory(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "Chronicle: Token does not exist");
        return _fragmentData[tokenId].eraHistory;
    }


    // --- Chronicle State Queries ---

    /// @notice Returns the index of the current Chronicle Era.
    function queryCurrentEra() public view returns (uint256) {
        return currentEra;
    }

    /// @notice Returns the total influence contributed to the *currently active* Era.
    function queryCurrentEraTotalInfluence() public view returns (uint256) {
        return currentEraTotalInfluence;
    }

    /// @notice Returns the influence needed to potentially transition to the next Era (Era `currentEra` + 1).
    function queryNextEraInfluenceTarget() public view returns (uint256) {
        return nextEraInfluenceTarget;
    }

    // getTotalSupply is inherited from ERC721Enumerable

    // --- Administration & Progression ---

    /// @notice Allows the owner to trigger the transition to the next Era.
    /// @dev Requires the current Era's influence target to be met. Resets era-specific state.
    function initiateNextEra() public onlyOwner whenNotPaused nonReentrant {
        require(currentEraTotalInfluence >= nextEraInfluenceTarget, "Chronicle: Influence target not met for next era");

        uint256 oldEra = currentEra;
        currentEra++;

        // Reset state for the new era
        currentEraTotalInfluence = 0;
        // _userInfluenceInEra for the *old* era persists, but the *new* era mapping is initially empty.
        // _fragmentData.lastUsedEra updates happen when useFragmentForInfluence is called in the *new* era.

        // Define the influence target for the *new* next era (currentEra + 1)
        // This could be fixed, calculated based on previous era, or set by admin later.
        // Example: increase target slightly each era.
        // nextEraInfluenceTarget = nextEraInfluenceTarget + (nextEraInfluenceTarget / 10); // Increase by 10%
        // Or keep it manual for admin control: require admin to call setNextEraInfluenceTarget

        emit EraTransitioned(oldEra, currentEra, currentEraTotalInfluence); // Note: Influence achieved is from the *previous* era
        emit AdminAction("EraTransitionInitiated", abi.encode(oldEra, currentEra, nextEraInfluenceTarget));
    }

    /// @notice Allows the owner to set the influence threshold for the *upcoming* Era transition (i.e., the target for the *current* era).
    /// @param target The new influence target for the current era.
    function setNextEraInfluenceTarget(uint256 target) public onlyOwner {
        uint256 oldTarget = nextEraInfluenceTarget;
        nextEraInfluenceTarget = target;
        emit InfluenceTargetUpdated(currentEra, oldTarget, nextEraInfluenceTarget);
        emit AdminAction("NextEraInfluenceTargetSet", abi.encode(currentEra, target));
    }

    /// @notice Pauses core Chronicle interactions (useFragmentForInfluence, attuneFragment, contributeEraEvent, witnessEraTransition).
    /// @dev Minting is explicitly *not* paused by this, but could be added.
    function pauseChronicleInteractions() public onlyOwner {
        require(!paused, "Chronicle: Already paused");
        paused = true;
        emit ChroniclePaused(_msgSender());
        emit AdminAction("ChronicleInteractionsPaused", "");
    }

    /// @notice Unpauses core Chronicle interactions.
    function unpauseChronicleInteractions() public onlyOwner {
        require(paused, "Chronicle: Not paused");
        paused = false;
        emit ChronicleUnpaused(_msgSender());
        emit AdminAction("ChronicleInteractionsUnpaused", "");
    }

    /// @notice Sets the base power assigned to newly minted Fragments.
    /// @param newPower The new base power value.
    function setFragmentBasePower(uint256 newPower) public onlyOwner {
        BASE_MINT_POWER = newPower;
        emit AdminAction("FragmentBasePowerSet", abi.encode(newPower));
    }

    /// @notice Sets how many Eras a Fragment must wait after being used before it can be used again for influence.
    /// @param cooldown The number of eras for the cooldown.
    function setInfluenceCooldownEras(uint256 cooldown) public onlyOwner {
        INFLUENCE_COOLDOWN_ERAS = cooldown;
        emit AdminAction("InfluenceCooldownSet", abi.encode(cooldown));
    }

    /// @notice Allows the owner to manually adjust a fragment's power.
    /// @dev Use with caution. Could be used for rewards, penalties, or fixing errors.
    /// @param tokenId The ID of the fragment to update.
    /// @param newPower The new power value for the fragment.
    function updateFragmentPower(uint256 tokenId, uint256 newPower) public onlyOwner {
        require(_exists(tokenId), "Chronicle: Token does not exist");
        uint256 oldPower = _fragmentData[tokenId].power;
        _fragmentData[tokenId].power = newPower;
        emit AdminAction("FragmentPowerUpdated", abi.encode(tokenId, oldPower, newPower));
    }

    /// @notice Allows the owner to withdraw any accumulated ETH from the contract.
    /// @param amount The amount of ETH to withdraw.
    function withdrawEth(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Chronicle: Insufficient balance");
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Chronicle: ETH withdrawal failed");
        emit AdminAction("EthWithdrawn", abi.encode(amount));
    }

    // --- Internal Helpers (Standard) ---
    // _baseURI() is needed for tokenURI. Returning empty string or base URI.
    function _baseURI() internal view override returns (string memory) {
        return ""; // Or a default URI if needed
    }

     // Helper to convert uint256 to string (for tokenURI)
    function _toString(uint256 value) internal pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Required ERC721 receiver check.
    // In this design, we don't have specific onERC721Received logic,
    // but including the interface is good practice if interacting with contracts
    // that might send tokens this way.
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
    //     // Optional: handle incoming transfers here if needed
    //     return this.onERC721Received.selector;
    // }
}
```