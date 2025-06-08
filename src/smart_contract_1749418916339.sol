Okay, let's design a smart contract system that combines several advanced and trendy concepts: Soulbound Tokens (SBTs), Dynamic NFTs, Reputation Systems, and Access Control Gating.

This system will allow users to earn non-transferable SBTs representing achievements or roles. These SBTs will influence a single, dynamic, non-transferable Profile NFT owned by each user. Access to certain functions within this (or potentially other integrated) contract will be gated based on the user's held SBTs or a calculated 'effective reputation' score derived from those SBTs.

It's not a standard ERC-20, ERC-721 (though it uses parts), or typical DeFi/DAO contract. The core uniqueness is the interplay between SBTs, the dynamically changing NFT, and reputation-based gating.

---

**Contract Name:** ReputationGatedDynamicAssets

**Outline & Function Summary:**

1.  **Purpose:** To create a system where users earn non-transferable Soulbound Tokens (SBTs) that contribute to a dynamic 'Effective Reputation' score. Each user owns a single, non-transferable Profile NFT whose properties (via metadata URI) are dynamically influenced by their SBTs and reputation. Access to certain contract functions is gated based on required SBTs or minimum reputation.

2.  **Key Concepts:**
    *   **Soulbound Tokens (SBTs):** Non-transferable tokens representing achievements, roles, or contributions. Managed by a trusted oracle/admin.
    *   **Dynamic NFTs:** A Profile NFT whose associated metadata (fetched via `tokenURI`) changes based on the owner's current state (held SBTs, calculated reputation).
    *   **Reputation System:** A calculated score based on the types and 'weights' of SBTs a user holds.
    *   **Access Control Gating:** Restricting function calls based on SBT ownership or minimum reputation requirements.
    *   **Non-Transferable Assets:** Both SBTs and the Profile NFT are designed to be non-transferable to maintain the integrity of the reputation/identity link.
    *   **Oracle Dependency:** Requires a trusted off-chain process or oracle to award/revoke SBTs based on verified actions/contributions.

3.  **Core Components:**
    *   Admin/Owner: Manages SBT types, oracle address, pausing.
    *   Trusted Oracle: The only entity (besides owner) that can award/revoke SBTs.
    *   SBT Management: Functions for defining, awarding, and revoking SBTs.
    *   Profile NFT Management: Functions for minting the single, non-transferable Profile NFT per user.
    *   Reputation Calculation: Internal and external functions to calculate effective reputation based on held SBTs.
    *   Dynamic Metadata: The `tokenURI` function generates a URL reflecting the user's current state.
    *   Gated Functions: Example functions that check for SBT/reputation requirements before execution.
    *   Query Functions: For checking SBTs, reputation, and profile data.

