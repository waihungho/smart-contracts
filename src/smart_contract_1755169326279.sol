This Solidity smart contract, named **SynapticCanvasProtocol**, introduces a decentralized system for AI-assisted, community-verified content classification. It uniquely combines dynamic NFTs (Synaptic Canvases) with a reputation-weighted dispute resolution mechanism and AI oracle integration. Unlike standard open-source projects, it focuses on the intrinsic evolution of NFTs based on their *classified content status* and community consensus, rather than just external data feeds or simple ownership.

---

## SynapticCanvasProtocol Smart Contract

**Outline:**

The contract is structured into distinct functional sections:

**I. Core Setup & Administration:**
   - Handles contract initialization, setting key parameters (stake requirements, fees, rewards), and managing registered AI oracle providers.
   - Defines and manages the content classification categories.

**II. Synaptic Canvas NFT (SCT) Management:**
   - Manages the lifecycle of ERC-721 NFTs, termed "Synaptic Canvases." Each NFT is inextricably linked to a unique content hash (e.g., an IPFS CID).
   - Features dynamic `tokenURI` generation, where the NFT's metadata (and implied visual traits) evolves based on its classification status, community engagement, and dispute outcomes.

**III. AI Oracle Interactions:**
   - Provides an interface for registered AI models to submit their initial classifications for content hashes. These submissions include a hashed proof for integrity.

**IV. Community Vetting & Dispute Resolution:**
   - Enables community members to actively participate in content classification by challenging AI's judgments or affirming them.
   - Implements a reputation-weighted voting system for resolving disputed classifications.
   - Manages the state and finalization of classification disputes.

**V. Reputation System & Rewards:**
   - Tracks and updates the reputation scores of users based on their accurate participation in the classification and dispute resolution process.
   - Defines mechanisms for AI oracles to manage their stake and for community members to claim rewards for correct dispute participation.

**VI. Utility & State Query Functions:**
   - Provides various view functions to query the contract's current state, including counts of canvases, lists of registered oracles, and details about classification categories or ongoing disputes.

---

**Function Summary:**

**I. Core Setup & Administration**
1.  `constructor()`: Initializes the contract, sets the deployer as owner, and defines initial core parameters (e.g., AI oracle stake, challenge fees, dispute duration, initial classification categories).
2.  `registerAIOracleProvider(address _oracleAddress)`: Allows a user to register an address as an official AI oracle by providing the required stake, enabling them to submit AI classifications.
3.  `deregisterAIOracleProvider(address _oracleAddress)`: Allows the owner to remove a registered AI oracle. The oracle can then withdraw their stake separately.
4.  `updateAIOracleStakeRequirement(uint256 _newStake)`: Owner function to adjust the minimum stake required for AI oracle registration.
5.  `updateChallengeFee(uint256 _newFee)`: Owner function to update the fee required for users to challenge an AI's classification.
6.  `updateAffirmReward(uint256 _newReward)`: Owner function to set the reward amount given to users who successfully affirm an AI classification.
7.  `defineClassificationCategory(uint8 _id, string calldata _name)`: Owner function to add a new content classification category (e.g., "Safe", "Sensitive", "Harmful") with a unique ID and name.
8.  `removeClassificationCategory(uint8 _id)`: Owner function to remove an existing content classification category by its ID.

**II. Synaptic Canvas NFT (SCT) Management**
9.  `mintSynapticCanvas(bytes32 _contentHash)`: Mints a new Synaptic Canvas NFT. Each NFT represents a unique content hash and starts in an "Awaiting AI Classification" state.
10. `tokenURI(uint256 _tokenId)`: Overrides the standard ERC721 function to generate dynamic metadata for a Synaptic Canvas NFT, reflecting its current classification status, engagement score, and dispute information.
11. `getCanvasState(bytes32 _contentHash)`: Retrieves a detailed struct containing all relevant state information for a Synaptic Canvas associated with a specific content hash.
12. `getCanvasTokenId(bytes32 _contentHash)`: A utility function to fetch the ERC-721 tokenId given a content hash.
13. `ownerOfContentHash(bytes32 _contentHash)`: Returns the address of the owner of the Synaptic Canvas NFT associated with a given content hash.
14. `burnSynapticCanvas(uint256 _tokenId)`: Allows the owner of a Synaptic Canvas to burn their NFT, removing it from circulation (cannot burn if in dispute).

**III. AI Oracle Interactions**
15. `submitAIClassification(bytes32 _contentHash, uint8 _classificationId, bytes32 _aiProofHash)`: Allows a registered AI oracle to submit an initial classification for a content hash. This updates the canvas status to "AI Classified."
16. `getAIClassification(bytes32 _contentHash)`: Retrieves the details of the latest classification submitted by an AI oracle for a given content hash, including the proof hash and oracle address.

**IV. Community Vetting & Dispute Resolution**
17. `challengeAIClassification(bytes32 _contentHash, uint8 _proposedClassificationId)`: Enables a community member to challenge an AI's classification by paying a fee and proposing an alternative classification, initiating a dispute.
18. `affirmAIClassification(bytes32 _contentHash)`: Allows a community member to affirm an AI's classification. If affirmed, the canvas can be finalized more quickly, and the affirmer receives a reward.
19. `submitDisputeVote(bytes32 _contentHash, uint8 _votedClassificationId)`: Allows users with sufficient reputation to cast a reputation-weighted vote for a specific classification within an active dispute.
20. `finalizeDispute(bytes32 _contentHash)`: Callable by anyone after the dispute voting period ends, this function tallies the votes, determines the final classification based on community consensus, and updates the Synaptic Canvas.
21. `getDisputeStatus(bytes32 _contentHash)`: Returns the current status of a content hash's classification dispute (e.g., `NoDispute`, `Active`, `Resolved`).
22. `getDisputeVoteTallies(bytes32 _contentHash)`: Provides the reputation-weighted vote counts for the AI's proposed classification and the challenger's proposed classification in an active dispute.
23. `getDisputeEndTime(bytes32 _contentHash)`: Returns the timestamp when the voting period for an active dispute is scheduled to conclude.
24. `getUserVoteInDispute(bytes32 _contentHash, address _voter)`: Returns the classification ID that a specific user voted for in a dispute, if they participated.

