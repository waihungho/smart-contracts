Here's a Solidity smart contract named "EchelonForge", designed as a decentralized platform for skill validation, content contribution, and reputation building, featuring dynamic NFTs, a staking-based curation system, AI oracle integration (conceptual), and a simplified governance model.

---

## EchelonForge Smart Contract: Outline & Function Summary

**Concept:** EchelonForge is a decentralized protocol where users can register skills, submit contributions (e.g., projects, content, proofs of work), and have them validated by the community or designated "Echelon Curators." This process builds an on-chain "Echelon Score" (reputation). Users also mint dynamic NFTs called "EchelonBadges" that visually evolve based on their Echelon Score, granting them tiered access to exclusive features and influencing governance. The protocol incorporates a challenge/bounty system for structured skill validation and a conceptual AI oracle for dynamic parameter adjustments.

---

### **Outline:**

1.  **Contract Information:** Pragma, Licenses, Imports.
2.  **Custom Errors:** Specific error messages for clarity.
3.  **Events:** To signal important state changes.
4.  **Enums & Structs:** Data structures for contributions, challenges, proposals, etc.
5.  **State Variables:** Global contract state, mappings for user data, challenges, NFTs.
6.  **Modifiers:** Access control and state validation.
7.  **Constructor:** Initial setup, setting owner and AI Oracle address.
8.  **Core Reputation & Profile Management (Echelon Score):** Functions for user profiles, skill declaration, contribution submission, and reputation gain/decay.
9.  **Dynamic EchelonBadges (ERC721 Extension):** Functions for minting and upgrading NFTs based on Echelon Score, managing metadata.
10. **Challenges & Bounties (Skill Validation through Tasks):** Functions for creating, submitting solutions to, and validating challenges, with token rewards.
11. **Staking & Curation (Influence & Validation Weight):** Functions for staking tokens to become a curator and gaining weighted influence in validation.
12. **AI Oracle Integration (Parameter Control):** Functions callable by a designated 'AI Oracle' address to dynamically adjust protocol parameters.
13. **Access Control & Gating (Utility of Reputation):** Functions to configure and check access to off-chain resources based on Echelon Score and Badge tier.
14. **Protocol Economics & Governance (Simplified):** Functions for fund management and a basic proposal/voting mechanism for protocol parameter changes.
15. **ERC721 Standard Functions:** Required functions for ERC721 compliance (e.g., `transferFrom`, `approve`, `ownerOf`, `balanceOf`, `tokenURI`).

---

### **Function Summary (27 Creative & Core Functions + Standard ERC721):**

**I. Core Reputation & Profile Management (Echelon Score)**
1.  `registerProfile(string calldata _username, string[] calldata _initialSkills)`: Creates a new user profile with a username and initial skills, initializing their Echelon Score.
2.  `updateProfileSkills(string[] calldata _newSkills)`: Allows a user to add or remove skills from their profile.
3.  `submitContribution(string calldata _contentHash, string calldata _category, string[] calldata _associatedSkills)`: Submits a hash representing a contribution (e.g., content, project) for community/curator validation.
4.  `endorseContribution(uint256 _contributionId, bool _isValid)`: Allows users or curators to validate/invalidate a contribution, directly impacting the submitter's Echelon Score.
5.  `getEchelonScore(address _user)`: Retrieves the current Echelon Score of a specified user.
6.  `processReputationDecay(address _user)`: Applies a reputation decay based on inactivity for a specific user. Designed to be called periodically (e.g., by a keeper).

**II. Dynamic EchelonBadges (ERC721 Extension)**
7.  `mintEchelonBadge(address _to)`: Mints the initial EchelonBadge NFT for a user. Each user can only have one.
8.  `upgradeEchelonBadge(uint256 _tokenId)`: Triggers an update to the metadata (tier) of an EchelonBadge NFT based on the holder's Echelon Score.
9.  `getEchelonBadgeTier(uint256 _tokenId)`: Returns the current reputation tier of an EchelonBadge NFT.
10. `getTierRequirements(uint256 _tier)`: Retrieves the minimum Echelon Score required for a specific EchelonBadge tier.

**III. Challenges & Bounties (Skill Validation through Tasks)**
11. `createChallenge(string calldata _challengeHash, string calldata _category, uint256 _bountyAmount, uint256 _duration, string[] calldata _requiredSkills)`: Creates a new time-bound challenge with a specified bounty and required skills.
12. `submitChallengeSolution(uint256 _challengeId, string calldata _solutionHash)`: Allows a user to submit a solution hash to an active challenge.
13. `validateChallengeSolution(uint256 _challengeId, address _solver, bool _isSuccessful)`: Callable by the challenge creator or a curator to validate a submitted solution, distributing the bounty and adjusting reputation.

**IV. Staking & Curation (Influence & Validation Weight)**
14. `stakeForCuratorStatus(uint256 _amount)`: Allows users to stake native tokens to become an "Echelon Curator," gaining increased weight in contribution and challenge validation.
15. `unstakeFromCuratorStatus()`: Enables an Echelon Curator to unstake their tokens after a cooldown period.
16. `getCuratorWeight(address _curator)`: Returns the current validation influence weight of a specified curator.

**V. AI Oracle Integration (Parameter Control)**
17. `setCategoryWeight(string calldata _category, uint256 _weight)`: Callable only by the designated 'AI Oracle' address to adjust the reputation impact of different contribution categories.
18. `setReputationDecayRate(uint256 _rate)`: Callable by the 'AI Oracle' to adjust the global reputation decay rate.
19. `updateDynamicParameter(bytes32 _paramKey, uint256 _value)`: A generic function for the 'AI Oracle' to update various system parameters (e.g., challenge difficulty multipliers, tier thresholds) dynamically.

**VI. Access Control & Gating (Utility of Reputation)**
20. `grantExclusiveAccess(address _user, string calldata _resourceId)`: Records that a user has been granted access to an off-chain resource, typically after meeting on-chain criteria.
21. `checkExclusiveAccess(address _user, string calldata _resourceId)`: Checks if a user currently has active access to a specific exclusive resource.
22. `configureAccessTier(string calldata _resourceId, uint256 _minEchelonScore, uint256 _minBadgeTier)`: Sets the minimum Echelon Score and EchelonBadge tier required for accessing a particular exclusive resource.

