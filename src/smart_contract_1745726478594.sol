Okay, here is a Solidity smart contract for a "Quantum Strategy Fund". This contract aims to be creative by combining:

1.  **Pooled Capital:** Standard fund mechanism.
2.  **Dynamic Strategy Allocation:** Funds are notionally allocated to various "strategies" based on weights provided by an external oracle (simulating an AI or expert system).
3.  **On-Chain Governance:** Governors can approve new strategies, change fund parameters (like fees), and manage the oracle address.
4.  **Tokenized Shares:** Investors receive ERC-20 tokens representing their stake.
5.  **Multiple Asset Support:** Can accept and manage multiple whitelisted ERC-20 tokens.

This setup is more complex than a basic vault or staking contract, incorporating elements of DeFi, Oracles, and DAO-like governance. It avoids simple duplicates like standard ERC-20s, basic NFTs, or typical yield aggregators by focusing on the internal decision-making process driven by external signals and internal governance.

We will target **at least 20 functions** including read, write, and admin/governance functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Outline ---
// 1. Contract Definition: QuantumStrategyFund inheriting ERC20, Ownable, Pausable.
// 2. Libraries: SafeERC20, EnumerableSet.
// 3. Events: Tracking key actions (Deposits, Redemptions, Strategy management, Governance).
// 4. Structs: Strategy details, Governance proposals (for parameters, strategies).
// 5. State Variables:
//    - Fund state (total assets, total shares, allowed assets).
//    - Strategy state (list of active strategies, current weights, proposal tracking).
//    - Governance state (list of governors, proposal tracking, voting threshold).
//    - Oracle state (oracle address).
//    - Fund parameters (min deposit, fees - simplified for this example).
// 6. Modifiers: Access control for governance and oracle.
// 7. Core Fund Logic: Deposit, Redeem, NAV calculation (simplified).
// 8. Asset Management: Whitelisting assets.
// 9. Strategy Management: Proposing, Voting, Executing, Deactivating strategies. Dynamic weighting based on oracle.
// 10. Capital Allocation: Triggering weight rebalancing based on oracle signal.
// 11. Governance: Adding/Removing governors, proposing/voting/executing parameter changes.
// 12. Oracle Management: Setting the oracle address.
// 13. Risk Management: Pausing.
// 14. View Functions: Retrieving state information.

// --- Function Summary ---
// Constructor: Initializes the fund with owner, name, symbol, and base asset.
// fundDeposit: Allows users to deposit allowed assets into the fund.
// fundRedeem: Allows users to redeem shares for proportional assets.
// addAllowedAsset: Owner adds an ERC20 asset to the allowed deposit list.
// removeAllowedAsset: Owner removes an ERC20 asset from the allowed deposit list.
// getAllowedAssets: Returns the list of allowed deposit assets.
// getAssetBalance: Returns the fund's balance of a specific asset.
// proposeStrategy: Allows anyone to propose a new investment strategy.
// voteOnStrategyProposal: Governors vote on a strategy proposal.
// executeStrategyProposal: Owner/Governor executes an approved strategy proposal.
// deactivateStrategy: Owner/Governor deactivates an active strategy.
// getStrategyProposal: Returns details of a strategy proposal.
// getAllStrategyProposals: Returns all active strategy proposals.
// getActiveStrategies: Returns the list of active strategy IDs.
// getStrategyDetails: Returns details of an active strategy.
// updateStrategyWeightsSignal: Oracle updates the target allocation weights for strategies.
// rebalanceFundWeights: Anyone can trigger the fund to adopt the latest oracle weights.
// getCurrentStrategyWeights: Returns the current strategy weights.
// addGovernor: Owner adds a new governor.
// removeGovernor: Owner removes a governor.
// isGovernor: Checks if an address is a governor.
// setGovernorThreshold: Owner sets the minimum votes required for a proposal.
// proposeFundParameterChange: Governors propose changing fund parameters.
// voteOnFundParameterChange: Governors vote on a parameter change proposal.
// executeFundParameterChange: Owner/Governor executes an approved parameter change proposal.
// getFundParameterProposal: Returns details of a parameter change proposal.
// getAllFundParameterProposals: Returns all active parameter change proposals.
// setAllocationOracle: Owner sets the address of the allocation oracle.
// getAllocationOracle: Returns the oracle address.
// pause: Owner pauses the fund (inherits Pausable).
// unpause: Owner unpauses the fund (inherits Pausable).
// getNAV: Calculates a simplified Net Asset Value (based on total deposited value relative to shares).
// getSharePrice: Calculates the price of one share (NAV per share).
// getTotalAssets: Returns the total value of assets managed (simplified).
// claimGovernanceFunds: Allows governors to claim any funds designated for governance use (e.g., proposal bonds).

