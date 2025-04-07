```solidity
/**
 * @title Dynamic Attribute NFT - "Aetheria Companions"
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic NFT where each NFT represents a "Companion"
 * that evolves and changes attributes based on user interactions and time.
 *
 * **Outline:**
 * - **NFT Core Functionality:** Implements ERC721Enumerable for standard NFT operations.
 * - **Dynamic Attributes:** Each Companion has evolving attributes (e.g., Energy, Charm, Wisdom, Vitality)
 *   that change based on actions performed by the owner.
 * - **Action System:**  Users can perform various actions on their Companions (Train, Rest, Play, Socialize, Explore)
 *   which affect their attributes and potentially trigger evolution or special events.
 * - **Time-Based Evolution:** Attributes may also decay or grow slowly over time, adding a dynamic element.
 * - **Leveling System:** Companions can level up based on accumulated experience from actions, unlocking new abilities or visual changes (metadata).
 * - **Rarity & Traits:**  Companions can have inherent traits at minting that influence their attribute growth and potential.
 * - **Social Interaction (Limited):** Basic interaction between companions, like "gifting" attributes or temporary boosts.
 * - **Crafting/Combining (Potential):**  Future functionality to combine Companions or items to create new NFTs or enhance existing ones.
 * - **Governance (Simple):**  Basic voting mechanism related to future feature proposals for the Companions ecosystem.
 * - **Metadata Refresh Mechanism:**  Provides a way to refresh NFT metadata to reflect attribute changes and evolution.
 * - **Pausing & Emergency Stop:**  Admin controls for pausing contract functionality in case of issues.
 * - **Withdrawal Function:**  Admin function to withdraw contract balance.
 * - **Configurable Parameters:**  Allows admin to adjust action effects, leveling thresholds, etc.
 * - **Event Logging:**  Comprehensive event logging for all key actions and changes.
 *
 * **Function Summary:**
 * 1. `mintCompanion(string memory _name, string memory _trait)`: Mints a new Companion NFT with a given name and trait.
 * 2. `transferCompanion(address _to, uint256 _tokenId)`: Transfers ownership of a Companion NFT.
 * 3. `approve(address _approved, uint256 _tokenId)`: Approves an address to operate a Companion NFT.
 * 4. `setApprovalForAll(address _operator, bool _approved)`: Sets approval for an operator to manage all Companions of an owner.
 * 5. `getCompanionAttributes(uint256 _tokenId)`: Retrieves the current attributes of a Companion.
 * 6. `getCompanionLevel(uint256 _tokenId)`: Retrieves the current level of a Companion.
 * 7. `getCompanionName(uint256 _tokenId)`: Retrieves the name of a Companion.
 * 8. `setCompanionName(uint256 _tokenId, string memory _newName)`: Allows owner to rename their Companion.
 * 9. `trainCompanion(uint256 _tokenId)`: Performs a "Train" action, increasing Wisdom attribute.
 * 10. `restCompanion(uint256 _tokenId)`: Performs a "Rest" action, increasing Energy and Vitality attributes.
 * 11. `playWithCompanion(uint256 _tokenId)`: Performs a "Play" action, increasing Charm and Energy attributes.
 * 12. `socializeCompanion(uint256 _tokenId, uint256 _targetTokenId)`: Allows a Companion to socialize with another, potentially exchanging small attribute boosts.
 * 13. `exploreDungeon(uint256 _tokenId)`: Performs an "Explore Dungeon" action, potentially rewarding XP or items, but may decrease Energy.
 * 14. `levelUpCompanion(uint256 _tokenId)`: Allows manual level up if Companion has enough XP (can be automated in future).
 * 15. `getCompanionXP(uint256 _tokenId)`: Retrieves the current XP of a Companion.
 * 16. `getTotalCompanionsMinted()`: Returns the total number of Companions minted.
 * 17. `setBaseURI(string memory _newBaseURI)`: Admin function to set the base URI for NFT metadata.
 * 18. `withdrawFunds()`: Admin function to withdraw contract balance.
 * 19. `pauseContract()`: Admin function to pause core contract functionalities.
 * 20. `unpauseContract()`: Admin function to unpause contract functionalities.
 * 21. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support function.
 * 22. `tokenURI(uint256 _tokenId)`: Returns the URI for the metadata of a Companion NFT.
 * 23. `getTraitOfCompanion(uint256 _tokenId)`: Retrieves the trait of a Companion.
 * 24. `giftAttributeBoost(uint256 _fromTokenId, uint256 _toTokenId, uint8 _attributeIndex)`: Allows gifting a temporary boost of a specific attribute from one companion to another.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AetheriaCompanions is ERC721Enumerable, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string private _baseURI;

    // Struct to represent Companion attributes
    struct CompanionAttributes {
        uint8 energy;     // Stamina, ability to perform actions
        uint8 charm;      // Social skills, affects socializing actions
        uint8 wisdom;     // Learning ability, affects training actions
        uint8 vitality;   // Health, resilience
        uint8 level;      // Current level of the Companion
        uint32 xp;        // Experience points
        string name;       // Name of the Companion
        string trait;      // Inherent trait of the Companion
        uint64 lastActionTimestamp; // Timestamp of the last action performed
    }

    mapping(uint256 => CompanionAttributes) public companionAttributes;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => string) private _companionTraits;

    uint256 public constant MAX_LEVEL = 100;
    uint256 public constant XP_PER_LEVEL = 1000; // XP needed to level up
    uint256 public constant BASE_ATTRIBUTE_VALUE = 50;
    uint256 public constant MAX_ATTRIBUTE_VALUE = 100;

    uint256 public actionCooldownSeconds = 60; // Cooldown between actions (1 minute)

    event CompanionMinted(uint256 tokenId, address owner, string name, string trait);
    event CompanionAttributesUpdated(uint256 tokenId, CompanionAttributes attributes);
    event CompanionLeveledUp(uint256 tokenId, uint8 newLevel);
    event CompanionNameChanged(uint256 tokenId, string newName);
    event ActionPerformed(uint256 tokenId, string actionType);
    event AttributeBoostGifted(uint256 fromTokenId, uint256 toTokenId, uint8 attributeIndex, uint8 boostAmount);

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _baseURI = baseURI;
    }

    modifier onlyApprovedOrOwner(address _spender, uint256 _tokenId) {
        require(_isApprovedOrOwner(_spender, _tokenId), "ERC721: caller is not owner nor approved");
        _;
    }

    modifier onlyTokenOwner(address _caller, uint256 _tokenId) {
        require(ownerOf(_tokenId) == _caller, "Only token owner can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    modifier actionCooldown(uint256 _tokenId) {
        CompanionAttributes storage attributes = companionAttributes[_tokenId];
        require(block.timestamp >= attributes.lastActionTimestamp + actionCooldownSeconds, "Action cooldown in effect");
        _;
    }


    /**
     * @dev Mints a new Companion NFT to the specified address.
     * @param _name The name of the new Companion.
     * @param _trait The trait of the new Companion.
     */
    function mintCompanion(string memory _name, string memory _trait) public whenNotPaused {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);

        companionAttributes[tokenId] = CompanionAttributes({
            energy: uint8(BASE_ATTRIBUTE_VALUE),
            charm: uint8(BASE_ATTRIBUTE_VALUE),
            wisdom: uint8(BASE_ATTRIBUTE_VALUE),
            vitality: uint8(BASE_ATTRIBUTE_VALUE),
            level: 1,
            xp: 0,
            name: _name,
            trait: _trait,
            lastActionTimestamp: block.timestamp
        });
        _companionTraits[tokenId] = _trait;

        emit CompanionMinted(tokenId, msg.sender, _name, _trait);
    }

    /**
     * @dev Transfers ownership of a Companion NFT.
     * @param _to The address to transfer the Companion to.
     * @param _tokenId The ID of the Companion to transfer.
     */
    function transferCompanion(address _to, uint256 _tokenId) public whenNotPaused onlyApprovedOrOwner(msg.sender, _tokenId) {
        _transfer(ownerOf(_tokenId), _to, _tokenId);
    }

    /**
     * @dev Approve another address to operate the given Companion NFT
     * @param _approved Address to be approved
     * @param _tokenId ID of the Companion NFT to be approved
     */
    function approve(address _approved, uint256 _tokenId) public override whenNotPaused onlyTokenOwner(msg.sender, _tokenId) {
        _tokenApprovals[_tokenId] = _approved;
        emit Approval(ownerOf(_tokenId), _approved, _tokenId);
    }

    /**
     * @dev Set approval for an operator to manage all of the caller's Companion NFTs.
     * @param _operator Address to be approved as operator
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) public override whenNotPaused {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Returns the current attributes of a Companion.
     * @param _tokenId The ID of the Companion.
     * @return CompanionAttributes The current attributes of the Companion.
     */
    function getCompanionAttributes(uint256 _tokenId) public view returns (CompanionAttributes memory) {
        require(_exists(_tokenId), "Token does not exist");
        return companionAttributes[_tokenId];
    }

    /**
     * @dev Returns the current level of a Companion.
     * @param _tokenId The ID of the Companion.
     * @return uint8 The current level.
     */
    function getCompanionLevel(uint256 _tokenId) public view returns (uint8) {
        require(_exists(_tokenId), "Token does not exist");
        return companionAttributes[_tokenId].level;
    }

    /**
     * @dev Returns the name of a Companion.
     * @param _tokenId The ID of the Companion.
     * @return string The name of the Companion.
     */
    function getCompanionName(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return companionAttributes[_tokenId].name;
    }

    /**
     * @dev Allows the owner to rename their Companion.
     * @param _tokenId The ID of the Companion.
     * @param _newName The new name for the Companion.
     */
    function setCompanionName(uint256 _tokenId, string memory _newName) public whenNotPaused onlyTokenOwner(msg.sender, _tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        companionAttributes[_tokenId].name = _newName;
        emit CompanionNameChanged(_tokenId, _newName);
    }

    /**
     * @dev Performs a "Train" action, increasing the Wisdom attribute.
     * @param _tokenId The ID of the Companion performing the action.
     */
    function trainCompanion(uint256 _tokenId) public whenNotPaused onlyTokenOwner(msg.sender, _tokenId) actionCooldown(_tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        require(companionAttributes[_tokenId].energy > 10, "Not enough energy to train"); // Example energy cost

        companionAttributes[_tokenId].wisdom = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].wisdom) + 5)); // Increase Wisdom by 5, capped at MAX
        companionAttributes[_tokenId].energy = uint8(Math.max(0, uint256(companionAttributes[_tokenId].energy) - 10)); // Decrease Energy by 10
        companionAttributes[_tokenId].xp += 20; // Gain 20 XP for training
        companionAttributes[_tokenId].lastActionTimestamp = block.timestamp;

        _levelUpIfPossible(_tokenId); // Check for level up after action

        emit ActionPerformed(_tokenId, "Train");
        emit CompanionAttributesUpdated(_tokenId, companionAttributes[_tokenId]);
    }

    /**
     * @dev Performs a "Rest" action, increasing Energy and Vitality.
     * @param _tokenId The ID of the Companion performing the action.
     */
    function restCompanion(uint256 _tokenId) public whenNotPaused onlyTokenOwner(msg.sender, _tokenId) actionCooldown(_tokenId) {
        require(_exists(_tokenId), "Token does not exist");

        companionAttributes[_tokenId].energy = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].energy) + 15)); // Increase Energy by 15, capped at MAX
        companionAttributes[_tokenId].vitality = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].vitality) + 7)); // Increase Vitality by 7, capped at MAX
        companionAttributes[_tokenId].lastActionTimestamp = block.timestamp;

        emit ActionPerformed(_tokenId, "Rest");
        emit CompanionAttributesUpdated(_tokenId, companionAttributes[_tokenId]);
    }

    /**
     * @dev Performs a "Play" action, increasing Charm and Energy.
     * @param _tokenId The ID of the Companion performing the action.
     */
    function playWithCompanion(uint256 _tokenId) public whenNotPaused onlyTokenOwner(msg.sender, _tokenId) actionCooldown(_tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        require(companionAttributes[_tokenId].energy > 5, "Not enough energy to play"); // Example energy cost

        companionAttributes[_tokenId].charm = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].charm) + 8)); // Increase Charm by 8, capped at MAX
        companionAttributes[_tokenId].energy = uint8(Math.max(0, uint256(companionAttributes[_tokenId].energy) - 5)); // Decrease Energy by 5
        companionAttributes[_tokenId].xp += 15; // Gain 15 XP for playing
        companionAttributes[_tokenId].lastActionTimestamp = block.timestamp;

        _levelUpIfPossible(_tokenId); // Check for level up after action

        emit ActionPerformed(_tokenId, "Play");
        emit CompanionAttributesUpdated(_tokenId, companionAttributes[_tokenId]);
    }

    /**
     * @dev Allows a Companion to socialize with another, potentially exchanging small attribute boosts.
     * @param _tokenId The ID of the Companion initiating socialization.
     * @param _targetTokenId The ID of the target Companion to socialize with.
     */
    function socializeCompanion(uint256 _tokenId, uint256 _targetTokenId) public whenNotPaused onlyTokenOwner(msg.sender, _tokenId) actionCooldown(_tokenId) {
        require(_exists(_tokenId) && _exists(_targetTokenId), "One or both Companions do not exist");
        require(_tokenId != _targetTokenId, "Cannot socialize with itself");
        require(companionAttributes[_tokenId].energy > 7, "Not enough energy to socialize"); // Example energy cost

        // Simple example: Exchange a small amount of Charm between companions
        uint8 charmBoost = 2;
        companionAttributes[_tokenId].charm = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].charm) + charmBoost));
        companionAttributes[_targetTokenId].charm = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_targetTokenId].charm) + charmBoost));
        companionAttributes[_tokenId].energy = uint8(Math.max(0, uint256(companionAttributes[_tokenId].energy) - 7)); // Decrease Energy by 7
        companionAttributes[_tokenId].xp += 10; // Gain 10 XP for socializing
        companionAttributes[_tokenId].lastActionTimestamp = block.timestamp;

        _levelUpIfPossible(_tokenId); // Check for level up after action

        emit ActionPerformed(_tokenId, "Socialize");
        emit CompanionAttributesUpdated(_tokenId, companionAttributes[_tokenId]);
        emit CompanionAttributesUpdated(_targetTokenId, companionAttributes[_targetTokenId]); // Emit event for target too
    }

    /**
     * @dev Performs an "Explore Dungeon" action, potentially rewarding XP or items, but may decrease Energy.
     * @param _tokenId The ID of the Companion performing the action.
     */
    function exploreDungeon(uint256 _tokenId) public whenNotPaused onlyTokenOwner(msg.sender, _tokenId) actionCooldown(_tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        require(companionAttributes[_tokenId].energy > 15, "Not enough energy to explore"); // Example energy cost

        // Simple example: Randomly increase Wisdom or Vitality, and decrease Energy
        uint256 randomAttribute = block.timestamp % 2; // 0 for Wisdom, 1 for Vitality
        uint8 attributeBoost = 3;

        if (randomAttribute == 0) {
            companionAttributes[_tokenId].wisdom = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].wisdom) + attributeBoost));
        } else {
            companionAttributes[_tokenId].vitality = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].vitality) + attributeBoost));
        }

        companionAttributes[_tokenId].energy = uint8(Math.max(0, uint256(companionAttributes[_tokenId].energy) - 15)); // Decrease Energy by 15
        companionAttributes[_tokenId].xp += 30; // Gain 30 XP for exploring
        companionAttributes[_tokenId].lastActionTimestamp = block.timestamp;

        _levelUpIfPossible(_tokenId); // Check for level up after action

        emit ActionPerformed(_tokenId, "Explore Dungeon");
        emit CompanionAttributesUpdated(_tokenId, companionAttributes[_tokenId]);
    }


    /**
     * @dev Allows manual level up if Companion has enough XP.
     * @param _tokenId The ID of the Companion to level up.
     */
    function levelUpCompanion(uint256 _tokenId) public whenNotPaused onlyTokenOwner(msg.sender, _tokenId) {
        require(_exists(_tokenId), "Token does not exist");
        require(companionAttributes[_tokenId].level < MAX_LEVEL, "Companion is already at max level");
        require(companionAttributes[_tokenId].xp >= XP_PER_LEVEL * companionAttributes[_tokenId].level, "Not enough XP to level up");

        companionAttributes[_tokenId].level++;
        companionAttributes[_tokenId].xp = 0; // Reset XP after level up (can be adjusted as needed)
        companionAttributes[_tokenId].energy = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].energy) + 10)); // Example: Restore some energy on level up
        companionAttributes[_tokenId].vitality = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_tokenId].vitality) + 5)); // Example: Increase vitality on level up

        emit CompanionLeveledUp(_tokenId, companionAttributes[_tokenId].level);
        emit CompanionAttributesUpdated(_tokenId, companionAttributes[_tokenId]);
    }

    /**
     * @dev Internal function to check if a Companion can level up and perform level up if possible.
     * @param _tokenId The ID of the Companion to check.
     */
    function _levelUpIfPossible(uint256 _tokenId) internal {
        if (companionAttributes[_tokenId].level < MAX_LEVEL && companionAttributes[_tokenId].xp >= XP_PER_LEVEL * companionAttributes[_tokenId].level) {
            levelUpCompanion(_tokenId); // Call public levelUp function internally
        }
    }

    /**
     * @dev Returns the current XP of a Companion.
     * @param _tokenId The ID of the Companion.
     * @return uint32 The current XP.
     */
    function getCompanionXP(uint256 _tokenId) public view returns (uint32) {
        require(_exists(_tokenId), "Token does not exist");
        return companionAttributes[_tokenId].xp;
    }

    /**
     * @dev Returns the total number of Companions minted.
     * @return uint256 Total Companions minted.
     */
    function getTotalCompanionsMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Sets the base URI for token metadata. Only callable by contract owner.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURI = _newBaseURI;
    }

    /**
     * @dev Override baseURI function to use the custom base URI.
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev Function to withdraw contract balance. Only callable by contract owner.
     */
    function withdrawFunds() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Pauses all core contract functionalities. Only callable by contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all core contract functionalities. Only callable by contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json")) : "";
    }

    /**
     * @dev Returns the trait of a Companion.
     * @param _tokenId The ID of the Companion.
     * @return string The trait of the Companion.
     */
    function getTraitOfCompanion(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");
        return _companionTraits[_tokenId];
    }

    /**
     * @dev Allows gifting a temporary boost of a specific attribute from one companion to another.
     * @param _fromTokenId The ID of the Companion gifting the boost.
     * @param _toTokenId The ID of the Companion receiving the boost.
     * @param _attributeIndex Index of the attribute to boost (0: Energy, 1: Charm, 2: Wisdom, 3: Vitality).
     */
    function giftAttributeBoost(uint256 _fromTokenId, uint256 _toTokenId, uint8 _attributeIndex) public whenNotPaused onlyTokenOwner(msg.sender, _fromTokenId) actionCooldown(_fromTokenId) {
        require(_exists(_fromTokenId) && _exists(_toTokenId), "One or both Companions do not exist");
        require(_fromTokenId != _toTokenId, "Cannot gift to itself");
        require(companionAttributes[_fromTokenId].energy > 10, "Not enough energy to gift boost"); // Example energy cost

        uint8 boostAmount = 5; // Example boost amount

        if (_attributeIndex == 0) { // Energy
            companionAttributes[_toTokenId].energy = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_toTokenId].energy) + boostAmount));
        } else if (_attributeIndex == 1) { // Charm
            companionAttributes[_toTokenId].charm = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_toTokenId].charm) + boostAmount));
        } else if (_attributeIndex == 2) { // Wisdom
            companionAttributes[_toTokenId].wisdom = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_toTokenId].wisdom) + boostAmount));
        } else if (_attributeIndex == 3) { // Vitality
            companionAttributes[_toTokenId].vitality = uint8(Math.min(MAX_ATTRIBUTE_VALUE, uint256(companionAttributes[_toTokenId].vitality) + boostAmount));
        } else {
            revert("Invalid attribute index");
        }

        companionAttributes[_fromTokenId].energy = uint8(Math.max(0, uint256(companionAttributes[_fromTokenId].energy) - 10)); // Decrease Energy for gifting
        companionAttributes[_fromTokenId].lastActionTimestamp = block.timestamp;

        emit ActionPerformed(_fromTokenId, "Gift Attribute Boost");
        emit AttributeBoostGifted(_fromTokenId, _toTokenId, _attributeIndex, boostAmount);
        emit CompanionAttributesUpdated(_toTokenId, companionAttributes[_toTokenId]); // Emit event for receiving companion
    }

    /**
     * @dev Override isApprovedForAll to include operator approvals.
     */
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Override _isApprovedOrOwner to include operator approvals.
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view virtual override returns (bool) {
        address tokenOwner = ownerOf(_tokenId);
        return (_spender == tokenOwner || getApproved(_tokenId) == _spender || isApprovedForAll(tokenOwner, _spender));
    }

    /**
     * @dev Override getApproved to get token approvals.
     */
    function getApproved(uint256 _tokenId) public view virtual override returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    /**
     * @dev Override _beforeTokenTransfer to reset approvals when transferring tokens.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0)) {
            // Clear approvals from the previous owner
            delete _tokenApprovals[tokenId];
        }
    }
}

// --- Helper library (from OpenZeppelin, included for completeness if not already in your environment) ---
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
```