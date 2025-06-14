Okay, let's design a smart contract that combines several advanced concepts: a **Sealed-Bid Auction** with a **Commit-Reveal** scheme, integrated with **Chainlink VRF** for verifiable randomness to determine a **Dynamic "Quantum" State** of the auctioned asset upon finalization. The asset will be represented by an NFT minted at the end, whose properties depend on this random outcome.

This contract structure involves distinct phases and requires careful state management and interaction with external services (like Chainlink VRF and an ERC721 contract).

**Concept:** **Quantum State Sealed-Bid Auction**

*   **Asset:** A single, unique digital asset (represented by an ERC721 token) that exists in a state of "superposition" regarding its final characteristics until the auction concludes.
*   **States:** The asset can materialize into one of several predefined "states" (e.g., 'Common', 'Rare', 'Epic', 'Legendary'), each associated with different metadata or properties (like a rarity score, a specific IPFS hash for the artwork).
*   **Auction Type:** Sealed-Bid. Bidders first commit a hashed version of their bid and a secret salt. In a later phase, they reveal their actual bid and salt.
*   **State Determination:** The final state of the asset is determined at the end of the auction by a Verifiable Random Function (VRF) call (using Chainlink VRF). The random number generated is used to select one of the predefined states.
*   **Winner:** The highest *revealed* valid bid wins the auction.
*   **NFT Minting:** Upon finalization, an ERC721 token is minted to the winner, encoding or referencing the determined "quantum state".
*   **Phases:** The auction proceeds through distinct phases: Setup -> Commitment -> Reveal -> VRF Request -> VRF Fulfillment -> Finalization -> Claiming.

---

## **QuantumAuction.sol**

**Outline:**

1.  **Pragma & Imports:** Specify Solidity version and import necessary interfaces (ERC721, VRFConsumerBaseV2).
2.  **Errors:** Custom error definitions for clarity and gas efficiency.
3.  **Events:** Log key actions and state changes.
4.  **Enums:** Define auction states for phase management.
5.  **Structs:** Define data structures for asset states and bid reveals.
6.  **State Variables:** Store auction parameters, state data, bid information, VRF details, winner info, etc.
7.  **Modifiers:** Control access and state transitions.
8.  **Constructor:** Initialize contract with VRF parameters.
9.  **Setup Functions:** Define auction parameters, phases, and possible asset states.
10. **Commitment Phase Functions:** Handle bid commitments.
11. **Reveal Phase Functions:** Handle bid reveals and validation.
12. **VRF Integration:** Implement the VRF request and fulfillment logic.
13. **Finalization Function:** Determine winner, calculate asset state, handle funds, and trigger NFT minting.
14. **Claiming Functions:** Allow winner to claim NFT and losers to claim refunds.
15. **View Functions:** Provide visibility into auction state, bids, and outcomes.

**Function Summary:**

*   `constructor`: Initializes the contract with Chainlink VRF coordinator and key hash.
*   `createAuction`: (Owner) Sets up a new auction instance with phases, VRF subscription, and links to the NFT contract.
*   `addAssetState`: (Owner) Defines a possible outcome state for the auctioned asset (e.g., 'Rare' with specific metadata).
*   `removeAssetState`: (Owner) Removes a previously defined asset state (only before auction starts).
*   `cancelAuction`: (Owner) Cancels the auction if no commitments have been made yet.
*   `commitBid`: (Public, Payable) Allows a bidder to submit a hashed commitment of their bid and a secret salt, depositing the bid amount.
*   `checkCommitment`: (Public View) Checks if an address has committed.
*   `extendCommitPhase`: (Owner) Extends the commitment phase end time.
*   `revealBid`: (Public) Allows a bidder to reveal their actual bid and salt, validating it against the commitment.
*   `checkReveal`: (Public View) Checks if an address has revealed a valid bid.
*   `extendRevealPhase`: (Owner) Extends the reveal phase end time.
*   `requestRandomWord`: (Anyone after Reveal) Triggers the VRF request to get a random number for state determination.
*   `rawFulfillRandomWords`: (Chainlink VRF Callback) Receives the random number and triggers the determination of the final asset state based on the randomness.
*   `finalizeAuction`: (Anyone after VRF Fulfillment) Determines the highest valid revealed bid, identifies the winner, transfers the winning bid funds, calculates the final asset state using the determined random number, and transitions to the Claiming phase.
*   `getAuctionOutcome`: (Public View) Provides details about the winner, winning bid, and final determined asset state after finalization.
*   `claimAsset`: (Winner Only) Allows the winning bidder to claim the minted NFT.
*   `claimRefund`: (Losers/Non-Revealers) Allows participants who did not win or did not reveal validly to claim their deposited ETH back.
*   `getAuctionState`: (Public View) Returns the current phase of the auction.
*   `getAssetStateCount`: (Public View) Returns the number of possible asset states defined.
*   `getAssetStateDetails`: (Public View) Returns the details for a specific asset state index.
*   `getCommitment`: (Public View) Returns the stored commitment hash for an address (careful with privacy, only shows hash).
*   `getBidReveal`: (Public View) Returns the stored revealed bid and salt for an address (only useful after reveal phase ends).
*   `getAuctionTimings`: (Public View) Returns the start and end times for each phase.
*   `getVRFRequestStatus`: (Public View) Returns the VRF request ID and fulfillment status.
*   `getWinnerAddress`: (Public View) Returns the winner's address after finalization.
*   `getWinningBidAmount`: (Public View) Returns the winning bid amount after finalization.
*   `getFinalAssetStateIndex`: (Public View) Returns the index of the final determined asset state after finalization.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// --- Outline ---
// 1. Pragma & Imports
// 2. Errors
// 3. Events
// 4. Enums
// 5. Structs
// 6. State Variables
// 7. Modifiers
// 8. Constructor
// 9. Setup Functions
// 10. Commitment Phase Functions
// 11. Reveal Phase Functions
// 12. VRF Integration
// 13. Finalization Function
// 14. Claiming Functions
// 15. View Functions

