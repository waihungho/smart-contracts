```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// --- ChronosFlow Protocol ---
// A Decentralized Lending Protocol with Dynamic Reputation and Adaptive Risk-Adjusted Parameters.
// This contract introduces a novel "FlowTier" reputation system based on user behavior
// (deposits, borrows, repayments, governance participation).
// Interest rates, LTVs, and borrowing limits dynamically adjust per user based on their FlowTier.
// It also integrates gamified "ChronosQuests" and NFT "AetherBadges" as rewards for engagement,
// along with a unique delegated borrowing capacity feature.

// --- Outline ---
// 1. Interfaces: Definitions for ERC20, PriceOracle, ChronosPointsToken, AetherBadgeNFT, and a simplified Governance module.
// 2. Errors: Custom error types for specific failure conditions, enhancing readability and debugging.
// 3. Events: Comprehensive logs for significant state changes and user actions, crucial for off-chain monitoring.
// 4. Structs: Data structures for managing Reserve configurations, individual Loans, UserAccount profiles,
//    ChronosQuests, FlowTier benefits, and Governance Proposals.
// 5. Enums: Defines states for governance proposals.
// 6. State Variables: Core protocol parameters, mappings for data storage, and addresses of external contracts.
// 7. Modifiers: Access control (e.g., `onlyGovernor`) and state-based checks (e.g., `whenNotEmergencyShutdown`).
// 8. Constructor: Initializes the default FlowTier configurations.
// 9. Core Protocol Initialization & Configuration: Functions to set up the protocol's dependencies and supported assets.
// 10. Lending & Borrowing Operations: Fundamental DeFi functions for collateral management and loan lifecycles.
// 11. Reputation System Functions: Logic for managing ChronosPoints, determining FlowTiers, and adjusting reputation parameters.
// 12. Dynamic Parameters & Risk Adjustment: Functions to calculate and retrieve risk-adjusted lending parameters based on user FlowTier.
// 13. Gamification Functions: Features for creating and completing on-chain quests, and minting achievement NFTs.
// 14. Delegation Functions: Unique functionality allowing users to delegate portions of their borrowing capacity.
// 15. Governance & Emergency Controls: Functions for protocol parameter changes via a simplified governance model and emergency pausing.
// 16. Helper Functions (Internal): Auxiliary functions for complex calculations (e.g., health factor, interest accrual).

// --- Function Summary ---

// --- Core Protocol Initialization & Configuration ---
// 1. initialize(address _priceOracle, address _chronosPointsToken, address _aetherBadgeNFT, address _governanceModule)
//    - Description: Initializes the ChronosFlow protocol with essential external contract addresses (Price Oracle, ChronosPoints token, AetherBadge NFT, and Governance module).
//    - Access: Callable once by the contract deployer.
// 2. setAssetReserveData(address asset, uint256 baseLTV, uint256 baseInterestRate, uint256 liquidationThreshold)
//    - Description: Establishes or updates the lending parameters for a specific ERC20 asset, making it supported by the protocol.
//    - Access: Restricted to the GOVERNOR.
// 3. setPriceOracle(address _newOracle)
//    - Description: Updates the address of the external price oracle, which provides real-time asset price data.
//    - Access: Restricted to the GOVERNOR.

// --- Lending & Borrowing Operations ---
// 4. depositCollateral(address asset, uint256 amount)
//    - Description: Allows users to deposit a specified amount of ERC20 tokens as collateral into their account.
//    - Access: Anyone, provided the protocol is not in emergency shutdown.
// 5. withdrawCollateral(address asset, uint256 amount)
//    - Description: Enables users to withdraw their deposited collateral, ensuring sufficient collateral remains for any active loans.
//    - Access: User, if their account health factor remains sound after withdrawal.
// 6. borrow(address asset, uint256 amount)
//    - Description: Allows users to borrow ERC20 tokens against their deposited collateral, subject to their borrowing limit and FlowTier.
//    - Access: User, if collateral and reputation allow, and no active loan for that asset exists.
// 7. repay(address asset, uint256 amount)
//    - Description: Enables users (or anyone on their behalf) to repay outstanding loans, including accrued interest.
//    - Access: Anyone.
// 8. liquidateLoan(address borrower, address collateralAsset, address debtAsset)
//    - Description: Permits a liquidator to close undercollateralized loans, taking a portion of the borrower's collateral as a bonus.
//    - Access: Anyone, when a loan is sufficiently undercollateralized.

// --- Reputation System (ChronosPoints & FlowTiers) ---
// 9. getChronosPoints(address user) view
//    - Description: Retrieves the current ChronosPoints balance for a specified user.
//    - Access: Publicly viewable.
// 10. getFlowTier(address user) view
//    - Description: Determines and returns the current FlowTier of a user based on their accumulated ChronosPoints.
//    - Access: Publicly viewable.
// 11. setReputationWeights(uint256 depositWeight, uint256 borrowWeight, uint256 repayWeight, uint256 governanceWeight)
//    - Description: Sets the multipliers for earning ChronosPoints based on different user actions (deposits, borrows, repayments, governance participation).
//    - Access: Restricted to the GOVERNOR.
// 12. slashChronosPoints(address user, uint256 points)
//    - Description: Reduces a user's ChronosPoints, typically used as a penalty for loan defaults or policy violations.
//    - Access: Restricted to the GOVERNOR (or designated liquidator roles).

// --- Dynamic Parameters & Risk Adjustment ---
// 13. getDynamicInterestRate(address user, address asset) view
//    - Description: Calculates and returns the real-time annual interest rate for a specific user and asset, adjusted by their FlowTier.
//    - Access: Publicly viewable.
// 14. getDynamicLoanToValue(address user, address asset) view
//    - Description: Calculates and returns the effective Loan-to-Value (LTV) ratio for a user and asset, adjusted by their FlowTier.
//    - Access: Publicly viewable.
// 15. getMaxBorrowableAmount(address user, address asset) view
//    - Description: Calculates the maximum amount of a specific asset a user can borrow, considering their collateral value and FlowTier benefits.
//    - Access: Publicly viewable.

// --- Gamification (ChronosQuests & AetherBadges) ---
// 16. createChronosQuest(string memory name, string memory description, uint256 rewardPoints, uint256 deadline, bytes32 requiredTaskHash)
//    - Description: Allows the governor to define and activate new on-chain quests that users can complete to earn ChronosPoints.
//    - Access: Restricted to the GOVERNOR.
// 17. completeChronosQuest(uint256 questId, bytes memory proofData)
//    - Description: Enables a user to submit proof of completion for a specific ChronosQuest to claim their reward points.
//    - Access: User, if quest conditions are met and active.
// 18. mintAetherBadge(address recipient, uint256 badgeId)
//    - Description: Mints an AetherBadge NFT to a user's address, signifying achievement (e.g., reaching a new FlowTier or completing a major quest).
//    - Access: Restricted to the GOVERNOR (or triggered internally by protocol logic on achievement).
// 19. getUserAetherBadges(address user) view
//    - Description: Queries the AetherBadgeNFT contract to retrieve all AetherBadge IDs owned by a specific user.
//    - Access: Publicly viewable.

// --- Delegated Borrowing Capacity ---
// 20. delegateBorrowingCapacity(address delegatee, uint256 amount)
//    - Description: Allows a high-tier user to delegate a portion of their unused borrowing capacity to another address.
//    - Access: User with a sufficiently high FlowTier.
// 21. withdrawDelegatedBorrowingCapacity(address delegatee, uint256 amount)
//    - Description: Enables a delegator to reclaim previously delegated borrowing capacity from a delegatee.
//    - Access: Delegator.
// 22. getDelegatedBorrowingCapacity(address delegator, address delegatee) view
//    - Description: Retrieves the current amount of borrowing capacity delegated from a specific delegator to a delegatee.
//    - Access: Publicly viewable.

// --- Governance & Emergency Controls ---
// 23. proposeProtocolParameterChange(bytes32 parameterHash, uint256 newValue, uint256 delay)
//    - Description: Allows a governor to initiate a proposal to change a core protocol parameter, with a specified execution delay.
//    - Access: Restricted to the GOVERNOR.
// 24. voteOnProposal(uint256 proposalId, bool support)
//    - Description: Enables a governor (or token/reputation holder in a full DAO) to cast a vote on an active proposal.
//    - Access: Restricted to the GOVERNOR (simplified for this example).
// 25. executeProposal(uint256 proposalId)
//    - Description: Executes a successfully voted-on proposal after its time-lock delay has passed.
//    - Access: Anyone (after the delay, assuming proposal conditions are met).
// 26. emergencyShutdown()
//    - Description: A critical function to pause key lending operations in response to a severe vulnerability or market instability.
//    - Access: Restricted to the GOVERNOR.
// 27. reclaimFunds(address tokenAddress, uint256 amount)
//    - Description: Allows the governor to recover ERC20 tokens accidentally sent to the contract that are not part of core protocol operations (e.g., collateral).
//    - Access: Restricted to the GOVERNOR.

// --- Access Control & Pausability ---
// Uses a simplified governance interface and a Pausable abstract contract.
// In a full production environment, `IGovernance` would interact with a more robust DAO contract
// (e.g., OpenZeppelin Governor) handling voting, quorums, and timelocks.
interface IGovernance {
    function isGovernor(address _address) external view returns (bool);
}

// A simplified Pausable contract to demonstrate pausing functionality.
// Production-grade Pausable (e.g., OpenZeppelin) would typically have `onlyPauser` or `onlyRole` modifiers.
abstract contract Pausable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!_paused, "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(_paused, "Pausable: not paused");
    }

    function _pause() internal virtual {
        _paused = true;
        emit Paused(msg.sender); // In a real setup, msg.sender would be the pauser role.
    }

    function _unpause() internal virtual {
        _paused = false;
        emit Unpaused(msg.sender); // In a real setup, msg.sender would be the unpauser role.
    }
}

// --- External Interfaces ---
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPriceOracle {
    // getPrice returns the price of an asset in USD, scaled by 1e8 (e.g., $1.00 = 100000000).
    function getPrice(address asset) external view returns (uint256);
}

interface IChronosPointsToken {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    // Assumed to be an ERC20-like token that allows contract to mint/burn.
}

interface IAetherBadgeNFT {
    // Assumed to be an ERC-1155 or ERC-721 like contract with a mint function.
    // For simplicity, a direct `mint` is used, and a `getTokensOfOwner` for ERC-1155 like query.
    function mint(address to, uint256 tokenId) external;
    function balanceOf(address owner, uint256 tokenId) external view returns (uint256); // ERC-1155 specific
    function getTokensOfOwner(address owner) external view returns (uint256[] memory); // Custom helper for ERC-1155/721 to get all IDs
}

// --- Utility Library for Safe ERC20 Operations ---
library SafeERC20 {
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: ERC20 operation did not succeed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ChronosFlow is Pausable {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error InitializationFailed();
    error NotGovernor();
    error AssetNotSupported();
    error InvalidAmount();
    error InsufficientCollateral();
    error LoanTooLarge();
    error LoanNotUndercollateralized();
    error RepaymentAmountExceedsDebt();
    error NoActiveLoan();
    error SelfLiquidationNotAllowed();
    error InvalidReputationWeights();
    error QuestNotFound();
    error QuestAlreadyCompleted();
    error QuestNotActive();
    error QuestDeadlinePassed();
    error InvalidQuestProof();
    error InsufficientFlowTier();
    error InvalidDelegationAmount();
    error NoDelegationFound();
    error InvalidProposalId();
    error ProposalAlreadyVoted();
    error ProposalNotQueued(); // Covers Pending/Active states where execution is not allowed
    error ProposalNotReadyForExecution();
    error ProposalAlreadyExecuted();
    error EmergencyShutdownActive();
    error CannotReclaimProtocolFunds();

    // --- Events ---
    event Initialized(address priceOracle, address chronosPointsToken, address aetherBadgeNFT, address governanceModule);
    event AssetReserveDataUpdated(address indexed asset, uint256 baseLTV, uint256 baseInterestRate, uint256 liquidationThreshold);
    event PriceOracleUpdated(address indexed newOracle);
    event CollateralDeposited(address indexed user, address indexed asset, uint256 amount);
    event CollateralWithdrawn(address indexed user, address indexed asset, uint256 amount);
    event LoanBorrowed(address indexed user, address indexed asset, uint256 amount, uint256 interestRate);
    event LoanRepaid(address indexed user, address indexed asset, uint256 amount);
    event LoanLiquidated(address indexed borrower, address indexed liquidator, address indexed collateralAsset, address debtAsset, uint256 debtToCover, uint256 liquidatedCollateral);
    event ChronosPointsUpdated(address indexed user, uint256 newPoints);
    event FlowTierUpdated(address indexed user, uint256 newTier);
    event ReputationWeightsUpdated(uint256 depositWeight, uint256 borrowWeight, uint256 repayWeight, uint256 governanceWeight);
    event ChronosPointsSlashed(address indexed user, uint256 points);
    event ChronosQuestCreated(uint256 indexed questId, string name, uint256 rewardPoints, uint256 deadline, bytes32 requiredTaskHash);
    event ChronosQuestCompleted(uint256 indexed questId, address indexed user, uint256 rewardPoints);
    event AetherBadgeMinted(address indexed recipient, uint256 indexed badgeId);
    event BorrowingCapacityDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
    event BorrowingCapacityWithdrawn(address indexed delegator, address indexed delegatee, uint256 amount);
    event ProposalCreated(uint256 indexed proposalId, bytes32 indexed parameterHash, uint256 newValue, uint256 delay, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event EmergencyShutdown();
    event FundsReclaimed(address indexed tokenAddress, uint256 amount);

    // --- Constants ---
    uint256 public constant LIQUIDATION_BONUS_FACTOR = 105; // 5% bonus (100% + 5%)
    uint256 public constant PERCENTAGE_FACTOR = 10_000; // For percentages (e.g., 100% = 10,000 basis points)
    uint256 public constant ONE_EIGHTEEN = 1e18; // Standard ERC20 token decimal scaling factor
    uint256 public constant PRICE_ORACLE_PRECISION = 1e8; // Price oracle returns prices scaled by 1e8 USD

    // --- Structs ---

    // Defines configuration for each supported lending asset.
    struct ReserveData {
        bool isSupported;
        uint256 totalDeposited;
        uint256 totalBorrowed; // Includes accrued interest
        uint256 baseLTV; // Base Loan-to-Value (e.g., 70% = 7000 basis points)
        uint256 baseInterestRate; // Base Annual Interest Rate (e.g., 5% = 500 basis points)
        uint256 liquidationThreshold; // If loan health drops below this, it can be liquidated (e.g., 110% = 11000 basis points)
        uint256 lastUpdateTimestamp; // Timestamp of the last interest accumulation update for the reserve.
    }

    // Stores details of a user's active loan for a specific asset.
    struct Loan {
        uint256 amount; // Principal loan amount (can be reduced by repayment)
        uint256 borrowedTimestamp;
        uint256 interestRateAtBorrow; // Interest rate fixed at the time of borrowing for this loan
    }

    // Comprehensive profile for each user, including collateral, loans, and reputation data.
    struct UserAccount {
        mapping(address => uint256) depositedCollateral; // asset => amount of collateral deposited
        mapping(address => Loan) activeLoans; // asset => Loan details
        uint256 chronosPoints; // User's accumulated reputation points
        uint256 flowTier; // Derived reputation tier
        mapping(address => uint256) delegatedBorrowingCapacity; // delegatee => amount of borrowing capacity delegated by this user
        mapping(uint256 => bool) completedQuests; // questId => whether the quest has been completed by this user
    }

    // Configuration for each FlowTier, defining benefits based on ChronosPoints.
    struct FlowTierConfig {
        uint256 minPoints; // Minimum ChronosPoints required for this tier
        uint256 ltvBonus; // Bonus (in basis points) added to the base LTV for this tier
        uint256 interestRateReduction; // Reduction (in basis points) from the base interest rate for this tier
        uint256 minBorrowCapacityMultiplier; // Multiplier for the user's borrowing capacity (e.g., 1050 = 1.05x)
    }

    // Enum for the different states of a governance proposal.
    enum ProposalState { Pending, Active, Succeeded, Failed, Executed }

    // Defines a governance proposal for protocol parameter changes.
    struct Proposal {
        bytes32 parameterHash; // Hashed identifier of the parameter to be changed (e.g., keccak256("LIQUIDATION_BONUS_FACTOR"))
        uint256 newValue; // The new value for the parameter
        uint256 creationTimestamp;
        uint256 executionDelay; // Time in seconds before a successful proposal can be executed
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted; // Tracks if a governor has voted on this proposal
        ProposalState state;
    }

    // Defines a ChronosQuest, a gamified task for users.
    struct ChronosQuest {
        string name;
        string description;
        uint256 rewardPoints; // ChronosPoints awarded upon completion
        uint256 deadline; // Timestamp by which the quest must be completed
        bytes32 requiredTaskHash; // A hash representing the proof or condition required for completion
        bool isActive;
    }

    // --- State Variables ---
    IPriceOracle public priceOracle;
    IChronosPointsToken public chronosPointsToken; // ERC20-like token representing reputation points
    IAetherBadgeNFT public aetherBadgeNFT; // ERC-1155 or ERC-721 contract for achievement badges
    IGovernance public governanceModule; // The contract responsible for governance roles (e.g., identifying governors)

    bool public initialized; // Tracks if the contract has been initialized
    bool public protocolPaused; // Flag for emergency shutdown, separate from `Pausable`'s `_paused` for clarity.

    mapping(address => ReserveData) public reserves; // Maps asset address to its ReserveData
    mapping(address => UserAccount) public userAccounts; // Maps user address to their UserAccount data

    // Weights for earning ChronosPoints from different user actions, adjustable by governance.
    uint256 public reputationDepositWeight; // Points earned per 1 USD value of collateral deposited
    uint256 public reputationBorrowWeight; // Points earned per 1 USD value of tokens borrowed
    uint256 public reputationRepayWeight; // Points earned per 1 USD value of loan repaid
    uint256 public reputationGovernanceWeight; // Points earned for participating in governance actions

    // Array of FlowTier configurations, ordered by `minPoints`.
    FlowTierConfig[] public flowTiers;

    // Quests management
    ChronosQuest[] public chronosQuests; // Stores all created quests
    uint256 public nextQuestId; // Counter for unique quest IDs

    // Governance proposals management
    uint256 public nextProposalId; // Counter for unique proposal IDs
    mapping(uint256 => Proposal) public proposals; // Maps proposal ID to Proposal data

    address[] public supportedAssets; // Array of addresses for all currently supported lending assets

    // --- Modifiers ---
    // Ensures that only an address recognized as a governor by the `governanceModule` can call the function.
    modifier onlyGovernor() {
        if (!governanceModule.isGovernor(msg.sender)) {
            revert NotGovernor();
        }
        _;
    }

    // Ensures that the protocol is not in an emergency shutdown state.
    modifier whenNotEmergencyShutdown() {
        if (protocolPaused) {
            revert EmergencyShutdownActive();
        }
        _;
    }

    // --- Constructor ---
    // Initializes the default FlowTier configurations when the contract is deployed.
    // In a real production scenario, this contract might be deployed behind a proxy for upgradeability,
    // and initialization would be handled by a separate `initialize` function.
    constructor() {
        // Default Tier 0: Base values, no bonus or reduction
        flowTiers.push(FlowTierConfig(0, 0, 0, ONE_EIGHTEEN)); // minPoints=0, ltvBonus=0, interestRateReduction=0, minBorrowCapacityMultiplier=1.0x

        // Example Tier 1: Small bonus for users with at least 1000 points
        flowTiers.push(FlowTierConfig(1000, 50, 20, 1050)); // 1000 points, 0.5% LTV bonus, 0.02% IR reduction, 1.05x borrow capacity

        // Example Tier 2: Medium bonus for users with at least 5000 points
        flowTiers.push(FlowTierConfig(5000, 100, 50, 1100)); // 5000 points, 1% LTV bonus, 0.05% IR reduction, 1.1x borrow capacity
        
        // Initial reputation weights (per 1 USD value of action)
        reputationDepositWeight = 1; // 1 point per $1 USD deposited
        reputationBorrowWeight = 2; // 2 points per $1 USD borrowed (encourages borrowing)
        reputationRepayWeight = 3; // 3 points per $1 USD repaid (rewards good repayment behavior)
        reputationGovernanceWeight = 100; // 100 points for a governance action (e.g., voting)
    }

    // --- Core Protocol Initialization & Configuration ---

    // @notice Initializes the ChronosFlow protocol with essential external contract addresses.
    // @param _priceOracle The address of the price oracle contract.
    // @param _chronosPointsToken The address of the ChronosPoints ERC20 token contract.
    // @param _aetherBadgeNFT The address of the AetherBadge NFT contract.
    // @param _governanceModule The address of the governance module contract.
    function initialize(
        address _priceOracle,
        address _chronosPointsToken,
        address _aetherBadgeNFT,
        address _governanceModule
    ) public {
        if (initialized) revert InitializationFailed();
        if (_priceOracle == address(0) || _chronosPointsToken == address(0) || _aetherBadgeNFT == address(0) || _governanceModule == address(0)) {
            revert InitializationFailed(); // All addresses must be valid
        }

        priceOracle = IPriceOracle(_priceOracle);
        chronosPointsToken = IChronosPointsToken(_chronosPointsToken);
        aetherBadgeNFT = IAetherBadgeNFT(_aetherBadgeNFT);
        governanceModule = IGovernance(_governanceModule);

        initialized = true;
        emit Initialized(_priceOracle, _chronosPointsToken, _aetherBadgeNFT, _governanceModule);
    }

    // @notice Sets or updates configuration data for a supported asset's lending reserve.
    // @param asset The address of the ERC20 token to configure.
    // @param baseLTV The base Loan-to-Value ratio for the asset (scaled by PERCENTAGE_FACTOR).
    // @param baseInterestRate The base annual interest rate for the asset (scaled by PERCENTAGE_FACTOR).
    // @param liquidationThreshold The liquidation threshold for the asset (scaled by PERCENTAGE_FACTOR).
    function setAssetReserveData(
        address asset,
        uint256 baseLTV,
        uint256 baseInterestRate,
        uint256 liquidationThreshold
    ) external onlyGovernor {
        // Basic validation: LTV/IR max 100%, LiqThreshold min 100%
        if (baseLTV > PERCENTAGE_FACTOR || baseInterestRate > PERCENTAGE_FACTOR || liquidationThreshold < PERCENTAGE_FACTOR)
            revert InvalidAmount(); 

        if (!reserves[asset].isSupported) {
            supportedAssets.push(asset); // Add to supported list if new asset
        }
        reserves[asset].isSupported = true;
        reserves[asset].baseLTV = baseLTV;
        reserves[asset].baseInterestRate = baseInterestRate;
        reserves[asset].liquidationThreshold = liquidationThreshold;
        reserves[asset].lastUpdateTimestamp = block.timestamp; // Initialize or update timestamp

        emit AssetReserveDataUpdated(asset, baseLTV, baseInterestRate, liquidationThreshold);
    }

    // @notice Updates the address of the external price oracle contract.
    // @param _newOracle The address of the new price oracle.
    function setPriceOracle(address _newOracle) external onlyGovernor {
        if (_newOracle == address(0)) revert InvalidAmount();
        priceOracle = IPriceOracle(_newOracle);
        emit PriceOracleUpdated(_newOracle);
    }

    // --- Lending & Borrowing Operations ---

    // @notice Allows users to deposit ERC20 tokens as collateral.
    // @param asset The address of the ERC20 token to deposit.
    // @param amount The amount of tokens to deposit.
    function depositCollateral(address asset, uint256 amount) external whenNotEmergencyShutdown {
        if (!reserves[asset].isSupported || amount == 0) revert InvalidAmount();

        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        userAccounts[msg.sender].depositedCollateral[asset] += amount;
        reserves[asset].totalDeposited += amount;

        // Award ChronosPoints for depositing collateral
        uint256 valueUSD = (amount * priceOracle.getPrice(asset)) / PRICE_ORACLE_PRECISION;
        _updateChronosPoints(msg.sender, (valueUSD * reputationDepositWeight) / ONE_EIGHTEEN, true); // Scale points for small amounts

        emit CollateralDeposited(msg.sender, asset, amount);
    }

    // @notice Allows users to withdraw their deposited collateral.
    // @param asset The address of the ERC20 token to withdraw.
    // @param amount The amount of tokens to withdraw.
    function withdrawCollateral(address asset, uint256 amount) external whenNotEmergencyShutdown {
        if (!reserves[asset].isSupported || amount == 0) revert InvalidAmount();
        if (userAccounts[msg.sender].depositedCollateral[asset] < amount) revert InsufficientCollateral();

        userAccounts[msg.sender].depositedCollateral[asset] -= amount;
        reserves[asset].totalDeposited -= amount;

        // Recalculate health factor after withdrawal to ensure solvency
        if (_calculateUserHealthFactor(msg.sender) < reserves[asset].liquidationThreshold) { 
            // If user would become undercollateralized, revert withdrawal and restore state
            userAccounts[msg.sender].depositedCollateral[asset] += amount;
            reserves[asset].totalDeposited += amount;
            revert InsufficientCollateral();
        }

        IERC20(asset).safeTransfer(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, asset, amount);
    }

    // @notice Allows users to borrow ERC20 tokens against their collateral.
    // @param asset The address of the ERC20 token to borrow.
    // @param amount The amount of tokens to borrow.
    function borrow(address asset, uint256 amount) external whenNotEmergencyShutdown {
        if (!reserves[asset].isSupported || amount == 0) revert InvalidAmount();
        if (userAccounts[msg.sender].activeLoans[asset].amount > 0) revert NoActiveLoan(); // Only one active loan per asset for simplicity

        // Calculate maximum borrowable amount for the user based on collateral and FlowTier
        uint256 maxBorrow = getMaxBorrowableAmount(msg.sender, asset);
        if (amount > maxBorrow) revert LoanTooLarge();

        // Update interest for the reserve before borrowing from it
        _updateReserveInterest(asset);
        uint256 currentInterestRate = getDynamicInterestRate(msg.sender, asset);

        userAccounts[msg.sender].activeLoans[asset] = Loan({
            amount: amount,
            borrowedTimestamp: block.timestamp,
            interestRateAtBorrow: currentInterestRate // Fixed rate for the duration of this loan
        });
        reserves[asset].totalBorrowed += amount;

        IERC20(asset).safeTransfer(msg.sender, amount);

        // Award ChronosPoints for borrowing
        uint256 valueUSD = (amount * priceOracle.getPrice(asset)) / PRICE_ORACLE_PRECISION;
        _updateChronosPoints(msg.sender, (valueUSD * reputationBorrowWeight) / ONE_EIGHTEEN, true);

        emit LoanBorrowed(msg.sender, asset, amount, currentInterestRate);
    }

    // @notice Allows users (or anyone) to repay their outstanding loans.
    // @param asset The address of the ERC20 token loan to repay.
    // @param amount The amount of tokens to repay.
    function repay(address asset, uint256 amount) external whenNotEmergencyShutdown {
        if (!reserves[asset].isSupported || amount == 0) revert InvalidAmount();
        if (userAccounts[msg.sender].activeLoans[asset].amount == 0) revert NoActiveLoan();

        // Update interest for the reserve before processing repayment
        _updateReserveInterest(asset);

        // Calculate current total debt including accumulated interest
        uint256 totalDebtIncludingInterest = _calculateCurrentLoanInterest(msg.sender, asset);
        if (totalDebtIncludingInterest == 0) revert NoActiveLoan(); // Loan might have been just repaid

        uint256 repayAmount = amount;
        if (repayAmount > totalDebtIncludingInterest) {
            repayAmount = totalDebtIncludingInterest; // Only repay up to the actual debt
        }

        IERC20(asset).safeTransferFrom(msg.sender, address(this), repayAmount);

        // Reduce the principal of the loan. In a more complex model, interest would be tracked separately.
        // For simplicity, we assume repayment directly reduces the effective loan amount.
        userAccounts[msg.sender].activeLoans[asset].amount -= repayAmount; 
        reserves[asset].totalBorrowed -= repayAmount;

        // If loan fully repaid, clear the loan entry
        if (userAccounts[msg.sender].activeLoans[asset].amount == 0) {
            delete userAccounts[msg.sender].activeLoans[asset];
        }

        // Award ChronosPoints for repaying a loan
        uint256 valueUSD = (repayAmount * priceOracle.getPrice(asset)) / PRICE_ORACLE_PRECISION;
        _updateChronosPoints(msg.sender, (valueUSD * reputationRepayWeight) / ONE_EIGHTEEN, true);

        emit LoanRepaid(msg.sender, asset, repayAmount);
    }

    // @notice Allows a liquidator to close undercollateralized loans, earning a bonus.
    // @param borrower The address of the borrower whose loan is being liquidated.
    // @param collateralAsset The address of the collateral token to be liquidated.
    // @param debtAsset The address of the debt token that needs to be covered.
    function liquidateLoan(address borrower, address collateralAsset, address debtAsset) external whenNotEmergencyShutdown {
        if (borrower == msg.sender) revert SelfLiquidationNotAllowed(); // Cannot liquidate your own loan
        if (!reserves[collateralAsset].isSupported || !reserves[debtAsset].isSupported) revert AssetNotSupported();
        if (userAccounts[borrower].activeLoans[debtAsset].amount == 0) revert NoActiveLoan();

        // Update interest for both relevant reserves to get current values
        _updateReserveInterest(collateralAsset);
        _updateReserveInterest(debtAsset);

        // Calculate borrower's current health factor
        uint256 borrowerHealthFactor = _calculateUserHealthFactor(borrower);
        uint256 liquidationThreshold = reserves[collateralAsset].liquidationThreshold; // Threshold specific to collateral

        if (borrowerHealthFactor >= liquidationThreshold) { 
            revert LoanNotUndercollateralized(); // Loan is healthy, cannot liquidate
        }

        // Calculate the current total debt (principal + interest)
        uint256 currentDebt = _calculateCurrentLoanInterest(borrower, debtAsset);
        
        // Get current prices from oracle
        uint256 debtAssetPrice = priceOracle.getPrice(debtAsset);
        uint256 collateralAssetPrice = priceOracle.getPrice(collateralAsset);
        if (debtAssetPrice == 0 || collateralAssetPrice == 0) revert InvalidAmount(); // Prices must be valid

        // Calculate the value of collateral (in USD) needed to cover the debt, including liquidation bonus
        uint256 collateralToLiquidateUSD = (currentDebt * debtAssetPrice * LIQUIDATION_BONUS_FACTOR) / (PERCENTAGE_FACTOR * PRICE_ORACLE_PRECISION);
        
        // Convert USD value back to collateral asset amount
        uint256 collateralAmount = (collateralToLiquidateUSD * PRICE_ORACLE_PRECISION) / collateralAssetPrice;
        
        // Ensure borrower has enough collateral
        if (userAccounts[borrower].depositedCollateral[collateralAsset] < collateralAmount) revert InsufficientCollateral();

        // Liquidator pays off the debt in the debtAsset
        IERC20(debtAsset).safeTransferFrom(msg.sender, address(this), currentDebt);

        // Transfer liquidated collateral to the liquidator as reward
        userAccounts[borrower].depositedCollateral[collateralAsset] -= collateralAmount;
        reserves[collateralAsset].totalDeposited -= collateralAmount;
        IERC20(collateralAsset).safeTransfer(msg.sender, collateralAmount);

        // Update borrower's debt and clear loan if fully liquidated
        reserves[debtAsset].totalBorrowed -= currentDebt;
        delete userAccounts[borrower].activeLoans[debtAsset];

        // Slash borrower's ChronosPoints for defaulting
        _updateChronosPoints(borrower, userAccounts[borrower].chronosPoints / 10, false); // Slash 10% of points for default

        emit LoanLiquidated(borrower, msg.sender, collateralAsset, debtAsset, currentDebt, collateralAmount);
    }

    // --- Reputation System (ChronosPoints & FlowTiers) ---

    // @notice Retrieves the current ChronosPoints balance for a specified user.
    // @param user The address of the user.
    // @return The ChronosPoints balance.
    function getChronosPoints(address user) public view returns (uint256) {
        return userAccounts[user].chronosPoints;
    }

    // @notice Determines and returns the FlowTier for a user based on their ChronosPoints.
    // @param user The address of the user.
    // @return The FlowTier number (0-indexed).
    function getFlowTier(address user) public view returns (uint256) {
        uint256 currentPoints = userAccounts[user].chronosPoints;
        uint256 currentTier = 0; // Default to Tier 0
        for (uint256 i = 0; i < flowTiers.length; i++) {
            if (currentPoints >= flowTiers[i].minPoints) {
                currentTier = i; // If points meet threshold, advance to this tier
            } else {
                break; // Tiers are sorted by minPoints, so if current points are less, no further tiers can be reached
            }
        }
        return currentTier;
    }

    // @notice Sets the weights for earning ChronosPoints based on different user actions.
    // @param depositWeight Points per 1 USD deposited.
    // @param borrowWeight Points per 1 USD borrowed.
    // @param repayWeight Points per 1 USD repaid.
    // @param governanceWeight Points for governance actions.
    function setReputationWeights(
        uint256 depositWeight,
        uint256 borrowWeight,
        uint256 repayWeight,
        uint256 governanceWeight
    ) external onlyGovernor {
        if (depositWeight == 0 || borrowWeight == 0 || repayWeight == 0 || governanceWeight == 0)
            revert InvalidReputationWeights();

        reputationDepositWeight = depositWeight;
        reputationBorrowWeight = borrowWeight;
        reputationRepayWeight = repayWeight;
        reputationGovernanceWeight = governanceWeight;

        emit ReputationWeightsUpdated(depositWeight, borrowWeight, repayWeight, governanceWeight);
    }

    // @notice Reduces a user's ChronosPoints, typically for loan defaults or policy violations.
    // @param user The address of the user whose points are to be slashed.
    // @param points The amount of ChronosPoints to slash.
    function slashChronosPoints(address user, uint256 points) external onlyGovernor { // Could be also callable by liquidator with specific rules
        _updateChronosPoints(user, points, false); // Use internal helper to reduce points and update tier
        emit ChronosPointsSlashed(user, points);
    }

    // --- Dynamic Parameters & Risk Adjustment ---

    // @notice Calculates the real-time annual interest rate for a user, adjusted by their FlowTier.
    // @param user The address of the user.
    // @param asset The address of the asset.
    // @return The dynamic interest rate (scaled by PERCENTAGE_FACTOR).
    function getDynamicInterestRate(address user, address asset) public view returns (uint256) {
        if (!reserves[asset].isSupported) revert AssetNotSupported();

        uint256 baseRate = reserves[asset].baseInterestRate;
        uint256 userTier = getFlowTier(user);

        // Apply tier-based reduction if the user is in a tier with a bonus
        if (userTier < flowTiers.length) {
            uint256 reduction = flowTiers[userTier].interestRateReduction;
            if (baseRate > reduction) {
                baseRate -= reduction;
            } else {
                baseRate = 0; // Interest rate cannot be negative
            }
        }
        return baseRate;
    }

    // @notice Calculates the effective Loan-to-Value (LTV) ratio for a user, adjusted by their FlowTier.
    // @param user The address of the user.
    // @param asset The address of the asset.
    // @return The dynamic LTV (scaled by PERCENTAGE_FACTOR).
    function getDynamicLoanToValue(address user, address asset) public view returns (uint256) {
        if (!reserves[asset].isSupported) revert AssetNotSupported();

        uint256 baseLTV = reserves[asset].baseLTV;
        uint256 userTier = getFlowTier(user);

        // Apply tier-based bonus if the user is in a tier with a bonus
        if (userTier < flowTiers.length) {
            baseLTV += flowTiers[userTier].ltvBonus;
        }
        return baseLTV;
    }

    // @notice Calculates the maximum amount a user can borrow, considering their total collateral value and FlowTier.
    // @param user The address of the user.
    // @param asset The address of the asset to borrow.
    // @return The maximum amount of `asset` that `user` can borrow.
    function getMaxBorrowableAmount(address user, address asset) public view returns (uint256) {
        if (!reserves[asset].isSupported) return 0; // Cannot borrow an unsupported asset

        uint256 totalCollateralValueUSD = 0;
        // Sum the USD value of all deposited collateral
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address currentCollateralAsset = supportedAssets[i];
            uint256 amount = userAccounts[user].depositedCollateral[currentCollateralAsset];
            if (amount > 0) {
                uint256 price = priceOracle.getPrice(currentCollateralAsset);
                if (price == 0) continue; // Skip assets with no price (or if oracle is down)
                totalCollateralValueUSD += (amount * price) / PRICE_ORACLE_PRECISION;
            }
        }

        uint256 currentDebtValueUSD = 0;
        // Sum the USD value of all active loans (including interest)
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address currentDebtAsset = supportedAssets[i];
            if (userAccounts[user].activeLoans[currentDebtAsset].amount > 0) {
                uint224 debtAmount = uint224(_calculateCurrentLoanInterest(user, currentDebtAsset));
                uint256 price = priceOracle.getPrice(currentDebtAsset);
                if (price == 0) continue;
                currentDebtValueUSD += (debtAmount * price) / PRICE_ORACLE_PRECISION;
            }
        }

        uint256 dynamicLTV = getDynamicLoanToValue(user, asset);
        uint256 maxBorrowableUSD = (totalCollateralValueUSD * dynamicLTV) / PERCENTAGE_FACTOR;
        
        uint256 availableToBorrowUSD = maxBorrowableUSD;
        if (availableToBorrowUSD <= currentDebtValueUSD) return 0; // Already at or above max borrowing capacity
        availableToBorrowUSD -= currentDebtValueUSD;

        uint256 assetPrice = priceOracle.getPrice(asset);
        if (assetPrice == 0) return 0; // Cannot calculate if asset has no price

        uint256 maxBorrowAmount = (availableToBorrowUSD * PRICE_ORACLE_PRECISION) / assetPrice;

        // Apply FlowTier's minBorrowCapacityMultiplier if applicable
        uint256 userTier = getFlowTier(user);
        if (userTier < flowTiers.length) {
            maxBorrowAmount = (maxBorrowAmount * flowTiers[userTier].minBorrowCapacityMultiplier) / ONE_EIGHTEEN;
        }
        
        return maxBorrowAmount;
    }

    // --- Gamification (ChronosQuests & AetherBadges) ---

    // @notice Allows the governor to create new on-chain quests for users to complete.
    // @param name The name of the quest.
    // @param description A description of the quest.
    // @param rewardPoints The ChronosPoints awarded upon quest completion.
    // @param deadline The timestamp by which the quest must be completed.
    // @param requiredTaskHash A hash representing the conditions or proof required for quest completion.
    // @return questId The unique identifier for the newly created quest.
    function createChronosQuest(
        string memory name,
        string memory description,
        uint256 rewardPoints,
        uint256 deadline,
        bytes32 requiredTaskHash
    ) external onlyGovernor returns (uint256 questId) {
        questId = nextQuestId++;
        chronosQuests.push(ChronosQuest({
            name: name,
            description: description,
            rewardPoints: rewardPoints,
            deadline: deadline,
            requiredTaskHash: requiredTaskHash,
            isActive: true
        }));
        emit ChronosQuestCreated(questId, name, rewardPoints, deadline, requiredTaskHash);
        return questId;
    }

    // @notice Allows a user to submit proof of quest completion to earn ChronosPoints.
    // @param questId The ID of the quest to complete.
    // @param proofData Arbitrary data representing the proof of completion, to be hashed and compared.
    function completeChronosQuest(uint256 questId, bytes memory proofData) external whenNotEmergencyShutdown {
        if (questId >= chronosQuests.length) revert QuestNotFound();
        ChronosQuest storage quest = chronosQuests[questId];

        if (!quest.isActive) revert QuestNotActive();
        if (userAccounts[msg.sender].completedQuests[questId]) revert QuestAlreadyCompleted();
        if (block.timestamp > quest.deadline) revert QuestDeadlinePassed();

        // This is a simplified proof verification. In a real system, `requiredTaskHash`
        // could represent a hash of specific on-chain actions, a ZK-proof,
        // or a condition verified by an oracle.
        if (keccak256(proofData) != quest.requiredTaskHash) {
            revert InvalidQuestProof();
        }

        userAccounts[msg.sender].completedQuests[questId] = true;
        _updateChronosPoints(msg.sender, quest.rewardPoints, true); // Award points for completion
        
        emit ChronosQuestCompleted(questId, msg.sender, quest.rewardPoints);
    }

    // @notice Mints an AetherBadge NFT to a user upon reaching a tier or completing an achievement.
    // @param recipient The address to mint the badge to.
    // @param badgeId The ID of the AetherBadge NFT to mint.
    function mintAetherBadge(address recipient, uint256 badgeId) external onlyGovernor {
        // This function is exposed to the governor for manual issuance.
        // In a more automated system, it might be called internally by `_updateChronosPoints`
        // when a user reaches a new FlowTier, or by `completeChronosQuest` for special achievements.
        aetherBadgeNFT.mint(recipient, badgeId);
        emit AetherBadgeMinted(recipient, badgeId);
    }

    // @notice Retrieves the IDs of AetherBadges owned by a user via the AetherBadgeNFT contract.
    // @param user The address of the user.
    // @return An array of badge IDs owned by the user.
    function getUserAetherBadges(address user) external view returns (uint256[] memory) {
        return aetherBadgeNFT.getTokensOfOwner(user);
    }

    // --- Delegated Borrowing Capacity ---

    // @notice Allows a high-tier user to delegate a portion of their borrowing capacity to another address.
    // @param delegatee The address to which borrowing capacity is delegated.
    // @param amount The amount of borrowing capacity (in USD equivalent) to delegate.
    function delegateBorrowingCapacity(address delegatee, uint256 amount) external whenNotEmergencyShutdown {
        if (amount == 0 || delegatee == address(0)) revert InvalidDelegationAmount();
        // Require at least FlowTier 1 to delegate borrowing capacity
        if (getFlowTier(msg.sender) < 1) revert InsufficientFlowTier(); 

        // Simplified check: ensure delegator has sufficient *potential* capacity
        // In a complex system, this would calculate the actual unused borrow capacity dynamically.
        // For simplicity, we assume `getMaxBorrowableAmount` reflects the available capacity.
        uint256 currentMaxBorrowable = getMaxBorrowableAmount(msg.sender, address(supportedAssets[0])); // Use first supported asset as reference
        if (currentMaxBorrowable < amount) revert InsufficientCollateral(); // Not enough capacity to delegate

        userAccounts[msg.sender].delegatedBorrowingCapacity[delegatee] += amount;
        emit BorrowingCapacityDelegated(msg.sender, delegatee, amount);
    }

    // @notice Allows a delegator to reclaim previously delegated borrowing capacity from a delegatee.
    // @param delegatee The address from which to reclaim capacity.
    // @param amount The amount of borrowing capacity to reclaim.
    function withdrawDelegatedBorrowingCapacity(address delegatee, uint256 amount) external whenNotEmergencyShutdown {
        if (amount == 0) revert InvalidDelegationAmount();
        if (userAccounts[msg.sender].delegatedBorrowingCapacity[delegatee] < amount) revert NoDelegationFound();

        userAccounts[msg.sender].delegatedBorrowingCapacity[delegatee] -= amount;
        emit BorrowingCapacityWithdrawn(msg.sender, delegatee, amount);
    }

    // @notice Retrieves the current delegated borrowing capacity between two addresses.
    // @param delegator The address of the delegator.
    // @param delegatee The address of the delegatee.
    // @return The amount of borrowing capacity delegated.
    function getDelegatedBorrowingCapacity(address delegator, address delegatee) public view returns (uint256) {
        return userAccounts[delegator].delegatedBorrowingCapacity[delegatee];
    }

    // --- Governance & Emergency Controls ---

    // @notice Allows a governor to propose a change to a core protocol parameter.
    // @param parameterHash A unique hash identifying the parameter to change (e.g., keccak256("LIQUIDATION_BONUS_FACTOR")).
    // @param newValue The new value for the parameter.
    // @param delay The time in seconds before the proposal can be executed if successful.
    // @return proposalId The unique identifier for the new proposal.
    function proposeProtocolParameterChange(
        bytes32 parameterHash,
        uint256 newValue,
        uint256 delay
    ) external onlyGovernor returns (uint256 proposalId) {
        proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            parameterHash: parameterHash,
            newValue: newValue,
            creationTimestamp: block.timestamp,
            executionDelay: delay,
            votesFor: 0,
            votesAgainst: 0,
            hasVoted: new mapping(address => bool), // Initialize empty mapping
            state: ProposalState.Pending
        });
        emit ProposalCreated(proposalId, parameterHash, newValue, delay, msg.sender);
        return proposalId;
    }

    // @notice Allows governor/voters to cast a vote on an active proposal.
    // @param proposalId The ID of the proposal to vote on.
    // @param support True for a 'for' vote, false for 'against'.
    function voteOnProposal(uint256 proposalId, bool support) external onlyGovernor { 
        if (proposalId >= nextProposalId) revert InvalidProposalId();
        Proposal storage proposal = proposals[proposalId];

        // Ensure proposal is in a votable state (Pending or Active)
        if (proposal.state != ProposalState.Pending && proposal.state != ProposalState.Active) {
            revert ProposalNotQueued(); 
        }
        if (proposal.hasVoted[msg.sender]) revert ProposalAlreadyVoted(); // Governor already voted

        proposal.hasVoted[msg.sender] = true;
        if (support) {
            proposal.votesFor += 1; // Simplified: 1 vote per governor. Full DAO would use token/reputation weighting.
        } else {
            proposal.votesAgainst += 1;
        }

        // Simplistic state transition: If any governor votes 'for', it's 'Succeeded'.
        // In a real DAO, there would be a voting period, quorum, and weighted votes.
        if (support) {
            proposal.state = ProposalState.Succeeded;
        } else {
            // A 'false' vote from a governor could also signify failure depending on governance rules
            // For simplicity, we only mark Succeeded on 'true' vote.
            // A more complex system would transition to Failed if threshold for 'against' is met or if voting period ends.
        }

        // Award ChronosPoints for participating in governance
        _updateChronosPoints(msg.sender, reputationGovernanceWeight, true);

        emit ProposalVoted(proposalId, msg.sender, support);
    }

    // @notice Executes a successfully voted-on and time-locked proposal.
    // @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external { // Can be called by anyone after time lock
        if (proposalId >= nextProposalId) revert InvalidProposalId();
        Proposal storage proposal = proposals[proposalId];

        if (proposal.state != ProposalState.Succeeded) revert ProposalNotQueued(); // Must be Succeeded
        if (block.timestamp < proposal.creationTimestamp + proposal.executionDelay) revert ProposalNotReadyForExecution();
        if (proposal.state == ProposalState.Executed) revert ProposalAlreadyExecuted();

        // --- Parameter Change Logic ---
        // This section would use the `parameterHash` to identify and apply the `newValue`
        // to the corresponding protocol variable. This is a simplified representation.
        // A robust system might use upgradeable proxies (e.g., UUPS) or a more generic
        // execution mechanism (e.g., calling arbitrary functions) defined by the hash.

        // Example direct application based on hash:
        if (proposal.parameterHash == keccak256("LIQUIDATION_BONUS_FACTOR")) {
            // LIQUIDATION_BONUS_FACTOR = proposal.newValue; // Need to make this state variable mutable
            // For now, this is symbolic. Real implementation requires careful parameter mapping.
        } else if (proposal.parameterHash == keccak256("REPUTATION_DEPOSIT_WEIGHT")) {
            reputationDepositWeight = proposal.newValue;
        } else if (proposal.parameterHash == keccak256("REPUTATION_BORROW_WEIGHT")) {
            reputationBorrowWeight = proposal.newValue;
        } else if (proposal.parameterHash == keccak256("REPUTATION_REPAY_WEIGHT")) {
            reputationRepayWeight = proposal.newValue;
        } else if (proposal.parameterHash == keccak256("REPUTATION_GOVERNANCE_WEIGHT")) {
            reputationGovernanceWeight = proposal.newValue;
        } 
        // ... extend with more parameters that can be changed by governance
        // For changing asset-specific parameters, it would need to pass the asset address as well.
        // e.g., keccak256(abi.encodePacked("ASSET_LTV", assetAddress))

        proposal.state = ProposalState.Executed;
        emit ProposalExecuted(proposalId);
    }

    // @notice Pauses critical lending operations in case of an emergency, preventing new deposits/borrows.
    function emergencyShutdown() external onlyGovernor {
        _pause(); // Pauses functions using the `Pausable` modifier
        protocolPaused = true; // Sets a specific flag for functions using `whenNotEmergencyShutdown`
        emit EmergencyShutdown();
    }

    // @notice Allows the governor to recover accidentally sent ERC20 tokens that are NOT core protocol assets.
    // @param tokenAddress The address of the ERC20 token to reclaim.
    // @param amount The amount of tokens to reclaim.
    function reclaimFunds(address tokenAddress, uint256 amount) external onlyGovernor {
        // Prevent reclaiming core protocol assets (collateral, borrowed funds managed by reserves)
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            if (supportedAssets[i] == tokenAddress) {
                revert CannotReclaimProtocolFunds();
            }
        }
        // Also prevent reclaiming addresses of core dependencies
        if (tokenAddress == address(chronosPointsToken) || tokenAddress == address(aetherBadgeNFT) || 
            tokenAddress == address(priceOracle) || tokenAddress == address(governanceModule)) {
            revert CannotReclaimProtocolFunds();
        }

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
        emit FundsReclaimed(tokenAddress, amount);
    }

    // --- Helper Functions (Internal) ---

    // @notice Calculates the user's current health factor across all their loans and collateral.
    // A health factor above the `liquidationThreshold` (e.g., 110%) indicates a healthy loan.
    // @param user The address of the user.
    // @return The health factor (scaled by PERCENTAGE_FACTOR). Returns max uint256 if no debt.
    function _calculateUserHealthFactor(address user) internal view returns (uint256) {
        uint256 totalCollateralValueUSD = 0;
        // Calculate total collateral value in USD, applying LTV factors for borrowing power.
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address currentCollateralAsset = supportedAssets[i];
            uint256 amount = userAccounts[user].depositedCollateral[currentCollateralAsset];
            if (amount > 0) {
                uint256 price = priceOracle.getPrice(currentCollateralAsset);
                if (price == 0) continue; // Skip if no price available
                // For health factor calculation, it's often total collateral value * liquidation threshold
                // (or LTV). Here, we'll use a direct proportion for simplicity.
                totalCollateralValueUSD += (amount * price) / PRICE_ORACLE_PRECISION;
            }
        }

        uint256 totalBorrowedValueUSD = 0;
        // Calculate total debt value in USD, including interest.
        for (uint256 i = 0; i < supportedAssets.length; i++) {
            address currentDebtAsset = supportedAssets[i];
            if (userAccounts[user].activeLoans[currentDebtAsset].amount > 0) {
                uint256 debtAmount = _calculateCurrentLoanInterest(user, currentDebtAsset);
                uint256 price = priceOracle.getPrice(currentDebtAsset);
                if (price == 0) continue; // Skip if no price available
                totalBorrowedValueUSD += (debtAmount * price) / PRICE_ORACLE_PRECISION;
            }
        }

        if (totalBorrowedValueUSD == 0) return type(uint256).max; // No debt means max health

        // Health Factor = (Total Collateral Value USD * PERCENTAGE_FACTOR) / Total Borrowed Value USD
        // This gives a ratio scaled to 10000. For example, if collateral is 1.5x debt, HF is 15000.
        return (totalCollateralValueUSD * PERCENTAGE_FACTOR) / totalBorrowedValueUSD;
    }

    // @notice Internal function to update a user's ChronosPoints and re-evaluate their FlowTier.
    // @param user The address of the user.
    // @param points The amount of points to add or remove.
    // @param increase True to add points, false to remove points.
    function _updateChronosPoints(address user, uint256 points, bool increase) internal {
        if (increase) {
            userAccounts[user].chronosPoints += points;
        } else {
            if (userAccounts[user].chronosPoints < points) {
                userAccounts[user].chronosPoints = 0;
            } else {
                userAccounts[user].chronosPoints -= points;
            }
        }
        
        uint256 newTier = getFlowTier(user);
        if (newTier != userAccounts[user].flowTier) {
            userAccounts[user].flowTier = newTier;
            emit FlowTierUpdated(user, newTier);
            // Example: Automatically mint an AetherBadge upon reaching a specific tier
            // This would require a mapping of tier IDs to badge IDs.
            // if (newTier == 1) { // Example: Mint badge 101 for reaching Tier 1
            //     aetherBadgeNFT.mint(user, 101);
            //     emit AetherBadgeMinted(user, 101);
            // }
        }
        emit ChronosPointsUpdated(user, userAccounts[user].chronosPoints);
    }

    // @notice Accumulates interest on a reserve's total borrowed amount.
    // This is a simplified linear interest model. Real protocols use more complex rate models.
    // @param asset The address of the asset reserve to update.
    function _updateReserveInterest(address asset) internal {
        ReserveData storage reserve = reserves[asset];
        uint256 timeElapsed = block.timestamp - reserve.lastUpdateTimestamp;
        if (timeElapsed == 0) return;

        uint256 secondsInYear = 365 days; // Approximately 31,536,000 seconds
        
        // Interest accrued = Total Borrowed * Base Interest Rate (annual) * Time Elapsed / Seconds in Year
        // Rates are scaled by PERCENTAGE_FACTOR (10000), so divide by it.
        uint256 interestAccrued = (reserve.totalBorrowed * reserve.baseInterestRate * timeElapsed) / (PERCENTAGE_FACTOR * secondsInYear);
        reserve.totalBorrowed += interestAccrued; // Add accrued interest to the total borrowed amount in the reserve

        reserve.lastUpdateTimestamp = block.timestamp;
    }

    // @notice Calculates the current total loan amount for a user, including accumulated interest.
    // @param user The address of the user.
    // @param asset The address of the loan asset.
    // @return The total loan amount (principal + interest).
    function _calculateCurrentLoanInterest(address user, address asset) internal view returns (uint256) {
        Loan storage loan = userAccounts[user].activeLoans[asset];
        if (loan.amount == 0) return 0; // No active loan

        uint256 timeElapsed = block.timestamp - loan.borrowedTimestamp;
        if (timeElapsed == 0) return loan.amount; // No time elapsed, no interest yet

        uint256 secondsInYear = 365 days;
        // Interest accrued on *this specific loan* = Loan Amount * Rate at Borrow * Time Elapsed / Seconds in Year
        uint252 interestAccrued = (loan.amount * loan.interestRateAtBorrow * timeElapsed) / (PERCENTAGE_FACTOR * secondsInYear);
        return loan.amount + interestAccrued;
    }

    // Fallback function to prevent accidental Ether transfers, unless explicitly handled for specific use cases.
    receive() external payable {
        revert("ChronosFlow: Ether transfers not supported");
    }
}
```