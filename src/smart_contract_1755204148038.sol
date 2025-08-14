Okay, this is an exciting challenge! Let's build a smart contract that goes beyond typical DeFi or NFT patterns. I'll conceptualize a "QuantumLeap Protocol" – a decentralized innovation and reputation network, where "Innovator Profiles" (non-transferable SBTs) propose "Leap Projects" that are funded based on community "Conviction" (a liquid staking mechanism), and where success builds dynamic reputation.

The core idea is to create a dynamic, self-evolving, reputation-driven ecosystem for funding and executing decentralized innovation.

---

## QuantumLeap Protocol (QLP)

**Contract Name:** `QuantumLeap`

**Concept:** The QuantumLeap Protocol is a decentralized innovation accelerator designed to foster groundbreaking projects through a unique combination of Soulbound Tokens (SBTs) for innovator profiles, liquid conviction-based funding, and a dynamic reputation system. It aims to create a verifiable, adaptable, and community-driven ecosystem where meritorious ideas and contributions are rewarded.

**Key Advanced Concepts & Creativity:**

1.  **Dynamic Soulbound Innovator Profiles (d-SIPS):** Non-transferable tokens that evolve. They accrue "Reputation" and "Skill Points" based on successful project contributions and community attestations, acting as on-chain professional identities.
2.  **Conviction-Driven Project Funding:** Instead of one-time voting, users stake tokens for a project over time. The longer and more tokens staked, the higher the "Conviction" for that project, gradually unlocking funds. This encourages long-term alignment.
3.  **Proof-of-Contribution (PoC) Attestations (ZK-Inspired):** A mechanism for innovators to submit verifiable, potentially privacy-preserving (abstractly representing ZK-proofs), attestations of external project milestones or contributions. The contract only stores a hash or a small proof, with full details off-chain.
4.  **Adaptive Protocol Governance:** Key protocol parameters (e.g., conviction decay rate, funding thresholds, reputation decay) can be proposed and voted upon by the community, allowing the protocol to self-tune and evolve.
5.  **Skill Tree & Specialization:** Innovators can declare and develop specific skill sets, which can be leveraged for project matching or specialized roles.
6.  **Epoch-Based Project Lifecycle:** Projects progress through defined phases (Proposal, Conviction, Execution, Evaluation), managed by time-based epochs.
7.  **Decentralized Project Evaluation & Dispute Resolution:** Community can signal project success or challenge failure, with a simplified dispute mechanism.
8.  **Liquid Reputation Delegation:** Innovators can delegate their reputation to another profile, enabling mentorship or group project benefits without transferring the underlying SBT.

---

### Outline and Function Summary

**I. Core Infrastructure & Configuration**
*   `constructor()`: Initializes the contract with an ERC20 token address for funding and initial parameters.
*   `initializeLeapProtocol()`: Allows the owner to set up initial critical parameters after deployment, making it more flexible.
*   `updateProtocolParameter()`: Allows for adaptive governance to modify key protocol parameters based on successful proposals.

**II. Innovator Profile Management (Dynamic Soulbound Tokens)**
*   `mintInnovatorProfile()`: Mints a new, non-transferable `InnovatorProfile` (SBT) for a user, serving as their on-chain identity.
*   `updateInnovatorSkills()`: Allows an innovator to declare and update their skill categories and associated points.
*   `attestContributionProof()`: Allows an innovator to submit a cryptographic proof (or hash) of an off-chain contribution, potentially increasing reputation.
*   `delegateReputation()`: Enables an innovator to temporarily delegate a portion of their reputation to another profile.
*   `revokeReputationDelegation()`: Revokes a previously established reputation delegation.
*   `getInnovatorProfile()`: View function to retrieve details of an `InnovatorProfile`.

**III. Leap Project Lifecycle Management**
*   `proposeLeapProject()`: Allows an innovator to submit a new project proposal, defining its scope, funding goal, and expected outcomes.
*   `catalyzeProjectFunding()`: Enables users to provide initial "catalyst" funds to a project, granting it early momentum and a small "conviction boost."
*   `signalProjectSuccess()`: Allows community members to attest to a project's success.
*   `challengeProjectFailure()`: Allows community members to challenge a project's success or declare its failure.
*   `distributeProjectFunds()`: Releases allocated funds to the project's innovator upon successful completion and community attestation.
*   `getLeapProjectDetails()`: View function to retrieve details of a `LeapProject`.

**IV. Conviction Staking & Funding**
*   `stakeConviction()`: Users stake the designated ERC20 token on a specific project to build "conviction" for its funding.
*   `reallocateConviction()`: Allows users to move their staked conviction from one project to another.
*   `withdrawConviction()`: Allows users to withdraw their staked tokens.
*   `claimConvictionRewards()`: Allows stakers to claim rewards earned for successful projects they supported.
*   `getProjectConviction()`: View function to get the current conviction score for a project.

**V. Rewards & Reputation Dynamics**
*   `claimProjectRewards()`: Allows the innovator of a successful project to claim their allocated rewards.
*   `updateReputationEpoch()`: A function (can be called by anyone or an automated system) to trigger the periodic update of innovator reputations based on their project involvement and contribution attestations.

**VI. Adaptive Governance**
*   `proposeParameterChange()`: Allows the Protocol Council or a sufficiently high-reputation innovator to propose a change to a key protocol parameter.
*   `voteOnParameterChange()`: Allows eligible voters (e.g., high-reputation innovators, conviction stakers) to vote on proposed parameter changes.
*   `executeParameterChange()`: Executes a parameter change proposal once it has passed and its timelock has expired.

**VII. Utility & Safety**
*   `emergencyWithdrawStuckTokens()`: An owner-only function to recover accidentally sent ERC20 tokens.
*   `transferOwnership()`: Transfers contract ownership.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For added safety, though 0.8.0+ has built-in checks
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol"; // For managing unique sets efficiently

