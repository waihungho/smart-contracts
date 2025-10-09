This smart contract, `IntellectualNexus`, introduces a decentralized, collaborative ecosystem for Intellectual Property (IP) co-creation and monetization. It aims to push beyond typical NFT marketplaces or simple royalty splits by incorporating dynamic contribution weighting, a reputation system, and a simulated interaction layer with off-chain AI services for enhanced content verification and quality assessment. The core idea is to empower creators to collaboratively build digital assets, with royalties automatically adjusting based on the evolving perceived impact of each contribution.

---

## **Contract: `IntellectualNexus`**

This contract facilitates a decentralized, collaborative ecosystem for Intellectual Property (IP) co-creation, dynamic royalty distribution, and community governance. It introduces concepts like impact-weighted contributions, reputation-based decision making, and simulated integration with off-chain AI for content verification, all encapsulated within ERC-721 Non-Fungible Tokens (NFTs) representing the finalized IP assets.

### **Outline and Function Summary:**

**I. Core IP Management & Lifecycle (ERC-721 IP Assets)**
1.  **`createIPAsset(string memory _title, string memory _descriptionHash, string memory _initialContentHash)`**: Initializes a new IP project. The caller becomes the initial IP owner and a core contributor. An IPFS hash is used for content references.
2.  **`submitContribution(uint256 _ipId, string memory _contributionHash, string memory _description, uint256 _proposedImpactScore)`**: Allows users to propose their creative additions or modifications to an ongoing IP project, suggesting their perceived value (`_proposedImpactScore`).
3.  **`approveContribution(uint256 _ipId, uint256 _contributionId, uint256 _actualImpactScore)`**: Core contributors or IP owners review and formally accept a submitted contribution, assigning a definitive impact score that directly influences future royalty distribution for that IP.
4.  **`rejectContribution(uint256 _ipId, uint256 _contributionId, string memory _reason)`**: Formally declines a submitted contribution, providing a reason for transparency within the project.
5.  **`finalizeIPAsset(uint256 _ipId)`**: Seals the IP project, preventing further contributions. This function also mints an ERC-721 NFT representing the completed IP, assigning its canonical content URI.
6.  **`updateIPDescription(uint256 _ipId, string memory _newDescriptionHash)`**: Allows the IP owner (or governance for highly decentralized IPs) to update the high-level conceptual description or metadata hash of a finalized IP.
7.  **`transferIPOwnershipNFT(uint256 _ipId, address _to)`**: Facilitates the transfer of the ERC-721 IP asset. This action also transfers the associated rights, such as control over future updates (if any) and potential governance weight related to that specific IP.

**II. Dynamic Royalty & Reward System**
8.  **`updateContributionImpactScore(uint256 _ipId, uint256 _contributionId, uint256 _newImpactScore)`**: **Advanced Concept:** Allows IP owners or designated governance bodies to dynamically adjust the impact score of an *already approved* contribution. This is crucial for reflecting evolving relevance, market impact, or refined assessments (e.g., post-AI analysis) over time.
9.  **`distributeRoyalties(uint256 _ipId)`**: Triggers the calculation and distribution of accumulated funds (from sales, donations, etc.) to all contributors of a specific IP, weighted by their *current* dynamic impact scores. Includes platform fees.
10. **`claimRoyalties(uint256 _ipId)`**: Allows individual contributors to withdraw their accumulated and calculated royalty share for a particular IP from the contract's balance.
11. **`getContributorCurrentRoyaltyShare(uint256 _ipId, address _contributor)`**: *View Function:* Calculates and returns the current percentage share of royalties a specific contributor is entitled to for an IP, based on the aggregate impact scores of all approved contributions.

**III. Reputation, Governance & Dispute Resolution**
12. **`updateUserReputation(address _user, int256 _reputationDelta)`**: **Advanced Concept:** A governance-controlled function to modify a user's global reputation score. Positive deltas reward good behavior, negative deltas penalize malicious actions. Reputation can influence voting power, proposal limits, and access.
13. **`proposeRuleChange(string memory _proposalHash, uint256 _quorumPercentage, uint256 _votingPeriod)`**: Enables users with sufficient reputation to formally propose platform-wide rule changes or parameter adjustments (e.g., fee structure, dispute thresholds).
14. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Allows eligible users to cast their vote on active governance proposals, with voting weight potentially augmented by their reputation score.
15. **`executeProposal(uint256 _proposalId)`**: Activates a passed governance proposal, applying its intended changes to the contract's state or parameters.
16. **`initiateDispute(uint256 _ipId, uint256 _contributionId, string memory _reasonHash)`**: Provides a formal mechanism for any user to raise concerns (e.g., plagiarism, misattribution, unfair impact score) regarding an IP or a specific contribution.
17. **`resolveDispute(uint256 _disputeId, address _arbitratorDecisionWinner, int256 _reputationPenaltyToLoser)`**: **Advanced Concept:** A governance- or arbitrator-controlled function to settle disputes, potentially resulting in adjustments to impact scores, revocation of contributions, or imposition of reputation penalties on involved parties.

