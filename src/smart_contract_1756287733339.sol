Here's a smart contract that implements a **"Decentralized Autonomous Environmental Monitoring Network (EcoSenseNet)"** with AI-powered insights, reputation-based staking, and dynamic NFTs. It's designed to be a unique blend of DePIN (Decentralized Physical Infrastructure Networks), AI integration (via oracles), and sophisticated DAO governance, all aimed at fostering environmental intelligence.

---

### EcoSenseNet Contract Outline & Function Summary

**Contract Name:** `EcoSenseNet`

**Core Concept:**
`EcoSenseNet` is a decentralized network for collecting, analyzing, and providing insights on environmental data. It leverages physical "Sensor Nodes" (represented by dynamic NFTs) operated by stakers, and "AI Models" (also dynamic NFTs) that process this data. A reputation system governs rewards and penalties, and a DAO oversees network parameters and dispute resolution. Data consumers can request AI-powered environmental insights, fostering a transparent and incentivized ecosystem for ecological monitoring.

**Key Features:**
1.  **`EMNET` Token (ERC-20):** The native utility and governance token of the network.
2.  **`SensorNode` NFTs (ERC-721):** Represents a physical environmental sensor. These NFTs are dynamic, meaning their metadata (reputation, data quality, status) changes on-chain based on performance.
3.  **`AIModel` NFTs (ERC-721):** Represents a registered AI algorithm designed to analyze sensor data. These are also dynamic, tracking accuracy, usage, and reputation.
4.  **Reputation System:** Both Sensor Nodes and AI Models accumulate a reputation score, which influences their reward potential, staking requirements, and network participation.
5.  **Data & Insight Marketplace:** Consumers can request specific environmental data analyses, paying with `EMNET` tokens, and AI Models compete to provide the most accurate insights.
6.  **Staking & Rewards:** Participants (Sensor Node operators, AI Model developers) stake `EMNET` tokens to join and earn rewards for their contributions.
7.  **DAO Governance:** A simplified DAO structure for proposing and voting on network parameter changes, validating AI models, and resolving disputes.
8.  **Verifiable Data & AI (Simulated):** Functions are designed to integrate with oracles or future verifiable computation systems for external data validation and AI model output verification.
9.  **Decentralized Environmental Credits (Future Concept):** Paving the way for a ReFi (Regenerative Finance) component where certain verified environmental actions could generate credits.

---

**Function Summary (25+ Functions):**

**I. Core Network Operations & Staking:**
1.  `constructor()`: Initializes the `EMNET` token, `SensorNode` NFT, `AIModel` NFT contracts, and sets initial network parameters.
2.  `registerSensorNode(string calldata _metadataURI)`: Allows users to register a new Sensor Node by staking `EMNET` tokens and minting a `SensorNode` NFT.
3.  `deregisterSensorNode(uint256 _nodeId)`: Initiates the process to remove a Sensor Node, unstake `EMNET`, and burn the NFT (subject to a cooldown and potential penalties).
4.  `updateSensorData(uint256 _nodeId, bytes calldata _encryptedDataHash, string calldata _dataType)`: Sensor operators submit a hash of encrypted environmental data. (Actual data stored off-chain).
5.  `claimSensorRewards(uint256 _nodeId)`: Allows Sensor Node operators to claim accumulated rewards based on their data contribution and reputation.
6.  `registerAIModel(string calldata _metadataURI)`: Allows AI developers to register a new AI Model by staking `EMNET` tokens and minting an `AIModel` NFT.
7.  `deregisterAIModel(uint256 _modelId)`: Initiates the process to remove an AI Model, unstake `EMNET`, and burn the NFT (subject to a cooldown and potential penalties).
8.  `submitModelInsight(uint256 _modelId, uint256 _requestId, bytes calldata _insightHash)`: AI Models submit their analysis/insight in response to a data request.
9.  `claimAIModelRewards(uint256 _modelId)`: Allows AI Model developers to claim rewards based on their model's accuracy and utility.

**II. Data & Insight Marketplace:**
10. `requestDataInsight(string calldata _query, uint256 _paymentAmount)`: Consumers initiate a request for specific environmental insights, paying `EMNET` tokens.
11. `retrieveDataInsight(uint256 _requestId)`: Consumers retrieve the verified insights provided by AI Models for their request.

**III. Reputation & Quality Control:**
12. `updateSensorReputationScore(uint256 _nodeId, int256 _changeAmount)`: DAO-controlled function to adjust a Sensor Node's reputation based on data quality, uptime, etc.
13. `updateAIModelReputationScore(uint256 _modelId, int256 _changeAmount)`: DAO-controlled function to adjust an AI Model's reputation based on insight accuracy and reliability.
14. `slashStake(address _participantAddress, uint256 _amount)`: DAO-controlled function to penalize malicious or underperforming participants by reducing their staked `EMNET`.
15. `getParticipantReputation(address _participantAddress)`: Retrieves the overall reputation score of a participant (sum of their node/model reputations).

