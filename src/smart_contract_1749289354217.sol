Okay, here is a Solidity smart contract concept named `QuantumFluctuations`. It blends ideas from dynamic NFTs, state-dependent logic, simulated complex systems, and basic governance, aiming for creativity and advanced concepts beyond a standard token or simple NFT.

**Disclaimer:** This contract uses simulated randomness for conceptual purposes (`_calculateQuantumNoise`). For any production system requiring secure or truly unpredictable randomness, a service like Chainlink VRF should be used. State-dependent logic and complexity increase gas costs; careful optimization would be needed for a production deployment. The governance mechanism is a simplified example.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title QuantumFluctuations
 * @dev A conceptual smart contract exploring dynamic state, particle (NFT) interactions,
 *      simulated quantum mechanics effects, staking, and basic governance based on
 *      a fluctuating 'Dimension'.
 */

/**
 * OUTLINE:
 * 1. State Management: Enum for Dimensions, track current dimension, fluctuation parameters.
 * 2. Particle (NFT) Management: ERC721Enumerable + URIStorage for unique, dynamic assets. Particles have alignment, intrinsic energy, and can be entangled.
 * 3. Fluctuations: Mechanism to trigger dimension changes based on simulated noise.
 * 4. Particle Interactions: Entanglement (linking two particles), Tunneling (random alignment change attempt).
 * 5. Staking: Stake particles to earn potential yield based on alignment and dimension.
 * 6. User Affinity: Track user alignment/interaction with dimensions.
 * 7. Governance: Basic system for proposals and voting (e.g., change fluctuation params, add dimensions).
 * 8. Utility: Pause, withdrawal, view functions.
 */

/**
 * FUNCTION SUMMARY:
 *
 * --- Core State & Fluctuations ---
 * 1. getCurrentDimension(): View current active dimension.
 * 2. triggerFluctuation(): Public function to advance the contract's state (dimension).
 * 3. getDimensionInfo(uint256 dimensionId): View name/description of a dimension.
 * 4. setFluctuationParameters(uint256 _baseNoiseSeed, uint256 _noiseFactor, uint256 _dimensionChangeThreshold): Owner/Governance sets parameters for fluctuation simulation.
 * 5. getFluctuationParameters(): View current fluctuation parameters.
 * 6. addDimension(string calldata name, string calldata description): Governance adds a new dimension type.
 * 7. removeDimension(uint256 dimensionId): Governance removes a dimension type (careful with existing state).
 * 8. getDimensionCount(): View total number of defined dimensions.
 *
 * --- Particle (Dynamic NFT) Management ---
 * 9. mintParticle(string calldata tokenURI): Mint a new Particle NFT. Cost required. Intrinsic energy assigned. Initial alignment set.
 * 10. getParticleDetails(uint256 particleId): View detailed state of a particle (alignment, energy, entanglement).
 * 11. updateParticleAlignment(uint256 particleId, uint256 newAlignmentId): Internal/Owner/Governance function to change a particle's alignment.
 * 12. setParticleMetadataURI(uint256 particleId, string calldata uri): Owner/Governance sets metadata URI for a specific particle.
 * 13. entangleParticles(uint256 particle1Id, uint256 particle2Id): Owner of two particles can entangle them.
 * 14. disentangleParticles(uint256 particleId): Owner of an entangled particle can disentangle it (and its pair).
 * 15. getEntangledParticle(uint256 particleId): View which particle, if any, a particle is entangled with.
 * 16. triggerEntanglementFluctuation(uint256 particleId): Trigger a fluctuation effect specifically affecting an entangled pair.
 *
 * --- Staking ---
 * 17. stakeParticle(uint256 particleId): Stake a Particle NFT to the contract.
 * 18. unstakeParticle(uint256 particleId): Unstake a previously staked Particle NFT.
 * 19. getStakedParticles(address staker): View list of particles staked by an address.
 * 20. calculatePotentialYield(uint256 particleId): View potential yield accumulated for a staked particle based on its history, alignment, and dimension states.
 * 21. claimYield(uint256[] calldata particleIds): Claim accumulated yield for multiple staked particles.
 * 22. isParticleStaked(uint256 particleId): Check if a particle is currently staked.
 *
 * --- User Affinity & Interactions ---
 * 23. observeDimension(): A user action that slightly influences future fluctuations and updates their dimension affinity. Costs gas.
 * 24. getUserDimensionAffinity(address user, uint256 dimensionId): View a user's affinity score for a specific dimension.
 * 25. simulateTunneling(uint256 particleId): Attempt to randomly change a staked particle's alignment to a different dimension. Low probability, uses simulated noise.
 *
 * --- Governance ---
 * 26. proposeGovernanceAction(GovernanceActionType actionType, bytes calldata data, string calldata description): Stakeholders propose changes.
 * 27. voteOnProposal(uint256 proposalId, bool voteYes): Stakeholders vote on an active proposal. Voting power based on staked particles.
 * 28. executeProposal(uint256 proposalId): Execute a successful proposal after the voting period ends.
 * 29. getProposalDetails(uint256 proposalId): View state, votes, and details of a proposal.
 * 30. getVotingPower(address voter): View a user's current voting power (based on staked particles).
 *
 * --- Utility & ERC721 Standards (Included via Inheritance) ---
 * 31. transferFrom(address from, address to, uint256 tokenId): ERC721 standard transfer.
 * 32. safeTransferFrom(address from, address to, uint256 tokenId): ERC721 standard safe transfer.
 * 33. balanceOf(address owner): ERC721 standard balance.
 * 34. ownerOf(uint256 tokenId): ERC721 standard owner lookup.
 * 35. totalSupply(): ERC721Enumerable standard total supply.
 * 36. tokenByIndex(uint256 index): ERC721Enumerable standard token by index.
 * 37. tokenOfOwnerByIndex(address owner, uint256 index): ERC721Enumerable standard token of owner by index.
 * 38. tokenURI(uint256 tokenId): ERC721URIStorage standard token URI.
 * 39. supportsInterface(bytes4 interfaceId): ERC721 standard interface support.
 * 40. pause(): Owner pauses the contract.
 * 41. unpause(): Owner unpauses the contract.
 * 42. paused(): View pause status.
 * 43. withdrawEther(address payable recipient, uint256 amount): Owner withdraws contract balance.
 *
 * Note: The inherited ERC721 functions count towards the total function count requirement.
 */

