This smart contract, named `QuantumEntanglementBondProtocol`, introduces a novel decentralized financial primitive: the **Quantum Entanglement Bond (Q-Bond)**. Inspired by quantum entanglement, Q-Bonds are non-fungible tokens (NFTs) whose principal and yield dynamically interlink with the collective performance and risk profile of other active Q-Bonds within the protocol, external market conditions, and an adaptive risk pool.

It aims to provide a sophisticated, self-adjusting, and resilient yield-bearing instrument that moves beyond fixed-rate or simple variable-rate bonds.

---

**Contract Name:** `QuantumEntanglementBondProtocol`

**Outline:**

1.  **Libraries & Imports:** Utilizes OpenZeppelin contracts for standard functionalities like ERC721, Ownable, Pausable, and SafeERC20 for secure token interactions. Chainlink interfaces for oracle integration.
2.  **Error Handling:** Custom errors for more descriptive revert messages.
3.  **Enums & Structs:**
    *   `DistributionReason`: Enum to categorize distributions from the Contingency Nexus.
    *   `QBondState`: Struct to store detailed information about each Q-Bond, including principal, accrued yield, lock duration, and state variables.
    *   `ParameterProposal`: Struct for managing and tracking proposed changes to protocol parameters, including voting status.
4.  **State Variables:**
    *   Core protocol parameters (e.g., `entanglementWeight`, `nexusContributionRate`, `earlyDisentanglementPenaltyFactor`).
    *   Mappings to store Q-Bond data, active parameter proposals, and voting records.
    *   Global metrics like `entanglementIndex` and `nexusBalance`.
    *   Addresses for the base asset, Chainlink oracle, and designated keepers.
    *   Counters for unique Q-Bond IDs and request IDs for oracle calls.
    *   Time-related variables for Quantum Flux and voting periods.
5.  **Events:** Comprehensive events for all significant actions (minting, redemption, yield claiming, parameter changes, Quantum Flux execution, Nexus distributions, oracle updates).
6.  **Modifiers:** Standard access control modifiers (`onlyOwner`, `onlyKeeper`) and `whenNotPaused`/`whenPaused` from Pausable.
7.  **Constructor:** Initializes the contract with the base asset address, oracle address, and initial keeper address.
8.  **I. Core Q-Bond Management:** Functions for the lifecycle of Q-Bonds – minting, various redemption options, and yield management.
9.  **II. Entanglement & Yield Mechanics:** Logic for calculating the dynamic yield based on the unique Entanglement Index and external factors.
10. **III. Contingency Nexus (Risk Pool):** Functions governing the collective risk pool, its contributions, and distributions for stability.
11. **IV. Quantum Flux & Protocol Health:** The core "rebalancing" mechanism that dynamically adjusts fundamental protocol parameters and risk profiles.
12. **V. Oracle & External Data Integration:** Functions for requesting and processing external data crucial for dynamic behavior (e.g., market volatility).
13. **VI. Governance/Parameter Adjustment (Controlled):** A simplified, owner-controlled mechanism for proposing and enacting changes to protocol parameters.
14. **VII. Utility & Access Control:** Administrative functions for pausing, unpausing, and emergency fund recovery.

---

**Function Summary (28 Functions):**

**I. Core Q-Bond Management**
1.  `mintQBond(uint256 _principalAmount, uint256 _lockDuration)`: Mints a new non-fungible Q-Bond (ERC-721 NFT) by depositing the base asset as principal. Specifies a lock-up duration (in seconds).
2.  `redeemQBond(uint256 _tokenId)`: Allows the owner of a Q-Bond to redeem it after its lock duration has expired. Returns the initial principal plus all accrued dynamic yield.
3.  `earlyDisentangle(uint256 _tokenId)`: Enables early redemption of a Q-Bond before its lock duration ends, applying a pre-defined penalty to the principal and/or accrued yield.
4.  `claimAccruedYield(uint256 _tokenId)`: Allows the owner to claim only the accumulated dynamic yield for their Q-Bond without redeeming the principal, which remains entangled.
5.  `reEntangleYield(uint256 _tokenId)`: Compounds the accumulated dynamic yield back into the Q-Bond's principal, effectively increasing the base for future yield calculation and strengthening the entanglement.
6.  `_updateQBondState(uint256 _tokenId)` (Internal): Helper function called before any interaction with a Q-Bond to update its accrued yield and effective principal based on elapsed time and dynamic rates.

**II. Entanglement & Yield Mechanics**
7.  `_calculateDynamicYieldRate(uint256 _tokenId)` (Internal): Computes the instantaneous dynamic yield rate for a given Q-Bond, considering the global Entanglement Index, current market volatility (from oracle), and the health of the Contingency Nexus.
8.  `updateEntanglementIndex()` (Keeper Callable): Triggered by a designated keeper, this function recalculates and updates the global Entanglement Index, which reflects the collective performance, risk, and health of all active Q-Bonds.
9.  `getEntanglementIndex()` (View): Returns the current, globally calculated Entanglement Index.
10. `getEffectiveYieldRate(uint256 _tokenId)` (View): Provides a real-time view of the effective annual yield rate for a specific Q-Bond, considering all dynamic factors.

