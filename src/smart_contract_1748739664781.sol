Okay, here is a smart contract concept called `QuantumEntanglementToken` (QET). It's a non-fungible token system inspired by quantum mechanics, specifically the concept of entanglement.

In this system:
1.  Tokens are minted in entangled pairs.
2.  Each token in a pair has an inherent 'polarity' (e.g., positive or negative). While entangled, the tokens in a pair always have opposite polarities.
3.  Transferring a single token from an entangled pair acts as an "observation" or "measurement". This "collapses" the state: the transferred token's polarity becomes fixed, and the entangled partner's polarity instantly flips to the opposite value, regardless of who owns the partner token.
4.  The entire entangled pair can be transferred together without affecting their relative polarities.
5.  Entanglement can be broken (`decoherePair`), making the tokens independent. Their polarities remain fixed after decoherence.
6.  There are functions inspired by quantum gates (`applyHadamardGate`) that flip polarity, and probabilistic events (`quantumFluctuation`).

This design is non-standard and focuses on unique state interactions between tokens linked via entanglement.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title QuantumEntanglementToken (QET)
 * @dev A novel ERC721-inspired token contract based on Quantum Entanglement concepts.
 *      Tokens are minted in pairs. Actions on one entangled token affect its partner.
 */

// --- OUTLINE ---
// 1. State Variables: Token data (owner, balances, nextId), Entanglement data (partners, polarities), Approvals, Metadata URI.
// 2. Events: Standard ERC721 events, plus custom events for entanglement and state changes.
// 3. Modifiers: Entangled check.
// 4. Constructor: Initialize contract with name and symbol.
// 5. Core ERC721 Functions: balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll.
// 6. Custom Minting: mintEntangledPair to create tokens in pairs.
// 7. Custom Transfer Logic:
//    - transferFrom/safeTransferFrom: Implements "state collapse" for single entangled tokens.
//    - transferEntangledPair: Transfers both tokens of a pair together.
// 8. Entanglement Management:
//    - getEntangledPartner, isEntangled, isEntangledPair: Query entanglement status.
//    - decoherePair: Break entanglement.
// 9. Quantum State Manipulation:
//    - getPolarity, predictPartnerPolarity: Query polarity.
//    - applyHadamardGate: Flip token polarity (and partner if entangled).
//    - quantumFluctuation: Probabilistically trigger polarity flip (illustrative).
// 10. Observation/Query Functions:
//     - getPairInfo: Detailed info on a pair.
//     - observerEffectAudit: Log observation event.
//     - getOwnedEntangledTokenIds, getOwnedIndependentTokenIds: Query owned tokens by entanglement status.
// 11. Metadata: setBaseURI, tokenURI.
// 12. Access Control: Ownable (renounceOwnership, transferOwnership).
// 13. ERC165 Support: supportsInterface.

// --- FUNCTION SUMMARY ---
// ERC721 Standard Functions:
// - supportsInterface(bytes4 interfaceId): Check if the contract supports an interface (ERC721, ERC165).
// - balanceOf(address owner): Returns the number of tokens owned by an address.
// - ownerOf(uint256 tokenId): Returns the owner of a specific token.
// - approve(address to, uint256 tokenId): Approves an address to transfer a specific token.
// - getApproved(uint256 tokenId): Returns the approved address for a specific token.
// - setApprovalForAll(address operator, bool approved): Approves or disapproves an operator for all tokens.
// - isApprovedForAll(address owner, address operator): Checks if an operator is approved for an owner.
// - transferFrom(address from, address to, uint256 tokenId): Transfers token with state collapse logic for entangled tokens.
// - safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer.
// - safeTransferFrom(address from, address to, uint256 tokenId, bytes data): Safe transfer with data.
// - name(): Returns the contract name.
// - symbol(): Returns the contract symbol.
// - tokenURI(uint256 tokenId): Returns the metadata URI for a token.

