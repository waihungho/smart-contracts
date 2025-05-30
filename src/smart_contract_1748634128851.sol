Okay, here is a Solidity smart contract implementing a conceptual "Epochal Innovations Hub".

This contract introduces concepts like:
*   **Epoch-based progression:** Time is divided into distinct epochs, triggering state changes.
*   **Dynamic Resources:** Multiple types of resources required for operations, with supply changing per epoch and subject to decay.
*   **Reputation System:** Researchers earn reputation by successfully completing proposals, which decays over time.
*   **Decentralized Proposals:** A system for submitting, voting on, and developing research proposals using resources and time.
*   **Dynamic Configuration:** Admin functions to adjust parameters like decay rates, epoch duration, resource additions, etc.
*   **On-chain State Management:** Complex state transitions based on time, resources, reputation, and user interaction.

It avoids replicating standard ERC-20/721 logic, basic DAO voting patterns, or simple staking/lending found in common open-source examples.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
Outline and Function Summary:

Epochal Innovations Hub - A Decentralized Research & Development Platform

Purpose:
To manage a decentralized platform where "Researchers" can propose, fund (with abstract resources), and develop "Innovations" across distinct time periods called "Epochs". The system incorporates dynamic resource management and a decaying reputation system for participants.

Core Concepts:
1.  Epochs: Time is segmented into epochs. Key events (resource generation, decay) happen at the start of each epoch.
2.  Resources: Abstract resources (Data, Compute, Energy, Knowledge) are required for developing proposals. Resource supply changes per epoch and decays.
3.  Reputation: Researchers earn reputation by completing proposals. Reputation decays over time (per epoch). Reputation might influence future interactions (though not explicitly implemented as a gate in this version, it's a trackable metric).
4.  Proposals: Ideas submitted by researchers, requiring specific resources and time to develop. They go through states: Proposed, Voting, Developing, Completed, Rejected, Cancelled.

State Variables:
- Current epoch number and timestamp details.
- Manager address (for administrative tasks).
- Mapping for researcher reputation and last update epoch.
- Mappings for resource supply, decay rates, and epoch additions.
- Proposal counter and mapping to Proposal structs.
- Configuration parameters (epoch duration, min voting/development time, reputation reward/decay rates).

Enums:
- ProposalStatus: Describes the current state of a proposal.
- ResourceType: Lists the available abstract resource types.

Structs:
- Proposal: Holds all details about a submitted innovation proposal.

Events:
- Signals key state changes like epoch transitions, proposal updates, resource changes, reputation updates.

Errors:
- Custom errors for specific failure conditions.

Modifiers:
- onlyManager: Restricts function access to the contract manager.

Functions (20+):

I.  Epoch Management (3 functions)
    1.  constructor(): Initializes the contract, sets the first epoch, manager, and initial configs.
    2.  startNewEpoch(): Advances the epoch if sufficient time has passed. Applies resource decay, adds new epoch resources, and triggers proposal state checks. (Advanced: Time-based state transition, resource dynamics)
    3.  getEpochDetails(): Retrieves current epoch number and next epoch start time.

II. Proposal Management (9 functions)
    4.  submitProposal(): Allows a researcher to submit a new innovation proposal with required resources and development duration.
    5.  voteOnProposal(): Allows a researcher to vote (support/against) on a proposal in the 'Voting' state.
    6.  startProposalDevelopment(): Transitions a 'Proposed' or 'Voting' proposal to 'Developing' state if voting duration passed and required resources are available. Consumes resources.
    7.  completeProposalDevelopment(): Transitions a 'Developing' proposal to 'Completed' state if development duration passed. Awards reputation to the submitter.
    8.  cancelProposal(): Allows the submitter or manager to cancel a proposal if not yet completed. Refunds resources if in 'Developing'.
    9.  rejectProposal(): Allows the manager to reject a proposal in any state before 'Completed'. Refunds resources if in 'Developing'.
    10. getProposalDetails(): Retrieves core details of a specific proposal (submitter, title, status, timings).
    11. getProposalVoteCounts(): Retrieves vote counts for a proposal.
    12. getProposalResourceRequirements(): Retrieves the required resources for a specific proposal.

III. Resource Management (5 functions)
    13. addResources(): Allows the manager to add resources to the global supply. (Advanced: Supply management)
    14. getResourceSupply(): Retrieves the current supply of a specific resource type.
    15. refundUnusedResources(): Helper function (also callable externally if needed) to refund resources from cancelled/rejected development.
    16. updateResourceDecayRate(): Allows the manager to set the decay rate for a resource type. (Advanced: Dynamic config)
    17. updateEpochResourcesAdded(): Allows the manager to set the amount of a resource added each epoch. (Advanced: Dynamic config)

IV. Reputation Management (3 functions)
    18. getResearcherReputation(): Retrieves a researcher's current calculated reputation (applying decay). (Advanced: Dynamic calculation with decay)
    19. slashReputation(): Allows the manager to reduce a researcher's reputation (e.g., for malicious behavior). (Advanced: On-chain punishment mechanism)
    20. updateReputationDecayRate(): Allows the manager to set the global reputation decay rate. (Advanced: Dynamic config)

V. Configuration & Admin (at least 5 more)
    21. setTreasuryManager(): Transfers the manager role.
    22. setEpochDuration(): Sets the duration of an epoch in seconds.
    23. setMinVotingDuration(): Sets the minimum duration a proposal must be in the 'Voting' state.
    24. setMinDevelopmentDuration(): Sets the minimum duration a proposal must be in the 'Developing' state.
    25. setReputationRewardRate(): Sets the base amount of reputation awarded for completing a proposal.
    26. getProposalCount(): Retrieves the total number of proposals ever submitted.
    27. hasVotedOnProposal(): Checks if a specific researcher has voted on a proposal.
    28. getResourceDecayRate(): Retrieves the decay rate for a specific resource type.
    29. getEpochResourcesAdded(): Retrieves the amount of a resource added each epoch.
    30. getReputationDecayRate(): Retrieves the global reputation decay rate.

Note: This contract provides the core framework. A production system would require more robust access control (e.g., multi-sig or DAO for manager roles), potentially token integration for resource value or proposal staking, off-chain indexing for complex queries, and careful consideration of gas costs for resource/reputation decay mechanisms with large numbers of users/resource types. Dynamic reputation decay calculation on read (`getResearcherReputation`) is gas-efficient as it doesn't iterate, but might show slight variations based on *when* the function is called relative to epoch boundaries if not carefully managed (using epochs for decay reference simplifies this).
*/

// --- Custom Errors ---
error NotManager();
error EpochNotYetEnded();
error EpochStillInProgress();
error ProposalNotFound(uint256 proposalId);
error InvalidProposalStatus(uint256 proposalId, ProposalStatus requiredStatus);
error AlreadyVoted(uint256 proposalId, address researcher);
error InsufficientResources(ResourceType resourceType, uint256 required, uint256 available);
error DevelopmentNotYetCompleted(uint256 proposalId, uint256 timeRemaining);
error NoOutputLinkProvided();
error OnlySubmitterOrManager();
error InvalidResourceAmount();
error InvalidDecayRate();
error InvalidRewardRate();
error InvalidDuration();


// --- Events ---
event EpochStarted(uint256 indexed epoch, uint256 startTime, uint256 endTime);
event ProposalSubmitted(uint256 indexed proposalId, address indexed submitter, string title, uint256 submissionEpoch);
event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
event DevelopmentStarted(uint256 indexed proposalId, uint256 startEpoch, uint256 startTime);
event DevelopmentCompleted(uint256 indexed proposalId, address indexed submitter, string outputLink, uint256 completionEpoch);
event ProposalCancelled(uint256 indexed proposalId, address indexed cancelledBy);
event ProposalRejected(uint256 indexed proposalId, address indexed rejectedBy);
event ResourcesAdded(ResourceType indexed resourceType, uint256 amount, address indexed addedBy);
event ResourcesRefunded(uint256 indexed proposalId, ResourceType indexed resourceType, uint256 amount);
event ReputationUpdated(address indexed researcher, uint256 newReputation, uint256 epoch);
event ReputationSlashed(address indexed researcher, uint256 amount, address indexed slashedBy, uint256 epoch);
event ManagerTransferred(address indexed oldManager, address indexed newManager);
event ConfigurationUpdated(string paramName, uint256 oldValue, uint256 newValue); // Generic config update event


// --- Enums ---
enum ProposalStatus {
    Proposed,      // Newly submitted
    Voting,        // Open for voting (implicit state after submission, duration checked on state transition)
    Developing,    // Resources allocated, development in progress
    Completed,     // Development finished, output provided
    Rejected,      // Rejected by manager or failed criteria
    Cancelled      // Cancelled by submitter or manager
}

enum ResourceType {
    Data,
    Compute,
    Energy,
    Knowledge
}


// --- Structs ---
struct Proposal {
    uint256 id;
    address submitter;
    string title;
    string description; // Optional longer description
    mapping(ResourceType => uint256) requiredResources;
    ProposalStatus status;
    uint256 submissionEpoch;
    uint256 submissionTime;
    uint256 developmentStartEpoch; // Epoch when development started
    uint256 developmentStartTime; // Timestamp when development started
    uint256 developmentDuration; // Minimum time required for development after starting
    uint256 votesFor;
    uint256 votesAgainst;
    mapping(address => bool) voters; // To track who has voted
    string outputLink; // Link to results (e.g., IPFS hash)
}


// --- State Variables ---
uint256 public currentEpoch;
uint256 public epochDuration; // Duration of an epoch in seconds
uint256 public nextEpochStartTime;

address private manager;

mapping(address => uint256) public researcherReputation;
mapping(address => uint256) private researcherLastReputationUpdateEpoch; // To track for decay

mapping(ResourceType => uint256) public resourceSupply;
mapping(ResourceType => uint256) public resourceDecayRate; // Percentage out of 10000 per epoch
mapping(ResourceType => uint256) public epochResourcesAdded; // Amount of resource added each epoch

uint256 public proposalCounter;
mapping(uint256 => Proposal) public proposals;

uint256 public minVotingDuration; // Minimum time a proposal is implicitly in 'Voting' state before development can start
uint256 public minDevelopmentDuration; // Minimum time a proposal must be in 'Developing' state
uint256 public reputationRewardRate; // Base reputation points awarded for completing a proposal (e.g., out of 100)
uint256 public reputationDecayRate; // Global reputation decay percentage out of 10000 per epoch


// --- Modifiers ---
modifier onlyManager() {
    if (msg.sender != manager) revert NotManager();
    _;
}


// --- Constructor ---
constructor(uint256 _epochDuration, uint256 _minVotingDuration, uint256 _minDevelopmentDuration, uint256 _reputationRewardRate, uint256 _reputationDecayRate) {
    manager = msg.sender;
    currentEpoch = 1;
    epochDuration = _epochDuration > 0 ? _epochDuration : 1 days; // Default to 1 day if 0
    nextEpochStartTime = block.timestamp + epochDuration;

    minVotingDuration = _minVotingDuration;
    minDevelopmentDuration = _minDevelopmentDuration;
    reputationRewardRate = _reputationRewardRate; // e.g., 100 for 100 points
    reputationDecayRate = _reputationDecayRate; // e.g., 100 for 1% decay per epoch (100/10000)

    // Initialize default resource decay rates (e.g., 5% decay per epoch for all)
    resourceDecayRate[ResourceType.Data] = 500; // 5%
    resourceDecayRate[ResourceType.Compute] = 500; // 5%
    resourceDecayRate[ResourceType.Energy] = 500; // 5%
    resourceDecayRate[ResourceType.Knowledge] = 500; // 5%

    // Initialize default resources added per epoch
    epochResourcesAdded[ResourceType.Data] = 1000;
    epochResourcesAdded[ResourceType.Compute] = 500;
    epochResourcesAdded[ResourceType.Energy] = 200;
    epochResourcesAdded[ResourceType.Knowledge] = 100;

    emit EpochStarted(currentEpoch, block.timestamp, nextEpochStartTime);
}


// --- I. Epoch Management ---

/// @notice Advances the epoch if the current epoch duration has passed.
/// Applies resource decay and adds new epoch resources.
/// Can potentially trigger proposal state transitions based on time.
function startNewEpoch() external {
    if (block.timestamp < nextEpochStartTime) revert EpochNotYetEnded();

    currentEpoch++;
    nextEpochStartTime = block.timestamp + epochDuration;

    _applyResourceDecay();
    _addEpochResources();
    // Note: Reputation decay is applied when reputation is read or updated.
    // Proposal state transitions based on time are checked when actions are taken (e.g., start development, complete development)
    // rather than iterating through all proposals here to save gas.

    emit EpochStarted(currentEpoch, block.timestamp, nextEpochStartTime);
}

/// @notice Gets the current epoch number and the timestamp when the next epoch starts.
/// @return epoch The current epoch number.
/// @return nextStart The timestamp when the next epoch begins.
function getEpochDetails() external view returns (uint256 epoch, uint256 nextStart) {
    return (currentEpoch, nextEpochStartTime);
}


// --- II. Proposal Management ---

/// @notice Submits a new innovation proposal.
/// @param _title The title of the proposal.
/// @param _description A brief description of the proposal.
/// @param _requiredResources An array of resource types required.
/// @param _requiredAmounts An array of amounts for the corresponding resource types.
/// @param _developmentDuration The minimum time required for development after starting (in seconds).
function submitProposal(
    string calldata _title,
    string calldata _description,
    ResourceType[] calldata _requiredResources,
    uint256[] calldata _requiredAmounts,
    uint256 _developmentDuration
) external {
    if (_requiredResources.length != _requiredAmounts.length) revert InvalidResourceAmount();
    if (_developmentDuration < minDevelopmentDuration) revert InvalidDuration();

    uint256 proposalId = proposalCounter++;
    Proposal storage proposal = proposals[proposalId];

    proposal.id = proposalId;
    proposal.submitter = msg.sender;
    proposal.title = _title;
    proposal.description = _description;
    proposal.status = ProposalStatus.Proposed; // Implicitly in Voting phase until development starts
    proposal.submissionEpoch = currentEpoch;
    proposal.submissionTime = block.timestamp;
    proposal.developmentDuration = _developmentDuration;

    for (uint i = 0; i < _requiredResources.length; i++) {
        proposal.requiredResources[_requiredResources[i]] = _requiredAmounts[i];
    }

    emit ProposalSubmitted(proposalId, msg.sender, _title, currentEpoch);
}

/// @notice Allows a researcher to vote on a proposal that is in the 'Proposed' or 'Voting' state.
/// Voting is implicitly allowed while the proposal status is 'Proposed'.
/// @param _proposalId The ID of the proposal to vote on.
/// @param _support True for a vote in support, false for against.
function voteOnProposal(uint256 _proposalId, bool _support) external {
    Proposal storage proposal = proposals[_proposalId];
    if (proposal.status == ProposalStatus.Completed ||
        proposal.status == ProposalStatus.Rejected ||
        proposal.status == ProposalStatus.Cancelled ||
        proposal.submissionTime + minVotingDuration < block.timestamp // Voting period over
        ) {
            revert InvalidProposalStatus(_proposalId, ProposalStatus.Voting); // Cannot vote on completed/rejected/cancelled or after voting period
        }

    if (proposal.voters[msg.sender]) revert AlreadyVoted(_proposalId, msg.sender);

    proposal.voters[msg.sender] = true;
    if (_support) {
        proposal.votesFor++;
    } else {
        proposal.votesAgainst++;
    }

    emit ProposalVoted(_proposalId, msg.sender, _support);
}

/// @notice Attempts to start development for a proposal.
/// Requires the proposal to be in 'Proposed' state and the minimum voting duration to have passed.
/// Also requires sufficient resources to be available.
/// @param _proposalId The ID of the proposal to start development for.
function startProposalDevelopment(uint256 _proposalId) external {
    Proposal storage proposal = proposals[_proposalId];
    if (proposal.status != ProposalStatus.Proposed) revert InvalidProposalStatus(_proposalId, ProposalStatus.Proposed);
    if (proposal.submissionTime + minVotingDuration > block.timestamp) revert InvalidDuration(); // Voting period not over

    // Check and consume resources
    ResourceType[] memory resourceTypes = new ResourceType[](4); // Data, Compute, Energy, Knowledge
    resourceTypes[0] = ResourceType.Data;
    resourceTypes[1] = ResourceType.Compute;
    resourceTypes[2] = ResourceType.Energy;
    resourceTypes[3] = ResourceType.Knowledge;

    for (uint i = 0; i < resourceTypes.length; i++) {
        ResourceType rType = resourceTypes[i];
        uint256 required = proposal.requiredResources[rType];
        if (required > 0) {
            if (resourceSupply[rType] < required) {
                // Revert and list the insufficient resource
                revert InsufficientResources(rType, required, resourceSupply[rType]);
            }
        }
    }

    // Resources are available, consume them
    for (uint i = 0; i < resourceTypes.length; i++) {
        ResourceType rType = resourceTypes[i];
        uint256 required = proposal.requiredResources[rType];
        if (required > 0) {
            resourceSupply[rType] -= required;
        }
    }

    proposal.status = ProposalStatus.Developing;
    proposal.developmentStartEpoch = currentEpoch;
    proposal.developmentStartTime = block.timestamp;

    emit DevelopmentStarted(_proposalId, currentEpoch, block.timestamp);
}

/// @notice Completes the development for a proposal.
/// Requires the proposal to be in 'Developing' state and the minimum development duration to have passed.
/// Awards reputation to the submitter.
/// @param _proposalId The ID of the proposal to complete.
/// @param _outputLink A link (e.g., IPFS hash) to the development output.
function completeProposalDevelopment(uint256 _proposalId, string calldata _outputLink) external {
    Proposal storage proposal = proposals[_proposalId];
    if (proposal.status != ProposalStatus.Developing) revert InvalidProposalStatus(_proposalId, ProposalStatus.Developing);
    if (proposal.developmentStartTime + proposal.developmentDuration > block.timestamp) {
        revert DevelopmentNotYetCompleted(_proposalId, (proposal.developmentStartTime + proposal.developmentDuration) - block.timestamp);
    }
    if (bytes(_outputLink).length == 0) revert NoOutputLinkProvided();

    proposal.status = ProposalStatus.Completed;
    proposal.outputLink = _outputLink;

    // Award reputation
    _updateResearcherReputation(proposal.submitter, reputationRewardRate); // Add the base reward rate

    emit DevelopmentCompleted(_proposalId, proposal.submitter, _outputLink, currentEpoch);
}

/// @notice Allows the submitter or manager to cancel a proposal.
/// Refunds resources if the proposal was in the 'Developing' state.
/// @param _proposalId The ID of the proposal to cancel.
function cancelProposal(uint256 _proposalId) external {
    Proposal storage proposal = proposals[_proposalId];
    if (proposal.status == ProposalStatus.Completed || proposal.status == ProposalStatus.Rejected || proposal.status == ProposalStatus.Cancelled) {
        revert InvalidProposalStatus(_proposalId, proposal.status); // Cannot cancel if already finalized
    }
    if (msg.sender != proposal.submitter && msg.sender != manager) revert OnlySubmitterOrManager();

    if (proposal.status == ProposalStatus.Developing) {
        _refundProposalResources(_proposalId);
    }

    proposal.status = ProposalStatus.Cancelled;

    emit ProposalCancelled(_proposalId, msg.sender);
}

/// @notice Allows the manager to reject a proposal.
/// Refunds resources if the proposal was in the 'Developing' state.
/// @param _proposalId The ID of the proposal to reject.
function rejectProposal(uint256 _proposalId) external onlyManager {
    Proposal storage proposal = proposals[_proposalId];
    if (proposal.status == ProposalStatus.Completed || proposal.status == ProposalStatus.Rejected || proposal.status == ProposalStatus.Cancelled) {
        revert InvalidProposalStatus(_proposalId, proposal.status); // Cannot reject if already finalized
    }

     if (proposal.status == ProposalStatus.Developing) {
        _refundProposalResources(_proposalId);
    }

    proposal.status = ProposalStatus.Rejected;

    emit ProposalRejected(_proposalId, msg.sender);
}

/// @notice Retrieves core details of a specific proposal.
/// @param _proposalId The ID of the proposal.
/// @return submitter The address of the submitter.
/// @return title The title of the proposal.
/// @return status The current status of the proposal.
/// @return submissionTime The timestamp the proposal was submitted.
/// @return developmentStartTime The timestamp development started (0 if not started).
/// @return developmentDuration The required development duration.
/// @return outputLink The output link if completed.
function getProposalDetails(uint256 _proposalId) external view returns (
    address submitter,
    string memory title,
    ProposalStatus status,
    uint256 submissionTime,
    uint256 developmentStartTime,
    uint256 developmentDuration,
    string memory outputLink
) {
    Proposal storage proposal = proposals[_proposalId];
    if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId); // Check if proposal exists

    return (
        proposal.submitter,
        proposal.title,
        proposal.status,
        proposal.submissionTime,
        proposal.developmentStartTime,
        proposal.developmentDuration,
        proposal.outputLink
    );
}