**V. Reputation System & Rewards**
25. `getUserReputation(address _user)`: Retrieves the current reputation score of any given user address.
26. `withdrawOracleStake()`: Allows a deregistered AI oracle provider to withdraw their original stake from the contract.
27. `claimDisputeParticipationReward(bytes32 _contentHash)`: Enables users whose votes aligned with the final consensus in a resolved dispute to claim a proportional reward based on their reputation and contribution.

**VI. Utility & State Query Functions**
28. `getTotalSynapticCanvases()`: Returns the total number of Synaptic Canvas NFTs that have been minted in the protocol.
29. `getRegisteredAIOracles()`: Returns an array of all addresses currently registered and active as AI oracle providers.
30. `getClassificationCategories()`: Returns arrays of all defined classification category IDs and their corresponding names.
31. `getPendingClassificationCount()`: Returns the number of Synaptic Canvases that are currently awaiting an initial classification from an AI oracle.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Outline:
// I. Core Setup & Administration
//    - Contract initialization, parameter setting, AI oracle management.
// II. Synaptic Canvas NFT (SCT) Management
//    - Minting, burning, and dynamic metadata generation for ERC721 NFTs tied to content hashes.
// III. AI Oracle Interactions
//    - Interface for AI models to submit content classifications.
// IV. Community Vetting & Dispute Resolution
//    - Mechanisms for users to challenge or affirm AI classifications and participate in dispute resolution.
// V. Reputation System & Rewards
//    - System for tracking user reputation and distributing rewards based on accurate participation.
// VI. Utility & State Query Functions
//    - Various helper and view functions to query contract state.

// Function Summary:

// I. Core Setup & Administration
// 1. constructor(): Initializes the contract, sets the owner, and defines initial parameters.
// 2. registerAIOracleProvider(address _oracleAddress): Allows an address to register as an AI oracle provider by staking tokens.
// 3. deregisterAIOracleProvider(address _oracleAddress): Allows a registered AI oracle to deregister and retrieve their stake.
// 4. updateAIOracleStakeRequirement(uint256 _newStake): Owner can update the minimum stake required for AI oracles.
// 5. updateChallengeFee(uint256 _newFee): Owner can update the fee required to challenge an AI classification.
// 6. updateAffirmReward(uint256 _newReward): Owner can update the reward for successfully affirming an AI classification.
// 7. defineClassificationCategory(uint8 _id, string calldata _name): Owner can define new content classification categories.
// 8. removeClassificationCategory(uint8 _id): Owner can remove an existing content classification category.

// II. Synaptic Canvas NFT (SCT) Management
// 9. mintSynapticCanvas(bytes32 _contentHash): Mints a new Synaptic Canvas NFT for a unique content hash.
// 10. tokenURI(uint256 _tokenId): Overrides ERC721's tokenURI to generate dynamic metadata based on the canvas's state.
// 11. getCanvasState(bytes32 _contentHash): Retrieves the detailed current state of a Synaptic Canvas.
// 12. getCanvasTokenId(bytes32 _contentHash): Returns the tokenId associated with a given content hash.
// 13. ownerOfContentHash(bytes32 _contentHash): Returns the owner address of the Synaptic Canvas linked to a content hash.
// 14. burnSynapticCanvas(uint256 _tokenId): Allows the owner of a Synaptic Canvas to burn their NFT.

// III. AI Oracle Interactions
// 15. submitAIClassification(bytes32 _contentHash, uint8 _classificationId, bytes32 _aiProofHash): Allows a registered AI oracle to submit a classification for a content hash.
// 16. getAIClassification(bytes32 _contentHash): Retrieves the latest AI classification data for a content hash.

// IV. Community Vetting & Dispute Resolution
// 17. challengeAIClassification(bytes32 _contentHash, uint8 _proposedClassificationId): Users can challenge an AI's classification, initiating a dispute.
// 18. affirmAIClassification(bytes32 _contentHash): Users can affirm an AI's classification, potentially speeding up its finalization.
// 19. submitDisputeVote(bytes32 _contentHash, uint8 _votedClassificationId): Allows users to cast their reputation-weighted vote in an active dispute.
// 20. finalizeDispute(bytes32 _contentHash): Finalizes a dispute after its voting period, applying the consensus classification to the Synaptic Canvas.
// 21. getDisputeStatus(bytes32 _contentHash): Returns the current state (active, pending, resolved) of a content hash's dispute.
// 22. getDisputeVoteTallies(bytes32 _contentHash): Retrieves the total reputation votes for each classification category in an active dispute.
// 23. getDisputeEndTime(bytes32 _contentHash): Returns the timestamp when the current dispute for a content hash is scheduled to end.
// 24. getUserVoteInDispute(bytes32 _contentHash, address _voter): Returns the classification ID a specific user voted for in a dispute.

// V. Reputation System & Rewards
// 25. getUserReputation(address _user): Retrieves the current reputation score of a given user.
// 26. withdrawOracleStake(): Allows a deregistered AI oracle provider to withdraw their staked tokens.
// 27. claimDisputeParticipationReward(bytes32 _contentHash): Allows users who voted with the winning side in a dispute to claim a reward.

// VI. Utility & State Query Functions
// 28. getTotalSynapticCanvases(): Returns the total number of Synaptic Canvases minted.
// 29. getRegisteredAIOracles(): Returns a list of all currently registered AI oracle addresses.
// 30. getClassificationCategories(): Returns a mapping of all defined classification category IDs to their names.
// 31. getPendingClassificationCount(): Returns the number of canvases awaiting initial AI classification.

