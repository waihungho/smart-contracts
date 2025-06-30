Okay, let's create a smart contract for a dynamic, historical NFT. This concept goes beyond standard static NFTs by allowing tokens to record a history of interactions or events associated with them on-chain, and potentially influence their metadata based on this history.

We'll call it `ChronicleNFT`.

**Core Concepts:**

1.  **ERC-721 Standard:** It will be a standard non-fungible token.
2.  **On-Chain History Log:** Each token will have an append-only list of structured events recorded against it.
3.  **Dynamic Metadata:** The `tokenURI` function will calculate attributes based on the token's history, making the metadata dynamic.
4.  **Access Control:** Using OpenZeppelin's `AccessControl` to manage who can add history entries or perform certain administrative tasks.
5.  **History Locking:** A feature to lock the history log for a specific token, preventing further additions.

**Outline and Function Summary**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChronicleNFT
 * @dev A dynamic NFT contract where each token maintains an on-chain history log
 * and its metadata can evolve based on this history. Utilizes AccessControl
 * for granular permissions on history modification and contract configuration.
 */
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // Useful for on-chain metadata generation

/**
 * @dev Enum for different types of history events. Can be extended.
 * 0: Mint
 * 1: Transfer
 * 2: Generic Interaction / Note
 * 3: Owner Update
 * 4: System Event (e.g., reaching age milestone, external trigger)
 * 5: Prepared for Burn (history entry before token is burned)
 * ... custom types
 */
enum HistoryEventType {
    Mint,
    Transfer,
    GenericInteraction,
    OwnerUpdate,
    SystemEvent,
    PreparedForBurn,
    CustomEvent1, // Add more custom types as needed
    CustomEvent2
    // Keep adding types up to 255
}

/**
 * @dev Struct representing a single entry in the token's history.
 * timestamp: The time the event occurred (uint48 to save space).
 * eventType: The type of event from the HistoryEventType enum.
 * data: Flexible bytes field to store event-specific data (e.g., transfer details, notes).
 */
struct HistoryEntry {
    uint48 timestamp; // Using uint48 to save gas/storage (covers ~17 trillion seconds from Unix epoch)
    HistoryEventType eventType;
    bytes data; // e.g., abi.encodePacked(from, to) for transfer, or a string note
}