/// @notice Retrieves vote counts for a specific proposal.
/// @param _proposalId The ID of the proposal.
/// @return votesFor The number of votes in support.
/// @return votesAgainst The number of votes against.
function getProposalVoteCounts(uint256 _proposalId) external view returns (uint256 votesFor, uint256 votesAgainst) {
     Proposal storage proposal = proposals[_proposalId];
    if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);

    return (proposal.votesFor, proposal.votesAgainst);
}

/// @notice Retrieves the required resources for a specific proposal.
/// Note: Due to mapping limitations in return types, this requires specifying the resource type.
/// Consider off-chain indexing for a full list.
/// @param _proposalId The ID of the proposal.
/// @param _resourceType The type of resource to query.
/// @return amount The required amount of the specified resource type.
function getProposalResourceRequirement(uint256 _proposalId, ResourceType _resourceType) external view returns (uint256 amount) {
     Proposal storage proposal = proposals[_proposalId];
    if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);

    return proposal.requiredResources[_resourceType];
}


// --- III. Resource Management ---

/// @notice Allows the manager to add resources to the global supply.
/// @param _resourceType The type of resource to add.
/// @param _amount The amount of resource to add.
function addResources(ResourceType _resourceType, uint256 _amount) external onlyManager {
    if (_amount == 0) revert InvalidResourceAmount();
    resourceSupply[_resourceType] += _amount;
    emit ResourcesAdded(_resourceType, _amount, msg.sender);
}

