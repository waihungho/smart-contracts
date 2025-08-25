Here is a Solidity smart contract for an **"AetherNexusDAO"**, a Decentralized Autonomous Organization augmented with a network of "Decentralized Intelligence Units" (DIUs). This contract aims to be advanced, creative, and trendy by integrating verifiable AI-driven insights directly into the DAO's governance and decision-making processes, creating a self-evolving system. It avoids direct duplication of common open-source projects by focusing on the dynamic adjustment of governance parameters based on AI performance and reputation, and a collaborative intelligence framework.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline & Function Summary ---
//
// Contract Name: AetherNexusDAO
//
// Concept: A Decentralized Autonomous Organization (DAO) augmented with a network of "Decentralized Intelligence Units" (DIUs). DIUs are contributed by participants, providing verifiable AI-driven insights, predictions, and even proposing dynamic governance adjustments. The DAO's governance evolves based on the collective intelligence and performance of these DIUs, alongside traditional human voting. It emphasizes verifiable AI outputs, reputation-based influence, and incentive mechanisms for data contributors and high-performing DIUs.
//
// Outline:
// I. Core Structures & State Variables: Defines structs for DIUs, proposals, collective insights, and essential mappings/storage.
// II. Initialization: Sets up the DAO's foundational parameters.
// III. Intelligence Unit Management: Functions for registering, updating, and verifying the outputs of DIUs.
// IV. Dynamic Governance & Policy: Mechanisms for DIUs to propose changes to DAO policies (e.g., voting weights, funding rules) and for members to vote on them.
// V. Treasury & Budget Management: Functions for DIUs to propose fund allocations and for the community to approve them.
// VI. Reputation & Incentive System: Tracking and rewarding high-performing DIUs and quality data contributors.
// VII. Collective Intelligence & Querying: Functions to facilitate aggregated insights from multiple DIUs for complex queries.
// VIII. View Functions: Read-only functions to query the state of the DAO.
// IX. Administration: Functions for managing the DAO's key roles.
//
// Function Summary (24 functions):
//
// I. Core DAO & AI Agent Management:
// 1. initializeDAO(address _initialGovernor, address _governanceToken, uint256 _minVotingPower): Initializes the DAO with an initial governor, governance token, and minimum voting power.
// 2. registerIntelligenceUnit(address _unitController, string memory _name, string memory _metadataURI, address _proofVerifierContract): Registers a new Decentralized Intelligence Unit (DIU), linking it to a controller and a proof verification method.
// 3. deregisterIntelligenceUnit(uint256 _unitId): Removes a DIU, potentially due to poor performance or malicious activity.
// 4. updateUnitMetadata(uint256 _unitId, string memory _newMetadataURI): Updates the descriptive metadata URI for a registered DIU.
// 5. submitIntelligenceOutput(uint256 _unitId, bytes32 _outputHash, bytes memory _proof): A DIU submits a verifiable output (e.g., a prediction, a recommendation) along with a proof (e.g., ZKP, signature).
// 6. verifyIntelligenceOutput(uint256 _unitId, bytes32 _outputHash, bytes memory _proof): Allows anyone to trigger on-chain verification of a submitted DIU output, using the registered proof verification method.
//
// II. Dynamic Governance & Policy:
// 7. proposePolicyAdjustment(uint256 _unitId, PolicyType _policyType, bytes memory _policyParameters, string memory _descriptionURI): A DIU proposes a dynamic adjustment to a DAO governance parameter (e.g., vote threshold, reputation decay rate).
// 8. voteOnPolicyAdjustment(uint256 _proposalId, bool _approve): DAO members vote on a proposed policy adjustment.
// 9. executePolicyAdjustment(uint256 _proposalId): Executes an approved policy adjustment.
//
// III. Treasury & Budget Management:
// 10. proposeBudgetAllocation(uint256 _unitId, uint256 _amount, address _recipient, string memory _purposeURI): A DIU proposes an allocation of funds from the DAO treasury.
// 11. voteOnBudgetAllocation(uint256 _proposalId, bool _approve): DAO members vote on a proposed budget allocation.
// 12. executeBudgetAllocation(uint256 _proposalId): Executes an approved budget allocation.
// 13. depositFunds(): Allows anyone to deposit funds into the DAO treasury (via the governance token).
//
// IV. Reputation & Incentive System:
// 14. attestDataContribution(address _contributor, bytes32 _dataHash, uint256 _qualityScore, string memory _proofURI): Allows users to attest to providing high-quality, verifiable data used for training DIUs, impacting their reputation and potential rewards.
// 15. evaluateUnitPerformance(uint256 _unitId, bytes32 _expectedOutputHash, bytes32 _actualOutputHash, int256 _scoreChange): An oracle or trusted entity evaluates a DIU's past output accuracy, updating its reputation score.
// 16. claimIncentives(): Allows eligible DIU controllers and data contributors to claim accrued rewards based on their reputation and contributions.
// 17. distributeIncentives(): Admin/DAO-controlled function to trigger the distribution of accumulated incentives. (Conceptual, relies mostly on claimIncentives)
//
// V. Collective Intelligence & Querying:
// 18. requestCollectiveInsight(bytes32 _questionIdentifier, string memory _contextURI): Initiates a collective intelligence query, prompting registered DIUs to contribute insights on a specific question.
// 19. submitCollectiveInsightComponent(uint256 _queryId, uint256 _unitId, bytes32 _componentHash, bytes memory _proof): A DIU submits its individual component of the collective insight, along with proof.
// 20. finalizeCollectiveInsight(uint256 _queryId): Aggregates and finalizes the collective insight from submitted components, potentially weighted by DIU reputation.
//
// VI. View Functions:
// 21. getUnitReputation(uint256 _unitId): Returns the current reputation score of a specific DIU.
// 22. getEffectiveVotingWeight(address _voter): Calculates and returns the effective voting weight of a DAO member, potentially factoring in their own DIU's reputation or their support for high-reputation DIUs.
//
// VII. Administration:
// 23. transferGovernor(address _newGovernor): Allows the current governor to transfer governorship to another address.
// 24. setReputationOracle(address _newOracle): Allows the governor to set a new reputation oracle address.

