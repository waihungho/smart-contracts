Okay, let's design a smart contract that embodies several advanced, creative, and interconnected concepts: **Programmable Soulbound Reputation Tokens**.

This contract will manage non-transferable (or conditionally transferable) tokens, where each token represents a user's identity or earned status within a specific domain. These tokens have dynamic attributes ("Traits") and behavior governed by on-chain "Rules" and community "Attestations".

Here's the breakdown:

1.  **Soulbound Nature:** Tokens are initially bound to an address (soulbound).
2.  **Programmable State:** Tokens have evolving "Traits" (attributes) that can change based on rules or actions.
3.  **Rule Engine:** Rules can be attached to tokens. These rules dictate when traits change, when the token might become temporarily transferable (unbound), or trigger other effects. Rules can be based on time, interactions with other contracts, holding other tokens, or needing specific attestations.
4.  **Attestations:** Other addresses can "attest" to properties of a token holder (e.g., skill, participation). Attestations can influence traits or rule evaluations.
5.  **Conditional Unbinding/Binding:** While primarily soulbound, rules can define conditions under which a token can be temporarily unbound (transferable) or bound again. This adds a dynamic layer to the SBT concept.
6.  **Delegation:** Token holders can delegate specific permissions related to their token (e.g., allowing a third party to add specific types of attestations, or manage certain traits).

This design combines elements of SBTs, Dynamic NFTs, Decentralized Identity/Reputation, and on-chain Rule Engines, while aiming for a novel combination.

---

## Contract Outline and Function Summary

**Contract Name:** `ChronicleReputation`

**Core Concepts:**
*   Programmable Soulbound Tokens (Chronicles).
*   Dynamic Traits / Attributes per token.
*   On-chain Rule Engine for state transitions (Traits, Binding).
*   Attestation mechanism for verifiable claims.
*   Conditional Transferability (Binding/Unbinding based on rules).
*   Delegated Permissions per token.

**Data Structures:**
*   `Chronicle`: Represents a single reputation token. Includes owner, traits, rules, binding status.
*   `Trait`: A key-value pair representing an attribute (e.g., "SkillLevel": "Advanced").
*   `RuleInstance`: A specific rule attached to a Chronicle (links to a RuleDefinition + parameters).
*   `RuleDefinition`: Global definition of a rule type (e.g., logic for "TimeDecayRule").
*   `Attestation`: A claim made by an attestor about a Chronicle holder.
*   `Permission`: Defines a type of delegated access.

**Function Categories & Summary:**

1.  **Token Management:**
    *   `mint(address to, bytes memory initialMetadata, Trait[] memory initialTraits)`: Creates a new Chronicle.
    *   `burn(uint256 tokenId)`: Destroys a Chronicle (requires specific conditions/permissions).
    *   `ownerOf(uint256 tokenId) view returns (address)`: Gets the owner of a Chronicle.
    *   `tokenURI(uint256 tokenId) view returns (string)`: Gets the metadata URI.
    *   `getTotalSupply() view returns (uint256)`: Gets the total number of minted Chronicles.
    *   `tokensOfOwner(address owner) view returns (uint256[] memory)`: Gets all Chronicle IDs owned by an address.

2.  **Trait Management:**
    *   `setTrait(uint256 tokenId, bytes32 traitKey, bytes memory traitValue)`: Sets or updates a specific trait for a token.
    *   `removeTrait(uint256 tokenId, bytes32 traitKey)`: Removes a trait.
    *   `getTrait(uint256 tokenId, bytes32 traitKey) view returns (bytes memory)`: Gets the value of a specific trait.
    *   `getAllTraits(uint256 tokenId) view returns (Trait[] memory)`: Gets all traits for a token.
    *   `hasTrait(uint256 tokenId, bytes32 traitKey) view returns (bool)`: Checks if a token has a specific trait.

3.  **Rule Engine & Execution:**
    *   `defineRuleLogic(bytes32 ruleType, address logicContract)`: (Owner) Defines or updates the contract address handling specific rule logic.
    *   `addRuleToChronicle(uint256 tokenId, bytes32 ruleType, bytes memory ruleParams)`: Attaches an instance of a defined rule type to a specific Chronicle with parameters.
    *   `removeRuleFromChronicle(uint256 tokenId, uint256 ruleIndex)`: Removes a rule instance from a Chronicle.
    *   `getRulesForChronicle(uint256 tokenId) view returns (RuleInstance[] memory)`: Gets all rule instances attached to a Chronicle.
    *   `applyChronicleRules(uint256 tokenId)`: Executes all attached rules for a Chronicle, potentially updating traits, binding status, etc. (Can be called by anyone to trigger state update, gas cost paid by caller).

