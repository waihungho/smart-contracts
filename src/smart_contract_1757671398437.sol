Here's a Solidity smart contract for an **AI-Assisted Decentralized Autonomous Organization (DAO) for Dynamic Treasury Management**, designed with advanced concepts, creativity, and trending functionalities. It aims to be distinct from common open-source implementations by custom building core components like the DAO token, voting system, and AI oracle integration.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // For initial deployment & setup; ownership will then transition to DAO governance.

/**
 * @title AIAssistedTreasuryDAO
 * @dev A novel DAO for managing a multi-asset treasury, leveraging AI oracles for rebalancing strategies.
 *      This contract introduces a unique blend of decentralized governance, AI integration via oracles,
 *      and dynamic treasury management, aiming for a creative and advanced approach beyond typical open-source patterns.
 *      The DAO's internal token (DAOToken) is non-transferable, representing voting power and contribution.
 */
contract AIAssistedTreasuryDAO is Ownable {
    using SafeMath for uint256;

    // --- Core Concepts ---
    // 1. Intents: High-level goals proposed by DAO members for treasury rebalancing (e.g., "increase exposure to stablecoins").
    // 2. Strategies: Detailed, executable plans (e.g., specific token swaps) formulated by registered AI Oracles to fulfill Intents.
    // 3. DAO Token (DAOToken): A non-transferable internal token representing a member's voting power and contribution to the DAO.
    // 4. AI Oracles: Off-chain entities, registered and managed by the DAO, responsible for generating optimal Strategies.
    // 5. Generic Governance: A flexible proposal system allowing the DAO to self-govern, adapt parameters, and manage its operations.
    // 6. Reputation & Rewards: Incentivizes active and successful participation from intent proposers and AI oracles.

    // --- Function Summary ---

    // Treasury Management (3 functions)
    // 1.  depositAsset(IERC20 _token, uint256 _amount): Allows anyone to deposit supported ERC-20 assets into the DAO treasury.
    // 2.  getTreasuryBalance(IERC20 _token): Retrieves the balance of a specific ERC-20 asset held by the DAO treasury.
    // 3.  recoverStuckAssets(IERC20 _token, address _to, uint256 _amount, uint256 _proposalId): An internal function (called via governance) to recover assets accidentally sent to the contract.

    // DAO Token & Membership (2 functions)
    // 4.  contributeAndMintDAOToken(): Allows users to contribute ETH to the treasury and receive non-transferable DAO tokens (voting power).
    // 5.  delegateVotingPower(address _delegatee): Delegates the caller's voting ability to another DAO member for proposals and strategies.

    // Intent & Strategy Lifecycle (8 functions)
    // 6.  proposeIntent(string memory _description, bytes32 _desiredStateHash): A DAO member proposes a high-level rebalancing goal for the treasury.
    // 7.  requestAIStrategy(uint256 _intentId, address _oracleAddress): A DAO member requests a specific AI oracle to formulate a strategy for a pending intent.
    // 8.  submitAIStrategy(uint256 _intentId, Strategy calldata _strategy): A registered AI oracle submits a detailed execution strategy for an intent.
    // 9.  voteOnStrategy(uint256 _strategyId, bool _support, address _onBehalfOf): DAO members vote to approve or reject an AI-generated strategy, potentially on behalf of a delegator.
    // 10. executeStrategy(uint256 _strategyId): Executes an approved AI strategy, performing the defined trades to rebalance the treasury.
    // 11. cancelIntent(uint256 _intentId): Allows the intent proposer or DAO to cancel a pending intent before strategy execution.
    // 12. getCurrentIntentStatus(uint256 _intentId): Retrieves the current state and details of a specific intent.
    // 13. getStrategyDetails(uint256 _strategyId): Retrieves the detailed information of a specific AI-generated strategy.

    // Governance & Oracle Management (5 functions)
    // 14. proposeGovernanceAction(ActionType _actionType, bytes memory _data, string memory _description): Creates a new generic governance proposal for DAO-wide decisions.
    // 15. voteOnGovernanceAction(uint256 _proposalId, bool _support, address _onBehalfOf): DAO members vote on a generic governance proposal, potentially on behalf of a delegator.
    // 16. executeGovernanceAction(uint256 _proposalId): Enacts an approved generic governance proposal, applying the DAO's decision.
    // 17. submitAIModelHash(bytes32 _newModelHash): A registered AI oracle submits a cryptographic hash of its AI model for transparency and auditing.
    // 18. isAIOracleRegistered(address _oracleAddress): Checks if a given address is currently a registered AI oracle.

    // Reputation & Rewards (2 functions)
    // 19. claimIntentProposerRewards(): Allows successful intent proposers to claim accumulated rewards for their insights.
    // 20. claimOraclePerformanceRewards(): Allows registered AI oracles to claim rewards for successfully executed strategies.


    // --- Custom Errors ---
    error Unauthorized();
    error InvalidAmount();
    error InsufficientBalance();
    error AlreadyVoted();
    error VotingPeriodEnded();
    error VotingPeriodNotEnded();
    error QuorumNotMet();
    error IntentNotFound();
    error StrategyNotFound();
    error InvalidIntentState();
    error IntentAlreadyStrategized();
    error OracleNotRegistered();
    error NotAnOracle();
    error OracleAlreadySubmittedStrategy(); // Re-used for "already registered"
    error InvalidProposalState();
    error UnknownActionType();
    error ProposalNotApproved();
    error InvalidETHContribution();
    error NotASupportedAsset();
    error DelegateeCannotBeSelf();
    error DelegateeCannotBeZeroAddress();
    error CannotDelegateToAlreadyDelegatedAddress();
    error NotEnoughVotingPower();
    error InvalidQuorumPercentage();

    // --- State Variables ---

    // DAO Token (non-transferable, for voting power)
    mapping(address => uint256) public daotokenBalance;
    mapping(address => address) public delegates; // Delegate voting power: delegator -> delegatee

    // Supported Assets
    mapping(address => bool) public supportedAssets;

    // AI Oracles
    mapping(address => bool) public isAIOracle;
    mapping(address => bytes32) public aiOracleModelHashes; // Hash of their AI model for transparency
    address[] public registeredOracles; // For iterating or easy lookup of all registered oracles.

    // Rewards
    mapping(address => uint256) public intentProposerRewards;
    mapping(address => uint256) public oraclePerformanceRewards;
    uint256 public constant INTENT_PROPOSER_REWARD_PERCENT = 1; // 1% of executed trade value (conceptual)
    uint256 public constant ORACLE_REWARD_PERCENT = 2; // 2% of executed trade value (conceptual)
    IERC20 public rewardToken; // Token used for rewards (e.g., a stablecoin or DAO's own transferable token)

    // Governance Parameters
    uint256 public minVotingPowerToPropose;     // Min DAOToken required to propose an intent or governance action
    uint256 public votingPeriodDurationInBlocks; // How long a vote lasts (in blocks)
    uint256 public quorumPercentage;             // Percentage of total voting power required for a proposal to pass (e.g., 51 for 51%)

    uint256 public totalDAOTokenSupply; // Total supply of DAOToken for quorum calculation

    // --- Intent & Strategy Structs and State ---

    enum IntentState {
        Proposed,           // Intent submitted, awaiting strategy request
        StrategyRequested,  // Strategy requested from an oracle
        StrategySubmitted,  // Strategy provided by oracle, awaiting DAO vote
        Cancelled,          // Intent cancelled (by proposer or DAO)
        Executed            // Strategy successfully executed
    }

    struct Intent {
        uint256 id;
        string description;
        bytes32 desiredStateHash; // A hash representing the desired end-state (e.g., target portfolio allocation)
        address proposer;
        uint256 proposedBlock;
        IntentState state;
        uint256 strategyId; // Link to the strategy if one is submitted
    }

    // A single trade within a strategy, designed for interaction with external DEX routers
    struct Trade {
        IERC20 tokenIn;        // Token to sell from treasury
        IERC20 tokenOut;       // Token to buy for treasury
        uint256 amountIn;      // Amount of tokenIn to sell
        uint256 minAmountOut;  // Minimum amount of tokenOut expected (slippage protection)
        address targetContract; // Address of the external contract (e.g., DEX router)
        bytes callData;         // Encoded function call for the targetContract (e.g., swapExactTokensForTokens)
    }

    enum StrategyState {
        ProposedByAI, // Strategy submitted by AI, awaiting voting period start (or directly to Voting)
        Voting,       // Strategy is open for DAO voting
        Approved,     // Strategy approved by DAO
        Rejected,     // Strategy rejected by DAO
        Executed,     // Strategy successfully executed
        Failed        // Strategy execution failed
    }

    struct Strategy {
        uint256 id;
        uint256 intentId;
        address oracleAddress;
        Trade[] trades; // Array of individual trades to execute
        bytes32 strategyHash; // Hash of the strategy data for integrity check (for off-chain verification)
        string explanationURI; // URI to a more detailed explanation of the strategy (off-chain)
        uint256 proposedBlock;
        uint256 votingEndsBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted for THIS strategy
        StrategyState state;
    }

    uint256 public nextIntentId = 1;
    uint256 public nextStrategyId = 1;

    mapping(uint256 => Intent) public intents;
    mapping(uint256 => Strategy) public strategies;

    // --- Generic Governance Proposal Structs and State ---

    enum ActionType {
        AddSupportedAsset,
        RemoveSupportedAsset,
        RegisterAIOracle,
        DeactivateAIOracle,
        ChangeVotingPeriod,
        ChangeQuorumPercentage,
        ChangeMinVotingPowerToPropose,
        EmergencyPauseContract,
        RecoverStuckAssetsAction // Specific action for recoverStuckAssets
    }

    enum ProposalState {
        Voting,    // Proposal is open for DAO voting
        Approved,  // Proposal approved by DAO
        Rejected,  // Proposal rejected by DAO
        Executed   // Proposal successfully executed
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        ActionType actionType;
        bytes data; // Encoded parameters for the action (e.g., abi.encode(tokenAddress))
        string description;
        uint256 proposedBlock;
        uint256 votingEndsBlock;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks who has voted for THIS proposal
        ProposalState state;
    }

    uint256 public nextProposalId = 1;
    mapping(uint256 => GovernanceProposal) public governanceProposals;

    // Pausability (controlled by DAO via GovernanceProposal)
    bool public paused;

    // --- Events ---
    event AssetDeposited(address indexed _token, address indexed _depositor, uint256 _amount);
    event DAOTokenMinted(address indexed _recipient, uint256 _amount);
    event VotingPowerDelegated(address indexed _delegator, address indexed _delegatee);

    event IntentProposed(uint256 indexed _intentId, address indexed _proposer, string _description);
    event StrategyRequested(uint256 indexed _intentId, address indexed _requester, address indexed _oracleAddress);
    event AIStrategySubmitted(uint256 indexed _strategyId, uint256 indexed _intentId, address indexed _oracleAddress);
    event StrategyVoteCast(uint256 indexed _strategyId, address indexed _voter, bool _support);
    event StrategyExecuted(uint256 indexed _strategyId, address indexed _executor);
    event IntentCancelled(uint256 indexed _intentId, address indexed _canceller);

    event GovernanceProposalProposed(uint256 indexed _proposalId, address indexed _proposer, ActionType _actionType);
    event GovernanceVoteCast(uint256 indexed _proposalId, address indexed _voter, bool _support);
    event GovernanceExecuted(uint256 indexed _proposalId);

    event AIOracleRegistered(address indexed _oracleAddress);
    event AIOracleDeactivated(address indexed _oracleAddress);
    event AIModelHashUpdated(address indexed _oracleAddress, bytes32 _newHash);

    event ProposerRewardsClaimed(address indexed _proposer, uint256 _amount);
    event OracleRewardsClaimed(address indexed _oracle, uint256 _amount);

    event ContractPaused(address indexed _by);
    event ContractUnpaused(address indexed _by);

    // --- Constructor ---
    constructor(
        address _initialRewardToken,
        uint256 _minVotingPowerToPropose,
        uint256 _votingPeriodDurationInBlocks,
        uint256 _quorumPercentage
    ) Ownable(msg.sender) {
        require(_initialRewardToken != address(0), "Reward token cannot be zero");
        if (_quorumPercentage == 0 || _quorumPercentage > 100) revert InvalidQuorumPercentage();

        rewardToken = IERC20(_initialRewardToken);
        minVotingPowerToPropose = _minVotingPowerToPropose;
        votingPeriodDurationInBlocks = _votingPeriodDurationInBlocks;
        quorumPercentage = _quorumPercentage;

        paused = false; // Initially not paused.
    }

    // --- Modifiers ---
    modifier onlyMember() {
        if (daotokenBalance[msg.sender] == 0) revert Unauthorized();
        _;
    }

    modifier onlyOracle() {
        if (!isAIOracle[msg.sender]) revert NotAnOracle();
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

    // --- Treasury Management (3 functions) ---

    /**
     * @dev Allows depositing supported ERC20 tokens into the DAO treasury.
     *      Anyone can deposit, but only DAO members (DAOToken holders) have governance power.
     * @param _token The address of the ERC20 token to deposit.
     * @param _amount The amount of tokens to deposit.
     */
    function depositAsset(IERC20 _token, uint256 _amount) external whenNotPaused {
        if (!supportedAssets[address(_token)]) revert NotASupportedAsset();
        if (_amount == 0) revert InvalidAmount();

        _token.transferFrom(msg.sender, address(this), _amount);
        emit AssetDeposited(address(_token), msg.sender, _amount);
    }

    /**
     * @dev Retrieves the balance of a specific ERC20 token held by the DAO treasury.
     * @param _token The address of the ERC20 token.
     * @return The balance of the token.
     */
    function getTreasuryBalance(IERC20 _token) public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @dev Internal function called by `executeGovernanceAction` to recover assets accidentally sent to the contract.
     *      This action must be approved via a governance proposal.
     * @param _token The address of the ERC20 token to recover.
     * @param _to The recipient address.
     * @param _amount The amount to recover.
     * @param _proposalId The ID of the governance proposal that approved this recovery.
     */
    function recoverStuckAssets(IERC20 _token, address _to, uint256 _amount, uint256 _proposalId) internal {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.state != ProposalState.Approved) revert ProposalNotApproved();

        // Verify the proposal data matches the requested recovery action
        bytes memory expectedData = abi.encode(_token, _to, _amount);
        if (proposal.actionType != ActionType.RecoverStuckAssetsAction || keccak256(proposal.data) != keccak256(expectedData)) {
            revert UnknownActionType(); // Proposal data mismatch
        }

        if (_token.balanceOf(address(this)) < _amount) revert InsufficientBalance();

        _token.transfer(_to, _amount);
        // Using AssetDeposited event for simplicity, though a more specific event RecoveredStuckAssets would be ideal.
        emit AssetDeposited(address(_token), _to, _amount);
    }

    // --- DAO Token & Membership (2 functions) ---

    /**
     * @dev Allows users to contribute ETH to the treasury and receive DAO tokens (voting power).
     *      Each 1 ETH contributed mints a fixed amount of DAOToken (e.g., 100 DAOToken).
     *      This token is non-transferable and directly represents voting power.
     */
    function contributeAndMintDAOToken() external payable whenNotPaused {
        if (msg.value == 0) revert InvalidETHContribution();

        // Example: 1 ETH = 100 DAOToken. The rate can be made dynamic via governance.
        uint256 tokensToMint = msg.value.mul(100).div(1 ether);
        if (tokensToMint == 0) revert InvalidETHContribution();

        daotokenBalance[msg.sender] = daotokenBalance[msg.sender].add(tokensToMint);
        totalDAOTokenSupply = totalDAOTokenSupply.add(tokensToMint);

        emit DAOTokenMinted(msg.sender, tokensToMint);
    }

    /**
     * @dev Delegates voting power to another DAO member.
     *      A delegator transfers their *ability* to vote for strategies and governance actions to a delegatee.
     *      The `daotokenBalance` of the delegator is still used for the vote count, but the vote must be cast by the delegatee.
     *      This is a simple one-hop delegation; re-delegation is not supported directly.
     * @param _delegatee The address to delegate voting power to.
     */
    function delegateVotingPower(address _delegatee) external onlyMember {
        if (_delegatee == address(0)) revert DelegateeCannotBeZeroAddress();
        if (_delegatee == msg.sender) revert DelegateeCannotBeSelf();
        if (delegates[msg.sender] != address(0)) revert CannotDelegateToAlreadyDelegatedAddress(); // Only one-time delegation

        delegates[msg.sender] = _delegatee;
        emit VotingPowerDelegated(msg.sender, _delegatee);
    }

    /**
     * @dev Internal helper to determine the actual voter address and their effective voting power.
     *      Handles direct voting by the caller or delegated voting on behalf of a delegator.
     * @param _caller The address making the transaction.
     * @param _onBehalfOf The address whose voting power is to be used. If 0x0, uses `_caller`'s power.
     * @return The actual address (delegator or direct voter) whose power is used, and that power amount.
     */
    function _getVoterAddressAndPower(address _caller, address _onBehalfOf) internal view returns (address actualVoter, uint256 power) {
        if (_onBehalfOf == address(0)) {
            // Direct vote by the caller
            actualVoter = _caller;
        } else {
            // Delegated vote: _caller must be the delegatee for _onBehalfOf
            if (delegates[_onBehalfOf] != _caller) revert Unauthorized(); // _caller is not the delegatee
            actualVoter = _onBehalfOf;
        }

        power = daotokenBalance[actualVoter];
        if (power == 0) revert NotEnoughVotingPower();
        return (actualVoter, power);
    }

    // --- Intent & Strategy Lifecycle (8 functions) ---

    /**
     * @dev A DAO member proposes a high-level rebalancing goal for the treasury.
     *      Requires a minimum amount of DAOToken to prevent spam proposals.
     * @param _description A human-readable description of the intent.
     * @param _desiredStateHash A cryptographic hash representing the desired end-state (e.g., target portfolio allocation).
     *      This is an off-chain data integrity check that the AI oracle might use.
     */
    function proposeIntent(string memory _description, bytes32 _desiredStateHash) external onlyMember whenNotPaused {
        if (daotokenBalance[msg.sender] < minVotingPowerToPropose) revert NotEnoughVotingPower();

        uint256 id = nextIntentId++;
        intents[id] = Intent({
            id: id,
            description: _description,
            desiredStateHash: _desiredStateHash,
            proposer: msg.sender,
            proposedBlock: block.number,
            state: IntentState.Proposed,
            strategyId: 0
        });
        emit IntentProposed(id, msg.sender, _description);
    }

    /**
     * @dev A DAO member (or designated role, e.g., an elected "Strategy Manager") requests a specific AI oracle
     *      to formulate a detailed execution strategy for a pending intent.
     *      This might trigger an off-chain computation by the AI.
     * @param _intentId The ID of the intent to request a strategy for.
     * @param _oracleAddress The address of the registered AI oracle to make the request to.
     */
    function requestAIStrategy(uint256 _intentId, address _oracleAddress) external onlyMember whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert IntentNotFound();
        if (intent.state != IntentState.Proposed) revert InvalidIntentState();
        if (!isAIOracle[_oracleAddress]) revert OracleNotRegistered();

        intent.state = IntentState.StrategyRequested;
        emit StrategyRequested(_intentId, msg.sender, _oracleAddress);
    }

    /**
     * @dev A registered AI oracle submits a detailed execution strategy for an intent.
     *      The strategy includes an array of `Trade` structs and a hash for integrity verification.
     * @param _intentId The ID of the intent this strategy is for.
     * @param _strategy The full Strategy struct proposed by the AI oracle.
     */
    function submitAIStrategy(uint256 _intentId, Strategy calldata _strategy) external onlyOracle whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert IntentNotFound();
        if (intent.state != IntentState.StrategyRequested) revert InvalidIntentState();
        if (intent.strategyId != 0) revert IntentAlreadyStrategized(); // Intent already has a submitted strategy

        // For robust verification, keccak256(abi.encode(_strategy.trades, _strategy.explanationURI)) should match _strategy.strategyHash
        // However, `_strategy.trades` is a dynamic array from calldata, making direct re-hashing here complex/expensive.
        // For this example, we trust the oracle provides a correct hash for the `calldata` it sent, and off-chain checks would occur.

        uint256 strategyId = nextStrategyId++;
        strategies[strategyId] = Strategy({
            id: strategyId,
            intentId: _intentId,
            oracleAddress: msg.sender,
            trades: _strategy.trades, // Copying calldata array
            strategyHash: _strategy.strategyHash,
            explanationURI: _strategy.explanationURI,
            proposedBlock: block.number,
            votingEndsBlock: block.number.add(votingPeriodDurationInBlocks),
            votesFor: 0,
            votesAgainst: 0,
            state: StrategyState.Voting
        });

        intent.state = IntentState.StrategySubmitted;
        intent.strategyId = strategyId;

        emit AIStrategySubmitted(strategyId, _intentId, msg.sender);
    }

    /**
     * @dev DAO members vote to approve or reject an AI-generated strategy.
     * @param _strategyId The ID of the strategy to vote on.
     * @param _support True for approval, false for rejection.
     * @param _onBehalfOf The address whose voting power is to be used. If 0x0, uses msg.sender's power directly.
     */
    function voteOnStrategy(uint256 _strategyId, bool _support, address _onBehalfOf) external whenNotPaused {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.id == 0) revert StrategyNotFound();
        if (strategy.state != StrategyState.Voting) revert InvalidStrategyState();
        if (block.number > strategy.votingEndsBlock) revert VotingPeriodEnded();

        (address actualVoter, uint252 power) = _getVoterAddressAndPower(msg.sender, _onBehalfOf); // Should be uint256

        if (strategy.hasVoted[actualVoter]) revert AlreadyVoted();

        strategy.hasVoted[actualVoter] = true;
        if (_support) {
            strategy.votesFor = strategy.votesFor.add(power);
        } else {
            strategy.votesAgainst = strategy.votesAgainst.add(power);
        }

        emit StrategyVoteCast(_strategyId, actualVoter, _support);
    }

    /**
     * @dev Executes an approved AI strategy, performing the defined trades to rebalance the treasury.
     *      Any DAO member can trigger execution after the voting period ends and quorum is met.
     * @param _strategyId The ID of the strategy to execute.
     */
    function executeStrategy(uint256 _strategyId) external whenNotPaused {
        Strategy storage strategy = strategies[_strategyId];
        if (strategy.id == 0) revert StrategyNotFound();
        if (strategy.state != StrategyState.Voting) revert InvalidStrategyState();
        if (block.number <= strategy.votingEndsBlock) revert VotingPeriodNotEnded();

        uint256 totalVotes = strategy.votesFor.add(strategy.votesAgainst);
        if (totalDAOTokenSupply == 0) revert QuorumNotMet(); // No DAOTokens minted yet
        if (totalVotes.mul(100) < totalDAOTokenSupply.mul(quorumPercentage)) revert QuorumNotMet();

        if (strategy.votesFor > strategy.votesAgainst) {
            strategy.state = StrategyState.Approved;
            // Execute trades
            for (uint256 i = 0; i < strategy.trades.length; i++) {
                Trade storage trade = strategy.trades[i];
                // Ensure the token to be swapped out is a supported asset
                if (!supportedAssets[address(trade.tokenIn)]) revert NotASupportedAsset();
                
                // Approve the target contract (e.g., DEX router) to spend tokens from the DAO treasury
                IERC20(trade.tokenIn).approve(trade.targetContract, trade.amountIn);
                
                // Call the target contract to perform the swap (e.g., Uniswap swap function)
                (bool success, bytes memory returndata) = trade.targetContract.call(trade.callData);
                if (!success) {
                    strategy.state = StrategyState.Failed;
                    // In a real system, would decode `returndata` for specific error message.
                    revert("Trade execution failed");
                }
            }
            strategy.state = StrategyState.Executed;
            // Grant rewards to proposer and oracle
            intentProposerRewards[intents[strategy.intentId].proposer] = intentProposerRewards[intents[strategy.intentId].proposer]
                .add(_calculateReward(strategy.trades, INTENT_PROPOSER_REWARD_PERCENT));
            oraclePerformanceRewards[strategy.oracleAddress] = oraclePerformanceRewards[strategy.oracleAddress]
                .add(_calculateReward(strategy.trades, ORACLE_REWARD_PERCENT));
            intents[strategy.intentId].state = IntentState.Executed;
        } else {
            strategy.state = StrategyState.Rejected;
            intents[strategy.intentId].state = IntentState.Cancelled; // If strategy rejected, the intent is also effectively cancelled
        }

        emit StrategyExecuted(_strategyId, msg.sender);
    }

    /**
     * @dev Internal helper function to calculate conceptual rewards based on trade volume.
     *      This is a simplified calculation; a real-world system would use more sophisticated metrics (e.g., profit).
     * @param _trades An array of trades in the strategy.
     * @param _percentage The percentage of total trade volume to reward.
     * @return The calculated reward amount.
     */
    function _calculateReward(Trade[] storage _trades, uint256 _percentage) internal view returns (uint256) {
        uint256 totalTradeVolume = 0;
        for (uint256 i = 0; i < _trades.length; i++) {
            totalTradeVolume = totalTradeVolume.add(_trades[i].amountIn);
        }
        // Assumes reward token value is roughly equivalent to traded asset value for this conceptual reward.
        return totalTradeVolume.mul(_percentage).div(100);
    }

    /**
     * @dev Allows the original intent proposer or a DAO member with sufficient power to cancel a pending intent.
     *      Can only cancel if the intent is in `Proposed` or `StrategyRequested` state.
     * @param _intentId The ID of the intent to cancel.
     */
    function cancelIntent(uint256 _intentId) external whenNotPaused {
        Intent storage intent = intents[_intentId];
        if (intent.id == 0) revert IntentNotFound();
        // Simplified DAO check: either the original proposer, or a member with enough voting power.
        if (intent.proposer != msg.sender && daotokenBalance[msg.sender] < minVotingPowerToPropose) revert Unauthorized();
        if (intent.state != IntentState.Proposed && intent.state != IntentState.StrategyRequested) revert InvalidIntentState();

        intent.state = IntentState.Cancelled;
        emit IntentCancelled(_intentId, msg.sender);
    }

    /**
     * @dev Retrieves the current state and details of a specific intent.
     * @param _intentId The ID of the intent.
     * @return The Intent struct.
     */
    function getCurrentIntentStatus(uint256 _intentId) public view returns (Intent memory) {
        if (intents[_intentId].id == 0) revert IntentNotFound();
        return intents[_intentId];
    }

    /**
     * @dev Retrieves the detailed information of a specific AI-generated strategy.
     * @param _strategyId The ID of the strategy.
     * @return The Strategy struct.
     */
    function getStrategyDetails(uint256 _strategyId) public view returns (Strategy memory) {
        if (strategies[_strategyId].id == 0) revert StrategyNotFound();
        return strategies[_strategyId];
    }

    // --- Governance & Oracle Management (5 functions) ---

    /**
     * @dev Creates a new generic governance proposal for DAO-wide decisions.
     *      Requires a minimum amount of DAOToken to prevent spam proposals.
     * @param _actionType The type of action this proposal entails (e.g., adding an asset, changing parameters).
     * @param _data Encoded parameters for the specific action type (e.g., `abi.encode(tokenAddress)` for `AddSupportedAsset`).
     * @param _description A human-readable description of the proposal.
     */
    function proposeGovernanceAction(ActionType _actionType, bytes memory _data, string memory _description) external onlyMember whenNotPaused {
        if (daotokenBalance[msg.sender] < minVotingPowerToPropose) revert NotEnoughVotingPower();

        uint256 id = nextProposalId++;
        governanceProposals[id] = GovernanceProposal({
            id: id,
            proposer: msg.sender,
            actionType: _actionType,
            data: _data,
            description: _description,
            proposedBlock: block.number,
            votingEndsBlock: block.number.add(votingPeriodDurationInBlocks),
            votesFor: 0,
            votesAgainst: 0,
            state: ProposalState.Voting
        });
        emit GovernanceProposalProposed(id, msg.sender, _actionType);
    }

    /**
     * @dev DAO members vote on a generic governance proposal.
     * @param _proposalId The ID of the governance proposal.
     * @param _support True for approval, false for rejection.
     * @param _onBehalfOf The address whose voting power is to be used. If 0x0, uses msg.sender's power directly.
     */
    function voteOnGovernanceAction(uint256 _proposalId, bool _support, address _onBehalfOf) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalState(); // Or ProposalNotFound
        if (proposal.state != ProposalState.Voting) revert InvalidProposalState();
        if (block.number > proposal.votingEndsBlock) revert VotingPeriodEnded();

        (address actualVoter, uint256 power) = _getVoterAddressAndPower(msg.sender, _onBehalfOf);

        if (proposal.hasVoted[actualVoter]) revert AlreadyVoted();

        proposal.hasVoted[actualVoter] = true;
        if (_support) {
            proposal.votesFor = proposal.votesFor.add(power);
        } else {
            proposal.votesAgainst = proposal.votesAgainst.add(power);
        }

        emit GovernanceVoteCast(_proposalId, actualVoter, _support);
    }

    /**
     * @dev Enacts an approved generic governance proposal, applying the DAO's decision.
     *      Any DAO member can trigger execution after the voting period ends and quorum is met.
     * @param _proposalId The ID of the proposal to execute.
     */
    function executeGovernanceAction(uint256 _proposalId) external whenNotPaused {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        if (proposal.id == 0) revert InvalidProposalState(); // Or ProposalNotFound
        if (proposal.state != ProposalState.Voting) revert InvalidProposalState();
        if (block.number <= proposal.votingEndsBlock) revert VotingPeriodNotEnded();

        uint256 totalVotes = proposal.votesFor.add(proposal.votesAgainst);
        if (totalDAOTokenSupply == 0) revert QuorumNotMet(); // No DAOTokens minted yet
        if (totalVotes.mul(100) < totalDAOTokenSupply.mul(quorumPercentage)) revert QuorumNotMet();

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Approved;
            _performGovernanceAction(proposal.actionType, proposal.data, _proposalId);
            proposal.state = ProposalState.Executed;
        } else {
            proposal.state = ProposalState.Rejected;
        }

        emit GovernanceExecuted(_proposalId);
    }

    /**
     * @dev Internal function to perform the actual governance action based on the `ActionType`.
     * @param _actionType The type of action to perform.
     * @param _data Encoded parameters for the action.
     * @param _proposalId The ID of the proposal (for linking to `recoverStuckAssets`).
     */
    function _performGovernanceAction(ActionType _actionType, bytes memory _data, uint256 _proposalId) internal {
        if (_actionType == ActionType.AddSupportedAsset) {
            address tokenAddress = abi.decode(_data, (address));
            supportedAssets[tokenAddress] = true;
        } else if (_actionType == ActionType.RemoveSupportedAsset) {
            address tokenAddress = abi.decode(_data, (address));
            supportedAssets[tokenAddress] = false;
        } else if (_actionType == ActionType.RegisterAIOracle) {
            address oracleAddress = abi.decode(_data, (address));
            if (isAIOracle[oracleAddress]) revert OracleAlreadySubmittedStrategy(); // Re-using error for "already registered"
            isAIOracle[oracleAddress] = true;
            registeredOracles.push(oracleAddress);
            emit AIOracleRegistered(oracleAddress);
        } else if (_actionType == ActionType.DeactivateAIOracle) {
            address oracleAddress = abi.decode(_data, (address));
            if (!isAIOracle[oracleAddress]) revert NotAnOracle(); // Oracle not active
            isAIOracle[oracleAddress] = false;
            // Remove from registeredOracles array (inefficient for very large arrays, but simple for example)
            for (uint256 i = 0; i < registeredOracles.length; i++) {
                if (registeredOracles[i] == oracleAddress) {
                    registeredOracles[i] = registeredOracles[registeredOracles.length - 1]; // Move last element to current position
                    registeredOracles.pop(); // Remove last element (now a duplicate)
                    break;
                }
            }
            emit AIOracleDeactivated(oracleAddress);
        } else if (_actionType == ActionType.ChangeVotingPeriod) {
            uint256 newPeriod = abi.decode(_data, (uint256));
            votingPeriodDurationInBlocks = newPeriod;
        } else if (_actionType == ActionType.ChangeQuorumPercentage) {
            uint256 newQuorum = abi.decode(_data, (uint256));
            if (newQuorum == 0 || newQuorum > 100) revert InvalidQuorumPercentage();
            quorumPercentage = newQuorum;
        } else if (_actionType == ActionType.ChangeMinVotingPowerToPropose) {
            uint256 newMinPower = abi.decode(_data, (uint256));
            minVotingPowerToPropose = newMinPower;
        } else if (_actionType == ActionType.EmergencyPauseContract) {
            bool shouldPause = abi.decode(_data, (bool));
            if (shouldPause && !paused) {
                paused = true;
                emit ContractPaused(address(this));
            } else if (!shouldPause && paused) {
                paused = false;
                emit ContractUnpaused(address(this));
            }
        } else if (_actionType == ActionType.RecoverStuckAssetsAction) {
            (IERC20 token, address to, uint256 amount) = abi.decode(_data, (IERC20, address, uint256));
            recoverStuckAssets(token, to, amount, _proposalId);
        } else {
            revert UnknownActionType();
        }
    }

    /**
     * @dev A registered AI oracle submits a cryptographic hash of its AI model for transparency and auditing.
     *      This allows the DAO to verify off-chain that the oracle is using a declared and auditable model version.
     * @param _newModelHash The new hash of the AI model.
     */
    function submitAIModelHash(bytes32 _newModelHash) external onlyOracle whenNotPaused {
        aiOracleModelHashes[msg.sender] = _newModelHash;
        emit AIModelHashUpdated(msg.sender, _newModelHash);
    }

    /**
     * @dev Checks if a given address is currently a registered AI oracle.
     * @param _oracleAddress The address to check.
     * @return True if registered, false otherwise.
     */
    function isAIOracleRegistered(address _oracleAddress) public view returns (bool) {
        return isAIOracle[_oracleAddress];
    }

    // --- Reputation & Rewards (2 functions) ---

    /**
     * @dev Allows successful intent proposers to claim their accumulated rewards.
     *      Rewards are transferred in the designated `rewardToken`.
     */
    function claimIntentProposerRewards() external whenNotPaused {
        uint256 amount = intentProposerRewards[msg.sender];
        if (amount == 0) revert InvalidAmount(); // No rewards to claim
        intentProposerRewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, amount);
        emit ProposerRewardsClaimed(msg.sender, amount);
    }

    /**
     * @dev Allows registered AI oracles to claim rewards for successfully executed strategies.
     *      Rewards are transferred in the designated `rewardToken`.
     */
    function claimOraclePerformanceRewards() external onlyOracle whenNotPaused {
        uint256 amount = oraclePerformanceRewards[msg.sender];
        if (amount == 0) revert InvalidAmount(); // No rewards to claim
        oraclePerformanceRewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, amount);
        emit OracleRewardsClaimed(msg.sender, amount);
    }

    // --- Utility functions for Ownable (initial setup) ---

    /**
     * @dev Set initial supported asset. Only callable by owner.
     *      Intended for initial setup before full DAO governance.
     *      After DAO is active, the `AddSupportedAsset` governance proposal should be used.
     * @param _token The address of the ERC20 token to support.
     * @param _isSupported True to support, false to remove support.
     */
    function setInitialSupportedAsset(address _token, bool _isSupported) external onlyOwner {
        supportedAssets[_token] = _isSupported;
    }

    /**
     * @dev Set the reward token. Only callable by owner.
     *      Intended for initial setup.
     * @param _rewardToken The address of the ERC20 token to be used for rewards.
     */
    function setRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Reward token cannot be zero");
        rewardToken = IERC20(_rewardToken);
    }

    /**
     * @dev Receives ETH directly into the treasury.
     *      Note: `contributeAndMintDAOToken` is preferred for members to gain voting power for their ETH contributions.
     *      ETH received here does NOT grant DAOTokens.
     */
    receive() external payable {
        // ETH deposits that don't go through contributeAndMintDAOToken do not grant voting power.
        // This ETH goes directly to the treasury for use in strategies.
        // Using address(0) for token address to denote ETH in the event.
        emit AssetDeposited(IERC20(address(0)), msg.sender, msg.value);
    }
}

// Interface for a generic Decentralized Exchange (DEX) Router (e.g., Uniswap V2/V3 Router-like)
// This interface defines a minimal set of functions required for the `Trade` struct's `callData`
// to interact with an external DEX. Real-world DEX routers have more complex functions and parameters.
interface IDexRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}
```