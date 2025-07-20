This smart contract, `AIAdaptivePolicyNetwork`, is designed as a decentralized policy framework that leverages **off-chain AI insights** (via oracle integration), **reputation-based governance**, and **epoch-based adaptive evolution** to manage dynamic policies. It aims to create a system where the community can propose, vote on, and evolve rules for a decentralized application or ecosystem, with AI contributing to data-driven decision-making.

The contract avoids duplicating existing open-source projects by combining these advanced concepts in a novel way, focusing on the orchestration of AI insights for policy governance rather than direct on-chain AI computation.

---

### Outline:

1.  **Core Data Structures**: Definitions for policies, proposals, AI insights, reputation, epochs.
2.  **Policy Lifecycle Management**: Functions for proposing, voting, activating, amending, and revoking policies.
3.  **AI Oracle Integration**: Mechanisms for requesting, receiving, and verifying off-chain AI insights from whitelisted oracles.
4.  **Reputation & Staking System**: Managing user reputation scores and collateral for proposals, influencing voting power.
5.  **Epoch & Adaptive Evolution**: Advancing system state through discrete time periods (epochs) which can trigger policy re-evaluation or parameter updates.
6.  **Dispute Resolution & Feedback**: Mechanisms for challenging AI insights and providing structured community input on active policies.
7.  **System Configuration & Treasury**: Ownership-gated functions for setting core parameters and managing contract funds.
8.  **Token Interfaces**: Compatibility functions for receiving ERC721 and ERC1155 tokens.

### Function Summary (26 Functions):

**I. Policy Lifecycle & Governance (7 functions)**
1.  `proposeDynamicPolicy(ProposalType _proposalType, uint256 _targetPolicyId, bytes calldata _proposedPolicyData, uint256 _votingDuration, address _aiOracleAddress, bytes calldata _aiQueryData, bytes32 _expectedInsightHash)`: Initiates a new policy proposal (or amendment/revocation) with dynamic parameters and an optional request for AI insight.
2.  `castPolicyVote(uint256 _proposalId, bool _support)`: Allows users to vote on active policy proposals, with their voting power weighted by their on-chain reputation.
3.  `finalizePolicyProposal(uint256 _proposalId)`: Concludes the voting period for a proposal, applying it if successful, checking quorum and majority.
4.  `amendActivePolicy(uint256 _policyId, bytes calldata _newPolicyData, uint256 _votingDuration, address _aiOracleAddress, bytes calldata _aiQueryData, bytes32 _expectedInsightHash)`: Proposes modifications to an already active policy.
5.  `revokeActivePolicy(uint256 _policyId, uint256 _votingDuration, address _aiOracleAddress, bytes calldata _aiQueryData, bytes32 _expectedInsightHash)`: Proposes the deactivation of an active policy.
6.  `getActivePolicyParameters(uint256 _policyId)`: Retrieves the currently active parameters/data and status for a given policy.
7.  `getProposalVoteCount(uint256 _proposalId)`: Returns the current 'yes' and 'no' vote counts (weighted by reputation) and the total reputation at proposal time for a specific proposal.

**II. AI Insight Orchestration (4 functions)**
8.  `registerAIInsightOracle(address _oracleAddress, string calldata _capabilities)`: Whitelists a new AI oracle, specifying its capabilities (callable by owner).
9.  `requestAIInsightForProposal(uint256 _proposalId, address _aiOracleAddress, bytes calldata _queryData, bytes32 _expectedInsightHash)`: Initiates an off-chain AI insight request for a policy proposal to a whitelisted oracle.
10. `receiveAIInsightCallback(uint256 _proposalId, bytes calldata _insightData, bytes32 _submittedInsightHash)`: Callback function for a whitelisted oracle to submit AI insights, with on-chain hash verification.
11. `disputeAIInsight(uint256 _proposalId, string calldata _reason)`: Allows a user to formally dispute a submitted AI insight for a proposal, potentially halting its finalization.

**III. Reputation & Staking (4 functions)**
12. `stakeForProposal(uint256 _proposalId, uint256 _amount)`: Locks ERC20 tokens as collateral to support a policy proposal.
13. `withdrawStake(uint256 _proposalId)`: Allows stakers to withdraw their collateral after a proposal's lifecycle is complete.
14. `updateReputationScore(address _user, int256 _delta)`: Internal/privileged function to adjust a user's on-chain reputation score, which influences voting power.
15. `getUserReputation(address _user)`: Queries the current reputation score of a specific address.

**IV. Epoch & Adaptive Evolution (3 functions)**
16. `advanceEpoch()`: Advances the system to the next epoch, triggering potential policy re-evaluation (e.g., expiration checks) and state updates.
17. `setEpochInterval(uint256 _newInterval)`: Sets the duration of each epoch in seconds (callable by owner).
18. `getEpochData(uint256 _epochId)`: Retrieves information about a specific epoch, including its start/end times and key metrics.

**V. Feedback & Transparency (2 functions)**
19. `submitPolicyFeedback(uint256 _policyId, string calldata _feedbackContent)`: Allows users to provide structured feedback on an active policy, which can be used for future AI analysis or amendments.
20. `getPolicyFeedback(uint256 _policyId)`: Retrieves all submitted feedback for a given policy.

