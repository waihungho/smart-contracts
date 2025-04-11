```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Bard (Example - Adaptable and Creative Smart Contract)
 * @notice This contract implements a dynamic NFT system where NFTs can evolve based on user interactions, time, and on-chain events.
 * It features a multi-stage evolution process, attribute customization, rarity system, decentralized governance for evolution rules,
 * and a marketplace for trading evolved NFTs. It aims to be a creative and advanced example, avoiding duplication of common open-source contracts.
 *
 * **Contract Outline and Function Summary:**
 *
 * **1. Core NFT Functionality (ERC721-like):**
 *    - `mintNFT(string memory _baseURI, string memory _name, string memory _symbol, uint256 _initialRarity)`: Mints a new NFT with initial attributes.
 *    - `transferNFT(address _to, uint256 _tokenId)`: Transfers ownership of an NFT.
 *    - `approve(address _approved, uint256 _tokenId)`: Approves an address to operate on a single NFT.
 *    - `getApproved(uint256 _tokenId)`: Gets the approved address for a single NFT.
 *    - `setApprovalForAll(address _operator, bool _approved)`: Enables or disables approval for an operator to manage all of the owner's NFTs.
 *    - `isApprovedForAll(address _owner, address _operator)`: Checks if an operator is approved for all NFTs of an owner.
 *    - `ownerOf(uint256 _tokenId)`: Returns the owner of a given NFT.
 *    - `tokenURI(uint256 _tokenId)`: Returns the metadata URI for an NFT, dynamically generated based on evolution stage and attributes.
 *    - `totalSupply()`: Returns the total number of NFTs minted.
 *    - `balanceOf(address _owner)`: Returns the number of NFTs owned by an address.
 *    - `tokenByIndex(uint256 _index)`: Returns the token ID at a given index in all minted NFTs.
 *    - `tokenOfOwnerByIndex(address _owner, uint256 _index)`: Returns the token ID at a given index for NFTs owned by an address.
 *
 * **2. Dynamic Evolution and Attributes:**
 *    - `interactWithNFT(uint256 _tokenId, InteractionType _interaction)`: Allows users to interact with their NFTs to influence evolution.
 *    - `checkEvolutionStatus(uint256 _tokenId)`: Checks the current evolution stage and progress of an NFT.
 *    - `getNFTAttributes(uint256 _tokenId)`: Retrieves the current attributes of an NFT.
 *    - `evolveNFT(uint256 _tokenId)`:  Triggers the evolution process for an NFT if conditions are met (internal function, triggered by interactions/time).
 *    - `setEvolutionThreshold(uint256 _stage, uint256 _threshold)`: Allows governance to set interaction thresholds for evolution stages.
 *    - `setBaseAttribute(uint256 _attributeId, string memory _name)`: Allows governance to define base attributes for NFTs.
 *
 * **3. Rarity and Specialization:**
 *    - `getRarityTier(uint256 _tokenId)`: Returns the rarity tier of an NFT based on its attributes.
 *    - `specializeNFT(uint256 _tokenId, SpecializationType _specialization)`: Allows users to choose a specialization path for their NFT during evolution.
 *
 * **4. Decentralized Governance (Simplified Example):**
 *    - `proposeEvolutionRuleChange(uint256 _stage, uint256 _newThreshold)`: Allows users to propose changes to evolution rules (simplified governance).
 *    - `voteOnRuleChangeProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on proposed rule changes.
 *    - `executeRuleChangeProposal(uint256 _proposalId)`: Executes a rule change proposal if it passes (simplified governance).
 *
 * **5. Marketplace (Basic Example):**
 *    - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Allows NFT owners to list their NFTs for sale.
 *    - `buyNFT(uint256 _tokenId)`: Allows users to buy NFTs listed for sale.
 *    - `cancelNFTSale(uint256 _tokenId)`: Allows NFT owners to cancel a sale listing.
 */
