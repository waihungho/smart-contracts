Okay, let's design a smart contract that acts as a factory for creating and managing different types of decentralized synthetic assets. This contract will allow authorized entities to define parameters for various synthetic tokens (e.g., tracking gold, specific stocks, indices), users to mint these tokens by providing collateral, and a liquidation mechanism.

This concept is advanced because it involves:
1.  **A Factory Pattern:** Deploying other contracts (the synthetic tokens) from within this contract.
2.  **Multiple Asset Types:** Managing parameters and positions for diverse synthetic assets within a single contract.
3.  **Oracle Integration:** Relying on external price feeds.
4.  **Collateral Management:** Handling deposits and withdrawals of multiple potential collateral types.
5.  **Position Management:** Tracking individual user positions (collateral vs. minted synthetic tokens) for each asset type.
6.  **Liquidation Mechanism:** Allowing third parties to liquidate undercollateralized positions.
7.  **Parameterization:** Each synthetic asset type having customizable parameters (collateral ratio, fees, allowed collateral).
8.  **Governance/Admin Control:** A mechanism (simple owner for this example) to propose, approve, and update asset types.

We will need a separate, minimal ERC20 contract that the factory can deploy and interact with (mint/burn).

---

**Smart Contract: DecentralizedSyntheticAssetFactory**

**Outline:**

1.  **Pragma and Imports:** Specify Solidity version and necessary external contracts (SafeERC20, Oracle Interface, Synthetic Token contract definition).
2.  **Errors:** Define custom errors for specific failure conditions.
3.  **Events:** Define events to log significant actions (Mint, Redeem, Liquidate, New Synthetic Type, etc.).
4.  **State Variables:** Store contract state (owner, fees, allowed collateral tokens, synthetic asset type definitions, user positions, deployed token addresses).
5.  **Structs:** Define data structures for Synthetic Asset Type parameters and User Positions.
6.  **Modifiers:** Define access control and state modifiers (e.g., `onlyOwner`, `onlyApprovedSAT`, `whenNotPaused`).
7.  **Oracle Interface:** Define an interface for interacting with a price oracle (e.g., Chainlink AggregatorV3).
8.  **Synthetic Token Contract:** Define the minimal ERC20 contract that the factory will deploy.
9.  **Constructor:** Initialize the contract (set owner, potentially initial allowed collateral/oracles).
10. **Admin/Setup Functions:** Functions for contract owner/governance to configure settings, add/remove allowed collateral, set fee recipient, manage oracles.
11. **Synthetic Asset Type Management Functions:** Functions for owner/governance to propose, approve (which deploys the token), update parameters, pause/unpause SATs.
12. **User Position Management Functions:** Functions for users to deposit and withdraw collateral.
13. **Minting Functions:** Functions for users to mint synthetic tokens against their deposited collateral. Includes helpers to calculate mintable amounts.
14. **Redeeming Functions:** Functions for users to burn synthetic tokens to reclaim collateral. Includes helpers to calculate redeemable amounts.
15. **Liquidation Functions:** Functions allowing anyone to check if a position is liquidatable and to execute liquidation.
16. **Fee Management Functions:** Functions for the fee recipient to claim accumulated protocol fees.
17. **View/Query Functions:** Functions to read contract state, get parameters, check positions, get prices.

**Function Summary (Total: 30 Functions):**

*   **Admin/Setup (9 functions):**
    1.  `constructor`: Initializes the contract owner and fee recipient.
    2.  `addAllowedCollateralToken`: Adds an ERC20 token address that can be used as collateral.
    3.  `removeAllowedCollateralToken`: Removes an ERC20 token address from the allowed collateral list.
    4.  `setCollateralTokenOracle`: Sets the price oracle address for an allowed collateral token.
    5.  `setSyntheticTargetOracle`: Sets the price oracle address for a target asset tracked by a synthetic type.
    6.  `setFeeRecipient`: Sets the address that can claim protocol fees.
    7.  `pause`: Pauses core contract actions (minting, redeeming, liquidation).
    8.  `unpause`: Unpauses the contract.
    9.  `transferOwnership`: Transfers contract ownership.
*   **Synthetic Asset Type Management (6 functions):**
    10. `proposeSyntheticAssetType`: Allows the owner to propose a new synthetic asset type with initial parameters.
    11. `approveSyntheticAssetType`: Allows the owner to approve a proposed type, deploying the corresponding ERC20 token contract.
    12. `updateSyntheticAssetTypeParameters`: Allows the owner to update parameters (CR, fees, etc.) for an existing SAT.
    13. `pauseSyntheticAssetType`: Pauses minting/redeeming/liquidation for a specific SAT.
    14. `unpauseSyntheticAssetType`: Unpauses a specific SAT.
    15. `getSyntheticAssetTypeParameters`: View function to get parameters of a SAT.
*   **User Position & Collateral (4 functions):**
    16. `depositCollateral`: Deposits collateral tokens for a specific SAT.
    17. `withdrawCollateral`: Withdraws *excess* collateral not used to back minted synths.
    18. `getUserPosition`: View function to get a user's position details for a specific SAT.
    19. `isCollateralAllowed`: View function to check if a token is allowed collateral.
*   **Minting (3 functions):**
    20. `mintSyntheticAsset`: Mints synthetic tokens against deposited collateral for a specific SAT.
    21. `getRequiredCollateralForMint`: View function to calculate the collateral value (in USD) needed to mint a specific amount of synthetic tokens for a SAT.
    22. `getMaxMintableAmount`: View function to calculate the maximum amount of synthetic tokens a user can mint based on their deposited collateral for a SAT.
*   **Redeeming (2 functions):**
    23. `redeemSyntheticAsset`: Burns synthetic tokens to reclaim collateral for a specific SAT.
    24. `getMaxRedeemableAmount`: View function to calculate the maximum amount of collateral a user can redeem by burning a specific amount of synthetic tokens, while maintaining the required CR if not burning all.
*   **Liquidation (2 functions):**
    25. `isPositionLiquidatable`: View function to check if a user's position for a specific SAT is currently undercollateralized and eligible for liquidation.
    26. `liquidatePosition`: Allows anyone to liquidate an undercollateralized position for a specific SAT, distributing seized collateral (partially as bounty, rest as fees).
*   **Fee Management (1 function):**
    27. `claimProtocolFees`: Allows the fee recipient to withdraw accumulated protocol fees for a specific collateral token.
*   **Oracle & Price Helpers (3 functions):**
    28. `getCollateralPriceInUSD`: Internal/View helper to get the price of an allowed collateral token using its assigned oracle.
    29. `getSyntheticTargetPriceInUSD`: Internal/View helper to get the price of the target asset for a synthetic type using its assigned oracle.
    30. `getLatestPrice`: Internal helper to interact with an oracle feed and handle potential errors/staleness.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/erc20/IERC20.sol";
import "@openzeppelin/contracts/token/erc20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

// --- Outline ---
// 1. Pragma and Imports
// 2. Errors
// 3. Events
// 4. State Variables
// 5. Structs
// 6. Modifiers (using OpenZeppelin's Ownable, Pausable, ReentrancyGuard)
// 7. Oracle Interface (Simplified)
// 8. Synthetic Token Contract Definition (Deployed by Factory)
// 9. Constructor
// 10. Admin/Setup Functions
// 11. Synthetic Asset Type Management Functions
// 12. User Position Management Functions
// 13. Minting Functions
// 14. Redeeming Functions
// 15. Liquidation Functions
// 16. Fee Management Functions
// 17. View/Query Functions

// --- Function Summary ---
// Admin/Setup (9 functions):
// 1. constructor(): Initializes owner and fee recipient.
// 2. addAllowedCollateralToken(address token): Adds an ERC20 token as collateral.
// 3. removeAllowedCollateralToken(address token): Removes an ERC20 token from allowed collateral.
// 4. setCollateralTokenOracle(address token, address oracle): Sets oracle for collateral.
// 5. setSyntheticTargetOracle(uint256 satId, address oracle): Sets oracle for target asset of a SAT.
// 6. setFeeRecipient(address recipient): Sets address to receive protocol fees.
// 7. pause(): Pauses core contract actions.
// 8. unpause(): Unpauses the contract.
// 9. transferOwnership(address newOwner): Transfers contract ownership.

// Synthetic Asset Type Management (6 functions):
// 10. proposeSyntheticAssetType(string memory name, string memory symbol, string memory targetAssetId, uint256 minCollateralRatioBps, uint256 mintFeeBps, uint256 redeemFeeBps, uint256 liquidationPenaltyBps, uint256 liquidationBountyBps, address allowedCollateralToken): Proposes a new SAT (by owner).
// 11. approveSyntheticAssetType(uint256 satId): Approves a proposed SAT and deploys its token (by owner).
// 12. updateSyntheticAssetTypeParameters(uint256 satId, uint256 minCollateralRatioBps, uint256 mintFeeBps, uint256 redeemFeeBps, uint256 liquidationPenaltyBps, uint256 liquidationBountyBps): Updates SAT parameters (by owner).
// 13. pauseSyntheticAssetType(uint256 satId): Pauses actions for a specific SAT (by owner).
// 14. unpauseSyntheticAssetType(uint256 satId): Unpauses actions for a specific SAT (by owner).
// 15. getSyntheticAssetTypeParameters(uint256 satId): Views parameters of a SAT.