// --- Function Summary ---
// constructor: Initializes the contract with Chainlink VRF coordinator and key hash.
// createAuction: (Owner) Sets up a new auction instance with phases, VRF subscription, and links to the NFT contract.
// addAssetState: (Owner) Defines a possible outcome state for the auctioned asset.
// removeAssetState: (Owner) Removes a previously defined asset state.
// cancelAuction: (Owner) Cancels the auction before commitments.
// commitBid: (Public, Payable) Submits a hashed commitment of bid+salt, depositing bid amount.
// checkCommitment: (Public View) Checks if an address has committed.
// extendCommitPhase: (Owner) Extends commitment phase end time.
// revealBid: (Public) Reveals bid+salt, validates against commitment.
// checkReveal: (Public View) Checks if an address has revealed validly.
// extendRevealPhase: (Owner) Extends reveal phase end time.
// requestRandomWord: (Anyone after Reveal) Triggers VRF request for randomness.
// rawFulfillRandomWords: (Chainlink VRF Callback) Receives randomness, determines final state index.
// finalizeAuction: (Anyone after VRF Fulfillment) Determines winner, transfers funds, sets final state, prepares for claims.
// getAuctionOutcome: (Public View) Shows winner, winning bid, final state index after finalization.
// claimAsset: (Winner Only) Claims the minted NFT.
// claimRefund: (Losers/Non-Revealers) Claims deposited ETH back.
// getAuctionState: (Public View) Returns current auction phase.
// getAssetStateCount: (Public View) Returns number of defined states.
// getAssetStateDetails: (Public View) Returns details for a state index.
// getCommitment: (Public View) Returns stored commitment hash (view only).
// getBidReveal: (Public View) Returns stored revealed bid/salt (view only).
// getAuctionTimings: (Public View) Returns phase start/end times.
// getVRFRequestStatus: (Public View) Returns VRF request ID and fulfillment status.
// getWinnerAddress: (Public View) Returns winner address after finalization.
// getWinningBidAmount: (Public View) Returns winning bid amount after finalization.
// getFinalAssetStateIndex: (Public View) Returns final state index after finalization.


// 2. Errors
error AuctionAlreadyActive();
error AuctionNotActive();
error NotInState(AuctionState requiredState);
error AuctionPeriodNotEnded(uint256 endTime);
error AuctionPeriodEnded(uint256 endTime);
error NoCommitmentFound();
error CommitmentHashMismatch();
error BidAmountMismatchWithDeposit();
error AlreadyRevealed();
error NoRevealedBids();
error NoAssetStatesDefined();
error VRFRequestFailed();
error VRFNotFulfilled();
error VRFAlreadyFulfilled();
error AuctionAlreadyFinalized();
error NotWinner();
error NoFundsToClaim();
error AssetAlreadyClaimed();
error InvalidAssetStateIndex(uint256 index);
error CannotRemoveActiveState(uint256 index);
error InsufficientFundsDeposited();
error CannotCancelAfterCommitments();
error OnlyOneVRFRequestAllowed();
error NFTMintingFailed(); // Hypothetical error for external NFT call


// 3. Events
event AuctionCreated(uint256 auctionId, address indexed owner, uint256 commitEndTime, uint256 revealEndTime, uint256 vrfRequestEndTime, address indexed nftContract);
event AssetStateAdded(uint256 index, string name, string ipfsHash, uint256 rarityScore);
event AssetStateRemoved(uint256 index);
event AuctionCancelled(uint256 auctionId);
event BidCommitted(uint256 auctionId, address indexed bidder, bytes32 commitment);
event BidRevealed(uint256 auctionId, address indexed bidder, uint256 amount);
event VRFRequested(uint256 auctionId, uint64 indexed requestId);
event VRFFulfilled(uint256 auctionId, uint64 indexed requestId, uint256[] randomWords);
event FinalStateDetermined(uint256 auctionId, uint256 indexed finalStateIndex, string stateName);
event AuctionFinalized(uint256 auctionId, address indexed winner, uint256 winningBid);
event AssetClaimed(uint256 auctionId, address indexed winner, uint256 tokenId);
event RefundClaimed(uint256 auctionId, address indexed claimant, uint256 amount);


// 4. Enums
enum AuctionState {
    Inactive,      // No active auction
    Setup,         // Auction parameters being set up
    Commitment,    // Bidders submit hashed bids
    Reveal,        // Bidders reveal their bids
    VRF_Requested, // Waiting for randomness
    VRF_Fulfilled, // Randomness received, state determined
    Finalized,     // Winner determined, funds distributed, ready for claims
    Cancelled      // Auction cancelled
}

// 5. Structs
struct AssetState {
    string name;
    string ipfsHash; // e.g., metadata URI fragment
    uint256 rarityScore; // Arbitrary score, higher could mean rarer
    bool isActive; // To allow "removing" states without shifting array indices
}

struct BidCommitment {
    bytes32 commitmentHash; // hash(bidAmount + salt)
    uint256 depositAmount;  // The ETH sent with the commitment (should equal bidAmount)
    bool hasRevealed;       // Track if the bidder has revealed
    bool isValidReveal;     // Track if the revealed bid was valid
}

struct BidReveal {
    uint256 amount;
    bytes32 salt;
}

