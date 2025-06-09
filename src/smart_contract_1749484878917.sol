Okay, here is a Solidity smart contract incorporating advanced concepts, creative mechanics, and a relatively high number of functions, distinct from common open-source examples.

The concept is a protocol governing "Quantum Particles" (NFTs) that have dynamic states influenced by user interactions, external data (simulated oracle), and a governance mechanism. It introduces ideas like entanglement, superposition, fluctuating states, and a utility token ("Resonance Spark") to fuel interactions.

**Disclaimer:** This is a complex conceptual design. Implementing this in a production environment would require extensive security audits, gas optimization, and careful consideration of the on-chain randomness/oracle problem. State transition logic is simplified for demonstration.

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Using interface for Spark token
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- OUTLINE AND FUNCTION SUMMARY ---
/*
Protocol: QuantumFluctuations
Concept: A system managing dynamic NFT "Particles" with fluctuating states, entanglement, superposition, fueled by a "Resonance Spark" token, and governed by Particle holders. States and state transitions can be influenced by simulated external data.

I. Core Assets (Particles - ERC721 based)
    - Represents Quantum Particles, each with dynamic state and resonance.
    - Functions:
        - mintParticle: Create a new particle.
        - transferParticle: Standard ERC721 transfer.
        - getParticleState: Retrieve the current state of a particle.
        - getParticleResonance: Retrieve the current resonance of a particle.
        - getParticleOwner: Retrieve the owner of a particle.
        - getTotalParticles: Get the total number of particles minted.
        - getOwnedParticles: Get list of particle IDs owned by an address (View Helper).
        - updateParticleResonance: Internal function to modify resonance based on interactions.

II. Resonance Spark Token (ERC20 - Minimal Interface)
    - A utility token required for certain interactions (e.g., triggering fluctuations).
    - Functions:
        - mintSpark: Governance function to create Spark tokens (e.g., for distribution, rewards).
        - burnSpark: Function to burn Spark tokens (used for actions).
        - getSparkBalance: Retrieve balance of Spark for an address.
        - transferSpark: Standard ERC20 transfer (assumes a deployed IERC20 contract).

III. Particle Interaction & State Dynamics
    - Mechanisms to change particle states and relationships.
    - Functions:
        - triggerFluctuation: Main function to attempt a particle state change, requires Spark, potentially influenced by external data.
        - observeParticle: A less impactful interaction, might slightly boost resonance or influence future fluctuations.
        - enterSuperposition: Temporarily put a particle into a special, unstable state.
        - exitSuperposition: Resolve a particle from superposition to a new state.
        - getSuperpositionExpiry: Check when a particle's superposition ends.
        - setFluctuationCosts: Governance function to set Spark costs for different fluctuation types.

IV. Entanglement
    - Linking two particles, potentially affecting their interactions or combined state.
    - Functions:
        - requestEntanglement: Propose entanglement between two particles.
        - confirmEntanglement: Confirm an entanglement request.
        - initiateDecoherence: Break an existing entanglement.
        - getEntangledPair: Get the particle ID entangled with a given particle.
        - triggerCatalyticFluctuation: A special fluctuation requiring an entangled pair.
        - getEntangledPairResonance: View the combined resonance of an entangled pair (View Helper).
        - setEntanglementCooldown: Governance function to set cooldowns.

V. Governance
    - Particle holders can propose and vote on changes to protocol parameters and state transition rules.
    - Functions:
        - proposeRuleChange: Submit a proposal to change protocol rules (e.g., state transition probabilities, costs).
        - voteOnProposal: Cast a vote on an active proposal (voting power based on owned particles).
        - executeProposal: Finalize and implement a successful proposal.
        - getProposalDetails: View function for proposal information.
        - getProposalVoteCount: View function for current vote count.
        - delegateVotingPower: Delegate particle voting power to another address.
        - undelegateVotingPower: Undelegate voting power.

VI. Oracle & External Influence (Simulated)
    - Allows simulating influence from external data sources on state changes.
    - Functions:
        - setOracleAddress: Governance function to set the trusted oracle address.
        - receiveOracleData: Function for the oracle to provide data that might influence fluctuations.
        - getLastOracleData: View the last received oracle data.

VII. Admin & Safety
    - Standard administrative functions.
    - Functions:
        - pauseContract: Emergency pause function.
        - unpauseContract: Unpause the contract.
        - setSuperpositionDuration: Governance function to set the duration of superposition.
        - setGovernanceThresholds: Governance function to set proposal/voting thresholds.

Total Functions: 7 (Assets) + 4 (Spark) + 6 (Interaction) + 7 (Entanglement) + 8 (Governance) + 3 (Oracle) + 4 (Admin) = 39 Functions
*/

