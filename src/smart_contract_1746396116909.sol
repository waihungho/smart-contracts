Okay, let's design a smart contract system that involves dynamic NFTs ("Digital Entities"), a fungible resource token, dual staking (both NFT and fungible), and simple on-chain governance for parameter tuning. This combines several advanced concepts: dynamic state, complex tokenomics, NFT utility beyond ownership, staking rewards, and decentralized control.

We will call the contract `GenesisEngine`. It manages `DigitalEntity` NFTs and `Essence` tokens.

---

## GenesisEngine Smart Contract Outline & Function Summary

**Contract Name:** `GenesisEngine`

**Core Concept:** A system managing dynamic Digital Entities (NFTs) that evolve, require maintenance, can interact, be bred/mutated, and provide yield through staking, powered by an `Essence` resource token and governed by staked assets.

**Key Features:**
*   **Dynamic NFTs (`DigitalEntity`):** NFTs with mutable attributes (e.g., Strength, Purity, Energy) that change based on time, user actions (training, feeding), and interactions.
*   **Resource Token (`Essence`):** An ERC-20 token used for creating, training, feeding, and breeding Entities, and also earnable through staking and other activities.
*   **Time-Based Decay:** Entity attributes degrade over time, requiring `Essence` for maintenance (feeding/training).
*   **Breeding & Mutation:** Combine entities to create new ones with inherited and potentially mutated attributes.
*   **State Transition (`Awakening`):** Entities can reach a mature state ("Awakened"), locking certain dynamics and enabling staking.
*   **Dual Staking:** Stake Awakened Digital Entities and/or `Essence` tokens to earn `Essence` yield.
*   **Simulated Interactions/Quests:** Functions simulating challenges where Entity attributes influence probabilistic outcomes, yielding rewards or penalties.
*   **On-Chain Governance (Simple):** Staked assets grant voting power to propose and vote on changes to contract parameters (e.g., decay rates, breeding costs).

**Function Summary (Total: 27 functions):**

**I. Core ERC-721 (DigitalEntity) Functions (Minimal Implementation):**
1.  `balanceOf(address owner)`: Get the number of entities owned by an address.
2.  `ownerOf(uint256 tokenId)`: Get the owner of a specific entity.
3.  `transferFrom(address from, address to, uint256 tokenId)`: Transfer ownership of an entity.
4.  `approve(address to, uint256 tokenId)`: Approve an address to manage a specific entity.
5.  `getApproved(uint256 tokenId)`: Get the approved address for an entity.
6.  `setApprovalForAll(address operator, bool approved)`: Set approval for an operator to manage all entities.
7.  `isApprovedForAll(address owner, address operator)`: Check if an operator is approved for all entities.

**II. Core ERC-20 (Essence) Functions (Minimal Implementation):**
8.  `totalSupplyEssence()`: Get the total supply of Essence.
9.  `balanceOfEssence(address account)`: Get the Essence balance of an address.
10. `transferEssence(address to, uint256 amount)`: Transfer Essence between addresses.
11. `transferFromEssence(address from, address to, uint256 amount)`: Transfer Essence using allowance.
12. `approveEssence(address spender, uint256 amount)`: Approve a spender to withdraw Essence.
13. `allowanceEssence(address owner, address spender)`: Get the allowance granted to a spender.

**III. DigitalEntity Life Cycle & Interaction Functions:**
14. `mintGenesisEntity(bytes memory initialGenes)`: Create the first generation of an Entity (restricted access, potentially via owner or specific criteria).
15. `getDigitalEntity(uint256 tokenId)`: View the full attributes of a specific entity.
16. `applyAttributeDecay(uint256 tokenId)`: Apply time-based decay to an entity's attributes. Can be called by anyone, entity owner pays gas.
17. `trainEntity(uint256 tokenId, uint8 attributeIndex, uint256 essenceAmount)`: Improve a specific entity attribute using Essence.
18. `feedEntity(uint256 tokenId, uint256 essenceAmount)`: Reduce an entity's Hunger using Essence.
19. `breedEntities(uint256 parent1Id, uint256 parent2Id, bytes memory mutationSeed)`: Breed two entities to create a new one (costs Essence, probabilistic).
20. `attemptMutation(uint256 tokenId, bytes memory mutationSeed)`: Attempt a random mutation on an entity (costs Essence, low probability).
21. `awakenEntity(uint256 tokenId)`: Transition an entity to the Awakened state if maturity criteria met.

**IV. Essence & Entity Staking Functions:**
22. `stakeEntity(uint256 tokenId)`: Stake an Awakened entity to earn yield.
23. `unstakeEntity(uint256 tokenId)`: Unstake a previously staked entity.
24. `stakeEssence(uint256 amount)`: Stake Essence tokens to earn yield.
25. `unstakeEssence(uint256 amount)`: Unstake previously staked Essence tokens.
26. `claimStakingYield()`: Claim accumulated Essence yield from all staked assets for the caller.

**V. Governance Functions (Simple Parameter Tuning):**
27. `proposeConfigChange(uint8 parameterIndex, uint256 newValue)`: Propose changing a contract configuration parameter (requires staking power).
28. `voteOnProposal(uint256 proposalId, bool support)`: Vote yes/no on an active proposal (requires staking power).
29. `executeProposal(uint256 proposalId)`: Execute a passed proposal after the voting period ends.
30. `getProposal(uint256 proposalId)`: View details of a specific governance proposal.
31. `getCurrentConfig()`: View the current configuration parameters.

**(Note: Total functions = 7 (ERC721 minimal) + 6 (ERC20 minimal) + 8 (Entity Life Cycle) + 5 (Staking) + 5 (Governance) = 31 functions, well exceeding the requirement of 20 unique concept functions.)**

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol"; // Although we won't implement ERC165 fully, useful conceptually
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial config, governance takes over later


/**
 * @title GenesisEngine
 * @dev A complex contract managing dynamic NFTs (Digital Entities), a resource token (Essence),
 *      dual staking (NFT & Fungible), and simple on-chain governance.
 *
 * Outline:
 * I. Core ERC-721 (DigitalEntity) - Minimal manual implementation
 * II. Core ERC-20 (Essence) - Minimal manual implementation
 * III. DigitalEntity Life Cycle & Interaction
 * IV. Essence & Entity Staking
 * V. Governance (Simple Parameter Tuning)
 */
