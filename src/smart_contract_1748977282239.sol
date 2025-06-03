Okay, let's design a smart contract that incorporates some interesting, advanced-concept features related to NFTs, state changes, and interactions, inspired by analogies from quantum mechanics – specifically, entanglement and state observation. We'll call it `QuantumEntanglementNFT`.

This contract won't implement actual quantum computing, but it will use the concepts of entanglement (linking two NFTs), superposition (a state that isn't fixed until "observed"), and decoherence (loss of entanglement) as core mechanics for how the NFTs behave and interact. It will also have a dynamic `tokenURI` based on the NFT's state.

We'll implement standard ERC-721-like functionalities but with custom logic that incorporates the quantum mechanics. We'll aim for over 20 distinct functions covering core logic, state management, admin controls, and query methods.

---

**Contract Outline and Function Summary:**

**Contract Name:** `QuantumEntanglementNFT`

**Description:** A novel NFT contract where tokens are minted in entangled pairs. These NFTs exist in a "superposition" state until explicitly "observed," collapsing into a fixed state (StateA or StateB). Entangled pairs share properties and interacting with one token (like transferring it) affects the "coherence" level of the pair, potentially leading to "decoherence" (loss of entanglement) and state changes for both. The `tokenURI` is dynamic based on the token's current quantum state.

**Core Concepts:**

1.  **Entanglement:** Tokens are minted in pairs. Actions on one token can affect its entangled partner.
2.  **Superposition:** NFTs have a probabilistic state until an `observeQuantumState` function is called.
3.  **Observation:** The act of calling `observeQuantumState` collapses the superposition, fixing the NFT's state permanently (StateA or StateB). This might require a fee.
4.  **Coherence & Decoherence:** An "entanglement coherence level" exists for each pair, decreasing with certain interactions (like transfers). Below a threshold, entanglement is lost (decoherence), potentially altering the tokens' states.
5.  **Dynamic State & URI:** The token's state (Superposition, StateA, StateB, Decohered) influences its behavior and its associated metadata/URI.

**Functions:**

1.  `constructor()`: Initializes the contract owner and basic parameters.
2.  `balanceOf(address owner)`: Returns the number of tokens owned by an address (ERC721-like).
3.  `ownerOf(uint256 tokenId)`: Returns the owner of a specific token (ERC721-like).
4.  `getApproved(uint256 tokenId)`: Gets the approved address for a single token (ERC721-like).
5.  `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all owner's tokens (ERC721-like).
6.  `approve(address to, uint256 tokenId)`: Approves an address to manage a specific token (ERC721-like).
7.  `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all tokens (ERC721-like).
8.  `transferFrom(address from, address to, uint256 tokenId)`: Transfers token ownership. Includes custom logic to check/affect entanglement and coherence.
9.  `safeTransferFrom(address from, address to, uint256 tokenId)`: Safe transfer of token ownership (ERC721-like, wraps `transferFrom`).
10. `mintEntangledPair(address owner1, address owner2)`: Mints two new tokens as an entangled pair, assigning them to specified owners. Sets initial superposition state and coherence.
11. `observeQuantumState(uint256 tokenId)`: Triggers the "observation" process for a token in superposition. Randomly (using block data) assigns and locks its state (StateA or StateB). Requires paying the `observationFee`.
12. `getQuantumState(uint256 tokenId)`: Returns the current quantum state of a token (Superposition, StateA, StateB, Decohered).
13. `getObservedState(uint256 tokenId)`: Returns the *locked* observed state if the token has been observed (StateA, StateB, or None).
14. `getEntanglementStatus(uint256 tokenId)`: Checks if a token is currently entangled.
15. `getCohereceLevel(uint256 tokenId)`: Gets the current coherence level of the entangled pair the token belongs to.
16. `applyCoherenceBoost(uint256 tokenId)`: Applies a boost to the coherence level of the token's entangled pair (requires calling logic, e.g., payment, burning another token - let's simplify to owner/approved caller for this example).
17. `triggerDecoherenceCheck(uint256 tokenId)`: Allows anyone to trigger a check for decoherence conditions (e.g., based on low coherence, time since last interaction). If conditions met, marks the pair as decohered.
18. `getEntanglementId(uint256 tokenId)`: Returns the unique ID linking the entangled pair.
19. `getOtherTokenInPair(uint256 tokenId)`: Given one token ID in a pair, returns the ID of the other token.
20. `tokenURI(uint256 tokenId)`: Returns the metadata URI for a token, dynamically generated or selected based on its `QuantumState` and `ObservedState`.
21. `setObservationFee(uint256 fee)`: Owner function to set the fee required for observation.
22. `setTransferCoherenceLoss(uint256 loss)`: Owner function to set the amount of coherence lost per transfer.
23. `setBoostCoherenceGain(uint256 gain)`: Owner function to set the amount of coherence gained per boost.
24. `setDecoherenceThreshold(uint256 threshold)`: Owner function to set the minimum coherence level required to remain entangled.
25. `setQuantumStateProbabilities(uint256 probStateA, uint256 probStateB)`: Owner function to set the probabilities (must sum to 10000, representing 100%) for collapsing to StateA vs StateB during observation.
26. `setBaseURI(string memory baseURI)`: Owner function to set the base URI used for `tokenURI`.
27. `withdrawFees()`: Owner function to withdraw collected observation fees.
28. `getTokenInfo(uint256 tokenId)`: Helper function to get aggregated information about a token (owner, state, observed state, entanglement status, pair ID, coherence).
29. `getPairInfo(uint256 entanglementId)`: Helper function to get aggregated information about an entangled pair.
30. `getTotalSupply()`: Returns the total number of tokens minted.
31. `burn(uint256 tokenId)`: Destroys a token. Includes logic for how this affects its entangled partner.
32. `splitEntanglement(uint256 entanglementId)`: Owner function to forcefully break the entanglement of a pair.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntanglementNFT
 * @dev A novel NFT contract utilizing concepts of quantum entanglement, superposition,
 * observation, and decoherence. Tokens are minted in pairs, their state is
 * probabilistic until observed, and interactions affect their linkage (coherence).
 * Based on ERC-721 principles but with custom state management and transfer logic.
 */

