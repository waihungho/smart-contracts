```solidity
pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT

/**
 * @title Dynamic NFT Composer - A generative art NFT contract with evolving traits.
 * @author Gemini
 * @notice This contract allows users to mint NFTs that initially have a set of randomized traits.
 *         These traits can dynamically change based on certain on-chain conditions or external oracles.
 *         The core innovation is the ability to define "evolution rules" that alter NFT metadata
 *         based on on-chain data or price feed updates.
 */

contract DynamicNFTComposer {

    // --- Data Structures ---

    struct Trait {
        string name;
        string value;
        uint8 weight; // Influence of this trait change
    }

    struct NFTMetadata {
        string name;
        string description;
        string image; // SVG data or a link to an image
        Trait[] traits;
    }

    struct EvolutionRule {
        string condition; // Eg. "block.timestamp > deadline" or "ethPrice > 3000"
        Trait[] changes; // Traits to modify when the condition is met
        bool applied; // Flag to prevent re-application
    }

    // --- State Variables ---

    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => NFTMetadata) public tokenMetadata;
    mapping(uint256 => EvolutionRule[]) public tokenEvolutionRules; // Each token can have multiple rules
    mapping(address => bool) public minters; // Addresses authorized to mint new NFTs

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event MetadataUpdated(uint256 indexed tokenId, NFTMetadata newMetadata);
    event EvolutionApplied(uint256 indexed tokenId, uint256 ruleIndex);
    event MinterAdded(address minter);
    event MinterRemoved(address minter);
    event RuleAdded(uint256 tokenId, EvolutionRule rule, uint256 ruleIndex);

    // --- Constructor ---

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        minters[msg.sender] = true; // Deployer is the initial minter.
    }

    // --- Modifiers ---
    modifier onlyMinter() {
        require(minters[msg.sender], "Not a minter");
        _;
    }

    // --- Core Functions ---

    /**
     * @notice Mints a new NFT with randomized initial traits.
     *         Generates a base set of random traits and stores the metadata.
     * @param _recipient The address to receive the newly minted NFT.
     * @return tokenId The ID of the minted token.
     */
    function mint(address _recipient) public onlyMinter returns (uint256 tokenId) {
        totalSupply++;
        tokenId = totalSupply;

        ownerOf[tokenId] = _recipient;
        balanceOf[_recipient]++;

        // Generate randomized initial metadata
        tokenMetadata[tokenId] = _generateRandomMetadata(tokenId);

        emit Transfer(address(0), _recipient, tokenId);
        return tokenId;
    }

    /**
     * @notice Internal function to generate random NFT metadata.  This is the core of the
     *         generative art aspect.  Modify this to customize trait generation.
     *         Uses chainlink VRF, and other random number generation can be used here.
     * @param _tokenId The ID of the token being generated for.
     * @return NFTMetadata The generated metadata for the NFT.
     */
    function _generateRandomMetadata(uint256 _tokenId) internal returns (NFTMetadata memory) {
        // Example implementation (very basic - improve for real usage!)
        Trait[] memory initialTraits = new Trait[](3);

        // NOTE: replace block.timestamp or block.difficulty with CHAINLINK VRF calls for production
        // or secure sources of randomness

        // "Color" Trait (using block.timestamp)
        uint256 colorValue = uint256(keccak256(abi.encodePacked(_tokenId, block.timestamp))) % 256;
        initialTraits[0] = Trait({name: "Color", value: string(abi.encodePacked(colorValue)), weight: 5});

        // "Shape" Trait (using block.difficulty)
        uint256 shapeValue = uint256(keccak256(abi.encodePacked(_tokenId, block.difficulty))) % 4;
        string memory shape;
        if (shapeValue == 0) { shape = "Circle"; }
        else if (shapeValue == 1) { shape = "Square"; }
        else if (shapeValue == 2) { shape = "Triangle"; }
        else { shape = "Hexagon"; }
        initialTraits[1] = Trait({name: "Shape", value: shape, weight: 10});

        // "Size" Trait (using block.number)
        uint256 sizeValue = uint256(keccak256(abi.encodePacked(_tokenId, block.number))) % 3;
        string memory size;
        if (sizeValue == 0) { size = "Small"; }
        else if (sizeValue == 1) { size = "Medium"; }
        else { size = "Large"; }
        initialTraits[2] = Trait({name: "Size", value: size, weight: 7});

        // Create basic SVG (very simple example, make it more complex and interesting!)
        string memory imageSVG = string(abi.encodePacked('<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><rect width="100" height="100" fill="rgb(', string(abi.encodePacked(colorValue)), ',0,0)" /></svg>'));

        NFTMetadata memory metadata = NFTMetadata({
            name: string(abi.encodePacked("Dynamic NFT #", uint256ToString(_tokenId))),
            description: "A Dynamic NFT that evolves based on on-chain conditions.",
            image: imageSVG, // Base64 encoded SVG data or IPFS link,
            traits: initialTraits
        });

        return metadata;
    }

    /**
     * @notice Adds an evolution rule to a specific NFT.
     *         Evolution rules define conditions that, when met, change the NFT's metadata.
     * @param _tokenId The ID of the NFT to add the rule to.
     * @param _rule The evolution rule to add.
     */
    function addEvolutionRule(uint256 _tokenId, EvolutionRule memory _rule) public onlyMinter {
        tokenEvolutionRules[_tokenId].push(_rule);
        uint256 ruleIndex = tokenEvolutionRules[_tokenId].length - 1;
        emit RuleAdded(_tokenId, _rule, ruleIndex);
    }

    /**
     * @notice Checks and applies evolution rules for a given NFT.
     *         Evaluates the condition of each rule and, if met, applies the corresponding trait changes.
     *         This function can be triggered by anyone (or automatically by a Chainlink Keeper, Gelato, etc.).
     * @param _tokenId The ID of the NFT to check and evolve.
     */
    function checkAndApplyEvolutions(uint256 _tokenId) public {
        EvolutionRule[] storage rules = tokenEvolutionRules[_tokenId];
        for (uint256 i = 0; i < rules.length; i++) {
            if (!rules[i].applied && _evaluateCondition(_tokenId, rules[i].condition)) {
                _applyEvolution(_tokenId, i);
            }
        }
    }

    /**
     * @notice Internal function to evaluate a rule's condition.
     *         This is where you define how the rule's condition is evaluated.
     * @param _tokenId The ID of the NFT.
     * @param _conditionString The condition string (e.g., "block.timestamp > deadline").
     * @return bool True if the condition is met, false otherwise.
     */
    function _evaluateCondition(uint256 _tokenId, string memory _conditionString) internal view returns (bool) {
        // This is a placeholder - implement your condition logic here!

        // Example 1: Check if a block timestamp is past a certain deadline
        if (keccak256(abi.encodePacked(_conditionString)) == keccak256(abi.encodePacked("block.timestamp > 1678886400"))) { // replace 1678886400 with a real deadline
            return block.timestamp > 1678886400;
        }

        // Example 2: Using a Chainlink price feed.  This is just a demo, you must setup the contract to handle the chainlink oracle feed.
        // if (keccak256(abi.encodePacked(_conditionString)) == keccak256(abi.encodePacked("ethPrice > 3000"))) {
        //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD Mainnet address
        //     ( , int price, , , ) = priceFeed.latestRoundData();
        //     return price > 3000 * 10**8; // Assuming 8 decimals for the price feed
        // }

        // Replace with your own logic...
        // Consider using a more robust expression parser for complex conditions.
        return false; // Default: condition not met
    }


    /**
     * @notice Internal function to apply the trait changes defined in an evolution rule.
     * @param _tokenId The ID of the NFT.
     * @param _ruleIndex The index of the rule in the `tokenEvolutionRules` array.
     */
    function _applyEvolution(uint256 _tokenId, uint256 _ruleIndex) internal {
        NFTMetadata storage metadata = tokenMetadata[_tokenId];
        EvolutionRule storage rule = tokenEvolutionRules[_tokenId][_ruleIndex];

        for (uint256 i = 0; i < rule.changes.length; i++) {
            Trait memory change = rule.changes[i];
            bool traitUpdated = false;

            // Update existing trait
            for (uint256 j = 0; j < metadata.traits.length; j++) {
                if (keccak256(abi.encodePacked(metadata.traits[j].name)) == keccak256(abi.encodePacked(change.name))) {
                    metadata.traits[j].value = change.value;
                    traitUpdated = true;
                    break;
                }
            }

            // Add new trait if it doesn't exist
            if (!traitUpdated) {
                metadata.traits.push(change);
            }
        }

        // Mark rule as applied
        rule.applied = true;

        // Update image (example - regenerate based on traits)
        metadata.image = _regenerateImage(_tokenId, metadata.traits);

        emit MetadataUpdated(_tokenId, metadata);
        emit EvolutionApplied(_tokenId, _ruleIndex);
    }

    /**
     * @notice Internal function to regenerate the NFT's image based on its current traits.
     *         This function can be customized to create different art styles based on the traits.
     * @param _tokenId The ID of the NFT.
     * @param _traits The current traits of the NFT.
     * @return string The new image data (e.g., SVG data or a link).
     */
    function _regenerateImage(uint256 _tokenId, Trait[] memory _traits) internal returns (string) {
        // This is a placeholder - implement your art generation logic here!

        // Example: Rebuild the SVG based on "Color" and "Shape" traits
        string memory color = "255";
        string memory shape = "Circle";

        for (uint256 i = 0; i < _traits.length; i++) {
            if (keccak256(abi.encodePacked(_traits[i].name)) == keccak256(abi.encodePacked("Color"))) {
                color = _traits[i].value;
            } else if (keccak256(abi.encodePacked(_traits[i].name)) == keccak256(abi.encodePacked("Shape"))) {
                shape = _traits[i].value;
            }
        }

        return string(abi.encodePacked('<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><rect width="100" height="100" fill="rgb(', color, ',0,0)" /><text x="10" y="50" fill="white">',shape,'</text></svg>'));
    }

   /**
    * @notice Get the metadata URI for a given token
    * @param _tokenId The ID of the NFT.
    * @return string The URI.
    */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require(ownerOf[_tokenId] != address(0), "Token does not exist");

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "', tokenMetadata[_tokenId].name, '",',
            '"description": "', tokenMetadata[_tokenId].description, '",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(tokenMetadata[_tokenId].image)), '",',
            '"attributes": [', _constructAttributes(_tokenId), ']}'
        ))));

        return string(abi.encodePacked('data:application/json;base64,', json));
    }

    /**
     * @notice Internal function to construct the attributes part of the JSON metadata.
     * @param _tokenId The ID of the NFT.
     * @return string The attributes string.
     */
    function _constructAttributes(uint256 _tokenId) internal view returns (string) {
        string memory attributesString = "";
        NFTMetadata memory metadata = tokenMetadata[_tokenId];

        for (uint256 i = 0; i < metadata.traits.length; i++) {
            attributesString = string(abi.encodePacked(
                attributesString,
                '{"trait_type": "', metadata.traits[i].name, '", "value": "', metadata.traits[i].value, '"}'
            ));
            if (i < metadata.traits.length - 1) {
                attributesString = string(abi.encodePacked(attributesString, ","));
            }
        }

        return attributesString;
    }


    // --- Utility Functions ---

    /**
     * @notice Converts a uint256 to a string.
     * @param _i The uint256 to convert.
     * @return string The string representation of the uint256.
     */
    function uint256ToString(uint256 _i) internal pure returns (string memory) {
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
            uint8 l = uint8(48 + (_i % 10));
            bstr[k] = bytes1(l);
            _i /= 10;
        }
        return string(bstr);
    }

    // --- Admin Functions ---
    /**
     * @notice Adds a new minter.
     * @param _minter The address to add as a minter.
     */
    function addMinter(address _minter) public onlyMinter {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    /**
     * @notice Removes a minter.
     * @param _minter The address to remove as a minter.
     */
    function removeMinter(address _minter) public onlyMinter {
        require(_minter != msg.sender, "Cannot remove yourself as minter");
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }

    /**
     * @notice Allows to withdraw any ether send to this contract.
     * @param _recipient The address that the funds will be sent to.
     */
    function withdraw(address payable _recipient) public onlyMinter {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }


   // --- ERC721 Standard Implementation (Minimal) ---

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(ownerOf[tokenId] == from, "Not owner");
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        _transfer(from, to, tokenId);
    }


    function _transfer(address from, address to, uint256 tokenId) internal {
        balanceOf[from] -= 1;
        balanceOf[to] += 1;
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }


}

library Base64 {
    string internal constant ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) {
            return "";
        }

        // Padding length calculation
        uint256 paddingLength = (3 - (data.length % 3)) % 3;

        // Memory allocation for padded data and output string
        bytes memory paddedData = new bytes(data.length + paddingLength);
        bytes memory encoded = new bytes(4 * (data.length + paddingLength) / 3);

        // Copy data to padded data
        for (uint256 i = 0; i < data.length; i++) {
            paddedData[i] = data[i];
        }

        // Encoding process
        for (uint256 i = 0; i < data.length + paddingLength; i += 3) {
            uint256 inputGroup = (uint256(paddedData[i]) << 16) + (uint256(paddedData[i + 1]) << 8) + uint256(paddedData[i + 2]);
            encoded[(i / 3) * 4] = bytes1(ALPHABET[inputGroup >> 18]);
            encoded[(i / 3) * 4 + 1] = bytes1(ALPHABET[(inputGroup >> 12) & 0x3F]);
            encoded[(i / 3) * 4 + 2] = bytes1(ALPHABET[(inputGroup >> 6) & 0x3F]);
            encoded[(i / 3) * 4 + 3] = bytes1(ALPHABET[inputGroup & 0x3F]);
        }

        // Replace padding characters
        for (uint256 i = 0; i < paddingLength; i++) {
            encoded[encoded.length - 1 - i] = bytes1(uint8('='));
        }

        return string(encoded);
    }

}

// --- Interfaces (Example - Chainlink Aggregator) ---

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}
```

