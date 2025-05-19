Okay, here is a Solidity smart contract draft incorporating several interesting, advanced, and creative concepts without directly replicating common open-source patterns.

The theme revolves around a "Genesis Labyrinth," an on-chain generative system where users contribute resources (Essence, represented by ETH) to grow unique, parametric "Strands." The Labyrinth itself exists in phases, influencing growth rules and interactions. Users can combine, mutate, challenge, and harvest these Strands, creating a dynamic, evolving ecosystem driven by user interaction and on-chain state.

This contract is a conceptual exploration and would require extensive security audits and optimization for production use.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title GenesisLabyrinth
 * @dev A conceptual smart contract representing a dynamic, generative on-chain labyrinth.
 * Users contribute Essence (ETH) to grow unique, parametric Strands. The Labyrinth
 * evolves through phases, influencing interactions and Strand properties.
 * Features include generative asset creation, dynamic costs, on-chain challenges,
 * resource harvesting, and pseudo-deterministic evolution based on state.
 * This contract is for exploration of complex on-chain mechanics and is not
 * audited for production use.
 */

// --- OUTLINE ---
// 1. State Variables: Define core data structures for the labyrinth, strands, challenges, etc.
// 2. Structs: Define custom types for Strand and Challenge data.
// 3. Events: Declare events emitted on key state changes.
// 4. Modifiers: Define custom modifiers for access control and state checks.
// 5. Constructor: Initialize the contract with owner and initial parameters.
// 6. Core Labyrinth Management: Functions for owner to manage labyrinth state, phases, and parameters.
// 7. Strand Management: Functions for users to create, interact with, modify, and query Strands.
// 8. Challenge System: Functions for users to propose, accept, resolve, and manage on-chain challenges.
// 9. Utility & Query: Helper and view functions to get information about the state, costs, etc.
// 10. Internal Logic: Helper functions for internal calculations and state transitions.

// --- FUNCTION SUMMARY ---
// 1.  constructor(): Deploys the contract, setting initial owner and parameters.
// 2.  transferOwnership(address newOwner): Transfers contract ownership.
// 3.  renounceOwnership(): Relinquishes contract ownership (irrevocable).
// 4.  pauseLabyrinth(): Owner can pause most user interactions (optional, not fully implemented for brevity).
// 5.  unpauseLabyrinth(): Owner can unpause the labyrinth.
// 6.  advanceLabyrinthPhase(): Owner advances the labyrinth to the next phase (subject to time lock).
// 7.  setPhaseParameters(uint256 phase, uint256 baseCost, uint256 growthFactor, uint256 stabilityFactor): Owner sets parameters for a specific labyrinth phase.
// 8.  setBaseChallengeStake(uint256 newStake): Owner sets the minimum stake for challenges.
// 9.  withdrawEssencePool(uint256 amount): Owner can withdraw accrued ETH (Essence) from the contract pool.
// 10. seedGenesisStrand(): (Owner/special function) Seeds initial strands for the labyrinth.
// 11. seedStrand(uint32 parentId1, uint32 parentId2): Users pay ETH (Essence) to create a new Strand, potentially linked to existing parents.
// 12. harvestStrandEnergy(uint256 strandId): Users extract stored internal energy from a Strand, converting it to harvestable value.
// 13. graftStrands(uint256 strandId1, uint256 strandId2): Combine properties of two Strands to create a new one (potentially consuming or modifying parents).
// 14. mutateStrand(uint256 strandId): Pay Essence to trigger a pseudo-random mutation of a Strand's properties.
// 15. refineStrand(uint256 strandId): Burn a Strand to recover a portion of invested Essence or gain other benefits.
// 16. transferStrand(address to, uint256 strandId): Transfer ownership of a Strand (ERC-721 like).
// 17. proposeChallenge(uint256 strandId1, uint256 strandId2, uint256 stake): Propose a challenge between two Strands, staking Essence.
// 18. acceptChallenge(uint64 challengeId): The challenged party accepts a challenge, matching the stake.
// 19. resolveChallenge(uint64 challengeId): Resolve a challenge based on predefined criteria (pseudo-random + Strand properties).
// 20. cancelChallenge(uint64 challengeId): Proposer cancels a pending challenge.
// 21. claimChallengeStake(uint64 challengeId): Winner of a resolved challenge claims their stake.
// 22. getCurrentLabyrinthPhase(): View function returning the current phase.
// 23. getDynamicSeedCost(uint32 parentId1, uint32 parentId2): View function calculating the cost to seed a new Strand based on current state and parents.
// 24. getStrand(uint256 strandId): View function returning details of a specific Strand.
// 25. getStrandOwner(uint256 strandId): View function returning the owner of a Strand.
// 26. getTotalStrands(): View function returning the total number of Strands created.
// 27. getChallenge(uint64 challengeId): View function returning details of a specific challenge.
// 28. getLabyrinthEntropy(): View function calculating a value representing system complexity/randomness.
// 29. predictMutationResult(uint256 strandId, bytes32 predictionSeed): View function to predict the outcome of a mutation *if* a specific seed were used (for off-chain simulation).
// 30. getUserAffinity(address user): View function returning a user's affinity score (conceptual).

