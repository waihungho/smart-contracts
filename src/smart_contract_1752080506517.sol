Okay, here is a Solidity smart contract implementing a complex, multi-party, conditional escrow system. It incorporates concepts like:

1.  **Multi-party involvement:** Initiator, multiple beneficiaries, multiple optional arbiters.
2.  **Multi-asset support:** Handling ETH, ERC20, and ERC721 tokens within the same escrow.
3.  **Dynamic Conditions:** Conditions for release/return can be added and are based on different types (timestamp, oracle data, party agreement, arbitration).
4.  **State Machine:** The escrow progresses through different states based on actions and condition evaluations.
5.  **Oracle Integration (Simulated/Interface-based):** Designed to interact with external data sources (like Chainlink) to check conditions.
6.  **Party Agreement/Disagreement:** Mechanisms for parties to signal their status on conditions.
7.  **Arbitration:** A process for designated arbiters to resolve disputes and force outcomes.
8.  **Proposal System:** A mini-governance-like system for proposing and approving structural updates to the escrow (like changing beneficiaries or asset distribution rules *before* release).
9.  **Partial Releases/Returns:** Flexibility to release/return specific assets or amounts.

It aims to be more advanced than a simple 2-party escrow and incorporates several interaction patterns.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Added for safety

// --- OUTLINE ---
// Contract Name: QuantumLeapEscrow
// Description: A multi-party, multi-asset escrow contract with dynamic conditional release, arbitration, and a proposal system.
// Core Concepts:
// - Complex state machine based on conditions and actions.
// - Support for ETH, ERC20, ERC721 deposits and releases.
// - Dynamic conditions (Timestamp, Oracle, Party Agreement, Arbitration).
// - Role-based access (Initiator, Beneficiary, Arbiter).
// - Dispute resolution via Arbiters.
// - Basic proposal mechanism for escrow updates.
// Key Data Structures:
// - EscrowState (Enum): Tracks the lifecycle of an escrow.
// - ConditionType (Enum): Defines types of conditions.
// - Condition (Struct): Details of a single condition.
// - Escrow (Struct): Contains all data for a single escrow agreement.
// - UpdateProposal (Struct): Details for proposed changes to an escrow.
// State Flow:
// Draft -> Active (Deposit made) -> ConditionsPending (Conditions set) ->
// ConditionsMet / ConditionsFailed (Conditions evaluated) ->
// FundsReleased / FundsReturned (Assets dispersed) -> Completed / Cancelled -> Dispute -> Arbitrated.

// --- FUNCTION SUMMARY ---
// --- Setup & Creation ---
// 1. constructor(): Initializes the contract. (Implicitly required)
// 2. createEscrow(): Initiates a new escrow agreement.
// --- Deposits ---
// 3. depositETH(): Deposits Ether into an escrow.
// 4. depositERC20(): Deposits ERC20 tokens into an escrow.
// 5. depositERC721(): Deposits ERC721 tokens into an escrow.
// --- Party & Role Management ---
// 6. addBeneficiary(): Adds a beneficiary to an escrow (only in Draft/Active).
// 7. removeBeneficiary(): Removes a beneficiary (only in Draft/Active).
// 8. addArbiter(): Adds an arbiter (only in Draft/Active).
// 9. removeArbiter(): Removes an arbiter (only in Draft/Active).
// --- Condition Management ---
// 10. addCondition(): Adds a new condition to an escrow.
// 11. removeCondition(): Removes a condition (if not yet met/validated).
// 12. updateConditionData(): Modifies the data associated with a condition.
// --- Condition Evaluation & Signaling ---
// 13. checkCondition(): A public function to check the status of a single condition.
// 14. signalPartyAgreement(): Parties signal agreement for a specific condition.
// 15. signalPartyDisagreement(): Parties signal disagreement for a specific condition.
// 16. resolvePartyAgreementCondition(): Arbiter/Contract resolves a PartyAgreement condition based on signals.
// 17. triggerOracleValidation(): Requests oracle validation for an OracleData condition (intended to be called externally or by keeper).
// 18. evaluateAllConditions(): Evaluates all conditions and updates the escrow's overall state.
// --- Dispute & Arbitration ---
// 19. initiateDispute(): Allows parties/arbiters to move the escrow into a Dispute state.
// 20. submitArbitrationResult(): Arbiters submit their binding decision.
// 21. applyArbitrationDecision(): Executes the decision submitted by arbiters.
// --- Release & Return ---
// 22. releaseAssets(): Allows beneficiaries to claim assets if conditions are met.
// 23. releasePartialAssets(): Allows beneficiaries to claim specific subsets of assets.
// 24. returnAssetsToInitiator(): Allows the initiator to reclaim assets if conditions fail.
// 25. returnPartialAssetsToInitiator(): Allows the initiator to reclaim specific subsets of assets.
// --- Escrow Lifecycle Management ---
// 26. cancelEscrow(): Allows initiator/arbiters to cancel an escrow (under certain states).
// 27. finalizeEscrow(): Marks escrow as Completed after all assets are dispersed.
// --- Update Proposal System ---
// 28. proposeUpdate(): Initiates a proposal for escrow modification.
// 29. approveUpdateProposal(): Parties/Arbiters approve a proposal.
// 30. executeUpdateProposal(): Applies a successfully approved proposal.

// Note: Some functions like `checkCondition` might primarily be 'view' logic but are included as callable actions to trigger state updates or external checks.
// The contract intentionally provides many granular functions to control complex state transitions.