**IV. DAO Governance & Administration:**
16. `proposeParameterChange(string calldata _description, bytes calldata _callData, address _targetContract)`: Allows eligible stakers to propose changes to network parameters or contract interactions.
17. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows stakers to cast votes on active proposals.
18. `executeProposal(uint256 _proposalId)`: Executes a passed proposal, applying the proposed changes.
19. `submitDispute(uint256 _contextId, DisputeType _type, string calldata _reason)`: Users can submit disputes regarding data quality, AI model accuracy, or slashing actions.
20. `resolveDispute(uint256 _disputeId, bool _isAccepted, int256 _reputationPenalty)`: DAO-controlled function to resolve disputes, potentially adjusting reputation or slasing stakes.
21. `setDAOAddress(address _newDAOAddress)`: Allows the current DAO to transfer control to a new DAO contract.
22. `setExternalOracleAddress(address _newOracle)`: Sets the address of an oracle contract for external data verification.
23. `emergencyPause()`: Allows the DAO (or a multi-sig admin initially) to pause critical contract functions in an emergency.
24. `emergencyUnpause()`: Unpauses the contract functions.

**V. Advanced / Utility:**
25. `delegateVotingPower(address _delegatee)`: Allows stakers to delegate their voting power to another address.
26. `transferERC20(address _tokenAddress, address _to, uint256 _amount)`: Generic function for the DAO to manage/transfer other ERC-20 tokens held by the contract.
27. `updateNodeMetadata(uint256 _nodeId, string calldata _newURI)`: Allows Sensor Node owner to update its metadata URI.
28. `updateModelMetadata(uint256 _modelId, string calldata _newURI)`: Allows AI Model owner to update its metadata URI.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For efficient tracking of participant addresses

/**
 * @title EcoSenseNet
 * @dev Decentralized Autonomous Environmental Monitoring Network (EcoSenseNet)
 *      This contract orchestrates a network of physical sensor nodes and AI models
 *      to collect, analyze, and provide insights on environmental data. It features
 *      dynamic NFTs for sensors and AI models, a reputation system, staking,
 *      and DAO governance.
 *
 * @outline
 * I. Core Network Operations & Staking:
 *    - constructor(): Initializes tokens, NFTs, and initial parameters.
 *    - registerSensorNode(): Registers a new sensor, stakes EMNET, mints SensorNode NFT.
 *    - deregisterSensorNode(): Removes a sensor, unstakes EMNET, burns NFT.
 *    - updateSensorData(): Sensor operator submits encrypted data hash.
 *    - claimSensorRewards(): Claim EMNET rewards based on sensor performance.
 *    - registerAIModel(): Registers a new AI model, stakes EMNET, mints AIModel NFT.
 *    - deregisterAIModel(): Removes an AI model, unstakes EMNET, burns NFT.
 *    - submitModelInsight(): AI model submits analysis in response to a data request.
 *    - claimAIModelRewards(): Claim EMNET rewards based on AI model accuracy/utility.
 *
 * II. Data & Insight Marketplace:
 *    - requestDataInsight(): Consumer pays EMNET to request specific insights.
 *    - retrieveDataInsight(): Consumer retrieves verified insights.
 *
 * III. Reputation & Quality Control:
 *    - updateSensorReputationScore(): DAO adjusts sensor reputation.
 *    - updateAIModelReputationScore(): DAO adjusts AI model reputation.
 *    - slashStake(): DAO penalizes participants by reducing staked EMNET.
 *    - getParticipantReputation(): Retrieves total reputation for an address.
 *
 * IV. DAO Governance & Administration:
 *    - proposeParameterChange(): Stakers propose network parameter changes.
 *    - voteOnProposal(): Stakers vote on active proposals.
 *    - executeProposal(): Executes a passed proposal.
 *    - submitDispute(): Users submit disputes (data quality, AI accuracy, slashing).
 *    - resolveDispute(): DAO resolves disputes, adjusting reputation/stakes.
 *    - setDAOAddress(): Transfers DAO control to a new contract.
 *    - setExternalOracleAddress(): Sets address for external data verification oracle.
 *    - emergencyPause(): Pauses critical functions in emergencies.
 *    - emergencyUnpause(): Unpauses functions.
 *
 * V. Advanced / Utility:
 *    - delegateVotingPower(): Allows stakers to delegate voting power.
 *    - transferERC20(): Generic DAO function to manage other ERC-20 tokens.
 *    - updateNodeMetadata(): Sensor owner updates NFT metadata URI.
 *    - updateModelMetadata(): AI model owner updates NFT metadata URI.
 */

// Custom ERC20 for EMNET Token
contract EMNETToken is ERC20Burnable {
    constructor(uint256 initialSupply) ERC20("EcoSenseNet Token", "EMNET") {
        _mint(msg.sender, initialSupply);
    }
}

// Custom ERC721 for Sensor Nodes
contract SensorNodeNFT is ERC721 {
    struct Sensor {
        address owner;
        uint256 stakedAmount;
        int256 reputation; // Can be negative
        uint256 lastDataTimestamp;
        bytes lastDataHash;
        uint256 deregisterCooldownEnd;
        string metadataURI; // Stores a link to off-chain dynamic metadata
    }

    mapping(uint256 => Sensor) public sensors;
    uint256 public nextSensorId; // Tracks the next available sensor ID

    constructor() ERC721("EcoSenseNet Sensor Node", "ESN") {}

    function mintSensor(address to, uint256 stakedAmount, string calldata metadataURI) external returns (uint256) {
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
        uint256 tokenId = nextSensorId++;
        _safeMint(to, tokenId);
        sensors[tokenId] = Sensor({
            owner: to,
            stakedAmount: stakedAmount,
            reputation: 0,
            lastDataTimestamp: 0,
            lastDataHash: "",
            deregisterCooldownEnd: 0,
            metadataURI: metadataURI
        });
        _setTokenURI(tokenId, metadataURI);
        return tokenId;
    }

    function burnSensor(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to burn");
        delete sensors[tokenId];
        _burn(tokenId);
    }

    // Function to update the metadata URI, reflecting dynamic state changes
    function updateTokenURI(uint256 tokenId, string calldata newURI) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to update URI");
        sensors[tokenId].metadataURI = newURI;
        _setTokenURI(tokenId, newURI);
    }

    // Override tokenURI to ensure it always points to the dynamic URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Use internal OpenZeppelin check
        return sensors[tokenId].metadataURI;
    }
}