Key improvements and explanations:

* **Dynamic Evolution Rules:**  The core feature.  NFT traits evolve over time based on on-chain conditions or external data.  This creates NFTs that are more than static images; they can respond to the world around them.
* **Trait Weights:** Each trait has a `weight` which could be used to influence the evolution. For example, if a trait is "Rare" (high weight) the evolution rule might try to avoid changing it or have it change less drastically.
* **Condition Evaluation Flexibility:** The `_evaluateCondition` function is the key to making this contract powerful. It's designed to be extended to evaluate *any* on-chain data. Examples include:
    * **Time-based changes:**  "block.timestamp > deadline" allows traits to change after a certain date.
    * **Price feeds:** Integrate with Chainlink or other oracles to change traits based on external data (e.g., "ethPrice > 3000").  The code includes a commented-out example.
    * **On-chain events:**  Trigger changes when other contracts are interacted with or events are emitted.
    * **Game logic:** Integrate with a game to change traits based on player actions.
* **Regenerated Images:** The `_regenerateImage` function provides a place to write code that takes the *current* traits of the NFT and uses them to generate a *new* image. This means the image itself changes as the traits evolve.  The code provides a very basic SVG example, you'll likely want to use a more sophisticated method for generating art.  Possible approaches:
    * **SVG generation:**  Dynamically construct SVG strings based on the traits.
    * **Layered images:**  Store image layers in IPFS and combine them based on traits.
    * **Off-chain rendering:**  Use a server or service to generate images based on trait data (more centralized, but more flexible).
