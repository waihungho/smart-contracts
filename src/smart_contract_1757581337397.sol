Here's a smart contract in Solidity called `AptitudeGuild`. It's designed around the concept of a decentralized, gamified on-chain reputation and skill-tree system, using dynamic Soulbound Tokens (SBTs), modular quest verification, and an internal gas subsidization model.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Interface for external quest verifiers
interface IQuestVerifier {
    /// @notice Verifies if a user has completed a specific quest based on provided data.
    /// @param user The address of the user attempting the quest.
    /// @param questId The ID of the quest being attempted.
    /// @param verificationData Structured data required for verification (e.g., proposal ID, LP pair).
    /// @return True if the quest action is verified, false otherwise.
    function verify(address user, uint256 questId, bytes calldata verificationData) external view returns (bool);
}

/// @title AptitudeGuild Smart Contract
/// @author [Your Name/Alias]
/// @notice This contract implements a decentralized "Aptitude Guild" system.
/// Users mint unique, non-transferable "Aptitude Tokens" (ATs) which represent their on-chain profile and skills.
/// By completing "Quests" (on-chain tasks), users earn "Aptitude Points" (AP), level up their ATs, and unlock "Talents".
/// The system features modular quest verification, a dynamic metadata system for ATs, gas subsidization for certain quests,
/// and a basic governance framework for managing quests and contract parameters.
///
/// @dev This contract relies on external verifier contracts for complex quest types to maintain modularity.
/// The Aptitude Tokens are designed as Soulbound Tokens (SBTs) by preventing transfers post-mint.

/// @dev Outline:
/// I. Core Components:
///    - AptitudeToken (AT): A Soulbound ERC721-like NFT representing a user's on-chain profile.
///    - Aptitude Points (AP): Earned by completing quests, used for leveling up ATs.
///    - Talents: Unlockable skills/badges associated with AT levels, providing utility or recognition.
///    - Quests: On-chain tasks verified by the guild, awarding AP and potentially other benefits.
/// II. Key Functionalities:
///    - Aptitude Token Management: Minting, delegation of reputation, dynamic metadata.
///    - Quest Lifecycle: Creation, verification (internal or via external verifiers), completion, reward distribution.
///    - Talent Tree Management: Definition of talents, unlocking by users, and optional reset.
///    - Gas Subsidization: Mechanism to rebate gas costs for specific quests in the form of AP.
///    - Decentralized Governance: For creating/updating quests, defining talents, and adjusting contract parameters.

/// @dev Function Summary (30 functions):

/// A. Aptitude Token (AT) Management:
/// 1. `mintAptitudeToken()`: Mints a new unique, non-transferable Aptitude Token (AT) for the caller.
/// 2. `delegateAptitude(uint256 tokenId, address delegatee)`: Delegates the AT's 'reputation' to another address for specific actions.
/// 3. `revokeAptitudeDelegation(uint256 tokenId)`: Revokes an existing aptitude delegation.
/// 4. `getAptitudeLevel(uint256 tokenId)`: Retrieves the current level of a specific AT.
/// 5. `getAptitudePoints(uint256 tokenId)`: Retrieves the total Aptitude Points (AP) accumulated by an AT.
/// 6. `getUnlockedTalents(uint256 tokenId)`: Lists all talents unlocked by a given AT.
/// 7. `tokenURI(uint256 tokenId)`: Returns the dynamic metadata URI for an Aptitude Token.

/// B. Quest Management & Completion:
/// 8. `createQuest(...)`: Admin/DAO creates a new quest with specific parameters.
/// 9. `updateQuest(...)`: Admin/DAO updates an existing quest's parameters.
/// 10. `getQuestDetails(uint256 questId)`: Retrieves comprehensive details about a specific quest.
/// 11. `getAllActiveQuestIds()`: Returns an array of all currently active quest IDs.
/// 12. `completeQuest(uint256 questId, uint256 tokenId, bytes memory verificationData)`: User attempts to complete a quest; contract verifies the action and awards AP.
/// 13. `resetQuestCooldown(uint256 questId, uint256 tokenId)`: Admin/DAO can reset a specific quest's cooldown for a user.

/// C. Talent Tree Management:
/// 14. `createTalent(...)`: Admin/DAO defines a new talent that can be unlocked by ATs.
/// 15. `unlockTalent(uint256 tokenId, uint256 talentId)`: Allows an AT holder to unlock an available talent after reaching the required level.
/// 16. `resetTalentTree(uint256 tokenId)`: Allows an AT holder to reset their unlocked talents (with potential cost/cooldown).
/// 17. `getTalentDetails(uint256 talentId)`: Retrieves details about a specific talent.