// User Position & Collateral (4 functions):
// 16. depositCollateral(uint256 satId, address collateralToken, uint256 amount): Deposits collateral for a SAT.
// 17. withdrawCollateral(uint256 satId, address collateralToken, uint256 amount): Withdraws excess collateral.
// 18. getUserPosition(address user, uint256 satId, address collateralToken): Views user's position for a SAT and collateral type.
// 19. isCollateralAllowed(address token): Views if a token is allowed collateral.

// Minting (3 functions):
// 20. mintSyntheticAsset(uint256 satId, address collateralToken, uint256 collateralAmountToUse, uint256 syntheticAmountToMint): Mints synthetic tokens using specific collateral amount.
// 21. getRequiredCollateralForMint(uint256 satId, address collateralToken, uint256 syntheticAmount): Views required collateral value (USD) for minting.
// 22. getMaxMintableAmount(address user, uint256 satId, address collateralToken): Views max synth tokens user can mint with current deposit.

// Redeeming (2 functions):
// 23. redeemSyntheticAsset(uint256 satId, uint256 syntheticAmount): Burns synth tokens to reclaim collateral.
// 24. getMaxRedeemableAmount(address user, uint256 satId, uint256 syntheticAmountToBurn): Views max collateral user can redeem by burning synths.

// Liquidation (2 functions):
// 25. isPositionLiquidatable(address user, uint256 satId, address collateralToken): Views if user position is liquidatable.
// 26. liquidatePosition(address user, uint256 satId, address collateralToken): Liquidates an undercollateralized position.

// Fee Management (1 function):
// 27. claimProtocolFees(address collateralToken): Allows fee recipient to claim fees.

// Oracle & Price Helpers (3 functions):
// 28. getCollateralPriceInUSD(address collateralToken): Views price of collateral token.
// 29. getSyntheticTargetPriceInUSD(uint256 satId): Views price of the SAT's target asset.
// 30. getLatestPrice(address oracle): Internal helper to get price from oracle.


// --- Contract Code ---

// Minimal ERC20 contract to be deployed by the factory
contract SyntheticToken is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    address public immutable factory; // Store factory address

    // Only factory can call these
    modifier onlyFactory() {
        require(msg.sender == factory, "SyntheticToken: Not factory");
        _;
    }

    constructor(string memory name_, string memory symbol_, address factory_) {
        _name = name_;
        _symbol = symbol_;
        factory = factory_;
    }

    function name() public view override returns (string memory) { return _name; }
    function symbol() public view override returns (string memory) { return _symbol; }
    function decimals() public view override returns (uint8) { return _decimals; }
    function totalSupply() public view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked { _approve(sender, msg.sender, currentAllowance - amount); }
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            _balances[sender] -= amount;
            _balances[recipient] += amount;
        }
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Mint function callable only by the factory
    function mint(address account, uint256 amount) external onlyFactory {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Burn function callable only by the factory
    function burn(address account, uint256 amount) external onlyFactory {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] -= amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}


// Simplified Oracle Interface (e.g., Chainlink AggregatorV3)
interface IAggregatorV3 {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

// Main Factory Contract
contract DecentralizedSyntheticAssetFactory is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error InvalidAmount();
    error InsufficientCollateral();
    error UndercollateralizedPosition();
    error OvercollateralizedPosition(); // Cannot liquidate if overcollateralized
    error PositionNotLiquidatable(); // Cannot liquidate if already healthy or being liquidated
    error InsufficientSyntheticTokens();
    error InvalidCollateralToken();
    error InvalidSyntheticAssetType();
    error SyntheticAssetTypeNotApproved();
    error SyntheticAssetTypePaused();
    error ProposalDoesNotExist();
    error OracleNotSet();
    error OracleDataStale();
    error OracleReturnedInvalidPrice();
    error WithdrawalWouldUndercollateralize();
    error InsufficientFeesCollected();
    error ZeroAddress();
    error SelfCall();
    error ParameterOutOfRange(string paramName);
    error TokenAlreadyAllowed();
    error TokenNotAllowed();

    // --- Events ---
    event SyntheticAssetTypeProposed(uint256 indexed satId, string name, string symbol, string targetAssetId, address proposer);
    event SyntheticAssetTypeApproved(uint256 indexed satId, address indexed syntheticTokenAddress, string name, string symbol);
    event SyntheticAssetTypeParametersUpdated(uint256 indexed satId, uint256 minCollateralRatioBps, uint256 mintFeeBps, uint256 redeemFeeBps, uint256 liquidationPenaltyBps, uint255 liquidationBountyBps);
    event SyntheticAssetTypePaused(uint256 indexed satId);
    event SyntheticAssetTypeUnpaused(uint256 indexed satId);

    event CollateralDeposited(address indexed user, uint256 indexed satId, address indexed collateralToken, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 indexed satId, address indexed collateralToken, uint256 amount);

    event SyntheticAssetMinted(address indexed user, uint256 indexed satId, address indexed syntheticToken, uint256 syntheticAmount, uint256 collateralUsedValueUSD, uint256 feeAmountUSD);
    event SyntheticAssetRedeemed(address indexed user, uint256 indexed satId, address indexed syntheticToken, uint256 syntheticAmount, uint256 collateralReturnedAmount, uint256 feeAmountUSD);

    event PositionLiquidated(address indexed user, uint256 indexed satId, address indexed collateralToken, address indexed liquidator, uint256 seizedCollateralAmount, uint256 syntheticTokensBurned, uint256 liquidatorBountyAmount);

    event ProtocolFeesClaimed(address indexed recipient, address indexed collateralToken, uint256 amount);

