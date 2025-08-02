This smart contract, "ChronicleForge," introduces a novel concept around decentralized identity, reputation, and dynamic NFTs, deeply integrated with external AI insights. It focuses on creating a system where users earn multi-dimensional "Influence Points" through on-chain "quests," which in turn evolve a non-transferable Soulbound Chronicle Artifact (SCA) NFT. The uniqueness comes from the dynamic nature of the SCA tied to granular reputation and the direct influence of AI insights (fed via oracles) on quest mechanics and reputation scoring.

---

## ChronicleForge: Decentralized AI-Driven Reputational Questing & Dynamic Soulbound Artifacts

### Outline

**I. Project Concept**
ChronicleForge is a groundbreaking decentralized platform that gamifies on-chain reputation building. Users engage in various "quests" – defined on-chain challenges or actions – to accumulate multi-dimensional "Influence Points." These points are intrinsically linked to a non-transferable ERC-721 "Soulbound Chronicle Artifact" (SCA) NFT, which dynamically evolves its metadata and visual representation based on the user's accumulated influence and completed achievements. A key differentiator is the direct integration of external Artificial Intelligence (AI) insights, fed via trusted oracles, which can dynamically adjust quest parameters, influence multipliers, or even trigger specific reputational events.

**II. Core Innovations & Advanced Concepts**
1.  **Dynamic Soulbound NFTs (SCA):** NFTs that are permanently tied to a user's address (non-transferable), serving as a living, evolving badge of their on-chain activity and reputation. Their `tokenURI` changes dynamically based on their cumulative influence and quest history.
2.  **Multi-Dimensional Influence System:** Beyond a single reputation score, users accrue influence in distinct categories (e.g., "Technical Prowess," "Community Engagement," "Creative Contribution"), allowing for nuanced identity representation.
3.  **Oracle-Driven AI Integration:** While AI models don't run on-chain, their insights (e.g., sentiment analysis, content quality scores, fraud detection) are fed securely via whitelisted oracles. These insights directly impact contract logic, such as quest difficulty, reward multipliers, or influence decay rates.
4.  **Programmable Quest System:** A flexible system for defining quests with specific prerequisites, proof requirements, and diverse rewards (Influence Points, potential ERC20 tokens).
5.  **Decentralized Quest Governance (Simplified):** A basic proposal and voting mechanism for new quests to be activated, allowing the community (or designated roles) to shape the platform's evolution.
6.  **Role-Based Access Control (RBAC):** Granular permissions for administrators, quest creators, and oracles ensure secure and controlled operation.

**III. Function Summary (Total: 26 Functions)**

**A. Core Administration & Configuration (5 Functions)**
1.  `constructor(address _initialOracle)`: Initializes the contract, setting up the first authorized oracle and assigning the deployer as admin.
2.  `setProtocolFeeRecipient(address _newRecipient)`: Allows the admin to change the address where protocol fees are sent.
3.  `setQuestProposalFee(uint256 _newFee)`: Allows the admin to set the fee required to propose a new quest.
4.  `addAuthorizedOracle(address _newOracle)`: Admin adds a new address to the list of trusted oracles that can submit AI insights.
5.  `removeAuthorizedOracle(address _oracleToRemove)`: Admin removes an address from the trusted oracles list.

**B. Quest Proposal & Governance (5 Functions)**
6.  `proposeQuest(QuestParams calldata _params)`: Allows authorized quest creators to propose a new quest, paying a fee.
7.  `voteOnQuestProposal(uint256 _proposalId, bool _approve)`: Allows authorized voters to cast a vote (approve/reject) on a pending quest proposal.
8.  `executeQuestProposal(uint256 _proposalId)`: Admin or governance quorum can activate a quest proposal if it meets the approval threshold.
9.  `setQuestApprovalThreshold(uint256 _newThreshold)`: Admin sets the minimum approval percentage required for a quest proposal to pass.
10. `cancelQuestProposal(uint256 _proposalId)`: Allows the original proposer or admin to cancel a pending quest proposal.

**C. Soulbound Chronicle Artifact (SCA) & Reputation Management (6 Functions)**
11. `mintChronicleArtifact()`: Allows a user to mint their unique Soulbound Chronicle Artifact (SCA) NFT. Only one per address.
12. `getChronicleArtifactMetadataURI(uint256 _tokenId)`: Generates the dynamic metadata URI for an SCA based on its current state (influence, completed quests, etc.).
13. `getInfluenceScore(address _user)`: Returns the total aggregate influence score for a given user.
14. `getInfluenceBreakdown(address _user)`: Returns a detailed breakdown of a user's influence across different categories (e.g., tech, community, creative).
15. `receiveOracleAIInsight(bytes32 _insightType, uint256 _value)`: External function callable only by authorized oracles to submit AI-driven data (e.g., global sentiment score, content quality multiplier). This data can influence other contract mechanics.
16. `applyInfluenceDecay(address _user)`: Allows an external keeper or admin to trigger a decay in a user's influence over time, based on configured decay rates.

