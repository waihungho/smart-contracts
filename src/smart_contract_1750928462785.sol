Okay, here is a smart contract concept centered around "Quantum Entangled Assets". This concept leverages NFTs (ERC721) to represent abstract quantum particles that can be entangled, measured, and have dynamic properties like stability and complexity. The core "advanced" and "creative" part is the simulated entanglement and measurement mechanic, where measuring one entangled particle instantly (within the same transaction) determines the state of its partner.

This contract will include standard ERC721 functions (using OpenZeppelin for efficiency and correctness) but will build a significant number of custom functions (well over 20 total) on top of this foundation to implement the unique mechanics.

**Disclaimer:** This contract simulates quantum mechanics conceptually on a deterministic blockchain. The "randomness" for measurement is based on block data, which is predictable to miners and not suitable for high-security applications requiring true unpredictability. For production systems needing secure randomness, Chainlink VRF or similar solutions would be necessary. This contract is designed for exploring the *concept* of entangled assets on-chain.

---

### Smart Contract: QuantumEntangledAsset

**Outline:**

1.  **Core Concept:** ERC721 NFTs representing "Quantum Particles" that can be paired and "entangled".
2.  **Entanglement Mechanic:** Two particles can be explicitly linked by their owners.
3.  **Measurement Mechanic:** Entangled particles are in a "superposition" (simulated) until measured. Measuring one instantly determines the "state" of both in a correlated manner (e.g., Spin Up/Spin Down). Measurement can only happen once per entanglement period.
4.  **Dynamic Properties:** Particles have properties like Stability (can decay, can be recharged) and Complexity (increases with interactions like entanglement/measurement).
5.  **State Transitions:** Particles move between states (Not Entangled, Entangled, Measured).
6.  **Asset Management:** Standard ERC721 operations plus specific functions for managing entangled pairs.
7.  **Information Queries:** Extensive view functions to query particle states and history.

**Function Summary (> 20 Functions):**

