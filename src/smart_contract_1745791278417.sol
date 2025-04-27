Okay, let's design a smart contract protocol centered around dynamic, state-dependent non-fungible tokens (NFTs) that influence DeFi interactions.

We'll call it the **Quantum Leap Protocol**. It manages "Quantum State Assets" (QSAs), which are NFTs with a dynamic `resonanceLevel`. This resonance level decays over time (Temporal Decay) but can be boosted through user interaction (`resonate`). The `resonanceLevel` of a QSA affects its utility in the protocol, specifically influencing potential yield from "Temporal Alignment" (staking) and the borrowing capacity in "Collateral Resonance" (lending). A global "Flux Factor" adds an external layer of volatility affecting all interactions.

This concept is unique because:
1.  **Dynamic NFT State:** NFTs typically have static properties. QSAs have a core, time-sensitive, user-modifiable state (`resonanceLevel`) on-chain.
2.  **State-Dependent DeFi:** Yield and borrowing power are directly tied to this dynamic NFT state, not just its existence or fixed attributes.
3.  **Interactive Decay/Boost:** Users must interact (`resonate`) to maintain or increase the utility of their QSA, creating active engagement.
4.  **Global Modifier:** The `FluxFactor` adds a layer of systemic risk/opportunity managed by governance or an oracle (simulated here).

**Outline:**

1.  **Contract Definition:** `QuantumLeapProtocol` inheriting necessary interfaces (`ERC721`, `ERC20` for a wrapped token, `Ownable`).
2.  **State Variables:** Mappings and variables to track QSA ownership, resonance levels, last resonance update time, alignment stakes, borrowing positions, protocol parameters, and a custom wrapped token (`QuantumCredit` - QCR).
3.  **Events:** To log key actions like minting, burning, resonance updates, alignment, borrowing, repayment, liquidation, parameter changes.
4.  **Modifiers:** For access control (`onlyOwner`, `onlyGovernance`).
5.  **Internal Helper Functions:** For calculations (resonance decay, yield, borrow limit) and state updates.
6.  **Core QSA Logic:** Minting, burning, transfer (standard ERC721), and the unique `updateResonance` function.
7.  **Temporal Alignment Logic:** Staking QSAs for yield, claiming yield, unstaking.
8.  **Collateral Resonance Logic:** Depositing QSAs as collateral, borrowing QCR, repaying QCR, withdrawing collateral.
9.  **Liquidation Logic:** Allowing anyone to liquidate underwater borrowing positions.
10. **Governance/Parameter Functions:** Functions to adjust protocol parameters (decay rate, flux factor, ratios, yield rates).
11. **Query Functions:** Read functions to check states, balances, limits, parameters.
12. **Internal QCR Token Logic:** Basic ERC20-like functions (`_mintQCR`, `_burnQCR`, `balanceOfQCR`, `transferQCR` etc.) for the protocol's native credit token, only minted/burned via protocol actions.

**Function Summary (Total: 29 Functions):**

*   **QSA Management (ERC721 + Custom State)**
    1.  `mintQSA(address to, uint256 initialResonance)`: Mint a new QSA to an address with an initial resonance level (protocol only).
    2.  `burnQSA(uint256 tokenId)`: Burn a QSA (protocol/owner conditions).
    3.  `transferFrom(address from, address to, uint256 tokenId)`: Standard ERC721 transfer.
    4.  `approve(address to, uint256 tokenId)`: Standard ERC721 approve.
    5.  `setApprovalForAll(address operator, bool approved)`: Standard ERC721 set approval for all.
    6.  `getApproved(uint256 tokenId)`: Standard ERC721 query approved.
    7.  `isApprovedForAll(address owner, address operator)`: Standard ERC721 query approval for all.
    8.  `updateResonance(uint256 tokenId)`: Public function to update a QSA's resonance based on time decay and potentially user interaction (callable by anyone).
    9.  `resonate(uint256 tokenId, uint256 boostAmount)`: User function to boost a QSA's resonance level.
    10. `getQSAResonance(uint256 tokenId)`: Get the current *calculated* resonance level of a QSA.
    11. `getQSAOwner(uint256 tokenId)`: Standard ERC721 query owner.
    12. `balanceOf(address owner)`: Standard ERC721 query balance.
    13. `totalSupply()`: Query total QSAs minted.

*   **Temporal Alignment (Yield)**
    14. `alignQSA(uint256 tokenId)`: Stake a QSA to earn yield.
    15. `unalignQSA(uint256 tokenId)`: Unstake a QSA.
    16. `claimAlignmentYield()`: Claim accumulated QCR yield from all aligned QSAs owned by the caller.
    17. `getPendingYield(address user)`: Query pending yield for a user.
    18. `isAligned(uint256 tokenId)`: Check if a QSA is currently aligned.

*   **Collateral Resonance (Borrowing)**
    19. `depositQSAForCollateral(uint256 tokenId)`: Lock a QSA to use as collateral for borrowing.
    20. `withdrawQSAFromCollateral(uint256 tokenId)`: Unlock a QSA from collateral (if no debt associated).
    21. `borrowQCR(uint256 tokenId, uint256 amount)`: Borrow QCR against a deposited QSA.
    22. `repayQCR(uint256 amount)`: Repay QCR debt.
    23. `getAvailableBorrowLimit(uint256 tokenId)`: Calculate borrow limit for a specific collateralized QSA.
    24. `getUserTotalDebt(address user)`: Query total QCR debt for a user across all their collateral.

