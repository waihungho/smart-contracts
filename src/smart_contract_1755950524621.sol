Here's a Solidity smart contract named "AuraWeaverProtocol" that incorporates several advanced, creative, and trendy concepts: **Dynamic NFTs (dNFTs), AI Oracle Integration (Simulated), Gamified Reputation System, Decentralized Knowledge Contribution, and a Dispute Mechanism.**

It avoids duplicating any open-source functionality directly by building a novel system on top of standard OpenZeppelin ERC-721, ERC-20, and Ownable contracts.

---

**Outline and Function Summary**

**Contract Name:** AuraWeaverProtocol

**Core Idea:** A decentralized protocol for the collaborative creation and evolution of "Sentient Relics" (dynamic NFTs) that embody evolving knowledge. Relics gain "Aura" (reputation) through community-submitted insights, verified by an AI oracle, and by completing "Aura Quests." Contributors are rewarded with "Insight Shards" (ERC-20).

**Key Concepts:**
*   **Sentient Relics (ERC721 dNFTs):** NFTs that evolve in stages, their metadata dynamically updated based on accrued "Aura." The visual representation of the NFT would change on platforms supporting dynamic metadata.
*   **Aura:** A non-transferable reputation metric for Relics, accumulated through validated insights and quest completion.
*   **Insight Shards (ERC20):** A fungible token rewarded to contributors for valuable insights and quest solutions. The supply is controlled by the AuraWeaverProtocol.
*   **AI Oracle Integration (Simulated):** An external service (mocked as a trusted address within this contract) that evaluates the quality and relevance of submitted knowledge. In a real-world deployment, this would use a decentralized oracle network like Chainlink.
*   **Chronicle:** An on-chain immutable log of all verified insights associated with a Relic, providing a verifiable history of its knowledge accumulation.
*   **Aura Quests:** Bounties proposed by Relic owners to incentivize specific research or data contributions, fostering collaborative problem-solving.
*   **Dispute Mechanism:** Allows community members to challenge AI verification results or quest outcomes, adding a layer of decentralized moderation and accountability.

---

**I. Protocol Administration & Core Setup (5 functions)**
1.  `constructor(address _initialAIOracle)`: Initializes the `AuraWeaverProtocol` contract, deploys the `InsightShards` ERC-20 token, sets the initial owner, and designates the initial AI oracle address.
2.  `setProtocolFeeRecipient(address _newRecipient)`: Updates the address that receives any future protocol fees (currently no fees implemented, but provides extensibility).
3.  `setAIOracleAddress(address _newOracle)`: Sets the trusted address of the external AI Oracle contract that will provide verification callbacks.
4.  `setAuraStageThresholds(uint[] memory _thresholds, string[] memory _baseURIs)`: Defines the `Aura` point thresholds required for Relics to ascend to different stages, along with the corresponding base URIs for their dynamic metadata.
5.  `setInsightShardMintRate(uint _rate)`: Adjusts the rate at which `InsightShards` are minted and rewarded per unit of `Aura` gained by a Relic.

**II. Sentient Relic (ERC721) Management (6 functions)**
6.  `mintDormantRelic(address _to, string memory _initialMetadataURI)`: Mints a new "Dormant" `Sentient Relic` NFT to a specified address with an initial metadata URI, ready to begin its evolution.
7.  `tokenURI(uint256 _relicId)`: Overrides the standard ERC721 `tokenURI` function to return the *current* dynamic metadata URI for a given Relic, which changes as the Relic ascends stages.
8.  `getRelicDetails(uint256 _relicId)`: Retrieves comprehensive data about a specific `Sentient Relic`, including its owner, `Aura`, current stage, and associated history.
9.  `getRelicChronicleEntries(uint256 _relicId)`: Returns an array of `entryId`s, listing all the `Insight Chronicle` entries associated with a particular Relic.
10. `getRelicActiveQuests(uint256 _relicId)`: Returns an array of `questId`s, listing quests currently active or proposed for a specific Relic.
11. `_checkAndAscendRelic(uint256 _relicId)` (Internal): A private helper function that automatically checks if a Relic's `Aura` has surpassed a predefined stage threshold and, if so, updates its stage and metadata URI.

**III. Insight Shard (ERC20) Management (3 functions)**
12. `mintShardsForContribution(address _to, uint _amount)` (Internal/Restricted): A controlled internal function to mint `Insight Shards` and transfer them to a contributor as a reward for verified insights or quest solutions.
13. `burnShardsForPenalty(address _from, uint _amount)` (Internal/Restricted): A controlled internal function to burn `Insight Shards` from an address, used for penalty mechanisms (e.g., failed disputes).
14. `getTotalShardsInCirculation()`: Returns the total supply of `Insight Shards` that have been minted and are currently in circulation.

