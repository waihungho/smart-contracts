Okay, here is a Solidity smart contract implementing a `MetaMorphoGnome` concept. This contract combines ERC721 NFT ownership with dynamic on-chain attributes, evolution/morphing mechanics based on various triggers (internal state, external data, combining NFTs), staking for rewards, interaction with external resources/items, simple on-chain game-like actions (quests, duels), delegation of specific rights, procedural art generation identifiers, and meta-transaction support.

It uses OpenZeppelin libraries for standard functionalities like ERC721 and AccessControl, but the core logic for Gnome state, morphing, interactions, etc., is custom.

---

**Contract Name:** `MetaMorphoGnome`

**Concept:** This contract represents a collection of dynamic, non-fungible tokens called "MetaMorphoGnomes". Each Gnome has on-chain attributes (level, stats, form, DNA) that can change based on various interactions and conditions. The contract introduces concepts like morphing/evolution, staking, resource interaction, item equipping, quests, duels, delegation of specific token rights, on-chain procedural art DNA generation, and meta-transaction execution.

---

**Outline:**

1.  **NFT Core:** Basic ERC721 functionality (ownership, transfers, approvals).
2.  **Access Control:** Role-based permissions for critical functions.
3.  **Gnome State & Attributes:** Struct to hold dynamic attributes and mappings to store them per token.
4.  **Gnome Creation:** Functions for minting Gnomes, including random attribute generation.
5.  **Attribute Management:** Functions to read and potentially update attributes.
6.  **Morphing & Evolution:** Functions to trigger state changes (morphing) based on different conditions (direct call, internal state, external data, combining Gnomes).
7.  **Interactions & Utility:**
    *   Staking: Lock Gnomes to potentially earn rewards (placeholder concept).
    *   Resource Management: Deposit and withdraw ERC20 tokens used as resources.
    *   Item Equipping: Associate external NFT items with Gnomes (storage only).
    *   Game-like Actions: Quests and duels updating Gnome state.
8.  **Advanced Features:**
    *   Right Delegation: Delegate specific actions (like morphing) for a token.
    *   Procedural Art DNA: Generate a unique string identifier based on attributes.
    *   Dynamic Metadata: Setting simple on-chain metadata like mood.
    *   Burning: Burn a Gnome for a resource.
    *   Prediction: Pure view function to simulate outcomes.
9.  **Meta-Transactions:** Allow users to execute certain functions via signed messages (requires a relayer for gas).
10. **Admin & Pausability:** Functions for pausing critical operations and setting external addresses (like oracles).
11. **Events:** To log significant actions.

---

**Function Summary:**

1.  `constructor(address initialAdmin, address rewardTokenAddress, address requiredResourceAddress)`: Initializes the contract, sets roles, and defines external token addresses.
2.  `mintGnome(address recipient)`: Mints a new Gnome NFT with default attributes to a recipient. (ADMIN_ROLE)
3.  `mintRandomGnome(address recipient, bytes32 entropy)`: Mints a new Gnome NFT with attributes partially derived from provided entropy. (ADMIN_ROLE or MINTER_ROLE)
4.  `batchMintGnomes(address[] recipients)`: Mints multiple Gnomes to an array of recipients. (ADMIN_ROLE or MINTER_ROLE)
5.  `getGnomeAttributes(uint256 tokenId)`: Returns the current attributes of a specific Gnome. (view)
6.  `getGnomeDNA(uint256 tokenId)`: Returns the generated DNA string for a Gnome. (view)
7.  `predictMorphOutcome(uint256 tokenId, uint potentialForm)`: Pure function that predicts what a Gnome's stats might look like if it morphed to a specific form. (pure)
8.  `generateProceduralArtDNA(uint256 tokenId, bytes32 seed)`: Generates and updates the on-chain `dna` string attribute for a Gnome based on its attributes and a seed. (Token Owner or Approved)
9.  `setGnomeMood(uint256 tokenId, string memory mood)`: Allows the owner to set a simple on-chain 'mood' string for their Gnome. (Token Owner or Approved)
10. `morphGnome(uint256 tokenId, uint newForm)`: Directly changes the `form` attribute of a Gnome. Requires owner/approved or MORPH_DELEGATOR_ROLE.
11. `evolveGnome(uint256 tokenId)`: Triggers an evolution process based on the Gnome's current state (e.g., level). Updates attributes including form. (Token Owner or Approved)
12. `triggerEnvironmentalMorph(uint256 tokenId, uint environmentCode, bytes memory proof)`: Molds a Gnome based on an external environmental condition, potentially verified by a proof (placeholder). (Requires specific role or logic)
13. `combineGnomes(uint256 tokenId1, uint256 tokenId2)`: Combines two Gnomes. Potentially burns one and enhances the other. Requires ownership/approval of both.
14. `stakeGnome(uint256 tokenId)`: Locks a Gnome in the contract for staking. (Token Owner or Approved)
15. `unstakeGnome(uint256 tokenId)`: Unlocks a staked Gnome. (Original Staker/Owner)
16. `claimStakingRewards(uint256[] tokenIds)`: Allows claiming accumulated rewards for staked Gnomes. (Staker)
17. `depositResource(uint256 amount)`: Deposits a required ERC20 resource token into the contract. (Anyone)
18. `withdrawResource(uint256 amount)`: Withdraws the required ERC20 resource token from the contract. (ADMIN_ROLE or RESOURCE_MANAGER_ROLE)
19. `assignSkillPoint(uint256 tokenId, uint skillType)`: Spends an internal "skill point" counter to increase a specific attribute (strength, magic, stamina). (Token Owner or Approved)
20. `equipItem(uint256 tokenId, address itemContract, uint256 itemId, uint itemSlot)`: Associates an external item (defined by contract address and ID) with a Gnome in a specific slot. (Token Owner or Approved)
21. `unequipItem(uint256 tokenId, uint itemSlot)`: Removes an item association from a Gnome. (Token Owner or Approved)
22. `sendGnomeOnQuest(uint256 tokenId, uint questId)`: Marks a Gnome as being on a quest (state change). (Token Owner or Approved)
23. `completeQuest(uint256 tokenId, bytes memory resultsProof)`: Resolves a quest for a Gnome, potentially granting rewards or changing attributes based on results (verified by oracle/proof - placeholder). (Requires QUEST_ORACLE_ROLE)
24. `resolveGnomeDuel(uint256 tokenId1, uint256 tokenId2, bytes32 randomSeed)`: Simulates a simple duel between two Gnomes on-chain, potentially affecting their state based on attributes and a seed. Requires approval/ownership of both.
25. `burnForEssence(uint256 tokenId)`: Burns a Gnome NFT and potentially grants an amount of the reward token or resource token ("Essence"). (Token Owner)
26. `pauseMorphing()`: Pauses the `morphGnome` and `evolveGnome` functions. (PAUSER_ROLE)
27. `unpauseMorphing()`: Unpauses morphing functions. (PAUSER_ROLE)
28. `setQuestOracle(address oracleAddress)`: Sets the address of the trusted oracle contract for quests. (ADMIN_ROLE)
29. `grantRole(bytes32 role, address account)`: Grants a specific access control role to an account. (Role Admin)
30. `revokeRole(bytes32 role, address account)`: Revokes a specific access control role from an account. (Role Admin)
31. `executeMetaTx(address user, bytes calldata functionCall, bytes memory signature)`: Allows a relayer to execute a function call on behalf of a user using their signature (basic ERC2771 concept). (Relayer)

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";


