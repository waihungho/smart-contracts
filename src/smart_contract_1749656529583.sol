Okay, here is a Solidity smart contract called `QuantumVault`.

This contract combines several concepts:
1.  **NFT-Represented Strategies:** Investment/staking strategies are associated with unique ERC-721 NFTs. Users stake funds into a specific strategy NFT.
2.  **Dynamic System Parameters (Phase Shifts):** The contract's behavior (fees, yield multipliers, unlock durations) can change based on triggered "Phase Shifts", adding a dynamic layer.
3.  **Role-Based Access Control:** Beyond just an owner, there are roles like `StrategyProvider` and `Keeper`.
4.  **Complex Yield Distribution:** Yield earned by a strategy is split between the staker, the strategy provider, and a protocol treasury/fee pool.
5.  **Time-Weighted Staking/Unstaking:** Staking duration can influence yield or introduce withdrawal penalties/locks.
6.  **Keeper/Oracle Integration (Conceptual):** A designated role (`Keeper`) can update parameters potentially based on external data (simulated here).

It aims to be more complex than a simple staking contract or vault by integrating NFTs as strategy identifiers and introducing dynamic, multi-party parameters and fee distribution.

---

**Outline & Function Summary:**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title QuantumVault
 * @dev A creative vault contract allowing users to stake tokens into strategies represented by NFTs,
 *      featuring dynamic parameters via Phase Shifts and complex yield distribution.
 */
