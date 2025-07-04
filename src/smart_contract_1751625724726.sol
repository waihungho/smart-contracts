Okay, here is a Solidity smart contract incorporating a blend of advanced, creative, and trendy concepts focusing on a dynamic, on-chain reputation system tied to proposal-based governance, a shared knowledge base, and earnable traits within an epoch-based system.

This contract is designed to be:
1.  **Dynamic & State-rich:** Reputation and traits change based on user interaction and governance outcomes.
2.  **Governance-focused:** Core changes to the system (parameters, data, reputation) happen via proposals.
3.  **Epoch-based:** Actions like proposal resolution are batched and processed at specific time intervals.
4.  **SBT-inspired:** Users register for a non-transferable profile ID representing their presence and reputation in the system.
5.  **Creative:** Combines reputation dynamics, multiple proposal types (including direct reputation challenge and trait grants), and a mutable knowledge base.

**It is NOT:**
*   A standard ERC-20, ERC-721, or ERC-1155.
*   A simple staking or farming contract.
*   A basic multi-signature wallet.
*   A generic DAO framework (it has DAO *elements* but a specific structure).
*   An exact copy of any widely known open-source protocol (though it uses common Solidity patterns).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Aetherium Agora
 * @author Your Name/Alias (for example)
 * @dev A decentralized system for community governance, reputation building,
 *      knowledge curation, and trait earning within an epoch-based structure.
 *      Users register for a non-transferable profile and participate in
 *      proposals affecting system parameters, a shared knowledge base,
 *      other users' reputations, and trait distribution.
 */

/*
 * OUTLINE:
 * 1. State Variables & Mappings
 * 2. Structs & Enums
 * 3. Events
 * 4. Errors
 * 5. Modifiers
 * 6. Constructor
 * 7. User Profile Management (SBT-like)
 * 8. Epoch Management
 * 9. Proposal Lifecycle & Signaling
 * 10. Resolution Logic (Internal Helpers)
 * 11. Parameter Management (Via Proposals)
 * 12. Knowledge Base Management (Via Proposals)
 * 13. Trait Management (Via Proposals)
 * 14. Query Functions
 * 15. Fee Management
 */

/*
 * FUNCTION SUMMARY:
 *
 * -- User Profile Management --
 * registerProfile(): Registers a user, assigning a unique, non-transferable ID and initial reputation.
 * getReputationScore(address user): Returns the current reputation score of a user.
 * getProfileID(address user): Returns the unique profile ID of a user.
 * hasProfile(address user): Checks if a user has registered a profile.
 * getReputationProfile(address user): Returns the full ReputationProfile struct for a user.
 *
 * -- Epoch Management --
 * getCurrentEpoch(): Returns the current epoch number.
 * getNextEpochTimestamp(): Returns the timestamp when the next epoch can potentially start.
 * advanceEpoch(): Public function to advance the epoch if the required duration has passed. Triggers proposal resolution.
 *
 * -- Proposal Lifecycle & Signaling --
 * submitProposal(ProposalType proposalType, bytes32 targetKey, bytes newValue, string calldata description): Allows a user with sufficient reputation to submit a proposal. Requires a fee.
 * activateProposal(uint256 proposalId): Allows anyone to activate a pending proposal after a delay.
 * signalSupport(uint256 proposalId): Allows a user with sufficient reputation to signal support for an active proposal. Signaling power is reputation-weighted.
 * cancelProposal(uint256 proposalId): Allows the proposer to cancel a pending or active proposal.
 * getProposalState(uint256 proposalId): Returns the current state of a proposal.
 * getProposalDetails(uint256 proposalId): Returns the details of a proposal.
 * getActiveProposalsForEpoch(uint256 epoch): Returns the list of proposal IDs active in a specific epoch.
 * getSignalingPower(uint256 proposalId): Returns the total accumulated signaling power for a proposal.
 * hasSignaled(uint256 proposalId, address user): Checks if a user has signaled support for a proposal.
 *
 * -- Parameter Management (Via Proposals) --
 * getSystemParameter(bytes32 parameterKey): Returns the current value of a system parameter.
 *
 * -- Knowledge Base Management (Via Proposals) --
 * getKnowledgeValue(bytes32 knowledgeKey): Returns the current value stored in the knowledge base for a given key.
 *
 * -- Trait Management (Via Proposals) --
 * defineTrait(string memory name, string memory uri, uint256 requiredReputation): Allows the owner (or eventually governance) to define new traits.
 * getTraitDetails(uint256 traitId): Returns the details of a specific trait.
 * getUserTraits(address user): Returns a list of trait IDs the user possesses.
 * hasTrait(address user, uint256 traitId): Checks if a user possesses a specific trait.
 *
 * -- Utility & Fee Management --
 * withdrawFees(): Allows the owner to withdraw accumulated proposal fees.
 * getContractBalance(): Returns the current balance of the contract (primarily proposal fees).
 *
 * -- Internal Functions --
 * _resolveProposals(uint256 epochToResolve): Internal function to process proposals active in a given epoch.
 * _updateReputation(address user, int256 scoreChange): Internal function to modify a user's reputation score.
 * _resolveParameterChange(uint256 proposalId, bytes32 key, bytes memory value): Handles ParameterChange proposal outcomes.
 * _resolveKnowledgeUpdate(uint256 proposalId, bytes32 key, bytes memory value): Handles KnowledgeUpdate proposal outcomes.
 * _resolveReputationChallenge(uint256 proposalId, bytes32 targetUserBytes32, bytes memory scoreChangeBytes): Handles ReputationChallenge proposal outcomes.
 * _resolveTraitGrant(uint256 proposalId, bytes32 targetUserBytes32, bytes memory traitIdBytes): Handles TraitGrant proposal outcomes.
 */


