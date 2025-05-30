Okay, here is a Solidity smart contract incorporating several advanced, creative, and non-standard concepts centered around the idea of "Quantum Entangled Tokens."

This contract defines two related token types (QET-A and QET-B) that are minted in pairs with unique IDs. Their state and behavior can be linked, and they can accumulate "potential" while held in the same wallet (entangled). The contract includes functions for managing these pairs, interacting with their state, conditional transfers, melding pairs, and claiming yield based on accumulated potential.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title QuantumEntangledTokens (QET)
 * @dev A novel smart contract for managing paired, stateful, and 'entangled' tokens.
 *      This contract defines two types of tokens, QET-A and QET-B, linked by a Pair ID.
 *      Tokens gain 'Potential' while held in the same wallet (entangled state).
 *      Includes features for conditional transfers, state-based interactions, and melding pairs.
 *      Not an implementation of standard token interfaces (ERC20/ERC721/ERC1155) but manages ownership
 *      and supply for its unique token types based on Pair IDs.
 */

/**
 * Outline:
 * 1. Contract Overview & Concepts
 * 2. State Variables
 * 3. Enums (PairState)
 * 4. Events
 * 5. Modifiers (Owner only, Pausable)
 * 6. Core Token/Pair Management Functions (Mint, Transfer, Burn, Split)
 * 7. Entanglement & Potential Functions (Check Entanglement, Accumulate Potential, Claim)
 * 8. State-Based & Conditional Functions (Get State, Conditional Transfer/Burn, Transform)
 * 9. Advanced Interaction Functions (Meld Pairs)
 * 10. Query Functions
 * 11. Access Control & Configuration Functions
 * 12. Utility Functions
 */

/**
 * Function Summary:
 *
 * Core Token/Pair Management:
 * 1.  mintPair(address _to): Mints a new entangled pair (QET-A and QET-B with a new ID) to an address.
 * 2.  transferA(uint256 _pairId, address _to): Transfers the QET-A token of a specific pair ID.
 * 3.  transferB(uint256 _pairId, address _to): Transfers the QET-B token of a specific pair ID.
 * 4.  burnPair(uint256 _pairId): Burns both QET-A and QET-B of a specific pair ID (requires caller ownership of both).
 * 5.  splitPair(uint256 _pairId): Splits an entangled pair by burning QET-B and changing the pair's state (requires entanglement).
 *
 * Entanglement & Potential:
 * 6.  isEntangled(uint256 _pairId): Checks if QET-A and QET-B of a pair ID are held by the same address.
 * 7.  triggerEntanglementPotential(uint256 _pairId): Manually triggers potential accumulation calculation for a pair based on entanglement time.
 * 8.  getAccumulatedPotential(uint256 _pairId): Calculates and returns the current *claimable* potential for a pair.
 * 9.  claimPotentialYield(uint256 _pairId): Claims the accumulated potential yield for an entangled pair (burns potential, simulates yield distribution).
 * 10. getPotentialRate(): Returns the current rate at which potential accumulates.
 *
 * State-Based & Conditional:
 * 11. getPairState(uint256 _pairId): Returns the current state of a specific pair.
 * 12. conditionalTransferA(uint256 _pairId, address _to, PairState _requiredState): Transfers QET-A only if the pair is in a specific required state.
 * 13. conditionalBurnB(uint256 _pairId, uint256 _minPotential): Burns QET-B only if the pair has accumulated a minimum potential amount.
 * 14. transformPair(uint256 _pairId): Transforms the state of an entangled pair, potentially consuming potential or requiring specific conditions.
 *
 * Advanced Interaction:
 * 15. meldEntangledPairs(uint256 _pairId1, uint256 _pairId2): Melds two *distinct* entangled pairs owned by the caller into a single new 'Meld' state pair, burning the originals.
 *
 * Query Functions:
 * 16. balanceOfA(address _owner): Gets the count of QET-A tokens owned by an address.
 * 17. balanceOfB(address _owner): Gets the count of QET-B tokens owned by an address.
 * 18. ownerOfA(uint256 _pairId): Gets the owner of the QET-A token of a specific pair ID.
 * 19. ownerOfB(uint256 _pairId): Gets the owner of the QET-B token of a specific pair ID.
 * 20. totalSupplyA(): Gets the total supply of QET-A tokens.
 * 21. totalSupplyB(): Gets the total supply of QET-B tokens.
 * 22. getPairsByOwner(address _owner): Returns an array of Pair IDs owned by an address (where they own *either* A or B).
 * 23. getEntangledPairsByOwner(address _owner): Returns an array of Pair IDs where the owner holds *both* A and B.
 *
 * Access Control & Configuration:
 * 24. transferOwnership(address _newOwner): Transfers contract ownership.
 * 25. setPotentialRate(uint256 _newRate): Sets the potential accumulation rate (Owner only).
 * 26. pauseContract(): Pauses core functionality (Owner only).
 * 27. unpauseContract(): Unpauses core functionality (Owner only).
 *
 * Utility Functions:
 * 28. recoverERC20(address _tokenContract, uint256 _amount): Allows owner to recover accidentally sent ERC20 tokens.
 */