/// @notice Retrieves the current global supply of a specific resource type.
/// @param _resourceType The type of resource to query.
/// @return supply The current supply of the resource type.
function getResourceSupply(ResourceType _resourceType) external view returns (uint256 supply) {
    return resourceSupply[_resourceType];
}

/// @notice Refunds resources consumed by a proposal if it's cancelled or rejected during development.
/// Internal helper function. Can be called externally by manager for safety/cleanup.
/// @param _proposalId The ID of the proposal.
function refundUnusedResources(uint256 _proposalId) public onlyManager { // Made public for manager trigger
     Proposal storage proposal = proposals[_proposalId];
     if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);
     // Only refund if it was developing and not completed/rejected/cancelled yet (or if manager forces refund)
     // Simplified: Assume this is only called during cancel/reject which check status
     // Add an explicit check if calling standalone is intended:
     // if (proposal.status != ProposalStatus.Developing) revert InvalidProposalStatus(_proposalId, ProposalStatus.Developing);


    ResourceType[] memory resourceTypes = new ResourceType[](4);
    resourceTypes[0] = ResourceType.Data;
    resourceTypes[1] = ResourceType.Compute;
    resourceTypes[2] = ResourceType.Energy;
    resourceTypes[3] = ResourceType.Knowledge;

    for (uint i = 0; i < resourceTypes.length; i++) {
        ResourceType rType = resourceTypes[i];
        uint256 required = proposal.requiredResources[rType];
        if (required > 0) {
             resourceSupply[rType] += required;
             emit ResourcesRefunded(_proposalId, rType, required);
        }
    }
}

