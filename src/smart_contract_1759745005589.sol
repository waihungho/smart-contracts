Here's a Solidity smart contract named `AetheriumLabs` that aims to be an **Adaptive Knowledge Curation & AI-Assisted Research Funding DAO**. It incorporates advanced concepts like AI oracle integration (simulated), dynamic reputation, Knowledge NFTs (KNFTs) for voting power, multi-role governance, and on-chain parameter updates.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // For KNFT interaction

/**
 * @title AetheriumLabs: Adaptive Knowledge Curation & AI-Assisted Research Funding DAO
 * @author Your Name/Pseudonym
 * @notice This contract implements a decentralized autonomous organization (DAO) focused on funding scientific research,
 *         curating knowledge, and leveraging AI for proposal evaluation. It introduces a multi-faceted governance model
 *         involving researchers, curators, community voters, and a central governor. Key features include:
 *         - AI-assisted research proposal scoring.
 *         - Milestone-based funding and progress tracking.
 *         - A dynamic reputation system for researchers.
 *         - Knowledge NFTs (KNFTs) representing validated research outcomes, stakeable for increased voting power.
 *         - Performance-based rewards for curators and accurate voters.
 *         - Decentralized parameter governance through community voting.
 *         This contract aims to provide an advanced, creative, and trendy framework for community-driven research and
 *         knowledge advancement in Web3.
 */