// --- Error Definitions ---
error QuantumFluctuations__OnlyStakedParticleOwner();
error QuantumFluctuations__NotOwnerOrApproved();
error QuantumFluctuations__ParticleNotStaked();
error QuantumFluctuations__ParticleAlreadyStaked();
error QuantumFluctuations__ParticlesNotEntangled();
error QuantumFluctuations__ParticlesAlreadyEntangled();
error QuantumFluctuations__CannotEntangleSameParticle();
error QuantumFluctuations__ParticleNotFound();
error QuantumFluctuations__InvalidDimension();
error QuantumFluctuations__NoYieldToClaim();
error QuantumFluctuations__InsufficientVotingPower();
error QuantumFluctuations__ProposalNotFound();
error QuantumFluctuations__ProposalVotingPeriodNotActive();
error QuantumFluctuations__ProposalAlreadyVoted();
error QuantumFluctuations__ProposalVotingPeriodActive();
error QuantumFluctuations__ProposalNotExecutable();
error QuantumFluctuations__ProposalAlreadyExecuted();
error QuantumFluctuations__ExecutionFailed();
error QuantumFluctuations__InvalidProposalData();
error QuantumFluctuations__InsufficientEther();
error QuantumFluctuations__CannotRemoveLastDimension();
error QuantumFluctuations__ParticleRequiresCurrentAlignment();
error QuantumFluctuations__ParticleNotEntangledWithGivenPair();

// --- Enums ---
enum GovernanceActionType {
    UpdateFluctuationParams,
    AddDimension,
    RemoveDimension,
    SetParticleMetadataURI // Governance can update specific particle metadata
}

enum ProposalState {
    Pending,
    Active,
    Succeeded,
    Failed,
    Executed
}

// --- Structs ---
struct Particle {
    uint256 intrinsicEnergy; // Fixed at creation, influences yield potential
    uint256 currentAlignment; // ID of the dimension it's currently aligned with
    uint256 creationBlock;
    uint256 entangledWith; // 0 if not entangled, otherwise the particleId it's linked to
    bool isStaked;
    uint256 stakeStartTime;
    mapping(uint256 => uint256) alignmentHistory; // block.number => dimensionId -- Maybe too much state? Let's track last alignment change block instead.
    uint256 lastAlignmentChangeBlock;
}

struct Dimension {
    string name;
    string description;
    // Could add properties like 'energy cost' or 'yield multiplier' later
}

struct Proposal {
    uint256 id;
    GovernanceActionType actionType;
    bytes data; // Encoded data for the action (e.g., new params, dimension info, particleId+URI)
    string description;
    uint256 proposer; // particleId of the proposer's staked particle (simplified)
    uint256 voteStartBlock;
    uint256 voteEndBlock;
    uint256 yesVotes;
    uint256 noVotes;
    mapping(address => bool) hasVoted;
    ProposalState state;
}

