```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For basic arithmetic safety

/*
*   Contract Name: AetherForge
*   Description: AetherForge is a pioneering Decentralized Autonomous Research & Development Lab (DARL)
*   designed for collaborative innovation. It empowers "Artisans" to propose and fund "Blueprints" (projects),
*   contribute "Essence" (resources and expertise), and collectively "Forge Artifacts" (dynamic NFTs
*   representing intellectual property or project outputs). The platform integrates a sophisticated
*   reputation system, simulated AI oracle for intelligent project evaluation and ideation, and
*   on-chain governance mechanisms to foster a thriving, self-regulating ecosystem of creators and innovators.
*
*   Core Concepts:
*   - Blueprints: Detailed project proposals defining objectives, milestones, and resource requirements.
*   - Essence: The foundational currency and resource within AetherForge, primarily contributed as ETH,
*     representing commitment and value.
*   - Artifacts: Dynamic NFTs (ERC-721 based) that encapsulate the intellectual property, output, or
*     completed state of a Blueprint. Their metadata and associated rights (e.g., royalty distribution) can evolve.
*   - Artisan Reputation: A non-transferable, on-chain score reflecting an Artisan's proven contributions,
*     successful project deliveries, and peer endorsements, influencing their privileges and trust within
*     the ecosystem.
*   - AI Oracle Integration (Simulated): A design pattern for intelligent agents (AI) to interact with
*     and augment the R&D process, offering evaluations, ideation, and automated task execution.
*
*/

/*
*   Function Summary:
*
*   I. Blueprint & Project Management:
*   1.  proposeBlueprint(string _name, string _descriptionHash, uint256 _requiredEssence, uint256 _milestoneCount, bytes32[] _milestoneHashes)
*       - Initiates a new project proposal, detailing its scope, funding, and milestones.
*   2.  contributeEssence(uint256 _blueprintId)
*       - Allows Artisans to contribute funds (Essence) to a proposed or active Blueprint, moving it towards completion.
*   3.  approveMilestoneCompletion(uint256 _blueprintId, uint256 _milestoneIndex)
*       - Marks a specific project milestone as successfully completed, enabling fund releases and progress tracking.
*   4.  forgeArtifact(uint256 _blueprintId, string _artifactUri, address[] _contributors, uint256[] _contributionWeights)
*       - Mints a new dynamic Artifact NFT upon project completion, allocating initial ownership and royalty shares
*         based on contributor weights.
*   5.  updateArtifactMetadata(uint256 _artifactId, string _newUri)
*       - Allows the primary owner of an Artifact NFT to update its associated metadata URI, reflecting evolution or new insights.
*   6.  transferArtifactOwnership(uint256 _artifactId, address _to)
*       - Transfers full ownership of an Artifact NFT to a new address.
*   7.  setArtifactRoyalties(uint256 _artifactId, address[] _recipients, uint96[] _basisPoints)
*       - Defines the on-chain royalty distribution for an Artifact, specifying multiple recipients and their respective shares.
*   8.  claimRoyalties(uint256 _artifactId)
*       - Enables designated royalty recipients to claim their accrued earnings from an Artifact.
*   9.  withdrawProjectFunds(uint256 _blueprintId, uint256 _amount)
*       - Allows the Blueprint lead to withdraw released funds after milestone approvals for project expenditures.
*   10. disputeMilestone(uint256 _blueprintId, uint256 _milestoneIndex, string _reasonHash)
*       - Initiates a formal dispute against a claimed milestone completion, triggering a review process.
*
*   II. Artisan Reputation & Governance:
*   11. stakeEssenceForReputation(uint256 _amount)
*       - Artisans can stake Essence to boost their reputation score over time, demonstrating long-term commitment.
*   12. delegateReputation(address _delegatee)
*       - Allows an Artisan to delegate their voting power (reputation) to another Artisan.
*   13. voteOnBlueprintProposal(uint256 _blueprintId, bool _approve)
*       - Artisans use their reputation to vote on whether to approve a new Blueprint proposal.
*   14. proposeArtisanCouncilMember(address _newMember)
*       - Initiates a proposal to add a new member to the governing Artisan Council.
*   15. voteOnCouncilProposal(uint256 _proposalId, bool _approve)
*       - Council members (or high-reputation Artisans) vote on specific governance proposals.
*   16. penalizeArtisan(address _artisan, uint256 _reputationLoss)
*       - The Artisan Council can enact penalties, reducing an Artisan's reputation for severe misconduct.
*
*   III. AI Oracle & Automated Task Integration (Simulated):
*   17. requestAIEvaluation(uint256 _blueprintId, string _promptHash)
*       - Requests an external AI oracle to provide an evaluation or feedback on a specific Blueprint.
*   18. fulfillAIEvaluation(uint256 _blueprintId, bytes32 _requestId, string _evaluationResultHash, uint256 _confidenceScore)
*       - (Internal/Oracle-only) Receives and records the AI oracle's evaluation result for a requested Blueprint.
*   19. initiateAutonomousTask(uint256 _blueprintId, string _taskDescriptionHash, uint256 _essenceReward)
*       - A Blueprint lead can define an automated task, potentially to be picked up and executed by an AI agent or bot
*         for a specified Essence reward.
*
*   IV. Advanced Access & Utility:
*   20. mintSubscriptionNFT(address _recipient, uint256 _tier, uint256 _duration)
*       - Mints a special ERC-721 Subscription NFT, granting tiered and time-bound access to exclusive AetherForge features or resources.
*
*/

contract AetherForge is Context, Ownable, IERC721, IERC721Metadata {
    using SafeMath for uint256;

    // --- Enums ---

    enum BlueprintStatus { Proposed, Active, Completed, Disputed, Canceled }
    enum AIRequestStatus { Pending, Fulfilled, Canceled }
    enum TaskStatus { Proposed, Assigned, Completed, Failed }
    enum CouncilProposalStatus { Active, Approved, Rejected }

    // --- Structs ---

    struct Blueprint {
        address payable projectLead;
        string name;
        string descriptionHash; // IPFS hash or similar
        uint256 requiredEssence; // ETH amount
        uint256 contributedEssence; // Total ETH contributed
        uint256 totalMilestones;
        uint256 currentCompletedMilestone; // 0-indexed, up to totalMilestones-1
        bytes32[] milestoneHashes; // Hashes of milestone descriptions/proofs
        BlueprintStatus status;
        uint256 aiEvaluationScore; // 0-100, set by AI oracle
        bool aiEvaluationRequested;
        uint256 artifactId; // 0 if no artifact yet
        mapping(address => uint256) essenceContributions; // Track individual contributions
        mapping(uint256 => bool) milestoneApproved; // Track approved milestones
    }

    struct Artifact {
        uint256 blueprintId;
        address currentOwner; // ERC721 owner
        string tokenURI; // Dynamic metadata URI
        uint96[] royaltyBasisPoints; // Basis points for each recipient (sum must be <= 10000)
        address[] royaltyRecipients; // Addresses corresponding to basis points
        mapping(address => uint256) claimedRoyalties; // Amount already claimed by recipient
        // `accruedRoyalties` is usually managed off-chain or by a payment splitter.
        // For simplicity, we'll simulate it being updated when claimRoyalties is called
        // for "external" sales, but not implement the full EIP-2981 `royaltyInfo` getter.
    }

    struct Artisan {
        uint256 reputationScore;
        uint256 stakedEssence; // Amount of Essence (ETH) staked for reputation
        address delegatee; // Address this Artisan's reputation is delegated to
        uint256 subscriptionNFTId; // 0 if no active subscription
    }

    struct AIEvaluationRequest {
        uint256 blueprintId;
        address requester;
        string promptHash;
        bytes32 requestId; // Unique ID for the request
        AIRequestStatus status;
        string evaluationResultHash;
        uint256 confidenceScore; // 0-100
        uint256 timestamp;
    }

    struct AutonomousTask {
        uint256 blueprintId;
        address initiator;
        string taskDescriptionHash;
        uint256 essenceReward;
        address assignedTo; // Address of AI agent or bot (or human)
        TaskStatus status;
    }

    struct CouncilProposal {
        address proposer;
        address targetAddress; // For adding/removing members, or other generic actions
        string descriptionHash;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks council member votes
        CouncilProposalStatus status;
    }

    struct SubscriptionNFT {
        address owner; // ERC721 owner
        uint256 tier; // e.g., 1, 2, 3
        uint256 expiryTimestamp;
        string tokenURI;
    }

    // --- State Variables ---

    uint256 public nextBlueprintId;
    mapping(uint256 => Blueprint) public blueprints;
    mapping(uint256 => mapping(address => bool)) public blueprintVoters; // blueprintId => voterAddress => voted

    uint256 public nextArtifactId;
    mapping(uint256 => Artifact) public artifacts;
    mapping(address => uint256) private _artifactBalance; // ERC721 balance of artifacts
    mapping(uint256 => address) private _artifactOwner; // ERC721 owner of artifact
    mapping(uint256 => address) private _artifactApprovals; // ERC721 approval
    mapping(address => mapping(address => bool)) private _artifactOperatorApprovals; // ERC721 operator approval

    uint256 public nextSubscriptionNFTId;
    mapping(uint256 => SubscriptionNFT) public subscriptionNFTs;
    mapping(address => uint256) private _subscriptionBalance; // ERC721 balance of subscription NFTs
    mapping(uint256 => address) private _subscriptionOwner; // ERC721 owner of subscription NFT
    mapping(uint256 => address) private _subscriptionApprovals; // ERC721 approval
    mapping(address => mapping(address => bool)) private _subscriptionOperatorApprovals; // ERC721 operator approval

    mapping(address => Artisan) public artisans;
    mapping(address => bool) public artisanCouncil; // Members of the Artisan Council

    uint256 public nextAIEvaluationRequestId;
    mapping(bytes32 => AIEvaluationRequest) public aiEvaluationRequests; // requestId -> AIEvaluationRequest

    uint256 public nextAutonomousTaskId;
    mapping(uint256 => AutonomousTask) public autonomousTasks;

    uint256 public nextCouncilProposalId;
    mapping(uint256 => CouncilProposal) public councilProposals;

    address public aiOracleAddress; // The trusted address for AI oracle callbacks
    uint256 public constant MIN_REPUTATION_FOR_COUNCIL_VOTE = 1000; // Example threshold

    // ERC721 metadata
    string private _artifactName = "AetherForge Artifact";
    string private _artifactSymbol = "AFA";
    string private _subscriptionName = "AetherForge Subscription";
    string private _subscriptionSymbol = "AFS";

    // --- Events ---

    event BlueprintProposed(uint256 indexed blueprintId, address indexed projectLead, string name, uint256 requiredEssence);
    event EssenceContributed(uint256 indexed blueprintId, address indexed contributor, uint256 amount, uint256 totalContributed);
    event MilestoneApproved(uint256 indexed blueprintId, uint256 indexed milestoneIndex);
    event ArtifactForged(uint256 indexed blueprintId, uint256 indexed artifactId, address indexed owner);
    event ArtifactMetadataUpdated(uint256 indexed artifactId, string newUri);
    event ArtifactTransfer(uint256 indexed artifactId, address indexed from, address indexed to);
    event RoyaltySet(uint256 indexed artifactId, address[] recipients, uint96[] basisPoints);
    event RoyaltiesClaimed(uint256 indexed artifactId, address indexed recipient, uint256 amount);
    event ProjectFundsWithdrawn(uint256 indexed blueprintId, address indexed lead, uint256 amount);
    event MilestoneDisputed(uint256 indexed blueprintId, uint256 indexed milestoneIndex, address indexed disputer, string reasonHash);

    event ReputationStaked(address indexed artisan, uint256 amount, uint256 newReputation);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event BlueprintVoted(uint256 indexed blueprintId, address indexed voter, bool approved, uint256 reputationWeight);
    event CouncilProposalInitiated(uint256 indexed proposalId, address indexed proposer, address indexed target);
    event CouncilVoted(uint256 indexed proposalId, address indexed voter, bool approved);
    event ArtisanPenalized(address indexed artisan, uint256 reputationLoss, address indexed enforcer);
    event ArtisanCouncilMemberAdded(address indexed member);

    event AIEvaluationRequested(uint256 indexed blueprintId, address indexed requester, bytes32 indexed requestId, string promptHash);
    event AIEvaluationFulfilled(uint256 indexed blueprintId, bytes32 indexed requestId, string evaluationResultHash, uint256 confidenceScore);
    event AutonomousTaskInitiated(uint256 indexed blueprintId, uint256 indexed taskId, address indexed initiator, uint256 essenceReward);

    event SubscriptionNFTMinted(uint256 indexed tokenId, address indexed recipient, uint256 tier, uint256 expiryTimestamp);

    // --- Modifiers ---

    modifier onlyProjectLead(uint256 _blueprintId) {
        require(blueprints[_blueprintId].projectLead == _msgSender(), "AF: Not project lead");
        _;
    }

    modifier onlyArtisanCouncil() {
        require(artisanCouncil[_msgSender()], "AF: Not an Artisan Council member");
        _;
    }

    modifier onlyAIOrcle() {
        require(_msgSender() == aiOracleAddress, "AF: Not the AI Oracle address");
        _;
    }

    modifier onlyBlueprintActive(uint256 _blueprintId) {
        require(blueprints[_blueprintId].status == BlueprintStatus.Active, "AF: Blueprint not active");
        _;
    }

    modifier onlyBlueprintProposed(uint256 _blueprintId) {
        require(blueprints[_blueprintId].status == BlueprintStatus.Proposed, "AF: Blueprint not in proposed status");
        _;
    }

    // --- Constructor ---

    constructor(address _aiOracleAddress, address[] memory _initialCouncilMembers) Ownable(_msgSender()) {
        require(_aiOracleAddress != address(0), "AF: AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;

        // Initialize Artisan Council with initial members
        for (uint256 i = 0; i < _initialCouncilMembers.length; i++) {
            require(_initialCouncilMembers[i] != address(0), "AF: Council member cannot be zero address");
            artisanCouncil[_initialCouncilMembers[i]] = true;
            artisans[_initialCouncilMembers[i]].reputationScore = 5000; // Grant initial high reputation
            emit ArtisanCouncilMemberAdded(_initialCouncilMembers[i]);
        }
    }

    // --- Core Project Lifecycle & Management ---

    /// @notice Proposes a new project Blueprint.
    /// @param _name The name of the blueprint.
    /// @param _descriptionHash IPFS hash or similar URI for blueprint description.
    /// @param _requiredEssence The total ETH required for the blueprint.
    /// @param _milestoneCount The number of milestones for the blueprint.
    /// @param _milestoneHashes Hashes describing each milestone.
    function proposeBlueprint(
        string memory _name,
        string memory _descriptionHash,
        uint256 _requiredEssence,
        uint256 _milestoneCount,
        bytes32[] memory _milestoneHashes
    ) public {
        require(bytes(_name).length > 0, "AF: Name cannot be empty");
        require(bytes(_descriptionHash).length > 0, "AF: Description hash cannot be empty");
        require(_requiredEssence > 0, "AF: Required essence must be greater than zero");
        require(_milestoneCount > 0, "AF: Must have at least one milestone");
        require(_milestoneHashes.length == _milestoneCount, "AF: Milestone hashes count mismatch");

        uint256 blueprintId = nextBlueprintId++;
        blueprints[blueprintId] = Blueprint({
            projectLead: payable(_msgSender()),
            name: _name,
            descriptionHash: _descriptionHash,
            requiredEssence: _requiredEssence,
            contributedEssence: 0,
            totalMilestones: _milestoneCount,
            currentCompletedMilestone: 0,
            milestoneHashes: _milestoneHashes,
            status: BlueprintStatus.Proposed,
            aiEvaluationScore: 0,
            aiEvaluationRequested: false,
            artifactId: 0
        });

        // Grant initial reputation to project lead
        artisans[_msgSender()].reputationScore = artisans[_msgSender()].reputationScore.add(100);

        emit BlueprintProposed(blueprintId, _msgSender(), _name, _requiredEssence);
    }

    /// @notice Allows Artisans to contribute funds (Essence) to a proposed or active Blueprint.
    /// @param _blueprintId The ID of the blueprint to contribute to.
    function contributeEssence(uint256 _blueprintId) public payable {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.projectLead != address(0), "AF: Blueprint does not exist");
        require(blueprint.status == BlueprintStatus.Proposed || blueprint.status == BlueprintStatus.Active, "AF: Blueprint not in a state to receive contributions");
        require(msg.value > 0, "AF: Contribution must be greater than zero");
        require(blueprint.contributedEssence.add(msg.value) <= blueprint.requiredEssence, "AF: Contribution exceeds required essence");

        blueprint.contributedEssence = blueprint.contributedEssence.add(msg.value);
        blueprint.essenceContributions[_msgSender()] = blueprint.essenceContributions[_msgSender()].add(msg.value);
        
        // If the blueprint is fully funded, activate it
        if (blueprint.contributedEssence == blueprint.requiredEssence && blueprint.status == BlueprintStatus.Proposed) {
            blueprint.status = BlueprintStatus.Active;
        }

        // Grant reputation for contribution (e.g., 10 reputation per ETH contributed)
        artisans[_msgSender()].reputationScore = artisans[_msgSender()].reputationScore.add(msg.value.div(10**14)); // 0.0001 ETH = 1 reputation

        emit EssenceContributed(_blueprintId, _msgSender(), msg.value, blueprint.contributedEssence);
    }

    /// @notice Marks a specific project milestone as successfully completed.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _milestoneIndex The 0-indexed milestone to approve.
    function approveMilestoneCompletion(uint256 _blueprintId, uint256 _milestoneIndex) public onlyProjectLead(_blueprintId) onlyBlueprintActive(_blueprintId) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(_milestoneIndex < blueprint.totalMilestones, "AF: Invalid milestone index");
        require(_milestoneIndex == blueprint.currentCompletedMilestone, "AF: Milestones must be approved in order");
        require(!blueprint.milestoneApproved[_milestoneIndex], "AF: Milestone already approved");

        blueprint.currentCompletedMilestone = blueprint.currentCompletedMilestone.add(1);
        blueprint.milestoneApproved[_milestoneIndex] = true;

        // Optionally, grant reputation to the lead for milestone completion
        artisans[_msgSender()].reputationScore = artisans[_msgSender()].reputationScore.add(50);

        if (blueprint.currentCompletedMilestone == blueprint.totalMilestones) {
            blueprint.status = BlueprintStatus.Completed;
            // Additional logic for finalization, e.g., releasing remaining funds to lead, or flagging for artifact forging.
        }

        emit MilestoneApproved(_blueprintId, _milestoneIndex);
    }

    /// @notice Mints a new dynamic Artifact NFT upon project completion.
    /// @param _blueprintId The ID of the completed blueprint.
    /// @param _artifactUri Initial IPFS hash or similar URI for the artifact metadata.
    /// @param _contributors Addresses of initial contributors to the artifact.
    /// @param _contributionWeights Weights representing each contributor's share (sum must be 10000 for 100%).
    function forgeArtifact(
        uint256 _blueprintId,
        string memory _artifactUri,
        address[] memory _contributors,
        uint256[] memory _contributionWeights
    ) public onlyProjectLead(_blueprintId) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.Completed, "AF: Blueprint not completed");
        require(blueprint.artifactId == 0, "AF: Artifact already forged for this blueprint");
        require(bytes(_artifactUri).length > 0, "AF: Artifact URI cannot be empty");
        require(_contributors.length == _contributionWeights.length, "AF: Contributor and weight mismatch");
        require(_contributors.length > 0, "AF: Must have at least one contributor");

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < _contributionWeights.length; i++) {
            totalWeight = totalWeight.add(_contributionWeights[i]);
        }
        require(totalWeight == 10000, "AF: Total contribution weights must sum to 10000 (100%)");

        uint256 artifactId = nextArtifactId++;
        artifacts[artifactId].blueprintId = _blueprintId;
        artifacts[artifactId].currentOwner = _msgSender(); // Project lead is initial owner
        artifacts[artifactId].tokenURI = _artifactUri;
        artifacts[artifactId].royaltyRecipients = _contributors; // Initial contributors become default royalty recipients
        artifacts[artifactId].royaltyBasisPoints = new uint96[](_contributionWeights.length); // Initialize

        // Set initial royalties based on contribution weights
        for (uint256 i = 0; i < _contributionWeights.length; i++) {
            artifacts[artifactId].royaltyBasisPoints[i] = uint96(_contributionWeights[i]);
            // Grant reputation for forging an artifact
            artisans[_contributors[i]].reputationScore = artisans[_contributors[i]].reputationScore.add(100);
        }

        blueprint.artifactId = artifactId;

        // ERC721 minting logic
        _artifactBalance[_msgSender()] = _artifactBalance[_msgSender()].add(1);
        _artifactOwner[artifactId] = _msgSender();

        emit ArtifactForged(_blueprintId, artifactId, _msgSender());
        emit Transfer(address(0), _msgSender(), artifactId); // ERC721 Transfer event for mint
    }

    /// @notice Allows the primary owner of an Artifact NFT to update its associated metadata URI.
    /// @param _artifactId The ID of the Artifact NFT.
    /// @param _newUri The new IPFS hash or URI for the artifact metadata.
    function updateArtifactMetadata(uint256 _artifactId, string memory _newUri) public {
        require(artifacts[_artifactId].currentOwner == _msgSender(), "AF: Not the owner of the artifact");
        require(bytes(_newUri).length > 0, "AF: New URI cannot be empty");

        artifacts[_artifactId].tokenURI = _newUri;
        emit ArtifactMetadataUpdated(_artifactId, _newUri);
    }

    /// @notice Transfers full ownership of an Artifact NFT to a new address.
    /// @param _artifactId The ID of the Artifact NFT.
    /// @param _to The address to transfer ownership to.
    function transferArtifactOwnership(uint256 _artifactId, address _to) public {
        require(_isApprovedOrOwnerArtifact(_msgSender(), _artifactId), "AF: Caller is not owner nor approved");
        require(_to != address(0), "AF: Transfer to the zero address is not allowed");
        require(_artifactOwner[_artifactId] != _to, "AF: Transfer to current owner is not allowed");

        _transferArtifact(artifacts[_artifactId].currentOwner, _to, _artifactId);
        emit ArtifactTransfer(_artifactId, artifacts[_artifactId].currentOwner, _to);
    }

    /// @notice Defines the on-chain royalty distribution for an Artifact.
    /// @dev Sum of _basisPoints must be <= 10000.
    /// @param _artifactId The ID of the Artifact NFT.
    /// @param _recipients Array of addresses to receive royalties.
    /// @param _basisPoints Array of basis points (e.g., 100 = 1%) for each recipient.
    function setArtifactRoyalties(
        uint256 _artifactId,
        address[] memory _recipients,
        uint96[] memory _basisPoints
    ) public {
        require(artifacts[_artifactId].currentOwner == _msgSender(), "AF: Not the owner of the artifact");
        require(_recipients.length == _basisPoints.length, "AF: Recipient and basis point arrays mismatch");

        uint256 totalBasisPoints = 0;
        for (uint256 i = 0; i < _basisPoints.length; i++) {
            require(_recipients[i] != address(0), "AF: Royalty recipient cannot be zero address");
            totalBasisPoints = totalBasisPoints.add(_basisPoints[i]);
        }
        require(totalBasisPoints <= 10000, "AF: Total basis points exceed 10000 (100%)");

        artifacts[_artifactId].royaltyRecipients = _recipients;
        artifacts[_artifactId].royaltyBasisPoints = _basisPoints;

        emit RoyaltySet(_artifactId, _recipients, _basisPoints);
    }

    /// @notice Enables designated royalty recipients to claim their accrued earnings from an Artifact.
    /// @dev This function assumes that external sales of artifacts are tracked off-chain, and funds are sent to AetherForge.
    /// @dev For simplicity, this function just lets recipients claim from `accruedRoyalties` which would be manually updated
    ///      by, e.g., the contract owner in a real scenario to simulate sales.
    /// @param _artifactId The ID of the Artifact NFT.
    function claimRoyalties(uint256 _artifactId) public {
        Artifact storage artifact = artifacts[_artifactId];
        uint256 amount = artifact.accruedRoyalties[_msgSender()];
        require(amount > 0, "AF: No royalties accrued for this address");

        artifact.accruedRoyalties[_msgSender()] = 0; // Reset accrued
        artifact.claimedRoyalties[_msgSender()] = artifact.claimedRoyalties[_msgSender()].add(amount);

        // Send ETH to the claimant
        payable(_msgSender()).transfer(amount);

        emit RoyaltiesClaimed(_artifactId, _msgSender(), amount);
    }
    
    // External function to simulate external sales contributing to royalties (only callable by owner for simulation)
    function simulateExternalSale(uint256 _artifactId, uint256 _salePrice) public onlyOwner {
        Artifact storage artifact = artifacts[_artifactId];
        require(artifact.blueprintId != 0, "AF: Artifact does not exist"); // Check if artifact is valid
        require(_salePrice > 0, "AF: Sale price must be positive");

        for (uint256 i = 0; i < artifact.royaltyRecipients.length; i++) {
            address recipient = artifact.royaltyRecipients[i];
            uint256 royaltyAmount = _salePrice.mul(artifact.royaltyBasisPoints[i]).div(10000);
            artifact.accruedRoyalties[recipient] = artifact.accruedRoyalties[recipient].add(royaltyAmount);
        }
    }


    /// @notice Allows the Blueprint lead to withdraw released funds after milestone approvals for project expenditures.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _amount The amount of Essence (ETH) to withdraw.
    function withdrawProjectFunds(uint256 _blueprintId, uint256 _amount) public onlyProjectLead(_blueprintId) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.projectLead != address(0), "AF: Blueprint does not exist");
        require(_amount > 0, "AF: Amount must be greater than zero");
        
        // Funds available for withdrawal are based on completed milestones
        // For simplicity, we'll allow withdrawal up to the full contributed amount if all milestones are approved.
        // In a real system, a more granular vesting schedule per milestone would be used.
        uint256 availableFunds = blueprint.contributedEssence; 
        if (blueprint.currentCompletedMilestone < blueprint.totalMilestones) {
            // Only allow withdrawal proportionate to completed milestones
            availableFunds = blueprint.contributedEssence.mul(blueprint.currentCompletedMilestone).div(blueprint.totalMilestones);
        }
        
        uint256 alreadyWithdrawn = blueprint.contributedEssence.sub(address(this).balance); // Simplistic way to check
        require(availableFunds.sub(alreadyWithdrawn) >= _amount, "AF: Insufficient funds cleared for withdrawal or already withdrawn");

        // Transfer funds
        payable(_msgSender()).transfer(_amount);

        emit ProjectFundsWithdrawn(_blueprintId, _msgSender(), _amount);
    }


    /// @notice Initiates a formal dispute against a claimed milestone completion.
    /// @param _blueprintId The ID of the blueprint.
    /// @param _milestoneIndex The 0-indexed milestone being disputed.
    /// @param _reasonHash IPFS hash or URI detailing the reason for the dispute.
    function disputeMilestone(uint256 _blueprintId, uint256 _milestoneIndex, string memory _reasonHash) public {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.projectLead != address(0), "AF: Blueprint does not exist");
        require(blueprint.status == BlueprintStatus.Active, "AF: Blueprint not active");
        require(_milestoneIndex < blueprint.totalMilestones, "AF: Invalid milestone index");
        require(blueprint.milestoneApproved[_milestoneIndex], "AF: Milestone not yet approved, cannot dispute");
        require(bytes(_reasonHash).length > 0, "AF: Dispute reason cannot be empty");

        blueprint.status = BlueprintStatus.Disputed;
        // In a real system, this would trigger a governance vote or council review.
        // For simplicity, we just mark it as disputed.

        emit MilestoneDisputed(_blueprintId, _milestoneIndex, _msgSender(), _reasonHash);
    }

    // --- Artisan Reputation & Governance ---

    /// @notice Artisans can stake Essence (ETH) to boost their reputation score over time.
    /// @dev Staked Essence influences reputation and provides long-term commitment.
    /// @param _amount The amount of ETH to stake.
    function stakeEssenceForReputation(uint256 _amount) public payable {
        require(msg.value == _amount, "AF: Sent ETH must match _amount");
        require(_amount > 0, "AF: Stake amount must be greater than zero");

        artisans[_msgSender()].stakedEssence = artisans[_msgSender()].stakedEssence.add(_amount);
        // Reputation increase for staking (e.g., 10 reputation per ETH staked)
        artisans[_msgSender()].reputationScore = artisans[_msgSender()].reputationScore.add(_amount.div(10**17)); // 0.1 ETH = 1 reputation

        emit ReputationStaked(_msgSender(), _amount, artisans[_msgSender()].reputationScore);
    }

    /// @notice Allows an Artisan to delegate their voting power (reputation) to another Artisan.
    /// @param _delegatee The address to delegate reputation to.
    function delegateReputation(address _delegatee) public {
        require(_delegatee != address(0), "AF: Delegatee cannot be zero address");
        require(_delegatee != _msgSender(), "AF: Cannot delegate to self");

        artisans[_msgSender()].delegatee = _delegatee;
        emit ReputationDelegated(_msgSender(), _delegatee);
    }

    /// @notice Artisans use their reputation to vote on whether to approve a new Blueprint proposal.
    /// @param _blueprintId The ID of the blueprint proposal to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnBlueprintProposal(uint256 _blueprintId, bool _approve) public {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.projectLead != address(0), "AF: Blueprint does not exist");
        require(blueprint.status == BlueprintStatus.Proposed, "AF: Blueprint not in proposed status for voting");
        require(!blueprintVoters[_blueprintId][_msgSender()], "AF: Already voted on this blueprint");

        uint256 reputation = artisans[_msgSender()].reputationScore;
        address actualVoter = _msgSender();
        if (artisans[_msgSender()].delegatee != address(0)) {
            reputation = artisans[artisans[_msgSender()].delegatee].reputationScore; // Use delegatee's reputation
            actualVoter = artisans[_msgSender()].delegatee;
        }
        require(reputation > 0, "AF: Voter has no reputation");

        // For simplicity, we'll just require a minimum reputation to vote and record the vote.
        // A more complex system would have weighted voting thresholds and proposal states.
        
        // Mark as voted
        blueprintVoters[_blueprintId][actualVoter] = true;

        if (_approve) {
            // Example: accumulate 'approval' reputation score for the blueprint
            blueprint.aiEvaluationScore = blueprint.aiEvaluationScore.add(reputation.div(100)); // Simple scoring mechanism
        } else {
            // Example: accumulate 'rejection' reputation score
            blueprint.aiEvaluationScore = blueprint.aiEvaluationScore.sub(reputation.div(100)); // Negative if more rejections
        }

        // Auto-approve/reject if a certain reputation threshold is reached (simulated)
        if (blueprint.aiEvaluationScore >= 500) { // arbitrary positive threshold
            blueprint.status = BlueprintStatus.Active;
        } else if (blueprint.aiEvaluationScore <= -500) { // arbitrary negative threshold
            blueprint.status = BlueprintStatus.Canceled;
        }

        emit BlueprintVoted(_blueprintId, actualVoter, _approve, reputation);
    }

    /// @notice Initiates a proposal to add a new member to the governing Artisan Council.
    /// @param _newMember The address of the Artisan to propose as a council member.
    function proposeArtisanCouncilMember(address _newMember) public {
        require(_newMember != address(0), "AF: New member address cannot be zero");
        require(!artisanCouncil[_newMember], "AF: Artisan is already a council member");
        require(artisans[_msgSender()].reputationScore >= MIN_REPUTATION_FOR_COUNCIL_VOTE, "AF: Insufficient reputation to propose");

        uint256 proposalId = nextCouncilProposalId++;
        councilProposals[proposalId] = CouncilProposal({
            proposer: _msgSender(),
            targetAddress: _newMember,
            descriptionHash: "Propose new Artisan Council member", // Generic description
            votesFor: 0,
            votesAgainst: 0,
            status: CouncilProposalStatus.Active
        });

        emit CouncilProposalInitiated(proposalId, _msgSender(), _newMember);
    }

    /// @notice Council members (or high-reputation Artisans) vote on specific governance proposals.
    /// @param _proposalId The ID of the council proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnCouncilProposal(uint256 _proposalId, bool _approve) public {
        CouncilProposal storage proposal = councilProposals[_proposalId];
        require(proposal.proposer != address(0), "AF: Council proposal does not exist");
        require(proposal.status == CouncilProposalStatus.Active, "AF: Proposal is not active");
        require(artisanCouncil[_msgSender()], "AF: Only council members can vote on council proposals");
        require(!proposal.hasVoted[_msgSender()], "AF: Council member already voted");

        proposal.hasVoted[_msgSender()] = true;
        if (_approve) {
            proposal.votesFor = proposal.votesFor.add(1);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(1);
        }

        // Simple majority vote for now
        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 currentCouncilSize = 0;
        for (uint256 i = 0; i < 100; i++) { // Max 100 council members, simplify
            if (artisanCouncil[address(uint160(i))]) { // Placeholder for iterating members
                currentCouncilSize++;
            }
        }
        // In a real system, council members would be stored in an array or iterable mapping.
        // For this example, we'll assume the currentCouncilSize is known or estimated.
        currentCouncilSize = 3; // Placeholder for actual council size

        if (totalVotes == currentCouncilSize) { // All council members have voted
            if (proposal.votesFor > proposal.votesAgainst) {
                proposal.status = CouncilProposalStatus.Approved;
                if (proposal.targetAddress != address(0) && !artisanCouncil[proposal.targetAddress]) {
                    artisanCouncil[proposal.targetAddress] = true;
                    artisans[proposal.targetAddress].reputationScore = artisans[proposal.targetAddress].reputationScore.add(1000); // Boost reputation
                    emit ArtisanCouncilMemberAdded(proposal.targetAddress);
                }
            } else {
                proposal.status = CouncilProposalStatus.Rejected;
            }
        }

        emit CouncilVoted(_proposalId, _msgSender(), _approve);
    }

    /// @notice The Artisan Council can enact penalties, reducing an Artisan's reputation for severe misconduct.
    /// @param _artisan The address of the Artisan to penalize.
    /// @param _reputationLoss The amount of reputation to deduct.
    function penalizeArtisan(address _artisan, uint256 _reputationLoss) public onlyArtisanCouncil {
        require(_artisan != address(0), "AF: Artisan address cannot be zero");
        require(_reputationLoss > 0, "AF: Reputation loss must be positive");
        require(artisans[_artisan].reputationScore >= _reputationLoss, "AF: Artisan does not have enough reputation to lose");

        artisans[_artisan].reputationScore = artisans[_artisan].reputationScore.sub(_reputationLoss);
        emit ArtisanPenalized(_artisan, _reputationLoss, _msgSender());
    }

    // --- AI Oracle & Automated Task Integration (Simulated) ---

    /// @notice Requests an external AI oracle to provide an evaluation or feedback on a specific Blueprint.
    /// @param _blueprintId The ID of the blueprint to evaluate.
    /// @param _promptHash IPFS hash or URI for the AI prompt/query.
    function requestAIEvaluation(uint256 _blueprintId, string memory _promptHash) public {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.projectLead != address(0), "AF: Blueprint does not exist");
        require(bytes(_promptHash).length > 0, "AF: Prompt hash cannot be empty");
        require(!blueprint.aiEvaluationRequested, "AF: AI evaluation already requested for this blueprint");

        blueprint.aiEvaluationRequested = true;
        bytes32 requestId = keccak256(abi.encodePacked(_blueprintId, _msgSender(), block.timestamp, _promptHash));
        aiEvaluationRequests[requestId] = AIEvaluationRequest({
            blueprintId: _blueprintId,
            requester: _msgSender(),
            promptHash: _promptHash,
            requestId: requestId,
            status: AIRequestStatus.Pending,
            evaluationResultHash: "",
            confidenceScore: 0,
            timestamp: block.timestamp
        });

        emit AIEvaluationRequested(_blueprintId, _msgSender(), requestId, _promptHash);
    }

    /// @notice (Internal/Oracle-only) Receives and records the AI oracle's evaluation result for a requested Blueprint.
    /// @dev This function can only be called by the designated AI Oracle address.
    /// @param _blueprintId The ID of the blueprint that was evaluated.
    /// @param _requestId The ID of the original AI evaluation request.
    /// @param _evaluationResultHash IPFS hash or URI for the AI's detailed evaluation.
    /// @param _confidenceScore The AI's confidence in its evaluation (0-100).
    function fulfillAIEvaluation(
        uint256 _blueprintId,
        bytes32 _requestId,
        string memory _evaluationResultHash,
        uint256 _confidenceScore
    ) public onlyAIOrcle {
        AIEvaluationRequest storage request = aiEvaluationRequests[_requestId];
        require(request.blueprintId == _blueprintId, "AF: Mismatch blueprint ID");
        require(request.status == AIRequestStatus.Pending, "AF: Request not pending");
        require(_confidenceScore <= 100, "AF: Confidence score must be 0-100");

        request.status = AIRequestStatus.Fulfilled;
        request.evaluationResultHash = _evaluationResultHash;
        request.confidenceScore = _confidenceScore;

        // Update blueprint with AI evaluation score
        blueprints[_blueprintId].aiEvaluationScore = _confidenceScore;

        emit AIEvaluationFulfilled(_blueprintId, _requestId, _evaluationResultHash, _confidenceScore);
    }

    /// @notice A Blueprint lead can define an automated task, potentially to be picked up and executed by an AI agent or bot.
    /// @param _blueprintId The ID of the blueprint this task belongs to.
    /// @param _taskDescriptionHash IPFS hash or URI detailing the task.
    /// @param _essenceReward The ETH reward for completing this task.
    function initiateAutonomousTask(
        uint256 _blueprintId,
        string memory _taskDescriptionHash,
        uint256 _essenceReward
    ) public onlyProjectLead(_blueprintId) {
        Blueprint storage blueprint = blueprints[_blueprintId];
        require(blueprint.status == BlueprintStatus.Active, "AF: Blueprint not active");
        require(bytes(_taskDescriptionHash).length > 0, "AF: Task description cannot be empty");
        require(_essenceReward > 0, "AF: Reward must be greater than zero");
        
        // Check if enough funds are available in the blueprint for the reward
        // This is a simplified check, a real system would need dedicated escrow.
        require(address(this).balance >= _essenceReward, "AF: Insufficient contract balance for task reward");

        uint256 taskId = nextAutonomousTaskId++;
        autonomousTasks[taskId] = AutonomousTask({
            blueprintId: _blueprintId,
            initiator: _msgSender(),
            taskDescriptionHash: _taskDescriptionHash,
            essenceReward: _essenceReward,
            assignedTo: address(0), // No one assigned initially
            status: TaskStatus.Proposed
        });

        emit AutonomousTaskInitiated(_blueprintId, taskId, _msgSender(), _essenceReward);
    }

    // --- Advanced Access & Utility ---

    /// @notice Mints a special ERC-721 Subscription NFT, granting tiered and time-bound access.
    /// @param _recipient The address to mint the NFT to.
    /// @param _tier The subscription tier (e.g., 1 for Basic, 2 for Premium).
    /// @param _duration The duration of the subscription in seconds from now.
    function mintSubscriptionNFT(address _recipient, uint256 _tier, uint256 _duration) public payable {
        // Example: require a payment for minting
        require(msg.value > 0, "AF: Must pay for subscription"); 
        require(_recipient != address(0), "AF: Recipient cannot be zero address");
        require(_tier > 0, "AF: Tier must be greater than zero");
        require(_duration > 0, "AF: Duration must be greater than zero");

        uint256 tokenId = nextSubscriptionNFTId++;
        subscriptionNFTs[tokenId] = SubscriptionNFT({
            owner: _recipient,
            tier: _tier,
            expiryTimestamp: block.timestamp.add(_duration),
            tokenURI: string(abi.encodePacked("ipfs://subscription-tier-", Strings.toString(_tier))) // Dynamic URI based on tier
        });

        artisans[_recipient].subscriptionNFTId = tokenId; // Link subscription to artisan

        // ERC721 minting logic for subscription NFTs
        _subscriptionBalance[_recipient] = _subscriptionBalance[_recipient].add(1);
        _subscriptionOwner[tokenId] = _recipient;

        emit SubscriptionNFTMinted(tokenId, _recipient, _tier, block.timestamp.add(_duration));
        emit Transfer(address(0), _recipient, tokenId); // ERC721 Transfer event for mint
    }

    // --- Internal/Helper Functions (ERC721-like implementation for Artifacts and Subscriptions) ---

    function _transferArtifact(address _from, address _to, uint256 _tokenId) internal {
        _artifactBalance[_from] = _artifactBalance[_from].sub(1);
        _artifactBalance[_to] = _artifactBalance[_to].add(1);
        _artifactOwner[_tokenId] = _to;
        delete _artifactApprovals[_tokenId];
    }

    function _isApprovedOrOwnerArtifact(address _spender, uint256 _tokenId) internal view returns (bool) {
        require(_artifactOwner[_tokenId] != address(0), "AF: Owner query for nonexistent token");
        return (_spender == _artifactOwner[_tokenId] ||
                _spender == _artifactApprovals[_tokenId] ||
                _artifactOperatorApprovals[_artifactOwner[_tokenId]][_spender]);
    }

    // --- ERC721 Interface Implementations for Artifacts ---

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _artifactBalance[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _artifactOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || _artifactOperatorApprovals[owner][_msgSender()], "ERC721: approve caller is not owner nor approved for all");

        _artifactApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_artifactOwner[tokenId] != address(0), "ERC721: approved query for nonexistent token");
        return _artifactApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _artifactOperatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _artifactOperatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwnerArtifact(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transferArtifact(from, to, tokenId);
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwnerArtifact(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _transferArtifact(from, to, tokenId);
        
        // This is a basic implementation; a full ERC721 standard would check if `to` is a contract and calls `onERC721Received`.
        // For brevity, we're skipping the `onERC721Received` check, as this is a concept contract.
        // A production contract would use OpenZeppelin's ERC721 implementation directly or include this check.
        
        emit Transfer(from, to, tokenId);
    }

    // --- IERC721Metadata for Artifacts (only name and symbol implemented for brevity) ---

    function name() public view override returns (string memory) {
        return _artifactName;
    }

    function symbol() public view override returns (string memory) {
        return _artifactSymbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_artifactOwner[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return artifacts[tokenId].tokenURI;
    }

    // --- ERC721 Interface Implementations for SubscriptionNFTs (re-using ERC721 logic but with separate state) ---
    // Note: In a full production system, it's better to deploy separate ERC721 contracts for Artifacts and Subscriptions
    // and interact with them via interfaces, rather than having one monolithic contract manage multiple distinct ERC721s.
    // This consolidated approach is for demonstrating functionality within a single file.

    function subscriptionBalanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _subscriptionBalance[owner];
    }

    function subscriptionOwnerOf(uint256 tokenId) public view returns (address) {
        address owner = _subscriptionOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function subscriptionTokenURI(uint256 tokenId) public view returns (string memory) {
        require(_subscriptionOwner[tokenId] != address(0), "ERC721Metadata: URI query for nonexistent token");
        return subscriptionNFTs[tokenId].tokenURI;
    }

    // --- Owner-specific functions ---
    function setAIOrcleAddress(address _newOracleAddress) public onlyOwner {
        require(_newOracleAddress != address(0), "AF: New AI Oracle address cannot be zero");
        aiOracleAddress = _newOracleAddress;
    }

    // Fallback function to receive Ether
    receive() external payable {}
    fallback() external payable {}
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```