/// @notice Allows the manager to update the decay rate for a specific resource type.
/// @param _resourceType The type of resource.
/// @param _rate The new decay rate percentage out of 10000 (e.g., 100 for 1%).
function updateResourceDecayRate(ResourceType _resourceType, uint256 _rate) external onlyManager {
    if (_rate > 10000) revert InvalidDecayRate(); // Rate > 100%

    uint256 oldRate = resourceDecayRate[_resourceType];
    resourceDecayRate[_resourceType] = _rate;

    // Emit a generic config update event or a specific one
    // emit ConfigurationUpdated("resourceDecayRate", uint256(_resourceType), _rate); // Need to map enum to string for better logging
    emit ConfigurationUpdated("resourceDecayRate", oldRate, _rate); // Simpler event value
}

/// @notice Allows the manager to update the amount of a resource added each epoch.
/// @param _resourceType The type of resource.
/// @param _amount The new amount to add each epoch.
function updateEpochResourcesAdded(ResourceType _resourceType, uint256 _amount) external onlyManager {
    uint256 oldAmount = epochResourcesAdded[_resourceType];
    epochResourcesAdded[_resourceType] = _amount;
    emit ConfigurationUpdated("epochResourcesAdded", oldAmount, _amount);
}


// --- IV. Reputation Management ---

