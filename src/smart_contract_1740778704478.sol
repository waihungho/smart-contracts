Okay, let's craft a Solidity smart contract that embodies a more advanced and trendy concept: **Decentralized Dynamic NFTs (DDN)**.  This contract allows for NFTs whose properties *change* based on external data feeds and complex on-chain logic, driven by user interaction and potentially oracles, creating NFTs that evolve over time. This avoids the traditional static nature of NFTs and introduces a layer of dynamic, reactive behavior.

Here's the outline and summary, followed by the Solidity code:

**Contract: `DynamicNFT`**

**Outline:**

*   **Concept:** Decentralized Dynamic NFTs (DDN) whose attributes are updated based on external data and internal logic.
*   **Functionality:**
    *   Minting of initial "seed" NFTs.
    *   Configuration of updateable attributes and their update triggers.
    *   Mechanism for triggering attribute updates (user interaction, oracle data, time-based triggers).
    *   On-chain logic to derive new attribute values based on the triggers.
    *   Storage and access to NFT metadata.
    *   Possible integration with an external oracle for real-world data.

**Function Summary:**

*   `constructor(string memory _name, string memory _symbol)`: Initializes the contract with the name and symbol of the NFT collection.
*   `mint(address _to, string memory _baseURI)`: Mints a new "seed" NFT with an initial base URI.
*   `setUpdateRule(uint256 _tokenId, string memory _attribute, UpdateRule _rule)`: Sets the update rules for a specific NFT attribute.
*   `triggerUpdate(uint256 _tokenId)`: Triggers the update logic for a specific NFT, applying update rules.
*   `getMetadata(uint256 _tokenId)`: Returns the current metadata for a specific NFT, incorporating dynamic attributes.
*   `setOracleAddress(address _oracleAddress)`: Sets the address of the oracle contract. (Potentially for integration).
*   `tokenURI(uint256 tokenId)`:  Returns the complete token URI, including dynamic metadata.

