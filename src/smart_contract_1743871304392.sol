```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Influence System (DRIS)
 * @author Bard (Example Smart Contract)
 * @notice This smart contract implements a Dynamic Reputation and Influence System (DRIS).
 * It allows entities (addresses) to earn reputation based on various on-chain and off-chain activities
 * (simulated here). Reputation is dynamic, influence is derived from reputation, and the system
 * includes features for delegation, endorsements, disputes, and customizable reputation metrics.
 * It is designed to be a foundational layer for decentralized governance, community management,
 * or any application requiring a nuanced and evolving reputation framework.
 *
 * ## Function Summary:
 *
 * **Reputation Management:**
 * - `updateReputation(address entity, int256 change, string memory reason)`: Updates the reputation score of an entity.
 * - `getReputation(address entity)`: Retrieves the current reputation score of an entity.
 * - `getReputationLevel(address entity)`: Retrieves the reputation level of an entity based on their score.
 * - `defineReputationLevel(uint256 levelThreshold, string memory levelName)`: Defines a new reputation level and its threshold.
 * - `getActionWeight(string memory actionName)`: Retrieves the weight associated with a specific action type.
 * - `setActionWeight(string memory actionName, int256 weight)`: Sets or updates the weight for a specific action type.
 * - `setBaseReputation(address entity, uint256 baseScore)`: Sets the base reputation score for a new or existing entity.
 *
 * **Influence and Delegation:**
 * - `delegateInfluence(address delegatee, address targetEntity)`: Allows an entity to delegate their influence to another entity for a specific target.
 * - `revokeInfluenceDelegation(address delegatee, address targetEntity)`: Revokes influence delegation.
 * - `getDelegatedInfluence(address targetEntity)`: Retrieves the aggregated influence delegated to a target entity.
 * - `endorseEntity(address endorser, address endorsedEntity, string memory reason)`: Allows a highly reputable entity to endorse another entity.
 * - `revokeEndorsement(address endorser, address endorsedEntity)`: Revokes an endorsement.
 * - `getEndorsements(address endorsedEntity)`: Retrieves the list of entities endorsing a specific entity.
 *
 * **Dispute and Review Mechanism:**
 * - `initiateReputationDispute(address targetEntity, string memory reason)`: Allows an entity to initiate a dispute against a reputation update.
 * - `resolveReputationDispute(uint256 disputeId, bool isUpheld, int256 reputationChange)`: Allows the contract owner to resolve a reputation dispute.
 * - `getDisputeDetails(uint256 disputeId)`: Retrieves details of a specific reputation dispute.
 *
 * **Utility and Admin Functions:**
 * - `pauseContract()`: Pauses the contract, restricting reputation updates and certain actions.
 * - `unpauseContract()`: Unpauses the contract, restoring normal functionality.
 * - `isContractPaused()`: Checks if the contract is currently paused.
 * - `transferOwnership(address newOwner)`: Transfers contract ownership to a new address.
 * - `renounceOwnership()`: Renounces contract ownership.
 * - `getVersion()`: Returns the contract version.
 * - `getContractName()`: Returns the contract name.
 */
contract DynamicReputationInfluenceSystem {
    // --- State Variables ---

    string public contractName = "DynamicReputationInfluenceSystem";
    string public version = "1.0.0";

    address public owner;
    bool public paused;

    // Reputation Scores for entities (address => reputation score)
    mapping(address => int256) public reputationScores;

    // Reputation Levels (level threshold => level name)
    mapping(uint256 => string) public reputationLevels;
    uint256[] public levelThresholds; // Ordered thresholds for level lookup

    // Action Weights (action name => reputation weight)
    mapping(string => int256) public actionWeights;

    // Influence Delegation (delegatee => (targetEntity => isDelegating))
    mapping(address => mapping(address => bool)) public influenceDelegations;

    // Endorsements (endorsedEntity => endorsers[])
    mapping(address => address[]) public endorsements;

    // Reputation Disputes (dispute ID => Dispute struct)
    uint256 public disputeCounter;
    mapping(uint256 => Dispute) public disputes;
    struct Dispute {
        address targetEntity;
        string reason;
        bool resolved;
        bool upheld;
        int256 reputationChange;
        address initiator;
        uint256 timestamp;
    }

    // --- Events ---

    event ReputationUpdated(address entity, int256 newReputation, string reason);
    event ReputationLevelDefined(uint256 threshold, string levelName);
    event ActionWeightSet(string actionName, int256 weight);
    event InfluenceDelegated(address delegatee, address targetEntity);
    event InfluenceDelegationRevoked(address delegatee, address targetEntity);
    event EntityEndorsed(address endorser, address endorsedEntity, string reason);
    event EndorsementRevoked(address endorser, address endorsedEntity);
    event ReputationDisputeInitiated(uint256 disputeId, address targetEntity, string reason, address initiator);
    event ReputationDisputeResolved(uint256 disputeId, bool isUpheld, int256 reputationChange, address resolver);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        paused = false;

        // Initialize default reputation levels
        defineReputationLevel(100, "Beginner");
        defineReputationLevel(500, "Intermediate");
        defineReputationLevel(1000, "Advanced");
        defineReputationLevel(5000, "Expert");

        // Initialize default action weights (example actions)
        setActionWeight("ProjectContribution", 10);
        setActionWeight("CommunityParticipation", 5);
        setActionWeight("PositiveFeedback", 2);
        setActionWeight("NegativeFeedback", -5);
        setActionWeight("DisputeResolutionSuccess", 20);
        setActionWeight("DisputeResolutionFailure", -10);
    }

    // --- Reputation Management Functions ---

    /**
     * @notice Updates the reputation score of an entity.
     * @param entity The address of the entity whose reputation is being updated.
     * @param change The amount to change the reputation score by (positive or negative).
     * @param reason A descriptive reason for the reputation update.
     */
    function updateReputation(address entity, int256 change, string memory reason) public whenNotPaused {
        reputationScores[entity] += change;
        emit ReputationUpdated(entity, reputationScores[entity], reason);
    }

    /**
     * @notice Retrieves the current reputation score of an entity.
     * @param entity The address of the entity.
     * @return The reputation score of the entity.
     */
    function getReputation(address entity) public view returns (int256) {
        return reputationScores[entity];
    }

    /**
     * @notice Retrieves the reputation level of an entity based on their score.
     * @param entity The address of the entity.
     * @return The reputation level name (string). Returns "Unranked" if no level is reached.
     */
    function getReputationLevel(address entity) public view returns (string memory) {
        int256 score = reputationScores[entity];
        for (uint256 i = 0; i < levelThresholds.length; i++) {
            if (uint256(score) >= levelThresholds[i]) {
                return reputationLevels[levelThresholds[i]];
            }
        }
        return "Unranked"; // Default if score is below all thresholds
    }

    /**
     * @notice Defines a new reputation level and its threshold. Only owner can call.
     * @param levelThreshold The score threshold required to reach this level.
     * @param levelName The name of the reputation level.
     */
    function defineReputationLevel(uint256 levelThreshold, string memory levelName) public onlyOwner {
        require(bytes(levelName).length > 0, "Level name cannot be empty.");
        reputationLevels[levelThreshold] = levelName;

        // Maintain sorted levelThresholds array for efficient level lookup in getReputationLevel
        bool inserted = false;
        for (uint256 i = 0; i < levelThresholds.length; i++) {
            if (levelThreshold < levelThresholds[i]) {
                levelThresholds.splice(i, 0, levelThreshold);
                inserted = true;
                break;
            }
        }
        if (!inserted) {
            levelThresholds.push(levelThreshold);
        }

        emit ReputationLevelDefined(levelThreshold, levelName);
    }

    /**
     * @notice Retrieves the weight associated with a specific action type.
     * @param actionName The name of the action.
     * @return The reputation weight for the action.
     */
    function getActionWeight(string memory actionName) public view returns (int256) {
        return actionWeights[actionName];
    }

    /**
     * @notice Sets or updates the weight for a specific action type. Only owner can call.
     * @param actionName The name of the action.
     * @param weight The reputation weight to assign to the action.
     */
    function setActionWeight(string memory actionName, int256 weight) public onlyOwner {
        actionWeights[actionName] = weight;
        emit ActionWeightSet(actionName, weight);
    }

    /**
     * @notice Sets the base reputation score for a new or existing entity. Only owner can call.
     * @param entity The address of the entity.
     * @param baseScore The base reputation score to set.
     */
    function setBaseReputation(address entity, uint256 baseScore) public onlyOwner {
        reputationScores[entity] = int256(baseScore);
        emit ReputationUpdated(entity, reputationScores[entity], "Base reputation set by owner");
    }


    // --- Influence and Delegation Functions ---

    /**
     * @notice Allows an entity to delegate their influence to another entity for a specific target.
     *         Influence delegation means the delegatee's reputation towards the target entity is increased
     *         by a portion of the delegator's reputation. (Simplified concept for this example)
     * @param delegatee The address receiving the delegated influence.
     * @param targetEntity The address towards which the influence is being delegated.
     */
    function delegateInfluence(address delegatee, address targetEntity) public whenNotPaused {
        require(delegatee != address(0) && targetEntity != address(0), "Invalid address.");
        require(delegatee != msg.sender, "Cannot delegate influence to yourself.");
        influenceDelegations[msg.sender][targetEntity] = true; // Mark delegation
        emit InfluenceDelegated(delegatee, targetEntity);
    }

    /**
     * @notice Revokes influence delegation.
     * @param delegatee The address whose delegated influence is being revoked.
     * @param targetEntity The target entity for the delegation revocation.
     */
    function revokeInfluenceDelegation(address delegatee, address targetEntity) public whenNotPaused {
        require(delegatee != address(0) && targetEntity != address(0), "Invalid address.");
        require(delegatee != msg.sender, "Cannot revoke delegation from yourself.");
        influenceDelegations[msg.sender][targetEntity] = false; // Remove delegation mark
        emit InfluenceDelegationRevoked(delegatee, targetEntity);
    }

    /**
     * @notice Retrieves the aggregated influence delegated to a target entity.
     *         In this simplified example, it returns the sum of reputation scores of all delegators.
     *         In a real-world scenario, influence calculation could be more complex.
     * @param targetEntity The entity to check delegated influence for.
     * @return The aggregated delegated influence (sum of reputation scores).
     */
    function getDelegatedInfluence(address targetEntity) public view returns (uint256) {
        uint256 totalDelegatedInfluence = 0;
        for (address delegator in influenceDelegations) {
            if (influenceDelegations[delegator][targetEntity]) {
                totalDelegatedInfluence += uint256(reputationScores[delegator]); // Simplified influence calculation
            }
        }
        return totalDelegatedInfluence;
    }

    /**
     * @notice Allows a highly reputable entity to endorse another entity.
     *         Endorsements can be used as a signal of trust or quality.
     * @param endorser The address of the entity doing the endorsement. Must be at least "Expert" level.
     * @param endorsedEntity The address of the entity being endorsed.
     * @param reason A reason for the endorsement.
     */
    function endorseEntity(address endorser, address endorsedEntity, string memory reason) public whenNotPaused {
        require(getReputationLevel(msg.sender) == "Expert", "Only Expert level or higher can endorse."); // Example level check
        require(endorser == msg.sender, "Endorser must be the sender.");
        require(endorsedEntity != address(0) && endorsedEntity != endorser, "Invalid endorsed entity.");

        // Prevent duplicate endorsements from the same endorser
        bool alreadyEndorsed = false;
        for (uint256 i = 0; i < endorsements[endorsedEntity].length; i++) {
            if (endorsements[endorsedEntity][i] == endorser) {
                alreadyEndorsed = true;
                break;
            }
        }
        require(!alreadyEndorsed, "Already endorsed this entity.");

        endorsements[endorsedEntity].push(endorser);
        emit EntityEndorsed(endorser, endorsedEntity, reason);
    }

    /**
     * @notice Revokes an endorsement. Only the endorser can revoke their endorsement.
     * @param endorser The address revoking the endorsement.
     * @param endorsedEntity The address whose endorsement is being revoked.
     */
    function revokeEndorsement(address endorser, address endorsedEntity) public whenNotPaused {
        require(endorser == msg.sender, "Only endorser can revoke their endorsement.");
        require(endorsedEntity != address(0) && endorsedEntity != endorser, "Invalid endorsed entity.");

        address[] storage currentEndorsements = endorsements[endorsedEntity];
        for (uint256 i = 0; i < currentEndorsements.length; i++) {
            if (currentEndorsements[i] == endorser) {
                currentEndorsements.splice(i, 1); // Remove from array
                emit EndorsementRevoked(endorser, endorsedEntity);
                return;
            }
        }
        revert("Endorsement not found."); // If endorsement was not found
    }

    /**
     * @notice Retrieves the list of entities endorsing a specific entity.
     * @param endorsedEntity The address of the entity.
     * @return An array of addresses that are endorsing the entity.
     */
    function getEndorsements(address endorsedEntity) public view returns (address[] memory) {
        return endorsements[endorsedEntity];
    }


    // --- Dispute and Review Mechanism ---

    /**
     * @notice Allows an entity to initiate a dispute against a reputation update.
     * @param targetEntity The entity whose reputation update is being disputed (should be msg.sender in most cases).
     * @param reason The reason for initiating the dispute.
     */
    function initiateReputationDispute(address targetEntity, string memory reason) public whenNotPaused {
        require(targetEntity == msg.sender, "Dispute must be initiated by the target entity."); // Example: entity disputes their own reputation
        disputeCounter++;
        disputes[disputeCounter] = Dispute({
            targetEntity: targetEntity,
            reason: reason,
            resolved: false,
            upheld: false,
            reputationChange: 0, // Initially 0, updated upon resolution
            initiator: msg.sender,
            timestamp: block.timestamp
        });
        emit ReputationDisputeInitiated(disputeCounter, targetEntity, reason, msg.sender);
    }

    /**
     * @notice Allows the contract owner to resolve a reputation dispute. Only owner can call.
     * @param disputeId The ID of the dispute to resolve.
     * @param isUpheld True if the dispute is upheld (reputation change was incorrect), false otherwise.
     * @param reputationChange The reputation change to apply if the dispute is upheld (can be 0 or a correction).
     */
    function resolveReputationDispute(uint256 disputeId, bool isUpheld, int256 reputationChange) public onlyOwner whenNotPaused {
        require(disputes[disputeId].resolved == false, "Dispute already resolved.");
        Dispute storage dispute = disputes[disputeId];
        dispute.resolved = true;
        dispute.upheld = isUpheld;
        dispute.reputationChange = reputationChange;

        if (isUpheld) {
            updateReputation(dispute.targetEntity, reputationChange, "Reputation dispute resolved - correction");
        }
        emit ReputationDisputeResolved(disputeId, isUpheld, reputationChange, msg.sender);
    }

    /**
     * @notice Retrieves details of a specific reputation dispute.
     * @param disputeId The ID of the dispute.
     * @return Dispute struct containing dispute details.
     */
    function getDisputeDetails(uint256 disputeId) public view returns (Dispute memory) {
        require(disputeId > 0 && disputeId <= disputeCounter, "Invalid dispute ID.");
        return disputes[disputeId];
    }


    // --- Utility and Admin Functions ---

    /**
     * @notice Pauses the contract. Only owner can call.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @notice Unpauses the contract. Only owner can call.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @notice Checks if the contract is currently paused.
     * @return True if paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @notice Transfers ownership of the contract to a new address. Only owner can call.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero.");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @notice Renounces ownership of the contract. Contract will be ownerless after this. Only owner can call.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /**
     * @notice Returns the contract version.
     * @return The contract version string.
     */
    function getVersion() public view returns (string memory) {
        return version;
    }

    /**
     * @notice Returns the contract name.
     * @return The contract name string.
     */
    function getContractName() public view returns (string memory) {
        return contractName;
    }

    // --- Fallback and Receive (Optional, for demonstration - not critical for DRIS functionality) ---
    receive() external payable {}
    fallback() external payable {}
}
```