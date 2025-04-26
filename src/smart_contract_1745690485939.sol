Okay, let's design a smart contract that acts as a "Quantum Fund" - a sophisticated, actively managed investment vault. It will utilize concepts like ERC-4626 for standardized vault mechanics, integrate with external strategies, incorporate a decentralized governance model (simulated interaction), use oracles for conditional logic, and include advanced features like gasless deposits and timed operations.

This contract will **not** replicate existing full protocols like Aave, Compound, Uniswap, Yearn, etc., but might demonstrate interactions *with* such concepts (e.g., allocating funds *to* a yield strategy). The governance is represented by interactions with a hypothetical external Governance contract.

**Disclaimer:** This is a complex design for educational purposes. It requires rigorous auditing and further development for production use. Oracle integration, external strategy calls, and complex state management introduce significant security risks if not handled perfectly.

---

**Outline & Function Summary:**

**Contract Name:** `QuantumFund`

**Concept:** An actively managed, diversified investment vault built on the ERC-4626 standard, allowing users to deposit assets and receive shares representing ownership. It can allocate deposited assets into multiple approved external "investment strategies" based on target percentages set via decentralized governance. Includes advanced features like oracle-based conditional actions, gasless deposits (Permit), and timed execution of sensitive changes.

**Outline:**

1.  **License & Version**
2.  **Imports:** ERC20, ERC4626, SafeERC20, ReentrancyGuard, Interfaces (Oracle, Governance, Strategy, Permit).
3.  **Errors:** Custom error definitions.
4.  **Events:** State changes and key actions.
5.  **State Variables:** Fund details, assets, strategies, allocations, governance, fees, oracle, state flags.
6.  **Structs:** Strategy configuration, queued allocation changes.
7.  **Modifiers:** `onlyGovernance`, `onlyApprovedStrategy`, `whenNotPaused`, `nonReentrant`.
8.  **Constructor:** Initialize fund parameters, assets, and initial governance.
9.  **ERC-4626 Core Implementation:**
    *   `asset()`: Returns the primary asset managed by the vault.
    *   `totalAssets()`: Total amount of primary asset held by the vault and its strategies.
    *   `convertToShares()`: Calculate shares received for a given asset amount.
    *   `convertToAssets()`: Calculate asset amount for a given share amount.
    *   `maxDeposit()`: Max assets a user can deposit.
    *   `previewDeposit()`: Preview shares received for a deposit.
    *   `deposit()`: Deposit assets and mint shares.
    *   `maxMint()`: Max shares a user can mint.
    *   `previewMint()`: Preview assets needed for minting shares.
    *   `mint()`: Mint shares by depositing assets.
    *   `maxRedeem()`: Max shares a user can redeem.
    *   `previewRedeem()`: Preview assets received for redemption.
    *   `redeem()`: Redeem shares for assets.
    *   `maxWithdraw()`: Max assets a user can withdraw.
    *   `previewWithdraw()`: Preview shares needed for withdrawal.
    *   `withdraw()`: Withdraw assets by burning shares.
10. **Strategy Management:**
    *   `addInvestmentStrategy()`: Add a new approved external strategy contract.
    *   `removeInvestmentStrategy()`: Remove an approved strategy (must be zero allocated).
    *   `getStrategyHoldings()`: Get assets held by a specific strategy.
    *   `getTotalStrategyAssets()`: Get total assets across all strategies.
11. **Allocation & Rebalancing:**
    *   `setStrategyTargetAllocation()`: Set the target percentage for a strategy (Governance only).
    *   `rebalanceStrategies()`: Execute rebalancing based on current targets.
    *   `queueStrategyAllocationChange()`: Queue a proposed allocation change with a timelock (Governance only).
    *   `executeQueuedStrategyAllocationChange()`: Execute a queued allocation change after timelock expires.
    *   `cancelQueuedAllocationChange()`: Cancel a pending queued change (Governance only).
12. **Governance & Parameters:**
    *   `setGovernanceAddress()`: Set the address of the governance contract (Owner/Current Governance).
    *   `proposeFundParameterChange()`: Example function for governance to propose changes (simulated interaction point).
13. **Fees:**
    *   `setPerformanceFeeRate()`: Set the performance fee rate (Governance only).
    *   `claimFees()`: Allows a fee recipient (set by Governance) to claim accumulated fees.
14. **Safety & Utility:**
    *   `pause()`: Pause core operations (deposit/withdraw/rebalance) (Governance only).
    *   `unpause()`: Unpause core operations (Governance only).
    *   `emergencyWithdrawFromStrategy()`: Force a strategy to return assets in emergency (Governance only).
    *   `rescueERC20()`: Rescue mistakenly sent ERC20 tokens (Governance only, excludes vault asset and shares).
15. **Advanced / Unique Features:**
    *   `setTrustedOracle()`: Set the address of a trusted price oracle (Governance only).
    *   `triggerRebalanceIfDeviation()`: Trigger rebalance only if asset value deviates significantly based on oracle feed.
    *   `depositWithPermit()`: Allow deposit using ERC-20 Permit signature (gasless approval).
    *   `conditionalStrategyExitBasedOnOracle()`: Exit a strategy based on a specific price condition from the oracle (e.g., asset price drops below threshold).
    *   `checkNFTBoostEligibility()`: (Example) Check if a user holds a specific NFT granting special access/modifier (requires an NFT contract address config). *Not fully implemented, just function signature and check placeholder.*

**Total Function Count:** ~35 (ERC-4626 adds many standard functions).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for initial setup, governance takes over sensitive functions.