4.  **Attestation:**
    *   `attest(uint256 tokenId, bytes32 attestationType, bytes memory attestationData)`: Adds an attestation to a Chronicle.
    *   `getAttestations(uint256 tokenId) view returns (Attestation[] memory)`: Gets all attestations for a Chronicle.
    *   `getAttestationsByType(uint256 tokenId, bytes32 attestationType) view returns (Attestation[] memory)`: Gets attestations of a specific type.
    *   `getAttestationsByAttestor(uint256 tokenId, address attestor) view returns (Attestation[] memory)`: Gets attestations made by a specific address.

5.  **Binding & Transferability:**
    *   `isBound(uint256 tokenId) view returns (bool)`: Checks if a Chronicle is currently soulbound (non-transferable).
    *   `checkTransferAllowed(uint256 tokenId) view returns (bool)`: Checks if `transferFrom` would succeed *right now* based on rules.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfers Chronicle ownership (only if `checkTransferAllowed` is true).
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer version (only if `checkTransferAllowed` is true).

6.  **Delegation:**
    *   `delegatePermission(uint256 tokenId, address delegatee, bytes32 permissionType, bool granted)`: Grants or revokes a specific permission type to an address for a specific Chronicle.
    *   `hasPermission(uint256 tokenId, address account, bytes32 permissionType) view returns (bool)`: Checks if an address has a specific delegated permission for a Chronicle.

7.  **Configuration (Owner/Admin):**
    *   `setBaseURI(string memory baseURI)`: Sets the base URI for token metadata.
    *   `setDefaultBindingStatus(bool status)`: Sets the default binding status for new Chronicles.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Note: This is a complex, advanced concept.
// - Rule logic is abstracted: `defineRuleLogic` points to external contracts or internal handlers.
// - The `applyChronicleRules` function is designed to be triggered externally
//   (e.g., by a relayer, or users themselves) to update state based on rules,
//   shifting computation cost.
// - Gas costs for functions iterating over traits, rules, or attestations
//   can be significant with many items.

