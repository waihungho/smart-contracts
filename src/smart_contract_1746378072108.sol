Okay, here is a smart contract concept called `DecentralizedArtFusion`.

This contract orchestrates the "fusion" of specialized ERC-721 "Fragment" NFTs into new, unique ERC-721 "Artwork" NFTs. The fusion process consumes the input Fragments and deterministically generates properties for the resulting Artwork based on the fused Fragments, blockchain state, and predefined rules. It includes various administrative, user, and view functions, incorporating concepts like on-chain property generation, configurable rules, burning, and minting across different token types controlled by a single contract.

It aims to be interesting, creative, and touch upon themes like generative art and scarcity mechanisms within NFTs, while not being a direct copy of existing widely used open-source projects (like standard marketplaces, simple minting contracts, or basic staking contracts).

**Disclaimer:** This is a complex conceptual contract. Production-level code would require extensive security audits, gas optimizations, and potentially more sophisticated on-chain property generation or oracle integration depending on requirements.

---

**Outline & Function Summary**

**Contract: DecentralizedArtFusion**

This contract acts as the central hub for the Art Fusion process. It defines Fragment types, fusion rules, costs, and handles the burning of Fragments and minting of new Artwork NFTs by interacting with two separate ERC-721 contracts (one for Fragments, one for Artwork).

**Core Concepts:**

1.  **Fragment NFTs:** ERC-721 tokens (`IFragmentNFT`) representing components or ingredients for art. They have types and potentially properties.
2.  **Artwork NFTs:** ERC-721 tokens (`IArtworkNFT`) created by fusing Fragments. Their properties are generated during the fusion process.
3.  **Fusion Rules:** Configurable rules determining which Fragments can be fused, the cost, and how properties are derived, including special rules for unique combinations.
4.  **On-chain Generation:** Artwork properties are calculated deterministically within the `fuseFragments` function based on the fused Fragments and blockchain data.
5.  **Scarcity:** Fused Fragments are burned (removed from circulation).

**State Variables:**

*   `fragmentNFT`: Address of the Fragment ERC-721 contract.
*   `artworkNFT`: Address of the Artwork ERC-721 contract.
*   `owner`: Contract owner (initially deployer).
*   `fusionCost`: Cost in native currency (ETH) to perform a fusion.
*   `fragmentTypes`: Mapping storing properties for each defined Fragment type ID.
*   `specialFusionRules`: Mapping storing rules for specific Fragment type combinations.
*   `fragmentNonce`: Counter for minting Fragment IDs.
*   `artworkNonce`: Counter for minting Artwork IDs.
*   `paused`: Boolean to pause sensitive operations like fusion.

**Events:**

*   `FragmentTypeAdded`: Emitted when a new Fragment type is defined.
*   `FragmentTypeUpdated`: Emitted when a Fragment type is modified.
*   `FragmentTypeRemoved`: Emitted when a Fragment type is removed.
*   `SpecialFusionRuleAdded`: Emitted when a new special fusion rule is added.
*   `SpecialFusionRuleUpdated`: Emitted when a special fusion rule is modified.
*   `SpecialFusionRuleRemoved`: Emitted when a special fusion rule is removed.
*   `FusionCostUpdated`: Emitted when the fusion cost changes.
*   `FragmentsMinted`: Emitted when initial Fragments are minted by admin.
*   `ArtworkFused`: Emitted when Fragments are successfully fused into a new Artwork.
*   `FundsWithdrawn`: Emitted when funds are withdrawn by the owner.
*   `Paused`: Emitted when the contract is paused.
*   `Unpaused`: Emitted when the contract is unpaused.

**Function Summary (>= 20 Functions):**

**Admin/Owner Functions:**

