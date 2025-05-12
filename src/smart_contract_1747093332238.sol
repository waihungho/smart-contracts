Okay, here is a Solidity smart contract for "Evolutionary NFTs". This concept involves NFTs that have on-chain genetic traits that can evolve over time, through user interactions (like feeding/nurturing), or by breeding with other NFTs. The metadata is dynamically generated on-chain based on the current state of the NFT's traits.

This contract aims for complexity by including:
*   **On-chain Traits/Genes:** Stored directly in the contract state.
*   **Time-Based Evolution/Decay:** Traits change based on elapsed time.
*   **Interaction-Based Evolution:** User actions influence traits.
*   **Breeding Mechanism:** Creating new NFTs by combining parent genes.
*   **Dynamic On-Chain Metadata:** `tokenURI` computes metadata based on current traits.
*   **Pseudo-Randomness:** Used for mutations and initial traits (with standard caveats).
*   **Parameterization:** Admin functions to adjust evolution mechanics.

It will implement the `ERC721` interface manually to avoid copying a standard implementation directly, while still being compliant. It also implements `ERC165`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // For safeTransferFrom data

// --- Outline ---
// 1. Contract Definition and Interfaces
// 2. Error Definitions
// 3. Event Definitions
// 4. Struct Definitions (EvolutionaryGene)
// 5. State Variables (for ERC721, Genes, Parameters)
// 6. Constructor (Initialize owner, initial parameters)
// 7. ERC721 Standard Functions (Manual Implementation)
//    - balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll
//    - transferFrom, safeTransferFrom (overloaded)
//    - supportsInterface (for ERC721 and ERC165)
// 8. Core Evolutionary Logic Functions
//    - getGene (view current genes)
//    - evolve (trigger evolution based on time, interaction, randomness)
//    - feed (user interaction to counter decay and boost traits)
//    - breed (create new NFT from two parents)
//    - mutate (force a random mutation - potentially costly/rare)
//    - getTraitValue (view a specific trait)
//    - getAge (calculate NFT age)
//    - predictEvolution (simulate evolution without state change)
// 9. Lifecycle Management
//    - mintRandom (mint new NFT with random genes)
//    - mintWithGenes (owner mint with specific genes)
//    - burn (destroy an NFT)
// 10. Dynamic Metadata
//    - tokenURI (generate metadata JSON string on-chain)
// 11. Admin/Parameter Functions (Ownable)
//    - setBaseGeneTemplate, setEvolutionRate, setMutationChance, setTraitDecayRate
//    - setMinMaxTraitValue, setBreedingFee
//    - withdraw (collect breeding fees)
// 12. Internal Helper Functions
//    - _mint, _burn, _transfer (ERC721 internals)
//    - _isApprovedOrForAll (ERC721 internal helper)
//    - _updateGene (apply trait changes)
//    - _applyAgingAndDecay (apply time-based changes)
//    - _applyMutation (apply random mutation)
//    - _generateChildGenes (breeding logic)
//    - _clampTrait (keep trait values within bounds)
//    - _random (pseudo-random number generator)
//    - _toString (helper for tokenURI)

