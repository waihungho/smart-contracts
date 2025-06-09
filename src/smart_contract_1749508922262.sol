Okay, here is a Solidity smart contract incorporating an interesting, advanced, and creative concept I'll call "Quantum Entanglement Bonds".

This contract simulates a concept where users deposit a pair of assets to create linked "bond particles" (represented by ERC-1155 tokens). At a predefined "observation time," a random event "collapses" the state of the entangled pair into one of several correlated outcomes (e.g., 'Up-Down', 'Down-Up'). The final payout for each particle holder depends *probabilistically* on the specific collapsed state of *their* pair. This simulates entanglement by linking the probabilistic outcome of two tokens created together.

**Important Note:** True quantum entanglement cannot be replicated on a classical blockchain. This contract uses on-chain randomness (with the standard caveats about security) and correlated outcomes to *simulate* the concept in a simplified financial instrument. For production use involving significant value, a secure Verifiable Random Function (VRF) like Chainlink VRF or similar would be essential instead of the block hash method used here for demonstration.

---

**Outline and Function Summary**

**Contract:** `QuantumEntanglementBond`

**Concept:** A decentralized bond instrument simulating "quantum entanglement". Users deposit two different ERC-20 tokens (Token A and Token B) to create a pair of linked ERC-1155 "Bond Particle" tokens (Particle A and Particle B). At a set observation time, a random outcome determines the final "collapsed state" of the pair. Each collapsed state has a different payout multiplier for the deposited tokens. Particle holders can claim their payout after the observation based on their pair's final state.

**Key Features:**
*   Paired deposit of two distinct ERC-20 tokens.
*   Issuance of two linked ERC-1155 tokens per pair (`id_pair * 2` for Particle A, `id_pair * 2 + 1` for Particle B).
*   Simulated "Entanglement Observation" based on on-chain randomness.
*   Multiple possible "Collapsed States" for each pair after observation.
*   Configurable payout multipliers for each collapsed state.
*   Probabilistic outcome weights for collapsed states, settable by owner.
*   Separable Bond Particles (ERC-1155) that can be traded independently *before* observation, but the payout is tied to the pair's state determined at observation.
*   Claiming mechanism for particle holders based on the observed state.
*   Owner functions for configuration, management, and emergency actions.
*   Pausable functionality.

**Function Summary (25+ Functions):**

1.  `constructor`: Initializes the contract, sets owner, and sets the two required ERC-20 token addresses.
2.  `setPausableAdmin`: Sets the admin address for the Pausable contract.
3.  `pause`: Pauses the contract (only Pausable admin).
4.  `unpause`: Unpauses the contract (only Pausable admin).
5.  `setOwner`: Transfers ownership of the contract.
6.  `setEntangledTokens`: Sets the two ERC-20 token addresses required for pairing (can only be set once or by owner with restrictions).
7.  `setPayoutMultiplier`: Sets the payout multiplier for a specific `PairState`.
8.  `setObservationWeights`: Sets the probability weights for each non-initial `PairState` outcome during observation. Weights are relative.
9.  `setObservationTimeTemplate`: Sets the default observation time offset from creation for new pairs.
10. `setPairObservationTime`: Sets a specific observation time for an individual existing pair (before observation).
11. `createBondPairStep1`: User initiates pair creation by depositing Token A and defining Token B amount. Mints Particle A ERC-1155.
12. `createBondPairStep2`: User (or different user) completes pair creation by depositing Token B for an existing Step 1 pair. Mints Particle B ERC-1155.
13. `triggerObservation`: Triggers the observation process for a specific pair, determining its `observedState` based on weights and randomness. Can only be called after `observationTime`.
14. `batchTriggerObservation`: Triggers observation for a list of pairs.
15. `claimPayoutA`: Holder of Particle A (ERC-1155 with ID `pairId * 2`) claims their payout after observation.
16. `claimPayoutB`: Holder of Particle B (ERC-1155 with ID `pairId * 2 + 1`) claims their payout after observation.
17. `batchClaimPayouts`: Allows claiming payout for multiple bond particle token IDs (handling both A and B types).
18. `withdrawExcessTokens`: Allows the owner to withdraw ERC-20 tokens sent to the contract that are not part of active bonds or pending payouts.
19. `forceResolveStuckPair`: Owner can force a pair into a specific observed state (emergency use only).
20. `delegateObservationTrigger`: Owner can delegate the right to call `triggerObservation` to another address.
21. `revokeObservationTriggerDelegate`: Owner revokes the delegation.
22. `getPairDetails`: Returns all details for a specific bond pair.
23. `getPayoutMultiplier`: Returns the payout multiplier for a specific state.
24. `getObservationWeights`: Returns the current observation weights.
25. `getClaimableAmount`: Calculates the potential payout amount for a bond particle based on the pair's observed state.
26. `getTotalDeposited`: Returns the total amount of Token A or B currently held in the contract within active (not fully claimed) pairs.
27. `getObservationTriggerDelegate`: Returns the address currently delegated to trigger observations.
28. `getPairState`: Returns the current state of a specific bond pair.
29. `canTriggerObservation`: Checks if observation is ready to be triggered for a specific pair.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Supply.sol"; // For total supply tracking