// --- Custom Errors for better gas efficiency and clarity ---
error AlreadyInitialized();
error NotInitialized();
error Unauthorized();
error InvalidUnitId();
error ProofVerificationFailed();
error InvalidProposalState();
error ProposalNotFound();
error AlreadyVoted();
error NotEnoughVotingPower();
error CannotExecuteYet();
error PolicyTypeMismatch();
error InsufficientFunds();
error NoIncentivesToClaim();
error InvalidQualityScore();
error QueryNotFound();
error QueryAlreadyFinalized();
error NotActiveUnit();
error InvalidZeroAddress();
error SubmissionPeriodNotOver();


// --- External Interfaces ---

// Placeholder for a Zero-Knowledge Proof (ZKP) verifier or similar on-chain verification system.
// In a real scenario, this would be a specific verifier contract (e.g., PLONK, Groth16)
// or an oracle interface for off-chain AI model inference verification.
interface IProofVerifier {
    function verify(bytes32 _outputHash, bytes calldata _proof) external view returns (bool);
}

// Interface for a reputation oracle or a contract authorized to evaluate DIU performance.
// In a full implementation, this might be a multi-sig or a sub-DAO.
interface IReputationOracle {
    function evaluate(uint256 _unitId, bytes32 _expectedOutputHash, bytes32 _actualOutputHash, int256 _scoreChange) external returns (bool);
}

