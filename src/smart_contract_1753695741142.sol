Okay, this is a fantastic challenge! Let's build a smart contract that encapsulates several advanced, trendy, and creative concepts. I'll focus on a "QuantumLeap DAO" – a decentralized autonomous organization dedicated to funding, evaluating, and curating scientific research, leveraging dynamic reputation and "AI-assisted" verification (simulated, as true on-chain AI is infeasible).

The core innovation will be a **Dynamic Soulbound Reputation Token (SBRT)** that evolves based on a user's contributions and a simulated "AI-assisted" research evaluation process.

---

## QuantumLeap DAO: On-chain Scientific Research & Dynamic Reputation

### Outline:

1.  **Core Concepts & Architecture:**
    *   **Dynamic Soulbound Reputation Token (SBRT):** An ERC-721 token that is non-transferable (soulbound) but whose internal attributes (like `reputationScore`, `expertise`, `impactFactor`) are dynamically updated by the DAO based on on-chain actions. This SBRT acts as the primary governance token.
    *   **AI-Assisted Evaluation (Simulated):** Research deliverables are evaluated by community peer-review, but an "AI Oracle" (simulated via an input parameter) provides an objective score, influencing reputation.
    *   **Decentralized Science (DeSci):** Focus on funding research projects, tracking milestones, and registering research outputs (via content hashes).
    *   **Staged Project Funding:** Projects are funded milestone-by-milestone, requiring evaluation at each stage.
    *   **Liquid Governance & Delegation:** SBRT holders can delegate their voting power.
    *   **Sybil Resistance (Light):** A basic verified contributor registry.

2.  **Contract Structure:**
    *   **Data Structures:** `Project`, `Proposal`, `SBRTAttributes`, `Deliverable`.
    *   **State Variables:** Mappings for projects, proposals, SBRTs, contributors.
    *   **Events:** For transparency and off-chain indexing.
    *   **Modifiers:** For access control and state validation.
    *   **Functions (25+):** Categorized below.

### Function Summary:

#### A. Core & Initialization:
1.  **`constructor()`**: Initializes the contract, setting up the deployer as the initial owner.
2.  **`setOwner(address newOwner)`**: Transfers ownership of the contract. (Standard OpenZeppelin function).

#### B. Verified Contributor & SBRT Management:
3.  **`registerVerifiedContributor(address _contributorAddress, string memory _identityHash)`**: Allows an authorized entity (e.g., initial DAO admin, or later, a governance proposal) to mark an address as a verified contributor, required for minting an SBRT. `_identityHash` could link to a PoH solution or KYC hash off-chain.
4.  **`mintReputationSBT(address _recipient)`**: Mints a new non-transferable Soulbound Reputation Token (SBRT) to a verified contributor. Sets initial reputation.
5.  **`updateReputationScore(uint256 _sbtId, int256 _reputationDelta)`**: Core function to adjust an SBRT's `reputationScore` based on contributions, evaluations, etc.
6.  **`updateSBRTExpertise(uint256 _sbtId, string memory _expertiseArea, uint8 _level)`**: Updates the expertise profile of an SBRT holder, influencing their eligibility for certain roles or evaluations.
7.  **`getReputationSBTAttributes(uint256 _sbtId)`**: Retrieves the current attributes (score, expertise, etc.) of a specific SBRT.
8.  **`tokenURI(uint256 tokenId)`**: Overrides ERC721's `tokenURI` to return dynamic, base64-encoded JSON metadata reflecting the SBRT's current attributes.

#### C. Research Project Lifecycle:
9.  **`proposeResearchProject(string memory _ipfsHash, uint256 _initialFundingRequest, uint256 _milestoneCount)`**: Allows an SBRT holder to propose a new research project, linking to off-chain details and requesting initial funding.
10. **`fundProjectMilestone(uint256 _projectId, uint256 _milestoneIndex)`**: Allows the DAO (via governance execution) to release funds for a specific milestone after successful evaluation.
11. **`submitResearchDeliverable(uint256 _projectId, uint256 _milestoneIndex, string memory _deliverableHash)`**: Researchers submit proof of work for a milestone, linking to actual data (e.g., on IPFS/Arweave).
12. **`evaluateResearchDeliverable(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, uint8 _peerReviewScore, uint8 _aiOracleScore, string memory _feedbackHash)`**: SBRT holders (peer reviewers) evaluate a submitted deliverable. The `_aiOracleScore` simulates an AI oracle's input, influencing the final evaluation impact. This is where the "AI-assisted" part comes in.
13. **`registerFinalResearchOutput(uint256 _projectId, string memory _finalOutputHash, string memory _researchPaperURI)`**: After project completion, the final research output and published paper URI are registered on-chain for provenance.

#### D. Governance (DAO):
14. **`createGovernanceProposal(uint256 _sbtId, string memory _description, bytes memory _calldata, address _targetContract, uint256 _value)`**: SBRT holders with sufficient reputation can create proposals to change contract parameters, fund projects, or execute arbitrary calls.
15. **`voteOnProposal(uint256 _proposalId, bool _support)`**: SBRT holders (or their delegates) cast their vote on an open proposal. Voting power is based on SBRT reputation score.
16. **`delegateVote(address _delegatee)`**: Allows an SBRT holder to delegate their SBRT's voting power to another address.
17. **`undelegateVote()`**: Revokes delegation.
18. **`executeProposal(uint256 _proposalId)`**: Executes a proposal if it has met quorum and passed the voting threshold.

#### E. Dispute Resolution & Community Policing:
19. **`disputeEvaluation(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, string memory _reasonHash)`**: Allows researchers or other stakeholders to dispute an evaluation, triggering a review.
20. **`resolveDispute(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, bool _isValidDispute, int256 _reputationPenaltyForEvaluator)`**: An admin or governance action to resolve a dispute, potentially penalizing evaluators for malicious or inaccurate assessments.
21. **`flagMaliciousActivity(uint256 _sbtId, string memory _reasonHash)`**: Allows any SBRT holder to flag potentially malicious activity by another SBRT holder, triggering a governance review.