contract QuantumLeapEscrow is ReentrancyGuard {
    using Address for address payable; // For safe ETH transfer

    error InvalidState(EscrowState currentState, string action);
    error Unauthorized(string action);
    error InvalidInput(string reason);
    error EscrowNotFound(uint256 escrowId);
    error ConditionNotFound(uint256 escrowId, uint256 conditionIndex);
    error ConditionNotYetMet(uint256 conditionIndex);
    error ConditionFailed(uint256 conditionIndex);
    error ConditionsNotMetOrFailed();
    error NoAssetsToClaim();
    error ProposalNotFound(uint256 escrowId, uint256 proposalId);
    error ProposalNotApproved(uint256 proposalId);
    error ProposalAlreadyExecuted(uint256 proposalId);

    enum EscrowState {
        Draft, // Created, awaiting initial deposits and conditions setup
        Active, // Assets deposited, conditions being added/evaluated
        ConditionsPending, // Assets deposited, conditions set, evaluation in progress
        ConditionsMet, // All conditions evaluated true
        ConditionsFailed, // At least one condition evaluated false
        Dispute, // Dispute initiated, awaiting arbitration
        Arbitrated, // Arbitration decision submitted
        FundsReleased, // Assets released to beneficiaries
        FundsReturned, // Assets returned to initiator
        Completed, // All assets dispersed, escrow finalized
        Cancelled // Escrow cancelled before completion
    }

    enum ConditionType {
        TimestampReached, // Condition is met if current block.timestamp >= targetTimestamp
        OracleDataValue, // Condition is met if an oracle reports a specific value/range (requires validation)
        PartyAgreement, // Condition is met if designated parties signal agreement (requires resolution)
        ArbitrationDecision // Condition is met if arbiters make a specific decision
    }

    enum ComparisonOperator {
        Equal,
        NotEqual,
        GreaterThan,
        LessThan,
        GreaterThanOrEqual,
        LessThanOrEqual
    }

    struct OracleData {
        address oracleAddress; // Address of the oracle contract (e.g., Chainlink feed)
        bytes feedId; // Identifier for the specific data feed
        bytes expectedValue; // The value or criteria expected from the feed
        ComparisonOperator operator; // How to compare the feed result
    }

    struct Condition {
        ConditionType conditionType;
        bytes conditionData; // Encoded data based on ConditionType (e.g., abi.encode(timestamp), abi.encode(OracleData), abi.encode(agreementHash))
        bool isMet; // Whether the condition logic itself evaluated true (e.g., timestamp reached, oracle value matches)
        bool isValidated; // True if an oracle/arbitration condition result has been confirmed (avoids reliance purely on external calls without trust)
        uint256 validationTimestamp; // Timestamp when validated
        mapping(address => bool) partySignals; // For PartyAgreement: true if party agreed, false if disagreed, unset otherwise
    }

    struct Escrow {
        uint256 id; // Unique identifier for the escrow
        address payable initiator; // The creator and funder of the escrow
        address[] beneficiaries; // Addresses who receive assets if conditions are met
        address[] arbiters; // Addresses designated to resolve disputes
        Condition[] conditions; // List of conditions that must be met
        EscrowState state; // Current state of the escrow
        uint256 creationTimestamp; // Timestamp of creation

        // Held Assets: Mappings to track assets associated with this specific escrow ID
        // Using nested mappings to associate assets with the escrow ID.
        // Note: This approach means assets are tracked *per escrow*, not per holder initially.
        // ETH: escrowId -> amount
        mapping(uint256 => uint256) heldETH;
        // ERC20: escrowId -> tokenAddress -> amount
        mapping(uint256 => mapping(address => uint256)) heldERC20;
        // ERC721: escrowId -> tokenAddress -> array of tokenIds
        mapping(uint256 => mapping(address => uint256[])) heldERC721TokenIds;

        // Asset Distribution (Flexible): How much/which assets go to which beneficiary if conditions met.
        // Could be complex, e.g., percentages, specific items. Using a placeholder structure.
        // For simplicity here, assumes equal distribution or based on conditions met.
        // A more complex contract might need a `distributionPlan` struct.

        // Arbitration decision (simplistic - could be a complex plan)
        enum ArbitrationOutcome { Undecided, AwardToBeneficiaries, AwardToInitiator, SplitAssets }
        ArbitrationOutcome arbitrationOutcome; // The outcome decided by arbiters

        // Proposal System State
        uint256 nextProposalId;
        mapping(uint256 => UpdateProposal) proposals; // proposalId -> Proposal
    }

    // Basic structure for a proposal to modify an escrow
    struct UpdateProposal {
        uint256 proposalId;
        uint256 escrowId;
        bytes proposalData; // Encoded data detailing the proposed change (e.g., add/remove beneficiary, change distribution plan)
        mapping(address => bool) approvals; // Addresses who have approved
        uint256 requiredApprovals; // Number of approvals needed (e.g., majority of parties + arbiters)
        uint256 currentApprovals;
        bool executed; // True if the proposal has been applied
    }


    uint256 private nextEscrowId = 1;
    mapping(uint256 => Escrow) public escrows;

    // Events
    event EscrowCreated(uint256 indexed escrowId, address indexed initiator, address[] beneficiaries, address[] arbiters, uint256 creationTimestamp);
    event ETHDeposited(uint256 indexed escrowId, address indexed depositor, uint256 amount);
    event ERC20Deposited(uint256 indexed escrowId, address indexed depositor, address indexed tokenAddress, uint256 amount);
    event ERC721Deposited(uint256 indexed escrowId, address indexed depositor, address indexed tokenAddress, uint256 tokenId);
    event BeneficiaryAdded(uint256 indexed escrowId, address beneficiary);
    event BeneficiaryRemoved(uint256 indexed escrowId, address beneficiary);
    event ArbiterAdded(uint256 indexed escrowId, address arbiter);
    event ArbiterRemoved(uint256 indexed escrowId, address arbiter);
    event ConditionAdded(uint256 indexed escrowId, uint256 indexed conditionIndex, ConditionType conditionType);
    event ConditionRemoved(uint256 indexed escrowId, uint256 indexed conditionIndex);
    event ConditionDataUpdated(uint256 indexed escrowId, uint256 indexed conditionIndex);
    event ConditionChecked(uint256 indexed escrowId, uint256 indexed conditionIndex, bool isMet);
    event PartySignal(uint256 indexed escrowId, uint256 indexed conditionIndex, address indexed party, bool agreed);
    event ConditionValidated(uint256 indexed escrowId, uint256 indexed conditionIndex, bool isValidated);
    event EscrowStateChanged(uint256 indexed escrowId, EscrowState newState);
    event DisputeInitiated(uint256 indexed escrowId, address indexed initiator);
    event ArbitrationResultSubmitted(uint256 indexed escrowId, ArbitrationOutcome outcome);
    event ArbitrationDecisionApplied(uint256 indexed escrowId, ArbitrationOutcome outcome);
    event ETHReleased(uint256 indexed escrowId, address indexed beneficiary, uint256 amount);
    event ERC20Released(uint256 indexed escrowId, address indexed beneficiary, address indexed tokenAddress, uint24 amount);
    event ERC721Released(uint256 indexed escrowId, address indexed beneficiary, address indexed tokenAddress, uint256 tokenId);
    event ETHReturned(uint256 indexed escrowId, address indexed initiator, uint256 amount);
    event ERC20Returned(uint256 indexed escrowId, address indexed initiator, address indexed tokenAddress, uint24 amount);
    event ERC721Returned(uint256 indexed escrowId, address indexed initiator, address indexed tokenAddress, uint256 tokenId);
    event EscrowCancelled(uint256 indexed escrowId, address indexed canceller);
    event EscrowFinalized(uint256 indexed escrowId);
    event ProposalCreated(uint256 indexed escrowId, uint256 indexed proposalId, bytes proposalData);
    event ProposalApproved(uint256 indexed escrowId, uint256 indexed proposalId, address indexed approver);
    event ProposalExecuted(uint256 indexed escrowId, uint256 indexed proposalId);


    // --- Modifiers ---
    modifier onlyInitiator(uint256 _escrowId) {
        require(escrows[_escrowId].initiator == msg.sender, Unauthorized("only initiator"));
        _;
    }

    modifier onlyBeneficiary(uint256 _escrowId) {
        bool isBeneficiary = false;
        for (uint i = 0; i < escrows[_escrowId].beneficiaries.length; i++) {
            if (escrows[_escrowId].beneficiaries[i] == msg.sender) {
                isBeneficiary = true;
                break;
            }
        }
        require(isBeneficiary, Unauthorized("only beneficiary"));
        _;
    }

    modifier onlyArbiter(uint256 _escrowId) {
        bool isArbiter = false;
        for (uint i = 0; i < escrows[_escrowId].arbiters.length; i++) {
            if (escrows[_escrowId].arbiters[i] == msg.sender) {
                isArbiter = true;
                break;
            }
        }
        require(isArbiter, Unauthorized("only arbiter"));
        _;
    }

    // --- Helper Functions ---
    function _getEscrow(uint256 _escrowId) internal view returns (Escrow storage) {
        Escrow storage escrow = escrows[_escrowId];
        require(escrow.id != 0, EscrowNotFound(_escrowId));
        return escrow;
    }

    function _changeState(Escrow storage _escrow, EscrowState _newState) internal {
        if (_escrow.state != _newState) {
            _escrow.state = _newState;
            emit EscrowStateChanged(_escrow.id, _newState);
        }
    }

    function _canModifyPartiesOrConditions(EscrowState _state) internal pure returns (bool) {
        return _state == EscrowState.Draft || _state == EscrowState.Active;
    }

     function _findBeneficiaryIndex(Escrow storage _escrow, address _beneficiary) internal view returns (int256) {
        for (uint i = 0; i < _escrow.beneficiaries.length; i++) {
            if (_escrow.beneficiaries[i] == _beneficiary) {
                return int256(i);
            }
        }
        return -1;
    }

    function _findArbiterIndex(Escrow storage _escrow, address _arbiter) internal view returns (int256) {
        for (uint i = 0; i < _escrow.arbiters.length; i++) {
            if (_escrow.arbiters[i] == _arbiter) {
                return int256(i);
            }
        }
        return -1;
    }

    // --- Public & External Functions (>= 20) ---

    // 1. constructor() - Inherited implicitly if not defined explicitly. Initializes contract state.
    // If complex init is needed, add one here. For this example, default init is fine.

    // 2. createEscrow()
    /// @notice Initiates a new escrow agreement.
    /// @param _beneficiaries Addresses of the beneficiaries.
    /// @param _arbiters Addresses of the arbiters (can be empty).
    /// @dev Assets and conditions are added in subsequent steps.
    function createEscrow(address[] calldata _beneficiaries, address[] calldata _arbiters) external returns (uint256) {
        require(_beneficiaries.length > 0, InvalidInput("must have at least one beneficiary"));

        uint256 escrowId = nextEscrowId++;
        Escrow storage newEscrow = escrows[escrowId];

        newEscrow.id = escrowId;
        newEscrow.initiator = payable(msg.sender);
        newEscrow.beneficiaries = _beneficiaries;
        newEscrow.arbiters = _arbiters;
        newEscrow.state = EscrowState.Draft;
        newEscrow.creationTimestamp = block.timestamp;
        newEscrow.nextProposalId = 1;
        newEscrow.arbitrationOutcome = ArbitrationOutcome.Undecided;

        emit EscrowCreated(escrowId, msg.sender, _beneficiaries, _arbiters, newEscrow.creationTimestamp);

        return escrowId;
    }

    // 3. depositETH()
    /// @notice Deposits Ether into a specific escrow. Can be called by initiator or others.
    /// @param _escrowId The ID of the escrow.
    /// @dev Only allowed in Draft or Active states. Updates state to Active if coming from Draft.
    receive() external payable {
        // This fallback function handles plain ETH sends without calling depositETH.
        // If you want to require deposits via depositETH, remove this function.
        // Or add logic here to reject or handle plain ETH sends.
        // For this contract, let's *not* use receive() for escrow deposits.
        // Revert if plain ETH send is received.
        revert("Direct ETH sends are not supported. Use depositETH.");
    }

    /// @param _escrowId The ID of the escrow.
    function depositETH(uint256 _escrowId) external payable nonReentrant {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(_canModifyPartiesOrConditions(escrow.state), InvalidState(escrow.state, "deposit ETH"));
        require(msg.value > 0, InvalidInput("amount must be greater than zero"));

        escrow.heldETH[_escrowId] += msg.value; // Store ETH associated with the escrow ID

        if (escrow.state == EscrowState.Draft) {
            _changeState(escrow, EscrowState.Active);
        }

        emit ETHDeposited(_escrowId, msg.sender, msg.value);
    }

    // 4. depositERC20()
    /// @notice Deposits ERC20 tokens into a specific escrow. Requires prior approval.
    /// @param _escrowId The ID of the escrow.
    /// @param _tokenAddress The address of the ERC20 token contract.
    /// @param _amount The amount of tokens to deposit.
    /// @dev The caller must have approved this contract to spend the tokens.
    /// @dev Only allowed in Draft or Active states. Updates state to Active if coming from Draft.
    function depositERC20(uint256 _escrowId, address _tokenAddress, uint256 _amount) external nonReentrant {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(_canModifyPartiesOrConditions(escrow.state), InvalidState(escrow.state, "deposit ERC20"));
        require(_amount > 0, InvalidInput("amount must be greater than zero"));
        require(_tokenAddress != address(0), InvalidInput("invalid token address"));

        IERC20 token = IERC20(_tokenAddress);
        // Transfer tokens from the depositor to this contract
        require(token.transferFrom(msg.sender, address(this), _amount), "ERC20 transfer failed");

        // Store tokens associated with the escrow ID and token address
        escrow.heldERC20[_escrowId][_tokenAddress] += _amount;

        if (escrow.state == EscrowState.Draft) {
            _changeState(escrow, EscrowState.Active);
        }

        emit ERC20Deposited(_escrowId, msg.sender, _tokenAddress, _amount);
    }

    // 5. depositERC721()
    /// @notice Deposits ERC721 tokens (NFTs) into a specific escrow. Requires prior approval or `safeTransferFrom`.
    /// @param _escrowId The ID of the escrow.
    /// @param _tokenAddress The address of the ERC721 token contract.
    /// @param _tokenId The ID of the NFT to deposit.
    /// @dev The caller must have approved this contract or the specific token ID.
    /// @dev Using `safeTransferFrom` is recommended which calls `onERC721Received` on this contract.
    /// @dev Only allowed in Draft or Active states. Updates state to Active if coming from Draft.
    function depositERC721(uint256 _escrowId, address _tokenAddress, uint256 _tokenId) external nonReentrant {
         Escrow storage escrow = _getEscrow(_escrowId);
        require(_canModifyPartiesOrConditions(escrow.state), InvalidState(escrow.state, "deposit ERC721"));
        require(_tokenAddress != address(0), InvalidInput("invalid token address"));

        IERC721 token = IERC721(_tokenAddress);
        // Transfer the NFT from the depositor to this contract
        // This requires the sender to have approved this contract or the specific token ID
        token.transferFrom(msg.sender, address(this), _tokenId);

        // Store the token ID associated with the escrow ID and token address
        // This is a simplified way to track; a more complex system might track ownership internally
        escrow.heldERC721TokenIds[_escrowId][_tokenAddress].push(_tokenId);

         if (escrow.state == EscrowState.Draft) {
            _changeState(escrow, EscrowState.Active);
        }

        emit ERC721Deposited(_escrowId, msg.sender, _tokenAddress, _tokenId);
    }

     // For ERC721 `safeTransferFrom` compatibility
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure returns (bytes4) {
        // Simply acknowledges receipt. Actual deposit logic should happen in depositERC721.
        // If using safeTransferFrom, the caller needs to call depositERC721 first with the ID.
        // A more sophisticated contract might embed the escrowId in the `data` parameter
        // and handle the deposit entirely within this function. For simplicity,
        // we assume depositERC721 is called explicitly.
        return this.onERC721Received.selector;
    }


    // 6. addBeneficiary()
    /// @notice Adds a beneficiary to the escrow. Only callable by initiator.
    /// @param _escrowId The ID of the escrow.
    /// @param _beneficiary Address of the beneficiary to add.
    /// @dev Only allowed in Draft or Active states.
    function addBeneficiary(uint256 _escrowId, address _beneficiary) external onlyInitiator(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(_canModifyPartiesOrConditions(escrow.state), InvalidState(escrow.state, "add beneficiary"));
        require(_beneficiary != address(0), InvalidInput("invalid beneficiary address"));

        require(_findBeneficiaryIndex(escrow, _beneficiary) == -1, InvalidInput("beneficiary already exists"));

        escrow.beneficiaries.push(_beneficiary);
        emit BeneficiaryAdded(_escrowId, _beneficiary);
    }

    // 7. removeBeneficiary()
    /// @notice Removes a beneficiary from the escrow. Only callable by initiator.
    /// @param _escrowId The ID of the escrow.
    /// @param _beneficiary Address of the beneficiary to remove.
    /// @dev Only allowed in Draft or Active states. Not possible if assets are allocated specifically to them.
    function removeBeneficiary(uint256 _escrowId, address _beneficiary) external onlyInitiator(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
         require(_canModifyPartiesOrConditions(escrow.state), InvalidState(escrow.state, "remove beneficiary"));
        require(_beneficiary != escrow.initiator, InvalidInput("cannot remove initiator as beneficiary")); // Initiator shouldn't be in beneficiaries list anyway

        int256 index = _findBeneficiaryIndex(escrow, _beneficiary);
        require(index != -1, InvalidInput("beneficiary not found"));

        // Simple removal: swap with last and pop. Order changes.
        uint256 lastIndex = escrow.beneficiaries.length - 1;
        if (uint256(index) != lastIndex) {
            escrow.beneficiaries[uint256(index)] = escrow.beneficiaries[lastIndex];
        }
        escrow.beneficiaries.pop();

        emit BeneficiaryRemoved(_escrowId, _beneficiary);
    }

     // 8. addArbiter()
    /// @notice Adds an arbiter to the escrow. Only callable by initiator.
    /// @param _escrowId The ID of the escrow.
    /// @param _arbiter Address of the arbiter to add.
    /// @dev Only allowed in Draft or Active states.
    function addArbiter(uint256 _escrowId, address _arbiter) external onlyInitiator(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(_canModifyPartiesOrConditions(escrow.state), InvalidState(escrow.state, "add arbiter"));
        require(_arbiter != address(0), InvalidInput("invalid arbiter address"));

        require(_findArbiterIndex(escrow, _arbiter) == -1, InvalidInput("arbiter already exists"));

        escrow.arbiters.push(_arbiter);
        emit ArbiterAdded(_escrowId, _arbiter);
    }

    // 9. removeArbiter()
    /// @notice Removes an arbiter from the escrow. Only callable by initiator.
    /// @param _escrowId The ID of the escrow.
    /// @param _arbiter Address of the arbiter to remove.
    /// @dev Only allowed in Draft or Active states.
    function removeArbiter(uint256 _escrowId, address _arbiter) external onlyInitiator(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(_canModifyPartiesOrConditions(escrow.state), InvalidState(escrow.state, "remove arbiter"));

        int256 index = _findArbiterIndex(escrow, _arbiter);
        require(index != -1, InvalidInput("arbiter not found"));

        // Simple removal: swap with last and pop. Order changes.
        uint256 lastIndex = escrow.arbiters.length - 1;
        if (uint256(index) != lastIndex) {
            escrow.arbiters[uint256(index)] = escrow.arbiters[lastIndex];
        }
        escrow.arbiters.pop();

        emit ArbiterRemoved(_escrowId, _arbiter);
    }

    // 10. addCondition()
    /// @notice Adds a new condition to the escrow. Only callable by initiator.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionType The type of the condition.
    /// @param _conditionData Encoded data for the condition (e.g., timestamp, oracle details, agreement hash).
    /// @dev Allowed in Draft, Active, or ConditionsPending states. Adding conditions moves to ConditionsPending.
    function addCondition(uint256 _escrowId, ConditionType _conditionType, bytes calldata _conditionData) external onlyInitiator(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state <= EscrowState.ConditionsPending, InvalidState(escrow.state, "add condition"));
        require(_conditionData.length > 0, InvalidInput("condition data cannot be empty"));

        // Basic validation for condition data format based on type (can be expanded)
        if (_conditionType == ConditionType.TimestampReached) {
            require(_conditionData.length == 32, InvalidInput("Timestamp condition data must be 32 bytes (uint256)"));
            uint256 targetTimestamp = abi.decode(_conditionData, (uint256));
            require(targetTimestamp > block.timestamp, InvalidInput("Timestamp must be in the future"));
        } else if (_conditionType == ConditionType.OracleDataValue) {
             // Decode OracleData struct and perform basic checks
             OracleData memory oracle;
             try abi.decode(_conditionData, (OracleData)) returns (OracleData memory decodedOracle) {
                 oracle = decodedOracle;
             } catch {
                 revert(InvalidInput("OracleData condition data must be encoded OracleData struct"));
             }
             require(oracle.oracleAddress != address(0), InvalidInput("Oracle address cannot be zero"));
             // Further validation might involve checking if the oracleAddress is a known/trusted oracle
        } else if (_conditionType == ConditionType.PartyAgreement) {
             // PartyAgreement might encode a hash of the agreement terms
             require(_conditionData.length == 32, InvalidInput("PartyAgreement condition data should be 32 bytes (e.g., hash)"));
             require(escrow.beneficiaries.length > 0 || escrow.arbiters.length > 0, InvalidInput("PartyAgreement requires beneficiaries or arbiters"));
        } else if (_conditionType == ConditionType.ArbitrationDecision) {
            // ArbitrationDecision might encode the expected outcome
             require(_conditionData.length == 32, InvalidInput("ArbitrationDecision condition data must be 32 bytes (uint256 enum)"));
             uint256 expectedOutcome = abi.decode(_conditionData, (uint256));
             require(expectedOutcome >= uint256(ArbitrationOutcome.AwardToBeneficiaries) && expectedOutcome <= uint256(ArbitrationOutcome.SplitAssets), InvalidInput("Invalid ArbitrationDecision outcome"));
             require(escrow.arbiters.length > 0, InvalidInput("ArbitrationDecision requires arbiters"));
        } else {
             revert(InvalidInput("Unsupported condition type"));
        }


        escrow.conditions.push(Condition({
            conditionType: _conditionType,
            conditionData: _conditionData,
            isMet: false,
            isValidated: false,
            validationTimestamp: 0 // Not applicable initially
            // partySignals mapping is implicitly initialized empty
        }));

        // Transition to ConditionsPending if not already there and if conditions are added
        if (escrow.state == EscrowState.Active && escrow.conditions.length > 0) {
             _changeState(escrow, EscrowState.ConditionsPending);
        } else if (escrow.state == EscrowState.Draft) {
            revert(InvalidState(escrow.state, "add conditions: deposit assets first"));
        }


        emit ConditionAdded(_escrowId, escrow.conditions.length - 1, _conditionType);
    }

    // 11. removeCondition()
    /// @notice Removes a condition from the escrow. Only callable by initiator.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionIndex The index of the condition to remove.
    /// @dev Only allowed in Draft, Active, or ConditionsPending states. Not possible if the condition is already met or validated.
    function removeCondition(uint256 _escrowId, uint256 _conditionIndex) external onlyInitiator(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state <= EscrowState.ConditionsPending, InvalidState(escrow.state, "remove condition"));
        require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));

        Condition storage condition = escrow.conditions[_conditionIndex];
        require(!condition.isMet && !condition.isValidated, InvalidInput("cannot remove a condition that is already met or validated"));

        // Simple removal: swap with last and pop. Order changes.
        uint256 lastIndex = escrow.conditions.length - 1;
        if (_conditionIndex != lastIndex) {
            escrow.conditions[_conditionIndex] = escrow.conditions[lastIndex];
        }
        escrow.conditions.pop();

        emit ConditionRemoved(_escrowId, _conditionIndex);

        // Re-evaluate state if conditions list becomes empty
        if (escrow.conditions.length == 0 && escrow.state == EscrowState.ConditionsPending) {
            // If all conditions removed, go back to Active (waiting for new conditions or cancellation)
             _changeState(escrow, EscrowState.Active);
        }
    }

    // 12. updateConditionData()
    /// @notice Modifies the data associated with a condition. Only callable by initiator.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionIndex The index of the condition.
    /// @param _newConditionData The new encoded data for the condition.
    /// @dev Only allowed in Draft, Active, or ConditionsPending states. Not possible if the condition is already met or validated.
    function updateConditionData(uint256 _escrowId, uint256 _conditionIndex, bytes calldata _newConditionData) external onlyInitiator(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state <= EscrowState.ConditionsPending, InvalidState(escrow.state, "update condition data"));
        require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));
        require(_newConditionData.length > 0, InvalidInput("condition data cannot be empty"));

        Condition storage condition = escrow.conditions[_conditionIndex];
        require(!condition.isMet && !condition.isValidated, InvalidInput("cannot update data for a condition that is already met or validated"));

         // Basic validation for new data based on existing type (can be expanded)
        if (condition.conditionType == ConditionType.TimestampReached) {
            require(_newConditionData.length == 32, InvalidInput("Timestamp condition data must be 32 bytes (uint256)"));
            uint256 targetTimestamp = abi.decode(_newConditionData, (uint256));
            require(targetTimestamp > block.timestamp, InvalidInput("Timestamp must be in the future"));
        } else if (condition.conditionType == ConditionType.OracleDataValue) {
             OracleData memory oracle;
             try abi.decode(_newConditionData, (OracleData)) returns (OracleData memory decodedOracle) {
                 oracle = decodedOracle;
             } catch {
                 revert(InvalidInput("OracleData condition data must be encoded OracleData struct"));
             }
             require(oracle.oracleAddress != address(0), InvalidInput("Oracle address cannot be zero"));
        } else if (condition.conditionType == ConditionType.PartyAgreement) {
             require(_newConditionData.length == 32, InvalidInput("PartyAgreement condition data should be 32 bytes (e.g., hash)"));
        } else if (condition.conditionType == ConditionType.ArbitrationDecision) {
             require(_newConditionData.length == 32, InvalidInput("ArbitrationDecision condition data must be 32 bytes (uint256 enum)"));
             uint256 expectedOutcome = abi.decode(_newConditionData, (uint256));
             require(expectedOutcome >= uint256(ArbitrationOutcome.AwardToBeneficiaries) && expectedOutcome <= uint256(ArbitrationOutcome.SplitAssets), InvalidInput("Invalid ArbitrationDecision outcome"));
        }

        condition.conditionData = _newConditionData;

        emit ConditionDataUpdated(_escrowId, _conditionIndex);
    }

    // 13. checkCondition()
    /// @notice Checks and potentially updates the 'isMet' status of a single condition.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionIndex The index of the condition to check.
    /// @dev Can be called by anyone. Updates internal state if the condition is now met.
    /// @dev Does not evaluate OracleData or PartyAgreement conditions until validated/resolved separately.
    function checkCondition(uint256 _escrowId, uint256 _conditionIndex) external {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.ConditionsPending, InvalidState(escrow.state, "check condition"));
         require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));

         Condition storage condition = escrow.conditions[_conditionIndex];

         if (condition.isMet) {
             // Already met, nothing to do
             return;
         }

         bool met = false;
         if (condition.conditionType == ConditionType.TimestampReached) {
             uint256 targetTimestamp = abi.decode(condition.conditionData, (uint256));
             if (block.timestamp >= targetTimestamp) {
                 met = true;
             }
         } else if (condition.conditionType == ConditionType.OracleDataValue) {
             // Oracle conditions require explicit validation via triggerOracleValidation / validation callback
             // The check here can't unilaterally set `isMet`.
             // A more complex contract might interface directly with a pull-based oracle here.
             // For this structure, `isMet` for OracleData is set by `triggerOracleValidation` after validation.
             met = condition.isMet; // Remains unchanged by just calling checkCondition
         } else if (condition.conditionType == ConditionType.PartyAgreement) {
             // Party agreement requires resolution via resolvePartyAgreementCondition
             met = condition.isMet; // Remains unchanged
         } else if (condition.conditionType == ConditionType.ArbitrationDecision) {
             // Arbitration conditions require arbitration to be applied
             met = condition.isMet; // Remains unchanged
         } else {
              // Should not happen if addCondition validates types
         }

         if (met && !condition.isMet) {
             condition.isMet = true;
             emit ConditionChecked(_escrowId, _conditionIndex, true);
         } else if (!met && condition.isMet) {
             // Condition previously met but now not? (e.g., oracle feed changed back).
             // This contract assumes conditions, once met, stay met. Remove this branch if temporary conditions are needed.
         } else if (met == condition.isMet) {
             // No change
              emit ConditionChecked(_escrowId, _conditionIndex, met);
         }
    }

    // 14. signalPartyAgreement()
    /// @notice Allows a beneficiary or arbiter to signal agreement for a PartyAgreement condition.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionIndex The index of the PartyAgreement condition.
    /// @dev Only callable by beneficiaries or arbiters involved in the escrow.
    /// @dev Does not automatically update `isMet` for the condition; requires `resolvePartyAgreementCondition`.
    function signalPartyAgreement(uint256 _escrowId, uint256 _conditionIndex) external {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state == EscrowState.ConditionsPending, InvalidState(escrow.state, "signal agreement"));
        require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));
        Condition storage condition = escrow.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.PartyAgreement, InvalidInput("condition is not a PartyAgreement type"));

        bool isParty = (_findBeneficiaryIndex(escrow, msg.sender) != -1) || (_findArbiterIndex(escrow, msg.sender) != -1);
        require(isParty, Unauthorized("only beneficiaries or arbiters can signal"));

        condition.partySignals[msg.sender] = true;
        emit PartySignal(_escrowId, _conditionIndex, msg.sender, true);
    }

     // 15. signalPartyDisagreement()
    /// @notice Allows a beneficiary or arbiter to signal disagreement for a PartyAgreement condition.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionIndex The index of the PartyAgreement condition.
    /// @dev Only callable by beneficiaries or arbiters involved in the escrow.
    /// @dev Does not automatically update `isMet` for the condition; requires `resolvePartyAgreementCondition`.
    function signalPartyDisagreement(uint256 _escrowId, uint256 _conditionIndex) external {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state == EscrowState.ConditionsPending, InvalidState(escrow.state, "signal disagreement"));
        require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));
        Condition storage condition = escrow.conditions[_conditionIndex];
        require(condition.conditionType == ConditionType.PartyAgreement, InvalidInput("condition is not a PartyAgreement type"));

        bool isParty = (_findBeneficiaryIndex(escrow, msg.sender) != -1) || (_findArbiterIndex(escrow, msg.sender) != -1);
        require(isParty, Unauthorized("only beneficiaries or arbiters can signal"));

        condition.partySignals[msg.sender] = false; // False means disagreement
        emit PartySignal(_escrowId, _conditionIndex, msg.sender, false);
    }

    // 16. resolvePartyAgreementCondition()
    /// @notice Resolves a PartyAgreement condition based on collected party signals.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionIndex The index of the PartyAgreement condition.
    /// @dev This function defines the consensus logic (e.g., majority, all).
    /// @dev For simplicity, requires *all* beneficiaries and *any* arbiter (if arbiters exist) to have signalled agreement.
    /// @dev Can be called by anyone, but its outcome depends on prior signals. Updates `isMet` and `isValidated`.
    function resolvePartyAgreementCondition(uint256 _escrowId, uint256 _conditionIndex) external {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.ConditionsPending || escrow.state == EscrowState.Dispute, InvalidState(escrow.state, "resolve party agreement"));
         require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));
         Condition storage condition = escrow.conditions[_conditionIndex];
         require(condition.conditionType == ConditionType.PartyAgreement, InvalidInput("condition is not a PartyAgreement type"));
         require(!condition.isValidated, InvalidInput("condition already resolved")); // isValidated means resolved

         // Consensus logic: All beneficiaries must agree, OR any arbiter agrees if arbiters exist.
         bool allBeneficiariesAgreed = true;
         for (uint i = 0; i < escrow.beneficiaries.length; i++) {
             if (!condition.partySignals[escrow.beneficiaries[i]]) {
                 allBeneficiariesAgreed = false;
                 break;
             }
         }

         bool anyArbiterAgreed = false;
         for (uint i = 0; i < escrow.arbiters.length; i++) {
             if (condition.partySignals[escrow.arbiters[i]]) {
                 anyArbiterAgreed = true;
                 break;
             }
         }

         // Define 'met' based on consensus rules
         bool met = false;
         if (escrow.arbiters.length > 0) {
             // If arbiters exist, either all beneficiaries agree OR any arbiter agrees
             met = allBeneficiariesAgreed || anyArbiterAgreed;
         } else {
             // If no arbiters, all beneficiaries must agree
             met = allBeneficiariesAgreed;
         }

         // Disagreement check: If any party signals disagreement, the condition fails.
         // This is a stricter interpretation - adjust logic as needed (e.g., majority disagreement)
         bool anyDisagreement = false;
         for (uint i = 0; i < escrow.beneficiaries.length; i++) {
              // Check if the signal was set to false (explicit disagreement)
              if (condition.partySignals[escrow.beneficiaries[i]] == false) {
                  anyDisagreement = true;
                  break;
              }
         }
          for (uint i = 0; i < escrow.arbiters.length; i++) {
              if (condition.partySignals[escrow.arbiters[i]] == false) {
                  anyDisagreement = true;
                  break;
              }
         }


         if (anyDisagreement) {
            // If anyone explicitly disagreed, the condition is not met.
            condition.isMet = false;
         } else {
             // Otherwise, evaluate based on agreement logic
             condition.isMet = met;
         }


         condition.isValidated = true; // Mark as resolved
         condition.validationTimestamp = block.timestamp;

         emit ConditionValidated(_escrowId, _conditionIndex, condition.isMet);
         emit ConditionChecked(_escrowId, _conditionIndex, condition.isMet); // Also emit checked for consistency

         // If the escrow is in Dispute state and an arbiter resolved this, potentially trigger state change or apply decision.
         // This is complex and might require a specific ArbitrationDecision condition type or explicit `applyArbitrationDecision` call.
    }


    // 17. triggerOracleValidation()
    /// @notice Triggers the validation logic for an OracleData condition.
    /// @param _escrowId The ID of the escrow.
    /// @param _conditionIndex The index of the OracleData condition.
    /// @dev Intended to be called by a trusted relayer, keeper, or potentially an arbiter.
    /// @dev Calls out to the specified oracle contract to get the current value and compares it. Updates `isMet` and `isValidated`.
    /// @dev NOTE: This is a simplified implementation. Real oracle interaction (like Chainlink) involves callbacks (`fulfill`) or direct calls to specific feed patterns.
    function triggerOracleValidation(uint256 _escrowId, uint256 _conditionIndex) external {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.ConditionsPending || escrow.state == EscrowState.Dispute, InvalidState(escrow.state, "trigger oracle validation"));
         require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));
         Condition storage condition = escrow.conditions[_conditionIndex];
         require(condition.conditionType == ConditionType.OracleDataValue, InvalidInput("condition is not an OracleData type"));
         require(!condition.isValidated, InvalidInput("oracle condition already validated"));

         // Decode OracleData struct
         OracleData memory oracleData;
         try abi.decode(condition.conditionData, (OracleData)) returns (OracleData memory decodedOracle) {
             oracleData = decodedOracle;
         } catch {
              revert(InvalidInput("Invalid OracleData encoding")); // Should have been caught in addCondition
         }

         // --- SIMULATED ORACLE INTERACTION ---
         // In a real contract, this would call an oracle contract (e.g., Chainlink AggregatorV3Interface)
         // For simulation, we'll use a placeholder check.
         // Example: Assuming oracle.oracleAddress is a contract with `latestAnswer()` returning int256
         // This simulation assumes oracleData.expectedValue and oracleData.operator are encoded correctly for comparison.
         // This is highly simplified and needs robust error handling, data type matching, and trust assumptions.

         // Placeholder: Assume the oracle needs to be called and returns a value.
         // A real implementation would need an interface for the oracle and handle the call.
         // Example: (Simplified)
         // int256 latestValue = IChainlinkFeed(oracleData.oracleAddress).latestAnswer();
         // bool comparisonResult = _compare(latestValue, oracleData.expectedValue, oracleData.operator);

         // --- Replacing with a stub for demonstration ---
         // Let's assume a separate oracle simulator contract or a pre-set value for testing.
         // For this example, let's pretend we *somehow* get a boolean result `oracleResult`.
         // In a real system, this would involve Chainlink's requested/fulfilled pattern or reading from a data feed.
         // We'll skip the actual external call and just require *someone trusted* calls this after getting the result.
         // A more robust system would require this function to be callable ONLY by a designated oracle or keeper.
         // For demonstration, let's allow anyone, but the real validation logic is skipped.
         // ***WARNING***: This is a security vulnerability in a real contract without proper access control or oracle interaction.

         // Placeholder: Assume validation happens off-chain and a trusted party calls this.
         // Let's require this is called by an arbiter for slightly better control in this demo.
         require(_findArbiterIndex(escrow, msg.sender) != -1 || escrow.initiator == msg.sender, Unauthorized("only arbiters or initiator can trigger oracle validation (in demo)"));

         // In a real contract, this is where the external call and callback handling happens.
         // Since we can't do that directly and securely in a simple example, let's assume the oracle result
         // is somehow verified off-chain and the arbiter/initiator is confirming it here.
         // This moves trust back to the caller of *this* function.
         // A truly decentralized way would require a dedicated oracle module/pattern.

         // --- Simplified Demo Logic: Arbiter manually sets met/failed ---
         // A real system would *not* let an arbiter directly set isMet without oracle proof.
         // This function title is misleading based on this simplified logic, but demonstrates setting validated.
         // A better name might be `confirmOracleConditionResult`.
         // Let's change the function name and require an outcome parameter.

         revert("Use confirmOracleConditionResult with the actual oracle outcome."); // Force use the more explicit function below
    }

    // 17b (Replacing 17). confirmOracleConditionResult()
     /// @notice Confirms the result of an OracleData condition validation.
     /// @param _escrowId The ID of the escrow.
     /// @param _conditionIndex The index of the OracleData condition.
     /// @param _oracleResult The actual result obtained from the oracle feed.
     /// @dev Intended to be called by a trusted keeper or an arbiter after obtaining the oracle data.
     /// @dev Compares the result against the condition data and updates `isMet` and `isValidated`.
     function confirmOracleConditionResult(uint256 _escrowId, uint256 _conditionIndex, bytes calldata _oracleResult) external onlyArbiter(_escrowId) { // Restricted to arbiters
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.ConditionsPending || escrow.state == EscrowState.Dispute, InvalidState(escrow.state, "confirm oracle result"));
         require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));
         Condition storage condition = escrow.conditions[_conditionIndex];
         require(condition.conditionType == ConditionType.OracleDataValue, InvalidInput("condition is not an OracleData type"));
         require(!condition.isValidated, InvalidInput("oracle condition already validated"));

         OracleData memory oracleData;
         try abi.decode(condition.conditionData, (OracleData)) returns (OracleData memory decodedOracle) {
             oracleData = decodedOracle;
         } catch {
              revert(InvalidInput("Invalid OracleData encoding")); // Should have been caught in addCondition
         }

         // --- Comparison Logic ---
         // This is a placeholder. Real comparison needs to handle different data types (int, uint, bytes, etc.)
         // and various comparison operators securely. This requires careful encoding/decoding.
         // For simplicity, let's assume both _oracleResult and oracleData.expectedValue are bytes representation of integers or booleans.
         bool comparisonResult = false;
         if (oracleData.operator == ComparisonOperator.Equal) {
             comparisonResult = keccak256(_oracleResult) == keccak256(oracleData.expectedValue);
         } else if (oracleData.operator == ComparisonOperator.GreaterThan) {
             // Requires _oracleResult and expectedValue to be encoded as fixed-size integers
             require(_oracleResult.length == 32 && oracleData.expectedValue.length == 32, InvalidInput("Comparison requires 32-byte integer encoding"));
             int256 resultValue = abi.decode(_oracleResult, (int256)); // Assuming int256 for flexibility
             int256 expectedValue = abi.decode(oracleData.expectedValue, (int256));
             comparisonResult = resultValue > expectedValue;
         }
         // Add other comparison operators (LessThan, GreaterThanOrEqual, LessThanOrEqual, NotEqual) similarly

         condition.isMet = comparisonResult;
         condition.isValidated = true; // Mark as validated by an arbiter
         condition.validationTimestamp = block.timestamp;

         emit ConditionValidated(_escrowId, _conditionIndex, condition.isMet);
         emit ConditionChecked(_escrowId, _conditionIndex, condition.isMet);
     }


    // 18. evaluateAllConditions()
    /// @notice Evaluates the `isMet` status of all conditions and updates the escrow's state.
    /// @param _escrowId The ID of the escrow.
    /// @dev Can be called by anyone. Transitions state to ConditionsMet or ConditionsFailed.
    function evaluateAllConditions(uint256 _escrowId) external {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state == EscrowState.ConditionsPending, InvalidState(escrow.state, "evaluate conditions"));

        bool allMet = true;
        for (uint i = 0; i < escrow.conditions.length; i++) {
            // Important: Trigger checks for conditions that haven't been checked/validated yet
            // This handles Timestamp conditions automatically.
            // OracleData and PartyAgreement conditions need separate trigger/confirm calls first.
            // If an OracleData or PartyAgreement condition is *not* validated yet, `isMet` will be false.
            // The design assumes these conditions must be *explicitly* validated/resolved to become true.
            // If you want to allow automatic failure of non-validated conditions after a deadline, add that logic here.

             if (!escrow.conditions[i].isMet || !escrow.conditions[i].isValidated) {
                 // For OracleData and PartyAgreement, require validation.
                 // For Timestamp, isValidated is effectively true if checkCondition was called after timestamp.
                 // Let's simplify: Just check `isMet`. Responsibility is on parties to trigger check/validate functions.
                 if (!escrow.conditions[i].isMet) {
                     allMet = false;
                     break;
                 }
             }
        }

        if (allMet) {
            _changeState(escrow, EscrowState.ConditionsMet);
        } else {
            _changeState(escrow, EscrowState.ConditionsFailed);
        }
    }

    // 19. initiateDispute()
    /// @notice Initiates a dispute process, moving the escrow to the Dispute state.
    /// @param _escrowId The ID of the escrow.
    /// @dev Can be called by the initiator, any beneficiary, or any arbiter.
    /// @dev Only allowed in Active, ConditionsPending, ConditionsMet, or ConditionsFailed states.
    function initiateDispute(uint256 _escrowId) external {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state >= EscrowState.Active && escrow.state <= EscrowState.ConditionsFailed, InvalidState(escrow.state, "initiate dispute"));

        bool isParty = (escrow.initiator == msg.sender) || (_findBeneficiaryIndex(escrow, msg.sender) != -1) || (_findArbiterIndex(escrow, msg.sender) != -1);
        require(isParty, Unauthorized("only parties or arbiters can initiate dispute"));
        require(escrow.arbiters.length > 0, InvalidInput("cannot initiate dispute without arbiters"));

        _changeState(escrow, EscrowState.Dispute);
        emit DisputeInitiated(_escrowId, msg.sender);
    }

    // 20. submitArbitrationResult()
    /// @notice Allows an arbiter to submit their decision in a Dispute state.
    /// @param _escrowId The ID of the escrow.
    /// @param _outcome The decision outcome (AwardToBeneficiaries, AwardToInitiator, SplitAssets).
    /// @dev Only callable by an arbiter of the escrow. Requires the escrow to be in Dispute state.
    /// @dev Does NOT immediately apply the decision; requires `applyArbitrationDecision`.
    function submitArbitrationResult(uint256 _escrowId, ArbitrationOutcome _outcome) external onlyArbiter(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state == EscrowState.Dispute, InvalidState(escrow.state, "submit arbitration result"));
        require(_outcome != ArbitrationOutcome.Undecided, InvalidInput("outcome cannot be Undecided"));

        // Simple majority or specific arbiter logic could be added here if multiple arbiters.
        // For simplicity, any arbiter's submission sets the outcome. A real system needs consensus.
        escrow.arbitrationOutcome = _outcome;

        // Transition to Arbitrated state to signal decision is ready
        _changeState(escrow, EscrowState.Arbitrated);
        emit ArbitrationResultSubmitted(_escrowId, _outcome);
    }

    // 21. applyArbitrationDecision()
    /// @notice Applies the arbitration decision, releasing or returning assets based on the outcome.
    /// @param _escrowId The ID of the escrow.
    /// @dev Callable by anyone once the escrow is in the Arbitrated state.
    function applyArbitrationDecision(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state == EscrowState.Arbitrated, InvalidState(escrow.state, "apply arbitration decision"));
        require(escrow.arbitrationOutcome != ArbitrationOutcome.Undecided, InvalidInput("arbitration outcome not set"));

        if (escrow.arbitrationOutcome == ArbitrationOutcome.AwardToBeneficiaries) {
            _releaseAllAssets(escrow);
            _changeState(escrow, EscrowState.FundsReleased);
        } else if (escrow.arbitrationOutcome == ArbitrationOutcome.AwardToInitiator) {
            _returnAllAssetsToInitiator(escrow);
            _changeState(escrow, EscrowState.FundsReturned);
        } else if (escrow.arbitrationOutcome == ArbitrationOutcome.SplitAssets) {
            // *** Complex Logic Placeholder ***
            // Splitting assets requires a defined distribution plan based on the arbitration outcome.
            // This would need a dedicated data structure in the Escrow struct and complex transfer logic here.
            // For simplicity, we'll just revert in this basic implementation of SplitAssets.
            revert(InvalidInput("SplitAssets outcome requires complex distribution logic not implemented"));
        }

        emit ArbitrationDecisionApplied(_escrowId, escrow.arbitrationOutcome);

        // Move to Completed if all assets successfully transferred
        if (escrow.heldETH[_escrowId] == 0 && _getTotalHeldERC20(_escrowId) == 0 && _getTotalHeldERC721(_escrowId) == 0) {
            _changeState(escrow, EscrowState.Completed);
            emit EscrowFinalized(_escrowId);
        }
    }

    // --- Internal Asset Transfer Helpers ---
    function _releaseAllAssets(Escrow storage _escrow) internal {
        // Release ETH
        uint256 ethAmount = _escrow.heldETH[_escrow.id];
        if (ethAmount > 0) {
             // Simple equal split for demo. A real contract needs a distribution plan.
            uint256 numBeneficiaries = _escrow.beneficiaries.length;
            require(numBeneficiaries > 0, InvalidInput("no beneficiaries to release ETH")); // Should not happen if conditions met

            uint256 share = ethAmount / numBeneficiaries;
            uint256 remainder = ethAmount % numBeneficiaries;

            for (uint i = 0; i < numBeneficiaries; i++) {
                 uint256 transferAmount = share + (i == numBeneficiaries - 1 ? remainder : 0); // Add remainder to last beneficiary
                 if (transferAmount > 0) {
                     address payable beneficiaryAddr = payable(_escrow.beneficiaries[i]);
                     beneficiaryAddr.sendValue(transferAmount); // Use sendValue as it's safer against reentrancy
                     _escrow.heldETH[_escrow.id] -= transferAmount; // Deduct locally after successful send
                     emit ETHReleased(_escrow.id, _escrow.beneficiaries[i], transferAmount);
                 }
             }
        }

        // Release ERC20
        // Iterate through all unique token addresses held for this escrow
        // This requires tracking unique tokens, which the current mapping doesn't do easily.
        // A set or array of token addresses would be needed.
        // For simplicity, we can't iterate efficiently here.
        // A better structure: `mapping(uint256 => address[]) heldERC20Tokens;` and `mapping(uint256 => mapping(address => uint256)) heldERC20Amounts;`
        // Let's skip the actual ERC20/ERC721 transfer *all* logic for simplicity in this sample and focus on ETH or specific partial transfers.
        // Realistically, you'd iterate through the *list* of token addresses held for the escrow.

        // Placeholder for ERC20/ERC721 release:
        // For a realistic implementation, you'd iterate through held token addresses and tokenIds
        // based on a defined distribution rule (e.g., equal split, specific allocation per beneficiary).
        // This requires more complex data structures than currently defined.
        // We will only implement partial release below which is more controlled.
    }

     function _returnAllAssetsToInitiator(Escrow storage _escrow) internal {
        // Return ETH
        uint256 ethAmount = _escrow.heldETH[_escrow.id];
         if (ethAmount > 0) {
             _escrow.initiator.sendValue(ethAmount); // Use sendValue
              _escrow.heldETH[_escrow.id] = 0; // Clear balance
              emit ETHReturned(_escrow.id, _escrow.initiator, ethAmount);
         }

        // Return ERC20
        // As with _releaseAllAssets, iterating through held ERC20 tokens requires tracking token addresses.
        // Skipping full return for simplicity, focus on partial return.

        // Return ERC721
        // Skipping full return for simplicity, focus on partial return.
    }

    // Helper for total held amounts (view only, doesn't count towards the 20+ requirement)
     function _getTotalHeldERC20(uint256 _escrowId) internal view returns (uint256) {
        // Cannot sum across different token addresses easily with the current structure.
        // This helper is ineffective for total value, only total *count* of unique tokens if token list was available.
        // Let's return 1 if any ERC20 is held, otherwise 0, as a proxy.
        // A proper implementation needs `mapping(uint256 => address[]) heldERC20Tokens;`
        return Object.keys(escrows[_escrowId].heldERC20[_escrowId]).length > 0 ? 1 : 0; // Placeholder check
     }

     function _getTotalHeldERC721(uint256 _escrowId) internal view returns (uint256) {
         // Cannot sum across different token addresses easily.
          return Object.keys(escrows[_escrowId].heldERC721TokenIds[_escrowId]).length > 0 ? 1 : 0; // Placeholder check
     }


    // 22. releaseAssets()
    /// @notice Allows beneficiaries to claim their share of assets if conditions are met.
    /// @param _escrowId The ID of the escrow.
    /// @dev Only callable by beneficiaries. Releases based on defined distribution logic (simple: equal split in demo).
    /// @dev Transitions state to FundsReleased if called for the first time.
    function releaseAssets(uint256 _escrowId) external nonReentrant onlyBeneficiary(_escrowId) {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state == EscrowState.ConditionsMet || escrow.state == EscrowState.Arbitrated, InvalidState(escrow.state, "release assets"));
        // Ensure the arbitration outcome was favorable if state is Arbitrated
        if (escrow.state == EscrowState.Arbitrated) {
             require(escrow.arbitrationOutcome == ArbitrationOutcome.AwardToBeneficiaries, InvalidInput("Arbitration outcome not favorable for beneficiaries"));
        }


        // *** Distribution Logic Placeholder ***
        // This is where complex distribution per beneficiary is implemented.
        // For this example, it's a simple claim mechanism for ETH (assumes equal split per beneficiary upon claim)
        // ERC20/ERC721 release needs specific logic per token/NFT.
        // A robust system would track which beneficiary is owed what amount/tokenId.

        // Simple Demo Logic: Each beneficiary can claim a share of *remaining* ETH upon calling.
        // This is NOT standard and has issues with multiple claims. A proper system tracks owed amounts.
        // Let's instead model a system where beneficiaries claim specific types/amounts if they are due.
        // Requires knowing *what* this beneficiary is supposed to get.

        // Reverting to force using partial release which is more explicit.
        revert("Use releasePartialAssets to claim specific assets.");
    }

     // 23. releasePartialAssets()
    /// @notice Allows beneficiaries to claim specific assets (ETH, ERC20, ERC721) allocated to them.
    /// @param _escrowId The ID of the escrow.
    /// @param _ethAmount Amount of ETH to claim (0 if none).
    /// @param _erc20Claims Array of ERC20 claims (token address, amount).
    /// @param _erc721Claims Array of ERC721 claims (token address, token IDs).
    /// @dev Only callable by beneficiaries. Requires conditions met or favorable arbitration.
    /// @dev This function requires the contract to know *which* assets/amounts are designated for *this* beneficiary.
    /// @dev This requires a complex `distributionPlan` data structure per escrow or per beneficiary, which isn't fully implemented here.
    /// @dev The current implementation will just transfer *if* the assets are held, which is insecure without a distribution plan.
    ///      *** WARNING: This implementation is a simplified placeholder and needs a proper distribution plan! ***
     function releasePartialAssets(
         uint256 _escrowId,
         uint256 _ethAmount,
         tuple(address tokenAddress, uint256 amount)[] calldata _erc20Claims,
         tuple(address tokenAddress, uint256[] tokenIds)[] calldata _erc721Claims
     ) external nonReentrant onlyBeneficiary(_escrowId) {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.ConditionsMet || escrow.state == EscrowState.Arbitrated, InvalidState(escrow.state, "release partial assets"));
         // Ensure the arbitration outcome was favorable if state is Arbitrated
         if (escrow.state == EscrowState.Arbitrated) {
              require(escrow.arbitrationOutcome == ArbitrationOutcome.AwardToBeneficiaries, InvalidInput("Arbitration outcome not favorable for beneficiaries"));
         }

         bool assetsTransferred = false;

         // Claim ETH
         if (_ethAmount > 0) {
             // *** Placeholder Distribution Check ***
             // A real system would check if msg.sender is *entitled* to this _ethAmount from a pool or specific allocation.
             // This demo just checks if the escrow holds enough total ETH, which is insufficient for security.
             require(escrow.heldETH[_escrow.id] >= _ethAmount, NoAssetsToClaim());

             payable(msg.sender).sendValue(_ethAmount); // Use sendValue
             escrow.heldETH[_escrow.id] -= _ethAmount;
             assetsTransferred = true;
             emit ETHReleased(_escrow.id, msg.sender, _ethAmount);
         }

         // Claim ERC20
         for (uint i = 0; i < _erc20Claims.length; i++) {
             address tokenAddress = _erc20Claims[i].tokenAddress;
             uint256 amount = _erc20Claims[i].amount;
             if (amount > 0) {
                 // *** Placeholder Distribution Check ***
                 // Check if msg.sender is entitled to this amount of this token.
                 require(escrow.heldERC20[_escrow.id][tokenAddress] >= amount, NoAssetsToClaim());

                 IERC20 token = IERC20(tokenAddress);
                 require(token.transfer(msg.sender, amount), "ERC20 transfer failed");
                 escrow.heldERC20[_escrow.id][tokenAddress] -= amount;
                 assetsTransferred = true;
                 emit ERC20Released(_escrow.id, msg.sender, tokenAddress, uint24(amount)); // Cast to uint24 for event log size, assumes amount fits
             }
         }

         // Claim ERC721
         for (uint i = 0; i < _erc721Claims.length; i++) {
             address tokenAddress = _erc721Claims[i].tokenAddress;
             uint256[] calldata tokenIds = _erc721Claims[i].tokenIds;
             IERC721 token = IERC721(tokenAddress);

             for (uint j = 0; j < tokenIds.length; j++) {
                 uint256 tokenId = tokenIds[j];
                 // *** Placeholder Distribution Check ***
                 // Check if msg.sender is entitled to this specific tokenId.
                 // Requires searching the heldERC721TokenIds array and removing the element.
                 // Array manipulation is costly. A mapping(tokenId => bool isHeldForEscrow) + separate distribution map is better.

                 // Simplified check: just confirm the contract *holds* this NFT for this escrow ID.
                 // Insecure without knowing entitlement.
                 bool isHeld = false;
                 uint265 heldIndex = 0; // Placeholder
                 for(uint k = 0; k < escrow.heldERC721TokenIds[_escrow.id][tokenAddress].length; k++) {
                     if(escrow.heldERC721TokenIds[_escrow.id][tokenAddress][k] == tokenId) {
                         isHeld = true;
                         heldIndex = k; // Store index for removal
                         break;
                     }
                 }
                 require(isHeld, NoAssetsToClaim());

                 // Transfer the NFT
                 token.safeTransferFrom(address(this), msg.sender, tokenId);

                 // Remove the tokenId from the held list for this escrow (costly)
                 uint lastIndex = escrow.heldERC721TokenIds[_escrow.id][tokenAddress].length - 1;
                 if (heldIndex != lastIndex) {
                      escrow.heldERC721TokenIds[_escrow.id][tokenAddress][heldIndex] = escrow.heldERC721TokenIds[_escrow.id][tokenAddress][lastIndex];
                 }
                 escrow.heldERC721TokenIds[_escrow.id][tokenAddress].pop();


                 assetsTransferred = true;
                 emit ERC721Released(_escrow.id, msg.sender, tokenAddress, tokenId);
             }
         }

         require(assetsTransferred, NoAssetsToClaim());

         // Check if all assets are now dispersed from this escrow
         if (escrow.heldETH[_escrow.id] == 0 && _getTotalHeldERC20(_escrow.id) == 0 && _getTotalHeldERC721(_escrow.id) == 0) {
              _changeState(escrow, EscrowState.Completed);
              emit EscrowFinalized(_escrow.id);
         } else {
             // If not all assets gone, but some were released
             _changeState(escrow, EscrowState.FundsReleased); // Stay in FundsReleased or transition
         }
     }


    // 24. returnAssetsToInitiator()
    /// @notice Allows the initiator to reclaim all assets if conditions failed or due to arbitration.
    /// @param _escrowId The ID of the escrow.
    /// @dev Only callable by the initiator. Releases all remaining assets held for this escrow ID.
     function returnAssetsToInitiator(uint256 _escrowId) external nonReentrant onlyInitiator(_escrowId) {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.ConditionsFailed || escrow.state == EscrowState.Arbitrated, InvalidState(escrow.state, "return assets"));
         // Ensure the arbitration outcome was favorable if state is Arbitrated
         if (escrow.state == EscrowState.Arbitrated) {
              require(escrow.arbitrationOutcome == ArbitrationOutcome.AwardToInitiator, InvalidInput("Arbitration outcome not favorable for initiator"));
         }

         _returnAllAssetsToInitiator(escrow);

         // Check if all assets are now dispersed
         if (escrow.heldETH[_escrow.id] == 0 && _getTotalHeldERC20(_escrow.id) == 0 && _getTotalHeldERC721(_escrow.id) == 0) {
             _changeState(escrow, EscrowState.Completed);
              emit EscrowFinalized(_escrow.id);
         } else {
             _changeState(escrow, EscrowState.FundsReturned); // Stay in FundsReturned or transition
         }
     }

     // 25. returnPartialAssetsToInitiator()
     /// @notice Allows the initiator to reclaim specific remaining assets (ETH, ERC20, ERC721).
    /// @param _escrowId The ID of the escrow.
    /// @param _ethAmount Amount of ETH to reclaim (0 if none).
    /// @param _erc20Returns Array of ERC20 returns (token address, amount).
    /// @param _erc721Returns Array of ERC721 returns (token address, token IDs).
    /// @dev Only callable by the initiator. Requires conditions failed or favorable arbitration.
    /// @dev Initiator can only reclaim assets still held *by* the escrow.
     function returnPartialAssetsToInitiator(
         uint256 _escrowId,
         uint256 _ethAmount,
         tuple(address tokenAddress, uint256 amount)[] calldata _erc20Returns,
         tuple(address tokenAddress, uint256[] tokenIds)[] calldata _erc721Returns
     ) external nonReentrant onlyInitiator(_escrowId) {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.ConditionsFailed || escrow.state == EscrowState.Arbitrated, InvalidState(escrow.state, "return partial assets"));
         // Ensure the arbitration outcome was favorable if state is Arbitrated
         if (escrow.state == EscrowState.Arbitrated) {
              require(escrow.arbitrationOutcome == ArbitrationOutcome.AwardToInitiator, InvalidInput("Arbitration outcome not favorable for initiator"));
         }

          bool assetsTransferred = false;

         // Return ETH
         if (_ethAmount > 0) {
             require(escrow.heldETH[_escrow.id] >= _ethAmount, NoAssetsToClaim());
             escrow.initiator.sendValue(_ethAmount); // Use sendValue
             escrow.heldETH[_escrow.id] -= _ethAmount;
             assetsTransferred = true;
             emit ETHReturned(_escrow.id, escrow.initiator, _ethAmount);
         }

         // Return ERC20
         for (uint i = 0; i < _erc20Returns.length; i++) {
             address tokenAddress = _erc20Returns[i].tokenAddress;
             uint256 amount = _erc20Returns[i].amount;
             if (amount > 0) {
                 require(escrow.heldERC20[_escrow.id][tokenAddress] >= amount, NoAssetsToClaim());

                 IERC20 token = IERC20(tokenAddress);
                 require(token.transfer(escrow.initiator, amount), "ERC20 transfer failed");
                 escrow.heldERC20[_escrow.id][tokenAddress] -= amount;
                 assetsTransferred = true;
                 emit ERC20Returned(_escrow.id, escrow.initiator, tokenAddress, uint24(amount)); // Cast to uint24
             }
         }

         // Return ERC721
         for (uint i = 0; i < _erc721Returns.length; i++) {
             address tokenAddress = _erc721Returns[i].tokenAddress;
             uint256[] calldata tokenIds = _erc721Returns[i].tokenIds;
             IERC721 token = IERC721(tokenAddress);

             for (uint j = 0; j < tokenIds.length; j++) {
                 uint256 tokenId = tokenIds[j];
                 // Check if the contract holds this specific tokenId for this escrow
                 bool isHeld = false;
                 uint256 heldIndex = 0; // Placeholder
                 for(uint k = 0; k < escrow.heldERC721TokenIds[_escrow.id][tokenAddress].length; k++) {
                     if(escrow.heldERC721TokenIds[_escrow.id][tokenAddress][k] == tokenId) {
                         isHeld = true;
                         heldIndex = k; // Store index for removal
                         break;
                     }
                 }
                 require(isHeld, NoAssetsToClaim());

                 // Transfer the NFT back
                 token.safeTransferFrom(address(this), escrow.initiator, tokenId);

                 // Remove the tokenId from the held list for this escrow (costly)
                 uint lastIndex = escrow.heldERC721TokenIds[_escrow.id][tokenAddress].length - 1;
                 if (heldIndex != lastIndex) {
                      escrow.heldERC721TokenIds[_escrow.id][tokenAddress][heldIndex] = escrow.heldERC721TokenIds[_escrow.id][tokenAddress][lastIndex];
                 }
                 escrow.heldERC721TokenIds[_escrow.id][tokenAddress].pop();

                 assetsTransferred = true;
                 emit ERC721Returned(_escrow.id, escrow.initiator, tokenAddress, tokenId);
             }
         }

         require(assetsTransferred, NoAssetsToClaim());

         // Check if all assets are now dispersed
         if (escrow.heldETH[_escrow.id] == 0 && _getTotalHeldERC20(_escrow.id) == 0 && _getTotalHeldERC721(_escrow.id) == 0) {
              _changeState(escrow, EscrowState.Completed);
              emit EscrowFinalized(_escrow.id);
         } else {
              _changeState(escrow, EscrowState.FundsReturned); // Stay in FundsReturned or transition
         }
     }


    // 26. cancelEscrow()
    /// @notice Allows the initiator or an arbiter to cancel the escrow.
    /// @param _escrowId The ID of the escrow.
    /// @dev Only allowed in Draft, Active, ConditionsPending states, or Dispute state (by arbiter).
    /// @dev Returns all deposited assets to the initiator.
    function cancelEscrow(uint256 _escrowId) external nonReentrant {
        Escrow storage escrow = _getEscrow(_escrowId);
        require(escrow.state <= EscrowState.ConditionsPending || (escrow.state == EscrowState.Dispute && _findArbiterIndex(escrow, msg.sender) != -1), InvalidState(escrow.state, "cancel escrow"));

        bool isInitiator = escrow.initiator == msg.sender;
        bool isArbiter = _findArbiterIndex(escrow, msg.sender) != -1;
        require(isInitiator || (isArbiter && escrow.state == EscrowState.Dispute), Unauthorized("only initiator (in allowed states) or arbiter (in Dispute) can cancel"));


        // Return all assets to the initiator
        _returnAllAssetsToInitiator(escrow);

        _changeState(escrow, EscrowState.Cancelled);
        emit EscrowCancelled(_escrowId, msg.sender);

        // Mark as Completed if all assets were successfully returned
        if (escrow.heldETH[_escrow.id] == 0 && _getTotalHeldERC20(_escrow.id) == 0 && _getTotalHeldERC721(_escrow.id) == 0) {
             _changeState(escrow, EscrowState.Completed);
             emit EscrowFinalized(_escrow.id);
        }
    }

    // 27. finalizeEscrow()
    /// @notice Explicitly marks an escrow as Completed if all assets have been dispersed.
    /// @param _escrowId The ID of the escrow.
    /// @dev Can be called by anyone. Useful if partial releases leave the state as FundsReleased/Returned.
    function finalizeEscrow(uint256 _escrowId) external {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state == EscrowState.FundsReleased || escrow.state == EscrowState.FundsReturned, InvalidState(escrow.state, "finalize escrow"));

         // Check if all assets are truly gone
         require(escrow.heldETH[_escrow.id] == 0 && _getTotalHeldERC20(_escrow.id) == 0 && _getTotalHeldERC721(_escrow.id) == 0, InvalidInput("assets still held"));

         _changeState(escrow, EscrowState.Completed);
         emit EscrowFinalized(_escrowId);
    }


    // --- Update Proposal System Functions ---

    // 28. proposeUpdate()
    /// @notice Creates a proposal to modify the escrow (e.g., change beneficiaries, distribution plan).
    /// @param _escrowId The ID of the escrow.
    /// @param _proposalData Encoded data representing the proposed changes.
    /// @param _requiredApprovals The number of approvals required from beneficiaries/arbiters.
    /// @dev Only callable by the initiator. Allowed in Draft, Active, ConditionsPending states.
    /// @dev *** NOTE: The contract does not currently interpret `_proposalData`. This is a placeholder for future logic. ***
     function proposeUpdate(uint256 _escrowId, bytes calldata _proposalData, uint256 _requiredApprovals) external onlyInitiator(_escrowId) {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state <= EscrowState.ConditionsPending, InvalidState(escrow.state, "propose update"));
         require(_proposalData.length > 0, InvalidInput("proposal data cannot be empty"));
         require(_requiredApprovals > 0, InvalidInput("required approvals must be greater than zero"));
         require(_requiredApprovals <= escrow.beneficiaries.length + escrow.arbiters.length, InvalidInput("required approvals exceeds total possible approvers"));

         uint256 proposalId = escrow.nextProposalId++;
         UpdateProposal storage proposal = escrow.proposals[proposalId];

         proposal.proposalId = proposalId;
         proposal.escrowId = _escrowId;
         proposal.proposalData = _proposalData;
         proposal.requiredApprovals = _requiredApprovals;
         proposal.currentApprovals = 0;
         proposal.executed = false;

         emit ProposalCreated(_escrowId, proposalId, _proposalData);
     }

     // 29. approveUpdateProposal()
     /// @notice Approves an outstanding proposal for an escrow update.
    /// @param _escrowId The ID of the escrow.
    /// @param _proposalId The ID of the proposal.
    /// @dev Callable by beneficiaries and arbiters of the escrow.
    /// @dev An address can only approve once per proposal.
     function approveUpdateProposal(uint256 _escrowId, uint256 _proposalId) external {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state <= EscrowState.ConditionsPending, InvalidState(escrow.state, "approve proposal"));

         UpdateProposal storage proposal = escrow.proposals[_proposalId];
         require(proposal.escrowId == _escrowId, ProposalNotFound(_escrowId, _proposalId));
         require(!proposal.executed, ProposalAlreadyExecuted(_proposalId));

         // Check if msg.sender is a beneficiary or arbiter
         bool isApprover = (_findBeneficiaryIndex(escrow, msg.sender) != -1) || (_findArbiterIndex(escrow, msg.sender) != -1);
         require(isApprover, Unauthorized("only beneficiaries or arbiters can approve"));

         require(!proposal.approvals[msg.sender], InvalidInput("already approved"));

         proposal.approvals[msg.sender] = true;
         proposal.currentApprovals++;

         emit ProposalApproved(_escrowId, _proposalId, msg.sender);
     }

     // 30. executeUpdateProposal()
     /// @notice Executes a proposal that has received the required number of approvals.
    /// @param _escrowId The ID of the escrow.
    /// @param _proposalId The ID of the proposal.
    /// @dev Callable by anyone.
    /// @dev *** NOTE: The contract does not currently interpret or apply `proposalData`. This is a placeholder. ***
     function executeUpdateProposal(uint256 _escrowId, uint256 _proposalId) external {
         Escrow storage escrow = _getEscrow(_escrowId);
         require(escrow.state <= EscrowState.ConditionsPending, InvalidState(escrow.state, "execute proposal"));

         UpdateProposal storage proposal = escrow.proposals[_proposalId];
         require(proposal.escrowId == _escrowId, ProposalNotFound(_escrowId, _proposalId));
         require(!proposal.executed, ProposalAlreadyExecuted(_proposalId));
         require(proposal.currentApprovals >= proposal.requiredApprovals, ProposalNotApproved(_proposalId));

         // *** Placeholder for applying the proposal data ***
         // This is the core logic that would parse proposal.proposalData
         // and modify the escrow struct (e.g., change beneficiaries, update distribution plan).
         // Example:
         // (bytes32 action, bytes data) = abi.decode(proposal.proposalData, (bytes32, bytes));
         // if (action == "ADD_BENEFICIARY") { ... }
         // else if (action == "UPDATE_DISTRIBUTION") { ... }
         // etc.
         // This part is highly specific to the types of updates you want to support.
         // Without implementing specific parsing and modification, this function is just a stub.

         // Mark as executed
         proposal.executed = true;

         emit ProposalExecuted(_escrowId, _proposalId);
     }

    // --- View Functions (Getters - not counted towards the 20+ logic functions) ---
    // Add these as needed for external applications to query the state.
    // Example:
    // function getEscrowState(uint256 _escrowId) external view returns (EscrowState) {
    //     return _getEscrow(_escrowId).state;
    // }
    // function getConditionDetails(uint256 _escrowId, uint256 _conditionIndex) external view returns (Condition memory) {
    //      Escrow storage escrow = _getEscrow(_escrowId);
    //      require(_conditionIndex < escrow.conditions.length, ConditionNotFound(_escrowId, _conditionIndex));
    //      return escrow.conditions[_conditionIndex];
    // }
    // function getHeldETH(uint256 _escrowId) external view returns (uint256) {
    //      return escrows[_escrowId].heldETH[_escrowId];
    // }
    // function getHeldERC20(uint256 _escrowId, address _tokenAddress) external view returns (uint256) {
    //     return escrows[_escrowId].heldERC20[_escrowId][_tokenAddress];
    // }
    // function getHeldERC721(uint256 _escrowId, address _tokenAddress) external view returns (uint256[] memory) {
    //     return escrows[_escrowId].heldERC721TokenIds[_escrowId][_tokenAddress];
    // }
    // etc.
    // Added `public` to struct mappings/arrays where appropriate to allow default getter creation.
    // The `getHeldERC721` example above requires explicit implementation because Solidity doesn't auto-generate getters for dynamic arrays in mappings.

}
```