contract EvolutionaryNFTs is Context, ERC165, IERC721 {

    // --- Function Summary ---
    // ERC721 Core:
    // balanceOf(address): Get NFT count for an address.
    // ownerOf(uint256): Get owner of a specific NFT.
    // transferFrom(address,address,uint256): Transfer NFT (non-safe).
    // safeTransferFrom(address,address,uint256): Transfer NFT safely (no data).
    // safeTransferFrom(address,address,uint256,bytes): Transfer NFT safely (with data).
    // approve(address,uint256): Approve an address to transfer an NFT.
    // getApproved(uint256): Get the approved address for an NFT.
    // setApprovalForAll(address,bool): Set operator approval for all NFTs of sender.
    // isApprovedForAll(address,address): Check if an operator is approved for an owner.
    // supportsInterface(bytes4): Check if contract supports an interface (ERC721, ERC165).
    // tokenURI(uint256): Get dynamic on-chain metadata URI for an NFT.

    // Evolutionary Logic:
    // getGene(uint256): Retrieve the full gene struct for an NFT.
    // evolve(uint256): Trigger the evolution process for an NFT based on time and parameters.
    // feed(uint256): Interact with an NFT to apply positive trait changes and reset decay timer.
    // breed(uint256, uint256): Combine two parent NFTs to mint a new offspring NFT.
    // mutate(uint256): Force a probabilistic mutation event on an NFT (owner only or costly).
    // getTraitValue(uint256,uint8): Get the value of a specific trait index for an NFT.
    // getAge(uint256): Calculate the current age of an NFT in seconds or blocks.
    // predictEvolution(uint256): Simulate the next evolution step for an NFT without changing state.

    // Lifecycle Management:
    // mintRandom(address): Mint a new NFT to an address with randomly generated initial traits.
    // mintWithGenes(address,uint8[]): Owner-only function to mint an NFT with specified initial traits.
    // burn(uint256): Destroy an NFT.

    // Admin Functions (Ownable):
    // setBaseGeneTemplate(uint8[]): Set the template for new NFT genes.
    // setEvolutionRate(uint16): Set the rate at which traits evolve over time/interaction.
    // setMutationChance(uint16): Set the base probability for mutations (per trait).
    // setTraitDecayRate(uint16): Set the rate at which traits decay if not interacted with.
    // setMinMaxTraitValue(uint8,uint8): Set the minimum and maximum allowed values for traits.
    // setBreedingFee(uint256): Set the ETH fee required to breed two NFTs.
    // withdraw(): Withdraw collected breeding fees (ETH).

    // --- Error Definitions ---
    error InvalidRecipient();
    error TokenDoesNotExist();
    error NotOwnerOrApproved();
    error ApprovalForSelf();
    error BreedingFeeNotMet();
    error InsufficientGenesForBreeding();
    error CannotBreedWithSelf();
    error CannotBreedBurned();
    error InvalidTraitIndex();
    error InvalidTraitTemplate();
    error InvalidTraitValue(uint8 value, uint8 min, uint8 max);
    error InvalidTraitBounds();

    // --- Event Definitions ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Evolved(uint256 indexed tokenId, uint256 blockTimestamp, uint8[] newTraits);
    event Bred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, uint8[] childTraits);
    event Mutated(uint256 indexed tokenId, uint8 traitIndex, uint8 oldValue, uint8 newValue);
    event Fed(uint256 indexed tokenId, uint256 blockTimestamp, uint8[] newTraits);
    event Burned(uint256 indexed tokenId);

    // --- Struct Definitions ---
    struct EvolutionaryGene {
        uint8[] traits;          // Array of trait values (0-255)
        uint48 birthTimestamp;   // Timestamp when minted (approximate)
        uint256 generation;      // Generation number (0 for initial mints, increases with breeding)
        uint8 breedingCount;     // How many times this NFT has been used for breeding
        uint48 lastInteraction; // Timestamp of last feed/evolve/breed
    }

    // --- State Variables ---
    // ERC721 Mappings
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token Counter
    uint256 private _tokenIdCounter;

    // Evolutionary Data
    mapping(uint256 => EvolutionaryGene) private tokenGenes;

    // Evolutionary Parameters (Owner-settable)
    uint8[] public baseGeneTemplate; // Template for number and initial value of traits
    uint16 public evolutionRate = 10; // How much traits change per interaction/time unit (scaled)
    uint16 public mutationChance = 50; // Chance per trait per evolution/mutation event (parts per 10000, 50 = 0.5%)
    uint16 public traitDecayRate = 5; // How much traits decay over time without interaction (scaled)
    uint8 public minTraitValue = 0;  // Minimum value for any trait
    uint8 public maxTraitValue = 100; // Maximum value for any trait
    uint256 public breedingFee = 0 ether; // Fee in wei to breed NFTs

    // ERC165 Interface IDs
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    // Owner
    address private _owner;

    // --- Constructor ---
    constructor(uint8[] memory initialBaseGeneTemplate) {
        _owner = _msgSender();
        if (initialBaseGeneTemplate.length == 0) {
             revert InvalidTraitTemplate();
        }
        for (uint i = 0; i < initialBaseGeneTemplate.length; i++) {
            if (initialBaseGeneTemplate[i] > maxTraitValue) {
                 revert InvalidTraitValue(initialBaseGeneTemplate[i], minTraitValue, maxTraitValue);
            }
        }
        baseGeneTemplate = initialBaseGeneTemplate;

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    modifier onlyOwner() {
        if (_owner != _msgSender()) {
             revert OwnableUnauthorizedAccount(_msgSender());
        }
        _;
    }

    // --- ERC721 Standard Functions (Manual Implementation) ---

    function balanceOf(address owner) external view override returns (uint256) {
        if (owner == address(0)) {
             revert InvalidRecipient();
        }
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) external payable override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external payable override {
        _transfer(from, to, tokenId);
        if (to.code.length > 0 && !IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, "")) {
             revert InvalidRecipient(); // ERC721Receiver not implemented or rejected
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external payable override {
        _transfer(from, to, tokenId);
         if (to.code.length > 0 && !IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)) {
             revert InvalidRecipient(); // ERC721Receiver not implemented or rejected
         }
    }

    function approve(address to, uint256 tokenId) external payable override {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }
        if (_msgSender() != owner) {
             revert NotOwnerOrApproved(); // Only owner can approve
        }
        if (to == owner) {
             revert ApprovalForSelf();
        }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) external view override returns (address) {
        if (_owners[tokenId] == address(0)) {
             revert TokenDoesNotExist();
        }
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external override {
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // ERC165 support check is handled by inheriting ERC165 and calling _registerInterface

    // --- Core Evolutionary Logic Functions ---

    function getGene(uint256 tokenId) external view returns (uint8[] memory traits, uint48 birthTimestamp, uint256 generation, uint8 breedingCount) {
        EvolutionaryGene storage gene = tokenGenes[tokenId];
        if (_owners[tokenId] == address(0)) {
             revert TokenDoesNotExist();
        }
        return (gene.traits, gene.birthTimestamp, gene.generation, gene.breedingCount);
    }

    function evolve(uint256 tokenId) external {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }
        // Allow owner or approved to trigger evolution
        if (_msgSender() != owner && !_isApprovedOrForAll(owner, _msgSender(), tokenId)) {
             revert NotOwnerOrApproved();
        }

        EvolutionaryGene storage gene = tokenGenes[tokenId];
        uint8[] memory currentTraits = gene.traits;
        uint8[] memory newTraits = new uint8[](currentTraits.length);

        // Apply aging and decay first
        _applyAgingAndDecay(tokenId);

        // Re-fetch gene as decay might have changed it
        currentTraits = gene.traits;

        // Apply general evolution based on traits themselves and parameters
        for (uint i = 0; i < currentTraits.length; i++) {
            int256 change = int256(evolutionRate) * (int256(currentTraits[i]) - int256(minTraitValue + (maxTraitValue - minTraitValue) / 2)) / 1000; // Example: traits closer to max increase, closer to min decrease
            newTraits[i] = _clampTrait(uint8(int256(currentTraits[i]) + change));
        }

        // Apply potential mutation
        _applyMutation(tokenId);

        // Final clamp after all changes
        for (uint i = 0; i < newTraits.length; i++) {
            newTraits[i] = _clampTrait(newTraits[i]);
        }

        _updateGene(tokenId, newTraits);
        gene.lastInteraction = uint48(block.timestamp); // Update interaction time

        emit Evolved(tokenId, block.timestamp, newTraits);
    }

    function feed(uint256 tokenId) external {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }
         if (_msgSender() != owner && !_isApprovedOrForAll(owner, _msgSender(), tokenId)) {
             revert NotOwnerOrApproved();
        }

        EvolutionaryGene storage gene = tokenGenes[tokenId];
        uint8[] memory currentTraits = gene.traits;
        uint8[] memory newTraits = new uint8[](currentTraits.length);

        // Apply some positive boost and reset decay
        for (uint i = 0; i < currentTraits.length; i++) {
             // Boost traits slightly, maybe biased towards max
             int256 boost = int256(evolutionRate / 5) * (int256(maxTraitValue) - int256(currentTraits[i])) / 100; // Example: boost traits that are lower
             newTraits[i] = _clampTrait(uint8(int256(currentTraits[i]) + boost));
        }

        _updateGene(tokenId, newTraits);
        gene.lastInteraction = uint48(block.timestamp); // Reset interaction time

        emit Fed(tokenId, block.timestamp, newTraits);
    }


    function breed(uint256 parent1Id, uint256 parent2Id) external payable returns (uint256 newTokenId) {
        if (_msgSender().value < breedingFee) {
             revert BreedingFeeNotMet();
        }

        address owner1 = _owners[parent1Id];
        address owner2 = _owners[parent2Id];

        if (owner1 == address(0) || owner2 == address(0)) {
             revert TokenDoesNotExist();
        }
        if (parent1Id == parent2Id) {
             revert CannotBreedWithSelf();
        }

        // Only owners can initiate breeding (or maybe approved operators?)
        // Let's stick to owners for simplicity now.
        if (_msgSender() != owner1 || _msgSender() != owner2) {
             // Revert if msg.sender is not owner of *both*
             revert NotOwnerOrApproved(); // Simplified check
             // A more complex check might allow breeding with someone else's NFT if they've approved the breeder
        }

        EvolutionaryGene storage gene1 = tokenGenes[parent1Id];
        EvolutionaryGene storage gene2 = tokenGenes[parent2Id];

        if (gene1.traits.length == 0 || gene2.traits.length == 0 || gene1.traits.length != gene2.traits.length) {
             revert InsufficientGenesForBreeding();
        }

        uint8[] memory childTraits = _generateChildGenes(gene1.traits, gene2.traits);
        uint256 childGeneration = (gene1.generation > gene2.generation ? gene1.generation : gene2.generation) + 1;

        // Increment breeding counts (optional, could influence future breeding or traits)
        gene1.breedingCount++;
        gene2.breedingCount++;

        // Update last interaction for parents
        gene1.lastInteraction = uint48(block.timestamp);
        gene2.lastInteraction = uint48(block.timestamp);

        // Mint the new token
        uint256 newId = _tokenIdCounter++;
        _owners[newId] = _msgSender();
        _balances[_msgSender()]++;

        tokenGenes[newId] = EvolutionaryGene({
            traits: childTraits,
            birthTimestamp: uint48(block.timestamp),
            generation: childGeneration,
            breedingCount: 0, // New NFT has not bred yet
            lastInteraction: uint48(block.timestamp)
        });

        emit Transfer(address(0), _msgSender(), newId);
        emit Bred(parent1Id, parent2Id, newId, childTraits);

        return newId;
    }

     function mutate(uint256 tokenId) external {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }
         // Allow owner or approved, maybe with a cost or condition?
         // Let's make it owner only for simplicity here, or require specific tokens to "force" mutation.
         // Sticking to simple owner/approved for now.
        if (_msgSender() != owner && !_isApprovedOrForAll(owner, _msgSender(), tokenId)) {
             revert NotOwnerOrApproved();
        }

        _applyMutation(tokenId); // Directly apply mutation logic
        tokenGenes[tokenId].lastInteraction = uint48(block.timestamp); // Update interaction time

        emit Evolved(tokenId, block.timestamp, tokenGenes[tokenId].traits); // Mutation is a form of evolution
        // Could also emit a specific Mutated event within _applyMutation if desired
    }


    function getTraitValue(uint256 tokenId, uint8 traitIndex) external view returns (uint8) {
        EvolutionaryGene storage gene = tokenGenes[tokenId];
         if (_owners[tokenId] == address(0)) {
             revert TokenDoesNotExist();
        }
        if (traitIndex >= gene.traits.length) {
             revert InvalidTraitIndex();
        }
        return gene.traits[traitIndex];
    }

    function getAge(uint256 tokenId) external view returns (uint256) {
        EvolutionaryGene storage gene = tokenGenes[tokenId];
         if (_owners[tokenId] == address(0)) {
             revert TokenDoesNotExist();
        }
        // Age in seconds since birth timestamp
        return block.timestamp - gene.birthTimestamp;
    }

     function predictEvolution(uint256 tokenId) external view returns (uint8[] memory predictedTraits) {
        EvolutionaryGene storage gene = tokenGenes[tokenId];
        if (_owners[tokenId] == address(0)) {
             revert TokenDoesNotExist();
        }

        uint8[] memory currentTraits = gene.traits;
        predictedTraits = new uint8[](currentTraits.length);
        uint256 timeElapsed = block.timestamp - gene.lastInteraction;

        // Simulate decay (read-only, does not change state)
        uint8[] memory decayedTraits = new uint8[](currentTraits.length);
         for (uint i = 0; i < currentTraits.length; i++) {
             int256 decayAmount = int256(traitDecayRate) * int256(timeElapsed) / 86400; // Example: decay per day
             decayedTraits[i] = _clampTrait(uint8(int256(currentTraits[i]) - decayAmount));
         }

        // Simulate general evolution (read-only)
        for (uint i = 0; i < decayedTraits.length; i++) {
            int256 change = int256(evolutionRate) * (int256(decayedTraits[i]) - int256(minTraitValue + (maxTraitValue - minTraitValue) / 2)) / 1000;
            predictedTraits[i] = _clampTrait(uint8(int256(decayedTraits[i]) + change));
        }

        // Note: Predicting mutation is difficult/impossible deterministically in a view function
        // as it relies on block data potentially changing. This prediction is simplified.
    }


    // --- Lifecycle Management ---

    function mintRandom(address to) external onlyOwner returns (uint256 tokenId) {
        uint256 newId = _tokenIdCounter++;

        uint8[] memory initialTraits = new uint8[](baseGeneTemplate.length);
        for (uint i = 0; i < baseGeneTemplate.length; i++) {
            // Initial traits are based on template + small random deviation
            uint256 randomBias = _random(uint256(block.difficulty) + block.timestamp + newId + i);
            int256 deviation = int256(randomBias % (maxTraitValue - minTraitValue + 1)) - int256((maxTraitValue - minTraitValue) / 2);
            initialTraits[i] = _clampTrait(uint8(int256(baseGeneTemplate[i]) + deviation/2)); // Deviation is halved
        }

        _mint(to, newId, initialTraits, 0); // Generation 0 for initial mints
        return newId;
    }

     function mintWithGenes(address to, uint8[] memory initialTraits) external onlyOwner returns (uint256 tokenId) {
        if (initialTraits.length != baseGeneTemplate.length) {
             revert InvalidTraitTemplate();
        }
        for (uint i = 0; i < initialTraits.length; i++) {
             if (initialTraits[i] < minTraitValue || initialTraits[i] > maxTraitValue) {
                 revert InvalidTraitValue(initialTraits[i], minTraitValue, maxTraitValue);
             }
         }

        uint256 newId = _tokenIdCounter++;
        _mint(to, newId, initialTraits, 0); // Generation 0
        return newId;
     }


    function burn(uint256 tokenId) external {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }
        if (_msgSender() != owner && !_isApprovedOrForAll(owner, _msgSender(), tokenId)) {
             revert NotOwnerOrApproved();
        }

        _burn(tokenId);
    }

    // --- Dynamic Metadata ---

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        EvolutionaryGene storage gene = tokenGenes[tokenId];
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }

        // Construct JSON metadata string on-chain
        // Basic JSON structure: { "name": "...", "description": "...", "attributes": [...] }
        string memory name = string(abi.encodePacked("Evolutionary NFT #", _toString(tokenId)));
        string memory description = string(abi.encodePacked(
            "A dynamic NFT that evolves. Generation: ", _toString(gene.generation),
            ", Age: ~", _toString(getAge(tokenId) / 86400), " days." // Display age in days
        ));

        string memory attributes = "[";
        for (uint i = 0; i < gene.traits.length; i++) {
            attributes = string(abi.encodePacked(attributes, '{"trait_type":"Trait ', _toString(i), '","value":', _toString(gene.traits[i]), "}"));
            if (i < gene.traits.length - 1) {
                attributes = string(abi.encodePacked(attributes, ","));
            }
        }
        attributes = string(abi.encodePacked(attributes, "]"));

        string memory json = string(abi.encodePacked(
            '{"name":"', name,
            '","description":"', description,
            '","attributes":', attributes,
            '}' // Closing brace for JSON
        ));

        // Return as data URI (base64 encoding is complex on-chain, return raw JSON with mime type)
        // Note: Some platforms might not fully support data URIs with raw JSON.
        // A robust system might return an HTTPS URL to a metadata server that reads on-chain state.
        // This is a creative ON-CHAIN data URI approach for demonstration.
        return string(abi.encodePacked("data:application/json,", json));
    }


    // --- Admin/Parameter Functions (Ownable) ---

    function setBaseGeneTemplate(uint8[] memory template) external onlyOwner {
         if (template.length == 0) {
             revert InvalidTraitTemplate();
        }
        for (uint i = 0; i < template.length; i++) {
             if (template[i] < minTraitValue || template[i] > maxTraitValue) {
                 revert InvalidTraitValue(template[i], minTraitValue, maxTraitValue);
             }
         }
        baseGeneTemplate = template;
    }

    function setEvolutionRate(uint16 rate) external onlyOwner {
        evolutionRate = rate;
    }

    function setMutationChance(uint16 chance) external onlyOwner {
        mutationChance = chance;
    }

     function setTraitDecayRate(uint16 rate) external onlyOwner {
        traitDecayRate = rate;
    }

    function setMinMaxTraitValue(uint8 min, uint8 max) external onlyOwner {
         if (min >= max) {
             revert InvalidTraitBounds();
         }
        minTraitValue = min;
        maxTraitValue = max;

        // Optionally: Iterate existing NFTs and clamp traits? Might be gas intensive.
        // For simplicity, existing traits are clamped on next evolution/feed/breed/mutate.
    }

    function setBreedingFee(uint256 fee) external onlyOwner {
        breedingFee = fee;
    }

    function withdraw() external onlyOwner {
        (bool success,) = payable(_owner).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }


    // --- Internal Helper Functions ---

    function _mint(address to, uint256 tokenId, uint8[] memory initialTraits, uint256 generation) internal {
        if (to == address(0)) {
             revert InvalidRecipient();
        }
        // Should check if token already exists, but with counter it shouldn't happen.
        // require(_owners[tokenId] == address(0), "Token already minted");

        _owners[tokenId] = to;
        _balances[to]++;
        tokenGenes[tokenId] = EvolutionaryGene({
            traits: initialTraits,
            birthTimestamp: uint48(block.timestamp),
            generation: generation,
            breedingCount: 0,
            lastInteraction: uint48(block.timestamp)
        });

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist(); // Should not happen if called from burn()
        }

        delete _tokenApprovals[tokenId];
        delete _owners[tokenId];
        delete tokenGenes[tokenId]; // Remove gene data

        _balances[owner]--;

        emit Transfer(owner, address(0), tokenId);
        emit Burned(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        address owner = _owners[tokenId];
        if (owner == address(0)) {
             revert TokenDoesNotExist();
        }
        if (from != owner) {
             revert NotOwnerOrApproved(); // Caller doesn't match 'from'
        }
        if (to == address(0)) {
             revert InvalidRecipient();
        }

        // Check approval: Caller is owner, or caller is approved for token, or caller is operator for owner
        if (_msgSender() != owner && !_isApprovedOrForAll(owner, _msgSender(), tokenId)) {
             revert NotOwnerOrApproved();
        }

        // Clear approval upon transfer
        delete _tokenApprovals[tokenId];

        _balances[from]--;
        _owners[tokenId] = to;
        _balances[to]++;

        // Update last interaction time on transfer (can also influence evolution)
        tokenGenes[tokenId].lastInteraction = uint48(block.timestamp);

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrForAll(address owner, address operator, uint256 tokenId) internal view returns (bool) {
        return operator == _tokenApprovals[tokenId] || _operatorApprovals[owner][operator];
    }

    function _updateGene(uint256 tokenId, uint8[] memory newTraits) internal {
        // Assumes validation/clamping is done before calling
        tokenGenes[tokenId].traits = newTraits;
        // Does not update lastInteraction here, needs to be done by calling function (evolve, feed, breed, transfer)
    }

     function _applyAgingAndDecay(uint256 tokenId) internal {
        EvolutionaryGene storage gene = tokenGenes[tokenId];
        uint8[] memory currentTraits = gene.traits;
        uint8[] memory decayedTraits = new uint8[](currentTraits.length);

        uint256 timeElapsed = block.timestamp - gene.lastInteraction;
        if (timeElapsed == 0) { // No time elapsed since last interaction
            for (uint i = 0; i < currentTraits.length; i++) {
                decayedTraits[i] = currentTraits[i]; // No change
            }
        } else {
            // Decay traits slowly based on time elapsed since last interaction
            // Example: decay scaled by timeElapsed / some time unit (e.g., 1 day = 86400s)
            // The longer between interactions, the more decay.
             int256 decayAmount = int256(traitDecayRate) * int256(timeElapsed) / 86400; // Decay scaled per day

             for (uint i = 0; i < currentTraits.length; i++) {
                 decayedTraits[i] = _clampTrait(uint8(int256(currentTraits[i]) - decayAmount));
             }
        }
         _updateGene(tokenId, decayedTraits);
     }

    function _applyMutation(uint256 tokenId) internal {
         EvolutionaryGene storage gene = tokenGenes[tokenId];
         uint8[] memory currentTraits = gene.traits;
         uint8[] memory mutatedTraits = new uint8[](currentTraits.length);
         bool mutated = false;

         for (uint i = 0; i < currentTraits.length; i++) {
             uint256 mutationSeed = _random(uint256(block.timestamp) + block.difficulty + tokenId + i);
             // Check if mutation occurs for this trait
             if (mutationSeed % 10000 < mutationChance) {
                 // Apply a random change to the trait
                 uint256 randomChange = _random(mutationSeed + 1) % (maxTraitValue - minTraitValue + 1);
                 // Randomly increase or decrease
                 if (randomChange % 2 == 0) {
                     mutatedTraits[i] = _clampTrait(uint8(int256(currentTraits[i]) + randomChange / 5)); // Apply change
                 } else {
                     mutatedTraits[i] = _clampTrait(uint8(int256(currentTraits[i]) - randomChange / 5)); // Apply change
                 }
                 mutated = true;
                 emit Mutated(tokenId, uint8(i), currentTraits[i], mutatedTraits[i]);
             } else {
                 mutatedTraits[i] = currentTraits[i];
             }
         }
         if (mutated) {
             _updateGene(tokenId, mutatedTraits);
         }
     }


    function _generateChildGenes(uint8[] memory parent1Genes, uint8[] memory parent2Genes) internal view returns (uint8[] memory childGenes) {
        // Simple breeding: Each trait is randomly chosen from one of the parents,
        // with a small chance of mutation during inheritance.
        uint genomeLength = parent1Genes.length; // Assumes parents have same length (checked in breed)
        childGenes = new uint8[](genomeLength);

        for (uint i = 0; i < genomeLength; i++) {
            uint256 geneSeed = _random(uint256(block.timestamp) + block.difficulty + i + uint256(keccak256(abi.encodePacked(parent1Genes, parent2Genes))));

            uint8 inheritedTrait;
            // Randomly pick from parent 1 or parent 2
            if (geneSeed % 2 == 0) {
                inheritedTrait = parent1Genes[i];
            } else {
                inheritedTrait = parent2Genes[i];
            }

             // Small chance of mutation during breeding
             uint256 mutationSeed = _random(geneSeed + 1);
             if (mutationSeed % 10000 < mutationChance * 2) { // Higher chance of mutation during breeding
                 int256 randomChange = int256(_random(mutationSeed + 1) % (maxTraitValue - minTraitValue + 1)) - int256((maxTraitValue - minTraitValue) / 2);
                 childGenes[i] = _clampTrait(uint8(int256(inheritedTrait) + randomChange / 4)); // Smaller random change
             } else {
                 childGenes[i] = inheritedTrait;
             }
        }
         // Ensure initial traits are within bounds after generation
        for (uint i = 0; i < childGenes.length; i++) {
            childGenes[i] = _clampTrait(childGenes[i]);
        }
    }


    function _clampTrait(uint8 value) internal view returns (uint8) {
        if (value < minTraitValue) return minTraitValue;
        if (value > maxTraitValue) return maxTraitValue;
        return value;
    }

    // Basic Pseudo-Random Number Generator
    // NOTE: This is NOT cryptographically secure and should not be used for
    // applications where randomness is a core security requirement (e.g., gambling).
    // Miners can influence outcomes. It's suitable for trait generation/evolution
    // where exact prediction/manipulation isn't a critical vulnerability.
    function _random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed, block.number)));
    }

     // Helper to convert uint256 to string (for tokenURI)
     function _toString(uint256 value) internal pure returns (string memory) {
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

     // Helper to convert uint8 to string (for tokenURI)
      function _toString(uint8 value) internal pure returns (string memory) {
         if (value == 0) {
             return "0";
         }
         uint8 temp = value;
         uint256 digits;
         while (temp != 0) {
             digits++;
             temp /= 10;
         }
         bytes memory buffer = new bytes(digits);
         while (value != 0) {
             digits -= 1;
             buffer[digits] = bytes1(uint8(48 + uint8(value % 10)));
             value /= 10;
         }
         return string(buffer);
     }

     // Override supportsInterface from ERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC721) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC721 || interfaceId == _INTERFACE_ID_ERC165 || super.supportsInterface(interfaceId);
    }

    // Required for ERC721 to signal contract name and symbol (though not strictly enforced by interface)
    // Add placeholder getters or state variables if desired.
    // function name() external view returns (string memory) { return "EvolutionaryNFT"; }
    // function symbol() external view returns (string memory) { return "EVONFT"; }

    // Manually implementing Ownable functions
    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
        emit OwnableTransferOwnership(address(this), address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnableTransferOwnership(oldOwner, newOwner);
    }

    event OwnableTransferOwnership(address indexed previousOwner, address indexed newOwner);

}
```