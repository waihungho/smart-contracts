Okay, let's design a smart contract that combines advanced concepts like Non-Fungible Tokens (NFTs) with a simulated process inspired by Quantum Key Exchange (QKE). The idea is that two NFTs can undergo a multi-step "quantum" pairing process to establish a shared secret (a "key") and become linked, unlocking special functions. This avoids duplicating standard ERC721 features directly by building a complex state machine and interaction layer on top.

**Concept:** **QuantumKeyExchangeNFT**

This contract mints unique NFTs. Each NFT can be "prepared" for a simulated quantum key exchange process. Two prepared NFTs, under control of their respective owners, can go through a series of steps mimicking QKE (state preparation, basis selection, measurement simulation, basis comparison, key derivation) to attempt to form a secure, shared secret key. If the simulated keys match, the two NFTs become permanently "paired", enabling unique interactions only between them.

**Outline:**

1.  **Contract Definition:** Inherit ERC721 and Ownable.
2.  **State Variables:**
    *   Standard ERC721 state.
    *   Quantum state data per token (initial bits, chosen bases, revealed bits, derived key).
    *   Status flags per token (prepared, revealed, paired).
    *   Mapping for paired tokens (`pairedWith`).
    *   Message storage for paired tokens.
    *   Admin configurable parameters (key length).
    *   Nonce for pseudo-randomness.
3.  **Events:** Minting, Preparation, BasisSet, Revealed, KeyExchangeInitiated, BasesCompared, KeyDerived, PairingSuccess, PairingFailed, PairingBroken, PairedMessageSent.
4.  **Enums:** Define `Basis` (Standard, Hadamard).
5.  **Modifiers:** Custom modifiers for state checks (e.g., `onlyOwnerOfToken`, `isPrepared`, `isRevealed`, `isPaired`).
6.  **ERC721 Functions:** Standard ERC721 interface functions.
7.  **Core NFT Management:** `mint`, `burn` (optional).
8.  **Quantum Preparation Phase:**
    *   `prepareForQuantumExchange(tokenId)`: Initializes quantum state data, marks as prepared.
    *   `setMeasurementBasis(tokenId, basisData)`: Owner sets the simulated measurement bases.
    *   `revealQuantumState(tokenId)`: Owner reveals the simulated measured state based on the chosen basis.
9.  **Quantum Key Exchange Phase (requires two tokens):**
    *   `initiateKeyExchange(tokenId1, tokenId2)`: Starts the two-token process.
    *   `performBasisComparison(tokenId1, tokenId2)`: Compares the revealed bases of both tokens.
    *   `deriveSharedKey(tokenId1, tokenId2)`: Derives a potential key based on bits where bases matched.
    *   `finalizeKeyExchange(tokenId1, tokenId2)`: Checks if derived keys match. If so, pairs the tokens.
10. **Paired Functionality:**
    *   `isPaired(tokenId)`: Check if a token is paired.
    *   `getPairedToken(tokenId)`: Get the ID of the paired token.
    *   `breakPairing(tokenId)`: Allows owners to break a pairing.
    *   `sendPairedMessage(tokenId, message)`: Send a message only receivable by the paired token.
    *   `getPairedMessage(tokenId)`: Retrieve message from the paired token.
11. **Query/Inspect Functions:**
    *   `getTokenState(tokenId)`: Get quantum state details (admin/debug).
    *   `getTokenStatus(tokenId)`: Get preparation/revealed/paired status.
    *   `getKeyLength()`: Get current key length.
13. **Admin Functions:**
    *   `setKeyLength(length)`: Set the length of the simulated key bits.
    *   `withdrawERC20(tokenAddress, amount)`: Safely withdraw accidentally sent ERC20 tokens.
    *   Ownable functions (`transferOwnership`, `renounceOwnership`).

**Function Summary (approx. 25+ functions):**