* **Rule Application Prevention:** The `applied` flag in the `EvolutionRule` struct prevents a rule from being applied multiple times.  This is crucial for rules that are meant to be one-time changes.
* **ERC-721 Compatibility:**  The contract includes a minimal ERC-721 implementation for basic transfer functionality. You can expand on this to provide full ERC-721 support if needed.  Importantly, the `tokenURI` function generates metadata on-the-fly, reflecting the current state of the NFT.
* **Minter Role:** A `minter` role controls who can create new NFTs and add evolution rules, adding a level of control.
* **Clear Events:** Events are emitted when NFTs are minted, metadata is updated, and evolution rules are applied, making it easier to track changes on the blockchain.
* **Base64 Encoding:** The `Base64` library is included to encode image data directly in the `tokenURI`.  This reduces reliance on external storage (like IPFS) but can increase gas costs.  Consider using IPFS for larger images.
* **Chainlink Example:** A commented-out example shows how to integrate with a Chainlink price feed.  **Important:**  You'll need to set up your contract to properly use Chainlink VRF or Keepers/Automation to make this truly functional.
* **Gas Optimization Considerations:**  Dynamic metadata and string manipulation can be gas-intensive. Carefully consider gas costs when designing your evolution rules and image generation logic.  Cache frequently used strings.