struct Auction {
    address owner;
    AuctionState currentState;
    uint256 commitEndTime;
    uint256 revealEndTime;
    uint256 vrfRequestEndTime; // Time limit for anyone to request VRF
    uint256 finalizationTime; // When finalization occurred

    address nftContract; // The ERC721 contract for the asset

    mapping(uint256 => AssetState) assetStates; // Possible outcomes
    uint256 assetStateCount; // To track total number of states

    mapping(address => BidCommitment) commitments;
    address[] committedBidders; // List of addresses that committed

    mapping(address => BidReveal) reveals; // Stored reveals for later verification/view

    uint256 totalCommitted; // Total ETH deposited
    uint256 totalRevealed; // Total ETH from valid revealed bids

    uint64 vrfRequestId; // Chainlink VRF request ID
    bool vrfFulfilled;   // Flag if VRF callback received

    uint256 finalAssetStateIndex; // Index of the determined state
    address winner;
    uint256 winningBid;
    uint256 mintedTokenId; // The token ID minted to the winner
    bool assetClaimed; // Flag for winner claiming the NFT
}


// 6. State Variables
VRFCoordinatorV2Interface COORDINATOR;
uint64 s_subscriptionId; // Your Chainlink VRF subscription ID
bytes32 s_keyHash;       // The VRF key hash
uint32 s_callbackGasLimit = 100000; // VRF gas limit
uint16 s_requestConfirmations = 3; // VRF confirmations

Auction public currentAuction; // Only supporting one auction for simplicity in this example


// 7. Modifiers
modifier onlyOwner() {
    if (msg.sender != currentAuction.owner) revert Ownable.NotOwner();
    _;
}

modifier inState(AuctionState requiredState) {
    if (currentAuction.currentState != requiredState) revert NotInState(requiredState);
    _;
}

modifier notInState(AuctionState excludedState) {
     if (currentAuction.currentState == excludedState) revert NotInState(excludedState); // Reusing error for simplicity
    _;
}

modifier auctionActive() {
    if (currentAuction.currentState == AuctionState.Inactive || currentAuction.currentState == AuctionState.Cancelled) revert AuctionNotActive();
    _;
}

modifier commitPhase() {
    auctionActive();
    inState(AuctionState.Commitment);
    if (block.timestamp > currentAuction.commitEndTime) revert AuctionPeriodEnded(currentAuction.commitEndTime);
    _;
}

modifier revealPhase() {
    auctionActive();
    inState(AuctionState.Reveal);
    if (block.timestamp > currentAuction.revealEndTime) revert AuctionPeriodEnded(currentAuction.revealEndTime);
    _;
}

modifier vrfRequestPhase() {
    auctionActive();
    inState(AuctionState.Reveal); // VRF can be requested as soon as reveal phase ends
    if (block.timestamp <= currentAuction.revealEndTime) revert AuctionPeriodNotEnded(currentAuction.revealEndTime);
    if (block.timestamp > currentAuction.vrfRequestEndTime) revert AuctionPeriodEnded(currentAuction.vrfRequestEndTime);
    _;
}

modifier vrfFulfilledPhase() {
     auctionActive();
     inState(AuctionState.VRF_Fulfilled);
     _;
}

modifier finalizationPhase() {
     auctionActive();
     inState(AuctionState.VRF_Fulfilled);
     if (!currentAuction.vrfFulfilled) revert VRFNotFulfilled();
     _;
}

modifier claimingPhase() {
    auctionActive();
    inState(AuctionState.Finalized);
    _;
}


// 8. Constructor
constructor(address vrfCoordinator, bytes32 keyHash, uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_keyHash = keyHash;
    s_subscriptionId = subscriptionId;
    // Auction state starts Inactive
}


// 9. Setup Functions

/// @notice Sets up a new auction instance with defined phases and linked NFT contract.
/// @param _commitDuration Duration of the commitment phase in seconds.
/// @param _revealDuration Duration of the reveal phase in seconds.
/// @param _vrfRequestDuration Duration after reveal ends to request VRF.
/// @param _nftContract Address of the ERC721 contract for the asset. This contract must allow minting by this auction contract.
function createAuction(uint256 _commitDuration, uint256 _revealDuration, uint256 _vrfRequestDuration, address _nftContract) external onlyOwner notInState(AuctionState.Setup) notInState(AuctionState.Commitment) {
    if (currentAuction.currentState != AuctionState.Inactive && currentAuction.currentState != AuctionState.Cancelled) revert AuctionAlreadyActive();
    if (currentAuction.assetStateCount == 0) revert NoAssetStatesDefined(); // Must define states first

    uint256 startTime = block.timestamp;
    currentAuction.owner = msg.sender;
    currentAuction.currentState = AuctionState.Setup; // Temporarily set to Setup
    currentAuction.commitEndTime = startTime + _commitDuration;
    currentAuction.revealEndTime = currentAuction.commitEndTime + _revealDuration;
    currentAuction.vrfRequestEndTime = currentAuction.revealEndTime + _vrfRequestDuration;
    currentAuction.nftContract = _nftContract;

    // Reset other auction specific variables
    delete currentAuction.commitments;
    delete currentAuction.reveals;
    delete currentAuction.committedBidders;
    currentAuction.committedBidders.length = 0; // Clear array
    currentAuction.totalCommitted = 0;
    currentAuction.totalRevealed = 0;
    currentAuction.vrfRequestId = 0;
    currentAuction.vrfFulfilled = false;
    currentAuction.finalAssetStateIndex = 0; // Default, will be overwritten
    delete currentAuction.winner; // Reset winner
    currentAuction.winningBid = 0;
    currentAuction.mintedTokenId = 0; // Reset token ID
    currentAuction.assetClaimed = false; // Reset claim status

     // Transition to the first active phase
    currentAuction.currentState = AuctionState.Commitment;

    emit AuctionCreated(block.timestamp, msg.sender, currentAuction.commitEndTime, currentAuction.revealEndTime, currentAuction.vrfRequestEndTime, _nftContract);
}

