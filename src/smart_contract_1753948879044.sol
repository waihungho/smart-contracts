Here's a Solidity smart contract focusing on advanced, creative, and trending concepts, while aiming to be distinct from common open-source implementations.

The core idea revolves around a "Cognitive Synthetic Network" where digital entities (Synthetics) evolve based on interactions, possess dynamic "Cognitive Trait Vectors," and contribute to a decentralized "Cognitive Resonance" governance system. It integrates concepts like dynamic NFTs, on-chain "AI-inspired" evolution (deterministic), a unique resource management system, and a novel governance model.

---

## **Cognitive Synthetic Network (CSN) - Contract Outline & Function Summary**

**Contract Name:** `CognitiveSyntheticNetwork`

**Overview:**
The `CognitiveSyntheticNetwork` is a sophisticated decentralized ecosystem for managing dynamic, AI-inspired digital entities called "Synthetics." Each Synthetic is a unique ERC721 token possessing a mutable "Cognitive Trait Vector" (CTV) which evolves based on user interactions and network events. Synthetics consume and produce "Cognitive Energy" (CE), a conceptual on-chain resource essential for their operations and evolution. The network is governed by a "Cognitive Resonance" system, where the collective intelligence and activity of Synthetics drive decision-making.

**Core Concepts:**
1.  **Synthetics (ERC721):** Unique, non-fungible digital entities with evolving attributes.
2.  **Cognitive Trait Vector (CTV):** A dynamic set of numerical attributes for each Synthetic, representing its "cognitive state." These traits change deterministically based on interactions.
3.  **Cognitive Energy (CE):** An internal, conceptual resource (not a separate ERC20) required for Synthetics to perform actions like evolution, fusion, or participation. Users stake ETH/tokens to generate CE.
4.  **Proof-of-Interaction (PoI):** A mechanism to verify and reward meaningful interactions between Synthetics or between a user and a Synthetic.
5.  **Synthetics Genesis Pool:** A decentralized mechanism for users to contribute funds to "bootstrap" the creation of new Synthetics, influenced by collective network needs.
6.  **Cognitive Resonance Governance:** A unique governance model where the collective "cognitive resonance" of active Synthetics determines voting power and proposal outcomes, fostering aligned decision-making.
7.  **Singularity Reserve:** A long-term reserve fund for network sustainability, growth, and potential future upgrades, governed by strict collective resonance.

---

**Function Summary (20+ functions):**

**I. Synthetic Management & Evolution:**
1.  `mintSynthetic(address _to, string memory _tokenURI)`: Creates and mints a new Synthetic (ERC721) to a specified address, initializing its CTV.
2.  `evolveSyntheticTraits(uint256 _syntheticId, bytes32 _interactionType, int256 _intensity)`: Triggers the deterministic evolution of a Synthetic's CTV based on a defined interaction type and intensity. Requires CE.
3.  `fuseSynthetics(uint256 _syntheticId1, uint256 _syntheticId2)`: Combines two existing Synthetics into a new, potentially more powerful one, burning the originals. Requires CE from both.
4.  `getSyntheticData(uint256 _syntheticId)`: Retrieves all core data for a given Synthetic, including its CTV.
5.  `getSyntheticCognitiveTraits(uint256 _syntheticId)`: Returns the current Cognitive Trait Vector for a specific Synthetic.
6.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer function.
7.  `approve(address to, uint256 tokenId)`: Standard ERC721 approval function.
8.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 operator approval function.

**II. Cognitive Energy (CE) Management:**
9.  `stakeForEnergyGeneration(uint256 _amount)`: Allows users to stake a base currency (e.g., ETH via `payable`) to passively generate Cognitive Energy over time.
10. `claimGeneratedEnergy()`: Allows users to claim their accumulated Cognitive Energy based on their stake.
11. `depositCognitiveEnergy(uint256 _syntheticId, uint256 _amount)`: Transfers CE from a user's balance to a specific Synthetic to fuel its operations.
12. `withdrawCognitiveEnergy(uint256 _syntheticId, uint256 _amount)`: Allows the owner to withdraw CE from their Synthetic back to their personal CE balance.
13. `getUserCognitiveEnergyBalance(address _user)`: Returns the total Cognitive Energy balance for a user.

**III. Synthetics Genesis Pool (New Synthetic Creation Protocol):**
14. `depositIntoGenesisPool()`: Allows users to contribute ETH (or other base token) to a pool dedicated to funding the creation of new Synthetics.
15. `initiateSyntheticGenesis(uint256 _contributedValueThreshold)`: A governance-controlled function to trigger the creation of a new batch of Synthetics from the Genesis Pool, once a value threshold is met.
16. `claimGenesisPoolContribution(uint256 _amount)`: Allows contributors to withdraw their stake from the Genesis Pool if not yet used for genesis.

**IV. Cognitive Resonance Governance:**
17. `proposeSystemParameterChange(string memory _description, bytes32 _paramName, int256 _newValue)`: Allows a user with sufficient Cognitive Resonance to propose changes to system parameters.
18. `voteOnProposal(uint256 _proposalId, bool _for)`: Allows Synthetics owners to cast votes on proposals, where voting power is derived from the "Cognitive Resonance" of their Synthetics.
19. `executeProposal(uint256 _proposalId)`: Executes a passed proposal, applying the proposed system parameter changes.
20. `delegateCognitiveResonance(uint256 _syntheticId, address _delegatee)`: Allows a Synthetic owner to delegate its Cognitive Resonance (voting power) to another address.
21. `undelegateCognitiveResonance(uint256 _syntheticId)`: Removes delegation of Cognitive Resonance for a Synthetic.
22. `getCollectiveResonance()`: Returns the total sum of Cognitive Resonance across all active Synthetics in the network.

**V. Proof-of-Interaction (PoI) & Rewards:**
23. `registerInteraction(uint256 _syntheticId1, uint256 _syntheticId2, bytes32 _interactionType, uint256 _value)`: Records and logs an interaction between two Synthetics, potentially triggering trait evolution and rewards.
24. `claimInteractionReward(bytes32 _interactionHash)`: Allows participants in verified interactions to claim rewards in CE or other incentives.