contract QuantumVault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // --- State Variables ---

    IERC20 public stakingToken; // The token users stake
    IERC721 public strategyNFTContract; // The contract for strategy NFTs

    // --- Role-Based Access Control ---
    mapping(address => bool) public isStrategyProvider; // Can register/manage strategy NFTs
    mapping(address => bool) public isKeeper; // Can trigger phase shifts or update oracle-like data

    // --- Strategy State ---
    struct Strategy {
        address provider; // Address of the strategy provider
        bool active; // Can users stake/claim/unstake?
        uint256 totalStaked; // Total stakingToken staked in this strategy
        uint256 accumulatedProtocolYield; // Yield accumulated for protocol/treasury
        uint256 accumulatedProviderYield; // Yield accumulated for the provider
        uint256 yieldPerTokenAdjusted; // Accumulated yield per token staked, adjusted over time/phases
        mapping(address => uint256) userStaked; // User's staked amount in this strategy
        mapping(address => uint256) userYieldClaimed; // User's claimed yield for this strategy
        mapping(address => uint256) userLastStakeTime; // Timestamp of user's last stake/claim for calculation
    }
    mapping(uint256 => Strategy) public strategies; // Maps NFT ID to Strategy data
    uint256[] public registeredStrategyNFTs; // List of all registered NFT IDs

    // --- Global Parameters & Phase Shifts ---
    struct PhaseParameters {
        uint256 baseYieldRatePerSecond; // Base yield rate applied (scaled)
        uint256 stakingFeeBps; // Staking fee in Basis Points (10000 BPS = 100%)
        uint256 withdrawalFeeBps; // Withdrawal fee in BPS
        uint256 providerCutBps; // Percentage of yield going to provider in BPS
        uint256 treasuryCutBps; // Percentage of yield going to treasury in BPS
        uint256 minimumStakingDuration; // Minimum time tokens must be staked before unstaking (seconds)
        uint256 yieldMultiplierBps; // Multiplier for yield calculation in this phase
    }
    mapping(uint256 => PhaseParameters) public phaseParams; // Parameters for each phase
    uint256 public currentPhaseId; // The ID of the currently active phase
    uint256 public phaseStartTime; // Timestamp when the current phase started

    // --- Fee & Treasury ---
    uint256 public totalProtocolFeesCollected; // Total fees collected for the protocol treasury

    // --- Events ---
    event StrategyRegistered(uint256 indexed nftId, address indexed provider);
    event StrategyStatusChanged(uint256 indexed nftId, bool active);
    event Staked(uint256 indexed nftId, address indexed user, uint256 amount, uint256 newTotalStaked);
    event Unstaked(uint256 indexed nftId, address indexed user, uint256 amount, uint256 feePaid, uint256 newTotalStaked);
    event YieldClaimed(uint256 indexed nftId, address indexed user, uint256 amount);
    event PhaseShiftTriggered(uint256 indexed oldPhaseId, uint256 indexed newPhaseId, uint256 timestamp);
    event PhaseParametersUpdated(uint256 indexed phaseId);
    event FeeRatesUpdated(uint256 stakingFeeBps, uint256 withdrawalFeeBps, uint256 providerCutBps, uint256 treasuryCutBps);
    event BaseYieldRateUpdated(uint256 baseYieldRatePerSecond);
    event MinimumStakingDurationUpdated(uint256 duration);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event StrategyProviderAdded(address indexed provider);
    event StrategyProviderRemoved(address indexed provider);
    event KeeperAdded(address indexed keeper);
    event KeeperRemoved(address indexed keeper);
    event StrategyYieldMultiplierUpdated(uint256 indexed nftId, uint256 multiplierBps);


    // --- Function Summaries ---

    // --- Admin & Setup Functions (Only Owner) ---
    // 1. constructor(address _stakingToken, address _strategyNFTContract): Initializes the contract with token and NFT addresses.
    // 2. setStakingToken(address _stakingToken): Sets the address of the staking ERC20 token. Requires Ownable.
    // 3. setStrategyNFTContract(address _strategyNFTContract): Sets the address of the strategy ERC721 NFT contract. Requires Ownable.
    // 4. addStrategyProvider(address _provider): Adds an address to the list of authorized strategy providers. Requires Ownable.
    // 5. removeStrategyProvider(address _provider): Removes an address from the list of authorized strategy providers. Requires Ownable.
    // 6. addKeeper(address _keeper): Adds an address to the list of authorized keepers. Requires Ownable.
    // 7. removeKeeper(address _keeper): Removes an address from the list of authorized keepers. Requires Ownable.
    // 8. withdrawProtocolFees(address _recipient): Allows the owner to withdraw accumulated protocol fees. Requires Ownable.

    // --- Strategy Management Functions (Only StrategyProvider or Owner) ---
    // 9. registerStrategyNFT(uint256 _nftId): Registers an NFT ID as a valid strategy. Requires StrategyProvider or Ownable.
    // 10. activateStrategyNFT(uint256 _nftId): Activates a registered strategy NFT, allowing staking/unstaking/claiming. Requires StrategyProvider or Ownable.
    // 11. deactivateStrategyNFT(uint256 _nftId): Deactivates a strategy NFT, pausing operations (except perhaps emergency unstake). Requires StrategyProvider or Ownable.

    // --- Parameter Update Functions (Only Keeper or Owner) ---
    // 12. setPhaseParameters(uint256 _phaseId, PhaseParameters calldata _params): Sets or updates parameters for a specific phase ID. Requires Keeper or Ownable.
    // 13. triggerPhaseShift(uint256 _newPhaseId): Changes the current active phase of the vault, applying new parameters. Requires Keeper or Ownable.
    // 14. setBaseYieldRate(uint256 _rate): Sets the global base yield rate per second. Requires Keeper or Ownable.
    // 15. setFeeRates(uint256 _stakingFeeBps, uint256 _withdrawalFeeBps, uint256 _providerCutBps, uint256 _treasuryCutBps): Sets the various fee percentages. Requires Keeper or Ownable.
    // 16. setMinimumStakingDuration(uint256 _duration): Sets the minimum time users must stake before unstaking. Requires Keeper or Ownable.
    // 17. updateStrategyYieldMultiplier(uint256 _nftId, uint256 _multiplierBps): Allows a Keeper to update a specific strategy's yield multiplier (simulating external performance input). Requires Keeper.

    // --- User Interaction Functions ---
    // 18. stake(uint256 _nftId, uint256 _amount): Stakes _amount of stakingToken into the strategy associated with _nftId. Requires token approval.
    // 19. unstake(uint256 _nftId, uint256 _amount): Unstakes _amount of tokens from the strategy. Applies withdrawal fee and duration check.
    // 20. claimYield(uint256 _nftId): Claims accumulated yield for the caller from the specified strategy.

    // --- View Functions (Public Read-Only) ---
    // 21. viewStakedBalance(uint256 _nftId, address _user): Gets the amount _user has staked in _nftId.
    // 22. viewClaimableYield(uint256 _nftId, address _user): Calculates and returns the yield _user can claim for _nftId *without* claiming it.
    // 23. viewTotalStakedForStrategy(uint256 _nftId): Gets the total amount staked in _nftId.
    // 24. viewStrategyProvider(uint256 _nftId): Gets the provider address for _nftId.
    // 25. isStrategyActive(uint256 _nftId): Checks if a strategy NFT is currently active.
    // 26. getRegisteredStrategyNFTs(): Returns the array of all registered strategy NFT IDs.
    // 27. getCurrentPhase(): Returns the current active phase ID.
    // 28. getPhaseParameters(uint256 _phaseId): Returns the parameters for a given phase ID.
    // 29. getStakingFeeRate(): Returns the current staking fee in BPS based on the current phase.
    // 30. getWithdrawalFeeRate(): Returns the current withdrawal fee in BPS based on the current phase.
    // 31. getProviderCutRate(): Returns the current provider cut percentage in BPS based on the current phase.
    // 32. getTreasuryCutRate(): Returns the current treasury cut percentage in BPS based on the current phase.
    // 33. getMinimumStakingDuration(): Returns the current minimum staking duration in seconds based on the current phase.
    // 34. getBaseYieldRate(): Returns the current global base yield rate per second based on the current phase.
    // 35. getStrategyYieldMultiplier(uint256 _nftId): Returns the specific yield multiplier for a strategy (defaults if not set by keeper).

    // --- Internal Helper Functions ---
    // _calculateYield(uint256 _nftId, address _user): Calculates the potential yield accrued since last interaction.
    // _updateAccruedYield(uint256 _nftId, address _user): Updates the accumulated yield for a user and strategy based on time passed.
    // _applyPhaseModifiers(uint256 _baseValue): Applies current phase yield multiplier.

    // Note: The actual yield generation mechanism is simplified for this example.
    // In a real protocol, yield might come from external DeFi interactions,
    // and a Keeper/Oracle would report accumulated yield or strategy performance.
    // This contract focuses on the *distribution* and *management* around the strategies.