**IV. Knowledge Weaving & Verification (6 functions)**
15. `submitInsightForRelic(uint256 _relicId, string memory _contentHash)`: Allows any user to submit a new piece of knowledge (referenced by an IPFS CID or similar `_contentHash`) to a `Sentient Relic` for potential `Aura` gain.
16. `receiveAIVerificationResult(uint256 _entryId, uint _aiScore, bool _isValid)`: This is the callback function intended to be invoked *only* by the trusted `aiOracleAddress`. It delivers the AI's verification result for a submitted insight, updating its status, `Aura`, and `Insight Shard` rewards.
17. `getChronicleEntryDetails(uint256 _entryId)`: Retrieves the full details of a specific `Chronicle Entry`, including its content hash, contributor, verification status, and rewards.
18. `disputeInsightVerification(uint256 _entryId, string memory _reasonHash)`: Allows a user to initiate a dispute against an AI's verification result for an insight, requiring a staked `Insight Shard` fee.
19. `resolveDispute(uint256 _entryId, bool _overruleAI, uint _newScore)` (Admin/DAO): A privileged function (currently `onlyOwner`, but intended for DAO governance) to resolve an active dispute, potentially overriding the AI's initial decision and adjusting rewards/penalties.
20. `_requestAIVerification(uint256 _entryId, string memory _contentHash)` (Internal): A private function that, in a real system, would interface with an external oracle (e.g., Chainlink) to send a request for AI verification of an insight. Here, it's a simulation.

**V. Aura Quests (7 functions)**
21. `proposeAuraQuest(uint256 _relicId, string memory _title, string memory _descriptionHash, uint _bountyAmount)`: A `Sentient Relic` owner can propose a research or data bounty (`Aura Quest`), staking `Insight Shards` as a reward for successful completion.
22. `acceptAuraQuest(uint256 _questId)`: Allows any community member to formally accept an open `Aura Quest`, committing to deliver a solution.
23. `submitQuestSolution(uint256 _questId, string memory _submissionHash)`: The accepted solver submits their solution for a quest (referenced by an `_submissionHash`).
24. `verifyQuestSolution(uint256 _questId, bool _isSolutionValid, uint _auraGainForRelic)`: The `Relic` owner (or designated verifier) evaluates the submitted quest solution, determines its validity, awards `Insight Shards`, and grants `Aura` to the `Relic`.
25. `getQuestDetails(uint256 _questId)`: Retrieves all the details about a specific `Aura Quest`, including its status, solver, and bounty.
26. `cancelAuraQuest(uint256 _questId)`: Allows the original proposer to cancel an `Open` quest, refunding the staked bounty if no solver has accepted it yet.
27. `reclaimBountyAfterTimeout(uint256 _questId)`: Enables the quest proposer to reclaim their staked bounty if an accepted quest's solution is not submitted within the specified `questCompletionTimeout`.

**VI. Protocol Governance (2 functions - Placeholder for future DAO integration)**
28. `initiateParameterUpdateProposal(bytes32 _paramKey, bytes memory _newValue)`: A placeholder function allowing a privileged entity (e.g., a future DAO) to propose changes to core protocol parameters.
29. `executeParameterUpdate(bytes32 _paramKey, bytes memory _newValue)`: A placeholder function to execute a proposed parameter update. In a full DAO, this would happen only after a successful governance vote and timelock period.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Helper library for enum to uint conversion
library EnumToUint {
    function toUint(AuraWeaverProtocol.RelicStage self) internal pure returns (uint256) {
        return uint256(self);
    }
}

/**
 * @title InsightShards
 * @dev An ERC-20 token used for rewards within the AuraWeaverProtocol.
 * Its minting and burning capabilities are restricted to the AuraWeaverProtocol contract.
 */
