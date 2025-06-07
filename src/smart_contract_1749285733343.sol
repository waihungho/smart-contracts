Okay, here is a Solidity smart contract implementing an "Evolving Digital Entities" system. This concept combines aspects of dynamic NFTs, resource management, user interaction-driven state changes, simple probabilistic outcomes, and basic on-chain governance for parameters.

It aims to be creative by having entity attributes that *actively* change based on time and user actions, not just being static metadata. It's trendy by incorporating NFT-like ownership and a simple resource token. It's advanced through the state update logic and parameter governance.

It does inherit from standard OpenZeppelin contracts (`ERC721`, `Ownable`, `Pausable`) for best practices and security, but the core logic for entity attributes, actions, and governance parameters is custom.

---

**Outline and Function Summary: EvolvingDigitalEntities**

This smart contract manages unique digital entities that have dynamic attributes which change over time and through user interactions. It includes a custom resource token required for certain actions and a simple on-chain governance system to adjust contract parameters.

**Core Concept:**
Users own "Entities" (represented as ERC721 tokens). Each Entity has attributes like Energy, Prowess, Mutation Potential, and Affinity. These attributes decay over time (Energy) or increase/change based on user actions (Nurture, Train, Mutate). A custom token, `NurtureDust`, is used to perform actions. A simple governance system allows approved governors to propose and execute changes to system parameters like costs, decay rates, and thresholds.

**Modules:**

1.  **Entity Management (Inherits ERC721):** Handles ownership, transfer, and basic NFT functions.
    *   `mintEntity`: Creates a new Entity token and assigns initial attributes.
    *   Standard ERC721 functions (`balanceOf`, `ownerOf`, `transferFrom`, etc.) are available through inheritance.

2.  **Attribute System:** Defines and manages the dynamic attributes of each Entity.
    *   `EntityAttributes` Struct: Stores Energy, Prowess, Mutation Potential, Affinity, last update timestamp, and staked status.
    *   `_updateAttributes`: Internal core logic to recalculate attributes based on elapsed time and apply decay/passive effects before any action.
    *   `getEntityAttributes`: View function to get the current attributes of an Entity (triggers `_updateAttributes` implicitly for the returned value).
    *   `getEnergy`, `getProwess`, `getMutationPotential`, `getAffinity`: View functions for specific attributes (trigger `_updateAttributes`).

3.  **Entity Actions:** User-initiated functions that cost `NurtureDust` and modify Entity attributes.
    *   `nurtureEntity`: Spends Dust to restore Entity Energy.
    *   `trainEntity`: Spends Dust to increase Entity Prowess.
    *   `attemptMutation`: Spends Dust for a probabilistic chance to mutate Entity attributes based on Mutation Potential.
    *   `stakeEntity`: Marks an Entity as staked, potentially granting benefits (e.g., slower decay, earning Dust).
    *   `unstakeEntity`: Unmarks a staked Entity.

4.  **NurtureDust Token:** A simple internal resource token.
    *   `balanceOfDust`: Get a user's `NurtureDust` balance.
    *   `mintDust`: (Governor-only) Mint `NurtureDust`. Can be used for initial distribution or rewards.
    *   `burnDust`: (Internal helper) Consumes `NurtureDust` for actions.
    *   `awardDustToStakers`: (Governor/Automated Trigger) Distributes Dust to staked entities (simplified implementation).

5.  **Governance System:** Allows approved governors to propose, vote on, and execute changes to configurable parameters.
    *   `proposeParameterChange`: Creates a new proposal to change a system parameter (e.g., costs, decay rates). Requires Dust fee.
    *   `voteOnProposal`: Allows users (or maybe token holders / entity owners) to vote on an active proposal. (Simplified: 1 Entity = 1 Vote).
    *   `executeProposal`: Executes a proposal if it has passed the deadline and met the required vote threshold.
    *   `getCurrentProposals`: View function to list active proposals.
    *   `getProposalVotes`: View function to see vote counts for a proposal.
    *   `setGovernor`: (Owner-only) Sets the address of the contract governor.

6.  **System & Admin:**
    *   `pause`, `unpause`: Pause/unpause sensitive contract functions.
    *   `withdrawFunds`: (Governor-only) Withdraw ETH from the contract (e.g., from mint fees, though not implemented here).
    *   `getTotalEntities`: View the total number of entities minted.
    *   `getContractBalance`: View the contract's ETH balance.
    *   `simulateGlobalEvent`: (Governor-only) A placeholder for triggering effects that modify all entities based on simulated external factors. (Simplified implementation).
    *   `getEntityMetadataURI`: Returns the base URI for entity metadata.
    *   `setEntityMetadataURI`: (Governor-only) Sets the base URI.