/**
 * @notice Contract Outline and Function Summary (Detailed in Header)
 * - Core Concepts: Entanglement, Superposition, Observation, Coherence/Decoherence, Dynamic State/URI.
 * - Functions:
 *   1. constructor(): Contract initialization.
 *   2. balanceOf(address owner): Get token count for owner. (ERC721-like)
 *   3. ownerOf(uint256 tokenId): Get owner of token. (ERC721-like)
 *   4. getApproved(uint256 tokenId): Get approved address for token. (ERC721-like)
 *   5. isApprovedForAll(address owner, address operator): Check operator approval. (ERC721-like)
 *   6. approve(address to, uint256 tokenId): Approve address for token. (ERC721-like)
 *   7. setApprovalForAll(address operator, bool approved): Set operator approval. (ERC721-like)
 *   8. transferFrom(address from, address to, uint256 tokenId): Transfer token with entanglement/coherence logic.
 *   9. safeTransferFrom(address from, address to, uint256 tokenId): Safe transfer wrapper. (ERC721-like)
 *   10. mintEntangledPair(address owner1, address owner2): Create a new entangled pair.
 *   11. observeQuantumState(uint256 tokenId): Collapse superposition to a fixed state (requires fee).
 *   12. getQuantumState(uint256 tokenId): Get current quantum state (Superposition, StateA, StateB, Decohered).
 *   13. getObservedState(uint256 tokenId): Get the permanently locked state (StateA, StateB, None).
 *   14. getEntanglementStatus(uint256 tokenId): Check if token is entangled.
 *   15. getCohereceLevel(uint256 tokenId): Get pair's coherence level.
 *   16. applyCoherenceBoost(uint256 tokenId): Increase pair's coherence (Admin/Approved).
 *   17. triggerDecoherenceCheck(uint256 tokenId): Manually check for decoherence conditions.
 *   18. getEntanglementId(uint256 tokenId): Get the pair's unique entanglement ID.
 *   19. getOtherTokenInPair(uint256 tokenId): Find the other token ID in the pair.
 *   20. tokenURI(uint256 tokenId): Get dynamic metadata URI based on state.
 *   21. setObservationFee(uint256 fee): Admin: Set observation fee.
 *   22. setTransferCoherenceLoss(uint256 loss): Admin: Set coherence loss per transfer.
 *   23. setBoostCoherenceGain(uint256 gain): Admin: Set coherence gain per boost.
 *   24. setDecoherenceThreshold(uint256 threshold): Admin: Set coherence threshold for decoherence.
 *   25. setQuantumStateProbabilities(uint256 probStateA, uint256 probStateB): Admin: Set state observation probabilities.
 *   26. setBaseURI(string memory baseURI): Admin: Set base URI for token metadata.
 *   27. withdrawFees(): Admin: Withdraw accumulated fees.
 *   28. getTokenInfo(uint256 tokenId): Helper: Get comprehensive token details.
 *   29. getPairInfo(uint256 entanglementId): Helper: Get comprehensive pair details.
 *   30. getTotalSupply(): Get total number of tokens.
 *   31. burn(uint256 tokenId): Burn a token, affects its partner.
 *   32. splitEntanglement(uint256 entanglementId): Admin: Forcefully break entanglement.
 */

