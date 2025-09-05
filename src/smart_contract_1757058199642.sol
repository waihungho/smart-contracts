Here's a smart contract in Solidity called "Quantum Nexus - Decentralized Predictive Asset & Reputation System".

This contract introduces a novel concept where users predict outcomes of future events. Based on the collective accuracy of these predictions and the actual event outcomes, users earn "Predictor Reputation Scores" and can mint unique, dynamic NFTs called "Quantum Assets" (QAs). The properties of these QAs are derived from the event's outcome, the collective predictions, and the individual's reputation.

**Advanced Concepts & Features:**

1.  **Decentralized Predictive Market:** Beyond simple binary predictions, this system aims for more nuanced outcomes, with assets whose properties are influenced by these predictions.
2.  **Dynamic NFTs (Quantum Assets - QAs):** ERC-721 tokens whose metadata/properties are not static but are algorithmically derived and resolved based on actual event outcomes and aggregated predictions. Their "rarity" or "utility score" is determined *after* the event concludes.
3.  **Meritocratic Reputation System:** Users build a `PredictorProfile` with a `reputationScore` that increases with accurate predictions and decreases with inaccurate ones, providing a tangible on-chain measure of reliability.
4.  **Time-Gated & Event-Driven Mechanics:** Predictions are submitted within a specific window, and assets resolve only after the event's resolution window closes and its outcome is verified.
5.  **Simplified Oracle/Arbitration Integration:** While not using a live Chainlink oracle for this example (to keep it self-contained and avoid external dependencies), it defines an `arbitratorContract` role responsible for submitting verified event outcomes, mimicking a decentralized truth source. It also includes a `challengeEventOutcome` placeholder for potential dispute resolution.
6.  **Staking & Incentivization:** Predictors stake ETH on their predictions, which is then pooled. Accurate predictors get their stake back plus a proportional share of the incorrect stakes, incentivizing honest and well-researched predictions.

---

## Contract: `QuantumNexus`

### Outline & Function Summary

**Core Concepts:**
*   **Event Management:** Lifecycle for proposing, approving, and resolving future events.
*   **Prediction & Reputation:** Users stake on predictions, building an on-chain reputation based on accuracy.
*   **Quantum Asset (QA) Generation:** Dynamic NFTs minted by accurate predictors, with properties based on event outcomes and individual performance.
*   **Arbitration & Resolution:** A designated arbitrator verifies event outcomes, leading to event resolution and reward distribution.
*   **Staking & Payouts:** Management of ETH staked by predictors and distribution of rewards.

**Data Structures:**
*   `EventData`: Details for each prediction event (description, windows, status, outcome).
*   `Prediction`: Individual user predictions (predictor, data hash, stake, accuracy, payout).
*   `PredictorProfile`: User's aggregated reputation and prediction statistics.
*   `QuantumAsset`: Details for each dynamic NFT (ID, linked event, minter, derived properties, status).

---

**Function Summary (28 Functions):**

**I. Event Management (Core):**
1.  `proposeNewEvent(string _description, uint256 _predictionWindowEnd, uint256 _resolutionWindowStart, uint256 _resolutionWindowEnd, bytes32 _outcomeSpecificationHash)`: Allows anyone to propose a new event for prediction.
2.  `approveEvent(uint256 _eventId)`: (Owner) Approves a proposed event, making it active for predictions.
3.  `cancelEvent(uint256 _eventId)`: (Owner) Cancels an event, refunding all stakes.
4.  `submitEventOutcome(uint256 _eventId, bytes32 _actualOutcomeHash)`: (Arbitrator) Submits the verified outcome of an event.
5.  `challengeEventOutcome(uint256 _eventId, bytes32 _challengedOutcomeHash)`: (User) Placeholder to challenge a submitted outcome, setting event to `OutcomeChallenged`.
6.  `resolveEvent(uint256 _eventId)`: Finalizes the event, calculates prediction accuracy, updates reputations, and prepares for reward payouts.

