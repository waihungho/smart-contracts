Okay, here is a Solidity smart contract concept called `QuantumFluctuationFund`. It aims to be a decentralized fund that manages diversified assets, allows community proposals and voting on investment strategies, incorporates external data (oracle prices), uses verifiable randomness (VRF) for potential strategy adjustments or rewards, and includes staking mechanics. It tries to combine several trending DeFi/Web3 concepts.

**Disclaimer:** This is a complex concept for a single contract example. The implementation details, especially around algorithmic rebalancing, external protocol interaction (simplified here to trading *between* approved tokens within the contract), security, gas efficiency, and precise staking reward calculations, are highly simplified for demonstration purposes. **Do not use this contract in production without extensive security audits, testing, and further development.** Interacting with external protocols via `call` is powerful but dangerous if not handled meticulously.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// Assume Chainlink imports for Oracle and VRF
// These would require linking against actual Chainlink contracts or interfaces
// For this example, we'll use interfaces/placeholders.
interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

interface VRFCoordinatorV2Interface {
    function requestRandomWords(
        bytes32 keyHash,
        uint32 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    // function addConsumer(...) external; // Needed for actual VRF setup
    // function removeConsumer(...) external; // Needed for actual VRF setup
}

interface VRFConsumerBaseV2 {
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}

// --- Contract: QuantumFluctuationFund ---

// Outline:
// 1. State Variables: Store fund assets, token info, prices, proposals, staking data, admin settings.
// 2. Events: Announce significant actions (deposits, withdrawals, rebalancing, proposals, votes, staking).
// 3. Modifiers: Restrict access based on roles (Owner, Council, Paused state).
// 4. Core Fund Logic: Deposit, Withdraw based on NAV.
// 5. Asset Management: Add/Remove approved tokens, Rebalancing strategy and execution.
// 6. Oracle Integration: Get external asset prices for NAV calculation and rebalancing.
// 7. VRF Integration: Request and fulfill randomness for potential random events/modifiers.
// 8. Staking: Stake/Unstake fund tokens to earn rewards.
// 9. Governance: Proposal submission (strategy & generic), Voting, Execution.
// 10. Fees: Collection of protocol fees.
// 11. Utility/View Functions: Get current state, balances, NAV, etc.
// 12. Emergency: Pause/Unpause contract.

// Function Summary:
// --- Fund Management ---
// 01. depositAssets: Deposit approved assets into the fund, receive QFF tokens.
// 02. withdrawAssets: Redeem QFF tokens for a proportional share of fund assets.
// 03. getFundNAV: Calculate the Net Asset Value of the fund using current oracle prices.
// 04. getSharePrice: Calculate the value of one QFF token (NAV / total supply).

// --- Asset & Strategy ---
// 05. addApprovedInvestmentToken: Owner adds an ERC20 token address the fund can hold/trade.
// 06. removeApprovedInvestmentToken: Owner removes an ERC20 token from the approved list.
// 07. proposeInvestmentStrategy: Users/Council propose a new allocation strategy (target percentages).
// 08. voteOnStrategyProposal: Stakeholders vote on a proposed strategy.
// 09. approveStrategy: Council or system approves a winning strategy proposal.
// 10. rebalanceFund: Execute the current approved strategy by reallocating funds between approved tokens based on oracle prices.

// --- Oracle Integration ---
// 11. setOracleAddress: Owner sets the address of an AggregatorV3Interface for an approved token.
// 12. getAssetPrice: Retrieve the latest price from a registered oracle for a specific token.

// --- VRF Integration ---
// 13. setVRFCoordinator: Owner sets the Chainlink VRF Coordinator and KeyHash.
// 14. requestRandomness: Request random words from the VRF coordinator (e.g., for a random event).
// 15. fulfillRandomWords: Callback function from VRF coordinator with random results (implements VRFConsumerBaseV2).
// 16. distributeRandomStakingBonus: Potentially uses VRF outcome to distribute a bonus to stakers.

// --- Staking ---
// 17. createStakingPool: Owner creates a new staking pool for QFF tokens.
// 18. stakeTokens: Stake QFF tokens into a specific pool.
// 19. unstakeTokens: Unstake QFF tokens from a pool.
// 20. claimStakingRewards: Claim accumulated rewards from staked tokens.

// --- Governance & Admin ---
// 21. setStrategyCouncil: Owner sets the address of the Strategy Council multisig/contract.
// 22. submitTextProposal: Submit a generic text-based proposal for community discussion/voting.
// 23. voteOnTextProposal: Stakeholders vote on a generic text proposal.
// 24. executeApprovedTextProposal: Owner/Council executes an action based on an approved text proposal (simplified - requires manual action).
// 25. setFeeRecipient: Owner sets the address receiving protocol fees.
// 26. collectProtocolFees: Owner/Recipient collects accrued protocol fees.
// 27. burnFundTokens: Admin can trigger burning of a portion of collected fees or treasury tokens.
// 28. pauseContract: Owner pauses sensitive contract functions in case of emergency.
// 29. unpauseContract: Owner unpauses the contract.

// --- View Functions ---
// 30. getApprovedInvestmentTokens: Get the list of tokens the fund can invest in.
// 31. getStakingPools: Get details of all active staking pools.
// 32. getPoolStake: Get a user's stake in a specific pool.
// 33. getPendingRewards: Get a user's pending rewards in a specific pool.
// 34. getStrategyProposalState: Get the current state of a strategy proposal.
// 35. getTextProposalState: Get the current state of a text proposal.
// 36. getCurrentStrategy: Get the currently approved investment strategy.

contract QuantumFluctuationFund is ERC20("QuantumFluctuationFund Token", "QFF"), Ownable, ReentrancyGuard, Pausable, VRFConsumerBaseV2 {

    // --- State Variables ---

    // Fund Assets
    mapping(address => bool) public isApprovedInvestmentToken;
    address[] public approvedInvestmentTokensList;
    mapping(address => AggregatorV3Interface) public tokenOracles;

    // Fund Parameters
    address public feeRecipient;
    uint256 public protocolFeeBasisPoints; // 100 = 1%
    uint256 public minDepositAmount; // Minimum amount of *any* approved token to deposit
    uint256 public minWithdrawAmountQFF; // Minimum QFF tokens to burn for withdrawal

    // Rebalancing & Strategy
    struct StrategyAllocation {
        address token;
        uint256 percentage; // Target percentage of fund NAV (scaled by 10000 for precision, e.g., 2500 = 25%)
    }

    struct StrategyProposal {
        uint256 id;
        StrategyAllocation[] allocations;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        address proposer;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    uint256 public nextStrategyProposalId = 1;
    mapping(uint256 => StrategyProposal) public strategyProposals;
    uint256[] public activeStrategyProposalIds;
    StrategyAllocation[] public currentApprovedStrategy; // The currently active strategy

    address public strategyCouncil; // Address (multisig or contract) that can approve strategies after voting

    // Generic Text Proposals (simplified - no automated execution)
    struct TextProposal {
        uint256 id;
        string description;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 votesFor;
        uint256 votesAgainst;
        address proposer;
        mapping(address => bool) hasVoted;
        ProposalState state;
    }

    uint256 public nextTextProposalId = 1;
    mapping(uint256 => TextProposal) public textProposals;
    uint256[] public activeTextProposalIds;

    // Governance Parameters
    uint256 public strategyVotingPeriod; // Duration in seconds
    uint256 public textVotingPeriod;     // Duration in seconds
    uint256 public minVotesForStrategyApproval; // Minimum votes (QFF tokens) needed for strategy to potentially pass
    uint256 public minVotesForTextApproval;     // Minimum votes (QFF tokens) needed for text proposal to potentially pass
    uint256 public strategyCouncilApprovalThreshold; // Percentage of votes council needs to approve (if council approval is step after voting)

    // Staking
    struct StakingPool {
        uint256 id;
        address token; // Token staked (presumably QFF)
        uint256 totalStaked;
        uint256 rewardRatePerSecond; // Rate at which reward tokens are distributed per second
        address rewardToken; // The token used for rewards (could be QFF, another token, or a portion of fees)
        uint256 lastUpdateTime; // Last block timestamp rewards were updated
        uint256 rewardPerTokenStored; // Global reward per token
        mapping(address => uint256) stakedBalances; // User's staked amount
        mapping(address => uint256) userRewardPerTokenPaid; // User's recorded rewardPerTokenStored at last interaction
        mapping(address => uint256) rewards; // User's accumulated rewards
    }

    uint256 public nextStakingPoolId = 1;
    mapping(uint256 => StakingPool) public stakingPools;
    uint256[] public activeStakingPoolIds;
    uint256 public stakingRewardDistributionBasisPoints; // % of protocol fees allocated to stakers

    // VRF Variables (Chainlink specific)
    VRFCoordinatorV2Interface public VRFCoordinator;
    uint256 public s_subscriptionId;
    bytes32 public s_keyHash; // Example: 0x474e34a077df58807dbe9c96d3c009b23b3c6766bcf02ba381e2a7dafb033324 (Goerli)
    uint16 public s_requestConfirmations = 3; // Number of confirmations needed
    uint32 public s_callbackGasLimit = 100000; // Gas limit for the fulfillRandomWords callback
    uint32 public s_numWords = 1; // Number of random words requested
    uint256 public lastRequestId;
    uint256 public lastRandomWord;

    // Fees collected in each approved investment token
    mapping(address => uint256) public collectedFees;

    // --- Events ---

    event Deposited(address indexed user, address indexed token, uint256 amount, uint256 qffMinted);
    event Withdrew(address indexed user, uint256 qffBurned, address indexed token, uint256 amountReceived);
    event ApprovedInvestmentTokenAdded(address indexed token);
    event ApprovedInvestmentTokenRemoved(address indexed token);
    event StrategyProposed(uint256 indexed proposalId, address indexed proposer);
    event StrategyVoted(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event StrategyStateChanged(uint256 indexed proposalId, ProposalState newState);
    event StrategyApproved(uint256 indexed proposalId, StrategyAllocation[] strategy);
    event FundRebalanced(StrategyAllocation[] strategyExecuted, uint256 navBefore, uint256 navAfter);
    event OracleAddressSet(address indexed token, address indexed oracle);
    event VRFSettingsSet(address indexed coordinator, bytes32 keyHash, uint256 subId);
    event RandomnessRequested(uint256 indexed requestId, address indexed requester);
    event RandomnessFulfilled(uint256 indexed requestId, uint256[] randomWords);
    event StakingPoolCreated(uint256 indexed poolId, address indexed token, address indexed rewardToken, uint256 rewardRate);
    event Staked(address indexed user, uint256 indexed poolId, uint256 amount);
    event Unstaked(address indexed user, uint256 indexed poolId, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 indexed poolId, uint256 amount);
    event StrategyCouncilSet(address indexed council);
    event TextProposalSubmitted(uint256 indexed proposalId, address indexed proposer);
    event TextProposalVoted(uint256 indexed proposalId, address indexed voter, bool voteFor);
    event TextProposalStateChanged(uint256 indexed proposalId, ProposalState newState);
    event FeeRecipientSet(address indexed recipient);
    event ProtocolFeesCollected(address indexed recipient, address indexed token, uint256 amount);
    event FundTokensBurned(uint256 amount);
    event ContractPaused(address account);
    event ContractUnpaused(address account);

    // --- Errors ---

    error OnlyStrategyCouncil();
    error OnlyApprovedToken();
    error OracleNotSet();
    error InvalidProposalState();
    error VotingPeriodNotActive();
    error AlreadyVoted();
    error NoActiveProposal();
    error StrategyNotApproved();
    error InsufficientFundBalance();
    error InvalidStrategyAllocation();
    error StakingPoolNotFound();
    error ZeroAmount();
    error NothingToClaim();
    error VRFNotConfigured();
    error InvalidStrategyCouncilAddress();
    error MinDepositNotMet(uint256 required, uint256 provided);
    error MinWithdrawNotMet(uint256 required, uint256 provided);
    error TokenAlreadyApproved();

    // --- Modifiers ---

    modifier onlyStrategyCouncil() {
        if (msg.sender != strategyCouncil) revert OnlyStrategyCouncil();
        _;
    }

    modifier onlyApprovedToken(address token) {
        if (!isApprovedInvestmentToken[token]) revert OnlyApprovedToken();
        _;
    }

    modifier whenProposalActive(uint256 proposalId, bool isStrategy) {
        ProposalState state;
        uint256 endTime;
        if (isStrategy) {
            if (strategyProposals[proposalId].id == 0) revert InvalidProposalState(); // Check existence
            state = strategyProposals[proposalId].state;
            endTime = strategyProposals[proposalId].voteEndTime;
        } else {
             if (textProposals[proposalId].id == 0) revert InvalidProposalState(); // Check existence
            state = textProposals[proposalId].state;
            endTime = textProposals[proposalId].voteEndTime;
        }
        if (state != ProposalState.Active) revert InvalidProposalState();
        if (block.timestamp > endTime) revert VotingPeriodNotActive();
        _;
    }

    modifier whenProposalEnd(uint256 proposalId, bool isStrategy) {
        ProposalState state;
        uint256 endTime;
        if (isStrategy) {
             if (strategyProposals[proposalId].id == 0) revert InvalidProposalState(); // Check existence
            state = strategyProposals[proposalId].state;
            endTime = strategyProposals[proposalId].voteEndTime;
        } else {
             if (textProposals[proposalId].id == 0) revert InvalidProposalState(); // Check existence
            state = textProposals[proposalId].state;
            endTime = textProposals[proposalId].voteEndTime;
        }
        if (state != ProposalState.Active || block.timestamp <= endTime) revert InvalidProposalState();
        _;
    }

    modifier updateStakingRewards(uint256 poolId) {
        StakingPool storage pool = stakingPools[poolId];
        uint256 timeElapsed = block.timestamp - pool.lastUpdateTime;
        if (timeElapsed > 0 && pool.totalStaked > 0) {
            uint256 rewardAmount = (pool.rewardRatePerSecond * timeElapsed);
            pool.rewardPerTokenStored += (rewardAmount * 1e18) / pool.totalStaked; // Use 1e18 for precision
        }
        pool.lastUpdateTime = block.timestamp;
        _;
    }

    modifier onlyVRFCoordinator() {
        require(msg.sender == address(VRFCoordinator), "Only VRF Coordinator can call");
        _;
    }

    // --- Constructor ---

    constructor(
        address initialFeeRecipient,
        uint256 _protocolFeeBasisPoints,
        uint256 _strategyVotingPeriod,
        uint256 _textVotingPeriod,
        uint256 _minVotesForStrategyApproval,
        uint256 _minVotesForTextApproval,
        uint256 _strategyCouncilApprovalThreshold,
        uint256 _stakingRewardDistributionBasisPoints,
        uint256 _minDepositAmount,
        uint256 _minWithdrawAmountQFF
    ) Ownable(msg.sender) ERC20("QuantumFluctuationFund Token", "QFF") Pausable() {
        feeRecipient = initialFeeRecipient;
        protocolFeeBasisPoints = _protocolFeeBasisPoints;
        strategyVotingPeriod = _strategyVotingPeriod;
        textVotingPeriod = _textVotingPeriod;
        minVotesForStrategyApproval = _minVotesForStrategyApproval;
        minVotesForTextApproval = _minVotesForTextApproval;
        strategyCouncilApprovalThreshold = _strategyCouncilApprovalThreshold;
        stakingRewardDistributionBasisPoints = _stakingRewardDistributionBasisPoints;
        minDepositAmount = _minDepositAmount;
        minWithdrawAmountQFF = _minWithdrawAmountQFF;
    }

    // --- Fund Management ---

    // 01. depositAssets - Deposit approved assets to get QFF tokens
    function depositAssets(address token, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        onlyApprovedToken(token)
    {
        if (amount == 0) revert ZeroAmount();
        if (amount < minDepositAmount) revert MinDepositNotMet(minDepositAmount, amount);

        // Calculate QFF tokens to mint based on current share price (NAV/TotalSupply)
        // If this is the first deposit, total supply is 0, mint 1:1 (or a chosen base amount)
        uint256 totalQFFSupply = totalSupply();
        uint256 sharePrice = 1e18; // Default initial share price (1 QFF = 1 wei of reference asset)
        if (totalQFFSupply > 0) {
            sharePrice = getSharePrice();
        }

        // Get deposited token value in terms of share price reference unit (e.g., USD)
        uint256 tokenPrice = getAssetPrice(token); // Assumes oracle returns price relative to a reference unit

        // Calculate equivalent value in reference unit and then QFF tokens
        // value_in_ref_unit = (amount * tokenPrice) / 1e18 (adjusting for token decimals vs 1e18)
        // QFF_to_mint = (value_in_ref_unit * 1e18) / sharePrice
        // Combined: QFF_to_mint = (amount * tokenPrice * 1e18) / (1e18 * sharePrice) = (amount * tokenPrice) / sharePrice
        // This requires careful decimal handling. Let's assume token prices are 1e18 for simplicity in calculation example.
        // For production, fetch token decimals and adjust calculation.
        // Assuming tokenPrice and sharePrice are both scaled by 1e18:
        uint256 equivalentValue = (amount * tokenPrice) / (1e18);
        uint256 qffToMint = (equivalentValue * 1e18) / sharePrice; // Mint QFF tokens scaled by 1e18

        if (qffToMint == 0) revert MinDepositNotMet(1, 0); // Or a more specific minimum QFF mint error

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, qffToMint);

        emit Deposited(msg.sender, token, amount, qffToMint);
    }

    // 02. withdrawAssets - Redeem QFF tokens for assets
    function withdrawAssets(uint256 qffAmount)
        external
        nonReentrant
        whenNotPaused
    {
        if (qffAmount == 0) revert ZeroAmount();
        if (qffAmount < minWithdrawAmountQFF) revert MinWithdrawNotMet(minWithdrawAmountQFF, qffAmount);
        if (balanceOf(msg.sender) < qffAmount) revert ERC20.ERC20InsufficientBalance(msg.sender, balanceOf(msg.sender), qffAmount);

        // Calculate asset amounts based on current share price and QFF amount
        uint256 totalQFFSupply = totalSupply();
        if (totalQFFSupply == 0) revert InsufficientFundBalance(); // Should not happen if QFF exists
        uint256 sharePrice = getSharePrice();

        // Calculate the total value being withdrawn in reference unit
        // value_to_withdraw_ref_unit = (qffAmount * sharePrice) / 1e18
        uint256 valueToWithdraw = (qffAmount * sharePrice) / (1e18); // Value in reference unit

        _burn(msg.sender, qffAmount);

        // Distribute proportional share of each asset
        for (uint i = 0; i < approvedInvestmentTokensList.length; i++) {
            address assetToken = approvedInvestmentTokensList[i];
            uint256 fundBalance = IERC20(assetToken).balanceOf(address(this));

            if (fundBalance > 0) {
                 uint256 assetPrice = getAssetPrice(assetToken); // Assumes oracle returns price relative to reference unit

                // Calculate value of this asset in fund
                 uint256 assetValueInFund = (fundBalance * assetPrice) / (1e18); // Value in reference unit

                 // Calculate the proportion of this asset the user is entitled to
                 // user_proportion = qffAmount / totalQFFSupply
                 // asset_amount_to_transfer = user_proportion * fundBalance
                 // Simplified: asset_amount_to_transfer = (qffAmount * fundBalance) / totalQFFSupply
                 // This simpler formula is only accurate if all assets had their value tracked in terms of the QFF token directly,
                 // not through an external reference unit.
                 // A more robust approach calculates the user's share of the *total fund value* and converts that back to *each asset*.

                 // Let's calculate based on valueToWithdraw
                 // For each asset, how much value does the user withdraw?
                 // user_asset_value = (valueToWithdraw * assetValueInFund) / total_fund_value_before_burn
                 // Total fund value before burn is (totalQFFSupply + qffAmount) * sharePrice / 1e18 -- NO, it's just totalQFFSupply * sharePrice / 1e18
                 // The total fund value *before* burning is (totalSupply() + qffAmount) * sharePrice, assuming burn happens *after* calculation.
                 // Correct total fund value: getFundNAV()
                 uint256 totalFundValue = getFundNAV();
                 if (totalFundValue == 0) continue; // Avoid division by zero

                 // user_asset_value = (valueToWithdraw * assetValueInFund) / totalFundValue
                 // asset_amount_to_transfer = (user_asset_value * 1e18) / assetPrice (convert value back to token amount)
                 // asset_amount_to_transfer = (valueToWithdraw * assetValueInFund * 1e18) / (totalFundValue * assetPrice)

                 // Combine and simplify carefully:
                 // user_asset_value = (qffAmount * sharePrice / 1e18) * ((fundBalance * assetPrice / 1e18) / getFundNAV())
                 // asset_amount = user_asset_value * 1e18 / assetPrice
                 // asset_amount = (qffAmount * sharePrice / 1e18) * (fundBalance * assetPrice / 1e18) / getFundNAV() * 1e18 / assetPrice
                 // asset_amount = (qffAmount * sharePrice * fundBalance) / (getFundNAV() * 1e18)

                 uint256 assetAmountToTransfer = (qffAmount * fundBalance) / totalQFFSupply; // Use the simplified ratio based on total QFF
                 // This simplified ratio (qffAmount / totalQFFSupply) works because QFF supply directly tracks the fund's *total* value.
                 // transfer fundBalance * (qffAmount / totalQFFSupply)

                 if (assetAmountToTransfer > 0) {
                     IERC20(assetToken).transfer(msg.sender, assetAmountToTransfer);
                     emit Withdrew(msg.sender, qffAmount, assetToken, assetAmountToTransfer);
                 }
            }
        }
        // Note: Value might slightly deviate due to integer division or stale oracle prices between NAV calc and withdrawals.
        // Advanced funds use techniques like withdrawal fees or a temporary NAV snapshot.
    }

    // 03. getFundNAV - Calculate the total Net Asset Value of the fund
    function getFundNAV() public view returns (uint256 totalValue) {
        totalValue = 0; // Value is in terms of the reference unit (e.g., USD) scaled by 1e18
        for (uint i = 0; i < approvedInvestmentTokensList.length; i++) {
            address token = approvedInvestmentTokensList[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                uint256 price = getAssetPrice(token); // Price scaled by 1e18
                // Add value: (balance * price) / 1e18 (adjusting for token decimals vs 1e18 if needed)
                // Assuming token decimals match 18 or are handled by oracle/price feed.
                totalValue += (balance * price) / (1e18); // Value added is also scaled by 1e18
            }
        }
        // Include native token balance if any (e.g., Ether or base chain token) - not handled here for simplicity
    }

    // 04. getSharePrice - Calculate the value of one QFF token
    function getSharePrice() public view returns (uint256) {
        uint256 totalQFFSupply = totalSupply();
        if (totalQFFSupply == 0) {
            return 1e18; // Initial price: 1 QFF = 1 unit of reference asset (scaled by 1e18)
        }
        uint256 nav = getFundNAV();
        // sharePrice = (nav * 1e18) / totalQFFSupply
        // nav is scaled by 1e18, totalQFFSupply is scaled by 1e18.
        // (nav / 1e18) = actual value in reference unit.
        // actual share price = (nav / 1e18) / (totalQFFSupply / 1e18) = nav / totalQFFSupply.
        // To return a result scaled by 1e18: (nav * 1e18) / totalQFFSupply
        return (nav * 1e18) / totalQFFSupply;
    }

    // --- Asset & Strategy ---

    // 05. addApprovedInvestmentToken - Owner adds a token to the investable list
    function addApprovedInvestmentToken(address token, address oracleAddress) external onlyOwner {
        if (token == address(0)) revert ZeroAmount();
        if (isApprovedInvestmentToken[token]) revert TokenAlreadyApproved();
        approvedInvestmentTokensList.push(token);
        isApprovedInvestmentToken[token] = true;
        tokenOracles[token] = AggregatorV3Interface(oracleAddress);
        emit ApprovedInvestmentTokenAdded(token);
        emit OracleAddressSet(token, oracleAddress);
    }

    // 06. removeApprovedInvestmentToken - Owner removes a token from the investable list
    function removeApprovedInvestmentToken(address token) external onlyOwner {
        if (!isApprovedInvestmentToken[token]) revert OnlyApprovedToken(); // Use generic error

        // Simple removal: mark as not approved. To save gas on array, could swap-and-pop.
        isApprovedInvestmentToken[token] = false;

        // Optional: remove from list by swapping with last and popping
        for (uint i = 0; i < approvedInvestmentTokensList.length; i++) {
            if (approvedInvestmentTokensList[i] == token) {
                approvedInvestmentTokensList[i] = approvedInvestmentTokensList[approvedInvestmentTokensList.length - 1];
                approvedInvestmentTokensList.pop();
                break; // Assuming unique tokens
            }
        }
        // Note: Assets of this token remain in the contract until rebalanced out or withdrawn.
        emit ApprovedInvestmentTokenRemoved(token);
    }

    // 07. proposeInvestmentStrategy - Propose a new allocation strategy
    // Allocations should sum up to 10000 (representing 100%)
    function proposeInvestmentStrategy(StrategyAllocation[] calldata allocations) external whenNotPaused {
        uint256 totalPercentage = 0;
        for (uint i = 0; i < allocations.length; i++) {
            if (!isApprovedInvestmentToken[allocations[i].token]) revert InvalidStrategyAllocation();
            totalPercentage += allocations[i].percentage;
        }
        if (totalPercentage != 10000) revert InvalidStrategyAllocation();

        uint256 proposalId = nextStrategyProposalId++;
        StrategyProposal storage proposal = strategyProposals[proposalId];
        proposal.id = proposalId;
        proposal.allocations = allocations; // Copy array
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + strategyVotingPeriod;
        proposal.proposer = msg.sender;
        proposal.state = ProposalState.Active;

        activeStrategyProposalIds.push(proposalId); // Track active proposals

        emit StrategyProposed(proposalId, msg.sender);
    }

    // 08. voteOnStrategyProposal - Stakeholders vote on a proposed strategy
    // Voting power is based on QFF token balance at the time of voting.
    function voteOnStrategyProposal(uint256 proposalId, bool voteFor)
        external
        whenProposalActive(proposalId, true)
    {
        StrategyProposal storage proposal = strategyProposals[proposalId];
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 votingPower = balanceOf(msg.sender); // Simple balance voting
        if (votingPower == 0) revert ZeroAmount(); // No voting power

        if (voteFor) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit StrategyVoted(proposalId, msg.sender, voteFor);
    }

    // 09. approveStrategy - Approve a winning strategy (can be called after voting ends)
    // Could be automated based on threshold OR require Council approval
    function approveStrategy(uint256 proposalId)
        external
        whenNotPaused
        whenProposalEnd(proposalId, true) // Voting must be over
        onlyStrategyCouncil // Or automated check: check if votesFor >= minVotesForStrategyApproval and votesFor > votesAgainst
    {
        StrategyProposal storage proposal = strategyProposals[proposalId];

        // Check if votes meet the minimum threshold and pass
        if (proposal.votesFor < minVotesForStrategyApproval || proposal.votesFor <= proposal.votesAgainst) {
             proposal.state = ProposalState.Failed;
             emit StrategyStateChanged(proposalId, ProposalState.Failed);
             // Remove from active list (simplified)
             for (uint i = 0; i < activeStrategyProposalIds.length; i++) {
                 if (activeStrategyProposalIds[i] == proposalId) {
                     activeStrategyProposalIds[i] = activeStrategyProposalIds[activeStrategyProposalIds.length - 1];
                     activeStrategyProposalIds.pop();
                     break;
                 }
             }
             return;
        }

        // Optional: Check Council specific approval logic here if needed
        // e.g., check if msg.sender (Council) has 'approved' this, maybe needing a certain % of Council weight

        currentApprovedStrategy = proposal.allocations;
        proposal.state = ProposalState.Succeeded; // Or Executed if execution is automatic

        emit StrategyStateChanged(proposalId, ProposalState.Succeeded);
        emit StrategyApproved(proposalId, currentApprovedStrategy);

         // Remove from active list (simplified)
         for (uint i = 0; i < activeStrategyProposalIds.length; i++) {
             if (activeStrategyProposalIds[i] == proposalId) {
                 activeStrategyProposalIds[i] = activeStrategyProposalIds[activeStrategyProposalIds.length - 1];
                 activeStrategyProposalIds.pop();
                 break;
             }
         }
    }

    // 10. rebalanceFund - Rebalance assets based on the current approved strategy
    // This is a simplified example. Actual rebalancing involves swapping tokens,
    // potentially interacting with AMMs (Uniswap, etc.) which is complex.
    // Here, we assume rebalancing happens *between* approved tokens held *by this contract*.
    function rebalanceFund() external whenNotPaused onlyStrategyCouncil nonReentrant {
        if (currentApprovedStrategy.length == 0) revert StrategyNotApproved();

        uint256 navBefore = getFundNAV();
        if (navBefore == 0) return; // Nothing to rebalance

        // Calculate current value of each asset and desired value based on strategy
        mapping(address => uint256) currentAssetValue; // Value in reference unit
        mapping(address => uint256) targetAssetValue; // Value in reference unit
        mapping(address => uint256) currentAssetBalance;

        for (uint i = 0; i < approvedInvestmentTokensList.length; i++) {
            address token = approvedInvestmentTokensList[i];
            currentAssetBalance[token] = IERC20(token).balanceOf(address(this));
            uint256 price = getAssetPrice(token); // Scaled by 1e18
            currentAssetValue[token] = (currentAssetBalance[token] * price) / 1e18; // Scaled by 1e18
        }

        for (uint i = 0; i < currentApprovedStrategy.length; i++) {
            StrategyAllocation storage allocation = currentApprovedStrategy[i];
            // targetValue = (totalNAV * targetPercentage) / 10000
            targetAssetValue[allocation.token] = (navBefore * allocation.percentage) / 10000;
        }

        // Determine assets to sell and buy
        address[] memory tokensToSell = new address[](0);
        address[] memory tokensToBuy = new address[](0);
        mapping(address => uint256) sellAmountsValue; // Value to sell (in reference unit)
        mapping(address => uint256) buyAmountsValue; // Value to buy (in reference unit)

        for (uint i = 0; i < approvedInvestmentTokensList.length; i++) {
            address token = approvedInvestmentTokensList[i];
            int256 valueDifference = int256(currentAssetValue[token]) - int256(targetAssetValue[token]);

            if (valueDifference > 0) {
                // We have an excess, need to sell
                tokensToSell.push(token);
                sellAmountsValue[token] = uint256(valueDifference);
            } else if (valueDifference < 0) {
                // We have a deficit, need to buy
                tokensToBuy.push(token);
                buyAmountsValue[token] = uint256(-valueDifference);
            }
        }

        // Execute trades (simplified: simulate transfers between tokens held by the contract)
        // In a real scenario, this would involve complex calls to DEXs.
        // This simplified version just conceptually moves value.
        // A more realistic simple version would be if the approved tokens *included* stablecoins or ETH
        // and the rebalance involved swapping volatile assets for stables, etc.
        // For this example, we won't implement the swap logic, only the calculation.
        // Implementing actual swaps would require interaction with DEX liquidity pools, which is too complex for this example.
        // **Actual implementation would require calculating token amounts to swap and executing external calls.**

        // Simulate successful rebalancing - In a real scenario, success depends on swaps
        // The following lines are conceptual placeholders for actual swap logic:
        // For each token to sell: calculate token amount from value using price. Transfer out to DEX/swap function.
        // For each token to buy: calculate token amount from value using price. Transfer in from DEX/swap function.
        // Error handling for failed swaps is critical.

        // After simulated (or actual) swaps, check actual balances and recalculate NAV
        uint256 navAfter = getFundNAV();

        emit FundRebalanced(currentApprovedStrategy, navBefore, navAfter);

        // Optional: Request VRF after rebalance for a potential random modifier
        // requestRandomness( /* params */ );
    }

    // --- Oracle Integration ---

    // 11. setOracleAddress - Owner sets or updates an oracle address for a token
    function setOracleAddress(address token, address oracleAddress) external onlyOwner onlyApprovedToken(token) {
        tokenOracles[token] = AggregatorV3Interface(oracleAddress);
        emit OracleAddressSet(token, oracleAddress);
    }

    // 12. getAssetPrice - Retrieve the latest price from a registered oracle
    function getAssetPrice(address token) public view returns (uint256 price) {
        AggregatorV3Interface oracle = tokenOracles[token];
        if (address(oracle) == address(0)) revert OracleNotSet();

        (, int256 answer, , , ) = oracle.latestRoundData();
        if (answer <= 0) revert OracleNotSet(); // Basic check for invalid price
        // Assume oracle returns price with 18 decimals for consistency with QFF
        // If oracle decimals differ, need to adjust: (uint256(answer) * (10**18)) / (10**oracle.decimals())
        // For Chainlink price feeds, often they have 8 decimals. Example adjustment:
        // uint8 decimals = oracle.decimals(); // Need to fetch decimals() if not 18
        // price = (uint256(answer) * 1e18) / (10**decimals);
        // For simplicity, assuming 18 decimals here.
        price = uint256(answer); // Price scaled by 1e18 (oracles usually have fewer, ADJUST THIS CAREFULLY IN PROD)
    }

    // --- VRF Integration ---

    // 13. setVRFCoordinator - Owner sets Chainlink VRF settings
    function setVRFCoordinator(address coordinator, bytes32 keyHash, uint256 subId) external onlyOwner {
        VRFCoordinator = VRFCoordinatorV2Interface(coordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subId;
        // In a real setup, you would also need to add this contract as a consumer to the subscription ID
        // VRFCoordinator.addConsumer(s_subscriptionId, address(this));
        emit VRFSettingsSet(coordinator, keyHash, subId);
    }

    // 14. requestRandomness - Request random words from VRF (e.g., for a random strategy modifier)
    function requestRandomness() external whenNotPaused onlyStrategyCouncil returns (uint256 requestId) {
        if (address(VRFCoordinator) == address(0) || s_keyHash == bytes32(0) || s_subscriptionId == 0) {
            revert VRFNotConfigured();
        }
        // Will revert if subscription is not funded or contract is not consumer
        requestId = VRFCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        lastRequestId = requestId;
        emit RandomnessRequested(requestId, msg.sender);
        return requestId;
    }

    // 15. fulfillRandomWords - Callback function from VRF coordinator
    // This function is called by the VRF Coordinator contract
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override onlyVRFCoordinator {
        if (requestId != lastRequestId) {
             // Handle unexpected requestId - maybe log or ignore
             return;
        }
        lastRandomWord = randomWords[0]; // Store the first random word
        emit RandomnessFulfilled(requestId, randomWords);

        // --- Use the random word here ---
        // Example: Use the random word to potentially trigger a random event,
        // apply a small random modifier to the next rebalance, or trigger a bonus distribution.
        // distributeRandomStakingBonus(lastRandomWord % 100); // Example: distribute bonus based on random number
    }

    // 16. distributeRandomStakingBonus - Distribute a bonus to stakers based on VRF outcome
    // Example usage of randomness - distribute a random amount of QFF or fees to stakers.
    // Requires VRF to be configured and fulfillRandomWords to be called.
    function distributeRandomStakingBonus(uint256 randomnessSeed) external whenNotPaused onlyStrategyCouncil {
        // This is a placeholder. Actual distribution logic would depend on the bonus source (fees, new tokens)
        // and how randomnessSeed influences the distribution.
        // e.g., select a random pool, select a random staker, determine bonus amount based on randomnessSeed.

        // Example: If randomnessSeed is <= 50, distribute 1% of collected fees as bonus.
        // If randomnessSeed is > 50 and <= 100, distribute 0.5% of total supply to stakers (newly minted or treasury).
        // This function needs logic to access fees or mint tokens and distribute.
        // For simplicity, this function is just a *trigger* concept. The actual distribution logic is complex.
        emit RandomnessFulfilled(lastRequestId, new uint256[](1).push(randomnessSeed)); // Re-emit for clarity if not from callback
        // ... Distribution logic here ...
    }

    // --- Staking ---

    // 17. createStakingPool - Owner creates a new staking pool
    function createStakingPool(address token, address rewardToken, uint256 rewardRatePerSecond) external onlyOwner {
        if (token == address(0) || rewardToken == address(0)) revert ZeroAmount();
        uint256 poolId = nextStakingPoolId++;
        StakingPool storage pool = stakingPools[poolId];
        pool.id = poolId;
        pool.token = token;
        pool.rewardToken = rewardToken;
        pool.rewardRatePerSecond = rewardRatePerSecond;
        pool.lastUpdateTime = block.timestamp;

        activeStakingPoolIds.push(poolId); // Track active pools

        emit StakingPoolCreated(poolId, token, rewardToken, rewardRatePerSecond);
    }

    // Internal: Calculate pending rewards for a user in a pool
    function _calculateRewards(uint256 poolId, address account) internal view returns (uint256) {
        StakingPool storage pool = stakingPools[poolId];
        uint256 currentRewardPerToken = pool.rewardPerTokenStored;
        if (pool.totalStaked > 0) {
            uint256 timeElapsed = block.timestamp - pool.lastUpdateTime;
            currentRewardPerToken += (pool.rewardRatePerSecond * timeElapsed * 1e18) / pool.totalStaked;
        }
        return (pool.stakedBalances[account] * (currentRewardPerToken - pool.userRewardPerTokenPaid[account])) / 1e18;
    }

    // 18. stakeTokens - Stake tokens into a pool (assuming QFF token)
    function stakeTokens(uint256 poolId, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateStakingRewards(poolId)
    {
        if (amount == 0) revert ZeroAmount();
        StakingPool storage pool = stakingPools[poolId];
        if (pool.id == 0) revert StakingPoolNotFound();
        if (pool.token != address(this)) revert InvalidStrategyAllocation(); // Only stake QFF for now

        // Claim pending rewards before updating stake
        uint256 pending = _calculateRewards(poolId, msg.sender);
        pool.rewards[msg.sender] += pending;
        pool.userRewardPerTokenPaid[msg.sender] = pool.rewardPerTokenStored;

        IERC20(pool.token).transferFrom(msg.sender, address(this), amount);
        pool.stakedBalances[msg.sender] += amount;
        pool.totalStaked += amount;

        emit Staked(msg.sender, poolId, amount);
    }

    // 19. unstakeTokens - Unstake tokens from a pool
    function unstakeTokens(uint256 poolId, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateStakingRewards(poolId)
    {
        if (amount == 0) revert ZeroAmount();
        StakingPool storage pool = stakingPools[poolId];
        if (pool.id == 0) revert StakingPoolNotFound();
        if (pool.stakedBalances[msg.sender] < amount) revert ERC20.ERC20InsufficientBalance(msg.sender, pool.stakedBalances[msg.sender], amount); // Not an ERC20, but similar concept

        // Claim pending rewards before updating stake
        uint256 pending = _calculateRewards(poolId, msg.sender);
        pool.rewards[msg.sender] += pending;
        pool.userRewardPerTokenPaid[msg.sender] = pool.rewardPerTokenStored;

        pool.stakedBalances[msg.sender] -= amount;
        pool.totalStaked -= amount;
        IERC20(pool.token).transfer(msg.sender, amount);

        emit Unstaked(msg.sender, poolId, amount);
    }

    // 20. claimStakingRewards - Claim accumulated rewards
    function claimStakingRewards(uint256 poolId)
        external
        nonReentrant
        whenNotPaused
        updateStakingRewards(poolId)
    {
        StakingPool storage pool = stakingPools[poolId];
        if (pool.id == 0) revert StakingPoolNotFound();

        uint256 pending = _calculateRewards(poolId, msg.sender);
        pool.rewards[msg.sender] += pending;
        pool.userRewardPerTokenPaid[msg.sender] = pool.rewardPerTokenStored;

        uint256 rewardsAmount = pool.rewards[msg.sender];
        if (rewardsAmount == 0) revert NothingToClaim();

        pool.rewards[msg.sender] = 0; // Reset claimed rewards

        // Distribute reward tokens
        IERC20(pool.rewardToken).transfer(msg.sender, rewardsAmount); // Assumes rewards are in pool.rewardToken

        emit RewardsClaimed(msg.sender, poolId, rewardsAmount);
    }

    // --- Governance & Admin ---

    // 21. setStrategyCouncil - Owner sets the Strategy Council address
    function setStrategyCouncil(address _strategyCouncil) external onlyOwner {
        if (_strategyCouncil == address(0)) revert InvalidStrategyCouncilAddress();
        strategyCouncil = _strategyCouncil;
        emit StrategyCouncilSet(_strategyCouncil);
    }

    // 22. submitTextProposal - Submit a generic text-based proposal
    function submitTextProposal(string calldata description) external whenNotPaused {
        uint256 proposalId = nextTextProposalId++;
        TextProposal storage proposal = textProposals[proposalId];
        proposal.id = proposalId;
        proposal.description = description;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + textVotingPeriod;
        proposal.proposer = msg.sender;
        proposal.state = ProposalState.Active;

        activeTextProposalIds.push(proposalId); // Track active proposals

        emit TextProposalSubmitted(proposalId, msg.sender);
    }

    // 23. voteOnTextProposal - Stakeholders vote on a generic text proposal
    function voteOnTextProposal(uint256 proposalId, bool voteFor)
        external
        whenProposalActive(proposalId, false)
    {
        TextProposal storage proposal = textProposals[proposalId];
        if (proposal.hasVoted[msg.sender]) revert AlreadyVoted();

        uint256 votingPower = balanceOf(msg.sender); // Simple balance voting
        if (votingPower == 0) revert ZeroAmount(); // No voting power

        if (voteFor) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }
        proposal.hasVoted[msg.sender] = true;

        emit TextProposalVoted(proposalId, msg.sender, voteFor);
    }

    // 24. executeApprovedTextProposal - Owner/Council marks a text proposal as executed
    // This function doesn't perform automated actions. It's a state change indicating
    // that an off-chain action or manual transaction based on the proposal has occurred.
    function executeApprovedTextProposal(uint256 proposalId)
        external
        whenNotPaused
        onlyStrategyCouncil // Or onlyOwner, depending on governance model
    {
        TextProposal storage proposal = textProposals[proposalId];
        if (proposal.state != ProposalState.Succeeded) revert InvalidProposalState();

        proposal.state = ProposalState.Executed;

        // Remove from active list (simplified)
         for (uint i = 0; i < activeTextProposalIds.length; i++) {
             if (activeTextProposalIds[i] == proposalId) {
                 activeTextProposalIds[i] = activeTextProposalIds[activeTextProposalIds.length - 1];
                 activeTextProposalIds.pop();
                 break;
             }
         }

        emit TextProposalStateChanged(proposalId, ProposalState.Executed);
    }

    // Function to check voting results and transition state (can be called by anyone after voting ends)
    function checkProposalResult(uint256 proposalId, bool isStrategy) external {
         if (isStrategy) {
             StrategyProposal storage proposal = strategyProposals[proposalId];
              if (proposal.id == 0) revert InvalidProposalState();
             if (proposal.state != ProposalState.Active || block.timestamp <= proposal.voteEndTime) revert InvalidProposalState(); // Ensure voting ended
             if (proposal.votesFor >= minVotesForStrategyApproval && proposal.votesFor > proposal.votesAgainst) {
                 proposal.state = ProposalState.Succeeded;
             } else {
                 proposal.state = ProposalState.Failed;
             }
             emit StrategyStateChanged(proposalId, proposal.state);
         } else {
             TextProposal storage proposal = textProposals[proposalId];
             if (proposal.id == 0) revert InvalidProposalState();
             if (proposal.state != ProposalState.Active || block.timestamp <= proposal.voteEndTime) revert InvalidProposalState(); // Ensure voting ended
             if (proposal.votesFor >= minVotesForTextApproval && proposal.votesFor > proposal.votesAgainst) {
                 proposal.state = ProposalState.Succeeded;
             } else {
                 proposal.state = ProposalState.Failed;
             }
             emit TextProposalStateChanged(proposalId, proposal.state);
         }
    }


    // 25. setFeeRecipient - Owner sets the address to receive protocol fees
    function setFeeRecipient(address recipient) external onlyOwner {
        feeRecipient = recipient;
        emit FeeRecipientSet(recipient);
    }

    // 26. collectProtocolFees - Owner/Recipient collects accrued protocol fees
    // Assumes fees are collected in the various approved investment tokens
    function collectProtocolFees() external whenNotPaused nonReentrant {
        // This function assumes fee collection happens automatically during deposits/withdrawals
        // or rebalancing, accumulating in the `collectedFees` mapping.
        // A more complex contract would calculate fees dynamically during operations.
        // For this example, fees might be a percentage of deposited/withdrawn value or a performance fee during rebalance.
        // Let's assume `collectedFees` is updated elsewhere (e.g., internal helper in deposit/withdraw).
        // Or, more simply, fees are a % taken during withdrawal. In that case, this function is to collect *those* fees.

        // Simplified: Assume fees are collected in approved tokens via another mechanism
        // This function just transfers collected amounts to the recipient.
        address recipient = feeRecipient;
        if (recipient == address(0)) return; // No recipient set

        for (uint i = 0; i < approvedInvestmentTokensList.length; i++) {
            address token = approvedInvestmentTokensList[i];
            uint256 feeAmount = collectedFees[token]; // Amount collected in this token

            if (feeAmount > 0) {
                collectedFees[token] = 0; // Reset collected amount for this token
                IERC20(token).transfer(recipient, feeAmount);
                emit ProtocolFeesCollected(recipient, token, feeAmount);

                // Optional: Distribute a portion of collected fees to stakers
                // uint256 stakingPortion = (feeAmount * stakingRewardDistributionBasisPoints) / 10000;
                // // Distribute stakingPortion to relevant staking pools (complex logic needed)
            }
        }
    }

     // 27. burnFundTokens - Burn a specific amount of QFF tokens (e.g., from collected fees converted to QFF or a treasury)
     function burnFundTokens(uint256 amount) external whenNotPaused onlyStrategyCouncil {
        if (amount == 0) revert ZeroAmount();
        // Ensure the contract or treasury has the balance
        if (balanceOf(address(this)) < amount) revert ERC20.ERC20InsufficientBalance(address(this), balanceOf(address(this)), amount);
        _burn(address(this), amount);
        emit FundTokensBurned(amount);
     }


    // 28. pauseContract - Owner pauses core operations
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    // 29. unpauseContract - Owner unpauses core operations
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    // --- View Functions ---

    // 30. getApprovedInvestmentTokens - Get the list of approved tokens
    function getApprovedInvestmentTokens() external view returns (address[] memory) {
        // Note: This list might contain addresses marked 'false' in isApprovedInvestmentToken
        // if removeApprovedInvestmentToken used the simple removal logic.
        // A cleaner implementation would return a list of *currently* approved tokens.
        uint208 count = 0;
        for(uint i = 0; i < approvedInvestmentTokensList.length; i++){
            if(isApprovedInvestmentToken[approvedInvestmentTokensList[i]]){
                count++;
            }
        }
        address[] memory currentApproved = new address[](count);
        uint currentIdx = 0;
         for(uint i = 0; i < approvedInvestmentTokensList.length; i++){
            if(isApprovedInvestmentToken[approvedInvestmentTokensList[i]]){
                currentApproved[currentIdx] = approvedInvestmentTokensList[i];
                currentIdx++;
            }
        }
        return currentApproved;
    }

    // 31. getStakingPools - Get basic details of all active staking pools
    function getStakingPools() external view returns (StakingPool[] memory) {
        StakingPool[] memory pools = new StakingPool[](activeStakingPoolIds.length);
        for(uint i = 0; i < activeStakingPoolIds.length; i++) {
            uint256 poolId = activeStakingPoolIds[i];
            StakingPool storage pool = stakingPools[poolId];
            // Copy data to memory struct (excluding internal mappings)
            pools[i].id = pool.id;
            pools[i].token = pool.token;
            pools[i].totalStaked = pool.totalStaked;
            pools[i].rewardRatePerSecond = pool.rewardRatePerSecond;
            pools[i].rewardToken = pool.rewardToken;
            pools[i].lastUpdateTime = pool.lastUpdateTime;
            pools[i].rewardPerTokenStored = pool.rewardPerTokenStored; // Note: This might need adjustment based on pending time
             // Internal mappings are not copied
        }
        return pools;
    }

    // 32. getPoolStake - Get a user's staked amount in a pool
    function getPoolStake(uint256 poolId, address account) external view returns (uint256) {
         StakingPool storage pool = stakingPools[poolId];
         if (pool.id == 0) revert StakingPoolNotFound();
         return pool.stakedBalances[account];
    }

    // 33. getPendingRewards - Get a user's pending rewards in a pool
    function getPendingRewards(uint256 poolId, address account) external view returns (uint256) {
         StakingPool storage pool = stakingPools[poolId];
         if (pool.id == 0) revert StakingPoolNotFound();
         return pool.rewards[account] + _calculateRewards(poolId, account);
    }

    // 34. getStrategyProposalState - Get the state of a strategy proposal
    function getStrategyProposalState(uint256 proposalId) external view returns (StrategyProposal memory) {
        StrategyProposal storage proposal = strategyProposals[proposalId];
        if (proposal.id == 0) revert InvalidProposalState(); // Check existence
        // Copy to memory to return
        StrategyProposal memory memProposal = proposal;
        delete memProposal.hasVoted; // Mappings cannot be returned directly
        return memProposal;
    }

    // 35. getTextProposalState - Get the state of a text proposal
    function getTextProposalState(uint256 proposalId) external view returns (TextProposal memory) {
         TextProposal storage proposal = textProposals[proposalId];
        if (proposal.id == 0) revert InvalidProposalState(); // Check existence
         // Copy to memory to return
        TextProposal memory memProposal = proposal;
        delete memProposal.hasVoted; // Mappings cannot be returned directly
        return memProposal;
    }

    // 36. getCurrentStrategy - Get the currently approved investment strategy
    function getCurrentStrategy() external view returns (StrategyAllocation[] memory) {
        return currentApprovedStrategy; // Returns a copy
    }

    // Fallback/Receive (Optional, not strictly needed for this design)
    // receive() external payable {}
    // fallback() external payable {}
}
```