4.  **Function Summary (24+ Functions):**

    *   **Admin/Setup (`onlyOwner`)**
        1.  `constructor(address initialOracle)`: Initializes the contract, sets owner and initial oracle.
        2.  `setTrustedOracle(address newOracle)`: Updates the address allowed to award/revoke SBTs.
        3.  `addSBTType(string memory name, uint256 weight)`: Defines a new type of SBT with a name and weight for reputation calculation. Emits `SBTTypeAdded`.
        4.  `removeSBTType(uint256 sbtTypeId)`: Removes an existing SBT type. Emits `SBTTypeRemoved`.
        5.  `setSBTTypeWeight(uint256 sbtTypeId, uint256 newWeight)`: Updates the reputation weight of an SBT type. Emits `SBTTypeWeightUpdated`.
        6.  `pause()`: Pauses core functionality (SBT awarding/revoking, gated actions). Inherited from Pausable.
        7.  `unpause()`: Unpauses the contract. Inherited from Pausable.
        8.  `withdrawFunds(address payable to, uint256 amount)`: Allows owner to withdraw ETH (if any is sent to contract).

    *   **Oracle Functions (`onlyOracle`)**
        9.  `awardSBT(address user, uint256 sbtTypeId)`: Awards an SBT of a specific type to a user. Fails if user already has it or type doesn't exist. Emits `SBT awarded`.
        10. `revokeSBT(address user, uint256 sbtTypeId)`: Revokes (burns) an SBT of a specific type from a user. Fails if user doesn't have it or type doesn't exist. Emits `SBTRevoked`.

    *   **User Functions (Profile NFT / Gated Actions)**
        11. `mintProfileNFT()`: Allows a user to mint their unique, non-transferable Profile NFT. Fails if user already has one. Emits `Transfer` (ERC721 mint event).
        12. `performGatedActionWithSBT(uint256 requiredSbtTypeId)`: An example function requiring the caller to hold a specific SBT type. Executes logic if eligible. Emits `GatedActionPerformed`.
        13. `performGatedActionWithMinReputation(uint256 minReputation)`: An example function requiring the caller to have at least a minimum effective reputation score. Executes logic if eligible. Emits `GatedActionPerformed`.

    *   **Public Query Functions**
        14. `getSBTTypes()`: Returns a list of all defined SBT type IDs.
        15. `getSBTTypeDetails(uint256 sbtTypeId)`: Returns the name and weight of a specific SBT type.
        16. `hasSBT(address user, uint256 sbtTypeId)`: Checks if a user holds a specific SBT type.
        17. `getUserSBTs(address user)`: Returns a list of all SBT type IDs held by a user.
        18. `calculateEffectiveReputation(address user)`: Calculates and returns the user's current effective reputation score based on held SBTs.
        19. `hasProfileNFT(address user)`: Checks if a user has minted their Profile NFT.
        20. `getProfileNFTId(address user)`: Returns the token ID of the user's Profile NFT.
        21. `getProfileOwner(uint256 tokenId)`: Returns the owner of a Profile NFT token ID (standard ERC721 `ownerOf`).
        22. `isGatedActionEligibleWithSBT(address user, uint256 requiredSbtTypeId)`: Checks if a user meets the SBT requirement for a gated action *without* performing the action.
        23. `isGatedActionEligibleWithMinReputation(address user, uint256 minReputation)`: Checks if a user meets the min reputation requirement for a gated action *without* performing the action.

    *   **ERC721 Standard Overrides (for Profile NFT)**
        24. `tokenURI(uint256 tokenId)`: Returns a dynamic URI pointing to metadata for the Profile NFT, including data influenced by the owner's SBTs/reputation.
        25. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 support.
        26. `balanceOf(address owner)`: Returns 0 or 1 for profile NFT ownership.
        27. `ownerOf(uint256 tokenId)`: Returns the owner of a profile NFT.
        (Other ERC721 functions like `approve`, `getApproved`, `setApprovalForAll`, `isApprovedForAll` will exist but might be effectively disabled by the non-transferable `_transfer` override for the Profile NFT).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol"; // For ERC721Enumerable, which isn't fully implemented here but useful standard