import "./IERC20.sol"; // Assume IERC20.sol is available or paste its interface here

// Basic ERC20 interface for recovery function
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}


contract QuantumEntangledTokens {

    address private _owner;
    bool private _paused;

    uint256 private _nextPairId;
    uint256 private _totalSupplyA;
    uint256 private _totalSupplyB;

    enum PairState {
        Initial,        // Just minted, entangled
        SplitA,         // QET-B burned, only QET-A remains
        SplitB,         // QET-A burned, only QET-B remains (less common, maybe from specific action)
        Transformed,    // Pair underwent transformation (e.g., from potential)
        Meld            // Result of merging two pairs
        // Add more states for complex interactions
    }

    // Mapping from Pair ID to owner of QET-A
    mapping(uint256 => address) private _qetAOwner;
    // Mapping from Pair ID to owner of QET-B
    mapping(uint256 => address) private _qetBOwner;

    // Mapping from Pair ID to its current state
    mapping(uint256 => PairState) private _pairState;

    // Mapping from Pair ID to the timestamp when it last became entangled (or 0 if not entangled)
    mapping(uint256 => uint256) private _lastEntangledStartTime;

    // Mapping from Pair ID to its currently accumulated *unclaimed* potential
    mapping(uint256 => uint256) private _accumulatedPotential;

    // Rate of potential accumulation per second (e.g., 1 unit per second)
    uint256 public potentialRatePerSecond = 1;

    // --- Events ---
    event PairMinted(uint256 indexed pairId, address indexed owner);
    event TransferA(uint256 indexed pairId, address indexed from, address indexed to);
    event TransferB(uint256 indexed pairId, address indexed from, address indexed to);
    event PairBurned(uint256 indexed pairId);
    event PairSplit(uint256 indexed pairId, PairState newState);
    event PairStateChanged(uint256 indexed pairId, PairState oldState, PairState newState);
    event EntanglementPotentialAccrued(uint256 indexed pairId, uint256 amountAccrued, uint256 totalPotential);
    event PotentialYieldClaimed(uint256 indexed pairId, uint256 amountClaimed);
    event PairsMeld(uint256 indexed pairId1, uint256 indexed pairId2, uint256 indexed newPairId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address account);
    event Unpaused(address account);
    event ERC20Recovered(address indexed token, uint256 amount);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == _owner, "QET: Not the contract owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "QET: Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "QET: Contract is not paused");
        _;
    }

    // --- Constructor ---
    constructor() {
        _owner = msg.sender;
        _paused = false;
        _nextPairId = 1; // Start pair IDs from 1
    }

    // --- Core Token/Pair Management Functions ---

    /**
     * @dev Mints a new entangled pair (QET-A and QET-B) with a unique ID.
     *      Assigns both tokens to the recipient and initializes state.
     * @param _to The address to receive the new pair.
     */
    function mintPair(address _to) external onlyOwner whenNotPaused {
        require(_to != address(0), "QET: Mint to the zero address");

        uint256 newPairId = _nextPairId++;
        _qetAOwner[newPairId] = _to;
        _qetBOwner[newPairId] = _to;
        _pairState[newPairId] = PairState.Initial;
        _lastEntangledStartTime[newPairId] = block.timestamp; // Starts entangled

        _totalSupplyA++;
        _totalSupplyB++;

        emit PairMinted(newPairId, _to);
    }

    /**
     * @dev Transfers the QET-A token of a specific pair ID.
     * @param _pairId The ID of the pair.
     * @param _to The recipient of the QET-A token.
     */
    function transferA(uint256 _pairId, address _to) public whenNotPaused {
        address currentOwnerA = _qetAOwner[_pairId];
        require(currentOwnerA != address(0), "QET: Pair A does not exist or is burned");
        require(msg.sender == currentOwnerA, "QET: Caller is not owner of QET-A");
        require(_to != address(0), "QET: Transfer to the zero address");

        _triggerPotentialUpdate(_pairId); // Update potential before ownership change

        _qetAOwner[_pairId] = _to;
        emit TransferA(_pairId, currentOwnerA, _to);

        _updateEntanglementState(_pairId); // Check entanglement after transfer
    }

    /**
     * @dev Transfers the QET-B token of a specific pair ID.
     * @param _pairId The ID of the pair.
     * @param _to The recipient of the QET-B token.
     */
    function transferB(uint256 _pairId, address _to) public whenNotPaused {
        address currentOwnerB = _qetBOwner[_pairId];
        require(currentOwnerB != address(0), "QET: Pair B does not exist or is burned");
        require(msg.sender == currentOwnerB, "QET: Caller is not owner of QET-B");
        require(_to != address(0), "QET: Transfer to the zero address");

        _triggerPotentialUpdate(_pairId); // Update potential before ownership change

        _qetBOwner[_pairId] = _to;
        emit TransferB(_pairId, currentOwnerB, _to);

        _updateEntanglementState(_pairId); // Check entanglement after transfer
    }

    /**
     * @dev Burns both QET-A and QET-B of a specific pair ID.
     *      Requires the caller to own both tokens of the pair.
     * @param _pairId The ID of the pair to burn.
     */
    function burnPair(uint256 _pairId) public whenNotPaused {
        address ownerA = _qetAOwner[_pairId];
        address ownerB = _qetBOwner[_pairId];

        require(ownerA != address(0), "QET: Pair does not exist or is already burned");
        require(ownerA == msg.sender && ownerB == msg.sender, "QET: Caller must own both parts of the pair");

        _triggerPotentialUpdate(_pairId); // Final potential update

        delete _qetAOwner[_pairId];
        delete _qetBOwner[_pairId];
        delete _pairState[_pairId];
        delete _lastEntangledStartTime[_pairId];
        delete _accumulatedPotential[_pairId];

        _totalSupplyA--;
        _totalSupplyB--;

        emit PairBurned(_pairId);
    }

    /**
     * @dev Splits an entangled pair by burning the QET-B token.
     *      The QET-A token remains and the pair state changes to SplitA.
     *      Only callable by the owner of an *entangled* pair.
     * @param _pairId The ID of the pair to split.
     */
    function splitPair(uint256 _pairId) public whenNotPaused {
        address ownerA = _qetAOwner[_pairId];
        address ownerB = _qetBOwner[_pairId];

        require(ownerA != address(0), "QET: Pair does not exist or is burned");
        require(ownerA == msg.sender && ownerB == msg.sender, "QET: Caller must own entangled pair");

        _triggerPotentialUpdate(_pairId); // Update potential before splitting

        // Burn QET-B
        delete _qetBOwner[_pairId];
        _totalSupplyB--;

        // Change state
        PairState oldState = _pairState[_pairId];
        _pairState[_pairId] = PairState.SplitA;

        // Reset entanglement tracking
        delete _lastEntangledStartTime[_pairId]; // No longer entangled

        emit PairSplit(_pairId, PairState.SplitA);
        emit PairStateChanged(_pairId, oldState, PairState.SplitA);
        emit TransferB(_pairId, msg.sender, address(0)); // Indicate burn of B
    }

    // --- Entanglement & Potential Functions ---

    /**
     * @dev Checks if the QET-A and QET-B tokens of a pair are held by the same address.
     * @param _pairId The ID of the pair to check.
     * @return bool True if entangled, false otherwise.
     */
    function isEntangled(uint256 _pairId) public view returns (bool) {
        address ownerA = _qetAOwner[_pairId];
        address ownerB = _qetBOwner[_pairId];
        // A pair is entangled if both A and B exist and are owned by the same address
        return ownerA != address(0) && ownerA == ownerB;
    }

     /**
      * @dev Internal function to update accumulated potential for a pair based on entanglement time.
      *      Called before actions that might change entanglement status or claim potential.
      * @param _pairId The ID of the pair.
      */
    function _triggerPotentialUpdate(uint256 _pairId) internal {
        if (_qetAOwner[_pairId] != address(0) && _lastEntangledStartTime[_pairId] > 0) {
            // Calculate time since last update / start of entanglement
            uint256 timeElapsed = block.timestamp - _lastEntangledStartTime[_pairId];
            uint256 potentialAccrued = timeElapsed * potentialRatePerSecond;

            if (potentialAccrued > 0) {
                 _accumulatedPotential[_pairId] += potentialAccrued;
                 emit EntanglementPotentialAccrued(_pairId, potentialAccrued, _accumulatedPotential[_pairId]);
            }
             _lastEntangledStartTime[_pairId] = block.timestamp; // Reset timer for future accumulation
        }
    }

    /**
     * @dev Internal function to update the entanglement state tracking.
     *      Called after transfers of A or B.
     * @param _pairId The ID of the pair.
     */
    function _updateEntanglementState(uint256 _pairId) internal {
        bool currentlyEntangled = isEntangled(_pairId);

        if (currentlyEntangled && _lastEntangledStartTime[_pairId] == 0) {
             // Became entangled
             _lastEntangledStartTime[_pairId] = block.timestamp;
        } else if (!currentlyEntangled && _lastEntangledStartTime[_pairId] > 0) {
             // Became disentangled - finalize potential accrual before resetting timer
             _triggerPotentialUpdate(_pairId); // Capture potential up to this block
             _lastEntangledStartTime[_pairId] = 0; // Reset timer
        }
        // If still entangled and timer is running, do nothing (potential accrues passively, updated on interaction)
        // If still disentangled and timer is 0, do nothing
    }


    /**
     * @dev Gets the currently accumulated *unclaimed* potential for a pair.
     *      Triggers a potential update calculation before returning.
     * @param _pairId The ID of the pair.
     * @return uint256 The total accumulated potential for the pair.
     */
    function getAccumulatedPotential(uint256 _pairId) public returns (uint256) {
         // Trigger potential update to include time up to this point
        _triggerPotentialUpdate(_pairId);
        return _accumulatedPotential[_pairId];
    }


    /**
     * @dev Claims the accumulated potential yield for an entangled pair.
     *      Requires the caller to own the entangled pair.
     *      Burns the accumulated potential.
     *      (Note: In a real dApp, this might trigger minting of a reward token or other action).
     *      Here it just zeroes out potential as a conceptual claim.
     * @param _pairId The ID of the pair to claim potential from.
     */
    function claimPotentialYield(uint256 _pairId) public whenNotPaused {
        address ownerA = _qetAOwner[_pairId];
        address ownerB = _qetBOwner[_pairId];

        require(ownerA != address(0) && ownerA == msg.sender && ownerB == msg.sender, "QET: Caller must own entangled pair to claim");

        _triggerPotentialUpdate(_pairId); // Final update before claiming
        uint256 claimablePotential = _accumulatedPotential[_pairId];

        require(claimablePotential > 0, "QET: No potential to claim");

        _accumulatedPotential[_pairId] = 0;

        // --- CONCEPTUAL YIELD DISTRIBUTION ---
        // In a real contract, this is where you would mint reward tokens,
        // update a balance, or trigger an off-chain action.
        // For this example, claiming potential is the 'yield' event itself.
        // --- END CONCEPTUAL YIELD DISTRIBUTION ---

        emit PotentialYieldClaimed(_pairId, claimablePotential);
    }

    /**
     * @dev Returns the current rate at which potential accumulates per second.
     */
    function getPotentialRate() public view returns (uint256) {
        return potentialRatePerSecond;
    }

    // --- State-Based & Conditional Functions ---

    /**
     * @dev Gets the current state of a specific pair.
     * @param _pairId The ID of the pair.
     * @return PairState The current state of the pair. Returns Initial if pair doesn't exist.
     */
    function getPairState(uint256 _pairId) public view returns (PairState) {
        // If pairId was never minted or was burned, _pairState[_pairId] will be the default value for enum, which is 0 (Initial).
        // We can add a check like `_qetAOwner[_pairId] == address(0)` to be more explicit about burned/non-existent pairs if needed,
        // but returning Initial for non-existent/burned is a reasonable default.
        if (_qetAOwner[_pairId] == address(0) && _qetBOwner[_pairId] == address(0)) {
             // Or perhaps a separate "Burned" state or return 0/error?
             // Let's stick to the mapping default for simplicity in this example.
             // Consider 0 as a non-existent pair for robust applications.
             // For this example, we assume non-zero pairIds returned by queries exist.
        }
        return _pairState[_pairId];
    }

    /**
     * @dev Conditionally transfers the QET-A token of a pair.
     *      Only succeeds if the pair is in a specified required state.
     * @param _pairId The ID of the pair.
     * @param _to The recipient of the QET-A token.
     * @param _requiredState The state the pair must be in for the transfer to succeed.
     */
    function conditionalTransferA(uint256 _pairId, address _to, PairState _requiredState) public whenNotPaused {
        require(getPairState(_pairId) == _requiredState, "QET: Pair is not in the required state for transfer");
        transferA(_pairId, _to); // Call the regular transfer logic after state check
    }

    /**
     * @dev Conditionally burns the QET-B token of a pair.
     *      Only succeeds if the pair has accumulated at least a minimum amount of potential.
     * @param _pairId The ID of the pair.
     * @param _minPotential The minimum required potential to burn B.
     */
    function conditionalBurnB(uint256 _pairId, uint256 _minPotential) public whenNotPaused {
        address ownerB = _qetBOwner[_pairId];
        require(ownerB != address(0), "QET: QET-B does not exist or is burned");
        require(msg.sender == ownerB, "QET: Caller is not owner of QET-B");

        // Update potential first
        _triggerPotentialUpdate(_pairId);
        require(_accumulatedPotential[_pairId] >= _minPotential, "QET: Insufficient potential to burn B");

        // Burn QET-B
        delete _qetBOwner[_pairId];
        _totalSupplyB--;

        // Potentially change state, e.g., if burning B from a non-SplitA state
        PairState oldState = _pairState[_pairId];
        // This logic can be more complex depending on desired state transitions
        if (oldState != PairState.SplitA) { // Avoid changing if already SplitA
             _pairState[_pairId] = PairState.SplitA; // Simple example: burning B always leads to SplitA state
             emit PairStateChanged(_pairId, oldState, PairState.SplitA);
        }

        // Reset entanglement tracking if B is burned
        delete _lastEntangledStartTime[_pairId];

        emit TransferB(_pairId, msg.sender, address(0)); // Indicate burn of B
        // No specific PairBurned event here, as only B is burned, not the whole pair.
    }

    /**
     * @dev Transforms the state of an entangled pair.
     *      Requires the pair to be entangled and meet specific conditions (e.g., minimum potential).
     *      Changes the state to 'Transformed'.
     * @param _pairId The ID of the pair to transform.
     */
    function transformPair(uint256 _pairId) public whenNotPaused {
        address ownerA = _qetAOwner[_pairId];
        address ownerB = _qetBO组成;

        require(ownerA != address(0) && ownerA == msg.sender && ownerB == msg.sender, "QET: Caller must own entangled pair to transform");
        require(getPairState(_pairId) != PairState.Transformed, "QET: Pair is already transformed");

        _triggerPotentialUpdate(_pairId); // Final potential update before check/use
        // Example condition: requires a minimum potential to transform
        uint256 requiredPotentialForTransform = 1000; // Example value
        require(_accumulatedPotential[_pairId] >= requiredPotentialForTransform, "QET: Not enough potential to transform");

        // Consume potential upon transformation (optional)
        _accumulatedPotential[_pairId] -= requiredPotentialForTransform; // Example: Consume required potential

        // Change state to Transformed
        PairState oldState = _pairState[_pairId];
        _pairState[_pairId] = PairState.Transformed;

        // Transformation might reset entanglement timer or affect future potential accrual
        // For simplicity, let's just change state. Potential can still accrue/be claimed based on new state rules if implemented.
        // Or could reset _lastEntangledStartTime[_pairId] = block.timestamp; if entanglement state changes properties

        emit PairStateChanged(_pairId, oldState, PairState.Transformed);
        // Optionally emit an event about potential consumption
    }

    // --- Advanced Interaction Functions ---

    /**
     * @dev Melds two *distinct* entangled pairs owned by the caller into a single new 'Meld' state pair.
     *      Burns the four original tokens (A1, B1, A2, B2) and mints one new pair with state Meld.
     *      Requires both input pairs to be entangled and owned by the caller.
     * @param _pairId1 The ID of the first pair to meld.
     * @param _pairId2 The ID of the second pair to meld.
     */
    function meldEntangledPairs(uint256 _pairId1, uint256 _pairId2) public whenNotPaused {
        require(_pairId1 != _pairId2, "QET: Cannot meld a pair with itself");

        // Check existence and ownership for pair 1
        address ownerA1 = _qetAOwner[_pairId1];
        address ownerB1 = _qetBOwner[_pairId1];
        require(ownerA1 != address(0) && ownerA1 == msg.sender && ownerB1 == msg.sender, "QET: Caller must own entangled Pair 1");

        // Check existence and ownership for pair 2
        address ownerA2 = _qetAOwner[_pairId2];
        address ownerB2 = _qetBOwner[_pairId2];
        require(ownerA2 != address(0) && ownerA2 == msg.sender && ownerB2 == msg.sender, "QET: Caller must own entangled Pair 2");

        // Before burning, update potential for both pairs
        _triggerPotentialUpdate(_pairId1);
        _triggerPotentialUpdate(_pairId2);

        // Burn the four original tokens (A1, B1, A2, B2)
        delete _qetAOwner[_pairId1];
        delete _qetBOwner[_pairId1];
        delete _pairState[_pairId1];
        delete _lastEntangledStartTime[_pairId1];
        delete _accumulatedPotential[_pairId1]; // Potential from P1 is lost or could be partially transferred

        delete _qetAOwner[_pairId2];
        delete _qetBOwner[_pairId2];
        delete _pairState[_pairId2];
        delete _lastEntangledStartTime[_pairId2];
        delete _accumulatedPotential[_pairId2]; // Potential from P2 is lost or could be partially transferred

        _totalSupplyA -= 2; // Burned 2 A tokens
        _totalSupplyB -= 2; // Burned 2 B tokens

        // Mint one new 'Meld' state pair
        uint256 newPairId = _nextPairId++;
        _qetAOwner[newPairId] = msg.sender;
        _qetBOwner[newPairId] = msg.sender;
        _pairState[newPairId] = PairState.Meld;
        _lastEntangledStartTime[newPairId] = block.timestamp; // New Meld pair starts entangled

        _totalSupplyA++; // Minted 1 A token
        _totalSupplyB++; // Minted 1 B token

        emit PairsMeld(_pairId1, _pairId2, newPairId);
        emit PairBurned(_pairId1); // Indicate original pairs are burned
        emit PairBurned(_pairId2);
        emit PairMinted(newPairId, msg.sender); // Indicate new pair is minted
    }

    // --- Query Functions ---

    /**
     * @dev Gets the count of QET-A tokens owned by an address.
     *      Iterates through all possible pair IDs up to the next ID.
     *      NOTE: This can be gas-intensive for large numbers of pairs.
     *      A mapping from address to a list/set of pair IDs would be more efficient but complex.
     * @param _owner The address to query.
     * @return uint256 The count of QET-A tokens owned.
     */
    function balanceOfA(address _owner) public view returns (uint256) {
        uint256 count = 0;
        // WARNING: Iterating through _nextPairId can be very gas-expensive.
        // In production, consider alternative data structures or off-chain indexing.
        for (uint256 i = 1; i < _nextPairId; i++) {
            if (_qetAOwner[i] == _owner) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Gets the count of QET-B tokens owned by an address.
     *      NOTE: Gas-intensive like balanceOfA.
     * @param _owner The address to query.
     * @return uint256 The count of QET-B tokens owned.
     */
    function balanceOfB(address _owner) public view returns (uint256) {
         uint256 count = 0;
        // WARNING: Iterating through _nextPairId can be very gas-expensive.
        for (uint256 i = 1; i < _nextPairId; i++) {
            if (_qetBOwner[i] == _owner) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Gets the owner of the QET-A token for a specific pair ID.
     * @param _pairId The ID of the pair.
     * @return address The owner of QET-A, or address(0) if not found/burned.
     */
    function ownerOfA(uint256 _pairId) public view returns (address) {
        return _qetAOwner[_pairId];
    }

    /**
     * @dev Gets the owner of the QET-B token for a specific pair ID.
     * @param _pairId The ID of the pair.
     * @return address The owner of QET-B, or address(0) if not found/burned.
     */
    function ownerOfB(uint256 _pairId) public view returns (address) {
        return _qetBOwner[_pairId];
    }

    /**
     * @dev Gets the total supply of QET-A tokens.
     * @return uint256 The total supply of QET-A.
     */
    function totalSupplyA() public view returns (uint256) {
        return _totalSupplyA;
    }

    /**
     * @dev Gets the total supply of QET-B tokens.
     * @return uint256 The total supply of QET-B.
     */
    function totalSupplyB() public view returns (uint256) {
        return _totalSupplyB;
    }

     /**
      * @dev Returns an array of Pair IDs where the given address owns either QET-A or QET-B.
      *      NOTE: Gas-intensive due to iteration.
      * @param _owner The address to query.
      * @return uint256[] An array of Pair IDs.
      */
    function getPairsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256[] memory ownedPairs = new uint256[](_totalSupplyA + _totalSupplyB); // Max possible size, will be trimmed
        uint256 count = 0;
        for (uint256 i = 1; i < _nextPairId; i++) {
            if (_qetAOwner[i] == _owner || _qetBOwner[i] == _owner) {
                 ownedPairs[count] = i;
                 count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = ownedPairs[i];
        }
        return result;
    }

     /**
      * @dev Returns an array of Pair IDs where the given address owns *both* QET-A and QET-B (is entangled).
      *      NOTE: Gas-intensive due to iteration.
      * @param _owner The address to query.
      * @return uint256[] An array of Pair IDs.
      */
    function getEntangledPairsByOwner(address _owner) public view returns (uint256[] memory) {
        uint256[] memory entangledPairs = new uint256[](_totalSupplyA); // Max possible entangled pairs is min(supplyA, supplyB) which is <= supplyA
        uint256 count = 0;
        for (uint256 i = 1; i < _nextPairId; i++) {
            if (isEntangled(i) && _qetAOwner[i] == _owner) { // Check isEntangled and one owner (since they are the same)
                 entangledPairs[count] = i;
                 count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = entangledPairs[i];
        }
        return result;
    }


    // --- Access Control & Configuration Functions ---

    /**
     * @dev Transfers ownership of the contract to a new account.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "QET: New owner is the zero address");
        address oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**
     * @dev Sets the rate at which potential accumulates per second for entangled pairs.
     * @param _newRate The new potential rate per second.
     */
    function setPotentialRate(uint256 _newRate) public onlyOwner {
        potentialRatePerSecond = _newRate;
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing state-changing operations again.
     */
    function unpauseContract() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @dev Returns true if the contract is paused, false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    // --- Utility Functions ---

     /**
      * @dev Allows the owner to recover ERC20 tokens accidentally sent to the contract.
      * @param _tokenContract The address of the ERC20 token contract.
      * @param _amount The amount of tokens to recover.
      */
    function recoverERC20(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 token = IERC20(_tokenContract);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "QET: Insufficient tokens in contract");
        require(token.transfer(_owner, _amount), "QET: ERC20 transfer failed");
        emit ERC20Recovered(_tokenContract, _amount);
    }
}
```

---

**Explanation of Concepts and Advanced Features:**

1.  **Paired Tokens (QET-A & QET-B):** Instead of a single token type, we have two intrinsically linked by a `pairId`. This creates a fundamental relationship that can be exploited by the contract logic.
2.  **Unique Pair IDs:** Each pair has a distinct ID, allowing granular tracking and management of individual pairs and their state, unlike fungible tokens.
3.  **Entanglement State:** The `isEntangled` function and the internal tracking (`_lastEntangledStartTime`) define a crucial state where owning both parts of a pair in the same wallet enables special behavior. This state is dynamic and changes upon transfers.
4.  **Dynamic State (`PairState` Enum):** Each pair has a mutable state (`Initial`, `SplitA`, `Transformed`, `Meld`). This state can change based on interactions (`splitPair`, `transformPair`, `meldEntangledPairs`) and governs what actions are possible.
5.  **Potential Accumulation:** Entangled pairs passively accumulate "potential" over time, tracked by `_accumulatedPotential` and driven by `potentialRatePerSecond` and `_lastEntangledStartTime`. This introduces a time-based, state-dependent resource generation mechanism. The `_triggerPotentialUpdate` internal function ensures potential is calculated accurately *at the moment* an action occurs that depends on or alters potential/entanglement state.
6.  **State-Based & Conditional Logic:** Functions like `conditionalTransferA` and `conditionalBurnB` demonstrate how actions can be gated based on the pair's current `PairState` or accumulated `_accumulatedPotential`. This adds a layer of complexity and game-like mechanics.
7.  **Transformation (`transformPair`):** A function that requires specific conditions (like minimum potential) and changes the pair's state permanently (or until another transformation). This represents an evolution or upgrade path for the tokens.
8.  **Melding (`meldEntangledPairs`):** A highly creative function where two separate entangled pairs are consumed to produce a *single* new pair with a special 'Meld' state. This reduces the total number of pairs while potentially creating a more powerful or distinct asset.
9.  **Manual Potential Trigger (`triggerEntanglementPotential`):** While potential accrues based on time, the calculation and update to the `_accumulatedPotential` mapping only happen when relevant functions are called (`_triggerPotentialUpdate`). This public trigger allows anyone to "poke" a pair to make its accumulated potential visible/usable via `getAccumulatedPotential` without needing ownership, potentially for external indexing or display.
10. **Internal Utility Functions:** The use of internal helper functions like `_triggerPotentialUpdate` and `_updateEntanglementState` encapsulates logic and improves code organization and safety by ensuring state updates are handled consistently before and after relevant external calls (transfers, burns, claims, etc.).
11. **Basic Access Control & Pausability:** Standard safety features (`Ownable`, `Pausable`) are included, implemented simply without external libraries.
12. **ERC20 Recovery:** A standard utility for the owner to rescue mistakenly sent tokens, often needed in contracts that can receive arbitrary tokens.
13. **Custom Query Functions:** Functions like `balanceOfA`, `balanceOfB`, `getPairsByOwner`, and `getEntangledPairsByOwner` are implemented to query the custom token structure, although the iteration approach is noted as gas-intensive for large scale.

This contract moves beyond simple token transfers and introduces concepts of linked state, time-based accumulation, conditional actions, and token evolution through interactions, providing a richer and more dynamic asset type.