*   `constructor()`: Initializes the contract, sets owner and initial key length.
*   `balanceOf(address owner)`: Returns the number of tokens owned by an address (ERC721).
*   `ownerOf(uint265 tokenId)`: Returns the owner of a token (ERC721).
*   `approve(address to, uint256 tokenId)`: Approves an address to transfer a token (ERC721).
*   `getApproved(uint256 tokenId)`: Gets the approved address for a token (ERC721).
*   `setApprovalForAll(address operator, bool approved)`: Sets approval for an operator for all tokens (ERC721).
*   `isApprovedForAll(address owner, address operator)`: Checks if an operator is approved for all tokens (ERC721).
*   `transferFrom(address from, address to, uint256 tokenId)`: Transfers a token (ERC721).
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfers a token safely (ERC721).
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfers a token safely with data (ERC721).
*   `mint(address to, uint256 tokenId)`: Mints a new NFT, assigns it to `to`. (Custom Mint)
*   `prepareForQuantumExchange(uint256 tokenId)`: Marks a token as prepared and generates its initial simulated quantum state. Requires token ownership.
*   `setMeasurementBasis(uint256 tokenId, uint256 basisData)`: Sets the simulated measurement basis mask for a prepared token. `basisData` is a bitmask representing Standard (0) or Hadamard (1) for each bit position. Requires token ownership and prepared state.
*   `revealQuantumState(uint256 tokenId)`: Simulates measuring the quantum state based on the set basis, generating `revealedBits`. Requires token ownership and set basis.
*   `initiateKeyExchange(uint256 tokenId1, uint256 tokenId2)`: Marks two distinct tokens as undergoing exchange. Requires owners' implicit consent via subsequent steps. Requires both tokens are prepared and revealed.
*   `performBasisComparison(uint256 tokenId1, uint256 tokenId2)`: Compares the chosen bases for the two tokens and internally stores a mask indicating bits where bases matched. Requires both tokens are revealed and exchange initiated.
*   `deriveSharedKey(uint256 tokenId1, uint256 tokenId2)`: Derives a potential shared key for each token using their `revealedBits` and the basis comparison mask. Requires basis comparison performed.
*   `finalizeKeyExchange(uint256 tokenId1, uint256 tokenId2)`: Checks if the derived keys for both tokens match. If they do, pairs the tokens. If not, the attempt fails, and tokens may need to be re-prepared. Requires keys derived.
*   `isPaired(uint256 tokenId)`: Returns true if the token is paired with another.
*   `getPairedToken(uint256 tokenId)`: Returns the token ID it's paired with, or 0 if not paired.
*   `breakPairing(uint256 tokenId)`: Allows the owner of *one* paired token to break the pairing.
*   `sendPairedMessage(uint256 tokenId, string memory message)`: Stores a message linked from `tokenId` to its paired token. Requires the token is paired.
*   `getPairedMessage(uint256 tokenId)`: Retrieves the message sent by the paired token to `tokenId`. Requires the token is paired.
*   `getTokenState(uint256 tokenId)`: (Internal/View helper, possibly external for admin/debugger) Returns detailed state info (initial bits, basis, revealed bits, derived key).
*   `getTokenStatus(uint256 tokenId)`: Returns preparation, revealed, and paired status flags.
*   `getKeyLength()`: Returns the currently configured key length.
*   `setKeyLength(uint256 length)`: (Admin Only) Sets the desired length of the simulated key bits. Affects future preparations.
*   `withdrawERC20(address tokenAddress, uint256 amount)`: (Admin Only) Allows withdrawal of ERC20 tokens accidentally sent to the contract.
*   `renounceOwnership()`: (Admin Only) Renounces contract ownership.
*   `transferOwnership(address newOwner)`: (Admin Only) Transfers contract ownership.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title QuantumKeyExchangeNFT
/// @author Your Name/Alias
/// @notice A creative NFT contract simulating Quantum Key Exchange (QKE) to pair tokens.
/// This contract allows minting unique NFTs that can undergo a multi-step simulated
/// QKE process to establish a shared secret key. If the keys match, the two NFTs
/// become permanently paired, unlocking special paired functionalities like secure messaging.
/// This is a simulation for on-chain interaction and does not involve actual quantum mechanics.

