Okay, here is a Solidity smart contract concept focusing on dynamic state evolution for NFTs based on staked tokens and time, incorporating concepts like cultivation, yield, state transitions, and potential mutations. It's named "QuantumBloomProtocol" to reflect the dynamic, time-sensitive, and potentially unexpected nature of the process.

This contract acts as a manager for *existing* ERC-721 tokens (referred to as "Bloom Units") and interacts with an *existing* ERC-20 token (referred to as "Essence"). Users stake Essence tokens on their Bloom Units within this contract to influence their "bloom state" and potentially earn yield.

**Concept:** Users stake `Essence` tokens on a specific `Bloom Unit` (NFT). The amount staked and the duration of staking influence the Bloom Unit's `bloomState`. Higher stake and longer time move the unit through different states (Seed -> Sprout -> Bud -> Blooming). Unstaking or insufficient stake can lead to a `Dormant` state. Being in a certain state might enable earning yield on the staked Essence and/or trigger trait mutations on the Bloom Unit.

**Disclaimer:** This is a conceptual contract for demonstration purposes. It requires careful review, security audits, and potentially external contracts (for the actual ERC20 and ERC721 tokens, and potentially for trait updates on the ERC721 itself, as this contract only *manages the state and logic* associated with the NFT ID, not the NFT contract's core data unless integrated). Randomness on-chain (`block.timestamp`, `blockhash`) is predictable and should not be used for high-value, security-critical randomness without external oracle solutions like Chainlink VRF.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // We'll interact with NFTs, but not define the NFT contract itself here
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Good practice for arithmetic

/// @title QuantumBloomProtocol
/// @author YourNameHere
/// @dev Manages the dynamic state and rewards for Bloom Unit NFTs based on staked Essence tokens and time.
/// Users stake Essence tokens on their Bloom Units to cultivate them through different states (Seed, Sprout, Bud, Blooming).
/// Staking duration and amount influence state progression and potential yield/mutations.

/*
Outline:
1. State Definitions (Enums, Structs)
2. Core State Variables (Mappings for NFT state, Contract parameters)
3. Events
4. Access Control (Owner-only functions)
5. Core User Interactions (Staking, Unstaking, Claiming Yield)
6. Dynamic State Logic (Updating Bloom State, Triggering Mutations)
7. Query Functions (Getting state, staked amount, yield, parameters)
8. Utility/Helper Functions (Calculations, Simulations, Batch updates)
9. Emergency/Administrative Functions
*/

/*
Function Summary:

1.  constructor(address _essenceTokenAddress, uint256 _bloomRate, uint256 _yieldRate, uint256 _mutationChance): Initializes the contract with token addresses and initial parameters.
2.  setEssenceTokenAddress(address _tokenAddress): Owner sets the address of the Essence ERC20 token.
3.  setBloomParameters(uint256 _bloomRate, uint256 _yieldRate, uint256 _mutationChance, uint256 _maxBloomState): Owner updates system parameters.
4.  pause(): Owner pauses staking, unstaking, and claiming.
5.  unpause(): Owner unpauses the contract.
6.  renounceOwnership(): Owner renounces ownership.
7.  transferOwnership(address newOwner): Owner transfers ownership.
8.  stakeEssence(uint256 _bloomUnitId, uint256 _amount): User stakes Essence tokens on their Bloom Unit NFT. Requires ERC20 approval.
9.  unstakeEssence(uint256 _bloomUnitId): User unstakes all Essence tokens from their Bloom Unit.
10. claimYield(uint256 _bloomUnitId): User claims accumulated yield for a Bloom Unit.
11. updateBloomState(uint256 _bloomUnitId): Public function to trigger the state update calculation for a Bloom Unit based on time and stake. Can be called by anyone.
12. triggerMutation(uint256 _bloomUnitId): Attempts to trigger a trait mutation for a Bloom Unit based on chance and state.
13. forceDormancy(uint256 _bloomUnitId): Owner can force a specific Bloom Unit into the Dormant state.
14. getBloomState(uint256 _bloomUnitId): Returns the current BloomState enum for a Bloom Unit.
15. getStakedEssence(uint256 _bloomUnitId): Returns the amount of Essence staked on a Bloom Unit.
16. getPendingYield(uint256 _bloomUnitId): Calculates and returns the pending yield for a Bloom Unit.
17. getTraitModifiers(uint256 _bloomUnitId): Returns the current trait modifiers struct for a Bloom Unit.
18. getTotalStakedEssence(): Returns the total amount of Essence staked across all Bloom Units in the contract.
19. getManagementStatus(uint256 _bloomUnitId): Checks if state management is active for a given Bloom Unit ID.
20. getCurrentParameters(): Returns the current configuration parameters (`bloomRate`, `yieldRate`, `mutationChance`, `maxBloomState`).
21. calculateBloomState(uint256 _bloomUnitId, uint256 _currentTime): Public helper to calculate the theoretical bloom state at a given time.
22. calculatePendingYield(uint256 _bloomUnitId, uint256 _currentTime): Public helper to calculate theoretical pending yield at a given time.
23. simulateBloomState(uint256 _bloomUnitId, uint256 _futureTime): Public helper to simulate the bloom state progression up to a future time.
24. triggerAllPendingUpdates(uint256[] memory _bloomUnitIds): Allows triggering `updateBloomState` for a batch of Bloom Units.
25. withdrawEssence(uint256 _amount): Owner can withdraw unallocated Essence tokens from the contract (e.g., tokens sent by mistake).
26. checkMutationSuccess(uint256 _bloomUnitId): Checks if a mutation *would* succeed based on current conditions and block data (note: on-chain randomness limitations).

*/

contract QuantumBloomProtocol is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- State Definitions ---
    enum BloomState {
        Seed,       // Initial state
        Sprout,     // Early growth
        Bud,        // Developing, potential yield
        Blooming,   // Fully bloomed, max yield/mutation chance
        Dormant     // Inactive state (e.g., after unstaking)
    }

    struct BloomUnitData {
        BloomState bloomState;
        uint256 cultivationStartTime; // When staking started/resumed
        uint256 stakedEssence;      // Amount of Essence staked
        uint256 lastYieldClaimTime; // When yield was last claimed
        TraitModifiers traitModifiers; // Dynamic modifiers for traits
    }

    struct TraitModifiers {
        uint256 yieldMultiplier;    // Affects yield rate
        uint256 mutationResistance; // Affects mutation chance
        uint256 bloomSpeedModifier; // Affects rate of state progression
        // Add more dynamic trait modifiers here as needed
    }

    // --- Core State Variables ---
    IERC20 public essenceToken;
    // IERC721 public bloomUnitToken; // Address of the Bloom Unit NFT contract (we interact, not own)

    mapping(uint256 => BloomUnitData) public bloomUnits; // BloomUnitId => Data
    mapping(uint256 => address) public bloomUnitOwner; // BloomUnitId => Owner address (stored for convenience, actual owner is on ERC721)
    mapping(uint256 => bool) private _isManaging; // Tracks if the contract is managing state for this ID

    uint256 public bloomRate; // How quickly states progress (e.g., units of stake-time per state change)
    uint256 public yieldRate; // Base yield per staked essence per unit of time
    uint256 public mutationChance; // Base chance (e.g., parts per 10000) of a mutation when triggered
    uint256 public maxBloomStateDuration; // Max time in Blooming state before potential reset/change? (Example param)

    uint256 public totalStakedEssence;
    bool public paused;

    // --- Events ---
    event EssenceStaked(address indexed user, uint256 indexed bloomUnitId, uint256 amount);
    event EssenceUnstaked(address indexed user, uint256 indexed bloomUnitId, uint256 amount);
    event YieldClaimed(address indexed user, uint256 indexed bloomUnitId, uint256 amount);
    event BloomStateChanged(uint256 indexed bloomUnitId, BloomState oldState, BloomState newState, uint256 cultivationTime);
    event TraitMutated(uint256 indexed bloomUnitId, bytes32 indexed mutationSeed, string description); // description could encode changes
    event ParametersUpdated(uint256 bloomRate, uint256 yieldRate, uint256 mutationChance, uint256 maxBloomState);
    event ContractPaused(address indexed account);
    event ContractUnpaused(address indexed account);
    event EmergencyEssenceWithdrawal(address indexed owner, uint256 amount);

    // --- Modifiers ---
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    modifier onlyManaged(uint256 _bloomUnitId) {
        require(_isManaging[_bloomUnitId], "Bloom unit not managed by this contract");
        _;
    }

    modifier onlyBloomUnitOwner(uint256 _bloomUnitId) {
        require(bloomUnitOwner[_bloomUnitId] == msg.sender, "Not your bloom unit");
        // Note: This relies on the stored owner, which might not be perfectly in sync with the ERC721 owner if transfers happen
        // without being registered here. A more robust system would query the actual ERC721 owner.
        // For this example, we'll assume ownership is recorded on first stake and updated if necessary.
        _;
    }


    // --- Constructor ---
    /// @notice Initializes the QuantumBloomProtocol contract.
    /// @param _essenceTokenAddress The address of the ERC20 token used for staking (Essence).
    /// @param _bloomRate Initial rate for bloom state progression.
    /// @param _yieldRate Initial rate for yield calculation.
    /// @param _mutationChance Initial chance for trait mutation.
    /// @param _maxBloomStateDuration Initial max duration for the Blooming state.
    constructor(
        address _essenceTokenAddress,
        uint256 _bloomRate,
        uint256 _yieldRate,
        uint256 _mutationChance,
        uint256 _maxBloomStateDuration
    ) Ownable(msg.sender) {
        essenceToken = IERC20(_essenceTokenAddress);
        // bloomUnitToken = IERC721(_bloomUnitTokenAddress); // If we need to query ERC721 state
        bloomRate = _bloomRate;
        yieldRate = _yieldRate;
        mutationChance = _mutationChance;
        maxBloomStateDuration = _maxBloomStateDuration; // Example parameter
        paused = false;
    }

    // --- Access Control (Owner-only) ---

    /// @notice Sets the address of the Essence ERC20 token contract.
    /// @dev Only callable by the contract owner.
    /// @param _tokenAddress The new address for the Essence token contract.
    function setEssenceTokenAddress(address _tokenAddress) external onlyOwner {
        essenceToken = IERC20(_tokenAddress);
    }

    /// @notice Updates the core parameters governing bloom state progression, yield, and mutation.
    /// @dev Only callable by the contract owner.
    /// @param _bloomRate New value for bloom rate.
    /// @param _yieldRate New value for yield rate.
    /// @param _mutationChance New value for mutation chance (e.g., parts per 10000).
    /// @param _maxBloomStateDuration New value for max bloom state duration.
    function setBloomParameters(
        uint256 _bloomRate,
        uint256 _yieldRate,
        uint256 _mutationChance,
        uint256 _maxBloomStateDuration
    ) external onlyOwner {
        bloomRate = _bloomRate;
        yieldRate = _yieldRate;
        mutationChance = _mutationChance;
        maxBloomStateDuration = _maxBloomStateDuration;
        emit ParametersUpdated(_bloomRate, _yieldRate, _mutationChance, _maxBloomStateDuration);
    }

    /// @notice Pauses core user interactions (staking, unstaking, claiming).
    /// @dev Only callable by the contract owner. Prevents user actions during upgrades or maintenance.
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, re-enabling core user interactions.
    /// @dev Only callable by the contract owner.
    function unpause() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the owner to withdraw unallocated Essence tokens from the contract.
    /// @dev Useful for recovering tokens accidentally sent to the contract address.
    /// @param _amount The amount of Essence tokens to withdraw.
    function withdrawEssence(uint256 _amount) external onlyOwner {
        uint256 contractBalance = essenceToken.balanceOf(address(this));
        require(_amount > 0 && _amount <= contractBalance, "Invalid withdrawal amount");
        // Prevent withdrawing staked tokens. A more complex check could subtract totalStakedEssence.
        // For simplicity, this withdraws any amount up to the balance, assuming staked is accounted for elsewhere or owner is careful.
        // A safer version might be `contractBalance.sub(totalStakedEssence)`.
        // For this example, let's assume owner withdraws excess.
        essenceToken.transfer(msg.sender, _amount);
        emit EmergencyEssenceWithdrawal(msg.sender, _amount);
    }


    // --- Core User Interactions ---

    /// @notice Stakes Essence tokens on a specific Bloom Unit NFT.
    /// @dev Requires the user to have previously approved this contract to spend the Essence tokens.
    /// Updates the bloom unit's data, starts/resumes cultivation, and updates total staked amount.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @param _amount The amount of Essence tokens to stake.
    function stakeEssence(uint256 _bloomUnitId, uint256 _amount) external whenNotPaused nonReentrant {
        require(_amount > 0, "Cannot stake zero amount");

        // We need to verify the msg.sender owns this NFT. This requires interaction with the ERC721 contract.
        // For this example, we'll *assume* the ERC721 contract is separate and managed externally,
        // and we'll store the owner on first stake. A production system would need to query the ERC721 directly.
        // Example (requires bloomUnitToken address):
        // require(bloomUnitToken.ownerOf(_bloomUnitId) == msg.sender, "Not the owner of the Bloom Unit");

        // If this is the first time staking for this ID, record the owner and mark as managed.
        if (!_isManaging[_bloomUnitId]) {
            bloomUnitOwner[_bloomUnitId] = msg.sender; // Store owner (see note above)
            _isManaging[_bloomUnitId] = true;
            // Initialize with Seed state and default modifiers
            bloomUnits[_bloomUnitId].bloomState = BloomState.Seed;
            bloomUnits[_bloomUnitId].traitModifiers = TraitModifiers({
                yieldMultiplier: 1e18, // Default 1x multiplier (using 18 decimals for precision)
                mutationResistance: 1e18, // Default resistance
                bloomSpeedModifier: 1e18 // Default speed
            });
        } else {
             // If already managed, ensure caller is the recorded owner
            require(bloomUnitOwner[_bloomUnitId] == msg.sender, "Only Bloom Unit owner can stake");
            // Claim any pending yield before updating stake
            _claimYield(_bloomUnitId);
        }


        // Transfer Essence tokens from the user to this contract
        require(essenceToken.transferFrom(msg.sender, address(this), _amount), "Essence transfer failed");

        // Update staked amount and total
        bloomUnits[_bloomUnitId].stakedEssence = bloomUnits[_bloomUnitId].stakedEssence.add(_amount);
        totalStakedEssence = totalStakedEssence.add(_amount);

        // If not in Blooming state and was Dormant or Seed with 0 stake, restart/start cultivation timer
        // Or if state needs recalculation based on new stake amount
        // Recalculate state based on *new* cumulative staked time + amount?
        // A simpler model: cultivation time resets/pauses when stake goes to 0 or state is Dormant.
        // When staking >= minStake, timer starts/resumes from *now*.
        // Let's reset cultivation timer on stake/unstake for simplicity in this example.
        bloomUnits[_bloomUnitId].cultivationStartTime = block.timestamp;
        bloomUnits[_bloomUnitId].lastYieldClaimTime = block.timestamp; // Also reset yield timer

        // Immediately calculate the new state based on the initial stake
        _updateBloomState(_bloomUnitId, block.timestamp);

        emit EssenceStaked(msg.sender, _bloomUnitId, _amount);
    }

    /// @notice Unstakes all Essence tokens from a specific Bloom Unit NFT.
    /// @dev Transfers tokens back to the Bloom Unit owner. Updates state to Dormant.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    function unstakeEssence(uint256 _bloomUnitId) external onlyManaged(_bloomUnitId) onlyBloomUnitOwner(_bloomUnitId) whenNotPaused nonReentrant {
        uint256 stakedAmount = bloomUnits[_bloomUnitId].stakedEssence;
        require(stakedAmount > 0, "No essence staked on this bloom unit");

        // Claim any pending yield before unstaking
        _claimYield(_bloomUnitId);

        // Update staked amount and total
        bloomUnits[_bloomUnitId].stakedEssence = 0;
        totalStakedEssence = totalStakedEssence.sub(stakedAmount);

        // Transfer Essence tokens back to the user
        require(essenceToken.transfer(msg.sender, stakedAmount), "Essence transfer failed");

        // Set state to Dormant immediately
        BloomState oldState = bloomUnits[_bloomUnitId].bloomState;
        bloomUnits[_bloomUnitId].bloomState = BloomState.Dormant;
        bloomUnits[_bloomUnitId].cultivationStartTime = 0; // Reset timer
        bloomUnits[_bloomUnitId].lastYieldClaimTime = block.timestamp; // Reset yield timer (yield was claimed)

        emit EssenceUnstaked(msg.sender, _bloomUnitId, stakedAmount);
        if (oldState != BloomState.Dormant) {
             emit BloomStateChanged(_bloomUnitId, oldState, BloomState.Dormant, 0);
        }
    }

    /// @notice Claims accumulated yield for a specific Bloom Unit NFT.
    /// @dev Calculates yield based on staked amount, state, time since last claim, and trait modifiers.
    /// Transfers yield (Essence tokens) to the Bloom Unit owner.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    function claimYield(uint256 _bloomUnitId) external onlyManaged(_bloomUnitId) onlyBloomUnitOwner(_bloomUnitId) whenNotPaused nonReentrant {
        _claimYield(_bloomUnitId);
    }

    /// @dev Internal helper for claiming yield, called by `claimYield` and `stakeEssence`/`unstakeEssence`.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    function _claimYield(uint256 _bloomUnitId) internal {
        uint256 pendingYield = _calculatePendingYield(_bloomUnitId, block.timestamp);

        if (pendingYield > 0) {
            // Ensure contract has enough balance (yield might come from staked pool or separate source)
            // In this simple model, yield comes from the contract's total balance.
            // A real system might require the owner to deposit yield pool funds.
            require(essenceToken.balanceOf(address(this)) >= pendingYield, "Insufficient contract balance for yield");

            // Transfer yield
            require(essenceToken.transfer(msg.sender, pendingYield), "Yield transfer failed");

            // Update last claim time
            bloomUnits[_bloomUnitId].lastYieldClaimTime = block.timestamp;

            emit YieldClaimed(msg.sender, _bloomUnitId, pendingYield);
        }
        // If pendingYield is 0, do nothing.
    }


    // --- Dynamic State Logic ---

    /// @notice Updates the bloom state of a specific Bloom Unit based on time and staked amount.
    /// @dev This function can be called by *anyone* to trigger the state transition, reducing gas costs for the owner.
    /// It calculates the potential next state based on cumulative cultivation time and the amount staked.
    /// Handles transitions between Seed, Sprout, Bud, Blooming, and checks for Dormant (set by unstake/forceDormancy).
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    function updateBloomState(uint256 _bloomUnitId) external onlyManaged(_bloomUnitId) {
        _updateBloomState(_bloomUnitId, block.timestamp);
    }

    /// @dev Internal helper for updating bloom state.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @param _currentTime The timestamp to use for calculation (typically `block.timestamp`).
    function _updateBloomState(uint256 _bloomUnitId, uint256 _currentTime) internal {
        BloomUnitData storage unitData = bloomUnits[_bloomUnitId];

        // Only update state if not Dormant and staking is active
        if (unitData.bloomState == BloomState.Dormant || unitData.stakedEssence == 0 || unitData.cultivationStartTime == 0) {
            return; // No active cultivation
        }

        BloomState oldState = unitData.bloomState;
        BloomState newCalculatedState = _calculateBloomState(_bloomUnitId, _currentTime);

        if (newCalculatedState != oldState) {
            unitData.bloomState = newCalculatedState;
            // Optionally update trait modifiers based on new state
            _applyStateBasedTraitModifiers(_bloomUnitId, newCalculatedState);

            emit BloomStateChanged(_bloomUnitId, oldState, newCalculatedState, _currentTime.sub(unitData.cultivationStartTime));

            // If transitioning into Blooming state, maybe start a timer towards decay/reset?
            // Or if transitioning OUT of Blooming state (e.g., due to maxDuration)
            // Example: If state becomes Dormant after prolonged Blooming (based on maxBloomStateDuration check, not implemented here)
        }
    }

     /// @dev Internal helper to apply trait modifiers based on the current state.
     /// @param _bloomUnitId The ID of the Bloom Unit NFT.
     /// @param _currentState The new state.
     function _applyStateBasedTraitModifiers(uint256 _bloomUnitId, BloomState _currentState) internal {
        BloomUnitData storage unitData = bloomUnits[_bloomUnitId];
        // Reset to defaults
        unitData.traitModifiers.yieldMultiplier = 1e18;
        unitData.traitModifiers.mutationResistance = 1e18;
        unitData.traitModifiers.bloomSpeedModifier = 1e18;

        // Apply multipliers based on state (example values)
        if (_currentState == BloomState.Sprout) {
            unitData.traitModifiers.bloomSpeedModifier = 1.1e18; // 10% faster progression to next state
        } else if (_currentState == BloomState.Bud) {
             unitData.traitModifiers.yieldMultiplier = 1.5e18; // 50% more yield
             unitData.traitModifiers.bloomSpeedModifier = 1.2e18; // 20% faster
        } else if (_currentState == BloomState.Blooming) {
             unitData.traitModifiers.yieldMultiplier = 2.0e18; // 100% more yield
             unitData.traitModifiers.mutationResistance = 0.8e18; // 20% less resistance (higher chance of mutation)
             unitData.traitModifiers.bloomSpeedModifier = 1.0e18; // Normal speed
        }
        // Dormant and Seed states use base modifiers (1.0x)
     }


    /// @notice Attempts to trigger a trait mutation for a Bloom Unit.
    /// @dev Can be called by anyone. Success depends on current state, mutationChance, and trait modifiers.
    /// Uses block data for a basic source of variation (note: predictable).
    /// If successful, modifies trait modifiers and emits an event.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    function triggerMutation(uint256 _bloomUnitId) external onlyManaged(_bloomUnitId) {
        BloomUnitData storage unitData = bloomUnits[_bloomUnitId];

        // Update state first to ensure calculations are based on current progression
        _updateBloomState(_bloomUnitId, block.timestamp);

        // Only allow mutation attempt in certain states (e.g., Blooming)
        if (unitData.bloomState != BloomState.Blooming) {
            return; // Mutation only happens in the peak state
        }

        // Calculate effective mutation chance considering modifiers
        // Base chance is mutationChance (per 10000), resistance reduces it.
        // E.g., mutationChance = 100 (1%), resistance = 0.8e18 (0.8x) -> effective = 100 * 0.8 = 80 (0.8%)
        uint256 effectiveChance = mutationChance.mul(unitData.traitModifiers.mutationResistance).div(1e18); // Adjust for 1e18 multiplier

        // Generate a "random" number using block data (predictable!)
        // A more secure random source (like Chainlink VRF) is needed for production
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _bloomUnitId, blockhash(block.number - 1)))) % 10000; // Number between 0-9999

        if (randomNumber < effectiveChance) {
            // Mutation Successful!
            bytes32 mutationSeed = keccak256(abi.encodePacked(block.timestamp, randomNumber, _bloomUnitId)); // Seed for off-chain trait generation

            // Apply a random modifier change (example: increase yield multiplier)
            // This is a very basic example, could be more complex based on the seed
            uint256 yieldBoost = (randomNumber % 50) + 10; // Boost between 10 and 59 per 1e18
            unitData.traitModifiers.yieldMultiplier = unitData.traitModifiers.yieldMultiplier.add(yieldBoost * 1e18 / 10000);

            emit TraitMutated(_bloomUnitId, mutationSeed, "Yield boost applied");

            // Optionally, trigger a state change or reset after mutation?
            // Example: Revert to Bud state after a successful mutation
            // BloomState oldState = unitData.bloomState;
            // unitData.bloomState = BloomState.Bud;
            // _applyStateBasedTraitModifiers(_bloomUnitId, BloomState.Bud);
            // emit BloomStateChanged(_bloomUnitId, oldState, BloomState.Bud, 0);
        }
    }

     /// @notice Owner function to force a specific Bloom Unit into the Dormant state.
     /// @dev Can be used for administrative purposes. Unstaking should be the normal way to become Dormant.
     /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    function forceDormancy(uint256 _bloomUnitId) external onlyOwner onlyManaged(_bloomUnitId) {
        BloomState oldState = bloomUnits[_bloomUnitId].bloomState;
        if (oldState != BloomState.Dormant) {
            bloomUnits[_bloomUnitId].bloomState = BloomState.Dormant;
            bloomUnits[_bloomUnitId].cultivationStartTime = 0; // Reset timer
            // Note: Staked essence remains unless unstaked separately
            emit BloomStateChanged(_bloomUnitId, oldState, BloomState.Dormant, 0);
        }
    }


    // --- Query Functions ---

    /// @notice Gets the current bloom state of a specific Bloom Unit.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @return The current BloomState enum value.
    function getBloomState(uint256 _bloomUnitId) external view onlyManaged(_bloomUnitId) returns (BloomState) {
        return bloomUnits[_bloomUnitId].bloomState;
    }

    /// @notice Gets the amount of Essence tokens currently staked on a specific Bloom Unit.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @return The staked amount in Essence tokens.
    function getStakedEssence(uint256 _bloomUnitId) external view onlyManaged(_bloomUnitId) returns (uint256) {
        return bloomUnits[_bloomUnitId].stakedEssence;
    }

    /// @notice Calculates the amount of pending yield for a specific Bloom Unit.
    /// @dev Calculates yield based on current state, staked amount, and time since last claim. Does not claim.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @return The amount of pending yield in Essence tokens.
    function getPendingYield(uint256 _bloomUnitId) external view onlyManaged(_bloomUnitId) returns (uint256) {
        return _calculatePendingYield(_bloomUnitId, block.timestamp);
    }

    /// @notice Gets the current dynamic trait modifiers for a specific Bloom Unit.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @return A struct containing the current trait modifiers.
    function getTraitModifiers(uint256 _bloomUnitId) external view onlyManaged(_bloomUnitId) returns (TraitModifiers memory) {
        return bloomUnits[_bloomUnitId].traitModifiers;
    }

    /// @notice Gets the total amount of Essence tokens staked across all managed Bloom Units in the contract.
    /// @return The total staked Essence amount.
    function getTotalStakedEssence() external view returns (uint256) {
        return totalStakedEssence;
    }

     /// @notice Checks if the contract is managing state for a specific Bloom Unit ID.
     /// @param _bloomUnitId The ID of the Bloom Unit NFT.
     /// @return True if the ID is being managed, false otherwise.
    function getManagementStatus(uint256 _bloomUnitId) external view returns (bool) {
        return _isManaging[_bloomUnitId];
    }

    /// @notice Gets the current configuration parameters of the protocol.
    /// @return bloomRate_, yieldRate_, mutationChance_, maxBloomStateDuration_
    function getCurrentParameters() external view returns (uint256, uint256, uint256, uint256) {
        return (bloomRate, yieldRate, mutationChance, maxBloomStateDuration);
    }


    // --- Utility/Helper Functions ---

    /// @notice Calculates the theoretical bloom state of a Bloom Unit at a given time.
    /// @dev Public helper function for off-chain calculations or verification. Does not change state.
    /// State progression is based on cumulative "cultivation power" (staked amount * duration).
    /// Assumes a linear progression model based on stake * time since cultivationStartTime.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @param _currentTime The timestamp to calculate the state for.
    /// @return The calculated BloomState enum value.
    function calculateBloomState(uint256 _bloomUnitId, uint256 _currentTime) external view onlyManaged(_bloomUnitId) returns (BloomState) {
        return _calculateBloomState(_bloomUnitId, _currentTime);
    }

     /// @dev Internal helper for calculating bloom state.
     function _calculateBloomState(uint256 _bloomUnitId, uint256 _currentTime) internal view returns (BloomState) {
        BloomUnitData storage unitData = bloomUnits[_bloomUnitId];

        if (unitData.stakedEssence == 0 || unitData.cultivationStartTime == 0 || _currentTime <= unitData.cultivationStartTime) {
             // Needs active stake and a start time
            return BloomState.Seed; // Or Dormant? Let's say Seed if managed but inactive.
        }

        uint256 duration = _currentTime.sub(unitData.cultivationStartTime);
        // Apply bloom speed modifier
        duration = duration.mul(unitData.traitModifiers.bloomSpeedModifier).div(1e18);

        // Calculate cumulative cultivation power (stake * time)
        // Scale stake amount down to avoid overflow if very large. Using 1e6 scaling for example.
        uint256 scaledStake = unitData.stakedEssence / (1e6);
        uint256 cultivationPower = scaledStake.mul(duration);

        // State thresholds (example values - need careful tuning)
        // These thresholds depend on the bloomRate parameter
        uint256 thresholdSprout = bloomRate;
        uint256 thresholdBud = bloomRate.mul(2);
        uint256 thresholdBlooming = bloomRate.mul(4); // Needs significantly more power to reach Blooming

        if (cultivationPower >= thresholdBlooming) {
             return BloomState.Blooming;
        } else if (cultivationPower >= thresholdBud) {
             return BloomState.Bud;
        } else if (cultivationPower >= thresholdSprout) {
             return BloomState.Sprout;
        } else {
             return BloomState.Seed;
        }
     }


    /// @notice Calculates the theoretical pending yield for a Bloom Unit at a given time.
    /// @dev Public helper function for off-chain calculations or verification. Does not change state.
    /// Yield accrues based on staked amount, time since last claim, current state, and yield multiplier.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @param _currentTime The timestamp to calculate the yield for.
    /// @return The calculated pending yield in Essence tokens.
    function calculatePendingYield(uint256 _bloomUnitId, uint256 _currentTime) external view onlyManaged(_bloomUnitId) returns (uint256) {
        return _calculatePendingYield(_bloomUnitId, _currentTime);
    }

     /// @dev Internal helper for calculating pending yield.
     function _calculatePendingYield(uint256 _bloomUnitId, uint256 _currentTime) internal view returns (uint256) {
        BloomUnitData storage unitData = bloomUnits[_bloomUnitId];

        // No yield if staked amount is zero or if state is Seed/Dormant
        if (unitData.stakedEssence == 0 || _currentTime <= unitData.lastYieldClaimTime || unitData.bloomState == BloomState.Seed || unitData.bloomState == BloomState.Dormant) {
            return 0;
        }

        uint256 timeSinceLastClaim = _currentTime.sub(unitData.lastYieldClaimTime);

        // Base yield = stakedAmount * timeSinceLastClaim * yieldRate
        // Apply yield multiplier from traits
        // Example: yieldRate is per second per token (using 1e18 scale for yieldRate)
        // Total yield = staked * time * yieldRate * yieldMultiplier / (1e18 * 1e18) -- need careful scaling
        // Let's simplify yieldRate: yield per staked token per second, scaled by 1e18
        // Example: yieldRate = 1e18 (1 token per second per token staked)
        // Total yield = staked * time * (yieldRate / 1e18) * (yieldMultiplier / 1e18) = staked * time * yieldRate * yieldMultiplier / 1e36
        // This can overflow easily. Let's use a smaller scale for yieldRate or a different calculation.

        // Alternative yield calculation: yieldRate is yield per **unit** of time per **unit** of stake (e.g., per second per 1 Essence)
        // yieldRate is scaled by 1e18.
        // Total Yield = (stakedAmount * timeSinceLastClaim * yieldRate * yieldMultiplier) / (1e18 * 1e18)
        // Use SafeMath mul/div to prevent overflow, scale down large numbers carefully.
        // Scale stakedAmount down for calculation:
        uint256 scaledStaked = unitData.stakedEssence / 1e6; // Scale down by 1e6
        uint256 scaledYieldRate = yieldRate / 1e6; // Scale down yieldRate by 1e6 as well

        // Now calculate: (scaledStaked * timeSinceLastClaim * scaledYieldRate * yieldMultiplier) / 1e18
        // Let's use `mul` directly with yieldRate * yieldMultiplier first
        uint256 yieldFactor = yieldRate.mul(unitData.traitModifiers.yieldMultiplier).div(1e18); // Combined rate, scaled by 1e18

        // Total Yield = (stakedAmount * timeSinceLastClaim * yieldFactor) / 1e18
        // This can still overflow if stakedAmount or timeSinceLastClaim are very large.
        // Let's assume reasonable scales or use a different fixed-point math library if needed.
        // For simplicity, assuming stakedAmount and timeSinceLastClaim fit in uint256 before multiplication with scaledFactor.
        uint256 totalAccrualUnits = unitData.stakedEssence.mul(timeSinceLastClaim);
        uint256 pendingYield = totalAccrualUnits.mul(yieldFactor).div(1e18); // Final yield, assuming yieldFactor was scaled by 1e18

        return pendingYield;
     }


    /// @notice Simulates the bloom state progression for a Bloom Unit up to a future time.
    /// @dev Public helper function for off-chain forecasting. Does not change state.
    /// Useful for predicting when a state transition might occur.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @param _futureTime The future timestamp to simulate up to.
    /// @return The calculated BloomState at the simulated future time.
    function simulateBloomState(uint256 _bloomUnitId, uint256 _futureTime) external view onlyManaged(_bloomUnitId) returns (BloomState) {
         require(_futureTime >= block.timestamp, "Future time must be in the future");
         // Use the internal helper with the future time
         return _calculateBloomState(_bloomUnitId, _futureTime);
    }

    /// @notice Allows triggering `updateBloomState` for a batch of Bloom Unit IDs.
    /// @dev Gas costs will be proportional to the number of units in the array.
    /// Can be called by anyone to help update the state of multiple NFTs.
    /// @param _bloomUnitIds An array of Bloom Unit IDs to update.
    function triggerAllPendingUpdates(uint256[] memory _bloomUnitIds) external {
        for (uint i = 0; i < _bloomUnitIds.length; i++) {
             uint256 bloomUnitId = _bloomUnitIds[i];
             // Only attempt update if managed, skip otherwise.
             // Using try-catch might be safer for robustness if some IDs might not be managed
             // but Simple `if` check is sufficient for this example.
             if (_isManaging[bloomUnitId]) {
                 _updateBloomState(bloomUnitId, block.timestamp);
             }
        }
    }

    /// @notice Checks if a mutation *would* succeed for a Bloom Unit based on current conditions and block data.
    /// @dev Public helper function. Useful for off-chain UI to indicate mutation potential.
    /// Note: The actual outcome on-chain can differ due to block timing influencing `block.timestamp` and `blockhash`.
    /// @param _bloomUnitId The ID of the Bloom Unit NFT.
    /// @return success_ True if a mutation attempt would succeed, false otherwise.
    /// @return effectiveChance_ The effective mutation chance used in the check (scaled by 10000).
    /// @return randomNumber_ The random number generated for the check (0-9999).
    function checkMutationSuccess(uint256 _bloomUnitId) external view onlyManaged(_bloomUnitId) returns (bool success_, uint256 effectiveChance_, uint256 randomNumber_) {
        BloomUnitData storage unitData = bloomUnits[_bloomUnitId];

         // Mutation only happens in the peak state (based on `triggerMutation` logic)
        if (unitData.bloomState != BloomState.Blooming) {
            return (false, 0, 0);
        }

        effectiveChance_ = mutationChance.mul(unitData.traitModifiers.mutationResistance).div(1e18); // Adjust for 1e18 multiplier

        // Generate a "random" number using block data (predictable!)
        randomNumber_ = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, _bloomUnitId, blockhash(block.number - 1)))) % 10000; // Number between 0-9999

        success_ = randomNumber_ < effectiveChance_;
        return (success_, effectiveChance_, randomNumber_);
    }


    // --- Fallback/Receive (Optional, but good practice) ---
    receive() external payable {
        revert("ETH not accepted");
    }

    fallback() external payable {
        revert("Calls not accepted");
    }
}
```