Here's a smart contract written in Solidity, incorporating advanced concepts, creative functions, and aiming for uniqueness.

---

## CognitoNexus Smart Contract

The `CognitoNexus` protocol is a decentralized platform designed for **on-chain skill validation, reputation building, and collaborative knowledge synthesis**. It leverages **Soulbound Tokens (SBTs)** as dynamic identity nodes, a unique **"Cognitive Challenge" system** for community-driven data validation and insight generation, and a **delegated validation mechanism**. Users earn reputation and skill points that directly influence the evolution of their dynamic `CognitoNode` NFT.

**Core Concepts:**

*   **CognitoNode (Soulbound Token):** A non-transferable NFT representing a user's on-chain persona, skill profile, and reputation. Its metadata dynamically evolves based on the user's activities within the protocol.
*   **Skill & Assertion Protocol:** Users can claim specific skills, provide verifiable evidence, and have these assertions validated by the community through staked challenges.
*   **Reputation & Skill Point System:** `reputationScore` reflects overall trustworthiness, while `skillPoints` track proficiency in specific domains. Both are dynamically adjusted by protocol interactions.
*   **Cognitive Challenges:** Decentralized mini-prediction markets or validation games. Users stake the native `SynapseToken` to vote on outcomes, validate assertions, or provide solutions to complex questions, earning rewards for correct participation.
*   **Delegated Validation Power:** Users can delegate a portion of their earned skill-specific validation power to other trusted `CognitoNodes`, fostering a network of expertise.
*   **Synergy Pools:** Collaborative groups formed by `CognitoNodes` that collectively meet specific skill requirements, facilitating decentralized project execution.
*   **Synapse Token (SYN):** The native utility token used for staking in challenges, asserting skills, earning rewards, and potentially future governance.

---

### Contract Outline & Function Summary

**I. CognitoNode (Soulbound Identity) Management**
*   `createCognitoNode()`: Mints a new soulbound `CognitoNode` (SBT) for the caller.
*   `updateNodeMetadata(string _uri)`: Allows the node owner to update their `CognitoNode`'s descriptive URI, potentially reflecting external profile data.
*   `revokeCognitoNode()`: Allows a user to irrevocably burn their `CognitoNode`, removing their on-chain persona.
*   `getNodeReputation(uint256 _nodeId)`: Retrieves the current reputation score of a `CognitoNode`.
*   `getNodeSkillPoints(uint256 _nodeId, bytes32 _topicHash)`: Retrieves skill points for a specific topic of a `CognitoNode`.

**II. Skill & Assertion Protocol**
*   `registerSkillTopic(string _topicName)`: Protocol admin/DAO registers new skill categories.
*   `assertSkill(bytes32 _topicHash, string _evidenceUri)`: Allows a `CognitoNode` to assert a skill, providing a URI to verifiable evidence. Requires a SYN token stake.
*   `proposeAssertionChallenge(uint256 _assertionId, uint256 _stakeAmount, uint256 _duration)`: Initiates a `CognitiveChallenge` specifically to validate or dispute an existing skill assertion.
*   `supportAssertion(uint256 _assertionId, uint256 _stakeAmount)`: Stakes SYN tokens to express support for an assertion within its challenge period.
*   `disputeAssertion(uint256 _assertionId, uint256 _stakeAmount)`: Stakes SYN tokens to express a dispute against an assertion within its challenge period.
*   `resolveAssertionChallenge(uint256 _assertionChallengeId)`: Finalizes an assertion challenge, updating reputation and skill points based on the outcome.
*   `getAssertionDetails(uint256 _assertionId)`: Retrieves comprehensive details about a specific skill assertion.

**III. Cognitive Challenge System**
*   `createCognitiveChallenge(string _questionUri, bytes32[] _answerOptionHashes, uint256 _stakeAmount, uint256 _duration)`: Initiates a general `CognitiveChallenge` for knowledge synthesis or insight generation.
*   `participateInChallenge(uint256 _challengeId, bytes32 _chosenAnswerHash, uint256 _stakeAmount)`: Allows a `CognitoNode` to participate in a challenge by staking on a chosen answer.
*   `revealChallengeOutcome(uint256 _challengeId, bytes32 _correctAnswerHash, string _oracleProofUri)`: Admin/trusted oracle reveals the true outcome for a general cognitive challenge. (Could be replaced by another nested challenge for full decentralization).
*   `distributeChallengeRewards(uint256 _challengeId)`: Distributes staked SYN tokens and reputation/skill rewards to correct participants.
*   `claimChallengeWinnings(uint256 _challengeId)`: Allows participants to withdraw their earned SYN tokens after a challenge is resolved.
*   `getChallengeStatus(uint256 _challengeId)`: Retrieves the current status and details of a cognitive challenge.

**IV. Reputation & Reward Mechanics (Internal & Admin)**
*   `_rewardNode(uint256 _nodeId, uint256 _reputationGain, bytes32 _topicHash, uint256 _skillPointGain)`: Internal function to update a node's reputation and skill points.
*   `_penalizeNode(uint256 _nodeId, uint256 _reputationLoss, bytes32 _reasonHash)`: Internal function to penalize a node.
*   `withdrawProtocolFees(address _to, uint256 _amount)`: Allows the protocol owner/DAO to withdraw accumulated SYN fees.
*   `updateProtocolParameter(bytes32 _paramName, uint256 _newValue)`: Allows admin/DAO to adjust protocol constants (e.g., min stake, challenge durations).

**V. Delegated Validation & Synergy Pools**
*   `delegateValidationPower(uint256 _delegateeNodeId, bytes32 _topicHash, uint256 _powerPercentage)`: Allows a `CognitoNode` to delegate a percentage of its skill-specific validation power to another node.
*   `revokeDelegation(uint256 _delegateeNodeId, bytes32 _topicHash)`: Revokes a previously made delegation.
*   `getDelegatedPower(uint256 _nodeId, bytes32 _topicHash)`: Calculates the total effective validation power of a node for a given skill topic.
*   `createSynergyPool(bytes32[] _requiredSkillTopics, string _poolName, address _adminAddress)`: Creates a new collaborative pool requiring specific aggregated skill sets from its members.
*   `joinSynergyPool(uint256 _poolId)`: Allows a `CognitoNode` to join a `SynergyPool` if it meets the skill requirements.
*   `submitPoolDeliverable(uint256 _poolId, string _deliverableUri)`: A `SynergyPool` member submits a URI pointing to a completed deliverable or milestone.

**VI. Protocol Configuration & Utility**
*   `setSynapseTokenAddress(address _synapseToken)`: Admin function to set the address of the `SynapseToken` contract.
*   `pauseProtocol()`: Admin function to pause core protocol functionalities in case of an emergency.
*   `unpauseProtocol()`: Admin function to unpause the protocol.
*   `isNodeOwner(address _addr, uint256 _nodeId)`: Utility function to check if an address owns a specific `CognitoNode`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Dummy Synapse Token for demonstration
// In a real scenario, this would be a separate, deployed ERC20 contract.
contract SynapseToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Synapse Token", "SYN") {
        _mint(msg.sender, initialSupply);
    }
}

