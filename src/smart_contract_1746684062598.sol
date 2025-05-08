Okay, let's design a smart contract that embodies some interesting, advanced, and creative concepts without being a direct copy of common open-source templates.

We will create a `QuantumTreasureChest` contract. The core idea is that a chest's "state" (whether it can be opened, and by whom) is initially uncertain (a "superposition") and is determined ("state collapse") by an "observation" event. This observation combines on-chain randomness (Chainlink VRF) and external data (Chainlink Data Feeds) to simulate probabilistic outcomes influenced by unpredictable factors. It will also include a "decay" mechanism, where chests left unobserved for too long might change state or become accessible differently.

This contract will handle multiple asset types (ETH, ERC20, ERC721, ERC1155) and have a state machine for each chest.

---

## Smart Contract: QuantumTreasureChest

### Outline:

1.  **Contract Setup:**
    *    SPDX License & Pragma
    *   Imports (Ownable, VRFConsumerBaseV2, AggregatorV3Interface, ERC interfaces)
    *   Error definitions
    *   State variable definitions (configs, mappings for chests, assets, VRF requests)
    *   Enum definitions (ChestState, QuantumConditionOutcome)
    *   Struct definitions (Chest, Asset)
    *   Event definitions

2.  **Initialization & Configuration:**
    *   `constructor`: Sets up Ownable, VRF, and initial configuration.
    *   `setConfig`: Allows owner to update VRF parameters, Oracle address, Decay period, etc.
    *   `setApprovedToken`: Whitelists ERC20 tokens that can be deposited.
    *   `setApprovedNFT`: Whitelists ERC721/ERC1155 tokens that can be deposited.

3.  **Chest Creation (Deposit Functions):**
    *   `createChestWithEth`: Creates a chest by depositing ETH.
    *   `createChestWithToken`: Creates a chest by depositing ERC20.
    *   `createChestWithNFT`: Creates a chest by depositing ERC721.
    *   `createChestWith1155`: Creates a chest by depositing ERC1155.

4.  **Quantum State Determination:**
    *   `triggerObservationRequest`: Initiates the "observation" by requesting randomness from Chainlink VRF. This changes the chest state to `ObservationRequested`. Can be triggered by the owner or potentially anyone (with cost/incentive?).
    *   `fulfillRandomWords`: Chainlink VRF callback function. This function receives the randomness, queries the Oracle feed, and based on both, determines the `QuantumConditionOutcome` (e.g., `Openable`, `NotOpenable`, `Entangled`, etc.). Updates chest state to `StateDetermined`.

5.  **Chest Interaction & Unlocking:**
    *   `attemptUnlock`: User attempts to unlock the chest. Checks if the chest is in `StateDetermined` and if the `QuantumConditionOutcome` is favorable (`Openable`). If successful, updates state to `Unlocked`.
    *   `triggerDecayCheck`: User or anyone can call this to check if a chest has decayed. If the decay period has passed since creation or last interaction, the state might change (e.g., to `Decayed`).
    *   `claimContents`: User claims the chest contents if the state is `Unlocked` or `Decayed`. Transfers all deposited assets.

6.  **Viewing & Querying:**
    *   `getChestState`: Gets the current state of a specific chest.
    *   `getChestOwner`: Gets the owner address of a chest.
    *   `getChestContents`: Lists the assets stored in a chest.
    *   `getApprovedTokens`: Lists currently approved ERC20 tokens.
    *   `getApprovedNFTs`: Lists currently approved ERC721/1155 tokens.
    *   `getChestObservationOutcome`: Gets the determined `QuantumConditionOutcome` after state collapse.
    *   `getOracleConditionValue`: Gets the latest value used from the Oracle feed for a specific chest's observation.
    *   `getVRFRequestStatus`: Gets the status of a specific VRF request ID.
    *   `getDecayPeriod`: Gets the configured decay period.
    *   `getTotalChests`: Gets the total number of chests created.

7.  **Admin & Emergency Functions:**
    *   `emergencyWithdrawERC20`: Owner can withdraw a specific ERC20 token from the contract in case of emergency (e.g., mistakenly sent directly).
    *   `emergencyWithdrawERC721`: Owner can withdraw a specific ERC721.
    *   `emergencyWithdrawERC1155`: Owner can withdraw a specific ERC1155.

