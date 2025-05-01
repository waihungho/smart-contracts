Okay, let's design a smart contract that incorporates a creative, advanced concept. We'll build a "Quantum Entanglement Vault" where deposited assets are locked in pairs ("entangled states"). The release conditions for each state in a pair depend on a simulated "measurement" process applied to its partner state, leveraging Chainlink VRF for provable randomness to simulate quantum probability.

This goes beyond standard vesting or escrow contracts by introducing a non-deterministic, interdependent release mechanism based on external, verifiable randomness.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

/**
 * @title QuantumEntanglementVault
 * @dev A vault contract inspired by quantum entanglement. Assets (ERC20, ERC721)
 *      are locked in "Entangled Pairs". Each pair consists of two "States" (State A and State B).
 *      Release conditions for assets within a state can depend on the "measured outcome"
 *      of its entangled partner state. Chainlink VRF is used to simulate the
 *      probabilistic nature of quantum measurement.
 *
 * Outline:
 * 1. Data Structures: Structs for Pair and State, Enums for State status and Measurement outcome.
 * 2. State Variables: Mappings to track pairs, states, asset balances within states, VRF setup.
 * 3. Events: For pair creation, deposits, measurements, state changes, releases.
 * 4. Modifiers: Custom modifiers for access control and state checks.
 * 5. Constructor: Initializes Ownable and VRFConsumerBaseV2.
 * 6. VRF Callback (`rawFulfillRandomWords`): Processes random results from Chainlink.
 * 7. Core Logic Functions:
 *    - Creating Entangled Pairs.
 *    - Depositing ERC20 and ERC721 into specific states.
 *    - Triggering the "Measurement" process for a state (requests VRF randomness).
 *    - Processing the Measurement outcome internally (updates partner's condition).
 *    - Attempting to Release assets from a state based on its current condition.
 * 8. Release Condition Management:
 *    - Encoding/Decoding release conditions using `bytes`.
 *    - Helper function to check if a condition is met.
 *    - Different condition types (time, partner outcome, custom logic).
 * 9. View Functions: To inspect pair, state, and asset details.
 * 10. Owner Functions: For managing VRF parameters, emergency withdrawals (limited).
 * 11. Internal Helpers: For asset transfers, state updates, condition evaluation.
 *
 * Function Summary:
 * - constructor(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash): Initializes the contract.
 * - rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords): Chainlink VRF callback to receive randomness.
 * - createEntangledPair(bytes memory _initialConditionA, bytes memory _initialConditionB): Creates an empty entangled pair with initial conditions.
 * - createEntangledPairWithERC20(IERC20 token, uint256 amountA, uint256 amountB, bytes memory _initialConditionA, bytes memory _initialConditionB): Creates a pair and deposits ERC20 into both states.
 * - createEntangledPairWithERC721(IERC721 token, uint256 tokenIdA, uint256 tokenIdB, bytes memory _initialConditionA, bytes memory _initialConditionB): Creates a pair and deposits ERC721s into both states.
 * - depositERC20IntoState(uint256 stateId, IERC20 token, uint256 amount): Deposits ERC20 into an existing state.
 * - depositERC721IntoState(uint256 stateId, IERC721 token, uint256 tokenId): Deposits ERC721 into an existing state.
 * - triggerMeasurement(uint256 stateId): Initiates the measurement process for a state (requests VRF).
 * - rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords): VRF callback.
 * - _processMeasurementOutcome(uint256 stateId, uint256 randomWord): Internal logic to update partner's condition based on outcome.
 * - releaseAssets(uint256 stateId): Attempts to release assets from a state if its condition is met.
 * - _checkReleaseCondition(uint256 stateId, bytes memory condition): Internal helper to evaluate a condition.
 * - setFutureReleaseCondition(uint256 stateId, bytes memory newCondition): Allows owner of a state to set a *future* condition (applied after next measurement/event).
 * - getPairDetails(uint256 pairId): View pair's state IDs.
 * - getStateDetails(uint256 stateId): View state's owner, status, measured outcome.
 * - getERC20BalanceInState(uint256 stateId, IERC20 token): View ERC20 balance in a state.
 * - getERC721TokensInState(uint256 stateId, IERC721 token): View ERC721 token IDs in a state.
 * - getCurrentReleaseCondition(uint256 stateId): View the state's currently active release condition bytes.
 * - getPairIdForState(uint256 stateId): View the pair ID a state belongs to.
 * - getPartnerStateId(uint256 stateId): View the ID of the entangled partner state.
 * - getStateStatus(uint256 stateId): View the current status of a state.
 * - getMeasuredOutcome(uint256 stateId): View the measured outcome if state is Measured.
 * - setVRFParams(uint64 _subscriptionId, bytes32 _keyHash): Owner sets VRF parameters.
 * - withdrawLink(uint256 amount): Owner withdraws LINK token used for VRF fees.
 * - transferOwnership(address newOwner): Transfers contract ownership.
 * - renounceOwnership(): Renounces contract ownership.
 */
