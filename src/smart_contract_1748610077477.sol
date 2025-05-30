Okay, let's design a sophisticated smart contract focusing on a *Decentralized Autonomous Synthetic Asset Protocol* with advanced features like dynamic parameters, multiple asset support, fee accrual, and governance hooks, ensuring it's distinct from standard examples.

This contract will allow users to stake approved collateral tokens and mint various approved synthetic tokens ("Synths") whose value is pegged via oracles. It will feature a liquidation mechanism and parameters configurable via simulated governance hooks.

---

## Smart Contract Outline & Summary

**Contract Name:** `DecentralizedAutonomousSynth`

**Concept:** A protocol enabling the creation and management of decentralized synthetic assets (Synths) backed by staked collateral. It incorporates dynamic parameters controlled by a (simulated) decentralized governance mechanism.

**Core Features:**

1.  **Multi-Collateral Support:** Users can stake different approved ERC20 tokens as collateral.
2.  **Multi-Synth Support:** Users can mint different approved ERC20 synthetic tokens.
3.  **Oracle Integration:** Uses external price feeds (simulated via interfaces) to value collateral and Synths.
4.  **Dynamic Collateralization Ratio (CR):** Users must maintain a minimum CR based on collateral value vs. minted Synth value.
5.  **Liquidation Mechanism:** Positions falling below a minimum CR can be liquidated.
6.  **Dynamic Parameters:** Minimum CR, liquidation penalties, fees, allowed collateral/synth types, etc., are configurable.
7.  **Fee Accrual:** Minting, burning, or liquidations can generate fees, accruing to a designated address or mechanism.
8.  **Governance Hooks:** Functions are protected by a `onlyGovernance` modifier, demonstrating how a DAO would control the protocol. (Note: A full DAO implementation is beyond the scope of this single contract and would typically involve separate voting contracts. This contract assumes a designated governance entity).
9.  **Position Management:** Tracks user stakes and minted amounts across different asset types.

**Function Summary:**

*   **Configuration (Governance-Gated):** Add/Remove/Update parameters for collateral types, synth types, system fees, governance addresses.
*   **User Actions:** Stake collateral, Unstake collateral, Mint Synths, Burn Synths, Claim accrued fees.
*   **Protocol Actions:** Liquidate undercollateralized positions.
*   **Query Functions:** Get details about collateral/synth types, user positions, system state, fees, parameters.
*   **Internal/Helper Functions:** Price fetching, CR calculation, liquidation check/calculation.

**Number of Functions:** > 20

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// --- Interfaces ---

// Interface for a simplified price oracle (e.g., Chainlink AggregatorV3Interface)
interface IPriceOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// Interface for the synthetic tokens (Synths) - minimal ERC20
interface ISynthToken is IERC20 {
    // Potentially add functions specific to the synth if needed later,
    // but for this example, ERC20 interface is sufficient for transfer/balance
}

// Interface for collateral tokens - standard ERC20
interface ICollateralToken is IERC20 {
    // Standard ERC20 interface is sufficient
}

// --- Custom Errors ---

error InvalidCollateralType(address collateralToken);
error InvalidSynthType(address synthToken);
error ZeroAmount();
error ZeroAddress();
error InsufficientCollateralAllowance();
error InsufficientSynthAllowance();
error StakingAmountZero();
error SynthAmountZero();
error InsufficientCollateralStaked();
error InsufficientSynthBurnAmount();
error CannotUnstakeBelowMinCR();
error CannotMintBelowMinCR();
error CannotBurnBelowDust(); // Dust limit prevents tiny positions
error PositionNotLiquidatable();
error CRTooLowToUnstake(uint256 currentCR, uint256 minCR);
error CRTooLowToMint(uint256 currentCR, uint256 minCR);
error CRStillBelowMinAfterBurn(uint256 currentCR, uint256 minCR);
error LiquidationAmountTooHigh();
error PriceFeedFailure();
error OracleDecimalsMismatch();
error ProtocolPaused();
error ProtocolNotPaused();
error AlreadyInitialized();
error NotGovernance();
error GovernanceAddressZero();