/// @title ChronicleReputation
/// @notice A smart contract for managing Programmable Soulbound Reputation Tokens (Chronicles).
/// These tokens represent identity or status, have dynamic traits,
/// and their behavior (like transferability and trait evolution) is governed by on-chain rules and attestations.
contract ChronicleReputation is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---

    struct Trait {
        bytes32 key;
        bytes value; // Can store various data types (strings, numbers, addresses)
    }

    struct RuleInstance {
        bytes32 ruleType; // References a global rule definition
        bytes params; // Parameters specific to this rule instance
        bool enabled; // Can be toggled
    }

    struct Attestation {
        address attestor;
        bytes32 attestationType;
        bytes data; // Data specific to the attestation
        uint48 timestamp;
    }

    // --- State Variables ---

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;
    // Mapping from owner address to list of owned tokens
    mapping(address => uint256[]) private _ownedTokens;
    // Mapping from token ID to index in the owner's ownedTokens array
    mapping(uint256 => uint256) private _ownedTokensIndex;
    // Array of all token IDs
    uint256[] private _allTokens;
    // Mapping from token ID to index in the _allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Token Data
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => mapping(bytes32 => bytes)) private _tokenTraits; // tokenId => traitKey => traitValue

    // Rule Engine Data
    // Mapping from rule type (bytes32 identifier) to the contract address or internal handler logic
    mapping(bytes32 => address) private _ruleLogicContracts;
    // Mapping from token ID to list of attached rule instances
    mapping(uint256 => RuleInstance[]) private _chronicleRules;
    // Mapping from token ID to its current binding status (true = soulbound, false = potentially transferable)
    mapping(uint256 => bool) private _isBound;

    // Attestation Data
    // Mapping from token ID to list of attestations
    mapping(uint256 => Attestation[]) private _tokenAttestations;

    // Delegation Data (permissionType => delegatee => granted)
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) private _tokenPermissions;

    // Default settings
    string private _baseTokenURI;
    bool private _defaultBindingStatus = true; // Default to soulbound

    // --- Events ---

    event ChronicleMinted(uint256 indexed tokenId, address indexed owner, bytes initialMetadata);
    event ChronicleBurned(uint256 indexed tokenId, address indexed owner);
    event TraitSet(uint256 indexed tokenId, bytes32 traitKey, bytes traitValue);
    event TraitRemoved(uint256 indexed tokenId, bytes32 traitKey);
    event AttestationAdded(uint256 indexed tokenId, address indexed attestor, bytes32 attestationType);
    event RuleDefined(bytes32 indexed ruleType, address indexed logicContract);
    event RuleAddedToChronicle(uint256 indexed tokenId, bytes32 ruleType, bytes params);
    event RuleRemovedFromChronicle(uint256 indexed tokenId, uint256 ruleIndex);
    event ChronicleRulesApplied(uint256 indexed tokenId);
    event ChronicleBound(uint256 indexed tokenId);
    event ChronicleUnbound(uint256 indexed tokenId);
    event PermissionDelegated(uint256 indexed tokenId, address indexed delegatee, bytes32 permissionType, bool granted);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // ERC721-like transfer event

    // --- Constructor ---

    constructor(string memory name, string memory symbol, string memory baseURI) Ownable(msg.sender) {
        // Name and Symbol are not strictly needed for non-standard ERC721, but can be included for context
        // string public constant name = name; // Example: "ChronicleReputation"
        // string public constant symbol = symbol; // Example: "CHR"
        _baseTokenURI = baseURI;
    }

    // --- Internal Helpers for Enumeration (Adapted from OpenZeppelin) ---

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // If the token is not the last in the array, move the last token to the token's position
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _allTokens[lastTokenIndex];
            _allTokens[tokenIndex] = lastTokenId;
            _allTokensIndex[lastTokenId] = tokenIndex;
        }

        // Remove the last token from the array
        _allTokens.pop();
        delete _allTokensIndex[tokenId];
    }

     function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
         uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // If the token is not the last in the array, move the last token to the token's position
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        // Remove the last token from the array
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId];
    }

    // --- Token Management (1/6) ---

    /// @notice Mints a new Chronicle token.
    /// @param to The address to mint the token to.
    /// @param initialMetadata The initial metadata string or reference.
    /// @param initialTraits Initial traits for the new token.
    /// @return The ID of the newly minted token.
    function mint(address to, bytes memory initialMetadata, Trait[] memory initialTraits) public onlyOwner returns (uint256) {
        require(to != address(0), "Mint to zero address");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _owners[newTokenId] = to;
        _isBound[newTokenId] = _defaultBindingStatus; // Set initial binding status

        // Set initial traits
        for (uint i = 0; i < initialTraits.length; i++) {
            _tokenTraits[newTokenId][initialTraits[i].key] = initialTraits[i].value;
        }

        _tokenURIs[newTokenId] = string(initialMetadata); // Store initial metadata reference

        // Add to enumerations
        _addTokenToAllTokensEnumeration(newTokenId);
        _addTokenToOwnerEnumeration(to, newTokenId);

        emit ChronicleMinted(newTokenId, to, initialMetadata);
        // Note: ERC721 Transfer event is usually emitted here with from=address(0)
        emit Transfer(address(0), to, newTokenId);

        return newTokenId;
    }

    /// @notice Burns a Chronicle token. Requires owner or delegated permission.
    /// @param tokenId The ID of the token to burn.
    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("BurnPermission")), "Not authorized to burn");
        require(owner != address(0), "Token does not exist");

        // Remove from enumerations first
        _removeTokenFromOwnerEnumeration(owner, tokenId);
        _removeTokenFromAllTokensEnumeration(tokenId);

        // Clear data
        delete _owners[tokenId];
        delete _tokenURIs[tokenId];
        delete _tokenTraits[tokenId]; // Clears the nested mapping
        delete _chronicleRules[tokenId];
        delete _tokenAttestations[tokenId];
        delete _tokenPermissions[tokenId];
        delete _isBound[tokenId];


        emit ChronicleBurned(tokenId, owner);
         // Note: ERC721 Transfer event is usually emitted here with to=address(0)
        emit Transfer(owner, address(0), tokenId);

    }

    /// @notice Gets the owner of a Chronicle.
    /// @param tokenId The ID of the token.
    /// @return The owner address.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    /// @notice Gets the metadata URI for a Chronicle.
    /// @param tokenId The ID of the token.
    /// @return The metadata URI.
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory base = _baseTokenURI;
        string memory tokenSpecific = _tokenURIs[tokenId];
        if (bytes(base).length == 0) {
            return tokenSpecific;
        }
        if (bytes(tokenSpecific).length == 0) {
             return base;
        }
        // Basic concatenation (consider using string utils for robustness if needed)
        return string(abi.encodePacked(base, tokenSpecific));
    }

    /// @notice Gets the total number of Chronicles minted.
    /// @return The total supply.
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

     /// @notice Gets a token ID by its index in the global list.
    /// @param index The index (0-based).
    /// @return The token ID.
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < _allTokens.length, "Index out of bounds");
        return _allTokens[index];
    }

    /// @notice Gets all Chronicle IDs owned by a specific address.
    /// @param owner The address to query.
    /// @return An array of token IDs.
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

     /// @notice Updates the token-specific part of the metadata URI. Requires owner or delegated permission.
    /// @param tokenId The ID of the token.
    /// @param newURI The new token-specific URI part.
    function updateTokenURI(uint256 tokenId, string memory newURI) public {
         address owner = ownerOf(tokenId); // Checks if token exists
         require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("UpdateURIPermission")), "Not authorized to update URI");
         _tokenURIs[tokenId] = newURI;
    }


    // --- Trait Management (2/6) ---

    /// @notice Sets or updates a specific trait for a Chronicle. Requires owner or delegated permission.
    /// @param tokenId The ID of the token.
    /// @param traitKey The key (name) of the trait.
    /// @param traitValue The value of the trait (encoded bytes).
    function setTrait(uint256 tokenId, bytes32 traitKey, bytes memory traitValue) public {
        address owner = ownerOf(tokenId); // Checks if token exists
        require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("ManageTraitsPermission")) || hasPermission(tokenId, msg.sender, traitKey), "Not authorized to set trait");

        _tokenTraits[tokenId][traitKey] = traitValue;
        emit TraitSet(tokenId, traitKey, traitValue);
    }

    /// @notice Removes a specific trait from a Chronicle. Requires owner or delegated permission.
    /// @param tokenId The ID of the token.
    /// @param traitKey The key (name) of the trait to remove.
    function removeTrait(uint256 tokenId, bytes32 traitKey) public {
        address owner = ownerOf(tokenId); // Checks if token exists
         require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("ManageTraitsPermission")) || hasPermission(tokenId, msg.sender, traitKey), "Not authorized to remove trait");

        delete _tokenTraits[tokenId][traitKey];
        emit TraitRemoved(tokenId, traitKey);
    }

    /// @notice Gets the value of a specific trait for a Chronicle.
    /// @param tokenId The ID of the token.
    /// @param traitKey The key (name) of the trait.
    /// @return The value of the trait (encoded bytes). Returns empty bytes if trait not found.
    function getTrait(uint256 tokenId, bytes32 traitKey) public view returns (bytes memory) {
         ownerOf(tokenId); // Checks if token exists
        return _tokenTraits[tokenId][traitKey];
    }

    /// @notice Gets all traits for a Chronicle. Note: can be gas-intensive if many traits.
    /// @param tokenId The ID of the token.
    /// @return An array of Trait structs.
    function getAllTraits(uint256 tokenId) public view returns (Trait[] memory) {
        ownerOf(tokenId); // Checks if token exists
        // Solidity <0.8 does not easily iterate mapping keys.
        // This implementation assumes traits are managed *via* setTrait/removeTrait
        // and might need external indexing for iteration if many traits are expected.
        // For simplicity in this example, we'll return a limited or best-effort list
        // or expect keys to be known. A more robust design might store keys in an array too.
        // Let's return a placeholder or require external indexing for this advanced function.
        // Placeholder: return an empty array or require specific trait keys.
        // To fulfill the requirement, we *must* be able to return them.
        // This requires storing keys. Let's add a mapping for keys.

        mapping(uint256 => bytes32[]) private _tokenTraitKeys; // tokenId => list of keys

        // Modify setTrait and removeTrait:
        // In setTrait: if (!_tokenTraits[tokenId][traitKey].length > 0), add traitKey to _tokenTraitKeys[tokenId]
        // In removeTrait: remove traitKey from _tokenTraitKeys[tokenId]

        // Re-implementing getAllTraits assuming _tokenTraitKeys exists:
        bytes32[] storage keys = _tokenTraitKeys[tokenId];
        Trait[] memory traits = new Trait[](keys.length);
        for (uint i = 0; i < keys.length; i++) {
            traits[i] = Trait(keys[i], _tokenTraits[tokenId][keys[i]]);
        }
        return traits;
    }

    // Helper for getAllTraits (need to add _tokenTraitKeys management)
    mapping(uint256 => bytes32[]) private _tokenTraitKeys;
    mapping(uint256 => mapping(bytes32 => uint256)) private _tokenTraitKeyIndex;

    // Modified setTrait (incorporate key tracking)
    function setTrait(uint256 tokenId, bytes32 traitKey, bytes memory traitValue) public {
        address owner = ownerOf(tokenId);
        require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("ManageTraitsPermission")) || hasPermission(tokenId, msg.sender, traitKey), "Not authorized to set trait");

        bytes memory currentValue = _tokenTraits[tokenId][traitKey];
        bool traitExists = currentValue.length > 0; // Check if value exists

        _tokenTraits[tokenId][traitKey] = traitValue;

        if (!traitExists) {
            // Add key to the list
            _tokenTraitKeyIndex[tokenId][traitKey] = _tokenTraitKeys[tokenId].length;
            _tokenTraitKeys[tokenId].push(traitKey);
        }

        emit TraitSet(tokenId, traitKey, traitValue);
    }

     // Modified removeTrait (incorporate key tracking)
    function removeTrait(uint256 tokenId, bytes32 traitKey) public {
        address owner = ownerOf(tokenId);
         require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("ManageTraitsPermission")) || hasPermission(tokenId, msg.sender, traitKey), "Not authorized to remove trait");

        bytes memory currentValue = _tokenTraits[tokenId][traitKey];
        require(currentValue.length > 0, "Trait does not exist");

        delete _tokenTraits[tokenId][traitKey];

        // Remove key from the list
        uint256 lastKeyIndex = _tokenTraitKeys[tokenId].length - 1;
        uint256 keyIndex = _tokenTraitKeyIndex[tokenId][traitKey];

        if (keyIndex != lastKeyIndex) {
            bytes32 lastKey = _tokenTraitKeys[tokenId][lastKeyIndex];
            _tokenTraitKeys[tokenId][keyIndex] = lastKey;
            _tokenTraitKeyIndex[tokenId][lastKey] = keyIndex;
        }

        _tokenTraitKeys[tokenId].pop();
        delete _tokenTraitKeyIndex[tokenId][traitKey];

        emit TraitRemoved(tokenId, traitKey);
    }

    // Re-implementing getAllTraits with key tracking
    function getAllTraits(uint256 tokenId) public view returns (Trait[] memory) {
        ownerOf(tokenId); // Checks if token exists
        bytes32[] storage keys = _tokenTraitKeys[tokenId];
        Trait[] memory traits = new Trait[](keys.length);
        for (uint i = 0; i < keys.length; i++) {
            traits[i] = Trait(keys[i], _tokenTraits[tokenId][keys[i]]);
        }
        return traits;
    }


    /// @notice Checks if a Chronicle has a specific trait.
    /// @param tokenId The ID of the token.
    /// @param traitKey The key (name) of the trait.
    /// @return True if the trait exists and has a non-empty value, false otherwise.
    function hasTrait(uint256 tokenId, bytes32 traitKey) public view returns (bool) {
        ownerOf(tokenId); // Checks if token exists
        // Check if the value exists and is not empty bytes
        return _tokenTraits[tokenId][traitKey].length > 0;
    }


    // --- Rule Engine & Execution (3/6) ---

    /// @notice Defines or updates the contract responsible for handling a specific rule type's logic.
    /// Only the owner can call this.
    /// @param ruleType A unique identifier for the rule type.
    /// @param logicContract The address of the contract implementing the rule logic (or address(0) for internal logic).
    function defineRuleLogic(bytes32 ruleType, address logicContract) public onlyOwner {
        _ruleLogicContracts[ruleType] = logicContract;
        emit RuleDefined(ruleType, logicContract);
    }

    /// @notice Attaches an instance of a defined rule type to a specific Chronicle. Requires owner or delegated permission.
    /// @param tokenId The ID of the token.
    /// @param ruleType The type of the rule (must be defined).
    /// @param ruleParams Parameters specific to this rule instance (encoded bytes).
    function addRuleToChronicle(uint256 tokenId, bytes32 ruleType, bytes memory ruleParams) public {
         address owner = ownerOf(tokenId); // Checks if token exists
         require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("ManageRulesPermission")), "Not authorized to add rule");
         require(_ruleLogicContracts[ruleType] != address(0) || ruleType == bytes32(0), "Rule type not defined"); // Allow ruleType 0 for internal logic placeholder

        _chronicleRules[tokenId].push(RuleInstance(ruleType, ruleParams, true));
        emit RuleAddedToChronicle(tokenId, ruleType, ruleParams);
    }

    /// @notice Removes a rule instance from a Chronicle by its index. Requires owner or delegated permission.
    /// @param tokenId The ID of the token.
    /// @param ruleIndex The index of the rule instance in the Chronicle's rule list.
    function removeRuleFromChronicle(uint256 tokenId, uint256 ruleIndex) public {
        address owner = ownerOf(tokenId); // Checks if token exists
        require(owner == msg.sender || hasPermission(tokenId, msg.sender, bytes32("ManageRulesPermission")), "Not authorized to remove rule");
        require(ruleIndex < _chronicleRules[tokenId].length, "Rule index out of bounds");

        // Simple removal by swapping with the last element and popping
        uint lastIndex = _chronicleRules[tokenId].length - 1;
        if (ruleIndex != lastIndex) {
            _chronicleRules[tokenId][ruleIndex] = _chronicleRules[tokenId][lastIndex];
        }
        _chronicleRules[tokenId].pop();

        emit RuleRemovedFromChronicle(tokenId, ruleIndex);
    }

     /// @notice Gets all rule instances attached to a Chronicle.
    /// @param tokenId The ID of the token.
    /// @return An array of RuleInstance structs.
    function getRulesForChronicle(uint256 tokenId) public view returns (RuleInstance[] memory) {
        ownerOf(tokenId); // Checks if token exists
        return _chronicleRules[tokenId];
    }

     /// @notice Evaluates a single rule instance for a Chronicle.
    /// This function should ideally call the relevant rule logic contract or internal handler.
    /// Placeholder implementation: always return true.
    /// A real implementation would need interfaces and calls to `_ruleLogicContracts[rule.ruleType]`.
    /// @param tokenId The ID of the token.
    /// @param ruleIndex The index of the rule instance.
    /// @return True if the rule condition is met, false otherwise.
    function evaluateRule(uint256 tokenId, uint256 ruleIndex) public view returns (bool) {
        ownerOf(tokenId); // Checks if token exists
        require(ruleIndex < _chronicleRules[tokenId].length, "Rule index out of bounds");
        RuleInstance storage rule = _chronicleRules[tokenId][ruleIndex];
        require(rule.enabled, "Rule is disabled");

        // --- Placeholder/Simplified Rule Evaluation Logic ---
        // In a real system:
        // address logicContract = _ruleLogicContracts[rule.ruleType];
        // if (logicContract != address(0)) {
        //     // Call external contract: requires defining an IRuleLogic interface
        //     IRuleLogic logic = IRuleLogic(logicContract);
        //     return logic.evaluate(tokenId, rule.params);
        // } else {
        //     // Internal logic for basic rules (e.g., time checks, trait checks)
        //     // This would involve a large if/else or switch statement based on rule.ruleType
        //     if (rule.ruleType == bytes32("ExampleTimeRule")) {
        //          uint256 timestampParam = abi.decode(rule.params, (uint256));
        //          return block.timestamp >= timestampParam;
        //     } else if (rule.ruleType == bytes32("ExampleTraitRule")) {
        //          bytes32 requiredTrait = abi.decode(rule.params, (bytes32));
        //          return hasTrait(tokenId, requiredTrait);
        //     } else {
                 // Default or unsupported rule type
                 return false; // Or revert, depending on desired strictness
        //     }
        // }
        // --- End Placeholder ---

         // Default return for this example's placeholder
         // A real rule engine should return true/false based on actual logic
         return true; // Simplification: assume rule evaluates true for demo
    }


    /// @notice Applies all enabled rules for a Chronicle.
    /// This function iterates through rules and triggers state changes (traits, binding)
    /// based on rule evaluation. This can be gas-intensive if many rules are attached.
    /// Can be called by anyone; gas cost is borne by the caller.
    /// @param tokenId The ID of the token.
    function applyChronicleRules(uint256 tokenId) public {
        ownerOf(tokenId); // Checks if token exists
        RuleInstance[] storage rules = _chronicleRules[tokenId];

        bool currentBindingStatus = _isBound[tokenId]; // Capture initial status

        // --- Placeholder/Simplified Rule Application Logic ---
        // In a real system:
        // Iterate rules, call evaluateRule, and if true, apply the effect
        // Effects could involve:
        // - Calling setTrait/removeTrait internally
        // - Setting _isBound[tokenId] = true/false
        // - Emitting other events
        // This requires associating effects with rule definitions.

        bool newBindingStatus = currentBindingStatus; // Assume no change unless rule dictates

        for (uint i = 0; i < rules.length; i++) {
            RuleInstance storage rule = rules[i];
            if (rule.enabled) {
                 // bool ruleMet = evaluateRule(tokenId, i); // Use the actual evaluateRule logic
                 // Placeholder evaluation:
                 bool ruleMet = true; // Simplified for example

                 if (ruleMet) {
                    // --- Apply Rule Effect (Placeholder) ---
                    // This is where rule effects would be triggered.
                    // Example rule effects:
                    // if (rule.ruleType == bytes32("UnbindConditionMet")) {
                    //     newBindingStatus = false; // Rule dictates unbinding
                    // } else if (rule.ruleType == bytes32("BindConditionMet")) {
                    //     newBindingStatus = true; // Rule dictates binding
                    // } else if (rule.ruleType == bytes32("GrantTraitRule")) {
                    //     bytes32 traitToGrant = abi.decode(rule.params, (bytes32));
                    //     _setTraitInternal(tokenId, traitToGrant, abi.encodePacked("true")); // Internal set (no permission check)
                    // }
                    // --- End Placeholder ---
                 }
            }
        }

        // Apply binding status change if needed
        if (newBindingStatus != currentBindingStatus) {
            _isBound[tokenId] = newBindingStatus;
            if (newBindingStatus) {
                emit ChronicleBound(tokenId);
            } else {
                emit ChronicleUnbound(tokenId);
            }
        }

        emit ChronicleRulesApplied(tokenId);
    }


    // --- Attestation (4/6) ---

    /// @notice Adds an attestation to a Chronicle. Anyone can attest.
    /// Reputation/trust of attestations should be handled externally or within rule logic.
    /// @param tokenId The ID of the token being attested about.
    /// @param attestationType The type of attestation (e.g., "SkillEndorsement", "ParticipationProof").
    /// @param attestationData Data related to the attestation (encoded bytes).
    function attest(uint256 tokenId, bytes32 attestationType, bytes memory attestationData) public {
        ownerOf(tokenId); // Checks if token exists
        // Anyone can attest, but rules/logic might filter based on attestor or type
        _tokenAttestations[tokenId].push(Attestation(msg.sender, attestationType, attestationData, uint48(block.timestamp)));
        emit AttestationAdded(tokenId, msg.sender, attestationType);
    }

    /// @notice Gets all attestations for a Chronicle. Note: can be gas-intensive if many attestations.
    /// @param tokenId The ID of the token.
    /// @return An array of Attestation structs.
    function getAttestations(uint256 tokenId) public view returns (Attestation[] memory) {
         ownerOf(tokenId); // Checks if token exists
        return _tokenAttestations[tokenId];
    }

     /// @notice Gets attestations of a specific type for a Chronicle. Note: can be gas-intensive.
    /// @param tokenId The ID of the token.
    /// @param attestationType The type to filter by.
    /// @return An array of Attestation structs of the specified type.
    function getAttestationsByType(uint256 tokenId, bytes32 attestationType) public view returns (Attestation[] memory) {
        Attestation[] storage allAttestations = _tokenAttestations[tokenId];
        uint256 count = 0;
        for (uint i = 0; i < allAttestations.length; i++) {
            if (allAttestations[i].attestationType == attestationType) {
                count++;
            }
        }

        Attestation[] memory filtered = new Attestation[](count);
        uint256 current = 0;
        for (uint i = 0; i < allAttestations.length; i++) {
            if (allAttestations[i].attestationType == attestationType) {
                filtered[current] = allAttestations[i];
                current++;
            }
        }
        return filtered;
    }

     /// @notice Gets attestations made by a specific attestor for a Chronicle. Note: can be gas-intensive.
    /// @param tokenId The ID of the token.
    /// @param attestor The address of the attestor to filter by.
    /// @return An array of Attestation structs made by the specified attestor.
    function getAttestationsByAttestor(uint256 tokenId, address attestor) public view returns (Attestation[] memory) {
        Attestation[] storage allAttestations = _tokenAttestations[tokenId];
        uint256 count = 0;
        for (uint i = 0; i < allAttestations.length; i++) {
            if (allAttestations[i].attestor == attestor) {
                count++;
            }
        }

        Attestation[] memory filtered = new Attestation[](count);
        uint256 current = 0;
        for (uint i = 0; i < allAttestations.length; i++) {
            if (allAttestations[i].attestor == attestor) {
                filtered[current] = allAttestations[i];
                current++;
            }
        }
        return filtered;
    }


    // --- Binding & Transferability (5/6) ---

    /// @notice Checks if a Chronicle is currently soulbound (non-transferable).
    /// This status is primarily controlled by the `applyChronicleRules` function based on rules.
    /// @param tokenId The ID of the token.
    /// @return True if the token is bound, false otherwise.
    function isBound(uint256 tokenId) public view returns (bool) {
        ownerOf(tokenId); // Checks if token exists
        return _isBound[tokenId];
    }

    /// @notice Checks if a Chronicle is currently allowed to be transferred.
    /// This is the core check for the soulbound property, considering current binding status and rules.
    /// @param tokenId The ID of the token.
    /// @return True if transfer is allowed, false otherwise.
    function checkTransferAllowed(uint256 tokenId) public view returns (bool) {
         ownerOf(tokenId); // Checks if token exists
        // Transfer is allowed only if the token is NOT bound AND there isn't a rule
        // currently enforcing binding even if _isBound is false (less common, but possible).
        // Or, if a specific rule explicitly overrides binding for transfer checks.
        // For this implementation, we rely solely on the _isBound state managed by rules.
        return !_isBound[tokenId];
    }

    /// @notice Transfers ownership of a Chronicle. Can only succeed if `checkTransferAllowed` returns true.
    /// This function overrides the standard ERC721 transfer logic to enforce binding.
    /// @param from The current owner.
    /// @param to The recipient.
    /// @param tokenId The ID of the token.
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf(tokenId) == from, "TransferFrom: Caller is not owner");
        require(to != address(0), "TransferFrom: Transfer to zero address");

        // --- Core Binding Check ---
        require(checkTransferAllowed(tokenId), "Chronicle is soulbound and cannot be transferred");
        // --- End Binding Check ---

        // Standard ERC721 approval checks (optional for SBT but included for compliance/flexibility)
        // This simple implementation assumes no `getApproved` or `isApprovedForAll` logic is active for binding.
        // A full ERC721 implementation would check approvals here. For an SBT, approvals are usually disabled.
        // require(_isApprovedOrOwner(msg.sender, tokenId), "TransferFrom: Transfer not approved");

        _transfer(from, to, tokenId);
    }

     /// @notice Safely transfers ownership of a Chronicle. Uses `transferFrom` and checks recipient.
    /// @param from The current owner.
    /// @param to The recipient.
    /// @param tokenId The ID of the token.
     function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        // ERC721 standard includes a check here if `to` is a contract to ensure it can receive ERC721.
        // Skipping the full check for brevity in this example, but important for compliance.
     }

    /// @notice Internal transfer logic. Handles state updates.
    function _transfer(address from, address to, uint256 tokenId) private {
        require(ownerOf(tokenId) == from, "_transfer: Invalid from address"); // Double check
        require(to != address(0), "_transfer: Transfer to zero address");

         // Update enumerations *before* changing _owners mapping
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

        _owners[tokenId] = to;

        // In a true SBT, transfer should not clear approvals.
        // If ERC721 approvals were supported, they would NOT be cleared here for a "transfer".
        // ERC721 standard typically clears approvals on transfer.
        // This highlights how SBTs deviate from standard ERC721.

        emit Transfer(from, to, tokenId);
    }

    // ERC721 Approval functions (included for functional completeness,
    // though likely non-functional or restricted for soulbound tokens)
    function approve(address to, uint256 tokenId) public {
        // ERC721 standard. For SBT, this is often disabled or requires special conditions.
        // require(_owners[tokenId] == msg.sender, "Approve: Caller is not owner");
        // require(checkTransferAllowed(tokenId), "Chronicle is soulbound and cannot be approved for transfer");
        // _tokenApprovals[tokenId] = to;
        // emit Approval(msg.sender, to, tokenId);
        revert("Approvals are restricted for soulbound tokens");
    }

     function getApproved(uint256 tokenId) public view returns (address) {
        // ERC721 standard. Likely always returns address(0) for SBT.
         ownerOf(tokenId); // Check if token exists
        // return _tokenApprovals[tokenId];
        return address(0); // Indicate no approvals for SBTs
     }

     function setApprovalForAll(address operator, bool approved) public {
        // ERC721 standard. Likely restricted for SBT.
        // _operatorApprovals[msg.sender][operator] = approved;
        // emit ApprovalForAll(msg.sender, operator, approved);
        revert("Approval for all is restricted for soulbound tokens");
     }

     function isApprovedForAll(address owner, address operator) public view returns (bool) {
        // ERC721 standard. Likely always returns false for SBT.
        // return _operatorApprovals[owner][operator];
        return false; // Indicate no operator approvals for SBTs
     }


    // --- Delegation (6/6) ---

    /// @notice Grants or revokes a specific permission type to an address for a specific Chronicle. Requires owner.
    /// Permission types are arbitrary bytes32 values (e.g., "ManageTraitsPermission", "AddAttestationTypeX").
    /// @param tokenId The ID of the token.
    /// @param delegatee The address to grant/revoke permission for.
    /// @param permissionType The type of permission.
    /// @param granted True to grant, false to revoke.
    function delegatePermission(uint256 tokenId, address delegatee, bytes32 permissionType, bool granted) public {
        address owner = ownerOf(tokenId); // Checks if token exists
        require(owner == msg.sender, "DelegatePermission: Caller is not owner");
        require(delegatee != address(0), "DelegatePermission: Delegatee cannot be zero address");

        _tokenPermissions[tokenId][permissionType][delegatee] = granted;
        emit PermissionDelegated(tokenId, delegatee, permissionType, granted);
    }

    /// @notice Checks if an address has a specific delegated permission for a Chronicle.
    /// @param tokenId The ID of the token.
    /// @param account The address to check.
    /// @param permissionType The type of permission.
    /// @return True if the account has the permission, false otherwise.
    function hasPermission(uint256 tokenId, address account, bytes32 permissionType) public view returns (bool) {
         ownerOf(tokenId); // Checks if token exists
        // Owner always has implicitly all permissions, but this function checks delegated ones specifically.
        // Add owner check if needed: return ownerOf(tokenId) == account || _tokenPermissions[tokenId][permissionType][account];
        return _tokenPermissions[tokenId][permissionType][account];
    }


    // --- Configuration (Owner Only) ---

     /// @notice Sets the base URI for token metadata.
    /// @param baseURI The new base URI.
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

     /// @notice Sets the default binding status for newly minted Chronicles.
    /// @param status The default status (true for soulbound, false otherwise).
    function setDefaultBindingStatus(bool status) public onlyOwner {
        _defaultBindingStatus = status;
    }

    // --- Internal Helper for Trait setting without permission check (used by rules maybe) ---
    // This is an example of how rule application might change state directly
    function _setTraitInternal(uint256 tokenId, bytes32 traitKey, bytes memory traitValue) internal {
         bytes memory currentValue = _tokenTraits[tokenId][traitKey];
        bool traitExists = currentValue.length > 0;

        _tokenTraits[tokenId][traitKey] = traitValue;

        if (!traitExists) {
            // Add key to the list
            _tokenTraitKeyIndex[tokenId][traitKey] = _tokenTraitKeys[tokenId].length;
            _tokenTraitKeys[tokenId].push(traitKey);
        }

        emit TraitSet(tokenId, traitKey, traitValue); // Still emit event
    }
}
```