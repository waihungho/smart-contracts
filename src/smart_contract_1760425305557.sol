```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AetherNexus: Adaptive Protocol for On-Chain Resource Governance
 * @author Your AI Assistant
 * @notice AetherNexus is an advanced decentralized protocol designed to manage and allocate
 *         scarce on-chain resources dynamically. It features a sophisticated reputation system (NexusPoints),
 *         intent-based resource requests, adaptive governance for key parameters, and robust
 *         dispute resolution. The protocol's behavior evolves through epochs, dynamically adjusting
 *         resource pricing, allocation, and user influence based on network activity, reputation,
 *         and potentially external oracle data. It aims to foster a self-regulating,
 *         meritocratic ecosystem for digital resource access.
 */

// OUTLINE:
// I. Core Infrastructure & Control
// II. Reputation System (NexusPoints)
// III. Resource Pool & Intent Matching
// IV. Adaptive Governance & Epoch Cycles
// V. Advanced Features & External Integration

// FUNCTION SUMMARY:

// I. Core Infrastructure & Control
// 1. constructor(uint256 _initialEpochDuration, address _initialOracle, address[] memory _initialGuardians): Initializes the protocol with epoch duration, oracle address, and initial guardians.
// 2. updateProtocolParameter(bytes32 _paramName, uint256 _newValue): Owner/DAO updates a core protocol constant.
// 3. pauseProtocol(): Emergency pause of critical functions by Owner/Guardian.
// 4. unpauseProtocol(): Resumes protocol operations.
// 5. addGuardian(address _newGuardian): Adds an address to the Guardian role.
// 6. removeGuardian(address _guardian): Removes an address from the Guardian role.
// 7. transferOwnership(address _newOwner): Transfers protocol ownership.

// II. Reputation System (NexusPoints)
// 8. mintNexusPoints(address _user, uint256 _amount, bytes32 _reason): Internal function to award NexusPoints for positive actions.
// 9. burnNexusPoints(address _user, uint256 _amount, bytes32 _reason): Internal function to deduct NexusPoints for negative actions.
// 10. getNexusTier(address _user): Public view to get a user's current reputation tier.
// 11. initiateNexusDecay(address _user): Publicly callable to trigger reputation decay for a user if due.
// 12. slashForMisconduct(address _user): Owner/Guardian drastically slashes NexusPoints for severe violations.

// III. Resource Pool & Intent Matching
// 13. registerResourceType(bytes32 _resourceTypeName, uint256 _basePrice, uint256 _maxSupply, uint256 _maxDurationEpochs): Owner/DAO defines a new resource type.
// 14. addResourceToPool(bytes32 _resourceTypeName, uint256 _amount): Owner/DAO adds resources to the pool.
// 15. submitResourceIntent(bytes32 _resourceTypeName, uint256 _quantity, uint256 _durationEpochs, bytes _metadata): User submits a request for a resource.
// 16. fulfillResourceIntent(uint256 _intentId, address _fulfiller): Matches a pending intent with available resources.
// 17. releaseResource(uint256 _userResourceId): User returns a previously acquired resource.
// 18. queryAvailableResources(bytes32 _resourceTypeName): View function to check current available resources.

// IV. Adaptive Governance & Epoch Cycles
// 19. advanceEpoch(): Publicly callable to advance the protocol to the next epoch.
// 20. proposeDynamicParameterChange(bytes32 _paramKey, uint256 _newValue, uint256 _votingDurationEpochs): User proposes a new value for a dynamic protocol parameter (e.g., fee rate, decay rate).
// 21. castVoteOnProposal(uint256 _proposalId, bool _for): User votes on a proposal using NexusPoints.
// 22. executeApprovedProposal(uint256 _proposalId): Executes a proposal once it passes and voting ends.
// 23. submitDispute(uint256 _triggeringActionId, bytes _reason): User formally disputes a protocol action/decision.
// 24. resolveDispute(uint256 _disputeId, bool _approved, bytes _resolutionMemo): Guardians/DAO review and resolve submitted disputes.

// V. Advanced Features & External Integration
// 25. setOracleAddress(address _newOracle): Owner/DAO sets the address of the trusted oracle.
// 26. updateDynamicPricingModel(bytes32 _resourceTypeName, bytes _pricingModelData): Owner/DAO updates the pricing logic for a resource.
// 27. delegateIntentApproval(address _delegatee, bool _canApprove): Allows user to delegate intent approval.
// 28. revokeIntentDelegation(address _delegatee): Revokes delegation.
// 29. triggerCircuitBreaker(): Guardian-only function to immediately pause critical functions.
// 30. resetCircuitBreaker(): Guardian-only function to reset the circuit breaker.
// 31. getProtocolHealthScore(): Returns an aggregated metric for protocol health.

contract AetherNexus is Ownable, Pausable, ReentrancyGuard {
    // --- I. Core Infrastructure & Control ---

    uint256 public currentEpoch;
    uint256 public epochDuration; // In seconds
    uint256 public lastEpochAdvanceTime;

    address public oracleAddress;
    mapping(address => bool) public isGuardian;
    address[] public guardians; // To iterate guardians

    // Global Protocol Parameters (configurable by owner/DAO)
    mapping(bytes32 => uint256) public protocolParameters;

    enum ParameterKeys {
        NexusPointDecayRate, // Points decayed per epoch
        MinNexusPointsForProposal,
        MinNexusPointsForIntent,
        DisputeResolutionEpochs,
        ProposalVotingEpochs,
        CircuitBreakerThreshold
    }

    // --- II. Reputation System (NexusPoints) ---
    uint256[] public nexusTierThresholds; // e.g., [0, 100, 500, 2000] for T0, T1, T2, T3
    mapping(address => uint256) public nexusPoints;
    mapping(address => uint256) public lastNexusDecayEpoch;

    // --- III. Resource Pool & Intent Matching ---
    struct ResourceType {
        bytes32 name;
        uint256 basePrice; // Base price per unit per epoch
        uint256 maxSupply; // Total allowed supply of this resource type
        uint256 currentSupply; // Currently available units
        uint256 maxDurationEpochs; // Max epochs an intent can request this resource
        bytes pricingModelData; // Data to inform dynamic pricing model (e.g., multiplier, curve parameters)
        uint256 currentUtilized; // How many units are currently in use
    }
    mapping(bytes32 => ResourceType) public resourceTypes;
    bytes32[] public registeredResourceTypes; // For iteration

    enum IntentStatus { Pending, Fulfilled, Rejected, Cancelled }
    struct ResourceIntent {
        uint256 id;
        address user;
        bytes32 resourceTypeName;
        uint256 quantity;
        uint256 durationEpochs;
        uint256 submittedEpoch;
        uint256 fulfillmentEpoch; // Epoch when fulfilled
        uint256 expiresEpoch; // Epoch when resource must be returned or renewed
        IntentStatus status;
        bytes metadata;
        address delegatedApprover; // Address allowed to fulfill this intent on behalf of the user
        bool approvalDelegated;
    }
    uint256 public nextIntentId = 1;
    mapping(uint256 => ResourceIntent) public resourceIntents;
    mapping(address => mapping(address => bool)) public canDelegateApproveIntent; // user => delegatee => canApprove

    struct UserResourceHolding {
        uint256 id;
        address user;
        bytes32 resourceTypeName;
        uint256 quantity;
        uint256 acquiredEpoch;
        uint256 expiresEpoch;
        uint256 intentId; // Link to the original intent
    }
    uint256 public nextUserResourceId = 1;
    mapping(uint256 => UserResourceHolding) public userResourceHoldings;
    mapping(address => uint256[]) public userActiveHoldings; // user => array of userResourceHoldingIds

    // --- IV. Adaptive Governance & Epoch Cycles ---
    enum ProposalStatus { Pending, Active, Approved, Rejected, Executed, Expired }
    struct Proposal {
        uint256 id;
        address proposer;
        bytes32 paramKey;
        uint256 newValue;
        uint256 startEpoch;
        uint256 endEpoch;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // Check if user has voted
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;

    enum DisputeStatus { Open, ResolvedApproved, ResolvedRejected, Dismissed }
    struct Dispute {
        uint256 id;
        address submitter;
        uint256 triggeringActionId; // E.g., intentId, proposalId, userResourceHoldingId, NexusPoints update transaction hash
        bytes reason;
        uint256 submittedEpoch;
        uint256 resolutionEpoch;
        DisputeStatus status;
        bytes resolutionMemo;
    }
    uint256 public nextDisputeId = 1;
    mapping(uint256 => Dispute) public disputes;

    // --- V. Advanced Features & External Integration ---
    bool public circuitBreakerActive; // Controlled by Guardians for emergency stops

    // Events
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint224 oldValue, uint224 newValue);
    event GuardianAdded(address indexed newGuardian);
    event GuardianRemoved(address indexed guardian);
    event NexusPointsMinted(address indexed user, uint256 amount, bytes32 reason, uint256 newBalance);
    event NexusPointsBurned(address indexed user, uint256 amount, bytes32 reason, uint256 newBalance);
    event NexusPointsSlashed(address indexed user, uint256 oldBalance, uint256 newBalance);
    event NexusDecayInitiated(address indexed user, uint256 oldPoints, uint256 newPoints, uint256 epoch);
    event ResourceTypeRegistered(bytes32 indexed name, uint256 basePrice, uint256 maxSupply);
    event ResourcesAddedToPool(bytes32 indexed resourceTypeName, uint256 amount, uint256 newSupply);
    event ResourceIntentSubmitted(uint256 indexed intentId, address indexed user, bytes32 resourceTypeName, uint256 quantity, uint256 durationEpochs);
    event ResourceIntentFulfilled(uint256 indexed intentId, address indexed user, address indexed fulfiller, uint256 userResourceId, uint256 actualPrice);
    event ResourceReleased(uint256 indexed userResourceId, address indexed user, bytes32 resourceTypeName, uint256 quantity);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, bytes32 paramKey, uint256 newValue, uint256 startEpoch, uint256 endEpoch);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool _for, uint256 voteWeight);
    event ProposalExecuted(uint256 indexed proposalId, bytes32 paramKey, uint256 newValue);
    event DisputeSubmitted(uint256 indexed disputeId, address indexed submitter, uint256 triggeringActionId);
    event DisputeResolved(uint256 indexed disputeId, bool approved, bytes resolutionMemo);
    event OracleAddressUpdated(address indexed newOracle);
    event DynamicPricingModelUpdated(bytes32 indexed resourceTypeName, bytes pricingModelData);
    event IntentApprovalDelegated(address indexed delegator, address indexed delegatee, bool canApprove);
    event CircuitBreakerTriggered(address indexed by);
    event CircuitBreakerReset(address indexed by);
    event ProtocolHealthScoreReported(uint256 score, uint256 epoch);

    // Modifiers
    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "AetherNexus: Caller is not a guardian");
        _;
    }

    modifier onlyActive() {
        require(!paused(), "AetherNexus: Protocol is paused");
        require(!circuitBreakerActive, "AetherNexus: Circuit breaker active");
        _;
    }

    constructor(uint256 _initialEpochDuration, address _initialOracle, address[] memory _initialGuardians) Ownable(msg.sender) {
        require(_initialEpochDuration > 0, "AetherNexus: Epoch duration must be > 0");
        require(_initialOracle != address(0), "AetherNexus: Initial oracle cannot be zero address");

        epochDuration = _initialEpochDuration;
        currentEpoch = 1;
        lastEpochAdvanceTime = block.timestamp;
        oracleAddress = _initialOracle;

        // Set initial reputation tier thresholds
        nexusTierThresholds = [0, 100, 500, 2000, 10000]; // T0, T1, T2, T3, T4+

        // Set initial protocol parameters
        protocolParameters[bytes32(abi.encodePacked("NexusPointDecayRate"))] = 10; // 10 points per epoch decay
        protocolParameters[bytes32(abi.encodePacked("MinNexusPointsForProposal"))] = 100;
        protocolParameters[bytes32(abi.encodePacked("MinNexusPointsForIntent"))] = 50;
        protocolParameters[bytes32(abi.encodePacked("DisputeResolutionEpochs"))] = 3;
        protocolParameters[bytes32(abi.encodePacked("ProposalVotingEpochs"))] = 5;
        protocolParameters[bytes32(abi.encodePacked("CircuitBreakerThreshold"))] = 100; // Placeholder, might be dynamic based on oracle

        // Add initial guardians
        for (uint256 i = 0; i < _initialGuardians.length; i++) {
            require(_initialGuardians[i] != address(0), "AetherNexus: Guardian address cannot be zero");
            isGuardian[_initialGuardians[i]] = true;
            guardians.push(_initialGuardians[i]);
            emit GuardianAdded(_initialGuardians[i]);
        }
    }

    // --- I. Core Infrastructure & Control ---

    /**
     * @notice Updates a core protocol parameter. Only callable by the owner (or DAO if upgraded).
     * @param _paramName The keccak256 hash of the parameter name (e.g., "NexusPointDecayRate").
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) external onlyOwner {
        uint256 oldValue = protocolParameters[_paramName];
        protocolParameters[_paramName] = _newValue;
        emit ProtocolParameterUpdated(_paramName, uint224(oldValue), uint224(_newValue));
    }

    /**
     * @notice Emergency pause function. Can be called by owner or any guardian.
     *         Pauses critical functions of the protocol.
     */
    function pauseProtocol() external whenNotPaused {
        require(msg.sender == owner() || isGuardian[msg.sender], "AetherNexus: Only owner or guardian can pause");
        _pause();
    }

    /**
     * @notice Resumes protocol operations after a pause. Only callable by the owner or any guardian.
     */
    function unpauseProtocol() external onlyPaused {
        require(msg.sender == owner() || isGuardian[msg.sender], "AetherNexus: Only owner or guardian can unpause");
        _unpause();
    }

    /**
     * @notice Adds a new address to the Guardian role. Guardians can perform emergency actions like pausing.
     * @param _newGuardian The address to add as a guardian.
     */
    function addGuardian(address _newGuardian) external onlyOwner {
        require(_newGuardian != address(0), "AetherNexus: Guardian address cannot be zero");
        require(!isGuardian[_newGuardian], "AetherNexus: Address is already a guardian");
        isGuardian[_newGuardian] = true;
        guardians.push(_newGuardian);
        emit GuardianAdded(_newGuardian);
    }

    /**
     * @notice Removes an address from the Guardian role.
     * @param _guardian The address to remove from guardians.
     */
    function removeGuardian(address _guardian) external onlyOwner {
        require(_guardian != address(0), "AetherNexus: Guardian address cannot be zero");
        require(isGuardian[_guardian], "AetherNexus: Address is not a guardian");
        isGuardian[_guardian] = false;
        // Remove from array (inefficient for large arrays, but guardians expected to be few)
        for (uint256 i = 0; i < guardians.length; i++) {
            if (guardians[i] == _guardian) {
                guardians[i] = guardians[guardians.length - 1];
                guardians.pop();
                break;
            }
        }
        emit GuardianRemoved(_guardian);
    }

    /**
     * @notice Transfers ownership of the contract. Standard Ownable functionality.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public override onlyOwner {
        super.transferOwnership(_newOwner);
    }

    // --- II. Reputation System (NexusPoints) ---

    /**
     * @notice Awards NexusPoints to a user. This is an internal function, called by other protocol logic.
     * @param _user The address of the user to award points to.
     * @param _amount The amount of points to award.
     * @param _reason A bytes32 string describing the reason for minting points.
     */
    function mintNexusPoints(address _user, uint256 _amount, bytes32 _reason) internal {
        nexusPoints[_user] += _amount;
        lastNexusDecayEpoch[_user] = currentEpoch; // Reset decay clock
        emit NexusPointsMinted(_user, _amount, _reason, nexusPoints[_user]);
    }

    /**
     * @notice Deducts NexusPoints from a user. This is an internal function.
     * @param _user The address of the user to deduct points from.
     * @param _amount The amount of points to deduct.
     * @param _reason A bytes32 string describing the reason for burning points.
     */
    function burnNexusPoints(address _user, uint256 _amount, bytes32 _reason) internal {
        if (nexusPoints[_user] < _amount) {
            _amount = nexusPoints[_user]; // Prevent underflow
        }
        nexusPoints[_user] -= _amount;
        lastNexusDecayEpoch[_user] = currentEpoch; // Reset decay clock
        emit NexusPointsBurned(_user, _amount, _reason, nexusPoints[_user]);
    }

    /**
     * @notice Returns the NexusTier of a user based on their current NexusPoints.
     * @param _user The address of the user.
     * @return The integer representing the NexusTier (0 for lowest, higher for more points).
     */
    function getNexusTier(address _user) public view returns (uint256) {
        uint256 userPoints = nexusPoints[_user];
        for (uint256 i = nexusTierThresholds.length - 1; i > 0; i--) {
            if (userPoints >= nexusTierThresholds[i]) {
                return i;
            }
        }
        return 0; // Tier 0
    }

    /**
     * @notice Initiates the decay process for a user's NexusPoints if enough epochs have passed.
     *         Can be called by anyone to trigger decay, incentivizing maintenance of reputation.
     * @param _user The address whose NexusPoints should be decayed.
     */
    function initiateNexusDecay(address _user) external onlyActive nonReentrant {
        uint256 decayRate = protocolParameters[bytes32(abi.encodePacked("NexusPointDecayRate"))];
        if (decayRate == 0) return; // No decay configured

        uint256 epochsSinceLastDecay = currentEpoch - lastNexusDecayEpoch[_user];
        if (epochsSinceLastDecay > 0) {
            uint256 oldPoints = nexusPoints[_user];
            uint256 decayAmount = epochsSinceLastDecay * decayRate;
            if (oldPoints <= decayAmount) {
                nexusPoints[_user] = 0;
            } else {
                nexusPoints[_user] -= decayAmount;
            }
            lastNexusDecayEpoch[_user] = currentEpoch;
            emit NexusDecayInitiated(_user, oldPoints, nexusPoints[_user], currentEpoch);
        }
    }

    /**
     * @notice Drastically slashes a user's NexusPoints for severe misconduct.
     *         Callable by owner or a guardian.
     * @param _user The address of the user to penalize.
     */
    function slashForMisconduct(address _user) external onlyActive {
        require(msg.sender == owner() || isGuardian[msg.sender], "AetherNexus: Only owner or guardian can slash");
        uint256 oldPoints = nexusPoints[_user];
        // Example: Reduce to lowest tier threshold, or 0
        nexusPoints[_user] = nexusTierThresholds[0]; // Set to 0 points or lowest tier
        lastNexusDecayEpoch[_user] = currentEpoch; // Reset decay clock
        emit NexusPointsSlashed(_user, oldPoints, nexusPoints[_user]);
        // Consider triggering a dispute process here or requiring a dispute ID for slashing
    }

    // --- III. Resource Pool & Intent Matching ---

    /**
     * @notice Registers a new type of on-chain resource that the protocol can manage.
     *         Only callable by the owner.
     * @param _resourceTypeName The unique identifier for the resource type (e.g., "COMPUTE_CREDIT").
     * @param _basePrice The base price per unit of this resource per epoch.
     * @param _maxSupply The maximum total quantity of this resource type that can exist.
     * @param _maxDurationEpochs Maximum epochs an intent can request this resource.
     */
    function registerResourceType(
        bytes32 _resourceTypeName,
        uint256 _basePrice,
        uint256 _maxSupply,
        uint256 _maxDurationEpochs
    ) external onlyOwner {
        require(_resourceTypeName != bytes32(0), "AetherNexus: Resource type name cannot be empty");
        require(resourceTypes[_resourceTypeName].name == bytes32(0), "AetherNexus: Resource type already exists");
        require(_basePrice > 0, "AetherNexus: Base price must be positive");
        require(_maxSupply > 0, "AetherNexus: Max supply must be positive");
        require(_maxDurationEpochs > 0, "AetherNexus: Max duration must be positive");

        resourceTypes[_resourceTypeName] = ResourceType({
            name: _resourceTypeName,
            basePrice: _basePrice,
            maxSupply: _maxSupply,
            currentSupply: 0, // Initially empty
            maxDurationEpochs: _maxDurationEpochs,
            pricingModelData: "", // Default empty
            currentUtilized: 0
        });
        registeredResourceTypes.push(_resourceTypeName);
        emit ResourceTypeRegistered(_resourceTypeName, _basePrice, _maxSupply);
    }

    /**
     * @notice Adds units of a registered resource type to the protocol's available pool.
     *         Only callable by the owner.
     * @param _resourceTypeName The type of resource to add.
     * @param _amount The quantity of resources to add.
     */
    function addResourceToPool(bytes32 _resourceTypeName, uint256 _amount) external onlyOwner {
        ResourceType storage resource = resourceTypes[_resourceTypeName];
        require(resource.name != bytes32(0), "AetherNexus: Resource type not registered");
        require(_amount > 0, "AetherNexus: Amount must be positive");
        require(resource.currentSupply + _amount <= resource.maxSupply, "AetherNexus: Exceeds max supply");

        resource.currentSupply += _amount;
        emit ResourcesAddedToPool(_resourceTypeName, _amount, resource.currentSupply);
    }

    /**
     * @notice Allows a user to submit an intent to acquire a certain quantity of a resource.
     *         Requires a minimum NexusPoints balance.
     * @param _resourceTypeName The type of resource desired.
     * @param _quantity The quantity of units desired.
     * @param _durationEpochs The number of epochs for which the resource is desired.
     * @param _metadata Optional metadata describing the intent.
     * @return The ID of the submitted intent.
     */
    function submitResourceIntent(
        bytes32 _resourceTypeName,
        uint256 _quantity,
        uint256 _durationEpochs,
        bytes _metadata
    ) external onlyActive nonReentrant returns (uint256) {
        ResourceType storage resource = resourceTypes[_resourceTypeName];
        require(resource.name != bytes32(0), "AetherNexus: Resource type not registered");
        require(_quantity > 0, "AetherNexus: Quantity must be positive");
        require(_durationEpochs > 0 && _durationEpochs <= resource.maxDurationEpochs, "AetherNexus: Invalid duration");
        require(nexusPoints[msg.sender] >= protocolParameters[bytes32(abi.encodePacked("MinNexusPointsForIntent"))], "AetherNexus: Insufficient NexusPoints for intent");

        // Basic check for available supply, though actual fulfillment happens later
        require(resource.currentSupply >= _quantity, "AetherNexus: Insufficient resources currently available");

        uint256 intentId = nextIntentId++;
        resourceIntents[intentId] = ResourceIntent({
            id: intentId,
            user: msg.sender,
            resourceTypeName: _resourceTypeName,
            quantity: _quantity,
            durationEpochs: _durationEpochs,
            submittedEpoch: currentEpoch,
            fulfillmentEpoch: 0,
            expiresEpoch: 0,
            status: IntentStatus.Pending,
            metadata: _metadata,
            delegatedApprover: address(0), // No delegation initially
            approvalDelegated: false
        });

        emit ResourceIntentSubmitted(intentId, msg.sender, _resourceTypeName, _quantity, _durationEpochs);
        return intentId;
    }

    /**
     * @notice Fulfills a pending resource intent. Can be called by the user, a delegated approver, or the owner/guardian.
     *         This function performs the actual allocation and charges the cost (simulated here, could be ERC20 transfer).
     * @param _intentId The ID of the intent to fulfill.
     * @param _fulfiller The address performing the fulfillment. This is typically msg.sender.
     */
    function fulfillResourceIntent(uint256 _intentId, address _fulfiller) external onlyActive nonReentrant {
        ResourceIntent storage intent = resourceIntents[_intentId];
        require(intent.status == IntentStatus.Pending, "AetherNexus: Intent is not pending");
        require(
            msg.sender == intent.user || // User fulfills their own intent
            (intent.approvalDelegated && canDelegateApproveIntent[intent.user][msg.sender]) || // Delegated approver
            msg.sender == owner() || isGuardian[msg.sender], // Owner/Guardian can always fulfill
            "AetherNexus: Not authorized to fulfill this intent"
        );
        require(intent.user == _fulfiller || msg.sender == owner() || isGuardian[msg.sender] || (intent.approvalDelegated && canDelegateApproveIntent[intent.user][msg.sender]), "AetherNexus: Invalid fulfiller address or authorization");


        ResourceType storage resource = resourceTypes[intent.resourceTypeName];
        require(resource.name != bytes32(0), "AetherNexus: Resource type not registered");
        require(resource.currentSupply >= intent.quantity, "AetherNexus: Not enough resources available to fulfill");

        // Calculate dynamic price (simulated: base price * quantity * duration * reputation_multiplier * dynamic_factor)
        uint256 currentResourcePrice = _calculateDynamicResourcePrice(intent.resourceTypeName, intent.quantity, intent.durationEpochs, intent.user);
        // In a real scenario, funds would be transferred here. For this example, we simulate.
        // require(IERC20(paymentToken).transferFrom(intent.user, address(this), currentResourcePrice), "AetherNexus: Payment failed");

        resource.currentSupply -= intent.quantity;
        resource.currentUtilized += intent.quantity;

        intent.status = IntentStatus.Fulfilled;
        intent.fulfillmentEpoch = currentEpoch;
        intent.expiresEpoch = currentEpoch + intent.durationEpochs;
        intent.delegatedApprover = _fulfiller; // Record who approved/fulfilled

        // Award NexusPoints for successful engagement
        mintNexusPoints(intent.user, 10, bytes32(abi.encodePacked("IntentFulfillment")));

        uint256 userResourceId = nextUserResourceId++;
        userResourceHoldings[userResourceId] = UserResourceHolding({
            id: userResourceId,
            user: intent.user,
            resourceTypeName: intent.resourceTypeName,
            quantity: intent.quantity,
            acquiredEpoch: currentEpoch,
            expiresEpoch: intent.expiresEpoch,
            intentId: intent.id
        });
        userActiveHoldings[intent.user].push(userResourceId);

        emit ResourceIntentFulfilled(intent.id, intent.user, _fulfiller, userResourceId, currentResourcePrice);
    }

    /**
     * @notice Allows a user to release a previously acquired resource back to the pool.
     *         Can also be triggered by the system if a resource expires.
     * @param _userResourceId The ID of the user's resource holding to release.
     */
    function releaseResource(uint256 _userResourceId) external onlyActive nonReentrant {
        UserResourceHolding storage holding = userResourceHoldings[_userResourceId];
        require(holding.id != 0, "AetherNexus: Resource holding not found");
        require(holding.user == msg.sender, "AetherNexus: Not authorized to release this resource");

        ResourceType storage resource = resourceTypes[holding.resourceTypeName];
        require(resource.name != bytes32(0), "AetherNexus: Resource type not registered");

        // Prevent double release and ensure current utilization is tracked
        if (holding.quantity == 0) return; // Already released or invalid state

        resource.currentSupply += holding.quantity;
        resource.currentUtilized -= holding.quantity;

        emit ResourceReleased(holding.id, holding.user, holding.resourceTypeName, holding.quantity);

        // Remove from user's active holdings
        uint256[] storage holdingsList = userActiveHoldings[holding.user];
        for (uint256 i = 0; i < holdingsList.length; i++) {
            if (holdingsList[i] == _userResourceId) {
                holdingsList[i] = holdingsList[holdingsList.length - 1];
                holdingsList.pop();
                break;
            }
        }

        // Mark holding as released (clear quantity to prevent double release)
        holding.quantity = 0;
        // Consider burning NexusPoints for early release if it's detrimental, or minting for timely return.
        mintNexusPoints(holding.user, 5, bytes32(abi.encodePacked("ResourceReturned")));
    }

    /**
     * @notice Returns the current available quantity of a specific resource type.
     * @param _resourceTypeName The type of resource to query.
     * @return The currently available quantity.
     */
    function queryAvailableResources(bytes32 _resourceTypeName) external view returns (uint256) {
        ResourceType storage resource = resourceTypes[_resourceTypeName];
        require(resource.name != bytes32(0), "AetherNexus: Resource type not registered");
        return resource.currentSupply;
    }

    // --- IV. Adaptive Governance & Epoch Cycles ---

    /**
     * @notice Advances the protocol to the next epoch. Can be called by anyone once the epoch duration has passed.
     *         Triggers internal recalculations, reputation decay, and proposal processing.
     */
    function advanceEpoch() external onlyActive nonReentrant {
        require(block.timestamp >= lastEpochAdvanceTime + epochDuration, "AetherNexus: Epoch duration has not passed");

        currentEpoch++;
        lastEpochAdvanceTime = block.timestamp;

        // Process expired resource holdings (release them)
        // This would iterate through userActiveHoldings and call an internal _releaseResource function if expiresEpoch <= currentEpoch
        // For brevity, this complex iteration is omitted but would be critical for a full implementation.

        // Process proposals
        for (uint256 i = 1; i < nextProposalId; i++) {
            Proposal storage p = proposals[i];
            if (p.status == ProposalStatus.Active && currentEpoch >= p.endEpoch) {
                if (p.totalVotesFor > p.totalVotesAgainst && p.totalVotesFor > 0) {
                    p.status = ProposalStatus.Approved;
                    // Actual execution happens via executeApprovedProposal
                } else {
                    p.status = ProposalStatus.Rejected;
                }
            }
        }

        // Process disputes that have reached their resolution epoch
        // Similar to proposals, iterate through active disputes.

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /**
     * @notice Allows a user with sufficient NexusPoints to propose a change to a dynamic protocol parameter.
     * @param _paramKey The key of the parameter to change (e.g., "NexusPointDecayRate").
     * @param _newValue The new value proposed for the parameter.
     * @param _votingDurationEpochs The number of epochs for which the proposal will be open for voting.
     * @return The ID of the created proposal.
     */
    function proposeDynamicParameterChange(
        bytes32 _paramKey,
        uint256 _newValue,
        uint256 _votingDurationEpochs
    ) external onlyActive returns (uint256) {
        require(nexusPoints[msg.sender] >= protocolParameters[bytes32(abi.encodePacked("MinNexusPointsForProposal"))], "AetherNexus: Insufficient NexusPoints to propose");
        require(_votingDurationEpochs > 0, "AetherNexus: Voting duration must be positive");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            paramKey: _paramKey,
            newValue: _newValue,
            startEpoch: currentEpoch,
            endEpoch: currentEpoch + _votingDurationEpochs,
            totalVotesFor: 0,
            totalVotesAgainst: 0,
            status: ProposalStatus.Active
        });

        emit ProposalSubmitted(proposalId, msg.sender, _paramKey, _newValue, currentEpoch, currentEpoch + _votingDurationEpochs);
        return proposalId;
    }

    /**
     * @notice Allows a user to cast their vote on a pending proposal. Their NexusPoints determine vote weight.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True for a 'for' vote, false for an 'against' vote.
     */
    function castVoteOnProposal(uint256 _proposalId, bool _for) external onlyActive nonReentrant {
        Proposal storage p = proposals[_proposalId];
        require(p.status == ProposalStatus.Active, "AetherNexus: Proposal is not active");
        require(p.endEpoch > currentEpoch, "AetherNexus: Voting period has ended");
        require(!p.hasVoted[msg.sender], "AetherNexus: Already voted on this proposal");
        require(nexusPoints[msg.sender] > 0, "AetherNexus: No NexusPoints to cast vote");

        uint256 voteWeight = nexusPoints[msg.sender]; // Vote weight is proportional to NexusPoints

        if (_for) {
            p.totalVotesFor += voteWeight;
        } else {
            p.totalVotesAgainst += voteWeight;
        }
        p.hasVoted[msg.sender] = true;

        mintNexusPoints(msg.sender, 2, bytes32(abi.encodePacked("VoteCast"))); // Reward for participation
        emit VoteCast(_proposalId, msg.sender, _for, voteWeight);
    }

    /**
     * @notice Executes an approved proposal, applying the parameter change. Can be called by anyone.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeApprovedProposal(uint256 _proposalId) external onlyActive nonReentrant {
        Proposal storage p = proposals[_proposalId];
        require(p.status == ProposalStatus.Approved, "AetherNexus: Proposal is not approved");
        require(currentEpoch >= p.endEpoch, "AetherNexus: Voting period has not ended");

        protocolParameters[p.paramKey] = p.newValue;
        p.status = ProposalStatus.Executed;

        emit ProposalExecuted(p.id, p.paramKey, p.newValue);
    }

    /**
     * @notice Allows a user to submit a formal dispute against a protocol action or reputation change.
     * @param _triggeringActionId An ID related to the action being disputed (e.g., intent ID, proposal ID, or a custom ID).
     * @param _reason A detailed reason for the dispute.
     * @return The ID of the submitted dispute.
     */
    function submitDispute(uint256 _triggeringActionId, bytes _reason) external onlyActive returns (uint256) {
        require(_reason.length > 0, "AetherNexus: Dispute reason cannot be empty");

        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            submitter: msg.sender,
            triggeringActionId: _triggeringActionId,
            reason: _reason,
            submittedEpoch: currentEpoch,
            resolutionEpoch: 0,
            status: DisputeStatus.Open,
            resolutionMemo: ""
        });

        mintNexusPoints(msg.sender, 1, bytes32(abi.encodePacked("DisputeSubmitted"))); // Small reward for vigilance
        emit DisputeSubmitted(disputeId, msg.sender, _triggeringActionId);
        return disputeId;
    }

    /**
     * @notice Allows Guardians to resolve a submitted dispute. Their decision can affect NexusPoints.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _approved True if the dispute is deemed valid (submitter is right), false otherwise.
     * @param _resolutionMemo A memo explaining the resolution.
     */
    function resolveDispute(uint256 _disputeId, bool _approved, bytes _resolutionMemo) external onlyGuardian onlyActive nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "AetherNexus: Dispute is not open");
        require(_resolutionMemo.length > 0, "AetherNexus: Resolution memo cannot be empty");

        dispute.resolutionEpoch = currentEpoch;
        dispute.resolutionMemo = _resolutionMemo;

        if (_approved) {
            dispute.status = DisputeStatus.ResolvedApproved;
            mintNexusPoints(dispute.submitter, 20, bytes32(abi.encodePacked("DisputeApproved"))); // Reward for valid dispute
            // Here, logic to reverse/correct the disputed action would be implemented.
        } else {
            dispute.status = DisputeStatus.ResolvedRejected;
            burnNexusPoints(dispute.submitter, 10, bytes32(abi.encodePacked("DisputeRejected"))); // Penalty for invalid dispute
        }
        emit DisputeResolved(dispute.id, _approved, _resolutionMemo);
    }

    // --- V. Advanced Features & External Integration ---

    /**
     * @notice Sets the address of the trusted oracle. Only callable by the owner.
     * @param _newOracle The address of the new oracle contract.
     */
    function setOracleAddress(address _newOracle) external onlyOwner {
        require(_newOracle != address(0), "AetherNexus: Oracle address cannot be zero");
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    /**
     * @notice Updates the dynamic pricing model data for a specific resource type.
     *         This data can be used by an internal `_calculateDynamicResourcePrice` function.
     *         Only callable by the owner.
     * @param _resourceTypeName The type of resource whose pricing model is being updated.
     * @param _pricingModelData New data for the pricing model (e.g., encoded parameters, function selector).
     */
    function updateDynamicPricingModel(bytes32 _resourceTypeName, bytes _pricingModelData) external onlyOwner {
        ResourceType storage resource = resourceTypes[_resourceTypeName];
        require(resource.name != bytes32(0), "AetherNexus: Resource type not registered");
        resource.pricingModelData = _pricingModelData;
        emit DynamicPricingModelUpdated(_resourceTypeName, _pricingModelData);
    }

    /**
     * @notice Allows a user to delegate the authority to approve/fulfill their resource intents
     *         to another address. This provides flexibility for automated systems or trusted agents.
     * @param _delegatee The address to delegate approval authority to.
     * @param _canApprove True to grant approval, false to revoke.
     */
    function delegateIntentApproval(address _delegatee, bool _canApprove) external onlyActive {
        require(_delegatee != address(0), "AetherNexus: Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "AetherNexus: Cannot delegate to self");

        canDelegateApproveIntent[msg.sender][_delegatee] = _canApprove;
        emit IntentApprovalDelegated(msg.sender, _delegatee, _canApprove);
    }

    /**
     * @notice Revokes a previously granted intent approval delegation.
     * @param _delegatee The address whose delegation is to be revoked.
     */
    function revokeIntentDelegation(address _delegatee) external onlyActive {
        require(canDelegateApproveIntent[msg.sender][_delegatee], "AetherNexus: No active delegation to revoke");
        canDelegateApproveIntent[msg.sender][_delegatee] = false;
        emit IntentApprovalDelegated(msg.sender, _delegatee, false);
    }

    /**
     * @notice Triggers an immediate circuit breaker, pausing all critical functions regardless of `paused()` state.
     *         Only callable by a Guardian, intended for severe, unforeseen issues (e.g., oracle compromise).
     */
    function triggerCircuitBreaker() external onlyGuardian {
        require(!circuitBreakerActive, "AetherNexus: Circuit breaker already active");
        circuitBreakerActive = true;
        emit CircuitBreakerTriggered(msg.sender);
    }

    /**
     * @notice Resets the circuit breaker, allowing critical functions to resume (if not paused by `Pausable`).
     *         Only callable by a Guardian.
     */
    function resetCircuitBreaker() external onlyGuardian {
        require(circuitBreakerActive, "AetherNexus: Circuit breaker not active");
        circuitBreakerActive = false;
        emit CircuitBreakerReset(msg.sender);
    }

    /**
     * @notice Calculates and returns an aggregated metric representing the protocol's overall operational health.
     *         This score can be based on factors like resource utilization, dispute rate, reputation distribution,
     *         oracle data freshness, etc. (Simplified for example).
     * @return A health score (e.g., out of 1000).
     */
    function getProtocolHealthScore() external view returns (uint256) {
        // Example simplified calculation:
        // Max health = 1000
        uint256 health = 1000;

        // Factor 1: Resource Utilization (penalize for very high or very low utilization)
        uint256 totalResources = 0;
        uint256 totalUtilized = 0;
        for (uint256 i = 0; i < registeredResourceTypes.length; i++) {
            ResourceType storage r = resourceTypes[registeredResourceTypes[i]];
            totalResources += r.maxSupply;
            totalUtilized += r.currentUtilized;
        }

        if (totalResources > 0) {
            uint256 utilizationPercentage = (totalUtilized * 1000) / totalResources; // Scale to 1000
            // Ideal utilization around 70%
            if (utilizationPercentage < 500) { // Underutilized
                health -= (500 - utilizationPercentage) / 10;
            } else if (utilizationPercentage > 900) { // Overutilized/scarce
                health -= (utilizationPercentage - 900) / 5;
            }
        }

        // Factor 2: Open Disputes (penalize for many open disputes)
        uint256 openDisputesCount = 0;
        for (uint256 i = 1; i < nextDisputeId; i++) {
            if (disputes[i].status == DisputeStatus.Open) {
                openDisputesCount++;
            }
        }
        health -= (openDisputesCount * 10); // Each open dispute reduces health by 10 points

        // Ensure health doesn't go below 0
        if (health < 0) health = 0;
        if (health > 1000) health = 1000; // Cap at max

        emit ProtocolHealthScoreReported(health, currentEpoch);
        return health;
    }

    // --- Internal Helpers ---

    /**
     * @notice Internal function to calculate the dynamic price of a resource.
     *         This logic can be highly complex, involving oracle data, utilization, reputation, etc.
     *         For this example, it's a simplified version.
     * @param _resourceTypeName The type of resource.
     * @param _quantity The quantity requested.
     * @param _durationEpochs The duration in epochs.
     * @param _user The user requesting the resource.
     * @return The calculated total price.
     */
    function _calculateDynamicResourcePrice(
        bytes32 _resourceTypeName,
        uint256 _quantity,
        uint256 _durationEpochs,
        address _user
    ) internal view returns (uint256) {
        ResourceType storage resource = resourceTypes[_resourceTypeName];
        uint256 baseCost = resource.basePrice * _quantity * _durationEpochs;

        // Example: Dynamic pricing based on utilization and reputation
        uint256 utilizationRatio = (resource.currentUtilized * 1000) / resource.maxSupply; // Scale to 1000

        // High utilization -> higher price
        uint256 utilizationMultiplier = 1e18; // 1.0
        if (utilizationRatio > 800) { // > 80% utilized
            utilizationMultiplier = 1e18 + (utilizationRatio - 800) * 5e15; // +0.5% for every 1% over 80
        } else if (utilizationRatio < 200) { // < 20% utilized
            utilizationMultiplier = 1e18 - (200 - utilizationRatio) * 2e15; // -0.2% for every 1% under 20
        }

        // Reputation bonus/penalty (higher tier -> lower price)
        uint256 userTier = getNexusTier(_user);
        uint256 reputationMultiplier = 1e18;
        if (userTier == 0) reputationMultiplier = 105e16; // 5% penalty for lowest tier
        else if (userTier >= 3) reputationMultiplier = 95e16; // 5% bonus for high tier

        // Get external factor from oracle (e.g., network congestion, market demand index)
        // This is a placeholder; requires actual oracle integration
        // uint256 externalFactor = IOracle(oracleAddress).getLatestPrice("NETWORK_CONGESTION");
        uint256 externalFactor = 1e18; // Assume 1.0 for now

        return (baseCost * utilizationMultiplier / 1e18 * reputationMultiplier / 1e18 * externalFactor / 1e18);
    }
}
```