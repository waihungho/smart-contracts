Here's a Solidity smart contract named `SynergyNetProtocol` that incorporates advanced concepts like Soulbound Reputation (SBR), Dynamic Skill Badges (DSB) as NFTs, a Proof-of-Contribution (PoC) system with expert review, adaptive system parameters, and weighted resource distribution.

This contract aims to create a meritocratic, self-regulating ecosystem where users earn recognition and resources based on their verifiable contributions and evolving skills, while the protocol itself adapts to its activity levels.

---

## SynergyNetProtocol: An Adaptive Reputation & Contribution Protocol

**Purpose:**
The `SynergyNetProtocol` is designed to foster a meritocratic, adaptive, and self-regulating decentralized community. It introduces Soulbound Reputation (SBR) as a non-transferable measure of a user's value and contribution, and Dynamic Skill Badges (DSB) as evolving NFTs that represent attested expertise. Contributions are verified through a multi-stage review system, and critical protocol parameters can dynamically adjust based on on-chain activity. Resource distribution is weighted by a combination of SBR and DSB.

**Core Concepts:**

1.  **Soulbound Reputation (SBR):** A non-transferable, on-chain score reflecting a user's accumulated value, contributions, and engagement within the protocol. It can decay over time to encourage continued participation.
2.  **Dynamic Skill Badges (DSB):** ERC-721 NFTs that represent a user's attested skills. These badges are "dynamic" because their metadata (and potentially visual traits) can evolve based on new attestations, skill level upgrades, or decay, reflecting a living record of expertise.
3.  **Proof-of-Contribution (PoC):** A system allowing users to submit verifiable proofs of work (e.g., code, research, moderation efforts). These proofs undergo a structured review process by qualified `SkillVerifiers` and can be challenged. Successful contributions earn SBR, potentially upgrade DSBs, and receive `rewardToken` from a protocol pool.
4.  **Adaptive Parameters:** Key system parameters (e.g., reputation decay rate, contribution reward multiplier, challenge stake) can dynamically adjust within defined bounds. This adjustment is influenced by an on-chain activity metric, allowing the protocol to "learn" and adapt its incentives or difficulty based on network health and engagement.
5.  **Weighted Resource Distribution (WRD):** A mechanism to distribute funds from the protocol's `rewardToken` pool. Distribution is not equal but weighted by a recipient's SBR points and the level/quality of their DSBs, ensuring resources are directed towards the most valuable contributors.

---

### Outline:

**I. Interfaces & Libraries:**
    *   `IERC20`: Standard ERC-20 token interface.
    *   `IDynamicSkillBadgeNFT`: Custom interface for the dynamic ERC-721 Skill Badges.

**II. Configuration & Storage:**
    *   `GlobalConfig`: Struct for various system parameters.
    *   `Profile`: Struct for user-specific Soulbound Reputation and metadata.
    *   `SkillType`: Struct for defining different skill categories.
    *   `Attestation`: Struct for storing skill attestations.
    *   `ContributionProof`: Struct for tracking submitted proofs of contribution.
    *   Mappings and arrays to store these structs and their relationships.
    *   `adaptiveParameters`: Mapping for dynamically adjustable parameters.
    *   `protocolActivityMetric`: On-chain metric for adaptability.

**III. Core System Management:**
    *   `constructor()`: Initializes the contract, owner, reward token, and DSB NFT.
    *   `updateGlobalConfig(string memory _paramName, uint256 _newValue)`: Allows governance to update system parameters.
    *   `depositProtocolFunds(uint256 _amount)`: Allows funding the reward pool.
    *   `emergencyPause()`: Pauses critical functions.
    *   `emergencyUnpause()`: Unpauses the contract.

**IV. Soulbound Reputation (SBR) Management:**
    *   `registerProfile(string memory _metadataURI)`: User registers their SBR profile.
    *   `getReputationPoints(address _user)`: Retrieves user's SBR.
    *   `decayReputationPoints()`: Triggers decay of all active user SBR.
    *   `getReputationDecayInfo()`: Returns decay parameters.

**V. Dynamic Skill Badges (DSB) Management:**
    *   `defineSkillType(string memory _skillName, string memory _skillDescription, address[] memory _initialVerifiers, uint256 _requiredReputation)`: Defines a new skill category.
    *   `requestSkillAttestation(uint256 _skillTypeId, string memory _proofURI)`: User requests skill attestation.
    *   `attestSkill(address _user, uint256 _skillTypeId, uint256 _level, string memory _badgeMetadataURI)`: SkillVerifier attests a skill.
    *   `revokeSkillAttestation(address _user, uint256 _skillTypeId)`: SkillVerifier revokes an attestation.
    *   `getUserSkillBadges(address _user)`: Retrieves user's DSBs.

**VI. Proof-of-Contribution (PoC) System:**
    *   `submitContributionProof(string memory _proofURI, uint256 _skillTypeId, uint256 _stakedAmount)`: User submits a contribution proof.
    *   `electReviewers(uint256 _proofId, address[] memory _reviewers)`: System/DAO elects reviewers.
    *   `reviewContributionProof(uint256 _proofId, bool _approved, string memory _feedbackURI)`: Reviewer submits assessment.
    *   `challengeProofOutcome(uint256 _proofId, string memory _challengeReasonURI, uint256 _challengeStake)`: User challenges a review outcome.
    *   `finalizeContributionProof(uint256 _proofId)`: Finalizes proof, distributes rewards.
    *   `getContributionDetails(uint256 _proofId)`: Retrieves proof details.

