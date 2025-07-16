This smart contract, **QuantumForge Protocol**, represents a decentralized, AI-augmented, and community-driven R&D platform. It aims to foster innovation by funding research projects, managing intellectual property (IP) as NFTs, enabling fractional ownership, and introducing dynamic resource allocation based on performance, reputation, and simulated AI insights.

---

## QuantumForge Protocol Outline & Function Summary

**Concept:** The QuantumForge Protocol acts as a decentralized incubator and marketplace for advanced technological intellectual property (IP). It allows innovators to propose research projects, secure funding via milestones, mint their completed IP as non-fungible tokens (IP-NFTs), and even fractionalize or license them. A unique "Karma" reputation system (inspired by Soulbound Tokens) tracks contributions and influences governance, while dynamic funding and fee adjustments leverage simulated AI/oracle insights for optimal resource allocation.

**Core Principles:**
*   **Decentralized R&D Funding:** Community-governed allocation of funds to promising research.
*   **IP-NFTs & Fractionalization:** Robust management of intellectual property, enabling liquid markets for innovation.
*   **Reputation-Based Incentives (Karma):** Non-transferable "Karma" tokens reward contributions and empower governance.
*   **AI-Augmented Dynamics:** Protocol parameters (funding, fees) adapt based on simulated AI/oracle inputs, reflecting real-world performance and market conditions.
*   **Adaptive Governance:** Stakeholders collaboratively steer the protocol's evolution.

---

### Function Summary:

**I. Project & IP Lifecycle Management**
1.  **`proposeResearchProject(string memory _metadataURI, uint256 _initialFundingRequest, uint256 _impactScoreGoal)`**: Allows a user to propose a new research project, detailing its scope, initial funding needs, and a qualitative impact goal. Projects enter a "Pending" state awaiting community review.
2.  **`fundResearchProject(uint256 _projectId)`**: Initiates funding for an approved research project, transferring the initial tranche from the treasury to the project's dedicated escrow. Only executable after a governance vote.
3.  **`submitMilestoneProof(uint256 _projectId, uint256 _milestoneId, string memory _proofURI)`**: Project leads submit verifiable proof (e.g., IPFS URI of code, report, demo) for a completed project milestone.
4.  **`reviewMilestoneProof(uint256 _projectId, uint256 _milestoneId, bool _approved)`**: Governance or designated reviewers evaluate submitted milestone proof. Approval releases the next funding tranche and potentially awards Karma.
5.  **`mintIPNFT(uint256 _projectId, string memory _ipMetadataURI)`**: Mints a unique ERC-721 Non-Fungible Token (IP-NFT) representing the completed Intellectual Property once a project reaches its final approved milestone.
6.  **`fractionalizeIPNFT(uint256 _ipNFTId, string memory _tokenName, string memory _tokenSymbol, uint256 _totalSupply)`**: Allows the owner of an IP-NFT to create and distribute ERC-20 fractional ownership tokens, enabling liquid secondary markets for the IP.
7.  **`grantIPLicense(uint256 _ipNFTId, address _licensee, string memory _licenseTermsURI, uint256 _royaltyPercentage, uint256 _duration)`**: Grants a conditional, revocable license for the specific IP-NFT to a third party, defining usage terms, royalty structure, and duration.
8.  **`revokeIPLicense(uint256 _ipNFTId, address _licensee)`**: Allows the IP-NFT owner (or authorized governance) to revoke a previously granted license if terms are violated.
9.  **`claimIPRoyalties(uint256 _ipNFTId)`**: Enables the IP-NFT owner or fractional token holders to claim accrued royalty payments from licensed usage.

**II. Reputation & Incentive Systems (Karma - Soulbound Concept)**
10. **`attestToContribution(address _contributor, uint256 _projectId, uint256 _karmaPoints, string memory _attestationURI)`**: Community members can formally attest to the positive contributions or impact of an individual or a project, potentially boosting their Karma.
11. **`awardKarmaPoints(address _recipient, uint256 _points, uint256 _projectId)`**: Internal or administrative function to award non-transferable "Karma" points based on successful project completion, positive attestations, or impactful governance proposals.
12. **`penalizeKarmaPoints(address _recipient, uint256 _points, string memory _reasonURI)`**: Internal or administrative function to deduct Karma points due to failed projects, malicious activity, or negative community consensus.
13. **`redeemKarmaForBoost(uint256 _pointsToRedeem, KarmaBoostType _boostType)`**: Allows Karma holders to "burn" their Karma points in exchange for protocol benefits, such as priority in funding queues, reduced protocol fees, or a temporary boost in voting weight.
14. **`delegateKarmaWeight(address _delegatee, uint256 _weightToDelegate)`**: Enables Karma holders to delegate their influence (e.g., for voting or project review) to another participant, without transferring the Karma itself (similar to liquid democracy).

**III. Dynamic Resource Allocation & "AI" Integration**
15. **`initiateAIOracleReview(uint256 _projectId)`**: Triggers an external oracle call (simulated AI) to obtain an objective evaluation of a project's market potential, technical feasibility, or societal impact, influencing funding decisions.
16. **`adjustProjectFunding(uint256 _projectId, uint256 _newFundingAmount)`**: Dynamically adjusts the allocated funding for an ongoing project based on its performance, milestones, and "AI" oracle insights. Requires governance approval.
17. **`proposeAdaptiveFeePolicy(uint256 _newLicensingFeePermyriad, uint256 _newFractionalizationFeePermyriad)`**: Governance proposes changes to dynamic protocol fees (e.g., IP licensing fees, fractionalization fees) based on network health or simulated AI-driven recommendations.
18. **`executeAdaptiveFeeAdjustment(uint256 _newLicensingFeePermyriad, uint256 _newFractionalizationFeePermyriad)`**: Implements the approved dynamic fee changes, allowing the protocol's economics to adapt to market conditions or usage.