/// @notice Calculates and returns a researcher's current reputation, applying epoch-based decay.
/// @param _researcher The address of the researcher.
/// @return reputation The researcher's current calculated reputation.
function getResearcherReputation(address _researcher) public view returns (uint256 reputation) {
    uint256 rawRep = researcherReputation[_researcher];
    if (rawRep == 0) return 0; // No reputation to decay

    uint256 lastUpdateEpoch = researcherLastReputationUpdateEpoch[_researcher];
    // If no specific update epoch is recorded, assume it was 0 or epoch 1 for initial state.
    // Or, if currentEpoch is the same as lastUpdateEpoch, no decay has occurred yet.
    uint256 epochsSinceLastUpdate = currentEpoch - lastUpdateEpoch;

    // Apply decay calculation (simplified - no floating point)
    // Decay rate is percentage out of 10000
    // newRep = oldRep * (1 - rate/10000)^epochs
    // This is computationally expensive for large 'epochsSinceLastUpdate'.
    // A common approximation or alternative is needed.
    // Let's use a simpler model for this example: decay reduces a fixed percentage *of the original reward* per epoch,
    // or a percentage *of the current value* per epoch.
    // Percentage of current value: This is tricky without precise math.
    // Alternative: Calculate decay in chunks or cap the number of epochs for calculation.
    // Simplest: If rate is X/10000, decay is (rawRep * X * epochs) / 10000. This is linear, not exponential.
    // Let's use the linear approximation for simplicity on-chain.
    // A more accurate exponential decay would require off-chain calculation or complex on-chain libs.

    if (epochsSinceLastUpdate > 0 && reputationDecayRate > 0) {
         uint256 totalDecayPercentage = epochsSinceLastUpdate * reputationDecayRate;
         if (totalDecayPercentage >= 10000) { // Decay rate reaches or exceeds 100% per epoch period
             return 0; // Reputation fully decayed
         }
        // Decay amount = rawRep * totalDecayPercentage / 10000
        uint256 decayAmount = (rawRep * totalDecayPercentage) / 10000;
        // Prevent underflow if decay is huge but rawRep is small
        return rawRep > decayAmount ? rawRep - decayAmount : 0;

    } else {
        // No decay if epochsSinceLastUpdate is 0 or decay rate is 0
        return rawRep;
    }
}

