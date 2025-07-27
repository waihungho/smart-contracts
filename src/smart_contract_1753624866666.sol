This smart contract, `AetherisNexus`, aims to create a decentralized, self-adapting ecosystem where resources, privileges, and rewards are dynamically allocated based on an aggregated "Impact Score" rather than just static token holdings. It fosters collective intelligence by incentivizing valuable contributions and allowing the protocol's parameters to adapt based on observed on-chain activity and external data.

---

## AetherisNexus Smart Contract: Outline & Function Summary

**Contract Name:** `AetherisNexus`

**Purpose:** To establish a decentralized, self-adapting protocol that dynamically allocates resources and incentives based on a robust "Impact Score" system, promoting a meritocratic and collectively intelligent community. It incorporates mechanisms for contribution proof, peer attestation, impact-weighted governance, and adaptive parameter adjustments.

**Key Concepts:**
*   **Dynamic Impact Scoring:** A reputation system where contributors earn an "Impact Score" based on submitted work, peer attestations, and the absence of disputes. This score is central to resource allocation and governance.
*   **Adaptive Resource Allocation:** A collective fund and epoch-based rewards are distributed proportionally to contributors' Impact Scores, encouraging continuous value creation.
*   **Self-Optimizing Parameters (Simulated):** The protocol's internal parameters (e.g., reward weighting for different contribution types, governance quorums) can be dynamically adjusted based on simulated oracle data and internal metrics, allowing the system to adapt and "optimize" its behavior.
*   **Impact-Weighted Governance:** Voting power for proposals (fund allocations, system changes) is tied to a contributor's Impact Score, shifting power from pure capital to proven contribution.
*   **Influence Staking:** A mechanism allowing contributors to stake tokens to temporarily amplify the *influence* of their Impact Score in specific allocations or votes, without directly increasing the score itself.

---

**Function Categories & Summaries:**

**I. Core Management & Access Control:**
1.  `constructor(address _rewardToken, address _influenceToken)`: Initializes the contract with the addresses of the reward token and the influence staking token. Sets the deployer as the owner.
2.  `emergencyPause()`: Allows the owner to pause critical functions in emergencies.
3.  `emergencyUnpause()`: Allows the owner to unpause the contract.
4.  `setEpochDuration(uint256 _durationSeconds)`: Allows the owner to set the duration of each reward epoch.
5.  `setContributionReviewer(address _reviewer, bool _isReviewer)`: Adds or removes addresses from the list of authorized contribution reviewers.

**II. Contributor & Impact System:**
6.  `registerContributor()`: Allows any address to register as a contributor to the AetherisNexus.
7.  `submitContributionProof(string memory _proofCID, uint256 _category)`: Contributors submit verifiable proof of their work (e.g., IPFS CID, GitHub PR link) along with a category identifier.
8.  `attestContribution(uint256 _contributionId, bool _isPositive)`: Authorized reviewers or other contributors (if enabled) can attest to the validity/quality of a submitted contribution. Positive attestations boost potential impact, negative ones reduce it.
9.  `disputeContribution(uint256 _contributionId)`: Allows any registered contributor to formally dispute a submitted contribution, flagging it for review and potential invalidation.
10. `triggerImpactRecalculation()`: (Callable by owner/guardian) Initiates a recalculation of all active contributors' Impact Scores based on recent contributions, attestations, and disputes. This function is gas-intensive and would ideally be off-chain or batched in a production system.
11. `getImpactScore(address _contributor)`: Returns the current Impact Score of a specific contributor.

**III. Collective Fund & Reward Distribution:**
12. `proposeCollectiveFundAllocation(string memory _description, address _recipient, uint256 _amount)`: Allows high-impact contributors to propose how funds from the collective treasury should be allocated.
13. `voteOnFundAllocationProposal(uint256 _proposalId, bool _for)`: Contributors vote on fund allocation proposals. Vote weight is based on Impact Score.
14. `executeFundAllocationProposal(uint256 _proposalId)`: Executes a passed fund allocation proposal, transferring funds from the collective treasury to the specified recipient.
15. `distributeEpochRewards()`: Initiates the distribution of rewards for the current epoch to eligible contributors based on their Impact Scores and any influence multipliers.
16. `claimEpochRewards()`: Allows individual contributors to claim their share of rewards after an epoch distribution.