/**
 * @dev Contract ChronicleNFT
 *
 * Inherits:
 * - ERC721: Core NFT functionality.
 * - ERC721URIStorage: Allows setting and retrieving token URIs (overridden for dynamism).
 * - AccessControl: Manages roles (DEFAULT_ADMIN_ROLE, HISTORIAN_ROLE).
 *
 * State Variables:
 * - tokenHistory: Mapping from tokenId to an array of HistoryEntry. Stores the history log.
 * - HISTORIAN_ROLE: The role needed to add history entries.
 * - historyLocked: Mapping from tokenId to boolean, indicates if history additions are locked.
 * - _nextTokenId: Counter for minting new tokens.
 * - contractBaseURI: Base URI for metadata, can be updated.
 *
 * Events:
 * - HistoryEntryAdded: Emitted when a new history entry is added to a token.
 * - HistoryAdditionLocked: Emitted when history additions are locked for a token.
 * - HistoryAdditionUnlocked: Emitted when history additions are unlocked for a token.
 * - ContractBaseURIUpdated: Emitted when the contract's base URI is changed.
 *
 * Functions:
 *
 * --- Core ERC721 (Standard Inherited/Overridden) ---
 * 1.  constructor(string memory name, string memory symbol, address defaultAdmin, address initialHistorian, string memory initialBaseURI): Initializes the contract, roles, and base URI.
 * 2.  supportsInterface(bytes4 interfaceId): Standard ERC165 interface support check.
 * 3.  name(): Returns the contract name.
 * 4.  symbol(): Returns the contract symbol.
 * 5.  balanceOf(address owner): Returns the number of tokens owned by an address.
 * 6.  ownerOf(uint256 tokenId): Returns the owner of a token.
 * 7.  approve(address to, uint256 tokenId): Approves an address to transfer a token.
 * 8.  getApproved(uint256 tokenId): Returns the approved address for a token.
 * 9.  setApprovalForAll(address operator, bool approved): Sets approval for an operator across all tokens.
 * 10. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all tokens.
 * 11. transferFrom(address from, address to, uint256 tokenId): Transfers ownership of a token.
 * 12. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers ownership.
 * 13. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Safely transfers ownership with data.
 * 14. _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize): Internal hook, overridden to add HistoryEventType.Mint/Transfer.
 *
 * --- Dynamic Metadata ---
 * 15. _baseURI(): Internal helper for tokenURI.
 * 16. tokenURI(uint256 tokenId): OVERRIDDEN. Generates a dynamic metadata URI based on the contract base URI and token history.
 * 17. calculateDynamicAttributes(uint256 tokenId): INTERNAL PURE/VIEW. Logic to process history and return attributes string (e.g., JSON snippet).
 * 18. getDynamicAttributes(uint256 tokenId): PUBLIC VIEW. Exposes the calculated dynamic attributes string.
 *
 * --- On-Chain History Management ---
 * 19. addHistoryEntry(uint256 tokenId, HistoryEventType eventType, bytes memory data): Adds a new history entry for a token. Requires HISTORIAN_ROLE and token is not locked.
 * 20. getHistoryLength(uint256 tokenId): Returns the number of history entries for a token.
 * 21. getHistoryEntry(uint256 tokenId, uint256 index): Returns a specific history entry by index.
 * 22. getAllHistory(uint256 tokenId): Returns the entire history array for a token (use with caution for long histories).
 * 23. getHistoryByType(uint256 tokenId, HistoryEventType eventType): Returns history entries filtered by type.
 * 24. getHistoryByTimestampRange(uint256 tokenId, uint48 startTime, uint48 endTime): Returns history entries filtered by timestamp range.
 * 25. getLastHistoryEntry(uint256 tokenId): Returns the most recent history entry.
 *
 * --- Minting ---
 * 26. mint(address to): Mints a new token and adds a Mint history entry.
 * 27. mintWithInitialEntry(address to, HistoryEventType initialEventType, bytes memory initialData): Mints a new token and adds a specified initial history entry.
 *
 * --- Access Control ---
 * 28. grantRole(bytes32 role, address account): Grants a role. Requires admin of the role.
 * 29. revokeRole(bytes32 role, address account): Revokes a role. Requires admin of the role.
 * 30. renounceRole(bytes32 role): Renounces a role (caller removes their own role).
 * 31. hasRole(bytes32 role, address account): Checks if an account has a specific role.
 * 32. getRoleAdmin(bytes32 role): Returns the admin role for a given role.
 * 33. getHistorianRole(): Returns the bytes32 value for the HISTORIAN_ROLE.
 * 34. canAddHistory(address account): Convenience view to check if an account has the HISTORIAN_ROLE.
 *
 * --- Configuration ---
 * 35. updateContractBaseURI(string memory newURI): Updates the contract's base URI. Requires DEFAULT_ADMIN_ROLE.
 * 36. getContractBaseURI(): Returns the current contract base URI.
 *
 * --- History Locking ---
 * 37. lockHistoryAddition(uint256 tokenId): Locks history additions for a token. Requires DEFAULT_ADMIN_ROLE.
 * 38. unlockHistoryAddition(uint256 tokenId): Unlocks history additions for a token. Requires DEFAULT_ADMIN_ROLE.
 * 39. isHistoryAdditionLocked(uint256 tokenId): Checks if history addition is locked for a token.
 *
 * --- Utility ---
 * 40. getTokenAge(uint256 tokenId): Calculates the age of the token based on its first history entry (mint timestamp).
 */
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

/**
 * @dev Enum for different types of history events. Can be extended.
 * 0: Mint
 * 1: Transfer
 * 2: Generic Interaction / Note
 * 3: Owner Update
 * 4: System Event (e.g., reaching age milestone, external trigger)
 * 5: Prepared for Burn (history entry before token is burned)
 * ... custom types
 */
enum HistoryEventType {
    Mint,
    Transfer,
    GenericInteraction,
    OwnerUpdate,
    SystemEvent,
    PreparedForBurn,
    CustomEvent1,
    CustomEvent2,
    CustomEvent3,
    CustomEvent4,
    CustomEvent5
    // Keep adding types up to 255 as needed
}

/**
 * @dev Struct representing a single entry in the token's history.
 * timestamp: The time the event occurred (uint48 to save space).
 * eventType: The type of event from the HistoryEventType enum.
 * data: Flexible bytes field to store event-specific data (e.g., transfer details, notes).
 */
