Okay, let's design a smart contract that acts as a versatile, somewhat autonomous treasury hub with advanced distribution and management features, going beyond standard multisig or simple DAO treasury patterns.

We'll incorporate concepts like:
*   **Conditional Distributions:** Releasing funds only when certain on-chain conditions are met (e.g., time elapsed).
*   **Batch Operations:** Performing multiple transfers in a single transaction (via proposal).
*   **Internal Grant System:** A simple mechanism for users to request funds which admins can then propose/approve.
*   **Role-Based Access Control (Simplified):** Beyond just an owner, introduce an 'admin' role for proposal approval and parameter changes.
*   **Dynamic Parameters:** Key contract parameters (like approval threshold, cooldowns) are adjustable via governance proposals.
*   **Proposal System:** A framework for proposing actions (withdrawals, parameter changes, conditional rules, etc.) that require admin approval.
*   **Dust Sweeping:** A specific proposal type to consolidate small amounts of various tokens.

This structure is not a direct copy of standard open-source libraries like OpenZeppelin's Governor or Treasury, though it borrows fundamental ideas like proposal patterns. The combination of specific proposal types (conditional, batch, sweep) and the internal grant request flow makes it distinct.

---

**Contract Name:** CreativeTreasuryHub

**Description:** A multi-asset treasury capable of holding ETH and various ERC-20 tokens. It implements a proposal system requiring administrator approval for most outflows and critical parameter changes. It supports advanced functions like conditional fund distributions, batch transfers, and a simple internal grant request mechanism.

**Outline:**

1.  **Interfaces:** Import necessary interfaces (IERC20).
2.  **Libraries:** SafeMath (though Solidity 0.8+ handles overflow), SafeERC20.
3.  **State Variables:**
    *   Owner (for initial setup and emergency).
    *   Admin Role mapping.
    *   Pausable state.
    *   Treasury parameters (proposal threshold, cooldown, duration).
    *   Registered ERC20 tokens mapping and list.
    *   Proposal tracking (struct, mapping, next ID).
    *   Grant Request tracking (struct, mapping, next ID).
4.  **Enums:** ProposalType, ProposalState, ConditionType, GrantRequestState.
5.  **Structs:** Proposal, GrantRequest.
6.  **Events:** Actions related to proposals, grants, admin roles, parameters, pausing, etc.
7.  **Modifiers:** onlyAdmin, onlyOwner, whenNotPaused, whenPaused.
8.  **Constructor:** Set initial owner and maybe initial admin.
9.  **Receive ETH:** Allow direct ETH transfers.
10. **Admin/Role Management:**
    *   Add/Remove Admin role.
    *   Check Admin role.
11. **Treasury In:**
    *   Deposit ERC20.
12. **Treasury Out / Proposal Creation:**
    *   Propose ETH withdrawal.
    *   Propose ERC20 withdrawal.
    *   Propose arbitrary contract call.
    *   Propose updating treasury parameters.
    *   Propose adding/removing ERC20 support.
    *   Propose Conditional ETH distribution.
    *   Propose Conditional ERC20 distribution.
    *   Propose Batch ETH withdrawal.
    *   Propose Batch ERC20 withdrawal.
    *   Propose Sweeping Dust ERC20.
    *   Propose approving a Grant Request.
    *   Propose rejecting a Grant Request.
13. **Governance / Proposal Management & Execution:**
    *   Admin Approval of a proposal.
    *   Cancel proposal (by proposer or admin).
    *   Execute proposal (if approved and within time constraints).
    *   Execute Conditional Distribution (specific function to trigger based on condition).
    *   Execute Batch Withdrawal (specific function to trigger batch transfers).
    *   Execute Dust Sweeping (specific function to trigger dust transfers).
    *   Execute Grant Action (triggers withdrawal after approval).
14. **Grant Request System:**
    *   Submit a Grant Request (external users).
    *   Cancel a Grant Request (by requester).
15. **Views:**
    *   Get ETH balance.
    *   Get ERC20 balance.
    *   Check if address is admin.
    *   Get proposal details.
    *   Get proposal approval status.
    *   Get grant request details.
    *   Get registered ERC20 list.
    *   Get total proposal count.
    *   Get total grant request count.

**Function Summary (Targeting 20+ unique actions/views):**

