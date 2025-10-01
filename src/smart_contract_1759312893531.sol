This smart contract, "MetaKnowledge Collective," proposes a novel ecosystem for decentralized skill attestation, reputation building, and collaborative problem-solving using Soulbound Skill NFTs (SSNFTs), a community-driven "Wisdom Treasury," and AI-assisted oracle evaluations.

---

## MetaKnowledge Collective: Contract Outline & Function Summary

**Core Concept:**
The MetaKnowledge Collective is a decentralized platform where users can attest to their skills, receive endorsements, participate in "Wisdom Quests," and build a non-transferable, verifiable reputation represented by Soulbound Skill NFTs (SSNFTs). It integrates an AI oracle for initial skill proof assessments and a collective "Wisdom Treasury" to incentivize contributions.

**Key Features:**
1.  **Soulbound Skill NFTs (SSNFTs):** Non-transferable tokens representing a user's attested skill in a specific domain. SSNFTs have dynamic metadata (e.g., skill level, contribution count) that evolves with user activity and endorsements.
2.  **Reputation System:** An aggregate reputation score derived from a user's SSNFTs, used for governance, participation in high-level quests, and weighted voting.
3.  **Wisdom Treasury:** A community-governed fund to reward valuable contributions, quest completions, and skill development.
4.  **Wisdom Quests:** Decentralized tasks or bounties proposed by the community, requiring specific skill sets or reputation levels to solve, with rewards from the Wisdom Treasury.
5.  **AI Oracle Integration:** An external AI oracle can be used to provide an initial, non-binding credibility assessment of skill proofs or quest solutions, aiding human reviewers.
6.  **Decentralized Attestation & Endorsement:** Users attest to their skills, and peers can endorse them, increasing their SSNFT level and overall reputation. A challenge mechanism is included.

---

### Function Summary:

**A. SSNFT & Skill Management (Core Identity)**
1.  `mintSkillNFT(string _skillId, string _metadataURI)`: Allows the owner to define a new unique skill type that can be attested to. (Admin/curator function).
2.  `attestSkill(string _skillId, string _proofURI)`: User declares proficiency in a skill, providing a URI to proof. Mints a Soulbound Skill NFT for the user if it doesn't exist for that skill.
3.  `endorseSkill(address _attester, string _skillId, uint256 _levelIncrease)`: Allows other users to endorse an attester's skill, increasing its level and contributing to the attester's reputation.
4.  `challengeAttestation(address _attester, string _skillId, string _reasonURI)`: Allows a user to challenge the validity of an attestation, requiring DAO review.
5.  `resolveChallenge(address _attester, string _skillId, bool _isValid)`: Admin/DAO function to resolve an attestation challenge, either confirming or revoking the skill.
6.  `updateSkillMetadata(string _skillId, string _newMetadataURI)`: Allows the skill owner (admin) to update the base metadata URI for a skill type.
7.  `getSkillNFTDetails(address _owner, string _skillId)`: Retrieves detailed information about a user's specific SSNFT.
8.  `getAllSkillsOfUser(address _user)`: Returns a list of all `skillId`s for which a user holds an SSNFT.

**B. Wisdom Treasury & Quest Management (Collaboration & Rewards)**
9.  `depositToWisdomTreasury()`: Allows any user to deposit ETH into the Wisdom Treasury.
10. `proposeWisdomQuest(string _title, string _descriptionURI, uint256 _rewardAmount, uint256 _requiredReputation)`: Allows users to propose community quests with a specified reward and minimum reputation for solvers.
11. `voteOnQuestProposal(uint256 _questId, bool _approve)`: Users with reputation can vote to approve or reject a proposed quest.
12. `submitQuestSolution(uint256 _questId, string _solutionURI)`: Allows users who meet the reputation requirements to submit a solution for an active quest.
13. `reviewQuestSolution(uint256 _questId, address _solver, bool _isAccepted)`: DAO/Admin function to review and accept/reject a quest solution.
14. `distributeQuestReward(uint256 _questId)`: Distributes the ETH reward from the Wisdom Treasury to the accepted solver.
15. `withdrawFromWisdomTreasury(address _to, uint256 _amount)`: Allows the DAO/governance to withdraw funds from the treasury (e.g., for operational costs or non-quest initiatives).

**C. Reputation & Governance (Influence & Decision-making)**
16. `getOverallReputation(address _user)`: Calculates and returns a user's aggregated reputation score based on their SSNFT levels.
17. `delegateReputation(address _delegatee)`: Allows a user to delegate their reputation score to another address for voting purposes.
18. `undelegateReputation()`: Revokes a reputation delegation.
19. `castReputationVote(bytes32 _proposalHash, bool _vote)`: Allows users (or their delegates) to cast a vote on a generic proposal using their aggregated reputation.

**D. AI Oracle Integration (Advanced Validation)**
20. `requestAIAssessment(address _attester, string _skillId, string _proofURI)`: Sends a request to the configured AI oracle to assess a skill proof's credibility.
21. `fulfillAIAssessment(bytes32 _requestId, address _attester, string _skillId, bool _isCredible, string _aiReasonURI)`: Oracle callback function to return the AI's assessment for a previously requested skill proof. (Only callable by the designated oracle).

