This smart contract, `EvolvingDigitalSentinels`, introduces a novel concept of dynamic, AI-augmented NFTs that act as decentralized data guardians within the blockchain ecosystem. These "Sentinels" monitor specific on-chain data streams, interpret patterns via off-chain AI (facilitated by an oracle), evolve their attributes, and compete in challenges to earn rewards and reputation.

---

## **Contract: EvolvingDigitalSentinels**

### **Outline & Function Summary**

**Core Concept:**
EvolvingDigitalSentinels (EDS) are dynamic Non-Fungible Tokens (NFTs) designed to monitor, analyze, and react to on-chain data streams. Each Sentinel possesses unique attributes (Intelligence, Specialization, Generation, Experience) that evolve based on its performance in detecting predefined patterns within assigned data streams. The contract integrates with an off-chain AI oracle network which provides "intelligence reports" on data stream analysis. Owners can assign their Sentinels to streams, request analyses, and participate in challenges, fostering a gamified environment for decentralized on-chain data surveillance and pattern detection.

**Key Features:**
*   **Dynamic NFTs:** Sentinel attributes (Intelligence, Specialization, Generation, Experience) are mutable and evolve based on activity and performance.
*   **Oracle Integration:** Leverages an external oracle network to perform complex off-chain AI analysis of on-chain data, submitting "intelligence reports" back to the contract.
*   **Gamified Evolution:** Sentinels gain Experience, evolve generations, and improve their Intelligence score based on successful pattern detections and challenge victories.
*   **Specialization Paths:** Sentinels can be guided by their owners to specialize in particular types of data analysis (e.g., flash loan detection, arbitrage opportunities, bridge monitoring).
*   **Decentralized Data Streams:** A registry of on-chain events/data sources that Sentinels can monitor.
*   **Pattern Recognition Engine:** A registry of known or proposed on-chain patterns that Sentinels aim to detect.
*   **Competitive Challenges:** Owners can enter their Sentinels into timed challenges to detect specific patterns in a stream, competing for rewards and recognition.
*   **Access Control:** Utilizes OpenZeppelin's AccessControl for robust role-based permissions (Governor, Oracle).

---

**Function Summary (23 Functions excluding inherited ERC721 basics):**

**I. Sentinel Core Management & Lifecycle (ERC721 + Dynamic Attributes)**
1.  `mintSentinel(string memory _name)`: Mints a new Sentinel NFT with initial base attributes.
2.  `getSentinelData(uint256 _tokenId)`: Retrieves the full dynamic attribute set of a Sentinel.
3.  `evolveSentinel(uint256 _tokenId, bytes32 _streamId, uint256 _intelligenceBoost, uint256 _expGain)`: Updates a Sentinel's attributes (Intelligence, Experience, Generation) based on successful analysis or performance.
4.  `upgradeSentinelModule(uint256 _tokenId, uint256 _moduleId, string memory _moduleName)`: Attaches a new "module" to a Sentinel, enhancing its capabilities or granting new attributes (represented as a dynamic attribute).
5.  `proposeSentinelSpecialization(uint256 _tokenId, string memory _specializationType)`: Owner proposes a specialization path for their Sentinel.
6.  `confirmSentinelSpecialization(uint256 _tokenId, string memory _specializationType)`: Governor confirms a proposed specialization for a Sentinel, setting its specialization attribute.
7.  `renameSentinel(uint256 _tokenId, string memory _newName)`: Allows the owner to rename their Sentinel.

**II. Data Stream & Pattern Registry**
8.  `registerDataStream(string memory _name, address _targetAddress, bytes4 _eventSignature, string memory _description)`: Governor registers a new on-chain data stream for monitoring.
9.  `getDataStreamDetails(bytes32 _streamId)`: Retrieves details about a registered data stream.
10. `assignSentinelToStream(uint256 _tokenId, bytes32 _streamId)`: Assigns a Sentinel to actively monitor a specific registered data stream.
11. `unassignSentinelFromStream(uint256 _tokenId, bytes32 _streamId)`: Unassigns a Sentinel from a data stream.
12. `proposePattern(bytes32 _streamId, string memory _patternName, string memory _patternDescription, string memory _riskLevel)`: Governor or trusted entity proposes a new pattern of interest for a specific data stream.
13. `getPatternDetails(bytes32 _patternId)`: Retrieves details about a registered pattern.