1.  `constructor(address initialAdmin)`: Initializes the contract, sets owner (via Ownable), and an initial admin.
2.  `receive() external payable`: Allows receiving ETH.
3.  `depositERC20(address tokenAddress, uint256 amount)`: Allows depositing specific amounts of supported ERC20 tokens.
4.  `addAdmin(address _admin)`: Grants admin role (Owner only).
5.  `removeAdmin(address _admin)`: Revokes admin role (Owner only).
6.  `isAdmin(address _address) view returns (bool)`: Checks if an address is an admin.
7.  `pause()`: Pauses the contract (Admin only).
8.  `unpause()`: Unpauses the contract (Admin only).
9.  `proposeWithdrawETH(address recipient, uint256 amount, string calldata description)`: Creates a proposal to withdraw ETH.
10. `proposeWithdrawERC20(address tokenAddress, address recipient, uint256 amount, string calldata description)`: Creates a proposal to withdraw ERC20.
11. `proposeExecuteCall(address target, bytes calldata callData, string calldata description)`: Creates a proposal for an arbitrary contract call.
12. `proposeUpdateParameters(uint256 newThreshold, uint256 newCooldown, uint256 newDuration, string calldata description)`: Creates a proposal to change treasury parameters.
13. `proposeAddERC20Support(address tokenAddress, string calldata description)`: Creates a proposal to register a new ERC-20 token for tracking/management.
14. `proposeRemoveERC20Support(address tokenAddress, string calldata description)`: Creates a proposal to deregister an ERC-20 token.
15. `proposeConditionalDistributionETH(address recipient, uint256 amount, ConditionType conditionType, uint256 conditionValue, string calldata description)`: Creates a proposal for a time-based ETH distribution.
16. `proposeConditionalDistributionERC20(address tokenAddress, address recipient, uint256 amount, ConditionType conditionType, uint256 conditionValue, string calldata description)`: Creates a proposal for a time-based ERC-20 distribution.
17. `proposeBatchWithdrawETH(address[] calldata recipients, uint256[] calldata amounts, string calldata description)`: Creates a proposal for a batch ETH withdrawal.
18. `proposeBatchWithdrawERC20(address tokenAddress, address[] calldata recipients, uint256[] calldata amounts, string calldata description)`: Creates a proposal for a batch ERC-20 withdrawal.
19. `proposeSweepDustERC20(address recipient, address[] calldata tokensToSweep, string calldata description)`: Creates a proposal to consolidate small amounts of specified ERC-20s.
20. `submitGrantRequest(uint256 amountETH, address tokenAddress, uint256 amountERC20, string calldata purpose)`: Allows an external user to submit a request for funds.
21. `cancelGrantRequest(uint256 requestId)`: Allows the requester to cancel their pending grant request.
22. `proposeGrantApproval(uint256 requestId, string calldata description)`: Admin action to propose approving a specific grant request.
23. `proposeGrantRejection(uint256 requestId, string calldata description)`: Admin action to propose rejecting a specific grant request.
24. `approveProposal(uint256 proposalId)`: Admin action to approve a proposal.
25. `cancelProposal(uint256 proposalId)`: Cancels a proposal (by proposer or admin).
26. `executeProposal(uint256 proposalId)`: Executes a standard proposal (withdrawal, call, parameter update) if approved and ready.
27. `executeConditionalDistribution(uint256 proposalId)`: Executes a conditional distribution proposal if condition met.
28. `executeBatchWithdrawal(uint256 proposalId)`: Executes a batch withdrawal proposal.
29. `executeSweepDustERC20(uint256 proposalId)`: Executes a dust sweeping proposal.
30. `executeGrantAction(uint256 proposalId)`: Executes the approved grant action (performs the withdrawal).
31. `getETHBalance() view returns (uint256)`: Gets the contract's ETH balance.
32. `getERC20Balance(address tokenAddress) view returns (uint256)`: Gets the contract's ERC-20 balance for a specific token.
33. `getProposalDetails(uint256 proposalId) view returns (...)`: Returns details of a proposal.
34. `getProposalApprovalStatus(uint256 proposalId) view returns (uint256 approvals, uint256 required)`: Gets current approvals vs required.
35. `getGrantRequestDetails(uint256 requestId) view returns (...)`: Returns details of a grant request.
36. `getRegisteredERC20s() view returns (address[])`: Gets the list of registered ERC-20 tokens.
37. `getProposalCount() view returns (uint256)`: Gets the total number of proposals.
38. `getGrantRequestCount() view returns (uint256)`: Gets the total number of grant requests.

This list provides 38 distinct functions, comfortably exceeding the requirement of 20. Some are views, but many involve state changes, access control, and complex logic flows (propose -> approve -> execute, conditional checks, batch operations, grant workflow).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Outline:
// 1. Interfaces (IERC20 - included via SafeERC20)
// 2. Libraries (SafeERC20, Address)
// 3. State Variables
// 4. Enums
// 5. Structs
// 6. Events
// 7. Modifiers
// 8. Constructor
// 9. Receive ETH
// 10. Admin/Role Management (Owner & Admin)
// 11. Treasury In (ETH handled by receive, ERC20 deposit)
// 12. Treasury Out / Proposal Creation (various types)
// 13. Governance / Proposal Management & Execution
// 14. Grant Request System (Submit, Cancel by requester, Admin propose approve/reject)
// 15. Views

// Function Summary:
// 1.  constructor(address initialAdmin): Initializes with an owner (from Ownable) and sets an initial admin.
// 2.  receive() external payable: Allows contract to receive Ether.
// 3.  depositERC20(address tokenAddress, uint256 amount): Deposits a specific amount of a registered ERC-20 token.
// 4.  addAdmin(address _admin): Grants admin role (Owner only).
// 5.  removeAdmin(address _admin): Revokes admin role (Owner only).
// 6.  isAdmin(address _address) view returns (bool): Checks if an address has the admin role.
// 7.  pause(): Pauses contract operations (Admin only).
// 8.  unpause(): Unpauses contract operations (Admin only).
// 9.  proposeWithdrawETH(address recipient, uint256 amount, string calldata description): Creates a proposal to send ETH.
// 10. proposeWithdrawERC20(address tokenAddress, address recipient, uint256 amount, string calldata description): Creates a proposal to send ERC-20 tokens.
// 11. proposeExecuteCall(address target, bytes calldata callData, string calldata description): Creates a proposal for a generic contract interaction.
// 12. proposeUpdateParameters(uint256 newThreshold, uint256 newCooldown, uint256 newDuration, string calldata description): Creates a proposal to change governance parameters.
// 13. proposeAddERC20Support(address tokenAddress, string calldata description): Creates a proposal to add an ERC-20 token to the registered list.
// 14. proposeRemoveERC20Support(address tokenAddress, string calldata description): Creates a proposal to remove an ERC-20 token from the registered list.
// 15. proposeConditionalDistributionETH(address recipient, uint256 amount, ConditionType conditionType, uint256 conditionValue, string calldata description): Proposes conditional ETH transfer based on a condition (e.g., time).
// 16. proposeConditionalDistributionERC20(address tokenAddress, address recipient, uint256 amount, ConditionType conditionType, uint256 conditionValue, string calldata description): Proposes conditional ERC-20 transfer.
// 17. proposeBatchWithdrawETH(address[] calldata recipients, uint256[] calldata amounts, string calldata description): Proposes multiple ETH transfers in one go.
// 18. proposeBatchWithdrawERC20(address tokenAddress, address[] calldata recipients, uint256[] calldata amounts, string calldata description): Proposes multiple ERC-20 transfers in one go.
// 19. proposeSweepDustERC20(address recipient, address[] calldata tokensToSweep, string calldata description): Proposes consolidating small token balances into one address.
// 20. submitGrantRequest(uint256 amountETH, address tokenAddress, uint256 amountERC20, string calldata purpose): Allows external users to request funds.
// 21. cancelGrantRequest(uint256 requestId): Allows a requester to cancel their submitted request.
// 22. proposeGrantApproval(uint256 requestId, string calldata description): Admin proposes approving a grant request.
// 23. proposeGrantRejection(uint256 requestId, string calldata description): Admin proposes rejecting a grant request.
// 24. approveProposal(uint256 proposalId): Admin approves a proposal, potentially triggering state change to Approved.
// 25. cancelProposal(uint256 proposalId): Cancels a pending proposal (by proposer or admin).
// 26. executeProposal(uint256 proposalId): Executes a standard Approved proposal after cooldown.
// 27. executeConditionalDistribution(uint256 proposalId): Executes an Approved conditional proposal if its condition is met.
// 28. executeBatchWithdrawal(uint256 proposalId): Executes an Approved batch withdrawal proposal.
// 29. executeSweepDustERC20(uint256 proposalId): Executes an Approved dust sweeping proposal.
// 30. executeGrantAction(uint256 proposalId): Executes the grant action (withdrawal) for an Approved grant proposal.
// 31. getETHBalance() view returns (uint256): Returns the contract's current ETH balance.
// 32. getERC20Balance(address tokenAddress) view returns (uint256): Returns the contract's current balance for a specific ERC-20.
// 33. getProposalDetails(uint256 proposalId) view returns (uint256 id, address proposer, ProposalType pType, ProposalState state, uint256 creationTime, uint256 approvalTime, uint256 expiryTime, uint256 currentApprovals, uint256 requiredApprovals, bytes memory data, string memory description): Gets full details of a proposal.
// 34. getProposalApprovalStatus(uint256 proposalId) view returns (uint256 currentApprovals, uint256 requiredApprovals): Gets just the approval counts for a proposal.
// 35. getGrantRequestDetails(uint256 requestId) view returns (uint256 id, address requester, uint256 amountETH, address tokenAddress, uint256 amountERC20, GrantRequestState state, string memory purpose, uint256 submissionTime, uint256 relatedProposalId): Gets full details of a grant request.
// 36. getRegisteredERC20s() view returns (address[] memory): Gets the list of tokens the contract tracks.
// 37. getProposalCount() view returns (uint256): Returns the total number of proposals created.
// 38. getGrantRequestCount() view returns (uint256): Returns the total number of grant requests submitted.