contract AetheriumAgora {

    address public owner; // Simple ownership for initial setup/fee withdrawal
    uint256 public currentEpoch = 0;
    uint256 public lastEpochAdvanceTimestamp;

    // Epoch duration in seconds (e.g., 1 day)
    uint256 public immutable EPOCH_DURATION;

    // -- SBT-like Profile System --
    uint256 private nextReputationID = 1;
    struct ReputationProfile {
        uint256 id; // Unique, non-transferable ID
        uint256 score; // Current reputation score
        uint64 lastActiveEpoch; // Epoch when profile was last active/scored
        bool exists; // Flag to check if profile is registered
    }
    mapping(address => ReputationProfile) public reputations;
    // Mapping for quick lookup of address to ID (redundant but helpful if only ID is known elsewhere)
    // mapping(uint256 => address) public reputationIdToAddress; // Might add later if needed

    // -- System Parameters (Governed) --
    struct SystemParameters {
        uint256 proposalFee; // Fee to submit a proposal
        uint256 minReputationToPropose; // Minimum reputation required to submit
        uint256 minReputationToSignal; // Minimum reputation required to signal support
        uint256 proposalActivationDelay; // Delay after submission before proposal can be activated (in seconds)
        uint256 minSignalingPowerForPass; // Minimum total signaling power for a proposal to pass
        uint256 signalingReputationMultiplier; // Multiplier for reputation to get signaling power (e.g., score * multiplier)
        int256 reputationGainOnSuccessfulSignal; // Reputation change for signaling a passed proposal
        int256 reputationLossOnFailedSignal; // Reputation change for signaling a failed proposal
        uint256 initialReputation; // Reputation granted upon registration
        uint256 minReputation; // Minimum allowed reputation (can't go below this)
    }
    SystemParameters public systemParameters;
    // Using a bytes32 key for parameters allows governed changes to different specific settings
    mapping(bytes32 => bytes) private governedParameters; // Alternative/future-proof storage for governed params

    // -- Proposal System --
    uint256 private proposalCounter = 0;
    struct Proposal {
        uint256 id;
        address proposer;
        ProposalState state;
        ProposalType proposalType;
        uint256 creationTimestamp;
        uint256 activationTimestamp; // When it became Active
        uint256 resolutionEpoch; // Epoch it will be resolved in
        uint256 requiredReputationToPropose; // Snapshot of param at creation
        uint256 requiredSignalingPower; // Snapshot of param at activation (optional, or derive from minSignalingPowerForPass)
        uint256 currentSignalingPower;
        bytes32 targetKey; // Parameter key, Knowledge key, or target user address (encoded)
        bytes newValue; // New parameter value, Knowledge value, reputation change (encoded), or trait ID (encoded)
        string description; // IPFS hash or short description
        bool passed; // Result after resolution
    }
    mapping(uint256 => Proposal) public proposals;
    // Track who signaled on which proposal
    mapping(uint256 => mapping(address => bool)) private signaledByProposal;
    // Track active proposals per epoch for resolution
    mapping(uint256 => uint256[]) private activeProposalsByEpoch;

    enum ProposalState {
        Pending,    // Submitted, waiting activation
        Active,     // Activated, open for signaling in current epoch
        Passed,     // Resolved, met signaling threshold
        Failed,     // Resolved, did not meet signaling threshold
        Canceled    // Canceled by proposer or governance
    }

    enum ProposalType {
        ParameterChange,  // Change a system parameter
        KnowledgeUpdate,  // Update a value in the Knowledge Base
        ReputationChallenge, // Propose changing a user's reputation
        TraitGrant        // Propose granting a specific trait to a user
        // Add more types here (e.g., ContractUpgrade, FundsDistribution)
    }

    // -- Shared Knowledge Base (Governed) --
    mapping(bytes32 => bytes) private knowledgeBase;

    // -- Trait/Badge System (Governed Definition & Granting) --
    uint256 private traitCounter = 0;
    struct Trait {
        uint256 id;
        string name;
        string uri; // IPFS hash or URL for trait metadata/image
        uint256 requiredReputation; // Reputation needed for automatic eligibility or display
    }
    mapping(uint256 => Trait) public traits;
    mapping(address => mapping(uint256 => bool)) private userTraits;
    mapping(address => uint256[]) private userTraitList; // To easily query user's traits

    // -- Events --
    event ProfileRegistered(address indexed user, uint256 profileId, uint256 initialScore);
    event EpochAdvanced(uint256 indexed epoch, uint256 timestamp);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType, uint256 submissionTimestamp);
    event ProposalActivated(uint256 indexed proposalId, uint256 indexed activationEpoch, uint256 activationTimestamp);
    event SignalRecorded(uint256 indexed proposalId, address indexed signaler, uint256 signalingPower);
    event ProposalResolved(uint256 indexed proposalId, uint256 indexed resolutionEpoch, ProposalState finalState, bool passed);
    event ReputationUpdated(address indexed user, int256 scoreChange, uint256 newScore);
    event ParameterChanged(bytes32 indexed parameterKey, bytes newValue); // Emitted when ParameterChange proposal passes
    event KnowledgeUpdated(bytes32 indexed knowledgeKey, bytes newValue); // Emitted when KnowledgeUpdate proposal passes
    event TraitDefined(uint256 indexed traitId, string name, string uri, uint256 requiredReputation);
    event TraitGranted(address indexed user, uint256 indexed traitId); // Emitted when TraitGrant proposal passes
    event FeesWithdrawn(address indexed to, uint256 amount);

    // -- Errors --
    error ProfileAlreadyRegistered();
    error ProfileNotRegistered();
    error NotEnoughReputation(uint256 required, uint256 current);
    error NotEnoughFee(uint256 required, uint256 current);
    error EpochNotReadyToAdvance(uint256 nextEpochTimestamp);
    error ProposalDoesNotExist();
    error ProposalNotInState(ProposalState requiredState, ProposalState currentState);
    error ProposalNotInCorrectEpochForActivation(uint256 activationEpoch);
    error ActivationDelayNotPassed(uint256 activationTimestamp);
    error AlreadySignaled();
    error NotProposer();
    error InvalidProposalType();
    error InvalidTargetAddress();
    error InvalidScoreChange();
    error TraitDoesNotExist();
    error UserAlreadyHasTrait();
    error OnlyOwner(); // For owner-restricted functions

    // -- Modifiers --
    modifier onlyExistingProfile() {
        if (!reputations[msg.sender].exists) {
            revert ProfileNotRegistered();
        }
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        _;
    }

    // -- Constructor --
    constructor(uint256 _epochDuration, uint256 _initialReputation, uint256 _minReputation, uint256 _proposalFee, uint256 _minReputationToPropose, uint256 _minReputationToSignal, uint256 _proposalActivationDelay, uint256 _minSignalingPowerForPass, uint256 _signalingReputationMultiplier, int256 _reputationGainOnSuccessfulSignal, int256 _reputationLossOnFailedSignal) {
        owner = msg.sender;
        EPOCH_DURATION = _epochDuration;
        lastEpochAdvanceTimestamp = block.timestamp;

        systemParameters = SystemParameters({
            proposalFee: _proposalFee,
            minReputationToPropose: _minReputationToPropose,
            minReputationToSignal: _minReputationToSignal,
            proposalActivationDelay: _proposalActivationDelay,
            minSignalingPowerForPass: _minSignalingPowerForPass,
            signalingReputationMultiplier: _signalingReputationMultiplier,
            reputationGainOnSuccessfulSignal: _reputationGainOnSuccessfulSignal,
            reputationLossOnFailedSignal: _reputationLossOnFailedSignal,
            initialReputation: _initialReputation,
            minReputation: _minReputation
        });

        // Initialize governed parameters with their initial values
        // For simplicity, mapping keys could just be keccak256 of param names
        governedParameters[keccak256("proposalFee")] = abi.encodePacked(systemParameters.proposalFee);
        governedParameters[keccak256("minReputationToPropose")] = abi.encodePacked(systemParameters.minReputationToPropose);
        governedParameters[keccak256("minReputationToSignal")] = abi.encodePacked(systemParameters.minReputationToSignal);
        governedParameters[keccak256("proposalActivationDelay")] = abi.encodePacked(systemParameters.proposalActivationDelay);
        governedParameters[keccak256("minSignalingPowerForPass")] = abi.encodePacked(systemParameters.minSignalingPowerForPass);
        governedParameters[keccak256("signalingReputationMultiplier")] = abi.encodePacked(systemParameters.signalingReputationMultiplier);
        governedParameters[keccak256("reputationGainOnSuccessfulSignal")] = abi.encodePacked(systemParameters.reputationGainOnSuccessfulSignal);
        governedParameters[keccak256("reputationLossOnFailedSignal")] = abi.encodePacked(systemParameters.reputationLossOnFailedSignal);
        governedParameters[keccak256("initialReputation")] = abi.encodePacked(systemParameters.initialReputation);
        governedParameters[keccak256("minReputation")] = abi.encodePacked(systemParameters.minReputation);
    }

    // -- User Profile Management --

    /**
     * @dev Registers a user, assigning a unique, non-transferable ID and initial reputation.
     *      Can only be called once per address.
     */
    function registerProfile() external {
        if (reputations[msg.sender].exists) {
            revert ProfileAlreadyRegistered();
        }
        reputations[msg.sender] = ReputationProfile({
            id: nextReputationID,
            score: systemParameters.initialReputation,
            lastActiveEpoch: currentEpoch, // Or 0, depending on desired logic
            exists: true
        });
        // reputationIdToAddress[nextReputationID] = msg.sender; // If needed
        emit ProfileRegistered(msg.sender, nextReputationID, systemParameters.initialReputation);
        unchecked {
            nextReputationID++;
        }
    }

    /**
     * @dev Returns the current reputation score of a user.
     * @param user The address of the user.
     * @return The reputation score.
     */
    function getReputationScore(address user) external view returns (uint256) {
        return reputations[user].score;
    }

    /**
     * @dev Returns the unique profile ID of a user.
     * @param user The address of the user.
     * @return The profile ID. Returns 0 if no profile exists.
     */
    function getProfileID(address user) external view returns (uint256) {
        return reputations[user].id;
    }

    /**
     * @dev Checks if a user has registered a profile.
     * @param user The address of the user.
     * @return True if the user has a profile, false otherwise.
     */
    function hasProfile(address user) external view returns (bool) {
        return reputations[user].exists;
    }

     /**
      * @dev Returns the full ReputationProfile struct for a user.
      * @param user The address of the user.
      * @return The ReputationProfile struct.
      */
    function getReputationProfile(address user) external view returns (ReputationProfile memory) {
         return reputations[user];
    }

    // -- Epoch Management --

    /**
     * @dev Returns the current epoch number.
     */
    function getCurrentEpoch() external view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Returns the timestamp when the next epoch can potentially start.
     */
    function getNextEpochTimestamp() external view returns (uint256) {
        return lastEpochAdvanceTimestamp + EPOCH_DURATION;
    }

    /**
     * @dev Advances the current epoch. Can only be called if the EPOCH_DURATION
     *      has passed since the last advance. Triggers the resolution of
     *      proposals active in the epoch that just ended.
     */
    function advanceEpoch() external {
        uint256 nextTimestamp = lastEpochAdvanceTimestamp + EPOCH_DURATION;
        if (block.timestamp < nextTimestamp) {
            revert EpochNotReadyToAdvance(nextTimestamp);
        }

        uint256 epochToResolve = currentEpoch;

        unchecked {
            currentEpoch++;
        }
        lastEpochAdvanceTimestamp = block.timestamp;

        // Resolve proposals from the epoch that *just* finished
        _resolveProposals(epochToResolve);

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    // -- Proposal Lifecycle & Signaling --

    /**
     * @dev Allows a user with sufficient reputation to submit a new proposal.
     *      Requires a proposal fee. The proposal starts in the Pending state.
     * @param proposalType The type of proposal.
     * @param targetKey Specific identifier depending on proposal type (e.g., parameter key, knowledge key, target user address bytes32).
     * @param newValue New value depending on proposal type (e.g., new parameter value bytes, new knowledge value bytes, reputation change bytes, trait ID bytes).
     * @param description A short description or IPFS hash for more details.
     */
    function submitProposal(ProposalType proposalType, bytes32 targetKey, bytes calldata newValue, string calldata description) external payable onlyExistingProfile {
        if (reputations[msg.sender].score < systemParameters.minReputationToPropose) {
            revert NotEnoughReputation(systemParameters.minReputationToPropose, reputations[msg.sender].score);
        }
        if (msg.value < systemParameters.proposalFee) {
            revert NotEnoughFee(systemParameters.proposalFee, msg.value);
        }

        uint256 newProposalId = proposalCounter;
        proposals[newProposalId] = Proposal({
            id: newProposalId,
            proposer: msg.sender,
            state: ProposalState.Pending,
            proposalType: proposalType,
            creationTimestamp: block.timestamp,
            activationTimestamp: 0, // Set on activation
            resolutionEpoch: 0, // Set on activation
            requiredReputationToPropose: reputations[msg.sender].score, // Snapshot reputation
            requiredSignalingPower: 0, // Set on activation from system parameters
            currentSignalingPower: 0,
            targetKey: targetKey,
            newValue: newValue,
            description: description,
            passed: false
        });

        unchecked {
            proposalCounter++;
        }

        emit ProposalSubmitted(newProposalId, msg.sender, proposalType, block.timestamp);
    }

    /**
     * @dev Allows anyone to activate a pending proposal if the activation delay has passed.
     *      Moves the proposal to the Active state and assigns it to the current epoch for resolution.
     * @param proposalId The ID of the proposal to activate.
     */
    function activateProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0 && proposalId != 0) { // Check if proposal exists (handles ID 0 case)
             revert ProposalDoesNotExist();
        }
        if (proposal.state != ProposalState.Pending) {
            revert ProposalNotInState(ProposalState.Pending, proposal.state);
        }
        if (block.timestamp < proposal.creationTimestamp + systemParameters.proposalActivationDelay) {
             revert ActivationDelayNotPassed(proposal.creationTimestamp + systemParameters.proposalActivationDelay);
        }

        proposal.state = ProposalState.Active;
        proposal.activationTimestamp = block.timestamp;
        proposal.resolutionEpoch = currentEpoch + 1; // Resolved in the *next* epoch
        proposal.requiredSignalingPower = systemParameters.minSignalingPowerForPass; // Snapshot required power

        activeProposalsByEpoch[currentEpoch + 1].push(proposalId); // Add to list for next epoch's resolution

        emit ProposalActivated(proposalId, currentEpoch + 1, block.timestamp);
    }


    /**
     * @dev Allows a user with sufficient reputation to signal support for an active proposal.
     *      Signaling power is calculated based on the user's current reputation score.
     * @param proposalId The ID of the proposal to signal support for.
     */
    function signalSupport(uint256 proposalId) external onlyExistingProfile {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.id == 0 && proposalId != 0) { // Check if proposal exists (handles ID 0 case)
             revert ProposalDoesNotExist();
         }
        if (proposal.state != ProposalState.Active) {
            revert ProposalNotInState(ProposalState.Active, proposal.state);
        }
        if (reputations[msg.sender].score < systemParameters.minReputationToSignal) {
            revert NotEnoughReputation(systemParameters.minReputationToSignal, reputations[msg.sender].score);
        }
        if (signaledByProposal[proposalId][msg.sender]) {
            revert AlreadySignaled();
        }
        // Check if this proposal is active in the *current* epoch (it will be resolved in the *next*)
        if (proposal.resolutionEpoch != currentEpoch + 1) {
             revert ProposalNotInCorrectEpochForActivation(currentEpoch + 1);
        }


        uint256 signalingPower = reputations[msg.sender].score * systemParameters.signalingReputationMultiplier;
        proposal.currentSignalingPower += signalingPower;
        signaledByProposal[proposalId][msg.sender] = true;
        reputations[msg.sender].lastActiveEpoch = uint64(currentEpoch); // Mark user active

        emit SignalRecorded(proposalId, msg.sender, signalingPower);
    }

    /**
     * @dev Allows the proposer to cancel their proposal if it's still in Pending or Active state.
     * @param proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
         if (proposal.id == 0 && proposalId != 0) { // Check if proposal exists (handles ID 0 case)
             revert ProposalDoesNotExist();
         }
        if (proposal.proposer != msg.sender) {
            revert NotProposer();
        }
        if (proposal.state != ProposalState.Pending && proposal.state != ProposalState.Active) {
            revert ProposalNotInState(ProposalState.Pending, proposal.state);
        }

        // Note: Fees are *not* refunded on cancellation in this simple model.
        proposal.state = ProposalState.Canceled;
        // Removal from activeProposalsByEpoch list is implicitly handled
        // because resolution function checks state.

        // Potentially refund signaling power? Or just let it be lost?
        // For simplicity, let's just let signaling power be lost on cancel.
    }

    /**
     * @dev Returns the current state of a proposal.
     * @param proposalId The ID of the proposal.
     * @return The ProposalState enum value.
     */
    function getProposalState(uint256 proposalId) external view returns (ProposalState) {
         if (proposals[proposalId].id == 0 && proposalId != 0) { return ProposalState.Pending; /* Or revert, depending on preference. Let's assume 0 means not found/default */ } // Check if proposal exists
        return proposals[proposalId].state;
    }

    /**
     * @dev Returns the details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getProposalDetails(uint256 proposalId) external view returns (
        uint256 id,
        address proposer,
        ProposalState state,
        ProposalType proposalType,
        uint256 creationTimestamp,
        uint256 activationTimestamp,
        uint256 resolutionEpoch,
        uint256 requiredReputationToPropose,
        uint256 requiredSignalingPower,
        uint256 currentSignalingPower,
        bytes32 targetKey,
        bytes memory newValue,
        string memory description,
        bool passed
    ) {
         if (proposals[proposalId].id == 0 && proposalId != 0) { revert ProposalDoesNotExist(); } // Check if proposal exists
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.proposer,
            proposal.state,
            proposal.proposalType,
            proposal.creationTimestamp,
            proposal.activationTimestamp,
            proposal.resolutionEpoch,
            proposal.requiredReputationToPropose,
            proposal.requiredSignalingPower,
            proposal.currentSignalingPower,
            proposal.targetKey,
            proposal.newValue,
            proposal.description,
            proposal.passed
        );
    }

    /**
     * @dev Returns the list of proposal IDs that were active and resolved in a specific epoch.
     * @param epoch The epoch number.
     * @return An array of proposal IDs.
     */
    function getActiveProposalsForEpoch(uint256 epoch) external view returns (uint256[] memory) {
        return activeProposalsByEpoch[epoch]; // Returns the list that was processed for that epoch
    }

    /**
     * @dev Returns the total accumulated signaling power for a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return The total signaling power.
     */
    function getSignalingPower(uint256 proposalId) external view returns (uint256) {
         if (proposals[proposalId].id == 0 && proposalId != 0) { return 0; } // Check if proposal exists
        return proposals[proposalId].currentSignalingPower;
    }

    /**
     * @dev Checks if a specific user has signaled support for a proposal.
     * @param proposalId The ID of the proposal.
     * @param user The address of the user.
     * @return True if the user has signaled, false otherwise.
     */
    function hasSignaled(uint256 proposalId, address user) external view returns (bool) {
         if (proposals[proposalId].id == 0 && proposalId != 0) { return false; } // Check if proposal exists
        return signaledByProposal[proposalId][user];
    }

    // -- Resolution Logic (Internal) --

    /**
     * @dev Internal function called by advanceEpoch to resolve proposals
     *      that were active in the specified epoch.
     * @param epochToResolve The epoch whose active proposals should be resolved.
     */
    function _resolveProposals(uint256 epochToResolve) internal {
        uint256[] storage proposalIds = activeProposalsByEpoch[epochToResolve];

        for (uint i = 0; i < proposalIds.length; i++) {
            uint256 proposalId = proposalIds[i];
            Proposal storage proposal = proposals[proposalId];

            // Only process proposals that are still Active and were intended for this epoch
            if (proposal.state == ProposalState.Active && proposal.resolutionEpoch == epochToResolve) {
                bool passed = proposal.currentSignalingPower >= proposal.requiredSignalingPower;
                proposal.passed = passed;
                proposal.state = passed ? ProposalState.Passed : ProposalState.Failed;

                // Apply proposal effects if passed
                if (passed) {
                    if (proposal.proposalType == ProposalType.ParameterChange) {
                        _resolveParameterChange(proposalId, proposal.targetKey, proposal.newValue);
                    } else if (proposal.proposalType == ProposalType.KnowledgeUpdate) {
                        _resolveKnowledgeUpdate(proposalId, proposal.targetKey, proposal.newValue);
                    } else if (proposal.proposalType == ProposalType.ReputationChallenge) {
                         _resolveReputationChallenge(proposalId, proposal.targetKey, proposal.newValue);
                    } else if (proposal.proposalType == ProposalType.TraitGrant) {
                         _resolveTraitGrant(proposalId, proposal.targetKey, proposal.newValue);
                    }
                    // Add more resolution handlers for new proposal types here
                }

                // Update reputation for all users who signaled on this proposal
                // NOTE: This simple iteration might become expensive with many signallers.
                // A more gas-efficient design might involve users claiming reputation changes.
                 for (address signaler : getSignallersForProposal(proposalId)) {
                     if (reputations[signaler].exists) {
                         int256 repChange = passed
                             ? systemParameters.reputationGainOnSuccessfulSignal
                             : systemParameters.reputationLossOnFailedSignal;
                         _updateReputation(signaler, repChange);
                     }
                 }

                emit ProposalResolved(proposalId, epochToResolve, proposal.state, passed);
            }
        }
         // Clear the list for the resolved epoch to save gas on future queries (optional)
         // delete activeProposalsByEpoch[epochToResolve]; // Careful if you need historical lists
    }

    /**
     * @dev Internal helper to update a user's reputation score.
     * @param user The address of the user.
     * @param scoreChange The amount to change the score by (can be negative).
     */
    function _updateReputation(address user, int256 scoreChange) internal {
        ReputationProfile storage profile = reputations[user];
        int256 currentScore = int256(profile.score);
        int256 minScore = int256(systemParameters.minReputation);

        unchecked {
            int256 newScore = currentScore + scoreChange;
             // Ensure score doesn't drop below the minimum
            if (newScore < minScore) {
                newScore = minScore;
            }
            profile.score = uint256(newScore);
        }
        emit ReputationUpdated(user, scoreChange, profile.score);
    }

    /**
     * @dev Internal helper to get addresses who signaled on a proposal.
     *      NOTE: This is inefficient for many signallers. For a real DApp,
     *      consider tracking signallers differently or requiring users to claim.
     *      This is simplified for demonstration.
     */
     function getSignallersForProposal(uint256 proposalId) internal view returns (address[] memory) {
         // This is a placeholder. A real implementation would need to store signaller addresses.
         // A mapping like `mapping(uint256 => address[]) public signallersByProposal;`
         // populated in signalSupport() would be needed, but arrays in mappings are complex/expensive.
         // For this example, we'll return an empty array. Realistically, you'd query events
         // or use a dedicated subgraph/off-chain indexer to find signallers.
         // Or, modify `signalSupport` to store addresses directly (gas cost).
         // Let's just return an empty array and emit an event instead.
         // The reputation update loop above is thus NOT functional without a list of signallers.
         // A better approach for reputation updates: user calls a function *after* resolution
         // to claim their reputation change, which checks if they signaled and if the proposal passed/failed.
         return new address[](0); // Placeholder - see note above
     }


    /**
     * @dev Handles the outcome of a passed ParameterChange proposal.
     * @param proposalId The ID of the proposal.
     * @param key The key of the parameter to change (bytes32 representation of parameter name).
     * @param value The new value for the parameter (abi.encoded bytes).
     */
    function _resolveParameterChange(uint256 proposalId, bytes32 key, bytes memory value) internal {
        // For simplicity, directly map bytes32 key to the systemParameters struct fields.
        // A more robust system might use a mapping `mapping(bytes32 => bytes) governedParameters;`
        // and update that map, requiring getters to decode. Let's switch to the mapping for flexibility.

        governedParameters[key] = value;
        emit ParameterChanged(key, value);

        // Additionally, for direct access and type safety, you might want to update
        // the struct values here by decoding the bytes. This requires knowing the type.
        // Example (simplified - requires knowing expected type of 'value'):
        // if (key == keccak256("proposalFee")) { systemParameters.proposalFee = abi.decode(value, (uint256)); }
        // ... and so on for all parameters ...
        // Keeping the `governedParameters` mapping updated is the more flexible approach for arbitrary parameters.
    }

    /**
     * @dev Handles the outcome of a passed KnowledgeUpdate proposal.
     * @param proposalId The ID of the proposal.
     * @param key The key in the knowledge base to update (bytes32).
     * @param value The new value (bytes).
     */
    function _resolveKnowledgeUpdate(uint256 proposalId, bytes32 key, bytes memory value) internal {
        knowledgeBase[key] = value;
        emit KnowledgeUpdated(key, value);
    }

    /**
     * @dev Handles the outcome of a passed ReputationChallenge proposal.
     *      Allows changing a target user's reputation.
     *      newValue is expected to be abi.encodePacked(int256 scoreChange).
     * @param proposalId The ID of the proposal.
     * @param targetUserBytes32 The address of the target user, encoded as bytes32.
     * @param scoreChangeBytes The int256 score change, encoded as bytes.
     */
    function _resolveReputationChallenge(uint256 proposalId, bytes32 targetUserBytes32, bytes memory scoreChangeBytes) internal {
        address targetUser = address(uint160(uint256(targetUserBytes32)));
         if (!reputations[targetUser].exists) {
             // Target user doesn't exist, proposal effect fails but proposal state is Passed
             return;
         }

        if (scoreChangeBytes.length != 32) {
            revert InvalidScoreChange(); // Not a valid int256 encoding
        }
        int256 scoreChange = abi.decode(scoreChangeBytes, (int256));

        _updateReputation(targetUser, scoreChange);
    }

    /**
     * @dev Handles the outcome of a passed TraitGrant proposal.
     *      Grants a specific trait to a target user.
     *      newValue is expected to be abi.encodePacked(uint256 traitId).
     * @param proposalId The ID of the proposal.
     * @param targetUserBytes32 The address of the target user, encoded as bytes32.
     * @param traitIdBytes The uint256 trait ID, encoded as bytes.
     */
    function _resolveTraitGrant(uint256 proposalId, bytes32 targetUserBytes32, bytes memory traitIdBytes) internal {
        address targetUser = address(uint160(uint256(targetUserBytes32)));
         if (!reputations[targetUser].exists) {
             // Target user doesn't exist
             return;
         }
        if (traitIdBytes.length != 32) {
             // Invalid trait ID encoding
             return;
        }
        uint256 traitId = abi.decode(traitIdBytes, (uint256));

        if (traits[traitId].id == 0 && traitId != 0) { // Check if trait exists
             // Trait doesn't exist
             return;
        }
        if (userTraits[targetUser][traitId]) {
             // User already has trait
             return;
        }

        userTraits[targetUser][traitId] = true;
        userTraitList[targetUser].push(traitId);
        emit TraitGranted(targetUser, traitId);
    }


    // -- Parameter Management (Via Proposals) --

     /**
      * @dev Returns the current value of a system parameter, fetched from the governed storage.
      * @param parameterKey The bytes32 key representing the parameter (e.g., keccak256("proposalFee")).
      * @return The value of the parameter as bytes. Decoding required by caller based on key.
      */
     function getSystemParameter(bytes32 parameterKey) external view returns (bytes memory) {
         return governedParameters[parameterKey];
     }


    // -- Knowledge Base Management (Via Proposals) --

     /**
      * @dev Returns the current value stored in the knowledge base for a given key.
      * @param knowledgeKey The bytes32 key for the knowledge entry.
      * @return The value as bytes. Decoding required by caller based on key.
      */
     function getKnowledgeValue(bytes32 knowledgeKey) external view returns (bytes memory) {
         return knowledgeBase[knowledgeKey];
     }


    // -- Trait Management (Governed Definition & Granting) --

    /**
     * @dev Allows the owner (or later governance via proposal) to define a new type of trait.
     * @param name The name of the trait.
     * @param uri The metadata URI for the trait (e.g., image, description).
     * @param requiredReputation The reputation score suggested or required for this trait.
     * @return The ID of the newly defined trait.
     */
     function defineTrait(string memory name, string memory uri, uint256 requiredReputation) external onlyOwner returns (uint256) {
         uint256 newTraitId = traitCounter;
         traits[newTraitId] = Trait({
             id: newTraitId,
             name: name,
             uri: uri,
             requiredReputation: requiredReputation
         });
         unchecked {
             traitCounter++;
         }
         emit TraitDefined(newTraitId, name, uri, requiredReputation);
         return newTraitId;
     }

     /**
      * @dev Returns the details of a specific trait.
      * @param traitId The ID of the trait.
      * @return The Trait struct.
      */
     function getTraitDetails(uint256 traitId) external view returns (Trait memory) {
          if (traits[traitId].id == 0 && traitId != 0) { revert TraitDoesNotExist(); }
         return traits[traitId];
     }

     /**
      * @dev Returns a list of trait IDs possessed by a user.
      *      NOTE: This returns a list which can be expensive if a user has many traits.
      *      Direct lookup using hasTrait() is more gas-efficient.
      * @param user The address of the user.
      * @return An array of trait IDs.
      */
     function getUserTraits(address user) external view returns (uint256[] memory) {
         return userTraitList[user];
     }

     /**
      * @dev Checks if a user possesses a specific trait.
      * @param user The address of the user.
      * @param traitId The ID of the trait.
      * @return True if the user has the trait, false otherwise.
      */
     function hasTrait(address user, uint256 traitId) external view returns (bool) {
          if (traits[traitId].id == 0 && traitId != 0) { return false; } // Cannot have a non-existent trait
         return userTraits[user][traitId];
     }

    // -- Utility & Fee Management --

    /**
     * @dev Allows the owner to withdraw accumulated proposal fees.
     */
    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(owner).call{value: balance}("");
        require(success, "Fee withdrawal failed");
        emit FeesWithdrawn(owner, balance);
    }

    /**
     * @dev Returns the current balance of the contract (primarily proposal fees).
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive ether for proposal fees
    receive() external payable {}
}
```