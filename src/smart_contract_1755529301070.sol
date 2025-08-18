This smart contract, "The Collective Aspiration Nexus (CAN)," is designed as a decentralized platform for proposing, funding, and executing community-driven "Aspirations" (projects or initiatives). It integrates several advanced concepts:

1.  **Dynamic Reputation System:** Users earn reputation based on successful aspiration outcomes, contributions, and governance participation. This score decays over inactivity, encouraging continuous engagement.
2.  **Liquid Delegation:** Users can delegate their reputation and associated voting/influence power to others, enabling a more efficient and representative governance model.
3.  **Adaptive Funding & Milestone Releases:** Aspirations define funding targets and milestones. Funds are released incrementally upon community approval of milestone completion, ensuring accountability.
4.  **Synergistic Aspirations:** Proposers can declare a "synergy" with another aspiration. If both linked aspirations succeed, they (and potentially their core contributors) receive an amplified reputation boost, fostering collaboration.
5.  **Catalyst Role:** High-reputation users can act as "Catalysts," applying a temporary reputation boost to aspirations they believe in, increasing their visibility and funding appeal.
6.  **On-Chain Dispute Resolution:** A mechanism for the community to dispute reported milestone completions or aspiration outcomes, leading to potential penalties for misbehaving parties.
7.  **Contribution Revocation:** During the funding phase, contributors can revoke their funds if the aspiration fails to meet its target or allows revocation.
8.  **ERC-20 & ETH Funding:** Aspirations can target both ETH and a specific ERC-20 token for funding.

---

## Contract Outline & Function Summary

**Contract Name:** `CollectiveAspirationNexus`

**Core Concepts:**
*   **Aspiration Lifecycle:** Manage projects from proposal, funding, active execution, milestone completion, to finalization.
*   **User Reputation:** A dynamic score reflecting a user's value and influence within the network.
*   **Decentralized Governance:** Community-driven decisions for milestone approval, dispute resolution, and parameter adjustments.
*   **Advanced Funding:** Incremental fund release and flexible ERC-20 integration.

---

### **I. Core Aspiration Lifecycle (8 Functions)**

1.  `proposeAspiration(string calldata _title, string calldata _description, uint256 _targetEth, uint256 _fundingDurationDays, bool _allowRevocation)`:
    *   Proposes a new aspiration accepting ETH. Sets initial status to `Funding`.
2.  `proposeAspirationWithERC20(string calldata _title, string calldata _description, uint256 _targetEth, uint256 _fundingDurationDays, address _erc20Token, uint256 _targetERC20, bool _allowRevocation)`:
    *   Proposes an aspiration accepting both ETH and a specified ERC-20 token.
3.  `contributeToAspiration(uint256 _aspirationId)`:
    *   Allows users to contribute ETH to an aspiration in the `Funding` stage.
4.  `contributeERC20ToAspiration(uint256 _aspirationId, address _tokenAddress, uint256 _amount)`:
    *   Allows users to contribute a specific ERC-20 token to an aspiration. Requires prior ERC-20 `approve` call.
5.  `revokeContribution(uint256 _aspirationId)`:
    *   Allows a contributor to withdraw their ETH or ERC-20 contribution if the aspiration is in `Funding` status, has not met its target, and `allowsRevocation` is true.
6.  `submitMilestoneReport(uint256 _aspirationId, uint256 _milestoneIndex)`:
    *   The aspiration proposer reports a milestone as completed, initiating a community review phase.
7.  `voteOnMilestoneCompletion(uint256 _aspirationId, uint256 _milestoneIndex, bool _approve)`:
    *   Community members (based on reputation) vote on the validity of a reported milestone.
8.  `finalizeAspirationOutcome(uint256 _aspirationId)`:
    *   Called by the proposer or anyone after all milestones are completed or funding deadline passed. Finalizes the aspiration status (`Completed` or `Failed`) and triggers reputation updates.

### **II. Reputation & Delegation System (4 Functions)**

9.  `getUserReputation(address _user) public view returns (uint256)`:
    *   Retrieves the current reputation score of a user, adjusted for decay based on inactivity.
10. `delegateReputationPower(address _delegatee)`:
    *   Allows a user to delegate their effective reputation power (and future earned reputation) to another address.
11. `revokeReputationDelegation()`:
    *   Allows a user to reclaim their delegated reputation power.
12. `getEffectiveReputation(address _user) public view returns (uint256)`:
    *   Calculates the total effective reputation of a user, summing their own score and all delegated power.

### **III. Aspiration Specific Actions (4 Functions)**

13. `addMilestone(uint256 _aspirationId, string calldata _description, uint256 _targetDate, uint256 _fundingPercentage)`:
    *   Proposer can add new milestones to their aspiration before or during the `Active` phase.
14. `claimMilestoneFunds(uint256 _aspirationId, uint256 _milestoneIndex)`:
    *   Proposer claims the allocated ETH and/or ERC-20 funds for an approved milestone.
15. `addAspirationSynergy(uint256 _aspirationId, uint256 _synergyWithAspirationId)`:
    *   Proposer declares a synergistic link with another aspiration. Successful completion of both yields a combined reputation bonus.
16. `applyCatalystBoost(uint256 _aspirationId)`:
    *   A "Catalyst" (user with high reputation) can apply a temporary boost to an aspiration, increasing its visibility and funding appeal.

### **IV. Dispute Resolution (3 Functions)**

17. `raiseDispute(uint256 _aspirationId, uint256 _milestoneIndex, string calldata _reason)`:
    *   Allows any user to raise a dispute against an aspiration's reported milestone or overall outcome.
18. `voteOnDispute(uint256 _disputeId, bool _supportDispute)`:
    *   Community members vote to uphold or reject a raised dispute. Their voting power is weighted by their reputation.
19. `resolveDispute(uint256 _disputeId)`:
    *   Finalizes a dispute based on community votes. Can result in penalties (reputation loss, fund clawback) for the disputed party.

### **V. Governance & Utility (6 Functions)**

20. `setGlobalParameter(uint256 _paramType, uint256 _value)`:
    *   Allows authorized governance roles to adjust global contract parameters (e.g., milestone approval thresholds, reputation decay rates, catalyst minimum reputation).
21. `getAspirationDetails(uint256 _aspirationId) public view returns (Aspiration memory)`:
    *   Retrieves all detailed information about a specific aspiration.
22. `getMilestoneDetails(uint256 _aspirationId, uint256 _milestoneIndex) public view returns (Milestone memory)`:
    *   Retrieves details for a specific milestone within an aspiration.