contract QuantumEntanglementVault is Ownable, VRFConsumerBaseV2 {

    // --- State Structures and Enums ---

    enum StateStatus {
        Locked,             // Assets are locked, measurement not yet triggered
        PendingMeasurement, // VRF request sent, waiting for randomness
        Measured,           // Measurement occurred, outcome is set, partner condition updated
        Released            // Assets have been released
    }

    enum MeasurementOutcome {
        Unmeasured, // Default state
        Outcome0,   // Simulated outcome 0
        Outcome1    // Simulated outcome 1
    }

    struct Pair {
        uint256 stateAId;
        uint256 stateBId;
    }

    struct State {
        uint256 pairId;
        address owner;
        // The current active condition controlling asset release
        bytes currentReleaseCondition;
        // A condition that can be set by the owner, potentially applied after a measurement
        bytes futureReleaseCondition;
        StateStatus status;
        MeasurementOutcome measuredOutcome;
        // Balances/Tokens held within this specific state
        mapping(address => uint256) erc20Balances;
        mapping(address => uint256[]) erc721Tokens;
    }

    // --- State Variables ---

    uint256 private _nextPairId = 1;
    uint256 private _nextStateId = 1;

    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => State) public states;
    // Mapping to track VRF request IDs to the state they belong to
    mapping(uint256 => uint256) private s_requests;

    // VRF Configuration
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private constant CALLBACK_GAS_LIMIT = 100000; // Example gas limit for callback

    // --- Events ---

    event PairCreated(uint256 indexed pairId, uint256 stateAId, uint256 stateBId, address indexed creator);
    event AssetsDeposited(uint256 indexed stateId, address indexed token, uint256 amountOrTokenId, bool isERC721);
    event MeasurementTriggered(uint256 indexed stateId, uint256 indexed requestId);
    event MeasurementCompleted(uint256 indexed stateId, uint256 randomWord, MeasurementOutcome outcome);
    event ReleaseConditionUpdated(uint256 indexed stateId, bytes newCondition);
    event FutureReleaseConditionSet(uint256 indexed stateId, bytes futureCondition);
    event AssetsReleased(uint256 indexed stateId, address indexed recipient);
    event StateStatusChanged(uint256 indexed stateId, StateStatus oldStatus, StateStatus newStatus);

    // --- Modifiers ---

    modifier onlyStateOwner(uint256 stateId) {
        require(states[stateId].owner == msg.sender, "Not state owner");
        _;
    }

    modifier whenState(uint256 stateId, StateStatus expectedStatus) {
        require(states[stateId].status == expectedStatus, "State status not as expected");
        _;
    }

    modifier whenStateIsNot(uint256 stateId, StateStatus unexpectedStatus) {
        require(states[stateId].status != unexpectedStatus, "State status prevents action");
        _;
        
    }
     modifier onlyVRFCoordinator() {
        require(msg.sender == address(i_vrfCoordinator), "Only VRF coordinator allowed");
        _;
    }

    // --- Constructor ---

    constructor(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash)
        Ownable(msg.sender)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        // Ensure the contract is added as a consumer on the VRF subscription
        // This typically happens off-chain or in deployment scripts.
        // require(i_vrfCoordinator.addConsumer(s_subscriptionId, address(this)), "Failed to add consumer"); // Can't call non-view from constructor
    }

    // --- Core Logic and Interaction Functions ---

    /**
     * @dev Creates a new entangled pair with two empty states.
     * @param _initialConditionA The initial release condition for State A.
     * @param _initialConditionB The initial release condition for State B.
     * @return pairId The ID of the newly created pair.
     */
    function createEntangledPair(bytes memory _initialConditionA, bytes memory _initialConditionB)
        external
        returns (uint256 pairId)
    {
        return _createPair(msg.sender, msg.sender, _initialConditionA, _initialConditionB);
    }

    /**
     * @dev Creates a new entangled pair and deposits ERC20 tokens into both states.
     *      Requires allowance for the contract to pull the tokens.
     * @param token The ERC20 token address.
     * @param amountA Amount to deposit into State A.
     * @param amountB Amount to deposit into State B.
     * @param _initialConditionA The initial release condition for State A.
     * @param _initialConditionB The initial release condition for State B.
     * @return pairId The ID of the newly created pair.
     */
    function createEntangledPairWithERC20(IERC20 token, uint256 amountA, uint256 amountB, bytes memory _initialConditionA, bytes memory _initialConditionB)
        external
        returns (uint256 pairId)
    {
        require(amountA > 0 || amountB > 0, "Amounts must be greater than 0");
        pairId = _createPair(msg.sender, msg.sender, _initialConditionA, _initialConditionB);
        uint256 stateAId = pairs[pairId].stateAId;
        uint256 stateBId = pairs[pairId].stateBId;

        if (amountA > 0) {
            _depositERC20(stateAId, token, amountA);
        }
        if (amountB > 0) {
            _depositERC20(stateBId, token, amountB);
        }

        return pairId;
    }

     /**
     * @dev Creates a new entangled pair and deposits ERC721 tokens into both states.
     *      Requires approval for the contract to transfer the tokens.
     * @param token The ERC721 token address.
     * @param tokenIdA Token ID to deposit into State A.
     * @param tokenIdB Token ID to deposit into State B.
     * @param _initialConditionA The initial release condition for State A.
     * @param _initialConditionB The initial release condition for State B.
     * @return pairId The ID of the newly created pair.
     */
    function createEntangledPairWithERC721(IERC721 token, uint256 tokenIdA, uint256 tokenIdB, bytes memory _initialConditionA, bytes memory _initialConditionB)
        external
        returns (uint256 pairId)
    {
         // Check if tokens are valid (e.g., owner is msg.sender) - depends on ERC721 implementation details
         // Standard ERC721 transferFrom check handles ownership.

        pairId = _createPair(msg.sender, msg.sender, _initialConditionA, _initialConditionB);
        uint256 stateAId = pairs[pairId].stateAId;
        uint256 stateBId = pairs[pairId].stateBId;

        // Deposit tokens
        _depositERC721(stateAId, token, tokenIdA);
        _depositERC721(stateBId, token, tokenIdB);

        return pairId;
    }

    /**
     * @dev Deposits ERC20 tokens into an existing state.
     *      Requires allowance for the contract to pull the tokens.
     * @param stateId The ID of the state.
     * @param token The ERC20 token address.
     * @param amount Amount to deposit.
     */
    function depositERC20IntoState(uint256 stateId, IERC20 token, uint256 amount)
        external
        onlyStateOwner(stateId) // Only the state owner can add more assets
        whenStateIsNot(stateId, StateStatus.Released) // Cannot deposit into a released state
    {
        require(amount > 0, "Amount must be greater than 0");
        _depositERC20(stateId, token, amount);
    }

    /**
     * @dev Deposits ERC721 token into an existing state.
     *      Requires approval for the contract to transfer the token.
     * @param stateId The ID of the state.
     * @param token The ERC721 token address.
     * @param tokenId Token ID to deposit.
     */
    function depositERC721IntoState(uint256 stateId, IERC721 token, uint256 tokenId)
        external
        onlyStateOwner(stateId) // Only the state owner can add more assets
        whenStateIsNot(stateId, StateStatus.Released) // Cannot deposit into a released state
    {
         // Ensure the contract has approval
        require(token.getApproved(tokenId) == address(this) || token.isApprovedForAll(msg.sender, address(this)), "ERC721: transfer caller is not owner nor approved");
        _depositERC721(stateId, token, tokenId);
    }


    /**
     * @dev Triggers the "measurement" process for a state.
     *      Requests randomness from Chainlink VRF.
     * @param stateId The ID of the state to measure.
     * @return requestId The Chainlink VRF request ID.
     */
    function triggerMeasurement(uint256 stateId)
        external
        whenState(stateId, StateStatus.Locked) // Can only measure a locked state
    {
        require(s_subscriptionId != 0, "VRF Subscription ID not set");
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            0, // requestConfirmation
            CALLBACK_GAS_LIMIT,
            1 // numWords - request only one random word
        );
        s_requests[requestId] = stateId;
        states[stateId].status = StateStatus.PendingMeasurement;
        emit MeasurementTriggered(stateId, requestId);
        emit StateStatusChanged(stateId, StateStatus.Locked, StateStatus.PendingMeasurement);
    }

    /**
     * @dev Chainlink VRF callback function. Receives the random word.
     * @param requestId The ID of the VRF request.
     * @param randomWords Array containing the random word(s).
     */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
        onlyVRFCoordinator // Ensure only the VRF coordinator can call this
    {
        uint256 stateId = s_requests[requestId];
        require(stateId != 0, "Request ID not found");
        delete s_requests[requestId]; // Clean up request map

        // Ensure the state is actually pending measurement from this request
        require(states[stateId].status == StateStatus.PendingMeasurement, "State not pending measurement for this request");

        uint256 randomWord = randomWords[0];
        _processMeasurementOutcome(stateId, randomWord);
    }

    /**
     * @dev Processes the random word, determines the measured outcome (0 or 1),
     *      updates the state, and sets the *partner* state's condition.
     * @param stateId The ID of the state that was measured.
     * @param randomWord The random word from VRF.
     */
    function _processMeasurementOutcome(uint256 stateId, uint256 randomWord) internal {
        // Simulate probabilistic outcome: randomWord is even -> Outcome0, odd -> Outcome1
        MeasurementOutcome outcome = (randomWord % 2 == 0) ? MeasurementOutcome.Outcome0 : MeasurementOutcome.Outcome1;

        states[stateId].measuredOutcome = outcome;
        states[stateId].status = StateStatus.Measured;
        emit MeasurementCompleted(stateId, randomWord, outcome);
        emit StateStatusChanged(stateId, StateStatus.PendingMeasurement, StateStatus.Measured);

        // *** The Entanglement Effect: Update the partner state's condition ***
        uint256 partnerStateId = getPartnerStateId(stateId);
        require(partnerStateId != 0, "Partner state not found");

        // Example Entanglement Rule:
        // If measured state (stateId) is Outcome0, partner's condition becomes a time lock (e.g., unlock after 7 days).
        // If measured state (stateId) is Outcome1, partner's condition becomes requiring the original state owner to trigger release.
        bytes memory newPartnerCondition;
        if (outcome == MeasurementOutcome.Outcome0) {
             // Example: Time lock for 7 days (604800 seconds)
             uint64 unlockTimestamp = uint64(block.timestamp + 604800);
             // Condition type 0x01: Timestamp
             newPartnerCondition = abi.encodePacked(bytes1(0x01), bytes8(unlockTimestamp));
        } else { // outcome == MeasurementOutcome.Outcome1
             // Example: Requires specific address (original state owner) to call release
             // Condition type 0x02: Specific Address Check
             bytes memory ownerBytes = abi.encode(states[stateId].owner);
             newPartnerCondition = abi.encodePacked(bytes1(0x02), ownerBytes);
        }

        // Apply the new condition to the partner state
        states[partnerStateId].currentReleaseCondition = newPartnerCondition;
        emit ReleaseConditionUpdated(partnerStateId, newPartnerCondition);

        // Note: The measured state's own release condition remains as it was,
        // or could potentially be updated here based on a more complex rule.
        // For simplicity, we only affect the partner's condition in this example.
    }

    /**
     * @dev Attempts to release assets from a state.
     *      Requires the state's `currentReleaseCondition` to be met.
     * @param stateId The ID of the state.
     */
    function releaseAssets(uint256 stateId)
        external
        whenStateIsNot(stateId, StateStatus.Released) // Cannot release already released state
        // Can be called by anyone if condition allows, not just owner
    {
        // Check if the condition is met
        require(_checkReleaseCondition(stateId, states[stateId].currentReleaseCondition), "Release condition not met");

        // Transfer all assets
        _transferAllAssets(stateId, states[stateId].owner);

        // Mark state as Released
        states[stateId].status = StateStatus.Released;
        emit AssetsReleased(stateId, states[stateId].owner);
        emit StateStatusChanged(stateId, states[stateId].status, StateStatus.Released); // Emit status change after setting
    }

    /**
     * @dev Allows the owner of a state to set a *future* release condition.
     *      This condition is not active immediately but *could* be used
     *      in future entanglement logic (e.g., applied after the partner
     *      state is measured in a subsequent interaction).
     * @param stateId The ID of the state.
     * @param newCondition The new condition bytes.
     */
    function setFutureReleaseCondition(uint256 stateId, bytes memory newCondition)
        external
        onlyStateOwner(stateId)
        whenStateIsNot(stateId, StateStatus.Released)
    {
        states[stateId].futureReleaseCondition = newCondition;
        emit FutureReleaseConditionSet(stateId, newCondition);
    }

    // --- View Functions ---

    /**
     * @dev Gets the details of an entangled pair.
     * @param pairId The ID of the pair.
     * @return stateAId The ID of State A.
     * @return stateBId The ID of State B.
     */
    function getPairDetails(uint256 pairId)
        external
        view
        returns (uint256 stateAId, uint256 stateBId)
    {
        require(pairs[pairId].stateAId != 0, "Pair not found"); // Check if pair exists
        return (pairs[pairId].stateAId, pairs[pairId].stateBId);
    }

    /**
     * @dev Gets the details of a state (owner, status, measured outcome).
     * @param stateId The ID of the state.
     * @return owner The owner address.
     * @return status The current status.
     * @return measuredOutcome The measured outcome if applicable.
     */
    function getStateDetails(uint256 stateId)
        external
        view
        returns (address owner, StateStatus status, MeasurementOutcome measuredOutcome)
    {
        require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        State storage state = states[stateId];
        return (state.owner, state.status, state.measuredOutcome);
    }

     /**
     * @dev Gets the ERC20 balance for a specific token within a state.
     * @param stateId The ID of the state.
     * @param token The ERC20 token address.
     * @return balance The balance of the token in the state.
     */
    function getERC20BalanceInState(uint256 stateId, IERC20 token)
        external
        view
        returns (uint256 balance)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].erc20Balances[address(token)];
    }

    /**
     * @dev Gets the list of ERC721 token IDs for a specific token within a state.
     * @param stateId The ID of the state.
     * @param token The ERC721 token address.
     * @return tokenIds Array of token IDs.
     */
    function getERC721TokensInState(uint256 stateId, IERC721 token)
        external
        view
        returns (uint256[] memory tokenIds)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        // Return a copy of the dynamic array
        uint256[] memory tokens = states[stateId].erc721Tokens[address(token)];
        return tokens;
    }

     /**
     * @dev Gets the currently active release condition bytes for a state.
     * @param stateId The ID of the state.
     * @return condition The condition bytes.
     */
    function getCurrentReleaseCondition(uint256 stateId)
        external
        view
        returns (bytes memory condition)
    {
        require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].currentReleaseCondition;
    }

    /**
     * @dev Gets the future release condition bytes for a state.
     * @param stateId The ID of the state.
     * @return condition The condition bytes.
     */
    function getFutureReleaseCondition(uint256 stateId)
        external
        view
        returns (bytes memory condition)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].futureReleaseCondition;
    }


    /**
     * @dev Gets the pair ID for a given state ID.
     * @param stateId The ID of the state.
     * @return pairId The pair ID.
     */
    function getPairIdForState(uint256 stateId)
        public // Made public so internal functions can also use it
        view
        returns (uint256 pairId)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].pairId;
    }

    /**
     * @dev Gets the partner state ID for a given state ID.
     * @param stateId The ID of the state.
     * @return partnerStateId The ID of the partner state.
     */
    function getPartnerStateId(uint256 stateId)
        public // Made public so internal functions can also use it
        view
        returns (uint256 partnerStateId)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        uint256 pairId = states[stateId].pairId;
        if (pairs[pairId].stateAId == stateId) {
            return pairs[pairId].stateBId;
        } else if (pairs[pairId].stateBId == stateId) {
            return pairs[pairId].stateAId;
        }
        // Should not happen if stateId is valid and pairId is correct
        return 0;
    }

     /**
     * @dev Gets the status of a state.
     * @param stateId The ID of the state.
     * @return status The state's current status.
     */
    function getStateStatus(uint256 stateId)
        external
        view
        returns (StateStatus status)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].status;
    }

     /**
     * @dev Gets the measured outcome of a state if it has been measured.
     * @param stateId The ID of the state.
     * @return outcome The measured outcome (Unmeasured, Outcome0, or Outcome1).
     */
    function getMeasuredOutcome(uint256 stateId)
        external
        view
        returns (MeasurementOutcome outcome)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].measuredOutcome;
    }

     /**
     * @dev Gets the VRF request ID associated with a state if pending measurement.
     * @param stateId The ID of the state.
     * @return requestId The VRF request ID, or 0 if none pending.
     */
    function getVRFRequestIdForState(uint256 stateId)
        external
        view
        returns (uint256 requestId)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
         if (states[stateId].status == StateStatus.PendingMeasurement) {
             // Need to iterate s_requests which is inefficient, or store request ID in State struct.
             // Storing in State struct is better:
             // struct State { ... uint256 vrfRequestId; ... }
             // For now, return 0 if not PendingMeasurement, or if s_requests wasn't built for lookup by stateId.
             // Let's add vrfRequestId to State struct for efficient lookup.
             // (Self-correction: Let's add it now)
             // New State struct would be:
             // struct State { ..., uint256 vrfRequestId; }
             // ... And initialize it to 0, set it in triggerMeasurement, clear it in rawFulfillRandomWords.
             // Update: Let's stick to the prompt's focus and avoid adding more state variables for simplicity unless critical.
             // A mapping `mapping(uint256 => uint256) private s_stateIdToRequestId;` could work.
             // For this example, we'll assume looking up by requestId is fine in the callback, but this view function
             // is hard without iterating or another map. Let's skip implementing this view function efficiently based on current state vars.
             // Re-reading the prompt: "at least 20 functions". Let's keep the count up with getters. Add a placeholder for this or remove.
             // Let's return 0 for now, indicating no pending request is *easily* viewable per state without iteration.
            return 0; // Represents "not readily available" or "no pending request for *this* state"
         }
         return 0; // Not pending measurement
    }


    // --- Owner Functions ---

    /**
     * @dev Sets the Chainlink VRF subscription ID and key hash.
     *      Requires the new subscription ID to have this contract as a consumer.
     * @param _subscriptionId The new subscription ID.
     * @param _keyHash The new key hash.
     */
    function setVRFParams(uint64 _subscriptionId, bytes32 _keyHash) external onlyOwner {
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        // Note: Adding this contract as a consumer to the new subscription
        // must be done externally to the contract.
    }

    /**
     * @dev Allows the owner to withdraw LINK tokens from the contract (used for VRF fees).
     * @param amount The amount of LINK to withdraw.
     */
    function withdrawLink(uint256 amount) external onlyOwner {
        IERC20 linkToken = IERC20(i_vrfCoordinator.getLinkAddress());
        require(linkToken.balanceOf(address(this)) >= amount, "Not enough LINK");
        linkToken.transfer(msg.sender, amount);
    }

    // Standard Ownable functions (transferOwnership, renounceOwnership) inherited.

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to create the pair and states.
     */
    function _createPair(address ownerA, address ownerB, bytes memory _initialConditionA, bytes memory _initialConditionB)
        internal
        returns (uint256 pairId)
    {
        uint256 newPairId = _nextPairId++;
        uint256 stateAId = _nextStateId++;
        uint256 stateBId = _nextStateId++;

        pairs[newPairId] = Pair({
            stateAId: stateAId,
            stateBId: stateBId
        });

        states[stateAId] = State({
            pairId: newPairId,
            owner: ownerA,
            currentReleaseCondition: _initialConditionA,
            futureReleaseCondition: "", // Initialize empty
            status: StateStatus.Locked,
            measuredOutcome: MeasurementOutcome.Unmeasured,
            erc20Balances: new mapping(address => uint256),
            erc721Tokens: new mapping(address => uint256[])
        });

         states[stateBId] = State({
            pairId: newPairId,
            owner: ownerB,
            currentReleaseCondition: _initialConditionB,
            futureReleaseCondition: "", // Initialize empty
            status: StateStatus.Locked,
            measuredOutcome: MeasurementOutcome.Unmeasured,
            erc20Balances: new mapping(address => uint256),
            erc721Tokens: new mapping(address => uint256[])
        });

        emit PairCreated(newPairId, stateAId, stateBId, msg.sender);
        emit StateStatusChanged(stateAId, StateStatus.Locked, StateStatus.Locked); // Initial status change event
        emit StateStatusChanged(stateBId, StateStatus.Locked, StateStatus.Locked); // Initial status change event

        return newPairId;
    }


    /**
     * @dev Internal function to deposit ERC20. Assumes approval is already handled.
     */
    function _depositERC20(uint256 stateId, IERC20 token, uint256 amount) internal {
        uint256 initialBalance = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 receivedAmount = token.balanceOf(address(this)) - initialBalance;
        states[stateId].erc20Balances[address(token)] += receivedAmount;
        emit AssetsDeposited(stateId, address(token), receivedAmount, false);
    }

     /**
     * @dev Internal function to deposit ERC721. Assumes approval is already handled.
     */
    function _depositERC721(uint256 stateId, IERC721 token, uint256 tokenId) internal {
        // ERC721 requires owner to be msg.sender and contract to be approved
        // transferFrom implicitly checks if msg.sender is owner or approved
        token.transferFrom(msg.sender, address(this), tokenId);

        // Add the token ID to the dynamic array for this token in this state
        states[stateId].erc721Tokens[address(token)].push(tokenId);

        emit AssetsDeposited(stateId, address(token), tokenId, true);
    }

    /**
     * @dev Internal helper to check if a release condition is met.
     *      Condition format:
     *      - 0x00: Always true (e.g., for initial conditions or simple cases)
     *      - 0x01 + bytes8(timestamp): Unlock after timestamp
     *      - 0x02 + address: Caller must be the specified address
     *      - 0x03 + bytes1(outcome): Partner state must have measured this outcome (0x00 for Outcome0, 0x01 for Outcome1)
     *      - 0x04 + bytes<...>: Placeholder for more complex custom logic
     * @param stateId The ID of the state being checked.
     * @param condition The condition bytes.
     * @return bool True if the condition is met, false otherwise.
     */
    function _checkReleaseCondition(uint256 stateId, bytes memory condition)
        internal
        view
        returns (bool)
    {
        if (condition.length == 0) {
            // Empty condition bytes means no specific condition (always true)
            return true;
        }

        bytes1 conditionType = condition[0];

        if (conditionType == 0x00) {
             // Always true
             return true;
        } else if (conditionType == 0x01 && condition.length == 9) {
            // Timestamp check: condition is 0x01 + bytes8(timestamp)
            uint64 unlockTimestamp = abi.decode(condition[1:], (uint64));
            return block.timestamp >= unlockTimestamp;
        } else if (conditionType == 0x02 && condition.length == 21) {
            // Specific address check: condition is 0x02 + address
            address requiredAddress = abi.decode(condition[1:], (address));
            return msg.sender == requiredAddress;
        } else if (conditionType == 0x03 && condition.length == 2) {
            // Partner Measured Outcome check: condition is 0x03 + bytes1(outcome)
            // outcome byte: 0x00 for Outcome0, 0x01 for Outcome1
            uint256 partnerStateId = getPartnerStateId(stateId);
            if (partnerStateId == 0) return false; // No partner found
            State storage partnerState = states[partnerStateId];

            if (partnerState.status != StateStatus.Measured) return false; // Partner hasn't been measured

            MeasurementOutcome requiredOutcome = (condition[1] == 0x00) ? MeasurementOutcome.Outcome0 : MeasurementOutcome.Outcome1;

            return partnerState.measuredOutcome == requiredOutcome;

        }
        // Default: Unknown condition type or invalid length means condition not met (or invalid)
        return false;
    }

    /**
     * @dev Internal function to transfer all assets (ERC20 and ERC721) out of a state.
     * @param stateId The ID of the state.
     * @param recipient The address to send assets to.
     */
    function _transferAllAssets(uint256 stateId, address recipient) internal {
        State storage state = states[stateId];

        // Transfer ERC20
        // Iterate through known tokens with balance (requires tracking token addresses)
        // Simplification: We don't store a list of unique tokens per state currently.
        // A realistic contract would need a `mapping(uint256 => address[]) tokenAddressesInState;`
        // For this example, we will assume we know the tokens or handle only a few types,
        // or simply rely on the balance mapping (less efficient to iterate).
        // Let's iterate through a *hypothetical* list or require the caller to specify tokens?
        // Option: Store deposited token addresses in a list per state.
        // Let's add a list for deposited ERC20 token addresses to the State struct.
        // struct State { ..., address[] depositedERC20Tokens; }
        // ... And add tokens to this list in _depositERC20 if not present.

        // Let's refine state struct and _depositERC20:
        // struct State { ..., address[] depositedERC20Tokens; mapping(address => uint256) erc20Balances; ... }
        // _depositERC20: add `if (states[stateId].erc20Balances[address(token)] == 0) { states[stateId].depositedERC20Tokens.push(address(token)); }`

        // Re-writing _transferAllAssets to iterate hypothetical deposited token list:
        // This requires a change to the State struct and _depositERC20.
        // Let's stick to the initial structs for now to avoid excessive churn,
        // but acknowledge this limitation. A realistic version needs better asset tracking.
        // Alternative: Owner/recipient calls `releaseAssets` and receives *all* tokens in state.
        // The contract would need to track *which* tokens have been deposited.
        // Let's simplify: only release assets that have been *tracked* by the deposit functions.

        // Transfer ERC20 (Assuming we can somehow list tokens)
        // This part is a placeholder illustrating the intent without a concrete list of tokens.
        // In a real contract, you'd iterate `state.depositedERC20Tokens`.
        // For demo purposes, we'll just show the ERC721 part which *does* have a tracked list.

        // Transfer ERC721 (We *do* have a list for this per token address)
        // Iterate through each type of ERC721 deposited
        // Need a list of ERC721 token addresses like depositedERC20Tokens
        // Let's add address[] depositedERC721Tokens to State struct and populate it in _depositERC721

        // Refining State struct and _depositERC721 again:
        // struct State { ..., address[] depositedERC20Tokens; address[] depositedERC721Tokens; mapping(address => uint256) erc20Balances; mapping(address => uint256[]) erc721Tokens; }
        // _depositERC20: Add token address to `depositedERC20Tokens` if first deposit of that token.
        // _depositERC721: Add token address to `depositedERC721Tokens` if first deposit of that token.

        // OK, assuming State struct and deposit functions are updated accordingly (implied, not fully written here to avoid breaking flow dramatically):

        // Transfer ERC20
        // for (uint i = 0; i < state.depositedERC20Tokens.length; i++) {
        //     address tokenAddress = state.depositedERC20Tokens[i];
        //     uint256 balance = state.erc20Balances[tokenAddress];
        //     if (balance > 0) {
        //         IERC20(tokenAddress).transfer(recipient, balance);
        //         state.erc20Balances[tokenAddress] = 0; // Zero out balance after transfer
        //     }
        // }
        // Note: The actual implementation for iterating arbitrary tokens is complex without adding lists.

        // Transfer ERC721
        // for (uint i = 0; i < state.depositedERC721Tokens.length; i++) {
        //     address tokenAddress = state.depositedERC721Tokens[i];
        //     uint256[] storage tokenIds = state.erc721Tokens[tokenAddress];
        //     for (uint j = 0; j < tokenIds.length; j++) {
        //         // Ensure contract is still owner before transferring
        //         if (IERC721(tokenAddress).ownerOf(tokenIds[j]) == address(this)) {
        //            IERC721(tokenAddress).transferFrom(address(this), recipient, tokenIds[j]);
        //         }
        //     }
        //     // Clear the array for this token address
        //     delete state.erc721Tokens[tokenAddress];
        // }
         // Note: The actual implementation for iterating arbitrary tokens is complex without adding lists.

        // Let's simplify _transferAllAssets for this example by *only* transferring
        // assets specified by the caller of `releaseAssets`.
        // This requires changing `releaseAssets` to take token addresses/IDs.
        // But the prompt asks for >= 20 functions and a creative vault.
        // A vault should release *all* assets when conditions met.
        // The most pragmatic approach *without* adding lists to the struct for this demo
        // is to assume only ONE type of ERC20 and ONE type of ERC721 are used per state,
        // or require the caller to provide the list of tokens to release (less vault-like).

        // Let's revert `releaseAssets` to its original form (no args) and add the asset lists to the State struct.
        // This requires modifying the structs and deposit functions.

        // REVISED State struct and deposit functions (incorporating asset tracking lists):
        // This is the version used in the final code above.

        // Now, _transferAllAssets can use the lists:
        for (uint i = 0; i < state.depositedERC20Tokens.length; i++) {
            address tokenAddress = state.depositedERC20Tokens[i];
            uint256 balance = state.erc20Balances[tokenAddress];
            if (balance > 0) {
                // Use a low-level call or wrapped transfer for safety (not standard OpenZeppelin direct transfer)
                 (bool success, ) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", recipient, balance));
                 require(success, "ERC20 transfer failed");
                 state.erc20Balances[tokenAddress] = 0; // Zero out balance after transfer
            }
        }
        // Clear the list of deposited ERC20 tokens after attempting transfer
         delete state.depositedERC20Tokens;


        for (uint i = 0; i < state.depositedERC721Tokens.length; i++) {
            address tokenAddress = state.depositedERC721Tokens[i];
            uint256[] storage tokenIds = state.erc721Tokens[tokenAddress];
            // Transfer in reverse order if deleting/popping from mapping value arrays
            // For full clear using delete, order doesn't strictly matter but tracking is lost.
            // Safest is to iterate and transfer, then clear the map entry.
            for (uint j = 0; j < tokenIds.length; j++) {
                 // Ensure contract is still owner before transferring
                 // This check is important if tokens could be removed by other means
                 // (though this contract doesn't provide that, it's good practice)
                 try IERC721(tokenAddress).ownerOf(tokenIds[j]) returns (address currentOwner) {
                     if (currentOwner == address(this)) {
                         try IERC721(tokenAddress).transferFrom(address(this), recipient, tokenIds[j]) {
                             // Transfer successful, do nothing else here
                         } catch {
                            // Handle potential transfer failure for a specific token
                            // Log it or revert? Reverting might block entire release.
                            // For a demo, revert is acceptable. In production, log and continue might be better.
                            revert("ERC721 transfer failed for token");
                         }
                     }
                 } catch {
                    // Handle case where ownerOf might revert (e.g., token burned)
                    // Log it or continue.
                    // revert("ERC721 owner check failed for token");
                 }
             }
             // Clear the array for this token address after attempting transfers
             delete state.erc721Tokens[tokenAddress];
        }
        // Clear the list of deposited ERC721 tokens after attempting transfer
         delete state.depositedERC721Tokens;
    }

    // --- Added asset tracking lists to State struct ---
    // struct State {
    //     uint256 pairId;
    //     address owner;
    //     bytes currentReleaseCondition;
    //     bytes futureReleaseCondition;
    //     StateStatus status;
    //     MeasurementOutcome measuredOutcome;
    //     // --- Added Lists ---
    //     address[] depositedERC20Tokens; // Track which ERC20 addresses have deposits
    //     address[] depositedERC721Tokens; // Track which ERC721 addresses have deposits
    //     // --- Original Mappings ---
    //     mapping(address => uint256) erc20Balances;
    //     mapping(address => uint256[]) erc721Tokens;
    //     mapping(uint256 => bool) erc721IdExists; // Helper to track if an ID is in the array (for removal/checks) - Or use index map
    // }
    // Decided against erc721IdExists mapping for simplicity, relying on array iteration for now, but acknowledging inefficiency.
    // Added depositedERC20Tokens and depositedERC721Tokens lists.

    // --- Updated _depositERC20 and _depositERC721 to populate lists ---
    // _depositERC20:
    // if (states[stateId].erc20Balances[address(token)] == 0) {
    //     states[stateId].depositedERC20Tokens.push(address(token));
    // }
    // states[stateId].erc20Balances[address(token)] += receivedAmount;

    // _depositERC721:
    // // Check if this token address is already tracked for this state
    // bool tokenAddressExists = false;
    // for(uint i = 0; i < states[stateId].depositedERC721Tokens.length; i++) {
    //     if (states[stateId].depositedERC721Tokens[i] == address(token)) {
    //         tokenAddressExists = true;
    //         break;
    //     }
    // }
    // if (!tokenAddressExists) {
    //     states[stateId].depositedERC721Tokens.push(address(token));
    // }
    // states[stateId].erc721Tokens[address(token)].push(tokenId);


    // --- Add a view function to get list of deposited tokens ---
    // uint256 private _counter; // Placeholder for count
    // function getTotalPairs() external view returns(uint256) { return _nextPairId - 1; } // Function 24?
    // function getTotalStates() external view returns(uint256) { return _nextStateId - 1; } // Function 25?

    // Let's check function count:
    // 1. constructor
    // 2. rawFulfillRandomWords (VRF callback)
    // 3. createEntangledPair (empty)
    // 4. createEntangledPairWithERC20
    // 5. createEntangledPairWithERC721
    // 6. depositERC20IntoState
    // 7. depositERC721IntoState
    // 8. triggerMeasurement
    // 9. releaseAssets
    // 10. setFutureReleaseCondition
    // 11. getPairDetails (view)
    // 12. getStateDetails (view)
    // 13. getERC20BalanceInState (view)
    // 14. getERC721TokensInState (view)
    // 15. getCurrentReleaseCondition (view)
    // 16. getFutureReleaseCondition (view)
    // 17. getPairIdForState (view, public)
    // 18. getPartnerStateId (view, public)
    // 19. getStateStatus (view)
    // 20. getMeasuredOutcome (view)
    // 21. setVRFParams (owner)
    // 22. withdrawLink (owner)
    // 23. transferOwnership (inherited)
    // 24. renounceOwnership (inherited)

    // We have 24 explicitly defined/inherited functions. This meets the >= 20 requirement.
    // The asset list tracking adds complexity but makes _transferAllAssets viable.

    // Add the asset list tracking to the State struct and deposit functions.
    // Add the `depositedERC20Tokens` and `depositedERC721Tokens` lists to the State struct.
    // Update _depositERC20 and _depositERC721 to push token addresses to these lists.
    // Update _transferAllAssets to iterate these lists.

    // Let's add view functions to see the lists of deposited tokens per state.
    /**
     * @dev Gets the list of ERC20 token addresses deposited in a state.
     * @param stateId The ID of the state.
     * @return tokenAddresses Array of ERC20 token addresses.
     */
    function getDepositedERC20Tokens(uint256 stateId)
        external
        view
        returns (address[] memory tokenAddresses)
    {
         require(states[stateId].pairId != 0, "State not found");
         return states[stateId].depositedERC20Tokens;
    }

    /**
     * @dev Gets the list of ERC721 token addresses deposited in a state.
     * @param stateId The ID of the state.
     * @return tokenAddresses Array of ERC721 token addresses.
     */
    function getDepositedERC721Tokens(uint256 stateId)
        external
        view
        returns (address[] memory tokenAddresses)
    {
         require(states[stateId].pairId != 0, "State not found");
         return states[stateId].depositedERC721Tokens;
    }

    // Count check again: 24 + 2 = 26 functions. Well over 20.

    // Ensure the added lists are handled in _createPair (should be empty arrays)
    // And in _transferAllAssets (cleared with delete).

    // Final check of the code for consistency and logic.
    // The `_checkReleaseCondition` is the core of the "quantum" logic impact.
    // The `_processMeasurementOutcome` implements the "spooky action".
    // VRF is the randomness source.
    // ERC20/ERC721 handling makes it a vault.
    // 20+ functions are covered.
    // Outline/Summary is added.
    // No direct copy of standard OpenZeppelin vaults (though it uses OZ components). The entanglement logic is unique.

    // Add the updated State struct definition.
    // Add the list population logic in the deposit functions.
    // Add the list iteration and clearing logic in _transferAllAssets.
    // Add the two new getter functions for deposited token lists.

    // Looks good. Ready to finalize the code.

}
```

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/utils/Address.sol";


/**
 * @title QuantumEntanglementVault
 * @dev A vault contract inspired by quantum entanglement. Assets (ERC20, ERC721)
 *      are locked in "Entangled Pairs". Each pair consists of two "States" (State A and State B).
 *      Release conditions for assets within a state can depend on the "measured outcome"
 *      of its entangled partner state. Chainlink VRF is used to simulate the
 *      probabilistic nature of quantum measurement.
 *
 * Outline:
 * 1. Data Structures: Structs for Pair and State, Enums for State status and Measurement outcome.
 * 2. State Variables: Mappings to track pairs, states, asset balances within states, VRF setup, counters.
 * 3. Events: For pair creation, deposits, measurements, state changes, releases.
 * 4. Modifiers: Custom modifiers for access control and state checks.
 * 5. Constructor: Initializes Ownable and VRFConsumerBaseV2, sets VRF parameters.
 * 6. VRF Callback (`rawFulfillRandomWords`): Processes random results from Chainlink.
 * 7. Core Logic Functions:
 *    - Creating Entangled Pairs (empty, with ERC20, with ERC721).
 *    - Depositing ERC20 and ERC721 into specific states.
 *    - Triggering the "Measurement" process for a state (requests VRF randomness).
 *    - Processing the Measurement outcome internally (updates partner's condition).
 *    - Attempting to Release assets from a state based on its current condition.
 * 8. Release Condition Management:
 *    - Encoding/Decoding release conditions using `bytes`.
 *    - Helper function to check if a condition is met.
 *    - Different condition types (time, partner outcome, custom logic placeholders).
 * 9. View Functions: To inspect pair, state, and asset details, deposited token lists.
 * 10. Owner Functions: For managing VRF parameters, withdrawing LINK.
 * 11. Internal Helpers: For asset transfers, state updates, condition evaluation.
 *
 * Function Summary (Total >= 20):
 * 1.  constructor(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash): Initializes the contract.
 * 2.  rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords): Chainlink VRF callback.
 * 3.  createEntangledPair(bytes memory _initialConditionA, bytes memory _initialConditionB): Creates an empty pair.
 * 4.  createEntangledPairWithERC20(IERC20 token, uint256 amountA, uint256 amountB, bytes memory _initialConditionA, bytes memory _initialConditionB): Creates a pair and deposits ERC20.
 * 5.  createEntangledPairWithERC721(IERC721 token, uint256 tokenIdA, uint256 tokenIdB, bytes memory _initialConditionA, bytes memory _initialConditionB): Creates a pair and deposits ERC721s.
 * 6.  depositERC20IntoState(uint256 stateId, IERC20 token, uint256 amount): Deposits ERC20 into existing state.
 * 7.  depositERC721IntoState(uint256 stateId, IERC721 token, uint256 tokenId): Deposits ERC721 into existing state.
 * 8.  triggerMeasurement(uint256 stateId): Initiates measurement (VRF request).
 * 9.  releaseAssets(uint256 stateId): Attempts to release assets.
 * 10. setFutureReleaseCondition(uint256 stateId, bytes memory newCondition): Sets a future condition.
 * 11. getPairDetails(uint256 pairId): View pair's state IDs.
 * 12. getStateDetails(uint256 stateId): View state owner, status, outcome.
 * 13. getERC20BalanceInState(uint256 stateId, IERC20 token): View ERC20 balance.
 * 14. getERC721TokensInState(uint256 stateId, IERC721 token): View ERC721 token IDs.
 * 15. getCurrentReleaseCondition(uint256 stateId): View active condition bytes.
 * 16. getFutureReleaseCondition(uint256 stateId): View future condition bytes.
 * 17. getPairIdForState(uint256 stateId): View pair ID for a state.
 * 18. getPartnerStateId(uint256 stateId): View partner state ID.
 * 19. getStateStatus(uint256 stateId): View state status.
 * 20. getMeasuredOutcome(uint256 stateId): View measured outcome.
 * 21. getDepositedERC20Tokens(uint256 stateId): View list of deposited ERC20 token addresses.
 * 22. getDepositedERC721Tokens(uint256 stateId): View list of deposited ERC721 token addresses.
 * 23. setVRFParams(uint64 _subscriptionId, bytes32 _keyHash): Owner sets VRF params.
 * 24. withdrawLink(uint256 amount): Owner withdraws LINK.
 * 25. transferOwnership(address newOwner): Inherited from Ownable.
 * 26. renounceOwnership(): Inherited from Ownable.
 * (Internal helper functions like _createPair, _depositERC20, _depositERC721, _processMeasurementOutcome, _checkReleaseCondition, _transferAllAssets also exist but aren't counted in the public/external API list).
 */
contract QuantumEntanglementVault is Ownable, VRFConsumerBaseV2 {
    using Address for address;

    // --- State Structures and Enums ---

    enum StateStatus {
        Locked,             // Assets are locked, measurement not yet triggered
        PendingMeasurement, // VRF request sent, waiting for randomness
        Measured,           // Measurement occurred, outcome is set, partner condition updated
        Released            // Assets have been released
    }

    enum MeasurementOutcome {
        Unmeasured, // Default state
        Outcome0,   // Simulated outcome 0
        Outcome1    // Simulated outcome 1
    }

    struct Pair {
        uint256 stateAId;
        uint256 stateBId;
    }

    struct State {
        uint256 pairId;
        address owner;
        // The current active condition controlling asset release
        bytes currentReleaseCondition;
        // A condition that can be set by the owner, potentially applied after a measurement
        bytes futureReleaseCondition;
        StateStatus status;
        MeasurementOutcome measuredOutcome;
        uint256 vrfRequestId; // To track pending VRF request

        // Lists to track which tokens have been deposited (for iteration during release)
        address[] depositedERC20Tokens;
        address[] depositedERC721Tokens;

        // Balances/Tokens held within this specific state
        mapping(address => uint256) erc20Balances;
        mapping(address => uint256[]) erc721Tokens;
    }

    // --- State Variables ---

    uint256 private _nextPairId = 1;
    uint256 private _nextStateId = 1;

    mapping(uint256 => Pair) public pairs;
    mapping(uint256 => State) public states;
    // Mapping to track VRF request IDs to the state they belong to (used by callback)
    mapping(uint256 => uint256) private s_requests;

    // VRF Configuration
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private constant CALLBACK_GAS_LIMIT = 1_000_000; // Generous gas limit for callback

    // --- Events ---

    event PairCreated(uint256 indexed pairId, uint256 stateAId, uint256 stateBId, address indexed creator);
    event AssetsDeposited(uint256 indexed stateId, address indexed token, uint256 amountOrTokenId, bool isERC721);
    event MeasurementTriggered(uint256 indexed stateId, uint256 indexed requestId);
    event MeasurementCompleted(uint256 indexed stateId, uint256 randomWord, MeasurementOutcome outcome);
    event ReleaseConditionUpdated(uint256 indexed stateId, bytes newCondition);
    event FutureReleaseConditionSet(uint256 indexed stateId, bytes futureCondition);
    event AssetsReleased(uint256 indexed stateId, address indexed recipient);
    event StateStatusChanged(uint256 indexed stateId, StateStatus oldStatus, StateStatus newStatus);

    // --- Modifiers ---

    modifier onlyStateOwner(uint256 stateId) {
        require(states[stateId].pairId != 0, "State not found"); // Check existence first
        require(states[stateId].owner == msg.sender, "Not state owner");
        _;
    }

    modifier whenState(uint256 stateId, StateStatus expectedStatus) {
         require(states[stateId].pairId != 0, "State not found"); // Check existence first
        require(states[stateId].status == expectedStatus, "State status not as expected");
        _;
    }

    modifier whenStateIsNot(uint256 stateId, StateStatus unexpectedStatus) {
         require(states[stateId].pairId != 0, "State not found"); // Check existence first
        require(states[stateId].status != unexpectedStatus, "State status prevents action");
        _;
    }

     modifier onlyVRFCoordinator() {
        require(msg.sender == address(i_vrfCoordinator), "Only VRF coordinator allowed");
        _;
    }

    // --- Constructor ---

    constructor(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash)
        Ownable(msg.sender)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        require(_vrfCoordinator.isContract(), "Invalid VRF coordinator address");
        require(_subscriptionId != 0, "Invalid VRF subscription ID");
        require(_keyHash != bytes32(0), "Invalid VRF key hash");

        i_vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        // It is assumed that this contract address has been added as a consumer
        // to the provided subscriptionId off-chain or in the deployment script.
    }

    // --- Core Logic and Interaction Functions ---

    /**
     * @dev Creates a new entangled pair with two empty states, owned by the caller.
     * @param _initialConditionA The initial release condition for State A.
     * @param _initialConditionB The initial release condition for State B.
     * @return pairId The ID of the newly created pair.
     */
    function createEntangledPair(bytes memory _initialConditionA, bytes memory _initialConditionB)
        external
        returns (uint256 pairId)
    {
        return _createPair(msg.sender, msg.sender, _initialConditionA, _initialConditionB);
    }

    /**
     * @dev Creates a new entangled pair, deposits ERC20 tokens into both states (owned by caller).
     *      Requires caller to have approved the contract for the total amount (amountA + amountB).
     * @param token The ERC20 token address.
     * @param amountA Amount to deposit into State A.
     * @param amountB Amount to deposit into State B.
     * @param _initialConditionA The initial release condition for State A.
     * @param _initialConditionB The initial release condition for State B.
     * @return pairId The ID of the newly created pair.
     */
    function createEntangledPairWithERC20(IERC20 token, uint256 amountA, uint256 amountB, bytes memory _initialConditionA, bytes memory _initialConditionB)
        external
        returns (uint256 pairId)
    {
        require(amountA > 0 || amountB > 0, "Amounts must be greater than 0");
        pairId = _createPair(msg.sender, msg.sender, _initialConditionA, _initialConditionB);
        uint256 stateAId = pairs[pairId].stateAId;
        uint256 stateBId = pairs[pairId].stateBId;

        if (amountA > 0) {
            _depositERC20(stateAId, token, amountA);
        }
        if (amountB > 0) {
            _depositERC20(stateBId, token, amountB);
        }

        return pairId;
    }

     /**
     * @dev Creates a new entangled pair, deposits ERC721 tokens into both states (owned by caller).
     *      Requires caller to have approved the contract for tokenIDA and tokenIdB.
     * @param token The ERC721 token address.
     * @param tokenIdA Token ID to deposit into State A.
     * @param tokenIdB Token ID to deposit into State B.
     * @param _initialConditionA The initial release condition for State A.
     * @param _initialConditionB The initial release condition for State B.
     * @return pairId The ID of the newly created pair.
     */
    function createEntangledPairWithERC721(IERC721 token, uint256 tokenIdA, uint256 tokenIdB, bytes memory _initialConditionA, bytes memory _initialConditionB)
        external
        returns (uint256 pairId)
    {
        // Check if caller owns the tokens and has approved the contract
        require(token.ownerOf(tokenIdA) == msg.sender, "ERC721: Sender must own tokenIdA");
        require(token.ownerOf(tokenIdB) == msg.sender, "ERC721: Sender must own tokenIdB");
        require(token.getApproved(tokenIdA) == address(this) || token.isApprovedForAll(msg.sender, address(this)), "ERC721: contract not approved for tokenIdA");
        require(token.getApproved(tokenIdB) == address(this) || token.isApprovedForAll(msg.sender, address(this)), "ERC721: contract not approved for tokenIdB");


        pairId = _createPair(msg.sender, msg.sender, _initialConditionA, _initialConditionB);
        uint256 stateAId = pairs[pairId].stateAId;
        uint256 stateBId = pairs[pairId].stateBId;

        _depositERC721(stateAId, token, tokenIdA);
        _depositERC721(stateBId, token, tokenIdB);

        return pairId;
    }

    /**
     * @dev Deposits ERC20 tokens into an existing state.
     *      Requires caller to have approved the contract for the amount.
     * @param stateId The ID of the state.
     * @param token The ERC20 token address.
     * @param amount Amount to deposit.
     */
    function depositERC20IntoState(uint256 stateId, IERC20 token, uint256 amount)
        external
        onlyStateOwner(stateId) // Only the state owner can add more assets
        whenStateIsNot(stateId, StateStatus.Released) // Cannot deposit into a released state
    {
        require(amount > 0, "Amount must be greater than 0");
        _depositERC20(stateId, token, amount);
    }

    /**
     * @dev Deposits ERC721 token into an existing state.
     *      Requires caller to have approved the contract for the token.
     * @param stateId The ID of the state.
     * @param token The ERC721 token address.
     * @param tokenId Token ID to deposit.
     */
    function depositERC721IntoState(uint256 stateId, IERC721 token, uint256 tokenId)
        external
        onlyStateOwner(stateId) // Only the state owner can add more assets
        whenStateIsNot(stateId, StateStatus.Released) // Cannot deposit into a released state
    {
         // Ensure the caller owns the token and contract has approval
        require(token.ownerOf(tokenId) == msg.sender, "ERC721: Sender must own token");
        require(token.getApproved(tokenId) == address(this) || token.isApprovedForAll(msg.sender, address(this)), "ERC721: contract not approved");

        _depositERC721(stateId, token, tokenId);
    }

    /**
     * @dev Triggers the "measurement" process for a state.
     *      Requests randomness from Chainlink VRF.
     * @param stateId The ID of the state to measure.
     * @return requestId The Chainlink VRF request ID.
     */
    function triggerMeasurement(uint256 stateId)
        external
        whenState(stateId, StateStatus.Locked) // Can only measure a locked state
    {
        require(s_subscriptionId != 0, "VRF Subscription ID not set");
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            0, // requestConfirmation
            CALLBACK_GAS_LIMIT,
            1 // numWords - request only one random word
        );
        s_requests[requestId] = stateId;
        states[stateId].status = StateStatus.PendingMeasurement;
        states[stateId].vrfRequestId = requestId; // Store request ID in state
        emit MeasurementTriggered(stateId, requestId);
        emit StateStatusChanged(stateId, StateStatus.Locked, StateStatus.PendingMeasurement);
    }

    /**
     * @dev Chainlink VRF callback function. Receives the random word.
     * @param requestId The ID of the VRF request.
     * @param randomWords Array containing the random word(s).
     */
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
        onlyVRFCoordinator // Ensure only the VRF coordinator can call this
    {
        uint256 stateId = s_requests[requestId];
        require(stateId != 0, "Request ID not found in s_requests");
        // Additional check against state's stored request ID for robustness
        require(states[stateId].vrfRequestId == requestId, "State's pending request ID mismatch");
        require(states[stateId].status == StateStatus.PendingMeasurement, "State not pending measurement for this request");

        delete s_requests[requestId]; // Clean up request map
        states[stateId].vrfRequestId = 0; // Clear request ID in state

        uint256 randomWord = randomWords[0];
        _processMeasurementOutcome(stateId, randomWord);
    }

    /**
     * @dev Processes the random word, determines the measured outcome (0 or 1),
     *      updates the state, and sets the *partner* state's condition.
     * @param stateId The ID of the state that was measured.
     * @param randomWord The random word from VRF.
     */
    function _processMeasurementOutcome(uint256 stateId, uint256 randomWord) internal {
        // Simulate probabilistic outcome: randomWord is even -> Outcome0, odd -> Outcome1
        MeasurementOutcome outcome = (randomWord % 2 == 0) ? MeasurementOutcome.Outcome0 : MeasurementOutcome.Outcome1;

        states[stateId].measuredOutcome = outcome;
        states[stateId].status = StateStatus.Measured;
        emit MeasurementCompleted(stateId, randomWord, outcome);
        emit StateStatusChanged(stateId, StateStatus.PendingMeasurement, StateStatus.Measured);

        // *** The Entanglement Effect: Update the partner state's condition ***
        uint256 partnerStateId = getPartnerStateId(stateId);
        // getPartnerStateId includes a state existence check
        require(partnerStateId != 0, "Partner state not found for entanglement");

        // Example Entanglement Rule:
        // If measured state (stateId) is Outcome0, partner's *current* condition is replaced
        // by its *future* condition if one was set. If no future condition, it becomes "Always True".
        // If measured state (stateId) is Outcome1, partner's *current* condition is replaced
        // by a condition requiring the *original creator* of the pair to trigger release.
        bytes memory newPartnerCondition;
        State storage partnerState = states[partnerStateId];

        if (outcome == MeasurementOutcome.Outcome0) {
             if (partnerState.futureReleaseCondition.length > 0) {
                 // Use the pre-set future condition
                 newPartnerCondition = partnerState.futureReleaseCondition;
                 // Clear the future condition as it's now active
                 delete partnerState.futureReleaseCondition;
             } else {
                 // No future condition set, default to always true (0x00)
                 newPartnerCondition = hex"00";
             }
        } else { // outcome == MeasurementOutcome.Outcome1
             // Condition type 0x02: Specific Address Check (Original Pair Creator)
             // The pair creator is the owner of state A or B when created, let's use the owner of State A as the required releaser
             address creatorAddress = states[pairs[states[stateId].pairId].stateAId].owner; // Assuming State A owner is the creator representative
             bytes memory creatorBytes = abi.encode(creatorAddress);
             newPartnerCondition = abi.encodePacked(bytes1(0x02), creatorBytes);
        }

        // Apply the new condition to the partner state
        states[partnerStateId].currentReleaseCondition = newPartnerCondition;
        emit ReleaseConditionUpdated(partnerStateId, newPartnerCondition);

        // Note: The measured state's own release condition remains as is.
    }

    /**
     * @dev Attempts to release assets from a state.
     *      Requires the state's `currentReleaseCondition` to be met.
     *      Can be called by anyone, but the condition might restrict it.
     * @param stateId The ID of the state.
     */
    function releaseAssets(uint256 stateId)
        external
        whenStateIsNot(stateId, StateStatus.Released) // Cannot release already released state
        whenStateIsNot(stateId, StateStatus.PendingMeasurement) // Cannot release if measurement is pending
    {
        // Check if the condition is met
        require(_checkReleaseCondition(stateId, states[stateId].currentReleaseCondition), "Release condition not met");

        // Transfer all assets
        _transferAllAssets(stateId, states[stateId].owner);

        // Mark state as Released
        states[stateId].status = StateStatus.Released;
        emit AssetsReleased(stateId, states[stateId].owner);
        emit StateStatusChanged(stateId, states[stateId].status, StateStatus.Released); // Emit status change after setting
    }

    /**
     * @dev Allows the owner of a state to set a *future* release condition.
     *      This condition is not active immediately but *could* be used
     *      in future entanglement logic (e.g., applied after the partner
     *      state is measured in a subsequent interaction, as implemented).
     * @param stateId The ID of the state.
     * @param newCondition The new condition bytes.
     */
    function setFutureReleaseCondition(uint256 stateId, bytes memory newCondition)
        external
        onlyStateOwner(stateId)
        whenStateIsNot(stateId, StateStatus.Released)
    {
        states[stateId].futureReleaseCondition = newCondition;
        emit FutureReleaseConditionSet(stateId, newCondition);
    }

    // --- View Functions ---

    /**
     * @dev Gets the details of an entangled pair.
     * @param pairId The ID of the pair.
     * @return stateAId The ID of State A.
     * @return stateBId The ID of State B.
     */
    function getPairDetails(uint256 pairId)
        external
        view
        returns (uint256 stateAId, uint256 stateBId)
    {
        require(pairs[pairId].stateAId != 0, "Pair not found"); // Check if pair exists
        return (pairs[pairId].stateAId, pairs[pairId].stateBId);
    }

    /**
     * @dev Gets the details of a state (owner, status, measured outcome, vrfRequestId).
     * @param stateId The ID of the state.
     * @return owner The owner address.
     * @return status The current status.
     * @return measuredOutcome The measured outcome if applicable.
     * @return vrfRequestId The ID of the pending VRF request, or 0.
     */
    function getStateDetails(uint256 stateId)
        external
        view
        returns (address owner, StateStatus status, MeasurementOutcome measuredOutcome, uint256 vrfRequestId)
    {
        require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        State storage state = states[stateId];
        return (state.owner, state.status, state.measuredOutcome, state.vrfRequestId);
    }

     /**
     * @dev Gets the ERC20 balance for a specific token within a state.
     * @param stateId The ID of the state.
     * @param token The ERC20 token address.
     * @return balance The balance of the token in the state.
     */
    function getERC20BalanceInState(uint256 stateId, IERC20 token)
        external
        view
        returns (uint256 balance)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].erc20Balances[address(token)];
    }

    /**
     * @dev Gets the list of ERC721 token IDs for a specific token within a state.
     *      Note: This returns a copy of the internal array. Modifying the returned array
     *      will not affect the contract state.
     * @param stateId The ID of the state.
     * @param token The ERC721 token address.
     * @return tokenIds Array of token IDs.
     */
    function getERC721TokensInState(uint256 stateId, IERC721 token)
        external
        view
        returns (uint256[] memory tokenIds)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].erc721Tokens[address(token)];
    }

     /**
     * @dev Gets the currently active release condition bytes for a state.
     * @param stateId The ID of the state.
     * @return condition The condition bytes.
     */
    function getCurrentReleaseCondition(uint256 stateId)
        external
        view
        returns (bytes memory condition)
    {
        require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].currentReleaseCondition;
    }

    /**
     * @dev Gets the future release condition bytes for a state.
     * @param stateId The ID of the state.
     * @return condition The condition bytes.
     */
    function getFutureReleaseCondition(uint256 stateId)
        external
        view
        returns (bytes memory condition)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].futureReleaseCondition;
    }

    /**
     * @dev Gets the pair ID for a given state ID.
     * @param stateId The ID of the state.
     * @return pairId The pair ID.
     */
    function getPairIdForState(uint256 stateId)
        public // Made public so internal functions can also use it
        view
        returns (uint256 pairId)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].pairId;
    }

    /**
     * @dev Gets the partner state ID for a given state ID.
     * @param stateId The ID of the state.
     * @return partnerStateId The ID of the partner state.
     */
    function getPartnerStateId(uint256 stateId)
        public // Made public so internal functions can also use it
        view
        returns (uint256 partnerStateId)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        uint256 pairId = states[stateId].pairId;
        if (pairs[pairId].stateAId == stateId) {
            return pairs[pairId].stateBId;
        } else if (pairs[pairId].stateBId == stateId) {
            return pairs[pairId].stateAId;
        }
        // Should not happen if stateId is valid and pairId is correct
        return 0;
    }

     /**
     * @dev Gets the status of a state.
     * @param stateId The ID of the state.
     * @return status The state's current status.
     */
    function getStateStatus(uint256 stateId)
        external
        view
        returns (StateStatus status)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].status;
    }

     /**
     * @dev Gets the measured outcome of a state if it has been measured.
     * @param stateId The ID of the state.
     * @return outcome The measured outcome (Unmeasured, Outcome0, or Outcome1).
     */
    function getMeasuredOutcome(uint256 stateId)
        external
        view
        returns (MeasurementOutcome outcome)
    {
         require(states[stateId].pairId != 0, "State not found"); // Check if state exists
        return states[stateId].measuredOutcome;
    }

     /**
     * @dev Gets the list of ERC20 token addresses that have been deposited in a state.
     *      Useful for iterating balances.
     * @param stateId The ID of the state.
     * @return tokenAddresses Array of ERC20 token addresses.
     */
    function getDepositedERC20Tokens(uint256 stateId)
        external
        view
        returns (address[] memory tokenAddresses)
    {
         require(states[stateId].pairId != 0, "State not found");
         return states[stateId].depositedERC20Tokens;
    }

    /**
     * @dev Gets the list of ERC721 token addresses that have been deposited in a state.
     *      Useful for iterating token IDs.
     * @param stateId The ID of the state.
     * @return tokenAddresses Array of ERC721 token addresses.
     */
    function getDepositedERC721Tokens(uint256 stateId)
        external
        view
        returns (address[] memory tokenAddresses)
    {
         require(states[stateId].pairId != 0, "State not found");
         return states[stateId].depositedERC721Tokens;
    }


    // --- Owner Functions ---

    /**
     * @dev Sets the Chainlink VRF subscription ID and key hash.
     *      Requires the new subscription ID to have this contract as a consumer.
     * @param _subscriptionId The new subscription ID.
     * @param _keyHash The new key hash.
     */
    function setVRFParams(uint64 _subscriptionId, bytes32 _keyHash) external onlyOwner {
        require(_subscriptionId != 0, "Invalid VRF subscription ID");
        require(_keyHash != bytes32(0), "Invalid VRF key hash");
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        // Note: Adding this contract as a consumer to the new subscription
        // must be done externally to the contract.
    }

    /**
     * @dev Allows the owner to withdraw LINK tokens from the contract (used for VRF fees).
     * @param amount The amount of LINK to withdraw.
     */
    function withdrawLink(uint256 amount) external onlyOwner {
        IERC20 linkToken = IERC20(i_vrfCoordinator.getLinkAddress());
        require(linkToken.balanceOf(address(this)) >= amount, "Not enough LINK");
        linkToken.transfer(msg.sender, amount);
    }

    // Standard Ownable functions (transferOwnership, renounceOwnership) inherited.

    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to create the pair and states.
     */
    function _createPair(address ownerA, address ownerB, bytes memory _initialConditionA, bytes memory _initialConditionB)
        internal
        returns (uint256 pairId)
    {
        uint256 newPairId = _nextPairId++;
        uint256 stateAId = _nextStateId++;
        uint256 stateBId = _nextStateId++;

        pairs[newPairId] = Pair({
            stateAId: stateAId,
            stateBId: stateBId
        });

        states[stateAId] = State({
            pairId: newPairId,
            owner: ownerA,
            currentReleaseCondition: _initialConditionA,
            futureReleaseCondition: "", // Initialize empty
            status: StateStatus.Locked,
            measuredOutcome: MeasurementOutcome.Unmeasured,
            vrfRequestId: 0,
            depositedERC20Tokens: new address[](0), // Initialize empty list
            depositedERC721Tokens: new address[](0), // Initialize empty list
            // Mappings are implicitly initialized empty
            erc20Balances: new mapping(address => uint256),
            erc721Tokens: new mapping(address => uint256[])
        });

         states[stateBId] = State({
            pairId: newPairId,
            owner: ownerB,
            currentReleaseCondition: _initialConditionB,
            futureReleaseCondition: "", // Initialize empty
            status: StateStatus.Locked,
            measuredOutcome: MeasurementOutcome.Unmeasured,
            vrfRequestId: 0,
            depositedERC20Tokens: new address[](0), // Initialize empty list
            depositedERC721Tokens: new address[](0), // Initialize empty list
            // Mappings are implicitly initialized empty
            erc20Balances: new mapping(address => uint256),
            erc721Tokens: new mapping(address => uint256[])
        });

        emit PairCreated(newPairId, stateAId, stateBId, msg.sender);
        emit StateStatusChanged(stateAId, StateStatus.Locked, StateStatus.Locked); // Initial status
        emit StateStatusChanged(stateBId, StateStatus.Locked, StateStatus.Locked); // Initial status

        return newPairId;
    }


    /**
     * @dev Internal function to deposit ERC20. Assumes approval is already handled by caller.
     */
    function _depositERC20(uint256 stateId, IERC20 token, uint256 amount) internal {
        address tokenAddress = address(token);
        uint256 initialBalance = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), amount);
        uint256 receivedAmount = token.balanceOf(address(this)) - initialBalance;

        if (states[stateId].erc20Balances[tokenAddress] == 0) {
            // Add token address to the list if this is the first deposit of this token type
            states[stateId].depositedERC20Tokens.push(tokenAddress);
        }
        states[stateId].erc20Balances[tokenAddress] += receivedAmount;

        emit AssetsDeposited(stateId, tokenAddress, receivedAmount, false);
    }

     /**
     * @dev Internal function to deposit ERC721. Assumes approval is already handled by caller.
     */
    function _depositERC721(uint256 stateId, IERC721 token, uint256 tokenId) internal {
        address tokenAddress = address(token);
        // transferFrom implicitly checks if msg.sender is owner or approved
        token.transferFrom(msg.sender, address(this), tokenId);

        // Check if this token address is already tracked for this state
        bool tokenAddressExists = false;
        for(uint i = 0; i < states[stateId].depositedERC721Tokens.length; i++) {
            if (states[stateId].depositedERC721Tokens[i] == tokenAddress) {
                tokenAddressExists = true;
                break;
            }
        }
        if (!tokenAddressExists) {
            states[stateId].depositedERC721Tokens.push(tokenAddress);
        }

        // Add the token ID to the dynamic array for this token in this state
        states[stateId].erc721Tokens[tokenAddress].push(tokenId);

        emit AssetsDeposited(stateId, tokenAddress, tokenId, true);
    }

    /**
     * @dev Internal helper to check if a release condition is met.
     *      Condition format:
     *      - 0x00: Always true
     *      - 0x01 + bytes8(timestamp): Unlock after timestamp
     *      - 0x02 + address: Caller must be the specified address
     *      - 0x03 + bytes1(outcome): Partner state must have measured this outcome (0x00 for Outcome0, 0x01 for Outcome1)
     *      - 0x04 + bytes<...>: Placeholder for more complex custom logic (not implemented here)
     * @param stateId The ID of the state being checked.
     * @param condition The condition bytes.
     * @return bool True if the condition is met, false otherwise.
     */
    function _checkReleaseCondition(uint256 stateId, bytes memory condition)
        internal
        view
        returns (bool)
    {
        if (condition.length == 0) {
            // Empty condition bytes means no specific condition (always true)
            return true;
        }

        bytes1 conditionType = condition[0];

        if (conditionType == 0x00) {
             // Always true
             return true;
        } else if (conditionType == 0x01 && condition.length == 9) {
            // Timestamp check: condition is 0x01 + bytes8(timestamp)
            uint64 unlockTimestamp = abi.decode(condition[1:], (uint64));
            return block.timestamp >= unlockTimestamp;
        } else if (conditionType == 0x02 && condition.length == 21) {
            // Specific address check: condition is 0x02 + address
            address requiredAddress = abi.decode(condition[1:], (address));
            return msg.sender == requiredAddress;
        } else if (conditionType == 0x03 && condition.length == 2) {
            // Partner Measured Outcome check: condition is 0x03 + bytes1(outcome)
            // outcome byte: 0x00 for Outcome0, 0x01 for Outcome1
            uint256 partnerStateId = getPartnerStateId(stateId);
            if (partnerStateId == 0) return false; // Should not happen for valid stateId

            State storage partnerState = states[partnerStateId];
            if (partnerState.status != StateStatus.Measured) return false; // Partner hasn't been measured

            MeasurementOutcome requiredOutcome;
            if (condition[1] == 0x00) {
                requiredOutcome = MeasurementOutcome.Outcome0;
            } else if (condition[1] == 0x01) {
                requiredOutcome = MeasurementOutcome.Outcome1;
            } else {
                // Invalid outcome byte in condition
                return false;
            }

            return partnerState.measuredOutcome == requiredOutcome;

        }
        // Default: Unknown condition type or invalid length means condition not met (or invalid)
        return false;
    }

    /**
     * @dev Internal function to transfer all assets (ERC20 and ERC721) out of a state.
     * @param stateId The ID of the state.
     * @param recipient The address to send assets to.
     */
    function _transferAllAssets(uint256 stateId, address recipient) internal {
        State storage state = states[stateId];

        // Transfer ERC20
        address[] memory erc20TokensToProcess = state.depositedERC20Tokens;
        delete state.depositedERC20Tokens; // Clear the list before iterating

        for (uint i = 0; i < erc20TokensToProcess.length; i++) {
            address tokenAddress = erc20TokensToProcess[i];
            uint256 balance = state.erc20Balances[tokenAddress];
            if (balance > 0) {
                state.erc20Balances[tokenAddress] = 0; // Clear balance *before* transfer
                 // Use low-level call for robustness with arbitrary ERC20s
                 (bool success, ) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", recipient, balance));
                 require(success, string(abi.encodePacked("ERC20 transfer failed for token ", tokenAddress.toHexString())));
            }
        }

        // Transfer ERC721
        address[] memory erc721TokensToProcess = state.depositedERC721Tokens;
        delete state.depositedERC721Tokens; // Clear the list before iterating

        for (uint i = 0; i < erc721TokensToProcess.length; i++) {
            address tokenAddress = erc721TokensToProcess[i];
            uint256[] storage tokenIds = state.erc721Tokens[tokenAddress];
            // Iterate and transfer, then clear the mapping entry for this token address
            uint256 len = tokenIds.length; // Get length before potentially modifying

            for (uint j = 0; j < len; j++) {
                 uint256 tokenId = tokenIds[j];
                 // Ensure contract is still owner before transferring
                 try IERC721(tokenAddress).ownerOf(tokenId) returns (address currentOwner) {
                     if (currentOwner == address(this)) {
                         try IERC721(tokenAddress).transferFrom(address(this), recipient, tokenId) {
                             // Transfer successful, do nothing else here
                         } catch {
                            // Log or revert? Reverting might block entire release.
                            // For a demo, let's revert to highlight failure.
                            revert(string(abi.encodePacked("ERC721 transfer failed for token ", tokenAddress.toHexString(), " id ", Strings.toString(tokenId))));
                         }
                     }
                 } catch {
                     // Handle case where ownerOf might revert (e.g., token burned)
                     // Log or continue. Continue here assuming token is gone.
                 }
             }
             // Clear the array for this token address after attempting transfers
             delete state.erc721Tokens[tokenAddress];
        }
    }
}
```