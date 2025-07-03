```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
Contract Name: QuantumVault

Concept:
A smart contract acting as a metaphorical "Quantum Vault" that holds Ether and manages internal "Quantum Shards".
The vault's state is not fixed but exists in varying "quantum states" represented by parameters like flux, coherence, and entropy.
Interactions with the vault, such as depositing or withdrawing, and interactions with Shards,
can trigger probabilistic outcomes influenced by the current quantum state.
Owning and manipulating Shards provides users a way to influence the state and potentially improve chances for favorable vault interactions.
The contract incorporates advanced features like probabilistic outcomes based on deterministic on-chain factors,
interlinked asset states (Vault ETH balance <=> Shard balances <=> Quantum State parameters),
delegated conditional access, and unique interaction functions simulating state manipulation.
This design aims for creativity and avoids typical ERC-20/ERC-721/DeFi patterns by focusing on a novel interaction model.

Outline:
1. State Variables
2. Events
3. Modifiers
4. Structs
5. Admin Functions
6. Vault Interaction (ETH)
7. Quantum Shard Management
8. Quantum State Interaction
9. Delegation Functions
10. Information & Utility Functions

Function Summary:

Admin Functions:
- constructor(): Deploys the contract and sets the initial owner and quantum parameters.
- transferOwnership(): Transfers ownership of the contract.
- renounceOwnership(): Renounces ownership of the contract.
- setQuantumParameters(): Allows the owner to adjust base parameters affecting quantum state dynamics and probabilities.
- emergencyWithdrawETH(): Allows the owner to withdraw all ETH in emergencies.

Vault Interaction (ETH):
- depositETH(): Allows users to deposit ETH into the vault. Affects the vault's state parameters.
- withdrawETH(): Attempts to withdraw ETH. The success chance and exact amount are probabilistic, influenced by the current quantum state and Shard balance. Requires Shards to attempt.
- attemptQuantumTunnelingWithdraw(): A high-risk, low-probability withdrawal attempt that might succeed under specific, rare state conditions or with a significant Shard burn, potentially bypassing some normal withdrawal checks.

Quantum Shard Management:
- mineShards(): Allows users to 'mine' new Shards by interacting with the contract under specific conditions, potentially burning a small amount of ETH or requiring vault interaction history. State influences mining output.
- transferShards(): Allows users to transfer their Quantum Shards to another address internally.
- burnShards(): Allows users to destroy their Shards. Burning Shards influences the quantum state.
- shatterShards(): A function to deliberately break down a user's Shards, increasing state entropy but potentially yielding a temporary benefit or triggering a specific state transition.

Quantum State Interaction:
- observeState(): A view function to check the current quantum state parameters (fluxLevel, coherence, entropy).
- perturbState(): Users can attempt to 'perturb' the quantum state, causing random-ish fluctuations in parameters, potentially requiring Shards or a small ETH fee.
- stabilizeState(): Users can attempt to stabilize the state (increase coherence, decrease flux/entropy), requiring a Shard burn or locked ETH.
- induceDecoherence(): Users can attempt to increase state entropy, potentially useful for certain strategies, costing Shards or ETH.

Delegation Functions:
- delegateWithdrawalPermission(): Allows a user to grant another address permission to withdraw a specified maximum amount of their deposited ETH under specific state conditions.
- revokeDelegationPermission(): Revokes an existing delegation.
- delegatedWithdrawal(): The function called by a delegate to attempt a withdrawal on behalf of the delegator, checking permissions and state conditions.

Information & Utility Functions:
- getVaultETHBalance(): Returns the total ETH held in the vault contract.
- getMyShardBalance(): Returns the caller's Quantum Shard balance.
- getTotalShards(): Returns the total number of Quantum Shards in existence.
- getQuantumStateParameters(): Returns the current values of fluxLevel, coherence, and entropy.
- calculateWithdrawalProbability(): A view function estimating the probabilistic factors for withdrawal based on the current state *without* executing the attempt.
- predictStateChange(): A view function simulating the potential outcome of a state interaction function based on current parameters.
- getDelegationStatus(): Checks and returns the details of a delegation granted by a specific user to a specific delegate.
- calculateTunnelingProbability(): A view function estimating the probabilistic factors for a quantum tunneling withdrawal.
- getDepositCount(): Returns the number of deposits made by the caller.
*/

contract QuantumVault {
    // 1. State Variables
    address private _owner;

    struct QuantumState {
        uint256 fluxLevel; // Represents volatility/randomness. High flux = more unpredictable outcomes.
        uint256 coherence; // Represents stability/predictability. High coherence = more favorable outcomes for stabilization/withdrawal.
        uint256 entropy;   // Represents decay/disorder. High entropy = harder to stabilize, potentially easier to perturb or tunnel.
        uint256 lastInteractionTime; // Timestamp of the last state-changing interaction.
        uint256 totalInteractions; // Counter for state-changing interactions.
    }

    QuantumState public currentQuantumState;

    // Base parameters influencing state changes and probabilities - adjustable by owner
    struct BaseQuantumParams {
        uint256 baseFluxDecayRate;
        uint256 baseCoherenceDecayRate;
        uint256 baseEntropyIncreaseRate;
        uint256 depositCoherenceBoost;
        uint256 depositFluxIncrease;
        uint256 shardBurnStabilizeEffect; // How much burning shards helps stabilize
        uint256 shardBurnEntropyDecrease;
        uint256 perturbFluxBoost;
        uint256 perturbEntropyBoost;
        uint256 tunnelingBaseChance; // Base probability for tunneling (out of 100,000)
        uint256 withdrawalBaseChance; // Base probability for withdrawal (out of 100)
        uint256 withdrawalShardCostPerAttempt; // Shards required for a standard withdrawal attempt
        uint256 miningShardOutputBase; // Base shards mined per attempt
        uint256 miningETHBurnCost; // ETH cost to mine shards
    }

    BaseQuantumParams public baseParams;

    mapping(address => uint256) private _shardBalances;
    uint256 private _totalSupplyShards;

    // Delegation structure for conditional withdrawals
    struct WithdrawalDelegation {
        address delegate;
        uint256 maxAmount; // Maximum ETH amount allowed for withdrawal
        uint256 expiryTime; // Timestamp after which the delegation is invalid
        uint256 minCoherenceRequired; // Minimum coherence level required for delegate withdrawal
        bool active; // Is this delegation currently active
    }
    // Mapping: Delegator Address => Delegate Address => Delegation Details
    mapping(address => mapping(address => WithdrawalDelegation)) private _withdrawalDelegations;

    mapping(address => uint256) private _userDepositCount; // Track user deposits for mining bonus/prerequisites

    // Counter to ensure unique hashes for probabilistic outcomes
    uint256 private _nonce;

    // 2. Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ETHDeposited(address indexed user, uint256 amount, uint256 newCoherence, uint256 newFlux);
    event ETHWithdrawalAttempt(address indexed user, uint256 requestedAmount, uint256 currentFlux, uint256 currentCoherence, uint256 currentEntropy, bool success, uint256 withdrawnAmount);
    event ShardsMined(address indexed user, uint256 amount, uint256 newEntropy, uint256 newFlux);
    event ShardsTransferred(address indexed from, address indexed to, uint256 amount);
    event ShardsBurned(address indexed user, uint256 amount, uint256 newCoherence, uint256 newEntropy);
    event ShardsShattered(address indexed user, uint256 amount, uint256 newEntropy, uint256 newFlux);
    event StatePerturbed(uint256 oldFlux, uint256 newFlux, uint256 oldEntropy, uint256 newEntropy);
    event StateStabilized(uint256 oldCoherence, uint256 newCoherence, uint256 oldFlux, uint256 newFlux);
    event DecoherenceInduced(uint256 oldEntropy, uint256 newEntropy, uint256 oldCoherence, uint256 newCoherence);
    event QuantumStateChanged(uint256 newFlux, uint256 newCoherence, uint256 newEntropy, uint256 totalInteractions);
    event WithdrawalPermissionDelegated(address indexed delegator, address indexed delegate, uint256 maxAmount, uint256 expiryTime);
    event WithdrawalPermissionRevoked(address indexed delegator, address indexed delegate);
    event DelegatedWithdrawalAttempt(address indexed delegator, address indexed delegate, uint256 requestedAmount, bool success, uint256 withdrawnAmount);
    event QuantumTunnelingAttempt(address indexed user, uint256 requestedAmount, uint256 currentFlux, uint256 currentEntropy, bool success, uint256 withdrawnAmount);

    // 3. Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not the contract owner");
        _;
    }

    // 4. Structs (Defined above)

    // Internal function to update quantum state based on time decay
    function _decayQuantumState() private {
        uint256 timePassed = block.timestamp - currentQuantumState.lastInteractionTime;
        if (timePassed > 0) {
            // Simple linear decay/increase based on time and base rates
            currentQuantumState.fluxLevel = currentQuantumState.fluxLevel >= (baseParams.baseFluxDecayRate * timePassed) ? currentQuantumState.fluxLevel - (baseParams.baseFluxDecayRate * timePassed) : 0;
            currentQuantumState.coherence = currentQuantumState.coherence >= (baseParams.baseCoherenceDecayRate * timePassed) ? currentQuantumState.coherence - (baseParams.baseCoherenceDecayRate * timePassed) : 0;
            currentQuantumState.entropy += (baseParams.baseEntropyIncreaseRate * timePassed); // Entropy always increases with time
            currentQuantumState.lastInteractionTime = block.timestamp;
        }
        // Cap/floor parameters to prevent overflow/underflow or unrealistic values
        currentQuantumState.fluxLevel = currentQuantumState.fluxLevel > 100000 ? 100000 : currentQuantumState.fluxLevel;
        currentQuantumState.coherence = currentQuantumState.coherence > 100000 ? 100000 : currentQuantumState.coherence;
        currentQuantumState.entropy = currentQuantumState.entropy > 100000 ? 100000 : currentQuantumState.entropy;
    }

    // Internal function to generate a deterministic pseudorandom number
    function _pseudoRandom(uint256 max) private returns (uint256) {
        unchecked {
            _nonce++;
            // Mix block data, sender, state params, and a nonce for variability
            uint256 randomSeed = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                msg.sender,
                currentQuantumState.fluxLevel,
                currentQuantumState.coherence,
                currentQuantumState.entropy,
                currentQuantumState.totalInteractions,
                _nonce
            )));
            return randomSeed % max;
        }
    }

    // 5. Admin Functions
    constructor(
        uint256 initialBaseFluxDecayRate,
        uint256 initialBaseCoherenceDecayRate,
        uint256 initialBaseEntropyIncreaseRate,
        uint256 initialDepositCoherenceBoost,
        uint256 initialDepositFluxIncrease,
        uint256 initialShardBurnStabilizeEffect,
        uint256 initialShardBurnEntropyDecrease,
        uint256 initialPerturbFluxBoost,
        uint256 initialPerturbEntropyBoost,
        uint256 initialTunnelingBaseChance,
        uint256 initialWithdrawalBaseChance,
        uint256 initialWithdrawalShardCostPerAttempt,
        uint256 initialMiningShardOutputBase,
        uint256 initialMiningETHBurnCost
    ) {
        _owner = msg.sender;
        currentQuantumState = QuantumState({
            fluxLevel: 5000, // Start in a moderate state
            coherence: 5000,
            entropy: 5000,
            lastInteractionTime: block.timestamp,
            totalInteractions: 0
        });

        baseParams = BaseQuantumParams({
            baseFluxDecayRate: initialBaseFluxDecayRate,
            baseCoherenceDecayRate: initialBaseCoherenceDecayRate,
            baseEntropyIncreaseRate: initialBaseEntropyIncreaseRate,
            depositCoherenceBoost: initialDepositCoherenceBoost,
            depositFluxIncrease: initialDepositFluxIncrease,
            shardBurnStabilizeEffect: initialShardBurnStabilizeEffect,
            shardBurnEntropyDecrease: initialShardBurnEntropyDecrease,
            perturbFluxBoost: initialPerturbFluxBoost,
            perturbEntropyBoost: initialPerturbEntropyBoost,
            tunnelingBaseChance: initialTunnelingBaseChance, // e.g., 10 (0.01%) out of 100000
            withdrawalBaseChance: initialWithdrawalBaseChance, // e.g., 50 (50%) out of 100
            withdrawalShardCostPerAttempt: initialWithdrawalShardCostPerAttempt, // e.g., 100
            miningShardOutputBase: initialMiningShardOutputBase, // e.g., 10
            miningETHBurnCost: initialMiningETHBurnCost // e.g., 100000000000000 (0.0001 ETH)
        });
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /// @notice Renounces ownership of the contract. Cannot be undone.
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /// @notice Allows the owner to adjust base parameters affecting quantum state dynamics and probabilities.
    /// @param _params The new BaseQuantumParams struct.
    function setQuantumParameters(BaseQuantumParams calldata _params) public onlyOwner {
        baseParams = _params;
    }

    /// @notice Allows the owner to withdraw all ETH from the contract in case of emergency.
    function emergencyWithdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "ETH withdrawal failed");
    }

    // 6. Vault Interaction (ETH)
    /// @notice Allows users to deposit ETH into the vault. Affects the vault's quantum state.
    function depositETH() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _decayQuantumState(); // Apply time decay before state change
        currentQuantumState.coherence += baseParams.depositCoherenceBoost;
        currentQuantumState.fluxLevel += baseParams.depositFluxIncrease;
        currentQuantumState.totalInteractions++;
        _userDepositCount[msg.sender]++;

        emit ETHDeposited(msg.sender, msg.value, currentQuantumState.coherence, currentQuantumState.fluxLevel);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    /// @notice Attempts to withdraw ETH. The success chance and exact amount are probabilistic, influenced by the current quantum state and Shard balance. Requires Shards to attempt.
    /// @param amount The desired amount of ETH to withdraw.
    function withdrawETH(uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        require(_shardBalances[msg.sender] >= baseParams.withdrawalShardCostPerAttempt, "Not enough Shards for withdrawal attempt");

        _decayQuantumState(); // Apply time decay

        // Probability calculation based on state and a pseudo-random factor
        uint256 probabilityBasis = _pseudoRandom(10000); // 0-9999
        uint256 stateInfluence = (currentQuantumState.coherence / 100) - (currentQuantumState.fluxLevel / 200) - (currentQuantumState.entropy / 300); // Coherence helps, Flux/Entropy hurt
        stateInfluence = stateInfluence > 0 ? stateInfluence : 0; // Only positive influence
        uint256 shardInfluence = (_shardBalances[msg.sender] / baseParams.withdrawalShardCostPerAttempt) * 5; // Shards provide a small bonus chance (5% per shard attempt cost unit)
        shardInfluence = shardInfluence > 50 ? 50 : shardInfluence; // Cap shard influence

        uint256 effectiveChance = baseParams.withdrawalBaseChance + stateInfluence + shardInfluence; // Out of 100
        effectiveChance = effectiveChance > 100 ? 100 : effectiveChance; // Cap chance at 100%

        bool success = probabilityBasis < (effectiveChance * 100); // Convert percentage chance to basis points

        uint256 withdrawnAmount = 0;
        if (success) {
            // Amount fluctuation based on state entropy and coherence
            uint256 amountFluctuationFactor = _pseudoRandom(1000); // 0-999
            int256 stateAmountModifier = int256((currentQuantumState.coherence / 200)) - int256((currentQuantumState.entropy / 100)); // Coherence adds, Entropy subtracts
            stateAmountModifier = stateAmountModifier > int256(amount) ? int252(amount) : stateAmountModifier; // Cap modifier

            uint256 finalAmountBasis = uint256(int256(amount) + stateAmountModifier);
            finalAmountBasis = finalAmountBasis > (amount * 2) ? (amount * 2) : finalAmountBasis; // Cap bonus amount
            finalAmountBasis = finalAmountBasis < (amount / 2) ? (amount / 2) : finalAmountBasis; // Floor amount

            // Apply fluctuation factor
            withdrawenAmount = (finalAmountBasis * (1000 + (amountFluctuationFactor - 500))) / 1000; // +/- 50% fluctuation around modified amount
            withdrawenAmount = withdrawenAmount > amount ? amount : withdrawenAmount; // Ensure not withdrawing more than requested (or requested max if less than calculated)
            withdrawenAmount = withdrawenAmount > address(this).balance ? address(this).balance : withdrawenAmount; // Ensure not withdrawing more than balance

            (bool ethSent, ) = payable(msg.sender).call{value: withdrawenAmount}("");
            require(ethSent, "ETH transfer failed during withdrawal");

            // Successful withdrawal affects state - usually increases entropy and flux slightly
            currentQuantumState.entropy += currentQuantumState.fluxLevel / 100;
            currentQuantumState.fluxLevel += 50; // Small flux increase
        }

        // Always burn shards on attempt, regardless of success
        _shardBalances[msg.sender] -= baseParams.withdrawalShardCostPerAttempt;
        _totalSupplyShards -= baseParams.withdrawalShardCostPerAttempt;

        currentQuantumState.totalInteractions++;
        emit ETHWithdrawalAttempt(msg.sender, amount, currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, success, withdrawnAmount);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    /// @notice A high-risk, low-probability withdrawal attempt that might succeed under specific, rare state conditions or with a significant Shard burn, potentially bypassing some normal withdrawal checks.
    /// @param amount The desired amount of ETH to withdraw.
    /// @param shardsToBurn The amount of Shards to burn for this attempt (higher burn increases chance).
    function attemptQuantumTunnelingWithdraw(uint256 amount, uint256 shardsToBurn) public {
        require(amount > 0, "Tunneling amount must be greater than 0");
        require(address(this).balance >= amount, "Insufficient contract balance");
        require(_shardBalances[msg.sender] >= shardsToBurn, "Not enough Shards to burn for tunneling");
        require(shardsToBurn > 0, "Must burn some Shards for tunneling");

        _decayQuantumState(); // Apply time decay

        // Tunneling probability calculation - very sensitive to state and shard burn
        uint256 probabilityBasis = _pseudoRandom(100000); // Basis 1 in 100,000
        // Tunneling is easier with high flux and entropy, harder with high coherence
        int256 stateInfluence = int256(currentQuantumState.fluxLevel / 50) + int256(currentQuantumState.entropy / 50) - int256(currentQuantumState.coherence / 100);
        stateInfluence = stateInfluence > -10000 ? stateInfluence : -10000; // Cap negative influence

        uint256 shardInfluence = shardsToBurn / 10; // 1% bonus chance per 10 shards burned
        shardInfluence = shardInfluence > 10000 ? 10000 : shardInfluence; // Cap shard influence at 100% effective bonus

        uint256 effectiveChanceBasis = baseParams.tunnelingBaseChance + (stateInfluence > 0 ? uint256(stateInfluence) : 0) + shardInfluence; // Add positive influences
        effectiveChanceBasis = effectiveChanceBasis > 100000 ? 100000 : effectiveChanceBasis; // Cap at 100% basis

        bool success = probabilityBasis < effectiveChanceBasis;

        uint256 withdrawnAmount = 0;
        if (success) {
             withdrawenAmount = amount > address(this).balance ? address(this).balance : amount; // Cannot withdraw more than contract holds

            (bool ethSent, ) = payable(msg.sender).call{value: withdrawenAmount}("");
            require(ethSent, "ETH transfer failed during tunneling");

            // Successful tunneling drastically affects state - high flux, high entropy, low coherence
            currentQuantumState.fluxLevel += amount / 1 ether * 1000; // Flux increases based on amount
            currentQuantumState.entropy += shardsToBurn / 20; // Entropy increases based on shards burned
            currentQuantumState.coherence = currentQuantumState.coherence >= (amount / 1 ether * 500) ? currentQuantumState.coherence - (amount / 1 ether * 500) : 0; // Coherence decreases
        } else {
            // Failed tunneling also affects state - increases entropy, might decrease coherence slightly
             currentQuantumState.entropy += shardsToBurn / 50; // Entropy increases slightly
             currentQuantumState.coherence = currentQuantumState.coherence >= 10 ? currentQuantumState.coherence - 10 : 0; // Small coherence decrease
        }

        // Always burn shards on attempt
        _shardBalances[msg.sender] -= shardsToBurn;
        _totalSupplyShards -= shardsToBurn;

        currentQuantumState.totalInteractions++;
        emit QuantumTunnelingAttempt(msg.sender, amount, currentQuantumState.fluxLevel, currentQuantumState.entropy, success, withdrawnAmount);
        emit ShardsBurned(msg.sender, shardsToBurn, currentQuantumState.coherence, currentQuantumState.entropy);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    // 7. Quantum Shard Management
    /// @notice Allows users to 'mine' new Shards by interacting with the contract. Requires burning a small amount of ETH. State influences mining output.
    function mineShards() public payable {
         require(msg.value >= baseParams.miningETHBurnCost, "Insufficient ETH sent to cover mining cost");

        _decayQuantumState(); // Apply time decay

        // Amount of shards mined is base + influence from state
        uint256 stateInfluence = (currentQuantumState.fluxLevel / 200) + (currentQuantumState.entropy / 300); // Flux & Entropy can help mining
        stateInfluence = stateInfluence > 50 ? 50 : stateInfluence; // Cap state influence on mining

        uint256 userHistoryBonus = _userDepositCount[msg.sender] / 10; // Users who deposited more get slight bonus
        userHistoryBonus = userHistoryBonus > 20 ? 20 : userHistoryBonus; // Cap history bonus

        uint256 minedAmount = baseParams.miningShardOutputBase + stateInfluence + userHistoryBonus;
        minedAmount = minedAmount > 0 ? minedAmount : 1; // Ensure at least 1 shard is mined

        _shardBalances[msg.sender] += minedAmount;
        _totalSupplyShards += minedAmount;

        // Mining affects state - usually increases entropy and flux slightly
        currentQuantumState.entropy += minedAmount / 5;
        currentQuantumState.fluxLevel += minedAmount / 10;
        currentQuantumState.totalInteractions++;

        // Return excess ETH if any
        if (msg.value > baseParams.miningETHBurnCost) {
            (bool sent, ) = payable(msg.sender).call{value: msg.value - baseParams.miningETHBurnCost}("");
            require(sent, "Failed to return excess ETH");
        }

        emit ShardsMined(msg.sender, minedAmount, currentQuantumState.entropy, currentQuantumState.fluxLevel);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    /// @notice Allows users to transfer their Quantum Shards to another address internally.
    /// @param recipient The address to transfer Shards to.
    /// @param amount The amount of Shards to transfer.
    function transferShards(address recipient, uint256 amount) public {
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(recipient != msg.sender, "Cannot transfer to yourself");
        require(_shardBalances[msg.sender] >= amount, "Insufficient Shard balance");

        _shardBalances[msg.sender] -= amount;
        _shardBalances[recipient] += amount;

        // Shard transfer does not directly affect core state parameters, but counts as an interaction
        _decayQuantumState(); // Apply time decay before interaction count
        currentQuantumState.totalInteractions++;

        emit ShardsTransferred(msg.sender, recipient, amount);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    /// @notice Allows users to destroy their Shards. Burning Shards influences the quantum state positively (increases coherence, decreases entropy).
    /// @param amount The amount of Shards to burn.
    function burnShards(uint256 amount) public {
        require(amount > 0, "Burn amount must be greater than 0");
        require(_shardBalances[msg.sender] >= amount, "Insufficient Shard balance to burn");

        _shardBalances[msg.sender] -= amount;
        _totalSupplyShards -= amount;

        _decayQuantumState(); // Apply time decay

        // Burning shards increases coherence and decreases entropy
        currentQuantumState.coherence += baseParams.shardBurnStabilizeEffect * (amount / 10); // Effect scales with amount burned
        currentQuantumState.entropy = currentQuantumState.entropy >= (baseParams.shardBurnEntropyDecrease * (amount / 5)) ? currentQuantumState.entropy - (baseParams.shardBurnEntropyDecrease * (amount / 5)) : 0; // Entropy decreases

        currentQuantumState.totalInteractions++;

        emit ShardsBurned(msg.sender, amount, currentQuantumState.coherence, currentQuantumState.entropy);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    /// @notice A function to deliberately break down a user's Shards, increasing state entropy but potentially yielding a temporary benefit or triggering a specific state transition.
    /// @param amount The amount of Shards to shatter.
    function shatterShards(uint256 amount) public {
        require(amount > 0, "Shatter amount must be greater than 0");
        require(_shardBalances[msg.sender] >= amount, "Insufficient Shard balance to shatter");

        _shardBalances[msg.sender] -= amount;
        _totalSupplyShards -= amount;

        _decayQuantumState(); // Apply time decay

        // Shattering shards drastically increases entropy and flux
        currentQuantumState.entropy += amount * 2; // High entropy increase
        currentQuantumState.fluxLevel += amount; // Flux increase
        currentQuantumState.coherence = currentQuantumState.coherence >= (amount / 5) ? currentQuantumState.coherence - (amount / 5) : 0; // Coherence decreases slightly

        currentQuantumState.totalInteractions++;

        // Could add a temporary "shatter effect" bonus here if desired, e.g., increased mining output for a short period, or a higher chance for a subsequent state perturbation. (Left out for brevity, but possible).

        emit ShardsShattered(msg.sender, amount, currentQuantumState.entropy, currentQuantumState.fluxLevel);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }


    // 8. Quantum State Interaction
    /// @notice A view function to check the current quantum state parameters (fluxLevel, coherence, entropy).
    /// @return flux The current flux level.
    /// @return coherence The current coherence level.
    /// @return entropy The current entropy level.
    function observeState() public view returns (uint256 flux, uint256 coherence, uint256 entropy) {
        // Note: This view function doesn't apply decay before returning, so state might be slightly different after a state-changing transaction.
        return (currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy);
    }

    /// @notice Users can attempt to 'perturb' the quantum state, causing random-ish fluctuations in parameters. Requires a small ETH fee.
    function perturbState() public payable {
        // Could add a cost here if desired, e.g., require(msg.value >= someCost, "Insufficient ETH for perturbation");
        // Or require Shards: require(_shardBalances[msg.sender] >= someShardCost, "Need shards to perturb");

        _decayQuantumState(); // Apply time decay

        uint256 randomFactor = _pseudoRandom(1000); // 0-999

        // Perturbation effect influenced by current state and random factor
        int256 fluxChange = int256((currentQuantumState.fluxLevel / 10) - 50 + (randomFactor - 500) / 10);
        int256 coherenceChange = int256((currentQuantumState.coherence / 10) - 50 + (randomFactor - 500) / 10);
        int256 entropyChange = int256((currentQuantumState.entropy / 10) - 50 + (randomFactor - 500) / 10);

        // Apply changes, ensuring non-negative values
        currentQuantumState.fluxLevel = fluxChange >= 0 ? currentQuantumState.fluxLevel + uint256(fluxChange) : currentQuantumState.fluxLevel >= uint256(-fluxChange) ? currentQuantumState.fluxLevel - uint256(-fluxChange) : 0;
        currentQuantumState.coherence = coherenceChange >= 0 ? currentQuantumState.coherence + uint256(coherenceChange) : currentQuantumState.coherence >= uint256(-coherenceChange) ? currentQuantumState.coherence - uint256(-coherenceChange) : 0;
        currentQuantumState.entropy = entropyChange >= 0 ? currentQuantumState.entropy + uint256(entropyChange) : currentQuantumState.entropy >= uint256(-entropyChange) ? currentQuantumState.entropy - uint256(-entropyChange) : 0;

         // Add a base perturb effect defined by owner
        currentQuantumState.fluxLevel += baseParams.perturbFluxBoost;
        currentQuantumState.entropy += baseParams.perturbEntropyBoost;
        currentQuantumState.coherence = currentQuantumState.coherence >= 10 ? currentQuantumState.coherence - 10 : 0; // Perturb reduces coherence

        // Cap/floor parameters
        currentQuantumState.fluxLevel = currentQuantumState.fluxLevel > 100000 ? 100000 : currentQuantumState.fluxLevel;
        currentQuantumState.coherence = currentQuantumState.coherence > 100000 ? 100000 : currentQuantumState.coherence;
        currentQuantumState.entropy = currentQuantumState.entropy > 100000 ? 100000 : currentQuantumState.entropy;


        currentQuantumState.totalInteractions++;

        emit StatePerturbed(currentQuantumState.fluxLevel - (baseParams.perturbFluxBoost), currentQuantumState.fluxLevel, currentQuantumState.entropy - (baseParams.perturbEntropyBoost), currentQuantumState.entropy); // Approx old values
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    /// @notice Users can attempt to stabilize the state (increase coherence, decrease flux/entropy). Requires burning Shards or locking ETH (not implemented, but possible).
    function stabilizeState() public {
        require(_shardBalances[msg.sender] > 0, "Must have Shards to attempt stabilization"); // Requires Shards

        _decayQuantumState(); // Apply time decay

        uint256 shardsToUse = _shardBalances[msg.sender] / 10 > 1 ? _shardBalances[msg.sender] / 10 : 1; // Use 10% of shards, minimum 1

        // Stabilization effect scaled by shards used and current state
        uint256 coherenceBoost = baseParams.shardBurnStabilizeEffect * shardsToUse / 10;
        uint256 fluxDecrease = currentQuantumState.fluxLevel / 100 > 10 ? currentQuantumState.fluxLevel / 100 : 10; // Effect based on current flux
        uint256 entropyDecrease = currentQuantumState.entropy / 100 > 10 ? currentQuantumState.entropy / 100 : 10; // Effect based on current entropy

        currentQuantumState.coherence += coherenceBoost;
        currentQuantumState.fluxLevel = currentQuantumState.fluxLevel >= fluxDecrease ? currentQuantumState.fluxLevel - fluxDecrease : 0;
        currentQuantumState.entropy = currentQuantumState.entropy >= entropyDecrease ? currentQuantumState.entropy - entropyDecrease : 0;

        // Burning the shards used for stabilization
         _shardBalances[msg.sender] -= shardsToUse;
        _totalSupplyShards -= shardsToUse;


        // Cap/floor parameters
        currentQuantumState.fluxLevel = currentQuantumState.fluxLevel > 100000 ? 100000 : currentQuantumState.fluxLevel;
        currentQuantumState.coherence = currentQuantumState.coherence > 100000 ? 100000 : currentQuantumState.coherence;
        currentQuantumState.entropy = currentQuantumState.entropy > 100000 ? 100000 : currentQuantumState.entropy;


        currentQuantumState.totalInteractions++;
        emit StateStabilized(currentQuantumState.coherence - coherenceBoost, currentQuantumState.coherence, currentQuantumState.fluxLevel + fluxDecrease, currentQuantumState.fluxLevel); // Approx old values
        emit ShardsBurned(msg.sender, shardsToUse, currentQuantumState.coherence, currentQuantumState.entropy);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

     /// @notice Users can attempt to increase state entropy, potentially useful for certain strategies.
     /// @param amount The amount of entropy units to try and induce.
    function induceDecoherence(uint256 amount) public {
         require(amount > 0, "Amount must be greater than 0");
         require(_shardBalances[msg.sender] >= amount/10, "Requires Shards to induce Decoherence"); // Costs Shards

        _decayQuantumState(); // Apply time decay

        uint256 shardsToUse = amount / 10;
        if (shardsToUse == 0 && amount > 0) shardsToUse = 1; // Minimum 1 shard cost if amount > 0
         require(_shardBalances[msg.sender] >= shardsToUse, "Requires Shards to induce Decoherence");

        uint256 entropyIncrease = amount;
        uint256 coherenceDecrease = amount / 2; // Costs coherence

        currentQuantumState.entropy += entropyIncrease;
        currentQuantumState.coherence = currentQuantumState.coherence >= coherenceDecrease ? currentQuantumState.coherence - coherenceDecrease : 0;

        _shardBalances[msg.sender] -= shardsToUse;
        _totalSupplyShards -= shardsToUse;

         // Cap/floor parameters
        currentQuantumState.fluxLevel = currentQuantumState.fluxLevel > 100000 ? 100000 : currentQuantumState.fluxLevel;
        currentQuantumState.coherence = currentQuantumState.coherence > 100000 ? 100000 : currentQuantumState.coherence;
        currentQuantumState.entropy = currentQuantumState.entropy > 100000 ? 100000 : currentQuantumState.entropy;

        currentQuantumState.totalInteractions++;
        emit DecoherenceInduced(currentQuantumState.entropy - entropyIncrease, currentQuantumState.entropy, currentQuantumState.coherence + coherenceDecrease, currentQuantumState.coherence); // Approx old values
        emit ShardsBurned(msg.sender, shardsToUse, currentQuantumState.coherence, currentQuantumState.entropy);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    // 9. Delegation Functions
    /// @notice Allows a user to grant another address permission to withdraw a specified maximum amount of their deposited ETH under specific state conditions.
    /// @param delegate The address to grant permission to.
    /// @param maxAmount The maximum ETH amount the delegate can withdraw on behalf of the delegator.
    /// @param expiryTime The timestamp after which the delegation is invalid.
    /// @param minCoherenceRequired Minimum coherence level required for delegate withdrawal.
    function delegateWithdrawalPermission(address delegate, uint256 maxAmount, uint256 expiryTime, uint256 minCoherenceRequired) public {
        require(delegate != address(0), "Cannot delegate to the zero address");
        require(delegate != msg.sender, "Cannot delegate to yourself");
        require(expiryTime > block.timestamp, "Expiry time must be in the future");
        require(maxAmount > 0, "Max amount must be greater than 0");

        _withdrawalDelegations[msg.sender][delegate] = WithdrawalDelegation({
            delegate: delegate,
            maxAmount: maxAmount,
            expiryTime: expiryTime,
            minCoherenceRequired: minCoherenceRequired,
            active: true
        });

        emit WithdrawalPermissionDelegated(msg.sender, delegate, maxAmount, expiryTime);
    }

    /// @notice Revokes an existing delegation.
    /// @param delegate The address whose permission is to be revoked.
    function revokeDelegationPermission(address delegate) public {
        require(delegate != address(0), "Invalid delegate address");
        WithdrawalDelegation storage delegation = _withdrawalDelegations[msg.sender][delegate];
        require(delegation.active, "Delegation does not exist or is not active");

        delete _withdrawalDelegations[msg.sender][delegate]; // Simply remove the entry
        // Or set active = false: delegation.active = false;

        emit WithdrawalPermissionRevoked(msg.sender, delegate);
    }

    /// @notice The function called by a delegate to attempt a withdrawal on behalf of the delegator, checking permissions and state conditions.
    /// @param delegator The address who granted the permission.
    /// @param amount The amount of ETH to withdraw (cannot exceed the max allowed in delegation).
    function delegatedWithdrawal(address delegator, uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        WithdrawalDelegation storage delegation = _withdrawalDelegations[delegator][msg.sender];

        require(delegation.active, "Delegation is not active");
        require(delegation.delegate == msg.sender, "Not authorized to act as this delegate");
        require(delegation.expiryTime > block.timestamp, "Delegation has expired");
        require(amount <= delegation.maxAmount, "Attempted amount exceeds delegated maximum");

         _decayQuantumState(); // Apply time decay

        require(currentQuantumState.coherence >= delegation.minCoherenceRequired, "Current coherence level is too low for this delegation");

        // Delegated withdrawal success is NOT probabilistic like normal withdrawal.
        // It depends only on delegation validity and state conditions.
        // Amount is fixed by the request (up to max).

        uint256 withdrawable = amount > address(this).balance ? address(this).balance : amount; // Cannot withdraw more than contract holds

        // Update delegation details for remaining amount
        delegation.maxAmount -= withdrawable;

        (bool ethSent, ) = payable(delegator).call{value: withdrawable}("");
        require(ethSent, "ETH transfer failed during delegated withdrawal");

        // Delegated withdrawal affects state - increases entropy and flux slightly
        currentQuantumState.entropy += 10;
        currentQuantumState.fluxLevel += 20;
         currentQuantumState.totalInteractions++;


        emit DelegatedWithdrawalAttempt(delegator, msg.sender, amount, true, withdrawable);
        emit QuantumStateChanged(currentQuantumState.fluxLevel, currentQuantumState.coherence, currentQuantumState.entropy, currentQuantumState.totalInteractions);
    }

    // 10. Information & Utility Functions

    /// @notice Returns the total ETH held in the vault contract.
    /// @return The current balance of the contract.
    function getVaultETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the caller's Quantum Shard balance.
    /// @return The caller's shard balance.
    function getMyShardBalance() public view returns (uint256) {
        return _shardBalances[msg.sender];
    }

    /// @notice Returns the total number of Quantum Shards in existence.
    /// @return The total supply of shards.
    function getTotalShards() public view returns (uint256) {
        return _totalSupplyShards;
    }

    /// @notice Returns the current values of fluxLevel, coherence, and entropy.
    /// @return flux The current flux level.
    /// @return coherence The current coherence level.
    /// @return entropy The current entropy level.
    function getQuantumStateParameters() public view returns (uint256 flux, uint256 coherence, uint256 entropy) {
         // Apply *simulated* time decay for the view function to give a more current estimate
        uint256 timePassed = block.timestamp - currentQuantumState.lastInteractionTime;
        uint256 simulatedFlux = currentQuantumState.fluxLevel >= (baseParams.baseFluxDecayRate * timePassed) ? currentQuantumState.fluxLevel - (baseParams.baseFluxDecayRate * timePassed) : 0;
        uint256 simulatedCoherence = currentQuantumState.coherence >= (baseParams.baseCoherenceDecayRate * timePassed) ? currentQuantumState.coherence - (baseParams.baseCoherenceDecayRate * timePassed) : 0;
        uint256 simulatedEntropy = currentQuantumState.entropy + (baseParams.baseEntropyIncreaseRate * timePassed);

        simulatedFlux = simulatedFlux > 100000 ? 100000 : simulatedFlux;
        simulatedCoherence = simulatedCoherence > 100000 ? 100000 : simulatedCoherence;
        simulatedEntropy = simulatedEntropy > 100000 ? 100000 : simulatedEntropy;


        return (simulatedFlux, simulatedCoherence, simulatedEntropy);
    }

    /// @notice A view function estimating the probabilistic factors for a standard ETH withdrawal based on the *current* state (without executing the attempt).
    /// @return estimatedSuccessChance The estimated percentage chance (0-100).
    /// @return estimatedMinAmount The estimated minimum possible amount that could be withdrawn if successful.
    /// @return estimatedMaxAmount The estimated maximum possible amount that could be withdrawn if successful.
    function calculateWithdrawalProbability(uint256 amountToAttempt) public view returns (uint256 estimatedSuccessChance, uint256 estimatedMinAmount, uint256 estimatedMaxAmount) {
         // Apply *simulated* time decay for the estimate
        uint256 timePassed = block.timestamp - currentQuantumState.lastInteractionTime;
        uint256 simulatedFlux = currentQuantumState.fluxLevel >= (baseParams.baseFluxDecayRate * timePassed) ? currentQuantumState.fluxLevel - (baseParams.baseFluxDecayRate * timePassed) : 0;
        uint256 simulatedCoherence = currentQuantumState.coherence >= (baseParams.baseCoherenceDecayRate * timePassed) ? currentQuantumState.coherence - (baseParams.baseCoherenceDecayRate * timePassed) : 0;
        uint256 simulatedEntropy = currentQuantumState.entropy + (baseParams.baseEntropyIncreaseRate * timePassed);

         // Cap/floor parameters for simulation
        simulatedFlux = simulatedFlux > 100000 ? 100000 : simulatedFlux;
        simulatedCoherence = simulatedCoherence > 100000 ? 100000 : simulatedCoherence;
        simulatedEntropy = simulatedEntropy > 100000 ? 100000 : simulatedEntropy;

        // Estimate success chance
        // Simplified state influence for estimation
        int256 stateInfluence = int256((simulatedCoherence / 100)) - int256((simulatedFlux / 200)) - int256((simulatedEntropy / 300)); // Coherence helps, Flux/Entropy hurt
        stateInfluence = stateInfluence > 0 ? stateInfluence : 0; // Only positive influence considered simply for estimate

        uint256 shardInfluence = (_shardBalances[msg.sender] / baseParams.withdrawalShardCostPerAttempt) * 5; // Shards provide a small bonus chance (5% per shard attempt cost unit)
        shardInfluence = shardInfluence > 50 ? 50 : shardInfluence; // Cap shard influence

        uint256 effectiveChance = baseParams.withdrawalBaseChance + uint256(stateInfluence) + shardInfluence; // Out of 100
        effectiveChance = effectiveChance > 100 ? 100 : effectiveChance; // Cap chance at 100%
        estimatedSuccessChance = effectiveChance;

        // Estimate amount fluctuation range
        int256 stateAmountModifier = int256((simulatedCoherence / 200)) - int256((simulatedEntropy / 100)); // Coherence adds, Entropy subtracts
        stateAmountModifier = stateAmountModifier > int256(amountToAttempt) ? int256(amountToAttempt) : stateAmountModifier; // Cap modifier

        uint256 finalAmountBasis = uint256(int256(amountToAttempt) + stateAmountModifier);
        finalAmountBasis = finalAmountBasis > (amountToAttempt * 2) ? (amountToAttempt * 2) : finalAmountBasis; // Cap bonus amount
        finalAmountBasis = finalAmountBasis < (amountToAttempt / 2) ? (amountToAttempt / 2) : finalAmountBasis; // Floor amount

        // Estimate min/max based on +/- 50% fluctuation around the basis
        estimatedMinAmount = (finalAmountBasis * 500) / 1000; // 50% of basis
        estimatedMaxAmount = (finalAmountBasis * 1500) / 1000; // 150% of basis

        // Ensure amounts don't exceed requested or contract balance
        estimatedMinAmount = estimatedMinAmount > amountToAttempt ? amountToAttempt : estimatedMinAmount;
        estimatedMaxAmount = estimatedMaxAmount > amountToAttempt ? amountToAttempt : estimatedMaxAmount;
        estimatedMinAmount = estimatedMinAmount > address(this).balance ? address(this).balance : estimatedMinAmount;
        estimatedMaxAmount = estimatedMaxAmount > address(this).balance ? address(this).balance : estimatedMaxAmount;

        return (estimatedSuccessChance, estimatedMinAmount, estimatedMaxAmount);
    }

    /// @notice A view function simulating the potential outcome of a state interaction function (perturb, stabilize, etc.) based on current parameters. NOTE: This is a simplified simulation for display purposes and the actual outcome on-chain may vary due to the _pseudoRandom factor and precise timing.
    /// @param interactionType 1=Perturb, 2=Stabilize, 3=InduceDecoherence
    /// @return predictedFlux The predicted flux level after interaction.
    /// @return predictedCoherence The predicted coherence level after interaction.
    /// @return predictedEntropy The predicted entropy level after interaction.
    function predictStateChange(uint256 interactionType) public view returns (uint256 predictedFlux, uint256 predictedCoherence, uint256 predictedEntropy) {
        // Apply *simulated* time decay for the estimate
        uint256 timePassed = block.timestamp - currentQuantumState.lastInteractionTime;
        predictedFlux = currentQuantumState.fluxLevel >= (baseParams.baseFluxDecayRate * timePassed) ? currentQuantumState.fluxLevel - (baseParams.baseFluxDecayRate * timePassed) : 0;
        predictedCoherence = currentQuantumState.coherence >= (baseParams.baseCoherenceDecayRate * timePassed) ? currentQuantumState.coherence - (baseParams.baseCoherenceDecayRate * timePassed) : 0;
        predictedEntropy = currentQuantumState.entropy + (baseParams.baseEntropyIncreaseRate * timePassed);

        // Simulate the specific interaction (without involving _pseudoRandom for predictability in view function)
        if (interactionType == 1) { // Perturb
            predictedFlux += baseParams.perturbFluxBoost;
            predictedEntropy += baseParams.perturbEntropyBoost;
            predictedCoherence = predictedCoherence >= 10 ? predictedCoherence - 10 : 0;
        } else if (interactionType == 2) { // Stabilize (estimate based on assumed minimum shard use)
             uint256 estimatedShardsToUse = _shardBalances[msg.sender] / 10 > 1 ? _shardBalances[msg.sender] / 10 : 1;
             predictedCoherence += baseParams.shardBurnStabilizeEffect * estimatedShardsToUse / 10;
             uint256 fluxDecrease = predictedFlux / 100 > 10 ? predictedFlux / 100 : 10;
             uint256 entropyDecrease = predictedEntropy / 100 > 10 ? predictedEntropy / 100 : 10;
             predictedFlux = predictedFlux >= fluxDecrease ? predictedFlux - fluxDecrease : 0;
             predictedEntropy = predictedEntropy >= entropyDecrease ? predictedEntropy - entropyDecrease : 0;
        } else if (interactionType == 3) { // InduceDecoherence (simulate for a base amount, e.g., 100 entropy units)
            uint256 baseAmount = 100;
             uint256 shardsToUse = baseAmount / 10;
            if (shardsToUse == 0 && baseAmount > 0) shardsToUse = 1;
             if (_shardBalances[msg.sender] >= shardsToUse) { // Only simulate if user has enough shards for base amount
                predictedEntropy += baseAmount;
                predictedCoherence = predictedCoherence >= baseAmount / 2 ? predictedCoherence - baseAmount / 2 : 0;
             }
        }

         // Cap/floor parameters for simulation
        predictedFlux = predictedFlux > 100000 ? 100000 : predictedFlux;
        predictedCoherence = predictedCoherence > 100000 ? 100000 : predictedCoherence;
        predictedEntropy = predictedEntropy > 100000 ? 100000 : predictedEntropy;

        return (predictedFlux, predictedCoherence, predictedEntropy);
    }


    /// @notice Checks and returns the details of a delegation granted by a specific user to a specific delegate.
    /// @param delegator The address who granted the permission.
    /// @param delegate The address who received the permission.
    /// @return delegateAddress The delegate's address.
    /// @return maxAmount The maximum ETH amount allowed.
    /// @return expiryTime The expiration timestamp.
    /// @return minCoherenceRequired The minimum coherence level required.
    /// @return active Whether the delegation is currently active.
    function getDelegationStatus(address delegator, address delegate) public view returns (address delegateAddress, uint256 maxAmount, uint256 expiryTime, uint256 minCoherenceRequired, bool active) {
        WithdrawalDelegation storage delegation = _withdrawalDelegations[delegator][delegate];
        return (delegation.delegate, delegation.maxAmount, delegation.expiryTime, delegation.minCoherenceRequired, delegation.active);
    }

    /// @notice A view function estimating the probabilistic factors for a Quantum Tunneling withdrawal.
    /// @param amountToAttempt The desired amount of ETH to withdraw.
    /// @param shardsToBurn The amount of Shards planned to burn for this attempt.
    /// @return estimatedSuccessChanceBasis The estimated chance out of 100,000.
    function calculateTunnelingProbability(uint256 amountToAttempt, uint256 shardsToBurn) public view returns (uint256 estimatedSuccessChanceBasis) {
         // Apply *simulated* time decay for the estimate
        uint256 timePassed = block.timestamp - currentQuantumState.lastInteractionTime;
        uint256 simulatedFlux = currentQuantumState.fluxLevel >= (baseParams.baseFluxDecayRate * timePassed) ? currentQuantumState.fluxLevel - (baseParams.baseFluxDecayRate * timePassed) : 0;
        uint256 simulatedCoherence = currentQuantumState.coherence >= (baseParams.baseCoherenceDecayRate * timePassed) ? currentQuantumState.coherence - (baseParams.baseCoherenceDecayRate * timePassed) : 0;
        uint256 simulatedEntropy = currentQuantumState.entropy + (baseParams.baseEntropyIncreaseRate * timePassed);

         // Cap/floor parameters for simulation
        simulatedFlux = simulatedFlux > 100000 ? 100000 : simulatedFlux;
        simulatedCoherence = simulatedCoherence > 100000 ? 100000 : simulatedCoherence;
        simulatedEntropy = simulatedEntropy > 100000 ? simulatedEntropy : simulatedEntropy; // No cap on entropy for tunneling estimate? Or use a high cap? Let's use the standard cap.
        simulatedEntropy = simulatedEntropy > 100000 ? 100000 : simulatedEntropy;


        // Tunneling probability calculation - very sensitive to state and shard burn
        // Simplified state influence for estimation
        int256 stateInfluence = int256(simulatedFlux / 50) + int256(simulatedEntropy / 50) - int256(simulatedCoherence / 100);
        stateInfluence = stateInfluence > -10000 ? stateInfluence : -10000; // Cap negative influence

        uint256 shardInfluence = shardsToBurn / 10; // 1% bonus chance per 10 shards burned
        shardInfluence = shardInfluence > 10000 ? 10000 : shardInfluence; // Cap shard influence at 100% effective bonus

        uint256 effectiveChanceBasis = baseParams.tunnelingBaseChance + (stateInfluence > 0 ? uint256(stateInfluence) : 0) + shardInfluence; // Add positive influences
        effectiveChanceBasis = effectiveChanceBasis > 100000 ? 100000 : effectiveChanceBasis; // Cap at 100% basis

        estimatedSuccessChanceBasis = effectiveChanceBasis;
        return estimatedSuccessChanceBasis;
    }

    /// @notice Returns the number of deposits made by a specific address.
    /// @param user The address to check.
    /// @return count The number of deposits made by the user.
    function getDepositCount(address user) public view returns (uint256 count) {
        return _userDepositCount[user];
    }

     // Fallback function to accept ETH deposits
    receive() external payable {
        depositETH();
    }
}
```