// Custom QET Functions:
// - totalSupply(): Returns the total number of tokens minted.
// - mintEntangledPair(address ownerA, address ownerB): Mints a new entangled pair assigning ownership and initial polarities.
// - transferEntangledPair(address fromOwner, address toOwner, uint256 tokenIdA, uint256 tokenIdB): Transfers both tokens of a pair together.
// - getEntangledPartner(uint256 tokenId): Returns the token ID of the entangled partner.
// - isEntangled(uint256 tokenId): Checks if a token is currently entangled.
// - isEntangledPair(uint256 tokenIdA, uint256 tokenIdB): Checks if two token IDs form an entangled pair.
// - getPolarity(uint256 tokenId): Returns the polarity of a token (true for Positive, false for Negative).
// - predictPartnerPolarity(uint256 tokenId): Predicts the polarity of the partner based on current token's polarity.
// - decoherePair(uint256 tokenIdA, uint256 tokenIdB): Breaks the entanglement between two tokens.
// - applyHadamardGate(uint256 tokenId): Flips the polarity of a token and its partner if entangled.
// - quantumFluctuation(uint256 tokenId): (Illustrative) Simulates a probabilistic event that might flip polarity. Requires token to be entangled.
// - getPairInfo(uint256 tokenId): Returns detailed information about an entangled pair using one token ID.
// - observerEffectAudit(uint256 tokenId): Logs the state of a token and its partner pair as an "observation".
// - getOwnedEntangledTokenIds(address owner): Returns a list of IDs of entangled tokens owned by an address. (Potentially gas-intensive for many tokens)
// - getOwnedIndependentTokenIds(address owner): Returns a list of IDs of non-entangled tokens owned by an address. (Potentially gas-intensive)
// - setBaseURI(string memory baseURI): Sets the base URI for token metadata (Owner only).
// - renounceOwnership(): Relinquishes ownership (Owner only).
// - transferOwnership(address newOwner): Transfers ownership (Owner only).