contract GenesisEngine is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // --- Error Definitions ---
    error NotApprovedOrOwner();
    error TransferToZeroAddress();
    error TokenDoesNotExist();
    error InsufficientBalance();
    error InsufficientAllowance();
    error Unauthorized();
    error EntityNotAwakened();
    error EntityAlreadyAwakened();
    error EntityAlreadyStaked();
    error EntityNotStaked();
    error InsufficientEssenceForAction();
    error BreedingConditionsNotMet();
    error MutationFailed();
    error InvalidAttributeIndex();
    error ProposalDoesNotExist();
    error ProposalNotExecutable();
    error ProposalNotActive();
    error ProposalAlreadyVoted();
    error InsufficientVotingPower();
    error InvalidConfigParameter();

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event EssenceMinted(address indexed to, uint256 amount);
    event EssenceBurned(address indexed from, uint256 amount);
    event EssenceTransfer(address indexed from, address indexed to, uint256 amount);
    event EssenceApproval(address indexed owner, address indexed spender, uint256 amount);

    event DigitalEntityCreated(uint256 indexed tokenId, address indexed owner, bytes initialGenes);
    event AttributeDecayed(uint256 indexed tokenId, uint8 attributeIndex, uint256 decayedAmount);
    event EntityTrained(uint256 indexed tokenId, uint8 attributeIndex, uint256 amountIncreased, uint256 essenceSpent);
    event EntityFed(uint256 indexed tokenId, uint256 hungerReduced, uint256 energyIncreased, uint256 essenceSpent);
    event EntitiesBred(uint256 indexed parent1Id, uint256 indexed parent2Id, uint256 indexed childId, uint256 essenceSpent);
    event MutationAttempted(uint256 indexed tokenId, bool mutated);
    event EntityAwakened(uint256 indexed tokenId);

    event EntityStaked(uint256 indexed tokenId, address indexed owner);
    event EntityUnstaked(uint256 indexed tokenId, address indexed owner);
    event EssenceStaked(address indexed owner, uint256 amount);
    event EssenceUnstaked(address indexed owner, uint256 amount);
    event YieldClaimed(address indexed owner, uint256 essenceClaimed);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint8 indexed parameterIndex, uint256 newValue, uint256 voteEnd);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed proposalId);


    // --- State Variables ---

    // ERC721 (DigitalEntity) State
    Counters.Counter private _entityIds;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _entityBalances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ERC20 (Essence) State
    uint256 private _totalEssenceSupply;
    mapping(address => uint256) private _essenceBalances;
    mapping(address => mapping(address => uint256)) private _essenceAllowances;

    // DigitalEntity Attributes & State
    struct DigitalEntity {
        uint256 strength;
        uint256 dexterity;
        uint256 intelligence;
        uint256 resilience;
        uint256 purity;      // Represents base quality / mutation resistance
        uint256 maturity;    // Increases over time or with actions
        uint256 hunger;      // Increases over time, decreases with feeding
        uint256 energy;      // Decreases with actions (training, breeding), increases with feeding
        uint256 lastInteractionTime; // For decay calculation
        bool metamorphosed;  // Awakened state
        uint256 creationTime;
    }
    mapping(uint256 => DigitalEntity) private _entities;
    uint256[] private _allTokens; // To iterate over all token IDs (less gas efficient for many, but simple)

    // Staking State
    struct EntityStake {
        uint256 tokenId;
        uint256 stakedTime;
        uint256 yieldAccumulated; // Accumulated yield *at time of last claim/update*
    }
    mapping(address => EntityStake[]) private _stakedEntities; // Owner -> Array of staked entities

    struct EssenceStake {
        uint256 amount;
        uint256 stakedTime;
    }
     // Using a single value for simplicity, could be array for multiple positions
    mapping(address => EssenceStake) private _stakedEssence;

    // Yield State
    // This would need a more sophisticated accounting system for gas-efficient yield tracking
    // For this example, we'll use a simple per-user yield accumulator.
    mapping(address => uint256) private _pendingYield;

    // Governance State
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        uint8 parameterIndex;
        uint256 newValue;
        uint256 creationTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }
    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) private _proposals;
    uint256 private _quorumPercentage = 4; // 4% of total voting power needed for quorum (e.g., total staked essence + entity value)
    uint256 private _supermajorityPercentage = 60; // 60% of votes must be 'for' to pass
    uint256 private _votingPeriod = 3 days; // Voting period duration

    // Configuration Parameters (Governable)
    // Index -> Value
    uint256[] public configParameters;
    // Indices:
    uint8 constant CONFIG_DECAY_RATE_PER_HOUR = 0; // Amount attributes decay per hour (scaled)
    uint8 constant CONFIG_TRAINING_ESSENCE_PER_POINT = 1; // Essence cost to increase attribute by 1
    uint8 constant CONFIG_FEEDING_ESSENCE_PER_HUNGER = 2; // Essence cost to reduce hunger by 1
    uint8 constant CONFIG_BREEDING_ESSENCE_COST = 3; // Base Essence cost for breeding
    uint8 constant CONFIG_MUTATION_CHANCE_PERCENT = 4; // Chance of mutation on attempt (0-100)
    uint8 constant CONFIG_MIN_MATURITY_FOR_AWAKENING = 5; // Minimum maturity to Awaken
    uint8 constant CONFIG_ESSENCE_STAKING_APR_PER_10K = 6; // Essence yield APR for Essence staking (scaled by 10k)
    uint8 constant CONFIG_ENTITY_STAKING_APR_PER_10K = 7; // Essence yield APR for Entity staking (scaled by 10k per Maturity?) - simplified for now

    // --- Constructor ---
    constructor(uint256 initialEssenceSupply) Ownable(msg.sender) {
        // Initialize configuration parameters
        configParameters.push(10);   // CONFIG_DECAY_RATE_PER_HOUR (e.g., 0.1 per attribute per hour if scaled by 100)
        configParameters.push(100);  // CONFIG_TRAINING_ESSENCE_PER_POINT
        configParameters.push(50);   // CONFIG_FEEDING_ESSENCE_PER_HUNGER
        configParameters.push(1000); // CONFIG_BREEDING_ESSENCE_COST
        configParameters.push(5);    // CONFIG_MUTATION_CHANCE_PERCENT (5%)
        configParameters.push(1000); // CONFIG_MIN_MATURITY_FOR_AWAKENING
        configParameters.push(1000); // CONFIG_ESSENCE_STAKING_APR_PER_10K (10%)
        configParameters.push(2000); // CONFIG_ENTITY_STAKING_APR_PER_10K (20%)

        // Mint initial Essence supply (e.g., to the deployer or a treasury)
        _mintEssence(msg.sender, initialEssenceSupply);
    }

    // --- Internal Helpers ---

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Uses public ownerOf, which checks existence
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert Unauthorized(); // ownerOf checks existence
        if (to == address(0)) revert TransferToZeroAddress();

        // Clear approvals
        _tokenApprovals[tokenId] = address(0);

        _entityBalances[from] = _entityBalances[from].sub(1);
        _entityBalances[to] = _entityBalances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _mintEntity(address to, bytes memory initialGenes) internal returns (uint256) {
        _entityIds.increment();
        uint256 newTokenId = _entityIds.current();

        _owners[newTokenId] = to;
        _entityBalances[to] = _entityBalances[to].add(1);
        _allTokens.push(newTokenId);

        // Basic attribute generation from genes - more complex logic would be here
        uint265 _strength = uint256(uint160(initialGenes[0] << 8 | initialGenes[1]));
        uint265 _dexterity = uint256(uint160(initialGenes[2] << 8 | initialGenes[3]));
        uint265 _intelligence = uint256(uint160(initialGenes[4] << 8 | initialGenes[5]));
        uint265 _resilience = uint256(uint160(initialGenes[6] << 8 | initialGenes[7]));
        uint265 _purity = uint256(uint160(initialGenes[8] << 8 | initialGenes[9]));

         _entities[newTokenId] = DigitalEntity({
            strength: _strength % 100, // Scale attributes down for simplicity
            dexterity: _dexterity % 100,
            intelligence: _intelligence % 100,
            resilience: _resilience % 100,
            purity: _purity % 100,
            maturity: 0,
            hunger: 50, // Start with some hunger
            energy: 100, // Start with full energy
            lastInteractionTime: block.timestamp,
            metamorphosed: false,
            creationTime: block.timestamp
        });


        emit DigitalEntityCreated(newTokenId, to, initialGenes);
        return newTokenId;
    }

    function _mintEssence(address account, uint256 amount) internal {
        if (account == address(0)) revert TransferToZeroAddress();
        _totalEssenceSupply = _totalEssenceSupply.add(amount);
        _essenceBalances[account] = _essenceBalances[account].add(amount);
        emit EssenceMinted(account, amount);
    }

    function _burnEssence(address account, uint256 amount) internal {
        if (account == address(0)) revert Unauthorized();
        _essenceBalances[account] = _essenceBalances[account].sub(amount, "Essence: burn amount exceeds balance");
        _totalEssenceSupply = _totalEssenceSupply.sub(amount);
        emit EssenceBurned(account, amount);
    }

    function _transferEssence(address from, address to, uint256 amount) internal {
        if (from == address(0) || to == address(0)) revert TransferToZeroAddress();
        _essenceBalances[from] = _essenceBalances[from].sub(amount, "Essence: transfer amount exceeds balance");
        _essenceBalances[to] = _essenceBalances[to].add(amount);
        emit EssenceTransfer(from, to, amount);
    }

     function _calculateTimeDecay(uint256 _lastInteractionTime) internal view returns (uint256 decayAmount) {
        uint256 timeElapsed = block.timestamp.sub(_lastInteractionTime);
        // Decay is based on time elapsed and config parameter
        // Simplified: decay rate per hour * hours elapsed
        // Scale it down: decayRate * timeElapsed / 3600 (seconds per hour)
        // Max decay per call to prevent massive stat loss from long periods
        uint256 decayRate = configParameters[CONFIG_DECAY_RATE_PER_HOUR]; // e.g., 10
        uint256 maxDecayPerCall = 100; // Prevent stats dropping too fast

        uint256 totalPossibleDecay = decayRate.mul(timeElapsed).div(3600); // This might overflow for very long times
        // Safe approach: calculate decay in chunks or cap total time.
        // Simple Cap: Max decay over 30 days for one call
        uint256 maxReasonableTime = 30 days;
        uint256 effectiveTime = timeElapsed > maxReasonableTime ? maxReasonableTime : timeElapsed;

        decayAmount = decayRate.mul(effectiveTime).div(3600);

        return decayAmount > maxDecayPerCall ? maxDecayPerCall : decayAmount;
    }

    function _getVotingPower(address account) internal view returns (uint256) {
        // Voting power = Staked Essence balance + (Number of staked Entities * Base Entity Voting Power)
        // Base Entity Voting Power could scale with Maturity or Purity, simplified here
        uint256 essencePower = _stakedEssence[account].amount;
        uint256 entityPower = uint256(_stakedEntities[account].length).mul(100); // Arbitrary power per staked entity

        return essencePower.add(entityPower);
    }

    function _calculateYield(address account) internal view returns (uint256 totalYield) {
        uint256 currentTimestamp = block.timestamp;
        uint256 essenceStakingAPR = configParameters[CONFIG_ESSENCE_STAKING_APR_PER_10K]; // Scaled by 10k
        uint256 entityStakingAPR = configParameters[CONFIG_ENTITY_STAKING_APR_PER_10K]; // Scaled by 10k per entity

        // Calculate yield from staked Essence
        EssenceStake storage essenceStake = _stakedEssence[account];
        if (essenceStake.amount > 0) {
            uint256 timeStaked = currentTimestamp.sub(essenceStake.stakedTime);
            // Yield = amount * APR * time / (seconds_in_year * scaling_factor)
             totalYield = totalYield.add(
                 essenceStake.amount.mul(essenceStakingAPR).mul(timeStaked).div(365 days).div(10000)
             );
        }

        // Calculate yield from staked Entities
        // This is more complex as each entity might have different yield potential or staking start times
        // For simplicity, iterate and apply a base APR per entity
        EntityStake[] storage stakedEntities = _stakedEntities[account];
        for (uint i = 0; i < stakedEntities.length; i++) {
            uint256 timeStaked = currentTimestamp.sub(stakedEntities[i].stakedTime);
            // Yield per entity = Base APR * time / seconds_in_year / scaling_factor
            // Could be enhanced: yield = entity.maturity * maturity_yield_factor * time / ...
            totalYield = totalYield.add(
                entityStakingAPR.mul(timeStaked).div(365 days).div(10000) // Base yield per entity
            );
             // Add yield accumulated BEFORE the last claim/update
            totalYield = totalYield.add(stakedEntities[i].yieldAccumulated);
        }
         // Add yield accumulated from essence staking BEFORE the last claim/update (not implemented in simple struct)
         // A proper system would store last claimed time or pending yield per position.

        // Add pending yield not yet claimed (from previous claims/updates)
        totalYield = totalYield.add(_pendingYield[account]);

        return totalYield;
    }

    // --- I. Core ERC-721 (DigitalEntity) Functions ---
    // Minimal implementation for core functionality

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == address(0)) revert TransferToZeroAddress();
        return _entityBalances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert TokenDoesNotExist();
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        if (_isApprovedOrOwner(msg.sender, tokenId)) {
             _transfer(from, to, tokenId);
        } else {
            revert NotApprovedOrOwner();
        }
    }

    // safeTransferFrom simplified - skips ERC721Receiver check
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        // In a full ERC721, add _checkOnERC721Received logic here
    }

     function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
         // In a full ERC721, add _checkOnERC721Received logic here with data
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId); // Checks existence
        if (msg.sender != owner) revert Unauthorized();
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // --- II. Core ERC-20 (Essence) Functions ---
     // Minimal implementation for core functionality

    function totalSupplyEssence() public view returns (uint256) {
        return _totalEssenceSupply;
    }

    function balanceOfEssence(address account) public view returns (uint256) {
        return _essenceBalances[account];
    }

    function transferEssence(address to, uint256 amount) public returns (bool) {
        _transferEssence(msg.sender, to, amount);
        return true;
    }

    function transferFromEssence(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _essenceAllowances[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance();
        _essenceAllowances[from][msg.sender] = currentAllowance.sub(amount);
        _transferEssence(from, to, amount);
        return true;
    }

    function approveEssence(address spender, uint256 amount) public returns (bool) {
        _essenceAllowances[msg.sender][spender] = amount;
        emit EssenceApproval(msg.sender, spender, amount);
        return true;
    }

    function allowanceEssence(address owner, address spender) public view returns (uint256) {
        return _essenceAllowances[owner][spender];
    }

    // --- III. DigitalEntity Life Cycle & Interaction Functions ---

    /**
     * @dev Mints a new first-generation DigitalEntity. Restricted to owner initially.
     *      Could be modified for public minting with cost or conditions.
     * @param initialGenes Byte array representing initial genetic material.
     * @return uint256 The ID of the newly minted entity.
     */
    function mintGenesisEntity(bytes memory initialGenes) public onlyOwner returns (uint256) {
        // Add cost here if public: e.g., require(balanceOfEssence(msg.sender) >= mintCost, InsufficientEssenceForAction());
        // if(mintCost > 0) _burnEssence(msg.sender, mintCost); // Example burn cost

        uint256 newTokenId = _mintEntity(msg.sender, initialGenes);

        // Add entity to the owner's collection tracker if needed for external tools
        // Not strictly necessary for basic ERC721 compliance or internal logic

        return newTokenId;
    }

    /**
     * @dev Gets the attributes of a DigitalEntity.
     * @param tokenId The ID of the entity.
     * @return tuple Entity attributes.
     */
    function getDigitalEntity(uint256 tokenId) public view returns (
        uint256 strength,
        uint256 dexterity,
        uint256 intelligence,
        uint256 resilience,
        uint256 purity,
        uint256 maturity,
        uint256 hunger,
        uint256 energy,
        uint256 lastInteractionTime,
        bool metamorphosed,
        uint256 creationTime
    ) {
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        DigitalEntity storage entity = _entities[tokenId];
        return (
            entity.strength,
            entity.dexterity,
            entity.intelligence,
            entity.resilience,
            entity.purity,
            entity.maturity,
            entity.hunger,
            entity.energy,
            entity.lastInteractionTime,
            entity.metamorphosed,
            entity.creationTime
        );
    }

    /**
     * @dev Applies time-based decay to an entity's attributes.
     *      Can be called by anyone, but primarily intended to be called by the owner
     *      before interacting with the entity.
     * @param tokenId The ID of the entity.
     */
    function applyAttributeDecay(uint256 tokenId) public {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         DigitalEntity storage entity = _entities[tokenId];

         if (entity.metamorphosed) {
             // Awakened entities may decay differently or not at all
             // For this example, Awakened entities do not decay attributes
             return;
         }

         uint256 decayAmount = _calculateTimeDecay(entity.lastInteractionTime);

         if (decayAmount > 0) {
             // Apply decay to mutable attributes (e.g., Strength, Dexterity, Intelligence, Resilience, Hunger, Energy)
             // Prevent attributes from going below a certain minimum (e.g., 1) except Hunger/Energy
             uint256 initialStrength = entity.strength;
             uint256 initialDexterity = entity.dexterity;
             uint256 initialIntelligence = entity.intelligence;
             uint256 initialResilience = entity.resilience;

             entity.strength = entity.strength > decayAmount ? entity.strength.sub(decayAmount) : 1;
             entity.dexterity = entity.dexterity > decayAmount ? entity.dexterity.sub(decayAmount) : 1;
             entity.intelligence = entity.intelligence > decayAmount ? entity.intelligence.sub(decayAmount) : 1;
             entity.resilience = entity.resilience > decayAmount ? entity.resilience.sub(decayAmount) : 1;

             entity.hunger = entity.hunger.add(decayAmount); // Hunger increases

             // Energy decay could also be applied here

             entity.lastInteractionTime = block.timestamp; // Reset interaction time

             // Emit events for each attribute decayed significantly, or a single summary event
             emit AttributeDecayed(tokenId, 0, initialStrength.sub(entity.strength)); // Example for Strength
             // ... emit for other attributes
         }
    }

     /**
     * @dev Improves a specific entity attribute using Essence.
     *      Applies decay before training.
     * @param tokenId The ID of the entity.
     * @param attributeIndex Index of the attribute to train (e.g., 0=Strength, 1=Dexterity).
     * @param essenceAmount The amount of Essence to spend.
     */
    function trainEntity(uint256 tokenId, uint8 attributeIndex, uint256 essenceAmount) public {
        address entityOwner = ownerOf(tokenId);
        if (msg.sender != entityOwner && !_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();
        if (balanceOfEssence(msg.sender) < essenceAmount) revert InsufficientEssenceForAction();
        if (_entities[tokenId].metamorphosed) revert EntityAlreadyAwakened(); // Cannot train awakened entities

        applyAttributeDecay(tokenId); // Apply decay first

        DigitalEntity storage entity = _entities[tokenId];

        // Calculate points gained and Essence cost
        uint256 essenceCostPerPoint = configParameters[CONFIG_TRAINING_ESSENCE_PER_POINT];
        uint256 pointsGained = essenceAmount.div(essenceCostPerPoint);
        if (pointsGained == 0) revert InsufficientEssenceForAction(); // Not enough essence to gain any points
        uint256 actualEssenceCost = pointsGained.mul(essenceCostPerPoint);

        // Apply attribute increase based on index
        // This is a simplified mapping; a real contract might use a switch or more complex logic
        // 0: Strength, 1: Dexterity, 2: Intelligence, 3: Resilience
        if (attributeIndex > 3) revert InvalidAttributeIndex();

        if (attributeIndex == 0) entity.strength = entity.strength.add(pointsGained);
        else if (attributeIndex == 1) entity.dexterity = entity.dexterity.add(pointsGained);
        else if (attributeIndex == 2) entity.intelligence = entity.intelligence.add(pointsGained);
        else if (attributeIndex == 3) entity.resilience = entity.resilience.add(pointsGained);

        // Training consumes Energy
        entity.energy = entity.energy > pointsGained ? entity.energy.sub(pointsGained) : 0;
        entity.maturity = entity.maturity.add(pointsGained); // Training also increases maturity

        _burnEssence(msg.sender, actualEssenceCost);
        entity.lastInteractionTime = block.timestamp;

        emit EntityTrained(tokenId, attributeIndex, pointsGained, actualEssenceCost);
    }

    /**
     * @dev Reduces an entity's Hunger and potentially increases Energy using Essence.
     *      Applies decay before feeding.
     * @param tokenId The ID of the entity.
     * @param essenceAmount The amount of Essence to spend on feeding.
     */
    function feedEntity(uint256 tokenId, uint256 essenceAmount) public {
        address entityOwner = ownerOf(tokenId);
        if (msg.sender != entityOwner && !_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();
        if (balanceOfEssence(msg.sender) < essenceAmount) revert InsufficientEssenceForAction();
         if (_entities[tokenId].metamorphosed) revert EntityAlreadyAwakened();

        applyAttributeDecay(tokenId); // Apply decay first

        DigitalEntity storage entity = _entities[tokenId];

        uint256 essenceCostPerHunger = configParameters[CONFIG_FEEDING_ESSENCE_PER_HUNGER];
        uint256 hungerReduction = essenceAmount.div(essenceCostPerHunger);
        if (hungerReduction == 0 && essenceAmount > 0) revert InsufficientEssenceForAction(); // Not enough essence to reduce any hunger

        // Reduce hunger, cap at 0
        uint256 actualHungerReduction = entity.hunger > hungerReduction ? hungerReduction : entity.hunger;
        entity.hunger = entity.hunger.sub(actualHungerReduction);

        // Increase energy based on actual hunger reduced
        entity.energy = entity.energy.add(actualHungerReduction); // Example: 1 hunger reduced gives 1 energy
         // Cap energy at a max value (e.g., 200)
        uint256 maxEnergy = 200;
        if (entity.energy > maxEnergy) entity.energy = maxEnergy;

        uint256 actualEssenceCost = actualHungerReduction.mul(essenceCostPerHunger); // Pay only for effective feeding

        _burnEssence(msg.sender, actualEssenceCost);
        entity.lastInteractionTime = block.timestamp;

        emit EntityFed(tokenId, actualHungerReduction, actualHungerReduction, actualEssenceCost); // Energy increased by same amount
    }

    /**
     * @dev Breeds two entities to create a new one. Costs Essence and is probabilistic.
     *      Applies decay before breeding.
     * @param parent1Id The ID of the first parent entity.
     * @param parent2Id The ID of the second parent entity.
     * @param mutationSeed A seed for randomness.
     * @return uint256 The ID of the new child entity (0 if breeding fails).
     */
    function breedEntities(uint256 parent1Id, uint256 parent2Id, bytes memory mutationSeed) public returns (uint256) {
        address owner1 = ownerOf(parent1Id); // Checks existence
        address owner2 = ownerOf(parent2Id); // Checks existence

        // Require caller to own or be approved for both parents
        if (!_isApprovedOrOwner(msg.sender, parent1Id)) revert Unauthorized();
        if (!_isApprovedOrOwner(msg.sender, parent2Id)) revert Unauthorized();

        // Breeding Cost
        uint256 breedingCost = configParameters[CONFIG_BREEDING_ESSENCE_COST];
        if (balanceOfEssence(msg.sender) < breedingCost) revert InsufficientEssenceForAction();

        // Apply decay to both parents
        applyAttributeDecay(parent1Id);
        applyAttributeDecay(parent2Id);

        DigitalEntity storage parent1 = _entities[parent1Id];
        DigitalEntity storage parent2 = _entities[parent2Id];

        // Breeding Conditions (Examples: minimum energy, minimum maturity, not already breeding)
        if (parent1.energy < 50 || parent2.energy < 50) revert BreedingConditionsNotMet();
        // Add checks for breeding cooldowns or other conditions

        _burnEssence(msg.sender, breedingCost);

        // Reduce parent energy after successful breeding cost payment
        parent1.energy = parent1.energy.sub(50); // Example energy cost
        parent2.energy = parent2.energy.sub(50);

        // Combine attributes (simple average + some variance based on seed and purity)
        // Add probabilistic breeding failure based on stats/purity?
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, parent1Id, parent2Id, mutationSeed)));

        uint256 childStrength = (parent1.strength.add(parent2.strength)).div(2);
        uint256 childDexterity = (parent1.dexterity.add(parent2.dexterity)).div(2);
        uint256 childIntelligence = (parent1.intelligence.add(parent2.intelligence)).div(2);
        uint256 childResilience = (parent1.resilience.add(parent2.resilience)).div(2);
        uint256 childPurity = (parent1.purity.add(parent2.purity)).div(2); // Purity tends towards average

        // Introduce variance based on randomFactor and combined purity
        uint256 variance = (randomFactor % 21) - 10; // Random number between -10 and 10
        uint256 purityInfluence = (parent1.purity.add(parent2.purity)).div(20); // Higher purity slightly reduces negative variance impact

        childStrength = childStrength.add(variance).add(purityInfluence);
        childDexterity = childDexterity.add(variance).add(purityInfluence);
        childIntelligence = childIntelligence.add(variance).add(purityInfluence);
        childResilience = childResilience.add(variance).add(purityInfluence);
        childPurity = childPurity > 50 ? childPurity.add(variance / 5) : childPurity.sub(variance / 5); // Purity variance is less extreme

        // Ensure attributes are within a reasonable range (e.g., 1-200)
        uint256 maxAttribute = 200;
        uint256 minAttribute = 1;
        childStrength = childStrength > maxAttribute ? maxAttribute : (childStrength < minAttribute ? minAttribute : childStrength);
        childDexterity = childDexterity > maxAttribute ? maxAttribute : (childDexterity < minAttribute ? minAttribute : childDexterity);
        childIntelligence = childIntelligence > maxAttribute ? maxAttribute : (childIntelligence < minAttribute ? minAttribute : childIntelligence);
        childResilience = childResilience > maxAttribute ? maxAttribute : (childResilience < minAttribute ? minAttribute : childResilience);
        childPurity = childPurity > 100 ? 100 : (childPurity < 1 ? 1 : childPurity); // Purity 1-100

        // Create genes for the child (simplified)
        bytes memory childGenes = new bytes(10);
        childGenes[0] = bytes1(uint8(childStrength % 256));
        childGenes[1] = bytes1(uint8(childStrength / 256)); // Example packing
         // ... pack other stats similarly

        uint256 childId = _mintEntity(msg.sender, childGenes); // New entity goes to caller

        parent1.lastInteractionTime = block.timestamp; // Update parents' interaction time
        parent2.lastInteractionTime = block.timestamp;

        emit EntitiesBred(parent1Id, parent2Id, childId, breedingCost);
        return childId;
    }

    /**
     * @dev Attempts a random mutation on an entity. Costs Essence and is low probability.
     *      Applies decay before attempt.
     * @param tokenId The ID of the entity.
     * @param mutationSeed A seed for randomness.
     * @return bool True if mutation occurred, false otherwise.
     */
    function attemptMutation(uint256 tokenId, bytes memory mutationSeed) public returns (bool) {
        address entityOwner = ownerOf(tokenId);
        if (msg.sender != entityOwner && !_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();
        uint256 attemptCost = configParameters[CONFIG_BREEDING_ESSENCE_COST].div(2); // Half breeding cost?
        if (balanceOfEssence(msg.sender) < attemptCost) revert InsufficientEssenceForAction();
        if (_entities[tokenId].metamorphosed) revert EntityAlreadyAwakened();

        applyAttributeDecay(tokenId);

        DigitalEntity storage entity = _entities[tokenId];

        _burnEssence(msg.sender, attemptCost);

        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, mutationSeed)));
        uint256 mutationChance = configParameters[CONFIG_MUTATION_CHANCE_PERCENT]; // 0-100

        bool mutated = false;
        if (randomFactor % 100 < mutationChance) {
            // Mutation successful! Randomly change some attributes significantly
            uint256 mutationEffect = (randomFactor % 51) - 25; // -25 to +25

            // Apply effect to random attributes
            uint8 affectedAttributeIndex = uint8(randomFactor % 5); // 0-4 for Str, Dex, Int, Res, Purity
            uint256 currentValue;
            if (affectedAttributeIndex == 0) { currentValue = entity.strength; entity.strength = currentValue.add(mutationEffect); }
            else if (affectedAttributeIndex == 1) { currentValue = entity.dexterity; entity.dexterity = currentValue.add(mutationEffect); }
            else if (affectedAttributeIndex == 2) { currentValue = entity.intelligence; entity.intelligence = currentValue.add(mutationEffect); }
            else if (affectedAttributeIndex == 3) { currentValue = entity.resilience; entity.resilience = currentValue.add(mutationEffect); }
            else { currentValue = entity.purity; entity.purity = currentValue.add(mutationEffect > 0 ? mutationEffect/2 : mutationEffect); } // Purity less affected

            // Clamp values
             uint256 maxAttribute = 200;
             uint256 minAttribute = 1;
             if (affectedAttributeIndex < 4) {
                 if (currentValue.add(mutationEffect) > maxAttribute) _entities[tokenId].strength = maxAttribute; // Need specific attribute access
                 else if (currentValue.add(mutationEffect) < minAttribute) _entities[tokenId].strength = minAttribute; // Need specific attribute access
                 // Need to properly access entity.strength, entity.dexterity etc. after the conditional check
                 if (affectedAttributeIndex == 0) entity.strength = entity.strength > maxAttribute ? maxAttribute : (entity.strength < minAttribute ? minAttribute : entity.strength);
                 else if (affectedAttributeIndex == 1) entity.dexterity = entity.dexterity > maxAttribute ? maxAttribute : (entity.dexterity < minAttribute ? minAttribute : entity.dexterity);
                 else if (affectedAttributeIndex == 2) entity.intelligence = entity.intelligence > maxAttribute ? maxAttribute : (entity.intelligence < minAttribute ? minAttribute : entity.intelligence);
                 else if (affectedAttributeIndex == 3) entity.resilience = entity.resilience > maxAttribute ? maxAttribute : (entity.resilience < minAttribute ? minAttribute : entity.resilience);
             } else { // Purity
                  uint256 maxPurity = 100; uint256 minPurity = 1;
                 entity.purity = entity.purity > maxPurity ? maxPurity : (entity.purity < minPurity ? minPurity : entity.purity);
             }

            entity.lastInteractionTime = block.timestamp;
            mutated = true;
        }

        emit MutationAttempted(tokenId, mutated);
        return mutated;
    }

    /**
     * @dev Transitions an entity to the Awakened state if maturity criteria met.
     *      Awakened entities may have different rules (e.g., no decay, no training, stakeable).
     * @param tokenId The ID of the entity.
     */
    function awakenEntity(uint256 tokenId) public {
        address entityOwner = ownerOf(tokenId);
        if (msg.sender != entityOwner && !_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();
        DigitalEntity storage entity = _entities[tokenId];

        if (entity.metamorphosed) revert EntityAlreadyAwakened();
        if (entity.maturity < configParameters[CONFIG_MIN_MATURITY_FOR_AWAKENING]) revert("Entity not mature enough to Awaken");

        entity.metamorphosed = true;
        // Lock attributes from training/decay here or in applyAttributeDecay/trainEntity checks
        entity.lastInteractionTime = block.timestamp; // Reset time

        emit EntityAwakened(tokenId);
    }

    // --- IV. Essence & Entity Staking Functions ---

    /**
     * @dev Stakes an Awakened DigitalEntity. Transfers NFT to the contract.
     * @param tokenId The ID of the entity to stake.
     */
    function stakeEntity(uint256 tokenId) public {
        address entityOwner = ownerOf(tokenId);
        if (msg.sender != entityOwner) revert Unauthorized(); // Must be owner to stake

        DigitalEntity storage entity = _entities[tokenId];
        if (!entity.metamorphosed) revert EntityNotAwakened();

        // Check if already staked (iterate staked entities for this user)
        for (uint i = 0; i < _stakedEntities[msg.sender].length; i++) {
            if (_stakedEntities[msg.sender][i].tokenId == tokenId) revert EntityAlreadyStaked();
        }

        // Transfer entity to the contract address
        _transfer(msg.sender, address(this), tokenId); // Transfers ownership

        // Record staking position
        _stakedEntities[msg.sender].push(EntityStake({
            tokenId: tokenId,
            stakedTime: block.timestamp,
            yieldAccumulated: 0 // Start with 0 accumulated yield for this new position
        }));

        emit EntityStaked(tokenId, msg.sender);
    }

    /**
     * @dev Unstakes a DigitalEntity. Transfers NFT back to the owner.
     *      Claims any pending yield first.
     * @param tokenId The ID of the entity to unstake.
     */
    function unstakeEntity(uint256 tokenId) public {
        // Check if the caller owns this staked entity
        // Find the entity in the user's staked array and remove it
        bool found = false;
        uint256 indexToRemove = type(uint256).max;

        for (uint i = 0; i < _stakedEntities[msg.sender].length; i++) {
            if (_stakedEntities[msg.sender][i].tokenId == tokenId) {
                found = true;
                indexToRemove = i;
                break;
            }
        }

        if (!found) revert EntityNotStaked(); // Entity not staked by this user

        // Before unstaking, claim yield to update pending yield
        claimStakingYield();

        // Transfer entity back to the owner
        // Note: Ownership in _owners is contract address while staked. Need to update it.
        address contractOwner = ownerOf(tokenId); // Should be address(this)
        if (contractOwner != address(this)) revert("Entity ownership mismatch"); // Sanity check

        // Remove from staked array (swap with last and pop)
        uint lastIndex = _stakedEntities[msg.sender].length - 1;
        if (indexToRemove != lastIndex) {
            _stakedEntities[msg.sender][indexToRemove] = _stakedEntities[msg.sender][lastIndex];
        }
        _stakedEntities[msg.sender].pop();

        // Manually update ownership state as _transfer checks ownership
        _owners[tokenId] = msg.sender;
        _entityBalances[address(this)] = _entityBalances[address(this)].sub(1);
        _entityBalances[msg.sender] = _entityBalances[msg.sender].add(1);
         // Approvals related to the contract holding the token should be cleared

        emit Transfer(address(this), msg.sender, tokenId); // Emit transfer event
        emit EntityUnstaked(tokenId, msg.sender);
    }


    /**
     * @dev Stakes Essence tokens.
     * @param amount The amount of Essence to stake.
     */
    function stakeEssence(uint256 amount) public {
        if (balanceOfEssence(msg.sender) < amount) revert InsufficientEssenceForAction();
        if (amount == 0) revert("Cannot stake zero amount");

        // Claim yield first to snapshot current yield based on old stake amount/time
        claimStakingYield();

        // Transfer Essence to the contract
        _transferEssence(msg.sender, address(this), amount);

        // Update staking position
        // This simplified version replaces the old stake position.
        // A more complex version would use an array or map for multiple stakes.
        _stakedEssence[msg.sender] = EssenceStake({
            amount: _stakedEssence[msg.sender].amount.add(amount), // Add to existing stake
            stakedTime: block.timestamp // Update time to avg or use new entry
        });
        // Note: Updating time like this isn't perfectly accurate for APR calculation
        // A weighted average time or separate stake entries would be better.

        emit EssenceStaked(msg.sender, amount);
    }

    /**
     * @dev Unstakes Essence tokens. Claims any pending yield first.
     * @param amount The amount of Essence to unstake.
     */
    function unstakeEssence(uint256 amount) public {
        if (_stakedEssence[msg.sender].amount < amount) revert("Insufficient staked Essence");
        if (amount == 0) revert("Cannot unstake zero amount");

        // Claim yield first to snapshot current yield based on old stake amount/time
        claimStakingYield();

        // Reduce staked amount
        _stakedEssence[msg.sender].amount = _stakedEssence[msg.sender].amount.sub(amount);
        // Note: Time is not updated here, yield calculation needs to handle this

        // Transfer Essence back to the owner
        _transferEssence(address(this), msg.sender, amount);

        emit EssenceUnstaked(msg.sender, amount);
    }

    /**
     * @dev Claims accumulated Essence yield from all staked assets for the caller.
     */
    function claimStakingYield() public {
        uint256 totalYield = _calculateYield(msg.sender);

        if (totalYield > 0) {
            // Mint yield to the user
            _mintEssence(msg.sender, totalYield);

            // Reset pending yield and update staked positions
            _pendingYield[msg.sender] = 0;

             // Update staked Essence time (reset for simplified calculation)
            _stakedEssence[msg.sender].stakedTime = block.timestamp;

            // Update staked Entities time and reset accumulated yield
            EntityStake[] storage stakedEntities = _stakedEntities[msg.sender];
            for (uint i = 0; i < stakedEntities.length; i++) {
                stakedEntities[i].stakedTime = block.timestamp;
                stakedEntities[i].yieldAccumulated = 0;
            }

            emit YieldClaimed(msg.sender, totalYield);
        }
    }


    // --- V. Governance Functions (Simple Parameter Tuning) ---

    /**
     * @dev Creates a proposal to change a configuration parameter.
     *      Requires minimum staking power (simplified: any staked assets).
     * @param parameterIndex The index of the configuration parameter to change.
     * @param newValue The new value for the parameter.
     */
    function proposeConfigChange(uint8 parameterIndex, uint256 newValue) public {
        // Require minimum staking power to propose
        if (_getVotingPower(msg.sender) == 0) revert InsufficientVotingPower();
        if (parameterIndex >= configParameters.length) revert InvalidConfigParameter();

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        Proposal storage newProposal = _proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.parameterIndex = parameterIndex;
        newProposal.newValue = newValue;
        newProposal.creationTime = block.timestamp;
        newProposal.voteEndTime = block.timestamp.add(_votingPeriod);
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.state = ProposalState.Active;

        emit ProposalCreated(proposalId, msg.sender, parameterIndex, newValue, newProposal.voteEndTime);
    }

    /**
     * @dev Votes on an active proposal.
     *      Voting power is based on staked assets at the time of voting.
     * @param proposalId The ID of the proposal to vote on.
     * @param support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 proposalId, bool support) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.timestamp > proposal.voteEndTime) revert ProposalNotActive(); // Voting period ended

        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        uint256 votingPower = _getVotingPower(msg.sender);
        if (votingPower == 0) revert InsufficientVotingPower();

        if (support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(proposalId, msg.sender, support, votingPower);
    }

    /**
     * @dev Executes a proposal if it has passed and the voting period is over.
     *      Anyone can call this function to trigger execution.
     * @param proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalNotActive();
        if (block.timestamp <= proposal.voteEndTime) revert ProposalNotExecutable(); // Voting period not over

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 totalVotingPower = _totalEssenceSupply.add(_entityIds.current().mul(100)); // Simplified total power calculation

        // Check Quorum: total votes must be >= quorum percentage of total possible voting power
        if (totalVotes.mul(100) < totalVotingPower.mul(_quorumPercentage)) {
            proposal.state = ProposalState.Failed;
            revert ProposalNotExecutable(); // Failed quorum
        }

        // Check Supermajority: votesFor must be >= supermajority percentage of total votes
        if (proposal.votesFor.mul(100) < totalVotes.mul(_supermajorityPercentage)) {
             proposal.state = ProposalState.Failed;
            revert ProposalNotExecutable(); // Failed supermajority
        }

        // Proposal passed! Execute the change.
        if (proposal.parameterIndex >= configParameters.length) {
             proposal.state = ProposalState.Failed; // Should not happen due to propose check
             revert InvalidConfigParameter();
        }

        configParameters[proposal.parameterIndex] = proposal.newValue;

        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(proposalId);
    }

     /**
     * @dev Gets details of a specific governance proposal.
     * @param proposalId The ID of the proposal.
     * @return tuple Proposal details.
     */
    function getProposal(uint256 proposalId) public view returns (
        uint256 id,
        uint8 parameterIndex,
        uint256 newValue,
        uint256 creationTime,
        uint256 voteEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalState state
    ) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0 && proposalId > 0) revert ProposalDoesNotExist(); // Check if proposal exists

        return (
            proposal.id,
            proposal.parameterIndex,
            proposal.newValue,
            proposal.creationTime,
            proposal.voteEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.state
        );
    }

    /**
     * @dev Gets the current configuration parameters.
     * @return uint256[] Array of current configuration values.
     */
    function getCurrentConfig() public view returns (uint256[] memory) {
        return configParameters;
    }

    // --- Additional Utility/View Functions ---

    /**
     * @dev Calculates the potential staking yield for a specific entity based on its current attributes.
     *      (Simplified: currently just uses base APR for entity staking).
     * @param tokenId The ID of the entity.
     * @return uint256 The calculated yield rate or multiplier.
     */
    function calculateOrganismYield(uint256 tokenId) public view returns (uint256) {
        // Placeholder for more complex yield calculation based on stats
        // e.g., return _entities[tokenId].maturity.mul(configParameters[CONFIG_ENTITY_STAKING_APR_PER_10K]).div(10000);
        if (!_exists(tokenId)) revert TokenDoesNotExist();
        if (!_entities[tokenId].metamorphosed) return 0; // Only Awakened entities yield
        return configParameters[CONFIG_ENTITY_STAKING_APR_PER_10K]; // Return base APR for simplicity
    }

    /**
     * @dev Gets the time elapsed since the entity's last interaction.
     * @param tokenId The ID of the entity.
     * @return uint256 Time in seconds.
     */
    function getTimeSinceLastInteraction(uint256 tokenId) public view returns (uint256) {
         if (!_exists(tokenId)) revert TokenDoesNotExist();
         return block.timestamp.sub(_entities[tokenId].lastInteractionTime);
    }

    /**
     * @dev Gets the pending Essence yield for the caller without claiming.
     * @return uint256 Total pending yield.
     */
    function getPendingEssenceYield() public view returns (uint256) {
        // Recalculate yield to show current amount
        uint256 currentTimestamp = block.timestamp;
        uint256 essenceStakingAPR = configParameters[CONFIG_ESSENCE_STAKING_APR_PER_10K];

        uint256 currentEssenceYield = 0;
         EssenceStake storage essenceStake = _stakedEssence[msg.sender];
        if (essenceStake.amount > 0) {
            uint256 timeStaked = currentTimestamp.sub(essenceStake.stakedTime);
             currentEssenceYield = essenceStake.amount.mul(essenceStakingAPR).mul(timeStaked).div(365 days).div(10000);
        }

        // This calculation in _calculateYield is complex due to summing different sources and pending.
        // A simplified view function just shows Essence yield or sums pending from previous snapshots.
        // For true "pending", need to iterate and sum yield since last stakedTime/yieldAccumulated for each position.
        // Let's return the snapshot from last claim + newly accrued Essence yield since then.

         uint256 yieldSinceLastClaim = 0;
         if (_stakedEssence[msg.sender].amount > 0) {
             uint256 timeStakedSinceLastClaim = block.timestamp.sub(_stakedEssence[msg.sender].stakedTime);
             yieldSinceLastClaim = _stakedEssence[msg.sender].amount
                                 .mul(configParameters[CONFIG_ESSENCE_STAKING_APR_PER_10K])
                                 .mul(timeStakedSinceLastClaim)
                                 .div(365 days)
                                 .div(10000);
         }

         // Add yield from entities since last claim (simplified)
         EntityStake[] storage stakedEntities = _stakedEntities[msg.sender];
         for (uint i = 0; i < stakedEntities.length; i++) {
              uint256 timeStakedSinceLastClaim = block.timestamp.sub(stakedEntities[i].stakedTime);
              yieldSinceLastClaim = yieldSinceLastClaim.add(
                  configParameters[CONFIG_ENTITY_STAKING_APR_PER_10K]
                  .mul(timeStakedSinceLastClaim)
                  .div(365 days)
                  .div(10000)
               );
         }


        return _pendingYield[msg.sender].add(yieldSinceLastClaim); // Return previously snapshotted + newly accrued
    }

    /**
     * @dev Simulates a "Quest" or challenge outcome for an entity based on its stats and randomness.
     *      Applies decay before simulation. Modifies entity stats and potentially rewards Essence.
     * @param tokenId The ID of the entity.
     * @param questSeed A seed for randomness unique to the quest.
     * @return bool True if quest succeeded, false otherwise.
     */
    function simulateQuestOutcome(uint256 tokenId, bytes memory questSeed) public returns (bool success) {
        address entityOwner = ownerOf(tokenId);
        if (msg.sender != entityOwner && !_isApprovedOrOwner(msg.sender, tokenId)) revert Unauthorized();
        // Could cost Essence to attempt a quest
        // uint256 questCost = 50;
        // if (balanceOfEssence(msg.sender) < questCost) revert InsufficientEssenceForAction();
        // _burnEssence(msg.sender, questCost);

        applyAttributeDecay(tokenId);

        DigitalEntity storage entity = _entities[tokenId];

        // Base success chance influenced by stats (example: Avg(Str, Dex, Int, Res) / 4 + Purity / 10)
        uint256 baseChance = (entity.strength.add(entity.dexterity).add(entity.intelligence).add(entity.resilience)).div(4);
        baseChance = baseChance.add(entity.purity.div(10)); // Purity adds a little

        // Clamp base chance (e.g., between 10 and 90)
        baseChance = baseChance > 90 ? 90 : (baseChance < 10 ? 10 : baseChance);

        // Add randomness based on seed and block data
        uint256 randomFactor = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, tokenId, questSeed))) % 100; // 0-99

        uint256 finalChance = baseChance.add(randomFactor > 50 ? (randomFactor - 50) : -(50 - randomFactor)); // Add/subtract up to 50 based on randomness
        finalChance = finalChance > 100 ? 100 : (finalChance < 0 ? 0 : finalChance); // Clamp between 0 and 100

        success = randomFactor < finalChance; // Success if random number is less than final chance

        // Apply outcomes
        uint256 rewardAmount = 0;
        uint256 penaltyAmount = 0;

        if (success) {
            // Reward: Gain some Essence, maybe slight stat increase
            rewardAmount = 50; // Example reward
            _mintEssence(msg.sender, rewardAmount);
            // Small random stat boost
            uint8 boostAttribute = uint8(randomFactor % 4); // Str, Dex, Int, Res
            uint256 boostAmount = (randomFactor % 5) + 1; // 1-5
             if (boostAttribute == 0) entity.strength = entity.strength.add(boostAmount);
             else if (boostAttribute == 1) entity.dexterity = entity.dexterity.add(boostAmount);
             else if (boostAttribute == 2) entity.intelligence = entity.intelligence.add(boostAmount);
             else if (boostAttribute == 3) entity.resilience = entity.resilience.add(boostAmount);

             // Ensure stats don't exceed max
             uint256 maxAttribute = 200;
             if (entity.strength > maxAttribute) entity.strength = maxAttribute;
             if (entity.dexterity > maxAttribute) entity.dexterity = maxAttribute;
             if (entity.intelligence > maxAttribute) entity.intelligence = maxAttribute;
             if (entity.resilience > maxAttribute) entity.resilience = maxAttribute;

        } else {
            // Penalty: Lose some Essence, maybe slight stat decrease or energy loss
            penaltyAmount = 20; // Example penalty
             if (balanceOfEssence(msg.sender) >= penaltyAmount) {
                 _burnEssence(msg.sender, penaltyAmount);
             } else {
                 // If not enough essence, maybe reduce energy instead
                 entity.energy = entity.energy > penaltyAmount ? entity.energy.sub(penaltyAmount) : 0;
             }

            // Small random stat decrease
            uint8 decreaseAttribute = uint8(randomFactor % 4); // Str, Dex, Int, Res
            uint256 decreaseAmount = (randomFactor % 3) + 1; // 1-3
             uint256 minAttribute = 1;
             if (decreaseAttribute == 0) entity.strength = entity.strength > decreaseAmount ? entity.strength.sub(decreaseAmount) : minAttribute;
             else if (decreaseAttribute == 1) entity.dexterity = entity.dexterity > decreaseAmount ? entity.dexterity.sub(decreaseAmount) : minAttribute;
             else if (decreaseAttribute == 2) entity.intelligence = entity.intelligence > decreaseAmount ? entity.intelligence.sub(decreaseAmount) : minAttribute;
             else if (decreaseAttribute == 3) entity.resilience = entity.resilience > decreaseAmount ? entity.resilience.sub(decreaseAmount) : minAttribute;
        }

        entity.energy = entity.energy > 10 ? entity.energy.sub(10) : 0; // Quest always costs energy
        entity.lastInteractionTime = block.timestamp; // Update interaction time

        // More detailed event could be emitted here
        // event QuestCompleted(uint256 indexed tokenId, bool success, uint256 essenceReward, uint256 essencePenalty);
        // emit QuestCompleted(tokenId, success, rewardAmount, penaltyAmount);

        return success;
    }

    /**
     * @dev Allows burning an entity to recover some Essence based on its stats/maturity.
     * @param tokenId The ID of the entity to sacrifice.
     */
    function sacrificeEntityForEssence(uint256 tokenId) public {
        address entityOwner = ownerOf(tokenId);
        if (msg.sender != entityOwner) revert Unauthorized(); // Must be owner to sacrifice

        // Calculate Essence yield from sacrifice (example: based on Maturity and Purity)
        DigitalEntity storage entity = _entities[tokenId];
        uint256 essenceYield = entity.maturity.mul(10).add(entity.purity.mul(5)); // Example calculation

        // Burn the entity NFT
        // Need to manually handle internal state changes for burn
        address owner = ownerOf(tokenId); // Checks existence

        _entityBalances[owner] = _entityBalances[owner].sub(1);
        _owners[tokenId] = address(0); // Set owner to zero address to indicate burned
        delete _entities[tokenId]; // Remove entity attributes

        // Remove from _allTokens array (inefficient for large arrays) - Skip for simplicity in this example

        emit Transfer(owner, address(0), tokenId); // Emit burn event

        // Mint calculated Essence to the sacrificer
        if (essenceYield > 0) {
            _mintEssence(msg.sender, essenceYield);
            emit EssenceMinted(msg.sender, essenceYield); // Emit mint event
        }
    }
}
```

---

**Explanation of Advanced Concepts and Functions:**

1.  **Dynamic State / Mutable NFTs:** The `DigitalEntity` struct and the `_entities` mapping store mutable attributes (`strength`, `hunger`, `maturity`, etc.). Functions like `trainEntity`, `feedEntity`, `applyAttributeDecay`, `breedEntities`, `attemptMutation`, and `simulateQuestOutcome` directly modify this state. This is a core departure from standard static NFTs.
2.  **Time-Based Dynamics:** `lastInteractionTime` and `applyAttributeDecay` introduce a time-sensitive element. Entities require active management (`feedEntity`, `trainEntity`) to counteract decay, creating a game loop or maintenance mechanic. `_calculateTimeDecay` handles the time differential.
3.  **Probabilistic Outcomes:** `breedEntities`, `attemptMutation`, and `simulateQuestOutcome` use `keccak256` hashing with various block data and a user-provided seed to introduce randomness. While not cryptographically secure randomness for high-value applications (due to miner manipulation), it's a common on-chain pattern for simulating uncertainty in games or procedural generation.
4.  **Resource Token Integration:** `Essence` (ERC-20) is central. It's burned for actions (`trainEntity`, `feedEntity`, `breedEntities`, `attemptMutation`), minted as rewards (`claimStakingYield`, `simulateQuestOutcome`, `sacrificeEntityForEssence`), and is itself a stakeable asset. This creates an internal economy.
5.  **State Transitions:** `awakenEntity` represents a significant, irreversible state change for an NFT, altering its future behavior (no decay/training, enables staking). This adds depth and strategic choice.
6.  **Dual Staking:** The contract handles staking logic for *both* ERC-721 (`stakeEntity`, `unstakeEntity`) and ERC-20 (`stakeEssence`, `unstakeEssence`) assets within the same contract. This is less common than separate staking contracts and offers integrated yield claiming via `claimStakingYield`. The yield calculation (`_calculateYield`) considers both sources.
7.  **Simple On-Chain Governance:** The `proposeConfigChange`, `voteOnProposal`, and `executeProposal` functions implement a basic governance model where holders of staked assets (`_getVotingPower`) can vote on changing core contract parameters (`configParameters`). Quorum and supermajority checks (`_quorumPercentage`, `_supermajorityPercentage`) are included. This moves control away from a single owner over time.
8.  **Simulated Complex Interaction:** `simulateQuestOutcome` is an example of using internal state (entity attributes) and simulated randomness to determine the outcome of a complex event on-chain. This pattern can be extended for battles, crafting, exploration outcomes, etc.
9.  **NFT Burning with Utility:** `sacrificeEntityForEssence` provides an alternative utility for an NFT, allowing it to be destroyed in exchange for a resource, potentially balancing the ecosystem or providing a use for unwanted entities.

This contract provides a framework for a complex, interactive digital asset ecosystem, leveraging several advanced Solidity concepts beyond basic token standards or simple NFT ownership. It is designed to be a single point of interaction for managing assets, resources, and participating in the system's evolution.