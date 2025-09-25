Here's a smart contract that embodies advanced concepts, creativity, and modern trends without directly duplicating existing open-source contracts, focusing on the unique interplay of collective intelligence, dynamic NFTs, and an evolving autonomous entity.

---

## AEDE_CognitiveNexus Smart Contract

This contract establishes an **Autonomous Evolving Digital Entity (AEDE)**, named "Cognitive Nexus." The AEDE's growth, direction, and even its "mood" or "aspect" are collectively governed by its participants through a Decentralized Autonomous Organization (DAO). Participants interact with the AEDE by holding unique, non-transferable **Soul Fragments (Dynamic Soulbound NFTs)** that represent their contribution and connection to the entity. The AEDE evolves based on collective "Knowledge Units" and "Evolution Points," influenced by participant actions and external oracle data.

### Contract Outline:

1.  **AEDE State Management:** Core variables defining the AEDE's current evolutionary stage, dominant aspect, accumulated resources, and historical events.
2.  **Soul Fragment (Dynamic SBT) System:** A custom implementation for non-transferable NFTs that evolve traits based on owner actions and AEDE state.
3.  **Governance (DAO) Module:** Mechanics for submitting, voting on, and executing proposals that directly influence the AEDE's evolution and actions.
4.  **Resource & Gamification Layer:** Mechanisms for users to contribute "Knowledge Units" and "Evolution Essence" to the AEDE, fostering collective growth.
5.  **Oracle Integration:** A system to receive external data that can trigger "Anomaly Events" or influence AEDE's evolution path.

### Function Summary:

#### AEDE Core State & Evolution (6 functions)
1.  **`initializeAEDE(string memory _initialAspect)`**: Initializes the AEDE with its first dominant aspect. Callable only once by the deployer.
2.  **`updateAEDEAspect(string memory _newAspect)`**: Changes the AEDE's dominant aspect, typically triggered by a passed DAO proposal.
3.  **`triggerAEDEEvolution(bytes memory _evolutionPayload)`**: Advances the AEDE to a new level if enough `evolutionPoints` are accumulated. Requires DAO approval or specific internal conditions. `_evolutionPayload` could contain parameters for new state.
4.  **`triggerAEDEAnomalyEvent(string memory _eventType, bytes memory _eventData)`**: Internal/Oracle-triggered function to register and react to external anomaly events that influence the AEDE's environment or internal state.
5.  **`initiateMutationProtocol(string memory _mutationType)`**: Triggers a 'mutation' phase for the AEDE, potentially altering its fundamental behavior or capabilities. Requires DAO vote and cooldown.
6.  **`getCurrentAEDEState()`**: Returns the comprehensive current state of the AEDE.

#### Soul Fragment (Dynamic SBT) Management (6 functions)
7.  **`mintSoulFragment(address _recipient, string memory _initialTrait)`**: Mints a new, non-transferable Soul Fragment NFT for a specific address. Represents a participant's connection.
8.  **`attuneSoulFragmentTrait(uint256 _fragmentId, string memory _newTrait)`**: Allows a Soul Fragment owner to attune their fragment's primary trait, influencing the AEDE's collective consciousness. Costs Knowledge Units.
9.  **`evolveSoulFragmentMood(uint256 _fragmentId, string memory _newMood)`**: Updates a fragment's 'mood' based on AEDE state or owner's recent contributions.
10. **`getSoulFragmentDetails(uint256 _fragmentId)`**: Retrieves all details for a specific Soul Fragment.
11. **`updateContributionScore(address _contributor, uint256 _scoreIncrease)`**: Increases a participant's contribution score, affecting their governance power and fragment traits.
12. **`burnSoulFragment(uint256 _fragmentId)`**: Allows an owner to voluntarily burn their Soul Fragment, severing their connection.

#### Governance & DAO (6 functions)
13. **`submitProposal(string memory _description, address _target, bytes memory _callData, uint256 _executionDelay)`**: Allows participants with sufficient governance power to submit a new proposal for the AEDE's direction.
14. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Casts a vote (yes/no) on an active proposal, weighted by the participant's governance power.
15. **`executeProposal(uint256 _proposalId)`**: Executes a proposal if it has passed the voting threshold and the execution delay has passed.
16. **`delegateGovernancePower(address _delegatee)`**: Delegates voting power to another address.
17. **`revokeGovernancePower()`**: Revokes any active governance delegation.
18. **`getProposalState(uint256 _proposalId)`**: Returns the current state and details of a specific proposal.