contract AetheriumLabs {

    // --- Outline and Function Summary ---
    // The contract's functions are categorized to provide clarity on their purpose and interaction within the DAO.

    // I. Core Infrastructure & Access Control (3 functions)
    //    1. constructor(): Initializes the contract with an initial governor.
    //    2. transferGovernorship(address newGovernor): Allows the current governor to transfer their role to a new address.
    //    3. renounceGovernorship(): Allows the governor to voluntarily step down, leaving the role vacant (can be reassigned via parameter change proposal).
    //
    // II. Funding & System Parameters (5 functions)
    //    4. depositFunds(): Enables anyone to contribute ETH to the DAO's central funding pool.
    //    5. withdrawSurplusFunds(uint256 amount): Allows the governor to withdraw excess funds beyond operational needs from the contract.
    //    6. setProposalFee(uint256 fee): Sets the fee (in wei) required for researchers to submit a new proposal.
    //    7. setVotingAndReviewPeriods(uint256 _votingPeriod, uint256 _milestoneReviewPeriod): Configures the duration for proposal voting and milestone review periods in seconds.
    //    8. setRewardRates(uint256 _curatorRewardBps, uint256 _voterRewardBps): Sets the reward rates in basis points (1/10000) for curators (per successful review) and voters (per accurate vote on completed proposals).
    //
    // III. Researcher & Curator Management (6 functions)
    //    9. registerResearcher(string calldata name): Allows a user to apply for researcher status, which requires governor approval.
    //   10. approveResearcher(address researcherAddress): Governor approves a pending researcher application, granting them the ability to submit proposals.
    //   11. revokeResearcher(address researcherAddress): Governor revokes an approved researcher's status.
    //   12. registerCurator(string calldata name): Allows a user to apply for curator status, which requires governor approval.
    //   13. approveCurator(address curatorAddress): Governor approves a pending curator application, granting them the ability to review milestones.
    //   14. revokeCurator(address curatorAddress): Governor revokes an approved curator's status.
    //
    // IV. Research Proposal Life Cycle (7 functions)
    //   15. submitResearchProposal(string calldata title, string calldata description, uint256 fundingRequested, Milestone[] calldata milestones): Researchers submit new proposals, including a title, detailed description, total funding requested, and a breakdown into milestones. Requires the `proposalFee`.
    //   16. requestAIAssessment(uint256 proposalId): Initiates an external AI oracle call to assess a proposal's viability and potential impact. Typically called by the governor or an authorized bot.
    //   17. receiveAIAssessment(uint256 proposalId, uint256 aiScore): A callback function, expected to be invoked by the designated AI Oracle contract, to report the AI's assessment score for a proposal.
    //   18. castVoteOnProposal(uint256 proposalId, bool voteYes): Allows community members to vote 'Yes' or 'No' on a research proposal during its active voting period. Voting power can be enhanced by staked KNFTs.
    //   19. finalizeProposalVoting(uint256 proposalId): Concludes the voting phase for a proposal once the voting period ends, determining whether the proposal is Approved or Rejected based on community votes and AI score.
    //   20. submitMilestoneReport(uint256 proposalId, uint256 milestoneIndex, string calldata reportHash): Researchers report the completion of a specific milestone, providing an off-chain reference (e.g., IPFS hash) to the report.
    //   21. reviewMilestone(uint256 proposalId, uint256 milestoneIndex, bool approved): Curators review a reported milestone, marking it as approved or rejected. Successful reviews accrue rewards for the curator.
    //
    // V. Funding & Completion (3 functions)
    //   22. disburseMilestoneFunding(uint256 proposalId, uint256 milestoneIndex): Disburses the allocated funds for an approved milestone to the researcher.
    //   23. completeProposal(uint256 proposalId): Marks a proposal as fully completed. This is automatically triggered when all milestones are funded but can also be manually called by the researcher if applicable.
    //   24. cancelProposal(uint256 proposalId, string calldata reason): Governor can cancel an active or pending proposal at any stage, typically leading to a negative reputation adjustment for the researcher.
    //
    // VI. Knowledge NFTs (KNFTs) & Data Curation (Interactions with an external ERC721 contract) (3 functions)
    //   25. mintKNFTFromProposal(address _knftContract, uint256 proposalId, string calldata uri): Governor or an authorized curator mints a KNFT (representing a validated research outcome or dataset) on an external ERC721 contract, linking it to a successfully completed proposal.
    //   26. stakeKNFTForVotingPower(address _knftContract, uint256 tokenId): Allows users to stake KNFTs (from a specified external KNFT contract) within this DAO to augment their voting power.
    //   27. unstakeKNFT(address _knftContract, uint256 tokenId): Allows users to retrieve their previously staked KNFTs.
    //
    // VII. Reputation & Rewards (3 functions)
    //   28. updateReputationBasedOnOutcome(uint256 proposalId, bool success): An internal or governor-called function that dynamically adjusts a researcher's reputation score based on the successful completion or failure/cancellation of their proposals.
    //   29. claimCuratorRewards(): Allows curators to claim their accumulated ETH rewards for successfully reviewing milestones.
    //   30. claimVoterRewards(uint256[] calldata proposalIds): Allows community voters to claim ETH rewards for accurately predicting the outcome (completion/failure) of research proposals.
    //
    // VIII. Decentralized Parameter Governance (3 functions)
    //   31. proposeParameterChange(string calldata description, bytes calldata encodedCallData): Governor initiates a proposal to change core system parameters (e.g., `proposalFee`, `votingPeriod`). The change is executed only if approved by community vote. `encodedCallData` specifies the function call to be made on `address(this)`.
    //   32. voteOnParameterChange(uint256 changeId, bool voteYes): Community members vote 'Yes' or 'No' on proposed parameter changes, utilizing their calculated voting power.
    //   33. executeParameterChange(uint256 changeId): Governor executes a parameter change proposal that has successfully passed community voting.
    //
    // IX. View Functions (4 functions)
    //    (These are public functions to read contract state but do not modify it)
    //    - getResearchProposal(uint256 proposalId): Retrieves all details of a specific research proposal.
    //    - getResearcher(address researcherAddress): Retrieves the profile details of a registered researcher.
    //    - getCurator(address curatorAddress): Retrieves the profile details of a registered curator.
    //    - getParameterChangeProposal(uint256 changeId): Retrieves the details of a specific parameter change proposal.
    //
    // X. Administrative & Configuration (2 functions)
    //    - setAIOracleAddress(address _aiOracleAddress): Sets the address of the external AI Oracle contract. Ideally configured via a parameter change proposal after initial setup.
    //    - setKNFTContractAddress(address _knftContractAddress): Sets the address of the external KNFT ERC721 contract. Ideally configured via a parameter change proposal after initial setup.

    // --- State Variables ---
    address public governor;
    uint256 public proposalFee; // Fee in wei to submit a proposal
    uint256 public votingPeriod; // Duration for proposal voting in seconds
    uint256 public milestoneReviewPeriod; // Duration for milestone review in seconds
    uint256 public curatorRewardBps; // Basis points (1/10000) for curator rewards
    uint256 public voterRewardBps; // Basis points (1/10000) for voter rewards

    uint256 public nextProposalId;
    uint256 public nextParameterChangeId;

    // --- External Contracts ---
    // A mock AI Oracle; in a real scenario, this would be a specialized oracle contract
    address public aiOracleAddress;
    // The address of the external KNFT (ERC721) contract
    address public knftContractAddress;

    // --- Structs ---
    struct Researcher {
        address wallet;
        string name;
        uint256 registeredAt;
        bool approved;
        uint256 reputation; // Accumulated reputation score
    }

    struct Curator {
        address wallet;
        string name;
        uint256 registeredAt;
        bool approved;
        uint256 totalReviews;
        uint256 successfulReviews;
        uint256 earnedRewards; // ETH rewards accrued
    }

    enum ProposalStatus { PendingApproval, Voting, Approved, Funded, Rejected, InProgress, Completed, Failed }
    enum MilestoneStatus { PendingReport, Reported, Reviewed, Approved, Rejected }

    struct Milestone {
        string description;
        uint256 fundingAllocation; // Amount in wei for this milestone
        uint256 completionDeadline; // Unix timestamp
        MilestoneStatus status;
        address[] reviewers; // Addresses of curators who reviewed this milestone
    }

    struct ResearchProposal {
        uint256 id;
        address researcher;
        string title;
        string description;
        uint256 fundingRequested; // Total funding requested
        uint256 fundingGranted;   // Total funding granted so far
        uint256 submittedAt;
        uint256 votingEndsAt;
        uint256 aiScore; // Score from the AI oracle
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
        Milestone[] milestones;
        uint256 currentMilestoneIndex; // Index of the next milestone to be reported/reviewed
        mapping(address => bool) voters; // Tracks who has voted on this proposal (used for uniqueness and reward tracking)
        mapping(address => bool) votedYes; // Tracks how each address voted
    }

    enum ParameterChangeStatus { PendingVote, Approved, Rejected, Executed }

    struct ParameterChangeProposal {
        uint256 id;
        address proposer;
        string description; // Description of the proposed change
        bytes encodedCallData; // Encoded function call to execute if approved, targets `address(this)`
        uint256 proposedAt;
        uint256 votingEndsAt;
        uint256 yesVotes;
        uint256 noVotes;
        ParameterChangeStatus status;
        mapping(address => bool) voters; // Tracks who has voted on this parameter change
    }

    // --- Mappings ---
    mapping(address => Researcher) public researchers;
    mapping(address => Curator) public curators;
    mapping(uint256 => ResearchProposal) public proposals;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    // user => KNFT_contract => array of tokenIds
    mapping(address => mapping(address => uint256[])) public stakedKNFTs; 

    // --- Events ---
    event GovernorTransferred(address indexed previousGovernor, address indexed newGovernor);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event ProposalFeeSet(uint256 newFee);
    event VotingAndReviewPeriodsSet(uint256 newVotingPeriod, uint256 newReviewPeriod);
    event RewardRatesSet(uint256 newCuratorRewardBps, uint256 newVoterRewardBps);

    event ResearcherRegistered(address indexed researcher, string name);
    event ResearcherApproved(address indexed researcher);
    event ResearcherRevoked(address indexed researcher);
    event CuratorRegistered(address indexed curator, string name);
    event CuratorApproved(address indexed curator);
    event CuratorRevoked(address indexed curator);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed researcher, uint256 fundingRequested);
    event AIAssessmentRequested(uint256 indexed proposalId);
    event AIAssessmentReceived(uint256 indexed proposalId, uint256 aiScore);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool voteYes, uint256 currentYesVotes, uint256 currentNoVotes);
    event ProposalVotingFinalized(uint256 indexed proposalId, ProposalStatus newStatus, uint256 finalYesVotes, uint256 finalNoVotes);
    event ProposalStatusUpdated(uint256 indexed proposalId, ProposalStatus newStatus);

    event MilestoneReported(uint256 indexed proposalId, uint256 indexed milestoneIndex, string reportHash);
    event MilestoneReviewed(uint256 indexed proposalId, uint256 indexed milestoneIndex, address indexed reviewer, bool approved);
    event MilestoneFundingDisbursed(uint256 indexed proposalId, uint256 indexed milestoneIndex, uint256 amount);

    event ProposalCompleted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId, string reason);

    event KNFTMinted(address indexed knftContract, uint256 indexed proposalId, uint256 indexed tokenId, address recipient);
    event KNFTStaked(address indexed user, address indexed knftContract, uint256 indexed tokenId);
    event KNFTUnstaked(address indexed user, address indexed knftContract, uint256 indexed tokenId);

    event ReputationUpdated(address indexed researcher, uint256 newReputation);
    event CuratorRewardClaimed(address indexed curator, uint256 amount);
    event VoterRewardClaimed(address indexed voter, uint256 amount);

    event ParameterChangeProposed(uint256 indexed changeId, address indexed proposer, string description);
    event ParameterChangeVoted(uint256 indexed changeId, address indexed voter, bool voteYes);
    event ParameterChangeExecuted(uint256 indexed changeId);


    // --- Modifiers ---
    modifier onlyGovernor() {
        require(msg.sender == governor, "Not the governor");
        _;
    }

    modifier onlyResearcher() {
        require(researchers[msg.sender].approved, "Not an approved researcher");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender].approved, "Not an approved curator");
        _;
    }

    modifier onlyAIOracle() {
        require(msg.sender == aiOracleAddress, "Only AI Oracle can call this");
        _;
    }

    // --- Constructor ---
    constructor() {
        governor = msg.sender;
        proposalFee = 0.05 ether; // Example: 0.05 ETH
        votingPeriod = 7 days; // Example: 7 days
        milestoneReviewPeriod = 3 days; // Example: 3 days
        curatorRewardBps = 500; // Example: 5% of milestone allocation
        voterRewardBps = 100; // Example: 1% of total funding if voted correctly
    }

    // --- I. Core Infrastructure & Access Control ---

    /**
     * @notice Transfers the governor role to a new address. Only the current governor can call this.
     * @param newGovernor The address of the new governor.
     */
    function transferGovernorship(address newGovernor) public onlyGovernor {
        require(newGovernor != address(0), "New governor cannot be zero address");
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorTransferred(oldGovernor, newGovernor);
    }

    /**
     * @notice Renounces the governor role. The role becomes address(0) and can only be set again by proposing a parameter change.
     *         Only the current governor can call this.
     */
    function renounceGovernorship() public onlyGovernor {
        address oldGovernor = governor;
        governor = address(0);
        emit GovernorTransferred(oldGovernor, address(0));
    }

    // --- II. Funding & System Parameters ---

    /**
     * @notice Allows anyone to deposit Ether into the contract's funding pool.
     */
    function depositFunds() public payable {
        require(msg.value > 0, "Must deposit non-zero amount");
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Allows the governor to withdraw surplus Ether from the contract.
     *         A parameter change proposal could be used to set a 'minimum operational balance' to prevent draining.
     * @param amount The amount of Ether to withdraw.
     */
    function withdrawSurplusFunds(uint256 amount) public onlyGovernor {
        require(amount > 0, "Withdraw amount must be positive");
        require(address(this).balance >= amount, "Insufficient contract balance");
        // In a real system, you might have a 'minimum reserve'
        // require(address(this).balance - amount >= MIN_RESERVE, "Cannot withdraw below minimum reserve");
        
        payable(governor).transfer(amount);
        emit FundsWithdrawn(governor, amount);
    }

    /**
     * @notice Sets the fee required for researchers to submit a new proposal.
     *         Only the governor can call this.
     * @param fee The new proposal submission fee in wei.
     */
    function setProposalFee(uint256 fee) public onlyGovernor {
        proposalFee = fee;
        emit ProposalFeeSet(fee);
    }

    /**
     * @notice Sets the durations for proposal voting and milestone review periods.
     *         Only the governor can call this.
     * @param _votingPeriod The new voting period in seconds.
     * @param _milestoneReviewPeriod The new milestone review period in seconds.
     */
    function setVotingAndReviewPeriods(uint256 _votingPeriod, uint256 _milestoneReviewPeriod) public onlyGovernor {
        require(_votingPeriod > 0 && _milestoneReviewPeriod > 0, "Periods must be positive");
        votingPeriod = _votingPeriod;
        milestoneReviewPeriod = _milestoneReviewPeriod;
        emit VotingAndReviewPeriodsSet(_votingPeriod, _milestoneReviewPeriod);
    }

    /**
     * @notice Sets the reward rates for curators and voters.
     *         Only the governor can call this.
     * @param _curatorRewardBps The reward rate for curators in basis points (e.g., 500 for 5%).
     * @param _voterRewardBps The reward rate for voters in basis points (e.g., 100 for 1%).
     */
    function setRewardRates(uint256 _curatorRewardBps, uint256 _voterRewardBps) public onlyGovernor {
        require(_curatorRewardBps <= 10000 && _voterRewardBps <= 10000, "Reward BPS cannot exceed 10000 (100%)");
        curatorRewardBps = _curatorRewardBps;
        voterRewardBps = _voterRewardBps;
        emit RewardRatesSet(_curatorRewardBps, _voterRewardBps);
    }

    // --- III. Researcher & Curator Management ---

    /**
     * @notice Allows a user to apply for researcher status.
     * @param name The name or pseudonym of the researcher.
     */
    function registerResearcher(string calldata name) public {
        require(researchers[msg.sender].wallet == address(0), "Already registered as researcher");
        researchers[msg.sender] = Researcher({
            wallet: msg.sender,
            name: name,
            registeredAt: block.timestamp,
            approved: false, // Requires governor approval
            reputation: 0
        });
        emit ResearcherRegistered(msg.sender, name);
    }

    /**
     * @notice Allows the governor to approve a pending researcher application.
     * @param researcherAddress The address of the researcher to approve.
     */
    function approveResearcher(address researcherAddress) public onlyGovernor {
        require(researchers[researcherAddress].wallet != address(0), "Researcher not registered");
        require(!researchers[researcherAddress].approved, "Researcher already approved");
        researchers[researcherAddress].approved = true;
        emit ResearcherApproved(researcherAddress);
    }

    /**
     * @notice Allows the governor to revoke researcher status.
     * @param researcherAddress The address of the researcher to revoke.
     */
    function revokeResearcher(address researcherAddress) public onlyGovernor {
        require(researchers[researcherAddress].wallet != address(0), "Researcher not registered");
        require(researchers[researcherAddress].approved, "Researcher not currently approved");
        researchers[researcherAddress].approved = false;
        // Optionally, reset reputation or specific project statuses
        emit ResearcherRevoked(researcherAddress);
    }

    /**
     * @notice Allows a user to apply for curator status.
     * @param name The name or pseudonym of the curator.
     */
    function registerCurator(string calldata name) public {
        require(curators[msg.sender].wallet == address(0), "Already registered as curator");
        curators[msg.sender] = Curator({
            wallet: msg.sender,
            name: name,
            registeredAt: block.timestamp,
            approved: false, // Requires governor approval
            totalReviews: 0,
            successfulReviews: 0,
            earnedRewards: 0
        });
        emit CuratorRegistered(msg.sender, name);
    }

    /**
     * @notice Allows the governor to approve a pending curator application.
     * @param curatorAddress The address of the curator to approve.
     */
    function approveCurator(address curatorAddress) public onlyGovernor {
        require(curators[curatorAddress].wallet != address(0), "Curator not registered");
        require(!curators[curatorAddress].approved, "Curator already approved");
        curators[curatorAddress].approved = true;
        emit CuratorApproved(curatorAddress);
    }

    /**
     * @notice Allows the governor to revoke curator status.
     * @param curatorAddress The address of the curator to revoke.
     */
    function revokeCurator(address curatorAddress) public onlyGovernor {
        require(curators[curatorAddress].wallet != address(0), "Curator not registered");
        require(curators[curatorAddress].approved, "Curator not currently approved");
        curators[curatorAddress].approved = false;
        // Optionally, manage any pending reviews or rewards
        emit CuratorRevoked(curatorAddress);
    }

    // --- IV. Research Proposal Life Cycle ---

    /**
     * @notice Allows an approved researcher to submit a new research proposal.
     *         Requires a proposal fee, sent along with the transaction.
     * @param title The title of the research proposal.
     * @param description A detailed description of the research.
     * @param fundingRequested The total ETH requested for the project.
     * @param milestones An array of milestones with descriptions, funding allocations, and deadlines.
     */
    function submitResearchProposal(
        string calldata title,
        string calldata description,
        uint256 fundingRequested,
        Milestone[] calldata milestones
    ) public payable onlyResearcher {
        require(msg.value == proposalFee, "Incorrect proposal fee");
        require(fundingRequested > 0, "Funding requested must be positive");
        require(milestones.length > 0, "Must have at least one milestone");

        uint256 totalMilestoneAllocation = 0;
        for (uint i = 0; i < milestones.length; i++) {
            require(milestones[i].fundingAllocation > 0, "Milestone funding must be positive");
            totalMilestoneAllocation += milestones[i].fundingAllocation;
        }
        require(totalMilestoneAllocation == fundingRequested, "Total milestone allocation must match total funding requested");
        require(address(this).balance >= fundingRequested, "Insufficient contract funds for requested amount");

        uint256 id = nextProposalId++;
        proposals[id].id = id;
        proposals[id].researcher = msg.sender;
        proposals[id].title = title;
        proposals[id].description = description;
        proposals[id].fundingRequested = fundingRequested;
        proposals[id].submittedAt = block.timestamp;
        proposals[id].votingEndsAt = block.timestamp + votingPeriod;
        proposals[id].status = ProposalStatus.PendingApproval; // Start as Pending, moved to Voting after AI/initial check
        proposals[id].milestones = new Milestone[](milestones.length);
        for(uint i=0; i < milestones.length; i++) {
            proposals[id].milestones[i] = milestones[i];
            proposals[id].milestones[i].status = MilestoneStatus.PendingReport;
        }

        emit ProposalSubmitted(id, msg.sender, fundingRequested);
    }

    /**
     * @notice Triggers an external AI oracle to assess a research proposal.
     *         This would typically be called by the governor or an authorized off-chain service.
     * @param proposalId The ID of the proposal to assess.
     */
    function requestAIAssessment(uint256 proposalId) public onlyGovernor {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.PendingApproval, "Proposal not in PendingApproval state");
        require(aiOracleAddress != address(0), "AI Oracle address not set");

        // In a real scenario, this would trigger an external call to the AI Oracle contract
        // which would then call back `receiveAIAssessment` after computation.
        // For simulation, we just emit an event to signal an off-chain process.
        emit AIAssessmentRequested(proposalId);
    }

    /**
     * @notice Callback function from the AI Oracle contract to report the assessment score.
     *         Only the designated `aiOracleAddress` can call this.
     * @param proposalId The ID of the proposal being assessed.
     * @param aiScore The score provided by the AI oracle (e.g., 0-100).
     */
    function receiveAIAssessment(uint256 proposalId, uint256 aiScore) external onlyAIOracle {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.PendingApproval, "Proposal not awaiting AI assessment");
        
        proposal.aiScore = aiScore;
        // Automatically move to voting phase after AI assessment
        proposal.status = ProposalStatus.Voting;
        emit AIAssessmentReceived(proposalId, aiScore);
        emit ProposalStatusUpdated(proposalId, ProposalStatus.Voting);
    }

    /**
     * @notice Allows any user to cast a vote on a research proposal.
     *         Staked KNFTs can increase voting power (calculated via `getVotingPower`).
     * @param proposalId The ID of the proposal to vote on.
     * @param voteYes True for a 'Yes' vote, false for a 'No' vote.
     */
    function castVoteOnProposal(uint256 proposalId, bool voteYes) public {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Voting, "Proposal not in voting phase");
        require(block.timestamp <= proposal.votingEndsAt, "Voting period has ended");
        require(!proposal.voters[msg.sender], "Already voted on this proposal");

        proposal.voters[msg.sender] = true;
        proposal.votedYes[msg.sender] = voteYes;

        uint256 power = getVotingPower(msg.sender);
        if (voteYes) {
            proposal.yesVotes += power;
        } else {
            proposal.noVotes += power;
        }
        emit VoteCast(proposalId, msg.sender, voteYes, proposal.yesVotes, proposal.noVotes);
    }

    /**
     * @notice Concludes the voting phase for a proposal, determining its outcome.
     *         Can be called by anyone after the voting period ends.
     * @param proposalId The ID of the proposal to finalize.
     */
    function finalizeProposalVoting(uint256 proposalId) public {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Voting, "Proposal not in voting phase");
        require(block.timestamp > proposal.votingEndsAt, "Voting period has not ended yet");

        // Example logic for approval:
        // Requires a simple majority of yesVotes over noVotes,
        // AND a minimum AI score (e.g., 60 out of 100),
        // AND a minimum number of total votes (e.g., at least 5 equivalent base votes).
        bool passedVoting = (proposal.yesVotes > proposal.noVotes && proposal.aiScore >= 60 && (proposal.yesVotes + proposal.noVotes) >= 5);

        if (passedVoting) {
            proposal.status = ProposalStatus.Approved;
            // Funds are 'earmarked' but not disbursed until milestones are completed.
        } else {
            proposal.status = ProposalStatus.Rejected;
        }
        emit ProposalVotingFinalized(proposalId, proposal.status, proposal.yesVotes, proposal.noVotes);
        emit ProposalStatusUpdated(proposalId, proposal.status);
    }

    /**
     * @notice Allows a researcher to report the completion of a milestone.
     *         Only the proposal's researcher can call this, and only for the current active milestone.
     * @param proposalId The ID of the proposal.
     * @param milestoneIndex The index of the milestone being reported.
     * @param reportHash IPFS hash or similar identifier for the milestone report.
     */
    function submitMilestoneReport(uint256 proposalId, uint256 milestoneIndex, string calldata reportHash) public onlyResearcher {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.researcher == msg.sender, "Only the proposal's researcher can report milestones");
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.InProgress, "Proposal not in active state");
        require(milestoneIndex == proposal.currentMilestoneIndex, "Not the current milestone to be reported");
        require(milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        require(proposal.milestones[milestoneIndex].status == MilestoneStatus.PendingReport, "Milestone already reported or reviewed");

        proposal.milestones[milestoneIndex].status = MilestoneStatus.Reported;
        // The reportHash is recorded in the event, but not stored on-chain to save gas.
        emit MilestoneReported(proposalId, milestoneIndex, reportHash);
    }

    /**
     * @notice Allows an approved curator to review a reported milestone.
     *         For simplicity, one rejection fails the milestone. One approval moves it to approved status.
     *         In a more complex system, multiple reviews or a voting mechanism would be employed.
     * @param proposalId The ID of the proposal.
     * @param milestoneIndex The index of the milestone being reviewed.
     * @param approved True if the milestone is approved, false otherwise.
     */
    function reviewMilestone(uint256 proposalId, uint256 milestoneIndex, bool approved) public onlyCurator {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.InProgress, "Proposal not in active state");
        require(milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        require(milestoneIndex == proposal.currentMilestoneIndex, "Not the current milestone to be reviewed");
        require(proposal.milestones[milestoneIndex].status == MilestoneStatus.Reported, "Milestone not reported or already reviewed");
        
        Curator storage curator = curators[msg.sender];
        // Prevent a curator from reviewing the same milestone multiple times
        for (uint i = 0; i < proposal.milestones[milestoneIndex].reviewers.length; i++) {
            require(proposal.milestones[milestoneIndex].reviewers[i] != msg.sender, "Curator already reviewed this milestone");
        }
        proposal.milestones[milestoneIndex].reviewers.push(msg.sender); // Record reviewer

        if (!approved) {
            proposal.milestones[milestoneIndex].status = MilestoneStatus.Rejected;
            proposal.status = ProposalStatus.Failed; // Project fails if a milestone is rejected
            updateReputationBasedOnOutcome(proposalId, false); // Penalize researcher
            emit MilestoneReviewed(proposalId, milestoneIndex, msg.sender, false);
            emit ProposalStatusUpdated(proposalId, ProposalStatus.Failed);
            return;
        }

        // If approved, update milestone status and curator's stats
        proposal.milestones[milestoneIndex].status = MilestoneStatus.Approved;
        curator.totalReviews++;
        curator.successfulReviews++;
        // Accrue rewards for the curator, claimable later
        curator.earnedRewards += (proposal.milestones[milestoneIndex].fundingAllocation * curatorRewardBps) / 10000;

        emit MilestoneReviewed(proposalId, milestoneIndex, msg.sender, true);
    }

    // --- V. Funding & Completion ---

    /**
     * @notice Disburses funds for an approved milestone to the researcher.
     *         Only the governor can call this.
     * @param proposalId The ID of the proposal.
     * @param milestoneIndex The index of the milestone to fund.
     */
    function disburseMilestoneFunding(uint256 proposalId, uint256 milestoneIndex) public onlyGovernor {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Approved || proposal.status == ProposalStatus.InProgress, "Proposal not in active state (Approved/InProgress)");
        require(milestoneIndex < proposal.milestones.length, "Invalid milestone index");
        require(milestoneIndex == proposal.currentMilestoneIndex, "Not the current milestone to be funded");
        require(proposal.milestones[milestoneIndex].status == MilestoneStatus.Approved, "Milestone not approved for funding");
        require(address(this).balance >= proposal.milestones[milestoneIndex].fundingAllocation, "Insufficient contract balance for disbursement");

        // Transition proposal to InProgress if it was Approved and this is the first milestone
        if (proposal.status == ProposalStatus.Approved) {
            proposal.status = ProposalStatus.InProgress;
            emit ProposalStatusUpdated(proposalId, ProposalStatus.InProgress);
        }

        // Disburse funds
        payable(proposal.researcher).transfer(proposal.milestones[milestoneIndex].fundingAllocation);
        proposal.fundingGranted += proposal.milestones[milestoneIndex].fundingAllocation;
        
        proposal.currentMilestoneIndex++; // Move to the next milestone

        // If all milestones funded, consider project complete
        if (proposal.currentMilestoneIndex == proposal.milestones.length) {
            proposal.status = ProposalStatus.Completed;
            updateReputationBasedOnOutcome(proposalId, true); // Update reputation on successful completion
            emit ProposalCompleted(proposalId);
            emit ProposalStatusUpdated(proposalId, ProposalStatus.Completed);
        } // Else, the project remains in InProgress, awaiting the next milestone report.

        emit MilestoneFundingDisbursed(proposalId, milestoneIndex, proposal.milestones[milestoneIndex].fundingAllocation);
    }

    /**
     * @notice Marks a proposal as fully completed. This is typically handled automatically when all milestones are funded,
     *         but can be manually called by the researcher if applicable (e.g., for projects without formal milestones).
     * @param proposalId The ID of the proposal to complete.
     */
    function completeProposal(uint256 proposalId) public onlyResearcher {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.researcher == msg.sender, "Only proposal researcher can mark as complete");
        require(proposal.status == ProposalStatus.InProgress, "Proposal not in InProgress state");
        // Ensure all milestones are considered complete before manual completion
        require(proposal.currentMilestoneIndex == proposal.milestones.length, "All milestones must be funded/completed first to manually complete");

        proposal.status = ProposalStatus.Completed;
        updateReputationBasedOnOutcome(proposalId, true);
        emit ProposalCompleted(proposalId);
        emit ProposalStatusUpdated(proposalId, ProposalStatus.Completed);
    }

    /**
     * @notice Allows the governor to cancel a proposal at any stage.
     *         Remaining funds for this proposal are effectively returned to the general pool.
     * @param proposalId The ID of the proposal to cancel.
     * @param reason A string explaining why the proposal was cancelled.
     */
    function cancelProposal(uint256 proposalId, string calldata reason) public onlyGovernor {
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status != ProposalStatus.Completed && proposal.status != ProposalStatus.Failed && proposal.status != ProposalStatus.Rejected, "Cannot cancel a completed, failed, or rejected proposal");

        proposal.status = ProposalStatus.Failed; // Use failed as a general "stopped" state for clarity
        updateReputationBasedOnOutcome(proposalId, false); // Reflect negatively on researcher
        emit ProposalCancelled(proposalId, reason);
        emit ProposalStatusUpdated(proposalId, ProposalStatus.Failed);
    }

    // --- VI. Knowledge NFTs (KNFTs) & Data Curation ---

    /**
     * @notice Allows the governor (or potentially an authorized curator role via a new modifier) to mint a KNFT for a successfully completed research proposal.
     *         This function interacts with an external ERC721 KNFT contract.
     *         NOTE: This requires the external KNFT contract to have a `mint` function that this contract can call.
     *         The current `IERC721` standard does not define a `mint` function; a custom interface or an `ERC721Mintable` contract would be needed.
     *         For this example, we're simulating the interaction with an event.
     * @param _knftContract The address of the KNFT ERC721 contract.
     * @param proposalId The ID of the completed proposal.
     * @param uri The URI for the KNFT metadata.
     */
    function mintKNFTFromProposal(address _knftContract, uint256 proposalId, string calldata uri) public onlyGovernor { // Could be onlyGovernor OR specific curators
        ResearchProposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Completed, "KNFT can only be minted for completed proposals");
        require(_knftContract != address(0), "KNFT Contract address not set");
        
        // In a real scenario, you'd call a custom mint function on your KNFT contract:
        // IKNFT(_knftContract).mint(proposal.researcher, uri); // Assuming an IKNFT interface with a `mint` function
        
        // For this example, we simulate by emitting an event with a placeholder tokenId.
        // The actual KNFT minting and token ID generation would happen in the external _knftContract.
        uint256 newKNFTTokenId = type(uint256).max; // Placeholder; actual ID would come from the external contract
        
        emit KNFTMinted(_knftContract, proposalId, newKNFTTokenId, proposal.researcher);
    }

    /**
     * @notice Allows users to stake KNFTs (from an external ERC721 contract) to gain additional voting power within the DAO.
     *         Requires the KNFT to be approved for transfer by this contract.
     * @param _knftContract The address of the KNFT ERC721 contract.
     * @param tokenId The ID of the KNFT to stake.
     */
    function stakeKNFTForVotingPower(address _knftContract, uint256 tokenId) public {
        require(_knftContract != address(0), "KNFT Contract address not set");
        IERC721 knft = IERC721(_knftContract);
        require(knft.ownerOf(tokenId) == msg.sender, "Caller is not the owner of the KNFT");
        require(knft.getApproved(tokenId) == address(this) || knft.isApprovedForAll(msg.sender, address(this)), "KNFT not approved for staking by this contract");

        knft.transferFrom(msg.sender, address(this), tokenId); // Transfer KNFT to this contract
        stakedKNFTs[msg.sender][_knftContract].push(tokenId);
        emit KNFTStaked(msg.sender, _knftContract, tokenId);
    }

    /**
     * @notice Allows users to unstake their KNFTs, returning them to the owner.
     * @param _knftContract The address of the KNFT ERC721 contract.
     * @param tokenId The ID of the KNFT to unstake.
     */
    function unstakeKNFT(address _knftContract, uint256 tokenId) public {
        require(_knftContract != address(0), "KNFT Contract address not set");
        bool found = false;
        uint256[] storage userStakedTokens = stakedKNFTs[msg.sender][_knftContract];
        for (uint i = 0; i < userStakedTokens.length; i++) {
            if (userStakedTokens[i] == tokenId) {
                // Efficiently remove element by swapping with last and popping
                userStakedTokens[i] = userStakedTokens[userStakedTokens.length - 1];
                userStakedTokens.pop();
                found = true;
                break;
            }
        }
        require(found, "KNFT not found among your staked tokens");
        
        IERC721(_knftContract).transferFrom(address(this), msg.sender, tokenId); // Transfer KNFT back to user
        emit KNFTUnstaked(msg.sender, _knftContract, tokenId);
    }

    /**
     * @notice Internal function to get a user's total voting power, including staked KNFTs.
     *         This is a placeholder for a more complex calculation based on KNFT properties,
     *         reputation, and potentially native token holdings.
     * @param voter The address of the voter.
     * @return The calculated voting power.
     */
    function getVotingPower(address voter) public view returns (uint256) {
        uint256 baseVotingPower = 1; // Everyone gets a base vote
        // Add power from staked KNFTs. Example: 1 KNFT = 5 additional votes.
        // This is simplified; KNFTs could have different weights based on rarity, content, etc.
        uint256 knftBonus = 0;
        if (knftContractAddress != address(0)) {
            knftBonus = stakedKNFTs[voter][knftContractAddress].length * 5;
        }
        
        // Could also integrate researcher reputation here if the voter is a researcher:
        // uint256 reputationBonus = researchers[voter].approved ? (researchers[voter].reputation / 100) : 0;
        
        return baseVotingPower + knftBonus; // + reputationBonus
    }


    // --- VII. Reputation & Rewards ---

    /**
     * @notice Internal or Governor-callable function to update a researcher's reputation.
     *         Called automatically upon proposal completion, failure, or cancellation.
     * @param proposalId The ID of the proposal.
     * @param success True if the project was successful, false if it failed or was cancelled.
     */
    function updateReputationBasedOnOutcome(uint256 proposalId, bool success) internal {
        ResearchProposal storage proposal = proposals[proposalId];
        Researcher storage researcher = researchers[proposal.researcher];
        
        if (success) {
            // Reward reputation based on funding size
            researcher.reputation += (proposal.fundingRequested / 1 ether) * 10; // Example: 10 reputation per ETH funded successfully
            // Add bonus for AI score or community sentiment in a more complex system
        } else {
            // Penalize reputation, possibly more severely for early failure
            uint256 penalty = (proposal.fundingRequested / 1 ether) * 5; // Example: 5 reputation per ETH for failure
            if (researcher.reputation > penalty) {
                researcher.reputation -= penalty;
            } else {
                researcher.reputation = 0; // Cannot go below zero
            }
        }
        emit ReputationUpdated(proposal.researcher, researcher.reputation);
    }

    /**
     * @notice Allows curators to claim their accumulated rewards for successful reviews.
     *         Only approved curators can call this.
     */
    function claimCuratorRewards() public onlyCurator {
        Curator storage curator = curators[msg.sender];
        require(curator.earnedRewards > 0, "No rewards to claim");

        uint256 amount = curator.earnedRewards;
        curator.earnedRewards = 0; // Reset
        
        payable(msg.sender).transfer(amount);
        emit CuratorRewardClaimed(msg.sender, amount);
    }

    /**
     * @notice Allows voters to claim rewards for accurately voting on successfully completed proposals.
     *         Voters who voted 'Yes' on approved proposals that eventually `Completed`, and 'No' on proposals that eventually `Failed`/`Rejected`,
     *         are considered accurate. Each voter can only claim rewards for a specific proposal once.
     * @param proposalIds An array of proposal IDs for which the voter wishes to claim rewards.
     */
    function claimVoterRewards(uint256[] calldata proposalIds) public {
        uint256 totalReward = 0;
        for (uint i = 0; i < proposalIds.length; i++) {
            uint256 proposalId = proposalIds[i];
            ResearchProposal storage proposal = proposals[proposalId];

            // Check if voter participated and if the proposal is in a final state (Completed or Failed/Rejected)
            // and if they haven't claimed for this specific proposal before (by checking `proposal.voters[msg.sender]`)
            if (proposal.voters[msg.sender] && 
                (proposal.status == ProposalStatus.Completed || 
                 proposal.status == ProposalStatus.Failed ||
                 proposal.status == ProposalStatus.Rejected)) {
                
                bool votedYes = proposal.votedYes[msg.sender];
                bool proposalSucceeded = (proposal.status == ProposalStatus.Completed);
                
                // Reward if vote matched the final outcome
                if ((votedYes && proposalSucceeded) || (!votedYes && !proposalSucceeded)) {
                    uint256 rewardPerProposal = (proposal.fundingRequested * voterRewardBps) / 10000;
                    totalReward += rewardPerProposal;
                    // Mark this specific vote/claim as processed to prevent double claims
                    delete proposal.voters[msg.sender]; 
                    delete proposal.votedYes[msg.sender];
                }
            }
        }

        require(totalReward > 0, "No rewards to claim for the provided proposals, or already claimed.");
        require(address(this).balance >= totalReward, "Insufficient contract balance for voter rewards");

        payable(msg.sender).transfer(totalReward);
        emit VoterRewardClaimed(msg.sender, totalReward);
    }


    // --- VIII. Decentralized Parameter Governance ---

    /**
     * @notice Allows the governor to propose a change to a system parameter.
     *         The change must be approved by community vote before execution.
     * @param description A description of the proposed change.
     * @param encodedCallData The encoded function call (function selector and arguments)
     *                        to execute if the proposal passes. Must target `address(this)`.
     *                        Example: `abi.encodeWithSelector(this.setProposalFee.selector, 0.1 ether)`
     */
    function proposeParameterChange(string calldata description, bytes calldata encodedCallData) public onlyGovernor {
        uint256 id = nextParameterChangeId++;
        parameterChangeProposals[id] = ParameterChangeProposal({
            id: id,
            proposer: msg.sender,
            description: description,
            encodedCallData: encodedCallData,
            proposedAt: block.timestamp,
            votingEndsAt: block.timestamp + votingPeriod, // Use same voting period as proposals
            yesVotes: 0,
            noVotes: 0,
            status: ParameterChangeStatus.PendingVote
        });
        emit ParameterChangeProposed(id, msg.sender, description);
    }

    /**
     * @notice Allows any user to vote on a proposed parameter change.
     *         Voting power (`getVotingPower`) is applied here.
     * @param changeId The ID of the parameter change proposal.
     * @param voteYes True for a 'Yes' vote, false for a 'No' vote.
     */
    function voteOnParameterChange(uint256 changeId, bool voteYes) public {
        ParameterChangeProposal storage pcp = parameterChangeProposals[changeId];
        require(pcp.status == ParameterChangeStatus.PendingVote, "Parameter change not in voting phase");
        require(block.timestamp <= pcp.votingEndsAt, "Voting period has ended");
        require(!pcp.voters[msg.sender], "Already voted on this parameter change");

        pcp.voters[msg.sender] = true;
        uint256 power = getVotingPower(msg.sender); // Use dynamic voting power
        if (voteYes) {
            pcp.yesVotes += power;
        } else {
            pcp.noVotes += power;
        }
        emit ParameterChangeVoted(changeId, msg.sender, voteYes);
    }

    /**
     * @notice Allows the governor to execute an approved parameter change proposal.
     *         Can be called by anyone after the voting period ends and if approved.
     * @param changeId The ID of the parameter change proposal.
     */
    function executeParameterChange(uint256 changeId) public {
        ParameterChangeProposal storage pcp = parameterChangeProposals[changeId];
        require(pcp.status == ParameterChangeStatus.PendingVote, "Parameter change not in voting phase");
        require(block.timestamp > pcp.votingEndsAt, "Voting period has not ended yet");

        // Simple majority approval based on voting power
        if (pcp.yesVotes > pcp.noVotes) {
            pcp.status = ParameterChangeStatus.Approved;
            // Execute the encoded call data against this contract itself
            (bool success, ) = address(this).call(pcp.encodedCallData);
            require(success, "Parameter change execution failed");
            pcp.status = ParameterChangeStatus.Executed;
            emit ParameterChangeExecuted(changeId);
        } else {
            pcp.status = ParameterChangeStatus.Rejected;
            // No event for rejected execution as it's implicit from status update
        }
    }

    // --- IX. View Functions ---

    /**
     * @notice Retrieves details of a specific research proposal.
     * @param proposalId The ID of the proposal.
     * @return A tuple containing proposal details.
     */
    function getResearchProposal(uint256 proposalId) public view returns (
        uint256 id,
        address researcher,
        string memory title,
        string memory description,
        uint256 fundingRequested,
        uint256 fundingGranted,
        uint256 submittedAt,
        uint256 votingEndsAt,
        uint256 aiScore,
        uint256 yesVotes,
        uint256 noVotes,
        ProposalStatus status,
        Milestone[] memory milestones,
        uint256 currentMilestoneIndex
    ) {
        ResearchProposal storage p = proposals[proposalId];
        Milestone[] memory _milestones = new Milestone[](p.milestones.length);
        for(uint i=0; i < p.milestones.length; i++) {
            _milestones[i] = p.milestones[i];
        }

        return (
            p.id,
            p.researcher,
            p.title,
            p.description,
            p.fundingRequested,
            p.fundingGranted,
            p.submittedAt,
            p.votingEndsAt,
            p.aiScore,
            p.yesVotes,
            p.noVotes,
            p.status,
            _milestones,
            p.currentMilestoneIndex
        );
    }
    
    /**
     * @notice Retrieves a researcher's details.
     * @param researcherAddress The address of the researcher.
     * @return A tuple containing researcher details.
     */
    function getResearcher(address researcherAddress) public view returns (
        address wallet, string memory name, uint256 registeredAt, bool approved, uint256 reputation
    ) {
        Researcher storage r = researchers[researcherAddress];
        return (r.wallet, r.name, r.registeredAt, r.approved, r.reputation);
    }

    /**
     * @notice Retrieves a curator's details.
     * @param curatorAddress The address of the curator.
     * @return A tuple containing curator details.
     */
    function getCurator(address curatorAddress) public view returns (
        address wallet, string memory name, uint256 registeredAt, bool approved, uint256 totalReviews, uint256 successfulReviews, uint256 earnedRewards
    ) {
        Curator storage c = curators[curatorAddress];
        return (c.wallet, c.name, c.registeredAt, c.approved, c.totalReviews, c.successfulReviews, c.earnedRewards);
    }
    
    /**
     * @notice Retrieves details of a specific parameter change proposal.
     * @param changeId The ID of the parameter change proposal.
     * @return A tuple containing parameter change proposal details.
     */
    function getParameterChangeProposal(uint256 changeId) public view returns (
        uint256 id,
        address proposer,
        string memory description,
        bytes memory encodedCallData,
        uint256 proposedAt,
        uint256 votingEndsAt,
        uint256 yesVotes,
        uint256 noVotes,
        ParameterChangeStatus status
    ) {
        ParameterChangeProposal storage pcp = parameterChangeProposals[changeId];
        return (
            pcp.id,
            pcp.proposer,
            pcp.description,
            pcp.encodedCallData,
            pcp.proposedAt,
            pcp.votingEndsAt,
            pcp.yesVotes,
            pcp.noVotes,
            pcp.status
        );
    }

    // --- X. Administrative & Configuration (Initial Setup) ---

    /**
     * @notice Allows the governor to set the AI Oracle contract address.
     *         This function is for initial setup; ideally, changes would occur via parameter change proposals.
     * @param _aiOracleAddress The address of the AI Oracle contract.
     */
    function setAIOracleAddress(address _aiOracleAddress) public onlyGovernor {
        require(_aiOracleAddress != address(0), "AI Oracle address cannot be zero");
        aiOracleAddress = _aiOracleAddress;
    }

    /**
     * @notice Allows the governor to set the KNFT contract address.
     *         This function is for initial setup; ideally, changes would occur via parameter change proposals.
     * @param _knftContractAddress The address of the KNFT ERC721 contract.
     */
    function setKNFTContractAddress(address _knftContractAddress) public onlyGovernor {
        require(_knftContractAddress != address(0), "KNFT contract address cannot be zero");
        knftContractAddress = _knftContractAddress;
    }
}
```