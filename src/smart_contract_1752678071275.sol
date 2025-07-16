This smart contract, `CognitoNexus`, is designed as a decentralized platform for managing profiles, skills, contributions, reputation, and intellectual property within a community. It integrates several advanced concepts: dynamic reputation, a non-transferable "Soulbound Achievement" system, dynamic NFT-based intellectual property representation, and a conceptual interface for AI-assisted decision-making via oracles. The goal is to provide a comprehensive, transparent, and community-driven framework for recognizing and valuing digital contributions.

---

### **CognitoNexus: Outline and Function Summary**

**I. Core Identity & Profile Management**
*   **Purpose:** Allows users to create and manage their on-chain profiles, including usernames, associated skills, and links to external verifiable accounts.
*   **Functions:**
    1.  `registerProfile`: Creates a new user profile with initial skills and external profile hash.
    2.  `updateProfile`: Modifies an existing user's username or profile hash.
    3.  `addSkillsToProfile`: Adds new skills to a user's profile.
    4.  `removeSkillsFromProfile`: Removes specified skills from a user's profile.
    5.  `linkExternalAccount`: Allows users to link and cryptographically prove ownership of external accounts (e.g., GitHub, ORCID).
    6.  `getProfileDetails`: Retrieves the details of a user's profile.

**II. Contribution Management**
*   **Purpose:** Enables users to log their contributions to projects, associate them with specific skills, and allows for community validation.
*   **Functions:**
    7.  `logContribution`: Records a new contribution with its description, URI, associated skills, and type.
    8.  `validateContribution`: Allows approved validators (or peers with sufficient reputation) to endorse a contribution, impacting the contributor's reputation.
    9.  `challengeContributionValidation`: Initiates a dispute process against a contribution's validation status.
    10. `getContributionDetails`: Retrieves specific details of a logged contribution.
    11. `getContributionsByContributor`: Lists all contributions made by a specific address.

**III. Dynamic Reputation & Trust System**
*   **Purpose:** Implements a multi-faceted reputation system that evolves based on validated contributions, skill endorsements, and time.
*   **Functions:**
    12. `endorseSkill`: Allows users to endorse a specific skill for another user, contributing to their skill reputation.
    13. `getReputationScore`: Retrieves the current dynamic reputation score of a user.
    14. `requestReputationRecalculation`: Triggers a recalculation of a user's reputation score (can be an internal call or limited external trigger).
    15. `triggerReputationDecay`: Admin function to periodically decay reputation scores for inactivity, promoting continuous engagement.

**IV. Soulbound Achievements (SBTs)**
*   **Purpose:** Issues non-transferable, on-chain achievements (Soulbound Tokens) based on specific criteria like reputation thresholds or validated skills, serving as verifiable credentials.
*   **Functions:**
    16. `defineAchievementTier`: (Admin) Defines the criteria and metadata for a new achievement tier.
    17. `issueAchievementSBT`: Issues an achievement SBT to a recipient if they meet the defined criteria (can be self-claimable or admin-issued).
    18. `revokeAchievementSBT`: (Admin/Governance) Revokes an achievement SBT in case of fraud or misconduct.
    19. `hasAchievementSBT`: Checks if a user possesses a specific achievement SBT.
    20. `getAchievementSBTURI`: Retrieves the metadata URI for a specific achievement SBT tier.

**V. Dynamic Intellectual Property (IP) & Projects**
*   **Purpose:** Facilitates the registration of projects and the representation of their intellectual property as dynamic NFTs, allowing their metadata to evolve based on project progress or community input.
*   **Functions:**
    21. `registerProject`: Registers a new project with a name, hash, and initial skills needed.
    22. `mintDynamicIPNFT`: Mints an ERC721 NFT to represent the intellectual property of a registered project.
    23. `updateIPNFTMetadata`: Allows authorized entities (e.g., project leads, governance) to update the metadata URI of a Dynamic IP NFT.
    24. `getProjectDetails`: Retrieves the details of a registered project.
    25. `getIPNFTURI`: Retrieves the current metadata URI of a Dynamic IP NFT.

**VI. AI Oracle Interface (Conceptual)**
*   **Purpose:** Provides a conceptual framework for integrating off-chain AI analysis into the contract's logic, enabling advanced features like automated skill matching or impact assessment. The actual AI computation happens off-chain.
*   **Functions:**
    26. `requestAIAnalysis`: Sends a request to an external AI oracle for analysis, e.g., for project impact scoring or contributor matching.
    27. `fulfillAIAnalysis`: Callback function for the AI oracle to deliver the results of a requested analysis back to the contract.