contract CognitoNexus is ERC721, Ownable, Pausable {
    using SafeMath for uint256;

    // --- State Variables ---

    // Synapse Token (SYN) for staking and rewards
    IERC20 public synapseToken;

    // CognitoNode (SBT) Details
    uint256 private _nextTokenId;
    mapping(uint256 => uint256) public nodeReputation; // nodeId => reputationScore
    mapping(uint256 => mapping(bytes32 => uint256)) public nodeSkillPoints; // nodeId => topicHash => skillPoints
    mapping(address => uint256) public addressToNodeId; // ownerAddress => nodeId (0 if not owned)
    mapping(uint256 => bool) public isNodeRevoked; // nodeId => true if revoked

    // Skill Topics
    mapping(bytes32 => string) public skillTopicNames; // topicHash => topicName
    mapping(bytes32 => bool) public isSkillTopicRegistered; // topicHash => registered?

    // Assertions
    struct Assertion {
        uint256 nodeId;         // Node making the assertion
        bytes32 topicHash;      // Skill topic
        string evidenceUri;     // URI to external evidence
        uint256 timestamp;      // When asserted
        uint256 stake;          // SYN staked for this assertion
        bool isValidated;       // True if validated, false if disputed/invalidated
        bool isResolved;        // True if the challenge has been resolved
        uint256 assertionChallengeId; // ID of the CognitiveChallenge resolving this assertion
    }
    uint256 private _nextAssertionId;
    mapping(uint256 => Assertion) public assertions;

    // Cognitive Challenges (General & Assertion-specific)
    enum ChallengeType { General, AssertionValidation }
    enum ChallengeStatus { Pending, Active, Resolved, Canceled }

    struct CognitiveChallenge {
        ChallengeType challengeType;
        uint256 relatedEntityId; // assertionId for AssertionValidation, 0 for General
        address proposer;
        string questionUri;     // URI to detailed question/context
        bytes32[] answerOptionHashes; // Hashes of possible answers
        uint256 totalStake;     // Total SYN staked in this challenge
        uint256 minStakePerParticipant; // Minimum SYN required to participate
        uint256 startTime;
        uint256 endTime;
        ChallengeStatus status;
        bytes32 revealedOutcomeHash; // The hash of the correct answer
        string oracleProofUri;  // URI to external proof if an oracle is used
        mapping(uint256 => mapping(bytes32 => uint256)) participantStakes; // nodeId => answerHash => stake
        mapping(uint256 => bool) hasClaimedRewards; // nodeId => claimed?
    }
    uint256 private _nextChallengeId;
    mapping(uint256 => CognitiveChallenge) public challenges;

    // Delegated Validation Power
    // delegatorNodeId => delegateeNodeId => topicHash => percentage (0-10000 for 0-100%)
    mapping(uint256 => mapping(uint256 => mapping(bytes32 => uint256))) public delegatedPower;

    // Synergy Pools
    struct SynergyPool {
        string name;
        address admin;          // Address of the pool administrator
        bytes32[] requiredSkillTopics; // Hashes of skills required to join
        mapping(uint256 => bool) members; // nodeId => isMember
        uint256 memberCount;
        uint256 poolId;
    }
    uint256 private _nextPoolId;
    mapping(uint256 => SynergyPool) public synergyPools;

    // Protocol Parameters
    uint256 public constant MIN_REPUTATION_FOR_ASSERTION = 100; // Example
    uint256 public constant ASSERTION_STAKE_FEE_PERCENTAGE = 10; // 10% of stake goes to protocol (0-100)
    uint256 public constant CHALLENGE_CREATION_FEE = 0.05 ether; // Example fee in SYN for creating challenges (50m SYN)

    mapping(bytes32 => uint256) public protocolParameters; // Generic parameters, e.g., minChallengeDuration, maxChallengeDuration

    // --- Events ---
    event CognitoNodeCreated(uint256 indexed nodeId, address indexed owner, string uri);
    event CognitoNodeMetadataUpdated(uint256 indexed nodeId, string oldUri, string newUri);
    event CognitoNodeRevoked(uint256 indexed nodeId, address indexed owner);
    event SkillTopicRegistered(bytes32 indexed topicHash, string topicName);
    event SkillAsserted(uint256 indexed assertionId, uint256 indexed nodeId, bytes32 topicHash, string evidenceUri, uint256 stake);
    event AssertionChallengeProposed(uint256 indexed assertionId, uint256 indexed challengeId, uint256 proposerNodeId, uint256 stakeAmount);
    event AssertionSupported(uint256 indexed assertionId, uint256 indexed nodeId, uint256 stakeAmount);
    event AssertionDisputed(uint256 indexed assertionId, uint256 indexed nodeId, uint256 stakeAmount);
    event AssertionResolved(uint256 indexed assertionId, bool isValid, uint256 totalSupportStake, uint256 totalDisputeStake);
    event CognitiveChallengeCreated(uint256 indexed challengeId, ChallengeType challengeType, address proposer, string questionUri, uint256 minStake);
    event ChallengeParticipated(uint256 indexed challengeId, uint256 indexed nodeId, bytes32 chosenAnswerHash, uint256 stakeAmount);
    event ChallengeOutcomeRevealed(uint256 indexed challengeId, bytes32 indexed outcomeHash, string oracleProofUri);
    event ChallengeRewardsDistributed(uint256 indexed challengeId, uint256 totalRewards, uint256 protocolFee);
    event ChallengeWinningsClaimed(uint256 indexed challengeId, uint256 indexed nodeId, uint256 amount);
    event ValidationPowerDelegated(uint256 indexed delegatorNodeId, uint256 indexed delegateeNodeId, bytes32 topicHash, uint256 powerPercentage);
    event DelegationRevoked(uint256 indexed delegatorNodeId, uint256 indexed delegateeNodeId, bytes32 topicHash);
    event SynergyPoolCreated(uint256 indexed poolId, string name, address admin);
    event SynergyPoolJoined(uint256 indexed poolId, uint256 indexed nodeId);
    event SynergyPoolDeliverableSubmitted(uint256 indexed poolId, uint256 indexed nodeId, string deliverableUri);
    event ProtocolParameterUpdated(bytes32 indexed paramName, uint256 oldValue, uint256 newValue);
    event ProtocolFeesWithdrawn(address indexed to, uint256 amount);


    // --- Modifiers ---
    modifier onlyCognitoNodeOwner(uint256 _nodeId) {
        require(msg.sender == ownerOf(_nodeId), "CognitoNexus: Not node owner");
        _;
    }

    modifier onlyRegisteredNode() {
        require(addressToNodeId[msg.sender] != 0, "CognitoNexus: Caller must have a CognitoNode");
        _;
    }

    modifier onlyValidNode(uint256 _nodeId) {
        require(_exists(_nodeId), "CognitoNexus: Node does not exist");
        require(!isNodeRevoked[_nodeId], "CognitoNexus: Node has been revoked");
        _;
    }

    modifier onlySynapseTokenApproved(uint256 _amount) {
        require(synapseToken.allowance(msg.sender, address(this)) >= _amount, "CognitoNexus: Insufficient SYN approval");
        _;
    }

    // --- Constructor ---
    constructor(address _synapseTokenAddress) ERC721("Cognito Node", "CNODE") Ownable(msg.sender) {
        require(_synapseTokenAddress != address(0), "CognitoNexus: SYN token address cannot be zero");
        synapseToken = IERC20(_synapseTokenAddress);
        _nextTokenId = 1;
        _nextAssertionId = 1;
        _nextChallengeId = 1;
        _nextPoolId = 1;

        // Set initial protocol parameters
        protocolParameters[keccak256("minChallengeDuration")] = 1 days;
        protocolParameters[keccak256("maxChallengeDuration")] = 7 days;
        protocolParameters[keccak256("minChallengeStake")] = 1 ether; // 1 SYN
        protocolParameters[keccak256("minAssertionStake")] = 0.1 ether; // 0.1 SYN
    }

    // --- I. CognitoNode (Soulbound Identity) Management ---

    /**
     * @notice Mints a new soulbound CognitoNode (SBT) for the caller.
     * @dev Each address can only own one CognitoNode.
     * @return The ID of the newly created CognitoNode.
     */
    function createCognitoNode() public whenNotPaused returns (uint256) {
        require(addressToNodeId[msg.sender] == 0, "CognitoNexus: Caller already owns a CognitoNode");

        uint256 newNodeId = _nextTokenId++;
        _safeMint(msg.sender, newNodeId);
        _setTokenURI(newNodeId, ""); // Initial empty URI
        addressToNodeId[msg.sender] = newNodeId;
        nodeReputation[newNodeId] = 0; // Start with 0 reputation

        emit CognitoNodeCreated(newNodeId, msg.sender, "");
        return newNodeId;
    }

    /**
     * @notice Allows the node owner to update their CognitoNode's descriptive URI.
     * @dev The URI can point to a JSON metadata file describing the node's profile.
     * @param _uri The new URI for the CognitoNode's metadata.
     */
    function updateNodeMetadata(string memory _uri) public onlyRegisteredNode whenNotPaused {
        uint256 nodeId = addressToNodeId[msg.sender];
        string memory oldUri = tokenURI(nodeId);
        _setTokenURI(nodeId, _uri);
        emit CognitoNodeMetadataUpdated(nodeId, oldUri, _uri);
    }

    /**
     * @notice Allows a user to irrevocably burn their CognitoNode.
     * @dev This action is permanent and cannot be undone. All associated reputation, skill points,
     *      and delegations will be lost. Any active challenges might be affected.
     */
    function revokeCognitoNode() public onlyRegisteredNode whenNotPaused {
        uint256 nodeId = addressToNodeId[msg.sender];
        require(!isNodeRevoked[nodeId], "CognitoNexus: Node already revoked");
        
        // ERC721 `_burn` function ensures it's removed from supply and ownership maps
        _burn(nodeId); 
        isNodeRevoked[nodeId] = true;
        delete addressToNodeId[msg.sender]; // Remove mapping

        // Potentially more cleanup here for active participations, though for SBT, just burning is sufficient
        // as its associated data (reputation, skills) remains mapped to the ID, but the node is not owned.
        
        emit CognitoNodeRevoked(nodeId, msg.sender);
    }

    /**
     * @notice Retrieves the current reputation score of a CognitoNode.
     * @param _nodeId The ID of the CognitoNode.
     * @return The reputation score.
     */
    function getNodeReputation(uint256 _nodeId) public view onlyValidNode(_nodeId) returns (uint256) {
        return nodeReputation[_nodeId];
    }

    /**
     * @notice Retrieves skill points for a specific topic of a CognitoNode.
     * @param _nodeId The ID of the CognitoNode.
     * @param _topicHash The keccak256 hash of the skill topic name.
     * @return The skill points for the given topic.
     */
    function getNodeSkillPoints(uint256 _nodeId, bytes32 _topicHash) public view onlyValidNode(_nodeId) returns (uint256) {
        return nodeSkillPoints[_nodeId][_topicHash];
    }

    // --- II. Skill & Assertion Protocol ---

    /**
     * @notice Protocol admin/DAO registers new skill categories.
     * @dev Only the contract owner can call this. Skill names are hashed for efficient storage.
     * @param _topicName The human-readable name of the skill topic.
     */
    function registerSkillTopic(string memory _topicName) public onlyOwner {
        bytes32 topicHash = keccak256(abi.encodePacked(_topicName));
        require(!isSkillTopicRegistered[topicHash], "CognitoNexus: Skill topic already registered");
        skillTopicNames[topicHash] = _topicName;
        isSkillTopicRegistered[topicHash] = true;
        emit SkillTopicRegistered(topicHash, _topicName);
    }

    /**
     * @notice Allows a CognitoNode to assert a skill, providing a URI to verifiable evidence.
     * @dev Requires a SYN token stake which is held until the assertion is challenged or accepted.
     * @param _topicHash The keccak256 hash of the skill topic.
     * @param _evidenceUri A URI pointing to external evidence (e.g., certificate, project repo).
     */
    function assertSkill(bytes32 _topicHash, string memory _evidenceUri) public onlyRegisteredNode whenNotPaused onlySynapseTokenApproved(protocolParameters[keccak256("minAssertionStake")]) returns (uint256) {
        require(isSkillTopicRegistered[_topicHash], "CognitoNexus: Skill topic not registered");
        uint256 nodeId = addressToNodeId[msg.sender];
        require(nodeReputation[nodeId] >= MIN_REPUTATION_FOR_ASSERTION, "CognitoNexus: Insufficient reputation to assert skill");

        uint256 assertionId = _nextAssertionId++;
        uint256 stakeAmount = protocolParameters[keccak256("minAssertionStake")];

        require(synapseToken.transferFrom(msg.sender, address(this), stakeAmount), "CognitoNexus: SYN transfer failed for assertion stake");

        assertions[assertionId] = Assertion({
            nodeId: nodeId,
            topicHash: _topicHash,
            evidenceUri: _evidenceUri,
            timestamp: block.timestamp,
            stake: stakeAmount,
            isValidated: false, // Initially considered unvalidated
            isResolved: false,
            assertionChallengeId: 0
        });

        emit SkillAsserted(assertionId, nodeId, _topicHash, _evidenceUri, stakeAmount);
        return assertionId;
    }

    /**
     * @notice Initiates a CognitiveChallenge specifically to validate or dispute an existing skill assertion.
     * @dev This moves the assertion into a challenge phase.
     * @param _assertionId The ID of the skill assertion to challenge.
     * @param _stakeAmount The SYN token amount to stake for initiating the challenge.
     * @param _duration The duration of the challenge in seconds.
     * @return The ID of the newly created CognitiveChallenge.
     */
    function proposeAssertionChallenge(uint256 _assertionId, uint256 _stakeAmount, uint256 _duration) public onlyRegisteredNode whenNotPaused onlySynapseTokenApproved(_stakeAmount) returns (uint256) {
        require(assertions[_assertionId].nodeId != 0, "CognitoNexus: Assertion does not exist");
        require(!assertions[_assertionId].isResolved, "CognitoNexus: Assertion already resolved");
        require(assertions[_assertionId].assertionChallengeId == 0, "CognitoNexus: Assertion already under challenge");
        require(_stakeAmount >= protocolParameters[keccak256("minChallengeStake")], "CognitoNexus: Stake too low for challenge");
        require(_duration >= protocolParameters[keccak256("minChallengeDuration")] && _duration <= protocolParameters[keccak256("maxChallengeDuration")], "CognitoNexus: Invalid challenge duration");

        uint256 proposerNodeId = addressToNodeId[msg.sender];
        require(proposerNodeId != assertions[_assertionId].nodeId, "CognitoNexus: Cannot challenge your own assertion");

        require(synapseToken.transferFrom(msg.sender, address(this), _stakeAmount), "CognitoNexus: SYN transfer failed for challenge stake");

        uint256 challengeId = _nextChallengeId++;
        bytes32[] memory answerOptions = new bytes32[](2);
        answerOptions[0] = keccak256(abi.encodePacked("VALID"));
        answerOptions[1] = keccak256(abi.encodePacked("INVALID"));

        challenges[challengeId] = CognitiveChallenge({
            challengeType: ChallengeType.AssertionValidation,
            relatedEntityId: _assertionId,
            proposer: msg.sender,
            questionUri: string(abi.encodePacked("Validate assertion ID: ", Strings.toString(_assertionId), " - ", assertions[_assertionId].evidenceUri)),
            answerOptionHashes: answerOptions,
            totalStake: _stakeAmount,
            minStakePerParticipant: _stakeAmount.div(100), // Smallest possible stake for participation
            startTime: block.timestamp,
            endTime: block.timestamp.add(_duration),
            status: ChallengeStatus.Active,
            revealedOutcomeHash: 0,
            oracleProofUri: ""
        });
        challenges[challengeId].participantStakes[proposerNodeId][keccak256(abi.encodePacked("INVALID"))] = _stakeAmount;
        
        assertions[_assertionId].assertionChallengeId = challengeId;

        emit AssertionChallengeProposed(_assertionId, challengeId, proposerNodeId, _stakeAmount);
        return challengeId;
    }

    /**
     * @notice Stakes SYN tokens to express support for an assertion within its challenge period.
     * @dev This effectively votes "VALID" in the assertion challenge.
     * @param _assertionId The ID of the assertion to support.
     * @param _stakeAmount The amount of SYN to stake.
     */
    function supportAssertion(uint256 _assertionId, uint256 _stakeAmount) public onlyRegisteredNode whenNotPaused onlySynapseTokenApproved(_stakeAmount) {
        require(assertions[_assertionId].nodeId != 0, "CognitoNexus: Assertion does not exist");
        uint256 challengeId = assertions[_assertionId].assertionChallengeId;
        require(challengeId != 0, "CognitoNexus: Assertion not under challenge");
        
        uint256 nodeId = addressToNodeId[msg.sender];
        require(nodeId != assertions[_assertionId].nodeId, "CognitoNexus: Assertor cannot support their own assertion in challenge");

        _participateInAssertionChallenge(challengeId, nodeId, keccak256(abi.encodePacked("VALID")), _stakeAmount);
        emit AssertionSupported(_assertionId, nodeId, _stakeAmount);
    }

    /**
     * @notice Stakes SYN tokens to express a dispute against an assertion within its challenge period.
     * @dev This effectively votes "INVALID" in the assertion challenge.
     * @param _assertionId The ID of the assertion to dispute.
     * @param _stakeAmount The amount of SYN to stake.
     */
    function disputeAssertion(uint256 _assertionId, uint256 _stakeAmount) public onlyRegisteredNode whenNotPaused onlySynapseTokenApproved(_stakeAmount) {
        require(assertions[_assertionId].nodeId != 0, "CognitoNexus: Assertion does not exist");
        uint256 challengeId = assertions[_assertionId].assertionChallengeId;
        require(challengeId != 0, "CognitoNexus: Assertion not under challenge");
        
        uint256 nodeId = addressToNodeId[msg.sender];
        require(nodeId != assertions[_assertionId].nodeId, "CognitoNexus: Assertor cannot dispute their own assertion");

        _participateInAssertionChallenge(challengeId, nodeId, keccak256(abi.encodePacked("INVALID")), _stakeAmount);
        emit AssertionDisputed(_assertionId, nodeId, _stakeAmount);
    }

    /**
     * @dev Internal function for participating in an assertion-specific challenge.
     */
    function _participateInAssertionChallenge(uint256 _challengeId, uint256 _nodeId, bytes32 _vote, uint256 _stakeAmount) internal {
        CognitiveChallenge storage challenge = challenges[_challengeId];
        require(challenge.challengeType == ChallengeType.AssertionValidation, "CognitoNexus: Not an assertion validation challenge");
        require(challenge.status == ChallengeStatus.Active, "CognitoNexus: Challenge not active");
        require(block.timestamp <= challenge.endTime, "CognitoNexus: Challenge has ended");
        require(_stakeAmount >= challenge.minStakePerParticipant, "CognitoNexus: Stake too low for participation");
        
        // Ensure the vote is one of the valid options
        bool validOption = false;
        for (uint i = 0; i < challenge.answerOptionHashes.length; i++) {
            if (challenge.answerOptionHashes[i] == _vote) {
                validOption = true;
                break;
            }
        }
        require(validOption, "CognitoNexus: Invalid vote for this challenge");

        require(synapseToken.transferFrom(msg.sender, address(this), _stakeAmount), "CognitoNexus: SYN transfer failed for challenge participation");

        challenge.participantStakes[_nodeId][_vote] = challenge.participantStakes[_nodeId][_vote].add(_stakeAmount);
        challenge.totalStake = challenge.totalStake.add(_stakeAmount);
        emit ChallengeParticipated(_challengeId, _nodeId, _vote, _stakeAmount);
    }

    /**
     * @notice Finalizes an assertion challenge, updating reputation and skill points based on the outcome.
     * @dev Can be called by anyone after the challenge `endTime`.
     * @param _assertionChallengeId The ID of the assertion-specific CognitiveChallenge.
     */
    function resolveAssertionChallenge(uint256 _assertionChallengeId) public whenNotPaused {
        CognitiveChallenge storage challenge = challenges[_assertionChallengeId];
        require(challenge.challengeType == ChallengeType.AssertionValidation, "CognitoNexus: Not an assertion validation challenge");
        require(challenge.status == ChallengeStatus.Active, "CognitoNexus: Challenge not active");
        require(block.timestamp > challenge.endTime, "CognitoNexus: Challenge period not over");

        uint256 assertionId = challenge.relatedEntityId;
        Assertion storage assertion = assertions[assertionId];

        uint256 totalValidStake = 0;
        uint256 totalInvalidStake = 0;

        // Sum stakes for 'VALID' and 'INVALID'
        for (uint256 i = 1; i < _nextTokenId; i++) { // Iterate through all possible nodeIds
            if (challenge.participantStakes[i][keccak256(abi.encodePacked("VALID"))] > 0) {
                totalValidStake = totalValidStake.add(challenge.participantStakes[i][keccak256(abi.encodePacked("VALID"))]);
            }
            if (challenge.participantStakes[i][keccak256(abi.encodePacked("INVALID"))] > 0) {
                totalInvalidStake = totalInvalidStake.add(challenge.participantStakes[i][keccak256(abi.encodePacked("INVALID"))]);
            }
        }
        
        bool outcomeIsValidated = totalValidStake >= totalInvalidStake; // Tie goes to validation
        challenge.revealedOutcomeHash = outcomeIsValidated ? keccak256(abi.encodePacked("VALID")) : keccak256(abi.encodePacked("INVALID"));
        challenge.status = ChallengeStatus.Resolved;
        assertion.isValidated = outcomeIsValidated;
        assertion.isResolved = true;

        // Reward and penalize based on outcome
        uint256 protocolFee = challenge.totalStake.mul(ASSERTION_STAKE_FEE_PERCENTAGE).div(100);
        uint256 rewardPool = challenge.totalStake.sub(protocolFee);

        uint256 winnerStakeTotal = outcomeIsValidated ? totalValidStake : totalInvalidStake;
        uint256 loserStakeTotal = outcomeIsValidated ? totalInvalidStake : totalValidStake;

        // Assertor's stake is handled here
        if (outcomeIsValidated) {
            _rewardNode(assertion.nodeId, 50, assertion.topicHash, 10); // Example: 50 reputation, 10 skill points
            // Return assertor's initial stake if validated
            require(synapseToken.transfer(assertion.nodeId, assertion.stake), "CognitoNexus: Failed to return assertor stake");
        } else {
            _penalizeNode(assertion.nodeId, 25, keccak256(abi.encodePacked("Failed assertion validation"))); // Example penalty
            // Assertor loses their stake (it contributes to the reward pool for correct disputers)
            rewardPool = rewardPool.add(assertion.stake); // Add assertor's stake to the pool for the disputers
            loserStakeTotal = loserStakeTotal.add(assertion.stake); // Add assertor's stake to loser pool for calculation
        }

        // Distribute rewards to winning participants
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (challenges[_assertionChallengeId].participantStakes[i][challenge.revealedOutcomeHash] > 0) {
                _rewardNode(i, 10, 0, 0); // Small reward for correct participation (reputation only for general challenge)
            }
        }
        // Specific reward distribution handled in distributeChallengeRewards

        emit AssertionResolved(assertionId, outcomeIsValidated, totalValidStake, totalInvalidStake);
        emit ChallengeOutcomeRevealed(_assertionChallengeId, challenge.revealedOutcomeHash, challenge.oracleProofUri);
        // Call distribute to handle the SYN rewards
        distributeChallengeRewards(_assertionChallengeId);
    }

    /**
     * @notice Retrieves comprehensive details about a specific skill assertion.
     * @param _assertionId The ID of the assertion.
     * @return tuple (nodeId, topicHash, evidenceUri, timestamp, stake, isValidated, isResolved, assertionChallengeId)
     */
    function getAssertionDetails(uint256 _assertionId) public view returns (uint256, bytes32, string memory, uint256, uint256, bool, bool, uint256) {
        Assertion storage a = assertions[_assertionId];
        require(a.nodeId != 0, "CognitoNexus: Assertion does not exist");
        return (a.nodeId, a.topicHash, a.evidenceUri, a.timestamp, a.stake, a.isValidated, a.isResolved, a.assertionChallengeId);
    }


    // --- III. Cognitive Challenge System (General) ---

    /**
     * @notice Initiates a general CognitiveChallenge for knowledge synthesis or insight generation.
     * @dev Requires a SYN token fee.
     * @param _questionUri A URI pointing to the detailed question or problem description.
     * @param _answerOptionHashes Hashes of predefined answer options (e.g., keccak256("Yes"), keccak256("No")).
     * @param _stakeAmount The minimum SYN token amount required to participate.
     * @param _duration The duration of the challenge in seconds.
     * @return The ID of the newly created CognitiveChallenge.
     */
    function createCognitiveChallenge(string memory _questionUri, bytes32[] memory _answerOptionHashes, uint256 _stakeAmount, uint256 _duration) public onlyRegisteredNode whenNotPaused onlySynapseTokenApproved(CHALLENGE_CREATION_FEE.add(_stakeAmount)) returns (uint256) {
        require(_answerOptionHashes.length > 1, "CognitoNexus: At least two answer options required");
        require(_stakeAmount >= protocolParameters[keccak256("minChallengeStake")], "CognitoNexus: Min participation stake too low");
        require(_duration >= protocolParameters[keccak256("minChallengeDuration")] && _duration <= protocolParameters[keccak256("maxChallengeDuration")], "CognitoNexus: Invalid challenge duration");

        require(synapseToken.transferFrom(msg.sender, address(this), CHALLENGE_CREATION_FEE), "CognitoNexus: SYN transfer failed for challenge creation fee");
        require(synapseToken.transferFrom(msg.sender, address(this), _stakeAmount), "CognitoNexus: SYN transfer failed for initial challenge stake"); // Proposer's initial stake

        uint256 challengeId = _nextChallengeId++;
        uint256 proposerNodeId = addressToNodeId[msg.sender];

        challenges[challengeId] = CognitiveChallenge({
            challengeType: ChallengeType.General,
            relatedEntityId: 0,
            proposer: msg.sender,
            questionUri: _questionUri,
            answerOptionHashes: _answerOptionHashes,
            totalStake: _stakeAmount,
            minStakePerParticipant: _stakeAmount, // Proposer's stake sets the minimum
            startTime: block.timestamp,
            endTime: block.timestamp.add(_duration),
            status: ChallengeStatus.Active,
            revealedOutcomeHash: 0,
            oracleProofUri: ""
        });
        challenges[challengeId].participantStakes[proposerNodeId][_answerOptionHashes[0]] = _stakeAmount; // Proposer stakes on first option by default

        emit CognitiveChallengeCreated(challengeId, ChallengeType.General, msg.sender, _questionUri, _stakeAmount);
        return challengeId;
    }

    /**
     * @notice Allows a CognitoNode to participate in a challenge by staking on a chosen answer.
     * @param _challengeId The ID of the CognitiveChallenge.
     * @param _chosenAnswerHash The keccak256 hash of the chosen answer option.
     * @param _stakeAmount The amount of SYN tokens to stake.
     */
    function participateInChallenge(uint256 _challengeId, bytes32 _chosenAnswerHash, uint256 _stakeAmount) public onlyRegisteredNode whenNotPaused onlySynapseTokenApproved(_stakeAmount) {
        CognitiveChallenge storage challenge = challenges[_challengeId];
        require(challenge.challengeType == ChallengeType.General, "CognitoNexus: Not a general cognitive challenge");
        require(challenge.status == ChallengeStatus.Active, "CognitoNexus: Challenge not active");
        require(block.timestamp <= challenge.endTime, "CognitoNexus: Challenge has ended");
        require(_stakeAmount >= challenge.minStakePerParticipant, "CognitoNexus: Stake too low for participation");

        bool validOption = false;
        for (uint i = 0; i < challenge.answerOptionHashes.length; i++) {
            if (challenge.answerOptionHashes[i] == _chosenAnswerHash) {
                validOption = true;
                break;
            }
        }
        require(validOption, "CognitoNexus: Invalid answer option for this challenge");

        require(synapseToken.transferFrom(msg.sender, address(this), _stakeAmount), "CognitoNexus: SYN transfer failed for challenge participation");

        uint256 nodeId = addressToNodeId[msg.sender];
        challenge.participantStakes[nodeId][_chosenAnswerHash] = challenge.participantStakes[nodeId][_chosenAnswerHash].add(_stakeAmount);
        challenge.totalStake = challenge.totalStake.add(_stakeAmount);

        emit ChallengeParticipated(_challengeId, nodeId, _chosenAnswerHash, _stakeAmount);
    }

    /**
     * @notice Admin/trusted oracle reveals the true outcome for a general cognitive challenge.
     * @dev This step can be decentralized further (e.g., through another sub-challenge or a reputation-weighted vote).
     * @param _challengeId The ID of the CognitiveChallenge.
     * @param _correctAnswerHash The keccak256 hash of the correct answer.
     * @param _oracleProofUri A URI pointing to external proof or justification for the outcome.
     */
    function revealChallengeOutcome(uint256 _challengeId, bytes32 _correctAnswerHash, string memory _oracleProofUri) public onlyOwner whenNotPaused {
        CognitiveChallenge storage challenge = challenges[_challengeId];
        require(challenge.challengeType == ChallengeType.General, "CognitoNexus: Not a general cognitive challenge");
        require(challenge.status == ChallengeStatus.Active, "CognitoNexus: Challenge not active");
        require(block.timestamp > challenge.endTime, "CognitoNexus: Challenge period not over");

        bool validOption = false;
        for (uint i = 0; i < challenge.answerOptionHashes.length; i++) {
            if (challenge.answerOptionHashes[i] == _correctAnswerHash) {
                validOption = true;
                break;
            }
        }
        require(validOption, "CognitoNexus: Revealed outcome is not a valid option");

        challenge.revealedOutcomeHash = _correctAnswerHash;
        challenge.oracleProofUri = _oracleProofUri;
        challenge.status = ChallengeStatus.Resolved;

        emit ChallengeOutcomeRevealed(_challengeId, _correctAnswerHash, _oracleProofUri);
        distributeChallengeRewards(_challengeId); // Immediately trigger reward distribution
    }

    /**
     * @notice Distributes staked SYN tokens and reputation/skill rewards to correct participants.
     * @dev Can be called by anyone once a challenge is resolved.
     * @param _challengeId The ID of the CognitiveChallenge.
     */
    function distributeChallengeRewards(uint256 _challengeId) public whenNotPaused {
        CognitiveChallenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Resolved, "CognitoNexus: Challenge not resolved");
        require(challenge.revealedOutcomeHash != 0, "CognitoNexus: Challenge outcome not revealed");

        uint256 protocolFee = challenge.totalStake.mul(ASSERTION_STAKE_FEE_PERCENTAGE).div(100);
        uint256 rewardPool = challenge.totalStake.sub(protocolFee);

        uint256 totalWinnerStake = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (_exists(i) && !isNodeRevoked[i]) {
                totalWinnerStake = totalWinnerStake.add(challenge.participantStakes[i][challenge.revealedOutcomeHash]);
            }
        }

        if (totalWinnerStake > 0) {
            for (uint256 i = 1; i < _nextTokenId; i++) {
                if (_exists(i) && !isNodeRevoked[i]) {
                    uint256 participantWinningStake = challenge.participantStakes[i][challenge.revealedOutcomeHash];
                    if (participantWinningStake > 0) {
                        uint256 reward = rewardPool.mul(participantWinningStake).div(totalWinnerStake);
                        // Store the reward amount for participants to claim
                        // A more robust system might use a separate mapping for claimable amounts per user
                        // For simplicity, we assume the reward is instantly available to claim
                        // For this demo, we'll store it in a dummy place or just emit for tracking
                        // In reality, this would be accumulated per participant to be claimed by them.
                        // Let's adjust this.
                        // challenge.claimableRewards[i] = challenge.claimableRewards[i].add(reward); // This would need to be added to struct
                        
                        // For the purpose of this example, we'll just track that rewards were distributed for logging
                        // The claimChallengeWinnings function will handle the actual transfer based on `participantStakes`
                        // and `hasClaimedRewards` flags.

                        _rewardNode(i, 10, 0, 0); // Small reputation reward for correct prediction
                    }
                }
            }
        }
        // Set all participant stakes to 0 after distribution to prevent double claims, mark claimed
        // This is done in claimChallengeWinnings
        
        emit ChallengeRewardsDistributed(_challengeId, rewardPool, protocolFee);
    }

    /**
     * @notice Allows participants to withdraw their earned SYN tokens after a challenge is resolved.
     * @param _challengeId The ID of the CognitiveChallenge.
     */
    function claimChallengeWinnings(uint256 _challengeId) public onlyRegisteredNode whenNotPaused {
        CognitiveChallenge storage challenge = challenges[_challengeId];
        require(challenge.status == ChallengeStatus.Resolved, "CognitoNexus: Challenge not resolved");
        require(challenge.revealedOutcomeHash != 0, "CognitoNexus: Challenge outcome not revealed");
        
        uint256 nodeId = addressToNodeId[msg.sender];
        require(!challenge.hasClaimedRewards[nodeId], "CognitoNexus: Rewards already claimed for this challenge");
        
        uint256 totalWinnerStake = 0;
        for (uint256 i = 1; i < _nextTokenId; i++) {
            if (_exists(i) && !isNodeRevoked[i]) {
                totalWinnerStake = totalWinnerStake.add(challenge.participantStakes[i][challenge.revealedOutcomeHash]);
            }
        }

        uint256 protocolFee = challenge.totalStake.mul(ASSERTION_STAKE_FEE_PERCENTAGE).div(100);
        uint256 rewardPool = challenge.totalStake.sub(protocolFee);

        uint256 participantWinningStake = challenge.participantStakes[nodeId][challenge.revealedOutcomeHash];
        require(participantWinningStake > 0, "CognitoNexus: No winning stake for this participant");

        uint256 winnings = 0;
        if (totalWinnerStake > 0) {
            winnings = rewardPool.mul(participantWinningStake).div(totalWinnerStake);
        }

        challenge.hasClaimedRewards[nodeId] = true; // Mark as claimed

        // Also refund any losing stakes that weren't won by anyone (e.g., if no one voted on winning option)
        // For simplicity, losing stakes are considered burned/contributed to winning pool.
        // A more complex system might have a mechanism to refund losing stakes if the winning pool is smaller.
        
        if (winnings > 0) {
            require(synapseToken.transfer(msg.sender, winnings), "CognitoNexus: SYN transfer failed for winnings");
        }
        
        // Zero out the participant's stake record for this challenge, ensures it's not counted again.
        challenge.participantStakes[nodeId][challenge.revealedOutcomeHash] = 0; 
        
        emit ChallengeWinningsClaimed(_challengeId, nodeId, winnings);
    }


    /**
     * @notice Retrieves the current status and details of a cognitive challenge.
     * @param _challengeId The ID of the CognitiveChallenge.
     * @return tuple (status, proposer, questionUri, endTime, totalStake, revealedOutcomeHash)
     */
    function getChallengeStatus(uint256 _challengeId) public view returns (ChallengeStatus, address, string memory, uint256, uint256, bytes32) {
        CognitiveChallenge storage challenge = challenges[_challengeId];
        require(challenge.proposer != address(0), "CognitoNexus: Challenge does not exist");
        return (challenge.status, challenge.proposer, challenge.questionUri, challenge.endTime, challenge.totalStake, challenge.revealedOutcomeHash);
    }


    // --- IV. Reputation & Reward Mechanics (Internal & Admin) ---

    /**
     * @dev Internal function to update a node's reputation and skill points.
     * @param _nodeId The ID of the CognitoNode.
     * @param _reputationGain The amount of reputation to add.
     * @param _topicHash The topic hash for skill points (0 if only reputation).
     * @param _skillPointGain The amount of skill points to add.
     */
    function _rewardNode(uint256 _nodeId, uint256 _reputationGain, bytes32 _topicHash, uint256 _skillPointGain) internal onlyValidNode(_nodeId) {
        nodeReputation[_nodeId] = nodeReputation[_nodeId].add(_reputationGain);
        if (_topicHash != 0) {
            nodeSkillPoints[_nodeId][_topicHash] = nodeSkillPoints[_nodeId][_topicHash].add(_skillPointGain);
        }
        // Potentially trigger dynamic NFT metadata update here if the URI is managed on-chain
        // For now, metadata update is manual via `updateNodeMetadata`.
    }

    /**
     * @dev Internal function to penalize a node by reducing its reputation.
     * @param _nodeId The ID of the CognitoNode.
     * @param _reputationLoss The amount of reputation to subtract.
     * @param _reasonHash A hash representing the reason for the penalty.
     */
    function _penalizeNode(uint256 _nodeId, uint256 _reputationLoss, bytes32 _reasonHash) internal onlyValidNode(_nodeId) {
        nodeReputation[_nodeId] = nodeReputation[_nodeId].sub(Math.min(nodeReputation[_nodeId], _reputationLoss));
        // Potentially trigger dynamic NFT metadata update here.
        // Also consider a "bad actor" flag if reputation drops too low.
    }

    /**
     * @notice Allows the protocol owner/DAO to withdraw accumulated SYN fees.
     * @param _to The address to send the fees to.
     * @param _amount The amount of SYN to withdraw.
     */
    function withdrawProtocolFees(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "CognitoNexus: Cannot withdraw to zero address");
        require(synapseToken.balanceOf(address(this)) >= _amount, "CognitoNexus: Insufficient protocol balance");
        require(synapseToken.transfer(_to, _amount), "CognitoNexus: Fee withdrawal failed");
        emit ProtocolFeesWithdrawn(_to, _amount);
    }

    /**
     * @notice Allows admin/DAO to adjust various protocol parameters.
     * @dev Use keccak256 hash of the parameter name (e.g., "minChallengeDuration").
     * @param _paramName The keccak256 hash of the parameter name.
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramName, uint256 _newValue) public onlyOwner {
        uint256 oldValue = protocolParameters[_paramName];
        protocolParameters[_paramName] = _newValue;
        emit ProtocolParameterUpdated(_paramName, oldValue, _newValue);
    }

    // --- V. Delegated Validation & Synergy Pools ---

    /**
     * @notice Allows a CognitoNode to delegate a percentage of its skill-specific validation power to another node.
     * @dev Delegation power multiplies the delegatee's effective skill points for voting/validation purposes.
     * @param _delegateeNodeId The ID of the CognitoNode receiving the delegated power.
     * @param _topicHash The skill topic for which power is delegated.
     * @param _powerPercentage The percentage of power to delegate (0-10000 for 0-100%).
     */
    function delegateValidationPower(uint256 _delegateeNodeId, bytes32 _topicHash, uint256 _powerPercentage) public onlyRegisteredNode whenNotPaused {
        uint256 delegatorNodeId = addressToNodeId[msg.sender];
        require(delegatorNodeId != _delegateeNodeId, "CognitoNexus: Cannot delegate to self");
        require(isSkillTopicRegistered[_topicHash], "CognitoNexus: Skill topic not registered");
        require(_powerPercentage <= 10000, "CognitoNexus: Power percentage exceeds 100%"); // 10000 = 100%
        
        delegatedPower[delegatorNodeId][_delegateeNodeId][_topicHash] = _powerPercentage;
        emit ValidationPowerDelegated(delegatorNodeId, _delegateeNodeId, _topicHash, _powerPercentage);
    }

    /**
     * @notice Revokes a previously made delegation of validation power.
     * @param _delegateeNodeId The ID of the CognitoNode from which power was delegated.
     * @param _topicHash The skill topic for which delegation is revoked.
     */
    function revokeDelegation(uint256 _delegateeNodeId, bytes32 _topicHash) public onlyRegisteredNode whenNotPaused {
        uint256 delegatorNodeId = addressToNodeId[msg.sender];
        require(delegatedPower[delegatorNodeId][_delegateeNodeId][_topicHash] > 0, "CognitoNexus: No active delegation to revoke");
        
        delete delegatedPower[delegatorNodeId][_delegateeNodeId][_topicHash];
        emit DelegationRevoked(delegatorNodeId, _delegateeNodeId, _topicHash);
    }

    /**
     * @notice Calculates the total effective validation power of a node for a given skill topic.
     * @dev Includes its own skill points plus any delegated power. This is a read-only helper.
     * @param _nodeId The ID of the CognitoNode.
     * @param _topicHash The skill topic.
     * @return The total effective validation power.
     */
    function getDelegatedPower(uint256 _nodeId, bytes32 _topicHash) public view onlyValidNode(_nodeId) returns (uint256) {
        uint256 effectiveSkillPoints = nodeSkillPoints[_nodeId][_topicHash];

        // Sum up power delegated FROM this node to others (not applicable for effective power of THIS node)
        // Sum up power delegated TO this node from others
        for (uint256 i = 1; i < _nextTokenId; i++) { // Iterate all possible delegator nodes
            if (_exists(i) && !isNodeRevoked[i] && i != _nodeId) { // Ensure it's a valid delegator and not self
                uint256 percentage = delegatedPower[i][_nodeId][_topicHash]; // Power FROM i TO _nodeId
                if (percentage > 0) {
                    // This is a simplified calculation. A true system might sum up directly (percentage * delegator's points)
                    // For demo, assume delegation directly adds 'points' proportional to delegatee's base skill for simplicity.
                    // Or, more accurately, 'percentage' of the *delegator's* skill points for that topic.
                    // Let's implement the latter: it represents the portion of the delegator's expertise contributed.
                    effectiveSkillPoints = effectiveSkillPoints.add(
                        nodeSkillPoints[i][_topicHash].mul(percentage).div(10000)
                    );
                }
            }
        }
        return effectiveSkillPoints;
    }

    /**
     * @notice Creates a new collaborative pool requiring specific aggregated skill sets from its members.
     * @param _requiredSkillTopics Hashes of skills required for joining this pool.
     * @param _poolName The name of the synergy pool.
     * @param _adminAddress The address of the pool administrator.
     * @return The ID of the newly created SynergyPool.
     */
    function createSynergyPool(bytes32[] memory _requiredSkillTopics, string memory _poolName, address _adminAddress) public onlyRegisteredNode whenNotPaused returns (uint256) {
        require(_requiredSkillTopics.length > 0, "CognitoNexus: Must specify at least one required skill");
        for (uint i = 0; i < _requiredSkillTopics.length; i++) {
            require(isSkillTopicRegistered[_requiredSkillTopics[i]], "CognitoNexus: Required skill topic not registered");
        }
        require(_adminAddress != address(0), "CognitoNexus: Pool admin cannot be zero address");

        uint256 poolId = _nextPoolId++;
        synergyPools[poolId] = SynergyPool({
            name: _poolName,
            admin: _adminAddress,
            requiredSkillTopics: _requiredSkillTopics,
            members: new mapping(uint256 => bool)(), // Initialize mapping
            memberCount: 0,
            poolId: poolId
        });
        emit SynergyPoolCreated(poolId, _poolName, _adminAddress);
        return poolId;
    }

    /**
     * @notice Allows a CognitoNode to join a SynergyPool if it meets the skill requirements.
     * @dev A node must have non-zero skill points in at least one of the required topics.
     * @param _poolId The ID of the SynergyPool to join.
     */
    function joinSynergyPool(uint256 _poolId) public onlyRegisteredNode whenNotPaused {
        SynergyPool storage pool = synergyPools[_poolId];
        require(pool.poolId != 0, "CognitoNexus: Synergy pool does not exist");
        
        uint256 nodeId = addressToNodeId[msg.sender];
        require(!pool.members[nodeId], "CognitoNexus: Node is already a member of this pool");

        bool hasRequiredSkill = false;
        for (uint i = 0; i < pool.requiredSkillTopics.length; i++) {
            if (getNodeSkillPoints(nodeId, pool.requiredSkillTopics[i]) > 0) { // Uses raw skill points, not delegated
                hasRequiredSkill = true;
                break;
            }
        }
        require(hasRequiredSkill, "CognitoNexus: Node does not meet required skill criteria");

        pool.members[nodeId] = true;
        pool.memberCount = pool.memberCount.add(1);
        emit SynergyPoolJoined(_poolId, nodeId);
    }

    /**
     * @notice A SynergyPool member submits a URI pointing to a completed deliverable or milestone.
     * @param _poolId The ID of the SynergyPool.
     * @param _deliverableUri A URI pointing to the deliverable (e.g., IPFS hash, GitHub link).
     */
    function submitPoolDeliverable(uint256 _poolId, string memory _deliverableUri) public onlyRegisteredNode whenNotPaused {
        SynergyPool storage pool = synergyPools[_poolId];
        require(pool.poolId != 0, "CognitoNexus: Synergy pool does not exist");

        uint256 nodeId = addressToNodeId[msg.sender];
        require(pool.members[nodeId], "CognitoNexus: Only pool members can submit deliverables");
        
        // This function just records the submission. Actual evaluation/rewards would be external or via another challenge.
        emit SynergyPoolDeliverableSubmitted(_poolId, nodeId, _deliverableUri);
    }


    // --- VI. Protocol Configuration & Utility ---

    /**
     * @notice Admin function to set the address of the SynapseToken contract.
     * @dev Can only be called once if the token was not set in the constructor.
     * @param _synapseToken The address of the SynapseToken contract.
     */
    function setSynapseTokenAddress(address _synapseToken) public onlyOwner {
        require(address(synapseToken) == address(0), "CognitoNexus: Synapse Token address already set");
        require(_synapseToken != address(0), "CognitoNexus: SYN token address cannot be zero");
        synapseToken = IERC20(_synapseToken);
    }

    /**
     * @notice Admin function to pause core protocol functionalities in case of an emergency.
     * @dev Prevents new nodes, assertions, challenges, and pool joins.
     */
    function pauseProtocol() public onlyOwner {
        _pause();
    }

    /**
     * @notice Admin function to unpause the protocol.
     */
    function unpauseProtocol() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Utility function to check if an address owns a specific CognitoNode.
     * @param _addr The address to check.
     * @param _nodeId The ID of the CognitoNode.
     * @return True if the address owns the node, false otherwise.
     */
    function isNodeOwner(address _addr, uint256 _nodeId) public view returns (bool) {
        return ownerOf(_nodeId) == _addr;
    }

    // --- ERC721 Overrides for Soulbound Behavior ---

    /**
     * @dev Overrides `_beforeTokenTransfer` to prevent transfers of CognitoNodes.
     *      SBTs are non-transferable.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from == address(0)) and burning (to == address(0) or internal _burn call)
        // Disallow all other transfers
        if (from != address(0) && to != address(0)) {
            revert("CognitoNexus: CognitoNodes are Soulbound and cannot be transferred");
        }
    }

    /**
     * @dev The following functions are explicitly marked as not supported to reinforce SBT nature.
     *      They would typically be handled by _beforeTokenTransfer but explicit reversion is clearer.
     */
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("CognitoNexus: CognitoNodes are Soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("CognitoNexus: CognitoNodes are Soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public pure override {
        revert("CognitoNexus: CognitoNodes are Soulbound and cannot be transferred");
    }

    function approve(address to, uint256 tokenId) public pure override {
        revert("CognitoNexus: CognitoNodes are Soulbound and cannot be approved");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("CognitoNexus: CognitoNodes are Soulbound and cannot be approved");
    }

    function getApproved(uint256 tokenId) public pure override returns (address) {
        revert("CognitoNexus: CognitoNodes are Soulbound and cannot be approved");
    }

    function isApprovedForAll(address owner, address operator) public pure override returns (bool) {
        revert("CognitoNexus: CognitoNodes are Soulbound and cannot be approved");
    }
}
```