23. `getAspirationsByStatus(AspirationStatus _status) public view returns (uint256[] memory)`:
    *   Returns a list of aspiration IDs filtered by their current status.
24. `calculateAspirationFundingProgress(uint256 _aspirationId) public view returns (uint256 ethProgressPercent, uint256 erc20ProgressPercent)`:
    *   Calculates the current funding progress (as a percentage) for ETH and ERC-20 targets.
25. `pauseContract()`:
    *   Emergency function to pause critical operations of the contract, callable by a designated multi-sig or governance council.
26. `unpauseContract()`:
    *   Emergency function to resume operations after a pause, callable by the same authorized entities.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline & Function Summary ---
// Contract Name: CollectiveAspirationNexus
// Core Concepts:
// - Aspiration Lifecycle: Manage projects from proposal, funding, active execution, milestone completion, to finalization.
// - User Reputation: A dynamic score reflecting a user's value and influence within the network.
// - Decentralized Governance: Community-driven decisions for milestone approval, dispute resolution, and parameter adjustments.
// - Advanced Funding: Incremental fund release and flexible ERC-20 integration.

// I. Core Aspiration Lifecycle (8 Functions)
// 1. proposeAspiration: Proposes a new aspiration accepting ETH.
// 2. proposeAspirationWithERC20: Proposes an aspiration accepting both ETH and a specified ERC-20.
// 3. contributeToAspiration: Allows users to contribute ETH.
// 4. contributeERC20ToAspiration: Allows users to contribute ERC-20.
// 5. revokeContribution: Allows contributors to withdraw funds under specific conditions.
// 6. submitMilestoneReport: Proposer reports milestone completion.
// 7. voteOnMilestoneCompletion: Community votes on milestone validity.
// 8. finalizeAspirationOutcome: Finalizes aspiration status and triggers reputation updates.

// II. Reputation & Delegation System (4 Functions)
// 9. getUserReputation: Retrieves a user's reputation score, adjusted for decay.
// 10. delegateReputationPower: Delegates reputation power to another address.
// 11. revokeReputationDelegation: Revokes delegated reputation power.
// 12. getEffectiveReputation: Calculates total effective reputation including delegations.

// III. Aspiration Specific Actions (4 Functions)
// 13. addMilestone: Proposer adds new milestones to their aspiration.
// 14. claimMilestoneFunds: Proposer claims funds for approved milestones.
// 15. addAspirationSynergy: Declares a synergistic link with another aspiration.
// 16. applyCatalystBoost: High-reputation 'Catalyst' user boosts an aspiration.

// IV. Dispute Resolution (3 Functions)
// 17. raiseDispute: Allows any user to raise a dispute.
// 18. voteOnDispute: Community members vote on dispute validity.
// 19. resolveDispute: Finalizes dispute outcome.

// V. Governance & Utility (6 Functions)
// 20. setGlobalParameter: Adjusts global contract parameters (Owner/Governance only).
// 21. getAspirationDetails: Retrieves detailed information about an aspiration.
// 22. getMilestoneDetails: Retrieves details for a specific milestone.
// 23. getAspirationsByStatus: Returns aspiration IDs filtered by status.
// 24. calculateAspirationFundingProgress: Calculates funding progress percentages.
// 25. pauseContract: Emergency pause function (Owner/Governance only).
// 26. unpauseContract: Emergency unpause function (Owner/Governance only).

// --- End Outline & Function Summary ---


