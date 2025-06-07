Okay, let's design a smart contract that serves as a Decentralized Autonomous Researcher (DAR) platform. This platform will allow users to propose research topics, crowdfund them, incentivize peer review, manage disputes, track researcher/reviewer reputation, and govern platform parameters using a native token and staking mechanism.

This concept incorporates:
*   **Decentralized Crowdfunding:** Funding research projects.
*   **Token-Curated Registries (TCR) elements:** Reviewer selection could be influenced by stake/reputation.
*   **Reputation System:** On-chain tracking of participant reliability.
*   **Staking:** Required for participation (research, review, governance).
*   **DAO Governance:** Parameter changes, dispute resolution, treasury management.
*   **Built-in Token:** Simplifies reward distribution and staking.

It's a complex system conceptually, integrating multiple distinct mechanics within a single contract (for this example's sake, though in practice, it might be split).

---

## Decentralized Autonomous Researcher (DAR) Platform Smart Contract

This contract implements a decentralized platform for funding, reviewing, and managing research or knowledge creation projects.

**Outline:**

1.  **Core Data Structures:** Structs for Proposals, Reviews, Governance Proposals, User Data.
2.  **Token Management:** Internal logic for a native `DARToken`.
3.  **Staking:** Mechanisms to stake and unstake `DARToken`.
4.  **Research Proposal Lifecycle:** Submission, Funding, Evaluation, Finalization.
5.  **Peer Review System:** Reviewer Registration, Assignment (simplified), Submission, Dispute handling.
6.  **Reputation System:** Tracking reputation for Researchers and Reviewers based on actions.
7.  **Reward Distribution:** Sending funded ETH/tokens and `DARToken` rewards.
8.  **Treasury Management:** Handling collected funds and reward distribution.
9.  **Decentralized Governance:** Proposing, voting on, and executing parameter changes and treasury withdrawals.
10. **Access Control & Pausability:** Modifiers for roles and emergency stop.
11. **View Functions:** Retrieving state information.

**Function Summary:**

*   **Token & Staking:**
    *   `stakeDAR(amount)`: Stake DAR tokens to participate.
    *   `unstakeDAR(amount)`: Unstake DAR tokens after lockup.
    *   `getUserStake(user)`: Get user's staked amount.
    *   `getTotalStaked()`: Get total staked amount in the system.
    *   `balanceOf(account)`: Get DAR token balance of an account.
    *   `transfer(recipient, amount)`: Transfer DAR tokens (internal/restricted). *Technically internal, but exposed for certain actions.*
    *   `mintInitialSupply(account, amount)`: Mint initial supply (Owner only).
    *   `burn(amount)`: Burn DAR tokens (utility, e.g., slashing).

*   **Research Proposals:**
    *   `submitResearchProposal(title, ipfsHash, fundingGoalETH, duration)`: Submit a new proposal.
    *   `fundResearchProposal(proposalId)`: Contribute ETH to fund a proposal. (Payable)
    *   `claimFundingRefund(proposalId)`: Claim refund if proposal fails to get funded.
    *   `finalizeProposalEvaluation(proposalId)`: Trigger final evaluation after review period. (Could be external keeper/DAO call)
    *   `distributeRewards(proposalId)`: Distribute rewards after successful evaluation. (Triggered internally or externally after finalization)
    *   `getProposalDetails(proposalId)`: Get details of a specific proposal.
    *   `listProposalsByStatus(status)`: List proposals filtered by status.

*   **Review System:**
    *   `registerAsReviewer()`: Register as a potential reviewer (requires stake).
    *   `submitReview(proposalId, rating, reviewIpfsHash)`: Submit a review for an assigned proposal.
    *   `disputeReview(proposalId, reviewIndex, reasonIpfsHash)`: Dispute a specific review.
    *   `settleDisputeOutcome(proposalId, disputeIndex, outcome)`: Settle a review dispute (Governance/Arbiter role).
    *   `getReviewDetails(proposalId, reviewIndex)`: Get details of a specific review.
    *   `getEligibleReviewers()`: Get list of users eligible to be reviewers.

*   **Reputation System:**
    *   `getResearcherReputation(user)`: Get reputation score of a researcher.
    *   `getReviewerReputation(user)`: Get reputation score of a reviewer.

*   **Governance:**
    *   `createParameterProposal(paramName, newValue)`: Create a proposal to change a system parameter.
    *   `voteOnGovernanceProposal(proposalId, support)`: Vote on a governance proposal.
    *   `executeGovernanceProposal(proposalId)`: Execute a passed governance proposal.
    *   `withdrawFromTreasury(recipient, amount)`: Withdraw funds from the treasury (Governance action).
    *   `getGovernanceProposalDetails(proposalId)`: Get details of a governance proposal.

*   **Utility & Admin:**
    *   `pauseContract()`: Pause the contract in case of emergency. (Owner/Governance)
    *   `unpauseContract()`: Unpause the contract. (Owner/Governance)
    *   `getMinStakeRequirement()`: Get current minimum stake for participation.
    *   `getTreasuryBalance()`: Get the contract's ETH balance.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DecentralizedAutonomousResearcher (DAR) Platform
 * @dev This contract implements a decentralized platform for funding, reviewing,
 * and managing research projects using a native token, staking, reputation,
 * and basic governance.
 *
 * Outline:
 * 1. Core Data Structures: Structs for Proposals, Reviews, Governance Proposals, User Data.
 * 2. Token Management: Internal logic for a native `DARToken`.
 * 3. Staking: Mechanisms to stake and unstake `DARToken`.
 * 4. Research Proposal Lifecycle: Submission, Funding, Evaluation, Finalization.
 * 5. Peer Review System: Reviewer Registration, Assignment (simplified), Submission, Dispute handling.
 * 6. Reputation System: Tracking reputation for Researchers and Reviewers based on actions.
 * 7. Reward Distribution: Sending funded ETH/tokens and `DARToken` rewards.
 * 8. Treasury Management: Handling collected funds and reward distribution.
 * 9. Decentralized Governance: Proposing, voting on, and executing parameter changes and treasury withdrawals.
 * 10. Access Control & Pausability: Modifiers for roles and emergency stop.
 * 11. View Functions: Retrieving state information.
 *
 * Function Summary:
 * - Token & Staking: stakeDAR, unstakeDAR, getUserStake, getTotalStaked, balanceOf, transfer, mintInitialSupply, burn
 * - Research Proposals: submitResearchProposal, fundResearchProposal, claimFundingRefund, finalizeProposalEvaluation, distributeRewards, getProposalDetails, listProposalsByStatus
 * - Review System: registerAsReviewer, submitReview, disputeReview, settleDisputeOutcome, getReviewDetails, getEligibleReviewers
 * - Reputation System: getResearcherReputation, getReviewerReputation
 * - Governance: createParameterProposal, voteOnGovernanceProposal, executeGovernanceProposal, withdrawFromTreasury, getGovernanceProposalDetails
 * - Utility & Admin: pauseContract, unpauseContract, getMinStakeRequirement, getTreasuryBalance
 */