struct HistoryEntry {
    uint48 timestamp; // Using uint48 saves 20 bytes per entry vs uint256
    HistoryEventType eventType;
    bytes data; // e.g., abi.encodePacked(from, to) for transfer, or a string note
}

/**
 * @title ChronicleNFT
 * @dev A dynamic NFT contract where each token maintains an on-chain history log
 * and its metadata can evolve based on this history. Utilizes AccessControl
 * for granular permissions on history modification and contract configuration.
 * Inherits ERC721, ERC721URIStorage, and AccessControl.
 */
contract ChronicleNFT is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    // --- State Variables ---
    mapping(uint256 => HistoryEntry[]) private tokenHistory;
    bytes32 public constant HISTORIAN_ROLE = keccak256("HISTORIAN_ROLE");
    mapping(uint256 => bool) private historyLocked;
    string private contractBaseURI;

    // --- Events ---
    event HistoryEntryAdded(uint256 indexed tokenId, uint256 index, uint48 timestamp, HistoryEventType eventType, bytes data);
    event HistoryAdditionLocked(uint256 indexed tokenId);
    event HistoryAdditionUnlocked(uint256 indexed tokenId);
    event ContractBaseURIUpdated(string oldURI, string newURI);

    // --- Constructor ---

    /**
     * @dev Constructor. Initializes the contract, sets up roles, and the initial base URI.
     * @param name The name for the NFT collection.
     * @param symbol The symbol for the NFT collection.
     * @param defaultAdmin The address to grant DEFAULT_ADMIN_ROLE.
     * @param initialHistorian The address to grant HISTORIAN_ROLE.
     * @param initialBaseURI The base URI for token metadata.
     */
    constructor(string memory name, string memory symbol, address defaultAdmin, address initialHistorian, string memory initialBaseURI)
        ERC721(name, symbol)
        ERC721URIStorage()
    {
        // Grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _setupRole(HISTORIAN_ROLE, initialHistorian);

        // Set initial base URI
        contractBaseURI = initialBaseURI;

        // Grant the deployer the admin role as well (optional, but common)
        if (msg.sender != defaultAdmin) {
             _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
    }

    // --- Core ERC721 Overrides ---

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     * @dev Overridden to use the stored contractBaseURI.
     */
    function _baseURI() internal view override returns (string memory) {
        return contractBaseURI;
    }

    /**
     * @dev See {ERC721-tokenURI}.
     * @dev Overridden to generate dynamic metadata based on history.
     * The generated URI points to a JSON object including base attributes and
     * a 'history_attributes' key containing the dynamically calculated part.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);

        string memory base = _baseURI();
        string memory historyAttrs = calculateDynamicAttributes(tokenId);

        // Simple JSON structure for metadata, including dynamic attributes
        // This part can be made more sophisticated to embed attributes directly
        // or point to a service that combines base + history data.
        // Here we embed a basic JSON with dynamic attributes base64 encoded.
        string memory json = string(abi.encodePacked(
            '{"name": "', name(), ' #', Strings.toString(tokenId), '",',
            '"description": "A Chronicle NFT tracking its history.",',
            '"image": "', base, Strings.toString(tokenId), '/image.png",', // Example image path
            '"history_attributes": ', historyAttrs, // This is the dynamically generated part
            '}'
        ));

        // Encode the JSON as a data URI
        string memory dataURI = string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        ));

        return dataURI;
    }

    /**
     * @dev Hook that is called before a token transfer. This includes minting and burning.
     * @dev Adds a history entry of type Mint or Transfer.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (from == address(0)) {
            // Minting
             _addHistoryEntryInternal(
                tokenId,
                HistoryEventType.Mint,
                abi.encodePacked(to) // Data can be the recipient address
            );
        } else if (to == address(0)) {
            // Burning (history is recorded *before* the token is gone)
            // Note: This history entry will exist briefly but will be inaccessible
            // via `tokenHistory[tokenId]` after the burn.
            // The event HistoryEntryAdded is crucial here for off-chain logging.
            _addHistoryEntryInternal(
                 tokenId,
                 HistoryEventType.PreparedForBurn,
                 abi.encodePacked(from) // Data can be the burner address (previous owner)
             );
        } else {
            // Transferring
             _addHistoryEntryInternal(
                tokenId,
                HistoryEventType.Transfer,
                abi.encodePacked(from, to) // Data includes both from and to addresses
            );
        }
    }

    // --- Minting ---

    /**
     * @dev Mints a new token to `to`. Automatically records a HistoryEventType.Mint entry.
     * @param to The address to mint the token to.
     */
    function mint(address to) public virtual {
        uint256 tokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(to, tokenId); // _beforeTokenTransfer hook adds the Mint history entry
        // No manual addHistoryEntry here, handled by hook
    }

     /**
     * @dev Mints a new token to `to` and adds a specified initial history entry.
     * @param to The address to mint the token to.
     * @param initialEventType The type of the initial history entry.
     * @param initialData The data for the initial history entry.
     */
    function mintWithInitialEntry(address to, HistoryEventType initialEventType, bytes memory initialData) public virtual {
        uint256 tokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(to, tokenId); // _beforeTokenTransfer hook adds the Mint history entry first
         // Then add the specific initial entry if it's not the Mint entry itself
        if (initialEventType != HistoryEventType.Mint) {
             _addHistoryEntryInternal(tokenId, initialEventType, initialData);
        } else {
            // If initialEventType is Mint, the hook already handled it.
            // We could append initialData to the hook's entry data,
            // but adding a separate entry is cleaner.
             _addHistoryEntryInternal(tokenId, HistoryEventType.GenericInteraction, initialData); // Use Generic if Mint data provided separately
        }
    }


    // --- On-Chain History Management ---

     /**
     * @dev Internal helper function to add a history entry.
     * Does not perform role or lock checks, used by internal functions/hooks.
     */
    function _addHistoryEntryInternal(uint256 tokenId, HistoryEventType eventType, bytes memory data) internal {
         tokenHistory[tokenId].push(HistoryEntry(uint48(block.timestamp), eventType, data));
         emit HistoryEntryAdded(tokenId, tokenHistory[tokenId].length - 1, uint48(block.timestamp), eventType, data);
    }

    /**
     * @dev Adds a new history entry for a token.
     * Requires the caller to have the HISTORIAN_ROLE and the token's history not to be locked.
     * @param tokenId The ID of the token.
     * @param eventType The type of history event.
     * @param data The data associated with the event.
     */
    function addHistoryEntry(uint256 tokenId, HistoryEventType eventType, bytes memory data) public onlyRole(HISTORIAN_ROLE) {
        _requireOwned(tokenId); // Ensure the token exists

        if (historyLocked[tokenId]) {
            revert("History addition is locked for this token");
        }

        _addHistoryEntryInternal(tokenId, eventType, data);
    }

    /**
     * @dev Returns the number of history entries for a given token.
     * @param tokenId The ID of the token.
     * @return The number of history entries.
     */
    function getHistoryLength(uint256 tokenId) public view returns (uint256) {
         // Note: Does not require token to be owned by caller, just that it *could* exist.
         // For safety, could add _exists(tokenId) check if needed.
        return tokenHistory[tokenId].length;
    }

    /**
     * @dev Returns a specific history entry for a token by index.
     * @param tokenId The ID of the token.
     * @param index The index of the history entry (0-based).
     * @return The history entry struct.
     */
    function getHistoryEntry(uint256 tokenId, uint256 index) public view returns (HistoryEntry memory) {
         // _exists(tokenId) check is implicitly done by tokenHistory[tokenId].length check
        require(index < tokenHistory[tokenId].length, "Index out of bounds");
        return tokenHistory[tokenId][index];
    }

    /**
     * @dev Returns the entire history array for a token.
     * WARNING: Can be expensive for tokens with a large number of history entries.
     * Consider using paginated getters or off-chain indexing for production.
     * @param tokenId The ID of the token.
     * @return An array of HistoryEntry structs.
     */
    function getAllHistory(uint256 tokenId) public view returns (HistoryEntry[] memory) {
         // _exists(tokenId) check is implicitly done by tokenHistory[tokenId].length check
        return tokenHistory[tokenId];
    }

     /**
     * @dev Returns history entries filtered by event type.
     * WARNING: Can be expensive for tokens with large history and many matching entries.
     * @param tokenId The ID of the token.
     * @param eventType The type to filter by.
     * @return An array of matching HistoryEntry structs.
     */
    function getHistoryByType(uint256 tokenId, HistoryEventType eventType) public view returns (HistoryEntry[] memory) {
         HistoryEntry[] storage history = tokenHistory[tokenId];
         uint256 count = 0;
         for (uint256 i = 0; i < history.length; i++) {
             if (history[i].eventType == eventType) {
                 count++;
             }
         }

         HistoryEntry[] memory filteredHistory = new HistoryEntry[](count);
         uint256 filteredIndex = 0;
         for (uint256 i = 0; i < history.length; i++) {
              if (history[i].eventType == eventType) {
                  filteredHistory[filteredIndex] = history[i];
                  filteredIndex++;
              }
         }
         return filteredHistory;
    }

    /**
     * @dev Returns history entries filtered by timestamp range.
     * WARNING: Can be expensive for tokens with large history.
     * @param tokenId The ID of the token.
     * @param startTime The start timestamp (inclusive, uint48).
     * @param endTime The end timestamp (inclusive, uint48).
     * @return An array of matching HistoryEntry structs.
     */
    function getHistoryByTimestampRange(uint256 tokenId, uint48 startTime, uint48 endTime) public view returns (HistoryEntry[] memory) {
         require(startTime <= endTime, "Start time must be <= end time");
         HistoryEntry[] storage history = tokenHistory[tokenId];
         uint256 count = 0;
         for (uint256 i = 0; i < history.length; i++) {
             if (history[i].timestamp >= startTime && history[i].timestamp <= endTime) {
                 count++;
             }
         }

         HistoryEntry[] memory filteredHistory = new HistoryEntry[](count);
         uint256 filteredIndex = 0;
         for (uint256 i = 0; i < history.length; i++) {
              if (history[i].timestamp >= startTime && history[i].timestamp <= endTime) {
                  filteredHistory[filteredIndex] = history[i];
                  filteredIndex++;
              }
         }
         return filteredHistory;
    }


    /**
     * @dev Returns the most recent history entry for a token.
     * @param tokenId The ID of the token.
     * @return The last history entry struct.
     */
    function getLastHistoryEntry(uint256 tokenId) public view returns (HistoryEntry memory) {
        HistoryEntry[] storage history = tokenHistory[tokenId];
        require(history.length > 0, "No history entries for this token");
        return history[history.length - 1];
    }


    // --- Dynamic Metadata Calculation ---

    /**
     * @dev Internal function to calculate dynamic attributes based on token history.
     * This logic determines what information from the history is reflected in metadata.
     * Can be overridden in derived contracts for more complex logic.
     * @param tokenId The ID of the token.
     * @return A string formatted as a JSON object/array suitable for embedding in tokenURI.
     */
    function calculateDynamicAttributes(uint256 tokenId) internal view returns (string memory) {
        HistoryEntry[] storage history = tokenHistory[tokenId];
        uint256 historyLength = history.length;

        // Example calculation: Include history length and the type of the last event
        string memory dynamicAttrsJson = "{";

        dynamicAttrsJson = string(abi.encodePacked(dynamicAttrsJson, '"history_length": ', Strings.toString(historyLength)));

        if (historyLength > 0) {
             HistoryEntry storage lastEntry = history[historyLength - 1];
             string memory lastEventTypeStr = ""; // Convert enum to string (basic example)
             if (lastEntry.eventType == HistoryEventType.Mint) lastEventTypeStr = "Mint";
             else if (lastEntry.eventType == HistoryEventType.Transfer) lastEventTypeStr = "Transfer";
             else if (lastEntry.eventType == HistoryEventType.GenericInteraction) lastEventTypeStr = "GenericInteraction";
             else if (lastEntry.eventType == HistoryEventType.OwnerUpdate) lastEventTypeStr = "OwnerUpdate";
             else if (lastEntry.eventType == HistoryEventType.SystemEvent) lastEventTypeStr = "SystemEvent";
             else if (lastEntry.eventType == HistoryEventType.PreparedForBurn) lastEventTypeStr = "PreparedForBurn";
              else if (lastEntry.eventType == HistoryEventType.CustomEvent1) lastEventTypeStr = "CustomEvent1";
              else if (lastEntry.eventType == HistoryEventType.CustomEvent2) lastEventTypeStr = "CustomEvent2";
              else if (lastEntry.eventType == HistoryEventType.CustomEvent3) lastEventTypeStr = "CustomEvent3";
              else if (lastEntry.eventType == HistoryEventType.CustomEvent4) lastEventTypeStr = "CustomEvent4";
              else if (lastEntry.eventType == HistoryEventType.CustomEvent5) lastEventTypeStr = "CustomEvent5";
             // Add more conversions as you add types

             dynamicAttrsJson = string(abi.encodePacked(dynamicAttrsJson, ',"last_event_type": "', lastEventTypeStr, '"'));
             dynamicAttrsJson = string(abi.encodePacked(dynamicAttrsJson, ',"last_event_timestamp": ', Strings.toString(lastEntry.timestamp)));

             // Example: Decode and include specific data for Transfer
             if (lastEntry.eventType == HistoryEventType.Transfer && lastEntry.data.length == 40) { // abi.encodePacked(address, address) results in 40 bytes
                address fromAddress;
                address toAddress;
                assembly {
                    fromAddress := mload(add(lastEntry.data, 32)) // Read first address (20 bytes)
                    toAddress := mload(add(lastEntry.data, 52))  // Read second address (20 bytes)
                }
                 dynamicAttrsJson = string(abi.encodePacked(dynamicAttrsJson, ',"last_transfer_from": "', Strings.toHexString(fromAddress), '"'));
                 dynamicAttrsJson = string(abi.encodePacked(dynamicAttrsJson, ',"last_transfer_to": "', Strings.toHexString(toAddress), '"'));
             }
             // Add more data decoding logic for other event types as needed
        }

        dynamicAttrsJson = string(abi.encodePacked(dynamicAttrsJson, "}"));

        return dynamicAttrsJson;
    }

    /**
     * @dev Returns the dynamically calculated attributes for a token as a JSON string snippet.
     * @param tokenId The ID of the token.
     * @return A JSON string representing the dynamic attributes.
     */
    function getDynamicAttributes(uint256 tokenId) public view returns (string memory) {
        _requireOwned(tokenId); // Or _exists to allow checking for non-existent tokens
        return calculateDynamicAttributes(tokenId);
    }

    // --- Access Control ---

    /**
     * @dev Returns the bytes32 value of the HISTORIAN_ROLE.
     */
    function getHistorianRole() public pure returns (bytes32) {
        return HISTORIAN_ROLE;
    }

     /**
     * @dev Checks if an account has the HISTORIAN_ROLE.
     * @param account The address to check.
     * @return True if the account has the role, false otherwise.
     */
    function canAddHistory(address account) public view returns (bool) {
        return hasRole(HISTORIAN_ROLE, account);
    }

    // grantRole, revokeRole, renounceRole, hasRole, getRoleAdmin are inherited from AccessControl

    // --- Configuration ---

    /**
     * @dev Updates the contract-level base URI.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param newURI The new base URI.
     */
    function updateContractBaseURI(string memory newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ContractBaseURIUpdated(contractBaseURI, newURI);
        contractBaseURI = newURI;
    }

     /**
     * @dev Returns the current contract-level base URI.
     * @return The current base URI string.
     */
    function getContractBaseURI() public view returns (string memory) {
        return contractBaseURI;
    }


    // --- History Locking ---

    /**
     * @dev Locks history additions for a specific token.
     * Once locked, addHistoryEntry will revert for this token.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param tokenId The ID of the token to lock.
     */
    function lockHistoryAddition(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _requireOwned(tokenId);
        require(!historyLocked[tokenId], "History already locked");
        historyLocked[tokenId] = true;
        emit HistoryAdditionLocked(tokenId);
    }

     /**
     * @dev Unlocks history additions for a specific token.
     * Requires DEFAULT_ADMIN_ROLE.
     * @param tokenId The ID of the token to unlock.
     */
    function unlockHistoryAddition(uint256 tokenId) public onlyRole(DEFAULT_ADMIN_ROLE) {
         _requireOwned(tokenId);
        require(historyLocked[tokenId], "History is not locked");
        historyLocked[tokenId] = false;
        emit HistoryAdditionUnlocked(tokenId);
    }

    /**
     * @dev Checks if history addition is locked for a token.
     * @param tokenId The ID of the token.
     * @return True if locked, false otherwise.
     */
    function isHistoryAdditionLocked(uint256 tokenId) public view returns (bool) {
        return historyLocked[tokenId];
    }

    // --- Utility ---

    /**
     * @dev Calculates the age of the token in seconds since its minting.
     * Based on the timestamp of the first history entry (Mint).
     * @param tokenId The ID of the token.
     * @return The age of the token in seconds.
     */
    function getTokenAge(uint256 tokenId) public view returns (uint256) {
        HistoryEntry[] storage history = tokenHistory[tokenId];
        require(history.length > 0, "Token does not have mint history"); // Should not happen for minted tokens

        // The first entry should be the Mint entry from _beforeTokenTransfer
        return block.timestamp - history[0].timestamp;
    }


    // --- Internal/Helper Functions ---

    /**
     * @dev Internal function to check if a token exists.
     * Used instead of _exists() in some view functions to allow querying history
     * even if the token might theoretically not be "owned" but still has history
     * (e.g. after a burn, though tokenHistory won't exist).
     * However, for `tokenURI` and `getDynamicAttributes`, requiring ownership
     * is more appropriate as these relate to the active token state.
     * Let's stick to _requireOwned where appropriate and rely on array checks elsewhere.
     */
    // function _exists(uint256 tokenId) internal view virtual returns (bool) {
    //     return ownerOf(tokenId) != address(0);
    // }

    // The inherited _requireOwned(tokenId) from ERC721 is useful for functions
    // that should only operate on active, owned tokens (like adding history manually,
    // or getting metadata for display).
}
```

**Explanation of Advanced Concepts and Features:**

1.  **On-Chain Structured History:** Instead of just relying on emitted events (which live in logs, not contract state), this contract stores a structured `HistoryEntry` for each significant event associated with a token directly within the contract's storage (`tokenHistory` mapping). This allows the contract's own logic (like dynamic metadata calculation) to easily access the history without relying on external indexers. Using `uint48` for timestamps is a gas optimization.
2.  **Dynamic Metadata (`tokenURI` and `calculateDynamicAttributes`):** The standard `tokenURI` function is overridden. It calls an internal `calculateDynamicAttributes` function. This function processes the token's on-chain history (`tokenHistory`) and generates a JSON string or snippet representing attributes derived from that history (e.g., number of transfers, age, type of last interaction, specific data from history entries). This JSON snippet is then embedded into a standard ERC721 metadata JSON structure, served as a data URI. This means the NFT's "traits" or "properties" can change over time based on how it's used or what happens to it, without needing to call `setTokenURI` manually.
3.  **ERC721 Hooks (`_beforeTokenTransfer`):** The `_beforeTokenTransfer` internal hook is overridden to automatically add history entries for fundamental ERC721 operations like minting and transferring. This ensures that core lifecycle events are always recorded in the on-chain history log. It also includes a `PreparedForBurn` entry *before* burning, capturing the state just before the token is destroyed (though accessing this specific entry via `tokenHistory` after the burn requires careful off-chain indexing of the `HistoryEntryAdded` event).
4.  **Access Control (`AccessControl` and Roles):** The contract uses OpenZeppelin's `AccessControl` module.
    *   `DEFAULT_ADMIN_ROLE`: Can grant/revoke other roles and manage contract-level settings like the base URI and history locking.
    *   `HISTORIAN_ROLE`: The specific role defined to allow authorized accounts (not necessarily the token owner) to add arbitrary history entries using `addHistoryEntry`. This decouples history writing from ownership, enabling curated additions or system-triggered events.
5.  **History Locking:** The `historyLocked` mapping and associated `lockHistoryAddition`/`unlockHistoryAddition` functions provide an administrative control to make a token's history immutable after a certain point. This could be used, for example, to "finalize" a token's state for historical preservation or gameplay mechanics.
6.  **Structured Events and Data (`HistoryEventType` Enum, `bytes data`):** Using an `enum` for event types makes the history structured and easier to query. The flexible `bytes data` field allows storing various types of information depending on the `eventType`, encoded using `abi.encodePacked` or other methods. Example decoding logic is included in `calculateDynamicAttributes`.
7.  **Gas Optimization (`uint48`):** Using `uint48` for timestamps instead of the default `uint256` saves storage space and gas for each history entry.

This contract provides a framework for NFTs that are not just static digital assets, but living records of their own journey on the blockchain, with metadata that evolves based on their history. It incorporates standard best practices (OpenZeppelin, AccessControl, events) while adding unique, advanced functionality.