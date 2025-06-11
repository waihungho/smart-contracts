Okay, let's design a smart contract that incorporates several advanced and creative concepts beyond typical open-source patterns. We'll create an `OmniFund` contract – a decentralized, participant-governed fund with dynamic features, reputation mechanics, non-transferable participation units, and flexible distribution rules.

**Core Concepts:**

1.  **Non-Transferable Participation:** Participants don't hold fungible tokens representing shares. Instead, they earn non-transferable "Participation Units" and "Reputation Points". This encourages long-term commitment and prevents speculative trading of fund shares.
2.  **Dynamic Funding Rounds:** The fund can operate in distinct funding rounds, each with configurable rules (min/max contribution, duration).
3.  **Weighted Governance:** Voting power on investment proposals or fund parameters is a combination of a participant's Participation Units and Reputation Points, allowing reputation (earned through contributions, activity, or admin grants) to influence decisions.
4.  **Flexible Distribution Logic:** Profits or distributed assets are allocated based on a configurable formula combining Participation Units, Reputation Points, and potentially time-based factors or vesting schedules (simulated).
5.  **Timed Withdrawal/Leaving:** Participants cannot instantly cash out. Initiating a withdrawal may subject their claimable amount to a vesting period or penalty, encouraging stability.
6.  **Asset Agnostic (ERC-20):** Can hold and distribute various ERC-20 tokens.

---

**Outline and Function Summary:**

**Contract: OmniFund**

A decentralized, dynamic investment fund managing multiple ERC-20 assets. Participation is non-transferable, based on earned units and reputation. Governance and distribution are weighted by these factors.

**State Variables:**

*   `owner`: Address of the contract owner.
*   `admins`: Mapping of addresses to boolean, indicating administrator status. Admins have elevated control over parameters and emergency actions.
*   `paused`: Boolean indicating if the contract is paused (emergency state).
*   `allowedAssets`: Mapping of ERC20 token addresses to boolean, indicating which tokens are accepted for contribution and distribution.
*   `participants`: Mapping of participant addresses to `Participant` structs. Stores individual participant data (units, reputation, withdrawal status, claimed amounts).
*   `totalParticipationUnits`: Total units ever issued across all participants.
*   `totalReputationPoints`: Total reputation points across all participants.
*   `fundBalances`: Mapping of ERC20 token addresses to the contract's balance of that token.
*   `currentRound`: Stores the state of the active funding round.
*   `nextRoundConfig`: Stores the configuration for the *next* funding round, set by admins.
*   `proposalCounter`: Counter for unique investment proposal IDs.
*   `proposals`: Mapping of proposal IDs to `InvestmentProposal` structs. Stores details and voting results for governance proposals.
*   `distributionParameters`: Stores the weights and rules currently used for calculating asset distributions.
*   `participantClaimedAmounts`: Mapping of participant address -> token address -> amount claimed. Tracks how much each participant has already claimed for each token.

**Structs:**

*   `Participant`: Details for each participant (units, reputation, join round, withdrawal initiation time, cancelled withdrawal count).
*   `FundingRoundConfig`: Configuration for a funding round (start time, end time, min/max contribution, target amount, unit issuance rate).
*   `FundingRoundState`: State of the current funding round (round number, config, total raised).
*   `InvestmentProposal`: Details for a proposal (proposer, target asset, amount, description, voting end time, state, votes for/against).
*   `DistributionParameters`: Weights for calculating distribution shares (e.g., how much units vs reputation influence payout).

**Events:**

*   `AdminAdded`, `AdminRemoved`, `AdminRoleTransferred`
*   `Paused`, `Unpaused`
*   `AllowedAssetSet`
*   `FundingRoundConfigured`, `FundingRoundStarted`, `FundingRoundEnded`
*   `Contributed`
*   `ParticipantJoined`
*   `UnitsIssued`, `ReputationAdded`, `ReputationSlashed`, `UnitsBurned`
*   `ProposalSubmitted`, `VotedOnProposal`, `ProposalExecuted`, `ProposalFailed`
*   `DistributionParametersUpdated`
*   `InvestmentReturnsReceived`
*   `AssetsClaimed`
*   `WithdrawalInitiated`, `WithdrawalCancelled`

**Modifiers:**

*   `onlyOwner`: Only the contract owner can call.
*   `onlyAdmin`: Only owner or an admin can call.
*   `whenNotPaused`: Function can only be called when the contract is not paused.
*   `whenPaused`: Function can only be called when the contract is paused.
*   `onlyParticipant`: Only registered participants can call.
*   `isActiveRound`: Function requires an active funding round.
*   `isProposalActive`: Function requires the proposal to be in the voting phase.
*   `isProposalExecutable`: Function requires the proposal to be approved and not yet executed.

**Functions (Total: 33)**

*   **Admin & Setup (9 functions)**
    1.  `constructor(address[] initialAdmins)`: Initializes the owner and adds initial admins.
    2.  `addAdmin(address _admin)`: Grants admin role. (`onlyOwner`)
    3.  `removeAdmin(address _admin)`: Revokes admin role. (`onlyOwner`)
    4.  `transferAdminRole(address _newOwner)`: Transfers contract ownership. (`onlyOwner`)
    5.  `setAllowedAsset(address _token, bool _isAllowed)`: Whitelists/delists an ERC20 asset for contribution/distribution. (`onlyAdmin`)
    6.  `configureFundingRound(uint256 _startTime, uint256 _endTime, uint256 _minContribution, uint256 _maxContribution, uint256 _targetAmount, uint256 _unitIssuanceRate)`: Sets parameters for the *next* funding round. (`onlyAdmin`)
    7.  `startFundingRound()`: Initiates the next configured funding round. (`onlyAdmin`, `whenNotPaused`)
    8.  `endFundingRound()`: Concludes the current funding round. (`onlyAdmin`, `whenNotPaused`)
    9.  `pauseFund()`: Pauses core contract interactions in emergency. (`onlyAdmin`)
    10. `unpauseFund()`: Unpauses the contract. (`onlyAdmin`)

*   **Participant Interaction (Funding & Info) (4 functions)**
    11. `contribute(uint256 _amount, address _token)`: Allows participants (new or existing) to contribute whitelisted tokens during an active funding round. Issues Participation Units. (`whenNotPaused`, `isActiveRound`)
    12. `getParticipantInfo(address _participant)`: View function to retrieve a participant's details.
    13. `getFundBalance(address _token)`: View function to retrieve the contract's balance of a specific token.
    14. `getCurrentRoundInfo()`: View function to retrieve details of the current funding round.

