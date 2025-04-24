Okay, here is a Solidity smart contract concept for a **Quantum Fluctuations DAO**.

This contract introduces dynamic NFTs ("Particles") whose state isn't fixed until an "Observation Event" (analogous to observing a quantum particle) "collapses" their state, revealing final attributes and potentially triggering effects based on probabilistic "fluctuations". The DAO governs parameters related to these dynamics, state transitions, and treasury management, using a custom influence/reputation system alongside standard token voting.

It aims for complexity through state management, probabilistic outcomes, inter-NFT relationships (entanglement), and a custom governance/influence model. It avoids duplicating a standard token, basic DAO, or simple NFT collection.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Outline & Function Summary

/*
Contract Name: QuantumFluctuationsDAO

Description:
A Decentralized Autonomous Organization governing a collection of dynamic, evolving NFTs called "Particles".
Particle states (Superposed, Entangled, Collapsed, Decayed) change based on interactions and time.
An "Observation Event" triggers a state "Collapse", fixing attributes based on probabilistic "Quantum Fluctuations"
and potentially observer influence. The DAO (governed by QFT token holders with influence)
controls system parameters, manages a treasury, and dictates the evolution rules.

Core Concepts:
1.  Dynamic NFTs: Particles with states that change.
2.  State Collapse: A function call fixes a particle's state and attributes probabilistically.
3.  Entanglement: Linking particles for shared fates during collapse.
4.  Quantum Fluctuations (Probabilistic Outcomes): Outcomes influenced by controlled entropy (e.g., block hash, although VRF is recommended for production).
5.  Influence System: A reputation-like score earned through participation, boosting voting power or interaction effects.
6.  DAO Governance: Token-based voting combined with influence for parameter changes and treasury management.
7.  Time Decay: Particles can decay if neglected, adding a maintenance incentive.

Tokens Involved:
-   QFT: Governance Token (ERC-20 like)
-   Particle: Dynamic NFT (ERC-721 like)
-   InfluenceToken: Reputation/Influence Score (non-transferable, internal)

Key Mechanisms:
-   Particle Creation: Burns QFT or requires DAO approval.
-   State Transitions: Superposed -> Entangled, Superposed -> Collapsed, Any -> Decayed.
-   Observation Event: Triggers Collapse. Callable by designated 'Observers' or high-influence users.
-   Governance Proposals: QFT holders propose changes to decay rates, fluctuation weights, observers, etc.
-   Influence Earning: Rewarded for voting on successful proposals, triggering collapses, potentially maintaining particles.
-   Treasury: Holds funds for ecosystem development, managed by DAO proposals.

Outline of Functions:

// --- Token Interfaces (Assumed Standard ERCs for interaction) ---
// (Interfaces defined here for completeness, but actual implementation uses standard patterns)
// function transfer(address to, uint256 amount) external returns (bool); // QFT
// function balanceOf(address account) external view returns (uint256); // QFT
// function safeTransferFrom(address from, address to, uint256 tokenId) external; // Particle
// function ownerOf(uint256 tokenId) external view returns (address); // Particle

// --- Particle State Management & Interaction (ERC721-like + Custom) ---
1.  createParticle(): Mints a new Particle in a Superposed state.
2.  entangleParticles(uint256 tokenId1, uint256 tokenId2): Links two Particles if owned by caller.
3.  breakEntanglement(uint256 tokenId): Unlinks a Particle from its entangled pair.
4.  triggerObservationEvent(uint256 tokenId): Initiates the state collapse process for a Particle.
5.  collapseParticle(uint256 tokenId, uint256 randomSeed): Internal function: Executes the probabilistic state collapse.
6.  decayParticle(uint256 tokenId): Allows eligible Particle owner or anyone with high influence to trigger decay.
7.  getParticleState(uint256 tokenId): Views the current state of a Particle.
8.  getParticleAttributes(uint256 tokenId): Views the revealed or potential attributes of a Particle.
9.  getEntangledPair(uint256 tokenId): Views the Particle ID entangled with a given one.
10. getParticleDecayEligibilityTime(uint256 tokenId): Views when a Particle is eligible for decay.

// --- Influence / Reputation System ---
11. earnInfluence(address account, uint256 amount): Internal function: Increments an account's influence score.
12. getInfluenceScore(address account): Views an account's current influence score.

// --- DAO Governance (QFT + Influence) ---
13. createProposal(bytes calldata proposalData, string calldata description): Creates a new governance proposal.
14. voteOnProposal(uint256 proposalId, bool support): Casts a vote on a proposal. Influence might modify weight.
15. executeProposal(uint256 proposalId): Executes a proposal if passed and grace period is over.
16. getProposalDetails(uint256 proposalId): Views details of a proposal.
17. getVoteDetails(uint256 proposalId, address voter): Views a specific voter's vote on a proposal.
18. updateDecayRate(uint256 newRate): Target function for a proposal: Updates the global decay rate.
19. addObserver(address observer): Target function for a proposal: Adds an address to the list of allowed Observers.
20. removeObserver(address observer): Target function for a proposal: Removes an address from the Observers list.
21. setFluctuationWeights(uint16[] calldata weights): Target function for a proposal: Sets probabilities for collapse outcomes.

// --- Treasury Management ---
22. depositToTreasury() payable: Allows sending ETH to the DAO treasury.
23. withdrawFromTreasury(address recipient, uint256 amount): Target function for a proposal: Transfers ETH from treasury.
24. getTreasuryBalance(): Views the current ETH balance of the treasury.

// --- Getters & Utilities ---
25. getQFTBalance(address account): Views QFT balance (Wrapper for ERC20).
26. getParticleOwner(uint256 tokenId): Views Particle owner (Wrapper for ERC721).
27. isObserver(address account): Checks if an address is a designated Observer.
28. getProposalCount(): Views the total number of proposals created.
29. getTokenAddresses(): Views the addresses of the QFT, Particle, and InfluenceToken contracts.


Function Summary:

1.  `createParticle(address owner)`: Mints a new NFT ('Particle') and assigns it an initial 'Superposed' state and potential attributes. Requires sender to have creation rights or burn QFT.
2.  `entangleParticles(uint256 tokenId1, uint256 tokenId2)`: Links two particles. Requires caller owns both. Entangled particles might influence each other's collapse.
3.  `breakEntanglement(uint256 tokenId)`: Removes the entanglement link for a particle. Requires caller owns the particle.
4.  `triggerObservationEvent(uint256 tokenId)`: Callable by designated 'Observers' or accounts meeting influence threshold. Initiates the state collapse for the specified particle (and potentially its entangled partner).
5.  `collapseParticle(uint256 tokenId, uint256 randomSeed)`: Internal function. Uses the random seed to probabilistically determine the particle's final state and attributes, transitioning it from 'Superposed' to 'Collapsed'. Awards influence to the triggerer.
6.  `decayParticle(uint256 tokenId)`: Callable by anyone once a particle's decay timer is reached. Changes the particle's state to 'Decayed' and potentially reduces its value or utility. Reward triggerer with influence.
7.  `getParticleState(uint256 tokenId)`: Public view function returning the current state (Superposed, Entangled, Collapsed, Decayed) of a particle.
8.  `getParticleAttributes(uint256 tokenId)`: Public view function returning the attributes. If not collapsed, might show 'potential' ranges. If collapsed, shows fixed values.
9.  `getEntangledPair(uint256 tokenId)`: Public view function returning the ID of the particle this particle is entangled with, or 0 if none.
10. `getParticleDecayEligibilityTime(uint256 tokenId)`: Public view function returning the timestamp after which a particle is eligible to be decayed.
11. `earnInfluence(address account, uint256 amount)`: Internal function used to award influence points. Called by the contract logic upon certain actions (e.g., successful collapse trigger, voting).
12. `getInfluenceScore(address account)`: Public view function returning the current influence score for an account.
13. `createProposal(bytes calldata proposalData, string calldata description)`: Allows QFT holders (above a threshold) to propose changes. `proposalData` encodes the function call and parameters for execution.
14. `voteOnProposal(uint256 proposalId, bool support)`: Allows QFT holders to vote yes/no. Influence score can multiply voting power.
15. `executeProposal(uint256 proposalId)`: Callable after voting period and if quorum/threshold met. Attempts to execute the proposed action using `call`.
16. `getProposalDetails(uint256 proposalId)`: Public view function returning the description, state, votes, and execution details of a proposal.
17. `getVoteDetails(uint256 proposalId, address voter)`: Public view function returning how a specific address voted and their effective vote weight.
18. `updateDecayRate(uint256 newRate)`: Callable only via a successful proposal execution. Updates the `decayRate` state variable.
19. `addObserver(address observer)`: Callable only via a successful proposal execution. Grants 'Observer' status to an address, allowing them to trigger `triggerObservationEvent`.
20. `removeObserver(address observer)`: Callable only via a successful proposal execution. Revokes 'Observer' status.
21. `setFluctuationWeights(uint16[] calldata weights)`: Callable only via a successful proposal execution. Updates the probability weights used in `collapseParticle`.
22. `depositToTreasury() payable`: Public payable function to send Ether to the contract's treasury.
23. `withdrawFromTreasury(address recipient, uint256 amount)`: Callable only via a successful proposal execution. Sends Ether from the treasury.
24. `getTreasuryBalance()`: Public view function returning the contract's current Ether balance.
25. `getQFTBalance(address account)`: Public view function wrapping the QFT token contract's balanceOf function.
26. `getParticleOwner(uint256 tokenId)`: Public view function wrapping the Particle token contract's ownerOf function.
27. `isObserver(address account)`: Public view function checking if an address is currently a designated Observer.
28. `getProposalCount()`: Public view function returning the total number of proposals that have been created.
29. `getTokenAddresses()`: Public view function returning the addresses of the QFT, Particle, and InfluenceToken contracts.

*/