contract DynamicNFTEvolution {
    // ** 1. Core NFT Functionality (ERC721-like) **

    string public name;
    string public symbol;
    string public baseURI;

    mapping(uint256 => address) private _ownerOf;
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => NFTData) private _nftData;
    uint256 private _currentTokenId = 1; // Start token IDs from 1

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event NFTMinted(uint256 _tokenId, address _minter);
    event NFTEvolved(uint256 _tokenId, uint256 _newStage);
    event NFTAttributeUpdated(uint256 _tokenId, uint256 _attributeId, uint256 _newValue);
    event InteractionOccurred(uint256 _tokenId, address _interactor, InteractionType _interaction);
    event RuleChangeProposed(uint256 _proposalId, uint256 _stage, uint256 _newThreshold, address _proposer);
    event VoteCast(uint256 _proposalId, address _voter, bool _vote);
    event RuleChangeExecuted(uint256 _proposalId, uint256 _newThreshold);
    event NFTListedForSale(uint256 _tokenId, uint256 _price, address _seller);
    event NFTBought(uint256 _tokenId, uint256 _price, address _buyer, address _seller);
    event NFTSaleCancelled(uint256 _tokenId, address _seller);

    // ** 2. Dynamic Evolution and Attributes **

    enum EvolutionStage { Egg, Hatchling, Juvenile, Adult, Ascended }
    enum InteractionType { Feed, Train, Explore, Socialize, Rest }
    enum SpecializationType { Warrior, Mage, Trader, Artisan }

    struct NFTData {
        EvolutionStage stage;
        uint256 lastInteractionTime;
        uint256 interactionPoints;
        uint256 rarity; // Initial Rarity score
        SpecializationType specialization;
        mapping(uint256 => uint256) attributes; // Attribute ID => Value
    }

    uint256 public constant MAX_EVOLUTION_STAGES = 5;
    uint256 public constant MAX_ATTRIBUTES = 5; // Example: Health, Strength, Intelligence, Agility, Luck

    mapping(uint256 => uint256) public evolutionThresholds; // EvolutionStage => Interaction Points needed
    mapping(uint256 => string) public baseAttributeNames; // Attribute ID => Attribute Name

    // ** 4. Decentralized Governance (Simplified Example) **
    struct RuleChangeProposal {
        uint256 stage;
        uint256 newThreshold;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => RuleChangeProposal) public ruleChangeProposals;
    uint256 public proposalCounter = 0;

    // ** 5. Marketplace (Basic Example) **
    struct SaleListing {
        uint256 price;
        address seller;
        bool isListed;
    }
    mapping(uint256 => SaleListing) public nftListings;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        // Initialize default evolution thresholds
        evolutionThresholds[uint256(EvolutionStage.Egg)] = 100;
        evolutionThresholds[uint256(EvolutionStage.Hatchling)] = 250;
        evolutionThresholds[uint256(EvolutionStage.Juvenile)] = 500;
        evolutionThresholds[uint256(EvolutionStage.Adult)] = 1000;

        // Initialize base attribute names
        baseAttributeNames[0] = "Health";
        baseAttributeNames[1] = "Strength";
        baseAttributeNames[2] = "Intelligence";
        baseAttributeNames[3] = "Agility";
        baseAttributeNames[4] = "Luck";
    }

    // ** 1. Core NFT Functionality (ERC721-like) **

    function mintNFT(string memory _tokenBaseURI, string memory _tokenName, string memory _tokenSymbol, uint256 _initialRarity) public returns (uint256) {
        uint256 tokenId = _currentTokenId++;
        _ownerOf[tokenId] = msg.sender;
        _balanceOf[msg.sender]++;

        // Initialize NFT Data
        _nftData[tokenId] = NFTData({
            stage: EvolutionStage.Egg,
            lastInteractionTime: block.timestamp,
            interactionPoints: 0,
            rarity: _initialRarity,
            specialization: SpecializationType.Warrior, // Default Specialization
            attributes: getDefaultAttributes(_initialRarity) // Initialize attributes based on rarity
        });

        emit Transfer(address(0), msg.sender, tokenId);
        emit NFTMinted(tokenId, msg.sender);
        return tokenId;
    }

    function transferNFT(address _to, uint256 _tokenId) public payable {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "ERC721: caller is not owner nor approved");
        require(_to != address(0), "ERC721: transfer to the zero address");

        address owner = ownerOf(_tokenId);
        _balanceOf[owner]--;
        _balanceOf[_to]++;
        _ownerOf[_tokenId] = _to;

        delete _tokenApprovals[_tokenId]; // Clear approvals after transfer

        emit Transfer(owner, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public payable {
        address owner = ownerOf(_tokenId);
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");

        _tokenApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "ERC721: ownerOf query for nonexistent token");
        return _ownerOf[_tokenId];
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Dynamically generate URI based on NFT data (stage, attributes, etc.)
        string memory stageStr;
        EvolutionStage stage = _nftData[_tokenId].stage;
        if (stage == EvolutionStage.Egg) {
            stageStr = "Egg";
        } else if (stage == EvolutionStage.Hatchling) {
            stageStr = "Hatchling";
        } else if (stage == EvolutionStage.Juvenile) {
            stageStr = "Juvenile";
        } else if (stage == EvolutionStage.Adult) {
            stageStr = "Adult";
        } else if (stage == EvolutionStage.Ascended) {
            stageStr = "Ascended";
        } else {
            stageStr = "Unknown";
        }

        string memory attributesStr = "[";
        for (uint256 i = 0; i < MAX_ATTRIBUTES; i++) {
            attributesStr = string(abi.encodePacked(attributesStr, baseAttributeNames[i], ":", Strings.toString(_nftData[_tokenId].attributes[i])));
            if (i < MAX_ATTRIBUTES - 1) {
                attributesStr = string(abi.encodePacked(attributesStr, ", "));
            }
        }
        attributesStr = string(abi.encodePacked(attributesStr, "]"));

        string memory metadata = string(abi.encodePacked('{ "name": "', name, ' #', Strings.toString(_tokenId), ' - ', stageStr, '", "description": "A dynamic NFT in stage ', stageStr, ' with attributes ', attributesStr, '.", "image": "', baseURI, tokenIdToString(tokenId), '.png", "attributes": ['));

        for (uint256 i = 0; i < MAX_ATTRIBUTES; i++) {
            metadata = string(abi.encodePacked(metadata, '{ "trait_type": "', baseAttributeNames[i], '", "value": ', Strings.toString(_nftData[_tokenId].attributes[i]), '}'));
            if (i < MAX_ATTRIBUTES - 1) {
                metadata = string(abi.encodePacked(metadata, ','));
            }
        }

        metadata = string(abi.encodePacked(metadata, '] }'));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata))));
    }

    function totalSupply() public view returns (uint256) {
        return _currentTokenId - 1;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balanceOf[_owner];
    }

    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require(_index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        // In a real implementation, you'd need to maintain an array of token IDs for enumeration.
        // This is a simplified example, and this function is not fully implemented for efficiency.
        // For simplicity, we'll just return _index + 1, assuming token IDs are sequential from 1.
        return _index + 1; // Simplified for example, not efficient for large collections
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        require(_owner != address(0), "ERC721Enumerable: owner query for the zero address");
        require(_index < balanceOf(_owner), "ERC721Enumerable: owner index out of bounds");
        // Similar to tokenByIndex, a real implementation would need owner-specific token ID arrays.
        // Simplified example, not fully implemented for efficiency.
        // Returning a placeholder, this function is not fully efficient in this example.
        return _index + 1; // Simplified for example, not efficient for large collections
    }


    // ** 2. Dynamic Evolution and Attributes **

    function interactWithNFT(uint256 _tokenId, InteractionType _interaction) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");

        NFTData storage nft = _nftData[_tokenId];
        nft.lastInteractionTime = block.timestamp;
        nft.interactionPoints += getInteractionPoints(_interaction);

        emit InteractionOccurred(_tokenId, msg.sender, _interaction);

        evolveNFT(_tokenId); // Check and trigger evolution if conditions are met.
    }

    function checkEvolutionStatus(uint256 _tokenId) public view returns (EvolutionStage, uint256, uint256) {
        require(_exists(_tokenId), "NFT does not exist");
        NFTData storage nft = _nftData[_tokenId];
        uint256 threshold = evolutionThresholds[uint256(nft.stage)];
        return (nft.stage, nft.interactionPoints, threshold);
    }

    function getNFTAttributes(uint256 _tokenId) public view returns (mapping(uint256 => uint256) storage) {
        require(_exists(_tokenId), "NFT does not exist");
        return _nftData[_tokenId].attributes;
    }

    function evolveNFT(uint256 _tokenId) private {
        NFTData storage nft = _nftData[_tokenId];
        EvolutionStage currentStage = nft.stage;

        if (currentStage < EvolutionStage.Ascended) { // Can't evolve beyond Ascended
            uint256 threshold = evolutionThresholds[uint256(currentStage)];
            if (nft.interactionPoints >= threshold) {
                nft.stage = EvolutionStage(uint256(currentStage) + 1); // Increment to next stage
                nft.interactionPoints = 0; // Reset interaction points after evolution
                updateAttributesOnEvolution(_tokenId, nft.stage); // Update attributes based on new stage
                emit NFTEvolved(_tokenId, uint256(nft.stage));
            }
        }
    }

    function setEvolutionThreshold(uint256 _stage, uint256 _threshold) public onlyOwner {
        require(_stage < MAX_EVOLUTION_STAGES, "Invalid evolution stage");
        evolutionThresholds[_stage] = _threshold;
    }

    function setBaseAttribute(uint256 _attributeId, string memory _name) public onlyOwner {
        require(_attributeId < MAX_ATTRIBUTES, "Invalid attribute ID");
        baseAttributeNames[_attributeId] = _name;
    }

    // ** 3. Rarity and Specialization **

    function getRarityTier(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist");
        uint256 rarityScore = _nftData[_tokenId].rarity;
        if (rarityScore >= 90) {
            return "Legendary";
        } else if (rarityScore >= 70) {
            return "Epic";
        } else if (rarityScore >= 50) {
            return "Rare";
        } else if (rarityScore >= 30) {
            return "Uncommon";
        } else {
            return "Common";
        }
    }

    function specializeNFT(uint256 _tokenId, SpecializationType _specialization) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_nftData[_tokenId].stage >= EvolutionStage.Juvenile, "Specialization available from Juvenile stage onwards"); // Example restriction

        _nftData[_tokenId].specialization = _specialization;
        // Potentially update attributes based on specialization here as well
    }

    // ** 4. Decentralized Governance (Simplified Example) **

    function proposeEvolutionRuleChange(uint256 _stage, uint256 _newThreshold) public {
        require(_stage < MAX_EVOLUTION_STAGES, "Invalid evolution stage");
        require(_newThreshold > 0, "Threshold must be positive");

        uint256 proposalId = proposalCounter++;
        ruleChangeProposals[proposalId] = RuleChangeProposal({
            stage: _stage,
            newThreshold: _newThreshold,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit RuleChangeProposed(proposalId, _stage, _newThreshold, msg.sender);
    }

    function voteOnRuleChangeProposal(uint256 _proposalId, bool _vote) public {
        require(ruleChangeProposals[_proposalId].proposer != address(0), "Proposal does not exist");
        require(!ruleChangeProposals[_proposalId].executed, "Proposal already executed");
        // In a real governance system, voting power would be based on token holdings or other metrics.
        // This is a simplified example where each address has equal voting power.

        if (_vote) {
            ruleChangeProposals[_proposalId].votesFor++;
        } else {
            ruleChangeProposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    function executeRuleChangeProposal(uint256 _proposalId) public onlyOwner { // Only contract owner can execute for simplicity
        require(ruleChangeProposals[_proposalId].proposer != address(0), "Proposal does not exist");
        require(!ruleChangeProposals[_proposalId].executed, "Proposal already executed");

        uint256 totalVotes = ruleChangeProposals[_proposalId].votesFor + ruleChangeProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast"); // Ensure some votes were cast
        require(ruleChangeProposals[_proposalId].votesFor > ruleChangeProposals[_proposalId].votesAgainst, "Proposal not passed"); // Simple majority

        evolutionThresholds[ruleChangeProposals[_proposalId].stage] = ruleChangeProposals[_proposalId].newThreshold;
        ruleChangeProposals[_proposalId].executed = true;
        emit RuleChangeExecuted(_proposalId, ruleChangeProposals[_proposalId].newThreshold);
    }

    // ** 5. Marketplace (Basic Example) **

    function listNFTForSale(uint256 _tokenId, uint256 _price) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT");
        require(_price > 0, "Price must be greater than zero");
        require(!nftListings[_tokenId].isListed, "NFT is already listed for sale");

        nftListings[_tokenId] = SaleListing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit NFTListedForSale(_tokenId, _price, msg.sender);
    }

    function buyNFT(uint256 _tokenId) public payable {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        require(nftListings[_tokenId].seller != msg.sender, "Cannot buy your own NFT");
        require(msg.value >= nftListings[_tokenId].price, "Insufficient funds to buy NFT");

        SaleListing storage listing = nftListings[_tokenId];
        uint256 price = listing.price;
        address seller = listing.seller;

        listing.isListed = false; // Remove from sale
        delete nftListings[_tokenId]; // Clean up listing data

        payable(seller).transfer(price); // Transfer funds to seller
        transferNFT(msg.sender, _tokenId); // Transfer NFT to buyer

        emit NFTBought(_tokenId, price, msg.sender, seller);
    }

    function cancelNFTSale(uint256 _tokenId) public {
        require(_exists(_tokenId), "NFT does not exist");
        require(nftListings[_tokenId].isListed, "NFT is not listed for sale");
        require(nftListings[_tokenId].seller == msg.sender, "You are not the seller");

        nftListings[_tokenId].isListed = false;
        delete nftListings[_tokenId]; // Clean up listing data

        emit NFTSaleCancelled(_tokenId, msg.sender);
    }


    // ** Internal Helper Functions **

    function _exists(uint256 _tokenId) private view returns (bool) {
        return _ownerOf[_tokenId] != address(0);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) private view returns (bool) {
        require(_exists(_tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(_tokenId);
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    function getInteractionPoints(InteractionType _interaction) private pure returns (uint256) {
        if (_interaction == InteractionType.Feed) {
            return 20;
        } else if (_interaction == InteractionType.Train) {
            return 30;
        } else if (_interaction == InteractionType.Explore) {
            return 15;
        } else if (_interaction == InteractionType.Socialize) {
            return 25;
        } else if (_interaction == InteractionType.Rest) {
            return 10;
        }
        return 0; // Default case
    }

    function getDefaultAttributes(uint256 _rarity) private pure returns (mapping(uint256 => uint256)) {
        mapping(uint256 => uint256) memory attributes;
        // Example: attributes scale with rarity, and have some randomness
        attributes[0] = 50 + (_rarity / 10) + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _rarity))) % 20; // Health
        attributes[1] = 20 + (_rarity / 15) + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _rarity, 1))) % 15; // Strength
        attributes[2] = 30 + (_rarity / 12) + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _rarity, 2))) % 25; // Intelligence
        attributes[3] = 40 + (_rarity / 8)  + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _rarity, 3))) % 18; // Agility
        attributes[4] = 10 + (_rarity / 20) + uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _rarity, 4))) % 10; // Luck
        return attributes;
    }

    function updateAttributesOnEvolution(uint256 _tokenId, EvolutionStage _newStage) private {
        NFTData storage nft = _nftData[_tokenId];
        // Example: Attributes increase upon evolution
        for (uint256 i = 0; i < MAX_ATTRIBUTES; i++) {
            nft.attributes[i] += (uint256(_newStage) * 5) + uint256(keccak256(abi.encodePacked(_tokenId, _newStage, i))) % 3; // Small randomness in attribute increase
            emit NFTAttributeUpdated(_tokenId, i, nft.attributes[i]);
        }
    }

    function tokenIdToString(uint256 _tokenId) private pure returns (string memory) {
        bytes memory str = new bytes(32);
        uint i = 0;
        while (_tokenId > 0) {
            uint digit = _tokenId % 10;
            str[i++] = byte(uint8('0' + digit));
            _tokenId /= 10;
        }
        bytes memory reversedStr = new bytes(i);
        for (uint j = 0; j < i; j++) {
            reversedStr[j] = str[i - 1 - j];
        }
        return string(reversedStr);
    }

    modifier onlyOwner() {
        require(msg.sender == ownerOf(0), "Only contract owner can call this function"); // Assuming token 0 is reserved for contract ownership
        _;
    }
}

// --- Libraries for TokenURI ---
library Strings {
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

library Base64 {
    string internal constant TABLE_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing gas optimization
        string memory result = new string(encodedLen+32);

        assembly {
            let ptr := add(result, 32)

            mstore(ptr, encodedLen)

            let dataLen := mload(data)
            let dataPtr := add(data, 32)

            for { let i := 0 } lt(i, dataLen) { i := add(i, 3) } {
                let input := mload(add(dataPtr, i))

                let out := mload(add(table, mul(and(shr(18, input), 0x3F), 1)))
                        shl(8, out)
                        or(out, mload(add(table, mul(and(shr(12, input), 0x3F), 1))))
                        shl(8, out)
                        or(out, mload(add(table, mul(and(shr( 6, input), 0x3F), 1))))
                        shl(8, out)
                        or(out, mload(add(table, mul(and(        input,  0x3F), 1))))

                mstore(add(ptr, mul(div(i, 3), 4)), shl(24, out))

                switch mod(dataLen, 3)
                case 1 { mstore(sub(ptr, 2), shl(16, 0x3d3d)) }
                case 2 { mstore(sub(ptr, 1), shl(8, 0x3d)) }
            }
        }

        return result;
    }
}
```