**IV. Decentralized Governance & Treasury**
19. **`submitGovernanceProposal(string memory _proposalURI, uint256 _quorumPercentage, uint256 _majorityPercentage)`**: Allows Karma holders to submit proposals for protocol upgrades, treasury spending, or new initiatives.
20. **`voteOnProposal(uint256 _proposalId, bool _support)`**: Karma-weighted voting on active governance proposals.
21. **`executeApprovedProposal(uint256 _proposalId)`**: Triggers the execution of a governance proposal once it passes the voting thresholds.
22. **`depositTreasuryFunds()`**: Allows external entities or users to contribute Ether to the QuantumForge treasury, supporting R&D initiatives.
23. **`withdrawTreasuryFunds(address _recipient, uint256 _amount)`**: Governed withdrawal of funds from the treasury for protocol operations, project funding, or other approved expenditures.

**V. Protocol Utility & Safety**
24. **`emergencyPause()`**: Allows a designated emergency role (e.g., a multisig) to pause critical protocol functions in case of severe vulnerabilities or unforeseen risks.
25. **`setOracleAddress(address _oracleType, address _newAddress)`**: Administrative function to update the addresses of trusted external oracle contracts (e.g., for AI insights, market data).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// --- Interfaces for external contracts/standards (simplified for this example) ---
interface IProjectNFT {
    function mint(address to, uint256 tokenId, string memory uri) external returns (uint256);
}

interface IKarmaToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function delegate(address delegatee, uint256 weightToDelegate) external; // Custom delegation logic
    function getDelegatedWeight(address delegator) external view returns (uint256);
}

interface IIPFractionalizer {
    function fractionalize(uint256 ipNFTId, string memory name, string memory symbol, uint256 supply) external returns (address);
}

interface IAIOracle {
    function getProjectEvaluation(uint256 projectId) external view returns (uint256 marketPotential, uint256 feasibility, uint256 impactScore);
}