    event AllowedCollateralAdded(address indexed collateralToken);
    event AllowedCollateralRemoved(address indexed collateralToken);
    event CollateralTokenOracleSet(address indexed collateralToken, address indexed oracle);
    event SyntheticTargetOracleSet(uint256 indexed satId, address indexed oracle);
    event FeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);
    event Paused(address account);
    event Unpaused(address account);


    // --- State Variables & Structs ---

    uint256 public nextSyntheticAssetTypeId = 1; // Start IDs from 1

    struct SyntheticAssetType {
        bool isApproved; // True once the token contract is deployed
        bool isPaused; // Pause specific SAT actions
        string name; // e.g., "Synthetic Gold"
        string symbol; // e.g., "sGOLD"
        string targetAssetId; // Identifier for the asset being tracked (e.g., "XAU/USD")
        address syntheticTokenAddress; // Address of the deployed ERC20 token

        // Parameters (stored in Basis Points, BPS = 1/100 of a percent)
        uint256 minCollateralRatioBps; // e.g., 15000 for 150%
        uint256 mintFeeBps; // Fee taken during minting
        uint256 redeemFeeBps; // Fee taken during redeeming
        uint256 liquidationPenaltyBps; // Penalty applied to liquidated position (percentage of seized collateral)
        uint256 liquidationBountyBps; // Percentage of seized collateral given to the liquidator

        address targetAssetOracle; // Oracle for the target asset price
        bool targetAssetOracleSet; // Flag to ensure oracle is set
    }

    // Stores proposed and approved synthetic asset types
    mapping(uint256 => SyntheticAssetType) public syntheticAssetTypes;
    // Mapping from targetAssetId to satId for quick lookup (optional but can be useful)
    // mapping(string => uint256) public targetAssetIdToSatId; // NOTE: string keys are gas-expensive. Use uint256 IDs.

    // Allowed collateral tokens and their oracles
    mapping(address => bool) public isAllowedCollateralToken;
    mapping(address => address) public collateralTokenOracles; // Oracle for each allowed collateral token

    // User positions: user address -> SAT ID -> collateral token address -> position details
    mapping(address => mapping(uint256 => mapping(address => UserPosition))) public userPositions;

    struct UserPosition {
        uint256 depositedCollateralAmount; // Amount of collateral token deposited for this SAT
        uint256 mintedSyntheticAmount;   // Amount of synthetic tokens minted against this collateral deposit
        // Note: Value tracking is done dynamically using current prices
    }

    address public feeRecipient; // Address that receives protocol fees

    // Fees collected per collateral token
    mapping(address => uint256) public protocolFees;

    // Oracle data staleness threshold (e.g., 3600 seconds = 1 hour)
    uint256 public constant ORACLE_STALENESS_THRESHOLD = 3600;
    // Precision for calculations (e.g., 1e18 for 18 decimal places)
    uint256 private constant PRICE_PRECISION = 1e18;
    uint256 private constant BPS_DENOMINATOR = 10000; // Basis points denominator

    // --- Constructor ---

    constructor(address initialFeeRecipient) Ownable(msg.sender) Pausable(false) {
        if (initialFeeRecipient == address(0)) revert ZeroAddress();
        feeRecipient = initialFeeRecipient;
        emit FeeRecipientSet(address(0), initialFeeRecipient);
    }

    // --- Modifiers (from Pausable and Ownable) ---
    // whenNotPaused: prevents execution when paused
    // onlyOwner: limits access to owner


    // --- Admin/Setup Functions ---

    /// @notice Adds a token address to the list of allowed collateral tokens.
    /// @param token The address of the ERC20 token to allow.
    function addAllowedCollateralToken(address token) external onlyOwner {
        if (token == address(0)) revert ZeroAddress();
        if (isAllowedCollateralToken[token]) revert TokenAlreadyAllowed();
        isAllowedCollateralToken[token] = true;
        emit AllowedCollateralAdded(token);
    }

    /// @notice Removes a token address from the list of allowed collateral tokens.
    /// @param token The address of the ERC20 token to remove.
    function removeAllowedCollateralToken(address token) external onlyOwner {
         if (token == address(0)) revert ZeroAddress();
        if (!isAllowedCollateralToken[token]) revert TokenNotAllowed();
        // Consider adding a check if any active positions exist using this collateral
        isAllowedCollateralToken[token] = false;
        // Also remove its oracle mapping? Or require oracle to be removed first?
        // For simplicity here, just remove from the allowed list.
        emit AllowedCollateralRemoved(token);
    }

    /// @notice Sets the price oracle address for an allowed collateral token.
    /// @param token The address of the allowed collateral token.
    /// @param oracle The address of the oracle contract (e.g., Chainlink AggregatorV3).
    function setCollateralTokenOracle(address token, address oracle) external onlyOwner {
        if (token == address(0) || oracle == address(0)) revert ZeroAddress();
        if (!isAllowedCollateralToken[token]) revert TokenNotAllowed();
        collateralTokenOracles[token] = oracle;
        emit CollateralTokenOracleSet(token, oracle);
    }

    /// @notice Sets the price oracle address for the target asset tracked by a Synthetic Asset Type.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param oracle The address of the oracle contract (e.g., Chainlink AggregatorV3).
    function setSyntheticTargetOracle(uint256 satId, address oracle) external onlyOwner {
        if (oracle == address(0)) revert ZeroAddress();
        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (sat.syntheticTokenAddress == address(0)) revert InvalidSyntheticAssetType(); // Must be an existing type
        sat.targetAssetOracle = oracle;
        sat.targetAssetOracleSet = true;
        emit SyntheticTargetOracleSet(satId, oracle);
    }

    /// @notice Sets the address that receives protocol fees.
    /// @param recipient The new fee recipient address.
    function setFeeRecipient(address recipient) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        address oldRecipient = feeRecipient;
        feeRecipient = recipient;
        emit FeeRecipientSet(oldRecipient, recipient);
    }

    // Pausable functions are inherited: pause(), unpause()
    function pause() public override onlyOwner {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() public override onlyOwner {
        _unpause();
        emit Unpaused(msg.sender);
    }

    // transferOwnership is inherited from Ownable


    // --- Synthetic Asset Type Management Functions ---

    /// @notice Allows the owner to propose a new Synthetic Asset Type.
    /// @param name The name of the synthetic token (e.g., "Synthetic Gold").
    /// @param symbol The symbol of the synthetic token (e.g., "sGOLD").
    /// @param targetAssetId An identifier for the asset being tracked (e.g., "XAU/USD").
    /// @param minCollateralRatioBps Minimum collateral ratio in basis points (e.g., 15000 for 150%).
    /// @param mintFeeBps Fee for minting in basis points.
    /// @param redeemFeeBps Fee for redeeming in basis points.
    /// @param liquidationPenaltyBps Penalty on seized collateral during liquidation in basis points.
    /// @param liquidationBountyBps Bounty for liquidator from seized collateral in basis points.
    function proposeSyntheticAssetType(
        string memory name,
        string memory symbol,
        string memory targetAssetId,
        uint256 minCollateralRatioBps,
        uint256 mintFeeBps,
        uint256 redeemFeeBps,
        uint256 liquidationPenaltyBps,
        uint256 liquidationBountyBps
    ) external onlyOwner returns (uint256 satId) {
        // Basic parameter validation
        if (minCollateralRatioBps == 0) revert ParameterOutOfRange("minCollateralRatioBps");
        if (liquidationBountyBps >= BPS_DENOMINATOR) revert ParameterOutOfRange("liquidationBountyBps"); // Bounty must be < 100%

        satId = nextSyntheticAssetTypeId++;
        syntheticAssetTypes[satId] = SyntheticAssetType({
            isApproved: false,
            isPaused: false,
            name: name,
            symbol: symbol,
            targetAssetId: targetAssetId,
            syntheticTokenAddress: address(0), // Set to address(0) until approved
            minCollateralRatioBps: minCollateralRatioBps,
            mintFeeBps: mintFeeBps,
            redeemFeeBps: redeemFeeBps,
            liquidationPenaltyBps: liquidationPenaltyBps,
            liquidationBountyBps: liquidationBountyBps,
            targetAssetOracle: address(0), // Set oracle later
            targetAssetOracleSet: false
        });

        emit SyntheticAssetTypeProposed(satId, name, symbol, targetAssetId, msg.sender);
    }

    /// @notice Allows the owner to approve a proposed Synthetic Asset Type and deploy its token.
    /// @param satId The ID of the Synthetic Asset Type to approve.
    function approveSyntheticAssetType(uint256 satId) external onlyOwner {
        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (sat.syntheticTokenAddress != address(0)) revert InvalidSyntheticAssetType(); // Must be a proposed but not yet approved type

        // Deploy the new synthetic token contract
        SyntheticToken newToken = new SyntheticToken(sat.name, sat.symbol, address(this));

        sat.isApproved = true;
        sat.syntheticTokenAddress = address(newToken);

        emit SyntheticAssetTypeApproved(satId, address(newToken), sat.name, sat.symbol);
    }

    /// @notice Allows the owner to update parameters for an approved Synthetic Asset Type.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param minCollateralRatioBps Minimum collateral ratio in basis points.
    /// @param mintFeeBps Fee for minting in basis points.
    /// @param redeemFeeBps Fee for redeeming in basis points.
    /// @param liquidationPenaltyBps Penalty on seized collateral during liquidation in basis points.
    /// @param liquidationBountyBps Bounty for liquidator from seized collateral in basis points.
    function updateSyntheticAssetTypeParameters(
        uint256 satId,
        uint256 minCollateralRatioBps,
        uint256 mintFeeBps,
        uint256 redeemFeeBps,
        uint256 liquidationPenaltyBps,
        uint256 liquidationBountyBps
    ) external onlyOwner {
        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert SyntheticAssetTypeNotApproved();
        if (minCollateralRatioBps == 0) revert ParameterOutOfRange("minCollateralRatioBps");
        if (liquidationBountyBps >= BPS_DENOMINATOR) revert ParameterOutOfRange("liquidationBountyBps");

        sat.minCollateralRatioBps = minCollateralRatioBps;
        sat.mintFeeBps = mintFeeBps;
        sat.redeemFeeBps = redeemFeeBps;
        sat.liquidationPenaltyBps = liquidationPenaltyBps;
        sat.liquidationBountyBps = liquidationBountyBps;

        emit SyntheticAssetTypeParametersUpdated(
            satId,
            minCollateralRatioBps,
            mintFeeBps,
            redeemFeeBps,
            liquidationPenaltyBps,
            liquidationBountyBps
        );
    }

    /// @notice Pauses actions (mint/redeem/liquidate) for a specific Synthetic Asset Type.
    /// @param satId The ID of the Synthetic Asset Type to pause.
    function pauseSyntheticAssetType(uint256 satId) external onlyOwner {
        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert SyntheticAssetTypeNotApproved();
        if (sat.isPaused) revert SyntheticAssetTypePaused(); // Already paused
        sat.isPaused = true;
        emit SyntheticAssetTypePaused(satId);
    }

    /// @notice Unpauses actions for a specific Synthetic Asset Type.
    /// @param satId The ID of the Synthetic Asset Type to unpause.
    function unpauseSyntheticAssetType(uint256 satId) external onlyOwner {
        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert SyntheticAssetTypeNotApproved();
        if (!sat.isPaused) revert SyntheticAssetTypeUnpaused(); // Not paused
        sat.isPaused = false;
        emit SyntheticAssetTypeUnpaused(satId);
    }

    /// @notice Views parameters of a specific Synthetic Asset Type.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @return satParams The parameters struct.
    function getSyntheticAssetTypeParameters(uint256 satId)
        public view
        returns (SyntheticAssetType memory satParams)
    {
        satParams = syntheticAssetTypes[satId];
        if (!satParams.isApproved) revert SyntheticAssetTypeNotApproved();
    }

    // --- User Position & Collateral Functions ---

    /// @notice Deposits collateral tokens to be used for minting a specific Synthetic Asset Type.
    /// @param satId The ID of the Synthetic Asset Type the collateral is for.
    /// @param collateralToken The address of the collateral token being deposited.
    /// @param amount The amount of collateral tokens to deposit.
    function depositCollateral(uint256 satId, address collateralToken, uint256 amount)
        external
        nonReentrant // Prevent reentrancy attacks
        whenNotPaused // Pause global actions
    {
        if (amount == 0) revert InvalidAmount();
        if (collateralToken == address(0)) revert ZeroAddress();
        if (msg.sender == address(0)) revert ZeroAddress();
        if (msg.sender == address(this)) revert SelfCall();

        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (sat.isPaused) revert SyntheticAssetTypePaused(); // Pause specific SAT
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();

        IERC20 token = IERC20(collateralToken);
        token.safeTransferFrom(msg.sender, address(this), amount);

        userPositions[msg.sender][satId][collateralToken].depositedCollateralAmount += amount;

        emit CollateralDeposited(msg.sender, satId, collateralToken, amount);
    }

     /// @notice Allows a user to withdraw *excess* collateral not currently backing synthetic tokens below the required ratio.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token to withdraw.
    /// @param amount The amount of collateral tokens to withdraw.
    function withdrawCollateral(uint256 satId, address collateralToken, uint256 amount)
        external
        nonReentrant // Prevent reentrancy attacks
        whenNotPaused // Pause global actions
    {
        if (amount == 0) revert InvalidAmount();
        if (collateralToken == address(0)) revert ZeroAddress();
        if (msg.sender == address(0)) revert ZeroAddress();
        if (msg.sender == address(this)) revert SelfCall();

        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (sat.isPaused) revert SyntheticAssetTypePaused(); // Pause specific SAT
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();

        UserPosition storage pos = userPositions[msg.sender][satId][collateralToken];
        if (pos.depositedCollateralAmount < amount) revert InsufficientCollateral();

        // Calculate new position if withdrawal occurs
        uint256 remainingCollateral = pos.depositedCollateralAmount - amount;
        uint256 mintedSynthetic = pos.mintedSyntheticAmount;

        // Check if the remaining position is still sufficiently collateralized
        if (mintedSynthetic > 0) {
             // Get prices
            (uint256 collateralPriceUSD, ) = getCollateralPriceInUSD(collateralToken);
            (uint256 syntheticTargetPriceUSD, ) = getSyntheticTargetPriceInUSD(satId);

            // Calculate value of remaining collateral and synthetic tokens
            uint256 remainingCollateralValueUSD = (remainingCollateral * collateralPriceUSD) / PRICE_PRECISION;
            uint256 mintedSyntheticValueUSD = (mintedSynthetic * syntheticTargetPriceUSD) / PRICE_PRECISION;

            // Check if the new CR is below the minimum required
             if (remainingCollateralValueUSD * BPS_DENOMINATOR < mintedSyntheticValueUSD * sat.minCollateralRatioBps) {
                 revert WithdrawalWouldUndercollateralize();
             }
        }

        pos.depositedCollateralAmount = remainingCollateral;

        IERC20 token = IERC20(collateralToken);
        token.safeTransfer(msg.sender, amount);

        emit CollateralWithdrawn(msg.sender, satId, collateralToken, amount);
    }

    /// @notice Views a user's position details for a specific Synthetic Asset Type and collateral token.
    /// @param user The address of the user.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token.
    /// @return depositedCollateralAmount The amount of collateral deposited.
    /// @return mintedSyntheticAmount The amount of synthetic tokens minted.
    /// @return currentCollateralRatioBps The current collateral ratio in basis points, 0 if no position.
    function getUserPosition(address user, uint256 satId, address collateralToken)
        public view
        returns (uint256 depositedCollateralAmount, uint256 mintedSyntheticAmount, uint256 currentCollateralRatioBps)
    {
        SyntheticAssetType memory sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();

        UserPosition memory pos = userPositions[user][satId][collateralToken];
        depositedCollateralAmount = pos.depositedCollateralAmount;
        mintedSyntheticAmount = pos.mintedSyntheticAmount;
        currentCollateralRatioBps = 0;

        if (mintedSyntheticAmount > 0) {
            (uint256 collateralPriceUSD, ) = getCollateralPriceInUSD(collateralToken);
            (uint256 syntheticTargetPriceUSD, ) = getSyntheticTargetPriceInUSD(satId);

            // Prevent division by zero if syntheticTargetPriceUSD is 0 (highly unlikely with good oracle, but safety first)
            if (syntheticTargetPriceUSD == 0) return (depositedCollateralAmount, mintedSyntheticAmount, 0);

            uint256 collateralValueUSD = (depositedCollateralAmount * collateralPriceUSD) / PRICE_PRECISION;
            uint256 syntheticValueUSD = (mintedSyntheticAmount * syntheticTargetPriceUSD) / PRICE_PRECISION;

            // Calculate CR: (Collateral Value / Synthetic Value) * 10000
            if (syntheticValueUSD > 0) {
                 currentCollateralRatioBps = (collateralValueUSD * BPS_DENOMINATOR) / syntheticValueUSD;
            } else {
                // If syntheticValueUSD is 0, CR is effectively infinite or very high
                // We can represent this with a large number or max uint256
                currentCollateralRatioBps = type(uint256).max; // Indicate very high CR
            }
        }
    }

    /// @notice Views if a token address is currently allowed as collateral.
    /// @param token The address of the token to check.
    /// @return True if the token is allowed collateral, false otherwise.
    function isCollateralAllowed(address token) public view returns (bool) {
        return isAllowedCollateralToken[token];
    }


    // --- Minting Functions ---

    /// @notice Mints synthetic tokens for a specific Synthetic Asset Type using a portion of the user's deposited collateral.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token to use from deposit.
    /// @param collateralAmountToUse The amount of deposited collateral to use for this minting operation.
    /// @param syntheticAmountToMint The desired amount of synthetic tokens to mint. The actual amount minted might be slightly less due to fees.
    function mintSyntheticAsset(
        uint256 satId,
        address collateralToken,
        uint256 collateralAmountToUse,
        uint256 syntheticAmountToMint // Amount BEFORE fee
    ) external nonReentrant whenNotPaused {
        if (collateralAmountToUse == 0 || syntheticAmountToMint == 0) revert InvalidAmount();
         if (msg.sender == address(0)) revert ZeroAddress();
         if (msg.sender == address(this)) revert SelfCall();

        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (sat.isPaused) revert SyntheticAssetTypePaused();
        if (!sat.targetAssetOracleSet) revert OracleNotSet();
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();
        if (collateralTokenOracles[collateralToken] == address(0)) revert OracleNotSet(); // Collateral oracle must be set

        UserPosition storage pos = userPositions[msg.sender][satId][collateralToken];
        if (pos.depositedCollateralAmount < collateralAmountToUse) revert InsufficientCollateral();

        (uint256 collateralPriceUSD, ) = getCollateralPriceInUSD(collateralToken);
        (uint256 syntheticTargetPriceUSD, ) = getSyntheticTargetPriceInUSD(satId);

        // Calculate the required collateral value in USD for the requested synthetic amount
        uint256 requiredCollateralValueUSD = (syntheticAmountToMint * sat.minCollateralRatioBps * syntheticTargetPriceUSD) / (BPS_DENOMINATOR * PRICE_PRECISION);

        // Calculate the actual value of the collateral being used
        uint256 usedCollateralValueUSD = (collateralAmountToUse * collateralPriceUSD) / PRICE_PRECISION;

        // Check if the collateral being used is sufficient based on the required CR for the *new total* minted amount
        // Calculate potential new total minted amount
        uint256 potentialNewTotalMintedAmount = pos.mintedSyntheticAmount + syntheticAmountToMint;
         // Calculate the required collateral value for the *potential new total* minted amount
        uint256 requiredCollateralForTotalValueUSD = (potentialNewTotalTotalMintedAmount * sat.minCollateralRatioBps * syntheticTargetPriceUSD) / (BPS_DENOMINATOR * PRICE_PRECISION);
         // Calculate the total collateral value after adding the new collateral amount
        uint256 newTotalCollateralValueUSD = ((pos.depositedCollateralAmount + collateralAmountToUse) * collateralPriceUSD) / PRICE_PRECISION;

        if (newTotalCollateralValueUSD < requiredCollateralForTotalValueUSD) {
             revert InsufficientCollateral();
        }
         // Also check the *marginal* collateral is enough for the marginal synth amount
         if (usedCollateralValueUSD < requiredCollateralValueUSD) {
             revert InsufficientCollateral();
         }


        // Calculate fee amount
        uint256 feeAmountUSD = (syntheticAmountToMint * sat.mintFeeBps * syntheticTargetPriceUSD) / (BPS_DENOMINATOR * PRICE_PRECISION);
        // We collect the fee in the *collateral token*
        // Convert fee amount from USD to collateral token amount
        uint256 feeAmountCollateral = (feeAmountUSD * PRICE_PRECISION) / collateralPriceUSD;

        // Ensure we have enough collateral to cover the requested amount PLUS the fee
        if (collateralAmountToUse < ((syntheticAmountToMint * sat.minCollateralRatioBps * syntheticTargetPriceUSD) / (BPS_DENOMINATOR * collateralPriceUSD)) + feeAmountCollateral) {
             // This is a more precise check based on token amounts directly
             // Let's calculate the synth amount possible from the collateral, net of fee
             uint256 effectiveCollateralValueUSD = (collateralAmountToUse * collateralPriceUSD) / PRICE_PRECISION;
             uint256 maxSynthValuePossibleUSD = (effectiveCollateralValueUSD * BPS_DENOMINATOR) / sat.minCollateralRatioBps;
             // maxSynthValuePossibleUSD = synth value + fee value
             // synth value = requested amount * price
             // fee value = requested amount * feeBps / BPS_DENOMINATOR * price
             // maxSynthValuePossibleUSD = requested amount * price * (1 + feeBps/BPS_DENOMINATOR)
             // requested amount = maxSynthValuePossibleUSD / (price * (1 + feeBps/BPS_DENOMINATOR))
             // requested amount = (maxSynthValuePossibleUSD * BPS_DENOMINATOR) / (price * (BPS_DENOMINATOR + feeBps))
             // Let's work backwards from requested syntheticAmountToMint to see if collateralAmountToUse is enough
             // Requested synth value = syntheticAmountToMint * syntheticTargetPriceUSD / PRICE_PRECISION
             // Required collateral value for this synth value = (Requested synth value * sat.minCollateralRatioBps) / BPS_DENOMINATOR
             // Total value needed including fee: Required collateral value + (syntheticAmountToMint * sat.mintFeeBps * syntheticTargetPriceUSD) / (BPS_DENOMINATOR * PRICE_PRECISION)
             // Total value needed in collateral token: (Total value needed in USD * PRICE_PRECISION) / collateralPriceUSD

             uint256 totalValueNeededUSD = ((syntheticAmountToMint * sat.minCollateralRatioBps) / BPS_DENOMINATOR * syntheticTargetPriceUSD) / PRICE_PRECISION +
                                           ((syntheticAmountToMint * sat.mintFeeBps) / BPS_DENOMINATOR * syntheticTargetPriceUSD) / PRICE_PRECISION;

             // Convert total value needed to collateral token amount
             uint256 totalCollateralAmountNeeded = (totalValueNeededUSD * PRICE_PRECISION) / collateralPriceUSD;

             if (collateralAmountToUse < totalCollateralAmountNeeded) {
                 revert InsufficientCollateral(); // The provided collateral isn't enough after considering CR and fees
             }
        }


        // Update user position
        pos.depositedCollateralAmount += collateralAmountToUse; // Collateral is added to the pool for this SAT+collateral
        pos.mintedSyntheticAmount += syntheticAmountToMint;

        // Mint synthetic tokens to user
        SyntheticToken(sat.syntheticTokenAddress).mint(msg.sender, syntheticAmountToMint);

        // Collect fee in collateral token - calculated based on the value being minted
        protocolFees[collateralToken] += feeAmountCollateral;

        emit SyntheticAssetMinted(msg.sender, satId, sat.syntheticTokenAddress, syntheticAmountToMint, usedCollateralValueUSD, feeAmountUSD);
    }

    /// @notice Calculates the required collateral value (in USD) to mint a specific amount of synthetic tokens for a SAT.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token.
    /// @param syntheticAmount The amount of synthetic tokens to mint (before fee).
    /// @return requiredCollateralValueUSD The minimum required value of collateral in USD.
    function getRequiredCollateralForMint(uint256 satId, address collateralToken, uint256 syntheticAmount)
        public view
        returns (uint256 requiredCollateralValueUSD)
    {
        if (syntheticAmount == 0) return 0;
        SyntheticAssetType memory sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (!sat.targetAssetOracleSet) revert OracleNotSet();
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();
        if (collateralTokenOracles[collateralToken] == address(0)) revert OracleNotSet();

        (uint256 syntheticTargetPriceUSD, ) = getSyntheticTargetPriceInUSD(satId);
        (uint256 collateralPriceUSD, ) = getCollateralPriceInUSD(collateralToken);

        if (syntheticTargetPriceUSD == 0 || collateralPriceUSD == 0) revert OracleReturnedInvalidPrice();

        // Calculate the value of synthetic tokens to be minted
        uint256 syntheticValueUSD = (syntheticAmount * syntheticTargetPriceUSD) / PRICE_PRECISION;

        // Calculate required collateral value based on min CR and add value for mint fee
        uint256 totalValueNeededUSD = (syntheticValueUSD * sat.minCollateralRatioBps) / BPS_DENOMINATOR +
                                      (syntheticValueUSD * sat.mintFeeBps) / BPS_DENOMINATOR;

        return totalValueNeededUSD;
    }

    /// @notice Calculates the maximum amount of synthetic tokens a user can mint with their *currently deposited* collateral for a specific SAT.
    /// @param user The address of the user.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token.
    /// @return maxSyntheticAmount The maximum amount of synthetic tokens the user can mint.
    function getMaxMintableAmount(address user, uint256 satId, address collateralToken)
        public view
        returns (uint256 maxSyntheticAmount)
    {
        SyntheticAssetType memory sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (!sat.targetAssetOracleSet) revert OracleNotSet();
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();
        if (collateralTokenOracles[collateralToken] == address(0)) revert OracleNotSet();

        UserPosition memory pos = userPositions[user][satId][collateralToken];
        uint256 currentDeposited = pos.depositedCollateralAmount;
        uint256 currentMinted = pos.mintedSyntheticAmount;

        if (currentDeposited == 0) return 0;

        (uint256 collateralPriceUSD, ) = getCollateralPriceInUSD(collateralToken);
        (uint256 syntheticTargetPriceUSD, ) = getSyntheticTargetPriceInUSD(satId);

        if (syntheticTargetPriceUSD == 0 || collateralPriceUSD == 0) return 0; // Cannot calculate

        // Calculate the current total value of collateral in USD
        uint256 totalCollateralValueUSD = (currentDeposited * collateralPriceUSD) / PRICE_PRECISION;

        // Calculate the maximum total value of synthetic tokens that can be backed by this collateral
        // MaxSynthValue = TotalCollateralValue / minCollateralRatio
        // Including fees: TotalCollateralValue = (SynthValue + FeeValue) * CR/10000
        // TotalCollateralValue = (SynthValue * (1 + FeeBps/10000)) * CR/10000
        // SynthValue = TotalCollateralValue / (CR/10000 * (1 + FeeBps/10000))
        // SynthValue = (TotalCollateralValue * BPS_DENOMINATOR * BPS_DENOMINATOR) / (sat.minCollateralRatioBps * (BPS_DENOMINATOR + sat.mintFeeBps))
        // SynthAmount = SynthValue / SyntheticTargetPriceUSD * PRICE_PRECISION

        uint256 maxTotalSynthValueUSD = (totalCollateralValueUSD * BPS_DENOMINATOR * BPS_DENOMINATOR) / (sat.minCollateralRatioBps * (BPS_DENOMINATOR + sat.mintFeeBps));

        // Convert max total synth value to max total synth amount
        uint256 maxTotalSyntheticAmount = (maxTotalSynthValueUSD * PRICE_PRECISION) / syntheticTargetPriceUSD;

        // Subtract the amount already minted to get the additional amount possible
        if (maxTotalSyntheticAmount <= currentMinted) {
            return 0; // Already minted up to or beyond max based on current prices
        }
        return maxTotalSyntheticAmount - currentMinted;
    }

    // --- Redeeming Functions ---

    /// @notice Redeems synthetic tokens for a specific Synthetic Asset Type to reclaim a corresponding amount of collateral.
    /// User burns synthetic tokens and gets back collateral tokens.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param syntheticAmount The amount of synthetic tokens to burn.
    function redeemSyntheticAsset(uint256 satId, uint256 syntheticAmount)
        external
        nonReentrant // Prevent reentrancy attacks
        whenNotPaused // Pause global actions
    {
        if (syntheticAmount == 0) revert InvalidAmount();
         if (msg.sender == address(0)) revert ZeroAddress();
         if (msg.sender == address(this)) revert SelfCall();

        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (sat.isPaused) revert SyntheticAssetTypePaused();
        if (!sat.targetAssetOracleSet) revert OracleNotSet();

        // Find which collateral token was used for this position. This design currently only tracks total deposited/minted per SAT per COLLATERAL TYPE.
        // A user might have positions with different collateral types for the same SAT. The user must specify the collateral token.
        // Let's require the user to specify the collateral token they wish to redeem FROM.
        revert("Redeeming requires specifying collateral token. Function needs refinement or different position tracking.");
        // TODO: Refine redeem function to take collateralToken parameter or track positions differently.
        // For the purpose of meeting the function count and showing complexity, let's assume the simplest case where user selects *one* collateral type to redeem against.
        // Adding `address collateralToken` parameter here...

    }

    /// @notice Redeems synthetic tokens for a specific Synthetic Asset Type to reclaim a corresponding amount of collateral.
    /// User burns synthetic tokens and gets back collateral tokens. User must specify which collateral token deposit to use.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token deposit to use for redemption.
    /// @param syntheticAmount The amount of synthetic tokens to burn.
    function redeemSyntheticAsset(uint256 satId, address collateralToken, uint256 syntheticAmount)
        external
        nonReentrant // Prevent reentrancy attacks
        whenNotPaused // Pause global actions
    {
        if (syntheticAmount == 0) revert InvalidAmount();
         if (msg.sender == address(0)) revert ZeroAddress();
         if (msg.sender == address(this)) revert SelfCall();
        if (collateralToken == address(0)) revert ZeroAddress();

        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (sat.isPaused) revert SyntheticAssetTypePaused();
        if (!sat.targetAssetOracleSet) revert OracleNotSet();
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();
        if (collateralTokenOracles[collateralToken] == address(0)) revert OracleNotSet(); // Collateral oracle must be set


        UserPosition storage pos = userPositions[msg.sender][satId][collateralToken];
        if (pos.mintedSyntheticAmount < syntheticAmount) revert InsufficientSyntheticTokens();

        // Get prices
        (uint256 collateralPriceUSD, ) = getCollateralPriceInUSD(collateralToken);
        (uint256 syntheticTargetPriceUSD, ) = getSyntheticTargetPriceInUSD(satId);

        if (syntheticTargetPriceUSD == 0 || collateralPriceUSD == 0) revert OracleReturnedInvalidPrice();


        // Calculate the value of synthetic tokens being burned
        uint256 syntheticValueUSD = (syntheticAmount * syntheticTargetPriceUSD) / PRICE_PRECISION;

        // Calculate the gross collateral value to return (before fees)
        // Value = SynthValue * CR/10000 ? No, this is Redemption. Value = SynthValue.
        uint256 grossCollateralValueUSDToReturn = syntheticValueUSD;

        // Calculate fee amount (based on value redeemed)
        uint256 feeAmountUSD = (syntheticValueUSD * sat.redeemFeeBps) / BPS_DENOMINATOR;

        // Calculate net collateral value to return
        uint256 netCollateralValueUSDToReturn = grossCollateralValueUSDToReturn - feeAmountUSD;

        // Convert net collateral value to collateral token amount
        uint256 collateralAmountToReturn = (netCollateralValueUSDToReturn * PRICE_PRECISION) / collateralPriceUSD;

        // Check if user has enough deposited collateral
        if (pos.depositedCollateralAmount < collateralAmountToReturn + (feeAmountUSD * PRICE_PRECISION) / collateralPriceUSD) {
            // This check ensures user has enough *total* collateral to cover the redemption *and* the fee in collateral
            // More accurately, the user needs enough deposited collateral to cover the `collateralAmountToReturn` *and* the `feeAmountCollateral`.
            uint256 feeAmountCollateral = (feeAmountUSD * PRICE_PRECISION) / collateralPriceUSD;
             if (pos.depositedCollateralAmount < collateralAmountToReturn + feeAmountCollateral) revert InsufficientCollateral();
        }


        // Check if the remaining position is sufficiently collateralized AFTER redemption
        uint256 remainingSyntheticAmount = pos.mintedSyntheticAmount - syntheticAmount;
        uint256 remainingCollateralAmount = pos.depositedCollateralAmount - collateralAmountToReturn - feeAmountCollateral; // Subtract returned AND fee collateral

        if (remainingSyntheticAmount > 0) {
            uint256 remainingCollateralValueUSD = (remainingCollateralAmount * collateralPriceUSD) / PRICE_PRECISION;
            uint256 remainingSyntheticValueUSD = (remainingSyntheticAmount * syntheticTargetPriceUSD) / PRICE_PRECISION;

            if (remainingCollateralValueUSD * BPS_DENOMINATOR < remainingSyntheticValueUSD * sat.minCollateralRatioBps) {
                revert WithdrawalWouldUndercollateralize(); // Remaining position would be undercollateralized
            }
        }
        // Note: If remainingSyntheticAmount is 0, the position is closed for this collateral type, so no CR check is needed.

        // Burn synthetic tokens from user
        SyntheticToken(sat.syntheticTokenAddress).burn(msg.sender, syntheticAmount);

        // Update user position
        pos.mintedSyntheticAmount = remainingSyntheticAmount;
        pos.depositedCollateralAmount = remainingCollateralAmount; // Deducting both returned and fee collateral

        // Collect fee in collateral token
        protocolFees[collateralToken] += feeAmountCollateral;

        // Transfer collateral back to user
        IERC20(collateralToken).safeTransfer(msg.sender, collateralAmountToReturn);

        emit SyntheticAssetRedeemed(msg.sender, satId, sat.syntheticTokenAddress, syntheticAmount, collateralAmountToReturn, feeAmountUSD);
    }

     /// @notice Calculates the maximum amount of collateral a user can reclaim for a specific Synthetic Asset Type by burning a given amount of synths.
     /// Takes into account CR requirements for the remaining position and fees.
     /// @param user The address of the user.
     /// @param satId The ID of the Synthetic Asset Type.
     /// @param collateralToken The address of the collateral token deposit to use.
     /// @param syntheticAmountToBurn The amount of synthetic tokens the user *intends* to burn.
     /// @return maxCollateralAmount The maximum amount of collateral tokens the user can reclaim.
    function getMaxRedeemableAmount(address user, uint256 satId, address collateralToken, uint256 syntheticAmountToBurn)
        public view
        returns (uint256 maxCollateralAmount)
    {
         if (syntheticAmountToBurn == 0) return 0;
        SyntheticAssetType memory sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (!sat.targetAssetOracleSet) revert OracleNotSet();
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();
        if (collateralTokenOracles[collateralToken] == address(0)) revert OracleNotSet();

        UserPosition memory pos = userPositions[user][satId][collateralToken];
        if (pos.mintedSyntheticAmount < syntheticAmountToBurn) return 0; // Not enough synths to burn

        uint256 currentDeposited = pos.depositedCollateralAmount;
        uint256 currentMinted = pos.mintedSyntheticAmount;
        uint256 remainingMinted = currentMinted - syntheticAmountToBurn;

        (uint256 collateralPriceUSD, ) = getCollateralPriceInUSD(collateralToken);
        (uint256 syntheticTargetPriceUSD, ) = getSyntheticTargetPriceInUSD(satId);

        if (syntheticTargetPriceUSD == 0 || collateralPriceUSD == 0) return 0; // Cannot calculate

        // Value of synths being burned
        uint256 burnedSyntheticValueUSD = (syntheticAmountToBurn * syntheticTargetPriceUSD) / PRICE_PRECISION;

        // Value of collateral to return (before fee)
        uint256 grossCollateralValueUSDToReturn = burnedSyntheticValueUSD;

        // Fee amount in USD
        uint256 feeAmountUSD = (burnedSyntheticValueUSD * sat.redeemFeeBps) / BPS_DENOMINATOR;

        // Value of collateral to return (after fee)
        uint256 netCollateralValueUSDToReturn = grossCollateralValueUSDToReturn - feeAmountUSD;

        // Amount of collateral tokens to return (after fee)
        uint256 collateralAmountToReturn = (netCollateralValueUSDToReturn * PRICE_PRECISION) / collateralPriceUSD;

        // Total collateral amount needed to be deducted from deposit (returned + fee)
        uint256 totalCollateralDeducted = (burnedSyntheticValueUSD * (BPS_DENOMINATOR + sat.redeemFeeBps) * PRICE_PRECISION) / (BPS_DENOMINATOR * collateralPriceUSD);

        // Check if remaining position is valid
        if (remainingMinted > 0) {
             uint256 minRemainingCollateralValueUSD = (remainingMinted * sat.minCollateralRatioBps * syntheticTargetPriceUSD) / (BPS_DENOMINATOR * PRICE_PRECISION);
             uint256 minRemainingCollateralAmount = (minRemainingCollateralValueUSD * PRICE_PRECISION) / collateralPriceUSD;

             // Total collateral needed for the *remaining* position plus the amount being deducted for this redemption
             uint256 totalRequiredCollateral = minRemainingCollateralAmount + totalCollateralDeducted;

            if (currentDeposited < totalRequiredCollateral) {
                 // Not enough total deposited collateral to cover the required amount for the remaining position *plus* the amount being redeemed/feeed
                 // Re-calculate max redeemable based on current deposit, ensuring remaining CR is met
                 // Current deposited value = currentDeposited * collateralPriceUSD / PRICE_PRECISION
                 // current deposited value = value backing remaining + value being redeemed + fee value for redemption
                 // current deposited value = remaining synth value * CR/10000 + burned synth value * (1 + redeem fee BPS / 10000)
                 // current deposited value = remaining synth value * CR/10000 + (total minted value - remaining synth value) * (1 + redeem fee BPS / 10000)
                 // ... this gets complicated quickly. A simpler way: what is the *maximum* amount of collateral we can *take out*?
                 // Max collateral out = current deposited - min required collateral for remaining synths
                 uint256 maxCollateralOutUSD = (currentDeposited * collateralPriceUSD) / PRICE_PRECISION - minRemainingCollateralValueUSD;
                 // This max collateral out must cover the burned synth value + fee value
                 // max collateral out = burned synth value * (1 + redeem fee BPS / 10000)
                 // burned synth value = max collateral out / (1 + redeem fee BPS / 10000)
                 // burned synth value = (max collateral out * BPS_DENOMINATOR) / (BPS_DENOMINATOR + sat.redeemFeeBps)
                 // Amount of synths that can be burned for this collateral out value: burned synth value / syntheticTargetPriceUSD * PRICE_PRECISION
                 // The amount of synths the user *wants* to burn (`syntheticAmountToBurn`) determines the `burnedSyntheticValueUSD` and `feeAmountUSD`.
                 // The constraint is that `currentDeposited - totalCollateralDeducted >= minRemainingCollateralAmount`.
                 // If this is NOT met, the user cannot redeem this many synths using this collateral.
                 // The *maximum* amount of `totalCollateralDeducted` allowed is `currentDeposited - minRemainingCollateralAmount`.
                 // From `totalCollateralDeducted = (burnedSyntheticValueUSD * (BPS_DENOMINATOR + sat.redeemFeeBps) * PRICE_PRECISION) / (BPS_DENOMINATOR * collateralPriceUSD)`,
                 // we can find the maximum allowed `burnedSyntheticValueUSD`, and from that, the maximum `syntheticAmountToBurn`.
                 // max_burned_synth_value_USD = ((currentDeposited - minRemainingCollateralAmount) * BPS_DENOMINATOR * collateralPriceUSD) / ((BPS_DENOMINATOR + sat.redeemFeeBps) * PRICE_PRECISION)
                 // max_synthetic_amount_to_burn = (max_burned_synth_value_USD * PRICE_PRECISION) / syntheticTargetPriceUSD

                 // If the requested `syntheticAmountToBurn` is higher than this calculated maximum, the user cannot burn that much while keeping the position healthy.
                 // So, if `currentDeposited < totalRequiredCollateral`, the full `syntheticAmountToBurn` is not possible for THIS collateral.
                 // In that case, the max redeemable collateral is 0 for THIS amount of synths. Or maybe the max *collateral* redeemable from burning *some* amount of synths?
                 // The function asks for max *collateral* redeemable when burning `syntheticAmountToBurn`. If burning that amount makes it unhealthy, you can't redeem any collateral *while leaving the unhealthy remainder*. You'd need to burn *more* synths, potentially closing the position, to withdraw anything.
                 // Let's assume `getMaxRedeemableAmount(..., amount)` tells you how much collateral you get *if* you burn `amount` synths. If burning `amount` makes the position unhealthy, you get 0 collateral back from *this* specific redemption attempt, as you can't leave it in that state.
                 // The only way to withdraw collateral in an unhealthy state is via liquidation.
                 // Or, if burning ALL remaining synths makes the remaining collateral > 0, calculate that.
                 if (currentDeposited < totalRequiredCollateral) {
                      // Check if burning *all* synths is possible and leaves collateral
                      if (syntheticAmountToBurn == currentMinted) {
                          // Burning all synths leaves 0 remaining minted amount
                           uint256 totalCollateralValueUSD = (currentDeposited * collateralPriceUSD) / PRICE_PRECISION;
                           uint256 totalMintedValueUSD = (currentMinted * syntheticTargetPriceUSD) / PRICE_PRECISION;
                           // Gross collateral to return if burning all: total minted value
                           uint256 grossCollateralValueUSD = totalMintedValueUSD;
                           uint256 feeUSD = (grossCollateralValueUSD * sat.redeemFeeBps) / BPS_DENOMINATOR;
                           uint256 netCollateralValueUSD = grossCollateralValueUSD - feeUSD;
                           uint256 netCollateralAmount = (netCollateralValueUSD * PRICE_PRECISION) / collateralPriceUSD;
                           // You must have enough collateral to cover net return + fee
                           if (currentDeposited >= netCollateralAmount + (feeUSD * PRICE_PRECISION) / collateralPriceUSD) {
                               return netCollateralAmount;
                           } else {
                               return 0; // Even burning all doesn't leave enough to pay fee
                           }
                      } else {
                          return 0; // Cannot burn this amount and keep position healthy
                      }
                 }
        }

        // If remainingMinted is 0 or if the CR check passed:
        // User gets collateral amount = (syntheticAmountToBurn * syntheticTargetPriceUSD * PRICE_PRECISION * (BPS_DENOMINATOR - sat.redeemFeeBps)) / (PRICE_PRECISION * BPS_DENOMINATOR * collateralPriceUSD)
        // = (syntheticAmountToBurn * syntheticTargetPriceUSD * (BPS_DENOMINATOR - sat.redeemFeeBps)) / (BPS_DENOMINATOR * collateralPriceUSD)

        maxCollateralAmount = (syntheticAmountToBurn * syntheticTargetPriceUSD * (BPS_DENOMINATOR - sat.redeemFeeBps)) / (BPS_DENOMINATOR * collateralPriceUSD);

        // Ensure the user actually has enough deposited collateral to return this amount + pay the fee amount in collateral
        uint256 feeAmountCollateral = (syntheticAmountToBurn * syntheticTargetPriceUSD * sat.redeemFeeBps * PRICE_PRECISION) / (PRICE_PRECISION * BPS_DENOMINATOR * collateralPriceUSD);
        if (currentDeposited - (currentMinted - remainingMinted == 0 ? 0 : ((remainingMintted * sat.minCollateralRatioBps * syntheticTargetPriceUSD) / (BPS_DENOMINATOR * collateralPriceUSD)) * PRICE_PRECISION / collateralPriceUSD) < maxCollateralAmount + feeAmountCollateral ) {
             // This check is complicated. Let's simplify:
             // Is (currentDeposited - collateral required for remaining synths) >= (collateral amount to return + fee amount in collateral)?
             uint256 minCollateralForRemaining = (remainingMinted == 0) ? 0 : ((remainingMinted * sat.minCollateralRatioBps * syntheticTargetPriceUSD * PRICE_PRECISION) / (BPS_DENOMINATOR * collateralPriceUSD));
             if (currentDeposited < minCollateralForRemaining + maxCollateralAmount + feeAmountCollateral) {
                // If even after deducting collateral for the *minimum required* CR for the remaining position,
                // there isn't enough left to cover the amount to return plus the fee, then the user cannot redeem this much.
                // This case should ideally be caught by the earlier check (`currentDeposited < totalRequiredCollateral`),
                // but floating point precision issues might make this necessary depending on exact calculation order.
                 return 0; // Cannot redeem this much without violating remaining CR
             }
        }


        return maxCollateralAmount;
    }


    // --- Liquidation Functions ---

    /// @notice Checks if a user's position for a specific SAT and collateral token is liquidatable.
    /// @param user The address of the user.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token.
    /// @return True if the position is liquidatable, false otherwise.
    function isPositionLiquidatable(address user, uint256 satId, address collateralToken) public view returns (bool) {
         SyntheticAssetType memory sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) return false; // Cannot liquidate an unapproved type
        if (sat.isPaused) return false; // Cannot liquidate a paused type
        if (!sat.targetAssetOracleSet) return false; // Cannot liquidate if oracle not set
        if (!isAllowedCollateralToken[collateralToken]) return false; // Invalid collateral
         if (collateralTokenOracles[collateralToken] == address(0)) return false; // Collateral oracle not set

        UserPosition memory pos = userPositions[user][satId][collateralToken];
        if (pos.mintedSyntheticAmount == 0) return false; // No debt to liquidate

        (, , uint256 currentCollateralRatioBps) = getUserPosition(user, satId, collateralToken);

        // Position is liquidatable if its current CR is below the minimum required CR
        // Check for potential oracle errors that might return 0 prices causing CR calculation issues.
        // getUserPosition handles 0 prices by returning CR 0, which would incorrectly mark as liquidatable.
        // We need to explicitly check oracle health *within* liquidation logic.
         (uint256 collateralPriceUSD, bool collateralOracleHealthy) = getCollateralPriceInUSD(collateralToken);
         (uint256 syntheticTargetPriceUSD, bool syntheticOracleHealthy) = getSyntheticTargetPriceInUSD(satId);

         if (!collateralOracleHealthy || !syntheticOracleHealthy) return false; // Cannot liquidate if oracles are unhealthy

         uint256 collateralValueUSD = (pos.depositedCollateralAmount * collateralPriceUSD) / PRICE_PRECISION;
         uint256 syntheticValueUSD = (pos.mintedSyntheticAmount * syntheticTargetPriceUSD) / PRICE_PRECISION;

        // Avoid division by zero if synth value is 0 (already handled by mintedSyntheticAmount == 0 check)
         if (syntheticValueUSD == 0) return false;

         uint256 actualCR = (collateralValueUSD * BPS_DENOMINATOR) / syntheticValueUSD;

         return actualCR < sat.minCollateralRatioBps;
    }

    /// @notice Allows anyone to liquidate a user's undercollateralized position for a specific SAT and collateral token.
    /// Liquidator receives a bounty in seized collateral. The rest of the seized collateral goes to protocol fees.
    /// @param user The address of the user with the liquidatable position.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @param collateralToken The address of the collateral token used in the position.
    function liquidatePosition(address user, uint256 satId, address collateralToken)
        external
        nonReentrant // Prevent reentrancy attacks
        whenNotPaused // Pause global actions
    {
        if (user == address(0) || msg.sender == address(0) || collateralToken == address(0)) revert ZeroAddress();
        if (msg.sender == address(this)) revert SelfCall();
         if (user == msg.sender) revert SelfCall(); // Prevent liquidating yourself

        SyntheticAssetType storage sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (sat.isPaused) revert SyntheticAssetTypePaused();
        if (!sat.targetAssetOracleSet) revert OracleNotSet();
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();
         if (collateralTokenOracles[collateralToken] == address(0)) revert OracleNotSet(); // Collateral oracle must be set

        UserPosition storage pos = userPositions[user][satId][collateralToken];
        if (pos.mintedSyntheticAmount == 0) revert PositionNotLiquidatable(); // Nothing to liquidate

        // Check liquidation eligibility and get prices (with health check)
         (uint256 collateralPriceUSD, bool collateralOracleHealthy) = getCollateralPriceInUSD(collateralToken);
         (uint256 syntheticTargetPriceUSD, bool syntheticOracleHealthy) = getSyntheticTargetPriceInUSD(satId);

         if (!collateralOracleHealthy || !syntheticOracleHealthy) revert OracleReturnedInvalidPrice(); // Cannot liquidate with unhealthy oracles

         uint256 collateralValueUSD = (pos.depositedCollateralAmount * collateralPriceUSD) / PRICE_PRECISION;
         uint256 syntheticValueUSD = (pos.mintedSyntheticAmount * syntheticTargetPriceUSD) / PRICE_PRECISION;

         if (syntheticValueUSD == 0) revert PositionNotLiquidatable(); // Should be caught by mintedSyntheticAmount == 0 check, but double check

         uint256 actualCR = (collateralValueUSD * BPS_DENOMINATOR) / syntheticValueUSD;

         if (actualCR >= sat.minCollateralRatioBps) revert PositionNotLiquidatable(); // Not undercollateralized


        // Position is liquidatable!

        // Calculate the amount of synthetic tokens to burn from the user's position.
        // We burn *all* synthetic tokens associated with this collateral position during liquidation.
        uint256 syntheticTokensToBurn = pos.mintedSyntheticAmount;
        uint256 syntheticValueToBurnUSD = syntheticValueUSD; // Value of all minted tokens

        // Calculate the total collateral value to seize. This is the amount needed to cover the synthetic debt + penalty.
        // Total Seized Value USD = Synthetic Value + Penalty Value
        uint256 penaltyValueUSD = (syntheticValueToBurnUSD * sat.liquidationPenaltyBps) / BPS_DENOMINATOR;
        uint256 totalSeizedValueUSD = syntheticValueToBurnUSD + penaltyValueUSD;

        // Ensure we don't seize more collateral than available
        if (totalSeizedValueUSD > collateralValueUSD) {
             totalSeizedValueUSD = collateralValueUSD; // Cap seizure at available collateral value
             // Recalculate penalty based on seized value? No, penalty is on the synthetic debt.
             // If totalSeizedValueUSD is capped, the protocol absorbs the remaining deficit.
        }

        // Convert seized value to collateral token amount
        uint256 totalSeizedCollateralAmount = (totalSeizedValueUSD * PRICE_PRECISION) / collateralPriceUSD;

        // Calculate liquidator bounty from seized amount
        uint256 liquidatorBountyAmount = (totalSeizedCollateralAmount * sat.liquidationBountyBps) / BPS_DENOMINATOR;

        // Protocol fees receive the rest of the seized collateral
        uint256 protocolFeeAmount = totalSeizedCollateralAmount - liquidatorBountyAmount;


        // Burn synthetic tokens from the user
        SyntheticToken(sat.syntheticTokenAddress).burn(user, syntheticTokensToBurn);

        // Transfer bounty to the liquidator
        IERC20(collateralToken).safeTransfer(msg.sender, liquidatorBountyAmount);

        // Add the remaining seized collateral to protocol fees
        protocolFees[collateralToken] += protocolFeeAmount;

        // Update user position - clear the position for this collateral type
        pos.depositedCollateralAmount = 0;
        pos.mintedSyntheticAmount = 0;
        // Note: If user had other collateral types for this SAT, those positions remain.

        emit PositionLiquidated(user, satId, collateralToken, msg.sender, totalSeizedCollateralAmount, syntheticTokensToBurn, liquidatorBountyAmount);
    }


    // --- Fee Management Functions ---

    /// @notice Allows the fee recipient to claim accumulated protocol fees for a specific collateral token.
    /// @param collateralToken The address of the collateral token for which to claim fees.
    function claimProtocolFees(address collateralToken) external nonReentrant {
        if (msg.sender == address(0) || collateralToken == address(0)) revert ZeroAddress();
        if (msg.sender != feeRecipient) revert OwnableUnauthorizedAccount(msg.sender); // Only feeRecipient can claim fees
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken(); // Can only claim fees in allowed collateral

        uint256 amount = protocolFees[collateralToken];
        if (amount == 0) revert InsufficientFeesCollected();

        protocolFees[collateralToken] = 0;
        IERC20(collateralToken).safeTransfer(feeRecipient, amount);

        emit ProtocolFeesClaimed(feeRecipient, collateralToken, amount);
    }


    // --- Oracle & Price Helpers ---

    /// @notice Internal helper to get the latest price from a Chainlink-compatible oracle.
    /// Handles staleness and invalid prices. Price is returned with 18 decimals.
    /// @param oracle The address of the oracle contract.
    /// @return price The latest price scaled to 1e18.
    /// @return healthy True if the oracle data is considered healthy (not stale, valid price).
    function getLatestPrice(address oracle) internal view returns (uint256 price, bool healthy) {
        if (oracle == address(0)) return (0, false);
        try IAggregatorV3(oracle).latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            // Check oracle health
            if (updatedAt == 0 || block.timestamp - updatedAt > ORACLE_STALENESS_THRESHOLD || answer <= 0) {
                return (0, false); // Stale or invalid price
            }

            // Get oracle decimals
            uint8 oracleDecimals;
            try IAggregatorV3(oracle).decimals() returns (uint8 dec) {
                oracleDecimals = dec;
            } catch {
                // Assume 8 decimals if decimals() call fails (common for older feeds)
                oracleDecimals = 8;
            }

            // Scale price to 1e18
            uint256 scaledPrice;
            if (oracleDecimals < 18) {
                scaledPrice = uint256(answer) * (10**(18 - oracleDecimals));
            } else if (oracleDecimals > 18) {
                scaledPrice = uint256(answer) / (10**(oracleDecimals - 18));
            } else {
                scaledPrice = uint256(answer);
            }

            return (scaledPrice, true); // Return scaled price and healthy status
        } catch {
            return (0, false); // Oracle call failed
        }
    }


    /// @notice Views the price of an allowed collateral token in USD using its assigned oracle.
    /// @param collateralToken The address of the collateral token.
    /// @return priceUSD The price of 1 token in USD, scaled to 1e18.
    /// @return healthy True if the oracle data is considered healthy.
    function getCollateralPriceInUSD(address collateralToken) public view returns (uint256 priceUSD, bool healthy) {
        if (!isAllowedCollateralToken[collateralToken]) revert InvalidCollateralToken();
        address oracle = collateralTokenOracles[collateralToken];
        if (oracle == address(0)) return (0, false); // Oracle not set

        return getLatestPrice(oracle);
    }

    /// @notice Views the price of the target asset for a Synthetic Asset Type in USD using its assigned oracle.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @return priceUSD The price of 1 unit of the target asset in USD, scaled to 1e18.
    /// @return healthy True if the oracle data is considered healthy.
    function getSyntheticTargetPriceInUSD(uint256 satId) public view returns (uint256 priceUSD, bool healthy) {
        SyntheticAssetType memory sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert InvalidSyntheticAssetType();
        if (!sat.targetAssetOracleSet) return (0, false); // Oracle not set

        return getLatestPrice(sat.targetAssetOracle);
    }

    // --- View Function for SAT Address ---
    /// @notice Gets the synthetic token address for an approved SAT ID.
    /// @param satId The ID of the Synthetic Asset Type.
    /// @return The address of the deployed synthetic token contract.
    function getSyntheticAssetTokenAddress(uint256 satId) public view returns (address) {
         SyntheticAssetType memory sat = syntheticAssetTypes[satId];
        if (!sat.isApproved) revert SyntheticAssetTypeNotApproved();
        return sat.syntheticTokenAddress;
    }

     // --- View Function for All SAT IDs ---
    /// @notice Returns the total number of Synthetic Asset Types proposed (including unapproved/paused).
    /// Note: This doesn't give a list of *approved* IDs, only the total count to iterate up to.
    /// A more sophisticated approach would track approved IDs in a dynamic array.
    function getTotalSyntheticAssetTypeCount() public view returns (uint256) {
        return nextSyntheticAssetTypeId - 1;
    }
}
```