contract AetherNexusDAO is Context, ReentrancyGuard {
    // --- I. Core Structures & State Variables ---

    bool private _initialized;

    // The token used for governance voting and potentially for incentives.
    IERC20 public governanceToken;

    // Minimum voting power (tokens) required to participate in governance.
    uint256 public minVotingPower;

    // Address of the main governor/admin of the DAO.
    address public governor;

    // Address of the contract/entity authorized to evaluate DIU performance.
    address public reputationOracle;

    // Enum for different types of dynamic policy adjustments DIUs can propose.
    enum PolicyType {
        VotingWeightFactor,      // Adjusts how much DIU reputation impacts voting weight
        ProposalThreshold,       // Changes the minimum votes/power required for a proposal to pass
        ReputationDecayRate,     // Adjusts how quickly DIU reputation decays over time
        FundingAllocationFactor  // Modifies factors for incentive distribution, e.g., how much incentives are paid per reputation point
    }

    // Struct for a Decentralized Intelligence Unit (DIU)
    struct IntelligenceUnit {
        address unitController;           // The address controlling this DIU
        string name;                      // Human-readable name
        string metadataURI;               // URI pointing to more details about the DIU (e.g., model architecture, training data summary)
        address proofVerifierContract;    // Address of the contract used to verify outputs from this DIU
        int256 reputationScore;           // Reputation score of the DIU
        bool isActive;                    // True if the unit is active and participating
        uint256 registeredTimestamp;      // Timestamp when the unit was registered
        uint256 lastActivityTimestamp;    // Last time unit submitted output or was evaluated
        uint256 accumulatedIncentives;    // Incentives waiting to be claimed by the controller
    }
    uint256 public nextUnitId = 1; // Start unit IDs from 1
    mapping(uint256 => IntelligenceUnit) public intelligenceUnits;
    mapping(address => uint256[]) public controllerToUnitIds; // Map controller to all units they own

    // Struct for a governance proposal (policy adjustment or budget allocation)
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }
    enum ProposalType { PolicyAdjustment, BudgetAllocation }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        uint256 proposerUnitId;           // The DIU that proposed this
        string descriptionURI;            // URI with details about the proposal
        uint256 creationTimestamp;
        uint256 votingDeadline;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if an address has voted
        ProposalState state;
        bytes data;                       // Specific data for PolicyAdjustment or BudgetAllocation
        address targetAddress;            // For BudgetAllocation: recipient address
        uint256 amount;                   // For BudgetAllocation: amount
        PolicyType policyType;            // For PolicyAdjustment: type of policy
    }
    uint256 public nextProposalId = 1;
    mapping(uint256 => Proposal) public proposals;

    // Struct for Data Contribution Attestation
    struct DataContribution {
        address contributor;
        bytes32 dataHash;                 // Hash of the contributed data (off-chain)
        uint256 qualityScore;             // Quality score for the data (e.g., 1-100)
        string proofURI;                  // URI to proof of data quality/provenance
        uint256 attestationTimestamp;
        bool claimed;                     // Whether incentives for this contribution have been claimed
        uint256 accumulatedIncentives;
    }
    uint256 public nextDataContributionId = 1;
    mapping(uint256 => DataContribution) public dataContributions;
    mapping(address => uint256[]) public contributorToDataContributions;

    // Struct for Collective Intelligence Queries
    struct CollectiveInsightQuery {
        uint256 queryId;
        bytes32 questionIdentifier;       // Unique identifier for the question being asked
        string contextURI;                // URI with more context about the question
        uint256 creationTimestamp;
        uint256 submissionDeadline;
        mapping(uint256 => bytes32) submittedComponents; // unitId => componentHash
        mapping(uint256 => bool) hasSubmitted; // unitId => submitted
        bool isFinalized;
        bytes32 finalInsightHash;         // The aggregated/finalized insight hash
    }
    uint256 public nextQueryId = 1;
    mapping(uint256 => CollectiveInsightQuery) public collectiveInsightQueries;

    // DAO parameters, adjustable by governance
    uint256 public proposalVotingPeriod = 3 days;
    uint256 public minReputationForProposing = 100; // Minimum reputation for a DIU to propose
    uint256 public defaultVotingWeightFactor = 1;    // Base factor for calculating how much reputation influences voting
    uint256 public reputationDecayRate = 1;          // Units of reputation decay per day (e.g., 1 point per day)
    uint256 public incentivePerReputationPoint = 10 ** 16; // 0.01 token per reputation point

    // Events
    event DAOInitialized(address indexed initialGovernor, address indexed governanceToken, uint256 minVotingPower);
    event UnitRegistered(uint256 indexed unitId, address indexed unitController, string name, string metadataURI);
    event UnitDeregistered(uint256 indexed unitId);
    event UnitMetadataUpdated(uint256 indexed unitId, string newMetadataURI);
    event IntelligenceOutputSubmitted(uint256 indexed unitId, bytes32 outputHash);
    event IntelligenceOutputVerified(uint256 indexed unitId, bytes32 outputHash, bool success);
    event PolicyAdjustmentProposed(uint256 indexed proposalId, uint256 indexed proposerUnitId, PolicyType policyType, bytes policyParameters);
    event BudgetAllocationProposed(uint256 indexed proposalId, uint256 indexed proposerUnitId, uint256 amount, address recipient);
    event Voted(uint256 indexed proposalId, address indexed voter, bool approved, uint256 votingPower);
    event ProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event PolicyAdjustmentExecuted(uint256 indexed proposalId, PolicyType policyType, bytes policyParameters);
    event BudgetAllocationExecuted(uint256 indexed proposalId, uint256 amount, address indexed recipient);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event DataAttested(uint256 indexed contributionId, address indexed contributor, bytes32 dataHash, uint256 qualityScore);
    event UnitPerformanceEvaluated(uint256 indexed unitId, int256 scoreChange, int256 newReputation);
    event IncentivesClaimed(address indexed receiver, uint256 amount);
    event IncentivesDistributed(uint256 totalDistributedAmount);
    event CollectiveInsightQueryRequested(uint256 indexed queryId, bytes32 questionIdentifier);
    event CollectiveInsightComponentSubmitted(uint256 indexed queryId, uint256 indexed unitId, bytes32 componentHash);
    event CollectiveInsightFinalized(uint256 indexed queryId, bytes32 finalInsightHash);

    // --- Constructor & Initialization ---

    /**
     * @dev Constructor to set initial key roles. `initializeDAO` performs full DAO setup.
     * @param _initialGovernor The address of the initial governor.
     * @param _initialReputationOracle The address of the initial reputation oracle.
     */
    constructor(address _initialGovernor, address _initialReputationOracle) {
        if (_initialGovernor == address(0) || _initialReputationOracle == address(0)) revert InvalidZeroAddress();
        governor = _initialGovernor;
        reputationOracle = _initialReputationOracle;
    }

    /**
     * @dev Initializes the DAO parameters. Can only be called once.
     * @param _governanceToken The ERC20 token address used for governance.
     * @param _minVotingPower The minimum amount of governance tokens required to vote.
     */
    function initializeDAO(address _governanceToken, uint256 _minVotingPower)
        external
        onlyGovernor
    {
        if (_initialized) revert AlreadyInitialized();
        if (_governanceToken == address(0)) revert InvalidZeroAddress();

        governanceToken = IERC20(_governanceToken);
        minVotingPower = _minVotingPower;
        _initialized = true;
        emit DAOInitialized(governor, _governanceToken, _minVotingPower);
    }

    // --- Modifiers ---
    modifier onlyGovernor() {
        if (_msgSender() != governor) revert Unauthorized();
        _;
    }

    modifier onlyReputationOracle() {
        if (_msgSender() != reputationOracle) revert Unauthorized();
        _;
    }

    modifier checkInitialized() {
        if (!_initialized) revert NotInitialized();
        _;
    }

    modifier onlyActiveUnit(uint256 _unitId) {
        if (intelligenceUnits[_unitId].unitController == address(0) || !intelligenceUnits[_unitId].isActive) revert NotActiveUnit();
        _;
    }

    // --- II. Intelligence Unit Management ---

    /**
     * @dev Registers a new Decentralized Intelligence Unit (DIU).
     * @param _unitController The address that controls this DIU.
     * @param _name A human-readable name for the DIU.
     * @param _metadataURI URI pointing to off-chain metadata (e.g., model architecture, training data summary).
     * @param _proofVerifierContract Address of the contract responsible for verifying proofs from this DIU.
     */
    function registerIntelligenceUnit(
        address _unitController,
        string memory _name,
        string memory _metadataURI,
        address _proofVerifierContract
    ) external checkInitialized {
        if (_unitController == address(0) || _proofVerifierContract == address(0)) revert InvalidZeroAddress();

        uint256 unitId = nextUnitId++;
        intelligenceUnits[unitId] = IntelligenceUnit({
            unitController: _unitController,
            name: _name,
            metadataURI: _metadataURI,
            proofVerifierContract: _proofVerifierContract,
            reputationScore: 0, // Starts with neutral reputation
            isActive: true,
            registeredTimestamp: block.timestamp,
            lastActivityTimestamp: block.timestamp,
            accumulatedIncentives: 0
        });
        controllerToUnitIds[_unitController].push(unitId);
        emit UnitRegistered(unitId, _unitController, _name, _metadataURI);
    }

    /**
     * @dev Deactivates a DIU. Can be called by the governor or the DIU's controller.
     *      A deactivated DIU cannot submit outputs or propose.
     * @param _unitId The ID of the DIU to deregister.
     */
    function deregisterIntelligenceUnit(uint256 _unitId) external checkInitialized {
        IntelligenceUnit storage unit = intelligenceUnits[_unitId];
        if (unit.unitController == address(0)) revert InvalidUnitId();
        if (_msgSender() != unit.unitController && _msgSender() != governor) revert Unauthorized();

        unit.isActive = false;
        emit UnitDeregistered(_unitId);
    }

    /**
     * @dev Updates the metadata URI for a registered DIU. Only the unit controller can call this.
     * @param _unitId The ID of the DIU.
     * @param _newMetadataURI The new URI pointing to off-chain metadata.
     */
    function updateUnitMetadata(uint256 _unitId, string memory _newMetadataURI) external checkInitialized onlyActiveUnit(_unitId) {
        IntelligenceUnit storage unit = intelligenceUnits[_unitId];
        if (unit.unitController != _msgSender()) revert Unauthorized();

        unit.metadataURI = _newMetadataURI;
        emit UnitMetadataUpdated(_unitId, _newMetadataURI);
    }

    /**
     * @dev A DIU submits a verifiable output (e.g., a prediction, a recommendation).
     * @param _unitId The ID of the DIU submitting the output.
     * @param _outputHash A hash representing the output data (actual data is off-chain).
     * @param _proof A cryptographic proof (e.g., ZKP, signature) verifying the output.
     */
    function submitIntelligenceOutput(uint256 _unitId, bytes32 _outputHash, bytes memory _proof)
        external
        checkInitialized
        onlyActiveUnit(_unitId)
    {
        IntelligenceUnit storage unit = intelligenceUnits[_unitId];
        if (unit.unitController != _msgSender()) revert Unauthorized();

        // The actual verification is done via `verifyIntelligenceOutput` which can be called by anyone.
        // This function only registers the output for later verification.
        unit.lastActivityTimestamp = block.timestamp;

        emit IntelligenceOutputSubmitted(_unitId, _outputHash);
    }

    /**
     * @dev Allows anyone to trigger on-chain verification of a submitted DIU output.
     *      This function interacts with the registered `IProofVerifier` contract.
     * @param _unitId The ID of the DIU whose output is being verified.
     * @param _outputHash The hash of the output to verify.
     * @param _proof The proof data associated with the output.
     */
    function verifyIntelligenceOutput(uint256 _unitId, bytes32 _outputHash, bytes memory _proof)
        public
        checkInitialized
        onlyActiveUnit(_unitId)
        returns (bool)
    {
        IntelligenceUnit storage unit = intelligenceUnits[_unitId];
        if (unit.proofVerifierContract == address(0)) revert ProofVerificationFailed(); // No verifier registered

        bool success = IProofVerifier(unit.proofVerifierContract).verify(_outputHash, _proof);
        if (!success) revert ProofVerificationFailed();

        emit IntelligenceOutputVerified(_unitId, _outputHash, success);
        return success;
    }

    // --- III. Dynamic Governance & Policy ---

    /**
     * @dev A DIU proposes a dynamic adjustment to a DAO governance parameter.
     *      Requires the DIU to have a minimum reputation score.
     * @param _unitId The ID of the proposing DIU.
     * @param _policyType The type of policy being adjusted.
     * @param _policyParameters Specific parameters for the policy (e.g., new value).
     * @param _descriptionURI URI with a detailed explanation of the proposed policy.
     */
    function proposePolicyAdjustment(
        uint256 _unitId,
        PolicyType _policyType,
        bytes memory _policyParameters,
        string memory _descriptionURI
    ) external checkInitialized onlyActiveUnit(_unitId) {
        IntelligenceUnit storage unit = intelligenceUnits[_unitId];
        if (unit.unitController != _msgSender()) revert Unauthorized();
        if (unit.reputationScore < int256(minReputationForProposing)) revert NotEnoughVotingPower(); // Using reputation as "power" for proposing

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.PolicyAdjustment,
            proposerUnitId: _unitId,
            descriptionURI: _descriptionURI,
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            data: _policyParameters,
            targetAddress: address(0),
            amount: 0,
            policyType: _policyType
        });

        emit PolicyAdjustmentProposed(proposalId, _unitId, _policyType, _policyParameters);
    }

    /**
     * @dev DAO members vote on a proposed policy adjustment or budget allocation.
     * @param _proposalId The ID of the proposal.
     * @param _approve True for a 'for' vote, false for 'against'.
     */
    function voteOnPolicyAdjustment(uint256 _proposalId, bool _approve) external checkInitialized nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposerUnitId == 0) revert ProposalNotFound();
        if (proposal.state != ProposalState.Active) revert InvalidProposalState();
        if (proposal.votingDeadline < block.timestamp) {
            _updateProposalState(_proposalId); // Update state if deadline passed
            revert InvalidProposalState(); // Revert because state has changed
        }
        if (proposal.hasVoted[_msgSender()]) revert AlreadyVoted();

        uint256 votingPower = getEffectiveVotingWeight(_msgSender());
        if (votingPower < minVotingPower) revert NotEnoughVotingPower();

        if (_approve) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[_msgSender()] = true;

        emit Voted(_proposalId, _msgSender(), _approve, votingPower);
    }

    /**
     * @dev Executes an approved policy adjustment. Only callable after the voting period ends and if approved.
     * @param _proposalId The ID of the policy adjustment proposal.
     */
    function executePolicyAdjustment(uint256 _proposalId) external checkInitialized onlyGovernor nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposerUnitId == 0) revert ProposalNotFound();
        if (proposal.proposalType != ProposalType.PolicyAdjustment) revert PolicyTypeMismatch();

        _updateProposalState(_proposalId); // Ensure state is up-to-date

        if (proposal.state != ProposalState.Succeeded) revert CannotExecuteYet();
        if (proposal.state == ProposalState.Executed) revert InvalidProposalState(); // Already executed

        // Apply the policy change based on `proposal.policyType` and `proposal.data`
        require(proposal.data.length == 32, "Invalid data length for policy parameter"); // Expect a uint256
        uint256 newValue = abi.decode(proposal.data, (uint256));

        if (proposal.policyType == PolicyType.VotingWeightFactor) {
            defaultVotingWeightFactor = newValue;
        } else if (proposal.policyType == PolicyType.ProposalThreshold) {
            minVotingPower = newValue;
            minReputationForProposing = newValue;
        } else if (proposal.policyType == PolicyType.ReputationDecayRate) {
            reputationDecayRate = newValue;
        } else if (proposal.policyType == PolicyType.FundingAllocationFactor) {
            incentivePerReputationPoint = newValue;
        } else {
            revert PolicyTypeMismatch();
        }

        proposal.state = ProposalState.Executed;
        emit PolicyAdjustmentExecuted(_proposalId, proposal.policyType, proposal.data);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    /**
     * @dev Internal function to update a proposal's state based on time and votes.
     * @param _proposalId The ID of the proposal.
     */
    function _updateProposalState(uint256 _proposalId) internal {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) return;

        if (block.timestamp < proposal.votingDeadline) return;

        // Simple majority: more 'for' votes than 'against' votes.
        // Can be extended with quorum or supermajority logic.
        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Succeeded;
        } else {
            proposal.state = ProposalState.Failed;
        }
        emit ProposalStateChanged(_proposalId, proposal.state);
    }

    // --- IV. Treasury & Budget Management ---

    /**
     * @dev A DIU proposes an allocation of funds from the DAO treasury.
     *      Requires the DIU to have a minimum reputation score.
     * @param _unitId The ID of the proposing DIU.
     * @param _amount The amount of governance tokens to allocate.
     * @param _recipient The address to receive the funds.
     * @param _purposeURI URI with a detailed explanation for the allocation.
     */
    function proposeBudgetAllocation(
        uint256 _unitId,
        uint256 _amount,
        address _recipient,
        string memory _purposeURI
    ) external checkInitialized onlyActiveUnit(_unitId) {
        IntelligenceUnit storage unit = intelligenceUnits[_unitId];
        if (unit.unitController != _msgSender()) revert Unauthorized();
        if (unit.reputationScore < int256(minReputationForProposing)) revert NotEnoughVotingPower();
        if (_recipient == address(0)) revert InvalidZeroAddress();

        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposalId: proposalId,
            proposalType: ProposalType.BudgetAllocation,
            proposerUnitId: _unitId,
            descriptionURI: _purposeURI,
            creationTimestamp: block.timestamp,
            votingDeadline: block.timestamp + proposalVotingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Active,
            data: new bytes(0),
            targetAddress: _recipient,
            amount: _amount,
            policyType: PolicyType.VotingWeightFactor // Default/unused for budget
        });

        emit BudgetAllocationProposed(proposalId, _unitId, _amount, _recipient);
    }

    /**
     * @dev DAO members vote on a proposed budget allocation.
     * @param _proposalId The ID of the budget proposal.
     * @param _approve True for a 'for' vote, false for 'against'.
     */
    function voteOnBudgetAllocation(uint256 _proposalId, bool _approve) external checkInitialized nonReentrant {
        // Uses the same voting logic as policy adjustments.
        voteOnPolicyAdjustment(_proposalId, _approve);
    }

    /**
     * @dev Executes an approved budget allocation, transferring governance tokens from the DAO treasury.
     * @param _proposalId The ID of the budget allocation proposal.
     */
    function executeBudgetAllocation(uint256 _proposalId) external checkInitialized onlyGovernor nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.proposerUnitId == 0) revert ProposalNotFound();
        if (proposal.proposalType != ProposalType.BudgetAllocation) revert PolicyTypeMismatch();

        _updateProposalState(_proposalId);

        if (proposal.state != ProposalState.Succeeded) revert CannotExecuteYet();
        if (proposal.state == ProposalState.Executed) revert InvalidProposalState();

        if (governanceToken.balanceOf(address(this)) < proposal.amount) revert InsufficientFunds();

        // Transfer funds
        bool success = governanceToken.transfer(proposal.targetAddress, proposal.amount);
        require(success, "Token transfer failed");

        proposal.state = ProposalState.Executed;
        emit BudgetAllocationExecuted(_proposalId, proposal.amount, proposal.targetAddress);
        emit ProposalStateChanged(_proposalId, ProposalState.Executed);
    }

    /**
     * @dev Allows anyone to deposit governance tokens into the DAO treasury.
     *      These funds can then be used for budget allocations or incentives.
     *      Requires the sender to have approved this contract to spend their tokens beforehand.
     */
    function depositFunds() external checkInitialized nonReentrant {
        uint256 amount = governanceToken.allowance(_msgSender(), address(this));
        if (amount == 0) revert InsufficientFunds(); // Or a more specific error for no allowance

        // Pull tokens from the sender's allowance
        bool success = governanceToken.transferFrom(_msgSender(), address(this), amount);
        require(success, "Token transferFrom failed");
        emit FundsDeposited(_msgSender(), amount);
    }

    // --- V. Reputation & Incentive System ---

    /**
     * @dev Allows users to attest to providing high-quality, verifiable data used for training DIUs.
     *      This contributes to their reputation and potential future incentives.
     *      Only callable by the designated Reputation Oracle.
     * @param _contributor The address of the data contributor.
     * @param _dataHash Hash of the off-chain data (for provenance).
     * @param _qualityScore A score indicating the perceived quality of the data (e.g., 1-100).
     * @param _proofURI URI to a proof of data quality/verifiability.
     */
    function attestDataContribution(
        address _contributor,
        bytes32 _dataHash,
        uint256 _qualityScore,
        string memory _proofURI
    ) external checkInitialized onlyReputationOracle {
        if (_qualityScore == 0 || _qualityScore > 100) revert InvalidQualityScore();
        if (_contributor == address(0)) revert InvalidZeroAddress();

        uint256 contributionId = nextDataContributionId++;
        dataContributions[contributionId] = DataContribution({
            contributor: _contributor,
            dataHash: _dataHash,
            qualityScore: _qualityScore,
            proofURI: _proofURI,
            attestationTimestamp: block.timestamp,
            claimed: false,
            accumulatedIncentives: _qualityScore * (incentivePerReputationPoint / 100) // Example: 1 token per 100 quality score, adjusted by incentivePerReputationPoint
        });
        contributorToDataContributions[_contributor].push(contributionId);
        emit DataAttested(contributionId, _contributor, _dataHash, _qualityScore);
    }

    /**
     * @dev An oracle or trusted entity evaluates a DIU's past output accuracy, updating its reputation score.
     *      Only callable by the designated Reputation Oracle.
     * @param _unitId The ID of the DIU being evaluated.
     * @param _expectedOutputHash Hash of the expected/ground-truth outcome (for logging/audit).
     * @param _actualOutputHash Hash of the DIU's submitted output (for logging/audit).
     * @param _scoreChange The amount to change the reputation score by (can be positive or negative).
     */
    function evaluateUnitPerformance(
        uint256 _unitId,
        bytes32 _expectedOutputHash,
        bytes32 _actualOutputHash,
        int256 _scoreChange
    ) external checkInitialized onlyReputationOracle onlyActiveUnit(_unitId) {
        IntelligenceUnit storage unit = intelligenceUnits[_unitId];

        // Apply decay before updating score (more accurate decay)
        uint256 daysPassed = (block.timestamp - unit.lastActivityTimestamp) / 1 days;
        if (daysPassed > 0) {
            int256 decayAmount = int256(daysPassed * reputationDecayRate);
            unit.reputationScore -= decayAmount;
            if (unit.reputationScore < 0) unit.reputationScore = 0; // Reputation doesn't go below zero
        }
        
        unit.reputationScore += _scoreChange;
        if (unit.reputationScore < 0) unit.reputationScore = 0; // Ensure reputation stays non-negative after score change

        unit.lastActivityTimestamp = block.timestamp; // Update activity after evaluation

        // Accrue incentives based on positive score changes
        if (_scoreChange > 0) {
            unit.accumulatedIncentives += uint256(_scoreChange) * incentivePerReputationPoint;
        }

        emit UnitPerformanceEvaluated(_unitId, _scoreChange, unit.reputationScore);
    }

    /**
     * @dev Allows eligible DIU controllers and data contributors to claim accrued rewards.
     */
    function claimIncentives() external checkInitialized nonReentrant {
        uint256 totalClaimable = 0;

        // Claim for DIUs controlled by msg.sender
        uint256[] memory unitIds = controllerToUnitIds[_msgSender()];
        for (uint256 i = 0; i < unitIds.length; i++) {
            IntelligenceUnit storage unit = intelligenceUnits[unitIds[i]];
            if (unit.accumulatedIncentives > 0) {
                totalClaimable += unit.accumulatedIncentives;
                unit.accumulatedIncentives = 0;
            }
        }

        // Claim for data contributions by msg.sender
        uint256[] memory dcIds = contributorToDataContributions[_msgSender()];
        for (uint256 i = 0; i < dcIds.length; i++) {
            DataContribution storage dc = dataContributions[dcIds[i]];
            if (!dc.claimed && dc.accumulatedIncentives > 0) {
                totalClaimable += dc.accumulatedIncentives;
                dc.claimed = true;
            }
        }

        if (totalClaimable == 0) revert NoIncentivesToClaim();
        if (governanceToken.balanceOf(address(this)) < totalClaimable) revert InsufficientFunds();

        bool success = governanceToken.transfer(_msgSender(), totalClaimable);
        require(success, "Incentive transfer failed");

        emit IncentivesClaimed(_msgSender(), totalClaimable);
    }

    /**
     * @dev Admin/DAO-controlled function to trigger the distribution of accumulated incentives.
     *      This function is conceptual for a global push mechanism, but `claimIncentives` is the primary user-initiated method.
     *      A practical implementation would involve querying total outstanding incentives and then `transfer`ring them to various addresses.
     *      For this example, it primarily signals that a distribution event occurred.
     */
    function distributeIncentives() external checkInitialized onlyGovernor nonReentrant {
        // In a real system, this would involve more complex logic, potentially iterating
        // over all pending claims or a snapshot to distribute from a central pool.
        // For simplicity, we assume individual users claim via `claimIncentives`.
        // This function could instead be used to top-up the incentive pool if needed,
        // or trigger a 'push' for specific, pre-determined incentive rounds.
        emit IncentivesDistributed(0); // Amount would be dynamic if actual distribution occurs here
    }

    // --- VI. Collective Intelligence & Querying ---

    /**
     * @dev Initiates a collective intelligence query, prompting registered DIUs to contribute insights.
     * @param _questionIdentifier A unique hash or identifier for the question.
     * @param _contextURI URI with more context/details about the question.
     */
    function requestCollectiveInsight(bytes32 _questionIdentifier, string memory _contextURI)
        external
        checkInitialized
        returns (uint256 queryId)
    {
        queryId = nextQueryId++;
        collectiveInsightQueries[queryId] = CollectiveInsightQuery({
            queryId: queryId,
            questionIdentifier: _questionIdentifier,
            contextURI: _contextURI,
            creationTimestamp: block.timestamp,
            submissionDeadline: block.timestamp + 1 days, // Example: 1 day for submissions
            isFinalized: false,
            finalInsightHash: bytes32(0)
        });
        emit CollectiveInsightQueryRequested(queryId, _questionIdentifier);
    }

    /**
     * @dev A DIU submits its individual component of a collective insight.
     * @param _queryId The ID of the collective intelligence query.
     * @param _unitId The ID of the DIU submitting the component.
     * @param _componentHash Hash of the insight component (off-chain).
     * @param _proof A cryptographic proof verifying the insight component.
     */
    function submitCollectiveInsightComponent(
        uint256 _queryId,
        uint256 _unitId,
        bytes32 _componentHash,
        bytes memory _proof
    ) external checkInitialized onlyActiveUnit(_unitId) {
        CollectiveInsightQuery storage query = collectiveInsightQueries[_queryId];
        if (query.queryId == 0) revert QueryNotFound();
        if (query.isFinalized) revert QueryAlreadyFinalized();
        if (block.timestamp > query.submissionDeadline) revert SubmissionPeriodNotOver();
        if (query.hasSubmitted[_unitId]) revert AlreadyVoted(); // 'Voted' reused for 'already submitted'

        IntelligenceUnit storage unit = intelligenceUnits[_unitId];
        if (unit.unitController != _msgSender()) revert Unauthorized();

        // Optionally, verify the proof here. This could directly call `verifyIntelligenceOutput`
        // if the component is designed as a standard DIU output.
        // For now, assuming proof accompanies the hash and is handled off-chain or by oracle.
        
        query.submittedComponents[_unitId] = _componentHash;
        query.hasSubmitted[_unitId] = true;
        unit.lastActivityTimestamp = block.timestamp; // Mark activity

        emit CollectiveInsightComponentSubmitted(_queryId, _unitId, _componentHash);
    }

    /**
     * @dev Aggregates and finalizes the collective insight from submitted components.
     *      This aggregation logic is complex and would typically happen off-chain with an on-chain commit by an oracle/governor.
     * @param _queryId The ID of the collective intelligence query.
     */
    function finalizeCollectiveInsight(uint256 _queryId) external checkInitialized onlyGovernor {
        CollectiveInsightQuery storage query = collectiveInsightQueries[_queryId];
        if (query.queryId == 0) revert QueryNotFound();
        if (query.isFinalized) revert QueryAlreadyFinalized();
        if (block.timestamp <= query.submissionDeadline) revert SubmissionPeriodNotOver();

        // Conceptual off-chain aggregation logic:
        // 1. Fetch all submitted components for this query.
        // 2. Query reputation scores for each submitting DIU.
        // 3. Aggregate components, potentially weighting by reputation, to compute a final collective insight.
        // For on-chain, this `finalInsightHash` would be the result of this off-chain process,
        // submitted by the governor/an oracle.
        bytes32 finalHash = keccak256(abi.encodePacked("SimulatedFinalInsightForQuery", _queryId, block.timestamp)); // Placeholder

        query.finalInsightHash = finalHash;
        query.isFinalized = true;

        emit CollectiveInsightFinalized(_queryId, finalHash);
    }

    // --- VII. View Functions ---

    /**
     * @dev Returns the current reputation score of a specific DIU.
     * @param _unitId The ID of the DIU.
     * @return The DIU's current reputation score.
     */
    function getUnitReputation(uint256 _unitId) public view checkInitialized returns (int256) {
        return intelligenceUnits[_unitId].reputationScore;
    }

    /**
     * @dev Calculates and returns the effective voting weight of a DAO member.
     *      This is augmented by the reputation of active DIUs they control.
     * @param _voter The address of the DAO member.
     * @return The calculated effective voting weight.
     */
    function getEffectiveVotingWeight(address _voter) public view checkInitialized returns (uint256) {
        uint256 baseVotingPower = governanceToken.balanceOf(_voter);
        uint256 totalReputationInfluence = 0;

        // Factor in reputation of DIUs controlled by the voter
        uint256[] memory unitIds = controllerToUnitIds[_voter];
        for (uint256 i = 0; i < unitIds.length; i++) {
            if (intelligenceUnits[unitIds[i]].isActive) {
                // Positive reputation adds to voting power
                if (intelligenceUnits[unitIds[i]].reputationScore > 0) {
                    totalReputationInfluence += uint256(intelligenceUnits[unitIds[i]].reputationScore);
                }
            }
        }

        // Apply a factor to reputation influence, adjustable by governance.
        uint256 effectiveReputationPower = totalReputationInfluence * defaultVotingWeightFactor;

        // The effective voting weight is the sum of base token power and reputation-derived power.
        return baseVotingPower + effectiveReputationPower;
    }

    // --- VIII. Administration ---
    
    /**
     * @dev Allows the current governor to transfer governorship to another address.
     *      This would typically be done via a DAO vote after initialization.
     * @param _newGovernor The address of the new governor.
     */
    function transferGovernor(address _newGovernor) external onlyGovernor {
        if (_newGovernor == address(0)) revert InvalidZeroAddress();
        governor = _newGovernor;
    }

    /**
     * @dev Allows the governor to set a new reputation oracle address.
     * @param _newOracle The address of the new reputation oracle.
     */
    function setReputationOracle(address _newOracle) external onlyGovernor {
        if (_newOracle == address(0)) revert InvalidZeroAddress();
        reputationOracle = _newOracle;
    }
}
```