// Custom ERC721 for AI Models
contract AIModelNFT is ERC721 {
    struct AIModel {
        address owner;
        uint256 stakedAmount;
        int256 reputation; // Can be negative
        uint256 lastSubmissionTimestamp;
        uint256 totalInsightsProvided;
        uint256 verifiedAccurateInsights;
        uint256 deregisterCooldownEnd;
        string metadataURI; // Stores a link to off-chain dynamic metadata
    }

    mapping(uint256 => AIModel) public aiModels;
    uint256 public nextModelId; // Tracks the next available AI model ID

    constructor() ERC721("EcoSenseNet AI Model", "EAIM") {}

    function mintAIModel(address to, uint256 stakedAmount, string calldata metadataURI) external returns (uint256) {
        require(bytes(metadataURI).length > 0, "Metadata URI cannot be empty");
        uint256 tokenId = nextModelId++;
        _safeMint(to, tokenId);
        aiModels[tokenId] = AIModel({
            owner: to,
            stakedAmount: stakedAmount,
            reputation: 0,
            lastSubmissionTimestamp: 0,
            totalInsightsProvided: 0,
            verifiedAccurateInsights: 0,
            deregisterCooldownEnd: 0,
            metadataURI: metadataURI
        });
        _setTokenURI(tokenId, metadataURI);
        return tokenId;
    }

    function burnAIModel(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to burn");
        delete aiModels[tokenId];
        _burn(tokenId);
    }

    // Function to update the metadata URI, reflecting dynamic state changes
    function updateTokenURI(uint256 tokenId, string calldata newURI) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized to update URI");
        aiModels[tokenId].metadataURI = newURI;
        _setTokenURI(tokenId, newURI);
    }

    // Override tokenURI to ensure it always points to the dynamic URI
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return aiModels[tokenId].metadataURI;
    }
}


