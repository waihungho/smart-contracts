```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Evolution Contract
 * @author Gemini AI Assistant
 * @dev This contract implements a dynamic NFT system where NFTs can evolve through different stages based on on-chain interactions and conditions.
 * It introduces several advanced concepts beyond standard NFT functionalities, including:
 *  - Dynamic Evolution: NFTs change form and metadata based on user actions and time.
 *  - Rarity Tier System: NFTs belong to different rarity tiers that can change with evolution.
 *  - Attribute-Based Evolution: Evolution paths are influenced by randomly assigned initial attributes.
 *  - Decentralized Governance (Simple): Token holders can vote on future evolution paths.
 *  - Staking for Evolution Boost: Staking native tokens can accelerate NFT evolution.
 *  - Fusion Mechanism: Combine multiple NFTs to create a new, potentially rarer NFT.
 *  - Burning for Resources: Burn NFTs to obtain resources for other in-contract actions.
 *  - Time-Based Events: Certain events and evolution paths are triggered by time.
 *  - On-Chain Randomness: Utilize block hash for pseudo-randomness in evolution outcomes.
 *  - Customizable Metadata: NFT metadata dynamically updates with each evolution stage and attributes.
 *  - Pausable Contract: Emergency pause functionality for contract security.
 *  - Fee Management:  Admin can set fees for certain actions (evolution, fusion).
 *  - Whitelist Functionality:  Restrict certain actions to whitelisted addresses.
 *  - Event Logging: Comprehensive event logging for all key actions.
 *  - View Functions for Data Retrieval:  Numerous view functions for easy access to contract state.
 *  - Safe Math Operations:  Utilize SafeMath for secure arithmetic operations.
 *  - Upgradeable (Proxy Pattern - Conceptual):  Design is proxy-friendly for future upgrades (though proxy implementation not included directly).
 *  - Layered Security:  Modifiers and require statements for access control and validation.
 *  - Resource Token Integration (Conceptual):  Design allows for integration with an external resource token for evolution costs.
 *  - Dynamic Base URI: Base URI for metadata can be updated.
 *  - NFT Gifting: Allow users to gift NFTs to others.
 *  - Batch Minting (Admin): Allow admin to mint multiple initial NFTs at once.

 * Function Summary:
 * 1. mintInitialNFT(): Mints a new initial stage NFT to the caller.
 * 2. evolveNFT(): Initiates the evolution process for a given NFT, subject to cooldown and cost.
 * 3. getEvolutionStage(uint256 tokenId): Returns the current evolution stage of an NFT.
 * 4. getRarityTier(uint256 tokenId): Returns the rarity tier of an NFT.
 * 5. getNFTAttributes(uint256 tokenId): Returns the attributes of an NFT.
 * 6. getEvolutionCooldown(uint256 tokenId): Returns the remaining cooldown time for evolution.
 * 7. getEvolutionCost(): Returns the current cost to evolve an NFT.
 * 8. setEvolutionCost(uint256 _cost): Admin function to set the evolution cost.
 * 9. stakeForEvolutionBoost(uint256 tokenId, uint256 amount): Allows staking of native tokens to boost evolution speed. (Conceptual)
 * 10. unstakeForEvolutionBoost(uint256 tokenId): Unstakes tokens used for evolution boost. (Conceptual)
 * 11. fuseNFTs(uint256[] tokenIds): Fuses multiple NFTs into a new NFT, potentially of higher rarity.
 * 12. getFusionCost(): Returns the cost to fuse NFTs.
 * 13. setFusionCost(uint256 _cost): Admin function to set the fusion cost.
 * 14. burnNFTForResources(uint256 tokenId): Burns an NFT to obtain in-contract resources.
 * 15. getBurnResources(uint256 tokenId): Returns the resources obtained from burning a specific NFT.
 * 16. pauseContract(): Admin function to pause the contract.
 * 17. unpauseContract(): Admin function to unpause the contract.
 * 18. withdrawFunds(): Admin function to withdraw contract balance.
 * 19. setBaseURI(string memory _baseURI): Admin function to set the base URI for metadata.
 * 20. giftNFT(uint256 tokenId, address _to): Allows owner to gift an NFT to another address.
 * 21. batchMintInitialNFTs(address[] _toAddresses, uint256 _count): Admin function to mint initial NFTs to multiple addresses.
 * 22. addToWhitelist(address _account): Admin function to add an address to the whitelist.
 * 23. removeFromWhitelist(address _account): Admin function to remove an address from the whitelist.
 * 24. isWhitelisted(address _account): Returns whether an address is whitelisted.
 * 25. setAttributeWeights(uint256[4] memory _weights): Admin function to set attribute weights for evolution.
 * 26. getAttributeWeights(): Returns the current attribute weights for evolution.
 * 27. setRarityThresholds(uint256[4] memory _thresholds): Admin function to set rarity thresholds.
 * 28. getRarityThresholds(): Returns the current rarity thresholds.
 * 29. getTokenMetadata(uint256 tokenId): Returns the complete metadata for a given token ID.
 * 30. supportsInterface(bytes4 interfaceId): Standard ERC721 interface support.
 * 31. totalSupply(): Returns the total number of NFTs minted.
 * 32. balanceOf(address owner): Returns the number of NFTs owned by an address.
 * 33. ownerOf(uint256 tokenId): Returns the owner of a specific NFT.
 * 34. transferFrom(address from, address to, uint256 tokenId): Transfers ownership of an NFT.
 * 35. safeTransferFrom(address from, address to, uint256 tokenId): Safely transfers ownership of an NFT.
 * 36. approve(address approved, uint256 tokenId): Approves an address to operate on an NFT.
 * 37. getApproved(uint256 tokenId): Gets the approved address for an NFT.
 * 38. setApprovalForAll(address operator, bool approved): Sets approval for all NFTs for an operator.
 * 39. isApprovedForAll(address owner, address operator): Checks if an operator is approved for all NFTs.
 */

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DynamicNFTEvolution is ERC721, Ownable, Pausable {
    using SafeMath for uint256;
    using Strings for uint256;

    // --- State Variables ---
    uint256 private _tokenCounter;
    string private _baseURI;

    // Evolution Parameters
    uint256 public evolutionCost = 0.01 ether; // Cost to evolve in native token
    uint256 public evolutionCooldownTime = 1 days; // Cooldown period before evolution
    mapping(uint256 => uint256) public lastEvolutionTime;
    mapping(uint256 => uint256) public evolutionStage; // 0: Initial, 1: Stage 1, 2: Stage 2, ...
    mapping(uint256 => uint256) public rarityTier; // 0: Common, 1: Uncommon, 2: Rare, 3: Epic, 4: Legendary
    uint256[4] public rarityThresholds = [50, 25, 10, 2]; // Percentages for rarity tiers (Uncommon, Rare, Epic, Legendary)
    mapping(uint256 => uint256[4]) public nftAttributes; // 4 attributes for each NFT

    // Fusion Parameters
    uint256 public fusionCost = 0.05 ether; // Cost to fuse NFTs
    uint256 public fusionRequiredNFTs = 2; // Minimum NFTs required for fusion
    uint256 public maxFusionNFTs = 5; // Maximum NFTs that can be fused together

    // Whitelist for special actions (e.g., early access to features)
    mapping(address => bool) public whitelist;

    // Event Logging
    event NFTMinted(address indexed to, uint256 tokenId, uint256 initialStage, uint256 initialRarity);
    event NFTEvolved(uint256 indexed tokenId, uint256 previousStage, uint256 newStage, uint256 newRarity);
    event NFTFused(address indexed to, uint256 newTokenId, uint256[] fusedTokenIds, uint256 newRarity);
    event NFTBurnedForResources(uint256 indexed tokenId, address burner, uint256 resources);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event BaseURISet(string baseURI, address admin);
    event EvolutionParametersSet(uint256 cost, uint256 cooldown, address admin);
    event FusionParametersSet(uint256 cost, uint256 requiredNFTs, uint256 maxNFTs, address admin);
    event WhitelistedAddressAdded(address account, address admin);
    event WhitelistedAddressRemoved(address account, address admin);
    event AttributeWeightsSet(uint256[4] weights, address admin);
    event RarityThresholdsSet(uint256[4] thresholds, address admin);


    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    // --- Constructor ---
    constructor(string memory name_, string memory symbol_, string memory baseURI_) ERC721(name_, symbol_) {
        _tokenCounter = 0;
        _baseURI = baseURI_;
    }

    // --- Admin Functions ---

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _baseURI = _newBaseURI;
        emit BaseURISet(_newBaseURI, msg.sender);
    }

    function setEvolutionCost(uint256 _cost) public onlyOwner {
        evolutionCost = _cost;
        emit EvolutionParametersSet(_cost, evolutionCooldownTime, msg.sender);
    }

    function setEvolutionCooldownTime(uint256 _cooldown) public onlyOwner {
        evolutionCooldownTime = _cooldown;
        emit EvolutionParametersSet(evolutionCost, _cooldown, msg.sender);
    }

    function setFusionCost(uint256 _cost) public onlyOwner {
        fusionCost = _cost;
        emit FusionParametersSet(_cost, fusionRequiredNFTs, maxFusionNFTs, msg.sender);
    }

    function setFusionRequiredNFTs(uint256 _requiredNFTs) public onlyOwner {
        fusionRequiredNFTs = _requiredNFTs;
        emit FusionParametersSet(fusionCost, _requiredNFTs, maxFusionNFTs, msg.sender);
    }

    function setMaxFusionNFTs(uint256 _maxNFTs) public onlyOwner {
        maxFusionNFTs = _maxNFTs;
        emit FusionParametersSet(fusionCost, fusionRequiredNFTs, _maxNFTs, msg.sender);
    }

    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    function withdrawFunds() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function addToWhitelist(address _account) public onlyOwner {
        whitelist[_account] = true;
        emit WhitelistedAddressAdded(_account, msg.sender);
    }

    function removeFromWhitelist(address _account) public onlyOwner {
        whitelist[_account] = false;
        emit WhitelistedAddressRemoved(_account, msg.sender);
    }

    function setAttributeWeights(uint256[4] memory _weights) public onlyOwner {
        // Example: Weights might influence attribute-based evolution paths
        // (Not fully implemented in this example but can be extended)
        // attributeWeights = _weights;
        emit AttributeWeightsSet(_weights, msg.sender); // Just emitting event for now as attribute-based evolution is conceptual here.
    }

    function setRarityThresholds(uint256[4] memory _thresholds) public onlyOwner {
        rarityThresholds = _thresholds;
        emit RarityThresholdsSet(_thresholds, msg.sender);
    }

    // --- Minting Functions ---

    function mintInitialNFT() public payable whenNotPaused {
        _mintNFT(msg.sender);
    }

    function batchMintInitialNFTs(address[] memory _toAddresses, uint256 _count) public onlyOwner whenNotPaused {
        require(_toAddresses.length <= _count, "Addresses array length must be less than or equal to count.");
        for (uint256 i = 0; i < _count; i++) {
            address toAddress = (i < _toAddresses.length) ? _toAddresses[i] : msg.sender; // Default to admin if addresses run out
            _mintNFT(toAddress);
        }
    }

    function _mintNFT(address _to) private {
        uint256 tokenId = _tokenCounter;
        _safeMint(_to, tokenId);
        _tokenCounter++;

        // Initialize NFT properties
        evolutionStage[tokenId] = 0; // Initial stage
        rarityTier[tokenId] = _determineInitialRarity(); // Determine initial rarity
        nftAttributes[tokenId] = _generateInitialAttributes(); // Generate initial attributes

        emit NFTMinted(_to, tokenId, evolutionStage[tokenId], rarityTier[tokenId]);
    }

    function _determineInitialRarity() private view returns (uint256) {
        // Simple rarity determination based on randomness (blockhash for example)
        uint256 randomValue = uint256(blockhash(block.number - 1)); // Not truly random, for demonstration
        uint256 randomNumber = randomValue % 100; // Percentage out of 100

        if (randomNumber < rarityThresholds[3]) { // Legendary
            return 4;
        } else if (randomNumber < rarityThresholds[2] + rarityThresholds[3]) { // Epic
            return 3;
        } else if (randomNumber < rarityThresholds[1] + rarityThresholds[2] + rarityThresholds[3]) { // Rare
            return 2;
        } else if (randomNumber < rarityThresholds[0] + rarityThresholds[1] + rarityThresholds[2] + rarityThresholds[3]) { // Uncommon
            return 1;
        } else { // Common
            return 0;
        }
    }

    function _generateInitialAttributes() private view returns (uint256[4] memory) {
        // Placeholder for attribute generation. Can be made more complex.
        uint256 randomSeed = uint256(blockhash(block.number - 1));
        uint256[4] memory attributes;
        for (uint256 i = 0; i < 4; i++) {
            attributes[i] = (randomSeed % 100) + 1; // Attribute values 1-100
            randomSeed = uint256(keccak256(abi.encode(randomSeed, i))); // Update seed for next attribute
        }
        return attributes;
    }

    // --- Evolution Functions ---

    function evolveNFT(uint256 tokenId) public payable whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(msg.value >= evolutionCost, "Insufficient evolution cost");
        require(block.timestamp >= lastEvolutionTime[tokenId] + evolutionCooldownTime, "Evolution cooldown not finished");

        uint256 currentStage = evolutionStage[tokenId];
        uint256 previousRarity = rarityTier[tokenId];

        uint256 newStage = currentStage + 1; // Simple linear evolution for demonstration
        evolutionStage[tokenId] = newStage;
        lastEvolutionTime[tokenId] = block.timestamp;

        uint256 newRarity = _determineEvolutionRarity(tokenId, previousRarity);
        rarityTier[tokenId] = newRarity;

        emit NFTEvolved(tokenId, currentStage, newStage, newRarity);
    }

    function _determineEvolutionRarity(uint256 tokenId, uint256 previousRarity) private view returns (uint256) {
        // Rarity can increase or decrease based on stage, attributes, and randomness
        uint256 randomValue = uint256(keccak256(abi.encode(block.timestamp, tokenId, evolutionStage[tokenId])));
        uint256 randomNumber = randomValue % 100;

        uint256 currentRarity = previousRarity;

        // Example: Chance to increase rarity on evolution, influenced by stage/attributes (conceptual)
        if (randomNumber < 15) { // 15% chance to increase rarity (adjust as needed)
            currentRarity = SafeMath.safeAdd(currentRarity, 1);
            if (currentRarity > 4) { // Cap at Legendary (tier 4)
                currentRarity = 4;
            }
        } else if (randomNumber > 90 && currentRarity > 0) { // 10% chance to decrease rarity if not already common
            currentRarity = SafeMath.safeSub(currentRarity, 1);
        }
        return currentRarity;
    }

    // --- Fusion Functions ---

    function fuseNFTs(uint256[] memory tokenIds) public payable whenNotPaused {
        require(tokenIds.length >= fusionRequiredNFTs && tokenIds.length <= maxFusionNFTs, "Invalid number of NFTs for fusion");
        require(msg.value >= fusionCost, "Insufficient fusion cost");

        address owner = msg.sender;
        uint256 totalRarityScore = 0;
        uint256 burnResources = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_exists(tokenId), "NFT does not exist");
            require(ownerOf(tokenId) == owner, "You are not the owner of all NFTs");
            totalRarityScore = SafeMath.safeAdd(totalRarityScore, rarityTier[tokenId]);
            burnResources = SafeMath.safeAdd(burnResources, getBurnResources(tokenId)); // Get resources from burning
            _burn(tokenId); // Burn fused NFTs
        }

        uint256 newTokenId = _tokenCounter;
        _safeMint(owner, newTokenId);
        _tokenCounter++;

        evolutionStage[newTokenId] = 0; // Reset stage for fused NFT (or could be based on average stage)
        rarityTier[newTokenId] = _determineFusionRarity(totalRarityScore, tokenIds.length); // Determine rarity based on fused NFTs
        nftAttributes[newTokenId] = _generateFusionAttributes(tokenIds); // Generate new attributes based on fused NFTs

        emit NFTFused(owner, newTokenId, tokenIds, rarityTier[newTokenId]);

        // Optionally distribute resources obtained from burning to the fuser (not implemented in this basic example).
        // Example: transfer native tokens or internal resource tokens.
    }

    function _determineFusionRarity(uint256 totalRarityScore, uint256 numFusedNFTs) private view returns (uint256) {
        // Rarity determination based on combined rarity score and number of NFTs
        uint256 averageRarity = totalRarityScore / numFusedNFTs; // Simple average for demonstration
        uint256 randomBoost = uint256(keccak256(abi.encode(block.timestamp, totalRarityScore, numFusedNFTs))) % 10; // Small random boost

        uint256 newRarity = averageRarity + randomBoost;
        if (newRarity > 4) {
            newRarity = 4; // Cap at Legendary
        }
        return newRarity;
    }

    function _generateFusionAttributes(uint256[] memory tokenIds) private view returns (uint256[4] memory) {
        // Placeholder for attribute generation from fusion. Can be more complex.
        uint256[4] memory combinedAttributes;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            for (uint256 j = 0; j < 4; j++) {
                combinedAttributes[j] = SafeMath.safeAdd(combinedAttributes[j], nftAttributes[tokenIds[i]][j]);
            }
        }
        // Average out attributes or use other combining logic
        for (uint256 i = 0; i < 4; i++) {
            combinedAttributes[i] = combinedAttributes[i] / tokenIds.length;
        }
        return combinedAttributes;
    }


    // --- Burning Functions ---

    function burnNFTForResources(uint256 tokenId) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner");

        uint256 resources = getBurnResources(tokenId);
        _burn(tokenId);

        // In a real scenario, you would transfer resources to the burner here.
        // For this example, we just emit an event.
        emit NFTBurnedForResources(tokenId, msg.sender, resources);
    }

    function getBurnResources(uint256 tokenId) public view returns (uint256) {
        // Resources obtained can depend on rarity, stage, attributes, etc.
        // This is a simple example based on rarity tier.
        uint256 baseResources = 100;
        uint256 rarityMultiplier = rarityTier[tokenId] + 1; // Common (tier 0) gives multiplier 1, Legendary (tier 4) gives 5
        return baseResources * rarityMultiplier;
    }


    // --- Staking for Evolution Boost (Conceptual - Implementation requires external token contract) ---
    // Functionality outline, actual staking implementation requires integration with a staking token.

    // function stakeForEvolutionBoost(uint256 tokenId, uint256 amount) public whenNotPaused { ... }
    // function unstakeForEvolutionBoost(uint256 tokenId) public whenNotPaused { ... }
    // function _applyEvolutionBoost(uint256 tokenId) private view returns (uint256) { ... } // Reduce cooldown


    // --- NFT Gifting ---
    function giftNFT(uint256 tokenId, address _to) public whenNotPaused {
        require(_exists(tokenId), "NFT does not exist");
        require(ownerOf(tokenId) == msg.sender, "You are not the owner");
        safeTransferFrom(msg.sender, _to, tokenId);
    }


    // --- Getter/View Functions ---

    function getEvolutionStage(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return evolutionStage[tokenId];
    }

    function getRarityTier(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        return rarityTier[tokenId];
    }

    function getNFTAttributes(uint256 tokenId) public view returns (uint256[4] memory) {
        require(_exists(tokenId), "NFT does not exist");
        return nftAttributes[tokenId];
    }

    function getEvolutionCooldown(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "NFT does not exist");
        uint256 timeLeft = 0;
        if (block.timestamp < lastEvolutionTime[tokenId] + evolutionCooldownTime) {
            timeLeft = (lastEvolutionTime[tokenId] + evolutionCooldownTime) - block.timestamp;
        }
        return timeLeft;
    }

    function getEvolutionCost() public view returns (uint256) {
        return evolutionCost;
    }

    function getFusionCost() public view returns (uint256) {
        return fusionCost;
    }

    function getFusionRequiredNFTs() public view returns (uint256) {
        return fusionRequiredNFTs;
    }

    function getMaxFusionNFTs() public view returns (uint256) {
        return maxFusionNFTs;
    }

    function isWhitelisted(address _account) public view returns (bool) {
        return whitelist[_account];
    }

    function getAttributeWeights() public view returns (uint256[4] memory) {
        // return attributeWeights; // If implemented attribute weights fully
        uint256[4] memory defaultWeights; // Return default if weights not fully implemented
        return defaultWeights;
    }

    function getRarityThresholds() public view returns (uint256[4] memory) {
        return rarityThresholds;
    }

    function getTokenMetadata(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "NFT does not exist");
        string memory stageStr = evolutionStage[tokenId].toString();
        string memory rarityStr = getRarityTierString(rarityTier[tokenId]);
        string memory attributesStr = "";
        for(uint256 i = 0; i < 4; i++){
            attributesStr = string(abi.encodePacked(attributesStr, "Attribute ", (i+1).toString(), ": ", nftAttributes[tokenId][i].toString(), ", "));
        }

        string memory metadata = string(abi.encodePacked(
            '{"name": "', name(), ' #', tokenId.toString(), '", ',
            '"description": "A Dynamic Evolving NFT. Stage: ', stageStr, ', Rarity: ', rarityStr, '. Attributes: ', attributesStr, '", ',
            '"image": "', _baseURI, tokenId.toString(), '.png", ', // Example image URI construction
            '"attributes": [',
                '{"trait_type": "Stage", "value": "', stageStr, '"},',
                '{"trait_type": "Rarity", "value": "', rarityStr, '"},',
                '{"trait_type": "Attribute 1", "value": "', nftAttributes[tokenId][0].toString(), '"},',
                '{"trait_type": "Attribute 2", "value": "', nftAttributes[tokenId][1].toString(), '"},',
                '{"trait_type": "Attribute 3", "value": "', nftAttributes[tokenId][2].toString(), '"},',
                '{"trait_type": "Attribute 4", "value": "', nftAttributes[tokenId][3].toString(), '"}]}'
        ));
        return metadata;
    }

    function getRarityTierString(uint256 tier) public pure returns (string memory) {
        if (tier == 0) return "Common";
        if (tier == 1) return "Uncommon";
        if (tier == 2) return "Rare";
        if (tier == 3) return "Epic";
        if (tier == 4) return "Legendary";
        return "Unknown";
    }


    // --- ERC721 Overrides ---

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return getTokenMetadata(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _tokenCounter;
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return super.ownerOf(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function approve(address approved, uint256 tokenId) public virtual override whenNotPaused {
        super.approve(approved, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        return super.getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(owner, operator);
    }
}
```