/// @notice Slashes (reduces) a researcher's reputation.
/// Useful for penalizing malicious behavior. Applies decay *before* slashing.
/// @param _researcher The address of the researcher.
/// @param _amount The amount of reputation to slash.
function slashReputation(address _researcher, uint256 _amount) external onlyManager {
     uint256 currentRep = getResearcherReputation(_researcher); // Get decayed value
     uint256 newRep = currentRep > _amount ? currentRep - _amount : 0;
     researcherReputation[_researcher] = newRep; // Update the *raw* reputation storage
     researcherLastReputationUpdateEpoch[_researcher] = currentEpoch; // Update last update epoch

     emit ReputationSlashed(_researcher, _amount, msg.sender, currentEpoch);
     emit ReputationUpdated(_researcher, newRep, currentEpoch);
}

/// @notice Allows the manager to update the global reputation decay rate.
/// @param _rate The new decay rate percentage out of 10000 per epoch.
function updateReputationDecayRate(uint256 _rate) external onlyManager {
    if (_rate > 10000) revert InvalidDecayRate();

    uint256 oldRate = reputationDecayRate;
    reputationDecayRate = _rate;
    emit ConfigurationUpdated("reputationDecayRate", oldRate, _rate);
}


// --- V. Configuration & Admin / Getters ---