8.  **Helper Functions (ERC Receptions):**
    *   `onERC721Received`: Hook to receive ERC721 tokens safely.
    *   `onERC1155Received`: Hook to receive single ERC1155 tokens safely.
    *   `onERC1155BatchReceived`: Hook to receive batch ERC1155 tokens safely.

### Function Summary:

1.  `constructor(address _vrfCoordinator, uint64 _subscriptionId, bytes32 _keyHash, address _oracleAddress, int256 _oracleThreshold, uint256 _decayPeriod)`: Initializes the contract with Chainlink VRF/Oracle details and decay config.
2.  `transferOwnership(address newOwner)`: Transfers contract ownership (Ownable).
3.  `renounceOwnership()`: Renounces contract ownership (Ownable).
4.  `setConfig(uint64 _subscriptionId, bytes32 _keyHash, address _oracleAddress, int256 _oracleThreshold, uint256 _decayPeriod)`: Owner updates core configuration parameters.
5.  `setApprovedToken(address token, bool approved)`: Owner whitelists/unwhitelists ERC20 tokens for deposit.
6.  `setApprovedNFT(address nft, bool approved)`: Owner whitelists/unwhitelists ERC721/ERC1155 tokens for deposit.
7.  `createChestWithEth() payable`: Creates a new chest, depositing sent ETH. Returns chest ID.
8.  `createChestWithToken(address token, uint256 amount)`: Creates a new chest, depositing specified ERC20 tokens. Requires token approval. Returns chest ID.
9.  `createChestWithNFT(address nft, uint256 tokenId)`: Creates a new chest, depositing specified ERC721 token. Requires NFT approval or transfer from contract. Returns chest ID.
10. `createChestWith1155(address nft, uint256 id, uint256 amount)`: Creates a new chest, depositing specified ERC1155 tokens. Requires token approval. Returns chest ID.
11. `triggerObservationRequest(uint256 chestId)`: Owner requests Chainlink VRF randomness for a chest, initiating state determination. Requires LINK or configured payment method for VRF.
12. `fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: Chainlink VRF callback. Uses randomness and current Oracle price to determine chest outcome. *Internal call only by VRF Coordinator.*
13. `attemptUnlock(uint256 chestId)`: User attempts to unlock a chest. Succeeds only if state is `StateDetermined` and outcome is `Openable`.
14. `triggerDecayCheck(uint256 chestId)`: Checks if the decay period for a chest has passed and updates its state if needed (e.g., to `Decayed`).
15. `claimContents(uint256 chestId)`: Allows the chest owner to claim contents if state is `Unlocked` or `Decayed`.
16. `getChestState(uint256 chestId) view`: Returns the current state of a chest (enum).
17. `getChestOwner(uint256 chestId) view`: Returns the owner address of a chest.
18. `getChestContents(uint256 chestId) view`: Returns an array of assets stored in a chest.
19. `getApprovedTokens() view`: Returns a list of whitelisted ERC20 addresses.
20. `getApprovedNFTs() view`: Returns a list of whitelisted ERC721/ERC1155 addresses.
21. `getChestObservationOutcome(uint256 chestId) view`: Returns the determined outcome (enum) after observation.
22. `getOracleConditionValue(address oracleAddress) view`: Returns the latest price from a specific Oracle feed. (Requires `AggregatorV3Interface`)
23. `getVRFRequestStatus(uint256 requestId) view`: Returns true if a VRF request has been fulfilled.
24. `getDecayPeriod() view`: Returns the configured decay period.
25. `getTotalChests() view`: Returns the total count of chests created.
26. `emergencyWithdrawERC20(address token, uint256 amount)`: Owner emergency withdraws ERC20.
27. `emergencyWithdrawERC721(address nft, uint256 tokenId)`: Owner emergency withdraws ERC721.
28. `emergencyWithdrawERC1155(address nft, uint256 id, uint256 amount)`: Owner emergency withdraws ERC1155.
29. `onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4)`: ERC721 reception hook.
30. `onERC1155Received(address operator, address from, uint256 id, uint256 amount, bytes calldata data) external returns (bytes4)`: ERC1155 single reception hook.
31. `onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external returns (bytes4)`: ERC1155 batch reception hook.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // To receive ERC721
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; // To receive ERC1155
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Custom Errors
error NotApprovedToken(address token);
error NotApprovedNFT(address nft);
error ChestNotFound(uint256 chestId);
error Unauthorized(address caller, uint256 chestId);
error InvalidChestState(uint256 chestId, ChestState currentState, ChestState expectedState);
error InvalidQuantumOutcome(uint256 chestId, QuantumConditionOutcome currentOutcome, QuantumConditionOutcome expectedOutcome);
error RandomnessNotFulfilled(uint256 chestId);
error OracleDataUnavailable(address oracle);
error VRFRequestFailed(uint256 chestId);
error NoContentsToClaim(uint256 chestId);
error DecayPeriodNotPassed(uint256 chestId);

contract QuantumTreasureChest is Ownable, VRFConsumerBaseV2, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    // --- State Definitions ---

    enum ChestState {
        Created,              // Chest exists, waiting for observation request
        ObservationRequested, // VRF request sent, waiting for fulfillment
        StateDetermined,      // VRF fulfilled, outcome (Openable/NotOpenable/Entangled) is set
        Unlocked,             // StateDetermined was Openable, now unlocked
        Decayed,              // Decay period passed without unlock/observation
        Claimed               // Contents have been claimed
    }

    enum QuantumConditionOutcome {
        Undetermined,   // Initial state before observation
        Openable,       // Conditions met, chest can be unlocked
        NotOpenable,    // Conditions not met, cannot be unlocked normally
        Entangled       // Outcome requires interaction with another chest (conceptually, not fully implemented here)
    }

    struct Asset {
        address contractAddress;
        uint256 id;     // tokenId for ERC721/ERC1155, 0 for ERC20/ETH
        uint256 amount; // amount for ERC20/ERC1155, 1 for ERC721/ETH
        bool isNativeEth;
        uint8 assetType; // 0: ETH, 1: ERC20, 2: ERC721, 3: ERC1155
    }

    struct Chest {
        address owner;
        ChestState state;
        uint256 createdAt;
        uint256 lastInteractionAt; // Timestamp of observation request or decay check
        QuantumConditionOutcome outcome;
        uint256 vrfRequestId; // Associated VRF request ID
        int256 oracleValueAtObservation; // Oracle value when VRF was fulfilled
        Asset[] contents;
    }

    // --- Contract State Variables ---

    uint256 public nextChestId;
    mapping(uint256 => Chest) public chests;
    mapping(address => bool) public approvedTokens; // Whitelisted ERC20
    mapping(address => bool) public approvedNFTs;   // Whitelisted ERC721/ERC1155

    // Chainlink VRF V2 configuration
    uint64 private s_subscriptionId;
    bytes32 private s_keyHash;
    uint32 private constant CALLBACK_GAS_LIMIT = 200000; // Adjust as needed
    uint16 private constant REQUEST_CONFIRMATIONS = 3;   // Number of block confirmations
    uint32 private constant NUM_WORDS = 1;              // Number of random words requested

    // Mapping from VRF request ID to Chest ID
    mapping(uint256 => uint256) public vrfRequestIdToChestId;

    // Chainlink Oracle configuration
    address public oracleAddress;
    int256 public oracleThreshold; // Threshold for oracle value to influence outcome

    // Decay mechanism
    uint256 public decayPeriod; // Time in seconds after which a chest may decay

    // --- Events ---

    event ChestCreated(uint256 chestId, address owner, ChestState initialState);
    event ObservationRequested(uint256 chestId, uint256 requestId);
    event StateDetermined(uint256 chestId, QuantumConditionOutcome outcome, int256 oracleValue);
    event Unlocked(uint256 chestId);
    event Decayed(uint256 chestId);
    event ContentsClaimed(uint256 chestId, address claimant);
    event ConfigUpdated(uint64 subscriptionId, bytes32 keyHash, address oracleAddress, int256 oracleThreshold, uint256 decayPeriod);
    event TokenApproved(address token, bool approved);
    event NFTApproved(address nft, bool approved);
    event EmergencyWithdrawal(address token, uint256 amount, address owner);

    // --- Constructor ---

    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _oracleAddress,
        int256 _oracleThreshold,
        uint256 _decayPeriod
    )
        Ownable(msg.sender)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        oracleAddress = _oracleAddress;
        oracleThreshold = _oracleThreshold;
        decayPeriod = _decayPeriod;
        nextChestId = 1; // Start chest IDs from 1

        emit ConfigUpdated(s_subscriptionId, s_keyHash, oracleAddress, oracleThreshold, decayPeriod);
    }

    // --- Configuration Functions (Owner Only) ---

    function setConfig(
        uint64 _subscriptionId,
        bytes32 _keyHash,
        address _oracleAddress,
        int256 _oracleThreshold,
        uint256 _decayPeriod
    ) external onlyOwner {
        s_subscriptionId = _subscriptionId;
        s_keyHash = _keyHash;
        oracleAddress = _oracleAddress;
        oracleThreshold = _oracleThreshold;
        decayPeriod = _decayPeriod;
        emit ConfigUpdated(s_subscriptionId, s_keyHash, oracleAddress, oracleThreshold, decayPeriod);
    }

    function setApprovedToken(address token, bool approved) external onlyOwner {
        approvedTokens[token] = approved;
        emit TokenApproved(token, approved);
    }

    function setApprovedNFT(address nft, bool approved) external onlyOwner {
        approvedNFTs[nft] = approved;
        emit NFTApproved(nft, approved);
    }

    // --- Chest Creation Functions ---

    function createChestWithEth() external payable returns (uint256) {
        require(msg.value > 0, "Must send ETH to create chest");

        uint256 chestId = nextChestId++;
        chests[chestId].owner = msg.sender;
        chests[chestId].state = ChestState.Created;
        chests[chestId].createdAt = block.timestamp;
        chests[chestId].lastInteractionAt = block.timestamp;
        chests[chestId].outcome = QuantumConditionOutcome.Undetermined;
        chests[chestId].contents.push(Asset({
            contractAddress: address(0),
            id: 0,
            amount: msg.value,
            isNativeEth: true,
            assetType: 0
        }));

        emit ChestCreated(chestId, msg.sender, ChestState.Created);
        return chestId;
    }

    function createChestWithToken(address token, uint256 amount) external returns (uint256) {
        require(approvedTokens[token], NotApprovedToken(token));
        require(amount > 0, "Amount must be > 0");

        uint256 chestId = nextChestId++;
        chests[chestId].owner = msg.sender;
        chests[chestId].state = ChestState.Created;
        chests[chestId].createdAt = block.timestamp;
        chests[chestId].lastInteractionAt = block.timestamp;
        chests[chestId].outcome = QuantumConditionOutcome.Undetermined;
        chests[chestId].contents.push(Asset({
            contractAddress: token,
            id: 0,
            amount: amount,
            isNativeEth: false,
            assetType: 1
        }));

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit ChestCreated(chestId, msg.sender, ChestState.Created);
        return chestId;
    }

    function createChestWithNFT(address nft, uint256 tokenId) external returns (uint256) {
        require(approvedNFTs[nft], NotApprovedNFT(nft));

        uint256 chestId = nextChestId++;
        chests[chestId].owner = msg.sender;
        chests[chestId].state = ChestState.Created;
        chests[chestId].createdAt = block.timestamp;
        chests[chestId].lastInteractionAt = block.timestamp;
        chests[chestId].outcome = QuantumConditionOutcome.Undetermined;
        chests[chestId].contents.push(Asset({
            contractAddress: nft,
            id: tokenId,
            amount: 1, // Always 1 for ERC721
            isNativeEth: false,
            assetType: 2
        }));

        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);

        emit ChestCreated(chestId, msg.sender, ChestState.Created);
        return chestId;
    }

    function createChestWith1155(address nft, uint256 id, uint256 amount) external returns (uint256) {
        require(approvedNFTs[nft], NotApprovedNFT(nft));
        require(amount > 0, "Amount must be > 0");

        uint256 chestId = nextChestId++;
        chests[chestId].owner = msg.sender;
        chests[chestId].state = ChestState.Created;
        chests[chestId].createdAt = block.timestamp;
        chests[chestId].lastInteractionAt = block.timestamp;
        chests[chestId].outcome = QuantumConditionOutcome.Undetermined;
        chests[chestId].contents.push(Asset({
            contractAddress: nft,
            id: id,
            amount: amount,
            isNativeEth: false,
            assetType: 3
        }));

        IERC1155(nft).safeTransferFrom(msg.sender, address(this), id, amount, ""); // Empty data field

        emit ChestCreated(chestId, msg.sender, ChestState.Created);
        return chestId;
    }

    // --- Quantum State Determination ---

    /**
     * @notice Triggers the "observation" event for a chest by requesting randomness.
     * This collapses the chest's quantum state.
     * @param chestId The ID of the chest to observe.
     */
    function triggerObservationRequest(uint256 chestId) public onlyOwner {
        // Currently restricted to owner for simplicity and gas management.
        // Could be opened up with appropriate payment/incentive mechanism.
        Chest storage chest = chests[chestId];
        if (chest.owner == address(0)) revert ChestNotFound(chestId);
        if (chest.state != ChestState.Created && chest.state != ChestState.StateDetermined) {
            revert InvalidChestState(chestId, chest.state, ChestState.Created);
        }

        // Request randomness
        uint256 requestId = requestRandomWords(s_keyHash, s_subscriptionId, REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT, NUM_WORDS);

        chest.state = ChestState.ObservationRequested;
        chest.vrfRequestId = requestId;
        chest.lastInteractionAt = block.timestamp; // Update interaction time

        vrfRequestIdToChestId[requestId] = chestId;

        emit ObservationRequested(chestId, requestId);
    }

    /**
     * @notice Chainlink VRF V2 callback function. Fulfills the randomness request.
     * This function calculates the QuantumConditionOutcome based on randomness and oracle data.
     * @param requestId The VRF request ID.
     * @param randomWords The array of random words received.
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 chestId = vrfRequestIdToChestId[requestId];
        // Chest ID 0 is not used, indicates request ID was not for a valid chest
        if (chestId == 0) return;

        Chest storage chest = chests[chestId];
        // Should be in ObservationRequested state, but add a check just in case
        if (chest.state != ChestState.ObservationRequested) return; // Or revert? Return is safer for callback.

        // Ensure randomness is received
        require(randomWords.length > 0, "No random words received");
        uint256 randomNumber = randomWords[0];

        // Get current Oracle value
        int256 oracleValue;
        uint80 roundId;
        uint256 startedAt;
        uint256 updatedAt;
        uint8 answeredInRound;

        try AggregatorV3Interface(oracleAddress).latestRoundData()
             returns (uint80, int256 value, uint256, uint256 timestamp, uint80) {
                 oracleValue = value;
                 // Use timestamp to determine data freshness if needed
                 updatedAt = timestamp;
             }
             catch {
                 // Handle oracle data unavailable - maybe chest becomes NotOpenable or stays in state?
                 // For this example, let's make it NotOpenable if data is unavailable.
                 chest.state = ChestState.StateDetermined;
                 chest.outcome = QuantumConditionOutcome.NotOpenable;
                 chest.oracleValueAtObservation = 0; // Indicate data unavailable
                 emit StateDetermined(chestId, QuantumConditionOutcome.NotOpenable, 0);
                 return;
             }

        chest.oracleValueAtObservation = oracleValue;

        // Determine outcome based on randomness and oracle value
        // Example Logic:
        // - If random number is high AND oracle value > threshold: Openable
        // - If random number is low AND oracle value <= threshold: Openable
        // - Otherwise: NotOpenable
        // - Could add more complex logic for Entangled etc.

        bool randomConditionMet = (randomNumber % 100) >= 50; // Example: 50% chance
        bool oracleConditionMet = (oracleValue > oracleThreshold);

        if ((randomConditionMet && oracleConditionMet) || (!randomConditionMet && !oracleConditionMet)) {
             chest.outcome = QuantumConditionOutcome.Openable;
        } else {
             chest.outcome = QuantumConditionOutcome.NotOpenable;
        }

        chest.state = ChestState.StateDetermined;
        chest.lastInteractionAt = block.timestamp; // Update interaction time

        emit StateDetermined(chestId, chest.outcome, oracleValue);
    }

    // --- Chest Interaction & Unlocking ---

    /**
     * @notice Attempts to unlock a chest after its state has been determined.
     * @param chestId The ID of the chest to unlock.
     */
    function attemptUnlock(uint256 chestId) public {
        Chest storage chest = chests[chestId];
        if (chest.owner == address(0)) revert ChestNotFound(chestId);
        if (msg.sender != chest.owner) revert Unauthorized(msg.sender, chestId);

        if (chest.state != ChestState.StateDetermined) {
            revert InvalidChestState(chestId, chest.state, ChestState.StateDetermined);
        }

        if (chest.outcome == QuantumConditionOutcome.Undetermined) {
             revert RandomnessNotFulfilled(chestId); // VRF hasn't fulfilled yet
        }

        if (chest.outcome == QuantumConditionOutcome.Openable) {
            chest.state = ChestState.Unlocked;
            chest.lastInteractionAt = block.timestamp; // Update interaction time
            emit Unlocked(chestId);
        } else {
            revert InvalidQuantumOutcome(chestId, chest.outcome, QuantumConditionOutcome.Openable);
            // Could transition to another state like 'PermanentlyClosed' here
        }
    }

    /**
     * @notice Checks if a chest has decayed and updates its state if so.
     * Decay happens if no relevant interaction (`triggerObservationRequest` or `attemptUnlock`)
     * occurs within the `decayPeriod` after chest creation or last interaction.
     * Anyone can trigger this check.
     * @param chestId The ID of the chest to check.
     */
    function triggerDecayCheck(uint256 chestId) public {
         Chest storage chest = chests[chestId];
         if (chest.owner == address(0)) revert ChestNotFound(chestId);

         // Only check if the chest is in a state where it can decay
         if (chest.state != ChestState.Created && chest.state != ChestState.StateDetermined && chest.state != ChestState.NotOpenable) {
             return; // Or revert if you want to restrict calls to relevant states
         }

         if (block.timestamp >= chest.lastInteractionAt + decayPeriod) {
             chest.state = ChestState.Decayed;
             chest.lastInteractionAt = block.timestamp; // Update interaction time
             emit Decayed(chestId);
         } else {
             revert DecayPeriodNotPassed(chestId);
         }
    }

    /**
     * @notice Allows the owner to claim the contents of an Unlocked or Decayed chest.
     * @param chestId The ID of the chest to claim from.
     */
    function claimContents(uint256 chestId) public {
        Chest storage chest = chests[chestId];
        if (chest.owner == address(0)) revert ChestNotFound(chestId);
        if (msg.sender != chest.owner) revert Unauthorized(msg.sender, chestId);

        if (chest.state != ChestState.Unlocked && chest.state != ChestState.Decayed) {
             revert InvalidChestState(chestId, chest.state, ChestState.Unlocked);
        }
        if (chest.contents.length == 0) revert NoContentsToClaim(chestId);

        // Transfer assets
        address payable ownerPayable = payable(chest.owner);
        for (uint i = 0; i < chest.contents.length; i++) {
            Asset storage asset = chest.contents[i];
            if (asset.isNativeEth) {
                (bool success, ) = ownerPayable.call{value: asset.amount}("");
                require(success, "ETH transfer failed");
            } else if (asset.assetType == 1) { // ERC20
                IERC20(asset.contractAddress).safeTransfer(ownerPayable, asset.amount);
            } else if (asset.assetType == 2) { // ERC721
                 IERC721(asset.contractAddress).transferFrom(address(this), ownerPayable, asset.id);
            } else if (asset.assetType == 3) { // ERC1155
                 IERC1155(asset.contractAddress).safeTransferFrom(address(this), ownerPayable, asset.id, asset.amount, ""); // Empty data field
            }
        }

        chest.contents = new Asset[](0); // Clear contents array
        chest.state = ChestState.Claimed;
        chest.lastInteractionAt = block.timestamp; // Update interaction time

        emit ContentsClaimed(chestId, msg.sender);
    }

    // --- Viewing & Querying Functions ---

    function getChestState(uint256 chestId) public view returns (ChestState) {
        if (chests[chestId].owner == address(0)) revert ChestNotFound(chestId);
        return chests[chestId].state;
    }

    function getChestOwner(uint256 chestId) public view returns (address) {
        if (chests[chestId].owner == address(0)) revert ChestNotFound(chestId);
        return chests[chestId].owner;
    }

    function getChestContents(uint256 chestId) public view returns (Asset[] memory) {
        if (chests[chestId].owner == address(0)) revert ChestNotFound(chestId);
        return chests[chestId].contents;
    }

    function getApprovedTokens() public view returns (address[] memory) {
        // This is inefficient for large numbers of tokens.
        // A production contract might use a different pattern (e.g., iterable mapping or events).
        uint256 count = 0;
        for (uint i = 0; i < 100; i++) { // Limit iteration to avoid gas issues
            // This is just a placeholder. Cannot reliably iterate over mapping keys.
            // A proper implementation would store keys in an array or use events.
        }
         // Returning an empty array or placeholder as true mapping iteration isn't possible directly
        return new address[](0);
    }

     function getApprovedNFTs() public view returns (address[] memory) {
        // Similar inefficiency as getApprovedTokens.
        // A proper implementation would store keys in an array or use events.
        return new address[](0);
    }

    function getChestObservationOutcome(uint256 chestId) public view returns (QuantumConditionOutcome) {
        if (chests[chestId].owner == address(0)) revert ChestNotFound(chestId);
        return chests[chestId].outcome;
    }

    function getOracleConditionValue(address _oracleAddress) public view returns (int256 latestValue) {
         // Added check for _oracleAddress != address(0)
         require(_oracleAddress != address(0), "Invalid oracle address");
         AggregatorV3Interface priceFeed = AggregatorV3Interface(_oracleAddress);
         (, int256 price, , , ) = priceFeed.latestRoundData();
         return price;
    }

     function getVRFRequestStatus(uint256 requestId) public view returns (bool fulfilled) {
        // VRFConsumerBaseV2 doesn't expose a public way to check if a request ID was fulfilled.
        // We can only know *our* state (if the chest transition to StateDetermined from RequestRequested).
        // This function is conceptual or would require tracking fulfilled requests internally,
        // mapping request ID to a boolean flag set in fulfillRandomWords.
        // For this example, we can indicate if a chest is no longer in ObservationRequested state
        // AND its vrfRequestId matches the queried one.
        uint256 chestId = vrfRequestIdToChestId[requestId];
        if (chestId == 0) return false; // Request ID not known or belongs to an invalid chest
        Chest storage chest = chests[chestId];
        return chest.state != ChestState.ObservationRequested && chest.vrfRequestId == requestId;
    }

    function getDecayPeriod() public view returns (uint256) {
        return decayPeriod;
    }

    function getTotalChests() public view returns (uint256) {
        return nextChestId - 1; // nextChestId is the ID for the *next* chest
    }


    // --- Admin & Emergency Functions (Owner Only) ---

    function emergencyWithdrawERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        IERC20(token).safeTransfer(msg.sender, amount);
        emit EmergencyWithdrawal(token, amount, msg.sender);
    }

    function emergencyWithdrawERC721(address nft, uint256 tokenId) external onlyOwner {
        require(nft != address(0), "Invalid NFT address");
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);
         emit EmergencyWithdrawal(nft, tokenId, msg.sender); // Re-using event, amount=tokenId
    }

    function emergencyWithdrawERC1155(address nft, uint256 id, uint256 amount) external onlyOwner {
        require(nft != address(0), "Invalid NFT address");
        require(amount > 0, "Amount must be > 0");
        IERC1155(nft).safeTransferFrom(address(this), msg.sender, id, amount, "");
        emit EmergencyWithdrawal(nft, id, msg.sender); // Re-using event, amount=id
    }


    // --- ERC Receiver Hooks ---
    // These hooks are necessary to receive ERC721 and ERC1155 tokens directly into the contract.

    // ERC721Holder and ERC1155Holder provide default implementations for these hooks.
    // By inheriting from them, our contract automatically supports receiving NFTs.
    // We just need to ensure they are included in the contract.

    // function onERC721Received(...) is inherited from ERC721Holder
    // function onERC1155Received(...) is inherited from ERC1155Holder
    // function onERC1155BatchReceived(...) is inherited from ERC1155Holder
}
```