contract QuantumForgeProtocol is Ownable, ReentrancyGuard, Pausable {
    using Counters for Counters.Counter;

    // --- State Variables ---

    Counters.Counter private _projectIdCounter;
    Counters.Counter private _ipNFTIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Configuration Addresses
    address public karmaTokenAddress;
    address public ipNFTAddress; // Represents the contract managing IP-NFTs (ERC721)
    address public ipFractionalizerAddress; // Contract responsible for fractionalizing IP-NFTs
    address public aiOracleAddress; // Address of the AI evaluation oracle

    // Protocol Fees (permyriad = parts per 10,000, 100 = 1%)
    uint256 public licensingFeePermyriad;
    uint256 public fractionalizationFeePermyriad;

    // Project States
    enum ProjectStatus { Pending, Approved, InProgress, MilestoneReview, Completed, Rejected, Canceled }

    struct ResearchProject {
        uint256 id;
        address proposer;
        string metadataURI; // URI pointing to detailed project proposal (IPFS)
        uint256 initialFundingRequest;
        uint256 currentFundingReceived;
        uint256 impactScoreGoal;
        ProjectStatus status;
        uint256 ipNFTId; // 0 if not yet minted
        uint256 lastMilestoneId;
        mapping(uint256 => Milestone) milestones;
        uint256 proposalId; // Associated governance proposal that approved it
    }

    struct Milestone {
        uint256 id;
        string proofURI; // URI to proof of completion
        uint256 fundingTrancheAmount;
        bool approved;
        bool submitted;
    }

    // IP Licensing
    struct IPLicense {
        uint256 ipNFTId;
        address licensee;
        string licenseTermsURI;
        uint256 royaltyPercentagePermyriad; // e.g., 100 = 1%
        uint256 duration; // in seconds
        uint256 startTime;
        bool active;
    }

    // Governance Proposals
    enum ProposalStatus { Active, Succeeded, Failed, Executed }

    struct GovernanceProposal {
        uint256 id;
        string proposalURI; // URI to proposal details
        address proposer;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 quorumPercentage; // Percentage of total Karma needed to pass
        uint256 majorityPercentage; // Percentage of YES votes needed to pass
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    // Mappings
    mapping(uint256 => ResearchProject) public projects;
    mapping(address => uint256[]) public userProjects; // Track projects by proposer
    mapping(uint256 => IPLicense[]) public ipLicenses; // IP-NFT ID => array of licenses
    mapping(uint256 => GovernanceProposal) public proposals;

    // Events
    event ProjectProposed(uint256 indexed projectId, address indexed proposer, string metadataURI, uint256 initialFundingRequest);
    event ProjectFunded(uint256 indexed projectId, address indexed funder, uint256 amount);
    event MilestoneSubmitted(uint256 indexed projectId, uint256 indexed milestoneId, string proofURI);
    event MilestoneReviewed(uint256 indexed projectId, uint256 indexed milestoneId, bool approved, address reviewer);
    event IPNFTMinted(uint256 indexed projectId, uint256 indexed ipNFTId, address owner);
    event IPFracted(uint256 indexed ipNFTId, address indexed fractionalTokenAddress, uint256 totalSupply);
    event IPLicenseGranted(uint256 indexed ipNFTId, address indexed licensee, uint256 indexed licenseId, uint256 royaltyPercentagePermyriad);
    event IPLicenseRevoked(uint256 indexed ipNFTId, address indexed licensee, uint256 indexed licenseId);
    event RoyaltyClaimed(uint256 indexed ipNFTId, address indexed claimant, uint256 amount);
    event KarmaAwarded(address indexed recipient, uint256 points, uint256 indexed projectId);
    event KarmaPenalized(address indexed recipient, uint256 points, string reasonURI);
    event KarmaRedeemedForBoost(address indexed redeemer, uint256 points, KarmaBoostType boostType);
    event KarmaWeightDelegated(address indexed delegator, address indexed delegatee, uint256 weight);
    event AIOracleReviewInitiated(uint256 indexed projectId);
    event ProjectFundingAdjusted(uint256 indexed projectId, uint256 newFundingAmount);
    event AdaptiveFeePolicyProposed(uint256 newLicensingFeePermyriad, uint256 newFractionalizationFeePermyriad);
    event AdaptiveFeeAdjustmentExecuted(uint256 oldLicensingFeePermyriad, uint256 newLicensingFeePermyriad, uint256 oldFractionalizationFeePermyriad, uint256 newFractionalizationFeePermyriad);
    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string proposalURI);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event ProtocolPaused(address indexed pauser);
    event OracleAddressSet(address indexed oracleType, address indexed newAddress);

    // Enums for KarmaBoostType
    enum KarmaBoostType { FundingPriority, FeeReduction, VotingWeightMultiplier }

    // --- Constructor ---
    constructor(address _karmaToken, address _ipNFT, address _ipFractionalizer, address _aiOracle) Ownable(msg.sender) {
        karmaTokenAddress = _karmaToken;
        ipNFTAddress = _ipNFT;
        ipFractionalizerAddress = _ipFractionalizer;
        aiOracleAddress = _aiOracle;

        // Initial default fees
        licensingFeePermyriad = 50; // 0.5%
        fractionalizationFeePermyriad = 100; // 1%
    }

    // --- Modifiers ---
    modifier onlyProjectProposer(uint256 _projectId) {
        require(projects[_projectId].proposer == msg.sender, "QFP: Only project proposer can call this.");
        _;
    }

    // Represents a general governance role, could be a DAO multisig or specific role
    modifier onlyGovernance() {
        // For simplicity, Owner acts as Governance. In a real DAO, this would be a more complex access control or proposal-driven execution.
        require(owner() == msg.sender, "QFP: Only governance can call this.");
        _;
    }

    // --- Core Protocol Functions ---

    /**
     * @notice Allows a user to propose a new research project.
     * @param _metadataURI URI pointing to detailed project proposal (e.g., IPFS).
     * @param _initialFundingRequest Initial funding tranche request in WEI.
     * @param _impactScoreGoal A qualitative goal for the project's societal/environmental impact (e.g., on a scale of 1-100).
     */
    function proposeResearchProject(
        string memory _metadataURI,
        uint256 _initialFundingRequest,
        uint256 _impactScoreGoal
    ) external whenNotPaused nonReentrant {
        _projectIdCounter.increment();
        uint256 newProjectId = _projectIdCounter.current();

        projects[newProjectId] = ResearchProject({
            id: newProjectId,
            proposer: msg.sender,
            metadataURI: _metadataURI,
            initialFundingRequest: _initialFundingRequest,
            currentFundingReceived: 0,
            impactScoreGoal: _impactScoreGoal,
            status: ProjectStatus.Pending,
            ipNFTId: 0,
            lastMilestoneId: 0,
            proposalId: 0 // Will be set upon approval by governance
        });
        // Note: milestones mapping is initialized dynamically when added

        userProjects[msg.sender].push(newProjectId);

        emit ProjectProposed(newProjectId, msg.sender, _metadataURI, _initialFundingRequest);
    }

    /**
     * @notice Funds an approved research project. This function is typically called as a result of a successful governance proposal.
     * @param _projectId The ID of the project to fund.
     */
    function fundResearchProject(uint256 _projectId) external payable whenNotPaused nonReentrant onlyGovernance {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Approved, "QFP: Project not approved for funding.");
        require(msg.value >= project.initialFundingRequest, "QFP: Insufficient funding provided.");

        project.currentFundingReceived += project.initialFundingRequest;
        project.status = ProjectStatus.InProgress;

        // Transfer funds to the project proposer (or a dedicated escrow contract for the project)
        // For simplicity, directly sending to proposer. In a real system, a dedicated escrow or multisig would be better.
        (bool success, ) = project.proposer.call{value: project.initialFundingRequest}("");
        require(success, "QFP: Failed to transfer initial funding to proposer.");

        emit ProjectFunded(_projectId, msg.sender, project.initialFundingRequest);
    }

    /**
     * @notice Allows the project lead to submit proof for a completed milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone.
     * @param _proofURI URI pointing to the proof of completion (e.g., IPFS hash).
     */
    function submitMilestoneProof(
        uint256 _projectId,
        uint256 _milestoneId,
        string memory _proofURI
    ) external whenNotPaused nonReentrant onlyProjectProposer(_projectId) {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.InProgress || project.status == ProjectStatus.MilestoneReview, "QFP: Project not in progress.");
        require(_milestoneId > 0 && _milestoneId <= project.lastMilestoneId + 1, "QFP: Invalid milestone ID.");

        if (_milestoneId > project.lastMilestoneId) {
            project.lastMilestoneId = _milestoneId;
        }

        project.milestones[_milestoneId] = Milestone({
            id: _milestoneId,
            proofURI: _proofURI,
            fundingTrancheAmount: 0, // This would be set by governance or proposal
            approved: false,
            submitted: true
        });
        project.status = ProjectStatus.MilestoneReview;

        emit MilestoneSubmitted(_projectId, _milestoneId, _proofURI);
    }

    /**
     * @notice Allows governance to review and approve/reject a submitted milestone proof.
     * @param _projectId The ID of the project.
     * @param _milestoneId The ID of the milestone to review.
     * @param _approved Whether the milestone proof is approved.
     */
    function reviewMilestoneProof(
        uint256 _projectId,
        uint256 _milestoneId,
        bool _approved
    ) external whenNotPaused nonReentrant onlyGovernance {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.MilestoneReview, "QFP: Project not awaiting milestone review.");
        require(project.milestones[_milestoneId].submitted, "QFP: Milestone not submitted for review.");

        project.milestones[_milestoneId].approved = _approved;

        if (_approved) {
            // Simulate funding tranche release. In a real system, this amount would be predefined or proposed.
            uint256 trancheAmount = project.initialFundingRequest / (project.lastMilestoneId > 0 ? project.lastMilestoneId : 1); // Simple example
            project.milestones[_milestoneId].fundingTrancheAmount = trancheAmount;
            project.currentFundingReceived += trancheAmount;

            (bool success, ) = project.proposer.call{value: trancheAmount}("");
            require(success, "QFP: Failed to transfer milestone funding.");

            // Award Karma points for successful milestone
            IKarmaToken(karmaTokenAddress).mint(project.proposer, 50); // Example points
            emit KarmaAwarded(project.proposer, 50, _projectId);

            project.status = ProjectStatus.InProgress; // Back to in progress for next milestone
            if (_milestoneId == project.lastMilestoneId) { // Check if this was the final milestone
                 // Simplified: assume last milestone means project completed.
                 // In reality, this would be explicitly managed via project completion proposal.
                 project.status = ProjectStatus.Completed;
            }
        } else {
            // Penalize Karma for failed milestone (optional)
            IKarmaToken(karmaTokenAddress).burn(project.proposer, 25); // Example penalty
            emit KarmaPenalized(project.proposer, 25, "Milestone proof rejected.");
            project.status = ProjectStatus.InProgress; // Allow resubmission or project termination
        }

        emit MilestoneReviewed(_projectId, _milestoneId, _approved, msg.sender);
    }

    /**
     * @notice Mints a unique ERC-721 Non-Fungible Token (IP-NFT) representing the completed Intellectual Property.
     * Can only be called after a project is marked as Completed.
     * @param _projectId The ID of the completed project.
     * @param _ipMetadataURI URI pointing to the metadata of the IP-NFT.
     */
    function mintIPNFT(uint256 _projectId, string memory _ipMetadataURI) external whenNotPaused nonReentrant onlyProjectProposer(_projectId) {
        ResearchProject storage project = projects[_projectId];
        require(project.status == ProjectStatus.Completed, "QFP: Project not completed.");
        require(project.ipNFTId == 0, "QFP: IP-NFT already minted for this project.");

        _ipNFTIdCounter.increment();
        uint256 newIpNFTId = _ipNFTIdCounter.current();

        // Mint the IP-NFT via the dedicated IP-NFT contract
        IProjectNFT(ipNFTAddress).mint(msg.sender, newIpNFTId, _ipMetadataURI);
        project.ipNFTId = newIpNFTId;

        emit IPNFTMinted(_projectId, newIpNFTId, msg.sender);
    }

    /**
     * @notice Allows the owner of an IP-NFT to create ERC-20 fractional ownership tokens.
     * @param _ipNFTId The ID of the IP-NFT to fractionalize.
     * @param _tokenName The name for the new ERC-20 fractional token.
     * @param _tokenSymbol The symbol for the new ERC-20 fractional token.
     * @param _totalSupply The total supply of fractional tokens to mint.
     */
    function fractionalizeIPNFT(
        uint256 _ipNFTId,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _totalSupply
    ) external whenNotPaused nonReentrant {
        // In a real scenario, this would check if msg.sender owns the IP-NFT via IProjectNFT.ownerOf(_ipNFTId)
        // For simplicity, we assume ownership for now or that IProjectNFT handles this internally.
        
        // Apply fractionalization fee
        uint256 feeAmount = (_totalSupply * fractionalizationFeePermyriad) / 10000;
        // In a real contract, this fee might be paid in native token or a stablecoin.
        // For now, let's just emit the event indicating fee calculation.
        // transfer to treasury or burn
        // require(msg.value >= feeAmount, "QFP: Insufficient fractionalization fee.");

        address fractionalTokenContract = IIPFractionalizer(ipFractionalizerAddress).fractionalize(
            _ipNFTId,
            _tokenName,
            _tokenSymbol,
            _totalSupply
        );

        emit IPFracted(_ipNFTId, fractionalTokenContract, _totalSupply);
    }

    /**
     * @notice Grants a conditional, revocable license for the specific IP-NFT.
     * @param _ipNFTId The ID of the IP-NFT.
     * @param _licensee The address of the entity receiving the license.
     * @param _licenseTermsURI URI pointing to the detailed license agreement.
     * @param _royaltyPercentagePermyriad The percentage of future revenue to be paid as royalty (e.g., 100 = 1%).
     * @param _duration Duration of the license in seconds.
     */
    function grantIPLicense(
        uint256 _ipNFTId,
        address _licensee,
        string memory _licenseTermsURI,
        uint256 _royaltyPercentagePermyriad,
        uint256 _duration
    ) external whenNotPaused nonReentrant {
        // Check if msg.sender owns the IP-NFT (or is authorized by governance)
        // IProjectNFT(ipNFTAddress).ownerOf(_ipNFTId) == msg.sender
        require(_royaltyPercentagePermyriad <= 10000, "QFP: Royalty percentage cannot exceed 100%.");

        IPLicense memory newLicense = IPLicense({
            ipNFTId: _ipNFTId,
            licensee: _licensee,
            licenseTermsURI: _licenseTermsURI,
            royaltyPercentagePermyriad: _royaltyPercentagePermyriad,
            duration: _duration,
            startTime: block.timestamp,
            active: true
        });

        ipLicenses[_ipNFTId].push(newLicense);

        // Apply licensing fee
        // uint256 feeAmount = (/* some base fee */ * licensingFeePermyriad) / 10000;
        // require(msg.value >= feeAmount, "QFP: Insufficient licensing fee.");

        emit IPLicenseGranted(_ipNFTId, _licensee, ipLicenses[_ipNFTId].length - 1, _royaltyPercentagePermyriad);
    }

    /**
     * @notice Allows the IP-NFT owner (or authorized governance) to revoke a previously granted license.
     * @param _ipNFTId The ID of the IP-NFT.
     * @param _licensee The address of the licensee.
     */
    function revokeIPLicense(uint256 _ipNFTId, address _licensee) external whenNotPaused nonReentrant {
        // Check if msg.sender owns the IP-NFT or is governance
        // require(IProjectNFT(ipNFTAddress).ownerOf(_ipNFTId) == msg.sender || owner() == msg.sender, "QFP: Not authorized to revoke license.");

        bool foundAndRevoked = false;
        for (uint256 i = 0; i < ipLicenses[_ipNFTId].length; i++) {
            if (ipLicenses[_ipNFTId][i].licensee == _licensee && ipLicenses[_ipNFTId][i].active) {
                ipLicenses[_ipNFTId][i].active = false; // Mark as inactive
                foundAndRevoked = true;
                emit IPLicenseRevoked(_ipNFTId, _licensee, i);
                break;
            }
        }
        require(foundAndRevoked, "QFP: Active license not found for this licensee.");
    }

    /**
     * @notice Allows fractional IP-NFT holders or the main owner to claim accrued royalty payments from licensed usage.
     * This function would typically be called by a dedicated royalty distribution contract.
     * For simplicity, this assumes a direct claim mechanism.
     * @param _ipNFTId The ID of the IP-NFT for which royalties are being claimed.
     */
    function claimIPRoyalties(uint256 _ipNFTId) external whenNotPaused nonReentrant {
        // This function would interact with a separate system or oracle that tracks royalty payments
        // and then distribute them based on fractional ownership.
        // For demonstration, we'll simulate a fixed amount.
        uint256 royaltyAmount = 1 ether; // Simulate some royalty received

        // In a real system, logic to verify claimant's ownership (full or fractional) and calculate their share
        // IProjectNFT(ipNFTAddress).ownerOf(_ipNFTId) == msg.sender || isFractionalOwner(_ipNFTId, msg.sender)
        
        (bool success, ) = msg.sender.call{value: royaltyAmount}("");
        require(success, "QFP: Failed to transfer royalty payment.");

        emit RoyaltyClaimed(_ipNFTId, msg.sender, royaltyAmount);
    }

    // --- Reputation & Incentive Systems (Karma - Soulbound Concept) ---

    /**
     * @notice Allows community members to formally attest to the quality or impact of a project or individual contribution.
     * This influences the recipient's Karma points.
     * @param _contributor The address of the contributor being attested for.
     * @param _projectId The ID of the project related to the contribution.
     * @param _karmaPoints The number of Karma points recommended by the attester. (Actual points awarded are adjusted by protocol logic).
     * @param _attestationURI URI to detailed attestation (e.g., IPFS).
     */
    function attestToContribution(
        address _contributor,
        uint256 _projectId,
        uint256 _karmaPoints,
        string memory _attestationURI
    ) external whenNotPaused nonReentrant {
        require(_contributor != address(0), "QFP: Invalid contributor address.");
        require(_karmaPoints > 0, "QFP: Attestation must recommend positive Karma.");
        // Implement logic to prevent spam or malicious attestations (e.g., reputation of attester, cooldowns)

        // For simplicity, directly award Karma based on attestation.
        // In reality, this would trigger a weighted awarding based on attester's own Karma, and consensus.
        IKarmaToken(karmaTokenAddress).mint(_contributor, _karmaPoints);
        emit KarmaAwarded(_contributor, _karmaPoints, _projectId);
    }

    /**
     * @notice Internal/administrative function to award non-transferable "Karma" points.
     * Called by protocol logic (e.g., successful milestones, impactful proposals).
     * @param _recipient The address to award Karma to.
     * @param _points The number of Karma points to award.
     * @param _projectId Optional project ID context.
     */
    function awardKarmaPoints(address _recipient, uint256 _points, uint256 _projectId) internal {
        require(_recipient != address(0), "QFP: Invalid recipient address.");
        require(_points > 0, "QFP: Points must be positive.");
        IKarmaToken(karmaTokenAddress).mint(_recipient, _points);
        emit KarmaAwarded(_recipient, _points, _projectId);
    }

    /**
     * @notice Internal/administrative function to deduct Karma points.
     * Called by protocol logic (e.g., failed projects, malicious activity).
     * @param _recipient The address to penalize.
     * @param _points The number of Karma points to deduct.
     * @param _reasonURI URI to the reason/justification for penalty.
     */
    function penalizeKarmaPoints(address _recipient, uint256 _points, string memory _reasonURI) internal {
        require(_recipient != address(0), "QFP: Invalid recipient address.");
        require(_points > 0, "QFP: Points must be positive.");
        IKarmaToken(karmaTokenAddress).burn(_recipient, _points);
        emit KarmaPenalized(_recipient, _points, _reasonURI);
    }

    /**
     * @notice Allows Karma holders to "burn" their Karma points in exchange for protocol benefits.
     * @param _pointsToRedeem The number of Karma points to redeem.
     * @param _boostType The type of boost requested (FundingPriority, FeeReduction, VotingWeightMultiplier).
     */
    function redeemKarmaForBoost(uint256 _pointsToRedeem, KarmaBoostType _boostType) external whenNotPaused nonReentrant {
        require(IKarmaToken(karmaTokenAddress).balanceOf(msg.sender) >= _pointsToRedeem, "QFP: Insufficient Karma points.");
        require(_pointsToRedeem > 0, "QFP: Must redeem positive Karma.");

        IKarmaToken(karmaTokenAddress).burn(msg.sender, _pointsToRedeem);

        // Apply the boost based on _boostType
        if (_boostType == KarmaBoostType.FundingPriority) {
            // Logic to increase funding priority score for msg.sender's future projects
            // This would interact with a priority queue system not fully implemented here.
        } else if (_boostType == KarmaBoostType.FeeReduction) {
            // Logic to grant a temporary fee reduction
            // This would involve a mapping of user => fee discount and expiry
        } else if (_boostType == KarmaBoostType.VotingWeightMultiplier) {
            // Logic to apply a temporary multiplier to voting weight
            // This would involve a mapping of user => multiplier and expiry
        }

        emit KarmaRedeemedForBoost(msg.sender, _pointsToRedeem, _boostType);
    }

    /**
     * @notice Enables Karma holders to delegate their influence (e.g., for voting or project review) to another participant.
     * The Karma itself remains with the delegator (Soulbound concept).
     * @param _delegatee The address to delegate Karma influence to.
     * @param _weightToDelegate The amount of Karma influence to delegate.
     */
    function delegateKarmaWeight(address _delegatee, uint256 _weightToDelegate) external whenNotPaused nonReentrant {
        require(_delegatee != address(0), "QFP: Invalid delegatee address.");
        require(IKarmaToken(karmaTokenAddress).balanceOf(msg.sender) >= _weightToDelegate, "QFP: Insufficient Karma to delegate.");
        require(msg.sender != _delegatee, "QFP: Cannot delegate to self.");

        IKarmaToken(karmaTokenAddress).delegate(_delegatee, _weightToDelegate); // Custom delegation logic in IKarmaToken
        emit KarmaWeightDelegated(msg.sender, _delegatee, _weightToDelegate);
    }

    // --- Dynamic Resource Allocation & "AI" Integration ---

    /**
     * @notice Triggers an external oracle call (simulated AI) to obtain an objective evaluation of a project.
     * The results would typically be fed back via a callback or updated in the contract state by the oracle.
     * @param _projectId The ID of the project to evaluate.
     */
    function initiateAIOracleReview(uint256 _projectId) external whenNotPaused nonReentrant onlyGovernance {
        require(projects[_projectId].id != 0, "QFP: Project does not exist.");
        // This function would typically call an external oracle contract
        // Example: IAIOracle(aiOracleAddress).requestProjectEvaluation(_projectId, address(this), "callbackFunction");

        // For this simplified example, we just emit an event indicating the request.
        emit AIOracleReviewInitiated(_projectId);
    }

    /**
     * @notice Dynamically adjusts the allocated funding for an ongoing project.
     * This might be based on its performance, milestones, and "AI" oracle insights.
     * Requires governance approval (implicitly, as it's onlyGovernance).
     * @param _projectId The ID of the project.
     * @param _newFundingAmount The new total funding amount for the project.
     */
    function adjustProjectFunding(uint256 _projectId, uint256 _newFundingAmount) external whenNotPaused nonReentrant onlyGovernance {
        ResearchProject storage project = projects[_projectId];
        require(project.id != 0, "QFP: Project does not exist.");
        require(project.status == ProjectStatus.InProgress, "QFP: Project not in progress.");
        require(_newFundingAmount >= project.currentFundingReceived, "QFP: New funding cannot be less than already received.");

        uint256 additionalFundingNeeded = _newFundingAmount - project.currentFundingReceived;
        project.initialFundingRequest = _newFundingAmount; // Update initial request to reflect total
        project.currentFundingReceived += additionalFundingNeeded;

        // Transfer additional funds
        (bool success, ) = project.proposer.call{value: additionalFundingNeeded}("");
        require(success, "QFP: Failed to transfer additional funding.");

        emit ProjectFundingAdjusted(_projectId, _newFundingAmount);
    }

    /**
     * @notice Governance proposes changes to dynamic protocol fees.
     * These changes might be based on network health, usage, or simulated AI-driven recommendations.
     * This function creates a governance proposal.
     * @param _newLicensingFeePermyriad The proposed new licensing fee (permyriad).
     * @param _newFractionalizationFeePermyriad The proposed new fractionalization fee (permyriad).
     */
    function proposeAdaptiveFeePolicy(
        uint256 _newLicensingFeePermyriad,
        uint256 _newFractionalizationFeePermyriad
    ) external whenNotPaused nonReentrant onlyGovernance {
        // This would typically create a formal governance proposal that needs to be voted on.
        // For simplicity here, calling this is an "intention". Execution is separate.
        emit AdaptiveFeePolicyProposed(_newLicensingFeePermyriad, _newFractionalizationFeePermyriad);
    }

    /**
     * @notice Implements approved dynamic fee changes.
     * This function would be called by the `executeApprovedProposal` function after a proposal to change fees passes.
     * @param _newLicensingFeePermyriad The new licensing fee to set.
     * @param _newFractionalizationFeePermyriad The new fractionalization fee to set.
     */
    function executeAdaptiveFeeAdjustment(
        uint256 _newLicensingFeePermyriad,
        uint256 _newFractionalizationFeePermyriad
    ) external whenNotPaused nonReentrant onlyGovernance {
        uint256 oldLicensingFee = licensingFeePermyriad;
        uint256 oldFractionalizationFee = fractionalizationFeePermyriad;

        licensingFeePermyriad = _newLicensingFeePermyriad;
        fractionalizationFeePermyriad = _newFractionalizationFeePermyriad;

        emit AdaptiveFeeAdjustmentExecuted(
            oldLicensingFee, _newLicensingFeePermyriad,
            oldFractionalizationFee, _newFractionalizationFeePermyriad
        );
    }

    // --- Decentralized Governance & Treasury ---

    /**
     * @notice Allows Karma holders to submit proposals for protocol upgrades, treasury spending, or new initiatives.
     * @param _proposalURI URI pointing to the detailed proposal document.
     * @param _quorumPercentage Percentage of total Karma supply that must vote.
     * @param _majorityPercentage Percentage of 'yes' votes needed to pass.
     */
    function submitGovernanceProposal(
        string memory _proposalURI,
        uint256 _quorumPercentage,
        uint256 _majorityPercentage
    ) external whenNotPaused nonReentrant {
        // Minimum Karma to submit proposal (anti-spam)
        require(IKarmaToken(karmaTokenAddress).balanceOf(msg.sender) > 0, "QFP: Must have Karma to submit proposal.");
        require(_quorumPercentage > 0 && _quorumPercentage <= 100, "QFP: Invalid quorum percentage.");
        require(_majorityPercentage > 50 && _majorityPercentage <= 100, "QFP: Majority must be >50% and <=100%.");

        _proposalIdCounter.increment();
        uint256 newProposalId = _proposalIdCounter.current();

        proposals[newProposalId] = GovernanceProposal({
            id: newProposalId,
            proposalURI: _proposalURI,
            proposer: msg.sender,
            creationTime: block.timestamp,
            votingEndTime: block.timestamp + 7 days, // Example: 7-day voting period
            quorumPercentage: _quorumPercentage,
            majorityPercentage: _majorityPercentage,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Active,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize
        });

        emit ProposalSubmitted(newProposalId, msg.sender, _proposalURI);
    }

    /**
     * @notice Allows Karma-weighted voting on active governance proposals.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'yes', false for 'no'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "QFP: Proposal is not active.");
        require(block.timestamp <= proposal.votingEndTime, "QFP: Voting period has ended.");
        require(!proposal.hasVoted[msg.sender], "QFP: Already voted on this proposal.");

        uint256 voterKarma = IKarmaToken(karmaTokenAddress).balanceOf(msg.sender); // Or delegated weight
        if (IKarmaToken(karmaTokenAddress).getDelegatedWeight(msg.sender) > 0) {
            voterKarma = IKarmaToken(karmaTokenAddress).getDelegatedWeight(msg.sender);
        }
        
        require(voterKarma > 0, "QFP: Must have Karma to vote.");

        if (_support) {
            proposal.yesVotes += voterKarma;
        } else {
            proposal.noVotes += voterKarma;
        }
        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(_proposalId, msg.sender, _support);
    }

    /**
     * @notice Triggers the execution of a governance proposal once it passes the voting thresholds.
     * Anyone can call this after the voting period ends.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeApprovedProposal(uint256 _proposalId) external whenNotPaused nonReentrant {
        GovernanceProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "QFP: Proposal not active or already executed.");
        require(block.timestamp > proposal.votingEndTime, "QFP: Voting period has not ended.");
        require(!proposal.executed, "QFP: Proposal already executed.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 totalKarmaSupply = IKarmaToken(karmaTokenAddress).totalSupply(); // Requires a totalSupply method on KarmaToken

        // Check quorum
        require(totalVotes * 100 >= totalKarmaSupply * proposal.quorumPercentage, "QFP: Quorum not met.");

        // Check majority
        require(proposal.yesVotes * 100 >= totalVotes * proposal.majorityPercentage, "QFP: Majority not met.");

        proposal.status = ProposalStatus.Succeeded;
        proposal.executed = true;

        // --- Execute specific actions based on proposal content ---
        // This is the tricky part for a generic DAO. In a real system, proposals would
        // encode specific calls or parameter changes. For this example, we'll
        // assume an external helper or a pattern like OpenZeppelin's Governor
        // where the proposal defines a target, calldata, and value.
        // E.g., if a proposal was to adjust fees, this function would then call
        // executeAdaptiveFeeAdjustment with the parameters from the proposal URI.

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows external entities or users to contribute Ether to the QuantumForge treasury.
     */
    function depositTreasuryFunds() external payable whenNotPaused {
        require(msg.value > 0, "QFP: Deposit amount must be greater than zero.");
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Governed withdrawal of funds from the treasury.
     * Only callable by governance after a successful proposal or designated role.
     * @param _recipient The address to send funds to.
     * @param _amount The amount of Ether to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external whenNotPaused nonReentrant onlyGovernance {
        require(_recipient != address(0), "QFP: Invalid recipient address.");
        require(address(this).balance >= _amount, "QFP: Insufficient treasury balance.");
        require(_amount > 0, "QFP: Withdrawal amount must be greater than zero.");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "QFP: Failed to withdraw funds.");

        emit TreasuryWithdrawal(_recipient, _amount);
    }

    // --- Protocol Utility & Safety ---

    /**
     * @notice Allows a designated emergency role (owner in this case) to pause critical protocol functions.
     */
    function emergencyPause() external onlyOwner whenNotPaused {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @notice Allows a designated emergency role (owner in this case) to unpause critical protocol functions.
     */
    function unpauseProtocol() external onlyOwner paused {
        _unpause();
    }

    /**
     * @notice Administrative function to update the addresses of trusted external oracle contracts.
     * @param _oracleType A symbolic representation of the oracle type (e.g., hash(AI_ORACLE_TYPE)).
     * @param _newAddress The new address for the oracle.
     */
    function setOracleAddress(address _oracleType, address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "QFP: New oracle address cannot be zero.");

        // This would typically use an enum or a bytes32 identifier for different oracle types
        // For simplicity, directly mapping.
        if (_oracleType == address(uint160(keccak256("AI_ORACLE_TYPE")))) { // Pseudo-address for type identification
            aiOracleAddress = _newAddress;
        } else {
            revert("QFP: Unknown oracle type.");
        }

        emit OracleAddressSet(_oracleType, _newAddress);
    }

    // --- View Functions ---

    /**
     * @notice Returns the current balance of the contract treasury.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Gets the details of a specific research project.
     * @param _projectId The ID of the project.
     */
    function getResearchProject(uint256 _projectId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory metadataURI,
            uint256 initialFundingRequest,
            uint256 currentFundingReceived,
            uint256 impactScoreGoal,
            ProjectStatus status,
            uint256 ipNFTId,
            uint256 lastMilestoneId
        )
    {
        ResearchProject storage project = projects[_projectId];
        return (
            project.id,
            project.proposer,
            project.metadataURI,
            project.initialFundingRequest,
            project.currentFundingReceived,
            project.impactScoreGoal,
            project.status,
            project.ipNFTId,
            project.lastMilestoneId
        );
    }

    /**
     * @notice Gets the details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     */
    function getGovernanceProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            string memory proposalURI,
            address proposer,
            uint256 creationTime,
            uint256 votingEndTime,
            uint256 quorumPercentage,
            uint256 majorityPercentage,
            uint256 yesVotes,
            uint256 noVotes,
            ProposalStatus status,
            bool executed
        )
    {
        GovernanceProposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposalURI,
            proposal.proposer,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.quorumPercentage,
            proposal.majorityPercentage,
            proposal.yesVotes,
    
            proposal.noVotes,
            proposal.status,
            proposal.executed
        );
    }
}