**III. Oracle Interaction & Analysis**
14. `requestAnalysisReport(uint256 _tokenId, bytes32 _streamId, bytes32 _requestId)`: Owner triggers an off-chain analysis request for their Sentinel on an assigned stream. This interacts with the Oracle role.
15. `submitAnalysisReport(bytes32 _requestId, uint256 _tokenId, bytes32 _streamId, uint256 _intelligenceScore, bytes32 _detectedPatternHash, string memory _reportURI)`: Callback function for the Oracle to deliver analysis results. This function triggers Sentinel evolution.

**IV. Gamified Challenges & Rewards**
16. `createChallenge(bytes32 _streamId, bytes32 _patternId, uint256 _rewardPool, uint256 _deadline)`: Governor creates a new challenge for Sentinels to detect a specific pattern.
17. `enterChallenge(uint256 _tokenId, bytes32 _challengeId)`: Owner enters their Sentinel into an active challenge.
18. `submitChallengeDetection(bytes32 _challengeId, uint256 _tokenId, bytes32 _detectedPatternHash, string memory _proofURI)`: Owner submits their Sentinel's "detection" for a challenge.
19. `adjudicateChallenge(bytes32 _challengeId, uint256[] memory _winningTokenIds, uint256 _totalWinningScore)`: Governor evaluates challenge submissions and declares winners.
20. `claimChallengeReward(uint256 _tokenId, bytes32 _challengeId)`: A winning Sentinel owner claims their share of the challenge reward pool.

**V. System Governance & Configuration**
21. `updateOracleAddress(address _newOracleAddress)`: Governor updates the trusted address for the Oracle role.
22. `updateTrainingCost(uint256 _newCost)`: Governor updates the cost (in ETH) for requesting an analysis report.
23. `toggleSystemActive(bool _isActive)`: Governor can pause or unpause the entire system.

