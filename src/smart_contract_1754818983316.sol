This smart contract, `SyntientProtocol`, introduces the concept of **Autonomous Intelligence Digital Organisms (AIDOs)**. These are dynamic NFTs that evolve based on experience, possess mutable AI "behavior modules," contribute to a decentralized knowledge base, and participate in an autonomous task market.

The core innovation lies in treating NFTs as programmable, evolving entities with measurable aptitudes, capable of performing complex tasks and contributing to a shared, verifiable knowledge graph, all facilitated by references to off-chain AI models and oracle integrations.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// Interfaces for potential external contracts, e.g., Oracle
interface IOracle {
    // A simplified interface for an external oracle service.
    // In a real scenario, this would adhere to specific oracle protocols (e.g., Chainlink).
    function requestData(string memory _key, bytes32 _callbackId) external returns (bytes32 requestId);
    function fulfillRequest(bytes32 _requestId, bytes memory _data) external;
}

/**
 * @title SyntientProtocol - Autonomous Intelligence Protocol for Evolving Digital Entities
 * @dev This contract implements a novel system for dynamic, AI-driven NFTs (AIDOs)
 *      that evolve based on experience, contribute to a decentralized knowledge base,
 *      and participate in an autonomous task market.
 *      It aims to combine concepts of dynamic NFTs, decentralized AI (via behavior modules),
 *      and verifiable knowledge graphs in a non-standard, creative way.
 */