/// @title MetaMorphoGnome
/// @author Your Name/Alias
/// @dev An ERC721 contract for dynamic NFTs (MetaMorphoGnomes) with complex on-chain state,
/// evolution mechanics, interactions, and advanced features like delegation and meta-transactions.

// --- Outline ---
// 1. NFT Core: ERC721Enumerable
// 2. Access Control: Role-based permissions
// 3. Gnome State & Attributes: Struct and mappings
// 4. Gnome Creation: Minting with random attributes
// 5. Attribute Management: Reading and updating state
// 6. Morphing & Evolution: State changes based on triggers
// 7. Interactions & Utility: Staking, Resources, Items, Quests, Duels
// 8. Advanced Features: Delegation, Procedural DNA, Mood, Burning, Prediction, Meta-Tx
// 9. Admin & Pausability: Control and external addresses
// 10. Events: Logging actions

// --- Function Summary ---
// constructor(address initialAdmin, address rewardTokenAddress, address requiredResourceAddress)
// mintGnome(address recipient)
// mintRandomGnome(address recipient, bytes32 entropy)
// batchMintGnomes(address[] recipients)
// getGnomeAttributes(uint256 tokenId)
// getGnomeDNA(uint256 tokenId)
// predictMorphOutcome(uint256 tokenId, uint potentialForm)
// generateProceduralArtDNA(uint256 tokenId, bytes32 seed)
// setGnomeMood(uint256 tokenId, string memory mood)
// morphGnome(uint256 tokenId, uint newForm)
// evolveGnome(uint256 tokenId)
// triggerEnvironmentalMorph(uint256 tokenId, uint environmentCode, bytes memory proof)
// combineGnomes(uint256 tokenId1, uint256 tokenId2)
// stakeGnome(uint256 tokenId)
// unstakeGnome(uint256 tokenId)
// claimStakingRewards(uint256[] tokenIds)
// depositResource(uint256 amount)
// withdrawResource(uint256 amount)
// assignSkillPoint(uint256 tokenId, uint skillType)
// equipItem(uint256 tokenId, address itemContract, uint256 itemId, uint itemSlot)
// unequipItem(uint256 tokenId, uint itemSlot)
// sendGnomeOnQuest(uint256 tokenId, uint questId)
// completeQuest(uint256 tokenId, bytes memory resultsProof)
// resolveGnomeDuel(uint256 tokenId1, uint256 tokenId2, bytes32 randomSeed)
// burnForEssence(uint256 tokenId)
// pauseMorphing()
// unpauseMorphing()
// setQuestOracle(address oracleAddress)
// grantRole(bytes32 role, address account)
// revokeRole(bytes32 role, address account)
// executeMetaTx(address user, bytes calldata functionCall, bytes memory signature)