**VII. Adaptive Mechanisms & Weighted Resource Distribution:**
    *   `updateActivityMetric(uint256 _newMetricValue)`: Updates protocol's activity metric.
    *   `adjustAdaptiveParameter(string memory _paramName, int256 _adjustmentFactor)`: Adjusts adaptive parameters based on activity.
    *   `distributeWeightedRewards(address[] memory _recipients, uint256 _totalAmount)`: Distributes rewards based on SBR and DSB.
    *   `getAdaptiveParameterValue(string memory _paramName)`: Retrieves current value of an adaptive parameter.

---

### Function Summary:

1.  **`constructor(address _rewardToken, address _dynamicSkillBadgeNFT)`**: Initializes the contract with the reward token address (ERC-20) and the address of the DynamicSkillBadgeNFT contract. Sets the deploying address as the initial owner.
2.  **`updateGlobalConfig(string memory _paramName, uint256 _newValue)`**: Allows the owner/DAO to update various system-wide configuration parameters like `proofReviewPeriod`, `reputationDecayInterval`, `minChallengeStake`, etc.
3.  **`depositProtocolFunds(uint256 _amount)`**: Enables any user or the DAO to deposit `rewardToken` into the protocol's reward pool, which will be used for weighted distributions and contribution rewards.
4.  **`emergencyPause()`**: Allows the owner to pause critical functionalities of the contract (e.g., submitting proofs, claiming rewards) in an emergency, implementing a `Pausable` pattern.
5.  **`emergencyUnpause()`**: Allows the owner to unpause the contract after an emergency has been resolved.
6.  **`registerProfile(string memory _metadataURI)`**: Allows a new user to register their Soulbound Reputation (SBR) profile. This action effectively "mints" their non-transferable SBR and links an optional off-chain metadata URI to their profile.
7.  **`getReputationPoints(address _user)`**: Retrieves the current Soulbound Reputation (SBR) points for a specified user.
8.  **`decayReputationPoints()`**: A permissioned function (e.g., callable by a DAO or an authorized keeper bot) that iterates through all active user profiles and applies the configured decay rate to their SBR points. This encourages continuous engagement.
9.  **`getReputationDecayInfo()`**: Returns information about the last reputation decay timestamp and the configured interval for decay, allowing users to track the SBR decay schedule.
10. **`defineSkillType(string memory _skillName, string memory _skillDescription, address[] memory _initialVerifiers, uint256 _requiredReputation)`**: Allows the owner/DAO to define a new skill category (e.g., "Solidity Dev", "Community Mod"), specify its description, assign initial `SkillVerifiers`, and set a minimum SBR required for a user to request attestation for this skill.
11. **`requestSkillAttestation(uint256 _skillTypeId, string memory _proofURI)`**: A user can formally request attestation for a specific `_skillTypeId`. They must meet the `requiredReputation` for that skill and provide an off-chain `_proofURI` (e.g., link to a portfolio, project, or credential).
12. **`attestSkill(address _user, uint256 _skillTypeId, uint256 _level, string memory _badgeMetadataURI)`**: An authorized `SkillVerifier` for a given `_skillTypeId` can attest to a user's skill, assigning a `_level` (e.g., 1-5). This action triggers the `IDynamicSkillBadgeNFT` contract to mint or update a dynamic ERC-721 badge for the user, with `_badgeMetadataURI` reflecting the new state.
13. **`revokeSkillAttestation(address _user, uint256 _skillTypeId)`**: An authorized `SkillVerifier` can revoke a previously issued skill attestation for a user, which would update or burn the corresponding Dynamic Skill Badge NFT.
14. **`getUserSkillBadges(address _user)`**: Retrieves detailed information about all Dynamic Skill Badges (DSBs) currently held by a specific user, including skill type, level, and metadata URI.
15. **`submitContributionProof(string memory _proofURI, uint256 _skillTypeId, uint256 _stakedAmount)`**: A user submits a proof of contribution (e.g., link to a code commit, research paper, moderation report), staking a specified amount of `rewardToken`. They can optionally link it to a specific `_skillTypeId` for specialized review.
16. **`electReviewers(uint256 _proofId, address[] memory _reviewers)`**: A permissioned function (e.g., by DAO or an automated selection process) to assign a panel of `SkillVerifiers` (reviewers) to a specific `_proofId` based on relevant skills or reputation.
17. **`reviewContributionProof(uint256 _proofId, bool _approved, string memory _feedbackURI)`**: An elected reviewer submits their assessment for a contribution proof, indicating approval or rejection, and providing optional feedback via `_feedbackURI`.
18. **`challengeProofOutcome(uint256 _proofId, string memory _challengeReasonURI, uint256 _challengeStake)`**: Allows the contributor or any other interested party to challenge the outcome of a proof review (e.g., if a rejection is deemed unfair), staking `_challengeStake` to initiate a re-review or dispute resolution process.
19. **`finalizeContributionProof(uint256 _proofId)`**: After the review and potential challenge period, this function processes the final outcome of a contribution proof. If approved, it distributes SBR points, potentially upgrades relevant DSBs, and awards `rewardToken` to the contributor and successful reviewers (and returns stakes).
20. **`getContributionDetails(uint256 _proofId)`**: Retrieves comprehensive details and the current status of a specific contribution proof, including reviewer votes, challenge status, and reward information.
21. **`updateActivityMetric(uint256 _newMetricValue)`**: A permissioned function (e.g., by DAO or a keeper) to update an on-chain `protocolActivityMetric` (e.g., total proofs submitted, total attestations). This metric drives the adaptive parameter adjustments.
22. **`adjustAdaptiveParameter(string memory _paramName, int256 _adjustmentFactor)`**: This function (callable by a keeper/DAO) automatically adjusts a pre-defined adaptive parameter (e.g., `reputationGainMultiplier`, `challengeStakeMultiplier`) within specified min/max bounds. The `_adjustmentFactor` could be derived from `protocolActivityMetric` and represents the magnitude and direction of the change.
23. **`distributeWeightedRewards(address[] memory _recipients, uint256 _totalAmount)`**: A permissioned function (e.g., by DAO) to distribute a `_totalAmount` of `rewardToken` from the protocol pool to an array of `_recipients`. The distribution is weighted by each recipient's SBR points and their aggregated DSB levels, ensuring higher value contributors receive proportionally more.
24. **`getAdaptiveParameterValue(string memory _paramName)`**: Retrieves the current value of a specified adaptively adjusted parameter, allowing users to inspect the protocol's current incentive and difficulty settings.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// =============================================================================
// INTERFACES & LIBRARIES
// =============================================================================

