This smart contract, **ChronoForge**, is designed as a sophisticated, multi-faceted protocol that intertwines **Soulbound Tokens (SBTs)**, **Dynamic NFTs**, **AI Oracle integration**, a **Decentralized Knowledge Repository**, and an **On-chain Reputation System**. It allows users to mint non-transferable "Skill" SBTs that evolve based on AI-evaluated on-chain activities, contribute to a curated knowledge base, and earn reputation. The protocol is governed by a DAO-like structure for its AI parameters and rewards.

---

## ChronoForge: Dynamic Soulbound Skills & AI-Curated Repositories

**Purpose:** To create a platform where users can mint and evolve non-transferable skill-based Soulbound Tokens (SBTs), contribute to an AI-curated decentralized knowledge repository, and build an on-chain reputation based on their activities and contributions. The system integrates an external AI oracle for dynamic evaluations and curation.

**Key Concepts:**
1.  **Soulbound Skills (SBTs):** Non-transferable NFTs representing unique skills, achievements, or roles tied directly to a wallet address.
2.  **Dynamic NFTs:** These SBTs can evolve and upgrade their metadata and attributes based on AI evaluations of on-chain activities or specific criteria.
3.  **AI Oracle Integration:** An external AI rule engine provides verifiable results for skill upgrades and knowledge base curation.
4.  **Decentralized Knowledge Repository:** Users can contribute content (e.g., educational materials, research, code snippets) linked to their skills, which is then AI-curated.
5.  **On-chain Reputation System:** A comprehensive score derived from skill levels, knowledge contributions, and active participation in the protocol.
6.  **DAO Governance (Simplified):** A mechanism for community-driven proposals and approvals of AI rule parameters.
7.  **Validator Staking:** Users can stake tokens to become "AI Validators" who can vote on AI rule proposals and potentially earn rewards for maintaining the integrity of the AI rule engine.

---

### Contract Outline & Function Summary:

**I. Core Infrastructure & Access Control**
*   `constructor()`: Initializes the contract with the deployer as the owner.
*   `setAIRuleEngineAddress(address _newEngine)`: Sets the authorized address for the AI rule engine.
*   `setSkillUpgradeFee(uint256 _fee)`: Sets the fee required to request a skill upgrade.
*   `pauseContractOperations(bool _state)`: Emergency function to pause/unpause critical operations.
*   `upgradeContractAddress(address _newAddress)`: Stores a reference to a new contract address for future upgrades (e.g., via a proxy).

**II. Soulbound Skill Token (SBT) Management (ERC721-like)**
*   `mintSoulboundSkill(address _recipient, string memory _initialSkillName, string memory _initialMetadataURI)`: Mints a new non-transferable Skill SBT.
*   `requestSkillUpgrade(uint256 _tokenId)`: Initiates a request for the AI rule engine to evaluate and potentially upgrade a skill.
*   `updateSkillMetadata(uint256 _tokenId, string memory _newMetadataURI)`: Allows governance/owner to directly update an SBT's metadata URI (e.g., after an AI upgrade).
*   `getSkillDetails(uint256 _tokenId)`: Retrieves all details of a specific Skill SBT.
*   `grantAdminBadge(address _recipient, string memory _badgeName, string memory _metadataURI)`: Allows the owner/governance to mint static, non-evolving administrative or honorary badges (SBTs).

**III. AI Oracle & Rule Governance**
*   `submitAIRuleEngineResult(bytes32 _requestId, uint256 _tokenIdOrContentHash, uint256 _score, string memory _newMetadataURI)`: The AI Rule Engine submits a verifiable result for a skill upgrade or content curation request.
*   `proposeAIRuleParameter(bytes32 _paramKey, bytes memory _paramValue)`: Allows users to propose changes to AI rule parameters.
*   `voteOnAIRuleParameterProposal(bytes32 _paramKey, bool _approve)`: AI Validators vote on proposed AI rule parameter changes.
*   `finalizeAIRuleParameter(bytes32 _paramKey)`: Finalizes a parameter change if enough votes are accumulated.
*   `getAIRuleParameter(bytes32 _paramKey)`: Retrieves the current value of an AI rule parameter.

