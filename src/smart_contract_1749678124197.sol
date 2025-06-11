Okay, let's create a smart contract that represents dynamic, evolvable digital entities – "Digital Genomes". This concept allows for minting unique "genomes", breeding them to create new ones with mixed traits, applying "mutations", associating external data, and even simulating evolutionary pressure. It combines elements of generative data, identity, and simulation, going beyond standard token or marketplace patterns.

To meet the "at least 20 functions" and "don't duplicate any of open source" requirements strictly, we will implement the core ownership and enumeration logic ourselves rather than inheriting from standard libraries like OpenZeppelin.

Here's the outline and function summary:

---

**Smart Contract: DigitalGenome**

**Concept:**
A contract managing unique, non-fungible Digital Genomes. Each Genome has an owner, a unique ID, and a dynamic data structure representing its "chromosomes". Genomes can be bred together to create new genomes, potentially inheriting traits from parents, and can undergo random mutations. External data hashes can be associated with genomes, and a conceptual "fitness" score can be calculated.

**Outline:**

1.  **State Variables:**
    *   Contract ownership.
    *   Genome data storage (chromosomes, active status, generation, metadata URI).
    *   External data hash storage.
    *   Ownership mapping (`_owners`, `_balances`).
    *   Token approvals (`_tokenApprovals`, `_operatorApprovals`).
    *   Enumeration tracking (`_allTokens`, `_ownedTokens`).
    *   Total supply counter.
    *   Configuration parameters (breeding fee, mutation probability).
    *   Fee balance.
2.  **Events:** Signal key actions (Mint, Transfer, Approval, Breeding, Mutation, Activation Change, Data Association).
3.  **Errors:** Custom errors for specific failure conditions.
4.  **Structs:** Define the `Genome` data structure.
5.  **Modifiers:** Access control (`onlyOwner`).
6.  **Internal Helpers:** Functions for core logic (minting, transferring, enumeration updates, ownership checks).
7.  **External/Public Functions:** Implement the required functionalities, including:
    *   Basic ownership and enumeration (manual implementation of ERC721/ERC721Enumerable interfaces).
    *   Genome creation (`mintGenome`, `mintGenesisGenome`).
    *   Genome data retrieval (`getGenome`, `getTraitValue`, `calculateFitnessScore`).
    *   Genome manipulation (`breedGenomes`, `mutateGenome`, `deactivateGenome`, `activateGenome`).
    *   External data association (`associateExternalDataHash`, `getAssociatedDataHash`).
    *   Configuration (`setBreedingFee`, `setMutationProbability`, `setGenomeMetadataURI`).
    *   Fee withdrawal (`withdrawFees`).
    *   Interface support (`supportsInterface` for ERC165).

**Function Summary:**