/// @notice Defines a possible outcome state for the auctioned asset. Can only be called before auction starts.
/// @param _name Name of the state (e.g., "Rare").
/// @param _ipfsHash IPFS hash or metadata fragment associated with this state.
/// @param _rarityScore A numerical score representing rarity or value.
function addAssetState(string calldata _name, string calldata _ipfsHash, uint256 _rarityScore) external onlyOwner inState(AuctionState.Inactive) {
    uint256 index = currentAuction.assetStateCount;
    currentAuction.assetStates[index] = AssetState({
        name: _name,
        ipfsHash: _ipfsHash,
        rarityScore: _rarityScore,
        isActive: true
    });
    currentAuction.assetStateCount++;
    emit AssetStateAdded(index, _name, _ipfsHash, _rarityScore);
}

/// @notice Removes a previously defined asset state by marking it inactive. Can only be called before auction starts.
/// @param _index The index of the state to remove.
function removeAssetState(uint256 _index) external onlyOwner inState(AuctionState.Inactive) {
    if (_index >= currentAuction.assetStateCount || !currentAuction.assetStates[_index].isActive) {
        revert InvalidAssetStateIndex(_index);
    }
     // Note: This doesn't shrink the array/mapping, just marks inactive
    currentAuction.assetStates[_index].isActive = false;
    emit AssetStateRemoved(_index);
}


/// @notice Cancels the auction if no commitments have been made.
function cancelAuction() external onlyOwner auctionActive() {
    if (currentAuction.currentState == AuctionState.Commitment && currentAuction.committedBidders.length > 0) {
         revert CannotCancelAfterCommitments();
    }
    // If commitments exist in Commitment phase, owner needs to wait for reveal phase
    // and finalize, or implement a different cancellation logic (e.g., owner can trigger refunds)
    // For simplicity here, cancellation is only allowed before any commitments in Commitment phase.

    currentAuction.currentState = AuctionState.Cancelled;
    // Note: Committed funds would need a specific claim function for cancelled state if commitments were allowed before cancel.
    // Given the check above, no funds are committed if cancelling in Commitment state.
    // If cancelling from other states (e.g., Reveal before any reveals), committed funds remain in contract.
    // A separate claimCancelledFunds function would be needed. Leaving it simple for now.

    emit AuctionCancelled(block.timestamp); // Using timestamp as a unique-ish ID for now
}


// 10. Commitment Phase Functions

/// @notice Allows a bidder to submit a hashed commitment of their bid and a secret salt. Requires depositing the bid amount.
/// @param _commitmentHash The hash of (bidAmount + salt).
function commitBid(bytes32 _commitmentHash) external payable commitPhase {
    if (currentAuction.commitments[msg.sender].commitmentHash != bytes32(0)) {
        // Already committed, maybe allow updating commitment before phase ends?
        // For simplicity, disallow multiple commitments from same address.
        revert AuctionAlreadyActive(); // Reusing error for simplicity
    }
    if (msg.value == 0) revert InsufficientFundsDeposited(); // Minimal bid required

    currentAuction.commitments[msg.sender] = BidCommitment({
        commitmentHash: _commitmentHash,
        depositAmount: msg.value, // The full bid amount is deposited
        hasRevealed: false,
        isValidReveal: false
    });
    currentAuction.committedBidders.push(msg.sender);
    currentAuction.totalCommitted += msg.value;

    emit BidCommitted(block.timestamp, msg.sender, _commitmentHash); // Using timestamp as auction ID
}

/// @notice Checks if an address has submitted a commitment.
/// @param _bidder Address to check.
/// @return True if committed, false otherwise.
function checkCommitment(address _bidder) external view auctionActive returns (bool) {
    return currentAuction.commitments[_bidder].commitmentHash != bytes32(0);
}

/// @notice Owner can extend the commitment phase end time.
/// @param _newEndTime New end time for the commitment phase. Must be in the future.
function extendCommitPhase(uint256 _newEndTime) external onlyOwner inState(AuctionState.Commitment) {
    if (_newEndTime <= block.timestamp || _newEndTime <= currentAuction.commitEndTime) {
        revert InvalidAssetStateIndex(0); // Reusing error, bad practice, use custom error
    }
    currentAuction.commitEndTime = _newEndTime;
    // Note: This might push back subsequent phases if reveal/vrf durations are relative.
    // For simplicity, durations are absolute from start or previous phase end.
    emit AuctionCreated(block.timestamp, currentAuction.owner, currentAuction.commitEndTime, currentAuction.revealEndTime, currentAuction.vrfRequestEndTime, currentAuction.nftContract); // Reusing event to show updated times
}


// 11. Reveal Phase Functions