**III. Contingency Nexus (Risk Pool)**
11. `_depositToNexus(uint256 _amount)` (Internal): Directs a calculated portion of the yield generated by Q-Bonds into the Contingency Nexus, acting as a collective risk pool.
12. `_distributeFromNexus(uint256 _amount, DistributionReason _reason)` (Internal): Manages the distribution of funds from the Contingency Nexus for purposes such as stabilizing distressed Q-Bonds or boosting yields under specific protocol conditions.
13. `getNexusBalance()` (View): Returns the current total balance held within the Contingency Nexus.
14. `triggerNexusRebalance()` (Keeper Callable): Initiates an internal rebalancing and potential distribution of funds from the Contingency Nexus based on predefined rules, aiming to maintain protocol stability.

**IV. Quantum Flux & Protocol Health**
15. `_executeQuantumFlux()` (Internal, Keeper Callable): The core periodic or event-driven rebalancing mechanism. It dynamically adjusts fundamental entanglement parameters, potentially re-distributing risk/reward profiles or recalibrating Q-Bond values based on long-term collective performance and market conditions.
16. `getQuantumFluxParameters()` (View): Displays the current parameters governing the Quantum Flux mechanism (represented by core protocol parameters).
17. `getAdaptiveCollateralFactor()` (View): Returns the current multiplier dictating the required collateral for minting new Q-Bonds, which adjusts based on overall protocol health and market volatility.

**V. Oracle & External Data Integration**
18. `requestMarketVolatility(address _asset)` (Keeper Callable): Initiates an external call (e.g., Chainlink Functions) to fetch real-time market volatility data for a specified asset, crucial for dynamic yield calculations.
19. `fulfillMarketVolatility(bytes32 _requestId, uint256 _volatility)` (External Callback): A callback function designed to receive and process the market volatility data returned by the oracle (e.g., Chainlink).
20. `setOracleAddress(address _newOracle)` (Owner Callable): Allows the protocol owner to update the address of the external oracle service.

**VI. Governance/Parameter Adjustment (Controlled)**
21. `proposeParameterChange(bytes32 _paramName, uint256 _newValue)`: Allows the owner to propose a change to a key protocol parameter (e.g., `entanglementWeight`, `nexusContributionRate`).
22. `voteOnParameterChange(bytes32 _paramHash, bool _approve)`: Enables the owner to cast a vote (approve/reject) on an active parameter change proposal. (Simplified single-voter system for this example).
23. `executeParameterChange(bytes32 _paramHash)`: Executes a proposed parameter change once it has received sufficient approval votes and its voting period has ended.
24. `setKeeperAddress(address _newKeeper)` (Owner Callable): Sets the address of the designated keeper role, which is responsible for triggering automated protocol functions.

**VII. Utility & Access Control**
25. `pause()` (Owner Callable): Activates a circuit breaker, pausing critical functions of the protocol in case of emergencies.
26. `unpause()` (Owner Callable): Deactivates the circuit breaker, resuming normal protocol operations.
27. `withdrawEmergencyFunds(address _tokenAddress, uint256 _amount)` (Owner Callable): Allows the owner to recover tokens accidentally sent to the contract or trapped funds in emergencies.
28. `getTotalActiveQBonds()` (View): Returns the total number of Q-Bonds that are currently active (not redeemed or early disentangled).

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces for Chainlink (simplified for illustration)
interface IChainlinkFunctionsClient {
    function sendRequest(
        bytes memory _args,
        uint64 _subscriptionId,
        bytes32 _donId,
        uint32 _callbackGasLimit
    ) external returns (bytes32 requestId);
}

interface IChainlinkFunctionsConsumer {
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) external;
}

/**
 * @title QuantumEntanglementBondProtocol
 * @dev A decentralized protocol for creating and managing dynamically interlinked, yield-bearing financial instruments ("Q-Bonds").
 * Q-Bonds are NFTs representing a principal amount and a dynamically adjusting yield, whose value and risk profiles
 * are "entangled" with other Q-Bonds within the protocol based on a collective performance metric, external market data,
 * and an adaptive risk pool.
 *
 * This contract uses OpenZeppelin libraries for standard functionalities (ERC721, Ownable, Pausable, SafeERC20).
 * The uniqueness and "advanced concept" aspects are implemented in the custom logic of the functions,
 * especially around dynamic yield calculation, entanglement index, contingency nexus, and quantum flux.
 */