**II. Prediction & Reputation:**
7.  `submitPrediction(uint256 _eventId, bytes32 _predictionDataHash, uint256 _stakeAmount)`: (User) Submits a prediction for an active event with a financial stake.
8.  `withdrawPredictionStake(uint256 _eventId, uint256 _predictionIndex)`: (User) Allows individual stake withdrawal if event cancelled (partially redundant with `cancelEvent`'s bulk refund, but for individual processing).
9.  `getPredictorProfile(address _predictor)`: (View) Retrieves a predictor's reputation score and statistics.
10. `getEventPredictionCount(uint256 _eventId)`: (View) Returns the total number of predictions for a specific event.
11. `getPredictionDetails(uint256 _eventId, uint256 _predictionIndex)`: (View) Retrieves specific details of a prediction.

**III. Quantum Asset (QA) Management (ERC-721 Interface & Custom Logic):**
12. `mintQuantumAsset(uint256 _eventId)`: (User) Mints a dynamic QA NFT for an accurate prediction on a resolved event.
13. `burnQuantumAsset(uint256 _qaId)`: (User) Allows the owner to burn their QA.
14. `getQuantumAssetDetails(uint256 _qaId)`: (View) Retrieves detailed properties of a specific QA.
15. `balanceOf(address owner)`: (ERC-721) Returns the number of QAs owned by an address.
16. `ownerOf(uint256 tokenId)`: (ERC-721) Returns the owner of a specific QA.
17. `approve(address to, uint256 tokenId)`: (ERC-721) Approves another address to transfer a specific QA.
18. `getApproved(uint256 tokenId)`: (ERC-721) Returns the approved address for a specific QA.
19. `setApprovalForAll(address operator, bool approved)`: (ERC-721) Grants or revokes approval for an operator to manage all QAs.
20. `isApprovedForAll(address owner, address operator)`: (ERC-721) Checks if an operator is approved for all QAs of an owner.
21. `transferFrom(address from, address to, uint256 tokenId)`: (ERC-721) Transfers a QA from one address to another.
22. `safeTransferFrom(address from, address to, uint256 tokenId)`: (ERC-721) Safer transfer of a QA.
23. `safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)`: (ERC-721) Safer transfer with additional data.

**IV. General Utility & Governance:**
24. `setArbitrator(address _newArbitrator)`: (Owner) Sets the address of the trusted arbitrator contract.
25. `setPredictionFee(uint256 _fee)`: (Owner) Sets the fee required to submit a prediction.
26. `claimPredictionRewards(uint256 _eventId)`: (User) Allows accurate predictors to claim their staked ETH and proportional winnings.
27. `withdrawContractBalance(uint256 _amount)`: (Owner) Allows the owner to withdraw accumulated fees/remaining contract balance.
28. `updateEventParameter(uint256 _eventId, uint256 _newResolutionWindowEnd)`: (Owner) Allows modification of specific event parameters (e.g., extend resolution window).
29. `getTotalStakedForEvent(uint256 _eventId)`: (View) Returns the total ETH staked for a given event.

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- Custom Errors ---
error QuantumNexus__InvalidEventState(uint256 _eventId, string _expectedState);
error QuantumNexus__PredictionWindowClosed();
error QuantumNexus__ResolutionWindowNotStarted();
error QuantumNexus__OutcomeAlreadySubmitted();
error QuantumNexus__NotEnoughStake();
error QuantumNexus__Unauthorized();
error QuantumNexus__EventNotResolved();
error QuantumNexus__AlreadyMintedQA();
error QuantumNexus__NoRewardsToClaim();
error QuantumNexus__TokenTransferFailed();
error QuantumNexus__InvalidQuantumAssetId();
error QuantumNexus__InvalidEventId();
error QuantumNexus__InvalidPredictionIndex(uint256 _eventId, uint256 _predictionIndex);

// --- Interface for a simplified Oracle/Arbitrator contract (mocked) ---
// In a real system, this would be a more complex oracle integration (e.g., Chainlink)
// or a robust DAO-governed arbitration process.
interface IArbitrator {
    function submitEventOutcome(uint256 _eventId, bytes32 _actualOutcomeHash) external;
    function getEventOutcome(uint256 _eventId) external view returns (bytes32);
    function isOutcomeChallenged(uint256 _eventId) external view returns (bool);
}

// --- Main Contract: QuantumNexus ---
contract QuantumNexus is Ownable, IERC721 {
    // --- Structs ---

    /// @dev Represents a prediction event in the system.
    struct EventData {
        uint256 id;
        string description;                 // IPFS CID or similar for detailed event description
        uint256 predictionWindowEnd;         // Timestamp when predictions close
        uint256 resolutionWindowStart;       // Timestamp when outcome can be submitted
        uint256 resolutionWindowEnd;         // Timestamp by which outcome must be resolved
        bytes32 outcomeSpecificationHash;    // IPFS CID for how outcome is determined/verified
        bytes32 actualOutcomeHash;           // Actual verified outcome of the event
        EventStatus status;
        uint256 totalStaked;                // Total ETH staked in this event (excluding fees)
        uint256 qaMintCounter;              // Counter for Quantum Assets minted for this event
    }

    /// @dev Represents an individual prediction made by a user for an event.
    struct Prediction {
        address predictor;
        bytes32 predictionDataHash;          // IPFS CID for predictor's specific data/choice
        uint256 stakeAmount;                 // Amount of ETH staked by the predictor
        bool claimedRewards;                 // True if rewards for this prediction have been claimed
        bool isAccurate;                     // True if the prediction was accurate
        uint256 payoutAmount;                // Total amount (stake + winnings) to be paid out if accurate
    }

    /// @dev Represents a user's profile, tracking their prediction performance.
    struct PredictorProfile {
        uint256 reputationScore;             // Score based on accuracy over time
        uint256 totalPredictions;            // Total number of predictions made
        uint256 correctPredictions;          // Total number of accurate predictions
        uint256 totalStakedAmount;           // Total ETH staked across all predictions
    }

    /// @dev Represents a dynamic Quantum Asset (NFT).
    struct QuantumAsset {
        uint256 id;
        uint256 linkedEventId;               // The event this QA is linked to
        address mintedBy;                    // The address that minted this QA
        bytes32 propertiesHash;              // IPFS CID for QA's dynamic properties (e.g., rarity, traits)
        QAStatus status;                    // Status of the QA
    }

    // --- Enums ---
    enum EventStatus { Proposed, Active, Resolved, Cancelled, OutcomeChallenged }
    enum QAStatus { Pending, Resolved } // QAs can be "Pending" during an event, "Resolved" after minting

    // --- State Variables ---
    uint256 public nextEventId;                 // Counter for new event IDs
    uint256 public nextQuantumAssetId;          // Counter for new QA IDs
    address public arbitratorContract;          // Address of the trusted arbitrator/oracle contract
    uint256 public predictionFee;               // Fee to submit a prediction (in wei)
    uint256 public constant MIN_PREDICTION_STAKE = 0.01 ether; // Minimum stake for a prediction

    mapping(uint256 => EventData) public events;
    mapping(uint256 => Prediction[]) public eventPredictions; // eventId => list of predictions
    mapping(address => PredictorProfile) public predictorProfiles;
    mapping(uint256 => QuantumAsset) public quantumAssets; // QA ID => QuantumAsset details
    mapping(uint256 => mapping(address => bool)) private _hasMintedQAForEvent; // eventId => minterAddress => bool

    // ERC721 specific mappings (minimal custom implementation, no full OpenZeppelin ERC721)
    mapping(uint256 => address) private _owners; // QA ID => owner
    mapping(address => uint256) private _balances; // owner => balance
    mapping(uint256 => address) private _tokenApprovals; // QA ID => approved address
    mapping(address => mapping(address => bool)) private _operatorApprovals; // owner => operator => approved

    // --- Events ---
    event EventProposed(uint256 indexed eventId, address indexed proposer, string description);
    event EventApproved(uint256 indexed eventId, address indexed approver);
    event EventCancelled(uint256 indexed eventId, address indexed canceller);
    event PredictionSubmitted(uint256 indexed eventId, address indexed predictor, bytes32 predictionDataHash, uint256 stakeAmount);
    event EventOutcomeSubmitted(uint256 indexed eventId, address indexed submitter, bytes32 actualOutcomeHash);
    event EventOutcomeChallenged(uint256 indexed eventId, address indexed challenger);
    event EventResolved(uint256 indexed eventId, bytes32 actualOutcomeHash, uint256 totalWinningsDistributed);
    event PredictorProfileUpdated(address indexed predictor, uint256 newReputationScore);
    event QuantumAssetMinted(uint256 indexed qaId, uint256 indexed eventId, address indexed minter, bytes32 propertiesHash);
    event PredictionRewardsClaimed(uint256 indexed eventId, address indexed predictor, uint256 amount);
    event ArbitratorUpdated(address indexed oldArbitrator, address indexed newArbitrator);

    // --- Constructor ---
    /// @notice Initializes the contract with an initial arbitrator address.
    /// @param _initialArbitrator The address of the trusted arbitrator or a mock contract.
    constructor(address _initialArbitrator) Ownable(msg.sender) {
        if (_initialArbitrator == address(0)) {
            revert QuantumNexus__Unauthorized(); // More specific error could be made
        }
        arbitratorContract = _initialArbitrator;
        nextEventId = 1;
        nextQuantumAssetId = 1;
        predictionFee = 0; // Default to no fee
    }

    // --- Modifiers ---
    /// @dev Restricts function access to the designated arbitrator contract.
    modifier onlyArbitrator() {
        if (msg.sender != arbitratorContract) {
            revert QuantumNexus__Unauthorized();
        }
        _;
    }

    // --- ERC721 Interface Implementations (Minimal) ---

    /// @inheritdoc IERC721
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert QuantumNexus__InvalidQuantumAssetId();
        return owner;
    }

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId); // Checks if tokenId exists
        if (owner != msg.sender && !_operatorApprovals[owner][msg.sender]) revert QuantumNexus__Unauthorized();
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /// @inheritdoc IERC721
    function getApproved(uint256 tokenId) public view override returns (address) {
        return _tokenApprovals[tokenId];
    }

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) public override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) public override {
        if (!(_isApprovedOrOwner(msg.sender, tokenId) || isApprovedForAll(from, msg.sender))) {
            revert QuantumNexus__Unauthorized();
        }
        _transfer(from, to, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {
        transferFrom(from, to, tokenId); // Handles approval and actual transfer
        if (to.code.length > 0 && IERC721Receiver(to).onERC721Received.selector != IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data).selector) {
             revert QuantumNexus__TokenTransferFailed();
        }
    }

    /// @dev Internal function to handle the actual transfer logic.
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (ownerOf(tokenId) != from) revert QuantumNexus__InvalidQuantumAssetId(); // Should not happen if ownerOf is correct
        if (to == address(0)) revert QuantumNexus__TokenTransferFailed(); // Cannot transfer to zero address

        _approve(address(0), tokenId); // Clear approval for the transferred token
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /// @dev Internal function to set token approval.
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        // emit Approval(_owners[tokenId], to, tokenId); // Already handled in public approve function
    }

    /// @dev Internal helper to check if a spender is approved or is the owner.
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId); // Will revert if tokenId does not exist
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }


    // --- I. Event Management (Core) ---

    /// @notice Proposes a new event for prediction.
    /// @param _description A string (e.g., IPFS CID) pointing to the detailed event description.
    /// @param _predictionWindowEnd Timestamp when prediction submissions close.
    /// @param _resolutionWindowStart Timestamp when the outcome can first be submitted.
    /// @param _resolutionWindowEnd Timestamp by which the event must be resolved.
    /// @param _outcomeSpecificationHash IPFS CID for how the outcome will be determined/verified.
    /// @dev Requires valid time windows. Event status is 'Proposed' until approved by owner.
    function proposeNewEvent(
        string memory _description,
        uint256 _predictionWindowEnd,
        uint256 _resolutionWindowStart,
        uint256 _resolutionWindowEnd,
        bytes32 _outcomeSpecificationHash
    ) external {
        if (_predictionWindowEnd <= block.timestamp) revert QuantumNexus__InvalidEventState(0, "Prediction window must be in the future");
        if (_resolutionWindowStart <= _predictionWindowEnd) revert QuantumNexus__InvalidEventState(0, "Resolution window must start after prediction window ends");
        if (_resolutionWindowEnd <= _resolutionWindowStart) revert QuantumNexus__InvalidEventState(0, "Resolution window must end after it starts");

        uint256 eventId = nextEventId++;
        events[eventId] = EventData({
            id: eventId,
            description: _description,
            predictionWindowEnd: _predictionWindowEnd,
            resolutionWindowStart: _resolutionWindowStart,
            resolutionWindowEnd: _resolutionWindowEnd,
            outcomeSpecificationHash: _outcomeSpecificationHash,
            actualOutcomeHash: bytes32(0),
            status: EventStatus.Proposed,
            totalStaked: 0,
            qaMintCounter: 0
        });
        emit EventProposed(eventId, msg.sender, _description);
    }

    /// @notice Approves a proposed event, making it active for predictions.
    /// @param _eventId The ID of the event to approve.
    /// @dev Only callable by the contract owner (admin/DAO).
    function approveEvent(uint256 _eventId) external onlyOwner {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Proposed) revert QuantumNexus__InvalidEventState(_eventId, "Expected Proposed");
        if (eventData.predictionWindowEnd <= block.timestamp) revert QuantumNexus__InvalidEventState(_eventId, "Prediction window already ended");

        eventData.status = EventStatus.Active;
        emit EventApproved(_eventId, msg.sender);
    }

    /// @notice Cancels an event before its resolution.
    /// @param _eventId The ID of the event to cancel.
    /// @dev Only callable by the contract owner (admin/DAO). All stakes are refunded.
    function cancelEvent(uint256 _eventId) external onlyOwner {
        EventData storage eventData = events[_eventId];
        if (eventData.status == EventStatus.Resolved || eventData.status == EventStatus.Cancelled) {
            revert QuantumNexus__InvalidEventState(_eventId, "Expected Active, Proposed, or OutcomeChallenged");
        }

        // Refund all stakes
        for (uint256 i = 0; i < eventPredictions[_eventId].length; i++) {
            Prediction storage prediction = eventPredictions[_eventId][i];
            // Safe transfer ETH
            (bool success,) = prediction.predictor.call{value: prediction.stakeAmount}("");
            if (!success) {
                revert QuantumNexus__TokenTransferFailed();
            }
            prediction.claimedRewards = true; // Mark as claimed
        }
        eventData.totalStaked = 0;
        eventData.status = EventStatus.Cancelled;
        emit EventCancelled(_eventId, msg.sender);
    }

    /// @notice Submits the actual outcome of an event.
    /// @param _eventId The ID of the event.
    /// @param _actualOutcomeHash A hash (e.g., IPFS CID) representing the verified outcome.
    /// @dev Only callable by the designated arbitrator. Must be within the resolution window.
    function submitEventOutcome(uint256 _eventId, bytes32 _actualOutcomeHash) external onlyArbitrator {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Active && eventData.status != EventStatus.OutcomeChallenged) {
            revert QuantumNexus__InvalidEventState(_eventId, "Expected Active or OutcomeChallenged");
        }
        if (block.timestamp < eventData.resolutionWindowStart) revert QuantumNexus__ResolutionWindowNotStarted();
        if (block.timestamp > eventData.resolutionWindowEnd) revert QuantumNexus__InvalidEventState(_eventId, "Resolution window closed");

        if (eventData.actualOutcomeHash != bytes32(0)) revert QuantumNexus__OutcomeAlreadySubmitted();

        eventData.actualOutcomeHash = _actualOutcomeHash;
        emit EventOutcomeSubmitted(_eventId, msg.sender, _actualOutcomeHash);
    }

    /// @notice Allows a user to challenge a submitted outcome.
    /// @param _eventId The ID of the event.
    /// @param _challengedOutcomeHash The outcome hash being challenged (for record-keeping).
    /// @dev This function currently just sets the event status. In a full system,
    ///      this would trigger a dispute resolution mechanism within the arbitrator contract.
    function challengeEventOutcome(uint252 _eventId, bytes32 _challengedOutcomeHash) external {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Active || eventData.actualOutcomeHash == bytes32(0)) {
            revert QuantumNexus__InvalidEventState(_eventId, "Outcome not submitted or event not active");
        }
        if (block.timestamp < eventData.resolutionWindowStart || block.timestamp > eventData.resolutionWindowEnd) {
            revert QuantumNexus__InvalidEventState(_eventId, "Not within resolution window");
        }

        // Placeholder: In a real system, IArbitrator(arbitratorContract).challengeOutcome(...) would be called.
        eventData.status = EventStatus.OutcomeChallenged;
        emit EventOutcomeChallenged(_eventId, msg.sender);
    }

    /// @notice Finalizes the event, calculates prediction accuracy, updates reputation, and prepares for QA minting.
    /// @param _eventId The ID of the event to resolve.
    /// @dev Callable by anyone after the resolution window ends and an outcome is submitted.
    function resolveEvent(uint256 _eventId) external {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Active && eventData.status != EventStatus.OutcomeChallenged) {
             revert QuantumNexus__InvalidEventState(_eventId, "Expected Active or OutcomeChallenged");
        }
        if (block.timestamp < eventData.resolutionWindowEnd) {
             revert QuantumNexus__InvalidEventState(_eventId, "Resolution window has not yet ended");
        }
        if (eventData.actualOutcomeHash == bytes32(0)) {
             revert QuantumNexus__InvalidEventState(_eventId, "Outcome not yet submitted");
        }

        uint256 totalWinningsDistributed = _calculateAndDistributeRewards(_eventId);
        eventData.status = EventStatus.Resolved;
        emit EventResolved(_eventId, eventData.actualOutcomeHash, totalWinningsDistributed);
    }

    // --- II. Prediction & Reputation ---

    /// @notice Submits a prediction for an active event with a stake.
    /// @param _eventId The ID of the event to predict on.
    /// @param _predictionDataHash IPFS CID or similar for the predictor's specific data/choice.
    /// @param _stakeAmount The amount of ETH to stake with this prediction.
    /// @dev Requires the event to be active and within the prediction window. Stake must meet minimum + prediction fee.
    function submitPrediction(uint256 _eventId, bytes32 _predictionDataHash, uint256 _stakeAmount) external payable {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Active) revert QuantumNexus__InvalidEventState(_eventId, "Expected Active");
        if (block.timestamp > eventData.predictionWindowEnd) revert QuantumNexus__PredictionWindowClosed();
        if (msg.value < MIN_PREDICTION_STAKE || msg.value != _stakeAmount + predictionFee) revert QuantumNexus__NotEnoughStake(); // Enforce stake + fee

        eventPredictions[_eventId].push(Prediction({
            predictor: msg.sender,
            predictionDataHash: _predictionDataHash,
            stakeAmount: _stakeAmount,
            claimedRewards: false,
            isAccurate: false, // Will be set on resolution
            payoutAmount: 0 // Will be set on resolution
        }));
        eventData.totalStaked += _stakeAmount; // Only the stake amount counts towards the pot
        predictorProfiles[msg.sender].totalPredictions++;
        predictorProfiles[msg.sender].totalStakedAmount += _stakeAmount;

        emit PredictionSubmitted(_eventId, msg.sender, _predictionDataHash, _stakeAmount);
    }

    /// @notice Allows a user to withdraw their prediction stake if the event is cancelled.
    /// @param _eventId The ID of the event.
    /// @param _predictionIndex The index of the prediction in the event's prediction array.
    /// @dev Only possible if event is cancelled and the specific prediction has not been claimed.
    function withdrawPredictionStake(uint256 _eventId, uint256 _predictionIndex) external {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Cancelled) revert QuantumNexus__InvalidEventState(_eventId, "Expected Cancelled");
        if (_predictionIndex >= eventPredictions[_eventId].length) revert QuantumNexus__InvalidPredictionIndex(_eventId, _predictionIndex);

        Prediction storage prediction = eventPredictions[_eventId][_predictionIndex];
        if (prediction.predictor != msg.sender) revert QuantumNexus__Unauthorized();
        if (prediction.claimedRewards) revert QuantumNexus__NoRewardsToClaim(); // Already processed

        prediction.claimedRewards = true;

        (bool success,) = msg.sender.call{value: prediction.stakeAmount}("");
        if (!success) revert QuantumNexus__TokenTransferFailed();

        // Note: The `cancelEvent` function already handles bulk refunds and sets totalStaked to 0.
        // This function would primarily be useful if `cancelEvent` only marks status and doesn't refund.
        // It's kept for functional completeness as per requirement.
    }

    /// @notice Retrieves a predictor's reputation score and other statistics.
    /// @param _predictor The address of the predictor.
    /// @return PredictorProfile struct containing score, total predictions, correct predictions, and total staked.
    function getPredictorProfile(address _predictor) public view returns (PredictorProfile memory) {
        return predictorProfiles[_predictor];
    }

    /// @notice Gets the total number of predictions submitted for a specific event.
    /// @param _eventId The ID of the event.
    /// @return The count of predictions for the event.
    function getEventPredictionCount(uint256 _eventId) public view returns (uint256) {
        return eventPredictions[_eventId].length;
    }

    /// @notice Retrieves details of a specific prediction for an event.
    /// @param _eventId The ID of the event.
    /// @param _predictionIndex The index of the prediction.
    /// @return Prediction struct.
    /// @dev Consider privacy implications for `_predictionDataHash` if it's sensitive.
    function getPredictionDetails(uint256 _eventId, uint256 _predictionIndex) public view returns (Prediction memory) {
        if (_predictionIndex >= eventPredictions[_eventId].length) revert QuantumNexus__InvalidPredictionIndex(_eventId, _predictionIndex);
        return eventPredictions[_eventId][_predictionIndex];
    }

    // --- III. Quantum Asset (QA) Management (ERC-721 like) ---

    /// @notice Mints a new Quantum Asset (QA) after an event is resolved.
    /// @param _eventId The ID of the event for which to mint the QA.
    /// @dev Only callable by a predictor who made an accurate prediction for a resolved event.
    ///      Each accurate predictor can mint one QA per event.
    function mintQuantumAsset(uint256 _eventId) external {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Resolved) revert QuantumNexus__EventNotResolved();

        bool hasAccuratePrediction = false;
        for (uint256 i = 0; i < eventPredictions[_eventId].length; i++) {
            if (eventPredictions[_eventId][i].predictor == msg.sender && eventPredictions[_eventId][i].isAccurate) {
                hasAccuratePrediction = true;
                break;
            }
        }
        if (!hasAccuratePrediction) revert QuantumNexus__Unauthorized(); // User did not make an accurate prediction

        if (_hasMintedQAForEvent[_eventId][msg.sender]) revert QuantumNexus__AlreadyMintedQA();
        _hasMintedQAForEvent[_eventId][msg.sender] = true;

        uint256 qaId = nextQuantumAssetId++;
        bytes32 propertiesHash = _calculateQuantumAssetProperties(_eventId, msg.sender); // Derive properties

        quantumAssets[qaId] = QuantumAsset({
            id: qaId,
            linkedEventId: _eventId,
            mintedBy: msg.sender,
            propertiesHash: propertiesHash,
            status: QAStatus.Resolved
        });

        // ERC721 minting logic
        _balances[msg.sender]++;
        _owners[qaId] = msg.sender;

        eventData.qaMintCounter++;
        emit QuantumAssetMinted(qaId, _eventId, msg.sender, propertiesHash);
    }

    /// @notice Allows the owner to burn their Quantum Asset.
    /// @param _qaId The ID of the Quantum Asset to burn.
    function burnQuantumAsset(uint256 _qaId) external {
        address owner = ownerOf(_qaId); // Will revert if not found
        if (owner != msg.sender && !_operatorApprovals[owner][msg.sender]) revert QuantumNexus__Unauthorized();

        _balances[owner]--;
        delete _owners[_qaId];
        delete _tokenApprovals[_qaId]; // Clear any existing approvals
        delete quantumAssets[_qaId]; // Delete QA details

        emit Transfer(owner, address(0), _qaId);
    }

    /// @notice Retrieves the detailed properties of a specific Quantum Asset.
    /// @param _qaId The ID of the Quantum Asset.
    /// @return QuantumAsset struct containing all details.
    function getQuantumAssetDetails(uint256 _qaId) public view returns (QuantumAsset memory) {
        if (quantumAssets[_qaId].id == 0) revert QuantumNexus__InvalidQuantumAssetId();
        return quantumAssets[_qaId];
    }

    /// @notice Internal function to derive the dynamic properties of a Quantum Asset.
    /// @param _eventId The event ID linked to the QA.
    /// @param _minter The address of the QA minter.
    /// @return A hash representing the unique, dynamic properties of the QA.
    /// @dev This is where the "magic" happens. In a real system, this would be a complex algorithm
    ///      considering aggregated predictions, individual accuracy, and the final outcome.
    ///      For this example, it's a simplified hash derivation.
    function _calculateQuantumAssetProperties(uint256 _eventId, address _minter) internal view returns (bytes32) {
        EventData storage eventData = events[_eventId];
        require(eventData.status == EventStatus.Resolved, "Event must be resolved");

        // Example: Properties could be a hash of the minter's address, the event outcome,
        // and their prediction data, and their current reputation score.
        // This makes each QA unique based on the context and the minter's performance.
        bytes32 qaProperties = keccak256(
            abi.encodePacked(
                _minter,
                _eventId,
                eventData.actualOutcomeHash,
                eventData.outcomeSpecificationHash,
                predictorProfiles[_minter].reputationScore // Incorporate reputation
            )
        );
        return qaProperties;
    }

    // --- IV. General Utility & Governance ---

    /// @notice Sets the address of the trusted arbitrator contract.
    /// @param _newArbitrator The new address for the arbitrator.
    /// @dev Only callable by the contract owner.
    function setArbitrator(address _newArbitrator) external onlyOwner {
        if (_newArbitrator == address(0)) revert QuantumNexus__Unauthorized(); // More specific error could be made
        emit ArbitratorUpdated(arbitratorContract, _newArbitrator);
        arbitratorContract = _newArbitrator;
    }

    /// @notice Sets the fee required to submit a prediction.
    /// @param _fee The new prediction fee in wei.
    /// @dev Only callable by the contract owner.
    function setPredictionFee(uint256 _fee) external onlyOwner {
        predictionFee = _fee;
    }

    /// @notice Allows accurate predictors to claim their staked ETH and rewards.
    /// @param _eventId The ID of the event.
    /// @dev Only callable by a predictor with an accurate, unclaimed prediction for a resolved event.
    function claimPredictionRewards(uint256 _eventId) external {
        EventData storage eventData = events[_eventId];
        if (eventData.status != EventStatus.Resolved) revert QuantumNexus__EventNotResolved();

        uint256 totalClaimable = 0;
        bool foundClaimable = false;

        for (uint256 i = 0; i < eventPredictions[_eventId].length; i++) {
            Prediction storage prediction = eventPredictions[_eventId][i];
            // Check if prediction belongs to msg.sender, is accurate, and not yet claimed
            if (prediction.predictor == msg.sender && prediction.isAccurate && !prediction.claimedRewards) {
                totalClaimable += prediction.payoutAmount;
                prediction.claimedRewards = true;
                foundClaimable = true;
            }
        }

        if (!foundClaimable || totalClaimable == 0) revert QuantumNexus__NoRewardsToClaim();

        (bool success,) = msg.sender.call{value: totalClaimable}("");
        if (!success) revert QuantumNexus__TokenTransferFailed();

        emit PredictionRewardsClaimed(_eventId, msg.sender, totalClaimable);
    }

    /// @notice Allows the contract owner to withdraw accumulated fees and remaining contract balance.
    /// @param _amount The amount of ETH to withdraw.
    /// @dev Only callable by the contract owner. This includes prediction fees and lost stakes.
    function withdrawContractBalance(uint256 _amount) external onlyOwner {
        if (address(this).balance < _amount) revert QuantumNexus__NotEnoughStake(); // Reusing error for "not enough balance"
        (bool success,) = msg.sender.call{value: _amount}("");
        if (!success) revert QuantumNexus__TokenTransferFailed();
    }

    /// @notice Allows the contract owner to update specific parameters of an event before resolution.
    /// @param _eventId The ID of the event to update.
    /// @param _newResolutionWindowEnd The new end timestamp for the resolution window.
    /// @dev Only callable by the contract owner if the event is not yet resolved or cancelled.
    function updateEventParameter(uint256 _eventId, uint256 _newResolutionWindowEnd) external onlyOwner {
        EventData storage eventData = events[_eventId];
        if (eventData.status == EventStatus.Resolved || eventData.status == EventStatus.Cancelled) {
            revert QuantumNexus__InvalidEventState(_eventId, "Expected not Resolved or Cancelled");
        }
        if (_newResolutionWindowEnd <= block.timestamp) revert QuantumNexus__InvalidEventState(_eventId, "New resolution window must be in the future");

        eventData.resolutionWindowEnd = _newResolutionWindowEnd;
        // Could emit a specific event: EventParameterUpdated(_eventId, "resolutionWindowEnd", _newResolutionWindowEnd);
    }

    /// @notice Returns the total amount of ETH staked across all predictions for a specific event.
    /// @param _eventId The ID of the event.
    /// @return The total staked amount.
    function getTotalStakedForEvent(uint256 _eventId) public view returns (uint256) {
        return events[_eventId].totalStaked;
    }

    // --- Internal Helpers ---

    /// @dev Internal function to calculate prediction accuracy, update reputation, and determine payout amounts.
    ///      This function does NOT transfer ETH; it prepares `payoutAmount` for `claimPredictionRewards`.
    /// @return The total amount of *winnings* (profit) calculated for distribution.
    function _calculateAndDistributeRewards(uint256 _eventId) internal returns (uint256) {
        EventData storage eventData = events[_eventId];
        require(eventData.status != EventStatus.Resolved && eventData.actualOutcomeHash != bytes32(0), "Event must be unresolved with an outcome");

        uint256 totalAccurateStake = 0;
        uint256 accuratePredictionCount = 0;

        // Phase 1: Determine accurate predictions and update reputation
        for (uint256 i = 0; i < eventPredictions[_eventId].length; i++) {
            Prediction storage prediction = eventPredictions[_eventId][i];
            bool isPredictionAccurate = _evaluatePredictionAccuracy(eventData.outcomeSpecificationHash, prediction.predictionDataHash, eventData.actualOutcomeHash);
            prediction.isAccurate = isPredictionAccurate;

            PredictorProfile storage profile = predictorProfiles[prediction.predictor];
            if (isPredictionAccurate) {
                profile.correctPredictions++;
                profile.reputationScore += 10; // Gain reputation
                totalAccurateStake += prediction.stakeAmount;
                accuratePredictionCount++;
            } else {
                if (profile.reputationScore >= 5) { // Prevent reputation from going negative
                    profile.reputationScore -= 5; // Lose reputation for incorrect prediction
                }
            }
            emit PredictorProfileUpdated(prediction.predictor, profile.reputationScore);
        }

        uint256 totalIncorrectStake = eventData.totalStaked - totalAccurateStake;
        uint256 totalWinningsCalculated = 0;

        // Phase 2: Calculate individual payout amounts (original stake + proportional winnings)
        if (accuratePredictionCount > 0) {
            // Rewards come from the pool of lost stakes (incorrect predictions)
            uint256 rewardsFromIncorrectStakes = totalIncorrectStake;

            for (uint256 i = 0; i < eventPredictions[_eventId].length; i++) {
                Prediction storage prediction = eventPredictions[_eventId][i];
                if (prediction.isAccurate) {
                    // Winnings are proportional to the stake size among accurate predictors
                    uint256 winnings = (rewardsFromIncorrectStakes * prediction.stakeAmount) / totalAccurateStake;
                    prediction.payoutAmount = prediction.stakeAmount + winnings; // Original stake + proportional winnings
                    totalWinningsCalculated += winnings; // Only sum the 'profit' part for the event
                } else {
                    prediction.payoutAmount = 0; // Stake is lost
                }
            }
        } else {
            // No accurate predictions. All staked ETH (both accurate and inaccurate)
            // remains in the contract, available for owner withdrawal.
            for (uint256 i = 0; i < eventPredictions[_eventId].length; i++) {
                Prediction storage prediction = eventPredictions[_eventId][i];
                prediction.payoutAmount = 0; // No payout for anyone
            }
        }

        eventData.totalStaked = 0; // All stakes are now either lost or assigned a payout amount.
        return totalWinningsCalculated;
    }

    /// @dev Mock function for evaluating prediction accuracy.
    /// In a real system, this would be a complex comparison based on the event's specification.
    /// For this example, it's a direct hash match.
    /// @param _outcomeSpecHash The specification of how to evaluate (e.g., IPFS CID to rules).
    /// @param _predictionHash The user's prediction data hash.
    /// @param _actualOutcomeHash The true outcome hash, submitted by the arbitrator.
    /// @return True if the prediction is deemed accurate, false otherwise.
    function _evaluatePredictionAccuracy(bytes32 _outcomeSpecHash, bytes32 _predictionHash, bytes32 _actualOutcomeHash) internal pure returns (bool) {
        // This is a simplified mock. In a real dApp, the logic would be:
        // 1. Fetch _outcomeSpecHash from IPFS to parse evaluation rules (e.g., "within 5% of ETH price at X time").
        // 2. Fetch _predictionHash from IPFS to get user's prediction (e.g., "$3500").
        // 3. Fetch _actualOutcomeHash from IPFS to get actual outcome (e.g., "$3480").
        // 4. Perform complex comparison based on rules (e.g., is $3500 within 5% of $3480?).
        // For the example, we assume `_predictionDataHash` directly matches `_actualOutcomeHash` for accuracy.
        return _predictionHash == _actualOutcomeHash;
    }
}

```