**Function Count Check (Public/External):**
1.  `mintEntity`
2.  `getEntityAttributes`
3.  `getEnergy`
4.  `getProwess`
5.  `getMutationPotential`
6.  `getAffinity`
7.  `nurtureEntity`
8.  `trainEntity`
9.  `attemptMutation`
10. `stakeEntity`
11. `unstakeEntity`
12. `balanceOfDust`
13. `mintDust` (Governor-only)
14. `awardDustToStakers` (Governor-only)
15. `proposeParameterChange`
16. `voteOnProposal`
17. `executeProposal`
18. `getCurrentProposals`
19. `getProposalVotes`
20. `pause` (Inherited, but exposed)
21. `unpause` (Inherited, but exposed)
22. `withdrawFunds` (Governor-only)
23. `getTotalEntities` (View)
24. `getContractBalance` (View)
25. `simulateGlobalEvent` (Governor-only)
26. `getEntityMetadataURI`
27. `setEntityMetadataURI` (Governor-only)
    + Standard ERC721 functions (approx 10 public/external).

Total public/external functions comfortably exceeds 20.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Custom Errors
error NotEnoughDust(uint256 required, uint256 has);
error EntityNotFound(uint256 tokenId);
error NotEntityOwner(uint256 tokenId, address owner);
error AlreadyStaked(uint256 tokenId);
error NotStaked(uint256 tokenId);
error InvalidProposalState(uint256 proposalId, ProposalState currentState);
error ProposalDoesNotExist(uint256 proposalId);
error VotingPeriodNotActive(uint256 proposalId);
error ProposalNotExpired(uint256 proposalId);
error ProposalThresholdNotMet(uint256 proposalId);
error InvalidAttributeType(uint8 attrType);
error OnlyGovernor(); // Using a modifier is cleaner, but custom error is also an option. Let's stick to modifier for simplicity with OpenZeppelin.
error GovernorNotSet();