contract QuantumEntanglementBondProtocol is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    // --- Custom Errors ---
    error InvalidAmount();
    error InvalidDuration();
    error BondNotFound();
    error LockPeriodNotOver();
    error NotOwnerOfBond();
    error NoYieldToClaim();
    error AlreadyEntangled();
    error TransferFailed();
    error NotEnoughBalance();
    error InsufficientCollateral();
    error InvalidParameterName();
    error ProposalNotFound();
    error VotingPeriodActive();
    error NoProposalVotes();
    error ProposalNotApproved();
    error UnauthorizedKeeper();
    error CallFailed();

    // --- Enums & Structs ---
    enum DistributionReason { Stabilization, YieldBoost }

    struct QBondState {
        uint256 principalAmount;      // Initial principal deposited
        uint256 effectivePrincipal;   // Principal + re-entangled yield
        uint256 accruedYield;         // Total yield accumulated
        uint64 lockDuration;          // Lock-up period in seconds
        uint64 creationTime;          // Timestamp of Q-Bond creation
        uint64 lastYieldUpdateTime;   // Last timestamp yield was calculated/updated
        bool active;                  // Is the bond active and not redeemed/disentangled?
    }

    struct ParameterProposal {
        bytes32 paramName;
        uint256 newValue;
        uint64 creationTime;
        uint64 votingEndTime;
        bool approved; // Simplified: true if owner votes true, false otherwise.
        bool executed;
    }

    // --- State Variables ---
    Counters.Counter private _qBondIds; // Counter for unique Q-Bond NFTs
    mapping(uint256 => QBondState) public qBonds; // Stores details of each Q-Bond by token ID
    mapping(bytes32 => ParameterProposal) public parameterProposals; // Stores active parameter proposals

    IERC20 public immutable baseAsset; // The asset used for Q-Bonds (e.g., WETH, USDC)

    // Entanglement & Yield Parameters (modifiable via governance)
    uint256 public entanglementWeight = 1e18; // Weight for Entanglement Index influence (1 = 100%)
    uint256 public volatilityImpactFactor = 5e17; // How much market volatility impacts yield (0.5 = 50%)
    uint256 public nexusContributionRate = 1e17; // 10% of yield contributes to Nexus (0.1 = 10%)
    uint256 public earlyDisentanglementPenaltyFactor = 2e17; // 20% penalty for early disentanglement (0.2 = 20%)
    uint256 public baseYieldRate = 1e16; // Base annual yield rate (0.01 = 1%) - min yield

    // Global Protocol Health Metrics
    uint256 public entanglementIndex; // Reflects collective performance and risk of all active Q-Bonds
    uint256 public nexusBalance; // Total funds in the Contingency Nexus (risk pool)
    uint256 public totalActivePrincipal; // Sum of effectivePrincipal for all active Q-Bonds

    // Oracle & Keeper Addresses
    address public oracleAddress;
    address public keeperAddress;
    uint256 public latestMarketVolatility; // Last fetched market volatility (e.g., 1e18 = 100% volatility)

    // Quantum Flux Parameters
    uint64 public quantumFluxInterval = 7 days; // How often Quantum Flux can be triggered
    uint64 public lastQuantumFluxTime;

    // Parameter Change Voting Parameters
    uint64 public proposalVotingPeriod = 3 days; // How long a proposal is active for voting

    // --- Events ---
    event QBondMinted(uint256 indexed tokenId, address indexed owner, uint256 principal, uint64 lockDuration, uint64 creationTime);
    event QBondRedeemed(uint256 indexed tokenId, address indexed owner, uint256 returnedAmount, uint256 principal, uint256 yield);
    event YieldClaimed(uint256 indexed tokenId, address indexed owner, uint256 amount);
    event YieldReEntangled(uint256 indexed tokenId, address indexed owner, uint256 reEntangledAmount, uint256 newEffectivePrincipal);
    event EarlyDisentangled(uint256 indexed tokenId, address indexed owner, uint256 returnedAmount, uint256 penaltyAmount);
    event EntanglementIndexUpdated(uint256 newIndex);
    event NexusContribution(uint256 indexed tokenId, uint256 amount);
    event NexusDistribution(uint256 amount, DistributionReason reason);
    event QuantumFluxExecuted(uint256 newEntanglementIndex, uint256 totalAdjustedPrincipal);
    event MarketVolatilityRequested(bytes32 indexed requestId, address indexed asset);
    event MarketVolatilityFulfilled(bytes32 indexed requestId, uint256 volatility);
    event OracleAddressUpdated(address newAddress);
    event KeeperAddressUpdated(address newAddress);
    event ParameterProposalCreated(bytes32 indexed paramHash, bytes32 paramName, uint256 newValue, uint64 votingEndTime);
    event ParameterVoteCast(bytes32 indexed paramHash, bool approved);
    event ParameterChangeExecuted(bytes32 indexed paramHash, bytes32 paramName, uint256 newValue);

    // --- Constructor ---
    constructor(
        address _baseAsset,
        address _oracleAddress,
        address _keeperAddress
    ) ERC721("QuantumEntanglementBond", "QEB") Ownable(msg.sender) Pausable() {
        if (_baseAsset == address(0) || _oracleAddress == address(0) || _keeperAddress == address(0)) {
            revert InvalidAddress();
        }
        baseAsset = IERC20(_baseAsset);
        oracleAddress = _oracleAddress;
        keeperAddress = _keeperAddress;
        lastQuantumFluxTime = uint64(block.timestamp); // Initialize
    }

    // --- Modifiers ---
    modifier onlyKeeper() {
        if (msg.sender != keeperAddress) {
            revert UnauthorizedKeeper();
        }
        _;
    }

    // --- I. Core Q-Bond Management ---

    /**
     * @dev Mints a new non-fungible Q-Bond (ERC-721 NFT) by depositing the base asset as principal.
     * Specifies a lock-up duration (in seconds).
     * @param _principalAmount The amount of baseAsset to deposit as principal.
     * @param _lockDuration The lock-up period for the Q-Bond in seconds.
     */
    function mintQBond(uint256 _principalAmount, uint64 _lockDuration) public payable whenNotPaused {
        if (_principalAmount == 0 || _lockDuration == 0) {
            revert InvalidAmount();
        }
        if (_principalAmount < getAdaptiveCollateralFactor()) { // Example check: min collateral
            revert InsufficientCollateral();
        }

        // Transfer principal from sender to contract
        baseAsset.safeTransferFrom(msg.sender, address(this), _principalAmount);

        _qBondIds.increment();
        uint256 newTokenId = _qBondIds.current();

        QBondState storage newBond = qBonds[newTokenId];
        newBond.principalAmount = _principalAmount;
        newBond.effectivePrincipal = _principalAmount;
        newBond.lockDuration = _lockDuration;
        newBond.creationTime = uint64(block.timestamp);
        newBond.lastYieldUpdateTime = uint64(block.timestamp);
        newBond.active = true;

        _safeMint(msg.sender, newTokenId);
        totalActivePrincipal += _principalAmount; // Update global total

        emit QBondMinted(newTokenId, msg.sender, _principalAmount, _lockDuration, newBond.creationTime);
    }

    /**
     * @dev Allows the owner of a Q-Bond to redeem it after its lock duration has expired.
     * Returns the initial principal plus all accrued dynamic yield.
     * @param _tokenId The ID of the Q-Bond to redeem.
     */
    function redeemQBond(uint256 _tokenId) public whenNotPaused {
        _updateQBondState(_tokenId); // Ensure state is up-to-date

        QBondState storage bond = qBonds[_tokenId];
        if (!bond.active || ownerOf(_tokenId) != msg.sender) {
            revert NotOwnerOfBond();
        }
        if (block.timestamp < bond.creationTime + bond.lockDuration) {
            revert LockPeriodNotOver();
        }

        uint256 totalAmount = bond.effectivePrincipal + bond.accruedYield;
        uint256 originalPrincipal = bond.principalAmount; // Store before resetting

        // Transfer funds back
        baseAsset.safeTransfer(msg.sender, totalAmount);

        // Deactivate bond and clean up
        bond.active = false;
        totalActivePrincipal -= bond.effectivePrincipal; // Deduct from global total
        bond.principalAmount = 0; // Clear data for redeemed bond
        bond.effectivePrincipal = 0;
        bond.accruedYield = 0;
        _burn(_tokenId);

        emit QBondRedeemed(_tokenId, msg.sender, totalAmount, originalPrincipal, totalAmount - originalPrincipal);
    }

    /**
     * @dev Enables early redemption of a Q-Bond before its lock duration ends,
     * applying a pre-defined penalty to the principal and/or accrued yield.
     * @param _tokenId The ID of the Q-Bond to early disentangle.
     */
    function earlyDisentangle(uint256 _tokenId) public whenNotPaused {
        _updateQBondState(_tokenId); // Ensure state is up-to-date

        QBondState storage bond = qBonds[_tokenId];
        if (!bond.active || ownerOf(_tokenId) != msg.sender) {
            revert NotOwnerOfBond();
        }
        if (block.timestamp >= bond.creationTime + bond.lockDuration) {
            revert LockPeriodNotOver(); // Use redeemQBond if lock is over
        }

        uint256 penalty = (bond.effectivePrincipal * earlyDisentanglementPenaltyFactor) / 1e18; // Example penalty calculation
        uint256 returnedAmount = (bond.effectivePrincipal + bond.accruedYield) - penalty;
        if (returnedAmount > baseAsset.balanceOf(address(this))) { // Prevent reentrancy or draining
            revert NotEnoughBalance();
        }

        baseAsset.safeTransfer(msg.sender, returnedAmount);

        // Deactivate bond and clean up
        bond.active = false;
        totalActivePrincipal -= bond.effectivePrincipal; // Deduct from global total
        bond.principalAmount = 0; // Clear data for disentangled bond
        bond.effectivePrincipal = 0;
        bond.accruedYield = 0;
        _burn(_tokenId);

        emit EarlyDisentangled(_tokenId, msg.sender, returnedAmount, penalty);
    }

    /**
     * @dev Allows the owner to claim only the accumulated dynamic yield for their Q-Bond
     * without redeeming the principal, which remains entangled.
     * @param _tokenId The ID of the Q-Bond to claim yield from.
     */
    function claimAccruedYield(uint256 _tokenId) public whenNotPaused {
        _updateQBondState(_tokenId); // Ensure state is up-to-date

        QBondState storage bond = qBonds[_tokenId];
        if (!bond.active || ownerOf(_tokenId) != msg.sender) {
            revert NotOwnerOfBond();
        }
        if (bond.accruedYield == 0) {
            revert NoYieldToClaim();
        }

        uint256 yieldToClaim = bond.accruedYield;
        bond.accruedYield = 0; // Reset accrued yield after claiming

        baseAsset.safeTransfer(msg.sender, yieldToClaim);

        emit YieldClaimed(_tokenId, msg.sender, yieldToClaim);
    }

    /**
     * @dev Compounds the accumulated dynamic yield back into the Q-Bond's principal,
     * effectively increasing the base for future yield calculation and strengthening the entanglement.
     * @param _tokenId The ID of the Q-Bond to re-entangle yield for.
     */
    function reEntangleYield(uint256 _tokenId) public whenNotPaused {
        _updateQBondState(_tokenId); // Ensure state is up-to-date

        QBondState storage bond = qBonds[_tokenId];
        if (!bond.active || ownerOf(_tokenId) != msg.sender) {
            revert NotOwnerOfBond();
        }
        if (bond.accruedYield == 0) {
            revert NoYieldToClaim(); // No yield to re-entangle
        }

        uint256 yieldToReEntangle = bond.accruedYield;
        bond.effectivePrincipal += yieldToReEntangle; // Add yield to effective principal
        totalActivePrincipal += yieldToReEntangle; // Update global total
        bond.accruedYield = 0; // Reset accrued yield
        bond.lastYieldUpdateTime = uint64(block.timestamp); // Reset last update time

        emit YieldReEntangled(_tokenId, msg.sender, yieldToReEntangle, bond.effectivePrincipal);
    }

    /**
     * @dev Internal helper function called before any interaction with a Q-Bond to update its
     * accrued yield and effective principal based on elapsed time and dynamic rates.
     * @param _tokenId The ID of the Q-Bond to update.
     */
    function _updateQBondState(uint256 _tokenId) internal {
        QBondState storage bond = qBonds[_tokenId];
        if (!bond.active) {
            revert BondNotFound();
        }

        uint64 timeElapsed = uint64(block.timestamp) - bond.lastYieldUpdateTime;
        if (timeElapsed == 0) return; // No time elapsed, no update needed

        uint256 dynamicRate = _calculateDynamicYieldRate(_tokenId); // Get current dynamic rate
        uint256 yieldGenerated = (bond.effectivePrincipal * dynamicRate * timeElapsed) / (1e18 * 365 days); // Annualized yield

        bond.accruedYield += yieldGenerated;
        bond.lastYieldUpdateTime = uint64(block.timestamp);

        // Portion of yield sent to Nexus
        uint256 nexusContribution = (yieldGenerated * nexusContributionRate) / 1e18;
        _depositToNexus(nexusContribution);
        // Reduce bond's accrued yield by contribution, so bond owner claims net
        bond.accruedYield -= nexusContribution; // This assumes Nexus contribution is taken from generated yield

        emit NexusContribution(_tokenId, nexusContribution);
    }

    // --- II. Entanglement & Yield Mechanics ---

    /**
     * @dev Internal function: Computes the instantaneous dynamic yield rate for a given Q-Bond,
     * considering the global Entanglement Index, current market volatility (from oracle),
     * and the health of the Contingency Nexus.
     * @param _tokenId The ID of the Q-Bond for which to calculate the rate.
     * @return The dynamic yield rate (scaled by 1e18 for percentage).
     */
    function _calculateDynamicYieldRate(uint256 _tokenId) internal view returns (uint256) {
        // Example dynamic yield formula:
        // Base Yield + (Entanglement Index influence) - (Volatility Impact) + (Nexus Health Boost)

        uint256 currentYield = baseYieldRate;

        // Influence of Entanglement Index (higher index = higher yield)
        // Capped to prevent extreme swings
        uint256 entIndexEffect = (entanglementIndex * entanglementWeight) / 1e18; // Normalize by weight
        currentYield += entIndexEffect;

        // Impact of Market Volatility (higher volatility = lower yield/higher risk premium)
        uint256 volatilityEffect = (latestMarketVolatility * volatilityImpactFactor) / 1e18; // Normalize by factor
        currentYield = currentYield > volatilityEffect ? currentYield - volatilityEffect : 0;

        // Contingency Nexus Health Boost (if Nexus is healthy, it can boost yields)
        // Simplified: if nexus balance is above a threshold, add a small boost.
        if (nexusBalance > (totalActivePrincipal / 100)) { // Example: If Nexus is >1% of total principal
            currentYield += (currentYield / 20); // 5% boost on current yield
        }

        return currentYield;
    }

    /**
     * @dev Triggered by a designated keeper, this function recalculates and updates the global
     * Entanglement Index, which reflects the collective performance, risk, and health of all active Q-Bonds.
     * This is a simplified calculation for demonstration. In a real scenario, this would involve
     * a complex algorithm over all active bonds, potentially considering their performance,
     * remaining lock durations, and even external market factors.
     */
    function updateEntanglementIndex() public onlyKeeper whenNotPaused {
        uint256 newEntanglementIndex = 0;
        if (totalActivePrincipal > 0) {
            // Simplified logic: index is a weighted average of effective principal and time
            // More complex logic would involve bond-specific performance, risk factors etc.
            newEntanglementIndex = (totalActivePrincipal * 1e18) / 1e18; // Just total principal as example
            // Add a slight multiplier based on how long bonds have been active, simulating collective "maturity"
            // This would require iterating over bonds or maintaining a cumulative time counter, omitted for gas brevity
        }
        entanglementIndex = newEntanglementIndex;
        emit EntanglementIndexUpdated(newEntanglementIndex);
    }

    /**
     * @dev Returns the current, globally calculated Entanglement Index.
     */
    function getEntanglementIndex() public view returns (uint256) {
        return entanglementIndex;
    }

    /**
     * @dev Provides a real-time view of the effective annual yield rate for a specific Q-Bond,
     * considering all dynamic factors. This function itself doesn't update the state.
     * @param _tokenId The ID of the Q-Bond.
     * @return The effective yield rate (scaled by 1e18).
     */
    function getEffectiveYieldRate(uint256 _tokenId) public view returns (uint256) {
        // This function must not modify state, so it cannot call _updateQBondState
        // It provides the *current potential* rate if updated now.
        QBondState storage bond = qBonds[_tokenId];
        if (!bond.active) {
            return 0; // Or revert BondNotFound()
        }
        return _calculateDynamicYieldRate(_tokenId);
    }

    // --- III. Contingency Nexus (Risk Pool) ---

    /**
     * @dev Internal function: Directs a calculated portion of the yield generated by Q-Bonds
     * into the Contingency Nexus, acting as a collective risk pool.
     * @param _amount The amount to deposit into the Nexus.
     */
    function _depositToNexus(uint256 _amount) internal {
        if (_amount > 0) {
            nexusBalance += _amount;
        }
    }

    /**
     * @dev Internal function: Manages the distribution of funds from the Contingency Nexus
     * for purposes such as stabilizing distressed Q-Bonds or boosting yields under
     * specific protocol conditions.
     * @param _amount The amount to distribute from the Nexus.
     * @param _reason The reason for the distribution (e.g., Stabilization, YieldBoost).
     */
    function _distributeFromNexus(uint256 _amount, DistributionReason _reason) internal {
        if (_amount == 0 || nexusBalance < _amount) {
            revert NotEnoughBalance();
        }
        nexusBalance -= _amount;
        // In a real scenario, this would involve complex logic to distribute to
        // specific distressed bonds, or proportionally to all active bonds.
        // For this example, we'll just log the distribution.
        emit NexusDistribution(_amount, _reason);
    }

    /**
     * @dev Returns the current total balance held within the Contingency Nexus.
     */
    function getNexusBalance() public view returns (uint256) {
        return nexusBalance;
    }

    /**
     * @dev Initiates an internal rebalancing and potential distribution of funds from the
     * Contingency Nexus based on predefined rules, aiming to maintain protocol stability.
     * Callable by keepers.
     * (Simplified logic for demonstration: if Nexus is too large, distribute some as yield boost).
     */
    function triggerNexusRebalance() public onlyKeeper whenNotPaused {
        uint256 nexusTarget = (totalActivePrincipal * nexusContributionRate) / 1e18; // Example target
        if (nexusBalance > nexusTarget * 2) { // If Nexus is double its "target" size
            uint256 excess = nexusBalance - nexusTarget;
            _distributeFromNexus(excess / 2, DistributionReason.YieldBoost); // Distribute half the excess
            // In a real system, this would then flow back to Q-Bonds as yield or directly to holders
        } else if (nexusBalance < nexusTarget / 2 && totalActivePrincipal > 0) { // If Nexus is too low
            // In a real system, this could trigger a temporary increase in nexusContributionRate
            // or a call to governance for re-collateralization.
            // For now, no automatic "top-up" from elsewhere, just acknowledges low health.
        }
    }

    // --- IV. Quantum Flux & Protocol Health ---

    /**
     * @dev The core periodic or event-driven rebalancing mechanism. It dynamically adjusts
     * fundamental entanglement parameters, potentially re-distributing risk/reward profiles
     * or recalibrating Q-Bond values based on long-term collective performance and market conditions.
     * Callable by keepers after a set interval.
     * (Simplified logic for demonstration: adjusts parameters based on overall protocol health).
     */
    function _executeQuantumFlux() internal onlyKeeper whenNotPaused {
        if (block.timestamp < lastQuantumFluxTime + quantumFluxInterval) {
            revert CallFailed(); // Not yet time for Quantum Flux
        }

        // Example: Adjust parameters based on Nexus health and Entanglement Index
        if (nexusBalance > (totalActivePrincipal / 10)) { // Nexus is very healthy (10% of total principal)
            entanglementWeight = 110e16; // Increase entanglement influence slightly (1.1x)
            baseYieldRate = 12e15; // Increase base yield rate (1.2%)
        } else if (nexusBalance < (totalActivePrincipal / 50) && totalActivePrincipal > 0) { // Nexus is struggling
            entanglementWeight = 90e16; // Decrease entanglement influence
            baseYieldRate = 8e15; // Decrease base yield rate (0.8%)
        }

        // This would also be the place to re-evaluate individual Q-Bond principals based on long-term collective performance.
        // E.g., if the protocol has been exceptionally profitable, a small portion of "excess" could be added to principals.
        // For brevity, individual bond re-valuation is omitted but conceptually fits here.

        lastQuantumFluxTime = uint64(block.timestamp);
        emit QuantumFluxExecuted(entanglementIndex, totalActivePrincipal);
    }

    /**
     * @dev Returns the current parameters governing the Quantum Flux mechanism.
     * In this example, it simply returns core protocol parameters which are influenced by Quantum Flux.
     */
    function getQuantumFluxParameters() public view returns (uint256 _entanglementWeight, uint256 _volatilityImpactFactor, uint256 _nexusContributionRate, uint256 _baseYieldRate) {
        return (entanglementWeight, volatilityImpactFactor, nexusContributionRate, baseYieldRate);
    }

    /**
     * @dev Returns the current multiplier dictating the required collateral for minting new Q-Bonds,
     * which adjusts based on overall protocol health and market volatility.
     * (Simplified logic for demonstration: always require at least 1 unit, adjust based on volatility).
     */
    function getAdaptiveCollateralFactor() public view returns (uint256) {
        uint256 baseCollateral = 1e18; // 1 unit of base asset
        // If volatility is high, require more collateral (e.g., 1.5x)
        if (latestMarketVolatility > 5e17) { // If >50% volatility
            return baseCollateral * 150 / 100; // 1.5x
        }
        return baseCollateral;
    }

    // --- V. Oracle & External Data Integration ---

    /**
     * @dev Initiates an external call (e.g., Chainlink Functions) to fetch real-time
     * market volatility data for a specified asset, crucial for dynamic yield calculations.
     * Callable by keeper.
     * @param _asset The address of the asset for which to fetch volatility.
     */
    function requestMarketVolatility(address _asset) public onlyKeeper whenNotPaused returns (bytes32 requestId) {
        // This is a placeholder for Chainlink Functions or similar oracle integration.
        // In a real implementation, you would construct Chainlink Functions request arguments here.
        // For simplicity, we are not making a real external call, just simulating a request ID.
        bytes32 mockRequestId = keccak256(abi.encodePacked(block.timestamp, _asset));
        emit MarketVolatilityRequested(mockRequestId, _asset);
        return mockRequestId;
    }

    /**
     * @dev A callback function designed to receive and process the market volatility data
     * returned by the oracle (e.g., Chainlink). This function would be called by the Chainlink node.
     * @param _requestId The ID of the original request.
     * @param _volatility The received volatility data (scaled by 1e18 for percentage).
     */
    function fulfillMarketVolatility(bytes32 _requestId, uint256 _volatility) external {
        // Ensure this is called by the trusted oracle address
        if (msg.sender != oracleAddress) {
            revert CallFailed();
        }

        latestMarketVolatility = _volatility;
        emit MarketVolatilityFulfilled(_requestId, _volatility);
    }

    /**
     * @dev Allows the protocol owner to update the address of the external oracle service.
     * @param _newOracle The new address of the oracle.
     */
    function setOracleAddress(address _newOracle) public onlyOwner {
        if (_newOracle == address(0)) {
            revert InvalidAddress();
        }
        oracleAddress = _newOracle;
        emit OracleAddressUpdated(_newOracle);
    }

    // --- VI. Governance/Parameter Adjustment (Controlled) ---
    // Note: This is a simplified governance mechanism for demonstration (owner-controlled proposals/votes).
    // A full DAO would involve token-weighted voting, multiple proposals, etc.

    /**
     * @dev Allows the owner to propose a change to a key protocol parameter.
     * Only one proposal can be active at a time for a given parameter name.
     * @param _paramName The keccak256 hash of the parameter name (e.g., keccak256("entanglementWeight")).
     * @param _newValue The new value for the parameter.
     */
    function proposeParameterChange(bytes32 _paramName, uint256 _newValue) public onlyOwner whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_paramName];
        if (proposal.creationTime != 0 && !proposal.executed && block.timestamp < proposal.votingEndTime) {
            revert VotingPeriodActive(); // A proposal for this param is already active
        }

        proposal.paramName = _paramName;
        proposal.newValue = _newValue;
        proposal.creationTime = uint64(block.timestamp);
        proposal.votingEndTime = uint64(block.timestamp) + proposalVotingPeriod;
        proposal.approved = false; // Owner must vote "true" later
        proposal.executed = false;

        emit ParameterProposalCreated(_paramName, _paramName, _newValue, proposal.votingEndTime);
    }

    /**
     * @dev Enables the owner to cast a vote (approve/reject) on an active parameter change proposal.
     * (Simplified single-voter system for this example).
     * @param _paramHash The keccak256 hash of the parameter name for the proposal.
     * @param _approve Boolean, true to approve, false to reject.
     */
    function voteOnParameterChange(bytes32 _paramHash, bool _approve) public onlyOwner whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_paramHash];
        if (proposal.creationTime == 0 || proposal.executed || block.timestamp >= proposal.votingEndTime) {
            revert ProposalNotFound();
        }

        proposal.approved = _approve; // Owner's vote directly sets approval status
        emit ParameterVoteCast(_paramHash, _approve);
    }

    /**
     * @dev Executes a proposed parameter change once it has received sufficient approval votes
     * and its voting period has ended.
     * @param _paramHash The keccak256 hash of the parameter name for the proposal.
     */
    function executeParameterChange(bytes32 _paramHash) public onlyOwner whenNotPaused {
        ParameterProposal storage proposal = parameterProposals[_paramHash];
        if (proposal.creationTime == 0 || proposal.executed || block.timestamp < proposal.votingEndTime) {
            revert ProposalNotFound(); // Or VotingPeriodActive()
        }
        if (!proposal.approved) {
            revert ProposalNotApproved();
        }

        // Apply the change based on paramName
        if (proposal.paramName == keccak256("entanglementWeight")) {
            entanglementWeight = proposal.newValue;
        } else if (proposal.paramName == keccak256("volatilityImpactFactor")) {
            volatilityImpactFactor = proposal.newValue;
        } else if (proposal.paramName == keccak256("nexusContributionRate")) {
            nexusContributionRate = proposal.newValue;
        } else if (proposal.paramName == keccak256("earlyDisentanglementPenaltyFactor")) {
            earlyDisentanglementPenaltyFactor = proposal.newValue;
        } else if (proposal.paramName == keccak256("baseYieldRate")) {
            baseYieldRate = proposal.newValue;
        } else if (proposal.paramName == keccak256("quantumFluxInterval")) {
            quantumFluxInterval = uint64(proposal.newValue);
        } else if (proposal.paramName == keccak256("proposalVotingPeriod")) {
            proposalVotingPeriod = uint64(proposal.newValue);
        } else {
            revert InvalidParameterName();
        }

        proposal.executed = true;
        emit ParameterChangeExecuted(_paramHash, proposal.paramName, proposal.newValue);
    }

    /**
     * @dev Sets the address of the designated keeper role, which is responsible for triggering
     * automated protocol functions like `updateEntanglementIndex` or `_executeQuantumFlux`.
     * @param _newKeeper The new address of the keeper.
     */
    function setKeeperAddress(address _newKeeper) public onlyOwner {
        if (_newKeeper == address(0)) {
            revert InvalidAddress();
        }
        keeperAddress = _newKeeper;
        emit KeeperAddressUpdated(_newKeeper);
    }

    // --- VII. Utility & Access Control ---

    /**
     * @dev Activates a circuit breaker, pausing critical functions of the protocol in case of emergencies.
     * Only callable by the contract owner.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Deactivates the circuit breaker, resuming normal protocol operations.
     * Only callable by the contract owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Allows the owner to recover tokens accidentally sent to the contract or trapped funds in emergencies.
     * @param _tokenAddress The address of the ERC20 token to withdraw.
     * @param _amount The amount of tokens to withdraw.
     */
    function withdrawEmergencyFunds(address _tokenAddress, uint256 _amount) public onlyOwner {
        if (_tokenAddress == address(0) || _amount == 0) {
            revert InvalidAmount();
        }
        IERC20 token = IERC20(_tokenAddress);
        if (token.balanceOf(address(this)) < _amount) {
            revert NotEnoughBalance();
        }
        token.safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Returns the total number of Q-Bonds that are currently active (not redeemed or early disentangled).
     * Note: This is a simplified getter. A more accurate count might require iterating through active bonds
     * or maintaining a dedicated counter that decrements on redemption/disentanglement.
     */
    function getTotalActiveQBonds() public view returns (uint256) {
        // This is a simplification; a true count would iterate or use a state variable.
        // `_qBondIds.current()` gives the total ever minted, not necessarily active.
        // For accurate active count, a mapping (tokenId => bool isActive) would be better.
        // For now, `totalActivePrincipal > 0` gives an indication of active bonds.
        return totalActivePrincipal > 0 ? _qBondIds.current() : 0; // Return current highest ID if any active principal
    }
}
```