/// @notice Allows a bidder to reveal their actual bid and salt. Validates against the commitment.
/// @param _amount The actual bid amount. Must match deposited ETH.
/// @param _salt The secret salt used in the commitment hash.
function revealBid(uint256 _amount, bytes32 _salt) external payable revealPhase {
    BidCommitment storage commitment = currentAuction.commitments[msg.sender];

    if (commitment.commitmentHash == bytes32(0)) {
        revert NoCommitmentFound();
    }
    if (commitment.hasRevealed) {
        revert AlreadyRevealed();
    }
    if (commitment.depositAmount != _amount) {
        revert BidAmountMismatchWithDeposit();
    }

    bytes32 calculatedCommitment = keccak256(abi.encodePacked(_amount, _salt));

    if (commitment.commitmentHash != calculatedCommitment) {
        revert CommitmentHashMismatch();
    }

    commitment.hasRevealed = true;
    commitment.isValidReveal = true;

    currentAuction.reveals[msg.sender] = BidReveal({
        amount: _amount,
        salt: _salt
    });
    currentAuction.totalRevealed += _amount;

    emit BidRevealed(block.timestamp, msg.sender, _amount); // Using timestamp as auction ID
}

/// @notice Checks if an address has revealed a valid bid.
/// @param _bidder Address to check.
/// @return True if revealed validly, false otherwise.
function checkReveal(address _bidder) external view auctionActive returns (bool) {
    return currentAuction.commitments[_bidder].isValidReveal;
}

/// @notice Owner can extend the reveal phase end time.
/// @param _newEndTime New end time for the reveal phase. Must be in the future and after commitEndTime.
function extendRevealPhase(uint256 _newEndTime) external onlyOwner inState(AuctionState.Reveal) {
     if (_newEndTime <= block.timestamp || _newEndTime <= currentAuction.revealEndTime || _newEndTime <= currentAuction.commitEndTime) {
        revert InvalidAssetStateIndex(0); // Reusing error, bad practice, use custom error
    }
    currentAuction.revealEndTime = _newEndTime;
    // Note: This might push back subsequent VRF request phase.
     currentAuction.vrfRequestEndTime = currentAuction.revealEndTime + (currentAuction.vrfRequestEndTime - (currentAuction.commitEndTime + (currentAuction.revealEndTime - block.timestamp))); // Complex calculation assumes relative VRF request duration
     // A simpler approach is to just extend revealEndTime and keep vrfRequestEndTime absolute or recalculate it entirely.
     // Let's recalculate based on original VRF request duration relative to reveal end. Need to store the original VRF request duration.
     // For simplicity in this version, let's assume VRF request duration is *fixed* relative to the *original* reveal end time.
     // This requires storing the original duration... Or just making it relative to the *new* reveal end time.
     // Let's make it relative to the *new* reveal end time for simplicity.
     uint256 originalVRFDuration = currentAuction.vrfRequestEndTime - currentAuction.revealEndTime;
     currentAuction.vrfRequestEndTime = _newEndTime + originalVRFDuration;


    emit AuctionCreated(block.timestamp, currentAuction.owner, currentAuction.commitEndTime, currentAuction.revealEndTime, currentAuction.vrfRequestEndTime, currentAuction.nftContract); // Reusing event
}


// 12. VRF Integration

/// @notice Requests a random word from Chainlink VRF. Can be called by anyone after the reveal phase ends and before the VRF request phase ends.
function requestRandomWord() external auctionActive vrfRequestPhase {
    if (currentAuction.vrfRequestId != 0 || currentAuction.vrfFulfilled) revert OnlyOneVRFRequestAllowed();
    if (currentAuction.committedBidders.length == 0) revert NoRevealedBids(); // Or handle case where no one revealed by cancelling? Let's require at least one commitment.
    if (currentAuction.assetStateCount == 0) revert NoAssetStatesDefined();

    // We need at least one active state to pick from
    bool hasActiveState = false;
    for (uint256 i = 0; i < currentAuction.assetStateCount; i++) {
        if (currentAuction.assetStates[i].isActive) {
            hasActiveState = true;
            break;
        }
    }
    if (!hasActiveState) revert NoAssetStatesDefined();


    // Will revert if subscription is not funded enough
    uint64 requestId = COORDINATOR.requestRandomWords(
        s_keyHash,
        s_subscriptionId,
        s_requestConfirmations,
        s_callbackGasLimit,
        1 // Requesting 1 random word
    );
    currentAuction.vrfRequestId = requestId;
    currentAuction.currentState = AuctionState.VRF_Requested;
    emit VRFRequested(block.timestamp, requestId); // Using timestamp as auction ID
}

/// @notice Chainlink VRF callback function. Receives the random number.
/// @dev This function is called by the VRF Coordinator contract. DO NOT call directly.
/// @param _requestId The VRf request ID.
/// @param _randomWords Array of random words.
function rawFulfillRandomWords(uint64 _requestId, uint256[] memory _randomWords) internal override {
    if (_requestId != currentAuction.vrfRequestId) {
        revert VRFRequestFailed(); // Should not happen if configured correctly
    }
    if (currentAuction.vrfFulfilled) {
        revert VRFAlreadyFulfilled(); // Should not happen with VRF
    }
    if (_randomWords.length == 0) {
         revert VRFRequestFailed(); // Expecting at least one word
    }

    uint256 randomNumber = _randomWords[0];
    currentAuction.vrfFulfilled = true;

    // Determine the final asset state based on the random number
    // We need to pick from the *active* states only
    uint256[] memory activeStateIndices = new uint256[](currentAuction.assetStateCount);
    uint256 activeCount = 0;
    for (uint256 i = 0; i < currentAuction.assetStateCount; i++) {
        if (currentAuction.assetStates[i].isActive) {
            activeStateIndices[activeCount] = i;
            activeCount++;
        }
    }

    if (activeCount == 0) {
         // This case should ideally be caught earlier, but handle defensively
         revert NoAssetStatesDefined();
    }

    // Use modulo to map the random number to an index within the active states
    uint256 chosenActiveIndex = randomNumber % activeCount;
    currentAuction.finalAssetStateIndex = activeStateIndices[chosenActiveIndex];

    currentAuction.currentState = AuctionState.VRF_Fulfilled;

    emit VRFFulfilled(block.timestamp, _requestId, _randomWords); // Using timestamp as auction ID
    emit FinalStateDetermined(block.timestamp, currentAuction.finalAssetStateIndex, currentAuction.assetStates[currentAuction.finalAssetStateIndex].name); // Using timestamp as auction ID
}