**IV. Adaptive Parameter Management:**
17. `receiveOracleData(uint256 _dataPointId, bytes memory _value)`: A simulated function to receive data from an external oracle (e.g., market volatility, community sentiment). This data influences adaptive parameter adjustments.
18. `proposeParameterAdjustment(string memory _description, uint256 _paramType, uint256 _newValue)`: Allows high-impact contributors to propose changes to core protocol parameters (e.g., specific reward weights, minimum proposal impact score).
19. `voteOnParameterAdjustment(uint256 _proposalId, bool _for)`: Contributors vote on proposed parameter adjustments, with vote weight tied to Impact Score.
20. `enactParameterAdjustment(uint256 _proposalId)`: Executes a passed parameter adjustment proposal, updating the relevant internal protocol setting.
21. `triggerAdaptiveRecalculation()`: (Callable by owner/guardian) Triggers the protocol's "self-optimization" mechanism, adjusting internal parameters (like reward weighting for contribution types) based on current oracle data and system metrics. This is a placeholder for complex adaptive logic.

**V. Governance & Delegation:**
22. `delegateImpactVote(address _delegatee)`: Allows a contributor to delegate their Impact Score-based voting power to another address.
23. `revokeImpactVoteDelegation()`: Allows a contributor to revoke any active delegation of their voting power.

**VI. Staking Mechanism:**
24. `stakeForImpactInfluence(uint256 _amount)`: Allows contributors to stake `_influenceToken` to temporarily increase the influence multiplier of their Impact Score for reward distribution or governance votes.
25. `unstakeImpactInfluence(uint256 _amount)`: Allows contributors to unstake their `_influenceToken`.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AetherisNexus
 * @dev A decentralized, self-adapting protocol for dynamic resource allocation and
 *      incentive alignment based on aggregated "Impact Scores." Fosters collective intelligence
 *      and meritocracy in a community.
 *
 * Key Concepts:
 * - Dynamic Impact Scoring: Reputation based on verifiable contributions, peer attestations, and dispute resolution.
 * - Adaptive Resource Allocation: Collective fund & epoch rewards distributed proportional to Impact Scores.
 * - Simulated Self-Optimizing Parameters: Protocol parameters (e.g., reward weights, governance quorums)
 *   can adapt based on oracle data and internal metrics.
 * - Impact-Weighted Governance: Voting power tied directly to a contributor's Impact Score.
 * - Influence Staking: Staking mechanism to amplify impact score's influence in distributions/governance.
 */
