This smart contract, named "AuraFlow Protocol," aims to create a decentralized ecosystem where user reputation (Karma) is a foundational element. Karma is not a transferable token but a dynamic score that influences various aspects of a user's interaction within the protocol. This includes access to exclusive financial opportunities, enhanced rewards, voting power, and participation in a decentralized task network.

The core idea is to move beyond simple token holdings for access or governance, instead using a dynamic, earned reputation system to foster healthier, more engaged, and more trustworthy community participation.

---

## AuraFlow Protocol: Decentralized Karma & Opportunity Network

**Outline:**

1.  **Core Infrastructure & Control:** Basic contract administration (ownership, pausing, fee management).
2.  **Karma & Reputation Management:** Functions to manage a user's Karma score, including granting, revoking, delegation, and a unique attestation system.
3.  **Dynamic Karma System:** Mechanisms for Karma decay and boosts.
4.  **Opportunity Pools:** Create and interact with financial pools where Karma influences deposit terms, rewards, and access.
5.  **Decentralized Task Network:** A system for proposing, accepting, completing, and verifying tasks, with Karma influencing participation and rewards.
6.  **Governance:** A Karma-weighted voting system for protocol decisions.
7.  **Query & Utility:** Functions to retrieve protocol and user-specific data.

**Function Summary:**

*   **`constructor()`:** Initializes the contract owner and initial parameters.
*   **`pause()` / `unpause()`:** Allows the owner to pause/unpause critical functions during emergencies.
*   **`transferOwnership()`:** Transfers ownership of the contract.
*   **`setProtocolFeeRecipient()`:** Sets the address to receive protocol fees.
*   **`setProtocolFeeRate()`:** Sets the percentage of fees collected by the protocol.
*   **`withdrawProtocolFees()`:** Allows the fee recipient to withdraw collected fees.
*   **`grantKarma()`:** Admin function to award Karma to a user.
*   **`revokeKarma()`:** Admin function to reduce or remove Karma from a user.
*   **`decayKarma()`:** A public function that can be called by anyone to trigger Karma decay for a specific user or the entire system (based on `_lastKarmaUpdate`).
*   **`getUserKarma()`:** Retrieves the current Karma score of a user, applying decay if necessary.
*   **`delegateKarmaInfluence()`:** Allows a user to delegate their Karma's *influence* (not the Karma itself) for voting or pool access to another address.
*   **`undelegateKarmaInfluence()`:** Revokes a previous Karma influence delegation.
*   **`submitAttestation()`:** Users can attest to another user's positive action, contributing to their Karma.
*   **`challengeAttestation()`:** Allows users to challenge a potentially false attestation.
*   **`resolveAttestationChallenge()`:** Admin/governance function to resolve attestation disputes.
*   **`burnKarmaForBoost()`:** Allows a user to spend Karma for a temporary, one-time boost (e.g., higher APR in a pool).
*   **`createOpportunityPool()`:** Creates a new investment/opportunity pool, potentially with Karma requirements for entry.
*   **`depositIntoPool()`:** Deposits funds into an opportunity pool, where Karma can influence deposit terms or share of rewards.
*   **`withdrawFromPool()`:** Withdraws deposited funds and accumulated rewards from a pool.
*   **`claimPoolRewards()`:** Claims accrued rewards from a pool, potentially boosted by Karma.
*   **`proposeDecentralizedTask()`:** Users with sufficient Karma can propose tasks/bounties.
*   **`acceptDecentralizedTask()`:** Users with sufficient Karma can accept to complete a task.
*   **`submitTaskCompletionProof()`:** The task accepter submits proof of completion.
*   **`verifyTaskCompletion()`:** Karma holders (or governance) verify the task completion.
*   **`challengeTaskCompletion()`:** Allows challenging a submitted task completion.
*   **`resolveTaskDispute()`:** Admin/governance function to resolve task disputes.
*   **`proposeGovernanceAction()`:** Users with enough Karma can propose system-wide changes.
*   **`voteOnGovernanceAction()`:** Users with Karma (or delegated influence) can vote on proposals.
*   **`executeGovernanceAction()`:** Executes a passed governance proposal.
*   **`getOpportunityPoolDetails()`:** Retrieves details about a specific opportunity pool.
*   **`getTaskDetails()`:** Retrieves details about a specific decentralized task.
*   **`getGovernanceProposalDetails()`:** Retrieves details about a specific governance proposal.
*   **`getProtocolStatus()`:** Returns the current paused status and fee rates.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title AuraFlow Protocol: Decentralized Karma & Opportunity Network
/// @author Your Name/AI
/// @notice This contract implements a decentralized reputation (Karma) system
///         that influences access, rewards, and governance within the protocol.
///         It integrates financial opportunity pools and a decentralized task network.

