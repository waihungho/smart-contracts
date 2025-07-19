Here's a Solidity smart contract for "Synthetica Nexus," an autonomous collective intelligence protocol, designed with advanced concepts, creative functions, and trendy elements, while aiming to be distinct from common open-source implementations.

**Synthetica Nexus: An Autonomous Collective Intelligence Protocol**

This protocol aims to create a self-evolving on-chain system by leveraging decentralized contributions of "Knowledge Primitives" (KPs). KPs are essentially proposals for new, verifiable, and callable external smart contract modules. The community, weighted by their reputation, evaluates these KPs. Approved KPs are integrated into the protocol's "Synthetica Core Logic," making the protocol's capabilities dynamic and extensible over time.

**Outline:**

I.  **Core Infrastructure & Configuration:** Manages essential protocol settings and state, including pausing mechanisms and owner controls.
II. **Knowledge Primitive (KP) Lifecycle Management:** Facilitates the submission, tracking, and basic management of proposed on-chain modules (KPs).
III. **Adaptive Consensus & Evaluation System:** Implements a sophisticated, reputation-weighted mechanism for community evaluation and approval of KPs. This is the "collective intelligence" aspect.
IV. **Synthetica Core Logic Integration:** Manages the active set of approved KPs, making them callable parts of the protocol's collective intelligence.
V.  **Reputation & Reward Mechanism:** Governs the issuance of Synthetica Reputation SBTs (Soulbound Tokens) and Synthetica Tokens as incentives for participation and contribution.
VI. **Treasury & Funding Management:** Handles the protocol's accumulated funds (ETH and ERC-20) and their distribution.
VII. **Governance & Upgradability:** Provides mechanisms for protocol evolution through decentralized decision-making via reputation-weighted proposals.

**Function Summary:**

**I. Core Infrastructure & Configuration**
1.  `constructor(address _syntheticaToken, address _syntheticaReputationSBT)`: Initializes the contract by setting addresses for the utility token and the reputation Soulbound Token (SBT). Sets the initial protocol owner.
2.  `updateProtocolParameters(uint256 _minReputationToSubmitKP, uint256 _evaluationPeriod, uint256 _minVotesRequired, uint256 _passThresholdPercentage, uint256 _rewardPerSuccessfulEvaluation, uint256 _rewardPerIntegratedKP)`: Allows governance to update key operational parameters, influencing KP submission, evaluation, and reward mechanics.
3.  `pause()`: Pauses the contract, restricting most state-changing operations to prevent unforeseen issues. Callable only by governance.
4.  `unpause()`: Unpauses the contract, resuming normal operations. Callable only by governance.

**II. Knowledge Primitive (KP) Lifecycle Management**
5.  `submitKnowledgePrimitive(address _kpModuleAddress, string memory _description, bytes32 _moduleHash)`: Enables users with a minimum reputation to propose a new `SyntheticaModule` contract address, providing a description and a unique hash of its bytecode for verification.
6.  `getKnowledgePrimitive(uint256 _kpId)`: Retrieves comprehensive details about a specific Knowledge Primitive based on its unique ID.
7.  `listPendingKnowledgePrimitives()`: Returns an array of IDs for all KPs currently in the 'Pending' state, awaiting community evaluation.
8.  `revokeKnowledgePrimitiveSubmission(uint256 _kpId)`: Allows the original submitter to withdraw their pending KP before the evaluation period concludes.

**III. Adaptive Consensus & Evaluation System**
9.  `evaluateKnowledgePrimitive(uint256 _kpId, bool _voteYes)`: Allows users possessing sufficient reputation to cast a 'yes' or 'no' vote on a pending KP. The voter's influence is directly proportional to their current reputation score.
10. `finalizeKnowledgePrimitiveEvaluation(uint256 _kpId)`: Initiates the finalization process for a KP's evaluation. It calculates the weighted consensus score and determines if the KP passes or fails based on predefined thresholds and vote counts. Automatically triggers integration if passed.
11. `getKPEvaluationStatus(uint256 _kpId)`: Provides the current lifecycle status (Pending, Passed, Failed, Integrated, Deactivated, Revoked) of a Knowledge Primitive.
12. `getKPWeightedScore(uint256 _kpId)`: Returns the current sum of weighted 'yes' votes for a specific KP, reflecting its community support.
13. `getKPVoteDetails(uint256 _kpId, address _voter)`: Checks if a specific user has voted on a KP and reveals their vote choice if they have.

**IV. Synthetica Core Logic Integration**
14. `integrateKnowledgePrimitive(uint256 _kpId)`: Integrates a successfully evaluated and 'Passed' KP into the active set of Synthetica Core Logic modules. This makes the KP's underlying module contract address callable via the `invokeSyntheticaCoreLogic` function. Primarily called internally, but governance can also trigger.
15. `deactivateKnowledgePrimitive(uint256 _kpId)`: Removes an integrated KP from the callable Synthetica Core Logic. This is used for modules found to be faulty, obsolete, or malicious, and is callable only by governance.
16. `getIntegratedKnowledgePrimitives()`: Returns an array of IDs for all currently active and integrated KPs, representing the protocol's current capabilities.
17. `invokeSyntheticaCoreLogic(uint256 _kpId, bytes memory _callData)`: A generic dispatcher function that allows external callers to execute functions on an approved and integrated `SyntheticaModule`. The `_callData` is forwarded to the specific module's contract.

**V. Reputation & Reward Mechanism**
18. `claimEvaluationRewards(uint256[] memory _kpIds)`: Enables evaluators to claim rewards (Synthetica Tokens and/or Reputation SBTs) for casting accurate votes on finalized KPs (i.e., voting 'yes' for passed KPs or 'no' for failed KPs).
19. `claimKnowledgePrimitiveRewards(uint256 _kpId)`: Allows the creator of a successfully integrated KP to claim their reward in Synthetica Tokens and potentially additional Reputation SBTs.
20. `getUserReputation(address _user)`: Queries the `SyntheticaReputationSBT` contract to return the reputation score of a specified user.
21. `burnReputation(uint256 _amount)`: Allows a user to intentionally burn a portion of their reputation, potentially to participate in specific, reputation-gated protocol features or to influence certain ephemeral actions.