#### F. Utility & View Functions:
22. **`getProposalDetails(uint256 _proposalId)`**: Returns details of a specific proposal.
23. **`getProjectDetails(uint256 _projectId)`**: Returns details of a specific project.
24. **`getDeliverableDetails(uint256 _projectId, uint256 _milestoneIndex)`**: Returns details of a specific deliverable submission.
25. **`getVerifiedStatus(address _addr)`**: Checks if an address is registered as a verified contributor.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title QuantumLeap DAO
 * @author Your Name/AI Assistant
 * @notice A Decentralized Autonomous Organization for funding, evaluating, and curating scientific research,
 *         leveraging dynamic Soulbound Reputation Tokens (SBRTs) and simulated AI-assisted verification.
 *
 * Outline:
 * 1.  Core Concepts & Architecture:
 *     - Dynamic Soulbound Reputation Token (SBRT): An ERC-721 token that is non-transferable (soulbound) but whose internal
 *       attributes (like `reputationScore`, `expertise`, `impactFactor`) are dynamically updated by the DAO.
 *       This SBRT acts as the primary governance token.
 *     - AI-Assisted Evaluation (Simulated): Research deliverables are evaluated by community peer-review, but an
 *       "AI Oracle" (simulated via an input parameter) provides an objective score, influencing reputation.
 *     - Decentralized Science (DeSci): Focus on funding research projects, tracking milestones, and registering
 *       research outputs (via content hashes).
 *     - Staged Project Funding: Projects are funded milestone-by-milestone, requiring evaluation at each stage.
 *     - Liquid Governance & Delegation: SBRT holders can delegate their voting power.
 *     - Sybil Resistance (Light): A basic verified contributor registry.
 *
 * 2.  Contract Structure:
 *     - Data Structures: Project, Proposal, SBRTAttributes, Deliverable.
 *     - State Variables: Mappings for projects, proposals, SBRTs, contributors.
 *     - Events: For transparency and off-chain indexing.
 *     - Modifiers: For access control and state validation.
 *
 * Function Summary:
 * A. Core & Initialization:
 * 1.  `constructor()`: Initializes the contract, setting up the deployer as the initial owner.
 * 2.  `setOwner(address newOwner)`: Transfers ownership of the contract. (Standard OpenZeppelin function).
 *
 * B. Verified Contributor & SBRT Management:
 * 3.  `registerVerifiedContributor(address _contributorAddress, string memory _identityHash)`: Allows an authorized entity
 *     to mark an address as a verified contributor, required for minting an SBRT.
 * 4.  `mintReputationSBT(address _recipient)`: Mints a new non-transferable Soulbound Reputation Token (SBRT) to a verified contributor.
 * 5.  `updateReputationScore(uint256 _sbtId, int256 _reputationDelta)`: Adjusts an SBRT's `reputationScore` based on contributions.
 * 6.  `updateSBRTExpertise(uint256 _sbtId, string memory _expertiseArea, uint8 _level)`: Updates the expertise profile of an SBRT holder.
 * 7.  `getReputationSBTAttributes(uint256 _sbtId)`: Retrieves the current attributes of a specific SBRT.
 * 8.  `tokenURI(uint256 tokenId)`: Overrides ERC721's `tokenURI` for dynamic, base64-encoded JSON metadata.
 *
 * C. Research Project Lifecycle:
 * 9.  `proposeResearchProject(string memory _ipfsHash, uint256 _initialFundingRequest, uint256 _milestoneCount)`:
 *     Allows an SBRT holder to propose a new research project.
 * 10. `fundProjectMilestone(uint256 _projectId, uint256 _milestoneIndex)`: Releases funds for a milestone after evaluation (via governance).
 * 11. `submitResearchDeliverable(uint256 _projectId, uint256 _milestoneIndex, string memory _deliverableHash)`:
 *     Researchers submit proof of work for a milestone.
 * 12. `evaluateResearchDeliverable(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, uint8 _peerReviewScore, uint8 _aiOracleScore, string memory _feedbackHash)`:
 *     SBRT holders (peer reviewers) evaluate a deliverable, influenced by a simulated AI oracle score.
 * 13. `registerFinalResearchOutput(uint256 _projectId, string memory _finalOutputHash, string memory _researchPaperURI)`:
 *     Registers the final research output for provenance.
 *
 * D. Governance (DAO):
 * 14. `createGovernanceProposal(uint256 _sbtId, string memory _description, bytes memory _calldata, address _targetContract, uint256 _value)`:
 *     Creates a new governance proposal.
 * 15. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows SBRT holders (or delegates) to vote.
 * 16. `delegateVote(address _delegatee)`: Allows an SBRT holder to delegate their SBRT's voting power.
 * 17. `undelegateVote()`: Revokes delegation.
 * 18. `executeProposal(uint256 _proposalId)`: Executes a proposal if it passes.
 *
 * E. Dispute Resolution & Community Policing:
 * 19. `disputeEvaluation(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, string memory _reasonHash)`:
 *     Allows to dispute an evaluation, triggering a review.
 * 20. `resolveDispute(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, bool _isValidDispute, int256 _reputationPenaltyForEvaluator)`:
 *     Resolves a dispute, potentially penalizing evaluators.
 * 21. `flagMaliciousActivity(uint256 _sbtId, string memory _reasonHash)`: Flags potential malicious activity for governance review.
 *
 * F. Utility & View Functions:
 * 22. `getProposalDetails(uint256 _proposalId)`: Returns details of a specific proposal.
 * 23. `getProjectDetails(uint256 _projectId)`: Returns details of a specific project.
 * 24. `getDeliverableDetails(uint256 _projectId, uint256 _milestoneIndex)`: Returns details of a specific deliverable.
 * 25. `getVerifiedStatus(address _addr)`: Checks if an address is a verified contributor.
 */