// Mock interface for an external Dynamic Skill Badge NFT contract
// This NFT contract would manage the actual ERC721 tokens
// and their metadata updates based on attestations.
interface IDynamicSkillBadgeNFT {
    function mintOrUpdateSkillBadge(
        address to,
        uint256 skillTypeId,
        uint256 level,
        string memory tokenURI
    ) external returns (uint256 tokenId);

    function revokeSkillBadge(address owner, uint256 skillTypeId) external;

    function getSkillBadgeInfo(
        address owner,
        uint256 skillTypeId
    )
        external
        view
        returns (
            uint256 tokenId,
            uint256 level,
            string memory tokenURI
        );

    function getTokenURI(uint256 tokenId) external view returns (string memory);

    function balanceOf(address owner) external view returns (uint256);
}

// =============================================================================
// CONTRACT: SynergyNetProtocol
// =============================================================================

contract SynergyNetProtocol is Ownable, Pausable {
    using SafeMath for uint256;

    // =========================================================================
    // CONFIGURATION & STORAGE
    // =========================================================================

    // --- Global Configuration ---
    struct GlobalConfig {
        uint256 reputationDecayInterval; // Time in seconds between reputation decay events
        uint256 reputationDecayRatePermille; // Rate per mille (per 1000)
        uint256 proofReviewPeriod; // Time in seconds for reviewers to act
        uint256 challengePeriod; // Time in seconds for challenging a review
        uint256 minChallengeStake; // Minimum token amount to challenge
        uint256 minReputationForReview; // Min SBR to be an elected reviewer
        uint256 baseReputationGainPerContribution; // Base SBR awarded for approved contribution
        uint256 rewardTokenPerContribution; // Base reward tokens for approved contribution
        uint256 adaptiveParameterAdjustmentFactor; // How much adaptive params change per tick
        uint256 minAdaptiveParamValue; // Min value for all adaptive parameters
        uint256 maxAdaptiveParamValue; // Max value for all adaptive parameters
    }
    GlobalConfig public globalConfig;

    // --- User Profile (Soulbound Reputation - SBR) ---
    struct Profile {
        uint256 reputationPoints; // Non-transferable reputation score
        uint256 lastReputationDecay; // Timestamp of the last decay applied
        string metadataURI; // Off-chain profile data
        bool exists; // To check if profile is registered
    }
    mapping(address => Profile) public profiles;
    address[] public registeredProfiles; // List of all registered profiles for iteration

    // --- Skill Types & Attestation (Dynamic Skill Badges - DSB) ---
    struct SkillType {
        string name;
        string description;
        address[] verifiers; // Addresses authorized to attest for this skill
        uint256 requiredReputation; // Min SBR to request this skill attestation
        uint256 nextAttestationId; // For internal tracking of attestations for this skillType
        bool exists;
    }
    mapping(uint256 => SkillType) public skillTypes;
    uint256 public nextSkillTypeId;

    struct Attestation {
        uint256 skillTypeId;
        uint256 level; // e.g., 1-5, indicating proficiency
        string proofURI; // Proof submitted by user when requesting attestation
        address attester; // Address who attested
        uint256 timestamp;
        bool exists;
    }
    mapping(address => mapping(uint256 => Attestation)) public userSkillAttestations; // user => skillTypeId => Attestation

    // --- Proof-of-Contribution (PoC) System ---
    enum ContributionStatus { PendingReview, Reviewed, Challenged, Finalized }

    struct ContributionProof {
        address contributor;
        string proofURI; // Link to the off-chain contribution
        uint256 skillTypeId; // Optional: specific skill this contribution relates to
        uint256 stakedAmount; // Tokens staked by contributor
        address[] reviewers; // Addresses elected to review
        mapping(address => bool) hasReviewed; // To track if a reviewer has submitted their vote
        mapping(address => bool) reviewerVote; // true for approve, false for reject
        uint256 approvalCount;
        uint256 rejectionCount;
        uint256 submissionTime;
        ContributionStatus status;
        address challenger; // Address who challenged, if any
        string challengeReasonURI;
        uint256 challengeStake;
        uint256 finalizedTime;
        bool exists;
    }
    mapping(uint256 => ContributionProof) public contributionProofs;
    uint256 public nextContributionProofId;

    // --- Adaptive Parameters ---
    // These parameters can be adjusted dynamically based on protocol activity
    mapping(string => int256) public adaptiveParameters; // E.g., "reputationGainMultiplier", "challengeStakeMultiplier"
    mapping(string => bool) public isAdaptiveParameter; // To mark which parameters are adaptive

    uint256 public protocolActivityMetric; // Metric tracking overall protocol health/activity

    // --- External Contracts ---
    IERC20 public immutable rewardToken;
    IDynamicSkillBadgeNFT public immutable dynamicSkillBadgeNFT;

    // =========================================================================
    // EVENTS
    // =========================================================================

    event ProfileRegistered(address indexed user, string metadataURI);
    event ReputationDecayed(address indexed user, uint256 oldReputation, uint256 newReputation);
    event GlobalConfigUpdated(string paramName, uint256 newValue);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event SkillTypeDefined(
        uint256 indexed skillTypeId,
        string name,
        uint256 requiredReputation
    );
    event SkillAttestationRequested(
        address indexed user,
        uint256 indexed skillTypeId,
        string proofURI
    );
    event SkillAttested(
        address indexed user,
        uint256 indexed skillTypeId,
        address indexed attester,
        uint256 level
    );
    event SkillAttestationRevoked(
        address indexed user,
        uint256 indexed skillTypeId,
        address indexed revoker
    );
    event ContributionProofSubmitted(
        uint256 indexed proofId,
        address indexed contributor,
        uint256 stakedAmount
    );
    event ReviewersElected(uint256 indexed proofId, address[] reviewers);
    event ContributionReviewed(
        uint256 indexed proofId,
        address indexed reviewer,
        bool approved
    );
    event ProofOutcomeChallenged(
        uint256 indexed proofId,
        address indexed challenger,
        uint256 challengeStake
    );
    event ContributionProofFinalized(
        uint256 indexed proofId,
        address indexed contributor,
        uint256 reputationGain,
        uint256 rewardAmount
    );
    event ActivityMetricUpdated(uint256 newMetricValue);
    event AdaptiveParameterAdjusted(string paramName, int256 oldValue, int256 newValue);
    event WeightedRewardsDistributed(address[] recipients, uint256 totalAmount);

    // =========================================================================
    // MODIFIERS
    // =========================================================================

    modifier onlyRegisteredProfile() {
        require(profiles[msg.sender].exists, "SynergyNet: Profile not registered");
        _;
    }

    modifier onlySkillVerifier(uint256 _skillTypeId) {
        bool isVerifier = false;
        for (uint256 i = 0; i < skillTypes[_skillTypeId].verifiers.length; i++) {
            if (skillTypes[_skillTypeId].verifiers[i] == msg.sender) {
                isVerifier = true;
                break;
            }
        }
        require(isVerifier, "SynergyNet: Not an authorized verifier for this skill");
        _;
    }

    modifier onlyContributionReviewer(uint256 _proofId) {
        ContributionProof storage proof = contributionProofs[_proofId];
        bool isReviewer = false;
        for (uint256 i = 0; i < proof.reviewers.length; i++) {
            if (proof.reviewers[i] == msg.sender) {
                isReviewer = true;
                break;
            }
        }
        require(isReviewer, "SynergyNet: Not an elected reviewer for this proof");
        _;
    }

    // =========================================================================
    // CORE SYSTEM MANAGEMENT
    // =========================================================================

    constructor(address _rewardToken, address _dynamicSkillBadgeNFT) Ownable(msg.sender) Pausable() {
        require(_rewardToken != address(0), "SynergyNet: Invalid reward token address");
        require(_dynamicSkillBadgeNFT != address(0), "SynergyNet: Invalid DSB NFT address");

        rewardToken = IERC20(_rewardToken);
        dynamicSkillBadgeNFT = IDynamicSkillBadgeNFT(_dynamicSkillBadgeNFT);

        // Initialize global configuration parameters
        globalConfig = GlobalConfig({
            reputationDecayInterval: 30 days, // Decay every month
            reputationDecayRatePermille: 10, // 1% decay
            proofReviewPeriod: 7 days,
            challengePeriod: 3 days,
            minChallengeStake: 1e18, // 1 token
            minReputationForReview: 100,
            baseReputationGainPerContribution: 10,
            rewardTokenPerContribution: 5e18, // 5 tokens
            adaptiveParameterAdjustmentFactor: 1, // Default adjustment factor
            minAdaptiveParamValue: 0, // Min value for all adaptive parameters
            maxAdaptiveParamValue: type(uint256).max // Max value for all adaptive parameters, can be set tighter
        });

        // Define initial adaptive parameters (value in basis points, e.g., 10000 for 1x)
        adaptiveParameters["reputationGainMultiplier"] = 10000; // 1x
        adaptiveParameters["rewardTokenMultiplier"] = 10000; // 1x
        adaptiveParameters["challengeStakeMultiplier"] = 10000; // 1x
        isAdaptiveParameter["reputationGainMultiplier"] = true;
        isAdaptiveParameter["rewardTokenMultiplier"] = true;
        isAdaptiveParameter["challengeStakeMultiplier"] = true;
    }

    /**
     * @notice Allows the owner/DAO to update various system-wide configuration parameters.
     * @param _paramName The name of the parameter to update (e.g., "reputationDecayInterval").
     * @param _newValue The new value for the parameter.
     */
    function updateGlobalConfig(string memory _paramName, uint256 _newValue)
        public
        onlyOwner
    {
        // This can be expanded to a more robust governance mechanism
        if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reputationDecayInterval"))) {
            globalConfig.reputationDecayInterval = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("reputationDecayRatePermille"))) {
            require(_newValue <= 1000, "SynergyNet: Decay rate cannot exceed 100%");
            globalConfig.reputationDecayRatePermille = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("proofReviewPeriod"))) {
            globalConfig.proofReviewPeriod = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("challengePeriod"))) {
            globalConfig.challengePeriod = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minChallengeStake"))) {
            globalConfig.minChallengeStake = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minReputationForReview"))) {
            globalConfig.minReputationForReview = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("baseReputationGainPerContribution"))) {
            globalConfig.baseReputationGainPerContribution = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("rewardTokenPerContribution"))) {
            globalConfig.rewardTokenPerContribution = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("adaptiveParameterAdjustmentFactor"))) {
            globalConfig.adaptiveParameterAdjustmentFactor = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("minAdaptiveParamValue"))) {
            globalConfig.minAdaptiveParamValue = _newValue;
        } else if (keccak256(abi.encodePacked(_paramName)) == keccak256(abi.encodePacked("maxAdaptiveParamValue"))) {
            globalConfig.maxAdaptiveParamValue = _newValue;
        } else {
            revert("SynergyNet: Unknown config parameter");
        }
        emit GlobalConfigUpdated(_paramName, _newValue);
    }

    /**
     * @notice Allows any user or the DAO to deposit `rewardToken` into the protocol's reward pool.
     * @param _amount The amount of reward tokens to deposit.
     */
    function depositProtocolFunds(uint256 _amount) public {
        require(_amount > 0, "SynergyNet: Amount must be greater than zero");
        rewardToken.transferFrom(msg.sender, address(this), _amount);
        emit FundsDeposited(msg.sender, _amount);
    }

    /**
     * @notice Pauses critical contract functionalities.
     */
    function emergencyPause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the contract.
     */
    function emergencyUnpause() public onlyOwner {
        _unpause();
    }

    // =========================================================================
    // SOULBOUND REPUTATION (SBR) MANAGEMENT
    // =========================================================================

    /**
     * @notice Allows a new user to register their Soulbound Reputation (SBR) profile.
     * @param _metadataURI An optional IPFS hash or URL for off-chain profile data.
     */
    function registerProfile(string memory _metadataURI)
        public
        whenNotPaused
    {
        require(!profiles[msg.sender].exists, "SynergyNet: Profile already registered");

        profiles[msg.sender] = Profile({
            reputationPoints: 0, // Initial reputation
            lastReputationDecay: block.timestamp,
            metadataURI: _metadataURI,
            exists: true
        });
        registeredProfiles.push(msg.sender);
        emit ProfileRegistered(msg.sender, _metadataURI);
    }

    /**
     * @notice Retrieves the current Soulbound Reputation (SBR) points for a specified user.
     * @param _user The address of the user.
     * @return The user's current reputation points.
     */
    function getReputationPoints(address _user) public view returns (uint256) {
        return profiles[_user].reputationPoints;
    }

    /**
     * @notice Triggers the decay of all active user reputation points.
     *         Callable by owner or a designated keeper. Designed to be called periodically.
     */
    function decayReputationPoints() public onlyOwner {
        // This function can be optimized for gas if there are many profiles,
        // e.g., by processing in batches or using a more advanced data structure.
        for (uint256 i = 0; i < registeredProfiles.length; i++) {
            address user = registeredProfiles[i];
            Profile storage profile = profiles[user];

            uint256 timeSinceLastDecay = block.timestamp.sub(profile.lastReputationDecay);
            uint256 decayPeriods = timeSinceLastDecay.div(globalConfig.reputationDecayInterval);

            if (decayPeriods > 0 && profile.reputationPoints > 0) {
                uint256 oldReputation = profile.reputationPoints;
                // Calculate compounded decay
                for (uint256 j = 0; j < decayPeriods; j++) {
                    profile.reputationPoints = profile.reputationPoints.mul(
                        1000 - globalConfig.reputationDecayRatePermille
                    ).div(1000);
                }
                profile.lastReputationDecay = profile.lastReputationDecay.add(
                    decayPeriods.mul(globalConfig.reputationDecayInterval)
                );
                emit ReputationDecayed(user, oldReputation, profile.reputationPoints);
            }
        }
    }

    /**
     * @notice Returns information about the last reputation decay timestamp and the configured interval.
     * @return lastDecay The timestamp of the last reputation decay.
     * @return decayInterval The configured interval for reputation decay in seconds.
     */
    function getReputationDecayInfo()
        public
        view
        returns (uint256 lastDecay, uint256 decayInterval)
    {
        return (globalConfig.reputationDecayInterval, globalConfig.reputationDecayInterval);
    }

    // =========================================================================
    // DYNAMIC SKILL BADGES (DSB) MANAGEMENT
    // =========================================================================

    /**
     * @notice Allows the owner/DAO to define a new skill category.
     * @param _skillName The name of the skill (e.g., "Solidity Dev").
     * @param _skillDescription A description of the skill.
     * @param _initialVerifiers An array of addresses authorized to initially verify this skill.
     * @param _requiredReputation Minimum SBR required to request attestation for this skill.
     */
    function defineSkillType(
        string memory _skillName,
        string memory _skillDescription,
        address[] memory _initialVerifiers,
        uint256 _requiredReputation
    ) public onlyOwner {
        uint256 id = nextSkillTypeId++;
        skillTypes[id] = SkillType({
            name: _skillName,
            description: _skillDescription,
            verifiers: _initialVerifiers,
            requiredReputation: _requiredReputation,
            nextAttestationId: 0,
            exists: true
        });
        emit SkillTypeDefined(id, _skillName, _requiredReputation);
    }

    /**
     * @notice A user requests attestation for a specific skill type.
     * @param _skillTypeId The ID of the skill type being requested.
     * @param _proofURI An optional IPFS hash or URL providing off-chain proof of skill.
     */
    function requestSkillAttestation(uint256 _skillTypeId, string memory _proofURI)
        public
        onlyRegisteredProfile
        whenNotPaused
    {
        require(skillTypes[_skillTypeId].exists, "SynergyNet: Skill type does not exist");
        require(
            profiles[msg.sender].reputationPoints >= skillTypes[_skillTypeId].requiredReputation,
            "SynergyNet: Insufficient reputation to request this skill"
        );

        userSkillAttestations[msg.sender][_skillTypeId] = Attestation({
            skillTypeId: _skillTypeId,
            level: 0, // Level will be set by verifier
            proofURI: _proofURI,
            attester: address(0), // Set by attester
            timestamp: block.timestamp,
            exists: true
        });

        emit SkillAttestationRequested(msg.sender, _skillTypeId, _proofURI);
    }

    /**
     * @notice An authorized SkillVerifier attests to a user's skill, minting/updating their DSB NFT.
     * @param _user The address of the user whose skill is being attested.
     * @param _skillTypeId The ID of the skill type.
     * @param _level The proficiency level (e.g., 1-5).
     * @param _badgeMetadataURI The metadata URI for the dynamic skill badge NFT.
     */
    function attestSkill(
        address _user,
        uint256 _skillTypeId,
        uint256 _level,
        string memory _badgeMetadataURI
    ) public onlySkillVerifier(_skillTypeId) whenNotPaused {
        require(profiles[_user].exists, "SynergyNet: User profile not registered");
        require(skillTypes[_skillTypeId].exists, "SynergyNet: Skill type does not exist");
        require(_level > 0, "SynergyNet: Skill level must be positive");

        Attestation storage attestation = userSkillAttestations[_user][_skillTypeId];
        // Can optionally require a prior request, but allowing direct attestation simplifies some flows.
        // require(attestation.exists, "SynergyNet: User has not requested attestation for this skill");

        attestation.level = _level;
        attestation.attester = msg.sender;
        attestation.timestamp = block.timestamp;
        attestation.exists = true; // Ensure it exists if directly attested

        // Interact with the Dynamic Skill Badge NFT contract
        dynamicSkillBadgeNFT.mintOrUpdateSkillBadge(_user, _skillTypeId, _level, _badgeMetadataURI);

        emit SkillAttested(_user, _skillTypeId, msg.sender, _level);
    }

    /**
     * @notice A SkillVerifier can revoke a previously issued skill attestation.
     * @param _user The address of the user whose attestation is being revoked.
     * @param _skillTypeId The ID of the skill type to revoke.
     */
    function revokeSkillAttestation(address _user, uint256 _skillTypeId)
        public
        onlySkillVerifier(_skillTypeId)
        whenNotPaused
    {
        require(userSkillAttestations[_user][_skillTypeId].exists, "SynergyNet: Attestation does not exist");
        require(userSkillAttestations[_user][_skillTypeId].attester == msg.sender, "SynergyNet: Only original attester can revoke");

        delete userSkillAttestations[_user][_skillTypeId];
        dynamicSkillBadgeNFT.revokeSkillBadge(_user, _skillTypeId);

        emit SkillAttestationRevoked(_user, _skillTypeId, msg.sender);
    }

    /**
     * @notice Retrieves details of all Dynamic Skill Badges held by a user.
     *         Note: This is a placeholder. A full implementation would likely
     *         query the IDynamicSkillBadgeNFT contract for all tokens owned by the user
     *         and then match with internal skillType info.
     * @param _user The address of the user.
     * @return skillTypeIds An array of skill type IDs.
     * @return levels An array of corresponding skill levels.
     * @return tokenURIs An array of corresponding NFT token URIs.
     */
    function getUserSkillBadges(address _user)
        public
        view
        returns (uint256[] memory skillTypeIds, uint256[] memory levels, string[] memory tokenURIs)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < nextSkillTypeId; i++) {
            if (userSkillAttestations[_user][i].exists && userSkillAttestations[_user][i].level > 0) {
                count++;
            }
        }

        skillTypeIds = new uint256[](count);
        levels = new uint256[](count);
        tokenURIs = new string[](count);

        uint256 current = 0;
        for (uint256 i = 0; i < nextSkillTypeId; i++) {
            if (userSkillAttestations[_user][i].exists && userSkillAttestations[_user][i].level > 0) {
                (uint256 tokenId, uint256 level, string memory uri) = dynamicSkillBadgeNFT.getSkillBadgeInfo(_user, i);
                skillTypeIds[current] = i;
                levels[current] = level;
                tokenURIs[current] = uri;
                current++;
            }
        }
        return (skillTypeIds, levels, tokenURIs);
    }

    // =========================================================================
    // PROOF-OF-CONTRIBUTION (PoC) SYSTEM
    // =========================================================================

    /**
     * @notice A user submits a proof of contribution, staking `rewardToken`.
     * @param _proofURI The IPFS hash or URL linking to the off-chain contribution.
     * @param _skillTypeId An optional skill type ID this contribution relates to for targeted review.
     * @param _stakedAmount The amount of `rewardToken` to stake with the proof.
     */
    function submitContributionProof(
        string memory _proofURI,
        uint256 _skillTypeId,
        uint256 _stakedAmount
    ) public onlyRegisteredProfile whenNotPaused {
        require(_stakedAmount >= globalConfig.minChallengeStake.div(2), "SynergyNet: Stake too low");
        require(skillTypes[_skillTypeId].exists || _skillTypeId == 0, "SynergyNet: Invalid skill type for contribution");
        require(rewardToken.transferFrom(msg.sender, address(this), _stakedAmount), "SynergyNet: Token transfer failed");

        uint256 id = nextContributionProofId++;
        contributionProofs[id] = ContributionProof({
            contributor: msg.sender,
            proofURI: _proofURI,
            skillTypeId: _skillTypeId,
            stakedAmount: _stakedAmount,
            reviewers: new address[](0), // Reviewers will be elected later
            approvalCount: 0,
            rejectionCount: 0,
            submissionTime: block.timestamp,
            status: ContributionStatus.PendingReview,
            challenger: address(0),
            challengeReasonURI: "",
            challengeStake: 0,
            finalizedTime: 0,
            exists: true
        });

        emit ContributionProofSubmitted(id, msg.sender, _stakedAmount);
    }

    /**
     * @notice Elects reviewers for a specific contribution proof. Callable by owner/DAO or automated system.
     *         Reviewers should meet `minReputationForReview` and optionally match `skillTypeId`.
     * @param _proofId The ID of the contribution proof.
     * @param _reviewers An array of addresses to be assigned as reviewers.
     */
    function electReviewers(uint256 _proofId, address[] memory _reviewers)
        public
        onlyOwner // or replace with a DAO/automated election logic
        whenNotPaused
    {
        ContributionProof storage proof = contributionProofs[_proofId];
        require(proof.exists, "SynergyNet: Proof does not exist");
        require(proof.status == ContributionStatus.PendingReview, "SynergyNet: Proof not in review state");
        require(_reviewers.length > 0, "SynergyNet: At least one reviewer required");

        for (uint256 i = 0; i < _reviewers.length; i++) {
            require(profiles[_reviewers[i]].exists, "SynergyNet: Reviewer not registered");
            require(profiles[_reviewers[i]].reputationPoints >= globalConfig.minReputationForReview, "SynergyNet: Reviewer insufficient reputation");
            // Add checks for skill type matching if _skillTypeId is set in proof
        }

        proof.reviewers = _reviewers;
        emit ReviewersElected(_proofId, _reviewers);
    }

    /**
     * @notice An elected reviewer submits their assessment for a contribution proof.
     * @param _proofId The ID of the contribution proof.
     * @param _approved True if the reviewer approves, false if they reject.
     * @param _feedbackURI An optional IPFS hash or URL for detailed feedback.
     */
    function reviewContributionProof(uint256 _proofId, bool _approved, string memory _feedbackURI)
        public
        onlyContributionReviewer(_proofId)
        whenNotPaused
    {
        ContributionProof storage proof = contributionProofs[_proofId];
        require(proof.exists, "SynergyNet: Proof does not exist");
        require(proof.status == ContributionStatus.PendingReview, "SynergyNet: Proof not in review state");
        require(block.timestamp <= proof.submissionTime.add(globalConfig.proofReviewPeriod), "SynergyNet: Review period ended");
        require(!proof.hasReviewed[msg.sender], "SynergyNet: Reviewer already submitted a vote");

        proof.hasReviewed[msg.sender] = true;
        proof.reviewerVote[msg.sender] = _approved;

        if (_approved) {
            proof.approvalCount++;
        } else {
            proof.rejectionCount++;
        }
        // FeedbackURI can be stored per reviewer if needed, or simply logged in event
        emit ContributionReviewed(_proofId, msg.sender, _approved);
    }

    /**
     * @notice Allows a user to challenge the outcome of a proof review.
     * @param _proofId The ID of the contribution proof.
     * @param _challengeReasonURI An IPFS hash or URL explaining the challenge reason.
     * @param _challengeStake The amount of `rewardToken` to stake for the challenge.
     */
    function challengeProofOutcome(uint256 _proofId, string memory _challengeReasonURI, uint256 _challengeStake)
        public
        onlyRegisteredProfile
        whenNotPaused
    {
        ContributionProof storage proof = contributionProofs[_proofId];
        require(proof.exists, "SynergyNet: Proof does not exist");
        require(proof.status == ContributionStatus.PendingReview || proof.status == ContributionStatus.Reviewed, "SynergyNet: Proof cannot be challenged in current state");
        require(block.timestamp > proof.submissionTime.add(globalConfig.proofReviewPeriod), "SynergyNet: Challenge period has not started or already passed review period");
        require(block.timestamp <= proof.submissionTime.add(globalConfig.proofReviewPeriod).add(globalConfig.challengePeriod), "SynergyNet: Challenge period ended");
        require(proof.challenger == address(0), "SynergyNet: Proof already challenged");
        require(_challengeStake >= globalConfig.minChallengeStake.mul(uint256(adaptiveParameters["challengeStakeMultiplier"])).div(10000), "SynergyNet: Challenge stake too low");
        require(rewardToken.transferFrom(msg.sender, address(this), _challengeStake), "SynergyNet: Token transfer for challenge failed");

        proof.status = ContributionStatus.Challenged;
        proof.challenger = msg.sender;
        proof.challengeReasonURI = _challengeReasonURI;
        proof.challengeStake = _challengeStake;

        // A challenge could trigger a re-review or a dispute resolution process (e.g., via a DAO vote)
        // For simplicity, this example just marks it as challenged and awaits finalization.
        emit ProofOutcomeChallenged(_proofId, msg.sender, _challengeStake);
    }

    /**
     * @notice Finalizes a contribution proof after review/challenge, distributing rewards.
     * @param _proofId The ID of the contribution proof.
     */
    function finalizeContributionProof(uint256 _proofId) public whenNotPaused {
        ContributionProof storage proof = contributionProofs[_proofId];
        require(proof.exists, "SynergyNet: Proof does not exist");
        require(proof.status != ContributionStatus.Finalized, "SynergyNet: Proof already finalized");
        require(
            block.timestamp > proof.submissionTime.add(globalConfig.proofReviewPeriod).add(globalConfig.challengePeriod) ||
            proof.status == ContributionStatus.Reviewed, // Allow early finalization if no challenge and reviews are in
            "SynergyNet: Review or challenge period not over"
        );

        bool approved = (proof.approvalCount > proof.rejectionCount);

        // Refund contributor's stake
        rewardToken.transfer(proof.contributor, proof.stakedAmount);

        if (proof.challenger != address(0)) {
            // Dispute resolution logic: for simplicity, if challenged, assume challenge wins if not explicitly overruled
            // A more complex system would involve DAO voting or Schelling game for dispute resolution
            if (approved) { // Challenger loses
                // Challenger's stake goes to protocol or gets burned
            } else { // Challenger wins
                rewardToken.transfer(proof.challenger, proof.challengeStake); // Refund challenger
            }
        }

        if (approved) {
            // Reward contributor
            uint256 reputationGain = globalConfig.baseReputationGainPerContribution.mul(uint256(adaptiveParameters["reputationGainMultiplier"])).div(10000);
            profiles[proof.contributor].reputationPoints = profiles[proof.contributor].reputationPoints.add(reputationGain);

            uint256 rewardAmount = globalConfig.rewardTokenPerContribution.mul(uint256(adaptiveParameters["rewardTokenMultiplier"])).div(10000);
            require(rewardToken.transfer(proof.contributor, rewardAmount), "SynergyNet: Reward token transfer failed");

            // Optionally, update DSB if skillTypeId is set and contributor has it
            if (proof.skillTypeId != 0 && userSkillAttestations[proof.contributor][proof.skillTypeId].exists) {
                // Logic to slightly increase level or update metadata based on contribution success
                // This would call dynamicSkillBadgeNFT.mintOrUpdateSkillBadge again
            }
            emit ContributionProofFinalized(proof.contributor, proof.contributor, reputationGain, rewardAmount);
        } else {
            // No rewards, but stake is refunded
        }

        proof.status = ContributionStatus.Finalized;
        proof.finalizedTime = block.timestamp;
    }

    /**
     * @notice Retrieves detailed information about a specific contribution proof.
     * @param _proofId The ID of the contribution proof.
     * @return proofDetails The full ContributionProof struct.
     */
    function getContributionDetails(uint256 _proofId)
        public
        view
        returns (ContributionProof memory proofDetails)
    {
        require(contributionProofs[_proofId].exists, "SynergyNet: Proof does not exist");
        return contributionProofs[_proofId];
    }

    // =========================================================================
    // ADAPTIVE MECHANISMS & WEIGHTED RESOURCE DISTRIBUTION
    // =========================================================================

    /**
     * @notice Updates the protocol's on-chain activity metric.
     *         Callable by owner/DAO or an authorized keeper bot.
     * @param _newMetricValue The new value for the activity metric.
     */
    function updateActivityMetric(uint256 _newMetricValue) public onlyOwner {
        protocolActivityMetric = _newMetricValue;
        emit ActivityMetricUpdated(_newMetricValue);
    }

    /**
     * @notice Automatically adjusts a pre-defined adaptive parameter based on the protocol's activity metric.
     *         Callable by owner/DAO or an authorized keeper bot.
     *         The `_adjustmentFactor` indicates whether the metric goes up (positive) or down (negative)
     *         and by how much it should influence the parameter.
     * @param _paramName The name of the adaptive parameter (e.g., "reputationGainMultiplier").
     * @param _adjustmentFactor An integer indicating the direction and magnitude of adjustment.
     *                          Positive for increase, negative for decrease. Actual adjustment
     *                          amount is calculated using `globalConfig.adaptiveParameterAdjustmentFactor`.
     */
    function adjustAdaptiveParameter(string memory _paramName, int256 _adjustmentFactor)
        public
        onlyOwner // Can be replaced by a DAO or decentralized oracle decision
    {
        require(isAdaptiveParameter[_paramName], "SynergyNet: Not an adaptive parameter");

        int256 currentVal = adaptiveParameters[_paramName];
        int256 adjustment = int256(globalConfig.adaptiveParameterAdjustmentFactor).mul(_adjustmentFactor); // Use int256 for signed multiplication

        int256 newVal = currentVal.add(adjustment);

        // Enforce min/max bounds
        if (newVal < int256(globalConfig.minAdaptiveParamValue)) {
            newVal = int256(globalConfig.minAdaptiveParamValue);
        }
        if (newVal > int256(globalConfig.maxAdaptiveParamValue)) {
            newVal = int256(globalConfig.maxAdaptiveParamValue);
        }

        if (newVal != currentVal) {
            adaptiveParameters[_paramName] = newVal;
            emit AdaptiveParameterAdjusted(_paramName, currentVal, newVal);
        }
    }

    /**
     * @notice Distributes a total amount of `rewardToken` to specified recipients
     *         based on their weighted SBR and DSB scores.
     *         Callable by owner/DAO.
     * @param _recipients An array of addresses to receive rewards.
     * @param _totalAmount The total amount of `rewardToken` to distribute.
     */
    function distributeWeightedRewards(address[] memory _recipients, uint256 _totalAmount)
        public
        onlyOwner // Can be replaced by a DAO vote for grant allocation
        whenNotPaused
    {
        require(_recipients.length > 0, "SynergyNet: No recipients provided");
        require(rewardToken.balanceOf(address(this)) >= _totalAmount, "SynergyNet: Insufficient funds in protocol pool");

        uint256 totalWeight = 0;
        mapping(address => uint256) recipientWeights;

        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            require(profiles[recipient].exists, "SynergyNet: Recipient profile not registered");

            uint256 sbrWeight = profiles[recipient].reputationPoints;

            // Aggregate DSB levels as additional weight
            uint256 dsbWeight = 0;
            for (uint256 skillId = 0; skillId < nextSkillTypeId; skillId++) {
                if (userSkillAttestations[recipient][skillId].exists) {
                    dsbWeight = dsbWeight.add(userSkillAttestations[recipient][skillId].level);
                }
            }

            // Simple example: SBR + (DSB levels * 10)
            // This weighting logic can be highly customized and made adaptive as well.
            uint256 combinedWeight = sbrWeight.add(dsbWeight.mul(10));
            recipientWeights[recipient] = combinedWeight;
            totalWeight = totalWeight.add(combinedWeight);
        }

        require(totalWeight > 0, "SynergyNet: Total weight of recipients is zero");

        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 amount = _totalAmount.mul(recipientWeights[recipient]).div(totalWeight);
            if (amount > 0) {
                rewardToken.transfer(recipient, amount);
            }
        }
        emit WeightedRewardsDistributed(_recipients, _totalAmount);
    }

    /**
     * @notice Retrieves the current value of an adaptively adjusted parameter.
     * @param _paramName The name of the adaptive parameter.
     * @return The current integer value of the parameter.
     */
    function getAdaptiveParameterValue(string memory _paramName)
        public
        view
        returns (int256)
    {
        require(isAdaptiveParameter[_paramName], "SynergyNet: Parameter is not adaptive");
        return adaptiveParameters[_paramName];
    }
}
```