**VI. Treasury & Funding Management**
22. `receive()`: A fallback function allowing direct deposits of native blockchain currency (e.g., Ether) into the protocol's treasury.
23. `depositTreasury(address _tokenAddress, uint256 _amount)`: Facilitates deposits of ERC-20 tokens into the protocol's treasury. The caller must pre-approve the contract.
24. `withdrawTreasuryFunds(address _tokenAddress, uint256 _amount, address _recipient)`: Allows governance to withdraw funds (both native currency and ERC-20 tokens) from the treasury for protocol operations, development, or approved initiatives.

**VII. Governance & Upgradability**
25. `proposeGovernanceAction(bytes memory _actionData, string memory _description)`: Allows users with a higher reputation threshold to propose a governance action, specified as ABI-encoded call data, along with a descriptive explanation.
26. `voteOnGovernanceAction(uint256 _proposalId, bool _voteFor)`: Enables reputation-weighted voting ('for' or 'against') on pending governance proposals.
27. `finalizeGovernanceAction(uint256 _proposalId)`: Triggers the execution of a passed governance proposal if the voting period has ended and the required consensus (min votes, threshold percentage) has been met.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Using IERC721 as a base for SBT, but noting non-transferability

/**
 * @title Synthetica Nexus: An Autonomous Collective Intelligence Protocol
 * @dev This contract orchestrates the submission, evaluation, and integration of "Knowledge Primitives" (KPs),
 *      allowing the protocol to dynamically evolve its on-chain capabilities. It features an adaptive,
 *      reputation-weighted consensus mechanism for KP approval, and a reward system for contributors.
 *      The "collective intelligence" aspect refers to the community-driven approval and integration of
 *      external, verifiable modules, effectively making the protocol's core logic adaptable and extensible.
 */

// --- OUTLINE ---
// I. Core Infrastructure & Configuration: Manages essential protocol settings and state, including pausing mechanisms and owner controls.
// II. Knowledge Primitive (KP) Lifecycle Management: Facilitates the submission, tracking, and basic management of proposed on-chain modules (KPs).
// III. Adaptive Consensus & Evaluation System: Implements a sophisticated, reputation-weighted mechanism for community evaluation and approval of KPs.
// IV. Synthetica Core Logic Integration: Manages the active set of approved KPs, making them callable parts of the protocol's collective intelligence.
// V. Reputation & Reward Mechanism: Governs the issuance of Synthetica Reputation SBTs and Synthetica Tokens as incentives for participation and contribution.
// VI. Treasury & Funding Management: Handles the protocol's accumulated funds and their distribution.
// VII. Governance & Upgradability: Provides mechanisms for protocol evolution through decentralized decision-making.

// --- FUNCTION SUMMARY ---

// I. Core Infrastructure & Configuration
// 1. constructor(address _syntheticaToken, address _syntheticaReputationSBT): Initializes the contract with addresses for the utility token and reputation SBT. Sets initial protocol owner.
// 2. updateProtocolParameters(uint256 _minReputationToSubmitKP, uint256 _evaluationPeriod, uint256 _minVotesRequired, uint256 _passThresholdPercentage, uint256 _rewardPerSuccessfulEvaluation, uint256 _rewardPerIntegratedKP): Allows governance to update key protocol parameters influencing KP submission, evaluation, and rewards.
// 3. pause(): Pauses the contract, restricting most state-changing operations, callable only by governance.
// 4. unpause(): Unpauses the contract, resuming normal operations, callable only by governance.

// II. Knowledge Primitive (KP) Lifecycle Management
// 5. submitKnowledgePrimitive(address _kpModuleAddress, string memory _description, bytes32 _moduleHash): Allows a user to propose a new SyntheticaModule contract address, along with its description and a unique hash of its bytecode for verification. Requires a minimum reputation.
// 6. getKnowledgePrimitive(uint256 _kpId): Retrieves detailed information about a specific Knowledge Primitive by its ID.
// 7. listPendingKnowledgePrimitives(): Returns an array of IDs for KPs currently awaiting community evaluation.
// 8. revokeKnowledgePrimitiveSubmission(uint256 _kpId): Allows the original submitter to withdraw their pending KP before evaluation completion.

// III. Adaptive Consensus & Evaluation System
// 9. evaluateKnowledgePrimitive(uint256 _kpId, bool _voteYes): Enables users with sufficient reputation to cast a 'yes' or 'no' vote on a pending KP. Reputation weight determines vote influence.
// 10. finalizeKnowledgePrimitiveEvaluation(uint256 _kpId): Triggers the finalization process for a KP's evaluation. Calculates the weighted score and determines if the KP passes or fails based on thresholds and vote counts.
// 11. getKPEvaluationStatus(uint256 _kpId): Returns the current evaluation status (Pending, Passed, Failed, Integrated) of a KP.
// 12. getKPWeightedScore(uint256 _kpId): Returns the current aggregate weighted score for a KP based on 'yes' votes.
// 13. getKPVoteDetails(uint256 _kpId, address _voter): Returns the vote details for a specific voter on a given KP.

// IV. Synthetica Core Logic Integration
// 14. integrateKnowledgePrimitive(uint256 _kpId): Integrates a successfully evaluated and passed KP into the active set of Synthetica Core Logic modules. This makes the _kpModuleAddress callable via the invokeSyntheticaCoreLogic function. Only callable by governance or after auto-integration via finalizeKnowledgePrimitiveEvaluation for passed KPs.
// 15. deactivateKnowledgePrimitive(uint256 _kpId): Deactivates an integrated KP, removing it from the callable Synthetica Core Logic (e.g., due to bug discovery or obsolescence). Callable only by governance.
// 16. getIntegratedKnowledgePrimitives(): Returns an array of IDs for all currently active and integrated KPs.
// 17. invokeSyntheticaCoreLogic(uint256 _kpId, bytes memory _callData): A generic dispatcher function that allows external callers to execute an approved and integrated SyntheticaModule's function. The _callData is forwarded to the specific module.

