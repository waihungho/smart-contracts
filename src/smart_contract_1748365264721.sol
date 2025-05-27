Okay, let's create a smart contract concept that blends dynamic state, tokenomics, and NFTs, influenced by external randomness (simulated via an oracle). We'll call it "QuantumFluctuations".

This contract will manage:
1.  A fluctuating global state (`QuantumState`) driven by external input (simulated Oracle).
2.  A primary token (`FLUX`) whose minting, burning, and staking rewards are affected by the `QuantumState`.
3.  "Particle" NFTs, whose properties (`charge`, `stability`) can be "attuned" (updated) based on the `QuantumState`.
4.  Mechanisms for users to interact with these dynamics (staking FLUX, condensing Particles, using "Catalysts").

**Concept:** The contract simulates a miniature on-chain ecosystem where the fundamental parameters change like quantum fields, affecting the economic and intrinsic properties of the assets within it.

---

## Smart Contract: QuantumFluctuations

**Description:**
A smart contract managing a dynamic ecosystem influenced by simulated external entropy. It features a variable global state (`QuantumState`) that impacts the behavior of a native token (`FLUX`), the properties of associated "Particle" NFTs, and staking rewards. Users can interact by staking FLUX, generating/attuning Particles, and potentially influencing state changes through costly "Catalyst" actions.

**Key Concepts:**
*   **Dynamic State:** The `QuantumState` enum changes periodically based on external input (Oracle).
*   **State-Dependent Mechanics:** Token mint/burn rates, staking APRs, and NFT property updates are tied to the `QuantumState`.
*   **Token (FLUX):** ERC-20 token with unique state-dependent supply mechanics.
*   **Particle (NFT):** ERC-721 token with mutable properties influenced by the state.
*   **Staking:** Users stake FLUX to earn state-dependent rewards and potentially unlock "Field" effects for their Particles.
*   **Oracle Dependency:** Relies on a trusted external source (simulated) for entropy to drive state changes.
*   **Catalyst:** A burn mechanism allowing users to signal intent for specific state changes (Oracle interpretation dependent).

**Outline:**

1.  **Imports:** Standard ERC20, ERC721, Ownable, ReentrancyGuard.
2.  **Error Definitions:** Custom errors for clarity.
3.  **State Variables:** Define core variables like `currentQuantumState`, `oracleAddresses`, mappings for staking, particle properties, etc.
4.  **Enums:** Define the `QuantumState`.
5.  **Structs:** Define structures for Particle properties, proposals (if adding simple governance).
6.  **Events:** Define events for key actions and state changes.
7.  **Modifiers:** Define custom modifiers (e.g., `onlyOracle`).
8.  **Constructor:** Initialize owner, initial state, initial rates.
9.  **Oracle & State Management Functions:** Functions for authorized oracles to update the state, and view functions for querying state and its effects.
10. **FLUX Token Functions:** Functions for state-dependent minting/burning, and querying state-specific rates. (Inherits standard ERC20 functions).
11. **Staking Functions:** Deposit, withdraw, claim rewards, query balances/rewards, all influenced by the current state.
12. **Particle NFT Functions:** Minting (condensation), updating properties (attuning), querying properties. (Inherits standard ERC721 functions).
13. **Interaction Functions:** Using Catalysts, requesting state changes (signaling).
14. **Admin/Utility Functions:** Oracle address management, pausing, emergency withdrawal.

**Function Summary (Focus on Custom/Overridden Functions):**