contract QuantumStrategyFund is ERC20, Ownable, Pausable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    // --- Events ---
    event Deposited(address indexed user, address indexed asset, uint256 amount, uint256 sharesMinted);
    event Redeemed(address indexed user, uint256 sharesBurned, uint256 totalValueReturned); // Simplified: total value in a base unit
    event AssetAllowed(address indexed asset);
    event AssetRemoved(address indexed asset);
    event StrategyProposed(uint256 indexed proposalId, address indexed proposer, bytes32 strategyHash); // strategyHash links to off-chain details
    event StrategyProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event StrategyProposalExecuted(uint256 indexed proposalId, uint256 indexed strategyId);
    event StrategyDeactivated(uint256 indexed strategyId);
    event StrategyWeightsUpdated(uint256[] strategyIds, uint256[] weights); // Weights in basis points (1/100 of a percent)
    event RebalanceTriggered();
    event GovernorAdded(address indexed governor);
    event GovernorRemoved(address indexed governor);
    event GovernorThresholdSet(uint256 threshold);
    event FundParameterProposed(uint256 indexed proposalId, address indexed proposer, uint8 paramType, uint256 newValue);
    event FundParameterVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event FundParameterExecuted(uint256 indexed proposalId, uint8 paramType, uint256 newValue);
    event AllocationOracleSet(address indexed oracle);

    // --- Structs ---
    struct Strategy {
        uint256 id;
        bytes32 strategyHash; // A hash linking to off-chain strategy details (e.g., IPFS)
        bool isActive;
    }

    struct StrategyProposal {
        uint256 proposalId;
        bytes32 strategyHash;
        address proposer;
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    struct ParameterProposal {
        uint256 proposalId;
        uint8 paramType; // e.g., 0 for MinDeposit, 1 for ManagementFee, 2 for PerformanceFee etc.
        uint256 newValue;
        address proposer;
        uint256 voteCountYes;
        uint256 voteCountNo;
        mapping(address => bool) hasVoted;
        bool executed;
    }

    // --- State Variables ---
    EnumerableSet.AddressSet private _allowedDepositAssets;
    mapping(address => uint256) private _assetBalances; // Track fund's balance of allowed assets

    uint256 private _nextStrategyId = 1;
    mapping(uint256 => Strategy) private _strategies; // Active strategies mapped by ID
    EnumerableSet.UintSet private _activeStrategyIds;
    mapping(uint256 => uint256) private _currentStrategyWeights; // Strategy weights in basis points (sum must be 10000)
    mapping(uint256 => uint256) private _targetStrategyWeights; // Weights proposed by oracle

    uint256 private _nextStrategyProposalId = 1;
    mapping(uint256 => StrategyProposal) private _strategyProposals;
    EnumerableSet.UintSet private _activeStrategyProposalIds;

    EnumerableSet.AddressSet private _governors;
    uint256 private _governorThreshold; // Minimum number of governor votes needed

    uint256 private _nextParameterProposalId = 1;
    mapping(uint256 => ParameterProposal) private _parameterProposals;
    EnumerableSet.UintSet private _activeParameterProposalIds;

    address private _allocationOracle;

    // Fund Parameters (Simplified - could be part of ParameterProposal enum)
    uint256 public minDeposit = 1e18; // Example: 1 Base Unit (ETH/Stablecoin)
    uint256 public managementFeeBasisPoints = 0; // Example: 0.1% = 10
    uint256 public performanceFeeBasisPoints = 0; // Example: 10% = 1000
    // Note: Fee calculation & distribution logic is complex and omitted for brevity,
    // focusing on governance & allocation mechanisms.

    // --- Modifiers ---
    modifier onlyGovernor() {
        require(_governors.contains(_msgSender()), "QuantumFund: Not a governor");
        _;
    }

    modifier onlyOracle() {
        require(_msgSender() == _allocationOracle, "QuantumFund: Not the allocation oracle");
        _;
    }

    // --- Constructor ---
    constructor(
        address initialBaseAsset, // e.g., WETH, USDC - used for initial deposit/NAV reference
        uint256 initialMinDeposit,
        uint256 initialGovernorThreshold,
        address initialOracle
    ) ERC20("QuantumStrategyFund Shares", "QFS") Ownable(_msgSender()) Pausable() {
        require(initialGovernorThreshold > 0, "QuantumFund: Governor threshold must be positive");
        require(initialOracle != address(0), "QuantumFund: Oracle address cannot be zero");

        _addAllowedAsset(initialBaseAsset); // Add the base asset initially
        minDeposit = initialMinDeposit;
        _governorThreshold = initialGovernorThreshold;
        _allocationOracle = initialOracle;
    }

    // --- Core Fund Logic ---

    /// @notice Allows users to deposit allowed assets into the fund.
    /// Shares are minted based on the current share price (NAV per share).
    /// @param asset The address of the ERC20 token to deposit.
    /// @param amount The amount of tokens to deposit.
    function fundDeposit(address asset, uint256 amount) external payable whenNotPaused {
        require(_allowedDepositAssets.contains(asset), "QuantumFund: Asset not allowed");
        require(amount >= minDeposit, "QuantumFund: Deposit amount below minimum");

        uint256 totalShares = totalSupply();
        uint256 sharesToMint;

        if (totalShares == 0) {
            // First deposit sets the initial share price (1 share = 1 unit of base asset value)
            // Assuming the first deposit is the base asset
            require(asset == _allowedDepositAssets.at(0), "QuantumFund: First deposit must be the base asset");
            sharesToMint = amount;
        } else {
            // Calculate shares based on current NAV per share
            // Simplified NAV: Total assets (in base units) / Total shares
            // This requires valuing assets consistently. For simplicity, we'll use the initial base asset deposit value
            // as the reference point. Real funds need price oracles for accurate NAV.
            // Here, we calculate shares based on the ratio of the new deposit value (in base units) to current total value.
            // This simplified model assumes all assets convert to a base value perfectly.
            // A more accurate NAV would sum (asset balance * asset price) / shares.
            // For this example, we will calculate shares based on the fund's *total share* count and *total asset value (simplified)*.
            // Let's use a simplified model where NAV is tracked as total shares issued vs total value deposited *at the time of deposit*.
            // We don't track asset prices dynamically. NAV is total initial value represented by shares.

            // Simplified NAV calculation: Value is represented by total shares issued against initial deposits.
            // The value of the fund grows by asset appreciation (not tracked here) and income (also not tracked).
            // To calculate shares for new deposit: (new deposit value / current NAV) * total shares
            // Where current NAV is total shares issued initially represented value.
            // Let's simplify further: Shares are minted proportionally to the *base asset value* of the deposit.
            // This implies we need to know the value of `asset` in terms of the base asset. This requires an oracle.
            // To keep it self-contained *without* complex asset price oracles, we will use a highly simplified NAV:
            // Total shares issued = Total amount of the *initial base asset* ever deposited.
            // This makes subsequent asset deposits problematic for share calculation.

            // Let's try another simplified NAV model: NAV is calculated as total *quantity* of assets *normalized* to the base asset quantity.
            // This still requires exchange rates.

            // *Final Simplified Approach for NAV & Shares:*
            // Total shares minted = total *value* deposited / initial share price (which is 1).
            // Total value deposited = sum of all deposited amounts * their value relative to the base asset *at deposit time*.
            // This needs an external call or oracle for the relative value.
            // Let's track total value *represented by shares* in a conceptual base unit.
            // When depositing, user deposits Asset A. We need value_A in BaseUnit.
            // shares_minted = (amount_A * value_A_in_BaseUnit) / current_share_price.
            // Current_share_price = total_value_in_fund / total_shares.
            // Total_value_in_fund = sum of (asset_balance * asset_price_in_BaseUnit). Again, needs oracle.

            // Let's use a very basic share calculation: shares are minted based on the ratio of total supply to fund asset balance.
            // This works best with a single asset fund. With multiple assets, NAV is complex.
            // To meet the "multiple asset" requirement *and* have a semblance of NAV:
            // We will track total *quantity* of assets. NAV is the sum of these quantities (ignoring value differences, or assuming they represent 'units').
            // This is a *highly* simplified NAV. A real fund needs price feeds.
            // Simplified NAV = sum of all `_assetBalances[asset]`. Share price = Simplified NAV / totalSupply().

            uint256 currentNAV = getNAV(); // Sum of current asset quantities (simplified)
            // If currentNAV is 0 but totalShares > 0, it implies assets were withdrawn without burning shares? (Bug potential).
            // This state should ideally not happen if deposit/redeem are paired.
            // Let's handle the case where totalShares > 0 but currentNAV is somehow 0 (e.g., assets transferred out directly).
            // In this scenario, share price is effectively infinite. Redemption is impossible. Deposits should yield 0 shares?
            // A robust fund needs invariant checks and proper handling.
            // For this example: if totalShares > 0 and currentNAV is 0, calculate sharePrice as 0 to prevent locking deposits.
            uint256 sharePrice = (totalShares == 0 || currentNAV == 0) ? 0 : currentNAV / totalShares;

            if (sharePrice == 0) {
                 // This happens on the first deposit or if fund value somehow dropped to zero with shares outstanding.
                 // If totalShares is 0, handled above. If currentNAV is 0 with totalShares > 0, something is wrong,
                 // but we cannot mint infinite shares. Mint 0 shares? That's also bad UX.
                 // Let's assume for simplicity this scenario (currentNAV 0, totalShares > 0) doesn't happen with proper usage.
                 // Or, more safely: if totalShares > 0 and currentNAV == 0, revert.
                 revert("QuantumFund: Fund value zero with shares outstanding");
            }

            // Shares to mint = (deposit amount * total shares) / current NAV
            // This formula works when deposit amount is in the same unit as NAV (sum of quantities).
            // Example: Fund has 100 A, 200 B. Total shares 300. NAV = 300. Share price = 1.
            // Deposit 50 A. New NAV = 100+50 + 200 = 350. Shares to mint = (50 * 300) / 300 = 50. New total shares = 350. New NAV 350. Share price 1.
            // This works if assets are interchangeable units for NAV calculation.
            // If assets have different values (1 A = 10 B): NAV = 100*1 + 200*0.1 = 120 (if Base=A). Share price = 120/300=0.4.
            // Deposit 50 A: Value 50. Shares = (50 / 0.4) = 125. New shares 300+125=425. New NAV = (150*1 + 200*0.1) = 170. Share price 170/425=0.4.
            // The formula `shares = (amount * total shares) / current NAV` is correct *if* `amount` is the value *in the NAV unit*.
            // Since our simplified NAV is just sum of quantities, amount must be in quantities.
            sharesToMint = (amount * totalShares) / currentNAV;
        }

        // Transfer tokens to the contract
        IERC20(asset).safeTransferFrom(_msgSender(), address(this), amount);
        _assetBalances[asset] += amount;

        // Mint shares
        _mint(_msgSender(), sharesToMint);

        emit Deposited(_msgSender(), asset, amount, sharesToMint);
    }


    /// @notice Allows users to redeem shares for proportional assets.
    /// @param shares The amount of shares to burn.
    /// @dev Redemption uses the current fund asset balances and share ratio.
    /// Assumes assets are redeemed proportionally across all held assets.
    function fundRedeem(uint256 shares) external whenNotPaused {
        require(shares > 0, "QuantumFund: Redeem amount must be positive");
        require(shares <= balanceOf(_msgSender()), "QuantumFund: Insufficient shares");

        uint256 totalShares = totalSupply();
        uint256 currentNAV = getNAV(); // Simplified NAV: sum of asset quantities

        require(totalShares > 0, "QuantumFund: No shares outstanding");
        require(currentNAV > 0, "QuantumFund: Fund has no assets to redeem");

        // Calculate the proportion of the fund the shares represent
        // uint256 shareRatio = (shares * 1e18) / totalShares; // Using 1e18 for fixed point precision
        // Simplified ratio calculation directly on values
        // Note: Integer division means some dust might be left in the contract over many redemptions.
        // A more complex approach tracks dust or forces full redemption.
        uint256 valueToRedeem = (shares * currentNAV) / totalShares;

        _burn(_msgSender(), shares);

        // Distribute assets proportionally based on the calculated value
        // This is still simplified. A real fund might redeem in a single asset or a basket.
        // Let's redeem proportionally based on the *quantity* of each asset held relative to the total simplified NAV.
        uint256 numAllowedAssets = _allowedDepositAssets.length();
        uint256 totalValueDistributed = 0; // Track total distributed value (simplified quantity sum)

        for (uint i = 0; i < numAllowedAssets; i++) {
            address asset = _allowedDepositAssets.at(i);
            uint256 assetBalance = _assetBalances[asset];

            if (assetBalance > 0) {
                // Calculate the proportion of this asset to redeem
                // proportion = (assetBalance / currentNAV) * valueToRedeem
                uint256 assetAmountToRedeem = (assetBalance * valueToRedeem) / currentNAV;

                if (assetAmountToRedeem > 0) {
                    _assetBalances[asset] -= assetAmountToRedeem;
                    IERC20(asset).safeTransfer(_msgSender(), assetAmountToRedeem);
                    totalValueDistributed += assetAmountToRedeem; // Add quantity to total distributed value
                }
            }
        }

        emit Redeemed(_msgSender(), shares, totalValueDistributed);
    }

    /// @notice Calculates a simplified Net Asset Value (NAV) of the fund.
    /// @dev This is a highly simplified calculation, merely summing the quantities of all held assets.
    /// A real fund requires external price feeds (oracles) to calculate NAV based on market values.
    /// @return The simplified total NAV of the fund.
    function getNAV() public view returns (uint256) {
        uint256 totalValue = 0;
        uint256 numAllowedAssets = _allowedDepositAssets.length();
        for (uint i = 0; i < numAllowedAssets; i++) {
            address asset = _allowedDepositAssets.at(i);
            totalValue += _assetBalances[asset]; // Simply sum quantities
        }
        return totalValue;
    }

     /// @notice Calculates the current price of one fund share.
     /// @dev Based on the simplified NAV. Returns 0 if no shares or no assets.
     /// @return The price of one share (NAV per share).
    function getSharePrice() public view returns (uint256) {
        uint256 totalShares = totalSupply();
        uint256 currentNAV = getNAV();

        if (totalShares == 0 || currentNAV == 0) {
            return 0; // Or handle initial price (e.g., 1e18) if needed
        }

        // Returns NAV per share in terms of the base unit of the simplified NAV
        // Multiply NAV by 1e18 before dividing by shares to maintain precision,
        // assuming shares have 18 decimals like standard ERC20.
        return (currentNAV * 1e18) / totalShares;
    }

    /// @notice Returns the total value of assets managed by the fund.
    /// @dev This is the same as the simplified NAV in this contract.
    /// @return The total quantity sum of assets in the fund.
    function getTotalAssets() public view returns (uint256) {
        return getNAV();
    }

    // --- Asset Management ---

    /// @notice Owner adds an ERC20 asset to the list of allowed deposit assets.
    /// @param asset The address of the ERC20 token to allow.
    function addAllowedAsset(address asset) external onlyOwner {
        require(asset != address(0), "QuantumFund: Zero address");
        require(!_allowedDepositAssets.contains(asset), "QuantumFund: Asset already allowed");
        _addAllowedAsset(asset);
        emit AssetAllowed(asset);
    }

    /// @dev Internal helper to add asset.
    function _addAllowedAsset(address asset) internal {
         _allowedDepositAssets.add(asset);
         // Optional: Grant approval to itself or future executor contracts for this asset
         // IERC20(asset).safeIncreaseAllowance(address(this), type(uint256).max); // Example - needs careful consideration
    }


    /// @notice Owner removes an ERC20 asset from the list of allowed deposit assets.
    /// @param asset The address of the ERC20 token to remove.
    /// @dev Cannot remove assets that are currently held in the fund.
    function removeAllowedAsset(address asset) external onlyOwner {
        require(_allowedDepositAssets.contains(asset), "QuantumFund: Asset not allowed");
        require(_assetBalances[asset] == 0, "QuantumFund: Cannot remove asset with balance > 0");
        _allowedDepositAssets.remove(asset);
        emit AssetRemoved(asset);
    }

    /// @notice Returns the list of allowed deposit assets.
    /// @return An array of allowed asset addresses.
    function getAllowedAssets() public view returns (address[] memory) {
        return _allowedDepositAssets.values();
    }

     /// @notice Returns the fund's balance of a specific asset.
     /// @param asset The address of the asset.
     /// @return The balance of the asset held by the fund.
    function getAssetBalance(address asset) public view returns (uint256) {
        return _assetBalances[asset];
    }


    // --- Strategy Management ---

    /// @notice Allows anyone to propose a new investment strategy.
    /// @param strategyHash A bytes32 hash linking to off-chain strategy details (e.g., IPFS CID).
    /// @dev A bond could be required here to prevent spam. Omitted for simplicity.
    /// @return The ID of the created proposal.
    function proposeStrategy(bytes32 strategyHash) external whenNotPaused returns (uint256) {
        uint256 proposalId = _nextStrategyProposalId++;
        StrategyProposal storage proposal = _strategyProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.strategyHash = strategyHash;
        proposal.proposer = _msgSender();
        proposal.executed = false;
        // Initialize vote counts to 0, hasVoted mapping is initially empty

        _activeStrategyProposalIds.add(proposalId);

        emit StrategyProposed(proposalId, _msgSender(), strategyHash);
        return proposalId;
    }

    /// @notice Governors vote on a strategy proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param vote True for Yes, False for No.
    function voteOnStrategyProposal(uint256 proposalId, bool vote) external onlyGovernor {
        StrategyProposal storage proposal = _strategyProposals[proposalId];
        require(proposal.proposalId != 0, "QuantumFund: Strategy proposal does not exist");
        require(!proposal.executed, "QuantumFund: Strategy proposal already executed");
        require(!proposal.hasVoted[_msgSender()], "QuantumFund: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (vote) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }

        emit StrategyProposalVoted(proposalId, _msgSender(), vote);
    }

    /// @notice Owner or Governor executes an approved strategy proposal.
    /// @param proposalId The ID of the proposal to execute.
    /// @dev Requires the number of Yes votes to meet or exceed the governor threshold.
    /// @return The ID of the newly activated strategy.
    function executeStrategyProposal(uint256 proposalId) external whenNotPaused returns (uint256) {
        require(isGovernor(_msgSender()) || _msgSender() == owner(), "QuantumFund: Must be owner or governor to execute strategy proposal");
        StrategyProposal storage proposal = _strategyProposals[proposalId];
        require(proposal.proposalId != 0, "QuantumFund: Strategy proposal does not exist");
        require(!proposal.executed, "QuantumFund: Strategy proposal already executed");
        require(proposal.voteCountYes >= _governorThreshold, "QuantumFund: Proposal has not met threshold");

        proposal.executed = true;
        _activeStrategyProposalIds.remove(proposalId);

        uint256 strategyId = _nextStrategyId++;
        _strategies[strategyId] = Strategy({
            id: strategyId,
            strategyHash: proposal.strategyHash,
            isActive: true
        });
        _activeStrategyIds.add(strategyId);

        // Initialize weight to 0 for the new strategy
        _currentStrategyWeights[strategyId] = 0;
        _targetStrategyWeights[strategyId] = 0;


        emit StrategyProposalExecuted(proposalId, strategyId);
        return strategyId;
    }

    /// @notice Owner or Governor deactivates an active strategy.
    /// @param strategyId The ID of the strategy to deactivate.
    /// @dev Deactivated strategies will no longer receive allocations.
    function deactivateStrategy(uint256 strategyId) external whenNotPaused {
         require(isGovernor(_msgSender()) || _msgSender() == owner(), "QuantumFund: Must be owner or governor to deactivate strategy");
         Strategy storage strategy = _strategies[strategyId];
         require(strategy.id != 0 && strategy.isActive, "QuantumFund: Strategy is not active or does not exist");

         strategy.isActive = false;
         _activeStrategyIds.remove(strategyId);

         // Set weights to 0 for the deactivated strategy immediately
         _currentStrategyWeights[strategyId] = 0;
         _targetStrategyWeights[strategyId] = 0;
         // Note: Funds notionally allocated to this strategy would need to be re-pooled or re-allocated
         // in a real system. Here, deactivating just removes it from the active list and sets weights to zero.

         emit StrategyDeactivated(strategyId);
    }

    /// @notice Returns details of a strategy proposal.
    /// @param proposalId The ID of the proposal.
    /// @return proposalId_, strategyHash_, proposer_, voteCountYes_, voteCountNo_, executed_
    function getStrategyProposal(uint256 proposalId) external view returns (
        uint256 proposalId_,
        bytes32 strategyHash_,
        address proposer_,
        uint256 voteCountYes_,
        uint256 voteCountNo_,
        bool executed_
    ) {
        StrategyProposal storage proposal = _strategyProposals[proposalId];
        require(proposal.proposalId != 0, "QuantumFund: Strategy proposal does not exist");
        return (
            proposal.proposalId,
            proposal.strategyHash,
            proposal.proposer,
            proposal.voteCountYes,
            proposal.voteCountNo,
            proposal.executed
        );
    }

    /// @notice Returns all active strategy proposal IDs.
    /// @return An array of active strategy proposal IDs.
    function getAllStrategyProposals() external view returns (uint256[] memory) {
        return _activeStrategyProposalIds.values();
    }


    /// @notice Returns the list of active strategy IDs.
    /// @return An array of active strategy IDs.
    function getActiveStrategies() public view returns (uint256[] memory) {
        return _activeStrategyIds.values();
    }

    /// @notice Returns details of an active strategy.
    /// @param strategyId The ID of the strategy.
    /// @return strategyId_, strategyHash_, isActive_
    function getStrategyDetails(uint256 strategyId) public view returns (
        uint256 strategyId_,
        bytes32 strategyHash_,
        bool isActive_
    ) {
        Strategy storage strategy = _strategies[strategyId];
         require(strategy.id != 0, "QuantumFund: Strategy does not exist");
         return (
             strategy.id,
             strategy.strategyHash,
             strategy.isActive
         );
    }


    // --- Capital Allocation ---

    /// @notice Called by the allocation oracle to update target strategy weights.
    /// @param strategyIds An array of strategy IDs.
    /// @param weights An array of weights (in basis points) corresponding to the strategyIds.
    /// @dev The sum of weights must be 10000 (100%). Only the designated oracle can call this.
    function updateStrategyWeightsSignal(uint256[] calldata strategyIds, uint256[] calldata weights) external onlyOracle whenNotPaused {
        require(strategyIds.length == weights.length, "QuantumFund: Mismatched array lengths");
        uint256 totalWeight = 0;

        for (uint i = 0; i < strategyIds.length; i++) {
            uint256 strategyId = strategyIds[i];
            uint256 weight = weights[i];

            Strategy storage strategy = _strategies[strategyId];
            require(strategy.id != 0 && strategy.isActive, "QuantumFund: Strategy not found or not active");

            _targetStrategyWeights[strategyId] = weight;
            totalWeight += weight;
        }

        require(totalWeight == 10000, "QuantumFund: Total weights must sum to 10000 basis points");

        // Strategies not included in the oracle signal have their target weight set to 0
        uint256[] memory activeIds = _activeStrategyIds.values();
        for (uint i = 0; i < activeIds.length; i++) {
             bool found = false;
             for (uint j = 0; j < strategyIds.length; j++) {
                 if (activeIds[i] == strategyIds[j]) {
                     found = true;
                     break;
                 }
             }
             if (!found) {
                 _targetStrategyWeights[activeIds[i]] = 0;
             }
        }


        emit StrategyWeightsUpdated(strategyIds, weights);
    }

    /// @notice Anyone can trigger the fund to adopt the latest oracle-provided weights.
    /// @dev This function simply copies the target weights to the current weights.
    /// A real rebalancing function would involve moving assets between strategies,
    /// which is complex and often handled by external executors.
    function rebalanceFundWeights() external whenNotPaused {
         uint256[] memory activeIds = _activeStrategyIds.values();
         for (uint i = 0; i < activeIds.length; i++) {
             uint256 strategyId = activeIds[i];
             _currentStrategyWeights[strategyId] = _targetStrategyWeights[strategyId];
         }
         emit RebalanceTriggered();
    }


    /// @notice Returns the current strategy weights.
    /// @dev These are the weights currently used for notional allocation (e.g., directing new deposits).
    /// @return An array of strategy IDs and their corresponding weights (basis points).
    function getCurrentStrategyWeights() external view returns (uint256[] memory strategyIds, uint256[] memory weights) {
        uint256[] memory activeIds = _activeStrategyIds.values();
        strategyIds = new uint256[](activeIds.length);
        weights = new uint256[](activeIds.length);

        for (uint i = 0; i < activeIds.length; i++) {
            strategyIds[i] = activeIds[i];
            weights[i] = _currentStrategyWeights[activeIds[i]];
        }
        return (strategyIds, weights);
    }


    // --- Governance ---

    /// @notice Owner adds a new governor.
    /// @param governor The address of the new governor.
    function addGovernor(address governor) external onlyOwner {
        require(governor != address(0), "QuantumFund: Zero address");
        require(!_governors.contains(governor), "QuantumFund: Address is already a governor");
        _governors.add(governor);
        emit GovernorAdded(governor);
    }

    /// @notice Owner removes a governor.
    /// @param governor The address of the governor to remove.
    function removeGovernor(address governor) external onlyOwner {
        require(governor != address(0), "QuantumFund: Zero address");
        require(_governors.contains(governor), "QuantumFund: Address is not a governor");
        _governors.remove(governor);
        // If threshold exceeds remaining governors, update threshold (safety measure)
        if (_governorThreshold > _governors.length()) {
             _governorThreshold = _governors.length();
             emit GovernorThresholdSet(_governorThreshold); // Emit event for change
        }
        emit GovernorRemoved(governor);
    }

    /// @notice Checks if an address is a governor.
    /// @param addr The address to check.
    /// @return True if the address is a governor, false otherwise.
    function isGovernor(address addr) public view returns (bool) {
        return _governors.contains(addr);
    }

    /// @notice Owner sets the minimum number of governor votes required for a proposal to pass.
    /// @param threshold The new threshold.
    /// @dev Must be less than or equal to the total number of governors.
    function setGovernorThreshold(uint256 threshold) external onlyOwner {
        require(threshold > 0, "QuantumFund: Threshold must be positive");
        require(threshold <= _governors.length(), "QuantumFund: Threshold cannot exceed number of governors");
        _governorThreshold = threshold;
        emit GovernorThresholdSet(threshold);
    }

    /// @notice Governors propose changing a fund parameter.
    /// @param paramType An identifier for the parameter type.
    /// @param newValue The proposed new value for the parameter.
    /// @return The ID of the created parameter proposal.
    function proposeFundParameterChange(uint8 paramType, uint256 newValue) external onlyGovernor returns (uint256) {
        uint256 proposalId = _nextParameterProposalId++;
        ParameterProposal storage proposal = _parameterProposals[proposalId];
        proposal.proposalId = proposalId;
        proposal.paramType = paramType;
        proposal.newValue = newValue;
        proposal.proposer = _msgSender();
        proposal.executed = false;
        // Initialize vote counts to 0, hasVoted mapping is initially empty

        _activeParameterProposalIds.add(proposalId);

        emit FundParameterProposed(proposalId, _msgSender(), paramType, newValue);
        return proposalId;
    }

    /// @notice Governors vote on a fund parameter change proposal.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param vote True for Yes, False for No.
    function voteOnFundParameterChange(uint256 proposalId, bool vote) external onlyGovernor {
        ParameterProposal storage proposal = _parameterProposals[proposalId];
        require(proposal.proposalId != 0, "QuantumFund: Parameter proposal does not exist");
        require(!proposal.executed, "QuantumFund: Parameter proposal already executed");
        require(!proposal.hasVoted[_msgSender()], "QuantumFund: Already voted on this proposal");

        proposal.hasVoted[_msgSender()] = true;
        if (vote) {
            proposal.voteCountYes++;
        } else {
            proposal.voteCountNo++;
        }

        emit FundParameterVoted(proposalId, _msgSender(), vote);
    }

    /// @notice Owner or Governor executes an approved fund parameter change proposal.
    /// @param proposalId The ID of the proposal to execute.
    /// @dev Requires the number of Yes votes to meet or exceed the governor threshold.
    function executeFundParameterChange(uint256 proposalId) external whenNotPaused {
        require(isGovernor(_msgSender()) || _msgSender() == owner(), "QuantumFund: Must be owner or governor to execute parameter proposal");
        ParameterProposal storage proposal = _parameterProposals[proposalId];
        require(proposal.proposalId != 0, "QuantumFund: Parameter proposal does not exist");
        require(!proposal.executed, "QuantumFund: Parameter proposal already executed");
        require(proposal.voteCountYes >= _governorThreshold, "QuantumFund: Proposal has not met threshold");

        proposal.executed = true;
        _activeParameterProposalIds.remove(proposalId);

        // Apply the parameter change based on paramType
        // This switch statement needs to be updated for each parameter type added
        if (proposal.paramType == 0) { // Example: Assuming 0 is minDeposit
            minDeposit = proposal.newValue;
        }
        // Add other parameter types here
        // else if (proposal.paramType == 1) { managementFeeBasisPoints = proposal.newValue; }
        // else if (proposal.paramType == 2) { performanceFeeBasisPoints = proposal.newValue; }
        else {
            revert("QuantumFund: Unknown parameter type");
        }


        emit FundParameterExecuted(proposalId, proposal.paramType, proposal.newValue);
    }

    /// @notice Returns details of a fund parameter change proposal.
    /// @param proposalId The ID of the proposal.
    /// @return proposalId_, paramType_, newValue_, proposer_, voteCountYes_, voteCountNo_, executed_
    function getFundParameterProposal(uint256 proposalId) external view returns (
        uint256 proposalId_,
        uint8 paramType_,
        uint256 newValue_,
        address proposer_,
        uint256 voteCountYes_,
        uint256 voteCountNo_,
        bool executed_
    ) {
        ParameterProposal storage proposal = _parameterProposals[proposalId];
        require(proposal.proposalId != 0, "QuantumFund: Parameter proposal does not exist");
        return (
            proposal.proposalId,
            proposal.paramType,
            proposal.newValue,
            proposal.proposer,
            proposal.voteCountYes,
            proposal.voteCountNo,
            proposal.executed
        );
    }

     /// @notice Returns all active fund parameter change proposal IDs.
     /// @return An array of active parameter proposal IDs.
    function getAllFundParameterProposals() external view returns (uint256[] memory) {
        return _activeParameterProposalIds.values();
    }

    // --- Oracle Management ---

    /// @notice Owner sets the address of the allocation oracle.
    /// @param oracleAddress The address of the oracle contract or EOA.
    function setAllocationOracle(address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "QuantumFund: Zero address");
        _allocationOracle = oracleAddress;
        emit AllocationOracleSet(oracleAddress);
    }

     /// @notice Returns the address of the allocation oracle.
     /// @return The oracle address.
    function getAllocationOracle() public view returns (address) {
        return _allocationOracle;
    }

    // --- Risk Management ---

    /// @notice Owner pauses the fund (inherits from Pausable).
    /// @dev Prevents deposits, redemptions, and rebalancing.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Owner unpauses the fund (inherits from Pausable).
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- Other Functions ---

    /// @notice Allows governors to claim funds potentially associated with governance actions (e.g., proposal bonds).
    /// @dev Placeholder function. Actual logic depends on how bonds/funds are handled for governance actions.
    /// As no bonds are implemented in this simplified version, this function is illustrative.
    function claimGovernanceFunds(address asset, uint256 amount) external onlyGovernor {
        // Example placeholder: transfer governance-related funds out
        // In a real scenario, logic would check if these funds are designated for governors
        // based on successful proposals, returned bonds, etc.
        // For simplicity, this version doesn't have deposit bonds or other governance funds,
        // but the function is kept to show interaction point.
         revert("QuantumFund: Governance fund claiming not implemented in this version");
         // Example basic transfer (REMOVE IN REAL IMPLEMENTATION without bond logic):
         // require(_assetBalances[asset] >= amount, "QuantumFund: Insufficient governance funds");
         // _assetBalances[asset] -= amount;
         // IERC20(asset).safeTransfer(_msgSender(), amount);
    }


    // Inherited ERC20 functions: totalSupply, balanceOf, transfer, allowance, approve, transferFrom.
    // Inherited Ownable functions: owner, renounceOwnership, transferOwnership.
    // Inherited Pausable functions: paused.

    // Total functions:
    // Constructor (1) + ERC20 (6) + Ownable (3) + Pausable (1) = 11 base functions
    // Custom: fundDeposit (12), fundRedeem (13), getNAV (14), getSharePrice (15), getTotalAssets (16),
    // addAllowedAsset (17), removeAllowedAsset (18), getAllowedAssets (19), getAssetBalance (20),
    // proposeStrategy (21), voteOnStrategyProposal (22), executeStrategyProposal (23), deactivateStrategy (24),
    // getStrategyProposal (25), getAllStrategyProposals (26), getActiveStrategies (27), getStrategyDetails (28),
    // updateStrategyWeightsSignal (29), rebalanceFundWeights (30), getCurrentStrategyWeights (31),
    // addGovernor (32), removeGovernor (33), isGovernor (34), setGovernorThreshold (35),
    // proposeFundParameterChange (36), voteOnFundParameterChange (37), executeFundParameterChange (38),
    // getFundParameterProposal (39), getAllFundParameterProposals (40), setAllocationOracle (41),
    // getAllocationOracle (42), claimGovernanceFunds (43).

    // Total custom functions added: 32
    // Total functions visible/callable including inherited ones: 11 + 32 = 43.
    // This easily exceeds the 20 function requirement.
}
```