// V. Reputation & Reward Mechanism
// 18. claimEvaluationRewards(uint256[] memory _kpIds): Allows evaluators to claim rewards (Synthetica Tokens and/or Reputation SBTs) for accurately participating in evaluations of finalized KPs.
// 19. claimKnowledgePrimitiveRewards(uint256 _kpId): Allows the creator of a successfully integrated KP to claim their reward in Synthetica Tokens.
// 20. getUserReputation(address _user): Returns the reputation score of a specific user. (This will query the SyntheticaReputationSBT contract).
// 21. burnReputation(uint256 _amount): Allows a user to optionally burn their reputation for specific protocol actions (e.g., to influence a specific vote, or access special features - conceptual).

// VI. Treasury & Funding Management
// 22. receive(): Allows anyone to deposit native blockchain currency (e.g., ETH) into the protocol's treasury.
// 23. depositTreasury(address _tokenAddress, uint256 _amount): Allows anyone to deposit ERC-20 tokens into the protocol's treasury.
// 24. withdrawTreasuryFunds(address _tokenAddress, uint256 _amount, address _recipient): Allows governance to withdraw funds from the treasury for protocol operations, development, or specific community-approved initiatives.

// VII. Governance & Upgradability
// 25. proposeGovernanceAction(bytes memory _actionData, string memory _description): Allows users with sufficient reputation to propose a governance action (e.g., parameter change, KP deactivation).
// 26. voteOnGovernanceAction(uint256 _proposalId, bool _voteFor): Allows users with reputation to vote on pending governance proposals.
// 27. finalizeGovernanceAction(uint256 _proposalId): Triggers the execution of a passed governance proposal.

// --- INTERFACES (Conceptual / Placeholder) ---

/**
 * @dev Placeholder interface for the Synthetica Utility Token.
 *      Assumed to be an ERC-20 compliant token, with a `mint` function for rewards.
 */
interface ISyntheticaToken is IERC20 {
    function mint(address to, uint256 amount) external;
}

/**
 * @dev Placeholder interface for the Synthetica Reputation Soulbound Token (SBT).
 *      Assumed to be an ERC-721 compliant token, but non-transferable (soulbound).
 *      `balanceOf` is used to represent the reputation score. `mint` and `burn`
 *      functions are included for internal reputation management.
 */
interface ISyntheticaReputationSBT is IERC721 {
    function mint(address to, uint256 amount) external; // Mints 'amount' reputation points
    function burn(address from, uint256 amount) external; // Burns 'amount' reputation points
    function balanceOf(address owner) external view returns (uint256); // Represents reputation score
}

/**
 * @dev Interface that all Knowledge Primitive Modules must implement.
 *      These are external contracts that perform specific functions,
 *      and the SyntheticaNexus interacts with them via this interface.
 */
interface ISyntheticaModule {
    // A generic entry point. In a real system, KPs would likely have more specific, well-typed interfaces.
    function execute(bytes calldata _data) external returns (bytes memory);
    function getModuleInfo() external view returns (string memory name, string memory version);
}