contract GenesisLabyrinth {

    // --- State Variables ---
    address private _owner;
    uint256 public labyrinthPhase;
    uint64 public lastPhaseAdvanceTime;
    uint256 public constant PHASE_DURATION = 7 days; // Example duration

    uint256 private essencePool; // Accumulates ETH sent to the contract

    uint256 public nextStrandId;
    mapping(uint256 => Strand) public strands;
    mapping(uint256 => address) public strandOwner; // ERC-721 like ownership
    mapping(address => uint256) public userAffinity; // Represents user's standing/trust/activity

    uint64 public nextChallengeId;
    mapping(uint64 => Challenge) public challenges;
    uint256 public baseChallengeStake;

    bool private _paused; // Simple pause mechanism (optional)

    struct Strand {
        uint256 id;
        uint64 creationTimestamp;
        uint128 essenceSeeded; // Total ETH contributed directly to this strand
        uint32 parentStrandId1; // 0 for genesis or root-like strands
        uint32 parentStrandId2; // 0 for genesis or root-like strands
        uint8 colorHue;      // Parametric property 1 (0-255) - can be visualized off-chain
        uint8 complexity;    // Parametric property 2 (0-255) - affects mechanics
        uint8 stability;     // Parametric property 3 (0-255) - affects mechanics
        uint32 energyStored;  // Internal energy, can be harvested
        bool exists;         // Sentinel to check if ID is valid
        bool isConsumed;     // True if consumed in grafting/refining
    }

    enum ChallengeState { Pending, Accepted, ChallengerResolvedWin, ChallengedResolvedWin, Cancelled, Expired }

    struct Challenge {
        uint64 id;
        address challenger;
        address challenged;
        uint256 strandId1;
        uint256 strandId2;
        uint256 stake; // In Wei (ETH)
        uint64 challengeTimestamp;
        ChallengeState state;
        // Future: bytes32 commitHash; // For commit-reveal challenge resolution
    }

    struct PhaseParameters {
        uint256 baseSeedCost; // Base ETH cost to seed a strand in this phase
        uint256 growthFactor; // Multiplier for energy storage / accumulation
        uint256 stabilityFactor; // Influences mutation probability / challenge outcomes
    }

    mapping(uint256 => PhaseParameters) public phaseParams;

    // --- Events ---
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event LabyrinthPaused(address account);
    event LabyrinthUnpaused(address account);
    event LabyrinthPhaseAdvanced(uint256 indexed newPhase, uint64 timestamp);
    event PhaseParametersUpdated(uint256 indexed phase, uint256 baseCost, uint256 growthFactor, uint256 stabilityFactor);
    event EssenceWithdrawn(address indexed recipient, uint256 amount);

    event StrandCreated(uint256 indexed strandId, address indexed owner, uint32 parentId1, uint32 parentId2, uint256 initialEssence, uint64 timestamp);
    event StrandHarvested(uint256 indexed strandId, address indexed owner, uint32 energyHarvested, uint256 amountReceived);
    event StrandsGrafted(uint256 indexed newStrandId, address indexed owner, uint256 indexed parentId1, uint256 indexed parentId2);
    event StrandMutated(uint256 indexed strandId, address indexed owner, uint8 newHue, uint8 newComplexity, uint8 newStability);
    event StrandRefined(uint256 indexed strandId, address indexed owner, uint256 essenceRecovered);
    event StrandTransferred(uint256 indexed strandId, address indexed from, address indexed to);

    event ChallengeProposed(uint64 indexed challengeId, address indexed challenger, address indexed challenged, uint256 strandId1, uint256 strandId2, uint256 stake);
    event ChallengeAccepted(uint64 indexed challengeId);
    event ChallengeResolved(uint64 indexed challengeId, ChallengeState state, address indexed winner);
    event ChallengeCancelled(uint64 indexed challengeId);
    event ChallengeStakeClaimed(uint64 indexed challengeId, address indexed winner, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Labyrinth is paused");
        _;
    }

    modifier strandExists(uint256 strandId) {
        require(strands[strandId].exists, "Strand does not exist");
        _;
    }

    modifier isStrandOwner(uint256 strandId) {
        require(strandOwner[strandId] == msg.sender, "Not strand owner");
        _;
    }

    modifier challengeExists(uint64 challengeId) {
        require(challenges[challengeId].id != 0 || nextChallengeId > challengeId, "Challenge does not exist"); // Check if ID was assigned
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        labyrinthPhase = 1; // Start at phase 1
        lastPhaseAdvanceTime = uint64(block.timestamp);
        nextStrandId = 1; // Start strand IDs from 1
        nextChallengeId = 1; // Start challenge IDs from 1

        // Set initial phase parameters
        phaseParams[1] = PhaseParameters(1 ether, 100, 100); // Example initial params
        baseChallengeStake = 0.1 ether; // Example minimum stake

        emit OwnershipTransferred(address(0), _owner);
        emit LabyrinthPhaseAdvanced(labyrinthPhase, lastPhaseAdvanceTime);
        emit PhaseParametersUpdated(1, phaseParams[1].baseSeedCost, phaseParams[1].growthFactor, phaseParams[1].stabilityFactor);
    }

    // --- Core Labyrinth Management ---

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() external onlyOwner {
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    function pauseLabyrinth() external onlyOwner whenNotPaused {
        _paused = true;
        emit LabyrinthPaused(msg.sender);
    }

    function unpauseLabyrinth() external onlyOwner {
        require(_paused, "Labyrinth is not paused");
        _paused = false;
        emit LabyrinthUnpaused(msg.sender);
    }

    function advanceLabyrinthPhase() external onlyOwner {
        require(block.timestamp >= lastPhaseAdvanceTime + PHASE_DURATION, "Phase duration not elapsed");
        labyrinthPhase++;
        lastPhaseAdvanceTime = uint64(block.timestamp);
        // TODO: Implement logic for how advancing phase affects existing strands (decay? boost?)
        emit LabyrinthPhaseAdvanced(labyrinthPhase, lastPhaseAdvanceTime);
    }

    function setPhaseParameters(uint256 phase, uint256 baseCost, uint256 growthFactor, uint256 stabilityFactor) external onlyOwner {
        phaseParams[phase] = PhaseParameters(baseCost, growthFactor, stabilityFactor);
        emit PhaseParametersUpdated(phase, baseCost, growthFactor, stabilityFactor);
    }

    function setBaseChallengeStake(uint256 newStake) external onlyOwner {
        baseChallengeStake = newStake;
    }

    function withdrawEssencePool(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= essencePool, "Insufficient essence in pool");
        essencePool -= amount;
        (bool success, ) = payable(_owner).call{value: amount}("");
        require(success, "ETH withdrawal failed");
        emit EssenceWithdrawn(_owner, amount);
    }

    // --- Strand Management ---

    function seedGenesisStrand() external onlyOwner {
        // Special function to seed the very first strands (e.g., 1-5)
        // Only callable once or in a specific setup phase
        require(nextStrandId == 1, "Genesis strands already seeded");

        // Seed a few initial strands
        _createStrand(msg.sender, 0, 0, 1 ether); // Seed with some initial value
        _createStrand(msg.sender, 0, 0, 1 ether);
        _createStrand(msg.sender, 0, 0, 1 ether);
        // ... create a few more ...
    }

    // Allows anyone to send ETH to seed a new strand
    // msg.value is the 'Essence' contributed
    function seedStrand(uint32 parentId1, uint32 parentId2) external payable whenNotPaused {
        require(msg.value >= getDynamicSeedCost(parentId1, parentId2), "Insufficient Essence sent");
        require(parentId1 == 0 || strands[parentId1].exists, "Parent 1 does not exist");
        require(parentId2 == 0 || strands[parentId2].exists, "Parent 2 does not exist");

        _createStrand(msg.sender, parentId1, parentId2, msg.value);
    }

    // Internal helper to create a strand
    function _createStrand(address owner, uint32 parentId1, uint32 parentId2, uint256 initialEssence) internal {
        uint256 currentId = nextStrandId++;

        // --- Generative Logic ---
        // Properties derived from parents, current labyrinth phase, creation time, and a bit of entropy
        bytes32 entropy = keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            tx.origin,
            owner,
            parentId1,
            parentId2,
            initialEssence,
            getLabyrinthEntropy() // Incorporate system entropy
        ));

        uint8 hue = uint8(entropy[0]);
        uint8 complexity = uint8(entropy[1]);
        uint8 stability = uint8(entropy[2]);

        // Adjust based on parents (example: average or blend)
        if (parentId1 != 0) {
            hue = uint8((uint256(hue) + strands[parentId1].colorHue) / 2);
            complexity = uint8((uint256(complexity) + strands[parentId1].complexity) / 2);
        }
        if (parentId2 != 0) {
             hue = uint8((uint256(hue) + strands[parentId2].colorHue) / 2);
             stability = uint8((uint256(stability) + strands[parentId2].stability) / 2);
        }

        // Adjust based on phase parameters
        complexity = uint8(uint256(complexity) * phaseParams[labyrinthPhase].growthFactor / 100);
        stability = uint8(uint256(stability) * phaseParams[labyrinthPhase].stabilityFactor / 100);


        // Cap values to 255
        if (complexity > 255) complexity = 255;
        if (stability > 255) stability = 255;

        // Initial energy stored based on essence and phase growth factor
        uint32 initialEnergy = uint32((initialEssence * phaseParams[labyrinthPhase].growthFactor) / 1 ether); // Scale ETH to energy points

        strands[currentId] = Strand({
            id: currentId,
            creationTimestamp: uint64(block.timestamp),
            essenceSeeded: uint128(initialEssence),
            parentStrandId1: parentId1,
            parentStrandId2: parentId2,
            colorHue: hue,
            complexity: complexity,
            stability: stability,
            energyStored: initialEnergy,
            exists: true,
            isConsumed: false
        });

        strandOwner[currentId] = owner;
        essencePool += msg.value; // Add received ETH to pool

        // Update user affinity (simple example: increase on creation)
        userAffinity[owner] += 1;

        emit StrandCreated(currentId, owner, parentId1, parentId2, initialEssence, uint64(block.timestamp));
    }

    // Harvests energy from a strand, converting it back to ETH
    function harvestStrandEnergy(uint256 strandId) external whenNotPaused isStrandOwner(strandId) strandExists(strandId) {
        Strand storage strand = strands[strandId];
        require(!strand.isConsumed, "Strand is consumed");
        require(strand.energyStored > 0, "No energy to harvest");

        // Calculate harvest amount - proportional to energy, potentially decay over time
        uint32 energyToHarvest = strand.energyStored; // Harvest all for simplicity
        strand.energyStored = 0; // Deplete energy

        // Calculate ETH amount - inverse of seeding logic, maybe with a fee/decay
        uint256 harvestAmount = (uint256(energyToHarvest) * 1 ether) / phaseParams[labyrinthPhase].growthFactor; // Simple conversion

        // Apply a harvesting fee/decay (e.g., 10%)
        uint256 fee = harvestAmount / 10;
        harvestAmount -= fee;
        essencePool += fee; // Fee goes back to the pool

        require(harvestAmount > 0, "Harvest amount too low after fee");
        require(essencePool >= harvestAmount, "Insufficient essence pool for withdrawal"); // Should generally not happen if pool accumulates fees

        essencePool -= harvestAmount;
        (bool success, ) = payable(msg.sender).call{value: harvestAmount}("");
        require(success, "ETH transfer failed");

        // Update user affinity (simple example: increase on harvest)
        userAffinity[msg.sender] += 1;

        emit StrandHarvested(strandId, msg.sender, energyToHarvest, harvestAmount);
    }

    // Combines two strands to create a new, potentially more complex one
    function graftStrands(uint256 strandId1, uint256 strandId2) external payable whenNotPaused {
        require(msg.value >= getDynamicSeedCost(uint32(strandId1), uint32(strandId2)), "Insufficient Essence for grafting");
        require(strandId1 != strandId2, "Cannot graft a strand onto itself");
        strandExists(strandId1);
        strandExists(strandId2);
        isStrandOwner(strandId1); // Must own both
        isStrandOwner(strandId2);

        Strand storage s1 = strands[strandId1];
        Strand storage s2 = strands[strandId2];

        require(!s1.isConsumed && !s2.isConsumed, "Parent strands are consumed");

        // Mark parents as consumed - they can no longer be harvested/grafted/mutated/refined
        s1.isConsumed = true;
        s2.isConsumed = true;
        // Ownership of consumed strands remains but their utility is gone (could add a `burn` option)

        // Create a new strand using parents as references
        _createStrand(msg.sender, uint32(strandId1), uint32(strandId2), msg.value);

        // Update user affinity
        userAffinity[msg.sender] += 5; // Grafting gives more affinity

        emit StrandsGrafted(nextStrandId - 1, msg.sender, uint32(strandId1), uint32(strandId2));
    }

    // Pay Essence to randomly mutate a strand's properties
    function mutateStrand(uint256 strandId) external payable whenNotPaused isStrandOwner(strandId) strandExists(strandId) {
        Strand storage strand = strands[strandId];
        require(!strand.isConsumed, "Strand is consumed");
        require(msg.value > 0, "Must send some Essence for mutation"); // Cost could be dynamic

        essencePool += msg.value; // Essence goes to the pool

        // Use block hash and strand properties for pseudo-randomness
        bytes32 entropy = keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            tx.origin,
            strandId,
            strand.colorHue,
            strand.complexity,
            strand.stability,
            getLabyrinthEntropy()
        ));

        // Apply mutation based on entropy and strand stability/labyrinth stabilityFactor
        // Less stability means higher chance/magnitude of mutation
        uint256 mutationFactor = (256 - strand.stability) * phaseParams[labyrinthPhase].stabilityFactor / 100; // Example calculation

        uint8 oldHue = strand.colorHue;
        uint8 oldComplexity = strand.complexity;
        uint8 oldStability = strand.stability;

        // Simple mutation: add or subtract a value based on entropy and factor
        strand.colorHue = uint8(uint256(strand.colorHue) + int8(int256(uint8(entropy[0])) - 128) * mutationFactor / 256);
        strand.complexity = uint8(uint256(strand.complexity) + int8(int256(uint8(entropy[1])) - 128) * mutationFactor / 256);
        strand.stability = uint8(uint256(strand.stability) + int8(int256(uint8(entropy[2])) - 128) * mutationFactor / 256);

        // Ensure properties stay within 0-255
        strand.colorHue = uint8(uint256(strand.colorHue) % 256); // Wrap around
        strand.complexity = uint8(uint256(strand.complexity) % 256);
        strand.stability = uint8(uint256(strand.stability) % 256);

        // Mutation also affects energy stored
        strand.energyStored = uint32(uint256(strand.energyStored) * (256 + uint8(entropy[3])) / 256); // Random boost/drain

        // Update user affinity
        userAffinity[msg.sender] += 2; // Mutation gives some affinity

        emit StrandMutated(strandId, msg.sender, strand.colorHue, strand.complexity, strand.stability);
    }

    // Burn a strand to recover some Essence
    function refineStrand(uint256 strandId) external whenNotPaused isStrandOwner(strandId) strandExists(strandId) {
        Strand storage strand = strands[strandId];
        require(!strand.isConsumed, "Strand is consumed");

        // Recover a percentage of the initial essence + energy (with a cost/decay)
        uint256 recoveredAmount = strand.essenceSeeded / 2; // Example: 50% recovery of initial seed
        recoveredAmount += (uint256(strand.energyStored) * 1 ether) / (phaseParams[labyrinthPhase].growthFactor * 2); // Example: 50% recovery of energy value

        // Mark as consumed (effectively burned)
        strand.isConsumed = true;
        strand.energyStored = 0; // Deplete energy on burn

        // Transfer recovered amount from pool
        require(essencePool >= recoveredAmount, "Insufficient essence pool for recovery");
        essencePool -= recoveredAmount;

        (bool success, ) = payable(msg.sender).call{value: recoveredAmount}("");
        require(success, "ETH transfer failed");

        // Update user affinity
        userAffinity[msg.sender] += 3; // Refining gives affinity

        emit StrandRefined(strandId, msg.sender, recoveredAmount);
    }

    // ERC-721 like transfer (simplified)
    function transferStrand(address to, uint256 strandId) external whenNotPaused isStrandOwner(strandId) strandExists(strandId) {
        require(to != address(0), "Cannot transfer to zero address");
        strandOwner[strandId] = to;
        emit StrandTransferred(strandId, msg.sender, to);
    }

    // --- Challenge System ---

    // Propose a challenge between two strands
    // Stake essence/ETH. Challenge involves properties of both strands.
    function proposeChallenge(uint256 strandId1, uint256 strandId2) external payable whenNotPaused {
        require(msg.value >= baseChallengeStake, "Stake must meet minimum");
        strandExists(strandId1);
        strandExists(strandId2);
        require(strands[strandId1].owner != address(0) && strands[strandId2].owner != address(0), "Strands must be owned"); // Should be guaranteed by strandExists+ownership tracking
        require(!strands[strandId1].isConsumed && !strands[strandId2].isConsumed, "Involved strands are consumed");


        // Determine challenged party - owner of strandId2 for now
        address challengedParty = strandOwner[strandId2];
        require(challengedParty != msg.sender, "Cannot challenge your own strand against yourself");

        uint64 currentChallengeId = nextChallengeId++;

        challenges[currentChallengeId] = Challenge({
            id: currentChallengeId,
            challenger: msg.sender,
            challenged: challengedParty,
            strandId1: strandId1,
            strandId2: strandId2,
            stake: msg.value,
            challengeTimestamp: uint64(block.timestamp),
            state: ChallengeState.Pending
        });

        essencePool += msg.value; // Stake goes to the pool temporarily

        // Update user affinity
        userAffinity[msg.sender] += 1; // Proposing gives minor affinity

        emit ChallengeProposed(currentChallengeId, msg.sender, challengedParty, strandId1, strandId2, msg.value);
    }

    // The challenged party accepts the challenge
    function acceptChallenge(uint64 challengeId) external payable whenNotPaused challengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.state == ChallengeState.Pending, "Challenge is not pending");
        require(msg.sender == challenge.challenged, "Only challenged party can accept");
        require(msg.value >= challenge.stake, "Must match the challenger's stake");

        challenge.state = ChallengeState.Accepted;
        essencePool += msg.value; // Challenged stake goes to the pool

        // Update user affinity
        userAffinity[msg.sender] += 1; // Accepting gives minor affinity

        emit ChallengeAccepted(challengeId);
    }

    // Resolve an accepted challenge
    // This is a simplified resolution mechanism using on-chain data.
    // **WARNING**: Using block.timestamp/block.number/block.hash for high-stakes randomness
    // is susceptible to miner manipulation. For a real application, use a verifiable
    // randomness source (VRF) or commit-reveal scheme.
    function resolveChallenge(uint64 challengeId) external whenNotPaused challengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.state == ChallengeState.Accepted, "Challenge is not accepted");
        // Anyone can call resolve once accepted (or add a time delay)

        Strand storage s1 = strands[challenge.strandId1];
        Strand storage s2 = strands[challenge.strandId2];

        // Ensure strands are still valid and not consumed
        require(s1.exists && s2.exists && !s1.isConsumed && !s2.isConsumed, "Involved strands invalid or consumed");

        // --- Challenge Resolution Logic (Simplified) ---
        // Use block hash, strand properties, and time for a pseudo-random outcome
        bytes32 resolutionSeed = keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty, // Adds some entropy
            getLabyrinthEntropy(), // Global entropy
            s1.colorHue, s1.complexity, s1.stability, s1.energyStored,
            s2.colorHue, s2.complexity, s2.stability, s2.energyStored
        ));

        // Example resolution: Challenger wins if (entropy + s1.complexity) > (s2.complexity + s2.stability) % a value
        uint256 challengerScore = uint256(resolutionSeed) + s1.complexity + s1.stability; // Incorporate stability
        uint256 challengedScore = s2.complexity + s2.stability;

        ChallengeState finalState;
        address winner;
        address loser;

        // Add some phase influence
        challengerScore += phaseParams[labyrinthPhase].growthFactor;
        challengedScore += phaseParams[labyrinthPhase].stabilityFactor;

        if (challengerScore >= challengedScore) { // Simple comparison
            finalState = ChallengeState.ChallengerResolvedWin;
            winner = challenge.challenger;
            loser = challenge.challenged;
        } else {
            finalState = ChallengeState.ChallengedResolvedWin;
            winner = challenge.challenged;
            loser = challenge.challenger;
        }

        challenge.state = finalState;

        // --- Post-Resolution Effects ---
        // Winner gets stake, loser loses stake (handled by claim function)
        // Strands are affected (e.g., loser's strand loses energy, winner's gains, or one is consumed)
        if (finalState == ChallengeState.ChallengerResolvedWin) {
            s2.energyStored = uint32(uint256(s2.energyStored) / 2); // Loser's strand loses half energy
            s1.energyStored = uint32(uint256(s1.energyStored) * 110 / 100); // Winner's strand gains 10% energy
            userAffinity[winner] += 10; // Winner gains significant affinity
            userAffinity[loser] = userAffinity[loser] >= 5 ? userAffinity[loser] - 5 : 0; // Loser loses some affinity
        } else { // Challenged Resolved Win
            s1.energyStored = uint32(uint256(s1.energyStored) / 2);
            s2.energyStored = uint32(uint256(s2.energyStored) * 110 / 100);
            userAffinity[winner] += 10;
            userAffinity[loser] = userAffinity[loser] >= 5 ? userAffinity[loser] - 5 : 0;
        }


        emit ChallengeResolved(challengeId, finalState, winner);
    }

    // Proposer can cancel a challenge if it's still pending
    function cancelChallenge(uint64 challengeId) external whenNotPaused challengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.state == ChallengeState.Pending, "Challenge is not pending");
        require(msg.sender == challenge.challenger, "Only challenger can cancel");

        challenge.state = ChallengeState.Cancelled;

        // Return stake to challenger
        uint256 stakeAmount = challenge.stake;
        essencePool -= stakeAmount;
        (bool success, ) = payable(msg.sender).call{value: stakeAmount}("");
        require(success, "ETH transfer failed during cancel");

        emit ChallengeCancelled(challengeId);
    }

    // Winner claims their stake after a challenge is resolved
    function claimChallengeStake(uint64 challengeId) external whenNotPaused challengeExists(challengeId) {
        Challenge storage challenge = challenges[challengeId];
        require(challenge.state == ChallengeState.ChallengerResolvedWin || challenge.state == ChallengeState.ChallengedResolvedWin, "Challenge not resolved");

        address winner;
        if (challenge.state == ChallengeState.ChallengerResolvedWin) {
            winner = challenge.challenger;
        } else { // ChallengedResolvedWin
            winner = challenge.challenged;
        }

        require(msg.sender == winner, "Only the winner can claim stake");

        // Calculate total pool for this challenge (both stakes)
        uint256 totalStake = challenge.stake * 2; // Assuming stakes are matched

        // Apply a small protocol fee (e.g., 2% of total stake)
        uint256 protocolFee = totalStake / 50; // 2%
        uint256 amountToWinner = totalStake - protocolFee;
        // protocolFee stays in essencePool

        require(amountToWinner > 0, "Amount to winner is zero");
        require(essencePool >= amountToWinner, "Insufficient essence pool for claim");

        // Mark challenge as claimed (e.g., set stake to 0 or state to Claimed)
        // Adding a 'Claimed' state is better practice
        // challenge.state = ChallengeState.Claimed; // Need to add Claimed state
        // For simplicity, let's zero out stake and rely on event
        challenge.stake = 0; // This prevents double claiming but means we can't look up claimed state easily

        essencePool -= amountToWinner;
        (bool success, ) = payable(msg.sender).call{value: amountToWinner}("");
        require(success, "ETH transfer failed during claim");

        emit ChallengeStakeClaimed(challengeId, winner, amountToWinner);
    }


    // --- Utility & Query ---

    function owner() external view returns (address) {
        return _owner;
    }

    function paused() external view returns (bool) {
        return _paused;
    }

    function getCurrentLabyrinthPhase() external view returns (uint256) {
        return labyrinthPhase;
    }

    // Calculates the current dynamic cost to seed a new strand
    function getDynamicSeedCost(uint32 parentId1, uint32 parentId2) public view returns (uint256) {
        PhaseParameters storage currentParams = phaseParams[labyrinthPhase];
        uint256 cost = currentParams.baseSeedCost;

        // Example dynamic adjustment: cost increases slightly with more parents or higher complexity parents
        uint256 parentBonus = 0;
        if (parentId1 != 0 && strands[parentId1].exists) {
             parentBonus += strands[parentId1].complexity;
        }
        if (parentId2 != 0 && strands[parentId2].exists) {
             parentBonus += strands[parentId2].complexity;
        }

        cost += cost * parentBonus / 1000; // Add small percentage based on parent complexity

        // Example adjustment: cost increases with total essence in the pool (less 'available space')
        cost += essencePool / 1000; // Add 0.1% of the essence pool

        return cost;
    }

    function getStrand(uint256 strandId) external view strandExists(strandId) returns (Strand memory) {
        return strands[strandId];
    }

    function getStrandOwner(uint256 strandId) external view returns (address) {
        return strandOwner[strandId];
    }

    function getTotalStrands() external view returns (uint256) {
        return nextStrandId - 1; // Total strands created
    }

     function getChallenge(uint64 challengeId) external view challengeExists(challengeId) returns (Challenge memory) {
        return challenges[challengeId];
    }

    // Provides a value representing the system's entropy/activity
    function getLabyrinthEntropy() public view returns (bytes32) {
        // Combine various volatile and stateful parameters
        return keccak256(abi.encodePacked(
            block.timestamp,
            block.number,
            block.difficulty,
            nextStrandId,
            essencePool,
            labyrinthPhase,
            lastPhaseAdvanceTime
        ));
    }

    // Allows off-chain clients to predict the potential outcome of a mutation
    // **NOTE**: This is a pure function and relies on off-chain deterministic seed generation
    // aligned with the on-chain _mutateStrand logic's use of getLabyrinthEntropy().
    // True on-chain prediction with future entropy is impossible. This helps UIs.
    function predictMutationResult(uint256 strandId, bytes32 predictionSeed) external view returns (uint8 predictedHue, uint8 predictedComplexity, uint8 predictedStability) {
        Strand storage strand = strands[strandId];
         // Re-apply the mutation logic deterministically using the provided seed
        // This assumes the caller can generate `predictionSeed` based on future estimated on-chain entropy
        // For a truly deterministic pure function, the seed would need to be *entirely* external input.
        // The current implementation uses a mix, making this prediction *imperfect* but indicative.
        bytes32 entropy = keccak256(abi.encodePacked(
            predictionSeed, // Use external seed
            strandId,
            strand.colorHue,
            strand.complexity,
            strand.stability,
            getLabyrinthEntropy() // Still includes current on-chain entropy for context
        ));


        uint256 mutationFactor = (256 - strand.stability) * phaseParams[labyrinthPhase].stabilityFactor / 100;

        uint8 newHue = uint8(uint256(strand.colorHue) + int8(int256(uint8(entropy[0])) - 128) * mutationFactor / 256);
        uint8 newComplexity = uint8(uint256(strand.complexity) + int8(int256(uint8(entropy[1])) - 128) * mutationFactor / 256);
        uint8 newStability = uint8(uint256(strand.stability) + int8(int256(uint8(entropy[2])) - 128) * mutationFactor / 256);

        predictedHue = uint8(uint256(newHue) % 256);
        predictedComplexity = uint8(uint256(newComplexity) % 256);
        predictedStability = uint8(uint256(newStability) % 256);

        // Note: energyStored prediction is omitted for simplicity here
    }


    function getUserAffinity(address user) external view returns (uint256) {
        return userAffinity[user];
    }

    // Fallback function to accept raw ETH sends, adds to essence pool
    receive() external payable {
        essencePool += msg.value;
        // Potentially emit an event here
    }

    // Fallback function for calls to undefined functions
    fallback() external payable {
       essencePool += msg.value;
       // Potentially revert or log event
    }

}
```