/**
 * @title QuantumLeap Protocol (QLP)
 * @dev A decentralized innovation accelerator fostering projects through dynamic Soulbound Innovator Profiles,
 *      conviction-based funding, and a dynamic reputation system.
 *
 * Outline and Function Summary:
 *
 * I. Core Infrastructure & Configuration
 *    - constructor(): Initializes the contract with an ERC20 token address for funding and initial parameters.
 *    - initializeLeapProtocol(): Allows the owner to set up initial critical parameters after deployment.
 *    - updateProtocolParameter(): Allows for adaptive governance to modify key protocol parameters.
 *
 * II. Innovator Profile Management (Dynamic Soulbound Tokens - d-SIPS)
 *    - mintInnovatorProfile(): Mints a new, non-transferable InnovatorProfile (SBT) for a user.
 *    - updateInnovatorSkills(): Allows an innovator to declare and update their skill categories and associated points.
 *    - attestContributionProof(): Allows an innovator to submit a cryptographic proof (or hash) of an off-chain contribution.
 *    - delegateReputation(): Enables an innovator to temporarily delegate a portion of their reputation to another profile.
 *    - revokeReputationDelegation(): Revokes a previously established reputation delegation.
 *    - getInnovatorProfile(): View function to retrieve details of an InnovatorProfile.
 *
 * III. Leap Project Lifecycle Management
 *    - proposeLeapProject(): Allows an innovator to submit a new project proposal.
 *    - catalyzeProjectFunding(): Enables users to provide initial "catalyst" funds to a project.
 *    - signalProjectSuccess(): Allows community members to attest to a project's success.
 *    - challengeProjectFailure(): Allows community members to challenge a project's success or declare its failure.
 *    - distributeProjectFunds(): Releases allocated funds to the project's innovator upon successful completion.
 *    - getLeapProjectDetails(): View function to retrieve details of a LeapProject.
 *
 * IV. Conviction Staking & Funding
 *    - stakeConviction(): Users stake the designated ERC20 token on a specific project.
 *    - reallocateConviction(): Allows users to move their staked conviction from one project to another.
 *    - withdrawConviction(): Allows users to withdraw their staked tokens.
 *    - claimConvictionRewards(): Allows stakers to claim rewards earned for successful projects they supported.
 *    - getProjectConviction(): View function to get the current conviction score for a project.
 *
 * V. Rewards & Reputation Dynamics
 *    - claimProjectRewards(): Allows the innovator of a successful project to claim their allocated rewards.
 *    - updateReputationEpoch(): Triggers the periodic update of innovator reputations.
 *
 * VI. Adaptive Governance
 *    - proposeParameterChange(): Allows eligible entities to propose a change to a key protocol parameter.
 *    - voteOnParameterChange(): Allows eligible voters to vote on proposed parameter changes.
 *    - executeParameterChange(): Executes a parameter change proposal.
 *
 * VII. Utility & Safety
 *    - emergencyWithdrawStuckTokens(): An owner-only function to recover accidentally sent ERC20 tokens.
 *    - transferOwnership(): Transfers contract ownership.
 */