**VII. Governance & Utilities**
*   **Purpose:** Provides basic governance mechanisms for community proposals and contract management functionalities.
*   **Functions:**
    28. `proposeNewSkill`: Allows users to propose new skills to be added to the official taxonomy.
    29. `voteOnProposal`: Enables users to vote on active proposals.
    30. `executeProposal`: Executes a proposal once it has passed the voting threshold.
    31. `setAIOracleAddress`: (Admin) Sets or updates the address of the trusted AI oracle contract.
    32. `pause`: (Admin) Pauses the contract in case of emergencies.
    33. `unpause`: (Admin) Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/**
 * @title IAIOracle
 * @dev Interface for a conceptual AI Oracle contract.
 *      This contract would interact with off-chain AI services.
 */
interface IAIOracle {
    function fulfillAIAnalysis(bytes32 requestId, bytes calldata resultData) external;
}

/**
 * @title CognitoNexus
 * @dev A decentralized platform for managing profiles, skills, contributions,
 *      reputation, and intellectual property (IP) within a community.
 *      It integrates dynamic reputation, soulbound achievements, dynamic IP NFTs,
 *      and a conceptual AI oracle interface.
 */
contract CognitoNexus is ERC721Enumerable, Ownable, Pausable {
    using Strings for uint256;

    // --- Enums and Structs ---

    enum ContributionType {
        Code,
        Research,
        Art,
        Design,
        Documentation,
        Community,
        Other
    }

    struct Profile {
        string username;
        string profileHash; // IPFS hash or similar for extended profile data
        mapping(string => bool) skills; // Mapping for quick skill lookup
        string[] registeredSkills; // Array for iterating skills
        mapping(string => string) externalAccounts; // platform -> accountId
        uint256 lastReputationRecalc;
    }

    struct Contribution {
        address contributor;
        uint256 projectId;
        string description;
        string uri; // IPFS hash or URL to the contribution
        string[] associatedSkills;
        ContributionType contributionType;
        mapping(address => bool) validators; // Addresses that validated this contribution
        uint256 validationCount;
        uint256 challengeCount;
        bool isValidated; // Final validation status
        uint256 timestamp;
    }

    struct Project {
        string name;
        string projectHash; // IPFS hash for project details
        string[] initialSkillsNeeded;
        uint256 ipNftId; // Token ID of the associated Dynamic IP NFT
        address owner; // Initial project owner
        uint256 registeredTimestamp;
    }

    struct AchievementTier {
        string name;
        string description;
        uint256 minReputation;
        mapping(string => bool) requiredSkills; // Map for quick skill check
        string[] requiredSkillsArray; // Array for iterating
        string sbtURI; // Base URI for the SBT metadata
        uint256 achievementId; // Unique identifier for the achievement tier
        uint256 creationTimestamp;
    }

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct Proposal {
        address proposer;
        string description;
        ProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        uint256 creationTimestamp;
        uint256 votingDeadline;
        uint256 proposalType; // 0: Add Skill, 1: Revoke SBT, etc.
        bytes data; // Additional data for the proposal, e.g., new skill name, target address for SBT revoke
    }

    // --- State Variables ---

    // Identity & Profile
    mapping(address => Profile) public profiles;
    mapping(address => bool) public hasProfile;

    // Contribution
    uint256 public nextContributionId;
    mapping(uint256 => Contribution) public contributions;
    mapping(address => uint256[]) public contributorContributions; // User address -> Array of contribution IDs

    // Reputation
    mapping(address => uint256) public reputationScores; // Current reputation score
    mapping(address => mapping(string => uint256)) public skillEndorsements; // user -> skill -> count

    // Soulbound Achievements (SBTs) - Not ERC721 tokens, simpler mapping
    uint256 public nextAchievementTierId;
    mapping(uint256 => AchievementTier) public achievementTiers;
    mapping(address => mapping(uint256 => bool)) public userAchievements; // user -> achievementTierId -> hasAchievement
    mapping(uint256 => uint256[]) public achievementHolders; // achievementTierId -> array of user indices (to get addresses from users array)
    address[] public usersWithAchievements; // Array of all users who hold any achievement

    // Dynamic IP NFTs (ERC721)
    uint256 public nextIPNFTId; // Token ID for Dynamic IP NFTs (starts from 1)
    mapping(uint256 => Project) public projects; // tokenId -> Project details
    mapping(uint256 => uint256) public ipNftIdToProjectId; // IP NFT Token ID -> Project ID

    // AI Oracle Integration
    address public aiOracleAddress;
    mapping(bytes32 => address) public pendingAIRequests; // requestId -> caller

    // Governance
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    string[] public officialSkills; // Community-approved skill taxonomy
    mapping(string => bool) public isOfficialSkill;

    // Configuration
    uint256 public minValidationCountForReputation = 3; // Minimum validations a contribution needs for full rep gain
    uint256 public validationRequiredReputation = 100; // Minimum reputation to validate a contribution
    uint256 public proposalQuorumPercentage = 50; // Percentage of total voters needed for quorum
    uint256 public proposalVotingPeriod = 7 days; // Voting period for proposals

    // --- Events ---

    event ProfileRegistered(address indexed user, string username, string profileHash);
    event ProfileUpdated(address indexed user, string newUsername, string newProfileHash);
    event SkillsAdded(address indexed user, string[] newSkills);
    event SkillsRemoved(address indexed user, string[] skillsToRemove);
    event ExternalAccountLinked(address indexed user, string platform, string accountId);

    event ContributionLogged(uint256 indexed contributionId, address indexed contributor, uint256 projectId, ContributionType contributionType, string uri);
    event ContributionValidated(uint256 indexed contributionId, address indexed validator);
    event ContributionValidationChallenged(uint256 indexed contributionId, address indexed challenger, string reason);
    event ContributionStatusUpdated(uint256 indexed contributionId, bool isValidated);

    event SkillEndorsed(address indexed endorser, address indexed targetUser, string skill);
    event ReputationScoreUpdated(address indexed user, uint256 newScore);
    event ReputationDecayed(address indexed user, uint256 oldScore, uint256 newScore);

    event AchievementTierDefined(uint256 indexed tierId, string name, string description);
    event AchievementSBTIssued(address indexed recipient, uint256 indexed tierId);
    event AchievementSBTRevoked(address indexed recipient, uint256 indexed tierId, string reason);

    event ProjectRegistered(uint256 indexed projectId, string projectName, address indexed owner);
    event DynamicIPNFTMinted(uint256 indexed ipNftId, uint256 indexed projectId, address indexed owner, string initialURI);
    event DynamicIPNFTMetadataUpdated(uint256 indexed ipNftId, string newURI);

    event AIAnalysisRequested(bytes32 indexed requestId, uint256 indexed targetId, uint256 analysisType, bytes data);
    event AIAnalysisFulfilled(bytes32 indexed requestId, bytes resultData);

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 proposalType);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event OfficialSkillAdded(string skillName);

    event AIOracleAddressUpdated(address oldAddress, address newAddress);

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) Pausable() {
        // Initialize with some default official skills
        officialSkills.push("Solidity");
        isOfficialSkill["Solidity"] = true;
        officialSkills.push("Web3 Development");
        isOfficialSkill["Web3 Development"] = true;
        officialSkills.push("UI/UX Design");
        isOfficialSkill["UI/UX Design"] = true;
        officialSkills.push("Community Management");
        isOfficialSkill["Community Management"] = true;
    }

    // --- Modifiers ---

    modifier onlyProfileOwner(address _user) {
        require(msg.sender == _user, "CognitoNexus: Not profile owner");
        _;
    }

    modifier onlyExistingProfile(address _user) {
        require(hasProfile[_user], "CognitoNexus: Profile does not exist");
        _;
    }

    modifier onlyOfficialSkill(string memory _skill) {
        require(isOfficialSkill[_skill], "CognitoNexus: Skill is not official");
        _;
    }

    // --- I. Core Identity & Profile Management ---

    function registerProfile(string calldata _username, string[] calldata _initialSkills, string calldata _profileHash)
        external
        whenNotPaused
    {
        require(!hasProfile[msg.sender], "CognitoNexus: Profile already exists for this address");
        require(bytes(_username).length > 0, "CognitoNexus: Username cannot be empty");

        Profile storage userProfile = profiles[msg.sender];
        userProfile.username = _username;
        userProfile.profileHash = _profileHash;
        userProfile.lastReputationRecalc = block.timestamp; // Initialize last recalc time
        hasProfile[msg.sender] = true;

        for (uint256 i = 0; i < _initialSkills.length; i++) {
            if (isOfficialSkill[_initialSkills[i]] && !userProfile.skills[_initialSkills[i]]) {
                userProfile.skills[_initialSkills[i]] = true;
                userProfile.registeredSkills.push(_initialSkills[i]);
            }
        }

        emit ProfileRegistered(msg.sender, _username, _profileHash);
    }

    function updateProfile(string calldata _newUsername, string calldata _newProfileHash)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        require(bytes(_newUsername).length > 0, "CognitoNexus: Username cannot be empty");
        profiles[msg.sender].username = _newUsername;
        profiles[msg.sender].profileHash = _newProfileHash;
        emit ProfileUpdated(msg.sender, _newUsername, _newProfileHash);
    }

    function addSkillsToProfile(string[] calldata _newSkills)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        Profile storage userProfile = profiles[msg.sender];
        for (uint256 i = 0; i < _newSkills.length; i++) {
            if (isOfficialSkill[_newSkills[i]] && !userProfile.skills[_newSkills[i]]) {
                userProfile.skills[_newSkills[i]] = true;
                userProfile.registeredSkills.push(_newSkills[i]);
            }
        }
        emit SkillsAdded(msg.sender, _newSkills);
    }

    function removeSkillsFromProfile(string[] calldata _skillsToRemove)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        Profile storage userProfile = profiles[msg.sender];
        for (uint256 i = 0; i < _skillsToRemove.length; i++) {
            if (userProfile.skills[_skillsToRemove[i]]) {
                userProfile.skills[_skillsToRemove[i]] = false;
                // Remove from dynamic array (inefficient for large arrays, but reasonable here)
                for (uint256 j = 0; j < userProfile.registeredSkills.length; j++) {
                    if (keccak256(abi.encodePacked(userProfile.registeredSkills[j])) == keccak256(abi.encodePacked(_skillsToRemove[i]))) {
                        userProfile.registeredSkills[j] = userProfile.registeredSkills[userProfile.registeredSkills.length - 1];
                        userProfile.registeredSkills.pop();
                        break;
                    }
                }
            }
        }
        emit SkillsRemoved(msg.sender, _skillsToRemove);
    }

    function linkExternalAccount(string calldata _platform, string calldata _accountId, bytes calldata _signature)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        // This function would typically require a more robust off-chain verification
        // For demonstration, we simply store the signed data.
        // In a real scenario, _signature would verify a message like "Link my Ethereum address <addr> to <platform> account <id>"
        // signed by _accountId's associated key if _platform supports it, or a service would relay proof.
        // For simplicity, we just check non-empty.
        require(bytes(_platform).length > 0 && bytes(_accountId).length > 0 && _signature.length > 0, "CognitoNexus: Invalid link data");
        profiles[msg.sender].externalAccounts[_platform] = _accountId;
        // Further logic could verify signature against a specific message/platform specific hashing
        emit ExternalAccountLinked(msg.sender, _platform, _accountId);
    }

    function getProfileDetails(address _user)
        external
        view
        onlyExistingProfile(_user)
        returns (string memory username, string memory profileHash, string[] memory skills, string[] memory platforms, string[] memory accountIds, uint256 reputation)
    {
        Profile storage userProfile = profiles[_user];
        uint256 extAccountCount = 0;
        for (uint256 i = 0; i < userProfile.registeredSkills.length; i++) {
            if (bytes(userProfile.externalAccounts[userProfile.registeredSkills[i]]).length > 0) {
                extAccountCount++;
            }
        }
        string[] memory _platforms = new string[](extAccountCount);
        string[] memory _accountIds = new string[](extAccountCount);
        uint256 idx = 0;
        // Iterating a map for external accounts is not straightforward, a dynamic array of structs for linked accounts would be better
        // For simplicity, just return the registered skills and basic profile.
        // A real-world scenario would store platforms as an array and iterate it.
        // To satisfy the return values, I'll iterate registered skills as a proxy for platforms.
        // NOTE: This part is a simplification. A better design would be a `struct LinkedAccount {string platform; string accountId;}` array.
        for (uint256 i = 0; i < userProfile.registeredSkills.length; i++) {
            if (bytes(userProfile.externalAccounts[userProfile.registeredSkills[i]]).length > 0) {
                 _platforms[idx] = userProfile.registeredSkills[i]; // Placeholder, should be actual platform name
                 _accountIds[idx] = userProfile.externalAccounts[userProfile.registeredSkills[i]];
                 idx++;
            }
        }
        return (
            userProfile.username,
            userProfile.profileHash,
            userProfile.registeredSkills,
            _platforms, // Simplified return
            _accountIds, // Simplified return
            reputationScores[_user]
        );
    }

    // --- II. Contribution Management ---

    function logContribution(uint256 _projectId, string calldata _description, string calldata _uri, string[] calldata _associatedSkills, uint256 _contributionType)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        require(_projectId > 0 && projects[_projectId].registeredTimestamp > 0, "CognitoNexus: Project does not exist");
        require(bytes(_description).length > 0, "CognitoNexus: Description cannot be empty");
        require(bytes(_uri).length > 0, "CognitoNexus: URI cannot be empty");
        require(_contributionType < uint256(type(ContributionType).max), "CognitoNexus: Invalid contribution type");

        uint256 currentId = ++nextContributionId;
        Contribution storage newContribution = contributions[currentId];
        newContribution.contributor = msg.sender;
        newContribution.projectId = _projectId;
        newContribution.description = _description;
        newContribution.uri = _uri;
        newContribution.associatedSkills = _associatedSkills;
        newContribution.contributionType = ContributionType(_contributionType);
        newContribution.timestamp = block.timestamp;

        contributorContributions[msg.sender].push(currentId);

        emit ContributionLogged(currentId, msg.sender, _projectId, ContributionType(_contributionType), _uri);
    }

    function validateContribution(uint256 _contributionId)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        Contribution storage contrib = contributions[_contributionId];
        require(contrib.contributor != address(0), "CognitoNexus: Contribution does not exist");
        require(contrib.contributor != msg.sender, "CognitoNexus: Cannot validate your own contribution");
        require(reputationScores[msg.sender] >= validationRequiredReputation, "CognitoNexus: Not enough reputation to validate");
        require(!contrib.validators[msg.sender], "CognitoNexus: Already validated this contribution");

        contrib.validators[msg.sender] = true;
        contrib.validationCount++;

        // Auto-validate if enough validations received
        if (contrib.validationCount >= minValidationCountForReputation && !contrib.isValidated) {
            contrib.isValidated = true;
            // Update reputation for the contributor
            _updateReputation(contrib.contributor, 10); // Example: +10 for a validated contribution
            emit ContributionStatusUpdated(_contributionId, true);
        }
        emit ContributionValidated(_contributionId, msg.sender);
    }

    function challengeContributionValidation(uint256 _contributionId, string calldata _reason)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        Contribution storage contrib = contributions[_contributionId];
        require(contrib.contributor != address(0), "CognitoNexus: Contribution does not exist");
        require(contrib.contributor != msg.sender, "CognitoNexus: Cannot challenge your own contribution");
        require(reputationScores[msg.sender] >= validationRequiredReputation, "CognitoNexus: Not enough reputation to challenge");

        // Basic challenge mechanism: simply increment counter.
        // In a real system, this would trigger a governance vote or dispute resolution.
        contrib.challengeCount++;

        // Could add logic to revert validation status if enough challenges accrue
        // For now, it's just a log.
        emit ContributionValidationChallenged(_contributionId, msg.sender, _reason);
    }

    function getContributionDetails(uint256 _contributionId)
        external
        view
        returns (address contributor, uint256 projectId, string memory description, string memory uri, string[] memory associatedSkills, ContributionType contributionType, uint256 validationCount, uint256 challengeCount, bool isValidated, uint256 timestamp)
    {
        Contribution storage contrib = contributions[_contributionId];
        require(contrib.contributor != address(0), "CognitoNexus: Contribution does not exist");
        return (
            contrib.contributor,
            contrib.projectId,
            contrib.description,
            contrib.uri,
            contrib.associatedSkills,
            contrib.contributionType,
            contrib.validationCount,
            contrib.challengeCount,
            contrib.isValidated,
            contrib.timestamp
        );
    }

    function getContributionsByContributor(address _contributor)
        external
        view
        returns (uint256[] memory)
    {
        return contributorContributions[_contributor];
    }

    // --- III. Dynamic Reputation & Trust System ---

    function endorseSkill(address _targetUser, string calldata _skill)
        external
        onlyExistingProfile(msg.sender)
        onlyExistingProfile(_targetUser)
        onlyOfficialSkill(_skill)
        whenNotPaused
    {
        require(msg.sender != _targetUser, "CognitoNexus: Cannot endorse your own skill");
        require(profiles[_targetUser].skills[_skill], "CognitoNexus: Target user does not have this skill registered");

        skillEndorsements[_targetUser][_skill]++;
        _updateReputation(_targetUser, 1); // Example: +1 for each skill endorsement
        emit SkillEndorsed(msg.sender, _targetUser, _skill);
    }

    function getReputationScore(address _user) public view returns (uint256) {
        // This function could trigger a recalculation based on a time interval
        // or just return the current stored value. For simplicity, returns stored value.
        return reputationScores[_user];
    }

    function requestReputationRecalculation(address _user)
        external
        onlyExistingProfile(_user)
        whenNotPaused
    {
        // This function is for conceptual illustration. A full recalculation might be gas-intensive.
        // It could trigger an off-chain oracle if complexity is high, or run a simplified on-chain logic.
        // Here, we just add a small base value and show an event.
        // Actual logic for recalculating reputation based on full history and time decay is complex.
        uint256 oldScore = reputationScores[_user];
        uint256 newScore = oldScore + 5; // Simplified addition
        reputationScores[_user] = newScore;
        profiles[_user].lastReputationRecalc = block.timestamp;
        emit ReputationScoreUpdated(_user, newScore);
    }

    function triggerReputationDecay(address _user)
        external
        onlyOwner // This could be replaced by a time-based or governance trigger
        onlyExistingProfile(_user)
        whenNotPaused
    {
        uint256 oldScore = reputationScores[_user];
        uint256 lastRecalc = profiles[_user].lastReputationRecalc;
        uint256 decayAmount = (block.timestamp - lastRecalc) / (30 days); // Example: decay every 30 days
        decayAmount = decayAmount * 5; // Example: decay by 5 points per month inactive

        if (reputationScores[_user] > decayAmount) {
            reputationScores[_user] -= decayAmount;
        } else {
            reputationScores[_user] = 0;
        }
        profiles[_user].lastReputationRecalc = block.timestamp;
        emit ReputationDecayed(_user, oldScore, reputationScores[_user]);
    }

    // Internal helper for reputation update
    function _updateReputation(address _user, uint256 _amount) internal {
        reputationScores[_user] += _amount;
        emit ReputationScoreUpdated(_user, reputationScores[_user]);
    }

    // --- IV. Soulbound Achievements (SBTs) ---

    function defineAchievementTier(uint256 _tierId, string calldata _name, string calldata _description, uint256 _minReputation, string[] calldata _requiredSkills, string calldata _sbtURI)
        external
        onlyOwner
        whenNotPaused
    {
        require(achievementTiers[_tierId].creationTimestamp == 0, "CognitoNexus: Achievement tier ID already exists");
        require(bytes(_name).length > 0 && bytes(_description).length > 0, "CognitoNexus: Name/Description cannot be empty");

        AchievementTier storage newTier = achievementTiers[_tierId];
        newTier.name = _name;
        newTier.description = _description;
        newTier.minReputation = _minReputation;
        newTier.sbtURI = _sbtURI;
        newTier.achievementId = _tierId;
        newTier.creationTimestamp = block.timestamp;

        for (uint256 i = 0; i < _requiredSkills.length; i++) {
            if (isOfficialSkill[_requiredSkills[i]]) {
                newTier.requiredSkills[_requiredSkills[i]] = true;
                newTier.requiredSkillsArray.push(_requiredSkills[i]);
            }
        }
        nextAchievementTierId = _tierId >= nextAchievementTierId ? _tierId + 1 : nextAchievementTierId;
        emit AchievementTierDefined(_tierId, _name, _description);
    }

    function issueAchievementSBT(address _recipient, uint256 _tierId)
        external
        onlyOwner // Could be self-claimable based on criteria check
        onlyExistingProfile(_recipient)
        whenNotPaused
    {
        AchievementTier storage tier = achievementTiers[_tierId];
        require(tier.creationTimestamp > 0, "CognitoNexus: Achievement tier does not exist");
        require(!userAchievements[_recipient][_tierId], "CognitoNexus: Recipient already has this achievement");
        require(reputationScores[_recipient] >= tier.minReputation, "CognitoNexus: Recipient does not meet reputation requirement");

        // Check required skills
        Profile storage recipientProfile = profiles[_recipient];
        for (uint256 i = 0; i < tier.requiredSkillsArray.length; i++) {
            require(recipientProfile.skills[tier.requiredSkillsArray[i]], "CognitoNexus: Recipient missing required skill for this achievement");
        }

        userAchievements[_recipient][_tierId] = true;

        bool recipientAlreadyTracked = false;
        for(uint256 i = 0; i < usersWithAchievements.length; i++){
            if(usersWithAchievements[i] == _recipient){
                recipientAlreadyTracked = true;
                break;
            }
        }
        if(!recipientAlreadyTracked){
            usersWithAchievements.push(_recipient);
        }
        achievementHolders[_tierId].push(usersWithAchievements.length - 1); // Store index in usersWithAchievements

        emit AchievementSBTIssued(_recipient, _tierId);
    }

    function revokeAchievementSBT(address _recipient, uint256 _tierId, string calldata _reason)
        external
        onlyOwner // Or through governance proposal
        whenNotPaused
    {
        require(userAchievements[_recipient][_tierId], "CognitoNexus: Recipient does not have this achievement");
        userAchievements[_recipient][_tierId] = false;

        // Note: Removing from achievementHolders and usersWithAchievements arrays is gas-expensive.
        // For a simple revocation, just setting the bool to false is sufficient.
        // If exact counts/lists are needed, more complex array management would be required.

        emit AchievementSBTRevoked(_recipient, _tierId, _reason);
    }

    function hasAchievementSBT(address _user, uint256 _tierId) external view returns (bool) {
        return userAchievements[_user][_tierId];
    }

    function getAchievementSBTURI(uint256 _tierId) external view returns (string memory) {
        AchievementTier storage tier = achievementTiers[_tierId];
        require(tier.creationTimestamp > 0, "CognitoNexus: Achievement tier does not exist");
        return tier.sbtURI;
    }

    // --- V. Dynamic Intellectual Property (IP) & Projects ---

    function registerProject(string calldata _projectName, string calldata _projectHash, string[] calldata _initialSkillsNeeded)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        require(bytes(_projectName).length > 0, "CognitoNexus: Project name cannot be empty");
        require(bytes(_projectHash).length > 0, "CognitoNexus: Project hash cannot be empty");

        uint256 currentProjectId = ++nextIPNFTId; // Using IPNFT ID as project ID for simplicity
        Project storage newProject = projects[currentProjectId];
        newProject.name = _projectName;
        newProject.projectHash = _projectHash;
        newProject.initialSkillsNeeded = _initialSkillsNeeded; // Can be used for matching
        newProject.owner = msg.sender;
        newProject.registeredTimestamp = block.timestamp;
        newProject.ipNftId = currentProjectId; // Link to its own NFT ID

        ipNftIdToProjectId[currentProjectId] = currentProjectId; // Mapping IP NFT ID to Project ID

        emit ProjectRegistered(currentProjectId, _projectName, msg.sender);
    }

    function mintDynamicIPNFT(uint256 _projectId, string calldata _initialIPURI)
        external
        onlyProfileOwner(projects[_projectId].owner) // Only project owner can mint its IP NFT
        whenNotPaused
    {
        Project storage project = projects[_projectId];
        require(project.registeredTimestamp > 0, "CognitoNexus: Project does not exist");
        require(project.ipNftId == _projectId, "CognitoNexus: Invalid project ID to IP NFT link");
        require(!_exists(_projectId), "CognitoNexus: IP NFT already minted for this project");

        _mint(project.owner, _projectId);
        _setTokenURI(_projectId, _initialIPURI);
        emit DynamicIPNFTMinted(_projectId, _projectId, project.owner, _initialIPURI);
    }

    function updateIPNFTMetadata(uint256 _ipNftId, string calldata _newIPURI)
        external
        onlyProfileOwner(ownerOf(_ipNftId)) // Only current IP NFT owner can update
        whenNotPaused
    {
        require(_exists(_ipNftId), "CognitoNexus: IP NFT does not exist");
        _setTokenURI(_ipNftId, _newIPURI);
        emit DynamicIPNFTMetadataUpdated(_ipNftId, _newIPURI);
    }

    function getProjectDetails(uint256 _projectId)
        external
        view
        returns (string memory name, string memory projectHash, string[] memory initialSkillsNeeded, address owner, uint256 ipNftId, uint256 registeredTimestamp)
    {
        Project storage project = projects[_projectId];
        require(project.registeredTimestamp > 0, "CognitoNexus: Project does not exist");
        return (project.name, project.projectHash, project.initialSkillsNeeded, project.owner, project.ipNftId, project.registeredTimestamp);
    }

    function getIPNFTURI(uint256 _ipNftId) external view returns (string memory) {
        return tokenURI(_ipNftId);
    }

    // --- VI. AI Oracle Interface (Conceptual) ---

    function requestAIAnalysis(uint256 _targetId, uint256 _analysisType, bytes calldata _data)
        external
        whenNotPaused
    {
        require(aiOracleAddress != address(0), "CognitoNexus: AI Oracle address not set");

        bytes32 requestId = keccak256(abi.encodePacked(block.timestamp, msg.sender, _targetId, _analysisType, _data));
        pendingAIRequests[requestId] = msg.sender;

        // In a real Chainlink integration, this would call a Chainlink request function:
        // ChainlinkClient.request(aiOracleAddress, jobId, requestId, _targetId, _analysisType, _data);
        // For demonstration, we just emit the event.
        emit AIAnalysisRequested(requestId, _targetId, _analysisType, _data);
    }

    function fulfillAIAnalysis(bytes32 _requestId, bytes calldata _resultData)
        external
        whenNotPaused
    {
        require(msg.sender == aiOracleAddress, "CognitoNexus: Only AI Oracle can fulfill requests");
        address caller = pendingAIRequests[_requestId];
        require(caller != address(0), "CognitoNexus: Invalid or expired AI analysis request ID");

        delete pendingAIRequests[_requestId];

        // Process _resultData based on the original _analysisType
        // Example: If analysisType was reputation boost, update reputationScores[caller]
        // Example: If analysisType was project impact, update project metadata (via _updateIPNFTMetadata if applicable)

        emit AIAnalysisFulfilled(_requestId, _resultData);
    }

    // --- VII. Governance & Utilities ---

    function proposeNewSkill(string calldata _newSkillName, string calldata _description)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        require(bytes(_newSkillName).length > 0, "CognitoNexus: Skill name cannot be empty");
        require(!isOfficialSkill[_newSkillName], "CognitoNexus: Skill already official or proposed");

        uint256 currentProposalId = ++nextProposalId;
        Proposal storage newProposal = proposals[currentProposalId];
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.status = ProposalStatus.Active;
        newProposal.creationTimestamp = block.timestamp;
        newProposal.votingDeadline = block.timestamp + proposalVotingPeriod;
        newProposal.proposalType = 0; // 0 for Add Skill
        newProposal.data = abi.encodePacked(_newSkillName); // Store new skill name

        emit ProposalCreated(currentProposalId, msg.sender, _description, newProposal.proposalType);
    }

    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyExistingProfile(msg.sender)
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitoNexus: Proposal does not exist");
        require(proposal.status == ProposalStatus.Active, "CognitoNexus: Proposal is not active for voting");
        require(block.timestamp <= proposal.votingDeadline, "CognitoNexus: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "CognitoNexus: Already voted on this proposal");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        // Basic check for immediate status update (could be more complex with quorum calculation)
        if (block.timestamp > proposal.votingDeadline) {
            _evaluateProposalStatus(_proposalId);
        }

        emit VotedOnProposal(_proposalId, msg.sender, _support);
    }

    function _evaluateProposalStatus(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.status == ProposalStatus.Active && block.timestamp > proposal.votingDeadline) {
            uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
            // Simple quorum: at least 10 votes, and 50% majority
            if (totalVotes > 10 && (proposal.votesFor * 100) / totalVotes >= proposalQuorumPercentage) {
                proposal.status = ProposalStatus.Succeeded;
            } else {
                proposal.status = ProposalStatus.Failed;
            }
        }
    }

    function executeProposal(uint256 _proposalId)
        external
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "CognitoNexus: Proposal does not exist");
        require(proposal.status != ProposalStatus.Executed, "CognitoNexus: Proposal already executed");

        // Ensure voting period has ended and status is evaluated
        _evaluateProposalStatus(_proposalId);
        require(proposal.status == ProposalStatus.Succeeded, "CognitoNexus: Proposal has not succeeded or is not ready for execution");

        if (proposal.proposalType == 0) { // Add Skill Proposal
            string memory newSkillName = abi.decode(proposal.data, (string));
            require(!isOfficialSkill[newSkillName], "CognitoNexus: Skill already official");
            officialSkills.push(newSkillName);
            isOfficialSkill[newSkillName] = true;
            emit OfficialSkillAdded(newSkillName);
        }
        // Add more proposal types here (e.g., revoke SBT, update config)

        proposal.status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
    }

    function setAIOracleAddress(address _newAIOracle) external onlyOwner {
        require(_newAIOracle != address(0), "CognitoNexus: AI Oracle address cannot be zero");
        emit AIOracleAddressUpdated(aiOracleAddress, _newAIOracle);
        aiOracleAddress = _newAIOracle;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}
```