**IV. Decentralized Knowledge Repository**
*   `contributeKnowledge(string memory _contentHash, string memory _ipfsURI, uint256[] memory _relatedSkillTokenIds)`: Users submit content to the repository, linking it to their skills.
*   `requestKnowledgeCuration(bytes32 _contentHash)`: Requests the AI rule engine to curate (evaluate) a submitted knowledge piece.
*   `getKnowledgeDetails(bytes32 _contentHash)`: Retrieves details about a knowledge contribution, including its curation score.
*   `withdrawKnowledgeReward(bytes32 _contentHash)`: Allows the creator of a highly-curated knowledge piece to claim rewards.

**V. Reputation & Validator Staking**
*   `getGlobalReputation(address _user)`: Calculates and returns a user's overall reputation score.
*   `stakeForAIValidator()`: Allows users to stake `_stakingToken` to become an AI Validator.
*   `unstakeFromAIValidator()`: Allows AI Validators to unstake their tokens after a cooldown period.
*   `distributeValidatorRewards()`: Owner/governance distributes accrued rewards to active AI Validators.
*   `withdrawStakingReward()`: Allows AI Validators to withdraw their earned rewards.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Dummy ERC20 for staking and fees - in a real scenario, this would be a separate deployed token
interface IStakingToken {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @title ChronoForge: Dynamic Soulbound Skills & AI-Curated Repositories
 * @author YourName / AI-Powered Contract
 * @notice This contract enables the creation of dynamic, non-transferable Soulbound Skill Tokens (SBTs),
 *         facilitates an AI-curated decentralized knowledge repository, and establishes an on-chain
 *         reputation system. It integrates with an external AI Oracle for dynamic evaluations and
 *         features a simplified DAO for governing AI parameters.
 *
 * @dev Key concepts: Soulbound Tokens (SBTs), Dynamic NFTs, AI Oracle Integration, Decentralized
 *      Knowledge Curation, On-chain Reputation, DAO Governance, AI Model Marketplace (simplified).
 */
contract ChronoForge is Context, Ownable, ReentrancyGuard, IERC721, IERC721Metadata {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // ERC721 Metadata
    string private _name;
    string private _symbol;

    // Token Counters
    Counters.Counter private _tokenIdCounter;

    // Mapping for NFT owner and tokenURI
    mapping(uint256 => address) private _owners;
    mapping(uint256 => string) private _tokenURIs;
    mapping(address => uint256) private _balanceOf; // Required for ERC721

    // Skill Token Data
    struct SkillData {
        string name;
        string currentLevel;
        address owner; // Redundant with _owners, but useful for quick access
        uint256 lastUpgradeTimestamp;
        bool isUpgradable; // Flag if it's an AI-upgradable skill or a static badge
    }
    mapping(uint256 => SkillData) public skills;

    // AI Oracle & Rule Engine
    address public aiRuleEngineAddress;
    uint256 public skillUpgradeFee; // Fee to request an AI evaluation for skill upgrade

    // AI Rule Parameters (for governance)
    struct AIParameterProposal {
        bytes paramValue;
        uint256 upvotes;
        uint256 downvotes;
        mapping(address => bool) hasVoted; // Tracks who has voted
        bool exists; // To check if a proposal is active
    }
    mapping(bytes32 => AIParameterProposal) public aiParameterProposals;
    mapping(bytes32 => bytes) public aiRuleParameters; // Current active parameters

    uint256 public minVotesForAIParamApproval = 3; // Minimum votes for a proposal to pass

    // Knowledge Repository
    struct KnowledgeData {
        address contributor;
        string ipfsURI;
        uint256 submissionTimestamp;
        uint256 curationScore; // 0-100, set by AI
        uint256[] relatedSkillTokenIds;
        bool isCurated;
        bool rewardClaimed;
    }
    mapping(bytes32 => KnowledgeData) public knowledgeRepository; // contentHash -> KnowledgeData
    mapping(bytes32 => address) public knowledgeRequestor; // requestId -> address of who requested curation

    uint256 public constant KNOWLEDGE_REWARD_THRESHOLD = 75; // Min curation score for reward
    uint256 public knowledgeBaseRewardAmount = 1 ether; // Dummy reward amount in staking token

    // Reputation System
    mapping(address => uint256) public globalReputation; // Address -> total reputation points

    // AI Validator Staking
    IStakingToken public stakingToken; // Address of the ERC20 token used for staking
    uint256 public validatorStakeAmount = 100 ether; // Required amount to stake
    uint256 public validatorCooldownPeriod = 7 days; // Cooldown for unstaking

    struct ValidatorData {
        uint256 stakedAmount;
        uint256 rewardsEarned;
        uint256 unstakeRequestTime;
        bool isActive;
    }
    mapping(address => ValidatorData) public aiValidators;

    // Pausability
    bool public paused = false;

    // Contract Upgrade Reference
    address public newContractReference;

    // --- Events ---

    event SkillMinted(uint256 indexed tokenId, address indexed owner, string skillName, string metadataURI);
    event SkillUpgradeRequested(uint256 indexed tokenId, address indexed requestor);
    event SkillMetadataUpdated(uint256 indexed tokenId, string oldURI, string newURI);
    event AIRuleEngineAddressSet(address indexed oldAddress, address indexed newAddress);
    event AIRuleParameterProposed(bytes32 indexed paramKey, bytes paramValue, address indexed proposer);
    event AIRuleParameterVoted(bytes32 indexed paramKey, address indexed voter, bool approved);
    event AIRuleParameterFinalized(bytes32 indexed paramKey, bytes paramValue);
    event AIResultSubmitted(bytes32 indexed requestId, uint256 indexed targetIdOrHash, uint256 score, string newMetadataURI);
    event KnowledgeContributed(bytes32 indexed contentHash, address indexed contributor, string ipfsURI);
    event KnowledgeCurationRequested(bytes32 indexed contentHash, address indexed requestor);
    event KnowledgeRewardClaimed(bytes32 indexed contentHash, address indexed contributor, uint256 amount);
    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstakeRequested(address indexed validator, uint256 amount, uint256 unlockTime);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event ValidatorRewardsClaimed(address indexed validator, uint256 amount);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event NewContractReferenceSet(address indexed newAddress);
    event SkillUpgradeFeeSet(uint256 oldFee, uint256 newFee);


    // --- Modifiers ---

    modifier onlyAIRuleEngine() {
        require(_msgSender() == aiRuleEngineAddress, "ChronoForge: Only AI Rule Engine can call this function");
        _;
    }

    modifier onlyAIValidator() {
        require(aiValidators[_msgSender()].isActive, "ChronoForge: Only active AI Validators can perform this action");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "ChronoForge: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "ChronoForge: Contract is not paused");
        _;
    }

    // --- Constructor ---

    constructor(string memory name_, string memory symbol_, address _stakingTokenAddress) Ownable(_msgSender()) {
        _name = name_;
        _symbol = symbol_;
        stakingToken = IStakingToken(_stakingTokenAddress);
        skillUpgradeFee = 0.01 ether; // Default fee
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @notice Sets the authorized address for the external AI Rule Engine.
     * @dev Only owner can call. This address is crucial for submitting AI evaluation results.
     * @param _newEngine The new address of the AI Rule Engine contract.
     */
    function setAIRuleEngineAddress(address _newEngine) external onlyOwner {
        require(_newEngine != address(0), "ChronoForge: Invalid AI Rule Engine address");
        emit AIRuleEngineAddressSet(aiRuleEngineAddress, _newEngine);
        aiRuleEngineAddress = _newEngine;
    }

    /**
     * @notice Sets the fee required to request an AI-driven skill upgrade.
     * @dev This fee is paid in the staking token. Only owner can call.
     * @param _fee The new fee amount in staking token units.
     */
    function setSkillUpgradeFee(uint256 _fee) external onlyOwner {
        emit SkillUpgradeFeeSet(skillUpgradeFee, _fee);
        skillUpgradeFee = _fee;
    }

    /**
     * @notice Pauses critical contract operations in case of emergency.
     * @dev Only owner can call. Prevents minting, upgrades, contributions, and staking.
     * @param _state True to pause, false to unpause.
     */
    function pauseContractOperations(bool _state) external onlyOwner {
        if (_state) {
            require(!paused, "ChronoForge: Contract already paused");
            paused = true;
            emit ContractPaused(_msgSender());
        } else {
            require(paused, "ChronoForge: Contract already unpaused");
            paused = false;
            emit ContractUnpaused(_msgSender());
        }
    }

    /**
     * @notice Stores a reference to a new contract address for potential future upgrades.
     * @dev This function doesn't perform the upgrade itself (requires a proxy pattern).
     *      It merely stores the address for users/frontend to find the new version.
     * @param _newAddress The address of the new contract.
     */
    function upgradeContractAddress(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "ChronoForge: Invalid new contract address");
        newContractReference = _newAddress;
        emit NewContractReferenceSet(_newAddress);
    }

    // --- II. Soulbound Skill Token (SBT) Management (ERC721-like) ---

    /**
     * @notice Mints a new non-transferable Soulbound Skill Token (SBT) to a recipient.
     * @dev These tokens cannot be transferred. They are tied to the recipient's address.
     *      Increments global reputation for the recipient.
     * @param _recipient The address to mint the SBT to.
     * @param _initialSkillName The initial name of the skill.
     * @param _initialMetadataURI The initial metadata URI for the skill.
     */
    function mintSoulboundSkill(address _recipient, string memory _initialSkillName, string memory _initialMetadataURI)
        external
        whenNotPaused
    {
        require(_recipient != address(0), "ChronoForge: Mint to the zero address");
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _owners[newItemId] = _recipient;
        _balanceOf[_recipient]++;
        _tokenURIs[newItemId] = _initialMetadataURI;

        skills[newItemId] = SkillData({
            name: _initialSkillName,
            currentLevel: "Novice",
            owner: _recipient,
            lastUpgradeTimestamp: block.timestamp,
            isUpgradable: true
        });

        // Update global reputation
        globalReputation[_recipient] += 10; // Base reputation for minting a skill

        emit SkillMinted(newItemId, _recipient, _initialSkillName, _initialMetadataURI);
        emit Transfer(address(0), _recipient, newItemId); // ERC721 compliance
    }

    /**
     * @notice Initiates a request for the AI rule engine to evaluate and potentially upgrade a skill.
     * @dev User must own the skill and pay a fee in staking tokens.
     * @param _tokenId The ID of the Skill SBT to upgrade.
     */
    function requestSkillUpgrade(uint256 _tokenId) external whenNotPaused nonReentrant {
        require(_owners[_tokenId] == _msgSender(), "ChronoForge: Not skill owner");
        require(skills[_tokenId].isUpgradable, "ChronoForge: This skill is not upgradable");
        require(skillUpgradeFee > 0, "ChronoForge: Skill upgrade fee not set or zero");
        require(stakingToken.balanceOf(_msgSender()) >= skillUpgradeFee, "ChronoForge: Insufficient funds for upgrade fee");

        // Transfer fee to contract
        require(stakingToken.transferFrom(_msgSender(), address(this), skillUpgradeFee), "ChronoForge: Fee transfer failed");

        // Generate a request ID (e.g., hash of tokenId and timestamp)
        bytes32 requestId = keccak256(abi.encodePacked(_tokenId, block.timestamp, "skill_upgrade"));
        knowledgeRequestor[requestId] = _msgSender(); // Store requestor for AI result processing

        emit SkillUpgradeRequested(_tokenId, _msgSender());
        // AI Rule Engine will pick this up and call submitAIRuleEngineResult later
    }

    /**
     * @notice Allows governance/owner to directly update an SBT's metadata URI.
     * @dev This might be used in cases where AI output needs manual adjustment or for specific events.
     * @param _tokenId The ID of the Skill SBT.
     * @param _newMetadataURI The new URI for the skill's metadata.
     */
    function updateSkillMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyOwner {
        require(_exists(_tokenId), "ChronoForge: Token ID does not exist");
        string memory oldURI = _tokenURIs[_tokenId];
        _tokenURIs[_tokenId] = _newMetadataURI;
        emit SkillMetadataUpdated(_tokenId, oldURI, _newMetadataURI);
    }

    /**
     * @notice Retrieves all details of a specific Skill SBT.
     * @param _tokenId The ID of the Skill SBT.
     * @return name_ The name of the skill.
     * @return level_ The current level of the skill.
     * @return owner_ The owner's address.
     * @return metadataURI_ The metadata URI.
     * @return lastUpgradeTimestamp_ The timestamp of the last upgrade.
     * @return isUpgradable_ If the skill is eligible for AI-driven upgrades.
     */
    function getSkillDetails(uint256 _tokenId)
        external
        view
        returns (
            string memory name_,
            string memory level_,
            address owner_,
            string memory metadataURI_,
            uint256 lastUpgradeTimestamp_,
            bool isUpgradable_
        )
    {
        require(_exists(_tokenId), "ChronoForge: Token ID does not exist");
        SkillData storage skill = skills[_tokenId];
        return (
            skill.name,
            skill.currentLevel,
            skill.owner,
            _tokenURIs[_tokenId],
            skill.lastUpgradeTimestamp,
            skill.isUpgradable
        );
    }

    /**
     * @notice Allows the owner/governance to mint static, non-evolving administrative or honorary badges.
     * @dev These are also Soulbound but are not subject to AI-driven upgrades.
     * @param _recipient The address to mint the badge to.
     * @param _badgeName The name of the badge.
     * @param _metadataURI The metadata URI for the badge.
     */
    function grantAdminBadge(address _recipient, string memory _badgeName, string memory _metadataURI)
        external
        onlyOwner
        whenNotPaused
    {
        require(_recipient != address(0), "ChronoForge: Mint to the zero address");
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _owners[newItemId] = _recipient;
        _balanceOf[_recipient]++;
        _tokenURIs[newItemId] = _metadataURI;

        skills[newItemId] = SkillData({
            name: _badgeName,
            currentLevel: "Badge",
            owner: _recipient,
            lastUpgradeTimestamp: block.timestamp,
            isUpgradable: false // This badge is not AI-upgradable
        });

        // Update global reputation
        globalReputation[_recipient] += 50; // Higher reputation for an admin-granted badge

        emit SkillMinted(newItemId, _recipient, _badgeName, _metadataURI);
        emit Transfer(address(0), _recipient, newItemId);
    }

    // --- III. AI Oracle & Rule Governance ---

    /**
     * @notice The AI Rule Engine submits a verifiable result for a skill upgrade or content curation request.
     * @dev Only the authorized AI Rule Engine can call this.
     *      It updates skill levels, metadata, or knowledge curation scores.
     * @param _requestId A unique identifier for the request (e.g., hash from `requestSkillUpgrade` or `requestKnowledgeCuration`).
     * @param _targetIdOrHash The tokenId for skill upgrades or contentHash for knowledge curation.
     * @param _score The evaluation score (e.g., 0-100).
     * @param _newMetadataURI The new metadata URI for skills, or updated metadata for knowledge.
     */
    function submitAIRuleEngineResult(
        bytes32 _requestId,
        uint256 _targetIdOrHash,
        uint256 _score,
        string memory _newMetadataURI
    ) external onlyAIRuleEngine whenNotPaused {
        require(knowledgeRequestor[_requestId] != address(0), "ChronoForge: Invalid or expired request ID");

        // Determine if it's a skill upgrade or knowledge curation
        if (_targetIdOrHash > 0 && _exists(_targetIdOrHash) && skills[_targetIdOrHash].owner == knowledgeRequestor[_requestId]) {
            // It's a skill upgrade result
            SkillData storage skill = skills[_targetIdOrHash];
            require(skill.isUpgradable, "ChronoForge: Cannot upgrade a non-upgradable skill");

            skill.currentLevel = _score >= 80 ? "Expert" : (_score >= 50 ? "Proficient" : "Apprentice");
            skill.lastUpgradeTimestamp = block.timestamp;
            _tokenURIs[_targetIdOrHash] = _newMetadataURI;

            // Update global reputation based on skill upgrade
            globalReputation[skill.owner] += _score / 5; // e.g., 16 for an 80 score

            emit SkillMetadataUpdated(_targetIdOrHash, _tokenURIs[_targetIdOrHash], _newMetadataURI);
            emit AIResultSubmitted(_requestId, _targetIdOrHash, _score, _newMetadataURI);

        } else if (knowledgeRepository[bytes32(_targetIdOrHash)].contributor != address(0) && knowledgeRepository[bytes32(_targetIdOrHash)].contributor == knowledgeRequestor[_requestId]) {
            // It's a knowledge curation result
            bytes32 contentHash = bytes32(_targetIdOrHash);
            KnowledgeData storage knowledge = knowledgeRepository[contentHash];
            knowledge.curationScore = _score;
            knowledge.isCurated = true;
            // _newMetadataURI could update the knowledge IPFS URI if needed, but not implemented for simplicity here.

            // Update global reputation for knowledge curation
            globalReputation[knowledge.contributor] += _score / 10; // e.g., 8 for an 80 score

            emit AIResultSubmitted(_requestId, _targetIdOrHash, _score, _newMetadataURI);
        } else {
            revert("ChronoForge: Invalid target for AI result or unauthorized requestor");
        }

        delete knowledgeRequestor[_requestId]; // Mark request as processed
    }

    /**
     * @notice Allows users to propose changes to AI rule parameters.
     * @dev These parameters might dictate thresholds for skill upgrades, curation scores, etc.
     * @param _paramKey A unique identifier (hash) for the parameter being proposed.
     * @param _paramValue The new value for the parameter (can be bytes for flexibility).
     */
    function proposeAIRuleParameter(bytes32 _paramKey, bytes memory _paramValue) external whenNotPaused {
        require(!aiParameterProposals[_paramKey].exists, "ChronoForge: Proposal already exists for this key");

        aiParameterProposals[_paramKey] = AIParameterProposal({
            paramValue: _paramValue,
            upvotes: 0,
            downvotes: 0,
            exists: true
        });
        emit AIRuleParameterProposed(_paramKey, _paramValue, _msgSender());
    }

    /**
     * @notice AI Validators vote on proposed AI rule parameter changes.
     * @dev Only active AI Validators can vote. Each validator can vote once per proposal.
     * @param _paramKey The key of the parameter proposal.
     * @param _approve True for upvote, false for downvote.
     */
    function voteOnAIRuleParameterProposal(bytes32 _paramKey, bool _approve) external onlyAIValidator whenNotPaused {
        AIParameterProposal storage proposal = aiParameterProposals[_paramKey];
        require(proposal.exists, "ChronoForge: Proposal does not exist");
        require(!proposal.hasVoted[_msgSender()], "ChronoForge: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (_approve) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit AIRuleParameterVoted(_paramKey, _msgSender(), _approve);
    }

    /**
     * @notice Finalizes a parameter change if enough upvotes are accumulated.
     * @dev Any user can call this once the vote threshold is met.
     * @param _paramKey The key of the parameter proposal.
     */
    function finalizeAIRuleParameter(bytes32 _paramKey) external whenNotPaused {
        AIParameterProposal storage proposal = aiParameterProposals[_paramKey];
        require(proposal.exists, "ChronoForge: Proposal does not exist");
        require(proposal.upvotes >= minVotesForAIParamApproval, "ChronoForge: Not enough upvotes to finalize");
        require(proposal.upvotes > proposal.downvotes, "ChronoForge: Downvotes outweigh upvotes");

        aiRuleParameters[_paramKey] = proposal.paramValue;
        delete aiParameterProposals[_paramKey]; // Remove proposal after finalization
        emit AIRuleParameterFinalized(_paramKey, aiRuleParameters[_paramKey]);
    }

    /**
     * @notice Retrieves the current value of an active AI rule parameter.
     * @param _paramKey The key of the AI rule parameter.
     * @return The bytes value of the parameter.
     */
    function getAIRuleParameter(bytes32 _paramKey) external view returns (bytes memory) {
        return aiRuleParameters[_paramKey];
    }

    // --- IV. Decentralized Knowledge Repository ---

    /**
     * @notice Allows users to submit content to the knowledge repository, linking it to their skills.
     * @dev Content is identified by a unique content hash and stored off-chain (e.g., IPFS).
     * @param _contentHash A unique hash identifying the content.
     * @param _ipfsURI The IPFS URI where the content is stored.
     * @param _relatedSkillTokenIds An array of Skill SBT IDs related to this content.
     */
    function contributeKnowledge(string memory _contentHash, string memory _ipfsURI, uint256[] memory _relatedSkillTokenIds)
        external
        whenNotPaused
    {
        bytes32 contentHashBytes = keccak256(abi.encodePacked(_contentHash));
        require(knowledgeRepository[contentHashBytes].contributor == address(0), "ChronoForge: Content already contributed");

        knowledgeRepository[contentHashBytes] = KnowledgeData({
            contributor: _msgSender(),
            ipfsURI: _ipfsURI,
            submissionTimestamp: block.timestamp,
            curationScore: 0,
            relatedSkillTokenIds: _relatedSkillTokenIds,
            isCurated: false,
            rewardClaimed: false
        });

        // Update global reputation
        globalReputation[_msgSender()] += 5; // Base reputation for contribution

        emit KnowledgeContributed(contentHashBytes, _msgSender(), _ipfsURI);
    }

    /**
     * @notice Requests the AI rule engine to curate (evaluate) a submitted knowledge piece.
     * @dev Any user can request curation for existing knowledge.
     * @param _contentHash The hash of the knowledge content to be curated.
     */
    function requestKnowledgeCuration(bytes32 _contentHash) external whenNotPaused {
        require(knowledgeRepository[_contentHash].contributor != address(0), "ChronoForge: Knowledge does not exist");
        require(!knowledgeRepository[_contentHash].isCurated, "ChronoForge: Knowledge already curated");

        bytes32 requestId = keccak256(abi.encodePacked(_contentHash, block.timestamp, "knowledge_curation"));
        knowledgeRequestor[requestId] = knowledgeRepository[_contentHash].contributor; // Store original contributor

        emit KnowledgeCurationRequested(_contentHash, _msgSender());
        // AI Rule Engine will pick this up and call submitAIRuleEngineResult later
    }

    /**
     * @notice Retrieves details about a knowledge contribution, including its curation score.
     * @param _contentHash The hash of the knowledge content.
     * @return contributor_ The address of the contributor.
     * @return ipfsURI_ The IPFS URI.
     * @return submissionTimestamp_ The timestamp of submission.
     * @return curationScore_ The AI-assigned curation score.
     * @return isCurated_ True if the content has been curated.
     */
    function getKnowledgeDetails(bytes32 _contentHash)
        external
        view
        returns (
            address contributor_,
            string memory ipfsURI_,
            uint256 submissionTimestamp_,
            uint256 curationScore_,
            bool isCurated_
        )
    {
        KnowledgeData storage knowledge = knowledgeRepository[_contentHash];
        require(knowledge.contributor != address(0), "ChronoForge: Knowledge does not exist");
        return (
            knowledge.contributor,
            knowledge.ipfsURI,
            knowledge.submissionTimestamp,
            knowledge.curationScore,
            knowledge.isCurated
        );
    }

    /**
     * @notice Allows the creator of a highly-curated knowledge piece to claim rewards.
     * @dev Requires the content to be curated above a certain score and rewards not yet claimed.
     * @param _contentHash The hash of the knowledge content.
     */
    function withdrawKnowledgeReward(bytes32 _contentHash) external whenNotPaused nonReentrant {
        KnowledgeData storage knowledge = knowledgeRepository[_contentHash];
        require(knowledge.contributor == _msgSender(), "ChronoForge: Not the contributor of this knowledge");
        require(knowledge.isCurated, "ChronoForge: Knowledge has not been curated yet");
        require(knowledge.curationScore >= KNOWLEDGE_REWARD_THRESHOLD, "ChronoForge: Curation score too low for reward");
        require(!knowledge.rewardClaimed, "ChronoForge: Reward already claimed");
        require(stakingToken.balanceOf(address(this)) >= knowledgeBaseRewardAmount, "ChronoForge: Insufficient contract balance for reward");

        knowledge.rewardClaimed = true;
        require(stakingToken.transfer(_msgSender(), knowledgeBaseRewardAmount), "ChronoForge: Reward transfer failed");

        // Update global reputation for successful reward claim
        globalReputation[_msgSender()] += 20;

        emit KnowledgeRewardClaimed(_contentHash, _msgSender(), knowledgeBaseRewardAmount);
    }

    // --- V. Reputation & Validator Staking ---

    /**
     * @notice Calculates and returns a user's overall reputation score.
     * @dev This is a simplified calculation for demonstration. In reality, it would be more complex.
     * @param _user The address of the user.
     * @return The aggregated reputation score.
     */
    function getGlobalReputation(address _user) public view returns (uint256) {
        // Base reputation is directly tracked, but could be enhanced with skill levels, etc.
        uint256 totalReputation = globalReputation[_user];

        // Add reputation based on validator status
        if (aiValidators[_user].isActive) {
            totalReputation += 50; // Bonus for being an active validator
        }

        // Could also iterate through owned skills and add points based on skill levels.
        // For simplicity and gas, we rely on event-driven updates to globalReputation.

        return totalReputation;
    }

    /**
     * @notice Allows users to stake `_stakingToken` to become an AI Validator.
     * @dev Requires a minimum stake amount.
     */
    function stakeForAIValidator() external whenNotPaused nonReentrant {
        require(!aiValidators[_msgSender()].isActive, "ChronoForge: Already an active AI Validator");
        require(stakingToken.balanceOf(_msgSender()) >= validatorStakeAmount, "ChronoForge: Insufficient staking token balance");
        require(stakingToken.transferFrom(_msgSender(), address(this), validatorStakeAmount), "ChronoForge: Staking token transfer failed");

        aiValidators[_msgSender()] = ValidatorData({
            stakedAmount: validatorStakeAmount,
            rewardsEarned: 0,
            unstakeRequestTime: 0,
            isActive: true
        });

        // Update global reputation
        globalReputation[_msgSender()] += 100; // Significant boost for becoming a validator

        emit ValidatorStaked(_msgSender(), validatorStakeAmount);
    }

    /**
     * @notice Allows AI Validators to request to unstake their tokens after a cooldown period.
     * @dev Initiates the cooldown period.
     */
    function unstakeFromAIValidator() external whenNotPaused nonReentrant {
        ValidatorData storage validator = aiValidators[_msgSender()];
        require(validator.isActive, "ChronoForge: Not an active AI Validator");
        require(validator.unstakeRequestTime == 0, "ChronoForge: Unstake already requested");

        validator.isActive = false; // Immediately deactivate for voting purposes
        validator.unstakeRequestTime = block.timestamp;

        // Decrease global reputation
        globalReputation[_msgSender()] -= 100; // Deduct boost for validator status

        emit ValidatorUnstakeRequested(_msgSender(), validator.stakedAmount, block.timestamp + validatorCooldownPeriod);
    }

    /**
     * @notice Allows an AI Validator to withdraw their staked tokens after the cooldown period.
     * @dev Can only be called after the `validatorCooldownPeriod` has passed since `unstakeFromAIValidator`.
     */
    function withdrawStakingReward() external whenNotPaused nonReentrant {
        ValidatorData storage validator = aiValidators[_msgSender()];
        require(validator.stakedAmount > 0, "ChronoForge: No staked amount to withdraw");
        require(validator.unstakeRequestTime != 0, "ChronoForge: Unstake not requested or already processed");
        require(block.timestamp >= validator.unstakeRequestTime + validatorCooldownPeriod, "ChronoForge: Cooldown period not over");
        require(stakingToken.balanceOf(address(this)) >= validator.stakedAmount + validator.rewardsEarned, "ChronoForge: Contract balance too low for withdrawal");


        uint256 totalAmount = validator.stakedAmount + validator.rewardsEarned;
        validator.stakedAmount = 0;
        validator.rewardsEarned = 0;
        validator.unstakeRequestTime = 0;

        require(stakingToken.transfer(_msgSender(), totalAmount), "ChronoForge: Staking withdrawal failed");

        emit ValidatorUnstaked(_msgSender(), totalAmount);
    }

    /**
     * @notice Distributes accrued rewards to active AI Validators.
     * @dev This is a simplified distribution (e.g., owner distributes from a pool).
     *      In a full system, rewards would accumulate from protocol fees and be distributed programmatically.
     * @param _amount The total amount of rewards to be distributed.
     * @param _recipients The addresses of the validators receiving rewards.
     * @param _rewardPerValidator An array specifying rewards for each recipient.
     */
    function distributeValidatorRewards(uint256 _amount, address[] memory _recipients, uint256[] memory _rewardPerValidator)
        external
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        require(_recipients.length == _rewardPerValidator.length, "ChronoForge: Mismatched array lengths");
        require(stakingToken.balanceOf(address(this)) >= _amount, "ChronoForge: Insufficient contract balance for rewards");

        uint256 totalDistributed = 0;
        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 reward = _rewardPerValidator[i];

            require(aiValidators[recipient].isActive, "ChronoForge: Recipient is not an active validator");
            aiValidators[recipient].rewardsEarned += reward;
            totalDistributed += reward;

            // Update global reputation
            globalReputation[recipient] += (reward / 1 ether); // Simple conversion to reputation points

            emit ValidatorRewardsClaimed(recipient, reward);
        }
        require(totalDistributed == _amount, "ChronoForge: Total distributed amount does not match specified amount");
    }

    // --- ERC721 Compliance (Soulbound - no transfer) ---

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balanceOf[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    // Override transfers to make tokens Soulbound (non-transferable)
    function approve(address to, uint256 tokenId) public pure override {
        revert("ChronoForge: Soulbound Tokens are not transferable or approvable");
    }

    function getApproved(uint256 tokenId) public pure override returns (address) {
        revert("ChronoForge: Soulbound Tokens are not transferable or approvable");
    }

    function setApprovalForAll(address operator, bool approved) public pure override {
        revert("ChronoForge: Soulbound Tokens are not transferable or approvable");
    }

    function isApprovedForAll(address owner, address operator) public pure override returns (bool) {
        revert("ChronoForge: Soulbound Tokens are not transferable or approvable");
    }

    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ChronoForge: Soulbound Tokens are not transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("ChronoForge: Soulbound Tokens are not transferable");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("ChronoForge: Soulbound Tokens are not transferable");
    }
}
```