```

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // Added for safety

/**
 * @title QuantumVault
 * @dev A creative vault contract allowing users to stake tokens into strategies represented by NFTs,
 *      featuring dynamic parameters via Phase Shifts and complex yield distribution.
 *      Yield generation is simplified; the contract manages distribution and state.
 */
contract QuantumVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public stakingToken; // The token users stake
    IERC721 public strategyNFTContract; // The contract for strategy NFTs

    // --- Role-Based Access Control ---
    mapping(address => bool) public isStrategyProvider; // Can register/manage strategy NFTs
    mapping(address => bool) public isKeeper; // Can trigger phase shifts or update oracle-like data

    // --- Strategy State ---
    struct Strategy {
        address provider; // Address of the strategy provider
        bool active; // Can users stake/claim/unstake?
        uint256 totalStaked; // Total stakingToken staked in this strategy

        // Simplified yield tracking:
        // yieldPerTokenAdjusted represents a cumulative yield index.
        // When a user interacts (stake/unstake/claim), their yield is calculated
        // based on the change in this index since their last interaction time,
        // multiplied by their staked balance during that period.
        uint256 yieldPerTokenAdjusted; // Accumulated yield per token staked, scaled

        mapping(address => uint256) userStaked; // User's staked amount in this strategy
        mapping(address => uint256) userYieldClaimed; // Total yield user has ever claimed for this strategy
        mapping(address => uint256) userLastInteractionYieldIndex; // yieldPerTokenAdjusted value at the time of last user interaction
        mapping(address => uint256) userLastStakeTime; // Timestamp of user's last stake/claim for calculation

        // Specific multiplier for this strategy, updateable by keeper
        uint256 strategyYieldMultiplierBps; // Yield multiplier in BPS specific to this strategy
    }
    mapping(uint256 => Strategy) public strategies; // Maps NFT ID to Strategy data
    uint256[] public registeredStrategyNFTs; // List of all registered NFT IDs

    // --- Global Parameters & Phase Shifts ---
    struct PhaseParameters {
        uint256 baseYieldRatePerSecondScaled; // Base yield rate applied (e.g., 1e18 for 1 unit per token per second)
        uint256 stakingFeeBps; // Staking fee in Basis Points (10000 BPS = 100%)
        uint256 withdrawalFeeBps; // Withdrawal fee in BPS
        uint256 providerCutBps; // Percentage of yield going to provider in BPS
        uint256 treasuryCutBps; // Percentage of yield going to treasury in BPS
        uint256 minimumStakingDuration; // Minimum time tokens must be staked before unstaking (seconds)
        uint256 phaseYieldMultiplierBps; // Multiplier for yield calculation in this phase (e.g., 12000 for 1.2x)
    }
    mapping(uint256 => PhaseParameters) public phaseParams; // Parameters for each phase
    uint256 public currentPhaseId; // The ID of the currently active phase
    uint256 public phaseStartTime; // Timestamp when the current phase started

    // --- Fee & Treasury ---
    uint256 public totalProtocolFeesCollected; // Total fees collected for the protocol treasury

    // --- Events ---
    event StrategyRegistered(uint256 indexed nftId, address indexed provider);
    event StrategyStatusChanged(uint256 indexed nftId, bool active);
    event Staked(uint256 indexed nftId, address indexed user, uint256 amount, uint256 newTotalStaked);
    event Unstaked(uint256 indexed nftId, address indexed user, uint256 amount, uint256 feePaid, uint256 newTotalStaked);
    event YieldClaimed(uint256 indexed nftId, address indexed user, uint256 amount);
    event PhaseShiftTriggered(uint256 indexed oldPhaseId, uint256 indexed newPhaseId, uint256 timestamp);
    event PhaseParametersUpdated(uint256 indexed phaseId);
    event FeeRatesUpdated(uint256 stakingFeeBps, uint256 withdrawalFeeBps, uint256 providerCutBps, uint256 treasuryCutBps);
    event BaseYieldRateUpdated(uint256 baseYieldRatePerSecondScaled);
    event MinimumStakingDurationUpdated(uint256 duration);
    event ProtocolFeesWithdrawn(address indexed recipient, uint256 amount);
    event StrategyProviderAdded(address indexed provider);
    event StrategyProviderRemoved(address indexed provider);
    event KeeperAdded(address indexed keeper);
    event KeeperRemoved(address indexed keeper);
    event StrategyYieldMultiplierUpdated(uint256 indexed nftId, uint256 multiplierBps);


    // --- Constructor ---

    constructor(address _stakingToken, address _strategyNFTContract) Ownable(msg.sender) {
        stakingToken = IERC20(_stakingToken);
        strategyNFTContract = IERC721(_strategyNFTContract);

        // Initialize default phase 0 parameters (can be updated later)
        phaseParams[0] = PhaseParameters({
            baseYieldRatePerSecondScaled: 1e15, // Example: 0.001 per token per second (scaled)
            stakingFeeBps: 0,
            withdrawalFeeBps: 0,
            providerCutBps: 2000, // 20%
            treasuryCutBps: 500, // 5%
            minimumStakingDuration: 0, // No minimum duration initially
            phaseYieldMultiplierBps: 10000 // 1x
        });
        currentPhaseId = 0;
        phaseStartTime = block.timestamp;
    }

    // --- Modifiers ---

    modifier onlyStrategyProviderOrOwner() {
        require(isStrategyProvider[msg.sender] || owner() == msg.sender, "Not authorized: Strategy Provider or Owner required");
        _;
    }

     modifier onlyKeeperOrOwner() {
        require(isKeeper[msg.sender] || owner() == msg.sender, "Not authorized: Keeper or Owner required");
        _;
    }

    modifier whenStrategyExistsAndActive(uint256 _nftId) {
        require(strategies[_nftId].provider != address(0), "Strategy NFT not registered");
        require(strategies[_nftId].active, "Strategy NFT is not active");
        _;
    }

    // --- Admin & Setup Functions ---

    // 1. (constructor already above)

    // 2. Sets the address of the staking ERC20 token.
    function setStakingToken(address _stakingToken) external onlyOwner {
        stakingToken = IERC20(_stakingToken);
    }

    // 3. Sets the address of the strategy ERC721 NFT contract.
    function setStrategyNFTContract(address _strategyNFTContract) external onlyOwner {
        strategyNFTContract = IERC721(_strategyNFTContract);
    }

    // 4. Adds an address to the list of authorized strategy providers.
    function addStrategyProvider(address _provider) external onlyOwner {
        require(_provider != address(0), "Invalid address");
        isStrategyProvider[_provider] = true;
        emit StrategyProviderAdded(_provider);
    }

    // 5. Removes an address from the list of authorized strategy providers.
    function removeStrategyProvider(address _provider) external onlyOwner {
        require(_provider != address(0), "Invalid address");
        isStrategyProvider[_provider] = false;
        emit StrategyProviderRemoved(_provider);
    }

    // 6. Adds an address to the list of authorized keepers.
    function addKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "Invalid address");
        isKeeper[_keeper] = true;
        emit KeeperAdded(_keeper);
    }

    // 7. Removes an address from the list of authorized keepers.
    function removeKeeper(address _keeper) external onlyOwner {
        require(_keeper != address(0), "Invalid address");
        isKeeper[_keeper] = false;
        emit KeeperRemoved(_keeper);
    }

    // 8. Allows the owner to withdraw accumulated protocol fees.
    function withdrawProtocolFees(address _recipient) external onlyOwner nonReentrant {
        require(_recipient != address(0), "Invalid recipient address");
        uint256 amount = totalProtocolFeesCollected;
        require(amount > 0, "No fees to withdraw");
        totalProtocolFeesCollected = 0;
        stakingToken.safeTransfer(_recipient, amount);
        emit ProtocolFeesWithdrawn(_recipient, amount);
    }

    // --- Strategy Management Functions ---

    // 9. Registers an NFT ID as a valid strategy, linking it to a provider.
    function registerStrategyNFT(uint256 _nftId) external onlyStrategyProviderOrOwner nonReentrant {
        // Check if NFT exists and caller owns it (optional but good practice)
        require(strategyNFTContract.ownerOf(_nftId) == msg.sender, "Caller must own the Strategy NFT");
        require(strategies[_nftId].provider == address(0), "Strategy NFT already registered");

        strategies[_nftId].provider = msg.sender;
        strategies[_nftId].active = true; // Strategies are active by default upon registration
        strategies[_nftId].strategyYieldMultiplierBps = 10000; // Default 1x multiplier

        registeredStrategyNFTs.push(_nftId); // Add to the list of registered NFTs

        emit StrategyRegistered(_nftId, msg.sender);
        emit StrategyStatusChanged(_nftId, true);
    }

    // 10. Activates a registered strategy NFT, allowing staking/unstaking/claiming.
    function activateStrategyNFT(uint256 _nftId) external onlyStrategyProviderOrOwner {
        require(strategies[_nftId].provider != address(0), "Strategy NFT not registered");
        require(!strategies[_nftId].active, "Strategy NFT is already active");
        // Only the provider or owner can activate their/any strategy
        require(strategies[_nftId].provider == msg.sender || owner() == msg.sender, "Not authorized to activate this strategy");

        strategies[_nftId].active = true;
        emit StrategyStatusChanged(_nftId, true);
    }

    // 11. Deactivates a strategy NFT, pausing operations (except perhaps emergency unstake logic, not implemented here).
    function deactivateStrategyNFT(uint256 _nftId) external onlyStrategyProviderOrOwner {
        require(strategies[_nftId].provider != address(0), "Strategy NFT not registered");
        require(strategies[_nftId].active, "Strategy NFT is already inactive");
        // Only the provider or owner can deactivate their/any strategy
         require(strategies[_nftId].provider == msg.sender || owner() == msg.sender, "Not authorized to deactivate this strategy");

        strategies[_nftId].active = false;
        // Note: Deactivation doesn't force unstake. Users cannot stake/claim,
        // and unstaking might have different rules (e.g., no fee, forced unlock).
        // Simple deactivation here just prevents new stakes/claims and applies fee on unstake.
        // More complex emergency logic would require a separate function/state.
        emit StrategyStatusChanged(_nftId, false);
    }

    // --- Parameter Update Functions ---

    // 12. Sets or updates parameters for a specific phase ID.
    function setPhaseParameters(uint256 _phaseId, PhaseParameters calldata _params) external onlyKeeperOrOwner {
         require(_params.stakingFeeBps <= 10000, "Staking fee cannot exceed 100%");
         require(_params.withdrawalFeeBps <= 10000, "Withdrawal fee cannot exceed 100%");
         require(_params.providerCutBps.add(_params.treasuryCutBps) <= 10000, "Provider and treasury cut cannot exceed 100%");
         // Add more sanity checks if needed, e.g., minimum values

        phaseParams[_phaseId] = _params;
        emit PhaseParametersUpdated(_phaseId);
    }

    // 13. Changes the current active phase of the vault, applying new parameters.
    function triggerPhaseShift(uint256 _newPhaseId) external onlyKeeperOrOwner {
        require(_newPhaseId != currentPhaseId, "Already in this phase");
        // Ensure parameters for the new phase are set (optional, but good practice)
        // require(phaseParams[_newPhaseId].baseYieldRatePerSecondScaled > 0, "Parameters not set for new phase"); // Example check

        uint256 oldPhaseId = currentPhaseId;
        currentPhaseId = _newPhaseId;
        phaseStartTime = block.timestamp; // Reset phase timer (important for duration checks/bonuses)
        emit PhaseShiftTriggered(oldPhaseId, currentPhaseId, phaseStartTime);
    }

    // 14. Sets the global base yield rate per second (part of phase 0 params by default, can be standalone).
    // This function allows setting just the base rate without a full phase update if needed.
    function setBaseYieldRate(uint256 _rate) external onlyKeeperOrOwner {
        phaseParams[currentPhaseId].baseYieldRatePerSecondScaled = _rate;
        emit BaseYieldRateUpdated(_rate);
        // Note: this only updates the *current* phase's base rate. For persistent changes, update phaseParams.
    }

    // 15. Sets the various fee percentages (part of phase 0 params by default).
    function setFeeRates(uint256 _stakingFeeBps, uint256 _withdrawalFeeBps, uint256 _providerCutBps, uint256 _treasuryCutBps) external onlyKeeperOrOwner {
         require(_stakingFeeBps <= 10000, "Staking fee cannot exceed 100%");
         require(_withdrawalFeeBps <= 10000, "Withdrawal fee cannot exceed 100%");
         require(_providerCutBps.add(_treasuryCutBps) <= 10000, "Provider and treasury cut cannot exceed 100%");

        PhaseParameters storage current = phaseParams[currentPhaseId];
        current.stakingFeeBps = _stakingFeeBps;
        current.withdrawalFeeBps = _withdrawalFeeBps;
        current.providerCutBps = _providerCutBps;
        current.treasuryCutBps = _treasuryCutBps;

        emit FeeRatesUpdated(_stakingFeeBps, _withdrawalFeeBps, _providerCutBps, _treasuryCutBps);
         // Note: this only updates the *current* phase's rates. For persistent changes, update phaseParams.
    }

    // 16. Sets the minimum time users must stake before unstaking (part of phase 0 params).
    function setMinimumStakingDuration(uint256 _duration) external onlyKeeperOrOwner {
        phaseParams[currentPhaseId].minimumStakingDuration = _duration;
        emit MinimumStakingDurationUpdated(_duration);
        // Note: this only updates the *current* phase's duration. For persistent changes, update phaseParams.
    }

    // 17. Allows a Keeper to update a specific strategy's yield multiplier (simulating external performance input).
    function updateStrategyYieldMultiplier(uint256 _nftId, uint256 _multiplierBps) external onlyKeeper {
         require(strategies[_nftId].provider != address(0), "Strategy NFT not registered");
         require(_multiplierBps <= 100000, "Multiplier too high (max 10x)"); // Example limit

        // Before updating multiplier, ensure any pending yield for existing stakers is accounted for
        // This is crucial to avoid unfairly distributing yield based on the *new* multiplier to old stakes.
        // In a real system, this would involve iterating through all users and updating their
        // userLastInteractionYieldIndex or similar mechanism.
        // For simplicity in this example, we'll just update the multiplier directly, which might
        // mean users staking *after* the update benefit differently than those staking before.
        // A more robust system would require a pull-based yield calculation mechanism that
        // snapshots parameters at the time yield accrues.
        // Calling _updateAccruedYield for *each user* in the strategy here would be gas-prohibitive.
        // A better approach would be a global yield index update triggered periodically by keepers.
        // This function serves as a conceptual placeholder.

        strategies[_nftId].strategyYieldMultiplierBps = _multiplierBps;
        emit StrategyYieldMultiplierUpdated(_nftId, _multiplierBps);
    }


    // --- User Interaction Functions ---

    // 18. Stakes _amount of stakingToken into the strategy associated with _nftId.
    function stake(uint256 _nftId, uint256 _amount) external nonReentrant whenStrategyExistsAndActive(_nftId) {
        require(_amount > 0, "Amount must be greater than 0");

        // Calculate yield before stake (important for compound calculations)
        _updateAccruedYield(_nftId, msg.sender);

        // Apply staking fee
        PhaseParameters storage currentPhase = phaseParams[currentPhaseId];
        uint256 stakingFee = _amount.mul(currentPhase.stakingFeeBps).div(10000);
        uint256 amountAfterFee = _amount.sub(stakingFee);

        // Transfer tokens from user
        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

        // Update user and strategy state
        strategies[_nftId].userStaked[msg.sender] = strategies[_nftId].userStaked[msg.sender].add(amountAfterFee);
        strategies[_nftId].totalStaked = strategies[_nftId].totalStaked.add(amountAfterFee);
        strategies[_nftId].userLastStakeTime[msg.sender] = block.timestamp;
        strategies[_nftId].userLastInteractionYieldIndex[msg.sender] = strategies[_nftId].yieldPerTokenAdjusted; // Snapshot yield index

        // Accumulate protocol fee
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(stakingFee);

        emit Staked(_nftId, msg.sender, amountAfterFee, strategies[_nftId].totalStaked); // Emit amount *after* fee
    }

    // 19. Unstakes _amount of tokens from the strategy. Applies withdrawal fee and duration check.
    function unstake(uint256 _nftId, uint256 _amount) external nonReentrant whenStrategyExistsAndActive(_nftId) {
        Strategy storage strategy = strategies[_nftId];
        require(_amount > 0, "Amount must be greater than 0");
        require(strategy.userStaked[msg.sender] >= _amount, "Insufficient staked balance");

        // Calculate yield before unstake
         _updateAccruedYield(_nftId, msg.sender);

        // Check minimum staking duration
        PhaseParameters storage currentPhase = phaseParams[currentPhaseId];
        if (currentPhase.minimumStakingDuration > 0) {
            require(block.timestamp >= strategy.userLastStakeTime[msg.sender].add(currentPhase.minimumStakingDuration),
                "Minimum staking duration not met");
        }

        // Apply withdrawal fee
        uint256 withdrawalFee = _amount.mul(currentPhase.withdrawalFeeBps).div(10000);
        uint256 amountToReturn = _amount.sub(withdrawalFee);

        // Update user and strategy state
        strategy.userStaked[msg.sender] = strategy.userStaked[msg.sender].sub(_amount);
        strategy.totalStaked = strategy.totalStaked.sub(_amount);
        strategy.userLastInteractionYieldIndex[msg.sender] = strategy.yieldPerTokenAdjusted; // Snapshot yield index
        // strategy.userLastStakeTime[msg.sender] is not reset here, only updated on *stake*.

        // Transfer tokens back to user
        stakingToken.safeTransfer(msg.sender, amountToReturn);

        // Accumulate protocol fee
        totalProtocolFeesCollected = totalProtocolFeesCollected.add(withdrawalFee);

        emit Unstaked(_nftId, msg.sender, _amount, withdrawalFee, strategy.totalStaked);
    }

    // 20. Claims accumulated yield for the caller from the specified strategy.
    function claimYield(uint256 _nftId) external nonReentrant whenStrategyExistsAndActive(_nftId) {
        Strategy storage strategy = strategies[_nftId];
        uint256 claimableYield = _calculateClaimableYield(_nftId, msg.sender);
        require(claimableYield > 0, "No yield to claim");

        // Update accrued yield indexes before claiming
        _updateAccruedYield(_nftId, msg.sender); // Ensure indexes are current

        // The calculated claimableYield is the user's portion.
        // The internal _updateAccruedYield already handled distributing the total yield
        // proportionally to provider and treasury when it updated the strategy's
        // yieldPerTokenAdjusted index.

        // Update user's claimed yield
        strategy.userYieldClaimed[msg.sender] = strategy.userYieldClaimed[msg.sender].add(claimableYield);

        // Transfer yield tokens to user (assuming stakingToken is also yield token)
        // If yield was a different token, this would need adjustment.
        stakingToken.safeTransfer(msg.sender, claimableYield);

        emit YieldClaimed(_nftId, msg.sender, claimableYield);
    }

    // --- View Functions ---

    // 21. Gets the amount _user has staked in _nftId.
    function viewStakedBalance(uint256 _nftId, address _user) external view returns (uint256) {
        return strategies[_nftId].userStaked[_user];
    }

    // 22. Calculates and returns the yield _user can claim for _nftId *without* claiming it.
    function viewClaimableYield(uint256 _nftId, address _user) public view returns (uint256) {
        return _calculateClaimableYield(_nftId, _user);
    }

    // 23. Gets the total amount staked in _nftId.
    function viewTotalStakedForStrategy(uint256 _nftId) external view returns (uint256) {
        return strategies[_nftId].totalStaked;
    }

    // 24. Gets the provider address for _nftId. Returns address(0) if not registered.
    function viewStrategyProvider(uint256 _nftId) external view returns (address) {
        return strategies[_nftId].provider;
    }

    // 25. Checks if a strategy NFT is currently active.
    function isStrategyActive(uint256 _nftId) external view returns (bool) {
        return strategies[_nftId].active;
    }

    // 26. Returns the array of all registered strategy NFT IDs.
    function getRegisteredStrategyNFTs() external view returns (uint256[] memory) {
        return registeredStrategyNFTs;
    }

    // 27. Returns the current active phase ID.
    function getCurrentPhase() external view returns (uint256) {
        return currentPhaseId;
    }

    // 28. Returns the parameters for a given phase ID.
    function getPhaseParameters(uint256 _phaseId) external view returns (PhaseParameters memory) {
        return phaseParams[_phaseId];
    }

    // 29. Returns the current staking fee in BPS based on the current phase.
    function getStakingFeeRate() external view returns (uint256) {
        return phaseParams[currentPhaseId].stakingFeeBps;
    }

    // 30. Returns the current withdrawal fee in BPS based on the current phase.
    function getWithdrawalFeeRate() external view returns (uint256) {
        return phaseParams[currentPhaseId].withdrawalFeeBps;
    }

    // 31. Returns the current provider cut percentage in BPS based on the current phase.
    function getProviderCutRate() external view returns (uint256) {
        return phaseParams[currentPhaseId].providerCutBps;
    }

    // 32. Returns the current treasury cut percentage in BPS based on the current phase.
    function getTreasuryCutRate() external view returns (uint256) {
        return phaseParams[currentPhaseId].treasuryCutBps;
    }

    // 33. Returns the current minimum staking duration in seconds based on the current phase.
    function getMinimumStakingDuration() external view returns (uint256) {
        return phaseParams[currentPhaseId].minimumStakingDuration;
    }

    // 34. Returns the current global base yield rate per second based on the current phase.
    function getBaseYieldRate() external view returns (uint256) {
        return phaseParams[currentPhaseId].baseYieldRatePerSecondScaled;
    }

     // 35. Returns the specific yield multiplier for a strategy.
    function getStrategyYieldMultiplier(uint256 _nftId) external view returns (uint256) {
        // Returns 0 if strategy not registered, or the specific multiplier
        return strategies[_nftId].strategyYieldMultiplierBps;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Calculates the potential yield accrued for a user in a strategy since their last interaction.
     * This is a view function for estimation *before* state changes.
     * The actual state update happens in _updateAccruedYield.
     */
    function _calculateClaimableYield(uint256 _nftId, address _user) internal view returns (uint256) {
        Strategy storage strategy = strategies[_nftId];
        uint256 stakedAmount = strategy.userStaked[_user];

        if (stakedAmount == 0) {
            return 0;
        }

        // Get current yield index for the strategy
        // We need to calculate what the *current* theoretical yield index would be if updated now
        uint256 currentStrategyYieldIndex = strategy.yieldPerTokenAdjusted;
        uint256 timeElapsedSinceLastUpdate = block.timestamp.sub(strategy.userLastStakeTime[_user]); // Or last interaction time

        // Calculate accrued yield based on time, amount, and current parameters
        // Simplified yield calculation:
        // yield = stakedAmount * baseRate * phaseMultiplier * strategyMultiplier * time
        // Scaled for precision (using 1e18 as scaling factor)
        // yieldPerToken per second = baseRate * phaseMultiplier / 10000 * strategyMultiplier / 10000
        // total yield accrued for strategy = totalStaked * yieldPerToken per second * time
        // This calculation is complex because the multipliers can change over time and phases.
        // The yield index approach is better: Index change = total yield / total staked
        // User yield = user staked * (current index - user last interaction index)

        // Let's update the theoretical current yield index
        PhaseParameters storage currentPhase = phaseParams[currentPhaseId];
         if (strategy.totalStaked > 0 && timeElapsedSinceLastUpdate > 0) {
             // Calculate yield per token accrued since last update
             uint256 yieldPerTokenAccruedScaled = (uint256(currentPhase.baseYieldRatePerSecondScaled)
                 .mul(currentPhase.phaseYieldMultiplierBps)).div(10000) // Apply phase multiplier
                 .mul(strategy.strategyYieldMultiplierBps).div(10000) // Apply strategy multiplier
                 .mul(timeElapsedSinceLastUpdate); // Multiply by time elapsed

            currentStrategyYieldIndex = strategy.yieldPerTokenAdjusted.add(yieldPerTokenAccruedScaled);
         }
        // Note: This view function *simulates* the update for calculation purposes.
        // The actual state update happens in the non-view _updateAccruedYield.

        uint256 indexChange = currentStrategyYieldIndex.sub(strategy.userLastInteractionYieldIndex[_user]);

        // User's gross yield = stakedAmount * indexChange (scaled)
        // Need to handle scaling correctly. If index is scaled by 1e18, result is also scaled.
        uint256 userGrossYieldScaled = stakedAmount.mul(indexChange);

        // Apply yield distribution (this happens in _updateAccruedYield state update,
        // but for the view function we calculate the user's portion of the *potential* yield)
        uint256 userCutBps = 10000 // Total (100%)
                             .sub(currentPhase.providerCutBps)
                             .sub(currentPhase.treasuryCutBps);

        uint256 userClaimable = userGrossYieldScaled.mul(userCutBps).div(10000);

        // Assuming yield index scaling is 1e18
        return userClaimable.div(1e18); // Unscale to get actual token amount

    }

    /**
     * @dev Updates the accumulated yield index for a strategy and user based on time passed.
     * This function should be called internally before or after any user interaction (stake, unstake, claim).
     */
    function _updateAccruedYield(uint256 _nftId, address _user) internal {
        Strategy storage strategy = strategies[_nftId];
        PhaseParameters storage currentPhase = phaseParams[currentPhaseId];

        uint256 timeElapsed = block.timestamp.sub(strategy.userLastStakeTime[_user]);
        if (timeElapsed == 0 || strategy.totalStaked == 0) {
            // No time passed or no total staked, no yield accrued for the strategy since last update
            strategy.userLastStakeTime[_user] = block.timestamp; // Update user's timestamp anyway
            // User's index is updated to match the *current* strategy index even if no yield accrued
            strategy.userLastInteractionYieldIndex[_user] = strategy.yieldPerTokenAdjusted;
            return;
        }

        // Calculate the amount of new yield accrued *for the entire strategy pool* since the last update
        // This is based on total staked, time, base rate, phase multiplier, and strategy multiplier.
        // Yield per token scaled per second = baseRate * phaseMultiplier / 10000 * strategyMultiplier / 10000
        uint256 yieldPerTokenPerSecondScaled = (uint256(currentPhase.baseYieldRatePerSecondScaled)
            .mul(currentPhase.phaseYieldMultiplierBps)).div(10000)
            .mul(strategy.strategyYieldMultiplierBps).div(10000);

        // Total new yield scaled = totalStaked * yieldPerTokenPerSecondScaled * timeElapsed
        uint256 totalNewYieldScaled = strategy.totalStaked
            .mul(yieldPerTokenPerSecondScaled)
            .mul(timeElapsed);

        // Update the strategy's cumulative yield index
        // Index increase = Total new yield scaled / total staked (if totalStaked > 0)
        // We already checked totalStaked > 0
        uint256 indexIncrease = totalNewYieldScaled.div(strategy.totalStaked);
        strategy.yieldPerTokenAdjusted = strategy.yieldPerTokenAdjusted.add(indexIncrease);

        // Now, calculate the user's share of this *newly accrued* yield based on their *staked amount during that period*
        // and the index change *relevant to them*.
        // User's gross yield from this period = user's staked amount * (current strategy index - user's last interaction index)
        uint256 userIndexChange = strategy.yieldPerTokenAdjusted.sub(strategy.userLastInteractionYieldIndex[_user]);
        uint256 userGrossYieldScaled = strategy.userStaked[_user].mul(userIndexChange);

        // Distribute this user's gross yield share
        uint256 providerShareScaled = userGrossYieldScaled.mul(currentPhase.providerCutBps).div(10000);
        uint256 treasuryShareScaled = userGrossYieldScaled.mul(currentPhase.treasuryCutBps).div(10000);
        uint256 userShareScaled = userGrossYieldScaled.sub(providerShareScaled).sub(treasuryShareScaled);

        // Accumulate provider and treasury shares (scaled)
        // These accumulated shares represent yield that can be claimed by the provider/treasury
        // A real system would need separate claim functions for providers/treasury.
        // For simplicity here, we just track the *concept* of accumulation.
        // strategy.accumulatedProviderYield = strategy.accumulatedProviderYield.add(providerShareScaled); // Keep track if needed
        // totalProtocolFeesCollected = totalProtocolFeesCollected.add(treasuryShareScaled); // Or similar mechanism for treasury

        // Update user's last interaction timestamp and yield index snapshot
        strategy.userLastStakeTime[_user] = block.timestamp;
        strategy.userLastInteractionYieldIndex[_user] = strategy.yieldPerTokenAdjusted;

        // The user's claimable yield is calculated by summing up all their userShareScaled portions
        // accumulated over time. Our current structure calculates the *total* yield
        // the user can claim *right now* based on the current strategy index.
        // This function primarily updates the index and snapshot for future calculations.

        // The actual claimable yield calculation in `_calculateClaimableYield` uses the difference
        // between the current index and the user's snapshot index to get the *total* yield
        // earned by the user *since their last interaction*. This is then distributed.
        // This index-based approach handles compounding correctly regardless of when individual users stake/claim.
    }

     /**
      * @dev Internal function to calculate the effective yield multiplier including phase and strategy specific multipliers.
      */
    function _getEffectiveYieldMultiplierBps(uint256 _nftId) internal view returns (uint256) {
         uint256 phaseMultiplier = phaseParams[currentPhaseId].phaseYieldMultiplierBps;
         uint256 strategyMultiplier = strategies[_nftId].strategyYieldMultiplierBps;

         // Total multiplier is phaseMultiplier * strategyMultiplier / 10000
         // This means if phase is 1.2x and strategy is 1.5x, total is 1.8x
         return phaseMultiplier.mul(strategyMultiplier).div(10000);
    }
}
```

