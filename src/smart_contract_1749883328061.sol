Okay, let's design a smart contract with a unique, dynamic, and somewhat abstract concept, aiming for complexity beyond standard DeFi or NFT patterns.

We'll call it the **Quantum Flux Protocol**.

**Concept:**
The protocol manages a shared, dynamic "Flux State" influenced by user contributions of an ERC-20 "Energy" token and external, unpredictable input ("Cosmic Jitter") provided via an oracle. Participants contribute Energy, which influences their "Potential Entanglement Score". Periodically, or when triggered, the Flux State is "observed" (calculated based on current total Energy, Jitter, and time). This state observation determines the actual reward participants can claim, based on their Entanglement Score derived from the state *at the time of claim*. The state is constantly shifting, making timing and observation key.

**Advanced/Creative Aspects:**
1.  **Dynamic State:** The core `fluxState` isn't static but changes based on aggregate user input and external data.
2.  **External Influence (Simulated Oracle):** Uses an oracle pattern to bring external "randomness" or unpredictable factors into the core state calculation.
3.  **Entanglement Score:** A metric derived from user input *and* the dynamic state, representing a probabilistic potential.
4.  **Observation Effect:** The act of "observing" or claiming interacts with the current state to realize a concrete outcome (rewards), inspired by quantum measurement.
5.  **Keeper System:** Decentralized (or semi-decentralized) mechanism to incentivize bringing the oracle data on-chain and triggering state observations.
6.  **Configurability:** Multiple parameters influence the state calculation and reward distribution, allowing protocol tuning (by owner/DAO).

**Disclaimer:** This is a conceptual contract for educational and creative purposes. The "quantum" analogy is used loosely to inspire the dynamic and probabilistic nature. Real-world quantum computing interaction with blockchains is a separate, complex field. The oracle simulation here is basic; a real oracle would require integration with Chainlink, Provable, etc.

---

**Outline and Function Summary:**

**Protocol Name:** QuantumFluxProtocol

**Description:** A protocol where users contribute ERC-20 tokens ("FluxEnergy") to influence a dynamic, shared "Flux State". This state is also affected by simulated external "Cosmic Jitter" via an oracle. Participants earn rewards based on their contribution and the current Flux State via a calculated "Potential Entanglement Score".

**Key Concepts:**
*   `FluxEnergy`: An ERC-20 token contributed by users.
*   `Flux State`: A core uint256 value that changes dynamically.
*   `Cosmic Jitter`: External data influencing the state (simulated via oracle).
*   `Potential Entanglement Score`: A user-specific metric for potential rewards, based on contribution and Flux State.
*   `Observation`: The process of updating the Flux State.
*   `Keepers`: Addresses incentivized to trigger state updates.

**State Variables:**
*   `owner`: Protocol owner.
*   `energyToken`: Address of the FluxEnergy ERC-20 token.
*   `fluxState`: The current dynamic state value.
*   `fluxStateModulus`: Modulus for the flux state calculation range.
*   `totalEnergy`: Total FluxEnergy contributed to the protocol.
*   `participantStates`: Mapping from user address to their contributed energy and last updated score/state info.
*   `lastStateObservationTime`: Timestamp of the last state update.
*   `observationInterval`: Minimum time between state observations.
*   `cosmicJitterValue`: The latest value from the simulated oracle.
*   `jitterOracleAddress`: Address authorized to push jitter values (or a simulated oracle contract).
*   `jitterInfluenceFactor`: Parameter for how much jitter affects state.
*   `rewardRate`: Parameter for converting entanglement score to reward amount.
*   `rewardDistributionFactor`: Parameter scaling the entanglement score calculation.
*   `isKeeper`: Mapping to track authorized keeper addresses.
*   `keeperRewards`: Mapping to track rewards owed to keepers.
*   `keeperRewardPerUpdate`: Amount paid to a keeper for a successful update.

**Events:**
*   `EnergyContributed`: When a user contributes energy.
*   `EnergyWithdrawn`: When a user withdraws energy.
*   `FluxStateObserved`: When the flux state is updated.
*   `CosmicJitterUpdated`: When jitter value is updated.
*   `RewardsClaimed`: When a user claims rewards.
*   `KeeperRegistered`: When a keeper is added.
*   `KeeperUnregistered`: When a keeper is removed.
*   `KeeperRewardClaimed`: When a keeper claims reward.
*   `ProtocolPaused`: When protocol is paused.
*   `ProtocolUnpaused`: When protocol is unpaused.