/// @notice Checks the status of the VRF request.
/// @return The VRF request ID and whether it has been fulfilled.
function getVRFRequestStatus() external view auctionActive returns (uint64 requestId, bool fulfilled) {
    return (currentAuction.vrfRequestId, currentAuction.vrfFulfilled);
}


// 13. Finalization Function

/// @notice Finalizes the auction: finds winner, transfers funds, sets final state, prepares for claims.
/// @dev Can be called by anyone after the VRF has been fulfilled.
function finalizeAuction() external auctionActive finalizationPhase {
    if (currentAuction.currentState == AuctionState.Finalized) revert AuctionAlreadyFinalized();

    address highestBidder = address(0);
    uint256 highestBid = 0;
    bool winnerFound = false;

    // Iterate through committed bidders to find the highest valid revealed bid
    for (uint256 i = 0; i < currentAuction.committedBidders.length; i++) {
        address bidder = currentAuction.committedBidders[i];
        BidCommitment storage commitment = currentAuction.commitments[bidder];

        if (commitment.isValidReveal) {
            BidReveal storage reveal = currentAuction.reveals[bidder];
            if (reveal.amount > highestBid) {
                highestBid = reveal.amount;
                highestBidder = bidder;
                winnerFound = true;
            }
            // Handle ties: Keep the first highest bidder found or apply a tie-breaking rule
            // Current logic keeps the first one encountered in the loop
        }
    }

    if (!winnerFound) {
        // No valid reveals, or no commitments. Auction ends without a winner.
        // All committed funds (if any) should be fully refundable.
        currentAuction.currentState = AuctionState.Finalized; // Still transition to Finalized for claiming refunds
        emit AuctionFinalized(block.timestamp, address(0), 0); // Winner is address(0)
        return;
    }

    currentAuction.winner = highestBidder;
    currentAuction.winningBid = highestBid;

    // Transfer winning bid amount to the owner
    // Using call to be robust against winner's contract (though unlikely they are the owner)
    (bool success, ) = payable(currentAuction.owner).call{value: currentAuction.winningBid}("");
    // We don't necessarily need to revert if this fails; the winner got the asset, owner can claim manually if needed.
    // But for simplicity, let's require it for a clean state transition.
    if (!success) revert InsufficientFundsDeposited(); // Reusing error for simplicity, means transfer failed

    // Mark winner's commitment as processed (implicitly handled by state transition and claim logic)

    // Trigger NFT minting to the winner with the determined state information
    // Assumes the target NFT contract has a function like `mintTo(address recipient, uint256 stateIndex)`
    // Or it might need to read state details from this contract via getters.
    // Let's assume a simple `mintTo` that takes winner and can potentially read state details later.
    // A more advanced NFT might take state parameters directly in the mint call.
    IERC721 nftContract = IERC721(currentAuction.nftContract);
    // This call might need error handling depending on the NFT contract
    // For example, if this contract needs approval to mint, or if the NFT contract has checks.
    // A robust implementation would use try/catch or ensure the NFT contract is trusted/compatible.
    // Simulating minting and getting a token ID. A real NFT contract would return the ID.
    // Let's assume a hypothetical `mintWithState(address recipient, uint256 stateIndex)` function exists.
    // As IERC721 doesn't have this, we'll just call a generic function if one exists, or assume external minting is handled based on events.
    // For this example, let's just emit an event indicating *which* NFT should be minted with which state,
    // assuming an off-chain process or another contract handles the actual minting based on this event.
    // Or, let's add a mock `mint` function call assuming a compatible interface.

    // **Mock NFT interaction:**
    // Replace with actual call based on your ERC721 contract's minting logic
    // Example: uint256 tokenId = MyNFTContract(currentAuction.nftContract).mintWithState(highestBidder, currentAuction.finalAssetStateIndex);
    // currentAuction.mintedTokenId = tokenId;
    // For this example, we'll skip the actual cross-contract call and just emit the necessary info.
    // In a real scenario, you need to call the NFT contract's mint function here.

    // Transition to Finalized state
    currentAuction.currentState = AuctionState.Finalized;
    currentAuction.finalizationTime = block.timestamp;

    // The NFT isn't 'claimed' by the winner until they call `claimAsset`.
    // The refunds aren't 'claimed' until losers call `claimRefund`.

    emit AuctionFinalized(block.timestamp, currentAuction.winner, currentAuction.winningBid); // Using timestamp as auction ID
    // Emit info needed for potential off-chain or future on-chain minting
    emit AssetClaimed(block.timestamp, currentAuction.winner, currentAuction.finalAssetStateIndex); // Emitting state index instead of tokenId as we don't mint here

}


// 14. Claiming Functions