contract DecentralizedAutonomousResearcher {

    // --- State Variables ---

    // Token (Internal ERC-20 like)
    string public constant name = "DAR Token";
    string public constant symbol = "DAR";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    // Staking
    mapping(address => uint256) public stakedBalances;
    uint256 public totalStaked;
    uint256 public stakingLockupPeriod; // Time in seconds
    mapping(address => uint256) public lastUnstakeRequestTime; // Timestamp of unstake initiation

    // Proposals
    struct Proposal {
        uint256 id;
        address researcher;
        string title;
        string ipfsHash; // Hash of the research content/proposal
        uint256 fundingGoalETH; // Required ETH for the proposal to proceed
        uint256 fundedAmountETH; // ETH collected so far
        uint256 submissionTime;
        uint256 fundingEndTime; // Timestamp when funding phase ends
        uint256 reviewEndTime; // Timestamp when review phase ends
        ProposalStatus status;
        uint256[] reviewIds; // Indexes of reviews associated with this proposal
        bool fundingClaimed; // Whether researcher claimed funded ETH
        bool rewardsDistributed; // Whether DAR rewards were distributed
    }

    enum ProposalStatus {
        FundingOpen,
        FundingFailed,
        FundingSuccessful,
        ReviewOpen,
        ReviewComplete,
        Approved,
        Rejected,
        Disputed, // Specific reviews disputed
        Finalized // Outcome determined after review/dispute
    }

    uint256 public nextProposalId = 0;
    mapping(uint256 => Proposal) public proposals;

    // Reviews
    struct Review {
        uint256 id;
        uint256 proposalId;
        address reviewer;
        uint256 submissionTime;
        uint8 rating; // e.g., 1-5
        string reviewIpfsHash; // Hash of the review content
        ReviewStatus status;
        uint256 disputeId; // Link to dispute if exists
    }

    enum ReviewStatus {
        Submitted,
        Accepted, // Review accepted by researcher/system
        Rejected, // Review rejected by researcher/system (less common)
        Disputed // Review is under dispute
    }

    uint256 public nextReviewId = 0;
    mapping(uint256 => Review) public reviews;

    // Review Disputes
    struct ReviewDispute {
        uint256 id;
        uint256 proposalId;
        uint256 reviewIndex; // Index of the review being disputed within proposal.reviewIds array
        address disputer; // Typically the researcher
        string reasonIpfsHash; // Hash of the dispute reason
        DisputeStatus status;
        uint256 settlementGovernanceProposalId; // Link to the governance proposal for settlement
    }

    enum DisputeStatus {
        Open,
        UnderGovernanceReview,
        SettledAcceptedReview, // Dispute failed, review stands
        SettledRejectedReview // Dispute succeeded, review is dismissed/penalized
    }

    uint256 public nextDisputeId = 0;
    mapping(uint256 => ReviewDispute) public reviewDisputes;

    // Reputation
    mapping(address => uint256) public researcherReputation; // Score based on approved proposals
    mapping(address => uint256) public reviewerReputation; // Score based on accepted reviews

    // Governance
    struct GovernanceProposal {
        uint256 id;
        address proposer;
        GovernanceProposalType proposalType;
        bytes data; // Encoded function call data for execution
        string description; // Short description/link to proposal details
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted;
        GovernanceProposalStatus status;
        // Fields for parameter changes
        string paramName;
        uint256 newValue;
        address targetAddress; // For withdrawal or other calls
        uint256 callValue; // For withdrawal or other calls
    }

    enum GovernanceProposalType {
        ParameterChange,
        TreasuryWithdrawal,
        SettleReviewDispute, // Outcome decided by governance vote
        CustomCall // General purpose call (requires careful use)
    }

    enum GovernanceProposalStatus {
        VotingOpen,
        VotingClosed, // Not yet executed or failed quorum/majority
        Passed, // Met quorum and majority
        Executed,
        Failed,
        Canceled
    }

    uint256 public nextGovernanceProposalId = 0;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Platform Parameters (Governable)
    uint256 public minStakeRequirement;
    uint256 public proposalFundingPeriod; // Duration for funding phase
    uint256 public proposalReviewPeriod; // Duration for review phase
    uint256 public reviewSubmissionPeriod; // Duration reviewers have to submit
    uint256 public researcherRewardRate; // Percentage of funded ETH or fixed DAR tokens
    uint256 public reviewerRewardRate; // Fixed DAR tokens per accepted review
    uint256 public reputationBoostApprovedProposal; // Points gained by researcher
    uint256 public reputationPenaltyRejectedProposal; // Points lost by researcher
    uint256 public reputationBoostAcceptedReview; // Points gained by reviewer
    uint256 public reputationPenaltyDisputedReview; // Points lost by reviewer if dispute succeeds
    uint256 public governanceVotingPeriod;
    uint256 public governanceQuorumPercentage; // e.g., 4% of total staked needed to pass
    uint256 public governanceMajorityPercentage; // e.g., 51% of votes cast needed to pass

    // Admin & Pausability
    address public owner; // Initial owner, potentially transferable/governed later
    bool public paused = false;

    // --- Events ---

    event TokensMinted(address indexed account, uint256 amount);
    event TokensBurned(address indexed account, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event UnstakeRequested(address indexed user, uint256 amount, uint256 unlockTime);
    event Unstaked(address indexed user, uint256 amount);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed researcher, uint256 fundingGoalETH);
    event ProposalFunded(uint256 indexed proposalId, address indexed funder, uint256 amountETH, uint256 totalFunded);
    event FundingRefunded(uint256 indexed proposalId, address indexed funder, uint256 amountETH);
    event ProposalStatusUpdated(uint256 indexed proposalId, ProposalStatus newStatus);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus finalOutcome);
    event RewardsDistributed(uint256 indexed proposalId, uint256 researcherRewardDAR, uint256 totalReviewerRewardDAR);

    event ReviewerRegistered(address indexed reviewer);
    event ReviewSubmitted(uint256 indexed reviewId, uint256 indexed proposalId, address indexed reviewer, uint8 rating);
    event ReviewStatusUpdated(uint256 indexed reviewId, ReviewStatus newStatus);
    event ReviewDisputed(uint256 indexed disputeId, uint256 indexed proposalId, uint256 indexed reviewIndex, address indexed disputer);
    event DisputeSettled(uint256 indexed disputeId, DisputeStatus outcome);

    event ReputationUpdated(address indexed user, uint256 newResearcherReputation, uint256 newReviewerReputation);

    event GovernanceProposalCreated(uint256 indexed proposalId, address indexed proposer, GovernanceProposalType proposalType);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPower);
    event GovernanceProposalStatusUpdated(uint256 indexed proposalId, GovernanceProposalStatus newStatus);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);

    event Paused(address account);
    event Unpaused(address account);
    event ParameterChanged(string paramName, uint256 newValue);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "DAR: Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "DAR: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "DAR: Contract is not paused");
        _;
    }

    modifier onlyStaker() {
        require(stakedBalances[msg.sender] > 0, "DAR: Requires stake");
        _;
    }

    modifier onlyResearcher(uint256 proposalId) {
         require(proposals[proposalId].researcher == msg.sender, "DAR: Not proposal researcher");
         _;
    }

    modifier onlyGovExecutor(uint256 proposalId) {
        require(governanceProposals[proposalId].status == GovernanceProposalStatus.Passed, "DAR: Proposal not passed");
        // Could add more complex checks, like a timelock
        _;
    }

    // --- Constructor ---

    constructor(
        uint256 _minStakeRequirement,
        uint256 _proposalFundingPeriod,
        uint256 _proposalReviewPeriod,
        uint256 _reviewSubmissionPeriod,
        uint256 _researcherRewardRate,
        uint256 _reviewerRewardRate,
        uint256 _reputationBoostApprovedProposal,
        uint256 _reputationPenaltyRejectedProposal,
        uint256 _reputationBoostAcceptedReview,
        uint256 _reputationPenaltyDisputedReview,
        uint256 _governanceVotingPeriod,
        uint256 _governanceQuorumPercentage,
        uint256 _governanceMajorityPercentage,
        uint256 _stakingLockupPeriod
    ) {
        owner = msg.sender;

        minStakeRequirement = _minStakeRequirement;
        proposalFundingPeriod = _proposalFundingPeriod;
        proposalReviewPeriod = _proposalReviewPeriod;
        reviewSubmissionPeriod = _reviewSubmissionPeriod;
        researcherRewardRate = _researcherRewardRate; // e.g., 10000 for 100% or fixed DAR
        reviewerRewardRate = _reviewerRewardRate;   // fixed DAR
        reputationBoostApprovedProposal = _reputationBoostApprovedProposal;
        reputationPenaltyRejectedProposal = _reputationPenaltyRejectedProposal;
        reputationBoostAcceptedReview = _reputationBoostAcceptedReview;
        reputationPenaltyDisputedReview = _reputationPenaltyDisputedReview;
        governanceVotingPeriod = _governanceVotingPeriod;
        governanceQuorumPercentage = _governanceQuorumPercentage; // percentage * 100
        governanceMajorityPercentage = _governanceMajorityPercentage; // percentage * 100
        stakingLockupPeriod = _stakingLockupPeriod;

        // Initial minting - example: mint to deployer or specific accounts
        // _mint(msg.sender, 1000000 * (10**decimals));
    }

    // --- Internal Token Logic (Simplified ERC-20) ---

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) internal returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "DAR: transfer from the zero address");
        require(recipient != address(0), "DAR: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "DAR: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        // Consider adding Transfer event if needed for external compatibility
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "DAR: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit TokensMinted(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "DAR: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "DAR: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit TokensBurned(account, amount);
    }

    // --- Staking ---

    /**
     * @dev Allows users to stake DAR tokens to participate. Requires sufficient balance.
     * @param amount The amount of DAR tokens to stake.
     */
    function stakeDAR(uint256 amount) public whenNotPaused {
        require(amount > 0, "DAR: Stake amount must be > 0");
        require(_balances[msg.sender] >= amount, "DAR: Insufficient DAR balance");
        require(stakedBalances[msg.sender] + amount >= minStakeRequirement, "DAR: Minimum stake requirement not met");

        _transfer(msg.sender, address(this), amount); // Transfer tokens to the contract
        stakedBalances[msg.sender] += amount;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    /**
     * @dev Initiates the unstaking process. Tokens are locked up for a period.
     * @param amount The amount of DAR tokens to unstake.
     */
    function unstakeDAR(uint256 amount) public whenNotPaused onlyStaker {
        require(amount > 0, "DAR: Unstake amount must be > 0");
        require(stakedBalances[msg.sender] >= amount, "DAR: Insufficient staked balance");

        uint256 newStakedBalance = stakedBalances[msg.sender] - amount;
        require(newStakedBalance == 0 || newStakedBalance >= minStakeRequirement, "DAR: Remaining stake must meet minimum requirement or be zero");

        stakedBalances[msg.sender] = newStakedBalance;
        totalStaked -= amount;
        lastUnstakeRequestTime[msg.sender] = block.timestamp;

        emit UnstakeRequested(msg.sender, amount, block.timestamp + stakingLockupPeriod);
    }

     /**
     * @dev Completes the unstaking process after the lockup period.
     * @param amount The amount of DAR tokens to withdraw. Must match requested unstake amount.
     */
    function claimUnstakedTokens(uint256 amount) public whenNotPaused {
        require(lastUnstakeRequestTime[msg.sender] > 0, "DAR: No pending unstake request");
        // This is a simplification. A real system would track WHICH unstake request is pending.
        // A proper system would track pending unstake amounts per user.
        // For simplicity, assuming the user is claiming the full amount they requested last.
        // This also assumes only one unstake request can be pending.
        // In a real contract, you'd need a mapping like `pendingUnstakes[user] => amount`.
        // Let's assume for this example, the user is claiming the amount that was reduced from `stakedBalances`.
        // The tokens are already *out* of `stakedBalances`, but they are still in the contract's balance.
        // This function would transfer the actual tokens *out* of the contract to the user.
        // The logic below assumes `amount` is the amount the user *wants* to transfer out,
        // and we check if they requested at least that much recently and if the lockup is over.

        // A more robust system tracks the *amount* requested to unstake specifically.
        // We don't have that state. Let's adjust the `unstakeDAR` logic conceptually.
        // `unstakeDAR` should *not* decrease stakedBalances immediately, but move it to a `pendingUnstake` mapping.
        // Then `claimUnstakedTokens` transfers from contract balance and updates `pendingUnstake`.

        // *** REVISED STAKING/UNSTAKING LOGIC FOR SIMPLICITY ***
        // User calls stakeDAR (moves tokens to contract, updates stakedBalances)
        // User calls unstakeDAR (decreases stakedBalances, records lastUnstakeRequestTime, tokens are now *claimable* after lockup)
        // User calls claimUnstakedTokens (moves tokens from contract back to user, if lockup passed)

        require(block.timestamp >= lastUnstakeRequestTime[msg.sender] + stakingLockupPeriod, "DAR: Staking lockup period not over");

        // We don't track the exact amount requested, so let's assume the user can claim *any* amount
        // up to their original stake minus their *current* stake, provided the *last* unstake request time has passed its lockup.
        // This is still a simplification. A real system needs more state.
        // Let's assume a mapping `claimableUnstaked[user] => amount` which is populated by `unstakeDAR`.

        // For this example, we will assume a single pending unstake amount per user.
        // Let's add a state variable for this:
        // mapping(address => uint256) public pendingUnstakeAmount; // Add this state variable

        // Re-writing unstakeDAR slightly:
        // function unstakeDAR(uint256 amount) public whenNotPaused onlyStaker { ... }
        // ... stakedBalances[msg.sender] -= amount;
        // ... pendingUnstakeAmount[msg.sender] += amount; // Add to pending
        // ... lastUnstakeRequestTime[msg.sender] = block.timestamp; // Record time
        // ... emit UnstakeRequested(...);

        // Re-writing claimUnstakedTokens:
        // function claimUnstakedTokens() public whenNotPaused {
        //     uint256 amount = pendingUnstakeAmount[msg.sender];
        //     require(amount > 0, "DAR: No pending unstake amount");
        //     require(block.timestamp >= lastUnstakeRequestTime[msg.sender] + stakingLockupPeriod, "DAR: Staking lockup period not over");
        //     pendingUnstakeAmount[msg.sender] = 0; // Clear pending amount
        //     _transfer(address(this), msg.sender, amount); // Transfer tokens out
        //     emit Unstaked(msg.sender, amount);
        // }
        // Let's use this simplified pending amount logic for the implementation.

        // Using the simplified `pendingUnstakeAmount` mapping:
        // requires adding `mapping(address => uint256) public pendingUnstakeAmount;` to state variables.
        // And modifying `unstakeDAR` to populate it.

        uint256 amountClaimable = pendingUnstakeAmount[msg.sender]; // Requires `pendingUnstakeAmount` mapping
        require(amountClaimable > 0, "DAR: No pending unstake amount");
        require(block.timestamp >= lastUnstakeRequestTime[msg.sender] + stakingLockupPeriod, "DAR: Staking lockup period not over");

        pendingUnstakeAmount[msg.sender] = 0; // Reset pending amount
        _transfer(address(this), msg.sender, amountClaimable); // Transfer tokens from contract to user

        emit Unstaked(msg.sender, amountClaimable);
    }

     // Requires adding `mapping(address => uint256) public pendingUnstakeAmount;` to state variables.
     // Modify unstakeDAR slightly:
     /*
     function unstakeDAR(uint256 amount) public whenNotPaused onlyStaker {
        require(amount > 0, "DAR: Unstake amount must be > 0");
        require(stakedBalances[msg.sender] >= amount, "DAR: Insufficient staked balance");

        uint256 newStakedBalance = stakedBalances[msg.sender] - amount;
        require(newStakedBalance == 0 || newStakedBalance >= minStakeRequirement, "DAR: Remaining stake must meet minimum requirement or be zero");

        stakedBalances[msg.sender] = newStakedBalance;
        totalStaked -= amount;
        pendingUnstakeAmount[msg.sender] += amount; // Add to pending
        lastUnstakeRequestTime[msg.sender] = block.timestamp; // Record time

        emit UnstakeRequested(msg.sender, amount, block.timestamp + stakingLockupPeriod);
     }
     */
     // Adding the `pendingUnstakeAmount` and updating `unstakeDAR` and `claimUnstakedTokens` logic...


    mapping(address => uint256) public pendingUnstakeAmount; // Added state variable

    /**
     * @dev Allows users to stake DAR tokens to participate. Requires sufficient balance.
     * @param amount The amount of DAR tokens to stake.
     */
    // Function 5: stakeDAR (Already listed in summary, adding body)
    // Implemented above.

    /**
     * @dev Initiates the unstaking process. Tokens are moved to a pending state locked up for a period.
     * @param amount The amount of DAR tokens to unstake.
     */
    // Function 6: unstakeDAR (Already listed in summary, adding body)
    function unstakeDAR(uint256 amount) public whenNotPaused onlyStaker {
        require(amount > 0, "DAR: Unstake amount must be > 0");
        require(stakedBalances[msg.sender] >= amount, "DAR: Insufficient staked balance");

        uint256 newStakedBalance = stakedBalances[msg.sender] - amount;
        require(newStakedBalance == 0 || newStakedBalance >= minStakeRequirement, "DAR: Remaining stake must meet minimum requirement or be zero");

        stakedBalances[msg.sender] = newStakedBalance;
        totalStaked -= amount;
        pendingUnstakeAmount[msg.sender] += amount; // Add to pending
        lastUnstakeRequestTime[msg.sender] = block.timestamp; // Record time

        emit UnstakeRequested(msg.sender, amount, block.timestamp + stakingLockupPeriod);
    }

    /**
     * @dev Completes the unstaking process after the lockup period. Transfers tokens from contract to user.
     */
    // Function: claimUnstakedTokens (Added this utility function)
    function claimUnstakedTokens() public whenNotPaused {
        uint256 amountClaimable = pendingUnstakeAmount[msg.sender];
        require(amountClaimable > 0, "DAR: No pending unstake amount");
        require(block.timestamp >= lastUnstakeRequestTime[msg.sender] + stakingLockupPeriod, "DAR: Staking lockup period not over");

        pendingUnstakeAmount[msg.sender] = 0; // Reset pending amount
        _transfer(address(this), msg.sender, amountClaimable); // Transfer tokens from contract to user

        emit Unstaked(msg.sender, amountClaimable);
    }


    /**
     * @dev Get user's currently staked amount.
     * @param user The address to query.
     * @return The staked amount.
     */
    // Function 7: getUserStake (Already listed in summary)
    function getUserStake(address user) public view returns (uint256) {
        return stakedBalances[user];
    }

    /**
     * @dev Get the total amount of DAR tokens staked in the contract.
     * @return The total staked amount.
     */
    // Function 8: getTotalStaked (Already listed in summary)
    function getTotalStaked() public view returns (uint256) {
        return totalStaked;
    }

    /**
     * @dev Get DAR token balance of an account. (Standard ERC-20 view)
     * @param account The address to query.
     * @return The balance.
     */
    // Function 9: balanceOf (Already listed in summary)
    // Implemented above as public view.

    /**
     * @dev Internal transfer function (simplified ERC-20). Exposed for certain actions.
     * @param recipient The address to transfer to.
     * @param amount The amount to transfer.
     * @return bool success.
     */
    // Function 10: transfer (Internal, not directly callable by users in this design, but part of summary)
    // Marked internal above. Example usage would be `_transfer(address(this), recipient, amount)` for rewards.

    /**
     * @dev Mint initial supply of DAR tokens. Callable only by owner.
     * @param account The account to mint to.
     * @param amount The amount to mint.
     */
    // Function 11: mintInitialSupply (Already listed in summary)
    function mintInitialSupply(address account, uint256 amount) public onlyOwner {
        require(_totalSupply == 0, "DAR: Initial supply already minted");
        _mint(account, amount);
    }

     /**
     * @dev Burn DAR tokens from caller's balance. (Utility/Slashing)
     * @param amount The amount to burn.
     */
    // Function 12: burn (Already listed in summary)
    function burn(uint256 amount) public whenNotPaused {
        _burn(msg.sender, amount);
    }


    // --- Research Proposals ---

    /**
     * @dev Allows a staked user to submit a research proposal.
     * @param title The title of the research proposal.
     * @param ipfsHash IPFS hash pointing to the proposal document.
     * @param fundingGoalETH The ETH funding required for this proposal.
     * @param duration The duration (in seconds) the proposal is open for funding.
     */
    // Function 13: submitResearchProposal (Already listed in summary)
    function submitResearchProposal(
        string memory title,
        string memory ipfsHash,
        uint256 fundingGoalETH,
        uint256 duration
    ) public whenNotPaused onlyStaker {
        uint256 proposalId = nextProposalId++;
        Proposal storage proposal = proposals[proposalId];

        proposal.id = proposalId;
        proposal.researcher = msg.sender;
        proposal.title = title;
        proposal.ipfsHash = ipfsHash;
        proposal.fundingGoalETH = fundingGoalETH;
        proposal.submissionTime = block.timestamp;
        proposal.fundingEndTime = block.timestamp + duration; // Use provided duration for funding
        proposal.status = ProposalStatus.FundingOpen;

        emit ProposalSubmitted(proposalId, msg.sender, fundingGoalETH);
    }

    /**
     * @dev Allows anyone to fund an open research proposal.
     * @param proposalId The ID of the proposal to fund.
     */
    // Function 14: fundResearchProposal (Already listed in summary, Payable)
    function fundResearchProposal(uint256 proposalId) public payable whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.FundingOpen, "DAR: Proposal not in funding phase");
        require(block.timestamp <= proposal.fundingEndTime, "DAR: Funding period has ended");
        require(msg.value > 0, "DAR: Funding amount must be > 0");

        proposal.fundedAmountETH += msg.value;

        emit ProposalFunded(proposalId, msg.sender, msg.value, proposal.fundedAmountETH);

        // Check if funding goal reached
        if (proposal.fundedAmountETH >= proposal.fundingGoalETH) {
            proposal.status = ProposalStatus.ReviewOpen;
            proposal.reviewEndTime = block.timestamp + proposalReviewPeriod; // Start review period
            // Note: Reviewers need to be assigned or self-select.
            // For simplicity, assuming reviewers *can* submit reviews once ReviewOpen.
            // A complex system would have explicit reviewer assignment.
            emit ProposalStatusUpdated(proposalId, ProposalStatus.ReviewOpen);
        }
    }

    /**
     * @dev Allows a funder to claim back their ETH if the proposal funding failed.
     * @param proposalId The ID of the proposal.
     */
    // Function 15: claimFundingRefund (Already listed in summary)
    function claimFundingRefund(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.FundingFailed, "DAR: Proposal funding did not fail");
        // Need to track individual funder contributions to refund.
        // This requires another mapping: `proposalContributions[proposalId][funderAddress] => amount`.
        // For simplicity here, we will skip tracking individual contributions for refund.
        // A real contract *must* track individual contributions to enable refunds.

        // This function is conceptually valid but requires the tracking mechanism.
        // require(proposalContributions[proposalId][msg.sender] > 0, "DAR: No contribution found from sender");
        // uint256 amount = proposalContributions[proposalId][msg.sender];
        // proposalContributions[proposalId][msg.sender] = 0;
        // (payable(msg.sender)).transfer(amount); // Send ETH refund
        // emit FundingRefunded(proposalId, msg.sender, amount);

        revert("DAR: Individual contribution tracking not implemented for refunds"); // Indicating missing logic
    }

     /**
     * @dev Triggers the final evaluation of a proposal after its review period ends.
     * Could be called by the researcher, a keeper, or via governance.
     * @param proposalId The ID of the proposal to finalize.
     */
    // Function 16: finalizeProposalEvaluation (Already listed in summary)
    function finalizeProposalEvaluation(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(
            proposal.status == ProposalStatus.ReviewOpen || proposal.status == ProposalStatus.Disputed,
            "DAR: Proposal not in review or disputed phase"
        );
        require(block.timestamp > proposal.reviewEndTime, "DAR: Review period not over");

        // Determine outcome based on reviews/disputes
        (bool approved, bool disputedReviewsSettled) = _evaluateOutcome(proposalId);

        if (!disputedReviewsSettled && proposal.status == ProposalStatus.Disputed) {
             // If there are unsettled disputes, cannot finalize yet.
             // This requires disputes to be settled via governance first.
             revert("DAR: Cannot finalize while reviews are under dispute");
        }

        if (approved) {
            proposal.status = ProposalStatus.Approved;
            _updateResearcherReputation(proposal.researcher, reputationBoostApprovedProposal);
        } else {
            proposal.status = ProposalStatus.Rejected;
            _updateResearcherReputation(proposal.researcher, reputationPenaltyRejectedProposal * (uint256(0) - int256(1))); // Subtract penalty
        }

        proposal.status = ProposalStatus.Finalized; // Move to a final state
        emit ProposalFinalized(proposalId, proposal.status);
        emit ProposalStatusUpdated(proposalId, proposal.status);

        // Rewards can now be distributed (either automatically or via distributeRewards call)
    }

    /**
     * @dev Distributes rewards (funded ETH to researcher, DAR to researcher/reviewers) for a finalized proposal.
     * @param proposalId The ID of the proposal.
     */
    // Function 17: distributeRewards (Already listed in summary)
    function distributeRewards(uint256 proposalId) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.Finalized, "DAR: Proposal not finalized");
        require(!proposal.fundingClaimed || !proposal.rewardsDistributed, "DAR: Rewards already distributed");

        // 1. Distribute Funded ETH to Researcher (if Approved)
        if (proposal.status == ProposalStatus.Approved && !proposal.fundingClaimed) {
            require(proposal.fundedAmountETH > 0, "DAR: No ETH funded for this proposal");
            (payable(proposal.researcher)).transfer(proposal.fundedAmountETH);
            proposal.fundedAmountETH = 0; // Mark as transferred
            proposal.fundingClaimed = true;
        }

        // 2. Distribute DAR Token Rewards (if not already distributed)
        if (!proposal.rewardsDistributed) {
            // Researcher Reward (Example: fixed amount or % of funded ETH value converted to DAR)
            // Using a fixed DAR reward for simplicity based on success
            uint256 researcherDAR = 0;
            if (proposal.status == ProposalStatus.Approved) {
                 researcherDAR = researcherRewardRate; // Assuming researcherRewardRate is fixed DAR amount
                 // Or calculate based on ETH funded: uint256 ethValueInDAR = getETHValueInDAR(proposal.fundedAmountETH); researcherDAR = (ethValueInDAR * researcherRewardRate) / 10000;
            }

            if (researcherDAR > 0) {
                _mint(proposal.researcher, researcherDAR); // Mint DAR tokens as reward
            }

            // Reviewer Rewards (fixed DAR per accepted review)
            uint256 totalReviewerDAR = 0;
            for (uint i = 0; i < proposal.reviewIds.length; i++) {
                Review storage review = reviews[proposal.reviewIds[i]];
                // Only reward for non-disputed/accepted reviews
                if (review.status == ReviewStatus.Submitted || review.status == ReviewStatus.Accepted) {
                    // A real system would need to mark reviews as 'Accepted' after evaluation
                    // For this example, let's reward for any review not in Dispute/Rejected status IF proposal was Approved
                    if (proposal.status == ProposalStatus.Approved && review.status != ReviewStatus.Disputed && review.status != ReviewStatus.Rejected) {
                         uint256 reviewerDAR = reviewerRewardRate; // Assuming fixed DAR amount
                         _mint(review.reviewer, reviewerDAR); // Mint DAR tokens as reward
                         totalReviewerDAR += reviewerDAR;
                         _updateReviewerReputation(review.reviewer, reputationBoostAcceptedReview); // Boost reputation for accepted reviews
                    } else if (proposal.status == ProposalStatus.Rejected && review.status != ReviewStatus.Disputed && review.status != ReviewStatus.Rejected) {
                         // Optional: Penalize reviewers of rejected proposals? Or only reward for approved?
                         // Sticking to rewarding for Approved proposals for simplicity.
                    }
                } else if (review.status == ReviewStatus.Disputed) {
                    // Reputation penalty handled in settleDisputeOutcome
                }
            }

            proposal.rewardsDistributed = true;
            emit RewardsDistributed(proposalId, researcherDAR, totalReviewerDAR);
        }
    }

    /**
     * @dev Internal helper to evaluate the proposal outcome based on reviews and dispute status.
     * @param proposalId The ID of the proposal.
     * @return (bool approved, bool disputedReviewsSettled) - approved indicates if majority reviews were positive, disputedReviewsSettled indicates if all linked disputes are resolved.
     */
    function _evaluateOutcome(uint256 proposalId) internal view returns (bool approved, bool disputedReviewsSettled) {
         Proposal storage proposal = proposals[proposalId];
         uint256 positiveReviews = 0;
         uint256 negativeReviews = 0;
         uint256 totalReviewed = 0;
         disputedReviewsSettled = true; // Assume settled until proven otherwise

         for (uint i = 0; i < proposal.reviewIds.length; i++) {
             Review storage review = reviews[proposal.reviewIds[i]];
             // Only consider reviews that are not currently disputed or rejected
             if (review.status == ReviewStatus.Submitted || review.status == ReviewStatus.Accepted) {
                 totalReviewed++;
                 if (review.rating >= 4) { // Example: Rating 4 or 5 is positive
                     positiveReviews++;
                 } else if (review.rating <= 2) { // Example: Rating 1 or 2 is negative
                     negativeReviews++;
                 }
                 // Rating 3 could be neutral - doesn't count towards positive/negative majority
             } else if (review.status == ReviewStatus.Disputed) {
                 // Check if the linked dispute is still open or under governance review
                 ReviewDispute storage dispute = reviewDisputes[review.disputeId];
                 if (dispute.status == DisputeStatus.Open || dispute.status == DisputeStatus.UnderGovernanceReview) {
                     disputedReviewsSettled = false;
                     // Don't count this review towards positive/negative until dispute settled
                 } else if (dispute.status == DisputeStatus.SettledRejectedReview) {
                    // Dispute succeeded, review is effectively dismissed, don't count it.
                 } else if (dispute.status == DisputeStatus.SettledAcceptedReview) {
                    // Dispute failed, review stands. Count it based on original rating.
                     totalReviewed++;
                     if (review.rating >= 4) { positiveReviews++; }
                     else if (review.rating <= 2) { negativeReviews++; }
                 }
             }
         }

         // Outcome determination logic:
         // Require a minimum number of reviews?
         // Majority of non-neutral, non-disputed reviews?
         // For simplicity: If total reviewed > 0, approved if positive reviews > negative reviews.
         // More complex: Use weighted average based on reviewer reputation.
         approved = (totalReviewed > 0) && (positiveReviews > negativeReviews);

         return (approved, disputedReviewsSettled);
    }

     /**
     * @dev Get details of a specific proposal.
     * @param proposalId The ID of the proposal.
     * @return Tuple containing proposal details.
     */
    // Function 18: getProposalDetails (Already listed in summary)
    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            uint256 id,
            address researcher,
            string memory title,
            string memory ipfsHash,
            uint256 fundingGoalETH,
            uint256 fundedAmountETH,
            uint256 submissionTime,
            uint256 fundingEndTime,
            uint256 reviewEndTime,
            ProposalStatus status,
            uint256[] memory reviewIds,
            bool fundingClaimed,
            bool rewardsDistributed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.id,
            proposal.researcher,
            proposal.title,
            proposal.ipfsHash,
            proposal.fundingGoalETH,
            proposal.fundedAmountETH,
            proposal.submissionTime,
            proposal.fundingEndTime,
            proposal.reviewEndTime,
            proposal.status,
            proposal.reviewIds,
            proposal.fundingClaimed,
            proposal.rewardsDistributed
        );
    }

    /**
     * @dev List proposals filtered by status. Note: This could be gas-intensive for many proposals.
     * In practice, dApps usually index this off-chain.
     * @param status The status to filter by.
     * @return Array of proposal IDs matching the status.
     */
    // Function 19: listProposalsByStatus (Already listed in summary)
     function listProposalsByStatus(ProposalStatus status) public view returns (uint256[] memory) {
        uint256[] memory filtered;
        uint256 count = 0;
        // First pass to count
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (proposals[i].status == status) {
                count++;
            }
        }

        filtered = new uint256[](count);
        uint256 current = 0;
        // Second pass to populate
        for (uint256 i = 0; i < nextProposalId; i++) {
            if (proposals[i].status == status) {
                filtered[current] = i;
                current++;
            }
        }
        return filtered;
    }


    // --- Review System ---

     /**
     * @dev Allows a staked user to register as a potential reviewer.
     */
    // Function 20: registerAsReviewer (Already listed in summary)
    function registerAsReviewer() public whenNotPaused onlyStaker {
        // Simple registration. A real system might have reviewer categories/expertise.
        // For simplicity, any staked user meeting minStakeRequirement can register.
        // We could add a mapping `isReviewer[address] => bool`.
        emit ReviewerRegistered(msg.sender);
    }

    /**
     * @dev Allows a registered reviewer to submit a review for a proposal in the review phase.
     * In a real system, reviewers might need to be assigned first.
     * @param proposalId The ID of the proposal being reviewed.
     * @param rating The rating (e.g., 1-5).
     * @param reviewIpfsHash IPFS hash pointing to the review document.
     */
    // Function 21: submitReview (Already listed in summary)
    function submitReview(
        uint256 proposalId,
        uint8 rating,
        string memory reviewIpfsHash
    ) public whenNotPaused onlyStaker {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.status == ProposalStatus.ReviewOpen || proposal.status == ProposalStatus.Disputed, "DAR: Proposal not open for review");
        require(block.timestamp <= proposal.reviewEndTime, "DAR: Review period has ended");
        // Require user is a registered reviewer (requires isReviewer mapping)
        // require(isReviewer[msg.sender], "DAR: Sender is not a registered reviewer");
         require(rating >= 1 && rating <= 5, "DAR: Rating must be between 1 and 5");

        uint256 reviewId = nextReviewId++;
        Review storage review = reviews[reviewId];

        review.id = reviewId;
        review.proposalId = proposalId;
        review.reviewer = msg.sender;
        review.submissionTime = block.timestamp;
        review.rating = rating;
        review.reviewIpfsHash = reviewIpfsHash;
        review.status = ReviewStatus.Submitted;

        proposal.reviewIds.push(reviewId);

        emit ReviewSubmitted(reviewId, proposalId, msg.sender, rating);
    }

    /**
     * @dev Allows the researcher of a proposal to dispute a specific submitted review.
     * Triggers a dispute resolution process (potentially via governance).
     * @param proposalId The ID of the proposal.
     * @param reviewIndex The index of the review within the proposal's reviewIds array.
     * @param reasonIpfsHash IPFS hash pointing to the dispute reason.
     */
    // Function 22: disputeReview (Already listed in summary)
    function disputeReview(uint256 proposalId, uint256 reviewIndex, string memory reasonIpfsHash) public whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.researcher == msg.sender, "DAR: Only researcher can dispute reviews");
        require(proposal.status == ProposalStatus.ReviewOpen || proposal.status == ProposalStatus.Disputed, "DAR: Proposal not in review/disputed phase");
        require(reviewIndex < proposal.reviewIds.length, "DAR: Invalid review index");

        uint256 reviewId = proposal.reviewIds[reviewIndex];
        Review storage review = reviews[reviewId];
        require(review.status == ReviewStatus.Submitted || review.status == ReviewStatus.Accepted, "DAR: Review not in a disputable status");

        review.status = ReviewStatus.Disputed; // Mark the review as disputed
        proposal.status = ProposalStatus.Disputed; // Mark the proposal as having disputes

        uint256 disputeId = nextDisputeId++;
        ReviewDispute storage dispute = reviewDisputes[disputeId];

        dispute.id = disputeId;
        dispute.proposalId = proposalId;
        dispute.reviewIndex = reviewIndex;
        dispute.disputer = msg.sender;
        dispute.reasonIpfsHash = reasonIpfsHash;
        dispute.status = DisputeStatus.Open;

        review.disputeId = disputeId; // Link the review to the dispute

        // A governance proposal is typically needed to *settle* the dispute outcome
        // We can auto-create a governance proposal here, or require a separate call.
        // Let's require a separate call `createGovernanceProposal` for type `SettleReviewDispute`.

        emit ReviewDisputed(disputeId, proposalId, reviewIndex, msg.sender);
        emit ProposalStatusUpdated(proposalId, ProposalStatus.Disputed);
        emit ReviewStatusUpdated(reviewId, ReviewStatus.Disputed);
    }

     /**
     * @dev Settles the outcome of a review dispute. Callable via Governance execution.
     * @param proposalId The ID of the proposal.
     * @param disputeIndex The index of the dispute.
     * @param outcome The settlement outcome (SettledAcceptedReview or SettledRejectedReview).
     */
    // Function 23: settleDisputeOutcome (Already listed in summary, Callable via Governance)
    function settleDisputeOutcome(uint256 proposalId, uint256 disputeIndex, DisputeStatus outcome) public whenNotPaused {
        // This function is intended to be callable *only* via Governance execution (executeGovernanceProposal)
        // Add a check that the sender is the contract itself, called from executeGovernanceProposal.
        // require(msg.sender == address(this), "DAR: Must be called by contract via governance");
        // Or check if it's called within the execution context of a specific governance proposal:
        // require(isExecutingGovernanceProposal, "DAR: Must be called via governance execution");
        // For simplicity in this example, we will allow owner to call it directly, but note it's for governance.
        require(msg.sender == owner, "DAR: Only owner (or governance) can settle disputes"); // Simplified access control

        ReviewDispute storage dispute = reviewDisputes[disputeIndex];
        require(dispute.proposalId == proposalId, "DAR: Dispute/Proposal mismatch");
        require(dispute.status == DisputeStatus.UnderGovernanceReview, "DAR: Dispute not under governance review");
        require(outcome == DisputeStatus.SettledAcceptedReview || outcome == DisputeStatus.SettledRejectedReview, "DAR: Invalid dispute outcome");

        dispute.status = outcome;

        uint256 reviewId = proposals[proposalId].reviewIds[dispute.reviewIndex];
        Review storage review = reviews[reviewId];

        if (outcome == DisputeStatus.SettledAcceptedReview) {
            // Dispute failed, reviewer was right (or researcher couldn't prove they were wrong)
            // Review remains 'Submitted' or set back to 'Accepted'
            review.status = ReviewStatus.Accepted; // Mark review as formally accepted
            // Reputation penalty for disputer (researcher)
             _updateResearcherReputation(dispute.disputer, reputationPenaltyRejectedProposal * (uint256(0) - int256(1))); // Use same penalty rate as rejected proposal
            // Optional: Small reputation boost for reviewer whose review was upheld
             _updateReviewerReputation(review.reviewer, reputationBoostAcceptedReview / 2); // Half boost for successfully defended review

        } else { // outcome == DisputeStatus.SettledRejectedReview
            // Dispute succeeded, reviewer was wrong/malicious
            review.status = ReviewStatus.Rejected; // Mark review as rejected
            // Reputation penalty for reviewer
             _updateReviewerReputation(review.reviewer, reputationPenaltyDisputedReview * (uint256(0) - int256(1)));
            // Optional: Small reputation boost for disputer (researcher)
             _updateResearcherReputation(dispute.disputer, reputationBoostApprovedProposal / 2); // Half boost for successful dispute

            // Slashing Reviewer's Stake (Example: burn some staked tokens)
             if (stakedBalances[review.reviewer] > 0) {
                 uint256 slashAmount = stakedBalances[review.reviewer] / 10; // Example: Slash 10% of stake
                 if (slashAmount > 0) {
                      _burn(review.reviewer, slashAmount);
                      stakedBalances[review.reviewer] -= slashAmount; // Update staked balance
                      totalStaked -= slashAmount; // Update total staked
                 }
             }
        }

        emit DisputeSettled(dispute.id, outcome);

        // Check if all disputes for this proposal are settled.
        // If yes, maybe update proposal status back to ReviewComplete or directly to Finalized.
        bool allDisputesSettled = true;
        for (uint i = 0; i < proposal.reviewIds.length; i++) {
             if (reviews[proposals[proposalId].reviewIds[i]].status == ReviewStatus.Disputed) {
                 allDisputesSettled = false;
                 break;
             }
        }
        if (allDisputesSettled) {
            // Now the proposal is ready for final evaluation based on the settled reviews
            proposals[proposalId].status = ProposalStatus.ReviewComplete; // Or directly Finalized?
            emit ProposalStatusUpdated(proposalId, ProposalStatus.ReviewComplete);
        }
    }

    /**
     * @dev Get details of a specific review.
     * @param proposalId The ID of the proposal the review belongs to.
     * @param reviewIndex The index of the review within the proposal's reviewIds array.
     * @return Tuple containing review details.
     */
    // Function 24: getReviewDetails (Already listed in summary)
     function getReviewDetails(uint256 proposalId, uint256 reviewIndex)
        public
        view
        returns (
            uint256 id,
            uint256 linkedProposalId,
            address reviewer,
            uint256 submissionTime,
            uint8 rating,
            string memory reviewIpfsHash,
            ReviewStatus status,
            uint256 disputeId
        )
    {
         require(proposalId < nextProposalId, "DAR: Invalid proposal ID");
         Proposal storage proposal = proposals[proposalId];
         require(reviewIndex < proposal.reviewIds.length, "DAR: Invalid review index");
         uint256 reviewId = proposal.reviewIds[reviewIndex];
         Review storage review = reviews[reviewId];

         return (
             review.id,
             review.proposalId,
             review.reviewer,
             review.submissionTime,
             review.rating,
             review.reviewIpfsHash,
             review.status,
             review.disputeId
         );
     }

    /**
     * @dev Internal helper to update researcher reputation. Can add or subtract points.
     * @param user The researcher's address.
     * @param points The amount of points to add or subtract (use negative for subtracting).
     */
    function _updateResearcherReputation(address user, int256 points) internal {
        if (points > 0) {
             researcherReputation[user] += uint256(points);
        } else if (points < 0) {
             uint256 pointsAbs = uint256(points * (int256(0) - int256(1)));
             if (researcherReputation[user] >= pointsAbs) {
                 researcherReputation[user] -= pointsAbs;
             } else {
                 researcherReputation[user] = 0; // Reputation cannot go below zero
             }
        }
        // Emit event for reputation change
        emit ReputationUpdated(user, researcherReputation[user], reviewerReputation[user]);
    }

     /**
     * @dev Internal helper to update reviewer reputation. Can add or subtract points.
     * @param user The reviewer's address.
     * @param points The amount of points to add or subtract (use negative for subtracting).
     */
    function _updateReviewerReputation(address user, int256 points) internal {
         if (points > 0) {
             reviewerReputation[user] += uint256(points);
         } else if (points < 0) {
             uint256 pointsAbs = uint256(points * (int256(0) - int256(1)));
             if (reviewerReputation[user] >= pointsAbs) {
                 reviewerReputation[user] -= pointsAbs;
             } else {
                 reviewerReputation[user] = 0; // Reputation cannot go below zero
             }
         }
         // Emit event for reputation change
         emit ReputationUpdated(user, researcherReputation[user], reviewerReputation[user]);
    }

    /**
     * @dev Get list of addresses eligible to be reviewers (e.g., meeting min stake).
     * Note: This is a simple check based on current stake. A real system might use registration.
     * @return Array of eligible reviewer addresses. This can be very gas-intensive.
     * DApps should track this off-chain or use different patterns.
     * Returning an empty array as a placeholder for efficiency reasons on-chain.
     */
    // Function 25: getEligibleReviewers (Already listed in summary)
    function getEligibleReviewers() public view returns (address[] memory) {
         // Returning a placeholder as iterating through all addresses is not feasible on-chain.
         // This function serves as a conceptual representation.
         return new address[](0);
         /*
         // Conceptual (Gas-intensive and not recommended for mainnet):
         address[] memory eligible;
         uint256 count = 0;
         // This requires iterating ALL possible addresses, which is impossible.
         // Alternative: Iterate through known stakers.
         // This requires tracking ALL staker addresses in a list/set.
         // Example if you tracked staker addresses in a `stakerAddresses` array:
         // for (uint i = 0; i < stakerAddresses.length; i++) {
         //     address staker = stakerAddresses[i];
         //     if (stakedBalances[staker] >= minStakeRequirement) {
         //         count++;
         //     }
         // }
         // Create array and populate...
         */
    }


    // --- Reputation System ---

    /**
     * @dev Get reputation score of a researcher.
     * @param user The address to query.
     * @return The researcher reputation score.
     */
    // Function 26: getResearcherReputation (Already listed in summary)
    // Implemented as public view variable.

    /**
     * @dev Get reputation score of a reviewer.
     * @param user The address to query.
     * @return The reviewer reputation score.
     */
    // Function 27: getReviewerReputation (Already listed in summary)
    // Implemented as public view variable.


    // --- Governance ---

    /**
     * @dev Allows a staked user to create a proposal to change a system parameter.
     * @param paramName The name of the parameter to change (e.g., "minStakeRequirement").
     * @param newValue The new value for the parameter.
     */
    // Function 28: createParameterProposal (Already listed in summary)
     function createParameterProposal(string memory paramName, uint256 newValue) public whenNotPaused onlyStaker {
        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.proposalType = GovernanceProposalType.ParameterChange;
        proposal.paramName = paramName;
        proposal.newValue = newValue;
        proposal.submissionTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + governanceVotingPeriod;
        proposal.status = GovernanceProposalStatus.VotingOpen;
        // Data field is not used for parameter changes, params stored directly

        emit GovernanceProposalCreated(proposalId, msg.sender, GovernanceProposalType.ParameterChange);
    }

     /**
     * @dev Allows a staked user to vote on an open governance proposal.
     * Voting power is based on staked DAR tokens.
     * @param proposalId The ID of the governance proposal.
     * @param support True for a vote in favor, false for a vote against.
     */
    // Function 29: voteOnGovernanceProposal (Already listed in summary)
     function voteOnGovernanceProposal(uint256 proposalId, bool support) public whenNotPaused onlyStaker {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == GovernanceProposalStatus.VotingOpen, "DAR: Governance proposal not open for voting");
        require(block.timestamp <= proposal.votingEndTime, "DAR: Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "DAR: Already voted on this proposal");

        uint256 votingPower = stakedBalances[msg.sender]; // Simple 1 DAR = 1 Vote power
        require(votingPower > 0, "DAR: Voter must have stake"); // Enforced by onlyStaker, but good check

        proposal.hasVoted[msg.sender] = true;

        if (support) {
            proposal.totalVotesFor += votingPower;
        } else {
            proposal.totalVotesAgainst += votingPower;
        }

        emit Voted(proposalId, msg.sender, support, votingPower);
     }

     /**
     * @dev Executes a governance proposal if it has passed quorum and majority rules.
     * @param proposalId The ID of the governance proposal to execute.
     */
    // Function 30: executeGovernanceProposal (Already listed in summary)
     function executeGovernanceProposal(uint256 proposalId) public whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == GovernanceProposalStatus.VotingOpen || proposal.status == GovernanceProposalStatus.VotingClosed, "DAR: Proposal not in correct state for execution");
        require(block.timestamp > proposal.votingEndTime, "DAR: Voting period not over");
        require(proposal.status != GovernanceProposalStatus.Executed, "DAR: Proposal already executed");

        // Check Quorum: Total votes (for + against) must be >= quorum percentage of total staked supply
        uint256 totalVotesCast = proposal.totalVotesFor + proposal.totalVotesAgainst;
        uint256 requiredQuorum = (totalStaked * governanceQuorumPercentage) / 10000; // percentage * 100
        bool quorumMet = totalVotesCast >= requiredQuorum;

        // Check Majority: Votes For must be > majority percentage of total votes cast
        uint256 requiredMajority = (totalVotesCast * governanceMajorityPercentage) / 10000; // percentage * 100
        bool majorityMet = proposal.totalVotesFor > requiredMajority;

        if (quorumMet && majorityMet) {
            // Proposal Passed
            proposal.status = GovernanceProposalStatus.Passed;
            emit GovernanceProposalStatusUpdated(proposalId, GovernanceProposalStatus.Passed);

            // Execute the proposal based on its type
            _execute(proposalId);

            proposal.status = GovernanceProposalStatus.Executed;
            emit GovernanceProposalExecuted(proposalId);

        } else {
            // Proposal Failed
            proposal.status = GovernanceProposalStatus.Failed;
            emit GovernanceProposalStatusUpdated(proposalId, GovernanceProposalStatus.Failed);
        }
     }

     /**
     * @dev Internal function to perform the action defined by a passed governance proposal.
     * @param proposalId The ID of the governance proposal.
     */
     function _execute(uint256 proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        require(proposal.status == GovernanceProposalStatus.Passed, "DAR: Proposal must be in Passed state to execute");

        if (proposal.proposalType == GovernanceProposalType.ParameterChange) {
            // Execute parameter change
            if (compareStrings(proposal.paramName, "minStakeRequirement")) {
                 minStakeRequirement = proposal.newValue;
                 emit ParameterChanged("minStakeRequirement", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "proposalFundingPeriod")) {
                 proposalFundingPeriod = proposal.newValue;
                 emit ParameterChanged("proposalFundingPeriod", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "proposalReviewPeriod")) {
                 proposalReviewPeriod = proposal.newValue;
                 emit ParameterChanged("proposalReviewPeriod", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "reviewSubmissionPeriod")) {
                 reviewSubmissionPeriod = proposal.newValue;
                 emit ParameterChanged("reviewSubmissionPeriod", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "researcherRewardRate")) {
                 researcherRewardRate = proposal.newValue;
                 emit ParameterChanged("researcherRewardRate", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "reviewerRewardRate")) {
                 reviewerRewardRate = proposal.newValue;
                 emit ParameterChanged("reviewerRewardRate", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "reputationBoostApprovedProposal")) {
                 reputationBoostApprovedProposal = proposal.newValue;
                 emit ParameterChanged("reputationBoostApprovedProposal", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "reputationPenaltyRejectedProposal")) {
                 reputationPenaltyRejectedProposal = proposal.newValue;
                 emit ParameterChanged("reputationPenaltyRejectedProposal", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "reputationBoostAcceptedReview")) {
                 reputationBoostAcceptedReview = proposal.newValue;
                 emit ParameterChanged("reputationBoostAcceptedReview", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "reputationPenaltyDisputedReview")) {
                 reputationPenaltyDisputedReview = proposal.newValue;
                 emit ParameterChanged("reputationPenaltyDisputedReview", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "governanceVotingPeriod")) {
                 governanceVotingPeriod = proposal.newValue;
                 emit ParameterChanged("governanceVotingPeriod", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "governanceQuorumPercentage")) {
                 governanceQuorumPercentage = proposal.newValue;
                 emit ParameterChanged("governanceQuorumPercentage", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "governanceMajorityPercentage")) {
                 governanceMajorityPercentage = proposal.newValue;
                 emit ParameterChanged("governanceMajorityPercentage", proposal.newValue);
            } else if (compareStrings(proposal.paramName, "stakingLockupPeriod")) {
                 stakingLockupPeriod = proposal.newValue;
                 emit ParameterChanged("stakingLockupPeriod", proposal.newValue);
            }
             // Add more parameters as needed
        } else if (proposal.proposalType == GovernanceProposalType.TreasuryWithdrawal) {
            // Execute treasury withdrawal
            withdrawFromTreasury(proposal.targetAddress, proposal.callValue);
        } else if (proposal.proposalType == GovernanceProposalType.SettleReviewDispute) {
             // Requires dispute ID and outcome encoded in data or stored separately.
             // Example: Assume data contains (uint256 disputeId, DisputeStatus outcome)
             // This needs a more concrete implementation of how dispute settlement is proposed.
             // For now, this type is conceptual. A dispute proposal would need specific structure.
             // Let's assume the `settleDisputeOutcome` function can be called directly by the contract.
             // This implies the governance proposal data would encode a call to `settleDisputeOutcome`.
             // Example: proposal.data = abi.encodeWithSelector(this.settleDisputeOutcome.selector, proposalId, disputeIndex, outcome);
             // (bool success,) = address(this).call(proposal.data); require(success, "DAR: Dispute settlement call failed");
             revert("DAR: SettleReviewDispute execution not fully implemented"); // Indicate conceptual part
        } else if (proposal.proposalType == GovernanceProposalType.CustomCall) {
             // Execute custom call (requires data, target, value)
             (bool success, ) = proposal.targetAddress.call{value: proposal.callValue}(proposal.data);
             require(success, "DAR: Custom governance call failed");
        }
         // Add more proposal types as needed
     }

     /**
     * @dev Allows governance to withdraw ETH from the contract treasury.
     * Callable ONLY via Governance execution.
     * @param recipient The address to send ETH to.
     * @param amount The amount of ETH to withdraw.
     */
    // Function 31: withdrawFromTreasury (Already listed in summary, Callable via Governance)
    function withdrawFromTreasury(address payable recipient, uint256 amount) public whenNotPaused {
        // This function is intended to be callable *only* via Governance execution.
        // Add a check that the sender is the contract itself, called from executeGovernanceProposal.
        // require(msg.sender == address(this), "DAR: Must be called by contract via governance");
        // Or check if it's called within the execution context of a specific governance proposal:
        // require(isExecutingGovernanceProposal, "DAR: Must be called via governance execution");
        // For simplicity in this example, allowing owner to call directly, but note it's for governance.
        require(msg.sender == owner, "DAR: Only owner (or governance) can withdraw"); // Simplified access control

        require(address(this).balance >= amount, "DAR: Insufficient treasury balance");
        recipient.transfer(amount);
        emit TreasuryWithdrawal(recipient, amount);
    }

    /**
     * @dev Get details of a specific governance proposal.
     * @param proposalId The ID of the governance proposal.
     * @return Tuple containing governance proposal details.
     */
    // Function 32: getGovernanceProposalDetails (Already listed in summary)
     function getGovernanceProposalDetails(uint256 proposalId)
         public
         view
         returns (
             uint256 id,
             address proposer,
             GovernanceProposalType proposalType,
             string memory description,
             uint256 submissionTime,
             uint256 votingEndTime,
             uint256 totalVotesFor,
             uint256 totalVotesAgainst,
             GovernanceProposalStatus status,
             string memory paramName,
             uint256 newValue,
             address targetAddress,
             uint256 callValue
         )
     {
        GovernanceProposal storage proposal = governanceProposals[proposalId];
        // Note: `data` mapping cannot be returned directly in view.
        // Also `hasVoted` mapping cannot be returned directly.
        return (
            proposal.id,
            proposal.proposer,
            proposal.proposalType,
            proposal.description, // Description field was not added to struct, adding now.
            proposal.submissionTime,
            proposal.votingEndTime,
            proposal.totalVotesFor,
            proposal.totalVotesAgainst,
            proposal.status,
            proposal.paramName,
            proposal.newValue,
            proposal.targetAddress,
            proposal.callValue
        );
     }
     // Need to add `string description;` to the GovernanceProposal struct.

     // Function 33: getVotingPower (Helper view function)
     /**
      * @dev Gets the voting power of a user (based on stake).
      * @param user The user's address.
      * @return The voting power.
      */
     function getVotingPower(address user) public view returns (uint256) {
         return stakedBalances[user];
     }

    // --- Utility & Admin ---

    /**
     * @dev Pauses the contract. Callable by owner or governance.
     */
    // Function 34: pauseContract (Already listed in summary)
    function pauseContract() public whenNotPaused {
        // Allow owner OR governance to pause
        require(msg.sender == owner /* || isExecutingGovernanceProposal */, "DAR: Only owner or governance can pause");
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract. Callable by owner or governance.
     */
    // Function 35: unpauseContract (Already listed in summary)
    function unpauseContract() public whenPaused {
        // Allow owner OR governance to unpause
        require(msg.sender == owner /* || isExecutingGovernanceProposal */, "DAR: Only owner or governance can unpause");
        paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Get the current minimum stake requirement.
     * @return The minimum stake amount.
     */
    // Function 36: getMinStakeRequirement (Already listed in summary)
    // Implemented as public view variable.

    /**
     * @dev Get the current contract's ETH balance (Treasury).
     * @return The ETH balance.
     */
    // Function 37: getTreasuryBalance (Already listed in summary)
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Helper function to compare strings (Solidity doesn't have built-in)
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    // Fallback function to receive ETH for funding proposals
    receive() external payable {
        // ETH received here must be intended for funding a proposal.
        // A better design would require funding via `fundResearchProposal(id)` call.
        // For this example, disabling direct ETH receive.
        revert("DAR: Direct ETH transfers not allowed. Use fundResearchProposal.");
    }

    // Need to add description field to GovernanceProposal struct
    // struct GovernanceProposal { ... string description; ... }
    // And update createParameterProposal and getGovernanceProposalDetails accordingly.

    // Let's update the GovernanceProposal struct and related functions.

    // *** RE-DECLARING GovernanceProposal STRUCT WITH DESCRIPTION ***
    /* struct GovernanceProposal {
        uint256 id;
        address proposer;
        GovernanceProposalType proposalType;
        bytes data; // Encoded function call data for execution
        string description; // Added field
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 totalVotesFor;
        uint256 totalVotesAgainst;
        mapping(address => bool) hasVoted;
        GovernanceProposalStatus status;
        // Fields for parameter changes (kept for easier retrieval in view)
        string paramName;
        uint256 newValue;
        address targetAddress; // For withdrawal or other calls
        uint256 callValue; // For withdrawal or other calls
    } */
    // Already declared above, just noting the addition.


    // Update createParameterProposal to include description
    /*
    function createParameterProposal(string memory paramName, uint256 newValue, string memory description) public whenNotPaused onlyStaker {
        uint256 proposalId = nextGovernanceProposalId++;
        GovernanceProposal storage proposal = governanceProposals[proposalId];

        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.proposalType = GovernanceProposalType.ParameterChange;
        proposal.paramName = paramName;
        proposal.newValue = newValue;
        proposal.description = description; // Add description
        proposal.submissionTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + governanceVotingPeriod;
        proposal.status = GovernanceProposalStatus.VotingOpen;
        // Data field is not used for parameter changes, params stored directly

        emit GovernanceProposalCreated(proposalId, msg.sender, GovernanceProposalType.ParameterChange);
    }
    */
    // Need to update the function signature and call site in the summary/outline.

    // Let's add more distinct functions to reach comfortably over 20, including view functions.
    // We have 37 functions listed above/in thought process. Let's add a couple more distinct ones.

    // Additional Potential Functions:
    // 38. `getProposalReviews(proposalId)`: Get all review IDs for a proposal (view).
    // 39. `getDisputeDetails(disputeId)`: Get details of a specific dispute (view).
    // 40. `listGovernanceProposalsByStatus(status)`: List governance proposals by status (view - similar gas concerns as listing research proposals).

    /**
     * @dev Get all review IDs associated with a proposal.
     * @param proposalId The ID of the proposal.
     * @return An array of review IDs.
     */
    // Function 38: getProposalReviews
     function getProposalReviewIds(uint256 proposalId) public view returns (uint256[] memory) {
         require(proposalId < nextProposalId, "DAR: Invalid proposal ID");
         return proposals[proposalId].reviewIds;
     }

     /**
     * @dev Get details of a specific review dispute.
     * @param disputeId The ID of the dispute.
     * @return Tuple containing dispute details.
     */
    // Function 39: getDisputeDetails
    function getDisputeDetails(uint256 disputeId)
         public
         view
         returns (
             uint256 id,
             uint256 proposalId,
             uint256 reviewIndex,
             address disputer,
             string memory reasonIpfsHash,
             DisputeStatus status,
             uint256 settlementGovernanceProposalId
         )
    {
         require(disputeId < nextDisputeId, "DAR: Invalid dispute ID");
         ReviewDispute storage dispute = reviewDisputes[disputeId];
         return (
             dispute.id,
             dispute.proposalId,
             dispute.reviewIndex,
             dispute.disputer,
             dispute.reasonIpfsHash,
             dispute.status,
             dispute.settlementGovernanceProposalId
         );
    }

    /**
     * @dev List governance proposals filtered by status. Note: Gas intensive.
     * @param status The status to filter by.
     * @return Array of governance proposal IDs matching the status.
     */
    // Function 40: listGovernanceProposalsByStatus
    function listGovernanceProposalsByStatus(GovernanceProposalStatus status) public view returns (uint256[] memory) {
        uint256[] memory filtered;
        uint256 count = 0;
        for (uint256 i = 0; i < nextGovernanceProposalId; i++) {
            if (governanceProposals[i].status == status) {
                count++;
            }
        }

        filtered = new uint256[](count);
        uint256 current = 0;
        for (uint256 i = 0; i < nextGovernanceProposalId; i++) {
            if (governanceProposals[i].status == status) {
                filtered[current] = i;
                current++;
            }
        }
        return filtered;
    }

     // Adding a function to allow researcher to claim approved funding after finalization
     // Although distributeRewards does this, a separate claim function might be cleaner
     // Function 41: claimApprovedFunding
     /**
      * @dev Allows the researcher of an Approved proposal to claim the funded ETH.
      * @param proposalId The ID of the proposal.
      */
     function claimApprovedFunding(uint256 proposalId) public whenNotPaused onlyResearcher(proposalId) {
         Proposal storage proposal = proposals[proposalId];
         require(proposal.status == ProposalStatus.Finalized || proposal.status == ProposalStatus.Approved, "DAR: Proposal not finalized or approved"); // Should be finalized
         require(proposal.status == ProposalStatus.Approved, "DAR: Proposal was not approved"); // Explicitly check approved state post-finalization
         require(!proposal.fundingClaimed, "DAR: Funding already claimed");
         require(proposal.fundedAmountETH > 0, "DAR: No ETH funded to claim");

         uint256 amountToClaim = proposal.fundedAmountETH;
         proposal.fundedAmountETH = 0; // Mark as claimed
         proposal.fundingClaimed = true;

         (payable(msg.sender)).transfer(amountToClaim);
         // Emit an event if needed, although RewardsDistributed covers it conceptually

     }

     // Function 42: getPendingUnstakeAmount (View function)
     /**
      * @dev Gets the amount of DAR tokens a user has requested to unstake and is pending lockup expiry.
      * @param user The address to query.
      * @return The pending unstake amount.
      */
     function getPendingUnstakeAmount(address user) public view returns (uint256) {
         return pendingUnstakeAmount[user]; // Requires the pendingUnstakeAmount mapping
     }

    // Total distinct functions counted (including internal token helpers exposed as public views where applicable, and significant views):
    // 1.  stakeDAR
    // 2.  unstakeDAR (requires update) -> updated
    // 3.  claimUnstakedTokens (new utility)
    // 4.  getUserStake (view)
    // 5.  getTotalStaked (view)
    // 6.  balanceOf (view)
    // 7.  totalSupply (view)
    // 8.  mintInitialSupply
    // 9.  burn
    // 10. submitResearchProposal
    // 11. fundResearchProposal (payable)
    // 12. claimFundingRefund (conceptual placeholder)
    // 13. finalizeProposalEvaluation
    // 14. distributeRewards
    // 15. getProposalDetails (view)
    // 16. listProposalsByStatus (view)
    // 17. registerAsReviewer
    // 18. submitReview
    // 19. disputeReview
    // 20. settleDisputeOutcome (governance callable)
    // 21. getReviewDetails (view)
    // 22. getProposalReviewIds (new view)
    // 23. getEligibleReviewers (conceptual placeholder view)
    // 24. getResearcherReputation (view)
    // 25. getReviewerReputation (view)
    // 26. createParameterProposal (governance)
    // 27. voteOnGovernanceProposal (governance)
    // 28. executeGovernanceProposal (governance)
    // 29. withdrawFromTreasury (governance callable)
    // 30. getGovernanceProposalDetails (view)
    // 31. listGovernanceProposalsByStatus (new view)
    // 32. getVotingPower (view)
    // 33. pauseContract (admin/governance)
    // 34. unpauseContract (admin/governance)
    // 35. getMinStakeRequirement (view)
    // 36. getTreasuryBalance (view)
    // 37. getDisputeDetails (new view)
    // 38. claimApprovedFunding (new utility)
    // 39. getPendingUnstakeAmount (new view)
    // 40. getStakingLockupPeriod (public view variable)

    // We have 40 functions now, well over the 20 minimum.

}
```