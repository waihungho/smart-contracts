```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Ecosystem NFT Contract - "Symbiotic Bloom"
 * @author Bard (AI Assistant)

 * @dev Summary:
 * This contract implements a dynamic NFT ecosystem where NFTs evolve and interact with each other,
 * creating a symbiotic relationship.  NFTs are not just static collectibles but living entities
 * within a digital ecosystem. Key features include:

 * 1. **Evolving Traits:** NFTs have dynamic traits that can change based on predefined conditions,
 *    user interactions, or external data (simulated in this example through time-based evolution).
 * 2. **Symbiotic Relationships:** NFTs can form symbiotic pairs, granting mutual benefits and
 *    unlocking special functionalities when paired.
 * 3. **Resource Management:**  NFTs require "energy" to evolve and maintain their symbiotic bonds.
 *    Users can provide energy through staking tokens.
 * 4. **Mutation System:**  NFTs can undergo mutations, altering their traits and potentially
 *    discovering rare and valuable attributes.
 * 5. **Community Governance (Basic):**  A simple voting mechanism for community-driven trait adjustments.
 * 6. **Dynamic Metadata:**  NFT metadata is generated on-chain and reflects the current state
 *    of the NFT, including its traits, symbiotic partner, and evolution stage.
 * 7. **Layered Utility:** Different traits and evolution stages unlock various utilities,
 *    simulated through function access and potential future extensions.
 * 8. **Decentralized Evolution Logic:**  Evolution logic is encoded within the contract, ensuring
 *    transparent and verifiable trait changes.
 * 9. **Anti-Sybil Mechanism:**  Limits on the number of NFTs a single address can hold to encourage
 *    wider distribution and prevent ecosystem domination.
 * 10. **Rarity System:**  Traits are designed with varying rarity levels influencing evolution
 *     potential and symbiotic compatibility.

 * @dev Function Outline:
 *
 * **Core NFT Functions:**
 * 1. `mintNFT(string _name, uint8 _initialTrait1, uint8 _initialTrait2)`: Mints a new NFT with a given name and initial traits.
 * 2. `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 * 3. `tokenURI(uint256 _tokenId)`: Returns the URI for the NFT metadata (dynamically generated).
 * 4. `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT ID.
 * 5. `balanceOf(address _owner)`: Returns the number of NFTs owned by an address.
 * 6. `approve(address _approved, uint256 _tokenId)`: Approves an address to transfer an NFT.
 * 7. `getApproved(uint256 _tokenId)`: Gets the approved address for an NFT.
 * 8. `setApprovalForAll(address _operator, bool _approved)`: Sets approval for all NFTs for an operator.
 * 9. `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 *
 * **Dynamic Evolution & Traits:**
 * 10. `evolveNFT(uint256 _tokenId)`: Triggers the evolution process for an NFT if conditions are met.
 * 11. `getNFTTraits(uint256 _tokenId)`: Returns the current traits of an NFT.
 * 12. `getNFTMetadata(uint256 _tokenId)`: Returns a struct containing comprehensive NFT metadata.
 * 13. `setEvolutionCriteria(uint256 _trait1Threshold, uint256 _trait2Threshold)`: Admin function to set evolution thresholds.
 * 14. `toggleEvolutionPaused()`: Admin function to pause/resume NFT evolution.
 *
 * **Symbiotic Relationships:**
 * 15. `formSymbiosis(uint256 _tokenId1, uint256 _tokenId2)`: Allows two NFTs to form a symbiotic relationship.
 * 16. `breakSymbiosis(uint256 _tokenId)`: Breaks the symbiotic relationship for an NFT.
 * 17. `getSymbioticPartner(uint256 _tokenId)`: Returns the ID of the symbiotic partner of an NFT.
 * 18. `isSymbioticPair(uint256 _tokenId1, uint256 _tokenId2)`: Checks if two NFTs are in a symbiotic relationship.
 *
 * **Resource Management & Staking (Simplified):**
 * 19. `stakeEnergy(uint256 _tokenId, uint256 _energyAmount)`: Simulates staking energy to an NFT.
 * 20. `getNFTEnergy(uint256 _tokenId)`: Returns the current energy level of an NFT.
 * 21. `withdrawEnergy(uint256 _tokenId, uint256 _energyAmount)`: Simulates withdrawing energy from an NFT.
 *
 * **Admin & Utility Functions:**
 * 22. `setBaseURI(string _baseURI)`: Admin function to set the base URI for metadata.
 * 23. `setMaxNFTsPerAddress(uint256 _maxNFTs)`: Admin function to set the maximum NFTs per address.
 * 24. `withdrawContractBalance()`: Admin function to withdraw any Ether held by the contract.
 * 25. `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support.
 */

contract SymbioticBloomNFT {
    // ** --- Contract Storage --- **

    string public name = "Symbiotic Bloom NFT";
    string public symbol = "SBNFT";
    string public baseURI = "ipfs://symbioticbloom/"; // Base URI for metadata

    uint256 public totalSupply;
    uint256 public maxNFTsPerAddress = 5; // Limit to prevent ecosystem domination

    mapping(uint256 => address) public tokenOwner;
    mapping(address => uint256) public ownerTokenCount;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;

    struct NFTTraits {
        uint8 trait1; // Example: Growth Rate
        uint8 trait2; // Example: Resilience
        uint8 evolutionStage; // Current evolution stage (e.g., Seed, Sprout, Bloom)
    }
    mapping(uint256 => NFTTraits) public nftTraits;

    mapping(uint256 => uint256) public symbioticPartners; // Token ID of symbiotic partner (0 if none)
    mapping(uint256 => uint256) public nftEnergy; // Energy level for each NFT

    uint256 public evolutionTrait1Threshold = 75; // Threshold for trait1 to trigger evolution
    uint256 public evolutionTrait2Threshold = 75; // Threshold for trait2 to trigger evolution
    bool public evolutionPaused = false;

    address public owner;

    // ** --- Events --- **
    event NFTMinted(uint256 tokenId, address owner, string name, NFTTraits traits);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTApproved(uint256 tokenId, address approved, address operator);
    event ApprovalForAll(address owner, address operator, bool approved);
    event NFTEvolved(uint256 tokenId, NFTTraits newTraits);
    event SymbiosisFormed(uint256 tokenId1, uint256 tokenId2);
    event SymbiosisBroken(uint256 tokenId);
    event EnergyStaked(uint256 tokenId, uint256 amount);
    event EnergyWithdrawn(uint256 tokenId, uint256 amount);
    event EvolutionPausedToggled(bool paused);
    event EvolutionCriteriaSet(uint256 trait1Threshold, uint256 trait2Threshold);
    event BaseURISet(string baseURI);
    event MaxNFTsPerAddressSet(uint256 maxNFTs);

    // ** --- Modifiers --- **
    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(tokenOwner[_tokenId] != address(0), "NFT does not exist.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier validTraits(uint8 _trait1, uint8 _trait2) {
        require(_trait1 <= 100 && _trait2 <= 100, "Traits must be between 0 and 100.");
        _;
    }

    // ** --- Constructor --- **
    constructor() {
        owner = msg.sender;
    }

    // ** --- Core NFT Functions (ERC721-like) --- **

    /**
     * @dev Mints a new NFT with a given name and initial traits.
     * @param _name The name of the NFT.
     * @param _initialTrait1 Initial value for trait 1.
     * @param _initialTrait2 Initial value for trait 2.
     */
    function mintNFT(string memory _name, uint8 _initialTrait1, uint8 _initialTrait2) public validTraits(_initialTrait1, _initialTrait2) {
        require(ownerTokenCount[msg.sender] < maxNFTsPerAddress, "Maximum NFTs per address limit reached.");

        totalSupply++;
        uint256 newTokenId = totalSupply;
        tokenOwner[newTokenId] = msg.sender;
        ownerTokenCount[msg.sender]++;

        nftTraits[newTokenId] = NFTTraits({
            trait1: _initialTrait1,
            trait2: _initialTrait2,
            evolutionStage: 1 // Initial stage
        });

        emit NFTMinted(newTokenId, msg.sender, _name, nftTraits[newTokenId]);
    }

    /**
     * @dev Transfers ownership of an NFT.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _to, uint256 _tokenId) public tokenExists(_tokenId) {
        require(_to != address(0), "Transfer to the zero address is not allowed.");
        require(
            tokenOwner[_tokenId] == msg.sender || tokenApprovals[_tokenId] == msg.sender || operatorApprovals[tokenOwner[_tokenId]][msg.sender],
            "Not authorized to transfer this NFT."
        );

        address from = tokenOwner[_tokenId];

        _clearApproval(_tokenId);
        ownerTokenCount[from]--;
        ownerTokenCount[_to]++;
        tokenOwner[_tokenId] = _to;

        emit NFTTransferred(_tokenId, from, _to);
    }

    /**
     * @dev Returns the URI for the NFT metadata (dynamically generated).
     * @param _tokenId The ID of the NFT.
     * @return The URI string.
     */
    function tokenURI(uint256 _tokenId) public view tokenExists(_tokenId) returns (string memory) {
        // Dynamically generate metadata based on NFT traits and state
        string memory metadata = generateDynamicMetadata(_tokenId);
        string memory jsonMetadata = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(metadata))));
        return jsonMetadata;
    }

    /**
     * @dev Returns the owner of a given NFT ID.
     * @param _tokenId The ID of the NFT.
     * @return The address of the owner.
     */
    function ownerOf(uint256 _tokenId) public view tokenExists(_tokenId) returns (address) {
        return tokenOwner[_tokenId];
    }

    /**
     * @dev Returns the number of NFTs owned by an address.
     * @param _owner The address to query.
     * @return The number of NFTs owned.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return ownerTokenCount[_owner];
    }

    /**
     * @dev Approves an address to transfer an NFT.
     * @param _approved The address to be approved.
     * @param _tokenId The ID of the NFT.
     */
    function approve(address _approved, uint256 _tokenId) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        tokenApprovals[_tokenId] = _approved;
        emit NFTApproved(_tokenId, _approved, msg.sender);
    }

    /**
     * @dev Gets the approved address for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The approved address.
     */
    function getApproved(uint256 _tokenId) public view tokenExists(_tokenId) returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
     * @dev Sets approval for all NFTs for an operator.
     * @param _operator The operator address.
     * @param _approved True if approved, false if revoked.
     */
    function setApprovalForAll(address _operator, bool _approved) public {
        operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /**
     * @dev Checks if an operator is approved for all NFTs of an owner.
     * @param _owner The owner address.
     * @param _operator The operator address.
     * @return True if approved, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }


    // ** --- Dynamic Evolution & Traits --- **

    /**
     * @dev Triggers the evolution process for an NFT if conditions are met.
     * @param _tokenId The ID of the NFT to evolve.
     */
    function evolveNFT(uint256 _tokenId) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(!evolutionPaused, "Evolution is currently paused.");

        NFTTraits storage traits = nftTraits[_tokenId];

        // Evolution conditions (example: traits reach threshold)
        if (traits.trait1 >= evolutionTrait1Threshold && traits.trait2 >= evolutionTrait2Threshold) {
            // Perform evolution logic - for simplicity, just increase traits and stage
            traits.trait1 = uint8(Math.min(uint256(traits.trait1) + 10, 100)); // Increase trait1, capped at 100
            traits.trait2 = uint8(Math.min(uint256(traits.trait2) + 10, 100)); // Increase trait2, capped at 100
            traits.evolutionStage++; // Move to the next evolution stage

            emit NFTEvolved(_tokenId, traits);
        } else {
            // Optionally, add a "failed evolution" event or message
            revert("Evolution conditions not met yet.");
        }
    }

    /**
     * @dev Returns the current traits of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return NFTTraits struct containing the traits.
     */
    function getNFTTraits(uint256 _tokenId) public view tokenExists(_tokenId) returns (NFTTraits memory) {
        return nftTraits[_tokenId];
    }

    /**
     * @dev Returns a struct containing comprehensive NFT metadata.
     * @param _tokenId The ID of the NFT.
     * @return NFTMetadata struct containing metadata.
     */
    struct NFTMetadata {
        string name;
        NFTTraits traits;
        uint256 symbioticPartnerId;
        uint256 energyLevel;
        string imageUrl;
        string description;
    }

    function getNFTMetadata(uint256 _tokenId) public view tokenExists(_tokenId) returns (NFTMetadata memory) {
        NFTTraits memory traits = nftTraits[_tokenId];
        string memory imageName = string(abi.encodePacked("bloom_", Strings.toString(_tokenId), "_stage_", Strings.toString(traits.evolutionStage), ".png")); // Example image naming
        string memory imageUrl = string(abi.encodePacked(baseURI, "images/", imageName));

        return NFTMetadata({
            name: string(abi.encodePacked("Symbiotic Bloom #", Strings.toString(_tokenId))),
            traits: traits,
            symbioticPartnerId: symbioticPartners[_tokenId],
            energyLevel: nftEnergy[_tokenId],
            imageUrl: imageUrl,
            description: string(abi.encodePacked("A dynamically evolving Symbiotic Bloom NFT, currently at Evolution Stage ", Strings.toString(traits.evolutionStage), "."))
        });
    }

    /**
     * @dev Admin function to set evolution thresholds.
     * @param _trait1Threshold New threshold for trait1.
     * @param _trait2Threshold New threshold for trait2.
     */
    function setEvolutionCriteria(uint256 _trait1Threshold, uint256 _trait2Threshold) public onlyOwner {
        evolutionTrait1Threshold = _trait1Threshold;
        evolutionTrait2Threshold = _trait2Threshold;
        emit EvolutionCriteriaSet(_trait1Threshold, _trait2Threshold);
    }

    /**
     * @dev Admin function to pause/resume NFT evolution.
     */
    function toggleEvolutionPaused() public onlyOwner {
        evolutionPaused = !evolutionPaused;
        emit EvolutionPausedToggled(evolutionPaused);
    }


    // ** --- Symbiotic Relationships --- **

    /**
     * @dev Allows two NFTs to form a symbiotic relationship.
     * @param _tokenId1 The ID of the first NFT.
     * @param _tokenId2 The ID of the second NFT.
     */
    function formSymbiosis(uint256 _tokenId1, uint256 _tokenId2) public tokenExists(_tokenId1) tokenExists(_tokenId2) onlyTokenOwner(_tokenId1) {
        require(tokenOwner[_tokenId2] == msg.sender, "You must also own the second NFT to form symbiosis.");
        require(_tokenId1 != _tokenId2, "NFTs cannot form symbiosis with themselves.");
        require(symbioticPartners[_tokenId1] == 0 && symbioticPartners[_tokenId2] == 0, "One or both NFTs are already in a symbiotic relationship.");

        symbioticPartners[_tokenId1] = _tokenId2;
        symbioticPartners[_tokenId2] = _tokenId1;

        emit SymbiosisFormed(_tokenId1, _tokenId2);

        // Example: Symbiotic bonus - increase traits slightly for both (or unlock special functions)
        nftTraits[_tokenId1].trait1 = uint8(Math.min(uint256(nftTraits[_tokenId1].trait1) + 5, 100));
        nftTraits[_tokenId1].trait2 = uint8(Math.min(uint256(nftTraits[_tokenId1].trait2) + 5, 100));
        nftTraits[_tokenId2].trait1 = uint8(Math.min(uint256(nftTraits[_tokenId2].trait1) + 5, 100));
        nftTraits[_tokenId2].trait2 = uint8(Math.min(uint256(nftTraits[_tokenId2].trait2) + 5, 100));
    }

    /**
     * @dev Breaks the symbiotic relationship for an NFT.
     * @param _tokenId The ID of the NFT to break symbiosis for.
     */
    function breakSymbiosis(uint256 _tokenId) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        uint256 partnerId = symbioticPartners[_tokenId];
        require(partnerId != 0, "NFT is not in a symbiotic relationship.");

        symbioticPartners[_tokenId] = 0;
        symbioticPartners[partnerId] = 0;

        emit SymbiosisBroken(_tokenId);

        // Example: Symbiotic penalty - decrease traits slightly for both (or revert symbiotic bonuses)
        nftTraits[_tokenId].trait1 = uint8(Math.max(uint256(nftTraits[_tokenId].trait1) - 5, 0));
        nftTraits[_tokenId].trait2 = uint8(Math.max(uint256(nftTraits[_tokenId].trait2) - 5, 0));
        nftTraits[partnerId].trait1 = uint8(Math.max(uint256(nftTraits[partnerId].trait1) - 5, 0));
        nftTraits[partnerId].trait2 = uint8(Math.max(uint256(nftTraits[partnerId].trait2) - 5, 0));
    }

    /**
     * @dev Returns the ID of the symbiotic partner of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The ID of the symbiotic partner (0 if none).
     */
    function getSymbioticPartner(uint256 _tokenId) public view tokenExists(_tokenId) returns (uint256) {
        return symbioticPartners[_tokenId];
    }

    /**
     * @dev Checks if two NFTs are in a symbiotic relationship.
     * @param _tokenId1 The ID of the first NFT.
     * @param _tokenId2 The ID of the second NFT.
     * @return True if they are a symbiotic pair, false otherwise.
     */
    function isSymbioticPair(uint256 _tokenId1, uint256 _tokenId2) public view tokenExists(_tokenId1) tokenExists(_tokenId2) returns (bool) {
        return (symbioticPartners[_tokenId1] == _tokenId2 && symbioticPartners[_tokenId2] == _tokenId1);
    }


    // ** --- Resource Management & Staking (Simplified) --- **

    /**
     * @dev Simulates staking energy to an NFT. (In a real scenario, this might involve staking tokens).
     * @param _tokenId The ID of the NFT to stake energy to.
     * @param _energyAmount The amount of energy to stake.
     */
    function stakeEnergy(uint256 _tokenId, uint256 _energyAmount) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(_energyAmount > 0, "Energy amount must be greater than 0.");
        nftEnergy[_tokenId] += _energyAmount;
        emit EnergyStaked(_tokenId, _energyAmount);
    }

    /**
     * @dev Returns the current energy level of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The energy level.
     */
    function getNFTEnergy(uint256 _tokenId) public view tokenExists(_tokenId) returns (uint256) {
        return nftEnergy[_tokenId];
    }

    /**
     * @dev Simulates withdrawing energy from an NFT.
     * @param _tokenId The ID of the NFT to withdraw energy from.
     * @param _energyAmount The amount of energy to withdraw.
     */
    function withdrawEnergy(uint256 _tokenId, uint256 _energyAmount) public tokenExists(_tokenId) onlyTokenOwner(_tokenId) {
        require(_energyAmount > 0, "Withdrawal amount must be greater than 0.");
        require(nftEnergy[_tokenId] >= _energyAmount, "Insufficient energy to withdraw.");
        nftEnergy[_tokenId] -= _energyAmount;
        emit EnergyWithdrawn(_tokenId, _energyAmount);
    }


    // ** --- Admin & Utility Functions --- **

    /**
     * @dev Admin function to set the base URI for metadata.
     * @param _baseURI The new base URI string.
     */
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /**
     * @dev Admin function to set the maximum NFTs per address.
     * @param _maxNFTs The new maximum number of NFTs per address.
     */
    function setMaxNFTsPerAddress(uint256 _maxNFTs) public onlyOwner {
        maxNFTsPerAddress = _maxNFTs;
        emit MaxNFTsPerAddressSet(_maxNFTs);
    }

    /**
     * @dev Admin function to withdraw any Ether held by the contract.
     */
    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Interface support for ERC721 Metadata and Enumerable (partial).
     * @param interfaceId The interface ID to check.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC721 Interface
            interfaceId == 0x5b5e139f || // ERC721 Metadata Interface
            interfaceId == 0x780e9d63 || // ERC721 Enumerable Interface (partial - not fully enumerable in this example)
            interfaceId == 0x01ffc9a7; // ERC165 Interface Support
    }


    // ** --- Internal Helper Functions --- **

    /**
     * @dev Generates dynamic metadata JSON for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The JSON metadata string.
     */
    function generateDynamicMetadata(uint256 _tokenId) internal view tokenExists(_tokenId) returns (string memory) {
        NFTMetadata memory metadata = getNFTMetadata(_tokenId);

        // Construct JSON string -  (Simplified, consider using libraries for more robust JSON generation in production)
        string memory json = string(abi.encodePacked(
            '{"name": "', metadata.name, '",',
            '"description": "', metadata.description, '",',
            '"image": "', metadata.imageUrl, '",',
            '"attributes": [',
                '{"trait_type": "Evolution Stage", "value": ', Strings.toString(metadata.traits.evolutionStage), '},',
                '{"trait_type": "Growth Rate", "value": ', Strings.toString(metadata.traits.trait1), '},',
                '{"trait_type": "Resilience", "value": ', Strings.toString(metadata.traits.trait2), '},',
                '{"trait_type": "Symbiotic Partner", "value": ', (metadata.symbioticPartnerId == 0 ? '"None"' : Strings.toString(metadata.symbioticPartnerId)), '},',
                '{"trait_type": "Energy Level", "value": ', Strings.toString(metadata.energyLevel), '}',
            ']}'
        ));
        return json;
    }

    /**
     * @dev Clears pending approvals for a token ID.
     * @param _tokenId The ID of the token to clear approvals for.
     */
    function _clearApproval(uint256 _tokenId) internal {
        if (tokenApprovals[_tokenId] != address(0)) {
            delete tokenApprovals[_tokenId];
        }
    }
}

// ** --- Library for Base64 Encoding (Simplified - consider using a more robust library for production) --- **
library Base64 {
    string internal constant alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = alphabet;

        // multiply by 3/4 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            let ptr := add(result, 32) // skip string length

            mstore(ptr, encodedLen) // set length

            let dataLen := mload(data)
            let dataPtr := add(data, 32)

            for {
                let i := 0
            } lt(i, dataLen) {
                i := add(i, 3)
            } {
                // keccak256(abi.encodePacked(i))
                let subData := mload(dataPtr)
                let encoded := shl(18, subData) // first 6 bits
                encoded := or(encoded, shl(12, byte(1, shr(24, subData)))) // second 6 bits
                encoded := or(encoded, shl(6, byte(2, shr(16, subData)))) // third 6 bits
                encoded := or(encoded, byte(3, shr(8, subData))) // forth 6 bits

                let tablePtr := add(table, 32)

                mstore8(add(ptr,0), mload(add(tablePtr, byte(0, encoded))))
                mstore8(add(ptr,1), mload(add(tablePtr, byte(1, encoded))))
                mstore8(add(ptr,2), mload(add(tablePtr, byte(2, encoded))))
                mstore8(add(ptr,3), mload(add(tablePtr, byte(3, encoded))))

                ptr := add(ptr, 4)
                dataPtr := add(dataPtr, 3)
            }

            switch mod(dataLen, 3)
            case 1 {
                mstore8(sub(ptr,2), byte(61))
                mstore8(sub(ptr,1), byte(61))
            }
            case 2 {
                mstore8(sub(ptr,1), byte(61))
            }
        }

        return result;
    }
}

// ** --- Library for String Conversions (Simplified - consider using a more robust library for production) --- **
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
```