contract EcoSenseNet is Ownable, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // Tokens and NFTs
    EMNETToken public EMNET_TOKEN;
    SensorNodeNFT public SENSOR_NODE_NFT;
    AIModelNFT public AI_MODEL_NFT;

    // --- Network Parameters (Governed by DAO) ---
    uint256 public constant INITIAL_EMNET_SUPPLY = 100_000_000 * 10**18; // 100M EMNET
    uint256 public minSensorStake;
    uint256 public minAIModelStake;
    uint256 public sensorDeregisterCooldown; // In seconds
    uint256 public aiModelDeregisterCooldown; // In seconds
    uint256 public sensorRewardPerDataPoint; // EMNET per valid data submission
    uint256 public aiModelRewardPerInsight; // EMNET per accurate insight
    uint256 public dataRequestFeeMultiplier; // Multiplier for data request cost
    uint256 public proposalQuorumFraction; // E.g., 500 = 50%
    uint256 public proposalVotingPeriod; // In seconds
    uint256 public minReputationForProposal; // Min reputation to create a proposal

    // --- DAO & Governance ---
    address public daoAddress; // Initially owner, then can be set to a DAO contract
    uint256 public nextProposalId;
    uint256 public nextRequestId;
    uint256 public nextDisputeId;

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    struct Proposal {
        uint256 id;
        string description;
        address targetContract;
        bytes callData;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        EnumerableSet.AddressSet voters; // Keep track of who voted
        ProposalState state;
        bool executed;
    }
    mapping(uint256 => Proposal) public proposals;

    enum DisputeType { SensorDataQuality, AIModelAccuracy, StakingSlash }
    enum DisputeStatus { Open, ResolvedAccepted, ResolvedRejected }
    struct Dispute {
        uint256 id;
        address creator;
        uint256 contextId; // e.g., sensorId, requestId, participantAddress
        DisputeType disputeType;
        string reason;
        DisputeStatus status;
        int256 reputationPenalty; // If dispute is accepted and a penalty applies
        address[] jury; // Placeholder for a more advanced jury system
    }
    mapping(uint256 => Dispute) public disputes;

    // --- Reputation System ---
    mapping(address => int256) public participantOverallReputation;
    mapping(address => uint256) public participantVotingPower; // Based on total stake + reputation

    // --- Data Requests ---
    enum RequestStatus { Pending, Processing, Completed, Rejected }
    struct DataRequest {
        address requester;
        uint256 paymentAmount;
        string query;
        uint256 completionTimestamp;
        bytes insightHash; // Hash of the final, verified insight
        RequestStatus status;
        uint256 winningModelId;
    }
    mapping(uint256 => DataRequest) public dataRequests;

    // --- External Oracles ---
    address public externalOracleAddress; // For data validation or AI verification

    // --- Events ---
    event SensorNodeRegistered(uint256 indexed nodeId, address indexed owner, uint256 stakedAmount, string metadataURI);
    event SensorNodeDeregisterRequested(uint256 indexed nodeId, address indexed owner, uint256 cooldownEnd);
    event SensorNodeDeregistered(uint256 indexed nodeId, address indexed owner, uint256 unstakedAmount);
    event SensorDataUpdated(uint256 indexed nodeId, address indexed sender, bytes dataHash, string dataType, uint256 timestamp);
    event SensorRewardsClaimed(uint256 indexed nodeId, address indexed owner, uint256 amount);
    event AIModelRegistered(uint256 indexed modelId, address indexed owner, uint256 stakedAmount, string metadataURI);
    event AIModelDeregisterRequested(uint256 indexed modelId, address indexed owner, uint256 cooldownEnd);
    event AIModelDeregistered(uint256 indexed modelId, address indexed owner, uint256 unstakedAmount);
    event AIModelInsightSubmitted(uint256 indexed modelId, uint256 indexed requestId, bytes insightHash);
    event AIModelRewardsClaimed(uint256 indexed modelId, address indexed owner, uint256 amount);

    event DataInsightRequested(uint256 indexed requestId, address indexed requester, string query, uint256 paymentAmount);
    event DataInsightRetrieved(uint256 indexed requestId, address indexed requester, bytes insightHash);

    event ReputationUpdated(address indexed participant, int256 newReputation);
    event StakeSlashed(address indexed participant, uint256 amount);

    event ProposalCreated(uint256 indexed proposalId, address indexed creator, string description, uint256 votingDeadline);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votePower);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor);

    event DisputeSubmitted(uint256 indexed disputeId, address indexed creator, uint256 contextId, DisputeType disputeType);
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status, int256 reputationPenalty);

    event DAOAddressSet(address indexed oldAddress, address indexed newAddress);
    event ExternalOracleAddressSet(address indexed oldAddress, address indexed newAddress);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event VotingPowerDelegated(address indexed delegator, address indexed delegatee);
    event MetadataURIUpdated(uint256 indexed tokenId, string newURI);

    // --- Modifiers ---
    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call this function");
        _;
    }

    modifier onlySensorOwner(uint256 _nodeId) {
        require(SENSOR_NODE_NFT.ownerOf(_nodeId) == msg.sender, "Only sensor owner can call this function");
        _;
    }

    modifier onlyAIModelOwner(uint256 _modelId) {
        require(AI_MODEL_NFT.ownerOf(_modelId) == msg.sender, "Only AI model owner can call this function");
        _;
    }

    constructor() Ownable(msg.sender) Pausable() {
        // Initialize EMNET Token
        EMNET_TOKEN = new EMNETToken(INITIAL_EMNET_SUPPLY);
        // Transfer initial supply to this contract for staking and rewards
        require(EMNET_TOKEN.transfer(address(this), INITIAL_EMNET_SUPPLY), "Failed to transfer initial EMNET to contract");

        // Initialize NFT contracts
        SENSOR_NODE_NFT = new SensorNodeNFT();
        AI_MODEL_NFT = new AIModelNFT();

        // Initial DAO address set to contract deployer
        daoAddress = msg.sender;

        // Set initial network parameters (can be changed by DAO later)
        minSensorStake = 100 * 10**18; // 100 EMNET
        minAIModelStake = 500 * 10**18; // 500 EMNET
        sensorDeregisterCooldown = 7 days;
        aiModelDeregisterCooldown = 14 days;
        sensorRewardPerDataPoint = 1 * 10**18; // 1 EMNET
        aiModelRewardPerInsight = 5 * 10**18; // 5 EMNET
        dataRequestFeeMultiplier = 1; // 1x payment amount
        proposalQuorumFraction = 500; // 50%
        proposalVotingPeriod = 3 days;
        minReputationForProposal = 100; // Require some reputation to propose

        externalOracleAddress = address(0); // Set later by DAO
    }

    // --- I. Core Network Operations & Staking ---

    /**
     * @dev Allows users to register a new Sensor Node by staking EMNET tokens.
     *      Mints a SensorNode NFT representing the physical sensor.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., sensor type, location, specs).
     */
    function registerSensorNode(string calldata _metadataURI) external payable whenNotPaused returns (uint256) {
        require(msg.value >= minSensorStake, "Insufficient EMNET staked for sensor registration");
        require(EMNET_TOKEN.transferFrom(msg.sender, address(this), msg.value), "EMNET transfer failed");

        uint256 nodeId = SENSOR_NODE_NFT.mintSensor(msg.sender, msg.value, _metadataURI);
        // Update participant's reputation with a small positive bias for joining
        _updateParticipantReputation(msg.sender, 1);
        emit SensorNodeRegistered(nodeId, msg.sender, msg.value, _metadataURI);
        return nodeId;
    }

    /**
     * @dev Initiates the deregistration process for a Sensor Node.
     *      Sets a cooldown period before the staked EMNET can be fully unstaked.
     * @param _nodeId The ID of the SensorNode NFT to deregister.
     */
    function deregisterSensorNode(uint256 _nodeId) external onlySensorOwner(_nodeId) whenNotPaused {
        SensorNodeNFT.Sensor storage sensor = SENSOR_NODE_NFT.sensors(_nodeId);
        require(sensor.deregisterCooldownEnd == 0 || sensor.deregisterCooldownEnd <= block.timestamp, "Sensor already in deregistration cooldown or active");

        sensor.deregisterCooldownEnd = block.timestamp + sensorDeregisterCooldown;
        emit SensorNodeDeregisterRequested(_nodeId, msg.sender, sensor.deregisterCooldownEnd);
    }

    /**
     * @dev Completes the deregistration process for a Sensor Node after the cooldown.
     *      Unstakes EMNET tokens and burns the SensorNode NFT.
     * @param _nodeId The ID of the SensorNode NFT to finalize deregistration.
     */
    function finalizeSensorDeregistration(uint256 _nodeId) external onlySensorOwner(_nodeId) whenNotPaused {
        SensorNodeNFT.Sensor storage sensor = SENSOR_NODE_NFT.sensors(_nodeId);
        require(sensor.deregisterCooldownEnd > 0, "Sensor not in deregistration process");
        require(sensor.deregisterCooldownEnd <= block.timestamp, "Deregistration cooldown not over yet");

        uint256 unstakeAmount = sensor.stakedAmount;
        SENSOR_NODE_NFT.burnSensor(_nodeId);
        require(EMNET_TOKEN.transfer(msg.sender, unstakeAmount), "Failed to return staked EMNET");
        _updateParticipantReputation(msg.sender, -1); // Small negative for leaving
        emit SensorNodeDeregistered(_nodeId, msg.sender, unstakeAmount);
    }

    /**
     * @dev Sensor operators submit a hash of their encrypted environmental data.
     *      This function does not store the actual data on-chain for gas efficiency and privacy.
     *      The `externalOracleAddress` is expected to verify the data's integrity off-chain.
     * @param _nodeId The ID of the SensorNode.
     * @param _encryptedDataHash Hash of the encrypted environmental data.
     * @param _dataType Type of data (e.g., "temperature", "humidity", "air_quality").
     */
    function updateSensorData(uint256 _nodeId, bytes calldata _encryptedDataHash, string calldata _dataType) external onlySensorOwner(_nodeId) whenNotPaused {
        SensorNodeNFT.Sensor storage sensor = SENSOR_NODE_NFT.sensors(_nodeId);
        require(sensor.deregisterCooldownEnd == 0, "Cannot update data while deregistration is active");

        sensor.lastDataTimestamp = block.timestamp;
        sensor.lastDataHash = _encryptedDataHash;

        // Rewards for data submission - actual reward amount depends on verification by oracle/DAO
        // For now, assume good data quality, adjust reputation later with _updateSensorReputationScore
        EMNET_TOKEN.transfer(msg.sender, sensorRewardPerDataPoint);
        _updateParticipantReputation(msg.sender, 1); // Provisional reputation increase
        emit SensorDataUpdated(_nodeId, msg.sender, _encryptedDataHash, _dataType, block.timestamp);
    }

    /**
     * @dev Allows Sensor Node operators to claim accumulated rewards.
     *      Rewards are based on data submissions and reputation.
     *      Note: This is a simplified example. A more complex system would track
     *      claimable rewards instead of just giving per data point.
     * @param _nodeId The ID of the SensorNode to claim rewards for.
     */
    function claimSensorRewards(uint256 _nodeId) external onlySensorOwner(_nodeId) whenNotPaused {
        // In a real system, there would be a more sophisticated reward calculation
        // based on verifiable data quality, uptime, and network demand.
        // For this demo, rewards are primarily distributed upon data submission.
        // This function could be expanded to include other forms of rewards.
        revert("Rewards are currently primarily distributed upon data submission. This function is a placeholder for future complex reward systems.");
    }

    /**
     * @dev Allows AI developers to register a new AI Model by staking EMNET tokens.
     *      Mints an AIModel NFT representing the AI algorithm.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., model type, capabilities, training data).
     */
    function registerAIModel(string calldata _metadataURI) external payable whenNotPaused returns (uint256) {
        require(msg.value >= minAIModelStake, "Insufficient EMNET staked for AI model registration");
        require(EMNET_TOKEN.transferFrom(msg.sender, address(this), msg.value), "EMNET transfer failed");

        uint256 modelId = AI_MODEL_NFT.mintAIModel(msg.sender, msg.value, _metadataURI);
        _updateParticipantReputation(msg.sender, 5); // Higher initial reputation for AI models
        emit AIModelRegistered(modelId, msg.sender, msg.value, _metadataURI);
        return modelId;
    }

    /**
     * @dev Initiates the deregistration process for an AI Model.
     *      Sets a cooldown period before the staked EMNET can be fully unstaked.
     * @param _modelId The ID of the AIModel NFT to deregister.
     */
    function deregisterAIModel(uint256 _modelId) external onlyAIModelOwner(_modelId) whenNotPaused {
        AIModelNFT.AIModel storage model = AI_MODEL_NFT.aiModels(_modelId);
        require(model.deregisterCooldownEnd == 0 || model.deregisterCooldownEnd <= block.timestamp, "AI Model already in deregistration cooldown or active");

        model.deregisterCooldownEnd = block.timestamp + aiModelDeregisterCooldown;
        emit AIModelDeregisterRequested(_modelId, msg.sender, model.deregisterCooldownEnd);
    }

    /**
     * @dev Completes the deregistration process for an AI Model after the cooldown.
     *      Unstakes EMNET tokens and burns the AIModel NFT.
     * @param _modelId The ID of the AIModel NFT to finalize deregistration.
     */
    function finalizeAIModelDeregistration(uint256 _modelId) external onlyAIModelOwner(_modelId) whenNotPaused {
        AIModelNFT.AIModel storage model = AI_MODEL_NFT.aiModels(_modelId);
        require(model.deregisterCooldownEnd > 0, "AI Model not in deregistration process");
        require(model.deregisterCooldownEnd <= block.timestamp, "Deregistration cooldown not over yet");

        uint256 unstakeAmount = model.stakedAmount;
        AI_MODEL_NFT.burnAIModel(_modelId);
        require(EMNET_TOKEN.transfer(msg.sender, unstakeAmount), "Failed to return staked EMNET");
        _updateParticipantReputation(msg.sender, -5); // Small negative for leaving
        emit AIModelDeregistered(_modelId, msg.sender, unstakeAmount);
    }

    /**
     * @dev AI Models submit their analysis/insight in response to a data request.
     *      The actual insight is stored off-chain, and a hash is submitted for verification.
     * @param _modelId The ID of the AIModel.
     * @param _requestId The ID of the data request this insight is for.
     * @param _insightHash Hash of the AI-generated insight.
     */
    function submitModelInsight(uint256 _modelId, uint256 _requestId, bytes calldata _insightHash) external onlyAIModelOwner(_modelId) whenNotPaused {
        AIModelNFT.AIModel storage model = AI_MODEL_NFT.aiModels(_modelId);
        DataRequest storage req = dataRequests[_requestId];

        require(model.deregisterCooldownEnd == 0, "Cannot submit insights while deregistration is active");
        require(req.status == RequestStatus.Pending, "Data request not pending or already fulfilled");
        require(bytes(_insightHash).length > 0, "Insight hash cannot be empty");

        model.lastSubmissionTimestamp = block.timestamp;
        model.totalInsightsProvided++;

        // In a real system, the winning model would be determined by an oracle or DAO
        // based on accuracy and speed. For now, first valid submission wins.
        req.insightHash = _insightHash;
        req.completionTimestamp = block.timestamp;
        req.status = RequestStatus.Completed;
        req.winningModelId = _modelId;

        // Rewards are claimed separately after verification
        emit AIModelInsightSubmitted(_modelId, _requestId, _insightHash);
    }

    /**
     * @dev Allows AI Model developers to claim rewards based on their model's accuracy and utility.
     *      This function would typically be called after an oracle or DAO has verified the insight.
     * @param _modelId The ID of the AIModel.
     */
    function claimAIModelRewards(uint256 _modelId) external onlyAIModelOwner(_modelId) whenNotPaused {
        AIModelNFT.AIModel storage model = AI_MODEL_NFT.aiModels(_modelId);

        // In a more complex system, this would track specific claimable rewards.
        // For this demo, let's assume `verifiedAccurateInsights` directly corresponds to claimable rewards.
        uint256 claimableAmount = model.verifiedAccurateInsights * aiModelRewardPerInsight;
        require(claimableAmount > 0, "No claimable rewards for this model");

        model.verifiedAccurateInsights = 0; // Reset after claiming
        require(EMNET_TOKEN.transfer(msg.sender, claimableAmount), "Failed to transfer EMNET rewards");
        emit AIModelRewardsClaimed(_modelId, msg.sender, claimableAmount);
    }

    // --- II. Data & Insight Marketplace ---

    /**
     * @dev Consumers initiate a request for specific environmental insights.
     *      They pay EMNET tokens which are held by the contract until an insight is provided.
     * @param _query A description of the environmental insight requested.
     * @param _paymentAmount The EMNET amount the consumer is willing to pay.
     */
    function requestDataInsight(string calldata _query, uint256 _paymentAmount) external whenNotPaused returns (uint256) {
        require(_paymentAmount > 0, "Payment amount must be greater than zero");
        require(EMNET_TOKEN.transferFrom(msg.sender, address(this), _paymentAmount), "EMNET transfer failed for data request");

        uint256 requestId = nextRequestId++;
        dataRequests[requestId] = DataRequest({
            requester: msg.sender,
            paymentAmount: _paymentAmount,
            query: _query,
            completionTimestamp: 0,
            insightHash: "",
            status: RequestStatus.Pending,
            winningModelId: 0
        });
        emit DataInsightRequested(requestId, msg.sender, _query, _paymentAmount);
        return requestId;
    }

    /**
     * @dev Consumers retrieve the verified insights provided by AI Models for their request.
     * @param _requestId The ID of the data request.
     */
    function retrieveDataInsight(uint256 _requestId) external view whenNotPaused returns (bytes memory) {
        DataRequest storage req = dataRequests[_requestId];
        require(req.requester == msg.sender, "Only requester can retrieve insight");
        require(req.status == RequestStatus.Completed, "Insight not yet completed or verified");

        emit DataInsightRetrieved(_requestId, msg.sender, req.insightHash);
        return req.insightHash; // Returns the hash, actual insight fetched off-chain
    }

    // --- III. Reputation & Quality Control ---

    /**
     * @dev DAO-controlled function to adjust a Sensor Node's reputation.
     *      This would typically be based on oracle verification of data quality, consistency, or uptime.
     * @param _nodeId The ID of the SensorNode.
     * @param _changeAmount The amount to change the reputation by (can be positive or negative).
     */
    function updateSensorReputationScore(uint256 _nodeId, int256 _changeAmount) external onlyDAO whenNotPaused {
        SensorNodeNFT.Sensor storage sensor = SENSOR_NODE_NFT.sensors(_nodeId);
        sensor.reputation += _changeAmount;
        _updateParticipantReputation(sensor.owner, _changeAmount);
        emit ReputationUpdated(sensor.owner, participantOverallReputation[sensor.owner]);
    }

    /**
     * @dev DAO-controlled function to adjust an AI Model's reputation.
     *      This would typically be based on oracle verification of insight accuracy and reliability.
     * @param _modelId The ID of the AIModel.
     * @param _changeAmount The amount to change the reputation by (can be positive or negative).
     */
    function updateAIModelReputationScore(uint256 _modelId, int256 _changeAmount) external onlyDAO whenNotPaused {
        AIModelNFT.AIModel storage model = AI_MODEL_NFT.aiModels(_modelId);
        model.reputation += _changeAmount;
        _updateParticipantReputation(model.owner, _changeAmount);

        // If reputation is positive and insight was for a request, reward the model
        if (_changeAmount > 0 && dataRequests[nextRequestId - 1].winningModelId == _modelId) {
            model.verifiedAccurateInsights++; // Increment for reward claim
            uint256 paymentFromRequest = dataRequests[nextRequestId - 1].paymentAmount;
            // Transfer portion of request payment to winning model
            require(EMNET_TOKEN.transfer(model.owner, paymentFromRequest * aiModelRewardPerInsight / dataRequestFeeMultiplier), "Failed to transfer AI model insight reward");
        }
        emit ReputationUpdated(model.owner, participantOverallReputation[model.owner]);
    }

    /**
     * @dev Internal function to update a participant's overall reputation.
     *      This aggregates reputation from all their owned nodes/models.
     * @param _participant The address of the participant.
     * @param _changeAmount The amount to change the overall reputation by.
     */
    function _updateParticipantReputation(address _participant, int256 _changeAmount) internal {
        participantOverallReputation[_participant] += _changeAmount;
        participantVotingPower[_participant] = EMNET_TOKEN.balanceOf(_participant) + uint256(participantOverallReputation[_participant] > 0 ? participantOverallReputation[_participant] : 0);
    }

    /**
     * @dev DAO-controlled function to penalize malicious or underperforming participants
     *      by reducing their staked EMNET.
     * @param _participantAddress The address of the participant to slash.
     * @param _amount The amount of EMNET to slash from their stake.
     */
    function slashStake(address _participantAddress, uint256 _amount) external onlyDAO whenNotPaused {
        // This function would need to identify which stake (sensor/model) to slash
        // and adjust the NFT's stakedAmount accordingly. For simplicity, we'll
        // assume it reduces their overall EMNET balance or a generic "locked stake".
        // In a real system, you'd iterate through their owned NFTs and reduce stakes.
        require(EMNET_TOKEN.balanceOf(_participantAddress) >= _amount, "Participant does not have enough staked EMNET to slash");
        EMNET_TOKEN.burn( _amount); // Burn the slashed tokens
        _updateParticipantReputation(_participantAddress, -10); // Significant reputation hit
        emit StakeSlashed(_participantAddress, _amount);
    }

    /**
     * @dev Retrieves the overall reputation score of a participant.
     * @param _participantAddress The address of the participant.
     * @return The participant's overall reputation score.
     */
    function getParticipantReputation(address _participantAddress) external view returns (int256) {
        return participantOverallReputation[_participantAddress];
    }

    // --- IV. DAO Governance & Administration ---

    /**
     * @dev Allows eligible stakers to propose changes to network parameters or contract interactions.
     * @param _description A clear description of the proposal.
     * @param _callData The encoded function call to be executed if the proposal passes.
     * @param _targetContract The address of the contract to call if the proposal passes.
     */
    function proposeParameterChange(string calldata _description, bytes calldata _callData, address _targetContract) external whenNotPaused returns (uint256) {
        require(participantOverallReputation[msg.sender] >= minReputationForProposal, "Not enough reputation to create a proposal");
        require(bytes(_description).length > 0, "Proposal description cannot be empty");
        require(_targetContract != address(0), "Target contract cannot be zero address");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            votingDeadline: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            voters: EnumerableSet.AddressSet(0),
            state: ProposalState.Active,
            executed: false
        });
        emit ProposalCreated(proposalId, msg.sender, _description, proposals[proposalId].votingDeadline);
        return proposalId;
    }

    /**
     * @dev Allows stakers to cast votes on active proposals.
     *      Voting power is based on the participant's overall stake + reputation.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.voters.contains(msg.sender), "Already voted on this proposal");

        uint256 voterPower = participantVotingPower[msg.sender];
        require(voterPower > 0, "No voting power");

        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }
        proposal.voters.add(msg.sender);
        emit Voted(_proposalId, msg.sender, _support, voterPower);
    }

    /**
     * @dev Executes a passed proposal. Only callable after the voting period ends and quorum is met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Proposal not active");
        require(block.timestamp > proposal.votingDeadline, "Voting period not over yet");
        require(!proposal.executed, "Proposal already executed");

        uint256 totalVotingPower = EMNET_TOKEN.totalSupply(); // Simplified: using total supply for quorum calculation
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 requiredQuorum = totalVotingPower * proposalQuorumFraction / 1000; // E.g., 500/1000 = 50%

        if (totalVotes >= requiredQuorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
            // Execute the proposed action
            (bool success,) = proposal.targetContract.call(proposal.callData);
            require(success, "Proposal execution failed");
            proposal.executed = true;
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId, msg.sender);
        } else {
            proposal.state = ProposalState.Failed;
            revert("Proposal failed to meet quorum or pass requirements");
        }
    }

    /**
     * @dev Users can submit disputes regarding data quality, AI model accuracy, or slashing actions.
     * @param _contextId The ID of the relevant context (e.g., sensorId, requestId, participant address).
     * @param _type The type of dispute.
     * @param _reason A description of the dispute.
     */
    function submitDispute(uint256 _contextId, DisputeType _type, string calldata _reason) external whenNotPaused returns (uint256) {
        require(bytes(_reason).length > 0, "Dispute reason cannot be empty");
        uint256 disputeId = nextDisputeId++;
        disputes[disputeId] = Dispute({
            id: disputeId,
            creator: msg.sender,
            contextId: _contextId,
            disputeType: _type,
            reason: _reason,
            status: DisputeStatus.Open,
            reputationPenalty: 0,
            jury: new address[](0) // Placeholder
        });
        emit DisputeSubmitted(disputeId, msg.sender, _contextId, _type);
        return disputeId;
    }

    /**
     * @dev DAO-controlled function to resolve disputes.
     *      Can result in reputation adjustments or staking penalties.
     * @param _disputeId The ID of the dispute to resolve.
     * @param _isAccepted Whether the dispute claim is accepted as valid.
     * @param _reputationPenalty The reputation change for the implicated party if the dispute is accepted.
     */
    function resolveDispute(uint256 _disputeId, bool _isAccepted, int256 _reputationPenalty) external onlyDAO whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute is not open");

        dispute.status = _isAccepted ? DisputeStatus.ResolvedAccepted : DisputeStatus.ResolvedRejected;
        dispute.reputationPenalty = _reputationPenalty;

        if (_isAccepted) {
            // Apply reputation penalty to the party at fault (contextId)
            // Example: If it's a sensor data quality dispute, penalize the sensor owner.
            if (dispute.disputeType == DisputeType.SensorDataQuality) {
                SensorNodeNFT.Sensor storage sensor = SENSOR_NODE_NFT.sensors(dispute.contextId);
                updateSensorReputationScore(dispute.contextId, _reputationPenalty);
            } else if (dispute.disputeType == DisputeType.AIModelAccuracy) {
                AIModelNFT.AIModel storage model = AI_MODEL_NFT.aiModels(dispute.contextId);
                updateAIModelReputationScore(dispute.contextId, _reputationPenalty);
            } else if (dispute.disputeType == DisputeType.StakingSlash) {
                // Here contextId would be the address of the slashed participant
                slashStake(address(uint160(dispute.contextId)), uint256(-_reputationPenalty)); // Slash tokens
                _updateParticipantReputation(address(uint160(dispute.contextId)), _reputationPenalty);
            }
        }
        emit DisputeResolved(_disputeId, dispute.status, _reputationPenalty);
    }

    /**
     * @dev Allows the current DAO to transfer control to a new DAO contract address.
     * @param _newDAOAddress The address of the new DAO contract.
     */
    function setDAOAddress(address _newDAOAddress) external onlyDAO whenNotPaused {
        require(_newDAOAddress != address(0), "New DAO address cannot be zero");
        emit DAOAddressSet(daoAddress, _newDAOAddress);
        daoAddress = _newDAOAddress;
    }

    /**
     * @dev Sets the address of an external oracle contract used for data verification or AI model evaluation.
     * @param _newOracle The address of the new oracle contract.
     */
    function setExternalOracleAddress(address _newOracle) external onlyDAO whenNotPaused {
        require(_newOracle != address(0), "Oracle address cannot be zero");
        emit ExternalOracleAddressSet(externalOracleAddress, _newOracle);
        externalOracleAddress = _newOracle;
    }

    /**
     * @dev Pauses critical contract functions in an emergency (callable by DAO or owner initially).
     *      Uses OpenZeppelin's Pausable.
     */
    function emergencyPause() external onlyDAO {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses critical contract functions (callable by DAO or owner initially).
     *      Uses OpenZeppelin's Pausable.
     */
    function emergencyUnpause() external onlyDAO {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // --- V. Advanced / Utility ---

    /**
     * @dev Allows stakers to delegate their voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) external whenNotPaused {
        require(_delegatee != address(0), "Delegatee cannot be zero address");
        require(_delegatee != msg.sender, "Cannot delegate to self");

        // Transfer voting power to delegatee (can only delegate once)
        uint256 power = participantVotingPower[msg.sender];
        require(power > 0, "No voting power to delegate");

        participantVotingPower[_delegatee] += power;
        participantVotingPower[msg.sender] = 0; // Remove own voting power
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Generic function for the DAO to manage/transfer other ERC-20 tokens held by the contract.
     * @param _tokenAddress The address of the ERC-20 token.
     * @param _to The recipient address.
     * @param _amount The amount of tokens to transfer.
     */
    function transferERC20(address _tokenAddress, address _to, uint256 _amount) external onlyDAO whenNotPaused {
        ERC20 token = ERC20(_tokenAddress);
        require(token.transfer(_to, _amount), "Failed to transfer ERC20 token");
    }

    /**
     * @dev Allows the owner of a SensorNode NFT to update its metadata URI.
     *      This could reflect real-world changes like maintenance, calibration, or status updates.
     * @param _nodeId The ID of the SensorNode NFT.
     * @param _newURI The new URI for the sensor's metadata.
     */
    function updateNodeMetadata(uint256 _nodeId, string calldata _newURI) external onlySensorOwner(_nodeId) whenNotPaused {
        SENSOR_NODE_NFT.updateTokenURI(_nodeId, _newURI);
        emit MetadataURIUpdated(_nodeId, _newURI);
    }

    /**
     * @dev Allows the owner of an AIModel NFT to update its metadata URI.
     *      This could reflect changes to the model version, training data, or performance metrics.
     * @param _modelId The ID of the AIModel NFT.
     * @param _newURI The new URI for the model's metadata.
     */
    function updateModelMetadata(uint256 _modelId, string calldata _newURI) external onlyAIModelOwner(_modelId) whenNotPaused {
        AI_MODEL_NFT.updateTokenURI(_modelId, _newURI);
        emit MetadataURIUpdated(_modelId, _newURI);
    }
}
```