/// D. Gas Subsidization:
/// 18. `depositGasSubsidizationFunds()`: Allows anyone to deposit ETH into the contract to subsidize gas for sponsored quests.
/// 19. `withdrawGasSubsidizationFunds(address recipient, uint256 amount)`: Admin/DAO withdraws funds from the gas subsidization pool.
/// 20. `getAvailableGasSubsidies(uint256 tokenId)`: Returns the amount of gas subsidies (in AP) accumulated by an AT.
/// 21. `claimGasSubsidies(uint256 tokenId)`: Allows an AT holder to convert accumulated gas subsidies into Aptitude Points (AP).

/// E. Governance & Admin Functions:
/// 22. `proposeParameterChange(bytes calldata callData, string calldata description)`: Allows AT holders to propose governance actions.
/// 23. `voteOnProposal(uint256 proposalId, bool support)`: AT holders vote on active proposals.
/// 24. `executeProposal(uint256 proposalId)`: Executes a passed governance proposal.
/// 25. `setAptitudeTokenUriBase(string calldata newBaseURI)`: Sets the base URI for AT metadata.
/// 26. `setMinAPForProposal(uint256 minAP)`: Sets the minimum AP required to create a new governance proposal.
/// 27. `setMinATLevelForTalentReset(uint256 _level)`: Sets the min AT level to reset talents.
/// 28. `setTalentResetCostAP(uint256 _costAP)`: Sets the AP cost for resetting talents.
/// 29. `setRequiredAPForLevel(uint256 level, uint256 requiredAP)`: Sets AP requirement for a specific level.
/// 30. `getProposalState(uint256 proposalId)`: Retrieves the current state of a governance proposal.