1.  `constructor()`: Initializes contract owner and genesis parameters.
2.  `supportsInterface(bytes4 interfaceId)`: Returns true if the contract supports the given interface (ERC165, ERC721, ERC721Enumerable).
3.  `balanceOf(address owner)`: Returns the number of genomes owned by a specific address.
4.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific genome ID.
5.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers ownership of a genome from one address to another.
6.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers ownership and checks if the receiver can accept non-fungible tokens.
7.  `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: Transfers ownership with extra data and checks receiver.
8.  `approve(address to, uint256 tokenId)`: Grants approval to a single address to transfer a specific genome.
9.  `getApproved(uint256 tokenId)`: Returns the approved address for a specific genome ID.
10. `setApprovalForAll(address operator, bool approved)`: Grants or revokes approval for an operator to manage all of the caller's genomes.
11. `isApprovedForAll(address owner, address operator)`: Returns true if an operator is approved for an owner.
12. `totalSupply()`: Returns the total number of existing genomes.
13. `tokenByIndex(uint256 index)`: Returns the ID of the genome at a specific index in the contract's total list of genomes.
14. `tokenOfOwnerByIndex(address owner, uint256 index)`: Returns the ID of the genome at a specific index in the owner's list of genomes.
15. `mintGenesisGenome(address to, uint256[] memory initialChromosomes)`: Mints a special 'genesis' genome (generation 0), only callable once by the owner.
16. `mintGenome(address to, uint256[] memory initialChromosomes)`: Mints a new genome with provided chromosomes (potentially for specific use cases beyond genesis/breeding).
17. `getGenome(uint256 genomeId)`: Retrieves the full `Genome` struct data for a given ID.
18. `getTraitValue(uint256 genomeId, uint256 traitStartIndex, uint256 traitLength)`: Extracts a specific segment (trait) from a genome's chromosomes.
19. `calculateFitnessScore(uint256 genomeId)`: Calculates a conceptual "fitness" score based on the genome's chromosomes.
20. `breedGenomes(uint256 parent1Id, uint256 parent2Id, address childOwner)`: Combines two parent genomes to create a new child genome (requires fee, parents must be active and owned/approved by caller). Child inherits a mix of chromosomes and potential mutations.
21. `mutateGenome(uint256 genomeId)`: Applies random mutations to a genome's chromosomes (requires genome to be active and owned/approved by caller). Uses a simple on-chain randomness source.
22. `deactivateGenome(uint256 genomeId)`: Marks a genome as inactive (cannot be used for breeding/mutation), callable by owner/approved operator.
23. `activateGenome(uint256 genomeId)`: Marks a genome as active, callable by owner/approved operator.
24. `associateExternalDataHash(uint256 genomeId, bytes32 dataHash)`: Links an external data hash (e.g., IPFS hash of detailed metadata, health data reference, etc.) to a genome.
25. `getAssociatedDataHash(uint256 genomeId)`: Retrieves the external data hash associated with a genome.
26. `setGenomeMetadataURI(uint256 genomeId, string memory uri)`: Sets an external metadata URI for a genome (like ERC721 tokenURI).
27. `getGenomeMetadataURI(uint256 genomeId)`: Gets the external metadata URI for a genome.
28. `setBreedingFee(uint256 fee)`: Sets the fee required to call `breedGenomes` (only owner).
29. `setMutationProbability(uint256 probability)`: Sets the probability factor for mutations (only owner). Probability is relative, e.g., 1 to 1000.
30. `withdrawFees()`: Allows the contract owner to withdraw collected breeding fees.
31. `transferOwnership(address newOwner)`: Transfers contract ownership (only owner).
32. `renounceOwnership()`: Renounces contract ownership (only owner, makes ownership unrecoverable).
33. `_requireOwned(uint256 tokenId)`: Internal helper to check if caller owns or is approved for a token.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DigitalGenome
/// @author Your Name/Alias
/// @notice A contract managing unique, non-fungible Digital Genomes with evolutionary concepts like breeding and mutation.
/// @dev This contract implements custom ownership and enumeration logic to avoid direct inheritance from standard libraries.

// Outline:
// 1. State Variables for Ownership, Approvals, Enumeration, Genome Data, Configuration, Fees.
// 2. Events for key actions.
// 3. Custom Errors.
// 4. Genome Struct definition.
// 5. Modifiers (onlyOwner).
// 6. Internal Helper functions for core logic (_mint, _transfer, enumeration updates, ownership checks).
// 7. Public/External Functions for ERC721/ERC721Enumerable-like interface (manual impl), Genome creation, data retrieval, manipulation (breed, mutate), external data linking, configuration, fee withdrawal, ownership management.
// 8. ERC165 support.

// Function Summary:
// 1. constructor(): Initializes contract owner and genesis parameters.
// 2. supportsInterface(bytes4 interfaceId): Checks interface support (ERC165, ERC721, ERC721Enumerable).
// 3. balanceOf(address owner): Returns genome count for owner.
// 4. ownerOf(uint256 tokenId): Returns owner by ID.
// 5. transferFrom(address from, address to, uint256 tokenId): Standard transfer.
// 6. safeTransferFrom(address from, address to, uint256 tokenId): Standard safe transfer.
// 7. safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data): Standard safe transfer with data.
// 8. approve(address to, uint256 tokenId): Approves one address for one token.
// 9. getApproved(uint256 tokenId): Gets approved address for token.
// 10. setApprovalForAll(address operator, bool approved): Approves/revokes operator for all tokens.
// 11. isApprovedForAll(address owner, address operator): Checks if operator is approved for owner.
// 12. totalSupply(): Total number of genomes.
// 13. tokenByIndex(uint256 index): Get token ID by index in total list.
// 14. tokenOfOwnerByIndex(address owner, uint256 index): Get token ID by index in owner's list.
// 15. mintGenesisGenome(address to, uint256[] memory initialChromosomes): Mints special genesis genome (owner only, once).
// 16. mintGenome(address to, uint256[] memory initialChromosomes): Mints a general new genome.
// 17. getGenome(uint256 genomeId): Retrieves full genome data.
// 18. getTraitValue(uint256 genomeId, uint256 traitStartIndex, uint256 traitLength): Extracts a trait segment.
// 19. calculateFitnessScore(uint256 genomeId): Calculates a sample fitness score.
// 20. breedGenomes(uint256 parent1Id, uint256 parent2Id, address childOwner): Breeds two genomes to create a new one (requires fee, active parents, authorization).
// 21. mutateGenome(uint256 genomeId): Mutates a genome (requires active, authorization). Uses simple on-chain randomness.
// 22. deactivateGenome(uint256 genomeId): Deactivates a genome.
// 23. activateGenome(uint256 genomeId): Activates a genome.
// 24. associateExternalDataHash(uint256 genomeId, bytes32 dataHash): Links external data hash.
// 25. getAssociatedDataHash(uint256 genomeId): Gets external data hash.
// 26. setGenomeMetadataURI(uint256 genomeId, string memory uri): Sets metadata URI.
// 27. getGenomeMetadataURI(uint256 genomeId): Gets metadata URI.
// 28. setBreedingFee(uint256 fee): Sets breeding fee (owner only).
// 29. setMutationProbability(uint256 probability): Sets mutation probability factor (owner only).
// 30. withdrawFees(): Withdraws collected fees (owner only).
// 31. transferOwnership(address newOwner): Transfers contract ownership (owner only).
// 32. renounceOwnership(): Renounces contract ownership (owner only).
// 33. _requireOwned(uint256 tokenId): Internal helper for ownership/approval checks.

contract DigitalGenome {

    // --- State Variables ---

    // Ownership Mapping
    mapping(uint256 => address) private _owners;
    // Owner Balances
    mapping(address => uint256) private _balances;

    // Token Approvals
    mapping(uint256 => address) private _tokenApprovals;
    // Operator Approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Enumeration (Manual Implementation of ERC721Enumerable)
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Total Supply
    uint256 private _totalSupplyCounter;

    // Genome Data
    struct Genome {
        uint256 tokenId;
        uint256[] chromosomes; // The core genetic data
        uint256 generation;    // Generation number (0 for genesis, increases with breeding)
        uint64 createdAt;      // Timestamp of creation
        bool isActive;         // Can be deactivated for breeding/mutation
    }
    mapping(uint256 => Genome) private _genomeData;
    mapping(uint256 => bytes32) private _externalDataHashes; // Hash link to external data (e.g., IPFS)
    mapping(uint256 => string) private _genomeMetadataURIs; // Link to external metadata JSON

    // Configuration Parameters
    uint256 public breedingFee; // Fee required to breed, in native token (wei)
    uint256 public mutationProbability; // Probability factor for mutation (e.g., 100 = 1/100 chance per gene)

    // Contract Ownership (Manual Implementation of Ownable)
    address private _owner;

    // Fee Management
    uint256 private _collectedFees;

    // Sentinel value for uninitialized token IDs
    uint256 private constant _NOT_INITIALIZED = 0;

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event GenomeMinted(address indexed owner, uint256 indexed tokenId, uint256 generation);
    event GenomesBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, address childOwner);
    event GenomeMutated(uint256 indexed genomeId);
    event GenomeActivationChanged(uint256 indexed genomeId, bool isActive);
    event ExternalDataHashAssociated(uint256 indexed genomeId, bytes32 dataHash);
    event MetadataURIUpdated(uint256 indexed genomeId, string uri);
    event BreedingFeeSet(uint256 fee);
    event MutationProbabilitySet(uint256 probability);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Custom Errors ---

    error NotOwnerOrApproved();
    error NotOwnerApprovedOrOperator();
    error NotOwner();
    error ZeroAddress();
    error GenomeDoesNotExist();
    error InvalidTokenId();
    error NotERC721Receiver();
    error BreedingFeeNotMet();
    error GenomeNotActive();
    error CannotBreedWithSelf();
    error InvalidChromosomesLength();
    error GenesisGenomeAlreadyMinted();
    error InvalidTraitRange();

    // --- Constructor ---

    constructor() {
        _owner = msg.sender;
        breedingFee = 0.01 ether; // Default breeding fee
        mutationProbability = 500; // Default mutation probability factor (1/500)
        _totalSupplyCounter = 0;
    }

    // --- Modifiers ---

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    // --- ERC165 Interface Support ---

    // ERC165 Interface ID
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    // ERC721 Interface ID
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC721Enumerable Interface ID
    bytes4 private constant _INTERFACE_ID_ERC721Enumerable = 0x780e9d63;

    /// @notice Checks if the contract supports a given interface.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return True if the contract supports `interfaceId`, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165 ||
               interfaceId == _INTERFACE_ID_ERC721 ||
               interfaceId == _INTERFACE_ID_ERC721Enumerable;
    }

    // --- Core Ownership & Enumeration (Manual ERC721/ERC721Enumerable Implementation) ---

    /// @notice Returns the number of genomes in existence that belong to an owner.
    /// @param owner Address of the owner.
    /// @return The number of genomes owned by the owner address.
    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert ZeroAddress();
        return _balances[owner];
    }

    /// @notice Finds the owner of a specific genome ID.
    /// @param tokenId The genome ID to find the owner of.
    /// @return The address of the owner.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId(); // Or GenomeDoesNotExist based on preference
        return owner;
    }

    /// @notice Allows an approved address or the owner to transfer a genome.
    /// @dev The `from` address is validated to be the current owner.
    /// @param from The current owner of the genome.
    /// @param to The new owner.
    /// @param tokenId The genome ID to transfer.
    function transferFrom(address from, address to, uint256 tokenId) public {
        if (from != ownerOf(tokenId)) revert NotOwnerOrApproved(); // Check owner first
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
        _transfer(from, to, tokenId);
    }

    /// @notice Transfers a genome and calls `onERC721Received` on the recipient if it's a contract.
    /// @param from The current owner.
    /// @param to The new owner.
    /// @param tokenId The genome ID.
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @notice Transfers a genome, calls `onERC721Received` on the recipient if it's a contract, and includes data.
    /// @param from The current owner.
    /// @param to The new owner.
    /// @param tokenId The genome ID.
    /// @param data Additional data to pass to the receiver.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        if (from != ownerOf(tokenId)) revert NotOwnerOrApproved(); // Check owner first
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
        _transfer(from, to, tokenId);

        if (to.code.length > 0) {
             // Check if receiver implements ERC721TokenReceiver and accepts the token
            (bool success, bytes memory returnData) = to.call(abi.encodeWithSelector(IERC721Receiver.onERC721Received.selector, msg.sender, from, tokenId, data));
            if (!success || (returnData.length > 0 && abi.decode(returnData, (bytes4)) != IERC721Receiver.onERC721Received.selector)) {
                revert NotERC721Receiver();
            }
        }
    }

    /// @notice Approves an address to spend a specific genome.
    /// @param to The address to approve.
    /// @param tokenId The genome ID.
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId); // Ensure token exists
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert NotOwnerOrApproved();
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @notice Gets the approved address for a specific genome.
    /// @param tokenId The genome ID.
    /// @return The approved address, or address(0) if none.
    function getApproved(uint256 tokenId) public view returns (address) {
         // No need to check if token exists here, will return address(0) if not mapped
        return _tokenApprovals[tokenId];
    }

    /// @notice Sets or revokes approval for an operator to manage all of caller's genomes.
    /// @param operator The address to grant or revoke approval for.
    /// @param approved True to grant approval, false to revoke.
    function setApprovalForAll(address operator, bool approved) public {
        if (operator == msg.sender) revert ZeroAddress(); // Cannot approve self as operator
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Checks if an operator is approved for a given owner.
    /// @param owner The owner address.
    /// @param operator The operator address.
    /// @return True if approved, false otherwise.
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     /// @notice Returns the total number of genomes in existence.
    function totalSupply() public view returns (uint256) {
        return _totalSupplyCounter;
    }

    /// @notice Returns a genome ID by index in the global list.
    /// @dev This relies on the manual enumeration tracking.
    /// @param index The index in the list (0 to totalSupply() - 1).
    /// @return The genome ID at the given index.
    function tokenByIndex(uint256 index) public view returns (uint256) {
        if (index >= _allTokens.length) revert InvalidTokenId(); // Use a more specific error if needed
        return _allTokens[index];
    }

    /// @notice Returns a genome ID by index in an owner's list.
    /// @dev This relies on the manual enumeration tracking.
    /// @param owner The owner address.
    /// @param index The index in the owner's list (0 to balanceOf(owner) - 1).
    /// @return The genome ID at the given index.
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        if (index >= _ownedTokens[owner].length) revert InvalidTokenId(); // Use a more specific error
        return _ownedTokens[owner][index];
    }


    // --- Internal Helper Functions ---

    /// @dev Internal function to mint a new genome. Handles ownership, balance, and enumeration updates.
    /// @param to The recipient address.
    /// @param tokenId The ID of the token to mint.
    /// @param initialChromosomes The initial chromosomes for the genome.
    /// @param generation The generation number for the new genome.
    /// @param isActive Whether the new genome should be active.
    function _mint(address to, uint256 tokenId, uint256[] memory initialChromosomes, uint256 generation, bool isActive) internal {
        if (to == address(0)) revert ZeroAddress();
        if (_owners[tokenId] != address(0)) revert InvalidTokenId(); // Token ID already exists

        _owners[tokenId] = to;
        _balances[to]++;
        _totalSupplyCounter++;

        _genomeData[tokenId] = Genome({
            tokenId: tokenId,
            chromosomes: initialChromosomes,
            generation: generation,
            createdAt: uint64(block.timestamp),
            isActive: isActive
        });

        // Update Enumeration
        _addTokenToAllTokensEnumeration(tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

        emit Transfer(address(0), to, tokenId);
        emit GenomeMinted(to, tokenId, generation);
    }

    /// @dev Internal function to transfer ownership of a genome. Handles ownership, balance, and enumeration updates.
    /// @param from The sender address.
    /// @param to The recipient address.
    /// @param tokenId The ID of the token to transfer.
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (from == address(0) || to == address(0)) revert ZeroAddress();
        if (_owners[tokenId] != from) revert InvalidTokenId(); // Should match owner

        // Clear approvals
        delete _tokenApprovals[tokenId];

        // Update ownership and balance
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        // Update Enumeration
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal helper to check if the caller is the owner, approved for the token, or approved for all tokens of the owner.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if token does not exist
        return (spender == owner ||
                spender == getApproved(tokenId) ||
                isApprovedForAll(owner, spender));
    }

     /// @dev Internal helper to require that the caller is the owner, approved for the token, or approved for all tokens of the owner.
    function _requireOwned(uint256 tokenId) internal view {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotOwnerOrApproved();
    }

    /// @dev Internal helper to add a token to the global enumeration list.
    function _addTokenToAllTokensEnumeration(uint256 tokenId) internal {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /// @dev Internal helper to add a token to an owner's enumeration list.
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /// @dev Internal helper to remove a token from a owner's enumeration list.
    /// Uses a swap-and-pop technique for gas efficiency.
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // If the token is not the last one, move the last one to its place
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        // Remove the last token (either the original or the swapped one)
        _ownedTokens[from].pop();
        delete _ownedTokensIndex[tokenId]; // Clean up the index mapping
    }

    // --- Genome Specific Functions ---

    /// @notice Mints the special genesis genome (generation 0). Can only be called once by the contract owner.
    /// @param to The address to mint the genesis genome to.
    /// @param initialChromosomes The initial genetic data for the genesis genome.
    function mintGenesisGenome(address to, uint256[] memory initialChromosomes) external onlyOwner {
        // Check if a genesis genome already exists
        if (_totalSupplyCounter > 0 && _genomeData[_allTokens[0]].generation == 0) {
            revert GenesisGenomeAlreadyMinted();
        }
        // Ensure chromosomes are provided
        if (initialChromosomes.length == 0) revert InvalidChromosomesLength();

        // Use 1 as the genesis token ID, subsequent tokens start from 2
        _mint(to, 1, initialChromosomes, 0, true);
    }

    /// @notice Mints a new genome with provided chromosomes.
    /// @dev This function could be used for injecting specific genome types or for admin purposes.
    /// @param to The address to mint the genome to.
    /// @param initialChromosomes The initial genetic data.
    function mintGenome(address to, uint256[] memory initialChromosomes) external onlyOwner {
         if (initialChromosomes.length == 0) revert InvalidChromosomesLength();
        // Use _totalSupplyCounter + 1 for the new token ID
        uint256 newTokenId = _totalSupplyCounter == 0 ? 1 : _allTokens[_allTokens.length - 1] + 1;
        _mint(to, newTokenId, initialChromosomes, 1, true); // Start generation at 1 for non-genesis
    }

    /// @notice Retrieves the full data for a given genome ID.
    /// @param genomeId The ID of the genome to retrieve.
    /// @return A tuple containing the genome's ID, chromosomes, generation, creation time, and active status.
    function getGenome(uint256 genomeId) public view returns (uint256, uint256[] memory, uint256, uint64, bool) {
        Genome storage genome = _genomeData[genomeId];
        if (genome.tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist(); // Check if token ID exists

        return (
            genome.tokenId,
            genome.chromosomes,
            genome.generation,
            genome.createdAt,
            genome.isActive
        );
    }

    /// @notice Extracts a specific segment ("trait") from a genome's chromosomes.
    /// @param genomeId The ID of the genome.
    /// @param traitStartIndex The starting index of the trait in the chromosomes array.
    /// @param traitLength The number of elements in the trait.
    /// @return A new array containing the extracted trait values.
    function getTraitValue(uint256 genomeId, uint256 traitStartIndex, uint256 traitLength) public view returns (uint256[] memory) {
        Genome storage genome = _genomeData[genomeId];
        if (genome.tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();

        if (traitStartIndex + traitLength > genome.chromosomes.length) revert InvalidTraitRange();

        uint256[] memory trait = new uint256[](traitLength);
        for (uint256 i = 0; i < traitLength; i++) {
            trait[i] = genome.chromosomes[traitStartIndex + i];
        }
        return trait;
    }

    /// @notice Calculates a conceptual "fitness" score for a genome based on a simple algorithm (e.g., sum of genes).
    /// @dev This is a placeholder for more complex off-chain or on-chain trait analysis.
    /// @param genomeId The ID of the genome.
    /// @return A uint256 representing the fitness score.
    function calculateFitnessScore(uint256 genomeId) public view returns (uint256) {
        Genome storage genome = _genomeData[genomeId];
        if (genome.tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();

        uint256 score = 0;
        for (uint256 i = 0; i < genome.chromosomes.length; i++) {
            // Simple example: sum all genes, then maybe take modulo for complexity
            score = (score + genome.chromosomes[i]) % 10000; // Example scoring logic
        }
        return score;
    }

    /// @notice Breeds two parent genomes to create a new child genome.
    /// @dev Requires a fee, parents must be active and owned/approved by the caller.
    /// Uses a simplified crossover mechanism and applies potential mutations.
    /// @param parent1Id The ID of the first parent genome.
    /// @param parent2Id The ID of the second parent genome.
    /// @param childOwner The address to mint the child genome to.
    function breedGenomes(uint256 parent1Id, uint256 parent2Id, address childOwner) public payable {
        if (msg.value < breedingFee) revert BreedingFeeNotMet();
        if (parent1Id == parent2Id) revert CannotBreedWithSelf();
        if (childOwner == address(0)) revert ZeroAddress();

        Genome storage parent1 = _genomeData[parent1Id];
        Genome storage parent2 = _genomeData[parent2Id];

        if (parent1.tokenId == _NOT_INITIALIZED || parent2.tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();
        if (!parent1.isActive || !parent2.isActive) revert GenomeNotActive();

        // Caller must own or be approved for both parents
        _requireOwned(parent1Id);
        _requireOwned(parent2Id);

        // Simple crossover: take first half from parent1, second half from parent2
        // Assumes parents have the same chromosome length for simplicity.
        // A more complex implementation would handle different lengths.
        if (parent1.chromosomes.length != parent2.chromosomes.length || parent1.chromosomes.length == 0) {
             revert InvalidChromosomesLength(); // Or specific error for breeding mismatch
        }

        uint256 chromosomeLength = parent1.chromosomes.length;
        uint256 crossoverPoint = chromosomeLength / 2; // Simple midpoint crossover
        uint256[] memory childChromosomes = new uint256[](chromosomeLength);

        for (uint256 i = 0; i < chromosomeLength; i++) {
            if (i < crossoverPoint) {
                childChromosomes[i] = parent1.chromosomes[i];
            } else {
                childChromosomes[i] = parent2.chromosomes[i];
            }

            // Apply mutation chance to each gene
            // Simple PRNG: blockhash is not truly random, but okay for demonstration
            // Add other entropy sources for better (but still not secure) distribution
            uint256 mutationRoll = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, parent1Id, parent2Id, i))) % mutationProbability;

            if (mutationRoll == 0) { // Mutation occurs if roll hits 0
                // Example mutation: flip a bit or generate a new random uint256
                // Simple example: XOR with a hash based on current state
                childChromosomes[i] = childChromosomes[i] ^ uint256(keccak256(abi.encodePacked(block.timestamp, i, msg.sender)));
                 emit GenomeMutated(0); // Placeholder event, child ID not known yet
            }
        }

        uint256 childGeneration = Math.max(parent1.generation, parent2.generation) + 1;
        uint256 childId = _totalSupplyCounter == 0 ? 1 : _allTokens[_allTokens.length - 1] + 1; // Next available ID

        _mint(childOwner, childId, childChromosomes, childGeneration, true); // Child is active by default

        _collectedFees += msg.value; // Collect the breeding fee

        emit GenomesBred(parent1Id, parent2Id, childId, childOwner);
    }

    /// @notice Applies random mutations to a genome's chromosomes.
    /// @dev Requires the genome to be active and owned/approved by the caller.
    /// Uses a simple on-chain randomness source.
    /// @param genomeId The ID of the genome to mutate.
    function mutateGenome(uint256 genomeId) public {
        Genome storage genome = _genomeData[genomeId];
        if (genome.tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();
        if (!genome.isActive) revert GenomeNotActive();

        _requireOwned(genomeId);

        bool mutated = false;
        for (uint256 i = 0; i < genome.chromosomes.length; i++) {
             // Simple PRNG: blockhash is not truly random, but okay for demonstration
            // Add other entropy sources for better distribution
            uint256 mutationRoll = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, genomeId, i))) % mutationProbability;

            if (mutationRoll == 0) { // Mutation occurs
                // Example mutation: XOR with a hash based on current state
                 genome.chromosomes[i] = genome.chromosomes[i] ^ uint256(keccak256(abi.encodePacked(block.timestamp, i, msg.sender)));
                 mutated = true;
            }
        }
        if(mutated) {
             emit GenomeMutated(genomeId);
        }
    }

    /// @notice Marks a genome as inactive, preventing it from being used in breeding or mutation.
    /// @param genomeId The ID of the genome to deactivate.
    function deactivateGenome(uint256 genomeId) public {
        Genome storage genome = _genomeData[genomeId];
        if (genome.tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();
        _requireOwned(genomeId);

        if (genome.isActive) {
            genome.isActive = false;
            emit GenomeActivationChanged(genomeId, false);
        }
    }

    /// @notice Marks a genome as active, allowing it to be used in breeding and mutation.
    /// @param genomeId The ID of the genome to activate.
    function activateGenome(uint256 genomeId) public {
        Genome storage genome = _genomeData[genomeId];
        if (genome.tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();
        _requireOwned(genomeId);

        if (!genome.isActive) {
            genome.isActive = true;
            emit GenomeActivationChanged(genomeId, true);
        }
    }

    /// @notice Associates an external data hash with a genome. Useful for linking off-chain data.
    /// @param genomeId The ID of the genome.
    /// @param dataHash The bytes32 hash to associate (e.g., IPFS hash, content hash).
    function associateExternalDataHash(uint256 genomeId, bytes32 dataHash) public {
        // Ensure token exists
        if (_genomeData[genomeId].tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();
        _requireOwned(genomeId);

        _externalDataHashes[genomeId] = dataHash;
        emit ExternalDataHashAssociated(genomeId, dataHash);
    }

    /// @notice Retrieves the external data hash associated with a genome.
    /// @param genomeId The ID of the genome.
    /// @return The associated bytes32 hash, or zero bytes32 if none.
    function getAssociatedDataHash(uint256 genomeId) public view returns (bytes32) {
        // No need to check for existence, will return default(bytes32) if not set
        return _externalDataHashes[genomeId];
    }

    /// @notice Sets the external metadata URI for a genome (like ERC721 tokenURI).
    /// @param genomeId The ID of the genome.
    /// @param uri The URI pointing to the metadata.
    function setGenomeMetadataURI(uint256 genomeId, string memory uri) public {
         // Ensure token exists
        if (_genomeData[genomeId].tokenId == _NOT_INITIALIZED) revert GenomeDoesNotExist();
        _requireOwned(genomeId);

        _genomeMetadataURIs[genomeId] = uri;
        emit MetadataURIUpdated(genomeId, uri);
    }

    /// @notice Gets the external metadata URI for a genome.
    /// @param genomeId The ID of the genome.
    /// @return The associated URI string.
    function getGenomeMetadataURI(uint256 genomeId) public view returns (string memory) {
        // No need to check for existence, will return default(string) if not set
        return _genomeMetadataURIs[genomeId];
    }

    // --- Configuration & Admin Functions ---

    /// @notice Sets the fee required to breed genomes.
    /// @param fee The new breeding fee in wei.
    function setBreedingFee(uint256 fee) external onlyOwner {
        breedingFee = fee;
        emit BreedingFeeSet(fee);
    }

    /// @notice Sets the probability factor for mutation. A lower number means higher probability (e.g., 1000 = 1/1000 chance per gene).
    /// @param probability The new probability factor (must be > 0).
    function setMutationProbability(uint256 probability) external onlyOwner {
         if (probability == 0) revert InvalidTraitRange(); // Or specific error
        mutationProbability = probability;
        emit MutationProbabilitySet(probability);
    }

    /// @notice Allows the contract owner to withdraw collected breeding fees.
    function withdrawFees() external onlyOwner {
        uint256 amount = _collectedFees;
        _collectedFees = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            // Revert or handle failure; for simplicity, we revert.
            // In a real contract, you might want to send smaller amounts or use a withdrawal pattern.
            revert("Fee withdrawal failed");
        }
        emit FeesWithdrawn(msg.sender, amount);
    }

    // --- Ownership Management (Manual Ownable Implementation) ---

    /// @notice Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    /// @param newOwner The address of the new owner.
    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /// @notice Renounces contract ownership.
    /// The caller's address will become zero, rendering the contract ownerless.
    /// Can only be called by the current owner.
    /// NOTE: This leaves the contract without an owner, which may be undesirable.
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// Interface for ERC721Receiver (to implement safeTransferFrom)
interface IERC721Receiver {
    /// @notice Handles the receipt of a non-fungible token.
    /// To accept a token, the contract must return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// Any other return value or a revert causes the transfer to fail.
    /// @dev The ERC721 smart contract calls this function on the recipient after a `safeTransferFrom` transaction.
    /// This function MUST NOT revert, otherwise the transaction will be reverted.
    /// @param operator The address which called `safeTransferFrom` function.
    /// @param from The address which previously owned the token.
    /// @param tokenId The NFT identifier which is being transferred.
    /// @param data Additional data with no specified format.
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` if transfer is accepted.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// Simple Math library for max (if not using OpenZeppelin)
library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
```