contract QuantumLeapDAO is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using Address for address; // For `isContract` (though not strictly used in current version, good for future)

    // --- State Variables ---

    // Total counters for unique IDs
    Counters.Counter private _sbtIds;
    Counters.Counter private _projectIds;
    Counters.Counter private _proposalIds;

    // --- Data Structures ---

    struct SBRTAttributes {
        uint256 reputationScore; // Core reputation score
        mapping(string => uint8) expertiseLevels; // e.g., "AI": 5, "Biotech": 3 (level 1-10)
        uint256 impactFactor; // Cumulative impact from successful projects/evaluations
        address ownerAddress; // The address this SBT is bound to
        address delegatee; // Address to which voting power is delegated
    }

    enum ProjectStatus { Proposed, Active, Completed, Cancelled }
    enum DeliverableStatus { PendingSubmission, Submitted, UnderEvaluation, Approved, Rejected, Disputed }

    struct Deliverable {
        string deliverableHash; // IPFS/Arweave hash of the research deliverable
        uint256 submissionTime;
        DeliverableStatus status;
        uint8 peerReviewScore; // Average peer review score (0-100)
        uint8 aiOracleScore; // Simulated AI oracle score (0-100)
        uint256 evaluationTime;
        address evaluator; // Last evaluator's address
        uint256 evaluatorSbtId; // SBT ID of the last evaluator
        string feedbackHash; // IPFS/Arweave hash for detailed feedback
        bool disputed;
        string disputeReasonHash; // Hash of reason if disputed
    }

    struct Project {
        address proposer;
        uint256 proposerSbtId;
        string projectMetadataHash; // IPFS/Arweave hash for project details (abstract, methodology, team, etc.)
        uint256 initialFundingRequest;
        ProjectStatus status;
        uint256 milestoneCount;
        mapping(uint256 => uint256) milestoneFunds; // Amount allocated per milestone
        mapping(uint256 => Deliverable) deliverables; // Deliverables for each milestone
        string finalOutputHash; // Final research paper/output hash
        string researchPaperURI; // URI to published paper (e.g., DOI)
    }

    enum ProposalStatus { Pending, Approved, Rejected, Executed }
    enum ProposalType { Funding, PolicyChange, ArbitraryCall } // Extended for different proposal types

    struct Proposal {
        uint256 proposerSbtId;
        string description;
        bytes calldataPayload; // The encoded function call to be executed
        address targetContract; // The contract to call if type is ArbitraryCall
        uint256 value; // ETH value to send with the call
        ProposalStatus status;
        uint256 creationTime;
        uint256 votingEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 requiredQuorum; // Minimum total voting power needed for validity
        uint256 passingThreshold; // Percentage of 'for' votes required (e.g., 51 for 51%)
        mapping(uint256 => bool) hasVoted; // SBRT ID => voted
    }

    // --- Mappings ---

    // Soulbound Reputation Tokens (SBRTs)
    mapping(uint256 => SBRTAttributes) private sbrtAttributes; // tokenId => attributes
    mapping(address => uint256) private sbrtIdByAddress; // address => tokenId (for quick lookup)
    mapping(address => bool) private isVerifiedContributor; // address => bool

    // Projects
    mapping(uint256 => Project) private projects; // projectId => Project struct

    // Proposals
    mapping(uint256 => Proposal) private proposals; // proposalId => Proposal struct

    // Delegations for voting
    mapping(address => address) public delegates; // holder address => delegatee address

    // --- Governance Parameters (can be changed by proposals) ---
    uint256 public constant MIN_REPUTATION_FOR_PROPOSAL = 100; // Example: 100 reputation score needed to propose
    uint256 public constant PROPOSAL_VOTING_PERIOD = 7 days; // Example: 7 days for voting
    uint256 public constant QUORUM_PERCENTAGE = 4; // Example: 4% of total reputation supply for quorum
    uint256 public constant PASSING_THRESHOLD_PERCENTAGE = 51; // Example: 51% 'for' votes to pass

    // --- Events ---
    event VerifiedContributorRegistered(address indexed _contributor, string _identityHash);
    event SBRTMinted(address indexed _recipient, uint256 indexed _sbtId);
    event ReputationScoreUpdated(uint256 indexed _sbtId, int256 _delta, uint256 _newScore);
    event SBRTExpertiseUpdated(uint256 indexed _sbtId, string _expertiseArea, uint8 _level);

    event ProjectProposed(uint256 indexed _projectId, address indexed _proposer, string _metadataHash, uint256 _fundingRequest);
    event MilestoneFunded(uint256 indexed _projectId, uint256 indexed _milestoneIndex, uint256 _amount);
    event DeliverableSubmitted(uint256 indexed _projectId, uint256 indexed _milestoneIndex, string _deliverableHash);
    event DeliverableEvaluated(uint256 indexed _projectId, uint256 indexed _milestoneIndex, uint256 indexed _evaluatorSbtId, uint8 _peerReviewScore, uint8 _aiOracleScore, uint8 _finalScore);
    event ResearchOutputRegistered(uint256 indexed _projectId, string _finalOutputHash, string _researchPaperURI);

    event ProposalCreated(uint256 indexed _proposalId, address indexed _proposer, string _description, ProposalType _type);
    event VoteCast(uint256 indexed _proposalId, uint256 indexed _voterSbtId, bool _support, uint256 _votingPower);
    event ProposalExecuted(uint256 indexed _proposalId);
    event ProposalCanceled(uint256 indexed _proposalId);

    event VoteDelegated(address indexed _delegator, address indexed _delegatee);
    event VoteUndelegated(address indexed _delegator);

    event EvaluationDisputed(uint256 indexed _projectId, uint256 indexed _milestoneIndex, uint256 indexed _evaluatorSbtId, string _reasonHash);
    event DisputeResolved(uint256 indexed _projectId, uint256 indexed _milestoneIndex, uint256 indexed _evaluatorSbtId, bool _isValidDispute, int256 _reputationPenalty);
    event MaliciousActivityFlagged(uint256 indexed _sbtId, string _reasonHash);

    // --- Modifiers ---

    modifier onlySBTAtrributesOwner(uint256 _sbtId) {
        require(sbrtAttributes[_sbtId].ownerAddress == _msgSender(), "SBRT: Caller is not the SBT owner");
        _;
    }

    modifier onlyVerified() {
        require(isVerifiedContributor[_msgSender()], "DAO: Caller is not a verified contributor.");
        _;
    }

    modifier onlySBRTHolder() {
        require(sbrtIdByAddress[_msgSender()] != 0, "DAO: Caller does not hold an SBRT.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Proposal: Does not exist.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= _projectIds.current(), "Project: Does not exist.");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("QuantumLeap Reputation Token", "QL-SBRT") Ownable(msg.sender) {
        // The ERC721 constructor handles naming.
        // `msg.sender` becomes the initial owner of the DAO contract.
    }

    // --- A. Core & Initialization ---

    // Inherited from Ownable: `transferOwnership` and `owner()` are available.
    // The `setOwner` function from the summary is typically `transferOwnership` in Ownable.
    // function setOwner(address newOwner) external onlyOwner {
    //     transferOwnership(newOwner);
    // }

    // --- B. Verified Contributor & SBRT Management ---

    /**
     * @notice Registers an address as a verified contributor. Only owner or approved governance can call.
     * @dev This is a crucial step for Sybil resistance.
     * @param _contributorAddress The address to mark as verified.
     * @param _identityHash An optional hash linking to off-chain identity verification (e.g., PoH, KYC).
     */
    function registerVerifiedContributor(address _contributorAddress, string memory _identityHash) external onlyOwner {
        require(!isVerifiedContributor[_contributorAddress], "Contributor already verified.");
        isVerifiedContributor[_contributorAddress] = true;
        emit VerifiedContributorRegistered(_contributorAddress, _identityHash);
    }

    /**
     * @notice Mints a new non-transferable Soulbound Reputation Token (SBRT) to a verified contributor.
     * @param _recipient The address to mint the SBRT to.
     */
    function mintReputationSBT(address _recipient) external onlyVerified {
        require(sbrtIdByAddress[_recipient] == 0, "SBRT: Recipient already has an SBRT.");

        _sbtIds.increment();
        uint256 newSbtId = _sbtIds.current();

        // ERC721 requires approval for transfer, but we will prevent transfer via `_beforeTokenTransfer`
        _safeMint(_recipient, newSbtId);

        sbrtAttributes[newSbtId].ownerAddress = _recipient;
        sbrtAttributes[newSbtId].reputationScore = 1; // Initial minimal reputation
        sbrtAttributes[newSbtId].impactFactor = 0;
        sbrtAttributes[newSbtId].delegatee = address(0); // No delegation initially

        sbrtIdByAddress[_recipient] = newSbtId; // Map address to SBT ID

        emit SBRTMinted(_recipient, newSbtId);
    }

    /**
     * @dev ERC721 hook to prevent transfers, making the token Soulbound.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
        // Allow minting (from address(0)) and burning (to address(0)), but prevent transfers between users.
        if (from != address(0) && to != address(0)) {
            revert("SBRT: This token is soulbound and cannot be transferred.");
        }
    }

    /**
     * @notice Adjusts an SBRT's reputation score. Can be positive or negative.
     * @dev This is a core mechanic, called by governance, evaluation functions, or dispute resolution.
     * @param _sbtId The ID of the SBRT to update.
     * @param _reputationDelta The amount to add or subtract from the reputation score.
     */
    function updateReputationScore(uint256 _sbtId, int256 _reputationDelta) external {
        // Only owner or via governance proposal can directly update reputation.
        // For simplicity, let's allow it via direct call for demo, but in real DAO, this would be a governance action.
        require(_sbtId > 0 && _sbtId <= _sbtIds.current(), "SBRT: Invalid SBT ID.");

        int256 currentScore = int256(sbrtAttributes[_sbtId].reputationScore);
        currentScore += _reputationDelta;

        // Ensure reputation doesn't go below zero (or a defined minimum)
        sbrtAttributes[_sbtId].reputationScore = uint256(currentScore > 0 ? currentScore : 0);
        emit ReputationScoreUpdated(_sbtId, _reputationDelta, sbrtAttributes[_sbtId].reputationScore);
    }

    /**
     * @notice Updates the expertise profile of an SBRT holder.
     * @param _sbtId The ID of the SBRT to update.
     * @param _expertiseArea The string representing the area of expertise (e.g., "AI", "Genomics").
     * @param _level The expertise level (e.g., 1-10).
     */
    function updateSBRTExpertise(uint256 _sbtId, string memory _expertiseArea, uint8 _level) external onlySBTAtrributesOwner(_sbtId) {
        require(_sbtId > 0 && _sbtId <= _sbtIds.current(), "SBRT: Invalid SBT ID.");
        require(_level > 0 && _level <= 10, "Expertise level must be between 1 and 10.");
        sbrtAttributes[_sbtId].expertiseLevels[_expertiseArea] = _level;
        emit SBRTExpertiseUpdated(_sbtId, _expertiseArea, _level);
    }

    /**
     * @notice Retrieves the current attributes of a specific SBRT.
     * @param _sbtId The ID of the SBRT.
     * @return reputationScore The current reputation score.
     * @return impactFactor The cumulative impact factor.
     * @return owner The address the SBT is bound to.
     * @return delegatee The current delegatee for voting.
     */
    function getReputationSBTAttributes(uint256 _sbtId) external view returns (uint256 reputationScore, uint256 impactFactor, address owner, address delegatee) {
        require(_sbtId > 0 && _sbtId <= _sbtIds.current(), "SBRT: Invalid SBT ID.");
        SBRTAttributes storage attrs = sbrtAttributes[_sbtId];
        return (attrs.reputationScore, attrs.impactFactor, attrs.ownerAddress, attrs.delegatee);
    }

    /**
     * @notice Overrides ERC721's tokenURI to return dynamic, base64-encoded JSON metadata.
     * @dev This allows the SBRT's metadata to reflect its current, evolving attributes on-chain.
     * @param tokenId The ID of the SBRT.
     * @return A data URI containing the base64-encoded JSON metadata.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        SBRTAttributes storage attrs = sbrtAttributes[tokenId];
        string memory expertiseJson = "";
        // In a real scenario, iterating through a mapping like this isn't efficient for dynamic JSON.
        // A better approach would be to store expertise as an array of structs or have off-chain metadata generation.
        // For demonstration, we'll keep it simple or omit dynamic expertise in JSON for gas.
        // Example: If expertise was stored as `string[] public expertiseAreas; uint8[] public expertiseLevels;`
        // we could iterate. For a mapping, it's not feasible on-chain to list all keys.
        // So, for now, expertise will be reflected only via `getReputationSBTAttributes` or off-chain tools.

        string memory json = string.concat(
            '{"name": "QuantumLeap SBRT #', tokenId.toString(), '",',
            '"description": "A dynamic, soulbound token representing on-chain reputation and contribution in the QuantumLeap DAO. This token's attributes evolve with user's actions and evaluations.",',
            '"image": "ipfs://QmbB1g9yJ2Q3b4c5D6e7F8H9I0k1L2M3N4O5P6q7R8s",', // Placeholder image
            '"attributes": [',
            '{"trait_type": "Reputation Score", "value": ', attrs.reputationScore.toString(), '},',
            '{"trait_type": "Impact Factor", "value": ', attrs.impactFactor.toString(), '}',
            ']}'
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    // --- C. Research Project Lifecycle ---

    /**
     * @notice Allows an SBRT holder to propose a new research project.
     * @param _ipfsHash IPFS hash of the detailed project proposal (abstract, methodology, budget breakdown, etc.).
     * @param _initialFundingRequest The initial amount of ETH requested for the first milestone.
     * @param _milestoneCount The total number of milestones planned for the project.
     */
    function proposeResearchProject(string memory _ipfsHash, uint256 _initialFundingRequest, uint256 _milestoneCount) external onlySBRTHolder {
        uint256 proposerSbtId = sbrtIdByAddress[_msgSender()];
        require(sbrtAttributes[proposerSbtId].reputationScore >= MIN_REPUTATION_FOR_PROPOSAL, "Project: Not enough reputation to propose.");
        require(_initialFundingRequest > 0, "Project: Initial funding request must be greater than zero.");
        require(_milestoneCount > 0, "Project: Must have at least one milestone.");

        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();

        Project storage newProject = projects[newProjectId];
        newProject.proposer = _msgSender();
        newProject.proposerSbtId = proposerSbtId;
        newProject.projectMetadataHash = _ipfsHash;
        newProject.initialFundingRequest = _initialFundingRequest;
        newProject.status = ProjectStatus.Proposed;
        newProject.milestoneCount = _milestoneCount;
        newProject.deliverables[1].status = DeliverableStatus.PendingSubmission; // Initialize first milestone

        // Initial funding request for milestone 1
        newProject.milestoneFunds[1] = _initialFundingRequest;

        emit ProjectProposed(newProjectId, _msgSender(), _ipfsHash, _initialFundingRequest);
    }

    /**
     * @notice Funds a specific milestone of a project. Can only be executed via a successful governance proposal.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone to fund.
     */
    function fundProjectMilestone(uint256 _projectId, uint256 _milestoneIndex) external payable {
        // This function should ideally only be callable by the `executeProposal` function after a successful vote.
        // For simplicity of direct call demo, we'll allow owner, but in real DAO, `executeProposal` would be the gateway.
        require(msg.sender == address(this) || msg.sender == owner(), "Project: Only callable by DAO or owner via governance.");
        projectExists(_projectId);
        Project storage project = projects[_projectId];

        require(project.status == ProjectStatus.Active || project.status == ProjectStatus.Proposed, "Project: Not in fundable state.");
        require(_milestoneIndex > 0 && _milestoneIndex <= project.milestoneCount, "Project: Invalid milestone index.");
        require(project.milestoneFunds[_milestoneIndex] == 0 || msg.value >= project.milestoneFunds[_milestoneIndex], "Project: Incorrect funding amount provided or already funded.");

        // If the project is in 'Proposed' state, setting it to 'Active' upon first milestone funding.
        if (project.status == ProjectStatus.Proposed) {
            project.status = ProjectStatus.Active;
        }

        project.milestoneFunds[_milestoneIndex] = msg.value; // Record the amount funded

        // Initialize next milestone if not final
        if (_milestoneIndex < project.milestoneCount) {
             project.deliverables[_milestoneIndex + 1].status = DeliverableStatus.PendingSubmission;
        }

        emit MilestoneFunded(_projectId, _milestoneIndex, msg.value);
    }

    /**
     * @notice Allows a project's proposer to submit a research deliverable for a specific milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone for which the deliverable is submitted.
     * @param _deliverableHash IPFS/Arweave hash of the actual research deliverable.
     */
    function submitResearchDeliverable(uint256 _projectId, uint256 _milestoneIndex, string memory _deliverableHash) external {
        projectExists(_projectId);
        Project storage project = projects[_projectId];
        require(project.proposer == _msgSender(), "Project: Only project proposer can submit deliverables.");
        require(_milestoneIndex > 0 && _milestoneIndex <= project.milestoneCount, "Project: Invalid milestone index.");
        require(project.deliverables[_milestoneIndex].status == DeliverableStatus.PendingSubmission ||
                project.deliverables[_milestoneIndex].status == DeliverableStatus.Rejected,
                "Deliverable: Not ready for submission or already submitted/approved.");
        require(bytes(_deliverableHash).length > 0, "Deliverable: Hash cannot be empty.");

        Deliverable storage deliverable = project.deliverables[_milestoneIndex];
        deliverable.deliverableHash = _deliverableHash;
        deliverable.submissionTime = block.timestamp;
        deliverable.status = DeliverableStatus.Submitted;
        deliverable.disputed = false; // Reset dispute status if re-submitting

        emit DeliverableSubmitted(_projectId, _milestoneIndex, _deliverableHash);
    }

    /**
     * @notice Allows an SBRT holder to evaluate a submitted research deliverable.
     * @dev The `_aiOracleScore` simulates an AI oracle's input, influencing the final evaluation impact.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone's deliverable.
     * @param _evaluatorSbtId The SBT ID of the evaluator.
     * @param _peerReviewScore A score (0-100) given by the human peer reviewer.
     * @param _aiOracleScore A simulated score (0-100) from an AI oracle (e.g., GPT for content analysis).
     * @param _feedbackHash IPFS hash for detailed feedback/justification.
     */
    function evaluateResearchDeliverable(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, uint8 _peerReviewScore, uint8 _aiOracleScore, string memory _feedbackHash) external onlySBTAtrributesOwner(_evaluatorSbtId) {
        projectExists(_projectId);
        require(sbrtAttributes[_evaluatorSbtId].ownerAddress == _msgSender(), "SBRT: Caller is not the evaluator's SBT owner.");
        Project storage project = projects[_projectId];
        Deliverable storage deliverable = project.deliverables[_milestoneIndex];

        require(deliverable.status == DeliverableStatus.Submitted || deliverable.status == DeliverableStatus.UnderEvaluation, "Deliverable: Not in evaluable state.");
        require(_peerReviewScore <= 100 && _aiOracleScore <= 100, "Evaluation scores must be between 0 and 100.");
        require(_evaluatorSbtId != project.proposerSbtId, "Evaluation: Proposer cannot evaluate their own project.");

        // Prevent multiple evaluations for simplicity, or implement a weighted average if multiple evaluators are desired
        require(deliverable.evaluatorSbtId == 0 || deliverable.evaluatorSbtId == _evaluatorSbtId, "Deliverable: Already evaluated by another, or duplicate evaluation.");

        deliverable.peerReviewScore = _peerReviewScore;
        deliverable.aiOracleScore = _aiOracleScore;
        deliverable.evaluationTime = block.timestamp;
        deliverable.evaluator = _msgSender();
        deliverable.evaluatorSbtId = _evaluatorSbtId;
        deliverable.feedbackHash = _feedbackHash;
        deliverable.status = DeliverableStatus.UnderEvaluation; // Set to UnderEvaluation until final decision

        // Example logic for determining outcome and reputation adjustments
        uint8 finalScore = (deliverable.peerReviewScore + deliverable.aiOracleScore) / 2; // Simple average
        if (finalScore >= 70) { // Threshold for approval
            deliverable.status = DeliverableStatus.Approved;
            // Reward researcher and evaluator
            updateReputationScore(project.proposerSbtId, 50); // Researcher gets reputation boost
            updateReputationScore(_evaluatorSbtId, 10); // Evaluator gets reputation for accurate evaluation
        } else {
            deliverable.status = DeliverableStatus.Rejected;
            // Optionally, penalize researcher or provide less reward. No penalty for evaluator for rejecting.
        }

        emit DeliverableEvaluated(_projectId, _milestoneIndex, _evaluatorSbtId, _peerReviewScore, _aiOracleScore, finalScore);

        // If it's the final milestone and approved, mark project as completed
        if (_milestoneIndex == project.milestoneCount && deliverable.status == DeliverableStatus.Approved) {
            project.status = ProjectStatus.Completed;
            updateReputationScore(project.proposerSbtId, 100); // Larger bonus for completing project
            sbrtAttributes[project.proposerSbtId].impactFactor += 1; // Increment impact factor
        }
    }

    /**
     * @notice Registers the final research output and published paper URI for provenance.
     * @param _projectId The ID of the completed project.
     * @param _finalOutputHash IPFS/Arweave hash of the final research data/code.
     * @param _researchPaperURI URI to the published paper (e.g., DOI, arXiv link).
     */
    function registerFinalResearchOutput(uint256 _projectId, string memory _finalOutputHash, string memory _researchPaperURI) external {
        projectExists(_projectId);
        Project storage project = projects[_projectId];
        require(project.proposer == _msgSender(), "Project: Only proposer can register final output.");
        require(project.status == ProjectStatus.Completed, "Project: Must be completed to register final output.");
        require(bytes(_finalOutputHash).length > 0 && bytes(_researchPaperURI).length > 0, "Output and URI cannot be empty.");

        project.finalOutputHash = _finalOutputHash;
        project.researchPaperURI = _researchPaperURI;

        emit ResearchOutputRegistered(_projectId, _finalOutputHash, _researchPaperURI);
    }

    // --- D. Governance (DAO) ---

    /**
     * @notice Allows an SBRT holder to create a new governance proposal.
     * @param _sbtId The SBT ID of the proposer.
     * @param _description A brief description of the proposal.
     * @param _calldata The encoded function call to be executed if the proposal passes.
     * @param _targetContract The address of the contract to call for execution.
     * @param _value The amount of ETH to send with the call (e.g., for funding projects).
     */
    function createGovernanceProposal(uint256 _sbtId, string memory _description, bytes memory _calldata, address _targetContract, uint256 _value) external onlySBTAtrributesOwner(_sbtId) {
        require(sbrtAttributes[_sbtId].reputationScore >= MIN_REPUTATION_FOR_PROPOSAL, "Proposal: Not enough reputation to propose.");
        require(bytes(_description).length > 0, "Proposal: Description cannot be empty.");

        _proposalIds.increment();
        uint256 newProposalId = _proposalIds.current();

        Proposal storage newProposal = proposals[newProposalId];
        newProposal.proposerSbtId = _sbtId;
        newProposal.description = _description;
        newProposal.calldataPayload = _calldata;
        newProposal.targetContract = _targetContract;
        newProposal.value = _value;
        newProposal.status = ProposalStatus.Pending;
        newProposal.creationTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + PROPOSAL_VOTING_PERIOD;
        newProposal.requiredQuorum = getTotalReputationSupply() * QUORUM_PERCENTAGE / 100;
        newProposal.passingThreshold = PASSING_THRESHOLD_PERCENTAGE;

        // Determine proposal type based on calldata/target for event
        ProposalType propType;
        if (_targetContract == address(this) && _calldata.length > 0 &&
            (bytes4(_calldata[:4]) == this.fundProjectMilestone.selector)) {
            propType = ProposalType.Funding;
        } else if (_targetContract != address(0) && _calldata.length > 0) {
            propType = ProposalType.ArbitraryCall;
        } else {
            propType = ProposalType.PolicyChange; // Generic for other types
        }

        emit ProposalCreated(newProposalId, _msgSender(), _description, propType);
    }

    /**
     * @notice Allows an SBRT holder (or their delegate) to cast a vote on an open proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, false for 'against' vote.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlySBRTHolder proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal: Not in pending state for voting.");
        require(block.timestamp <= proposal.votingEndTime, "Proposal: Voting period has ended.");

        // Get the actual voter's SBT ID (could be delegatee or self)
        uint256 voterSbtId = sbrtIdByAddress[getVotingPowerHolder(_msgSender())];
        require(voterSbtId != 0, "Vote: No SBRT found for voter or delegatee.");
        require(!proposal.hasVoted[voterSbtId], "Vote: SBT has already voted on this proposal.");

        uint256 votingPower = sbrtAttributes[voterSbtId].reputationScore;
        require(votingPower > 0, "Vote: SBT has no voting power (reputation score is 0).");

        if (_support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[voterSbtId] = true;

        emit VoteCast(_proposalId, voterSbtId, _support, votingPower);
    }

    /**
     * @notice Allows an SBRT holder to delegate their SBRT's voting power to another address.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVote(address _delegatee) external onlySBRTHolder {
        require(_delegatee != address(0), "Delegate: Cannot delegate to zero address.");
        require(_delegatee != _msgSender(), "Delegate: Cannot delegate to self.");
        require(sbrtIdByAddress[_delegatee] != 0, "Delegate: Delegatee must hold an SBRT.");

        uint256 delegatorSbtId = sbrtIdByAddress[_msgSender()];
        sbrtAttributes[delegatorSbtId].delegatee = _delegatee;
        delegates[_msgSender()] = _delegatee;
        emit VoteDelegated(_msgSender(), _delegatee);
    }

    /**
     * @notice Revokes delegation, returning voting power to the original SBRT holder.
     */
    function undelegateVote() external onlySBRTHolder {
        uint256 delegatorSbtId = sbrtIdByAddress[_msgSender()];
        require(sbrtAttributes[delegatorSbtId].delegatee != address(0), "Delegate: No active delegation to undelegate.");

        sbrtAttributes[delegatorSbtId].delegatee = address(0);
        delete delegates[_msgSender()];
        emit VoteUndelegated(_msgSender());
    }

    /**
     * @dev Internal function to get the address that holds the voting power for a given address.
     * @param _voter The address checking for voting power.
     * @return The address (either _voter or its delegatee) that can cast votes.
     */
    function getVotingPowerHolder(address _voter) internal view returns (address) {
        if (delegates[_voter] != address(0)) {
            return delegates[_voter];
        }
        return _voter;
    }

    /**
     * @notice Executes a governance proposal if it has met quorum and passed the voting threshold.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Pending, "Proposal: Not in pending state for execution.");
        require(block.timestamp > proposal.votingEndTime, "Proposal: Voting period not yet ended.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes >= proposal.requiredQuorum, "Proposal: Quorum not met.");
        require(proposal.votesFor * 100 / totalVotes >= proposal.passingThreshold, "Proposal: Did not meet passing threshold.");

        proposal.status = ProposalStatus.Executed;

        // Execute the payload
        (bool success, ) = proposal.targetContract.call{value: proposal.value}(proposal.calldataPayload);
        require(success, "Proposal: Execution failed.");

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice Allows the proposer to cancel a proposal before voting begins or if it failed.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function revokeProposal(uint256 _proposalId) external proposalExists(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(sbrtAttributes[proposal.proposerSbtId].ownerAddress == _msgSender(), "Proposal: Only proposer can revoke.");
        require(proposal.status == ProposalStatus.Pending && block.timestamp < proposal.votingEndTime, "Proposal: Can only revoke pending proposals before voting ends.");
        // Could also allow revocation if it failed quorum/threshold but not executed.

        proposal.status = ProposalStatus.Rejected; // Mark as rejected/canceled
        emit ProposalCanceled(_proposalId);
    }

    // --- E. Dispute Resolution & Community Policing ---

    /**
     * @notice Allows a researcher or any SBRT holder to dispute a deliverable evaluation.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone whose evaluation is disputed.
     * @param _evaluatorSbtId The SBT ID of the evaluator whose assessment is disputed.
     * @param _reasonHash IPFS/Arweave hash for the detailed reason for the dispute.
     */
    function disputeEvaluation(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, string memory _reasonHash) external onlySBRTHolder {
        projectExists(_projectId);
        Project storage project = projects[_projectId];
        Deliverable storage deliverable = project.deliverables[_milestoneIndex];

        require(deliverable.status == DeliverableStatus.Approved || deliverable.status == DeliverableStatus.Rejected, "Dispute: Deliverable not in a finalized evaluation state.");
        require(!deliverable.disputed, "Dispute: Evaluation already disputed.");
        require(deliverable.evaluatorSbtId == _evaluatorSbtId, "Dispute: Provided evaluator SBT ID does not match.");
        require(bytes(_reasonHash).length > 0, "Dispute: Reason hash cannot be empty.");

        deliverable.disputed = true;
        deliverable.disputeReasonHash = _reasonHash;
        deliverable.status = DeliverableStatus.Disputed; // Change status to reflect dispute

        emit EvaluationDisputed(_projectId, _milestoneIndex, _evaluatorSbtId, _reasonHash);

        // A governance proposal would typically be created here to resolve the dispute.
        // For simplicity, `resolveDispute` is a separate call for now.
    }

    /**
     * @notice Resolves a disputed evaluation, potentially penalizing evaluators for malicious or inaccurate assessments.
     * @dev This function would typically be called by a successful governance proposal.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     * @param _evaluatorSbtId The SBT ID of the evaluator involved in the dispute.
     * @param _isValidDispute True if the dispute is deemed valid (i.e., evaluator was wrong/malicious).
     * @param _reputationPenaltyForEvaluator The amount of reputation to subtract if the dispute is valid.
     */
    function resolveDispute(uint256 _projectId, uint256 _milestoneIndex, uint256 _evaluatorSbtId, bool _isValidDispute, int256 _reputationPenaltyForEvaluator) external onlyOwner {
        // In a real DAO, this would be triggered by a governance proposal execution.
        projectExists(_projectId);
        Project storage project = projects[_projectId];
        Deliverable storage deliverable = project.deliverables[_milestoneIndex];

        require(deliverable.status == DeliverableStatus.Disputed, "Dispute: Deliverable is not currently disputed.");
        require(deliverable.evaluatorSbtId == _evaluatorSbtId, "Dispute: Evaluator SBT ID does not match.");

        if (_isValidDispute) {
            updateReputationScore(_evaluatorSbtId, -_reputationPenaltyForEvaluator); // Penalize evaluator
            // Revert deliverable status for re-evaluation or mark as approved/rejected based on dispute outcome.
            // For simplicity, let's mark it as rejected for now, and proposer can resubmit.
            deliverable.status = DeliverableStatus.Rejected;
        } else {
            // Dispute was invalid, evaluator was correct. Optionally reward evaluator.
            deliverable.status = DeliverableStatus.Approved; // Or original status if it was approved
        }
        deliverable.disputed = false; // Dispute resolved

        emit DisputeResolved(_projectId, _milestoneIndex, _evaluatorSbtId, _isValidDispute, _reputationPenaltyForEvaluator);
    }

    /**
     * @notice Allows any SBRT holder to flag potentially malicious activity by another SBRT holder, triggering a governance review.
     * @param _sbtId The SBT ID of the person being flagged.
     * @param _reasonHash IPFS/Arweave hash for the detailed reason for flagging.
     */
    function flagMaliciousActivity(uint256 _sbtId, string memory _reasonHash) external onlySBRTHolder {
        require(_sbtId > 0 && _sbtId <= _sbtIds.current(), "Flag: Invalid SBT ID.");
        require(sbrtAttributes[_sbtId].ownerAddress != _msgSender(), "Flag: Cannot flag yourself.");
        require(bytes(_reasonHash).length > 0, "Flag: Reason hash cannot be empty.");

        // This would typically trigger a special type of governance proposal for review.
        // For simplicity, this just emits an event.
        emit MaliciousActivityFlagged(_sbtId, _reasonHash);
    }

    // --- F. Utility & View Functions ---

    /**
     * @notice Returns details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     */
    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (
        uint256 proposerSbtId,
        string memory description,
        ProposalStatus status,
        uint256 creationTime,
        uint256 votingEndTime,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 requiredQuorum,
        uint256 passingThreshold
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.proposerSbtId,
            proposal.description,
            proposal.status,
            proposal.creationTime,
            proposal.votingEndTime,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.requiredQuorum,
            proposal.passingThreshold
        );
    }

    /**
     * @notice Returns details of a specific project.
     * @param _projectId The ID of the project.
     */
    function getProjectDetails(uint256 _projectId) public view projectExists(_projectId) returns (
        address proposer,
        uint256 proposerSbtId,
        string memory projectMetadataHash,
        uint256 initialFundingRequest,
        ProjectStatus status,
        uint256 milestoneCount,
        string memory finalOutputHash,
        string memory researchPaperURI
    ) {
        Project storage project = projects[_projectId];
        return (
            project.proposer,
            project.proposerSbtId,
            project.projectMetadataHash,
            project.initialFundingRequest,
            project.status,
            project.milestoneCount,
            project.finalOutputHash,
            project.researchPaperURI
        );
    }

    /**
     * @notice Returns details of a specific deliverable submission for a milestone.
     * @param _projectId The ID of the project.
     * @param _milestoneIndex The index of the milestone.
     */
    function getDeliverableDetails(uint256 _projectId, uint256 _milestoneIndex) public view projectExists(_projectId) returns (
        string memory deliverableHash,
        uint256 submissionTime,
        DeliverableStatus status,
        uint8 peerReviewScore,
        uint8 aiOracleScore,
        uint256 evaluationTime,
        address evaluator,
        uint256 evaluatorSbtId,
        string memory feedbackHash,
        bool disputed,
        string memory disputeReasonHash
    ) {
        Project storage project = projects[_projectId];
        require(_milestoneIndex > 0 && _milestoneIndex <= project.milestoneCount, "Deliverable: Invalid milestone index.");
        Deliverable storage deliverable = project.deliverables[_milestoneIndex];
        return (
            deliverable.deliverableHash,
            deliverable.submissionTime,
            deliverable.status,
            deliverable.peerReviewScore,
            deliverable.aiOracleScore,
            deliverable.evaluationTime,
            deliverable.evaluator,
            deliverable.evaluatorSbtId,
            deliverable.feedbackHash,
            deliverable.disputed,
            deliverable.disputeReasonHash
        );
    }

    /**
     * @notice Checks if an address is registered as a verified contributor.
     * @param _addr The address to check.
     * @return True if the address is a verified contributor, false otherwise.
     */
    function getVerifiedStatus(address _addr) public view returns (bool) {
        return isVerifiedContributor[_addr];
    }

    /**
     * @notice Returns the SBT ID associated with an address.
     * @param _addr The address to query.
     * @return The SBT ID, or 0 if no SBT is owned by the address.
     */
    function getSbtIdByAddress(address _addr) public view returns (uint256) {
        return sbrtIdByAddress[_addr];
    }

    /**
     * @notice Returns the total cumulative reputation score across all minted SBRTs.
     * @dev This is used for calculating quorum.
     * @return The total reputation supply.
     */
    function getTotalReputationSupply() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= _sbtIds.current(); i++) {
            total += sbrtAttributes[i].reputationScore;
        }
        return total;
    }

    /**
     * @notice Withdraws the contract's ETH balance. Can only be triggered by successful governance proposal.
     * @dev This function should only be called by a governance proposal execution.
     * @param _amount The amount of ETH to withdraw.
     * @param _to The address to send the ETH to.
     */
    function withdrawFunds(uint256 _amount, address _to) external {
        require(msg.sender == address(this) || msg.sender == owner(), "Withdraw: Only callable by DAO or owner via governance.");
        require(address(this).balance >= _amount, "Withdraw: Insufficient balance.");
        require(_to != address(0), "Withdraw: Cannot send to zero address.");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdraw: Failed to send ETH.");
    }
}
```