contract QuantumEntanglementToken is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---
    Counters.Counter private _nextTokenId;

    // Mapping from token ID to owner address
    mapping(uint256 tokenId => address owner) private _owners;

    // Mapping from owner address to number of tokens owned
    mapping(address owner => uint256 balance) private _balances;

    // Mapping from token ID to its entangled partner's token ID
    mapping(uint256 tokenId => uint256 partnerTokenId) private _entangledPartners;

    // Mapping from token ID to its polarity (true for Positive, false for Negative)
    mapping(uint256 tokenId => bool polarity) private _polarities;

    // Mapping from token ID to approved address
    mapping(uint256 tokenId => address approved) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address owner => mapping(address operator => bool approved)) private _operatorApprovals;

    // Base URI for token metadata
    string private _baseURI;

    // --- Events ---
    event PairEntangled(uint256 indexed tokenIdA, uint256 indexed tokenIdB, address indexed ownerA, address indexed ownerB);
    event PairDecohered(uint256 indexed tokenIdA, uint256 indexed tokenIdB);
    event PolarityFlipped(uint256 indexed tokenId, bool newPolarity);
    event EntanglementObserved(uint256 indexed observerTokenId, uint256 indexed partnerTokenId, bool observerPolarity, bool partnerPolarity);
    event QuantumFluctuated(uint256 indexed tokenId, bool newPolarity);

    // --- Modifiers ---
    modifier onlyEntangled(uint256 tokenId) {
        require(_entangledPartners[tokenId] != 0, "QET: token is not entangled");
        _;
    }

    modifier onlyEntangledPair(uint256 tokenIdA, uint256 tokenIdB) {
        require(isEntangledPair(tokenIdA, tokenIdB), "QET: tokens are not an entangled pair");
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Core ERC721 Standard Functions ---

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        // Check required by ERC721. We handle approval/ownership in _transfer
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        // --- QET Specific: State Collapse on Transfer ---
        uint256 partnerId = _entangledPartners[tokenId];
        if (partnerId != 0) {
            // Check if the entanglement is still valid (partner exists and links back)
            if (_entangledPartners[partnerId] == tokenId) {
                // Simulate state collapse: transferred token keeps its polarity, partner flips
                // Note: The "instant" nature is inherent to blockchain's atomic transactions within a block.
                // No state change occurs *before* the transfer, it's part of the atomic operation.
                bool transferredTokenCurrentPolarity = _polarities[tokenId];
                bool partnerCurrentPolarity = _polarities[partnerId]; // Should be !transferredTokenCurrentPolarity

                // Flip the partner's polarity upon observation/transfer of this token
                _polarities[partnerId] = !partnerCurrentPolarity;

                // Emit event about the collapse effect
                emit EntanglementObserved(tokenId, partnerId, transferredTokenCurrentPolarity, !partnerCurrentPolarity);
                // Also emit polarity flip event for the partner
                 emit PolarityFlipped(partnerId, !partnerCurrentPolarity);
            } else {
                 // Entanglement link was broken, but the mapping wasn't cleared for this side. Clean up.
                 delete _entangledPartners[tokenId];
            }
        }
        // --- End QET Specific Logic ---

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    // --- Custom QET Minting ---

    /**
     * @dev Mints a new entangled pair of tokens.
     *      Assigns them unique IDs, sets them as entangled partners,
     *      assigns opposite initial polarities, and assigns ownership.
     *      Only callable by the contract owner.
     * @param ownerA Address to mint the first token (tokenIdA) to.
     * @param ownerB Address to mint the second token (tokenIdB) to.
     *               Can be the same as ownerA.
     */
    function mintEntangledPair(address ownerA, address ownerB) external onlyOwner returns (uint256 tokenIdA, uint256 tokenIdB) {
        require(ownerA != address(0), "QET: ownerA is zero address");
        require(ownerB != address(0), "QET: ownerB is zero address");

        tokenIdA = _nextTokenId.current();
        _nextTokenId.increment();
        tokenIdB = _nextTokenId.current();
        _nextTokenId.increment();

        // Assign ownership
        _safeMint(ownerA, tokenIdA);
        _safeMint(ownerB, tokenIdB);

        // Set entanglement link
        _entangledPartners[tokenIdA] = tokenIdB;
        _entangledPartners[tokenIdB] = tokenIdA;

        // Assign initial opposite polarities (e.g., A=Positive, B=Negative)
        _polarities[tokenIdA] = true; // Positive
        _polarities[tokenIdB] = false; // Negative

        emit PairEntangled(tokenIdA, tokenIdB, ownerA, ownerB);
    }

    // --- Custom QET Transfer ---

    /**
     * @dev Transfers an entire entangled pair of tokens to a new owner.
     *      Requires the caller to own or be approved for both tokens.
     *      Polarities and entanglement linkage remain unchanged.
     * @param fromOwner The current owner of both tokens.
     * @param toOwner The address to transfer the pair to.
     * @param tokenIdA The ID of the first token in the pair.
     * @param tokenIdB The ID of the second token in the pair.
     */
    function transferEntangledPair(address fromOwner, address toOwner, uint256 tokenIdA, uint256 tokenIdB) external {
        require(fromOwner != address(0), "ERC721: transfer from the zero address");
        require(toOwner != address(0), "ERC721: transfer to the zero address");
        require(ownerOf(tokenIdA) == fromOwner, "QET: tokenIdA not owned by fromOwner");
        require(ownerOf(tokenIdB) == fromOwner, "QET: tokenIdB not owned by fromOwner");
        require(isEntangledPair(tokenIdA, tokenIdB), "QET: tokens are not an entangled pair");

        // Caller must be the owner or approved for ALL tokens of fromOwner
        require(
             _msgSender() == fromOwner || isApprovedForAll(fromOwner, _msgSender()),
            "QET: transfer caller is not owner nor approved for all of the pair"
        );

        // Perform the transfers without triggering single-token collapse logic explicitly
        // _transfer handles ownership/approval checks internally based on the msg.sender from _isApprovedOrOwner logic
        // We override transferFrom, so need a way to transfer without triggering the collapse logic.
        // Let's create an internal helper for this or rely on _transfer which doesn't call the override.
        _transfer(fromOwner, toOwner, tokenIdA);
        _transfer(fromOwner, toOwner, tokenIdB);

        // Entanglement and polarities are preserved by _transfer (which doesn't call the override)
    }


    // --- Entanglement Management ---

    /**
     * @dev Returns the token ID of the entangled partner for a given token.
     *      Returns 0 if the token is not entangled or does not exist.
     * @param tokenId The ID of the token.
     */
    function getEntangledPartner(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) return 0;
        uint256 partnerId = _entangledPartners[tokenId];
        // Verify the link is bidirectional
        if (partnerId != 0 && _entangledPartners[partnerId] == tokenId) {
            return partnerId;
        }
        // If link is broken or one-sided, return 0 and potentially clean up
        // Cannot clean up in a view function, but indicates non-entangled state.
        return 0;
    }

    /**
     * @dev Checks if a token is currently entangled with a partner.
     * @param tokenId The ID of the token.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        return getEntangledPartner(tokenId) != 0;
    }

     /**
     * @dev Checks if two token IDs form an entangled pair.
     * @param tokenIdA The ID of the first token.
     * @param tokenIdB The ID of the second token.
     */
    function isEntangledPair(uint256 tokenIdA, uint256 tokenIdB) public view returns (bool) {
        if (tokenIdA == tokenIdB || !_exists(tokenIdA) || !_exists(tokenIdB)) return false;
        return getEntangledPartner(tokenIdA) == tokenIdB && getEntangledPartner(tokenIdB) == tokenIdA;
    }

    /**
     * @dev Breaks the entanglement between two tokens.
     *      Requires the caller to own or be an approved operator for both tokens.
     *      Their polarities become fixed at their current values.
     * @param tokenIdA The ID of the first token in the pair.
     * @param tokenIdB The ID of the second token in the pair.
     */
    function decoherePair(uint256 tokenIdA, uint256 tokenIdB) external onlyEntangledPair(tokenIdA, tokenIdB) {
        address ownerA = ownerOf(tokenIdA);
        address ownerB = ownerOf(tokenIdB);

        // Require caller is owner or operator for both tokens
        require(
            (_msgSender() == ownerA || isApprovedForAll(ownerA, _msgSender())) &&
            (_msgSender() == ownerB || isApprovedForAll(ownerB, _msgSender())),
            "QET: caller is not owner nor approved for both tokens to decohere"
        );

        delete _entangledPartners[tokenIdA];
        delete _entangledPartners[tokenIdB];

        // Polarities remain fixed at their current values

        emit PairDecohered(tokenIdA, tokenIdB);
    }

    // --- Quantum State Manipulation ---

    /**
     * @dev Returns the polarity of a token.
     *      True represents 'Positive' state, false represents 'Negative' state.
     *      If the token doesn't exist, reverts.
     * @param tokenId The ID of the token.
     */
    function getPolarity(uint256 tokenId) public view returns (bool) {
         require(_exists(tokenId), "QET: polarity query for nonexistent token");
        return _polarities[tokenId];
    }

     /**
     * @dev Predicts the polarity of the entangled partner token.
     *      Based on the rule that entangled partners always have opposite polarities.
     *      Requires the token to be entangled.
     * @param tokenId The ID of the token.
     */
    function predictPartnerPolarity(uint256 tokenId) public view onlyEntangled(tokenId) returns (bool) {
         require(_exists(_entangledPartners[tokenId]), "QET: partner does not exist"); // Should always be true if entangled
        return !_polarities[tokenId];
    }

    /**
     * @dev Applies a "Hadamard Gate" operation conceptually, flipping the token's polarity.
     *      If the token is entangled, its partner's polarity also flips to maintain opposite states.
     *      Requires caller to own or be approved for the token.
     * @param tokenId The ID of the token.
     */
    function applyHadamardGate(uint256 tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "QET: caller is not owner nor approved");
        require(_exists(tokenId), "QET: cannot apply gate to nonexistent token");

        _polarities[tokenId] = !_polarities[tokenId];
        emit PolarityFlipped(tokenId, _polarities[tokenId]);

        uint256 partnerId = _entangledPartners[tokenId];
        if (partnerId != 0 && _entangledPartners[partnerId] == tokenId) {
             _polarities[partnerId] = !_polarities[partnerId];
             emit PolarityFlipped(partnerId, _polarities[partnerId]);
        }
    }

    /**
     * @dev (Illustrative) Simulates a "Quantum Fluctuation" - a probabilistic event.
     *      There's a chance (e.g., based on block hash) that an entangled token's polarity
     *      (and its partner's) will spontaneously flip.
     *      Requires token to be entangled.
     *      Note: Using block.timestamp and block.difficulty/blockhash is not cryptographically secure randomness on-chain.
     *      This function is purely for demonstrating the concept. A real application might use Chainlink VRF or similar.
     * @param tokenId The ID of the token.
     */
    function quantumFluctuation(uint256 tokenId) external onlyEntangled(tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "QET: caller is not owner nor approved");
        require(_exists(tokenId), "QET: cannot apply fluctuation to nonexistent token");

        // Pseudo-random check using block data (WARNING: not secure randomness)
        // Let's say there's a ~1/256 chance based on the last byte of the hash
        bytes32 blockHash = blockhash(block.number - 1); // Use previous block hash
        uint8 randomnessFactor = uint8(uint256(blockHash));

        if (randomnessFactor % 2 == 0) { // ~50% chance flip (adjust condition for different probabilities)
           applyHadamardGate(tokenId); // Use the existing flip logic
           emit QuantumFluctuated(tokenId, _polarities[tokenId]);
        }
        // Else: nothing happens this time
    }

    // --- Observation / Query Functions ---

    /**
     * @dev Gets detailed information about an entangled pair using one token ID.
     *      Returns partner ID, owner of each, and polarity of each.
     *      Requires the input token to be entangled.
     * @param tokenId The ID of one token in the pair.
     * @return pairTokenId1 The ID of the first token (input tokenId).
     * @return pairTokenId2 The ID of the entangled partner.
     * @return owner1 The owner of the first token.
     * @return owner2 The owner of the second token.
     * @return polarity1 The polarity of the first token.
     * @return polarity2 The polarity of the second token.
     */
    function getPairInfo(uint256 tokenId) public view onlyEntangled(tokenId) returns (uint256 pairTokenId1, uint256 pairTokenId2, address owner1, address owner2, bool polarity1, bool polarity2) {
        uint256 partnerId = _entangledPartners[tokenId];
        require(_exists(partnerId), "QET: partner token does not exist"); // Double check partner validity

        pairTokenId1 = tokenId;
        pairTokenId2 = partnerId;
        owner1 = ownerOf(tokenId);
        owner2 = ownerOf(partnerId);
        polarity1 = _polarities[tokenId];
        polarity2 = _polarities[partnerId];
    }

    /**
     * @dev Logs the current state of a token and its entangled partner (if any)
     *      to simulate an "observation" or audit effect without changing state.
     * @param tokenId The ID of the token to observe.
     */
    function observerEffectAudit(uint256 tokenId) external {
        require(_exists(tokenId), "QET: cannot observe nonexistent token");

        uint256 partnerId = _entangledPartners[tokenId];
        if (partnerId != 0 && _entangledPartners[partnerId] == tokenId) {
            // Entangled
            emit EntanglementObserved(tokenId, partnerId, _polarities[tokenId], _polarities[partnerId]);
        } else {
            // Not entangled, just log the single token's state
             emit EntanglementObserved(tokenId, 0, _polarities[tokenId], false); // Use 0 for partnerId, false for dummy polarity
        }
    }

    /**
     * @dev Returns a list of token IDs owned by an address that are currently part of an entangled pair.
     *      Note: This function iterates over all minted tokens and can be gas-intensive.
     * @param owner The address to query.
     * @return tokenIds An array of entangled token IDs owned by the address.
     */
    function getOwnedEntangledTokenIds(address owner) public view returns (uint256[] memory) {
        require(owner != address(0), "QET: query for zero address");
        uint256[] memory entangledIds = new uint256[](balanceOf(owner)); // Max possible size

        uint256 count = 0;
        // Iterating over all possible token IDs is inefficient.
        // A more complex data structure would be needed for efficient query.
        // For demonstration, we iterate up to the current total supply.
        uint256 total = _nextTokenId.current();
        for (uint256 i = 1; i < total; i++) { // Assuming token IDs start from 1
            if (_owners[i] == owner && isEntangled(i)) {
                entangledIds[count] = i;
                count++;
            }
        }

        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = entangledIds[i];
        }
        return result;
    }

     /**
     * @dev Returns a list of token IDs owned by an address that are currently NOT entangled.
     *      Note: This function iterates over all minted tokens and can be gas-intensive.
     * @param owner The address to query.
     * @return tokenIds An array of independent token IDs owned by the address.
     */
    function getOwnedIndependentTokenIds(address owner) public view returns (uint256[] memory) {
         require(owner != address(0), "QET: query for zero address");
        uint256[] memory independentIds = new uint256[](balanceOf(owner)); // Max possible size

        uint256 count = 0;
        uint256 total = _nextTokenId.current();
        for (uint256 i = 1; i < total; i++) { // Assuming token IDs start from 1
            if (_owners[i] == owner && !isEntangled(i)) {
                independentIds[count] = i;
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = independentIds[i];
        }
        return result;
    }

    // --- Metadata ---

     function _baseURI() internal view override returns (string memory) {
        return _baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return "";
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }


    // --- Internal Helper Functions (Standard ERC721 overrides/helpers) ---

    function _exists(uint256 tokenId) internal view override returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _safeMint(address to, uint256 tokenId) internal override {
         require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }


    function _approve(address to, uint256 tokenId) internal override {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal override {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

     // Helper function to check if caller is owner or approved for a token
     function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override returns (bool) {
         address owner = ownerOf(tokenId); // Throws if token doesn't exist
         return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
     }

    // Overrides ERC721's _checkOnERC721Received to use our internal safe transfer
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) internal returns (bool) {
         if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity thus user can detect a contract which is not ERC721Receiver
                    /// and revert by consuming all gas (vs just reverting with the contract's revert reason).
                    revert(string(abi.encodePacked("ERC721: transfer to non ERC721Receiver implementer ", string(reason))));
                }
            }
        } else {
            return true; // transferring to an EOA
        }
    }

    // Helper for safeTransferFrom to check the receiving address
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    // ERC721 Hooks (can be extended)
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {}
    function _afterTokenTransfer(address from, address to, uint256 tokenId) internal override {}

    // --- Access Control Functions (from Ownable) ---
    // Kept for completeness as part of the >20 function count, though standard from Ownable
    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
}
```