// Outline:
// 1. Contract Definition (ERC721, Ownable)
// 2. State Variables (Token data, QKE state, pairing, messages, config)
// 3. Events (Lifecycle, QKE steps, Pairing, Messaging)
// 4. Enums (Basis types)
// 5. Modifiers (Ownership, Token status checks)
// 6. ERC721 Standard Functions
// 7. Core NFT Management (mint)
// 8. Quantum Preparation Phase (prepare, setBasis, reveal)
// 9. Quantum Key Exchange Phase (initiate, compareBases, deriveKey, finalize)
// 10. Paired Functionality (isPaired, getPairedToken, breakPairing, sendPairedMessage, getPairedMessage)
// 11. Query/Inspect Functions (getTokenState, getTokenStatus, getKeyLength)
// 12. Admin Functions (setKeyLength, withdrawERC20, Ownable)

// Function Summary:
// - constructor(): Initialize owner and key length.
// - ERC721 Standard (balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom x2)
// - mint(address to, uint256 tokenId): Mints a new NFT.
// - prepareForQuantumExchange(uint256 tokenId): Prepares a token for QKE, generating initial state.
// - setMeasurementBasis(uint256 tokenId, uint256 basisData): Sets the simulated measurement basis bitmask (0=Standard, 1=Hadamard per bit).
// - revealQuantumState(uint256 tokenId): Simulates measurement based on basis, calculates revealed state.
// - initiateKeyExchange(uint256 tokenId1, uint256 tokenId2): Marks two tokens for exchange process.
// - performBasisComparison(uint256 tokenId1, uint256 tokenId2): Compares bases and finds matching bit positions.
// - deriveSharedKey(uint256 tokenId1, uint256 tokenId2): Derives potential key from revealed bits at matching basis positions.
// - finalizeKeyExchange(uint256 tokenId1, uint256 tokenId2): Compares derived keys and pairs tokens if they match.
// - isPaired(uint256 tokenId): Checks if token is paired.
// - getPairedToken(uint256 tokenId): Gets paired token ID.
// - breakPairing(uint256 tokenId): Breaks an existing pairing.
// - sendPairedMessage(uint256 tokenId, string memory message): Sends a message to paired token.
// - getPairedMessage(uint256 tokenId): Retrieves message from paired token.
// - getTokenState(uint256 tokenId): (Internal/Debug) Gets detailed quantum state data.
// - getTokenStatus(uint256 tokenId): Gets prepared, revealed, paired status.
// - getKeyLength(): Gets configured key length.
// - setKeyLength(uint256 length): Admin sets key length for future tokens.
// - withdrawERC20(address tokenAddress, uint256 amount): Admin withdraws ERC20s.
// - Ownable (renounceOwnership, transferOwnership)