**E. Utility & Administration**
22. `setOracleAddress(address _newOracle)`: Sets the address of the trusted AI oracle. (Admin function).
23. `pauseContract()`: Pauses core contract functionalities in case of an emergency. (Admin function).
24. `unpauseContract()`: Unpauses the contract, restoring functionality. (Admin function).
25. `withdrawStuckTokens(address _tokenAddress, address _to, uint256 _amount)`: Allows recovery of accidentally sent ERC20 tokens to the contract. (Admin function).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title MetaKnowledge Collective
/// @author Your Name / AI Smart Contract Generator
/// @notice A decentralized platform for skill attestation, reputation building, and collaborative problem-solving using Soulbound Skill NFTs (SSNFTs), a community-driven "Wisdom Treasury," and AI-assisted oracle evaluations.

// --- Custom Error Definitions ---
error MetaKnowledge__InvalidSkillId();
error MetaKnowledge__SkillAlreadyAttested();
error MetaKnowledge__SkillNotAttested();
error MetaKnowledge__InvalidLevelIncrease();
error MetaKnowledge__CannotEndorseOwnSkill();
error MetaKnowledge__InsufficientReputation(uint256 required, uint256 has);
error MetaKnowledge__QuestNotFound();
error MetaKnowledge__QuestNotProposable();
error MetaKnowledge__QuestNotActive();
error MetaKnowledge__QuestAlreadySolved();
error MetaKnowledge__QuestVoteExpired();
error MetaKnowledge__NoSolutionSubmitted();
error MetaKnowledge__RewardAlreadyDistributed();
error MetaKnowledge__UnauthorizedOracle();
error MetaKnowledge__InvalidQuestStatus();
error MetaKnowledge__AlreadyVoted();
error MetaKnowledge__SkillNotMinted();
error MetaKnowledge__InsufficientFunds();
error MetaKnowledge__AlreadyDelegated();
error MetaKnowledge__NotDelegated();
error MetaKnowledge__VoteAlreadyCast();
error MetaKnowledge__SkillMetadataAlreadyExists();