#### Resource & Gamification (5 functions)
19. **`contributeKnowledge(uint256 _amount)`**: Users contribute an `_amount` of "Knowledge Units" to the AEDE's collective pool, potentially earning personal rewards or increasing contribution score.
20. **`harvestEvolutionEssence()`**: A time-gated function allowing users to "harvest" Evolution Essence, adding to the AEDE's total Evolution Points.
21. **`claimAEDEInsightReward()`**: Allows users to claim a reward (e.g., more `KnowledgeUnits` or a temporary boost) based on their contribution score and the AEDE's current level.
22. **`setOracleAddress(address _newOracle)`**: Sets the address of the external oracle that can feed data to the AEDE.
23. **`retrieveOracleData(bytes memory _data)`**: Callable only by the designated oracle, pushes external data into the contract to potentially trigger internal events.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Custom error for better readability and gas efficiency
error AEDE_InvalidSoulFragmentOwner();
error AEDE_SoulFragmentNotFound();
error AEDE_AlreadyInitialized();
error AEDE_NotInitialized();
error AEDE_InsufficientKnowledgeUnits();
error AEDE_NotEnoughEvolutionPoints();
error AEDE_MutationCooldownActive();
error AEDE_InsufficientGovernancePower();
error AEDE_ProposalNotFound();
error AEDE_AlreadyVoted();
error AEDE_VotingPeriodNotEnded();
error AEDE_ExecutionDelayNotPassed();
error AEDE_ProposalAlreadyExecuted();
error AEDE_ProposalFailed();
error AEDE_OracleUnauthorized();
error AEDE_HarvestCooldownActive();

/**
 * @title AEDE_CognitiveNexus
 * @dev An Autonomous Evolving Digital Entity (AEDE) governed by a DAO, with dynamic, soulbound NFTs
 *      representing participant connection and influence. The AEDE evolves based on collective
 *      contributions and external oracle data, driving a unique on-chain narrative.
 */