**Errors:**
*   `NotOwner`: Caller is not the owner.
*   `NotKeeperOrOwner`: Caller is not a keeper or owner.
*   `ProtocolPaused`: Protocol is paused.
*   `ProtocolNotPaused`: Protocol is not paused.
*   `InsufficientEnergy`: User does not have enough contributed energy.
*   `MinimumEnergyNotMet`: Contribution is below minimum.
*   `ObservationIntervalNotElapsed`: Not enough time since last observation.
*   `NoJitterValueYet`: Cosmic jitter value has not been set.
*   `ZeroAddress`: Provided address is zero.
*   `ZeroAmount`: Provided amount is zero.
*   `NoRewardsPending`: No rewards calculated for user.
*   `NoKeeperRewardsPending`: No rewards calculated for keeper.
*   `SelfAddressNotAllowed`: Cannot perform action with contract address itself.
*   `CannotRescueEnergyToken`: Cannot rescue the primary energy token.

**Functions (Minimum 20):**

1.  `constructor(address _energyToken, address _jitterOracle, uint256 _observationInterval, uint256 _fluxStateModulus)`: Initializes the contract with energy token, oracle address, interval, and modulus.
2.  `receive()`: Payable function to receive ETH for rewards.
3.  `contributeEnergy(uint256 amount)`: Users transfer FluxEnergy to the contract to increase their contribution and total energy.
4.  `withdrawEnergy(uint256 amount)`: Users reclaim contributed FluxEnergy.
5.  `updateCosmicJitter(uint256 newJitterValue)`: (Callable by Jitter Oracle address) Updates the `cosmicJitterValue`.
6.  `observeFluxState()`: (Callable by Keeper or Owner) Triggers the calculation and update of `fluxState` if the observation interval has passed and jitter is available. Includes keeper reward logic.
7.  `_calculateFluxState()`: Internal helper function to compute the new flux state based on total energy, jitter, time, and modulus.
8.  `calculatePotentialEntanglementScore(address user)`: (View) Calculates a user's current entanglement score based on their contribution and the *current* `fluxState`.
9.  `getPendingRewards(address user)`: (View) Calculates the potential ETH reward a user could claim based on their current entanglement score and `rewardRate`.
10. `claimRewards()`: Allows a user to claim calculated ETH rewards based on their current entanglement score. Resets their relevant state for reward calculation.
11. `registerKeeper(address keeperAddress)`: (Owner Only) Adds an address to the list of authorized keepers.
12. `unregisterKeeper(address keeperAddress)`: (Owner Only) Removes an address from the list of authorized keepers.
13. `claimKeeperReward()`: (Keeper Only) Allows a keeper to claim accumulated rewards for triggering updates.
14. `pauseProtocol()`: (Owner Only) Pauses core functionalities like contributing, withdrawing, and claiming.
15. `unpauseProtocol()`: (Owner Only) Unpauses the protocol.
16. `rescueERC20(address tokenAddress, uint256 amount)`: (Owner Only) Allows rescuing accidentally sent ERC-20 tokens (excluding the primary energy token).
17. `setJitterOracleAddress(address _newOracle)`: (Owner Only) Sets the address authorized to update jitter.
18. `setObservationInterval(uint256 _newInterval)`: (Owner Only) Sets the minimum time between state observations.
19. `setJitterInfluenceFactor(uint256 _newFactor)`: (Owner Only) Sets the factor influencing jitter's effect on the state.
20. `setRewardRate(uint256 _newRate)`: (Owner Only) Sets the rate converting entanglement score to ETH reward.
21. `setRewardDistributionFactor(uint256 _newFactor)`: (Owner Only) Sets the factor scaling the entanglement score calculation.
22. `setFluxStateModulus(uint256 _newModulus)`: (Owner Only) Sets the modulus for the flux state calculation.
23. `setKeeperRewardPerUpdate(uint256 _rewardAmount)`: (Owner Only) Sets the ETH reward amount for keepers per successful update.
24. `getLatestFluxState()`: (View) Returns the current `fluxState`.
25. `getLastStateObservationTime()`: (View) Returns the timestamp of the last observation.
26. `getTotalEnergy()`: (View) Returns the total contributed energy.
27. `getParticipantState(address user)`: (View) Returns a user's contributed energy.
28. `getCosmicJitterValue()`: (View) Returns the latest jitter value.
29. `getJitterOracleAddress()`: (View) Returns the configured jitter oracle address.
30. `getKeepers()`: (View) Returns the list of registered keepers (or a way to query if an address is a keeper). *Self-correction:* Returning a dynamic array is gas-intensive/impossible for potentially large lists. Let's just provide `isKeeper(address)`.
31. `isKeeper(address _address)`: (View) Checks if an address is a registered keeper.
32. `getKeeperRewardAmount(address keeper)`: (View) Returns the pending rewards for a specific keeper.
33. `getProtocolBalance()`: (View) Returns the contract's ETH balance (available for rewards).
34. `getEnergyTokenBalance()`: (View) Returns the contract's FluxEnergy token balance.