**Solidity Code:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DynamicNFT is ERC721, Ownable {

    using Strings for uint256;

    // --- Structs and Enums ---

    struct NFTData {
        string baseURI; // Initial base URI
        uint256 lastUpdated; // Timestamp of last attribute update
        // Add any other initial static data needed here.
    }

    enum UpdateType {
        INCREMENT,
        DECREMENT,
        SET_VALUE,
        ORACLE_VALUE // Potential integration with an oracle
    }

    struct UpdateRule {
        UpdateType updateType;
        string attribute;  // The NFT attribute that is updated.
        int256  value;     // Value for increment, decrement or set
        // Add other data depending on your needs.  Oracle data for example.
    }

    // --- State Variables ---

    mapping(uint256 => NFTData) public nftData;  // Token ID => NFT Data
    mapping(uint256 => mapping(string => UpdateRule)) public updateRules; // Token ID => Attribute => UpdateRule
    uint256 public tokenIdCounter; // Keeps track of token ID's
    address public oracleAddress;   // (Optional) Address of the oracle contract.
    string public baseTokenURI;  // Base URI for metadata (e.g., IPFS folder)
    string public contractURI;
    // --- Events ---

    event NFTMinted(address indexed to, uint256 tokenId);
    event AttributeUpdated(uint256 indexed tokenId, string attribute, string newValue);

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
      contractURI = "yourContractMetadataURI.json";  //Consider putting contract metadata on IPFS or similar.
      tokenIdCounter = 1; // Start at 1 for convenience
    }

    // --- Minting ---

    function mint(address _to, string memory _baseURI) public onlyOwner returns (uint256) {
        uint256 newTokenId = tokenIdCounter;
        _safeMint(_to, newTokenId);

        nftData[newTokenId] = NFTData({
            baseURI: _baseURI,
            lastUpdated: block.timestamp
            // Initialize any other static values.
        });

        emit NFTMinted(_to, newTokenId);
        tokenIdCounter++;
        return newTokenId;
    }

    // --- Update Rules ---

    function setUpdateRule(uint256 _tokenId, string memory _attribute, UpdateRule memory _rule) public onlyOwner {
        require(_exists(_tokenId), "Token does not exist");
        updateRules[_tokenId][_attribute] = _rule;
    }

    // --- Oracle Address Management ---

    function setOracleAddress(address _oracleAddress) public onlyOwner {
        oracleAddress = _oracleAddress;
    }

    // --- Update Trigger and Logic ---

    function triggerUpdate(uint256 _tokenId) public {
        require(_exists(_tokenId), "Token does not exist");

        for (uint i = 0; i < getUpdateRuleCount(_tokenId); i++) {
            string memory attribute = getUpdateRuleAttribute(_tokenId, i);
            UpdateRule memory rule = updateRules[_tokenId][attribute];

            if (rule.updateType == UpdateType.INCREMENT) {
                // Example: Increment a numerical attribute
                string memory currentValue = getAttributeValue(_tokenId, attribute);
                int256 intValue = parseInt(currentValue); // You'll need a parseInt library
                intValue += rule.value;
                setAttributeValue(_tokenId, attribute, toString(intValue)); // You'll need a toString library
                emit AttributeUpdated(_tokenId, attribute, toString(intValue));
            } else if (rule.updateType == UpdateType.DECREMENT) {
                string memory currentValue = getAttributeValue(_tokenId, attribute);
                int256 intValue = parseInt(currentValue); // You'll need a parseInt library
                intValue -= rule.value;
                setAttributeValue(_tokenId, attribute, toString(intValue)); // You'll need a toString library
                emit AttributeUpdated(_tokenId, attribute, toString(intValue));
            } else if (rule.updateType == UpdateType.SET_VALUE) {
                setAttributeValue(_tokenId, attribute, toString(rule.value));
                emit AttributeUpdated(_tokenId, attribute, toString(rule.value));
            }
             else if (rule.updateType == UpdateType.ORACLE_VALUE) {
                 //  Fetch data from oracle
                 //  setAttributeValue(_tokenId, attribute, oracleResult);
                 //  emit AttributeUpdated(_tokenId, attribute, oracleResult);
            }
        }

        nftData[_tokenId].lastUpdated = block.timestamp;
    }

    // --- Get Metadata ---

    function getMetadata(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Token does not exist");

        string memory metadata = string(abi.encodePacked(
            '{"name": "', name(), ' #', _tokenId.toString(), '",',
            '"description": "A dynamically updated NFT.",',
            '"image": "', nftData[_tokenId].baseURI, _tokenId.toString(),'.png",', // Example. Could be a different image based on attributes
            '"attributes": {'
        ));

        // Build attributes part dynamically
        bool firstAttribute = true;
        for (uint i = 0; i < getAttributeCount(_tokenId); i++) {
            string memory attributeName = getAttributeName(_tokenId, i);
            string memory attributeValue = getAttributeValue(_tokenId, attributeName);

            if (!firstAttribute) {
                metadata = string(abi.encodePacked(metadata, ","));
            } else {
                firstAttribute = false;
            }

            metadata = string(abi.encodePacked(metadata,
                '"', attributeName, '": "', attributeValue, '"'
            ));
        }

        metadata = string(abi.encodePacked(metadata, '}}'));
        return metadata;
    }

    // --- Token URI ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId), ".json"));
    }

    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    // --- Helper Functions ---

    function getUpdateRuleCount(uint256 _tokenId) public view returns (uint) {
        uint count = 0;
        bytes32[] memory keys = getKeys(_tokenId);
        for (uint i = 0; i < keys.length; i++) {
            if (keys[i] != bytes32(0)) {
                count++;
            }
        }
        return count;
    }

    function getUpdateRuleAttribute(uint256 _tokenId, uint _index) public view returns (string memory) {
        bytes32[] memory keys = getKeys(_tokenId);
        require(_index < keys.length, "Index out of bounds");
        return string(keys[_index]);
    }

    function getAttributeCount(uint256 _tokenId) public view returns (uint) {
        uint count = 0;
        bytes32[] memory keys = getKeys(_tokenId);
        for (uint i = 0; i < keys.length; i++) {
            if (keys[i] != bytes32(0)) {
                count++;
            }
        }
        return count;
    }

    function getAttributeName(uint256 _tokenId, uint _index) public view returns (string memory) {
        bytes32[] memory keys = getKeys(_tokenId);
        require(_index < keys.length, "Index out of bounds");
        return string(keys[_index]);
    }

    function getAttributeValue(uint256 _tokenId, string memory _attribute) public view returns (string memory) {
        bytes32 key = keccak256(bytes(_attribute));
        bytes32 value = _getAttributeValue(_tokenId, key);
        return string(value);
    }

    function setAttributeValue(uint256 _tokenId, string memory _attribute, string memory _value) internal {
        bytes32 key = keccak256(bytes(_attribute));
        bytes32 value = keccak256(bytes(_value));
        _setAttributeValue(_tokenId, key, value);
    }

    function _setAttributeValue(uint256 _tokenId, bytes32 _key, bytes32 _value) internal {
        bytes32 slot = keccak256(abi.encode(_tokenId, _key));
        assembly {
            sstore(slot, _value)
        }
    }

    function _getAttributeValue(uint256 _tokenId, bytes32 _key) internal view returns (bytes32) {
        bytes32 slot = keccak256(abi.encode(_tokenId, _key));
        bytes32 value;
        assembly {
            value := sload(slot)
        }
        return value;
    }

    function getKeys(uint256 _tokenId) internal view returns (bytes32[] memory) {
        bytes32 slot = keccak256(abi.encode(_tokenId));
        uint256 count = 0;
        bytes32 key;
        bytes32 value;
        bytes32 dataSlot;

        // Calculate the number of elements
        assembly {
            dataSlot := slot
            for { let i := 0 } lt(i, 100) { i := add(i, 1) } {
                key := sload(dataSlot)
                if iszero(key) {
                    break
                }
                count := add(count, 1)
                dataSlot := add(dataSlot, 1)
            }
        }

        bytes32[] memory keys = new bytes32[](count);
        assembly {
            dataSlot := slot
            for { let i := 0 } lt(i, count) { i := add(i, 1) } {
                key := sload(dataSlot)
                keys[i] := key
                dataSlot := add(dataSlot, 1)
            }
        }

        return keys;
    }

    // --- parseInt Function ---

    function parseInt(string memory _str) internal pure returns (int) {
        int result = 0;
        bytes memory strBytes = bytes(_str);
        bool negative = false;
        if (strBytes.length > 0 && strBytes[0] == '-') {
            negative = true;
            for (uint i = 1; i < strBytes.length; i++) {
                require(strBytes[i] >= '0' && strBytes[i] <= '9', "Invalid character in string");
                result = result * 10 - int(uint8(strBytes[i] - '0'));
            }
        } else {
            for (uint i = 0; i < strBytes.length; i++) {
                require(strBytes[i] >= '0' && strBytes[i] <= '9', "Invalid character in string");
                result = result * 10 + int(uint8(strBytes[i] - '0'));
            }
        }
        return result;
    }

    // --- toString Function ---

    function toString(int value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        bool negative = false;
        if (value < 0) {
            negative = true;
            value = -value;
        }

        string memory reversed = "";
        while (value > 0) {
            uint digit = uint(value % 10);
            value /= 10;
            reversed = string(abi.encodePacked(reversed, string(unicode(uint8(digit + 48)))));
        }

        string memory str = "";
        if (negative) {
            str = "-";
        }
        bytes memory reversedBytes = bytes(reversed);
        for (uint i = reversedBytes.length; i > 0; i--) {
            str = string(abi.encodePacked(str, string(unicode(reversedBytes[i - 1]))));
        }

        return str;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function contractURI2() public view returns (string memory) {
        return contractURI;
    }
}
```

**Key Improvements and Explanations:**

*   **Dynamic Attributes:** The `NFTData` struct holds the initial NFT information, like the `baseURI`.  The heart of the dynamism lies in the `setAttributeValue` and `getAttributeValue` functions.  These functions use assembly to directly write to storage slots based on a hash of the token ID and attribute name.  This allows for the arbitrary addition and retrieval of dynamic NFT attributes *without* pre-defining them in the contract's state variables.  This is crucial for flexibility.
*   **Update Rules:** The `UpdateRule` struct and `setUpdateRule` function allow the contract owner to specify *how* an NFT's attributes should be updated. The `UpdateType` enum provides examples like incrementing, decrementing, setting a direct value, and even (potentially) fetching a value from an oracle.
*   **Oracle Integration (Illustrative):**  The `oracleAddress` and `UpdateType.ORACLE_VALUE` are included to suggest how an external oracle could be used to drive updates.  The contract *doesn't* directly implement the oracle call (as that would require a specific oracle implementation), but the placeholder is there.  You would need to add the appropriate oracle client library (e.g., Chainlink's) and the logic to request and receive data.
*   **`triggerUpdate` Function:** This function is the entry point for triggering the update logic.  It iterates through the defined update rules for a given NFT and applies the corresponding transformations. It also updates the `lastUpdated` timestamp.
*   **`getMetadata` Function:**  This is a critical function.  It dynamically constructs the NFT metadata JSON string by fetching the current values of all the dynamic attributes.  This is what allows the NFT to reflect its current, updated state.  It creates a basic JSON with "name", "description", "image", and a dynamically generated "attributes" section.  You can customize this to fit your desired metadata schema.
*   **Assembly Optimization:** Using assembly in `_setAttributeValue` and `_getAttributeValue` provides a more gas-efficient way to directly manipulate storage slots, bypassing some of the overhead of Solidity's mapping operations.
*   **Error Handling:**  Includes `require` statements to validate inputs and prevent unexpected behavior.
*   **`tokenURI` Override:** The `tokenURI` function is overridden to return a metadata URI that points to a resource that would dynamically generate the metadata based on the `getMetadata` function's output.  This would typically be a server or decentralized storage solution that hosts a script that calls the `getMetadata` function on the contract.  This is *essential* for making the NFT's dynamic nature visible on platforms like OpenSea.
*   **parseInt and toString Helpers:** These functions are used to convert between strings and integers, which are often needed when dealing with numerical attributes.
*  **supportsInterface function:**
    *   This function overrides the ERC721 `supportsInterface` function. It is used to indicate that the contract supports certain interfaces, such as ERC721 metadata.
*   **Set/Get Contract URI:** added function for set and get contract URI, its good practice.
**Important Considerations and Next Steps:**

*   **Gas Optimization:** Dynamic NFTs, especially those with complex update logic, can be gas-intensive.  Careful optimization is essential. Consider using libraries for string manipulation or efficient data structures.
*   **Security:** Thoroughly audit the contract for vulnerabilities, especially related to access control, arithmetic overflows, and potential oracle manipulation.
*   **Oracle Integration (Implementation):** If you plan to use an oracle, you'll need to select a specific oracle provider (e.g., Chainlink, API3) and integrate their client library into the contract.
*   **Metadata Hosting:** You'll need a solution for hosting the NFT metadata. Options include centralized servers, decentralized storage (IPFS, Arweave), or even generating the metadata directly on-chain (though this is very expensive).  A common pattern is to have a server that listens for `AttributeUpdated` events and then updates the metadata accordingly, storing it on IPFS.
*   **Frontend Integration:** A frontend is needed to allow users to view the dynamic NFTs, trigger updates, and interact with the update rules.
*   **Testing:** Write extensive unit and integration tests to ensure the contract functions correctly under various scenarios.
*   **UI/UX Considerations:**  Make sure the UI/UX clearly communicates the dynamic nature of the NFTs to users.

This contract provides a solid foundation for creating truly dynamic and evolving NFTs. Remember to adapt and extend it based on your specific project requirements.