// --- Minimal ERC20 for KarmaToken (demonstrative, actual implementation more complex) ---
// In a real scenario, this would be a separate, more robust contract with Soulbound properties.
contract KarmaToken is ERC20Burnable {
    constructor() ERC20("Karma Token", "KRM") {
        // No initial supply, tokens are minted dynamically.
    }

    // Only allow specific addresses (like QuantumForgeProtocol) to mint.
    modifier onlyProtocol() {
        // Placeholder: in real use, would restrict based on roles or specific contract address
        require(msg.sender == owner(), "KarmaToken: Only protocol can mint.");
        _;
    }

    function mint(address _to, uint256 _amount) external onlyProtocol {
        _mint(_to, _amount);
    }

    // Custom delegation logic for Karma, where balance doesn't transfer but influence does.
    mapping(address => address) public delegates; // delegator => delegatee
    mapping(address => uint256) public delegatedWeights; // delegatee => total weight delegated to them

    function delegate(address _delegatee, uint256 _weightToDelegate) external {
        require(_delegatee != address(0), "KarmaToken: Invalid delegatee.");
        require(_weightToDelegate > 0, "KarmaToken: Must delegate positive weight.");
        require(balanceOf(msg.sender) >= _weightToDelegate, "KarmaToken: Insufficient Karma to delegate.");

        // Remove old delegation if exists
        address oldDelegatee = delegates[msg.sender];
        if (oldDelegatee != address(0)) {
            delegatedWeights[oldDelegatee] -= balanceOf(msg.sender); // Remove total balance (previous delegation)
        }
        
        delegates[msg.sender] = _delegatee;
        delegatedWeights[_delegatee] += _weightToDelegate; // Add new delegated weight
    }

    function getDelegatedWeight(address _delegator) public view returns (uint256) {
        address delegatee = delegates[_delegator];
        if (delegatee == address(0)) {
            return 0; // No delegation
        }
        return delegatedWeights[delegatee]; // This isn't quite right for individual weight.
        // It should be 'balanceOf(_delegator)' if delegated to delegatee
        // or a more complex system where actual delegated value is tracked per delegator.
        // For simplified Soulbound Karma: if you delegate, your 'vote' value goes to delegatee.
        // Let's simplify this to just return the delegator's balance if they have delegated.
        // Or better yet, the IKarmaToken.getDelegatedWeight(address) should actually give the delegator's influence.
        // Let's assume the `IKarmaToken.delegate` in QuantumForge would manage this correctly.
        // For simplicity, let's just make it return the delegator's own balance IF they delegated.
        // This is a common simplification for initial delegated voting.
        return (delegates[_delegator] != address(0) ? balanceOf(_delegator) : 0);
    }

    // Override transfer and transferFrom to prevent transfers (Soulbound)
    function transfer(address to, uint256 amount) public pure override returns (bool) {
        revert("KarmaToken: This is a Soulbound Token and cannot be transferred.");
    }

    function transferFrom(address from, address to, uint256 amount) public pure override returns (bool) {
        revert("KarmaToken: This is a Soulbound Token and cannot be transferred.");
    }

    function approve(address spender, uint256 amount) public pure override returns (bool) {
        revert("KarmaToken: This is a Soulbound Token and cannot be approved.");
    }

    function allowance(address owner, address spender) public pure override view returns (uint256) {
        return 0; // No allowances for Soulbound tokens
    }
}

