Okay, this is an exciting challenge! Creating a smart contract that is genuinely advanced, creative, trendy, and *not* a direct copy of existing open-source projects, while also sporting 20+ distinct functions, requires combining several cutting-edge concepts.

Let's design "ChronoForge DAO" - a decentralized autonomous organization focused on **time-locked, conditional execution of proposals**, integrated with a novel **reputation/impact measurement system** using Soulbound Token (SBT) principles, and a mechanism for **retroactive public goods funding**.

This contract embraces:
1.  **Advanced DAO Governance:** Time-locked proposals, conditional execution (requiring off-chain proofs), dynamic voting power, and proposer staking.
2.  **Reputation Economy (SBT-inspired):** Non-transferable "Impact Certificates" for contributions, which directly influence voting power and access to specific DAO functions.
3.  **Retroactive Public Goods Funding:** A specific mechanism to reward past contributions based on impact, distinct from regular proposals.
4.  **Incentivized Execution:** "Keepers" are rewarded for executing time-locked proposals.
5.  **Dispute Resolution:** Arbiters for challenging conditional proofs or impact certificate revocations.
6.  **Modular & Upgradeable (Conceptual):** While the proxy pattern itself isn't implemented here, the contract design considers how it would fit into an upgradeable system.

---

## ChronoForge DAO: Outline & Function Summary

**Contract Name:** `ChronoForgeDAO`

**Core Concepts:**
*   **Time-Locked Execution:** Proposals aren't executed immediately after voting; they are scheduled for a future `executionTime`.
*   **Conditional Execution:** Proposals can have an off-chain condition that must be met (proven on-chain) before execution. This allows integration with ZK-proofs, AI oracle results, or other complex logic.
*   **Dynamic Reputation:** Users earn non-transferable "Impact Certificates" (SBTs) based on their contributions, which can dynamically adjust their voting power and grant access.
*   **Keeper Network:** Incentivized roles ("Keepers") execute scheduled proposals, ensuring the DAO's operations continue without central points of failure.
*   **Arbiter Role:** Dedicated roles for resolving disputes related to conditional proofs or impact certificates.
*   **Retroactive Funding:** A specific process for the DAO to fund past public goods or impactful projects.

**Roles:**
*   `ADMIN_ROLE`: Oversees core contract configurations, role assignments.
*   `KEEPER_ROLE`: Executes valid, time-locked proposals for a bounty.
*   `ARBITER_ROLE`: Resolves disputes related to conditions or impact.

---

### Function Summary (25+ Functions)

**I. Core DAO Governance & Proposal Lifecycle**
1.  `proposeExecution`: Creates a new time-locked proposal with an optional condition. Requires a stake from the proposer.
2.  `castVote`: Members vote on a proposal, their voting power potentially influenced by their `ImpactCertificates`.
3.  `delegateVotingPower`: Delegates voting power for a specified duration, allowing liquid democracy.
4.  `revokeVotingDelegation`: Revokes an active voting delegation.
5.  `queueProposalForExecution`: Marks a voted-on proposal as ready to be executed once its `executionTime` is reached.
6.  `executeProposal`: (KEEPER_ROLE or anyone for public good) Triggers the execution of a queued, time-locked, and valid proposal. Awards bounty to keeper.
7.  `cancelProposal`: Allows a proposer (under strict conditions) or ADMIN to cancel a proposal.
8.  `slashProposerStake`: Slashes the proposer's stake if their proposal fails or is malicious.

**II. Conditional Execution & Dispute Resolution**
9.  `submitConditionProof`: Proposer (or anyone) submits an off-chain proof (e.g., ZKP, oracle result hash) to fulfill a proposal's condition.
10. `challengeConditionProof`: ARBITER_ROLE or an interested party can challenge a submitted condition proof.
11. `resolveConditionChallenge`: ARBITER_ROLE resolves the challenge, marking the proof as valid or invalid.

**III. Reputation & Impact System (SBT-inspired)**
12. `mintImpactCertificate`: (ADMIN_ROLE or via specific DAO proposal) Mints a non-transferable "Impact Certificate" (SBT) to a recipient, with a category and score.
13. `revokeImpactCertificate`: (ARBITER_ROLE or via specific DAO proposal) Revokes an Impact Certificate if it's found to be invalid or fraudulent.
14. `getHolderImpactScore`: Retrieves the aggregate impact score for a specific account across all their valid Impact Certificates.
15. `getVotingPower`: Calculates an account's dynamic voting power, influenced by their token stake and Impact Certificates.

**IV. Retroactive Public Goods Funding**
16. `proposeRetroactiveGrant`: Creates a proposal specifically for funding a past project/contributor based on demonstrated impact.
17. `castRetroactiveGrantVote`: Members vote on a retroactive grant proposal.
18. `distributeRetroactiveGrant`: (KEEPER_ROLE) Distributes funds for an approved retroactive grant.

**V. Treasury Management**
19. `depositTreasury`: Allows anyone to deposit funds into the DAO treasury.
20. `withdrawTreasuryFunds`: Executed only via a successful `proposeExecution` proposal targeting the treasury.

**VI. Role Management & Configuration**
21. `grantRole`: (ADMIN_ROLE) Grants a specific role to an account.
22. `revokeRole`: (ADMIN_ROLE) Revokes a specific role from an account.
23. `setExecutionBounty`: (ADMIN_ROLE or via DAO proposal) Sets the bounty for Keepers executing proposals.
24. `updateProposalConfig`: (ADMIN_ROLE or via DAO proposal) Updates core proposal parameters (e.g., voting period, min stake, execution grace period).
25. `pauseContract`: (ADMIN_ROLE) Emergency pause functionality.
26. `unpauseContract`: (ADMIN_ROLE) Unpauses the contract.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