1.  `constructor(address _fragmentNFT, address _artworkNFT)`: Initializes the contract, sets the Fragment and Artwork NFT contract addresses, and sets the owner.
2.  `setFragmentNFT(address _fragmentNFT)`: Sets/updates the Fragment NFT contract address (only callable by owner).
3.  `setArtworkNFT(address _artworkNFT)`: Sets/updates the Artwork NFT contract address (only callable by owner).
4.  `addFragmentType(uint256 _typeId, string memory _name, uint256 _maxSupply, uint256 _initialPropertiesSeed)`: Defines a new Fragment type with name, max supply, and a seed for potential initial properties (only callable by owner).
5.  `updateFragmentType(uint256 _typeId, string memory _name, uint256 _maxSupply, uint256 _initialPropertiesSeed)`: Updates an existing Fragment type's properties (only callable by owner).
6.  `removeFragmentType(uint256 _typeId)`: Removes a Fragment type definition (requires checking no existing tokens of that type) (only callable by owner).
7.  `setFusionCost(uint256 _cost)`: Sets the required native currency cost for performing a fusion (only callable by owner).
8.  `addSpecialFusionRule(uint256[] memory _fragmentTypeIds, uint256 _resultingArtworkTypeId, string memory _ruleDescription)`: Adds a rule defining that a specific combination of Fragment *types* (_fragmentTypeIds) yields a *special* Artwork type (_resultingArtworkTypeId) (only callable by owner).
9.  `updateSpecialFusionRule(uint256[] memory _fragmentTypeIds, uint256 _resultingArtworkTypeId, string memory _ruleDescription)`: Updates an existing special fusion rule (only callable by owner).
10. `removeSpecialFusionRule(uint256[] memory _fragmentTypeIds)`: Removes a special fusion rule based on the input fragment type combination (only callable by owner).
11. `adminMintFragments(uint256 _typeId, address[] memory _recipients, uint256[] memory _amounts)`: Mints initial Fragments of a specific type and distributes them to recipients (only callable by owner).
12. `withdrawFunds()`: Allows the owner to withdraw collected fusion fees (only callable by owner).
13. `pause()`: Pauses the contract, preventing fusion and other sensitive operations (only callable by owner).
14. `unpause()`: Unpauses the contract (only callable by owner).
15. `transferOwnership(address newOwner)`: Transfers ownership of the contract (standard Ownable function).
16. `renounceOwnership()`: Renounces ownership of the contract (standard Ownable function).

**User Functions:**

17. `fuseFragments(uint256[] memory _fragmentTokenIds)`: The core user function. Burns the specified Fragment tokens owned by the caller and mints a new Artwork token, paying the fusion cost.

**View Functions:**

18. `getFragmentType(uint256 _typeId)`: Returns details of a specific Fragment type.
19. `getFragmentTypes()`: Returns a list of all defined Fragment type IDs.
20. `getSpecialFusionRule(uint256[] memory _fragmentTypeIds)`: Returns details for a special fusion rule based on fragment types.
21. `getSpecialFusionRules()`: Returns a list of all defined special fusion rule fragment type combinations.
22. `getFusionCost()`: Returns the current cost to perform a fusion.
23. `canFuseFragments(uint256[] memory _fragmentTokenIds, address _owner)`: Checks if a given set of Fragment token IDs owned by `_owner` can be fused according to current rules and ownership checks (does not check balance/cost).
24. `getArtworkProperties(uint256 _artworkTokenId)`: Returns the on-chain generated properties for a specific Artwork token (requires Artwork contract to store this data).
25. `getFragmentOnchainProperties(uint256 _fragmentTokenId)`: Returns the on-chain properties for a specific Fragment token (requires Fragment contract to store this data).
26. `getFragmentSupply(uint256 _typeId)`: Returns the current minted supply for a specific Fragment type.
27. `getTotalFragmentsMinted()`: Returns the total number of Fragments ever minted across all types.
28. `getTotalArtworksMinted()`: Returns the total number of Artworks ever minted.
29. `isPaused()`: Returns the current pause status of the contract.
30. `getTokenOwner(address _nftContract, uint256 _tokenId)`: Helper view function to get the owner of an NFT (Fragment or Artwork) from its respective contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Define minimal interfaces for the external NFT contracts
interface IFragmentNFT is IERC721, IERC721Burnable {
    // Function to get on-chain properties of a Fragment token
    // Assume it stores a typeId and a uint256 seed/properties hash
    function getOnchainProperties(uint256 tokenId) external view returns (uint256 typeId, uint256 propertiesHash);
    function mint(address to, uint256 tokenId, uint256 typeId, uint256 propertiesHash) external;
    // Allow this contract to burn Fragments
    function burn(uint256 tokenId) external;
}

interface IArtworkNFT is IERC721 {
    // Function to get on-chain properties of an Artwork token
    // Assume it stores a typeId (if special rule applied) and a uint256 properties hash
    function getOnchainProperties(uint256 tokenId) external view returns (uint256 typeId, uint256 propertiesHash);
     function mint(address to, uint256 tokenId, uint256 typeId, uint256 propertiesHash) external;
}