contract AuraFlowProtocol is Ownable, Pausable, ReentrancyGuard {

    // --- Events ---
    event KarmaGranted(address indexed user, uint256 amount, string reasonHash);
    event KarmaRevoked(address indexed user, uint256 amount, string reasonHash);
    event KarmaDecayed(address indexed user, uint256 oldKarma, uint256 newKarma);
    event KarmaDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event KarmaUndelegated(address indexed delegator, address indexed delegatee);
    event AttestationSubmitted(uint256 indexed attestationId, address indexed attester, address indexed subject, bytes32 descriptionHash);
    event AttestationChallenged(uint256 indexed attestationId, address indexed challenger);
    event AttestationResolved(uint256 indexed attestationId, bool approved);
    event KarmaBurned(address indexed user, uint256 amount, string boostType);

    event PoolCreated(uint256 indexed poolId, address indexed creator, address assetToken, address rewardToken, uint256 minKarmaRequired);
    event DepositedIntoPool(uint256 indexed poolId, address indexed user, address token, uint256 amount);
    event WithdrawnFromPool(uint256 indexed poolId, address indexed user, uint256 amount);
    event RewardsClaimed(uint256 indexed poolId, address indexed user, address rewardToken, uint256 amount);

    event TaskProposed(uint256 indexed taskId, address indexed proposer, address bountyToken, uint256 bountyAmount, bytes32 descriptionHash, uint256 minKarmaRequired);
    event TaskAccepted(uint256 indexed taskId, address indexed accepter);
    event TaskCompletionSubmitted(uint256 indexed taskId, address indexed submitter, bytes32 proofHash);
    event TaskCompletionVerified(uint256 indexed taskId, address indexed verifier, bool approved);
    event TaskCompletionChallenged(uint256 indexed taskId, address indexed challenger);
    event TaskDisputeResolved(uint256 indexed taskId, bool success);

    event GovernanceProposalProposed(uint256 indexed proposalId, address indexed proposer, bytes32 descriptionHash, address target, bytes callData);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 karmaWeight);
    event GovernanceProposalExecuted(uint256 indexed proposalId);

    event ProtocolFeeRecipientUpdated(address indexed newRecipient);
    event ProtocolFeeRateUpdated(uint256 newRate);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);

    // --- Errors ---
    error InsufficientKarma(uint256 required, uint256 current);
    error UnauthorizedAction(string message);
    error InvalidAmount();
    error PoolNotFound();
    error TaskNotFound();
    error AttestationNotFound();
    error GovernanceProposalNotFound();
    error PoolAlreadyEnded();
    error PoolNotEndedYet();
    error AlreadyDelegated();
    error NotDelegated();
    error CannotDelegateToSelf();
    error InvalidKarmaRate();
    error ZeroAddress();
    error AlreadyVoted();
    error ProposalNotYetExecutable();
    error ProposalAlreadyExecuted();
    error ProposalFailed();
    error TaskNotAccepted();
    error TaskAlreadyCompleted();
    error TaskNotYetCompleted();
    error AttestationAlreadyResolved();
    error NoFeesToWithdraw();

    // --- Constants & Configuration ---
    uint256 public constant MAX_KARMA = 10_000_000; // Max Karma a user can have
    uint256 public constant KARMA_DECAY_PERIOD = 30 days; // Karma decays every 30 days
    uint256 public constant KARMA_DECAY_PERCENTAGE = 10; // 10% decay
    uint256 public constant MAX_PROTOCOL_FEE_RATE = 1000; // 10% (1000 basis points)
    uint256 public constant MIN_KARMA_FOR_PROPOSAL = 1000; // Minimum Karma to propose governance action
    uint256 public constant VOTING_PERIOD_DURATION = 7 days; // How long a proposal is open for voting

    // --- State Variables ---
    address public protocolFeeRecipient;
    uint256 public protocolFeeRate; // In basis points (e.g., 100 for 1%)

    struct UserKarma {
        uint256 karma;
        uint256 lastKarmaUpdate; // Timestamp of last Karma update or decay application
        address delegatedTo; // Address this user's influence is delegated to
        mapping(address => bool) delegatedBy; // Addresses that have delegated their influence to this user
    }
    mapping(address => UserKarma) private _userKarma;

    enum AttestationStatus {
        Pending,
        Challenged,
        Approved,
        Rejected
    }

    struct Attestation {
        address attester;
        address subject;
        bytes32 descriptionHash;
        uint256 timestamp;
        AttestationStatus status;
        address challenger;
    }
    Attestation[] public attestations;
    uint256 private _nextAttestationId;

    struct OpportunityPool {
        address creator;
        IERC20 assetToken; // Token users deposit
        IERC20 rewardToken; // Token rewards are paid in
        uint256 startTime;
        uint256 endTime;
        uint256 totalDeposited;
        uint256 totalRewardsDistributed;
        uint256 minKarmaRequired; // Karma needed to deposit
        uint256 karmaBoostFactor; // Multiplier for rewards based on Karma (e.g., 100 = 1x, 110 = 1.1x)
        mapping(address => uint256) deposits; // User deposits
        mapping(address => uint256) rewardsClaimed; // Rewards already claimed by user
    }
    OpportunityPool[] public opportunityPools;
    uint256 private _nextPoolId;

    enum TaskStatus {
        Proposed,
        Accepted,
        ProofSubmitted,
        Verified,
        Challenged,
        Completed,
        Failed
    }

    struct DecentralizedTask {
        address proposer;
        address accepter;
        IERC20 bountyToken;
        uint256 bountyAmount;
        bytes32 descriptionHash;
        bytes32 completionProofHash;
        uint256 minKarmaRequired;
        TaskStatus status;
        uint256 proposalTime;
        uint256 acceptTime;
        uint256 completionSubmitTime;
        address challenger;
    }
    DecentralizedTask[] public decentralizedTasks;
    uint256 private _nextTaskId;

    enum ProposalStatus {
        Pending,
        Active,
        Succeeded,
        Failed,
        Executed
    }

    struct GovernanceProposal {
        address proposer;
        bytes32 descriptionHash;
        address target; // Address of contract to call
        bytes callData; // Calldata for execution
        uint256 startBlock;
        uint256 endBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        ProposalStatus status;
        mapping(address => bool) hasVoted; // User voting record
    }
    GovernanceProposal[] public governanceProposals;
    uint256 private _nextProposalId;

    mapping(address => uint256) private _protocolCollectedFees; // Per token address

    // --- Modifiers ---
    modifier onlyKarmaHolder(uint256 _requiredKarma) {
        if (getUserKarma(msg.sender) < _requiredKarma) {
            revert InsufficientKarma(_requiredKarma, getUserKarma(msg.sender));
        }
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        protocolFeeRecipient = msg.sender;
        protocolFeeRate = 50; // 0.5% default fee
        _nextAttestationId = 0;
        _nextPoolId = 0;
        _nextTaskId = 0;
        _nextProposalId = 0;
    }

    // --- Core Infrastructure & Control (6 functions) ---

    /// @notice Pauses contract functionality, usable by owner.
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses contract functionality, usable by owner.
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Sets the address that receives protocol fees.
    /// @param _newRecipient The new address for fee collection.
    function setProtocolFeeRecipient(address _newRecipient) public onlyOwner {
        if (_newRecipient == address(0)) revert ZeroAddress();
        protocolFeeRecipient = _newRecipient;
        emit ProtocolFeeRecipientUpdated(_newRecipient);
    }

    /// @notice Sets the protocol fee rate in basis points.
    /// @param _newRate The new fee rate (e.g., 100 for 1%). Max 1000 (10%).
    function setProtocolFeeRate(uint256 _newRate) public onlyOwner {
        if (_newRate > MAX_PROTOCOL_FEE_RATE) revert InvalidKarmaRate(); // Reusing error for rate
        protocolFeeRate = _newRate;
        emit ProtocolFeeRateUpdated(_newRate);
    }

    /// @notice Allows the protocolFeeRecipient to withdraw collected fees for a specific token.
    /// @param _token The address of the ERC20 token for which fees are to be withdrawn.
    function withdrawProtocolFees(IERC20 _token) public nonReentrant {
        if (msg.sender != protocolFeeRecipient) revert UnauthorizedAction("Only fee recipient can withdraw fees");
        uint256 fees = _protocolCollectedFees[address(_token)];
        if (fees == 0) revert NoFeesToWithdraw();

        _protocolCollectedFees[address(_token)] = 0;
        _token.transfer(protocolFeeRecipient, fees);
        emit ProtocolFeesWithdrawn(protocolFeeRecipient, fees);
    }

    // --- Karma & Reputation Management (10 functions) ---

    /// @notice Admin function to grant Karma to a user.
    /// @param _user The address of the user to grant Karma to.
    /// @param _amount The amount of Karma to grant.
    /// @param _reasonHash A hash of the reason for granting Karma.
    function grantKarma(address _user, uint256 _amount, string memory _reasonHash) public onlyOwner whenNotPaused {
        if (_user == address(0)) revert ZeroAddress();
        _userKarma[_user].karma = _userKarma[_user].karma + _amount > MAX_KARMA ? MAX_KARMA : _userKarma[_user].karma + _amount;
        _userKarma[_user].lastKarmaUpdate = block.timestamp;
        emit KarmaGranted(_user, _amount, _reasonHash);
    }

    /// @notice Admin function to revoke Karma from a user.
    /// @param _user The address of the user to revoke Karma from.
    /// @param _amount The amount of Karma to revoke.
    /// @param _reasonHash A hash of the reason for revoking Karma.
    function revokeKarma(address _user, uint256 _amount, string memory _reasonHash) public onlyOwner whenNotPaused {
        if (_user == address(0)) revert ZeroAddress();
        _userKarma[_user].karma = _userKarma[_user].karma < _amount ? 0 : _userKarma[_user].karma - _amount;
        _userKarma[_user].lastKarmaUpdate = block.timestamp;
        emit KarmaRevoked(_user, _amount, _reasonHash);
    }

    /// @notice Applies Karma decay for a specific user. Can be called by anyone.
    ///         Karma decays by a set percentage every KARMA_DECAY_PERIOD.
    /// @param _user The address of the user whose Karma should decay.
    function decayKarma(address _user) public whenNotPaused {
        uint256 currentKarma = _userKarma[_user].karma;
        uint256 lastUpdate = _userKarma[_user].lastKarmaUpdate;

        if (currentKarma == 0 || block.timestamp < lastUpdate + KARMA_DECAY_PERIOD) {
            return; // No decay needed or not enough time passed
        }

        uint256 periods = (block.timestamp - lastUpdate) / KARMA_DECAY_PERIOD;
        uint256 oldKarma = currentKarma;

        for (uint256 i = 0; i < periods; i++) {
            currentKarma = currentKarma * (100 - KARMA_DECAY_PERCENTAGE) / 100;
            if (currentKarma < 10) { // Don't decay to zero unless it's very low
                currentKarma = 0;
                break;
            }
        }

        _userKarma[_user].karma = currentKarma;
        _userKarma[_user].lastKarmaUpdate = lastUpdate + (periods * KARMA_DECAY_PERIOD); // Update last update time incrementally
        emit KarmaDecayed(_user, oldKarma, currentKarma);
    }

    /// @notice Retrieves the current Karma of a user, applying decay if due.
    /// @param _user The address of the user.
    /// @return The current Karma score.
    function getUserKarma(address _user) public view returns (uint256) {
        // This view function will not modify state, but the caller should understand
        // that calling `decayKarma(_user)` explicitly would update the stored value.
        // For accurate real-time display, this view applies decay virtually.
        uint256 currentKarma = _userKarma[_user].karma;
        uint256 lastUpdate = _userKarma[_user].lastKarmaUpdate;

        if (currentKarma == 0 || block.timestamp < lastUpdate + KARMA_DECAY_PERIOD) {
            return currentKarma;
        }

        uint256 periods = (block.timestamp - lastUpdate) / KARMA_DECAY_PERIOD;
        for (uint256 i = 0; i < periods; i++) {
            currentKarma = currentKarma * (100 - KARMA_DECAY_PERCENTAGE) / 100;
            if (currentKarma < 10) {
                currentKarma = 0;
                break;
            }
        }
        return currentKarma;
    }

    /// @notice Allows a user to delegate their Karma's influence (e.g., voting power, pool access)
    ///         to another address without transferring the actual Karma.
    /// @param _delegatee The address to delegate influence to.
    function delegateKarmaInfluence(address _delegatee) public whenNotPaused {
        if (_delegatee == address(0)) revert ZeroAddress();
        if (_delegatee == msg.sender) revert CannotDelegateToSelf();
        if (_userKarma[msg.sender].delegatedTo != address(0)) revert AlreadyDelegated();

        _userKarma[msg.sender].delegatedTo = _delegatee;
        _userKarma[_delegatee].delegatedBy[msg.sender] = true;
        emit KarmaDelegated(msg.sender, _delegatee, getUserKarma(msg.sender));
    }

    /// @notice Revokes a previous Karma influence delegation.
    function undelegateKarmaInfluence() public whenNotPaused {
        address delegatee = _userKarma[msg.sender].delegatedTo;
        if (delegatee == address(0)) revert NotDelegated();

        _userKarma[msg.sender].delegatedTo = address(0);
        _userKarma[delegatee].delegatedBy[msg.sender] = false;
        emit KarmaUndelegated(msg.sender, delegatee);
    }

    /// @notice Users can submit an attestation about another user's positive action.
    ///         This contributes to the subject's Karma once approved.
    /// @param _subject The address of the user being attested about.
    /// @param _descriptionHash A hash of the attestation description.
    function submitAttestation(address _subject, bytes32 _descriptionHash) public whenNotPaused {
        if (_subject == address(0) || _subject == msg.sender) revert ZeroAddress();

        attestations.push(Attestation({
            attester: msg.sender,
            subject: _subject,
            descriptionHash: _descriptionHash,
            timestamp: block.timestamp,
            status: AttestationStatus.Pending,
            challenger: address(0)
        }));
        emit AttestationSubmitted(_nextAttestationId, msg.sender, _subject, _descriptionHash);
        _nextAttestationId++;
    }

    /// @notice Allows a user to challenge an attestation if they believe it's false.
    /// @param _attestationId The ID of the attestation to challenge.
    function challengeAttestation(uint256 _attestationId) public whenNotPaused {
        if (_attestationId >= attestations.length) revert AttestationNotFound();
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.status != AttestationStatus.Pending) revert AttestationAlreadyResolved();
        if (attestation.attester == msg.sender || attestation.subject == msg.sender) revert UnauthorizedAction("Cannot challenge own/subject attestation");

        attestation.status = AttestationStatus.Challenged;
        attestation.challenger = msg.sender;
        emit AttestationChallenged(_attestationId, msg.sender);
    }

    /// @notice Resolves an attestation challenge (Owner/Governance decision).
    ///         If approved, Karma is granted to the subject.
    /// @param _attestationId The ID of the attestation to resolve.
    /// @param _approved True to approve the attestation, false to reject.
    function resolveAttestationChallenge(uint256 _attestationId, bool _approved) public onlyOwner whenNotPaused {
        // In a full DAO, this would be `onlyGovernance`. For simplicity, `onlyOwner`.
        if (_attestationId >= attestations.length) revert AttestationNotFound();
        Attestation storage attestation = attestations[_attestationId];
        if (attestation.status == AttestationStatus.Approved || attestation.status == AttestationStatus.Rejected) revert AttestationAlreadyResolved();

        if (_approved) {
            attestation.status = AttestationStatus.Approved;
            grantKarma(attestation.subject, 100, "Attestation Approved"); // Example Karma amount
        } else {
            attestation.status = AttestationStatus.Rejected;
            // Optionally, penalize attester or challenger
        }
        emit AttestationResolved(_attestationId, _approved);
    }

    /// @notice Allows a user to burn a portion of their Karma for a one-time boost.
    ///         e.g., a temporary APR boost in a specific pool, or reduced fee.
    /// @param _amount The amount of Karma to burn.
    /// @param _boostType A string describing the type of boost desired.
    function burnKarmaForBoost(uint256 _amount, string memory _boostType) public whenNotPaused onlyKarmaHolder(_amount) {
        uint256 currentKarma = getUserKarma(msg.sender);
        if (currentKarma < _amount) revert InsufficientKarma(_amount, currentKarma);

        _userKarma[msg.sender].karma -= _amount;
        _userKarma[msg.sender].lastKarmaUpdate = block.timestamp; // Update last karma update due to burn
        emit KarmaBurned(msg.sender, _amount, _boostType);

        // Actual boost logic would be implemented here or trigger an external contract
        // For this example, it only emits the event.
    }

    // --- Opportunity Pools (4 functions) ---

    /// @notice Creates a new opportunity pool where users can deposit assets.
    /// @param _assetToken The ERC20 token to be deposited into the pool.
    /// @param _rewardToken The ERC20 token used for rewards.
    /// @param _durationDays The duration of the pool in days.
    /// @param _minKarmaRequired The minimum Karma required to participate in this pool.
    /// @param _karmaBoostFactor The boost multiplier for rewards based on Karma (e.g., 100 for 1x, 120 for 1.2x).
    function createOpportunityPool(
        IERC20 _assetToken,
        IERC20 _rewardToken,
        uint256 _durationDays,
        uint256 _minKarmaRequired,
        uint256 _karmaBoostFactor
    ) public whenNotPaused onlyKarmaHolder(500) returns (uint256) { // Example: requires 500 Karma to create a pool
        if (_assetToken == IERC20(address(0)) || _rewardToken == IERC20(address(0))) revert ZeroAddress();
        if (_durationDays == 0 || _karmaBoostFactor < 100) revert InvalidAmount();

        opportunityPools.push(OpportunityPool({
            creator: msg.sender,
            assetToken: _assetToken,
            rewardToken: _rewardToken,
            startTime: block.timestamp,
            endTime: block.timestamp + (_durationDays * 1 days),
            totalDeposited: 0,
            totalRewardsDistributed: 0,
            minKarmaRequired: _minKarmaRequired,
            karmaBoostFactor: _karmaBoostFactor
        }));

        uint256 poolId = _nextPoolId++;
        emit PoolCreated(poolId, msg.sender, address(_assetToken), address(_rewardToken), _minKarmaRequired);
        return poolId;
    }

    /// @notice Deposits tokens into an existing opportunity pool.
    ///         Karma influences eligibility and potential reward share.
    /// @param _poolId The ID of the opportunity pool.
    /// @param _amount The amount of tokens to deposit.
    function depositIntoPool(uint256 _poolId, uint256 _amount) public whenNotPaused nonReentrant {
        if (_poolId >= opportunityPools.length) revert PoolNotFound();
        if (_amount == 0) revert InvalidAmount();

        OpportunityPool storage pool = opportunityPools[_poolId];
        if (block.timestamp >= pool.endTime) revert PoolAlreadyEnded();

        uint256 userKarma = getUserKarma(msg.sender);
        if (userKarma < pool.minKarmaRequired) revert InsufficientKarma(pool.minKarmaRequired, userKarma);

        pool.assetToken.transferFrom(msg.sender, address(this), _amount);
        pool.deposits[msg.sender] += _amount;
        pool.totalDeposited += _amount;
        emit DepositedIntoPool(_poolId, msg.sender, address(pool.assetToken), _amount);
    }

    /// @notice Withdraws deposited tokens from an opportunity pool.
    /// @param _poolId The ID of the opportunity pool.
    function withdrawFromPool(uint256 _poolId) public whenNotPaused nonReentrant {
        if (_poolId >= opportunityPools.length) revert PoolNotFound();
        OpportunityPool storage pool = opportunityPools[_poolId];
        if (pool.deposits[msg.sender] == 0) revert InvalidAmount(); // No deposits to withdraw

        uint256 amountToWithdraw = pool.deposits[msg.sender];
        pool.deposits[msg.sender] = 0;
        pool.totalDeposited -= amountToWithdraw;

        pool.assetToken.transfer(msg.sender, amountToWithdraw);
        emit WithdrawnFromPool(_poolId, msg.sender, amountToWithdraw);
    }

    /// @notice Claims accumulated rewards from an opportunity pool.
    ///         Rewards are boosted by user's Karma and pool's boost factor.
    /// @param _poolId The ID of the opportunity pool.
    function claimPoolRewards(uint256 _poolId) public whenNotPaused nonReentrant {
        if (_poolId >= opportunityPools.length) revert PoolNotFound();
        OpportunityPool storage pool = opportunityPools[_poolId];
        if (block.timestamp < pool.endTime) revert PoolNotEndedYet();
        if (pool.deposits[msg.sender] == 0) revert InvalidAmount(); // No deposits, no rewards
        if (pool.rewardsClaimed[msg.sender] > 0) revert UnauthorizedAction("Rewards already claimed"); // Simple claim for now

        // Example reward calculation (can be much more complex, e.g., based on time, share, total rewards)
        // For simplicity: reward is a percentage of deposit, boosted by Karma
        uint256 userKarma = getUserKarma(msg.sender);
        uint256 rewardPercentage = 10; // Example: 10% base reward
        uint256 baseReward = pool.deposits[msg.sender] * rewardPercentage / 100;

        // Apply Karma boost
        uint256 finalReward = baseReward * (pool.karmaBoostFactor + (userKarma / 100)) / 100; // Simplified boost logic

        if (finalReward == 0) revert NoFeesToWithdraw(); // Reusing error

        pool.rewardsClaimed[msg.sender] = finalReward;
        pool.totalRewardsDistributed += finalReward;

        // Take a small protocol fee from the reward
        uint256 fee = finalReward * protocolFeeRate / 10_000; // protocolFeeRate is in basis points
        uint256 netReward = finalReward - fee;

        _protocolCollectedFees[address(pool.rewardToken)] += fee;
        pool.rewardToken.transfer(msg.sender, netReward);
        emit RewardsClaimed(_poolId, msg.sender, address(pool.rewardToken), netReward);
    }

    // --- Decentralized Task Network (6 functions) ---

    /// @notice Allows Karma holders to propose a decentralized task/bounty.
    /// @param _bountyToken The ERC20 token for the bounty.
    /// @param _bountyAmount The amount of bounty.
    /// @param _descriptionHash A hash of the task description.
    /// @param _minKarmaRequired The minimum Karma required for a user to accept this task.
    function proposeDecentralizedTask(
        IERC20 _bountyToken,
        uint256 _bountyAmount,
        bytes32 _descriptionHash,
        uint256 _minKarmaRequired
    ) public whenNotPaused onlyKarmaHolder(200) returns (uint256) { // Requires 200 Karma to propose task
        if (_bountyToken == IERC20(address(0))) revert ZeroAddress();
        if (_bountyAmount == 0) revert InvalidAmount();

        _bountyToken.transferFrom(msg.sender, address(this), _bountyAmount); // Proposer locks bounty

        decentralizedTasks.push(DecentralizedTask({
            proposer: msg.sender,
            accepter: address(0),
            bountyToken: _bountyToken,
            bountyAmount: _bountyAmount,
            descriptionHash: _descriptionHash,
            completionProofHash: bytes32(0),
            minKarmaRequired: _minKarmaRequired,
            status: TaskStatus.Proposed,
            proposalTime: block.timestamp,
            acceptTime: 0,
            completionSubmitTime: 0,
            challenger: address(0)
        }));

        uint256 taskId = _nextTaskId++;
        emit TaskProposed(taskId, msg.sender, address(_bountyToken), _bountyAmount, _descriptionHash, _minKarmaRequired);
        return taskId;
    }

    /// @notice Allows a Karma holder to accept a proposed task.
    /// @param _taskId The ID of the task to accept.
    function acceptDecentralizedTask(uint256 _taskId) public whenNotPaused {
        if (_taskId >= decentralizedTasks.length) revert TaskNotFound();
        DecentralizedTask storage task = decentralizedTasks[_taskId];
        if (task.status != TaskStatus.Proposed) revert UnauthorizedAction("Task not in proposed state");

        uint256 userKarma = getUserKarma(msg.sender);
        if (userKarma < task.minKarmaRequired) revert InsufficientKarma(task.minKarmaRequired, userKarma);
        if (msg.sender == task.proposer) revert UnauthorizedAction("Proposer cannot accept their own task");

        task.accepter = msg.sender;
        task.status = TaskStatus.Accepted;
        task.acceptTime = block.timestamp;
        emit TaskAccepted(_taskId, msg.sender);
    }

    /// @notice The task accepter submits proof of task completion.
    /// @param _taskId The ID of the task.
    /// @param _proofHash A hash of the completion proof.
    function submitTaskCompletionProof(uint256 _taskId, bytes32 _proofHash) public whenNotPaused {
        if (_taskId >= decentralizedTasks.length) revert TaskNotFound();
        DecentralizedTask storage task = decentralizedTasks[_taskId];
        if (task.accepter != msg.sender) revert UnauthorizedAction("Only task accepter can submit proof");
        if (task.status != TaskStatus.Accepted) revert UnauthorizedAction("Task not in accepted state");

        task.completionProofHash = _proofHash;
        task.status = TaskStatus.ProofSubmitted;
        task.completionSubmitTime = block.timestamp;
        emit TaskCompletionSubmitted(_taskId, msg.sender, _proofHash);
    }

    /// @notice Allows Karma holders or governance to verify task completion.
    /// @param _taskId The ID of the task.
    /// @param _approved True if completion is verified, false otherwise.
    function verifyTaskCompletion(uint256 _taskId, bool _approved) public whenNotPaused onlyOwner { // Can be extended to Karma-weighted vote
        if (_taskId >= decentralizedTasks.length) revert TaskNotFound();
        DecentralizedTask storage task = decentralizedTasks[_taskId];
        if (task.status != TaskStatus.ProofSubmitted && task.status != TaskStatus.Challenged) revert UnauthorizedAction("Task not in proof submitted or challenged state");

        if (_approved) {
            task.status = TaskStatus.Completed;
            task.bountyToken.transfer(task.accepter, task.bountyAmount); // Release bounty
            grantKarma(task.accepter, 50, "Task Completion Karma"); // Grant Karma for successful completion
        } else {
            task.status = TaskStatus.Failed;
            task.bountyToken.transfer(task.proposer, task.bountyAmount); // Return bounty to proposer
        }
        emit TaskCompletionVerified(_taskId, msg.sender, _approved);
    }

    /// @notice Allows a user to challenge a submitted task completion.
    /// @param _taskId The ID of the task.
    function challengeTaskCompletion(uint256 _taskId) public whenNotPaused {
        if (_taskId >= decentralizedTasks.length) revert TaskNotFound();
        DecentralizedTask storage task = decentralizedTasks[_taskId];
        if (task.status != TaskStatus.ProofSubmitted) revert UnauthorizedAction("Task not in proof submitted state");
        if (task.proposer == msg.sender || task.accepter == msg.sender) revert UnauthorizedAction("Proposer/Accepter cannot challenge");

        task.status = TaskStatus.Challenged;
        task.challenger = msg.sender;
        emit TaskCompletionChallenged(_taskId, msg.sender);
    }

    /// @notice Resolves a challenged task completion.
    /// @param _taskId The ID of the task.
    /// @param _success True if the task completion is upheld, false if rejected.
    function resolveTaskDispute(uint256 _taskId, bool _success) public onlyOwner whenNotPaused {
        if (_taskId >= decentralizedTasks.length) revert TaskNotFound();
        DecentralizedTask storage task = decentralizedTasks[_taskId];
        if (task.status != TaskStatus.Challenged) revert UnauthorizedAction("Task not in challenged state");

        if (_success) {
            task.status = TaskStatus.Completed;
            task.bountyToken.transfer(task.accepter, task.bountyAmount);
            grantKarma(task.accepter, 50, "Task Dispute Upheld Karma");
        } else {
            task.status = TaskStatus.Failed;
            task.bountyToken.transfer(task.proposer, task.bountyAmount);
            revokeKarma(task.accepter, 20, "Task Dispute Failed Karma"); // Penalize for failed completion
        }
        emit TaskDisputeResolved(_taskId, _success);
    }

    // --- Governance (3 functions) ---

    /// @notice Allows Karma holders to propose a governance action.
    /// @param _descriptionHash A hash of the proposal's description.
    /// @param _target The address of the contract to call if proposal passes.
    /// @param _callData The calldata for the target contract's function.
    function proposeGovernanceAction(
        bytes32 _descriptionHash,
        address _target,
        bytes memory _callData
    ) public whenNotPaused onlyKarmaHolder(MIN_KARMA_FOR_PROPOSAL) returns (uint256) {
        governanceProposals.push(GovernanceProposal({
            proposer: msg.sender,
            descriptionHash: _descriptionHash,
            target: _target,
            callData: _callData,
            startBlock: block.number,
            endBlock: block.number + (VOTING_PERIOD_DURATION / block.timestamp), // Approx blocks in duration
            votesFor: 0,
            votesAgainst: 0,
            status: ProposalStatus.Active,
            hasVoted: new mapping(address => bool)
        }));

        uint256 proposalId = _nextProposalId++;
        emit GovernanceProposalProposed(proposalId, msg.sender, _descriptionHash, _target, _callData);
        return proposalId;
    }

    /// @notice Allows Karma holders (or their delegates) to vote on a governance proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _support True for 'for' vote, false for 'against' vote.
    function voteOnGovernanceAction(uint256 _proposalId, bool _support) public whenNotPaused {
        if (_proposalId >= governanceProposals.length) revert GovernanceProposalNotFound();
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.status != ProposalStatus.Active) revert UnauthorizedAction("Proposal not active");
        if (block.number > proposal.endBlock) revert UnauthorizedAction("Voting period ended");

        address voter = msg.sender;
        if (_userKarma[voter].delegatedTo != address(0)) {
            voter = _userKarma[voter].delegatedTo; // If delegated, the vote is counted by the delegatee
        }

        if (proposal.hasVoted[voter]) revert AlreadyVoted();

        uint256 karmaWeight = getUserKarma(voter);
        if (karmaWeight == 0) revert InsufficientKarma(1, 0); // Must have some Karma to vote

        if (_support) {
            proposal.votesFor += karmaWeight;
        } else {
            proposal.votesAgainst += karmaWeight;
        }
        proposal.hasVoted[voter] = true;
        emit Voted(_proposalId, msg.sender, _support, karmaWeight); // Emit original msg.sender for tracking
    }

    /// @notice Executes a governance proposal if it has passed and the voting period has ended.
    /// @param _proposalId The ID of the proposal to execute.
    function executeGovernanceAction(uint256 _proposalId) public whenNotPaused nonReentrant {
        if (_proposalId >= governanceProposals.length) revert GovernanceProposalNotFound();
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.status == ProposalStatus.Executed) revert ProposalAlreadyExecuted();
        if (block.number <= proposal.endBlock) revert ProposalNotYetExecutable();

        if (proposal.votesFor > proposal.votesAgainst && proposal.votesFor > (proposal.votesFor + proposal.votesAgainst) / 2) {
            // Basic majority rule: more 'for' votes than 'against' and more than 50% of total votes
            proposal.status = ProposalStatus.Succeeded;
            // Execute the action
            (bool success,) = proposal.target.call(proposal.callData);
            if (!success) {
                // In a real scenario, more robust error handling/reverts would be needed
                // For this example, we'll assume a revert means failure, but often try-catch is used
                revert ProposalFailed();
            }
            proposal.status = ProposalStatus.Executed;
            emit GovernanceProposalExecuted(_proposalId);
        } else {
            proposal.status = ProposalStatus.Failed;
            revert ProposalFailed();
        }
    }

    // --- Query & Utility (5 functions) ---

    /// @notice Retrieves details of an opportunity pool.
    /// @param _poolId The ID of the pool.
    /// @return poolDetails Tuple containing various pool information.
    function getOpportunityPoolDetails(uint256 _poolId) public view returns (
        address creator,
        address assetToken,
        address rewardToken,
        uint256 startTime,
        uint256 endTime,
        uint256 totalDeposited,
        uint256 totalRewardsDistributed,
        uint256 minKarmaRequired,
        uint256 karmaBoostFactor
    ) {
        if (_poolId >= opportunityPools.length) revert PoolNotFound();
        OpportunityPool storage pool = opportunityPools[_poolId];
        return (
            pool.creator,
            address(pool.assetToken),
            address(pool.rewardToken),
            pool.startTime,
            pool.endTime,
            pool.totalDeposited,
            pool.totalRewardsDistributed,
            pool.minKarmaRequired,
            pool.karmaBoostFactor
        );
    }

    /// @notice Retrieves details of a decentralized task.
    /// @param _taskId The ID of the task.
    /// @return taskDetails Tuple containing various task information.
    function getTaskDetails(uint256 _taskId) public view returns (
        address proposer,
        address accepter,
        address bountyToken,
        uint256 bountyAmount,
        bytes32 descriptionHash,
        bytes32 completionProofHash,
        uint256 minKarmaRequired,
        TaskStatus status,
        uint256 proposalTime,
        uint256 acceptTime,
        uint256 completionSubmitTime
    ) {
        if (_taskId >= decentralizedTasks.length) revert TaskNotFound();
        DecentralizedTask storage task = decentralizedTasks[_taskId];
        return (
            task.proposer,
            task.accepter,
            address(task.bountyToken),
            task.bountyAmount,
            task.descriptionHash,
            task.completionProofHash,
            task.minKarmaRequired,
            task.status,
            task.proposalTime,
            task.acceptTime,
            task.completionSubmitTime
        );
    }

    /// @notice Retrieves details of a governance proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return proposalDetails Tuple containing various proposal information.
    function getGovernanceProposalDetails(uint256 _proposalId) public view returns (
        address proposer,
        bytes32 descriptionHash,
        address target,
        bytes memory callData,
        uint256 startBlock,
        uint256 endBlock,
        uint256 votesFor,
        uint256 votesAgainst,
        ProposalStatus status
    ) {
        if (_proposalId >= governanceProposals.length) revert GovernanceProposalNotFound();
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        return (
            proposal.proposer,
            proposal.descriptionHash,
            proposal.target,
            proposal.callData,
            proposal.startBlock,
            proposal.endBlock,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.status
        );
    }

    /// @notice Returns the current protocol status and configuration.
    /// @return _paused Current paused state.
    /// @return _feeRecipient Current fee recipient.
    /// @return _feeRate Current protocol fee rate.
    function getProtocolStatus() public view returns (bool _paused, address _feeRecipient, uint256 _feeRate) {
        return (paused(), protocolFeeRecipient, protocolFeeRate);
    }

    /// @notice Returns the number of existing opportunity pools.
    function getOpportunityPoolCount() public view returns (uint256) {
        return opportunityPools.length;
    }

    // Total functions: 31
    // Core Infrastructure: 6
    // Karma Management: 10
    // Opportunity Pools: 4
    // Decentralized Task Network: 6
    // Governance: 3
    // Query & Utility: 5
}
```