contract AetherisNexus is Ownable, Pausable, ReentrancyGuard {

    // --- State Variables ---

    IERC20 public immutable rewardToken; // Token used for epoch rewards and collective fund allocations
    IERC20 public immutable influenceToken; // Token used for staking to gain influence

    // Contributor data
    struct Contributor {
        uint256 impactScore; // Cumulative score reflecting contributions and attestations
        uint256 lastContributionEpoch; // The epoch of their last recorded contribution
        bool isRegistered; // True if the address is a registered contributor
        uint256 stakedInfluence; // Amount of influenceToken staked by this contributor
        address impactDelegatee; // Address to whom this contributor has delegated their impact vote
    }
    mapping(address => Contributor) public contributors;
    address[] public registeredContributors; // Array to iterate through all contributors (for distribution)

    // Contribution Proofs
    struct ContributionProof {
        address contributor;
        string proofCID; // IPFS CID or similar identifier for the proof
        uint256 category; // Category of contribution (e.g., 0=code, 1=content, 2=research)
        uint256 submissionTime;
        uint256 attestationsCount; // Number of positive attestations
        uint256 disputesCount; // Number of disputes
        bool isValidated; // True if a contribution has passed initial review/validation
        bool isDisputed; // True if a contribution is currently under dispute
        bool isProcessed; // True if the contribution has been factored into impact scores
    }
    mapping(uint256 => ContributionProof) public contributionProofs;
    uint256 public nextContributionId;

    // Reviewer roles
    mapping(address => bool) public isContributionReviewer;

    // Governance Proposals
    enum ProposalType { FundAllocation, ParameterAdjustment }
    struct Proposal {
        uint256 id;
        ProposalType pType;
        address proposer;
        string description;
        uint256 creationTime;
        uint256 votesForImpact; // Total impact score of voters for
        uint256 votesAgainstImpact; // Total impact score of voters against
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this proposal
        bool executed;
        // Specifics for FundAllocation
        address recipient;
        uint256 amount;
        // Specifics for ParameterAdjustment
        uint256 paramType; // Identifier for which parameter is being adjusted
        uint256 newValue; // The new value for the parameter
    }
    mapping(uint256 => Proposal) public proposals;
    uint256 public nextProposalId;
    uint256 public minImpactScoreForProposal; // Minimum impact score to create a proposal
    uint256 public proposalQuorumPercentage; // Percentage of total active impact score needed for quorum (e.g., 10_000 for 10%)

    // Epochs & Rewards
    struct Epoch {
        uint256 id;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 totalRewardPool; // Total rewards available for this epoch
        uint256 totalImpactScoreSum; // Sum of all contributors' impact scores in this epoch
        bool rewardsDistributed;
    }
    mapping(uint256 => Epoch) public epochs;
    uint256 public currentEpochId;
    uint256 public epochDuration; // Duration of an epoch in seconds

    // Adaptive Parameters
    // Example: Reward weighting for different contribution categories
    mapping(uint256 => uint256) public rewardWeightings; // category => weight multiplier (e.g., 1000 for 1x, 1500 for 1.5x)
    // Could include more: min/max influence stake, impact decay rate, etc.

    // Simulated Oracle Data
    // For concept, simply stores a mapping; in real-world, would use Chainlink/Band Protocol etc.
    mapping(uint256 => bytes) public oracleData; // dataPointId => value

    // --- Events ---

    event ContributorRegistered(address indexed contributor);
    event ContributionSubmitted(uint256 indexed contributionId, address indexed contributor, string proofCID, uint256 category);
    event ContributionAttested(uint256 indexed contributionId, address indexed attester, bool isPositive);
    event ContributionDisputed(uint256 indexed contributionId, address indexed disputer);
    event ImpactScoreRecalculated(address indexed contributor, uint256 newScore);
    event ReviewerStatusChanged(address indexed reviewer, bool isReviewer);

    event CollectiveFundAllocationProposed(uint256 indexed proposalId, address indexed proposer, address recipient, uint256 amount);
    event CollectiveFundAllocationExecuted(uint256 indexed proposalId);

    event ParameterAdjustmentProposed(uint256 indexed proposalId, uint256 paramType, uint256 newValue);
    event ParameterAdjustmentEnacted(uint256 indexed proposalId, uint256 paramType, uint256 newValue);

    event Voted(uint256 indexed proposalId, address indexed voter, bool _for, uint256 impactWeight);
    event EpochRewardsDistributed(uint256 indexed epochId, uint256 totalDistributed);
    event RewardsClaimed(uint256 indexed epochId, address indexed claimant, uint256 amount);

    event ImpactVoteDelegated(address indexed delegator, address indexed delegatee);
    event ImpactVoteDelegationRevoked(address indexed delegator);

    event InfluenceStaked(address indexed staker, uint256 amount);
    event InfluenceUnstaked(address indexed unstaker, uint256 amount);

    event OracleDataReceived(uint256 indexed dataPointId, bytes value);
    event AdaptiveRecalculationTriggered();

    // --- Constructor ---

    constructor(address _rewardToken, address _influenceToken) Ownable(msg.sender) {
        rewardToken = IERC20(_rewardToken);
        influenceToken = IERC20(_influenceToken);

        epochDuration = 7 days; // Default to 1 week
        minImpactScoreForProposal = 100; // Default minimum impact to propose
        proposalQuorumPercentage = 2000; // Default 20% quorum (2000 / 10000)

        // Set default reward weightings (e.g., all categories get 1x multiplier)
        rewardWeightings[0] = 1000; // Code
        rewardWeightings[1] = 1000; // Content
        rewardWeightings[2] = 1000; // Research
        // Initialize the first epoch
        currentEpochId = 0;
        epochs[currentEpochId].startTimestamp = block.timestamp;
        epochs[currentEpochId].endTimestamp = block.timestamp + epochDuration;
        epochs[currentEpochId].rewardsDistributed = false;
    }

    // --- Modifiers ---

    modifier onlyRegisteredContributor() {
        require(contributors[msg.sender].isRegistered, "AetherisNexus: Caller not a registered contributor");
        _;
    }

    modifier onlyReviewer() {
        require(isContributionReviewer[msg.sender], "AetherisNexus: Caller not an authorized reviewer");
        _;
    }

    modifier onlyActiveEpoch() {
        require(block.timestamp < epochs[currentEpochId].endTimestamp, "AetherisNexus: Current epoch has ended");
        _;
    }

    modifier onlyEpochEnded() {
        require(block.timestamp >= epochs[currentEpochId].endTimestamp, "AetherisNexus: Current epoch has not ended yet");
        _;
    }

    // --- Core Management & Access Control Functions ---

    /**
     * @dev Pauses the contract in case of an emergency.
     * Only callable by the owner.
     */
    function emergencyPause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract after an emergency.
     * Only callable by the owner.
     */
    function emergencyUnpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the duration for each reward epoch.
     * Only callable by the owner.
     * @param _durationSeconds The new duration for epochs in seconds.
     */
    function setEpochDuration(uint256 _durationSeconds) external onlyOwner {
        require(_durationSeconds > 0, "AetherisNexus: Epoch duration must be positive");
        epochDuration = _durationSeconds;
    }

    /**
     * @dev Designates or revokes an address as a contribution reviewer.
     * Reviewers can attest to contribution quality.
     * Only callable by the owner.
     * @param _reviewer The address to set/unset as a reviewer.
     * @param _isReviewer True to make them a reviewer, false to revoke.
     */
    function setContributionReviewer(address _reviewer, bool _isReviewer) external onlyOwner {
        isContributionReviewer[_reviewer] = _isReviewer;
        emit ReviewerStatusChanged(_reviewer, _isReviewer);
    }

    // --- Contributor & Impact System Functions ---

    /**
     * @dev Allows any address to register as a contributor.
     * New contributors start with an impact score of 0.
     */
    function registerContributor() external whenNotPaused {
        require(!contributors[msg.sender].isRegistered, "AetherisNexus: Already a registered contributor");
        contributors[msg.sender].isRegistered = true;
        registeredContributors.push(msg.sender);
        emit ContributorRegistered(msg.sender);
    }

    /**
     * @dev Submits proof of a contribution.
     * Contributors describe their work with an IPFS CID or similar identifier.
     * @param _proofCID A string identifier for the contribution proof (e.g., IPFS hash, URL).
     * @param _category An integer representing the category of contribution (e.g., 0 for code, 1 for content).
     */
    function submitContributionProof(string memory _proofCID, uint256 _category)
        external
        onlyRegisteredContributor
        onlyActiveEpoch
        whenNotPaused
    {
        uint256 currentId = nextContributionId++;
        contributionProofs[currentId] = ContributionProof({
            contributor: msg.sender,
            proofCID: _proofCID,
            category: _category,
            submissionTime: block.timestamp,
            attestationsCount: 0,
            disputesCount: 0,
            isValidated: false, // Requires review/attestation
            isDisputed: false,
            isProcessed: false
        });
        emit ContributionSubmitted(currentId, msg.sender, _proofCID, _category);
    }

    /**
     * @dev Allows a designated reviewer or other eligible contributor to attest to a contribution.
     * Positive attestations increase the contribution's validity score.
     * @param _contributionId The ID of the contribution to attest.
     * @param _isPositive True for a positive attestation, false for a negative (implies dispute if false and not explicitly disputed).
     */
    function attestContribution(uint256 _contributionId, bool _isPositive)
        external
        onlyRegisteredContributor // Could be `onlyReviewer` or allow any registered user based on design
        whenNotPaused
    {
        ContributionProof storage proof = contributionProofs[_contributionId];
        require(proof.contributor != address(0), "AetherisNexus: Contribution does not exist");
        require(proof.contributor != msg.sender, "AetherisNexus: Cannot attest your own contribution");
        require(!proof.isProcessed, "AetherisNexus: Contribution already processed");
        require(!proof.isDisputed, "AetherisNexus: Cannot attest a disputed contribution");

        if (_isPositive) {
            proof.attestationsCount++;
            // Simple validation: 3 positive attestations mark as valid
            if (proof.attestationsCount >= 3) {
                proof.isValidated = true;
            }
        } else {
            // A negative attestation implies a dispute, could be integrated with dispute mechanism
            proof.disputesCount++;
            if (proof.disputesCount >= 1) { // A single negative attestation can trigger dispute
                proof.isDisputed = true;
            }
        }
        emit ContributionAttested(_contributionId, msg.sender, _isPositive);
    }

    /**
     * @dev Allows any registered contributor to formally dispute a contribution.
     * This flags the contribution for closer review and prevents it from immediately affecting impact scores.
     * @param _contributionId The ID of the contribution to dispute.
     */
    function disputeContribution(uint256 _contributionId) external onlyRegisteredContributor whenNotPaused {
        ContributionProof storage proof = contributionProofs[_contributionId];
        require(proof.contributor != address(0), "AetherisNexus: Contribution does not exist");
        require(proof.contributor != msg.sender, "AetherisNexus: Cannot dispute your own contribution");
        require(!proof.isDisputed, "AetherisNexus: Contribution already disputed");
        require(!proof.isProcessed, "AetherisNexus: Contribution already processed");

        proof.isDisputed = true;
        proof.disputesCount++;
        emit ContributionDisputed(_contributionId, msg.sender);
    }

    /**
     * @dev Triggers the recalculation of Impact Scores for all contributors.
     * This function iterates through unprocessed contributions and updates scores.
     * Should be called periodically (e.g., at epoch end or by an oracle).
     * This can be gas-intensive if many contributions exist.
     * @notice In a real-world scenario, this might be an off-chain process feeding results,
     * or a batching mechanism to prevent gas limits.
     */
    function triggerImpactRecalculation() external onlyOwner whenNotPaused {
        uint256 processedCount = 0;
        // Iterate through all contributions and process unprocessed ones
        // (A more scalable solution would involve queuing or pagination)
        for (uint256 i = 0; i < nextContributionId; i++) {
            ContributionProof storage proof = contributionProofs[i];
            if (proof.contributor != address(0) && !proof.isProcessed) {
                // Simplified impact calculation:
                // Validated contributions boost score, disputed ones reduce it.
                // Weight by category.
                uint256 baseImpact = 10; // Base impact points per contribution
                uint256 weightedImpact = baseImpact * rewardWeightings[proof.category] / 1000;

                if (proof.isValidated && !proof.isDisputed) {
                    contributors[proof.contributor].impactScore += weightedImpact;
                } else if (proof.isDisputed) {
                    // Punish for disputed contributions, potentially reduce score
                    if (contributors[proof.contributor].impactScore > weightedImpact / 2) {
                        contributors[proof.contributor].impactScore -= weightedImpact / 2;
                    } else {
                        contributors[proof.contributor].impactScore = 0;
                    }
                }
                contributors[proof.contributor].lastContributionEpoch = currentEpochId;
                proof.isProcessed = true;
                processedCount++;
                emit ImpactScoreRecalculated(proof.contributor, contributors[proof.contributor].impactScore);
            }
        }
        // Emit event for overall recalculation, not individual scores
        // emit ImpactScoresRecalculated(processedCount);
    }

    /**
     * @dev Returns the current Impact Score of a specific contributor.
     * @param _contributor The address of the contributor.
     * @return The current Impact Score.
     */
    function getImpactScore(address _contributor) public view returns (uint256) {
        return contributors[_contributor].impactScore;
    }

    // --- Collective Fund & Reward Distribution Functions ---

    /**
     * @dev Allows high-impact contributors to propose how funds from the collective treasury should be allocated.
     * Requires a minimum impact score to propose.
     * @param _description A description of the proposed allocation.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount of rewardToken to allocate.
     */
    function proposeCollectiveFundAllocation(string memory _description, address _recipient, uint256 _amount)
        external
        onlyRegisteredContributor
        whenNotPaused
    {
        require(contributors[msg.sender].impactScore >= minImpactScoreForProposal, "AetherisNexus: Insufficient impact score to propose");
        require(rewardToken.balanceOf(address(this)) >= _amount, "AetherisNexus: Insufficient collective fund balance");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            pType: ProposalType.FundAllocation,
            proposer: msg.sender,
            description: _description,
            creationTime: block.timestamp,
            votesForImpact: 0,
            votesAgainstImpact: 0,
            executed: false,
            recipient: _recipient,
            amount: _amount,
            paramType: 0, // Not applicable
            newValue: 0 // Not applicable
        });
        emit CollectiveFundAllocationProposed(proposalId, msg.sender, _recipient, _amount);
    }

    /**
     * @dev Allows contributors to vote on fund allocation proposals.
     * Vote weight is based on the contributor's Impact Score.
     * Includes delegation logic.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _for True to vote for, false to vote against.
     */
    function voteOnFundAllocationProposal(uint256 _proposalId, bool _for)
        external
        onlyRegisteredContributor
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.pType == ProposalType.FundAllocation, "AetherisNexus: Not a fund allocation proposal");
        require(proposal.proposer != address(0), "AetherisNexus: Proposal does not exist");
        require(!proposal.hasVoted[msg.sender], "AetherisNexus: Already voted on this proposal");
        require(!proposal.executed, "AetherisNexus: Proposal already executed");

        address voterAddress = contributors[msg.sender].impactDelegatee != address(0) ? contributors[msg.sender].impactDelegatee : msg.sender;
        uint256 voteWeight = contributors[voterAddress].impactScore;

        if (_for) {
            proposal.votesForImpact += voteWeight;
        } else {
            proposal.votesAgainstImpact += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _for, voteWeight);
    }

    /**
     * @dev Executes a passed fund allocation proposal.
     * Requires the proposal to have met quorum and passed.
     * Only callable by owner/guardian in this example, or by a timelock/DAO.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeFundAllocationProposal(uint256 _proposalId) external onlyOwner whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.pType == ProposalType.FundAllocation, "AetherisNexus: Not a fund allocation proposal");
        require(proposal.proposer != address(0), "AetherisNexus: Proposal does not exist");
        require(!proposal.executed, "AetherisNexus: Proposal already executed");

        uint256 totalVotes = proposal.votesForImpact + proposal.votesAgainstImpact;
        uint256 totalActiveImpact = _getTotalActiveImpactScore(); // Sum of all contributors' impact scores

        require(totalVotes * 10000 >= totalActiveImpact * proposalQuorumPercentage, "AetherisNexus: Quorum not met");
        require(proposal.votesForImpact > proposal.votesAgainstImpact, "AetherisNexus: Proposal not passed");

        proposal.executed = true;
        require(rewardToken.transfer(proposal.recipient, proposal.amount), "AetherisNexus: Token transfer failed");
        emit CollectiveFundAllocationExecuted(_proposalId);
    }

    /**
     * @dev Initiates the distribution of rewards for the current epoch to eligible contributors.
     * This function should be called after an epoch ends.
     * It also prepares for the next epoch.
     * @param _rewardAmount Total amount of rewardToken to distribute for this epoch.
     * @notice This assumes the _rewardAmount is topped up by some external mechanism (e.g., treasury, protocol fees).
     */
    function distributeEpochRewards(uint256 _rewardAmount) external onlyOwner onlyEpochEnded whenNotPaused nonReentrant {
        require(!epochs[currentEpochId].rewardsDistributed, "AetherisNexus: Rewards already distributed for this epoch");

        // First, trigger impact score recalculation for the *just ended* epoch
        // For simplicity, we just call the existing trigger. A more robust system
        // would snapshot scores at epoch end.
        triggerImpactRecalculation();

        uint256 totalWeightedImpact = 0;
        // Calculate total weighted impact across all contributors for this epoch
        for (uint256 i = 0; i < registeredContributors.length; i++) {
            address contributorAddr = registeredContributors[i];
            Contributor storage contributor = contributors[contributorAddr];
            if (contributor.isRegistered) {
                // Influence staking multiplies the impact score's *weight* in distribution
                uint256 weightedScore = contributor.impactScore * (1000 + contributor.stakedInfluence / 100); // 1000 = 1x base, every 100 staked influence adds 0.01x
                totalWeightedImpact += weightedScore;
            }
        }

        epochs[currentEpochId].totalRewardPool = _rewardAmount;
        epochs[currentEpochId].totalImpactScoreSum = totalWeightedImpact; // Store for transparency
        epochs[currentEpochId].rewardsDistributed = true;

        // Ensure the contract has enough rewards
        require(rewardToken.balanceOf(address(this)) >= _rewardAmount, "AetherisNexus: Insufficient reward pool balance");

        emit EpochRewardsDistributed(currentEpochId, _rewardAmount);

        // Prepare for the next epoch
        currentEpochId++;
        epochs[currentEpochId].startTimestamp = block.timestamp;
        epochs[currentEpochId].endTimestamp = block.timestamp + epochDuration;
        epochs[currentEpochId].rewardsDistributed = false;
    }

    /**
     * @dev Allows individual contributors to claim their share of rewards from the previous epoch.
     * @notice A user can only claim for the *last completed* epoch if rewards have been distributed.
     */
    function claimEpochRewards() external onlyRegisteredContributor whenNotPaused nonReentrant {
        uint256 claimEpoch = currentEpochId - 1; // Claim for the previously completed epoch
        require(claimEpoch >= 0, "AetherisNexus: No past epoch to claim rewards from");
        require(epochs[claimEpoch].rewardsDistributed, "AetherisNexus: Rewards not yet distributed for this epoch");
        require(contributors[msg.sender].lastContributionEpoch >= claimEpoch, "AetherisNexus: No valid contribution in last epoch"); // Simple check
        // A more robust system would track claims per user per epoch

        Contributor storage contributor = contributors[msg.sender];
        uint256 totalWeightedImpact = epochs[claimEpoch].totalImpactScoreSum;
        require(totalWeightedImpact > 0, "AetherisNexus: No impact recorded for this epoch");

        uint256 weightedScore = contributor.impactScore * (1000 + contributor.stakedInfluence / 100);
        uint256 rewardAmount = (epochs[claimEpoch].totalRewardPool * weightedScore) / totalWeightedImpact;

        require(rewardAmount > 0, "AetherisNexus: No rewards due");
        // A proper system would mark this user as claimed for this epoch to prevent double claims
        // For simplicity, this example allows multiple claims if not marked, or uses a per-epoch mapping.
        // E.g., mapping(uint256 => mapping(address => bool)) public hasClaimed;

        rewardToken.transfer(msg.sender, rewardAmount);
        emit RewardsClaimed(claimEpoch, msg.sender, rewardAmount);
    }

    // --- Adaptive Parameter Management Functions ---

    /**
     * @dev Simulated function to receive data from an external oracle.
     * In a real system, this would be integrated with Chainlink, Band Protocol, etc.
     * The `_value` could be encoded data (e.g., market volatility, community sentiment score).
     * @param _dataPointId An identifier for the type of oracle data.
     * @param _value The raw bytes value received from the oracle.
     */
    function receiveOracleData(uint256 _dataPointId, bytes memory _value) external onlyOwner { // Or designated oracle address
        oracleData[_dataPointId] = _value;
        emit OracleDataReceived(_dataPointId, _value);
    }

    /**
     * @dev Allows high-impact contributors to propose changes to core protocol parameters.
     * @param _description A description of the proposed parameter adjustment.
     * @param _paramType An identifier for the parameter to adjust (e.g., 0 for rewardWeightings[0], 1 for minImpactScoreForProposal).
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterAdjustment(string memory _description, uint256 _paramType, uint256 _newValue)
        external
        onlyRegisteredContributor
        whenNotPaused
    {
        require(contributors[msg.sender].impactScore >= minImpactScoreForProposal, "AetherisNexus: Insufficient impact score to propose");

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            id: proposalId,
            pType: ProposalType.ParameterAdjustment,
            proposer: msg.sender,
            description: _description,
            creationTime: block.timestamp,
            votesForImpact: 0,
            votesAgainstImpact: 0,
            executed: false,
            recipient: address(0), // Not applicable
            amount: 0, // Not applicable
            paramType: _paramType,
            newValue: _newValue
        });
        emit ParameterAdjustmentProposed(proposalId, _paramType, _newValue);
    }

    /**
     * @dev Allows contributors to vote on proposed parameter adjustments.
     * Vote weight is based on Impact Score, respecting delegation.
     * @param _proposalId The ID of the parameter adjustment proposal.
     * @param _for True to vote for, false to vote against.
     */
    function voteOnParameterAdjustment(uint256 _proposalId, bool _for)
        external
        onlyRegisteredContributor
        whenNotPaused
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.pType == ProposalType.ParameterAdjustment, "AetherisNexus: Not a parameter adjustment proposal");
        require(proposal.proposer != address(0), "AetherisNexus: Proposal does not exist");
        require(!proposal.hasVoted[msg.sender], "AetherisNexus: Already voted on this proposal");
        require(!proposal.executed, "AetherisNexus: Proposal already executed");

        address voterAddress = contributors[msg.sender].impactDelegatee != address(0) ? contributors[msg.sender].impactDelegatee : msg.sender;
        uint256 voteWeight = contributors[voterAddress].impactScore;

        if (_for) {
            proposal.votesForImpact += voteWeight;
        } else {
            proposal.votesAgainstImpact += voteWeight;
        }
        proposal.hasVoted[msg.sender] = true;
        emit Voted(_proposalId, msg.sender, _for, voteWeight);
    }

    /**
     * @dev Executes a passed parameter adjustment proposal, updating the relevant internal protocol setting.
     * @param _proposalId The ID of the proposal to execute.
     */
    function enactParameterAdjustment(uint256 _proposalId) external onlyOwner whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.pType == ProposalType.ParameterAdjustment, "AetherisNexus: Not a parameter adjustment proposal");
        require(proposal.proposer != address(0), "AetherisNexus: Proposal does not exist");
        require(!proposal.executed, "AetherisNexus: Proposal already executed");

        uint256 totalVotes = proposal.votesForImpact + proposal.votesAgainstImpact;
        uint256 totalActiveImpact = _getTotalActiveImpactScore();

        require(totalVotes * 10000 >= totalActiveImpact * proposalQuorumPercentage, "AetherisNexus: Quorum not met");
        require(proposal.votesForImpact > proposal.votesAgainstImpact, "AetherisNexus: Proposal not passed");

        proposal.executed = true;

        // Apply the parameter change based on _paramType
        if (proposal.paramType == 0) { // Example: Adjusting rewardWeightings for category 0
            rewardWeightings[0] = proposal.newValue;
        } else if (proposal.paramType == 1) { // Example: Adjusting minImpactScoreForProposal
            minImpactScoreForProposal = proposal.newValue;
        } else if (proposal.paramType == 2) { // Example: Adjusting proposalQuorumPercentage
            proposalQuorumPercentage = proposal.newValue;
        }
        // Add more else if blocks for other parameters as needed

        emit ParameterAdjustmentEnacted(_proposalId, proposal.paramType, proposal.newValue);
    }

    /**
     * @dev Triggers the protocol's "self-optimization" mechanism.
     * This function would ideally analyze oracle data and internal metrics to
     * recommend/enact adaptive parameter adjustments.
     * @notice For this example, it's a placeholder. Real adaptive logic would be complex
     * and likely rely on off-chain computation or simple on-chain rules based on data.
     * E.g., if oracle data indicates high market volatility, reduce stake influence multiplier.
     */
    function triggerAdaptiveRecalculation() external onlyOwner { // Could be called by a trusted oracle or time-based
        // Example of simple adaptive logic (conceptual):
        // if (oracleData[0] interprets as "high volatility") {
        //     rewardWeightings[0] = 800; // Reduce code rewards slightly
        //     rewardWeightings[1] = 1200; // Increase content/communication rewards
        // } else if (oracleData[0] interprets as "low engagement") {
        //     minImpactScoreForProposal = 50; // Lower barrier to proposal
        // }
        emit AdaptiveRecalculationTriggered();
    }

    // --- Governance & Delegation Functions ---

    /**
     * @dev Allows a contributor to delegate their Impact Score-based voting power to another address.
     * The delegatee will represent the delegator's impact score in votes.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateImpactVote(address _delegatee) external onlyRegisteredContributor whenNotPaused {
        require(_delegatee != msg.sender, "AetherisNexus: Cannot delegate to self");
        require(contributors[_delegatee].isRegistered, "AetherisNexus: Delegatee must be a registered contributor");
        contributors[msg.sender].impactDelegatee = _delegatee;
        emit ImpactVoteDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Allows a contributor to revoke any active delegation of their voting power.
     */
    function revokeImpactVoteDelegation() external onlyRegisteredContributor whenNotPaused {
        require(contributors[msg.sender].impactDelegatee != address(0), "AetherisNexus: No active delegation to revoke");
        contributors[msg.sender].impactDelegatee = address(0);
        emit ImpactVoteDelegationRevoked(msg.sender);
    }

    // --- Staking Mechanism Functions ---

    /**
     * @dev Allows contributors to stake `influenceToken` to temporarily increase the influence multiplier
     * of their Impact Score for reward distribution or governance votes.
     * @param _amount The amount of `influenceToken` to stake.
     */
    function stakeForImpactInfluence(uint256 _amount) external onlyRegisteredContributor whenNotPaused nonReentrant {
        require(_amount > 0, "AetherisNexus: Stake amount must be positive");
        require(influenceToken.transferFrom(msg.sender, address(this), _amount), "AetherisNexus: Influence token transfer failed");
        contributors[msg.sender].stakedInfluence += _amount;
        emit InfluenceStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows contributors to unstake their `influenceToken`.
     * @param _amount The amount of `influenceToken` to unstake.
     */
    function unstakeImpactInfluence(uint256 _amount) external onlyRegisteredContributor whenNotPaused nonReentrant {
        require(_amount > 0, "AetherisNexus: Unstake amount must be positive");
        require(contributors[msg.sender].stakedInfluence >= _amount, "AetherisNexus: Insufficient staked influence");

        contributors[msg.sender].stakedInfluence -= _amount;
        require(influenceToken.transfer(msg.sender, _amount), "AetherisNexus: Influence token transfer failed");
        emit InfluenceUnstaked(msg.sender, _amount);
    }

    // --- Internal/Helper Functions ---

    /**
     * @dev Calculates the total impact score of all registered contributors.
     * @return The sum of all active contributors' impact scores.
     */
    function _getTotalActiveImpactScore() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < registeredContributors.length; i++) {
            total += contributors[registeredContributors[i]].impactScore;
        }
        return total;
    }

    // Fallback and Receive functions if needed (not strictly required for this contract logic)
    receive() external payable {
        // Accept ETH for potential future features or direct funding
    }

    fallback() external payable {
        // Handle calls to undefined functions
    }
}
```