/**
 * @title QuantumEntanglementBond
 * @dev A smart contract simulating "quantum entanglement" in a bond structure.
 * Users deposit a pair of assets (Token A and Token B) to create linked
 * ERC-1155 bond particle tokens. At an observation time, a random event
 * collapses the state of the pair, determining the payout based on configurable multipliers.
 *
 * This contract is a conceptual demonstration. On-chain randomness relies on block properties
 * and is NOT cryptographically secure for high-value applications. A VRF (like Chainlink VRF)
 * or other secure randomness source would be needed in production.
 */
contract QuantumEntanglementBond is ERC1155, Ownable, Pausable, ERC1155Supply {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Constants ---
    uint256 private constant TOKEN_A_SUFFIX = 0; // Used internally for pair ID to Particle A ID
    uint256 private constant TOKEN_B_SUFFIX = 1; // Used internally for pair ID to Particle B ID

    // --- State Variables ---
    IERC20 public tokenA; // Address of the first ERC-20 token for the pair
    IERC20 public tokenB; // Address of the second ERC-20 token for the pair
    bool private tokensSet = false; // Flag to ensure tokens are set only once initially

    // Enum representing the possible states of a bond pair
    enum PairState {
        Initial,       // Created with Token A deposited
        Paired,        // Created with both Token A and Token B deposited
        Observed_AA,   // Collapsed state AA
        Observed_AB,   // Collapsed state AB
        Observed_BA,   // Collapsed state BA
        Observed_BB,   // Collapsed state BB
        Matured        // Payout claimed by both parties
    }

    // Struct to store details of each bond pair
    struct BondPair {
        address depositorA;     // Address that initiated step 1 (deposited Token A)
        address depositorB;     // Address that completed step 2 (deposited Token B)
        uint256 amountA;        // Amount of Token A deposited
        uint256 amountB;        // Amount of Token B deposited
        uint64 creationTime;    // Timestamp of pair creation (step 2)
        uint64 observationTime; // Timestamp when observation can occur
        PairState state;        // Current state of the pair
        bool isClaimedA;        // Whether payout for Particle A has been claimed
        bool isClaimedB;        // Whether payout for Particle B has been claimed
    }

    // Mapping from pair ID to its BondPair details
    mapping(uint256 => BondPair) public bondPairs;

    // Counter for generating unique bond pair IDs
    Counters.Counter private _pairIds;

    // Mapping from PairState (observed) to payout multiplier (e.g., 1000 = 1x, 1500 = 1.5x)
    mapping(PairState => uint256) public payoutMultipliers;

    // Probability weights for observation outcomes (sum doesn't have to be 100, relative)
    // e.g., {Observed_AA: 30, Observed_AB: 70, Observed_BA: 50, Observed_BB: 20}
    mapping(PairState => uint256) public observationWeights;

    // Default offset from creation time for observation time (in seconds)
    uint64 public defaultObservationTimeOffset = 7 * 24 * 60 * 60; // 7 days

    // Address authorized to trigger observations (can be delegated by owner)
    address public observationTriggerDelegate;

    // --- Events ---
    event PairCreated(uint256 indexed pairId, address indexed depositorA, address indexed depositorB, uint256 amountA, uint256 amountB, uint64 creationTime, uint64 observationTime);
    event ObservationTriggered(uint256 indexed pairId, address indexed triggeredBy);
    event PairObserved(uint256 indexed pairId, PairState indexed observedState);
    event PayoutClaimed(uint256 indexed pairId, address indexed claimant, uint256 tokenId, uint256 amountA, uint256 amountB);
    event TokensSet(address indexed tokenA, address indexed tokenB);
    event ObservationTriggerDelegateUpdated(address indexed oldDelegate, address indexed newDelegate);

    // --- Constructor ---
    constructor(
        address _tokenA,
        address _tokenB,
        address pausableAdmin
    ) ERC1155("https://base_uri/{id}.json") Ownable(msg.sender) Pausable(pausableAdmin) {
        setEntangledTokens(_tokenA, _tokenB); // Set initial tokens
        observationTriggerDelegate = msg.sender; // Owner is initial delegate
    }

    // --- Modifiers ---
    modifier onlyInitializedTokens() {
        require(tokensSet, "Tokens not set");
        _;
    }

    modifier onlyPairCreatorOrApproved(uint256 _pairId) {
        BondPair storage pair = bondPairs[_pairId];
        require(msg.sender == pair.depositorA || msg.sender == pair.depositorB || isApprovedForAll(pair.depositorA, msg.sender) || isApprovedForAll(pair.depositorB, msg.sender), "Not pair creator or approved");
        _;
    }

    // --- Owner & Admin Functions ---

    /**
     * @dev See {Pausable-setPausableAdmin}.
     */
    function setPausableAdmin(address newAdmin) public virtual onlyOwner {
        _setPausableAdmin(newAdmin);
    }

    /**
     * @dev See {Pausable-pause}.
     */
    function pause() public virtual override onlyOwnerOrAdmin {
        _pause();
    }

    /**
     * @dev See {Pausable-unpause}.
     */
    function unpause() public virtual override onlyOwnerOrAdmin {
        _unpause();
    }

    /**
     * @dev Transfers ownership of the contract to a new account.
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) public virtual onlyOwner {
        transferOwnership(newOwner);
    }

    /**
     * @dev Sets the two ERC-20 token addresses used for pairing.
     * Can only be set once initially, or by owner if not yet used in a pair.
     * @param _tokenA The address of ERC-20 Token A.
     * @param _tokenB The address of ERC-20 Token B.
     */
    function setEntangledTokens(address _tokenA, address _tokenB) public onlyOwner whenNotPaused {
        require(!tokensSet || _pairIds.current() == 0, "Tokens already set and pairs created");
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
        require(_tokenA != _tokenB, "Token A and Token B must be different");

        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        tokensSet = true;
        emit TokensSet(_tokenA, _tokenB);
    }

    /**
     * @dev Sets the payout multiplier for a specific observed state.
     * The multiplier is represented as a scaled integer (e.g., 1500 for 1.5x).
     * Initial deposit is 1000 (1x). 0 means no payout for that state.
     * @param _state The observed PairState (Observed_AA, AB, BA, BB).
     * @param _multiplier The payout multiplier scaled by 1000 (e.g., 1000 for 1x).
     */
    function setPayoutMultiplier(PairState _state, uint256 _multiplier) public onlyOwner {
        require(_state >= PairState.Observed_AA && _state <= PairState.Observed_BB, "Invalid state");
        payoutMultipliers[_state] = _multiplier;
    }

    /**
     * @dev Sets the relative probability weights for observation outcomes.
     * The total sum of weights determines the denominator for probability calculation.
     * Only weights for Observed_AA, AB, BA, BB states are considered.
     * @param _weights An array of state/weight pairs.
     */
    function setObservationWeights(PairState[] memory _states, uint256[] memory _weights) public onlyOwner {
        require(_states.length == _weights.length, "Arrays must have same length");
        uint256 totalWeight = 0;
        // Reset existing weights first (optional, but safer)
        delete observationWeights[PairState.Observed_AA];
        delete observationWeights[PairState.Observed_AB];
        delete observationWeights[PairState.Observed_BA];
        delete observationWeights[PairState.Observed_BB];

        for (uint i = 0; i < _states.length; i++) {
            require(_states[i] >= PairState.Observed_AA && _states[i] <= PairState.Observed_BB, "Invalid state in weights");
            observationWeights[_states[i]] = _weights[i];
            totalWeight = totalWeight.add(_weights[i]);
        }
        require(totalWeight > 0, "Total observation weight must be positive");
    }

    /**
     * @dev Sets the default observation time offset from creation for new pairs.
     * @param _offsetInSeconds The time offset in seconds.
     */
    function setObservationTimeTemplate(uint64 _offsetInSeconds) public onlyOwner {
        defaultObservationTimeOffset = _offsetInSeconds;
    }

    /**
     * @dev Sets a specific observation time for an individual pair before it's observed.
     * Cannot set a time in the past relative to the current time.
     * @param _pairId The ID of the bond pair.
     * @param _observationTime The specific timestamp for observation.
     */
    function setPairObservationTime(uint256 _pairId, uint64 _observationTime) public onlyOwner whenNotPaused {
        BondPair storage pair = bondPairs[_pairId];
        require(pair.state == PairState.Paired, "Pair must be in Paired state");
        require(_observationTime > block.timestamp, "Observation time must be in the future");
        pair.observationTime = _observationTime;
    }

    /**
     * @dev Allows the owner to withdraw any ERC-20 tokens held by the contract
     * that are not currently allocated to active bond pairs or pending payouts.
     * Use with caution.
     * @param _token The address of the ERC-20 token to withdraw.
     * @param _amount The amount to withdraw.
     */
    function withdrawExcessTokens(address _token, uint256 _amount) public onlyOwner {
        require(_token != address(tokenA) && _token != address(tokenB), "Cannot withdraw active bond tokens this way");
        IERC20(_token).transfer(owner(), _amount);
    }

    /**
     * @dev Emergency function to force a pair into a specific observed state.
     * Should only be used to resolve stuck pairs due to unforeseen issues.
     * WARNING: Use of this function can bypass normal observation logic.
     * @param _pairId The ID of the bond pair.
     * @param _state The target observed state (Observed_AA, AB, BA, BB).
     */
    function forceResolveStuckPair(uint256 _pairId, PairState _state) public onlyOwner {
        BondPair storage pair = bondPairs[_pairId];
        require(pair.state < PairState.Observed_AA, "Pair already observed or claimed");
        require(_state >= PairState.Observed_AA && _state <= PairState.Observed_BB, "Invalid target state");

        pair.state = _state;
        emit PairObserved(_pairId, _state);
        emit ObservationTriggered(_pairId, msg.sender); // Log that it was triggered (manually)
    }

    /**
     * @dev Delegates the right to trigger observations to a specific address.
     * This is useful for allowing an automated system or trusted oracle keeper
     * to call the triggerObservation function at the appropriate time.
     * @param _delegate The address to delegate triggering rights to.
     */
    function delegateObservationTrigger(address _delegate) public onlyOwner {
        require(_delegate != address(0), "Delegate cannot be zero address");
        emit ObservationTriggerDelegateUpdated(observationTriggerDelegate, _delegate);
        observationTriggerDelegate = _delegate;
    }

    /**
     * @dev Revokes any previously set observation trigger delegate.
     * The owner will be the only address able to trigger observations again.
     */
    function revokeObservationTriggerDelegate() public onlyOwner {
        emit ObservationTriggerDelegateUpdated(observationTriggerDelegate, owner());
        observationTriggerDelegate = owner(); // Reset to owner
    }


    // --- Core Bond Lifecycle Functions ---

    /**
     * @dev Step 1: Initiates the creation of a bond pair.
     * User deposits Token A and specifies the desired amount of Token B for the pair.
     * Mints the Particle A ERC-1155 token for the depositor.
     * Requires approval for the contract to pull Token A.
     * @param _amountA The amount of Token A to deposit.
     * @param _amountB The amount of Token B planned for step 2.
     * @return pairId The ID of the newly created bond pair.
     */
    function createBondPairStep1(uint256 _amountA, uint256 _amountB) public whenNotPaused onlyInitializedTokens returns (uint256 pairId) {
        require(_amountA > 0 && _amountB > 0, "Amounts must be positive");

        // Pull Token A from the depositor
        tokenA.transferFrom(msg.sender, address(this), _amountA);

        // Generate a new pair ID
        _pairIds.increment();
        pairId = _pairIds.current();

        // Initialize the bond pair struct
        bondPairs[pairId] = BondPair({
            depositorA: msg.sender,
            depositorB: address(0), // Depositor B is unknown initially
            amountA: _amountA,
            amountB: _amountB,
            creationTime: 0, // Creation time set in step 2
            observationTime: 0, // Observation time set in step 2
            state: PairState.Initial,
            isClaimedA: false,
            isClaimedB: false
        });

        // Mint the Particle A token for this pair ID to the depositor
        uint256 particleAId = _getParticleAId(pairId);
        _mint(msg.sender, particleAId, 1, "");

        return pairId;
    }

    /**
     * @dev Step 2: Completes the creation of a bond pair initiated in Step 1.
     * User deposits Token B for a given pair ID.
     * Mints the Particle B ERC-1155 token for the depositor.
     * Updates the pair state, sets creation and observation times.
     * Requires approval for the contract to pull Token B.
     * @param _pairId The ID of the bond pair initiated in Step 1.
     * @param _amountB The amount of Token B to deposit. Must match the amount specified in Step 1.
     */
    function createBondPairStep2(uint256 _pairId, uint256 _amountB) public whenNotPaused onlyInitializedTokens {
        BondPair storage pair = bondPairs[_pairId];
        require(pair.state == PairState.Initial, "Pair not in Initial state");
        require(_amountB == pair.amountB, "Amount B must match step 1 definition");
        require(msg.sender != address(0), "Invalid sender address");

        // Pull Token B from the depositor
        tokenB.transferFrom(msg.sender, address(this), _amountB);

        // Update bond pair details
        pair.depositorB = msg.sender;
        pair.creationTime = uint64(block.timestamp);
        pair.observationTime = pair.creationTime + defaultObservationTimeOffset; // Use default offset
        pair.state = PairState.Paired;

        // Mint the Particle B token for this pair ID to the depositor
        uint256 particleBId = _getParticleBId(_pairId);
        _mint(msg.sender, particleBId, 1, "");

        emit PairCreated(_pairId, pair.depositorA, pair.depositorB, pair.amountA, pair.amountB, pair.creationTime, pair.observationTime);
    }

    /**
     * @dev Triggers the observation process for a specific bond pair.
     * This determines the final 'collapsed state' of the pair using randomness.
     * Can only be called after the pair's observationTime and if the pair is in Paired state.
     * Callable by owner or the observationTriggerDelegate.
     * @param _pairId The ID of the bond pair to observe.
     */
    function triggerObservation(uint256 _pairId) public whenNotPaused {
        require(msg.sender == owner() || msg.sender == observationTriggerDelegate, "Only owner or delegate can trigger");
        BondPair storage pair = bondPairs[_pairId];
        require(pair.state == PairState.Paired, "Pair not in Paired state");
        require(block.timestamp >= pair.observationTime, "Observation time not reached");

        _triggerObservationLogic(_pairId);
    }

    /**
     * @dev Triggers the observation process for multiple bond pairs in a batch.
     * Callable by owner or the observationTriggerDelegate.
     * @param _pairIds Array of bond pair IDs to observe.
     */
    function batchTriggerObservation(uint256[] memory _pairIds) public whenNotPaused {
        require(msg.sender == owner() || msg.sender == observationTriggerDelegate, "Only owner or delegate can trigger");
        for (uint i = 0; i < _pairIds.length; i++) {
             BondPair storage pair = bondPairs[_pairIds[i]];
             // Check conditions inline to avoid reverting the whole batch on one failure (except for sender)
             if (pair.state == PairState.Paired && block.timestamp >= pair.observationTime) {
                 _triggerObservationLogic(_pairIds[i]);
             }
        }
    }

    /**
     * @dev Claims the payout for the Particle A token holder of a specific pair.
     * Can only be called after observation and if the payout hasn't been claimed yet.
     * The payout amount depends on the observed state of the pair.
     * Requires the caller to hold the Particle A token for this pair.
     * @param _pairId The ID of the bond pair.
     */
    function claimPayoutA(uint256 _pairId) public whenNotPaused onlyInitializedTokens {
        BondPair storage pair = bondPairs[_pairId];
        uint256 particleAId = _getParticleAId(_pairId);
        require(balanceOf(msg.sender, particleAId) > 0, "Caller does not hold Particle A");
        require(pair.state >= PairState.Observed_AA && pair.state <= PairState.Observed_BB, "Pair not yet observed");
        require(!pair.isClaimedA, "Payout A already claimed");

        uint256 payoutAmountA = _calculatePayout(pair.amountA, pair.state);
        tokenA.transfer(msg.sender, payoutAmountA);

        pair.isClaimedA = true;
        _burn(msg.sender, particleAId, 1); // Burn the token upon claiming

        if (pair.isClaimedB) {
            pair.state = PairState.Matured; // Mark pair as fully matured
        }

        emit PayoutClaimed(_pairId, msg.sender, particleAId, payoutAmountA, 0);
    }

    /**
     * @dev Claims the payout for the Particle B token holder of a specific pair.
     * Can only be called after observation and if the payout hasn't been claimed yet.
     * The payout amount depends on the observed state of the pair.
     * Requires the caller to hold the Particle B token for this pair.
     * @param _pairId The ID of the bond pair.
     */
    function claimPayoutB(uint256 _pairId) public whenNotPaused onlyInitializedTokens {
        BondPair storage pair = bondPairs[_pairId];
        uint256 particleBId = _getParticleBId(_pairId);
        require(balanceOf(msg.sender, particleBId) > 0, "Caller does not hold Particle B");
        require(pair.state >= PairState.Observed_AA && pair.state <= PairState.Observed_BB, "Pair not yet observed");
        require(!pair.isClaimedB, "Payout B already claimed");

        uint256 payoutAmountB = _calculatePayout(pair.amountB, pair.state);
        tokenB.transfer(msg.sender, payoutAmountB);

        pair.isClaimedB = true;
        _burn(msg.sender, particleBId, 1); // Burn the token upon claiming

        if (pair.isClaimedA) {
            pair.state = PairState.Matured; // Mark pair as fully matured
        }

        emit PayoutClaimed(_pairId, msg.sender, particleBId, 0, payoutAmountB);
    }

     /**
     * @dev Claims payouts for multiple bond particle token IDs in a batch.
     * Automatically determines if the token ID is Particle A or Particle B
     * and claims the corresponding payout if available and owned by the caller.
     * @param _tokenIds Array of ERC-1155 token IDs (Particle A or B IDs).
     */
    function batchClaimPayouts(uint256[] memory _tokenIds) public whenNotPaused onlyInitializedTokens {
         for (uint i = 0; i < _tokenIds.length; i++) {
            uint256 tokenId = _tokenIds[i];
            require(balanceOf(msg.sender, tokenId) > 0, "Caller does not hold token ID");

            uint256 pairId;
            bool isParticleA;

            // Determine if it's Particle A or B ID and get the pair ID
            if (tokenId % 2 == TOKEN_A_SUFFIX) {
                pairId = tokenId / 2;
                isParticleA = true;
            } else if (tokenId % 2 == TOKEN_B_SUFFIX) {
                pairId = (tokenId - 1) / 2;
                isParticleA = false;
            } else {
                // Invalid token ID format, skip or revert? Skip for batch robustness.
                continue;
            }

            // Ensure pairId is valid and corresponds to a created pair
            if (pairId == 0 || pairId > _pairIds.current()) {
                 continue; // Skip invalid pair ID
            }

            BondPair storage pair = bondPairs[pairId];

            // Check if pair is observed and not already claimed for this particle type
            if (pair.state >= PairState.Observed_AA && pair.state <= PairState.Observed_BB) {
                 if (isParticleA && !pair.isClaimedA) {
                      uint256 payoutAmountA = _calculatePayout(pair.amountA, pair.state);
                      tokenA.transfer(msg.sender, payoutAmountA);
                      pair.isClaimedA = true;
                       _burn(msg.sender, tokenId, 1);
                       emit PayoutClaimed(pairId, msg.sender, tokenId, payoutAmountA, 0);
                       if (pair.isClaimedB) pair.state = PairState.Matured;
                 } else if (!isParticleA && !pair.isClaimedB) {
                      uint256 payoutAmountB = _calculatePayout(pair.amountB, pair.state);
                      tokenB.transfer(msg.sender, payoutAmountB);
                      pair.isClaimedB = true;
                       _burn(msg.sender, tokenId, 1);
                       emit PayoutClaimed(pairId, msg.sender, tokenId, 0, payoutAmountB);
                       if (pair.isClaimedA) pair.state = PairState.Matured;
                 }
            }
         }
    }


    // --- View Functions ---

    /**
     * @dev Returns details of a specific bond pair.
     * @param _pairId The ID of the bond pair.
     * @return depositorA The address that deposited Token A.
     * @return depositorB The address that deposited Token B.
     * @return amountA The amount of Token A deposited.
     * @return amountB The amount of Token B deposited.
     * @return creationTime The timestamp of pair creation.
     * @return observationTime The timestamp when observation can occur.
     * @return state The current state of the pair.
     * @return isClaimedA Whether payout for Particle A is claimed.
     * @return isClaimedB Whether payout for Particle B is claimed.
     */
    function getPairDetails(uint256 _pairId) public view returns (
        address depositorA,
        address depositorB,
        uint256 amountA,
        uint256 amountB,
        uint64 creationTime,
        uint64 observationTime,
        PairState state,
        bool isClaimedA,
        bool isClaimedB
    ) {
        BondPair storage pair = bondPairs[_pairId];
        return (
            pair.depositorA,
            pair.depositorB,
            pair.amountA,
            pair.amountB,
            pair.creationTime,
            pair.observationTime,
            pair.state,
            pair.isClaimedA,
            pair.isClaimedB
        );
    }

    /**
     * @dev Returns the payout multiplier for a given observed state.
     * @param _state The observed PairState.
     * @return The payout multiplier scaled by 1000.
     */
    function getPayoutMultiplier(PairState _state) public view returns (uint256) {
        require(_state >= PairState.Observed_AA && _state <= PairState.Observed_BB, "Invalid state");
        return payoutMultipliers[_state];
    }

    /**
     * @dev Returns the probability weights for observation outcomes.
     * @return states Array of observed PairStates.
     * @return weights Array of corresponding weights.
     */
    function getObservationWeights() public view returns (PairState[] memory states, uint256[] memory weights) {
        PairState[] memory observedStates = new PairState[](4);
        observedStates[0] = PairState.Observed_AA;
        observedStates[1] = PairState.Observed_AB;
        observedStates[2] = PairState.Observed_BA;
        observedStates[3] = PairState.Observed_BB;

        weights = new uint256[](4);
        weights[0] = observationWeights[PairState.Observed_AA];
        weights[1] = observationWeights[PairState.Observed_AB];
        weights[2] = observationWeights[PairState.Observed_BA];
        weights[3] = observationWeights[PairState.BB];

        return (observedStates, weights);
    }

     /**
     * @dev Calculates the potential claimable amount for a specific bond particle token ID
     * based on the pair's observed state. Returns 0 if not observed or already claimed.
     * @param _tokenId The ERC-1155 token ID (Particle A or B ID).
     * @return claimableAmount The amount of the corresponding token claimable.
     */
    function getClaimableAmount(uint256 _tokenId) public view returns (uint256 claimableAmount) {
        uint256 pairId;
        bool isParticleA;

        if (_tokenId % 2 == TOKEN_A_SUFFIX) {
            pairId = _tokenId / 2;
            isParticleA = true;
        } else if (_tokenId % 2 == TOKEN_B_SUFFIX) {
            pairId = (_tokenId - 1) / 2;
            isParticleA = false;
        } else {
            return 0; // Invalid token ID
        }

         // Ensure pairId is valid
        if (pairId == 0 || pairId > _pairIds.current()) {
             return 0;
        }

        BondPair storage pair = bondPairs[pairId];

        if (pair.state >= PairState.Observed_AA && pair.state <= PairState.Observed_BB) {
            if (isParticleA && !pair.isClaimedA) {
                 return _calculatePayout(pair.amountA, pair.state);
            } else if (!isParticleA && !pair.isClaimedB) {
                 return _calculatePayout(pair.amountB, pair.state);
            }
        }
        return 0; // Not observed, or already claimed, or invalid state
    }

     /**
     * @dev Gets the current state of a specific bond pair.
     * @param _pairId The ID of the bond pair.
     * @return The current PairState.
     */
    function getPairState(uint256 _pairId) public view returns (PairState) {
         // Ensure pairId is valid before accessing the mapping
         if (_pairId == 0 || _pairId > _pairIds.current()) {
              return PairState.Initial; // Or revert, depending on desired behavior for invalid IDs
         }
         return bondPairs[_pairId].state;
    }

    /**
     * @dev Checks if a specific pair is ready for observation triggering.
     * @param _pairId The ID of the bond pair.
     * @return True if the pair is in Paired state and observation time has passed.
     */
    function canTriggerObservation(uint256 _pairId) public view returns (bool) {
        // Ensure pairId is valid
         if (_pairId == 0 || _pairId > _pairIds.current()) {
              return false;
         }
        BondPair storage pair = bondPairs[_pairId];
        return pair.state == PairState.Paired && block.timestamp >= pair.observationTime;
    }


    /**
     * @dev Returns the total amount of Token A or Token B currently held within the contract
     * that corresponds to *active* bond pairs (not fully claimed).
     * This is different from the total contract balance, which might include excess tokens.
     * Calculation iterates through pairs, which might be gas-intensive for many pairs.
     * @param _tokenAddress The address of the token (tokenA or tokenB).
     * @return The total amount held in active pairs.
     */
    function getTotalDeposited(address _tokenAddress) public view returns (uint256) {
        require(_tokenAddress == address(tokenA) || _tokenAddress == address(tokenB), "Invalid token address");
        uint256 total = 0;
        uint256 currentPairId = _pairIds.current();

        // Warning: This loop can be gas-intensive for a large number of pairs.
        // For a production system with many pairs, consider a state variable
        // that tracks total deposits/claims incrementally.
        for (uint i = 1; i <= currentPairId; i++) {
            BondPair storage pair = bondPairs[i];
            if (pair.state != PairState.Initial && pair.state != PairState.Matured) {
                 if (_tokenAddress == address(tokenA) && !pair.isClaimedA) {
                     // Add original deposit amount for Particle A if not claimed
                     // Or add calculated payout if observed and not claimed?
                     // Let's add the original deposit amounts that are locked.
                     total = total.add(pair.amountA);
                 } else if (_tokenAddress == address(tokenB) && !pair.isClaimedB) {
                      total = total.add(pair.amountB);
                 }
            }
        }
        return total;
    }


    // --- Internal Helpers ---

    /**
     * @dev Internal function to get the ERC-1155 token ID for Particle A.
     * Particle A ID for pair N is (N * 2).
     */
    function _getParticleAId(uint256 _pairId) internal pure returns (uint256) {
        return _pairId.mul(2).add(TOKEN_A_SUFFIX);
    }

    /**
     * @dev Internal function to get the ERC-1155 token ID for Particle B.
     * Particle B ID for pair N is (N * 2) + 1.
     */
    function _getParticleBId(uint256 _pairId) internal pure returns (uint256) {
        return _pairId.mul(2).add(TOKEN_B_SUFFIX);
    }

    /**
     * @dev Internal logic for triggering observation on a pair.
     * Selects an observed state based on weights and randomness.
     * Updates the pair's state.
     * @param _pairId The ID of the bond pair.
     */
    function _triggerObservationLogic(uint256 _pairId) internal {
         BondPair storage pair = bondPairs[_pairId];

        // Ensure valid state before observation
        if (pair.state != PairState.Paired) {
            // Should ideally not happen if called correctly, but good safety check
            return;
        }

        // --- Simulate Randomness and State Collapse ---
        // WARNING: Using block.timestamp and block.difficulty/prevrandao is predictable.
        // Use a VRF like Chainlink VRF for secure randomness in production.
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.prevrandao, _pairId, msg.sender)));

        // Calculate total weight
        uint256 totalWeight = observationWeights[PairState.Observed_AA]
            .add(observationWeights[PairState.Observed_AB])
            .add(observationWeights[PairState.Observed_BA])
            .add(observationWeights[PairState.Observed_BB]);

        require(totalWeight > 0, "Observation weights not set or are zero");

        // Select outcome based on weighted randomness
        uint256 selection = randomNumber % totalWeight;

        PairState observedState;
        if (selection < observationWeights[PairState.Observed_AA]) {
            observedState = PairState.Observed_AA;
        } else if (selection < observationWeights[PairState.Observed_AA].add(observationWeights[PairState.Observed_AB])) {
            observedState = PairState.Observed_AB;
        } else if (selection < observationWeights[PairState.Observed_AA].add(observationWeights[PairState.Observed_AB]).add(observationWeights[PairState.Observed_BA])) {
            observedState = PairState.Observed_BA;
        } else {
            observedState = PairState.Observed_BB;
        }

        // Update the pair's state
        pair.state = observedState;

        emit ObservationTriggered(_pairId, msg.sender);
        emit PairObserved(_pairId, observedState);
    }

    /**
     * @dev Internal function to calculate the payout amount for a deposited amount
     * based on the observed state and configured multiplier.
     * Payout = amount * multiplier / 1000
     * @param _amount The initial deposited amount.
     * @param _state The observed state of the pair.
     * @return The calculated payout amount.
     */
    function _calculatePayout(uint256 _amount, PairState _state) internal view returns (uint256) {
        require(_state >= PairState.Observed_AA && _state <= PairState.Observed_BB, "Invalid state for payout calculation");
        uint256 multiplier = payoutMultipliers[_state];
        return _amount.mul(multiplier) / 1000; // Assuming multiplier is scaled by 1000
    }


    // --- ERC1155 Overrides ---

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     * Prevents transfers of Particle B until Particle A is minted for the pair.
     * Prevents transfers/burning after claiming (handled by burn in claim functions).
     */
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply) // Add ERC1155Supply override
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Custom logic: Ensure Particle B cannot be transferred before pair is fully created
        // And prevent transfers of Particle A or B *if* the pair is in Initial state (waiting for step 2)
        for (uint i = 0; i < ids.length; i++) {
            uint256 tokenId = ids[i];
            uint256 pairId;

            if (tokenId % 2 == TOKEN_A_SUFFIX) {
                pairId = tokenId / 2;
                // Transfers of A are allowed once minted
            } else if (tokenId % 2 == TOKEN_B_SUFFIX) {
                pairId = (tokenId - 1) / 2;
                 // Disallow transfer of B if the pair is still in the Initial state
                if (pairId > 0 && pairId <= _pairIds.current() && bondPairs[pairId].state == PairState.Initial) {
                    require(false, "Particle B cannot be transferred until pair is complete");
                }
            }
             // Optionally restrict transfers after observation or after claiming,
             // but burning upon claim handles post-claim transfer prevention.
             // Pre-observation transfers are allowed by design to enable trading the particle tokens.
        }
    }

    // The following functions are required by ERC1155Supply
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
```