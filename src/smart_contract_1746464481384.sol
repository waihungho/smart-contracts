Okay, here is a Solidity smart contract for a "Decentralized Knowledge Base with Proof-of-Truth and Reputation".

This concept involves users submitting claims (representing knowledge), staking tokens on their truthfulness, challenging claims they believe are false, participating in a dispute resolution process (like a jury) weighted by reputation, earning reputation and rewards for correct judgments and valuable contributions, and governing the system parameters decentralizingly.

It's creative as it combines elements of TCRs, prediction markets (in a sense), reputation systems, and decentralized governance focused specifically on verifying information authenticity via economic incentives and community consensus. It's advanced due to the state transitions, complex reward/slashing logic, and governance overlay. It's trendy because of the focus on decentralized information validation and reputation.

---

**Outline & Function Summary**

**Contract Name:** `DecentralizedKnowledgeBase`

**Concept:** A decentralized platform for submitting, verifying, challenging, and resolving knowledge claims using staking, reputation, and community governance. Users stake tokens on claims, endorse or challenge them, participate in disputes as a reputation-weighted jury, and earn rewards/reputation for aligning with the validated truth.

**Core Components:**

1.  **Knowledge Claims:** Represented by IPFS hashes, staked by submitters and potentially endorsers/challengers.
2.  **Claim Status:** Tracks the lifecycle of a claim (Pending, Validated, Disputed, Invalidated).
3.  **Staking:** Users lock tokens to submit, endorse, or challenge claims. Stakes are used for rewards, slashing, and voting power.
4.  **Reputation:** A score for each user, increased by successful contributions (validated claims, correct dispute votes) and decreased by unsuccessful ones. Affects voting power and reward share.
5.  **Disputes:** Initiated by challenging a Validated claim. Resolved by a community vote (jury).
6.  **Dispute Voting/Jury:** Users (potentially weighted by reputation/stake) vote on the truthfulness of a disputed claim.
7.  **Rewards & Slashing:** Staked tokens and protocol-level rewards are distributed based on dispute outcomes, rewarding those who aligned with the truth and slashing those who did not.
8.  **Governance:** Allows token/reputation holders to propose and vote on changes to protocol parameters.

**Enums:**

*   `ClaimStatus`: Enum representing the state of a knowledge claim.
*   `StakeType`: Enum representing the purpose of a stake on a claim.
*   `DisputeStatus`: Enum representing the state of a dispute.
*   `VoteOption`: Enum for voting in disputes and governance.
*   `ProposalStatus`: Enum representing the state of a governance proposal.

**Structs:**

*   `KnowledgeClaim`: Details of a submitted claim (submitter, hash, status, stakes, reputation, timestamps).
*   `ClaimStake`: Details of a specific stake associated with a claim.
*   `Dispute`: Details of a dispute process (claim ID, challenger, voters, outcome, timestamps).
*   `DisputeVote`: Details of a specific vote within a dispute.
*   `UserReputation`: Stores a user's reputation score and rewards balance.
*   `GovernanceProposal`: Details of a governance proposal.
*   `ProposalVote`: Details of a specific vote on a proposal.
*   `ProtocolConfig`: Stores various configurable parameters of the contract.

**State Variables:**

*   `token`: The address of the ERC20 token used for staking and rewards.
*   `claims`: Mapping from claim ID to `KnowledgeClaim`.
*   `disputes`: Mapping from dispute ID to `Dispute`.
*   `userReputation`: Mapping from user address to `UserReputation`.
*   `governanceProposals`: Mapping from proposal ID to `GovernanceProposal`.
*   `config`: Stores the current `ProtocolConfig`.
*   Counters for claim, dispute, and proposal IDs.
*   Mappings to track stakes, votes, etc.

**Function Summary (Minimum 20):**