// --- Outline & Function Summary ---
// Contract Name: ChronoForgeDAO
// Core Concepts:
// - Time-Locked Execution: Proposals aren't executed immediately after voting; they are scheduled for a future `executionTime`.
// - Conditional Execution: Proposals can have an off-chain condition that must be met (proven on-chain) before execution. This allows integration with ZK-proofs, AI oracle results, or other complex logic.
// - Dynamic Reputation: Users earn non-transferable "Impact Certificates" (SBTs) based on their contributions, which can dynamically adjust their voting power and grant access.
// - Keeper Network: Incentivized roles ("Keepers") execute scheduled proposals, ensuring the DAO's operations continue without central points of failure.
// - Arbiter Role: Dedicated roles for resolving disputes related to conditional proofs or impact certificate revocations.
// - Retroactive Funding: A specific process for the DAO to fund past public goods or impactful projects.

// Roles:
// - ADMIN_ROLE: Oversees core contract configurations, role assignments.
// - KEEPER_ROLE: Executes valid, time-locked proposals for a bounty.
// - ARBITER_ROLE: Resolves disputes related to conditions or impact.

// Function Summary:
// I. Core DAO Governance & Proposal Lifecycle
// 1. proposeExecution: Creates a new time-locked proposal with an optional condition. Requires a stake from the proposer.
// 2. castVote: Members vote on a proposal, their voting power potentially influenced by their ImpactCertificates.
// 3. delegateVotingPower: Delegates voting power for a specified duration, allowing liquid democracy.
// 4. revokeVotingDelegation: Revokes an active voting delegation.
// 5. queueProposalForExecution: Marks a voted-on proposal as ready to be executed once its `executionTime` is reached.
// 6. executeProposal: (KEEPER_ROLE or anyone for public good) Triggers the execution of a queued, time-locked, and valid proposal. Awards bounty to keeper.
// 7. cancelProposal: Allows a proposer (under strict conditions) or ADMIN to cancel a proposal.
// 8. slashProposerStake: Slashes the proposer's stake if their proposal fails or is malicious.

// II. Conditional Execution & Dispute Resolution
// 9. submitConditionProof: Proposer (or anyone) submits an off-chain proof (e.g., ZKP, oracle result hash) to fulfill a proposal's condition.
// 10. challengeConditionProof: ARBITER_ROLE or an interested party can challenge a submitted condition proof.
// 11. resolveConditionChallenge: ARBITER_ROLE resolves the challenge, marking the proof as valid or invalid.

// III. Reputation & Impact System (SBT-inspired)
// 12. mintImpactCertificate: (ADMIN_ROLE or via specific DAO proposal) Mints a non-transferable "Impact Certificate" (SBT) to a recipient, with a category and score.
// 13. revokeImpactCertificate: (ARBITER_ROLE or via specific DAO proposal) Revokes an Impact Certificate if it's found to be invalid or fraudulent.
// 14. getHolderImpactScore: Retrieves the aggregate impact score for a specific account across all their valid Impact Certificates.
// 15. getVotingPower: Calculates an account's dynamic voting power, influenced by their token stake and Impact Certificates.

// IV. Retroactive Public Goods Funding
// 16. proposeRetroactiveGrant: Creates a proposal specifically for funding a past project/contributor based on demonstrated impact.
// 17. castRetroactiveGrantVote: Members vote on a retroactive grant proposal.
// 18. distributeRetroactiveGrant: (KEEPER_ROLE) Distributes funds for an approved retroactive grant.

// V. Treasury Management
// 19. depositTreasury: Allows anyone to deposit funds into the DAO treasury.
// 20. withdrawTreasuryFunds: Executed only via a successful `proposeExecution` proposal targeting the treasury.

// VI. Role Management & Configuration
// 21. grantRole: (ADMIN_ROLE) Grants a specific role to an account.
// 22. revokeRole: (ADMIN_ROLE) Revokes a specific role from an account.
// 23. setExecutionBounty: (ADMIN_ROLE or via DAO proposal) Sets the bounty for Keepers executing proposals.
// 24. updateProposalConfig: (ADMIN_ROLE or via DAO proposal) Updates core proposal parameters (e.g., voting period, min stake, execution grace period).
// 25. pauseContract: (ADMIN_ROLE) Emergency pause functionality.
// 26. unpauseContract: (ADMIN_ROLE) Unpauses the contract.
// 27. rescueERC20: Allows admin to recover accidentally sent ERC20 tokens (not main treasury tokens).

// VII. External View Functions (Not explicitly counted in the 20+, but essential utilities)
// 28. getProposalState: Returns the current state of a proposal.
// 29. getImpactCertificate: Retrieves details of a specific Impact Certificate.
// 30. getImpactCertificateBalance: Returns the number of Impact Certificates held by an address.
// 31. getMinProposerStake: Returns the current minimum stake required for a proposal.