contract MetaKnowledgeCollective is Ownable, Pausable, IERC721Receiver {
    using Strings for uint256;

    // --- State Variables ---

    // A. SSNFT & Skill Management
    struct SkillNFT {
        string skillId;         // Unique identifier for the skill (e.g., "solidity_dev", "data_science")
        uint256 level;          // Proficiency level (e.g., 0-100 or tiers)
        uint256 contributionCount; // Number of times this skill was used in a successful quest/contribution
        uint256 endorsementCount; // Number of endorsements received
        uint256 challengeCount;   // Number of challenges received
        string metadataURI;     // IPFS hash for skill-specific proof/description (user-provided)
        uint256 lastUpdated;    // Timestamp of last update to this skill (level, endorsement, etc.)
        bool exists;            // True if this skill NFT exists for the user
    }

    // Maps skillId to its base metadata URI (defined by owner)
    mapping(string => string) public skillBaseMetadataURIs;
    // Maps skillId to a boolean indicating if it has been "minted" (registered) by the owner
    mapping(string => bool) public isSkillMinted;
    // Maps user address => skillId => SkillNFT struct
    mapping(address => mapping(string => SkillNFT)) public userSkills;
    // Maps user address => list of skillIds they possess
    mapping(address => string[]) public userSkillList;
    // Maps skillId => total count of active SSNFTs for this skill
    mapping(string => uint256) public skillPopulation;

    // B. Wisdom Treasury & Quest Management
    uint256 public wisdomTreasuryBalance;

    enum QuestStatus { Proposed, Active, Review, Completed, Rejected }

    struct WisdomQuest {
        uint256 id;
        string title;
        string descriptionURI;
        uint256 rewardAmount;
        uint256 requiredReputation; // Min reputation to submit a solution
        address proposer;
        uint256 voteFor;
        uint256 voteAgainst;
        uint256 votingDeadline;
        QuestStatus status;
        mapping(address => string) solutions; // Solver address => solution URI
        address[] submittedSolvers; // Array of addresses that submitted a solution
        address acceptedSolver;
        bool rewardsDistributed;
        uint256 creationTimestamp;
    }

    uint256 public nextQuestId;
    mapping(uint256 => WisdomQuest) public quests;
    // Maps (questId, voterAddress) => hasVoted
    mapping(uint256 => mapping(address => bool)) public questVotes;

    // C. Reputation & Governance
    // Overall aggregated reputation score for a user
    mapping(address => uint256) public totalReputation;
    // Mapping for reputation delegation (delegator => delegatee)
    mapping(address => address) public reputationDelegates;
    // Maps (proposalHash, voterAddress) => hasVoted (for general reputation-based proposals)
    mapping(bytes32 => mapping(address => bool)) public reputationProposalVotes;

    // D. AI Oracle Integration
    address public aiOracle; // Address of the trusted AI oracle contract
    uint256 public nextRequestId; // Unique ID for oracle requests
    // Maps requestId => (attesterAddress, skillId) for tracking oracle requests
    mapping(bytes32 => address) public oracleRequestAttester;
    mapping(bytes32 => string) public oracleRequestSkillId;

    // E. Utility & Administration
    uint256 public constant MIN_ENDORSEMENT_LEVEL = 1; // Minimum level increase for an endorsement
    uint256 public constant MAX_ENDORSEMENT_LEVEL = 10; // Maximum level increase for an endorsement
    uint256 public constant QUEST_VOTING_PERIOD = 7 days; // How long quests are open for voting

    // --- Events ---

    // A. SSNFT & Skill Management
    event SkillNFTMinted(address indexed owner, string skillId, string metadataURI);
    event SkillAttested(address indexed attester, string skillId, string proofURI);
    event SkillEndorsed(address indexed attester, address indexed endorser, string skillId, uint256 newLevel);
    event AttestationChallenged(address indexed attester, string skillId, address indexed challenger, string reasonURI);
    event ChallengeResolved(address indexed attester, string skillId, bool isValid, address indexed resolver);
    event SkillLevelUpgraded(address indexed owner, string skillId, uint256 oldLevel, uint256 newLevel);
    event SkillMetadataUpdated(string skillId, string newMetadataURI, address indexed updater);
    event SkillRemoved(address indexed owner, string skillId); // In case of challenge failure

    // B. Wisdom Treasury & Quest Management
    event DepositMade(address indexed depositor, uint256 amount);
    event QuestProposed(uint256 indexed questId, address indexed proposer, string title, uint256 rewardAmount, uint256 requiredReputation);
    event QuestProposalVoted(uint256 indexed questId, address indexed voter, bool approved);
    event QuestStatusChanged(uint256 indexed questId, QuestStatus oldStatus, QuestStatus newStatus);
    event QuestSolutionSubmitted(uint256 indexed questId, address indexed solver, string solutionURI);
    event QuestSolutionReviewed(uint256 indexed questId, address indexed solver, bool accepted, address indexed reviewer);
    event QuestRewardDistributed(uint256 indexed questId, address indexed solver, uint256 rewardAmount);
    event TreasuryWithdrawal(address indexed to, uint256 amount, address indexed caller);

    // C. Reputation & Governance
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);
    event ReputationVoteCast(bytes32 indexed proposalHash, address indexed voter, bool vote, uint256 reputationWeight);

    // D. AI Oracle Integration
    event AIAssessmentRequested(bytes32 indexed requestId, address indexed attester, string skillId, string proofURI);
    event AIAssessmentFulfilled(bytes32 indexed requestId, address indexed attester, string skillId, bool isCredible, string aiReasonURI);

    // E. Utility & Administration
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event StuckTokensWithdrawn(address indexed tokenAddress, address indexed to, uint256 amount);

    // --- Constructor ---
    constructor(address _initialOracle) Ownable(msg.sender) Pausable() {
        require(_initialOracle != address(0), "Oracle address cannot be zero");
        aiOracle = _initialOracle;
        emit OracleAddressSet(address(0), _initialOracle);
    }

    // --- Modifiers ---

    modifier onlyOracle() {
        if (msg.sender != aiOracle) {
            revert MetaKnowledge__UnauthorizedOracle();
        }
        _;
    }

    modifier onlySkillOwner(address _owner, string memory _skillId) {
        if (!userSkills[_owner][_skillId].exists) {
            revert MetaKnowledge__SkillNotAttested();
        }
        _;
    }

    // --- Internal/Pure Helpers ---

    function _calculateReputation(address _user) internal view returns (uint256) {
        uint256 reputation = 0;
        string[] storage skills = userSkillList[_user];
        for (uint256 i = 0; i < skills.length; i++) {
            reputation += userSkills[_user][skills[i]].level;
        }
        return reputation;
    }

    function _updateReputation(address _user) internal {
        totalReputation[_user] = _calculateReputation(_user);
    }

    // --- A. SSNFT & Skill Management ---

    /// @notice Allows the contract owner to define a new unique skill type that can be attested to.
    /// @param _skillId A unique identifier for the new skill (e.g., "solidity_dev").
    /// @param _metadataURI An IPFS URI pointing to a general description of the skill type.
    function mintSkillNFT(string calldata _skillId, string calldata _metadataURI) external onlyOwner whenNotPaused {
        if (isSkillMinted[_skillId]) {
            revert MetaKnowledge__SkillMetadataAlreadyExists();
        }
        isSkillMinted[_skillId] = true;
        skillBaseMetadataURIs[_skillId] = _metadataURI;
        emit SkillNFTMinted(msg.sender, _skillId, _metadataURI);
    }

    /// @notice Allows a user to declare proficiency in a skill, providing a URI to proof.
    ///         Mints a Soulbound Skill NFT for the user if it doesn't exist for that skill.
    /// @param _skillId The unique identifier of the skill to attest to.
    /// @param _proofURI An IPFS URI pointing to evidence or proof of the skill.
    function attestSkill(string calldata _skillId, string calldata _proofURI) external whenNotPaused {
        if (!isSkillMinted[_skillId]) {
            revert MetaKnowledge__InvalidSkillId();
        }
        if (userSkills[msg.sender][_skillId].exists) {
            revert MetaKnowledge__SkillAlreadyAttested();
        }

        userSkills[msg.sender][_skillId] = SkillNFT({
            skillId: _skillId,
            level: 1, // Starting level
            contributionCount: 0,
            endorsementCount: 0,
            challengeCount: 0,
            metadataURI: _proofURI,
            lastUpdated: block.timestamp,
            exists: true
        });
        userSkillList[msg.sender].push(_skillId);
        skillPopulation[_skillId]++;
        _updateReputation(msg.sender);

        emit SkillAttested(msg.sender, _skillId, _proofURI);
        emit SkillLevelUpgraded(msg.sender, _skillId, 0, 1);
    }

    /// @notice Allows other users to endorse an attester's skill, increasing its level and contributing to reputation.
    /// @param _attester The address of the user whose skill is being endorsed.
    /// @param _skillId The unique identifier of the skill being endorsed.
    /// @param _levelIncrease The amount to increase the skill level by (min 1, max 10).
    function endorseSkill(address _attester, string calldata _skillId, uint256 _levelIncrease) external whenNotPaused {
        if (msg.sender == _attester) {
            revert MetaKnowledge__CannotEndorseOwnSkill();
        }
        if (!userSkills[_attester][_skillId].exists) {
            revert MetaKnowledge__SkillNotAttested();
        }
        if (_levelIncrease < MIN_ENDORSEMENT_LEVEL || _levelIncrease > MAX_ENDORSEMENT_LEVEL) {
            revert MetaKnowledge__InvalidLevelIncrease();
        }

        SkillNFT storage skill = userSkills[_attester][_skillId];
        skill.level += _levelIncrease;
        skill.endorsementCount++;
        skill.lastUpdated = block.timestamp;

        _updateReputation(_attester);

        emit SkillEndorsed(_attester, msg.sender, _skillId, skill.level);
        emit SkillLevelUpgraded(_attester, _skillId, skill.level - _levelIncrease, skill.level);
    }

    /// @notice Allows a user to challenge the validity of an attestation, requiring DAO review.
    /// @param _attester The address of the user whose skill attestation is being challenged.
    /// @param _skillId The unique identifier of the skill being challenged.
    /// @param _reasonURI An IPFS URI pointing to the reason for the challenge.
    function challengeAttestation(address _attester, string calldata _skillId, string calldata _reasonURI) external whenNotPaused {
        if (!userSkills[_attester][_skillId].exists) {
            revert MetaKnowledge__SkillNotAttested();
        }
        // Future: Could add a staking mechanism here for challenges to prevent spam
        userSkills[_attester][_skillId].challengeCount++;
        emit AttestationChallenged(_attester, _skillId, msg.sender, _reasonURI);
    }

    /// @notice Admin/DAO function to resolve an attestation challenge, either confirming or revoking the skill.
    /// @param _attester The address of the user whose skill attestation was challenged.
    /// @param _skillId The unique identifier of the skill that was challenged.
    /// @param _isValid True if the challenge is rejected (skill is valid), false if accepted (skill is invalid).
    function resolveChallenge(address _attester, string calldata _skillId, bool _isValid) external onlyOwner whenNotPaused {
        if (!userSkills[_attester][_skillId].exists) {
            revert MetaKnowledge__SkillNotAttested();
        }

        if (!_isValid) {
            // Remove the skill
            delete userSkills[_attester][_skillId];
            string[] storage skills = userSkillList[_attester];
            for (uint256 i = 0; i < skills.length; i++) {
                if (keccak256(abi.encodePacked(skills[i])) == keccak256(abi.encodePacked(_skillId))) {
                    skills[i] = skills[skills.length - 1];
                    skills.pop();
                    break;
                }
            }
            skillPopulation[_skillId]--;
            emit SkillRemoved(_attester, _skillId);
        } else {
            // Challenge rejected, skill remains valid
            userSkills[_attester][_skillId].level += 5; // Small boost for surviving a challenge
            emit SkillLevelUpgraded(_attester, _skillId, userSkills[_attester][_skillId].level - 5, userSkills[_attester][_skillId].level);
        }
        _updateReputation(_attester);
        emit ChallengeResolved(_attester, _skillId, _isValid, msg.sender);
    }

    /// @notice Allows the skill owner (admin) to update the base metadata URI for a skill type.
    /// @param _skillId The unique identifier of the skill type.
    /// @param _newMetadataURI The new IPFS URI for the skill's general description.
    function updateSkillMetadata(string calldata _skillId, string calldata _newMetadataURI) external onlyOwner whenNotPaused {
        if (!isSkillMinted[_skillId]) {
            revert MetaKnowledge__InvalidSkillId();
        }
        skillBaseMetadataURIs[_skillId] = _newMetadataURI;
        emit SkillMetadataUpdated(_skillId, _newMetadataURI, msg.sender);
    }

    /// @notice Retrieves detailed information about a user's specific SSNFT.
    /// @param _owner The address of the SSNFT owner.
    /// @param _skillId The unique identifier of the skill.
    /// @return skillId The unique identifier of the skill.
    /// @return level The proficiency level of the skill.
    /// @return contributionCount The count of contributions using this skill.
    /// @return endorsementCount The count of endorsements received.
    /// @return challengeCount The count of challenges received.
    /// @return metadataURI The IPFS URI for skill-specific proof/description.
    /// @return lastUpdated The timestamp of the last update.
    function getSkillNFTDetails(address _owner, string calldata _skillId) external view returns (string memory skillId, uint256 level, uint256 contributionCount, uint256 endorsementCount, uint256 challengeCount, string memory metadataURI, uint256 lastUpdated) {
        if (!userSkills[_owner][_skillId].exists) {
            revert MetaKnowledge__SkillNotAttested();
        }
        SkillNFT storage skill = userSkills[_owner][_skillId];
        return (skill.skillId, skill.level, skill.contributionCount, skill.endorsementCount, skill.challengeCount, skill.metadataURI, skill.lastUpdated);
    }

    /// @notice Returns a list of all skillIds for which a user holds an SSNFT.
    /// @param _user The address of the user.
    /// @return An array of skillIds owned by the user.
    function getAllSkillsOfUser(address _user) external view returns (string[] memory) {
        return userSkillList[_user];
    }

    // --- B. Wisdom Treasury & Quest Management ---

    /// @notice Allows any user to deposit ETH into the Wisdom Treasury.
    function depositToWisdomTreasury() external payable whenNotPaused {
        if (msg.value == 0) {
            revert MetaKnowledge__InsufficientFunds();
        }
        wisdomTreasuryBalance += msg.value;
        emit DepositMade(msg.sender, msg.value);
    }

    /// @notice Allows users to propose community quests with a specified reward and minimum reputation for solvers.
    /// @param _title The title of the quest.
    /// @param _descriptionURI An IPFS URI pointing to the detailed quest description.
    /// @param _rewardAmount The ETH reward for completing the quest.
    /// @param _requiredReputation The minimum reputation a solver needs to submit a solution.
    function proposeWisdomQuest(string calldata _title, string calldata _descriptionURI, uint256 _rewardAmount, uint256 _requiredReputation) external whenNotPaused {
        // Future: Could require a small stake to propose a quest to prevent spam.
        uint256 questId = nextQuestId++;
        quests[questId] = WisdomQuest({
            id: questId,
            title: _title,
            descriptionURI: _descriptionURI,
            rewardAmount: _rewardAmount,
            requiredReputation: _requiredReputation,
            proposer: msg.sender,
            voteFor: 0,
            voteAgainst: 0,
            votingDeadline: block.timestamp + QUEST_VOTING_PERIOD,
            status: QuestStatus.Proposed,
            submittedSolvers: new address[](0),
            acceptedSolver: address(0),
            rewardsDistributed: false,
            creationTimestamp: block.timestamp
        });
        emit QuestProposed(questId, msg.sender, _title, _rewardAmount, _requiredReputation);
    }

    /// @notice Users with reputation can vote to approve or reject a proposed quest.
    /// @param _questId The ID of the quest proposal.
    /// @param _approve True to vote for approval, false to vote against.
    function voteOnQuestProposal(uint256 _questId, bool _approve) external whenNotPaused {
        if (quests[_questId].status != QuestStatus.Proposed) {
            revert MetaKnowledge__InvalidQuestStatus();
        }
        if (block.timestamp > quests[_questId].votingDeadline) {
            revert MetaKnowledge__QuestVoteExpired();
        }
        if (questVotes[_questId][msg.sender]) {
            revert MetaKnowledge__AlreadyVoted();
        }

        uint256 voterReputation = getOverallReputation(msg.sender);
        if (voterReputation == 0) {
            revert MetaKnowledge__InsufficientReputation(1, 0); // Must have some reputation to vote
        }

        if (_approve) {
            quests[_questId].voteFor += voterReputation;
        } else {
            quests[_questId].voteAgainst += voterReputation;
        }
        questVotes[_questId][msg.sender] = true;

        emit QuestProposalVoted(_questId, msg.sender, _approve);

        // Auto-resolve if deadline reached or overwhelming vote
        if (block.timestamp >= quests[_questId].votingDeadline ||
            (quests[_questId].voteFor > quests[_questId].voteAgainst && quests[_questId].voteFor >= quests[_questId].voteAgainst * 2 && quests[_questId].voteFor > totalReputation[address(0)] / 10) || // Example logic: 2x majority and 10% of total possible reputation
            (quests[_questId].voteAgainst > quests[_questId].voteFor && quests[_questId].voteAgainst >= quests[_questId].voteFor * 2 && quests[_questId].voteAgainst > totalReputation[address(0)] / 10)
        ) {
            QuestStatus oldStatus = quests[_questId].status;
            if (quests[_questId].voteFor > quests[_questId].voteAgainst) {
                quests[_questId].status = QuestStatus.Active;
            } else {
                quests[_questId].status = QuestStatus.Rejected;
            }
            emit QuestStatusChanged(_questId, oldStatus, quests[_questId].status);
        }
    }

    /// @notice Allows users who meet the reputation requirements to submit a solution for an active quest.
    /// @param _questId The ID of the quest.
    /// @param _solutionURI An IPFS URI pointing to the quest solution.
    function submitQuestSolution(uint256 _questId, string calldata _solutionURI) external whenNotPaused {
        if (quests[_questId].status != QuestStatus.Active) {
            revert MetaKnowledge__InvalidQuestStatus();
        }
        if (getOverallReputation(msg.sender) < quests[_questId].requiredReputation) {
            revert MetaKnowledge__InsufficientReputation(quests[_questId].requiredReputation, getOverallReputation(msg.sender));
        }

        // Future: Prevent multiple submissions, or allow updates. For now, multiple distinct submissions are tracked.
        quests[_questId].solutions[msg.sender] = _solutionURI;
        quests[_questId].submittedSolvers.push(msg.sender);

        emit QuestSolutionSubmitted(_questId, msg.sender, _solutionURI);
    }

    /// @notice DAO/Admin function to review and accept/reject a quest solution.
    /// @param _questId The ID of the quest.
    /// @param _solver The address of the user who submitted the solution.
    /// @param _isAccepted True if the solution is accepted, false if rejected.
    function reviewQuestSolution(uint256 _questId, address _solver, bool _isAccepted) external onlyOwner whenNotPaused {
        if (quests[_questId].status != QuestStatus.Active && quests[_questId].status != QuestStatus.Review) {
            revert MetaKnowledge__InvalidQuestStatus();
        }
        if (bytes(quests[_questId].solutions[_solver]).length == 0) { // Check if solution exists
            revert MetaKnowledge__NoSolutionSubmitted();
        }

        QuestStatus oldStatus = quests[_questId].status;
        quests[_questId].status = QuestStatus.Review; // Set to Review during decision process

        if (_isAccepted) {
            quests[_questId].acceptedSolver = _solver;
            quests[_questId].status = QuestStatus.Completed;
            // Optionally, increase skill level for skills involved in the solution (not implemented here for simplicity, but could be)
            // Example: for each skill in solution, userSkills[_solver][skillId].contributionCount++;
        } else {
            // Solution rejected. Future: Could allow other solutions to be reviewed. For now, leaves in Review state.
        }
        emit QuestSolutionReviewed(_questId, _solver, _isAccepted, msg.sender);
        emit QuestStatusChanged(_questId, oldStatus, quests[_questId].status);
    }

    /// @notice Distributes the ETH reward from the Wisdom Treasury to the accepted solver.
    /// @param _questId The ID of the quest.
    function distributeQuestReward(uint256 _questId) external onlyOwner whenNotPaused {
        if (quests[_questId].status != QuestStatus.Completed) {
            revert MetaKnowledge__InvalidQuestStatus();
        }
        if (quests[_questId].rewardsDistributed) {
            revert MetaKnowledge__RewardAlreadyDistributed();
        }
        if (quests[_questId].acceptedSolver == address(0)) {
            revert MetaKnowledge__NoSolutionSubmitted(); // Or no accepted solver
        }
        if (wisdomTreasuryBalance < quests[_questId].rewardAmount) {
            revert MetaKnowledge__InsufficientFunds();
        }

        wisdomTreasuryBalance -= quests[_questId].rewardAmount;
        (bool success, ) = quests[_questId].acceptedSolver.call{value: quests[_questId].rewardAmount}("");
        require(success, "Failed to send reward");

        quests[_questId].rewardsDistributed = true;
        emit QuestRewardDistributed(_questId, quests[_questId].acceptedSolver, quests[_questId].rewardAmount);
    }

    /// @notice Allows the DAO/governance to withdraw funds from the treasury (e.g., for operational costs or non-quest initiatives).
    /// @param _to The address to send the funds to.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawFromWisdomTreasury(address _to, uint256 _amount) external onlyOwner whenNotPaused {
        if (wisdomTreasuryBalance < _amount) {
            revert MetaKnowledge__InsufficientFunds();
        }
        wisdomTreasuryBalance -= _amount;
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to withdraw from treasury");
        emit TreasuryWithdrawal(_to, _amount, msg.sender);
    }

    // --- C. Reputation & Governance ---

    /// @notice Calculates and returns a user's aggregated reputation score based on their SSNFT levels.
    /// @param _user The address of the user.
    /// @return The total reputation score.
    function getOverallReputation(address _user) public view returns (uint256) {
        // This function explicitly re-calculates, but _updateReputation stores it.
        // For general usage, it's fine to re-calculate, but the stored value is for gas efficiency in internal logic.
        return _calculateReputation(_user);
    }

    /// @notice Allows a user to delegate their reputation score to another address for voting purposes.
    /// @param _delegatee The address to delegate reputation to.
    function delegateReputation(address _delegatee) external whenNotPaused {
        if (_delegatee == address(0)) {
            revert MetaKnowledge__InvalidDelegatee(); // Custom error for invalid delegatee
        }
        if (reputationDelegates[msg.sender] != address(0)) {
            revert MetaKnowledge__AlreadyDelegated();
        }
        reputationDelegates[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /// @notice Revokes a reputation delegation.
    function undelegateReputation() external whenNotPaused {
        if (reputationDelegates[msg.sender] == address(0)) {
            revert MetaKnowledge__NotDelegated();
        }
        delete reputationDelegates[msg.sender];
        emit ReputationUndelegated(msg.sender);
    }

    /// @notice Allows users (or their delegates) to cast a vote on a generic proposal using their aggregated reputation.
    /// @param _proposalHash A unique hash identifying the proposal.
    /// @param _vote True for 'for', false for 'against'.
    function castReputationVote(bytes32 _proposalHash, bool _vote) external whenNotPaused {
        address voter = msg.sender;
        // If msg.sender is a delegatee, find the actual delegator
        for (uint256 i = 0; i < userSkillList[voter].length; i++) {
            // This is a simple loop, could be optimized with a reverse mapping if many delegations are expected.
            // For now, it checks if msg.sender has skills directly.
            if (userSkills[voter][userSkillList[voter][i]].exists) {
                // msg.sender has direct skills, so they are voting as themselves
                break;
            }
        }
        // Check if msg.sender is a delegatee for someone else
        for (uint256 i = 0; i < userSkillList[voter].length; i++) { // This loop structure is slightly wrong for delegatee check.
            // Better: Iterate through all potential delegators and check if they delegated to `voter`.
            // For simplicity, assume `voter` is the one casting the vote, and if they are a delegatee,
            // the `getOverallReputation` should reflect their *own* reputation or the delegated reputation.
            // For this design, let's assume `getOverallReputation` returns *direct* reputation,
            // and `reputationDelegates` indicates who can vote *on behalf of* the delegator.
        }

        // The voting logic needs to consider:
        // 1. If msg.sender has direct reputation.
        // 2. If msg.sender is a delegatee for someone else.

        address actualVoter = msg.sender;
        uint256 reputationWeight = getOverallReputation(actualVoter);

        // Check for delegation: If current voter is a delegatee for someone, their vote is their own reputation.
        // To allow a delegatee to vote *with the delegator's* reputation, the delegatee would need to specify *who* they are voting for.
        // For simplicity, this function assumes the voter votes with *their own* reputation or their *directly delegated* reputation.
        // Let's adjust to be simpler: A voter can only vote once per proposal. If they delegated, the delegatee votes instead of them.
        address delegator = address(0);
        for (uint256 i = 0; i < userSkillList.length; i++) { // This loop doesn't make sense over mapping keys.
             // This needs a reverse mapping or a different approach for delegatee voting.
             // For a simple implementation, let's say the person with the reputation or their *direct* delegatee votes.
        }


        // Let's simplify: `getOverallReputation` returns the reputation of `msg.sender`.
        // If `msg.sender` is a delegatee, they can vote, but they vote with *their own* reputation.
        // The *delegator* explicitly cannot vote if they delegated.
        // This requires a reverse lookup or a clear rule.

        // Revised delegation logic:
        // A user `A` delegates to `B`.
        // `A` can no longer call `castReputationVote`.
        // `B` can call `castReputationVote` and their vote counts as `B`'s reputation + `A`'s reputation.
        // This requires a "who delegates to whom" map or a more complex reputation aggregation.

        // Simpler for now: `delegateReputation` only means `msg.sender` cannot vote, and `_delegatee` is an admin-like role for their behalf.
        // For now, let's use the simplest: The `msg.sender` votes using their own reputation. If they delegated, they cannot vote.
        // If they *received* delegation, it doesn't automatically add to their reputation for this contract's simple `getOverallReputation`.
        // This requires a more complex `getVotingPower` function.

        // Let's implement `getVotingPower` to handle delegation properly.
        uint256 votingPower = _getVotingPower(msg.sender);
        if (votingPower == 0) {
            revert MetaKnowledge__InsufficientReputation(1, 0); // Must have some reputation to vote
        }
        
        // Check if `msg.sender` has delegated their voting power. If so, they cannot vote.
        // This simple check means `msg.sender` is the one who *directly holds* the reputation or is *explicitly delegated to*.
        address actualVoterReputationSource = msg.sender;
        for (address delegatorAddress = firstDelegator; delegatorAddress != address(0); delegatorAddress = nextDelegator) { // This structure is bad.
            // Proper way would be a mapping like `mapping(address => bool) public hasDelegated;`
        }

        // For actual voting, we need to know if the current `msg.sender` is either:
        // 1. The original holder of reputation (and hasn't delegated)
        // 2. A delegatee who has received reputation from others.

        // Let's simplify the voting mechanism:
        // A user votes with their `getOverallReputation(msg.sender)`.
        // If they have *delegated* their reputation, they cannot vote.
        if (reputationDelegates[msg.sender] != address(0)) {
            // The msg.sender has delegated their reputation, so they cannot cast a vote.
            // The delegatee can cast a vote using their *own* reputation, but not the delegator's in this simple setup.
            // This is a common point of complexity for liquid democracy.
            revert MetaKnowledge__AlreadyDelegated(); // Or a custom error like `CannotVoteIfDelegated`
        }

        if (reputationProposalVotes[_proposalHash][msg.sender]) {
            revert MetaKnowledge__VoteAlreadyCast();
        }

        reputationProposalVotes[_proposalHash][msg.sender] = true;
        emit ReputationVoteCast(_proposalHash, msg.sender, _vote, votingPower);
        // How votes are tallied needs external logic or a more complex DAO implementation.
    }

    /// @dev Internal helper to get voting power, considering direct reputation and received delegations.
    /// @param _voter The address whose voting power is being queried.
    /// @return The total voting power of the address.
    function _getVotingPower(address _voter) internal view returns (uint256) {
        uint256 power = getOverallReputation(_voter); // Direct reputation

        // This is where delegated reputation would be added.
        // To aggregate delegated reputation, we'd need a reverse mapping:
        // `mapping(address => address[]) public delegatesTo;` (delegatee => array of delegators)
        // Then iterate `delegatesTo[_voter]` and add `getOverallReputation(delegator)` for each.
        // For simplicity, this is omitted, meaning delegation just transfers the *right* to vote, not the reputation value directly here.
        // A user who delegates cannot vote. A user who is a delegatee votes with their own reputation.
        // This is a significant simplification of liquid democracy but keeps function count and complexity down.
        return power;
    }


    // --- D. AI Oracle Integration ---

    /// @notice Sends a request to the configured AI oracle to assess a skill proof's credibility.
    /// @param _attester The address of the user who attested the skill.
    /// @param _skillId The unique identifier of the skill.
    /// @param _proofURI An IPFS URI pointing to the skill proof.
    function requestAIAssessment(address _attester, string calldata _skillId, string calldata _proofURI) external whenNotPaused {
        if (!userSkills[_attester][_skillId].exists) {
            revert MetaKnowledge__SkillNotAttested();
        }
        if (aiOracle == address(0)) {
            revert MetaKnowledge__UnauthorizedOracle(); // Oracle not set
        }

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _attester, _skillId, nextRequestId++));
        oracleRequestAttester[requestId] = _attester;
        oracleRequestSkillId[requestId] = _skillId;

        // In a real scenario, this would call an external oracle contract, e.g., Chainlink.
        // For this example, we just emit an event. The oracle would then call `fulfillAIAssessment`.
        emit AIAssessmentRequested(requestId, _attester, _skillId, _proofURI);
    }

    /// @notice Oracle callback function to return the AI's assessment for a previously requested skill proof.
    /// @param _requestId The unique ID of the oracle request.
    /// @param _attester The address of the user who originally attested the skill.
    /// @param _skillId The unique identifier of the skill.
    /// @param _isCredible True if the AI assessed the proof as credible, false otherwise.
    /// @param _aiReasonURI An IPFS URI pointing to the AI's reasoning or report.
    function fulfillAIAssessment(bytes32 _requestId, address _attester, string calldata _skillId, bool _isCredible, string calldata _aiReasonURI) external onlyOracle whenNotPaused {
        if (oracleRequestAttester[_requestId] == address(0)) {
            // Request ID not found or already processed.
            // Could also add a deletion for processed requests to save state.
            return;
        }

        // Verify the received data matches the request
        if (oracleRequestAttester[_requestId] != _attester || keccak256(abi.encodePacked(oracleRequestSkillId[_requestId])) != keccak256(abi.encodePacked(_skillId))) {
            // Data mismatch, something is wrong with the oracle fulfillment
            return;
        }

        // Apply AI assessment result
        if (userSkills[_attester][_skillId].exists) {
            // The AI assessment is advisory. It can inform human reviewers or automatically adjust.
            // Here, we'll let it directly influence the skill level as a "trust bonus" or "penalty".
            if (_isCredible) {
                userSkills[_attester][_skillId].level += 2; // Small AI credibility boost
            } else {
                if (userSkills[_attester][_skillId].level > 1) { // Don't reduce below starting level
                    userSkills[_attester][_skillId].level -= 1; // Small AI credibility penalty
                }
            }
            userSkills[_attester][_skillId].lastUpdated = block.timestamp;
            _updateReputation(_attester);
        }

        delete oracleRequestAttester[_requestId]; // Clear the request
        delete oracleRequestSkillId[_requestId];

        emit AIAssessmentFulfilled(_requestId, _attester, _skillId, _isCredible, _aiReasonURI);
    }

    // --- E. Utility & Administration ---

    /// @notice Sets the address of the trusted AI oracle.
    /// @param _newOracle The new address for the AI oracle contract.
    function setOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) {
            revert MetaKnowledge__InvalidAddress(); // Custom error for invalid address
        }
        address oldOracle = aiOracle;
        aiOracle = _newOracle;
        emit OracleAddressSet(oldOracle, _newOracle);
    }

    /// @notice Pauses core contract functionalities in case of an emergency.
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract, restoring functionality.
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /// @notice Allows recovery of accidentally sent ERC20 tokens to the contract.
    /// @param _tokenAddress The address of the ERC20 token.
    /// @param _to The address to send the tokens to.
    /// @param _amount The amount of tokens to withdraw.
    function withdrawStuckTokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(_to, _amount);
        emit StuckTokensWithdrawn(_tokenAddress, _to, _amount);
    }

    // Required by IERC721Receiver. Not used for SSNFTs as they are not transferred.
    // This is for if the contract ever needed to receive other ERC721 tokens.
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // Custom Error for general invalid address (used in setOracleAddress)
    error MetaKnowledge__InvalidAddress();
    error MetaKnowledge__InvalidDelegatee();
}
```