1.  `setTokenAddress(IERC20 _token)`: (Admin/Setup) Sets the address of the staking/reward token.
2.  `submitClaim(string memory _ipfsHash)`: Allows a user to submit a new knowledge claim by staking tokens.
3.  `endorseClaim(uint256 _claimId)`: Allows a user to stake tokens to endorse a claim they believe is true.
4.  `challengeClaim(uint256 _claimId)`: Allows a user to stake tokens to challenge a Validated claim they believe is false, initiating a dispute.
5.  `withdrawStake(uint256 _claimId)`: Allows a user to withdraw their stake after a claim/dispute is resolved, if eligible.
6.  `voteInDispute(uint256 _disputeId, VoteOption _vote)`: Allows eligible users (stakers/high reputation) to vote on the truthfulness of a disputed claim.
7.  `resolveDispute(uint256 _disputeId)`: Allows anyone to trigger the resolution of a dispute after the voting period ends, distributing stakes/rewards and updating reputations based on the outcome.
8.  `claimRewards()`: Allows a user to claim accumulated rewards from successful staking, voting, or claim submissions.
9.  `getUserReputation(address _user)`: Retrieves a user's current reputation score.
10. `getClaimDetails(uint256 _claimId)`: Retrieves the details of a specific knowledge claim.
11. `getDisputeDetails(uint256 _disputeId)`: Retrieves the details of a specific dispute.
12. `getStakeDetails(uint256 _claimId, address _user)`: Retrieves the details of a user's stake on a specific claim.
13. `getDisputeVote(uint256 _disputeId, address _user)`: Retrieves a user's vote in a specific dispute.
14. `getUserRewardsAvailable(address _user)`: Checks the amount of rewards available for a user to claim.
15. `submitGovernanceProposal(string memory _description, address _targetContract, bytes memory _callData)`: Allows users with sufficient reputation/stake to submit a proposal to change contract parameters or execute other actions.
16. `voteOnGovernanceProposal(uint256 _proposalId, VoteOption _vote)`: Allows eligible users (reputation/stake holders) to vote on a governance proposal.
17. `executeGovernanceProposal(uint256 _proposalId)`: Allows anyone to trigger the execution of a governance proposal that has passed and is ready.
18. `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
19. `getUserProposalVote(uint256 _proposalId, address _user)`: Retrieves a user's vote on a specific proposal.
20. `getProtocolConfig()`: Retrieves the current configuration parameters of the protocol.
21. `getClaimStakeCount(uint256 _claimId, StakeType _type)`: Gets the number of stakes of a specific type on a claim.
22. `isEligibleToVoteInDispute(uint256 _disputeId, address _user)`: Checks if a user is eligible to vote in a given dispute.
23. `isEligibleToSubmitProposal(address _user)`: Checks if a user is eligible to submit a governance proposal.
24. `isEligibleToVoteOnProposal(address _user)`: Checks if a user is eligible to vote on governance proposals.
25. `getClaimSubmitter(uint256 _claimId)`: Gets the address of the submitter of a claim.
26. `getDisputeChallenger(uint256 _disputeId)`: Gets the address of the challenger in a dispute.

*(Self-correction: We have more than 20 functions listed above, fulfilling the requirement.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial setup, governance takes over

contract DecentralizedKnowledgeBase is Ownable {
    using SafeERC20 for IERC20;

    // --- Enums ---

    enum ClaimStatus { Pending, Validated, Disputed, Invalidated }
    enum StakeType { Submit, Endorse, Challenge }
    enum DisputeStatus { Voting, Resolved }
    enum VoteOption { Abstain, Yes, No } // Yes = Truthful (for Dispute), Yes = Approve (for Proposal)
    enum ProposalStatus { Pending, Active, Succeeded, Defeated, Executed }

    // --- Structs ---

    struct KnowledgeClaim {
        address submitter;
        string ipfsHash; // Hash referring to the off-chain knowledge content
        ClaimStatus status;
        uint256 submitStake; // Initial stake by submitter
        mapping(address => ClaimStake) stakes; // Stakers on this claim (endorse/challenge)
        address[] stakerAddresses; // To iterate stakes
        uint256 totalEndorseStake;
        uint256 totalChallengeStake;
        uint256 claimReputation; // Aggregate reputation of stakers (endorsers)
        uint48 timestamp; // Submission timestamp
    }

    struct ClaimStake {
        StakeType stakeType;
        uint256 amount;
        uint48 timestamp;
        bool withdrawn; // Flag to prevent double withdrawal
    }

    struct Dispute {
        uint256 claimId;
        address challenger;
        DisputeStatus status;
        uint48 startTime;
        uint48 endTime; // End of voting period
        mapping(address => DisputeVote) votes; // User vote in this dispute
        address[] voterAddresses; // To iterate votes
        uint256 yesVotes; // Weighted by reputation
        uint256 noVotes; // Weighted by reputation
        VoteOption outcome; // Resolved outcome (Yes=True, No=False)
    }

    struct DisputeVote {
        VoteOption vote;
        uint256 reputationWeight; // Reputation snapshot at voting time
    }

    struct UserReputation {
        uint256 score; // Reputation points
        uint256 rewardsAvailable; // Tokens earned, ready to be claimed
    }

    struct ProtocolConfig {
        uint256 minSubmitStake;
        uint256 minEndorseStake;
        uint256 minChallengeStake;
        uint48 disputeVotingPeriod; // Seconds
        uint256 disputeVoteReputationThreshold; // Minimum reputation to vote
        uint256 governanceProposalStake; // Stake required to submit proposal
        uint48 governanceVotingPeriod; // Seconds
        uint256 governanceQuorumNumerator; // Quorum = totalReputation * numerator / 100
        uint256 governanceThresholdNumerator; // Threshold = totalVotes * numerator / 100
        uint256 disputeSlashPercentage; // Percentage of stake slashed from losing side
        uint256 disputeRewardPercentage; // Percentage of slashed amount given to winning voters/jury
        uint256 submitterRewardPercentage; // Percentage of submit stake returned on validation
    }

    struct GovernanceProposal {
        string description;
        address targetContract; // Contract to call if proposal passes (e.g., self for config updates)
        bytes callData; // Calldata for the targetContract function
        ProposalStatus status;
        uint48 startTime;
        uint48 endTime; // End of voting period
        mapping(address => ProposalVote) votes;
        address[] voterAddresses;
        uint256 totalReputationWeight; // Sum of reputation of voters
        uint256 yesReputationWeight; // Weighted Yes votes
        uint256 noReputationWeight; // Weighted No votes
        uint256 proposalStake; // Stake of the proposer
    }

    struct ProposalVote {
        VoteOption vote;
        uint256 reputationWeight; // Reputation snapshot at voting time
    }

    // --- State Variables ---

    IERC20 public token;
    mapping(uint256 => KnowledgeClaim) public claims;
    uint256 private _claimCounter;

    mapping(uint256 => Dispute) public disputes;
    uint256 private _disputeCounter;

    mapping(address => UserReputation) public userReputation;
    uint256 private _totalReputation; // Sum of all user reputation

    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 private _proposalCounter;

    ProtocolConfig public config;

    // --- Events ---

    event TokenAddressSet(address indexed tokenAddress);
    event ClaimSubmitted(uint256 indexed claimId, address indexed submitter, string ipfsHash, uint256 stake);
    event ClaimStatusUpdated(uint256 indexed claimId, ClaimStatus newStatus);
    event StakeAdded(uint256 indexed claimId, address indexed staker, StakeType stakeType, uint256 amount);
    event StakeWithdrawn(uint256 indexed claimId, address indexed staker, uint256 amount);
    event DisputeStarted(uint256 indexed disputeId, uint256 indexed claimId, address indexed challenger);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, VoteOption vote, uint256 reputationWeight);
    event DisputeResolved(uint256 indexed disputeId, VoteOption outcome, uint256 totalStakesDistributed);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceProposalVoted(uint256 indexed proposalId, address indexed voter, VoteOption vote, uint256 reputationWeight);
    event GovernanceProposalStatusUpdated(uint256 indexed proposalId, ProposalStatus newStatus);
    event GovernanceProposalExecuted(uint256 indexed proposalId);
    event ConfigUpdated(bytes32 indexed paramName, uint256 newValue); // Example for config changes

    // --- Modifiers ---

    modifier onlyTokenOwner() {
        require(msg.sender == token.owner(), "DKB: Not token owner"); // If token is also managed by this contract owner
        _;
    }

    // Modifier for governance execution (can be called by anyone after passing)
    modifier onlyGovExecutor(uint256 _proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Succeeded, "DKB: Proposal not succeeded");
        require(block.timestamp > proposal.endTime, "DKB: Proposal voting not ended"); // Ensure voting ended
        _;
    }

    // Modifier to check sufficient reputation/stake for proposal submission/voting
    modifier checkGovernanceEligibility(address _user, bool requireProposalStake) {
        if (requireProposalStake) {
             require(userReputation[_user].score >= config.governanceProposalStake, "DKB: Insufficient reputation for proposal");
        } else {
             require(userReputation[_user].score > 0, "DKB: No reputation to vote"); // Simplified: requires any reputation
        }
        _;
    }

    // --- Constructor ---

    constructor(address _initialOwner) Ownable(_initialOwner) {
        // Initial configuration - should ideally be set via a first governance proposal
        // Or set by owner post-deployment and then ownership transferred/renounced
        config = ProtocolConfig({
            minSubmitStake: 100 ether,
            minEndorseStake: 10 ether,
            minChallengeStake: 50 ether,
            disputeVotingPeriod: 7 days,
            disputeVoteReputationThreshold: 50, // Arbitrary threshold
            governanceProposalStake: 1000, // Reputation score required
            governanceVotingPeriod: 3 days,
            governanceQuorumNumerator: 4, // 40% quorum (out of 100)
            governanceThresholdNumerator: 5, // 50% threshold (out of 10)
            disputeSlashPercentage: 30, // 30% slashed
            disputeRewardPercentage: 50, // 50% of slashed amount rewarded
            submitterRewardPercentage: 100 // 100% of submit stake returned
        });
    }

    // --- Initial Setup Functions (Callable by Owner) ---

    /**
     * @notice Sets the address of the ERC20 token used for staking and rewards.
     * @param _token Address of the ERC20 token contract.
     */
    function setTokenAddress(IERC20 _token) external onlyOwner {
        require(address(token) == address(0), "DKB: Token address already set");
        token = _token;
        emit TokenAddressSet(address(_token));
    }

     /**
     * @notice Allows the owner to set initial configuration parameters.
     *         Should be used carefully before governance is fully active.
     * @param _config The initial configuration struct.
     */
    function setInitialConfig(ProtocolConfig memory _config) external onlyOwner {
         // Basic validation, more comprehensive validation could be added
         require(_config.minSubmitStake > 0 && _config.disputeVotingPeriod > 0, "DKB: Invalid initial config");
         config = _config;
         // No specific event for setting the whole struct, individual parameter events could be added.
    }


    // --- Core Knowledge Base Functions ---

    /**
     * @notice Allows a user to submit a new knowledge claim.
     * @param _ipfsHash The IPFS hash pointing to the knowledge content.
     */
    function submitClaim(string memory _ipfsHash) external {
        require(bytes(_ipfsHash).length > 0, "DKB: IPFS hash cannot be empty");
        require(address(token) != address(0), "DKB: Token address not set");
        require(msg.sender != address(0), "DKB: Invalid sender");

        uint256 requiredStake = config.minSubmitStake;
        require(token.balanceOf(msg.sender) >= requiredStake, "DKB: Insufficient token balance for submission stake");
        token.safeTransferFrom(msg.sender, address(this), requiredStake);

        _claimCounter++;
        uint256 newClaimId = _claimCounter;

        KnowledgeClaim storage newClaim = claims[newClaimId];
        newClaim.submitter = msg.sender;
        newClaim.ipfsHash = _ipfsHash;
        newClaim.status = ClaimStatus.Pending; // Starts as pending validation
        newClaim.submitStake = requiredStake;
        newClaim.claimReputation = 0; // Initial reputation derived from endorsers later
        newClaim.timestamp = uint48(block.timestamp);

        // Add submitter's stake entry
        newClaim.stakes[msg.sender] = ClaimStake({
            stakeType: StakeType.Submit,
            amount: requiredStake,
            timestamp: uint48(block.timestamp),
            withdrawn: false
        });
        newClaim.stakerAddresses.push(msg.sender);

        emit ClaimSubmitted(newClaimId, msg.sender, _ipfsHash, requiredStake);
        // Claim remains Pending until endorsed or challenged

        // Auto-validate if submit stake is very high? Or require manual validation/endorsement?
        // Let's require endorsement/challenge for transition from Pending
    }

    /**
     * @notice Allows a user to stake tokens to endorse a claim they believe is true.
     *         Can transition a Pending claim to Validated.
     * @param _claimId The ID of the claim to endorse.
     */
    function endorseClaim(uint256 _claimId) external {
        KnowledgeClaim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "DKB: Claim does not exist");
        require(claim.status == ClaimStatus.Pending || claim.status == ClaimStatus.Validated, "DKB: Claim is not pending or validated");
        require(claim.stakes[msg.sender].amount == 0, "DKB: User already staked on this claim"); // One stake per user per claim

        uint256 requiredStake = config.minEndorseStake;
        require(token.balanceOf(msg.sender) >= requiredStake, "DKB: Insufficient token balance for endorsement stake");
        token.safeTransferFrom(msg.sender, address(this), requiredStake);

        claim.stakes[msg.sender] = ClaimStake({
            stakeType: StakeType.Endorse,
            amount: requiredStake,
            timestamp: uint48(block.timestamp),
            withdrawn: false
        });
        claim.stakerAddresses.push(msg.sender);
        claim.totalEndorseStake += requiredStake;

        // Update claim reputation based on endorsers' reputation
        // This is a simple sum, could be more complex (e.g., average, decaying)
        claim.claimReputation += userReputation[msg.sender].score;

        if (claim.status == ClaimStatus.Pending && claim.totalEndorseStake >= claim.submitStake) {
             // Example rule: endorse stake matches submit stake to move to Validated
            claim.status = ClaimStatus.Validated;
            emit ClaimStatusUpdated(_claimId, ClaimStatus.Validated);
        }

        emit StakeAdded(_claimId, msg.sender, StakeType.Endorse, requiredStake);
    }

    /**
     * @notice Allows a user to stake tokens to challenge a Validated claim, initiating a dispute.
     * @param _claimId The ID of the claim to challenge.
     */
    function challengeClaim(uint256 _claimId) external {
        KnowledgeClaim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "DKB: Claim does not exist");
        require(claim.status == ClaimStatus.Validated, "DKB: Can only challenge validated claims");
        require(claim.stakes[msg.sender].amount == 0, "DKB: User already staked on this claim"); // One stake per user per claim

        uint256 requiredStake = config.minChallengeStake;
        require(token.balanceOf(msg.sender) >= requiredStake, "DKB: Insufficient token balance for challenge stake");
        token.safeTransferFrom(msg.sender, address(this), requiredStake);

        claim.stakes[msg.sender] = ClaimStake({
            stakeType: StakeType.Challenge,
            amount: requiredStake,
            timestamp: uint48(block.timestamp),
            withdrawn: false
        });
        claim.stakerAddresses.push(msg.sender);
        claim.totalChallengeStake += requiredStake;

        claim.status = ClaimStatus.Disputed;
        emit ClaimStatusUpdated(_claimId, ClaimStatus.Disputed);

        // Start dispute
        _disputeCounter++;
        uint256 newDisputeId = _disputeCounter;
        Dispute storage newDispute = disputes[newDisputeId];
        newDispute.claimId = _claimId;
        newDispute.challenger = msg.sender;
        newDispute.status = DisputeStatus.Voting;
        newDispute.startTime = uint48(block.timestamp);
        newDispute.endTime = uint48(block.timestamp + config.disputeVotingPeriod);

        emit StakeAdded(_claimId, msg.sender, StakeType.Challenge, requiredStake);
        emit DisputeStarted(newDisputeId, _claimId, msg.sender);
    }

    /**
     * @notice Allows eligible users to vote in an ongoing dispute.
     * @param _disputeId The ID of the dispute.
     * @param _vote The user's vote (Yes for True, No for False).
     */
    function voteInDispute(uint256 _disputeId, VoteOption _vote) external {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.claimId != 0, "DKB: Dispute does not exist");
        require(dispute.status == DisputeStatus.Voting, "DKB: Dispute is not in voting phase");
        require(block.timestamp >= dispute.startTime && block.timestamp < dispute.endTime, "DKB: Voting period is not active");
        require(_vote == VoteOption.Yes || _vote == VoteOption.No, "DKB: Invalid vote option");
        require(dispute.votes[msg.sender].reputationWeight == 0, "DKB: User already voted in this dispute"); // One vote per user

        // Eligibility: User must have minimum reputation
        uint256 voterReputation = userReputation[msg.sender].score;
        require(voterReputation >= config.disputeVoteReputationThreshold, "DKB: Insufficient reputation to vote");

        dispute.votes[msg.sender] = DisputeVote({
            vote: _vote,
            reputationWeight: voterReputation // Snapshot reputation at vote time
        });
        dispute.voterAddresses.push(msg.sender);

        if (_vote == VoteOption.Yes) {
            dispute.yesVotes += voterReputation;
        } else {
            dispute.noVotes += voterReputation;
        }

        emit DisputeVoted(_disputeId, msg.sender, _vote, voterReputation);
    }

    /**
     * @notice Triggers the resolution of a dispute after the voting period ends.
     *         Distributes stakes/rewards and updates reputations based on the outcome.
     * @param _disputeId The ID of the dispute to resolve.
     */
    function resolveDispute(uint256 _disputeId) external {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.claimId != 0, "DKB: Dispute does not exist");
        require(dispute.status == DisputeStatus.Voting, "DKB: Dispute is not in voting phase");
        require(block.timestamp >= dispute.endTime, "DKB: Voting period is still active");

        KnowledgeClaim storage claim = claims[dispute.claimId];

        // Determine Outcome: Yes = Truthful (Validated), No = False (Invalidated)
        // Outcome based on total reputation-weighted votes
        VoteOption outcome;
        if (dispute.yesVotes > dispute.noVotes) {
            outcome = VoteOption.Yes; // Claim is deemed True -> Validated
            claim.status = ClaimStatus.Validated; // Revert to Validated if previously disputed
        } else {
            outcome = VoteOption.No; // Claim is deemed False -> Invalidated
            claim.status = ClaimStatus.Invalidated;
        }
        dispute.outcome = outcome;
        dispute.status = DisputeStatus.Resolved;

        emit ClaimStatusUpdated(dispute.claimId, claim.status);

        // Distribute Stakes and Rewards
        _distributeStakesAndRewards(dispute.claimId, outcome);

        emit DisputeResolved(_disputeId, outcome, claim.submitStake + claim.totalEndorseStake + claim.totalChallengeStake); // Total theoretical stake involved
    }

    /**
     * @notice Allows a user to withdraw their stake from a resolved claim/dispute.
     *         Stakes are only withdrawable if the user was on the winning side of a resolved dispute,
     *         or if their submitted claim was Validated.
     * @param _claimId The ID of the claim the stake is associated with.
     */
    function withdrawStake(uint256 _claimId) external {
        KnowledgeClaim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "DKB: Claim does not exist");
        require(claim.status == ClaimStatus.Validated || claim.status == ClaimStatus.Invalidated, "DKB: Claim status must be Validated or Invalidated");

        ClaimStake storage stake = claim.stakes[msg.sender];
        require(stake.amount > 0, "DKB: User has no stake on this claim");
        require(!stake.withdrawn, "DKB: Stake already withdrawn");

        uint256 amountToReturn = 0;

        // Check if the user's stake aligns with the final outcome
        if (claim.status == ClaimStatus.Validated) {
            if (stake.stakeType == StakeType.Submit) {
                 // Submitter gets their stake back if validated
                 amountToReturn = stake.amount;
                 // Submitter gets reputation for successful submission
                 _updateReputation(msg.sender, stake.amount / 10 ether); // Example: 1 point per 10 tokens staked successfully
            } else if (stake.stakeType == StakeType.Endorse) {
                // Endorsers get their stake back and potentially rewards
                amountToReturn = stake.amount;
                // Rewards for endorsers come from dispute resolution if claim was challenged
                // For non-disputed validation, maybe smaller reputation boost?
                _updateReputation(msg.sender, stake.amount / 20 ether); // Example: 1 point per 20 tokens endorsed successfully
            } else if (stake.stakeType == StakeType.Challenge) {
                 // Challenger was wrong, their stake was slashed in _distributeStakesAndRewards
                 amountToReturn = 0; // No stake returned
                 // Challenger loses reputation in _distributeStakesAndRewards
            }
        } else if (claim.status == ClaimStatus.Invalidated) { // Claim was invalidated
             if (stake.stakeType == StakeType.Submit || stake.stakeType == StakeType.Endorse) {
                 // Submitter/Endorser was wrong, their stake was slashed
                 amountToReturn = 0; // No stake returned
                 // Submitter/Endorser loses reputation in _distributeStakesAndRewards
             } else if (stake.stakeType == StakeType.Challenge) {
                 // Challenger was right, gets stake back and rewards
                 amountToReturn = stake.amount;
                 // Challenger gains reputation in _distributeStakesAndRewards
             }
        } else {
             revert("DKB: Invalid claim status for withdrawal"); // Should not happen
        }

        stake.withdrawn = true; // Mark as withdrawn

        if (amountToReturn > 0) {
             token.safeTransfer(msg.sender, amountToReturn);
        }

        emit StakeWithdrawn(_claimId, msg.sender, amountToReturn);
    }

    /**
     * @notice Allows a user to claim their accumulated rewards.
     */
    function claimRewards() external {
        uint256 rewards = userReputation[msg.sender].rewardsAvailable;
        require(rewards > 0, "DKB: No rewards available");

        userReputation[msg.sender].rewardsAvailable = 0;
        token.safeTransfer(msg.sender, rewards);

        emit RewardsClaimed(msg.sender, rewards);
    }


    // --- Dispute Resolution Helper (Internal) ---

    /**
     * @notice Distributes stakes and rewards after a dispute is resolved.
     * @dev This function is internal and called by `resolveDispute`.
     * @param _claimId The ID of the disputed claim.
     * @param _outcome The resolved outcome of the dispute (Yes = True, No = False).
     */
    function _distributeStakesAndRewards(uint256 _claimId, VoteOption _outcome) internal {
        KnowledgeClaim storage claim = claims[_claimId];
        Dispute storage dispute = disputes[_claimId]; // Get the dispute associated with this claim
        require(dispute.claimId == _claimId, "DKB: Internal error, dispute mismatch");

        // Calculate total stakes from involved parties in the dispute
        // For simplicity, assume all stakes on the claim participate in the potential slashing/reward pool
        // A more complex model might only include stakes active *during* the dispute
        uint256 totalStakePool = 0;
        for (uint i = 0; i < claim.stakerAddresses.length; i++) {
            address stakerAddress = claim.stakerAddresses[i];
            ClaimStake storage stake = claim.stakes[stakerAddress];
            if (!stake.withdrawn) { // Only consider stakes not yet withdrawn
                 totalStakePool += stake.amount;
            }
        }

        uint256 totalSlashingPool = 0;
        mapping(address => uint256) winningStakes; // Stakes to be returned to winners

        // Determine winning/losing sides based on dispute outcome
        bool challengerWon = (_outcome == VoteOption.No); // If outcome is 'No' (False), challenger was right
        bool submitterEndorserWon = (_outcome == VoteOption.Yes); // If outcome is 'Yes' (True), submitter/endorsers were right

        // Process stakes
        for (uint i = 0; i < claim.stakerAddresses.length; i++) {
            address stakerAddress = claim.stakerAddresses[i];
            ClaimStake storage stake = claim.stakes[stakerAddress];

            if (stake.amount == 0 || stake.withdrawn) continue; // Skip if no stake or already processed

            bool stakerWasWinner = false;
            if (submitterEndorserWon && (stake.stakeType == StakeType.Submit || stake.stakeType == StakeType.Endorse)) {
                stakerWasWinner = true;
            } else if (challengerWon && stake.stakeType == StakeType.Challenge) {
                stakerWasWinner = true;
            }

            if (stakerWasWinner) {
                winningStakes[stakerAddress] += stake.amount; // Return their full stake
                // Reputation boost handled below
            } else {
                // Losers get slashed
                uint256 slashedAmount = (stake.amount * config.disputeSlashPercentage) / 100;
                totalSlashingPool += slashedAmount;
                winningStakes[stakerAddress] += stake.amount - slashedAmount; // Return remaining stake
                // Reputation slash handled below
            }
        }

        // Process voters (Jury)
        uint256 totalWinningVoterReputation = 0;
        for (uint i = 0; i < dispute.voterAddresses.length; i++) {
            address voterAddress = dispute.voterAddresses[i];
            DisputeVote storage vote = dispute.votes[voterAddress];

            bool voterWasWinner = false;
            if (submitterEndorserWon && vote.vote == VoteOption.Yes) {
                voterWasWinner = true;
            } else if (challengerWon && vote.vote == VoteOption.No) {
                 voterWasWinner = true;
            }

            if (voterWasWinner) {
                 totalWinningVoterReputation += vote.reputationWeight;
                 // Reputation boost handled below
            } else {
                 // Reputation slash handled below
            }
        }

        // Calculate reward pool for winning voters/jury
        uint256 voterRewardPool = (totalSlashingPool * config.disputeRewardPercentage) / 100;
        uint256 remainingSlashingPool = totalSlashingPool - voterRewardPool; // The rest is burned or goes to protocol treasury

        // Distribute voter rewards based on winning reputation weight
        for (uint i = 0; i < dispute.voterAddresses.length; i++) {
            address voterAddress = dispute.voterAddresses[i];
            DisputeVote storage vote = dispute.votes[voterAddress];

             bool voterWasWinner = false;
            if (submitterEndorserWon && vote.vote == VoteOption.Yes) {
                voterWasWinner = true;
            } else if (challengerWon && vote.vote == VoteOption.No) {
                 voterWasWinner = true;
            }

            if (voterWasWinner && totalWinningVoterReputation > 0) {
                uint256 rewardShare = (voterRewardPool * vote.reputationWeight) / totalWinningVoterReputation;
                userReputation[voterAddress].rewardsAvailable += rewardShare;
            }
        }

        // Update Reputations based on outcome and stakes/votes
        // Simple linear scale based on stake/reputation amount involved
        uint256 reputationChangeScale = 1; // Can be adjusted
        // Stakes
        for (uint i = 0; i < claim.stakerAddresses.length; i++) {
            address stakerAddress = claim.stakerAddresses[i];
            ClaimStake storage stake = claim.stakes[stakerAddress];
            if (stake.amount == 0 || stake.withdrawn) continue;

             bool stakerWasWinner = false;
            if (submitterEndorserWon && (stake.stakeType == StakeType.Submit || stake.stakeType == StakeType.Endorse)) {
                stakerWasWinner = true;
            } else if (challengerWon && stake.stakeType == StakeType.Challenge) {
                stakerWasWinner = true;
            }

            if (stakerWasWinner) {
                // Reputation gain for correct staking
                 uint256 reputationGain = (stake.amount * reputationChangeScale) / config.minEndorseStake; // Scale by stake amount relative to min
                _updateReputation(stakerAddress, reputationGain);
            } else {
                // Reputation loss for incorrect staking
                 uint256 reputationLoss = (stake.amount * reputationChangeScale) / config.minEndorseStake; // Scale by stake amount relative to min
                _updateReputation(stakerAddress, reputationLoss > userReputation[stakerAddress].score ? userReputation[stakerAddress].score : reputationLoss * -1); // Don't go below 0
            }
             // Mark stake as processed for distribution
             stake.withdrawn = true; // Mark as withdrawn AFTER calculation
        }

        // Voters
        for (uint i = 0; i < dispute.voterAddresses.length; i++) {
            address voterAddress = dispute.voterAddresses[i];
            DisputeVote storage vote = dispute.votes[v voterAddress];
            // Reputation change already factored in vote.reputationWeight during the vote.
            // Could add a *further* reputation change based on *whether* they voted correctly.
            // Let's add a simple fixed amount for correct voters.
             bool voterWasWinner = false;
            if (submitterEndorserWon && vote.vote == VoteOption.Yes) {
                voterWasWinner = true;
            } else if (challengerWon && vote.vote == VoteOption.No) {
                 voterWasWinner = true;
            }
            if (voterWasWinner) {
                 _updateReputation(voterAddress, reputationChangeScale * 5); // Gain 5 points for correct vote
            } else {
                 _updateReputation(voterAddress, reputationChangeScale * -2); // Lose 2 points for incorrect vote
            }
        }


        // Transfer winning stakes back
        for (uint i = 0; i < claim.stakerAddresses.length; i++) {
             address stakerAddress = claim.stakerAddresses[i];
             if (winningStakes[stakerAddress] > 0) {
                  token.safeTransfer(stakerAddress, winningStakes[stakerAddress]);
             }
        }

        // The remainingSlashingPool stays in the contract (could be burned or held for future distribution/governance)
    }


    // --- Reputation Management (Internal) ---

    /**
     * @notice Updates a user's reputation score.
     * @dev This is an internal helper function. Use positive value to increase, negative to decrease.
     * @param _user The address of the user.
     * @param _change The amount of reputation to add or subtract.
     */
    function _updateReputation(address _user, int256 _change) internal {
        UserReputation storage rep = userReputation[_user];
        uint256 oldScore = rep.score;

        if (_change > 0) {
            rep.score += uint256(_change);
            _totalReputation += uint256(_change);
        } else if (_change < 0) {
            uint256 decreaseAmount = uint256(-_change);
            if (rep.score < decreaseAmount) {
                _totalReputation -= rep.score; // Subtract full current score
                rep.score = 0;
            } else {
                rep.score -= decreaseAmount;
                _totalReputation -= decreaseAmount;
            }
        }

        if (rep.score != oldScore) {
             emit ReputationUpdated(_user, rep.score);
        }
    }


    // --- Query Functions (View) ---

    /**
     * @notice Retrieves a user's current reputation score.
     * @param _user The address of the user.
     * @return The user's reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputation[_user].score;
    }

    /**
     * @notice Retrieves the details of a specific knowledge claim.
     * @param _claimId The ID of the claim.
     * @return The claim details.
     */
    function getClaimDetails(uint256 _claimId) external view returns (
        address submitter,
        string memory ipfsHash,
        ClaimStatus status,
        uint256 submitStake,
        uint256 totalEndorseStake,
        uint256 totalChallengeStake,
        uint256 claimReputation,
        uint48 timestamp
    ) {
        KnowledgeClaim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "DKB: Claim does not exist");
        return (
            claim.submitter,
            claim.ipfsHash,
            claim.status,
            claim.submitStake,
            claim.totalEndorseStake,
            claim.totalChallengeStake,
            claim.claimReputation,
            claim.timestamp
        );
    }

     /**
     * @notice Retrieves the number of stakes of a specific type on a claim.
     * @param _claimId The ID of the claim.
     * @param _type The type of stake (Submit, Endorse, Challenge).
     * @return The count of stakes of that type.
     */
    function getClaimStakeCount(uint256 _claimId, StakeType _type) external view returns (uint256) {
         KnowledgeClaim storage claim = claims[_claimId];
         require(claim.submitter != address(0), "DKB: Claim does not exist");
         uint256 count = 0;
         for(uint i = 0; i < claim.stakerAddresses.length; i++) {
             address staker = claim.stakerAddresses[i];
             if (claim.stakes[staker].stakeType == _type && claim.stakes[staker].amount > 0) {
                 count++;
             }
         }
         return count;
    }


    /**
     * @notice Retrieves the details of a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @return The dispute details.
     */
    function getDisputeDetails(uint256 _disputeId) external view returns (
        uint256 claimId,
        address challenger,
        DisputeStatus status,
        uint48 startTime,
        uint48 endTime,
        uint256 yesVotes,
        uint256 noVotes,
        VoteOption outcome
    ) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.claimId != 0, "DKB: Dispute does not exist");
        return (
            dispute.claimId,
            dispute.challenger,
            dispute.status,
            dispute.startTime,
            dispute.endTime,
            dispute.yesVotes,
            dispute.noVotes,
            dispute.outcome
        );
    }

    /**
     * @notice Retrieves a user's stake details on a specific claim.
     * @param _claimId The ID of the claim.
     * @param _user The address of the user.
     * @return The stake details.
     */
    function getStakeDetails(uint256 _claimId, address _user) external view returns (
        StakeType stakeType,
        uint256 amount,
        uint48 timestamp,
        bool withdrawn
    ) {
        KnowledgeClaim storage claim = claims[_claimId];
        require(claim.submitter != address(0), "DKB: Claim does not exist");
        ClaimStake storage stake = claim.stakes[_user];
        // Note: If user has no stake, amount will be 0 and stakeType will be default (0/Submit)
        return (
            stake.stakeType,
            stake.amount,
            stake.timestamp,
            stake.withdrawn
        );
    }

    /**
     * @notice Retrieves a user's vote details in a specific dispute.
     * @param _disputeId The ID of the dispute.
     * @param _user The address of the user.
     * @return The vote details.
     */
    function getDisputeVote(uint256 _disputeId, address _user) external view returns (
        VoteOption vote,
        uint256 reputationWeight
    ) {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.claimId != 0, "DKB: Dispute does not exist");
        DisputeVote storage userVote = dispute.votes[_user];
         // Note: If user hasn't voted, reputationWeight will be 0 and vote will be default (0/Abstain)
        return (
            userVote.vote,
            userVote.reputationWeight
        );
    }


    /**
     * @notice Checks the amount of rewards available for a user to claim.
     * @param _user The address of the user.
     * @return The amount of available rewards.
     */
    function getUserRewardsAvailable(address _user) external view returns (uint256) {
        return userReputation[_user].rewardsAvailable;
    }

     /**
     * @notice Gets the address of the submitter of a claim.
     * @param _claimId The ID of the claim.
     * @return The submitter's address.
     */
    function getClaimSubmitter(uint256 _claimId) external view returns (address) {
         KnowledgeClaim storage claim = claims[_claimId];
         require(claim.submitter != address(0), "DKB: Claim does not exist");
         return claim.submitter;
     }

     /**
     * @notice Gets the address of the challenger in a dispute.
     * @param _disputeId The ID of the dispute.
     * @return The challenger's address.
     */
     function getDisputeChallenger(uint256 _disputeId) external view returns (address) {
         Dispute storage dispute = disputes[_disputeId];
         require(dispute.claimId != 0, "DKB: Dispute does not exist");
         return dispute.challenger;
     }

     /**
     * @notice Checks if a user is eligible to vote in a given dispute based on reputation threshold.
     * @param _disputeId The ID of the dispute.
     * @param _user The address of the user.
     * @return True if eligible, false otherwise.
     */
    function isEligibleToVoteInDispute(uint256 _disputeId, address _user) external view returns (bool) {
         Dispute storage dispute = disputes[_disputeId];
         require(dispute.claimId != 0, "DKB: Dispute does not exist");
         // Must not have already voted
         if (dispute.votes[_user].reputationWeight > 0) return false;
         // Must meet reputation threshold
         return userReputation[_user].score >= config.disputeVoteReputationThreshold;
    }


    // --- Governance Functions ---

    /**
     * @notice Allows users with sufficient reputation to submit a governance proposal.
     * @param _description A description of the proposal.
     * @param _targetContract The address of the contract to call (usually self for config changes).
     * @param _callData The calldata for the function call on the target contract.
     */
    function submitGovernanceProposal(
        string memory _description,
        address _targetContract,
        bytes memory _callData
    ) external checkGovernanceEligibility(msg.sender, true) {
        _proposalCounter++;
        uint256 newProposalId = _proposalCounter;

        governanceProposals[newProposalId] = GovernanceProposal({
            description: _description,
            targetContract: _targetContract,
            callData: _callData,
            status: ProposalStatus.Pending, // Could require manual activation or threshold
            startTime: uint48(block.timestamp), // Starts active immediately
            endTime: uint48(block.timestamp + config.governanceVotingPeriod),
            yesReputationWeight: 0,
            noReputationWeight: 0,
            totalReputationWeight: 0,
            proposalStake: userReputation[msg.sender].score // Snapshot proposer's reputation as stake
        });

        // Transition to active state immediately for simplicity
        governanceProposals[newProposalId].status = ProposalStatus.Active;
        emit GovernanceProposalSubmitted(newProposalId, msg.sender, _description);
        emit GovernanceProposalStatusUpdated(newProposalId, ProposalStatus.Active);
    }

    /**
     * @notice Allows eligible users to vote on an active governance proposal.
     * @param _proposalId The ID of the proposal.
     * @param _vote The user's vote (Yes = Approve, No = Reject).
     */
    function voteOnGovernanceProposal(uint256 _proposalId, VoteOption _vote)
        external checkGovernanceEligibility(msg.sender, false) // No stake required to vote, only reputation
    {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "DKB: Proposal not active");
        require(block.timestamp < proposal.endTime, "DKB: Voting period ended");
        require(_vote == VoteOption.Yes || _vote == VoteOption.No, "DKB: Invalid vote option");
        require(proposal.votes[msg.sender].reputationWeight == 0, "DKB: User already voted on this proposal");

        uint256 voterReputation = userReputation[msg.sender].score;
        require(voterReputation > 0, "DKB: Voter must have reputation"); // Redundant check due to modifier, but good practice

        proposal.votes[msg.sender] = ProposalVote({
            vote: _vote,
            reputationWeight: voterReputation
        });
        proposal.voterAddresses.push(msg.sender);
        proposal.totalReputationWeight += voterReputation;

        if (_vote == VoteOption.Yes) {
            proposal.yesReputationWeight += voterReputation;
        } else {
            proposal.noReputationWeight += voterReputation;
        }

        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote, voterReputation);

        // Check for immediate outcome if quorum/threshold met early (optional)
        // For simplicity, we resolve only after the voting period ends
    }

    /**
     * @notice Triggers the execution of a governance proposal that has passed.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceProposal(uint256 _proposalId) external onlyGovExecutor(_proposalId) {
         GovernanceProposal storage proposal = governanceProposals[_proposalId];
         require(proposal.targetContract != address(0), "DKB: Invalid target contract");
         require(proposal.callData.length > 0, "DKB: Empty call data");

         // Execute the call
         (bool success, ) = proposal.targetContract.call(proposal.callData);
         require(success, "DKB: Proposal execution failed");

         proposal.status = ProposalStatus.Executed;
         emit GovernanceProposalExecuted(_proposalId);
    }

    /**
     * @notice Resolves the outcome of a governance proposal after the voting period ends.
     *         This must be called before `executeGovernanceProposal`.
     * @param _proposalId The ID of the proposal to resolve.
     */
    function resolveGovernanceProposal(uint256 _proposalId) external {
         GovernanceProposal storage proposal = governanceProposals[_proposalId];
         require(proposal.status == ProposalStatus.Active, "DKB: Proposal not active");
         require(block.timestamp >= proposal.endTime, "DKB: Voting period not ended");

         // Check Quorum: Total reputation voted must be >= Quorum % of total *current* protocol reputation
         uint256 quorumThreshold = (_totalReputation * config.governanceQuorumNumerator) / 100;
         bool quorumReached = proposal.totalReputationWeight >= quorumThreshold;

         // Check Threshold: Yes votes must be >= Threshold % of total *voted* reputation
         uint256 voteThreshold = (proposal.totalReputationWeight * config.governanceThresholdNumerator) / 10; // Note: denominator 10 for 50% threshold from numerator 5
         bool thresholdReached = proposal.yesReputationWeight >= voteThreshold;

         if (quorumReached && thresholdReached) {
             proposal.status = ProposalStatus.Succeeded;
         } else {
             proposal.status = ProposalStatus.Defeated;
         }

         emit GovernanceProposalStatusUpdated(_proposalId, proposal.status);
         // Proposer's stake (reputation) could be returned/slashed based on outcome - omitted for simplicity
    }


    // --- Governance Configuration (Callable only by successful governance proposals) ---

    /**
     * @notice Updates a specific configuration parameter. Callable only via governance execution.
     * @param _paramName The name of the parameter to update (e.g., "minSubmitStake").
     * @param _newValue The new value for the parameter.
     */
    function updateConfigParameter(bytes32 _paramName, uint256 _newValue) external {
        // This function is designed to be called ONLY by a successful governance proposal (via `executeGovernanceProposal`)
        // A simple require(msg.sender == address(this)) check here would prevent external calls,
        // BUT the call comes from `address(this).call(calldata)`, so msg.sender *is* address(this).
        // A more robust check would involve tracking if the call originated from a valid proposal execution context,
        // but for this example, relying on it being called internally by executeGovernanceProposal is sufficient.
        // Add a basic check to prevent accidental external calls, relying on the governance flow.
        require(msg.sender == address(this), "DKB: Config update only via governance execution");

        // Add checks for valid ranges of _newValue for each parameter name
        if (_paramName == "minSubmitStake") {
            config.minSubmitStake = _newValue;
        } else if (_paramName == "minEndorseStake") {
            config.minEndorseStake = _newValue;
        } else if (_paramName == "minChallengeStake") {
            config.minChallengeStake = _newValue;
        } else if (_paramName == "disputeVotingPeriod") {
            config.disputeVotingPeriod = uint48(_newValue);
        } else if (_paramName == "disputeVoteReputationThreshold") {
            config.disputeVoteReputationThreshold = _newValue;
        } else if (_paramName == "governanceProposalStake") {
            config.governanceProposalStake = _newValue;
        } else if (_paramName == "governanceVotingPeriod") {
            config.governanceVotingPeriod = uint48(_newValue);
        } else if (_paramName == "governanceQuorumNumerator") {
            require(_newValue <= 100, "DKB: Quorum numerator invalid");
            config.governanceQuorumNumerator = _newValue;
        } else if (_paramName == "governanceThresholdNumerator") {
             require(_newValue <= 10, "DKB: Threshold numerator invalid"); // Assuming threshold is out of 10
            config.governanceThresholdNumerator = _newValue;
        } else if (_paramName == "disputeSlashPercentage") {
             require(_newValue <= 100, "DKB: Slash percentage invalid");
            config.disputeSlashPercentage = _newValue;
        } else if (_paramName == "disputeRewardPercentage") {
             require(_newValue <= 100, "DKB: Reward percentage invalid");
            config.disputeRewardPercentage = _newValue;
        } else if (_paramName == "submitterRewardPercentage") {
             require(_newValue <= 100, "DKB: Submitter reward percentage invalid");
            config.submitterRewardPercentage = _newValue;
        }
        // Add more parameters as needed

        emit ConfigUpdated(_paramName, _newValue);
    }


    // --- Governance Query Functions (View) ---

    /**
     * @notice Retrieves the details of a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @return The proposal details.
     */
    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (
        string memory description,
        address targetContract,
        bytes memory callData,
        ProposalStatus status,
        uint48 startTime,
        uint48 endTime,
        uint256 yesReputationWeight,
        uint256 noReputationWeight,
        uint256 totalReputationWeight,
        uint256 proposalStake
    ) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(bytes(proposal.description).length > 0, "DKB: Proposal does not exist");
        return (
            proposal.description,
            proposal.targetContract,
            proposal.callData,
            proposal.status,
            proposal.startTime,
            proposal.endTime,
            proposal.yesReputationWeight,
            proposal.noReputationWeight,
            proposal.totalReputationWeight,
            proposal.proposalStake
        );
    }

    /**
     * @notice Retrieves a user's vote details on a specific governance proposal.
     * @param _proposalId The ID of the proposal.
     * @param _user The address of the user.
     * @return The vote details.
     */
    function getUserProposalVote(uint256 _proposalId, address _user) external view returns (
        VoteOption vote,
        uint256 reputationWeight
    ) {
         GovernanceProposal storage proposal = governanceProposals[_proposalId];
         require(bytes(proposal.description).length > 0, "DKB: Proposal does not exist");
         ProposalVote storage userVote = proposal.votes[_user];
          // Note: If user hasn't voted, reputationWeight will be 0 and vote will be default (0/Abstain)
         return (
             userVote.vote,
             userVote.reputationWeight
         );
    }

    /**
     * @notice Checks if a user is eligible to submit a governance proposal based on reputation stake.
     * @param _user The address of the user.
     * @return True if eligible, false otherwise.
     */
    function isEligibleToSubmitProposal(address _user) external view returns (bool) {
        return userReputation[_user].score >= config.governanceProposalStake;
    }

     /**
     * @notice Checks if a user is eligible to vote on governance proposals based on reputation.
     * @param _user The address of the user.
     * @return True if eligible, false otherwise.
     */
    function isEligibleToVoteOnProposal(address _user) external view returns (bool) {
         return userReputation[_user].score > 0; // Simple check: any reputation allows voting
    }

    /**
     * @notice Retrieves the current configuration parameters of the protocol.
     * @return The current configuration struct.
     */
    function getProtocolConfig() external view returns (ProtocolConfig memory) {
        return config;
    }

    // Note: Functions to list claims/disputes/proposals by status or ID range would require
    // storing IDs in dynamic arrays or more complex mappings, which adds gas cost.
    // For this example, direct ID lookup is used. Listing would add several more functions.
    // E.g., `getClaimIdsByStatus(ClaimStatus _status)`, `getDisputeIdsByStatus(DisputeStatus _status)`, etc.
    // We have met the 20+ function requirement without these.

    // Missing:
    // - Detailed error handling and require messages for all functions.
    // - More complex reputation calculation (decay, different weights).
    // - Handling of edge cases (e.g., what happens if totalReputationWeight is 0 in governance?).
    // - More sophisticated slashing/reward distribution proportional to stake/reputation.
    // - Potential integration with oracles for external truth verification.
    // - Pausability/Upgradeability patterns.
    // - Security considerations (re-entrancy, etc. - SafeERC20 helps here).
    // - More robust proposal execution (e.g., queuing, multi-step execution).
    // - Token implementation if the contract mints its own token. (Here, assuming external ERC20).

}
```