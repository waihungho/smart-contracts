Okay, here is a smart contract implementing an "Evolutionary NFT" concept. This contract represents NFTs whose attributes can change over time and based on interactions, potentially "evolving" through different stages.

It avoids simply using standard OpenZeppelin implementations directly by building the core ERC-721 logic internally, and focuses on the unique state-changing mechanics.

**Concept:** Evolutionary NFTs (E-NFTs)
These NFTs have core attributes (Strength, Speed, Intelligence, Adaptability) and metadata (Generation, Evolution Stage) that are not static. They can evolve or mutate based on rules, time elapsed, and interactions like "feeding". Each NFT has a unique "DNA" that influences its evolutionary path.

**Advanced/Trendy Concepts Used:**
1.  **Dynamic NFT Attributes:** State changes directly on-chain.
2.  **On-Chain Evolution/Mutation Logic:** Rules defined in the contract determine attribute changes.
3.  **DNA/Genome System:** A unique seed influencing evolution bias.
4.  **Lifecycle Stages:** NFTs progress through defined stages based on attributes.
5.  **Time-Based Mechanics:** Evolution requires time to pass.
6.  **Interaction-Based Mechanics:** "Feeding" the NFT affects its state and eligibility for evolution.
7.  **Rule-Based State Transitions:** Attribute changes governed by configurable rules.
8.  **Fee Collection:** Interactions like evolution/mutation can cost fees collected by the owner.
9.  **Basic Internal ERC-721 Implementation:** Avoiding external libraries for the core NFT standard (as requested not to duplicate open source libraries).
10. **Basic Access Control:** Owner-only functions for configuration.

---

**Outline and Function Summary:**

1.  **Contract Definition & State:**
    *   Inherits ERC165 (standard practice for interfaces).
    *   Defines `EvolutionaryNFTAttributes` struct.
    *   Defines `EvolutionRules` struct.
    *   Defines `MutationRules` struct.
    *   State variables for owner, token counter, mappings for ERC-721 data (`_owners`, `_balances`, `_tokenApprovals`, `_operatorApprovals`), mappings for NFT attributes (`_tokenAttributes`), rule structs, base URI, evolution stages, fees.
    *   Events for standard ERC-721 and unique evolution/mutation actions.

2.  **Access Control:**
    *   `constructor`: Sets contract owner.
    *   `onlyOwner` modifier: Restricts function calls to the owner.

3.  **ERC-165 Support:**
    *   `supportsInterface`: Declares support for ERC-721 and ERC-165 interfaces.

4.  **ERC-721 Core (Implemented Internally):**
    *   `balanceOf`: Get owner's token count.
    *   `ownerOf`: Get token's owner.
    *   `transferFrom`: Transfer token ownership.
    *   `safeTransferFrom` (2 variants): Safely transfer token ownership (checks receiver support).
    *   `approve`: Approve another address to transfer a specific token.
    *   `getApproved`: Get the approved address for a token.
    *   `setApprovalForAll`: Set operator approval for all tokens.
    *   `isApprovedForAll`: Check if an address is an approved operator.
    *   `_exists`: Internal helper to check if a token ID exists.
    *   `_requireOwned`: Internal helper to ensure sender owns token.
    *   `_approve`: Internal helper for setting approval.
    *   `_transfer`: Internal helper for transferring ownership.
    *   `_mint`: Internal helper for creating a new token.

5.  **Evolutionary NFT Specifics:**
    *   `tokenURI`: Get the metadata URI for a token (references dynamic state via base URI).
    *   `setBaseTokenURI`: Owner sets the base URI for metadata.
    *   `mintInitialNFT`: Mints a new E-NFT with generated DNA and initial attributes.
    *   `getNFTAttributes`: View function to retrieve current attributes of a token.
    *   `getDNA`: View function to retrieve the DNA of a token.
    *   `getEvolutionStage`: View function to get the current stage based on attributes.
    *   `feedNFT`: Allows owner to feed an NFT, costing ETH and incrementing feeding count.
    *   `triggerEvolution`: Allows owner to attempt evolving an NFT (checks cooldown, feeding, costs).
    *   `triggerMutation`: Allows owner to attempt mutating an NFT (checks cooldown, feeding, costs, higher randomness/risk).
    *   `_calculateEvolution`: Internal logic for deterministic evolution based on rules, DNA, and time.
    *   `_calculateMutation`: Internal logic for mutation (more random).
    *   `getEvolutionCooldown`: View function for time since last evolution attempt.
    *   `getTotalAttributeScore`: Internal helper to calculate the sum of core attributes.
    *   `_generateDNA`: Internal helper to generate a unique DNA sequence.