// --- Outline & Function Summary ---
// Contract Name: ReputationGatedDynamicAssets
// Purpose: To create a system where users earn non-transferable Soulbound Tokens (SBTs) that contribute to a dynamic 'Effective Reputation' score. Each user owns a single, non-transferable Profile NFT whose properties (via metadata URI) are dynamically influenced by their SBTs and reputation. Access to certain contract functions is gated based on required SBTs or minimum reputation.
// Key Concepts: Soulbound Tokens (SBTs), Dynamic NFTs, Reputation System, Access Control, Oracles (simplified role), Non-transferable Assets.
//
// Core Components:
// - Admin/Owner: Manages SBT types, oracle address, pausing.
// - Trusted Oracle: Entity allowed to award/revoke SBTs.
// - SBT Management: Define, award, revoke SBTs.
// - Profile NFT Management: Mint single, non-transferable Profile NFT per user.
// - Reputation Calculation: Score based on held SBTs and their weights.
// - Dynamic Metadata: tokenURI reflects current SBTs/reputation state.
// - Gated Functions: Require SBTs or min reputation to execute.
//
// Function Summary (24+):
// Admin/Setup (`onlyOwner`):
// 1.  constructor(address initialOracle)
// 2.  setTrustedOracle(address newOracle)
// 3.  addSBTType(string memory name, uint256 weight)
// 4.  removeSBTType(uint256 sbtTypeId)
// 5.  setSBTTypeWeight(uint256 sbtTypeId, uint256 newWeight)
// 6.  pause() (Inherited)
// 7.  unpause() (Inherited)
// 8.  withdrawFunds(address payable to, uint256 amount)
//
// Oracle Functions (`onlyOracle`):
// 9.  awardSBT(address user, uint256 sbtTypeId)
// 10. revokeSBT(address user, uint256 sbtTypeId)
//
// User Functions (Profile NFT / Gated Actions):
// 11. mintProfileNFT()
// 12. performGatedActionWithSBT(uint256 requiredSbtTypeId)
// 13. performGatedActionWithMinReputation(uint256 minReputation)
//
// Public Query Functions:
// 14. getSBTTypes()
// 15. getSBTTypeDetails(uint256 sbtTypeId)
// 16. hasSBT(address user, uint256 sbtTypeId)
// 17. getUserSBTs(address user)
// 18. calculateEffectiveReputation(address user)
// 19. hasProfileNFT(address user)
// 20. getProfileNFTId(address user)
// 21. getProfileOwner(uint256 tokenId) (Standard ERC721)
// 22. isGatedActionEligibleWithSBT(address user, uint256 requiredSbtTypeId)
// 23. isGatedActionEligibleWithMinReputation(address user, uint256 minReputation)
//
// ERC721 Standard Overrides (for Profile NFT):
// 24. tokenURI(uint256 tokenId) (Dynamic)
// 25. supportsInterface(bytes4 interfaceId) (Standard ERC165)
// 26. balanceOf(address owner) (Standard ERC721)
// 27. ownerOf(uint256 tokenId) (Standard ERC721)
// (Other ERC721 like approve/setApprovalForAll exist but are restricted by non-transferable logic)
// -----------------------------------------------------