contract QuantumEntanglementNFT {

    // --- State Variables ---

    // ERC-721-like State
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 private _tokenIdCounter;
    string private _baseURI;

    // Quantum State Management
    enum QuantumState { Superposition, StateA, StateB, Decohered }
    enum ObservedState { None, StateA, StateB } // Locked state after observation

    mapping(uint256 => QuantumState) private _tokenQuantumState;
    mapping(uint256 => ObservedState) private _tokenObservedState;
    mapping(uint256 => uint256) private _tokenObservationBlock; // Block when observation happened

    // Entanglement Management
    struct EntangledPairInfo {
        uint256 tokenId1; // Lower token ID in the pair
        uint256 tokenId2; // Higher token ID in the pair
        uint256 coherenceLevel;
        bool isEntangled;
    }

    uint256 private _entanglementIdCounter;
    mapping(uint256 => uint256) private _tokenIdToEntanglementId;
    mapping(uint256 => EntangledPairInfo) private _entanglementIdToPairInfo;

    // Configuration Parameters (Admin Configurable)
    address public owner;
    address public feeRecipient;
    uint256 public observationFee = 0.01 ether; // Fee to observe a token
    uint256 public transferCoherenceLoss = 50; // Amount of coherence lost per transfer (out of 10000 max)
    uint256 public boostCoherenceGain = 1000; // Amount of coherence gained per boost
    uint256 public maxCoherence = 10000; // Max possible coherence level
    uint256 public decoherenceThreshold = 1000; // Coherence level below which entanglement is lost
    uint256 public probStateA_10000 = 5000; // Probability of collapsing to StateA (out of 10000)

    // --- Events ---

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event EntangledPairCreated(uint256 indexed entanglementId, uint256 indexed tokenId1, uint256 indexed tokenId2);
    event QuantumStateChanged(uint256 indexed tokenId, QuantumState newState);
    event QuantumStateObserved(uint256 indexed tokenId, ObservedState observedState, uint256 observationBlock);
    event EntanglementLost(uint256 indexed entanglementId, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 finalCoherence);
    event CoherenceBoosted(uint256 indexed entanglementId, uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 newCoherence);
    event FeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenEntangled(uint256 tokenId) {
        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        require(entanglementId != 0, "Not part of any pair");
        require(_entanglementIdToPairInfo[entanglementId].isEntangled, "Not currently entangled");
        _;
    }

    modifier whenSuperposition(uint256 tokenId) {
        require(_tokenQuantumState[tokenId] == QuantumState.Superposition, "Not in superposition");
        _;
    }

    modifier whenObserved(uint256 tokenId) {
         require(_tokenObservedState[tokenId] != ObservedState.None, "Has not been observed");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        feeRecipient = msg.sender; // Default fee recipient
        _tokenIdCounter = 0; // Start token IDs from 1
        _entanglementIdCounter = 0; // Start entanglement IDs from 1
    }

    // --- ERC-721-like Functions (Custom Logic) ---

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner_) public view returns (uint256) {
        require(owner_ != address(0), "Owner query for non-existent address");
        return _balances[owner_];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner_ = _owners[tokenId];
        require(owner_ != address(0), "Owner query for non-existent token");
        return owner_;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "Approved query for non-existent token");
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return _operatorApprovals[owner_][operator];
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public {
        address owner_ = ownerOf(tokenId);
        require(msg.sender == owner_ || isApprovedForAll(owner_, msg.sender), "Approval to caller is not owner nor approved for all");
        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * Includes custom logic for entanglement and coherence loss.
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner");
        require(to != address(0), "Transfer to the zero address");

        // --- Quantum Logic Before Transfer ---
        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        if (entanglementId != 0 && _entanglementIdToPairInfo[entanglementId].isEntangled) {
             EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];
             // Decrease coherence level
             pairInfo.coherenceLevel = pairInfo.coherenceLevel > transferCoherenceLoss ?
                                      pairInfo.coherenceLevel - transferCoherenceLoss : 0;

            // Check if decoherence occurred
            if (pairInfo.coherenceLevel < decoherenceThreshold) {
                _triggerDecoherence(entanglementId);
            }
        }
        // --- End Quantum Logic ---

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * ERC721-like safe transfer. Does not include a check for `onERC721Received`
     * as this requires ERC721 standard interface import, which we are avoiding
     * for maximum custom implementation demonstration.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        // Note: A full ERC721 safeTransferFrom would include a check for
        // `to` being a contract and calling its `onERC721Received` hook.
        // This simplified version omits that for brevity and focus on custom logic.
    }

    // --- Quantum Mechanics Functions ---

    /**
     * @dev Mints a new entangled pair of tokens.
     * @param owner1 The address to mint the first token to.
     * @param owner2 The address to mint the second token to.
     */
    function mintEntangledPair(address owner1, address owner2) public onlyOwner {
        require(owner1 != address(0) && owner2 != address(0), "Cannot mint to zero address");

        _entanglementIdCounter++;
        uint256 currentEntanglementId = _entanglementIdCounter;

        uint256 tokenId1 = _mint(owner1);
        uint256 tokenId2 = _mint(owner2);

        // Ensure tokenId1 is the smaller one for consistent pair struct
        if (tokenId1 > tokenId2) {
            (tokenId1, tokenId2) = (tokenId2, tokenId1);
        }

        // Link tokens to entanglement ID
        _tokenIdToEntanglementId[tokenId1] = currentEntanglementId;
        _tokenIdToEntanglementId[tokenId2] = currentEntanglementId;

        // Store pair info
        _entanglementIdToPairInfo[currentEntanglementId] = EntangledPairInfo({
            tokenId1: tokenId1,
            tokenId2: tokenId2,
            coherenceLevel: maxCoherence, // Start with maximum coherence
            isEntangled: true
        });

        // Set initial quantum state to Superposition for both
        _tokenQuantumState[tokenId1] = QuantumState.Superposition;
        _tokenQuantumState[tokenId2] = QuantumState.Superposition;
        _tokenObservedState[tokenId1] = ObservedState.None;
        _tokenObservedState[tokenId2] = ObservedState.None;

        emit EntangledPairCreated(currentEntanglementId, tokenId1, tokenId2);
        emit QuantumStateChanged(tokenId1, QuantumState.Superposition);
        emit QuantumStateChanged(tokenId2, QuantumState.Superposition);
    }

    /**
     * @dev Triggers the "observation" process for a token in Superposition.
     * Randomly collapses the state to StateA or StateB based on probabilities.
     * Requires payment of the observation fee.
     * @param tokenId The ID of the token to observe.
     */
    function observeQuantumState(uint256 tokenId) public payable whenSuperposition(tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(msg.value >= observationFee, "Insufficient observation fee");

        // Pay the fee to the recipient
        (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
        require(success, "Fee payment failed");

        // Pseudo-random state determination
        // Note: Using blockhash/timestamp is susceptible to miner manipulation,
        // especially for low-value outcomes. For serious use, consider a commit-reveal scheme
        // or a decentralized oracle network for randomness.
        uint256 blockValue = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, tokenId)));
        uint256 randomResult = blockValue % 10000;

        ObservedState finalObservedState;
        QuantumState finalQuantumState;

        if (randomResult < probStateA_10000) {
            finalObservedState = ObservedState.StateA;
            finalQuantumState = QuantumState.StateA;
        } else {
            finalObservedState = ObservedState.StateB;
            finalQuantumState = QuantumState.StateB;
        }

        _tokenObservedState[tokenId] = finalObservedState;
        _tokenQuantumState[tokenId] = finalQuantumState; // State changes from Superposition to A or B
        _tokenObservationBlock[tokenId] = block.number;

        emit QuantumStateObserved(tokenId, finalObservedState, block.number);
        emit QuantumStateChanged(tokenId, finalQuantumState);

        // What happens to the entangled partner?
        // Option 1: The partner's superposition collapses too (spooky action at a distance analogy)
        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        if (entanglementId != 0 && _entanglementIdToPairInfo[entanglementId].isEntangled) {
             EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];
             uint256 otherTokenId = pairInfo.tokenId1 == tokenId ? pairInfo.tokenId2 : pairInfo.tokenId1;

             // If the other token is also in Superposition, collapse its state based on THIS token's result
             if (_tokenQuantumState[otherTokenId] == QuantumState.Superposition) {
                  _tokenObservedState[otherTokenId] = finalObservedState; // Same state as the observed one
                  _tokenQuantumState[otherTokenId] = finalQuantumState; // State changes from Superposition to A or B
                  _tokenObservationBlock[otherTokenId] = block.number; // Observed at the same time

                  emit QuantumStateObserved(otherTokenId, finalObservedState, block.number);
                  emit QuantumStateChanged(otherTokenId, finalQuantumState);
             }
             // If the other token was already observed or decohered, nothing happens to it quantum-state-wise due to THIS observation.
        }

    }

    /**
     * @dev Gets the current quantum state of a token.
     * @param tokenId The ID of the token.
     * @return The current state (Superposition, StateA, StateB, Decohered). Defaults to Decohered if token non-existent.
     */
    function getQuantumState(uint256 tokenId) public view returns (QuantumState) {
         if (!_exists(tokenId)) return QuantumState.Decohered; // Or revert, but return might be user friendlier
        return _tokenQuantumState[tokenId];
    }

     /**
     * @dev Gets the permanently locked state of a token after observation.
     * @param tokenId The ID of the token.
     * @return The observed state (StateA, StateB) or None if not observed. Defaults to None if token non-existent.
     */
    function getObservedState(uint256 tokenId) public view returns (ObservedState) {
         if (!_exists(tokenId)) return ObservedState.None;
        return _tokenObservedState[tokenId];
    }

    /**
     * @dev Checks if a token is currently part of an active entangled pair.
     * @param tokenId The ID of the token.
     * @return True if entangled, false otherwise.
     */
    function getEntanglementStatus(uint256 tokenId) public view returns (bool) {
        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        if (entanglementId == 0) return false;
        return _entanglementIdToPairInfo[entanglementId].isEntangled;
    }

    /**
     * @dev Gets the coherence level of the entangled pair a token belongs to.
     * @param tokenId The ID of the token.
     * @return The coherence level (0 to maxCoherence). Returns 0 if not entangled.
     */
    function getCohereceLevel(uint256 tokenId) public view returns (uint256) {
        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        if (entanglementId == 0) return 0; // Not part of any pair
        if (!_entanglementIdToPairInfo[entanglementId].isEntangled) return 0; // Not currently entangled (decohered)
        return _entanglementIdToPairInfo[entanglementId].coherenceLevel;
    }

    /**
     * @dev Applies a boost to the coherence level of the token's entangled pair.
     * This could be triggered by various in-game or contract mechanics.
     * (Simplified: Owner or approved caller can trigger).
     * @param tokenId The ID of a token in the pair to boost.
     */
    function applyCoherenceBoost(uint256 tokenId) public whenEntangled(tokenId) {
        // Example condition: require(msg.sender == owner || isApprovedForCoherenceBoost(msg.sender));
        // For simplicity here, let's allow anyone (demonstration purposes), but in a real app, lock this down.
        // require(msg.sender == owner, "Only owner can boost coherence"); // More realistic

        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];

        uint256 oldCoherence = pairInfo.coherenceLevel;
        pairInfo.coherenceLevel = pairInfo.coherenceLevel + boostCoherenceGain > maxCoherence ?
                                  maxCoherence : pairInfo.coherenceLevel + boostCoherenceGain;

        if (oldCoherence < decoherenceThreshold && pairInfo.coherenceLevel >= decoherenceThreshold) {
             // If boosting brought it back above threshold, maybe it re-entangles?
             // Complex! Let's say for now, once decohered, it's permanent via the bool flag.
             // If it was already entangled, just boost.
        }

        emit CoherenceBoosted(entanglementId, pairInfo.tokenId1, pairInfo.tokenId2, pairInfo.coherenceLevel);
    }

    /**
     * @dev Allows anyone to trigger a check for decoherence conditions for a pair.
     * This is useful if decoherence can happen passively (e.g., over time, or based on state outside a transaction).
     * Our current model primarily triggers decoherence on transfer, but this adds flexibility.
     * For now, it just re-checks the coherence level against the threshold.
     * @param tokenId The ID of a token in the pair to check.
     */
    function triggerDecoherenceCheck(uint256 tokenId) public {
        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        if (entanglementId == 0) return; // Not part of any pair

        EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];

        if (pairInfo.isEntangled && pairInfo.coherenceLevel < decoherenceThreshold) {
            _triggerDecoherence(entanglementId);
        }
         // Could add checks here for time elapsed since last interaction, number of observers, etc.
    }

    /**
     * @dev Internal function to handle the decoherence process for a pair.
     * @param entanglementId The ID of the pair to decohere.
     */
    function _triggerDecoherence(uint256 entanglementId) internal {
         EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];
         if (!pairInfo.isEntangled) return; // Already decohered

         pairInfo.isEntangled = false;

         // Set state of both tokens to Decohered, unless they were already observed
         if (_tokenQuantumState[pairInfo.tokenId1] == QuantumState.Superposition) {
             _tokenQuantumState[pairInfo.tokenId1] = QuantumState.Decohered;
              emit QuantumStateChanged(pairInfo.tokenId1, QuantumState.Decohered);
         }
          if (_tokenQuantumState[pairInfo.tokenId2] == QuantumState.Superposition) {
             _tokenQuantumState[pairInfo.tokenId2] = QuantumState.Decohered;
              emit QuantumStateChanged(pairInfo.tokenId2, QuantumState.Decohered);
         }

         emit EntanglementLost(entanglementId, pairInfo.tokenId1, pairInfo.tokenId2, pairInfo.coherenceLevel);
    }


    /**
     * @dev Gets the entanglement ID for a token.
     * @param tokenId The ID of the token.
     * @return The entanglement ID, or 0 if not part of a pair.
     */
    function getEntanglementId(uint256 tokenId) public view returns (uint256) {
        return _tokenIdToEntanglementId[tokenId];
    }

    /**
     * @dev Gets the token ID of the entangled partner.
     * @param tokenId The ID of one token in the pair.
     * @return The token ID of the partner, or 0 if not part of an entangled pair.
     */
    function getOtherTokenInPair(uint256 tokenId) public view returns (uint256) {
        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        if (entanglementId == 0) return 0; // Not part of any pair

        EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];
        if (!pairInfo.isEntangled) return 0; // Pair is decohered

        return pairInfo.tokenId1 == tokenId ? pairInfo.tokenId2 : pairInfo.tokenId1;
    }

    /**
     * @dev Returns the metadata URI for a token.
     * The URI can be dynamic based on the token's current state.
     * @param tokenId The ID of the token.
     * @return The metadata URI.
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for non-existent token");

        string memory stateIndicator;
        QuantumState currentState = _tokenQuantumState[tokenId];
        ObservedState observedState = _tokenObservedState[tokenId];

        if (currentState == QuantumState.Superposition) {
            stateIndicator = "superposition";
        } else if (currentState == QuantumState.Decohered) {
             stateIndicator = "decohered";
        } else { // StateA or StateB - use the *observed* state for specificity
             if (observedState == ObservedState.StateA) {
                 stateIndicator = "stateA";
             } else { // Must be StateB
                 stateIndicator = "stateB";
             }
        }

        // Example structure: baseURI/tokenId/stateIndicator.json
        // This assumes the metadata server handles paths like /1/superposition.json, /5/stateA.json, etc.
        // Or the metadata could be generated directly on-chain for truly dynamic properties,
        // but complex metadata is typically off-chain.
        return string(abi.encodePacked(_baseURI, Strings.toString(tokenId), "/", stateIndicator, ".json"));
    }

    // --- Admin/Configuration Functions (Owner Only) ---

    /**
     * @dev Sets the fee required to observe a token's quantum state.
     * @param fee The new observation fee in Wei.
     */
    function setObservationFee(uint256 fee) public onlyOwner {
        observationFee = fee;
    }

    /**
     * @dev Sets the amount of coherence lost by a pair when one of its tokens is transferred.
     * @param loss The amount of coherence units to lose (out of maxCoherence).
     */
    function setTransferCoherenceLoss(uint256 loss) public onlyOwner {
        require(loss <= maxCoherence, "Loss cannot exceed max coherence");
        transferCoherenceLoss = loss;
    }

    /**
     * @dev Sets the amount of coherence gained by a pair when a boost is applied.
     * @param gain The amount of coherence units to gain (out of maxCoherence).
     */
    function setBoostCoherenceGain(uint256 gain) public onlyOwner {
        boostCoherenceGain = gain;
    }

    /**
     * @dev Sets the minimum coherence level required for a pair to remain entangled.
     * @param threshold The new decoherence threshold.
     */
    function setDecoherenceThreshold(uint256 threshold) public onlyOwner {
        require(threshold <= maxCoherence, "Threshold cannot exceed max coherence");
        decoherenceThreshold = threshold;
        // Could trigger decoherence check for all existing pairs here if threshold decreases
    }

     /**
     * @dev Sets the probabilities for collapsing to StateA vs StateB upon observation.
     * Probabilities are out of 10000. probStateA_10000 + probStateB_10000 must equal 10000.
     * @param probStateA The probability for StateA (out of 10000).
     * @param probStateB The probability for StateB (out of 10000).
     */
    function setQuantumStateProbabilities(uint256 probStateA, uint256 probStateB) public onlyOwner {
        require(probStateA + probStateB == 10000, "Probabilities must sum to 10000");
        probStateA_10000 = probStateA;
        // probStateB_10000 is implicitly 10000 - probStateA
    }

    /**
     * @dev Sets the base URI for token metadata.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseURI = baseURI_;
    }

    /**
     * @dev Sets the address that receives observation fees.
     * @param recipient The address to receive fees.
     */
    function setFeeRecipient(address recipient) public onlyOwner {
        require(recipient != address(0), "Fee recipient cannot be zero address");
        feeRecipient = recipient;
    }

    /**
     * @dev Allows the owner to withdraw accumulated observation fees.
     */
    function withdrawFees() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner, balance);
    }

    // --- Utility & Query Functions ---

    /**
     * @dev Gets comprehensive information about a token.
     * @param tokenId The ID of the token.
     * @return owner_, state, observedState, isEntangled, entanglementId, coherenceLevel.
     */
    function getTokenInfo(uint256 tokenId) public view returns (
        address owner_,
        QuantumState state,
        ObservedState observedState,
        bool isEntangled,
        uint256 entanglementId,
        uint256 coherenceLevel
    ) {
        owner_ = _owners[tokenId]; // Will be address(0) if non-existent
        state = _tokenQuantumState[tokenId];
        observedState = _tokenObservedState[tokenId];
        entanglementId = _tokenIdToEntanglementId[tokenId];

        if (entanglementId != 0) {
            isEntangled = _entanglementIdToPairInfo[entanglementId].isEntangled;
            coherenceLevel = _entanglementIdToPairInfo[entanglementId].coherenceLevel;
        } else {
            isEntangled = false;
            coherenceLevel = 0;
        }

        return (owner_, state, observedState, isEntangled, entanglementId, coherenceLevel);
    }

    /**
     * @dev Gets comprehensive information about an entangled pair.
     * @param entanglementId The ID of the pair.
     * @return tokenId1, tokenId2, coherenceLevel, isEntangled.
     */
    function getPairInfo(uint256 entanglementId) public view returns (
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 coherenceLevel,
        bool isEntangled
    ) {
        EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];
         // Return default values if entanglementId doesn't exist
        if (pairInfo.tokenId1 == 0 && pairInfo.tokenId2 == 0) {
             return (0, 0, 0, false);
        }
        return (pairInfo.tokenId1, pairInfo.tokenId2, pairInfo.coherenceLevel, pairInfo.isEntangled);
    }


    /**
     * @dev Gets the current total number of tokens minted.
     * @return The total supply.
     */
    function getTotalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @dev Burns (destroys) a token.
     * Includes logic for how burning one token affects its entangled partner.
     * @param tokenId The ID of the token to burn.
     */
    function burn(uint256 tokenId) public {
        address owner_ = ownerOf(tokenId); // Will revert if non-existent
        require(msg.sender == owner_ || _isApprovedOrOwner(msg.sender, tokenId), "Burn caller is not owner nor approved");

        uint256 entanglementId = _tokenIdToEntanglementId[tokenId];
        if (entanglementId != 0) {
            EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];
            if (pairInfo.isEntangled) {
                 // Option: Burning one decoheres the other and potentially burns it too?
                 // Let's make it decohere the other and set its state to Decohered.
                 uint256 otherTokenId = pairInfo.tokenId1 == tokenId ? pairInfo.tokenId2 : pairInfo.tokenId1;

                 // Force decoherence for the pair
                 _triggerDecoherence(entanglementId);

                 // If the other token was not already observed, set its state to Decohered
                 if (_tokenObservedState[otherTokenId] == ObservedState.None) {
                     _tokenQuantumState[otherTokenId] = QuantumState.Decohered;
                     emit QuantumStateChanged(otherTokenId, QuantumState.Decohered);
                 }
                 // The other token remains in existence, but is now decohered.
            }
             // If the pair was already decohered, burning one has no special effect on the other's entanglement state.
        }

        _burn(tokenId, owner_);
    }

     /**
     * @dev Forcefully breaks the entanglement for a pair (Admin/Owner function).
     * @param entanglementId The ID of the pair to split.
     */
    function splitEntanglement(uint256 entanglementId) public onlyOwner {
        EntangledPairInfo storage pairInfo = _entanglementIdToPairInfo[entanglementId];
        require(pairInfo.tokenId1 != 0 || pairInfo.tokenId2 != 0, "Invalid entanglement ID");
        require(pairInfo.isEntangled, "Pair is not currently entangled");

        _triggerDecoherence(entanglementId);
        // Note: This uses the same decoherence logic as when coherence drops naturally.
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Internal transfer function.
     * @param from The address transferring the token.
     * @param to The address receiving the token.
     * @param tokenId The ID of the token being transferred.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer from incorrect owner (internal)"); // Redundant check but good practice
        require(to != address(0), "Transfer to zero address (internal)");

        _approve(address(0), tokenId); // Clear approvals

        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal mint function. Creates a new token with incremented ID.
     * Does not set quantum state or entanglement.
     * @param to The address to mint the token to.
     * @return The newly minted token ID.
     */
    function _mint(address to) internal returns (uint256) {
        require(to != address(0), "Mint to zero address");

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _balances[to]++;
        _owners[newTokenId] = to;
        // Quantum state and entanglement linkage are handled in mintEntangledPair

        emit Transfer(address(0), to, newTokenId);
        return newTokenId;
    }

     /**
     * @dev Internal burn function. Destroys a token.
     * Does not handle entanglement logic directly, caller should do that before calling burn.
     * @param tokenId The ID of the token to burn.
     * @param owner_ The current owner of the token (passed for safety).
     */
    function _burn(uint256 tokenId, address owner_) internal {
        require(ownerOf(tokenId) == owner_, "Burn of incorrect owner (internal)");

        // Clear approvals and owner data
        _approve(address(0), tokenId);
        _balances[owner_]--;
        delete _owners[tokenId];

        // Clear quantum and entanglement data for the burned token
        delete _tokenQuantumState[tokenId];
        delete _tokenObservedState[tokenId];
        delete _tokenObservationBlock[tokenId];
        delete _tokenIdToEntanglementId[tokenId]; // Note: The pair's info in _entanglementIdToPairInfo remains until the *pair* struct is cleared or the *other* token is also burned.

        emit Transfer(owner_, address(0), tokenId);

        // A more complex implementation might track which token in a pair is burned,
        // and potentially clean up the EntangledPairInfo struct if both are burned.
        // For simplicity, the struct entry persists, but `isEntangled` will be false
        // if decohered, or the other token's lookup will fail if only one is burned.
    }


    /**
     * @dev Internal approval function.
     * @param to The address to approve.
     * @param tokenId The ID of the token to approve.
     */
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Checks if a token exists.
     * @param tokenId The ID of the token.
     * @return True if the token exists, false otherwise.
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Checks if msg.sender is the owner or approved for a token.
     * @param spender The address to check.
     * @param tokenId The ID of the token.
     * @return True if the spender is authorized, false otherwise.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner_ = ownerOf(tokenId); // Will revert if non-existent
        return (spender == owner_ || getApproved(tokenId) == spender || isApprovedForAll(owner_, spender));
    }

    // --- Helper library (simplified toString) ---
    // In a real project, use OpenZeppelin's Strings library.
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
}
```