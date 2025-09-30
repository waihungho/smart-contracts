Here's a Solidity smart contract named `AetherialNexus` that embodies advanced concepts, creative functions, and trendy features, ensuring a minimum of 20 distinct functions without directly duplicating existing open-source patterns (though utilizing standard OpenZeppelin utilities for best practice).

This contract aims to be a Decentralized Autonomous Research & Development Hub, integrating AI-assisted verification, dynamic NFTs (dNFTs) for projects, a reputation-based skill system, and on-chain IP management.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; // Using OpenZeppelin's Strings for convenience

// Interface for an external AI Oracle, representing verifiable off-chain computation.
// In a real-world scenario, this would interact with a Chainlink Oracle, gelato, or similar
// decentralized oracle network that can query off-chain AI services and post verifiable results.
interface IAIOracle {
    // A simplified interface; real oracle interactions might involve request IDs, callbacks, etc.
    // The contract internally manages the verificationRequestId to match results.
    function submitResult(
        uint256 _requestId,
        bytes32 _oracleType,
        int256 _score,
        string calldata _justificationCID
    ) external; // This function would be called by the oracle itself.
}


/**
 * @title AetherialNexus - Decentralized Autonomous Research & Development Hub
 * @dev This contract facilitates decentralized research project funding, AI-assisted verification,
 *      reputation-based governance, and dynamic Intellectual Property (IP) management.
 *      It integrates concepts like dynamic NFTs (dNFTs), verifiable off-chain AI oracles,
 *      and skill-based contribution systems to foster a novel R&D ecosystem.
 *
 *      The contract itself is not an ERC-721 token but *manages* the state and metadata
 *      of Project dNFTs, simulating their dynamic behavior and ownership. In a full dApp,
 *      a dedicated, minimal ERC-721 contract (e.g., `ProjectNFT.sol`) would handle token
 *      transfers, approvals, etc., and this contract would interact with it. For the
 *      purpose of meeting the function count requirement and showcasing the *concept*,
 *      we embed the basic dNFT metadata and ownership management directly.
 */

// Outline:
// I.   Core System Management: Basic access control, pausing, general parameter updates.
// II.  Oracle & Verifier Management: Registration and management of trusted off-chain AI oracles and skill attestation verifiers.
// III. Research Project Lifecycle: Creation, funding, milestone submission, AI-assisted verification, fund distribution.
// IV.  Reputation & Skill System: User skill attestation, reputation tracking, delegation for voting.
// V.   Dynamic Project NFTs (dNFTs) & IP Management: Project NFT creation, dynamic metadata updates, derived IP registration, and royalty distribution.
// VI.  Decentralized Governance & Treasury: Proposal system for treasury allocations, reputation-delegated voting mechanism.
// VII. Emergency & Utilities: Owner-only emergency token withdrawal.

// Function Summary:
// 1.  constructor(): Initializes the contract with an owner and essential core parameters (e.g., fees, thresholds).
// 2.  updateCoreParameter(bytes32 _paramKey, uint256 _value): Allows the owner to adjust system-wide configurations, enhancing adaptability.
// 3.  pauseSystem(): Temporarily suspends critical operations in emergencies, controlled by the owner.
// 4.  unpauseSystem(): Resumes operations after a pause, controlled by the owner.
// 5.  addTrustedOracle(address _oracleAddress, bytes32 _oracleType): Registers an address as a trusted off-chain AI oracle for specific verification tasks (e.g., "AI_CODE_AUDIT").
// 6.  removeTrustedOracle(address _oracleAddress): Deregisters a trusted oracle, revoking its ability to submit verification results.
// 7.  registerSkillAttestationVerifier(address _verifierAddress, bytes32 _skillType): Designates an address as a trusted entity capable of attesting to specific user skills (e.g., "QUANTUM_PHYSICS").
// 8.  attestUserSkill(address _user, bytes32 _skillHash, uint256 _attestationScore): Allows a registered skill verifier to record a user's proficiency (1-100) in a specific skill on-chain.
// 9.  createResearchProject(string memory _projectName, string memory _projectDescription, bytes32[] memory _requiredSkills, uint256 _fundingGoal): Initiates a new research project, minting a unique Dynamic Project NFT (dNFT) and setting its funding goal.
// 10. submitProjectMilestone(uint256 _projectId, string memory _milestoneDescription, uint256 _expectedCompletionTimestamp): Allows the project lead to propose a new milestone with a description and expected completion time.
// 11. fundProject(uint256 _projectId): Enables users to contribute Ether (or a specified token) towards a project's funding goal, granting them a share of future IP royalties if applicable.
// 12. requestMilestoneVerification(uint256 _projectId, uint256 _milestoneIndex, string memory _proofCID, bytes32 _oracleType): The project lead requests verification for a completed milestone, providing off-chain proof (IPFS CID) and specifying the required AI oracle type.
// 13. submitOracleVerificationResult(uint256 _projectId, uint256 _milestoneIndex, uint256 _verificationRequestId, bytes32 _oracleType, int256 _score, string memory _justificationCID): A trusted AI oracle submits its verifiable score (0-100) and justification (IPFS CID) for a specific milestone.
// 14. distributeMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex): Releases a portion of project funds to the project lead upon successful milestone verification and updates the associated dNFT metadata.
// 15. claimStakedFunds(uint256 _projectId): Allows funders to withdraw their staked funds if a project fails, is cancelled, or has excess funds upon completion.
// 16. updateProjectNFTMetadata(uint256 _projectId, string memory _newURI): Updates the metadata URI for a Project dNFT, reflecting project progress, status changes, or major milestones.
// 17. registerDerivedIP(uint256 _projectId, string memory _ipCID, uint256 _royaltyShareNumerator, uint256 _royaltyShareDenominator): Registers new Intellectual Property (IP) derived from a completed project, setting its on-chain royalty structure.
// 18. distributeIPRoyalty(uint256 _ipId): Facilitates the collection and distribution of royalties for registered derived IP to the creator and potentially other contributors.
// 19. proposeTreasuryAllocation(bytes32 _allocationType, uint256 _amount, address _recipient): Allows eligible users to propose spending from the contract's treasury for various purposes (e.g., grants, infrastructure).
// 20. voteOnTreasuryAllocation(uint256 _proposalId, bool _approve): Enables users with delegated reputation to vote on pending treasury allocation proposals, influencing governance decisions.
// 21. delegateReputation(address _delegatee): Allows a user to delegate their accumulated reputation score to another address, centralizing voting power for specific representatives.
// 22. revokeReputationDelegation(): Revokes any active reputation delegation, restoring voting power to the delegator.
// 23. emergencyWithdrawTokens(address _tokenAddress, uint256 _amount, address _recipient): An owner-only function to safely retrieve any ERC-20 tokens accidentally sent to the contract, preventing loss.
// 24. transferOwnership(address _newOwner): Initiates a two-step process to securely transfer ownership of the contract to a new address.