contract SynapticCanvasProtocol is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums and Structs ---

    enum ClassificationStatus {
        AwaitingAI, // Content has been minted, awaiting AI classification
        AIClassified, // AI has submitted a classification
        Disputed, // AI classification has been challenged, dispute is active
        Finalized // Classification has been finalized via AI affirmation or dispute resolution
    }

    enum DisputeState {
        NoDispute, // No dispute is active for this content
        Active,    // A dispute is currently ongoing and open for voting
        Resolved   // A dispute has concluded, and a final classification has been set
    }

    // Stores the state of each Synaptic Canvas NFT
    struct SynapticCanvasState {
        uint256 tokenId;                   // The unique ERC-721 token ID
        address owner;                     // The current owner of the NFT
        ClassificationStatus status;       // Current classification status of the content
        uint8 currentClassificationId;     // The ID of the current classification (0 if unclassified)
        uint256 mintTimestamp;             // Timestamp when the canvas was minted
        uint256 lastUpdatedTimestamp;      // Last time the canvas state was updated
        uint256 engagementScore;           // A score reflecting community interaction (challenges, affirmations)
        bytes32 aiProofHash;               // Hash of the AI's classification proof (off-chain data)
        address aiOracleAddress;           // Address of the AI oracle that submitted the classification
    }

    // Stores information about a registered AI oracle
    struct AIOracleInfo {
        bool isRegistered;                 // True if the oracle is currently registered
        uint256 stake;                     // Amount of ETH staked by the oracle
    }

    // Stores information about an active or resolved dispute
    struct DisputeInfo {
        uint256 startTime;                 // Timestamp when the dispute began
        uint256 endTime;                   // Timestamp when the voting period ends
        uint8 aiProposedClassificationId;    // The classification initially proposed by the AI
        uint8 proposedChallengedClassificationId; // The classification proposed by the challenger
        mapping(uint8 => uint256) voteTallies; // classificationId => total reputation-weighted votes
        mapping(address => uint8) userVotes;   // userAddress => votedClassificationId (0 if not voted)
        uint256 totalReputationVotes;      // Total sum of reputation points cast in the dispute
        DisputeState state;                // Current state of the dispute
        bool disputeFinalized;             // True if the dispute has been finalized
        uint8 finalClassificationId;       // The winning classification ID after resolution
        bool aiAffirmed;                   // True if AI classification was affirmed without a formal dispute
    }

    // Stores information about a defined classification category
    struct ClassificationCategory {
        string name;                       // The human-readable name of the category
        bool exists;                       // True if this category ID is currently defined
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter; // Counter for ERC-721 token IDs

    // Mapping: contentHash (bytes32) => SynapticCanvasState
    mapping(bytes32 => SynapticCanvasState) public s_canvases;
    // Mapping: tokenId (uint256) => contentHash (bytes32)
    mapping(uint256 => bytes32) public s_tokenIdToContentHash;
    // Mapping: contentHash (bytes32) => DisputeInfo
    mapping(bytes32 => DisputeInfo) public s_disputes;
    // Mapping: userAddress => reputationScore (uint256)
    mapping(address => uint256) public s_userReputation;
    // Mapping: oracleAddress => AIOracleInfo
    mapping(address => AIOracleInfo) public s_aiOracles;
    // Mapping: classificationId (uint8) => ClassificationCategory
    mapping(uint8 => ClassificationCategory) public s_classificationCategories;

    // Mapping: contentHash (bytes32) => userAddress => bool (true if reward claimed)
    mapping(bytes32 => mapping(address => bool)) private _claimedDisputeRewards;

    // General protocol parameters
    uint256 public s_aiOracleStakeRequirement; // Minimum ETH required to stake as an AI oracle
    uint256 public s_challengeFee;             // ETH fee to challenge an AI classification
    uint256 public s_affirmReward;             // ETH reward for affirming a correct AI classification
    uint256 public s_disputeDuration;          // Duration (in seconds) for which disputes are open for voting
    uint256 public s_minReputationForVoting;   // Minimum reputation score required to vote in disputes
    uint256 public s_rewardPerReputationPoint; // ETH (in wei) reward multiplier per reputation point for dispute participants

    // Counters for utility queries
    uint256 private _pendingAIClassificationsCount; // Number of canvases awaiting initial AI classification
    uint256 private _totalSynapticCanvases;         // Total number of Synaptic Canvases minted
    address[] private _registeredAIOraclesList;     // List of registered AI oracle addresses for enumeration

    // --- Events ---

    event AIOracleRegistered(address indexed oracleAddress, uint256 stakeAmount);
    event AIOracleDeregistered(address indexed oracleAddress, uint256 stakeReturned);
    event AIClassificationSubmitted(bytes32 indexed contentHash, uint8 classificationId, address indexed oracleAddress, bytes32 aiProofHash);
    event CanvasMinted(uint256 indexed tokenId, bytes32 indexed contentHash, address indexed owner);
    event CanvasBurned(uint256 indexed tokenId, bytes32 indexed contentHash, address indexed burner);
    event ClassificationChallenged(bytes32 indexed contentHash, address indexed challenger, uint8 proposedClassificationId, uint256 feePaid);
    event ClassificationAffirmed(bytes32 indexed contentHash, address indexed affirmers, uint256 rewardReceived);
    event DisputeVoteCast(bytes32 indexed contentHash, address indexed voter, uint8 classificationId, uint256 reputationWeightedVote);
    event DisputeFinalized(bytes32 indexed contentHash, uint8 finalClassificationId, DisputeState finalState);
    event ReputationUpdated(address indexed user, uint256 newReputation);
    event DisputeParticipationRewardClaimed(address indexed participant, bytes32 indexed contentHash, uint256 rewardAmount);
    event ClassificationCategoryDefined(uint8 indexed categoryId, string categoryName);
    event ClassificationCategoryRemoved(uint8 indexed categoryId);

    // --- Modifiers ---

    modifier onlyRegisteredAIOracle() {
        require(s_aiOracles[msg.sender].isRegistered, "SynapticCanvas: Caller is not a registered AI oracle.");
        _;
    }

    modifier onlyContentOwner(bytes32 _contentHash) {
        require(s_canvases[_contentHash].owner == msg.sender, "SynapticCanvas: Caller is not the content owner.");
        _;
    }

    // --- I. Core Setup & Administration ---

    constructor() ERC721("SynapticCanvas", "SCT") Ownable(msg.sender) {
        // Initialize default parameters
        s_aiOracleStakeRequirement = 10 ether; // Example: 10 ETH equivalent
        s_challengeFee = 0.05 ether;          // Example: 0.05 ETH equivalent
        s_affirmReward = 0.01 ether;          // Example: 0.01 ETH equivalent
        s_disputeDuration = 3 days;           // Example: 3 days for dispute voting
        s_minReputationForVoting = 100;       // Example: Minimum 100 reputation to vote
        s_rewardPerReputationPoint = 100;     // Example: 100 wei per reputation point for rewards

        // Define initial classification categories
        _defineClassificationCategory(1, "General");
        _defineClassificationCategory(2, "Mature");
        _defineClassificationCategory(3, "Harmful");
    }

    /**
     * @notice Allows an address to register as an AI oracle provider by staking tokens.
     * @param _oracleAddress The address to register as an AI oracle.
     * @dev Only the owner can call this function. Requires `s_aiOracleStakeRequirement` ETH.
     */
    function registerAIOracleProvider(address _oracleAddress) external payable nonReentrant onlyOwner {
        require(!s_aiOracles[_oracleAddress].isRegistered, "SynapticCanvas: Oracle already registered.");
        require(msg.value >= s_aiOracleStakeRequirement, "SynapticCanvas: Insufficient stake provided.");

        s_aiOracles[_oracleAddress] = AIOracleInfo({
            isRegistered: true,
            stake: msg.value
        });
        _registeredAIOraclesList.push(_oracleAddress); // Add to list for enumeration
        emit AIOracleRegistered(_oracleAddress, msg.value);
    }

    /**
     * @notice Allows the owner to deregister an AI oracle provider.
     * @param _oracleAddress The address of the oracle to deregister.
     * @dev Only the owner can call this function. The stake can be withdrawn later by the oracle.
     */
    function deregisterAIOracleProvider(address _oracleAddress) external nonReentrant onlyOwner {
        require(s_aiOracles[_oracleAddress].isRegistered, "SynapticCanvas: Oracle not registered.");

        s_aiOracles[_oracleAddress].isRegistered = false;

        // Remove from the enumeration list
        for (uint256 i = 0; i < _registeredAIOraclesList.length; i++) {
            if (_registeredAIOraclesList[i] == _oracleAddress) {
                // Replace with last element and pop to maintain O(1) average time complexity for deletion
                _registeredAIOraclesList[i] = _registeredAIOraclesList[_registeredAIOraclesList.length - 1];
                _registeredAIOraclesList.pop();
                break;
            }
        }

        emit AIOracleDeregistered(_oracleAddress, s_aiOracles[_oracleAddress].stake);
    }

    /**
     * @notice Allows the owner to update the minimum stake required for AI oracles.
     * @param _newStake The new minimum stake amount in wei.
     * @dev Only the owner can call this function.
     */
    function updateAIOracleStakeRequirement(uint256 _newStake) external onlyOwner {
        s_aiOracleStakeRequirement = _newStake;
    }

    /**
     * @notice Allows the owner to update the fee required to challenge an AI classification.
     * @param _newFee The new challenge fee amount in wei.
     * @dev Only the owner can call this function.
     */
    function updateChallengeFee(uint256 _newFee) external onlyOwner {
        s_challengeFee = _newFee;
    }

    /**
     * @notice Allows the owner to update the reward for successfully affirming an AI classification.
     * @param _newReward The new affirmation reward amount in wei.
     * @dev Only the owner can call this function.
     */
    function updateAffirmReward(uint256 _newReward) external onlyOwner {
        s_affirmReward = _newReward;
    }

    /**
     * @notice Allows the owner to define a new content classification category.
     * @param _id The unique ID for the new category (1-255).
     * @param _name The human-readable name for the category (e.g., "Safe", "Mature").
     * @dev Only the owner can call this function. Category IDs must be unique and names non-empty.
     */
    function defineClassificationCategory(uint8 _id, string calldata _name) external onlyOwner {
        _defineClassificationCategory(_id, _name);
        emit ClassificationCategoryDefined(_id, _name);
    }

    /**
     * @dev Internal helper function to define a classification category.
     */
    function _defineClassificationCategory(uint8 _id, string calldata _name) private {
        require(!s_classificationCategories[_id].exists, "SynapticCanvas: Category ID already exists.");
        require(bytes(_name).length > 0, "SynapticCanvas: Category name cannot be empty.");
        s_classificationCategories[_id] = ClassificationCategory({
            name: _name,
            exists: true
        });
    }

    /**
     * @notice Allows the owner to remove an existing content classification category.
     * @param _id The ID of the category to remove.
     * @dev Only the owner can call this function.
     */
    function removeClassificationCategory(uint8 _id) external onlyOwner {
        require(s_classificationCategories[_id].exists, "SynapticCanvas: Category ID does not exist.");
        delete s_classificationCategories[_id];
        emit ClassificationCategoryRemoved(_id);
    }

    // --- II. Synaptic Canvas NFT (SCT) Management ---

    /**
     * @notice Mints a new Synaptic Canvas NFT for a unique content hash.
     * @param _contentHash A bytes32 hash representing the unique content (e.g., IPFS CID).
     * @return The tokenId of the newly minted Synaptic Canvas.
     * @dev Each content hash can only have one Synaptic Canvas. The NFT starts in AwaitingAI status.
     */
    function mintSynapticCanvas(bytes32 _contentHash) external nonReentrant returns (uint256) {
        require(s_canvases[_contentHash].tokenId == 0, "SynapticCanvas: Content hash already has a canvas.");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(msg.sender, newTokenId); // Mints the ERC-721 token to the caller
        _totalSynapticCanvases++;

        s_canvases[_contentHash] = SynapticCanvasState({
            tokenId: newTokenId,
            owner: msg.sender,
            status: ClassificationStatus.AwaitingAI,
            currentClassificationId: 0, // No classification yet
            mintTimestamp: block.timestamp,
            lastUpdatedTimestamp: block.timestamp,
            engagementScore: 0,
            aiProofHash: bytes32(0),
            aiOracleAddress: address(0)
        });
        s_tokenIdToContentHash[newTokenId] = _contentHash;
        _pendingAIClassificationsCount++; // Increment count of canvases awaiting AI classification

        emit CanvasMinted(newTokenId, _contentHash, msg.sender);
        return newTokenId;
    }

    /**
     * @notice Generates a dynamic metadata URI for a Synaptic Canvas NFT based on its current state.
     * @param _tokenId The ID of the Synaptic Canvas NFT.
     * @return A data URI containing the JSON metadata, Base64 encoded.
     * @dev This function dynamically creates NFT metadata including classification status, engagement, and dispute info.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes32 contentHash = s_tokenIdToContentHash[_tokenId];
        SynapticCanvasState memory canvas = s_canvases[contentHash];

        string memory classificationName = "Unclassified";
        if (canvas.currentClassificationId != 0 && s_classificationCategories[canvas.currentClassificationId].exists) {
            classificationName = s_classificationCategories[canvas.currentClassificationId].name;
        }

        string memory statusString;
        if (canvas.status == ClassificationStatus.AwaitingAI) statusString = "Awaiting AI Classification";
        else if (canvas.status == ClassificationStatus.AIClassified) statusString = "AI Classified";
        else if (canvas.status == ClassificationStatus.Disputed) statusString = "Disputed";
        else if (canvas.status == ClassificationStatus.Finalized) statusString = "Finalized";

        // Construct the base JSON metadata
        string memory json = string.concat(
            '{"name": "Synaptic Canvas #', _tokenId.toString(), '",',
            '"description": "A dynamic NFT reflecting the decentralized classification status of content. ',
            'Content Hash: 0x', Strings.toHexString(uint256(contentHash)), '",',
            '"image": "ipfs://QmbnQ4L7w5J3w5J3w5J3w5J3w5J3w5J3w5J3w5J3w5J3w",', // Placeholder image (can be dynamic based on status)
            '"attributes": [',
            '{"trait_type": "Classification Status", "value": "', statusString, '"},',
            '{"trait_type": "Current Classification", "value": "', classificationName, '"},',
            '{"trait_type": "Engagement Score", "value": ', canvas.engagementScore.toString(), '},',
            '{"trait_type": "Mint Timestamp", "value": ', canvas.mintTimestamp.toString(), '}'
        );

        // Add dispute specific attributes if the canvas is currently disputed
        if (canvas.status == ClassificationStatus.Disputed) {
            DisputeInfo memory dispute = s_disputes[contentHash];
            json = string.concat(json, ',',
                '{"trait_type": "Dispute State", "value": "', dispute.state == DisputeState.Active ? "Active" : "Resolved", '"},',
                '{"trait_type": "Dispute End Time", "value": ', dispute.endTime.toString(), '}'
            );
        }

        json = string.concat(json, ']}'); // Close JSON object

        // Encode the JSON string to Base64 and prefix with data URI scheme
        string memory baseURI = "data:application/json;base64,";
        return string.concat(baseURI, Base64.encode(bytes(json)));
    }

    /**
     * @notice Retrieves the detailed current state of a Synaptic Canvas.
     * @param _contentHash The content hash linked to the Synaptic Canvas.
     * @return A `SynapticCanvasState` struct containing all its current data.
     */
    function getCanvasState(bytes32 _contentHash) public view returns (SynapticCanvasState memory) {
        require(s_canvases[_contentHash].tokenId != 0, "SynapticCanvas: Content hash not found.");
        return s_canvases[_contentHash];
    }

    /**
     * @notice Returns the tokenId associated with a given content hash.
     * @param _contentHash The content hash to query.
     * @return The tokenId of the Synaptic Canvas.
     */
    function getCanvasTokenId(bytes32 _contentHash) public view returns (uint256) {
        require(s_canvases[_contentHash].tokenId != 0, "SynapticCanvas: Content hash not found.");
        return s_canvases[_contentHash].tokenId;
    }

    /**
     * @notice Returns the owner address of the Synaptic Canvas linked to a content hash.
     * @param _contentHash The content hash to query.
     * @return The owner's address.
     */
    function ownerOfContentHash(bytes32 _contentHash) public view returns (address) {
        return s_canvases[_contentHash].owner;
    }

    /**
     * @notice Allows the owner of a Synaptic Canvas to burn their NFT.
     * @param _tokenId The ID of the Synaptic Canvas to burn.
     * @dev The NFT cannot be burned if it is currently in a disputed state.
     */
    function burnSynapticCanvas(uint256 _tokenId) external nonReentrant {
        bytes32 contentHash = s_tokenIdToContentHash[_tokenId];
        require(_exists(_tokenId), "SynapticCanvas: Token does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "SynapticCanvas: Not the owner of this canvas.");
        require(s_canvases[contentHash].status != ClassificationStatus.Disputed, "SynapticCanvas: Cannot burn a disputed canvas.");

        _burn(_tokenId); // Standard ERC-721 burn
        _totalSynapticCanvases--;
        delete s_tokenIdToContentHash[_tokenId]; // Remove tokenId to contentHash mapping
        delete s_canvases[contentHash];           // Remove canvas state

        // Adjust _pendingAIClassificationsCount if the burned canvas was awaiting AI classification
        if (s_canvases[contentHash].status == ClassificationStatus.AwaitingAI) {
            _pendingAIClassificationsCount--;
        }

        emit CanvasBurned(_tokenId, contentHash, msg.sender);
    }

    // --- III. AI Oracle Interactions ---

    /**
     * @notice Allows a registered AI oracle to submit a classification for a content hash.
     * @param _contentHash The content hash to classify.
     * @param _classificationId The ID of the classification proposed by the AI.
     * @param _aiProofHash A bytes32 hash representing an off-chain proof of the AI's classification.
     * @dev Only registered AI oracles can call this. The canvas must be in 'AwaitingAI' status.
     */
    function submitAIClassification(
        bytes32 _contentHash,
        uint8 _classificationId,
        bytes32 _aiProofHash
    ) external nonReentrant onlyRegisteredAIOracle {
        SynapticCanvasState storage canvas = s_canvases[_contentHash];
        require(canvas.tokenId != 0, "SynapticCanvas: Canvas not found for hash.");
        require(canvas.status == ClassificationStatus.AwaitingAI, "SynapticCanvas: Canvas not awaiting AI classification.");
        require(s_classificationCategories[_classificationId].exists, "SynapticCanvas: Invalid classification ID.");

        canvas.status = ClassificationStatus.AIClassified;
        canvas.currentClassificationId = _classificationId;
        canvas.aiProofHash = _aiProofHash;
        canvas.aiOracleAddress = msg.sender;
        canvas.lastUpdatedTimestamp = block.timestamp;

        _pendingAIClassificationsCount--; // Decrement count as it's now classified by AI
        _updateReputation(msg.sender, 5); // Example: AI oracle gains reputation for submitting

        emit AIClassificationSubmitted(_contentHash, _classificationId, msg.sender, _aiProofHash);
    }

    /**
     * @notice Retrieves the latest AI classification data for a content hash.
     * @param _contentHash The content hash to query.
     * @return classificationId The classification ID.
     * @return aiProofHash The hash of the AI's proof.
     * @return oracleAddress The address of the AI oracle.
     * @return timestamp The timestamp when the AI classification was submitted.
     * @dev Requires that an AI classification has already been submitted for the content.
     */
    function getAIClassification(bytes32 _contentHash)
        public
        view
        returns (uint8 classificationId, bytes32 aiProofHash, address oracleAddress, uint256 timestamp)
    {
        SynapticCanvasState memory canvas = s_canvases[_contentHash];
        require(canvas.tokenId != 0, "SynapticCanvas: Content hash not found.");
        require(
            canvas.status == ClassificationStatus.AIClassified ||
            canvas.status == ClassificationStatus.Disputed ||
            canvas.status == ClassificationStatus.Finalized,
            "SynapticCanvas: AI classification not yet submitted or unavailable."
        );

        return (
            canvas.currentClassificationId,
            canvas.aiProofHash,
            canvas.aiOracleAddress,
            canvas.lastUpdatedTimestamp
        );
    }

    // --- IV. Community Vetting & Dispute Resolution ---

    /**
     * @notice Allows a user to challenge an AI's classification, initiating a dispute.
     * @param _contentHash The content hash of the canvas whose classification is being challenged.
     * @param _proposedClassificationId The classification ID the challenger believes is correct.
     * @dev Requires a fee to be paid. Canvas must be in 'AIClassified' state and not already disputed.
     */
    function challengeAIClassification(bytes32 _contentHash, uint8 _proposedClassificationId) external payable nonReentrant {
        SynapticCanvasState storage canvas = s_canvases[_contentHash];
        require(canvas.tokenId != 0, "SynapticCanvas: Canvas not found.");
        require(canvas.status == ClassificationStatus.AIClassified, "SynapticCanvas: Canvas not in AI Classified state.");
        require(msg.value >= s_challengeFee, "SynapticCanvas: Insufficient challenge fee.");
        require(s_classificationCategories[_proposedClassificationId].exists, "SynapticCanvas: Invalid proposed classification ID.");
        require(_proposedClassificationId != canvas.currentClassificationId, "SynapticCanvas: Cannot challenge with the same classification.");

        // Refund any excess ETH sent by the challenger
        if (msg.value > s_challengeFee) {
            payable(msg.sender).transfer(msg.value - s_challengeFee);
        }

        DisputeInfo storage dispute = s_disputes[_contentHash];
        require(dispute.state == DisputeState.NoDispute, "SynapticCanvas: Dispute already active for this content.");

        dispute.startTime = block.timestamp;
        dispute.endTime = block.timestamp + s_disputeDuration;
        dispute.aiProposedClassificationId = canvas.currentClassificationId;
        dispute.proposedChallengedClassificationId = _proposedClassificationId; // Store challenger's proposal
        dispute.state = DisputeState.Active;
        dispute.disputeFinalized = false;
        dispute.aiAffirmed = false;

        // The challenger's initial vote is automatically cast
        _submitVoteInternal(_contentHash, msg.sender, _proposedClassificationId);

        canvas.status = ClassificationStatus.Disputed; // Update canvas status
        canvas.lastUpdatedTimestamp = block.timestamp;
        canvas.engagementScore++; // Increase engagement score

        emit ClassificationChallenged(_contentHash, msg.sender, _proposedClassificationId, s_challengeFee);
    }

    /**
     * @notice Allows a user to affirm an AI's classification.
     * @param _contentHash The content hash of the canvas whose classification is being affirmed.
     * @dev Rewards the affirmer and can lead to faster finalization if no dispute is initiated.
     */
    function affirmAIClassification(bytes32 _contentHash) external nonReentrant {
        SynapticCanvasState storage canvas = s_canvases[_contentHash];
        require(canvas.tokenId != 0, "SynapticCanvas: Canvas not found.");
        require(canvas.status == ClassificationStatus.AIClassified, "SynapticCanvas: Canvas not in AI Classified state.");

        DisputeInfo storage dispute = s_disputes[_contentHash];
        require(dispute.state == DisputeState.NoDispute, "SynapticCanvas: Dispute already active for this content.");

        // Reward the affirmer
        payable(msg.sender).transfer(s_affirmReward);
        _updateReputation(msg.sender, 2); // Small reputation boost for affirming

        // Update canvas status to Finalized
        canvas.status = ClassificationStatus.Finalized;
        canvas.lastUpdatedTimestamp = block.timestamp;
        canvas.engagementScore++;

        // Mark dispute info as resolved and affirmed
        dispute.state = DisputeState.Resolved;
        dispute.disputeFinalized = true;
        dispute.finalClassificationId = canvas.currentClassificationId; // AI's classification is the final one
        dispute.aiAffirmed = true; // Mark as affirmed without dispute

        emit ClassificationAffirmed(_contentHash, msg.sender, s_affirmReward);
        emit DisputeFinalized(_contentHash, canvas.currentClassificationId, DisputeState.Resolved);
    }

    /**
     * @notice Allows users to cast their reputation-weighted vote in an active dispute.
     * @param _contentHash The content hash of the disputed canvas.
     * @param _votedClassificationId The classification ID the user votes for.
     * @dev User must have minimum reputation and not have voted yet in this dispute.
     */
    function submitDisputeVote(bytes32 _contentHash, uint8 _votedClassificationId) external nonReentrant {
        DisputeInfo storage dispute = s_disputes[_contentHash];
        require(dispute.state == DisputeState.Active, "SynapticCanvas: No active dispute for this content.");
        require(block.timestamp < dispute.endTime, "SynapticCanvas: Dispute voting period has ended.");
        require(s_userReputation[msg.sender] >= s_minReputationForVoting, "SynapticCanvas: Insufficient reputation to vote.");
        require(s_classificationCategories[_votedClassificationId].exists, "SynapticCanvas: Invalid classification ID.");
        require(dispute.userVotes[msg.sender] == 0, "SynapticCanvas: You have already voted in this dispute."); // 0 means no vote

        _submitVoteInternal(_contentHash, msg.sender, _votedClassificationId);

        emit DisputeVoteCast(_contentHash, msg.sender, _votedClassificationId, s_userReputation[msg.sender]);
    }

    /**
     * @dev Internal helper function to record a vote in a dispute.
     * @param _contentHash The content hash of the disputed canvas.
     * @param _voter The address of the voter.
     * @param _votedClassificationId The classification ID the voter chose.
     */
    function _submitVoteInternal(bytes32 _contentHash, address _voter, uint8 _votedClassificationId) private {
        DisputeInfo storage dispute = s_disputes[_contentHash];
        uint256 voterReputation = s_userReputation[_voter];
        
        // If voter's reputation is below minimum, their vote carries no weight
        if (voterReputation < s_minReputationForVoting) {
            voterReputation = 0;
        }
        
        dispute.userVotes[_voter] = _votedClassificationId;
        dispute.voteTallies[_votedClassificationId] += voterReputation; // Add reputation-weighted vote
        dispute.totalReputationVotes += voterReputation;
    }

    /**
     * @notice Finalizes a dispute after its voting period, applying the consensus classification to the Synaptic Canvas.
     * @param _contentHash The content hash of the disputed canvas.
     * @dev Callable by anyone once the dispute's voting period has ended. Determines winner based on reputation-weighted votes.
     */
    function finalizeDispute(bytes32 _contentHash) external nonReentrant {
        SynapticCanvasState storage canvas = s_canvases[_contentHash];
        DisputeInfo storage dispute = s_disputes[_contentHash];

        require(canvas.tokenId != 0, "SynapticCanvas: Canvas not found.");
        require(dispute.state == DisputeState.Active, "SynapticCanvas: No active dispute to finalize.");
        require(block.timestamp >= dispute.endTime, "SynapticCanvas: Dispute voting period not yet ended.");
        require(!dispute.disputeFinalized, "SynapticCanvas: Dispute already finalized.");

        uint8 winningClassificationId = dispute.aiProposedClassificationId;
        uint256 maxVotes = dispute.voteTallies[dispute.aiProposedClassificationId];
        
        // Compare votes for AI's proposed classification vs. challenger's proposed classification
        // For simplicity, only these two are considered the primary options in dispute resolution.
        // If tied, the AI's original classification wins by default.
        if (dispute.voteTallies[dispute.proposedChallengedClassificationId] > maxVotes) {
            maxVotes = dispute.voteTallies[dispute.proposedChallengedClassificationId];
            winningClassificationId = dispute.proposedChallengedClassificationId;
        }
        
        dispute.finalClassificationId = winningClassificationId;
        canvas.currentClassificationId = winningClassificationId;
        canvas.status = ClassificationStatus.Finalized;
        canvas.lastUpdatedTimestamp = block.timestamp;
        dispute.state = DisputeState.Resolved;
        dispute.disputeFinalized = true;

        // Reputation adjustments based on dispute outcome
        if (winningClassificationId == dispute.proposedChallengedClassificationId) {
            // Challenger's side won, potential reputation boost for challenger (and other aligning voters)
            // (Actual individual voter rewards are handled via claimDisputeParticipationReward)
        } else {
            // AI's side won (or AI's initial classification remained), reputation boost for AI oracle
            _updateReputation(dispute.aiOracleAddress, 10);
        }
        
        emit DisputeFinalized(_contentHash, winningClassificationId, DisputeState.Resolved);
    }

    /**
     * @notice Returns the current state (active, pending, resolved) of a content hash's dispute.
     * @param _contentHash The content hash to query.
     * @return The `DisputeState` enum value.
     */
    function getDisputeStatus(bytes32 _contentHash) public view returns (DisputeState) {
        return s_disputes[_contentHash].state;
    }

    /**
     * @notice Retrieves the total reputation votes for each classification category in an active dispute.
     * @param _contentHash The content hash of the disputed canvas.
     * @return classificationIds An array of classification IDs that received votes in the dispute.
     * @return voteCounts An array of the corresponding reputation-weighted vote totals.
     * @dev Only returns tallies for the AI's proposed and the challenger's proposed categories for simplicity.
     */
    function getDisputeVoteTallies(bytes32 _contentHash) public view returns (uint8[] memory classificationIds, uint256[] memory voteCounts) {
        DisputeInfo storage dispute = s_disputes[_contentHash];
        require(dispute.state != DisputeState.NoDispute, "SynapticCanvas: No dispute data.");

        // For this demo, only consider the two main classifications in a dispute:
        // the AI's original proposal and the challenger's specific counter-proposal.
        classificationIds = new uint8[](2); 
        voteCounts = new uint256[](2);

        classificationIds[0] = dispute.aiProposedClassificationId;
        voteCounts[0] = dispute.voteTallies[dispute.aiProposedClassificationId];

        classificationIds[1] = dispute.proposedChallengedClassificationId;
        voteCounts[1] = dispute.voteTallies[dispute.proposedChallengedClassificationId];

        return (classificationIds, voteCounts);
    }

    /**
     * @notice Returns the timestamp when the current dispute for a content hash is scheduled to end.
     * @param _contentHash The content hash to query.
     * @return The Unix timestamp of the dispute's end time.
     */
    function getDisputeEndTime(bytes32 _contentHash) public view returns (uint256) {
        return s_disputes[_contentHash].endTime;
    }

    /**
     * @notice Returns the classification ID a specific user voted for in a dispute.
     * @param _contentHash The content hash of the dispute.
     * @param _voter The address of the user.
     * @return The classification ID voted for (0 if no vote was cast by this user).
     */
    function getUserVoteInDispute(bytes32 _contentHash, address _voter) public view returns (uint8) {
        return s_disputes[_contentHash].userVotes[_voter];
    }

    // --- V. Reputation System & Rewards ---

    /**
     * @notice Retrieves the current reputation score of a given user.
     * @param _user The address of the user to query.
     * @return The user's current reputation score.
     */
    function getUserReputation(address _user) public view returns (uint256) {
        return s_userReputation[_user];
    }

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address whose reputation is being updated.
     * @param _change The amount of reputation to add (positive) or subtract (negative).
     */
    function _updateReputation(address _user, int256 _change) private {
        if (_change < 0) {
            // Ensure reputation doesn't go below zero
            if (s_userReputation[_user] < uint256(uint256(-_change))) {
                s_userReputation[_user] = 0;
            } else {
                s_userReputation[_user] -= uint256(uint256(-_change));
            }
        } else {
            s_userReputation[_user] += uint256(_change);
        }
        emit ReputationUpdated(_user, s_userReputation[_user]);
    }

    /**
     * @notice Allows a deregistered AI oracle provider to withdraw their staked tokens.
     * @dev Callable by the oracle address only after they have been deregistered.
     */
    function withdrawOracleStake() external nonReentrant {
        AIOracleInfo storage oracle = s_aiOracles[msg.sender];
        require(!oracle.isRegistered, "SynapticCanvas: Oracle is still registered.");
        require(oracle.stake > 0, "SynapticCanvas: No stake to withdraw.");

        uint256 amount = oracle.stake;
        oracle.stake = 0; // Reset stake immediately to prevent reentrancy issues

        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Allows users who voted with the winning side in a dispute to claim a reward.
     * @param _contentHash The content hash of the dispute for which to claim rewards.
     * @dev Rewards are calculated based on the user's reputation and a fixed reward per point.
     * Requires the dispute to be resolved and the user's vote to match the final consensus.
     */
    function claimDisputeParticipationReward(bytes32 _contentHash) external nonReentrant {
        DisputeInfo storage dispute = s_disputes[_contentHash];
        require(dispute.state == DisputeState.Resolved, "SynapticCanvas: Dispute is not resolved.");
        require(block.timestamp >= dispute.endTime, "SynapticCanvas: Dispute not yet ended."); // Ensure dispute has finished time-wise

        uint8 userVote = dispute.userVotes[msg.sender];
        require(userVote != 0, "SynapticCanvas: You did not vote in this dispute.");
        require(userVote == dispute.finalClassificationId, "SynapticCanvas: Your vote did not align with the final consensus.");
        
        // Prevent claiming multiple times for the same dispute by the same user
        require(!_claimedDisputeRewards[_contentHash][msg.sender], "SynapticCanvas: Reward already claimed for this dispute.");

        uint256 reputationPoints = s_userReputation[msg.sender];
        uint256 rewardAmount = reputationPoints * s_rewardPerReputationPoint;
        require(rewardAmount > 0, "SynapticCanvas: No reward calculated for your participation.");

        _claimedDisputeRewards[_contentHash][msg.sender] = true; // Mark as claimed

        // A real system would have a dedicated reward pool or treasury.
        // For this demo, we'll transfer from the contract's balance (which would be topped up by challenge fees).
        require(address(this).balance >= rewardAmount, "SynapticCanvas: Insufficient contract balance for reward.");
        
        payable(msg.sender).transfer(rewardAmount);
        _updateReputation(msg.sender, 5); // Small reputation boost for successfully claiming reward

        emit DisputeParticipationRewardClaimed(msg.sender, _contentHash, rewardAmount);
    }

    // --- VI. Utility & State Query Functions ---

    /**
     * @notice Returns the total number of Synaptic Canvases minted.
     * @return The total supply of Synaptic Canvas NFTs.
     */
    function getTotalSynapticCanvases() public view returns (uint256) {
        return _totalSynapticCanvases;
    }

    /**
     * @notice Returns a list of all currently registered AI oracle addresses.
     * @return An array of addresses of active AI oracles.
     */
    function getRegisteredAIOracles() public view returns (address[] memory) {
        return _registeredAIOraclesList;
    }

    /**
     * @notice Returns a list of all defined classification category IDs and their corresponding names.
     * @return categoryIds An array of all valid classification IDs.
     * @return categoryNames An array of the corresponding category names.
     */
    function getClassificationCategories() public view returns (uint8[] memory categoryIds, string[] memory categoryNames) {
        uint256 count = 0;
        // Iterate up to 255 (max uint8 value) to find all defined categories
        for (uint8 i = 0; i < 255; i++) { 
            if (s_classificationCategories[i].exists) {
                count++;
            }
        }

        categoryIds = new uint8[](count);
        categoryNames = new string[](count);
        uint256 index = 0;
        for (uint8 i = 0; i < 255; i++) {
            if (s_classificationCategories[i].exists) {
                categoryIds[index] = i;
                categoryNames[index] = s_classificationCategories[i].name;
                index++;
            }
        }
        return (categoryIds, categoryNames);
    }

    /**
     * @notice Returns the number of Synaptic Canvases currently awaiting an initial AI classification.
     * @return The count of canvases in `AwaitingAI` status.
     */
    function getPendingClassificationCount() public view returns (uint256) {
        return _pendingAIClassificationsCount;
    }

    // Fallback and Receive functions to allow the contract to receive ETH for stakes and fees
    receive() external payable {}
    fallback() external payable {}
}

```