contract QuantumFluctuations is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // --- STATE VARIABLES ---

    Counters.Counter private _particleIds;

    enum ParticleState {
        Idle,          // Default state
        Excited,       // More reactive state
        Superposition, // Unstable, temporary state
        Entangled,     // Linked state
        Decohered,     // Recently disentangled, less reactive
        Stable         // Less reactive state
        // Add more creative states here
    }

    enum FluctuationType {
        Standard,        // Basic state change attempt
        ObservationBoost,// Boost attempt via observation influence
        Catalytic        // Requires entangled pair
        // Add more fluctuation types
    }

    struct Particle {
        uint256 id;
        ParticleState state;
        uint256 resonance; // Represents potential or influence
        uint64 lastFluctuationBlock; // Cooldown mechanism
        uint64 superpositionExpiryBlock; // Block number when superposition ends
    }

    mapping(uint256 => Particle) private _particles;
    mapping(address => uint256[]) private _ownedParticles; // Helper for getOwnedParticles (can be gas intensive for large collections)
    mapping(address => uint256) private _ownedParticleCount; // More efficient count

    mapping(uint256 => uint256) private _entangledPair; // particleId => entangledParticleId
    mapping(uint256 => uint64) private _entanglementCooldown; // particleId => cooldown end block

    // Oracle simulation
    address public oracleAddress;
    struct OracleData {
        bytes32 dataHash;
        uint256 value;
        uint64 timestamp;
    }
    OracleData public lastOracleData;

    // Resonance Spark Token (using interface for external contract)
    IERC20 public resonanceSparkToken;

    // Governance
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        address proposer;
        string description; // e.g., "Change Idle -> Excited chance"
        bytes data; // Encoded function call data for execution (e.g., updateStateRules param)
        uint64 startBlock;
        uint64 endBlock;
        uint256 yesVotes;
        uint256 noVotes;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    uint256 public minParticlesForProposal; // Minimum particles needed to propose
    uint256 public votingPeriodBlocks; // How long voting lasts
    uint256 public requiredVoteMajorityNumerator; // For calculating majority (e.g., 51)
    uint256 public requiredVoteMajorityDenominator; // (e.g., 100)

    mapping(address => address) public votingDelegates; // Delegated voting power

    // Rule Configuration (Governance controlled)
    mapping(FluctuationType => uint256) public fluctuationCosts; // Spark cost for fluctuations
    uint64 public particleFluctuationCooldown; // Blocks between fluctuations for a single particle
    uint64 public entanglementInitiationCooldown; // Blocks after decoherence/entanglement before initiating new one
    uint64 public superpositionDurationBlocks; // How long superposition lasts

    // Simplified State Transition Rules (Governance sets costs/cooldowns, logic is in triggerFluctuation)
    // A more complex contract would have data structures here governing specific transitions/probabilities based on state, type, and oracle data.

    bool private _paused;

    // --- EVENTS ---
    event ParticleMinted(uint256 indexed particleId, address indexed owner, ParticleState initialState);
    event ParticleStateChanged(uint256 indexed particleId, ParticleState indexed oldState, ParticleState indexed newState, FluctuationType indexed fluctuationType);
    event ParticleResonanceChanged(uint256 indexed particleId, uint256 oldResonance, uint256 newResonance);
    event ParticlesEntangled(uint256 indexed particle1Id, uint256 indexed particle2Id);
    event ParticlesDecohered(uint256 indexed particle1Id, uint256 indexed particle2Id);
    event EnteredSuperposition(uint256 indexed particleId, uint64 expiryBlock);
    event ExitedSuperposition(uint256 indexed particleId, ParticleState indexed newState);
    event FluctuationTriggered(uint256 indexed particleId, FluctuationType indexed fluctuationType, bytes32 externalDataHash, uint256 cost);
    event CatalyticFluctuationTriggered(uint256 indexed particle1Id, uint256 indexed particle2Id, FluctuationType indexed catalyticType, bytes32 externalDataHash, uint256 cost);
    event OracleDataReceived(bytes32 indexed dataHash, uint256 value, uint64 timestamp);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint64 startBlock, uint64 endBlock);
    event Voted(uint256 indexed proposalId, address indexed voter, bool voteSupport, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId);
    event VotingDelegated(address indexed delegator, address indexed delegatee);

    // --- ERRORS ---
    error InvalidParticleId();
    error NotParticleOwner();
    error ParticleAlreadyExists();
    error InsufficientSpark();
    error ParticleOnCooldown();
    error ParticleNotInState(ParticleState requiredState);
    error ParticleInState(ParticleState excludedState);
    error ParticlesNotEntangled();
    error ParticlesAlreadyEntangled();
    error EntanglementCooldownActive();
    error EntanglementRequestPending();
    error NoEntanglementRequest();
    error NotEntanglementRequester();
    error CannotEntangleSelf();
    error SuperpositionExpiredOrNotActive();
    error InvalidFluctuationType();
    error OracleAddressNotSet();
    error CallerNotOracle();
    error ProposalDoesNotExist();
    error ProposalNotActive();
    error ProposalNotSucceeded();
    error ProposalAlreadyExecuted();
    error AlreadyVoted();
    error InsufficientParticlesForProposal(uint256 required, uint256 has);
    error VotingPeriodNotEnded();
    error VotingPeriodNotStarted();
    error CannotDelegateToSelf();
    error ContractPaused();

    // --- MODIFIERS ---
    modifier whenNotPaused() {
        if (_paused) revert ContractPaused();
        _;
    }

    modifier onlyGovernance() {
        // In a real DAO, this would check if the caller holds enough governance power (e.g., particles) or is the result of an executed proposal.
        // For this example, we'll simplify: onlyOwner can execute governance functions directly, or they are called by executeProposal.
        // A more complex system would check if the caller is the contract itself calling after executeProposal or is a whitelisted governance contract.
        require(msg.sender == owner() || _isExecutingProposal(), "QF: Caller not governance or owner");
        _;
    }

    // Helper to simulate if the caller is the contract executing a proposal
    bool private _executingProposal = false;
    modifier isExecutingProposal() {
        _executingProposal = true;
        _;
        _executingProposal = false;
    }

    function _isExecutingProposal() internal view returns (bool) {
         return _executingProposal;
    }

    // --- CONSTRUCTOR ---
    constructor(address _resonanceSparkTokenAddress) ERC721("QuantumParticle", "QPART") Ownable(msg.sender) {
        resonanceSparkToken = IERC20(_resonanceSparkTokenAddress);
        _paused = false; // Start unpaused

        // Set some initial governance parameters (can be changed by governance later)
        minParticlesForProposal = 1; // Low for testing
        votingPeriodBlocks = 100; // Short for testing
        requiredVoteMajorityNumerator = 51; // 51% majority
        requiredVoteMajorityDenominator = 100;

        // Set initial fluctuation costs (can be changed by governance)
        fluctuationCosts[FluctuationType.Standard] = 10 * (10**18); // Example cost (assuming 18 decimals)
        fluctuationCosts[FluctuationType.ObservationBoost] = 5 * (10**18);
        fluctuationCosts[FluctuationType.Catalytic] = 25 * (10**18);

        // Set initial cooldowns/durations
        particleFluctuationCooldown = 20; // Blocks
        entanglementInitiationCooldown = 50; // Blocks
        superpositionDurationBlocks = 30; // Blocks
    }

    // --- CORE ASSETS (Particles) ---

    /**
     * @notice Mints a new Quantum Particle NFT. Only callable by the owner initially,
     *         can be changed by governance to allow public minting or other mechanisms.
     * @param to The address to mint the particle to.
     * @param initialState The initial state of the particle.
     * @param initialResonance The initial resonance value.
     */
    function mintParticle(address to, ParticleState initialState, uint256 initialResonance) external onlyOwner whenNotPaused {
        uint256 newTokenId = _particleIds.current();
        _particleIds.increment();

        _particles[newTokenId] = Particle({
            id: newTokenId,
            state: initialState,
            resonance: initialResonance,
            lastFluctuationBlock: 0,
            superpositionExpiryBlock: 0
        });

        _safeMint(to, newTokenId);
        _ownedParticles[to].push(newTokenId); // Helper update
        _ownedParticleCount[to]++;

        emit ParticleMinted(newTokenId, to, initialState);
    }

    /**
     * @notice Transfers a Quantum Particle NFT. Standard ERC721 transfer logic.
     * @param from The current owner.
     * @param to The recipient.
     * @param tokenId The ID of the particle.
     */
    function transferParticle(address from, address to, uint256 tokenId) external whenNotPaused {
        require(_exists(tokenId), InvalidParticleId());
        require(msg.sender == _ownerOf(tokenId) || isApprovedForAll(from, msg.sender) || getApproved(tokenId) == msg.sender, "QF: Transfer caller is not owner nor approved");

        // Manually update helper mapping before standard transfer hooks
        _removeTokenFromOwnedList(from, tokenId);
        _ownedParticleCount[from]--;

        _safeTransfer(from, to, tokenId);

        _ownedParticles[to].push(tokenId); // Helper update
        _ownedParticleCount[to]++;
    }

    // Internal helper for managing the _ownedParticles array
    function _removeTokenFromOwnedList(address owner, uint256 tokenId) internal {
        uint256[] storage ownedList = _ownedParticles[owner];
        for (uint i = 0; i < ownedList.length; i++) {
            if (ownedList[i] == tokenId) {
                ownedList[i] = ownedList[ownedList.length - 1];
                ownedList.pop();
                return;
            }
        }
        // Should not happen if _ownedParticles is kept in sync
    }


    /**
     * @notice Gets the current state of a particle.
     * @param particleId The ID of the particle.
     * @return The current ParticleState.
     */
    function getParticleState(uint256 particleId) public view returns (ParticleState) {
        require(_exists(particleId), InvalidParticleId());
        return _particles[particleId].state;
    }

     /**
     * @notice Gets the current resonance of a particle.
     * @param particleId The ID of the particle.
     * @return The current resonance value.
     */
    function getParticleResonance(uint256 particleId) public view returns (uint256) {
        require(_exists(particleId), InvalidParticleId());
        return _particles[particleId].resonance;
    }

     /**
     * @notice Gets the owner of a particle.
     * @param particleId The ID of the particle.
     * @return The owner address.
     */
    function getParticleOwner(uint256 particleId) public view returns (address) {
        require(_exists(particleId), InvalidParticleId());
        return ownerOf(particleId); // Uses ERC721's ownerOf
    }

    /**
     * @notice Gets the total number of particles minted.
     * @return The total count.
     */
    function getTotalParticles() public view returns (uint256) {
        return _particleIds.current();
    }

     /**
     * @notice Gets the list of particle IDs owned by an address.
     * @param owner The address to query.
     * @return An array of particle IDs.
     */
    function getOwnedParticles(address owner) public view returns (uint256[] memory) {
        return _ownedParticles[owner];
    }

    /**
     * @notice Internal function to update a particle's resonance.
     * @param particleId The ID of the particle.
     * @param newResonance The new resonance value.
     */
    function _updateParticleResonance(uint256 particleId, uint256 newResonance) internal {
        uint256 oldResonance = _particles[particleId].resonance;
        _particles[particleId].resonance = newResonance;
        emit ParticleResonanceChanged(particleId, oldResonance, newResonance);
    }

    // --- RESONANCE SPARK TOKEN ---

    /**
     * @notice Mints Resonance Spark tokens. Controlled by governance.
     * @param to The address to mint to.
     * @param amount The amount of tokens to mint.
     */
    function mintSpark(address to, uint256 amount) external onlyGovernance whenNotPaused {
        // Assumes the Resonance Spark contract has a mint function callable by this contract
        // In a real scenario, the Spark contract would need to grant minter role to this contract.
        // Example: IERC20(resonanceSparkToken).mint(to, amount); // This syntax might vary based on token standard
        // For this example, we'll assume the ERC20 interface has a 'mint' function this contract is approved to call.
        // A more realistic approach might involve a custom token contract or managing balances internally.
        // Placeholder: Log the action as if minting happened externally.
        emit OracleDataReceived(bytes32(uint256(1)), amount, uint64(block.timestamp)); // Re-using event for simplicity, ideally have a SparkMinted event
    }

    /**
     * @notice Burns Resonance Spark tokens.
     * @param amount The amount of tokens to burn.
     */
    function burnSpark(uint256 amount) internal {
        // Assumes the Resonance Spark contract has a burnFrom function or user has approved this contract
        // to spend and this contract calls transferFrom to 'burn' (send to 0x0).
        // Simplification: require user approves this contract, then this contract transfersFrom to 0x0
        require(resonanceSparkToken.transferFrom(msg.sender, address(0x0), amount), "QF: Spark burn failed");
    }

     /**
     * @notice Gets the balance of Resonance Spark for an address.
     * @param holder The address to query.
     * @return The balance of Spark tokens.
     */
    function getSparkBalance(address holder) public view returns (uint256) {
        return resonanceSparkToken.balanceOf(holder);
    }

    /**
     * @notice Transfers Resonance Spark tokens. Standard ERC20 transfer.
     *         Included here for completeness but logic resides in the Spark contract.
     * @param to The recipient.
     * @param amount The amount.
     * @return bool success.
     */
    function transferSpark(address to, uint256 amount) external returns (bool) {
        // This just proxies the call to the Spark token contract
        return resonanceSparkToken.transfer(to, amount);
    }


    // --- PARTICLE INTERACTION & STATE DYNAMICS ---

    /**
     * @notice Attempts to trigger a state fluctuation for a particle.
     *         Requires Resonance Spark and respects cooldowns. Outcome is influenced by type and external data.
     * @param particleId The ID of the particle.
     * @param fluctuationType The type of fluctuation to attempt.
     * @param externalDataHash A hash representing external data (e.g., from an oracle) influencing the outcome.
     */
    function triggerFluctuation(uint256 particleId, FluctuationType fluctuationType, bytes32 externalDataHash) external payable whenNotPaused nonReentrant {
        require(_exists(particleId), InvalidParticleId());
        require(ownerOf(particleId) == msg.sender, NotParticleOwner());
        require(block.number > _particles[particleId].lastFluctuationBlock + particleFluctuationCooldown, ParticleOnCooldown());
        require(fluctuationCosts[fluctuationType] > 0, InvalidFluctuationType()); // Ensure type is configured
        require(getSparkBalance(msg.sender) >= fluctuationCosts[fluctuationType], InsufficientSpark());

        Particle storage particle = _particles[particleId];
        ParticleState oldState = particle.state;
        ParticleState newState = oldState; // Default: no change

        // Consume Spark
        burnSpark(fluctuationCosts[fluctuationType]);

        // --- SIMPLIFIED STATE TRANSITION LOGIC ---
        // This is the core, complex part. In a real system, this would use:
        // 1. Particle's current state, resonance, history.
        // 2. Fluctuation type.
        // 3. External data (oracle data value based on externalDataHash).
        // 4. Potentially on-chain randomness (like Chainlink VRF).
        // 5. Configurable rules set by governance.

        // Example simplified logic:
        // - Superposition particles always try to exit.
        // - Certain types strongly push towards specific states.
        // - External dataHash (or oracle data value) might influence probability or outcome.
        // - Resonance might increase/decrease based on success/failure or state.

        uint256 oracleInfluence = lastOracleData.dataHash == externalDataHash ? lastOracleData.value : uint256(externalDataHash); // Use provided hash or last oracle data

        if (particle.state == ParticleState.Superposition) {
            // Superposition decay
            if (block.number >= particle.superpositionExpiryBlock || fluctuationType != FluctuationType.Standard) {
                 // Resolve superposition based on external data/resonance/type
                 if ((oracleInfluence + particle.resonance) % 2 == 0) {
                     newState = ParticleState.Excited;
                 } else {
                     newState = ParticleState.Stable;
                 }
                 particle.superpositionExpiryBlock = 0; // Exit superposition
            } else {
                 // Still in superposition, maybe resonance changes?
                 _updateParticleResonance(particleId, particle.resonance + 1); // Small resonance boost
            }
        } else {
            // Standard state transition attempt
            if (fluctuationType == FluctuationType.Standard) {
                 if (oracleInfluence % 3 == 0) newState = ParticleState.Excited;
                 else if (oracleInfluence % 3 == 1) newState = ParticleState.Stable;
                 // Otherwise stays the same
            } else if (fluctuationType == FluctuationType.ObservationBoost) {
                 // Observation boost makes it more likely to become Excited
                 if ((oracleInfluence + particle.resonance) % 2 == 0) newState = ParticleState.Excited;
            }
            // Catalytic handled in its own function
        }

        // Ensure Entangled particles don't change state via Standard/ObservationBoost? Or maybe they can?
        // Let's say Entangled particles *can* fluctuate individually, but catalytic is special.
         if (oldState == ParticleState.Entangled && newState != ParticleState.Entangled) {
            // Entangled particles cannot leave Entangled state via standard fluctuation
             newState = oldState;
             // Maybe reduce resonance for 'failed' attempt?
             _updateParticleResonance(particleId, particle.resonance > 0 ? particle.resonance - 1 : 0);
         }


        if (newState != oldState) {
            particle.state = newState;
            // Resonance change based on successful transition?
             _updateParticleResonance(particleId, particle.resonance + 5); // Example boost
             emit ParticleStateChanged(particleId, oldState, newState, fluctuationType);
        } else {
             // Resonance change on failed transition?
            _updateParticleResonance(particleId, particle.resonance > 0 ? particle.resonance - 1 : 0); // Example reduction
        }

        particle.lastFluctuationBlock = uint64(block.number); // Update cooldown
        emit FluctuationTriggered(particleId, fluctuationType, externalDataHash, fluctuationCosts[fluctuationType]);
    }

    /**
     * @notice Allows a user to 'observe' a particle. Less resource intensive, subtle effects.
     *         Might grant a small resonance boost or influence future fluctuations slightly.
     * @param particleId The ID of the particle.
     */
    function observeParticle(uint256 particleId) external whenNotPaused {
         require(_exists(particleId), InvalidParticleId());
         // Cost zero Spark? Or a very small amount? Let's make it free but have a minor cooldown/limit
         // For simplicity, no cost and no cooldown in this example.
         // Effects: Small resonance boost. Could store last observer.

         Particle storage particle = _particles[particleId];
         _updateParticleResonance(particleId, particle.resonance + 1); // Small boost
         // Could emit an event: emit ParticleObserved(particleId, msg.sender);
    }

    /**
     * @notice Puts a particle into the temporary Superposition state.
     * @param particleId The ID of the particle.
     */
    function enterSuperposition(uint256 particleId) external whenNotPaused {
         require(_exists(particleId), InvalidParticleId());
         require(ownerOf(particleId) == msg.sender, NotParticleOwner());
         require(_particles[particleId].state != ParticleState.Superposition, ParticleInState(ParticleState.Superposition));
         require(_particles[particleId].state != ParticleState.Entangled, ParticleInState(ParticleState.Entangled)); // Cannot enter superposition if entangled
         // Could require Spark cost or other conditions here

         Particle storage particle = _particles[particleId];
         ParticleState oldState = particle.state;
         particle.state = ParticleState.Superposition;
         particle.superpositionExpiryBlock = uint64(block.number + superpositionDurationBlocks);

         emit ParticleStateChanged(particleId, oldState, ParticleState.Superposition, FluctuationType.Standard); // Use Standard type for state change event? Or add SuperpositionEnter type?
         emit EnteredSuperposition(particleId, particle.superpositionExpiryBlock);
    }

    /**
     * @notice Attempts to exit a particle from the Superposition state.
     *         Can be called by anyone, or triggered by time. Outcome is state-dependent.
     * @param particleId The ID of the particle.
     * @param externalDataHash A hash representing external data (optional, might influence outcome).
     */
    function exitSuperposition(uint256 particleId, bytes32 externalDataHash) external whenNotPaused nonReentrant {
         require(_exists(particleId), InvalidParticleId());
         Particle storage particle = _particles[particleId];
         require(particle.state == ParticleState.Superposition, ParticleNotInState(ParticleState.Superposition));
         // Anyone can trigger exit, especially if expired
         // Require ownership only if exiting early before expiry? Let's allow anyone to finalize expired superposition.

         // Only allow early exit if owner calls? Or if specific conditions met?
         // For simplicity, require expiry or owner call + cost? Let's require expiry OR owner call.
         bool isOwnerCall = ownerOf(particleId) == msg.sender;
         require(block.number >= particle.superpositionExpiryBlock || isOwnerCall, SuperpositionExpiredOrNotActive());
         // Could require Spark cost for early exit

         ParticleState oldState = ParticleState.Superposition;
         ParticleState newState;

         // Determine new state (simplified logic)
         uint256 oracleInfluence = lastOracleData.dataHash == externalDataHash ? lastOracleData.value : uint256(externalDataHash);
         if ((oracleInfluence + particle.resonance) % 2 == 0) {
            newState = ParticleState.Excited;
         } else {
            newState = ParticleState.Stable;
         }

         particle.state = newState;
         particle.superpositionExpiryBlock = 0; // Exit superposition

         _updateParticleResonance(particleId, particle.resonance + 10); // Significant boost for resolving
         emit ParticleStateChanged(particleId, oldState, newState, FluctuationType.Standard); // Again, simple type for event
         emit ExitedSuperposition(particleId, newState);
    }

    /**
     * @notice Checks the block number when a particle's superposition state will expire.
     * @param particleId The ID of the particle.
     * @return The block number of expiry, or 0 if not in superposition.
     */
    function getSuperpositionExpiry(uint256 particleId) public view returns (uint64) {
        require(_exists(particleId), InvalidParticleId());
        return _particles[particleId].superpositionExpiryBlock;
    }

    /**
     * @notice Governance function to set Spark costs for different fluctuation types.
     * @param fluctuationType The type to configure.
     * @param cost The new cost in Spark tokens.
     */
    function setFluctuationCosts(FluctuationType fluctuationType, uint256 cost) external onlyGovernance whenNotPaused {
        fluctuationCosts[fluctuationType] = cost;
        // Could emit event
    }

    // --- ENTANGLEMENT ---

    /**
     * @notice Requests entanglement between two particles. Requires ownership of particle1.
     *         Requires confirmation from the owner of particle2.
     * @param particle1Id The ID of the particle initiating the request (owned by msg.sender).
     * @param particle2Id The ID of the particle to request entanglement with.
     */
    function requestEntanglement(uint256 particle1Id, uint256 particle2Id) external whenNotPaused {
        require(_exists(particle1Id), InvalidParticleId());
        require(_exists(particle2Id), InvalidParticleId());
        require(ownerOf(particle1Id) == msg.sender, NotParticleOwner());
        require(particle1Id != particle2Id, CannotEntangleSelf());
        require(_entangledPair[particle1Id] == 0 && _entangledPair[particle2Id] == 0, ParticlesAlreadyEntangled());
        require(block.number > _entanglementCooldown[particle1Id] && block.number > _entanglementCooldown[particle2Id], EntanglementCooldownActive());
        require(_particles[particle1Id].state != ParticleState.Superposition && _particles[particle2Id].state != ParticleState.Superposition, ParticleInState(ParticleState.Superposition));

        // Use a mapping to store pending requests: particle1Id => particle2Id
        // Check if particle1 already requested, or particle2 is already requested by someone else
        // Let's use a simple mapping for pending requests: mapping(uint256 => uint256) pendingEntanglementRequests;
        // pendingEntanglementRequests[particle1Id] = particle2Id; // Simpler, but doesn't prevent A->B and C->B requests.
        // Better: mapping(uint256 => mapping(uint256 => bool)) pendingEntanglements; // particle1 => particle2 => exists?
        // And mapping(uint256 => uint256) requestedBy; // particleId being requested => particleId doing the requesting

         // Check if particle1 is requesting something else, or if particle2 is being requested by someone else
        require(_entangledPair[particle1Id] == 0, "QF: Particle 1 already involved in request/entanglement");
        require(_entangledPair[particle2Id] == 0, "QF: Particle 2 already involved in request/entanglement"); // Re-using _entangledPair for pending requests state

        // Store the request using _entangledPair mapping temporarily, maybe signify pending with a special value or separate mapping
        // Let's use _entangledPair, but check if *both* sides confirm for actual entanglement.
        // Simpler approach for example: particle1Id requests particle2Id. Store request: mapping(uint256 => uint256) pendingRequests; particle1Id => particle2Id.
        // Check if particle1Id *has* a pending request or is *the target* of one.
        mapping(uint256 => uint256) pendingEntanglementRequests; // particle1 requesting => particle2 being requested
        mapping(uint256 => uint256) requestedBy; // particle2 being requested => particle1 requesting

        require(pendingEntanglementRequests[particle1Id] == 0 && requestedBy[particle1Id] == 0, "QF: Particle 1 already involved in request");
        require(pendingEntanglementRequests[particle2Id] == 0 && requestedBy[particle2Id] == 0, "QF: Particle 2 already involved in request");

        pendingEntanglementRequests[particle1Id] = particle2Id;
        requestedBy[particle2Id] = particle1Id;

        // Could emit an event: emit EntanglementRequested(particle1Id, particle2Id, ownerOf(particle2Id));
    }

    /**
     * @notice Confirms an entanglement request. Callable by the owner of particle2.
     * @param particle1Id The ID of the particle that initiated the request.
     * @param particle2Id The ID of the particle confirming the request (owned by msg.sender).
     */
    function confirmEntanglement(uint256 particle1Id, uint256 particle2Id) external whenNotPaused nonReentrant {
        require(_exists(particle1Id), InvalidParticleId());
        require(_exists(particle2Id), InvalidParticleId());
        require(ownerOf(particle2Id) == msg.sender, NotParticleOwner());
        require(particle1Id != particle2Id, CannotEntangleSelf());

        // Check if there's a pending request from particle1Id to particle2Id
        mapping(uint256 => uint256) pendingEntanglementRequests; // Copy from requestEntanglement logic
        mapping(uint256 => uint256) requestedBy;

        require(pendingEntanglementRequests[particle1Id] == particle2Id, NoEntanglementRequest());
        require(_entangledPair[particle1Id] == 0 && _entangledPair[particle2Id] == 0, ParticlesAlreadyEntangled()); // Double check no existing entanglement

        // --- Perform Entanglement ---
        _entangledPair[particle1Id] = particle2Id;
        _entangledPair[particle2Id] = particle1Id; // Symmetric link

        // Remove pending requests
        delete pendingEntanglementRequests[particle1Id];
        delete requestedBy[particle2Id];

        // Update states (optional, could automatically go to Entangled state)
        // Let's make entanglement put them into the Entangled state.
        ParticleState oldState1 = _particles[particle1Id].state;
        ParticleState oldState2 = _particles[particle2Id].state;
        _particles[particle1Id].state = ParticleState.Entangled;
        _particles[particle2Id].state = ParticleState.Entangled;

        // Apply cooldowns
        _entanglementCooldown[particle1Id] = uint64(block.number + entanglementInitiationCooldown);
        _entanglementCooldown[particle2Id] = uint64(block.number + entanglementInitiationCooldown);

        emit ParticleStateChanged(particle1Id, oldState1, ParticleState.Entangled, FluctuationType.Standard); // Use standard type
        emit ParticleStateChanged(particle2Id, oldState2, ParticleState.Entangled, FluctuationType.Standard);
        emit ParticlesEntangled(particle1Id, particle2Id);
    }

    /**
     * @notice Initiates decoherence (breaks entanglement) between two particles. Callable by either owner.
     * @param particleId The ID of one of the entangled particles.
     */
    function initiateDecoherence(uint256 particleId) external whenNotPaused nonReentrant {
         require(_exists(particleId), InvalidParticleId());
         require(ownerOf(particleId) == msg.sender, NotParticleOwner());

         uint256 entangledPartnerId = _entangledPair[particleId];
         require(entangledPartnerId != 0, ParticlesNotEntangled());
         require(_entangledPair[entangledPartnerId] == particleId, ParticlesNotEntangled()); // Consistency check

         // --- Perform Decoherence ---
         delete _entangledPair[particleId];
         delete _entangledPair[entangledPartnerId];

         // Update states (optional, could go to Decohered state)
         // Let's make decoherence put them into the Decohered state.
         ParticleState oldState1 = _particles[particleId].state;
         ParticleState oldState2 = _particles[entangledPartnerId].state;
         _particles[particleId].state = ParticleState.Decohered;
         _particles[entangledPartnerId].state = ParticleState.Decohered;

         // Apply cooldowns (can't re-entangle immediately)
         _entanglementCooldown[particleId] = uint64(block.number + entanglementInitiationCooldown);
         _entanglementCooldown[entangledPartnerId] = uint64(block.number + entanglementInitiationCooldown);


         emit ParticleStateChanged(particleId, oldState1, ParticleState.Decohered, FluctuationType.Standard); // Use standard type
         emit ParticleStateChanged(entangledPartnerId, oldState2, ParticleState.Decohered, FluctuationType.Standard);
         emit ParticlesDecohered(particleId, entangledPartnerId);
    }

    /**
     * @notice Gets the particle ID that a given particle is entangled with.
     * @param particleId The ID of the particle.
     * @return The entangled particle ID, or 0 if not entangled.
     */
    function getEntangledPair(uint256 particleId) public view returns (uint256) {
         require(_exists(particleId), InvalidParticleId());
         return _entangledPair[particleId];
    }

     /**
     * @notice Triggers a special 'Catalytic' fluctuation that requires an entangled pair.
     *         Might have unique outcomes or effects on both particles.
     * @param particle1Id The ID of one of the entangled particles (owned by msg.sender).
     * @param particle2Id The ID of the other entangled particle.
     * @param catalyticType Specific subtype of catalytic fluctuation.
     * @param externalDataHash External data influencing the outcome.
     */
    function triggerCatalyticFluctuation(uint256 particle1Id, uint256 particle2Id, uint8 catalyticType, bytes32 externalDataHash) external payable whenNotPaused nonReentrant {
         require(_exists(particle1Id), InvalidParticleId());
         require(_exists(particle2Id), InvalidParticleId());
         require(ownerOf(particle1Id) == msg.sender, NotParticleOwner());
         require(_entangledPair[particle1Id] == particle2Id && _entangledPair[particle2Id] == particle1Id, ParticlesNotEntangled()); // Verify entanglement
         require(block.number > _particles[particle1Id].lastFluctuationBlock + particleFluctuationCooldown &&
                 block.number > _particles[particle2Id].lastFluctuationBlock + particleFluctuationCooldown, ParticleOnCooldown()); // Both must be off cooldown
         require(fluctuationCosts[FluctuationType.Catalytic] > 0, InvalidFluctuationType()); // Ensure cost is set
         require(getSparkBalance(msg.sender) >= fluctuationCosts[FluctuationType.Catalytic], InsufficientSpark());
         // catalyticType could influence specific logic branches within the function

         Particle storage particle1 = _particles[particle1Id];
         Particle storage particle2 = _particles[particle2Id];
         ParticleState oldState1 = particle1.state; // Should be Entangled
         ParticleState oldState2 = particle2.state; // Should be Entangled

         // Consume Spark
         burnSpark(fluctuationCosts[FluctuationType.Catalytic]);

         // --- SIMPLIFIED CATALYTIC LOGIC ---
         // Combine resonance? Influence states of *both* particles? Chance to decohere? Chance to create new particle?

         uint256 combinedResonance = particle1.resonance + particle2.resonance;
         uint256 oracleInfluence = lastOracleData.dataHash == externalDataHash ? lastOracleData.value : uint256(externalDataHash);

         // Example: high combined resonance + favorable external data -> resonance boost or chance of special event
         // Low resonance + unfavorable data -> resonance loss or chance of forced decoherence
         // Catalytic type can steer the outcome

         bool success = false;
         if (catalyticType == 1) { // Example type: Resonance Amplification
             if ((combinedResonance + oracleInfluence) % 5 < 3) { // 60% chance based on values
                 uint256 boost = (combinedResonance / 10) + 1;
                 _updateParticleResonance(particle1Id, particle1.resonance + boost);
                 _updateParticleResonance(particle2Id, particle2.resonance + boost);
                 success = true;
             } else {
                  // Failure: slight resonance loss
                 _updateParticleResonance(particle1Id, particle1.resonance > 0 ? particle1.resonance - 1 : 0);
                 _updateParticleResonance(particle2Id, particle2.resonance > 0 ? particle2.resonance - 1 : 0);
             }
         } else { // Default or other types: Maybe minor state changes
            // No state change from Entangled state here, just resonance/side effects
             if (oracleInfluence % 2 == 0) {
                 _updateParticleResonance(particle1Id, particle1.resonance + 2);
                 _updateParticleResonance(particle2Id, particle2.resonance + 2);
                 success = true;
             }
         }


         // Catalytic fluctuation could also have a chance to *force* decoherence or even create a new particle (very complex).
         // For simplicity, just resonance change and no state change from Entangled state here.

         particle1.lastFluctuationBlock = uint64(block.number);
         particle2.lastFluctuationBlock = uint64(block.number);

         emit CatalyticFluctuationTriggered(particle1Id, particle2Id, catalyticType, externalDataHash, fluctuationCosts[FluctuationType.Catalytic]);
         // No StateChanged events unless state actually changes (e.g., forcibly decohered)
    }

    /**
     * @notice Gets the combined resonance of an entangled pair.
     * @param particleId The ID of one of the entangled particles.
     * @return The sum of resonance values.
     */
    function getEntangledPairResonance(uint256 particleId) public view returns (uint256) {
        require(_exists(particleId), InvalidParticleId());
        uint256 entangledPartnerId = _entangledPair[particleId];
        require(entangledPartnerId != 0, ParticlesNotEntangled());
        return _particles[particleId].resonance + _particles[entangledPartnerId].resonance;
    }

     /**
     * @notice Governance function to set the cooldown duration for entanglement initiation.
     * @param blocks The cooldown in blocks.
     */
    function setEntanglementCooldown(uint64 blocks) external onlyGovernance whenNotPaused {
        entanglementInitiationCooldown = blocks;
        // Could emit event
    }


    // --- GOVERNANCE ---

    /**
     * @notice Proposes a change to the protocol rules. Requires minimum particles.
     * @param description A description of the proposal.
     * @param data The encoded function call data to be executed if the proposal passes.
     */
    function proposeRuleChange(string calldata description, bytes calldata data) external whenNotPaused {
         // Voting power for proposal creation based on current owned particles
         require(_ownedParticleCount[msg.sender] >= minParticlesForProposal, InsufficientParticlesForProposal(minParticlesForProposal, _ownedParticleCount[msg.sender]));

         uint256 proposalId = _proposalIds.current();
         _proposalIds.increment();

         proposals[proposalId] = Proposal({
             proposer: msg.sender,
             description: description,
             data: data,
             startBlock: uint64(block.number),
             endBlock: uint64(block.number + votingPeriodBlocks),
             yesVotes: 0,
             noVotes: 0,
             state: ProposalState.Active
         });

         emit ProposalCreated(proposalId, msg.sender, uint64(block.number), uint64(block.number + votingPeriodBlocks));
    }

    /**
     * @notice Casts a vote on an active proposal. Voting power based on particles or delegation.
     * @param proposalId The ID of the proposal.
     * @param voteSupport True for Yes, False for No.
     */
    function voteOnProposal(uint256 proposalId, bool voteSupport) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.proposer != address(0), ProposalDoesNotExist());
        require(proposal.state == ProposalState.Active, ProposalNotActive());
        require(block.number >= proposal.startBlock && block.number < proposal.endBlock, VotingPeriodNotActive());

        address voter = msg.sender;
        address delegate = votingDelegates[voter];
        address voteAccount = delegate == address(0) ? voter : delegate; // Use delegate if set, otherwise caller

        require(!proposal.hasVoted[voteAccount], AlreadyVoted());

        // Voting power based on owned particles at the time of voting
        uint256 voteWeight = _ownedParticleCount[voteAccount];
        require(voteWeight > 0, "QF: No voting power");

        if (voteSupport) {
            proposal.yesVotes += voteWeight;
        } else {
            proposal.noVotes += voteWeight;
        }

        proposal.hasVoted[voteAccount] = true;

        emit Voted(proposalId, voter, voteSupport, voteWeight);
    }

     /**
     * @notice Executes a proposal that has succeeded after the voting period ends.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) external whenNotPaused nonReentrant {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.proposer != address(0), ProposalDoesNotExist());
         require(proposal.state != ProposalState.Executed, ProposalAlreadyExecuted());
         require(block.number >= proposal.endBlock, VotingPeriodNotEnded()); // Voting period must be over

         // Check if proposal succeeded
         if ((proposal.yesVotes * requiredVoteMajorityDenominator) > (proposal.noVotes + proposal.yesVotes) * requiredVoteMajorityNumerator && proposal.yesVotes > 0) {
             proposal.state = ProposalState.Succeeded; // Mark as succeeded before execution
             // Execute the proposal data
             (bool success, bytes memory result) = address(this).call(proposal.data);
             require(success, string(abi.encodePacked("QF: Proposal execution failed: ", result)));
             proposal.state = ProposalState.Executed; // Mark as executed

             emit ProposalExecuted(proposalId);
         } else {
             proposal.state = ProposalState.Failed;
             // Could emit an event for failure
         }
     }


    /**
     * @notice Gets the details of a proposal.
     * @param proposalId The ID of the proposal.
     * @return struct Proposal details.
     */
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
        require(proposals[proposalId].proposer != address(0), ProposalDoesNotExist());
        return proposals[proposalId];
    }

     /**
     * @notice Gets the current vote count for a proposal.
     * @param proposalId The ID of the proposal.
     * @return uint256 yesVotes, uint256 noVotes.
     */
    function getProposalVoteCount(uint256 proposalId) public view returns (uint256 yesVotes, uint256 noVotes) {
        require(proposals[proposalId].proposer != address(0), ProposalDoesNotExist());
        return (proposals[proposalId].yesVotes, proposals[proposalId].noVotes);
    }


     /**
     * @notice Delegates voting power for governance proposals.
     * @param delegatee The address to delegate voting power to. Address(0) to undelegate.
     */
    function delegateVotingPower(address delegatee) external whenNotPaused {
        require(delegatee != msg.sender, CannotDelegateToSelf());
        votingDelegates[msg.sender] = delegatee;
        emit VotingDelegated(msg.sender, delegatee);
    }

    /**
     * @notice Undelegates voting power.
     */
    function undelegateVotingPower() external whenNotPaused {
         require(votingDelegates[msg.sender] != address(0), "QF: No delegation active");
         delete votingDelegates[msg.sender];
         emit VotingDelegated(msg.sender, address(0));
    }

     /**
     * @notice Governance function to set the minimum number of particles required to create a proposal.
     * @param count The minimum particle count.
     */
    function setMinParticlesForProposal(uint256 count) external onlyGovernance whenNotPaused {
        minParticlesForProposal = count;
        // Could emit event
    }

     /**
     * @notice Governance function to set the voting period duration in blocks.
     * @param blocks The voting period in blocks.
     */
    function setVotingPeriodBlocks(uint256 blocks) external onlyGovernance whenNotPaused {
        require(blocks > 0, "QF: Voting period must be > 0");
        votingPeriodBlocks = blocks;
         // Could emit event
    }

     /**
     * @notice Governance function to set the required majority for a proposal to succeed.
     * @param numerator The numerator (e.g., 51 for 51%).
     * @param denominator The denominator (e.g., 100 for 51%).
     */
    function setGovernanceThresholds(uint256 numerator, uint256 denominator) external onlyGovernance whenNotPaused {
        require(denominator > 0, "QF: Denominator must be > 0");
        require(numerator <= denominator, "QF: Numerator cannot exceed denominator");
        requiredVoteMajorityNumerator = numerator;
        requiredVoteMajorityDenominator = denominator;
         // Could emit event
    }


    // --- ORACLE & EXTERNAL INFLUENCE ---

    /**
     * @notice Governance function to set the address of the trusted oracle.
     * @param _oracleAddress The address of the oracle contract/account.
     */
    function setOracleAddress(address _oracleAddress) external onlyGovernance whenNotPaused {
         oracleAddress = _oracleAddress;
         // Could emit event
    }

    /**
     * @notice Allows the designated oracle to submit external data to the contract.
     * @param dataHash A hash identifying the external data.
     * @param value A numeric value associated with the data.
     * @param timestamp The timestamp of the data on the oracle's end.
     */
    function receiveOracleData(bytes32 dataHash, uint256 value, uint64 timestamp) external whenNotPaused {
        require(msg.sender == oracleAddress, CallerNotOracle());
        lastOracleData = OracleData(dataHash, value, timestamp);
        emit OracleDataReceived(dataHash, value, timestamp);
    }

    /**
     * @notice Gets the last received data from the oracle.
     * @return struct OracleData.
     */
    function getLastOracleData() public view returns (OracleData memory) {
        return lastOracleData;
    }


    // --- ADMIN & SAFETY ---

    /**
     * @notice Emergency pause function. Only callable by owner.
     */
    function pauseContract() external onlyOwner {
        _paused = true;
    }

    /**
     * @notice Unpause function. Only callable by owner.
     */
    function unpauseContract() external onlyOwner {
        _paused = false;
    }

     /**
     * @notice Governance function to set the duration a particle stays in Superposition.
     * @param blocks The duration in blocks.
     */
    function setSuperpositionDuration(uint64 blocks) external onlyGovernance whenNotPaused {
        superpositionDurationBlocks = blocks;
         // Could emit event
    }

    // --- INTERNAL/OVERRIDDEN ERC721 FUNCTIONS ---

    // Override ERC721 _beforeTokenTransfer to handle ownedParticles helper on standard transfers/mints/burns
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Note: This won't handle the custom transferParticle function where we manage the list explicitly.
        // A more robust approach might ditch the _ownedParticles list helper entirely or manage it more carefully.
        // For this example, _ownedParticles is just a best-effort view helper. _ownedParticleCount is more reliable.

        // Example check: prevent transfer if entangled (optional rule)
        // require(_entangledPair[tokenId] == 0, "QF: Cannot transfer entangled particle");
    }

    // The following functions are required by ERC721 but don't need custom logic beyond OpenZeppelin's implementation
    // function approve(address to, uint256 tokenId) public virtual override {}
    // function getApproved(uint256 tokenId) public view virtual override returns (address) {}
    // function setApprovalForAll(address operator, bool approved) public virtual override {}
    // function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {}
    // function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {}
    // function _burn(uint256 tokenId) internal override {} // If burning particles is ever needed
    // function _baseURI() internal view virtual override returns (string memory) { return ""; } // Add base URI if metadata exists
}
```