contract SyntientProtocol is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    /*//////////////////////////////////////////////////////////////
                            OUTLINE & FUNCTION SUMMARY
    //////////////////////////////////////////////////////////////*/

    // --- Core ERC721 & AIDO Management (Functions 1-9) ---
    // 1. constructor(string memory _name, string memory _symbol): Initializes the ERC721 contract with a name and symbol.
    // 2. setBaseURI(string memory _newBaseURI): Sets the base URI for token metadata, typically pointing to image/asset storage.
    // 3. mintAIDO(address _to, string memory _initialGenomeCID): Mints a new AIDO NFT to `_to` with an immutable initial "genome" (a CID for its foundational AI architecture).
    // 4. tokenURI(uint256 tokenId): Generates dynamic JSON metadata for an AIDO, reflecting its current level, XP, aptitudes, and behavior modules.
    // 5. setAIDOGenomeTemplate(uint256 _baseXPPerLevel, uint256 _aptitudeGrowthFactor): Sets global parameters influencing AIDO evolution mechanics (XP required per level, aptitude gain per XP).
    // 6. getAIDOGenomeTemplate(): Retrieves the current global AIDO evolution parameters.
    // 7. pause(): Pauses all transfers and most functionalities, useful for emergency stops or upgrades.
    // 8. unpause(): Unpauses the contract, re-enabling its functionalities.
    // 9. withdrawFunds(address payable _to): Allows the contract owner to withdraw accumulated ETH (e.g., from task rewards, assertion collateral).

    // --- AIDO Attributes & Evolution (Functions 10-14) ---
    // 10. gainExperience(uint256 tokenId, uint256 amount): Internal function to credit experience points (XP) to an AIDO. Triggered by successful tasks, knowledge contributions, etc.
    // 11. getLevel(uint256 tokenId): Calculates an AIDO's current level based on its accumulated XP and the `baseXPPerLevel` template.
    // 12. getAptitude(uint256 tokenId, AptitudeType _type): Retrieves the current score of a specific aptitude (e.g., DataAnalysis, DecisionMaking) for an AIDO.
    // 13. evolveAptitude(uint256 tokenId, AptitudeType _type): Allows an AIDO's owner to spend accumulated XP to increase a specific aptitude score, up to a maximum.
    // 14. updateBehaviorModule(uint256 tokenId, AptitudeType _type, string memory _newModuleCID): Allows an AIDO's owner to link a new AI behavior module (represented by a CID) to a specific aptitude type. Requires a minimum aptitude score.
    // 15. getBehaviorModuleCID(uint256 tokenId, AptitudeType _type): Retrieves the CID of the AI behavior module currently linked to an AIDO's specific aptitude.

    // --- Decentralized Knowledge Base (DKB) (Functions 16-20) ---
    // 16. proposeAssertion(uint256 aidoId, string memory assertionHash, bytes memory dataProof, uint256 collateralAmount): An AIDO (via its owner) proposes a new verifiable fact or insight to the DKB, staking collateral.
    // 17. voteOnAssertion(uint256 assertionId, uint256 aidoId, bool support): Other AIDOs (via their owners) vote on the veracity of a proposed assertion. Vote weight can depend on AIDO aptitudes.
    // 18. resolveAssertion(uint256 assertionId): Resolves an assertion after its voting period ends, distributing or slashing collateral based on the vote outcome.
    // 19. getAssertionStatus(uint256 assertionId): Retrieves the current status (e.g., Proposed, Voting, ResolvedTrue) of an assertion in the DKB.
    // 20. queryDKB(uint256 aidoId, string memory queryHash): Simulates an AIDO performing a query on the DKB, potentially earning XP for "knowledge discovery."

    // --- Autonomous Task Market (Functions 21-27) ---
    // 21. createTask(string memory _taskDescriptionHash, uint256 _reward, uint256 _deadline, AptitudeType _requiredAptitude, uint256 _minAptitudeScore): Allows anyone to create a task, specifying requirements, reward, and deadline. The reward is staked upfront.
    // 22. proposeAIDOForTask(uint256 taskId, uint256 aidoId): An AIDO owner proposes their AIDO to perform an open task, provided it meets the aptitude requirements.
    // 23. selectAIDOForTask(uint256 taskId, uint256 aidoId): The task creator selects an AIDO from the proposals to assign the task to.
    // 24. submitTaskProof(uint256 taskId, uint256 aidoId, bytes memory _proofHash, bytes memory _oracleAttestation): The assigned AIDO's owner submits a hash of the off-chain proof of completion, optionally with an oracle attestation.
    // 25. verifyTaskCompletion(uint256 taskId, uint256 aidoId): The task creator verifies the submitted proof (often off-chain) and releases the reward to the AIDO's owner.
    // 26. disputeTaskResult(uint256 taskId, uint256 aidoId): Allows the task creator to formally dispute the submitted proof, potentially triggering a dispute resolution mechanism.
    // 27. claimTaskReward(uint256 taskId, uint256 aidoId): Finalizes the task's state as 'Completed' after rewards have been disbursed.

    // --- Oracle Integration (Simplified) (Functions 28-30) ---
    // 28. setOracleContract(address _oracleAddress): Sets the address of an approved external oracle contract that the protocol can interact with.
    // 29. requestDataFromOracle(uint256 aidoId, string memory _key): An AIDO (via its owner) triggers a request to the configured oracle for specific external data.
    // 30. receiveOracleData(bytes32 _requestId, bytes memory _data): A callback function, callable only by the designated oracle, to deliver requested data back to the contract.

    /*//////////////////////////////////////////////////////////////
                            ERROR CODES
    //////////////////////////////////////////////////////////////*/
    error Unauthorized(); // Caller is not authorized for the action
    error NotMinted(); // Token ID does not exist
    error InvalidState(); // Operation not allowed in current contract/entity state
    error InvalidInput(); // Invalid or malformed input parameters
    error InsufficientFunds(); // Not enough ETH provided or available
    error TaskAlreadyAssigned(); // Task is already assigned to an AIDO
    error NotAssignedAIDO(); // AIDO is not assigned to this specific task
    error TaskNotComplete(); // Task is not in a completed/verified state
    error TaskExpired(); // Task deadline has passed
    error InsufficientAptitude(); // AIDO does not meet the minimum aptitude requirement
    error AIDOAlreadyProposed(); // AIDO has already been proposed for this task
    error NoXPToEvolve(); // AIDO has insufficient XP for aptitude evolution
    error AssertionNotFound(); // Assertion ID does not exist
    error AIDOAlreadyVoted(); // AIDO has already voted on this assertion
    error NotOracle(); // Caller is not the designated oracle contract
    error RequestNotFound(); // Oracle request ID does not exist
    error RequestAlreadyFulfilled(); // Oracle request has already been fulfilled
    error OwnerMismatch(); // Provided owner address does not match actual owner

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private _tokenIdCounter; // Counter for unique AIDO IDs
    Counters.Counter private _assertionIdCounter; // Counter for unique Assertion IDs
    Counters.Counter private _taskIdCounter; // Counter for unique Task IDs
    Counters.Counter private _oracleRequestIdCounter; // Counter for unique Oracle Request IDs

    uint256 public baseXPPerLevel = 1000; // Base XP needed to gain a level
    uint256 public aptitudeGrowthFactor = 200; // Multiplier for aptitude gain per XP spent (e.g., 100 for 1:1, 200 for 1:2)
    uint256 public constant MAX_APTITUDE = 10000; // Cap for any single aptitude score to prevent overflow/unbounded growth
    uint256 public constant MIN_XP_FOR_EVOLUTION = 500; // Minimum XP required to perform an aptitude evolution step

    // Enum for different AIDO aptitude types
    enum AptitudeType {
        DataAnalysis,
        PatternRecognition,
        DecisionMaking,
        Communication,
        ProblemSolving
    }

    // Struct defining an AIDO's properties
    struct AIDO {
        string genomeCID; // Immutable IPFS/CID hash representing the AIDO's foundational "genetic code" or initial AI model architecture.
        uint256 xp; // Experience Points accumulated
        mapping(AptitudeType => uint256) aptitudes; // Scores for different aptitudes (e.g., DataAnalysis: 85)
        mapping(AptitudeType => string) behaviorModuleCIDs; // CIDs for specific AI models/behaviors (e.g., DataAnalysis module CID)
        uint256 lastEvolutionTime; // Timestamp of last aptitude evolution for potential cooldowns
    }
    mapping(uint256 => AIDO) public aidos; // Mapping from AIDO ID to AIDO struct

    // Enum for the status of an assertion in the DKB
    enum AssertionStatus {
        Proposed, // Assertion just proposed, waiting for voting to start
        Voting, // Assertion is currently in its voting phase
        ResolvedTrue, // Assertion resolved as true
        ResolvedFalse, // Assertion resolved as false
        Disputed // Assertion resolution is ambiguous or requires further dispute mechanism
    }

    // Struct defining an Assertion in the Decentralized Knowledge Base
    struct Assertion {
        uint256 id; // Unique ID for the assertion
        uint256 proposerAIDOId; // ID of the AIDO that proposed the assertion
        address proposerAddress; // Address of the AIDO owner who proposed
        string assertionHash; // Hash of the assertion statement (e.g., "The current price of BTC is $X")
        bytes dataProof; // Off-chain data proof linked to the assertion (e.g., signed data, ZKP hash)
        uint256 collateral; // Collateral staked by the proposer
        AssertionStatus status; // Current status of the assertion
        uint256 proposalTime; // Timestamp when the assertion was proposed
        uint256 votingEndTime; // Timestamp when voting period ends
        uint256 votesFor; // Total vote weight for the assertion
        uint256 votesAgainst; // Total vote weight against the assertion
        mapping(uint256 => bool) hasVoted; // AIDO ID => whether this AIDO has voted
    }
    mapping(uint256 => Assertion) public assertions; // Mapping from Assertion ID to Assertion struct

    // Enum for the status of a Task in the Task Market
    enum TaskStatus {
        Open, // Task is open for proposals
        Proposed, // AIDOs have proposed, awaiting selection
        Assigned, // Task assigned to an AIDO
        ProofSubmitted, // AIDO has submitted proof of completion
        Verified, // Task creator has verified proof and reward disbursed
        Disputed, // Task proof is under dispute
        Completed, // Task is fully completed (reward claimed, state finalized)
        Cancelled // Task was cancelled by creator
    }

    // Struct defining a Task in the Autonomous Task Market
    struct Task {
        uint256 id; // Unique ID for the task
        address creator; // Address of the task creator
        string taskDescriptionHash; // IPFS/CID hash of off-chain detailed task description
        uint256 reward; // ETH reward for task completion
        uint256 deadline; // Timestamp by which the task must be completed
        AptitudeType requiredAptitude; // Type of aptitude required for this task
        uint256 minAptitudeScore; // Minimum score in the required aptitude
        uint256 assignedAIDOId; // ID of the AIDO assigned to the task (0 if none)
        address assignedAIDOOwner; // Owner address of the assigned AIDO
        string proofHash; // Hash of the proof submitted by AIDO (e.g., result CID or ZKP output hash)
        string oracleAttestation; // Optional oracle attestation of off-chain proof verification
        TaskStatus status; // Current status of the task
        uint256 assignmentTime; // Timestamp when task was assigned
        uint256 proofSubmissionTime; // Timestamp when proof was submitted
        mapping(uint256 => bool) hasProposed; // AIDO ID => whether this AIDO has proposed for this task
    }
    mapping(uint256 => Task) public tasks; // Mapping from Task ID to Task struct

    // Oracle Integration
    address public oracleContract; // Address of the trusted oracle contract
    mapping(bytes32 => OracleRequest) public oracleRequests; // Mapping from oracle request ID to request details
    struct OracleRequest {
        uint256 aidoId; // ID of the AIDO that initiated the request
        address requester; // Address of the AIDO owner who initiated
        string key; // Key or query for the oracle
        bool fulfilled; // True if the request has been fulfilled by the oracle
    }

    bool private _paused; // Contract pause state

    /*//////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event AIDOEvoked(uint256 indexed tokenId, address indexed owner, string initialGenomeCID);
    event ExperienceGained(uint256 indexed tokenId, uint256 amount, uint256 newXP);
    event AptitudeEvolved(uint256 indexed tokenId, AptitudeType indexed aptitudeType, uint256 newScore);
    event BehaviorModuleUpdated(uint256 indexed tokenId, AptitudeType indexed aptitudeType, string newModuleCID);

    event AssertionProposed(uint256 indexed assertionId, uint256 indexed aidoId, string assertionHash, uint256 collateral);
    event AssertionVoted(uint256 indexed assertionId, uint256 indexed aidoId, bool support);
    event AssertionResolved(uint256 indexed assertionId, AssertionStatus newStatus);

    event TaskCreated(uint256 indexed taskId, address indexed creator, string taskDescriptionHash, uint256 reward);
    event AIDOProposedForTask(uint256 indexed taskId, uint256 indexed aidoId);
    event AIDOSelectedForTask(uint256 indexed taskId, uint256 indexed aidoId);
    event TaskProofSubmitted(uint256 indexed taskId, uint256 indexed aidoId, string proofHash);
    event TaskVerifiedAndRewarded(uint256 indexed taskId, uint256 indexed aidoId, uint256 reward);
    event TaskDisputed(uint256 indexed taskId, uint256 indexed aidoId);

    event OracleSet(address indexed newOracleAddress);
    event OracleDataRequested(uint256 indexed aidoId, bytes32 indexed requestId, string key);
    event OracleDataReceived(bytes32 indexed requestId, bytes data);

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        if (_paused) revert InvalidState();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert InvalidState();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleContract) revert NotOracle();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Initializes the ERC721 contract with a name and symbol.
     * @param name_ The name of the NFT collection.
     * @param symbol_ The symbol of the NFT collection.
     */
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                    CORE ERC721 & AIDO MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Sets the base URI for token metadata. Only callable by the owner.
     *      This typically points to an IPFS gateway or web server hosting AIDO images/assets.
     * @param _newBaseURI The new base URI string.
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    /**
     * @dev Mints a new AIDO NFT.
     *      Each AIDO starts with initial base aptitudes and generic behavior module CIDs.
     * @param _to The address to mint the AIDO to.
     * @param _initialGenomeCID The immutable IPFS/CID hash representing the AIDO's foundational "genetic code" or initial AI model architecture.
     * @return The ID of the newly minted AIDO.
     */
    function mintAIDO(address _to, string memory _initialGenomeCID) public whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 newAIDOId = _tokenIdCounter.current();

        aidos[newAIDOId].genomeCID = _initialGenomeCID;
        aidos[newAIDOId].xp = 0; // Starts with 0 XP
        aidos[newAIDOId].aptitudes[AptitudeType.DataAnalysis] = 100; // Initial base aptitudes
        aidos[newAIDOId].aptitudes[AptitudeType.PatternRecognition] = 100;
        aidos[newAIDOId].aptitudes[AptitudeType.DecisionMaking] = 100;
        aidos[newAIDOId].aptitudes[AptitudeType.Communication] = 100;
        aidos[newAIDOId].aptitudes[AptitudeType.ProblemSolving] = 100;

        // Initialize behavior modules with generic/default CIDs. These can be updated later.
        aidos[newAIDOId].behaviorModuleCIDs[AptitudeType.DataAnalysis] = "QmInitialDataAnalysisModule";
        aidos[newAIDOId].behaviorModuleCIDs[AptitudeType.PatternRecognition] = "QmInitialPatternRecognitionModule";
        aidos[newAIDOId].behaviorModuleCIDs[AptitudeType.DecisionMaking] = "QmInitialDecisionMakingModule";
        aidos[newAIDOId].behaviorModuleCIDs[AptitudeType.Communication] = "QmInitialCommunicationModule";
        aidos[newAIDOId].behaviorModuleCIDs[AptitudeType.ProblemSolving] = "QmInitialProblemSolvingModule";

        _safeMint(_to, newAIDOId);
        emit AIDOEvoked(newAIDOId, _to, _initialGenomeCID);
        return newAIDOId;
    }

    /**
     * @dev Generates dynamic metadata for an AIDO, reflecting its current state.
     *      This function provides the JSON data URI required by NFT marketplaces.
     * @param tokenId The ID of the AIDO.
     * @return A data URI containing the JSON metadata, base64 encoded.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert NotMinted();

        AIDO storage aido = aidos[tokenId];
        uint256 currentLevel = getLevel(tokenId);

        // Construct JSON metadata string reflecting AIDO's dynamic state
        string memory json = string(
            abi.encodePacked(
                '{"name": "Syntient AIDO #', tokenId.toString(),
                '", "description": "An evolving, autonomous intelligence digital organism within the Syntient Protocol.",',
                '"image": "', _baseURI(), 'image/', tokenId.toString(), '.svg",', // Placeholder image URI, could be dynamic too
                '"attributes": [',
                    '{"trait_type": "Level", "value": ', currentLevel.toString(), '},',
                    '{"trait_type": "XP", "value": ', aido.xp.toString(), '},',
                    '{"trait_type": "Genome CID", "value": "', aido.genomeCID, '"},',
                    '{"trait_type": "Data Analysis Aptitude", "value": ', aido.aptitudes[AptitudeType.DataAnalysis].toString(), '},',
                    '{"trait_type": "Pattern Recognition Aptitude", "value": ', aido.aptitudes[AptitudeType.PatternRecognition].toString(), '},',
                    '{"trait_type": "Decision Making Aptitude", "value": ', aido.aptitudes[AptitudeType.DecisionMaking].toString(), '},',
                    '{"trait_type": "Communication Aptitude", "value": ', aido.aptitudes[AptitudeType.Communication].toString(), '},',
                    '{"trait_type": "Problem Solving Aptitude", "value": ', aido.aptitudes[AptitudeType.ProblemSolving].toString(), '},',
                    '{"trait_type": "Data Analysis Module", "value": "', aido.behaviorModuleCIDs[AptitudeType.DataAnalysis], '"},',
                    '{"trait_type": "Pattern Recognition Module", "value": "', aido.behaviorModuleCIDs[AptitudeType.PatternRecognition], '"},',
                    '{"trait_type": "Decision Making Module", "value": "', aido.behaviorModuleCIDs[AptitudeType.DecisionMaking], '"},',
                    '{"trait_type": "Communication Module", "value": "', aido.behaviorModuleCIDs[AptitudeType.Communication], '"},',
                    '{"trait_type": "Problem Solving Module", "value": "', aido.behaviorModuleCIDs[AptitudeType.ProblemSolving], '"}'
                ']}'
            )
        );
        // Encodes the JSON string to base64 for the data URI format
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /**
     * @dev Sets global parameters for AIDO evolution, such as XP per level and aptitude growth factor.
     *      These parameters influence how AIDOs gain levels and improve aptitudes.
     * @param _baseXPPerLevel New base XP required for the next level. Must be greater than 0.
     * @param _aptitudeGrowthFactor New aptitude growth factor. Must be greater than 0.
     */
    function setAIDOGenomeTemplate(uint256 _baseXPPerLevel, uint256 _aptitudeGrowthFactor) public onlyOwner {
        if (_baseXPPerLevel == 0 || _aptitudeGrowthFactor == 0) revert InvalidInput();
        baseXPPerLevel = _baseXPPerLevel;
        aptitudeGrowthFactor = _aptitudeGrowthFactor;
    }

    /**
     * @dev Returns the current global AIDO genome template parameters.
     * @return baseXPPerLevel_ Current base XP per level.
     * @return aptitudeGrowthFactor_ Current aptitude growth factor.
     */
    function getAIDOGenomeTemplate() public view returns (uint256 baseXPPerLevel_, uint256 aptitudeGrowthFactor_) {
        return (baseXPPerLevel, aptitudeGrowthFactor);
    }

    /**
     * @dev Pauses all token transfers and most contract functionalities. Only owner can call.
     *      Useful for emergency situations or during upgrades.
     */
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
    }

    /**
     * @dev Unpauses the contract, re-enabling its functionalities. Only owner can call.
     */
    function unpause() public onlyOwner whenPaused {
        _paused = false;
    }

    /**
     * @dev Allows the owner to withdraw any accumulated ETH from the contract.
     *      This could include task rewards, assertion collateral, or direct deposits.
     * @param _to The address to send funds to.
     */
    function withdrawFunds(address payable _to) public onlyOwner {
        if (address(this).balance == 0) revert InsufficientFunds();
        _to.transfer(address(this).balance);
    }

    /*//////////////////////////////////////////////////////////////
                        AIDO ATTRIBUTES & EVOLUTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Internal function to add experience points to an AIDO.
     *      Called by other functions (e.g., successful task completion, knowledge contribution).
     * @param tokenId The ID of the AIDO.
     * @param amount The amount of XP to add.
     */
    function gainExperience(uint256 tokenId, uint256 amount) internal {
        if (!_exists(tokenId)) revert NotMinted(); // Should not happen internally if ID is valid
        aidos[tokenId].xp += amount;
        emit ExperienceGained(tokenId, amount, aidos[tokenId].xp);
    }

    /**
     * @dev Calculates the current level of an AIDO based on its XP.
     *      Uses a simple linear scaling for demonstration.
     * @param tokenId The ID of the AIDO.
     * @return The calculated level (always at least 1).
     */
    function getLevel(uint256 tokenId) public view returns (uint256) {
        if (!_exists(tokenId)) revert NotMinted();
        // A simple linear scaling: level = (XP / baseXPPerLevel) + 1
        return (aidos[tokenId].xp / baseXPPerLevel) + 1;
    }

    /**
     * @dev Retrieves an AIDO's aptitude score for a specific type.
     * @param tokenId The ID of the AIDO.
     * @param _type The type of aptitude to retrieve (e.g., DataAnalysis, DecisionMaking).
     * @return The aptitude score.
     */
    function getAptitude(uint256 tokenId, AptitudeType _type) public view returns (uint256) {
        if (!_exists(tokenId)) revert NotMinted();
        return aidos[tokenId].aptitudes[_type];
    }

    /**
     * @dev Allows an AIDO owner to spend accumulated XP to boost a specific aptitude.
     *      Each evolution step costs `MIN_XP_FOR_EVOLUTION` and increases the aptitude by a calculated amount.
     * @param tokenId The ID of the AIDO to evolve.
     * @param _type The aptitude type to boost.
     */
    function evolveAptitude(uint256 tokenId, AptitudeType _type) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert Unauthorized();
        AIDO storage aido = aidos[tokenId];

        if (aido.xp < MIN_XP_FOR_EVOLUTION) revert NoXPToEvolve();

        uint256 xpCost = MIN_XP_FOR_EVOLUTION;
        // Aptitude gain scales with XP cost and growth factor relative to base XP per level
        uint256 aptitudeGain = (xpCost * aptitudeGrowthFactor) / baseXPPerLevel;
        
        uint256 newAptitude = aido.aptitudes[_type] + aptitudeGain;
        if (newAptitude > MAX_APTITUDE) {
            newAptitude = MAX_APTITUDE; // Cap aptitude at defined maximum
        }

        aido.xp -= xpCost; // Deduct XP
        aido.aptitudes[_type] = newAptitude; // Update aptitude
        aido.lastEvolutionTime = block.timestamp; // Record last evolution time

        emit AptitudeEvolved(tokenId, _type, newAptitude);
    }

    /**
     * @dev Updates an AIDO's AI behavior module (CID) for a given aptitude type.
     *      This represents "installing" or "upgrading" an AI model into the AIDO's capabilities.
     *      Requires the AIDO to have a minimum aptitude score in that category to equip advanced modules.
     * @param tokenId The ID of the AIDO.
     * @param _type The aptitude type to associate the new module with.
     * @param _newModuleCID The IPFS/CID hash of the new behavior module (e.g., a trained ML model).
     */
    function updateBehaviorModule(uint256 tokenId, AptitudeType _type, string memory _newModuleCID) public whenNotPaused {
        if (ownerOf(tokenId) != msg.sender) revert Unauthorized();
        AIDO storage aido = aidos[tokenId];

        // Example requirement: AIDO must have a certain aptitude score (e.g., 500) to equip/change modules
        uint256 minAptitudeForModule = 500;
        if (aido.aptitudes[_type] < minAptitudeForModule) revert InsufficientAptitude();

        aido.behaviorModuleCIDs[_type] = _newModuleCID;
        emit BehaviorModuleUpdated(tokenId, _type, _newModuleCID);
    }

    /**
     * @dev Retrieves the current behavior module CID for an AIDO's specified aptitude.
     * @param tokenId The ID of the AIDO.
     * @param _type The aptitude type (e.g., DataAnalysis) for which to retrieve the module CID.
     * @return The CID of the behavior module.
     */
    function getBehaviorModuleCID(uint256 tokenId, AptitudeType _type) public view returns (string memory) {
        if (!_exists(tokenId)) revert NotMinted();
        return aidos[tokenId].behaviorModuleCIDs[_type];
    }

    /*//////////////////////////////////////////////////////////////
                        DECENTRALIZED KNOWLEDGE BASE (DKB)
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev An AIDO (via its owner) proposes a new verifiable assertion about the world, staking collateral.
     *      This could be an AI-generated insight, a verifiable fact, or a claim requiring community verification.
     *      Requires the proposing AIDO to have a minimum DataAnalysis aptitude.
     * @param aidoId The ID of the AIDO making the assertion.
     * @param assertionHash Hash of the assertion statement (e.g., IPFS CID of a detailed claim).
     * @param dataProof Proof of the assertion (e.g., hash of signed data, ZKP proof, oracle response hash).
     * @param collateralAmount Amount of collateral (in ETH) staked by the proposer.
     */
    function proposeAssertion(
        uint256 aidoId,
        string memory assertionHash,
        bytes memory dataProof,
        uint256 collateralAmount
    ) public payable whenNotPaused {
        if (ownerOf(aidoId) != msg.sender) revert Unauthorized();
        if (msg.value < collateralAmount) revert InsufficientFunds(); // Ensure enough ETH is sent for collateral
        // Example: AIDO needs a certain aptitude to propose complex assertions
        if (aidos[aidoId].aptitudes[AptitudeType.DataAnalysis] < 200) revert InsufficientAptitude(); 

        _assertionIdCounter.increment();
        uint256 newAssertionId = _assertionIdCounter.current();

        assertions[newAssertionId] = Assertion({
            id: newAssertionId,
            proposerAIDOId: aidoId,
            proposerAddress: msg.sender,
            assertionHash: assertionHash,
            dataProof: dataProof,
            collateral: collateralAmount,
            status: AssertionStatus.Voting, // Immediately enters voting phase
            proposalTime: block.timestamp,
            votingEndTime: block.timestamp + 3 days, // Example: 3-day voting period
            votesFor: 0,
            votesAgainst: 0
        });

        emit AssertionProposed(newAssertionId, aidoId, assertionHash, collateralAmount);
    }

    /**
     * @dev An AIDO (via its owner) votes on the veracity of an assertion.
     *      The vote weight of an AIDO is proportional to its DecisionMaking aptitude.
     * @param assertionId The ID of the assertion to vote on.
     * @param aidoId The ID of the AIDO casting the vote.
     * @param support True for supporting the assertion, false for refuting it.
     */
    function voteOnAssertion(uint256 assertionId, uint256 aidoId, bool support) public whenNotPaused {
        if (ownerOf(aidoId) != msg.sender) revert Unauthorized(); // Only AIDO owner can vote on its behalf
        Assertion storage assertion = assertions[assertionId];

        if (assertion.id == 0) revert AssertionNotFound();
        if (assertion.status != AssertionStatus.Voting || block.timestamp >= assertion.votingEndTime) revert InvalidState();
        if (assertion.hasVoted[aidoId]) revert AIDOAlreadyVoted(); // Prevent double voting by same AIDO
        if (aidoId == assertion.proposerAIDOId) revert InvalidInput(); // Proposer AIDO cannot vote on its own assertion

        // Example: Vote weight based on AIDO's DecisionMaking aptitude (e.g., 100 aptitude points = 1 vote weight)
        uint256 voteWeight = aidos[aidoId].aptitudes[AptitudeType.DecisionMaking] / 100;
        if (voteWeight == 0) voteWeight = 1; // Ensure minimum vote weight

        if (support) {
            assertion.votesFor += voteWeight;
        } else {
            assertion.votesAgainst += voteWeight;
        }
        assertion.hasVoted[aidoId] = true;

        gainExperience(aidoId, 10); // Reward AIDO for participating in knowledge governance
        emit AssertionVoted(assertionId, aidoId, support);
    }

    /**
     * @dev Resolves an assertion based on the accumulated votes after the voting period ends.
     *      Distributes collateral (slashes for false assertions, returns/rewards for true).
     *      Can be called by anyone after `votingEndTime` to finalize.
     * @param assertionId The ID of the assertion to resolve.
     */
    function resolveAssertion(uint256 assertionId) public whenNotPaused {
        Assertion storage assertion = assertions[assertionId];

        if (assertion.id == 0) revert AssertionNotFound();
        if (assertion.status != AssertionStatus.Voting || block.timestamp < assertion.votingEndTime) revert InvalidState(); // Must be in voting state and voting period must be over

        if (assertion.votesFor > assertion.votesAgainst) {
            assertion.status = AssertionStatus.ResolvedTrue;
            // Return proposer's collateral for a true assertion
            payable(assertion.proposerAddress).transfer(assertion.collateral);
            // In a more complex system, could distribute a portion of protocol fees or new tokens as rewards to truth voters
        } else if (assertion.votesAgainst > assertion.votesFor) {
            assertion.status = AssertionStatus.ResolvedFalse;
            // Collateral is slashed (remains in contract or distributed to false voters)
            // For simplicity, slashed collateral remains in the contract balance here.
            // In production, might be distributed to 'false' voters or a treasury.
        } else {
            assertion.status = AssertionStatus.Disputed; // Or unresolved, collateral returned in this case
            payable(assertion.proposerAddress).transfer(assertion.collateral); // Return collateral if tie or insufficient votes
        }
        emit AssertionResolved(assertionId, assertion.status);
    }

    /**
     * @dev Checks the current status of an assertion.
     * @param assertionId The ID of the assertion.
     * @return The current status (e.g., Proposed, Voting, ResolvedTrue, ResolvedFalse, Disputed).
     */
    function getAssertionStatus(uint256 assertionId) public view returns (AssertionStatus) {
        if (assertions[assertionId].id == 0) revert AssertionNotFound();
        return assertions[assertionId].status;
    }

    /**
     * @dev An AIDO performs an internal query against the DKB.
     *      This simulates an AIDO accessing and processing knowledge from the decentralized base.
     *      Potentially rewards XP for the "effort" of knowledge discovery.
     *      In a real system, this might involve off-chain computation and verifiable proofs.
     * @param aidoId The ID of the AIDO querying.
     * @param queryHash A hash representing the query criteria or knowledge domain the AIDO is exploring.
     */
    function queryDKB(uint256 aidoId, string memory queryHash) public whenNotPaused {
        if (ownerOf(aidoId) != msg.sender) revert Unauthorized();
        // This function represents an AIDO's internal "learning" or "research" activity.
        // For demonstration, we simply grant XP for the act of querying.
        // A more advanced version might involve checking queryHash against actual DKB content (off-chain)
        // and rewarding based on "discovery" of new relevant info.
        gainExperience(aidoId, 25); // Reward for querying and "learning"
        // Could also log the query or link to an oracle for complex query fulfillment if needed
    }

    /*//////////////////////////////////////////////////////////////
                        AUTONOMOUS TASK MARKET
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates a new task that AIDOs can perform.
     *      The task creator stakes the reward upfront, which is held by the contract.
     * @param _taskDescriptionHash IPFS/CID hash of the detailed task description.
     * @param _reward Amount of ETH to be paid as reward upon successful completion.
     * @param _deadline Timestamp by which the task must be completed.
     * @param _requiredAptitude The type of aptitude (e.g., DataAnalysis, ProblemSolving) required for this task.
     * @param _minAptitudeScore The minimum score in the required aptitude for AIDOs to be eligible.
     * @return The ID of the newly created task.
     */
    function createTask(
        string memory _taskDescriptionHash,
        uint256 _reward,
        uint256 _deadline,
        AptitudeType _requiredAptitude,
        uint256 _minAptitudeScore
    ) public payable whenNotPaused returns (uint256) {
        if (msg.value < _reward) revert InsufficientFunds(); // Ensure creator sends enough ETH for reward
        if (_deadline <= block.timestamp) revert InvalidInput(); // Deadline must be in the future

        _taskIdCounter.increment();
        uint256 newTaskId = _taskIdCounter.current();

        tasks[newTaskId] = Task({
            id: newTaskId,
            creator: msg.sender,
            taskDescriptionHash: _taskDescriptionHash,
            reward: _reward,
            deadline: _deadline,
            requiredAptitude: _requiredAptitude,
            minAptitudeScore: _minAptitudeScore,
            assignedAIDOId: 0, // No AIDO assigned initially
            assignedAIDOOwner: address(0),
            proofHash: "",
            oracleAttestation: "",
            status: TaskStatus.Open, // Task is open for proposals
            assignmentTime: 0,
            proofSubmissionTime: 0
        });

        emit TaskCreated(newTaskId, msg.sender, _taskDescriptionHash, _reward);
        return newTaskId;
    }

    /**
     * @dev An AIDO owner proposes their AIDO to perform an open task.
     *      The AIDO must meet the task's minimum aptitude requirements.
     * @param taskId The ID of the task.
     * @param aidoId The ID of the AIDO to propose.
     */
    function proposeAIDOForTask(uint256 taskId, uint256 aidoId) public whenNotPaused {
        if (ownerOf(aidoId) != msg.sender) revert Unauthorized(); // Only AIDO owner can propose their AIDO
        Task storage task = tasks[taskId];

        if (task.id == 0) revert InvalidInput(); // Task not found
        if (task.status != TaskStatus.Open) revert InvalidState(); // Task must be open for proposals
        if (block.timestamp >= task.deadline) revert TaskExpired(); // Cannot propose for an expired task
        if (task.hasProposed[aidoId]) revert AIDOAlreadyProposed(); // AIDO cannot propose twice for the same task

        // Check if AIDO meets the required aptitude for the task
        if (aidos[aidoId].aptitudes[task.requiredAptitude] < task.minAptitudeScore) {
            revert InsufficientAptitude();
        }

        task.hasProposed[aidoId] = true;
        emit AIDOProposedForTask(taskId, aidoId);
    }

    /**
     * @dev The task creator selects an AIDO from the proposed list to perform the task.
     *      Only the original task creator can assign the task.
     * @param taskId The ID of the task.
     * @param aidoId The ID of the AIDO to assign. This AIDO must have proposed for the task.
     */
    function selectAIDOForTask(uint256 taskId, uint256 aidoId) public whenNotPaused {
        Task storage task = tasks[taskId];
        if (task.creator != msg.sender) revert Unauthorized(); // Only the task creator can select
        if (task.id == 0 || !_exists(aidoId)) revert InvalidInput(); // Task or AIDO not found
        if (task.status != TaskStatus.Open) revert InvalidState(); // Task must be in 'Open' state
        if (block.timestamp >= task.deadline) revert TaskExpired(); // Cannot assign an expired task
        if (!task.hasProposed[aidoId]) revert InvalidInput(); // Selected AIDO must have proposed

        task.assignedAIDOId = aidoId;
        task.assignedAIDOOwner = ownerOf(aidoId); // Store the owner's address for reward disbursement
        task.status = TaskStatus.Assigned; // Update task status
        task.assignmentTime = block.timestamp; // Record assignment time

        emit AIDOSelectedForTask(taskId, aidoId);
    }

    /**
     * @dev AIDO owner submits the proof of task completion.
     *      In a real system, this proof would be generated off-chain (e.g., ZKP, Merkle Proof, signed data),
     *      and then optionally verified via an oracle (e.g., Chainlink External Adapters for compute verification).
     * @param taskId The ID of the task.
     * @param aidoId The ID of the AIDO that completed the task.
     * @param _proofHash A hash representing the verifiable proof of completion (e.g., CID of results).
     * @param _oracleAttestation An optional attestation from an oracle confirming off-chain proof validity (as a string/CID).
     */
    function submitTaskProof(
        uint256 taskId,
        uint256 aidoId,
        bytes memory _proofHash,
        bytes memory _oracleAttestation
    ) public whenNotPaused {
        if (ownerOf(aidoId) != msg.sender) revert Unauthorized(); // Only the assigned AIDO's owner can submit proof
        Task storage task = tasks[taskId];

        if (task.id == 0 || task.assignedAIDOId != aidoId) revert NotAssignedAIDO(); // Task not found or AIDO not assigned
        if (task.status != TaskStatus.Assigned) revert InvalidState(); // Must be in 'Assigned' state
        if (block.timestamp >= task.deadline) revert TaskExpired(); // Cannot submit proof for an expired task

        task.proofHash = Strings.toHexString(bytes32(_proofHash), 32); // Store proof hash
        task.oracleAttestation = string(_oracleAttestation); // Store attestation hash/CID
        task.proofSubmissionTime = block.timestamp; // Record submission time
        task.status = TaskStatus.ProofSubmitted; // Update task status

        emit TaskProofSubmitted(taskId, aidoId, task.proofHash);
    }

    /**
     * @dev The task creator verifies the submitted proof and releases the reward.
     *      This verification usually involves off-chain inspection of `proofHash` and `oracleAttestation`.
     * @param taskId The ID of the task.
     * @param aidoId The ID of the AIDO that completed the task.
     */
    function verifyTaskCompletion(uint256 taskId, uint256 aidoId) public whenNotPaused {
        Task storage task = tasks[taskId];
        if (task.creator != msg.sender) revert Unauthorized(); // Only the task creator can verify
        if (task.id == 0 || task.assignedAIDOId != aidoId) revert NotAssignedAIDO(); // Task or AIDO mismatch
        if (task.status != TaskStatus.ProofSubmitted) revert InvalidState(); // Must be in 'ProofSubmitted' state

        // In a real dApp, this verification might trigger an oracle call for complex verification,
        // or rely on a human check of the proofHash/oracleAttestation via an off-chain interface.
        // For this example, we assume the creator has verified off-chain.

        task.status = TaskStatus.Verified; // Mark task as verified
        // Transfer reward from contract balance (staked by creator) to AIDO owner
        payable(task.assignedAIDOOwner).transfer(task.reward);
        gainExperience(aidoId, task.reward / 100); // AIDO gains XP based on the earned reward (e.g., 1 XP per 100 wei reward)

        emit TaskVerifiedAndRewarded(taskId, aidoId, task.reward);
    }

    /**
     * @dev Allows the task creator to dispute the result if the submitted proof is unsatisfactory.
     *      This would ideally trigger a decentralized dispute resolution mechanism (e.g., integration with Kleros).
     * @param taskId The ID of the task.
     * @param aidoId The ID of the AIDO whose proof is disputed.
     */
    function disputeTaskResult(uint256 taskId, uint256 aidoId) public whenNotPaused {
        Task storage task = tasks[taskId];
        if (task.creator != msg.sender) revert Unauthorized(); // Only the task creator can dispute
        if (task.id == 0 || task.assignedAIDOId != aidoId) revert NotAssignedAIDO(); // Task or AIDO mismatch
        if (task.status != TaskStatus.ProofSubmitted) revert InvalidState(); // Must be in 'ProofSubmitted' state

        task.status = TaskStatus.Disputed; // Change task status to disputed
        // In a real scenario, this would initiate a dispute contract, potentially lock funds, etc.
        emit TaskDisputed(taskId, aidoId);
    }

    /**
     * @dev Allows the AIDO owner to claim their reward after the task has been verified.
     *      This function primarily serves to finalize the task state on-chain.
     *      (Note: in this implementation, `verifyTaskCompletion` already sends funds, this primarily updates status).
     * @param taskId The ID of the task.
     * @param aidoId The ID of the AIDO.
     */
    function claimTaskReward(uint256 taskId, uint256 aidoId) public whenNotPaused {
        if (ownerOf(aidoId) != msg.sender) revert Unauthorized(); // Only the AIDO owner can claim
        Task storage task = tasks[taskId];

        if (task.id == 0 || task.assignedAIDOId != aidoId || task.assignedAIDOOwner != msg.sender) revert NotAssignedAIDO();
        if (task.status != TaskStatus.Verified) revert TaskNotComplete(); // Only claim if task is verified

        task.status = TaskStatus.Completed; // Mark as completed to prevent re-claiming/further actions
        // If funds were held until claim: payable(msg.sender).transfer(task.reward);
        // But in this design, rewards are sent in `verifyTaskCompletion`.
    }


    /*//////////////////////////////////////////////////////////////
                        ORACLE INTEGRATION (SIMPLIFIED)
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Sets the address of an approved oracle contract. Only owner can set.
     *      This oracle would be responsible for providing external data or verifiable computation results.
     * @param _oracleAddress The address of the oracle contract.
     */
    function setOracleContract(address _oracleAddress) public onlyOwner {
        oracleContract = _oracleAddress;
        emit OracleSet(_oracleAddress);
    }

    /**
     * @dev An AIDO (via its owner) can trigger an oracle data request for external information.
     *      This could be for specific data needed for tasks, for knowledge discovery, or for AI model inputs.
     * @param aidoId The ID of the AIDO making the request.
     * @param _key The key or query string for the oracle data (e.g., "current_eth_price", "weather_data_london").
     */
    function requestDataFromOracle(uint256 aidoId, string memory _key) public whenNotPaused {
        if (ownerOf(aidoId) != msg.sender) revert Unauthorized(); // Only AIDO owner can request data
        if (oracleContract == address(0)) revert InvalidState(); // Oracle contract must be set

        _oracleRequestIdCounter.increment();
        // Generate a unique request ID (e.g., using block.timestamp and a counter)
        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, _oracleRequestIdCounter.current()));

        oracleRequests[requestId] = OracleRequest({
            aidoId: aidoId,
            requester: msg.sender,
            key: _key,
            fulfilled: false
        });

        // Call the external oracle contract's requestData function
        IOracle(oracleContract).requestData(_key, requestId);
        emit OracleDataRequested(aidoId, requestId, _key);
    }

    /**
     * @dev Callback function for the oracle to send data back to the contract.
     *      Only the designated `oracleContract` address can call this function.
     *      Upon receiving data, it updates the relevant AIDO's state or DKB, and grants XP.
     * @param _requestId The ID of the original request that is being fulfilled.
     * @param _data The data (as bytes) returned by the oracle.
     */
    function receiveOracleData(bytes32 _requestId, bytes memory _data) external onlyOracle {
        OracleRequest storage req = oracleRequests[_requestId];
        if (req.aidoId == 0) revert RequestNotFound(); // Request ID must exist
        if (req.fulfilled) revert RequestAlreadyFulfilled(); // Request must not have been fulfilled yet

        req.fulfilled = true; // Mark request as fulfilled

        // Example: If data is successfully received, grant XP to the AIDO that requested it.
        // In a real scenario, parsing _data would be complex and context-dependent (e.g., update AIDO trait, DKB entry).
        gainExperience(req.aidoId, 50); // AIDO gains XP for successfully processed external data
        emit OracleDataReceived(_requestId, _data);
    }
}
```