**VI. System Configuration & Treasury (4 functions)**
21. `setMinProposalStake(uint256 _amount)`: Sets the minimum token amount required to propose a policy (callable by owner).
22. `setVotingQuorum(uint256 _quorumBPS)`: Configures the required voting quorum for policy proposals in Basis Points (BPS) (callable by owner).
23. `emergencyPauseSystem()`: Pauses critical contract functions in case of an emergency (callable by owner, inherited from Pausable).
24. `withdrawContractFunds(address _tokenAddress, uint256 _amount)`: Allows the owner to withdraw specific ERC20 tokens from the contract treasury.

**VII. Token Interface (2 functions)**
25. `onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)`: ERC721 compatibility function, allowing the contract to safely receive ERC721 tokens.
26. `onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data)` / `onERC1155BatchReceived`: ERC1155 compatibility functions, allowing the contract to safely receive ERC1155 tokens.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Outline:
// 1. Core Data Structures: Definitions for policies, proposals, AI insights, reputation, epochs.
// 2. Policy Lifecycle Management: Proposing, voting, activating, amending, and revoking policies.
// 3. AI Oracle Integration: Requesting, receiving, and verifying off-chain AI insights.
// 4. Reputation & Staking System: Managing user reputation scores and collateral for proposals.
// 5. Epoch & Adaptive Evolution: Advancing system state through epochs and dynamic parameter updates.
// 6. Dispute Resolution & Feedback: Mechanisms for challenging decisions and providing community input.
// 7. System Configuration & Treasury: Ownership, pausing, and emergency measures.
// 8. Token Interfaces: Compatibility functions for receiving ERC721 and ERC1155 tokens.

// Function Summary:
// I. Policy Lifecycle & Governance (7 functions)
//    1. proposeDynamicPolicy: Initiates a new policy proposal with dynamic parameters and an optional AI insight request.
//    2. castPolicyVote: Allows users to vote on active policy proposals, considering their reputation.
//    3. finalizePolicyProposal: Concludes the voting period for a proposal, applying it if successful.
//    4. amendActivePolicy: Proposes modifications to an already active policy.
//    5. revokeActivePolicy: Proposes the deactivation of an active policy.
//    6. getActivePolicyParameters: Retrieves the currently active parameters for a given policy.
//    7. getProposalVoteCount: Returns the current vote counts for a specific proposal.

// II. AI Insight Orchestration (4 functions)
//    8. registerAIInsightOracle: Whitelists a new AI oracle with specific capabilities.
//    9. requestAIInsightForProposal: Initiates an off-chain AI insight request for a policy proposal.
//    10. receiveAIInsightCallback: Callback function for a whitelisted oracle to submit AI insights.
//    11. disputeAIInsight: Allows a user to formally dispute a submitted AI insight.

// III. Reputation & Staking (4 functions)
//    12. stakeForProposal: Locks tokens as collateral to support a policy proposal.
//    13. withdrawStake: Allows stakers to withdraw their collateral after a proposal's lifecycle.
//    14. updateReputationScore: Internal/privileged function to adjust a user's reputation based on their participation.
//    15. getUserReputation: Queries the reputation score of a specific address.

// IV. Epoch & Adaptive Evolution (3 functions)
//    16. advanceEpoch: Advances the system to the next epoch, triggering potential policy re-evaluation or parameter updates.
//    17. setEpochInterval: Sets the duration of each epoch.
//    18. getEpochData: Retrieves information about the current or a past epoch.

// V. Feedback & Transparency (2 functions)
//    19. submitPolicyFeedback: Allows users to provide structured feedback on an active policy.
//    20. getPolicyFeedback: Retrieves aggregated feedback for a given policy.

// VI. System Configuration & Treasury (4 functions)
//    21. setMinProposalStake: Sets the minimum token amount required to propose a policy.
//    22. setVotingQuorum: Configures the required voting quorum for policy proposals.
//    23. emergencyPauseSystem: Pauses critical contract functions in case of an emergency.
//    24. withdrawContractFunds: Allows the owner to withdraw specific tokens from the contract treasury.

// VII. Token Interface (2 functions)
//    25. onERC721Received: Handles incoming ERC721 tokens (e.g., if policies are represented as NFTs or roles).
//    26. onERC1155Received & onERC1155BatchReceived: Handles incoming ERC1155 tokens.

