Here's a smart contract written in Solidity, `SynthetIQ_DAO_V1`, designed around the concepts of dynamic reputation, adaptive governance, and a simulated "AI Oracle" for on-chain recommendations. It aims to be creative, advanced, and trendy by integrating several cutting-edge ideas into a single, cohesive system.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For explicit intent, though Solidity 0.8+ has built-in safety.

/**
 * @title SynthetIQ_DAO_V1 - The Adaptive Governance Protocol
 * @dev This contract implements a Decentralized Autonomous Organization (DAO) with advanced features:
 *      - Dynamic "IQ Score" (non-transferable, SBT-like) for reputation, influencing voting power and privileges.
 *      - Adaptive Governance: Core DAO parameters (voting period, quorum, min IQ for proposals) can be adjusted via governance.
 *      - Simulated "AI Oracle": An on-chain module that processes DAO metrics and generates parameter recommendations,
 *        which are then voted on. Its internal weights are also governable.
 *      - Verifiable Claims & Attestations: Members can register claims that high-IQ members can attest to,
 *        further influencing IQ scores.
 *      - Strategic Treasury Management: DAO can propose and execute investments of its treasury funds.
 *      - Emergency Circuit Breaker: A multi-signature-like `emergencyCouncil` can pause critical operations.
 *
 * @outline
 * 1.  Core Structures:
 *     - `Proposal`: Defines the parameters of a governance proposal.
 *     - `Attestation`: Details for a user's claim and its attestations.
 *     - `GovernanceParameters`: Dynamic parameters controlling DAO behavior (voting, quorum, etc.).
 *     - `AIOracleConfig`: Weights and thresholds for the simulated AI Oracle's recommendation logic.
 *     - `ProposalState`: Enum for proposal lifecycle.
 *
 * 2.  State Variables:
 *     - `iqScores`: Non-transferable "IQ Score" for each member (SBT-like).
 *     - `proposals`: Mapping of proposal IDs to their details.
 *     - `attestations`: Mapping of claim hashes to attestation data.
 *     - `treasuryTokens`: Tracks ERC20 token balances held by the DAO.
 *     - `governanceParams`: Current active governance rules.
 *     - `aiOracleConfig`: Current configuration for the simulated AI's logic.
 *     - `emergencyCouncil`: Addresses with power to pause/unpause critical functions.
 *     - `delegatedVotes`: Mapping for vote delegation.
 *     - `isPaused`: Emergency circuit breaker status.
 *
 * 3.  Events:
 *     - To log all significant actions (proposal creation, votes, IQ changes, treasury movements).
 *
 * 4.  Modifiers:
 *     - `onlyInitialized`: Ensures contract is fully set up.
 *     - `minIQRequired`: Restricts function access based on minimum IQ.
 *     - `onlyEmergencyCouncil`: Restricts function access to emergency council members.
 *     - `whenNotPaused` / `whenPaused`: For pause functionality.
 *
 * 5.  Custom Errors:
 *     - For clearer, gas-efficient error reporting.
 *
 * 6.  Functions (26 total, categorized):
 *     A. Setup & Initialization (2 functions):
 *        1. `constructor()`: Initializes the contract with deployer as a temporary owner.
 *        2. `initializeDAO(...)`: Completes DAO setup, transfers ownership to the DAO itself (via a proposal or self-ownership).
 *     B. IQ Management & Attestations (4 functions):
 *        3. `getIQScore(address _user)`: Retrieves a user's current IQ score.
 *        4. `registerClaim(bytes32 _claimHash, string calldata _claimURI)`: Allows users to register a verifiable claim for attestation.
 *        5. `attestClaim(address _targetUser, bytes32 _claimHash, bool _positiveAttestation)`: High-IQ members attest to a claim, impacting target's IQ.
 *        6. `getClaimStatus(bytes32 _claimHash)`: Returns the aggregate attestation status for a registered claim.
 *     C. Governance & Voting (6 functions):
 *        7. `submitProposal(...)`: Creates a new governance proposal (requires minimum IQ).
 *        8. `voteOnProposal(...)`: Casts a vote on an active proposal (IQ-weighted).
 *        9. `executeProposal(...)`: Executes a passed proposal.
 *        10. `getProposalDetails(...)`: Reads full details of a proposal.
 *        11. `delegateVote(address _delegatee)`: Delegates voting power to another address.
 *        12. `revokeVoteDelegation()`: Revokes any active vote delegation.
 *     D. Adaptive Governance & AI Oracle Integration (4 functions):
 *        13. `proposeGovernanceParameterUpdate(...)`: Submits a proposal to change core DAO rules.
 *        14. `proposeAIOracleConfigUpdate(...)`: Proposes changes to the simulated AI Oracle's decision-making weights.
 *        15. `_simulateAIRecommendation()`: Internal function for the AI Oracle to generate a parameter recommendation proposal.
 *        16. `acceptAIRecommendation(...)`: Special vote to accept an AI-generated recommendation.
 *     E. Treasury Management (2 functions):
 *        17. `depositToTreasury(...)`: Allows external entities to deposit funds into the DAO treasury.
 *        18. `proposeTreasuryInvestment(...)`: Submits a proposal for the DAO to invest treasury funds.
 *     F. Emergency & Security (4 functions):
 *        19. `emergencyPause()`: Pauses critical DAO functionalities (Emergency Council).
 *        20. `emergencyUnpause()`: Unpauses critical DAO functionalities (Emergency Council).
 *        21. `addEmergencyCouncilMember(...)`: Adds a member to the Emergency Council (via proposal).
 *        22. `removeEmergencyCouncilMember(...)`: Removes a member from the Emergency Council (via proposal).
 *     G. Rewards & Penalties (2 functions):
 *        23. `awardContribution(...)`: Rewards a contributor with IQ boost and/or tokens (via proposal).
 *        24. `penalizeMaliciousActivity(...)`: Penalizes an actor by reducing IQ (via proposal).
 *     H. Read-Only / Information (2 functions):
 *        25. `getGovernanceParameters()`: Returns current governance parameters.
 *        26. `getAIOracleConfig()`: Returns current AI Oracle configuration.
 *
 * @functionSummary
 * - `constructor()`: Deploys the contract, setting the deployer as temporary owner (for `initializeDAO`).
 * - `initializeDAO(...)`: Finalizes DAO setup, assigning initial `admin` with `initialIQ`, and transferring `Ownable` ownership to the zero address (effectively making the DAO self-governing).
 * - `getIQScore(...)`: Returns a user's non-transferable IQ score, reflecting their reputation within the DAO.
 * - `registerClaim(...)`: Allows a user to create a unique hash for an off-chain claim (e.g., "I completed X task"), making it available for attestation by others.
 * - `attestClaim(...)`: Enables high-IQ members to positively or negatively attest to a registered claim, which directly influences the claimant's IQ score.
 * - `getClaimStatus(...)`: Provides the current aggregated attestation state (positive and negative counts) for a specific registered claim.
 * - `submitProposal(...)`: Initiates a new governance proposal for on-chain execution, requiring a minimum IQ score from the proposer.
 * - `voteOnProposal(...)`: Allows eligible members to vote on active proposals, with their vote weight directly proportional to their IQ score.
 * - `executeProposal(...)`: Executes the target function of a proposal that has successfully passed its voting period and met quorum.
 * - `getProposalDetails(...)`: Retrieves all structural details of a specific governance proposal.
 * - `delegateVote(...)`: Allows a user to assign their IQ-weighted voting power to another address, enhancing collective decision-making.
 * - `revokeVoteDelegation()`: Cancels any existing vote delegation, restoring direct voting power to the caller.
 * - `proposeGovernanceParameterUpdate(...)`: Submits a proposal to dynamically adjust core DAO governance rules (e.g., voting period, quorum, minimum IQ for proposals).
 * - `proposeAIOracleConfigUpdate(...)`: Submits a proposal to modify the weights and thresholds used by the simulated AI Oracle for its recommendation logic.
 * - `_simulateAIRecommendation()`: An internal function (intended to be called by a high-IQ member or a timed oracle) that processes DAO metrics (e.g., treasury growth, proposal success rates) to generate a new parameter adjustment proposal based on the current `AIOracleConfig`.
 * - `acceptAIRecommendation(...)`: A specific voting mechanism for DAO members to approve or reject a parameter adjustment proposal that was generated by the `_simulateAIRecommendation` function.
 * - `depositToTreasury(...)`: Facilitates the transfer of ERC20 tokens into the DAO's collective treasury from external sources.
 * - `proposeTreasuryInvestment(...)`: Submits a proposal for the DAO to invest a portion of its treasury into a specified external strategy contract, detailing the investment parameters.
 * - `emergencyPause()`: A critical security function, callable by a super-majority of the `emergencyCouncil`, to temporarily halt all sensitive DAO operations in case of an exploit or severe vulnerability.
 * - `emergencyUnpause()`: Reverses the `emergencyPause` state, also requiring a super-majority vote from the `emergencyCouncil` to reactivate DAO functions.
 * - `addEmergencyCouncilMember(...)`: A governance proposal that, if passed, includes a new address in the `emergencyCouncil`, enhancing emergency response capabilities.
 * - `removeEmergencyCouncilMember(...)`: A governance proposal that, if passed, removes an address from the `emergencyCouncil`.
 * - `awardContribution(...)`: A governance proposal to reward a member with an IQ boost and/or ERC20 tokens for valuable contributions to the DAO.
 * - `penalizeMaliciousActivity(...)`: A governance proposal to reduce the IQ score of an actor identified as malicious or harmful to the DAO.
 * - `getGovernanceParameters()`: Provides the current, actively used governance parameters of the DAO.
 * - `getAIOracleConfig()`: Provides the current configuration weights and thresholds for the simulated AI Oracle's recommendation logic.
 */