contract QuantumLeap is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    IERC20 public fundingToken;

    // --- Protocol Parameters (Adaptive Governance Controlled) ---
    uint256 public constant MAX_SKILL_CATEGORIES = 10;
    uint256 public constant MAX_PROOF_HASHES_PER_PROFILE = 50;

    // Epochs in seconds
    uint256 public proposalReviewPeriod = 3 days;
    uint256 public convictionAccumulationPeriod = 14 days;
    uint256 public projectExecutionPeriod = 60 days;
    uint256 public evaluationPeriod = 7 days;
    uint256 public reputationUpdateInterval = 30 days; // How often reputation is re-calculated/decayed

    // Funding thresholds and rates
    uint256 public minProjectFundingGoal = 1000e18; // Example: 1000 tokens
    uint256 public convictionFundingRateBasisPoints = 100; // 1% of staked amount per day contributes to conviction score
    uint256 public convictionDecayRateBasisPoints = 5; // 0.05% decay per day if no new stake
    uint256 public projectFundingAllocationBasisPoints = 8000; // 80% of project funds go to innovator
    uint256 public stakerRewardAllocationBasisPoints = 1500; // 15% of project funds to stakers
    uint256 public protocolFeeBasisPoints = 500; // 5% fee for the protocol treasury

    // Reputation dynamics
    uint256 public baseReputationGainOnSuccess = 100; // Base points
    uint256 public reputationDecayBasisPoints = 10; // 0.1% decay per reputation update interval

    // --- Enums & Structs ---

    enum ProjectStatus { Proposed, ConvictionBuilding, Executing, Evaluation, Success, Failed, Challenged }

    enum SkillCategory {
        BlockchainDev, AI_ML, UI_UX, DataScience, Research, Marketing, Legal, Finance, Community, Other
    }

    struct InnovatorProfile {
        bool exists;
        uint256 reputation;
        uint256 lastReputationUpdate;
        mapping(SkillCategory => uint256) skills; // Points in each skill category
        EnumerableSet.AddressSet delegatedReputationFrom; // Addresses delegating reputation to this profile
        EnumerableSet.AddressSet delegatedReputationTo; // Addresses this profile is delegating reputation to
        bytes32[] contributionProofs; // Array of hashes/proofs of external contributions
    }

    struct LeapProject {
        address innovator;
        string name;
        string descriptionURI; // URI to IPFS or similar for detailed description
        uint256 fundingGoal;
        uint256 currentConvictionScore;
        uint256 totalCatalystFunds;
        uint256 fundsRaised; // Total tokens accumulated for project funding from conviction
        ProjectStatus status;
        uint256 proposalTimestamp;
        uint256 convictionStartTimestamp;
        uint256 executionStartTimestamp;
        uint256 evaluationStartTimestamp;
        uint256 finalizationTimestamp;
        mapping(address => uint256) stakerConviction; // Actual staked amount per user
        mapping(address => uint256) lastStakerConvictionUpdate; // To calculate conviction score based on time
        mapping(address => bool) hasSignaledSuccess; // Who signaled success
        mapping(address => bool) hasChallengedFailure; // Who challenged failure
        uint256 successSignals;
        uint256 failureChallenges;
    }

    struct ParameterChangeProposal {
        bytes32 parameterNameHash; // Hash of the parameter name (e.g., keccak256("proposalReviewPeriod"))
        uint256 newValue;
        uint256 proposalTimestamp;
        uint256 votingDeadline;
        uint256 executionTimelock; // Time after voting ends before execution
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        bool executed;
        bool passed;
    }

    // --- State Variables ---
    uint256 public nextInnovatorProfileId = 1; // Start from 1 for non-zero check
    mapping(address => uint256) public innovatorProfileIds; // address => profileId
    mapping(uint256 => InnovatorProfile) public innovatorProfiles; // profileId => InnovatorProfile

    uint256 public nextProjectId = 1;
    mapping(uint256 => LeapProject) public leapProjects;

    mapping(address => uint256) public totalStakedConvictionByUser; // Total tokens staked by a user across all projects
    mapping(uint256 => mapping(address => uint256)) public projectStakerRewards; // projectId => stakerAddress => unclaimedRewards

    uint256 public nextParamProposalId = 1;
    mapping(uint256 => ParameterChangeProposal) public paramChangeProposals;

    // --- Events ---
    event InnovatorProfileMinted(address indexed owner, uint256 indexed profileId);
    event InnovatorSkillsUpdated(uint256 indexed profileId, SkillCategory indexed skill, uint256 points);
    event ContributionProofAttested(uint256 indexed profileId, bytes32 indexed proofHash);
    event ReputationDelegated(address indexed from, address indexed to, uint256 amount);
    event ReputationRevoked(address indexed from, address indexed to);

    event LeapProjectProposed(uint256 indexed projectId, address indexed innovator, uint256 fundingGoal);
    event ProjectCatalyzed(uint256 indexed projectId, address indexed supporter, uint256 amount);
    event ProjectStatusUpdated(uint256 indexed projectId, ProjectStatus newStatus, uint256 timestamp);
    event ProjectFundsDistributed(uint256 indexed projectId, uint256 amount);

    event ConvictionStaked(uint256 indexed projectId, address indexed staker, uint256 amount);
    event ConvictionReallocated(uint256 indexed fromProjectId, uint256 indexed toProjectId, address indexed staker, uint256 amount);
    event ConvictionWithdrawn(uint256 indexed projectId, address indexed staker, uint256 amount);
    event StakerRewardsClaimed(uint256 indexed projectId, address indexed staker, uint256 amount);

    event ProjectSuccessSignaled(uint256 indexed projectId, address indexed signaler);
    event ProjectFailureChallenged(uint256 indexed projectId, address indexed challenger);

    event InnovatorRewardsClaimed(uint256 indexed projectId, address indexed innovator, uint256 amount);
    event ReputationUpdated(uint256 indexed profileId, uint256 newReputation);

    event ParameterChangeProposed(uint256 indexed proposalId, bytes32 indexed paramNameHash, uint256 newValue);
    event ParameterChangeVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ParameterChangeExecuted(uint256 indexed proposalId, bytes32 indexed paramNameHash, uint256 newValue);

    // --- Modifiers ---
    modifier onlyInnovatorProfileOwner(uint256 _profileId) {
        require(innovatorProfileIds[_msgSender()] == _profileId, "QLP: Not owner of this profile");
        _;
    }

    modifier onlyRegisteredInnovator() {
        require(innovatorProfileIds[_msgSender()] != 0, "QLP: Caller is not a registered innovator");
        _;
    }

    modifier onlyProtocolCouncil() {
        // In a real scenario, this would be a multi-sig or DAO governance contract.
        // For simplicity, it's currently just the owner.
        require(owner() == _msgSender(), "QLP: Not a member of the Protocol Council");
        _;
    }

    modifier onlyActiveProject(uint256 _projectId) {
        require(leapProjects[_projectId].status == ProjectStatus.ConvictionBuilding ||
                leapProjects[_projectId].status == ProjectStatus.Executing ||
                leapProjects[_projectId].status == ProjectStatus.Evaluation, "QLP: Project not active");
        _;
    }

    // --- Constructor ---
    constructor(address _fundingTokenAddress) {
        require(_fundingTokenAddress != address(0), "QLP: Funding token address cannot be zero");
        fundingToken = IERC20(_fundingTokenAddress);
    }

    // --- I. Core Infrastructure & Configuration ---

    /**
     * @dev Allows the owner to set up initial critical parameters after deployment.
     *      This is useful for staging or pre-launch configuration. Can only be called once.
     *      After this, parameters are changed via adaptive governance.
     */
    function initializeLeapProtocol(
        uint256 _proposalReviewPeriod,
        uint256 _convictionAccumulationPeriod,
        uint256 _projectExecutionPeriod,
        uint256 _evaluationPeriod,
        uint256 _reputationUpdateInterval,
        uint256 _minProjectFundingGoal
    ) external onlyOwner {
        require(proposalReviewPeriod == 0, "QLP: Protocol already initialized"); // Only allow once

        proposalReviewPeriod = _proposalReviewPeriod;
        convictionAccumulationPeriod = _convictionAccumulationPeriod;
        projectExecutionPeriod = _projectExecutionPeriod;
        evaluationPeriod = _evaluationPeriod;
        reputationUpdateInterval = _reputationUpdateInterval;
        minProjectFundingGoal = _minProjectFundingGoal;
    }

    /**
     * @dev Updates a specific protocol parameter. This function is called by the `executeParameterChange`
     *      function after a successful governance proposal. Direct calls by owner are not allowed
     *      for most parameters to enforce adaptive governance.
     * @param _paramNameHash The keccak256 hash of the parameter name (e.g., keccak256("proposalReviewPeriod"))
     * @param _newValue The new value for the parameter.
     */
    function updateProtocolParameter(bytes32 _paramNameHash, uint256 _newValue) internal {
        // This function is intended to be called ONLY by `executeParameterChange`
        // Ensure only allowed parameters can be updated this way
        if (_paramNameHash == keccak256(abi.encodePacked("proposalReviewPeriod"))) {
            proposalReviewPeriod = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("convictionAccumulationPeriod"))) {
            convictionAccumulationPeriod = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("projectExecutionPeriod"))) {
            projectExecutionPeriod = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("evaluationPeriod"))) {
            evaluationPeriod = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("reputationUpdateInterval"))) {
            reputationUpdateInterval = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("minProjectFundingGoal"))) {
            minProjectFundingGoal = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("convictionFundingRateBasisPoints"))) {
            convictionFundingRateBasisPoints = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("convictionDecayRateBasisPoints"))) {
            convictionDecayRateBasisPoints = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("projectFundingAllocationBasisPoints"))) {
            projectFundingAllocationBasisPoints = _newValue;
            require(_newValue.add(stakerRewardAllocationBasisPoints).add(protocolFeeBasisPoints) <= 10000, "QLP: Allocation sum exceeds 100%");
        } else if (_paramNameHash == keccak256(abi.encodePacked("stakerRewardAllocationBasisPoints"))) {
            stakerRewardAllocationBasisPoints = _newValue;
            require(projectFundingAllocationBasisPoints.add(_newValue).add(protocolFeeBasisPoints) <= 10000, "QLP: Allocation sum exceeds 100%");
        } else if (_paramNameHash == keccak256(abi.encodePacked("protocolFeeBasisPoints"))) {
            protocolFeeBasisPoints = _newValue;
            require(projectFundingAllocationBasisPoints.add(stakerRewardAllocationBasisPoints).add(_newValue) <= 10000, "QLP: Allocation sum exceeds 100%");
        } else if (_paramNameHash == keccak256(abi.encodePacked("baseReputationGainOnSuccess"))) {
            baseReputationGainOnSuccess = _newValue;
        } else if (_paramNameHash == keccak256(abi.encodePacked("reputationDecayBasisPoints"))) {
            reputationDecayBasisPoints = _newValue;
        } else {
            revert("QLP: Invalid parameter name for update");
        }
    }

    // --- II. Innovator Profile Management (Dynamic Soulbound Tokens) ---

    /**
     * @dev Mints a new, non-transferable InnovatorProfile (SBT) for a user.
     *      Each address can only mint one profile.
     */
    function mintInnovatorProfile() external {
        require(innovatorProfileIds[_msgSender()] == 0, "QLP: Already has an innovator profile");

        uint256 profileId = nextInnovatorProfileId++;
        innovatorProfileIds[_msgSender()] = profileId;
        innovatorProfiles[profileId].exists = true;
        innovatorProfiles[profileId].reputation = 0; // Starts with 0 reputation
        innovatorProfiles[profileId].lastReputationUpdate = block.timestamp;

        emit InnovatorProfileMinted(_msgSender(), profileId);
    }

    /**
     * @dev Allows an innovator to declare and update their skill categories and associated points.
     *      Skill points represent proficiency and can influence project matching or roles.
     * @param _skill The SkillCategory to update.
     * @param _points The new points for this skill. Can be 0 to remove proficiency.
     */
    function updateInnovatorSkills(SkillCategory _skill, uint256 _points) external onlyRegisteredInnovator {
        uint256 profileId = innovatorProfileIds[_msgSender()];
        innovatorProfiles[profileId].skills[_skill] = _points;
        emit InnovatorSkillsUpdated(profileId, _skill, _points);
    }

    /**
     * @dev Allows an innovator to submit a cryptographic proof (or hash) of an off-chain contribution.
     *      This is a conceptual representation of verifiable contributions using ZK-proofs or similar.
     *      The contract stores the hash, implying an external verification process confirms the proof.
     * @param _proofHash A cryptographic hash or identifier of the contribution proof.
     */
    function attestContributionProof(bytes32 _proofHash) external onlyRegisteredInnovator {
        uint256 profileId = innovatorProfileIds[_msgSender()];
        InnovatorProfile storage profile = innovatorProfiles[profileId];

        require(profile.contributionProofs.length < MAX_PROOF_HASHES_PER_PROFILE, "QLP: Max contribution proofs reached");

        profile.contributionProofs.push(_proofHash);
        // Reputation could be boosted here, or upon successful verification by a decentralized oracle network.
        // For simplicity, it just records the proof. Actual reputation gain happens on project success.
        emit ContributionProofAttested(profileId, _proofHash);
    }

    /**
     * @dev Enables an innovator to temporarily delegate a portion of their reputation to another profile.
     *      Useful for team projects or mentorship. This does not transfer actual reputation.
     * @param _to The address of the profile to delegate reputation to.
     */
    function delegateReputation(address _to) external onlyRegisteredInnovator {
        require(innovatorProfileIds[_to] != 0, "QLP: Target is not a registered innovator profile");
        require(_to != _msgSender(), "QLP: Cannot delegate reputation to self");

        uint256 fromProfileId = innovatorProfileIds[_msgSender()];
        uint256 toProfileId = innovatorProfileIds[_to];

        require(innovatorProfiles[fromProfileId].delegatedReputationTo.add(_to), "QLP: Already delegating to this address");
        require(innovatorProfiles[toProfileId].delegatedReputationFrom.add(_msgSender()), "QLP: Target already receiving delegation from this address");

        emit ReputationDelegated(_msgSender(), _to, innovatorProfiles[fromProfileId].reputation); // The actual amount delegated would be calculated dynamically
    }

    /**
     * @dev Revokes a previously established reputation delegation.
     * @param _to The address of the profile to revoke delegation from.
     */
    function revokeReputationDelegation(address _to) external onlyRegisteredInnovator {
        uint256 fromProfileId = innovatorProfileIds[_msgSender()];
        uint256 toProfileId = innovatorProfileIds[_to];

        require(innovatorProfiles[fromProfileId].delegatedReputationTo.remove(_to), "QLP: Not currently delegating to this address");
        require(innovatorProfiles[toProfileId].delegatedReputationFrom.remove(_msgSender()), "QLP: Target was not receiving delegation from this address");

        emit ReputationRevoked(_msgSender(), _to);
    }

    /**
     * @dev Retrieves the details of an Innovator Profile.
     * @param _profileId The ID of the innovator profile.
     * @return innovator The address of the innovator.
     * @return reputation The current reputation score.
     * @return lastReputationUpdate The timestamp of the last reputation update.
     * @return skillCategories The array of skill categories associated with the profile.
     * @return skillPoints The corresponding array of skill points for each category.
     * @return contributionProofHashes An array of stored contribution proof hashes.
     */
    function getInnovatorProfile(uint256 _profileId)
        external
        view
        returns (
            address innovator,
            uint256 reputation,
            uint256 lastReputationUpdate,
            SkillCategory[] memory skillCategories,
            uint256[] memory skillPoints,
            bytes32[] memory contributionProofHashes
        )
    {
        require(innovatorProfiles[_profileId].exists, "QLP: Profile does not exist");
        InnovatorProfile storage profile = innovatorProfiles[_profileId];

        innovator = address(0); // Find innovator address by iterating map values if needed, or by specific storage. Not directly stored in struct.
        // For actual innovator address, one would need a reverse mapping: profileId => address
        // As a shortcut, we can check if the caller owns it
        if (innovatorProfileIds[_msgSender()] == _profileId) {
            innovator = _msgSender();
        } else {
            // Iterating a mapping is not feasible for public view.
            // A dedicated mapping `profileIdToAddress` would be needed if this is a common query.
            // For now, assume a front-end keeps track or user queries their own profile.
        }

        reputation = profile.reputation;
        lastReputationUpdate = profile.lastReputationUpdate;

        skillCategories = new SkillCategory[](MAX_SKILL_CATEGORIES);
        skillPoints = new uint256[](MAX_SKILL_CATEGORIES);
        for (uint256 i = 0; i < MAX_SKILL_CATEGORIES; i++) {
            skillCategories[i] = SkillCategory(i);
            skillPoints[i] = profile.skills[SkillCategory(i)];
        }

        contributionProofHashes = new bytes32[](profile.contributionProofs.length);
        for (uint256 i = 0; i < profile.contributionProofs.length; i++) {
            contributionProofHashes[i] = profile.contributionProofs[i];
        }
    }


    // --- III. Leap Project Lifecycle Management ---

    /**
     * @dev Allows an innovator to submit a new project proposal.
     * @param _name The name of the project.
     * @param _descriptionURI URI to detailed project description (e.g., IPFS hash).
     * @param _fundingGoal The target funding amount for the project.
     */
    function proposeLeapProject(
        string memory _name,
        string memory _descriptionURI,
        uint256 _fundingGoal
    ) external onlyRegisteredInnovator {
        require(_fundingGoal >= minProjectFundingGoal, "QLP: Funding goal too low");

        uint256 projectId = nextProjectId++;
        leapProjects[projectId] = LeapProject({
            innovator: _msgSender(),
            name: _name,
            descriptionURI: _descriptionURI,
            fundingGoal: _fundingGoal,
            currentConvictionScore: 0,
            totalCatalystFunds: 0,
            fundsRaised: 0,
            status: ProjectStatus.Proposed,
            proposalTimestamp: block.timestamp,
            convictionStartTimestamp: 0,
            executionStartTimestamp: 0,
            evaluationStartTimestamp: 0,
            finalizationTimestamp: 0,
            stakerConviction: new mapping(address => uint256)(),
            lastStakerConvictionUpdate: new mapping(address => uint256)(),
            hasSignaledSuccess: new mapping(address => bool)(),
            hasChallengedFailure: new mapping(address => bool)(),
            successSignals: 0,
            failureChallenges: 0
        });

        emit LeapProjectProposed(projectId, _msgSender(), _fundingGoal);
    }

    /**
     * @dev Enables users to provide initial "catalyst" funds to a project.
     *      This gives it early momentum and a small boost to conviction score.
     * @param _projectId The ID of the project to catalyze.
     * @param _amount The amount of funding token to provide.
     */
    function catalyzeProjectFunding(uint256 _projectId, uint256 _amount) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(project.status == ProjectStatus.Proposed, "QLP: Project not in proposal stage");
        require(_amount > 0, "QLP: Amount must be greater than zero");

        fundingToken.transferFrom(_msgSender(), address(this), _amount);
        project.totalCatalystFunds = project.totalCatalystFunds.add(_amount);

        // A small conviction boost for catalyst funds (e.g., 10% of value for a fixed duration)
        // For simplicity, we just add it to `fundsRaised` and let conviction staking be the main driver.
        project.fundsRaised = project.fundsRaised.add(_amount);

        // Transition to ConvictionBuilding if enough catalyst funds or time passes.
        // For simplicity, we directly transition upon first catalyst funds, or let another function handle it based on time.
        // Let's make it time-based after the proposal review period.
        if (project.convictionStartTimestamp == 0 && block.timestamp >= project.proposalTimestamp.add(proposalReviewPeriod)) {
             project.status = ProjectStatus.ConvictionBuilding;
             project.convictionStartTimestamp = block.timestamp;
             emit ProjectStatusUpdated(_projectId, ProjectStatus.ConvictionBuilding, block.timestamp);
        }

        emit ProjectCatalyzed(_projectId, _msgSender(), _amount);
    }

    /**
     * @dev Allows community members to attest to a project's success.
     *      Requires the project to be in the evaluation phase.
     * @param _projectId The ID of the project.
     */
    function signalProjectSuccess(uint256 _projectId) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(project.status == ProjectStatus.Evaluation, "QLP: Project not in evaluation phase");
        require(!project.hasSignaledSuccess[_msgSender()], "QLP: Already signaled success for this project");

        project.hasSignaledSuccess[_msgSender()] = true;
        project.successSignals = project.successSignals.add(1);

        emit ProjectSuccessSignaled(_projectId, _msgSender());
    }

    /**
     * @dev Allows community members to challenge a project's success or declare its failure.
     *      Requires the project to be in the evaluation phase.
     * @param _projectId The ID of the project.
     */
    function challengeProjectFailure(uint256 _projectId) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(project.status == ProjectStatus.Evaluation, "QLP: Project not in evaluation phase");
        require(!project.hasChallengedFailure[_msgSender()], "QLP: Already challenged failure for this project");

        project.hasChallengedFailure[_msgSender()] = true;
        project.failureChallenges = project.failureChallenges.add(1);

        // If sufficient challenges, transition to Challenged
        // (Simplified threshold, a real system would use a governance vote or Schelling point game)
        if (project.failureChallenges > project.successSignals.div(2) && project.failureChallenges >= 5) { // Example threshold
             project.status = ProjectStatus.Challenged;
             project.finalizationTimestamp = block.timestamp;
             emit ProjectStatusUpdated(_projectId, ProjectStatus.Challenged, block.timestamp);
        }

        emit ProjectFailureChallenged(_projectId, _msgSender());
    }

    /**
     * @dev Distributes allocated funds to the project's innovator upon successful completion.
     *      This also triggers the reputation update for the innovator.
     *      Callable by anyone to finalize successful projects.
     * @param _projectId The ID of the project.
     */
    function distributeProjectFunds(uint256 _projectId) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(project.status == ProjectStatus.Evaluation, "QLP: Project not in evaluation phase");
        require(block.timestamp >= project.evaluationStartTimestamp.add(evaluationPeriod), "QLP: Evaluation period not over");
        require(project.successSignals > project.failureChallenges, "QLP: Project was challenged or not enough success signals");
        require(project.fundsRaised >= project.fundingGoal, "QLP: Project did not reach funding goal");

        // Mark as Success
        project.status = ProjectStatus.Success;
        project.finalizationTimestamp = block.timestamp;
        emit ProjectStatusUpdated(_projectId, ProjectStatus.Success, block.timestamp);

        uint256 totalFunded = project.fundsRaised;
        uint256 innovatorShare = totalFunded.mul(projectFundingAllocationBasisPoints).div(10000);
        uint256 stakerShare = totalFunded.mul(stakerRewardAllocationBasisPoints).div(10000);
        uint256 protocolFee = totalFunded.mul(protocolFeeBasisPoints).div(10000);

        // Update innovator's reputation (Simplified: direct gain)
        InnovatorProfile storage innovatorProfile = innovatorProfiles[innovatorProfileIds[project.innovator]];
        innovatorProfile.reputation = innovatorProfile.reputation.add(baseReputationGainOnSuccess);
        emit ReputationUpdated(innovatorProfileIds[project.innovator], innovatorProfile.reputation);

        // Allocate staker rewards (claimed separately)
        uint256 totalStaked = 0;
        // In a real system, you'd iterate through all stakers or manage totalStake dynamically
        // For simplicity, we'll assume a way to calculate their relative contribution
        // This is a placeholder; real implementation needs a more robust way to iterate/sum stakers
        // For now, assume staker share is simply available for claiming based on their total conviction.
        // A more advanced system would calculate individual staker shares based on their conviction at funding time.
        // Let's just set the project's reward pool for stakers.
        projectStakerRewards[_projectId][address(this)] = stakerShare; // A conceptual pool

        fundingToken.transfer(project.innovator, innovatorShare);
        // Protocol fee would go to a DAO treasury address
        // fundingToken.transfer(owner(), protocolFee); // Or a DAO contract
        emit ProjectFundsDistributed(_projectId, innovatorShare);
    }

    /**
     * @dev Retrieves the details of a Leap Project.
     * @param _projectId The ID of the project.
     */
    function getLeapProjectDetails(uint256 _projectId)
        external
        view
        returns (
            address innovator,
            string memory name,
            string memory descriptionURI,
            uint256 fundingGoal,
            uint256 currentConvictionScore,
            uint256 totalCatalystFunds,
            uint256 fundsRaised,
            ProjectStatus status,
            uint256 proposalTimestamp,
            uint256 convictionStartTimestamp,
            uint256 executionStartTimestamp,
            uint256 evaluationStartTimestamp,
            uint256 finalizationTimestamp,
            uint256 successSignals,
            uint256 failureChallenges
        )
    {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");

        innovator = project.innovator;
        name = project.name;
        descriptionURI = project.descriptionURI;
        fundingGoal = project.fundingGoal;
        currentConvictionScore = project.currentConvictionScore;
        totalCatalystFunds = project.totalCatalystFunds;
        fundsRaised = project.fundsRaised;
        status = project.status;
        proposalTimestamp = project.proposalTimestamp;
        convictionStartTimestamp = project.convictionStartTimestamp;
        executionStartTimestamp = project.executionStartTimestamp;
        evaluationStartTimestamp = project.evaluationStartTimestamp;
        finalizationTimestamp = project.finalizationTimestamp;
        successSignals = project.successSignals;
        failureChallenges = project.failureChallenges;
    }

    // --- IV. Conviction Staking & Funding ---

    /**
     * @dev Stakes tokens on a specific project to build "conviction" for its funding.
     *      Updates the project's conviction score over time.
     * @param _projectId The ID of the project to stake on.
     * @param _amount The amount of funding token to stake.
     */
    function stakeConviction(uint256 _projectId, uint256 _amount) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(project.status == ProjectStatus.ConvictionBuilding || project.status == ProjectStatus.Executing, "QLP: Project not accepting conviction");
        require(_amount > 0, "QLP: Amount must be greater than zero");

        // If project just entered conviction building (first stake)
        if (project.convictionStartTimestamp == 0) {
            project.status = ProjectStatus.ConvictionBuilding;
            project.convictionStartTimestamp = block.timestamp;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.ConvictionBuilding, block.timestamp);
        }

        // Calculate conviction increase based on time elapsed and previous stake
        _updateConvictionScore(_projectId, _msgSender());

        fundingToken.transferFrom(_msgSender(), address(this), _amount);
        project.stakerConviction[_msgSender()] = project.stakerConviction[_msgSender()].add(_amount);
        project.lastStakerConvictionUpdate[_msgSender()] = block.timestamp;

        totalStakedConvictionByUser[_msgSender()] = totalStakedConvictionByUser[_msgSender()].add(_amount);

        emit ConvictionStaked(_projectId, _msgSender(), _amount);

        _tryProgressProjectStatus(_projectId);
    }

    /**
     * @dev Allows users to move their staked conviction from one project to another.
     *      This is a "liquid conviction" feature.
     * @param _fromProjectId The ID of the project to unstake from.
     * @param _toProjectId The ID of the project to restake on.
     * @param _amount The amount to reallocate.
     */
    function reallocateConviction(uint256 _fromProjectId, uint256 _toProjectId, uint256 _amount) external {
        require(_fromProjectId != _toProjectId, "QLP: Cannot reallocate to the same project");
        require(_amount > 0, "QLP: Amount must be greater than zero");

        LeapProject storage fromProject = leapProjects[_fromProjectId];
        LeapProject storage toProject = leapProjects[_toProjectId];

        require(fromProject.stakerConviction[_msgSender()] >= _amount, "QLP: Insufficient staked amount in source project");
        require(toProject.innovator != address(0), "QLP: Target project does not exist");
        require(toProject.status == ProjectStatus.ConvictionBuilding || toProject.status == ProjectStatus.Executing, "QLP: Target project not accepting conviction");

        // Update conviction for both projects before reallocating
        _updateConvictionScore(_fromProjectId, _msgSender());
        _updateConvictionScore(_toProjectId, _msgSender());

        fromProject.stakerConviction[_msgSender()] = fromProject.stakerConviction[_msgSender()].sub(_amount);
        toProject.stakerConviction[_msgSender()] = toProject.stakerConviction[_msgSender()].add(_amount);

        fromProject.lastStakerConvictionUpdate[_msgSender()] = block.timestamp; // Update timestamp for source to reflect change
        toProject.lastStakerConvictionUpdate[_msgSender()] = block.timestamp;

        emit ConvictionReallocated(_fromProjectId, _toProjectId, _msgSender(), _amount);

        _tryProgressProjectStatus(_toProjectId);
    }

    /**
     * @dev Allows users to withdraw their staked tokens.
     * @param _projectId The ID of the project to withdraw from.
     * @param _amount The amount to withdraw.
     */
    function withdrawConviction(uint256 _projectId, uint256 _amount) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(_amount > 0, "QLP: Amount must be greater than zero");
        require(project.stakerConviction[_msgSender()] >= _amount, "QLP: Insufficient staked amount");
        require(project.status != ProjectStatus.Success && project.status != ProjectStatus.Failed, "QLP: Cannot withdraw from finalized project");

        _updateConvictionScore(_projectId, _msgSender()); // Update conviction before withdrawal

        project.stakerConviction[_msgSender()] = project.stakerConviction[_msgSender()].sub(_amount);
        project.lastStakerConvictionUpdate[_msgSender()] = block.timestamp;

        totalStakedConvictionByUser[_msgSender()] = totalStakedConvictionByUser[_msgSender()].sub(_amount);

        fundingToken.transfer(_msgSender(), _amount);

        emit ConvictionWithdrawn(_projectId, _msgSender(), _amount);
    }

    /**
     * @dev Internal function to update a project's conviction score for a given staker.
     *      This simulates the continuous accumulation of conviction.
     * @param _projectId The ID of the project.
     * @param _staker The address of the staker.
     */
    function _updateConvictionScore(uint256 _projectId, address _staker) internal {
        LeapProject storage project = leapProjects[_projectId];
        uint256 stakedAmount = project.stakerConviction[_staker];
        uint256 lastUpdate = project.lastStakerConvictionUpdate[_staker];

        if (stakedAmount == 0 || lastUpdate == 0 || block.timestamp == lastUpdate) {
            return; // No stake or no time elapsed
        }

        uint256 timeElapsed = block.timestamp.sub(lastUpdate);
        uint256 convictionIncrease = stakedAmount.mul(convictionFundingRateBasisPoints).mul(timeElapsed).div(10000).div(1 days); // Basis points per day

        project.currentConvictionScore = project.currentConvictionScore.add(convictionIncrease);
        project.lastStakerConvictionUpdate[_staker] = block.timestamp;

        // Apply decay if no new stake (simplified, a full decay model would be more complex)
        // For now, decay is handled globally during reputation updates.
    }

    /**
     * @dev Internal function to try and progress a project's status based on time and conviction.
     * @param _projectId The ID of the project.
     */
    function _tryProgressProjectStatus(uint256 _projectId) internal {
        LeapProject storage project = leapProjects[_projectId];

        if (project.status == ProjectStatus.Proposed && block.timestamp >= project.proposalTimestamp.add(proposalReviewPeriod)) {
            project.status = ProjectStatus.ConvictionBuilding;
            project.convictionStartTimestamp = block.timestamp;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.ConvictionBuilding, block.timestamp);
        }

        // If conviction period ends and enough conviction, transition to Executing
        if (project.status == ProjectStatus.ConvictionBuilding && block.timestamp >= project.convictionStartTimestamp.add(convictionAccumulationPeriod)) {
            if (project.currentConvictionScore >= project.fundingGoal) { // Simplified conversion: conviction score == fundingGoal
                project.status = ProjectStatus.Executing;
                project.executionStartTimestamp = block.timestamp;
                project.fundsRaised = project.fundingGoal; // Funds are "realized" from the pool if conviction met
                emit ProjectStatusUpdated(_projectId, ProjectStatus.Executing, block.timestamp);
            } else {
                // If not enough conviction, project fails to fund (or goes into extended period)
                project.status = ProjectStatus.Failed;
                project.finalizationTimestamp = block.timestamp;
                emit ProjectStatusUpdated(_projectId, ProjectStatus.Failed, block.timestamp);
            }
        }

        // If execution period ends, transition to Evaluation
        if (project.status == ProjectStatus.Executing && block.timestamp >= project.executionStartTimestamp.add(projectExecutionPeriod)) {
            project.status = ProjectStatus.Evaluation;
            project.evaluationStartTimestamp = block.timestamp;
            emit ProjectStatusUpdated(_projectId, ProjectStatus.Evaluation, block.timestamp);
        }
    }

    /**
     * @dev Retrieves the current conviction score for a project.
     * @param _projectId The ID of the project.
     * @return The current conviction score.
     */
    function getProjectConviction(uint256 _projectId) external view returns (uint256) {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        return project.currentConvictionScore;
    }


    // --- V. Rewards & Reputation Dynamics ---

    /**
     * @dev Allows stakers to claim rewards earned for successful projects they supported.
     *      Rewards are based on their proportion of conviction contributed to a successful project.
     * @param _projectId The ID of the project.
     */
    function claimConvictionRewards(uint256 _projectId) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(project.status == ProjectStatus.Success, "QLP: Project not successfully completed");
        require(project.stakerConviction[_msgSender()] > 0, "QLP: Not a staker in this project");

        // Simplified calculation: rewards are distributed proportionally to staked amount at finalization.
        // A more complex system would track conviction over time.
        uint256 totalProjectStaked = 0;
        // In reality, this would require iterating through all stakers or maintaining a global sum
        // For simplicity, we assume this value is tracked by front-end or a more complex sum is managed.
        // For now, let's use the project's totalConvictionScore as a proxy for total stake,
        // and distribute rewards based on staker's *final* staked amount at project success relative to that.
        // This is a simplification. A real system needs to track total liquid stake over time.
        // Let's assume `project.currentConvictionScore` at `finalizationTimestamp` is the "total qualified stake".

        // For now, let's just use `projectStakerRewards[_projectId][address(this)]` as the total reward pool for stakers
        // and divide it by the total conviction score to get a "reward per conviction point"
        uint256 totalStakerRewardPool = projectStakerRewards[_projectId][address(this)];
        require(totalStakerRewardPool > 0, "QLP: No rewards allocated for stakers on this project");

        // This is a highly simplified reward distribution. In a real system, you'd calculate a staker's share
        // based on their contributed conviction over the accumulation period relative to total conviction.
        // Here, we'll just give a portion of the project's total allocated staker rewards.
        uint256 rewardAmount = (totalStakerRewardPool.mul(project.stakerConviction[_msgSender()])).div(project.currentConvictionScore); // simplified proportion

        require(rewardAmount > 0, "QLP: No rewards to claim");

        // Clear the user's eligibility for these specific rewards to prevent double claiming
        project.stakerConviction[_msgSender()] = 0; // Clear their stake in the project if they haven't withdrawn it (simplification)
        projectStakerRewards[_projectId][_msgSender()] = 0; // Clear specific user rewards

        fundingToken.transfer(_msgSender(), rewardAmount);
        emit StakerRewardsClaimed(_projectId, _msgSender(), rewardAmount);
    }

    /**
     * @dev Allows the innovator of a successful project to claim their allocated rewards.
     *      This is called by distributeProjectFunds, but can be a separate claim function too.
     * @param _projectId The ID of the project.
     */
    function claimProjectRewards(uint256 _projectId) external {
        LeapProject storage project = leapProjects[_projectId];
        require(project.innovator != address(0), "QLP: Project does not exist");
        require(project.innovator == _msgSender(), "QLP: Only innovator can claim project rewards");
        require(project.status == ProjectStatus.Success, "QLP: Project not successfully completed");
        require(project.finalizationTimestamp > 0, "QLP: Project not finalized");

        // Funds are distributed by `distributeProjectFunds` directly to innovator.
        // This function would be for a different model, e.g., if funds are held here and claimed.
        // For now, it's a placeholder if a separate claim mechanism is desired post-distribution.
        // As distributeProjectFunds sends directly, this is redundant in the current model.
        // If funds were held for claiming:
        // uint256 unclaimed = project.innovatorUnclaimedRewards; // conceptual
        // require(unclaimed > 0, "No rewards to claim");
        // project.innovatorUnclaimedRewards = 0;
        // fundingToken.transfer(_msgSender(), unclaimed);
        // emit InnovatorRewardsClaimed(_projectId, _msgSender(), unclaimed);
        revert("QLP: Innovator rewards distributed directly upon project success.");
    }

    /**
     * @dev A function (can be called by anyone or an automated system) to trigger the periodic
     *      update of innovator reputations based on their project involvement and contribution
     *      attestations. This also applies reputation decay.
     * @param _profileId The ID of the innovator profile to update.
     */
    function updateReputationEpoch(uint256 _profileId) external {
        InnovatorProfile storage profile = innovatorProfiles[_profileId];
        require(profile.exists, "QLP: Profile does not exist");

        uint256 lastUpdate = profile.lastReputationUpdate;
        uint256 timeElapsed = block.timestamp.sub(lastUpdate);

        if (timeElapsed < reputationUpdateInterval) {
            revert("QLP: Not enough time passed for reputation update");
        }

        uint256 decayPeriods = timeElapsed.div(reputationUpdateInterval);
        for (uint256 i = 0; i < decayPeriods; i++) {
            profile.reputation = profile.reputation.mul(10000 - reputationDecayBasisPoints).div(10000);
        }

        profile.lastReputationUpdate = block.timestamp;
        emit ReputationUpdated(_profileId, profile.reputation);
    }

    // --- VI. Adaptive Governance ---

    /**
     * @dev Allows eligible entities (Protocol Council, or possibly high-reputation innovators)
     *      to propose a change to a key protocol parameter.
     * @param _paramNameHash The keccak256 hash of the parameter name (e.g., keccak256("proposalReviewPeriod")).
     * @param _newValue The new value proposed for the parameter.
     */
    function proposeParameterChange(bytes32 _paramNameHash, uint256 _newValue) external onlyProtocolCouncil {
        // In a real system, eligibility would be based on reputation/token holdings.
        // For this example, it's owner-only (acting as Protocol Council).
        uint256 proposalId = nextParamProposalId++;
        paramChangeProposals[proposalId] = ParameterChangeProposal({
            parameterNameHash: _paramNameHash,
            newValue: _newValue,
            proposalTimestamp: block.timestamp,
            votingDeadline: block.timestamp.add(7 days), // Example: 7 days voting period
            executionTimelock: 2 days, // Example: 2 days timelock after voting ends
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)(),
            executed: false,
            passed: false
        });
        emit ParameterChangeProposed(proposalId, _paramNameHash, _newValue);
    }

    /**
     * @dev Allows eligible voters (e.g., high-reputation innovators, conviction stakers)
     *      to vote on proposed parameter changes.
     * @param _proposalId The ID of the parameter change proposal.
     * @param _support True for 'for', false for 'against'.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _support) external {
        ParameterChangeProposal storage proposal = paramChangeProposals[_proposalId];
        require(proposal.proposalTimestamp != 0, "QLP: Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "QLP: Voting period has ended");
        require(!proposal.hasVoted[_msgSender()], "QLP: Already voted on this proposal");

        // Voting power could be based on reputation, total conviction staked, or a governance token
        uint256 votingPower = 1; // Simplified: 1 address = 1 vote
        // More complex: votingPower = innovatorProfiles[innovatorProfileIds[_msgSender()]].reputation;
        // Or: votingPower = totalStakedConvictionByUser[_msgSender()];
        require(votingPower > 0, "QLP: Caller has no voting power");

        proposal.hasVoted[_msgSender()] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votingPower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votingPower);
        }

        emit ParameterChangeVoted(_proposalId, _msgSender(), _support);
    }

    /**
     * @dev Executes a parameter change proposal once it has passed and its timelock has expired.
     *      Anyone can call this to trigger execution.
     * @param _proposalId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 _proposalId) external {
        ParameterChangeProposal storage proposal = paramChangeProposals[_proposalId];
        require(proposal.proposalTimestamp != 0, "QLP: Proposal does not exist");
        require(!proposal.executed, "QLP: Proposal already executed");
        require(block.timestamp > proposal.votingDeadline, "QLP: Voting period not over");
        require(block.timestamp > proposal.votingDeadline.add(proposal.executionTimelock), "QLP: Execution timelock not expired");

        // Example quorum/majority logic (simplified)
        require(proposal.votesFor > proposal.votesAgainst, "QLP: Proposal did not pass majority vote");
        require(proposal.votesFor.add(proposal.votesAgainst) >= 5, "QLP: Not enough votes (quorum)"); // Example quorum

        proposal.executed = true;
        proposal.passed = true;

        updateProtocolParameter(proposal.parameterNameHash, proposal.newValue);

        emit ParameterChangeExecuted(_proposalId, proposal.parameterNameHash, proposal.newValue);
    }

    // --- VII. Utility & Safety ---

    /**
     * @dev Allows the owner to recover accidentally sent ERC20 tokens that are not the funding token.
     *      This is a safety mechanism.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function emergencyWithdrawStuckTokens(address _tokenAddress, uint256 _amount) external onlyOwner {
        require(_tokenAddress != address(fundingToken), "QLP: Cannot withdraw funding token this way");
        IERC20 stuckToken = IERC20(_tokenAddress);
        require(stuckToken.transfer(owner(), _amount), "QLP: Failed to withdraw stuck tokens");
    }

    // Note: Ownable's transferOwnership is inherited and available.
}
```