contract ReputationGatedDynamicAssets is ERC721, Ownable, Pausable {

    // --- State Variables ---

    // SBT Management
    struct SBTType {
        string name;
        uint256 weight; // Weight contributing to effective reputation
        bool exists;    // To check if a type ID is valid
    }

    mapping(uint256 => SBTType) public sbtTypes;
    uint256 private _nextSbtTypeId;
    uint256[] private _sbtTypeIds; // Array to keep track of existing SBT type IDs

    // User SBT Balances (Soulbound: mapping user => sbtTypeId => bool)
    mapping(address => mapping(uint256 => bool)) private _userSbtBalances;

    // Profile NFT Management
    // Each user gets exactly one non-transferable Profile NFT
    mapping(address => uint256) private _userProfileNftId;
    mapping(uint256 => address) private _profileNftIdToUser; // Reverse lookup
    using Counters for Counters.Counter;
    Counters.Counter private _profileTokenIds;

    // Access Control
    address public trustedOracle;

    // Base URI for dynamic metadata. Actual metadata needs an external service.
    string public baseTokenURI;

    // --- Events ---

    event SBTTypeAdded(uint256 indexed sbtTypeId, string name, uint256 weight);
    event SBTTypeRemoved(uint256 indexed sbtTypeId);
    event SBTTypeWeightUpdated(uint256 indexed sbtTypeId, uint256 oldWeight, uint256 newWeight);
    event SBTAwarded(address indexed user, uint256 indexed sbtTypeId);
    event SBTRevoked(address indexed user, uint256 indexed sbtTypeId);
    event ProfileNFTMinted(address indexed user, uint256 indexed tokenId);
    event GatedActionPerformed(address indexed user, string actionIdentifier); // Generic event for gated actions

    // --- Modifiers ---

    modifier onlyOracle() {
        require(msg.sender == trustedOracle, "Not the trusted oracle");
        _;
    }

    modifier onlyProfileNFTAwner(uint256 tokenId) {
        require(_profileNftIdToUser[tokenId] == msg.sender, "Not the Profile NFT owner");
        _;
    }

    modifier gatedBySBT(uint256 sbtTypeId) {
        require(sbtTypes[sbtTypeId].exists, "Invalid SBT type ID");
        require(_userSbtBalances[msg.sender][sbtTypeId], "Requires specific SBT");
        _;
    }

    modifier gatedByMinReputation(uint256 minReputation) {
        require(calculateEffectiveReputation(msg.sender) >= minReputation, "Insufficient reputation");
        _;
    }

    // --- Constructor ---

    constructor(address initialOracle)
        ERC721("UserProfileNFT", "UPRO")
        Ownable(msg.sender) // Set contract deployer as owner
    {
        require(initialOracle != address(0), "Initial oracle cannot be zero address");
        trustedOracle = initialOracle;
        _nextSbtTypeId = 1; // Start SBT Type IDs from 1
        baseTokenURI = "https://your-metadata-server.com/metadata/"; // **IMPORTANT: Replace with your actual server URI**
    }

    // --- Admin Functions (`onlyOwner`) ---

    function setTrustedOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "New oracle cannot be zero address");
        trustedOracle = newOracle;
    }

    function addSBTType(string memory name, uint256 weight) external onlyOwner {
        uint256 sbtTypeId = _nextSbtTypeId++;
        sbtTypes[sbtTypeId] = SBTType({
            name: name,
            weight: weight,
            exists: true
        });
        _sbtTypeIds.push(sbtTypeId); // Add to the list of existing types
        emit SBTTypeAdded(sbtTypeId, name, weight);
    }

    function removeSBTType(uint256 sbtTypeId) external onlyOwner {
        require(sbtTypes[sbtTypeId].exists, "SBT type does not exist");
        // We don't delete the SBTType struct fully, just mark it non-existent
        // This prevents conflicts if the ID is re-used (which it isn't in this system)
        // and avoids iterating over a sparse mapping during reputation calc.
        // More importantly, it allows `getUserSBTs` to still potentially show
        // a user *had* a revoked type, although `hasSBT` would be false.
        // A cleaner approach might be to move users' balances for this type.
        // For simplicity here, just mark as non-existent.
        sbtTypes[sbtTypeId].exists = false;

        // Remove from the list of IDs (inefficient for large arrays, consider a set/linked list for production)
        for (uint i = 0; i < _sbtTypeIds.length; i++) {
            if (_sbtTypeIds[i] == sbtTypeId) {
                _sbtTypeIds[i] = _sbtTypeIds[_sbtTypeIds.length - 1];
                _sbtTypeIds.pop();
                break;
            }
        }

        emit SBTTypeRemoved(sbtTypeId);
    }

    function setSBTTypeWeight(uint256 sbtTypeId, uint256 newWeight) external onlyOwner {
        require(sbtTypes[sbtTypeId].exists, "SBT type does not exist");
        uint256 oldWeight = sbtTypes[sbtTypeId].weight;
        sbtTypes[sbtTypeId].weight = newWeight;
        emit SBTTypeWeightUpdated(sbtTypeId, oldWeight, newWeight);
    }

    function withdrawFunds(address payable to, uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        (bool success, ) = to.call{value: amount}("");
        require(success, "ETH withdrawal failed");
    }

    // --- Oracle Functions (`onlyOracle` & `whenNotPaused`) ---

    function awardSBT(address user, uint256 sbtTypeId) external onlyOracle whenNotPaused {
        require(user != address(0), "Cannot award to zero address");
        require(sbtTypes[sbtTypeId].exists, "SBT type does not exist");
        require(!_userSbtBalances[user][sbtTypeId], "User already has this SBT");

        _userSbtBalances[user][sbtTypeId] = true;
        emit SBTAwarded(user, sbtTypeId);
    }

    function revokeSBT(address user, uint256 sbtTypeId) external onlyOracle whenNotPaused {
        require(user != address(0), "Cannot revoke from zero address");
        require(sbtTypes[sbtTypeId].exists, "SBT type does not exist");
        require(_userSbtBalances[user][sbtTypeId], "User does not have this SBT");

        _userSbtBalances[user][sbtTypeId] = false;
        emit SBTRevoked(user, sbtTypeId);
    }

    // --- User Functions (Profile NFT / Gated Actions) (`whenNotPaused`) ---

    function mintProfileNFT() external whenNotPaused {
        require(_userProfileNftId[msg.sender] == 0, "User already has a Profile NFT");

        _profileTokenIds.increment();
        uint256 newTokenId = _profileTokenIds.current();

        _safeMint(msg.sender, newTokenId); // Standard ERC721 mint
        _userProfileNftId[msg.sender] = newTokenId;
        _profileNftIdToUser[newTokenId] = msg.sender;

        emit ProfileNFTMinted(msg.sender, newTokenId);
    }

    // Example Gated Function 1: Requires a specific SBT
    function performGatedActionWithSBT(uint256 requiredSbtTypeId) external whenNotPaused gatedBySBT(requiredSbtTypeId) {
        // --- Your Gated Logic Here ---
        // This is a placeholder for actions like:
        // - Accessing a special feature
        // - Receiving a bonus or reward
        // - Participating in a restricted vote
        // - Crafting a special item (in a game context)
        // -----------------------------

        emit GatedActionPerformed(msg.sender, string(abi.encodePacked("RequiresSBT_", Strings.toString(requiredSbtTypeId))));
        // Example: potentially interact with another contract, update user state, etc.
    }

    // Example Gated Function 2: Requires a minimum effective reputation score
    function performGatedActionWithMinReputation(uint256 minReputation) external whenNotPaused gatedByMinReputation(minReputation) {
        // --- Your Gated Logic Here ---
        // This is a placeholder for actions like:
        // - Accessing higher tiers of service
        // - Becoming eligible for a role
        // - Unlocking advanced functionalities
        // -----------------------------

        emit GatedActionPerformed(msg.sender, string(abi.encodePacked("RequiresMinReputation_", Strings.toString(minReputation))));
        // Example: potentially interact with another contract, update user state, etc.
    }

    // --- Public Query Functions ---

    function getSBTTypes() external view returns (uint256[] memory) {
        // Only return IDs that are currently marked as existing
        uint256 count = 0;
        for(uint i = 0; i < _sbtTypeIds.length; i++) {
            if (sbtTypes[_sbtTypeIds[i]].exists) {
                count++;
            }
        }
        uint256[] memory activeSbtTypeIds = new uint256[](count);
        uint256 index = 0;
         for(uint i = 0; i < _sbtTypeIds.length; i++) {
            if (sbtTypes[_sbtTypeIds[i]].exists) {
                activeSbtTypeIds[index++] = _sbtTypeIds[i];
            }
        }
        return activeSbtTypeIds;
    }

    function getSBTTypeDetails(uint256 sbtTypeId) external view returns (string memory name, uint256 weight) {
        require(sbtTypes[sbtTypeId].exists, "SBT type does not exist");
        return (sbtTypes[sbtTypeId].name, sbtTypes[sbtTypeId].weight);
    }

    function hasSBT(address user, uint256 sbtTypeId) public view returns (bool) {
        // Note: This only returns true if the SBT type exists *and* the user has it.
        // If the type was removed, it will return false even if the user technically
        // had it before removal. This aligns with using 'exists' flag.
        return sbtTypes[sbtTypeId].exists && _userSbtBalances[user][sbtTypeId];
    }

    function getUserSBTs(address user) external view returns (uint256[] memory) {
        uint256[] memory allSbtTypes = getSBTTypes(); // Get active types
        uint256 count = 0;
        for (uint i = 0; i < allSbtTypes.length; i++) {
            if (_userSbtBalances[user][allSbtTypes[i]]) {
                count++;
            }
        }

        uint256[] memory userSbtIds = new uint256[](count);
        uint256 index = 0;
        for (uint i = 0; i < allSbtTypes.length; i++) {
            if (_userSbtBalances[user][allSbtTypes[i]]) {
                userSbtIds[index++] = allSbtTypes[i];
            }
        }
        return userSbtIds;
    }

    function calculateEffectiveReputation(address user) public view returns (uint256) {
        uint256 reputation = 0;
        // Iterate through all active SBT types
        uint256[] memory allSbtTypes = getSBTTypes();
        for (uint i = 0; i < allSbtTypes.length; i++) {
            uint256 sbtTypeId = allSbtTypes[i];
            // If the user has this SBT, add its weight to the reputation
            if (_userSbtBalances[user][sbtTypeId]) {
                 // This check is technically redundant due to hasSBT logic,
                 // but explicit check against the mapping is clearer for this calculation.
                if (sbtTypes[sbtTypeId].exists) { // Ensure type still exists
                     reputation += sbtTypes[sbtTypeId].weight;
                }
            }
        }
        return reputation;
    }

    function hasProfileNFT(address user) public view returns (bool) {
        return _userProfileNftId[user] != 0;
    }

    function getProfileNFTId(address user) public view returns (uint256) {
        return _userProfileNftId[user];
    }

    // Standard ERC721 ownerOf function
    function getProfileOwner(uint256 tokenId) external view returns (address) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
         return ownerOf(tokenId); // Uses inherited ownerOf
    }

    function isGatedActionEligibleWithSBT(address user, uint256 requiredSbtTypeId) external view returns (bool) {
         return hasSBT(user, requiredSbtTypeId);
    }

    function isGatedActionEligibleWithMinReputation(address user, uint256 minReputation) external view returns (bool) {
         return calculateEffectiveReputation(user) >= minReputation;
    }


    // --- ERC721 Standard Overrides ---

    // Override _transfer to make Profile NFTs non-transferable between users
    // Allows burning by transferring to address(0) if needed, but prevents user-to-user transfers.
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(
            to == address(0) || _profileNftIdToUser[tokenId] == from,
            "Profile NFT is non-transferable"
        );
        // If transferring to address(0), we can allow burning.
        // If transferring from 'from' to 'to' (where 'to' is not zero),
        // the 'require' checks if the token belongs to 'from'.
        // The requirement `_profileNftIdToUser[tokenId] == from` *itself* prevents
        // user-to-user transfer because the outer function `transferFrom` requires
        // `_isApprovedOrOwner(from, tokenId)`, which will be true if 'from' is the owner.
        // But this override then checks if the destination 'to' is the owner.
        // This logic is slightly confusing. Let's simplify: disallow *any* transfer
        // that is not a mint or a burn.
         if (from != address(0) && to != address(0)) {
             revert("Profile NFT is non-transferable");
         }
        // Minting (from address(0)) and Burning (to address(0)) are allowed
        super._transfer(from, to, tokenId);

        // Update the reverse mapping on mint/burn
        if (from == address(0)) { // Mint
             _profileNftIdToUser[tokenId] = to;
             _userProfileNftId[to] = tokenId; // Store the token id for the user
        } else if (to == address(0)) { // Burn
             delete _profileNftIdToUser[tokenId];
             delete _userProfileNftId[from]; // Remove the token id from the user
        }
    }

     // We need to override the external transfer functions to use our internal _transfer logic
    function transferFrom(address from, address to, uint256 tokenId) public override {
        // This will trigger the _transfer override which prevents user-to-user transfer
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        // This will trigger the _transfer override which prevents user-to-user transfer
        super.safeTransferFrom(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        // This will trigger the _transfer override which prevents user-to-user transfer
        super.safeTransferFrom(from, to, tokenId, data);
    }


    // This function makes the NFT dynamic by pointing to a metadata server endpoint
    // The server should query the contract for the owner's SBTs and reputation
    // using the provided token ID (and hence the owner's address), and generate
    // the appropriate JSON metadata on the fly.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        address owner = ownerOf(tokenId);
        // Construct a URI that includes owner address or token ID
        // The server uses this info to query contract state and build dynamic metadata
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId), "/", Strings.toHexString(owner)));
    }

    // Standard ERC165 support for ERC721
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    // Standard ERC721 balance
    function balanceOf(address owner) public view override returns (uint256) {
         require(owner != address(0), "ERC721: address zero is not a valid owner");
        // Since each user can have at most one Profile NFT, balance is 0 or 1
        return _userProfileNftId[owner] != 0 ? 1 : 0;
    }

     // Standard ERC721 ownerOf
    function ownerOf(uint256 tokenId) public view override returns (address) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
         // Use our reverse lookup mapping which is updated by _transfer
         return _profileNftIdToUser[tokenId];
    }

    // We should also ensure the Profile NFT cannot be approved or delegated for transfer
    // By overriding _transfer to revert on user-to-user transfers, approve/setApprovalForAll
    // become effectively useless for transferring the NFT, but the functions still exist.
    // For strict soulbound, we could potentially make them revert or return false,
    // but relying on the _transfer override is common practice.

    // Need to explicitly add Pausable's whenNotPaused modifier to relevant functions
    // Added above.

    // Need to explicitly add ERC721's _beforeTokenTransfer hook if any logic
    // is needed *before* mint/burn/transfer happens (not used here).
    // Need to explicitly add ERC721's _afterTokenTransfer hook if any logic
    // is needed *after* mint/burn/transfer happens (used implicitly via super._transfer which calls hooks)
}
```

**Explanation of Advanced/Trendy/Creative Concepts:**

1.  **Soulbound Tokens (SBTs):** Implemented by `_userSbtBalances` mapping and the `awardSBT`/`revokeSBT` functions. The crucial "soulbound" aspect is enforced by preventing transfers of these specific token types (they aren't standard ERC20/ERC1155/ERC721 tokens themselves, just a boolean flag linked to the user address and an `sbtTypeId`).
2.  **Dynamic NFTs:** The `ProfileNFT` is ERC721 compatible but dynamic. Its visual or data properties are not static. The `tokenURI` function points to an external service (`baseTokenURI`) and passes parameters (like the token ID and owner address). The server *then* queries the contract (or a read-replica) via public functions (`getUserSBTs`, `calculateEffectiveReputation`) to fetch the user's current state and generate the NFT metadata JSON dynamically. This allows the NFT to visually or functionally evolve as the user earns more SBTs or reputation.
3.  **Reputation System:** The `calculateEffectiveReputation` function aggregates a score based on the `weight` assigned to different `SBTType`s held by the user. This provides a quantifiable measure derived from qualitative achievements (SBTs).
4.  **Access Control Gating:** Modifiers like `gatedBySBT` and `gatedByMinReputation` are used to restrict who can call certain functions (`performGatedAction...`). This is a powerful pattern for building tiered access, privileged actions, or feature unlocks based on verifiable on-chain identity/reputation.
5.  **Non-Transferable Assets:** Both the SBT concept (by design) and the Profile NFT (enforced by overriding `_transfer`) are made non-transferable. This is key for identity and reputation systems, as the asset is tied to the specific user's wallet and history, not a tradeable commodity. Overriding standard functions like `_transfer` is an advanced Solidity technique.
6.  **Oracle Dependency:** The contract design explicitly acknowledges the need for a trusted source (`trustedOracle`) to manage the awarding and revoking of SBTs. This is a common pattern for bringing off-chain actions or complex verification results into a smart contract system.

This contract provides a robust framework for building identity and reputation-based applications on-chain, leveraging several modern web3 concepts beyond basic token standards.