This gives us more than 20 functions, covering core logic, configuration, permissions, and views.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // SafeMath for older versions, not strictly needed in 0.8+ for simple ops but good practice for clarity or if using non-standard ops

// Using SafeMath for clarity, although most ops are safe in 0.8+ with default overflow checks
using SafeMath for uint256;

/**
 * @title QuantumFluxProtocol
 * @dev A protocol where users contribute ERC-20 tokens ("FluxEnergy") to influence a dynamic, shared "Flux State".
 * This state is also affected by simulated external "Cosmic Jitter" via an oracle. Participants earn rewards
 * based on their contribution and the current Flux State via a calculated "Potential Entanglement Score".
 *
 * Outline:
 * - Core Mechanics: Energy Contribution, Flux State Update (via Jitter & Observation), Reward Calculation/Claiming.
 * - Admin Controls: Configuration, Pausing, Emergency Rescue.
 * - Keeper System: Incentivizing state updates via authorized addresses.
 * - View Functions: Reading protocol and participant state.
 *
 * Function Summary:
 * 1. constructor: Initializes the contract.
 * 2. receive: Allows receiving ETH for rewards.
 * 3. contributeEnergy: Users send FluxEnergy to the protocol.
 * 4. withdrawEnergy: Users withdraw contributed FluxEnergy.
 * 5. updateCosmicJitter: (Oracle/Admin) Updates the external jitter value.
 * 6. observeFluxState: (Keeper/Owner) Triggers a state observation/update.
 * 7. _calculateFluxState: Internal function to calculate the new state.
 * 8. calculatePotentialEntanglementScore: (View) Estimates user's score.
 * 9. getPendingRewards: (View) Estimates user's reward amount.
 * 10. claimRewards: Allows users to claim ETH rewards based on score.
 * 11. registerKeeper: (Owner) Adds a keeper address.
 * 12. unregisterKeeper: (Owner) Removes a keeper address.
 * 13. claimKeeperReward: (Keeper) Claims reward for triggering updates.
 * 14. pauseProtocol: (Owner) Pauses core user actions.
 * 15. unpauseProtocol: (Owner) Unpauses the protocol.
 * 16. rescueERC20: (Owner) Rescues misplaced ERC-20 tokens.
 * 17. setJitterOracleAddress: (Owner) Sets the jitter oracle address.
 * 18. setObservationInterval: (Owner) Sets minimum time between state updates.
 * 19. setJitterInfluenceFactor: (Owner) Sets jitter's impact on state.
 * 20. setRewardRate: (Owner) Sets score-to-reward conversion rate.
 * 21. setRewardDistributionFactor: (Owner) Sets score scaling factor.
 * 22. setFluxStateModulus: (Owner) Sets the state value range.
 * 23. setKeeperRewardPerUpdate: (Owner) Sets keeper reward amount.
 * 24. getLatestFluxState: (View) Returns current flux state.
 * 25. getLastStateObservationTime: (View) Returns last observation timestamp.
 * 26. getTotalEnergy: (View) Returns total contributed energy.
 * 27. getParticipantState: (View) Returns user's contributed energy.
 * 28. getCosmicJitterValue: (View) Returns latest jitter.
 * 29. getJitterOracleAddress: (View) Returns oracle address.
 * 30. isKeeper: (View) Checks if address is a keeper.
 * 31. getKeeperRewardAmount: (View) Returns keeper pending reward.
 * 32. getProtocolBalance: (View) Returns contract ETH balance.
 * 33. getEnergyTokenBalance: (View) Returns contract Energy token balance.
 * 34. getMinimumEnergyContribution: (View) Returns minimum contribution.
 * 35. setMinimumEnergyContribution: (Owner) Sets minimum contribution.
 */