contract EvolvingDigitalEntities is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    Counters.Counter private _entityIds;

    struct EntityAttributes {
        uint16 energy; // Decays over time
        uint16 prowess; // Increases with training
        uint8 mutationPotential; // Chance for random attribute change
        uint8 affinity; // Elemental/Type affinity (0-255)
        uint64 lastUpdated; // Timestamp of last attribute calculation
        bool isStaked;
    }

    mapping(uint256 => EntityAttributes) private _entityAttributes;
    mapping(address => uint256) private _dustBalances;
    mapping(address => uint256[] ether staked entities) private _stakedEntitiesByOwner; // Simple tracking

    // Configuration Parameters (Governed)
    struct Parameters {
        uint16 maxEnergy;
        uint256 energyDecayRatePerMinute; // Energy lost per minute
        uint256 nurtureCostDust;
        uint256 nurtureEnergyRestore;
        uint256 trainCostDust;
        uint256 trainProwessBoost;
        uint256 mutationCostDust;
        uint8 baseMutationChance; // Added to mutationPotential
        uint256 dustMintAmountGovernor; // Amount governor can mint per call (example)
        uint256 proposalFeeDust;
        uint64 votingPeriodDuration; // In seconds
        uint256 proposalQuorumThreshold; // Minimum votes needed
        uint256 proposalMajorityThreshold; // Percentage of votes needed (e.g., 51)
        uint256 stakingDustRewardPerMinutePerEntity;
    }
    Parameters public entityParams;

    // Governance
    enum AttributeType {
        MaxEnergy,
        EnergyDecayRatePerMinute,
        NurtureCostDust,
        NurtureEnergyRestore,
        TrainCostDust,
        TrainProwessBoost,
        MutationCostDust,
        BaseMutationChance,
        DustMintAmountGovernor,
        ProposalFeeDust,
        VotingPeriodDuration,
        ProposalQuorumThreshold,
        ProposalMajorityThreshold,
        StakingDustRewardPerMinutePerEntity
    }

    enum ProposalState {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        uint256 id;
        AttributeType attributeType;
        uint256 newValue;
        address proposer;
        uint64 votingDeadline;
        uint256 yeVotes;
        uint256 noVotes;
        ProposalState state;
        mapping(address => bool) hasVoted; // Prevent double voting
    }

    uint256 private _proposalCount;
    mapping(uint256 => Proposal) private _proposals;
    address public governor; // Separate role from contract owner

    string private _baseTokenURI;

    // --- Events ---

    event EntityMinted(uint256 tokenId, address owner, uint16 initialEnergy);
    event EntityAttributesUpdated(uint256 tokenId, uint16 energy, uint16 prowess, uint8 mutationPotential, uint8 affinity);
    event EnergyNurtured(uint256 tokenId, uint16 newEnergy, uint256 dustSpent);
    event ProwessTrained(uint256 tokenId, uint16 newProwess, uint256 dustSpent);
    event MutationAttempted(uint256 tokenId, bool success, uint256 dustSpent);
    event EntityMutated(uint256 tokenId, AttributeType changedAttribute, uint256 oldValue, uint256 newValue);
    event EntityStaked(uint256 tokenId, address owner);
    event EntityUnstaked(uint256 tokenId, address owner);
    event DustMinted(address recipient, uint256 amount);
    event DustBurned(address account, uint256 amount);
    event ProposalCreated(uint256 proposalId, AttributeType attributeType, uint256 newValue, address proposer, uint64 votingDeadline);
    event Voted(uint256 proposalId, address voter, bool support);
    event ProposalStateChanged(uint256 proposalId, ProposalState newState);
    event ParametersUpdated(AttributeType attributeType, uint256 newValue);
    event GlobalEventSimulated(uint256 eventCode, string description);

    // --- Constructor ---

    constructor(
        string memory name,
        string memory symbol,
        uint16 initialMaxEnergy,
        uint256 initialEnergyDecayRate,
        uint256 initialNurtureCost,
        uint256 initialNurtureRestore,
        uint256 initialTrainCost,
        uint256 initialTrainProwess,
        uint256 initialMutationCost,
        uint8 initialBaseMutationChance,
        uint256 initialDustMintAmountGovernor,
        uint256 initialProposalFeeDust,
        uint64 initialVotingPeriodDuration,
        uint256 initialProposalQuorumThreshold,
        uint256 initialProposalMajorityThreshold,
        uint256 initialStakingDustReward
    ) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        // Set initial parameters
        entityParams = Parameters({
            maxEnergy: initialMaxEnergy,
            energyDecayRatePerMinute: initialEnergyDecayRate,
            nurtureCostDust: initialNurtureCost,
            nurtureEnergyRestore: initialNurtureRestore,
            trainCostDust: initialTrainCost,
            trainProwessBoost: initialTrainProwess,
            mutationCostDust: initialMutationCost,
            baseMutationChance: initialBaseMutationChance,
            dustMintAmountGovernor: initialDustMintAmountGovernor,
            proposalFeeDust: initialProposalFeeDust,
            votingPeriodDuration: initialVotingPeriodDuration,
            proposalQuorumThreshold: initialProposalQuorumThreshold,
            proposalMajorityThreshold: initialProposalMajorityThreshold,
            stakingDustRewardPerMinutePerEntity: initialStakingDustReward
        });

        // Governor is initially the contract owner
        governor = msg.sender;
    }

    // --- Modifiers ---

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert OnlyGovernor();
        }
        _;
    }

    // --- Internal Helpers ---

    /**
     * @dev Charges NurtureDust from an account. Reverts if balance is insufficient.
     */
    function _chargeDust(address account, uint256 amount) internal {
        if (_dustBalances[account] < amount) {
            revert NotEnoughDust(_dustBalances[account], amount);
        }
        _dustBalances[account] = _dustBalances[account].sub(amount);
        emit DustBurned(account, amount);
    }

     /**
     * @dev Awards NurtureDust to an account.
     */
    function _awardDust(address account, uint256 amount) internal {
        _dustBalances[account] = _dustBalances[account].add(amount);
        // No event needed for internal award? Or maybe one for clarity? Let's omit for simplicity.
    }


    /**
     * @dev Calculates and applies attribute decay (Energy) and passive effects (Staking rewards).
     * This function should be called internally before accessing or modifying attributes.
     * @param tokenId The ID of the entity.
     * @return The updated EntityAttributes struct.
     */
    function _updateAttributes(uint256 tokenId) internal returns (EntityAttributes storage) {
        EntityAttributes storage attrs = _entityAttributes[tokenId];
        require(attrs.lastUpdated != 0, "Entity not initialized"); // Should not happen for valid tokens

        uint64 currentTime = uint64(block.timestamp);
        uint64 timePassed = currentTime - attrs.lastUpdated;

        // Apply Energy Decay (only if not staked for potentially slower decay, or different decay rate)
        // Simple decay for now, regardless of staking
        uint256 decayAmount = (uint256(timePassed) * entityParams.energyDecayRatePerMinute) / 60; // seconds to minutes
        if (decayAmount > 0) {
             if (attrs.energy > decayAmount) {
                attrs.energy = uint16(attrs.energy - decayAmount);
            } else {
                attrs.energy = 0;
            }
        }

        // Apply Staking Rewards (Dust)
        if (attrs.isStaked) {
             uint256 dustEarned = (uint256(timePassed) * entityParams.stakingDustRewardPerMinutePerEntity) / 60; // seconds to minutes
             if (dustEarned > 0) {
                 _awardDust(ownerOf(tokenId), dustEarned);
             }
        }


        attrs.lastUpdated = currentTime; // Update timestamp AFTER calculations
        // Note: Prowess and Mutation Potential are generally not decayed by time,
        // but could be added here if the design required it.

        // No event emitted here to avoid spam, event is emitted by calling public functions.
        return attrs;
    }

    /**
     * @dev Attempts a probabilistic mutation for an entity.
     * Internal function called by attemptMutation.
     * Uses a simple hash-based randomness (note: predictable on-chain).
     * @param tokenId The ID of the entity.
     */
    function _attemptMutationLogic(uint256 tokenId) internal {
        EntityAttributes storage attrs = _entityAttributes[tokenId];

        // Basic randomness: combine block data and entity ID
        // NOTE: This is NOT secure randomness and can be front-run.
        // For production, use Chainlink VRF or similar.
        uint256 randomSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId, tx.origin, block.number)));
        uint256 randomChoice = randomSeed % 4; // Decide which attribute *might* change

        uint8 oldVal;
        uint8 newVal;
        AttributeType changedAttrType;

        // Example simple mutation effects
        if (randomChoice == 0) {
            // Increase Energy Cap slightly (if below max)
             if (entityParams.maxEnergy < type(uint16).max) {
                 oldVal = uint8(entityParams.maxEnergy / 100); // Example mapping to uint8
                 entityParams.maxEnergy = entityParams.maxEnergy + 10; // Flat boost
                 newVal = uint8(entityParams.maxEnergy / 100);
                 changedAttrType = AttributeType.MaxEnergy;
                 // Also boost current energy? Or leave it? Let's boost slightly.
                 attrs.energy = uint16(Math.min(uint256(attrs.energy) + 20, entityParams.maxEnergy));
             }
        } else if (randomChoice == 1) {
            // Boost Prowess
            oldVal = uint8(attrs.prowess / 100); // Example mapping to uint8
            attrs.prowess = attrs.prowess + 5; // Flat boost
            newVal = uint8(attrs.prowess / 100);
            changedAttrType = AttributeType.TrainProwessBoost; // Signify change related to Prowess
        } else if (randomChoice == 2) {
            // Change Affinity (randomly)
            oldVal = attrs.affinity;
            attrs.affinity = uint8(randomSeed % 256);
            newVal = attrs.affinity;
            changedAttrType = AttributeType.BaseMutationChance; // Signify change related to Mutation
        } else { // randomChoice == 3
            // Increase Mutation Potential
             oldVal = attrs.mutationPotential;
             attrs.mutationPotential = uint8(Math.min(uint256(attrs.mutationPotential) + 2, 100)); // Cap at 100
             newVal = attrs.mutationPotential;
             changedAttrType = AttributeType.BaseMutationChance;
        }

        if (oldVal != newVal) { // Only emit if something actually changed significantly
             emit EntityMutated(tokenId, changedAttrType, oldVal, newVal);
        }
    }


    /**
     * @dev Gets the number of entities owned by an address.
     * Overridden to handle potential ERC721Enumerable if needed, but base is fine.
     */
    // function balanceOf(address owner) public view override returns (uint256) {
    //     return super.balanceOf(owner);
    // }

    /**
     * @dev Returns the owner of the entity with the given tokenId.
     * Overridden just to show it's part of the contract.
     */
    // function ownerOf(uint256 tokenId) public view override returns (address) {
    //    return super.ownerOf(tokenId);
    // }


    // --- Entity Management ---

    /**
     * @dev Mints a new Entity and assigns initial attributes.
     * @param recipient The address to mint the entity to.
     * @return The ID of the new entity.
     */
    function mintEntity(address recipient) public onlyOwner whenNotPaused returns (uint256) {
        _entityIds.increment();
        uint256 newItemId = _entityIds.current();

        // Initial attributes (can be randomized or fixed)
        // Using simple blockhash based seed for uniqueness (not for security)
        uint256 initialSeed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, newItemId, block.number)));

        _entityAttributes[newItemId] = EntityAttributes({
            energy: entityParams.maxEnergy, // Start with full energy
            prowess: uint16(initialSeed % 100), // Random initial prowess (0-99)
            mutationPotential: uint8((initialSeed / 100) % 10), // Random initial potential (0-9)
            affinity: uint8((initialSeed / 1000) % 256), // Random initial affinity (0-255)
            lastUpdated: uint64(block.timestamp),
            isStaked: false
        });

        _safeMint(recipient, newItemId);

        emit EntityMinted(newItemId, recipient, entityParams.maxEnergy);

        return newItemId;
    }

    // --- Attribute System & Views ---

     /**
     * @dev Gets the current attributes of an entity after applying time-based updates.
     * @param tokenId The ID of the entity.
     * @return EntityAttributes struct.
     */
    function getEntityAttributes(uint256 tokenId) public returns (EntityAttributes memory) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
         // Use memory for return value, but storage for internal update
        EntityAttributes storage attrs = _entityAttributes[tokenId];
        _updateAttributes(tokenId); // Apply decay/rewards before returning latest state
        return attrs;
    }

    /**
     * @dev Gets the current energy of an entity.
     */
    function getEnergy(uint256 tokenId) public returns (uint16) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _updateAttributes(tokenId).energy;
    }

    /**
     * @dev Gets the current prowess of an entity.
     */
    function getProwess(uint256 tokenId) public returns (uint16) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _updateAttributes(tokenId).prowess;
    }

    /**
     * @dev Gets the current mutation potential of an entity.
     */
    function getMutationPotential(uint256 tokenId) public returns (uint8) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _updateAttributes(tokenId).mutationPotential;
    }

     /**
     * @dev Gets the current affinity of an entity.
     */
    function getAffinity(uint256 tokenId) public returns (uint8) {
         require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _updateAttributes(tokenId).affinity;
    }

    // --- Entity Actions ---

    /**
     * @dev Nurtures an entity, restoring energy. Costs NurtureDust.
     * @param tokenId The ID of the entity to nurture.
     */
    function nurtureEntity(uint256 tokenId) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        EntityAttributes storage attrs = _updateAttributes(tokenId); // Update before action

        _chargeDust(msg.sender, entityParams.nurtureCostDust);

        uint256 newEnergy = uint256(attrs.energy).add(entityParams.nurtureEnergyRestore);
        attrs.energy = uint16(Math.min(newEnergy, uint256(entityParams.maxEnergy))); // Cap at max energy

        emit EnergyNurtured(tokenId, attrs.energy, entityParams.nurtureCostDust);
        emit EntityAttributesUpdated(tokenId, attrs.energy, attrs.prowess, attrs.mutationPotential, attrs.affinity);
    }

    /**
     * @dev Trains an entity, increasing prowess. Costs NurtureDust.
     * @param tokenId The ID of the entity to train.
     */
    function trainEntity(uint256 tokenId) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        EntityAttributes storage attrs = _updateAttributes(tokenId); // Update before action

        _chargeDust(msg.sender, entityParams.trainCostDust);

        attrs.prowess = uint16(uint256(attrs.prowess).add(entityParams.trainProwessBoost)); // Prowess can exceed 100

        emit ProwessTrained(tokenId, attrs.prowess, entityParams.trainCostDust);
        emit EntityAttributesUpdated(tokenId, attrs.energy, attrs.prowess, attrs.mutationPotential, attrs.affinity);
    }

    /**
     * @dev Attempts a mutation for an entity. Costs NurtureDust and is probabilistic.
     * @param tokenId The ID of the entity.
     */
    function attemptMutation(uint256 tokenId) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        EntityAttributes storage attrs = _updateAttributes(tokenId); // Update before action

        _chargeDust(msg.sender, entityParams.mutationCostDust);

        // Probabilistic check based on current potential + base chance
        // Using block.timestamp is NOT secure randomness
        uint256 randomChance = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))) % 100;
        uint256 effectiveChance = uint256(attrs.mutationPotential).add(entityParams.baseMutationChance);

        bool success = randomChance < effectiveChance;

        if (success) {
            _attemptMutationLogic(tokenId); // Apply mutation effects
        }

        emit MutationAttempted(tokenId, success, entityParams.mutationCostDust);
        emit EntityAttributesUpdated(tokenId, attrs.energy, attrs.prowess, attrs.mutationPotential, attrs.affinity);
    }

    /**
     * @dev Stakes an entity. Marks it as staked and potentially grants benefits.
     * Does NOT transfer entity ownership for simplicity in this example.
     * A more complex system might transfer to the contract or a staking module.
     * @param tokenId The ID of the entity to stake.
     */
    function stakeEntity(uint256 tokenId) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        EntityAttributes storage attrs = _entityAttributes[tokenId]; // No need to update attributes *before* staking

        if (attrs.isStaked) revert AlreadyStaked(tokenId);

        attrs.isStaked = true;
        // Add to staked list (simple tracking, inefficient for many entities per owner)
        _stakedEntitiesByOwner[msg.sender].push(tokenId);

        // Initial attribute update immediately after staking to start passive effects from now
        _updateAttributes(tokenId);

        emit EntityStaked(tokenId, msg.sender);
    }

    /**
     * @dev Unstakes an entity. Marks it as unstaked and removes benefits.
     * @param tokenId The ID of the entity to unstake.
     */
    function unstakeEntity(uint256 tokenId) public whenNotPaused {
        require(ownerOf(tokenId) == msg.sender, "Not entity owner");
        EntityAttributes storage attrs = _entityAttributes[tokenId];

        if (!attrs.isStaked) revert NotStaked(tokenId);

        attrs.isStaked = false;
        // Remove from staked list (simple inefficient removal)
        uint256[] storage stakedTokens = _stakedEntitiesByOwner[msg.sender];
        for (uint256 i = 0; i < stakedTokens.length; i++) {
            if (stakedTokens[i] == tokenId) {
                stakedTokens[i] = stakedTokens[stakedTokens.length - 1];
                stakedTokens.pop();
                break;
            }
        }

         // Final attribute update immediately before unstaking to apply last passive effects
        _updateAttributes(tokenId);

        emit EntityUnstaked(tokenId, msg.sender);
    }

    // --- NurtureDust Token System ---

    /**
     * @dev Gets the NurtureDust balance of an address.
     * @param account The address to check.
     * @return The Dust balance.
     */
    function balanceOfDust(address account) public view returns (uint256) {
        return _dustBalances[account];
    }

    /**
     * @dev Mints NurtureDust to a recipient. Only callable by the governor.
     * Useful for initial distribution or rewards.
     * @param recipient The address to send Dust to.
     */
    function mintDust(address recipient) public onlyGovernor {
        uint256 amount = entityParams.dustMintAmountGovernor; // Fixed amount per call for simplicity
        _dustBalances[recipient] = _dustBalances[recipient].add(amount);
        emit DustMinted(recipient, amount);
    }

    /**
     * @dev Awards dust to all currently staked entities.
     * Intended to be called by the governor or a trusted keeper/automation.
     * Simplified: iterates through all token IDs, check if staked, apply reward.
     * NOTE: Iterating through all tokens can be gas-intensive if there are many.
     * A better approach might be to track total staked time or use a claim system.
     */
    function awardDustToStakers() public onlyGovernor {
        // THIS IS HIGHLY INEFFICIENT FOR LARGE NUMBERS OF ENTITIES.
        // IT'S AN EXAMPLE OF THE *CONCEPT*, NOT PRODUCTION-READY FOR SCALABILITY.
        // A real system would use accumulated rewards or a per-staker claim pattern.
         uint256 totalEntities = _entityIds.current();
         uint256 totalDustAwarded = 0;

        for (uint256 i = 1; i <= totalEntities; i++) {
            if (_exists(i)) { // Check if token exists and hasn't been burned/transferred oddly
                EntityAttributes storage attrs = _entityAttributes[i];
                if (attrs.isStaked) {
                    // Recalculate attributes to award dust since last update
                    uint64 currentTime = uint64(block.timestamp);
                    uint64 timePassed = currentTime - attrs.lastUpdated;
                    uint256 dustEarned = (uint256(timePassed) * entityParams.stakingDustRewardPerMinutePerEntity) / 60;
                    if (dustEarned > 0) {
                        address owner = ownerOf(i); // Get current owner
                        _awardDust(owner, dustEarned);
                        totalDustAwarded = totalDustAwarded.add(dustEarned);
                    }
                     attrs.lastUpdated = currentTime; // Update timestamp
                }
            }
        }
        // Emit a general event for the batch award? Or rely on internal _awardDust logs?
        // Let's add a summary event.
        // event StakingRewardsDistributed(uint256 totalAmount, uint256 numberOfEntitiesAffected);
        // emit StakingRewardsDistributed(totalDustAwarded, 0); // Cannot easily count affected entities here
    }


    // --- Governance System ---

    /**
     * @dev Gets the current proposal count.
     */
    function getProposalCount() public view returns (uint256) {
        return _proposalCount;
    }

    /**
     * @dev Gets details for a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Proposal struct details.
     */
    function getProposal(uint256 proposalId) public view returns (
        uint256 id,
        AttributeType attributeType,
        uint256 newValue,
        address proposer,
        uint64 votingDeadline,
        uint256 yeVotes,
        uint256 noVotes,
        ProposalState state
    ) {
        require(proposalId > 0 && proposalId <= _proposalCount, "Invalid proposal ID");
        Proposal storage proposal = _proposals[proposalId];
        return (
            proposal.id,
            proposal.attributeType,
            proposal.newValue,
            proposal.proposer,
            proposal.votingDeadline,
            proposal.yeVotes,
            proposal.noVotes,
            proposal.state
        );
    }


    /**
     * @dev Gets the current list of active proposals.
     * Limited to a certain number to avoid gas issues if many exist.
     * @param startIndex The starting index (inclusive).
     * @param count The maximum number of proposals to return.
     * @return Array of active proposal IDs.
     */
    function getCurrentProposals(uint256 startIndex, uint256 count) public view returns (uint256[] memory) {
        uint256 total = _proposalCount;
        if (startIndex >= total) return new uint256[](0);

        uint256 endIndex = startIndex + count;
        if (endIndex > total) endIndex = total;

        uint256[] memory activeIds = new uint256[](endIndex - startIndex);
        uint256 currentIdx = 0;
        for (uint256 i = startIndex + 1; i <= endIndex; i++) { // Proposal IDs start from 1
             if (_proposals[i].state == ProposalState.Pending || _proposals[i].state == ProposalState.Active) {
                 activeIds[currentIdx] = i;
                 currentIdx++;
             }
        }
         // Resize array to actual number of active proposals found in range
         uint256[] memory result = new uint256[](currentIdx);
         for(uint256 i = 0; i < currentIdx; i++) {
             result[i] = activeIds[i];
         }
         return result;
    }


    /**
     * @dev Gets the vote counts for a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return yeVotes The number of 'yes' votes.
     * @return noVotes The number of 'no' votes.
     */
    function getProposalVotes(uint256 proposalId) public view returns (uint256 yeVotes, uint256 noVotes) {
         require(proposalId > 0 && proposalId <= _proposalCount, "Invalid proposal ID");
         Proposal storage proposal = _proposals[proposalId];
         return (proposal.yeVotes, proposal.noVotes);
    }


    /**
     * @dev Proposes a change to a contract parameter. Costs NurtureDust.
     * Only callable by the governor.
     * @param attrType The AttributeType enum value for the parameter.
     * @param newValue The proposed new value for the parameter.
     */
    function proposeParameterChange(AttributeType attrType, uint256 newValue) public onlyGovernor whenNotPaused {
        // Check if the attribute type is valid
        // Example check (can add more specific range checks if needed)
        if (uint8(attrType) > uint8(AttributeType.StakingDustRewardPerMinutePerEntity)) {
             revert InvalidAttributeType(uint8(attrType));
        }

        // Charge proposer a fee in Dust
        _chargeDust(msg.sender, entityParams.proposalFeeDust);

        _proposalCount++;
        uint256 proposalId = _proposalCount;
        uint64 votingDeadline = uint64(block.timestamp) + entityParams.votingPeriodDuration;

        _proposals[proposalId] = Proposal({
            id: proposalId,
            attributeType: attrType,
            newValue: newValue,
            proposer: msg.sender,
            votingDeadline: votingDeadline,
            yeVotes: 0,
            noVotes: 0,
            state: ProposalState.Active, // Starts as Active immediately
            // hasVoted mapping is inside the struct storage
            0: false // Placeholder to avoid stack too deep error with mapping
        });

        emit ProposalCreated(proposalId, attrType, newValue, msg.sender, votingDeadline);
        emit ProposalStateChanged(proposalId, ProposalState.Active);
    }


    /**
     * @dev Votes on an active proposal. Users can vote 'yes' (support) or 'no'.
     * Simplified: 1 ERC721 Entity owned counts as 1 vote. Requires owner of at least one entity.
     * @param proposalId The ID of the proposal.
     * @param support True for 'yes', False for 'no'.
     */
    function voteOnProposal(uint256 proposalId, bool support) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) revert ProposalDoesNotExist(proposalId); // Check if proposal exists
        if (proposal.state != ProposalState.Active) revert InvalidProposalState(proposalId, proposal.state);
        if (uint64(block.timestamp) > proposal.votingDeadline) revert VotingPeriodNotActive(proposalId);
        if (proposal.hasVoted[msg.sender]) revert("Already voted");

        // Determine voting power (Example: Number of entities owned)
        // For a more advanced system, this could be staked tokens, total prowess of entities, etc.
        uint256 votingPower = balanceOf(msg.sender); // Standard ERC721 balance
        if (votingPower == 0) revert("No voting power (own at least one entity)");

        if (support) {
            proposal.yeVotes = proposal.yeVotes.add(votingPower);
        } else {
            proposal.noVotes = proposal.noVotes.add(votingPower);
        }

        proposal.hasVoted[msg.sender] = true;

        emit Voted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a proposal if the voting period has ended and thresholds are met.
     * Any user can trigger execution after the deadline.
     * @param proposalId The ID of the proposal.
     */
    function executeProposal(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.id == 0) revert ProposalDoesNotExist(proposalId);
        if (proposal.state != ProposalState.Active) revert InvalidProposalState(proposalId, proposal.state);
        if (uint64(block.timestamp) <= proposal.votingDeadline) revert ProposalNotExpired(proposalId);

        uint256 totalVotes = proposal.yeVotes.add(proposal.noVotes);

        // Check quorum (minimum total votes)
        if (totalVotes < entityParams.proposalQuorumThreshold) {
            proposal.state = ProposalState.Failed;
             emit ProposalStateChanged(proposalId, ProposalState.Failed);
             revert ProposalThresholdNotMet(proposalId); // Or just return/log failure without revert? Revert is clearer.
        }

        // Check majority (percentage of yes votes)
        bool passed = (proposal.yeVotes.mul(100)) / totalVotes >= entityParams.proposalMajorityThreshold;

        if (passed) {
            // Update the corresponding parameter
            uint256 oldValue;
            uint256 newValue = proposal.newValue;

            // Need to handle different parameter types
            if (proposal.attributeType == AttributeType.MaxEnergy) { oldValue = entityParams.maxEnergy; entityParams.maxEnergy = uint16(newValue); }
            else if (proposal.attributeType == AttributeType.EnergyDecayRatePerMinute) { oldValue = entityParams.energyDecayRatePerMinute; entityParams.energyDecayRatePerMinute = newValue; }
            else if (proposal.attributeType == AttributeType.NurtureCostDust) { oldValue = entityParams.nurtureCostDust; entityParams.nurtureCostDust = newValue; }
            else if (proposal.attributeType == AttributeType.NurtureEnergyRestore) { oldValue = entityParams.nurtureEnergyRestore; entityParams.nurtureEnergyRestore = newValue; }
            else if (proposal.attributeType == AttributeType.TrainCostDust) { oldValue = entityParams.trainCostDust; entityParams.trainCostDust = newValue; }
            else if (proposal.attributeType == AttributeType.TrainProwessBoost) { oldValue = entityParams.trainProwessBoost; entityParams.trainProwessBoost = newValue; }
            else if (proposal.attributeType == AttributeType.MutationCostDust) { oldValue = entityParams.mutationCostDust; entityParams.mutationCostDust = newValue; }
            else if (proposal.attributeType == AttributeType.BaseMutationChance) { oldValue = entityParams.baseMutationChance; entityParams.baseMutationChance = uint8(newValue); }
            else if (proposal.attributeType == AttributeType.DustMintAmountGovernor) { oldValue = entityParams.dustMintAmountGovernor; entityParams.dustMintAmountGovernor = newValue; }
            else if (proposal.attributeType == AttributeType.ProposalFeeDust) { oldValue = entityParams.proposalFeeDust; entityParams.proposalFeeDust = newValue; }
            else if (proposal.attributeType == AttributeType.VotingPeriodDuration) { oldValue = entityParams.votingPeriodDuration; entityParams.votingPeriodDuration = uint64(newValue); }
            else if (proposal.attributeType == AttributeType.ProposalQuorumThreshold) { oldValue = entityParams.proposalQuorumThreshold; entityParams.proposalQuorumThreshold = newValue; }
            else if (proposal.attributeType == AttributeType.ProposalMajorityThreshold) { oldValue = entityParams.proposalMajorityThreshold; entityParams.proposalMajorityThreshold = newValue; }
             else if (proposal.attributeType == AttributeType.StakingDustRewardPerMinutePerEntity) { oldValue = entityParams.stakingDustRewardPerMinutePerEntity; entityParams.stakingDustRewardPerMinutePerEntity = newValue; }
            else {
                // Should not happen if proposal creation is restricted to valid types
                 revert InvalidAttributeType(uint8(proposal.attributeType));
            }

            proposal.state = ProposalState.Succeeded; // Mark as succeeded before executing
            emit ProposalStateChanged(proposalId, ProposalState.Succeeded);
            emit ParametersUpdated(proposal.attributeType, proposal.newValue);

            proposal.state = ProposalState.Executed; // Mark as executed
            emit ProposalStateChanged(proposalId, ProposalState.Executed);

        } else {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(proposalId, ProposalState.Failed);
        }
    }

     /**
     * @dev Sets the address of the contract governor. Only callable by the contract owner.
     * The governor is responsible for proposing parameter changes, minting dust, and triggering global events.
     * @param _governor The new governor address.
     */
    function setGovernor(address _governor) public onlyOwner {
        require(_governor != address(0), "Governor cannot be zero address");
        governor = _governor;
        emit OwnershipTransferred(owner(), _governor); // Reusing OwnershipTransferred event from Ownable? Or define new one. Let's use a new one for clarity.
        // event GovernorSet(address oldGovernor, address newGovernor);
        // emit GovernorSet(oldGovernor, _governor); // Need to store old governor to emit
        // Let's just emit that governor was updated
        emit ParametersUpdated(AttributeType.DustMintAmountGovernor, uint256(uint160(_governor))); // Hacky way to signal governor change via ParametersUpdated
    }


    // --- System & Admin ---

    /**
     * @dev Triggers a simulated global event affecting all entities.
     * Only callable by the governor.
     * This is a placeholder function; the actual logic would be complex.
     * Example: A "Solar Flare" reduces all entities' energy by a percentage.
     * NOTE: Directly iterating through all tokens is NOT gas efficient.
     * A better approach would be to store global modifiers that _updateAttributes checks.
     * @param eventCode A numerical code for the event type.
     * @param description A description of the event.
     */
    function simulateGlobalEvent(uint256 eventCode, string memory description) public onlyGovernor {
         // THIS IS HIGHLY INEFFICIENT FOR LARGE NUMBERS OF ENTITIES.
         // A production system would use a global state variable or a claim system
         // to apply effects lazily or via user claims.
         uint256 totalEntities = _entityIds.current();

         // Example: Event 1 = Energy Drain
         if (eventCode == 1) {
             for (uint256 i = 1; i <= totalEntities; i++) {
                 if (_exists(i)) {
                     EntityAttributes storage attrs = _entityAttributes[i];
                      _updateAttributes(i); // Update first
                     uint256 drainAmount = uint256(attrs.energy) / 10; // Drain 10%
                     if (attrs.energy > drainAmount) {
                         attrs.energy = uint16(attrs.energy - drainAmount);
                     } else {
                         attrs.energy = 0;
                     }
                     // Emit EntityAttributesUpdated(i, attrs.energy, attrs.prowess, attrs.mutationPotential, attrs.affinity); // Too many events
                 }
             }
         }
         // Add more event codes/logic here...

        emit GlobalEventSimulated(eventCode, description);
    }

    /**
     * @dev Withdraws contract balance (e.g., ETH) to the governor.
     * In this example, fees are in Dust, so this might be used for initial ETH sent to contract.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawFunds(uint256 amount) public onlyGovernor {
        require(address(this).balance >= amount, "Insufficient contract balance");
        (bool success, ) = payable(governor).call{value: amount}("");
        require(success, "ETH transfer failed");
    }

     /**
     * @dev Gets the total number of entities that have been minted.
     * @return The total count.
     */
    function getTotalEntities() public view returns (uint256) {
        return _entityIds.current();
    }

    /**
     * @dev Gets the contract's current ETH balance.
     * @return The ETH balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- ERC721 Overrides ---

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Sets the base URI for token metadata. Only callable by the governor.
     * @param baseURI The new base URI.
     */
    function setEntityMetadataURI(string memory baseURI) public onlyGovernor {
        _baseTokenURI = baseURI;
    }

    // The following functions are standard ERC721 overrides.
    // We don't need to modify their logic here, the core Entity logic
    // happens in the custom functions.
    // function approve(address to, uint256 tokenId) public override(ERC721, IERC721) {}
    // function getApproved(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {}
    // function isApprovedForAll(address owner, address operator) public view override(ERC721, IERC721) returns (bool) {}
    // function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) {}
    // function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {}
    // function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {}
    // function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) {}


    // --- Pausable Overrides ---
    function pause() public onlyOwner override {
        super.pause();
    }

    function unpause() public onlyOwner override {
        super.unpause();
    }

    // --- Receive ETH ---
    // Allow contract to receive ETH (e.g., if someone sends ETH mistakenly or for future features)
    receive() external payable {}
}
```