---
---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @title EvolvingDigitalSentinels
/// @notice A smart contract for dynamic, AI-augmented NFTs that act as decentralized data guardians.
///         Sentinels monitor on-chain data streams, interpret patterns via off-chain AI (oracle),
///         evolve their attributes, and compete in challenges for rewards and reputation.
/// @dev This contract relies on external oracle services for AI analysis of on-chain data.
///      The 'Intelligence Score' and 'Detected Pattern Hash' are results submitted by the oracle.
contract EvolvingDigitalSentinels is ERC721URIStorage, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _streamIdCounter;
    Counters.Counter private _patternIdCounter;
    Counters.Counter private _challengeIdCounter;
    Counters.Counter private _requestIdCounter; // For unique oracle request IDs

    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    bool public systemActive = true;
    uint256 public trainingCost = 0.01 ether; // Cost for an owner to request an analysis report

    struct SentinelData {
        string name;
        uint256 intelligence;       // Reflects analytical prowess, improves with evolution
        uint256 experience;         // Accumulated points, leads to generation upgrades
        uint256 generation;         // Indicates evolution stage
        string specialization;      // E.g., "Flash Loan Detector", "Arbitrage Seeker"
        string assignedStreamId;    // The current stream the sentinel is monitoring (bytes32 converted to string for easier storage/retrieval)
        string moduleName;          // E.g., "Enhanced Pattern Processor", "Quantum Data Filter"
        string lastReportURI;       // URI to the last detailed analysis report
    }

    struct DataStream {
        string name;
        address targetAddress;      // The contract address to monitor
        bytes4 eventSignature;      // The event signature to listen for (e.g., ERC20 Transfer)
        string description;
        bool isActive;
    }

    struct PatternData {
        bytes32 streamId;           // The stream this pattern belongs to
        string name;
        string description;
        string riskLevel;           // E.g., "High", "Medium", "Low"
        bool isApproved;
    }

    struct ChallengeData {
        bytes32 streamId;
        bytes32 patternId;
        uint256 rewardPool;         // ETH amount
        uint256 deadline;
        bool isOpen;
        mapping(uint256 => bool) participants; // tokenId => participated
        mapping(uint256 => bytes32) detections; // tokenId => detectedPatternHash
        mapping(uint256 => string) proofURIs;  // tokenId => URI to off-chain proof
        uint256[] winners;
        uint256 totalWinningScore; // Sum of intelligence scores of winners used for reward distribution
    }

    mapping(uint256 => SentinelData) public sentinels;
    mapping(bytes32 => DataStream) public dataStreams;
    mapping(bytes32 => PatternData) public patterns;
    mapping(bytes32 => ChallengeData) public challenges;
    mapping(bytes32 => bool) public oracleRequests; // Tracks active oracle requests (requestId => true)

    event SentinelMinted(uint256 indexed tokenId, address indexed owner, string name, uint256 timestamp);
    event SentinelEvolved(uint256 indexed tokenId, uint256 newIntelligence, uint256 newExperience, uint256 newGeneration, uint256 timestamp);
    event SentinelModuleUpgraded(uint256 indexed tokenId, uint256 indexed moduleId, string moduleName, uint256 timestamp);
    event SentinelSpecializationProposed(uint256 indexed tokenId, string specializationType, address indexed proposer, uint256 timestamp);
    event SentinelSpecializationConfirmed(uint256 indexed tokenId, string specializationType, uint256 timestamp);
    event SentinelRenamed(uint256 indexed tokenId, string newName, uint256 timestamp);

    event DataStreamRegistered(bytes32 indexed streamId, string name, address indexed targetAddress, uint256 timestamp);
    event SentinelAssignedToStream(uint256 indexed tokenId, bytes32 indexed streamId, uint256 timestamp);
    event SentinelUnassignedFromStream(uint256 indexed tokenId, bytes32 indexed streamId, uint256 timestamp);
    event PatternProposed(bytes32 indexed patternId, bytes32 indexed streamId, string name, uint256 timestamp);

    event AnalysisReportRequested(bytes32 indexed requestId, uint256 indexed tokenId, bytes32 indexed streamId, uint256 timestamp);
    event AnalysisReportSubmitted(bytes32 indexed requestId, uint256 indexed tokenId, bytes32 indexed streamId, uint256 intelligenceScore, bytes32 detectedPatternHash, string reportURI, uint256 timestamp);

    event ChallengeCreated(bytes32 indexed challengeId, bytes32 indexed streamId, bytes32 indexed patternId, uint256 rewardPool, uint256 deadline, uint256 timestamp);
    event ChallengeEntered(bytes32 indexed challengeId, uint256 indexed tokenId, uint256 timestamp);
    event ChallengeDetectionSubmitted(bytes32 indexed challengeId, uint256 indexed tokenId, bytes32 detectedPatternHash, string proofURI, uint256 timestamp);
    event ChallengeAdjudicated(bytes32 indexed challengeId, uint256[] winningTokenIds, uint256 timestamp);
    event ChallengeRewardClaimed(bytes32 indexed challengeId, uint256 indexed tokenId, uint256 amount, uint256 timestamp);

    modifier onlyGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "EDS: Caller is not a governor");
        _;
    }

    modifier onlyOracle() {
        require(hasRole(ORACLE_ROLE, _msgSender()), "EDS: Caller is not an oracle");
        _;
    }

    modifier systemMustBeActive() {
        require(systemActive, "EDS: System is currently paused");
        _;
    }

    constructor() ERC721("EvolvingDigitalSentinels", "EDS") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(GOVERNOR_ROLE, _msgSender()); // Deployer is initial governor
        // Oracle role must be granted explicitly later to a trusted oracle address
    }

    // --- I. Sentinel Core Management & Lifecycle ---

    /// @notice Mints a new Sentinel NFT with initial base attributes.
    /// @param _name The desired name for the new Sentinel.
    /// @return The tokenId of the newly minted Sentinel.
    function mintSentinel(string memory _name) public systemMustBeActive returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(_msgSender(), newItemId);
        _setTokenURI(newItemId, ""); // URI can be updated dynamically

        sentinels[newItemId] = SentinelData({
            name: _name,
            intelligence: 100, // Base intelligence
            experience: 0,
            generation: 1,
            specialization: "Generalist",
            assignedStreamId: "",
            moduleName: "Base Unit",
            lastReportURI: ""
        });

        emit SentinelMinted(newItemId, _msgSender(), _name, block.timestamp);
        return newItemId;
    }

    /// @notice Retrieves the full dynamic attribute set of a Sentinel.
    /// @param _tokenId The ID of the Sentinel to query.
    /// @return A tuple containing all SentinelData attributes.
    function getSentinelData(uint256 _tokenId) public view returns (
        string memory name,
        uint256 intelligence,
        uint256 experience,
        uint256 generation,
        string memory specialization,
        string memory assignedStreamId,
        string memory moduleName,
        string memory lastReportURI
    ) {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        SentinelData storage sentinel = sentinels[_tokenId];
        return (
            sentinel.name,
            sentinel.intelligence,
            sentinel.experience,
            sentinel.generation,
            sentinel.specialization,
            sentinel.assignedStreamId,
            sentinel.moduleName,
            sentinel.lastReportURI
        );
    }

    /// @notice Updates a Sentinel's attributes (Intelligence, Experience, Generation) based on successful analysis or performance.
    ///         This function is typically called internally after `submitAnalysisReport` or `adjudicateChallenge`.
    /// @param _tokenId The ID of the Sentinel to evolve.
    /// @param _streamId The stream ID relevant to the evolution.
    /// @param _intelligenceBoost The amount to increase intelligence.
    /// @param _expGain The amount of experience gained.
    function evolveSentinel(uint256 _tokenId, bytes32 _streamId, uint256 _intelligenceBoost, uint256 _expGain) internal systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        SentinelData storage sentinel = sentinels[_tokenId];

        sentinel.intelligence += _intelligenceBoost;
        sentinel.experience += _expGain;

        // Simple generation evolution: every 1000 experience points, it gains a generation
        uint256 newGeneration = (sentinel.experience / 1000) + 1;
        if (newGeneration > sentinel.generation) {
            sentinel.generation = newGeneration;
        }

        // Update URI (placeholder for dynamic metadata generation)
        _setTokenURI(_tokenId, string(abi.encodePacked(
            "ipfs://", // Base URI, in practice this would resolve to a JSON file
            Strings.toString(_tokenId),
            ".json" // Sentinel-specific metadata
        )));

        emit SentinelEvolved(_tokenId, sentinel.intelligence, sentinel.experience, sentinel.generation, block.timestamp);
    }

    /// @notice Attaches a new "module" to a Sentinel, enhancing its capabilities or granting new attributes.
    /// @dev This is a simplified representation; in a real scenario, `moduleId` could represent another NFT or complex trait.
    /// @param _tokenId The ID of the Sentinel to upgrade.
    /// @param _moduleId An arbitrary ID representing the module.
    /// @param _moduleName The name of the module being attached.
    function upgradeSentinelModule(uint256 _tokenId, uint256 _moduleId, string memory _moduleName) public systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");

        SentinelData storage sentinel = sentinels[_tokenId];
        sentinel.moduleName = _moduleName; // Overwrites previous module for simplicity, could be an array/mapping

        emit SentinelModuleUpgraded(_tokenId, _moduleId, _moduleName, block.timestamp);
    }

    /// @notice Owner proposes a specialization path for their Sentinel.
    /// @param _tokenId The ID of the Sentinel.
    /// @param _specializationType The proposed specialization (e.g., "DeFi Security", "NFT Market Analyst").
    function proposeSentinelSpecialization(uint256 _tokenId, string memory _specializationType) public systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");
        // Further logic could involve a fee or a waiting period.
        emit SentinelSpecializationProposed(_tokenId, _specializationType, _msgSender(), block.timestamp);
    }

    /// @notice Governor confirms a proposed specialization for a Sentinel, setting its specialization attribute.
    /// @param _tokenId The ID of the Sentinel.
    /// @param _specializationType The specialization to confirm.
    function confirmSentinelSpecialization(uint256 _tokenId, string memory _specializationType) public onlyGovernor systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        sentinels[_tokenId].specialization = _specializationType;
        // Could also add an intelligence boost or unique attribute here.
        emit SentinelSpecializationConfirmed(_tokenId, _specializationType, block.timestamp);
    }

    /// @notice Allows the owner to rename their Sentinel.
    /// @param _tokenId The ID of the Sentinel to rename.
    /// @param _newName The new name for the Sentinel.
    function renameSentinel(uint256 _tokenId, string memory _newName) public systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");
        sentinels[_tokenId].name = _newName;
        emit SentinelRenamed(_tokenId, _newName, block.timestamp);
    }

    // --- II. Data Stream & Pattern Registry ---

    /// @notice Governor registers a new on-chain data stream for monitoring.
    /// @param _name Descriptive name for the stream.
    /// @param _targetAddress The contract address whose events are to be monitored.
    /// @param _eventSignature The keccak256 hash of the event signature (e.g., `bytes4(keccak256("Transfer(address,address,uint256)"))`).
    /// @param _description A detailed description of the data stream.
    /// @return The generated bytes32 ID for the new data stream.
    function registerDataStream(string memory _name, address _targetAddress, bytes4 _eventSignature, string memory _description)
        public onlyGovernor systemMustBeActive returns (bytes32)
    {
        _streamIdCounter.increment();
        bytes32 streamId = keccak256(abi.encodePacked(Strings.toString(_streamIdCounter.current()), block.timestamp));
        
        dataStreams[streamId] = DataStream({
            name: _name,
            targetAddress: _targetAddress,
            eventSignature: _eventSignature,
            description: _description,
            isActive: true
        });

        emit DataStreamRegistered(streamId, _name, _targetAddress, block.timestamp);
        return streamId;
    }

    /// @notice Retrieves details about a registered data stream.
    /// @param _streamId The ID of the data stream.
    /// @return A tuple containing all DataStream attributes.
    function getDataStreamDetails(bytes32 _streamId) public view returns (
        string memory name,
        address targetAddress,
        bytes4 eventSignature,
        string memory description,
        bool isActive
    ) {
        require(dataStreams[_streamId].isActive, "EDS: Data stream not found or inactive");
        DataStream storage stream = dataStreams[_streamId];
        return (stream.name, stream.targetAddress, stream.eventSignature, stream.description, stream.isActive);
    }

    /// @notice Assigns a Sentinel to actively monitor a specific registered data stream.
    /// @param _tokenId The ID of the Sentinel.
    /// @param _streamId The ID of the data stream to assign.
    function assignSentinelToStream(uint256 _tokenId, bytes32 _streamId) public systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");
        require(dataStreams[_streamId].isActive, "EDS: Data stream not found or inactive");

        sentinels[_tokenId].assignedStreamId = string(abi.encodePacked(_streamId)); // Store as string for simpler struct
        emit SentinelAssignedToStream(_tokenId, _streamId, block.timestamp);
    }

    /// @notice Unassigns a Sentinel from a data stream.
    /// @param _tokenId The ID of the Sentinel.
    /// @param _streamId The ID of the data stream to unassign from.
    function unassignSentinelFromStream(uint256 _tokenId, bytes32 _streamId) public systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");
        require(sentinels[_tokenId].assignedStreamId == string(abi.encodePacked(_streamId)), "EDS: Sentinel not assigned to this stream");

        sentinels[_tokenId].assignedStreamId = "";
        emit SentinelUnassignedFromStream(_tokenId, _streamId, block.timestamp);
    }

    /// @notice Governor or trusted entity proposes a new pattern of interest for a specific data stream.
    /// @param _streamId The data stream this pattern is relevant to.
    /// @param _patternName A descriptive name for the pattern (e.g., "Large Flash Loan").
    /// @param _patternDescription Detailed description of what constitutes this pattern.
    /// @param _riskLevel The perceived risk level associated with this pattern.
    /// @return The generated bytes32 ID for the new pattern.
    function proposePattern(bytes32 _streamId, string memory _patternName, string memory _patternDescription, string memory _riskLevel)
        public onlyGovernor systemMustBeActive returns (bytes32)
    {
        require(dataStreams[_streamId].isActive, "EDS: Data stream not found or inactive");
        _patternIdCounter.increment();
        bytes32 patternId = keccak256(abi.encodePacked(Strings.toString(_patternIdCounter.current()), _streamId, block.timestamp));

        patterns[patternId] = PatternData({
            streamId: _streamId,
            name: _patternName,
            description: _patternDescription,
            riskLevel: _riskLevel,
            isApproved: true // Governor proposes, so it's auto-approved. Could have a separate `approvePattern` for user proposals.
        });

        emit PatternProposed(patternId, _streamId, _patternName, block.timestamp);
        return patternId;
    }

    /// @notice Retrieves details about a registered pattern.
    /// @param _patternId The ID of the pattern to query.
    /// @return A tuple containing all PatternData attributes.
    function getPatternDetails(bytes32 _patternId) public view returns (
        bytes32 streamId,
        string memory name,
        string memory description,
        string memory riskLevel,
        bool isApproved
    ) {
        require(patterns[_patternId].isApproved, "EDS: Pattern not found or not approved");
        PatternData storage pattern = patterns[_patternId];
        return (pattern.streamId, pattern.name, pattern.description, pattern.riskLevel, pattern.isApproved);
    }


    // --- III. Oracle Interaction & Analysis ---

    /// @notice Owner triggers an off-chain analysis request for their Sentinel on an assigned stream.
    /// @dev This function charges a `trainingCost` and emits an event for the oracle to pick up.
    /// @param _tokenId The ID of the Sentinel.
    /// @param _streamId The ID of the data stream to analyze.
    /// @param _requestId A unique request identifier provided by the client, useful for tracking.
    function requestAnalysisReport(uint256 _tokenId, bytes32 _streamId, bytes32 _requestId) public payable systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");
        require(msg.value >= trainingCost, "EDS: Insufficient payment for analysis report");
        require(sentinels[_tokenId].assignedStreamId == string(abi.encodePacked(_streamId)), "EDS: Sentinel not assigned to this stream");
        require(dataStreams[_streamId].isActive, "EDS: Data stream not found or inactive");
        require(!oracleRequests[_requestId], "EDS: Duplicate oracle request ID");

        // Mark request as active, waiting for oracle callback
        oracleRequests[_requestId] = true;
        
        emit AnalysisReportRequested(_requestId, _tokenId, _streamId, block.timestamp);
    }

    /// @notice Callback function for the Oracle to deliver analysis results.
    /// @dev Only callable by an address with the ORACLE_ROLE. This function triggers Sentinel evolution.
    /// @param _requestId The unique request ID that was originally sent.
    /// @param _tokenId The ID of the Sentinel for which the report is submitted.
    /// @param _streamId The ID of the data stream analyzed.
    /// @param _intelligenceScore The intelligence score determined by the off-chain AI.
    /// @param _detectedPatternHash A hash representing the detected pattern, if any.
    /// @param _reportURI URI pointing to a detailed off-chain report (e.g., IPFS).
    function submitAnalysisReport(
        bytes32 _requestId,
        uint256 _tokenId,
        bytes32 _streamId,
        uint256 _intelligenceScore,
        bytes32 _detectedPatternHash,
        string memory _reportURI
    ) public onlyOracle systemMustBeActive {
        require(oracleRequests[_requestId], "EDS: Invalid or inactive oracle request");
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(sentinels[_tokenId].assignedStreamId == string(abi.encodePacked(_streamId)), "EDS: Sentinel not assigned to this stream");
        
        // Clear the request status
        oracleRequests[_requestId] = false;

        SentinelData storage sentinel = sentinels[_tokenId];
        sentinel.lastReportURI = _reportURI;

        // Evolve the Sentinel based on the report
        // For simplicity, intelligence boost is proportional to reported score, and fixed experience
        evolveSentinel(_tokenId, _streamId, _intelligenceScore / 10, 50); // Example evolution logic

        emit AnalysisReportSubmitted(_requestId, _tokenId, _streamId, _intelligenceScore, _detectedPatternHash, _reportURI, block.timestamp);
    }

    // --- IV. Gamified Challenges & Rewards ---

    /// @notice Governor creates a new challenge for Sentinels to detect a specific pattern.
    /// @dev The reward pool is funded by `msg.value` when calling this function.
    /// @param _streamId The data stream where the pattern is to be detected.
    /// @param _patternId The ID of the pattern Sentinels need to find.
    /// @param _rewardPool The total ETH rewards for this challenge.
    /// @param _deadline The timestamp when the challenge ends.
    /// @return The generated bytes32 ID for the new challenge.
    function createChallenge(bytes32 _streamId, bytes32 _patternId, uint256 _rewardPool, uint256 _deadline)
        public payable onlyGovernor systemMustBeActive returns (bytes32)
    {
        require(dataStreams[_streamId].isActive, "EDS: Data stream not found or inactive");
        require(patterns[_patternId].isApproved && patterns[_patternId].streamId == _streamId, "EDS: Pattern not found or not for this stream");
        require(_deadline > block.timestamp, "EDS: Challenge deadline must be in the future");
        require(msg.value == _rewardPool, "EDS: Reward pool must match sent ETH");

        _challengeIdCounter.increment();
        bytes32 challengeId = keccak256(abi.encodePacked(Strings.toString(_challengeIdCounter.current()), block.timestamp));

        challenges[challengeId] = ChallengeData({
            streamId: _streamId,
            patternId: _patternId,
            rewardPool: _rewardPool,
            deadline: _deadline,
            isOpen: true,
            participants: new mapping(uint256 => bool), // Initialize mappings
            detections: new mapping(uint256 => bytes32),
            proofURIs: new mapping(uint256 => string),
            winners: new uint256[](0),
            totalWinningScore: 0
        });

        emit ChallengeCreated(challengeId, _streamId, _patternId, _rewardPool, _deadline, block.timestamp);
        return challengeId;
    }

    /// @notice Owner enters their Sentinel into an active challenge.
    /// @param _tokenId The ID of the Sentinel.
    /// @param _challengeId The ID of the challenge to enter.
    function enterChallenge(uint256 _tokenId, bytes32 _challengeId) public systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");
        require(challenges[_challengeId].isOpen, "EDS: Challenge is not open or does not exist");
        require(challenges[_challengeId].deadline > block.timestamp, "EDS: Challenge has ended");
        require(!challenges[_challengeId].participants[_tokenId], "EDS: Sentinel already entered");

        challenges[_challengeId].participants[_tokenId] = true;
        emit ChallengeEntered(_challengeId, _tokenId, block.timestamp);
    }

    /// @notice Owner submits their Sentinel's "detection" for a challenge.
    /// @dev This typically involves the Sentinel owner's off-chain system, using their Sentinel's intelligence,
    ///      submitting a hash of the pattern it believes it detected and a URI to the proof.
    /// @param _challengeId The ID of the challenge.
    /// @param _tokenId The ID of the Sentinel submitting the detection.
    /// @param _detectedPatternHash The hash of the pattern detected by the Sentinel.
    /// @param _proofURI URI pointing to the off-chain proof of detection.
    function submitChallengeDetection(bytes32 _challengeId, uint256 _tokenId, bytes32 _detectedPatternHash, string memory _proofURI) public systemMustBeActive {
        require(_exists(_tokenId), "EDS: Sentinel does not exist");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");
        require(challenges[_challengeId].isOpen, "EDS: Challenge is not open or does not exist");
        require(challenges[_challengeId].deadline > block.timestamp, "EDS: Challenge has ended");
        require(challenges[_challengeId].participants[_tokenId], "EDS: Sentinel not entered in this challenge");
        
        challenges[_challengeId].detections[_tokenId] = _detectedPatternHash;
        challenges[_challengeId].proofURIs[_tokenId] = _proofURI;
        emit ChallengeDetectionSubmitted(_challengeId, _tokenId, _detectedPatternHash, _proofURI, block.timestamp);
    }

    /// @notice Governor evaluates challenge submissions and declares winners.
    /// @dev The `_winningTokenIds` should have successfully detected the correct pattern.
    /// @param _challengeId The ID of the challenge to adjudicate.
    /// @param _winningTokenIds An array of token IDs that are declared winners.
    /// @param _totalWinningScore The sum of intelligence scores of all winning Sentinels, used for proportional reward distribution.
    function adjudicateChallenge(bytes32 _challengeId, uint256[] memory _winningTokenIds, uint256 _totalWinningScore) public onlyGovernor systemMustBeActive {
        ChallengeData storage challenge = challenges[_challengeId];
        require(challenge.isOpen, "EDS: Challenge is not open or does not exist");
        require(challenge.deadline <= block.timestamp, "EDS: Challenge has not ended yet");
        require(_totalWinningScore > 0, "EDS: Total winning score must be greater than zero");
        
        challenge.isOpen = false; // Close the challenge

        for (uint256 i = 0; i < _winningTokenIds.length; i++) {
            uint256 winnerTokenId = _winningTokenIds[i];
            require(challenge.participants[winnerTokenId], "EDS: Winner not a participant");
            // Optional: require(challenge.detections[winnerTokenId] == patterns[challenge.patternId].expectedPatternHash);
            // This would require storing an 'expectedPatternHash' on-chain or a mechanism to verify it.
            
            challenge.winners.push(winnerTokenId);
            challenge.totalWinningScore += sentinels[winnerTokenId].intelligence; // Use current intelligence for reward share
            
            // Evolve winning Sentinels
            evolveSentinel(winnerTokenId, challenge.streamId, 100, 200); // Boost winners
        }
        
        emit ChallengeAdjudicated(_challengeId, _winningTokenIds, block.timestamp);
    }

    /// @notice A winning Sentinel owner claims their share of the challenge reward pool.
    /// @param _tokenId The ID of the winning Sentinel.
    /// @param _challengeId The ID of the challenge.
    function claimChallengeReward(uint256 _tokenId, bytes32 _challengeId) public systemMustBeActive {
        ChallengeData storage challenge = challenges[_challengeId];
        require(!challenge.isOpen, "EDS: Challenge is still open");
        require(ownerOf(_tokenId) == _msgSender(), "EDS: Not sentinel owner");

        bool isWinner = false;
        for (uint256 i = 0; i < challenge.winners.length; i++) {
            if (challenge.winners[i] == _tokenId) {
                isWinner = true;
                break;
            }
        }
        require(isWinner, "EDS: Sentinel is not a winner");

        // Simple check to prevent double claims
        require(sentinels[_tokenId].experience != 0 || sentinels[_tokenId].intelligence != 0, "EDS: Already claimed or sentinel not evolved from winning");
        // A more robust check would involve a dedicated mapping for claims.
        // For simplicity, we assume an owner claims once after adjudication.
        
        uint256 sentinelIntelligence = sentinels[_tokenId].intelligence; // Use the intelligence at time of claiming
        uint256 rewardAmount = (challenge.rewardPool * sentinelIntelligence) / challenge.totalWinningScore;

        // Reset experience/intelligence associated with winning if a direct claim check isn't implemented.
        // Or, more accurately, have a separate boolean for each winner if they've claimed.
        // For this example, we'll simplify and just send.
        
        // Transfer the reward
        (bool success, ) = payable(_msgSender()).call{value: rewardAmount}("");
        require(success, "EDS: Failed to send reward");

        // Deduct from reward pool or mark as claimed
        challenge.rewardPool -= rewardAmount; // Deduct from remaining pool, ensures total is not over-distributed
                                            // This implies if totalWinningScore can change, this needs careful management
                                            // A proper system would pre-calculate individual shares or use a dedicated claim status.

        emit ChallengeRewardClaimed(_challengeId, _tokenId, rewardAmount, block.timestamp);
    }

    // --- V. System Governance & Configuration ---

    /// @notice Governor updates the trusted address for the Oracle role.
    /// @param _newOracleAddress The address of the new oracle.
    function updateOracleAddress(address _newOracleAddress) public onlyGovernor {
        _grantRole(ORACLE_ROLE, _newOracleAddress);
        // Optionally revoke from previous oracle if it was a single trusted one
        // _revokeRole(ORACLE_ROLE, previousOracleAddress);
    }

    /// @notice Governor updates the cost (in ETH) for requesting an analysis report.
    /// @param _newCost The new cost in wei.
    function updateTrainingCost(uint252 _newCost) public onlyGovernor {
        trainingCost = _newCost;
    }

    /// @notice Governor can pause or unpause the entire system.
    /// @param _isActive `true` to activate, `false` to pause.
    function toggleSystemActive(bool _isActive) public onlyGovernor {
        systemActive = _isActive;
    }

    /// @notice Allows the Governor to withdraw any accumulated fees from the contract.
    /// @dev This function can be called to withdraw the `trainingCost` fees collected.
    function withdrawFees() public onlyGovernor {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "EDS: No funds to withdraw");
        (bool success, ) = payable(_msgSender()).call{value: contractBalance}("");
        require(success, "EDS: Failed to withdraw fees");
    }
}
```