contract QuantumFluxProtocol is Ownable, ReentrancyGuard, Pausable {
    // --- State Variables ---
    IERC20 public immutable energyToken;

    uint256 public fluxState; // The core dynamic state
    uint256 public fluxStateModulus; // Modulus for state calculation

    uint256 public totalEnergy; // Total ERC20 tokens contributed

    struct ParticipantState {
        uint256 contributedEnergy;
        // Future expansion could add lastInteractionTime, etc.
        // For simplicity now, score is calculated dynamically on current state
    }
    mapping(address => ParticipantState) public participantStates;

    uint256 public lastStateObservationTime; // Timestamp of the last state update
    uint256 public observationInterval; // Minimum time between observations (seconds)

    uint256 public cosmicJitterValue; // Value from the simulated oracle
    address public jitterOracleAddress; // Address allowed to call updateCosmicJitter
    uint256 public jitterInfluenceFactor; // Factor scaling jitter influence (e.g., 1e18 for 1:1)

    uint256 public rewardRate; // Factor converting score to reward (e.g., 1e15 for 0.001 ETH per score point)
    uint256 public rewardDistributionFactor; // Factor scaling the entanglement score calculation (e.g., 1e18)

    uint256 public minimumEnergyContribution; // Minimum amount for contributeEnergy

    mapping(address => bool) private _isKeeper; // Keepers authorized to trigger observation
    address[] private _keepers; // Array to iterate over keepers (handle growth carefully) - Alternative: events and off-chain indexing

    mapping(address => uint256) public keeperRewards; // Rewards owed to keepers
    uint256 public keeperRewardPerUpdate; // ETH reward for a keeper triggering a successful observation

    // --- Events ---
    event EnergyContributed(address indexed user, uint256 amount, uint256 newTotalEnergy);
    event EnergyWithdrawn(address indexed user, uint256 amount, uint256 newTotalEnergy);
    event FluxStateObserved(uint256 newFluxState, uint256 totalEnergySnapshot, uint256 cosmicJitterSnapshot, uint256 observationTimestamp);
    event CosmicJitterUpdated(uint256 oldJitterValue, uint256 newJitterValue);
    event RewardsClaimed(address indexed user, uint256 rewardAmount);
    event KeeperRegistered(address indexed keeper);
    event KeeperUnregistered(address indexed keeper);
    event KeeperRewardClaimed(address indexed keeper, uint256 rewardAmount);
    event ProtocolPaused(address indexed by);
    event ProtocolUnpaused(address indexed by);
    event ERC20Rescued(address indexed token, address indexed to, uint256 amount);
    event ParametersUpdated(string parameterName, uint256 oldValue, uint256 newValue);

    // --- Errors ---
    error NotOwner();
    error NotKeeperOrOwner();
    error ProtocolPaused();
    error ProtocolNotPaused();
    error InsufficientEnergy(uint256 requested, uint256 available);
    error MinimumEnergyNotMet(uint256 sent, uint256 minimum);
    error ObservationIntervalNotElapsed(uint256 timeRemaining);
    error NoJitterValueYet();
    error ZeroAddress();
    error ZeroAmount();
    error NoRewardsPending();
    error NoKeeperRewardsPending();
    error SelfAddressNotAllowed();
    error CannotRescueEnergyToken();

    // --- Modifiers ---
    modifier onlyKeeper() {
        if (!_isKeeper[msg.sender] && msg.sender != owner()) {
            revert NotKeeperOrOwner();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address _energyToken,
        address _jitterOracle,
        uint256 _observationInterval,
        uint256 _fluxStateModulus
    ) Ownable(msg.sender) Pausable() {
        if (_energyToken == address(0)) revert ZeroAddress();
        if (_jitterOracle == address(0)) revert ZeroAddress();
        if (_observationInterval == 0) revert ZeroAmount();
        if (_fluxStateModulus == 0) revert ZeroAmount();

        energyToken = IERC20(_energyToken);
        jitterOracleAddress = _jitterOracle;
        observationInterval = _observationInterval;
        fluxStateModulus = _fluxStateModulus;

        // Set reasonable initial defaults (can be changed by owner)
        fluxState = 0;
        lastStateObservationTime = block.timestamp; // Initialize with current time
        cosmicJitterValue = 0; // Needs to be updated by oracle
        jitterInfluenceFactor = 1e18; // Default 1:1 influence
        rewardRate = 1e15; // Default 0.001 ETH per score point (adjust based on desired scale)
        rewardDistributionFactor = 1e18; // Default 1:1 scaling for score calculation
        minimumEnergyContribution = 0;
        keeperRewardPerUpdate = 0.001 ether; // Example: 0.001 ETH per update

        emit ProtocolUnpaused(msg.sender); // Start unpaused
    }

    // --- Core Protocol Functions ---

    /**
     * @dev Allows contract to receive ETH for potential rewards.
     */
    receive() external payable {}

    /**
     * @dev User contributes FluxEnergy tokens to the protocol.
     * @param amount The amount of FluxEnergy to contribute.
     */
    function contributeEnergy(uint256 amount) external whenNotPaused nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (amount < minimumEnergyContribution) revert MinimumEnergyNotMet(amount, minimumEnergyContribution);

        // Transfer tokens from user to contract
        bool success = energyToken.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");

        // Update state
        participantStates[msg.sender].contributedEnergy = participantStates[msg.sender].contributedEnergy.add(amount);
        totalEnergy = totalEnergy.add(amount);

        emit EnergyContributed(msg.sender, amount, totalEnergy);
    }

    /**
     * @dev User withdraws contributed FluxEnergy tokens from the protocol.
     * @param amount The amount of FluxEnergy to withdraw.
     */
    function withdrawEnergy(uint256 amount) external whenNotPaused nonReentrant {
        if (amount == 0) revert ZeroAmount();
        if (participantStates[msg.sender].contributedEnergy < amount) {
            revert InsufficientEnergy(amount, participantStates[msg.sender].contributedEnergy);
        }

        // Update state
        participantStates[msg.sender].contributedEnergy = participantStates[msg.sender].contributedEnergy.sub(amount);
        totalEnergy = totalEnergy.sub(amount);

        // Transfer tokens from contract to user
        bool success = energyToken.transfer(msg.sender, amount);
        require(success, "Token transfer failed");

        emit EnergyWithdrawn(msg.sender, amount, totalEnergy);
    }

    /**
     * @dev Callable by the designated jitter oracle address to update the cosmic jitter value.
     * @param newJitterValue The new value from the oracle.
     */
    function updateCosmicJitter(uint256 newJitterValue) external {
        if (msg.sender != jitterOracleAddress && msg.sender != owner()) revert NotOwner(); // Or create specific OracleRole

        uint256 oldJitterValue = cosmicJitterValue;
        cosmicJitterValue = newJitterValue;

        emit CosmicJitterUpdated(oldJitterValue, newJitterValue);
    }

    /**
     * @dev Triggers an observation and update of the flux state.
     * Callable by registered keepers or the owner, if the observation interval has passed and jitter is available.
     * Rewards the caller if they are a registered keeper.
     */
    function observeFluxState() external onlyKeeper nonReentrant {
        if (block.timestamp < lastStateObservationTime.add(observationInterval)) {
            revert ObservationIntervalNotElapsed(lastStateObservationTime.add(observationInterval).sub(block.timestamp));
        }
        if (cosmicJitterValue == 0) revert NoJitterValueYet(); // Require initial jitter setting

        uint256 oldFluxState = fluxState;
        uint256 totalEnergySnapshot = totalEnergy; // Take snapshots for calculation and event
        uint256 cosmicJitterSnapshot = cosmicJitterValue;
        uint256 observationTimestamp = block.timestamp;

        fluxState = _calculateFluxState(totalEnergySnapshot, cosmicJitterSnapshot, lastStateObservationTime, observationTimestamp);
        lastStateObservationTime = observationTimestamp;

        // Reward keeper if caller is a keeper (owner doesn't get keeper reward here)
        if (_isKeeper[msg.sender] && keeperRewardPerUpdate > 0) {
            keeperRewards[msg.sender] = keeperRewards[msg.sender].add(keeperRewardPerUpdate);
        }

        emit FluxStateObserved(fluxState, totalEnergySnapshot, cosmicJitterSnapshot, observationTimestamp);
        // No specific event for keeper reward being assigned, it's accumulated internally
    }

    /**
     * @dev Internal function to calculate the new flux state.
     * Uses a combination of inputs including total energy, jitter, time, and hashing for pseudo-randomness.
     * The modulus ensures the state stays within a defined range.
     * @param _totalEnergySnapshot Total energy at observation time.
     * @param _cosmicJitterSnapshot Jitter value at observation time.
     * @param _lastObservationTime Timestamp of previous observation.
     * @param _currentTimestamp Current block timestamp.
     * @return The newly calculated flux state.
     */
    function _calculateFluxState(
        uint256 _totalEnergySnapshot,
        uint256 _cosmicJitterSnapshot,
        uint256 _lastObservationTime,
        uint256 _currentTimestamp
    ) internal view returns (uint256) {
        if (fluxStateModulus == 0) return 0; // Prevent division by zero if modulus is unset

        // A more complex calculation involving inputs and pseudo-randomness from hashing
        // Use keccak256 hash of packed inputs for pseudo-randomness
        bytes32 seed = keccak256(abi.encodePacked(
            _totalEnergySnapshot,
            _cosmicJitterSnapshot,
            _lastObservationTime,
            _currentTimestamp,
            block.difficulty, // Add some block data entropy
            block.number
        ));

        // Combine hash and inputs arithmetically, then apply influence factors and modulus
        uint256 rawState = uint256(seed);

        // Simple linear combination influenced by factors
        uint256 calculatedValue = (_totalEnergySnapshot.add(rawState.div(1e18).mul(jitterInfluenceFactor)).mul(rewardDistributionFactor)).div(1e18); // Example scaling

        // Apply modulus to keep state within bounds
        return calculatedValue % fluxStateModulus;
    }

    /**
     * @dev Calculates the potential entanglement score for a user based on current state.
     * This is a view function and does not alter state. The actual reward is based on this score at claim time.
     * The formula is conceptual: `(userEnergy * fluxState * rewardDistributionFactor) / totalEnergy`.
     * @param user The address of the user.
     * @return The calculated potential entanglement score.
     */
    function calculatePotentialEntanglementScore(address user) public view returns (uint256) {
        uint256 userEnergy = participantStates[user].contributedEnergy;
        if (userEnergy == 0 || totalEnergy == 0 || fluxStateModulus == 0) {
            return 0; // Cannot calculate score if no energy, no total, or no modulus
        }

        // Example score calculation: Scale user energy by flux state and distribution factor, normalized by total energy.
        // Use 1e18 scaling for factor precision
        // score = (userEnergy * fluxState * rewardDistributionFactor) / totalEnergy
        // To avoid overflow: score = (userEnergy * (fluxState.mul(rewardDistributionFactor) / 1e18)) / totalEnergy
        uint256 scaledFlux = fluxState.mul(rewardDistributionFactor) / 1e18;
        uint256 potentialScore = userEnergy.mul(scaledFlux) / totalEnergy;

        return potentialScore;
    }

    /**
     * @dev Calculates the potential ETH reward for a user based on their current entanglement score.
     * This is a view function.
     * @param user The address of the user.
     * @return The potential reward amount in wei.
     */
    function getPendingRewards(address user) public view returns (uint256) {
        uint256 potentialScore = calculatePotentialEntanglementScore(user);
        // reward = potentialScore * rewardRate
        uint256 potentialReward = potentialScore.mul(rewardRate) / 1e18; // Assuming rewardRate uses 1e18 scaling

        // Cap potential reward by available ETH balance in the contract
        return potentialReward > address(this).balance ? address(this).balance : potentialReward;
    }

    /**
     * @dev Allows a user to claim their calculated ETH rewards based on their current entanglement score.
     * The score used for claiming is calculated at the moment of this function call based on the current state.
     */
    function claimRewards() external whenNotPaused nonReentrant {
        uint256 rewardAmount = getPendingRewards(msg.sender);

        if (rewardAmount == 0) {
            revert NoRewardsPending();
        }
        if (address(this).balance < rewardAmount) {
             // Should not happen if getPendingRewards caps correctly, but as a safeguard
            rewardAmount = address(this).balance;
            if (rewardAmount == 0) revert NoRewardsPending();
        }

        // Send rewards
        // Use call for sending ETH, recommended over transfer/send for custom gas stipends
        (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
        require(success, "ETH transfer failed");

        // Note: The entanglement score is ephemeral. Claiming consumes the *opportunity* derived from
        // the current state and the user's contribution *at this moment*. There's no 'pending score' state variable
        // that needs resetting, as the calculation always happens on the fly.
        // If we wanted a more complex model where claiming locks in a specific reward amount
        // based on state at last interaction, the ParticipantState struct would need more fields.
        // For this model, claiming simply realizes the value derived from the current dynamic state.

        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    // --- Keeper System Functions ---

    /**
     * @dev Registers an address as a keeper. Callable only by owner.
     * @param keeperAddress The address to register as a keeper.
     */
    function registerKeeper(address keeperAddress) external onlyOwner {
        if (keeperAddress == address(0)) revert ZeroAddress();
        if (!_isKeeper[keeperAddress]) {
            _isKeeper[keeperAddress] = true;
            _keepers.push(keeperAddress); // Adding to array - potential gas concern if many keepers
            emit KeeperRegistered(keeperAddress);
        }
    }

    /**
     * @dev Unregisters a keeper address. Callable only by owner.
     * @param keeperAddress The address to unregister.
     */
    function unregisterKeeper(address keeperAddress) external onlyOwner {
        if (keeperAddress == address(0)) revert ZeroAddress();
        if (_isKeeper[keeperAddress]) {
            _isKeeper[keeperAddress] = false;
            // Removing from array is gas intensive for large arrays.
            // A better pattern for large lists is to use a mapping and iterate off-chain,
            // or implement a swap-and-pop if order doesn't matter (complex with arbitrary removal).
            // For a potentially small list of keepers, simple iteration to find and remove is OK.
            // Let's stick to mapping + simple check for keeper status for gas efficiency in calls.
            // The _keepers array is less critical for on-chain logic. If needed, iterate it off-chain.
            // Simple state update is enough for on-chain checks.
            emit KeeperUnregistered(keeperAddress);
        }
    }

    /**
     * @dev Allows a registered keeper to claim their accumulated rewards for triggering observations.
     */
    function claimKeeperReward() external nonReentrant {
        if (!_isKeeper[msg.sender]) revert NotKeeperOrOwner(); // Ensure caller is a registered keeper

        uint256 rewardAmount = keeperRewards[msg.sender];

        if (rewardAmount == 0) {
            revert NoKeeperRewardsPending();
        }
        if (address(this).balance < rewardAmount) {
             // Should not happen often but safety check
            rewardAmount = address(this).balance;
            if (rewardAmount == 0) revert NoKeeperRewardsPending();
        }


        keeperRewards[msg.sender] = 0; // Reset reward balance

        (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
        require(success, "Keeper ETH transfer failed");

        emit KeeperRewardClaimed(msg.sender, rewardAmount);
    }

    // --- Admin/Owner Functions ---

    /**
     * @dev Pauses the protocol, stopping core user interactions. Callable only by owner.
     */
    function pauseProtocol() external onlyOwner {
        _pause();
        emit ProtocolPaused(msg.sender);
    }

    /**
     * @dev Unpauses the protocol, re-enabling core user interactions. Callable only by owner.
     */
    function unpauseProtocol() external onlyOwner {
        _unpause();
        emit ProtocolUnpaused(msg.sender);
    }

    /**
     * @dev Allows the owner to rescue accidentally sent ERC20 tokens (excluding the energy token).
     * @param tokenAddress The address of the ERC20 token to rescue.
     * @param amount The amount of tokens to rescue.
     */
    function rescueERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0)) revert ZeroAddress();
        if (tokenAddress == address(energyToken)) revert CannotRescueEnergyToken();
        if (amount == 0) revert ZeroAmount();
        if (msg.sender == address(this)) revert SelfAddressNotAllowed(); // Prevent sending to self

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        uint256 amountToTransfer = amount > balance ? balance : amount;

        if (amountToTransfer == 0) return;

        bool success = token.transfer(msg.sender, amountToTransfer);
        require(success, "Token rescue failed");

        emit ERC20Rescued(tokenAddress, msg.sender, amountToTransfer);
    }

     /**
     * @dev Sets the address of the cosmic jitter oracle. Callable only by owner.
     * @param _newOracle The new oracle address.
     */
    function setJitterOracleAddress(address _newOracle) external onlyOwner {
        if (_newOracle == address(0)) revert ZeroAddress();
        address oldOracle = jitterOracleAddress;
        jitterOracleAddress = _newOracle;
        emit ParametersUpdated("JitterOracleAddress", uint256(uint160(oldOracle)), uint256(uint160(_newOracle)));
    }

    /**
     * @dev Sets the minimum observation interval for the flux state. Callable only by owner.
     * @param _newInterval The new minimum interval in seconds.
     */
    function setObservationInterval(uint256 _newInterval) external onlyOwner {
        if (_newInterval == 0) revert ZeroAmount();
        uint256 oldInterval = observationInterval;
        observationInterval = _newInterval;
        emit ParametersUpdated("ObservationInterval", oldInterval, _newInterval);
    }

    /**
     * @dev Sets the factor influencing the cosmic jitter's effect on the flux state. Callable only by owner.
     * @param _newFactor The new influence factor (e.g., 1e18 for 1:1 influence).
     */
    function setJitterInfluenceFactor(uint256 _newFactor) external onlyOwner {
        uint256 oldFactor = jitterInfluenceFactor;
        jitterInfluenceFactor = _newFactor;
        emit ParametersUpdated("JitterInfluenceFactor", oldFactor, _newFactor);
    }

    /**
     * @dev Sets the rate converting entanglement score to ETH reward. Callable only by owner.
     * @param _newRate The new reward rate (e.g., 1e15 for 0.001 ETH per score point).
     */
    function setRewardRate(uint256 _newRate) external onlyOwner {
        uint256 oldRate = rewardRate;
        rewardRate = _newRate;
        emit ParametersUpdated("RewardRate", oldRate, _newRate);
    }

     /**
     * @dev Sets the factor scaling the entanglement score calculation. Callable only by owner.
     * @param _newFactor The new distribution factor (e.g., 1e18).
     */
    function setRewardDistributionFactor(uint256 _newFactor) external onlyOwner {
        uint256 oldFactor = rewardDistributionFactor;
        rewardDistributionFactor = _newFactor;
        emit ParametersUpdated("RewardDistributionFactor", oldFactor, _newFactor);
    }

    /**
     * @dev Sets the modulus for the flux state calculation. Callable only by owner.
     * @param _newModulus The new modulus.
     */
    function setFluxStateModulus(uint256 _newModulus) external onlyOwner {
         if (_newModulus == 0) revert ZeroAmount(); // Modulus cannot be zero
        uint256 oldModulus = fluxStateModulus;
        fluxStateModulus = _newModulus;
        emit ParametersUpdated("FluxStateModulus", oldModulus, _newModulus);
    }

    /**
     * @dev Sets the ETH reward amount paid to a keeper for successfully triggering an observation. Callable only by owner.
     * @param _rewardAmount The new reward amount in wei.
     */
    function setKeeperRewardPerUpdate(uint256 _rewardAmount) external onlyOwner {
        uint256 oldAmount = keeperRewardPerUpdate;
        keeperRewardPerUpdate = _rewardAmount;
        emit ParametersUpdated("KeeperRewardPerUpdate", oldAmount, _rewardAmount);
    }

     /**
     * @dev Sets the minimum amount of Energy token required for a contribution. Callable only by owner.
     * @param _minimum The new minimum amount.
     */
    function setMinimumEnergyContribution(uint256 _minimum) external onlyOwner {
        uint256 oldMinimum = minimumEnergyContribution;
        minimumEnergyContribution = _minimum;
        emit ParametersUpdated("MinimumEnergyContribution", oldMinimum, _minimum);
    }

    // --- View Functions ---

    /**
     * @dev Returns the current flux state.
     */
    function getLatestFluxState() external view returns (uint256) {
        return fluxState;
    }

     /**
     * @dev Returns the timestamp of the last state observation.
     */
    function getLastStateObservationTime() external view returns (uint256) {
        return lastStateObservationTime;
    }

    /**
     * @dev Returns the total amount of FluxEnergy contributed to the protocol.
     */
    function getTotalEnergy() external view returns (uint256) {
        return totalEnergy;
    }

    /**
     * @dev Returns the amount of FluxEnergy contributed by a specific user.
     * @param user The address of the user.
     */
    function getParticipantState(address user) external view returns (uint256 contributedEnergy) {
        return participantStates[user].contributedEnergy;
    }

     /**
     * @dev Returns the latest cosmic jitter value received from the oracle.
     */
    function getCosmicJitterValue() external view returns (uint256) {
        return cosmicJitterValue;
    }

    /**
     * @dev Returns the address configured as the cosmic jitter oracle.
     */
    function getJitterOracleAddress() external view returns (address) {
        return jitterOracleAddress;
    }

     /**
     * @dev Checks if an address is a registered keeper.
     * @param _address The address to check.
     */
    function isKeeper(address _address) external view returns (bool) {
        return _isKeeper[_address];
    }

    /**
     * @dev Returns the accumulated pending rewards for a specific keeper.
     * @param keeper The address of the keeper.
     */
    function getKeeperRewardAmount(address keeper) external view returns (uint256) {
        return keeperRewards[keeper];
    }

     /**
     * @dev Returns the current ETH balance of the protocol (available for rewards).
     */
    function getProtocolBalance() external view returns (uint256) {
        return address(this).balance;
    }

     /**
     * @dev Returns the current balance of the FluxEnergy token held by the protocol.
     */
    function getEnergyTokenBalance() external view returns (uint256) {
        return energyToken.balanceOf(address(this));
    }

     /**
     * @dev Returns the minimum energy contribution required.
     */
    function getMinimumEnergyContribution() external view returns (uint256) {
        return minimumEnergyContribution;
    }

    // Helper function to get keeper list (handle carefully due to gas if list is large)
    // Using a mapping for on-chain checks is better. This is just for potential off-chain UI listing.
    // Function name indicates it's an internal-like view, might be restricted or removed in practice.
    // Exposing this directly could be problematic with very large keeper counts.
    // function _getKeepersList() external view returns (address[] memory) {
    //     return _keepers;
    // }

    // Get other parameters
    function getObservationInterval() external view returns (uint256) { return observationInterval; }
    function getJitterInfluenceFactor() external view returns (uint256) { return jitterInfluenceFactor; }
    function getRewardRate() external view returns (uint256) { return rewardRate; }
    function getRewardDistributionFactor() external view returns (uint256) { return rewardDistributionFactor; }
    function getFluxStateModulus() external view returns (uint256) { return fluxStateModulus; }
    function getKeeperRewardPerUpdate() external view returns (uint256) { return keeperRewardPerUpdate; }
}
```