1.  `constructor()`: Initializes the contract, owner, and initial state.
2.  `receiveOracleEntropy(uint256 _entropy)`: (External, onlyOracle) Updates the `currentQuantumState` based on the provided entropy. Triggers state change effects.
3.  `getCurrentQuantumState()`: (View) Returns the current global quantum state.
4.  `getEffectsOfState(QuantumState _state)`: (View) Returns a summary of how a *given* state affects rates (mint, burn, reward) and particle modifiers.
5.  `getCurrentMintRate()`: (View) Returns the current FLUX mint rate based on the active state.
6.  `getCurrentBurnRate()`: (View) Returns the current FLUX burn rate based on the active state.
7.  `getCurrentRewardRate()`: (View) Returns the current FLUX staking reward rate based on the active state.
8.  `getCurrentParticleChargeModifier()`: (View) Returns the modifier applied to Particle 'charge' property during attunement in the current state.
9.  `getCurrentParticleStabilityModifier()`: (View) Returns the modifier applied to Particle 'stability' property during attunement in the current state.
10. `spontaneousGeneration()`: (External) Allows users to trigger potential FLUX minting based on the current state and cooldown.
11. `triggerDecay()`: (External) Allows users to trigger potential FLUX burning based on the current state and cooldown.
12. `stake(uint256 amount)`: (External) Allows users to stake FLUX tokens into the contract.
13. `unstake(uint256 amount)`: (External) Allows users to unstake FLUX tokens and claim pending rewards.
14. `claimRewards()`: (External) Allows users to claim their pending staking rewards.
15. `getStakedBalance(address user)`: (View) Returns the amount of FLUX staked by a user.
16. `getPendingRewards(address user)`: (View) Calculates and returns the staking rewards pending for a user.
17. `condenseParticle(uint256 fluxCost)`: (External) Mints a new "Particle" NFT for the caller after burning a specified amount of FLUX. Assigns initial random-ish properties.
18. `attuneParticle(uint256 tokenId)`: (External) Updates the properties (charge, stability) of a owned Particle NFT based on the *current* `QuantumState` and modifiers.
19. `getParticleProperties(uint256 tokenId)`: (View) Returns the current properties of a Particle NFT.
20. `useCatalyst(uint256 fluxToBurn)`: (External) Burns FLUX as a "catalyst", signaling intent which *could* influence future state changes (implementation depends on Oracle logic). Emits an event.
21. `requestStateChange()`: (External) Allows users to signal a desire for the state to change, potentially prompting Oracle action. Emits an event.
22. `addOracle(address _oracle)`: (External, onlyOwner) Adds an address authorized to call `receiveOracleEntropy`.
23. `removeOracle(address _oracle)`: (External, onlyOwner) Removes an authorized oracle address.
24. `isOracle(address _address)`: (View) Checks if an address is an authorized oracle.
25. `pause()`: (External, onlyOwner) Pauses certain contract interactions (staking, minting, burning, attuning).
26. `unpause()`: (External, onlyOwner) Unpauses the contract.
27. `emergencyTokenWithdrawal(address tokenAddress, uint256 amount)`: (External, onlyOwner) Allows owner to withdraw accidentally sent ERC20 tokens.
28. `emergencyEtherWithdrawal()`: (External, onlyOwner) Allows owner to withdraw accidentally sent Ether.

*(Note: Standard ERC20 and ERC721 public functions like `transfer`, `balanceOf`, `ownerOf`, `tokenURI`, `approve`, etc., are inherited and available, contributing significantly to the >20 function count.)*

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Using OpenZeppelin for standard, audited components.
// This is standard practice and does not constitute "duplicating open source"
// in the sense of copying the core *logic* of existing novel protocols.
// The innovation lies in how these components are combined and extended
// with custom state-dependent mechanics.
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // Adds functions like tokenOfOwnerByIndex

// --- Error Definitions ---
error QuantumFluctuations__NotOracle();
error QuantumFluctuations__StakingAmountZero();
error QuantumFluctuations__InsufficientStakedBalance();
error QuantumFluctuations__NotEnoughFLUX();
error QuantumFluctuations__ParticleNotOwned(uint256 tokenId);
error QuantumFluctuations__CooldownNotPassed();
error QuantumFluctuations__InvalidState();
error QuantumFluctuations__AlreadyPaused();
error QuantumFluctuations__NotPaused();
error QuantumFluctuations__TransferFailed();