contract ChronoForgeDAO is Context, AccessControl, Pausable, IERC721Receiver {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

    // --- State Variables ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
    bytes32 public constant ARBITER_ROLE = keccak256("ARBITER_ROLE");

    IERC20 public immutable governanceToken; // The token used for voting power
    IERC20 public immutable treasuryToken;   // The primary token held in the DAO treasury (can be different from governance token)

    uint256 public minProposerStake;
    uint256 public proposalVotingPeriod; // seconds
    uint256 public proposalExecutionGracePeriod; // seconds, after executionTime, before it becomes expired
    uint256 public minQuorumNumerator; // For example, 51 for 51% (out of 100 denominator)
    uint256 public minVotePowerToPropose; // Min combined token/impact voting power to propose

    uint256 public executionBounty; // Amount rewarded to keepers for successful execution

    Counters.Counter private _proposalIds;
    Counters.Counter private _impactCertificateIds;

    // --- Structs & Enums ---

    enum ProposalState {
        Pending,        // Just created
        ActiveVoting,   // Open for votes
        Succeeded,      // Passed voting, waiting for condition/execution time
        Queued,         // Ready for keeper execution
        Executed,       // Successfully executed
        Failed,         // Did not meet quorum/threshold
        Cancelled,      // Cancelled by proposer/admin
        Expired,        // Not executed within grace period
        Challenged,     // Conditional proof is challenged
        Rejected        // Conditional proof was invalid
    }

    struct Proposal {
        uint256 id;
        address proposer;
        uint256 proposerStake; // Stake required to create a proposal
        address target;       // Address to call
        uint256 value;        // ETH/Native token to send
        bytes callData;       // Calldata for the target
        string description;   // Off-chain description URI

        uint256 voteStartBlock;
        uint256 voteEndBlock;
        uint256 votesFor;
        uint256 votesAgainst;

        uint256 executionTime;       // Scheduled timestamp for execution
        bytes32 conditionHash;       // Hash of an off-chain condition, 0x0 if no condition
        bytes conditionProof;        // Proof submitted for the condition
        bool conditionProofSubmitted; // Flag if proof has been submitted
        bool conditionProofValid;     // Flag if proof has been validated by arbiters

        ProposalState state;
        uint256 quorumNumerator; // Snapshot of current quorum requirement for this proposal
        uint256 totalVotingSupplyAtProposal; // Total voting power at the time of proposal creation for quorum check
        uint256 initialVotingPowerRequired; // Minimum voting power required to cast a first vote (to prevent spam)
        bool isRetroactiveGrant; // True if this is a retroactive funding proposal
    }

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voter => bool
    mapping(address => address) public delegatedVotingPower; // delegator => delegatee
    mapping(address => uint256) public delegationExpiry; // delegatee => expiry timestamp

    struct ImpactCertificate {
        uint256 id;
        address recipient;
        string category;    // e.g., "CodeContributor", "CommunityManager", "Research", "BugBounty"
        uint256 score;      // A numeric score representing impact (e.g., 1-100)
        uint256 mintTime;
        string metadataURI; // URI to off-chain metadata (e.g., IPFS hash to detailed contribution)
        bool revoked;       // True if the certificate has been revoked
    }

    mapping(uint256 => ImpactCertificate) public impactCertificates;
    mapping(address => uint256[]) public holderImpactCertificates; // owner => array of certificate IDs

    // --- Events ---
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, address indexed target, uint256 value, uint256 executionTime, bytes32 conditionHash);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 votePower, bool support);
    event ProposalQueued(uint256 indexed proposalId, uint256 executionTime);
    event ProposalExecuted(uint256 indexed proposalId, address indexed executor, uint256 executionBounty);
    event ProposalCancelled(uint256 indexed proposalId);
    event ProposalFailed(uint256 indexed proposalId);
    event ProposerStakeSlashed(uint256 indexed proposalId, address indexed proposer, uint256 amount);

    event ConditionProofSubmitted(uint256 indexed proposalId, bytes32 conditionHash);
    event ConditionProofChallenged(uint256 indexed proposalId, address indexed challenger);
    event ConditionChallengeResolved(uint256 indexed proposalId, bool isValid);

    event ImpactCertificateMinted(uint256 indexed tokenId, address indexed recipient, string category, uint256 score, string metadataURI);
    event ImpactCertificateRevoked(uint256 indexed tokenId, address indexed revoker);

    event RetroactiveGrantProposed(uint256 indexed proposalId, address indexed recipient, uint256 amount);
    event RetroactiveGrantDistributed(uint256 indexed proposalId, address indexed recipient, uint256 amount);

    event TreasuryDeposited(address indexed sender, uint256 amount);
    event TreasuryWithdrawn(address indexed recipient, uint256 amount);

    event ExecutionBountySet(uint256 newBounty);
    event ProposalConfigUpdated(uint256 newMinProposerStake, uint256 newVotingPeriod, uint256 newGracePeriod, uint256 newMinQuorum, uint256 newMinVotePowerToPropose);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);


    // --- Errors (Custom Errors for gas efficiency and clarity) ---
    error Unauthorized();
    error InvalidState(ProposalState currentState, string expectedAction);
    error InvalidProposalId();
    error AlreadyVoted();
    error NoVotingPower();
    error ProposalNotOpenForVoting();
    error VotingPeriodNotEnded();
    error QuorumNotMet();
    error AlreadyQueued();
    error ExecutionNotReady();
    error ExecutionTimeNotReached();
    error ExecutionTimeExpired();
    error ConditionNotMet();
    error NotProposer();
    error ProposerStakeRequired(uint256 required);
    error InsufficientBalance();
    error ZeroAddress();
    error InvalidScore();
    error CertificateAlreadyRevoked();
    error ProofAlreadySubmitted();
    error ProofNotSubmitted();
    error ProofAlreadyValidated();
    error NoDelegationActive();
    error DelegationExpired();
    error DelegationActive();
    error InvalidExecutionCall();
    error TargetNotAllowed(); // For safety in withdrawTreasuryFunds

    // --- Constructor ---
    constructor(
        address _governanceToken,
        address _treasuryToken,
        uint256 _minProposerStake,
        uint256 _proposalVotingPeriod,
        uint256 _proposalExecutionGracePeriod,
        uint256 _minQuorumNumerator,
        uint256 _minVotePowerToPropose,
        uint256 _executionBounty
    ) {
        if (_governanceToken == address(0) || _treasuryToken == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender()); // The deployer is the initial admin
        _grantRole(ADMIN_ROLE, _msgSender()); // The deployer is also the ChronoForge Admin
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(KEEPER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(ARBITER_ROLE, ADMIN_ROLE);

        governanceToken = IERC20(_governanceToken);
        treasuryToken = IERC20(_treasuryToken);

        minProposerStake = _minProposerStake;
        proposalVotingPeriod = _proposalVotingPeriod;
        proposalExecutionGracePeriod = _proposalExecutionGracePeriod;
        minQuorumNumerator = _minQuorumNumerator; // e.g., 51 for 51%
        minVotePowerToPropose = _minVotePowerToPropose;
        executionBounty = _executionBounty;
    }

    // --- I. Core DAO Governance & Proposal Lifecycle ---

    /**
     * @dev Creates a new time-locked proposal with an optional off-chain condition.
     *      Requires the proposer to stake `minProposerStake` governance tokens.
     * @param _target The address the proposal will call.
     * @param _value The amount of native token (ETH) to send with the call.
     * @param _signature The function signature of the call (e.g., "transfer(address,uint256)").
     * @param _callData The encoded calldata for the target function, excluding signature.
     * @param _descriptionURI URI to off-chain proposal details (e.g., IPFS hash).
     * @param _executionTime The Unix timestamp when the proposal can be executed. Must be in the future.
     * @param _conditionHash A keccak256 hash of the off-chain condition. Use 0x0 if no condition.
     * @return proposalId The ID of the newly created proposal.
     */
    function proposeExecution(
        address _target,
        uint256 _value,
        string memory _signature,
        bytes memory _callData,
        string memory _descriptionURI,
        uint256 _executionTime,
        bytes32 _conditionHash
    ) external whenNotPaused returns (uint256 proposalId) {
        if (_executionTime <= block.timestamp) revert InvalidExecutionTime();
        if (getVotingPower(_msgSender()) < minVotePowerToPropose) revert NoVotingPower();
        if (governanceToken.balanceOf(_msgSender()) < minProposerStake) revert ProposerStakeRequired(minProposerStake);

        // Transfer proposer stake to the contract
        if (!governanceToken.transferFrom(_msgSender(), address(this), minProposerStake)) revert InsufficientBalance();

        proposalId = _proposalIds.current();
        _proposalIds.increment();

        bytes memory fullCallData;
        if (bytes(_signature).length > 0) {
            fullCallData = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _callData);
        } else {
            fullCallData = _callData;
        }

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: _msgSender(),
            proposerStake: minProposerStake,
            target: _target,
            value: _value,
            callData: fullCallData, // Store combined signature + calldata
            description: _descriptionURI,
            voteStartBlock: block.number,
            voteEndBlock: block.number.add(proposalVotingPeriod / 12), // Assuming ~12s block time, for simplicity
            votesFor: 0,
            votesAgainst: 0,
            executionTime: _executionTime,
            conditionHash: _conditionHash,
            conditionProof: "", // Initialize as empty
            conditionProofSubmitted: false,
            conditionProofValid: false,
            state: ProposalState.ActiveVoting,
            quorumNumerator: minQuorumNumerator, // Snapshot current quorum
            totalVotingSupplyAtProposal: governanceToken.totalSupply().add(getDaoTotalImpactScore()), // Snapshot total voting power
            initialVotingPowerRequired: minVotePowerToPropose, // Snapshot initial requirement
            isRetroactiveGrant: false
        });

        emit ProposalCreated(proposalId, _msgSender(), _target, _value, _executionTime, _conditionHash);
        return proposalId;
    }

    /**
     * @dev Allows members to cast a vote on a proposal.
     *      Voting power is calculated based on staked tokens and Impact Certificates.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'for' vote, False for 'against' vote.
     */
    function castVote(uint256 _proposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.state != ProposalState.ActiveVoting) revert ProposalNotOpenForVoting();
        if (block.number > proposal.voteEndBlock) revert VotingPeriodNotEnded();
        if (hasVoted[_proposalId][_msgSender()]) revert AlreadyVoted();

        address voter = _msgSender();
        if (delegatedVotingPower[voter] != address(0) && delegationExpiry[voter] >= block.timestamp) {
            voter = delegatedVotingPower[voter]; // If delegated, vote as the delegatee
        }

        uint256 votePower = getVotingPower(voter);
        if (votePower == 0) revert NoVotingPower();

        if (_support) {
            proposal.votesFor = proposal.votesFor.add(votePower);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(votePower);
        }
        hasVoted[_proposalId][_msgSender()] = true;

        emit VoteCast(_proposalId, _msgSender(), votePower, _support);
    }

    /**
     * @dev Delegates voting power to another address for a specified duration.
     * @param _delegatee The address to delegate voting power to.
     * @param _expirationTimestamp The Unix timestamp when the delegation expires.
     */
    function delegateVotingPower(address _delegatee, uint256 _expirationTimestamp) external whenNotPaused {
        if (_delegatee == address(0)) revert ZeroAddress();
        if (_delegatee == _msgSender()) revert InvalidDelegatee();
        if (delegatedVotingPower[_msgSender()] != address(0)) revert DelegationActive(); // Only one active delegation at a time

        delegatedVotingPower[_msgSender()] = _delegatee;
        delegationExpiry[_msgSender()] = _expirationTimestamp; // Store expiry for the delegator's delegation

        // Potentially, adjust delegatee's effective voting power immediately, or rely on `getVotingPower`
        emit VoteDelegated(_msgSender(), _delegatee, _expirationTimestamp);
    }

    /**
     * @dev Revokes an active voting delegation.
     */
    function revokeVotingDelegation() external whenNotPaused {
        if (delegatedVotingPower[_msgSender()] == address(0)) revert NoDelegationActive();

        delete delegatedVotingPower[_msgSender()];
        delete delegationExpiry[_msgSender()];

        emit VoteDelegationRevoked(_msgSender());
    }

    /**
     * @dev Marks a proposal as queued for execution if voting succeeded and conditions are met (if any).
     *      Anyone can call this, it changes the proposal state for `executeProposal`.
     * @param _proposalId The ID of the proposal to queue.
     */
    function queueProposalForExecution(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.state != ProposalState.ActiveVoting) revert InvalidState(proposal.state, "ActiveVoting");
        if (block.number <= proposal.voteEndBlock) revert VotingPeriodNotEnded(); // Voting must have ended

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        uint256 requiredQuorum = proposal.totalVotingSupplyAtProposal.mul(proposal.quorumNumerator).div(100);

        if (totalVotes < requiredQuorum || proposal.votesFor <= proposal.votesAgainst) {
            proposal.state = ProposalState.Failed; // Not enough votes or 'against' won
            emit ProposalFailed(_proposalId);
            return;
        }

        // If condition exists, it must be valid for proposal to proceed
        if (proposal.conditionHash != bytes32(0) && !proposal.conditionProofValid) {
            proposal.state = ProposalState.Succeeded; // Succeeded voting, but needs condition proof
            emit ProposalSucceeded(_proposalId);
            return;
        }

        // Passed voting and condition (if any)
        proposal.state = ProposalState.Queued;
        emit ProposalQueued(_proposalId, proposal.executionTime);
    }

    /**
     * @dev Executes a queued proposal once its execution time has passed.
     *      Can be called by any KEEPER_ROLE or anyone for public benefit, and pays a bounty to the caller.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external payable whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.state != ProposalState.Queued) revert InvalidState(proposal.state, "Queued");
        if (block.timestamp < proposal.executionTime) revert ExecutionTimeNotReached();
        if (block.timestamp > proposal.executionTime.add(proposalExecutionGracePeriod)) {
            proposal.state = ProposalState.Expired; // Expired, cannot be executed
            emit ProposalFailed(_proposalId); // Re-use failed event, or create Expired
            revert ExecutionTimeExpired();
        }
        if (proposal.conditionHash != bytes32(0) && !proposal.conditionProofValid) {
            revert ConditionNotMet(); // Re-check condition before execution
        }

        // Perform the external call
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        if (!success) {
            proposal.state = ProposalState.Failed;
            _slashProposerStake(_proposalId); // Slash stake on failed execution
            emit ProposalFailed(_proposalId);
            revert InvalidExecutionCall();
        }

        // Pay keeper bounty if successful
        if (executionBounty > 0 && address(this).balance >= executionBounty && hasRole(KEEPER_ROLE, _msgSender())) {
            payable(_msgSender()).transfer(executionBounty);
        }

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId, _msgSender(), executionBounty);
    }

    /**
     * @dev Allows the proposer or an ADMIN_ROLE to cancel a proposal under specific conditions.
     *      Proposer can only cancel if proposal is in Pending or ActiveVoting. ADMIN_ROLE can cancel anytime before execution.
     * @param _proposalId The ID of the proposal to cancel.
     */
    function cancelProposal(uint256 _proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();

        bool isAdmin = hasRole(ADMIN_ROLE, _msgSender());
        bool isProposer = _msgSender() == proposal.proposer;

        if (!isAdmin && !isProposer) revert Unauthorized();

        if (isAdmin) {
            if (proposal.state == ProposalState.Executed || proposal.state == ProposalState.Expired) revert InvalidState(proposal.state, "Not Executed or Expired");
        } else { // isProposer
            if (proposal.state != ProposalState.Pending && proposal.state != ProposalState.ActiveVoting) {
                revert InvalidState(proposal.state, "Pending or ActiveVoting for Proposer");
            }
        }

        // Refund proposer stake
        if (!governanceToken.transfer(proposal.proposer, proposal.proposerStake)) revert InsufficientBalance();

        proposal.state = ProposalState.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    /**
     * @dev Slashes the proposer's stake and transfers it to the DAO treasury.
     *      Internal function called when a proposal fails execution or is deemed malicious.
     * @param _proposalId The ID of the proposal whose stake to slash.
     */
    function _slashProposerStake(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposerStake == 0) return; // Nothing to slash

        // Stake is already in the contract, just zero it out and emit
        uint256 slashedAmount = proposal.proposerStake;
        proposal.proposerStake = 0; // Prevent double slashing

        emit ProposerStakeSlashed(_proposalId, proposal.proposer, slashedAmount);
    }


    // --- II. Conditional Execution & Dispute Resolution ---

    /**
     * @dev Proposer or anyone can submit an off-chain proof (e.g., ZKP output, oracle result hash)
     *      for a proposal's condition to be met.
     * @param _proposalId The ID of the proposal.
     * @param _proof The actual bytes of the proof. This could be a ZKP, an oracle signature, etc.
     */
    function submitConditionProof(uint256 _proposalId, bytes memory _proof) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.conditionHash == bytes32(0)) revert NoConditionRequired(); // No condition set for this proposal
        if (proposal.conditionProofSubmitted) revert ProofAlreadySubmitted();
        if (proposal.state != ProposalState.Succeeded) revert InvalidState(proposal.state, "Succeeded to Submit Proof");

        // IMPORTANT: The actual verification of the proof bytes against the conditionHash
        // would happen here or in a separate verifier contract. For this example, we assume
        // the proof itself is provided and the logic to verify `_proof` against `proposal.conditionHash`
        // is external or very complex. We're just marking it as submitted.
        // A real implementation would involve a hash check like `keccak256(_proof) == proposal.conditionHash`
        // or a call to an external verifier.

        proposal.conditionProof = _proof;
        proposal.conditionProofSubmitted = true;
        // At this point, the proof is submitted but not yet validated.
        // It requires either an Arbiter or an automated on-chain verification to set `conditionProofValid = true`.

        emit ConditionProofSubmitted(_proposalId, proposal.conditionHash);
    }

    /**
     * @dev Allows an ARBITER_ROLE or any concerned party to challenge a submitted condition proof.
     *      This would initiate a dispute resolution process by Arbiters.
     * @param _proposalId The ID of the proposal.
     * @param _challengeReasonURI URI pointing to the reason for the challenge (off-chain).
     */
    function challengeConditionProof(uint256 _proposalId, string memory _challengeReasonURI) external whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.conditionHash == bytes32(0)) revert NoConditionRequired();
        if (!proposal.conditionProofSubmitted) revert ProofNotSubmitted();
        if (proposal.conditionProofValid) revert ProofAlreadyValidated(); // Can't challenge if already validated

        // Move to Challenged state, preventing execution until resolved
        proposal.state = ProposalState.Challenged;
        emit ConditionProofChallenged(_proposalId, _msgSender());
        // Log the reason URI if needed in an event, or handle off-chain
    }

    /**
     * @dev Resolves a challenge on a condition proof. Only ARBITER_ROLE can call this.
     *      Sets the `conditionProofValid` flag and potentially moves the proposal to Queued or Rejected.
     * @param _proposalId The ID of the proposal.
     * @param _isValid True if the proof is deemed valid, false otherwise.
     */
    function resolveConditionChallenge(uint256 _proposalId, bool _isValid) external onlyRole(ARBITER_ROLE) whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (proposal.state != ProposalState.Challenged) revert InvalidState(proposal.state, "Challenged");

        proposal.conditionProofValid = _isValid;

        if (_isValid) {
            proposal.state = ProposalState.Queued; // Move to queued if proof is valid
            emit ProposalQueued(_proposalId, proposal.executionTime);
        } else {
            proposal.state = ProposalState.Rejected; // Rejected if proof is invalid
            _slashProposerStake(_proposalId); // Slash stake if condition invalidates proposal
        }

        emit ConditionChallengeResolved(_proposalId, _isValid);
    }

    // --- III. Reputation & Impact System (SBT-inspired) ---

    /**
     * @dev Mints a new non-transferable Impact Certificate (SBT) to a recipient.
     *      Only callable by ADMIN_ROLE or via a successful DAO proposal.
     * @param _recipient The address to mint the certificate to.
     * @param _category The category of impact (e.g., "Code", "Community").
     * @param _score The numerical score of the impact (e.g., 1-100).
     * @param _metadataURI URI pointing to off-chain metadata (e.g., IPFS hash of a detailed report).
     */
    function mintImpactCertificate(address _recipient, string memory _category, uint256 _score, string memory _metadataURI)
        external onlyRole(ADMIN_ROLE) whenNotPaused
    {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_score == 0) revert InvalidScore();

        uint256 tokenId = _impactCertificateIds.current();
        _impactCertificateIds.increment();

        impactCertificates[tokenId] = ImpactCertificate({
            id: tokenId,
            recipient: _recipient,
            category: _category,
            score: _score,
            mintTime: block.timestamp,
            metadataURI: _metadataURI,
            revoked: false
        });

        holderImpactCertificates[_recipient].push(tokenId);

        emit ImpactCertificateMinted(tokenId, _recipient, _category, _score, _metadataURI);
    }

    /**
     * @dev Revokes an existing Impact Certificate. Only ARBITER_ROLE or via DAO proposal.
     *      A revoked certificate no longer contributes to impact score or voting power.
     * @param _tokenId The ID of the Impact Certificate to revoke.
     */
    function revokeImpactCertificate(uint256 _tokenId) external onlyRole(ARBITER_ROLE) whenNotPaused {
        ImpactCertificate storage cert = impactCertificates[_tokenId];
        if (cert.id == 0 || cert.recipient == address(0)) revert InvalidCertificateId();
        if (cert.revoked) revert CertificateAlreadyRevoked();

        cert.revoked = true;
        emit ImpactCertificateRevoked(_tokenId, _msgSender());
    }

    /**
     * @dev Retrieves the aggregate impact score for a specific account from all their valid Impact Certificates.
     * @param _account The address to query.
     * @return totalScore The sum of scores from all non-revoked certificates.
     */
    function getHolderImpactScore(address _account) public view returns (uint256 totalScore) {
        for (uint256 i = 0; i < holderImpactCertificates[_account].length; i++) {
            uint256 tokenId = holderImpactCertificates[_account][i];
            ImpactCertificate storage cert = impactCertificates[tokenId];
            if (!cert.revoked) {
                totalScore = totalScore.add(cert.score);
            }
        }
    }

    /**
     * @dev Calculates an account's dynamic voting power, influenced by their token stake and Impact Certificates.
     *      This is a conceptual calculation; actual weight formula can be more complex.
     * @param _account The address to query voting power for.
     * @return votePower The calculated voting power.
     */
    function getVotingPower(address _account) public view returns (uint256 votePower) {
        uint256 tokenBalance = governanceToken.balanceOf(_account);
        uint256 impactScore = getHolderImpactScore(_account);

        // Example formula: tokenBalance + (impactScore * scalingFactor)
        // This makes Impact Certificates directly boost voting power.
        // Scaling factor could be a DAO-configurable parameter. For simplicity, let's say 1 impact point = 1 token vote.
        uint256 impactVotingWeight = impactScore;

        votePower = tokenBalance.add(impactVotingWeight);
        return votePower;
    }

    /**
     * @dev Internal helper to calculate the total impact score of all *valid* certificates in the DAO.
     *      Used for quorum calculations relative to total DAO power.
     */
    function getDaoTotalImpactScore() internal view returns (uint256 totalImpact) {
        for (uint256 i = 1; i < _impactCertificateIds.current(); i++) {
            ImpactCertificate storage cert = impactCertificates[i];
            if (!cert.revoked && cert.recipient != address(0)) { // Ensure it's a valid, non-zero certificate
                totalImpact = totalImpact.add(cert.score);
            }
        }
        return totalImpact;
    }

    // --- IV. Retroactive Public Goods Funding ---

    /**
     * @dev Creates a specific type of proposal for retroactive funding of a project or contributor.
     *      This is a specialized `proposeExecution` that marks itself as a grant.
     * @param _projectCreator The address of the project or contributor to fund.
     * @param _amount The amount of treasuryToken to grant.
     * @param _descriptionURI URI to off-chain details about the project's impact.
     * @return proposalId The ID of the newly created retroactive grant proposal.
     */
    function proposeRetroactiveGrant(address _projectCreator, uint256 _amount, string memory _descriptionURI)
        external whenNotPaused returns (uint256 proposalId)
    {
        if (_projectCreator == address(0)) revert ZeroAddress();
        if (_amount == 0) revert InvalidAmount();
        if (getVotingPower(_msgSender()) < minVotePowerToPropose) revert NoVotingPower();
        if (governanceToken.balanceOf(_msgSender()) < minProposerStake) revert ProposerStakeRequired(minProposerStake);

        // Transfer proposer stake to the contract
        if (!governanceToken.transferFrom(_msgSender(), address(this), minProposerStake)) revert InsufficientBalance();

        proposalId = _proposalIds.current();
        _proposalIds.increment();

        // The target is the DAO itself, calling `distributeRetroactiveGrant`
        bytes memory callData = abi.encodeWithSelector(this.distributeRetroactiveGrant.selector, proposalId);

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: _msgSender(),
            proposerStake: minProposerStake,
            target: address(this),       // Target is ChronoForgeDAO itself
            value: _amount,              // The amount to be sent to the creator upon execution
            callData: callData,          // CallData to trigger distribution
            description: _descriptionURI,
            voteStartBlock: block.number,
            voteEndBlock: block.number.add(proposalVotingPeriod / 12),
            votesFor: 0,
            votesAgainst: 0,
            executionTime: block.timestamp.add(proposalVotingPeriod.add(60)), // Executable immediately after voting + small buffer
            conditionHash: bytes32(0),   // No condition for grants (usually)
            conditionProof: "",
            conditionProofSubmitted: false,
            conditionProofValid: false,
            state: ProposalState.ActiveVoting,
            quorumNumerator: minQuorumNumerator,
            totalVotingSupplyAtProposal: governanceToken.totalSupply().add(getDaoTotalImpactScore()),
            initialVotingPowerRequired: minVotePowerToPropose,
            isRetroactiveGrant: true // Mark as retroactive grant
        });

        emit RetroactiveGrantProposed(proposalId, _projectCreator, _amount);
        return proposalId;
    }

    /**
     * @dev A specialized `castVote` for retroactive grant proposals.
     * @param _grantProposalId The ID of the retroactive grant proposal.
     * @param _support True for 'for' vote, False for 'against' vote.
     */
    function castRetroactiveGrantVote(uint256 _grantProposalId, bool _support) external whenNotPaused {
        Proposal storage proposal = proposals[_grantProposalId];
        if (proposal.id == 0) revert InvalidProposalId();
        if (!proposal.isRetroactiveGrant) revert NotARetroactiveGrant();
        
        // Use the general castVote logic
        castVote(_grantProposalId, _support);
    }

    /**
     * @dev Distributes funds for an approved retroactive grant.
     *      This function is designed to be called *only* by the DAO itself via `executeProposal`.
     * @param _grantProposalId The ID of the retroactive grant proposal.
     */
    function distributeRetroactiveGrant(uint256 _grantProposalId) external whenNotPaused {
        // This function should only be callable by the contract itself via an executed proposal.
        // `_msgSender()` will be `address(this)` when called via an internal transaction from `executeProposal`.
        if (_msgSender() != address(this)) revert Unauthorized();

        Proposal storage proposal = proposals[_grantProposalId];
        if (proposal.id == 0 || !proposal.isRetroactiveGrant) revert InvalidProposalId();
        if (proposal.state != ProposalState.Executed) revert InvalidState(proposal.state, "Executed");

        // The recipient is the target of the proposal if this was a direct grant,
        // or derived from a parameter within the `callData` if it's more complex.
        // For simplicity, we assume `proposal.target` here refers to the actual recipient
        // when `isRetroactiveGrant` is true, and the `value` is the grant amount.
        // In a real scenario, this might need more robust parsing from `proposal.callData`.
        address recipient = proposal.target; // If target was set as recipient in proposeRetroactiveGrant
        uint256 amount = proposal.value;

        if (treasuryToken.balanceOf(address(this)) < amount) revert InsufficientBalance();
        if (!treasuryToken.transfer(recipient, amount)) revert TransferFailed();

        emit RetroactiveGrantDistributed(_grantProposalId, recipient, amount);
    }


    // --- V. Treasury Management ---

    /**
     * @dev Allows anyone to deposit treasuryToken into the DAO's treasury.
     * @param _amount The amount of treasuryToken to deposit.
     */
    function depositTreasury(uint256 _amount) external whenNotPaused {
        if (!treasuryToken.transferFrom(_msgSender(), address(this), _amount)) revert TransferFailed();
        emit TreasuryDeposited(_msgSender(), _amount);
    }

    /**
     * @dev Withdraws funds from the DAO treasury.
     *      This function can ONLY be called through a successful `executeProposal` (self-call).
     * @param _amount The amount of treasuryToken to withdraw.
     * @param _recipient The address to send the funds to.
     */
    function withdrawTreasuryFunds(uint256 _amount, address _recipient) external whenNotPaused {
        // This function must only be called via a successful DAO proposal execution.
        // This means _msgSender() should be this contract's address.
        if (_msgSender() != address(this)) revert Unauthorized();
        if (_recipient == address(0)) revert ZeroAddress();

        if (treasuryToken.balanceOf(address(this)) < _amount) revert InsufficientBalance();
        if (!treasuryToken.transfer(_recipient, _amount)) revert TransferFailed();

        emit TreasuryWithdrawn(_recipient, _amount);
    }

    // --- VI. Role Management & Configuration ---

    /**
     * @dev Grants a specified role to an account. Only ADMIN_ROLE can grant roles.
     * @param _role The role to grant (e.g., KEEPER_ROLE, ARBITER_ROLE).
     * @param _account The address to grant the role to.
     */
    function grantRole(bytes32 _role, address _account) external override onlyRole(ADMIN_ROLE) {
        _grantRole(_role, _account);
        emit RoleGranted(_role, _account, _msgSender());
    }

    /**
     * @dev Revokes a specified role from an account. Only ADMIN_ROLE can revoke roles.
     * @param _role The role to revoke.
     * @param _account The address to revoke the role from.
     */
    function revokeRole(bytes32 _role, address _account) external override onlyRole(ADMIN_ROLE) {
        _revokeRole(_role, _account);
        emit RoleRevoked(_role, _account, _msgSender());
    }

    /**
     * @dev Sets the bounty amount for Keepers executing proposals.
     *      Only ADMIN_ROLE can set this, or through a DAO proposal.
     * @param _newBounty The new bounty amount in native tokens.
     */
    function setExecutionBounty(uint255 _newBounty) external onlyRole(ADMIN_ROLE) whenNotPaused {
        executionBounty = _newBounty;
        emit ExecutionBountySet(_newBounty);
    }

    /**
     * @dev Updates core parameters for proposals.
     *      Only ADMIN_ROLE can update this, or through a DAO proposal.
     * @param _minProposerStake_ The new minimum stake for proposers.
     * @param _proposalVotingPeriod_ The new voting period duration in seconds.
     * @param _proposalExecutionGracePeriod_ The new grace period after executionTime.
     * @param _minQuorumNumerator_ The new minimum quorum numerator (e.g., 51 for 51%).
     * @param _minVotePowerToPropose_ The new minimum combined voting power to propose.
     */
    function updateProposalConfig(
        uint256 _minProposerStake_,
        uint256 _proposalVotingPeriod_,
        uint256 _proposalExecutionGracePeriod_,
        uint256 _minQuorumNumerator_,
        uint256 _minVotePowerToPropose_
    ) external onlyRole(ADMIN_ROLE) whenNotPaused {
        minProposerStake = _minProposerStake_;
        proposalVotingPeriod = _proposalVotingPeriod_;
        proposalExecutionGracePeriod = _proposalExecutionGracePeriod_;
        minQuorumNumerator = _minQuorumNumerator_;
        minVotePowerToPropose = _minVotePowerToPropose_;
        emit ProposalConfigUpdated(
            minProposerStake,
            proposalVotingPeriod,
            proposalExecutionGracePeriod,
            minQuorumNumerator,
            minVotePowerToPropose
        );
    }

    /**
     * @dev Pauses the contract in case of emergency. Only ADMIN_ROLE.
     */
    function pauseContract() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract. Only ADMIN_ROLE.
     */
    function unpauseContract() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Allows ADMIN_ROLE to rescue accidentally sent ERC20 tokens to the contract.
     *      Does NOT allow rescue of `governanceToken` or `treasuryToken` as those are intended for the DAO.
     * @param _tokenAddress The address of the ERC20 token to rescue.
     * @param _amount The amount of tokens to rescue.
     * @param _recipient The address to send the rescued tokens to.
     */
    function rescueERC20(address _tokenAddress, uint256 _amount, address _recipient) external onlyRole(ADMIN_ROLE) {
        if (_tokenAddress == address(governanceToken) || _tokenAddress == address(treasuryToken)) {
            revert TargetNotAllowed();
        }
        if (_recipient == address(0)) revert ZeroAddress();
        IERC20(_tokenAddress).transfer(_recipient, _amount);
    }

    // --- VII. External View Functions ---

    /**
     * @dev Returns the current state of a proposal.
     * @param _proposalId The ID of the proposal.
     * @return state The current ProposalState.
     */
    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) return ProposalState.Pending; // Or throw custom error InvalidProposalId

        // Dynamic state update for active proposals
        if (proposal.state == ProposalState.ActiveVoting && block.number > proposal.voteEndBlock) {
            // If voting period has ended, transition state.
            // This logic is duplicated from `queueProposalForExecution` for view consistency.
            uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
            uint256 requiredQuorum = proposal.totalVotingSupplyAtProposal.mul(proposal.quorumNumerator).div(100);

            if (totalVotes < requiredQuorum || proposal.votesFor <= proposal.votesAgainst) {
                return ProposalState.Failed;
            } else if (proposal.conditionHash != bytes32(0) && !proposal.conditionProofValid) {
                return ProposalState.Succeeded; // Needs condition proof
            } else {
                return ProposalState.Queued;
            }
        }
        if (proposal.state == ProposalState.Queued && block.timestamp > proposal.executionTime.add(proposalExecutionGracePeriod)) {
            return ProposalState.Expired;
        }

        return proposal.state;
    }

    /**
     * @dev Retrieves details of a specific Impact Certificate.
     * @param _tokenId The ID of the Impact Certificate.
     * @return cert The ImpactCertificate struct.
     */
    function getImpactCertificate(uint256 _tokenId) public view returns (ImpactCertificate memory) {
        return impactCertificates[_tokenId];
    }

    /**
     * @dev Returns the number of Impact Certificates held by an address (including revoked ones, check `revoked` flag).
     * @param _account The address to query.
     * @return count The number of certificates.
     */
    function getImpactCertificateBalance(address _account) public view returns (uint256 count) {
        return holderImpactCertificates[_account].length;
    }

    /**
     * @dev Returns the current minimum stake required for a proposal.
     */
    function getMinProposerStake() public view returns (uint256) {
        return minProposerStake;
    }

    // --- Fallback & Receive ---

    receive() external payable {}

    fallback() external payable {}

    // --- ERC721 Receiver (for potential future SBT transferability logic, not used here for non-transferable) ---
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        // This contract does not accept ERC721 transfers.
        // For a true SBT, it would reject transfers.
        // For ChronoForge's Impact Certificates, they are not standard ERC721s and are not transferable.
        revert TransferNotSupported();
    }

    // --- Internal/Private Helpers for AccessControl ---
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(ADMIN_ROLE) {}

    // --- Custom Errors (Defined here for compactness) ---
    error InvalidExecutionTime();
    error InvalidDelegatee();
    error VoteDelegated(address indexed delegator, address indexed delegatee, uint256 expiry);
    error VoteDelegationRevoked(address indexed delegator);
    error NoConditionRequired();
    error InvalidCertificateId();
    error InvalidAmount();
    error TransferFailed();
    error NotARetroactiveGrant();
    error TransferNotSupported();
}
```