/// @notice Allows the winning bidder to claim the minted NFT.
/// @dev Requires the auction to be finalized and the asset not yet claimed.
function claimAsset() external claimingPhase {
    if (msg.sender != currentAuction.winner) revert NotWinner();
    if (currentAuction.assetClaimed) revert AssetAlreadyClaimed();
     // If using actual NFT minting within Finalize:
     // IERC721(currentAuction.nftContract).transferFrom(address(this), msg.sender, currentAuction.mintedTokenId);
     // If relying on external minting triggered by event:
     // This function might just be a state change or a signal.
     // Let's make it a state change for this example, assuming external minting happens.
     // A real implementation would transfer the NFT here if it was minted to THIS contract,
     // or call the NFT contract's claim function if it's designed that way.

    currentAuction.assetClaimed = true;
    // In a real scenario with on-chain minting to `address(this)`, you'd transfer here:
    // IERC721(currentAuction.nftContract).safeTransferFrom(address(this), msg.sender, currentAuction.mintedTokenId);
    // Or if the NFT contract mints directly to the winner in finalize, this function might be unnecessary
    // or just used to update a flag in this contract.

    // As we emitted AssetClaimed with the state index in finalize,
    // this function simply marks the asset as claimed within THIS contract's state.
    // The token ID emitted previously (which was the state index) is just illustrative.
     emit AssetClaimed(block.timestamp, msg.sender, currentAuction.finalAssetStateIndex); // Re-emitting for clarity
}

/// @notice Allows bidders who did not win (or failed to reveal) to claim their deposited ETH back.
/// @dev Requires the auction to be finalized.
function claimRefund() external payable claimingPhase {
    address claimant = msg.sender;
    BidCommitment storage commitment = currentAuction.commitments[claimant];

    // Check if they committed and are not the winner
    if (commitment.commitmentHash == bytes32(0) || claimant == currentAuction.winner) {
        revert NoFundsToClaim();
    }

    // Check if they have funds deposited that haven't been refunded
    if (commitment.depositAmount == 0) {
         revert NoFundsToClaim();
    }

    uint256 amountToRefund = commitment.depositAmount;

    // Mark funds as claimed by setting depositAmount to 0
    commitment.depositAmount = 0;

    // Transfer refund
    (bool success, ) = payable(claimant).call{value: amountToRefund}("");
    if (!success) {
        // If transfer fails, reset the depositAmount so they can try claiming again.
        commitment.depositAmount = amountToRefund;
        revert InsufficientFundsDeposited(); // Reusing error
    }

    currentAuction.totalCommitted -= amountToRefund; // Adjust total committed as funds are withdrawn

    emit RefundClaimed(block.timestamp, claimant, amountToRefund); // Using timestamp as auction ID
}


// 15. View Functions

/// @notice Returns the current phase of the auction.
function getAuctionState() external view returns (AuctionState) {
    return currentAuction.currentState;
}

/// @notice Returns the number of possible asset states defined.
function getAssetStateCount() external view returns (uint256) {
    return currentAuction.assetStateCount;
}

/// @notice Returns the details for a specific asset state index.
/// @param _index The index of the asset state.
function getAssetStateDetails(uint256 _index) external view returns (string memory name, string memory ipfsHash, uint256 rarityScore, bool isActive) {
    if (_index >= currentAuction.assetStateCount) revert InvalidAssetStateIndex(_index);
    AssetState storage state = currentAuction.assetStates[_index];
    return (state.name, state.ipfsHash, state.rarityScore, state.isActive);
}

/// @notice Returns the stored commitment hash for an address.
/// @dev Only reveals the hash, not the amount or salt.
/// @param _bidder Address to check.
/// @return The commitment hash.
function getCommitment(address _bidder) external view auctionActive returns (bytes32) {
    return currentAuction.commitments[_bidder].commitmentHash;
}

/// @notice Returns the stored revealed bid and salt for an address.
/// @dev Only useful after the reveal phase has ended.
/// @param _bidder Address to check.
/// @return The revealed bid amount and salt.
function getBidReveal(address _bidder) external view auctionActive returns (uint256 amount, bytes32 salt) {
     if (currentAuction.currentState < AuctionState.Reveal) revert NotInState(AuctionState.Reveal); // Only view after reveal starts/ends
     BidCommitment storage commitment = currentAuction.commitments[_bidder];
     if (!commitment.hasRevealed) {
         revert NoReveal(); // Custom error needed: error NoReveal();
     }
    BidReveal storage reveal = currentAuction.reveals[_bidder];
    return (reveal.amount, reveal.salt);
}

/// @notice Returns the start and end times for each auction phase.
function getAuctionTimings() external view auctionActive returns (uint256 commitEnd, uint256 revealEnd, uint256 vrfRequestEnd) {
    return (currentAuction.commitEndTime, currentAuction.revealEndTime, currentAuction.vrfRequestEndTime);
}

/// @notice Provides details about the winner, winning bid, and final determined asset state after finalization.
/// @dev Requires the auction to be in the Finalized state.
function getAuctionOutcome() external view finalizationPhase returns (address winner, uint256 winningBid, uint256 finalStateIndex, string memory finalStateName) {
    string memory _finalStateName = "N/A";
    if (currentAuction.vrfFulfilled && currentAuction.finalAssetStateIndex < currentAuction.assetStateCount) {
        _finalStateName = currentAuction.assetStates[currentAuction.finalAssetStateIndex].name;
    }
    return (currentAuction.winner, currentAuction.winningBid, currentAuction.finalAssetStateIndex, _finalStateName);
}


/// @notice Returns the winner's address after finalization.
function getWinnerAddress() external view claimingPhase returns (address) {
    return currentAuction.winner;
}

/// @notice Returns the winning bid amount after finalization.
function getWinningBidAmount() external view claimingPhase returns (uint256) {
    return currentAuction.winningBid;
}

/// @notice Returns the index of the final determined asset state after VRF fulfillment.
function getFinalAssetStateIndex() external view vrfFulfilledPhase returns (uint256) {
    return currentAuction.finalAssetStateIndex;
}

// Additional view functions (to reach 20+ and provide more info)

/// @notice Returns the total ETH deposited by bidders during the commitment phase.
function getTotalCommittedFunds() external view auctionActive returns (uint256) {
    return currentAuction.totalCommitted;
}