contract CreativeTreasuryHub is Ownable, Pausable {
    using SafeERC20 for IERC20;
    using Address for address;

    // --- State Variables ---
    mapping(address => bool) public admins;
    uint256 public proposalThreshold; // Number of admin approvals required
    uint256 public executionCooldown; // Time in seconds after approval before execution is allowed
    uint256 public maxProposalDuration; // Time in seconds after creation until proposal expires

    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalApprovals; // proposalId => admin => approved

    mapping(address => bool) public registeredERC20s;
    address[] private _registeredERC20List; // To allow iterating registered tokens

    uint256 public nextGrantRequestId;
    mapping(uint256 => GrantRequest) public grantRequests;

    // --- Enums ---
    enum ProposalType {
        WithdrawETH,
        WithdrawERC20,
        ExecuteCall,
        UpdateParameter,
        AddERC20,
        RemoveERC20,
        ConditionalDistributionETH,
        ConditionalDistributionERC20,
        BatchWithdrawETH,
        BatchWithdrawERC20,
        SweepDustERC20,
        ApproveGrant, // Links to a GrantRequest
        RejectGrant   // Links to a GrantRequest
    }

    enum ProposalState {
        Pending,      // Created, awaiting approvals
        Approved,     // Threshold met, awaiting cooldown
        Executed,     // Successfully executed
        Cancelled,    // Cancelled by proposer or admin
        Expired,      // Did not get enough approvals in time
        Rejected      // Specifically rejected (e.g., RejectGrant proposal executed)
    }

    enum ConditionType {
        TimeBased // Simple time-based condition: conditionValue is a timestamp
        // Add more complex conditions here (e.g., PriceFeed, ExternalEvent)
    }

    enum GrantRequestState {
        Submitted,              // User submitted the request
        ProposedForApproval,    // Admin created a proposal to approve it
        ProposedForRejection,   // Admin created a proposal to reject it
        Approved,               // Approval proposal executed
        Rejected,               // Rejection proposal executed
        Executed                // Withdrawal proposal executed (via related grant proposal)
    }

    // --- Structs ---
    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType pType;
        ProposalState state;
        uint256 creationTime;
        uint256 approvalTime; // Timestamp when threshold was met
        uint256 expiryTime;   // Timestamp when the proposal expires
        uint256 currentApprovals;
        uint256 requiredApprovals; // Snapshot of threshold at proposal creation

        bytes data; // Encoded parameters specific to the ProposalType
        string description; // Human-readable description

        // Specific fields used for convenience (can be decoded from data)
        address targetAddress; // Recipient or target contract
        uint256 amount;        // ETH or single token amount
        address tokenAddress;  // For ERC20 operations
        uint256 grantRequestId; // For ApproveGrant/RejectGrant types
    }

     struct GrantRequest {
        uint256 id;
        address requester;
        uint256 amountETH;
        address tokenAddress; // Address of ERC20 requested (address(0) for ETH only)
        uint256 amountERC20;
        GrantRequestState state;
        string purpose;
        uint256 submissionTime;
        uint256 relatedProposalId; // ID of the proposal (ApproveGrant/RejectGrant) linked to this request
    }

    // --- Events ---
    event ProposalCreated(uint256 proposalId, address indexed proposer, ProposalType pType, string description);
    event ProposalApproved(uint256 proposalId, address indexed approver, uint256 currentApprovals, uint256 requiredApprovals);
    event ProposalStateChanged(uint256 proposalId, ProposalState newState);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ProposalExpired(uint256 proposalId);

    event ParameterUpdated(string parameterName, uint256 oldValue, uint256 newValue);
    event ERC20Registered(address indexed tokenAddress);
    event ERC20Deregistered(address indexed tokenAddress);

    event GrantRequestSubmitted(uint256 requestId, address indexed requester, uint256 amountETH, address indexed tokenAddress, uint256 amountERC20, string purpose);
    event GrantRequestStateChanged(uint256 requestId, GrantRequestState newState);
    event GrantRequestCancelled(uint256 requestId);

    event AdminGranted(address indexed admin);
    event AdminRevoked(address indexed admin);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(admins[msg.sender], "CTH: Not an admin");
        _;
    }

    // Inherits whenNotPaused and whenPaused from Pausable

    // --- Constructor ---
    constructor(address initialAdmin) Ownable(msg.sender) {
        require(initialAdmin != address(0), "CTH: Initial admin cannot be zero address");
        admins[initialAdmin] = true;
        emit AdminGranted(initialAdmin);

        // Set reasonable initial parameters (can be changed via proposal)
        proposalThreshold = 1; // e.g., requires 1 admin approval initially
        executionCooldown = 0; // e.g., no cooldown initially
        maxProposalDuration = 7 * 24 * 60 * 60; // e.g., proposals expire after 7 days

        nextProposalId = 1;
        nextGrantRequestId = 1;
    }

    // --- Receive ETH ---
    receive() external payable whenNotPaused {}

    // --- Admin/Role Management ---
    function addAdmin(address _admin) external onlyOwner whenNotPaused {
        require(_admin != address(0), "CTH: Admin address cannot be zero");
        require(!admins[_admin], "CTH: Address is already an admin");
        admins[_admin] = true;
        emit AdminGranted(_admin);
    }

    function removeAdmin(address _admin) external onlyOwner whenNotPaused {
        require(admins[_admin], "CTH: Address is not an admin");
         // Prevent removing the last admin? Or allow? Allowing for flexibility.
        admins[_admin] = false;
        emit AdminRevoked(_admin);
    }

    function isAdmin(address _address) public view returns (bool) {
        return admins[_address];
    }

    // --- Pausable Functions ---
    // Inherited: pause(), unpause()
    function pause() public override onlyAdmin whenNotPaused {
        _pause();
    }

    function unpause() public override onlyAdmin whenPaused {
        _unpause();
    }

    // --- Treasury In ---
    function depositERC20(address tokenAddress, uint256 amount) external whenNotPaused {
        require(registeredERC20s[tokenAddress], "CTH: Token not registered");
        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    }

    // --- Treasury Out / Proposal Creation ---

    // Helper to create proposal
    function _createProposal(
        ProposalType pType,
        bytes memory data,
        string calldata description,
        address targetAddress, // Optional: Recipient or target contract
        uint256 amount,        // Optional: ETH or single token amount
        address tokenAddress,  // Optional: For ERC20 operations
        uint256 grantRequestId // Optional: For grant proposals
    ) internal onlyAdmin whenNotPaused returns (uint256 proposalId) {
        proposalId = nextProposalId++;
        uint256 currentTimestamp = block.timestamp;

        Proposal storage proposal = proposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.pType = pType;
        proposal.state = ProposalState.Pending;
        proposal.creationTime = currentTimestamp;
        proposal.expiryTime = currentTimestamp + maxProposalDuration;
        proposal.currentApprovals = 0;
        proposal.requiredApprovals = proposalThreshold;
        proposal.data = data;
        proposal.description = description;
        proposal.targetAddress = targetAddress;
        proposal.amount = amount;
        proposal.tokenAddress = tokenAddress;
        proposal.grantRequestId = grantRequestId;

        emit ProposalCreated(proposalId, msg.sender, pType, description);
    }

    function proposeWithdrawETH(address recipient, uint256 amount, string calldata description) external onlyAdmin returns (uint256) {
        require(recipient != address(0), "CTH: Recipient cannot be zero");
        require(amount > 0, "CTH: Amount must be greater than 0");
         // Simple check, execution will fail if balance is insufficient later
        require(address(this).balance >= amount, "CTH: Insufficient ETH balance");

        bytes memory data = abi.encode(recipient, amount);
        return _createProposal(ProposalType.WithdrawETH, data, description, recipient, amount, address(0), 0);
    }

    function proposeWithdrawERC20(address tokenAddress, address recipient, uint256 amount, string calldata description) external onlyAdmin returns (uint256) {
        require(recipient != address(0), "CTH: Recipient cannot be zero");
        require(amount > 0, "CTH: Amount must be greater than 0");
        require(registeredERC20s[tokenAddress], "CTH: Token not registered");
         // Simple check, execution will fail if balance is insufficient later
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "CTH: Insufficient ERC20 balance");

        bytes memory data = abi.encode(tokenAddress, recipient, amount);
         return _createProposal(ProposalType.WithdrawERC20, data, description, recipient, amount, tokenAddress, 0);
    }

    function proposeExecuteCall(address target, bytes calldata callData, string calldata description) external onlyAdmin returns (uint256) {
        require(target != address(0), "CTH: Target cannot be zero");
        require(callData.length > 0, "CTH: Call data must not be empty");
         // Cannot predict if call will succeed, check happens on execution

        bytes memory data = abi.encode(target, callData);
         return _createProposal(ProposalType.ExecuteCall, data, description, target, 0, address(0), 0);
    }

    function proposeUpdateParameters(uint256 newThreshold, uint256 newCooldown, uint256 newDuration, string calldata description) external onlyAdmin returns (uint256) {
        // Add sanity checks if needed, e.g., require(newDuration > executionCooldown)
        bytes memory data = abi.encode(newThreshold, newCooldown, newDuration);
        return _createProposal(ProposalType.UpdateParameter, data, description, address(0), newThreshold, address(0), 0); // Store threshold in 'amount' for visibility
    }

    function proposeAddERC20Support(address tokenAddress, string calldata description) external onlyAdmin returns (uint256) {
        require(tokenAddress != address(0), "CTH: Token address cannot be zero");
        require(!registeredERC20s[tokenAddress], "CTH: Token already registered");

        bytes memory data = abi.encode(tokenAddress);
        return _createProposal(ProposalType.AddERC20, data, description, tokenAddress, 0, tokenAddress, 0);
    }

    function proposeRemoveERC20Support(address tokenAddress, string calldata description) external onlyAdmin returns (uint256) {
        require(tokenAddress != address(0), "CTH: Token address cannot be zero");
        require(registeredERC20s[tokenAddress], "CTH: Token not registered");

        bytes memory data = abi.encode(tokenAddress);
        return _createProposal(ProposalType.RemoveERC20, data, description, tokenAddress, 0, tokenAddress, 0);
    }

     function proposeConditionalDistributionETH(address recipient, uint256 amount, ConditionType conditionType, uint256 conditionValue, string calldata description) external onlyAdmin returns (uint256) {
        require(recipient != address(0), "CTH: Recipient cannot be zero");
        require(amount > 0, "CTH: Amount must be greater than 0");
        require(conditionType == ConditionType.TimeBased, "CTH: Unsupported condition type");
        require(conditionValue > block.timestamp, "CTH: Time condition must be in the future");
        require(address(this).balance >= amount, "CTH: Insufficient ETH balance"); // Simple check

        bytes memory data = abi.encode(recipient, amount, conditionType, conditionValue);
        return _createProposal(ProposalType.ConditionalDistributionETH, data, description, recipient, amount, address(0), 0);
    }

     function proposeConditionalDistributionERC20(address tokenAddress, address recipient, uint256 amount, ConditionType conditionType, uint256 conditionValue, string calldata description) external onlyAdmin returns (uint256) {
        require(recipient != address(0), "CTH: Recipient cannot be zero");
        require(amount > 0, "CTH: Amount must be greater than 0");
         require(registeredERC20s[tokenAddress], "CTH: Token not registered");
        require(conditionType == ConditionType.TimeBased, "CTH: Unsupported condition type");
        require(conditionValue > block.timestamp, "CTH: Time condition must be in the future");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "CTH: Insufficient ERC20 balance"); // Simple check

        bytes memory data = abi.encode(tokenAddress, recipient, amount, conditionType, conditionValue);
         return _createProposal(ProposalType.ConditionalDistributionERC20, data, description, recipient, amount, tokenAddress, 0);
    }

     function proposeBatchWithdrawETH(address[] calldata recipients, uint256[] calldata amounts, string calldata description) external onlyAdmin returns (uint256) {
        require(recipients.length > 0, "CTH: Recipients list cannot be empty");
        require(recipients.length == amounts.length, "CTH: Recipients and amounts length mismatch");
        uint256 totalAmount = 0;
        for(uint i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "CTH: Recipient cannot be zero");
            require(amounts[i] > 0, "CTH: Amount must be greater than 0");
            totalAmount += amounts[i];
        }
        require(address(this).balance >= totalAmount, "CTH: Insufficient total ETH balance"); // Simple check

        bytes memory data = abi.encode(recipients, amounts);
        return _createProposal(ProposalType.BatchWithdrawETH, data, description, address(0), totalAmount, address(0), 0); // Store total in 'amount'
    }

     function proposeBatchWithdrawERC20(address tokenAddress, address[] calldata recipients, uint256[] calldata amounts, string calldata description) external onlyAdmin returns (uint256) {
        require(registeredERC20s[tokenAddress], "CTH: Token not registered");
        require(recipients.length > 0, "CTH: Recipients list cannot be empty");
        require(recipients.length == amounts.length, "CTH: Recipients and amounts length mismatch");
        uint256 totalAmount = 0;
        for(uint i = 0; i < amounts.length; i++) {
            require(recipients[i] != address(0), "CTH: Recipient cannot be zero");
            require(amounts[i] > 0, "CTH: Amount must be greater than 0");
            totalAmount += amounts[i];
        }
         require(IERC20(tokenAddress).balanceOf(address(this)) >= totalAmount, "CTH: Insufficient total ERC20 balance"); // Simple check

        bytes memory data = abi.encode(tokenAddress, recipients, amounts);
        return _createProposal(ProposalType.BatchWithdrawERC20, data, description, address(0), totalAmount, tokenAddress, 0); // Store total in 'amount'
    }

     function proposeSweepDustERC20(address recipient, address[] calldata tokensToSweep, string calldata description) external onlyAdmin returns (uint256) {
        require(recipient != address(0), "CTH: Recipient cannot be zero");
        require(tokensToSweep.length > 0, "CTH: Token list cannot be empty");
        for(uint i = 0; i < tokensToSweep.length; i++) {
            require(registeredERC20s[tokensToSweep[i]], "CTH: Token not registered");
             // Note: Cannot check balance here efficiently for multiple tokens. Check happens at execution.
        }

        bytes memory data = abi.encode(recipient, tokensToSweep);
        return _createProposal(ProposalType.SweepDustERC20, data, description, recipient, 0, address(0), 0);
    }

    function proposeGrantApproval(uint256 requestId, string calldata description) external onlyAdmin returns (uint256) {
        GrantRequest storage request = grantRequests[requestId];
        require(request.id != 0, "CTH: Grant request does not exist");
        require(request.state == GrantRequestState.Submitted, "CTH: Grant request not in submitted state");

        // Create a proposal for the actual withdrawal based on the grant request
        // The execution of THIS proposal (ApproveGrant) will create the *actual* withdrawal proposal
        bytes memory data = abi.encode(requestId);
        uint256 proposalId = _createProposal(ProposalType.ApproveGrant, data, description, request.requester, request.amountETH > 0 ? request.amountETH : request.amountERC20, request.tokenAddress, requestId);

        request.state = GrantRequestState.ProposedForApproval;
        request.relatedProposalId = proposalId;
        emit GrantRequestStateChanged(requestId, GrantRequestState.ProposedForApproval);

        return proposalId;
    }

    function proposeGrantRejection(uint256 requestId, string calldata description) external onlyAdmin returns (uint256) {
         GrantRequest storage request = grantRequests[requestId];
        require(request.id != 0, "CTH: Grant request does not exist");
        require(request.state == GrantRequestState.Submitted, "CTH: Grant request not in submitted state");

        // Create a proposal to simply mark the request as rejected
        bytes memory data = abi.encode(requestId);
        uint256 proposalId = _createProposal(ProposalType.RejectGrant, data, description, request.requester, 0, address(0), requestId);

        request.state = GrantRequestState.ProposedForRejection;
        request.relatedProposalId = proposalId;
        emit GrantRequestStateChanged(requestId, GrantRequestState.ProposedForRejection);

        return proposalId;
    }


    // --- Governance / Proposal Management & Execution ---

    function approveProposal(uint256 proposalId) external onlyAdmin whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        require(proposal.state == ProposalState.Pending, "CTH: Proposal not in pending state");
        require(block.timestamp <= proposal.expiryTime, "CTH: Proposal has expired");
        require(!proposalApprovals[proposalId][msg.sender], "CTH: Already approved");

        proposalApprovals[proposalId][msg.sender] = true;
        proposal.currentApprovals++;

        emit ProposalApproved(proposalId, msg.sender, proposal.currentApprovals, proposal.requiredApprovals);

        if (proposal.currentApprovals >= proposal.requiredApprovals) {
            proposal.state = ProposalState.Approved;
            proposal.approvalTime = block.timestamp;
            emit ProposalStateChanged(proposalId, ProposalState.Approved);
        }
    }

    function cancelProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        require(proposal.state == ProposalState.Pending, "CTH: Proposal not in pending state");
        require(msg.sender == proposal.proposer || admins[msg.sender], "CTH: Not proposer or admin");
        require(block.timestamp <= proposal.expiryTime, "CTH: Proposal has expired");

        proposal.state = ProposalState.Cancelled;
        emit ProposalStateChanged(proposalId, ProposalState.Cancelled);
        emit ProposalCancelled(proposalId);
    }

    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        require(proposal.state == ProposalState.Approved, "CTH: Proposal not approved");
        require(block.timestamp >= proposal.approvalTime + executionCooldown, "CTH: Execution cooldown not passed");
        require(block.timestamp <= proposal.expiryTime, "CTH: Proposal has expired"); // Check expiry again before execution

        // Mark as executed BEFORE the action to prevent re-entrancy issues if the call is malicious
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        bytes memory proposalData = proposal.data;

        // Execute based on ProposalType
        if (proposal.pType == ProposalType.WithdrawETH) {
            (address recipient, uint256 amount) = abi.decode(proposalData, (address, uint256));
            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "CTH: ETH withdrawal failed");

        } else if (proposal.pType == ProposalType.WithdrawERC20) {
            (address tokenAddress, address recipient, uint256 amount) = abi.decode(proposalData, (address, uint256, uint256));
             require(registeredERC20s[tokenAddress], "CTH: Token not registered for withdrawal");
            IERC20(tokenAddress).safeTransfer(recipient, amount);

        } else if (proposal.pType == ProposalType.ExecuteCall) {
            (address target, bytes memory callData) = abi.decode(proposalData, (address, bytes));
            (bool success, ) = target.call(callData);
             require(success, "CTH: Arbitrary call failed");

        } else if (proposal.pType == ProposalType.UpdateParameter) {
             (uint256 newThreshold, uint256 newCooldown, uint256 newDuration) = abi.decode(proposalData, (uint256, uint256, uint256));
             emit ParameterUpdated("proposalThreshold", proposalThreshold, newThreshold);
             proposalThreshold = newThreshold;
             emit ParameterUpdated("executionCooldown", executionCooldown, newCooldown);
             executionCooldown = newCooldown;
             emit ParameterUpdated("maxProposalDuration", maxProposalDuration, newDuration);
             maxProposalDuration = newDuration;

        } else if (proposal.pType == ProposalType.AddERC20) {
             (address tokenAddress) = abi.decode(proposalData, (address));
             require(!registeredERC20s[tokenAddress], "CTH: Token already registered"); // Double check
             registeredERC20s[tokenAddress] = true;
             _registeredERC20List.push(tokenAddress);
             emit ERC20Registered(tokenAddress);

        } else if (proposal.pType == ProposalType.RemoveERC20) {
             (address tokenAddress) = abi.decode(proposalData, (address));
             require(registeredERC20s[tokenAddress], "CTH: Token not registered"); // Double check
             registeredERC20s[tokenAddress] = false;
             // Removing from the list is tricky/costly. We'll leave it but rely on the mapping check.
             // A more gas-efficient way might involve iterating or a doubly-linked list,
             // but for simplicity, we just mark it false in the mapping.
             emit ERC20Deregistered(tokenAddress);
        } else if (proposal.pType == ProposalType.ApproveGrant) {
             // Execution of ApproveGrant creates the actual withdrawal proposal
             uint256 grantRequestId = proposal.grantRequestId;
             GrantRequest storage request = grantRequests[grantRequestId];
             require(request.id != 0 && request.state == GrantRequestState.ProposedForApproval, "CTH: Invalid grant request state for approval execution");

             request.state = GrantRequestState.Approved;
             emit GrantRequestStateChanged(grantRequestId, GrantRequestState.Approved);

             // Now, automatically create the withdrawal proposal for the approved grant
             uint256 withdrawProposalId;
             if (request.amountETH > 0 && request.amountERC20 == 0) {
                 withdrawProposalId = proposeWithdrawETH(request.requester, request.amountETH, string(abi.encodePacked("Grant Approval #", Strings.toString(grantRequestId))));
             } else if (request.amountERC20 > 0 && request.amountETH == 0) {
                 withdrawProposalId = proposeWithdrawERC20(request.tokenAddress, request.requester, request.amountERC20, string(abi.encodePacked("Grant Approval #", Strings.toString(grantRequestId))));
             } else if (request.amountETH > 0 && request.amountERC20 > 0) {
                 // Handle dual ETH/ERC20 grant - simplify by requiring separate grants or batch?
                 // For simplicity, let's say grants are ETH *or* one ERC20.
                 revert("CTH: Mixed ETH/ERC20 grants not supported by proposeGrantApproval logic");
             } else {
                  revert("CTH: Grant amount is zero");
             }

             // Note: The newly created withdrawProposalId will need separate admin approvals!
             // If auto-approval is desired, logic would need to change here.
             // Current flow requires 2 sets of approvals: ApproveGrant Proposal -> Actual Withdraw Proposal.
             // Let's auto-approve the resulting withdrawal proposal for this example,
             // simplifying the workflow after the *grant itself* is approved.
             Proposal storage withdrawProposal = proposals[withdrawProposalId];
             withdrawProposal.currentApprovals = withdrawProposal.requiredApprovals; // Auto-approve
             withdrawProposal.state = ProposalState.Approved;
             withdrawProposal.approvalTime = block.timestamp;
             emit ProposalApproved(withdrawProposalId, address(this), withdrawProposal.currentApprovals, withdrawProposal.requiredApprovals); // Signal auto-approval
             emit ProposalStateChanged(withdrawProposalId, ProposalState.Approved);

             // Link the withdraw proposal back to the grant request for tracking
             request.relatedProposalId = withdrawProposalId; // Update to the new withdrawal proposal ID


        } else if (proposal.pType == ProposalType.RejectGrant) {
            uint256 grantRequestId = proposal.grantRequestId;
            GrantRequest storage request = grantRequests[grantRequestId];
            require(request.id != 0 && request.state == GrantRequestState.ProposedForRejection, "CTH: Invalid grant request state for rejection execution");

            request.state = GrantRequestState.Rejected;
            emit GrantRequestStateChanged(grantRequestId, GrantRequestState.Rejected);

        } else {
            // These types require dedicated execution functions due to complexity (conditional checks, loops)
            revert("CTH: Use specific execute function for this proposal type");
        }


        emit ProposalExecuted(proposalId);
    }

    // Dedicated execute function for Conditional Distributions
     function executeConditionalDistribution(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        require(proposal.pType == ProposalType.ConditionalDistributionETH || proposal.pType == ProposalType.ConditionalDistributionERC20, "CTH: Not a conditional distribution proposal");
        require(proposal.state == ProposalState.Approved, "CTH: Proposal not approved");
        // No executionCooldown for conditional, as the condition acts as the trigger
        // require(block.timestamp >= proposal.approvalTime + executionCooldown, "CTH: Execution cooldown not passed");
        require(block.timestamp <= proposal.expiryTime, "CTH: Proposal has expired"); // Conditional proposals can also expire

        bytes memory proposalData = proposal.data;
        ConditionType conditionType;
        uint256 conditionValue;

        if (proposal.pType == ProposalType.ConditionalDistributionETH) {
            (address recipient, uint256 amount, ConditionType cType, uint256 cValue) = abi.decode(proposalData, (address, uint256, ConditionType, uint256));
            conditionType = cType;
            conditionValue = cValue;
             require(address(this).balance >= amount, "CTH: Insufficient ETH balance for conditional distribution");

            // Check Condition
            require(conditionType == ConditionType.TimeBased && block.timestamp >= conditionValue, "CTH: Condition not met");

            // Mark executed BEFORE transfer
             proposal.state = ProposalState.Executed;
            emit ProposalStateChanged(proposalId, ProposalState.Executed);

            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "CTH: Conditional ETH transfer failed");


        } else if (proposal.pType == ProposalType.ConditionalDistributionERC20) {
             (address tokenAddress, address recipient, uint256 amount, ConditionType cType, uint256 cValue) = abi.decode(proposalData, (address, uint256, uint256, ConditionType, uint256));
             conditionType = cType;
             conditionValue = cValue;
             require(registeredERC20s[tokenAddress], "CTH: Token not registered for conditional distribution");
             require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "CTH: Insufficient ERC20 balance for conditional distribution");

            // Check Condition
             require(conditionType == ConditionType.TimeBased && block.timestamp >= conditionValue, "CTH: Condition not met");

             // Mark executed BEFORE transfer
             proposal.state = ProposalState.Executed;
             emit ProposalStateChanged(proposalId, ProposalState.Executed);

            IERC20(tokenAddress).safeTransfer(recipient, amount);
        }

        emit ProposalExecuted(proposalId);
    }

    // Dedicated execute function for Batch Withdrawals
     function executeBatchWithdrawal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        require(proposal.pType == ProposalType.BatchWithdrawETH || proposal.pType == ProposalType.BatchWithdrawERC20, "CTH: Not a batch withdrawal proposal");
        require(proposal.state == ProposalState.Approved, "CTH: Proposal not approved");
        require(block.timestamp >= proposal.approvalTime + executionCooldown, "CTH: Execution cooldown not passed");
        require(block.timestamp <= proposal.expiryTime, "CTH: Proposal has expired");

        bytes memory proposalData = proposal.data;

        // Mark executed BEFORE transfers
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        if (proposal.pType == ProposalType.BatchWithdrawETH) {
            (address[] memory recipients, uint256[] memory amounts) = abi.decode(proposalData, (address[], uint256[]));
             require(recipients.length == amounts.length, "CTH: Data length mismatch in batch ETH");
             for (uint i = 0; i < recipients.length; i++) {
                 if (amounts[i] > 0) { // Skip 0 amounts
                    // Use call for security, ignore result if any fail (can be designed differently)
                    (bool success, ) = payable(recipients[i]).call{value: amounts[i]}("");
                    // Consider if failure of one should revert all (more complex)
                    // For simplicity here, we let subsequent transfers proceed.
                    if (!success) {
                         // Log failure? Revert? Reverting is safer for treasury.
                         // Revert if ANY transfer fails in the batch
                         revert("CTH: Batch ETH transfer failed");
                    }
                 }
             }

        } else if (proposal.pType == ProposalType.BatchWithdrawERC20) {
             (address tokenAddress, address[] memory recipients, uint256[] memory amounts) = abi.decode(proposalData, (address, address[], uint256[]));
             require(registeredERC20s[tokenAddress], "CTH: Token not registered for batch withdrawal");
             require(recipients.length == amounts.length, "CTH: Data length mismatch in batch ERC20");
             IERC20 token = IERC20(tokenAddress);
             for (uint i = 0; i < recipients.length; i++) {
                 if (amounts[i] > 0) { // Skip 0 amounts
                    token.safeTransfer(recipients[i], amounts[i]);
                 }
             }
        }

        emit ProposalExecuted(proposalId);
     }

    // Dedicated execute function for Sweeping Dust
    function executeSweepDustERC20(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        require(proposal.pType == ProposalType.SweepDustERC20, "CTH: Not a dust sweeping proposal");
        require(proposal.state == ProposalState.Approved, "CTH: Proposal not approved");
        require(block.timestamp >= proposal.approvalTime + executionCooldown, "CTH: Execution cooldown not passed");
        require(block.timestamp <= proposal.expiryTime, "CTH: Proposal has expired");

        bytes memory proposalData = proposal.data;
        (address recipient, address[] memory tokensToSweep) = abi.decode(proposalData, (address, address[]));
        require(recipient != address(0), "CTH: Recipient cannot be zero for dust sweep");
        require(tokensToSweep.length > 0, "CTH: Token list cannot be empty for dust sweep");

        // Mark executed BEFORE transfers
        proposal.state = ProposalState.Executed;
        emit ProposalStateChanged(proposalId, ProposalState.Executed);

        for(uint i = 0; i < tokensToSweep.length; i++) {
             address tokenAddress = tokensToSweep[i];
             require(registeredERC20s[tokenAddress], "CTH: Token not registered for dust sweep"); // Double check

            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));

            // Define "dust" threshold. Here, any non-zero balance is considered dust to sweep.
            // A more complex definition could be added (e.g., < 100 wei).
            if (balance > 0) {
                token.safeTransfer(recipient, balance);
                 // Note: This sweeps *all* of the token's balance, not just dust below a threshold.
                 // Adjust `if (balance > 0)` and the transfer amount if a specific dust threshold is needed.
            }
        }

         emit ProposalExecuted(proposalId);
    }


    // Dedicated execute function for Grant Actions (Approval/Rejection)
     function executeGrantAction(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        require(proposal.pType == ProposalType.ApproveGrant || proposal.pType == ProposalType.RejectGrant, "CTH: Not a grant action proposal");
        require(proposal.state == ProposalState.Approved, "CTH: Proposal not approved");
        require(block.timestamp >= proposal.approvalTime + executionCooldown, "CTH: Execution cooldown not passed");
        require(block.timestamp <= proposal.expiryTime, "CTH: Proposal has expired");

         // Mark executed BEFORE updating grant state
         proposal.state = ProposalState.Executed;
         emit ProposalStateChanged(proposalId, ProposalState.Executed);
         emit ProposalExecuted(proposalId);

        uint256 grantRequestId = proposal.grantRequestId;
        GrantRequest storage request = grantRequests[grantRequestId];
        require(request.id != 0, "CTH: Grant request does not exist for this proposal");

        if (proposal.pType == ProposalType.ApproveGrant) {
            // This execution step was already handled within executeProposal(ApproveGrant)
            // where it transitioned the GrantRequest to Approved and created/auto-approved the withdrawal proposal.
            // This separate function is just to have a dedicated entry point if needed, but the logic is tied.
             revert("CTH: ApproveGrant executed via standard executeProposal. Use that function.");

        } else if (proposal.pType == ProposalType.RejectGrant) {
            require(request.state == GrantRequestState.ProposedForRejection, "CTH: Grant request not in proposed rejection state");
            request.state = GrantRequestState.Rejected;
            emit GrantRequestStateChanged(grantRequestId, GrantRequestState.Rejected);
        }
     }


    // --- Grant Request System ---

    function submitGrantRequest(uint256 amountETH, address tokenAddress, uint256 amountERC20, string calldata purpose) external whenNotPaused returns (uint256 requestId) {
        // Allow requesting ETH *or* one ERC20, but not both simultaneously for simplicity
        require((amountETH > 0 && amountERC20 == 0 && tokenAddress == address(0)) || (amountERC20 > 0 && amountETH == 0 && tokenAddress != address(0) && registeredERC20s[tokenAddress]), "CTH: Request either ETH or a registered ERC20");
        require(bytes(purpose).length > 0, "CTH: Purpose cannot be empty");

        requestId = nextGrantRequestId++;
        GrantRequest storage request = grantRequests[requestId];
        request.id = requestId;
        request.requester = msg.sender;
        request.amountETH = amountETH;
        request.tokenAddress = tokenAddress;
        request.amountERC20 = amountERC20;
        request.state = GrantRequestState.Submitted;
        request.purpose = purpose;
        request.submissionTime = block.timestamp;
        request.relatedProposalId = 0; // No proposal linked yet

        emit GrantRequestSubmitted(requestId, msg.sender, amountETH, tokenAddress, amountERC20, purpose);
    }

    function cancelGrantRequest(uint256 requestId) external whenNotPaused {
        GrantRequest storage request = grantRequests[requestId];
        require(request.id != 0, "CTH: Grant request does not exist");
        require(request.requester == msg.sender, "CTH: Not the requester");
        require(request.state == GrantRequestState.Submitted, "CTH: Request not in submitted state");

        // Mark request as cancelled
        request.state = GrantRequestState.Rejected; // Using Rejected state to signify it's no longer valid/actionable
        emit GrantRequestStateChanged(requestId, GrantRequestState.Rejected);
        emit GrantRequestCancelled(requestId);
    }


    // --- Views ---

    function getETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getERC20Balance(address tokenAddress) public view returns (uint256) {
        require(registeredERC20s[tokenAddress], "CTH: Token not registered");
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getProposalDetails(uint256 proposalId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            ProposalType pType,
            ProposalState state,
            uint256 creationTime,
            uint256 approvalTime,
            uint256 expiryTime,
            uint256 currentApprovals,
            uint256 requiredApprovals,
            bytes memory data,
            string memory description
        )
    {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        return (
            proposal.id,
            proposal.proposer,
            proposal.pType,
            proposal.state,
            proposal.creationTime,
            proposal.approvalTime,
            proposal.expiryTime,
            proposal.currentApprovals,
            proposal.requiredApprovals,
            proposal.data,
            proposal.description
        );
    }

    function getProposalApprovalStatus(uint256 proposalId) public view returns (uint256 currentApprovals, uint256 requiredApprovals) {
         Proposal storage proposal = proposals[proposalId];
        require(proposal.id != 0, "CTH: Proposal does not exist");
        return (proposal.currentApprovals, proposal.requiredApprovals);
    }


    function getGrantRequestDetails(uint256 requestId)
        public
        view
        returns (
            uint256 id,
            address requester,
            uint256 amountETH,
            address tokenAddress,
            uint256 amountERC20,
            GrantRequestState state,
            string memory purpose,
            uint256 submissionTime,
            uint256 relatedProposalId
        )
    {
        GrantRequest storage request = grantRequests[requestId];
        require(request.id != 0, "CTH: Grant request does not exist");
         return (
             request.id,
             request.requester,
             request.amountETH,
             request.tokenAddress,
             request.amountERC20,
             request.state,
             request.purpose,
             request.submissionTime,
             request.relatedProposalId
         );
    }

     function getRegisteredERC20s() public view returns (address[] memory) {
         // Iterate through the mapping to build the list of *currently* registered tokens
         // The _registeredERC20List is not reliable after removals
         address[] memory activeList;
         uint256 count = 0;
         for(uint i = 0; i < _registeredERC20List.length; i++) {
             if (registeredERC20s[_registeredERC20List[i]]) {
                 count++;
             }
         }
         activeList = new address[](count);
         uint256 index = 0;
          for(uint i = 0; i < _registeredERC20List.length; i++) {
             if (registeredERC20s[_registeredERC20List[i]]) {
                 activeList[index] = _registeredERC20List[i];
                 index++;
             }
         }
         return activeList;
     }

     function getProposalCount() public view returns (uint256) {
         return nextProposalId - 1;
     }

     function getGrantRequestCount() public view returns (uint256) {
         return nextGrantRequestId - 1;
     }

}
```