// --- Required Libraries/Interfaces (Simplified/Represented Here) ---
// In a real scenario, you'd import these from OpenZeppelin or similar standard libraries.
// We define minimal interfaces here to avoid copying full standard library code.

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // ... other standard ERC20 functions
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    // ... other standard ERC721 functions
}

// --- Contract Definition ---

contract QuantumFluctuationsDAO {

    // --- State Variables ---

    // Token Contracts (Assume deployed elsewhere and addresses are set)
    IERC20 public immutable qftToken;
    IERC721 public immutable particleToken;
    // Note: InfluenceToken is internal and not a separate ERC contract for simplicity
    //       influenceScores mapping represents this.

    // Particle Data
    enum ParticleState { Superposed, Entangled, Collapsed, Decayed }
    struct ParticleData {
        ParticleState state;
        uint256 creationTime;
        uint256 lastInteractionTime; // Time of collapse, decay, or entanglement
        uint256 entangledWith; // TokenId of entangled particle, 0 if none
        // Simplified attributes - in reality, this would be more complex (e.g., mapping uint to value)
        uint256 revealedAttribute1;
        uint256 revealedAttribute2;
        // Add more attributes as needed
    }
    mapping(uint256 => ParticleData) public particleData;
    uint256 private _nextTokenId; // Counter for particles

    // Influence System
    mapping(address => uint256) public influenceScores;
    uint256 public constant COLLAPSE_INFLUENCE_REWARD = 10;
    uint256 public constant DECAY_TRIGGER_INFLUENCE_REWARD = 5;
    uint256 public constant VOTING_INFLUENCE_MULTIPLIER = 10; // Influence multiplies vote weight

    // DAO Governance
    struct Proposal {
        uint256 id;
        string description;
        bytes proposalData; // Encoded function call and parameters
        uint256 creationTime;
        uint256 votingPeriodEnd;
        uint256 gracePeriodEnd;
        uint256 totalVotesFor; // Weighted votes
        uint256 totalVotesAgainst; // Weighted votes
        mapping(address => bool) hasVoted; // Prevents double voting
        bool executed;
        bool canceled; // Optional: for canceling malicious/invalid proposals
        bool passed; // Calculated outcome
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 private _nextProposalId;

    uint256 public votingPeriodDuration = 3 days;
    uint256 public gracePeriodDuration = 1 days;
    uint256 public proposalThresholdQFT = 1000 * (10**18); // QFT needed to create proposal
    uint256 public quorumVotesPercentage = 4; // 4% of total QFT supply needed for quorum (multiplied by influence)
    uint256 public proposalPassThresholdPercentage = 51; // 51% of total votes cast needed to pass

    address[] public observers;
    mapping(address => bool) public isObserver;

    // System Parameters (Governed by DAO)
    uint256 public decayRate = 7 days; // Time until a particle is eligible for decay after creation or last interaction
    uint16[] public fluctuationWeights; // Weights for probabilistic outcomes during collapse (sum should ideally be 10000 for 0-9999 range)

    // Treasury
    address public treasuryRecipient; // Default recipient for treasury withdrawals (can be changed by DAO)

    // --- Events ---

    event ParticleCreated(uint256 tokenId, address owner, uint256 creationTime);
    event ParticleStateChanged(uint256 tokenId, ParticleState newState, uint256 timestamp);
    event ParticlesEntangled(uint256 tokenId1, uint256 tokenId2, uint256 timestamp);
    event EntanglementBroken(uint256 tokenId, uint256 timestamp);
    event ObservationTriggered(uint256 tokenId, address triggerer, uint256 timestamp);
    event ParticleCollapsed(uint256 tokenId, uint256 randomSeed, uint256 revealedAttribute1, uint256 revealedAttribute2, uint256 timestamp);
    event ParticleDecayed(uint256 tokenId, address triggerer, uint256 timestamp);
    event InfluenceEarned(address account, uint256 amount, string reason);

    event ProposalCreated(uint256 proposalId, address proposer, string description, uint256 creationTime);
    event VoteCast(uint256 proposalId, address voter, bool support, uint256 weightedVotes);
    event ProposalExecuted(uint256 proposalId, uint256 executionTime);
    event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event ObserverAdded(address observer);
    event ObserverRemoved(address observer);
    event FluctuationWeightsUpdated(uint16[] weights);

    event TreasuryDeposited(address indexed sender, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    // --- Modifiers ---

    modifier whenStateIs(uint256 _tokenId, ParticleState _state) {
        require(particleData[_tokenId].state == _state, "Wrong particle state");
        _;
    }

    modifier onlyObserverOrInfluence(uint256 requiredInfluence) {
        require(isObserver[msg.sender] || influenceScores[msg.sender] >= requiredInfluence, "Not authorized or insufficient influence");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == address(this), "Only DAO can call");
        _;
    }

    modifier onlyQFTHolders(uint256 requiredAmount) {
        require(qftToken.balanceOf(msg.sender) >= requiredAmount, "Insufficient QFT");
        _;
    }

    // --- Constructor ---

    constructor(address _qftToken, address _particleToken, address _initialGovernor) {
        qftToken = IERC20(_qftToken);
        particleToken = IERC721(_particleToken);
        treasuryRecipient = _initialGovernor; // Set an initial treasury recipient (can be DAO address itself later)

        // Initial fluctuation weights (example: 3 possible outcomes with weights 5000, 3000, 2000)
        fluctuationWeights = new uint16[](3);
        fluctuationWeights[0] = 5000;
        fluctuationWeights[1] = 3000;
        fluctuationWeights[2] = 2000;
    }

    // --- Particle State Management & Interaction ---

    // 1. Mint a new Particle
    function createParticle(address owner) public onlyQFTHolders(100 * (10**18)) { // Example: requires burning or locking QFT
        // In a real contract, this would interact with the ParticleToken contract to mint
        // For this example, we simulate minting and add data here.
        uint256 tokenId = _nextTokenId++;
        // particleToken.safeMint(owner, tokenId); // Assume safeMint exists on ParticleToken

        particleData[tokenId] = ParticleData({
            state: ParticleState.Superposed,
            creationTime: block.timestamp,
            lastInteractionTime: block.timestamp, // Initial interaction time
            entangledWith: 0,
            revealedAttribute1: 0, // Not set yet
            revealedAttribute2: 0 // Not set yet
        });

        // Example: Burn required QFT
        // require(qftToken.transferFrom(msg.sender, address(this), 100 * (10**18)), "QFT transfer failed");
        // depositToTreasury() // Maybe direct QFT to treasury?

        emit ParticleCreated(tokenId, owner, block.timestamp);
        emit ParticleStateChanged(tokenId, ParticleState.Superposed, block.timestamp);
    }

    // 2. Entangle two Particles
    function entangleParticles(uint256 tokenId1, uint256 tokenId2) public {
        require(tokenId1 != tokenId2, "Cannot entangle a particle with itself");
        require(particleToken.ownerOf(tokenId1) == msg.sender, "Caller does not own particle 1");
        require(particleToken.ownerOf(tokenId2) == msg.sender, "Caller does not own particle 2");
        require(particleData[tokenId1].state == ParticleState.Superposed, "Particle 1 not in Superposed state");
        require(particleData[tokenId2].state == ParticleState.Superposed, "Particle 2 not in Superposed state");
        require(particleData[tokenId1].entangledWith == 0, "Particle 1 is already entangled");
        require(particleData[tokenId2].entangledWith == 0, "Particle 2 is already entangled");

        particleData[tokenId1].state = ParticleState.Entangled;
        particleData[tokenId2].state = ParticleState.Entangled;
        particleData[tokenId1].entangledWith = tokenId2;
        particleData[tokenId2].entangledWith = tokenId1;

        particleData[tokenId1].lastInteractionTime = block.timestamp;
        particleData[tokenId2].lastInteractionTime = block.timestamp;

        emit ParticleStateChanged(tokenId1, ParticleState.Entangled, block.timestamp);
        emit ParticleStateChanged(tokenId2, ParticleState.Entangled, block.timestamp);
        emit ParticlesEntangled(tokenId1, tokenId2, block.timestamp);
    }

    // 3. Break Entanglement
    function breakEntanglement(uint256 tokenId) public {
        require(particleToken.ownerOf(tokenId) == msg.sender, "Caller does not own particle");
        require(particleData[tokenId].state == ParticleState.Entangled, "Particle is not in Entangled state");
        require(particleData[tokenId].entangledWith != 0, "Particle is not entangled");

        uint256 entangledTokenId = particleData[tokenId].entangledWith;
        require(entangledTokenId != 0, "Entangled particle ID invalid"); // Should not happen if state is Entangled

        // Break links
        particleData[tokenId].entangledWith = 0;
        particleData[entangledTokenId].entangledWith = 0;

        // Revert to Superposed state
        particleData[tokenId].state = ParticleState.Superposed;
        particleData[entangledTokenId].state = ParticleState.Superposed;

        particleData[tokenId].lastInteractionTime = block.timestamp;
        particleData[entangledTokenId].lastInteractionTime = block.timestamp;


        emit ParticleStateChanged(tokenId, ParticleState.Superposed, block.timestamp);
        emit ParticleStateChanged(entangledTokenId, ParticleState.Superposed, block.timestamp);
        emit EntanglementBroken(tokenId, block.timestamp);
    }

    // 4. Trigger Observation Event
    function triggerObservationEvent(uint256 tokenId)
        public
        onlyObserverOrInfluence(100) // Example: requires Observer status or 100 influence
    {
        ParticleData storage particle = particleData[tokenId];
        require(particle.state == ParticleState.Superposed || particle.state == ParticleState.Entangled, "Particle is not in a state to be observed");

        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, block.difficulty))); // Simple randomness, use VRF in prod!

        if (particle.state == ParticleState.Entangled) {
            uint256 entangledTokenId = particle.entangledWith;
            require(entangledTokenId != 0, "Entangled particle ID missing");

            // Entangled collapse - affects both particles using the same seed
            collapseParticle(tokenId, randomSeed);
            collapseParticle(entangledTokenId, randomSeed); // Use same seed for entanglement correlation
             // Ensure entanglement is broken after collapse
            particleData[tokenId].entangledWith = 0;
            particleData[entangledTokenId].entangledWith = 0;

        } else { // Superposed state
            collapseParticle(tokenId, randomSeed);
        }

        emit ObservationTriggered(tokenId, msg.sender, block.timestamp);
        earnInfluence(msg.sender, COLLAPSE_INFLUENCE_REWARD);
    }

    // 5. Internal function to execute state collapse
    function collapseParticle(uint256 tokenId, uint256 randomSeed) internal {
        ParticleData storage particle = particleData[tokenId];
        require(particle.state == ParticleState.Superposed || particle.state == ParticleState.Entangled, "Particle already collapsed or decayed");

        uint256 outcomeIndex = _getPseudoRandomOutcome(randomSeed);

        // Based on outcomeIndex and fluctuationWeights, determine revealed attributes
        // This is a simplified example. Real logic could be complex, mapping index to attribute ranges.
        particle.revealedAttribute1 = (randomSeed * (outcomeIndex + 1)) % 1000;
        particle.revealedAttribute2 = (randomSeed / (outcomeIndex + 1)) % 1000;

        particle.state = ParticleState.Collapsed;
        particle.lastInteractionTime = block.timestamp;

        emit ParticleStateChanged(tokenId, ParticleState.Collapsed, block.timestamp);
        emit ParticleCollapsed(tokenId, randomSeed, particle.revealedAttribute1, particle.revealedAttribute2, block.timestamp);
    }

    // Helper for pseudo-random outcome based on weights (simplified)
    function _getPseudoRandomOutcome(uint256 randomSeed) internal view returns (uint256) {
        uint256 totalWeight = 0;
        for (uint i = 0; i < fluctuationWeights.length; i++) {
            totalWeight += fluctuationWeights[i];
        }
        require(totalWeight > 0, "Fluctuation weights must be set");

        uint256 randomValue = randomSeed % totalWeight;
        uint256 cumulativeWeight = 0;
        for (uint i = 0; i < fluctuationWeights.length; i++) {
            cumulativeWeight += fluctuationWeights[i];
            if (randomValue < cumulativeWeight) {
                return i;
            }
        }
        // Fallback - should not be reached if totalWeight > 0
        return 0;
    }

    // 6. Trigger Particle Decay
    function decayParticle(uint256 tokenId) public {
        ParticleData storage particle = particleData[tokenId];
        require(particle.state != ParticleState.Decayed, "Particle is already Decayed");
        require(block.timestamp >= particle.lastInteractionTime + decayRate, "Particle not yet eligible for decay");

        particle.state = ParticleState.Decayed;
        // Optionally reset attributes or change ownership? For simplicity, just state change here.

        emit ParticleStateChanged(tokenId, ParticleState.Decayed, block.timestamp);
        emit ParticleDecayed(tokenId, msg.sender, block.timestamp);
        earnInfluence(msg.sender, DECAY_TRIGGER_INFLUENCE_REWARD); // Reward the triggerer
    }

    // 7. Get Particle State
    function getParticleState(uint256 tokenId) public view returns (ParticleState) {
        require(particleData[tokenId].creationTime > 0, "Particle does not exist"); // Check if particle exists
        return particleData[tokenId].state;
    }

    // 8. Get Particle Attributes
    function getParticleAttributes(uint256 tokenId) public view returns (uint256 attr1, uint256 attr2) {
         require(particleData[tokenId].creationTime > 0, "Particle does not exist");
        if (particleData[tokenId].state == ParticleState.Collapsed || particleData[tokenId].state == ParticleState.Decayed) {
            return (particleData[tokenId].revealedAttribute1, particleData[tokenId].revealedAttribute2);
        } else {
            // Return placeholder or potential range if not collapsed/decayed
            // Returning 0 here as a placeholder
            return (0, 0);
        }
    }

    // 9. Get Entangled Pair
    function getEntangledPair(uint256 tokenId) public view returns (uint256) {
         require(particleData[tokenId].creationTime > 0, "Particle does not exist");
        return particleData[tokenId].entangledWith;
    }

    // 10. Get Particle Decay Eligibility Time
    function getParticleDecayEligibilityTime(uint256 tokenId) public view returns (uint256) {
         require(particleData[tokenId].creationTime > 0, "Particle does not exist");
        return particleData[tokenId].lastInteractionTime + decayRate;
    }

    // --- Influence / Reputation System ---

    // 11. Earn Influence (Internal)
    function earnInfluence(address account, uint256 amount) internal {
        influenceScores[account] += amount;
        emit InfluenceEarned(account, amount, "Contract action"); // Generic reason
    }

    // 12. Get Influence Score
    function getInfluenceScore(address account) public view returns (uint256) {
        return influenceScores[account];
    }

    // --- DAO Governance ---

    // 13. Create a new Proposal
    function createProposal(bytes calldata proposalData, string calldata description)
        public
        onlyQFTHolders(proposalThresholdQFT)
        returns (uint256 proposalId)
    {
        proposalId = _nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: description,
            proposalData: proposalData,
            creationTime: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriodDuration,
            gracePeriodEnd: 0, // Set after voting ends if passed
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            hasVoted: new mapping(address => bool),
            executed: false,
            canceled: false,
            passed: false
        });
        emit ProposalCreated(proposalId, msg.sender, description, block.timestamp);
    }

    // 14. Cast a Vote on a Proposal
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime > 0, "Proposal does not exist");
        require(block.timestamp <= proposal.votingPeriodEnd, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal canceled");

        uint256 qftBalance = qftToken.balanceOf(msg.sender);
        require(qftBalance > 0, "Must hold QFT to vote");

        uint256 influence = influenceScores[msg.sender];
        uint256 weightedVotes = qftBalance + (influence * VOTING_INFLUENCE_MULTIPLIER); // Example: Influence boosts vote weight

        if (support) {
            proposal.totalVotesFor += weightedVotes;
        } else {
            proposal.totalVotesAgainst += weightedVotes;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, weightedVotes);
        // Optionally award influence for voting, maybe only on winning side after execution
    }

    // 15. Execute a Proposal
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime > 0, "Proposal does not exist");
        require(!proposal.executed, "Proposal already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(block.timestamp > proposal.votingPeriodEnd, "Voting period not ended");

        // Calculate quorum and result AFTER voting ends
        uint256 totalPossibleVotes = qftToken.balanceOf(address(this)); // Simplified: total supply in DAO, or use total supply tracking
        // A more robust quorum calculation would involve tracking total QFT holders' potential voting power.
        // For simplicity, let's use a percentage of total QFT supply *if* we could track it.
        // Let's assume a function `getTotalSupplyQFT()` exists or track it.
        // For *this* example, let's use a simple check against votes cast vs a minimum threshold relative to *total supply* or *total QFT held by potential voters*.
         uint256 totalQFTSupply = qftToken.balanceOf(address(0)); // Placeholder - needs actual total supply
         if (totalQFTSupply == 0) totalQFTSupply = 1; // Prevent division by zero if token hasn't minted supply yet (adjust based on token design)

        uint256 totalVotesCast = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 quorumVotesNeeded = (totalQFTSupply * quorumVotesPercentage) / 100; // This is too simple, needs refinement based on weighted votes vs potential total weighted votes


        // Simplified quorum check: Total votes cast must be significant AND meet threshold
        // A better quorum uses total possible weighted votes, or minimum voters.
        // Let's simplify: Quorum is met if total *weighted* votes cast exceed a % of potential max weighted votes (hard to track easily) OR just a fixed high number.
        // Simpler quorum for example: total weighted votes cast must be at least X QFT * equivalents
        uint256 simplifiedQuorumThreshold = 10000 * (10**18); // Example: 10k QFT equivalent votes minimum

        require(totalVotesCast >= simplifiedQuorumThreshold, "Quorum not reached"); // Simplified Quorum Check


        // Check if threshold passed
        proposal.passed = (proposal.totalVotesFor * 100) / totalVotesCast >= proposalPassThresholdPercentage;

        require(proposal.passed, "Proposal did not pass");

        // Set grace period
        proposal.gracePeriodEnd = block.timestamp + gracePeriodDuration;
        require(block.timestamp > proposal.gracePeriodEnd, "Grace period not ended"); // Ensure grace period passed

        // Execute the proposal data
        (bool success, ) = address(this).call(proposal.proposalData);
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId, block.timestamp);

        // Optional: Reward voters on the winning side with influence
        // This would require iterating through voters or tracking winners, more complex
    }

     // 16. Get Proposal Details
    function getProposalDetails(uint256 proposalId) public view returns (
        uint256 id,
        string memory description,
        bytes memory proposalData,
        uint256 creationTime,
        uint256 votingPeriodEnd,
        uint256 gracePeriodEnd,
        uint256 totalVotesFor,
        uint256 totalVotesAgainst,
        bool executed,
        bool canceled,
        bool passed
    ) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.creationTime > 0, "Proposal does not exist");
        return (
            proposal.id,
            proposal.description,
            proposal.proposalData,
            proposal.creationTime,
            proposal.votingPeriodEnd,
            proposal.gracePeriodEnd,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.executed,
            proposal.canceled,
            proposal.passed
        );
    }

    // 17. Get Vote Details (Requires checking the mapping directly)
    // Note: Due to mapping storage limitations, cannot easily list *all* voters.
    // This function checks if a *specific* voter has voted.
    function getVoteDetails(uint256 proposalId, address voter) public view returns (bool hasVoted) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.creationTime > 0, "Proposal does not exist");
         // Cannot retrieve vote *weight* or *support* easily from storage after the fact without storing it per voter
         // Returning just if they voted.
         return proposal.hasVoted[voter];
    }


    // --- DAO Target Functions (Only callable by the DAO via executeProposal) ---

    // 18. Update Decay Rate
    function updateDecayRate(uint256 newRate) public onlyDAO {
        uint256 oldRate = decayRate;
        decayRate = newRate;
        emit ParameterUpdated("decayRate", oldRate, newRate);
    }

    // 19. Add Observer
    function addObserver(address observer) public onlyDAO {
        require(!isObserver[observer], "Address is already an observer");
        observers.push(observer);
        isObserver[observer] = true;
        emit ObserverAdded(observer);
    }

    // 20. Remove Observer
    function removeObserver(address observer) public onlyDAO {
        require(isObserver[observer], "Address is not an observer");
        isObserver[observer] = false;
        // Removing from array is inefficient, but for a small list is acceptable.
        // Find and remove the observer from the observers array
        for (uint i = 0; i < observers.length; i++) {
            if (observers[i] == observer) {
                observers[i] = observers[observers.length - 1]; // Replace with last element
                observers.pop(); // Remove last element
                break;
            }
        }
        emit ObserverRemoved(observer);
    }

    // 21. Set Fluctuation Weights
    function setFluctuationWeights(uint16[] calldata weights) public onlyDAO {
         uint256 totalWeight = 0;
         for (uint i = 0; i < weights.length; i++) {
             totalWeight += weights[i];
         }
         require(totalWeight > 0, "Total weight must be greater than 0"); // Optional: require total = 10000 for 0-9999 range logic

         fluctuationWeights = weights; // Replace old weights
         emit FluctuationWeightsUpdated(weights);
    }


    // --- Treasury Management ---

    // 22. Deposit to Treasury
    receive() external payable {
        emit TreasuryDeposited(msg.sender, msg.value);
    }

    function depositToTreasury() public payable {
         emit TreasuryDeposited(msg.sender, msg.value);
    }


    // 23. Withdraw from Treasury
    function withdrawFromTreasury(address recipient, uint256 amount) public onlyDAO {
        require(address(this).balance >= amount, "Insufficient treasury balance");
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Withdrawal failed");
        emit TreasuryWithdrawn(recipient, amount);
    }

    // 24. Get Treasury Balance
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Getters & Utilities ---

    // 25. Get QFT Balance
    function getQFTBalance(address account) public view returns (uint256) {
        return qftToken.balanceOf(account);
    }

    // 26. Get Particle Owner
    function getParticleOwner(uint256 tokenId) public view returns (address) {
         require(particleData[tokenId].creationTime > 0, "Particle does not exist");
        return particleToken.ownerOf(tokenId);
    }

     // 27. Check if Observer
    function isObserver(address account) public view returns (bool) {
        return isObserver[account]; // Directly return from mapping
    }

    // 28. Get Proposal Count
    function getProposalCount() public view returns (uint256) {
        return _nextProposalId;
    }

    // 29. Get Token Addresses
    function getTokenAddresses() public view returns (address _qft, address _particle, address _influencePlaceholder) {
        // Influence is internal, return address(0) or a placeholder
        return (address(qftToken), address(particleToken), address(0));
    }

    // Add more getters for DAO parameters if needed
    // Example: Get observer list (careful with gas for large arrays)
    function getObserverList() public view returns (address[] memory) {
        return observers; // Note: Copying array can be expensive
    }

     // Example: Get fluctuation weights
    function getFluctuationWeights() public view returns (uint16[] memory) {
        return fluctuationWeights; // Copying array can be expensive
    }

    // Total 31 functions including internal ones used in summary, and public getters.


}
```