*   **Liquidation**
    25. `liquidatePosition(address user, uint256 tokenId)`: Liquidate an underwater borrowing position.

*   **Governance/Parameters**
    26. `setTemporalDecayRate(uint256 rate)`: Set the decay rate for QSA resonance (Governance/Owner only).
    27. `setFluxFactor(uint256 factor)`: Set the global flux factor (Governance/Owner only, potentially via Oracle).
    28. `setLiquidationThreshold(uint256 threshold)`: Set the debt-to-borrow-limit ratio for liquidation (Governance/Owner only).
    29. `setYieldRate(uint256 rate)`: Set the QCR yield rate for aligned QSAs (Governance/Owner only).
    *(Note: A full governance system would be more complex, this provides parameter control functions)*

*   **Query/Utility (Internal QCR state - simplifying QCR as internal to protocol for demo)**
    *   `balanceOfQCR(address user)`: Check user's QCR balance *within the protocol*. (Internal helper function)
    *   `getTotalMintedQCR()`: Check total QCR minted by the protocol. (Internal helper function)

*(Self-correction: Instead of separate QCR functions `transferQCR`, `approveQCR` etc., we'll make QCR an internal balance within this contract to simplify and keep focus on the QSA dynamics. Users interact with QCR only *via* protocol functions like `borrowQCR` and `repayQCR` which adjust these internal balances. If QCR needed to be a separate, transferable ERC20, that would require a separate contract or more complex internal logic replicating ERC20 standards.)*

Okay, let's proceed with the code, incorporating the simplified QCR internal balance model. This keeps the function count focused on the core protocol mechanics while still exceeding 20 functions.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Just for interface structure idea, QCR is internal

/// @title QuantumLeapProtocol
/// @dev A protocol for managing dynamic Non-Fungible Tokens (Quantum State Assets - QSAs)
/// whose state (resonanceLevel) decays over time but can be boosted, and impacts
/// DeFi interactions (Temporal Alignment for yield, Collateral Resonance for borrowing).
/// Features a global Flux Factor influencing all interactions.
///
/// **Outline:**
/// 1.  Contract Definition & Imports
/// 2.  State Variables (QSAs, Resonance, Alignment, Borrowing, Parameters, Internal QCR)
/// 3.  Events
/// 4.  Modifiers
/// 5.  Internal Helper Functions
/// 6.  Core QSA Logic (Minting, Burning, ERC721, Resonance)
/// 7.  Temporal Alignment Logic (Staking & Yield)
/// 8.  Collateral Resonance Logic (Depositing, Borrowing, Repaying)
/// 9.  Liquidation Logic
/// 10. Governance/Parameter Control
/// 11. Query Functions
/// 12. Internal QCR Management (Simplified)

/// @notice Function Summary (Total: 29 Functions)
///
/// **QSA Management (ERC721 Standard + Custom State)**
/// 1.  `mintQSA(address to, uint256 initialResonance)`: Mint a new QSA.
/// 2.  `burnQSA(uint256 tokenId)`: Burn a QSA.
/// 3.  `transferFrom(address from, address to, uint256 tokenId)`: ERC721 Transfer.
/// 4.  `approve(address to, uint256 tokenId)`: ERC721 Approve.
/// 5.  `setApprovalForAll(address operator, bool approved)`: ERC721 Set Approval For All.
/// 6.  `getApproved(uint256 tokenId)`: ERC721 Get Approved.
/// 7.  `isApprovedForAll(address owner, address operator)`: ERC721 Is Approved For All.
/// 8.  `updateResonance(uint256 tokenId)`: Update QSA resonance based on decay/time.
/// 9.  `resonate(uint256 tokenId, uint256 boostAmount)`: Boost QSA resonance.
/// 10. `getQSAResonance(uint256 tokenId)`: Get current calculated resonance.
/// 11. `getQSAOwner(uint256 tokenId)`: ERC721 Get Owner.
/// 12. `balanceOf(address owner)`: ERC721 Balance Of.
/// 13. `totalSupply()`: Total QSAs minted.
///
/// **Temporal Alignment (Yield)**
/// 14. `alignQSA(uint256 tokenId)`: Stake QSA for yield.
/// 15. `unalignQSA(uint256 tokenId)`: Unstake QSA.
/// 16. `claimAlignmentYield()`: Claim accumulated QCR yield.
/// 17. `getPendingYield(address user)`: Query pending yield.
/// 18. `isAligned(uint256 tokenId)`: Check if QSA is aligned.
///
/// **Collateral Resonance (Borrowing)**
/// 19. `depositQSAForCollateral(uint256 tokenId)`: Use QSA as collateral.
/// 20. `withdrawQSAFromCollateral(uint256 tokenId)`: Withdraw collateral.
/// 21. `borrowQCR(uint256 tokenId, uint256 amount)`: Borrow QCR.
/// 22. `repayQCR(uint256 amount)`: Repay QCR.
/// 23. `getAvailableBorrowLimit(uint256 tokenId)`: Calculate borrow limit for QSA.
/// 24. `getUserTotalDebt(address user)`: Query user's total debt.
///
/// **Liquidation**
/// 25. `liquidatePosition(address user, uint256 tokenId)`: Liquidate undercollateralized position.
///
/// **Governance/Parameters**
/// 26. `setTemporalDecayRate(uint256 rate)`: Set resonance decay rate.
/// 27. `setFluxFactor(uint256 factor)`: Set global flux factor.
/// 28. `setLiquidationThreshold(uint256 threshold)`: Set liquidation ratio threshold.
/// 29. `setYieldRate(uint256 rate)`: Set alignment yield rate.
///
/// **Query/Utility (Internal QCR)**
/// *Internal functions used by others, not direct external calls for QCR transfer:*
/// `_mintQCR(address user, uint256 amount)`: Mint internal QCR balance.
/// `_burnQCR(address user, uint256 amount)`: Burn internal QCR balance.
/// `balanceOfQCR(address user)`: Get internal QCR balance.
/// `getTotalMintedQCR()`: Get total internal QCR supply.


contract QuantumLeapProtocol is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Math for uint256;

    // --- State Variables ---

    // QSA State
    Counters.Counter private _qsaTokenIds;
    struct QSAState {
        uint256 resonanceLevel;
        uint256 lastResonanceUpdate; // Timestamp
        bool isAligned;              // Staked for yield
        bool isCollateral;           // Used as collateral
    }
    mapping(uint256 => QSAState) private _qsaStates;
    mapping(address => uint256[]) private _alignedQSAs; // QSAs staked by user
    mapping(address => uint256[]) private _collateralQSAs; // QSAs used as collateral by user

    // Temporal Alignment (Yield)
    mapping(address => uint256) private _pendingYield; // Accumulated QCR yield per user
    mapping(uint256 => uint256) private _lastYieldClaimTime; // Last time yield was calculated for an aligned QSA

    // Collateral Resonance (Borrowing)
    mapping(address => uint256) private _userDebt; // QCR debt per user
    mapping(uint256 => uint256) private _qsaDebtShare; // Debt associated with a specific collateralized QSA (simplification)

    // Protocol Parameters (Governance controlled)
    uint256 public temporalDecayRate = 100; // Resonance points per hour (example: 100)
    uint256 public fluxFactor = 1e18; // Global multiplier (fixed point, 1e18 = 1x)
    uint256 public liquidationThreshold = 1200; // Debt/BorrowLimit ratio * 10000 (example: 120% = 12000)
    uint256 public qcrMintRatio = 5000; // QCR minted per QSA value * 10000 (example: 50% = 5000)
    uint256 public yieldRate = 10; // QCR yield per resonance per hour * 1000 (example: 0.01 QCR/res/hr = 10)

    // Internal QuantumCredit (QCR) Token State (Simplified - not a separate ERC20 contract)
    mapping(address => uint256) private _qcrBalances; // Internal QCR balance
    uint256 private _totalMintedQCR;

    // --- Events ---

    event QSAMinted(address indexed owner, uint256 indexed tokenId, uint256 initialResonance);
    event QSABurned(uint256 indexed tokenId);
    event ResonanceUpdated(uint256 indexed tokenId, uint256 oldResonance, uint256 newResonance, uint256 decayAmount);
    event ResonanceBoosted(uint256 indexed tokenId, uint256 boostAmount, uint256 newResonance);
    event QSAAligned(uint256 indexed tokenId, address indexed user);
    event QSAUnaligned(uint256 indexed tokenId, address indexed user);
    event YieldClaimed(address indexed user, uint256 amount);
    event QSACollateralized(uint256 indexed tokenId, address indexed user);
    event QSAUncollateralized(uint256 indexed tokenId, address indexed user);
    event QCRBorrowed(address indexed user, uint256 indexed tokenId, uint256 amount);
    event QCRRepaid(address indexed user, uint256 amount);
    event PositionLiquidated(address indexed user, uint256 indexed tokenId, address indexed liquidator, uint256 debtCovered);
    event ParameterUpdated(string paramName, uint256 newValue);

    // --- Constructor ---

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    // --- Modifiers (Example, could be extended with governance roles) ---
    // Functionality shown uses onlyOwner for simplicity, real governance would be separate

    // --- Internal Helper Functions ---

    /// @dev Calculates resonance decay based on time passed.
    /// @param lastUpdate Timestamp of the last update.
    /// @param currentResonance The current resonance level.
    /// @return The amount of resonance decay.
    function _calculateDecay(uint256 lastUpdate, uint256 currentResonance) internal view returns (uint256) {
        uint256 timeElapsed = block.timestamp - lastUpdate;
        // Decay is per hour, so divide by 1 hour (3600 seconds)
        uint256 potentialDecay = (timeElapsed * temporalDecayRate) / 3600;
        return Math.min(potentialDecay, currentResonance); // Resonance cannot go below zero
    }

    /// @dev Internal function to update a QSA's resonance state.
    /// @param tokenId The ID of the QSA.
    /// @return The new resonance level after decay.
    function _updateResonanceInternal(uint256 tokenId) internal returns (uint256) {
        QSAState storage qsa = _qsaStates[tokenId];
        if (block.timestamp > qsa.lastResonanceUpdate) {
            uint256 decayAmount = _calculateDecay(qsa.lastResonanceUpdate, qsa.resonanceLevel);
            qsa.resonanceLevel -= decayAmount;
            qsa.lastResonanceUpdate = block.timestamp;
            emit ResonanceUpdated(tokenId, qsa.resonanceLevel + decayAmount, qsa.resonanceLevel, decayAmount);

            // If aligned, update last yield claim time to capture yield up to decay time
            if (qsa.isAligned) {
                _lastYieldClaimTime[tokenId] = block.timestamp;
            }
        }
        return qsa.resonanceLevel;
    }

    /// @dev Calculates the effective 'value' of a QSA based on its resonance and global flux.
    /// This is a simplified model.
    /// @param resonance The current resonance level.
    /// @return The calculated effective value (fixed point).
    function _calculateQSAEffectiveValue(uint256 resonance) internal view returns (uint256) {
        // Simple model: Value is proportional to resonance * flux factor
        // Assume resonance is in natural units, fluxFactor is fixed point 1e18
        return (resonance * fluxFactor) / 1e18;
    }

    /// @dev Calculates the borrow limit for a QSA based on its resonance and parameters.
    /// @param tokenId The ID of the QSA.
    /// @return The calculated borrow limit in QCR.
    function _calculateBorrowLimit(uint256 tokenId) internal view returns (uint256) {
        // Ensure resonance is up-to-date for calculation purity in `view` function
        // In actual borrow, resonance should be updated first.
        // For a view function, we calculate hypothetically based on *current* state + decay
        QSAState storage qsa = _qsaStates[tokenId];
        uint256 currentResonance = qsa.resonanceLevel;
        uint256 hypotheticalDecay = _calculateDecay(qsa.lastResonanceUpdate, currentResonance);
        uint256 effectiveResonance = currentResonance - hypotheticalDecay; // Calculate based on hypothetical decay

        if (effectiveResonance == 0) {
            return 0;
        }

        uint256 effectiveValue = _calculateQSAEffectiveValue(effectiveResonance);

        // Borrow limit = Effective Value * QCR Mint Ratio
        // qcrMintRatio is fixed point * 10000
        return (effectiveValue * qcrMintRatio) / 10000;
    }

    /// @dev Calculates the yield accumulated for an aligned QSA since the last claim/update.
    /// @param tokenId The ID of the QSA.
    /// @return The calculated yield in QCR.
    function _calculateQSAYield(uint256 tokenId) internal view returns (uint256) {
        QSAState storage qsa = _qsaStates[tokenId];
        if (!qsa.isAligned || qsa.lastResonanceUpdate == 0) {
            return 0;
        }

        // Note: This calculates yield based on the resonance *at the time of last update*.
        // For more accuracy, resonance should be updated first.
        // A more complex system might average resonance over time or use snapshots.
        // Here, we use the resonance at the last update timestamp.
        uint256 resonanceAtLastUpdate = qsa.resonanceLevel; // This is resonance AFTER the decay calculated in _updateResonanceInternal
        uint256 timeAligned = block.timestamp - _lastYieldClaimTime[tokenId];

        // Yield = Resonance * Yield Rate * Time Aligned
        // yieldRate is fixed point * 1000
        uint256 yield = (resonanceAtLastUpdate * yieldRate) / 1000;
        yield = (yield * timeAligned) / 3600; // Convert yield per hour to yield for timeAligned seconds

        return yield;
    }

    /// @dev Adds QCR balance internally.
    function _mintQCR(address user, uint256 amount) internal {
        _qcrBalances[user] += amount;
        _totalMintedQCR += amount;
        // No event for internal mint/burn
    }

    /// @dev Subtracts QCR balance internally.
    function _burnQCR(address user, uint256 amount) internal {
        require(_qcrBalances[user] >= amount, "Insufficient QCR balance");
        _qcrBalances[user] -= amount;
        _totalMintedQCR -= amount;
    }

    // --- Core QSA Logic ---

    /// @notice Mints a new Quantum State Asset (QSA). Restricted to owner/protocol.
    /// @param to The address to mint the QSA to.
    /// @param initialResonance The starting resonance level for the QSA.
    function mintQSA(address to, uint256 initialResonance) external onlyOwner {
        _qsaTokenIds.increment();
        uint256 newTokenId = _qsaTokenIds.current();

        _safeMint(to, newTokenId);

        QSAState storage newState = _qsaStates[newTokenId];
        newState.resonanceLevel = initialResonance;
        newState.lastResonanceUpdate = block.timestamp;
        newState.isAligned = false;
        newState.isCollateral = false;

        emit QSAMinted(to, newTokenId, initialResonance);
    }

    /// @notice Burns a QSA. Can only be burned if not aligned or used as collateral.
    /// @param tokenId The ID of the QSA to burn.
    function burnQSA(uint256 tokenId) external {
        require(_exists(tokenId), "QSA does not exist");
        require(ownerOf(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "Not QSA owner or approved");
        require(!_qsaStates[tokenId].isAligned, "QSA is aligned");
        require(!_qsaStates[tokenId].isCollateral, "QSA is collateralized");

        _burn(tokenId);
        delete _qsaStates[tokenId];

        emit QSABurned(tokenId);
    }

    // ERC721 standard functions are inherited and functional:
    // transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll, ownerOf, balanceOf

    /// @notice Updates the resonance level of a QSA based on time decay. Callable by anyone.
    /// @dev This function MUST be called before relying on the resonance level for yield or borrowing calculations.
    /// It also updates the yield calculation point for aligned QSAs.
    /// @param tokenId The ID of the QSA to update.
    function updateResonance(uint256 tokenId) external {
        require(_exists(tokenId), "QSA does not exist");
        _updateResonanceInternal(tokenId);
    }

    /// @notice Allows the QSA owner to boost the resonance level.
    /// @param tokenId The ID of the QSA.
    /// @param boostAmount The amount to increase resonance by.
    function resonate(uint256 tokenId, uint256 boostAmount) external {
        require(_exists(tokenId), "QSA does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not QSA owner");
        require(boostAmount > 0, "Boost amount must be positive");

        // Update decay before boosting
        _updateResonanceInternal(tokenId);

        QSAState storage qsa = _qsaStates[tokenId];
        uint256 oldResonance = qsa.resonanceLevel;
        qsa.resonanceLevel += boostAmount;

        // If aligned, update last yield claim time to capture yield up to boost time
        if (qsa.isAligned) {
            _lastYieldClaimTime[tokenId] = block.timestamp;
        }

        emit ResonanceBoosted(tokenId, boostAmount, qsa.resonanceLevel);
    }

    /// @notice Gets the current calculated resonance level of a QSA, including potential decay since last update.
    /// @param tokenId The ID of the QSA.
    /// @return The current effective resonance level.
    function getQSAResonance(uint256 tokenId) public view returns (uint256) {
         require(_exists(tokenId), "QSA does not exist");
        QSAState storage qsa = _qsaStates[tokenId];
        uint256 hypotheticalDecay = _calculateDecay(qsa.lastResonanceUpdate, qsa.resonanceLevel);
        return qsa.resonanceLevel - hypotheticalDecay; // Calculate based on hypothetical decay
    }

    // ERC721 Query functions: getQSAOwner (ownerOf), balanceOf, totalSupply inherited

    // --- Temporal Alignment (Yield) ---

    /// @notice Stakes a QSA to earn Temporal Alignment yield in QCR.
    /// @dev QSA must be owned by the caller and not already aligned or collateralized.
    /// Automatically updates resonance and claims any pending yield for this QSA before aligning.
    /// @param tokenId The ID of the QSA to align.
    function alignQSA(uint256 tokenId) external {
        require(_exists(tokenId), "QSA does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not QSA owner");
        require(!_qsaStates[tokenId].isAligned, "QSA already aligned");
        require(!_qsaStates[tokenId].isCollateral, "QSA is collateralized");

        // Update resonance and calculate/add pending yield before aligning
        _updateResonanceInternal(tokenId);
        _pendingYield[msg.sender] += _calculateQSAYield(tokenId);

        _qsaStates[tokenId].isAligned = true;
        _alignedQSAs[msg.sender].push(tokenId);
        _lastYieldClaimTime[tokenId] = block.timestamp; // Start yield calculation from now

        emit QSAAligned(tokenId, msg.sender);
    }

    /// @notice Unstakes a QSA from Temporal Alignment.
    /// @dev QSA must be aligned by the caller. Automatically calculates and adds pending yield.
    /// @param tokenId The ID of the QSA to unalign.
    function unalignQSA(uint256 tokenId) external {
        require(_exists(tokenId), "QSA does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not QSA owner");
        require(_qsaStates[tokenId].isAligned, "QSA not aligned");

        // Update resonance and calculate/add pending yield before unaligning
        _updateResonanceInternal(tokenId);
        _pendingYield[msg.sender] += _calculateQSAYield(tokenId);

        _qsaStates[tokenId].isAligned = false;
        // Remove from _alignedQSAs array (simple but gas inefficient for large arrays)
        uint256 index = _getQSAIndex(_alignedQSAs[msg.sender], tokenId);
        require(index != type(uint256).max, "QSA not found in aligned list"); // Should not happen if isAligned is true
        _removeQSAFromArray(_alignedQSAs[msg.sender], index);

        emit QSAUnaligned(tokenId, msg.sender);
    }

    /// @notice Claims accumulated QCR yield for all of the caller's aligned QSAs.
    /// @dev Automatically updates resonance and calculates yield for all aligned QSAs before claiming.
    function claimAlignmentYield() external {
        uint256 totalYieldToClaim = 0;

        // Calculate yield for each aligned QSA and add to pending
        uint256[] storage userAligned = _alignedQSAs[msg.sender];
        for (uint i = 0; i < userAligned.length; i++) {
            uint256 tokenId = userAligned[i];
             // Update resonance and add pending yield
            _updateResonanceInternal(tokenId);
            _pendingYield[msg.sender] += _calculateQSAYield(tokenId);
             // Reset yield calculation start time for the QSA
            _lastYieldClaimTime[tokenId] = block.timestamp;
        }

        totalYieldToClaim = _pendingYield[msg.sender];
        require(totalYieldToClaim > 0, "No yield to claim");

        _pendingYield[msg.sender] = 0;
        _mintQCR(msg.sender, totalYieldToClaim);

        emit YieldClaimed(msg.sender, totalYieldToClaim);
    }

    /// @notice Queries the currently pending QCR yield for a user across all their aligned QSAs.
    /// @dev This calculates yield *up to the current block time* based on their state after the *last* resonance update.
    /// Calling `claimAlignmentYield` or `unalignQSA` will update resonance and give a more accurate final amount.
    /// @param user The address to query.
    /// @return The total pending yield amount.
    function getPendingYield(address user) external view returns (uint256) {
        uint256 currentPending = _pendingYield[user];
        uint256[] storage userAligned = _alignedQSAs[user];

        // Add hypothetical yield since last claim/update for *each* aligned QSA
        for (uint i = 0; i < userAligned.length; i++) {
            uint256 tokenId = userAligned[i];
            // Calculate yield since the last yield start time for this QSA
            uint256 timeAligned = block.timestamp - _lastYieldClaimTime[tokenId];

             // Use resonance level *at the time of last update* for this hypothetical calculation
             // More complex averaging could be used for higher precision
            uint256 resonanceAtLastUpdate = _qsaStates[tokenId].resonanceLevel;
            uint256 yield = (resonanceAtLastUpdate * yieldRate) / 1000;
            yield = (yield * timeAligned) / 3600;

            currentPending += yield;
        }
        return currentPending;
    }

    /// @notice Checks if a QSA is currently staked for Temporal Alignment.
    /// @param tokenId The ID of the QSA.
    /// @return True if aligned, false otherwise.
    function isAligned(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "QSA does not exist");
        return _qsaStates[tokenId].isAligned;
    }

    // --- Collateral Resonance (Borrowing) ---

    /// @notice Designates a QSA as collateral for borrowing QCR.
    /// @dev QSA must be owned by caller, not aligned, and not already collateral.
    /// Transfers QSA ownership to the protocol contract while it's collateralized.
    /// @param tokenId The ID of the QSA to use as collateral.
    function depositQSAForCollateral(uint256 tokenId) external {
        require(_exists(tokenId), "QSA does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not QSA owner");
        require(!_qsaStates[tokenId].isAligned, "QSA is aligned");
        require(!_qsaStates[tokenId].isCollateral, "QSA already collateralized");

        _qsaStates[tokenId].isCollateral = true;
        _collateralQSAs[msg.sender].push(tokenId);

        // Transfer QSA to the protocol contract (or a vault contract)
        // Using _transfer to bypass ERC721 hooks potentially
        _transfer(msg.sender, address(this), tokenId);

        emit QSACollateralized(tokenId, msg.sender);
    }

    /// @notice Withdraws a QSA from collateral.
    /// @dev QSA must be collateralized by the caller and the user must have no outstanding debt.
    /// Transfers QSA back to the original owner.
    /// @param tokenId The ID of the QSA to withdraw.
    function withdrawQSAFromCollateral(uint256 tokenId) external {
        require(_exists(tokenId), "QSA does not exist");
        require(_qsaStates[tokenId].isCollateral, "QSA not collateralized");
        require(ownerOf(tokenId) == address(this), "QSA not held by protocol (collateral bug?)");
        require(msg.sender == _getOriginalCollateralOwner(tokenId), "Not original collateral owner");
        require(_userDebt[msg.sender] == 0, "User has outstanding debt");

        _qsaStates[tokenId].isCollateral = false;
        // Remove from _collateralQSAs array
        uint256 index = _getQSAIndex(_collateralQSAs[msg.sender], tokenId);
        require(index != type(uint256).max, "QSA not found in collateral list"); // Should not happen
        _removeQSAFromArray(_collateralQSAs[msg.sender], index);

        // Transfer QSA back
         // Need to store original owner on deposit, or rely on msg.sender here
         // Storing is safer. Let's add original owner state.
         // (Self-correction: Adding _originalCollateralOwner mapping)
        address originalOwner = _originalCollateralOwner[tokenId];
        delete _originalCollateralOwner[tokenId]; // Clean up
        _transfer(address(this), originalOwner, tokenId);

        emit QSAUncollateralized(tokenId, originalOwner);
    }

    mapping(uint256 => address) private _originalCollateralOwner; // Track original owner of collateralized QSA

     // Adjust deposit to store original owner
     function depositQSAForCollateral(uint256 tokenId) public { // Making public to allow _transfer
        require(_exists(tokenId), "QSA does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not QSA owner");
        require(!_qsaStates[tokenId].isAligned, "QSA is aligned");
        require(!_qsaStates[tokenId].isCollateral, "QSA already collateralized");

        _qsaStates[tokenId].isCollateral = true;
        _collateralQSAs[msg.sender].push(tokenId);
        _originalCollateralOwner[tokenId] = msg.sender; // Store original owner

        _transfer(msg.sender, address(this), tokenId);

        emit QSACollateralized(tokenId, msg.sender);
    }


    /// @notice Borrows QCR against a deposited and collateralized QSA.
    /// @dev Updates QSA resonance first. Amount must be within the borrow limit.
    /// @param tokenId The ID of the collateralized QSA to borrow against.
    /// @param amount The amount of QCR to borrow.
    function borrowQCR(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "QSA does not exist");
        require(ownerOf(tokenId) == address(this), "QSA not held by protocol (not collateral)");
        require(_qsaStates[tokenId].isCollateral, "QSA not marked as collateral");
        require(_getOriginalCollateralOwner(tokenId) == msg.sender, "Not original collateral owner");
        require(amount > 0, "Borrow amount must be positive");

        // Update resonance before checking borrow limit
        _updateResonanceInternal(tokenId);

        uint256 currentBorrowLimit = _calculateBorrowLimit(tokenId);
        uint256 userCurrentDebt = _userDebt[msg.sender];
        uint256 totalPotentialDebt = userCurrentDebt + amount;

        // Simple check: Total debt must be within the limit provided by *this* specific QSA
        // A more complex system would aggregate borrow limits across all collateral
        // Let's stick to simple: borrow limit check is per-QSA for now.
        // Max debt against THIS QSA cannot exceed its limit.
        // And total user debt cannot exceed limit provided by *all* their collateral.
        // This is complex. Let's simplify: Check against the *total* borrow capacity from *all* user's collateral.
        uint256 totalUserCollateralLimit = 0;
        uint256[] storage userCollateral = _collateralQSAs[msg.sender];
         for(uint i=0; i < userCollateral.length; i++) {
             // Update resonance for each collateralized QSA first
             _updateResonanceInternal(userCollateral[i]);
             totalUserCollateralLimit += _calculateBorrowLimit(userCollateral[i]);
         }

        require(totalPotentialDebt <= totalUserCollateralLimit, "Borrow amount exceeds user's total collateral limit");

        _userDebt[msg.sender] = totalPotentialDebt;
        // Simple debt tracking per QSA (optional, complex for repayment logic)
        // Let's not track debt per QSA for now, just per user.
        // _qsaDebtShare[tokenId] += amount; // Removed for simplification

        _mintQCR(msg.sender, amount);

        emit QCRBorrowed(msg.sender, tokenId, amount);
    }

    /// @notice Repays QCR debt.
    /// @dev Burns the QCR from the user's internal balance.
    /// @param amount The amount of QCR to repay.
    function repayQCR(uint256 amount) external {
        require(amount > 0, "Repay amount must be positive");
        require(_userDebt[msg.sender] > 0, "User has no debt");
        require(_qcrBalances[msg.sender] >= amount, "Insufficient QCR balance to repay");

        uint256 debtBefore = _userDebt[msg.sender];
        uint256 actualRepaid = Math.min(amount, debtBefore);

        _userDebt[msg.sender] -= actualRepaid;
        _burnQCR(msg.sender, actualRepaid);

        emit QCRRepaid(msg.sender, actualRepaid);
    }

    /// @notice Calculates the available QCR borrowing limit for a specific collateralized QSA.
    /// @dev This is the maximum QCR that *this specific QSA* can support as collateral.
    /// User's *total* borrow limit is the sum of limits from all their collateral QSAs.
    /// Automatically updates QSA resonance before calculating.
    /// @param tokenId The ID of the collateralized QSA.
    /// @return The available borrow limit in QCR for this QSA.
    function getAvailableBorrowLimit(uint256 tokenId) public returns (uint256) {
        require(_exists(tokenId), "QSA does not exist");
        require(_qsaStates[tokenId].isCollateral, "QSA not collateralized");

        // Update resonance first
        _updateResonanceInternal(tokenId);

        return _calculateBorrowLimit(tokenId);
    }

    /// @notice Queries the total QCR debt for a user.
    /// @param user The address to query.
    /// @return The total QCR debt amount.
    function getUserTotalDebt(address user) external view returns (uint256) {
        return _userDebt[user];
    }


    // --- Liquidation ---

    /// @notice Allows anyone to liquidate an undercollateralized position.
    /// @dev A position is undercollateralized if total user debt exceeds their total borrow limit (adjusted for liquidation threshold).
    /// Liquidator covers a portion of the debt using their QCR and receives collateral QSAs.
    /// This is a simplified liquidation model.
    /// @param user The address of the borrower to liquidate.
    /// @param tokenId A specific QSA owned by the user to potentially seize as part of liquidation.
    /// @dev This simplified liquidation seizes *one* specified QSA if the user is liquidatable.
    /// A real system would seize enough collateral to cover debt plus incentive.
    function liquidatePosition(address user, uint256 tokenId) external {
        require(_exists(tokenId), "QSA does not exist");
        require(_qsaStates[tokenId].isCollateral, "QSA not collateralized");
        require(_getOriginalCollateralOwner(tokenId) == user, "QSA not collateralized by user");

        uint256 userDebt = _userDebt[user];
        require(userDebt > 0, "User has no debt");

        uint256 totalUserCollateralLimit = 0;
        uint256[] storage userCollateral = _collateralQSAs[user];
        for(uint i=0; i < userCollateral.length; i++) {
            // Update resonance for each collateralized QSA before checking liquidation threshold
            _updateResonanceInternal(userCollateral[i]);
            totalUserCollateralLimit += _calculateBorrowLimit(userCollateral[i]);
        }

        // Check liquidation threshold: debt > limit * threshold / 10000
        require(userDebt * 10000 > totalUserCollateralLimit * liquidationThreshold, "Position is not undercollateralized");

        // --- Simplified Liquidation Execution ---
        // The liquidator covers the *entire* debt (simplified).
        // The liquidator gets the specified QSA (simplified, real system would take enough collateral).
        uint256 debtCovered = userDebt;
        _burnQCR(msg.sender, debtCovered); // Liquidator pays off the debt
        _userDebt[user] = 0; // Borrower's debt is cleared

        // Transfer the seized collateral QSA to the liquidator
        _qsaStates[tokenId].isCollateral = false;
        uint256 index = _getQSAIndex(_collateralQSAs[user], tokenId);
        require(index != type(uint256).max, "QSA not found in collateral list for user"); // Should not happen
        _removeQSAFromArray(_collateralQSAs[user], index);
        delete _originalCollateralOwner[tokenId]; // Clean up collateral owner tracking

        _transfer(address(this), msg.sender, tokenId); // Transfer seized QSA

        emit PositionLiquidated(user, tokenId, msg.sender, debtCovered);
    }

    /// @notice Checks if a user's position is currently liquidatable.
    /// @param user The address to check.
    /// @return True if the user's total debt exceeds their total collateral limit adjusted by the liquidation threshold.
    function isPositionLiquidatable(address user) external returns (bool) { // Not pure because of updateResonanceInternal
        uint256 userDebt = _userDebt[user];
        if (userDebt == 0) {
            return false;
        }

        uint256 totalUserCollateralLimit = 0;
        uint256[] storage userCollateral = _collateralQSAs[user];
         for(uint i=0; i < userCollateral.length; i++) {
             // Update resonance for each collateralized QSA first
             _updateResonanceInternal(userCollateral[i]);
             totalUserCollateralLimit += _calculateBorrowLimit(userCollateral[i]);
         }

        // Check liquidation threshold: debt > limit * threshold / 10000
        return userDebt * 10000 > totalUserCollateralLimit * liquidationThreshold;
    }

    // --- Governance/Parameter Control (Requires Owner/Governance) ---

    /// @notice Sets the rate at which QSA resonance decays per hour. Owner only.
    /// @param rate The new decay rate.
    function setTemporalDecayRate(uint256 rate) external onlyOwner {
        temporalDecayRate = rate;
        emit ParameterUpdated("temporalDecayRate", rate);
    }

    /// @notice Sets the global Flux Factor multiplier. Owner only (potentially via Oracle integration).
    /// @param factor The new flux factor (fixed point 1e18).
    function setFluxFactor(uint256 factor) external onlyOwner {
        fluxFactor = factor;
        emit ParameterUpdated("fluxFactor", factor);
    }

    /// @notice Sets the debt-to-borrow-limit ratio that triggers liquidation. Owner only.
    /// @param threshold The new threshold (percentage * 10000, e.g., 12000 for 120%).
    function setLiquidationThreshold(uint256 threshold) external onlyOwner {
        liquidationThreshold = threshold;
        emit ParameterUpdated("liquidationThreshold", threshold);
    }

    /// @notice Sets the ratio for how much QCR can be borrowed per unit of QSA effective value. Owner only.
    /// @param ratio The new ratio (percentage * 10000, e.g., 5000 for 50%).
    function setQCRMintRatio(uint256 ratio) external onlyOwner {
        qcrMintRatio = ratio;
        emit ParameterUpdated("qcrMintRatio", ratio);
    }

    /// @notice Sets the QCR yield rate for aligned QSAs per resonance point per hour. Owner only.
    /// @param rate The new rate (fixed point * 1000, e.g., 10 for 0.01 QCR/res/hr).
    function setYieldRate(uint256 rate) external onlyOwner {
        yieldRate = rate;
        emit ParameterUpdated("yieldRate", rate);
    }

    // --- Query Functions ---

    // getQSAResonance, getPendingYield, getAvailableBorrowLimit, getUserTotalDebt, isAligned, isPositionLiquidatable covered above.
    // ERC721 queries: ownerOf, balanceOf, totalSupply, getApproved, isApprovedForAll also covered.

    /// @notice Gets the current Temporal Decay Rate.
    function getTemporalDecayRate() external view returns (uint256) {
        return temporalDecayRate;
    }

    /// @notice Gets the current global Flux Factor.
    function getFluxFactor() external view returns (uint256) {
        return fluxFactor;
    }

    /// @notice Gets the current Liquidation Threshold.
    function getLiquidationThreshold() external view returns (uint256) {
        return liquidationThreshold;
    }

    /// @notice Gets the current QCR Mint Ratio.
    function getQCRMintRatio() external view returns (uint256) {
        return qcrMintRatio;
    }

     /// @notice Gets the current Yield Rate.
    function getYieldRate() external view returns (uint256) {
        return yieldRate;
    }

    /// @notice Gets the list of QSAs currently aligned by a user.
    /// @param user The address to query.
    /// @return An array of QSA token IDs.
    function getAlignedQSAs(address user) external view returns (uint256[] memory) {
        return _alignedQSAs[user];
    }

    /// @notice Gets the list of QSAs currently used as collateral by a user.
    /// @param user The address to query.
    /// @return An array of QSA token IDs.
    function getCollateralQSAs(address user) external view returns (uint256[] memory) {
        return _collateralQSAs[user];
    }


    // --- Internal QCR Management (Simplified ERC20-like within the contract) ---

    // _mintQCR, _burnQCR implemented as helpers above

    /// @notice Gets the internal QCR balance for a user within the protocol.
    /// @param user The address to query.
    /// @return The QCR balance.
    function balanceOfQCR(address user) external view returns (uint256) {
        return _qcrBalances[user];
    }

    /// @notice Gets the total supply of QCR minted within the protocol.
    function getTotalMintedQCR() external view returns (uint256) {
        return _totalMintedQCR;
    }


    // --- Internal Array Utility (Gas inefficient for large arrays, consider linked list or better structure for production) ---

    /// @dev Finds the index of a tokenId in an array.
    /// @return The index, or type(uint256).max if not found.
    function _getQSAIndex(uint256[] storage arr, uint256 tokenId) internal view returns (uint256) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == tokenId) {
                return i;
            }
        }
        return type(uint256).max;
    }

    /// @dev Removes an element from an array by index (maintains order).
    function _removeQSAFromArray(uint256[] storage arr, uint256 index) internal {
        require(index < arr.length, "Index out of bounds");
        for (uint i = index; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        arr.pop();
    }
}
```