contract MetaMorphoGnome is ERC721Enumerable, AccessControl, Pausable {
    using Math for uint256;
    using ECDSA for bytes32;
    using SignatureChecker for address;

    // --- Constants ---
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MORPH_DELEGATOR_ROLE = keccak256("MORPH_DELEGATOR_ROLE"); // Role for triggering morphing on any token
    bytes32 public constant RESOURCE_MANAGER_ROLE = keccak256("RESOURCE_MANAGER_ROLE"); // Role to withdraw resources
    bytes32 public constant QUEST_ORACLE_ROLE = keccak256("QUEST_ORACLE_ROLE"); // Role to complete quests

    uint256 private _nextTokenId;

    // --- Structs ---
    struct GnomeAttributes {
        uint level;
        uint strength;
        uint magic;
        uint stamina;
        uint form; // Represents the current visual/functional form (e.g., 1=basic, 2=winged, 3=stone)
        string dna; // String representation for procedural art generation
        string mood; // Simple dynamic metadata
        uint skillPointsAvailable;
    }

    struct StakingInfo {
        uint startTime;
        address originalStaker;
        // Add reward tracking info if needed, e.g., accumulatedRewards, lastClaimTime
    }

    struct EquippedItem {
        address itemContract;
        uint256 itemId;
    }

    // --- State Variables ---
    mapping(uint256 => GnomeAttributes) private _gnomeAttributes;
    mapping(uint256 => bool) private _isStaked;
    mapping(uint256 => StakingInfo) private _stakingInfo;
    mapping(uint256 => EquippedItem[5]) private _equippedItems; // Max 5 item slots per gnome
    mapping(uint256 => uint) private _gnomeQuest; // 0 if not on quest, >0 indicates questId
    mapping(uint256 => address) private _morphDelegates; // Address allowed to morph this specific token

    address public rewardToken;
    address public requiredResource;
    address public questOracleAddress;

    // --- Events ---
    event GnomeMinted(uint256 tokenId, address indexed owner, GnomeAttributes attributes);
    event GnomeMorphed(uint256 indexed tokenId, uint oldForm, uint newForm);
    event GnomeAttributesUpdated(uint256 indexed tokenId, GnomeAttributes newAttributes);
    event GnomeCombined(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 indexed resultTokenId); // resultTokenId could be tokenId1 or a new token
    event GnomeStaked(uint256 indexed tokenId, address indexed staker);
    event GnomeUnstaked(uint256 indexed tokenId, address indexed staker);
    event RewardsClaimed(address indexed staker, uint256 amount); // Placeholder
    event ResourceDeposited(address indexed depositor, uint256 amount);
    event ResourceWithdraw(address indexed recipient, uint256 amount);
    event SkillPointAssigned(uint256 indexed tokenId, uint skillType);
    event ItemEquipped(uint256 indexed tokenId, uint indexed slot, address itemContract, uint256 itemId);
    event ItemUnequipped(uint256 indexed tokenId, uint indexed slot);
    event GnomeSentOnQuest(uint256 indexed tokenId, uint questId);
    event GnomeQuestCompleted(uint256 indexed tokenId, uint questId, bytes results);
    event GnomeDuelResolved(uint256 indexed tokenId1, uint256 indexed tokenId2, uint winnerTokenId);
    event GnomeBurnedForEssence(uint256 indexed tokenId, address indexed recipient, uint256 essenceAmount);
    event MorphPowerDelegated(uint256 indexed tokenId, address indexed delegatee);
    event MorphPowerRenounced(uint256 indexed tokenId);
    event MetaTxExecuted(address indexed user, bytes32 indexed functionSig);

    // --- Constructor ---
    constructor(address initialAdmin, address rewardTokenAddress, address requiredResourceAddress)
        ERC721("MetaMorphoGnome", "MMG")
        Pausable()
    {
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);
        _grantRole(MINTER_ROLE, initialAdmin);
        _grantRole(PAUSER_ROLE, initialAdmin);
        _grantRole(RESOURCE_MANAGER_ROLE, initialAdmin);
        // Initial admin can grant other roles like MORPH_DELEGATOR_ROLE, QUEST_ORACLE_ROLE

        rewardToken = rewardTokenAddress;
        requiredResource = requiredResourceAddress;
        _nextTokenId = 0;
    }

    // --- Access Control Overrides ---
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Internal Helpers ---
    function _isTokenOwnerOrApproved(uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return msg.sender == owner || isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender;
    }

     function _isTokenOwnerOrDelegate(uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return msg.sender == owner || isApprovedForAll(owner, msg.sender) || getApproved(tokenId) == msg.sender || _morphDelegates[tokenId] == msg.sender;
    }


    function _generateRandomAttributes(bytes32 entropy) internal pure returns (GnomeAttributes memory) {
        // Simple deterministic pseudo-random generation based on entropy
        uint _level = 1; // Start at level 1
        uint _strength = (uint(keccak256(abi.encodePacked(entropy, "strength"))) % 10) + 1; // 1-10
        uint _magic = (uint(keccak256(abi.encodePacked(entropy, "magic"))) % 10) + 1;     // 1-10
        uint _stamina = (uint(keccak256(abi.encodePacked(entropy, "stamina"))) % 10) + 1;   // 1-10
        uint _form = (uint(keccak256(abi.encodePacked(entropy, "form"))) % 3) + 1;         // 1-3 (basic forms)
        string memory _dna = ""; // Placeholder, generated later
        string memory _mood = "Neutral";
        uint _skillPoints = 0;

        return GnomeAttributes({
            level: _level,
            strength: _strength,
            magic: _magic,
            stamina: _stamina,
            form: _form,
            dna: _dna,
            mood: _mood,
            skillPointsAvailable: _skillPoints
        });
    }

    function _processQuestResults(uint256 tokenId, bytes memory resultsProof) internal {
        // *** ADVANCED CONCEPT: Placeholder for verifying external quest results ***
        // In a real application, this would involve:
        // 1. Calling a trusted oracle contract (questOracleAddress) with resultsProof.
        // 2. The oracle verifies the proof (e.g., ZK proof, signed data).
        // 3. Based on the verified results, update gnome attributes, grant items/tokens, etc.
        // For this example, we'll just simulate a simple level up.

        require(hasRole(QUEST_ORACLE_ROLE, msg.sender), "Only Oracle Role can complete quests");
        require(_gnomeQuest[tokenId] > 0, "Gnome is not on a quest");

        // Simulate success - grant exp/level up
        GnomeAttributes storage attrs = _gnomeAttributes[tokenId];
        attrs.level += 1;
        attrs.skillPointsAvailable += 2; // Grant points for leveling up
        _gnomeQuest[tokenId] = 0; // Mark quest as complete

        emit GnomeQuestCompleted(tokenId, _gnomeQuest[tokenId], resultsProof);
        emit GnomeAttributesUpdated(tokenId, attrs);
    }

    // --- Gnome Creation ---

    /// @notice Mints a new Gnome NFT with default attributes.
    /// @param recipient The address to receive the new Gnome.
    function mintGnome(address recipient) public onlyRole(MINTER_ROLE) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(recipient, newTokenId);
        GnomeAttributes memory initialAttrs = GnomeAttributes({
            level: 1,
            strength: 5,
            magic: 5,
            stamina: 5,
            form: 1, // Default basic form
            dna: "", // Empty DNA initially
            mood: "Neutral",
            skillPointsAvailable: 0
        });
        _gnomeAttributes[newTokenId] = initialAttrs;
        emit GnomeMinted(newTokenId, recipient, initialAttrs);
    }

    /// @notice Mints a new Gnome NFT with attributes derived from provided entropy.
    /// @param recipient The address to receive the new Gnome.
    /// @param entropy A random seed (e.g., hash of block, tx, or VRF output).
    function mintRandomGnome(address recipient, bytes32 entropy) public onlyRole(MINTER_ROLE) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(recipient, newTokenId);
        GnomeAttributes memory randomAttrs = _generateRandomAttributes(entropy);
        _gnomeAttributes[newTokenId] = randomAttrs;
        emit GnomeMinted(newTokenId, recipient, randomAttrs);
    }

    /// @notice Mints multiple Gnomes to an array of recipients.
    /// @param recipients An array of addresses to receive Gnomes.
    function batchMintGnomes(address[] calldata recipients) public onlyRole(MINTER_ROLE) {
        for (uint i = 0; i < recipients.length; i++) {
            uint256 newTokenId = _nextTokenId++;
            _safeMint(recipients[i], newTokenId);
             GnomeAttributes memory initialAttrs = GnomeAttributes({
                level: 1,
                strength: 5,
                magic: 5,
                stamina: 5,
                form: 1,
                dna: "",
                mood: "Neutral",
                skillPointsAvailable: 0
            });
            _gnomeAttributes[newTokenId] = initialAttrs;
            emit GnomeMinted(newTokenId, recipients[i], initialAttrs);
        }
    }

    // --- Attribute Management & View Functions ---

    /// @notice Returns the current attributes of a specific Gnome.
    /// @param tokenId The ID of the Gnome.
    /// @return GnomeAttributes struct containing the Gnome's stats and state.
    function getGnomeAttributes(uint256 tokenId) public view returns (GnomeAttributes memory) {
        require(_exists(tokenId), "Gnome does not exist");
        return _gnomeAttributes[tokenId];
    }

    /// @notice Returns the procedural art DNA string for a Gnome.
    /// @param tokenId The ID of the Gnome.
    /// @return string The DNA string.
    function getGnomeDNA(uint256 tokenId) public view returns (string memory) {
         require(_exists(tokenId), "Gnome does not exist");
        return _gnomeAttributes[tokenId].dna;
    }

    /// @notice Allows the owner to set a simple on-chain 'mood' string for their Gnome.
    /// @param tokenId The ID of the Gnome.
    /// @param mood The string representing the Gnome's mood.
    function setGnomeMood(uint256 tokenId, string memory mood) public {
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        _gnomeAttributes[tokenId].mood = mood;
        // Could add an event here if needed
    }


    // --- Morphing & Evolution ---

    /// @notice Directly changes the 'form' attribute of a Gnome.
    /// @dev This is a basic morphing function. More complex evolution uses evolveGnome.
    /// @param tokenId The ID of the Gnome.
    /// @param newForm The ID of the new form.
    function morphGnome(uint256 tokenId, uint newForm) public whenNotPaused {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrDelegate(tokenId) || hasRole(MORPH_DELEGATOR_ROLE, msg.sender), "Caller not authorized to morph this gnome");
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");

        GnomeAttributes storage attrs = _gnomeAttributes[tokenId];
        uint oldForm = attrs.form;
        attrs.form = newForm; // Basic form change

        // Attributes could be adjusted here based on the form change
        attrs.strength += (newForm > oldForm ? 1 : 0); // Simple example attribute change

        emit GnomeMorphed(tokenId, oldForm, newForm);
        emit GnomeAttributesUpdated(tokenId, attrs);
    }

    /// @notice Triggers an evolution process for a Gnome based on its current state (e.g., level).
    /// @param tokenId The ID of the Gnome.
    function evolveGnome(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrDelegate(tokenId), "Caller is not owner/delegate nor approved");
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");

        GnomeAttributes storage attrs = _gnomeAttributes[tokenId];

        // *** ADVANCED CONCEPT: Complex Evolution Logic ***
        // This is where you'd put logic based on multiple factors:
        // - attrs.level: e.g., level > 10 triggers a morph
        // - items equipped: e.g., needs a specific item equipped
        // - resources spent: e.g., burn 100 requiredResource tokens
        // - time staked: e.g., must have been staked for 30 days
        // - external conditions: oracle calls

        require(attrs.level >= 5, "Gnome requires level 5 for basic evolution"); // Simple level requirement
        // require(IERC20(requiredResource).transferFrom(msg.sender, address(this), 100), "Resource deposit failed"); // Example resource cost

        uint oldForm = attrs.form;
        uint newForm = oldForm + 1; // Simple evolution: next form

        // Prevent evolving past a max form, or loop back
        uint maxForm = 5;
        if (newForm > maxForm) {
            newForm = 1; // Loop back or stop
        }

        attrs.form = newForm;
        attrs.level = 1; // Reset level? Or keep it? Depends on game design.
        attrs.strength += 2; // Stat boost on evolution

        emit GnomeMorphed(tokenId, oldForm, newForm);
        emit GnomeAttributesUpdated(tokenId, attrs);
    }

    /// @notice Morphs a Gnome based on an external environmental condition, potentially verified by a proof.
    /// @param tokenId The ID of the Gnome.
    /// @param environmentCode An identifier for the environment type.
    /// @param proof A bytes array containing data/proof verified by an oracle. (Placeholder)
    function triggerEnvironmentalMorph(uint256 tokenId, uint environmentCode, bytes memory proof) public whenNotPaused {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrDelegate(tokenId), "Caller is not owner/delegate nor approved"); // Can also restrict this to a specific role
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");

        // *** ADVANCED CONCEPT: Oracle Integration / Proof Verification ***
        // In a real application, this proof would be verified:
        // E.g., `require(questOracleAddress.isValidEnvironmentalProof(environmentCode, proof), "Invalid environmental proof");`
        // For this example, assume the proof is valid if msg.sender has the QUEST_ORACLE_ROLE
        require(hasRole(QUEST_ORACLE_ROLE, msg.sender), "Environmental morph requires oracle role");


        GnomeAttributes storage attrs = _gnomeAttributes[tokenId];
        uint oldForm = attrs.form;
        uint newForm = environmentCode; // Example: environment code dictates new form

        // Adjust attributes based on environment/form change
         attrs.magic += 1; // Example stat change

        attrs.form = newForm;
        emit GnomeMorphed(tokenId, oldForm, newForm);
        emit GnomeAttributesUpdated(tokenId, attrs);
    }

    /// @notice Combines two Gnomes. Potentially burns one and enhances the other or creates a new one.
    /// @dev This is a complex interaction that could have many different outcomes.
    /// @param tokenId1 The ID of the first Gnome.
    /// @param tokenId2 The ID of the second Gnome.
    function combineGnomes(uint256 tokenId1, uint256 tokenId2) public whenNotPaused {
        require(_exists(tokenId1), "Gnome 1 does not exist");
        require(_exists(tokenId2), "Gnome 2 does not exist");
        require(tokenId1 != tokenId2, "Cannot combine a gnome with itself");
        require(_isTokenOwnerOrApproved(tokenId1), "Caller not authorized for Gnome 1");
        require(_isTokenOwnerOrApproved(tokenId2), "Caller not authorized for Gnome 2"); // Requires approval/ownership for both

        require(_gnomeQuest[tokenId1] == 0 && _gnomeQuest[tokenId2] == 0, "Gnomes are on quests");
        require(!_isStaked[tokenId1] && !_isStaked[tokenId2], "Gnomes are staked");

        GnomeAttributes storage attrs1 = _gnomeAttributes[tokenId1];
        GnomeAttributes storage attrs2 = _gnomeAttributes[tokenId2];

        // *** ADVANCED CONCEPT: Combination Logic ***
        // This logic could be based on:
        // - Specific forms or attributes required
        // - Probability based on rarity/stats
        // - Burning one or both Gnomes
        // - Creating a brand new Gnome (burning both parents)
        // - Enhancing one Gnome (burning the other)
        // - Cost in resources

        // Example logic: Enhance Gnome 1, burn Gnome 2
        uint winnerId = tokenId1;
        uint loserId = tokenId2;

        // Simple stat boost based on the 'loser' gnome's stats
        attrs1.strength += attrs2.strength / 2;
        attrs1.magic += attrs2.magic / 2;
        attrs1.stamina += attrs2.stamina / 2;
        attrs1.level = attrs1.level.add(attrs2.level / 4); // Add fractional level

        // Deterministic form combination (example: based on XOR of forms)
        attrs1.form = (attrs1.form ^ attrs2.form) % 5 + 1; // Forms 1-5

        // Requires burning tokenId2
        _burn(tokenId2);
        delete _gnomeAttributes[tokenId2]; // Clean up state for burned token
        delete _stakingInfo[tokenId2];
        delete _equippedItems[tokenId2];
        delete _gnomeQuest[tokenId2];
        delete _morphDelegates[tokenId2];


        emit GnomeCombined(tokenId1, tokenId2, winnerId);
        emit GnomeAttributesUpdated(tokenId1, attrs1);
    }


    // --- Interactions & Utility ---

    /// @notice Locks a Gnome in the contract for staking.
    /// @param tokenId The ID of the Gnome to stake.
    function stakeGnome(uint256 tokenId) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        require(!_isStaked[tokenId], "Gnome is already staked");
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");

        address owner = ownerOf(tokenId);
        // Transfer the token to the contract
        safeTransferFrom(owner, address(this), tokenId);

        _isStaked[tokenId] = true;
        _stakingInfo[tokenId] = StakingInfo({
            startTime: block.timestamp,
            originalStaker: msg.sender // Store who initiated staking
            // Initialize reward tracking
        });

        emit GnomeStaked(tokenId, msg.sender);
    }

    /// @notice Unlocks a staked Gnome.
    /// @param tokenId The ID of the staked Gnome.
    function unstakeGnome(uint256 tokenId) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(ownerOf(tokenId) == address(this), "Gnome is not staked in this contract");
        require(_isStaked[tokenId], "Gnome is not marked as staked");
        // Only the original staker or the current owner (if different and allowed) can unstake
        require(msg.sender == _stakingInfo[tokenId].originalStaker, "Only original staker can unstake"); // Simple check

        // Calculate and potentially distribute rewards here
        // uint256 rewards = calculateRewards(tokenId);
        // if (rewards > 0) {
        //     IERC20(rewardToken).transfer(msg.sender, rewards);
        //     emit RewardsClaimed(msg.sender, rewards);
        // }

        // Transfer the token back to the original staker
        address staker = _stakingInfo[tokenId].originalStaker;
        _safeTransfer(address(this), staker, tokenId);

        _isStaked[tokenId] = false;
        delete _stakingInfo[tokenId]; // Clean up staking info

        emit GnomeUnstaked(tokenId, staker);
    }

    /// @notice Allows claiming accumulated rewards for an array of staked Gnomes. (Placeholder)
    /// @param tokenIds An array of staked Gnome IDs.
    function claimStakingRewards(uint256[] memory tokenIds) public {
        // *** ADVANCED CONCEPT: Reward Distribution Logic ***
        // This function would iterate through the tokenIds, verify they are staked by msg.sender,
        // calculate rewards based on staking duration and potentially Gnome attributes,
        // transfer reward tokens, and reset reward counters.
        // For this example, it's a placeholder.
        revert("Reward claiming not implemented yet");
        // Example structure:
        // uint256 totalRewards = 0;
        // for (uint i = 0; i < tokenIds.length; i++) {
        //     uint256 tokenId = tokenIds[i];
        //     require(_exists(tokenId) && ownerOf(tokenId) == address(this) && _isStaked[tokenId], "Invalid or unstaked Gnome");
        //     require(_stakingInfo[tokenId].originalStaker == msg.sender, "Not your staked Gnome");
        //     uint256 rewards = calculateRewards(tokenId); // Internal function to calculate
        //     totalRewards += rewards;
        //     // Update staking info to reflect claimed rewards/reset timer
        // }
        // if (totalRewards > 0) {
        //     IERC20(rewardToken).transfer(msg.sender, totalRewards);
        //     emit RewardsClaimed(msg.sender, totalRewards);
        // }
    }

    /// @notice Deposits a required ERC20 resource token into the contract.
    /// @param amount The amount of the resource token to deposit.
    function depositResource(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(requiredResource != address(0), "Required resource token not set");
        IERC20(requiredResource).transferFrom(msg.sender, address(this), amount);
        emit ResourceDeposited(msg.sender, amount);
    }

    /// @notice Withdraws the required ERC20 resource token from the contract.
    /// @param amount The amount of the resource token to withdraw.
    function withdrawResource(uint256 amount) public onlyRole(RESOURCE_MANAGER_ROLE) {
        require(amount > 0, "Amount must be greater than 0");
        require(requiredResource != address(0), "Required resource token not set");
        IERC20(requiredResource).transfer(msg.sender, amount);
        emit ResourceWithdraw(msg.sender, amount);
    }

    /// @notice Spends an internal "skill point" counter to increase a specific attribute.
    /// @param tokenId The ID of the Gnome.
    /// @param skillType 1 for strength, 2 for magic, 3 for stamina.
    function assignSkillPoint(uint256 tokenId, uint skillType) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        require(_gnomeAttributes[tokenId].skillPointsAvailable > 0, "No skill points available");
        require(skillType >= 1 && skillType <= 3, "Invalid skill type");
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");


        GnomeAttributes storage attrs = _gnomeAttributes[tokenId];
        attrs.skillPointsAvailable--;

        if (skillType == 1) {
            attrs.strength++;
        } else if (skillType == 2) {
            attrs.magic++;
        } else if (skillType == 3) {
            attrs.stamina++;
        }

        emit SkillPointAssigned(tokenId, skillType);
        emit GnomeAttributesUpdated(tokenId, attrs);
    }

    /// @notice Associates an external item (defined by contract address and ID) with a Gnome in a specific slot.
    /// @dev Does NOT handle item ownership or transfer - only records the association.
    /// @param tokenId The ID of the Gnome.
    /// @param itemContract The address of the ERC721 or ERC1155 item contract.
    /// @param itemId The ID of the item token.
    /// @param itemSlot The slot index (0-4) to equip the item.
    function equipItem(uint256 tokenId, address itemContract, uint256 itemId, uint itemSlot) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        require(itemSlot < 5, "Invalid item slot");
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");

        // *** ADVANCED CONCEPT: Item Ownership Check / Interaction ***
        // In a real system, you'd verify msg.sender owns itemContract/itemId.
        // e.g., `IERC721(itemContract).ownerOf(itemId) == msg.sender`
        // Or if ERC1155: `IERC1155(itemContract).balanceOf(msg.sender, itemId) > 0`
        // For this example, we just store the association.

        _equippedItems[tokenId][itemSlot] = EquippedItem({
            itemContract: itemContract,
            itemId: itemId
        });

        emit ItemEquipped(tokenId, itemSlot, itemContract, itemId);
    }

    /// @notice Removes an item association from a Gnome.
    /// @param tokenId The ID of the Gnome.
    /// @param itemSlot The slot index (0-4) to unequip the item.
    function unequipItem(uint256 tokenId, uint itemSlot) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        require(itemSlot < 5, "Invalid item slot");
         require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");


        delete _equippedItems[tokenId][itemSlot];

        emit ItemUnequipped(tokenId, itemSlot);
    }

     /// @notice Sends a Gnome on a quest, changing its state.
     /// @dev While on a quest, the Gnome cannot be staked, morphed, combined, etc.
     /// @param tokenId The ID of the Gnome.
     /// @param questId An identifier for the quest.
    function sendGnomeOnQuest(uint256 tokenId, uint questId) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        require(_gnomeQuest[tokenId] == 0, "Gnome is already on a quest");
        require(!_isStaked[tokenId], "Gnome is staked");

        _gnomeQuest[tokenId] = questId;
        emit GnomeSentOnQuest(tokenId, questId);

        // In a real system, quest duration, difficulty, etc., would be stored/managed
    }

    /// @notice Resolves a quest for a Gnome based on results verified by an oracle/proof.
    /// @param tokenId The ID of the Gnome.
    /// @param resultsProof Data/proof from the oracle about the quest outcome.
    function completeQuest(uint256 tokenId, bytes memory resultsProof) public {
        require(_exists(tokenId), "Gnome does not exist");
        // This function is called by the oracle or someone with the oracle role
        // The internal _processQuestResults checks the role
        _processQuestResults(tokenId, resultsProof);
    }

    /// @notice Simulates a simple duel between two Gnomes on-chain.
    /// @dev Outcome based on stats and a provided random seed. Affects Gnome state.
    /// @param tokenId1 The ID of the first Gnome.
    /// @param tokenId2 The ID of the second Gnome.
    /// @param randomSeed A seed for outcome determination (e.g., from VRF).
    function resolveGnomeDuel(uint256 tokenId1, uint256 tokenId2, bytes32 randomSeed) public whenNotPaused {
        require(_exists(tokenId1), "Gnome 1 does not exist");
        require(_exists(tokenId2), "Gnome 2 does not exist");
        require(tokenId1 != tokenId2, "Cannot duel itself");
        require(_isTokenOwnerOrApproved(tokenId1), "Caller not authorized for Gnome 1");
        require(_isTokenOwnerOrApproved(tokenId2), "Caller not authorized for Gnome 2"); // Requires approval/ownership for both

         require(_gnomeQuest[tokenId1] == 0 && _gnomeQuest[tokenId2] == 0, "Gnomes are on quests");
         require(!_isStaked[tokenId1] && !_isStaked[tokenId2], "Gnomes are staked");


        GnomeAttributes storage attrs1 = _gnomeAttributes[tokenId1];
        GnomeAttributes storage attrs2 = _gnomeAttributes[tokenId2];

        // *** ADVANCED CONCEPT: On-Chain Combat Simulation ***
        // This logic can be simple or complex.
        // Example: Simple comparison + randomness
        uint totalStat1 = attrs1.strength + attrs1.magic + attrs1.stamina + attrs1.level;
        uint totalStat2 = attrs2.strength + attrs2.magic + attrs2.stamina + attrs2.level;

        // Introduce randomness using the seed
        uint randomFactor = uint(keccak256(abi.encodePacked(randomSeed, block.timestamp))) % 10; // 0-9

        uint score1 = totalStat1 * 10 + randomFactor;
        uint score2 = totalStat2 * 10 + (10 - randomFactor); // Complementary factor

        uint winnerId;
        uint loserId;

        if (score1 > score2) {
            winnerId = tokenId1;
            loserId = tokenId2;
        } else if (score2 > score1) {
            winnerId = tokenId2;
            loserId = tokenId1;
        } else {
             // Draw - no state change or minor change
             emit GnomeDuelResolved(tokenId1, tokenId2, 0); // 0 could indicate draw
             return; // Exit if draw
        }

        // Apply consequences to the loser (example: reduced stamina, level decrease)
        GnomeAttributes storage loserAttrs = _gnomeAttributes[loserId];
        if (loserAttrs.stamina > 0) loserAttrs.stamina--;
        if (loserAttrs.level > 1) loserAttrs.level--;
        loserAttrs.skillPointsAvailable = 0; // Loser loses pending points

        // Apply consequences to the winner (example: small stat gain, level up)
        GnomeAttributes storage winnerAttrs = _gnomeAttributes[winnerId];
        winnerAttrs.strength += 1;
        winnerAttrs.magic += 1;
        winnerAttrs.level += 1;
         winnerAttrs.skillPointsAvailable += 1; // Winner gets a point

        emit GnomeDuelResolved(tokenId1, tokenId2, winnerId);
        emit GnomeAttributesUpdated(loserId, loserAttrs);
        emit GnomeAttributesUpdated(winnerId, winnerAttrs);
    }

     /// @notice Burns a Gnome NFT in exchange for an amount of the reward token ("Essence").
     /// @dev The amount of essence could be based on the Gnome's attributes.
     /// @param tokenId The ID of the Gnome to burn.
    function burnForEssence(uint256 tokenId) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");
        require(!_isStaked[tokenId], "Gnome is staked");

        address owner = ownerOf(tokenId);
        GnomeAttributes memory attrs = _gnomeAttributes[tokenId];

        // *** ADVANCED CONCEPT: Essence Calculation ***
        // Calculate essence amount based on attributes
        uint256 essenceAmount = (attrs.level * 10) + attrs.strength + attrs.magic + attrs.stamina + (attrs.form * 5);
        essenceAmount = essenceAmount * 1000; // Scale up

        // Burn the token
        _burn(tokenId);

        // Transfer essence (reward token)
        if (essenceAmount > 0 && rewardToken != address(0)) {
            IERC20(rewardToken).transfer(owner, essenceAmount);
            emit GnomeBurnedForEssence(tokenId, owner, essenceAmount);
        } else {
             emit GnomeBurnedForEssence(tokenId, owner, 0); // Log burn even if no essence token exists/transferred
        }


        // Clean up state
        delete _gnomeAttributes[tokenId];
        delete _stakingInfo[tokenId];
        delete _equippedItems[tokenId];
        delete _gnomeQuest[tokenId];
        delete _morphDelegates[tokenId];

    }

    // --- Advanced Features ---

    /// @notice Delegates the specific right to trigger morphing for a single Gnome to another address.
    /// @dev This is distinct from ERC721 approval/operator.
    /// @param delegatee The address to delegate morphing power to.
    /// @param tokenId The ID of the Gnome.
    function delegateMorphPower(address delegatee, uint256 tokenId) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        require(delegatee != address(0), "Delegatee cannot be zero address");
        _morphDelegates[tokenId] = delegatee;
        emit MorphPowerDelegated(tokenId, delegatee);
    }

     /// @notice Renounces the delegated morphing power for a single Gnome.
     /// @param tokenId The ID of the Gnome.
    function renounceMorphPower(uint256 tokenId) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(ownerOf(tokenId) == msg.sender || _morphDelegates[tokenId] == msg.sender, "Caller is not owner or current delegate");
        delete _morphDelegates[tokenId];
         emit MorphPowerRenounced(tokenId);
    }


    /// @notice Pure function that predicts what a Gnome's stats might look like if it morphed to a specific form.
    /// @dev Does not change state. Provides a preview.
    /// @param tokenId The ID of the Gnome. (Attributes read from storage)
    /// @param potentialForm The target form ID.
    /// @return GnomeAttributes struct showing potential attributes.
    function predictMorphOutcome(uint256 tokenId, uint potentialForm) public view pure returns (GnomeAttributes memory) {
         // *** ADVANCED CONCEPT: On-Chain Simulation/Prediction ***
         // This requires the logic to be deterministic and encapsulated in a pure/view function.
         // Accessing state variables directly is not allowed in pure functions.
         // We'd need to pass the current attributes as arguments if we want it truly pure.
         // For demonstration, let's fake it or make it view and read state (less pure).

         // As a `view` function, we can read state:
         // GnomeAttributes memory currentAttrs = _gnomeAttributes[tokenId]; // This would work in view, but not pure

         // To make it pure, the caller would need to provide the current state:
         // function predictMorphOutcome(GnomeAttributes memory currentAttrs, uint potentialForm) public pure ...

         // Let's keep it simple and slightly break purity for the `tokenId` parameter, assuming the caller knows the state.
         // In reality, a pure prediction wouldn't take a tokenId directly unless the state is passed.
         // This implementation will just apply a simple rule to a *simulated* attribute set.

         GnomeAttributes memory simulatedAttrs;
         // Simulate some base attributes for prediction purposes if not using view/state
         simulatedAttrs.level = 5; simulatedAttrs.strength = 10; simulatedAttrs.magic = 10; simulatedAttrs.stamina = 10;
         simulatedAttrs.form = 1; simulatedAttrs.dna = ""; simulatedAttrs.mood = "Curious"; simulatedAttrs.skillPointsAvailable = 0;


         // Apply prediction logic based *only* on the potential form and simulated base attributes
         if (potentialForm > simulatedAttrs.form) {
             simulatedAttrs.strength += (potentialForm - simulatedAttrs.form) * 2;
             simulatedAttrs.magic += (potentialForm - simulatedAttrs.form);
         } else {
             simulatedAttrs.stamina += (simulatedAttrs.form - potentialForm);
         }
         simulatedAttrs.form = potentialForm; // Set the predicted form

         return simulatedAttrs; // Returns the projected attributes
    }

     /// @notice Generates and updates the on-chain `dna` string attribute for a Gnome based on its attributes and a seed.
     /// @dev This DNA string can be used off-chain by renderers (e.g., frontends, APIs) to create visual art.
     /// @param tokenId The ID of the Gnome.
     /// @param seed A seed value (e.g., block hash, timestamp, user input) for randomness in DNA generation.
    function generateProceduralArtDNA(uint256 tokenId, bytes32 seed) public {
        require(_exists(tokenId), "Gnome does not exist");
        require(_isTokenOwnerOrApproved(tokenId), "Caller is not owner nor approved");
        require(_gnomeQuest[tokenId] == 0, "Gnome is on a quest");


        GnomeAttributes storage attrs = _gnomeAttributes[tokenId];

        // *** ADVANCED CONCEPT: On-Chain Procedural Data Generation ***
        // This logic is deterministic based on attributes and seed.
        // The resulting string is the "DNA" for generating art off-chain.

        string memory dnaString = "";

        // Example DNA generation logic (simplified)
        // Form influences base structure
        dnaString = string(abi.encodePacked(dnaString, "F", Strings.toString(attrs.form)));
        // Stats influence features
        dnaString = string(abi.encodePacked(dnaString, "S", Strings.toString(attrs.strength)));
        dnaString = string(abi.encodePacked(dnaString, "M", Strings.toString(attrs.magic)));
        dnaString = string(abi.encodePacked(dnaString, "T", Strings.toString(attrs.stamina)));
        dnaString = string(abi.encodePacked(dnaString, "L", Strings.toString(attrs.level)));

        // Seed adds variation
        uint seedComponent = uint(keccak256(abi.encodePacked(seed, tokenId))) % 1000;
        dnaString = string(abi.encodePacked(dnaString, "X", Strings.toString(seedComponent)));

        // Mood could also influence DNA temporarily
        // dnaString = string(abi.encodePacked(dnaString, "D", attrs.mood)); // Example


        attrs.dna = dnaString; // Update the DNA string

        // Could emit a specific event for DNA updated
    }


    // --- Meta-Transactions (ERC2771 Basic Concept) ---

    /// @notice Allows a relayer to execute a function call on behalf of a user using their signature.
    /// @dev Implements a basic meta-transaction execution flow. Requires nonce management off-chain.
    /// @param user The address of the user whose signature is provided.
    /// @param functionCall The encoded function call data.
    /// @param signature The signature of the user for the call data.
    function executeMetaTx(address user, bytes calldata functionCall, bytes memory signature) public payable {
        // *** ADVANCED CONCEPT: Meta-Transaction Execution ***
        // This enables gasless transactions for the 'user', paid by the relayer (msg.sender).
        // Requires careful nonce management off-chain to prevent replay attacks.
        // A full ERC2771 implementation would inherit from a base contract.

        // Reconstruct the message hash signed by the user.
        // This often includes the contract address, chain ID, nonce, and the function call data.
        // For simplicity here, we'll assume the signature is directly over the call data + user address.
        // A real implementation needs a robust domain separator and nonce.
        bytes32 messageHash = keccak256(abi.encodePacked(address(this), user, functionCall)); // Simplified hash

        // Verify the signature
        address signer = messageHash.recover(signature);
        require(signer == user, "Meta-tx signature invalid");

        // *** SECURITY NOTE: Replay Protection Needed ***
        // Without nonces (per user or globally), the same signed message could be replayed.
        // Add a mapping like `mapping(address => uint256) private _nonces;`
        // The message hash should include the nonce:
        // bytes32 metaTxHash = keccak256(abi.encodePacked(
        //     bytes1(0x19), bytes1(0x01), // EIP-191 header
        //     _domainSeparator(),         // EIP-712 domain separator
        //     keccak256(abi.encode(
        //         keccak256("MetaTx(address user,bytes functionCall,uint256 nonce)"), // Type hash
        //         user,
        //         keccak256(functionCall),
        //         _nonces[user]
        //     ))
        // ));
        // Then increment `_nonces[user]` after execution.

        // Execute the function call using delegatecall from the contract's perspective
        // Ensure the called function respects the `user` as the effective caller (e.g., check `_msgSender()` override)
        (bool success, bytes memory result) = address(this).delegatecall(functionCall);
        require(success, string(abi.encodePacked("Meta-tx failed: ", result)));

        // Increment nonce here if implementing replay protection
        // _nonces[user]++;

        emit MetaTxExecuted(user, bytes4(functionCall)); // Log the executed call
    }

    // Optional: Add _msgSender() override for ERC2771 compatibility if functions check msg.sender internally
    // function _msgSender() internal view virtual override(Context, ERC721) returns (address sender) {
    //     // This is a placeholder and needs full ERC2771 implementation
    //     // It would check if the call came from a trusted relayer and recover the original sender.
    //     return super._msgSender();
    // }


    // --- Admin & Pausability ---

    /// @notice Pauses the `morphGnome` and `evolveGnome` functions.
    function pauseMorphing() public onlyRole(PAUSER_ROLE) {
        _pause(); // Pauses functions with `whenNotPaused` modifier
    }

    /// @notice Unpauses morphing functions.
    function unpauseMorphing() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

     /// @notice Sets the address of the trusted oracle contract for quests.
     /// @param oracleAddress The address of the quest oracle contract.
    function setQuestOracle(address oracleAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        questOracleAddress = oracleAddress;
    }


    // --- Internal ERC721 Overrides (for Enumerable) ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

         // Ensure staked/questing tokens cannot be transferred unless by the contract itself (for staking)
        if (from != address(this)) {
             require(!_isStaked[tokenId], "Staked Gnomes cannot be transferred");
             require(_gnomeQuest[tokenId] == 0, "Gnomes on quest cannot be transferred");
        }
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721, ERC721Enumerable) {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
        // Clean up state if token is transferred away from staking address
        if (from == address(this) && _isStaked[tokenId]) {
             _isStaked[tokenId] = false;
             delete _stakingInfo[tokenId];
        }
    }

    // Override ERC721 internal functions that might rely on _msgSender
    // Add if you implement ERC2771 _msgSender override
    // function _approve(address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    //     super._approve(to, tokenId);
    // }
    // function _setApprovalForAll(address operator, bool approved) internal virtual override(ERC721, ERC721Enumerable) {
    //      super._setApprovalForAll(operator, approved);
    // }
    // function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
    //     super._burn(tokenId);
    // }
    // function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual override(ERC721, ERC721Enumerable) {
    //     super._safeTransfer(from, to, tokenId, data);
    // }
}
```