/// @notice Allows the current manager to transfer the manager role to a new address.
/// @param _newManager The address of the new manager.
function setTreasuryManager(address _newManager) external onlyManager {
    address oldManager = manager;
    manager = _newManager;
    emit ManagerTransferred(oldManager, _newManager);
}

/// @notice Allows the manager to set the duration of an epoch in seconds.
/// Must be greater than 0.
/// @param _duration The new epoch duration in seconds.
function setEpochDuration(uint256 _duration) external onlyManager {
    if (_duration == 0) revert InvalidDuration();
    uint256 oldDuration = epochDuration;
    epochDuration = _duration;
     // Adjust next epoch time based on new duration? Complex edge cases.
     // Simpler: New duration applies *after* the current epoch ends.
     // If epoch has ended but startNewEpoch not called, nextEpochStartTime will be old + old.
     // Next call to startNewEpoch will set it to block.timestamp + new.
    emit ConfigurationUpdated("epochDuration", oldDuration, _duration);
}

/// @notice Allows the manager to set the minimum duration a proposal must be implicitly in 'Voting' state.
/// @param _duration The new minimum voting duration in seconds.
function setMinVotingDuration(uint256 _duration) external onlyManager {
    uint256 oldDuration = minVotingDuration;
    minVotingDuration = _duration;
    emit ConfigurationUpdated("minVotingDuration", oldDuration, _duration);
}

/// @notice Allows the manager to set the minimum duration a proposal must be in the 'Developing' state.
/// @param _duration The new minimum development duration in seconds.
function setMinDevelopmentDuration(uint256 _duration) external onlyManager {
    uint256 oldDuration = minDevelopmentDuration;
    minDevelopmentDuration = _duration;
    emit ConfigurationUpdated("minDevelopmentDuration", oldDuration, _duration);
}

/// @notice Allows the manager to set the base reputation awarded for completing a proposal.
/// @param _rate The new reputation reward rate.
function setReputationRewardRate(uint256 _rate) external onlyManager {
    uint256 oldRate = reputationRewardRate;
    reputationRewardRate = _rate;
    emit ConfigurationUpdated("reputationRewardRate", oldRate, _rate);
}

/// @notice Gets the total number of proposals ever submitted.
/// @return count The total proposal count.
function getProposalCount() external view returns (uint256 count) {
    return proposalCounter;
}

/// @notice Checks if a specific researcher has voted on a specific proposal.
/// @param _proposalId The ID of the proposal.
/// @param _researcher The address of the researcher.
/// @return hasVoted True if the researcher has voted, false otherwise.
function hasVotedOnProposal(uint256 _proposalId, address _researcher) external view returns (bool hasVoted) {
     Proposal storage proposal = proposals[_proposalId];
    if (proposal.id == 0 && _proposalId != 0) revert ProposalNotFound(_proposalId);

    return proposal.voters[_researcher];
}

