```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution & Attribute System
 * @author Gemini AI (Conceptual Contract - Do not deploy directly to production)
 * @dev This contract implements a dynamic NFT system where NFTs can evolve through stages,
 * acquire attributes based on various in-contract actions and external influences (simulated here).
 * It features a complex attribute system, evolution mechanics, crafting, social interaction,
 * decentralized governance over evolution paths, and more.
 *
 * **Outline & Function Summary:**
 *
 * **Core NFT Functionality (ERC721-like with extensions):**
 * 1. `mintNFT(address _to, string memory _baseURI)`: Mints a new NFT to the specified address with initial stage and attributes.
 * 2. `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT from one address to another.
 * 3. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
 * 4. `balanceOf(address _owner)`: Returns the number of NFTs owned by an address.
 * 5. `tokenURI(uint256 _tokenId)`: Returns the dynamic metadata URI for an NFT, reflecting its current stage and attributes.
 * 6. `approve(address _approved, uint256 _tokenId)`: Approves an address to transfer a specific NFT.
 * 7. `getApproved(uint256 _tokenId)`: Gets the approved address for a specific NFT.
 * 8. `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for all of an owner's NFTs.
 * 9. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all of an owner's NFTs.
 *
 * **Dynamic Evolution & Stage Management:**
 * 10. `getNFTStage(uint256 _tokenId)`: Returns the current evolution stage of an NFT.
 * 11. `evolveNFT(uint256 _tokenId)`: Attempts to evolve an NFT to the next stage, based on criteria.
 * 12. `setEvolutionCriteria(uint256 _stage, string memory _criteria)`: (Admin) Sets the evolution criteria for a specific stage.
 * 13. `getEvolutionCriteria(uint256 _stage)`: Returns the evolution criteria for a specific stage.
 * 14. `manualEvolveNFT(uint256 _tokenId)`: (Admin) Manually forces an NFT to evolve to the next stage (for testing/emergencies).
 *
 * **Attribute System & Management:**
 * 15. `getNFTAttributes(uint256 _tokenId)`: Returns all attributes of an NFT as a string (or structured data in a real implementation).
 * 16. `setAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue)`:  Sets a specific attribute for an NFT.
 * 17. `applyEnvironmentalEffect(uint256 _tokenId, string memory _effect)`: Simulates applying environmental effects that modify NFT attributes.
 * 18. `learnSkill(uint256 _tokenId, string memory _skillName)`:  Allows NFTs to "learn" new skills, adding to their attributes.
 * 19. `resetNFTAttributes(uint256 _tokenId)`: (Admin) Resets all attributes of an NFT to default values.
 *
 * **Social Interaction & Community Features (Conceptual):**
 * 20. `interactNFTs(uint256 _tokenId1, uint256 _tokenId2, string memory _interactionType)`: Simulates interactions between two NFTs, potentially affecting their attributes.
 * 21. `communityVoteForEvolutionPath(uint256 _tokenId, uint256 _nextStage)`: (Conceptual - DAO integration needed) Allows community voting on future evolution paths for specific NFTs.
 *
 * **Admin & Utility Functions:**
 * 22. `setBaseMetadataURI(string memory _newBaseURI)`: (Admin) Sets the base URI for NFT metadata.
 * 23. `pauseContract()`: (Admin) Pauses core contract functionalities.
 * 24. `unpauseContract()`: (Admin) Resumes paused contract functionalities.
 * 25. `withdrawContractBalance()`: (Admin) Allows the contract owner to withdraw any accumulated ETH balance.
 */
contract DynamicNFTEvolution {
    // --- State Variables ---

    string public name = "DynamicEvolverNFT";
    string public symbol = "DYNFT";
    string public baseMetadataURI; // Base URI for metadata
    uint256 public totalSupply;
    uint256 public nextTokenId = 1;
    address public admin;
    bool public paused = false;

    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    // NFT Stage and Evolution
    mapping(uint256 => uint256) public nftStage; // TokenId => Stage (e.g., 1, 2, 3...)
    mapping(uint256 => string) public evolutionCriteria; // Stage => Criteria description

    // NFT Attributes - Stored as simple strings for this example, can be more complex struct in real app
    mapping(uint256 => mapping(string => string)) public nftAttributes; // TokenId => AttributeName => AttributeValue


    // --- Events ---
    event NFTMinted(address to, uint256 tokenId);
    event NFTTransferred(address from, address to, uint256 tokenId);
    event NFTApproved(address owner, address approved, uint256 tokenId);
    event ApprovalForAll(address owner, address operator, bool approved);
    event NFTEvolved(uint256 tokenId, uint256 fromStage, uint256 toStage);
    event NFTAttributeSet(uint256 tokenId, string attributeName, string attributeValue);
    event EnvironmentalEffectApplied(uint256 tokenId, string effect);
    event SkillLearned(uint256 tokenId, string skillName);


    // --- Modifiers ---
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "Not the owner of this NFT");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }


    // --- Constructor ---
    constructor(string memory _baseURI) {
        admin = msg.sender;
        baseMetadataURI = _baseURI;
    }

    // --- Core NFT Functions ---

    /**
     * @dev Mints a new NFT to the specified address.
     * @param _to The address to mint the NFT to.
     * @param _baseURI Base URI to use for the NFT's metadata
     */
    function mintNFT(address _to, string memory _baseURI) public whenNotPaused returns (uint256) {
        require(_to != address(0), "Mint to the zero address");

        uint256 tokenId = nextTokenId++;
        tokenOwner[tokenId] = _to;
        ownerTokenCount[_to]++;
        totalSupply++;
        nftStage[tokenId] = 1; // Initial Stage
        baseMetadataURI = _baseURI; // Set base URI on mint (can be improved for dynamic base URI per NFT batch)

        // Initialize default attributes for Stage 1 NFTs (example)
        setAttribute(tokenId, "Rarity", "Common");
        setAttribute(tokenId, "Generation", "1");
        setAttribute(tokenId, "Element", "Neutral");

        emit NFTMinted(_to, tokenId);
        return tokenId;
    }

    /**
     * @dev Transfers an NFT from one address to another.
     * @param _from The current owner of the NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_to != address(0), "Transfer to the zero address");
        require(tokenOwner[_tokenId] == _from, "Not the owner of this NFT");

        require(msg.sender == _from || getApproved(_tokenId) == msg.sender || isApprovedForAll(_from, msg.sender), "Transfer caller is not owner nor approved");

        _clearApproval(_tokenId);

        ownerTokenCount[_from]--;
        ownerTokenCount[_to]++;
        tokenOwner[_tokenId] = _to;

        emit NFTTransferred(_from, _to, _tokenId);
    }

    /**
     * @dev Returns the owner of a given NFT.
     * @param _tokenId The ID of the NFT to query.
     * @return The address of the owner of the NFT.
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0), "Invalid token ID");
        return owner;
    }

    /**
     * @dev Returns the number of NFTs owned by an address.
     * @param _owner The address to query.
     * @return The number of NFTs owned by the address.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "Balance query for the zero address");
        return ownerTokenCount[_owner];
    }

    /**
     * @dev Returns the dynamic metadata URI for an NFT, reflecting its current stage and attributes.
     * @param _tokenId The ID of the NFT to query.
     * @return The URI string for the NFT metadata.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        // In a real application, this would dynamically generate a URI based on:
        // - baseMetadataURI
        // - tokenId
        // - nftStage[_tokenId]
        // - nftAttributes[_tokenId]
        // For simplicity, we'll return a placeholder URI that indicates stage and attributes.
        return string(abi.encodePacked(baseMetadataURI, "/", uint2str(nftStage[_tokenId]), "/", getNFTAttributes(_tokenId), ".json"));
    }

    /**
     * @dev Approve another address to transfer the given NFT ID
     * @param _approved Address to be approved
     * @param _tokenId NFT ID to be approved
     */
    function approve(address _approved, uint256 _tokenId) public whenNotPaused onlyOwnerOf(_tokenId) {
        tokenApprovals[_tokenId] = _approved;
        emit NFTApproved(msg.sender, _approved, _tokenId);
    }

    /**
     * @dev Get the approved address for a given NFT ID, if any
     * @param _tokenId NFT ID to query the approval of
     * @return Address that NFT ID is approved for, or zero address if not approved
     */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
     * @dev Set or unset the approval of a given operator to transfer all NFTs of msg.sender
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) public whenNotPaused {
        require(_operator != msg.sender, "Approve to caller");
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if the operator is approved for all tokens of the owner, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

    function _clearApproval(uint256 _tokenId) private {
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }
    }


    // --- Dynamic Evolution & Stage Management ---

    /**
     * @dev Returns the current evolution stage of an NFT.
     * @param _tokenId The ID of the NFT to query.
     * @return The current evolution stage (e.g., 1, 2, 3...).
     */
    function getNFTStage(uint256 _tokenId) public view returns (uint256) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        return nftStage[_tokenId];
    }

    /**
     * @dev Attempts to evolve an NFT to the next stage based on predefined criteria.
     *  In this simplified example, evolution is just time-based (simplified criteria).
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public whenNotPaused onlyOwnerOf(_tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        uint256 currentStage = nftStage[_tokenId];
        uint256 nextStage = currentStage + 1;

        // --- Simplified Evolution Criteria Example ---
        // In a real application, criteria could be complex, involving:
        // - Time passed since last evolution
        // - In-game actions (e.g., battles, quests)
        // - Resource accumulation
        // - Community voting
        // - Oracle data (e.g., weather conditions)

        string memory criteria = evolutionCriteria[currentStage];
        if (bytes(criteria).length == 0) {
             criteria = "Default evolution criteria: Time Passed"; // Default criteria if none set for stage
        }

        // Placeholder for criteria check -  For this example, always evolve (REMOVE in real app)
        // In a real application, implement logic to check criteria and determine if evolution is possible.
        bool canEvolve = true; // Placeholder - Replace with actual criteria check logic

        if (canEvolve) {
            nftStage[_tokenId] = nextStage;
            // Update attributes upon evolution (example - can be more complex)
            setAttribute(_tokenId, "Stage", uint2str(nextStage));
            setAttribute(_tokenId, "Power", uint2str(parseInt(nftAttributes[_tokenId]["Power"]) + 10)); // Example: Increase power

            emit NFTEvolved(_tokenId, currentStage, nextStage);
        } else {
            revert("Evolution criteria not met yet."); // Or return false/error code in a real app
        }
    }

    /**
     * @dev (Admin) Sets the evolution criteria for a specific stage.
     * @param _stage The stage number to set criteria for.
     * @param _criteria A description of the evolution criteria (can be more structured in real app).
     */
    function setEvolutionCriteria(uint256 _stage, string memory _criteria) public onlyAdmin {
        evolutionCriteria[_stage] = _criteria;
    }

    /**
     * @dev Returns the evolution criteria for a specific stage.
     * @param _stage The stage number to query.
     * @return A string describing the evolution criteria.
     */
    function getEvolutionCriteria(uint256 _stage) public view returns (string memory) {
        return evolutionCriteria[_stage];
    }

    /**
     * @dev (Admin) Manually forces an NFT to evolve to the next stage (for testing or emergency situations).
     * @param _tokenId The ID of the NFT to manually evolve.
     */
    function manualEvolveNFT(uint256 _tokenId) public onlyAdmin {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        uint256 currentStage = nftStage[_tokenId];
        uint256 nextStage = currentStage + 1;
        nftStage[_tokenId] = nextStage;
        emit NFTEvolved(_tokenId, currentStage, nextStage);
    }


    // --- Attribute System & Management ---

    /**
     * @dev Returns all attributes of an NFT as a string (for simplicity in this example).
     *  In a real application, consider returning a struct or mapping for structured data.
     * @param _tokenId The ID of the NFT to query.
     * @return A string representing all attributes (e.g., "Rarity:Rare, Power:120, Element:Fire").
     */
    function getNFTAttributes(uint256 _tokenId) public view returns (string memory) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        string memory attributesString = "";
        string memory rarity = nftAttributes[_tokenId]["Rarity"];
        string memory generation = nftAttributes[_tokenId]["Generation"];
        string memory element = nftAttributes[_tokenId]["Element"];
        string memory stage = nftAttributes[_tokenId]["Stage"];
        string memory power = nftAttributes[_tokenId]["Power"];

        if (bytes(rarity).length > 0) attributesString = string(abi.encodePacked(attributesString, "Rarity:", rarity, ", "));
        if (bytes(generation).length > 0) attributesString = string(abi.encodePacked(attributesString, "Generation:", generation, ", "));
        if (bytes(element).length > 0) attributesString = string(abi.encodePacked(attributesString, "Element:", element, ", "));
        if (bytes(stage).length > 0) attributesString = string(abi.encodePacked(attributesString, "Stage:", stage, ", "));
        if (bytes(power).length > 0) attributesString = string(abi.encodePacked(attributesString, "Power:", power, ", "));

        if (bytes(attributesString).length > 2) {
            // Remove trailing ", " if attributes exist
            attributesString = substring(attributesString, 0, bytes(attributesString).length - 2);
        }
        return attributesString;
    }

    /**
     * @dev Sets a specific attribute for an NFT.
     * @param _tokenId The ID of the NFT to modify.
     * @param _attributeName The name of the attribute (e.g., "Power", "Speed").
     * @param _attributeValue The value of the attribute (e.g., "150", "Fast").
     */
    function setAttribute(uint256 _tokenId, string memory _attributeName, string memory _attributeValue) public onlyOwnerOf(_tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        nftAttributes[_tokenId][_attributeName] = _attributeValue;
        emit NFTAttributeSet(_tokenId, _attributeName, _attributeValue);
    }

    /**
     * @dev Simulates applying environmental effects that can modify NFT attributes.
     *  Example effects: "Rain", "Sunlight", "Volcanic Eruption".
     * @param _tokenId The ID of the NFT to apply the effect to.
     * @param _effect A string representing the environmental effect.
     */
    function applyEnvironmentalEffect(uint256 _tokenId, string memory _effect) public whenNotPaused {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");

        string memory currentElement = nftAttributes[_tokenId]["Element"];

        if (keccak256(bytes(_effect)) == keccak256(bytes("Rain"))) {
            if (keccak256(bytes(currentElement)) == keccak256(bytes("Fire"))) {
                setAttribute(_tokenId, "Power", uint2str(parseInt(nftAttributes[_tokenId]["Power"]) - 5)); // Weaken Fire in rain
                setAttribute(_tokenId, "Element", "Water"); // Change element to water
            } else if (keccak256(bytes(currentElement)) == keccak256(bytes("Earth"))) {
                setAttribute(_tokenId, "Power", uint2str(parseInt(nftAttributes[_tokenId]["Power"]) + 3)); // Strengthen Earth in rain
            }
            emit EnvironmentalEffectApplied(_tokenId, _effect);

        } else if (keccak256(bytes(_effect)) == keccak256(bytes("Sunlight"))) {
            if (keccak256(bytes(currentElement)) == keccak256(bytes("Water"))) {
                setAttribute(_tokenId, "Power", uint2str(parseInt(nftAttributes[_tokenId]["Power"]) - 3)); // Weaken Water in sunlight
                setAttribute(_tokenId, "Element", "Fire"); // Change element to Fire
            } else if (keccak256(bytes(currentElement)) == keccak256(bytes("Fire"))) {
                setAttribute(_tokenId, "Power", uint2str(parseInt(nftAttributes[_tokenId]["Power"]) + 5)); // Strengthen Fire in sunlight
            }
            emit EnvironmentalEffectApplied(_tokenId, _effect);

        } // Add more effects as needed
    }

    /**
     * @dev Allows NFTs to "learn" new skills, adding to their attributes.
     * @param _tokenId The ID of the NFT learning the skill.
     * @param _skillName The name of the skill to learn (e.g., "Fireball", "Healing Touch").
     */
    function learnSkill(uint256 _tokenId, string memory _skillName) public onlyOwnerOf(_tokenId) {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        setAttribute(_tokenId, string(abi.encodePacked("Skill_", _skillName)), "Learned"); // Skill attribute, value "Learned"
        emit SkillLearned(_tokenId, _skillName);
    }

    /**
     * @dev (Admin) Resets all attributes of an NFT to default values.
     * @param _tokenId The ID of the NFT to reset.
     */
    function resetNFTAttributes(uint256 _tokenId) public onlyAdmin {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        delete nftAttributes[_tokenId]; // Simplest reset - removes all attributes. Can be more granular.
        // Re-initialize default attributes if needed (like on mint)
        setAttribute(_tokenId, "Rarity", "Common");
        setAttribute(_tokenId, "Generation", "1");
        setAttribute(_tokenId, "Element", "Neutral");
        setAttribute(_tokenId, "Stage", uint2str(nftStage[_tokenId])); // Keep stage attribute updated
    }


    // --- Social Interaction & Community Features (Conceptual) ---

    /**
     * @dev Simulates interactions between two NFTs, potentially affecting their attributes.
     *  Example interactions: "Battle", "Trade", "Cooperation".
     * @param _tokenId1 The ID of the first NFT.
     * @param _tokenId2 The ID of the second NFT.
     * @param _interactionType A string representing the type of interaction.
     */
    function interactNFTs(uint256 _tokenId1, uint256 _tokenId2, string memory _interactionType) public whenNotPaused {
        require(tokenOwner[_tokenId1] != address(0) && tokenOwner[_tokenId2] != address(0), "Invalid token IDs");
        address owner1 = ownerOf(_tokenId1);
        address owner2 = ownerOf(_tokenId2);
        require(msg.sender == owner1 || msg.sender == owner2, "Interaction initiated by non-owner"); // One of the owners must initiate

        string memory element1 = nftAttributes[_tokenId1]["Element"];
        string memory element2 = nftAttributes[_tokenId2]["Element"];

        if (keccak256(bytes(_interactionType)) == keccak256(bytes("Battle"))) {
            // Simplified Battle logic based on elements (Rock-Paper-Scissors like)
            if ((keccak256(bytes(element1)) == keccak256(bytes("Fire")) && keccak256(bytes(element2)) == keccak256(bytes("Earth"))) ||
                (keccak256(bytes(element1)) == keccak256(bytes("Earth")) && keccak256(bytes(element2)) == keccak256(bytes("Water"))) ||
                (keccak256(bytes(element1)) == keccak256(bytes("Water")) && keccak256(bytes(element2)) == keccak256(bytes("Fire")))) {
                // NFT 1 wins (elemental advantage)
                setAttribute(_tokenId1, "Power", uint2str(parseInt(nftAttributes[_tokenId1]["Power"]) + 2)); // Winner gains power
                setAttribute(_tokenId2, "Power", uint2str(parseInt(nftAttributes[_tokenId2]["Power"]) - 1)); // Loser loses power
            } else if (keccak256(bytes(element1)) != keccak256(bytes(element2))) { // If not elemental advantage, but different elements
                setAttribute(_tokenId1, "Power", uint2str(parseInt(nftAttributes[_tokenId1]["Power"]) + 1)); // Minor power change even without advantage
                setAttribute(_tokenId2, "Power", uint2str(parseInt(nftAttributes[_tokenId2]["Power"]) + 1));
            } // If elements are the same, no power change in this example
        } else if (keccak256(bytes(_interactionType)) == keccak256(bytes("Cooperation"))) {
            setAttribute(_tokenId1, "Power", uint2str(parseInt(nftAttributes[_tokenId1]["Power"]) + 1)); // Cooperation might give small boost
            setAttribute(_tokenId2, "Power", uint2str(parseInt(nftAttributes[_tokenId2]["Power"]) + 1));
        } // Add more interaction types and effects as needed.
    }

    /**
     * @dev (Conceptual - DAO integration needed) Allows community voting on future evolution paths for specific NFTs.
     *  In a real DAO integrated scenario, this would involve voting mechanisms and governance tokens.
     *  This is a placeholder function to illustrate the concept.
     * @param _tokenId The ID of the NFT for which to vote on evolution path.
     * @param _nextStage The proposed next evolution stage.
     */
    function communityVoteForEvolutionPath(uint256 _tokenId, uint256 _nextStage) public {
        require(tokenOwner[_tokenId] != address(0), "Invalid token ID");
        // --- Conceptual Implementation ---
        // 1. Check if user has voting power (e.g., based on governance tokens held).
        // 2. Record user's vote for _nextStage for _tokenId.
        // 3. Tally votes over a period.
        // 4. If _nextStage gets enough votes, update evolution path for _tokenId (not implemented here, requires more complex logic).
        // For now, this function just logs the vote (for demonstration).
        // In a real DAO, integrate with a voting/governance contract.
        // For simplicity, just emit an event showing a vote was cast.
        emit VoteCast(_tokenId, msg.sender, _nextStage);
    }
    event VoteCast(uint256 tokenId, address voter, uint256 nextStage);


    // --- Admin & Utility Functions ---

    /**
     * @dev (Admin) Sets the base URI for NFT metadata.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseMetadataURI(string memory _newBaseURI) public onlyAdmin {
        baseMetadataURI = _newBaseURI;
    }

    /**
     * @dev (Admin) Pauses core contract functionalities (minting, transfers, evolution, interactions).
     */
    function pauseContract() public onlyAdmin whenNotPaused {
        paused = true;
    }

    /**
     * @dev (Admin) Resumes paused contract functionalities.
     */
    function unpauseContract() public onlyAdmin whenPaused {
        paused = false;
    }

    /**
     * @dev (Admin) Allows the contract owner to withdraw any accumulated ETH balance.
     */
    function withdrawContractBalance() public onlyAdmin {
        payable(admin).transfer(address(this).balance);
    }


    // --- Helper Functions (String Conversion for tokenURI and attributes) ---

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 lsd = uint8((_i % 10) + 48);
            bstr[k] = bytes1(lsd);
            _i /= 10;
        }
        return string(bstr);
    }

    function parseInt(string memory _str) internal pure returns (uint) {
        uint result = 0;
        bytes memory bStr = bytes(_str);
        uint slen = bStr.length;
        for (uint i = 0; i < slen; i++) {
            if (bStr[i] >= 48 && bStr[i] <= 57) {
                result = result * 10 + (uint(bStr[i]) - 48);
            }
        }
        return result;
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory resultBytes = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            resultBytes[i-startIndex] = strBytes[i];
        }
        return string(resultBytes);
    }
}
```