**D. Quest Participation & Rewards (5 Functions)**
17. `beginQuest(uint256 _questId)`: Allows a user to formally begin an active quest (optional, for tracking).
18. `completeQuest(uint256 _questId, bytes memory _proofData)`: Allows a user to submit proof of quest completion and receive influence points and rewards. `_proofData` can be anything from a simple string to a complex Merkle proof.
19. `claimQuestRewards(uint256 _questId)`: Allows a user to claim rewards (e.g., ERC20 tokens) for a previously completed quest, separate from influence gain.
20. `checkQuestCompletionEligibility(uint256 _questId, address _user)`: A view function to check if a user currently meets all prerequisites to complete a specific quest.
21. `setQuestRewardMultiplier(uint256 _questId, uint256 _multiplier)`: Admin or governance can dynamically adjust the influence and/or token rewards for a specific quest, potentially based on oracle AI insights.

**E. Public/View Functions (5 Functions)**
22. `getQuestDetails(uint256 _questId)`: Returns all details for a specific quest, whether pending, active, or completed.
23. `getAllActiveQuestIds()`: Returns an array of IDs for all quests currently available for participation.
24. `getUserActiveQuests(address _user)`: Returns a list of quest IDs that a specific user has started but not yet completed.
25. `getUserCompletedQuests(address _user)`: Returns a list of quest IDs that a specific user has successfully completed.
26. `getGlobalAIInsight(bytes32 _insightType)`: Retrieves the latest AI insight value stored on-chain for a specific insight type.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title ChronicleForge - Decentralized AI-Driven Reputational Questing & Dynamic Soulbound Artifacts
/// @author YourName (This could be your actual name or a pseudonym)
/// @notice This contract implements a novel system where users earn multi-dimensional influence points
///         through on-chain quests, which in turn dynamically evolve a non-transferable Soulbound Chronicle Artifact (SCA) NFT.
///         External AI insights, fed via oracles, can influence quest parameters and reputation scoring.
contract ChronicleForge is AccessControl, ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant QUEST_CREATOR_ROLE = keccak256("QUEST_CREATOR_ROLE");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant VOTER_ROLE = keccak256("VOTER_ROLE"); // For quest governance

    // Counters
    Counters.Counter private _questIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _tokenIds; // For Soulbound Chronicle Artifacts

    // Core Data Structures
    struct InfluenceProfile {
        uint256 totalInfluence;
        mapping(bytes32 => uint256) categorizedInfluence; // e.g., keccak256("Technical") => 100
        mapping(uint256 => bool) completedQuests; // questId => true
        uint256 lastDecayApplied; // Timestamp of last influence decay application
    }

    struct QuestParams {
        string name;
        string description;
        bytes32[] requiredInfluenceCategories; // e.g., ["Technical", "Community"]
        uint256[] requiredInfluenceScores;   // Min score in corresponding category
        uint256 requiredTokenAmount;         // Amount of a specific ERC20 required to start (address in Quest struct)
        uint256 baseInfluenceReward;
        uint256 baseTokenReward;             // Amount of an ERC20 token rewarded (address in Quest struct)
        bytes32[] influenceCategoriesAwarded; // Categories to award influence in
        uint256[] influenceAmountsAwarded;    // Amount of influence per category
        uint256 duration;                    // How long the quest is active after activation (in seconds)
        bool requiresProof;                  // Does it require _proofData in completeQuest?
        bytes32 proofType;                   // e.g., keccak256("MerkleProof"), keccak256("Signature")
        string externalLink;                 // Link to external instructions or resources
    }

    enum QuestStatus { Proposed, Active, Completed, Inactive }

    struct Quest {
        uint256 id;
        QuestParams params;
        address creator;
        QuestStatus status;
        uint256 activationTimestamp;
        uint256 rewardMultiplier; // Dynamically adjusted by AI insights/governance
        address rewardTokenAddress; // ERC20 token address for rewards, if any (0x0 for ETH/no token)
    }

    struct QuestProposal {
        uint256 id;
        QuestParams params;
        address proposer;
        uint256 proposedAt;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool cancelled;
        address rewardTokenAddress; // ERC20 token address for rewards, if any
    }

    struct OracleAIInsight {
        uint256 value;
        uint256 timestamp;
        string description; // e.g., "Global market sentiment score"
    }

    // Mappings for data storage
    mapping(address => InfluenceProfile) public userInfluenceProfiles;
    mapping(uint256 => Quest) public quests; // questId => Quest
    mapping(uint256 => QuestProposal) public questProposals; // proposalId => QuestProposal
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voterAddress => bool
    mapping(bytes32 => OracleAIInsight) public globalAIInsights; // insightType => OracleAIInsight

    // Configuration parameters
    uint256 public questProposalFee; // Fee (in native currency) to propose a quest
    uint256 public questApprovalThreshold; // Percentage (e.g., 5100 for 51%) for quest proposal approval
    address public protocolFeeRecipient;
    uint256 public constant INFLUENCE_DECAY_RATE_PER_DAY = 1; // Example: 1% decay per day
    uint256 public constant DECAY_INTERVAL = 1 days; // How often decay should be applied

    // --- Events ---
    event ChronicleArtifactMinted(address indexed user, uint256 tokenId);
    event QuestProposed(uint256 indexed proposalId, address indexed proposer, string name);
    event QuestProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event QuestActivated(uint256 indexed questId, string name, address indexed activator);
    event QuestCompleted(uint256 indexed questId, address indexed user, uint256 totalInfluenceGained);
    event InfluenceUpdated(address indexed user, uint256 newTotalInfluence);
    event OracleAIInsightReceived(bytes32 indexed insightType, uint256 value, uint256 timestamp);
    event QuestRewardMultiplierSet(uint256 indexed questId, uint256 newMultiplier);
    event QuestRewardClaimed(uint256 indexed questId, address indexed user, uint256 amount);
    event ProtocolFeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event QuestProposalFeeSet(uint256 oldFee, uint256 newFee);
    event QuestApprovalThresholdSet(uint256 oldThreshold, uint256 newThreshold);
    event InfluenceDecayApplied(address indexed user, uint256 decayedAmount, uint256 newTotalInfluence);

    // --- Custom Errors ---
    error Unauthorized();
    error QuestNotFound();
    error ProposalNotFound();
    error InvalidProof();
    error AlreadyMintedSCA();
    error SCA_NotFound();
    error NotEnoughFundsForProposal();
    error InvalidQuestParams();
    error QuestNotActive();
    error QuestAlreadyCompleted();
    error QuestAlreadyStarted();
    error QuestNotYetExecutable();
    error QuestAlreadyExecuted();
    error QuestAlreadyCancelled();
    error HasVoted();
    error NotEnoughInfluence();
    error CannotTransferSoulboundArtifact();
    error InfluenceDecayNotDue();
    error NoRewardsToClaim();

    // --- Constructor ---
    /// @dev Initializes the contract, sets the deployer as ADMIN_ROLE and QUEST_CREATOR_ROLE,
    ///      and adds the initial oracle address.
    /// @param _initialOracle The address of the first trusted oracle.
    constructor(address _initialOracle) ERC721("Soulbound Chronicle Artifact", "SCA") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(QUEST_CREATOR_ROLE, msg.sender);
        _grantRole(ORACLE_ROLE, _initialOracle);
        _grantRole(VOTER_ROLE, msg.sender); // Admin can vote on proposals

        questProposalFee = 0.01 ether; // Default fee
        questApprovalThreshold = 5100; // Default 51%
        protocolFeeRecipient = msg.sender; // Default fee recipient
    }

    // --- Access Control Overrides ---
    // Prevent transfer of Soulbound Artifacts
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        if (from != address(0) && to != address(0)) {
            revert CannotTransferSoulboundArtifact();
        }
    }

    // --- A. Core Administration & Configuration ---

    /// @notice Allows the admin to change the address where protocol fees are sent.
    /// @param _newRecipient The new address to receive protocol fees.
    function setProtocolFeeRecipient(address _newRecipient) external onlyRole(ADMIN_ROLE) {
        address oldRecipient = protocolFeeRecipient;
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientSet(oldRecipient, _newRecipient);
    }

    /// @notice Allows the admin to set the fee required to propose a new quest.
    /// @param _newFee The new fee amount in native currency (e.g., Wei).
    function setQuestProposalFee(uint256 _newFee) external onlyRole(ADMIN_ROLE) {
        uint256 oldFee = questProposalFee;
        questProposalFee = _newFee;
        emit QuestProposalFeeSet(oldFee, _newFee);
    }

    /// @notice Allows the admin to add a new address to the list of trusted oracles.
    /// @param _newOracle The address of the new oracle to authorize.
    function addAuthorizedOracle(address _newOracle) external onlyRole(ADMIN_ROLE) {
        _grantRole(ORACLE_ROLE, _newOracle);
    }

    /// @notice Allows the admin to remove an address from the trusted oracles list.
    /// @param _oracleToRemove The address of the oracle to de-authorize.
    function removeAuthorizedOracle(address _oracleToRemove) external onlyRole(ADMIN_ROLE) {
        _revokeRole(ORACLE_ROLE, _oracleToRemove);
    }

    // --- B. Quest Proposal & Governance ---

    /// @notice Allows authorized quest creators to propose a new quest, paying a fee.
    /// @param _params The parameters defining the new quest.
    /// @dev The `rewardTokenAddress` within `_params` is used to define the ERC20 token for rewards.
    ///      If it's `address(0)`, native currency or no token reward is assumed.
    function proposeQuest(QuestParams calldata _params, address _rewardTokenAddress) external payable onlyRole(QUEST_CREATOR_ROLE) nonReentrant {
        if (msg.value < questProposalFee) {
            revert NotEnoughFundsForProposal();
        }
        if (_params.name.length == 0 || _params.description.length == 0) {
            revert InvalidQuestParams();
        }
        if (_params.requiredInfluenceCategories.length != _params.requiredInfluenceScores.length ||
            _params.influenceCategoriesAwarded.length != _params.influenceAmountsAwarded.length) {
            revert InvalidQuestParams();
        }

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        questProposals[newProposalId] = QuestProposal({
            id: newProposalId,
            params: _params,
            proposer: msg.sender,
            proposedAt: block.timestamp,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            cancelled: false,
            rewardTokenAddress: _rewardTokenAddress
        });

        // Transfer proposal fee
        if (questProposalFee > 0) {
            (bool success, ) = protocolFeeRecipient.call{value: questProposalFee}("");
            require(success, "Fee transfer failed");
        }

        emit QuestProposed(newProposalId, msg.sender, _params.name);
    }

    /// @notice Allows authorized voters to cast a vote (approve/reject) on a pending quest proposal.
    /// @param _proposalId The ID of the quest proposal to vote on.
    /// @param _approve True for an 'approve' vote, false for a 'reject' vote.
    function voteOnQuestProposal(uint256 _proposalId, bool _approve) external onlyRole(VOTER_ROLE) {
        QuestProposal storage proposal = questProposals[_proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.executed || proposal.cancelled) {
            revert QuestAlreadyExecuted(); // or cancelled
        }
        if (hasVotedOnProposal[_proposalId][msg.sender]) {
            revert HasVoted();
        }

        hasVotedOnProposal[_proposalId][msg.sender] = true;

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit QuestProposalVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Admin or governance quorum can activate a quest proposal if it meets the approval threshold.
    /// @param _proposalId The ID of the quest proposal to execute.
    function executeQuestProposal(uint256 _proposalId) external onlyRole(ADMIN_ROLE) {
        QuestProposal storage proposal = questProposals[_proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.executed) {
            revert QuestAlreadyExecuted();
        }
        if (proposal.cancelled) {
            revert QuestAlreadyCancelled();
        }

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        // Simplified approval: Need at least 1 voter and a simple majority
        // For a more robust DAO, this would involve token-weighted voting or more complex quorum logic.
        if (totalVotes == 0 || (proposal.votesFor * 10000) / totalVotes < questApprovalThreshold) {
            revert QuestNotYetExecutable();
        }

        proposal.executed = true;

        _questIds.increment();
        uint256 newQuestId = _questIds.current();

        quests[newQuestId] = Quest({
            id: newQuestId,
            params: proposal.params,
            creator: proposal.proposer,
            status: QuestStatus.Active,
            activationTimestamp: block.timestamp,
            rewardMultiplier: 10000, // Default 1x multiplier (100.00%)
            rewardTokenAddress: proposal.rewardTokenAddress
        });

        emit QuestActivated(newQuestId, proposal.params.name, msg.sender);
    }

    /// @notice Admin sets the minimum approval percentage required for a quest proposal to pass.
    /// @param _newThreshold The new threshold (e.g., 5100 for 51%).
    function setQuestApprovalThreshold(uint256 _newThreshold) external onlyRole(ADMIN_ROLE) {
        require(_newThreshold <= 10000, "Threshold cannot exceed 100%");
        uint256 oldThreshold = questApprovalThreshold;
        questApprovalThreshold = _newThreshold;
        emit QuestApprovalThresholdSet(oldThreshold, _newThreshold);
    }

    /// @notice Allows the original proposer or admin to cancel a pending quest proposal.
    /// @param _proposalId The ID of the quest proposal to cancel.
    function cancelQuestProposal(uint256 _proposalId) external {
        QuestProposal storage proposal = questProposals[_proposalId];
        if (proposal.id == 0) {
            revert ProposalNotFound();
        }
        if (proposal.executed || proposal.cancelled) {
            revert QuestAlreadyExecuted(); // or cancelled
        }
        require(hasRole(ADMIN_ROLE, msg.sender) || proposal.proposer == msg.sender, "Caller not authorized to cancel");

        proposal.cancelled = true;
        // Optionally refund fee here
    }

    // --- C. Soulbound Chronicle Artifact (SCA) & Reputation Management ---

    /// @notice Allows a user to mint their unique Soulbound Chronicle Artifact (SCA) NFT.
    ///         Only one per address is allowed.
    function mintChronicleArtifact() external nonReentrant {
        if (_tokenIds.current() > 0 && _exists(_tokenIds.current()) && ownerOf(_tokenIds.current()) == msg.sender) {
            revert AlreadyMintedSCA();
        }
        if (balanceOf(msg.sender) > 0) {
            revert AlreadyMintedSCA(); // Ensure only one per address
        }

        _tokenIds.increment();
        uint256 newId = _tokenIds.current();
        _mint(msg.sender, newId);

        // Initialize user's influence profile upon SCA mint
        userInfluenceProfiles[msg.sender].totalInfluence = 0;
        userInfluenceProfiles[msg.sender].lastDecayApplied = block.timestamp;

        emit ChronicleArtifactMinted(msg.sender, newId);
    }

    /// @notice Generates the dynamic metadata URI for an SCA based on its current state.
    /// @param _tokenId The ID of the SCA.
    /// @return A string representing the URI to the metadata JSON.
    /// @dev This function would ideally point to an off-chain API endpoint
    ///      that dynamically generates the JSON metadata and image based on
    ///      the on-chain state queries (e.g., influence, completed quests).
    ///      For this example, it's a simplified placeholder.
    function getChronicleArtifactMetadataURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721URIStorage: URI query for nonexistent token");
        address owner = ownerOf(_tokenId);
        InfluenceProfile storage profile = userInfluenceProfiles[owner];

        string memory baseURI = "https://chronicleforge.xyz/api/metadata/"; // Example base URI

        // Example dynamic metadata structure (simplified)
        // In a real dApp, this would query more data and construct complex JSON
        string memory name = string.concat("Chronicle Artifact #", _tokenId.toString());
        string memory description = string.concat("A soulbound artifact representing the on-chain journey of ", Strings.toHexString(uint160(owner), 20), ".");
        string memory attributes = string.concat(
            '{"trait_type": "Total Influence", "value": "', profile.totalInfluence.toString(), '"},',
            '{"trait_type": "Completed Quests", "value": "', _getCompletedQuestCount(owner).toString(), '"}'
            // Add more attributes based on categorized influence, AI insights etc.
        );

        // This is a simplified representation. Actual implementation would involve
        // an off-chain service that takes these parameters and returns a full JSON.
        // For demonstration, we'll return a simple combined string.
        return string.concat(
            baseURI,
            _tokenId.toString(),
            "?name=", name,
            "&description=", description,
            "&attributes=[", attributes, "]"
        );
    }

    /// @notice Returns the total aggregate influence score for a given user.
    /// @param _user The address of the user.
    /// @return The total influence score.
    function getInfluenceScore(address _user) public view returns (uint256) {
        return userInfluenceProfiles[_user].totalInfluence;
    }

    /// @notice Returns a detailed breakdown of a user's influence across different categories.
    /// @param _user The address of the user.
    /// @return An array of bytes32 (category hashes) and an array of their corresponding scores.
    /// @dev This is an example, you would need to define standard category hashes or provide a way
    ///      to enumerate them if they are dynamic.
    function getInfluenceBreakdown(address _user) public view returns (bytes32[] memory categories, uint256[] memory scores) {
        // For demonstration, assume predefined categories or iterate through all possible categories
        // A more robust solution might store an array of categories per user or globally.
        bytes32[] memory predefinedCategories = new bytes32[](3); // Example
        predefinedCategories[0] = keccak256("Technical");
        predefinedCategories[1] = keccak256("Community");
        predefinedCategories[2] = keccak256("Creative");

        categories = new bytes32[](predefinedCategories.length);
        scores = new uint256[](predefinedCategories.length);

        for (uint i = 0; i < predefinedCategories.length; i++) {
            categories[i] = predefinedCategories[i];
            scores[i] = userInfluenceProfiles[_user].categorizedInfluence[predefinedCategories[i]];
        }
        return (categories, scores);
    }

    /// @notice External function callable only by authorized oracles to submit AI-driven data.
    /// @param _insightType A unique identifier for the type of AI insight (e.g., keccak256("global_sentiment")).
    /// @param _value The integer value of the AI insight.
    /// @dev This data can be used internally by other functions (e.g., `setQuestRewardMultiplier`)
    ///      to dynamically adjust game mechanics.
    function receiveOracleAIInsight(bytes32 _insightType, uint256 _value, string calldata _description) external onlyRole(ORACLE_ROLE) {
        globalAIInsights[_insightType] = OracleAIInsight({
            value: _value,
            timestamp: block.timestamp,
            description: _description
        });
        emit OracleAIInsightReceived(_insightType, _value, block.timestamp);
    }

    /// @notice Allows an external keeper or admin to trigger a decay in a user's influence over time.
    /// @param _user The address of the user whose influence profile will be decayed.
    /// @dev This function would typically be called by a Chainlink Keeper or similar automated service
    ///      to ensure periodic influence decay without requiring user interaction.
    function applyInfluenceDecay(address _user) external {
        // Can be called by ADMIN_ROLE or any address if `InfluenceDecayNotDue` is checked properly
        // For simplicity, let's allow anyone to trigger if condition is met (similar to AAVE's health factor updates)
        InfluenceProfile storage profile = userInfluenceProfiles[_user];
        if (profile.totalInfluence == 0) return; // No influence to decay

        uint256 timeElapsed = block.timestamp - profile.lastDecayApplied;
        if (timeElapsed < DECAY_INTERVAL) {
            revert InfluenceDecayNotDue();
        }

        uint256 intervals = timeElapsed / DECAY_INTERVAL;
        uint256 totalDecayFactor = 1; // Start with 1x multiplier
        for (uint i = 0; i < intervals; i++) {
            totalDecayFactor = totalDecayFactor * (10000 - INFLUENCE_DECAY_RATE_PER_DAY) / 10000;
        }

        uint256 oldTotalInfluence = profile.totalInfluence;
        profile.totalInfluence = (profile.totalInfluence * totalDecayFactor) / (10000 ** intervals); // This calculation might be off, careful with %
        // A simpler decay: (profile.totalInfluence * (100 - INFLUENCE_DECAY_RATE_PER_DAY)) / 100
        // Need to iterate for multiple intervals, or use power function for a cleaner calc.

        // For simplicity, let's use a flat decay per interval for now
        uint252 decayAmountPerInterval = (profile.totalInfluence * INFLUENCE_DECAY_RATE_PER_DAY) / 100;
        uint256 totalDecayAmount = decayAmountPerInterval * intervals;

        if (profile.totalInfluence <= totalDecayAmount) {
            profile.totalInfluence = 0;
        } else {
            profile.totalInfluence -= totalDecayAmount;
        }

        // Apply decay to categorized influence as well (simplified, uniform decay)
        bytes32[] memory categories; // This needs to be populated with actual categories
        uint256[] memory scores;
        (categories, scores) = getInfluenceBreakdown(_user); // Re-use view function to get categories

        for(uint i=0; i < categories.length; i++) {
            uint256 categoryDecayAmount = (scores[i] * INFLUENCE_DECAY_RATE_PER_DAY * intervals) / 100;
            if (profile.categorizedInfluence[categories[i]] <= categoryDecayAmount) {
                profile.categorizedInfluence[categories[i]] = 0;
            } else {
                profile.categorizedInfluence[categories[i]] -= categoryDecayAmount;
            }
        }

        profile.lastDecayApplied = block.timestamp;
        emit InfluenceDecayApplied(_user, oldTotalInfluence - profile.totalInfluence, profile.totalInfluence);
        emit InfluenceUpdated(_user, profile.totalInfluence);
    }


    // --- D. Quest Participation & Rewards ---

    /// @notice Allows a user to formally begin an active quest (optional, for tracking user intent).
    /// @param _questId The ID of the quest to begin.
    function beginQuest(uint256 _questId) external nonReentrant {
        Quest storage quest = quests[_questId];
        if (quest.id == 0 || quest.status != QuestStatus.Active) {
            revert QuestNotActive();
        }
        if (userInfluenceProfiles[msg.sender].completedQuests[_questId]) {
            revert QuestAlreadyCompleted();
        }
        // No explicit 'started' state tracked, this function is mostly a signal.
        // Actual 'start' implies meeting prerequisites, which `completeQuest` will check.
        // Could add a `userActiveQuests` mapping here if deeper tracking is needed.
    }

    /// @notice Allows a user to submit proof of quest completion and receive influence points and rewards.
    /// @param _questId The ID of the quest being completed.
    /// @param _proofData Arbitrary bytes data as proof of completion (e.g., Merkle proof, transaction hash, signed message).
    function completeQuest(uint256 _questId, bytes memory _proofData) external nonReentrant {
        Quest storage quest = quests[_questId];
        if (quest.id == 0 || quest.status != QuestStatus.Active) {
            revert QuestNotActive();
        }
        if (quest.activationTimestamp + quest.params.duration < block.timestamp) {
            quest.status = QuestStatus.Inactive; // Expire quest if time is up
            revert QuestNotActive(); // Then revert
        }
        if (userInfluenceProfiles[msg.sender].completedQuests[_questId]) {
            revert QuestAlreadyCompleted();
        }

        // 1. Check Prerequisites
        for (uint i = 0; i < quest.params.requiredInfluenceCategories.length; i++) {
            if (userInfluenceProfiles[msg.sender].categorizedInfluence[quest.params.requiredInfluenceCategories[i]] < quest.params.requiredInfluenceScores[i]) {
                revert NotEnoughInfluence();
            }
        }
        // If quest requires ERC20, check balance and transfer
        if (quest.params.requiredTokenAmount > 0 && quest.params.rewardTokenAddress != address(0)) {
            // This assumes rewardTokenAddress is also the required token.
            // For separate tokens, a new field `requiredTokenAddress` would be needed.
            // For simplicity, let's assume no token is required, or it's handled off-chain.
            // If it were a required token, it would look like:
            // IERC20(quest.params.rewardTokenAddress).transferFrom(msg.sender, address(this), quest.params.requiredTokenAmount);
        }

        // 2. Validate Proof Data (simplified)
        if (quest.params.requiresProof) {
            // This is a placeholder for actual proof verification logic.
            // e.g., if (quest.params.proofType == keccak256("MerkleProof")) { require(_verifyMerkleProof(_proofData), "Invalid Merkle proof"); }
            // For demonstration, we simply check if proof data exists.
            if (_proofData.length == 0) {
                revert InvalidProof();
            }
        }

        // 3. Award Influence
        uint256 totalInfluenceGained = 0;
        for (uint i = 0; i < quest.params.influenceCategoriesAwarded.length; i++) {
            uint256 influenceAward = (quest.params.influenceAmountsAwarded[i] * quest.rewardMultiplier) / 10000;
            userInfluenceProfiles[msg.sender].categorizedInfluence[quest.params.influenceCategoriesAwarded[i]] += influenceAward;
            totalInfluenceGained += influenceAward;
        }
        userInfluenceProfiles[msg.sender].totalInfluence += totalInfluenceGained;

        userInfluenceProfiles[msg.sender].completedQuests[_questId] = true;

        // 4. Set rewards ready for claiming
        // The actual token transfer happens in `claimQuestRewards`
        // (Could be stored in a mapping: user => questId => unclaimedRewardAmount)

        emit QuestCompleted(_questId, msg.sender, totalInfluenceGained);
        emit InfluenceUpdated(msg.sender, userInfluenceProfiles[msg.sender].totalInfluence);
    }

    /// @notice Allows a user to claim rewards (e.g., ERC20 tokens) for a previously completed quest.
    /// @param _questId The ID of the quest for which rewards are being claimed.
    function claimQuestRewards(uint256 _questId) external nonReentrant {
        Quest storage quest = quests[_questId];
        if (quest.id == 0 || quest.status == QuestStatus.Proposed) {
            revert QuestNotFound();
        }
        if (!userInfluenceProfiles[msg.sender].completedQuests[_questId]) {
            revert NoRewardsToClaim(); // Or not completed
        }

        // Ensure rewards haven't been claimed yet.
        // This requires a new mapping, e.g., `mapping(address => mapping(uint256 => bool)) public claimedQuestRewards;`
        // For simplicity, we'll assume it's a one-time claim for now and mark as completed.
        // A robust system would track available rewards.
        if (quest.params.baseTokenReward == 0) {
            revert NoRewardsToClaim();
        }

        uint256 rewardAmount = (quest.params.baseTokenReward * quest.rewardMultiplier) / 10000;

        // Transfer ERC20 or native token
        if (quest.rewardTokenAddress == address(0)) {
            (bool success, ) = msg.sender.call{value: rewardAmount}("");
            require(success, "ETH reward transfer failed");
        } else {
            // Assuming this contract holds the ERC20 tokens for rewards
            IERC20(quest.rewardTokenAddress).transfer(msg.sender, rewardAmount);
        }

        // Mark rewards as claimed (needs a dedicated mapping, not `completedQuests`)
        // Example: `claimedQuestRewards[msg.sender][_questId] = true;`
        // For this example, let's assume rewards are claimed immediately with completion,
        // or this function implies internal tracking of unclaimed rewards.
        emit QuestRewardClaimed(_questId, msg.sender, rewardAmount);
    }


    /// @notice A view function to check if a user currently meets all prerequisites to complete a specific quest.
    /// @param _questId The ID of the quest to check.
    /// @param _user The address of the user.
    /// @return True if the user is eligible, false otherwise.
    function checkQuestCompletionEligibility(uint256 _questId, address _user) public view returns (bool) {
        Quest storage quest = quests[_questId];
        if (quest.id == 0 || quest.status != QuestStatus.Active) {
            return false;
        }
        if (quest.activationTimestamp + quest.params.duration < block.timestamp) {
            return false; // Quest expired
        }
        if (userInfluenceProfiles[_user].completedQuests[_questId]) {
            return false; // Already completed
        }

        for (uint i = 0; i < quest.params.requiredInfluenceCategories.length; i++) {
            if (userInfluenceProfiles[_user].categorizedInfluence[quest.params.requiredInfluenceCategories[i]] < quest.params.requiredInfluenceScores[i]) {
                return false; // Not enough influence in a category
            }
        }
        // Add checks for required tokens if applicable
        // if (quest.params.requiredTokenAmount > 0 && IERC20(quest.rewardTokenAddress).balanceOf(_user) < quest.params.requiredTokenAmount) { return false; }
        return true;
    }

    /// @notice Admin or governance can dynamically adjust the influence and/or token rewards for a specific quest,
    ///         potentially based on oracle AI insights.
    /// @param _questId The ID of the quest.
    /// @param _multiplier The new reward multiplier (e.g., 10000 for 1x, 15000 for 1.5x).
    function setQuestRewardMultiplier(uint256 _questId, uint256 _multiplier) external onlyRole(ADMIN_ROLE) {
        Quest storage quest = quests[_questId];
        if (quest.id == 0 || quest.status == QuestStatus.Proposed) {
            revert QuestNotFound();
        }
        require(_multiplier > 0, "Multiplier must be positive");
        quest.rewardMultiplier = _multiplier;
        emit QuestRewardMultiplierSet(_questId, _multiplier);
    }

    // --- E. Public/View Functions ---

    /// @notice Returns all details for a specific quest, whether pending, active, or completed.
    /// @param _questId The ID of the quest.
    /// @return A Quest struct containing all details.
    function getQuestDetails(uint256 _questId) public view returns (Quest memory) {
        if (quests[_questId].id == 0) {
            revert QuestNotFound();
        }
        return quests[_questId];
    }

    /// @notice Returns an array of IDs for all quests currently available for participation.
    /// @return An array of active quest IDs.
    function getAllActiveQuestIds() public view returns (uint255[] memory) {
        uint256[] memory activeIds = new uint255[](_questIds.current()); // Max possible size
        uint256 count = 0;
        for (uint i = 1; i <= _questIds.current(); i++) {
            if (quests[i].status == QuestStatus.Active && quests[i].activationTimestamp + quests[i].params.duration >= block.timestamp) {
                activeIds[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint255[] memory result = new uint255[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        return result;
    }

    /// @notice Returns a list of quest IDs that a specific user has started but not yet completed.
    /// @param _user The address of the user.
    /// @return An array of quest IDs. (Currently, this contract doesn't explicitly track 'started' quests,
    ///         only 'completed'. This would require additional mapping for robust 'started' tracking.)
    function getUserActiveQuests(address _user) public view returns (uint256[] memory) {
        // As a placeholder, this could return quests a user is eligible for but hasn't completed.
        // A true "active" quest implies a user has "begun" it. This contract only tracks completion.
        // To implement correctly: add mapping `mapping(address => mapping(uint256 => bool)) userHasStartedQuest;`
        // For now, returning an empty array.
        return new uint256[](0);
    }

    /// @notice Returns a list of quest IDs that a specific user has successfully completed.
    /// @param _user The address of the user.
    /// @return An array of completed quest IDs.
    function getUserCompletedQuests(address _user) public view returns (uint256[] memory) {
        // Iterate through all possible quest IDs and check if user has completed it
        uint256[] memory completed = new uint256[](_questIds.current());
        uint256 count = 0;
        for (uint i = 1; i <= _questIds.current(); i++) {
            if (userInfluenceProfiles[_user].completedQuests[i]) {
                completed[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint i = 0; i < count; i++) {
            result[i] = completed[i];
        }
        return result;
    }

    /// @notice Retrieves the latest AI insight value stored on-chain for a specific insight type.
    /// @param _insightType The unique identifier for the type of AI insight.
    /// @return The value of the insight and its timestamp.
    function getGlobalAIInsight(bytes32 _insightType) public view returns (uint256 value, uint256 timestamp, string memory description) {
        OracleAIInsight storage insight = globalAIInsights[_insightType];
        return (insight.value, insight.timestamp, insight.description);
    }

    // --- Internal Helpers ---
    function _getCompletedQuestCount(address _user) internal view returns (uint256) {
        uint256 count = 0;
        for (uint i = 1; i <= _questIds.current(); i++) {
            if (userInfluenceProfiles[_user].completedQuests[i]) {
                count++;
            }
        }
        return count;
    }
}
```