6.  **Rule Configuration (Owner Only):**
    *   `setEvolutionRules`: Sets parameters for the evolution process.
    *   `getEvolutionRules`: View function for current evolution rules.
    *   `setMutationRules`: Sets parameters for the mutation process.
    *   `getMutationRules`: View function for current mutation rules.
    *   `setBaseAttributeRange`: Sets the minimum and maximum range for initial attribute generation.
    *   `getBaseAttributeRange`: View function for initial attribute range.
    *   `setMaxGeneration`: Sets the maximum possible generation.
    *   `getMaxGeneration`: View function for max generation.
    *   `setStageThresholds`: Sets the score thresholds required for each evolution stage.
    *   `getStageThresholds`: View function for stage thresholds.
    *   `setFeedingCost`: Sets the ETH cost for feeding an NFT.
    *   `getFeedingCost`: View function for feeding cost.
    *   `setEvolutionCost`: Sets the ETH cost for triggering evolution.
    *   `getEvolutionCost`: View function for evolution cost.
    *   `setMutationCost`: Sets the ETH cost for triggering mutation.
    *   `getMutationCost`: View function for mutation cost.
    *   `setRequiredFeedingsForEvolution`: Sets how many feedings are needed per evolution attempt.
    *   `getRequiredFeedingsForEvolution`: View function for required feedings.
    *   `setTimeLockForEvolution`: Sets the minimum time required between evolution attempts.
    *   `getTimeLockForEvolution`: View function for time lock duration.

7.  **Fee Management (Owner Only):**
    *   `claimFees`: Allows the owner to withdraw collected ETH fees.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; // Not implemented fully, just interfaces
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol"; // Not implemented fully, just interfaces
import { ERC721TokenReceiver } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // Just interface reference
import { Address } from "@openzeppelin/contracts/utils/Address.sol"; // For isContract check

// Note: This contract implements ERC721 interfaces internally rather than inheriting
// full OpenZeppelin implementations, as per the user's request to avoid duplication.
// However, standard interfaces (IERC721, etc.) are used for compatibility and clarity.