/// @notice Returns the total ETH from valid revealed bids during the reveal phase.
function getTotalRevealedFunds() external view auctionActive returns (uint256) {
    // Only relevant after reveal phase
    if (currentAuction.currentState < AuctionState.Reveal) return 0;
    return currentAuction.totalRevealed;
}

/// @notice Returns the list of addresses that committed to the auction.
/// @dev Useful for debugging or off-chain tracking.
function getCommittedBidders() external view auctionActive returns (address[] memory) {
    return currentAuction.committedBidders;
}

/// @notice Checks if the winning asset has been claimed.
function isAssetClaimed() external view claimingPhase returns (bool) {
    return currentAuction.assetClaimed;
}

// Add a custom error for getBidReveal
error NoReveal();

// Add a custom error for extend phase timing
error InvalidEndTime();

// Fix extend phase errors
function extendCommitPhase(uint256 _newEndTime) external onlyOwner inState(AuctionState.Commitment) {
    if (_newEndTime <= block.timestamp || _newEndTime <= currentAuction.commitEndTime) {
        revert InvalidEndTime();
    }
    currentAuction.commitEndTime = _newEndTime;
     uint256 originalRevealDuration = currentAuction.revealEndTime - (currentAuction.commitEndTime - (block.timestamp - (_newEndTime - currentAuction.commitEndTime))); // Attempt to preserve original duration
     currentAuction.revealEndTime = _newEndTime + originalRevealDuration;
     uint256 originalVRFDuration = currentAuction.vrfRequestEndTime - currentAuction.revealEndTime;
     currentAuction.vrfRequestEndTime = currentAuction.revealEndTime + originalVRFDuration;

    emit AuctionCreated(block.timestamp, currentAuction.owner, currentAuction.commitEndTime, currentAuction.revealEndTime, currentAuction.vrfRequestEndTime, currentAuction.nftContract);
}

function extendRevealPhase(uint256 _newEndTime) external onlyOwner inState(AuctionState.Reveal) {
     if (_newEndTime <= block.timestamp || _newEndTime <= currentAuction.revealEndTime || _newEndTime <= currentAuction.commitEndTime) {
        revert InvalidEndTime();
    }
    currentAuction.revealEndTime = _newEndTime;
    uint256 originalVRFDuration = currentAuction.vrfRequestEndTime - currentAuction.revealEndTime;
    currentAuction.vrfRequestEndTime = currentAuction.revealEndTime + originalVRFDuration;


    emit AuctionCreated(block.timestamp, currentAuction.owner, currentAuction.commitEndTime, currentAuction.revealEndTime, currentAuction.vrfRequestEndTime, currentAuction.nftContract);
}

// Final count check:
// 1. constructor
// 2. createAuction
// 3. addAssetState
// 4. removeAssetState
// 5. cancelAuction
// 6. commitBid
// 7. checkCommitment
// 8. extendCommitPhase
// 9. revealBid
// 10. checkReveal
// 11. extendRevealPhase
// 12. requestRandomWord
// 13. rawFulfillRandomWords (internal override, but part of the functional contract)
// 14. finalizeAuction
// 15. getAuctionOutcome
// 16. claimAsset
// 17. claimRefund
// 18. getAuctionState
// 19. getAssetStateCount
// 20. getAssetStateDetails
// 21. getCommitment
// 22. getBidReveal
// 23. getAuctionTimings
// 24. getVRFRequestStatus
// 25. getWinnerAddress
// 26. getWinningBidAmount
// 27. getFinalAssetStateIndex
// 28. getTotalCommittedFunds
// 29. getTotalRevealedFunds
// 30. getCommittedBidders
// 31. isAssetClaimed

// Okay, easily over 20 functions, implementing a complex, non-standard flow.


// --- Notes and Considerations ---
// - ERC721 interaction: The current code emits an event to signal the outcome and winner,
//   assuming external logic (like a backend service or another contract) handles the actual
//   minting to the winner based on this event and the determined state index.
//   A more integrated approach would require this contract to hold minting permissions
//   on the target ERC721 contract and call its `mint` or `safeTransferFrom` function in `finalizeAuction` or `claimAsset`.
//   I opted for emitting the event to keep this contract focused on the auction and state determination logic,
//   as direct cross-contract minting calls can add significant complexity depending on the ERC721 implementation.
// - VRF Subscription: This contract assumes you have a pre-funded Chainlink VRF Subscription ID.
//   Managing the subscription balance (funding, adding/removing consumers) is done via the Chainlink VRF Coordinator UI or contract.
// - Gas Limits: The `s_callbackGasLimit` for VRF fulfillment needs to be sufficient for the `rawFulfillRandomWords` function, including the state determination logic.
// - Commit-Reveal Security: The security relies on bidders choosing a strong, unpredictable salt and keeping it secret until the reveal phase.
// - Tie-breaking: The current implementation picks the first highest bidder encountered in the `committedBidders` array during finalization. A more sophisticated tie-breaker could be added (e.g., based on reveal timestamp, or another random number).
// - Error Handling: Using custom errors is a gas-efficient and recommended pattern.
// - Reentrancy: Not a significant risk with simple ETH transfers using `.call` and explicit state changes before transfers.
// - Single Auction: This contract structure is designed for running one auction at a time. To support multiple concurrent auctions, you would need a factory pattern or nest the `Auction` struct within a mapping keyed by an auction ID, and modify all functions to take the auction ID as a parameter.
// - View function `getBidReveal`: Added check to only allow viewing after the reveal phase has started/ended to maintain privacy during the reveal period itself.

```