contract AIAdaptivePolicyNetwork is Ownable, Pausable, IERC721Receiver, IERC1155Receiver {
    // --- State Variables & Data Structures ---

    uint256 private nextPolicyId = 1;
    uint256 private nextProposalId = 1;
    uint256 public currentEpoch = 0;
    uint256 public totalReputationSupply; // Tracks the sum of all reputation scores in the system

    // Configuration parameters
    uint256 public minProposalStake; // Minimum tokens required to propose a policy
    uint256 public votingQuorumBPS;  // Quorum in Basis Points (e.g., 5000 for 50%)
    uint256 public epochInterval;    // Duration of an epoch in seconds

    IERC20 public stakeToken; // ERC20 token used for staking and governance incentives

    // Enums for clarity
    enum PolicyStatus { Proposed, Active, Amended, Revoked, Disputed, Expired }
    enum ProposalType { NewPolicy, AmendPolicy, RevokePolicy }
    enum AIInsightStatus { Requested, Received, Verified, Disputed }

    // Structs
    struct Policy {
        uint256 id;
        address proposer;
        bytes policyData; // Can contain parameters, logic hashes, or configuration for dynamic policies
        PolicyStatus status;
        uint256 activeSinceEpoch; // The epoch from which this policy became active
        uint256 expirationEpoch; // Policy expires after this epoch (0 for perpetual)
        uint256 latestProposalId; // Tracks the last proposal ID that affected this policy (for amendments/revocations)
    }

    struct PolicyProposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        uint256 targetPolicyId; // For amend/revoke proposals
        bytes proposedPolicyData; // The new data for the policy (if NewPolicy/AmendPolicy)
        uint256 proposalEpoch; // Epoch when proposed
        uint256 votingDeadline; // Timestamp when voting ends
        uint256 stakeAmount;
        mapping(address => bool) hasVoted; // Voter tracking
        uint256 yesVotes; // Accumulated reputation weight for 'yes' votes
        uint256 noVotes;  // Accumulated reputation weight for 'no' votes
        address[] stakers; // List of addresses that staked for this proposal
        mapping(address => uint256) stakeholderStakes; // Maps staker address to staked amount for this proposal
        uint256 totalReputationAtProposal; // Snapshot of total reputation to calculate quorum
        AIInsightStatus aiInsightStatus;
        bytes aiInsightData; // The raw AI insight data (if applicable)
        bytes32 aiInsightHash; // Hash of the expected AI insight (for verification)
        address aiOracleAddress; // Address of the oracle providing the insight
        bool aiInsightDisputed; // True if the AI insight has been disputed
    }

    struct AIOracle {
        address oracleAddress;
        bool isWhitelisted;
        string capabilities; // Description of what type of AI insights this oracle provides
    }

    struct EpochData {
        uint256 startTime;
        uint256 endTime;
        uint256 totalProposalsInEpoch;
        uint256 activePoliciesCountSnapshot; // Snapshot of active policies at epoch start
        // Future: Could snapshot system metrics, total reputation, etc.
    }

    struct PolicyFeedback {
        uint256 submissionEpoch;
        address contributor;
        string feedbackContent;
        // Could be extended with sentiment scores, categories etc.
    }

    // Mappings
    mapping(uint256 => Policy) public policies;
    mapping(uint256 => PolicyProposal) public proposals;
    mapping(address => uint256) public reputationScores; // Tracks reputation for each address
    mapping(uint256 => EpochData) public epochs;
    mapping(address => AIOracle) public aiOracles; // Whitelisted AI oracles
    mapping(uint256 => PolicyFeedback[]) public policyFeedback; // Policy ID to array of feedback

    // Events
    event PolicyProposed(uint256 indexed proposalId, uint256 indexed policyId, address indexed proposer, ProposalType proposalType, uint256 deadline);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 reputationWeight);
    event PolicyFinalized(uint256 indexed proposalId, uint256 indexed policyId, PolicyStatus newStatus, bool success);
    event AIInsightRequested(uint256 indexed proposalId, address indexed oracleAddress, bytes queryData, bytes32 expectedInsightHash);
    event AIInsightReceived(uint256 indexed proposalId, address indexed oracleAddress, bytes insightData, bytes32 insightHash, AIInsightStatus status);
    event AIInsightDisputed(uint256 indexed proposalId, address indexed disputer, string reason);
    event ReputationUpdated(address indexed user, uint256 newScore);
    event EpochAdvanced(uint256 indexed newEpoch, uint256 timestamp);
    event PolicyFeedbackSubmitted(uint256 indexed policyId, address indexed contributor, uint256 epoch);
    event StakeDeposited(uint256 indexed proposalId, address indexed staker, uint256 amount);
    event StakeWithdrawn(uint256 indexed proposalId, address indexed staker, uint256 amount);

    // --- Constructor ---
    constructor(address _stakeTokenAddress, uint256 _minProposalStake, uint256 _votingQuorumBPS, uint256 _epochInterval) Ownable(msg.sender) {
        require(_stakeTokenAddress != address(0), "Invalid stake token address");
        require(_votingQuorumBPS <= 10000, "Quorum BPS cannot exceed 100%");
        require(_epochInterval > 0, "Epoch interval must be greater than 0");

        stakeToken = IERC20(_stakeTokenAddress);
        minProposalStake = _minProposalStake;
        votingQuorumBPS = _votingQuorumBPS;
        epochInterval = _epochInterval;

        // Initialize epoch 0
        epochs[0] = EpochData({
            startTime: block.timestamp,
            endTime: block.timestamp + epochInterval,
            totalProposalsInEpoch: 0,
            activePoliciesCountSnapshot: 0 // Will be updated as policies become active
        });
        currentEpoch = 0;
        totalReputationSupply = 0; // Initialize global reputation supply
    }

    // --- Modifiers ---
    modifier onlyAIOracle(address _oracle) {
        require(aiOracles[_oracle].isWhitelisted, "Not a whitelisted AI oracle");
        _;
    }

    modifier onlyReputationHolder(address _addr) {
        require(reputationScores[_addr] > 0, "Requires reputation to perform this action");
        _;
    }

    // --- I. Policy Lifecycle & Governance ---

    /**
     * @notice Initiates a new policy proposal or an amendment/revocation proposal.
     * @dev Policy data can be a hash, parameters, or a URL to off-chain logic.
     *      Optionally requests AI insight for the proposal. Requires `minProposalStake` tokens.
     * @param _proposalType The type of proposal (NewPolicy, AmendPolicy, RevokePolicy).
     * @param _targetPolicyId For AmendPolicy/RevokePolicy, the ID of the policy to target. Ignored for NewPolicy.
     * @param _proposedPolicyData The new data for the policy (if NewPolicy or AmendPolicy). Ignored for RevokePolicy.
     * @param _votingDuration The duration for voting in seconds.
     * @param _aiOracleAddress If not address(0), specifies an AI oracle to request insight from.
     * @param _aiQueryData Data for the AI oracle query, interpreted by the oracle off-chain.
     * @param _expectedInsightHash Hash of the expected AI insight data for on-chain verification.
     */
    function proposeDynamicPolicy(
        ProposalType _proposalType,
        uint256 _targetPolicyId,
        bytes calldata _proposedPolicyData,
        uint256 _votingDuration,
        address _aiOracleAddress,
        bytes calldata _aiQueryData,
        bytes32 _expectedInsightHash
    ) external whenNotPaused {
        require(_votingDuration > 0, "Voting duration must be positive");
        require(stakeToken.transferFrom(msg.sender, address(this), minProposalStake), "Stake transfer failed");

        uint256 proposalId = nextProposalId++;
        uint256 policyId;

        if (_proposalType == ProposalType.NewPolicy) {
            policyId = nextPolicyId++;
        } else {
            require(policies[_targetPolicyId].proposer != address(0), "Target policy does not exist");
            require(policies[_targetPolicyId].status == PolicyStatus.Active, "Target policy must be active for amendment/revocation");
            policyId = _targetPolicyId;
        }

        AIInsightStatus _insightStatus = AIInsightStatus.Requested;
        if (_aiOracleAddress == address(0)) {
            _insightStatus = AIInsightStatus.Verified; // No AI insight requested, consider it 'verified' by default
        } else {
            require(aiOracles[_aiOracleAddress].isWhitelisted, "AI oracle not whitelisted");
            require(_expectedInsightHash != bytes32(0), "Expected insight hash required for AI oracle request");
        }

        proposals[proposalId] = PolicyProposal({
            id: proposalId,
            proposer: msg.sender,
            proposalType: _proposalType,
            targetPolicyId: policyId,
            proposedPolicyData: _proposedPolicyData,
            proposalEpoch: currentEpoch,
            votingDeadline: block.timestamp + _votingDuration,
            stakeAmount: minProposalStake,
            yesVotes: 0,
            noVotes: 0,
            stakers: new address[](0), // Will be populated by stakeForProposal and proposer's stake
            stakeholderStakes: new mapping(address => uint256)(), // Initialized empty
            totalReputationAtProposal: totalReputationSupply, // Snapshot current total reputation for quorum calculation
            aiInsightStatus: _insightStatus,
            aiInsightData: "",
            aiInsightHash: _expectedInsightHash,
            aiOracleAddress: _aiOracleAddress,
            aiInsightDisputed: false
        });

        proposals[proposalId].stakers.push(msg.sender); // Proposer is implicitly a staker
        proposals[proposalId].stakeholderStakes[msg.sender] += minProposalStake;

        if (_aiOracleAddress != address(0)) {
            emit AIInsightRequested(proposalId, _aiOracleAddress, _aiQueryData, _expectedInsightHash);
        }
        epochs[currentEpoch].totalProposalsInEpoch++;
        emit PolicyProposed(proposalId, policyId, msg.sender, _proposalType, proposals[proposalId].votingDeadline);
    }

    /**
     * @notice Allows users to vote on an active policy proposal.
     * @dev Voting power is weighted by the user's on-chain reputation score.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for a 'yes' vote, false for a 'no' vote.
     */
    function castPolicyVote(uint256 _proposalId, bool _support) external whenNotPaused onlyReputationHolder(msg.sender) {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "Voting period has ended");
        require(!proposal.hasVoted[msg.sender], "Already voted on this proposal");
        require(!proposal.aiInsightDisputed, "Cannot vote on a proposal with a disputed AI insight");

        uint256 voterReputation = reputationScores[msg.sender];
        require(voterReputation > 0, "Voter must have positive reputation");

        proposal.hasVoted[msg.sender] = true;
        if (_support) {
            proposal.yesVotes += voterReputation;
        } else {
            proposal.noVotes += voterReputation;
        }

        emit VoteCast(_proposalId, msg.sender, _support, voterReputation);
    }

    /**
     * @notice Finalizes a policy proposal once its voting period has ended.
     * @dev Checks quorum and approval, then applies the policy if successful.
     *      Returns staked tokens to participants.
     * @param _proposalId The ID of the proposal to finalize.
     */
    function finalizePolicyProposal(uint256 _proposalId) external whenNotPaused {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp > proposal.votingDeadline, "Voting period has not ended");
        require(proposal.aiInsightStatus == AIInsightStatus.Verified, "AI Insight not yet received or verified");
        require(!proposal.aiInsightDisputed, "AI Insight is disputed, cannot finalize proposal");

        bool success = false;
        uint256 totalVotesCast = proposal.yesVotes + proposal.noVotes;

        // Check quorum: total votes cast vs. snapshot of total reputation at proposal time
        uint256 requiredQuorumVotes = (proposal.totalReputationAtProposal * votingQuorumBPS) / 10000;
        if (totalVotesCast >= requiredQuorumVotes) {
            // Check approval: simple majority of cast votes
            if (proposal.yesVotes > proposal.noVotes) {
                success = true;
                _applyPolicy(proposal.id, proposal.proposalType, proposal.targetPolicyId, proposal.proposedPolicyData);
                _distributeIncentives(_proposalId, true); // Reward for success
            } else {
                _distributeIncentives(_proposalId, false); // No reward for failure
            }
        } else {
            // Quorum not met
            _distributeIncentives(_proposalId, false); // No reward if quorum not met
        }

        // Return stakes to all stakers
        for (uint i = 0; i < proposal.stakers.length; i++) {
            address staker = proposal.stakers[i];
            uint256 amount = proposal.stakeholderStakes[staker];
            if (amount > 0) {
                stakeToken.transfer(staker, amount);
                emit StakeWithdrawn(_proposalId, staker, amount);
            }
        }
        delete proposal.stakers; // Clear the array of stakers for gas efficiency

        emit PolicyFinalized(_proposalId, proposal.targetPolicyId, policies[proposal.targetPolicyId].status, success);
    }

    /**
     * @notice Proposes an amendment to an existing active policy.
     * @param _policyId The ID of the policy to amend.
     * @param _newPolicyData The new data for the policy.
     * @param _votingDuration The duration for voting in seconds.
     * @param _aiOracleAddress If not address(0), specifies an AI oracle to request insight from.
     * @param _aiQueryData Data for the AI oracle query.
     * @param _expectedInsightHash Hash of the expected AI insight data for on-chain verification.
     */
    function amendActivePolicy(
        uint256 _policyId,
        bytes calldata _newPolicyData,
        uint256 _votingDuration,
        address _aiOracleAddress,
        bytes calldata _aiQueryData,
        bytes32 _expectedInsightHash
    ) external whenNotPaused {
        require(policies[_policyId].status == PolicyStatus.Active, "Only active policies can be amended.");
        proposeDynamicPolicy(
            ProposalType.AmendPolicy,
            _policyId,
            _newPolicyData,
            _votingDuration,
            _aiOracleAddress,
            _aiQueryData,
            _expectedInsightHash
        );
    }

    /**
     * @notice Proposes the revocation (deactivation) of an existing active policy.
     * @param _policyId The ID of the policy to revoke.
     * @param _votingDuration The duration for voting in seconds.
     * @param _aiOracleAddress If not address(0), specifies an AI oracle to request insight from.
     * @param _aiQueryData Data for the AI oracle query.
     * @param _expectedInsightHash Hash of the expected AI insight data for on-chain verification.
     */
    function revokeActivePolicy(
        uint256 _policyId,
        uint256 _votingDuration,
        address _aiOracleAddress,
        bytes calldata _aiQueryData,
        bytes32 _expectedInsightHash
    ) external whenNotPaused {
        require(policies[_policyId].status == PolicyStatus.Active, "Only active policies can be revoked.");
        proposeDynamicPolicy(
            ProposalType.RevokePolicy,
            _policyId,
            "", // No new policy data for revocation
            _votingDuration,
            _aiOracleAddress,
            _aiQueryData,
            _expectedInsightHash
        );
    }

    /**
     * @notice Retrieves the currently active parameters/data for a given policy.
     * @param _policyId The ID of the policy.
     * @return The policy's data and its current status.
     */
    function getActivePolicyParameters(uint256 _policyId) external view returns (bytes memory, PolicyStatus) {
        require(policies[_policyId].proposer != address(0), "Policy does not exist");
        return (policies[_policyId].policyData, policies[_policyId].status);
    }

    /**
     * @notice Returns the current vote counts for a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return yesVotes Total reputation weight for 'yes' votes.
     * @return noVotes Total reputation weight for 'no' votes.
     * @return totalReputationAtProposal Snapshot of total reputation when proposed.
     * @return votingDeadline Timestamp when voting ends.
     * @return aiInsightStatus Current status of the AI insight for this proposal.
     * @return aiInsightDisputed Boolean indicating if the AI insight has been disputed.
     */
    function getProposalVoteCount(uint256 _proposalId) external view returns (uint256 yesVotes, uint256 noVotes, uint256 totalReputationAtProposal, uint256 votingDeadline, AIInsightStatus aiInsightStatus, bool aiInsightDisputed) {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        return (proposal.yesVotes, proposal.noVotes, proposal.totalReputationAtProposal, proposal.votingDeadline, proposal.aiInsightStatus, proposal.aiInsightDisputed);
    }


    // --- II. AI Oracle Integration ---

    /**
     * @notice Whitelists a new AI oracle with specific capabilities.
     * @dev Only callable by the contract owner.
     * @param _oracleAddress The address of the AI oracle contract/EOA.
     * @param _capabilities A string describing the oracle's AI capabilities (e.g., "Sentiment Analysis", "Prediction Market").
     */
    function registerAIInsightOracle(address _oracleAddress, string calldata _capabilities) external onlyOwner {
        require(_oracleAddress != address(0), "Invalid oracle address");
        aiOracles[_oracleAddress] = AIOracle({
            oracleAddress: _oracleAddress,
            isWhitelisted: true,
            capabilities: _capabilities
        });
    }

    /**
     * @notice Initiates an off-chain AI insight request for a policy proposal.
     * @dev This function is internally called by `proposeDynamicPolicy` if an oracle is specified.
     *      It emits an event that an off-chain oracle service would monitor and act upon.
     * @param _proposalId The ID of the policy proposal that needs the AI insight.
     * @param _aiOracleAddress The address of the whitelisted AI oracle.
     * @param _queryData The data specific to the AI query (e.g., data hash, specific parameters).
     * @param _expectedInsightHash A hash of the *expected* or *target* AI insight, allowing on-chain verification later.
     */
    function requestAIInsightForProposal(
        uint256 _proposalId,
        address _aiOracleAddress,
        bytes calldata _queryData,
        bytes32 _expectedInsightHash
    ) internal {
        // This function is designed to be called internally after a proposal is created.
        // The actual request to the oracle would typically involve an external call or an event.
        // For this example, we assume the oracle monitors events and acts off-chain.
        // A real implementation might use Chainlink, Tellor, or a custom oracle network.
        emit AIInsightRequested(_proposalId, _aiOracleAddress, _queryData, _expectedInsightHash);
    }

    /**
     * @notice Callback function for a whitelisted oracle to submit AI insights.
     * @dev The oracle provides the raw insight data and a hash. The contract verifies this hash against the expected one.
     *      Only callable by a whitelisted AI oracle whose address was specified in the proposal.
     * @param _proposalId The ID of the policy proposal this insight relates to.
     * @param _insightData The raw AI insight data generated by the oracle.
     * @param _submittedInsightHash The hash of the _insightData submitted by the oracle (for integrity check).
     */
    function receiveAIInsightCallback(
        uint256 _proposalId,
        bytes calldata _insightData,
        bytes32 _submittedInsightHash
    ) external onlyAIOracle(msg.sender) whenNotPaused {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.aiOracleAddress == msg.sender, "Insight from unauthorized oracle for this proposal");
        require(proposal.aiInsightStatus == AIInsightStatus.Requested, "AI Insight not in 'Requested' state");
        require(keccak256(_insightData) == _submittedInsightHash, "Submitted insight hash mismatch");

        // Crucial verification: If an expectedInsightHash was provided during proposal, verify it here.
        require(_submittedInsightHash == proposal.aiInsightHash, "AI Insight data does not match expected hash!");

        proposal.aiInsightData = _insightData;
        // proposal.aiInsightHash remains the expected hash, but we now have confirmed data.
        proposal.aiInsightStatus = AIInsightStatus.Verified;

        emit AIInsightReceived(_proposalId, msg.sender, _insightData, _submittedInsightHash, AIInsightStatus.Verified);
    }

    /**
     * @notice Allows a user to formally dispute a submitted AI insight.
     * @dev This marks the proposal's AI insight as disputed, preventing its finalization until resolved.
     *      In a more advanced system, this would trigger an arbitration process (e.g., Kleros or a specific arbitrator contract).
     * @param _proposalId The ID of the proposal with the disputed AI insight.
     * @param _reason A string explaining the reason for the dispute.
     */
    function disputeAIInsight(uint256 _proposalId, string calldata _reason) external whenNotPaused {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(proposal.aiInsightStatus == AIInsightStatus.Verified, "AI Insight not received or already disputed");
        require(!proposal.aiInsightDisputed, "AI Insight already disputed");
        require(block.timestamp <= proposal.votingDeadline, "Cannot dispute after voting deadline");

        // In a real system, this might require a stake to dispute, to prevent spam.
        proposal.aiInsightDisputed = true;
        proposal.aiInsightStatus = AIInsightStatus.Disputed;

        emit AIInsightDisputed(_proposalId, msg.sender, _reason);
    }


    // --- III. Reputation & Staking ---

    /**
     * @notice Allows a user to stake tokens to support a policy proposal.
     * @param _proposalId The ID of the proposal to stake for.
     * @param _amount The amount of stake tokens to deposit.
     */
    function stakeForProposal(uint256 _proposalId, uint256 _amount) external whenNotPaused {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp <= proposal.votingDeadline, "Staking period has ended for this proposal");
        require(_amount > 0, "Stake amount must be positive");

        stakeToken.transferFrom(msg.sender, address(this), _amount);

        if (proposal.stakeholderStakes[msg.sender] == 0) {
            proposal.stakers.push(msg.sender); // Add staker to the list only once
        }
        proposal.stakeholderStakes[msg.sender] += _amount;
        proposal.stakeAmount += _amount; // Increment total stake for the proposal

        emit StakeDeposited(_proposalId, msg.sender, _amount);
    }

    /**
     * @notice Allows a staker to withdraw their collateral after a proposal's lifecycle (voting deadline has passed).
     * @dev Funds are returned whether the proposal passed or failed.
     * @param _proposalId The ID of the proposal to withdraw stake from.
     */
    function withdrawStake(uint256 _proposalId) external whenNotPaused {
        PolicyProposal storage proposal = proposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp > proposal.votingDeadline, "Cannot withdraw stake before voting ends for this proposal");

        uint256 amount = proposal.stakeholderStakes[msg.sender];
        require(amount > 0, "No stake found for this user on this proposal");

        proposal.stakeholderStakes[msg.sender] = 0; // Clear stake for this user
        // Note: `proposal.stakeAmount` is not reduced here as it's a historical record of total staked for the proposal.
        stakeToken.transfer(msg.sender, amount);

        emit StakeWithdrawn(_proposalId, msg.sender, amount);
    }

    /**
     * @notice Internal function to adjust a user's reputation score.
     * @dev This would be called by the contract's internal logic based on participation,
     *      successful proposals, or adherence to policies. Reputation directly influences voting power.
     * @param _user The address whose reputation is to be updated.
     * @param _delta The amount to add to (positive) or subtract from (negative) reputation.
     */
    function updateReputationScore(address _user, int256 _delta) internal {
        if (_delta > 0) {
            reputationScores[_user] += uint256(_delta);
            totalReputationSupply += uint256(_delta); // Update global reputation supply
        } else {
            uint256 absDelta = uint256(-_delta);
            if (reputationScores[_user] < absDelta) {
                totalReputationSupply -= reputationScores[_user]; // Only subtract what was actually there
                reputationScores[_user] = 0;
            } else {
                reputationScores[_user] -= absDelta;
                totalReputationSupply -= absDelta; // Update global reputation supply
            }
        }
        emit ReputationUpdated(_user, reputationScores[_user]);
    }

    /**
     * @notice Queries the reputation score of a specific address.
     * @param _user The address to query.
     * @return The current reputation score of the user.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return reputationScores[_user];
    }


    // --- IV. Epoch & Adaptive Evolution ---

    /**
     * @notice Advances the system to the next epoch.
     * @dev This function can be called by anyone but only processes if the current epoch has ended.
     *      Triggers potential policy re-evaluation (e.g., expiration checks) and updates epoch data.
     */
    function advanceEpoch() external whenNotPaused {
        EpochData storage currentEpochData = epochs[currentEpoch];
        require(block.timestamp >= currentEpochData.endTime, "Current epoch has not ended");

        currentEpoch++;
        uint256 currentActivePolicies = 0;
        // In a real system, you'd iterate through a list of actively managed policies
        // or have a more complex way to get this count without iterating all possible IDs.
        // For demonstration, we assume a manageable count or a background process updates this.
        // The `_evaluateExpiredPolicies` loop implicitly updates counts if policies expire.

        epochs[currentEpoch] = EpochData({
            startTime: block.timestamp,
            endTime: block.timestamp + epochInterval,
            totalProposalsInEpoch: 0,
            activePoliciesCountSnapshot: currentActivePolicies // Will be updated correctly after evaluating expired policies
        });

        _evaluateExpiredPolicies(); // Check and mark policies as expired

        // Update activePoliciesCountSnapshot after expiration evaluation
        uint256 actualActivePoliciesCount = 0;
        for (uint256 i = 1; i < nextPolicyId; i++) {
            if (policies[i].proposer != address(0) && (policies[i].status == PolicyStatus.Active || policies[i].status == PolicyStatus.Amended)) {
                actualActivePoliciesCount++;
            }
        }
        epochs[currentEpoch].activePoliciesCountSnapshot = actualActivePoliciesCount;

        emit EpochAdvanced(currentEpoch, block.timestamp);
    }

    /**
     * @notice Sets the duration of each epoch.
     * @dev Only callable by the contract owner. New interval applies from the *next* epoch.
     * @param _newInterval The new duration of an epoch in seconds.
     */
    function setEpochInterval(uint256 _newInterval) external onlyOwner {
        require(_newInterval > 0, "Epoch interval must be greater than 0");
        epochInterval = _newInterval;
    }

    /**
     * @notice Retrieves information about the current or a past epoch.
     * @param _epochId The ID of the epoch to query.
     * @return startTime The start timestamp of the epoch.
     * @return endTime The end timestamp of the epoch.
     * @return totalProposalsInEpoch Number of proposals initiated in this epoch.
     * @return activePoliciesCountSnapshot Snapshot of active policies count during this epoch.
     */
    function getEpochData(uint256 _epochId) external view returns (uint256 startTime, uint256 endTime, uint256 totalProposalsInEpoch, uint256 activePoliciesCountSnapshot) {
        require(_epochId <= currentEpoch, "Epoch ID out of range");
        EpochData storage data = epochs[_epochId];
        return (data.startTime, data.endTime, data.totalProposalsInEpoch, data.activePoliciesCountSnapshot);
    }


    // --- V. Feedback & Transparency ---

    /**
     * @notice Allows users to provide structured feedback on an active policy.
     * @dev This feedback can be used off-chain for AI training or future policy amendments.
     * @param _policyId The ID of the policy to provide feedback for.
     * @param _feedbackContent The content of the feedback (e.g., a text string, or a JSON string with structured data).
     */
    function submitPolicyFeedback(uint256 _policyId, string calldata _feedbackContent) external whenNotPaused {
        require(policies[_policyId].proposer != address(0), "Policy does not exist");
        require(policies[_policyId].status == PolicyStatus.Active || policies[_policyId].status == PolicyStatus.Amended, "Can only provide feedback for active or amended policies");
        require(bytes(_feedbackContent).length > 0, "Feedback content cannot be empty");

        policyFeedback[_policyId].push(PolicyFeedback({
            submissionEpoch: currentEpoch,
            contributor: msg.sender,
            feedbackContent: _feedbackContent
        }));

        emit PolicyFeedbackSubmitted(_policyId, msg.sender, currentEpoch);
    }

    /**
     * @notice Retrieves aggregated feedback for a given policy.
     * @dev Returns an array of PolicyFeedback structs. For very large amounts of feedback, consider pagination off-chain.
     * @param _policyId The ID of the policy to retrieve feedback for.
     * @return An array of PolicyFeedback structs.
     */
    function getPolicyFeedback(uint256 _policyId) external view returns (PolicyFeedback[] memory) {
        require(policies[_policyId].proposer != address(0), "Policy does not exist");
        return policyFeedback[_policyId];
    }


    // --- VI. System Configuration & Treasury ---

    /**
     * @notice Sets the minimum token amount required to propose a policy.
     * @dev Only callable by the contract owner.
     * @param _amount The new minimum stake amount.
     */
    function setMinProposalStake(uint256 _amount) external onlyOwner {
        minProposalStake = _amount;
    }

    /**
     * @notice Configures the required voting quorum for policy proposals.
     * @dev Quorum is in Basis Points (BPS), e.g., 5000 for 50%. Only callable by the contract owner.
     * @param _quorumBPS The new quorum in basis points.
     */
    function setVotingQuorum(uint256 _quorumBPS) external onlyOwner {
        require(_quorumBPS <= 10000, "Quorum BPS cannot exceed 100%");
        votingQuorumBPS = _quorumBPS;
    }

    /**
     * @notice Pauses critical contract functions in case of an emergency.
     * @dev Inherited from OpenZeppelin Pausable. Only callable by the contract owner.
     */
    function emergencyPauseSystem() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses critical contract functions.
     * @dev Inherited from OpenZeppelin Pausable. Only callable by the contract owner.
     */
    function unpauseSystem() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw specific tokens from the contract treasury.
     * @dev Useful for managing surplus stakes, fees, or initial funding.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawContractFunds(address _tokenAddress, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        require(token.transfer(msg.sender, _amount), "Token withdrawal failed");
    }

    // --- VII. Token Interfaces ---

    /**
     * @notice ERC721 compatibility function.
     * @dev This function allows the contract to safely receive ERC721 tokens.
     *      No specific logic beyond returning the selector is implemented, as this contract
     *      is not primarily an NFT vault or minter itself.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Implement specific logic here if this contract needs to react to receiving ERC721s.
        // For example, if policy ownership or specific roles are represented by NFTs transferred to this contract.
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice ERC1155 compatibility function.
     * @dev This function allows the contract to safely receive single ERC1155 tokens.
     *      No specific logic beyond returning the selector is implemented.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Implement specific logic here if this contract needs to react to receiving ERC1155s.
        return IERC1155Receiver.onERC1155Received.selector;
    }

    /**
     * @notice ERC1155 compatibility function.
     * @dev This function allows the contract to safely receive batch ERC1155 tokens.
     *      No specific logic beyond returning the selector is implemented.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // Implement specific logic here if this contract needs to react to receiving batch ERC1155s.
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }


    // --- Internal/Private Helper Functions ---

    /**
     * @dev Applies a policy change based on a successful proposal.
     * @param _proposalId The ID of the successful proposal.
     * @param _proposalType The type of proposal.
     * @param _targetPolicyId The ID of the policy affected.
     * @param _policyData The data to apply (if new or amendment).
     */
    function _applyPolicy(uint256 _proposalId, ProposalType _proposalType, uint256 _targetPolicyId, bytes memory _policyData) internal {
        if (_proposalType == ProposalType.NewPolicy) {
            policies[_targetPolicyId] = Policy({
                id: _targetPolicyId,
                proposer: proposals[_proposalId].proposer,
                policyData: _policyData,
                status: PolicyStatus.Active,
                activeSinceEpoch: currentEpoch,
                expirationEpoch: 0, // 0 indicates a perpetual policy, could be dynamic based on policyData
                latestProposalId: _proposalId
            });
        } else if (_proposalType == ProposalType.AmendPolicy) {
            Policy storage existingPolicy = policies[_targetPolicyId];
            require(existingPolicy.status == PolicyStatus.Active, "Policy must be active to amend");
            existingPolicy.policyData = _policyData;
            existingPolicy.status = PolicyStatus.Amended; // Mark as amended
            existingPolicy.latestProposalId = _proposalId;
            existingPolicy.activeSinceEpoch = currentEpoch; // Amendment becomes active in current epoch
        } else if (_proposalType == ProposalType.RevokePolicy) {
            Policy storage existingPolicy = policies[_targetPolicyId];
            require(existingPolicy.status == PolicyStatus.Active, "Policy must be active to revoke");
            existingPolicy.status = PolicyStatus.Revoked;
            existingPolicy.expirationEpoch = currentEpoch; // Mark as revoked in current epoch
            existingPolicy.latestProposalId = _proposalId;
        }
    }

    /**
     * @dev Distributes incentives (e.g., reputation, additional tokens) based on proposal outcome.
     * @param _proposalId The ID of the proposal.
     * @param _success True if the proposal passed, false otherwise.
     */
    function _distributeIncentives(uint256 _proposalId, bool _success) internal {
        PolicyProposal storage proposal = proposals[_proposalId];

        // Example: Reward proposer with reputation. In a real system, this would be more complex.
        uint256 reputationReward = 0;
        if (_success) {
            reputationReward = 50; // Higher reward for successful proposals
            // Could also transfer a portion of staked tokens or mint new tokens
        } else {
            // Potentially penalize for failed proposals or low participation.
            reputationReward = 5; // Small participation reward even if failed.
        }
        updateReputationScore(proposal.proposer, int256(reputationReward));

        // Could add logic here to reward voters proportionally based on their reputation or stake.
        // For simplicity, it's omitted in this example to keep the function focused.
    }

    /**
     * @dev Iterates through policies and marks them as expired if their expiration epoch is reached.
     * @note This is a simplified function. For a very large number of policies, iterating through all of them
     *       would be gas-inefficient. A more robust solution might use an iterable mapping (e.g., by maintaining
     *       a dynamic array of active policy IDs) or a dedicated keeper system.
     */
    function _evaluateExpiredPolicies() internal {
        for (uint256 i = 1; i < nextPolicyId; i++) {
            Policy storage policy = policies[i];
            // Check if policy exists and is active, and has an expiration epoch set.
            if (policy.proposer != address(0) && (policy.status == PolicyStatus.Active || policy.status == PolicyStatus.Amended) && policy.expirationEpoch > 0) {
                if (currentEpoch >= policy.expirationEpoch) {
                    policy.status = PolicyStatus.Expired;
                }
            }
        }
    }
}
```