/// @notice Retrieves the decay rate for a specific resource type.
/// @param _resourceType The type of resource.
/// @return rate The decay rate percentage out of 10000.
function getResourceDecayRate(ResourceType _resourceType) external view returns (uint256 rate) {
    return resourceDecayRate[_resourceType];
}

/// @notice Retrieves the amount of a specific resource type added each epoch.
/// @param _resourceType The type of resource.
/// @return amount The amount added per epoch.
function getEpochResourcesAdded(ResourceType _resourceType) external view returns (uint256 amount) {
    return epochResourcesAdded[_resourceType];
}

/// @notice Retrieves the global reputation decay rate.
/// @return rate The decay rate percentage out of 10000 per epoch.
function getReputationDecayRate() external view returns (uint256 rate) {
    return reputationDecayRate;
}


// --- Internal Helper Functions ---

/// @dev Applies resource decay based on configured rates for all resource types.
function _applyResourceDecay() internal {
    ResourceType[] memory resourceTypes = new ResourceType[](4);
    resourceTypes[0] = ResourceType.Data;
    resourceTypes[1] = ResourceType.Compute;
    resourceTypes[2] = ResourceType.Energy;
    resourceTypes[3] = ResourceType.Knowledge;

    for (uint i = 0; i < resourceTypes.length; i++) {
        ResourceType rType = resourceTypes[i];
        uint256 currentSupply = resourceSupply[rType];
        uint256 decayRate = resourceDecayRate[rType];

        if (currentSupply > 0 && decayRate > 0) {
            // Decay amount = currentSupply * decayRate / 10000
            uint256 decayAmount = (currentSupply * decayRate) / 10000;
            resourceSupply[rType] = currentSupply > decayAmount ? currentSupply - decayAmount : 0;
             // No specific event for decay to save gas per resource type
        }
    }
}

/// @dev Adds configured amounts of resources for the new epoch.
function _addEpochResources() internal {
     ResourceType[] memory resourceTypes = new ResourceType[](4);
    resourceTypes[0] = ResourceType.Data;
    resourceTypes[1] = ResourceType.Compute;
    resourceTypes[2] = ResourceType.Energy;
    resourceTypes[3] = ResourceType.Knowledge;

    for (uint i = 0; i < resourceTypes.length; i++) {
        ResourceType rType = resourceTypes[i];
        uint256 amountToAdd = epochResourcesAdded[rType];
         if (amountToAdd > 0) {
            resourceSupply[rType] += amountToAdd;
             // No specific event for adding per resource type to save gas
         }
    }
     // Could emit a single event indicating resources were added this epoch, or rely on EpochStarted event
}

/// @dev Updates a researcher's raw reputation and records the epoch of the update.
/// Applies decay before adding/subtracting.
function _updateResearcherReputation(address _researcher, int256 _change) internal {
    uint256 currentRep = getResearcherReputation(_researcher); // Get reputation with decay applied

    uint256 newRawRep; // This will store the *new base value* before future decay
    if (_change >= 0) {
        // Adding reputation: current (decayed) + change
        newRawRep = currentRep + uint256(_change);
    } else {
        // Slashing reputation: current (decayed) - abs(change)
        uint256 absChange = uint256(-_change);
        newRawRep = currentRep > absChange ? currentRep - absChange : 0;
    }

    researcherReputation[_researcher] = newRawRep; // Store the calculated new value
    researcherLastReputationUpdateEpoch[_researcher] = currentEpoch; // Mark this epoch as the last update

    emit ReputationUpdated(_researcher, newRawRep, currentEpoch); // Emitting the raw value after update
}

/// @dev Refunds resources from a proposal that was in development.
/// Used internally by cancel/reject.
function _refundProposalResources(uint256 _proposalId) internal {
    Proposal storage proposal = proposals[_proposalId];
    ResourceType[] memory resourceTypes = new ResourceType[](4);
    resourceTypes[0] = ResourceType.Data;
    resourceTypes[1] = ResourceType.Compute;
    resourceTypes[2] = ResourceType.Energy;
    resourceTypes[3] = ResourceType.Knowledge;

    for (uint i = 0; i < resourceTypes.length; i++) {
        ResourceType rType = resourceTypes[i];
        uint256 required = proposal.requiredResources[rType];
        if (required > 0) {
             resourceSupply[rType] += required;
             emit ResourcesRefunded(_proposalId, rType, required);
        }
    }
}

// Helper for getting manager address (often useful)
function getManager() external view returns (address) {
    return manager;
}
```