contract DecentralizedArtFusion is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Address for address;

    // State Variables
    IFragmentNFT public fragmentNFT;
    IArtworkNFT public artworkNFT;

    uint256 public fusionCost; // Cost in native currency (ETH)

    // Fragment type definitions
    struct FragmentType {
        string name;
        uint256 maxSupply;
        uint256 mintedSupply;
        uint256 initialPropertiesSeed; // Seed for potential base properties
    }
    mapping(uint256 => FragmentType) public fragmentTypes;
    uint256[] public fragmentTypeIds; // To iterate over types

    // Special Fusion Rules
    // Key: Hash of sorted fragment type IDs involved in the rule
    struct SpecialFusionRule {
        uint256 resultingArtworkTypeId; // 0 for generic artwork
        string description;
    }
    mapping(bytes32 => SpecialFusionRule) public specialFusionRules;
    bytes32[] public specialFusionRuleKeys; // To iterate over rules

    Counters.Counter private _fragmentNonce;
    Counters.Counter private _artworkNonce;

    bool public paused;

    // Events
    event FragmentTypeAdded(uint256 indexed typeId, string name, uint256 maxSupply);
    event FragmentTypeUpdated(uint256 indexed typeId, string name, uint256 maxSupply);
    event FragmentTypeRemoved(uint256 indexed typeId);
    event SpecialFusionRuleAdded(bytes32 indexed ruleHash, uint256[] fragmentTypeIds, uint256 resultingArtworkTypeId);
    event SpecialFusionRuleUpdated(bytes32 indexed ruleHash, uint256[] fragmentTypeIds, uint256 resultingArtworkTypeId);
    event SpecialFusionRuleRemoved(bytes32 indexed ruleHash);
    event FusionCostUpdated(uint256 oldCost, uint256 newCost);
    event FragmentsMinted(uint256 indexed typeId, uint256 amount, address indexed recipient);
    event ArtworkFused(address indexed owner, uint256[] indexed fragmentTokenIds, uint256 indexed newArtworkTokenId);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _fragmentNFT, address _artworkNFT) Ownable(msg.sender) {
        require(_fragmentNFT.isContract(), "Fragment NFT address must be a contract");
        require(_artworkNFT.isContract(), "Artwork NFT address must be a contract");
        fragmentNFT = IFragmentNFT(_fragmentNFT);
        artworkNFT = IArtworkNFT(_artworkNFT);
        paused = false; // Initially not paused
        fusionCost = 0; // Default fusion cost is 0
    }

    // --- Admin/Owner Functions ---

    /// @notice Sets or updates the address of the Fragment NFT contract.
    /// @param _fragmentNFT The address of the IFragmentNFT contract.
    function setFragmentNFT(address _fragmentNFT) external onlyOwner {
        require(_fragmentNFT.isContract(), "Fragment NFT address must be a contract");
        fragmentNFT = IFragmentNFT(_fragmentNFT);
    }

    /// @notice Sets or updates the address of the Artwork NFT contract.
    /// @param _artworkNFT The address of the IArtworkNFT contract.
    function setArtworkNFT(address _artworkNFT) external onlyOwner {
        require(_artworkNFT.isContract(), "Artwork NFT address must be a contract");
        artworkNFT = IArtworkNFT(_artworkNFT);
    }

    /// @notice Defines a new type of Fragment.
    /// @param _typeId Unique identifier for the new Fragment type.
    /// @param _name Descriptive name for the type.
    /// @param _maxSupply Maximum number of tokens of this type that can ever exist.
    /// @param _initialPropertiesSeed A seed value for generating initial properties.
    function addFragmentType(uint256 _typeId, string memory _name, uint256 _maxSupply, uint256 _initialPropertiesSeed) external onlyOwner {
        require(fragmentTypes[_typeId].maxSupply == 0, "Fragment type already exists");
        require(_maxSupply > 0, "Max supply must be positive");

        fragmentTypes[_typeId] = FragmentType({
            name: _name,
            maxSupply: _maxSupply,
            mintedSupply: 0,
            initialPropertiesSeed: _initialPropertiesSeed
        });
        fragmentTypeIds.push(_typeId);
        emit FragmentTypeAdded(_typeId, _name, _maxSupply);
    }

    /// @notice Updates an existing Fragment type definition.
    /// @param _typeId Identifier of the Fragment type to update.
    /// @param _name New name for the type.
    /// @param _maxSupply New maximum number of tokens. Must be >= current minted supply.
    /// @param _initialPropertiesSeed New seed value.
    function updateFragmentType(uint256 _typeId, string memory _name, uint256 _maxSupply, uint256 _initialPropertiesSeed) external onlyOwner {
        FragmentType storage fType = fragmentTypes[_typeId];
        require(fType.maxSupply > 0, "Fragment type does not exist");
        require(_maxSupply >= fType.mintedSupply, "New max supply cannot be less than current minted supply");

        fType.name = _name;
        fType.maxSupply = _maxSupply;
        fType.initialPropertiesSeed = _initialPropertiesSeed;
        emit FragmentTypeUpdated(_typeId, _name, _maxSupply);
    }

    /// @notice Removes a Fragment type definition. Can only be done if no tokens of that type have been minted.
    /// @param _typeId Identifier of the Fragment type to remove.
    function removeFragmentType(uint256 _typeId) external onlyOwner {
        FragmentType storage fType = fragmentTypes[_typeId];
        require(fType.maxSupply > 0, "Fragment type does not exist");
        require(fType.mintedSupply == 0, "Cannot remove type with minted tokens");

        delete fragmentTypes[_typeId];
        // Remove from fragmentTypeIds array (basic implementation, inefficient for many types)
        for (uint i = 0; i < fragmentTypeIds.length; i++) {
            if (fragmentTypeIds[i] == _typeId) {
                fragmentTypeIds[i] = fragmentTypeIds[fragmentTypeIds.length - 1];
                fragmentTypeIds.pop();
                break;
            }
        }
        emit FragmentTypeRemoved(_typeId);
    }

    /// @notice Sets the cost in native currency (ETH) required to perform a fusion.
    /// @param _cost The new fusion cost in wei.
    function setFusionCost(uint256 _cost) external onlyOwner {
        uint256 oldCost = fusionCost;
        fusionCost = _cost;
        emit FusionCostUpdated(oldCost, fusionCost);
    }

    /// @notice Adds or updates a special rule for fusing specific Fragment types into a unique Artwork type.
    /// @param _fragmentTypeIds The sorted list of Fragment type IDs required for this rule.
    /// @param _resultingArtworkTypeId The unique type ID for the Artwork resulting from this fusion. Use 0 for generic.
    /// @param _ruleDescription A description of this rule (e.g., "Mythic Beast Fusion").
    function addSpecialFusionRule(uint256[] memory _fragmentTypeIds, uint256 _resultingArtworkTypeId, string memory _ruleDescription) external onlyOwner {
        require(_fragmentTypeIds.length > 1, "A special rule requires at least two fragment types");
        bytes32 ruleHash = keccak256(abi.encodePacked(_fragmentTypeIds)); // Hash of sorted types
        require(specialFusionRules[ruleHash].resultingArtworkTypeId == 0, "Special fusion rule already exists for these types");

        specialFusionRules[ruleHash] = SpecialFusionRule({
            resultingArtworkTypeId: _resultingArtworkTypeId,
            description: _ruleDescription
        });
         specialFusionRuleKeys.push(ruleHash); // Store key for iteration
        emit SpecialFusionRuleAdded(ruleHash, _fragmentTypeIds, _resultingArtworkTypeId);
    }

     /// @notice Updates an existing special fusion rule.
    /// @param _fragmentTypeIds The sorted list of Fragment type IDs for the rule to update.
    /// @param _resultingArtworkTypeId The new unique type ID for the Artwork.
    /// @param _ruleDescription The new description.
    function updateSpecialFusionRule(uint256[] memory _fragmentTypeIds, uint256 _resultingArtworkTypeId, string memory _ruleDescription) external onlyOwner {
        bytes32 ruleHash = keccak256(abi.encodePacked(_fragmentTypeIds));
        require(specialFusionRules[ruleHash].resultingArtworkTypeId != 0, "Special fusion rule does not exist for these types");

        specialFusionRules[ruleHash].resultingArtworkTypeId = _resultingArtworkTypeId;
        specialFusionRules[ruleHash].description = _ruleDescription;
        emit SpecialFusionRuleUpdated(ruleHash, _fragmentTypeIds, _resultingArtworkTypeId);
    }


    /// @notice Removes a special fusion rule.
    /// @param _fragmentTypeIds The sorted list of Fragment type IDs for the rule to remove.
    function removeSpecialFusionRule(uint256[] memory _fragmentTypeIds) external onlyOwner {
        bytes32 ruleHash = keccak256(abi.encodePacked(_fragmentTypeIds));
        require(specialFusionRules[ruleHash].resultingArtworkTypeId != 0, "Special fusion rule does not exist for these types");

        delete specialFusionRules[ruleHash];

        // Remove from specialFusionRuleKeys array (basic implementation)
         for (uint i = 0; i < specialFusionRuleKeys.length; i++) {
            if (specialFusionRuleKeys[i] == ruleHash) {
                specialFusionRuleKeys[i] = specialFusionRuleKeys[specialFusionRuleKeys.length - 1];
                specialFusionRuleKeys.pop();
                break;
            }
        }

        emit SpecialFusionRuleRemoved(ruleHash);
    }

    /// @notice Mints initial Fragments of a specific type and sends them to recipients. Limited by max supply.
    /// @param _typeId The type of Fragment to mint.
    /// @param _recipients The addresses to receive the minted tokens.
    /// @param _amounts The number of tokens to mint for each recipient (must match length of _recipients).
    function adminMintFragments(uint256 _typeId, address[] memory _recipients, uint256[] memory _amounts) external onlyOwner {
        require(_recipients.length == _amounts.length, "Recipient and amount arrays must match length");
        FragmentType storage fType = fragmentTypes[_typeId];
        require(fType.maxSupply > 0, "Fragment type does not exist");

        uint256 totalToMint = 0;
        for (uint i = 0; i < _amounts.length; i++) {
            totalToMint += _amounts[i];
        }

        require(fType.mintedSupply + totalToMint <= fType.maxSupply, "Exceeds max supply for this fragment type");

        fType.mintedSupply += totalToMint;

        uint256 initialSeed = fType.initialPropertiesSeed; // Use seed from type definition

        for (uint i = 0; i < _recipients.length; i++) {
            for (uint j = 0; j < _amounts[i]; j++) {
                _fragmentNonce.increment();
                uint256 newTokenId = _fragmentNonce.current();
                // Calculate a simple initial property hash based on seed, type, and token ID
                uint256 propertiesHash = uint256(keccak256(abi.encodePacked(initialSeed, _typeId, newTokenId)));
                fragmentNFT.mint(_recipients[i], newTokenId, _typeId, propertiesHash);
                emit FragmentsMinted(_typeId, 1, _recipients[i]);
            }
        }
    }

    /// @notice Allows the owner to withdraw accumulated native currency fees.
    function withdrawFunds() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
        emit FundsWithdrawn(owner(), balance);
    }

    /// @notice Pauses the contract, preventing fusion and other sensitive operations.
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- User Functions ---

    /// @notice Fuses a set of Fragment tokens owned by the caller into a new Artwork token.
    /// @param _fragmentTokenIds An array of token IDs of the Fragments to fuse.
    function fuseFragments(uint256[] memory _fragmentTokenIds) external payable nonReentrant whenNotPaused {
        require(_fragmentTokenIds.length > 1, "Fusion requires at least two fragments");
        require(msg.value >= fusionCost, "Insufficient fusion cost");

        // Transfer cost to the contract
        if (fusionCost > 0) {
             // msg.value is automatically transferred
        }

        // Verify ownership and get fragment type IDs
        uint256[] memory typeIds = new uint256[](_fragmentTokenIds.length);
        for (uint i = 0; i < _fragmentTokenIds.length; i++) {
            // Check ownership via external contract
            require(fragmentNFT.ownerOf(_fragmentTokenIds[i]) == msg.sender, "Caller must own all fragments");
            // Get type ID from external contract
            (uint256 fragmentTypeId, ) = fragmentNFT.getOnchainProperties(_fragmentTokenIds[i]);
            require(fragmentTypes[fragmentTypeId].maxSupply > 0, "Invalid fragment type"); // Ensure type is defined
            typeIds[i] = fragmentTypeId;
        }

        // Burn the fragments
        _burnFragments(_fragmentTokenIds);

        // Determine resulting artwork properties and type
        (uint256 newArtworkTypeId, uint256 newArtworkPropertiesHash) = _calculateArtworkProperties(typeIds, _fragmentTokenIds);

        // Mint the new artwork
        _artworkNonce.increment();
        uint256 newArtworkTokenId = _artworkNonce.current();
        artworkNFT.mint(msg.sender, newArtworkTokenId, newArtworkTypeId, newArtworkPropertiesHash);

        emit ArtworkFused(msg.sender, _fragmentTokenIds, newArtworkTokenId);
    }

    // --- View Functions ---

    /// @notice Returns the details of a specific Fragment type.
    /// @param _typeId The identifier of the Fragment type.
    /// @return name Name of the type.
    /// @return maxSupply Maximum number of tokens of this type.
    /// @return mintedSupply Number of tokens of this type currently minted.
    /// @return initialPropertiesSeed Seed value for initial properties.
    function getFragmentType(uint256 _typeId) external view returns (string memory name, uint256 maxSupply, uint256 mintedSupply, uint256 initialPropertiesSeed) {
        FragmentType storage fType = fragmentTypes[_typeId];
         require(fType.maxSupply > 0, "Fragment type does not exist"); // Check if type is defined
        return (fType.name, fType.maxSupply, fType.mintedSupply, fType.initialPropertiesSeed);
    }

    /// @notice Returns an array of all defined Fragment type IDs.
    /// @return An array of Fragment type identifiers.
    function getFragmentTypes() external view returns (uint256[] memory) {
        return fragmentTypeIds;
    }


    /// @notice Returns the details of a special fusion rule based on input fragment types.
    /// @param _fragmentTypeIds The sorted list of Fragment type IDs for the rule.
    /// @return resultingArtworkTypeId The unique type ID for the resulting Artwork (0 for generic).
    /// @return description Description of the rule.
    function getSpecialFusionRule(uint256[] memory _fragmentTypeIds) external view returns (uint256 resultingArtworkTypeId, string memory description) {
         require(_fragmentTypeIds.length > 1, "Special rule requires at least two fragment types");
         // It's crucial that the caller sorts the type IDs consistently before calling
        bytes32 ruleHash = keccak256(abi.encodePacked(_fragmentTypeIds));
        SpecialFusionRule storage rule = specialFusionRules[ruleHash];
        require(rule.resultingArtworkTypeId != 0, "Special fusion rule does not exist for these types");
        return (rule.resultingArtworkTypeId, rule.description);
    }

    /// @notice Returns an array of key hashes for all defined special fusion rules.
    /// Use `getSpecialFusionRule` with the corresponding fragment type IDs (requires re-sorting) to get details.
    /// @return An array of keccak256 hashes representing the sorted fragment type combinations.
     function getSpecialFusionRules() external view returns (bytes32[] memory) {
        return specialFusionRuleKeys;
    }


    /// @notice Returns the current cost in native currency (ETH) for performing a fusion.
    /// @return The fusion cost in wei.
    function getFusionCost() external view returns (uint256) {
        return fusionCost;
    }

     /// @notice Checks if a set of Fragment token IDs owned by `_owner` can be fused based on current rules.
     /// Does NOT check if the owner has enough ETH for the fusion cost.
     /// @param _fragmentTokenIds An array of token IDs of the Fragments to check.
     /// @param _owner The address that supposedly owns the tokens.
     /// @return bool True if the set of fragments can be fused by the owner.
     /// @return string A message indicating success or the reason for failure.
    function canFuseFragments(uint256[] memory _fragmentTokenIds, address _owner) external view returns (bool, string memory) {
        if (_fragmentTokenIds.length < 2) {
            return (false, "Fusion requires at least two fragments");
        }
        if (_owner == address(0)) {
             return (false, "Invalid owner address");
        }

        uint256[] memory typeIds = new uint256[](_fragmentTokenIds.length);
        for (uint i = 0; i < _fragmentTokenIds.length; i++) {
            // Check ownership via external contract
            try fragmentNFT.ownerOf(_fragmentTokenIds[i]) returns (address tokenOwner) {
                if (tokenOwner != _owner) {
                     return (false, string(abi.encodePacked("Fragment ", Strings.toString(_fragmentTokenIds[i]), " not owned by caller")));
                }
            } catch {
                 return (false, string(abi.encodePacked("Fragment ", Strings.toString(_fragmentTokenIds[i]), " does not exist")));
            }

            // Get type ID from external contract
            try fragmentNFT.getOnchainProperties(_fragmentTokenIds[i]) returns (uint256 fragmentTypeId, uint256 propertiesHash) {
                 if (fragmentTypes[fragmentTypeId].maxSupply == 0) { // Check if type is defined
                      return (false, string(abi.encodePacked("Fragment ", Strings.toString(_fragmentTokenIds[i]), " has invalid type")));
                 }
                 typeIds[i] = fragmentTypeId;
            } catch {
                 return (false, string(abi.encodePacked("Could not get properties for fragment ", Strings.toString(_fragmentTokenIds[i]))));
            }
        }

        // Check for special rules (requires sorting typeIds locally)
        uint256[] memory sortedTypeIds = new uint256[](typeIds.length);
        for(uint i = 0; i < typeIds.length; i++) sortedTypeIds[i] = typeIds[i];
        // Simple bubble sort for demonstration (inefficient for large arrays)
        for (uint i = 0; i < sortedTypeIds.length; i++) {
            for (uint j = 0; j < sortedTypeIds.length - i - 1; j++) {
                if (sortedTypeIds[j] > sortedTypeIds[j + 1]) {
                    uint temp = sortedTypeIds[j];
                    sortedTypeIds[j] = sortedTypeIds[j + 1];
                    sortedTypeIds[j + 1] = temp;
                }
            }
        }
        bytes32 ruleHash = keccak256(abi.encodePacked(sortedTypeIds));
        // If a special rule exists, it's fusable
        if (specialFusionRules[ruleHash].resultingArtworkTypeId != 0) {
            return (true, "Fusible (Special Rule)");
        }

        // If no special rule, check for a generic rule (e.g., any 2+ fragments?)
        // For this example, assume any combination of 2+ *valid* fragments can fuse generically
         return (true, "Fusible (Generic Rule)");
    }


    /// @notice Returns the on-chain generated properties for a specific Artwork token.
    /// Relies on the Artwork NFT contract storing and exposing this data.
    /// @param _artworkTokenId The ID of the Artwork token.
    /// @return typeId The Artwork type ID (0 for generic, non-zero for special rules).
    /// @return propertiesHash The calculated on-chain properties hash.
    function getArtworkProperties(uint256 _artworkTokenId) external view returns (uint256 typeId, uint256 propertiesHash) {
        // Check if token exists (ownerOf will revert if not)
        artworkNFT.ownerOf(_artworkTokenId);
        return artworkNFT.getOnchainProperties(_artworkTokenId);
    }

    /// @notice Returns the on-chain properties for a specific Fragment token.
    /// Relies on the Fragment NFT contract storing and exposing this data.
    /// @param _fragmentTokenId The ID of the Fragment token.
    /// @return typeId The Fragment type ID.
    /// @return propertiesHash The calculated on-chain properties hash.
    function getFragmentOnchainProperties(uint256 _fragmentTokenId) external view returns (uint256 typeId, uint256 propertiesHash) {
         // Check if token exists (ownerOf will revert if not)
        fragmentNFT.ownerOf(_fragmentTokenId);
        return fragmentNFT.getOnchainProperties(_fragmentTokenId);
    }

    /// @notice Returns the current minted supply for a specific Fragment type.
    /// @param _typeId The identifier of the Fragment type.
    /// @return The number of tokens minted for this type.
    function getFragmentSupply(uint256 _typeId) external view returns (uint256) {
        require(fragmentTypes[_typeId].maxSupply > 0, "Fragment type does not exist");
        return fragmentTypes[_typeId].mintedSupply;
    }

     /// @notice Returns the total number of Fragments ever minted across all types.
     /// @return The total number of minted Fragment tokens.
    function getTotalFragmentsMinted() external view returns (uint256) {
        return _fragmentNonce.current();
    }

    /// @notice Returns the total number of Artworks ever minted.
    /// @return The total number of minted Artwork tokens.
     function getTotalArtworksMinted() external view returns (uint256) {
        return _artworkNonce.current();
    }

    /// @notice Returns the current pause status of the contract.
    /// @return True if paused, false otherwise.
     function isPaused() external view returns (bool) {
        return paused;
     }

    /// @notice Helper view to get the owner of an NFT from its respective contract.
    /// @param _nftContract The address of the NFT contract (Fragment or Artwork).
    /// @param _tokenId The token ID.
    /// @return The owner address of the token.
    function getTokenOwner(address _nftContract, uint256 _tokenId) external view returns (address) {
        require(_nftContract == address(fragmentNFT) || _nftContract == address(artworkNFT), "Invalid NFT contract address");
        // ownerOf will revert if token does not exist
        return IERC721(_nftContract).ownerOf(_tokenId);
    }


    // --- Internal Helper Functions ---

    /// @dev Burns the specified Fragment tokens using the external Fragment NFT contract.
    /// Assumes ownership and validity checks have already passed.
    /// @param _fragmentTokenIds An array of token IDs to burn.
    function _burnFragments(uint256[] memory _fragmentTokenIds) internal {
        for (uint i = 0; i < _fragmentTokenIds.length; i++) {
            fragmentNFT.burn(_fragmentTokenIds[i]);
        }
    }

    /// @dev Deterministically calculates properties for the new Artwork token.
    /// This logic is crucial for the uniqueness and value of the artwork.
    /// @param _fragmentTypeIds The type IDs of the fragments used in fusion.
    /// @param _fragmentTokenIds The actual token IDs of the fragments used.
    /// @return resultingArtworkTypeId The type ID for the new Artwork (0 for generic, non-zero for special).
    /// @return propertiesHash The calculated on-chain properties hash for the new Artwork.
    function _calculateArtworkProperties(uint256[] memory _fragmentTypeIds, uint256[] memory _fragmentTokenIds) internal view returns (uint256 resultingArtworkTypeId, uint256 propertiesHash) {
        // Sort type IDs consistently to check against special rules
        uint256[] memory sortedTypeIds = new uint256[](_fragmentTypeIds.length);
        for(uint i = 0; i < _fragmentTypeIds.length; i++) sortedTypeIds[i] = _fragmentTypeIds[i];

        // Simple bubble sort (ok for small N fragments, replace with more efficient sort if needed)
        for (uint i = 0; i < sortedTypeIds.length; i++) {
            for (uint j = 0; j < sortedTypeIds.length - i - 1; j++) {
                if (sortedTypeIds[j] > sortedTypeIds[j + 1]) {
                    uint temp = sortedTypeIds[j];
                    sortedTypeIds[j] = sortedTypeIds[j + 1];
                    sortedTypeIds[j + 1] = temp;
                }
            }
        }

        bytes32 ruleHash = keccak256(abi.encodePacked(sortedTypeIds));
        SpecialFusionRule storage rule = specialFusionRules[ruleHash];

        // Check for special rule outcome
        resultingArtworkTypeId = rule.resultingArtworkTypeId; // Will be 0 if no special rule exists

        // --- On-chain Property Generation Logic ---
        // This is a critical creative part. Properties should be deterministic
        // based on inputs but ideally complex enough to be unique and interesting.

        // Combine inputs: fragment token IDs, fragment types, current block data
        bytes memory dataToHash = abi.encodePacked(
            _fragmentTokenIds,
            _fragmentTypeIds,
            block.number,
            block.timestamp,
            block.difficulty, // Using block.difficulty/coinbase is discouraged post-merge, but fine for properties hash example
            block.coinbase
        );

        // You could also incorporate:
        // - Properties from the fused fragments (requires getting them via fragmentNFT.getOnchainProperties)
        // - A base seed value (maybe from contract state or a block hash historical window)
        // - External data (if using an oracle, but adds complexity)

        propertiesHash = uint256(keccak256(dataToHash));

        // Further manipulate propertiesHash or derive multiple properties from it
        // Example: propertiesHash could be a seed for an off-chain generative art process,
        // or bits within the hash could represent traits (color, shape, etc.).

        // For example, if propertiesHash represents traits:
        // uint256 trait1 = propertiesHash % 100;
        // uint256 trait2 = (propertiesHash / 100) % 100;
        // ... and store/emit these or have the Artwork contract interpret the hash.

        // For this example, we'll just return the single hash.
         return (resultingArtworkTypeId, propertiesHash);
    }

    // The actual minting interaction with the Artwork NFT contract happens in `fuseFragments`

    // --- Optional: Add receive() or fallback() for ETH ---
    // If you want the contract to accept ETH outside of the fusion function, add this.
    receive() external payable {}
    fallback() external payable {}

    // --- Optional: ERC721Metadata/Enumerable functions in external contracts ---
    // Functions like tokenURI, totalSupply, tokenOfOwnerByIndex, etc., would
    // reside in the IFragmentNFT and IArtworkNFT contracts, not here.
    // Users would interact directly with those contracts for standard NFT operations.
}

```