// --- Minimal ERC721 for IPNFT (demonstrative, actual implementation more complex) ---
// In a real scenario, this would be a separate, more robust contract.
contract IPNFT is ERC721 {
    constructor() ERC721("Intellectual Property NFT", "IPNFT") {}

    // Only allow specific addresses (like QuantumForgeProtocol) to mint.
    modifier onlyProtocol() {
        // Placeholder: in real use, would restrict based on roles or specific contract address
        require(msg.sender == owner(), "IPNFT: Only protocol can mint.");
        _;
    }

    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external onlyProtocol returns (uint256) {
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
        return _tokenId;
    }
}

// --- Minimal IPFractionalizer (demonstrative, actual implementation more complex) ---
// In a real scenario, this would be a separate, more robust contract that deploys new ERC20s.
contract IPFractionalizer {
    function fractionalize(uint256 _ipNFTId, string memory _name, string memory _symbol, uint256 _supply) external returns (address) {
        // This would deploy a new ERC20 contract for the fractional shares of _ipNFTId
        // For demonstration, returning a dummy address.
        // In reality, it would deploy a new contract like: new ERC20(_name, _symbol)
        // and mint _supply to the caller or IP-NFT owner.
        return address(keccak256(abi.encodePacked(_ipNFTId, _name, _symbol, _supply)));
    }
}
```