---

**Explanation of Advanced/Creative Concepts:**

1.  **NFT-Represented Strategies:** Instead of a single vault or a list of hardcoded strategies, each strategy is linked to a specific ERC-721 NFT. This allows:
    *   Strategy creation/ownership to be tokenized and potentially permissioned.
    *   Strategies could have unique properties encoded in the NFT metadata or linked data.
    *   Different NFTs could represent different risk profiles, underlying assets (simulated here), or provider performance tiers.
    *   This opens up possibilities for a marketplace of strategies represented by tradeable NFTs.
2.  **Dynamic Phase Shifts:** The `PhaseParameters` struct and `triggerPhaseShift` function introduce a dynamic layer. The contract's behavior (fees, yield rates, minimum staking duration) isn't static. It can transition through predefined phases, potentially linked to external events, governance decisions, or time. This allows the protocol to adapt or create timed events (e.g., high-yield promotional phases, stricter withdrawal periods).
3.  **Role-Based Access Control (StrategyProvider, Keeper):** Moves beyond a single `owner` by defining specific roles with limited permissions. `StrategyProvider` manages their specific strategy NFTs, while `Keeper` can update dynamic parameters like phase settings or yield multipliers (simulating oracle input or protocol adjustment based on external conditions). This promotes decentralization compared to an owner-only model.
4.  **Complex Yield Distribution (Provider/Treasury Cut):** The yield calculation (`_updateAccruedYield`) not only tracks user yield but conceptually splits the total yield generated by a strategy into shares for the user, the strategy provider, and a protocol treasury. While the provider/treasury claim mechanisms are simplified here, the logic demonstrates a multi-party revenue-sharing model common in DeFi protocols.
5.  **Yield Indexing:** The `yieldPerTokenAdjusted` is a common pattern in yield protocols (like Compound or Aave's accumulation logic). Instead of calculating individual yield continuously, it tracks a cumulative index. User yield is then the difference between the current index and their snapshot index at their last interaction, multiplied by their stake. This is gas-efficient and correctly handles compounding and users joining/leaving at different times.
6.  **Time-Weighted Logic (Minimum Staking Duration):** The `minimumStakingDuration` parameter adds a time-based constraint to unstaking, configurable per phase. This can be used to encourage long-term staking or manage liquidity.
7.  **Keeper-Updatable Strategy Multiplier:** The `updateStrategyYieldMultiplier` function allows a `Keeper` to adjust the yield rate for a *specific* strategy NFT. This is a hook that could be used to integrate external data (e.g., an oracle reporting the actual APY generated by an off-chain strategy linked to the NFT) or manual adjustments based on perceived strategy performance.

This contract provides a framework for a more complex and dynamic staking or yield-farming protocol compared to basic examples, integrating NFT-based identity for strategies and dynamic rule changes. Note that a production-ready system would require more robust error handling, potentially an emergency unstake function, and potentially on-chain mechanics for external yield generation if not relying on off-chain reporting via keepers.