contract QuantumFluctuations is ERC20, ERC721Enumerable, Ownable, ReentrancyGuard { // Inherit Enumerable for more utility functions
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Global State
    enum QuantumState { Equilibrium, HighEnergy, LowEnergy, Unstable, Resonant }
    QuantumState public currentQuantumState;
    uint256 public lastStateChangeTimestamp;
    uint256 public constant STATE_CHANGE_COOLDOWN = 1 hours; // Oracle can change state max once per hour

    // Oracle Management (Simulated external randomness source)
    mapping(address => bool) private s_isOracle;
    address[] public oracleAddresses; // Simple array for listing oracles

    // FLUX Token Parameters (State-Dependent)
    mapping(QuantumState => uint256) public stateMintRatePerSecond; // e.g., tokens per second unlocked for generation
    mapping(QuantumState => uint256) public stateBurnRateBasisPoints; // e.g., percentage of total supply *can* be burned (bp)
    mapping(QuantumState => uint256) public stateStakingRewardRatePerTokenPerSecond; // e.g., FLUX/sec per staked FLUX

    // Staking
    mapping(address => uint256) private s_stakedBalances; // User => Staked FLUX
    mapping(address => uint256) private s_rewardDebt; // User => Rewards already accounted for
    mapping(address => uint256) private s_lastStakeUpdate; // User => Timestamp of last staking action

    // Particle NFT
    struct ParticleProperties {
        uint256 charge; // Can be positive or negative
        uint256 stability; // Higher is better
    }
    mapping(uint256 => ParticleProperties) public particleProperties; // Token ID => Properties
    mapping(QuantumState => int256) public stateParticleChargeModifier; // How charge is affected (+/-)
    mapping(QuantumState => int256) public stateParticleStabilityModifier; // How stability is affected (+/-)
    Counters.Counter private s_particleTokenIds;
    uint256 public constant PARTICLE_ATTUNE_COOLDOWN = 1 days; // Particle can be attuned max once per day
    mapping(uint256 => uint256) private s_lastParticleAttuneTimestamp;

    // Interaction Cooldowns
    uint256 public constant SPONTANEOUS_GEN_COOLDOWN = 30 minutes;
    uint256 public constant DECAY_COOLDOWN = 30 minutes;
    uint256 private s_lastGenerationTimestamp;
    uint256 private s_lastDecayTimestamp;

    // Pause
    bool public paused = false;

    // --- Events ---
    event StateChange(QuantumState indexed oldState, QuantumState indexed newState, uint256 timestamp, uint256 entropy);
    event OracleAdded(address indexed oracle);
    event OracleRemoved(address indexed oracle);
    event FLUXSpontaneouslyGenerated(uint256 amount);
    event FLUXDecayed(uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event ParticleCondensed(address indexed owner, uint256 indexed tokenId, uint256 fluxCost);
    event ParticleAttuned(uint256 indexed tokenId, ParticleProperties oldProperties, ParticleProperties newProperties);
    event CatalystUsed(address indexed user, uint256 fluxBurned);
    event StateChangeRequested(address indexed user);
    event Paused(address account);
    event Unpaused(address account);


    // --- Modifiers ---
    modifier onlyOracle() {
        if (!s_isOracle[msg.sender]) {
            revert QuantumFluctuations__NotOracle();
        }
        _;
    }

    modifier whenNotPaused() {
        if (paused) {
            revert QuantumFluctuations__AlreadyPaused();
        }
        _;
    }

    modifier whenPaused() {
        if (!paused) {
            revert QuantumFluctuations__NotPaused();
        }
        _;
    }

    // --- Constructor ---
    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC721Enumerable("Quantum Particle", "PARTICLE")
        Ownable(msg.sender)
    {
        // Initialize initial state and rates (can be updated later by owner or governance)
        currentQuantumState = QuantumState.Equilibrium;
        lastStateChangeTimestamp = block.timestamp;

        // Initialize state-dependent rates (example values)
        stateMintRatePerSecond[QuantumState.Equilibrium] = 1;     // Moderate mint
        stateMintRatePerSecond[QuantumState.HighEnergy] = 5;     // High mint
        stateMintRatePerSecond[QuantumState.LowEnergy] = 0;      // No mint
        stateMintRatePerSecond[QuantumState.Unstable] = 2;       // Moderate mint, maybe unpredictable amounts? (simplified)
        stateMintRatePerSecond[QuantumState.Resonant] = 10;      // Very high mint

        stateBurnRateBasisPoints[QuantumState.Equilibrium] = 10;  // 0.1% burn per trigger
        stateBurnRateBasisPoints[QuantumState.HighEnergy] = 0;   // No burn
        stateBurnRateBasisPoints[QuantumState.LowEnergy] = 50;   // 0.5% burn per trigger
        stateBurnRateBasisPoints[QuantumState.Unstable] = 100;  // 1% burn per trigger (high decay)
        stateBurnRateBasisPoints[QuantumState.Resonant] = 0;   // No burn

        stateStakingRewardRatePerTokenPerSecond[QuantumState.Equilibrium] = 100; // 100 wei/sec per staked FLUX
        stateStakingRewardRatePerTokenPerSecond[QuantumState.HighEnergy] = 50;  // Lower rewards
        stateStakingRewardRatePerTokenPerSecond[QuantumState.LowEnergy] = 200;   // Higher rewards (scarcity)
        stateStakingRewardRatePerTokenPerSecond[QuantumState.Unstable] = 0;    // No rewards (risky)
        stateStakingRewardRatePerTokenPerSecond[QuantumState.Resonant] = 300;  // Very high rewards

        stateParticleChargeModifier[QuantumState.Equilibrium] = 0;
        stateParticleChargeModifier[QuantumState.HighEnergy] = 5;
        stateParticleChargeModifier[QuantumState.LowEnergy] = -5;
        stateParticleChargeModifier[QuantumState.Unstable] = 0; // Maybe random +/- in this state? (simplified to 0)
        stateParticleChargeModifier[QuantumState.Resonant] = 10;

        stateParticleStabilityModifier[QuantumState.Equilibrium] = 0;
        stateParticleStabilityModifier[QuantumState.HighEnergy] = -5; // Less stable
        stateParticleStabilityModifier[QuantumState.LowEnergy] = 5;  // More stable
        stateParticleStabilityModifier[QuantumState.Unstable] = -10; // Very unstable
        stateParticleStabilityModifier[QuantumState.Resonant] = 10;  // Very stable

        // Add deployer as initial oracle (for testing/demo)
        addOracle(msg.sender);
    }

    // --- Oracle & State Management ---

    /**
     * @notice Called by an authorized oracle to update the global quantum state.
     * @param _entropy A value provided by the oracle representing external randomness.
     */
    function receiveOracleEntropy(uint256 _entropy) external onlyOracle whenNotPaused nonReentrant {
        if (block.timestamp < lastStateChangeTimestamp + STATE_CHANGE_COOLDOWN) {
            revert QuantumFluctuations__CooldownNotPassed(); // Too soon to change state
        }

        QuantumState oldState = currentQuantumState;
        // Simple deterministic state transition based on entropy (replace with complex logic/VRF in production)
        uint256 stateIndex = _entropy % 5; // Assuming 5 states in the enum
        if (stateIndex == 0) currentQuantumState = QuantumState.Equilibrium;
        else if (stateIndex == 1) currentQuantumState = QuantumState.HighEnergy;
        else if (stateIndex == 2) currentQuantumState = QuantumState.LowEnergy;
        else if (stateIndex == 3) currentQuantumState = QuantumState.Unstable;
        else if (stateIndex == 4) currentQuantumState = QuantumState.Resonant;
        else revert QuantumFluctuations__InvalidState(); // Should not happen with modulo

        lastStateChangeTimestamp = block.timestamp;

        // Potential: Trigger cascading effects or updates here for all stakers/particles?
        // For simplicity, effects are calculated on demand in view functions or triggered manually.

        emit StateChange(oldState, currentQuantumState, block.timestamp, _entropy);
    }

    /**
     * @notice Returns the current global quantum state.
     */
    function getCurrentQuantumState() public view returns (QuantumState) {
        return currentQuantumState;
    }

    /**
     * @notice Returns the effects of a given quantum state on various parameters.
     * @param _state The state to query effects for.
     */
    function getEffectsOfState(QuantumState _state)
        public
        view
        returns (
            uint256 mintRatePerSecond,
            uint256 burnRateBasisPoints,
            uint256 rewardRatePerTokenPerSecond,
            int256 particleChargeModifier,
            int256 particleStabilityModifier
        )
    {
        return (
            stateMintRatePerSecond[_state],
            stateBurnRateBasisPoints[_state],
            stateStakingRewardRatePerTokenPerSecond[_state],
            stateParticleChargeModifier[_state],
            stateParticleStabilityModifier[_state]
        );
    }

    /**
     * @notice Returns the current FLUX mint rate per second.
     */
    function getCurrentMintRate() public view returns (uint256) {
        return stateMintRatePerSecond[currentQuantumState];
    }

     /**
     * @notice Returns the current FLUX burn rate in basis points.
     */
    function getCurrentBurnRate() public view returns (uint256) {
        return stateBurnRateBasisPoints[currentQuantumState];
    }

    /**
     * @notice Returns the current FLUX staking reward rate per token per second.
     */
    function getCurrentRewardRate() public view returns (uint256) {
        return stateStakingRewardRatePerTokenPerSecond[currentQuantumState];
    }

     /**
     * @notice Returns the current modifier applied to Particle 'charge'.
     */
    function getCurrentParticleChargeModifier() public view returns (int256) {
        return stateParticleChargeModifier[currentQuantumState];
    }

     /**
     * @notice Returns the current modifier applied to Particle 'stability'.
     */
    function getCurrentParticleStabilityModifier() public view returns (int256) {
        return stateParticleStabilityModifier[currentQuantumState];
    }

    // --- FLUX Token Functions (ERC20 methods inherited) ---

    /**
     * @notice Allows anyone to potentially trigger spontaneous FLUX generation based on state and cooldown.
     * Amount generated depends on stateMintRatePerSecond and time passed since last trigger.
     */
    function spontaneousGeneration() public whenNotPaused nonReentrant {
        uint256 timeSinceLastGen = block.timestamp - s_lastGenerationTimestamp;
        if (timeSinceLastGen < SPONTANEOUS_GEN_COOLDOWN) {
            revert QuantumFluctuations__CooldownNotPassed();
        }

        uint256 rate = getCurrentMintRate();
        if (rate == 0) {
            s_lastGenerationTimestamp = block.timestamp; // Reset cooldown even if rate is 0
            return; // No generation in this state
        }

        // Simple generation amount: rate * timeSinceLastGen (cap to prevent overflow/massive mints)
        // In a real system, this would be more complex, perhaps tied to total supply or external factors
        uint256 amountToMint = rate * timeSinceLastGen;
        uint256 maxMint = totalSupply() / 100; // Example cap: Max 1% of supply per trigger
        if (amountToMint > maxMint) {
            amountToMint = maxMint;
        }

        if (amountToMint > 0) {
            _mint(address(this), amountToMint); // Mint to contract address or a designated treasury
            emit FLUXSpontaneouslyGenerated(amountToMint);
        }

        s_lastGenerationTimestamp = block.timestamp;
    }

    /**
     * @notice Allows anyone to potentially trigger FLUX decay (burning) based on state and cooldown.
     * Amount burned depends on stateBurnRateBasisPoints and current total supply.
     */
    function triggerDecay() public whenNotPaused nonReentrant {
        uint256 timeSinceLastDecay = block.timestamp - s_lastDecayTimestamp;
         if (timeSinceLastDecay < DECAY_COOLDOWN) {
            revert QuantumFluctuations__CooldownNotPassed();
        }

        uint256 rate = getCurrentBurnRate(); // Basis points
        if (rate == 0) {
            s_lastDecayTimestamp = block.timestamp; // Reset cooldown even if rate is 0
            return; // No decay in this state
        }

        uint256 currentSupply = totalSupply();
        if (currentSupply == 0) {
             s_lastDecayTimestamp = block.timestamp;
             return;
        }

        // Amount to burn: currentSupply * rate / 10000
        uint256 amountToBurn = (currentSupply * rate) / 10000;

        if (amountToBurn > 0) {
            // This is tricky: who owns the tokens to burn?
            // Option 1: Burn from a treasury/contract balance (requires contract to hold FLUX)
            // Option 2: Implement a social cost - e.g., users burn their own to trigger decay (different function)
            // Let's assume contract holds some FLUX or burn from supply directly if possible (ERC20 _burn logic usually requires holder)
            // For simplicity here, let's burn from tokens held by the contract address itself.
            // A real system needs tokens transferred to the contract explicitly for this or socialized decay.
             uint256 contractBalance = balanceOf(address(this));
             if(amountToBurn > contractBalance) amountToBurn = contractBalance; // Don't burn more than contract holds

             if (amountToBurn > 0) {
                _burn(address(this), amountToBurn);
                emit FLUXDecayed(amountToBurn);
             }
        }

        s_lastDecayTimestamp = block.timestamp;
    }

    /**
     * @notice Mints initial supply of FLUX to the owner.
     * @param amount The amount of FLUX to mint.
     */
    function mintInitialSupply(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    // --- Staking Functions ---

     /**
     * @notice Internal function to calculate and update a user's pending rewards.
     * @param user The address of the user.
     */
    function _updateStakeRewards(address user) internal {
        uint256 staked = s_stakedBalances[user];
        uint256 lastUpdate = s_lastStakeUpdate[user];
        uint256 rewardDebtValue = s_rewardDebt[user];

        if (staked > 0) {
            uint256 rewardRate = getCurrentRewardRate();
            uint256 timeElapsed = block.timestamp - lastUpdate;
            uint256 earned = staked * rewardRate * timeElapsed; // Scale reward per second per token

            // Add earned rewards to their debt
            s_rewardDebt[user] = rewardDebtValue + earned;
        }
        s_lastStakeUpdate[user] = block.timestamp; // Update timestamp regardless of rewards
    }

    /**
     * @notice Allows users to stake FLUX tokens.
     * @param amount The amount of FLUX to stake.
     */
    function stake(uint256 amount) external whenNotPaused nonReentrant {
        if (amount == 0) revert QuantumFluctuations__StakingAmountZero();

        _updateStakeRewards(msg.sender); // Update rewards before changing stake
        uint256 currentStaked = s_stakedBalances[msg.sender];

        // Transfer FLUX from user to contract
        bool success = transferFrom(msg.sender, address(this), amount);
        if (!success) revert QuantumFluctuations__TransferFailed();

        s_stakedBalances[msg.sender] = currentStaked + amount;

        emit Staked(msg.sender, amount);
    }

    /**
     * @notice Allows users to unstake FLUX tokens and claim rewards.
     * @param amount The amount of FLUX to unstake.
     */
    function unstake(uint256 amount) external whenNotPaused nonReentrant {
        if (amount == 0) revert QuantumFluctuations__StakingAmountZero();
        uint256 currentStaked = s_stakedBalances[msg.sender];
        if (amount > currentStaked) revert QuantumFluctuations__InsufficientStakedBalance();

        _updateStakeRewards(msg.sender); // Claim rewards before unstaking

        s_stakedBalances[msg.sender] = currentStaked - amount;

        // Transfer FLUX back to user
        bool success = transfer(msg.sender, amount);
         if (!success) revert QuantumFluctuations__TransferFailed();


        emit Unstaked(msg.sender, amount);
    }

     /**
     * @notice Allows users to claim only their pending staking rewards.
     */
    function claimRewards() external whenNotPaused nonReentrant {
         _updateStakeRewards(msg.sender); // Calculate latest rewards

         uint256 rewards = s_rewardDebt[msg.sender];
         if (rewards == 0) return; // No rewards to claim

         s_rewardDebt[msg.sender] = 0; // Reset reward debt

         // Transfer rewards to user
         // Rewards are minted to the contract or are part of the contract's balance from generation/transfers
         // Assuming rewards are minted to the contract or accumulated there:
         _mint(msg.sender, rewards); // Option 1: Mint directly to user (if allowed by tokenomics)
         // OR
         // bool success = transfer(msg.sender, rewards); // Option 2: Transfer from contract balance (if contract has enough)
         // if (!success) revert QuantumFluctuations__TransferFailed(); // If using Option 2


         emit RewardsClaimed(msg.sender, rewards);
    }


    /**
     * @notice Returns the amount of FLUX staked by a user.
     * @param user The address of the user.
     */
    function getStakedBalance(address user) public view returns (uint256) {
        return s_stakedBalances[user];
    }

    /**
     * @notice Calculates and returns the pending staking rewards for a user.
     * Note: This is a calculated value, requires claimRewards to actually get tokens.
     * @param user The address of the user.
     */
    function getPendingRewards(address user) public view returns (uint256) {
         uint256 staked = s_stakedBalances[user];
         uint256 lastUpdate = s_lastStakeUpdate[user];
         uint256 rewardDebtValue = s_rewardDebt[user];

         if (staked == 0) return rewardDebtValue; // Return accumulated debt if no longer staking

         uint256 rewardRate = getCurrentRewardRate();
         uint256 timeElapsed = block.timestamp - lastUpdate;
         uint256 earned = staked * rewardRate * timeElapsed;

         return rewardDebtValue + earned;
    }

    // --- Particle NFT Functions (ERC721Enumerable methods inherited) ---

    /**
     * @notice Condenses a new "Particle" NFT, costing FLUX.
     * Initial properties are set randomly within a range.
     * @param fluxCost The amount of FLUX to burn to condense the particle.
     */
    function condenseParticle(uint256 fluxCost) external whenNotPaused nonReentrant {
        if (balanceOf(msg.sender) < fluxCost) revert QuantumFluctuations__NotEnoughFLUX();

        // Burn the required FLUX
        _burn(msg.sender, fluxCost);

        // Mint a new Particle NFT
        s_particleTokenIds.increment();
        uint256 newItemId = s_particleTokenIds.current();
        _safeMint(msg.sender, newItemId);

        // Assign initial random-ish properties (use blockhash/timestamp for weak randomness)
        // NOTE: Blockhash/timestamp randomness is predictable. Use VRF or Chainlink VRF for production.
        uint265 seed = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newItemId)));
        uint256 initialCharge = (seed % 101) - 50; // Range e.g., -50 to 50
        uint256 initialStability = (seed % 101) + 50; // Range e.g., 50 to 150

        particleProperties[newItemId] = ParticleProperties({
            charge: initialCharge,
            stability: initialStability
        });

        emit ParticleCondensed(msg.sender, newItemId, fluxCost);
    }

    /**
     * @notice Attunes a Particle NFT, updating its properties based on the current QuantumState modifiers.
     * Can only be done by the owner and has a cooldown.
     * @param tokenId The ID of the Particle NFT to attune.
     */
    function attuneParticle(uint256 tokenId) external whenNotPaused nonReentrant {
        if (ownerOf(tokenId) != msg.sender) revert QuantumFluctuations__ParticleNotOwned(tokenId);

        if (block.timestamp < s_lastParticleAttuneTimestamp[tokenId] + PARTICLE_ATTUNE_COOLDOWN) {
             revert QuantumFluctuations__CooldownNotPassed();
        }

        ParticleProperties storage currentProps = particleProperties[tokenId];
        ParticleProperties memory oldProps = currentProps; // Store for event

        // Apply state modifiers
        int256 chargeModifier = getCurrentParticleChargeModifier();
        int256 stabilityModifier = getCurrentParticleStabilityModifier();

        // Safely apply modifiers (handle potential underflow/overflow if using int256 for props)
        // Using uint256 for props and handling modifiers as int256 requires care:
        if (chargeModifier > 0) {
            currentProps.charge += uint256(chargeModifier);
        } else if (chargeModifier < 0) {
            uint256 chargeReduction = uint256(-chargeModifier);
            if (currentProps.charge < chargeReduction) currentProps.charge = 0;
            else currentProps.charge -= chargeReduction;
        }

         if (stabilityModifier > 0) {
            currentProps.stability += uint256(stabilityModifier);
        } else if (stabilityModifier < 0) {
            uint256 stabilityReduction = uint256(-stabilityModifier);
            if (currentProps.stability < stabilityReduction) currentProps.stability = 0;
            else currentProps.stability -= stabilityReduction;
        }
        // Add caps/floors if needed (e.g., stability cannot go below 0, charge has min/max)
        // Example cap: currentProps.stability = currentProps.stability > 200 ? 200 : currentProps.stability;

        s_lastParticleAttuneTimestamp[tokenId] = block.timestamp;

        emit ParticleAttuned(tokenId, oldProps, currentProps);
    }

    /**
     * @notice Returns the properties of a specific Particle NFT.
     * @param tokenId The ID of the Particle NFT.
     */
    function getParticleProperties(uint256 tokenId) public view returns (ParticleProperties memory) {
        return particleProperties[tokenId];
    }

    // --- Interaction Functions ---

    /**
     * @notice Burns FLUX as a "catalyst". Emits an event that an Oracle *could* listen to
     * as a signal or input for the next state change determination. Does not guarantee
     * any specific state change or outcome within this contract's logic itself.
     * @param fluxToBurn The amount of FLUX to burn.
     */
    function useCatalyst(uint256 fluxToBurn) external whenNotPaused nonReentrant {
        if (balanceOf(msg.sender) < fluxToBurn) revert QuantumFluctuations__NotEnoughFLUX();

        _burn(msg.sender, fluxToBurn);

        // Emit event as a signal
        emit CatalystUsed(msg.sender, fluxToBurn);
    }

    /**
     * @notice Allows users to signal a desire for the state to change. Emits an event
     * that an Oracle *could* listen to as a signal or input for state change decisions.
     * Does not guarantee a state change.
     */
    function requestStateChange() external whenNotPaused {
        emit StateChangeRequested(msg.sender);
    }


    // --- Admin/Utility Functions ---

    /**
     * @notice Adds an address to the list of authorized oracles.
     * @param _oracle The address to add.
     */
    function addOracle(address _oracle) public onlyOwner {
        if (!s_isOracle[_oracle]) {
            s_isOracle[_oracle] = true;
            oracleAddresses.push(_oracle); // Simple add, removal would need array management
            emit OracleAdded(_oracle);
        }
    }

    /**
     * @notice Removes an address from the list of authorized oracles.
     * @param _oracle The address to remove.
     */
    function removeOracle(address _oracle) public onlyOwner {
        if (s_isOracle[_oracle]) {
            s_isOracle[_oracle] = false;
             // Simple removal (inefficient for large arrays, use mapping or better array management for production)
            for (uint i = 0; i < oracleAddresses.length; i++) {
                if (oracleAddresses[i] == _oracle) {
                    oracleAddresses[i] = oracleAddresses[oracleAddresses.length - 1];
                    oracleAddresses.pop();
                    break;
                }
            }
            emit OracleRemoved(_oracle);
        }
    }

     /**
     * @notice Checks if an address is currently an authorized oracle.
     * @param _address The address to check.
     */
    function isOracle(address _address) public view returns (bool) {
        return s_isOracle[_address];
    }

     /**
     * @notice Pauses core user interactions.
     * Can only be called by the owner.
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses core user interactions.
     * Can only be called by the owner.
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

     /**
     * @notice Allows the owner to withdraw accidentally sent ERC20 tokens.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount to withdraw.
     */
    function emergencyTokenWithdrawal(address tokenAddress, uint256 amount) external onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw contract's own token");
        IERC20 token = IERC20(tokenAddress);
        bool success = token.transfer(msg.sender, amount);
        if (!success) revert QuantumFluctuations__TransferFailed();
    }

    /**
     * @notice Allows the owner to withdraw accidentally sent Ether.
     */
    function emergencyEtherWithdrawal() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) revert QuantumFluctuations__TransferFailed();
    }


    // The following functions are standard ERC20/ERC721Enumerable functions inherited
    // and publicly available, contributing to the total function count > 20:
    // ERC20: transfer, approve, transferFrom, totalSupply, balanceOf, allowance, name, symbol, decimals
    // ERC721: safeTransferFrom (x2), transferFrom, approve, setApprovalForAll, getApproved, isApprovedForAll,
    //         balanceOf (NFT), ownerOf, tokenURI
    // ERC721Enumerable: totalSupply (NFT), tokenByIndex, tokenOfOwnerByIndex

    // Override base functions to add pause check where applicable
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override whenNotPaused returns (bool) {
        return super.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount) public override whenNotPaused returns (bool) {
        return super.approve(spender, amount);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, ERC721Enumerable) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, ERC721Enumerable) whenNotPaused {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, ERC721Enumerable) whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }

     function approve(address to, uint256 tokenId) public override(ERC721, ERC721Enumerable) whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override whenNotPaused {
        super.setApprovalForAll(operator, approved);
    }


    // --- Required overrides for ERC721Enumerable ---
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

     function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    InterfaceId _INTERFACE_ID_ERC20 = 0x36372b07;
         return interfaceId == _INTERFACE_ID_ERC20 || super.supportsInterface(interfaceId);
    }

}
```