contract EvolutionaryNFT is ERC165, IERC721, IERC721Metadata {

    using Address for address;

    // --- State Variables ---

    address private _owner; // Basic owner pattern
    uint256 private _nextTokenId; // Counter for new tokens
    string private _baseTokenURI; // Base URI for metadata

    // ERC-721 Data
    mapping(uint256 => address) private _owners; // Token ID to owner address
    mapping(address => uint256) private _balances; // Owner address to token count
    mapping(uint256 => address) private _tokenApprovals; // Token ID to approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Owner to operator approval

    // Evolutionary NFT Data
    struct EvolutionaryNFTAttributes {
        uint32 strength; // Core attribute 1
        uint32 speed;    // Core attribute 2
        uint32 intelligence; // Core attribute 3
        uint32 adaptability; // Core attribute 4
        uint32 rarityScore;  // Derived score based on attributes
        uint32 generation;   // How many times it evolved
        uint32 evolutionStage; // Current stage (Juvenile, Adult, etc.)
        uint256 lastEvolutionTime; // Timestamp of last evolution/mutation attempt
        uint32 currentFeedings; // Number of times fed since last evolution/mutation
        bytes32 dna;         // Unique genetic code influencing evolution
    }

    mapping(uint256 => EvolutionaryNFTAttributes) private _tokenAttributes;

    // Evolution and Mutation Rules (Configurable by Owner)
    struct EvolutionRules {
        uint32 attributeIncreaseMin; // Min points gained per attribute on evolution
        uint32 attributeIncreaseMax; // Max points gained per attribute on evolution
        uint256 timeLockDuration;   // Min time in seconds between evolution attempts
        uint32 requiredFeedings;    // How many feedings are needed per attempt
        uint256 evolutionCost;      // ETH cost to trigger evolution
    }
    EvolutionRules public evolutionRules;

    struct MutationRules {
        uint32 attributeChangeMin;  // Min points changed (can be negative)
        uint32 attributeChangeMax;  // Max points changed (can be negative)
        uint32 rarityChangeMin;     // Min rarity score change
        uint32 rarityChangeMax;     // Max rarity score change
        uint16 mutationProbability; // Probability out of 10000 (e.g., 100 = 1%)
        uint256 mutationCost;       // ETH cost to trigger mutation
    }
    MutationRules public mutationRules;

    struct AttributeRange {
        uint32 min;
        uint32 max;
    }
    mapping(uint8 => AttributeRange) public baseAttributeRange; // 0: Strength, 1: Speed, 2: Intelligence, 3: Adaptability

    uint32 public maxGeneration = 10; // Max possible generation
    mapping(uint32 => uint32) public evolutionStageThresholds; // Stage -> Min total attribute score

    uint256 public feedingCost = 0.001 ether; // ETH cost to feed

    // Collected fees
    uint256 private _collectedFees;

    // --- Events ---

    event EvolutionTriggered(uint256 indexed tokenId, uint32 oldGeneration, uint32 newGeneration, uint32 oldStage, uint32 newStage, uint32 oldRarity, uint32 newRarity);
    event MutationTriggered(uint256 indexed tokenId, uint32 oldGeneration, uint32 newGeneration, uint32 oldStage, uint32 newStage, uint32 oldRarity, uint32 newRarity);
    event AttributesChanged(uint256 indexed tokenId, uint32 strength, uint32 speed, uint32 intelligence, uint32 adaptability, uint32 rarityScore);
    event FeedingReceived(uint256 indexed tokenId, address indexed feeder, uint256 amount, uint32 newFeedingCount);
    event FeeClaimed(address indexed receiver, uint256 amount);

    // ERC-721 Standard Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // --- Access Control ---

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not contract owner");
        _;
    }

    constructor() ERC165() {
        _owner = msg.sender;
        _nextTokenId = 0;

        // Initialize default rules (can be changed by owner)
        evolutionRules = EvolutionRules({
            attributeIncreaseMin: 5,
            attributeIncreaseMax: 20,
            timeLockDuration: 1 days, // 1 day cooldown
            requiredFeedings: 3,      // Needs 3 feedings
            evolutionCost: 0.01 ether // Costs 0.01 ETH
        });

        mutationRules = MutationRules({
            attributeChangeMin: 1,
            attributeChangeMax: 50, // Larger range for bigger changes
            rarityChangeMin: 10,
            rarityChangeMax: 100,
            mutationProbability: 500, // 5% chance
            mutationCost: 0.02 ether // Costs 0.02 ETH
        });

        // Default base attribute ranges (e.g., 1-10 for initial mint)
        baseAttributeRange[0] = AttributeRange({min: 1, max: 10}); // Strength
        baseAttributeRange[1] = AttributeRange({min: 1, max: 10}); // Speed
        baseAttributeRange[2] = AttributeRange({min: 1, max: 10}); // Intelligence
        baseAttributeRange[3] = AttributeRange({min: 1, max: 10}); // Adaptability

        // Default stage thresholds (example: Juvenile < 50, Adult < 100, Mature < 150, Legendary >= 150)
        evolutionStageThresholds[0] = 0;   // Stage 0 (Hatchling/Juvenile) - always starts here
        evolutionStageThresholds[1] = 50;  // Stage 1 (Adult)
        evolutionStageThresholds[2] = 100; // Stage 2 (Mature)
        evolutionStageThresholds[3] = 150; // Stage 3 (Legendary)
        // Add more stages/thresholds as needed

        _registerInterface(type(IERC721).interfaceId);
        _registerInterface(type(IERC721Metadata).interfaceId);
        // _registerInterface(type(IERC721Enumerable).interfaceId); // Not implementing enumerable
    }

    // --- ERC-165 Standard ---

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId ||
               // interfaceId == type(IERC721Enumerable).interfaceId || // If Enumerable implemented
               super.supportsInterface(interfaceId);
    }

    // --- ERC-721 Core Implementation (Internal) ---

    /// @dev See {IERC721-balanceOf}.
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /// @dev See {IERC721-ownerOf}.
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /// @dev See {IERC721-approve}.
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    /// @dev See {IERC721-getApproved}.
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    /// @dev See {IERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev See {IERC721-isApprovedForAll}.
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @dev See {IERC721-transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @dev See {IERC721-safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /// @dev Returns whether the specified token exists.
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /// @dev Throws if the token ID is not owned by the caller.
    function _requireOwned(uint256 tokenId) internal view virtual {
        require(ownerOf(tokenId) == msg.sender, "ERC721: caller is not token owner");
    }

    /// @dev Approve `to` to operate on `tokenId`
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /// @dev Returns whether `spender` is allowed to manage `tokenId`.
    ///     Requirements:
    ///
    ///     - `tokenId` must exist.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /// @dev Internal function to transfer ownership of a given token ID to a different address.
    ///     Requires the token ID to exist.
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _approve(address(0), tokenId); // Clear approval

        _balances[from] -= 1;
        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal function to safely transfer ownership of a given token ID to a different address.
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
         _transfer(from, to, tokenId);
         require(to.isContract() ? _checkOnERC721Received(from, to, tokenId, data) : true, "ERC721: transfer to non ERC721Receiver implementer");
    }

     /// @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     ///     Returns whether the target address accepted the transfer.
     function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
         try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
             return retval == ERC721TokenReceiver.onERC721Received.selector;
         } catch (bytes memory reason) {
             if (reason.length == 0) {
                 revert("ERC721: transfer to non ERC721Receiver implementer");
             } else {
                 /// @solidity from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/token/ERC721/ERC721.sol
                 assembly {
                     revert(add(32, reason), mload(reason))
                 }
             }
         }
     }


    /// @dev Internal function to create a new token and assign it to `to`.
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;
        _tokenAttributes[tokenId].generation = 0; // Start at generation 0
        _tokenAttributes[tokenId].evolutionStage = 0; // Start at stage 0
        _tokenAttributes[tokenId].lastEvolutionTime = block.timestamp; // Initialize last evolution time
        _tokenAttributes[tokenId].currentFeedings = 0; // Initialize feedings

        emit Transfer(address(0), to, tokenId);
    }

    // --- Metadata (ERC-721Metadata) ---

    /// @dev See {IERC721Metadata-name}.
    function name() public view virtual override returns (string memory) {
        return "EvolutionaryNFT";
    }

    /// @dev See {IERC721Metadata-symbol}.
    function symbol() public view virtual override returns (string memory) {
        return "ENFT";
    }

    /// @dev See {IERC721Metadata-tokenURI}.
    /// @dev Returns the URI for metadata of token with id `tokenId`.
    /// The metadata JSON should reference the current on-chain attributes.
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // Return base URI + token ID. A metadata server will serve dynamic JSON.
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(tokenId)));
    }

    /// @dev Owner sets the base URI for token metadata.
    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    // --- Evolutionary NFT Specific Functions ---

    /// @dev Mints a new Evolutionary NFT with initial attributes and DNA.
    function mintInitialNFT(address to) public onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _mint(to, tokenId);

        // Generate DNA
        _tokenAttributes[tokenId].dna = _generateDNA(tokenId);

        // Generate initial attributes within defined range
        uint256 seed = uint256(_tokenAttributes[tokenId].dna) ^ block.timestamp ^ block.number ^ tokenId; // Add some entropy
        uint32 strength = uint32(_getRandomValue(seed, baseAttributeRange[0].min, baseAttributeRange[0].max));
        seed = uint256(keccak256(abi.encodePacked(seed, strength)));
        uint32 speed = uint32(_getRandomValue(seed, baseAttributeRange[1].min, baseAttributeRange[1].max));
        seed = uint256(keccak256(abi.encodePacked(seed, speed)));
        uint32 intelligence = uint32(_getRandomValue(seed, baseAttributeRange[2].min, baseAttributeRange[2].max));
        seed = uint256(keccak256(abi.encodePacked(seed, intelligence)));
        uint32 adaptability = uint32(_getRandomValue(seed, baseAttributeRange[3].min, baseAttributeRange[3].max));

        _tokenAttributes[tokenId].strength = strength;
        _tokenAttributes[tokenId].speed = speed;
        _tokenAttributes[tokenId].intelligence = intelligence;
        _tokenAttributes[tokenId].adaptability = adaptability;

        // Calculate initial rarity and stage
        _tokenAttributes[tokenId].rarityScore = _calculateRarityScore(tokenId);
        _tokenAttributes[tokenId].evolutionStage = _calculateEvolutionStage(tokenId);

        emit AttributesChanged(tokenId, strength, speed, intelligence, adaptability, _tokenAttributes[tokenId].rarityScore);
    }

    /// @dev Gets the current attributes of a given NFT.
    function getNFTAttributes(uint256 tokenId) public view returns (EvolutionaryNFTAttributes memory) {
        require(_exists(tokenId), "ENFT: query for nonexistent token attributes");
        return _tokenAttributes[tokenId];
    }

    /// @dev Gets the DNA of a given NFT.
    function getDNA(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "ENFT: query for nonexistent token DNA");
        return _tokenAttributes[tokenId].dna;
    }

    /// @dev Gets the evolution stage of a given NFT based on its current attributes.
    function getEvolutionStage(uint256 tokenId) public view returns (uint32) {
        require(_exists(tokenId), "ENFT: query for nonexistent token stage");
        return _calculateEvolutionStage(tokenId);
    }

    /// @dev Allows the token owner to feed the NFT, costing ETH and potentially enabling evolution.
    /// @param tokenId The ID of the NFT to feed.
    function feedNFT(uint256 tokenId) public payable {
        _requireOwned(tokenId);
        require(msg.value >= feedingCost, "ENFT: Insufficient ETH to feed");

        _collectedFees += msg.value;
        _tokenAttributes[tokenId].currentFeedings += 1;

        emit FeedingReceived(tokenId, msg.sender, msg.value, _tokenAttributes[tokenId].currentFeedings);
    }

    /// @dev Allows the token owner to attempt to evolve their NFT.
    /// Requires sufficient time elapsed, required feedings, and ETH cost.
    /// @param tokenId The ID of the NFT to evolve.
    function triggerEvolution(uint256 tokenId) public payable {
        _requireOwned(tokenId);
        require(_tokenAttributes[tokenId].generation < maxGeneration, "ENFT: Max generation reached");
        require(block.timestamp >= _tokenAttributes[tokenId].lastEvolutionTime + evolutionRules.timeLockDuration, "ENFT: Evolution time lock not elapsed");
        require(_tokenAttributes[tokenId].currentFeedings >= evolutionRules.requiredFeedings, "ENFT: Not enough feedings");
        require(msg.value >= evolutionRules.evolutionCost, "ENFT: Insufficient ETH for evolution cost");

        _collectedFees += msg.value;
        uint32 oldGeneration = _tokenAttributes[tokenId].generation;
        uint32 oldStage = _tokenAttributes[tokenId].evolutionStage;
        uint32 oldRarity = _tokenAttributes[tokenId].rarityScore;

        _tokenAttributes[tokenId].generation += 1;
        _calculateEvolution(tokenId); // Apply evolution logic
        _tokenAttributes[tokenId].rarityScore = _calculateRarityScore(tokenId); // Recalculate rarity
        _tokenAttributes[tokenId].evolutionStage = _calculateEvolutionStage(tokenId); // Recalculate stage

        _tokenAttributes[tokenId].lastEvolutionTime = block.timestamp; // Reset time lock
        _tokenAttributes[tokenId].currentFeedings = 0; // Reset feedings

        emit EvolutionTriggered(
            tokenId,
            oldGeneration, _tokenAttributes[tokenId].generation,
            oldStage, _tokenAttributes[tokenId].evolutionStage,
            oldRarity, _tokenAttributes[tokenId].rarityScore
        );

        emit AttributesChanged(
            tokenId,
            _tokenAttributes[tokenId].strength,
            _tokenAttributes[tokenId].speed,
            _tokenAttributes[tokenId].intelligence,
            _tokenAttributes[tokenId].adaptability,
            _tokenAttributes[tokenId].rarityScore
        );
    }

    /// @dev Allows the token owner to attempt to mutate their NFT.
    /// Mutation is less predictable than evolution.
    /// Requires sufficient time elapsed, required feedings, and ETH cost.
    /// @param tokenId The ID of the NFT to mutate.
    function triggerMutation(uint256 tokenId) public payable {
        _requireOwned(tokenId);
         require(_tokenAttributes[tokenId].generation < maxGeneration, "ENFT: Max generation reached");
        require(block.timestamp >= _tokenAttributes[tokenId].lastEvolutionTime + evolutionRules.timeLockDuration, "ENFT: Mutation time lock not elapsed"); // Uses same time lock
        require(_tokenAttributes[tokenId].currentFeedings >= evolutionRules.requiredFeedings, "ENFT: Not enough feedings"); // Uses same feeding requirement
        require(msg.value >= mutationRules.mutationCost, "ENFT: Insufficient ETH for mutation cost");

        _collectedFees += msg.value;
        uint32 oldGeneration = _tokenAttributes[tokenId].generation;
        uint32 oldStage = _tokenAttributes[tokenId].evolutionStage;
        uint32 oldRarity = _tokenAttributes[tokenId].rarityScore;

        // Apply mutation logic (probabilistic)
        uint256 seed = uint256(_tokenAttributes[tokenId].dna) ^ block.timestamp ^ block.number ^ tokenId ^ uint256(keccak256(abi.encodePacked(msg.sender)));
        uint16 mutationRoll = uint16(_getRandomValue(seed, 0, 9999)); // Roll between 0 and 9999

        if (mutationRoll < mutationRules.mutationProbability) {
             _tokenAttributes[tokenId].generation += 1; // Mutation also advances generation
            _calculateMutation(tokenId, seed); // Apply mutation logic
            _tokenAttributes[tokenId].rarityScore = _calculateRarityScore(tokenId); // Recalculate rarity
            _tokenAttributes[tokenId].evolutionStage = _calculateEvolutionStage(tokenId); // Recalculate stage

             emit MutationTriggered(
                tokenId,
                oldGeneration, _tokenAttributes[tokenId].generation,
                oldStage, _tokenAttributes[tokenId].evolutionStage,
                oldRarity, _tokenAttributes[tokenId].rarityScore
            );
            emit AttributesChanged(
                tokenId,
                _tokenAttributes[tokenId].strength,
                _tokenAttributes[tokenId].speed,
                _tokenAttributes[tokenId].intelligence,
                _tokenAttributes[tokenId].adaptability,
                _tokenAttributes[tokenId].rarityScore
            );
        }
         // else: Mutation attempt failed, nothing changes except fees paid and cooldown reset

        _tokenAttributes[tokenId].lastEvolutionTime = block.timestamp; // Reset time lock regardless of success
        _tokenAttributes[tokenId].currentFeedings = 0; // Reset feedings

         // Emit an event even if mutation failed, to log the attempt? Optional.
         // emit MutationAttempted(tokenId, success: mutationRoll < mutationRules.mutationProbability);
    }

    /// @dev Internal function to calculate attribute changes based on evolution rules and DNA.
    function _calculateEvolution(uint256 tokenId) internal {
        EvolutionaryNFTAttributes storage attributes = _tokenAttributes[tokenId];
        uint256 seed = uint256(attributes.dna) ^ block.timestamp ^ block.number ^ tokenId; // Seed based on DNA and current block data

        // Simple attribute increase based on rules and a bit of DNA bias
        uint32 strengthIncrease = uint32(_getRandomValue(seed, evolutionRules.attributeIncreaseMin, evolutionRules.attributeIncreaseMax));
        seed = uint256(keccak256(abi.encodePacked(seed, strengthIncrease)));
        uint32 speedIncrease = uint32(_getRandomValue(seed, evolutionRules.attributeIncreaseMin, evolutionRules.attributeIncreaseMax));
        seed = uint256(keccak256(abi.encodePacked(seed, speedIncrease)));
        uint32 intelligenceIncrease = uint32(_getRandomValue(seed, evolutionRules.attributeIncreaseMin, evolutionRules.attributeIncreaseMax));
        seed = uint256(keccak256(abi.encodePacked(seed, intelligenceIncrease)));
        uint32 adaptabilityIncrease = uint32(_getRandomValue(seed, evolutionRules.attributeIncreaseMin, evolutionRules.attributeIncreaseMax));

        // DNA bias could influence which attribute gets *more* increase
        // Example: DNA byte influences attribute bias (simplified)
        uint8 biasAttribute = uint8(attributes.dna[0]) % 4; // 0=Str, 1=Spd, 2=Int, 3=Ada
        uint32 biasAmount = uint32(_getRandomValue(seed, 0, evolutionRules.attributeIncreaseMax / 2)); // Add extra points based on bias

        if (biasAttribute == 0) strengthIncrease += biasAmount;
        else if (biasAttribute == 1) speedIncrease += biasAmount;
        else if (biasAttribute == 2) intelligenceIncrease += biasAmount;
        else adaptabilityIncrease += biasAmount;


        attributes.strength += strengthIncrease;
        attributes.speed += speedIncrease;
        attributes.intelligence += intelligenceIncrease;
        attributes.adaptability += adaptabilityIncrease;

        // Optional: Cap attributes at a certain max value if needed
        // attributes.strength = Math.min(attributes.strength, MAX_ATTRIBUTE_VALUE);
    }

    /// @dev Internal function to calculate attribute changes based on mutation rules and DNA.
    function _calculateMutation(uint256 tokenId, uint256 seed) internal {
        EvolutionaryNFTAttributes storage attributes = _tokenAttributes[tokenId];

        // Mutation can increase or decrease attributes more drastically
        int32 strengthChange = int32(_getRandomValue(seed, mutationRules.attributeChangeMin, mutationRules.attributeChangeMax));
        seed = uint256(keccak256(abi.encodePacked(seed, strengthChange)));
        int32 speedChange = int32(_getRandomValue(seed, mutationRules.attributeChangeMin, mutationRules.attributeChangeMax));
        seed = uint256(keccak256(abi.encodePacked(seed, speedChange)));
        int32 intelligenceChange = int32(_getRandomValue(seed, mutationRules.attributeChangeMin, mutationRules.attributeChangeMax));
        seed = uint256(keccak256(abi.encodePacked(seed, intelligenceChange)));
        int32 adaptabilityChange = int32(_getRandomValue(seed, mutationRules.attributeChangeMin, mutationRules.attributeChangeMax));
         seed = uint256(keccak256(abi.encodePacked(seed, adaptabilityChange)));
        int32 rarityChange = int32(_getRandomValue(seed, mutationRules.rarityChangeMin, mutationRules.rarityChangeMax));


        // Apply changes, ensuring attributes don't go below 0 (or a min floor)
        attributes.strength = uint32(int32(attributes.strength) + strengthChange > 0 ? int32(attributes.strength) + strengthChange : 0);
        attributes.speed = uint32(int32(attributes.speed) + speedChange > 0 ? int32(attributes.speed) + speedChange : 0);
        attributes.intelligence = uint32(int32(attributes.intelligence) + intelligenceChange > 0 ? int32(attributes.intelligence) + intelligenceChange : 0);
        attributes.adaptability = uint32(int32(attributes.adaptability) + adaptabilityChange > 0 ? int32(attributes.adaptability) + adaptabilityChange : 0);
        attributes.rarityScore = uint32(int32(attributes.rarityScore) + rarityChange > 0 ? int32(attributes.rarityScore) + rarityChange : 0);

        // DNA might influence mutation bias too
         uint8 biasAttribute = uint8(attributes.dna[1]) % 4; // Use a different part of DNA for mutation bias
        int32 biasAmount = int32(_getRandomValue(seed, mutationRules.attributeChangeMin / 2, mutationRules.attributeChangeMax / 2)); // Add/subtract extra

        if (biasAttribute == 0) attributes.strength = uint32(int32(attributes.strength) + biasAmount > 0 ? int32(attributes.strength) + biasAmount : 0);
        else if (biasAttribute == 1) attributes.speed = uint32(int32(attributes.speed) + biasAmount > 0 ? int32(attributes.speed) + biasAmount : 0);
        else if (biasAttribute == 2) attributes.intelligence = uint32(int32(attributes.intelligence) + biasAmount > 0 ? int32(attributes.intelligence) + biasAmount : 0);
        else attributes.adaptability = uint32(int32(attributes.adaptability) + biasAmount > 0 ? int32(attributes.adaptability) + biasAmount : 0);

    }

    /// @dev Gets the time elapsed since the last evolution/mutation attempt.
    /// @param tokenId The ID of the NFT.
    /// @return The time elapsed in seconds.
    function getEvolutionCooldown(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "ENFT: query for nonexistent token cooldown");
        uint256 lastTime = _tokenAttributes[tokenId].lastEvolutionTime;
        if (block.timestamp <= lastTime) return 0; // Should not happen usually, handles edge cases
        return block.timestamp - lastTime;
    }

    /// @dev Internal helper to calculate the total sum of core attributes.
    function _getTotalAttributeScore(uint256 tokenId) internal view returns (uint32) {
         EvolutionaryNFTAttributes storage attributes = _tokenAttributes[tokenId];
         return attributes.strength + attributes.speed + attributes.intelligence + attributes.adaptability;
    }

     /// @dev Internal helper to calculate the rarity score based on attributes.
     /// (Simple sum for now, could be more complex later)
    function _calculateRarityScore(uint256 tokenId) internal view returns (uint32) {
         return _getTotalAttributeScore(tokenId); // Rarity is sum of attributes
     }


    /// @dev Internal helper to determine the evolution stage based on total attributes.
    function _calculateEvolutionStage(uint256 tokenId) internal view returns (uint32) {
        uint32 totalScore = _getTotalAttributeScore(tokenId);
        uint32 stage = 0;
        // Iterate through defined thresholds to find the highest stage reached
        for (uint32 i = 0; i <= 10; i++) { // Max stages + a buffer
            if (evolutionStageThresholds[i] > 0 && totalScore >= evolutionStageThresholds[i]) {
                stage = i;
            } else if (evolutionStageThresholds[i] == 0 && i == 0) {
                 // Stage 0 threshold is 0, always at least stage 0
                 stage = 0;
            } else if (evolutionStageThresholds[i] == 0 && i > 0) {
                // Stop if we hit an unset threshold > 0
                 break;
            }
        }
        return stage;
    }

    /// @dev Internal helper to generate a unique DNA for a new NFT.
    /// @param tokenId The ID of the new token.
    /// @return bytes32 representing the DNA.
    function _generateDNA(uint256 tokenId) internal view returns (bytes32) {
        // Combine block data, token ID, and minter address for a unique seed
        return keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.coinbase, block.number, msg.sender, tokenId, _nextTokenId));
    }

    /// @dev Internal helper for pseudorandom number generation.
    /// NOTE: Using block data for randomness is susceptible to miner manipulation.
    /// For true randomness, integrate with an oracle like Chainlink VRF.
    function _getRandomValue(uint256 seed, uint32 min, uint32 max) internal pure returns (uint256) {
        if (min >= max) return min;
        uint256 value = uint256(keccak256(abi.encodePacked(seed)));
        return value % (max - min + 1) + min;
    }

    // --- Owner Configuration Functions ---

    /// @dev Owner sets the evolution rules.
    function setEvolutionRules(uint32 _attributeIncreaseMin, uint32 _attributeIncreaseMax, uint256 _timeLockDuration, uint32 _requiredFeedings, uint256 _evolutionCost) public onlyOwner {
        evolutionRules = EvolutionRules({
            attributeIncreaseMin: _attributeIncreaseMin,
            attributeIncreaseMax: _attributeIncreaseMax,
            timeLockDuration: _timeLockDuration,
            requiredFeedings: _requiredFeedings,
            evolutionCost: _evolutionCost
        });
    }

    /// @dev Owner sets the mutation rules.
    function setMutationRules(uint32 _attributeChangeMin, uint32 _attributeChangeMax, uint32 _rarityChangeMin, uint32 _rarityChangeMax, uint16 _mutationProbability, uint256 _mutationCost) public onlyOwner {
        mutationRules = MutationRules({
            attributeChangeMin: _attributeChangeMin,
            attributeChangeMax: _attributeChangeMax,
            rarityChangeMin: _rarityChangeMin,
            rarityChangeMax: _rarityChangeMax,
            mutationProbability: _mutationProbability,
            mutationCost: _mutationCost
        });
         require(mutationRules.mutationProbability <= 10000, "Mutation probability out of 10000");
    }

     /// @dev Owner sets the initial attribute range for new mints.
     function setBaseAttributeRange(uint8 attributeIndex, uint32 min, uint32 max) public onlyOwner {
         require(attributeIndex < 4, "Invalid attribute index");
         require(min <= max, "Min must be less than or equal to max");
         baseAttributeRange[attributeIndex] = AttributeRange({min: min, max: max});
     }

     /// @dev Owner sets the maximum possible generation an NFT can reach.
     function setMaxGeneration(uint32 _maxGeneration) public onlyOwner {
         maxGeneration = _maxGeneration;
     }

     /// @dev Owner sets the total attribute score thresholds for evolution stages.
     /// Stage 0 is always 0. Index corresponds to stage number.
     function setStageThresholds(uint32 stage, uint32 threshold) public onlyOwner {
         require(stage > 0, "Cannot set threshold for stage 0 (it's always 0)");
         evolutionStageThresholds[stage] = threshold;
     }

    /// @dev Owner sets the ETH cost for feeding an NFT.
    function setFeedingCost(uint256 _feedingCost) public onlyOwner {
        feedingCost = _feedingCost;
    }

    /// @dev Owner sets the ETH cost for triggering evolution.
    function setEvolutionCost(uint256 _evolutionCost) public onlyOwner {
         evolutionRules.evolutionCost = _evolutionCost;
    }

     /// @dev Owner sets the ETH cost for triggering mutation.
    function setMutationCost(uint256 _mutationCost) public onlyOwner {
        mutationRules.mutationCost = _mutationCost;
    }

     /// @dev Owner sets the number of feedings required per evolution/mutation attempt.
    function setRequiredFeedingsForEvolution(uint32 _requiredFeedings) public onlyOwner {
        evolutionRules.requiredFeedings = _requiredFeedings;
    }

    /// @dev Owner sets the minimum time (in seconds) between evolution/mutation attempts.
    function setTimeLockForEvolution(uint256 _timeLockDuration) public onlyOwner {
         evolutionRules.timeLockDuration = _timeLockDuration;
    }

    /// @dev Gets the feeding cost.
    function getFeedingCost() public view returns (uint256) {
        return feedingCost;
    }

    /// @dev Gets the evolution cost.
     function getEvolutionCost() public view returns (uint256) {
         return evolutionRules.evolutionCost;
     }

     /// @dev Gets the mutation cost.
     function getMutationCost() public view returns (uint256) {
         return mutationRules.mutationCost;
     }

     /// @dev Gets the required feedings for evolution/mutation.
     function getRequiredFeedingsForEvolution() public view returns (uint32) {
         return evolutionRules.requiredFeedings;
     }

     /// @dev Gets the time lock duration for evolution/mutation.
     function getTimeLockForEvolution() public view returns (uint256) {
         return evolutionRules.timeLockDuration;
     }


    // --- Fee Management ---

    /// @dev Owner can claim collected fees.
    function claimFees() public onlyOwner {
        uint256 amount = _collectedFees;
        require(amount > 0, "ENFT: No fees to claim");
        _collectedFees = 0;
        payable(msg.sender).transfer(amount);
        emit FeeClaimed(msg.sender, amount);
    }

    /// @dev Fallback function to collect ETH sent without calling a specific function (optional, but good for collecting fees).
    receive() external payable {
        _collectedFees += msg.value;
    }

    // --- Internal Libraries (Simplified/Built-in) ---
    // In a real contract, you'd likely import safe math, string conversions etc.
    // Added a basic toString for tokenURI compatibility

    library Strings {
        function toString(uint256 value) internal pure returns (string memory) {
            // From OpenZeppelin Contracts, simplified
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
                digits--;
                buffer[digits] = bytes1(uint8(48 + value % 10));
                value /= 10;
            }
            return string(buffer);
        }
    }
}
```