*   **Participant Interaction (Governance) (6 functions)**
    15. `submitInvestmentProposal(address _targetAsset, uint256 _amount, string calldata _description, uint256 _votingDuration)`: Allows participants to propose using fund assets for an investment. Requires minimum units/reputation to propose. (`onlyParticipant`, `whenNotPaused`)
    16. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows participants to vote on an active proposal using their weighted voting power (Units + Reputation). Cannot change vote. (`onlyParticipant`, `whenNotPaused`, `isProposalActive`)
    17. `delegateVotingPower(address _delegatee)`: Allows a participant to delegate their voting power to another address. (`onlyParticipant`)
    18. `revokeVotingPower()`: Revokes current voting delegation. (`onlyParticipant`)
    19. `getProposalInfo(uint256 _proposalId)`: View function to retrieve details of a specific proposal.
    20. `getProposalCount()`: View function to get the total number of proposals.

*   **Fund Management & Execution (3 functions)**
    21. `executeInvestmentProposal(uint256 _proposalId)`: Executes an approved proposal by transferring funds to the target. (`onlyAdmin`, `whenNotPaused`, `isProposalExecutable`)
    22. `receiveInvestmentReturns(address _token, uint256 _amount)`: Function to handle receiving investment returns into the contract. *Requires external call or integration.* (`onlyAdmin`, `whenNotPaused`)
    23. `updateDistributionParameters(uint256 _unitWeight, uint256 _reputationWeight, uint256 _withdrawalVestingPeriod)`: Sets the parameters used for calculating claimable assets. (`onlyAdmin`, `whenNotPaused`)

*   **Participant Interaction (Distribution & Withdrawal) (6 functions)**
    24. `calculateClaimableAssets(address _participant, address _token)`: View function calculating the *potential* claimable amount for a participant for a specific token, considering units, reputation, claimed amounts, and withdrawal vesting.
    25. `claimAssets(address _token)`: Allows a participant to claim their calculated claimable assets for a specific token. Subject to withdrawal vesting period if initiated. (`onlyParticipant`, `whenNotPaused`)
    26. `initiateParticipantWithdrawal()`: A participant signals intent to withdraw. Starts a vesting period for future claims. (`onlyParticipant`, `whenNotPaused`)
    27. `cancelParticipantWithdrawal()`: A participant cancels their pending withdrawal, potentially resetting the vesting clock or incurring a penalty (simulated by tracking cancellations). (`onlyParticipant`, `whenNotPaused`)
    28. `getParticipantWithdrawalStatus(address _participant)`: View function to check if a participant has initiated withdrawal and when the vesting period ends (if applicable).
    29. `getClaimedAmount(address _participant, address _token)`: View function to see how much a participant has claimed for a token.

*   **Reputation Management (Admin) (3 functions)**
    30. `addReputation(address _participant, uint256 _amount)`: Admins can grant reputation points (e.g., for non-financial contributions). (`onlyAdmin`)
    31. `slashReputation(address _participant, uint256 _amount)`: Admins can reduce reputation points (e.g., for malicious behavior). (`onlyAdmin`)
    32. `burnUnits(address _participant, uint256 _amount)`: Admins can burn participant units (e.g., in extreme penalty cases). (`onlyAdmin`)

*   **View Functions (Utility) (1 function)**
    33. `getAllowedAssets()`: View function returning the list of allowed token addresses.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for owner, adding custom admin role

/**
 * @title OmniFund
 * @dev A decentralized investment fund with non-transferable participation units,
 *      reputation-weighted governance, dynamic funding rounds, and flexible distribution logic.
 */