contract QuantumKeyExchangeNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    uint256 public keyLength = 64; // Length of the simulated quantum key in bits (max 256)

    // Simulated Quantum State Data per Token
    mapping(uint256 => uint256) private _initialBits;       // Initial 'state' bits (simulated |0> or |1>)
    mapping(uint256 => uint256) private _measurementBases;  // Chosen measurement bases (0=Standard, 1=Hadamard per bit)
    mapping(uint256 => uint256) private _revealedBits;      // Bits revealed after simulated measurement
    mapping(uint256 => uint256) private _derivedKey;        // Key derived from matching basis measurements

    // Token Status Flags
    mapping(uint256 => bool) private _isPrepared;
    mapping(uint256 => bool) private _basisSet;
    mapping(uint256 => bool) private _isRevealed;
    mapping(uint256 => bool) private _inExchange; // Simple flag for active exchange attempt
    mapping(uint256 => uint256) private _pairedWith;

    // State for Key Exchange Process (tracking masks and shared key attempt)
    mapping(uint256 => uint256) private _basisMatchMask; // Mask indicating bits where bases matched
    mapping(uint256 => uint256) private _exchangePartner; // Temporary partner during exchange process

    // Paired Message Storage
    mapping(uint256 => mapping(uint256 => string)) private _pairedMessages;

    // Pseudo-randomness nonce
    uint256 private _nonce = 0;

    // --- Events ---

    event TokenMinted(address indexed to, uint256 indexed tokenId);
    event TokenPrepared(uint256 indexed tokenId);
    event MeasurementBasisSet(uint256 indexed tokenId, uint256 basisData);
    event QuantumStateRevealed(uint256 indexed tokenId, uint256 revealedBits);
    event KeyExchangeInitiated(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event BasesCompared(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 basisMatchMask);
    event SharedKeyDerived(uint256 indexed tokenId, uint256 derivedKey);
    event PairingSuccess(uint256 indexed tokenId1, uint256 indexed tokenId2, uint256 finalKey);
    event PairingFailed(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PairingBroken(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event PairedMessageSent(uint256 indexed fromTokenId, uint256 indexed toTokenId);
    event KeyLengthSet(uint256 indexed newLength);

    // --- Enums ---

    enum Basis { Standard, Hadamard }

    // --- Modifiers ---

    modifier onlyOwnerOfToken(uint256 tokenId) {
        require(_exists(tokenId), "QKENFT: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "QKENFT: Not owner of token");
        _;
    }

    modifier isPrepared(uint256 tokenId) {
        require(_isPrepared[tokenId], "QKENFT: Token not prepared");
        _;
    }

     modifier isBasisSet(uint256 tokenId) {
        require(_basisSet[tokenId], "QKENFT: Measurement basis not set");
        _;
    }

    modifier isRevealed(uint256 tokenId) {
        require(_isRevealed[tokenId], "QKENFT: Quantum state not revealed");
        _;
    }

    modifier isPaired(uint256 tokenId) {
        require(_pairedWith[tokenId] != 0, "QKENFT: Token is not paired");
        _;
    }

    modifier notPaired(uint256 tokenId) {
        require(_pairedWith[tokenId] == 0, "QKENFT: Token is already paired");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("QuantumKeyExchangeNFT", "QKENFT") Ownable(msg.sender) {}

    // --- Internal Helper Functions (Simulating Quantum Logic) ---

    /// @dev Generates pseudo-random bits using block data and a nonce.
    function _generateRandomBits(uint256 seed) internal returns (uint256) {
        _nonce++;
        // Using blockhash is deprecated/unreliable past 256 blocks.
        // block.difficulty is being removed.
        // Using abi.encodePacked with multiple variable sources for better, but still limited, entropy on EVM.
        // For real-world randomness, oracle solutions are needed. This is for simulation.
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed, _nonce, block.number)));
    }

     /// @dev Gets the bit at a specific position in a uint256.
    function _getBit(uint256 data, uint256 position) internal pure returns (uint8) {
        require(position < 256, "QKENFT: Bit position out of bounds");
        return uint8((data >> position) & 1);
    }

    /// @dev Sets the bit at a specific position in a uint256.
    function _setBit(uint256 data, uint256 position, uint8 bit) internal pure returns (uint256) {
        require(position < 256, "QKENFT: Bit position out of bounds");
        require(bit == 0 || bit == 1, "QKENFT: Bit must be 0 or 1");
        if (bit == 1) {
            return data | (1 << position);
        } else {
            return data & ~(1 << position);
        }
    }

    /// @dev Simulates measurement based on basis.
    /// In BB84-like protocols:
    /// - Standard Basis (Z) measurement on |0> or |1> state yields 0 or 1 deterministically.
    /// - Hadamard Basis (X) measurement on |0> or |1> state yields |+> or |->. Measuring |+> or |-> in Z yields 0 or 1 probabilistically.
    /// This simulation abstracts this:
    /// - Standard Basis measurement reveals the initial bit.
    /// - Hadamard Basis measurement yields a *new* pseudo-random bit (simulating collapse).
    function _simulateMeasurement(uint256 initialBits, uint256 measurementBases, uint256 tokenId) internal returns (uint256) {
        uint256 revealed = 0;
        uint256 randomSeed = _generateRandomBits(tokenId); // Use a unique seed for randomness per token/reveal

        for (uint256 i = 0; i < keyLength; i++) {
            uint8 initialBit = _getBit(initialBits, i);
            uint8 basisBit = _getBit(measurementBases, i); // 0=Standard, 1=Hadamard

            if (basisBit == uint8(Basis.Standard)) {
                // Standard basis reveals original bit
                revealed = _setBit(revealed, i, initialBit);
            } else { // basisBit == uint8(Basis.Hadamard)
                // Hadamard basis measurement is probabilistic in Standard basis (what we simulate observing)
                // Simulate this by using a new random bit
                 uint8 randomBitForHadamard = _getBit(randomSeed, i % 256); // Use a bit from the random seed
                revealed = _setBit(revealed, i, randomBitForHadamard);
            }
        }
        return revealed;
    }

    /// @dev Derives the key from revealed bits at positions where bases matched.
    /// According to QKE, if bases match, the measured bits should correlate (deterministically for Standard,
    /// probabilistically with high chance for Hadamard depending on exact QKE variant and simulation).
    /// In this simulation, if bases match, we take the bit from tokenId1's revealedBits.
    /// The finalize step checks if tokenId2's revealedBit *at those same positions* matches.
    function _deriveKey(uint256 revealedBits, uint256 basisMatchMask) internal pure returns (uint256) {
        return revealedBits & basisMatchMask; // Keep only the bits where bases matched
    }

    // --- Core NFT Management ---

    /// @notice Mints a new NFT with a sequential token ID.
    /// @param to The address to mint the token to.
    /// @param tokenId The specific ID of the token to mint.
    function mint(address to, uint256 tokenId) public onlyOwner {
        require(!_exists(tokenId), "QKENFT: token already minted");
        _safeMint(to, tokenId);
        // Initialize default state (not prepared)
        _isPrepared[tokenId] = false;
        _basisSet[tokenId] = false;
        _isRevealed[tokenId] = false;
        _pairedWith[tokenId] = 0;
        _inExchange[tokenId] = false;

        emit TokenMinted(to, tokenId);
    }

    // Override ERC721 transfer functions to check for pairing
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_pairedWith[tokenId] == 0, "QKENFT: Cannot transfer paired token");
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
         require(_pairedWith[tokenId] == 0, "QKENFT: Cannot transfer paired token");
        super.safeTransferFrom(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         require(_pairedWith[tokenId] == 0, "QKENFT: Cannot transfer paired token");
        super.safeTransferFrom(from, to, tokenId, data);
    }


    // --- Quantum Preparation Phase ---

    /// @notice Prepares a token for the quantum key exchange process.
    /// Initializes its simulated internal quantum state.
    /// @param tokenId The ID of the token to prepare.
    function prepareForQuantumExchange(uint256 tokenId) public onlyOwnerOfToken(tokenId) notPaired(tokenId) {
        require(!_isPrepared[tokenId], "QKENFT: Token is already prepared");
        require(!_inExchange[tokenId], "QKENFT: Token is in an active exchange attempt");

        // Simulate generating initial quantum state (|0> or |1> for each bit)
        _initialBits[tokenId] = _generateRandomBits(tokenId);
        _isPrepared[tokenId] = true;
        _basisSet[tokenId] = false;
        _isRevealed[tokenId] = false;
        _derivedKey[tokenId] = 0; // Reset derived key

        emit TokenPrepared(tokenId);
    }

    /// @notice Sets the simulated measurement basis for a prepared token.
    /// Represents Alice/Bob choosing their basis (Standard/Hadamard) for each qubit.
    /// @param tokenId The ID of the token.
    /// @param basisData A bitmask where the i-th bit is 0 for Standard, 1 for Hadamard.
    function setMeasurementBasis(uint256 tokenId, uint256 basisData) public onlyOwnerOfToken(tokenId) isPrepared(tokenId) {
         require(!_basisSet[tokenId], "QKENFT: Measurement basis already set");
         require(!_isRevealed[tokenId], "QKENFT: Cannot set basis after revealing");
         require(!_inExchange[tokenId], "QKENFT: Token is in an active exchange attempt");
         // Optional: Add check that basisData only uses bits up to keyLength

        _measurementBases[tokenId] = basisData;
        _basisSet[tokenId] = true;

        emit MeasurementBasisSet(tokenId, basisData);
    }

    /// @notice Simulates the quantum measurement based on the chosen basis.
    /// Represents observing the qubit, collapsing its state and yielding a classical bit.
    /// @param tokenId The ID of the token.
    function revealQuantumState(uint256 tokenId) public onlyOwnerOfToken(tokenId) isBasisSet(tokenId) {
         require(!_isRevealed[tokenId], "QKENFT: Quantum state already revealed");
         require(!_inExchange[tokenId], "QKENFT: Token is in an active exchange attempt");

        // Simulate measurement based on initial state and chosen basis
        _revealedBits[tokenId] = _simulateMeasurement(_initialBits[tokenId], _measurementBases[tokenId], tokenId);
        _isRevealed[tokenId] = true;

        emit QuantumStateRevealed(tokenId, _revealedBits[tokenId]);
    }

    // --- Quantum Key Exchange Phase ---

    /// @notice Initiates the key exchange process between two revealed tokens.
    /// Represents Alice and Bob agreeing to compare measurement results.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function initiateKeyExchange(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "QKENFT: Cannot exchange with self");
        require(_exists(tokenId1), "QKENFT: Token 1 does not exist");
        require(_exists(tokenId2), "QKENFT: Token 2 does not exist");
        require(ownerOf(tokenId1) == msg.sender || ownerOf(tokenId2) == msg.sender, "QKENFT: Must own one of the tokens to initiate");

        require(!_inExchange[tokenId1] && !_inExchange[tokenId2], "QKENFT: One or both tokens already in an exchange attempt");
        require(!isPaired(tokenId1) && !isPaired(tokenId2), "QKENFT: One or both tokens are already paired");

        isRevealed(tokenId1); // Check if revealed (modifier applies to msg.sender's token if only one is owned)
        isRevealed(tokenId2); // Check if revealed

        _inExchange[tokenId1] = true;
        _inExchange[tokenId2] = true;
        _exchangePartner[tokenId1] = tokenId2;
        _exchangePartner[tokenId2] = tokenId1;

        // Reset previous exchange data for these tokens
        _basisMatchMask[tokenId1] = 0;
        _basisMatchMask[tokenId2] = 0;
        _derivedKey[tokenId1] = 0;
        _derivedKey[tokenId2] = 0;


        emit KeyExchangeInitiated(tokenId1, tokenId2);
    }

    /// @notice Compares the measurement bases of two tokens to find matching positions.
    /// Represents Alice and Bob publicly revealing their measurement bases.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function performBasisComparison(uint256 tokenId1, uint256 tokenId2) public {
        require(_inExchange[tokenId1] && _exchangePartner[tokenId1] == tokenId2, "QKENFT: Not in an active exchange together");
        require(ownerOf(tokenId1) == msg.sender || ownerOf(tokenId2) == msg.sender, "QKENFT: Must own one of the tokens");

        uint256 basis1 = _measurementBases[tokenId1];
        uint256 basis2 = _measurementBases[tokenId2];

        // Find bit positions where bases match (Standard vs Standard, Hadamard vs Hadamard)
        uint256 matchMask = 0;
        for (uint256 i = 0; i < keyLength; i++) {
            if (_getBit(basis1, i) == _getBit(basis2, i)) {
                matchMask = _setBit(matchMask, i, 1);
            }
        }

        _basisMatchMask[tokenId1] = matchMask;
        _basisMatchMask[tokenId2] = matchMask; // Should be the same mask

        emit BasesCompared(tokenId1, tokenId2, matchMask);
    }

    /// @notice Derives a potential shared key based on revealed bits at matching basis positions.
    /// Represents using the classical bits from matching-basis measurements.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function deriveSharedKey(uint256 tokenId1, uint256 tokenId2) public {
        require(_inExchange[tokenId1] && _exchangePartner[tokenId1] == tokenId2, "QKENFT: Not in an active exchange together");
        require(ownerOf(tokenId1) == msg.sender || ownerOf(tokenId2) == msg.sender, "QKENFT: Must own one of the tokens");
        require(_basisMatchMask[tokenId1] != 0 || keyLength == 0, "QKENFT: Basis comparison not performed or no matching bases"); // Must have run comparison

        // Derive key from revealed bits using the match mask
        _derivedKey[tokenId1] = _deriveKey(_revealedBits[tokenId1], _basisMatchMask[tokenId1]);
        _derivedKey[tokenId2] = _deriveKey(_revealedBits[tokenId2], _basisMatchMask[tokenId2]);

        emit SharedKeyDerived(tokenId1, _derivedKey[tokenId1]);
        emit SharedKeyDerived(tokenId2, _derivedKey[tokenId2]); // Emitting for both

    }

    /// @notice Finalizes the key exchange by checking if the derived keys match.
    /// If keys match, tokens are paired. If not, pairing fails.
    /// @param tokenId1 The ID of the first token.
    /// @param tokenId2 The ID of the second token.
    function finalizeKeyExchange(uint256 tokenId1, uint256 tokenId2) public {
        require(_inExchange[tokenId1] && _exchangePartner[tokenId1] == tokenId2, "QKENFT: Not in an active exchange together");
        require(ownerOf(tokenId1) == msg.sender || ownerOf(tokenId2) == msg.sender, "QKENFT: Must own one of the tokens");
        require(_derivedKey[tokenId1] != 0 || keyLength == 0, "QKENFT: Keys not derived"); // Must have derived keys

        uint256 key1 = _derivedKey[tokenId1];
        uint256 key2 = _derivedKey[tokenId2];

        // Reset exchange state regardless of outcome
        _inExchange[tokenId1] = false;
        _inExchange[tokenId2] = false;
        _exchangePartner[tokenId1] = 0;
        _exchangePartner[tokenId2] = 0;
        // Keep _basisMatchMask, _derivedKey for potential inspection after failure

        if (key1 == key2 && _basisMatchMask[tokenId1] != 0) { // Keys match and there was at least one matching bit
            _pairedWith[tokenId1] = tokenId2;
            _pairedWith[tokenId2] = tokenId1;

            // Clear QKE state for paired tokens (they are now linked)
            _isPrepared[tokenId1] = false;
            _basisSet[tokenId1] = false;
            _isRevealed[tokenId1] = false;
            _initialBits[tokenId1] = 0;
            _measurementBases[tokenId1] = 0;
            _revealedBits[tokenId1] = 0;
             _basisMatchMask[tokenId1] = 0;
            _derivedKey[tokenId1] = key1; // Store the successful key (optional, could be cleared)

            _isPrepared[tokenId2] = false;
            _basisSet[tokenId2] = false;
            _isRevealed[tokenId2] = false;
            _initialBits[tokenId2] = 0;
            _measurementBases[tokenId2] = 0;
            _revealedBits[tokenId2] = 0;
             _basisMatchMask[tokenId2] = 0;
            _derivedKey[tokenId2] = key2; // Store the successful key


            emit PairingSuccess(tokenId1, tokenId2, key1);

        } else {
             // Clear QKE state for failed tokens, allow re-preparation
            _isPrepared[tokenId1] = false; // Need to re-prepare
            _basisSet[tokenId1] = false;
            _isRevealed[tokenId1] = false;
            _initialBits[tokenId1] = 0;
            _measurementBases[tokenId1] = 0;
            _revealedBits[tokenId1] = 0;
            _basisMatchMask[tokenId1] = 0;
            _derivedKey[tokenId1] = 0; // Clear failed key

            _isPrepared[tokenId2] = false;
            _basisSet[tokenId2] = false;
            _isRevealed[tokenId2] = false;
            _initialBits[tokenId2] = 0;
            _measurementBases[tokenId2] = 0;
            _revealedBits[tokenId2] = 0;
            _basisMatchMask[tokenId2] = 0;
            _derivedKey[tokenId2] = 0; // Clear failed key

            emit PairingFailed(tokenId1, tokenId2);
        }
    }

    // --- Paired Functionality ---

    /// @notice Checks if a token is currently paired with another.
    /// @param tokenId The ID of the token.
    /// @return bool True if paired, false otherwise.
    function isPaired(uint256 tokenId) public view returns (bool) {
        return _pairedWith[tokenId] != 0;
    }

    /// @notice Gets the token ID that a token is paired with.
    /// @param tokenId The ID of the token.
    /// @return uint256 The paired token ID, or 0 if not paired.
    function getPairedToken(uint256 tokenId) public view returns (uint256) {
        return _pairedWith[tokenId];
    }

    /// @notice Allows the owner of a paired token to break the pairing.
    /// Unlinks the two tokens.
    /// @param tokenId The ID of the token.
    function breakPairing(uint256 tokenId) public onlyOwnerOfToken(tokenId) isPaired(tokenId) {
        uint256 pairedTokenId = _pairedWith[tokenId];
        require(_exists(pairedTokenId), "QKENFT: Paired token does not exist?"); // Should not happen if logic is correct

        _pairedWith[tokenId] = 0;
        _pairedWith[pairedTokenId] = 0;

        // Clear any stored messages between them
        delete _pairedMessages[tokenId][pairedTokenId];
        delete _pairedMessages[pairedTokenId][tokenId];

        // The derived key is kept for historical purposes but is no longer active for communication
        // _derivedKey[tokenId] and _derivedKey[pairedTokenId] are not cleared here.

        emit PairingBroken(tokenId, pairedTokenId);
    }

    /// @notice Sends a message that can only be retrieved by the paired token.
    /// Simulates secure communication established by the shared key (although the key isn't used for actual encryption here).
    /// @param tokenId The ID of the token sending the message.
    /// @param message The message string to send.
    function sendPairedMessage(uint256 tokenId, string memory message) public onlyOwnerOfToken(tokenId) isPaired(tokenId) {
        uint256 recipientTokenId = _pairedWith[tokenId];
        require(_exists(recipientTokenId), "QKENFT: Paired token does not exist?");

        _pairedMessages[tokenId][recipientTokenId] = message;

        emit PairedMessageSent(tokenId, recipientTokenId);
    }

    /// @notice Retrieves the message sent by the paired token.
    /// @param tokenId The ID of the token retrieving the message.
    /// @return string The message received from the paired token.
    function getPairedMessage(uint256 tokenId) public view onlyOwnerOfToken(tokenId) isPaired(tokenId) returns (string memory) {
        uint256 senderTokenId = _pairedWith[tokenId];
        require(_exists(senderTokenId), "QKENFT: Paired token does not exist?");

        return _pairedMessages[senderTokenId][tokenId];
    }


    // --- Query/Inspect Functions ---

    /// @notice Gets the current preparation, revealed, and paired status flags for a token.
    /// @param tokenId The ID of the token.
    /// @return bool isPreparedStatus
    /// @return bool isBasisSetStatus
    /// @return bool isRevealedStatus
    /// @return bool isPairedStatus
    function getTokenStatus(uint256 tokenId) public view returns (bool isPreparedStatus, bool isBasisSetStatus, bool isRevealedStatus, bool isPairedStatus) {
         require(_exists(tokenId), "QKENFT: Token does not exist");
         return (_isPrepared[tokenId], _basisSet[tokenId], _isRevealed[tokenId], _pairedWith[tokenId] != 0);
    }

    /// @notice Gets the current key length used for QKE simulation.
    /// @return uint256 The configured key length.
    function getKeyLength() public view returns (uint256) {
        return keyLength;
    }

     /// @notice Internal view function to get full quantum state details for a token.
     /// Can be exposed via a public admin/debug function if needed, but kept internal for privacy by default.
     /// @param tokenId The ID of the token.
     /// @return uint256 initialBits
     /// @return uint256 measurementBases
     /// @return uint256 revealedBits
     /// @return uint256 basisMatchMask (if applicable from last exchange)
     /// @return uint256 derivedKey (from last exchange attempt)
    function _getTokenQuantumState(uint256 tokenId) internal view returns (uint256, uint256, uint256, uint256, uint256) {
         require(_exists(tokenId), "QKENFT: Token does not exist");
         return (
             _initialBits[tokenId],
             _measurementBases[tokenId],
             _revealedBits[tokenId],
             _basisMatchMask[tokenId],
             _derivedKey[tokenId]
         );
    }


    // --- Admin Functions ---

    /// @notice Allows the owner to set the length of the simulated quantum key.
    /// Affects *future* tokens prepared for exchange. Existing prepared tokens keep their length.
    /// Max length is limited by uint256 (256 bits).
    /// @param length The new desired key length.
    function setKeyLength(uint256 length) public onlyOwner {
        require(length > 0 && length <= 256, "QKENFT: Key length must be between 1 and 256");
        keyLength = length;
        emit KeyLengthSet(length);
    }

     /// @notice Allows the owner to withdraw any ERC20 tokens accidentally sent to the contract.
     /// @param tokenAddress The address of the ERC20 token.
     /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20 erc20Token = IERC20(tokenAddress);
        require(erc20Token.transfer(owner(), amount), "QKENFT: ERC20 transfer failed");
    }

    // Inherits renounceOwnership and transferOwnership from Ownable

}
```