**IV. AI-Assisted Features (Simulated Oracle Integration)**
18. **`requestAICheck(uint256 _ipId, uint256 _contributionId, string memory _contentHash, AICheckType _checkType)`**: **Trendy Concept:** Initiates an off-chain request to a designated AI oracle service for analysis (e.g., plagiarism detection, quality assessment, stylistic coherence) on a specific contribution's content. Stores the request's intent on-chain.
19. **`receiveAIReport(uint256 _ipId, uint256 _contributionId, AICheckType _checkType, string memory _reportHash, int256 _impactScoreDelta)`**: **Advanced Concept:** A callback function, callable only by the trusted AI oracle. It relays analysis results (e.g., report hash for off-chain access) and can *automatically* adjust the contribution's impact score or trigger further on-chain governance actions based on the AI's findings.
20. **`setTrustedAIAssessor(address _newAssessor)`**: A governance function to update the trusted address of the AI oracle service that is authorized to call `receiveAIReport`.

**V. Financial & Platform Management**
21. **`depositFundsForIP(uint256 _ipId) payable`**: Allows any user to directly contribute Ether (or other native tokens) to a specific IP, thereby increasing its total royalty pool available for distribution.
22. **`withdrawUnclaimedPlatformFees(address _to)`**: Allows the platform owner to withdraw accumulated service fees (a small percentage from royalties or other revenue streams) to a specified address.
23. **`setPlatformFeeRate(uint256 _newRate)`**: A governance function that allows adjusting the percentage of royalties or other revenue taken as a platform fee, providing flexibility for future economic models.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Custom Errors ---
error IntellectualNexus__NotIPOwner();
error IntellectualNexus__IPNotFound();
error IntellectualNexus__IPNotFinalized();
error IntellectualNexus__IPAlreadyFinalized();
error IntellectualNexus__ContributionNotFound();
error IntellectualNexus__ContributionAlreadyApproved();
error IntellectualNexus__ContributionNotApproved();
error IntellectualNexus__InvalidImpactScore();
error IntellectualNexus__NoRoyaltiesDue();
error IntellectualNexus__InsufficientReputation();
error IntellectualNexus__ProposalNotFound();
error IntellectualNexus__ProposalVotingPeriodActive();
error IntellectualNexus__ProposalVotingPeriodExpired();
error IntellectualNexus__AlreadyVoted();
error IntellectualNexus__QuorumNotReached();
error IntellectualNexus__ProposalNotExecutable();
error IntellectualNexus__UnauthorizedAIAssessor();
error IntellectualNexus__DisputeNotFound();
error IntellectualNexus__InvalidFeeRate();
error IntellectualNexus__FundsAlreadyClaimed();
error IntellectualNexus__NoFundsToWithdraw();
error IntellectualNexus__ContributionAlreadyRejected();
error IntellectualNexus__CannotApproveRejectedContribution();


// --- Events ---
event IPAssetCreated(uint256 indexed ipId, address indexed creator, string title, string initialContentHash);
event ContributionSubmitted(uint256 indexed ipId, uint256 indexed contributionId, address indexed contributor, uint256 proposedImpactScore, string contributionHash);
event ContributionApproved(uint256 indexed ipId, uint256 indexed contributionId, address indexed approver, uint256 actualImpactScore);
event ContributionRejected(uint256 indexed ipId, uint256 indexed contributionId, address indexed approver, string reason);
event IPAssetFinalized(uint256 indexed ipId, string finalContentURI);
event IPDescriptionUpdated(uint256 indexed ipId, string newDescriptionHash);
event IPOwnershipTransferred(uint256 indexed ipId, address indexed from, address indexed to);

event ContributionImpactScoreUpdated(uint256 indexed ipId, uint256 indexed contributionId, uint256 oldImpactScore, uint256 newImpactScore);
event RoyaltiesDistributed(uint256 indexed ipId, uint256 totalDistributedAmount);
event RoyaltiesClaimed(uint256 indexed ipId, address indexed contributor, uint256 amount);

event UserReputationUpdated(address indexed user, int256 reputationDelta, uint256 newReputationScore);
event RuleChangeProposed(uint256 indexed proposalId, address indexed proposer, string proposalHash, uint256 quorumPercentage, uint256 votingPeriod);
event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
event ProposalExecuted(uint256 indexed proposalId);
event DisputeInitiated(uint256 indexed disputeId, uint256 indexed ipId, uint256 indexed contributionId, address indexed initiator, string reasonHash);
event DisputeResolved(uint256 indexed disputeId, address indexed winner, int256 reputationPenaltyToLoser);

