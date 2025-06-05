Okay, let's create a smart contract concept that goes beyond standard tokens and simple interactions. We'll build a "Digital Estate" contract that represents a complex on-chain identity or collection of digital assets and attributes, featuring dynamic properties, inheritance mechanisms, granular access control, and linked external assets.

It won't be a simple ERC20, ERC721, or staking contract. It incorporates elements of programmable assets, decentralized identity fragments, and on-chain legacy planning.

**Concept: Digital Estate Manager**

This contract manages unique "Digital Estate Core" NFTs (ERC721). Each Estate Core NFT represents a user's primary digital presence within this ecosystem. Attached to this core are dynamic attributes, skills, traits, authorized managers, inheritance plans, and links to other on-chain assets.

**Advanced Concepts Used:**

1.  **Programmable Assets:** The `EstateCoreNFT` is not just an ID; its state (attributes, skills) changes dynamically.
2.  **Dynamic Attributes:** Arbitrary key-value pairs (of different types) attached to an NFT instance, mutable under specific conditions.
3.  **On-chain Legacy/Inheritance:** A defined process for transferring ownership based on a configurable inactivity timer.
4.  **Granular Access Control:** Differentiating between ownership, management rights, and specific feature access granted to other addresses.
5.  **Internal Skill Tree/Progression:** Numerical skill levels and boolean traits attached to the NFT, potentially influencing interactions.
6.  **External Asset Linking (Metadata/Reference):** Ability to record ownership or association with other NFTs/tokens on-chain within the estate's context (without transferring actual ownership of external assets).

---

**Smart Contract: DigitalEstateManager**

**Outline & Function Summary:**

*   **Core Data Structures:** Define structs for Estate data, linked external assets, attribute types.
*   **State Variables:** Mappings to store estate data, attribute values, skills, traits, managers, heirs, access rights, etc. Counters for unique IDs.
*   **Events:** Define events for key state changes (creation, attribute updates, skill changes, manager/heir updates, inheritance, access grants, linking).
*   **Modifiers:** Custom modifiers for access control (`onlyEstateOwner`, `onlyEstateManager`, `onlyEstateOwnerOrManager`, `onlyHeirIfInheritable`).
*   **ERC721 Standard Functions:** Implement necessary ERC721 functions (via inheritance) for ownership and transfers.
*   **Estate Management Functions:**
    *   `createEstateCore`: Mint a new `EstateCoreNFT` for `msg.sender`.
    *   `authorizeManager`: Grant management rights for an estate to another address.
    *   `revokeManager`: Remove management rights.
    *   `extendInactivityPeriod`: Reset the inheritance inactivity timer for the owner's estate.
    *   `transferEstateCore`: Wrapper around ERC721 transfer, potentially updating state (like resetting inactivity timer).
*   **Dynamic Attribute Functions:**
    *   `setAttributeUint`: Set/update a unsigned integer attribute for an estate.
    *   `getAttributeUint`: Retrieve an unsigned integer attribute.
    *   `removeAttributeUint`: Remove an unsigned integer attribute.
    *   `setAttributeString`: Set/update a string attribute.
    *   `getAttributeString`: Retrieve a string attribute.
    *   `removeAttributeString`: Remove a string attribute.
    *   `setAttributeAddress`: Set/update an address attribute.
    *   `getAttributeAddress`: Retrieve an address attribute.
    *   `removeAttributeAddress`: Remove an address attribute.
*   **Skill & Trait Functions:**
    *   `addSkillLevel`: Increase a skill level for an estate.
    *   `getSkillLevel`: Retrieve a skill level.
    *   `unlockTrait`: Grant a specific boolean trait.
    *   `hasTrait`: Check if a trait is unlocked.
    *   `applySkillEffect`: (Conceptual) A function representing the usage of a skill, requires a minimum level. Could log usage or trigger internal state changes.
*   **Inheritance Functions:**
    *   `setHeir`: Nominate an heir address for an estate.
    *   `removeHeir`: Remove the nominated heir.
    *   `activateInheritance`: Allows the designated heir to claim ownership if the inactivity period has passed.