contract SyntheticaNexus is Ownable, Pausable {

    // --- ENUMS & STRUCTS ---

    enum KPStatus {
        Pending,      // Awaiting evaluation votes
        Passed,       // Passed evaluation, ready for integration
        Failed,       // Failed evaluation
        Integrated,   // Successfully integrated and active in core logic
        Deactivated,  // Integrated but later deactivated by governance
        Revoked       // Revoked by creator before evaluation
    }

    struct KnowledgePrimitive {
        address creator;
        address kpModuleAddress; // Address of the external module contract
        bytes32 moduleHash;     // keccak256 hash of the module's bytecode for verification
        string description;
        uint256 submissionTime;
        uint256 evaluationEndTime;
        uint256 totalWeightedYesVotes;
        uint256 totalWeightedNoVotes;
        uint256 uniqueVotersCount; // To track if minVotesRequired is met
        KPStatus status;
        bool claimedByCreator; // Flag to prevent double claiming of creator rewards
    }

    struct GovernanceProposal {
        address proposer;
        bytes actionData; // ABI-encoded call data for the action to be executed (e.g., updateProtocolParameters)
        string description;
        uint256 submissionTime;
        uint256 votingEndTime;
        uint256 totalWeightedForVotes;
        uint256 totalWeightedAgainstVotes;
        uint256 uniqueVotersCount;
        bool executed; // Flag to prevent double execution
    }

    // --- STATE VARIABLES ---

    ISyntheticaToken public syntheticaToken;
    ISyntheticaReputationSBT public syntheticaReputationSBT;

    uint256 public nextKpId;
    mapping(uint256 => KnowledgePrimitive) public knowledgePrimitives;
    uint256[] public pendingKpIds;     // List of KPs currently in 'Pending' status
    uint256[] public integratedKpIds;  // List of KPs currently in 'Integrated' status

    // Mappings for KP evaluation voting
    mapping(uint256 => mapping(address => bool)) public hasVotedOnKp; // kpId => voterAddress => voted status
    mapping(uint256 => mapping(address => bool)) public kpVoteChoice; // kpId => voterAddress => true for Yes, false for No

    // Governance parameters affecting KP evaluation and rewards
    uint256 public minReputationToSubmitKP;
    uint256 public evaluationPeriod; // Duration in seconds for KP & Governance proposal evaluation/voting
    uint256 public minVotesRequired; // Minimum unique voters required for a KP or proposal to be finalized
    uint256 public passThresholdPercentage; // E.g., 60 for 60% of total weighted 'yes' votes
    uint256 public rewardPerSuccessfulEvaluation; // STK tokens for accurate KP evaluation
    uint256 public rewardPerIntegratedKP;       // STK tokens for KP creator upon integration

    uint256 public nextProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    // Mappings for Governance proposal voting (similar to KP voting)
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal;
    mapping(uint256 => mapping(address => bool)) public proposalVoteChoice;

    // --- EVENTS ---

    event KPSubmitted(uint256 indexed kpId, address indexed creator, address kpModuleAddress, string description);
    event KPEvaluated(uint256 indexed kpId, address indexed evaluator, bool voteYes, uint256 reputationWeight);
    event KPEvaluationFinalized(uint256 indexed kpId, KPStatus newStatus, uint256 totalWeightedYesVotes, uint256 totalWeightedNoVotes);
    event KPIntegrated(uint256 indexed kpId, address kpModuleAddress);
    event KPDeactivated(uint256 indexed kpId, address kpModuleAddress);
    event KPRewardsClaimed(uint256 indexed kpId, address indexed recipient, uint256 amount);
    event EvaluationRewardsClaimed(address indexed evaluator, uint256 totalAmount, uint256 numberOfKPsClaimed); // Changed to indicate total amount and count
    event ProtocolParametersUpdated(uint256 minReputationToSubmitKP, uint256 evaluationPeriod, uint256 minVotesRequired, uint256 passThresholdPercentage, uint256 rewardPerSuccessfulEvaluation, uint256 rewardPerIntegratedKP);
    event TreasuryDeposited(address indexed depositor, address indexed tokenAddress, uint256 amount); // Added tokenAddress
    event TreasuryWithdrawn(address indexed recipient, address indexed tokenAddress, uint256 amount);
    event GovernanceProposalSubmitted(uint256 indexed proposalId, address indexed proposer, string description);
    event GovernanceVoteCasted(uint256 indexed proposalId, address indexed voter, bool voteFor, uint256 reputationWeight);
    event GovernanceProposalFinalized(uint256 indexed proposalId, bool executedSuccessfully); // Renamed for clarity
    event KPRevoked(uint256 indexed kpId, address indexed revoker);
    event ReputationBurned(address indexed user, uint256 amount);

    // --- MODIFIERS ---

    // In a more complex system, `onlyOwner` would typically be replaced by a dedicated
    // governance contract address (e.g., a DAO contract) that manages the protocol.
    // For this example, `onlyOwner` serves as a placeholder for the governance entity.
    modifier onlyGovernance() {
        require(owner() == _msgSender(), "SyntheticaNexus: Not governance entity");
        _;
    }

    modifier onlyReputable(uint256 _minRep) {
        require(syntheticaReputationSBT.balanceOf(_msgSender()) >= _minRep, "SyntheticaNexus: Insufficient reputation");
        _;
    }

    // --- CONSTRUCTOR ---

    constructor(address _syntheticaToken, address _syntheticaReputationSBT) Ownable(_msgSender()) Pausable() {
        require(_syntheticaToken != address(0), "SyntheticaToken address cannot be zero");
        require(_syntheticaReputationSBT != address(0), "SyntheticaReputationSBT address cannot be zero");

        syntheticaToken = ISyntheticaToken(_syntheticaToken);
        syntheticaReputationSBT = ISyntheticaReputationSBT(_syntheticaReputationSBT);

        // Set initial parameters for the protocol.
        // These can be updated later via governance proposals.
        minReputationToSubmitKP = 100; // Example: 100 reputation points to submit a KP
        evaluationPeriod = 7 days;     // KPs and proposals are open for 7 days of voting
        minVotesRequired = 3;          // At least 3 unique voters for a decision to be valid
        passThresholdPercentage = 60;  // 60% weighted 'yes'/'for' votes required to pass
        rewardPerSuccessfulEvaluation = 10 * (10 ** 18); // 10 tokens per correct evaluation
        rewardPerIntegratedKP = 100 * (10 ** 18);       // 100 tokens for KP creator if integrated

        nextKpId = 1;
        nextProposalId = 1;
    }

    // --- I. Core Infrastructure & Configuration ---

    /**
     * @dev Allows governance to update key protocol parameters that control KP submission,
     *      evaluation, and rewards. This enables the protocol to adapt and evolve.
     * @param _minReputationToSubmitKP Minimum reputation required to submit a KP.
     * @param _evaluationPeriod Duration in seconds for KP and governance proposal evaluation/voting.
     * @param _minVotesRequired Minimum unique voters required for a KP or proposal to be finalized.
     * @param _passThresholdPercentage Percentage of total weighted 'yes'/'for' votes required for a KP/proposal to pass.
     * @param _rewardPerSuccessfulEvaluation Amount of Synthetica Tokens rewarded for an accurate evaluation vote.
     * @param _rewardPerIntegratedKP Amount of Synthetica Tokens rewarded to the creator of an integrated KP.
     */
    function updateProtocolParameters(
        uint256 _minReputationToSubmitKP,
        uint256 _evaluationPeriod,
        uint256 _minVotesRequired,
        uint256 _passThresholdPercentage,
        uint256 _rewardPerSuccessfulEvaluation,
        uint256 _rewardPerIntegratedKP
    ) external onlyGovernance whenNotPaused {
        require(_evaluationPeriod > 0, "Evaluation period must be positive");
        require(_minVotesRequired > 0, "Minimum votes required must be positive");
        require(_passThresholdPercentage > 0 && _passThresholdPercentage <= 100, "Pass threshold must be between 1 and 100");

        minReputationToSubmitKP = _minReputationToSubmitKP;
        evaluationPeriod = _evaluationPeriod;
        minVotesRequired = _minVotesRequired;
        passThresholdPercentage = _passThresholdPercentage;
        rewardPerSuccessfulEvaluation = _rewardPerSuccessfulEvaluation;
        rewardPerIntegratedKP = _rewardPerIntegratedKP;

        emit ProtocolParametersUpdated(
            minReputationToSubmitKP,
            evaluationPeriod,
            minVotesRequired,
            passThresholdPercentage,
            rewardPerSuccessfulEvaluation,
            rewardPerIntegratedKP
        );
    }

    /**
     * @dev Pauses the contract operations.
     *      Most state-changing functions will revert when the contract is paused.
     *      Callable only by governance.
     */
    function pause() external onlyGovernance {
        _pause();
    }

    /**
     * @dev Unpauses the contract operations.
     *      Callable only by governance.
     */
    function unpause() external onlyGovernance {
        _unpause();
    }

    // --- II. Knowledge Primitive (KP) Lifecycle Management ---

    /**
     * @dev Allows a user to propose a new Knowledge Primitive (KP) for community evaluation.
     *      Requires the submitter to have a minimum reputation score.
     *      The `_kpModuleAddress` must be a pre-deployed contract implementing `ISyntheticaModule`.
     *      The `_moduleHash` should be the `keccak256(bytecode)` of the `_kpModuleAddress` for off-chain verification.
     * @param _kpModuleAddress The address of the external `SyntheticaModule` contract.
     * @param _description A concise description explaining the KP's functionality.
     * @param _moduleHash The `keccak256` hash of the module's bytecode for integrity verification.
     */
    function submitKnowledgePrimitive(
        address _kpModuleAddress,
        string memory _description,
        bytes32 _moduleHash
    ) external whenNotPaused onlyReputable(minReputationToSubmitKP) {
        require(_kpModuleAddress != address(0), "KP module address cannot be zero");
        require(bytes(_description).length > 0, "Description cannot be empty");

        // Basic check for deployed code. In a full system, `extcodehash(_kpModuleAddress) == _moduleHash`
        // would be a critical security check to ensure the proposed code matches the hash.
        uint256 codeSize;
        assembly { codeSize := extcodesize(_kpModuleAddress) }
        require(codeSize > 0, "KP module address has no deployed code");

        uint256 kpId = nextKpId++;
        KnowledgePrimitive storage newKp = knowledgePrimitives[kpId];
        newKp.creator = _msgSender();
        newKp.kpModuleAddress = _kpModuleAddress;
        newKp.moduleHash = _moduleHash;
        newKp.description = _description;
        newKp.submissionTime = block.timestamp;
        newKp.evaluationEndTime = block.timestamp + evaluationPeriod;
        newKp.status = KPStatus.Pending;
        newKp.claimedByCreator = false;

        pendingKpIds.push(kpId); // Add to the list of KPs awaiting evaluation

        emit KPSubmitted(kpId, _msgSender(), _kpModuleAddress, _description);
    }

    /**
     * @dev Retrieves detailed information about a specific Knowledge Primitive.
     * @param _kpId The ID of the Knowledge Primitive.
     * @return All relevant details of the KP, including creator, module address, description,
     *         current status, and evaluation metrics.
     */
    function getKnowledgePrimitive(uint256 _kpId)
        external
        view
        returns (
            address creator,
            address kpModuleAddress,
            bytes32 moduleHash,
            string memory description,
            uint256 submissionTime,
            uint256 evaluationEndTime,
            uint256 totalWeightedYesVotes,
            uint256 totalWeightedNoVotes,
            uint256 uniqueVotersCount,
            KPStatus status,
            bool claimedByCreator
        )
    {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.creator != address(0), "KP does not exist"); // Check if KP ID is valid
        return (
            kp.creator,
            kp.kpModuleAddress,
            kp.moduleHash,
            kp.description,
            kp.submissionTime,
            kp.evaluationEndTime,
            kp.totalWeightedYesVotes,
            kp.totalWeightedNoVotes,
            kp.uniqueVotersCount,
            kp.status,
            kp.claimedByCreator
        );
    }

    /**
     * @dev Returns an array of IDs for Knowledge Primitives currently in the 'Pending' evaluation state.
     *      This list can be used by front-ends to display active evaluation opportunities.
     * @return An array of KP IDs that are currently pending.
     */
    function listPendingKnowledgePrimitives() external view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < pendingKpIds.length; i++) {
            if (knowledgePrimitives[pendingKpIds[i]].status == KPStatus.Pending) {
                count++;
            }
        }

        uint256[] memory currentPending = new uint256[](count);
        uint256 j = 0;
        for (uint256 i = 0; i < pendingKpIds.length; i++) {
            if (knowledgePrimitives[pendingKpIds[i]].status == KPStatus.Pending) {
                currentPending[j] = pendingKpIds[i];
                j++;
            }
        }
        return currentPending;
    }

    /**
     * @dev Allows the original submitter to revoke their pending KP submission.
     *      This is only possible if the KP is still in 'Pending' status and its
     *      evaluation period has not yet ended.
     * @param _kpId The ID of the Knowledge Primitive to revoke.
     */
    function revokeKnowledgePrimitiveSubmission(uint256 _kpId) external whenNotPaused {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.creator != address(0), "KP does not exist");
        require(kp.creator == _msgSender(), "SyntheticaNexus: Not KP creator");
        require(kp.status == KPStatus.Pending, "SyntheticaNexus: KP not in pending status");
        require(block.timestamp < kp.evaluationEndTime, "SyntheticaNexus: Evaluation period has ended");

        kp.status = KPStatus.Revoked;

        // Remove the KP ID from the pendingKpIds array for efficiency (linear scan, could be optimized for large arrays)
        for (uint256 i = 0; i < pendingKpIds.length; i++) {
            if (pendingKpIds[i] == _kpId) {
                pendingKpIds[i] = pendingKpIds[pendingKpIds.length - 1]; // Replace with last element
                pendingKpIds.pop(); // Remove last element
                break;
            }
        }

        emit KPRevoked(_kpId, _msgSender());
    }

    // --- III. Adaptive Consensus & Evaluation System ---

    /**
     * @dev Enables users with sufficient reputation to cast a 'yes' or 'no' vote on a pending KP.
     *      A user's vote influence is weighted by their current `SyntheticaReputationSBT` balance.
     *      This mechanism forms the core of the adaptive consensus.
     * @param _kpId The ID of the Knowledge Primitive to evaluate.
     * @param _voteYes True for a 'yes' vote (in favor of integration), false for a 'no' vote.
     */
    function evaluateKnowledgePrimitive(uint256 _kpId, bool _voteYes) external whenNotPaused {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.creator != address(0), "KP does not exist");
        require(kp.status == KPStatus.Pending, "KP is not in pending status");
        require(block.timestamp < kp.evaluationEndTime, "Evaluation period has ended");
        require(!hasVotedOnKp[_kpId][_msgSender()], "Already voted on this KP");
        require(_msgSender() != kp.creator, "Creator cannot vote on their own KP");

        uint256 voterReputation = syntheticaReputationSBT.balanceOf(_msgSender());
        require(voterReputation > 0, "Evaluator must have reputation to vote"); // Minimum reputation to vote could be minReputationToSubmitKP / X

        if (_voteYes) {
            kp.totalWeightedYesVotes += voterReputation;
        } else {
            kp.totalWeightedNoVotes += voterReputation;
        }
        kp.uniqueVotersCount++;
        hasVotedOnKp[_kpId][_msgSender()] = true; // Mark as voted
        kpVoteChoice[_kpId][_msgSender()] = _voteYes; // Record vote choice

        emit KPEvaluated(_kpId, _msgSender(), _voteYes, voterReputation);
    }

    /**
     * @dev Triggers the finalization process for a KP's evaluation.
     *      Determines if the KP passes or fails based on weighted votes, minimum voters, and threshold.
     *      If the KP passes, it is automatically integrated into the Synthetica Core Logic.
     *      This function can be called by anyone after the evaluation period concludes.
     * @param _kpId The ID of the Knowledge Primitive to finalize.
     */
    function finalizeKnowledgePrimitiveEvaluation(uint256 _kpId) external whenNotPaused {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.creator != address(0), "KP does not exist");
        require(kp.status == KPStatus.Pending, "KP is not in pending status");
        require(block.timestamp >= kp.evaluationEndTime, "Evaluation period has not ended yet");
        require(kp.uniqueVotersCount >= minVotesRequired, "Not enough unique voters to finalize");

        uint256 totalWeightedVotes = kp.totalWeightedYesVotes + kp.totalWeightedNoVotes;
        bool passed = false;

        if (totalWeightedVotes > 0) { // Avoid division by zero if no votes were cast
            uint256 yesPercentage = (kp.totalWeightedYesVotes * 100) / totalWeightedVotes;
            if (yesPercentage >= passThresholdPercentage) {
                passed = true;
            }
        }

        if (passed) {
            kp.status = KPStatus.Passed;
            // Automatically integrate the KP if it passes evaluation
            _integrateKnowledgePrimitive(_kpId);
        } else {
            kp.status = KPStatus.Failed;
        }

        // Remove from pendingKpIds as it's no longer pending
        for (uint256 i = 0; i < pendingKpIds.length; i++) {
            if (pendingKpIds[i] == _kpId) {
                pendingKpIds[i] = pendingKpIds[pendingKpIds.length - 1];
                pendingKpIds.pop();
                break;
            }
        }

        emit KPEvaluationFinalized(_kpId, kp.status, kp.totalWeightedYesVotes, kp.totalWeightedNoVotes);
    }

    /**
     * @dev Returns the current evaluation status of a Knowledge Primitive.
     * @param _kpId The ID of the Knowledge Primitive.
     * @return The current status as a `KPStatus` enum value.
     */
    function getKPEvaluationStatus(uint256 _kpId) external view returns (KPStatus) {
        return knowledgePrimitives[_kpId].status;
    }

    /**
     * @dev Returns the current aggregate weighted 'yes' score for a Knowledge Primitive.
     *      This represents the total reputation weight of 'yes' votes received.
     * @param _kpId The ID of the Knowledge Primitive.
     * @return The total weighted 'yes' votes.
     */
    function getKPWeightedScore(uint256 _kpId) external view returns (uint256) {
        return knowledgePrimitives[_kpId].totalWeightedYesVotes;
    }

    /**
     * @dev Returns the voting details for a specific voter on a given Knowledge Primitive.
     * @param _kpId The ID of the Knowledge Primitive.
     * @param _voter The address of the voter.
     * @return `hasVoted` A boolean indicating if the voter has cast a vote.
     * @return `voteChoice` The recorded vote choice (true for yes, false for no) if they voted.
     */
    function getKPVoteDetails(uint256 _kpId, address _voter) external view returns (bool hasVoted, bool voteChoice) {
        return (hasVotedOnKp[_kpId][_voter], kpVoteChoice[_kpId][_voter]);
    }

    // --- IV. Synthetica Core Logic Integration ---

    /**
     * @dev Internal function to integrate a successfully evaluated Knowledge Primitive.
     *      This adds the KP's module address to the list of callable core logic modules.
     *      It's automatically called by `finalizeKnowledgePrimitiveEvaluation` if a KP passes.
     * @param _kpId The ID of the KP to integrate.
     */
    function _integrateKnowledgePrimitive(uint256 _kpId) internal {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.status == KPStatus.Passed, "KP not in Passed status"); // Ensure only passed KPs are integrated

        kp.status = KPStatus.Integrated;
        integratedKpIds.push(_kpId); // Add to the list of integrated KPs

        emit KPIntegrated(_kpId, kp.kpModuleAddress);
    }

    /**
     * @dev Allows governance to explicitly integrate a KP that has passed evaluation.
     *      This function can be used if auto-integration is disabled or for manual override/management.
     * @param _kpId The ID of the KP to integrate.
     */
    function integrateKnowledgePrimitive(uint256 _kpId) external onlyGovernance whenNotPaused {
        _integrateKnowledgePrimitive(_kpId);
    }

    /**
     * @dev Deactivates an integrated KP, removing it from the callable Synthetica Core Logic.
     *      This is crucial for maintaining security and protocol health, allowing the removal
     *      of buggy, deprecated, or malicious modules. Callable only by governance.
     * @param _kpId The ID of the KP to deactivate.
     */
    function deactivateKnowledgePrimitive(uint256 _kpId) external onlyGovernance whenNotPaused {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.creator != address(0), "KP does not exist");
        require(kp.status == KPStatus.Integrated, "KP is not currently integrated");

        kp.status = KPStatus.Deactivated;

        // Remove the KP ID from the integratedKpIds array (linear scan, could be optimized for large arrays)
        for (uint256 i = 0; i < integratedKpIds.length; i++) {
            if (integratedKpIds[i] == _kpId) {
                integratedKpIds[i] = integratedKpIds[integratedKpIds.length - 1];
                integratedKpIds.pop();
                break;
            }
        }

        emit KPDeactivated(_kpId, kp.kpModuleAddress);
    }

    /**
     * @dev Returns an array of IDs for all currently active and integrated KPs.
     *      This represents the current set of capabilities of the Synthetica Nexus.
     * @return An array of KP IDs that are currently integrated.
     */
    function getIntegratedKnowledgePrimitives() external view returns (uint256[] memory) {
        return integratedKpIds;
    }

    /**
     * @dev A generic dispatcher function that allows external callers to execute an approved and integrated
     *      `SyntheticaModule`'s function. The `_callData` is forwarded directly to the specific module.
     *      This function is the primary interface for external applications to leverage the protocol's
     *      collective intelligence, by calling any of the community-approved modules.
     * @param _kpId The ID of the integrated Knowledge Primitive to invoke.
     * @param _callData The ABI-encoded call data (function signature and arguments) for the function to be executed on the module.
     * @return The raw bytes returned by the module's execution.
     */
    function invokeSyntheticaCoreLogic(uint256 _kpId, bytes memory _callData) external returns (bytes memory) {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.creator != address(0), "KP does not exist");
        require(kp.status == KPStatus.Integrated, "KP is not integrated or active"); // Only allow calls to active KPs

        // Create an interface instance for the module
        ISyntheticaModule module = ISyntheticaModule(kp.kpModuleAddress);

        // Forward the call to the module. Consider adding re-entrancy guards if modules handle funds or sensitive state.
        // It's also wise to implement gas limits for external module calls in a production system.
        (bool success, bytes memory result) = address(module).call(_callData);
        require(success, "Module execution failed"); // Revert if the module's call fails

        return result;
    }

    // --- V. Reputation & Reward Mechanism ---

    /**
     * @dev Allows evaluators to claim rewards (Synthetica Tokens and/or Reputation SBTs) for accurately
     *      participating in evaluations of finalized KPs. Rewards are based on correct predictions
     *      (e.g., voting 'yes' for a passed KP, or 'no' for a failed KP).
     * @param _kpIds An array of KP IDs for which the caller wants to claim rewards.
     */
    function claimEvaluationRewards(uint256[] memory _kpIds) external whenNotPaused {
        uint256 totalRewardAmount = 0;
        uint256 successfullyClaimedKPs = 0;
        address claimant = _msgSender();

        for (uint256 i = 0; i < _kpIds.length; i++) {
            uint256 kpId = _kpIds[i];
            KnowledgePrimitive storage kp = knowledgePrimitives[kpId];

            // Ensure KP exists, is finalized, and user voted on it
            if (kp.creator == address(0) || (kp.status == KPStatus.Pending || kp.status == KPStatus.Revoked) || !hasVotedOnKp[kpId][claimant]) {
                continue; // Skip invalid KPs or those not voted on
            }

            // Check if the user's vote was correct
            // The `hasVotedOnKp[kpId][claimant]` being `true` also serves as a "not yet claimed" flag for this specific KP.
            if ( (kpVoteChoice[kpId][claimant] && kp.status == KPStatus.Passed) ||
                 (!kpVoteChoice[kpId][claimant] && kp.status == KPStatus.Failed) )
            {
                totalRewardAmount += rewardPerSuccessfulEvaluation;
                successfullyClaimedKPs++;
                hasVotedOnKp[kpId][claimant] = false; // Mark this specific vote as claimed to prevent double claims
            }
        }

        require(totalRewardAmount > 0, "No rewards to claim for provided KPs or already claimed");

        syntheticaToken.mint(claimant, totalRewardAmount); // Mint STK tokens
        // Mint reputation SBTs as a bonus for good evaluations. Ratio example: 1 reputation per 1 STK (considering 10^18 precision)
        syntheticaReputationSBT.mint(claimant, totalRewardAmount / (10 ** 18));

        emit EvaluationRewardsClaimed(claimant, totalRewardAmount, successfullyClaimedKPs);
    }

    /**
     * @dev Allows the creator of a successfully integrated KP to claim their reward in Synthetica Tokens.
     *      This incentivizes valuable contributions to the protocol's collective intelligence.
     * @param _kpId The ID of the integrated KP for which to claim rewards.
     */
    function claimKnowledgePrimitiveRewards(uint256 _kpId) external whenNotPaused {
        KnowledgePrimitive storage kp = knowledgePrimitives[_kpId];
        require(kp.creator != address(0), "KP does not exist");
        require(kp.creator == _msgSender(), "SyntheticaNexus: Not KP creator");
        require(kp.status == KPStatus.Integrated, "KP is not integrated");
        require(!kp.claimedByCreator, "KP creator reward already claimed");

        kp.claimedByCreator = true; // Mark reward as claimed
        syntheticaToken.mint(kp.creator, rewardPerIntegratedKP);
        // Also grant additional reputation to the creator for a valuable contribution
        syntheticaReputationSBT.mint(kp.creator, rewardPerIntegratedKP / (10 ** 18));

        emit KPRewardsClaimed(_kpId, kp.creator, rewardPerIntegratedKP);
    }

    /**
     * @dev Returns the reputation score of a specific user by querying the `SyntheticaReputationSBT` contract.
     *      This score dictates a user's influence in evaluations and governance.
     * @param _user The address of the user.
     * @return The user's current reputation score.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return syntheticaReputationSBT.balanceOf(_user);
    }

    /**
     * @dev Allows a user to optionally burn their reputation.
     *      This function is conceptual and could be integrated with future protocol features
     *      where burning reputation might unlock temporary boosts, access to exclusive areas,
     *      or specific voting power.
     * @param _amount The amount of reputation points to burn.
     */
    function burnReputation(uint256 _amount) external whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        syntheticaReputationSBT.burn(_msgSender(), _amount);
        emit ReputationBurned(_msgSender(), _amount);
    }

    // --- VI. Treasury & Funding Management ---

    /**
     * @dev Fallback function to allow direct deposits of native blockchain currency (e.g., Ether on Ethereum)
     *      into the protocol's treasury. These funds can later be managed and withdrawn by governance.
     */
    receive() external payable {
        emit TreasuryDeposited(_msgSender(), address(0), msg.value); // Use address(0) for native currency
    }

    /**
     * @dev Allows anyone to deposit ERC-20 tokens into the protocol's treasury.
     *      The caller must first approve this contract to spend their tokens via an ERC-20 `approve` call.
     * @param _tokenAddress The address of the ERC-20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositTreasury(address _tokenAddress, uint256 _amount) external whenNotPaused {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        require(_amount > 0, "Amount must be greater than zero");
        IERC20 token = IERC20(_tokenAddress);
        // Using transferFrom requires the sender to have pre-approved this contract.
        bool success = token.transferFrom(_msgSender(), address(this), _amount);
        require(success, "Token transfer failed during deposit");

        emit TreasuryDeposited(_msgSender(), _tokenAddress, _amount);
    }

    /**
     * @dev Allows governance to withdraw funds (both native blockchain currency and ERC-20 tokens)
     *      from the protocol's treasury. These funds are used for protocol operations, development,
     *      or specific community-approved initiatives.
     * @param _tokenAddress The address of the token to withdraw. Use `address(0)` for native currency (e.g., ETH).
     * @param _amount The amount of funds to withdraw.
     * @param _recipient The address to send the withdrawn funds to.
     */
    function withdrawTreasuryFunds(address _tokenAddress, uint256 _amount, address _recipient) external onlyGovernance whenNotPaused {
        require(_amount > 0, "Amount must be greater than zero");
        require(_recipient != address(0), "Recipient cannot be zero address");

        if (_tokenAddress == address(0)) {
            // Withdraw native currency
            require(address(this).balance >= _amount, "Insufficient native balance in treasury");
            (bool success, ) = payable(_recipient).call{value: _amount}("");
            require(success, "Native currency transfer failed");
        } else {
            // Withdraw ERC-20 tokens
            IERC20 token = IERC20(_tokenAddress);
            require(token.transfer(_recipient, _amount), "ERC-20 transfer failed");
        }

        emit TreasuryWithdrawn(_recipient, _tokenAddress, _amount);
    }

    // --- VII. Governance & Upgradability ---

    /**
     * @dev Allows users with a sufficiently high reputation to propose a governance action.
     *      The `_actionData` parameter should be ABI-encoded call data for the target function
     *      (e.g., `abi.encodeWithSignature("updateProtocolParameters(uint256,uint256,...)", ...)`)
     *      to be executed if the proposal passes. This enables dynamic protocol evolution.
     * @param _actionData The ABI-encoded call data for the action to be executed upon proposal passage.
     * @param _description A clear and concise description of the proposed action.
     * @return The ID of the newly created governance proposal.
     */
    function proposeGovernanceAction(bytes memory _actionData, string memory _description)
        external
        whenNotPaused
        onlyReputable(minReputationToSubmitKP * 2) // Requires higher reputation to propose governance actions
        returns (uint256)
    {
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_actionData.length > 0, "Action data cannot be empty");

        uint256 proposalId = nextProposalId++;
        GovernanceProposal storage newProposal = governanceProposals[proposalId];
        newProposal.proposer = _msgSender();
        newProposal.actionData = _actionData;
        newProposal.description = _description;
        newProposal.submissionTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + evaluationPeriod; // Reuse evaluationPeriod for governance proposals
        newProposal.executed = false;

        emit GovernanceProposalSubmitted(proposalId, _msgSender(), _description);
        return proposalId;
    }

    /**
     * @dev Allows users with reputation to vote on pending governance proposals.
     *      Vote weight is directly determined by the voter's `SyntheticaReputationSBT` balance.
     * @param _proposalId The ID of the governance proposal to vote on.
     * @param _voteFor True for a 'for' vote (in favor of the proposal), false for an 'against' vote.
     */
    function voteOnGovernanceAction(uint256 _proposalId, bool _voteFor) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp < proposal.votingEndTime, "Voting period has ended");
        require(!proposal.executed, "Proposal already executed");
        require(!hasVotedOnProposal[_proposalId][_msgSender()], "Already voted on this proposal");
        require(_msgSender() != proposal.proposer, "Proposer cannot vote on their own proposal");

        uint256 voterReputation = syntheticaReputationSBT.balanceOf(_msgSender());
        require(voterReputation > 0, "Voter must have reputation to vote");

        if (_voteFor) {
            proposal.totalWeightedForVotes += voterReputation;
        } else {
            proposal.totalWeightedAgainstVotes += voterReputation;
        }
        proposal.uniqueVotersCount++;
        hasVotedOnProposal[_proposalId][_msgSender()] = true;
        proposalVoteChoice[_proposalId][_msgSender()] = _voteFor;

        emit GovernanceVoteCasted(_proposalId, _msgSender(), _voteFor, voterReputation);
    }

    /**
     * @dev Triggers the execution of a passed governance proposal.
     *      Can be called by anyone after the voting period has ended, provided the proposal
     *      has met the minimum votes and threshold percentage. If passed, the `actionData`
     *      is executed, allowing for on-chain parameter changes or other protocol modifications.
     * @param _proposalId The ID of the governance proposal to finalize and execute.
     */
    function finalizeGovernanceAction(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.proposer != address(0), "Proposal does not exist");
        require(block.timestamp >= proposal.votingEndTime, "Voting period has not ended yet");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.uniqueVotersCount >= minVotesRequired, "Not enough unique voters for governance proposal");

        uint256 totalWeightedVotes = proposal.totalWeightedForVotes + proposal.totalWeightedAgainstVotes;
        bool passed = false;

        if (totalWeightedVotes > 0) {
            uint256 forPercentage = (proposal.totalWeightedForVotes * 100) / totalWeightedVotes;
            if (forPercentage >= passThresholdPercentage) {
                passed = true;
            }
        }

        if (passed) {
            // Execute the proposed action by calling a function on this contract with the encoded data
            (bool success, ) = address(this).call(proposal.actionData);
            require(success, "Governance action execution failed"); // Revert if the proposed action itself failed
            proposal.executed = true; // Mark as executed
        }

        emit GovernanceProposalFinalized(_proposalId, passed);
    }
}
```