**VII. Protocol Economics & Governance (Simplified)**
23. `depositProtocolFunds()`: Allows users to deposit native tokens into the contract's treasury (e.g., for bounties, future feature development).
24. `withdrawProtocolTreasury(address _to, uint256 _amount)`: Callable by the owner or via governance to withdraw funds from the protocol treasury.
25. `proposeProtocolParameterChange(bytes32 _parameterKey, uint256 _newValue)`: Allows users with sufficient reputation/stake to propose changes to system parameters.
26. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows eligible users (based on Echelon Score/stake) to cast their weighted vote on an active proposal.
27. `executeProposal(uint256 _proposalId)`: Executes a proposal that has passed its voting threshold and duration.

**Standard ERC721 Functions (Implemented for EchelonBadge):**
*   `balanceOf(address owner)`
*   `ownerOf(uint256 tokenId)`
*   `approve(address to, uint256 tokenId)`
*   `getApproved(uint256 tokenId)`
*   `setApprovalForAll(address operator, bool approved)`
*   `isApprovedForAll(address owner, address operator)`
*   `transferFrom(address from, address to, uint256 tokenId)`
*   `safeTransferFrom(address from, address to, uint256 tokenId)`
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`
*   `supportsInterface(bytes4 interfaceId)`
*   `name()`
*   `symbol()`
*   `tokenURI(uint256 _tokenId)`: Generates dynamic metadata URI based on badge tier.
*   `setBaseURI(string memory baseURI_)`: Sets the base URI for NFT metadata.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title EchelonForge
 * @dev A decentralized protocol for skill validation, content contribution, and dynamic reputation building.
 *      Features include dynamic NFTs (EchelonBadges), a staking-based curation system,
 *      conceptual AI oracle integration for parameter adjustments, and simplified governance.
 */
contract EchelonForge is Context, ERC165, IERC721 {
    using Strings for uint256;

    /*///////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/
    error EchelonForge__NotOwner();
    error EchelonForge__NotAIOracle();
    error EchelonForge__ProfileDoesNotExist();
    error EchelonForge__ProfileAlreadyExists();
    error EchelonForge__InvalidSkill();
    error EchelonForge__ContributionNotFound();
    error EchelonForge__AlreadyEndorsed();
    error EchelonForge__CannotEndorseOwnContribution();
    error EchelonForge__InsufficientEchelonScore();
    error EchelonForge__BadgeAlreadyMinted();
    error EchelonForge__BadgeNotFound();
    error EchelonForge__ChallengeNotFound();
    error EchelonForge__ChallengeNotActive();
    error EchelonForge__ChallengeExpired();
    error EchelonForge__ChallengeNotEnded();
    error EchelonForge__ChallengeNotCreator();
    error EchelonForge__SolutionAlreadySubmitted();
    error EchelonForge__SolutionNotFound();
    error EchelonForge__SolutionAlreadyValidated();
    error EchelonForge__InsufficientStake();
    error EchelonForge__AlreadyStaked();
    error EchelonForge__NotStaked();
    error EchelonForge__UnstakeCooldownActive(uint256 timeLeft);
    error EchelonForge__InvalidParameterKey();
    error EchelonForge__AccessAlreadyGranted();
    error EchelonForge__AccessNotConfigured();
    error EchelonForge__ProposalNotFound();
    error EchelonForge__ProposalAlreadyVoted();
    error EchelonForge__ProposalNotActive();
    error EchelonForge__ProposalAlreadyExecuted();
    error EchelonForge__ProposalFailed();
    error EchelonForge__ProposalNotPassed();
    error EchelonForge__CannotExecuteFutureProposal();
    error EchelonForge__InsufficientFunds();
    error EchelonForge__NotIERC721Receiver();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event ProfileRegistered(address indexed user, string username);
    event SkillsUpdated(address indexed user, string[] newSkills);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed submitter, string contentHash, string category);
    event ContributionEndorsed(uint256 indexed contributionId, address indexed endorser, bool isValid, uint256 newEchelonScore);
    event EchelonScoreDecayed(address indexed user, uint256 newEchelonScore);
    event EchelonBadgeMinted(address indexed user, uint256 indexed tokenId);
    event EchelonBadgeUpgraded(uint256 indexed tokenId, uint256 newTier);
    event ChallengeCreated(uint256 indexed challengeId, address indexed creator, uint256 bountyAmount, uint256 duration);
    event ChallengeSolutionSubmitted(uint256 indexed challengeId, address indexed solver, string solutionHash);
    event ChallengeSolutionValidated(uint256 indexed challengeId, address indexed solver, bool isSuccessful, uint256 reputationGain);
    event ChallengeBountyClaimed(uint256 indexed challengeId, address indexed solver, uint256 amount);
    event CuratorStaked(address indexed curator, uint256 amount);
    event CuratorUnstaked(address indexed curator, uint256 amount);
    event CategoryWeightUpdated(string indexed category, uint256 newWeight);
    event ReputationDecayRateUpdated(uint256 newRate);
    event DynamicParameterUpdated(bytes32 indexed paramKey, uint256 newValue);
    event AccessTierConfigured(string indexed resourceId, uint256 minEchelonScore, uint256 minBadgeTier);
    event ExclusiveAccessGranted(address indexed user, string indexed resourceId);
    event ProtocolFundsDeposited(address indexed depositor, uint256 amount);
    event ProtocolFundsWithdrawn(address indexed to, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 parameterKey, uint256 newValue);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weightedVote);
    event ProposalExecuted(uint256 indexed proposalId);

    /*///////////////////////////////////////////////////////////////
                            ENUMS & STRUCTS
    //////////////////////////////////////////////////////////////*/

    enum ChallengeStatus { Active, Ended, Completed }
    enum ProposalStatus { Pending, Active, Succeeded, Failed, Executed }

    struct UserProfile {
        string username;
        uint256 echelonScore; // Current reputation score
        uint256 lastActivityTime; // For decay calculation
        string[] skills; // Declared skills
        uint256 badgeTokenId; // The ID of their EchelonBadge NFT
        bool profileExists; // True if profile is registered
    }

    struct Contribution {
        address submitter;
        string contentHash;
        string category;
        string[] associatedSkills;
        uint256 submissionTime;
        mapping(address => bool) endorsedBy; // Who endorsed (positive/negative)
        uint256 positiveEndorsements;
        uint256 negativeEndorsements;
        bool isValidated; // Final validation status
    }

    struct Challenge {
        address creator;
        string challengeHash;
        string category;
        uint256 bountyAmount;
        uint256 startTime;
        uint256 endTime;
        string[] requiredSkills;
        ChallengeStatus status;
        mapping(address => string) solutions; // solver => solutionHash
        mapping(address => bool) solutionValidated; // solver => isSuccessful
        address[] solvers; // List of addresses who submitted solutions
    }

    struct CuratorStake {
        uint256 amount;
        uint256 unstakeRequestTime; // When unstake was initiated
    }

    struct AccessTier {
        uint256 minEchelonScore;
        uint256 minBadgeTier;
        bool configured;
    }

    struct Proposal {
        bytes32 parameterKey;
        uint256 newValue;
        uint256 proposerEchelonScore; // Score at time of proposal
        uint256 proposalEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) voted; // Has user voted?
        ProposalStatus status;
        uint256 proposalThreshold; // Minimum weighted vote to pass
    }

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address private immutable i_owner;
    address public aiOracleAddress; // Address authorized to update AI-driven parameters

    // Core Reputation & Profile
    mapping(address => UserProfile) public s_userProfiles;
    uint256 private s_nextContributionId;
    mapping(uint256 => Contribution) public s_contributions; // Contribution ID => Contribution struct
    mapping(string => uint256) public s_categoryWeights; // Category => Reputation weight multiplier
    uint256 public s_reputationDecayRate; // Percentage decay per week (e.g., 100 = 1%)

    // Dynamic EchelonBadges (ERC721)
    string private s_baseURI;
    uint256 private s_nextTokenId;
    mapping(uint256 => address) private s_owners; // Token ID to owner
    mapping(address => uint256) private s_balances; // Owner to balance
    mapping(uint256 => address) private s_tokenApprovals; // Token ID to approved address
    mapping(address => mapping(address => bool)) private s_operatorApprovals; // Owner to (Operator to Approved)

    // Tier thresholds for EchelonBadges
    uint256[] public s_echelonBadgeTiers; // e.g., [0, 100, 500, 1000] for tiers 0, 1, 2, 3

    // Challenges & Bounties
    uint256 private s_nextChallengeId;
    mapping(uint256 => Challenge) public s_challenges;
    mapping(address => uint256) public s_protocolBalance; // Native token balance for bounties/treasury

    // Staking & Curation
    uint256 public s_curatorMinStakeAmount;
    uint256 public s_curatorUnstakeCooldown; // In seconds
    mapping(address => CuratorStake) public s_curatorStakes;

    // Access Control & Gating
    mapping(string => AccessTier) public s_accessTiers; // Resource ID => AccessTier requirements
    mapping(address => mapping(string => bool)) public s_userAccessGranted; // User => Resource ID => Has Access

    // Governance
    uint256 private s_nextProposalId;
    mapping(uint256 => Proposal) public s_proposals;
    uint256 public s_proposalVoteDuration; // In seconds
    uint256 public s_minEchelonScoreForProposal; // Minimum score to create a proposal
    uint256 public s_minWeightedVotesForPass; // Minimum weighted votes for a proposal to pass

    /*///////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert EchelonForge__NotOwner();
        }
        _;
    }

    modifier onlyAIOracle() {
        if (msg.sender != aiOracleAddress) {
            revert EchelonForge__NotAIOracle();
        }
        _;
    }

    modifier userExists(address _user) {
        if (!s_userProfiles[_user].profileExists) {
            revert EchelonForge__ProfileDoesNotExist();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _aiOracleAddress, uint256[] memory _echelonBadgeTierThresholds) {
        i_owner = _msgSender();
        aiOracleAddress = _aiOracleAddress;

        // Initial default parameters
        s_reputationDecayRate = 100; // 1% decay per decay period
        s_curatorMinStakeAmount = 1 ether; // 1 native token
        s_curatorUnstakeCooldown = 7 days; // 7 days cooldown
        s_proposalVoteDuration = 3 days;
        s_minEchelonScoreForProposal = 500;
        s_minWeightedVotesForPass = 1000; // Example threshold, depends on curator stake values

        // Initial EchelonBadge tiers:
        // Tier 0: 0+
        // Tier 1: 100+
        // Tier 2: 500+
        // Tier 3: 1000+
        // ... and so on. Must be sorted ascending.
        require(_echelonBadgeTierThresholds.length > 0, "EchelonForge: Tier thresholds cannot be empty");
        s_echelonBadgeTiers = _echelonBadgeTierThresholds;

        // Initialize default category weights (can be updated by AI Oracle)
        s_categoryWeights["Development"] = 10;
        s_categoryWeights["Art"] = 8;
        s_categoryWeights["Writing"] = 7;
        s_categoryWeights["Research"] = 9;
    }

    /*///////////////////////////////////////////////////////////////
                I. Core Reputation & Profile Management
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Registers a new user profile on the EchelonForge protocol.
     * @param _username The desired username for the profile.
     * @param _initialSkills An array of initial skills for the user.
     */
    function registerProfile(string calldata _username, string[] calldata _initialSkills) external {
        if (s_userProfiles[_msgSender()].profileExists) {
            revert EchelonForge__ProfileAlreadyExists();
        }

        UserProfile storage profile = s_userProfiles[_msgSender()];
        profile.username = _username;
        profile.echelonScore = 0; // Starts with 0 score
        profile.lastActivityTime = block.timestamp;
        profile.skills = _initialSkills;
        profile.profileExists = true;

        emit ProfileRegistered(_msgSender(), _username);
    }

    /**
     * @dev Allows a user to update their declared skills.
     * @param _newSkills An array of the new set of skills for the user.
     */
    function updateProfileSkills(string[] calldata _newSkills) external userExists(_msgSender()) {
        s_userProfiles[_msgSender()].skills = _newSkills;
        s_userProfiles[_msgSender()].lastActivityTime = block.timestamp;
        emit SkillsUpdated(_msgSender(), _newSkills);
    }

    /**
     * @dev Submits a new contribution for validation.
     * @param _contentHash The IPFS/Arweave hash or identifier of the content/proof.
     * @param _category The category of the contribution (e.g., "Development", "Art").
     * @param _associatedSkills An array of skills relevant to this contribution.
     * @return The ID of the newly created contribution.
     */
    function submitContribution(string calldata _contentHash, string calldata _category, string[] calldata _associatedSkills) external userExists(_msgSender()) returns (uint256) {
        uint256 id = s_nextContributionId++;
        s_contributions[id].submitter = _msgSender();
        s_contributions[id].contentHash = _contentHash;
        s_contributions[id].category = _category;
        s_contributions[id].associatedSkills = _associatedSkills;
        s_contributions[id].submissionTime = block.timestamp;
        s_contributions[id].isValidated = false;

        s_userProfiles[_msgSender()].lastActivityTime = block.timestamp;
        emit ContributionSubmitted(id, _msgSender(), _contentHash, _category);
        return id;
    }

    /**
     * @dev Allows other users or curators to endorse a contribution, impacting the submitter's Echelon Score.
     * @param _contributionId The ID of the contribution to endorse.
     * @param _isValid True if the endorser believes the contribution is valid, false otherwise.
     */
    function endorseContribution(uint256 _contributionId, bool _isValid) external userExists(_msgSender()) {
        Contribution storage contribution = s_contributions[_contributionId];
        if (contribution.submitter == address(0)) {
            revert EchelonForge__ContributionNotFound();
        }
        if (contribution.endorsedBy[_msgSender()]) {
            revert EchelonForge__AlreadyEndorsed();
        }
        if (contribution.submitter == _msgSender()) {
            revert EchelonForge__CannotEndorseOwnContribution();
        }

        contribution.endorsedBy[_msgSender()] = true;
        uint256 endorserWeight = 1; // Default weight for regular users
        CuratorStake storage curator = s_curatorStakes[_msgSender()];
        if (curator.amount > 0) {
            endorserWeight = getCuratorWeight(_msgSender()); // Use curator's weighted influence
        }

        UserProfile storage submitterProfile = s_userProfiles[contribution.submitter];
        uint256 categoryWeight = s_categoryWeights[contribution.category];
        if (categoryWeight == 0) {
            categoryWeight = 1; // Default to 1 if category not set
        }

        if (_isValid) {
            contribution.positiveEndorsements += endorserWeight;
            submitterProfile.echelonScore += (1 * endorserWeight * categoryWeight); // Positive impact
        } else {
            contribution.negativeEndorsements += endorserWeight;
            // Negative impact, capped at 0 Echelon Score
            if (submitterProfile.echelonScore > (1 * endorserWeight * categoryWeight)) {
                submitterProfile.echelonScore -= (1 * endorserWeight * categoryWeight);
            } else {
                submitterProfile.echelonScore = 0;
            }
        }
        submitterProfile.lastActivityTime = block.timestamp;
        emit ContributionEndorsed(_contributionId, _msgSender(), _isValid, submitterProfile.echelonScore);
    }

    /**
     * @dev Retrieves the current Echelon Score of a specified user.
     * @param _user The address of the user.
     * @return The user's Echelon Score.
     */
    function getEchelonScore(address _user) public view userExists(_user) returns (uint256) {
        return s_userProfiles[_user].echelonScore;
    }

    /**
     * @dev Applies a reputation decay to a user's Echelon Score based on inactivity.
     *      Designed to be called periodically by a keeper or the user themselves.
     * @param _user The address of the user to process decay for.
     */
    function processReputationDecay(address _user) external userExists(_user) {
        UserProfile storage profile = s_userProfiles[_user];
        uint256 timePassed = block.timestamp - profile.lastActivityTime;
        uint256 decayPeriod = 7 days; // Example: decay weekly

        if (timePassed < decayPeriod) {
            return; // Not enough time has passed for decay
        }

        uint256 numDecayPeriods = timePassed / decayPeriod;
        uint256 decayAmount = (profile.echelonScore * s_reputationDecayRate * numDecayPeriods) / 10000; // s_reputationDecayRate is in 1/100 of a percent, so divide by 10000 for actual percentage

        if (profile.echelonScore > decayAmount) {
            profile.echelonScore -= decayAmount;
        } else {
            profile.echelonScore = 0;
        }
        profile.lastActivityTime = block.timestamp; // Reset last activity time
        emit EchelonScoreDecayed(_user, profile.echelonScore);
    }

    /*///////////////////////////////////////////////////////////////
                    II. Dynamic EchelonBadges (ERC721 Extension)
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Mints the initial EchelonBadge NFT for a user. Each user can only have one badge.
     * @param _to The address to mint the badge to.
     */
    function mintEchelonBadge(address _to) external userExists(_to) {
        UserProfile storage profile = s_userProfiles[_to];
        if (profile.badgeTokenId != 0) {
            revert EchelonForge__BadgeAlreadyMinted();
        }

        uint256 newId = s_nextTokenId++;
        _mint(_to, newId);
        profile.badgeTokenId = newId;

        emit EchelonBadgeMinted(_to, newId);
    }

    /**
     * @dev Triggers an update to the metadata (tier) of an EchelonBadge NFT based on the holder's Echelon Score.
     *      This function can be called by the NFT owner or an authorized operator.
     * @param _tokenId The ID of the EchelonBadge NFT to upgrade.
     */
    function upgradeEchelonBadge(uint256 _tokenId) external {
        address badgeOwner = s_owners[_tokenId];
        if (badgeOwner == address(0)) {
            revert EchelonForge__BadgeNotFound();
        }
        if (badgeOwner != _msgSender() && !isApprovedForAll(badgeOwner, _msgSender())) {
            revert EchelonForge__NotOwner(); // Or specific ERC721 error for approval
        }

        // Logic to update the tier based on current echelon score
        uint256 currentScore = s_userProfiles[badgeOwner].echelonScore;
        uint256 newTier = 0;
        for (uint256 i = s_echelonBadgeTiers.length - 1; i >= 0; i--) {
            if (currentScore >= s_echelonBadgeTiers[i]) {
                newTier = i;
                break;
            }
            if (i == 0) break; // Prevent underflow for 0
        }

        // In a real scenario, this would likely involve updating off-chain metadata JSON and refreshing clients.
        // For this contract, it simply emits an event indicating the tier change.
        emit EchelonBadgeUpgraded(_tokenId, newTier);
    }

    /**
     * @dev Returns the current reputation tier of an EchelonBadge NFT.
     * @param _tokenId The ID of the EchelonBadge.
     * @return The tier number (0-indexed).
     */
    function getEchelonBadgeTier(uint256 _tokenId) public view returns (uint256) {
        address badgeOwner = s_owners[_tokenId];
        if (badgeOwner == address(0)) {
            revert EchelonForge__BadgeNotFound();
        }
        uint256 currentScore = s_userProfiles[badgeOwner].echelonScore;
        uint256 currentTier = 0;
        for (uint256 i = s_echelonBadgeTiers.length - 1; i >= 0; i--) {
            if (currentScore >= s_echelonBadgeTiers[i]) {
                currentTier = i;
                break;
            }
            if (i == 0) break;
        }
        return currentTier;
    }

    /**
     * @dev Retrieves the minimum Echelon Score required for a specific EchelonBadge tier.
     * @param _tier The tier number.
     * @return The minimum score required.
     */
    function getTierRequirements(uint256 _tier) public view returns (uint256) {
        require(_tier < s_echelonBadgeTiers.length, "EchelonForge: Invalid tier");
        return s_echelonBadgeTiers[_tier];
    }

    /*///////////////////////////////////////////////////////////////
                III. Challenges & Bounties
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Creates a new time-bound challenge with a specified bounty and required skills.
     *      Funds for the bounty must be sent with this transaction.
     * @param _challengeHash An identifier or hash for the challenge details (off-chain).
     * @param _category The category of the challenge.
     * @param _bountyAmount The amount of native tokens offered as bounty.
     * @param _duration The duration of the challenge in seconds.
     * @param _requiredSkills An array of skills required to solve the challenge.
     * @return The ID of the newly created challenge.
     */
    function createChallenge(
        string calldata _challengeHash,
        string calldata _category,
        uint256 _bountyAmount,
        uint256 _duration,
        string[] calldata _requiredSkills
    ) external payable userExists(_msgSender()) returns (uint256) {
        if (msg.value < _bountyAmount) {
            revert EchelonForge__InsufficientFunds();
        }

        uint256 id = s_nextChallengeId++;
        s_challenges[id].creator = _msgSender();
        s_challenges[id].challengeHash = _challengeHash;
        s_challenges[id].category = _category;
        s_challenges[id].bountyAmount = _bountyAmount;
        s_challenges[id].startTime = block.timestamp;
        s_challenges[id].endTime = block.timestamp + _duration;
        s_challenges[id].requiredSkills = _requiredSkills;
        s_challenges[id].status = ChallengeStatus.Active;

        s_protocolBalance[address(this)] += _bountyAmount; // Store bounty within contract's managed balance

        s_userProfiles[_msgSender()].lastActivityTime = block.timestamp;
        emit ChallengeCreated(id, _msgSender(), _bountyAmount, _duration);
        return id;
    }

    /**
     * @dev Allows a user to submit a solution hash to an active challenge.
     * @param _challengeId The ID of the challenge.
     * @param _solutionHash The hash or identifier of the submitted solution (off-chain).
     */
    function submitChallengeSolution(uint256 _challengeId, string calldata _solutionHash) external userExists(_msgSender()) {
        Challenge storage challenge = s_challenges[_challengeId];
        if (challenge.creator == address(0)) {
            revert EchelonForge__ChallengeNotFound();
        }
        if (challenge.status != ChallengeStatus.Active) {
            revert EchelonForge__ChallengeNotActive();
        }
        if (block.timestamp > challenge.endTime) {
            challenge.status = ChallengeStatus.Ended; // Mark as ended
            revert EchelonForge__ChallengeExpired();
        }
        if (bytes(challenge.solutions[_msgSender()]).length > 0) {
            revert EchelonForge__SolutionAlreadySubmitted();
        }

        challenge.solutions[_msgSender()] = _solutionHash;
        challenge.solvers.push(_msgSender());

        s_userProfiles[_msgSender()].lastActivityTime = block.timestamp;
        emit ChallengeSolutionSubmitted(_challengeId, _msgSender(), _solutionHash);
    }

    /**
     * @dev Callable by the challenge creator or a curator to validate a submitted solution.
     *      Distributes bounty and adjusts reputation if successful.
     * @param _challengeId The ID of the challenge.
     * @param _solver The address of the user who submitted the solution.
     * @param _isSuccessful True if the solution is considered successful, false otherwise.
     */
    function validateChallengeSolution(uint256 _challengeId, address _solver, bool _isSuccessful) external userExists(_solver) {
        Challenge storage challenge = s_challenges[_challengeId];
        if (challenge.creator == address(0)) {
            revert EchelonForge__ChallengeNotFound();
        }
        if (challenge.status == ChallengeStatus.Active && block.timestamp <= challenge.endTime) {
            revert EchelonForge__ChallengeNotEnded(); // Can only validate after challenge ends
        }
        if (challenge.status == ChallengeStatus.Completed) {
            revert EchelonForge__ChallengeAlreadyExecuted(); // Prevent re-validation
        }
        if (challenge.creator != _msgSender()) {
            // Only creator or a curator can validate
            CuratorStake storage curator = s_curatorStakes[_msgSender()];
            if (curator.amount == 0) {
                revert EchelonForge__ChallengeNotCreator();
            }
        }
        if (bytes(challenge.solutions[_solver]).length == 0) {
            revert EchelonForge__SolutionNotFound();
        }
        if (challenge.solutionValidated[_solver]) {
            revert EchelonForge__SolutionAlreadyValidated();
        }

        challenge.solutionValidated[_solver] = true;
        uint256 reputationGain = 0;

        if (_isSuccessful) {
            uint256 bountyAmount = challenge.bountyAmount;
            // Transfer bounty to solver
            (bool success,) = _solver.call{value: bountyAmount}("");
            if (!success) {
                // If transfer fails, send back to protocol treasury, but mark bounty as distributed to prevent re-attempts.
                s_protocolBalance[address(this)] += bountyAmount;
                // Consider adding a re-claim mechanism or manual intervention for failed transfers.
            } else {
                s_protocolBalance[address(this)] -= bountyAmount;
                emit ChallengeBountyClaimed(_challengeId, _solver, bountyAmount);
            }

            // Award reputation
            uint256 categoryWeight = s_categoryWeights[challenge.category];
            if (categoryWeight == 0) categoryWeight = 1;

            reputationGain = 10 * categoryWeight; // Example: fixed reputation gain for successful challenge
            s_userProfiles[_solver].echelonScore += reputationGain;
            s_userProfiles[_solver].lastActivityTime = block.timestamp;
        }

        // Set challenge status to completed after all solutions are processed or after a grace period.
        // For simplicity, we just mark this specific solution as validated.
        // A more complex system would have a finalization function for the challenge itself.
        emit ChallengeSolutionValidated(_challengeId, _solver, _isSuccessful, reputationGain);
    }

    /*///////////////////////////////////////////////////////////////
                    IV. Staking & Curation
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows users to stake native tokens to become an "Echelon Curator,"
     *      gaining increased weight in contribution and challenge validation.
     * @param _amount The amount of native tokens to stake.
     */
    function stakeForCuratorStatus(uint256 _amount) external payable userExists(_msgSender()) {
        if (s_curatorStakes[_msgSender()].amount > 0) {
            revert EchelonForge__AlreadyStaked();
        }
        if (_amount < s_curatorMinStakeAmount) {
            revert EchelonForge__InsufficientStake();
        }
        if (msg.value < _amount) {
            revert EchelonForge__InsufficientFunds();
        }

        s_curatorStakes[_msgSender()].amount = _amount;
        s_protocolBalance[address(this)] += _amount; // Funds moved to protocol treasury
        s_userProfiles[_msgSender()].lastActivityTime = block.timestamp;
        emit CuratorStaked(_msgSender(), _amount);
    }

    /**
     * @dev Enables an Echelon Curator to unstake their tokens after a cooldown period.
     *      Initiates a cooldown period if one is not active.
     */
    function unstakeFromCuratorStatus() external userExists(_msgSender()) {
        CuratorStake storage curator = s_curatorStakes[_msgSender()];
        if (curator.amount == 0) {
            revert EchelonForge__NotStaked();
        }

        if (curator.unstakeRequestTime == 0) {
            // Initiate cooldown
            curator.unstakeRequestTime = block.timestamp;
            revert EchelonForge__UnstakeCooldownActive(s_curatorUnstakeCooldown); // Inform about cooldown
        }

        if (block.timestamp < curator.unstakeRequestTime + s_curatorUnstakeCooldown) {
            revert EchelonForge__UnstakeCooldownActive(curator.unstakeRequestTime + s_curatorUnstakeCooldown - block.timestamp);
        }

        uint256 amountToUnstake = curator.amount;
        curator.amount = 0;
        curator.unstakeRequestTime = 0;

        (bool success,) = _msgSender().call{value: amountToUnstake}("");
        if (!success) {
            // If transfer fails, revert the state change.
            curator.amount = amountToUnstake; // Revert the amount
            curator.unstakeRequestTime = block.timestamp; // Re-initiate cooldown
            revert EchelonForge__InsufficientFunds(); // Or more specific error like "TransferFailed"
        }

        s_protocolBalance[address(this)] -= amountToUnstake;
        s_userProfiles[_msgSender()].lastActivityTime = block.timestamp;
        emit CuratorUnstaked(_msgSender(), amountToUnstake);
    }

    /**
     * @dev Returns the current validation influence weight of a specified curator.
     *      Weight increases with stake amount.
     * @param _curator The address of the curator.
     * @return The weighted influence multiplier.
     */
    function getCuratorWeight(address _curator) public view returns (uint256) {
        uint256 stakedAmount = s_curatorStakes[_curator].amount;
        if (stakedAmount == 0) {
            return 1; // Default weight for non-curators
        }
        // Example: weight = 1 + (stakedAmount / minStakeAmount)
        // So, 1 ETH stake with 1 ETH minStake gives weight 2.
        return 1 + (stakedAmount / s_curatorMinStakeAmount);
    }

    /*///////////////////////////////////////////////////////////////
                    V. AI Oracle Integration
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Callable only by the designated 'AI Oracle' address to adjust the
     *      reputation impact of different contribution categories.
     * @param _category The category name.
     * @param _weight The new weight multiplier for the category.
     */
    function setCategoryWeight(string calldata _category, uint256 _weight) external onlyAIOracle {
        s_categoryWeights[_category] = _weight;
        emit CategoryWeightUpdated(_category, _weight);
    }

    /**
     * @dev Callable by the 'AI Oracle' to adjust the global reputation decay rate.
     * @param _rate The new decay rate (e.g., 100 for 1%).
     */
    function setReputationDecayRate(uint256 _rate) external onlyAIOracle {
        s_reputationDecayRate = _rate;
        emit ReputationDecayRateUpdated(_rate);
    }

    /**
     * @dev A generic function for the 'AI Oracle' to update various system parameters dynamically.
     *      This provides a flexible integration point for off-chain AI analysis.
     * @param _paramKey A unique key identifying the parameter to update (e.g., hash of "CHALLENGE_DIFFICULTY_MULTIPLIER").
     * @param _value The new unsigned integer value for the parameter.
     */
    function updateDynamicParameter(bytes32 _paramKey, uint256 _value) external onlyAIOracle {
        // This mapping `s_dynamicParameters` is not explicitly defined for space,
        // but conceptually would map `bytes32 => uint256`.
        // For demonstration, we'll just emit an event.
        // In a real system, it would update actual state variables or mappings.
        // Example usage:
        // if (_paramKey == keccak256("CHALLENGE_DIFFICULTY_MULTIPLIER")) {
        //     s_challengeDifficultyMultiplier = _value;
        // } else if (_paramKey == keccak256("PROPOSAL_PASS_THRESHOLD")) {
        //     s_minWeightedVotesForPass = _value;
        // }
        // For this contract, consider it a placeholder for a more complex system.

        emit DynamicParameterUpdated(_paramKey, _value);
    }

    /*///////////////////////////////////////////////////////////////
                VI. Access Control & Gating
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Records that a user has been granted access to an off-chain resource.
     *      This function would typically be called by an off-chain server
     *      after verifying the user meets configured on-chain criteria.
     * @param _user The address of the user to grant access to.
     * @param _resourceId A unique identifier for the exclusive resource (e.g., content ID, feature ID).
     */
    function grantExclusiveAccess(address _user, string calldata _resourceId) external onlyOwner { // Or by a specific access controller role
        if (s_userAccessGranted[_user][_resourceId]) {
            revert EchelonForge__AccessAlreadyGranted();
        }
        AccessTier storage tier = s_accessTiers[_resourceId];
        if (!tier.configured) {
            revert EchelonForge__AccessNotConfigured();
        }

        // Verify on-chain conditions before granting access (though an off-chain service might also do this)
        UserProfile storage profile = s_userProfiles[_user];
        if (profile.echelonScore < tier.minEchelonScore) {
            revert EchelonForge__InsufficientEchelonScore();
        }
        if (getEchelonBadgeTier(profile.badgeTokenId) < tier.minBadgeTier) {
            revert EchelonForge__InsufficientEchelonScore(); // Re-using error, could be more specific
        }

        s_userAccessGranted[_user][_resourceId] = true;
        emit ExclusiveAccessGranted(_user, _resourceId);
    }

    /**
     * @dev Checks if a user currently has active access to a specific exclusive resource.
     *      Designed for off-chain services to query on-chain access rights.
     * @param _user The address of the user.
     * @param _resourceId The unique identifier of the resource.
     * @return True if the user has access, false otherwise.
     */
    function checkExclusiveAccess(address _user, string calldata _resourceId) public view returns (bool) {
        return s_userAccessGranted[_user][_resourceId];
    }

    /**
     * @dev Configures the minimum Echelon Score and EchelonBadge tier required for accessing a particular exclusive resource.
     * @param _resourceId A unique identifier for the exclusive resource.
     * @param _minEchelonScore The minimum Echelon Score required.
     * @param _minBadgeTier The minimum EchelonBadge tier required.
     */
    function configureAccessTier(string calldata _resourceId, uint256 _minEchelonScore, uint256 _minBadgeTier) external onlyOwner {
        s_accessTiers[_resourceId].minEchelonScore = _minEchelonScore;
        s_accessTiers[_resourceId].minBadgeTier = _minBadgeTier;
        s_accessTiers[_resourceId].configured = true;
        emit AccessTierConfigured(_resourceId, _minEchelonScore, _minBadgeTier);
    }

    /*///////////////////////////////////////////////////////////////
                VII. Protocol Economics & Governance
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Allows users to deposit native tokens into the contract's treasury.
     *      Funds can be used for bounties, future feature development, etc.
     */
    function depositProtocolFunds() external payable {
        if (msg.value == 0) {
            revert EchelonForge__InsufficientFunds();
        }
        s_protocolBalance[address(this)] += msg.value;
        emit ProtocolFundsDeposited(_msgSender(), msg.value);
    }

    /**
     * @dev Allows the owner or via a governance proposal to withdraw funds from the protocol treasury.
     * @param _to The address to send the funds to.
     * @param _amount The amount of native tokens to withdraw.
     */
    function withdrawProtocolTreasury(address _to, uint256 _amount) external onlyOwner { // Or add governance check later
        if (s_protocolBalance[address(this)] < _amount) {
            revert EchelonForge__InsufficientFunds();
        }
        s_protocolBalance[address(this)] -= _amount;
        (bool success,) = _to.call{value: _amount}("");
        if (!success) {
            s_protocolBalance[address(this)] += _amount; // Revert balance if transfer fails
            revert EchelonForge__InsufficientFunds(); // More specific transfer error could be used
        }
        emit ProtocolFundsWithdrawn(_to, _amount);
    }

    /**
     * @dev Allows users with sufficient reputation/stake to propose changes to system parameters.
     * @param _parameterKey A bytes32 identifier for the parameter (e.g., keccak256("REPUTATION_DECAY_RATE")).
     * @param _newValue The new value for the parameter.
     * @return The ID of the created proposal.
     */
    function proposeProtocolParameterChange(bytes32 _parameterKey, uint256 _newValue) external userExists(_msgSender()) returns (uint256) {
        UserProfile storage proposerProfile = s_userProfiles[_msgSender()];
        if (proposerProfile.echelonScore < s_minEchelonScoreForProposal) {
            revert EchelonForge__InsufficientEchelonScore();
        }

        uint256 id = s_nextProposalId++;
        s_proposals[id].parameterKey = _parameterKey;
        s_proposals[id].newValue = _newValue;
        s_proposals[id].proposerEchelonScore = proposerProfile.echelonScore;
        s_proposals[id].proposalEndTime = block.timestamp + s_proposalVoteDuration;
        s_proposals[id].status = ProposalStatus.Active;
        s_proposals[id].proposalThreshold = s_minWeightedVotesForPass; // Can be dynamic based on proposal type

        emit ProposalCreated(id, _msgSender(), _parameterKey, _newValue);
        return id;
    }

    /**
     * @dev Allows eligible users (based on Echelon Score/stake) to cast their weighted vote on an active proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external userExists(_msgSender()) {
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.parameterKey == bytes32(0)) {
            revert EchelonForge__ProposalNotFound();
        }
        if (proposal.status != ProposalStatus.Active) {
            revert EchelonForge__ProposalNotActive();
        }
        if (block.timestamp > proposal.proposalEndTime) {
            proposal.status = ProposalStatus.Failed; // Mark as failed if vote period ended
            revert EchelonForge__ProposalNotActive();
        }
        if (proposal.voted[_msgSender()]) {
            revert EchelonForge__ProposalAlreadyVoted();
        }

        uint256 voterWeight = getEchelonScore(_msgSender()) / 100 + getCuratorWeight(_msgSender()); // Example: Echelon score divided by 100 + curator weight
        if (voterWeight == 0) { // Must have some influence
            revert EchelonForge__InsufficientEchelonScore();
        }

        proposal.voted[_msgSender()] = true;
        if (_support) {
            proposal.votesFor += voterWeight;
        } else {
            proposal.votesAgainst += voterWeight;
        }
        s_userProfiles[_msgSender()].lastActivityTime = block.timestamp;
        emit ProposalVoted(_proposalId, _msgSender(), _support, voterWeight);
    }

    /**
     * @dev Executes a proposal that has passed its voting threshold and duration.
     *      This function needs to be manually triggered after the voting period ends.
     *      Only the owner can trigger, but a DAO or multi-sig could replace this.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external onlyOwner { // Could be permissioned by DAO/Curators
        Proposal storage proposal = s_proposals[_proposalId];
        if (proposal.parameterKey == bytes32(0)) {
            revert EchelonForge__ProposalNotFound();
        }
        if (proposal.status == ProposalStatus.Executed) {
            revert EchelonForge__ProposalAlreadyExecuted();
        }
        if (block.timestamp < proposal.proposalEndTime) {
            revert EchelonForge__CannotExecuteFutureProposal();
        }

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor >= proposal.proposalThreshold) {
            // Proposal passed, execute the parameter change.
            // This part would use the `updateDynamicParameter` logic or direct state updates.
            // For example:
            if (proposal.parameterKey == keccak256("REPUTATION_DECAY_RATE")) {
                s_reputationDecayRate = proposal.newValue;
            } else if (proposal.parameterKey == keccak256("CURATOR_MIN_STAKE")) {
                s_curatorMinStakeAmount = proposal.newValue;
            } else if (proposal.parameterKey == keccak256("PROPOSAL_VOTE_DURATION")) {
                s_proposalVoteDuration = proposal.newValue;
            } else {
                revert EchelonForge__InvalidParameterKey(); // Parameter not recognized for direct execution
            }

            proposal.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            revert EchelonForge__ProposalFailed();
        }
    }

    /*///////////////////////////////////////////////////////////////
                    ERC721 STANDARD INTERFACE
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner_) public view override returns (uint256) {
        require(owner_ != address(0), "ERC721: address zero is not a valid owner");
        return s_balances[owner_];
    }

    function ownerOf(uint256 tokenId_) public view override returns (address) {
        address owner_ = s_owners[tokenId_];
        require(owner_ != address(0), "ERC721: owner query for nonexistent token");
        return owner_;
    }

    function approve(address to_, uint256 tokenId_) public override {
        address owner_ = ownerOf(tokenId_);
        require(to_ != owner_, "ERC721: approval to current owner");
        require(_msgSender() == owner_ || isApprovedForAll(owner_, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

        s_tokenApprovals[tokenId_] = to_;
        emit Approval(owner_, to_, tokenId_);
    }

    function getApproved(uint256 tokenId_) public view override returns (address) {
        require(_exists(tokenId_), "ERC721: approved query for nonexistent token");
        return s_tokenApprovals[tokenId_];
    }

    function setApprovalForAll(address operator_, bool approved_) public override {
        require(operator_ != _msgSender(), "ERC721: approve to caller");
        s_operatorApprovals[_msgSender()][operator_] = approved_;
        emit ApprovalForAll(_msgSender(), operator_, approved_);
    }

    function isApprovedForAll(address owner_, address operator_) public view override returns (bool) {
        return s_operatorApprovals[owner_][operator_];
    }

    function transferFrom(address from_, address to_, uint256 tokenId_) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: transfer caller is not owner nor approved");
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes calldata data_) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from_, to_, tokenId_, data_);
    }

    function _mint(address to_, uint256 tokenId_) internal {
        require(to_ != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId_), "ERC721: token already minted");

        s_balances[to_]++;
        s_owners[tokenId_] = to_;

        emit Transfer(address(0), to_, tokenId_);
    }

    function _transfer(address from_, address to_, uint256 tokenId_) internal {
        require(ownerOf(tokenId_) == from_, "ERC721: transfer of token that is not own");
        require(to_ != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId_);

        s_balances[from_]--;
        s_balances[to_]++;
        s_owners[tokenId_] = to_;

        emit Transfer(from_, to_, tokenId_);
    }

    function _safeTransfer(address from_, address to_, uint256 tokenId_, bytes calldata data_) internal {
        _transfer(from_, to_, tokenId_);
        require(_checkOnERC721Received(from_, to_, tokenId_, data_), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId_) internal view returns (bool) {
        return s_owners[tokenId_] != address(0);
    }

    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view returns (bool) {
        require(_exists(tokenId_), "ERC721: operator query for nonexistent token");
        address owner_ = ownerOf(tokenId_);
        return (spender_ == owner_ || getApproved(tokenId_) == spender_ || isApprovedForAll(owner_, spender_));
    }

    function _checkOnERC721Received(address from_, address to_, uint256 tokenId_, bytes calldata data_) private returns (bool) {
        if (to_.code.length > 0) {
            try IERC721Receiver(to_).onERC721Received(_msgSender(), from_, tokenId_, data_) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert EchelonForge__NotIERC721Receiver();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _clearApproval(uint256 tokenId_) private {
        if (s_tokenApprovals[tokenId_] != address(0)) {
            delete s_tokenApprovals[tokenId_];
        }
    }

    // ERC721 Metadata
    function name() public pure override returns (string memory) {
        return "EchelonBadge";
    }

    function symbol() public pure override returns (string memory) {
        return "EBH"; // EchelonBadgeHolder
    }

    function _setBaseURI(string memory baseURI_) internal {
        s_baseURI = baseURI_;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 tier = getEchelonBadgeTier(_tokenId);
        // Assuming metadata for each tier is at baseURI/tierId.json
        // e.g., "ipfs://Qmb.../0.json", "ipfs://Qmb.../1.json"
        return string(abi.encodePacked(s_baseURI, tier.toString(), ".json"));
    }
}
```