**VI. Singularity Reserve & System Parameters:**
25. `depositIntoSingularityReserve()`: Allows for depositing funds into the long-term sustainability reserve (e.g., a small percentage of CE generation fees, or direct contributions).
26. `withdrawFromSingularityReserve(uint256 _amount)`: Allows withdrawals from the reserve only via successful governance proposals.
27. `updateSystemParameter(bytes32 _paramName, int256 _newValue)`: An internal/governance-only function to update various system parameters (e.g., CE generation rate, fusion cost, genesis threshold).
28. `pauseSystem()`: Emergency function by owner/governance to pause critical operations.
29. `unpauseSystem()`: Emergency function by owner/governance to unpause critical operations.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Using SafeMath explicitly for clarity, though 0.8+ handles overflow

/**
 * @title CognitiveSyntheticNetwork
 * @dev A sophisticated decentralized ecosystem for managing dynamic, AI-inspired digital entities called "Synthetics."
 *      Each Synthetic is a unique ERC721 token possessing a mutable "Cognitive Trait Vector" (CTV) which evolves
 *      based on user interactions and network events. Synthetics consume and produce "Cognitive Energy" (CE).
 *      The network is governed by a "Cognitive Resonance" system.
 */
contract CognitiveSyntheticNetwork is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeMath for int256; // For trait math

    // --- Events ---
    event SyntheticMinted(uint256 indexed syntheticId, address indexed owner, string tokenURI);
    event SyntheticEvolved(uint256 indexed syntheticId, bytes32 indexed interactionType, int256 intensity);
    event SyntheticsFused(uint256 indexed newSyntheticId, uint256 indexed oldSyntheticId1, uint256 indexed oldSyntheticId2);
    event CognitiveEnergyStaked(address indexed staker, uint256 amount);
    event CognitiveEnergyClaimed(address indexed claimant, uint256 amount);
    event CognitiveEnergyDeposited(uint256 indexed syntheticId, address indexed depositor, uint256 amount);
    event CognitiveEnergyWithdrawn(uint256 indexed syntheticId, address indexed withdrawer, uint256 amount);
    event GenesisPoolDeposit(address indexed depositor, uint256 amount);
    event SyntheticGenesisInitiated(uint256 indexed genesisBatchId, uint256 newSyntheticsCount);
    event GenesisPoolContributionClaimed(address indexed claimant, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, bytes32 paramName, int256 newValue);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool decision, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);
    event CognitiveResonanceDelegated(uint256 indexed syntheticId, address indexed delegator, address indexed delegatee);
    event CognitiveResonanceUndelegated(uint256 indexed syntheticId, address indexed delegator);
    event InteractionRegistered(uint256 indexed syntheticId1, uint256 indexed syntheticId2, bytes32 indexed interactionType, uint256 value);
    event InteractionRewardClaimed(address indexed receiver, bytes32 indexed interactionHash, uint256 rewardAmount);
    event SingularityReserveDeposited(address indexed depositor, uint256 amount);
    event SingularityReserveWithdrawn(address indexed recipient, uint256 amount);
    event SystemParameterUpdated(bytes32 indexed paramName, int256 newValue);

    // --- Structs ---

    struct Synthetic {
        uint256 id;
        address owner;
        uint64 creationTimestamp;
        uint64 lastInteractionTimestamp;
        uint256 cognitiveEnergy; // Internal energy balance
        mapping(bytes32 => int256) cognitiveTraitVector; // Dynamic traits
    }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes32 targetParamName; // Parameter to change
        int256 newParamValue;    // New value for the parameter
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 snapshotCollectiveResonance; // Total resonance at proposal creation
        uint64 proposalTimestamp;
        uint64 votingEndTime;
        bool executed;
        bool passed;
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        mapping(address => uint256) votedPower; // Stores the power of the vote
    }

    struct InteractionRecord {
        uint256 syntheticId1;
        uint256 syntheticId2;
        bytes32 interactionType;
        uint256 value; // Contextual value of the interaction
        uint64 timestamp;
        bool claimed; // If reward has been claimed
    }

    // --- State Variables ---

    Counters.Counter private _syntheticIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _genesisBatchIds;

    mapping(uint256 => Synthetic) public synthetics;
    mapping(address => uint256) public userCognitiveEnergyBalances; // User's personal CE balance
    mapping(address => uint256) public userStakedBalance; // Amount staked for CE generation
    mapping(address => uint64) public lastCEClaimTimestamp; // Last time user claimed CE

    uint256 public totalStakedForEnergy;
    uint256 public cognitiveEnergyGenerationRate; // CE per staked unit per second

    uint256 public genesisPoolBalance; // Funds for new synthetic creation
    uint256 public genesisValueThreshold; // Required funds for a new genesis event

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => uint256)) public proposalVotes; // proposalId => voter => voting_power

    mapping(bytes32 => InteractionRecord) public interactionRecords; // Hash of interaction params to record

    mapping(uint256 => address) public syntheticDelegations; // syntheticId => delegatee address

    uint256 public singularityReserveBalance; // Funds for long-term sustainability

    // --- System Parameters (Configurable via Governance) ---
    uint256 public syntheticEvolutionCostCE;
    uint256 public syntheticFusionCostCE;
    uint256 public proposalQuorumPercentage; // % of total resonance needed for quorum
    uint256 public proposalVotingPeriod;    // Seconds for voting
    uint256 public baseCognitiveResonancePerSynthetic; // Base resonance for a synthetic
    uint256 public interactionRewardCE; // CE reward for a verified interaction
    uint256 public minCognitiveResonanceToPropose; // Min resonance required to propose

    // --- Constants for Trait Management ---
    // Example Trait Names (can be extended)
    bytes32 public constant TRAIT_AGILITY = keccak256("AGILITY");
    bytes32 public constant TRAIT_INTELLIGENCE = keccak256("INTELLIGENCE");
    bytes32 public constant TRAIT_RESILIENCE = keccak256("RESILIENCE");
    bytes32 public constant TRAIT_CREATIVITY = keccak256("CREATIVITY");

    // Example Interaction Types
    bytes32 public constant INTERACTION_TRAINING = keccak256("TRAINING");
    bytes32 public constant INTERACTION_EXPLORATION = keccak256("EXPLORATION");
    bytes32 public constant INTERACTION_COLLABORATION = keccak256("COLLABORATION");
    bytes32 public constant INTERACTION_ADVERSARIAL = keccak256("ADVERSARIAL");

    constructor() ERC721("CognitiveSynthetic", "CSN") Ownable(msg.sender) {
        // Initial System Parameters
        cognitiveEnergyGenerationRate = 100; // 100 CE per staked unit per second
        syntheticEvolutionCostCE = 500;
        syntheticFusionCostCE = 1000;
        genesisValueThreshold = 1 ether; // 1 ETH to trigger new genesis batch
        proposalQuorumPercentage = 20;  // 20% of total resonance
        proposalVotingPeriod = 3 days;  // 3 days for voting
        baseCognitiveResonancePerSynthetic = 1000; // Base resonance for each synthetic
        interactionRewardCE = 100;
        minCognitiveResonanceToPropose = 5000; // Requires 5000 resonance to propose
    }

    // --- Modifiers ---
    modifier onlySyntheticOwner(uint256 _syntheticId) {
        require(_isApprovedOrOwner(msg.sender, _syntheticId), "CSN: Caller is not synthetic owner nor approved");
        _;
    }

    modifier syntheticExists(uint256 _syntheticId) {
        require(_exists(_syntheticId), "CSN: Synthetic does not exist");
        _;
    }

    // --- I. Synthetic Management & Evolution ---

    /**
     * @dev Creates and mints a new Synthetic (ERC721) to a specified address.
     *      Initializes its Cognitive Trait Vector (CTV) with random-ish values.
     * @param _to The address to mint the Synthetic to.
     * @param _tokenURI The URI for the Synthetic's metadata.
     */
    function mintSynthetic(address _to, string memory _tokenURI) public onlyOwner whenNotPaused returns (uint256) {
        _syntheticIds.increment();
        uint256 newId = _syntheticIds.current();

        synthetics[newId].id = newId;
        synthetics[newId].owner = _to;
        synthetics[newId].creationTimestamp = uint64(block.timestamp);
        synthetics[newId].lastInteractionTimestamp = uint64(block.timestamp);
        synthetics[newId].cognitiveEnergy = 0; // Starts with no energy

        // Initialize CTV with pseudo-random values
        synthetics[newId].cognitiveTraitVector[TRAIT_AGILITY] = _generateInitialTraitValue(newId, TRAIT_AGILITY);
        synthetics[newId].cognitiveTraitVector[TRAIT_INTELLIGENCE] = _generateInitialTraitValue(newId, TRAIT_INTELLIGENCE);
        synthetics[newId].cognitiveTraitVector[TRAIT_RESILIENCE] = _generateInitialTraitValue(newId, TRAIT_RESILIENCE);
        synthetics[newId].cognitiveTraitVector[TRAIT_CREATIVITY] = _generateInitialTraitValue(newId, TRAIT_CREATIVITY);

        _safeMint(_to, newId);
        _setTokenURI(newId, _tokenURI);

        emit SyntheticMinted(newId, _to, _tokenURI);
        return newId;
    }

    /**
     * @dev Triggers the deterministic evolution of a Synthetic's CTV based on a defined interaction.
     *      Requires Cognitive Energy (CE) to perform the evolution.
     * @param _syntheticId The ID of the Synthetic to evolve.
     * @param _interactionType A bytes32 identifier for the type of interaction (e.g., TRAINING, EXPLORATION).
     * @param _intensity An integer representing the intensity or impact of the interaction (can be positive or negative).
     */
    function evolveSyntheticTraits(uint256 _syntheticId, bytes32 _interactionType, int256 _intensity)
        public
        whenNotPaused
        onlySyntheticOwner(_syntheticId)
        syntheticExists(_syntheticId)
    {
        require(synthetics[_syntheticId].cognitiveEnergy >= syntheticEvolutionCostCE, "CSN: Insufficient Cognitive Energy for evolution");

        synthetics[_syntheticId].cognitiveEnergy = synthetics[_syntheticId].cognitiveEnergy.sub(syntheticEvolutionCostCE);
        synthetics[_syntheticId].lastInteractionTimestamp = uint64(block.timestamp);

        _applyTraitEvolution(_syntheticId, _interactionType, _intensity);

        emit SyntheticEvolved(_syntheticId, _interactionType, _intensity);
    }

    /**
     * @dev Combines two existing Synthetics into a new one, burning the originals.
     *      The new Synthetic's CTV is an average or combination of the originals.
     *      Requires Cognitive Energy from both Synthetics.
     * @param _syntheticId1 The ID of the first Synthetic.
     * @param _syntheticId2 The ID of the second Synthetic.
     */
    function fuseSynthetics(uint256 _syntheticId1, uint256 _syntheticId2) public whenNotPaused {
        require(_syntheticId1 != _syntheticId2, "CSN: Cannot fuse a synthetic with itself");
        require(_isApprovedOrOwner(msg.sender, _syntheticId1), "CSN: Caller not owner/approved for synthetic 1");
        require(_isApprovedOrOwner(msg.sender, _syntheticId2), "CSN: Caller not owner/approved for synthetic 2");
        require(synthetics[_syntheticId1].cognitiveEnergy >= syntheticFusionCostCE, "CSN: Synthetic 1 has insufficient CE for fusion");
        require(synthetics[_syntheticId2].cognitiveEnergy >= syntheticFusionCostCE, "CSN: Synthetic 2 has insufficient CE for fusion");

        synthetics[_syntheticId1].cognitiveEnergy = synthetics[_syntheticId1].cognitiveEnergy.sub(syntheticFusionCostCE);
        synthetics[_syntheticId2].cognitiveEnergy = synthetics[_syntheticId2].cognitiveEnergy.sub(syntheticFusionCostCE);

        // Logic for creating new combined synthetic
        _syntheticIds.increment();
        uint256 newId = _syntheticIds.current();
        address newOwner = msg.sender; // Owner of the fusion

        synthetics[newId].id = newId;
        synthetics[newId].owner = newOwner;
        synthetics[newId].creationTimestamp = uint64(block.timestamp);
        synthetics[newId].lastInteractionTimestamp = uint64(block.timestamp);
        synthetics[newId].cognitiveEnergy = 0; // Starts with no energy

        // Average or combine traits
        synthetics[newId].cognitiveTraitVector[TRAIT_AGILITY] = (synthetics[_syntheticId1].cognitiveTraitVector[TRAIT_AGILITY] + synthetics[_syntheticId2].cognitiveTraitVector[TRAIT_AGILITY]) / 2;
        synthetics[newId].cognitiveTraitVector[TRAIT_INTELLIGENCE] = (synthetics[_syntheticId1].cognitiveTraitVector[TRAIT_INTELLIGENCE] + synthetics[_syntheticId2].cognitiveTraitVector[TRAIT_INTELLIGENCE]) / 2;
        synthetics[newId].cognitiveTraitVector[TRAIT_RESILIENCE] = (synthetics[_syntheticId1].cognitiveTraitVector[TRAIT_RESILIENCE] + synthetics[_syntheticId2].cognitiveTraitVector[TRAIT_RESILIENCE]) / 2;
        synthetics[newId].cognitiveTraitVector[TRAIT_CREATIVITY] = (synthetics[_syntheticId1].cognitiveTraitVector[TRAIT_CREATIVITY] + synthetics[_syntheticId2].cognitiveTraitVector[TRAIT_CREATIVITY]) / 2;

        _safeMint(newOwner, newId);
        // _setTokenURI(newId, _generateFusionTokenURI(_syntheticId1, _syntheticId2)); // Placeholder for generating new URI

        _burn(_syntheticId1);
        _burn(_syntheticId2);

        emit SyntheticsFused(newId, _syntheticId1, _syntheticId2);
    }

    /**
     * @dev Returns all core data for a given Synthetic.
     * @param _syntheticId The ID of the Synthetic.
     * @return A tuple containing the Synthetic's ID, owner, creation timestamp, last interaction timestamp, and CE balance.
     */
    function getSyntheticData(uint256 _syntheticId)
        public
        view
        syntheticExists(_syntheticId)
        returns (
            uint256 id,
            address owner,
            uint64 creationTimestamp,
            uint64 lastInteractionTimestamp,
            uint256 cognitiveEnergy
        )
    {
        Synthetic storage s = synthetics[_syntheticId];
        return (s.id, s.owner, s.creationTimestamp, s.lastInteractionTimestamp, s.cognitiveEnergy);
    }

    /**
     * @dev Returns the current Cognitive Trait Vector for a specific Synthetic.
     * @param _syntheticId The ID of the Synthetic.
     * @return A tuple containing the values for Agility, Intelligence, Resilience, and Creativity.
     */
    function getSyntheticCognitiveTraits(uint256 _syntheticId)
        public
        view
        syntheticExists(_syntheticId)
        returns (int256 agility, int256 intelligence, int256 resilience, int256 creativity)
    {
        Synthetic storage s = synthetics[_syntheticId];
        return (
            s.cognitiveTraitVector[TRAIT_AGILITY],
            s.cognitiveTraitVector[TRAIT_INTELLIGENCE],
            s.cognitiveTraitVector[TRAIT_RESILIENCE],
            s.cognitiveTraitVector[TRAIT_CREATIVITY]
        );
    }

    // --- II. Cognitive Energy (CE) Management ---

    /**
     * @dev Allows users to stake a base currency (ETH) to passively generate Cognitive Energy over time.
     */
    function stakeForEnergyGeneration() public payable whenNotPaused {
        require(msg.value > 0, "CSN: Stake amount must be greater than zero");
        userStakedBalance[msg.sender] = userStakedBalance[msg.sender].add(msg.value);
        totalStakedForEnergy = totalStakedForEnergy.add(msg.value);
        lastCEClaimTimestamp[msg.sender] = uint64(block.timestamp); // Reset claim time on new stake

        emit CognitiveEnergyStaked(msg.sender, msg.value);
    }

    /**
     * @dev Allows users to claim their accumulated Cognitive Energy based on their stake.
     */
    function claimGeneratedEnergy() public whenNotPaused {
        uint256 availableCE = _calculateAvailableCE(msg.sender);
        require(availableCE > 0, "CSN: No Cognitive Energy available to claim");

        userCognitiveEnergyBalances[msg.sender] = userCognitiveEnergyBalances[msg.sender].add(availableCE);
        lastCEClaimTimestamp[msg.sender] = uint64(block.timestamp);

        emit CognitiveEnergyClaimed(msg.sender, availableCE);
    }

    /**
     * @dev Transfers CE from a user's balance to a specific Synthetic to fuel its operations.
     * @param _syntheticId The ID of the Synthetic to deposit CE into.
     * @param _amount The amount of CE to deposit.
     */
    function depositCognitiveEnergy(uint256 _syntheticId, uint256 _amount)
        public
        whenNotPaused
        onlySyntheticOwner(_syntheticId)
        syntheticExists(_syntheticId)
    {
        require(_amount > 0, "CSN: Deposit amount must be greater than zero");
        require(userCognitiveEnergyBalances[msg.sender] >= _amount, "CSN: Insufficient personal Cognitive Energy");

        userCognitiveEnergyBalances[msg.sender] = userCognitiveEnergyBalances[msg.sender].sub(_amount);
        synthetics[_syntheticId].cognitiveEnergy = synthetics[_syntheticId].cognitiveEnergy.add(_amount);

        emit CognitiveEnergyDeposited(_syntheticId, msg.sender, _amount);
    }

    /**
     * @dev Allows the owner to withdraw CE from their Synthetic back to their personal CE balance.
     * @param _syntheticId The ID of the Synthetic to withdraw CE from.
     * @param _amount The amount of CE to withdraw.
     */
    function withdrawCognitiveEnergy(uint256 _syntheticId, uint256 _amount)
        public
        whenNotPaused
        onlySyntheticOwner(_syntheticId)
        syntheticExists(_syntheticId)
    {
        require(_amount > 0, "CSN: Withdrawal amount must be greater than zero");
        require(synthetics[_syntheticId].cognitiveEnergy >= _amount, "CSN: Synthetic has insufficient Cognitive Energy");

        synthetics[_syntheticId].cognitiveEnergy = synthetics[_syntheticId].cognitiveEnergy.sub(_amount);
        userCognitiveEnergyBalances[msg.sender] = userCognitiveEnergyBalances[msg.sender].add(_amount);

        emit CognitiveEnergyWithdrawn(_syntheticId, msg.sender, _amount);
    }

    /**
     * @dev Returns the total Cognitive Energy balance for a user.
     * @param _user The address of the user.
     * @return The user's total Cognitive Energy balance.
     */
    function getUserCognitiveEnergyBalance(address _user) public view returns (uint256) {
        return userCognitiveEnergyBalances[_user].add(_calculateAvailableCE(_user));
    }

    /**
     * @dev Internal function to calculate available CE for a user since last claim.
     */
    function _calculateAvailableCE(address _user) internal view returns (uint256) {
        uint256 staked = userStakedBalance[_user];
        if (staked == 0) return 0;

        uint256 timeElapsed = block.timestamp.sub(lastCEClaimTimestamp[_user]);
        return staked.mul(cognitiveEnergyGenerationRate).mul(timeElapsed).div(10**18); // Assumes staked amount is in wei, CE rate is per second
    }

    // --- III. Synthetics Genesis Pool (New Synthetic Creation Protocol) ---

    /**
     * @dev Allows users to contribute ETH to a pool dedicated to funding the creation of new Synthetics.
     */
    function depositIntoGenesisPool() public payable whenNotPaused {
        require(msg.value > 0, "CSN: Deposit amount must be greater than zero");
        genesisPoolBalance = genesisPoolBalance.add(msg.value);
        emit GenesisPoolDeposit(msg.sender, msg.value);
    }

    /**
     * @dev A governance-controlled function to trigger the creation of a new batch of Synthetics from the Genesis Pool.
     *      Can only be called if governance proposal passes. This function would typically be called by the `executeProposal`
     *      function after a successful genesis proposal.
     * @param _contributedValueThreshold The threshold of funds required in the genesis pool to initiate the genesis.
     *        This parameter should match what was approved in the governance proposal.
     */
    function initiateSyntheticGenesis(uint256 _contributedValueThreshold) public onlyOwner whenNotPaused {
        // This function is intended to be called by governance / owner after a proposal approves it.
        // For a public function, it would need more strict access control,
        // or integrate directly into proposal execution logic.
        require(genesisPoolBalance >= _contributedValueThreshold, "CSN: Genesis pool balance below threshold");
        require(_contributedValueThreshold == genesisValueThreshold, "CSN: Threshold mismatch with current system parameter");

        _genesisBatchIds.increment();
        uint256 currentBatchId = _genesisBatchIds.current();

        uint256 fundsToUse = genesisPoolBalance; // Use all available for genesis
        genesisPoolBalance = 0; // Reset pool after use

        // Determine how many new synthetics can be created based on funds and a conceptual cost per synthetic
        // Example: 0.1 ETH per synthetic, so 1 ETH in pool creates 10 synthetics
        uint256 conceptualCostPerSynthetic = 0.1 ether;
        uint256 newSyntheticsCount = fundsToUse.div(conceptualCostPerSynthetic);
        require(newSyntheticsCount > 0, "CSN: Not enough funds to create any new synthetics");

        // Mint new synthetics to owner (or a specified genesis address)
        for (uint256 i = 0; i < newSyntheticsCount; i++) {
            _syntheticIds.increment();
            uint256 newId = _syntheticIds.current();
            address genesisOwner = owner(); // Or a specific 'genesisWallet' address

            synthetics[newId].id = newId;
            synthetics[newId].owner = genesisOwner;
            synthetics[newId].creationTimestamp = uint64(block.timestamp);
            synthetics[newId].lastInteractionTimestamp = uint64(block.timestamp);
            synthetics[newId].cognitiveEnergy = 0;

            synthetics[newId].cognitiveTraitVector[TRAIT_AGILITY] = _generateInitialTraitValue(newId, TRAIT_AGILITY);
            synthetics[newId].cognitiveTraitVector[TRAIT_INTELLIGENCE] = _generateInitialTraitValue(newId, TRAIT_INTELLIGENCE);
            synthetics[newId].cognitiveTraitVector[TRAIT_RESILIENCE] = _generateInitialTraitValue(newId, TRAIT_RESILIENCE);
            synthetics[newId].cognitiveTraitVector[TRAIT_CREATIVITY] = _generateInitialTraitValue(newId, TRAIT_CREATIVITY);

            _safeMint(genesisOwner, newId);
            // _setTokenURI(newId, _generateGenesisTokenURI(newId)); // Placeholder
        }

        emit SyntheticGenesisInitiated(currentBatchId, newSyntheticsCount);
    }


    /**
     * @dev Allows contributors to withdraw their stake from the Genesis Pool if not yet used for genesis.
     * @param _amount The amount to claim.
     */
    function claimGenesisPoolContribution(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "CSN: Claim amount must be greater than zero");
        require(genesisPoolBalance >= _amount, "CSN: Insufficient funds in Genesis Pool or invalid amount");

        genesisPoolBalance = genesisPoolBalance.sub(_amount);
        payable(msg.sender).transfer(_amount); // Transfer ETH back

        emit GenesisPoolContributionClaimed(msg.sender, _amount);
    }

    // --- IV. Cognitive Resonance Governance ---

    /**
     * @dev Allows a user with sufficient Cognitive Resonance to propose changes to system parameters.
     * @param _description A description of the proposal.
     * @param _paramName The name of the system parameter to change (e.g., keccak256("GENESIS_THRESHOLD")).
     * @param _newValue The new value for the parameter.
     */
    function proposeSystemParameterChange(string memory _description, bytes32 _paramName, int256 _newValue) public whenNotPaused {
        uint256 proposerResonance = _getAccountCognitiveResonance(msg.sender);
        require(proposerResonance >= minCognitiveResonanceToPropose, "CSN: Not enough Cognitive Resonance to propose");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            description: _description,
            targetParamName: _paramName,
            newParamValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            snapshotCollectiveResonance: _getCollectiveResonance(), // Snapshot at creation
            proposalTimestamp: uint64(block.timestamp),
            votingEndTime: uint64(block.timestamp) + uint64(proposalVotingPeriod),
            executed: false,
            passed: false,
            hasVoted: new mapping(address => bool),
            votedPower: new mapping(address => uint256)
        });

        emit ProposalCreated(newProposalId, msg.sender, _description, _paramName, _newValue);
    }

    /**
     * @dev Allows Synthetics owners to cast votes on proposals, where voting power is derived from the "Cognitive Resonance" of their Synthetics.
     *      Uses a "quadratic voting" inspired model: voting power is sqrt of resonance.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _for) public whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "CSN: Proposal does not exist");
        require(block.timestamp <= p.votingEndTime, "CSN: Voting period has ended");
        require(!p.hasVoted[msg.sender], "CSN: Already voted on this proposal");

        uint256 voterResonance = _getAccountCognitiveResonance(msg.sender);
        require(voterResonance > 0, "CSN: No Cognitive Resonance to vote");

        // Quadratic voting: voting power is sqrt of resonance
        uint256 votingPower = _sqrt(voterResonance);

        if (_for) {
            p.votesFor = p.votesFor.add(votingPower);
        } else {
            p.votesAgainst = p.votesAgainst.add(votingPower);
        }
        p.hasVoted[msg.sender] = true;
        p.votedPower[msg.sender] = votingPower;

        emit VoteCast(_proposalId, msg.sender, _for, votingPower);
    }

    /**
     * @dev Executes a passed proposal, applying the proposed system parameter changes.
     *      Can be called by anyone after the voting period ends and quorum/majority is met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public whenNotPaused {
        Proposal storage p = proposals[_proposalId];
        require(p.id != 0, "CSN: Proposal does not exist");
        require(block.timestamp > p.votingEndTime, "CSN: Voting period has not ended yet");
        require(!p.executed, "CSN: Proposal already executed");

        uint256 totalVotes = p.votesFor.add(p.votesAgainst);
        require(totalVotes > 0, "CSN: No votes cast for this proposal");

        // Quorum check: total votes must meet a percentage of snapshot resonance
        require(totalVotes.mul(100) >= p.snapshotCollectiveResonance.mul(proposalQuorumPercentage), "CSN: Quorum not met");

        // Majority check
        if (p.votesFor > p.votesAgainst) {
            p.passed = true;
            _updateSystemParameter(p.targetParamName, p.newParamValue);
        } else {
            p.passed = false;
        }

        p.executed = true;
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Allows a Synthetic owner to delegate its Cognitive Resonance (voting power) to another address.
     * @param _syntheticId The ID of the Synthetic whose resonance is being delegated.
     * @param _delegatee The address to delegate the resonance to.
     */
    function delegateCognitiveResonance(uint256 _syntheticId, address _delegatee)
        public
        whenNotPaused
        onlySyntheticOwner(_syntheticId)
        syntheticExists(_syntheticId)
    {
        require(_delegatee != address(0), "CSN: Delegatee cannot be zero address");
        require(_delegatee != ownerOf(_syntheticId), "CSN: Cannot delegate to self"); // Avoid self-delegation loop
        syntheticDelegations[_syntheticId] = _delegatee;
        emit CognitiveResonanceDelegated(_syntheticId, ownerOf(_syntheticId), _delegatee);
    }

    /**
     * @dev Removes delegation of Cognitive Resonance for a Synthetic.
     * @param _syntheticId The ID of the Synthetic whose delegation is being removed.
     */
    function undelegateCognitiveResonance(uint256 _syntheticId)
        public
        whenNotPaused
        onlySyntheticOwner(_syntheticId)
        syntheticExists(_syntheticId)
    {
        delete syntheticDelegations[_syntheticId]; // Set delegatee to address(0)
        emit CognitiveResonanceUndelegated(_syntheticId, ownerOf(_syntheticId));
    }

    /**
     * @dev Returns the total sum of Cognitive Resonance across all active Synthetics in the network.
     * @return The total collective Cognitive Resonance.
     */
    function getCollectiveResonance() public view returns (uint256) {
        return _getCollectiveResonance();
    }

    // Internal helper for collective resonance (can be optimized for large numbers of synthetics)
    function _getCollectiveResonance() internal view returns (uint256) {
        uint256 totalResonance = 0;
        for (uint256 i = 1; i <= _syntheticIds.current(); i++) {
            if (_exists(i)) { // Check if synthetic exists and hasn't been burned
                 totalResonance = totalResonance.add(_getSyntheticCognitiveResonance(i));
            }
        }
        return totalResonance;
    }

    // Helper to get resonance for a specific synthetic, considering traits
    function _getSyntheticCognitiveResonance(uint256 _syntheticId) internal view returns (uint256) {
        if (!_exists(_syntheticId)) return 0;
        Synthetic storage s = synthetics[_syntheticId];
        // Example: Resonance based on a weighted sum of traits + base
        uint256 traitSum = uint256(s.cognitiveTraitVector[TRAIT_AGILITY] > 0 ? s.cognitiveTraitVector[TRAIT_AGILITY] : 0) // Only positive traits contribute
                           .add(uint256(s.cognitiveTraitVector[TRAIT_INTELLIGENCE] > 0 ? s.cognitiveTraitVector[TRAIT_INTELLIGENCE] : 0))
                           .add(uint256(s.cognitiveTraitVector[TRAIT_RESILIENCE] > 0 ? s.cognitiveTraitVector[TRAIT_RESILIENCE] : 0))
                           .add(uint256(s.cognitiveTraitVector[TRAIT_CREATIVITY] > 0 ? s.cognitiveTraitVector[TRAIT_CREATIVITY] : 0));

        return baseCognitiveResonancePerSynthetic.add(traitSum.div(100)); // Divide by 100 to scale down trait influence
    }

    // Helper to get an account's total resonance (including delegated)
    function _getAccountCognitiveResonance(address _account) internal view returns (uint256) {
        uint256 totalResonance = 0;
        for (uint256 i = 1; i <= _syntheticIds.current(); i++) {
            if (_exists(i)) {
                address syntheticOwner = ownerOf(i);
                address currentDelegatee = syntheticDelegations[i];

                if (syntheticOwner == _account || currentDelegatee == _account) {
                    totalResonance = totalResonance.add(_getSyntheticCognitiveResonance(i));
                }
            }
        }
        return totalResonance;
    }

    // --- V. Proof-of-Interaction (PoI) & Rewards ---

    /**
     * @dev Records and logs an interaction between two Synthetics (or a Synthetic and an external entity).
     *      This function could be called by a trusted oracle or specific DApp logic, not directly by users for *arbitrary* interactions.
     *      It triggers trait evolution and sets up a potential reward claim.
     * @param _syntheticId1 The ID of the primary Synthetic involved.
     * @param _syntheticId2 The ID of the secondary Synthetic involved (can be 0 if only one synthetic).
     * @param _interactionType The type of interaction (e.g., GAME_COMPLETION, DATA_EXCHANGE).
     * @param _value A contextual value associated with the interaction (e.g., score, data size).
     */
    function registerInteraction(uint256 _syntheticId1, uint256 _syntheticId2, bytes32 _interactionType, uint256 _value) public whenNotPaused onlyOwner {
        // This function assumes it's called by an authorized entity (e.g., the contract owner, representing a PoI oracle/service)
        // In a real decentralized system, this would involve a more robust PoI mechanism (e.g., verifiable computation, trusted relayer network, or consensus among participants).
        require(syntheticExists(_syntheticId1), "CSN: Synthetic 1 does not exist");
        if (_syntheticId2 != 0) {
            require(syntheticExists(_syntheticId2), "CSN: Synthetic 2 does not exist");
        }

        // Apply trait evolution based on interaction
        _applyTraitEvolution(_syntheticId1, _interactionType, int256(_value)); // Value can influence intensity
        if (_syntheticId2 != 0) {
            _applyTraitEvolution(_syntheticId2, _interactionType, int256(_value));
        }

        bytes32 interactionHash = keccak256(abi.encodePacked(_syntheticId1, _syntheticId2, _interactionType, _value, block.timestamp));
        require(interactionRecords[interactionHash].timestamp == 0, "CSN: Interaction already registered");

        interactionRecords[interactionHash] = InteractionRecord({
            syntheticId1: _syntheticId1,
            syntheticId2: _syntheticId2,
            interactionType: _interactionType,
            value: _value,
            timestamp: uint64(block.timestamp),
            claimed: false
        });

        emit InteractionRegistered(_syntheticId1, _syntheticId2, _interactionType, _value);
    }

    /**
     * @dev Allows participants in verified interactions to claim rewards in CE.
     * @param _interactionHash The unique hash identifying the registered interaction.
     */
    function claimInteractionReward(bytes32 _interactionHash) public whenNotPaused {
        InteractionRecord storage record = interactionRecords[_interactionHash];
        require(record.timestamp != 0, "CSN: Interaction record not found");
        require(!record.claimed, "CSN: Reward already claimed for this interaction");
        require(ownerOf(record.syntheticId1) == msg.sender || (record.syntheticId2 != 0 && ownerOf(record.syntheticId2) == msg.sender), "CSN: Not a participant in this interaction");

        record.claimed = true;
        userCognitiveEnergyBalances[msg.sender] = userCognitiveEnergyBalances[msg.sender].add(interactionRewardCE);

        emit InteractionRewardClaimed(msg.sender, _interactionHash, interactionRewardCE);
    }

    // --- VI. Singularity Reserve & System Parameters ---

    /**
     * @dev Allows for depositing funds into the long-term sustainability reserve.
     *      Can be called by anyone, or automatically via governance/fees.
     */
    function depositIntoSingularityReserve() public payable whenNotPaused {
        require(msg.value > 0, "CSN: Deposit amount must be greater than zero");
        singularityReserveBalance = singularityReserveBalance.add(msg.value);
        emit SingularityReserveDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Allows withdrawals from the reserve only via successful governance proposals.
     *      This function is called internally by `executeProposal` if a withdrawal proposal passes.
     * @param _amount The amount to withdraw.
     * @param _recipient The address to send the funds to.
     */
    function withdrawFromSingularityReserve(uint256 _amount, address _recipient) public onlyOwner whenNotPaused {
        // Only owner can call, implying it's called through governance execution flow.
        require(_amount > 0, "CSN: Withdrawal amount must be greater than zero");
        require(singularityReserveBalance >= _amount, "CSN: Insufficient funds in Singularity Reserve");
        require(_recipient != address(0), "CSN: Recipient cannot be zero address");

        singularityReserveBalance = singularityReserveBalance.sub(_amount);
        payable(_recipient).transfer(_amount);
        emit SingularityReserveWithdrawn(_recipient, _amount);
    }

    /**
     * @dev Updates various system parameters based on governance decisions.
     *      This function is called internally by `executeProposal`.
     * @param _paramName The name of the parameter to update (e.g., keccak256("CE_RATE")).
     * @param _newValue The new value for the parameter.
     */
    function _updateSystemParameter(bytes32 _paramName, int256 _newValue) internal {
        // Use a switch or if-else structure for known parameters
        if (_paramName == keccak256("CE_GENERATION_RATE")) {
            require(_newValue >= 0, "CSN: CE rate cannot be negative");
            cognitiveEnergyGenerationRate = uint256(_newValue);
        } else if (_paramName == keccak256("SYNTH_EVOLUTION_COST")) {
            require(_newValue >= 0, "CSN: Evolution cost cannot be negative");
            syntheticEvolutionCostCE = uint256(_newValue);
        } else if (_paramName == keccak256("SYNTH_FUSION_COST")) {
            require(_newValue >= 0, "CSN: Fusion cost cannot be negative");
            syntheticFusionCostCE = uint256(_newValue);
        } else if (_paramName == keccak256("GENESIS_THRESHOLD")) {
            require(_newValue >= 0, "CSN: Genesis threshold cannot be negative");
            genesisValueThreshold = uint256(_newValue);
        } else if (_paramName == keccak256("PROPOSAL_QUORUM")) {
            require(_newValue >= 0 && _newValue <= 100, "CSN: Quorum must be 0-100");
            proposalQuorumPercentage = uint256(_newValue);
        } else if (_paramName == keccak256("VOTING_PERIOD")) {
            require(_newValue > 0, "CSN: Voting period must be positive");
            proposalVotingPeriod = uint256(_newValue);
        } else if (_paramName == keccak256("BASE_SYNTH_RESONANCE")) {
            require(_newValue >= 0, "CSN: Base resonance cannot be negative");
            baseCognitiveResonancePerSynthetic = uint256(_newValue);
        } else if (_paramName == keccak256("INTERACTION_REWARD_CE")) {
            require(_newValue >= 0, "CSN: Interaction reward cannot be negative");
            interactionRewardCE = uint256(_newValue);
        } else if (_paramName == keccak256("MIN_RESONANCE_TO_PROPOSE")) {
            require(_newValue >= 0, "CSN: Min resonance to propose cannot be negative");
            minCognitiveResonanceToPropose = uint256(_newValue);
        } else {
            revert("CSN: Unknown system parameter");
        }
        emit SystemParameterUpdated(_paramName, _newValue);
    }

    /**
     * @dev Pauses the contract, disabling most state-changing functions.
     *      Only callable by the contract owner.
     */
    function pauseSystem() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, enabling all functions again.
     *      Only callable by the contract owner.
     */
    function unpauseSystem() public onlyOwner whenPaused {
        _unpause();
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Deterministically applies evolution to a Synthetic's traits.
     *      This is where the "AI-inspired" logic resides.
     *      More complex algorithms could be used here.
     * @param _syntheticId The ID of the Synthetic.
     * @param _interactionType The type of interaction that triggered evolution.
     * @param _intensity The intensity of the interaction.
     */
    function _applyTraitEvolution(uint256 _syntheticId, bytes32 _interactionType, int256 _intensity) internal {
        Synthetic storage s = synthetics[_syntheticId];

        // Example: Simple rule-based trait evolution
        if (_interactionType == INTERACTION_TRAINING) {
            s.cognitiveTraitVector[TRAIT_INTELLIGENCE] = s.cognitiveTraitVector[TRAIT_INTELLIGENCE].add(_intensity);
            s.cognitiveTraitVector[TRAIT_AGILITY] = s.cognitiveTraitVector[TRAIT_AGILITY].add(_intensity.div(2)); // Less impact
            s.cognitiveTraitVector[TRAIT_RESILIENCE] = s.cognitiveTraitVector[TRAIT_RESILIENCE].sub(_intensity.div(4)); // Small cost
        } else if (_interactionType == INTERACTION_EXPLORATION) {
            s.cognitiveTraitVector[TRAIT_CREATIVITY] = s.cognitiveTraitVector[TRAIT_CREATIVITY].add(_intensity);
            s.cognitiveTraitVector[TRAIT_RESILIENCE] = s.cognitiveTraitVector[TRAIT_RESILIENCE].add(_intensity.div(2));
        } else if (_interactionType == INTERACTION_COLLABORATION) {
            s.cognitiveTraitVector[TRAIT_INTELLIGENCE] = s.cognitiveTraitVector[TRAIT_INTELLIGENCE].add(_intensity.div(2));
            s.cognitiveTraitVector[TRAIT_CREATIVITY] = s.cognitiveTraitVector[TRAIT_CREATIVITY].add(_intensity.div(2));
            s.cognitiveTraitVector[TRAIT_AGILITY] = s.cognitiveTraitVector[TRAIT_AGILITY].add(_intensity.div(4));
        } else if (_interactionType == INTERACTION_ADVERSARIAL) {
            s.cognitiveTraitVector[TRAIT_RESILIENCE] = s.cognitiveTraitVector[TRAIT_RESILIENCE].add(_intensity);
            s.cognitiveTraitVector[TRAIT_AGILITY] = s.cognitiveTraitVector[TRAIT_AGILITY].add(_intensity.div(2));
            s.cognitiveTraitVector[TRAIT_INTELLIGENCE] = s.cognitiveTraitVector[TRAIT_INTELLIGENCE].sub(_intensity.div(4)); // Potential cost
        }
        // Add more complex rules, bounds, decay, or interaction matrices for traits.

        // Ensure traits stay within a reasonable range (e.g., -1000 to 1000)
        s.cognitiveTraitVector[TRAIT_AGILITY] = _clampTraitValue(s.cognitiveTraitVector[TRAIT_AGILITY]);
        s.cognitiveTraitVector[TRAIT_INTELLIGENCE] = _clampTraitValue(s.cognitiveTraitVector[TRAIT_INTELLIGENCE]);
        s.cognitiveTraitVector[TRAIT_RESILIENCE] = _clampTraitValue(s.cognitiveTraitVector[TRAIT_RESILIENCE]);
        s.cognitiveTraitVector[TRAIT_CREATIVITY] = _clampTraitValue(s.cognitiveTraitVector[TRAIT_CREATIVITY]);
    }

    /**
     * @dev Generates an initial trait value with pseudo-randomness.
     *      Uses block data and synthetic ID for variability.
     *      Not cryptographically secure randomness, but sufficient for game-like traits.
     */
    function _generateInitialTraitValue(uint256 _syntheticId, bytes32 _traitType) internal view returns (int256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender, _syntheticId, _traitType)));
        return int224(seed % 200) - 100; // Value between -100 and +99
    }

    /**
     * @dev Clamps a trait value within a defined range (e.g., -500 to 500).
     */
    function _clampTraitValue(int256 _value) internal pure returns (int256) {
        int256 min = -500;
        int256 max = 500;
        if (_value < min) return min;
        if (_value > max) return max;
        return _value;
    }

    /**
     * @dev Calculates the integer square root of a number.
     *      Used for quadratic voting power.
     *      Source: https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Binary_longhand_method
     */
    function _sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
```