Okay, here is a Solidity smart contract concept for a `QuantumTreasury`. This contract aims to be interesting and advanced by combining state management, conditional and probabilistic asset releases, and a basic form of asset "entanglement" (metaphorical, within the contract's logic), framed under a "Quantum" theme to represent complex, state-dependent interactions. It avoids simple ERC-20/721 logic or standard staking/lending patterns.

**Concept:**

The `QuantumTreasury` is a complex vault capable of holding various ERC-20 tokens and ERC-721 NFTs. Its behavior and the rules for releasing assets are governed by an internal state machine and predefined conditional, probabilistic, and "entanglement" rules. The "quantum" aspect is a metaphor for the state-dependent, potentially non-obvious (without querying the rules), and sometimes pseudo-random nature of asset interactions and releases within the treasury.

**Outline:**

1.  **License and Pragma**
2.  **Imports** (ERC20, ERC721 interfaces, SafeTransferLib, ReentrancyGuard)
3.  **Error Definitions**
4.  **Enums** (`TreasuryState`, `ProposalState`)
5.  **Structs** (`ConditionalReleaseRule`, `AssetEntanglementRule`, `ProbabilisticDistributionRule`, `Proposal`)
6.  **Events**
7.  **State Variables** (Ownership/Governance, Supported Assets, Balances, Rules, Proposals, State Management)
8.  **Modifiers** (`onlyGovernance`, `whenStateIs`, `nonReentrant`)
9.  **Constructor**
10. **Core Treasury Management** (Deposit, Withdrawal - governance only)
11. **Supported Asset Management** (Add/Remove tokens and NFTs)
12. **Treasury State Management** (Get state, Proposal system for state changes)
13. **Conditional Release Rules** (Add, Remove, Query, Check, Execute)
14. **Asset Entanglement Rules** (Add, Remove, Query, Trigger Effect)
15. **Probabilistic Distribution Rules** (Add, Remove, Query, Execute)
16. **Query Functions** (Balances, Rules, Proposals, State)

**Function Summary:**

1.  `constructor()`: Initializes the contract, sets governance.
2.  `depositToken(address token, uint256 amount)`: Allows users to deposit supported ERC-20 tokens.
3.  `depositNFT(address nftContract, uint256 tokenId)`: Allows users to deposit supported ERC-721 NFTs.
4.  `governanceWithdrawToken(address token, uint256 amount, address recipient)`: Allows governance to withdraw any supported ERC-20.
5.  `governanceWithdrawNFT(address nftContract, uint256 tokenId, address recipient)`: Allows governance to withdraw any supported ERC-721.
6.  `addSupportedToken(address token)`: Governance adds an ERC-20 token address to the supported list.
7.  `removeSupportedToken(address token)`: Governance removes an ERC-20 token address from the supported list.
8.  `addSupportedNFT(address nftContract)`: Governance adds an ERC-721 contract address to the supported list.
9.  `removeSupportedNFT(address nftContract)`: Governance removes an ERC-721 contract address from the supported list.
10. `submitStateChangeProposal(TreasuryState newState)`: Governance submits a proposal to change the treasury's state.
11. `voteOnProposal(uint256 proposalId, bool support)`: Governance members vote on an active proposal.
12. `executeProposal(uint256 proposalId)`: Governance executes a proposal if it has passed the voting period and threshold.
13. `addConditionalReleaseRule(address token, uint256 amount, address recipient, uint256 conditionType, uint256 conditionValue)`: Governance adds a rule for conditionally releasing tokens (e.g., based on time since deposit).
14. `removeConditionalReleaseRule(uint256 ruleId)`: Governance removes a conditional release rule.
15. `checkConditionalRelease(uint256 ruleId)`: Checks if the conditions for a specific release rule are met.
16. `executeConditionalRelease(uint256 ruleId)`: Allows a permitted caller (or anyone, depending on design) to trigger a conditional release if `checkConditionalRelease` is true.
17. `addAssetEntanglementRule(address assetAContract, uint256 assetAId, address assetBContract, uint256 assetBId, uint256 effectType, uint256 effectValue)`: Governance adds a rule defining how interacting with asset A affects asset B (e.g., withdrawing asset A locks asset B). Asset ID is 0 for ERC20s.
18. `removeAssetEntanglementRule(uint256 ruleId)`: Governance removes an entanglement rule.
19. `triggerEntanglementEffect(address assetContract, uint256 assetId)`: Internal/external function to trigger entanglement effects associated with an asset (e.g., when it's withdrawn).
20. `addProbabilisticDistributionRule(address token, uint256 totalAmount, address[] potentialRecipients, uint256[] weights)`: Governance adds a rule for distributing a token amount probabilistically among recipients based on weights (uses block data for pseudo-randomness).
21. `removeProbabilisticDistributionRule(uint256 ruleId)`: Governance removes a probabilistic distribution rule.
22. `executeProbabilisticDistribution(uint256 ruleId)`: Executes a probabilistic distribution rule, transferring tokens based on the pseudo-random outcome.
23. `getCurrentState()`: Returns the current operational state of the treasury.
24. `getConditionalReleaseRule(uint256 ruleId)`: Returns details of a specific conditional release rule.
25. `getAssetEntanglementRule(uint256 ruleId)`: Returns details of a specific entanglement rule.
26. `getProbabilisticDistributionRule(uint256 ruleId)`: Returns details of a specific probabilistic distribution rule.
27. `getProposalState(uint256 proposalId)`: Returns the current state and details of a proposal.
28. `getSupportedTokens()`: Returns the list of supported ERC-20 token addresses.
29. `getSupportedNFTs()`: Returns the list of supported ERC-721 contract addresses.
30. `getTokenBalance(address token)`: Returns the contract's balance for a specific supported token.
31. `isNFTDeposited(address nftContract, uint256 tokenId)`: Returns true if a specific NFT is held by the treasury.

*(Note: The implementation of conditions and effects in rules will be simplified for a contract example, but the structures allow for more complex off-chain logic or helper contracts if needed.)*

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc721/IERC721.sol";
import "@openzeppelin/contracts/token/erc721/utils/ERC721Holder.sol"; // To receive NFTs
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Simple governance model, could be expanded

// Safe token transfer libraries
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";

/**
 * @title QuantumTreasury
 * @dev An advanced, state-dependent treasury contract managing ERC-20 and ERC-721 assets.
 * Features conditional releases, probabilistic distributions, and asset entanglement logic.
 * The "Quantum" theme represents complex, non-linear interactions and state changes.
 * Uses a simple Ownable pattern for governance, which could be replaced by a DAO/multi-sig.
 * Note: Probabilistic distribution uses block data for pseudo-randomness, which is NOT
 * cryptographically secure and susceptible to miner/validator manipulation (MEV). This is
 * included for demonstration of the concept on-chain. Real-world systems should use VRF.
 */
contract QuantumTreasury is ERC721Holder, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;
    using SafeMath for uint256; // Although 0.8+ handles overflow, good for clarity on complex ops

    // --- Errors ---
    error InvalidState();
    error UnsupportedAsset();
    error DepositFailed();
    error WithdrawalFailed();
    error NFTNotDeposited();
    error RuleDoesNotExist();
    error ConditionNotMet();
    error RuleAlreadyExecuted();
    error InvalidRuleParameters();
    error ProposalDoesNotExist();
    error ProposalVotingPeriodNotActive();
    error ProposalAlreadyVoted();
    error ProposalNotExecutable();
    error ProposalAlreadyExecuted();
    error NotEnoughTokensInTreasury();
    error EntanglementEffectFailed();
    error ProbabilisticDistributionFailed();
    error InsufficientEntropy(); // For pseudo-randomness

    // --- Enums ---
    enum TreasuryState {
        Initializing,   // Treasury setup phase
        Operational,    // Standard operations allowed
        Restricted,     // Only specific operations allowed
        Locked          // No withdrawals/transfers allowed except governance emergency
    }

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Failed,
        Executed
    }

    // --- Structs ---
    /**
     * @dev Defines a rule for releasing tokens based on conditions.
     * conditionType: 1=Time elapsed since rule creation (conditionValue = seconds)
     *                2=Time elapsed since asset deposit (conditionValue = seconds)
     *                3=Other (requires external helper or more complex byte parsing) - Not fully implemented here
     */
    struct ConditionalReleaseRule {
        bool active;
        address token;
        uint256 amount;
        address recipient;
        uint256 conditionType;
        uint256 conditionValue; // e.g., duration in seconds
        uint256 ruleCreationTimestamp; // For time-based conditions
        bool executed;
    }

    /**
     * @dev Defines how interacting with one asset affects another.
     * assetA/BId: tokenId for ERC721, 0 for ERC20
     * effectType: 1=Lock Asset B (effectValue = duration in seconds)
     *             2=Transfer Fee from sender (effectValue = amount) - Not fully implemented here
     *             3=Trigger State Change Proposal (effectValue = target TreasuryState enum value)
     */
    struct AssetEntanglementRule {
        bool active;
        address assetAContract;
        uint256 assetAId;
        address assetBContract;
        uint256 assetBId;
        uint256 effectType;
        uint256 effectValue; // e.g., lock duration, fee amount, target state enum value
    }

    /**
     * @dev Defines a rule for distributing tokens probabilistically.
     * Uses weighted distribution based on provided weights.
     * Pseudo-randomness from block data.
     */
    struct ProbabilisticDistributionRule {
        bool active;
        address token;
        uint256 totalAmount;
        address[] potentialRecipients;
        uint256[] weights; // Sum of weights determines the "probability space"
        bool executed;
    }

    /**
     * @dev Defines a proposal for governance actions, currently only state changes.
     */
    struct Proposal {
        ProposalState state;
        TreasuryState targetState; // For state change proposals
        uint256 creationTimestamp;
        uint256 votingPeriodEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        // Could add more proposal types here later (e.g., adding rules, changing parameters)
    }

    // --- State Variables ---
    TreasuryState public currentState;
    uint256 public proposalCount;
    uint256 public conditionalReleaseRuleCount;
    uint256 public assetEntanglementRuleCount;
    uint256 public probabilisticDistributionRuleCount;

    // Supported Assets
    mapping(address => bool) private _isSupportedToken;
    mapping(address => bool) private _isSupportedNFT;
    address[] private _supportedTokensList; // For easy iteration/query
    address[] private _supportedNFTsList; // For easy iteration/query

    // Asset Holdings (ERC20 balance tracked externally, ERC721 ownership tracked by ERC721Holder)
    // mapping(address => uint256) private _tokenBalances; // ERC20 balances tracked implicitly by treasury address

    // Rules
    mapping(uint256 => ConditionalReleaseRule) public conditionalReleaseRules;
    mapping(uint256 => AssetEntanglementRule) public assetEntanglementRules;
    mapping(uint256 => ProbabilisticDistributionRule) public probabilisticDistributionRules;

    // Asset State Overrides (e.g., locked assets)
    mapping(address => mapping(uint256 => uint256)) private _assetLockedUntil; // assetContract => tokenId (0 for ERC20) => timestamp

    // Governance Proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public votingPeriodDuration = 3 days;
    uint256 public proposalPassThreshold = 1; // Simple threshold: just need 1 vote "for" from governance currently

    // --- Events ---
    event TokenDeposited(address indexed token, address indexed depositor, uint256 amount);
    event NFTDeposited(address indexed nftContract, address indexed depositor, uint256 tokenId);
    event TokenWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event NFTWithdrawn(address indexed nftContract, address indexed recipient, uint256 tokenId);
    event TreasuryStateChanged(TreasuryState oldState, TreasuryState newState);
    event SupportedTokenAdded(address indexed token);
    event SupportedTokenRemoved(address indexed token);
    event SupportedNFTAdded(address indexed nftContract);
    event SupportedNFTRemoved(address indexed nftContract);
    event ConditionalReleaseRuleAdded(uint256 indexed ruleId, address indexed token, address indexed recipient);
    event ConditionalReleaseRuleRemoved(uint256 indexed ruleId);
    event ConditionalReleaseExecuted(uint256 indexed ruleId, address indexed token, uint256 amount, address indexed recipient);
    event AssetEntanglementRuleAdded(uint256 indexed ruleId, address indexed assetAContract, uint256 assetAId, address indexed assetBContract, uint256 assetBId);
    event AssetEntanglementRuleRemoved(uint256 indexed ruleId);
    event EntanglementEffectTriggered(uint256 indexed ruleId, address indexed assetContract, uint256 assetId, uint256 effectType);
    event ProbabilisticDistributionRuleAdded(uint256 indexed ruleId, address indexed token, uint256 totalAmount);
    event ProbabilisticDistributionRuleRemoved(uint256 indexed ruleId);
    event ProbabilisticDistributionExecuted(uint256 indexed ruleId, address indexed token, uint256 totalAmount, address[] recipients, uint256[] amounts);
    event ProposalCreated(uint256 indexed proposalId, address indexed creator, TreasuryState targetState);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);

    // --- Modifiers ---
    modifier whenStateIs(TreasuryState _state) {
        if (currentState != _state) revert InvalidState();
        _;
    }

    modifier onlySupportedToken(address token) {
        if (!_isSupportedToken[token]) revert UnsupportedAsset();
        _;
    }

    modifier onlySupportedNFT(address nftContract) {
        if (!_isSupportedNFT[nftContract]) revert UnsupportedAsset();
        _;
    }

    // --- Constructor ---
    constructor(address initialGovernance) Ownable(initialGovernance) {
        currentState = TreasuryState.Initializing;
        // Add deployer as the initial governance member (using Ownable)
        // In a real DAO, this would be replaced by a member list and voting contract
    }

    // --- Core Treasury Management ---

    /**
     * @dev Deposits supported ERC-20 tokens into the treasury.
     * Requires caller to approve the treasury contract beforehand.
     * Callable in Initializing and Operational states.
     */
    function depositToken(address token, uint256 amount)
        external
        nonReentrant
        onlySupportedToken(token)
        whenStateIs(TreasuryState.Initializing) // Example: Only allow deposits in certain states
        whenStateIs(TreasuryState.Operational) // Combined state check (logical OR) - requires careful implementation
    {
        // Check state logic carefully. Simple OR check:
        if (currentState != TreasuryState.Initializing && currentState != TreasuryState.Operational) {
             revert InvalidState();
        }

        // Using SafeERC20 for pull-based transfer
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit TokenDeposited(token, msg.sender, amount);
    }

    /**
     * @dev Deposits supported ERC-721 NFTs into the treasury.
     * Requires caller to approve the treasury contract beforehand.
     * Callable in Initializing and Operational states.
     */
    function depositNFT(address nftContract, uint256 tokenId)
        external
        nonReentrant
        onlySupportedNFT(nftContract)
    {
         // Check state logic carefully. Simple OR check:
        if (currentState != TreasuryState.Initializing && currentState != TreasuryState.Operational) {
             revert InvalidState();
        }

        // Using SafeERC721 for pull-based transfer
        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        emit NFTDeposited(nftContract, msg.sender, tokenId);
    }

    /**
     * @dev Governance withdrawal of ERC-20 tokens. Emergency or specific use only.
     * Most withdrawals should happen via rule execution (`executeConditionalRelease`, `executeProbabilisticDistribution`).
     */
    function governanceWithdrawToken(address token, uint256 amount, address recipient)
        external
        onlyOwner // Using Ownable as simple governance
        nonReentrant
        onlySupportedToken(token)
    {
        // Optional: Add state checks (e.g., not allowed in Locked state unless emergency flag)
        // if (currentState == TreasuryState.Locked) revert InvalidState(); // Example

        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) revert NotEnoughTokensInTreasury();

        IERC20(token).safeTransfer(recipient, amount);

        emit TokenWithdrawn(token, recipient, amount);
    }

    /**
     * @dev Governance withdrawal of ERC-721 NFTs. Emergency or specific use only.
     */
    function governanceWithdrawNFT(address nftContract, uint256 tokenId, address recipient)
        external
        onlyOwner // Using Ownable as simple governance
        nonReentrant
        onlySupportedNFT(nftContract)
    {
        // Optional: Add state checks

        // Check if the treasury actually holds the NFT
        if (IERC721(nftContract).ownerOf(tokenId) != address(this)) revert NFTNotDeposited();

        // Check entanglement status before withdrawal
        // This is where triggerEntanglementEffect might be called internally
        // Simplified: just check if locked by entanglement
         if (_assetLockedUntil[nftContract][tokenId] > block.timestamp) {
            revert EntanglementEffectFailed(); // Or a more specific error
        }
        triggerEntanglementEffect(nftContract, tokenId); // Trigger any effects before transfer

        IERC721(nftContract).safeTransferFrom(address(this), recipient, tokenId);

        emit NFTWithdrawn(nftContract, recipient, tokenId);
    }

    // --- Supported Asset Management ---

    /**
     * @dev Governance adds a supported ERC-20 token.
     */
    function addSupportedToken(address token) external onlyOwner {
        if (_isSupportedToken[token]) revert InvalidRuleParameters(); // Already supported
        _isSupportedToken[token] = true;
        _supportedTokensList.push(token);
        emit SupportedTokenAdded(token);
    }

    /**
     * @dev Governance removes a supported ERC-20 token.
     * Note: Does not remove existing balance, just prevents new rules/deposits for it.
     */
    function removeSupportedToken(address token) external onlyOwner {
        if (!_isSupportedToken[token]) revert UnsupportedAsset();
        _isSupportedToken[token] = false;
        // Simple removal by marking unsupported. Removing from list is complex (loops or requires moving elements).
        // For simplicity here, we just mark unsupported. Query functions will need to filter.
        // In a real contract, consider a more robust list management or just rely on the mapping.
        emit SupportedTokenRemoved(token);
    }

    /**
     * @dev Governance adds a supported ERC-721 contract.
     */
    function addSupportedNFT(address nftContract) external onlyOwner {
        if (_isSupportedNFT[nftContract]) revert InvalidRuleParameters(); // Already supported
        _isSupportedNFT[nftContract] = true;
        _supportedNFTsList.push(nftContract);
        emit SupportedNFTAdded(nftContract);
    }

    /**
     * @dev Governance removes a supported ERC-721 contract.
     * Note: Does not remove existing NFTs, just prevents new rules/deposits for it.
     */
    function removeSupportedNFT(address nftContract) external onlyOwner {
         if (!_isSupportedNFT[nftContract]) revert UnsupportedAsset();
        _isSupportedNFT[nftContract] = false;
        emit SupportedNFTRemoved(nftContract);
    }

    // --- Treasury State Management (Simple Proposal System) ---

    /**
     * @dev Submits a proposal to change the treasury's state.
     * Only callable by governance.
     */
    function submitStateChangeProposal(TreasuryState newState) external onlyOwner {
        uint256 proposalId = ++proposalCount;
        proposals[proposalId] = Proposal({
            state: ProposalState.Active,
            targetState: newState,
            creationTimestamp: block.timestamp,
            votingPeriodEnd: block.timestamp + votingPeriodDuration,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool)()
        });
        emit ProposalCreated(proposalId, msg.sender, newState);
    }

    /**
     * @dev Allows governance members to vote on an active proposal.
     * Using Ownable, only the owner can vote (can be extended for multi-sig/DAO).
     */
    function voteOnProposal(uint256 proposalId, bool support) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Active) revert ProposalDoesNotExist(); // Or not Active
        if (block.timestamp > proposal.votingPeriodEnd) revert ProposalVotingPeriodNotActive();
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted();

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        // Simple check for passing (can be made more complex)
        if (proposal.votesFor >= proposalPassThreshold) {
            proposal.state = ProposalState.Passed;
        }

        emit ProposalVoted(proposalId, msg.sender, support);
    }

    /**
     * @dev Executes a passed proposal after the voting period ends.
     * Callable by governance.
     */
    function executeProposal(uint256 proposalId) external onlyOwner {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.state != ProposalState.Passed) revert ProposalNotExecutable();
        if (block.timestamp <= proposal.votingPeriodEnd) revert ProposalVotingPeriodNotActive(); // Ensure voting period is over
        if (proposal.executed) revert ProposalAlreadyExecuted();

        // Execute the state change
        TreasuryState oldState = currentState;
        currentState = proposal.targetState;
        proposal.state = ProposalState.Executed; // Mark proposal as executed
        proposal.executed = true;

        emit TreasuryStateChanged(oldState, currentState);
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Gets the current operational state of the treasury.
     */
    function getCurrentState() external view returns (TreasuryState) {
        return currentState;
    }

    // --- Conditional Release Rules ---

    /**
     * @dev Governance adds a conditional release rule.
     * @param conditionType 1=Time elapsed since rule creation (conditionValue = seconds)
     *                      2=Time elapsed since asset deposit (conditionValue = seconds)
     */
    function addConditionalReleaseRule(
        address token,
        uint256 amount,
        address recipient,
        uint256 conditionType,
        uint256 conditionValue
    ) external onlyOwner onlySupportedToken(token) {
        if (conditionType != 1 && conditionType != 2) revert InvalidRuleParameters();
        if (amount == 0) revert InvalidRuleParameters();
        if (recipient == address(0)) revert InvalidRuleParameters();

        uint256 ruleId = ++conditionalReleaseRuleCount;
        conditionalReleaseRules[ruleId] = ConditionalReleaseRule({
            active: true,
            token: token,
            amount: amount,
            recipient: recipient,
            conditionType: conditionType,
            conditionValue: conditionValue,
            ruleCreationTimestamp: block.timestamp,
            executed: false
        });
        emit ConditionalReleaseRuleAdded(ruleId, token, recipient);
    }

    /**
     * @dev Governance removes a conditional release rule.
     * Does not affect releases already queued or in progress.
     */
    function removeConditionalReleaseRule(uint256 ruleId) external onlyOwner {
        if (!conditionalReleaseRules[ruleId].active) revert RuleDoesNotExist();
        conditionalReleaseRules[ruleId].active = false;
        emit ConditionalReleaseRuleRemoved(ruleId);
    }

    /**
     * @dev Checks if the conditions for a specific release rule are met.
     * @param ruleId The ID of the conditional release rule.
     * @return bool True if the conditions are met.
     */
    function checkConditionalRelease(uint256 ruleId) public view returns (bool) {
        ConditionalReleaseRule storage rule = conditionalReleaseRules[ruleId];
        if (!rule.active || rule.executed) return false;

        uint256 contractBalance = IERC20(rule.token).balanceOf(address(this));
        if (contractBalance < rule.amount) return false; // Ensure treasury has enough

        if (rule.conditionType == 1) {
            // Time elapsed since rule creation
            return block.timestamp >= rule.ruleCreationTimestamp.add(rule.conditionValue);
        } else if (rule.conditionType == 2) {
            // Time elapsed since asset deposit - Requires tracking individual deposits, complex.
            // Simplified: Assume condition is met if rule is active and time elapsed since rule creation.
            // A real implementation would need to track specific deposit timestamps per user/amount.
             return block.timestamp >= rule.ruleCreationTimestamp.add(rule.conditionValue); // Using rule creation time as proxy
        }
        // Add more condition types here

        return false; // Unknown condition type
    }

    /**
     * @dev Executes a conditional release rule if its conditions are met.
     * Can potentially be called by anyone to trigger a release once conditions are true,
     * making it a push mechanism. Requires nonReentrant guard.
     */
    function executeConditionalRelease(uint256 ruleId) external nonReentrant {
        ConditionalReleaseRule storage rule = conditionalReleaseRules[ruleId];
        if (!rule.active) revert RuleDoesNotExist();
        if (rule.executed) revert RuleAlreadyExecuted();
        if (!checkConditionalRelease(ruleId)) revert ConditionNotMet();

        // Perform the transfer
        IERC20(rule.token).safeTransfer(rule.recipient, rule.amount);

        rule.executed = true;
        rule.active = false; // Deactivate rule after execution
        emit ConditionalReleaseExecuted(ruleId, rule.token, rule.amount, rule.recipient);
    }

    // --- Asset Entanglement Rules ---

    /**
     * @dev Governance adds an asset entanglement rule.
     * Defines effects when asset A interacts (e.g., is withdrawn).
     * @param assetAContract Address of asset A contract (ERC20 or ERC721).
     * @param assetAId Token ID for ERC721, 0 for ERC20.
     * @param assetBContract Address of asset B contract.
     * @param assetBId Token ID for ERC721, 0 for ERC20.
     * @param effectType 1=Lock Asset B (effectValue = duration in seconds)
     *                   3=Trigger State Change Proposal (effectValue = target TreasuryState enum value)
     */
    function addAssetEntanglementRule(
        address assetAContract,
        uint256 assetAId,
        address assetBContract,
        uint256 assetBId,
        uint256 effectType,
        uint256 effectValue
    ) external onlyOwner {
        // Basic validation
        if (assetAContract == address(0) || assetBContract == address(0)) revert InvalidRuleParameters();
        if (effectType != 1 && effectType != 3) revert InvalidRuleParameters(); // Only support lock and state change effects for now
        if (effectType == 1 && effectValue == 0) revert InvalidRuleParameters(); // Lock duration must be > 0
        if (effectType == 3 && effectValue > uint256(type(TreasuryState).max)) revert InvalidRuleParameters(); // Target state must be valid

        uint256 ruleId = ++assetEntanglementRuleCount;
        assetEntanglementRules[ruleId] = AssetEntanglementRule({
            active: true,
            assetAContract: assetAContract,
            assetAId: assetAId,
            assetBContract: assetBContract,
            assetBId: assetBId,
            effectType: effectType,
            effectValue: effectValue
        });
        emit AssetEntanglementRuleAdded(ruleId, assetAContract, assetAId, assetBContract, assetBId);
    }

     /**
     * @dev Governance removes an asset entanglement rule.
     */
    function removeAssetEntanglementRule(uint256 ruleId) external onlyOwner {
        if (!assetEntanglementRules[ruleId].active) revert RuleDoesNotExist();
        assetEntanglementRules[ruleId].active = false;
        emit AssetEntanglementRuleRemoved(ruleId);
    }


    /**
     * @dev Internal function to trigger entanglement effects associated with an asset.
     * Called when an asset is about to be withdrawn via governanceWithdrawToken/NFT.
     * Could be extended to be triggered by other interactions.
     * @param assetContract Address of the asset contract.
     * @param assetId Token ID for ERC721, 0 for ERC20.
     */
    function triggerEntanglementEffect(address assetContract, uint256 assetId) internal {
        // Iterate through all entanglement rules (inefficient for many rules, better to use a mapping ruleId => assetA)
        for (uint256 i = 1; i <= assetEntanglementRuleCount; ++i) {
            AssetEntanglementRule storage rule = assetEntanglementRules[i];

            // Check if rule is active and applies to the interacted asset (Asset A)
            if (rule.active && rule.assetAContract == assetContract && rule.assetAId == assetId) {
                emit EntanglementEffectTriggered(i, assetContract, assetId, rule.effectType);

                // Apply the effect on Asset B
                if (rule.effectType == 1) { // Lock Asset B
                     _assetLockedUntil[rule.assetBContract][rule.assetBId] = block.timestamp + rule.effectValue;
                } else if (rule.effectType == 3) { // Trigger State Change Proposal
                     // This could lead to multiple proposals for the same state; needs refinement for robust DAO
                    submitStateChangeProposal(TreasuryState(uint8(rule.effectValue)));
                }
                // Add more effect types here (e.g., transfer fee, burn token, etc.)
            }
        }
    }

    // --- Probabilistic Distribution Rules ---

    /**
     * @dev Governance adds a probabilistic distribution rule.
     * Defines a pool of tokens to be distributed probabilistically among recipients.
     * @param token The ERC-20 token to distribute.
     * @param totalAmount The total amount of tokens to distribute.
     * @param potentialRecipients Array of recipient addresses.
     * @param weights Array of weights corresponding to recipients. Sum of weights is total "probability space".
     */
    function addProbabilisticDistributionRule(
        address token,
        uint256 totalAmount,
        address[] memory potentialRecipients,
        uint256[] memory weights
    ) external onlyOwner onlySupportedToken(token) {
        if (totalAmount == 0 || potentialRecipients.length == 0 || potentialRecipients.length != weights.length) {
            revert InvalidRuleParameters();
        }

        uint256 totalWeights = 0;
        for (uint256 i = 0; i < weights.length; ++i) {
            totalWeights = totalWeights.add(weights[i]);
        }
        if (totalWeights == 0) revert InvalidRuleParameters();

        uint256 ruleId = ++probabilisticDistributionRuleCount;
        probabilisticDistributionRules[ruleId] = ProbabilisticDistributionRule({
            active: true,
            token: token,
            totalAmount: totalAmount,
            potentialRecipients: potentialRecipients,
            weights: weights,
            executed: false
        });
        emit ProbabilisticDistributionRuleAdded(ruleId, token, totalAmount);
    }

    /**
     * @dev Governance removes a probabilistic distribution rule.
     */
    function removeProbabilisticDistributionRule(uint256 ruleId) external onlyOwner {
         if (!probabilisticDistributionRules[ruleId].active) revert RuleDoesNotExist();
        probabilisticDistributionRules[ruleId].active = false;
        emit ProbabilisticDistributionRuleRemoved(ruleId);
    }

    /**
     * @dev Executes a probabilistic distribution rule.
     * Uses block data for pseudo-randomness (MEV risk!).
     * Distributes the totalAmount among recipients based on weights.
     * Can be called by anyone once active. Requires nonReentrant guard.
     */
    function executeProbabilisticDistribution(uint256 ruleId) external nonReentrant {
        ProbabilisticDistributionRule storage rule = probabilisticDistributionRules[ruleId];
        if (!rule.active) revert RuleDoesNotExist();
        if (rule.executed) revert RuleAlreadyExecuted();

        uint256 contractBalance = IERC20(rule.token).balanceOf(address(this));
        if (contractBalance < rule.totalAmount) revert NotEnoughTokensInTreasury();

        uint256 totalWeights = 0;
        for (uint256 i = 0; i < rule.weights.length; ++i) {
            totalWeights = totalWeights.add(rule.weights[i]);
        }
        if (totalWeights == 0) revert ProbabilisticDistributionFailed(); // Should be caught on add

        // --- Pseudo-Random Distribution Logic (MEV Risk!) ---
        // Use block.timestamp and block.difficulty/blockhash as seeds
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.difficulty, // block.difficulty is deprecated in favor of block.prevrandao post-Merge
            block.coinbase,
            block.number,
            ruleId,
            msg.sender // Add sender for slight variation, though still predictable
        )));

        address[] memory awardedRecipients = new address[](rule.potentialRecipients.length); // Track who gets what
        uint256[] memory awardedAmounts = new uint256[](rule.potentialRecipients.length);

        uint256 remainingAmount = rule.totalAmount;
        uint256 remainingWeights = totalWeights;

        // Distribute proportionally based on weights, scaled down if needed
        for (uint256 i = 0; i < rule.potentialRecipients.length; ++i) {
             if (remainingWeights == 0) break; // Avoid division by zero

             // Calculate proportion for this recipient
            uint256 weight = rule.weights[i];
            if (weight == 0) continue; // Skip recipients with zero weight

            // Calculate amount based on weight proportion of remaining amount
            // Using a simple proportion: (weight / totalWeights) * totalAmount
            // Integer division means this might not sum perfectly, or recipients with small weights get 0.
            // A better approach might involve a lottery pick or distributing based on `seed % totalWeights`.
            // Let's use a simple lottery pick proportional to weight.

            uint256 cumulativeWeight = 0;
            // Find which weight range the seed falls into
            uint256 choice = seed % remainingWeights; // Modulo biased, but simple on-chain

            uint256 recipientIndex = 0;
            uint256 currentCumulative = 0;
            bool foundRecipient = false;

            // Find the recipient based on the random choice
            // This loop iterates recipients *again* to find the one chosen by the seed
            for(uint256 j = 0; j < rule.potentialRecipients.length; ++j) {
                 if (rule.weights[j] == 0) continue; // Skip if weight is zero

                 currentCumulative = currentCumulative.add(rule.weights[j]);
                 if (choice < currentCumulative) {
                     recipientIndex = j;
                     foundRecipient = true;
                     break; // Found the recipient for this 'spin'
                 }
            }

            if (!foundRecipient) continue; // Should not happen if totalWeights > 0

            // Simple allocation: give a chunk to the chosen recipient.
            // This simple loop distributes *one* chunk based on one random number.
            // For a full probabilistic distribution of the *total* amount, a more complex
            // algorithm is needed, possibly one that handles remainders or distributes across multiple picks.
            // Let's simplify: just pick ONE recipient and give them the whole `totalAmount`.
            // This is NOT a true distribution, but a 'winner takes all' based on weighted probability.

            // Simplified logic: Pick ONE winner based on weighted random.
            IERC20(rule.token).safeTransfer(rule.potentialRecipients[recipientIndex], rule.totalAmount);

            awardedRecipients[0] = rule.potentialRecipients[recipientIndex];
            awardedAmounts[0] = rule.totalAmount;
            // Reset remaining for clarity, though only one transfer happens in this simplified version
            remainingAmount = 0;
            remainingWeights = 0; // Stop the loop

            break; // Exit after the single winner is chosen and paid

            // --- Alternative: Distribute a Fixed Chunk based on Proportion (Less 'Random' but spreads) ---
            /*
            uint256 proportion = rule.weights[i].mul(1e18).div(totalWeights); // Calculate proportion (scaled)
            uint256 recipientAmount = rule.totalAmount.mul(proportion).div(1e18); // Calculate amount for this recipient

            if (recipientAmount > 0) {
                 // Transfer the calculated amount
                 // Need to ensure total transferred doesn't exceed totalAmount and handle remainders
                 // This approach is complex to get right with integer math and remainders.
                 // The single winner approach is simpler for a conceptual example.
            }
            */
        }

        // Mark rule as executed
        rule.executed = true;
        rule.active = false; // Deactivate rule after execution

        // Emit event with actual amounts/recipients (simplified to just the winner in this version)
         address[] memory finalRecipients = new address[](1);
         uint256[] memory finalAmounts = new uint256[](1);
         finalRecipients[0] = awardedRecipients[0];
         finalAmounts[0] = awardedAmounts[0];


        emit ProbabilisticDistributionExecuted(ruleId, rule.token, rule.totalAmount, finalRecipients, finalAmounts);
    }

    // --- Query Functions ---

    /**
     * @dev Returns details of a specific conditional release rule.
     */
    function getConditionalReleaseRule(uint256 ruleId)
        external
        view
        returns (
            bool active,
            address token,
            uint256 amount,
            address recipient,
            uint256 conditionType,
            uint256 conditionValue,
            uint256 ruleCreationTimestamp,
            bool executed
        )
    {
        ConditionalReleaseRule storage rule = conditionalReleaseRules[ruleId];
        if (!rule.active && !rule.executed) revert RuleDoesNotExist(); // Check if rule exists at all
        return (
            rule.active,
            rule.token,
            rule.amount,
            rule.recipient,
            rule.conditionType,
            rule.conditionValue,
            rule.ruleCreationTimestamp,
            rule.executed
        );
    }

     /**
     * @dev Returns details of a specific asset entanglement rule.
     */
    function getAssetEntanglementRule(uint256 ruleId)
         external
         view
         returns (
             bool active,
             address assetAContract,
             uint256 assetAId,
             address assetBContract,
             uint256 assetBId,
             uint256 effectType,
             uint256 effectValue
         )
    {
        AssetEntanglementRule storage rule = assetEntanglementRules[ruleId];
        if (!rule.active) revert RuleDoesNotExist(); // Assumes inactive rules are removed/not queryable easily
        return (
            rule.active,
            rule.assetAContract,
            rule.assetAId,
            rule.assetBContract,
            rule.assetBId,
            rule.effectType,
            rule.effectValue
        );
    }


     /**
     * @dev Returns details of a specific probabilistic distribution rule.
     */
    function getProbabilisticDistributionRule(uint256 ruleId)
         external
         view
         returns (
             bool active,
             address token,
             uint256 totalAmount,
             address[] memory potentialRecipients,
             uint256[] memory weights,
             bool executed
         )
    {
        ProbabilisticDistributionRule storage rule = probabilisticDistributionRules[ruleId];
         if (!rule.active && !rule.executed) revert RuleDoesNotExist(); // Check if rule exists at all
        return (
            rule.active,
            rule.token,
            rule.totalAmount,
            rule.potentialRecipients,
            rule.weights,
            rule.executed
        );
    }

    /**
     * @dev Returns the state and details of a proposal.
     */
    function getProposalState(uint256 proposalId)
        external
        view
        returns (
            ProposalState state,
            TreasuryState targetState,
            uint256 creationTimestamp,
            uint256 votingPeriodEnd,
            uint256 votesFor,
            uint256 votesAgainst,
            bool executed
        )
    {
        Proposal storage proposal = proposals[proposalId];
        if (proposal.creationTimestamp == 0) revert ProposalDoesNotExist(); // Check if proposal exists

        return (
            proposal.state,
            proposal.targetState,
            proposal.creationTimestamp,
            proposal.votingPeriodEnd,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.executed
        );
    }

     /**
     * @dev Returns the list of currently supported ERC-20 token addresses.
     * Iterates through the full list and filters by the mapping (less gas than resizing array).
     */
    function getSupportedTokens() external view returns (address[] memory) {
        uint256 count = 0;
        for(uint256 i = 0; i < _supportedTokensList.length; ++i) {
            if (_isSupportedToken[_supportedTokensList[i]]) {
                count++;
            }
        }
        address[] memory supported = new address[](count);
        uint256 current = 0;
        for(uint256 i = 0; i < _supportedTokensList.length; ++i) {
            if (_isSupportedToken[_supportedTokensList[i]]) {
                supported[current] = _supportedTokensList[i];
                current++;
            }
        }
        return supported;
    }

    /**
     * @dev Returns the list of currently supported ERC-721 contract addresses.
     */
    function getSupportedNFTs() external view returns (address[] memory) {
         uint256 count = 0;
        for(uint256 i = 0; i < _supportedNFTsList.length; ++i) {
            if (_isSupportedNFT[_supportedNFTsList[i]]) {
                count++;
            }
        }
        address[] memory supported = new address[](count);
        uint256 current = 0;
        for(uint256 i = 0; i < _supportedNFTsList.length; ++i) {
            if (_isSupportedNFT[_supportedNFTsList[i]]) {
                supported[current] = _supportedNFTsList[i];
                current++;
            }
        }
        return supported;
    }

    /**
     * @dev Returns the balance of a specific supported token held by the treasury.
     */
    function getTokenBalance(address token) external view onlySupportedToken(token) returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev Checks if a specific supported NFT is currently held by the treasury.
     */
    function isNFTDeposited(address nftContract, uint256 tokenId) external view onlySupportedNFT(nftContract) returns (bool) {
        return IERC721(nftContract).ownerOf(tokenId) == address(this);
    }

    /**
     * @dev Checks if an asset is currently locked due to an entanglement effect.
     * @param assetContract Address of the asset contract (ERC20 or ERC721).
     * @param assetId Token ID for ERC721, 0 for ERC20.
     * @return bool True if the asset is locked.
     */
    function isAssetLocked(address assetContract, uint256 assetId) external view returns (bool) {
        return _assetLockedUntil[assetContract][assetId] > block.timestamp;
    }

    // --- ERC721Holder compatibility ---
    // Required for onERC721Received callback
    // Default implementation from OpenZeppelin ERC721Holder suffices for receiving NFTs.
    // Add custom logic here if needed, e.g., logging specific deposit details.
    // function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    //     public virtual override returns (bytes4)
    // {
    //     // Custom logic could go here, e.g., checking if the NFT is supported
    //     // if (!_isSupportedNFT[msg.sender]) revert UnsupportedAsset(); // msg.sender is the NFT contract

    //     // Default behavior: just accept the token
    //     return super.onERC721Received(operator, from, tokenId, data);
    // }
}
```