event AICheckRequested(uint256 indexed ipId, uint256 indexed contributionId, AICheckType checkType, string contentHash);
event AIReportReceived(uint256 indexed ipId, uint256 indexed contributionId, AICheckType checkType, string reportHash, int256 impactScoreDelta);
event TrustedAIAssessorSet(address indexed oldAssessor, address indexed newAssessor);

event FundsDepositedForIP(uint256 indexed ipId, address indexed depositor, uint256 amount);
event PlatformFeesWithdrawn(address indexed recipient, uint256 amount);
event PlatformFeeRateSet(uint256 oldRate, uint256 newRate);


contract IntellectualNexus is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Enums ---
    enum ContributionStatus { Pending, Approved, Rejected }
    enum AICheckType { Plagiarism, Quality, Semantic }
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // --- Structs ---
    struct IPAsset {
        uint256 id;
        string title;
        string descriptionHash; // IPFS hash for general description
        string initialContentHash; // IPFS hash for initial work/concept
        address creator;
        bool isFinalized;
        string finalContentURI; // URI for the final NFT metadata and content
        mapping(uint256 => Contribution) contributions;
        Counters.Counter contributionCounter;
        uint256 totalApprovedImpactScore; // Sum of all approved contribution impact scores for this IP
        uint256 totalRoyaltiesAccrued;
        mapping(address => uint256) royaltiesOwed; // Unclaimed royalties per contributor
        mapping(address => bool) hasClaimedRoyalties; // To prevent claiming the same batch twice (simplified)
    }

    struct Contribution {
        uint256 id;
        address contributor;
        string contributionHash; // IPFS hash for the contribution content
        string description;
        uint256 impactScore; // Weighted score for royalty distribution, can be dynamic
        ContributionStatus status;
        uint256 timestamp;
    }

    struct Proposal {
        uint256 id;
        string proposalHash; // IPFS hash for proposal details
        address proposer;
        uint256 startTime;
        uint256 votingPeriod; // Duration in seconds
        uint256 quorumPercentage; // e.g., 51 for 51%
        uint256 yeas;
        uint256 nays;
        mapping(address => bool) hasVoted;
        ProposalState state;
        bytes callData; // For executable proposals
        address target; // For executable proposals
    }

    struct Dispute {
        uint256 id;
        uint256 ipId;
        uint256 contributionId; // 0 if dispute is about IP itself
        address initiator;
        string reasonHash; // IPFS hash for detailed reason
        bool resolved;
    }

    // --- State Variables ---
    Counters.Counter private _ipIds;
    Counters.Counter private _proposalIds;
    Counters.Counter private _disputeIds;

    mapping(uint256 => IPAsset) public ipAssets;
    
    // Global reputation score for users
    mapping(address => uint256) public userReputation;

    // Platform fees and related
    uint256 public platformFeeRate = 500; // 5.00% (500 basis points)
    uint256 public totalPlatformFeesAccrued;

    address public trustedAIAssessor; // Address of the trusted off-chain AI oracle

    // Governance proposals
    mapping(uint256 => Proposal) public proposals;

    // Disputes
    mapping(uint256 => Dispute) public disputes;

    // Minimum reputation required to propose a rule change
    uint256 public minReputationForProposal = 100;

    constructor(address initialAIAssessor) ERC721("IntellectualNexusIP", "INIP") Ownable(msg.sender) {
        trustedAIAssessor = initialAIAssessor;
    }

    // --- Modifiers ---
    modifier onlyIPOwner(uint256 _ipId) {
        if (ipAssets[_ipId].creator != msg.sender && owner() != msg.sender) { // Allow platform owner to also act
            // In a more complex DAO, this would involve governance vote
            revert IntellectualNexus__NotIPOwner();
        }
        _;
    }

    modifier onlyTrustedAIAssessor() {
        if (msg.sender != trustedAIAssessor) {
            revert IntellectualNexus__UnauthorizedAIAssessor();
        }
        _;
    }

    // --- I. Core IP Management & Lifecycle (ERC-721 IP Assets) ---

    /// @notice Initiates a new IP project, minting the initial IP token to the creator.
    /// @param _title A concise title for the IP.
    /// @param _descriptionHash IPFS hash linking to a detailed description of the IP concept.
    /// @param _initialContentHash IPFS hash for any initial drafts, sketches, or foundational content.
    function createIPAsset(
        string memory _title,
        string memory _descriptionHash,
        string memory _initialContentHash
    ) public returns (uint256) {
        _ipIds.increment();
        uint256 newIpId = _ipIds.current();

        ipAssets[newIpId].id = newIpId;
        ipAssets[newIpId].title = _title;
        ipAssets[newIpId].descriptionHash = _descriptionHash;
        ipAssets[newIpId].initialContentHash = _initialContentHash;
        ipAssets[newIpId].creator = msg.sender;
        ipAssets[newIpId].isFinalized = false;
        ipAssets[newIpId].totalApprovedImpactScore = 0;
        ipAssets[newIpId].totalRoyaltiesAccrued = 0;

        // Mint the ERC-721 token representing the IP
        _safeMint(msg.sender, newIpId);

        emit IPAssetCreated(newIpId, msg.sender, _title, _initialContentHash);
        return newIpId;
    }

    /// @notice Allows users to submit their creative additions or modifications to an ongoing IP project.
    /// @param _ipId The ID of the IP asset to contribute to.
    /// @param _contributionHash IPFS hash linking to the actual content of the contribution.
    /// @param _description A brief description of the contribution.
    /// @param _proposedImpactScore The contributor's proposed impact score for their work. This is subject to approval.
    function submitContribution(
        uint256 _ipId,
        string memory _contributionHash,
        string memory _description,
        uint256 _proposedImpactScore
    ) public {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (ip.isFinalized) revert IntellectualNexus__IPAlreadyFinalized();
        if (_proposedImpactScore == 0) revert IntellectualNexus__InvalidImpactScore();

        ip.contributionCounter.increment();
        uint256 newContributionId = ip.contributionCounter.current();

        Contribution storage newContribution = ip.contributions[newContributionId];
        newContribution.id = newContributionId;
        newContribution.contributor = msg.sender;
        newContribution.contributionHash = _contributionHash;
        newContribution.description = _description;
        newContribution.impactScore = _proposedImpactScore; // Initial proposed score
        newContribution.status = ContributionStatus.Pending;
        newContribution.timestamp = block.timestamp;

        emit ContributionSubmitted(_ipId, newContributionId, msg.sender, _proposedImpactScore, _contributionHash);
    }

    /// @notice Core contributors or IP owners validate and accept a submitted contribution.
    /// @param _ipId The ID of the IP asset.
    /// @param _contributionId The ID of the contribution to approve.
    /// @param _actualImpactScore The definitive impact score assigned by the approver.
    function approveContribution(
        uint256 _ipId,
        uint256 _contributionId,
        uint256 _actualImpactScore
    ) public onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (ip.isFinalized) revert IntellectualNexus__IPAlreadyFinalized();
        if (_actualImpactScore == 0) revert IntellectualNexus__InvalidImpactScore();

        Contribution storage contribution = ip.contributions[_contributionId];
        if (contribution.id == 0 || contribution.contributor == address(0)) revert IntellectualNexus__ContributionNotFound();
        if (contribution.status == ContributionStatus.Approved) revert IntellectualNexus__ContributionAlreadyApproved();
        if (contribution.status == ContributionStatus.Rejected) revert IntellectualNexus__CannotApproveRejectedContribution();

        contribution.status = ContributionStatus.Approved;
        contribution.impactScore = _actualImpactScore;
        ip.totalApprovedImpactScore += _actualImpactScore;

        emit ContributionApproved(_ipId, _contributionId, msg.sender, _actualImpactScore);
    }

    /// @notice Formally declines a contribution, providing a reason for transparency.
    /// @param _ipId The ID of the IP asset.
    /// @param _contributionId The ID of the contribution to reject.
    /// @param _reason IPFS hash or string for the reason of rejection.
    function rejectContribution(
        uint256 _ipId,
        uint256 _contributionId,
        string memory _reason
    ) public onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (ip.isFinalized) revert IntellectualNexus__IPAlreadyFinalized();

        Contribution storage contribution = ip.contributions[_contributionId];
        if (contribution.id == 0 || contribution.contributor == address(0)) revert IntellectualNexus__ContributionNotFound();
        if (contribution.status == ContributionStatus.Rejected) revert IntellectualNexus__ContributionAlreadyRejected();
        if (contribution.status == ContributionStatus.Approved) {
            // If already approved, removing it will reduce the total impact score
            ip.totalApprovedImpactScore -= contribution.impactScore;
        }
        
        contribution.status = ContributionStatus.Rejected;
        emit ContributionRejected(_ipId, _contributionId, msg.sender, _reason);
    }

    /// @notice Seals the IP project, preventing further contributions and minting an ERC-721 NFT.
    /// @param _ipId The ID of the IP asset to finalize.
    function finalizeIPAsset(uint256 _ipId) public onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (ip.isFinalized) revert IntellectualNexus__IPAlreadyFinalized();

        // For simplicity, `finalContentURI` points to the last approved content hash for example,
        // or a curated URI assembling all approved contributions.
        // In a real scenario, an off-chain process would compile content and generate this URI.
        string memory finalURI = string(abi.encodePacked("ipfs://", ip.initialContentHash, "/final")); // Placeholder
        
        ip.isFinalized = true;
        ip.finalContentURI = finalURI;

        _setTokenURI(_ipId, finalURI); // Sets the URI for the NFT

        emit IPAssetFinalized(_ipId, finalURI);
    }

    /// @notice Allows the IP owner or governance to update the conceptual description of a finalized IP.
    /// @param _ipId The ID of the IP asset.
    /// @param _newDescriptionHash IPFS hash for the updated description.
    function updateIPDescription(uint256 _ipId, string memory _newDescriptionHash) public onlyIPOwner(_ipId) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (!ip.isFinalized) revert IntellectualNexus__IPNotFinalized();

        ip.descriptionHash = _newDescriptionHash;
        emit IPDescriptionUpdated(_ipId, _newDescriptionHash);
    }

    /// @notice Facilitates the transfer of the ERC-721 IP asset.
    /// @param _ipId The ID of the IP NFT to transfer.
    /// @param _to The recipient address.
    function transferIPOwnershipNFT(uint256 _ipId, address _to) public {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (!ip.isFinalized) revert IntellectualNexus__IPNotFinalized(); // Only finalized IPs can be fully transferred

        // Uses ERC721's internal transfer logic, which includes ownership checks
        _transfer(msg.sender, _to, _ipId);
        ip.creator = _to; // Update the creator role within the IPAsset struct as well
        emit IPOwnershipTransferred(_ipId, msg.sender, _to);
    }

    // --- II. Dynamic Royalty & Reward System ---

    /// @notice Dynamically adjusts the impact score of an existing, approved contribution.
    /// @param _ipId The ID of the IP asset.
    /// @param _contributionId The ID of the contribution to update.
    /// @param _newImpactScore The new impact score to assign.
    function updateContributionImpactScore(
        uint256 _ipId,
        uint256 _contributionId,
        uint256 _newImpactScore
    ) public onlyIPOwner(_ipId) { // Can be extended to governance/AI oracle
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (ip.isFinalized) revert IntellectualNexus__IPAlreadyFinalized(); // Or allow limited updates post-finalization
        if (_newImpactScore == 0) revert IntellectualNexus__InvalidImpactScore();

        Contribution storage contribution = ip.contributions[_contributionId];
        if (contribution.id == 0 || contribution.contributor == address(0)) revert IntellectualNexus__ContributionNotFound();
        if (contribution.status != ContributionStatus.Approved) revert IntellectualNexus__ContributionNotApproved();

        uint256 oldImpactScore = contribution.impactScore;
        contribution.impactScore = _newImpactScore;

        // Update the total impact score for royalty calculations
        ip.totalApprovedImpactScore = ip.totalApprovedImpactScore - oldImpactScore + _newImpactScore;

        emit ContributionImpactScoreUpdated(_ipId, _contributionId, oldImpactScore, _newImpactScore);
    }

    /// @notice Triggers the calculation and distribution of accumulated funds to all contributors of an IP.
    /// @param _ipId The ID of the IP asset.
    function distributeRoyalties(uint256 _ipId) public nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (ip.totalRoyaltiesAccrued == 0) revert IntellectualNexus__NoRoyaltiesDue();
        if (ip.totalApprovedImpactScore == 0) revert IntellectualNexus__NoRoyaltiesDue(); // No contributors with impact

        uint256 amountToDistribute = ip.totalRoyaltiesAccrued;
        uint256 platformFee = (amountToDistribute * platformFeeRate) / 10000; // Basis points
        
        totalPlatformFeesAccrued += platformFee;
        uint256 netAmountForContributors = amountToDistribute - platformFee;

        // Reset total royalties accrued for this IP
        ip.totalRoyaltiesAccrued = 0;

        // Iterate through all contributions to calculate shares (can be gas-heavy for many contributions)
        // A more gas-efficient approach might involve storing contributor arrays or snapshotting.
        for (uint256 i = 1; i <= ip.contributionCounter.current(); i++) {
            Contribution storage contribution = ip.contributions[i];
            if (contribution.status == ContributionStatus.Approved) {
                uint256 share = (netAmountForContributors * contribution.impactScore) / ip.totalApprovedImpactScore;
                ip.royaltiesOwed[contribution.contributor] += share;
            }
        }
        emit RoyaltiesDistributed(_ipId, netAmountForContributors);
    }

    /// @notice Allows individual contributors to withdraw their accumulated royalty share for a specific IP.
    /// @param _ipId The ID of the IP asset.
    function claimRoyalties(uint256 _ipId) public nonReentrant {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();

        uint256 amount = ip.royaltiesOwed[msg.sender];
        if (amount == 0) revert IntellectualNexus__NoRoyaltiesDue();

        ip.royaltiesOwed[msg.sender] = 0; // Reset owed amount
        
        // Mark that this batch of distributed royalties has been claimed.
        // For a true multiple distribution model, a more sophisticated tracking is needed.
        // For now, this prevents claiming the same `royaltiesOwed` amount again.
        ip.hasClaimedRoyalties[msg.sender] = true; 

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            // Revert on failed transfer to ensure funds are safe and can be claimed later
            ip.royaltiesOwed[msg.sender] = amount; // Restore owed amount
            revert IntellectualNexus__NoRoyaltiesDue(); // Or a specific transfer error
        }

        emit RoyaltiesClaimed(_ipId, msg.sender, amount);
    }

    /// @notice Provides the current calculated percentage of royalties a specific contributor is entitled to for an IP.
    /// @param _ipId The ID of the IP asset.
    /// @param _contributor The address of the contributor.
    /// @return The percentage share (multiplied by 10,000 for basis points).
    function getContributorCurrentRoyaltyShare(
        uint256 _ipId,
        address _contributor
    ) public view returns (uint256) {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) return 0; // IP not found
        if (ip.totalApprovedImpactScore == 0) return 0; // No approved contributions

        uint256 contributorImpact = 0;
        for (uint256 i = 1; i <= ip.contributionCounter.current(); i++) {
            Contribution storage contribution = ip.contributions[i];
            if (contribution.status == ContributionStatus.Approved && contribution.contributor == _contributor) {
                contributorImpact += contribution.impactScore;
            }
        }

        if (contributorImpact == 0) return 0; // Contributor has no approved impact

        return (contributorImpact * 10000) / ip.totalApprovedImpactScore; // Return in basis points
    }

    // --- III. Reputation, Governance & Dispute Resolution ---

    /// @notice Modifies a user's global reputation score. Controlled by governance.
    /// @param _user The address of the user whose reputation is being updated.
    /// @param _reputationDelta The change in reputation (positive for increase, negative for decrease).
    function updateUserReputation(address _user, int256 _reputationDelta) public onlyOwner {
        // More advanced: Could be triggered by governance vote or specific roles.
        uint256 currentReputation = userReputation[_user];
        if (_reputationDelta > 0) {
            userReputation[_user] = currentReputation + uint256(_reputationDelta);
        } else if (_reputationDelta < 0) {
            uint256 absDelta = uint256(-_reputationDelta);
            userReputation[_user] = currentReputation > absDelta ? currentReputation - absDelta : 0;
        }
        emit UserReputationUpdated(_user, _reputationDelta, userReputation[_user]);
    }

    /// @notice Enables users with sufficient reputation to propose platform-wide rule changes.
    /// @param _proposalHash IPFS hash linking to a detailed description of the proposal.
    /// @param _quorumPercentage The percentage of total reputation required for a proposal to pass (e.g., 51 for 51%).
    /// @param _votingPeriod Duration in seconds for the voting period.
    function proposeRuleChange(
        string memory _proposalHash,
        uint256 _quorumPercentage,
        uint256 _votingPeriod
    ) public {
        if (userReputation[msg.sender] < minReputationForProposal) revert IntellectualNexus__InsufficientReputation();

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposalHash = _proposalHash;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.timestamp;
        newProposal.votingPeriod = _votingPeriod;
        newProposal.quorumPercentage = _quorumPercentage;
        newProposal.yeas = 0;
        newProposal.nays = 0;
        newProposal.state = ProposalState.Active;
        // executable data can be set here if the proposal involves contract calls

        emit RuleChangeProposed(newProposalId, msg.sender, _proposalHash, _quorumPercentage, _votingPeriod);
    }

    /// @notice Allows eligible users to cast their vote on active governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'yea' vote, false for 'nay' vote.
    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Active) revert IntellectualNexus__ProposalNotFound();
        if (block.timestamp >= proposal.startTime + proposal.votingPeriod) revert IntellectualNexus__ProposalVotingPeriodExpired();
        if (proposal.hasVoted[msg.sender]) revert IntellectualNexus__AlreadyVoted();
        
        uint256 votingPower = userReputation[msg.sender]; // Voting power is based on reputation
        if (votingPower == 0) revert IntellectualNexus__InsufficientReputation(); // Must have some reputation to vote

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yeas += votingPower;
        } else {
            proposal.nays += votingPower;
        }

        emit VotedOnProposal(_proposalId, msg.sender, _support, votingPower);
    }

    /// @notice Activates a passed governance proposal, applying its intended changes.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0 || proposal.state != ProposalState.Active) revert IntellectualNexus__ProposalNotFound();
        if (block.timestamp < proposal.startTime + proposal.votingPeriod) revert IntellectualNexus__ProposalVotingPeriodActive();

        uint256 totalReputation = 0; // This needs to be calculated dynamically or snapshotted
        // For simplicity, we'll assume a fixed total, or aggregate from active users.
        // A more robust DAO would have a `getTotalReputation()` function.
        // For now, let's use a placeholder.
        totalReputation = 100000; // Example: A hypothetical total active reputation

        if ((proposal.yeas * 100) / totalReputation < proposal.quorumPercentage) {
            proposal.state = ProposalState.Failed;
            revert IntellectualNexus__QuorumNotReached();
        }

        if (proposal.yeas <= proposal.nays) {
            proposal.state = ProposalState.Failed;
            revert IntellectualNexus__ProposalNotExecutable();
        }

        // --- Execute the proposal's action (example: update fee rate) ---
        // This part needs to be dynamic based on the proposal's content.
        // For a general DAO, `callData` and `target` would be used.
        // Example: if proposal was to change platformFeeRate:
        // (bool success, ) = proposal.target.call(proposal.callData);
        // require(success, "Proposal execution failed");
        
        // Placeholder for a passed proposal:
        // Imagine proposal.proposalHash contained "change_fee_rate:100" (1%)
        // The execution logic would parse this and call setPlatformFeeRate(100)
        
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
    }

    /// @notice A formal mechanism for users to raise concerns regarding an IP or specific contribution.
    /// @param _ipId The ID of the IP asset.
    /// @param _contributionId The ID of the contribution (0 if dispute is about the entire IP).
    /// @param _reasonHash IPFS hash linking to the detailed reason for the dispute.
    function initiateDispute(
        uint256 _ipId,
        uint256 _contributionId,
        string memory _reasonHash
    ) public {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (_contributionId != 0 && (ip.contributions[_contributionId].id == 0 || ip.contributions[_contributionId].contributor == address(0))) {
            revert IntellectualNexus__ContributionNotFound();
        }

        _disputeIds.increment();
        uint256 newDisputeId = _disputeIds.current();

        disputes[newDisputeId].id = newDisputeId;
        disputes[newDisputeId].ipId = _ipId;
        disputes[newDisputeId].contributionId = _contributionId;
        disputes[newDisputeId].initiator = msg.sender;
        disputes[newDisputeId].reasonHash = _reasonHash;
        disputes[newDisputeId].resolved = false;

        emit DisputeInitiated(newDisputeId, _ipId, _contributionId, msg.sender, _reasonHash);
    }

    /// @notice A governance-controlled function to settle disputes, potentially adjusting impact scores or revoking contributions.
    /// @param _disputeId The ID of the dispute to resolve.
    /// @param _arbitratorDecisionWinner The address identified as the "winner" or party whose claim is upheld.
    /// @param _reputationPenaltyToLoser Optional: A reputation penalty to apply to the losing party (negative delta).
    function resolveDispute(
        uint256 _disputeId,
        address _arbitratorDecisionWinner,
        int256 _reputationPenaltyToLoser
    ) public onlyOwner { // This could be a more complex DAO decision or a specific arbitration role.
        Dispute storage dispute = disputes[_disputeId];
        if (dispute.id == 0) revert IntellectualNexus__DisputeNotFound();
        if (dispute.resolved) revert IntellectualNexus__DisputeNotFound(); // Already resolved

        dispute.resolved = true;

        // Apply reputation penalty if specified
        if (_reputationPenaltyToLoser < 0) {
            updateUserReputation(_arbitratorDecisionWinner == dispute.initiator ? msg.sender : dispute.initiator, _reputationPenaltyToLoser);
        }

        // Example: If a plagiarism dispute is resolved against a contributor, their impact score might be set to 0, or contribution rejected.
        if (dispute.contributionId != 0 && _arbitratorDecisionWinner != ipAssets[dispute.ipId].contributions[dispute.contributionId].contributor) {
            // If the original contributor is not the winner, their contribution might be devalued
            updateContributionImpactScore(dispute.ipId, dispute.contributionId, 0); // Remove impact
            // Alternatively, rejectContribution(dispute.ipId, dispute.contributionId, "Plagiarism confirmed");
        }
        
        emit DisputeResolved(_disputeId, _arbitratorDecisionWinner, _reputationPenaltyToLoser);
    }

    // --- IV. AI-Assisted Features (Simulated Oracle Integration) ---

    /// @notice Initiates an off-chain request to a designated AI oracle service for analysis on a contribution.
    /// @param _ipId The ID of the IP asset.
    /// @param _contributionId The ID of the contribution to check.
    /// @param _contentHash IPFS hash linking to the content to be analyzed.
    /// @param _checkType The type of AI check requested (Plagiarism, Quality, Semantic).
    function requestAICheck(
        uint256 _ipId,
        uint256 _contributionId,
        string memory _contentHash,
        AICheckType _checkType
    ) public {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (ip.contributions[_contributionId].id == 0 || ip.contributions[_contributionId].contributor == address(0)) {
            revert IntellectualNexus__ContributionNotFound();
        }

        // In a real dApp, this would typically involve an oracle network or a specific off-chain service
        // that monitors these events and performs the AI analysis.
        emit AICheckRequested(_ipId, _contributionId, _checkType, _contentHash);
    }

    /// @notice A callback function, callable only by the trusted AI oracle, providing analysis results.
    /// @param _ipId The ID of the IP asset.
    /// @param _contributionId The ID of the contribution analyzed.
    /// @param _checkType The type of AI check performed.
    /// @param _reportHash IPFS hash linking to the detailed AI report.
    /// @param _impactScoreDelta The change to apply to the contribution's impact score based on AI findings.
    function receiveAIReport(
        uint256 _ipId,
        uint256 _contributionId,
        AICheckType _checkType,
        string memory _reportHash,
        int256 _impactScoreDelta
    ) public onlyTrustedAIAssessor {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        
        Contribution storage contribution = ip.contributions[_contributionId];
        if (contribution.id == 0 || contribution.contributor == address(0)) revert IntellectualNexus__ContributionNotFound();
        if (contribution.status != ContributionStatus.Approved) revert IntellectualNexus__ContributionNotApproved();

        // Apply the impact score delta
        uint256 oldImpactScore = contribution.impactScore;
        uint256 newImpactScore;
        if (_impactScoreDelta > 0) {
            newImpactScore = oldImpactScore + uint256(_impactScoreDelta);
        } else {
            uint256 absDelta = uint256(-_impactScoreDelta);
            newImpactScore = oldImpactScore > absDelta ? oldImpactScore - absDelta : 0;
        }

        updateContributionImpactScore(_ipId, _contributionId, newImpactScore);
        
        // Further actions could be triggered based on checkType or severity (e.g., if plagiarism detected)
        // For example, trigger a dispute if plagiarism score is too high.

        emit AIReportReceived(_ipId, _contributionId, _checkType, _reportHash, _impactScoreDelta);
    }

    /// @notice Governance function to update the trusted address of the AI oracle service.
    /// @param _newAssessor The new address for the trusted AI assessor.
    function setTrustedAIAssessor(address _newAssessor) public onlyOwner {
        address oldAssessor = trustedAIAssessor;
        trustedAIAssessor = _newAssessor;
        emit TrustedAIAssessorSet(oldAssessor, _newAssessor);
    }

    // --- V. Financial & Platform Management ---

    /// @notice Allows any user to directly contribute funds to a specific IP.
    /// @param _ipId The ID of the IP asset to fund.
    function depositFundsForIP(uint256 _ipId) public payable {
        IPAsset storage ip = ipAssets[_ipId];
        if (ip.id == 0) revert IntellectualNexus__IPNotFound();
        if (msg.value == 0) revert IntellectualNexus__NoFundsToWithdraw(); // Or specific error

        ip.totalRoyaltiesAccrued += msg.value;
        emit FundsDepositedForIP(_ipId, msg.sender, msg.value);
    }

    /// @notice Allows the platform owner to withdraw accumulated service fees.
    /// @param _to The recipient address for the withdrawn fees.
    function withdrawUnclaimedPlatformFees(address _to) public onlyOwner nonReentrant {
        if (totalPlatformFeesAccrued == 0) revert IntellectualNexus__NoFundsToWithdraw();
        
        uint256 amount = totalPlatformFeesAccrued;
        totalPlatformFeesAccrued = 0;

        (bool success, ) = _to.call{value: amount}("");
        if (!success) {
            totalPlatformFeesAccrued = amount; // Restore if transfer fails
            revert IntellectualNexus__NoFundsToWithdraw(); // Or specific transfer error
        }
        emit PlatformFeesWithdrawn(_to, amount);
    }

    /// @notice A governance function that allows adjusting the percentage of royalties taken as a platform fee.
    /// @param _newRate The new platform fee rate in basis points (e.g., 100 for 1%). Max 10000 (100%).
    function setPlatformFeeRate(uint256 _newRate) public onlyOwner {
        if (_newRate > 10000) revert IntellectualNexus__InvalidFeeRate(); // Max 100%
        uint256 oldRate = platformFeeRate;
        platformFeeRate = _newRate;
        emit PlatformFeeRateSet(oldRate, _newRate);
    }

    // --- Internal/View Helpers for ERC721 ---
    function _baseURI() internal view override returns (string memory) {
        return "https://intellectualnexus.io/ip/"; // Base URI for IP metadata
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        IPAsset storage ip = ipAssets[tokenId];
        if (ip.id == 0) revert ERC721NonexistentToken(tokenId);
        if (!ip.isFinalized) {
            return string(abi.encodePacked(_baseURI(), tokenId.toString(), "/draft")); // Use a draft URI
        }
        return ip.finalContentURI; // Return the final, curated URI
    }
}
```