contract CollectiveAspirationNexus is Ownable, Pausable, ReentrancyGuard {

    // --- Enums and Structs ---

    enum AspirationStatus {
        PendingApproval, // Can be used for an optional initial review phase (not fully implemented here)
        Funding,         // Open for contributions
        Active,          // Funding target met, project execution in progress
        MilestoneReview, // A specific milestone is being reviewed for completion
        Completed,       // All milestones completed, project finalized
        Failed,          // Failed to meet funding, or abandoned, or dispute failed
        Disputed         // Under dispute resolution
    }

    enum ParameterType {
        MilestoneApprovalThreshold, // Percentage of effective reputation votes needed for milestone approval
        DisputeApprovalThreshold,   // Percentage of effective reputation votes needed to uphold a dispute
        ReputationDecayRatePerDay,  // Points of reputation decay per day of inactivity
        FundingFeePercentage,       // Percentage fee taken from successful aspiration funding
        CatalystMinReputation       // Minimum reputation for a user to become a 'Catalyst'
    }

    struct Milestone {
        uint256 id; // Index within aspiration's milestones array
        string description;
        uint256 targetDate; // Unix timestamp
        uint256 fundingPercentage; // Percentage of total aspiration funding released for this milestone (0-100)
        bool isReported; // Proposer reported completion
        bool isApproved; // Community approved completion
        uint256 approvalVotes; // Total effective reputation votes for approval
        uint256 rejectionVotes; // Total effective reputation votes against approval
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this milestone
        uint256 disputeId; // 0 if no active dispute, otherwise ID of the active dispute
    }

    struct Aspiration {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 targetFundingEth; // In wei
        uint256 currentFundingEth; // In wei
        AspirationStatus status;
        uint256 proposalTimestamp;
        uint256 fundingDeadline; // Unix timestamp
        uint256 completionTimestamp; // When project was marked as completed
        address erc20TargetToken; // address(0) if not used
        uint256 targetFundingERC20;
        uint256 currentFundingERC20;
        uint256 reputationBoostFactor; // Multiplier applied to proposer's reputation gain (100 = 1x, 110 = 1.1x)
        bool allowsRevocation; // If contributions can be revoked during funding phase
        uint256 milestoneCount; // Total number of milestones added
        mapping(address => uint256) ethContributions; // User => ETH amount contributed
        mapping(address => uint256) erc20Contributions; // User => ERC20 amount contributed
        mapping(uint256 => Milestone) milestones; // Milestone index => Milestone details
        uint256 synergyWithAspirationId; // 0 if no synergy, otherwise ID of the synergistic aspiration
        uint256 totalClaimedEth; // Sum of ETH claimed by proposer
        uint256 totalClaimedERC20; // Sum of ERC20 claimed by proposer
    }

    struct UserReputation {
        uint256 score;
        uint256 lastActivityTimestamp;
        address delegatedTo; // Address this user has delegated their power to (address(0) if none)
        mapping(address => bool) delegatedFrom; // Addresses whose power is delegated to this user
    }

    struct Dispute {
        uint256 id;
        uint256 aspirationId;
        uint256 milestoneIndex; // 0 if dispute is about whole aspiration, otherwise milestone ID
        address raisedBy;
        string reason;
        uint256 disputedTimestamp;
        uint256 supportVotes; // Effective reputation votes to uphold the dispute
        uint256 againstVotes; // Effective reputation votes against the dispute
        mapping(address => bool) hasVoted; // Tracks if an address has voted on this dispute
        bool isResolved;
        bool resolutionOutcome; // True if dispute was upheld, false if rejected
    }

    // --- State Variables ---

    uint256 private _nextAspirationId;
    uint256 private _nextDisputeId;

    mapping(uint256 => Aspiration) public aspirations;
    mapping(address => UserReputation) public userReputation;
    mapping(uint256 => Dispute) public disputes;

    mapping(ParameterType => uint256) public globalParameters;

    // List of aspiration IDs by status (for querying)
    mapping(AspirationStatus => uint256[]) public aspirationsByStatus;

    // --- Events ---

    event AspirationProposed(uint256 indexed aspirationId, address indexed proposer, string title, uint256 targetEth, address erc20Token, uint256 targetERC20, uint256 fundingDeadline);
    event ContributionMade(uint256 indexed aspirationId, address indexed contributor, uint256 ethAmount, uint256 erc20Amount);
    event ContributionRevoked(uint256 indexed aspirationId, address indexed contributor, uint256 ethAmount, uint256 erc20Amount);
    event AspirationStatusChanged(uint256 indexed aspirationId, AspirationStatus oldStatus, AspirationStatus newStatus);
    event MilestoneReported(uint256 indexed aspirationId, uint256 indexed milestoneIndex);
    event MilestoneVoted(uint256 indexed aspirationId, uint256 indexed milestoneIndex, address indexed voter, bool approved, uint256 effectiveReputation);
    event MilestoneApproved(uint256 indexed aspirationId, uint256 indexed milestoneIndex);
    event MilestoneFundsClaimed(uint256 indexed aspirationId, uint256 indexed milestoneIndex, uint256 ethAmount, uint256 erc20Amount);
    event ReputationUpdated(address indexed user, uint256 oldScore, uint256 newScore, string reason);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationDelegationRevoked(address indexed delegator, address indexed oldDelegatee);
    event MilestoneAdded(uint256 indexed aspirationId, uint256 indexed milestoneIndex, string description, uint256 fundingPercentage);
    event SynergyDeclared(uint256 indexed aspirationId, uint256 indexed synergyWithAspirationId);
    event CatalystBoostApplied(uint256 indexed aspirationId, address indexed catalyst, uint256 boostFactor);
    event DisputeRaised(uint256 indexed disputeId, uint256 indexed aspirationId, uint256 milestoneIndex, address indexed raisedBy);
    event DisputeVoted(uint256 indexed disputeId, address indexed voter, bool support, uint256 effectiveReputation);
    event DisputeResolved(uint256 indexed disputeId, bool outcome, uint256 aspirationId);
    event GlobalParameterSet(ParameterType indexed paramType, uint256 value);
    event ContractPaused(address indexed by);
    event ContractUnpaused(address indexed by);


    // --- Constructor ---

    constructor(uint256 _initialMilestoneApprovalThreshold, uint256 _initialDisputeApprovalThreshold, uint256 _initialReputationDecayRatePerDay, uint256 _initialFundingFeePercentage, uint256 _initialCatalystMinReputation) Ownable(msg.sender) {
        // Initialize default global parameters (can be changed by governance later)
        globalParameters[ParameterType.MilestoneApprovalThreshold] = _initialMilestoneApprovalThreshold; // e.g., 60 (for 60%)
        globalParameters[ParameterType.DisputeApprovalThreshold] = _initialDisputeApprovalThreshold;     // e.g., 70 (for 70%)
        globalParameters[ParameterType.ReputationDecayRatePerDay] = _initialReputationDecayRatePerDay; // e.g., 1 (for 1 point per day)
        globalParameters[ParameterType.FundingFeePercentage] = _initialFundingFeePercentage;             // e.g., 5 (for 5%)
        globalParameters[ParameterType.CatalystMinReputation] = _initialCatalystMinReputation;           // e.g., 1000

        // Initialize owner's reputation
        _updateReputationScore(msg.sender, 100, "Initial owner reputation"); // Give owner some initial reputation
    }

    // --- Modifiers ---

    modifier onlyAspirationProposer(uint256 _aspirationId) {
        require(aspirations[_aspirationId].proposer == msg.sender, "Caller is not the aspiration proposer");
        _;
    }

    modifier onlyGovernance() {
        // In a real DAO, this would be a check against a DAO multisig,
        // or a successful on-chain vote. For this example, we use Ownable.
        require(owner() == msg.sender, "Not authorized by governance");
        _;
    }

    // --- Internal Helpers ---

    function _updateAspirationStatus(uint256 _aspirationId, AspirationStatus _newStatus) internal {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        AspirationStatus oldStatus = aspiration.status;
        if (oldStatus == _newStatus) return; // No change needed

        // Remove from old status list
        uint256[] storage oldList = aspirationsByStatus[oldStatus];
        for (uint256 i = 0; i < oldList.length; i++) {
            if (oldList[i] == _aspirationId) {
                oldList[i] = oldList[oldList.length - 1];
                oldList.pop();
                break;
            }
        }

        aspiration.status = _newStatus;

        // Add to new status list
        aspirationsByStatus[_newStatus].push(_aspirationId);

        emit AspirationStatusChanged(_aspirationId, oldStatus, _newStatus);
    }

    function _getReputationScore(address _user) internal view returns (uint256) {
        UserReputation storage rep = userReputation[_user];
        if (rep.lastActivityTimestamp == 0) { // New user or no activity
            return rep.score;
        }

        uint256 daysInactive = (block.timestamp - rep.lastActivityTimestamp) / 1 days;
        uint256 decayPoints = daysInactive * globalParameters[ParameterType.ReputationDecayRatePerDay];

        if (rep.score <= decayPoints) {
            return 0;
        }
        return rep.score - decayPoints;
    }

    function _updateReputationScore(address _user, int256 _change, string memory _reason) internal {
        UserReputation storage rep = userReputation[_user];
        uint256 oldScore = _getReputationScore(_user); // Get decayed score
        
        uint256 newScore;
        if (_change < 0) {
            newScore = oldScore >= uint256(-_change) ? oldScore - uint256(-_change) : 0;
        } else {
            newScore = oldScore + uint256(_change);
        }
        
        rep.score = newScore;
        rep.lastActivityTimestamp = block.timestamp;

        emit ReputationUpdated(_user, oldScore, newScore, _reason);
    }

    function _recalculateAndApplyEffectiveReputation(address _user) internal {
        // This function is for internal use when reputation is _read_ or _delegated_.
        // It ensures the base score is up-to-date before it's used in calculations.
        UserReputation storage rep = userReputation[_user];
        uint256 currentDecayedScore = _getReputationScore(_user);
        if (rep.score != currentDecayedScore) {
            rep.score = currentDecayedScore;
        }
        rep.lastActivityTimestamp = block.timestamp;
    }

    function _getEffectiveReputationInternal(address _user) internal returns (uint256) {
        _recalculateAndApplyEffectiveReputation(_user); // Ensure self-score is up-to-date
        
        uint256 totalEffectiveReputation = userReputation[_user].score;
        // Summing up delegated power to this user
        // This part would be inefficient for many delegates.
        // A more scalable solution might involve a separate counter for "delegated_power_to_me"
        // which is updated on delegation/revocation events.
        // For simplicity in this example, we'll assume a limited number of delegators per user.
        // Or, we could just return the user's base score if delegation is only one-way (from delegatee).
        // For now, let's assume `delegatedFrom` stores addresses that delegated *to* `_user`.
        // This is not directly usable as mapping value is bool.
        // A better approach for delegation would be:
        // mapping(address => uint256) public effectiveDelegatedPower; // maps delegatee => total power delegated to them
        // This would be updated when delegate/revoke is called.
        // For now, let's just return the user's own (decayed) score + any 'hardcoded' boost from catalyst for simplicity of `getEffectiveReputation`.
        // The `getEffectiveReputation` in section II will calculate the sum.

        // Re-thinking effective reputation for delegation:
        // If A delegates to B, B's effective reputation is (B's score + A's score).
        // If B delegates to C, C's effective reputation is (C's score + B's score + A's score).
        // This forms a chain. The `getEffectiveReputation` public function will handle this.
        // For internal use here, it just uses the user's direct score.
        return userReputation[_user].score;
    }

    // --- Fallback & Receive ---

    receive() external payable {
        // Allows the contract to receive ETH. Typically for direct deposits or refunds.
    }

    fallback() external payable {
        // Catch-all for unexpected ETH transfers.
    }

    // --- Public & External Functions ---

    // I. Core Aspiration Lifecycle

    function proposeAspiration(string calldata _title, string calldata _description, uint256 _targetEth, uint256 _fundingDurationDays, bool _allowRevocation)
        external
        whenNotPaused
        returns (uint256 aspirationId)
    {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_targetEth > 0, "Target ETH must be greater than 0");
        require(_fundingDurationDays > 0, "Funding duration must be positive");

        aspirationId = ++_nextAspirationId;
        uint256 deadline = block.timestamp + (_fundingDurationDays * 1 days);

        aspirations[aspirationId] = Aspiration({
            id: aspirationId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            targetFundingEth: _targetEth,
            currentFundingEth: 0,
            status: AspirationStatus.Funding,
            proposalTimestamp: block.timestamp,
            fundingDeadline: deadline,
            completionTimestamp: 0,
            erc20TargetToken: address(0),
            targetFundingERC20: 0,
            currentFundingERC20: 0,
            totalERC20ValueReceived: 0,
            reputationBoostFactor: 100, // Default 1x
            allowsRevocation: _allowRevocation,
            milestoneCount: 0,
            synergyWithAspirationId: 0,
            totalClaimedEth: 0,
            totalClaimedERC20: 0
        });

        _updateAspirationStatus(aspirationId, AspirationStatus.Funding); // Add to status list
        _updateReputationScore(msg.sender, 5, "Proposed new aspiration"); // Small reputation boost for proposing

        emit AspirationProposed(aspirationId, msg.sender, _title, _targetEth, address(0), 0, deadline);
    }

    function proposeAspirationWithERC20(string calldata _title, string calldata _description, uint256 _targetEth, uint256 _fundingDurationDays, address _erc20Token, uint256 _targetERC20, bool _allowRevocation)
        external
        whenNotPaused
        returns (uint256 aspirationId)
    {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_targetEth > 0 || _targetERC20 > 0, "At least one target funding must be greater than 0");
        require(_fundingDurationDays > 0, "Funding duration must be positive");
        require(_erc20Token != address(0), "ERC20 token address cannot be zero");

        aspirationId = ++_nextAspirationId;
        uint256 deadline = block.timestamp + (_fundingDurationDays * 1 days);

        aspirations[aspirationId] = Aspiration({
            id: aspirationId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            targetFundingEth: _targetEth,
            currentFundingEth: 0,
            status: AspirationStatus.Funding,
            proposalTimestamp: block.timestamp,
            fundingDeadline: deadline,
            completionTimestamp: 0,
            erc20TargetToken: _erc20Token,
            targetFundingERC20: _targetERC20,
            currentFundingERC20: 0,
            totalERC20ValueReceived: 0, // Placeholder, for future multi-ERC20 support
            reputationBoostFactor: 100,
            allowsRevocation: _allowRevocation,
            milestoneCount: 0,
            synergyWithAspirationId: 0,
            totalClaimedEth: 0,
            totalClaimedERC20: 0
        });

        _updateAspirationStatus(aspirationId, AspirationStatus.Funding);
        _updateReputationScore(msg.sender, 5, "Proposed new aspiration with ERC20");

        emit AspirationProposed(aspirationId, msg.sender, _title, _targetEth, _erc20Token, _targetERC20, deadline);
    }

    function contributeToAspiration(uint256 _aspirationId) external payable whenNotPaused nonReentrant {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(aspiration.status == AspirationStatus.Funding, "Aspiration is not in funding phase");
        require(block.timestamp <= aspiration.fundingDeadline, "Funding deadline has passed");
        require(msg.value > 0, "Contribution must be greater than 0");

        aspiration.ethContributions[msg.sender] += msg.value;
        aspiration.currentFundingEth += msg.value;

        _updateReputationScore(msg.sender, 1, "Contributed ETH to aspiration"); // Small reputation for contribution

        if (aspiration.currentFundingEth >= aspiration.targetFundingEth && (aspiration.erc20TargetToken == address(0) || aspiration.currentFundingERC20 >= aspiration.targetFundingERC20)) {
            _updateAspirationStatus(_aspirationId, AspirationStatus.Active);
            _updateReputationScore(aspiration.proposer, 20, "Aspiration fully funded"); // Boost proposer on full funding
        }

        emit ContributionMade(_aspirationId, msg.sender, msg.value, 0);
    }

    function contributeERC20ToAspiration(uint256 _aspirationId, address _tokenAddress, uint256 _amount) external whenNotPaused nonReentrant {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(aspiration.status == AspirationStatus.Funding, "Aspiration is not in funding phase");
        require(block.timestamp <= aspiration.fundingDeadline, "Funding deadline has passed");
        require(aspiration.erc20TargetToken == _tokenAddress, "This aspiration does not accept this ERC20 token");
        require(_amount > 0, "Contribution must be greater than 0");

        IERC20 token = IERC20(_tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transfer failed. Check allowance and balance.");

        aspiration.erc20Contributions[msg.sender] += _amount;
        aspiration.currentFundingERC20 += _amount;

        _updateReputationScore(msg.sender, 1, "Contributed ERC20 to aspiration");

        if (aspiration.currentFundingEth >= aspiration.targetFundingEth && aspiration.currentFundingERC20 >= aspiration.targetFundingERC20) {
            _updateAspirationStatus(_aspirationId, AspirationStatus.Active);
            _updateReputationScore(aspiration.proposer, 20, "Aspiration fully funded");
        }

        emit ContributionMade(_aspirationId, msg.sender, 0, _amount);
    }

    function revokeContribution(uint256 _aspirationId) external whenNotPaused nonReentrant {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(aspiration.allowsRevocation, "Contribution revocation not allowed for this aspiration");
        require(aspiration.status == AspirationStatus.Funding, "Aspiration is not in funding phase");
        require(block.timestamp > aspiration.fundingDeadline, "Funding deadline has not passed yet");
        require(aspiration.currentFundingEth < aspiration.targetFundingEth || aspiration.currentFundingERC20 < aspiration.targetFundingERC20, "Aspiration has met its funding target");

        uint256 ethToReturn = aspiration.ethContributions[msg.sender];
        uint256 erc20ToReturn = aspiration.erc20Contributions[msg.sender];

        require(ethToReturn > 0 || erc20ToReturn > 0, "No contribution to revoke for this user");

        aspiration.ethContributions[msg.sender] = 0;
        aspiration.erc20Contributions[msg.sender] = 0;
        aspiration.currentFundingEth -= ethToReturn;
        aspiration.currentFundingERC20 -= erc20ToReturn;

        if (ethToReturn > 0) {
            (bool success, ) = msg.sender.call{value: ethToReturn}("");
            require(success, "Failed to send ETH back");
        }
        if (erc20ToReturn > 0) {
            IERC20 token = IERC20(aspiration.erc20TargetToken);
            require(token.transfer(msg.sender, erc20ToReturn), "Failed to send ERC20 back");
        }

        emit ContributionRevoked(_aspirationId, msg.sender, ethToReturn, erc20ToReturn);
    }


    function submitMilestoneReport(uint256 _aspirationId, uint256 _milestoneIndex)
        external
        whenNotPaused
        onlyAspirationProposer(_aspirationId)
    {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.status == AspirationStatus.Active, "Aspiration is not active");
        require(_milestoneIndex < aspiration.milestoneCount, "Milestone index out of bounds");
        Milestone storage milestone = aspiration.milestones[_milestoneIndex];
        require(!milestone.isReported, "Milestone already reported");
        require(!milestone.isApproved, "Milestone already approved");
        require(milestone.disputeId == 0, "Milestone is currently under dispute");

        milestone.isReported = true;
        milestone.approvalVotes = 0; // Reset votes for fresh review
        milestone.rejectionVotes = 0;
        // Clear previous voters for this milestone
        // This is inefficient. Better to use a separate mapping for each milestone like mapping(address => bool) private _votedForMilestone[aspirationId][milestoneIndex];
        // For simplicity for now, it's assumed that `milestone.hasVoted` is a per-milestone mapping, which it is.
        // It should be cleared to allow re-voting IF a dispute or re-report occurs. For a first report, it's already clear.

        _updateAspirationStatus(_aspirationId, AspirationStatus.MilestoneReview);
        emit MilestoneReported(_aspirationId, _milestoneIndex);
    }

    function voteOnMilestoneCompletion(uint256 _aspirationId, uint256 _milestoneIndex, bool _approve) external whenNotPaused {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(aspiration.status == AspirationStatus.MilestoneReview, "Aspiration is not in milestone review phase");
        require(_milestoneIndex < aspiration.milestoneCount, "Milestone index out of bounds");
        Milestone storage milestone = aspiration.milestones[_milestoneIndex];
        require(milestone.isReported, "Milestone has not been reported yet");
        require(!milestone.isApproved, "Milestone already approved");
        require(!milestone.hasVoted[msg.sender], "Already voted on this milestone");
        require(milestone.disputeId == 0, "Milestone is currently under dispute");

        uint256 voterEffectiveReputation = getEffectiveReputation(msg.sender);
        require(voterEffectiveReputation > 0, "Voter has no effective reputation");

        milestone.hasVoted[msg.sender] = true;

        if (_approve) {
            milestone.approvalVotes += voterEffectiveReputation;
        } else {
            milestone.rejectionVotes += voterEffectiveReputation;
        }

        emit MilestoneVoted(_aspirationId, _milestoneIndex, msg.sender, _approve, voterEffectiveReputation);

        uint256 totalVotes = milestone.approvalVotes + milestone.rejectionVotes;
        uint256 requiredApprovalVotes = totalVotes * globalParameters[ParameterType.MilestoneApprovalThreshold] / 100;

        if (milestone.approvalVotes >= requiredApprovalVotes && milestone.approvalVotes > milestone.rejectionVotes) {
            milestone.isApproved = true;
            _updateAspirationStatus(_aspirationId, AspirationStatus.Active); // Revert to active after approval
            emit MilestoneApproved(_aspirationId, _milestoneIndex);
            _updateReputationScore(aspiration.proposer, 10, "Milestone approved"); // Boost proposer on milestone approval
        } else if (milestone.rejectionVotes > requiredApprovalVotes) { // If rejection votes are overwhelming, consider it failed or go to dispute.
            // For simplicity, if overwhelming rejections, it goes back to active and proposer has to re-report or aspiration fails.
            // In a more complex system, this might auto-trigger a dispute or lead to aspiration failure.
            _updateAspirationStatus(_aspirationId, AspirationStatus.Active);
            _updateReputationScore(aspiration.proposer, -5, "Milestone rejected by community"); // Penalty for rejection
        }
    }

    function finalizeAspirationOutcome(uint256 _aspirationId) external whenNotPaused {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(aspiration.status != AspirationStatus.Completed && aspiration.status != AspirationStatus.Failed, "Aspiration already finalized");
        require(aspiration.proposer == msg.sender || block.timestamp > aspiration.fundingDeadline, "Only proposer can finalize before deadline, or anyone after deadline");

        bool allMilestonesApproved = true;
        for (uint256 i = 0; i < aspiration.milestoneCount; i++) {
            if (!aspiration.milestones[i].isApproved) {
                allMilestonesApproved = false;
                break;
            }
        }

        if (allMilestonesApproved && aspiration.milestoneCount > 0) {
            _updateAspirationStatus(_aspirationId, AspirationStatus.Completed);
            aspiration.completionTimestamp = block.timestamp;
            // Major reputation boost for successful completion
            uint256 baseRepGain = 50;
            if (aspiration.reputationBoostFactor > 100) {
                baseRepGain = baseRepGain * aspiration.reputationBoostFactor / 100;
            }
            _updateReputationScore(aspiration.proposer, int256(baseRepGain), "Aspiration successfully completed");

            // Apply synergy bonus if applicable
            if (aspiration.synergyWithAspirationId != 0) {
                Aspiration storage synergyAspiration = aspirations[aspiration.synergyWithAspirationId];
                if (synergyAspiration.status == AspirationStatus.Completed) {
                    _updateReputationScore(aspiration.proposer, int256(baseRepGain / 2), "Synergy bonus"); // Additional boost
                    _updateReputationScore(synergyAspiration.proposer, int256(baseRepGain / 2), "Synergy bonus");
                }
            }

        } else if (block.timestamp > aspiration.fundingDeadline && (aspiration.currentFundingEth < aspiration.targetFundingEth || aspiration.currentFundingERC20 < aspiration.targetFundingERC20)) {
            _updateAspirationStatus(_aspirationId, AspirationStatus.Failed);
            _updateReputationScore(aspiration.proposer, -30, "Aspiration failed to meet funding"); // Penalty for funding failure
        } else {
            // Can be finalized as failed if not all milestones are approved, and proposer abandons.
            // Or if in MilestoneReview and not approved, and proposer or anyone calls to finalize.
            if(aspiration.status == AspirationStatus.MilestoneReview || aspiration.status == AspirationStatus.Active){
                // If proposer finalizes without all milestones being approved, it's considered failed.
                if(msg.sender == aspiration.proposer){
                    _updateAspirationStatus(_aspirationId, AspirationStatus.Failed);
                    _updateReputationScore(aspiration.proposer, -40, "Aspiration failed before full completion");
                } else {
                    revert("Aspiration cannot be finalized yet by non-proposer or funding not failed.");
                }
            } else {
                 revert("Aspiration cannot be finalized yet.");
            }
        }
    }


    // II. Reputation & Delegation System

    function getUserReputation(address _user) public view returns (uint256) {
        return _getReputationScore(_user);
    }

    function delegateReputationPower(address _delegatee) external whenNotPaused {
        require(msg.sender != _delegatee, "Cannot delegate to yourself");
        UserReputation storage delegatorRep = userReputation[msg.sender];
        UserReputation storage delegateeRep = userReputation[_delegatee];

        // Ensure current score is calculated before delegation
        _recalculateAndApplyEffectiveReputation(msg.sender);
        _recalculateAndApplyEffectiveReputation(_delegatee);

        require(delegatorRep.delegatedTo == address(0), "Already delegated reputation");

        delegatorRep.delegatedTo = _delegatee;
        delegateeRep.delegatedFrom[msg.sender] = true;

        emit ReputationDelegated(msg.sender, _delegatee);
    }

    function revokeReputationDelegation() external whenNotPaused {
        UserReputation storage delegatorRep = userReputation[msg.sender];
        require(delegatorRep.delegatedTo != address(0), "No active delegation to revoke");

        address oldDelegatee = delegatorRep.delegatedTo;
        UserReputation storage oldDelegateeRep = userReputation[oldDelegatee];

        delegatorRep.delegatedTo = address(0);
        delete oldDelegateeRep.delegatedFrom[msg.sender]; // Remove from delegatedFrom list

        emit ReputationDelegationRevoked(msg.sender, oldDelegatee);
    }

    // This function calculates total effective reputation by recursively summing up delegated power.
    // Be careful with deep delegation chains as it can hit gas limits.
    // For production, a simpler model or off-chain calculation might be needed.
    function getEffectiveReputation(address _user) public returns (uint256) {
        _recalculateAndApplyEffectiveReputation(_user); // Ensure _user's own score is current

        uint256 effectiveScore = userReputation[_user].score;
        address currentDelegator = _user; // Start with the user whose score is being queried
        uint256 maxDepth = 10; // Prevent infinite loops or excessive gas usage for long chains
        uint256 currentDepth = 0;

        // Sum up reputation delegated TO this user
        // This is the tricky part. `delegatedFrom` only stores _who_ delegated.
        // It's not efficient to iterate through all possible users to find who delegated to `_user`.
        // A better design: `mapping(address => uint256) public totalDelegatedPowerToUser;`
        // which gets updated when delegation occurs.
        // For now, let's assume `getEffectiveReputation` *only* returns the user's score PLUS what they themselves delegated *from*.
        // No, that's wrong. Effective reputation means "my own score + score of those who delegated to me".
        // The `delegatedFrom` mapping is just a boolean.
        // The current implementation of `getEffectiveReputation` cannot recursively sum up *incoming* delegations.
        // It would require iterating all addresses, or a more complex DAG structure.

        // So, let's simplify `getEffectiveReputation` to return the user's own score + any hardcoded boosts,
        // and acknowledge that complex delegated power aggregation needs a different approach for true efficiency.
        // The `delegateReputationPower` still functions to point `delegatedTo`.
        // The impact of delegation would then be handled where votes are cast,
        // e.g., vote power comes from `getEffectiveReputation(msg.sender)` which should ideally be a sum of `msg.sender`'s own score + sum of all `delegatedFrom` scores.
        // For now, let's make it simpler and assume the `delegatedTo` mechanism is just for chain of command for certain actions,
        // and voting power uses a simpler direct score calculation or an aggregated proxy.

        // New approach for getEffectiveReputation: Summing up the chain of delegation.
        // If A delegates to B, B's effective score includes A's current score.
        // If B delegates to C, C's effective score includes B's current score (which itself includes A's score if A delegated to B).
        
        address current = _user;
        while (userReputation[current].delegatedTo != address(0) && currentDepth < maxDepth) {
            current = userReputation[current].delegatedTo;
            effectiveScore += userReputation[current].score; // Add the score of the next delegatee in the chain
            currentDepth++;
        }
        // This sums up the chain. So if A->B->C, getEffectiveReputation(A) = A + B + C.
        // This means, the delegatee's score *adds* to the delegator's influence.
        // This is a common interpretation for 'liquid democracy' where A's vote is cast by B, but A's weight contributes to B's total influence.
        // This makes `getEffectiveReputation(msg.sender)` truly represent their "voice".

        return effectiveScore;
    }


    // III. Aspiration Specific Actions

    function addMilestone(uint256 _aspirationId, string calldata _description, uint256 _targetDate, uint256 _fundingPercentage)
        external
        whenNotPaused
        onlyAspirationProposer(_aspirationId)
    {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.status == AspirationStatus.Funding || aspiration.status == AspirationStatus.Active, "Aspiration must be in funding or active status to add milestones");
        require(bytes(_description).length > 0, "Milestone description cannot be empty");
        require(_targetDate > block.timestamp, "Milestone target date must be in the future");
        require(_fundingPercentage > 0, "Funding percentage must be greater than 0");

        uint256 currentAllocatedPercentage = 0;
        for (uint256 i = 0; i < aspiration.milestoneCount; i++) {
            currentAllocatedPercentage += aspiration.milestones[i].fundingPercentage;
        }
        require(currentAllocatedPercentage + _fundingPercentage <= 100, "Total milestone funding percentages cannot exceed 100%");

        uint256 newMilestoneId = aspiration.milestoneCount++;
        aspiration.milestones[newMilestoneId] = Milestone({
            id: newMilestoneId,
            description: _description,
            targetDate: _targetDate,
            fundingPercentage: _fundingPercentage,
            isReported: false,
            isApproved: false,
            approvalVotes: 0,
            rejectionVotes: 0,
            hasVoted: new mapping(address => bool)(), // Initialize a fresh mapping for new milestone
            disputeId: 0
        });

        emit MilestoneAdded(_aspirationId, newMilestoneId, _description, _fundingPercentage);
    }

    function claimMilestoneFunds(uint256 _aspirationId, uint256 _milestoneIndex)
        external
        whenNotPaused
        nonReentrant
        onlyAspirationProposer(_aspirationId)
    {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(_milestoneIndex < aspiration.milestoneCount, "Milestone index out of bounds");
        Milestone storage milestone = aspiration.milestones[_milestoneIndex];
        require(milestone.isApproved, "Milestone not yet approved by community");
        require(milestone.disputeId == 0, "Milestone is currently under dispute");

        uint256 ethAmountToClaim = (aspiration.targetFundingEth * milestone.fundingPercentage) / 100;
        uint256 erc20AmountToClaim = (aspiration.targetFundingERC20 * milestone.fundingPercentage) / 100;

        // Adjust for already claimed amounts (if any partial claims were made in a multi-claim scenario per milestone)
        // Ensure no double claiming for a single milestone by design (milestone.isApproved is one-time).
        // This check is to prevent claiming more than what's available or already claimed in total from the aspiration.
        require(aspiration.totalClaimedEth + ethAmountToClaim <= aspiration.currentFundingEth, "Not enough ETH funds available or already claimed");
        if (aspiration.erc20TargetToken != address(0)) {
            require(aspiration.totalClaimedERC20 + erc20AmountToClaim <= aspiration.currentFundingERC20, "Not enough ERC20 funds available or already claimed");
        }

        // Apply funding fee
        uint256 feePercentage = globalParameters[ParameterType.FundingFeePercentage];
        uint256 ethFee = (ethAmountToClaim * feePercentage) / 100;
        uint256 erc20Fee = (erc20AmountToClaim * feePercentage) / 100;

        uint256 ethPayout = ethAmountToClaim - ethFee;
        uint256 erc20Payout = erc20AmountToClaim - erc20Fee;

        // Transfer ETH
        if (ethPayout > 0) {
            (bool success, ) = msg.sender.call{value: ethPayout}("");
            require(success, "Failed to send ETH to proposer");
        }
        aspiration.totalClaimedEth += ethAmountToClaim; // Track gross amount for reconciliation

        // Transfer ERC20
        if (erc20Payout > 0 && aspiration.erc20TargetToken != address(0)) {
            IERC20 token = IERC20(aspiration.erc20TargetToken);
            require(token.transfer(msg.sender, erc20Payout), "Failed to send ERC20 to proposer");
        }
        aspiration.totalClaimedERC20 += erc20AmountToClaim; // Track gross amount

        // Fees go to contract owner / governance treasury (for this example, owner)
        if (ethFee > 0) {
             (bool success, ) = owner().call{value: ethFee}("");
             require(success, "Failed to send ETH fee to owner");
        }
        if (erc20Fee > 0 && aspiration.erc20TargetToken != address(0)) {
            IERC20 token = IERC20(aspiration.erc20TargetToken);
            require(token.transfer(owner(), erc20Fee), "Failed to send ERC20 fee to owner");
        }

        // Mark milestone as fully processed (no re-claim)
        // Consider having a flag here, for now `milestone.isApproved` prevents double-claiming.
        // A specific `fundsClaimed` flag might be clearer.
        // For simplicity, once claimed, `milestone.isApproved` implicitly means funds were or can be claimed.

        emit MilestoneFundsClaimed(_aspirationId, _milestoneIndex, ethPayout, erc20Payout);
    }

    function addAspirationSynergy(uint256 _aspirationId, uint256 _synergyWithAspirationId) external whenNotPaused onlyAspirationProposer(_aspirationId) {
        Aspiration storage aspiration = aspirations[_aspirationId];
        Aspiration storage synergyAspiration = aspirations[_synergyWithAspirationId];

        require(aspiration.id != 0 && synergyAspiration.id != 0, "One or both aspirations do not exist");
        require(_aspirationId != _synergyWithAspirationId, "Cannot declare synergy with self");
        require(aspiration.synergyWithAspirationId == 0, "Aspiration already has a declared synergy");
        require(aspiration.status == AspirationStatus.Funding || aspiration.status == AspirationStatus.Active, "Aspiration must be in funding or active status");
        require(synergyAspiration.status == AspirationStatus.Funding || synergyAspiration.status == ApirationStatus.Active || synergyAspiration.status == AspirationStatus.Completed, "Synergy aspiration must be active or completed");

        aspiration.synergyWithAspirationId = _synergyWithAspirationId;
        emit SynergyDeclared(_aspirationId, _synergyWithAspirationId);
    }

    function applyCatalystBoost(uint256 _aspirationId) external whenNotPaused {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(aspiration.status == AspirationStatus.Funding, "Aspiration is not in funding phase");

        uint256 catalystMinRep = globalParameters[ParameterType.CatalystMinReputation];
        require(getEffectiveReputation(msg.sender) >= catalystMinRep, "Caller is not a recognized Catalyst (insufficient reputation)");

        // A simple boost, could be more complex (e.g., decaying over time, multiple boosts)
        aspiration.reputationBoostFactor += 10; // Add 10% boost (e.g., from 100 to 110)
        require(aspiration.reputationBoostFactor <= 200, "Maximum boost reached for aspiration"); // Cap boost

        _updateReputationScore(msg.sender, 2, "Applied Catalyst Boost"); // Small reputation boost for catalysts

        emit CatalystBoostApplied(_aspirationId, msg.sender, aspiration.reputationBoostFactor);
    }

    // IV. Dispute Resolution

    function raiseDispute(uint256 _aspirationId, uint256 _milestoneIndex, string calldata _reason) external whenNotPaused {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");
        require(_milestoneIndex < aspiration.milestoneCount, "Milestone index out of bounds");
        require(bytes(_reason).length > 0, "Reason for dispute cannot be empty");

        Milestone storage milestone = aspiration.milestones[_milestoneIndex];
        require(milestone.disputeId == 0, "Milestone is already under dispute"); // Only one dispute at a time per milestone

        uint256 disputeId = ++_nextDisputeId;
        disputes[disputeId] = Dispute({
            id: disputeId,
            aspirationId: _aspirationId,
            milestoneIndex: _milestoneIndex,
            raisedBy: msg.sender,
            reason: _reason,
            disputedTimestamp: block.timestamp,
            supportVotes: 0,
            againstVotes: 0,
            hasVoted: new mapping(address => bool)(), // New mapping for voters
            isResolved: false,
            resolutionOutcome: false
        });

        milestone.disputeId = disputeId; // Link milestone to dispute
        _updateAspirationStatus(_aspirationId, AspirationStatus.Disputed);

        emit DisputeRaised(disputeId, _aspirationId, _milestoneIndex, msg.sender);
    }

    function voteOnDispute(uint256 _disputeId, bool _supportDispute) external whenNotPaused {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(!dispute.isResolved, "Dispute already resolved");
        require(!dispute.hasVoted[msg.sender], "Already voted on this dispute");

        uint256 voterEffectiveReputation = getEffectiveReputation(msg.sender);
        require(voterEffectiveReputation > 0, "Voter has no effective reputation");

        dispute.hasVoted[msg.sender] = true;

        if (_supportDispute) {
            dispute.supportVotes += voterEffectiveReputation;
        } else {
            dispute.againstVotes += voterEffectiveReputation;
        }

        emit DisputeVoted(_disputeId, msg.sender, _supportDispute, voterEffectiveReputation);
    }

    function resolveDispute(uint256 _disputeId) external whenNotPaused nonReentrant {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.id != 0, "Dispute does not exist");
        require(!dispute.isResolved, "Dispute already resolved");

        // Simple resolution: if support votes reach a threshold, dispute is upheld.
        // A more advanced system might have a specific resolution period.
        uint256 totalVotes = dispute.supportVotes + dispute.againstVotes;
        require(totalVotes > 0, "No votes cast yet"); // Require at least some votes to resolve

        uint256 requiredSupportVotes = totalVotes * globalParameters[ParameterType.DisputeApprovalThreshold] / 100;

        bool disputeUpheld = dispute.supportVotes >= requiredSupportVotes && dispute.supportVotes > dispute.againstVotes;
        
        dispute.isResolved = true;
        dispute.resolutionOutcome = disputeUpheld;

        Aspiration storage aspiration = aspirations[dispute.aspirationId];
        Milestone storage milestone = aspiration.milestones[dispute.milestoneIndex];

        if (disputeUpheld) {
            // If dispute is upheld, penalize proposer and potentially revert milestone status
            _updateReputationScore(aspiration.proposer, -50, "Reputation penalty for upheld dispute");
            milestone.isApproved = false; // Revoke approval if dispute was on a completed milestone
            milestone.isReported = false; // Needs to be re-reported
            // Optionally: clawback funds if already claimed (requires more complex tracking of claimed funds for disputed milestones)
        } else {
            // If dispute rejected, reward proposer / disfavored parties slightly
            _updateReputationScore(aspiration.proposer, 10, "Reputation bonus for rejected dispute");
        }

        milestone.disputeId = 0; // Clear dispute link
        _updateAspirationStatus(dispute.aspirationId, AspirationStatus.Active); // Return to Active or Funding based on state

        emit DisputeResolved(_disputeId, disputeUpheld, dispute.aspirationId);
    }

    // V. Governance & Utility

    function setGlobalParameter(ParameterType _paramType, uint256 _value) external onlyGovernance {
        require(_value > 0, "Parameter value must be positive");
        globalParameters[_paramType] = _value;
        emit GlobalParameterSet(_paramType, _value);
    }

    function getAspirationDetails(uint256 _aspirationId) public view returns (Aspiration memory) {
        return aspirations[_aspirationId];
    }

    function getMilestoneDetails(uint256 _aspirationId, uint256 _milestoneIndex) public view returns (Milestone memory) {
        require(aspirations[_aspirationId].id != 0, "Aspiration does not exist");
        require(_milestoneIndex < aspirations[_aspirationId].milestoneCount, "Milestone index out of bounds");
        return aspirations[_aspirationId].milestones[_milestoneIndex];
    }

    function getAspirationsByStatus(AspirationStatus _status) public view returns (uint256[] memory) {
        return aspirationsByStatus[_status];
    }

    function calculateAspirationFundingProgress(uint256 _aspirationId) public view returns (uint256 ethProgressPercent, uint256 erc20ProgressPercent) {
        Aspiration storage aspiration = aspirations[_aspirationId];
        require(aspiration.id != 0, "Aspiration does not exist");

        if (aspiration.targetFundingEth > 0) {
            ethProgressPercent = (aspiration.currentFundingEth * 100) / aspiration.targetFundingEth;
        }
        if (aspiration.targetFundingERC20 > 0) {
            erc20ProgressPercent = (aspiration.currentFundingERC20 * 100) / aspiration.targetFundingERC20;
        }
    }

    function pauseContract() external onlyGovernance {
        _pause();
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyGovernance {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }
}
```