*   **Access Control Functions:**
    *   `grantAccessRight`: Grant a specific named access permission to an address for an estate.
    *   `revokeAccessRight`: Revoke a specific named access permission.
    *   `hasAccessRight`: Check if an address has a specific access permission.
*   **External Asset Linking Functions:**
    *   `linkExternalNFT`: Record a reference to an external ERC721 asset associated with an estate.
    *   `unlinkExternalNFT`: Remove the reference to an external NFT.
    *   `getLinkedExternalNFTs`: Retrieve the list of linked external NFTs for an estate.
*   **View/Utility Functions:**
    *   `getEstateCoreDetails`: Get core data for an estate (owner, creation time, last interaction).
    *   `isManager`: Check if an address is an authorized manager for an estate.
    *   `getHeir`: Get the designated heir for an estate.
    *   `getInheritanceActivationTime`: Get the timestamp when inheritance can be activated.
    *   `getAccessRights`: Get all granted access rights for an estate (might need pagination or be limited).
    *   `getSkillList`: Get all skills and levels for an estate (might need pagination).
    *   `getAttributeListUint`, `getAttributeListString`, `getAttributeListAddress`: Get lists of attribute keys (might need pagination).
    *   `getTotalEstates`: Get the total number of minted estates.
    *   `estateExists`: Check if an estate ID is valid.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Note: Using Ownable for contract *deployment/config* owner, not for estate owner.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Outline & Function Summary above the contract code.