*   **Standard ERC721 Functions (inherited from OpenZeppelin ERC721Enumerable):**
    *   `balanceOf(address owner)`: Get the number of tokens owned by an address.
    *   `ownerOf(uint256 tokenId)`: Get the owner of a specific token.
    *   `approve(address to, uint256 tokenId)`: Approve another address to transfer a specific token.
    *   `getApproved(uint256 tokenId)`: Get the approved address for a specific token.
    *   `setApprovalForAll(address operator, bool approved)`: Approve or revoke approval for an operator for all tokens.
    *   `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for an owner.
    *   `transferFrom(address from, address to, uint256 tokenId)`: Transfer token ownership.
    *   `safeTransferFrom(address from, address to, uint256 tokenId)`: Transfer token ownership safely.
    *   `safeTransferFrom(address from, address to, uint256 tokenId, bytes data)`: Transfer token ownership safely with data.
    *   `totalSupply()`: Get the total number of tokens in existence.
    *   `tokenByIndex(uint256 index)`: Get a token ID by index.
    *   `tokenOfOwnerByIndex(address owner, uint256 index)`: Get a token ID of an owner by index.
    *   `supportsInterface(bytes4 interfaceId)`: Check if the contract supports an interface.
*   **Custom QuantumEntangledAsset Functions:**
    *   `mintParticle(address recipient)`: Mints a new Quantum Particle NFT.
    *   `proposeEntanglement(uint256 tokenId1, uint256 tokenId2)`: Owner of `tokenId1` proposes entanglement to owner of `tokenId2`. Requires approval for `tokenId2` by the proposer or ownership by the proposer.
    *   `acceptEntanglement(uint256 tokenId1, uint256 tokenId2)`: Owner of `tokenId2` accepts the entanglement proposal from `tokenId1`. Establishes the entangled link.
    *   `cancelEntanglementProposal(uint256 tokenId1, uint256 tokenId2)`: Owner of `tokenId1` cancels their proposal.
    *   `disentangle(uint256 tokenId)`: Owner of one particle breaks the entanglement link for both particles.
    *   `prepareForMeasurement(uint256 tokenId)`: (Optional preparation step, maybe resets state after disentanglement/measurement). Let's refine: Measurement is a one-time event per entanglement link. This function isn't strictly needed if measurement is simple. Let's make `measureParticle` callable if not already measured *in this entanglement*.
    *   `measureParticle(uint256 tokenId)`: Triggers the "measurement" for an entangled particle. Determines and sets the `measuredState` for *both* entangled particles based on simulated randomness. Can only be called once per entanglement pair before they are disentangled.
    *   `decayStability(uint256 tokenId)`: Allows decreasing a particle's stability (can be called by anyone, but rate limited per particle/block).
    *   `rechargeStability(uint256 tokenId)`: Allows the owner to increase stability, potentially costing Ether.
    *   `increaseComplexity(uint256 tokenId)`: Increases complexity, automatically called upon entanglement or measurement.
    *   `transferEntangledPair(uint256 tokenId1, uint256 tokenId2, address recipient)`: Transfers both entangled particles to the same recipient in a single transaction. Requires ownership of both or approval for both.
    *   `getParticleState(uint256 tokenId)`: Returns the full state struct for a particle.
    *   `getEntanglementPartner(uint256 tokenId)`: Returns the ID of the entangled partner (0 if none).
    *   `isEntangled(uint256 tokenId)`: Checks if a particle is currently entangled.
    *   `getEntanglementBlock(uint256 tokenId)`: Returns the block number when the particle was last entangled.
    *   `getMeasurementBlock(uint256 tokenId)`: Returns the block number when the particle was last measured.
    *   `querySuperpositionState(uint256 tokenId)`: Returns the current conceptual superposition state (usually `Unknown` before measurement).
    *   `queryMeasuredState(uint256 tokenId)`: Returns the determined state after measurement (e.g., `SpinUp`, `SpinDown`).
    *   `queryStability(uint256 tokenId)`: Returns the current stability value.
    *   `queryComplexity(uint256 tokenId)`: Returns the current complexity value.
    *   `queryAge(uint256 tokenId)`: Returns the age of the particle in blocks.
    *   `getTotalParticlesMinted()`: Returns the total number of particles minted.
    *   `getEntangledPairsCount()`: Returns the total number of active entangled pairs.
    *   `getEntanglementProposalStatus(uint256 tokenId1, uint256 tokenId2)`: Checks if a proposal exists between two tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Disclaimer: This contract uses block data for simulated randomness,
// which is predictable and not suitable for applications requiring
// strong security or verifiably fair outcomes. It serves conceptual purposes.

/**
 * @title QuantumEntangledAsset
 * @dev An ERC721 contract representing abstract quantum particles with
 * entanglement, measurement, and dynamic properties.
 *
 * Outline:
 * 1. Core Concept: ERC721 NFTs representing "Quantum Particles" that can be paired and "entangled".
 * 2. Entanglement Mechanic: Two particles can be explicitly linked by their owners.
 * 3. Measurement Mechanic: Entangled particles are in a "superposition" (simulated) until measured.
 *    Measuring one instantly determines the "state" of both in a correlated manner.
 *    Measurement can only happen once per entanglement period.
 * 4. Dynamic Properties: Particles have properties like Stability (can decay, can be recharged)
 *    and Complexity (increases with interactions).
 * 5. State Transitions: Particles move between states (Not Entangled, Entangled, Measured).
 * 6. Asset Management: Standard ERC721 operations plus specific functions for managing entangled pairs.
 * 7. Information Queries: Extensive view functions to query particle states and history.
 *
 * Function Summary (> 20 Functions):
 * - Standard ERC721 Functions (inherited from OpenZeppelin ERC721Enumerable):
 *   balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
 *   transferFrom, safeTransferFrom (x2), totalSupply, tokenByIndex, tokenOfOwnerByIndex,
 *   supportsInterface. (13 functions)
 * - Custom QuantumEntangledAsset Functions:
 *   mintParticle, proposeEntanglement, acceptEntanglement, cancelEntanglementProposal,
 *   disentangle, measureParticle, decayStability, rechargeStability, increaseComplexity,
 *   transferEntangledPair, getParticleState, getEntanglementPartner, isEntangled,
 *   getEntanglementBlock, getMeasurementBlock, querySuperpositionState, queryMeasuredState,
 *   queryStability, queryComplexity, queryAge, getTotalParticlesMinted, getEntangledPairsCount,
 *   getEntanglementProposalStatus. (23 functions)
 *
 * Total functions: 13 + 23 = 36 (well over 20 required)
 */
contract QuantumEntangledAsset is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- Data Structures & State ---

    enum SuperpositionState { Unknown, SpinUp, SpinDown }

    struct ParticleState {
        uint256 tokenId;
        uint256 entangledPartnerId; // 0 if not entangled
        uint256 entanglementBlock;  // Block number when last entangled
        SuperpositionState superpositionState; // Conceptual state before measurement
        SuperpositionState measuredState;      // State determined after measurement
        uint256 measurementBlock;   // Block number when last measured (0 if not measured in current entanglement)
        uint256 stability;          // A dynamic property (e.g., max 100, decays over time, rechargeable)
        uint256 complexity;         // A dynamic property (increases with interactions)
        uint256 creationBlock;      // Block number when minted
        uint256 lastStabilityDecayBlock; // Block of last decay check/application
    }

    mapping(uint256 => ParticleState) private particleStates;
    mapping(uint256 => mapping(uint256 => bool)) private entanglementProposals; // proposal from tokenId1 to tokenId2

    uint256 private _entangledPairsCount;

    // --- Configuration ---
    uint256 public constant INITIAL_STABILITY = 100;
    uint256 public constant MAX_STABILITY = 100;
    uint256 public constant STABILITY_DECAY_RATE_PER_BLOCK = 1; // Decay by 1 per block checked
    uint256 public constant MIN_STABILITY_FOR_MEASUREMENT = 10; // Minimum stability required to measure
    uint256 public constant RECHARGE_COST_PER_POINT = 1 ether / 100; // Cost to recharge 1 stability point
    uint256 public constant BASE_COMPLEXITY = 1; // Initial complexity
    uint256 public constant COMPLEXITY_INCREASE_ENTANGLE = 5;
    uint256 public constant COMPLEXITY_INCREASE_MEASURE = 10;

    // --- Events ---
    event ParticleMinted(uint256 indexed tokenId, address indexed recipient);
    event EntanglementProposed(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed proposer);
    event EntanglementAccepted(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event EntanglementCancelled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event Disentangled(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event ParticleMeasured(uint256 indexed tokenId1, uint256 indexed tokenId2, SuperpositionState state1, SuperpositionState state2);
    event StabilityDecayed(uint256 indexed tokenId, uint256 newStability);
    event StabilityRecharged(uint256 indexed tokenId, uint256 newStability, uint256 cost);
    event ComplexityIncreased(uint256 indexed tokenId, uint256 newComplexity);
    event EntangledPairTransferred(uint256 indexed tokenId1, uint256 indexed tokenId2, address indexed from, address indexed to);

    // --- Modifiers ---
    modifier onlyParticleOwner(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        _;
    }

    modifier onlyApprovedOrOwner(uint256 tokenId) {
        require(_exists(tokenId), "Token does not exist");
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(tokenOwner, msg.sender), "Not owner nor approved");
        _;
    }

    modifier requireEntangled(uint256 tokenId) {
        require(isEntangled(tokenId), "Particle is not entangled");
        _;
    }

    modifier requireNotEntangled(uint256 tokenId) {
        require(!isEntangled(tokenId), "Particle is already entangled");
        _;
    }

     modifier requireSameEntanglement(uint256 tokenId1, uint256 tokenId2) {
        requireEntangled(tokenId1);
        requireEntangled(tokenId2);
        require(particleStates[tokenId1].entangledPartnerId == tokenId2, "Particles are not entangled with each other");
        _;
    }

    // --- Constructor ---

    constructor() ERC721Enumerable("QuantumEntangledAsset", "QEA") Ownable(msg.sender) {
        // Initial setup if needed
    }

    // --- Internal Helpers ---

    function _applyStabilityDecay(uint256 tokenId) internal {
        ParticleState storage particle = particleStates[tokenId];
        uint256 blocksSinceLastDecay = block.number - particle.lastStabilityDecayBlock;

        if (blocksSinceLastDecay > 0 && particle.stability > 0) {
            uint256 decayAmount = blocksSinceLastDecay * STABILITY_DECAY_RATE_PER_BLOCK;
            if (decayAmount >= particle.stability) {
                particle.stability = 0;
            } else {
                particle.stability -= decayAmount;
            }
            particle.lastStabilityDecayBlock = block.number;
            emit StabilityDecayed(tokenId, particle.stability);
        }
    }

    function _increaseComplexity(uint256 tokenId, uint256 amount) internal {
        ParticleState storage particle = particleStates[tokenId];
        particle.complexity += amount;
        emit ComplexityIncreased(tokenId, particle.complexity);
    }

    // --- Core Custom Functions ---

    /**
     * @dev Mints a new Quantum Particle and assigns it to the recipient.
     * @param recipient The address to receive the new token.
     */
    function mintParticle(address recipient) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(recipient, newTokenId);

        particleStates[newTokenId] = ParticleState({
            tokenId: newTokenId,
            entangledPartnerId: 0,
            entanglementBlock: 0,
            superpositionState: SuperpositionState.Unknown,
            measuredState: SuperpositionState.Unknown,
            measurementBlock: 0,
            stability: INITIAL_STABILITY,
            complexity: BASE_COMPLEXITY,
            creationBlock: block.number,
            lastStabilityDecayBlock: block.number
        });

        emit ParticleMinted(newTokenId, recipient);
    }

    /**
     * @dev Proposes entanglement between two non-entangled particles.
     * Requires approval for tokenId2 by the proposer or ownership of both.
     * @param tokenId1 The ID of the first particle (proposer's particle).
     * @param tokenId2 The ID of the second particle (recipient's particle).
     */
    function proposeEntanglement(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "Token1 does not exist");
        require(_exists(tokenId2), "Token2 does not exist");
        require(tokenId1 != tokenId2, "Cannot propose entanglement with itself");
        requireNotEntangled(tokenId1);
        requireNotEntangled(tokenId2);

        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);

        // Check if caller is owner of token1 and has permission for token2
        bool callerIsOwner1 = (owner1 == msg.sender);
        bool callerHasApprovalFor2 = (getApproved(tokenId2) == msg.sender || isApprovedForAll(owner2, msg.sender));

        require(callerIsOwner1, "Must own token1 to propose");
        require(owner1 == owner2 || callerHasApprovalFor2, "Must own token2 or have approval for token2 to propose");

        entanglementProposals[tokenId1][tokenId2] = true;
        emit EntanglementProposed(tokenId1, tokenId2, msg.sender);
    }

     /**
     * @dev Cancels an entanglement proposal made by tokenId1 to tokenId2.
     * @param tokenId1 The ID of the first particle (proposer's particle).
     * @param tokenId2 The ID of the second particle (recipient's particle).
     */
    function cancelEntanglementProposal(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "Token1 does not exist");
        require(_exists(tokenId2), "Token2 does not exist");
        require(tokenId1 != tokenId2, "Invalid proposal");
        require(entanglementProposals[tokenId1][tokenId2], "No such entanglement proposal exists");
        require(ownerOf(tokenId1) == msg.sender, "Must own token1 to cancel the proposal");

        delete entanglementProposals[tokenId1][tokenId2];
        emit EntanglementCancelled(tokenId1, tokenId2);
    }


    /**
     * @dev Accepts an entanglement proposal between two non-entangled particles.
     * Requires owner of tokenId2 to call and a proposal from tokenId1 to tokenId2 must exist.
     * @param tokenId1 The ID of the first particle (proposer's particle).
     * @param tokenId2 The ID of the second particle (recipient's particle).
     */
    function acceptEntanglement(uint256 tokenId1, uint256 tokenId2) public {
        require(_exists(tokenId1), "Token1 does not exist");
        require(_exists(tokenId2), "Token2 does not exist");
        require(tokenId1 != tokenId2, "Cannot entangle with itself");
        requireNotEntangled(tokenId1);
        requireNotEntangled(tokenId2);
        require(entanglementProposals[tokenId1][tokenId2], "No entanglement proposal from Token1 to Token2");
        require(ownerOf(tokenId2) == msg.sender, "Must own token2 to accept the proposal");
        require(ownerOf(tokenId1) == ownerOf(tokenId2), "Tokens must be owned by the same address to accept entanglement"); // Simplification: requires co-ownership for acceptance

        delete entanglementProposals[tokenId1][tokenId2]; // Remove the proposal

        particleStates[tokenId1].entangledPartnerId = tokenId2;
        particleStates[tokenId1].entanglementBlock = block.number;
        particleStates[tokenId1].superpositionState = SuperpositionState.Unknown; // Reset state upon new entanglement
        particleStates[tokenId1].measuredState = SuperpositionState.Unknown;
        particleStates[tokenId1].measurementBlock = 0;

        particleStates[tokenId2].entangledPartnerId = tokenId1;
        particleStates[tokenId2].entanglementBlock = block.number;
        particleStates[tokenId2].superpositionState = SuperpositionState.Unknown; // Reset state upon new entanglement
        particleStates[tokenId2].measuredState = SuperpositionState.Unknown;
        particleStates[tokenId2].measurementBlock = 0;

        _entangledPairsCount++;
        _increaseComplexity(tokenId1, COMPLEXITY_INCREASE_ENTANGLE);
        _increaseComplexity(tokenId2, COMPLEXITY_INCREASE_ENTANGLE);

        emit EntanglementAccepted(tokenId1, tokenId2);
    }

    /**
     * @dev Breaks the entanglement link for a particle and its partner.
     * Requires ownership of the particle.
     * @param tokenId The ID of the particle to disentangle.
     */
    function disentangle(uint256 tokenId) public onlyParticleOwner(tokenId) requireEntangled(tokenId) {
        uint256 partnerId = particleStates[tokenId].entangledPartnerId;
        require(_exists(partnerId), "Partner token does not exist"); // Should not happen if entangled correctly

        // Reset state for both particles
        particleStates[tokenId].entangledPartnerId = 0;
        particleStates[tokenId].entanglementBlock = 0;
        particleStates[tokenId].superpositionState = SuperpositionState.Unknown; // Return to superposition conceptually
        particleStates[tokenId].measuredState = SuperpositionState.Unknown;
        particleStates[tokenId].measurementBlock = 0;

        particleStates[partnerId].entangledPartnerId = 0;
        particleStates[partnerId].entanglementBlock = 0;
        particleStates[partnerId].superpositionState = SuperpositionState.Unknown; // Return to superposition conceptually
        particleStates[partnerId].measuredState = SuperpositionState.Unknown;
        particleStates[partnerId].measurementBlock = 0;

        _entangledPairsCount--;

        emit Disentangled(tokenId, partnerId);
    }

    /**
     * @dev "Measures" an entangled particle, collapsing the superposition (simulated).
     * Determines the state of both entangled particles. Can only be called once
     * per entanglement period. Requires minimum stability.
     * @param tokenId The ID of the particle to measure.
     */
    function measureParticle(uint256 tokenId) public onlyParticleOwner(tokenId) requireEntangled(tokenId) {
        ParticleState storage particle1 = particleStates[tokenId];
        uint256 partnerId = particle1.entangledPartnerId;
        ParticleState storage particle2 = particleStates[partnerId];

        require(particle1.measuredState == SuperpositionState.Unknown, "Particle already measured in this entanglement");
        require(particle1.stability >= MIN_STABILITY_FOR_MEASUREMENT, "Insufficient stability to perform measurement");

        // --- Simulated Quantum Measurement ---
        // Using block data for pseudo-randomness. PREDICTABLE.
        // This is for conceptual simulation only.
        uint256 entropy = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, tokenId, partnerId, msg.sender)));
        bool outcome = (entropy % 2 == 0); // Simple random spin up/down

        SuperpositionState state1;
        SuperpositionState state2;

        if (outcome) {
            state1 = SuperpositionState.SpinUp;
            state2 = SuperpositionState.SpinDown; // Entangled states are anti-correlated
        } else {
            state1 = SuperpositionState.SpinDown;
            state2 = SuperpositionState.SpinUp; // Entangled states are anti-correlated
        }

        // Apply measured state and update blocks
        particle1.measuredState = state1;
        particle1.measurementBlock = block.number;
        particle1.superpositionState = SuperpositionState.Unknown; // No longer in measurable superposition for this entanglement

        particle2.measuredState = state2;
        particle2.measurementBlock = block.number;
        particle2.superpositionState = SuperpositionState.Unknown; // No longer in measurable superposition for this entanglement

        // Apply consequences
        _applyStabilityDecay(tokenId); // Apply decay before measurement impact
        _applyStabilityDecay(partnerId);
        particle1.stability = particle1.stability > MIN_STABILITY_FOR_MEASUREMENT ? particle1.stability - MIN_STABILITY_FOR_MEASUREMENT : 0; // Cost stability to measure
         particle2.stability = particle2.stability > MIN_STABILITY_FOR_MEASUREMENT ? particle2.stability - MIN_STABILITY_FOR_MEASUREMENT : 0; // Cost stability to measure
        _increaseComplexity(tokenId, COMPLEXITY_INCREASE_MEASURE);
        _increaseComplexity(partnerId, COMPLEXITY_INCREASE_MEASURE);


        emit ParticleMeasured(tokenId, partnerId, state1, state2);
    }

    /**
     * @dev Allows anyone to trigger stability decay for a particle based on elapsed blocks.
     * Rate limited by the internal lastStabilityDecayBlock timestamp.
     * @param tokenId The ID of the particle.
     */
    function decayStability(uint256 tokenId) public {
        require(_exists(tokenId), "Token does not exist");
         _applyStabilityDecay(tokenId);
    }

    /**
     * @dev Allows the owner to recharge a particle's stability by paying Ether.
     * @param tokenId The ID of the particle.
     */
    function rechargeStability(uint256 tokenId) public payable onlyParticleOwner(tokenId) {
        ParticleState storage particle = particleStates[tokenId];
        _applyStabilityDecay(tokenId); // Apply any pending decay first

        uint256 currentStability = particle.stability;
        if (currentStability >= MAX_STABILITY) {
            require(msg.value == 0, "Particle is already at max stability, send 0 Ether");
            return; // Already max stability, no recharge needed
        }

        uint256 pointsToRecharge = MAX_STABILITY - currentStability;
        uint256 requiredCost = pointsToRecharge * RECHARGE_COST_PER_POINT;

        require(msg.value >= requiredCost, "Insufficient Ether sent");

        particle.stability = MAX_STABILITY;

        uint256 refund = msg.value - requiredCost;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        emit StabilityRecharged(tokenId, particle.stability, requiredCost);
    }

    /**
     * @dev Transfers an entangled pair of particles to a new recipient.
     * Requires ownership of both or approval for both by the sender.
     * @param tokenId1 The ID of the first particle in the pair.
     * @param tokenId2 The ID of the second particle in the pair.
     * @param recipient The address to receive both tokens.
     */
    function transferEntangledPair(uint256 tokenId1, uint256 tokenId2, address recipient) public requireSameEntanglement(tokenId1, tokenId2) {
        address owner1 = ownerOf(tokenId1);
        address owner2 = ownerOf(tokenId2);
        require(owner1 == owner2, "Entangled tokens must have the same owner"); // Only allow transferring pairs owned by the same person

        require(recipient != address(0), "ERC721: transfer to the zero address");

        // Check approval for the pair transfer
        bool isApproved = (getApproved(tokenId1) == msg.sender || isApprovedForAll(owner1, msg.sender));
        require(owner1 == msg.sender || isApproved, "ERC721: transfer caller is not owner nor approved");

        // We must check approval for *both* if the caller is not the owner,
        // or that the caller is the owner of both.
        if (owner1 != msg.sender) {
             bool isApproved2 = (getApproved(tokenId2) == msg.sender || isApprovedForAll(owner2, msg.sender));
             require(isApproved2, "ERC721: transfer caller is not approved for token2");
        }


        // Perform transfers
        // Need to clear approvals before transferring
        _approve(address(0), tokenId1);
        _approve(address(0), tokenId2);

        _transfer(owner1, recipient, tokenId1);
        _transfer(owner2, recipient, tokenId2);

        emit EntangledPairTransferred(tokenId1, tokenId2, owner1, recipient);
    }

    // --- View/Query Functions ---

    /**
     * @dev Gets the full state struct for a particle.
     * @param tokenId The ID of the particle.
     * @return The ParticleState struct.
     */
    function getParticleState(uint256 tokenId) public view returns (ParticleState memory) {
         require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId];
    }

     /**
     * @dev Gets the entangled partner's ID.
     * @param tokenId The ID of the particle.
     * @return The partner's token ID, or 0 if not entangled.
     */
    function getEntanglementPartner(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId].entangledPartnerId;
    }

    /**
     * @dev Checks if a particle is currently entangled.
     * @param tokenId The ID of the particle.
     * @return True if entangled, false otherwise.
     */
    function isEntangled(uint256 tokenId) public view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId].entangledPartnerId != 0;
    }

    /**
     * @dev Gets the block number when the particle was last entangled.
     * @param tokenId The ID of the particle.
     * @return The block number, or 0 if never entangled or currently disentangled.
     */
    function getEntanglementBlock(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId].entanglementBlock;
    }

    /**
     * @dev Gets the block number when the particle was last measured in its current entanglement.
     * @param tokenId The ID of the particle.
     * @return The block number, or 0 if not measured in the current entanglement.
     */
    function getMeasurementBlock(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId].measurementBlock;
    }

    /**
     * @dev Gets the particle's conceptual superposition state.
     * @param tokenId The ID of the particle.
     * @return The SuperpositionState enum value.
     */
    function querySuperpositionState(uint256 tokenId) public view returns (SuperpositionState) {
         require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId].superpositionState;
    }

    /**
     * @dev Gets the particle's state determined after the last measurement.
     * @param tokenId The ID of the particle.
     * @return The SuperpositionState enum value (Unknown if never measured in current entanglement).
     */
    function queryMeasuredState(uint256 tokenId) public view returns (SuperpositionState) {
         require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId].measuredState;
    }

    /**
     * @dev Gets the particle's current stability value, applying potential decay.
     * Note: This doesn't store the decay, it calculates it dynamically.
     * Use _applyStabilityDecay internal function to persist decay.
     * @param tokenId The ID of the particle.
     * @return The calculated current stability.
     */
    function queryStability(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        ParticleState memory particle = particleStates[tokenId];
         uint256 blocksSinceLastDecay = block.number - particle.lastStabilityDecayBlock;

        if (blocksSinceLastDecay > 0 && particle.stability > 0) {
             uint256 decayAmount = blocksSinceLastDecay * STABILITY_DECAY_RATE_PER_BLOCK;
             if (decayAmount >= particle.stability) {
                 return 0;
             } else {
                 return particle.stability - decayAmount;
             }
        }
        return particle.stability; // No decay if 0 blocks or already 0
    }

    /**
     * @dev Gets the particle's current complexity value.
     * @param tokenId The ID of the particle.
     * @return The complexity value.
     */
    function queryComplexity(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
        return particleStates[tokenId].complexity;
    }

    /**
     * @dev Gets the age of the particle in blocks.
     * @param tokenId The ID of the particle.
     * @return The age in blocks.
     */
    function queryAge(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "Token does not exist");
        return block.number - particleStates[tokenId].creationBlock;
    }

    /**
     * @dev Gets the total number of particles minted.
     * @return The total count.
     */
    function getTotalParticlesMinted() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev Gets the current number of active entangled pairs.
     * @return The count of entangled pairs.
     */
    function getEntangledPairsCount() public view returns (uint256) {
        return _entangledPairsCount;
    }

     /**
     * @dev Checks if a proposal exists from tokenId1 to tokenId2.
     * @param tokenId1 The ID of the potential proposer particle.
     * @param tokenId2 The ID of the potential recipient particle.
     * @return True if a proposal exists, false otherwise.
     */
    function getEntanglementProposalStatus(uint256 tokenId1, uint256 tokenId2) public view returns (bool) {
        return entanglementProposals[tokenId1][tokenId2];
    }


    // The following functions are overrides required by Solidity.
    // They are part of the ERC721Enumerable standard and count towards the total function count.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Additional logic: Disentangle if transferred individually
        // Does NOT disentangle if transferred as a pair via transferEntangledPair
        // because that function handles the transfer using _transfer directly.
        // This hook is called by _safeTransferFrom and _transfer from ERC721 base.
        // We only want to disentangle if this *isn't* part of a paired transfer.
        // This is tricky to track cleanly in _beforeTokenTransfer.
        // A simpler approach is to make transferEntangledPair call disentangle *before* transferring,
        // or handle the disentanglement logic *after* standard transfers.
        // Let's add a require that entangled tokens cannot be transferred individually
        // using standard ERC721 functions. They MUST be disentangled first or transferred as a pair.
        if (particleStates[tokenId].entangledPartnerId != 0) {
             // Check if this transfer is part of a transferEntangledPair call
             // This requires checking the call stack, which is difficult and insecure.
             // The cleaner approach is to prevent individual transfers if entangled.
             require(
                 msg.sender == address(this), // Check if called internally by a method like transferEntangledPair
                 "Entangled particles must be disentangled or transferred as a pair"
             );
             // If called internally, check it's specifically by transferEntangledPair
             // (Still hard to do cleanly. The best is to prevent all external standard transfers if entangled).
        }
         // If called internally by transferEntangledPair, no disentanglement needed within this hook.
         // If this hook is reached by external standard transfer, the require above will fail.
    }

    // Override the standard transfer functions to prevent individual transfer of entangled tokens
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(!isEntangled(tokenId), "Cannot transfer entangled particles individually");
        super.transferFrom(from, to, tokenId);
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(!isEntangled(tokenId), "Cannot transfer entangled particles individually");
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(!isEntangled(tokenId), "Cannot transfer entangled particles individually");
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // Override necessary ERC165 function
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```