contract AEDE_CognitiveNexus is Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    // --- AEDE Core State ---
    bool public isAEDEInitialized;
    uint256 public currentAEDELevel;
    string public currentAEDEAspect; // e.g., "Explorer", "Builder", "Protector"
    uint256 public totalEvolutionPoints;
    uint256 public totalKnowledgeUnits;
    uint256 public lastMutationTimestamp;

    // --- Configuration Constants ---
    uint256 public constant EVOLUTION_THRESHOLD_PER_LEVEL = 1000;
    uint256 public constant MUTATION_COOLDOWN = 30 days; // Cooldown for triggering major mutations
    uint256 public constant HARVEST_COOLDOWN = 1 days;   // Cooldown for harvesting essence
    uint256 public constant MIN_GOVERNANCE_POWER_FOR_PROPOSAL = 100; // Min power to submit proposals
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days;
    uint256 public constant PROPOSAL_PASS_THRESHOLD_PERCENT = 51; // 51% of total votes cast
    uint256 public constant ATTUNE_TRAIT_COST_KU = 50; // Cost in Knowledge Units to attune a trait

    // --- Soul Fragment (Dynamic Soulbound NFT) System ---
    struct AEDESoulFragment {
        uint256 id;
        address owner;
        uint256 mintedTimestamp;
        uint256 contributionScore; // Reflects owner's overall engagement
        string trait;             // Customizable by owner, influences AEDE's aspect
        string currentMood;       // Dynamic, can change based on AEDE state or owner actions
        uint256 lastEssenceHarvest; // Timestamp of last harvest
    }

    Counters.Counter private _soulFragmentIds;
    mapping(uint256 => AEDESoulFragment) public soulFragments;
    mapping(address => EnumerableSet.UintSet) private _ownerSoulFragmentIds; // Store fragment IDs per owner
    mapping(address => uint256) public userTotalContributionScore; // Aggregate score across all fragments for an owner

    // --- Governance (DAO) Module ---
    struct Proposal {
        uint256 id;
        string description;
        address target;          // Address of the contract to call
        bytes callData;          // Encoded function call
        uint256 submissionTimestamp;
        uint256 votingDeadline;
        uint256 executionDelayEnd; // Timestamp when proposal can be executed
        uint256 yesVotes;
        uint256 noVotes;
        uint256 totalVotesCastPower; // Sum of governance power from all voters
        EnumerableSet.AddressSet voters; // Addresses that have voted
        bool executed;
    }

    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public governancePower; // Based on contribution score & fragment ownership
    mapping(address => address) public delegatedPower; // Address an owner has delegated their power to

    // --- External Oracle Integration ---
    address public externalOracleAddress;

    // --- Events ---
    event AEDEInitialized(address indexed deployer, string initialAspect);
    event AEDEEvolved(uint256 newLevel, string newAspect, uint256 totalEvolutionPoints);
    event AEDEAspectChanged(string oldAspect, string newAspect);
    event AEDEAnomalyEvent(string eventType, bytes eventData, uint256 timestamp);
    event AEDEMutationTriggered(string mutationType, uint256 timestamp);

    event SoulFragmentMinted(uint256 indexed fragmentId, address indexed owner, string initialTrait);
    event SoulFragmentTraitAttuned(uint256 indexed fragmentId, string oldTrait, string newTrait);
    event SoulFragmentMoodEvolved(uint256 indexed fragmentId, string oldMood, string newMood);
    event SoulFragmentBurned(uint256 indexed fragmentId, address indexed owner);
    event ContributionScoreUpdated(address indexed user, uint256 oldScore, uint256 newScore);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 governancePower);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event GovernancePowerDelegated(address indexed delegator, address indexed delegatee);
    event GovernancePowerRevoked(address indexed delegator);

    event KnowledgeContributed(address indexed contributor, uint256 amount, uint256 newTotalKnowledgeUnits);
    event EssenceHarvested(address indexed harvester, uint256 amountAddedToAEDE, uint256 timestamp);
    event InsightRewardClaimed(address indexed claimant, uint256 amount);
    event OracleAddressUpdated(address indexed oldOracle, address indexed newOracle);
    event OracleDataRetrieved(bytes data, uint256 timestamp);


    /**
     * @dev Constructor sets the deployer as the initial owner.
     */
    constructor() Ownable(msg.sender) {}

    // --- Modifiers ---

    modifier onlyDAOExecutor() {
        // This modifier should check if the caller is the contract itself or a specific executor role,
        // typically invoked after a successful proposal execution. For simplicity, we'll assume
        // a proposal execution function (executeProposal) will call the target contract.
        // Direct calls to sensitive AEDE functions are usually guarded by DAO voting.
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != externalOracleAddress) {
            revert AEDE_OracleUnauthorized();
        }
        _;
    }

    // --- AEDE Core State & Evolution ---

    /**
     * @dev Initializes the Autonomous Evolving Digital Entity.
     *      Callable only once by the contract deployer.
     * @param _initialAspect The initial dominant aspect of the AEDE (e.g., "Explorer").
     */
    function initializeAEDE(string memory _initialAspect) public onlyOwner {
        if (isAEDEInitialized) {
            revert AEDE_AlreadyInitialized();
        }
        isAEDEInitialized = true;
        currentAEDELevel = 1;
        currentAEDEAspect = _initialAspect;
        lastMutationTimestamp = block.timestamp; // Initialize cooldown
        emit AEDEInitialized(msg.sender, _initialAspect);
    }

    /**
     * @dev Updates the AEDE's dominant aspect.
     *      Typically called by the `executeProposal` function after a successful DAO vote.
     * @param _newAspect The new dominant aspect for the AEDE.
     */
    function updateAEDEAspect(string memory _newAspect) public onlyDAOExecutor {
        if (!isAEDEInitialized) {
            revert AEDE_NotInitialized();
        }
        string memory oldAspect = currentAEDEAspect;
        currentAEDEAspect = _newAspect;
        emit AEDEAspectChanged(oldAspect, _newAspect);
    }

    /**
     * @dev Triggers the AEDE's evolution to the next level if conditions are met.
     *      This function is designed to be called via a successful DAO proposal.
     * @param _evolutionPayload Arbitrary data that can define how the AEDE evolves (e.g., new traits, capabilities).
     */
    function triggerAEDEEvolution(bytes memory _evolutionPayload) public onlyDAOExecutor {
        if (!isAEDEInitialized) {
            revert AEDE_NotInitialized();
        }
        if (totalEvolutionPoints < currentAEDELevel * EVOLUTION_THRESHOLD_PER_LEVEL) {
            revert AEDE_NotEnoughEvolutionPoints();
        }

        currentAEDELevel++;
        // Optionally, reset evolution points or apply a decay. For simplicity, we keep accumulating.
        // totalEvolutionPoints = 0; // Or totalEvolutionPoints -= (currentAEDELevel -1) * EVOLUTION_THRESHOLD_PER_LEVEL;

        // Process _evolutionPayload to update other AEDE properties, e.g., default aspect, new capabilities
        // For demonstration, we just emit an event.
        emit AEDEEvolved(currentAEDELevel, currentAEDEAspect, totalEvolutionPoints);
    }

    /**
     * @dev Internal function (or callable by Oracle) to register and react to external anomaly events.
     *      These events can influence AEDE's state, mood, or trigger follow-up DAO proposals.
     * @param _eventType A string describing the type of anomaly (e.g., "ResourceScarcity", "NewDiscovery").
     * @param _eventData Arbitrary data related to the event, to be interpreted by off-chain systems or future contract logic.
     */
    function triggerAEDEAnomalyEvent(string memory _eventType, bytes memory _eventData) public onlyOracle {
        // This function would typically lead to:
        // 1. A change in the AEDE's 'mood' or 'internal state'.
        // 2. Potentially trigger a new DAO proposal to respond to the event.
        // 3. Influence future mutation outcomes.
        emit AEDEAnomalyEvent(_eventType, _eventData, block.timestamp);
    }

    /**
     * @dev Initiates a major mutation protocol for the AEDE.
     *      Requires a successful DAO proposal and adherence to a cooldown period.
     *      A mutation can fundamentally alter the AEDE's capabilities or purpose.
     * @param _mutationType A string describing the nature of the mutation.
     */
    function initiateMutationProtocol(string memory _mutationType) public onlyDAOExecutor {
        if (!isAEDEInitialized) {
            revert AEDE_NotInitialized();
        }
        if (block.timestamp < lastMutationTimestamp + MUTATION_COOLDOWN) {
            revert AEDE_MutationCooldownActive();
        }
        lastMutationTimestamp = block.timestamp;
        // Logic for applying the mutation (e.g., changing parameters, enabling new features)
        emit AEDEMutationTriggered(_mutationType, block.timestamp);
    }

    /**
     * @dev Returns the current overarching state of the AEDE.
     * @return _currentAEDELevel Current evolutionary level.
     * @return _currentAEDEAspect Dominant aspect (e.g., "Explorer").
     * @return _totalEvolutionPoints Accumulated evolution points.
     * @return _totalKnowledgeUnits Accumulated knowledge units.
     * @return _lastMutationTimestamp Timestamp of the last mutation.
     */
    function getCurrentAEDEState()
        public
        view
        returns (uint256 _currentAEDELevel, string memory _currentAEDEAspect, uint256 _totalEvolutionPoints, uint256 _totalKnowledgeUnits, uint256 _lastMutationTimestamp)
    {
        return (
            currentAEDELevel,
            currentAEDEAspect,
            totalEvolutionPoints,
            totalKnowledgeUnits,
            lastMutationTimestamp
        );
    }

    // --- Soul Fragment (Dynamic Soulbound NFT) Management ---

    /**
     * @dev Mints a new, non-transferable (soulbound) Soul Fragment for a specific recipient.
     *      Each fragment represents a unique connection to the AEDE.
     * @param _recipient The address to receive the new Soul Fragment.
     * @param _initialTrait The initial trait assigned to this fragment.
     */
    function mintSoulFragment(address _recipient, string memory _initialTrait) public onlyOwner {
        _soulFragmentIds.increment();
        uint256 newId = _soulFragmentIds.current();

        AEDESoulFragment storage newFragment = soulFragments[newId];
        newFragment.id = newId;
        newFragment.owner = _recipient;
        newFragment.mintedTimestamp = block.timestamp;
        newFragment.contributionScore = 1; // Base score
        newFragment.trait = _initialTrait;
        newFragment.currentMood = "Neutral"; // Initial mood
        newFragment.lastEssenceHarvest = 0; // Can harvest immediately

        _ownerSoulFragmentIds[_recipient].add(newId);
        userTotalContributionScore[_recipient] += newFragment.contributionScore;
        _updateGovernancePower(_recipient);

        emit SoulFragmentMinted(newId, _recipient, _initialTrait);
    }

    /**
     * @dev Allows a Soul Fragment owner to attune their fragment's primary trait.
     *      This action costs Knowledge Units and can influence the AEDE's collective aspect.
     * @param _fragmentId The ID of the Soul Fragment to attune.
     * @param _newTrait The new trait to set for the fragment.
     */
    function attuneSoulFragmentTrait(uint256 _fragmentId, string memory _newTrait) public {
        AEDESoulFragment storage fragment = soulFragments[_fragmentId];
        if (fragment.owner != msg.sender) {
            revert AEDE_InvalidSoulFragmentOwner();
        }
        if (fragment.id == 0) { // Check if fragment exists
            revert AEDE_SoulFragmentNotFound();
        }

        if (userTotalContributionScore[msg.sender] < ATTUNE_TRAIT_COST_KU) {
            revert AEDE_InsufficientKnowledgeUnits();
        }

        userTotalContributionScore[msg.sender] -= ATTUNE_TRAIT_COST_KU; // Deduct from personal KU
        totalKnowledgeUnits += ATTUNE_TRAIT_COST_KU; // Contribute to AEDE pool

        string memory oldTrait = fragment.trait;
        fragment.trait = _newTrait;
        emit SoulFragmentTraitAttuned(_fragmentId, oldTrait, _newTrait);
    }

    /**
     * @dev Updates a fragment's 'mood' based on AEDE state or owner's recent contributions.
     *      This could be triggered by external events, AEDE evolution, or a user action (e.g. contributing a lot).
     * @param _fragmentId The ID of the Soul Fragment to update.
     * @param _newMood The new mood to set (e.g., "Inspired", "Anxious", "Determined").
     */
    function evolveSoulFragmentMood(uint256 _fragmentId, string memory _newMood) public {
        AEDESoulFragment storage fragment = soulFragments[_fragmentId];
        if (fragment.owner != msg.sender) {
            revert AEDE_InvalidSoulFragmentOwner();
        }
        if (fragment.id == 0) {
            revert AEDE_SoulFragmentNotFound();
        }

        string memory oldMood = fragment.currentMood;
        fragment.currentMood = _newMood;
        emit SoulFragmentMoodEvolved(_fragmentId, oldMood, _newMood);
    }

    /**
     * @dev Retrieves all details for a specific Soul Fragment.
     * @param _fragmentId The ID of the Soul Fragment.
     * @return _owner The owner of the fragment.
     * @return _mintedTimestamp When the fragment was minted.
     * @return _contributionScore The fragment's individual contribution score.
     * @return _trait The fragment's current trait.
     * @return _mood The fragment's current mood.
     */
    function getSoulFragmentDetails(uint256 _fragmentId)
        public
        view
        returns (address _owner, uint256 _mintedTimestamp, uint256 _contributionScore, string memory _trait, string memory _mood)
    {
        AEDESoulFragment storage fragment = soulFragments[_fragmentId];
        if (fragment.id == 0) {
            revert AEDE_SoulFragmentNotFound();
        }
        return (fragment.owner, fragment.mintedTimestamp, fragment.contributionScore, fragment.trait, fragment.currentMood);
    }

    /**
     * @dev Increases a participant's contribution score. This can be called internally
     *      (e.g., after successful proposal participation) or via a specific rewarded action.
     *      Increases both individual fragment score and aggregate user score.
     * @param _contributor The address of the contributor.
     * @param _scoreIncrease The amount to increase the score by.
     */
    function updateContributionScore(address _contributor, uint256 _scoreIncrease) public onlyDAOExecutor {
        // This function is called internally by other mechanisms (e.g. successful proposal execution)
        // or by a DAO proposal itself for rewarding.
        uint256 oldScore = userTotalContributionScore[_contributor];
        userTotalContributionScore[_contributor] += _scoreIncrease;
        _updateGovernancePower(_contributor);
        emit ContributionScoreUpdated(_contributor, oldScore, userTotalContributionScore[_contributor]);

        // Optionally, distribute score increase among fragments if desired.
        // For simplicity, we just update the total contribution score for the user.
    }

    /**
     * @dev Allows an owner to voluntarily burn their Soul Fragment.
     *      This severs their unique connection to the AEDE.
     * @param _fragmentId The ID of the Soul Fragment to burn.
     */
    function burnSoulFragment(uint256 _fragmentId) public {
        AEDESoulFragment storage fragment = soulFragments[_fragmentId];
        if (fragment.owner != msg.sender) {
            revert AEDE_InvalidSoulFragmentOwner();
        }
        if (fragment.id == 0) {
            revert AEDE_SoulFragmentNotFound();
        }

        address ownerToUpdate = fragment.owner;
        uint256 scoreToDeduct = fragment.contributionScore;

        _ownerSoulFragmentIds[ownerToUpdate].remove(_fragmentId);
        delete soulFragments[_fragmentId]; // Effectively 'burns' the fragment

        userTotalContributionScore[ownerToUpdate] -= scoreToDeduct;
        _updateGovernancePower(ownerToUpdate); // Recalculate governance power

        emit SoulFragmentBurned(_fragmentId, ownerToUpdate);
    }

    // --- Governance (DAO) Module ---

    /**
     * @dev Submits a new proposal for the AEDE's direction or actions.
     *      Requires a minimum governance power from the proposer.
     * @param _description A brief description of the proposal.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _callData The encoded function call (selector + arguments) for the target contract.
     * @param _executionDelay The delay in seconds after voting ends before the proposal can be executed.
     */
    function submitProposal(string memory _description, address _target, bytes memory _callData, uint256 _executionDelay) public {
        if (governancePower[msg.sender] < MIN_GOVERNANCE_POWER_FOR_PROPOSAL) {
            revert AEDE_InsufficientGovernancePower();
        }

        _proposalIds.increment();
        uint256 newId = _proposalIds.current();

        Proposal storage newProposal = proposals[newId];
        newProposal.id = newId;
        newProposal.description = _description;
        newProposal.target = _target;
        newProposal.callData = _callData;
        newProposal.submissionTimestamp = block.timestamp;
        newProposal.votingDeadline = block.timestamp + PROPOSAL_VOTING_PERIOD;
        newProposal.executionDelayEnd = newProposal.votingDeadline + _executionDelay;
        newProposal.executed = false;

        emit ProposalSubmitted(newId, msg.sender, _description);
    }

    /**
     * @dev Casts a vote (yes/no) on an active proposal, weighted by the participant's governance power.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes' vote, false for 'no' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AEDE_ProposalNotFound();
        }
        if (block.timestamp > proposal.votingDeadline) {
            revert AEDE_VotingPeriodNotEnded();
        }
        if (proposal.voters.contains(msg.sender)) {
            revert AEDE_AlreadyVoted();
        }

        address voter = _getEffectiveVoter(msg.sender);
        uint256 power = governancePower[voter];
        if (power == 0) {
            revert AEDE_InsufficientGovernancePower(); // No power to vote
        }

        if (_support) {
            proposal.yesVotes += power;
        } else {
            proposal.noVotes += power;
        }
        proposal.totalVotesCastPower += power;
        proposal.voters.add(msg.sender); // Record the actual address that called this, not the delegated one

        emit VoteCast(_proposalId, msg.sender, _support, power);
    }

    /**
     * @dev Executes a proposal if it has passed the voting threshold and the execution delay has passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AEDE_ProposalNotFound();
        }
        if (proposal.executed) {
            revert AEDE_ProposalAlreadyExecuted();
        }
        if (block.timestamp <= proposal.votingDeadline) {
            revert AEDE_VotingPeriodNotEnded();
        }
        if (block.timestamp <= proposal.executionDelayEnd) {
            revert AEDE_ExecutionDelayNotPassed();
        }

        uint256 totalYesNoVotes = proposal.yesVotes + proposal.noVotes;
        bool proposalPassed = (totalYesNoVotes > 0 && (proposal.yesVotes * 100 / totalYesNoVotes) >= PROPOSAL_PASS_THRESHOLD_PERCENT);

        if (!proposalPassed) {
            proposal.executed = true; // Mark as executed but failed
            emit ProposalExecuted(_proposalId, false);
            revert AEDE_ProposalFailed();
        }

        // Execute the proposal's callData on the target contract
        (bool success, ) = proposal.target.call(proposal.callData);
        if (success) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, true);
        } else {
            // Revert if the execution fails, but mark as executed to prevent retries
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, false);
            revert AEDE_ProposalFailed();
        }
    }

    /**
     * @dev Delegates voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateGovernancePower(address _delegatee) public {
        delegatedPower[msg.sender] = _delegatee;
        _updateGovernancePower(msg.sender); // Recalculate power for delegator and delegatee
        _updateGovernancePower(_delegatee);
        emit GovernancePowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any active governance delegation.
     */
    function revokeGovernancePower() public {
        address oldDelegatee = delegatedPower[msg.sender];
        delete delegatedPower[msg.sender];
        _updateGovernancePower(msg.sender);
        if (oldDelegatee != address(0)) {
            _updateGovernancePower(oldDelegatee);
        }
        emit GovernancePowerRevoked(msg.sender);
    }

    /**
     * @dev Internal helper to determine the effective voter address (delegator or delegatee).
     * @param _voter The original caller's address.
     * @return The address whose governance power should be used.
     */
    function _getEffectiveVoter(address _voter) internal view returns (address) {
        if (delegatedPower[_voter] != address(0)) {
            return delegatedPower[_voter];
        }
        return _voter;
    }

    /**
     * @dev Internal function to update a user's governance power.
     *      Power is derived from `userTotalContributionScore` and the number of Soul Fragments.
     * @param _user The address whose governance power needs to be updated.
     */
    function _updateGovernancePower(address _user) internal {
        // Simple formula: base power from contribution + bonus per fragment.
        uint256 currentFragments = _ownerSoulFragmentIds[_user].length();
        uint256 newPower = userTotalContributionScore[_user] + (currentFragments * 5); // 5 power per fragment
        governancePower[_user] = newPower;
    }

    /**
     * @dev Returns the current state and details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return _description The proposal's description.
     * @return _target The target contract address.
     * @return _votingDeadline The timestamp when voting ends.
     * @return _yesVotes Total yes votes.
     * @return _noVotes Total no votes.
     * @return _totalVotesCastPower Total power cast.
     * @return _executed Whether the proposal has been executed.
     */
    function getProposalState(uint256 _proposalId)
        public
        view
        returns (
            string memory _description,
            address _target,
            uint256 _votingDeadline,
            uint256 _yesVotes,
            uint256 _noVotes,
            uint256 _totalVotesCastPower,
            bool _executed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) {
            revert AEDE_ProposalNotFound();
        }
        return (
            proposal.description,
            proposal.target,
            proposal.votingDeadline,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.totalVotesCastPower,
            proposal.executed
        );
    }

    // --- Resource & Gamification ---

    /**
     * @dev Allows users to contribute "Knowledge Units" to the AEDE's collective pool.
     *      This increases the AEDE's `totalKnowledgeUnits` and potentially the user's `contributionScore`.
     * @param _amount The amount of Knowledge Units to contribute.
     */
    function contributeKnowledge(uint256 _amount) public payable {
        // For simplicity, we assume Knowledge Units are abstract and represented by ETH/MATIC/etc.
        // In a real scenario, this could interact with an ERC20 token for Knowledge Units.
        // Here, `_amount` can be conceptual, or a conversion from msg.value.
        // Let's assume msg.value is the direct contribution amount.
        if (msg.value == 0) {
            revert AEDE_InsufficientKnowledgeUnits();
        }

        totalKnowledgeUnits += msg.value; // Add contributed value to AEDE's pool
        userTotalContributionScore[msg.sender] += msg.value / 10**12; // Small score for contribution
        _updateGovernancePower(msg.sender); // Update power based on new score

        emit KnowledgeContributed(msg.sender, msg.value, totalKnowledgeUnits);
    }

    /**
     * @dev A time-gated function allowing users to "harvest" Evolution Essence.
     *      Adds to the AEDE's total Evolution Points. Users must own at least one Soul Fragment.
     */
    function harvestEvolutionEssence() public {
        if (_ownerSoulFragmentIds[msg.sender].length() == 0) {
            revert AEDE_SoulFragmentNotFound(); // User must own a fragment
        }

        // To make it tied to fragments, we can make it per fragment.
        // For simplicity, let's allow harvesting once per user per HARVEST_COOLDOWN.
        // Or, implement a loop over fragments for more advanced logic.
        // For this example, we'll pick the first fragment for cooldown check.
        uint256 firstFragmentId = _ownerSoulFragmentIds[msg.sender].at(0);
        AEDESoulFragment storage fragment = soulFragments[firstFragmentId];

        if (block.timestamp < fragment.lastEssenceHarvest + HARVEST_COOLDOWN) {
            revert AEDE_HarvestCooldownActive();
        }

        uint256 essenceAmount = currentAEDELevel * 10; // More essence at higher AEDE levels
        totalEvolutionPoints += essenceAmount;
        fragment.lastEssenceHarvest = block.timestamp;
        userTotalContributionScore[msg.sender] += essenceAmount / 2; // Some personal score
        _updateGovernancePower(msg.sender);

        emit EssenceHarvested(msg.sender, essenceAmount, block.timestamp);
    }

    /**
     * @dev Allows users to claim a reward (e.g., more `KnowledgeUnits` or a temporary boost)
     *      based on their contribution score and the AEDE's current level.
     *      Requires a significant contribution score to claim.
     */
    function claimAEDEInsightReward() public {
        uint256 minScoreForReward = currentAEDELevel * 50; // Higher levels require more score
        if (userTotalContributionScore[msg.sender] < minScoreForReward) {
            revert AEDE_InsufficientKnowledgeUnits(); // Using this error as a generic "not enough score/resources"
        }

        // Calculate reward based on score and level
        uint256 rewardAmount = (userTotalContributionScore[msg.sender] / 10) + (currentAEDELevel * 5); // Example reward calc
        // This reward could be actual ETH, ERC20 tokens, or more 'Knowledge Units' credited internally.
        // For simplicity, we credit more internal Knowledge Units.
        userTotalContributionScore[msg.sender] += rewardAmount;
        _updateGovernancePower(msg.sender);

        emit InsightRewardClaimed(msg.sender, rewardAmount);
    }

    // --- External Oracle Integration ---

    /**
     * @dev Sets the address of the external oracle that can feed data to the AEDE.
     *      Only callable by the contract owner.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        address oldOracle = externalOracleAddress;
        externalOracleAddress = _newOracle;
        emit OracleAddressUpdated(oldOracle, _newOracle);
    }

    /**
     * @dev Callable only by the designated oracle, pushes external data into the contract.
     *      This data can be used to trigger internal events, influence parameters, or prompt DAO actions.
     * @param _data Raw bytes containing the oracle data payload.
     */
    function retrieveOracleData(bytes memory _data) public onlyOracle {
        // This function would contain logic to parse _data and use it.
        // For example, if _data contains "environmental_stress_level", it might
        // trigger an AEDEAnomalyEvent internally.
        // This makes the contract adaptive to real-world data without direct off-chain computation.
        // Example: If _data implies a high stress level, call triggerAEDEAnomalyEvent("EnvironmentalStress", _data);
        emit OracleDataRetrieved(_data, block.timestamp);
    }
}
```