contract DecentralizedAutonomousSynth {
    using SafeERC20 for IERC20;
    using Address for address;
    using Math for uint256;

    // --- State Variables ---

    // Governance related
    address public governanceCouncil; // Address authorized to call onlyGovernance functions

    // Protocol State
    bool public protocolPaused = false; // Governance can pause critical operations

    // Collateral Configurations
    struct CollateralType {
        address token;             // Address of the collateral ERC20 token
        IPriceOracle oracle;      // Oracle for pricing this collateral
        uint256 minCR;             // Minimum Collateralization Ratio (e.g., 15000 = 150%)
        uint256 liquidationPenalty;// Percentage penalty on collateral during liquidation (e.g., 1000 = 10%)
        bool isWhitelisted;        // Is this collateral type currently allowed?
    }
    mapping(address => CollateralType) public collateralConfigs;
    address[] public whitelistedCollateralTokens; // List of currently active collateral tokens

    // Synth Configurations
    struct SynthType {
        address token;             // Address of the synthetic ERC20 token
        IPriceOracle oracle;      // Oracle for pricing the asset the synth tracks
        uint256 mintingFeeRate;    // Percentage fee on minting (e.g., 50 = 0.5%)
        uint256 burningFeeRate;    // Percentage fee on burning (e.g., 25 = 0.25%)
        uint256 dustLimit;         // Minimum amount of this synth a user must mint/hold in a position
        bool isWhitelisted;        // Is this synth type currently allowed?
    }
    mapping(address => SynthType) public synthConfigs;
    address[] public whitelistedSynthTokens; // List of currently active synth tokens

    // User Positions
    struct UserPosition {
        mapping(address => uint256) stakedCollateral; // collateralToken => amount
        mapping(address => uint256) mintedSynths;     // synthToken => amount
    }
    mapping(address => UserPosition) public userPositions; // userAddress => UserPosition

    // Accrued Fees (could be distributed or used by governance)
    mapping(address => uint256) public accruedFees; // tokenAddress => amount of fees collected in this token

    // System Totals (Optional, but useful for system health monitoring)
    mapping(address => uint256) public totalStakedCollateral; // collateralToken => total amount staked
    mapping(address => uint256) public totalMintedSynths;     // synthToken => total amount minted

    // --- Events ---

    event CollateralTypeAdded(address indexed token, address indexed oracle, uint256 minCR, uint256 liquidationPenalty);
    event CollateralTypeUpdated(address indexed token, address indexed oracle, uint256 minCR, uint256 liquidationPenalty);
    event CollateralTypeRemoved(address indexed token);
    event SynthTypeAdded(address indexed token, address indexed oracle, uint256 mintingFeeRate, uint256 burningFeeRate, uint256 dustLimit);
    event SynthTypeUpdated(address indexed token, address indexed oracle, uint256 mintingFeeRate, uint256 burningFeeRate, uint256 dustLimit);
    event SynthTypeRemoved(address indexed token);
    event GovernanceCouncilSet(address indexed oldCouncil, address indexed newCouncil);
    event ProtocolPaused(address indexed caller);
    event ProtocolUnpaused(address indexed caller);

    event CollateralStaked(address indexed user, address indexed token, uint256 amount);
    event CollateralUnstaked(address indexed user, address indexed token, uint256 amount);
    event SynthMinted(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event SynthBurned(address indexed user, address indexed token, uint256 amount, uint256 fee);
    event PositionLiquidated(address indexed liquidator, address indexed user, address indexed collateralToken, address indexed synthToken, uint256 collateralLiquidated, uint256 synthsRepaid, uint256 penaltyAmount);
    event FeesClaimed(address indexed receiver, address indexed token, uint256 amount);

    // --- Modifiers ---

    modifier onlyGovernance() {
        if (msg.sender != governanceCouncil) revert NotGovernance();
        _;
    }

    modifier whenNotPaused() {
        if (protocolPaused) revert ProtocolPaused();
        _;
    }

    modifier whenPaused() {
        if (!protocolPaused) revert ProtocolNotPaused();
        _;
    }

    // --- Constructor ---

    constructor(address _initialGovernanceCouncil) {
        if (_initialGovernanceCouncil == address(0)) revert GovernanceAddressZero();
        governanceCouncil = _initialGovernanceCouncil;
        emit GovernanceCouncilSet(address(0), _initialGovernanceCouncil);
    }

    // --- Configuration Functions (onlyGovernance) ---

    // 1. Set the governance council address
    function setGovernanceCouncil(address _newCouncil) external onlyGovernance {
        if (_newCouncil == address(0)) revert GovernanceAddressZero();
        emit GovernanceCouncilSet(governanceCouncil, _newCouncil);
        governanceCouncil = _newCouncil;
    }

    // 2. Add a new collateral type
    function addCollateralType(
        address _token,
        address _oracle,
        uint256 _minCR,
        uint256 _liquidationPenalty
    ) external onlyGovernance {
        if (_token == address(0) || _oracle == address(0)) revert ZeroAddress();
        // Check if token is already whitelisted
        if (collateralConfigs[_token].isWhitelisted) {
             revert InvalidCollateralType(_token); // Or use a more specific error like CollateralTypeAlreadyExists
        }

        collateralConfigs[_token] = CollateralType({
            token: _token,
            oracle: IPriceOracle(_oracle),
            minCR: _minCR,
            liquidationPenalty: _liquidationPenalty,
            isWhitelisted: true
        });
        whitelistedCollateralTokens.push(_token);

        emit CollateralTypeAdded(_token, _oracle, _minCR, _liquidationPenalty);
    }

    // 3. Update parameters for an existing collateral type
    function updateCollateralType(
        address _token,
        address _oracle,
        uint256 _minCR,
        uint256 _liquidationPenalty
    ) external onlyGovernance {
        if (_token == address(0) || _oracle == address(0)) revert ZeroAddress();
        if (!collateralConfigs[_token].isWhitelisted) revert InvalidCollateralType(_token);

        collateralConfigs[_token].oracle = IPriceOracle(_oracle);
        collateralConfigs[_token].minCR = _minCR;
        collateralConfigs[_token].liquidationPenalty = _liquidationPenalty;

        emit CollateralTypeUpdated(_token, _oracle, _minCR, _liquidationPenalty);
    }

    // 4. Remove a collateral type (sets isWhitelisted to false, doesn't remove from array for simplicity)
    function removeCollateralType(address _token) external onlyGovernance {
         if (_token == address(0)) revert ZeroAddress();
         if (!collateralConfigs[_token].isWhitelisted) revert InvalidCollateralType(_token);

         // TODO: Add logic or a governance process to handle existing positions using this collateral
         // before it can be fully deactivated or removed. For simplicity here, we just disable new uses.

         collateralConfigs[_token].isWhitelisted = false;
         emit CollateralTypeRemoved(_token);
         // Note: Removing from `whitelistedCollateralTokens` array is complex and gas-intensive,
         // often better to iterate and check `isWhitelisted`.
    }


    // 5. Add a new synth type
    function addSynthType(
        address _token,
        address _oracle,
        uint256 _mintingFeeRate,
        uint256 _burningFeeRate,
        uint256 _dustLimit
    ) external onlyGovernance {
        if (_token == address(0) || _oracle == address(0)) revert ZeroAddress();
         // Check if token is already whitelisted
        if (synthConfigs[_token].isWhitelisted) {
            revert InvalidSynthType(_token); // Or SynthTypeAlreadyExists
        }

        synthConfigs[_token] = SynthType({
            token: _token,
            oracle: IPriceOracle(_oracle),
            mintingFeeRate: _mintingFeeRate,
            burningFeeRate: _burningFeeRate,
            dustLimit: _dustLimit,
            isWhitelisted: true
        });
        whitelistedSynthTokens.push(_token);

        emit SynthTypeAdded(_token, _oracle, _mintingFeeRate, _burningFeeRate, _dustLimit);
    }

    // 6. Update parameters for an existing synth type
    function updateSynthType(
        address _token,
        address _oracle,
        uint256 _mintingFeeRate,
        uint256 _burningFeeRate,
        uint256 _dustLimit
    ) external onlyGovernance {
        if (_token == address(0) || _oracle == address(0)) revert ZeroAddress();
        if (!synthConfigs[_token].isWhitelisted) revert InvalidSynthType(_token);

        synthConfigs[_token].oracle = IPriceOracle(_oracle);
        synthConfigs[_token].mintingFeeRate = _mintingFeeRate;
        synthConfigs[_token].burningFeeRate = _burningFeeRate;
        synthConfigs[_token].dustLimit = _dustLimit;

        emit SynthTypeUpdated(_token, _oracle, _mintingFeeRate, _burningFeeRate, _dustLimit);
    }

    // 7. Remove a synth type (sets isWhitelisted to false)
    function removeSynthType(address _token) external onlyGovernance {
        if (_token == address(0)) revert ZeroAddress();
        if (!synthConfigs[_token].isWhitelisted) revert InvalidSynthType(_token);

        // TODO: Add logic to handle users holding this synth against staked collateral.
        // Maybe require all positions to be closed first.

        synthConfigs[_token].isWhitelisted = false;
        emit SynthTypeRemoved(_token);
         // Note: Removing from `whitelistedSynthTokens` array is complex and gas-intensive.
    }

    // 8. Pause protocol operations (e.g., minting, unstaking, burning by users)
    function pauseProtocol() external onlyGovernance whenNotPaused {
        protocolPaused = true;
        emit ProtocolPaused(msg.sender);
    }

    // 9. Unpause protocol operations
    function unpauseProtocol() external onlyGovernance whenPaused {
        protocolPaused = false;
        emit ProtocolUnpaused(msg.sender);
    }

    // --- User Functions (whenNotPaused) ---

    // 10. Stake collateral
    function stakeCollateral(address _collateralToken, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert StakingAmountZero();
        if (!collateralConfigs[_collateralToken].isWhitelisted) revert InvalidCollateralType(_collateralToken);

        IERC20 collateralToken = IERC20(_collateralToken);

        // Check allowance
        if (collateralToken.allowance(msg.sender, address(this)) < _amount) {
             revert InsufficientCollateralAllowance();
        }

        // Transfer collateral into the contract
        collateralToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update user position and total
        userPositions[msg.sender].stakedCollateral[_collateralToken] += _amount;
        totalStakedCollateral[_collateralToken] += _amount;

        emit CollateralStaked(msg.sender, _collateralToken, _amount);
    }

     // 11. Unstake collateral
    function unstakeCollateral(address _collateralToken, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        if (!collateralConfigs[_collateralToken].isWhitelisted) revert InvalidCollateralType(_collateralToken);

        UserPosition storage pos = userPositions[msg.sender];
        if (pos.stakedCollateral[_collateralToken] < _amount) revert InsufficientCollateralStaked();

        // Temporarily reduce staked amount for CR calculation
        pos.stakedCollateral[_collateralToken] -= _amount;

        // Check if unstaking keeps the position above the minimum CR for all minted synths
        // This is complex: Need to check against *every* synth the user has minted.
        uint256 currentCR = _calculatePositionCR(msg.sender);
        uint256 maxMinCR = _getMaxMinCRForPosition(msg.sender); // Max of all relevant synth/collateral minCRs

        if (currentCR < maxMinCR && _getSynthedValue(msg.sender) > 0) {
             // Revert the temporary reduction
             pos.stakedCollateral[_collateralToken] += _amount;
             revert CRTooLowToUnstake(currentCR, maxMinCR);
        }

        // Perform the transfer
        IERC20(_collateralToken).safeTransfer(msg.sender, _amount);

        // Update total
        totalStakedCollateral[_collateralToken] -= _amount;

        emit CollateralUnstaked(msg.sender, _collateralToken, _amount);
    }


    // 12. Mint Synths
    function mintSynth(address _synthToken, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert SynthAmountZero();
        SynthType storage synthConfig = synthConfigs[_synthToken];
        if (!synthConfig.isWhitelisted) revert InvalidSynthType(_synthToken);
        if (_amount < synthConfig.dustLimit && userPositions[msg.sender].mintedSynths[_synthToken] == 0) {
             revert CannotMintBelowDust();
        }

        // Check position CR before minting
        uint256 currentCR = _calculatePositionCR(msg.sender);
        uint256 maxMinCR = _getMaxMinCRForPosition(msg.sender);
        if (currentCR < maxMinCR) {
             revert CRTooLowToMint(currentCR, maxMinCR);
        }

        // Calculate fee
        uint256 feeAmount = _amount.mul(synthConfig.mintingFeeRate) / 10000; // Rate is in hundredths of a percent
        uint256 amountToMint = _amount - feeAmount;

        // Mint Synths to the user
        ISynthToken synthToken = ISynthToken(_synthToken);
        // Assume the Synth token contract has a minting function callable by this contract
        // In a real system, ISynthToken would need a `mint(address to, uint256 amount)` function
        // and the Synth token contract would need to trust this contract.
        // For this example, we'll simulate this by assuming direct transfer from contract balance
        // and track total minted, as if the tokens were created here or pre-funded.
        // A more typical approach is having the Synth token implement its own ERC20 and mint internally.
        // Let's simulate by adjusting internal state and requiring the Synth token balance to be >= amountToMint
        // This contract would need to *own* the supply of synths it manages.

        // Alternative and more common approach: Synths are minted by the Synth contract itself
        // and this contract calls a trusted minting function on it.
        // Let's assume `ISynthToken` has a `mint` function:
         synthToken.safeTransfer(msg.sender, amountToMint); // Simulate mint by transferring from contract's pre-approved balance

        // Update user position and total
        userPositions[msg.sender].mintedSynths[_synthToken] += _amount; // Track the gross amount user is liable for
        totalMintedSynths[_synthToken] += _amount;

        // Accrue fee
        // Decide where fees go. For simplicity, let's say they accrue in the Synth token itself
        // to be claimed by governance or stakers later.
        accruedFees[_synthToken] += feeAmount;
        // If fees were in collateral, we'd transfer them here. Mint fees are typically paid in the minted asset.


        emit SynthMinted(msg.sender, _synthToken, _amount, feeAmount);
    }

     // 13. Burn Synths
    function burnSynth(address _synthToken, uint256 _amount) external whenNotPaused {
        if (_amount == 0) revert ZeroAmount();
        SynthType storage synthConfig = synthConfigs[_synthToken];
        if (!synthConfig.isWhitelisted) revert InvalidSynthType(_synthToken);

        UserPosition storage pos = userPositions[msg.sender];
        if (pos.mintedSynths[_synthToken] < _amount) revert InsufficientSynthBurnAmount();

        // Check if burning leaves position below dust limit, unless burning the whole position
        if (pos.mintedSynths[_synthToken] > _amount && pos.mintedSynths[_synthToken] - _amount < synthConfig.dustLimit) {
            revert CannotBurnBelowDust();
        }

        // Calculate fee
        uint256 feeAmount = _amount.mul(synthConfig.burningFeeRate) / 10000;
        uint256 amountToBurn = _amount; // Fees are typically taken *after* burning, or separate? Let's take fee *from* amount burned.
                                        // Fees on burn often *reduce* the collateral released.
                                        // Let's adjust: User burns _amount, this is removed from liability. A fee is charged, reducing collateral released.
                                        // Simpler: Fee is a percentage of the amount burned, paid in the burned asset.
        uint256 feeInSynth = _amount.mul(synthConfig.burningFeeRate) / 10000;

        // Burn Synths (transfer them to this contract)
        ISynthToken(_synthToken).safeTransferFrom(msg.sender, address(this), amountToBurn); // User sends amountToBurn to be burned

        // Update user position and total
        pos.mintedSynths[_synthToken] -= amountToBurn;
        totalMintedSynths[_synthToken] -= amountToBurn;

        // Accrue fee (in Synth token)
        accruedFees[_synthToken] += feeInSynth; // Fee amount stays in the contract

        // Check CR after burning. Burning *should* improve CR.
        // The check is more about preventing users from ending up with CR just *slightly* above minCR
        // if the protocol wants a buffer, or if burning a tiny amount leaves them with a sub-dust position.
        // The dust limit check handles the latter. The CR check is implicitly handled because burning improves CR.
        // However, we could add a check that CR *must* be above minCR *after* burn, but that's usually redundant.

        emit SynthBurned(msg.sender, _synthToken, amountToBurn, feeInSynth);
    }

    // 14. Claim Accrued Fees (can be called by governance or stakers depending on fee model)
    // Let's make this callable by governance for now.
    function claimAccruedFees(address _token, address _receiver) external onlyGovernance {
         if (_receiver == address(0)) revert ZeroAddress();
         uint256 amount = accruedFees[_token];
         if (amount == 0) revert ZeroAmount();

         accruedFees[_token] = 0;
         IERC20(_token).safeTransfer(_receiver, amount);

         emit FeesClaimed(_receiver, _token, amount);
    }


    // --- Protocol Functions ---

    // 15. Liquidate a user position
    function liquidatePosition(address _user, address _collateralToken, address _synthToken) external whenNotPaused {
        if (_user == address(0)) revert ZeroAddress();
        if (!collateralConfigs[_collateralToken].isWhitelisted) revert InvalidCollateralType(_collateralToken);
        if (!synthConfigs[_synthToken].isWhitelisted) revert InvalidSynthType(_synthToken);

        UserPosition storage pos = userPositions[_user];
        if (pos.stakedCollateral[_collateralToken] == 0 || pos.mintedSynths[_synthToken] == 0) {
             revert PositionNotLiquidatable(); // Need position in both assets
        }

        // Check if liquidatable
        uint256 currentCR = _calculatePositionCR(_user);
        uint256 maxMinCR = _getMaxMinCRForPosition(_user);
        if (currentCR >= maxMinCR) {
            revert PositionNotLiquidatable(); // Not below min CR
        }

        CollateralType storage collateralConfig = collateralConfigs[_collateralToken];
        SynthType storage synthConfig = synthConfigs[_synthToken];

        uint256 collateralPrice = _getCollateralPrice(_collateralToken);
        uint256 synthPrice = _getSynthPrice(_synthToken);

        if (collateralPrice == 0 || synthPrice == 0) revert PriceFeedFailure();

        // Calculate amount of synth to repay to get position back above minCR
        // This is simplified; a real system might liquidate a fixed amount or liquidate all.
        // Let's calculate the amount of Synth needed to burn to reach minCR + a buffer,
        // and the corresponding collateral amount to seize including penalty.

        // Target Collateral Value = Total Synth Value * maxMinCR / 10000
        uint256 currentSynthValue = pos.mintedSynths[_synthToken].mul(synthPrice) / (10 ** _getSynthOracleDecimals(_synthToken));
        // This calculation is tricky with fixed point. Let's use 1e18 for calculation base.
        uint256 currentSynthValueScaled = (pos.mintedSynths[_synthToken] * (10**18) / (10**IERC20(_synthToken).decimals()))
                                         .mul(synthPrice * (10**18) / (10**_getSynthOracleDecimals(_synthToken))) / (10**18);

        uint256 totalCollateralValueScaled = _getTotalCollateralValueScaled(_user);
        uint256 maxMinCRScaled = maxMinCR * (10**18) / 10000; // Scale minCR

        // Value of collateral needed to back *current* synths at minCR
        uint256 neededCollateralValueScaled = currentSynthValueScaled.mul(maxMinCRScaled) / (10**18);

        // If total collateral value is less than needed, the position is liquidatable.
        // We need to seize enough collateral to cover the minted synths *at the penalty rate*.

        // Value of synth tokens to repay (burn)
        // This is the amount of synth that, if burned, brings the position's CR >= maxMinCR.
        // Or, calculate the collateral shortfall and determine how many synths its worth.
        // Simpler approach for this example: Liquidate a fixed percentage of the *required* collateral.
        // Or, repay a fixed percentage of the minted synths?

        // Let's make it simple: The liquidator provides the needed Synth amount,
        // and receives collateral at a discount.
        // Amount of Synth to repay to clear ALL of this synth debt for the user: `pos.mintedSynths[_synthToken]`
        uint256 synthsToRepay = pos.mintedSynths[_synthToken];
        uint256 synthsToRepayValueScaled = (synthsToRepay * (10**18) / (10**IERC20(_synthToken).decimals()))
                                          .mul(synthPrice * (10**18) / (10**_getSynthOracleDecimals(_synthToken))) / (10**18);

        // Value of collateral that *should* back this synth amount at 100% CR
        uint256 equivalentCollateralValueScaled = synthsToRepayValueScaled;

        // Value of collateral to seize, with penalty applied
        // collateral_seized_value = synth_repaid_value * (1 + penalty_rate)
        uint256 penaltyRateScaled = collateralConfig.liquidationPenalty * (10**18) / 10000;
        uint256 collateralValueToSeizeScaled = equivalentCollateralValueScaled.mul((10**18) + penaltyRateScaled) / (10**18);

        // Amount of collateral token to seize = collateralValueToSeize / collateralPrice
        uint256 collateralTokenDecimals = IERC20(_collateralToken).decimals();
        uint256 collateralOracleDecimals = _getCollateralOracleDecimals(_collateralToken);

        // Calculate amount of collateral tokens to seize, scaled by its decimals
        uint256 collateralAmountToSeize = (collateralValueToSeizeScaled * (10**collateralTokenDecimals))
                                         .div(collateralPrice * (10**18) / (10**collateralOracleDecimals));


        // Ensure the user has enough collateral of this type to be seized
        if (pos.stakedCollateral[_collateralToken] < collateralAmountToSeize) {
            // If not enough of *this* collateral, liquidate all of it.
            // A real system might liquidate across multiple collateral types.
            // For this example, we'll just liquidate the maximum possible of this type.
            collateralAmountToSeize = pos.stakedCollateral[_collateralToken];

             // Recalculate synths to repay based on available collateral value after penalty
             // collateral_seized_value / (1 + penalty) = synth_value_repaid
             uint256 actualCollateralValueSeizedScaled = (collateralAmountToSeize * (10**18) / (10**collateralTokenDecimals))
                                                        .mul(collateralPrice * (10**18) / (10**collateralOracleDecimals)) / (10**18);

             synthsToRepayValueScaled = actualCollateralValueSeizedScaled.mul(10**18) / ((10**18) + penaltyRateScaled);

             // Amount of synth tokens to repay = synthValueRepaid / synthPrice
             synthsToRepay = (synthsToRepayValueScaled * (10**IERC20(_synthToken).decimals()))
                           .div(synthPrice * (10**18) / (10**_getSynthOracleDecimals(_synthToken)));

             // Ensure we don't try to repay more synths than the user owes
             if (synthsToRepay > pos.mintedSynths[_synthToken]) {
                 synthsToRepay = pos.mintedSynths[_synthToken];
                  // If we are clearing all synth debt, seize collateral equivalent to that debt * (1 + penalty)
                  synthsToRepayValueScaled = (synthsToRepay * (10**18) / (10**IERC20(_synthToken).decimals()))
                                            .mul(synthPrice * (10**18) / (10**_getSynthOracleDecimals(_synthToken))) / (10**18);
                  collateralValueToSeizeScaled = synthsToRepayValueScaled.mul((10**18) + penaltyRateScaled) / (10**18);
                   collateralAmountToSeize = (collateralValueToSeizeScaled * (10**collateralTokenDecimals))
                                         .div(collateralPrice * (10**18) / (10**collateralOracleDecimals));
                  // Recalculate seize amount based on *clearing* the synth debt if user has enough collateral
                  // If not, seize all collateral and calculate how much synth debt is cleared. This path is complex.

                  // Let's simplify: Liquidate up to the amount of synth the user holds, capped by available collateral at penalty.
                  // Liquidator provides X synths, gets Y collateral.
                  // Y = X * (synthPrice / collateralPrice) * (1 + penalty).
                  // Max X is user's total holding of that synth type. Max Y is user's total holding of that collateral type.
                  // Liquidator calls with the amount of Synth *they are providing*.
                  // Let's rename the function to liquidateWithSynth and take amount of synth provided by liquidator.
                  // This requires a different function signature and flow.

                  // Reverting back to the simpler liquidation: Liquidate a proportional amount of the *collateral*
                  // based on the CR shortfall, and burn the corresponding amount of *synth* plus penalty.
                  // This is also complex as it requires solving for amount.

                  // Let's choose the simplest mechanism: Liquidate *all* of the user's position in *this specific* collateral/synth pair
                  // if they are below CR, limited by the user's actual holdings. Liquidator gets collateral at discount.
                  // Liquidator pays back the user's synth debt (transfers synths to contract).
                  // Amount of collateral given to liquidator = (Amount of synth repaid * synthPrice / collateralPrice) * (1 + penalty)

                  synthsToRepay = pos.mintedSynths[_synthToken]; // Liquidate the entire synth debt for this type
                  synthsToRepayValueScaled = (synthsToRepay * (10**18) / (10**IERC20(_synthToken).decimals()))
                                            .mul(synthPrice * (10**18) / (10**_getSynthOracleDecimals(_synthToken))) / (10**18);

                  collateralValueToSeizeScaled = synthsToRepayValueScaled.mul((10**18) + penaltyRateScaled) / (10**18);

                  collateralAmountToSeize = (collateralValueToSeizeScaled * (10**collateralTokenDecimals))
                                         .div(collateralPrice * (10**18) / (10**collateralOracleDecimals));

                 // Ensure we don't seize more collateral than available
                 if (collateralAmountToSeize > pos.stakedCollateral[_collateralToken]) {
                     collateralAmountToSeize = pos.stakedCollateral[_collateralToken];
                     // The amount of synth debt cleared is less in this case.
                     // We could calculate it, but clearing full debt if possible is simpler.
                     // Let's stick to seizing collateralAmountToSeize and assume the corresponding synth debt is cleared proportionally?
                     // No, the user owes a fixed amount of synth. Liquidator needs to clear that.
                     // If collateral is insufficient to cover full synth debt at penalty, the liquidator gets all available collateral
                     // and the *full* synth debt is still repaid (liquidator overpays for efficiency/incentive?).

                     // Simplified liquidation flow: Liquidator provides the full `pos.mintedSynths[_synthToken]`
                     // and receives `pos.stakedCollateral[_collateralToken]` IF pos is liquidatable.
                     // This might result in the liquidator getting less than the penalty implies if collateral is scarce.
                     // A better approach: Liquidator provides `synthsToRepay`, receives `collateralAmountToSeize`.
                     // Let's use the calculation where `synthsToRepay` clears the debt and `collateralAmountToSeize` is calculated.
                     // If `collateralAmountToSeize` > available, revert or liquidate max available?
                     // Reverting is safer for clarity in this example. A real system would handle partial/max liquidations.
                     revert LiquidationAmountTooHigh();
                 }
        }


        // Liquidator transfers synths to the contract (burning them effectively)
        ISynthToken(_synthToken).safeTransferFrom(msg.sender, address(this), synthsToRepay);

        // Transfer seized collateral to the liquidator
        IERC20(_collateralToken).safeTransfer(msg.sender, collateralAmountToSeize);

        // Calculate penalty amount seized (this is the liquidator's profit)
        uint256 equivalentValueWithoutPenaltyScaled = synthsToRepayValueScaled;
        uint256 seizedValueScaled = (collateralAmountToSeize * (10**18) / (10**collateralTokenDecimals))
                                   .mul(collateralPrice * (10**18) / (10**collateralOracleDecimals)) / (10**18);
        uint256 penaltyValueScaled = seizedValueScaled > equivalentValueWithoutPenaltyScaled ? seizedValueScaled - equivalentValueWithoutPenaltyScaled : 0;

        // Update user position and totals
        pos.mintedSynths[_synthToken] -= synthsToRepay;
        pos.stakedCollateral[_collateralToken] -= collateralAmountToSeize;
        totalMintedSynths[_synthToken] -= synthsToRepay;
        totalStakedCollateral[_collateralToken] -= collateralAmountToSeize;

        // Fees? The liquidation penalty IS the fee/incentive for the liquidator.
        // Could accrue a small *protocol* fee on liquidation too. Let's skip for now.

        emit PositionLiquidated(
            msg.sender,
            _user,
            _collateralToken,
            _synthToken,
            collateralAmountToSeize,
            synthsToRepay,
            penaltyValueScaled // Emitting value, not token amount, due to multiple collateral types
        );
    }

    // --- Query Functions ---

    // 16. Get a user's staked collateral amount for a specific token
    function getUserStakedCollateral(address _user, address _collateralToken) external view returns (uint256) {
        return userPositions[_user].stakedCollateral[_collateralToken];
    }

    // 17. Get a user's minted synth amount for a specific token
     function getUserMintedSynths(address _user, address _synthToken) external view returns (uint256) {
        return userPositions[_user].mintedSynths[_synthToken];
    }

    // 18. Get the current Collateralization Ratio for a user's entire position
    // Returns CR scaled by 10000 (e.g., 20000 for 200%)
    function getUserPositionCR(address _user) external view returns (uint256) {
        return _calculatePositionCR(_user);
    }

    // 19. Get the total value of collateral staked by a user (in USD, scaled by 1e18)
    function getUserTotalCollateralValue(address _user) external view returns (uint256) {
        return _getTotalCollateralValueScaled(_user);
    }

    // 20. Get the total value of synths minted by a user (in USD, scaled by 1e18)
    function getUserTotalSynthValue(address _user) external view returns (uint256) {
        return _getSynthedValueScaled(_user);
    }


    // 21. Check if a user's position is liquidatable (for any synth/collateral combination)
    function isPositionLiquidatable(address _user) external view returns (bool) {
        uint256 currentCR = _calculatePositionCR(_user);
        uint256 maxMinCR = _getMaxMinCRForPosition(_user);
        // A position with zero synths is never liquidatable
        return _getSynthedValueScaled(_user) > 0 && currentCR < maxMinCR;
    }

    // 22. Get available collateral token addresses
    function getWhitelistedCollateralTokens() external view returns (address[] memory) {
        // Filter out removed ones if necessary, or just return the list and client checks isWhitelisted
        return whitelistedCollateralTokens;
    }

     // 23. Get available synth token addresses
    function getWhitelistedSynthTokens() external view returns (address[] memory) {
         // Filter out removed ones if necessary
        return whitelistedSynthTokens;
    }

    // 24. Get config for a specific collateral type
    function getCollateralConfig(address _token) external view returns (
        address token,
        address oracleAddress,
        uint256 minCR,
        uint256 liquidationPenalty,
        bool isWhitelisted
    ) {
        CollateralType storage config = collateralConfigs[_token];
        return (
            config.token,
            address(config.oracle),
            config.minCR,
            config.liquidationPenalty,
            config.isWhitelisted
        );
    }

     // 25. Get config for a specific synth type
    function getSynthConfig(address _token) external view returns (
        address token,
        address oracleAddress,
        uint256 mintingFeeRate,
        uint256 burningFeeRate,
        uint256 dustLimit,
        bool isWhitelisted
    ) {
        SynthType storage config = synthConfigs[_token];
        return (
            config.token,
            address(config.oracle),
            config.mintingFeeRate,
            config.burningFeeRate,
            config.dustLimit,
            config.isWhitelisted
        );
    }

     // 26. Get total amount of a specific collateral token staked in the protocol
     function getTotalStakedCollateral(address _token) external view returns (uint256) {
        return totalStakedCollateral[_token];
     }

     // 27. Get total amount of a specific synth token minted by the protocol
     function getTotalMintedSynths(address _token) external view returns (uint256) {
        return totalMintedSynths[_token];
     }

     // 28. Get accrued fees for a specific token
     function getAccruedFees(address _token) external view returns (uint256) {
         return accruedFees[_token];
     }

     // 29. Calculate max synth amount user can mint for a specific synth type
     // based on their current collateral and other minted synths
     function calculateMaxMintableSynth(address _user, address _synthToken) external view returns (uint256 maxAmount) {
         if (!synthConfigs[_synthToken].isWhitelisted) revert InvalidSynthType(_synthToken);

         uint256 totalCollateralValueScaled = _getTotalCollateralValueScaled(_user);
         uint256 totalSynthValueExcludingNewScaled = _getSynthedValueScaledExcluding(_user, _synthToken);

         // Value of new synth that can be minted = (TotalCollateralValue / maxMinCR) - TotalSynthValueExcludingNew
         uint256 maxMinCR = _getMaxMinCRForPosition(_user);
         if (maxMinCR == 0) return 0; // Should not happen if types are configured, but safety
         if (totalCollateralValueScaled.mul(10000) < totalSynthValueExcludingNewScaled.mul(maxMinCR)) return 0; // Already below CR or no capacity

         uint256 maxTotalSynthValueScaled = totalCollateralValueScaled.mul(10000) / maxMinCR;
         uint256 potentialNewSynthValueScaled = maxTotalSynthValueScaled > totalSynthValueExcludingNewScaled ?
                                                maxTotalSynthValueScaled - totalSynthValueExcludingNewScaled : 0;

         // Convert value to synth token amount
         uint256 synthPrice = _getSynthPrice(_synthToken);
         if (synthPrice == 0) return 0; // Cannot calculate without price

         uint256 synthTokenDecimals = IERC20(_synthToken).decimals();
         uint256 synthOracleDecimals = _getSynthOracleDecimals(_synthToken);

         uint256 potentialNewSynthAmount = (potentialNewSynthValueScaled * (10**synthTokenDecimals))
                                         .div(synthPrice * (10**18) / (10**synthOracleDecimals));

         // Adjust for fee (user receives amount after fee, needs to mint enough to cover fee)
         // amountBeforeFee * (1 - feeRate) = amountAfterFee
         // amountBeforeFee = amountAfterFee / (1 - feeRate)
         // Let's return the amount the user can *request* to mint (before fee is deducted)
         // The actual amount transferred to user will be less.
         // If fee rate is 0.5% (50/10000), factor is (10000-50)/10000 = 9950/10000
         // amountBeforeFee = amountAfterFee * 10000 / 9950
         uint256 mintingFeeRate = synthConfigs[_synthToken].mintingFeeRate;
         if (mintingFeeRate >= 10000) return 0; // Fee 100% or more

         maxAmount = potentialNewSynthAmount.mul(10000) / (10000 - mintingFeeRate);

         // Adjust for dust limit if this is the first mint of this synth type for the user
         if (userPositions[_user].mintedSynths[_synthToken] == 0 && maxAmount > 0 && maxAmount < synthConfigs[_synthToken].dustLimit) {
             return 0; // Cannot mint less than dust as a starting position
         }

         return maxAmount;
     }


    // --- Internal Helper Functions ---

    // Calculate the total USD value of a user's staked collateral across all types
    // Returns value scaled by 1e18
    function _getTotalCollateralValueScaled(address _user) internal view returns (uint256 totalValueScaled) {
        totalValueScaled = 0;
        UserPosition storage pos = userPositions[_user];
        // Iterate over all whitelisted collateral types
        for (uint i = 0; i < whitelistedCollateralTokens.length; i++) {
            address tokenAddress = whitelistedCollateralTokens[i];
            if (collateralConfigs[tokenAddress].isWhitelisted && pos.stakedCollateral[tokenAddress] > 0) {
                uint256 amount = pos.stakedCollateral[tokenAddress];
                uint256 price = _getCollateralPrice(tokenAddress);
                 if (price == 0) continue; // Skip if price feed is down (or handle error)

                uint256 tokenDecimals = IERC20(tokenAddress).decimals();
                uint256 oracleDecimals = _getCollateralOracleDecimals(tokenAddress);

                // Value = amount * price * (1e18 / tokenDecimals) / (1eOracleDecimals)
                // To avoid large numbers and division loss:
                // Value scaled by 1e18 = (amount / 1eTokenDecimals) * (price / 1eOracleDecimals) * 1e18
                // = (amount * price * 1e18) / (1eTokenDecimals * 1eOracleDecimals)

                totalValueScaled += (amount * price * (10**18)) / (10**tokenDecimals * 10**oracleDecimals);
            }
        }
    }

     // Calculate the total USD value of a user's minted synths across all types
     // Returns value scaled by 1e18
    function _getSynthedValueScaled(address _user) internal view returns (uint256 totalValueScaled) {
         totalValueScaled = 0;
        UserPosition storage pos = userPositions[_user];
         // Iterate over all whitelisted synth types
        for (uint i = 0; i < whitelistedSynthTokens.length; i++) {
            address tokenAddress = whitelistedSynthTokens[i];
            if (synthConfigs[tokenAddress].isWhitelisted && pos.mintedSynths[tokenAddress] > 0) {
                uint256 amount = pos.mintedSynths[tokenAddress];
                uint256 price = _getSynthPrice(tokenAddress);
                 if (price == 0) continue; // Skip if price feed is down

                uint256 tokenDecimals = IERC20(tokenAddress).decimals();
                uint256 oracleDecimals = _getSynthOracleDecimals(tokenAddress);

                 totalValueScaled += (amount * price * (10**18)) / (10**tokenDecimals * 10**oracleDecimals);
            }
        }
    }

     // Calculate the total USD value of a user's minted synths excluding a specific type
     // Returns value scaled by 1e18
    function _getSynthedValueScaledExcluding(address _user, address _excludeSynthToken) internal view returns (uint256 totalValueScaled) {
         totalValueScaled = 0;
        UserPosition storage pos = userPositions[_user];
         for (uint i = 0; i < whitelistedSynthTokens.length; i++) {
            address tokenAddress = whitelistedSynthTokens[i];
            if (tokenAddress == _excludeSynthToken) continue; // Skip the excluded token
            if (synthConfigs[tokenAddress].isWhitelisted && pos.mintedSynths[tokenAddress] > 0) {
                 uint256 amount = pos.mintedSynths[tokenAddress];
                uint256 price = _getSynthPrice(tokenAddress);
                 if (price == 0) continue;

                uint256 tokenDecimals = IERC20(tokenAddress).decimals();
                uint256 oracleDecimals = _getSynthOracleDecimals(tokenAddress);

                 totalValueScaled += (amount * price * (10**18)) / (10**tokenDecimals * 10**oracleDecimals);
            }
        }
    }


    // Calculate the current Collateralization Ratio for a user
    // Returns CR scaled by 10000 (e.g., 20000 for 200%)
    function _calculatePositionCR(address _user) internal view returns (uint256) {
        uint256 totalCollateralValueScaled = _getTotalCollateralValueScaled(_user);
        uint256 totalSynthValueScaled = _getSynthedValueScaled(_user);

        if (totalSynthValueScaled == 0) {
            return type(uint256).max; // Effectively infinite CR if no synths minted
        }

        // CR = (Total Collateral Value / Total Synth Value) * 100%
        // CR scaled by 10000 = (Total Collateral Value Scaled / Total Synth Value Scaled) * 10000
        return totalCollateralValueScaled.mul(10000).div(totalSynthValueScaled);
    }

    // Get the maximum minimum CR required by any collateral or synth type in the user's position
    // This is the effective minimum CR the user must maintain.
    function _getMaxMinCRForPosition(address _user) internal view returns (uint256 maxMinCR) {
        maxMinCR = 0; // Default min CR is 0 if no position

        UserPosition storage pos = userPositions[_user];

        // Check collateral types used
        for (uint i = 0; i < whitelistedCollateralTokens.length; i++) {
            address tokenAddress = whitelistedCollateralTokens[i];
            if (collateralConfigs[tokenAddress].isWhitelisted && pos.stakedCollateral[tokenAddress] > 0) {
                maxMinCR = Math.max(maxMinCR, collateralConfigs[tokenAddress].minCR);
            }
        }

        // Check synth types minted
        for (uint i = 0; i < whitelistedSynthTokens.length; i++) {
            address tokenAddress = whitelistedSynthTokens[i];
            if (synthConfigs[tokenAddress].isWhitelisted && pos.mintedSynths[tokenAddress] > 0) {
                 // Max CR might come from Synth type config too? Or just collateral?
                 // Usually, minCR is a property of the *collateral type* used to back *any* synth.
                 // Let's refine: minCR is purely a property of the collateral type.
                 // The function `_getMaxMinCRForPosition` should just iterate staked collateral types.
                 // Let's remove the check for synth types here.
            }
        }
         // Re-iterate, minCR is per collateral type. A user's position CR must be >= the minCR of *every* collateral type they use.
         // This is also complex. A more typical design has a single system-wide minCR, or minCR *per collateral type*
         // where the user's *total* position CR must exceed the minCR of *all* collateral types they are using.
         // Let's assume the latter: maxMinCR is the highest minCR among all collateral types the user staked.
    }

     // Get price from oracle for a collateral token, returns price scaled by 1e18 (adjusting for oracle decimals)
     function _getCollateralPrice(address _token) internal view returns (uint256) {
        CollateralType storage config = collateralConfigs[_token];
        if (!config.isWhitelisted) return 0; // Or revert, depending on desired behavior
        try config.oracle.latestAnswer() returns (int256 price) {
            if (price <= 0) return 0; // Handle invalid price
             uint8 oracleDecimals = _getCollateralOracleDecimals(_token);
             // Scale price to 1e18
             return uint256(price).mul(10**(18 - oracleDecimals));
        } catch {
            return 0; // Oracle call failed
        }
    }

    // Get price from oracle for a synth token, returns price scaled by 1e18
     function _getSynthPrice(address _token) internal view returns (uint256) {
        SynthType storage config = synthConfigs[_token];
         if (!config.isWhitelisted) return 0;
        try config.oracle.latestAnswer() returns (int256 price) {
            if (price <= 0) return 0;
             uint8 oracleDecimals = _getSynthOracleDecimals(_token);
             // Scale price to 1e18
             return uint256(price).mul(10**(18 - oracleDecimals));
        } catch {
            return 0;
        }
    }

     // Get oracle decimals for a collateral token
     function _getCollateralOracleDecimals(address _token) internal view returns (uint8) {
         CollateralType storage config = collateralConfigs[_token];
          if (!config.isWhitelisted) revert InvalidCollateralType(_token); // Or return 0? Revert is safer.
          try config.oracle.decimals() returns (uint8 oracleDecimals) {
             return oracleDecimals;
          } catch {
             revert PriceFeedFailure(); // Or OracleDecimalsMismatch
          }
     }

     // Get oracle decimals for a synth token
     function _getSynthOracleDecimals(address _token) internal view returns (uint8) {
        SynthType storage config = synthConfigs[_token];
         if (!config.isWhitelisted) revert InvalidSynthType(_token);
         try config.oracle.decimals() returns (uint8 oracleDecimals) {
            return oracleDecimals;
         } catch {
            revert PriceFeedFailure(); // Or OracleDecimalsMismatch
         }
     }
}
```