contract InsightShards is ERC20, Ownable {
    constructor() ERC20("Insight Shards", "ISH") Ownable(msg.sender) {}

    /**
     * @notice Mints new Insight Shards and assigns them to an address.
     * @dev Only callable by the owner (AuraWeaverProtocol contract).
     * @param to The address to receive the minted shards.
     * @param amount The amount of shards to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns Insight Shards from an address.
     * @dev Only callable by the owner (AuraWeaverProtocol contract).
     * @param from The address from which to burn shards.
     * @param amount The amount of shards to burn.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}

/**
 * @title AuraWeaverProtocol
 * @dev A decentralized protocol for dynamic NFTs (Sentient Relics) that evolve based on AI-verified knowledge contributions and quests.
 * Includes ERC-721 for Relics, ERC-20 for Insight Shards, simulated AI oracle integration, and a dispute mechanism.
 */
contract AuraWeaverProtocol is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256; // For safe arithmetic operations
    using Address for address; // For address utility functions
    using EnumToUint for RelicStage; // For converting RelicStage enum to uint

    // --- State Variables ---

    InsightShards public insightShards; // Instance of the ERC20 token for rewards

    Counters.Counter private _relicIds; // Counter for unique Relic IDs
    Counters.Counter private _chronicleEntryIds; // Counter for unique Chronicle Entry IDs
    Counters.Counter private _questIds; // Counter for unique Aura Quest IDs

    address public aiOracleAddress; // Trusted address for AI oracle callbacks
    address public protocolFeeRecipient; // Address to receive protocol fees

    // Protocol parameters (configurable by owner/DAO)
    uint256 public insightShardMintRate = 100; // Shards minted per Aura point (e.g., 100 ISH for 1 Aura)
    uint256 public disputeFee = 100 * (10 ** 18); // Example: 100 ISH required to dispute an insight
    uint256 public questCompletionTimeout = 7 days; // Time (in seconds) for a solver to submit a quest solution

    // --- Enums ---

    enum RelicStage { Dormant, Awakened, Enlightened, Transcendent }
    enum VerificationStatus { Pending, Verified, Rejected, Disputed }
    enum QuestStatus { Open, Accepted, SolutionSubmitted, Verified, Cancelled, TimedOut }

    // --- Structs ---

    /**
     * @dev Represents a dynamic NFT (Sentient Relic).
     */
    struct SentientRelic {
        uint256 aura; // Reputation points accumulated by the Relic
        uint256 creationTimestamp; // Timestamp of Relic creation
        RelicStage currentStage; // Current evolutionary stage of the Relic
        string currentMetadataURI; // Dynamic metadata URI reflecting the current stage
        uint256[] chronicleEntries; // Array of IDs of insights woven into this Relic
        uint256[] activeQuests; // Array of IDs of quests currently associated with this Relic
    }
    mapping(uint256 => SentientRelic) public relics;

    /**
     * @dev Represents an entry in a Relic's knowledge chronicle.
     */
    struct ChronicleEntry {
        uint256 relicId; // ID of the Relic this insight belongs to
        address contributor; // Address of the user who submitted the insight
        string contentHash; // IPFS CID or similar hash pointing to the submitted knowledge
        uint256 timestamp; // Timestamp of insight submission
        uint256 auraGain; // Aura points gained by the Relic upon verification
        uint256 shardReward; // ISH rewarded to contributor upon verification
        VerificationStatus verificationStatus; // Current verification status
        uint256 aiScore; // Score from AI oracle (e.g., 0-100)
        address disputer; // Address that initiated a dispute (if any)
        string disputeReasonHash; // IPFS CID for the reason of dispute
    }
    mapping(uint256 => ChronicleEntry) public chronicleEntries;

    /**
     * @dev Represents an Aura Quest bounty for research or contribution.
     */
    struct AuraQuest {
        uint256 relicId; // ID of the Relic this quest is associated with
        address proposer; // Address of the Relic owner who proposed the quest
        string title; // Title of the quest
        string descriptionHash; // IPFS CID for detailed quest description
        uint256 bountyAmount; // Amount of Insight Shards offered as bounty
        QuestStatus status; // Current status of the quest
        address acceptedSolver; // Address of the user who accepted the quest
        string submissionHash; // IPFS CID for the solver's submitted solution
        uint256 acceptedTimestamp; // Timestamp when the quest was accepted
        uint256 completionTimestamp; // Timestamp when the quest was completed/verified
        bool solutionValid; // True if the submitted solution was deemed valid
    }
    mapping(uint256 => AuraQuest) public auraQuests;

    // Relic stage thresholds and corresponding URI base paths (configurable)
    uint256[] public auraStageThresholds; // e.g., [0, 1000, 5000, 10000] Aura points
    string[] public relicStageBaseURIs; // e.g., ["ipfs://dormant/", "ipfs://awakened/", ...]

    // --- Events ---

    event RelicMinted(uint256 indexed relicId, address indexed owner, string initialURI);
    event RelicAscended(uint256 indexed relicId, RelicStage newStage, uint256 newAura, string newURI);
    event InsightSubmitted(uint256 indexed entryId, uint256 indexed relicId, address indexed contributor, string contentHash);
    event AIVerificationReceived(uint256 indexed entryId, uint256 aiScore, bool isValid);
    event AuraGained(uint256 indexed relicId, uint256 entryId, uint256 auraAmount);
    event InsightShardsMinted(address indexed recipient, uint256 amount);
    event InsightDisputed(uint256 indexed entryId, address indexed disputer, string reasonHash);
    event DisputeResolved(uint256 indexed entryId, bool overruleAI, uint256 newScore);
    event AuraQuestProposed(uint256 indexed questId, uint256 indexed relicId, address indexed proposer, uint256 bountyAmount);
    event AuraQuestAccepted(uint256 indexed questId, address indexed solver);
    event AuraQuestSolutionSubmitted(uint256 indexed questId, address indexed solver, string submissionHash);
    event AuraQuestVerified(uint256 indexed questId, bool solutionValid, uint256 auraGain);
    event AuraQuestCancelled(uint256 indexed questId);
    event AuraQuestBountyReclaimed(uint256 indexed questId, address indexed proposer, uint256 amount);
    event ProtocolParameterUpdated(bytes32 paramKey, bytes newValue);

    // --- Modifiers ---

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "AuraWeaver: Only AI Oracle can call this function");
        _;
    }

    modifier onlyRelicOwner(uint256 _relicId) {
        require(_exists(_relicId), "AuraWeaver: Relic does not exist");
        require(ownerOf(_relicId) == msg.sender, "AuraWeaver: Not relic owner");
        _;
    }

    modifier onlyQuestProposer(uint256 _questId) {
        require(_questIds.current() >= _questId && _questId > 0, "AuraWeaver: Quest does not exist");
        require(auraQuests[_questId].proposer == msg.sender, "AuraWeaver: Not quest proposer");
        _;
    }

    // --- Constructor ---

    /**
     * @dev Initializes the AuraWeaverProtocol contract.
     * Deploys the InsightShards ERC20 token and transfers its ownership to this contract.
     * Sets the initial AI oracle address and protocol fee recipient.
     * @param _initialAIOracle The address of the initial trusted AI Oracle contract.
     */
    constructor(address _initialAIOracle)
        ERC721("Sentient Relic", "RELC")
        Ownable(msg.sender)
    {
        insightShards = new InsightShards();
        // Transfer ownership of InsightShards to this contract, allowing it to control minting/burning
        insightShards.transferOwnership(address(this));

        aiOracleAddress = _initialAIOracle;
        require(aiOracleAddress != address(0), "AuraWeaver: AI Oracle address cannot be zero");

        protocolFeeRecipient = msg.sender; // Initial fee recipient is the contract deployer
    }

    // --- I. Protocol Administration & Core Setup ---

    /**
     * @notice Updates the address designated to receive protocol fees.
     * @param _newRecipient The new address for fee reception.
     */
    function setProtocolFeeRecipient(address _newRecipient) public onlyOwner {
        require(_newRecipient != address(0), "AuraWeaver: Recipient cannot be zero address");
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @notice Sets the address of the trusted AI Oracle contract.
     * @param _newOracle The new address of the AI Oracle.
     */
    function setAIOracleAddress(address _newOracle) public onlyOwner {
        require(_newOracle != address(0), "AuraWeaver: AI Oracle address cannot be zero");
        aiOracleAddress = _newOracle;
    }

    /**
     * @notice Defines the Aura thresholds for Relic ascension stages and their corresponding metadata URIs.
     * @dev The first threshold must be 0 for the Dormant stage. Thresholds must be in ascending order.
     * @param _thresholds An array of Aura points required to reach each stage.
     * @param _baseURIs An array of base URIs for the metadata of each stage. Must match _thresholds length.
     */
    function setAuraStageThresholds(uint256[] memory _thresholds, string[] memory _baseURIs) public onlyOwner {
        require(_thresholds.length > 0, "AuraWeaver: Thresholds cannot be empty");
        require(_thresholds.length == _baseURIs.length, "AuraWeaver: Thresholds and URIs length mismatch");
        require(_thresholds[0] == 0, "AuraWeaver: First threshold must be 0 for Dormant stage");

        for (uint i = 1; i < _thresholds.length; i++) {
            require(_thresholds[i] > _thresholds[i-1], "AuraWeaver: Thresholds must be in ascending order");
        }
        auraStageThresholds = _thresholds;
        relicStageBaseURIs = _baseURIs;
    }

    /**
     * @notice Adjusts the rate at which Insight Shards are minted per unit of Aura gain.
     * @param _rate The new mint rate (e.g., 100 for 100 ISH per Aura point).
     */
    function setInsightShardMintRate(uint256 _rate) public onlyOwner {
        insightShardMintRate = _rate;
    }

    // --- II. Sentient Relic (ERC721) Management ---

    /**
     * @notice Mints a new "Dormant" Sentient Relic NFT.
     * @param _to The address to mint the Relic to.
     * @param _initialMetadataURI The initial metadata URI for the Dormant stage.
     * @return The ID of the newly minted Relic.
     */
    function mintDormantRelic(address _to, string memory _initialMetadataURI) public returns (uint256) {
        _relicIds.increment();
        uint256 newRelicId = _relicIds.current();

        SentientRelic storage newRelic = relics[newRelicId];
        newRelic.aura = 0;
        newRelic.creationTimestamp = block.timestamp;
        newRelic.currentStage = RelicStage.Dormant;
        newRelic.currentMetadataURI = _initialMetadataURI;
        // chronicleEntries and activeQuests start empty

        _mint(_to, newRelicId);
        _setTokenURI(newRelicId, _initialMetadataURI); // Set URI via ERC721URIStorage

        emit RelicMinted(newRelicId, _to, _initialMetadataURI);
        return newRelicId;
    }

    /**
     * @notice Returns the current metadata URI for a given Relic, reflecting its stage.
     * @param _relicId The ID of the Relic.
     * @return The current metadata URI.
     */
    function tokenURI(uint256 _relicId) public view override returns (string memory) {
        require(_exists(_relicId), "ERC721URIStorage: URI query for nonexistent token");
        return relics[_relicId].currentMetadataURI;
    }

    /**
     * @notice Retrieves comprehensive details about a specific Relic.
     * @param _relicId The ID of the Relic.
     * @return A tuple containing all Relic details.
     */
    function getRelicDetails(uint256 _relicId)
        public view
        returns (
            address owner,
            uint256 aura,
            uint256 creationTimestamp,
            RelicStage currentStage,
            string memory currentMetadataURI,
            uint256[] memory chronicleEntryIds,
            uint256[] memory activeQuestIds
        )
    {
        require(_exists(_relicId), "AuraWeaver: Relic does not exist");
        SentientRelic storage relic = relics[_relicId];
        return (
            ownerOf(_relicId),
            relic.aura,
            relic.creationTimestamp,
            relic.currentStage,
            relic.currentMetadataURI,
            relic.chronicleEntries,
            relic.activeQuests
        );
    }

    /**
     * @notice Returns an array of `entryId`s for all insights associated with a Relic.
     * @param _relicId The ID of the Relic.
     * @return An array of chronicle entry IDs.
     */
    function getRelicChronicleEntries(uint256 _relicId) public view returns (uint256[] memory) {
        require(_exists(_relicId), "AuraWeaver: Relic does not exist");
        return relics[_relicId].chronicleEntries;
    }

    /**
     * @notice Returns an array of `questId`s for quests currently active on a Relic.
     * @param _relicId The ID of the Relic.
     * @return An array of active quest IDs.
     */
    function getRelicActiveQuests(uint256 _relicId) public view returns (uint256[] memory) {
        require(_exists(_relicId), "AuraWeaver: Relic does not exist");
        return relics[_relicId].activeQuests;
    }

    /**
     * @dev Internal function to check if a Relic's Aura surpasses a stage threshold and update its stage and metadata.
     * @param _relicId The ID of the Relic to check.
     */
    function _checkAndAscendRelic(uint256 _relicId) internal {
        if (auraStageThresholds.length == 0) return; // No stages defined

        SentientRelic storage relic = relics[_relicId];
        RelicStage currentStage = relic.currentStage;

        // Iterate through stages from the current stage onwards
        for (uint i = currentStage.toUint() + 1; i < auraStageThresholds.length; i++) {
            if (relic.aura >= auraStageThresholds[i]) {
                relic.currentStage = RelicStage(i);
                relic.currentMetadataURI = relicStageBaseURIs[i];
                _setTokenURI(_relicId, relic.currentMetadataURI); // Update token URI
                emit RelicAscended(_relicId, relic.currentStage, relic.aura, relic.currentMetadataURI);
            } else {
                break; // Aura not enough for the next stage, stop checking
            }
        }
    }

    // --- III. Insight Shard (ERC20) Management ---

    /**
     * @dev Internal function to mint Insight Shards and transfer them to the contributor.
     * Only callable by this contract (as it owns the InsightShards contract).
     * @param _to The address to receive the minted shards.
     * @param _amount The amount of shards to mint.
     */
    function mintShardsForContribution(address _to, uint256 _amount) internal {
        if (_amount > 0) {
            insightShards.mint(_to, _amount);
            emit InsightShardsMinted(_to, _amount);
        }
    }

    /**
     * @dev Internal function to burn Insight Shards from an address, typically for penalties or disputes.
     * Only callable by this contract (as it owns the InsightShards contract).
     * @param _from The address from which to burn shards.
     * @param _amount The amount of shards to burn.
     */
    function burnShardsForPenalty(address _from, uint256 _amount) internal {
        if (_amount > 0) {
            insightShards.burn(_from, _amount);
        }
    }

    /**
     * @notice Returns the total supply of Insight Shards in circulation.
     * @return The total supply of Insight Shards.
     */
    function getTotalShardsInCirculation() public view returns (uint256) {
        return insightShards.totalSupply();
    }

    // --- IV. Knowledge Weaving & Verification ---

    /**
     * @notice Allows users to submit a new piece of knowledge to a specific Relic.
     * The submission will then be sent for AI verification.
     * @param _relicId The ID of the Relic to contribute to.
     * @param _contentHash An IPFS CID or similar hash pointing to the submitted knowledge.
     * @return The ID of the newly created chronicle entry.
     */
    function submitInsightForRelic(uint256 _relicId, string memory _contentHash) public returns (uint256) {
        require(_exists(_relicId), "AuraWeaver: Relic does not exist");
        _chronicleEntryIds.increment();
        uint256 newEntryId = _chronicleEntryIds.current();

        ChronicleEntry storage newEntry = chronicleEntries[newEntryId];
        newEntry.relicId = _relicId;
        newEntry.contributor = msg.sender;
        newEntry.contentHash = _contentHash;
        newEntry.timestamp = block.timestamp;
        newEntry.verificationStatus = VerificationStatus.Pending;

        relics[_relicId].chronicleEntries.push(newEntryId);

        _requestAIVerification(newEntryId, _contentHash); // Request AI verification
        emit InsightSubmitted(newEntryId, _relicId, msg.sender, _contentHash);
        return newEntryId;
    }

    /**
     * @notice Callback function invoked by the AI Oracle to deliver verification results for an insight.
     * @dev This function can ONLY be called by the trusted `aiOracleAddress`.
     * It updates the insight's status, awards Aura to the Relic, and mints Insight Shards to the contributor if valid.
     * @param _entryId The ID of the chronicle entry being verified.
     * @param _aiScore The score assigned by the AI Oracle (e.g., 0-100, representing quality/relevance).
     * @param _isValid True if the AI deemed the insight valid and valuable, false otherwise.
     */
    function receiveAIVerificationResult(uint256 _entryId, uint256 _aiScore, bool _isValid) public onlyAIOracle {
        require(_chronicleEntryIds.current() >= _entryId && _entryId > 0, "AuraWeaver: Chronicle entry does not exist");
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        require(entry.verificationStatus == VerificationStatus.Pending, "AuraWeaver: Insight already verified or disputed");

        entry.aiScore = _aiScore;
        entry.verificationStatus = _isValid ? VerificationStatus.Verified : VerificationStatus.Rejected;

        if (_isValid) {
            // Calculate Aura gain and Shard reward based on AI score
            // Example: 1 Aura for every 10 AI score points (max 10 Aura for 100 AI score)
            uint256 auraGain = _aiScore.div(10);
            uint256 shardReward = auraGain.mul(insightShardMintRate);

            entry.auraGain = auraGain;
            entry.shardReward = shardReward;

            relics[entry.relicId].aura = relics[entry.relicId].aura.add(auraGain);
            mintShardsForContribution(entry.contributor, shardReward);

            _checkAndAscendRelic(entry.relicId); // Check for Relic ascension after Aura gain
            emit AuraGained(entry.relicId, _entryId, auraGain);
        } else {
            // No aura or shards awarded for rejected insights
            entry.auraGain = 0;
            entry.shardReward = 0;
        }

        emit AIVerificationReceived(_entryId, _aiScore, _isValid);
    }

    /**
     * @notice Retrieves the full details of a specific chronicle entry.
     * @param _entryId The ID of the chronicle entry.
     * @return A tuple containing all chronicle entry details.
     */
    function getChronicleEntryDetails(uint256 _entryId)
        public view
        returns (
            uint256 relicId,
            address contributor,
            string memory contentHash,
            uint256 timestamp,
            uint256 auraGain,
            uint256 shardReward,
            VerificationStatus verificationStatus,
            uint256 aiScore,
            address disputer,
            string memory disputeReasonHash
        )
    {
        require(_chronicleEntryIds.current() >= _entryId && _entryId > 0, "AuraWeaver: Chronicle entry does not exist");
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        return (
            entry.relicId,
            entry.contributor,
            entry.contentHash,
            entry.timestamp,
            entry.auraGain,
            entry.shardReward,
            entry.verificationStatus,
            entry.aiScore,
            entry.disputer,
            entry.disputeReasonHash
        );
    }

    /**
     * @notice Initiates a dispute against an AI verification result, staking a small fee.
     * @dev Only users who are not the original contributor can dispute an insight.
     * @param _entryId The ID of the chronicle entry to dispute.
     * @param _reasonHash An IPFS CID or similar hash for the detailed reason for the dispute.
     */
    function disputeInsightVerification(uint256 _entryId, string memory _reasonHash) public {
        require(_chronicleEntryIds.current() >= _entryId && _entryId > 0, "AuraWeaver: Chronicle entry does not exist");
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        require(entry.verificationStatus == VerificationStatus.Verified || entry.verificationStatus == VerificationStatus.Rejected, "AuraWeaver: Insight not verified or already disputed");
        require(entry.contributor != msg.sender, "AuraWeaver: Contributor cannot dispute their own insight.");

        // Transfer dispute fee from the disputer to this contract
        require(insightShards.transferFrom(msg.sender, address(this), disputeFee), "AuraWeaver: Failed to transfer dispute fee");

        entry.verificationStatus = VerificationStatus.Disputed;
        entry.disputer = msg.sender;
        entry.disputeReasonHash = _reasonHash;

        emit InsightDisputed(_entryId, msg.sender, _reasonHash);
    }

    /**
     * @notice Resolves an active dispute, potentially overriding the AI's decision.
     * @dev This function is `onlyOwner` but in a full DAO setup, it would be protected by governance voting.
     * It handles refunding the dispute fee and re-evaluating the insight's impact on Aura and Shards.
     * @param _entryId The ID of the chronicle entry under dispute.
     * @param _overruleAI True to override the AI's previous decision (e.g., mark as valid if AI rejected, or vice versa).
     * @param _newScore The new AI score if `_overruleAI` is true.
     */
    function resolveDispute(uint256 _entryId, bool _overruleAI, uint256 _newScore) public onlyOwner {
        require(_chronicleEntryIds.current() >= _entryId && _entryId > 0, "AuraWeaver: Chronicle entry does not exist");
        ChronicleEntry storage entry = chronicleEntries[_entryId];
        require(entry.verificationStatus == VerificationStatus.Disputed, "AuraWeaver: Entry is not under dispute");

        // Refund dispute fee to the disputer
        insightShards.transfer(entry.disputer, disputeFee);

        // If the DAO/owner decides to overrule the AI's original decision
        if (_overruleAI) {
            // Revert previous effects if any (e.g., if it was originally verified, then disputed)
            if (entry.verificationStatus == VerificationStatus.Verified) {
                // Remove previous aura and shards if it was incorrectly verified
                relics[entry.relicId].aura = relics[entry.relicId].aura.sub(entry.auraGain, "AuraWeaver: Aura underflow");
                burnShardsForPenalty(entry.contributor, entry.shardReward);
            }

            entry.aiScore = _newScore;
            entry.verificationStatus = VerificationStatus.Verified; // Mark as verified by DAO/admin decision

            uint256 auraGain = _newScore.div(10);
            uint256 shardReward = auraGain.mul(insightShardMintRate);

            entry.auraGain = auraGain;
            entry.shardReward = shardReward;

            relics[entry.relicId].aura = relics[entry.relicId].aura.add(auraGain);
            mintShardsForContribution(entry.contributor, shardReward);
            _checkAndAscendRelic(entry.relicId); // Check for Relic ascension again
        } else {
            // Uphold AI's original decision (dispute failed)
            // If it was disputed from Verified, it means the dispute failed, so it's still Verified.
            // If it was disputed from Rejected, it means the dispute failed, so it's still Rejected.
            entry.verificationStatus = (entry.aiScore > 0 && entry.shardReward > 0) ? VerificationStatus.Verified : VerificationStatus.Rejected;
        }

        emit DisputeResolved(_entryId, _overruleAI, _newScore);
    }

    /**
     * @dev Internal function to simulate sending a request to an off-chain AI Oracle.
     * In a real scenario, this would emit an event for an oracle service (e.g., Chainlink) to pick up,
     * which would then call `receiveAIVerificationResult` upon completion.
     * @param _entryId The ID of the chronicle entry requiring verification.
     * @param _contentHash The content hash to be verified.
     */
    function _requestAIVerification(uint256 _entryId, string memory _contentHash) internal {
        // This function would typically emit an event that an off-chain oracle node monitors.
        // For example:
        // emit OracleRequest(_entryId, _contentHash, address(this), "receiveAIVerificationResult(uint256,uint256,bool)");
        // As a simulation, it's a no-op that expects receiveAIVerificationResult to be called by aiOracleAddress.
    }

    // --- V. Aura Quests ---

    /**
     * @notice A Relic owner proposes a quest, staking Insight Shards as bounty.
     * @dev The `_bountyAmount` will be transferred from the proposer to this contract.
     * @param _relicId The ID of the Relic this quest is associated with.
     * @param _title The title of the quest.
     * @param _descriptionHash An IPFS CID or similar hash for the detailed quest description.
     * @param _bountyAmount The amount of Insight Shards offered as bounty.
     * @return The ID of the newly created quest.
     */
    function proposeAuraQuest(uint256 _relicId, string memory _title, string memory _descriptionHash, uint256 _bountyAmount)
        public
        onlyRelicOwner(_relicId)
        returns (uint256)
    {
        require(_bountyAmount > 0, "AuraWeaver: Bounty must be greater than zero");
        require(insightShards.transferFrom(msg.sender, address(this), _bountyAmount), "AuraWeaver: Failed to stake bounty");

        _questIds.increment();
        uint256 newQuestId = _questIds.current();

        AuraQuest storage newQuest = auraQuests[newQuestId];
        newQuest.relicId = _relicId;
        newQuest.proposer = msg.sender;
        newQuest.title = _title;
        newQuest.descriptionHash = _descriptionHash;
        newQuest.bountyAmount = _bountyAmount;
        newQuest.status = QuestStatus.Open;

        relics[_relicId].activeQuests.push(newQuestId); // Add quest to the Relic's active list

        emit AuraQuestProposed(newQuestId, _relicId, msg.sender, _bountyAmount);
        return newQuestId;
    }

    /**
     * @notice Allows a community member to accept to undertake an open quest.
     * @dev The accepted solver cannot be the quest proposer.
     * @param _questId The ID of the quest to accept.
     */
    function acceptAuraQuest(uint256 _questId) public {
        require(_questIds.current() >= _questId && _questId > 0, "AuraWeaver: Quest does not exist");
        AuraQuest storage quest = auraQuests[_questId];
        require(quest.status == QuestStatus.Open, "AuraWeaver: Quest is not open");
        require(quest.proposer != msg.sender, "AuraWeaver: Proposer cannot accept their own quest");

        quest.acceptedSolver = msg.sender;
        quest.acceptedTimestamp = block.timestamp;
        quest.status = QuestStatus.Accepted;

        emit AuraQuestAccepted(_questId, msg.sender);
    }

    /**
     * @notice The accepted solver submits their solution for a quest.
     * @dev Solution must be submitted within the `questCompletionTimeout` period.
     * @param _questId The ID of the quest.
     * @param _submissionHash An IPFS CID or similar hash for the solver's submission.
     */
    function submitQuestSolution(uint256 _questId, string memory _submissionHash) public {
        require(_questIds.current() >= _questId && _questId > 0, "AuraWeaver: Quest does not exist");
        AuraQuest storage quest = auraQuests[_questId];
        require(quest.status == QuestStatus.Accepted, "AuraWeaver: Quest not in accepted state");
        require(quest.acceptedSolver == msg.sender, "AuraWeaver: Only accepted solver can submit solution");
        require(block.timestamp <= quest.acceptedTimestamp.add(questCompletionTimeout), "AuraWeaver: Quest submission timed out");

        quest.submissionHash = _submissionHash;
        quest.status = QuestStatus.SolutionSubmitted;

        emit AuraQuestSolutionSubmitted(_questId, msg.sender, _submissionHash);
    }

    /**
     * @notice The Relic owner (or a DAO) verifies the submitted solution and awards bounty/aura.
     * @dev This function is `onlyRelicOwner` but in a full DAO setup, it might involve governance voting.
     * If valid, the solver receives the bounty and the Relic gains Aura. If invalid, bounty is returned to proposer.
     * @param _questId The ID of the quest.
     * @param _isSolutionValid True if the solution is deemed valid by the verifier.
     * @param _auraGainForRelic The amount of Aura the Relic gains if solution is valid.
     */
    function verifyQuestSolution(uint256 _questId, bool _isSolutionValid, uint256 _auraGainForRelic)
        public
        onlyRelicOwner(auraQuests[_questId].relicId)
    {
        require(_questIds.current() >= _questId && _questId > 0, "AuraWeaver: Quest does not exist");
        AuraQuest storage quest = auraQuests[_questId];
        require(quest.status == QuestStatus.SolutionSubmitted, "AuraWeaver: Solution not submitted yet");
        require(quest.proposer == msg.sender, "AuraWeaver: Only the quest proposer can verify");

        quest.solutionValid = _isSolutionValid;
        quest.completionTimestamp = block.timestamp;
        quest.status = QuestStatus.Verified;

        if (_isSolutionValid) {
            // Reward solver with bounty from the staked amount
            require(insightShards.transfer(quest.acceptedSolver, quest.bountyAmount), "AuraWeaver: Failed to transfer quest bounty to solver");

            // Gain Aura for the Relic
            relics[quest.relicId].aura = relics[quest.relicId].aura.add(_auraGainForRelic);
            _checkAndAscendRelic(quest.relicId); // Check for Relic ascension
            emit AuraGained(quest.relicId, 0, _auraGainForRelic); // 0 indicates Aura from quest, not insight
        } else {
            // Return bounty to proposer if solution is invalid
            require(insightShards.transfer(quest.proposer, quest.bountyAmount), "AuraWeaver: Failed to return bounty to proposer");
        }

        // Remove quest from active list of the associated Relic
        _removeQuestFromRelicActiveList(quest.relicId, _questId);

        emit AuraQuestVerified(_questId, _isSolutionValid, _auraGainForRelic);
    }

    /**
     * @notice Retrieves comprehensive details about a specific quest.
     * @param _questId The ID of the quest.
     * @return A tuple containing all quest details.
     */
    function getQuestDetails(uint256 _questId)
        public view
        returns (
            uint256 relicId,
            address proposer,
            string memory title,
            string memory descriptionHash,
            uint256 bountyAmount,
            QuestStatus status,
            address acceptedSolver,
            string memory submissionHash,
            uint256 acceptedTimestamp,
            uint256 completionTimestamp,
            bool solutionValid
        )
    {
        require(_questIds.current() >= _questId && _questId > 0, "AuraWeaver: Quest does not exist");
        AuraQuest storage quest = auraQuests[_questId];
        return (
            quest.relicId,
            quest.proposer,
            quest.title,
            quest.descriptionHash,
            quest.bountyAmount,
            quest.status,
            quest.acceptedSolver,
            quest.submissionHash,
            quest.acceptedTimestamp,
            quest.completionTimestamp,
            quest.solutionValid
        );
    }

    /**
     * @notice Allows the proposer to cancel an open quest, refunding the bounty.
     * @dev Only the quest proposer can cancel, and only if the quest is still in `Open` status.
     * @param _questId The ID of the quest to cancel.
     */
    function cancelAuraQuest(uint256 _questId) public onlyQuestProposer(_questId) {
        AuraQuest storage quest = auraQuests[_questId];
        require(quest.status == QuestStatus.Open, "AuraWeaver: Quest is not open for cancellation");

        quest.status = QuestStatus.Cancelled;
        require(insightShards.transfer(quest.proposer, quest.bountyAmount), "AuraWeaver: Failed to refund bounty");

        _removeQuestFromRelicActiveList(quest.relicId, _questId);

        emit AuraQuestCancelled(_questId);
    }

    /**
     * @notice Allows the proposer to reclaim bounty if a quest isn't completed within a timeout period.
     * @dev Can only be called if the quest status is `Accepted` and the `questCompletionTimeout` has passed.
     * @param _questId The ID of the quest.
     */
    function reclaimBountyAfterTimeout(uint256 _questId) public onlyQuestProposer(_questId) {
        AuraQuest storage quest = auraQuests[_questId];
        require(quest.status == QuestStatus.Accepted, "AuraWeaver: Quest must be accepted to reclaim bounty by timeout");
        require(block.timestamp > quest.acceptedTimestamp.add(questCompletionTimeout), "AuraWeaver: Quest timeout not reached yet");

        quest.status = QuestStatus.TimedOut;
        require(insightShards.transfer(quest.proposer, quest.bountyAmount), "AuraWeaver: Failed to reclaim bounty");

        _removeQuestFromRelicActiveList(quest.relicId, _questId);

        emit AuraQuestBountyReclaimed(_questId, msg.sender, quest.bountyAmount);
    }

    /**
     * @dev Helper function to remove a quest ID from a relic's active quests list.
     * This is an internal utility to keep the `activeQuests` array tidy.
     * @param _relicId The ID of the Relic.
     * @param _questId The ID of the quest to remove.
     */
    function _removeQuestFromRelicActiveList(uint256 _relicId, uint256 _questId) internal {
        SentientRelic storage relic = relics[_relicId];
        for (uint256 i = 0; i < relic.activeQuests.length; i++) {
            if (relic.activeQuests[i] == _questId) {
                // Replace the found quest with the last element and pop the last element
                relic.activeQuests[i] = relic.activeQuests[relic.activeQuests.length - 1];
                relic.activeQuests.pop();
                break;
            }
        }
    }


    // --- VI. Protocol Governance (Placeholder) ---

    // These functions are simplified placeholders for a full-fledged DAO integration.
    // In a production system, `owner()` would likely be a governance contract with robust voting and timelock mechanisms.
    // This provides the flexibility for future upgrades without requiring a full re-deployment if designed correctly.

    /**
     * @notice Allows a privileged entity (e.g., future DAO) to propose a protocol parameter change.
     * @dev This is a simplified placeholder. A real DAO would involve voting, timelocks, etc.
     * @param _paramKey A bytes32 identifier for the parameter to change (e.g., `keccak256("insightShardMintRate")`).
     * @param _newValue The new value for the parameter, encoded as bytes.
     */
    function initiateParameterUpdateProposal(bytes32 _paramKey, bytes memory _newValue) public onlyOwner {
        // In a real DAO, this would create a proposal, emit an event,
        // and allow voting before execution.
        emit ProtocolParameterUpdated(_paramKey, _newValue);
    }

    /**
     * @notice Executes a proposed parameter update after a successful governance vote.
     * @dev This is a simplified placeholder. A real DAO would involve more checks (e.g., `isProposalApproved`).
     * @param _paramKey A bytes32 identifier for the parameter to change.
     * @param _newValue The new value for the parameter, encoded as bytes.
     */
    function executeParameterUpdate(bytes32 _paramKey, bytes memory _newValue) public onlyOwner {
        // In a real DAO, this would check if the proposal passed voting and timelock.
        // For this example, we directly apply the change.
        if (_paramKey == keccak256("insightShardMintRate")) {
            insightShardMintRate = abi.decode(_newValue, (uint256));
        } else if (_paramKey == keccak256("disputeFee")) {
            disputeFee = abi.decode(_newValue, (uint256));
        } else if (_paramKey == keccak256("questCompletionTimeout")) {
            questCompletionTimeout = abi.decode(_newValue, (uint256));
        }
        // Add more parameters as needed
        // For example:
        // else if (_paramKey == keccak256("someOtherParam")) {
        //     someOtherParam = abi.decode(_newValue, (uint256));
        // }
    }
}
```