contract AptitudeGuild is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Base64 for bytes; // For dynamic tokenURI

    // --- Events ---
    event AptitudeTokenMinted(uint256 indexed tokenId, address indexed owner);
    event AptitudeLevelUp(uint256 indexed tokenId, uint256 newLevel);
    event AptitudePointsAwarded(uint256 indexed tokenId, uint256 amount);
    event TalentUnlocked(uint256 indexed tokenId, uint256 indexed talentId);
    event TalentTreeReset(uint256 indexed tokenId);
    event QuestCreated(uint256 indexed questId, QuestType indexed questType, address indexed creator);
    event QuestUpdated(uint256 indexed questId, address indexed updater);
    event QuestCompleted(uint256 indexed questId, uint256 indexed tokenId, address indexed completer);
    event AptitudeDelegated(uint256 indexed tokenId, address indexed delegator, address indexed delegatee);
    event AptitudeDelegationRevoked(uint256 indexed tokenId, address indexed delegator);
    event GasSubsidiesClaimed(uint256 indexed tokenId, uint256 amountAP);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, uint256 indexed tokenId, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Structs & Enums ---

    enum QuestType {
        ERC20_BALANCE_CHECK,    // Verify user holds a min balance of a token
        ERC721_OWNERSHIP_CHECK, // Verify user owns a specific NFT or min count of a collection
        CALL_EXTERNAL_VERIFIER  // Delegate verification to an external IQuestVerifier contract
    }

    struct AptitudeTokenData {
        address owner;
        uint256 level;
        uint256 aptitudePoints;
        uint256 gasSubsidiesAccumulated; // Amount of gas subsidies in AP, ready to be claimed
    }

    struct Quest {
        uint256 id;
        QuestType questType;
        address targetAddress;      // e.g., Token address, NFT contract address
        uint256 minRequiredValue;   // e.g., Min token balance, min NFT count
        address verifier;           // Address of IQuestVerifier for CALL_EXTERNAL_VERIFIER type
        string metadataCID;         // IPFS CID for detailed quest info
        uint256 rewardAP;           // Aptitude Points awarded on completion
        uint256 requiredATLevel;    // Minimum AT level to attempt quest
        uint256 cooldownDuration;   // Cooldown period for this quest for a specific AT (in seconds)
        bool isActive;
        bool gasSponsored;          // If true, gas costs for completion attempt are subsidized as AP
        mapping(uint256 => uint256) lastCompleted; // tokenId => timestamp of last completion
    }

    struct Talent {
        uint256 id;
        string name;
        string description;
        uint256 requiredLevel;
        uint256 parentTalentId; // 0 if root talent
    }

    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Executed }

    struct Proposal {
        uint256 id;
        bytes callData;         // The function call to execute if proposal passes
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 forVotes;
        uint256 againstVotes;
        address proposer;
        ProposalState state;
        mapping(uint256 => bool) hasVoted; // tokenId => hasVoted
    }

    // --- State Variables ---

    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _questIdCounter; // Used for unique quest IDs if they are incremental
    Counters.Counter private _talentIdCounter; // Used for unique talent IDs if they are incremental
    Counters.Counter private _proposalIdCounter;

    string private _aptitudeTokenUriBase; // Base URI for AT metadata, can be IPFS gateway
    mapping(uint256 => AptitudeTokenData) public aptitudeTokens;
    mapping(address => uint256) public aptitudeTokenIdOf; // User address to their AT tokenId (0 if none)

    mapping(uint256 => Quest) public quests;
    uint256[] public activeQuestIds; // Array to easily retrieve all active quest IDs

    mapping(uint256 => Talent) public talents;
    mapping(uint256 => mapping(uint256 => bool)) public unlockedTalents; // tokenId => talentId => unlocked status

    // APT level requirements
    mapping(uint256 => uint256) public requiredAPForLevel; // level => required AP for that level
    uint256 public constant MAX_LEVEL = 100; // Example max level

    // Gas subsidization
    uint256 public gasSubsidizationPool; // ETH stored for gas subsidies
    uint256 public gasSubsidiesPerAP; // How many AP are awarded per 1 ETH equivalent gas subsidization (e.g., 1e18 AP / 1e18 Wei)
    uint256 public minGasForSubsidy; // Minimum gas cost (in Wei) to trigger a subsidy for a sponsored quest

    // Governance
    uint256 public minAPForProposal; // Minimum AP required to create a governance proposal
    uint256 public proposalVotingPeriod; // Duration for voting in seconds
    uint256 public proposalThresholdAP; // Minimum *accumulated* AP votes needed for a proposal to pass (forVotes)
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(uint256 => bool)) public proposalVoteCast; // proposalId => tokenId => hasVoted

    uint256 public minATLevelForTalentReset = 10; // Minimum AT level to reset talents
    uint256 public talentResetCostAP = 1000; // AP cost for resetting talents

    // Delegation
    mapping(uint256 => address) public aptitudeDelegations; // tokenId => delegatee address for reputation

    // --- Constructor ---
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint256 _gasSubsidiesPerAP,
        uint256 _minGasForSubsidy,
        uint256 _minAPForProposal,
        uint256 _proposalVotingPeriod,
        uint256 _proposalThresholdAP
    ) ERC721(name, symbol) Ownable(msg.sender) {
        _aptitudeTokenUriBase = baseURI;
        gasSubsidiesPerAP = _gasSubsidiesPerAP;
        minGasForSubsidy = _minGasForSubsidy;

        // Initialize AP requirements for initial levels
        requiredAPForLevel[1] = 0; // Level 1 is free upon mint
        requiredAPForLevel[2] = 100;
        requiredAPForLevel[3] = 250;
        requiredAPForLevel[4] = 500;
        requiredAPForLevel[5] = 1000;
        // ... more levels can be set via setRequiredAPForLevel or governance

        minAPForProposal = _minAPForProposal;
        proposalVotingPeriod = _proposalVotingPeriod;
        proposalThresholdAP = _proposalThresholdAP;
    }

    // --- Modifiers ---

    /// @dev Requires that the caller is the owner of the given Aptitude Token or an approved address.
    modifier onlyAptitudeTokenOwner(uint256 tokenId) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "AptitudeGuild: Not AT owner or approved");
        _;
    }

    /// @dev Requires that the caller is the owner, an approved address, or the designated delegatee of the Aptitude Token.
    modifier onlyDelegatorOrOwner(uint256 tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || aptitudeDelegations[tokenId] == _msgSender(),
            "AptitudeGuild: Not AT owner, approved, or delegator"
        );
        _;
    }

    // --- A. AT Management (7 functions) ---

    /// @notice Mints a new, unique Aptitude Token (AT) for the caller.
    /// @dev ATs are non-transferable (Soulbound Tokens) and one per address.
    /// @return The tokenId of the newly minted Aptitude Token.
    function mintAptitudeToken() external returns (uint256) {
        require(aptitudeTokenIdOf[msg.sender] == 0, "AptitudeGuild: Caller already has an Aptitude Token");

        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(msg.sender, newItemId);
        aptitudeTokens[newItemId] = AptitudeTokenData({
            owner: msg.sender,
            level: 1, // Start at level 1
            aptitudePoints: 0,
            gasSubsidiesAccumulated: 0
        });
        aptitudeTokenIdOf[msg.sender] = newItemId;

        emit AptitudeTokenMinted(newItemId, msg.sender);
        return newItemId;
    }

    /// @notice Delegates the AT's 'reputation' to another address.
    /// The delegatee can perform certain actions on behalf of the AT owner (e.g., quest completion).
    /// @param tokenId The ID of the Aptitude Token.
    /// @param delegatee The address to delegate reputation to.
    function delegateAptitude(uint256 tokenId, address delegatee) external onlyAptitudeTokenOwner(tokenId) {
        require(delegatee != address(0), "AptitudeGuild: Delegatee cannot be zero address");
        aptitudeDelegations[tokenId] = delegatee;
        emit AptitudeDelegated(tokenId, msg.sender, delegatee);
    }

    /// @notice Revokes an existing aptitude delegation.
    /// @param tokenId The ID of the Aptitude Token.
    function revokeAptitudeDelegation(uint256 tokenId) external onlyAptitudeTokenOwner(tokenId) {
        require(aptitudeDelegations[tokenId] != address(0), "AptitudeGuild: No active delegation to revoke");
        aptitudeDelegations[tokenId] = address(0);
        emit AptitudeDelegationRevoked(tokenId, msg.sender);
    }

    /// @notice Retrieves the current level of a specific AT.
    /// @param tokenId The ID of the Aptitude Token.
    /// @return The current level.
    function getAptitudeLevel(uint256 tokenId) public view returns (uint256) {
        return aptitudeTokens[tokenId].level;
    }

    /// @notice Retrieves the total Aptitude Points (AP) accumulated by an AT.
    /// @param tokenId The ID of the Aptitude Token.
    /// @return The total Aptitude Points.
    function getAptitudePoints(uint256 tokenId) public view returns (uint256) {
        return aptitudeTokens[tokenId].aptitudePoints;
    }

    /// @notice Lists all talents unlocked by a given AT.
    /// @param tokenId The ID of the Aptitude Token.
    /// @return An array of unlocked talent IDs.
    function getUnlockedTalents(uint256 tokenId) public view returns (uint256[] memory) {
        uint256[] memory unlocked = new uint256[_talentIdCounter.current()];
        uint256 count = 0;
        for (uint256 i = 1; i <= _talentIdCounter.current(); i++) {
            if (unlockedTalents[tokenId][i]) {
                unlocked[count] = i;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory actualUnlocked = new uint256[](count);
        for(uint256 i = 0; i < count; i++){
            actualUnlocked[i] = unlocked[i];
        }
        return actualUnlocked;
    }

    /// @notice Returns the dynamic metadata URI for an Aptitude Token.
    /// @param tokenId The ID of the Aptitude Token.
    /// @return A data URI containing JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId); // Ensure token exists

        AptitudeTokenData storage atData = aptitudeTokens[tokenId];
        string memory level = atData.level.toString();
        string memory ap = atData.aptitudePoints.toString();
        string memory talentCount = getUnlockedTalents(tokenId).length.toString();

        string memory json = string.concat(
            '{"name": "Aptitude Token #', tokenId.toString(),
            '", "description": "A unique, non-transferable token representing on-chain aptitude and progress within the Aptitude Guild. Level up by completing quests!",',
            '"image": "', _aptitudeTokenUriBase, tokenId.toString(), '.png",', // Placeholder image, could be dynamic
            '"attributes": [',
            '{"trait_type": "Level", "value": ', level, '},',
            '{"trait_type": "Aptitude Points", "value": ', ap, '},',
            '{"trait_type": "Talents Unlocked", "value": ', talentCount, '}',
            ']}'
        );

        return string.concat("data:application/json;base64,", bytes(json).encode());
    }

    /// @dev Prevents transfers after mint to make it a Soulbound Token (SBT).
    /// Reverts if an attempt is made to transfer the token from one non-zero address to another non-zero address.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        if (from != address(0) && to != address(0)) {
            revert("AptitudeGuild: Aptitude Tokens are soulbound and cannot be transferred.");
        }
    }

    // --- B. Quest Management & Completion (6 functions) ---

    /// @notice Creates a new quest. Callable by owner/governance.
    /// @param questId The unique ID for the quest (can be a custom ID, or use getNextQuestId()).
    /// @param questType The type of verification logic for this quest.
    /// @param targetAddress The target address for verification (e.g., token address, NFT contract).
    /// @param minRequiredValue The minimum value required for completion (e.g., balance, count).
    /// @param verifier Address of an IQuestVerifier contract for `CALL_EXTERNAL_VERIFIER` type quests.
    /// @param metadataCID IPFS CID for detailed quest information.
    /// @param rewardAP Aptitude Points awarded upon successful completion.
    /// @param requiredATLevel Minimum AT level to attempt this quest.
    /// @param cooldownDuration Cooldown period in seconds for an AT to re-attempt this quest.
    /// @param gasSponsored If true, this quest is eligible for gas subsidization.
    function createQuest(
        uint256 questId,
        QuestType questType,
        address targetAddress,
        uint256 minRequiredValue,
        address verifier,
        string calldata metadataCID,
        uint256 rewardAP,
        uint256 requiredATLevel,
        uint256 cooldownDuration,
        bool gasSponsored
    ) external onlyOwner { // In a full DAO, this would be `onlyGovernance()`
        require(quests[questId].id == 0, "AptitudeGuild: Quest ID already exists");
        if (questType == QuestType.CALL_EXTERNAL_VERIFIER) {
            require(verifier != address(0), "AptitudeGuild: Verifier address required for external quest type");
        } else {
            require(verifier == address(0), "AptitudeGuild: Verifier address not applicable for this quest type");
        }
        
        quests[questId].id = questId;
        quests[questId].questType = questType;
        quests[questId].targetAddress = targetAddress;
        quests[questId].minRequiredValue = minRequiredValue;
        quests[questId].verifier = verifier;
        quests[questId].metadataCID = metadataCID;
        quests[questId].rewardAP = rewardAP;
        quests[questId].requiredATLevel = requiredATLevel;
        quests[questId].cooldownDuration = cooldownDuration;
        quests[questId].isActive = true;
        quests[questId].gasSponsored = gasSponsored;

        // If using auto-incrementing quest IDs, uncomment and manage _questIdCounter
        // _questIdCounter.increment(); 
        activeQuestIds.push(questId); // Add to active quest list
        emit QuestCreated(questId, questType, msg.sender);
    }

    /// @notice Updates an existing quest. Callable by owner/governance.
    /// @param questId The unique ID for the quest.
    /// @param questType The type of verification logic for this quest.
    /// @param targetAddress The target address for verification (e.g., token address, NFT contract).
    /// @param minRequiredValue The minimum value required for completion (e.g., balance, count).
    /// @param verifier Address of an IQuestVerifier contract for `CALL_EXTERNAL_VERIFIER` type quests.
    /// @param metadataCID IPFS CID for detailed quest information.
    /// @param rewardAP Aptitude Points awarded upon successful completion.
    /// @param requiredATLevel Minimum AT level to attempt this quest.
    /// @param cooldownDuration Cooldown period in seconds for an AT to re-attempt this quest.
    /// @param isActive Whether the quest is active and available for completion.
    /// @param gasSponsored If true, this quest is eligible for gas subsidization.
    function updateQuest(
        uint256 questId,
        QuestType questType,
        address targetAddress,
        uint256 minRequiredValue,
        address verifier,
        string calldata metadataCID,
        uint256 rewardAP,
        uint256 requiredATLevel,
        uint256 cooldownDuration,
        bool isActive,
        bool gasSponsored
    ) external onlyOwner { // In a full DAO, this would be `onlyGovernance()`
        require(quests[questId].id != 0, "AptitudeGuild: Quest ID does not exist");
        if (questType == QuestType.CALL_EXTERNAL_VERIFIER) {
            require(verifier != address(0), "AptitudeGuild: Verifier address required for external quest type");
        } else {
            require(verifier == address(0), "AptitudeGuild: Verifier address not applicable for this quest type");
        }

        Quest storage quest = quests[questId];
        quest.questType = questType;
        quest.targetAddress = targetAddress;
        quest.minRequiredValue = minRequiredValue;
        quest.verifier = verifier;
        quest.metadataCID = metadataCID;
        quest.rewardAP = rewardAP;
        quest.requiredATLevel = requiredATLevel;
        quest.cooldownDuration = cooldownDuration;
        
        // Handle changes in isActive status affecting activeQuestIds array
        if (quest.isActive != isActive) {
            quest.isActive = isActive;
            if (!isActive) { // Quest deactivated
                for (uint224 i = 0; i < activeQuestIds.length; i++) {
                    if (activeQuestIds[i] == questId) {
                        activeQuestIds[i] = activeQuestIds[activeQuestIds.length - 1];
                        activeQuestIds.pop();
                        break;
                    }
                }
            } else { // Quest reactivated
                bool found = false;
                for (uint224 i = 0; i < activeQuestIds.length; i++) {
                    if (activeQuestIds[i] == questId) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    activeQuestIds.push(questId);
                }
            }
        }
        quest.gasSponsored = gasSponsored;
        emit QuestUpdated(questId, msg.sender);
    }

    /// @notice Retrieves comprehensive details about a specific quest.
    /// @param questId The ID of the quest.
    /// @return A tuple containing all quest parameters.
    function getQuestDetails(uint256 questId)
        public
        view
        returns (
            uint256 id,
            QuestType questType,
            address targetAddress,
            uint256 minRequiredValue,
            address verifier,
            string memory metadataCID,
            uint256 rewardAP,
            uint256 requiredATLevel,
            uint256 cooldownDuration,
            bool isActive,
            bool gasSponsored
        )
    {
        Quest storage quest = quests[questId];
        require(quest.id != 0, "AptitudeGuild: Quest not found");
        return (
            quest.id,
            quest.questType,
            quest.targetAddress,
            quest.minRequiredValue,
            quest.verifier,
            quest.metadataCID,
            quest.rewardAP,
            quest.requiredATLevel,
            quest.cooldownDuration,
            quest.isActive,
            quest.gasSponsored
        );
    }

    /// @notice Returns an array of all currently active quest IDs.
    /// @return An array of active quest IDs.
    function getAllActiveQuestIds() public view returns (uint256[] memory) {
        return activeQuestIds;
    }

    /// @notice Allows a user to attempt completion of a quest.
    /// The contract verifies the quest requirements and awards AP.
    /// @param questId The ID of the quest to complete.
    /// @param tokenId The ID of the Aptitude Token to apply rewards to.
    /// @param verificationData Optional data required by external verifiers.
    function completeQuest(uint256 questId, uint256 tokenId, bytes memory verificationData) external onlyDelegatorOrOwner(tokenId) {
        Quest storage quest = quests[questId];
        AptitudeTokenData storage atData = aptitudeTokens[tokenId];

        require(quest.id != 0 && quest.isActive, "AptitudeGuild: Quest not found or inactive");
        require(atData.level >= quest.requiredATLevel, "AptitudeGuild: AT level too low for this quest");
        require(
            block.timestamp >= quest.lastCompleted[tokenId] + quest.cooldownDuration,
            "AptitudeGuild: Quest on cooldown for this AT"
        );

        bool verified = false;
        if (quest.questType == QuestType.ERC20_BALANCE_CHECK) {
            require(quest.targetAddress != address(0), "AptitudeGuild: Target address not set for ERC20 quest");
            require(IERC20(quest.targetAddress).balanceOf(ownerOf(tokenId)) >= quest.minRequiredValue, "AptitudeGuild: Insufficient ERC20 balance");
            verified = true;
        } else if (quest.questType == QuestType.ERC721_OWNERSHIP_CHECK) {
            require(quest.targetAddress != address(0), "AptitudeGuild: Target address not set for ERC721 quest");
            require(IERC721(quest.targetAddress).balanceOf(ownerOf(tokenId)) >= quest.minRequiredValue, "AptitudeGuild: Insufficient ERC721 count");
            verified = true;
        } else if (quest.questType == QuestType.CALL_EXTERNAL_VERIFIER) {
            require(quest.verifier != address(0), "AptitudeGuild: External verifier not set for this quest");
            verified = IQuestVerifier(quest.verifier).verify(ownerOf(tokenId), questId, verificationData);
        } else {
            revert("AptitudeGuild: Unknown quest type");
        }

        require(verified, "AptitudeGuild: Quest verification failed");

        // Award AP and handle level-up
        _awardAptitudePoints(tokenId, quest.rewardAP);
        quest.lastCompleted[tokenId] = block.timestamp; // Set cooldown timestamp
        
        // Handle gas subsidization if applicable. Gas is hard to refund directly.
        // Instead, we accumulate "gas subsidies" as additional AP for the user, claimable later.
        if (quest.gasSponsored) {
            // Note: block.gaslimit - gasleft() is an approximation of gas used in current context.
            // For more accurate tx gas cost, off-chain monitoring or specific L2 features might be needed.
            uint256 gasUsed = tx.gasprice * (block.gaslimit - gasleft());
            if (gasUsed >= minGasForSubsidy) {
                uint256 subsidyAP = gasUsed / gasSubsidiesPerAP;
                atData.gasSubsidiesAccumulated += subsidyAP;
                // Emit event for gas subsidy accumulation is implicit with GasSubsidiesClaimed
            }
        }

        emit QuestCompleted(questId, tokenId, msg.sender);
    }

    /// @dev Internal function to award Aptitude Points and check for level-ups.
    /// @param tokenId The ID of the Aptitude Token.
    /// @param amount The amount of AP to award.
    function _awardAptitudePoints(uint256 tokenId, uint256 amount) internal {
        AptitudeTokenData storage atData = aptitudeTokens[tokenId];
        atData.aptitudePoints += amount;
        emit AptitudePointsAwarded(tokenId, amount);

        _checkLevelUp(tokenId);
    }

    /// @dev Internal function to check if an AT should level up.
    /// @param tokenId The ID of the Aptitude Token.
    function _checkLevelUp(uint256 tokenId) internal {
        AptitudeTokenData storage atData = aptitudeTokens[tokenId];
        while (atData.level < MAX_LEVEL && atData.aptitudePoints >= requiredAPForLevel[atData.level + 1]) {
            atData.level++;
            emit AptitudeLevelUp(tokenId, atData.level);
        }
    }

    /// @notice Admin/DAO can reset a specific quest's cooldown for a user.
    /// @dev This could be used for special events or to fix issues.
    /// @param questId The ID of the quest.
    /// @param tokenId The ID of the Aptitude Token.
    function resetQuestCooldown(uint256 questId, uint256 tokenId) external onlyOwner {
        require(quests[questId].id != 0, "AptitudeGuild: Quest not found");
        require(aptitudeTokens[tokenId].owner != address(0), "AptitudeGuild: AT not found");
        quests[questId].lastCompleted[tokenId] = 0; // Reset to allow immediate re-attempt
    }

    // --- C. Talent Tree Management (4 functions) ---

    /// @notice Defines a new talent that can be unlocked by ATs.
    /// @param talentId Unique ID for the talent (can be custom, or use _talentIdCounter).
    /// @param name Name of the talent.
    /// @param description Description of the talent.
    /// @param requiredLevel The AT level required to unlock this talent.
    /// @param parentTalentId If this talent is part of a tree, ID of the parent talent (0 if root).
    function createTalent(
        uint256 talentId,
        string calldata name,
        string calldata description,
        uint256 requiredLevel,
        uint256 parentTalentId
    ) external onlyOwner {
        require(talents[talentId].id == 0, "AptitudeGuild: Talent ID already exists");
        if (parentTalentId != 0) {
            require(talents[parentTalentId].id != 0, "AptitudeGuild: Parent talent does not exist");
            require(requiredLevel > talents[parentTalentId].requiredLevel, "AptitudeGuild: Child talent level must be higher than parent");
        }

        talents[talentId] = Talent({
            id: talentId,
            name: name,
            description: description,
            requiredLevel: requiredLevel,
            parentTalentId: parentTalentId
        });
        _talentIdCounter.increment(); // Only if talentId is auto-incremented
    }

    /// @notice Allows an AT holder to unlock an available talent after reaching the required level.
    /// @param tokenId The ID of the Aptitude Token.
    /// @param talentId The ID of the talent to unlock.
    function unlockTalent(uint256 tokenId, uint256 talentId) external onlyAptitudeTokenOwner(tokenId) {
        Talent storage talent = talents[talentId];
        AptitudeTokenData storage atData = aptitudeTokens[tokenId];

        require(talent.id != 0, "AptitudeGuild: Talent not found");
        require(atData.level >= talent.requiredLevel, "AptitudeGuild: AT level too low to unlock talent");
        require(!unlockedTalents[tokenId][talentId], "AptitudeGuild: Talent already unlocked");

        if (talent.parentTalentId != 0) {
            require(unlockedTalents[tokenId][talent.parentTalentId], "AptitudeGuild: Parent talent must be unlocked first");
        }

        unlockedTalents[tokenId][talentId] = true;
        emit TalentUnlocked(tokenId, talentId);
    }

    /// @notice Allows an AT holder to reset their unlocked talents, with a defined AP cost.
    /// @param tokenId The ID of the Aptitude Token.
    function resetTalentTree(uint256 tokenId) external onlyAptitudeTokenOwner(tokenId) {
        AptitudeTokenData storage atData = aptitudeTokens[tokenId];

        require(atData.level >= minATLevelForTalentReset, "AptitudeGuild: AT level too low to reset talents");
        require(atData.aptitudePoints >= talentResetCostAP, "AptitudeGuild: Insufficient AP to reset talents");

        atData.aptitudePoints -= talentResetCostAP; // Deduct cost

        for (uint256 i = 1; i <= _talentIdCounter.current(); i++) {
            unlockedTalents[tokenId][i] = false; // Reset all talents
        }
        emit TalentTreeReset(tokenId);
    }

    /// @notice Retrieves details about a specific talent.
    /// @param talentId The ID of the talent.
    /// @return A tuple containing all talent parameters.
    function getTalentDetails(uint256 talentId)
        public
        view
        returns (
            uint256 id,
            string memory name,
            string memory description,
            uint256 requiredLevel,
            uint256 parentTalentId
        )
    {
        Talent storage talent = talents[talentId];
        require(talent.id != 0, "AptitudeGuild: Talent not found");
        return (talent.id, talent.name, talent.description, talent.requiredLevel, talent.parentTalentId);
    }

    // --- D. Gas Subsidization (4 functions) ---

    /// @notice Allows anyone to deposit ETH into the contract to subsidize gas for sponsored quests.
    function depositGasSubsidizationFunds() external payable {
        require(msg.value > 0, "AptitudeGuild: Deposit amount must be greater than zero");
        gasSubsidizationPool += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Admin/DAO withdraws funds from the gas subsidization pool.
    /// @param recipient The address to send the funds to.
    /// @param amount The amount of ETH to withdraw.
    function withdrawGasSubsidizationFunds(address recipient, uint256 amount) external onlyOwner {
        require(amount > 0, "AptitudeGuild: Withdrawal amount must be greater than zero");
        require(gasSubsidizationPool >= amount, "AptitudeGuild: Insufficient funds in subsidization pool");
        gasSubsidizationPool -= amount;
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "AptitudeGuild: ETH transfer failed");
        emit FundsWithdrawn(recipient, amount);
    }

    /// @notice Returns the amount of gas subsidies (in AP) accumulated by an AT.
    /// @param tokenId The ID of the Aptitude Token.
    /// @return The accumulated gas subsidies in AP.
    function getAvailableGasSubsidies(uint256 tokenId) public view returns (uint256) {
        return aptitudeTokens[tokenId].gasSubsidiesAccumulated;
    }

    /// @notice Allows an AT holder to convert accumulated gas subsidies into Aptitude Points.
    /// @param tokenId The ID of the Aptitude Token.
    function claimGasSubsidies(uint256 tokenId) external onlyAptitudeTokenOwner(tokenId) {
        AptitudeTokenData storage atData = aptitudeTokens[tokenId];
        uint256 subsidiesToClaim = atData.gasSubsidiesAccumulated;
        require(subsidiesToClaim > 0, "AptitudeGuild: No gas subsidies to claim");

        atData.gasSubsidiesAccumulated = 0;
        _awardAptitudePoints(tokenId, subsidiesToClaim); // Convert to AP

        emit GasSubsidiesClaimed(tokenId, subsidiesToClaim);
    }

    // --- E. Governance & Admin Functions (8 functions) ---

    /// @notice Allows AT holders with sufficient AP to propose a governance action.
    /// @dev Proposals execute direct calls to this contract's functions.
    /// @param callData The encoded function call to be executed if the proposal passes.
    /// @param description A brief description of the proposal.
    /// @return The ID of the newly created proposal.
    function proposeParameterChange(bytes calldata callData, string calldata description) external {
        uint256 tokenId = aptitudeTokenIdOf[msg.sender];
        require(tokenId != 0, "AptitudeGuild: Caller does not own an AT");
        require(aptitudeTokens[tokenId].aptitudePoints >= minAPForProposal, "AptitudeGuild: Insufficient AP to create proposal");

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            callData: callData,
            description: description,
            voteStartTime: block.timestamp,
            voteEndTime: block.timestamp + proposalVotingPeriod,
            forVotes: 0,
            againstVotes: 0,
            proposer: msg.sender,
            state: ProposalState.Active
        });

        emit ProposalCreated(proposalId, msg.sender);
        return proposalId;
    }

    /// @notice AT holders vote on active proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True for 'for' vote, false for 'against' vote.
    function voteOnProposal(uint256 proposalId, bool support) external {
        uint256 tokenId = aptitudeTokenIdOf[msg.sender];
        require(tokenId != 0, "AptitudeGuild: Caller does not own an AT");

        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AptitudeGuild: Proposal not found");
        require(getProposalState(proposalId) == ProposalState.Active, "AptitudeGuild: Proposal not in active voting period");
        require(!proposalVoteCast[proposalId][tokenId], "AptitudeGuild: AT already voted on this proposal");

        // Use AT's current AP as voting power
        uint256 votingPower = aptitudeTokens[tokenId].aptitudePoints;

        if (support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        proposalVoteCast[proposalId][tokenId] = true;

        emit VoteCast(proposalId, tokenId, support);
    }

    /// @notice Executes a passed governance proposal.
    /// @dev This function can be called by anyone after the voting period ends and the proposal has succeeded.
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "AptitudeGuild: Proposal not found");
        require(getProposalState(proposalId) == ProposalState.Succeeded, "AptitudeGuild: Proposal not in succeeded state");
        
        proposal.state = ProposalState.Executed;
        // Execute the callData. This allows governance to call any function on this contract.
        (bool success, ) = address(this).call(proposal.callData);
        require(success, "AptitudeGuild: Proposal execution failed");
        
        emit ProposalExecuted(proposalId);
    }

    /// @notice Sets the base URI for Aptitude Token metadata.
    /// @param newBaseURI The new base URI (e.g., an IPFS gateway URL).
    function setAptitudeTokenUriBase(string calldata newBaseURI) external onlyOwner {
        _aptitudeTokenUriBase = newBaseURI;
    }

    /// @notice Sets the minimum AP required to create a new governance proposal.
    /// @param minAP The new minimum AP.
    function setMinAPForProposal(uint256 minAP) external onlyOwner {
        minAPForProposal = minAP;
    }

    /// @notice Sets the minimum AT level required to reset talents.
    /// @param _level The new minimum level.
    function setMinATLevelForTalentReset(uint256 _level) external onlyOwner {
        minATLevelForTalentReset = _level;
    }

    /// @notice Sets the AP cost for resetting talents.
    /// @param _costAP The new AP cost.
    function setTalentResetCostAP(uint256 _costAP) external onlyOwner {
        talentResetCostAP = _costAP;
    }

    /// @notice Sets the required AP for a specific level.
    /// @dev Can be used to define the leveling curve.
    /// @param level The target level.
    /// @param requiredAP The AP required to reach this level.
    function setRequiredAPForLevel(uint256 level, uint256 requiredAP) external onlyOwner {
        require(level > 0 && level <= MAX_LEVEL, "AptitudeGuild: Invalid level");
        requiredAPForLevel[level] = requiredAP;
    }
    
    // --- Helper Functions (Public View) ---

    /// @notice Gets the current state of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The current ProposalState (Pending, Active, Canceled, Defeated, Succeeded, Executed).
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.id == 0) return ProposalState.Canceled; // Or a specific Not_Found state
        if (proposal.state == ProposalState.Executed || proposal.state == ProposalState.Defeated || proposal.state == ProposalState.Succeeded) {
            return proposal.state;
        }
        if (block.timestamp < proposal.voteStartTime) return ProposalState.Pending;
        if (block.timestamp <= proposal.voteEndTime) return ProposalState.Active;

        // Voting period has ended
        if (proposal.forVotes > proposal.againstVotes && proposal.forVotes >= proposalThresholdAP) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }
}
```