contract SynthetIQ_DAO_V1 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Custom Errors ---
    error NotInitialized();
    error AlreadyInitialized();
    error MinIQNotMet(address user, uint256 requiredIQ, uint256 currentIQ);
    error ProposalNotFound(uint256 proposalId);
    error ProposalNotExecutable(uint256 proposalId);
    error ProposalNotOpen(uint256 proposalId);
    error ProposalAlreadyVoted(uint256 proposalId, address voter);
    error ZeroVotesDelegated();
    error SelfDelegationNotAllowed();
    error InvalidAttestationTarget();
    error ClaimAlreadyRegistered(bytes32 claimHash);
    error ClaimNotFound(bytes32 claimHash);
    error AttestationAlreadyMade(bytes32 claimHash, address attester);
    error InvalidAIRecommendationTarget();
    error InsufficientEmergencyCouncilVote();
    error ZeroAddressNotAllowed();
    error TreasuryTransferFailed(address token, uint256 amount);

    // --- Enums ---
    enum ProposalState {
        Pending,   // Proposal has been submitted
        Active,    // Voting is ongoing
        Succeeded, // Voting ended, passed quorum & threshold
        Failed,    // Voting ended, did not pass
        Executed,  // Proposal was executed
        Defeated   // Proposal was canceled or superseded
    }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        address target;       // Contract to call
        bytes callData;       // Data for the call
        uint256 value;        // ETH value to send with the call
        uint256 startBlock;
        uint256 endBlock;
        uint256 ForVotes;
        uint256 AgainstVotes;
        bool executed;
        ProposalState state;
        mapping(address => bool) hasVoted; // Tracks who has voted
        mapping(address => bool) isAIRecommendation; // Is this proposal an AI recommendation?
    }

    struct Attestation {
        address claimant;
        string uri; // URI to off-chain claim details
        uint256 positiveCount;
        uint256 negativeCount;
        mapping(address => bool) hasAttested; // attester => did_attest_this_claim
        mapping(address => bool) isPositiveAttestation; // attester => was_positive
    }

    struct GovernanceParameters {
        uint256 votingPeriodBlocks;     // How many blocks a proposal is open for voting
        uint256 quorumPercentage;       // Percentage of total IQ supply needed for a proposal to pass
        uint256 minIQForProposal;       // Minimum IQ score required to submit a proposal
        uint256 minIQForAttestation;    // Minimum IQ score required to attest to a claim
        uint256 attestationIQBoost;     // IQ boost for successful positive attestations
        uint256 attestationIQPunish;    // IQ penalty for negative attestations
        uint256 proposalPassThreshold;  // Percentage of (ForVotes / TotalVotes) needed to pass
    }

    // This simulates an "AI Oracle" logic. It's a deterministic algorithm on-chain
    // whose parameters (weights) are governable.
    struct AIOracleConfig {
        uint256 performanceWeight;  // Weight given to DAO's overall performance (e.g., treasury growth)
        uint256 riskWeight;         // Weight given to current risk indicators (e.g., volatile asset holdings)
        uint256 innovationWeight;   // Weight given to new successful proposals or initiatives
        uint256 recommendationFactor; // Factor to apply to calculated recommendation for parameter change
    }

    // --- State Variables ---
    bool public initialized;
    bool public isPaused;

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public iqScores; // Non-transferable IQ score (SBT-like)
    uint256 public totalIQSupply; // Sum of all IQ scores, used for quorum calculation

    mapping(bytes32 => Attestation) public attestations; // claimHash => Attestation
    mapping(address => address) public delegatedVotes; // delegator => delegatee

    GovernanceParameters public governanceParams;
    AIOracleConfig public aiOracleConfig;

    mapping(address => bool) public emergencyCouncil;
    uint256 public emergencyCouncilCount; // Cache count for efficiency

    // --- Events ---
    event DAOInitialized(address indexed initialAdmin, uint256 initialIQ);
    event IQScoreChanged(address indexed user, uint256 oldIQ, uint256 newIQ, string reason);
    event ClaimRegistered(address indexed claimant, bytes32 indexed claimHash, string claimURI);
    event ClaimAttested(address indexed attester, address indexed claimant, bytes32 indexed claimHash, bool positive, uint256 newIQ);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, address target, uint256 value, uint256 startBlock, uint256 endBlock);
    event VoteCast(uint256 indexed proposalId, address indexed voter, uint256 iqWeight, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event VoteDelegated(address indexed delegator, address indexed delegatee);
    event VoteDelegationRevoked(address indexed delegator);
    event GovernanceParametersUpdated(GovernanceParameters newParams);
    event AIOracleConfigUpdated(AIOracleConfig newConfig);
    event AIRecommendationGenerated(uint256 indexed proposalId, string description);
    event TreasuryDeposit(address indexed token, address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed token, address indexed recipient, uint256 amount);
    event EmergencyPause(address indexed pauser);
    event EmergencyUnpause(address indexed unpauser);
    event EmergencyCouncilMemberAdded(address indexed member);
    event EmergencyCouncilMemberRemoved(address indexed member);
    event ContributorAwarded(address indexed contributor, uint256 iqBoost, uint256 tokenRewardAmount, address rewardToken);
    event MaliciousActorPenalized(address indexed actor, uint256 iqPenalty);

    // --- Modifiers ---
    modifier onlyInitialized() {
        if (!initialized) revert NotInitialized();
        _;
    }

    modifier minIQRequired(uint256 _requiredIQ) {
        if (iqScores[_msgSender()] < _requiredIQ) {
            revert MinIQNotMet(_msgSender(), _requiredIQ, iqScores[_msgSender()]);
        }
        _;
    }

    modifier onlyEmergencyCouncil() {
        if (!emergencyCouncil[_msgSender()]) {
            revert OwnableUnauthorizedAccount(_msgSender()); // Re-using Ownable's error for consistency
        }
        _;
    }

    modifier whenNotPaused() {
        if (isPaused) revert Ownable2StepInitialOwnerZeroAddress(); // Re-using for pause state
        _;
    }

    modifier whenPaused() {
        if (!isPaused) revert OwnableUnauthorizedAccount(_msgSender()); // Re-using for pause state
        _;
    }

    // --- Constructor ---
    constructor() Ownable(msg.sender) {
        // Owner is initially deployer. initializeDAO will transfer ownership to address(0) for self-governance.
        nextProposalId = 1;
        isPaused = false;
        // Set initial dummy governance parameters. These MUST be updated via initializeDAO.
        governanceParams = GovernanceParameters({
            votingPeriodBlocks: 0,
            quorumPercentage: 0,
            minIQForProposal: 0,
            minIQForAttestation: 0,
            attestationIQBoost: 0,
            attestationIQPunish: 0,
            proposalPassThreshold: 0
        });
        // Set initial dummy AI Oracle config. These MUST be updated via initializeDAO.
        aiOracleConfig = AIOracleConfig({
            performanceWeight: 0,
            riskWeight: 0,
            innovationWeight: 0,
            recommendationFactor: 0
        });
    }

    // --- A. Setup & Initialization ---

    /**
     * @dev Initializes the DAO, sets up initial parameters, and grants the first admin IQ.
     *      Crucially, this function transfers the `Ownable` ownership to address(0),
     *      making the DAO self-governing.
     *      Can only be called once by the contract deployer (initial Ownable owner).
     * @param _initialAdmin The address of the first DAO administrator.
     * @param _initialIQ The starting IQ score for the initial administrator.
     * @param _votingPeriodBlocks Number of blocks for a proposal to be active.
     * @param _quorumPercentage Percentage of total IQ supply needed for a proposal to pass (e.g., 40 for 40%).
     * @param _minIQForProposal Minimum IQ required to submit a proposal.
     * @param _minIQForAttestation Minimum IQ required to attest to a claim.
     * @param _attestationIQBoost IQ points gained for successful positive attestation.
     * @param _attestationIQPunish IQ points lost for negative attestation / failed dispute.
     * @param _proposalPassThreshold Percentage of 'For' votes out of total votes (e.g., 51 for 51%).
     * @param _aiPerformanceWeight Initial weight for AI's performance metric.
     * @param _aiRiskWeight Initial weight for AI's risk metric.
     * @param _aiInnovationWeight Initial weight for AI's innovation metric.
     * @param _aiRecommendationFactor Factor to scale AI's parameter recommendations.
     */
    function initializeDAO(
        address _initialAdmin,
        uint256 _initialIQ,
        uint256 _votingPeriodBlocks,
        uint256 _quorumPercentage,
        uint256 _minIQForProposal,
        uint256 _minIQForAttestation,
        uint256 _attestationIQBoost,
        uint256 _attestationIQPunish,
        uint256 _proposalPassThreshold,
        uint256 _aiPerformanceWeight,
        uint256 _aiRiskWeight,
        uint256 _aiInnovationWeight,
        uint256 _aiRecommendationFactor
    ) external onlyOwner {
        if (initialized) revert AlreadyInitialized();
        if (_initialAdmin == address(0)) revert ZeroAddressNotAllowed();
        if (_initialIQ == 0) revert MinIQNotMet(_initialAdmin, 1, 0); // IQ must be positive
        if (_quorumPercentage > 100 || _proposalPassThreshold > 100) revert InvalidAIRecommendationTarget(); // Reusing error
        if (_aiPerformanceWeight.add(_aiRiskWeight).add(_aiInnovationWeight) == 0) revert InvalidAIRecommendationTarget(); // At least one AI weight must be non-zero

        initialized = true;

        // Set initial governance parameters
        governanceParams = GovernanceParameters({
            votingPeriodBlocks: _votingPeriodBlocks,
            quorumPercentage: _quorumPercentage,
            minIQForProposal: _minIQForProposal,
            minIQForAttestation: _minIQForAttestation,
            attestationIQBoost: _attestationIQBoost,
            attestationIQPunish: _attestationIQPunish,
            proposalPassThreshold: _proposalPassThreshold
        });

        // Set initial AI Oracle config
        aiOracleConfig = AIOracleConfig({
            performanceWeight: _aiPerformanceWeight,
            riskWeight: _aiRiskWeight,
            innovationWeight: _aiInnovationWeight,
            recommendationFactor: _aiRecommendationFactor
        });

        // Grant initial IQ to admin
        _adjustIQScore(_initialAdmin, _initialIQ, "Initial DAO admin");

        // Add initial admin to emergency council by default
        emergencyCouncil[_initialAdmin] = true;
        emergencyCouncilCount = 1;

        emit DAOInitialized(_initialAdmin, _initialIQ);
        emit GovernanceParametersUpdated(governanceParams);
        emit AIOracleConfigUpdated(aiOracleConfig);
        emit EmergencyCouncilMemberAdded(_initialAdmin);

        // Transfer Ownable ownership to address(0) for self-governance.
        // All subsequent changes must go through the DAO's proposal system.
        // This is a common pattern for "renouncing ownership" to a DAO.
        _transferOwnership(address(0));
    }

    // --- B. IQ Management & Attestations ---

    /**
     * @dev Internal function to adjust a user's IQ score.
     * @param _user The address whose IQ score is being adjusted.
     * @param _amount The amount to add or subtract.
     * @param _reason The reason for the IQ adjustment.
     * @param _isAddition True if adding, false if subtracting.
     */
    function _adjustIQScore(address _user, uint256 _amount, string memory _reason, bool _isAddition) internal {
        uint256 oldIQ = iqScores[_user];
        uint256 newIQ;

        if (_isAddition) {
            newIQ = oldIQ.add(_amount);
            totalIQSupply = totalIQSupply.add(_amount);
        } else {
            if (oldIQ < _amount) { // Prevent underflow if score goes below zero
                newIQ = 0;
                totalIQSupply = totalIQSupply.sub(oldIQ);
            } else {
                newIQ = oldIQ.sub(_amount);
                totalIQSupply = totalIQSupply.sub(_amount);
            }
        }
        iqScores[_user] = newIQ;
        emit IQScoreChanged(_user, oldIQ, newIQ, _reason);
    }

    /**
     * @dev Retrieves the current IQ score of a specific user.
     * @param _user The address to query.
     * @return The IQ score of the user.
     */
    function getIQScore(address _user) external view returns (uint256) {
        return iqScores[_user];
    }

    /**
     * @dev Allows a user to register a hash of an off-chain claim, making it available for attestation.
     *      The `_claimURI` points to details of the claim (e.g., IPFS hash, URL).
     * @param _claimHash A unique hash identifying the claim (e.g., `keccak256("I built this feature")`).
     * @param _claimURI URI pointing to the full details of the claim (e.g., IPFS CID).
     */
    function registerClaim(bytes32 _claimHash, string calldata _claimURI) external onlyInitialized whenNotPaused minIQRequired(governanceParams.minIQForProposal) {
        if (attestations[_claimHash].claimant != address(0)) {
            revert ClaimAlreadyRegistered(_claimHash);
        }
        attestations[_claimHash].claimant = _msgSender();
        attestations[_claimHash].uri = _claimURI;
        emit ClaimRegistered(_msgSender(), _claimHash, _claimURI);
    }

    /**
     * @dev High-IQ members can attest to a claim, positively or negatively.
     *      This impacts the target user's IQ score. An attester cannot attest to their own claim.
     * @param _targetUser The user whose claim is being attested.
     * @param _claimHash The hash of the claim being attested.
     * @param _positiveAttestation True for a positive attestation, false for negative.
     */
    function attestClaim(address _targetUser, bytes32 _claimHash, bool _positiveAttestation)
        external
        onlyInitialized
        whenNotPaused
        minIQRequired(governanceParams.minIQForAttestation)
    {
        if (_targetUser == address(0)) revert InvalidAttestationTarget();
        if (_targetUser == _msgSender()) revert InvalidAttestationTarget(); // Cannot attest your own claim

        Attestation storage claim = attestations[_claimHash];
        if (claim.claimant == address(0)) revert ClaimNotFound(_claimHash);
        if (claim.hasAttested[_msgSender()]) revert AttestationAlreadyMade(_claimHash, _msgSender());

        claim.hasAttested[_msgSender()] = true;
        claim.isPositiveAttestation[_msgSender()] = _positiveAttestation;

        if (_positiveAttestation) {
            claim.positiveCount = claim.positiveCount.add(1);
            _adjustIQScore(_targetUser, governanceParams.attestationIQBoost, "Positive claim attestation", true);
        } else {
            claim.negativeCount = claim.negativeCount.add(1);
            _adjustIQScore(_targetUser, governanceParams.attestationIQPunish, "Negative claim attestation", false);
        }

        emit ClaimAttested(_msgSender(), _targetUser, _claimHash, _positiveAttestation, iqScores[_targetUser]);
    }

    /**
     * @dev Returns the aggregate attestation status for a registered claim.
     * @param _claimHash The hash of the claim to query.
     * @return claimant The address who registered the claim.
     * @return uri The URI pointing to the off-chain claim details.
     * @return positiveCount The number of positive attestations.
     * @return negativeCount The number of negative attestations.
     */
    function getClaimStatus(bytes32 _claimHash)
        external
        view
        onlyInitialized
        returns (address claimant, string memory uri, uint256 positiveCount, uint256 negativeCount)
    {
        Attestation storage claim = attestations[_claimHash];
        if (claim.claimant == address(0)) revert ClaimNotFound(_claimHash);
        return (claim.claimant, claim.uri, claim.positiveCount, claim.negativeCount);
    }

    // --- C. Governance & Voting ---

    /**
     * @dev Submits a new governance proposal.
     * @param _description A detailed description of the proposal.
     * @param _target The address of the contract to call if the proposal passes.
     * @param _callData The encoded function call data for `_target`.
     * @param _value The amount of native token (ETH) to send with the call.
     * @return The ID of the newly created proposal.
     */
    function submitProposal(string calldata _description, address _target, bytes calldata _callData, uint256 _value)
        external
        onlyInitialized
        whenNotPaused
        minIQRequired(governanceParams.minIQForProposal)
        returns (uint256)
    {
        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.description = _description;
        newProposal.proposer = _msgSender();
        newProposal.target = _target;
        newProposal.callData = _callData;
        newProposal.value = _value;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(governanceParams.votingPeriodBlocks);
        newProposal.state = ProposalState.Active;

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            _description,
            _target,
            _value,
            newProposal.startBlock,
            newProposal.endBlock
        );
        return proposalId;
    }

    /**
     * @dev Casts a vote on an active proposal. Voting power is proportional to IQ.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True for 'For', false for 'Against'.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyInitialized whenNotPaused {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (proposal.state != ProposalState.Active) revert ProposalNotOpen(_proposalId);
        if (block.number > proposal.endBlock) revert ProposalNotOpen(_proposalId);

        address voter = _msgSender();
        // Resolve delegated votes
        address effectiveVoter = delegatedVotes[voter] != address(0) ? delegatedVotes[voter] : voter;
        if (proposal.hasVoted[effectiveVoter]) revert ProposalAlreadyVoted(_proposalId, effectiveVoter);

        uint256 voterIQ = iqScores[effectiveVoter];
        if (voterIQ == 0) revert MinIQNotMet(effectiveVoter, 1, 0); // Must have some IQ to vote

        proposal.hasVoted[effectiveVoter] = true;
        if (_support) {
            proposal.ForVotes = proposal.ForVotes.add(voterIQ);
        } else {
            proposal.AgainstVotes = proposal.AgainstVotes.add(voterIQ);
        }

        emit VoteCast(_proposalId, effectiveVoter, voterIQ, _support);
    }

    /**
     * @dev Executes a passed proposal.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeProposal(uint256 _proposalId) external payable onlyInitialized whenNotPaused nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyVoted(_proposalId, address(0)); // Re-using error for already executed
        if (proposal.state == ProposalState.Failed || proposal.state == ProposalState.Defeated) revert ProposalNotExecutable(_proposalId);
        if (block.number <= proposal.endBlock) revert ProposalNotExecutable(_proposalId); // Voting period must be over

        _updateProposalState(_proposalId); // Ensure state is up-to-date

        if (proposal.state != ProposalState.Succeeded) revert ProposalNotExecutable(_proposalId);

        // Execute the proposal's call
        (bool success, ) = proposal.target.call{value: proposal.value}(proposal.callData);
        if (!success) {
            // If execution fails, mark as defeated (though passed voting)
            proposal.state = ProposalState.Defeated;
            emit ProposalStateChanged(_proposalId, ProposalState.Defeated);
            revert ProposalNotExecutable(_proposalId);
        }

        proposal.executed = true;
        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(_proposalId);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    /**
     * @dev Internal function to update a proposal's state based on current conditions.
     * @param _proposalId The ID of the proposal.
     */
    function _updateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Executed || proposal.state == ProposalState.Defeated) {
            return; // No need to update if already final
        }

        if (block.number <= proposal.endBlock) {
            if (proposal.state != ProposalState.Active) {
                proposal.state = ProposalState.Active; // Should be active if voting period not over
                emit ProposalStateChanged(_proposalId, ProposalState.Active);
            }
            return;
        }

        // Voting period is over. Determine outcome.
        uint256 totalVotes = proposal.ForVotes.add(proposal.AgainstVotes);

        // Check quorum: total votes must meet a percentage of total IQ supply
        bool quorumMet = totalVotes.mul(100) >= totalIQSupply.mul(governanceParams.quorumPercentage);

        // Check pass threshold: 'For' votes must exceed a percentage of total votes
        bool thresholdMet = proposal.ForVotes.mul(100) >= totalVotes.mul(governanceParams.proposalPassThreshold);

        if (quorumMet && thresholdMet) {
            proposal.state = ProposalState.Succeeded;
            emit ProposalStateChanged(_proposalId, ProposalState.Succeeded);
        } else {
            proposal.state = ProposalState.Failed;
            emit ProposalStateChanged(_proposalId, ProposalState.Failed);
        }
    }

    /**
     * @dev Retrieves all details of a specific proposal.
     * @param _proposalId The ID of the proposal.
     * @return A tuple containing all proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        external
        view
        onlyInitialized
        returns (
            uint256 id,
            string memory description,
            address proposer,
            address target,
            bytes memory callData,
            uint256 value,
            uint256 startBlock,
            uint256 endBlock,
            uint256 ForVotes,
            uint256 AgainstVotes,
            bool executed,
            ProposalState state
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.id == 0) revert ProposalNotFound(_proposalId);

        return (
            proposal.id,
            proposal.description,
            proposal.proposer,
            proposal.target,
            proposal.callData,
            proposal.value,
            proposal.startBlock,
            proposal.endBlock,
            proposal.ForVotes,
            proposal.AgainstVotes,
            proposal.executed,
            proposal.state
        );
    }

    /**
     * @dev Allows a user to delegate their IQ-weighted voting power to another address.
     * @param _delegatee The address to delegate votes to.
     */
    function delegateVote(address _delegatee) external onlyInitialized whenNotPaused {
        if (_delegatee == address(0)) revert ZeroAddressNotAllowed();
        if (_delegatee == _msgSender()) revert SelfDelegationNotAllowed();
        if (iqScores[_msgSender()] == 0) revert ZeroVotesDelegated();

        delegatedVotes[_msgSender()] = _delegatee;
        emit VoteDelegated(_msgSender(), _delegatee);
    }

    /**
     * @dev Revokes any active vote delegation, restoring direct voting power to the caller.
     */
    function revokeVoteDelegation() external onlyInitialized whenNotPaused {
        if (delegatedVotes[_msgSender()] == address(0)) revert ZeroVotesDelegated();
        delete delegatedVotes[_msgSender()];
        emit VoteDelegationRevoked(_msgSender());
    }

    // --- D. Adaptive Governance & AI Oracle Integration ---

    /**
     * @dev Submits a proposal to change the core DAO governance parameters.
     *      Requires a standard governance vote to pass.
     * @param _newVotingPeriodBlocks The new number of blocks for proposal voting.
     * @param _newQuorumPercentage The new percentage of total IQ supply needed for quorum.
     * @param _newMinIQForProposal The new minimum IQ required to submit proposals.
     * @param _newMinIQForAttestation The new minimum IQ required to attest.
     * @param _newAttestationIQBoost The new IQ boost amount for positive attestations.
     * @param _newAttestationIQPunish The new IQ penalty amount for negative attestations.
     * @param _newProposalPassThreshold The new percentage of 'For' votes needed to pass.
     */
    function proposeGovernanceParameterUpdate(
        uint256 _newVotingPeriodBlocks,
        uint256 _newQuorumPercentage,
        uint256 _newMinIQForProposal,
        uint256 _newMinIQForAttestation,
        uint256 _newAttestationIQBoost,
        uint256 _newAttestationIQPunish,
        uint256 _newProposalPassThreshold
    ) external onlyInitialized whenNotPaused minIQRequired(governanceParams.minIQForProposal) {
        if (_newQuorumPercentage > 100 || _newProposalPassThreshold > 100) revert InvalidAIRecommendationTarget(); // Reusing error
        // Encode the function call to updateGovernanceParameters for the proposal
        bytes memory callData = abi.encodeWithSelector(
            this.updateGovernanceParameters.selector,
            _newVotingPeriodBlocks,
            _newQuorumPercentage,
            _newMinIQForProposal,
            _newMinIQForAttestation,
            _newAttestationIQBoost,
            _newAttestationIQPunish,
            _newProposalPassThreshold
        );
        submitProposal(
            "Update DAO Governance Parameters",
            address(this),
            callData,
            0
        );
    }

    /**
     * @dev Internal function to update governance parameters. Callable only by a successful proposal.
     * @param _newVotingPeriodBlocks The new number of blocks for proposal voting.
     * @param _newQuorumPercentage The new percentage of total IQ supply needed for quorum.
     * @param _newMinIQForProposal The new minimum IQ required to submit proposals.
     * @param _newMinIQForAttestation The new minimum IQ required to attest.
     * @param _newAttestationIQBoost The new IQ boost amount for positive attestations.
     * @param _newAttestationIQPunish The new IQ penalty amount for negative attestations.
     * @param _newProposalPassThreshold The new percentage of 'For' votes needed to pass.
     */
    function updateGovernanceParameters(
        uint256 _newVotingPeriodBlocks,
        uint256 _newQuorumPercentage,
        uint256 _newMinIQForProposal,
        uint256 _newMinIQForAttestation,
        uint256 _newAttestationIQBoost,
        uint256 _newAttestationIQPunish,
        uint256 _newProposalPassThreshold
    ) internal onlyInitialized { // Only callable via internal mechanism (e.g., proposal execution)
        governanceParams = GovernanceParameters({
            votingPeriodBlocks: _newVotingPeriodBlocks,
            quorumPercentage: _newQuorumPercentage,
            minIQForProposal: _newMinIQForProposal,
            minIQForAttestation: _newMinIQForAttestation,
            attestationIQBoost: _newAttestationIQBoost,
            attestationIQPunish: _newAttestationIQPunish,
            proposalPassThreshold: _newProposalPassThreshold
        });
        emit GovernanceParametersUpdated(governanceParams);
    }


    /**
     * @dev Submits a proposal to change the configuration weights of the simulated AI Oracle.
     *      Requires a standard governance vote to pass.
     * @param _newPerformanceWeight New weight for DAO's overall performance metric.
     * @param _newRiskWeight New weight for current risk indicators.
     * @param _newInnovationWeight New weight for new successful proposals/initiatives.
     * @param _newRecommendationFactor New factor to scale AI's parameter recommendations.
     */
    function proposeAIOracleConfigUpdate(
        uint256 _newPerformanceWeight,
        uint256 _newRiskWeight,
        uint256 _newInnovationWeight,
        uint256 _newRecommendationFactor
    ) external onlyInitialized whenNotPaused minIQRequired(governanceParams.minIQForProposal) {
        if (_newPerformanceWeight.add(_newRiskWeight).add(_newInnovationWeight) == 0) revert InvalidAIRecommendationTarget(); // Reusing error
        // Encode the function call to updateAIOracleConfig for the proposal
        bytes memory callData = abi.encodeWithSelector(
            this.updateAIOracleConfig.selector,
            _newPerformanceWeight,
            _newRiskWeight,
            _newInnovationWeight,
            _newRecommendationFactor
        );
        submitProposal(
            "Update AI Oracle Configuration",
            address(this),
            callData,
            0
        );
    }

    /**
     * @dev Internal function to update AI Oracle configuration. Callable only by a successful proposal.
     * @param _newPerformanceWeight New weight for DAO's overall performance metric.
     * @param _newRiskWeight New weight for current risk indicators.
     * @param _newInnovationWeight New weight for new successful proposals/initiatives.
     * @param _newRecommendationFactor New factor to scale AI's parameter recommendations.
     */
    function updateAIOracleConfig(
        uint256 _newPerformanceWeight,
        uint256 _newRiskWeight,
        uint256 _newInnovationWeight,
        uint256 _newRecommendationFactor
    ) internal onlyInitialized { // Only callable via internal mechanism (e.g., proposal execution)
        aiOracleConfig = AIOracleConfig({
            performanceWeight: _newPerformanceWeight,
            riskWeight: _newRiskWeight,
            innovationWeight: _newInnovationWeight,
            recommendationFactor: _newRecommendationFactor
        });
        emit AIOracleConfigUpdated(aiOracleConfig);
    }

    /**
     * @dev INTERNAL/Simulated: The AI Oracle processes current DAO state and generates a parameter recommendation.
     *      This function does NOT change parameters directly, but creates a special proposal
     *      that DAO members can `acceptAIRecommendation` to pass.
     *      This is triggered by a high-IQ member or external oracle (simulated here as public for testing).
     * @dev NOTE: For a real system, this would likely be called by a trusted external oracle or a specific
     *      DAO role (e.g., "AI Operator") and not just any high-IQ member, to prevent spamming proposals.
     */
    function _simulateAIRecommendation() external onlyInitialized whenNotPaused minIQRequired(governanceParams.minIQForProposal) {
        // --- Simulated AI Logic ---
        // This is a simplified, deterministic example. In a real scenario, this logic
        // would be far more complex, potentially drawing on various on-chain metrics
        // (e.g., treasury value change, number of executed proposals, dispute rates,
        // external oracle data for market sentiment/risk).

        // Placeholder metrics (can be replaced with real on-chain data)
        // e.g., totalIQSupply can represent DAO engagement
        // number of successful proposals, treasury balance changes etc.
        uint256 currentPerformanceScore = totalIQSupply.div(1000).add(1); // Simple proxy for growth
        uint256 currentRiskScore = totalIQSupply.div(500).add(1);       // Simple proxy for scale = risk
        uint256 currentInnovationScore = nextProposalId.div(100).add(1); // Simple proxy for activity

        // Calculate weighted average for recommendation
        uint256 weightedScore = (currentPerformanceScore.mul(aiOracleConfig.performanceWeight))
                                .add(currentInnovationScore.mul(aiOracleConfig.innovationWeight))
                                .sub(currentRiskScore.mul(aiOracleConfig.riskWeight)); // Risk might lead to reduction

        // Apply recommendation factor to adjust parameters (e.g., reduce voting period if score is high)
        uint256 recommendedVotingPeriod = governanceParams.votingPeriodBlocks;
        if (weightedScore > 0 && aiOracleConfig.recommendationFactor > 0) {
            recommendedVotingPeriod = recommendedVotingPeriod.mul(100).div(100 + aiOracleConfig.recommendationFactor);
            if (recommendedVotingPeriod < 10) recommendedVotingPeriod = 10; // Minimum period
        } else if (weightedScore < 0 && aiOracleConfig.recommendationFactor > 0) {
            // If score is negative, increase voting period (more caution)
            recommendedVotingPeriod = recommendedVotingPeriod.mul(100 + aiOracleConfig.recommendationFactor).div(100);
        }
        // Example: Recommend a change to voting period.
        // More complex AI could recommend changes to multiple parameters.

        // Create a special proposal for this AI-generated recommendation
        bytes memory callData = abi.encodeWithSelector(
            this.updateGovernanceParameters.selector,
            recommendedVotingPeriod,
            governanceParams.quorumPercentage, // Keep others constant for this example
            governanceParams.minIQForProposal,
            governanceParams.minIQForAttestation,
            governanceParams.attestationIQBoost,
            governanceParams.attestationIQPunish,
            governanceParams.proposalPassThreshold
        );

        uint256 proposalId = nextProposalId++;
        Proposal storage newProposal = proposals[proposalId];

        newProposal.id = proposalId;
        newProposal.description = string(abi.encodePacked("AI Recommendation: Adjust Voting Period to ", uint256(recommendedVotingPeriod).toString()));
        newProposal.proposer = address(this); // AI proposes itself
        newProposal.target = address(this);
        newProposal.callData = callData;
        newProposal.value = 0;
        newProposal.startBlock = block.number;
        newProposal.endBlock = block.number.add(governanceParams.votingPeriodBlocks);
        newProposal.state = ProposalState.Active;
        newProposal.isAIRecommendation[_msgSender()] = true; // Mark as AI-triggered, can be voted by 'acceptAIRecommendation'

        emit ProposalCreated(
            proposalId,
            address(this), // AI is the proposer
            newProposal.description,
            address(this),
            0,
            newProposal.startBlock,
            newProposal.endBlock
        );
        emit AIRecommendationGenerated(proposalId, newProposal.description);
    }

    /**
     * @dev Special voting mechanism to accept or reject an AI-generated recommendation.
     *      This is identical to `voteOnProposal` but clarifies the intent for AI proposals.
     * @param _recommendationId The ID of the AI-generated proposal.
     * @param _support True for 'Accept', false for 'Reject'.
     */
    function acceptAIRecommendation(uint256 _recommendationId, bool _support) external onlyInitialized whenNotPaused {
        Proposal storage proposal = proposals[_recommendationId];
        if (proposal.id == 0) revert ProposalNotFound(_recommendationId);
        if (proposal.proposer != address(this)) revert InvalidAIRecommendationTarget(); // Must be an AI-generated proposal

        // Uses the same voting logic as regular proposals
        voteOnProposal(_recommendationId, _support);
    }

    // --- E. Treasury Management ---

    /**
     * @dev Allows users or other contracts to deposit ERC20 tokens into the DAO treasury.
     * @param _token The address of the ERC20 token.
     * @param _amount The amount of tokens to deposit.
     */
    function depositToTreasury(address _token, uint256 _amount) external onlyInitialized whenNotPaused {
        if (_token == address(0) || _amount == 0) revert ZeroAddressNotAllowed(); // Reusing error
        IERC20 token = IERC20(_token);
        uint256 balanceBefore = token.balanceOf(address(this));
        if (!token.transferFrom(_msgSender(), address(this), _amount)) {
            revert TreasuryTransferFailed(_token, _amount);
        }
        uint256 balanceAfter = token.balanceOf(address(this));
        if (balanceAfter.sub(balanceBefore) != _amount) { // Double check for actual transfer
             revert TreasuryTransferFailed(_token, _amount);
        }
        emit TreasuryDeposit(_token, _msgSender(), _amount);
    }

    /**
     * @dev Submits a proposal for the DAO to invest treasury funds into a specific on-chain strategy.
     * @param _tokenToInvest The ERC20 token from the treasury to invest.
     * @param _amount The amount of tokens to invest.
     * @param _strategyContract The address of the external strategy contract.
     * @param _strategyCallData The encoded function call to interact with the strategy contract.
     */
    function proposeTreasuryInvestment(address _tokenToInvest, uint256 _amount, address _strategyContract, bytes calldata _strategyCallData)
        external
        onlyInitialized
        whenNotPaused
        minIQRequired(governanceParams.minIQForProposal)
    {
        if (_tokenToInvest == address(0) || _strategyContract == address(0) || _amount == 0) revert ZeroAddressNotAllowed();

        // The proposal will first approve the strategy contract to spend the tokens,
        // then call the strategy contract to invest. This requires a two-step proposal or a single
        // proposal that calls an intermediate helper function in the DAO.
        // For simplicity, this single proposal will call the strategy contract directly.
        // A more robust system would involve SafeERC20 approve/transferFrom pattern.
        bytes memory approveAndInvestCallData = abi.encodeWithSelector(
            this.executeTreasuryInvestment.selector,
            _tokenToInvest,
            _amount,
            _strategyContract,
            _strategyCallData
        );

        submitProposal(
            "Propose Treasury Investment",
            address(this),
            approveAndInvestCallData,
            0
        );
    }

    /**
     * @dev Internal function to execute a treasury investment. Only callable by a successful proposal.
     *      Handles the `approve` and then the `call` to the strategy contract.
     * @param _tokenToInvest The ERC20 token from the treasury to invest.
     * @param _amount The amount of tokens to invest.
     * @param _strategyContract The address of the external strategy contract.
     * @param _strategyCallData The encoded function call to interact with the strategy contract.
     */
    function executeTreasuryInvestment(address _tokenToInvest, uint256 _amount, address _strategyContract, bytes calldata _strategyCallData)
        internal
        onlyInitialized
        nonReentrant
    {
        // First, approve the strategy contract to spend the tokens
        IERC20 token = IERC20(_tokenToInvest);
        if (!token.approve(_strategyContract, _amount)) {
            revert TreasuryTransferFailed(_tokenToInvest, _amount); // Reusing error
        }

        // Then, call the strategy contract's investment function
        (bool success, ) = _strategyContract.call(_strategyCallData);
        if (!success) {
            // If the investment fails, revoke the approval to be safe
            token.approve(_strategyContract, 0);
            revert TreasuryTransferFailed(_tokenToInvest, _amount); // Reusing error
        }
        emit TreasuryWithdrawal(_tokenToInvest, _strategyContract, _amount); // Log as a withdrawal for tracking
    }


    // --- F. Emergency & Security ---

    /**
     * @dev Activates the emergency circuit breaker, pausing critical DAO functions.
     *      Requires a super-majority (e.g., 70%) of the `emergencyCouncil` to call.
     *      In a real system, this would likely be a more robust multi-sig check.
     *      For simplicity here, we assume a simple 'vote' from emergency council members.
     */
    function emergencyPause() external onlyEmergencyCouncil whenNotPaused {
        // This is a simplified emergency pause. A robust solution would involve a multi-sig
        // or a threshold vote among the emergency council members.
        // For this example, we assume `_msgSender()` being in the council is enough to trigger a proposal-less pause.
        // A more advanced version might require N out of M council members to call this within a short timeframe.
        isPaused = true;
        emit EmergencyPause(_msgSender());
    }

    /**
     * @dev Deactivates the emergency circuit breaker, resuming DAO functions.
     *      Requires a super-majority (e.g., 70%) of the `emergencyCouncil` to call.
     */
    function emergencyUnpause() external onlyEmergencyCouncil whenPaused {
        // Similar simplified unpause mechanism as emergencyPause.
        isPaused = false;
        emit EmergencyUnpause(_msgSender());
    }

    /**
     * @dev Adds a new member to the emergency council. Requires a standard governance proposal.
     * @param _member The address to add.
     */
    function addEmergencyCouncilMember(address _member) external onlyInitialized whenNotPaused minIQRequired(governanceParams.minIQForProposal) {
        if (_member == address(0)) revert ZeroAddressNotAllowed();
        // This function simply creates the proposal. The execution (updateEmergencyCouncil) will add the member.
        bytes memory callData = abi.encodeWithSelector(this.updateEmergencyCouncil.selector, _member, true);
        submitProposal(
            string(abi.encodePacked("Add ", _member.toHexString(), " to Emergency Council")),
            address(this),
            callData,
            0
        );
    }

    /**
     * @dev Removes a member from the emergency council. Requires a standard governance proposal.
     * @param _member The address to remove.
     */
    function removeEmergencyCouncilMember(address _member) external onlyInitialized whenNotPaused minIQRequired(governanceParams.minIQForProposal) {
        if (_member == address(0)) revert ZeroAddressNotAllowed();
        bytes memory callData = abi.encodeWithSelector(this.updateEmergencyCouncil.selector, _member, false);
        submitProposal(
            string(abi.encodePacked("Remove ", _member.toHexString(), " from Emergency Council")),
            address(this),
            callData,
            0
        );
    }

    /**
     * @dev Internal function to update the emergency council. Only callable by a successful proposal.
     * @param _member The address to add or remove.
     * @param _add True to add, false to remove.
     */
    function updateEmergencyCouncil(address _member, bool _add) internal onlyInitialized {
        if (_add) {
            if (!emergencyCouncil[_member]) {
                emergencyCouncil[_member] = true;
                emergencyCouncilCount = emergencyCouncilCount.add(1);
                emit EmergencyCouncilMemberAdded(_member);
            }
        } else {
            if (emergencyCouncil[_member]) {
                emergencyCouncil[_member] = false;
                emergencyCouncilCount = emergencyCouncilCount.sub(1);
                emit EmergencyCouncilMemberRemoved(_member);
            }
        }
    }

    // --- G. Rewards & Penalties ---

    /**
     * @dev Awards a contributor with an IQ boost and/or ERC20 tokens. Requires a standard governance proposal.
     * @param _contributor The address of the contributor.
     * @param _iqBoost The amount of IQ points to boost.
     * @param _tokenRewardAmount The amount of tokens to reward.
     * @param _rewardToken The address of the reward token (address(0) for no token reward).
     */
    function awardContribution(address _contributor, uint256 _iqBoost, uint256 _tokenRewardAmount, address _rewardToken)
        external
        onlyInitialized
        whenNotPaused
        minIQRequired(governanceParams.minIQForProposal)
    {
        if (_contributor == address(0)) revert ZeroAddressNotAllowed();
        bytes memory callData = abi.encodeWithSelector(this.executeAwardContribution.selector, _contributor, _iqBoost, _tokenRewardAmount, _rewardToken);
        submitProposal(
            string(abi.encodePacked("Award Contributor: ", _contributor.toHexString())),
            address(this),
            callData,
            0
        );
    }

    /**
     * @dev Internal function to execute contribution awards. Only callable by a successful proposal.
     * @param _contributor The address of the contributor.
     * @param _iqBoost The amount of IQ points to boost.
     * @param _tokenRewardAmount The amount of tokens to reward.
     * @param _rewardToken The address of the reward token (address(0) for no token reward).
     */
    function executeAwardContribution(address _contributor, uint256 _iqBoost, uint256 _tokenRewardAmount, address _rewardToken) internal onlyInitialized nonReentrant {
        if (_iqBoost > 0) {
            _adjustIQScore(_contributor, _iqBoost, "Contribution award", true);
        }
        if (_tokenRewardAmount > 0 && _rewardToken != address(0)) {
            IERC20 rewardToken = IERC20(_rewardToken);
            if (!rewardToken.transfer(_contributor, _tokenRewardAmount)) {
                revert TreasuryTransferFailed(_rewardToken, _tokenRewardAmount);
            }
            emit TreasuryWithdrawal(_rewardToken, _contributor, _tokenRewardAmount);
        }
        emit ContributorAwarded(_contributor, _iqBoost, _tokenRewardAmount, _rewardToken);
    }

    /**
     * @dev Penalizes a malicious actor by reducing their IQ score. Requires a standard governance proposal.
     * @param _maliciousActor The address of the malicious actor.
     * @param _iqPenalty The amount of IQ points to deduct.
     */
    function penalizeMaliciousActivity(address _maliciousActor, uint256 _iqPenalty)
        external
        onlyInitialized
        whenNotPaused
        minIQRequired(governanceParams.minIQForProposal)
    {
        if (_maliciousActor == address(0)) revert ZeroAddressNotAllowed();
        bytes memory callData = abi.encodeWithSelector(this.executePenalizeMaliciousActivity.selector, _maliciousActor, _iqPenalty);
        submitProposal(
            string(abi.encodePacked("Penalize Malicious Actor: ", _maliciousActor.toHexString())),
            address(this),
            callData,
            0
        );
    }

    /**
     * @dev Internal function to execute malicious activity penalties. Only callable by a successful proposal.
     * @param _maliciousActor The address of the malicious actor.
     * @param _iqPenalty The amount of IQ points to deduct.
     */
    function executePenalizeMaliciousActivity(address _maliciousActor, uint256 _iqPenalty) internal onlyInitialized {
        if (_iqPenalty > 0) {
            _adjustIQScore(_maliciousActor, _iqPenalty, "Malicious activity penalty", false);
        }
        emit MaliciousActorPenalized(_maliciousActor, _iqPenalty);
    }

    // --- H. Read-Only / Information ---

    /**
     * @dev Returns the current active governance parameters of the DAO.
     */
    function getGovernanceParameters() external view onlyInitialized returns (GovernanceParameters memory) {
        return governanceParams;
    }

    /**
     * @dev Returns the current configuration weights and thresholds for the simulated AI Oracle.
     */
    function getAIOracleConfig() external view onlyInitialized returns (AIOracleConfig memory) {
        return aiOracleConfig;
    }

    /**
     * @dev Helper function to convert uint256 to string.
     * @param value The uint256 to convert.
     * @return The string representation of the uint256.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```