// Minimal ERC-4626 interface for clarity, implementing the full standard
// as defined in EIP-4626 involves inheriting or implementing all specified
// functions, which we will do below.
interface IERC4626 is IERC20 {
    function asset() external view returns (address assetTokenAddress);
    function totalAssets() external view returns (uint256 totalManagedAssets);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function maxDeposit(address receiver) external view returns (uint256 assets);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external nonReentrant returns (uint256 shares);
    function maxMint(address receiver) external view returns (uint256 shares);
    function previewMint(uint256 shares) external view returns (uint256 assets);
    function mint(uint256 shares, address receiver) external nonReentrant returns (uint256 assets);
    function maxWithdraw(address owner) external view returns (uint256 assets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external nonReentrant returns (uint256 shares);
    function maxRedeem(address owner) external view returns (uint256 shares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function redeem(uint256 shares, address receiver, address owner) external nonReentrant returns (uint256 assets);

    // Events from ERC-4626
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
}

// Interface for external investment strategies
interface IInvestmentStrategy {
    function deposit(address assetToken, uint256 amount) external returns (bool success);
    function withdraw(address assetToken, uint256 amount) external returns (uint256 returnedAmount);
    function withdrawAll(address assetToken) external returns (uint256 returnedAmount);
    function getHoldings(address assetToken) external view returns (uint256 holdings);
    // Potentially add other strategy-specific functions (e.g., harvest rewards)
}

// Interface for a price oracle (simplified)
interface IPriceOracle {
    function getPrice(address assetAddress) external view returns (uint256 price); // Price in USD cents, e.g. 1 token = $1.23 -> returns 123
    function isPriceValid(address assetAddress) external view returns (bool valid);
}

// Interface for a governance contract (simplified interaction points)
interface IGovernance {
    function isApprovedGovernor(address account) external view returns (bool);
    // Functions the governance contract itself might call on QuantumFund
    // function proposeFundParameterChange(address target, bytes data, uint256 value) external returns (uint256 proposalId);
    // function vote(uint256 proposalId, bool support) external;
    // function execute(uint256 proposalId) external;
}

// Interface for ERC20 Permit (EIP-2612)
interface IERC20Permit {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


error QuantumFund__InvalidStrategy();
error QuantumFund__AllocationMismatch();
error QuantumFund__AllocationSumMustBe100Percent();
error QuantumFund__ZeroAllocationStrategyNotEmpty();
error QuantumFund__InsufficientFunds();
error QuantumFund__TimelockNotExpired();
error QuantumFund__TimelockStillActive();
error QuantumFund__QueueDoesNotExist();
error QuantumFund__QueueAlreadyExists();
error QuantumFund__UnauthorizedGovernanceCall();
error QuantumFund__FeeRecipientNotSet();
error QuantumFund__CannotRescueVaultAssets();
error QuantumFund__PermitInvalidSignature();
error QuantumFund__OraclePriceInvalid();
error QuantumFund__ConditionalExitNotMet();
error QuantumFund__CannotRebalancePaused();


contract QuantumFund is IERC4626, ERC20, ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;

    // --- State Variables ---

    IERC20 public immutable asset; // The underlying asset managed by the vault (e.g., USDC, DAI)
    address public governanceAddress; // Address of the governance contract controlling sensitive operations
    address public trustedOracle; // Address of the trusted price oracle
    address public feeRecipient; // Address to send collected fees

    struct StrategyConfig {
        address strategyAddress;
        uint256 targetAllocationPercent; // Target percentage of total assets (basis points, 10000 = 100%)
        bool isApproved; // Whether the strategy is currently approved for allocation
    }

    // Mapping strategy address to its configuration
    mapping(address => StrategyConfig) public investmentStrategies;
    address[] public approvedStrategiesList; // List of approved strategy addresses for iteration

    // State for queued allocation changes (Governance controlled timelock)
    struct QueuedAllocationChange {
        address strategyAddress;
        uint256 newTargetAllocationPercent;
        uint256 queueTime;
        bytes32 proposalHash; // Hash of the proposal data (e.g., from governance)
    }
    mapping(bytes32 => QueuedAllocationChange) public queuedAllocationChanges;
    uint256 public allocationTimelockDuration = 2 days; // Time required before executing a queued change

    uint256 public performanceFeeRate = 1000; // Performance fee in basis points (e.g., 1000 = 10%)
    uint256 private _totalPerformanceFees = 0; // Accumulated performance fees

    // Placeholder for NFT boost - requires a specific NFT contract address to check
    address public nftBoostContractAddress;
    uint256 public nftBoostVotingPowerMultiplier = 1; // Example use case, could apply to voting in external governance

    // --- Events ---

    // ERC-4626 Events imported from interface

    event StrategyAdded(address indexed strategy, uint256 initialTargetAllocation);
    event StrategyRemoved(address indexed strategy);
    event StrategyTargetAllocationSet(address indexed strategy, uint256 newTargetAllocation);
    event StrategiesRebalanced(uint256 totalAssetsRebalanced);
    event AllocationChangeQueued(bytes32 indexed proposalHash, address indexed strategy, uint256 newTargetAllocation, uint256 queueTime);
    event AllocationChangeExecuted(bytes32 indexed proposalHash, address indexed strategy, uint256 newTargetAllocation);
    event AllocationChangeCancelled(bytes32 indexed proposalHash);
    event GovernanceAddressSet(address indexed oldGovernance, address indexed newGovernance);
    event PerformanceFeeRateSet(uint256 newRate);
    event FeesClaimed(address indexed recipient, uint256 amount);
    event EmergencyWithdraw(address indexed strategy, uint256 amount);
    event ERC20Rescued(address indexed token, uint256 amount);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event RebalanceTriggeredByDeviation(uint256 deviationPercent);
    event ConditionalExitTriggered(address indexed strategy, uint256 assetsWithdrawn, string conditionMet);
    event NFTBoostContractSet(address indexed contractAddress);


    // --- Modifiers ---

    modifier onlyGovernance() {
        // Allows owner initially, transitions to governance contract
        require(msg.sender == owner() || (governanceAddress != address(0) && IGovernance(governanceAddress).isApprovedGovernor(msg.sender)), QuantumFund__UnauthorizedGovernanceCall());
        _;
    }

    modifier onlyApprovedStrategy(address _strategy) {
        require(investmentStrategies[_strategy].isApproved, QuantumFund__InvalidStrategy());
        _;
    }

    // Pausable modifier inherited from OpenZeppelin

    // nonReentrant modifier inherited from OpenZeppelin


    // --- Constructor ---

    constructor(IERC20 _asset, string memory name, string memory symbol, address _initialGovernance)
        ERC20(name, symbol) // Shares token
        Pausable() // Pausable functionality
        Ownable(msg.sender) // Initial owner
    {
        asset = _asset;
        governanceAddress = _initialGovernance; // Can be set to owner() initially and changed later
        // Initial supply of shares is zero as per ERC-4626
    }

    // --- ERC-4626 Core Implementation ---

    /// @inheritdoc IERC4626
    function asset() public view override returns (address) {
        return address(asset);
    }

    /// @inheritdoc IERC4626
    function totalAssets() public view override returns (uint256) {
        // Total assets are assets held by the vault + assets held by strategies
        uint256 vaultHoldings = asset.balanceOf(address(this));
        uint256 strategyHoldings = getTotalStrategyAssets();
        return vaultHoldings + strategyHoldings;
    }

    /// @inheritdoc IERC4626
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : assets.mul(supply) / totalAssets();
    }

    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : shares.mul(totalAssets()) / supply;
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address) public view override returns (uint256) {
        // No deposit limit enforced by the vault itself, external limits might apply
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function previewDeposit(uint256 assets) public view override returns (uint256) {
        return convertToShares(assets);
    }

    /// @inheritdoc IERC4626
    function deposit(uint256 assetsAmount, address receiver) public override nonReentrant whenNotPaused returns (uint256 shares) {
        require(assetsAmount > 0, "Deposit amount must be > 0");
        uint256 sharesAmount = convertToShares(assetsAmount);
        require(sharesAmount > 0, "Deposit yielded 0 shares"); // Avoids dust shares

        uint256 totalAssetsBefore = totalAssets(); // For accurate share calculation

        // Transfer assets from sender to vault
        asset.safeTransferFrom(msg.sender, address(this), assetsAmount);

        // Recalculate shares based on actual assets received (handling potential transfer fees)
        uint256 totalAssetsAfterTransfer = asset.balanceOf(address(this)) + getTotalStrategyAssets();
        // Use the state *after* transfer for the most accurate pricing point during deposit
        // If total supply was 0, shares = assets received. Otherwise, calculate based on price delta.
        if (totalSupply() == 0) {
             sharesAmount = assetsAmount; // 1 asset = 1 share initially
        } else {
             // Shares = (Assets added) * (Total shares) / (Total assets before deposit)
             // Using totalAssetsBefore here reflects the price *before* the new assets potentially shifted it slightly.
             sharesAmount = assetsAmount.mul(totalSupply()) / totalAssetsBefore;
        }

        _mint(receiver, sharesAmount);

        emit Deposit(msg.sender, receiver, assetsAmount, sharesAmount);
        return sharesAmount;
    }

    /// @inheritdoc IERC4626
    function maxMint(address) public view override returns (uint256) {
        // No mint limit enforced
        return type(uint256).max;
    }

    /// @inheritdoc IERC4626
    function previewMint(uint256 shares) public view override returns (uint256) {
        return convertToAssets(shares);
    }

    /// @inheritdoc IERC4626
    function mint(uint256 sharesAmount, address receiver) public override nonReentrant whenNotPaused returns (uint256 assets) {
        require(sharesAmount > 0, "Mint shares must be > 0");
        uint256 assetsAmount = convertToAssets(sharesAmount);

        // Transfer assets from sender to vault
        asset.safeTransferFrom(msg.sender, address(this), assetsAmount);

        // Due to potential transfer fees or price movements between previewMint and mint execution,
        // recalculate shares based on assets received.
        uint256 assetsActuallyReceived = asset.balanceOf(address(this)) + getTotalStrategyAssets() - totalAssets(); // Assets added
        uint256 sharesActuallyMinted;
         if (totalSupply() == 0) {
             sharesActuallyMinted = assetsActuallyReceived;
         } else {
            sharesActuallyMinted = assetsActuallyReceived.mul(totalSupply()) / (totalAssets() - assetsActuallyReceived); // Price based on state *before* mint
         }
        require(sharesActuallyMinted > 0, "Mint yielded 0 shares after transfer");


        _mint(receiver, sharesActuallyMinted);

        emit Deposit(msg.sender, receiver, assetsActuallyReceived, sharesActuallyMinted);
        return assetsActuallyReceived;
    }


    /// @inheritdoc IERC4626
    function maxWithdraw(address owner) public view override returns (uint256) {
        return convertToAssets(balanceOf(owner)); // Max withdrawable assets is limited by user's shares value
    }

    /// @inheritdoc IERC4626
    function previewWithdraw(uint256 assetsAmount) public view override returns (uint256) {
         // Require enough total assets in the vault/strategies to cover this withdrawal
         require(totalAssets() >= assetsAmount, QuantumFund__InsufficientFunds());
         return convertToShares(assetsAmount);
    }

    /// @inheritdoc IERC4626
    function withdraw(uint256 assetsAmount, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256 shares) {
        require(assetsAmount > 0, "Withdraw amount must be > 0");

        uint256 sharesAmount = convertToShares(assetsAmount); // Shares needed to withdraw `assetsAmount`
        uint256 ownerShares = balanceOf(owner);
        require(ownerShares >= sharesAmount, QuantumFund__InsufficientFunds()); // User must have enough shares
        require(totalAssets() >= assetsAmount, QuantumFund__InsufficientFunds()); // Vault must have enough total assets

        // Burn shares from owner
        _burn(owner, sharesAmount);

        // Transfer assets to receiver. Pull from vault balance first, then strategies if needed.
        uint256 vaultBalance = asset.balanceOf(address(this));
        uint256 assetsToTransfer = assetsAmount;

        if (vaultBalance >= assetsToTransfer) {
            asset.safeTransfer(receiver, assetsToTransfer);
        } else {
            // Need to pull from strategies
            uint256 vaultTransferAmount = vaultBalance;
            asset.safeTransfer(receiver, vaultTransferAmount);
            assetsToTransfer -= vaultTransferAmount;

            // Pull remaining from strategies based on their current holdings ratio (simplified)
            // A more sophisticated approach would consider target allocation or specific strategy performance
            uint256 totalStratHoldings = getTotalStrategyAssets();
            require(totalStratHoldings >= assetsToTransfer, QuantumFund__InsufficientFunds()); // Should be covered by initial totalAssets check, but double-check.

            // Iterate through approved strategies and withdraw proportionally or sequentially
            for (uint256 i = 0; i < approvedStrategiesList.length && assetsToTransfer > 0; ++i) {
                address stratAddress = approvedStrategiesList[i];
                IInvestmentStrategy strategy = IInvestmentStrategy(stratAddress);
                uint256 stratHoldings = strategy.getHoldings(address(asset));
                if (stratHoldings > 0) {
                     uint256 amountToPullFromStrat = (stratHoldings * assetsAmount) / totalStratHoldings; // Proportional pull
                     amountToPullFromStrat = amountToPullFromStrat > assetsToTransfer ? assetsToTransfer : amountToPullFromStrat;

                     if (amountToPullFromStrat > 0) {
                        uint256 returnedAmount = strategy.withdraw(address(asset), amountToPullFromStrat);
                        require(returnedAmount >= amountToPullFromStrat, "Strategy withdrawal failed or returned less"); // Ensure strategy returned enough
                        asset.safeTransfer(receiver, returnedAmount); // Transfer from strategy to receiver
                        assetsToTransfer -= returnedAmount;
                     }
                }
            }
             require(assetsToTransfer == 0, "Failed to withdraw required assets from strategies"); // Should be 0 if all needed assets were pulled
        }


        emit Withdraw(msg.sender, receiver, owner, assetsAmount, sharesAmount);
        return sharesAmount;
    }

     /// @inheritdoc IERC4626
    function maxRedeem(address owner) public view override returns (uint256) {
        return balanceOf(owner); // Max redeemable shares is user's balance
    }

    /// @inheritdoc IERC4626
    function previewRedeem(uint256 sharesAmount) public view override returns (uint256) {
        // Require enough shares in total supply
        require(totalSupply() >= sharesAmount, QuantumFund__InsufficientFunds());
        return convertToAssets(sharesAmount);
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 sharesAmount, address receiver, address owner) public override nonReentrant whenNotPaused returns (uint256 assetsAmount) {
         require(sharesAmount > 0, "Redeem shares must be > 0");

        uint256 ownerShares = balanceOf(owner);
        require(ownerShares >= sharesAmount, QuantumFund__InsufficientFunds()); // User must have enough shares
        require(totalSupply() >= sharesAmount, QuantumFund__InsufficientFunds()); // Total supply check

        uint256 assetsToTransfer = convertToAssets(sharesAmount); // Assets to transfer for these shares

        // Burn shares from owner
        _burn(owner, sharesAmount);

        // Transfer assets to receiver. Same logic as withdraw.
        uint256 vaultBalance = asset.balanceOf(address(this));
        uint256 assetsTransferredTotal = 0;

        if (vaultBalance >= assetsToTransfer) {
            asset.safeTransfer(receiver, assetsToTransfer);
            assetsTransferredTotal = assetsToTransfer;
        } else {
            // Need to pull from strategies
            uint256 vaultTransferAmount = vaultBalance;
            asset.safeTransfer(receiver, vaultTransferAmount);
            assetsTransferredTotal += vaultTransferAmount;
            uint256 remainingAssetsToTransfer = assetsToTransfer - vaultTransferAmount;

            uint256 totalStratHoldings = getTotalStrategyAssets();
            require(totalStratHoldings >= remainingAssetsToTransfer, QuantumFund__InsufficientFunds());

             for (uint256 i = 0; i < approvedStrategiesList.length && remainingAssetsToTransfer > 0; ++i) {
                address stratAddress = approvedStrategiesList[i];
                IInvestmentStrategy strategy = IInvestmentStrategy(stratAddress);
                uint256 stratHoldings = strategy.getHoldings(address(asset));
                if (stratHoldings > 0) {
                     uint256 amountToPullFromStrat = (stratHoldings * assetsToTransfer) / totalStratHoldings; // Proportional pull relative to original assetsToTransfer
                     amountToPullFromStrat = amountToPullFromStrat > remainingAssetsToTransfer ? remainingAssetsToTransfer : amountToPullFromStrat;

                     if (amountToPullFromStrat > 0) {
                        uint256 returnedAmount = strategy.withdraw(address(asset), amountToPullFromStrat);
                         require(returnedAmount >= amountToPullFromStrat, "Strategy withdrawal failed or returned less");
                        asset.safeTransfer(receiver, returnedAmount);
                        assetsTransferredTotal += returnedAmount;
                        remainingAssetsToTransfer -= returnedAmount;
                     }
                }
            }
            require(remainingAssetsToTransfer == 0, "Failed to withdraw required assets from strategies");
        }

        emit Withdraw(msg.sender, receiver, owner, assetsTransferredTotal, sharesAmount);
        return assetsTransferredTotal;
    }


    // --- Strategy Management ---

    /// @dev Adds a new investment strategy contract that this fund can allocate assets to.
    /// Must be called by Governance.
    /// @param _strategyAddress The address of the external strategy contract.
    /// @param _initialTargetAllocation The initial target percentage (basis points). Must be 0.
    function addInvestmentStrategy(address _strategyAddress, uint256 _initialTargetAllocation)
        external
        onlyGovernance
        whenNotPaused
    {
        require(!investmentStrategies[_strategyAddress].isApproved, "Strategy already approved");
        require(_initialTargetAllocation == 0, "Initial allocation must be zero"); // Allocation set separately

        investmentStrategies[_strategyAddress] = StrategyConfig({
            strategyAddress: _strategyAddress,
            targetAllocationPercent: _initialTargetAllocation,
            isApproved: true
        });
        approvedStrategiesList.push(_strategyAddress);

        emit StrategyAdded(_strategyAddress, _initialTargetAllocation);
    }

    /// @dev Removes an approved strategy. Strategy must have 0 target allocation and 0 holdings.
    /// Must be called by Governance.
    /// @param _strategyAddress The address of the strategy to remove.
    function removeInvestmentStrategy(address _strategyAddress)
        external
        onlyGovernance
        whenNotPaused
    {
        require(investmentStrategies[_strategyAddress].isApproved, QuantumFund__InvalidStrategy());
        require(investmentStrategies[_strategyAddress].targetAllocationPercent == 0, "Strategy target allocation must be zero");
        require(IInvestmentStrategy(_strategyAddress).getHoldings(address(asset)) == 0, "Strategy must have zero holdings");

        investmentStrategies[_strategyAddress].isApproved = false;
        // Remove from approvedStrategiesList (inefficient for large arrays, but simple)
        for (uint256 i = 0; i < approvedStrategiesList.length; ++i) {
            if (approvedStrategiesList[i] == _strategyAddress) {
                approvedStrategiesList[i] = approvedStrategiesList[approvedStrategiesList.length - 1];
                approvedStrategiesList.pop();
                break;
            }
        }

        emit StrategyRemoved(_strategyAddress);
    }

    /// @dev Gets the current asset holdings within a specific approved strategy.
    /// @param _strategyAddress The address of the strategy.
    /// @return The amount of asset held by the strategy.
    function getStrategyHoldings(address _strategyAddress)
        public
        view
        onlyApprovedStrategy(_strategyAddress)
        returns (uint256)
    {
        return IInvestmentStrategy(_strategyAddress).getHoldings(address(asset));
    }

     /// @dev Gets the total asset holdings across all approved strategies.
    /// @return The total amount of asset held by all strategies.
    function getTotalStrategyAssets() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < approvedStrategiesList.length; ++i) {
            address stratAddress = approvedStrategiesList[i];
            if (investmentStrategies[stratAddress].isApproved) { // Double check in case removal failed list update
                 total += IInvestmentStrategy(stratAddress).getHoldings(address(asset));
            }
        }
        return total;
    }


    // --- Allocation & Rebalancing ---

    /// @dev Sets the target allocation percentage for a specific strategy.
    /// This only updates the target, rebalancing needs to be triggered separately.
    /// This function is sensitive and should ideally be called via a queued governance proposal.
    /// @param _strategyAddress The address of the strategy.
    /// @param _newTargetAllocation The new target percentage (basis points).
    function setStrategyTargetAllocation(address _strategyAddress, uint256 _newTargetAllocation)
        external
        onlyGovernance
        whenNotPaused // Rebalancing happens when not paused, setting target should also be.
    {
        require(investmentStrategies[_strategyAddress].isApproved, QuantumFund__InvalidStrategy());
        require(_newTargetAllocation <= 10000, "Allocation percent exceeds 100%");

        investmentStrategies[_strategyAddress].targetAllocationPercent = _newTargetAllocation;

        // Optional: Add a check here that the sum of all target allocations doesn't exceed 10000
        // This could be enforced during queueing/execution instead, allowing temporary sums > 100% during a transition.
        // For simplicity, we'll enforce it on rebalance.

        emit StrategyTargetAllocationSet(_strategyAddress, _newTargetAllocation);
    }

    /// @dev Initiates rebalancing by moving assets between the vault and strategies
    /// based on current target allocations. Can be called by anyone (executor pattern)
    /// but likely triggered by governance or an automated bot.
    function rebalanceStrategies() external nonReentrant whenNotPaused {
        uint256 totalValue = totalAssets(); // Total assets under management

        uint256 totalTargetPercentage = 0;
        for (uint256 i = 0; i < approvedStrategiesList.length; ++i) {
            address stratAddress = approvedStrategiesList[i];
            if (investmentStrategies[stratAddress].isApproved) {
                 totalTargetPercentage += investmentStrategies[stratAddress].targetAllocationPercent;
            }
        }
        require(totalTargetPercentage <= 10000, QuantumFund__AllocationSumMustBe100Percent()); // Enforce total target <= 100%

        uint256 totalAssetsInVault = asset.balanceOf(address(this));

        // Phase 1: Consolidate assets from strategies that are over-allocated or have zero target
        for (uint256 i = 0; i < approvedStrategiesList.length; ++i) {
            address stratAddress = approvedStrategiesList[i];
             if (!investmentStrategies[stratAddress].isApproved) continue; // Skip if removed

            uint256 targetAmount = (totalValue * investmentStrategies[stratAddress].targetAllocationPercent) / 10000;
            uint256 currentHoldings = IInvestmentStrategy(stratAddress).getHoldings(address(asset));

            if (currentHoldings > targetAmount) {
                uint256 amountToWithdraw = currentHoldings - targetAmount;
                // Important: Strategies should withdraw to the vault address
                uint256 returnedAmount = IInvestmentStrategy(stratAddress).withdraw(address(asset), amountToWithdraw);
                totalAssetsInVault += returnedAmount; // Update vault balance tracking
            } else if (investmentStrategies[stratAddress].targetAllocationPercent == 0 && currentHoldings > 0) {
                 // Strategy has 0 target but holds assets - pull everything out
                 uint256 returnedAmount = IInvestmentStrategy(stratAddress).withdrawAll(address(asset));
                 totalAssetsInVault += returnedAmount; // Update vault balance tracking
            }
        }

        // Phase 2: Distribute assets from the vault to strategies that are under-allocated
        for (uint256 i = 0; i < approvedStrategiesList.length; ++i) {
            address stratAddress = approvedStrategiesList[i];
             if (!investmentStrategies[stratAddress].isApproved) continue; // Skip if removed

            uint256 targetAmount = (totalValue * investmentStrategies[stratAddress].targetAllocationPercent) / 10000;
            uint256 currentHoldings = IInvestmentStrategy(stratAddress).getHoldings(address(asset)); // Re-fetch in case of consolidation

            if (currentHoldings < targetAmount) {
                uint256 amountToDeposit = targetAmount - currentHoldings;
                 require(totalAssetsInVault >= amountToDeposit, QuantumFund__InsufficientFunds()); // Should ideally not happen if totalValue is correct

                asset.safeTransfer(stratAddress, amountToDeposit);
                // Note: Strategy deposit might fail or accept less. This is a risk.
                // A robust system would check strategy's new holdings after deposit.
                // For this example, we assume deposit succeeds for the transferred amount.
                // IInvestmentStrategy(stratAddress).deposit(address(asset), amountToDeposit); // Call deposit function
                totalAssetsInVault -= amountToDeposit; // Update vault balance tracking
            }
        }

        // Remaining assets stay in the vault, acting as a buffer or liquidity pool.
        // totalAssetsInVault should now reflect the asset balance in the vault after rebalancing.

        emit StrategiesRebalanced(totalValue); // Emitting total value rebalanced for context
    }

    /// @dev Queues a sensitive strategy allocation change, requiring a timelock before execution.
    /// Must be called by Governance.
    /// @param _strategyAddress The address of the strategy.
    /// @param _newTargetAllocation The new target percentage (basis points).
    /// @param _proposalHash A unique identifier hash for this change proposal (e.g., from the governance contract).
    function queueStrategyAllocationChange(address _strategyAddress, uint256 _newTargetAllocation, bytes32 _proposalHash)
        external
        onlyGovernance
        whenNotPaused
    {
        require(investmentStrategies[_strategyAddress].isApproved, QuantumFund__InvalidStrategy());
        require(_newTargetAllocation <= 10000, "New target percent exceeds 100%");
        require(queuedAllocationChanges[_proposalHash].queueTime == 0, QuantumFund__QueueAlreadyExists()); // Prevent duplicate queues

        queuedAllocationChanges[_proposalHash] = QueuedAllocationChange({
            strategyAddress: _strategyAddress,
            newTargetAllocationPercent: _newTargetAllocation,
            queueTime: block.timestamp,
            proposalHash: _proposalHash
        });

        emit AllocationChangeQueued(_proposalHash, _strategyAddress, _newTargetAllocation, block.timestamp);
    }

     /// @dev Executes a previously queued strategy allocation change after the timelock has expired.
    /// Can be called by anyone after the timelock.
    /// @param _proposalHash The hash of the queued proposal.
    function executeQueuedStrategyAllocationChange(bytes32 _proposalHash)
        external
        whenNotPaused
    {
        QueuedAllocationChange storage queuedChange = queuedAllocationChanges[_proposalHash];
        require(queuedChange.queueTime > 0, QuantumFund__QueueDoesNotExist());
        require(block.timestamp >= queuedChange.queueTime + allocationTimelockDuration, QuantumFund__TimelockNotExpired());

        // Perform the actual change
        address stratAddress = queuedChange.strategyAddress;
        uint256 newAllocation = queuedChange.newTargetAllocationPercent;

        // Ensure strategy is still approved (it could have been removed via a different process)
        require(investmentStrategies[stratAddress].isApproved, QuantumFund__InvalidStrategy());

        investmentStrategies[stratAddress].targetAllocationPercent = newAllocation;

        // Clear the queued change
        delete queuedAllocationChanges[_proposalHash];

        emit AllocationChangeExecuted(_proposalHash, stratAddress, newAllocation);

        // Note: Rebalancing is not automatically triggered, needs a separate call after execution.
    }

     /// @dev Allows Governance to cancel a queued allocation change before execution.
    /// @param _proposalHash The hash of the queued proposal.
    function cancelQueuedAllocationChange(bytes32 _proposalHash)
        external
        onlyGovernance
        whenNotPaused
    {
         QueuedAllocationChange storage queuedChange = queuedAllocationChanges[_proposalHash];
         require(queuedChange.queueTime > 0, QuantumFund__QueueDoesNotExist());
         require(block.timestamp < queuedChange.queueTime + allocationTimelockDuration, QuantumFund__TimelockStillActive()); // Can only cancel before expiry

         delete queuedAllocationChanges[_proposalHash];

         emit AllocationChangeCancelled(_proposalHash);
    }


    // --- Governance & Parameters ---

    /// @dev Sets the address of the governance contract.
    /// Can only be called by the current owner or the current governance contract itself.
    /// This allows for a smooth transition of power.
    /// @param _newGovernance Address of the new governance contract.
    function setGovernanceAddress(address _newGovernance) external {
        require(msg.sender == owner() || msg.sender == governanceAddress, "Unauthorized: Only owner or current governance");
        require(_newGovernance != address(0), "Governance address cannot be zero");
        address oldGovernance = governanceAddress;
        governanceAddress = _newGovernance;
        emit GovernanceAddressSet(oldGovernance, _newGovernance);
    }

     /// @dev Example function representing a governance call to change a fund parameter.
    /// In a real system, the Governance contract would call specific functions
    /// on this contract using `execute` mechanisms (e.g., calling `setPerformanceFeeRate`).
    /// This function is here to illustrate *how* a governance interaction might look
    /// from the perspective of the fund contract's interface. It doesn't perform
    /// any state change itself.
    function proposeFundParameterChange(address _target, bytes memory _data, uint256 _value)
        external
        onlyGovernance
        pure // This is a pure function for demonstration; a real one wouldn't be.
    {
        // In a real scenario, the governance contract would handle proposals, voting,
        // and then call the *actual* state-changing functions like setPerformanceFeeRate,
        // setAllocationTimelockDuration, pause, unpause, etc., likely via execute().
        // This function just serves as a marker that governance *can* initiate changes.
        // require(_target == address(this), "Target must be this contract"); // Example check
        // require(_data.length > 0, "Call data required"); // Example check
        // require(_value == 0, "Value must be zero for parameter changes"); // Example check (unless transferring ETH)

        // This function does nothing but signal an intent.
        // The actual parameter changes are handled by other `onlyGovernance` functions.
    }


    // --- Fees ---

    /// @dev Sets the rate for performance fees. Fees are calculated and collected
    /// during asset appreciation events or withdrawals/redemptions (implementation detail).
    /// Must be called by Governance.
    /// @param _newRate The new performance fee rate in basis points (e.g., 1000 for 10%).
    function setPerformanceFeeRate(uint256 _newRate) external onlyGovernance {
        require(_newRate <= 10000, "Fee rate exceeds 100%");
        performanceFeeRate = _newRate;
        emit PerformanceFeeRateSet(_newRate);
    }

    /// @dev Sets the address that can claim accumulated fees.
    /// Must be called by Governance.
    /// @param _recipient The address to receive claimed fees.
    function setFeeRecipient(address _recipient) external onlyGovernance {
         require(_recipient != address(0), "Fee recipient cannot be zero address");
         feeRecipient = _recipient;
    }


    /// @dev Allows the designated fee recipient to claim accumulated performance fees.
    /// Fee calculation logic (how _totalPerformanceFees accrues) needs to be implemented
    /// during mint/redeem/deposit/withdraw or a separate harvest function, based on the
    /// value increase of the total assets.
    /// For simplicity in this example, we just show the claiming mechanism.
    function claimFees() external {
        require(msg.sender == feeRecipient, QuantumFund__FeeRecipientNotSet()); // Only the designated recipient can claim
        require(_totalPerformanceFees > 0, "No fees to claim");

        uint256 feesToClaim = _totalPerformanceFees;
        _totalPerformanceFees = 0; // Reset accumulated fees

        asset.safeTransfer(feeRecipient, feesToClaim);

        emit FeesClaimed(feeRecipient, feesToClaim);
    }

    // Note: The mechanism for *calculating* and *accruing* `_totalPerformanceFees`
    // is a complex part of vault design (e.g., based on high-water marks,
    // performance over a period). This example focuses on the claim function.


    // --- Safety & Utility ---

    /// @dev Pauses key operations (deposit, withdraw, mint, redeem, rebalance).
    /// Must be called by Governance.
    function pause() external onlyGovernance whenNotPaused {
        _pause();
    }

    /// @dev Unpauses key operations.
    /// Must be called by Governance.
    function unpause() external onlyGovernance whenPaused {
        _unpause();
    }

    /// @dev Allows Governance to forcefully withdraw assets from a specific strategy
    /// in case of an emergency (e.g., strategy exploit or failure).
    /// @param _strategyAddress The address of the strategy to withdraw from.
    /// @param _amount The amount of asset to withdraw.
    function emergencyWithdrawFromStrategy(address _strategyAddress, uint256 _amount)
        external
        onlyGovernance
        nonReentrant // Prevent re-entrancy during potential external strategy call
    {
        require(investmentStrategies[_strategyAddress].isApproved, QuantumFund__InvalidStrategy());
        require(_amount > 0, "Withdrawal amount must be > 0");

        IInvestmentStrategy strategy = IInvestmentStrategy(_strategyAddress);
        uint256 returnedAmount = strategy.withdraw(address(asset), _amount);

        // The returned assets are now in the vault, ready for rebalancing or withdrawals.
        // No further action needed on them in this function.

        emit EmergencyWithdraw(_strategyAddress, returnedAmount);
    }

    /// @dev Allows Governance to rescue ERC20 tokens accidentally sent to the contract,
    /// provided they are not the main vault asset or the shares token.
    /// @param _token Address of the ERC20 token to rescue.
    /// @param _amount Amount of tokens to rescue.
    /// @param _to Recipient address for the rescued tokens.
    function rescueERC20(IERC20 _token, uint256 _amount, address _to) external onlyGovernance {
        require(address(_token) != address(asset), QuantumFund__CannotRescueVaultAssets());
        require(address(_token) != address(this), QuantumFund__CannotRescueVaultAssets()); // Cannot rescue shares token this way
        require(_amount > 0, "Rescue amount must be > 0");
        require(_to != address(0), "Recipient cannot be zero address");

        _token.safeTransfer(_to, _amount);

        emit ERC20Rescued(address(_token), _amount);
    }

     /// @dev Gets the total value of all assets managed by the fund (vault + strategies)
    /// based on the oracle price.
    /// Requires a trusted oracle to be set.
    /// @return The total value in USD cents.
    function getTotalFundValue() public view returns (uint256) {
        require(trustedOracle != address(0), "Oracle not set");
        IPriceOracle oracle = IPriceOracle(trustedOracle);
        require(oracle.isPriceValid(address(asset)), QuantumFund__OraclePriceInvalid());

        uint256 totalAssetsAmount = totalAssets();
        uint256 assetPrice = oracle.getPrice(address(asset)); // Price in USD cents

        // Calculate total value: (totalAssetsAmount * assetPrice) / (10^decimals) * 100 (for USD cents)
        // Simplify: (totalAssetsAmount * assetPrice) / (10^(asset.decimals))
        // Let's assume asset decimals for price scale match oracle's expected scale (e.g., 1e18 for both)
        // Or adjust based on asset decimals: (totalAssetsAmount * assetPrice) / (10**uint256(asset.decimals()))
        // Example: 100 USDC (6 decimals) at $1.01 (101 cents) -> (100e6 * 101) / 1e6 = 10100 cents ($101)
        // Example: 1 WETH (18 decimals) at $2000 (200000 cents) -> (1e18 * 200000) / 1e18 = 200000 cents ($2000)
        uint256 assetDecimals = asset.decimals();
        return (totalAssetsAmount * assetPrice) / (10**assetDecimals);
    }


    // --- Advanced / Unique Features ---

     /// @dev Sets the address of the trusted price oracle.
    /// Must be called by Governance.
    /// @param _oracle Address of the trusted oracle contract.
    function setTrustedOracle(address _oracle) external onlyGovernance {
        require(_oracle != address(0), "Oracle address cannot be zero");
        address oldOracle = trustedOracle;
        trustedOracle = _oracle;
        emit OracleAddressSet(oldOracle, _oracle);
    }

    /// @dev Triggers a rebalance only if the current fund allocation deviates significantly
    /// from target allocations based on the oracle price and strategy holdings.
    /// Can be called by anyone, allowing for incentivized maintenance.
    /// @param _deviationThresholdPercent Percentage deviation (basis points) to trigger rebalance (e.g., 500 for 5%).
    function triggerRebalanceIfDeviation(uint256 _deviationThresholdPercent) external nonReentrant whenNotPaused {
         require(trustedOracle != address(0), "Oracle not set");
         IPriceOracle oracle = IPriceOracle(trustedOracle);
         require(oracle.isPriceValid(address(asset)), QuantumFund__OraclePriceInvalid());
         // Price of asset relative to itself is always 1, but oracle might be used for strategy internal asset prices

        uint256 totalValue = totalAssets(); // Total assets managed

        uint256 totalTargetValue = 0;
        uint256 totalCurrentValue = 0;

        for (uint256 i = 0; i < approvedStrategiesList.length; ++i) {
            address stratAddress = approvedStrategiesList[i];
            if (!investmentStrategies[stratAddress].isApproved) continue;

            uint256 targetAllocation = investmentStrategies[stratAddress].targetAllocationPercent;
            uint256 currentHoldings = IInvestmentStrategy(stratAddress).getHoldings(address(asset));

            uint256 targetValue = (totalValue * targetAllocation) / 10000; // Value this strategy *should* hold
            // For simplicity, assume strategy holdings are in the main asset.
            // A more complex version would get value of strategy holdings using the oracle.
            uint256 currentValue = currentHoldings; // Value this strategy *does* hold (in terms of the main asset)

            totalTargetValue += targetValue;
            totalCurrentValue += currentValue; // This is summing assets, not value if strategies hold other tokens
        }

        // Check deviation between target allocation and current holdings in the main asset
        // This check is simplified. A real check would compare each strategy's current % vs target %.
        // Example Simplified check: Is the total *amount* of asset in strategies deviating from the total target amount?
        uint256 totalTargetAssetsInStrategies = (totalValue * totalTargetPercentage()) / 10000; // Assuming totalTargetPercentage() exists or is calculated
        uint256 totalCurrentAssetsInStrategies = getTotalStrategyAssets();

        uint256 deviation;
        if (totalTargetAssetsInStrategies > totalCurrentAssetsInStrategies) {
            deviation = totalTargetAssetsInStrategies - totalCurrentAssetsInStrategies;
        } else {
            deviation = totalCurrentAssetsInStrategies - totalTargetAssetsInStrategies;
        }

        // Calculate percentage deviation relative to total target assets in strategies
        uint256 deviationPercent = (deviation * 10000) / totalTargetAssetsInStrategies; // Basis points

        if (deviationPercent >= _deviationThresholdPercent) {
            emit RebalanceTriggeredByDeviation(deviationPercent);
            rebalanceStrategies(); // Trigger rebalance if deviation is met
        }
    }

    /// @dev Allows users to deposit using an ERC-20 Permit signature, avoiding the need for a separate `approve` transaction.
    /// Requires the underlying asset token to support EIP-2612 Permit.
    /// @param assets Amount of assets to deposit.
    /// @param receiver Address to receive shares.
    /// @param deadline Permit deadline.
    /// @param v, r, s Permit signature components.
    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant whenNotPaused returns (uint256 shares) {
        // Use Permit to approve the transfer
        IERC20Permit(address(asset)).permit(msg.sender, address(this), assets, deadline, v, r, s);

        // Then perform the standard deposit
        return deposit(assets, receiver);
    }

    /// @dev (Example) Checks if a user is eligible for an NFT-based boost.
    /// Requires the `nftBoostContractAddress` to be set to an ERC-721 or ERC-1155 contract.
    /// This is a view function and doesn't affect state directly, but could be used
    /// within governance logic (e.g., `onlyGovernance` calls `checkNFTBoostEligibility`).
    /// @param _account The account to check.
    /// @return True if the account holds an NFT from the specified contract.
    function checkNFTBoostEligibility(address _account) public view returns (bool) {
        if (nftBoostContractAddress == address(0)) {
            return false; // No boost configured
        }
        // This is a simplified check. A real implementation would need to know
        // if it's ERC721 (check balanceOf > 0) or ERC1155 (check balanceOf > 0 for specific token ID).
        // For demonstration, we'll just return true if the address is not zero.
        // return IERC721(nftBoostContractAddress).balanceOf(_account) > 0; // Example for ERC721
        // return IERC1155(nftBoostContractAddress).balanceOf(_account, TOKEN_ID) > 0; // Example for ERC1155
        return true; // Placeholder logic: assume eligibility if contract address is set
    }

    /// @dev Sets the address of the NFT contract used for boost eligibility.
    /// Must be called by Governance.
    /// @param _nftContractAddress Address of the NFT contract.
    function setNFTBoostContractAddress(address _nftContractAddress) external onlyGovernance {
        nftBoostContractAddress = _nftContractAddress;
        emit NFTBoostContractSet(_nftBoostContractAddress);
    }

    /// @dev Triggers an emergency exit from a strategy if a specific oracle condition is met.
    /// Example: If the price of a strategy's underlying asset drops below a threshold.
    /// This function is highly specific and requires detailed condition logic.
    /// For this example, we'll simulate a condition based on the main asset price.
    /// @param _strategyAddress The strategy to potentially exit.
    /// @param _priceThreshold The price threshold (in USD cents) below which to exit.
    function conditionalStrategyExitBasedOnOracle(address _strategyAddress, uint256 _priceThreshold)
        external
        nonReentrant // Prevent re-entrancy during strategy withdrawal
        whenNotPaused
        onlyGovernance // Likely governance permission needed for emergency exits
    {
         require(investmentStrategies[_strategyAddress].isApproved, QuantumFund__InvalidStrategy());
         require(trustedOracle != address(0), "Oracle not set");
         IPriceOracle oracle = IPriceOracle(trustedOracle);
         require(oracle.isPriceValid(address(asset)), QuantumFund__OraclePriceInvalid());

         uint256 currentAssetPrice = oracle.getPrice(address(asset));

         // Define the condition: exit if asset price drops below threshold
         if (currentAssetPrice < _priceThreshold) {
             // Execute emergency withdrawal of ALL assets from this strategy
             IInvestmentStrategy strategy = IInvestmentStrategy(_strategyAddress);
             uint256 holdings = strategy.getHoldings(address(asset));
             if (holdings > 0) {
                 uint256 returnedAmount = strategy.withdrawAll(address(asset));
                 emit ConditionalExitTriggered(_strategyAddress, returnedAmount, "Asset price below threshold");
             } else {
                  // Condition met, but nothing to withdraw
                  emit ConditionalExitTriggered(_strategyAddress, 0, "Asset price below threshold - Strategy empty");
             }

             // Optionally set target allocation to 0 and remove the strategy via governance after exit.

         } else {
             revert(QuantumFund__ConditionalExitNotMet()); // Condition not met, do not exit
         }
    }

    // --- Internal/Helper Functions ---

    /// @dev Calculates the sum of all target allocations for approved strategies.
    /// @return Total target allocation percentage in basis points.
    function totalTargetPercentage() internal view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < approvedStrategiesList.length; ++i) {
             address stratAddress = approvedStrategiesList[i];
             if (investmentStrategies[stratAddress].isApproved) {
                 total += investmentStrategies[stratAddress].targetAllocationPercent;
             }
        }
        return total;
    }

    // Helper for basic arithmetic, although SafeMath is often preferred
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

     function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        uint256 c = a / b;
        return c;
    }


     // ERC20 standard functions (_mint, _burn, _transfer, _approve, _beforeTokenTransfer)
     // are handled by inheriting OpenZeppelin's ERC20 contract.
     // Pausability (_pause, _unpause) by OpenZeppelin's Pausable.
     // ReentrancyGuard by OpenZeppelin's ReentrancyGuard.
     // Ownership (owner(), renounceOwnership(), transferOwnership()) by OpenZeppelin's Ownable (used only for initial setup/governance transition).
}
```