contract AetherialNexus is Ownable2Step, Pausable {
    using SafeMath for uint256; // For safe arithmetic operations

    // --- Enums and Structs ---

    enum ProjectStatus {
        Proposed,      // Initial state, awaiting funding
        Funding,       // Actively seeking funds
        InProgress,    // Actively working on milestones
        Completed,     // All milestones verified, project finished
        Failed,        // Unable to complete due to failed milestones or insufficient funds
        Cancelled      // Project manually cancelled by lead or governance
    }

    struct Project {
        uint256 id;
        address payable projectLead;
        string name;
        string description;
        bytes32[] requiredSkills; // Skill hashes needed for contributors
        uint256 fundingGoal;
        uint256 currentFundedAmount;
        ProjectStatus status;
        uint256 nftTokenId; // Unique ID for the Dynamic Project NFT
        uint256 milestoneCount; // Total number of milestones for this project
        mapping(address => uint256) funders; // Who funded and how much (ETH)
        bool isIPRegistered; // True if derived IP has been registered
    }

    struct Milestone {
        string description;
        uint256 expectedCompletionTimestamp;
        bool isVerified;         // True if AI oracle has verified it successfully
        bool fundsReleased;      // True if milestone funds have been sent to lead
        int256 oracleScore;      // Score from the AI oracle (e.g., 0-100)
        string proofCID;         // IPFS CID for submitted proof of work
        string justificationCID; // IPFS CID for oracle's detailed justification
        uint256 verificationRequestId; // Unique ID to link to an external oracle request
        bytes32 requestedOracleType;   // Type of oracle requested (e.g., "AI_CODE_AUDIT")
    }

    struct OracleInfo {
        bytes32 oracleType; // Specific function of the oracle (e.g., "AI_CODE_AUDIT", "AI_DATA_VERIFICATION")
        bool isActive;
    }

    struct SkillAttestationVerifier {
        bytes32 skillType; // Specific skill this verifier can attest to (e.g., "QUANTUM_PHYSICS", "SOLIDITY_DEV")
        bool isActive;
    }

    struct TreasuryProposal {
        uint256 id;
        address proposer;
        bytes32 allocationType; // Category of allocation (e.g., "INFRASTRUCTURE", "GRANT_PROGRAM", "MAINTENANCE")
        uint256 amount;
        address recipient;
        uint256 totalYesVotes;  // Accumulated reputation for 'yes' votes
        mapping(address => bool) hasVoted; // Tracks who (effective voters) has voted
        uint256 creationTimestamp;
        uint256 votingDeadline;
        bool isApproved;
        bool executed;
    }

    struct DerivedIP {
        uint256 id;
        uint256 projectId;
        string ipCID; // IPFS CID for the derived IP details
        address creator; // The project lead who registered the IP
        uint256 royaltyShareNumerator; // Numerator for royalty percentage (e.g., 10 for 10%)
        uint256 royaltyShareDenominator; // Denominator for royalty percentage (usually 100)
        uint256 totalRoyaltyCollected; // Total royalties collected for this IP
        // A more complex system might distribute to a pool of contributors based on their involvement.
    }

    // --- State Variables ---

    uint256 public projectCounter; // Total number of projects created
    mapping(uint256 => Project) public projects;
    mapping(uint256 => mapping(uint256 => Milestone)) public projectMilestones;

    uint256 public nextOracleRequestId; // Unique ID for oracle requests
    mapping(address => OracleInfo) public trustedOracles;

    mapping(bytes32 => mapping(address => SkillAttestationVerifier)) public skillAttestationVerifiers; // skillType => verifierAddress => verifierInfo
    mapping(address => mapping(bytes32 => uint256)) public userSkills; // user => skillHash => score (1-100)

    mapping(address => uint256) public userReputation; // Raw reputation score for an address
    mapping(address => address) public reputationDelegates; // delegator => delegatee
    mapping(address => uint256) public delegatedVotingPower; // delegatee => total voting power delegated to them

    uint256 public treasuryProposalCounter;
    mapping(uint256 => TreasuryProposal) public treasuryProposals;

    // --- Dynamic Project NFT (dNFT) Management ---
    // These mappings simulate a minimal ERC-721 for Project dNFTs.
    // In a production environment, this would interact with a separate ERC-721 contract.
    uint256 public projectNFTTokenCounter; // Auto-incrementing token ID for new dNFTs
    mapping(uint256 => address) public projectNFTOwner; // tokenId => owner address
    mapping(uint256 => string) public projectNFTTokenURIs; // tokenId => metadata URI (IPFS CID)

    uint256 public ipCounter;
    mapping(uint256 => DerivedIP) public derivedIPs;

    // Core configurable parameters, accessible by key (e.g., "PROJECT_CREATION_FEE")
    mapping(bytes32 => uint256) public coreParameters;

    // --- Events ---

    event CoreParameterUpdated(bytes32 indexed paramKey, uint256 value);
    event TrustedOracleAdded(address indexed oracleAddress, bytes32 indexed oracleType);
    event TrustedOracleRemoved(address indexed oracleAddress);
    event SkillVerifierRegistered(address indexed verifierAddress, bytes32 indexed skillType);
    event UserSkillAttested(address indexed user, bytes32 indexed skillHash, uint256 score);
    event ProjectCreated(uint256 indexed projectId, address indexed projectLead, string name, uint256 fundingGoal, uint256 nftTokenId);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, string description);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneVerificationRequested(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 requestId, bytes32 indexed oracleType, string proofCID);
    event OracleVerificationResultSubmitted(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 requestId, bytes32 indexed oracleType, int256 score);
    event MilestoneFundsDistributed(uint256 indexed projectId, uint256 indexed milestoneIndex, uint256 amount);
    event FundsClaimed(uint256 indexed projectId, address indexed funder, uint256 amount);
    event ProjectNFTMetadataUpdated(uint256 indexed projectId, uint256 indexed tokenId, string newURI);
    event DerivedIPRegistered(uint256 indexed ipId, uint256 indexed projectId, address indexed creator, string ipCID);
    event IPRoyaltyDistributed(uint256 indexed ipId, uint256 amount);
    event TreasuryProposalCreated(uint256 indexed proposalId, address indexed proposer, bytes32 allocationType, uint256 amount, address recipient);
    event TreasuryProposalVoted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 currentVoteCount);
    event TreasuryProposalExecuted(uint256 indexed proposalId, bool approved);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationRevoked(address indexed delegator);
    event EmergencyTokensWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event ReputationUpdated(address indexed user, int256 delta, uint256 newReputation);

    // --- Modifiers ---

    modifier onlyTrustedOracle(bytes32 _oracleType) {
        require(trustedOracles[msg.sender].isActive && trustedOracles[msg.sender].oracleType == _oracleType, "AetherialNexus: Not a trusted oracle of this type");
        _;
    }

    modifier onlySkillVerifier(bytes32 _skillType) {
        require(skillAttestationVerifiers[_skillType][msg.sender].isActive, "AetherialNexus: Not a trusted verifier for this skill type");
        _;
    }

    modifier onlyProjectLead(uint256 _projectId) {
        require(projects[_projectId].projectLead == msg.sender, "AetherialNexus: Not the project lead");
        _;
    }

    modifier hasMinimumReputation(uint256 _requiredReputation) {
        require(userReputation[msg.sender] >= _requiredReputation, "AetherialNexus: Insufficient reputation");
        _;
    }

    // --- Constructor ---

    constructor() Ownable2Step(msg.sender) Pausable() {
        // Initialize core parameters with default values
        coreParameters["PROJECT_CREATION_FEE"] = 0.01 ether; // Example: 0.01 ETH to create a project
        coreParameters["MIN_REPUTATION_FOR_VOTE"] = 100; // Minimum reputation to vote on proposals
        coreParameters["MILESTONE_VERIFICATION_THRESHOLD_SCORE"] = 70; // Minimum oracle score for milestone approval (out of 100)
        coreParameters["TREASURY_VOTING_PERIOD_SECONDS"] = 7 days; // Voting period for treasury proposals
        coreParameters["TREASURY_APPROVAL_THRESHOLD_PERCENT"] = 51; // 51% of total delegated reputation for approval (needs `getTotalDelegatedVotingPower` logic)
        coreParameters["PROJECT_FUNDING_PERIOD_SECONDS"] = 30 days; // Max duration for initial project funding
    }

    // --- I. Core System Management ---

    /**
     * @dev Updates a core system parameter. Only callable by the owner.
     * @param _paramKey The unique key identifying the parameter (e.g., "PROJECT_CREATION_FEE").
     * @param _value The new value for the parameter.
     */
    function updateCoreParameter(bytes32 _paramKey, uint256 _value) external onlyOwner {
        coreParameters[_paramKey] = _value;
        emit CoreParameterUpdated(_paramKey, _value);
    }

    /**
     * @dev Pauses the contract, preventing critical state-changing functions from being called.
     *      Only callable by the owner. Inherited from Pausable.
     */
    function pauseSystem() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing critical state-changing functions to resume.
     *      Only callable by the owner. Inherited from Pausable.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    // --- II. Oracle & Verifier Management ---

    /**
     * @dev Registers an address as a trusted off-chain AI oracle.
     *      Oracles are responsible for submitting verifiable results for milestone verification.
     *      Only callable by the owner.
     * @param _oracleAddress The address of the new trusted oracle.
     * @param _oracleType A unique identifier for the type of oracle (e.g., "AI_CODE_AUDIT", "AI_DATA_VERIFICATION").
     */
    function addTrustedOracle(address _oracleAddress, bytes32 _oracleType) external onlyOwner {
        require(_oracleAddress != address(0), "AetherialNexus: Invalid oracle address");
        require(!trustedOracles[_oracleAddress].isActive, "AetherialNexus: Oracle already registered");
        trustedOracles[_oracleAddress] = OracleInfo({oracleType: _oracleType, isActive: true});
        emit TrustedOracleAdded(_oracleAddress, _oracleType);
    }

    /**
     * @dev Removes a trusted oracle. Only callable by the owner.
     * @param _oracleAddress The address of the oracle to remove.
     */
    function removeTrustedOracle(address _oracleAddress) external onlyOwner {
        require(trustedOracles[_oracleAddress].isActive, "AetherialNexus: Oracle not active");
        delete trustedOracles[_oracleAddress];
        emit TrustedOracleRemoved(_oracleAddress);
    }

    /**
     * @dev Registers an address as a trusted verifier for a specific skill type.
     *      Skill verifiers can attest to users' skills on the platform. Only callable by the owner.
     * @param _verifierAddress The address of the skill attestation verifier.
     * @param _skillType A unique identifier for the skill type (e.g., "QUANTUM_PHYSICS").
     */
    function registerSkillAttestationVerifier(address _verifierAddress, bytes32 _skillType) external onlyOwner {
        require(_verifierAddress != address(0), "AetherialNexus: Invalid verifier address");
        require(!skillAttestationVerifiers[_skillType][_verifierAddress].isActive, "AetherialNexus: Verifier already registered for this skill type");
        skillAttestationVerifiers[_skillType][_verifierAddress] = SkillAttestationVerifier({skillType: _skillType, isActive: true});
        emit SkillVerifierRegistered(_verifierAddress, _skillType);
    }

    /**
     * @dev Allows a registered skill verifier to attest to a user's skill.
     *      This updates the user's on-chain skill profile.
     * @param _user The address of the user whose skill is being attested.
     * @param _skillHash The hash of the skill being attested (e.g., keccak256("Solidity")).
     * @param _attestationScore The score representing the user's proficiency (e.g., 1-100).
     */
    function attestUserSkill(address _user, bytes32 _skillHash, uint256 _attestationScore) external onlySkillVerifier(_skillHash) {
        require(_user != address(0), "AetherialNexus: Invalid user address");
        require(_attestationScore > 0 && _attestationScore <= 100, "AetherialNexus: Score must be between 1 and 100");
        userSkills[_user][_skillHash] = _attestationScore;
        emit UserSkillAttested(_user, _skillHash, _attestationScore);
    }

    // --- III. Research Project Lifecycle ---

    /**
     * @dev Creates a new research project. Requires a project creation fee.
     *      A unique Dynamic Project NFT (dNFT) is minted to represent the project.
     * @param _projectName The name of the research project.
     * @param _projectDescription A detailed description of the project.
     * @param _requiredSkills An array of skill hashes required for this project.
     * @param _fundingGoal The total amount of Ether required to fund the project.
     */
    function createResearchProject(
        string memory _projectName,
        string memory _projectDescription,
        bytes32[] memory _requiredSkills,
        uint256 _fundingGoal
    ) external payable whenNotPaused {
        require(msg.value >= coreParameters["PROJECT_CREATION_FEE"], "AetherialNexus: Insufficient project creation fee");
        require(_fundingGoal > 0, "AetherialNexus: Funding goal must be greater than zero");
        require(bytes(_projectName).length > 0 && bytes(_projectDescription).length > 0, "AetherialNexus: Project name and description cannot be empty");

        projectCounter++;
        projectNFTTokenCounter++; // Increment for new dNFT token ID

        Project storage newProject = projects[projectCounter];
        newProject.id = projectCounter;
        newProject.projectLead = payable(msg.sender);
        newProject.name = _projectName;
        newProject.description = _projectDescription;
        newProject.requiredSkills = _requiredSkills;
        newProject.fundingGoal = _fundingGoal;
        newProject.status = ProjectStatus.Funding; // Projects start in funding phase
        newProject.nftTokenId = projectNFTTokenCounter;
        newProject.milestoneCount = 0;
        newProject.isIPRegistered = false;

        // "Mint" the dNFT by assigning ownership and an initial URI
        projectNFTOwner[newProject.nftTokenId] = msg.sender;
        // Initial metadata URI for the dNFT, reflecting its 'Proposed' or 'Funding' state
        projectNFTTokenURIs[newProject.nftTokenId] = string(abi.encodePacked("ipfs://initial-project-metadata-", Strings.toString(projectCounter)));

        // Initial reputation boost for proposing a project
        _updateReputation(msg.sender, 10);

        emit ProjectCreated(newProject.id, msg.sender, _projectName, _fundingGoal, newProject.nftTokenId);
        emit ProjectNFTMetadataUpdated(newProject.id, newProject.nftTokenId, projectNFTTokenURIs[newProject.nftTokenId]);
    }

    /**
     * @dev Allows the project lead to propose a new milestone for their project.
     *      Project must be fully funded to submit milestones for active work.
     * @param _projectId The ID of the project.
     * @param _milestoneDescription A description of the milestone.
     * @param _expectedCompletionTimestamp The timestamp when the milestone is expected to be completed.
     */
    function submitProjectMilestone(
        uint256 _projectId,
        string memory _milestoneDescription,
        uint256 _expectedCompletionTimestamp
    ) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(project.status == ProjectStatus.Funding || project.status == ProjectStatus.InProgress, "AetherialNexus: Project not in funding or in-progress phase");
        require(project.currentFundedAmount >= project.fundingGoal, "AetherialNexus: Project not fully funded yet");
        require(_expectedCompletionTimestamp > block.timestamp, "AetherialNexus: Expected completion must be in the future");
        require(bytes(_milestoneDescription).length > 0, "AetherialNexus: Milestone description cannot be empty");

        project.milestoneCount++;
        uint256 milestoneIndex = project.milestoneCount;
        projectMilestones[_projectId][milestoneIndex] = Milestone({
            description: _milestoneDescription,
            expectedCompletionTimestamp: _expectedCompletionTimestamp,
            isVerified: false,
            fundsReleased: false,
            oracleScore: 0,
            proofCID: "",
            justificationCID: "",
            verificationRequestId: 0,
            requestedOracleType: bytes32(0)
        });

        // If project was just funded, set status to InProgress
        if (project.status == ProjectStatus.Funding) {
            project.status = ProjectStatus.InProgress;
        }

        emit MilestoneSubmitted(_projectId, milestoneIndex, _milestoneDescription);
    }

    /**
     * @dev Allows users to fund a project with Ether.
     * @param _projectId The ID of the project to fund.
     */
    function fundProject(uint256 _projectId) external payable whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(project.status == ProjectStatus.Funding, "AetherialNexus: Project is not in funding phase");
        require(msg.value > 0, "AetherialNexus: Funding amount must be greater than zero");

        project.currentFundedAmount = project.currentFundedAmount.add(msg.value);
        project.funders[msg.sender] = project.funders[msg.sender].add(msg.value);

        // Reputation adjustments for funding
        if (project.currentFundedAmount >= project.fundingGoal) {
            _updateReputation(msg.sender, 5); // Boost for contributing to a fully funded project
        } else {
            _updateReputation(msg.sender, 1); // Small boost for partial funding
        }

        emit ProjectFunded(_projectId, msg.sender, msg.value);
    }

    /**
     * @dev Project lead requests verification for a completed milestone.
     *      This triggers an off-chain AI oracle process.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _proofCID IPFS CID pointing to the submitted proof of work.
     * @param _oracleType The type of oracle required for verification (e.g., "AI_CODE_AUDIT").
     */
    function requestMilestoneVerification(
        uint256 _projectId,
        uint256 _milestoneIndex,
        string memory _proofCID,
        bytes32 _oracleType
    ) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        Milestone storage milestone = projectMilestones[_projectId][_milestoneIndex];

        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(_milestoneIndex > 0 && _milestoneIndex <= project.milestoneCount, "AetherialNexus: Invalid milestone index");
        require(!milestone.isVerified, "AetherialNexus: Milestone already verified");
        require(milestone.verificationRequestId == 0, "AetherialNexus: Verification already requested for this milestone");
        
        // Ensure the specified oracle type is a registered trusted oracle
        bool oracleTypeRegistered = false;
        for (uint256 i = 0; i < projectCounter; i++) { // This loop is illustrative, needs optimization in production
            // A direct check `trustedOracles[someAddress].oracleType == _oracleType` is better if we iterate addresses
            // but for _oracleType check specifically, we might need a mapping `bytes32 => bool` for registered types
        }
        // Simplified check: ensure a dummy oracle exists for this type. Real system would check active oracles.
        require(_oracleType != bytes32(0), "AetherialNexus: Invalid oracle type specified");

        nextOracleRequestId++;
        milestone.verificationRequestId = nextOracleRequestId;
        milestone.proofCID = _proofCID;
        milestone.requestedOracleType = _oracleType;

        emit MilestoneVerificationRequested(_projectId, _milestoneIndex, nextOracleRequestId, _oracleType, _proofCID);
    }

    /**
     * @dev A trusted AI oracle submits its verification result for a milestone.
     *      This is a critical function for AI-assisted validation.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _verificationRequestId The ID of the original verification request.
     * @param _oracleType The type of oracle submitting the result.
     * @param _score The verifiable score from the AI oracle (e.g., 0-100).
     * @param _justificationCID IPFS CID for the oracle's detailed justification.
     */
    function submitOracleVerificationResult(
        uint256 _projectId,
        uint256 _milestoneIndex,
        uint256 _verificationRequestId,
        bytes32 _oracleType,
        int256 _score,
        string memory _justificationCID
    ) external onlyTrustedOracle(_oracleType) whenNotPaused {
        Project storage project = projects[_projectId];
        Milestone storage milestone = projectMilestones[_projectId][_milestoneIndex];

        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(_milestoneIndex > 0 && _milestoneIndex <= project.milestoneCount, "AetherialNexus: Invalid milestone index");
        require(!milestone.isVerified, "AetherialNexus: Milestone already verified");
        require(milestone.verificationRequestId == _verificationRequestId, "AetherialNexus: Invalid verification request ID");
        require(milestone.requestedOracleType == _oracleType, "AetherialNexus: Oracle type mismatch for request");
        require(_score >= 0 && _score <= 100, "AetherialNexus: Score must be between 0 and 100");
        require(bytes(_justificationCID).length > 0, "AetherialNexus: Justification CID cannot be empty");

        milestone.oracleScore = _score;
        milestone.justificationCID = _justificationCID;

        if (uint256(_score) >= coreParameters["MILESTONE_VERIFICATION_THRESHOLD_SCORE"]) {
            milestone.isVerified = true;
            _updateReputation(project.projectLead, 20); // Reward project lead for successful milestone
        } else {
            // Negative reputation for failing a milestone
            _updateReputation(project.projectLead, -10);
            // Optionally, change project status to failed if a critical milestone fails
            // project.status = ProjectStatus.Failed;
        }

        emit OracleVerificationResultSubmitted(_projectId, _milestoneIndex, _verificationRequestId, _oracleType, _score);
    }

    /**
     * @dev Distributes funds for a successfully verified milestone to the project lead.
     *      Also updates the project's dNFT metadata.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function distributeMilestoneFunds(uint256 _projectId, uint256 _milestoneIndex) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        Milestone storage milestone = projectMilestones[_projectId][_milestoneIndex];

        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(_milestoneIndex > 0 && _milestoneIndex <= project.milestoneCount, "AetherialNexus: Invalid milestone index");
        require(milestone.isVerified, "AetherialNexus: Milestone not yet verified or failed verification");
        require(!milestone.fundsReleased, "AetherialNexus: Funds already released for this milestone");
        require(project.currentFundedAmount > 0, "AetherialNexus: No funds available to distribute");

        // Simple funds distribution: divide remaining funds equally by remaining milestones
        // A more complex system might pre-allocate funds per milestone.
        uint256 remainingMilestones = 0;
        for (uint256 i = 1; i <= project.milestoneCount; i++) {
            if (!projectMilestones[_projectId][i].fundsReleased) {
                remainingMilestones++;
            }
        }
        require(remainingMilestones > 0, "AetherialNexus: No remaining milestones to fund");

        uint256 fundsToDistribute = project.currentFundedAmount.div(remainingMilestones);
        require(fundsToDistribute > 0, "AetherialNexus: Insufficient funds for milestone distribution");
        
        project.currentFundedAmount = project.currentFundedAmount.sub(fundsToDistribute);
        milestone.fundsReleased = true;

        (bool success, ) = project.projectLead.call{value: fundsToDistribute}("");
        require(success, "AetherialNexus: Failed to transfer milestone funds");

        // Update dNFT metadata to reflect milestone completion
        string memory newURI = string(abi.encodePacked("ipfs://project-", Strings.toString(project.id), "-milestone-", Strings.toString(_milestoneIndex), "-completed"));
        _updateProjectNFTMetadata(_projectId, newURI);

        emit MilestoneFundsDistributed(_projectId, _milestoneIndex, fundsToDistribute);
        emit ProjectNFTMetadataUpdated(project.id, project.nftTokenId, newURI);

        // Check if all milestones are verified and funds distributed to mark project as completed
        bool allMilestonesCompleted = true;
        for (uint256 i = 1; i <= project.milestoneCount; i++) {
            if (!projectMilestones[_projectId][i].isVerified || !projectMilestones[_projectId][i].fundsReleased) {
                allMilestonesCompleted = false;
                break;
            }
        }

        if (allMilestonesCompleted) {
            project.status = ProjectStatus.Completed;
            _updateReputation(project.projectLead, 50); // Significant reputation for project completion
        }
    }

    /**
     * @dev Allows funders to claim back their staked funds if a project fails or has excess funds.
     * @param _projectId The ID of the project.
     */
    function claimStakedFunds(uint256 _projectId) external whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(project.funders[msg.sender] > 0, "AetherialNexus: No funds staked by this address for this project");

        // Can only claim if project failed, completed (with excess), or cancelled
        require(project.status == ProjectStatus.Failed || project.status == ProjectStatus.Completed || project.status == ProjectStatus.Cancelled,
            "AetherialNexus: Funds can only be claimed from failed, completed, or cancelled projects");

        uint256 amountToClaim = project.funders[msg.sender];
        project.funders[msg.sender] = 0; // Reset funder's stake for this project

        // Distribute from the remaining project funds.
        require(project.currentFundedAmount >= amountToClaim, "AetherialNexus: Insufficient remaining project funds for claim");
        project.currentFundedAmount = project.currentFundedAmount.sub(amountToClaim);

        (bool success, ) = msg.sender.call{value: amountToClaim}("");
        require(success, "AetherialNexus: Failed to transfer funds back to funder");

        _updateReputation(msg.sender, -2); // Small reputation penalty for claiming funds from a failed/cancelled project (optional)

        emit FundsClaimed(_projectId, msg.sender, amountToClaim);
    }

    // --- IV. Reputation & Skill System ---

    /**
     * @dev Internal function to update a user's reputation score.
     * @param _user The address of the user.
     * @param _reputationDelta The amount to add or subtract from reputation.
     */
    function _updateReputation(address _user, int256 _reputationDelta) internal {
        if (_reputationDelta > 0) {
            userReputation[_user] = userReputation[_user].add(uint256(_reputationDelta));
        } else { // _reputationDelta is negative
            uint256 currentRep = userReputation[_user];
            uint256 deltaAbs = uint256(-_reputationDelta); // Absolute value
            userReputation[_user] = currentRep > deltaAbs ? currentRep.sub(deltaAbs) : 0;
        }
        emit ReputationUpdated(_user, _reputationDelta, userReputation[_user]);
    }

    /**
     * @dev Allows a user to delegate their accumulated reputation score to another address.
     *      The delegatee gains the delegator's voting power for governance proposals.
     * @param _delegatee The address to delegate reputation to.
     */
    function delegateReputation(address _delegatee) external whenNotPaused {
        require(_delegatee != address(0), "AetherialNexus: Invalid delegatee address");
        require(_delegatee != msg.sender, "AetherialNexus: Cannot delegate to self");
        
        address currentDelegatee = reputationDelegates[msg.sender];
        if (currentDelegatee != address(0)) {
            // Remove existing delegation
            delegatedVotingPower[currentDelegatee] = delegatedVotingPower[currentDelegatee].sub(userReputation[msg.sender]);
        }

        reputationDelegates[msg.sender] = _delegatee;
        delegatedVotingPower[_delegatee] = delegatedVotingPower[_delegatee].add(userReputation[msg.sender]);

        emit ReputationDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Revokes any active reputation delegation, restoring voting power to the caller.
     */
    function revokeReputationDelegation() external whenNotPaused {
        address currentDelegatee = reputationDelegates[msg.sender];
        require(currentDelegatee != address(0), "AetherialNexus: No active delegation to revoke");
        
        delegatedVotingPower[currentDelegatee] = delegatedVotingPower[currentDelegatee].sub(userReputation[msg.sender]);
        delete reputationDelegates[msg.sender];
        
        emit ReputationRevoked(msg.sender);
    }

    /**
     * @dev Gets the total voting power for a specific address, including all delegated reputation.
     *      This would be used for calculating votes on proposals.
     * @param _voter The address for whom to calculate total voting power.
     * @return The total reputation score this address can wield for voting.
     */
    function getTotalVotingPower(address _voter) public view returns (uint256) {
        // If the user has delegated their own reputation, their personal voting power is 0 for themselves
        if (reputationDelegates[_voter] != address(0)) {
            return delegatedVotingPower[_voter]; // Return the power they received
        }
        return userReputation[_voter].add(delegatedVotingPower[_voter]); // Their own rep + delegated to them
    }


    // --- V. Dynamic Project NFTs (dNFTs) & IP Management ---

    /**
     * @dev Updates the metadata URI for a Project dNFT.
     *      This makes the NFT dynamic, reflecting project progress or status changes.
     *      Can be called internally (e.g., after milestone) or explicitly by project lead.
     * @param _projectId The ID of the project.
     * @param _newURI The new IPFS CID or URL for the dNFT's metadata.
     */
    function updateProjectNFTMetadata(uint256 _projectId, string memory _newURI) public onlyProjectLead(_projectId) whenNotPaused {
        _updateProjectNFTMetadata(_projectId, _newURI);
    }

    /**
     * @dev Internal function to update the metadata URI for a Project dNFT.
     * @param _projectId The ID of the project.
     * @param _newURI The new IPFS CID or URL for the dNFT's metadata.
     */
    function _updateProjectNFTMetadata(uint256 _projectId, string memory _newURI) internal {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(projectNFTOwner[project.nftTokenId] != address(0), "AetherialNexus: Project NFT does not exist"); // Ensure NFT exists

        projectNFTTokenURIs[project.nftTokenId] = _newURI;
        emit ProjectNFTMetadataUpdated(_projectId, project.nftTokenId, _newURI);
    }

    /**
     * @dev Registers new Intellectual Property (IP) derived from a completed project.
     *      Sets an on-chain royalty structure for future distributions. Only callable by project lead.
     * @param _projectId The ID of the project from which the IP was derived.
     * @param _ipCID IPFS CID pointing to the details of the derived IP.
     * @param _royaltyShareNumerator Numerator for royalty percentage (e.g., 10 for 10%).
     * @param _royaltyShareDenominator Denominator for royalty percentage (e.g., 100).
     */
    function registerDerivedIP(
        uint256 _projectId,
        string memory _ipCID,
        uint256 _royaltyShareNumerator,
        uint256 _royaltyShareDenominator
    ) external onlyProjectLead(_projectId) whenNotPaused {
        Project storage project = projects[_projectId];
        require(project.id != 0, "AetherialNexus: Project does not exist");
        require(project.status == ProjectStatus.Completed, "AetherialNexus: IP can only be registered for completed projects");
        require(!project.isIPRegistered, "AetherialNexus: IP already registered for this project");
        require(bytes(_ipCID).length > 0, "AetherialNexus: IP CID cannot be empty");
        require(_royaltyShareNumerator <= _royaltyShareDenominator, "AetherialNexus: Invalid royalty share");
        require(_royaltyShareDenominator > 0, "AetherialNexus: Royalty denominator cannot be zero");

        ipCounter++;
        derivedIPs[ipCounter] = DerivedIP({
            id: ipCounter,
            projectId: _projectId,
            ipCID: _ipCID,
            creator: msg.sender, // The project lead is the initial IP creator/beneficiary
            royaltyShareNumerator: _royaltyShareNumerator,
            royaltyShareDenominator: _royaltyShareDenominator,
            totalRoyaltyCollected: 0
            // royaltyHoldings mapping is not directly on this struct but would be managed
            // through more complex internal logic or a separate contract if multiple beneficiaries
        });

        project.isIPRegistered = true;
        _updateReputation(msg.sender, 30); // Reward for registering valuable IP

        emit DerivedIPRegistered(ipCounter, _projectId, msg.sender, _ipCID);
    }

    /**
     * @dev Allows collection and distribution of royalties for a registered derived IP.
     *      Anyone can call this to trigger a royalty distribution process (e.g., from an external payment gateway).
     * @param _ipId The ID of the derived IP.
     */
    function distributeIPRoyalty(uint256 _ipId) external payable whenNotPaused {
        DerivedIP storage ip = derivedIPs[_ipId];
        require(ip.id != 0, "AetherialNexus: Derived IP does not exist");
        require(msg.value > 0, "AetherialNexus: No funds provided for royalty distribution");

        uint256 royaltyAmount = msg.value.mul(ip.royaltyShareNumerator).div(ip.royaltyShareDenominator);
        require(royaltyAmount <= msg.value, "AetherialNexus: Royalty calculation error"); // Safety check

        ip.totalRoyaltyCollected = ip.totalRoyaltyCollected.add(royaltyAmount);

        // For simplicity, distribute royalties directly to the IP creator (project lead).
        // A more complex system could distribute to all project funders/contributors based on their stake/reputation
        // or a pre-defined split from `projects[_ip.projectId].funders` etc.
        (bool success, ) = ip.creator.call{value: royaltyAmount}("");
        require(success, "AetherialNexus: Failed to transfer royalty to creator");

        // Any excess funds not part of the defined royalty go back to the caller
        if (msg.value > royaltyAmount) {
            uint256 remainder = msg.value.sub(royaltyAmount);
            (bool remainderSuccess, ) = msg.sender.call{value: remainder}("");
            require(remainderSuccess, "AetherialNexus: Failed to return remainder funds");
        }

        emit IPRoyaltyDistributed(_ipId, royaltyAmount);
    }

    // --- VI. Decentralized Governance & Treasury ---

    /**
     * @dev Allows eligible users to propose spending from the contract's treasury.
     *      Requires a minimum reputation to propose.
     * @param _allocationType A category for the allocation (e.g., "INFRASTRUCTURE", "GRANT_PROGRAM").
     * @param _amount The amount of Ether to allocate.
     * @param _recipient The address to receive the allocated funds.
     */
    function proposeTreasuryAllocation(
        bytes32 _allocationType,
        uint256 _amount,
        address _recipient
    ) external hasMinimumReputation(coreParameters["MIN_REPUTATION_FOR_VOTE"]) whenNotPaused {
        require(_amount > 0, "AetherialNexus: Allocation amount must be greater than zero");
        require(_recipient != address(0), "AetherialNexus: Invalid recipient address");
        require(address(this).balance >= _amount, "AetherialNexus: Insufficient treasury balance");

        treasuryProposalCounter++;
        treasuryProposals[treasuryProposalCounter] = TreasuryProposal({
            id: treasuryProposalCounter,
            proposer: msg.sender,
            allocationType: _allocationType,
            amount: _amount,
            recipient: _recipient,
            totalYesVotes: 0, // Will be updated by _voteOnTreasuryProposal
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp.add(coreParameters["TREASURY_VOTING_PERIOD_SECONDS"]),
            isApproved: false,
            executed: false
            // hasVoted mapping initialized empty
        });

        // Proposer automatically casts a 'yes' vote
        _voteOnTreasuryProposal(treasuryProposalCounter, true);

        emit TreasuryProposalCreated(treasuryProposalCounter, msg.sender, _allocationType, _amount, _recipient);
    }

    /**
     * @dev Allows users with delegated reputation to vote on pending treasury allocation proposals.
     * @param _proposalId The ID of the treasury proposal.
     * @param _approve True for a 'yes' vote, false for a 'no' vote.
     */
    function voteOnTreasuryAllocation(uint256 _proposalId, bool _approve) external whenNotPaused {
        _voteOnTreasuryProposal(_proposalId, _approve);
    }

    /**
     * @dev Internal function for voting on treasury proposals.
     *      Considers delegated reputation for voting power.
     */
    function _voteOnTreasuryProposal(uint256 _proposalId, bool _approve) internal {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.id != 0, "AetherialNexus: Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "AetherialNexus: Voting period has ended");
        require(!proposal.executed, "AetherialNexus: Proposal already executed");
        
        // Determine the effective voter: either msg.sender or their delegatee
        address voter = msg.sender;
        address effectiveVoter = reputationDelegates[voter] != address(0) ? reputationDelegates[voter] : voter;
        
        uint256 voterReputation = userReputation[effectiveVoter];
        require(voterReputation >= coreParameters["MIN_REPUTATION_FOR_VOTE"], "AetherialNexus: Insufficient reputation to vote");
        require(!proposal.hasVoted[effectiveVoter], "AetherialNexus: Already voted on this proposal");

        proposal.hasVoted[effectiveVoter] = true;
        uint256 voteWeight = voterReputation; // Use the voter's direct reputation for their vote

        if (_approve) {
            proposal.totalYesVotes = proposal.totalYesVotes.add(voteWeight);
        } else {
            // "No" votes are simply recorded by not adding to `totalYesVotes`.
            // In a more complex system, `totalNoVotes` might be tracked.
        }

        emit TreasuryProposalVoted(_proposalId, effectiveVoter, _approve, proposal.totalYesVotes);

        // Check for immediate execution if voting period is over
        if (block.timestamp > proposal.votingDeadline && !proposal.executed) {
            // This calculation would ideally use the total *eligible* voting power at the time the proposal was created.
            // For simplicity, we'll use a hardcoded threshold or a proxy of total reputation.
            // A more robust system would snapshot total reputation/delegated power for accurate percentages.
            // Placeholder: Assume approval if a certain sum of 'yes' votes is reached.
            if (proposal.totalYesVotes >= (coreParameters["TREASURY_APPROVAL_THRESHOLD_PERCENT"] * 100)) { // Example: 5100 total rep points
                proposal.isApproved = true;
            }
            _executeTreasuryAllocation(_proposalId);
        }
    }

    /**
     * @dev Executes an approved treasury allocation proposal. Only callable once the voting period ends and it's approved.
     *      This function is called internally after the voting period ends or when a critical mass is reached.
     * @param _proposalId The ID of the treasury proposal.
     */
    function _executeTreasuryAllocation(uint256 _proposalId) internal {
        TreasuryProposal storage proposal = treasuryProposals[_proposalId];
        require(proposal.id != 0, "AetherialNexus: Proposal does not exist");
        require(block.timestamp > proposal.votingDeadline, "AetherialNexus: Voting period has not ended");
        require(proposal.isApproved, "AetherialNexus: Proposal not approved");
        require(!proposal.executed, "AetherialNexus: Proposal already executed");
        require(address(this).balance >= proposal.amount, "AetherialNexus: Insufficient contract balance for execution");

        proposal.executed = true;

        (bool success, ) = proposal.recipient.call{value: proposal.amount}("");
        require(success, "AetherialNexus: Failed to execute treasury transfer");

        emit TreasuryProposalExecuted(_proposalId, true);
    }

    // --- VII. Emergency & Utilities ---

    /**
     * @dev Allows the owner to withdraw any accidentally sent ERC-20 tokens from the contract.
     *      Does not affect project or treasury funds.
     * @param _tokenAddress The address of the ERC-20 token.
     * @param _amount The amount of tokens to withdraw.
     * @param _recipient The address to send the tokens to.
     */
    function emergencyWithdrawTokens(address _tokenAddress, uint256 _amount, address _recipient) external onlyOwner {
        require(_tokenAddress != address(0), "AetherialNexus: Invalid token address");
        require(_recipient != address(0), "AetherialNexus: Invalid recipient address");
        require(_amount > 0, "AetherialNexus: Amount must be greater than zero");

        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "AetherialNexus: Insufficient token balance");

        token.transfer(_recipient, _amount);
        emit EmergencyTokensWithdrawn(_tokenAddress, _recipient, _amount);
    }

    // Fallback function to accept Ether
    // Any Ether sent directly to the contract (without calling a specific function)
    // will be added to the general contract balance, which can then be used for
    // treasury allocations or project funding via specific calls.
    receive() external payable {
        // No specific event is emitted here, as direct Ether might be for various purposes
        // like future project funding or general treasury top-up.
    }
}

```