contract OmniFund is Ownable, Pausable {

    // --- Outline and Function Summary ---
    // This contract represents a sophisticated, dynamic decentralized fund.
    // Participants contribute allowed ERC-20 tokens and receive non-transferable
    // Participation Units and Reputation Points. These are used to weighted voting
    // on investment proposals and calculating asset distribution.

    // Core Concepts:
    // - Non-Transferable Participation: Units and Reputation are bound to the address.
    // - Dynamic Funding Rounds: Configurable contribution periods.
    // - Weighted Governance: Voting power = f(Units, Reputation).
    // - Flexible Distribution: Payouts = f(Units, Reputation, DistributionParameters, Vesting).
    // - Timed Withdrawal: Initiating withdrawal may trigger a vesting period.
    // - Asset Agnostic (ERC-20): Can handle multiple token types.

    // State Variables:
    // - owner: Address of the contract owner (inherited from Ownable).
    // - admins: Mapping of addresses to boolean, indicating administrator status.
    // - paused: Boolean indicating if the contract is paused (inherited from Pausable).
    // - allowedAssets: Mapping of ERC20 token addresses to boolean for allowed tokens.
    // - participants: Mapping of participant addresses to Participant structs.
    // - totalParticipationUnits: Total units issued.
    // - totalReputationPoints: Total reputation points.
    // - fundBalances: Mapping of ERC20 token addresses to contract balance.
    // - currentRound: State of the active funding round.
    // - nextRoundConfig: Configuration for the next funding round.
    // - proposalCounter: Counter for proposal IDs.
    // - proposals: Mapping of proposal IDs to InvestmentProposal structs.
    // - distributionParameters: Weights and rules for distributions.
    // - participantClaimedAmounts: Mapping participant -> token -> amount claimed.

    // Structs:
    // - Participant: Units, reputation, join round, withdrawal state.
    // - FundingRoundConfig: Rules for a round (times, min/max contribution, target, unit rate).
    // - FundingRoundState: Current round details (number, config, raised).
    // - InvestmentProposal: Proposal details (target asset, amount, description, voting, state, votes).
    // - DistributionParameters: Weights (units, reputation) for payout calculation, withdrawal vesting time.

    // Events:
    // - AdminAdded, AdminRemoved, AdminRoleTransferred
    // - Paused, Unpaused (from Pausable)
    // - AllowedAssetSet
    // - FundingRoundConfigured, FundingRoundStarted, FundingRoundEnded
    // - Contributed, ParticipantJoined, UnitsIssued, ReputationAdded, ReputationSlashed, UnitsBurned
    // - ProposalSubmitted, VotedOnProposal, ProposalExecuted, ProposalFailed
    // - DistributionParametersUpdated
    // - InvestmentReturnsReceived
    // - AssetsClaimed
    // - WithdrawalInitiated, WithdrawalCancelled

    // Modifiers:
    // - onlyOwner (from Ownable), onlyAdmin, whenNotPaused (from Pausable), whenPaused (from Pausable)
    // - onlyParticipant, isActiveRound, isProposalActive, isProposalExecutable

    // Functions (33 Total):
    // - Admin & Setup (10 functions): constructor, addAdmin, removeAdmin, transferAdminRole, setAllowedAsset, configureFundingRound, startFundingRound, endFundingRound, pauseFund, unpauseFund.
    // - Participant Interaction (Funding & Info) (4 functions): contribute, getParticipantInfo, getFundBalance, getCurrentRoundInfo.
    // - Participant Interaction (Governance) (6 functions): submitInvestmentProposal, voteOnProposal, delegateVotingPower, revokeVotingPower, getProposalInfo, getProposalCount.
    // - Fund Management & Execution (3 functions): executeInvestmentProposal, receiveInvestmentReturns, updateDistributionParameters.
    // - Participant Interaction (Distribution & Withdrawal) (6 functions): calculateClaimableAssets, claimAssets, initiateParticipantWithdrawal, cancelParticipantWithdrawal, getParticipantWithdrawalStatus, getClaimedAmount.
    // - Reputation Management (Admin) (3 functions): addReputation, slashReputation, burnUnits.
    // - View Functions (Utility) (1 function): getAllowedAssets.

    // --- State Variables ---

    mapping(address => bool) public admins;
    mapping(address => bool) public allowedAssets;

    struct Participant {
        uint256 participationUnits;
        uint256 reputationPoints;
        uint256 joinedRound; // The round number they first joined
        uint256 withdrawalInitiatedTime; // Timestamp when withdrawal was initiated (0 if not initiated)
        uint256 cancelledWithdrawalCount; // Counter for how many times they cancelled withdrawal
        address delegatee; // Address they delegated their voting power to (address(0) if none)
    }
    mapping(address => Participant) public participants;

    uint256 public totalParticipationUnits;
    uint256 public totalReputationPoints;

    mapping(address => uint256) public fundBalances;

    struct FundingRoundConfig {
        uint256 startTime;
        uint256 endTime;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 targetAmount; // Target in a specific asset (defined when starting round, e.g., ETH or stablecoin)
        address targetAsset;
        uint256 unitIssuanceRate; // Units issued per 1 unit of targetAsset (e.g., 1e18 for 1 token = X units)
    }
    struct FundingRoundState {
        uint256 roundNumber;
        FundingRoundConfig config;
        uint256 raisedAmount;
        bool isActive;
    }
    FundingRoundState public currentRound;
    FundingRoundConfig public nextRoundConfig; // Config stored for the *next* round

    enum ProposalState { Pending, Active, Approved, Rejected, Executed, Failed }
    struct InvestmentProposal {
        uint256 proposalId;
        address proposer;
        address targetAsset; // The asset requested for the investment
        uint256 amount;      // The amount of the target asset requested
        string description;  // IPFS hash or URL linking to proposal details
        uint256 submissionTime;
        uint256 votingEndTime;
        ProposalState state;
        uint256 votesForUnits; // Total units voting For
        uint256 votesForReputation; // Total reputation voting For
        uint256 votesAgainstUnits; // Total units voting Against
        uint256 votesAgainstReputation; // Total reputation voting Against
        mapping(address => bool) hasVoted; // To ensure participants vote only once
    }
    uint256 public proposalCounter;
    mapping(uint256 => InvestmentProposal) public proposals;

    struct DistributionParameters {
        uint256 unitWeight; // How much 1 unit is weighted (e.g., 100)
        uint256 reputationWeight; // How much 1 reputation point is weighted (e.g., 10)
        uint256 withdrawalVestingPeriod; // Time in seconds after withdrawal initiation before funds are fully claimable
    }
    DistributionParameters public distributionParameters;

    mapping(address => mapping(address => uint256)) public participantClaimedAmounts;

    // Internal state to track total earnings received per token, used for distribution calculation
    mapping(address => uint256) internal totalDistributedEarnings;
    // Mapping participant address => token address => earnings distribution basis
    // Stores the participant's weighted share basis when the last distribution parameters were updated or earnings received
    // This is a simplified approach; a more robust system would track this per earnings event.
    mapping(address => mapping(address => uint256)) internal participantDistributionBasis;
    mapping(address => uint256) internal totalDistributionBasis; // total basis for a given token's earnings

    // --- Events ---

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event AdminRoleTransferred(address indexed newOwner);
    // Paused, Unpaused events inherited from Pausable

    event AllowedAssetSet(address indexed token, bool isAllowed);

    event FundingRoundConfigured(uint256 startTime, uint256 endTime, uint256 minContribution, uint256 maxContribution, uint256 targetAmount, address indexed targetAsset, uint256 unitIssuanceRate);
    event FundingRoundStarted(uint256 indexed roundNumber, uint256 startTime, uint256 endTime, address indexed targetAsset);
    event FundingRoundEnded(uint256 indexed roundNumber, uint256 raisedAmount);

    event Contributed(address indexed contributor, address indexed token, uint256 amount, uint256 unitsIssued);
    event ParticipantJoined(address indexed participant, uint256 roundNumber);
    event UnitsIssued(address indexed participant, uint256 amount);
    event ReputationAdded(address indexed participant, uint256 amount, address indexed granter);
    event ReputationSlashed(address indexed participant, uint256 amount, address indexed slasher);
    event UnitsBurned(address indexed participant, uint256 amount, address indexed burner);

    event ProposalSubmitted(uint256 indexed proposalId, address indexed proposer, address targetAsset, uint256 amount);
    event VotedOnProposal(uint256 indexed proposalId, address indexed voter, bool support, uint256 votingPowerUnits, uint256 votingPowerReputation);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor, address targetAsset, uint256 amount);
    event ProposalFailed(uint256 indexed proposalId);

    event DistributionParametersUpdated(uint256 unitWeight, uint256 reputationWeight, uint256 withdrawalVestingPeriod);
    event InvestmentReturnsReceived(address indexed token, uint256 amount);
    event AssetsClaimed(address indexed participant, address indexed token, uint256 amount);

    event WithdrawalInitiated(address indexed participant, uint256 timestamp);
    event WithdrawalCancelled(address indexed participant, uint256 timestamp);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(admins[msg.sender] || owner() == msg.sender, "OmniFund: Not an admin");
        _;
    }

    modifier onlyParticipant() {
        require(participants[msg.sender].participationUnits > 0 || participants[msg.sender].reputationPoints > 0, "OmniFund: Not a participant");
        _;
    }

    modifier isActiveRound() {
        require(currentRound.isActive && block.timestamp >= currentRound.config.startTime && block.timestamp < currentRound.config.endTime, "OmniFund: No active funding round");
        _;
    }

    modifier isProposalActive(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "OmniFund: Invalid proposal ID");
        InvestmentProposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active && block.timestamp < proposal.votingEndTime, "OmniFund: Proposal not active for voting");
        _;
    }

    modifier isProposalExecutable(uint256 _proposalId) {
         require(_proposalId > 0 && _proposalId <= proposalCounter, "OmniFund: Invalid proposal ID");
         InvestmentProposal storage proposal = proposals[_proposalId];
         require(proposal.state == ProposalState.Approved, "OmniFund: Proposal not approved");
         require(fundBalances[proposal.targetAsset] >= proposal.amount, "OmniFund: Insufficient funds for proposal");
         _;
    }


    // --- Functions ---

    // 1. constructor
    constructor(address[] memory initialAdmins) Ownable(msg.sender) Pausable() {
        for (uint i = 0; i < initialAdmins.length; i++) {
            admins[initialAdmins[i]] = true;
            emit AdminAdded(initialAdmins[i]);
        }
        // Set default distribution parameters
        distributionParameters = DistributionParameters({
            unitWeight: 100, // Default: Units have more weight
            reputationWeight: 10,
            withdrawalVestingPeriod: 30 * 24 * 60 * 60 // Default: 30 days vesting after initiating withdrawal
        });
        emit DistributionParametersUpdated(distributionParameters.unitWeight, distributionParameters.reputationWeight, distributionParameters.withdrawalVestingPeriod);
    }

    // 2. addAdmin
    function addAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "OmniFund: Zero address");
        require(!admins[_admin], "OmniFund: Already an admin");
        admins[_admin] = true;
        emit AdminAdded(_admin);
    }

    // 3. removeAdmin
    function removeAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "OmniFund: Zero address");
        require(admins[_admin], "OmniFund: Not an admin");
        admins[_admin] = false;
        emit AdminRemoved(_admin);
    }

    // 4. transferAdminRole - Transfer Ownership (Owner is the highest admin)
    function transferAdminRole(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "OmniFund: Zero address");
        _transferOwnership(_newOwner); // Uses Ownable's internal function
        emit AdminRoleTransferred(_newOwner);
    }

    // 5. setAllowedAsset
    function setAllowedAsset(address _token, bool _isAllowed) external onlyAdmin {
        require(_token != address(0), "OmniFund: Zero address");
        allowedAssets[_token] = _isAllowed;
        emit AllowedAssetSet(_token, _isAllowed);
    }

    // 6. configureFundingRound
    function configureFundingRound(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _targetAmount,
        address _targetAsset,
        uint256 _unitIssuanceRate // e.g., 1e18 if 1 token = 1 unit
    ) external onlyAdmin {
        require(_startTime > block.timestamp, "OmniFund: Start time must be in the future");
        require(_endTime > _startTime, "OmniFund: End time must be after start time");
        require(_minContribution > 0, "OmniFund: Min contribution must be greater than 0");
        require(_maxContribution >= _minContribution, "OmniFund: Max contribution must be >= min contribution");
        require(allowedAssets[_targetAsset], "OmniFund: Target asset not allowed");
        require(_unitIssuanceRate > 0, "OmniFund: Unit issuance rate must be > 0");

        nextRoundConfig = FundingRoundConfig({
            startTime: _startTime,
            endTime: _endTime,
            minContribution: _minContribution,
            maxContribution: _maxContribution,
            targetAmount: _targetAmount,
            targetAsset: _targetAsset,
            unitIssuanceRate: _unitIssuanceRate
        });

        emit FundingRoundConfigured(_startTime, _endTime, _minContribution, _maxContribution, _targetAmount, _targetAsset, _unitIssuanceRate);
    }

    // 7. startFundingRound
    function startFundingRound() external onlyAdmin whenNotPaused {
        require(!currentRound.isActive, "OmniFund: A round is already active");
        require(nextRoundConfig.startTime > 0 && nextRoundConfig.startTime <= block.timestamp, "OmniFund: Next round configuration not set or start time not reached");

        currentRound = FundingRoundState({
            roundNumber: currentRound.roundNumber + 1,
            config: nextRoundConfig,
            raisedAmount: 0,
            isActive: true
        });

        // Reset nextRoundConfig
        nextRoundConfig = FundingRoundConfig(0, 0, 0, 0, 0, address(0), 0);

        emit FundingRoundStarted(currentRound.roundNumber, currentRound.config.startTime, currentRound.config.endTime, currentRound.config.targetAsset);
    }

    // 8. endFundingRound
    function endFundingRound() external onlyAdmin whenNotPaused {
        require(currentRound.isActive, "OmniFund: No active round to end");
        // Can be ended manually by admin, or automatically if block.timestamp >= currentRound.config.endTime
        // require(block.timestamp >= currentRound.config.endTime, "OmniFund: Round end time not reached yet"); // Optional: enforce time

        currentRound.isActive = false;
        emit FundingRoundEnded(currentRound.roundNumber, currentRound.raisedAmount);
    }

    // 9. pauseFund
    function pauseFund() external onlyAdmin {
        _pause(); // Uses Pausable's internal function
    }

    // 10. unpauseFund
    function unpauseFund() external onlyAdmin {
        _unpause(); // Uses Pausable's internal function
    }

    // 11. contribute
    function contribute(uint256 _amount, address _token) external whenNotPaused isActiveRound {
        require(allowedAssets[_token], "OmniFund: Asset not allowed for contribution");
        require(_token == currentRound.config.targetAsset, "OmniFund: Must contribute the target asset of the current round");
        require(_amount >= currentRound.config.minContribution, "OmniFund: Contribution below minimum");
        require(_amount <= currentRound.config.maxContribution, "OmniFund: Contribution above maximum");

        // Transfer tokens to the contract
        IERC20 token = IERC20(_token);
        uint256 balanceBefore = token.balanceOf(address(this));
        require(token.transferFrom(msg.sender, address(this), _amount), "OmniFund: Token transfer failed");
        uint256 transferredAmount = token.balanceOf(address(this)) - balanceBefore;
        require(transferredAmount == _amount, "OmniFund: Token transfer amount mismatch"); // Sanity check against potential deflationary tokens

        fundBalances[_token] += _amount;
        currentRound.raisedAmount += _amount;

        bool isNewParticipant = participants[msg.sender].participationUnits == 0 && participants[msg.sender].reputationPoints == 0;

        if (isNewParticipant) {
             participants[msg.sender].joinedRound = currentRound.roundNumber;
             // Initial reputation for joining
             participants[msg.sender].reputationPoints += 10; // Give a small initial reputation
             totalReputationPoints += 10;
             emit ParticipantJoined(msg.sender, currentRound.roundNumber);
             emit ReputationAdded(msg.sender, 10, address(this)); // Contract adding reputation
        }

        // Calculate units issued based on contribution amount and rate
        // Use safe multiplication to prevent overflow
        uint256 unitsIssued = (_amount * currentRound.config.unitIssuanceRate) / (10**IERC20(_token).decimals()); // Scale by token decimals

        participants[msg.sender].participationUnits += unitsIssued;
        totalParticipationUnits += unitsIssued;

        emit Contributed(msg.sender, _token, _amount, unitsIssued);
        emit UnitsIssued(msg.sender, unitsIssued);
    }

    // 12. submitInvestmentProposal
    function submitInvestmentProposal(
        address _targetAsset,
        uint256 _amount,
        string calldata _description,
        uint256 _votingDuration
    ) external onlyParticipant whenNotPaused returns (uint256) {
        require(allowedAssets[_targetAsset], "OmniFund: Target asset not allowed");
        require(_amount > 0, "OmniFund: Amount must be greater than 0");
        require(fundBalances[_targetAsset] >= _amount, "OmniFund: Insufficient fund balance for proposal");
        require(bytes(_description).length > 0, "OmniFund: Description cannot be empty");
        require(_votingDuration > 0, "OmniFund: Voting duration must be greater than 0");
        // Add minimum units/reputation to submit proposal
        require(participants[msg.sender].participationUnits > 1000 || participants[msg.sender].reputationPoints > 100, "OmniFund: Insufficient units or reputation to submit proposal");


        proposalCounter++;
        uint256 proposalId = proposalCounter;

        proposals[proposalId] = InvestmentProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            targetAsset: _targetAsset,
            amount: _amount,
            description: _description,
            submissionTime: block.timestamp,
            votingEndTime: block.timestamp + _votingDuration,
            state: ProposalState.Active,
            votesForUnits: 0,
            votesForReputation: 0,
            votesAgainstUnits: 0,
            votesAgainstReputation: 0,
            hasVoted: new mapping(address => bool)() // Initialize the mapping
        });

        emit ProposalSubmitted(proposalId, msg.sender, _targetAsset, _amount);
        return proposalId;
    }

    // 13. voteOnProposal
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyParticipant whenNotPaused isProposalActive(_proposalId) {
        InvestmentProposal storage proposal = proposals[_proposalId];
        address voter = msg.sender;

        // Resolve delegation
        while (participants[voter].delegatee != address(0) && participants[voter].delegatee != voter) {
             voter = participants[voter].delegatee;
        }
        require(voter != address(0) && (participants[voter].participationUnits > 0 || participants[voter].reputationPoints > 0), "OmniFund: Resolved voter is not a participant");

        require(!proposal.hasVoted[voter], "OmniFund: Voter already voted");

        Participant storage voterInfo = participants[voter];
        uint256 votingPowerUnits = voterInfo.participationUnits;
        uint256 votingPowerReputation = voterInfo.reputationPoints;

        if (_support) {
            proposal.votesForUnits += votingPowerUnits;
            proposal.votesForReputation += votingPowerReputation;
        } else {
            proposal.votesAgainstUnits += votingPowerUnits;
            proposal.votesAgainstReputation += votingPowerReputation;
        }

        proposal.hasVoted[voter] = true;

        emit VotedOnProposal(_proposalId, msg.sender, _support, votingPowerUnits, votingPowerReputation);
    }

    // 14. delegateVotingPower
    function delegateVotingPower(address _delegatee) external onlyParticipant {
        require(_delegatee != address(0), "OmniFund: Cannot delegate to zero address");
        require(_delegatee != msg.sender, "OmniFund: Cannot delegate to self");
        // Optional: Require delegatee to be a participant
        // require(participants[_delegatee].participationUnits > 0 || participants[_delegatee].reputationPoints > 0, "OmniFund: Delegatee must be a participant");

        participants[msg.sender].delegatee = _delegatee;
    }

    // 15. revokeVotingPower
    function revokeVotingPower() external onlyParticipant {
        participants[msg.sender].delegatee = address(0);
    }


    // 16. executeInvestmentProposal - Admin executed after voting passes
    function executeInvestmentProposal(uint256 _proposalId) external onlyAdmin whenNotPaused isProposalExecutable(_proposalId) {
        InvestmentProposal storage proposal = proposals[_proposalId];

        // State check should be done by isProposalExecutable modifier
        // require(proposal.state == ProposalState.Approved, "OmniFund: Proposal not approved");
        // require(fundBalances[proposal.targetAsset] >= proposal.amount, "OmniFund: Insufficient funds for proposal");

        // Assuming the 'targetAsset' is a contract/service we interact with
        // In a real scenario, this would involve calling another contract's function.
        // For this example, we simulate sending the asset out.
        IERC20 token = IERC20(proposal.targetAsset);

        fundBalances[proposal.targetAsset] -= proposal.amount; // Update internal balance tracking
        bool success = token.transfer(proposal.proposer, proposal.amount); // Sending to proposer for simplicity

        if (success) {
            proposal.state = ProposalState.Executed;
            emit ProposalExecuted(_proposalId, msg.sender, proposal.targetAsset, proposal.amount);
        } else {
             // Revert or handle failure state? Reverting is safer.
            fundBalances[proposal.targetAsset] += proposal.amount; // Revert internal balance tracking
            proposal.state = ProposalState.Failed; // Mark as failed execution
             emit ProposalFailed(_proposalId);
            revert("OmniFund: Token transfer failed during execution");
        }
    }

    // 17. updateDistributionParameters
    function updateDistributionParameters(
        uint256 _unitWeight,
        uint256 _reputationWeight,
        uint256 _withdrawalVestingPeriod
    ) external onlyAdmin whenNotPaused {
        require(_unitWeight > 0 || _reputationWeight > 0, "OmniFund: At least one weight must be > 0");
        // Note: _withdrawalVestingPeriod can be 0 for instant withdrawal after initiation

        distributionParameters = DistributionParameters({
            unitWeight: _unitWeight,
            reputationWeight: _reputationWeight,
            withdrawalVestingPeriod: _withdrawalVestingPeriod
        });

        // Important: When parameters change, we might need to recalculate or snapshot basis.
        // For simplicity in this example, we assume the new parameters apply to all *future* distributions
        // or earnings received *after* this update. A more complex system would track parameter versions.
        // For now, we just update the parameters. The calculation function will use the latest ones.

        emit DistributionParametersUpdated(_unitWeight, _reputationWeight, _withdrawalVestingPeriod);
    }

    // 18. receiveInvestmentReturns - Simulates receiving assets from an investment
    function receiveInvestmentReturns(address _token, uint256 _amount) external onlyAdmin whenNotPaused {
        require(allowedAssets[_token], "OmniFund: Received asset not allowed");
        require(_amount > 0, "OmniFund: Amount must be greater than 0");

        // Simulate receiving tokens - in a real dApp, this might be from an external contract call
        // or a push mechanism. For this example, assume tokens are already sent or minted here.
        // In a real contract, you would typically use `token.transferFrom(source, address(this), _amount)`
        // or a `receive` function if receiving ETH, or handle a callback from an investment protocol.

        // For demonstration, we'll just update the balance assuming tokens were received.
        // *** WARNING: In production, ensure tokens are actually transferred/received securely ***
        fundBalances[_token] += _amount;
        totalDistributedEarnings[_token] += _amount; // Track total earned for this token

        // When new earnings arrive, we potentially update the distribution basis for participants
        // A simplified approach: recalculate the total current basis. Participants' individual basis
        // will be evaluated using the calculateClaimableAssets function against the total basis.
        uint256 currentTotalBasis = 0;
         for (address participantAddr = address(0); ; ) {
             // Iterate through participants (inefficient on-chain for large numbers)
             // This pattern is illustrative; a real system might require off-chain calculation or different tracking
             // We need a way to iterate or map through *all* participant addresses efficiently.
             // This simulation won't iterate all, it will rely on the calculate function iterating relevant ones.
             // A better approach would be to track basis per *earnings event* or require participants to update basis.

             // *Self-correction*: Iterating all participants on-chain here is not feasible.
             // The `calculateClaimableAssets` function must compute the participant's *current* basis and the *current* total basis
             // based on the latest `distributionParameters` at the time of calculation, and then compare that
             // against the `totalDistributedEarnings` for the token, minus `participantClaimedAmounts`.
             // We don't need to update individual `participantDistributionBasis` mappings here every time earnings arrive.
             // The claim logic handles the division based on current state and params.

             // *Second self-correction*: To prevent the distribution parameters changing drastically and unfairly affecting
             // earned but unclaimed funds, a more robust system would either:
             // a) Snapshot participant bases and total basis for each `receiveInvestmentReturns` event.
             // b) Require participants to "checkpoint" their basis before claiming from a specific earning pool.
             // For *this* example, using the *current* distribution parameters and *current* participant units/reputation
             // to calculate claimable funds from the *total* received earnings is the simplest approach,
             // but it means the claimable amount per unit/reputation is dynamic based on parameters and other participants' state.
             // Let's stick with the simpler, dynamic calculation for this example.

             break; // Exit the simulated loop
         }


        emit InvestmentReturnsReceived(_token, _amount);
    }

    // 19. calculateClaimableAssets - View function to estimate claimable amount
    function calculateClaimableAssets(address _participant, address _token) public view returns (uint256 claimableAmount) {
        Participant storage p = participants[_participant];
        if (p.participationUnits == 0 && p.reputationPoints == 0) {
            return 0; // Not a valid participant
        }

        // Calculate the participant's weighted basis based on current units and reputation
        uint256 participantBasis = (p.participationUnits * distributionParameters.unitWeight) + (p.reputationPoints * distributionParameters.reputationWeight);

        // Calculate the total weighted basis across all participants using current state
        // NOTE: This requires iterating or having a global tally. Iterating is inefficient.
        // For simplicity in this *view* function, we will calculate total basis IF we had a list of all participants.
        // A better approach for a production system is to track total basis upon contributions/reputation changes.
        // Since we don't have an iterable list of all addresses on-chain easily, this view function
        // is illustrative of the *logic* but relies on an assumption of how total basis would be tracked
        // or calculated efficiently. Let's assume we have a way to get the current total basis.
        // We have `totalParticipationUnits` and `totalReputationPoints`, let's use those as proxies for total basis calculation.
        // This is a significant simplification: it implies total basis is simply (totalUnits * unitWeight) + (totalReputation * repWeight),
        // which only works if all units/reputation contribute equally to the *current* basis calculation, even if they are from participants
        // who initiated withdrawal etc. A production system needs a more nuanced total basis tracking.

        // Simplified Total Basis Calculation:
        uint256 totalCurrentBasis = (totalParticipationUnits * distributionParameters.unitWeight) + (totalReputationPoints * distributionParameters.reputationWeight);

        if (totalCurrentBasis == 0) {
            return 0; // Avoid division by zero
        }

        // Calculate the participant's proportion of the total basis
        // Use fixed point math or careful integer division if precision is needed.
        // Using integer division for simplicity: (participantBasis / totalCurrentBasis)
        // This division order is problematic. Better: total earnings * (participantBasis / totalCurrentBasis)
        // To maintain precision with integer math: (total earnings * participantBasis) / totalCurrentBasis

        uint256 totalShareAmount = (totalDistributedEarnings[_token] * participantBasis) / totalCurrentBasis;

        // Subtract amounts already claimed by this participant for this token
        uint256 alreadyClaimed = participantClaimedAmounts[_participant][_token];
        uint256 potentialClaim = totalShareAmount > alreadyClaimed ? totalShareAmount - alreadyClaimed : 0;

        // Apply withdrawal vesting if initiated
        if (p.withdrawalInitiatedTime > 0) {
            uint256 vestingEndTime = p.withdrawalInitiatedTime + distributionParameters.withdrawalVestingPeriod;
            if (block.timestamp < vestingEndTime) {
                // If still vesting, calculate the percentage vested
                uint256 timeElapsed = block.timestamp - p.withdrawalInitiatedTime;
                uint256 vestedPercentage = (timeElapsed * 1e18) / distributionParameters.withdrawalVestingPeriod; // Scale to 1e18
                vestedPercentage = vestedPercentage > 1e18 ? 1e18 : vestedPercentage; // Cap at 100%

                // Claimable amount is the vested portion of the potential claim
                potentialClaim = (potentialClaim * vestedPercentage) / 1e18;
            }
            // If block.timestamp >= vestingEndTime, potentialClaim is the full calculated amount (no reduction)
        }

        return potentialClaim;
    }

    // 20. claimAssets
    function claimAssets(address _token) external onlyParticipant whenNotPaused {
        require(allowedAssets[_token], "OmniFund: Token is not allowed for claiming");

        uint256 claimableAmount = calculateClaimableAssets(msg.sender, _token);

        require(claimableAmount > 0, "OmniFund: No claimable amount");
        require(fundBalances[_token] >= claimableAmount, "OmniFund: Insufficient fund balance for claim");

        // Update claimed amounts
        participantClaimedAmounts[msg.sender][_token] += claimableAmount;
        fundBalances[_token] -= claimableAmount;

        // Transfer tokens to the participant
        IERC20 token = IERC20(_token);
        require(token.transfer(msg.sender, claimableAmount), "OmniFund: Token transfer failed during claim");

        emit AssetsClaimed(msg.sender, _token, claimableAmount);
    }

    // 21. initiateParticipantWithdrawal
    function initiateParticipantWithdrawal() external onlyParticipant whenNotPaused {
        require(participants[msg.sender].withdrawalInitiatedTime == 0, "OmniFund: Withdrawal already initiated");

        participants[msg.sender].withdrawalInitiatedTime = block.timestamp;

        emit WithdrawalInitiated(msg.sender, block.timestamp);
    }

    // 22. cancelParticipantWithdrawal
    function cancelParticipantWithdrawal() external onlyParticipant whenNotPaused {
        require(participants[msg.sender].withdrawalInitiatedTime > 0, "OmniFund: No active withdrawal to cancel");

        participants[msg.sender].withdrawalInitiatedTime = 0;
        participants[msg.sender].cancelledWithdrawalCount++; // Track cancellations - could be used for penalties

        emit WithdrawalCancelled(msg.sender, block.timestamp);
    }

    // 23. addReputation (Admin)
    function addReputation(address _participant, uint256 _amount) external onlyAdmin whenNotPaused {
        require(_participant != address(0), "OmniFund: Zero address");
        require(_amount > 0, "OmniFund: Amount must be greater than 0");
        // Optional: require participant exists? No, admin can grant initial reputation.

        participants[_participant].reputationPoints += _amount;
        totalReputationPoints += _amount;

        emit ReputationAdded(_participant, _amount, msg.sender);
    }

    // 24. slashReputation (Admin)
    function slashReputation(address _participant, uint256 _amount) external onlyAdmin whenNotPaused {
        require(_participant != address(0), "OmniFund: Zero address");
        require(_amount > 0, "OmniFund: Amount must be greater than 0");
        require(participants[_participant].reputationPoints >= _amount, "OmniFund: Insufficient reputation to slash");

        participants[_participant].reputationPoints -= _amount;
        totalReputationPoints -= _amount;

        emit ReputationSlashed(_participant, _amount, msg.sender);
    }

    // 25. burnUnits (Admin) - Severe penalty
    function burnUnits(address _participant, uint256 _amount) external onlyAdmin whenNotPaused {
        require(_participant != address(0), "OmniFund: Zero address");
        require(_amount > 0, "OmniFund: Amount must be greater than 0");
        require(participants[_participant].participationUnits >= _amount, "OmniFund: Insufficient units to burn");

        participants[_participant].participationUnits -= _amount;
        totalParticipationUnits -= _amount;

        emit UnitsBurned(_participant, _amount, msg.sender);
    }

     // 26. getParticipantInfo
     // Public state variable `participants` already provides this view function.

     // 27. getFundBalance
     // Public state variable `fundBalances` already provides this view function.

     // 28. getCurrentRoundInfo
     // Public state variable `currentRound` already provides this view function.

     // 29. getProposalInfo
     // Public state variable `proposals` already provides this view function by ID.

     // 30. getAllowedAssets - Need a way to return all keys from mapping, inefficient on-chain.
     // For view, return an array of known allowed assets or require checking individually.
     // Let's make a placeholder view function assuming a separate way to track the list or check one by one.
     function getAllowedAssets() public view returns (address[] memory) {
         // WARNING: Iterating through mapping keys is not possible directly or efficiently on-chain.
         // This function is illustrative. In practice, you would maintain an array alongside the mapping.
         // Returning an empty array or requiring individual checks is the practical approach for this example.
         // To return a list, we'd need a state variable like `address[] private _allowedAssetsList;`
         // and update it in `setAllowedAsset`.

         // Placeholder implementation returning an empty array as iteration is not feasible.
         address[] memory allowed = new address[](0);
         return allowed;
     }

     // 31. getAdminList
     // Similar issue to getAllowedAssets. Need a separate array state variable.
     function getAdminList() public view returns (address[] memory) {
         // Placeholder implementation returning an empty array.
          address[] memory adminsList = new address[](0);
          // If we had an array `_adminsList`, we'd populate and return it here.
         return adminsList;
     }

     // 32. getProposalCount
     // Public state variable `proposalCounter` already provides this view.

     // 33. getParticipantWithdrawalStatus
     // Public state variable `participants` includes `withdrawalInitiatedTime`, allowing external check.
     // However, we can provide a helper view:
     function getParticipantWithdrawalStatus(address _participant) public view returns (uint256 initiatedTime, uint256 vestingEndTime, bool isVestingActive) {
        Participant storage p = participants[_participant];
        initiatedTime = p.withdrawalInitiatedTime;
        isVestingActive = initiatedTime > 0 && block.timestamp < initiatedTime + distributionParameters.withdrawalVestingPeriod;
        vestingEndTime = initiatedTime > 0 ? initiatedTime + distributionParameters.withdrawalVestingPeriod : 0;
        return (initiatedTime, vestingEndTime, isVestingActive);
     }


    // --- Internal/Helper Functions ---
    // _updateProposalState: Function to check and update proposal state based on voting time/results.
    // This would typically be called externally by anyone (gas cost) or by admin after voting ends.
    function _updateProposalState(uint256 _proposalId) internal {
        InvestmentProposal storage proposal = proposals[_proposalId];

        if (proposal.state == ProposalState.Active && block.timestamp >= proposal.votingEndTime) {
            // Voting period ended, determine outcome based on weighted votes
            uint256 totalVotesFor = (proposal.votesForUnits * distributionParameters.unitWeight) + (proposal.votesForReputation * distributionParameters.reputationWeight);
            uint256 totalVotesAgainst = (proposal.votesAgainstUnits * distributionParameters.unitWeight) + (proposal.votesAgainstReputation * distributionParameters.reputationWeight);

            // Define quorum and approval percentage rules here
            // Example rule: Need > 50% of *participating* weighted votes, and a minimum threshold of total weighted votes cast.
            // Calculating total *participating* weighted votes reliably on-chain is hard.
            // Simpler rule: Absolute majority of votes cast (total votes for > total votes against). Quorum check omitted for simplicity.
            if (totalVotesFor > totalVotesAgainst) {
                 proposal.state = ProposalState.Approved;
             } else {
                 proposal.state = ProposalState.Rejected;
             }
        }
        // No specific event for state update from Active -> Approved/Rejected, as voteOnProposal or execute handles outcome.
        // A dedicated event or return value could signal this transition.
    }


    // External function to allow anyone to trigger the proposal state update after voting ends
    function finalizeProposalVoting(uint256 _proposalId) external {
        require(_proposalId > 0 && _proposalId <= proposalCounter, "OmniFund: Invalid proposal ID");
        InvestmentProposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "OmniFund: Proposal not in Active state");
        require(block.timestamp >= proposal.votingEndTime, "OmniFund: Voting period not ended yet");

        _updateProposalState(_proposalId);
    }

    // Fallback/Receive function to potentially handle incoming ETH or other tokens not via contribute
    // Consider security implications. For this complex contract, disallowing arbitrary sends might be safer.
    // receive() external payable {}
    // fallback() external payable {}
}
```

**Explanation of Advanced/Creative Concepts Implementation:**

1.  **Non-Transferable Participation Units & Reputation:**
    *   The `Participant` struct stores `participationUnits` and `reputationPoints`.
    *   These are incremented/decremented via specific internal or admin functions (`contribute`, `addReputation`, `slashReputation`, `burnUnits`).
    *   There are no functions for `transferUnits` or `transferReputation`, making them soulbound to the participant's address within this contract.

2.  **Dynamic Funding Rounds:**
    *   `FundingRoundConfig` and `FundingRoundState` structs manage round parameters and state.
    *   `configureFundingRound` allows admins to set the rules for the *next* round.
    *   `startFundingRound` activates the configured round.
    *   `endFundingRound` manually ends the current round.
    *   `contribute` is restricted to be called only during an `isActiveRound` and checks round-specific min/max contribution and target asset.

3.  **Weighted Governance:**
    *   `voteOnProposal` calculates voting power using `(participants[voter].participationUnits * distributionParameters.unitWeight) + (participants[voter].reputationPoints * distributionParameters.reputationWeight)`.
    *   Votes are tallied separately for units and reputation, allowing the `distributionParameters` to control the weight of each.
    *   Delegation (`delegateVotingPower`, `revokeVotingPower`) allows participants to assign their combined voting power to another address.
    *   `_updateProposalState` calculates the outcome based on these weighted votes.

4.  **Flexible Distribution Logic:**
    *   `DistributionParameters` stores `unitWeight` and `reputationWeight`.
    *   `calculateClaimableAssets` computes a participant's share based on `(participantBasis / totalCurrentBasis) * totalDistributedEarnings`.
    *   `totalCurrentBasis` is a simplified calculation based on *global* totals (`totalParticipationUnits`, `totalReputationPoints`). A more robust system would need more complex tracking of total basis that contributed to specific earning events.
    *   `updateDistributionParameters` allows admins to change the weights, influencing future claims.
    *   `totalDistributedEarnings` tracks total funds received for a token, acting as the pool for distribution.
    *   `participantClaimedAmounts` prevents claiming more than calculated.

5.  **Timed Withdrawal/Leaving:**
    *   `initiateParticipantWithdrawal` records a timestamp.
    *   `cancelParticipantWithdrawal` resets the timestamp and increments a counter (could be used for penalties in a more complex version).
    *   `calculateClaimableAssets` checks `withdrawalInitiatedTime` and `distributionParameters.withdrawalVestingPeriod` to reduce the claimable amount if the vesting period hasn't passed.

6.  **Asset Agnostic (ERC-20):**
    *   `allowedAssets` mapping controls which tokens are permitted.
    *   `fundBalances` tracks balances for each token.
    *   Functions like `contribute`, `setAllowedAsset`, `receiveInvestmentReturns`, `executeInvestmentProposal`, `calculateClaimableAssets`, and `claimAssets` take a token address as a parameter, allowing interaction with different ERC-20s.

**Key Considerations and Potential Improvements:**

*   **Efficiency:** Iterating through all participants or tracking global basis on-chain for perfect distribution calculation (`calculateClaimableAssets`) is highly inefficient and costly. A production system would likely use off-chain computation and on-chain proofs, or a more sophisticated on-chain snapshotting mechanism. The current `calculateClaimableAssets` is simplified for demonstration.
*   **Quorum:** The current proposal voting lacks a quorum mechanism (minimum number of votes cast for a proposal to be valid). This is a standard DAO feature that could be added.
*   **Proposal Execution:** The `executeInvestmentProposal` currently transfers funds to the *proposer*. In a real investment scenario, it should interact with another investment contract or protocol.
*   **Error Handling/Edge Cases:** More robust checks could be added (e.g., what happens if `unitIssuanceRate` results in 0 units for a contribution?).
*   **Admin Power:** Admins have significant power (pause, change distribution rules, add/slash reputation, burn units). A real-world DAO might decentralize some of these powers via further governance votes.
*   **Complexity:** This contract is already quite complex. Adding features like NFT-based badges, multiple simultaneous funding rounds, or more intricate vesting schedules would increase complexity significantly.
*   **External Calls:** Interacting with `IERC20` involves external calls. While common, reentrancy guards (`nonReentrant` modifier from OpenZeppelin) would be crucial if `claimAssets` or `executeInvestmentProposal` involved sending tokens and then immediately calling back into the contract. In this design, tokens are sent *out* at the end, reducing reentrancy risk, but it's good practice to be mindful.

This contract provides a solid framework demonstrating how multiple advanced concepts can be combined into a unique decentralized application logic, going beyond simple token transfers or standard governance models.