contract DigitalEstateManager is ERC721, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _estateIdCounter;

    // --- Data Structures ---

    struct EstateCoreData {
        address owner; // Redundant with ERC721 ownerOf, but useful for quick struct access
        uint256 creationTime;
        uint256 lastOwnerInteractionTime; // For inheritance timer
        address heir;
    }

    struct ExternalNFTLink {
        address contractAddress;
        uint256 tokenId;
    }

    // --- State Variables ---

    // Core data for each estate ID
    mapping(uint256 => EstateCoreData) private _estateCoreData;

    // Dynamic Attributes (categorized by type)
    mapping(uint256 => mapping(string => uint256)) private _attributesUint;
    mapping(uint256 => mapping(string => string)) private _attributesString;
    mapping(uint256 => mapping(string => address)) private _attributesAddress;

    // Skills (using bytes32 for fixed-size key)
    mapping(uint256 => mapping(bytes32 => uint256)) private _skills;

    // Traits (using bytes32 for fixed-size key)
    mapping(uint256 => mapping(bytes32 => bool)) private _traits;

    // Authorized Managers for an estate (can modify attributes, skills, traits, grant access)
    mapping(uint256 => mapping(address => bool)) private _authorizedManagers;

    // Access Rights (grant specific permissions beyond manager)
    // estateId => permissionId (bytes32) => address => granted
    mapping(uint256 => mapping(bytes32 => mapping(address => bool))) private _accessRights;

    // Linked External Assets
    mapping(uint256 => ExternalNFTLink[]) private _linkedExternalNFTs;
    // Helper mapping to quickly check if a link exists (address+tokenId)
    mapping(uint256 => mapping(address => mapping(uint256 => bool))) private _linkedExternalNFTExists;


    // Configuration
    uint256 public inactivityPeriodForInheritance = 365 days; // Default: 1 year

    // --- Events ---

    event EstateCoreCreated(uint256 indexed estateId, address indexed owner, uint256 creationTime);
    event ManagerAuthorized(uint256 indexed estateId, address indexed manager, address indexed authorizer);
    event ManagerRevoked(uint256 indexed estateId, address indexed manager, address indexed revoker);
    event AttributeUintUpdated(uint256 indexed estateId, string key, uint256 value);
    event AttributeStringUpdated(uint256 indexed estateId, string key, string value);
    event AttributeAddressUpdated(uint256 indexed estateId, string key, address value);
    event AttributeUintRemoved(uint256 indexed estateId, string key);
    event AttributeStringRemoved(uint256 indexed estateId, string key);
    event AttributeAddressRemoved(uint256 indexed estateId, string key);
    event SkillLevelUpdated(uint256 indexed estateId, bytes32 skill, uint256 level);
    event TraitUnlocked(uint256 indexed estateId, bytes32 trait);
    event SkillEffectApplied(uint256 indexed estateId, bytes32 skill, address indexed user);
    event HeirSet(uint256 indexed estateId, address indexed heir, address indexed setter);
    event HeirRemoved(uint256 indexed estateId, address indexed remover);
    event InheritanceActivated(uint256 indexed estateId, address indexed oldOwner, address indexed newOwner);
    event InactivityPeriodExtended(uint256 indexed estateId, address indexed extender, uint256 newInteractionTime);
    event AccessRightGranted(uint256 indexed estateId, bytes32 permissionId, address indexed grantee, address indexed granter);
    event AccessRightRevoked(uint256 indexed estateId, bytes32 permissionId, address indexed revokee, address indexed revoker);
    event ExternalNFTLinked(uint256 indexed estateId, address indexed nftContract, uint256 indexed tokenId);
    event ExternalNFTUnlinked(uint256 indexed estateId, address indexed nftContract, uint256 indexed tokenId);


    // --- Modifiers ---

    modifier estateExists(uint256 estateId) {
        require(_exists(estateId), "DigitalEstate: Estate does not exist");
        _;
    }

    modifier onlyEstateOwner(uint256 estateId) {
        require(ownerOf(estateId) == msg.sender, "DigitalEstate: Not estate owner");
        _;
    }

    modifier onlyEstateManager(uint256 estateId) {
        require(_authorizedManagers[estateId][msg.sender], "DigitalEstate: Not an authorized manager");
        _;
    }

    modifier onlyEstateOwnerOrManager(uint256 estateId) {
        require(ownerOf(estateId) == msg.sender || _authorizedManagers[estateId][msg.sender], "DigitalEstate: Not estate owner or authorized manager");
        _;
    }

    modifier onlyHeirIfInheritable(uint256 estateId) {
        EstateCoreData storage estate = _estateCoreData[estateId];
        require(msg.sender == estate.heir, "DigitalEstate: Caller is not the heir");
        require(block.timestamp >= estate.lastOwnerInteractionTime + inactivityPeriodForInheritance, "DigitalEstate: Inheritance period not active yet");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("DigitalEstateCore", "DECORE") {}

    // --- ERC721 Overrides (for ERC721Enumerable and potential custom logic) ---

    // Required overrides for ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint16 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Wrap the transfer function to update last interaction time
    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        // Reset inactivity timer and heir info on ownership transfer
        _estateCoreData[tokenId].lastOwnerInteractionTime = block.timestamp;
        _estateCoreData[tokenId].heir = address(0); // Clear heir on transfer
        // Note: Managers and other data persist across transfers.
    }

    // Also wrap safeTransferFrom variants if needed, or ensure _transfer is used internally and reset happens there
    // For simplicity here, we rely on the ERC721 internal _transfer, but resetting the timer
    // requires hooking into the transfer process, which the `transferFrom` override does.
    // A more robust approach might use OpenZeppelin's `_beforeTokenTransfer` hook.
    // For this example's scope, the `transferFrom` override is sufficient.

    // --- Estate Management Functions (5) ---

    /**
     * @notice Mints a new Digital Estate Core NFT for the caller.
     * @return The ID of the newly created estate.
     */
    function createEstateCore() public returns (uint256) {
        _estateIdCounter.increment();
        uint256 newEstateId = _estateIdCounter.current();
        address owner = msg.sender;

        _safeMint(owner, newEstateId);

        _estateCoreData[newEstateId] = EstateCoreData({
            owner: owner, // Store for easy lookup, ownerOf is source of truth
            creationTime: block.timestamp,
            lastOwnerInteractionTime: block.timestamp,
            heir: address(0)
        });

        emit EstateCoreCreated(newEstateId, owner, block.timestamp);
        return newEstateId;
    }

    /**
     * @notice Authorizes an address to be a manager for a specific estate.
     * Managers can update attributes, skills, traits, and grant/revoke access rights.
     * @param estateId The ID of the estate.
     * @param manager The address to authorize.
     */
    function authorizeManager(uint256 estateId, address manager) public estateExists(estateId) onlyEstateOwner(estateId) {
        require(manager != address(0), "DigitalEstate: Cannot authorize zero address");
        require(manager != msg.sender, "DigitalEstate: Cannot authorize self as manager");
        _authorizedManagers[estateId][manager] = true;
        emit ManagerAuthorized(estateId, manager, msg.sender);
    }

    /**
     * @notice Revokes management rights for an address from a specific estate.
     * @param estateId The ID of the estate.
     * @param manager The address to revoke.
     */
    function revokeManager(uint256 estateId, address manager) public estateExists(estateId) onlyEstateOwner(estateId) {
        require(manager != address(0), "DigitalEstate: Cannot revoke zero address");
        _authorizedManagers[estateId][manager] = false;
        emit ManagerRevoked(estateId, manager, msg.sender);
    }

    /**
     * @notice Extends the inactivity period timer for the owner's estate.
     * This resets the countdown for inheritance activation.
     * @param estateId The ID of the estate.
     */
    function extendInactivityPeriod(uint256 estateId) public estateExists(estateId) onlyEstateOwner(estateId) {
        _estateCoreData[estateId].lastOwnerInteractionTime = block.timestamp;
        emit InactivityPeriodExtended(estateId, msg.sender, block.timestamp);
    }

    // --- Dynamic Attribute Functions (9) ---

    // uint attributes
    function setAttributeUint(uint256 estateId, string calldata key, uint256 value) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        _attributesUint[estateId][key] = value;
        emit AttributeUintUpdated(estateId, key, value);
    }

    function getAttributeUint(uint256 estateId, string calldata key) public view estateExists(estateId) returns (uint256) {
        return _attributesUint[estateId][key];
    }

    function removeAttributeUint(uint256 estateId, string calldata key) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        delete _attributesUint[estateId][key];
        emit AttributeUintRemoved(estateId, key);
    }

    // string attributes
    function setAttributeString(uint256 estateId, string calldata key, string calldata value) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        _attributesString[estateId][key] = value;
        emit AttributeStringUpdated(estateId, key, value);
    }

    function getAttributeString(uint256 estateId, string calldata key) public view estateExists(estateId) returns (string memory) {
        return _attributesString[estateId][key];
    }

    function removeAttributeString(uint256 estateId, string calldata key) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        delete _attributesString[estateId][key];
        emit AttributeStringRemoved(estateId, key);
    }

    // address attributes
    function setAttributeAddress(uint256 estateId, string calldata key, address value) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        _attributesAddress[estateId][key] = value;
        emit AttributeAddressUpdated(estateId, key, value);
    }

    function getAttributeAddress(uint256 estateId, string calldata key) public view estateExists(estateId) returns (address) {
        return _attributesAddress[estateId][key];
    }

    function removeAttributeAddress(uint256 estateId, string calldata key) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        delete _attributesAddress[estateId][key];
        emit AttributeAddressRemoved(estateId, key);
    }


    // --- Skill & Trait Functions (5) ---

    /**
     * @notice Increases the level of a specific skill for an estate.
     * Can only increase the level.
     * @param estateId The ID of the estate.
     * @param skill The identifier of the skill (e.g., keccak256("trading_skill")).
     */
    function addSkillLevel(uint256 estateId, bytes32 skill, uint256 levelsToAdd) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        require(levelsToAdd > 0, "DigitalEstate: Levels to add must be positive");
        _skills[estateId][skill] += levelsToAdd;
        emit SkillLevelUpdated(estateId, skill, _skills[estateId][skill]);
    }

    /**
     * @notice Gets the current level of a specific skill for an estate.
     * @param estateId The ID of the estate.
     * @param skill The identifier of the skill.
     * @return The skill level.
     */
    function getSkillLevel(uint256 estateId, bytes32 skill) public view estateExists(estateId) returns (uint256) {
        return _skills[estateId][skill];
    }

    /**
     * @notice Unlocks a specific trait for an estate. Traits are boolean flags.
     * Once unlocked, a trait cannot be locked again via this function.
     * @param estateId The ID of the estate.
     * @param trait The identifier of the trait (e.g., keccak256("verified_identity")).
     */
    function unlockTrait(uint256 estateId, bytes32 trait) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        require(!_traits[estateId][trait], "DigitalEstate: Trait already unlocked");
        _traits[estateId][trait] = true;
        emit TraitUnlocked(estateId, trait);
    }

    /**
     * @notice Checks if a specific trait is unlocked for an estate.
     * @param estateId The ID of the estate.
     * @param trait The identifier of the trait.
     * @return True if the trait is unlocked, false otherwise.
     */
    function hasTrait(uint256 estateId, bytes32 trait) public view estateExists(estateId) returns (bool) {
        return _traits[estateId][trait];
    }

    /**
     * @notice Conceptual function to represent applying a skill effect.
     * Requires a minimum skill level. This function itself doesn't do complex external interactions
     * but logs an event and could potentially modify internal state or be called by other contracts.
     * @param estateId The ID of the estate.
     * @param skill The identifier of the skill being applied.
     * @param requiredLevel The minimum level required to apply the effect.
     */
    function applySkillEffect(uint256 estateId, bytes32 skill, uint256 requiredLevel) public estateExists(estateId) {
        // This function can potentially be called by ANY address,
        // if the skill usage is meant to be triggered by external actors
        // interacting *with* the estate's capabilities.
        // Add more specific access control if only owner/manager can "use" skills.
        // e.g., require(ownerOf(estateId) == msg.sender, "DigitalEstate: Only owner can apply skill");

        require(_skills[estateId][skill] >= requiredLevel, "DigitalEstate: Insufficient skill level");

        // --- Potential internal logic here ---
        // e.g., decrease a "mana" attribute: _attributesUint[estateId]["mana"] -= cost;
        // e.g., set a cooldown timestamp: _attributesUint[estateId][bytes32(abi.encodePacked(skill, "_cooldown"))] = block.timestamp + cooldownDuration;
        // e.g., update a temporary boost attribute
        // --- End internal logic ---

        emit SkillEffectApplied(estateId, skill, msg.sender);
    }

    // --- Inheritance Functions (3) ---

    /**
     * @notice Sets or updates the heir for a specific estate.
     * Can only be set by the estate owner. Setting to address(0) removes the heir.
     * @param estateId The ID of the estate.
     * @param heirAddress The address of the heir, or address(0) to remove.
     */
    function setHeir(uint256 estateId, address heirAddress) public estateExists(estateId) onlyEstateOwner(estateId) {
        require(heirAddress != ownerOf(estateId), "DigitalEstate: Cannot set owner as heir");
        _estateCoreData[estateId].heir = heirAddress;
        emit HeirSet(estateId, heirAddress, msg.sender);
    }

    /**
     * @notice Removes the designated heir for a specific estate.
     * Can only be done by the estate owner.
     * @param estateId The ID of the estate.
     */
    function removeHeir(uint256 estateId) public estateExists(estateId) onlyEstateOwner(estateId) {
        _estateCoreData[estateId].heir = address(0);
        emit HeirRemoved(estateId, msg.sender);
    }

    /**
     * @notice Allows the designated heir to claim ownership of the estate
     * if the owner has been inactive for the specified period.
     * Resets the heir and inactivity timer upon successful activation.
     * @param estateId The ID of the estate.
     */
    function activateInheritance(uint256 estateId) public estateExists(estateId) onlyHeirIfInheritable(estateId) {
        EstateCoreData storage estate = _estateCoreData[estateId];
        address oldOwner = ownerOf(estateId);
        address newOwner = msg.sender; // The heir

        _transfer(oldOwner, newOwner, estateId); // Transfer ERC721 ownership

        // Reset inheritance state
        estate.lastOwnerInteractionTime = block.timestamp;
        estate.heir = address(0); // Clear the heir after inheritance

        emit InheritanceActivated(estateId, oldOwner, newOwner);
    }

    // --- Access Control Functions (3) ---

    /**
     * @notice Grants a specific named access right to an address for an estate.
     * Access rights are custom permissions defined by `permissionId` (e.g., keccak256("view_private_attributes")).
     * Can only be granted by the owner or an authorized manager.
     * @param estateId The ID of the estate.
     * @param permissionId The identifier of the permission (e.g., keccak256("some_feature_access")).
     * @param grantee The address to grant the permission to.
     */
    function grantAccessRight(uint256 estateId, bytes32 permissionId, address grantee) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
        require(grantee != address(0), "DigitalEstate: Cannot grant access to zero address");
        _accessRights[estateId][permissionId][grantee] = true;
        emit AccessRightGranted(estateId, permissionId, grantee, msg.sender);
    }

    /**
     * @notice Revokes a specific named access right from an address for an estate.
     * Can only be revoked by the owner or an authorized manager.
     * @param estateId The ID of the estate.
     * @param permissionId The identifier of the permission.
     * @param revokee The address to revoke the permission from.
     */
    function revokeAccessRight(uint256 estateId, bytes32 permissionId, address revokee) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
         _accessRights[estateId][permissionId][revokee] = false;
         emit AccessRightRevoked(estateId, permissionId, revokee, msg.sender);
    }

    /**
     * @notice Checks if an address has a specific named access right for an estate.
     * @param estateId The ID of the estate.
     * @param permissionId The identifier of the permission.
     * @param user The address to check.
     * @return True if the address has the permission, false otherwise.
     */
    function hasAccessRight(uint256 estateId, bytes32 permissionId, address user) public view estateExists(estateId) returns (bool) {
        return _accessRights[estateId][permissionId][user];
    }

    // --- External Asset Linking Functions (3) ---

    /**
     * @notice Links an external NFT (ERC721) to an estate. This is a reference link,
     * it does NOT transfer ownership of the external NFT to this contract or the estate owner.
     * Useful for stating association or provenance on-chain.
     * Requires the caller to prove ownership of the external NFT (e.g., via signature or requiring ownerOf check).
     * For simplicity, this implementation *assumes* the caller has the right to link this NFT.
     * A more robust version would require `IERC721(nftContract).ownerOf(tokenId) == msg.sender` or a signature.
     * @param estateId The ID of the estate to link to.
     * @param nftContract The address of the external ERC721 contract.
     * @param tokenId The ID of the external NFT.
     */
    function linkExternalNFT(uint256 estateId, address nftContract, uint256 tokenId) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
         require(nftContract != address(0), "DigitalEstate: Invalid NFT contract address");
         require(!_linkedExternalNFTExists[estateId][nftContract][tokenId], "DigitalEstate: NFT already linked");

         _linkedExternalNFTs[estateId].push(ExternalNFTLink({
             contractAddress: nftContract,
             tokenId: tokenId
         }));
         _linkedExternalNFTExists[estateId][nftContract][tokenId] = true;

         emit ExternalNFTLinked(estateId, nftContract, tokenId);
    }

    /**
     * @notice Unlinks an external NFT reference from an estate.
     * @param estateId The ID of the estate.
     * @param nftContract The address of the external ERC721 contract.
     * @param tokenId The ID of the external NFT.
     */
    function unlinkExternalNFT(uint256 estateId, address nftContract, uint256 tokenId) public estateExists(estateId) onlyEstateOwnerOrManager(estateId) {
         require(_linkedExternalNFTExists[estateId][nftContract][tokenId], "DigitalEstate: NFT is not linked");

         ExternalNFTLink[] storage links = _linkedExternalNFTs[estateId];
         bool found = false;
         for (uint i = 0; i < links.length; i++) {
             if (links[i].contractAddress == nftContract && links[i].tokenId == tokenId) {
                 // Simple remove by swapping with last element and popping
                 links[i] = links[links.length - 1];
                 links.pop();
                 found = true;
                 break; // Assuming no duplicate links allowed (enforced by _linkedExternalNFTExists)
             }
         }
         // Should always be found if _linkedExternalNFTExists is true
         require(found, "DigitalEstate: Internal linking error");

         _linkedExternalNFTExists[estateId][nftContract][tokenId] = false;

         emit ExternalNFTUnlinked(estateId, nftContract, tokenId);
    }

    /**
     * @notice Gets the list of external NFT references linked to an estate.
     * @param estateId The ID of the estate.
     * @return An array of ExternalNFTLink structs.
     */
    function getLinkedExternalNFTs(uint256 estateId) public view estateExists(estateId) returns (ExternalNFTLink[] memory) {
        return _linkedExternalNFTs[estateId];
    }


    // --- View/Utility Functions (8) ---

    /**
     * @notice Gets core details for a specific estate.
     * @param estateId The ID of the estate.
     * @return A tuple containing owner, creation time, last interaction time, and heir.
     */
    function getEstateCoreDetails(uint256 estateId) public view estateExists(estateId) returns (address owner, uint256 creationTime, uint256 lastOwnerInteractionTime, address heir) {
        EstateCoreData storage estate = _estateCoreData[estateId];
        // ownerOf(estateId) is the source of truth for current owner
        return (ownerOf(estateId), estate.creationTime, estate.lastOwnerInteractionTime, estate.heir);
    }

    /**
     * @notice Checks if an address is an authorized manager for an estate.
     * @param estateId The ID of the estate.
     * @param manager Address to check.
     * @return True if the address is an authorized manager, false otherwise.
     */
    function isManager(uint256 estateId, address manager) public view estateExists(estateId) returns (bool) {
        return _authorizedManagers[estateId][manager];
    }

    /**
     * @notice Gets the designated heir for an estate.
     * @param estateId The ID of the estate.
     * @return The heir's address, or address(0) if none is set.
     */
    function getHeir(uint256 estateId) public view estateExists(estateId) returns (address) {
        return _estateCoreData[estateId].heir;
    }

    /**
     * @notice Calculates the earliest time the heir can activate inheritance.
     * @param estateId The ID of the estate.
     * @return The activation timestamp. Returns 0 if no heir is set or estate doesn't exist.
     */
    function getInheritanceActivationTime(uint256 estateId) public view returns (uint256) {
         if (!_exists(estateId) || _estateCoreData[estateId].heir == address(0)) {
             return 0;
         }
         return _estateCoreData[estateId].lastOwnerInteractionTime + inactivityPeriodForInheritance;
    }

    /**
     * @notice Checks if an estate ID exists.
     * @param estateId The ID to check.
     * @return True if the estate exists, false otherwise.
     */
    function estateExists(uint256 estateId) public view returns (bool) {
        return _exists(estateId);
    }

    /**
     * @notice Gets the total number of estates minted.
     * @return The total count.
     */
    function getTotalEstates() public view returns (uint256) {
        return _estateIdCounter.current();
    }

    // Note: Retrieving *all* managers, skills, traits, or access rights for a specific estate
    // directly in a single view function can be gas-expensive and might hit block limits
    // if the lists are long. Mappings in Solidity do not store their keys, so iterating
    // is not natively supported on-chain.
    // For read operations, it's generally better to query specific items (e.g., isManager, getSkillLevel, hasAccessRight)
    // or rely on off-chain indexing (subgraph) to list all keys/values.
    // Including list functions here would require storing keys in arrays alongside mappings,
    // adding complexity and gas cost to write operations (adding/removing from arrays).
    // Let's include placeholders demonstrating the concept but acknowledge their limitations.

    // Example placeholder view functions (potentially expensive)
    // To make these work efficiently, you'd need additional storage structures like `string[] _attributeUintKeys[estateId]`

    // function getAttributeListUint(uint256 estateId) public view estateExists(estateId) returns (string[] memory) {
    //     // This would require storing keys in an array and iterating. Not simple with native mappings.
    //     // Returning an empty array or requiring off-chain indexing is more practical.
    //     revert("DigitalEstate: Direct attribute key listing not supported for gas efficiency. Query individual keys or use off-chain indexing.");
    // }

    // function getSkillList(uint256 estateId) public view estateExists(estateId) returns (bytes32[] memory) {
    //      revert("DigitalEstate: Direct skill key listing not supported for gas efficiency. Query individual keys or use off-chain indexing.");
    // }

    // function getManagerList(uint256 estateId) public view estateExists(estateId) returns (address[] memory) {
    //     // Same limitation as attribute lists.
    //      revert("DigitalEstate: Direct manager listing not supported for gas efficiency. Query individual addresses or use off-chain indexing.");
    // }

    // We *can* provide counts if needed, but listing all keys is problematic on-chain.
    // Let's omit the list functions to avoid misleading examples and stick to direct lookups or functions that return arrays where keys ARE stored (like _linkedExternalNFTs).

    // Function count check (including the base ERC721 functions implicitly available/overridden):
    // ERC721 Standard (approx 9 core + 4Enumerable): ownerOf, balanceOf, getApproved, isApprovedForAll, approve, setApprovalForAll, transferFrom, safeTransferFrom(2), tokenOfOwnerByIndex, tokenByIndex, totalSupply + overrides (_update, _increaseBalance, supportsInterface) = ~16
    // Custom Functions:
    // Estate Management: 5
    // Attribute Management (uint, string, address): 3 * 3 = 9
    // Skill & Trait: 5
    // Inheritance: 3
    // Access Control: 3
    // External Linking: 3
    // View/Utility: 6 (getEstateCoreDetails, isManager, getHeir, getInheritanceActivationTime, estateExists, getTotalEstates)
    // Total = ~16 + 5 + 9 + 5 + 3 + 3 + 3 + 6 = ~50+ functions (well over 20, counting inherited/overridden + custom).

    // Adding back a few reasonable list/count functions that don't require iterating all keys:
    // (Actually, the linked NFTs array is already included and listable).
    // Let's add a count for linked NFTs.

    /**
     * @notice Gets the number of external NFTs linked to an estate.
     * @param estateId The ID of the estate.
     * @return The count of linked NFTs.
     */
    function getLinkedExternalNFTCount(uint256 estateId) public view estateExists(estateId) returns (uint256) {
        return _linkedExternalNFTs[estateId].length;
    }
    // New function count: ~50 + 1 = ~51

}
```

---

**Explanation of Advanced/Creative Aspects:**

1.  **Dynamic, Typed Attributes:** Instead of just IPFS hashes or simple key-value strings in metadata (common for NFTs), this contract allows storing on-chain `uint256`, `string`, and `address` attributes directly tied to the `EstateCoreNFT`. This makes the NFT itself a dynamic data container. Examples: a `uint` "reputationScore", a `string` "bioSummary", an `address` "associatedWallet".
2.  **Internal Skill/Trait System:** The `_skills` and `_traits` mappings allow building a simple RPG-like progression or identity-proofing system directly into the NFT. `applySkillEffect` is a conceptual hook for how these could be *used* within this contract or by others.
3.  **Layered Access Control:** Beyond the ERC721 owner:
    *   **Managers:** Can update attributes, skills, traits, and grant/revoke `AccessRights`. Useful for delegating specific management tasks without transferring full ownership.
    *   **Access Rights:** A more granular layer allowing arbitrary, named permissions (e.g., `hasAccessRight(estateId, keccak256("view_private_data"), user)`). This can be used by *other* contracts or off-chain systems interacting with the estate.
4.  **Inactivity-Based Inheritance:** The `lastOwnerInteractionTime` and `activateInheritance` logic provide a basic, decentralized mechanism for passing on the digital asset if the owner becomes inactive on-chain for a set period. This addresses the problem of digital asset loss due to death or incapacity in a trustless way (assuming "inactivity" is a valid proxy).
5.  **External Asset Linking:** While simple in implementation (just storing references), the `linkExternalNFT` function allows an estate to curate and *declare* its relationship with other assets on-chain. This builds a richer digital identity/portfolio within the estate's context, viewable by anyone.

This contract structure provides a foundation for building complex on-chain digital identities, profiles, or programmable asset bundles that can represent more than just a single item or token balance. It introduces concepts relevant to decentralized identity, on-chain reputation, gaming mechanics, and digital legacy.