contract QuantumFluctuations is ERC721Enumerable, ERC721URIStorage, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Strings for uint256;

    Counters.Counter private _particleIds;
    Counters.Counter private _dimensionIds;
    Counters.Counter private _proposalIds;

    uint256 private _currentDimensionId; // ID of the dimension the system is currently in

    mapping(uint256 => Particle) private _particles;
    mapping(uint256 => Dimension) private _dimensions;
    mapping(address => uint256[]) private _stakedParticlesByAddress; // array of particleIds
    mapping(uint256 => address) private _stakedParticleOwner; // particleId => owner address

    mapping(address => mapping(uint256 => uint256)) private _userDimensionAffinity; // address => dimensionId => score

    mapping(uint256 => Proposal) private _proposals;

    // Fluctuaton Parameters (adjustable via governance)
    uint256 public baseNoiseSeed;
    uint256 public noiseFactor;
    uint256 public dimensionChangeThreshold;
    uint256 public fluctuationTriggerCooldown; // Minimum blocks between triggers
    uint256 private lastFluctuationBlock;

    // Governance Parameters (adjustable via governance, or hardcoded initially)
    uint256 public constant GOVERNANCE_VOTING_PERIOD_BLOCKS = 100; // Approx 25 minutes
    uint256 public constant GOVERNANCE_PROPOSAL_STAKE_REQUIRED = 1; // Number of staked particles
    uint256 public constant GOVERNANCE_MIN_VOTES_PERCENTAGE = 5; // 5% of total staked particles needed to pass

    // Yield Calculation Parameters (simplified, adjustable via governance)
    uint256 public constant BASE_YIELD_RATE_PER_BLOCK = 1e14; // Example: 0.0001 Ether per block
    uint256 public constant ALIGNMENT_BOOST_FACTOR = 2; // Multiply yield by this if aligned
    uint256 public constant ENTANGLEMENT_BOOST_FACTOR = 1.5 ether; // Add a flat amount if entangled (simplified)

    // Simulated Tunneling Parameters
    uint256 public constant TUNNELING_BASE_SUCCESS_CHANCE = 50; // Out of 1000 (5%)
    uint256 public constant TUNNELING_ALIGNMENT_BOOST_FACTOR = 10; // Added to chance per affinity point (simplified)


    // --- Events ---
    event ParticleMinted(uint256 indexed particleId, address indexed owner, uint256 initialAlignment, uint256 intrinsicEnergy);
    event DimensionFluctuated(uint256 indexed oldDimensionId, uint256 indexed newDimensionId, uint256 noiseValue);
    event ParticleAlignmentChanged(uint256 indexed particleId, uint256 indexed oldAlignmentId, uint256 indexed newAlignmentId, string reason);
    event ParticlesEntangled(uint256 indexed particle1Id, uint256 indexed particle2Id);
    event ParticlesDisentangled(uint256 indexed particle1Id, uint256 indexed particle2Id);
    event ParticleStaked(uint256 indexed particleId, address indexed staker);
    event ParticleUnstaked(uint256 indexed particleId, address indexed staker);
    event YieldClaimed(address indexed user, uint256[] indexed particleIds, uint256 amount);
    event UserDimensionAffinityUpdated(address indexed user, uint256 indexed dimensionId, uint256 newAffinity);
    event TunnelingAttempt(uint256 indexed particleId, bool success, uint256 newAlignmentId);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, GovernanceActionType actionType, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteYes, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event FluctuationParametersUpdated(uint256 baseNoiseSeed, uint256 noiseFactor, uint256 dimensionChangeThreshold);
    event DimensionAdded(uint256 indexed dimensionId, string name);
    event DimensionRemoved(uint256 indexed dimensionId);
    event ParticleMetadataURISet(uint256 indexed particleId, string uri);
    event EntanglementFluctuationTriggered(uint256 indexed particle1Id, uint256 indexed particle2Id, uint256 noiseValue);


    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        // Initialize with a default dimension
        _addDimension("Void", "The initial, undefined state.");
        _currentDimensionId = 1; // Assuming the first dimension added is ID 1
        lastFluctuationBlock = block.number;

        // Set initial fluctuation parameters (can be changed by owner/governance)
        baseNoiseSeed = 12345; // Arbitrary initial seed
        noiseFactor = 1000; // Arbitrary initial factor
        dimensionChangeThreshold = 5000; // Arbitrary threshold
        fluctuationTriggerCooldown = 10; // Can only trigger fluctuation every 10 blocks
    }

    // --- Inherited Function Overrides ---
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        if (!_exists(tokenId)) revert ERC721Enumerable.ERC721NonexistentToken();
        string memory base = super.tokenURI(tokenId);
        Particle storage particle = _particles[tokenId];

        // Append dynamic data (simplified - could be a complex JSON payload in a real app)
        // For this example, we'll just indicate alignment and staked status
        string memory dynamicData = string.concat(
            "?alignment=", particle.currentAlignment.toString(),
            "&staked=", particle.isStaked ? "true" : "false",
            "&entangled=", particle.entangledWith == 0 ? "false" : particle.entangledWith.toString(),
            "&energy=", particle.intrinsicEnergy.toString()
        );

        return string.concat(base, dynamicData);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // --- Modifiers ---
    modifier onlyStakedParticleOwner(uint256 particleId) {
        if (!_particles[particleId].isStaked || _stakedParticleOwner[particleId] != msg.sender) {
             revert QuantumFluctuations__OnlyStakedParticleOwner();
        }
        _;
    }

    modifier onlyParticleOwnerOrApproved(uint256 particleId) {
        if (ownerOf(particleId) != msg.sender && getApproved(particleId) != msg.sender && !isApprovedForAll(ownerOf(particleId), msg.sender)) {
            revert QuantumFluctuations__NotOwnerOrApproved();
        }
        _;
    }

    // --- Core State & Fluctuations ---

    /**
     * @dev Returns the ID of the currently active dimension.
     */
    function getCurrentDimension() public view returns (uint256) {
        return _currentDimensionId;
    }

    /**
     * @dev Triggers a fluctuation event, potentially changing the current dimension.
     * Limited by a cooldown period.
     */
    function triggerFluctuation() public whenNotPaused {
        if (block.number < lastFluctuationBlock + fluctuationTriggerCooldown) {
            // Too soon to trigger another fluctuation
            return;
        }

        uint256 oldDimensionId = _currentDimensionId;
        uint256 noise = _calculateQuantumNoise();
        _applyFluctuation(noise);
        lastFluctuationBlock = block.number;

        emit DimensionFluctuated(oldDimensionId, _currentDimensionId, noise);
    }

    /**
     * @dev Internal function to calculate a simulated quantum noise value.
     * Uses a combination of block data and state parameters.
     * NOTE: This is NOT cryptographically secure randomness and is predictable.
     */
    function _calculateQuantumNoise() internal view returns (uint256) {
        // Combine various sources for a non-deterministic (but predictable) value
        uint256 seed = baseNoiseSeed + block.timestamp + block.number + uint256(keccak256(abi.encodePacked(msg.sender, tx.origin, tx.gasprice)));
        // Add a factor based on total staked particles or other contract state?
        // uint256 complexity = _particleIds.current() + _proposalIds.current();
        // seed += complexity;

        // Use previous block hash if available and not too old
        bytes32 prevBlockHash = block.blockhash(block.number - 1);
        if (prevBlockHash != bytes32(0)) {
            seed += uint256(keccak256(abi.encodePacked(seed, prevBlockHash)));
        }

         // Incorporate aggregated user affinity somehow? (Simplified for now)
        uint256 totalAffinitySum = 0;
        // This would require iterating over users and dimensions, which is gas intensive.
        // A better approach might be a state variable that tracks total affinity.

        seed = seed.add(totalAffinitySum);


        // Simple hash-based "noise"
        uint256 noise = uint256(keccak256(abi.encodePacked(seed, noiseFactor)));

        // Simulate interaction with current dimension properties (if dimensions had properties)
        // For now, just add current dimension ID
        noise = noise.add(_currentDimensionId);


        return noise;
    }

    /**
     * @dev Internal function to apply the calculated noise to potentially change the dimension.
     * Simplified: Noise value compared to a threshold determines if we shift, and if so, where.
     */
    function _applyFluctuation(uint256 noise) internal {
        uint256 totalDimensions = _dimensionIds.current();
        if (totalDimensions <= 1) return; // Cannot change dimension if only one exists

        uint256 currentDimensionIndex = _currentDimensionId - 1; // Assuming IDs start at 1

        if (noise % dimensionChangeThreshold == 0) {
             // Significant fluctuation detected, potentially jump to a random dimension
            uint256 nextDimensionIndex = noise % totalDimensions;
            _currentDimensionId = nextDimensionIndex + 1;

        } else if (noise % (dimensionChangeThreshold / 2) == 0) {
             // Moderate fluctuation, shift to an adjacent dimension
            uint256 direction = (noise % 2 == 0) ? 1 : (totalDimensions - 1); // 1 for forward, totalDimensions-1 for backward wrap-around
            _currentDimensionId = (currentDimensionIndex + direction) % totalDimensions + 1;

        }
        // Else: No significant change, currentDimensionId remains the same
    }

    /**
     * @dev Returns the name and description for a given dimension ID.
     * @param dimensionId The ID of the dimension.
     */
    function getDimensionInfo(uint256 dimensionId) public view returns (string memory name, string memory description) {
        if (dimensionId == 0 || dimensionId > _dimensionIds.current()) revert QuantumFluctuations__InvalidDimension();
        Dimension storage dim = _dimensions[dimensionId];
        return (dim.name, dim.description);
    }

    /**
     * @dev Allows the owner or governance to set parameters influencing the fluctuation simulation.
     * @param _baseNoiseSeed New base seed for noise calculation.
     * @param _noiseFactor New factor multiplying the final noise value range.
     * @param _dimensionChangeThreshold New threshold determining significant fluctuations.
     */
    function setFluctuationParameters(uint256 _baseNoiseSeed, uint256 _noiseFactor, uint256 _dimensionChangeThreshold) public onlyOwnerOrGovernance {
        baseNoiseSeed = _baseNoiseSeed;
        noiseFactor = _noiseFactor;
        dimensionChangeThreshold = _dimensionChangeThreshold;
        emit FluctuationParametersUpdated(baseNoiseSeed, noiseFactor, dimensionChangeThreshold);
    }

     /**
     * @dev Views the current fluctuation parameters.
     */
    function getFluctuationParameters() public view returns (uint256, uint256, uint256) {
        return (baseNoiseSeed, noiseFactor, dimensionChangeThreshold);
    }

    /**
     * @dev Allows governance to add a new dimension type.
     * @param name The name of the new dimension.
     * @param description A description of the new dimension.
     */
    function addDimension(string calldata name, string calldata description) public onlyOwnerOrGovernance {
        _addDimension(name, description);
    }

    /**
     * @dev Internal function to add a new dimension.
     */
    function _addDimension(string calldata name, string calldata description) internal {
        _dimensionIds.increment();
        uint256 newId = _dimensionIds.current();
        _dimensions[newId] = Dimension(name, description);
        emit DimensionAdded(newId, name);
    }

     /**
     * @dev Allows governance to remove a dimension type.
     * Requires the dimension ID to be valid and not the current dimension.
     * @param dimensionId The ID of the dimension to remove.
     */
    function removeDimension(uint256 dimensionId) public onlyOwnerOrGovernance {
        if (dimensionId == 0 || dimensionId > _dimensionIds.current()) revert QuantumFluctuations__InvalidDimension();
        if (dimensionId == _currentDimensionId) revert QuantumFluctuations__InvalidDimension(); // Cannot remove current dimension
        if (_dimensionIds.current() <= 1) revert QuantumFluctuations__CannotRemoveLastDimension(); // Must have at least one dimension

        // Note: This doesn't update particle alignments pointing to this dimension.
        // A more robust system would handle this (e.g., re-align particles, mark dimension as deprecated).
        // For this concept, we'll just delete the dimension data.

        delete _dimensions[dimensionId]; // Deletes the struct data
        // Does NOT decrement _dimensionIds.current() to avoid ID conflicts.
        // Instead, rely on checking if _dimensions[id].name is empty string.

        emit DimensionRemoved(dimensionId);
    }

    /**
     * @dev Returns the total number of defined dimensions (including potentially removed ones if ID was reused).
     * Use getDimensionInfo(id) and check name != "" to see active ones.
     */
    function getDimensionCount() public view returns (uint256) {
        return _dimensionIds.current();
    }


    // --- Particle (Dynamic NFT) Management ---

    /**
     * @dev Mints a new Particle NFT. Requires sending ether to contribute energy.
     * @param tokenURI The metadata URI for the particle.
     */
    function mintParticle(string calldata tokenURI) public payable whenNotPaused returns (uint256) {
        // Example cost to mint
        uint256 mintCost = 0.01 ether; // Example cost
        if (msg.value < mintCost) revert QuantumFluctuations__InsufficientEther();

        _particleIds.increment();
        uint256 newItemId = _particleIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);

        // Simulate assigning intrinsic energy (could be based on msg.value, noise, etc.)
        // For simplicity, let's use a noise-based value
        uint256 intrinsicEnergy = _calculateQuantumNoise() % 1000 + 100; // Energy between 100 and 1099

        // Initial alignment is random or aligned with current dimension? Let's make it random.
        uint256 initialAlignment = (_calculateQuantumNoise() % _dimensionIds.current()) + 1;
         // Check if dimension exists
        while(_dimensions[initialAlignment].name == "") {
             initialAlignment = (initialAlignment % _dimensionIds.current()) + 1;
        }

        _particles[newItemId] = Particle(
            intrinsicEnergy,
            initialAlignment,
            block.number,
            0, // not entangled
            false, // not staked
            0, // stake time
            block.number // last alignment change
        );

        emit ParticleMinted(newItemId, msg.sender, initialAlignment, intrinsicEnergy);

        // Transfer any excess ether back
        if (msg.value > mintCost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - mintCost}("");
            require(success, "Refund failed");
        }

        return newItemId;
    }

    /**
     * @dev Gets the detailed state of a specific particle.
     * @param particleId The ID of the particle.
     */
    function getParticleDetails(uint256 particleId) public view returns (
        uint256 intrinsicEnergy,
        uint256 currentAlignment,
        uint256 creationBlock,
        uint256 entangledWith,
        bool isStaked,
        uint256 stakeStartTime,
        uint256 lastAlignmentChangeBlock
    ) {
         if (!_exists(particleId)) revert ERC721Enumerable.ERC721NonexistentToken();
         Particle storage particle = _particles[particleId];
         return (
             particle.intrinsicEnergy,
             particle.currentAlignment,
             particle.creationBlock,
             particle.entangledWith,
             particle.isStaked,
             particle.stakeStartTime,
             particle.lastAlignmentChangeBlock
         );
    }

    /**
     * @dev Internal or governance controlled function to update a particle's alignment.
     * @param particleId The ID of the particle.
     * @param newAlignmentId The new dimension ID for alignment.
     * @param reason String describing why the alignment changed.
     */
    function _updateParticleAlignment(uint256 particleId, uint256 newAlignmentId, string memory reason) internal {
         if (!_exists(particleId)) revert QuantumFluctuations__ParticleNotFound();
         if (newAlignmentId == 0 || (newAlignmentId <= _dimensionIds.current() && _dimensions[newAlignmentId].name == "")) revert QuantumFluctuations__InvalidDimension();

         Particle storage particle = _particles[particleId];
         uint256 oldAlignmentId = particle.currentAlignment;
         if (oldAlignmentId == newAlignmentId) return; // No change needed

         particle.currentAlignment = newAlignmentId;
         particle.lastAlignmentChangeBlock = block.number;

         // Potentially update alignmentHistory mapping here if we tracked it (removed for gas)
         // particle.alignmentHistory[block.number] = newAlignmentId;

         emit ParticleAlignmentChanged(particleId, oldAlignmentId, newAlignmentId, reason);
    }

     /**
     * @dev Allows the owner or governance to set the base metadata URI for a specific particle.
     * @param particleId The ID of the particle.
     * @param uri The new URI.
     */
    function setParticleMetadataURI(uint256 particleId, string calldata uri) public onlyOwnerOrGovernance {
        if (!_exists(particleId)) revert ERC721Enumerable.ERC721NonexistentToken();
        _setTokenURI(particleId, uri);
        emit ParticleMetadataURISet(particleId, uri);
    }

    /**
     * @dev Entangles two particles owned by the same address.
     * Entangled particles influence each other during certain fluctuations.
     * @param particle1Id The ID of the first particle.
     * @param particle2Id The ID of the second particle.
     */
    function entangleParticles(uint256 particle1Id, uint256 particle2Id) public whenNotPaused {
        address owner = ownerOf(particle1Id);
        if (ownerOf(particle2Id) != owner) revert QuantumFluctuations__NotOwnerOrApproved(); // Must own both
        if (particle1Id == particle2Id) revert QuantumFluctuations__CannotEntangleSameParticle();
        if (_particles[particle1Id].entangledWith != 0 || _particles[particle2Id].entangledWith != 0) revert QuantumFluctuations__ParticlesAlreadyEntangled();

        _particles[particle1Id].entangledWith = particle2Id;
        _particles[particle2Id].entangledWith = particle1Id;

        // Optional: Update metadata URIs to reflect entanglement
        _setTokenURI(particle1Id, tokenURI(particle1Id));
        _setTokenURI(particle2Id, tokenURI(particle2Id));


        emit ParticlesEntangled(particle1Id, particle2Id);
    }

    /**
     * @dev Disentangles a particle and its entangled pair. Requires ownership of the particle.
     * @param particleId The ID of the particle to disentangle.
     */
    function disentangleParticles(uint256 particleId) public whenNotPaused {
        if (ownerOf(particleId) != msg.sender) revert QuantumFluctuations__NotOwnerOrApproved();
        uint256 entangledWithId = _particles[particleId].entangledWith;
        if (entangledWithId == 0) revert QuantumFluctuations__ParticlesNotEntangled();

        // Check the pair is correctly entangled back
        if (_particles[entangledWithId].entangledWith != particleId) revert QuantumFluctuations__ParticleNotEntangledWithGivenPair();


        _particles[particleId].entangledWith = 0;
        _particles[entangledWithId].entangledWith = 0;

        // Optional: Update metadata URIs
        _setTokenURI(particleId, tokenURI(particleId));
        _setTokenURI(entangledWithId, tokenURI(entangledWithId));

        emit ParticlesDisentangled(particleId, entangledWithId);
    }

     /**
     * @dev Gets the particle ID that a given particle is entangled with. Returns 0 if not entangled.
     * @param particleId The ID of the particle.
     */
    function getEntangledParticle(uint256 particleId) public view returns (uint256) {
        if (!_exists(particleId)) revert QuantumFluctuations__ParticleNotFound();
        return _particles[particleId].entangledWith;
    }


    /**
     * @dev Triggers a special fluctuation that affects an entangled pair, potentially changing their alignments.
     * Requires owning one of the entangled particles.
     * @param particleId The ID of one of the entangled particles.
     */
    function triggerEntanglementFluctuation(uint256 particleId) public whenNotPaused {
        if (ownerOf(particleId) != msg.sender) revert QuantumFluctuations__NotOwnerOrApproved();
        uint256 entangledWithId = _particles[particleId].entangledWith;
         if (entangledWithId == 0) revert QuantumFluctuations__ParticlesNotEntangled();

        uint256 noise = _calculateQuantumNoise();

        // Simplified logic: Both particles' alignment shifts towards a dimension influenced by the noise,
        // or perhaps towards each other's alignment, or the current system dimension.
        // Let's make them potentially align with a noise-influenced dimension.

        uint256 totalDimensions = _dimensionIds.current();
        if (totalDimensions == 0) return; // Cannot align if no dimensions exist

        uint256 potentialNewAlignmentId = (noise % totalDimensions) + 1;
        // Ensure the dimension exists
        while(_dimensions[potentialNewAlignmentId].name == "") {
             potentialNewAlignmentId = (potentialNewAlignmentId % totalDimensions) + 1;
        }


        // Only change alignment if the noise strongly suggests it (e.g., noise is high)
        if (noise > (type(uint256).max / 2)) { // Arbitrary threshold
            _updateParticleAlignment(particleId, potentialNewAlignmentId, "Entanglement Fluctuation");
            _updateParticleAlignment(entangledWithId, potentialNewAlignmentId, "Entanglement Fluctuation");
        } else {
             // Small fluctuation, maybe a slight shift towards each other's current alignment?
             // Or just emit an event showing an interaction occurred?
             // Let's just emit the event for now without state change for simplicity.
              emit EntanglementFluctuationTriggered(particleId, entangledWithId, noise);
        }
    }


    // --- Staking ---

    /**
     * @dev Stakes a Particle NFT, transferring it to the contract.
     * Only the owner can stake their particles.
     * @param particleId The ID of the particle to stake.
     */
    function stakeParticle(uint256 particleId) public whenNotPaused {
        address owner = ownerOf(particleId);
        if (owner != msg.sender) revert QuantumFluctuations__NotOwnerOrApproved(); // Must be owner
        if (_particles[particleId].isStaked) revert QuantumFluctuations__ParticleAlreadyStaked();

        // Transfer the NFT to the contract
        _safeTransfer(msg.sender, address(this), particleId);

        // Update internal state
        _particles[particleId].isStaked = true;
        _particles[particleId].stakeStartTime = block.number;
        _stakedParticleOwner[particleId] = msg.sender;
        _stakedParticlesByAddress[msg.sender].push(particleId); // Add to user's list

        emit ParticleStaked(particleId, msg.sender);
    }

    /**
     * @dev Unstakes a Particle NFT, transferring it back to the original staker.
     * Only the original staker can unstake their particle.
     * @param particleId The ID of the particle to unstake.
     */
    function unstakeParticle(uint256 particleId) public whenNotPaused {
        if (!_particles[particleId].isStaked) revert QuantumFluctuations__ParticleNotStaked();
        if (_stakedParticleOwner[particleId] != msg.sender) revert QuantumFluctuations__OnlyStakedParticleOwner();

        // Transfer the NFT back to the staker
        _safeTransfer(address(this), msg.sender, particleId);

        // Update internal state
        _particles[particleId].isStaked = false;
        _particles[particleId].stakeStartTime = 0;
        delete _stakedParticleOwner[particleId]; // Remove owner lookup

        // Remove from user's list (simple swap-and-pop, less gas than ordered delete)
        uint256[] storage stakedParticles = _stakedParticlesByAddress[msg.sender];
        uint256 len = stakedParticles.length;
        for (uint256 i = 0; i < len; i++) {
            if (stakedParticles[i] == particleId) {
                stakedParticles[i] = stakedParticles[len - 1];
                stakedParticles.pop();
                break;
            }
        }

        emit ParticleUnstaked(particleId, msg.sender);
    }

    /**
     * @dev Gets the list of particle IDs staked by a specific address.
     * @param staker The address to check.
     */
    function getStakedParticles(address staker) public view returns (uint256[] memory) {
        return _stakedParticlesByAddress[staker];
    }

    /**
     * @dev Checks if a particle is currently staked.
     * @param particleId The ID of the particle.
     */
    function isParticleStaked(uint256 particleId) public view returns (bool) {
        return _particles[particleId].isStaked;
    }


    /**
     * @dev Calculates the potential yield accumulated for a single staked particle.
     * Yield is calculated based on stake duration, current dimension, and particle alignment.
     * This is a view function and does not claim the yield.
     * @param particleId The ID of the staked particle.
     */
    function calculatePotentialYield(uint256 particleId) public view returns (uint256) {
        if (!_particles[particleId].isStaked) return 0;

        Particle storage particle = _particles[particleId];
        uint256 duration = block.number.sub(particle.stakeStartTime);
        if (duration == 0) return 0;

        uint256 yieldPerBlock = BASE_YIELD_RATE_PER_BLOCK;

        // Boost yield if particle is aligned with the current dimension
        if (particle.currentAlignment == _currentDimensionId) {
            yieldPerBlock = yieldPerBlock.mul(ALIGNMENT_BOOST_FACTOR);
        }

        // Simplified entanglement boost (example: add a flat amount per block if entangled)
        if (particle.entangledWith != 0) {
            yieldPerBlock = yieldPerBlock.add(ENTANGLEMENT_BOOST_FACTOR / 1000); // Reduce entanglement boost to a per-block rate
        }

        // Incorporate intrinsic energy (e.g., energy acts as a multiplier)
        yieldPerBlock = yieldPerBlock.mul(particle.intrinsicEnergy).div(100); // Scale by energy (e.g., energy 100 means 1x yield)

        return duration.mul(yieldPerBlock);
    }

    /**
     * @dev Claims accumulated yield for multiple staked particles owned by the caller.
     * Transfers ether from the contract balance.
     * @param particleIds An array of particle IDs to claim yield for.
     */
    function claimYield(uint256[] calldata particleIds) public whenNotPaused {
        uint256 totalYield = 0;
        for (uint256 i = 0; i < particleIds.length; i++) {
            uint256 particleId = particleIds[i];
            if (_particles[particleId].isStaked && _stakedParticleOwner[particleId] == msg.sender) {
                uint256 particleYield = calculatePotentialYield(particleId);
                if (particleYield > 0) {
                    totalYield = totalYield.add(particleYield);
                    // Reset stake timer for claimed particles
                    _particles[particleId].stakeStartTime = block.number;
                    // Note: This model resets *all* yield history on claim. A more complex model
                    // would track claimed vs. unclaimed yield.
                }
            }
        }

        if (totalYield == 0) revert QuantumFluctuations__NoYieldToClaim();

        // Ensure contract has enough balance
        if (address(this).balance < totalYield) revert QuantumFluctuations__ExecutionFailed(); // Or a more specific error

        (bool success, ) = payable(msg.sender).call{value: totalYield}("");
        if (!success) revert QuantumFluctuations__ExecutionFailed(); // Transfer failed

        emit YieldClaimed(msg.sender, particleIds, totalYield);
    }


    // --- User Affinity & Interactions ---

    /**
     * @dev Allows a user to 'observe' the current dimension. This action
     * updates their affinity towards that dimension and slightly influences the
     * next fluctuation calculation.
     * Costs gas to execute.
     */
    function observeDimension() public whenNotPaused {
        uint256 currentDimId = _currentDimensionId;

        // Increase user's affinity for the current dimension
        _userDimensionAffinity[msg.sender][currentDimId] = _userDimensionAffinity[msg.sender][currentDimId].add(1); // Simple affinity increase

        // Note: The influence on _calculateQuantumNoise would require
        // a way to aggregate user observations since the last fluctuation,
        // potentially a state variable tracking aggregated 'observation energy'.
        // For simplicity here, the influence is implicit in the next noise calculation
        // if we were to add aggregated user affinity to the noise seed.

        emit UserDimensionAffinityUpdated(msg.sender, currentDimId, _userDimensionAffinity[msg.sender][currentDimId]);

        // Could add a small gas cost simulation or require a token payment here
    }

    /**
     * @dev Gets a user's affinity score for a specific dimension.
     * @param user The address of the user.
     * @param dimensionId The ID of the dimension.
     */
    function getUserDimensionAffinity(address user, uint256 dimensionId) public view returns (uint256) {
        return _userDimensionAffinity[user][dimensionId];
    }

    /**
     * @dev Internal function to update user affinity. Can be triggered by staking, claiming yield, etc.
     */
    function _updateUserDimensionAffinity(address user, uint256 dimensionId, uint256 points) internal {
         _userDimensionAffinity[user][dimensionId] = _userDimensionAffinity[user][dimensionId].add(points);
         emit UserDimensionAffinityUpdated(user, dimensionId, _userDimensionAffinity[user][dimensionId]);
    }


    /**
     * @dev Attempts to simulate quantum tunneling, allowing a staked particle
     * to randomly change its alignment to a different dimension.
     * Has a probability of success influenced by noise and user affinity.
     * Costs gas.
     * @param particleId The ID of the staked particle.
     */
    function simulateTunneling(uint256 particleId) public whenNotPaused onlyStakedParticleOwner(particleId) {
         Particle storage particle = _particles[particleId];
         if (particle.currentAlignment == 0) revert QuantumFluctuations__ParticleRequiresCurrentAlignment(); // Must have an alignment

        uint256 noise = _calculateQuantumNoise();
        uint256 totalDimensions = _dimensionIds.current();
        if (totalDimensions <= 1) {
            emit TunnelingAttempt(particleId, false, particle.currentAlignment);
            return; // Cannot tunnel if only one or zero dimensions exist
        }

        // Calculate success chance
        uint256 baseChance = TUNNELING_BASE_SUCCESS_CHANCE; // e.g., 5%
        uint256 userAffinityForCurrentDim = _userDimensionAffinity[msg.sender][particle.currentAlignment];
        uint256 chance = baseChance.add(userAffinityForCurrentDim.mul(TUNNELING_ALIGNMENT_BOOST_FACTOR)); // Affinity slightly boosts chance

        // Use noise to determine success
        uint256 successRoll = noise % 1000; // Roll between 0 and 999

        if (successRoll < chance) {
            // Success: Find a new, different alignment
            uint256 oldAlignment = particle.currentAlignment;
            uint256 newAlignment = oldAlignment;

            // Pick a random *different* valid dimension
            uint256 attemptCount = 0;
            do {
                newAlignment = (noise + attemptCount) % totalDimensions + 1;
                 // Ensure the dimension exists and is different from current
                 attemptCount++;
            } while((_dimensions[newAlignment].name == "" || newAlignment == oldAlignment) && attemptCount < totalDimensions * 2); // Prevent infinite loop

            if (_dimensions[newAlignment].name != "" && newAlignment != oldAlignment) {
                 _updateParticleAlignment(particleId, newAlignment, "Tunneling");
                 emit TunnelingAttempt(particleId, true, newAlignment);
            } else {
                 // Couldn't find a valid new dimension
                 emit TunnelingAttempt(particleId, false, particle.currentAlignment);
            }

        } else {
            // Failure
            emit TunnelingAttempt(particleId, false, particle.currentAlignment);
        }
    }


    // --- Governance ---

    /**
     * @dev Allows users with staked particles to propose governance actions.
     * Requires a minimum number of staked particles to propose.
     * @param actionType The type of action proposed.
     * @param data Encoded data specific to the action (e.g., new params, dimension info).
     * @param description Text description of the proposal.
     */
    function proposeGovernanceAction(GovernanceActionType actionType, bytes calldata data, string calldata description) public whenNotPaused returns (uint256) {
        uint256 votingPower = getVotingPower(msg.sender);
        if (votingPower < GOVERNANCE_PROPOSAL_STAKE_REQUIRED) revert QuantumFluctuations__InsufficientVotingPower();

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        // Find one of the user's staked particles to represent the proposer (simplified)
        uint256 proposerParticleId = _stakedParticlesByAddress[msg.sender][0];
        // In a real system, proposal stake might be locked separately.

        _proposals[proposalId] = Proposal(
            proposalId,
            actionType,
            data,
            description,
            proposerParticleId,
            block.number,
            block.number + GOVERNANCE_VOTING_PERIOD_BLOCKS,
            0, 0,
            // hasVoted mapping initialized empty
            ProposalState.Active
        );

        emit ProposalCreated(proposalId, msg.sender, actionType, description);
        emit ProposalStateChanged(proposalId, ProposalState.Active);

        return proposalId;
    }

    /**
     * @dev Allows users with staked particles to vote on an active proposal.
     * Voting power is based on the number of particles staked at the time of voting.
     * @param proposalId The ID of the proposal.
     * @param voteYes True for a 'Yes' vote, false for a 'No' vote.
     */
    function voteOnProposal(uint256 proposalId, bool voteYes) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) revert QuantumFluctuations__ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert QuantumFluctuations__ProposalVotingPeriodNotActive();
        if (block.number > proposal.voteEndBlock) {
             // Voting period ended, update state if necessary
             _updateProposalState(proposalId);
             if (proposal.state != ProposalState.Active) revert QuantumFluctuations__ProposalVotingPeriodNotActive();
        }

        if (proposal.hasVoted[msg.sender]) revert QuantumFluctuations__ProposalAlreadyVoted();

        uint256 votingPower = getVotingPower(msg.sender);
        if (votingPower == 0) revert QuantumFluctuations__InsufficientVotingPower();

        if (voteYes) {
            proposal.yesVotes = proposal.yesVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, voteYes, votingPower);

        // Check if voting period ended immediately after this vote
        if (block.number >= proposal.voteEndBlock) {
             _updateProposalState(proposalId);
        }
    }

    /**
     * @dev Updates the state of a proposal based on time and vote counts.
     * Internal helper or can be called externally to trigger state change.
     */
    function _updateProposalState(uint256 proposalId) internal {
         Proposal storage proposal = _proposals[proposalId];
         if (proposal.state != ProposalState.Active) return;

         if (block.number < proposal.voteEndBlock) return; // Voting period not over yet

         // Check minimum participation (total votes vs. total staked power at start of vote?)
         // Simplified: Check against total staked power *now* - requires summing staked particles globally (expensive).
         // Or check against voting power of proposer?
         // Let's simplify: Just require minimum percentage of total supply of particles have voted.
         uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
         uint256 totalParticles = _particleIds.current();
         // Simplified check: Min votes must be X% of total particles *ever* minted.
         uint256 minRequiredVotes = totalParticles.mul(GOVERNANCE_MIN_VOTES_PERCENTAGE).div(100);

         if (totalVotes < minRequiredVotes) {
             proposal.state = ProposalState.Failed;
         } else {
             if (proposal.yesVotes > proposal.noVotes) {
                 proposal.state = ProposalState.Succeeded;
             } else {
                 proposal.state = ProposalState.Failed;
             }
         }
         emit ProposalStateChanged(proposalId, proposal.state);
    }


    /**
     * @dev Executes a proposal that has succeeded and whose voting period has ended.
     * Only executable once.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) revert QuantumFluctuations__ProposalNotFound();

        // Ensure voting period is over and update state if needed
        if (proposal.state == ProposalState.Active && block.number >= proposal.voteEndBlock) {
             _updateProposalState(proposalId);
        }

        if (proposal.state != ProposalState.Succeeded) revert QuantumFluctuations__ProposalNotExecutable();
        if (proposal.state == ProposalState.Executed) revert QuantumFluctuations__ProposalAlreadyExecuted();

        bool success = false;
        // Execute the action based on actionType
        if (proposal.actionType == GovernanceActionType.UpdateFluctuationParams) {
            (uint256 _baseNoiseSeed, uint256 _noiseFactor, uint256 _dimensionChangeThreshold) = abi.decode(proposal.data, (uint256, uint256, uint256));
            setFluctuationParameters(_baseNoiseSeed, _noiseFactor, _dimensionChangeThreshold);
            success = true;
        } else if (proposal.actionType == GovernanceActionType.AddDimension) {
            (string memory name, string memory description) = abi.decode(proposal.data, (string, string));
             _addDimension(name, description); // Direct call to internal helper
            success = true;
        } else if (proposal.actionType == GovernanceActionType.RemoveDimension) {
             (uint256 dimensionId) = abi.decode(proposal.data, (uint256));
             removeDimension(dimensionId); // Direct call
            success = true;
        } else if (proposal.actionType == GovernanceActionType.SetParticleMetadataURI) {
             (uint256 particleId, string memory uri) = abi.decode(proposal.data, (uint256, string));
             // Check if particle exists before calling internal
             if (_exists(particleId)) {
                  _setTokenURI(particleId, uri);
                  emit ParticleMetadataURISet(particleId, uri);
                  success = true;
             } else {
                 success = false; // Particle doesn't exist
             }

        } else {
             revert QuantumFluctuations__InvalidProposalData(); // Unknown action type
        }

        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);
        emit ProposalExecuted(proposalId, success);

        if (!success) revert QuantumFluctuations__ExecutionFailed(); // Revert if execution logic failed
    }

    /**
     * @dev Gets the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     */
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        GovernanceActionType actionType,
        string memory description,
        uint256 voteStartBlock,
        uint256 voteEndBlock,
        uint256 yesVotes,
        uint256 noVotes,
        ProposalState state
    ) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) revert QuantumFluctuations__ProposalNotFound();

        ProposalState currentState = proposal.state;
        // If active and voting period is over, calculate final state for view
        if (currentState == ProposalState.Active && block.number >= proposal.voteEndBlock) {
             uint256 totalVotes = proposal.yesVotes.add(proposal.noVotes);
             uint256 totalParticles = _particleIds.current();
             uint256 minRequiredVotes = totalParticles.mul(GOVERNANCE_MIN_VOTES_PERCENTAGE).div(100);

             if (totalVotes < minRequiredVotes) {
                 currentState = ProposalState.Failed;
             } else {
                 if (proposal.yesVotes > proposal.noVotes) {
                     currentState = ProposalState.Succeeded;
                 } else {
                     currentState = ProposalState.Failed;
                 }
             }
        }


        return (
            proposal.id,
            proposal.actionType,
            proposal.description,
            proposal.voteStartBlock,
            proposal.voteEndBlock,
            proposal.yesVotes,
            proposal.noVotes,
            currentState // Return calculated state if active and period ended
        );
    }

    /**
     * @dev Gets the voting power of a user.
     * Voting power is based on the number of particles they currently have staked.
     * @param voter The address to check.
     */
    function getVotingPower(address voter) public view returns (uint256) {
        // Voting power is simply the count of staked particles for this user
        return _stakedParticlesByAddress[voter].length;
    }


    // --- Utility ---

    /**
     * @dev See {Ownable-pause}.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev See {Ownable-unpause}.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev See {Pausable-paused}.
     */
    function paused() public view override returns (bool) {
        return super.paused();
    }

    /**
     * @dev Allows the contract owner or governance to withdraw ether balance.
     * @param recipient The address to send the ether to.
     * @param amount The amount of ether to withdraw.
     */
    function withdrawEther(address payable recipient, uint256 amount) public onlyOwnerOrGovernance {
        if (amount == 0) return;
        if (address(this).balance < amount) revert QuantumFluctuations__InsufficientEther();

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert QuantumFluctuations__ExecutionFailed();
    }

    /**
     * @dev Internal helper to check if the caller is the owner or if governance execution is active.
     * Governance execution is simplified here: only the contract itself during executeProposal
     * or the owner can call functions intended for governance.
     */
    modifier onlyOwnerOrGovernance() {
        // This is a simplification. A real DAO would use a contract like Governor
        // that calls back into this contract. Here, we just allow owner or the contract itself.
        // The contract calling itself happens during executeProposal.
        require(msg.sender == owner() || msg.sender == address(this), "Only owner or governance");
        _;
    }
}
```

---

**Explanation of Concepts and Functions:**

1.  **Dynamic State (`currentDimension`):** The contract isn't static; it has a central state variable `_currentDimensionId` representing its "Dimension." This state can change based on a simulated fluctuation mechanism.
2.  **Simulated Quantum Fluctuations:**
    *   `_calculateQuantumNoise`: A private function attempting to generate a pseudo-random value by combining various blockchain parameters and contract state. This is the core of the "fluctuation" concept, mimicking unpredictable change.
    *   `_applyFluctuation`: Uses the calculated noise to potentially transition `_currentDimensionId` to a different dimension based on thresholds.
    *   `triggerFluctuation`: A public function (with a cooldown) that anyone can call to advance the simulation, causing a chance for the dimension to change.
    *   `setFluctuationParameters`: Allows tuning the simulation's behavior (thresholds, factors).
3.  **Dynamic NFTs (`Particle` ERC721):**
    *   Each NFT (`Particle`) has internal, on-chain state beyond standard metadata: `intrinsicEnergy`, `currentAlignment`, `entangledWith`, `isStaked`, `stakeStartTime`, `lastAlignmentChangeBlock`.
    *   `mintParticle`: Creates these NFTs, assigning initial (simulated) random properties like `intrinsicEnergy` and `currentAlignment`. Requires ether, framing it as an "energy contribution."
    *   `tokenURI`: Overridden to include dynamic particle state in the metadata URI, allowing external services (like marketplaces) to potentially display this dynamic data.
    *   `updateParticleAlignment`: An internal helper (callable by governance/internal logic) to change a particle's `currentAlignment`.
    *   `setParticleMetadataURI`: Allows setting the base URI (governance function example).
4.  **Particle Interactions:**
    *   `entangleParticles`: Allows linking two particles owned by the same person. This creates an on-chain relationship (`entangledWith`).
    *   `disentangleParticles`: Breaks the entanglement link.
    *   `triggerEntanglementFluctuation`: A special function that specifically targets an entangled pair, potentially causing *both* particles to change alignment based on a fluctuation event.
5.  **Staking & State-Dependent Yield:**
    *   `stakeParticle`/`unstakeParticle`: Standard staking pattern where the NFT is transferred to the contract.
    *   `calculatePotentialYield`: A view function calculating yield based on how long the particle has been staked *and* whether its `currentAlignment` matches the contract's `_currentDimensionId`, plus bonuses for `intrinsicEnergy` and `entanglement`. This makes staking rewards dynamic and state-dependent.
    *   `claimYield`: Allows claiming the calculated yield, transferring ether to the user and resetting the stake timer.
6.  **User Affinity & Micro-Interactions:**
    *   `_userDimensionAffinity`: Tracks how much a user has interacted with (`observeDimension`) or aligned with (`updateUserDimensionAffinity`) specific dimensions.
    *   `observeDimension`: A simple function a user can call to "observe" the current state. This boosts their affinity for that dimension and (conceptually) provides a tiny input into the next fluctuation calculation (though the implementation here is simplified).
    *   `simulateTunneling`: A creative function allowing a user to attempt to force their staked particle's alignment to a *different* random dimension. It has a simulated probability of success influenced by noise and user affinity.
7.  **Basic Governance:**
    *   A simplified proposal and voting system (`Proposal` struct, `proposeGovernanceAction`, `voteOnProposal`, `executeProposal`).
    *   Voting power (`getVotingPower`) is tied to the number of staked particles.
    *   Governance actions include modifying fluctuation parameters, adding/removing dimensions, or even updating specific particle metadata URIs. The execution logic decodes data to call relevant functions (`setFluctuationParameters`, `_addDimension`, `removeDimension`, `_setTokenURI`).
8.  **Standard ERC721/Enumerable/URIStorage:** Inherited from OpenZeppelin for standard NFT functionality.
9.  **Utility:** Pause/unpause, owner/governance withdrawal.

This contract goes beyond basic token functions by introducing an evolving state, dynamic NFT properties influenced by that state and interactions, a state-dependent yield mechanism, and simulated complex phenomena like entanglement and tunneling, all tied together with a basic governance layer.