To deploy and use this contract, you would:

1.  **Deploy:** Deploy the contract to a testnet or mainnet.
2.  **Mint NFTs:**  Call the `mint` function to create new NFTs.
3.  **Add Evolution Rules:** Use the `addEvolutionRule` function to add rules to individual NFTs.  Carefully design your rules to create interesting and dynamic changes.
4.  **Trigger Evolutions:**  Call the `checkAndApplyEvolutions` function (or set up a Chainlink Keeper/Automation task to call it automatically).
5.  **View NFT Metadata:**  Use the `tokenURI` function to get the current metadata for an NFT, including its name, description, image, and traits.  Your NFT marketplace or viewer will use this data to display the NFT.
6. **Chainlink VRF for Randomness:** Integrate Chainlink VRF for a truly provable random trait generation.  This is critical for fair and unpredictable initial trait assignments.
7.  **Chainlink Keepers/Automation:** To automate evolution, use Chainlink Keepers to periodically call `checkAndApplyEvolutions`. This avoids manual triggering and makes the evolution process truly dynamic.
8.  **Optimization** Gas costs for this implementation can be high due to string manipulation and storage updates. Explore optimization techniques like using smaller data types, caching frequently used strings, and optimizing the image generation logic.

This example provides a solid foundation for creating Dynamic NFTs.  Remember to adapt and extend it to fit your specific artistic and technical goals.  Good luck!
