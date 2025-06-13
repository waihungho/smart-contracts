Okay, let's design a smart contract that represents dynamic, interactive NFTs called "Quantum Tunnels". These tunnels can be used to send crypto assets (ETH, ERC20, or even other ERC721s) on a "quantum journey" through virtual spacetime. The journey takes time, is influenced by the tunnel's unique parameters (which can be upgraded), uses verifiable randomness for its outcome, and can result in transformation, loss, or unexpected results.

This concept combines:
1.  **Dynamic NFTs:** NFT properties (parameters) can change over time or via interaction.
2.  **Asset Transformation/Consumption:** The core utility is taking one asset and potentially getting something else back, or losing it.
3.  **Time-Based Mechanics:** Actions have duration.
4.  **Verifiable Randomness:** Outcomes are unpredictable but provably fair using Chainlink VRF.
5.  **NFT Utility:** The NFT isn't just a static image; it has a core, active function within the contract's ecosystem.
6.  **Inter-token Interaction:** It can interact with and consume/transform other ERC20/ERC721 tokens.

We will define distinct states for the tunnel NFTs (Idle, Tunneling, ReadyToFinalize, Damaged). The process involves initiating with an input asset, waiting for a time duration, requesting randomness, and then finalizing based on randomness and tunnel stats.

Here's the outline and the Solidity code:

---

**QuantumTunnelNFT Smart Contract**

**Outline:**

1.  **License & Pragma**
2.  **Imports:** ERC721, Ownable, Pausable, ERC20 interfaces, ERC721 interfaces, Chainlink VRF interfaces.
3.  **Error Handling:** Custom errors for clarity.
4.  **Interfaces:** Define interfaces for interacting with ERC20, ERC721, and Chainlink VRF.
5.  **Libraries:** SafeTransferLib (for ERC20/ERC721 transfers).
6.  **State Variables:**
    *   Contract metadata (name, symbol).
    *   Token counter (`_tokenIdCounter`).
    *   Mapping for tunnel parameters (`_tunnelParameters`).
    *   Mapping for active tunneling processes (`_tunnelProcesses`).
    *   Mapping from VRF request ID to token ID (`_vrfRequests`).
    *   Allowed input token/NFT addresses.
    *   VRF Configuration (coordinator, keyhash, subscription ID, gas limit).
    *   Admin configurable parameters (min/max duration, costs, success chance modifiers).
    *   Pause state.
7.  **Structs:**
    *   `TunnelParameters`: `stability`, `capacity`, `speed`, `purity`, `lastUsedTimestamp`, `cooldownEndTimestamp`, `successChanceModifier`.
    *   `TunnelProcess`: `initiator`, `inputAssetType`, `inputTokenAddress`, `inputNFTAddress`, `inputNFTId`, `inputAmount`, `startTimestamp`, `expectedEndTime`, `vrfRequestId`, `randomnessFulfilled`, `randomnessResult`.
8.  **Enums:**
    *   `AssetType`: `ETH`, `ERC20`, `ERC721`.
    *   `TunnelStatus`: `Idle`, `Tunneling`, `ReadyToFinalize`, `Damaged`.
    *   `TunnelOutcome`: `Success`, `PartialLoss`, `CompleteLoss`, `TransformationERC20`, `TransformationERC721`, `TunnelCollapse`.
9.  **Events:**
    *   `TunnelMinted`
    *   `TunnelingInitiated`
    *   `TunnelingFinalized`
    *   `TunnelUpgraded`
    *   `AssetClaimed`
    *   `FieldStabilized`
    *   `RepairExecuted`
    *   `InputAssetConfigured`
    *   `ParametersUpdated`
    *   `TunnelDamaged`
    *   `TunnelRepaired`
    *   `TunnelCollapsed`
    *   `VRFRandomnessReceived`
10. **Modifiers:**
    *   `onlyTunnelOwnerOrApproved`
    *   `onlyTunnelInStatus`
11. **Constructor:** Initializes ERC721, Ownable, Pausable, and VRF coordinator/keyhash/subId.
12. **Core Tunneling Logic:**
    *   `mintInitialTunnel`: Mints founder tunnels (Owner only).
    *   `initiateTunneling`: Starts a new tunneling process for a token ID. Takes input asset, calculates duration, requests VRF randomness.
    *   `rawFulfillRandomWords`: VRF callback to receive randomness. Stores the result.
    *   `finalizeTunneling`: Processes the tunnel after time is up and randomness is available. Determines outcome based on tunnel parameters and randomness. Executes outcome logic (transfers, burns, etc.).
    *   `cancelTunneling`: Allows the initiator to cancel a tunneling process before finalization (with potential loss).
    *   `claimTunnelOutput`: Allows the initiator to claim assets resulting from a successful or transformed journey.
13. **Tunnel Management & Upgrades:**
    *   `upgradeTunnelStability`: Improves stability parameter.
    *   `upgradeTunnelCapacity`: Improves capacity parameter.
    *   `upgradeTunnelSpeed`: Improves speed parameter.
    *   `stabilizeQuantumField`: Applies a temporary success chance boost for the *next* journey (consumes resources).
    *   `repairTunnelStructure`: Fixes a damaged tunnel (consumes resources).
14. **Information & Getters:**
    *   `getTunnelParameters`: Get the parameters of a specific tunnel.
    *   `getTunnelStatus`: Get the current status of a specific tunnel.
    *   `getProcessDetails`: Get details of an ongoing or finished process.
    *   `getAllowedTokenInput`: Check if an ERC20 address is allowed input.
    *   `getAllowedNFTInput`: Check if an ERC721 address is allowed input.
    *   `getTunnelCooldown`: Get the timestamp when a tunnel is out of cooldown.
    *   Standard ERC721 getters (`balanceOf`, `ownerOf`, `getApproved`, `isApprovedForAll`).
15. **Admin Functions (Owner Only):**
    *   `pauseContract`: Pauses most functions.
    *   `unpauseContract`: Unpauses contract.
    *   `setAllowedTokenInput`: Configure allowed ERC20 inputs.
    *   `setAllowedNFTInput`: Configure allowed ERC721 inputs.
    *   `setMinTunnelDuration`: Set minimum journey time.
    *   `setMaxTunnelDuration`: Set maximum journey time.
    *   `setBaseUpgradeCost`: Set base cost for upgrades.
    *   `setRepairCost`: Set cost to repair.
    *   `setStabilizeCost`: Set cost to stabilize.
    *   `setCollateralRecoveryAddress`: Address for recovering stuck assets.
    *   `withdrawStuckETH`: Recover ETH sent accidentally.
    *   `withdrawStuckTokens`: Recover ERC20 tokens sent accidentally.
    *   `withdrawStuckNFT`: Recover ERC721 tokens stuck.
    *   `setTunnelMetadataURI`: Set base URI for metadata.
    *   `requestRandomnessManual`: (Emergency/Testing) Request randomness without initiating a process. *Self-correction:* This isn't strictly necessary for the core concept and could be complex to manage the callback context. Let's skip for simplicity and focus on VRF tied to `initiateTunneling`.
    *   `recoverFundsFromProcess`: Owner can recover inputs from a stuck process (e.g., if VRF fails permanently).
16. **Standard ERC721 Implementations:** Override `_beforeTokenTransfer` potentially for state checks (though might not be needed if transfers are blocked during tunneling).
17. **Receive and Fallback:** To accept ETH for payments/input.

**Function Summary (Minimum 20):**

1.  `constructor()`: Initializes contract state, VRF config.
2.  `mintInitialTunnel(address to)`: Mints a new Quantum Tunnel NFT to an address (Owner only).
3.  `initiateTunneling(uint256 tokenId, AssetType inputAssetType, address inputTokenAddress, uint256 inputNFTId, uint256 inputAmount)`: Starts a tunneling process for `tokenId` with specified asset. Handles asset transfer/lock. Requests VRF randomness.
4.  `rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords)`: VRF callback. Stores the random number.
5.  `finalizeTunneling(uint256 tokenId)`: Completes the tunneling process. Determines outcome based on time, randomness, and tunnel stats. Executes outcome logic.
6.  `cancelTunneling(uint256 tokenId)`: Allows the initiator to cancel a pending process.
7.  `claimTunnelOutput(uint256 tokenId)`: Allows initiator to claim resulting assets.
8.  `upgradeTunnelStability(uint256 tokenId)`: Improves stability parameter (consumes resources).
9.  `upgradeTunnelCapacity(uint256 tokenId)`: Improves capacity parameter (consumes resources).
10. `upgradeTunnelSpeed(uint256 tokenId)`: Improves speed parameter (consumes resources).
11. `stabilizeQuantumField(uint256 tokenId)`: Applies a temporary success chance boost (consumes resources).
12. `repairTunnelStructure(uint256 tokenId)`: Fixes a damaged tunnel (consumes resources).
13. `getTunnelParameters(uint256 tokenId)`: Returns parameters of a tunnel.
14. `getTunnelStatus(uint256 tokenId)`: Returns the current operational status of a tunnel.
15. `getProcessDetails(uint256 tokenId)`: Returns details about the current/last process.
16. `getAllowedTokenInput(address tokenAddress)`: Checks if an ERC20 is allowed input.
17. `getAllowedNFTInput(address nftAddress)`: Checks if an ERC721 is allowed input.
18. `setAllowedTokenInput(address tokenAddress, bool allowed)`: Owner configures allowed ERC20 inputs.
19. `setAllowedNFTInput(address nftAddress, bool allowed)`: Owner configures allowed ERC721 inputs.
20. `pauseContract()`: Owner pauses contract.
21. `unpauseContract()`: Owner unpauses contract.
22. `withdrawStuckETH()`: Owner recovers stuck ETH.
23. `withdrawStuckTokens(address tokenAddress)`: Owner recovers stuck ERC20.
24. `withdrawStuckNFT(address nftAddress, uint256 nftId)`: Owner recovers stuck ERC721.
25. `transferOwnership(address newOwner)`: Transfers contract ownership.
    *(Plus standard ERC721 functions like balanceOf, ownerOf, approve, setApprovalForAll, getApproved, isApprovedForAll, transferFrom, safeTransferFrom, supportsInterface, total supply if using counters)*.
    This easily exceeds 20 functions.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Chainlink VRF Imports
import "@chainlink/contracts/src/v0.8/vrf/V2/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/V2/VRFConsumerBaseV2.sol";

// Custom Libraries (minimal example, SafeTransferLib could be implemented or imported)
library SafeTransferLib {
    function safeTransferETH(address payable to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "ETH transfer failed");
    }
}

/**
 * @title QuantumTunnelNFT
 * @dev An advanced, dynamic NFT contract representing 'Quantum Tunnels' used for asset transformation.
 * Users can initiate time-based journeys for ETH, ERC20s, or ERC721s through their tunnels.
 * The outcome is determined by tunnel parameters (upgradable) and verifiable randomness via Chainlink VRF.
 * Tunnels can be damaged or enhanced. Features pausing, ownership, and asset recovery.
 */
contract QuantumTunnelNFT is ERC721, Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;

    // --- Errors ---
    error NotOwnerOrApproved();
    error TunnelNotFound();
    error InvalidTunnelStatus(TunnelStatus currentStatus, TunnelStatus requiredStatus);
    error TunnelOnCooldown();
    error InvalidInputAsset();
    error InputAssetNotAllowed(address assetAddress);
    error InputAssetMismatch(AssetType expectedType);
    error InsufficientFunds(uint256 required, uint256 sent);
    error TransferFailed();
    error VRFRequestFailed();
    error RandomnessNotFulfilled();
    error ProcessAlreadyFinalized();
    error ProcessNotFound();
    error NotTunnelInitiator();
    error CannotFinalizeYet(uint256 finalizationTime);
    error TunnelNotDamaged();
    error TunnelAlreadyDamaged();
    error InvalidUpgradeCost();
    error MetadataURINotSet();
    error NoInputAssetToClaim();
    error NotOwnerOrCollateralRecoveryAddress();
    error RecoveryFailed();

    // --- State Variables ---
    Counters.Counter private _tokenIdCounter;

    // Tunnel Data
    struct TunnelParameters {
        uint16 stability; // Affects success chance (0-1000)
        uint16 capacity; // Affects max input amount/size (0-1000)
        uint16 speed; // Affects journey duration (0-1000)
        uint16 purity; // Affects transformation outcome quality (0-1000)
        uint64 lastUsedTimestamp;
        uint64 cooldownEndTimestamp;
        uint16 successChanceModifier; // Temporary boost (0-100)
        TunnelStatus currentStatus;
    }
    mapping(uint256 => TunnelParameters) private _tunnelParameters;

    // Tunneling Process Data
    struct TunnelProcess {
        address initiator; // Address that initiated the process
        AssetType inputAssetType;
        address inputTokenAddress; // For ERC20 or ERC721 contract address
        uint256 inputNFTId;      // For ERC721 token ID
        uint256 inputAmount;     // For ETH or ERC20 amount
        uint64 startTimestamp;
        uint64 expectedEndTime;
        uint256 vrfRequestId;
        bool randomnessFulfilled;
        uint256 randomnessResult; // The raw randomness received
        bool finalized; // To prevent double finalization
    }
    mapping(uint256 => TunnelProcess) private _tunnelProcesses; // Keyed by tokenId

    // VRF data mapping
    mapping(uint256 => uint256) private _vrfRequests; // Chainlink VRF Request ID => Token ID

    // Allowed Input Assets (Owner Configurable)
    mapping(address => bool) private _allowedERC20Input;
    mapping(address => bool) private _allowedERC721Input;

    // Admin Configurable Parameters
    uint64 private _minTunnelDuration = 1 hours; // Base minimum duration
    uint64 private _maxTunnelDuration = 24 hours; // Base maximum duration
    uint256 private _baseUpgradeCost = 0.01 ether; // Cost to upgrade a parameter
    uint256 private _repairCost = 0.005 ether;    // Cost to repair a damaged tunnel
    uint256 private _stabilizeCost = 0.002 ether; // Cost to stabilize the field
    address payable private _collateralRecoveryAddress; // Address for recovering stuck assets

    // Chainlink VRF Configuration
    VRFCoordinatorV2Interface immutable i_vrfCoordinator;
    uint64 immutable i_subscriptionId;
    bytes32 immutable i_keyHash;
    uint32 constant private CALLBACK_GAS_LIMIT = 1_000_000; // Gas limit for VRF callback

    string private _baseTokenURI;

    // --- Enums ---
    enum AssetType {
        ETH,
        ERC20,
        ERC721
    }

    enum TunnelStatus {
        Idle,
        Tunneling,
        ReadyToFinalize,
        Damaged
    }

    enum TunnelOutcome {
        Success,            // Input returned (potentially transformed)
        PartialLoss,        // Part of input lost
        CompleteLoss,       // All input lost
        TransformationERC20, // Input lost, new ERC20 minted/transferred
        TransformationERC721, // Input lost, new ERC721 minted/transferred
        TunnelCollapse      // Input lost, tunnel becomes Damaged or burned
    }

    // --- Events ---
    event TunnelMinted(address indexed owner, uint256 indexed tokenId);
    event TunnelingInitiated(
        uint256 indexed tokenId,
        address indexed initiator,
        AssetType inputAssetType,
        address inputTokenAddress,
        uint256 inputNFTId,
        uint256 inputAmount,
        uint64 expectedEndTime,
        uint256 vrfRequestId
    );
    event TunnelingFinalized(
        uint256 indexed tokenId,
        TunnelOutcome indexed outcome,
        uint256 randomnessResult
    );
    event TunnelUpgraded(
        uint256 indexed tokenId,
        string indexed parameter,
        uint16 newValue,
        uint256 cost
    );
    event AssetClaimed(
        uint256 indexed tokenId,
        address indexed claimant,
        AssetType assetType,
        address tokenAddress,
        uint256 nftId,
        uint256 amount
    );
    event FieldStabilized(uint256 indexed tokenId, address indexed user, uint256 cost);
    event RepairExecuted(uint256 indexed tokenId, address indexed user, uint256 cost);
    event InputAssetConfigured(address indexed assetAddress, AssetType assetType, bool allowed);
    event ParametersUpdated(string parameterName, uint256 newValue);
    event TunnelDamaged(uint256 indexed tokenId);
    event TunnelRepaired(uint256 indexed tokenId);
    event TunnelCollapsed(uint256 indexed tokenId, address indexed owner);
    event VRFRandomnessReceived(uint256 indexed requestId, uint256 indexed tokenId, uint256 randomness);

    // --- Modifiers ---
    modifier onlyTunnelOwnerOrApproved(uint256 tokenId) {
        if (ownerOf(tokenId) != _msgSender() && getApproved(tokenId) != _msgSender() && !isApprovedForAll(ownerOf(tokenId), _msgSender())) {
            revert NotOwnerOrApproved();
        }
        _;
    }

    modifier onlyTunnelInStatus(uint256 tokenId, TunnelStatus requiredStatus) {
        if (_tunnelParameters[tokenId].currentStatus != requiredStatus) {
             revert InvalidTunnelStatus(_tunnelParameters[tokenId].currentStatus, requiredStatus);
        }
        _;
    }

    modifier onlyCollateralRecoveryAddress() {
        if (_msgSender() != owner() && _msgSender() != _collateralRecoveryAddress) {
            revert NotOwnerOrCollateralRecoveryAddress();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        address vrfCoordinator,
        uint64 subscriptionId,
        bytes32 keyHash
    )
        ERC721("Quantum Tunnel", "QTT")
        Ownable(msg.sender)
        Pausable()
        VRFConsumerBaseV2(vrfCoordinator)
    {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_subscriptionId = subscriptionId;
        i_keyHash = keyHash;

        _collateralRecoveryAddress = payable(msg.sender); // Default to owner, can be changed
    }

    // --- ERC721 Overrides ---
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721) returns (address) {
        // Optional: Add checks here to prevent transfer if tunnel is not Idle
        // require(_tunnelParameters[tokenId].currentStatus == TunnelStatus.Idle, "Tunnel not idle");
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721NonexistentToken(tokenId);
        }
        if (bytes(_baseTokenURI).length == 0) {
            revert MetadataURINotSet();
        }
        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId)));
    }

    // --- Core Tunneling Logic ---

    /**
     * @dev Mints the initial set of Quantum Tunnel NFTs.
     * @param to The address to mint the tunnel to.
     * @dev Only callable by the owner.
     */
    function mintInitialTunnel(address to) external onlyOwner whenNotPaused {
        uint256 newTokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, newTokenId);

        // Initialize base tunnel parameters
        _tunnelParameters[newTokenId] = TunnelParameters({
            stability: 500, // Start mid-range
            capacity: 100,
            speed: 500,
            purity: 500,
            lastUsedTimestamp: 0,
            cooldownEndTimestamp: 0,
            successChanceModifier: 0,
            currentStatus: TunnelStatus.Idle
        });

        emit TunnelMinted(to, newTokenId);
    }

    /**
     * @dev Initiates a tunneling process for a specific Quantum Tunnel NFT.
     * Locks the input asset and requests VRF randomness for the outcome.
     * @param tokenId The ID of the tunnel NFT to use.
     * @param inputAssetType The type of asset being sent (ETH, ERC20, ERC721).
     * @param inputTokenAddress The contract address for ERC20/ERC721 inputs (address(0) for ETH).
     * @param inputNFTId The token ID for ERC721 input (0 for ETH/ERC20).
     * @param inputAmount The amount for ETH/ERC20 input (0 for ERC721).
     */
    function initiateTunneling(
        uint256 tokenId,
        AssetType inputAssetType,
        address inputTokenAddress,
        uint256 inputNFTId,
        uint256 inputAmount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId)
        onlyTunnelInStatus(tokenId, TunnelStatus.Idle)
    {
        TunnelParameters storage tunnel = _tunnelParameters[tokenId];

        if (block.timestamp < tunnel.cooldownEndTimestamp) {
            revert TunnelOnCooldown();
        }

        // --- Validate Input Asset ---
        if (inputAssetType == AssetType.ETH) {
            if (msg.value == 0) revert InsufficientFunds(1, 0);
            if (inputTokenAddress != address(0) || inputNFTId != 0 || inputAmount != msg.value) revert InvalidInputAsset();
        } else if (inputAssetType == AssetType.ERC20) {
             if (msg.value > 0) revert InvalidInputAsset();
            if (inputTokenAddress == address(0)) revert InvalidInputAsset();
            if (!_allowedERC20Input[inputTokenAddress]) revert InputAssetNotAllowed(inputTokenAddress);
            if (inputAmount == 0) revert InvalidInputAsset();
             if (inputNFTId != 0) revert InvalidInputAsset();
        } else if (inputAssetType == AssetType.ERC721) {
             if (msg.value > 0) revert InvalidInputAsset();
            if (inputTokenAddress == address(0)) revert InvalidInputAsset();
            if (!_allowedERC721Input[inputTokenAddress]) revert InputAssetNotAllowed(inputTokenAddress);
            if (inputNFTId == 0) revert InvalidInputAsset(); // ERC721 ID must be non-zero
            if (inputAmount != 0) revert InvalidInputAsset();
        } else {
            revert InvalidInputAsset(); // Unknown AssetType
        }

         // --- Handle Input Asset Transfer/Lock ---
        if (inputAssetType == AssetType.ERC20) {
            IERC20(inputTokenAddress).safeTransferFrom(_msgSender(), address(this), inputAmount);
        } else if (inputAssetType == AssetType.ERC721) {
            IERC721(inputTokenAddress).safeTransferFrom(_msgSender(), address(this), inputNFTId);
        }
        // ETH is handled by payable keyword and msg.value

        // --- Determine Journey Duration (Example: inversely related to speed) ---
        // Speed 0 -> max duration, Speed 1000 -> min duration
        uint64 journeyDuration = _maxTunnelDuration - ((_maxTunnelDuration - _minTunnelDuration) * tunnel.speed / 1000);
        if (journeyDuration < _minTunnelDuration) journeyDuration = _minTunnelDuration; // Sanity check

        uint64 expectedEndTime = uint64(block.timestamp) + journeyDuration;

        // --- Request Verifiable Randomness ---
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_keyHash,
            i_subscriptionId,
            3, // Request 3 random words for potential multiple outcomes/rolls
            CALLBACK_GAS_LIMIT,
            1 // Request just 1 time
        );

        // --- Store Process Data ---
        _tunnelProcesses[tokenId] = TunnelProcess({
            initiator: _msgSender(),
            inputAssetType: inputAssetType,
            inputTokenAddress: inputTokenAddress,
            inputNFTId: inputNFTId,
            inputAmount: inputAmount,
            startTimestamp: uint64(block.timestamp),
            expectedEndTime: expectedEndTime,
            vrfRequestId: requestId,
            randomnessFulfilled: false,
            randomnessResult: 0, // Will be set in rawFulfillRandomWords
            finalized: false
        });

        // Update tunnel status
        tunnel.currentStatus = TunnelStatus.Tunneling;
        tunnel.lastUsedTimestamp = uint64(block.timestamp);
        // Cooldown is applied *after* finalization based on speed and outcome

        _vrfRequests[requestId] = tokenId; // Map request ID back to token ID

        emit TunnelingInitiated(
            tokenId,
            _msgSender(),
            inputAssetType,
            inputTokenAddress,
            inputNFTId,
            inputAmount,
            expectedEndTime,
            requestId
        );
    }

    /**
     * @dev Chainlink VRF V2 callback function. Receives random words.
     * @param requestId The ID of the VRF request.
     * @param randomWords The random numbers generated by the VRF.
     */
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 tokenId = _vrfRequests[requestId];
        if (tokenId == 0) {
            // Should not happen if request mapping is managed correctly
            // Consider logging or handling unknown requests
            return;
        }

        TunnelProcess storage process = _tunnelProcesses[tokenId];
        // Only update if the process is still active and randomness hasn't been fulfilled for it
        if (!process.finalized && !process.randomnessFulfilled) {
            process.randomnessResult = randomWords[0]; // Use the first word for primary outcome roll
            process.randomnessFulfilled = true;
            // Transition status if process time is already up
            if (block.timestamp >= process.expectedEndTime) {
                 _tunnelParameters[tokenId].currentStatus = TunnelStatus.ReadyToFinalize;
            }
             // Else, status remains Tunneling until time passes
        }
        // Delete the mapping entry after use
        delete _vrfRequests[requestId];

        emit VRFRandomnessReceived(requestId, tokenId, randomWords[0]);
    }

    /**
     * @dev Finalizes a tunneling process after the expected time has passed and randomness is received.
     * Determines the outcome and executes the corresponding logic.
     * @param tokenId The ID of the tunnel NFT.
     */
    function finalizeTunneling(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId)
    {
        TunnelProcess storage process = _tunnelProcesses[tokenId];
        TunnelParameters storage tunnel = _tunnelParameters[tokenId];

        if (process.finalized) revert ProcessAlreadyFinalized();
        if (!process.randomnessFulfilled) revert RandomnessNotFulfilled();
        if (block.timestamp < process.expectedEndTime) revert CannotFinalizeYet(process.expectedEndTime);
        if (process.initiator == address(0)) revert ProcessNotFound(); // Basic check if process exists

        // Transition status if not already ReadyToFinalize (should be handled by VRF callback, but safe check)
        if (tunnel.currentStatus == TunnelStatus.Tunneling) {
             tunnel.currentStatus = TunnelStatus.ReadyToFinalize;
        }
         if (tunnel.currentStatus != TunnelStatus.ReadyToFinalize) {
             revert InvalidTunnelStatus(tunnel.currentStatus, TunnelStatus.ReadyToFinalize);
         }


        // --- Determine Outcome ---
        // Combine tunnel stats, success chance modifier, and randomness
        uint256 outcomeRoll = process.randomnessResult % 10000; // Roll between 0-9999

        // Example Outcome Logic (Simplified):
        // Base success chance based on stability, modified by `successChanceModifier`.
        // Speed affects cooldown. Capacity affects max input. Purity affects transformation.
        uint256 baseSuccessThreshold = 4000 + tunnel.stability * 5; // Base range (e.g., 4000 + 500*5 = 6500)
        uint256 effectiveSuccessThreshold = baseSuccessThreshold + tunnel.successChanceModifier * 50; // + up to 5000
        if (effectiveSuccessThreshold > 9900) effectiveSuccessThreshold = 9900; // Cap success chance

        TunnelOutcome outcome;
        // Example simple outcome distribution based on roll
        if (outcomeRoll < effectiveSuccessThreshold) {
            // Potential Success or Transformation
            if (tunnel.purity > 700 && outcomeRoll % 2 == 0) { // High purity *might* transform
                // Transformation logic - Example: Always ERC20 for simplicity
                outcome = TunnelOutcome.TransformationERC20; // Could implement more complex transformation logic
            } else {
                outcome = TunnelOutcome.Success;
            }
        } else if (outcomeRoll < effectiveSuccessThreshold + 1500) { // Higher roll = Partial Loss
            outcome = TunnelOutcome.PartialLoss;
        } else if (outcomeRoll < effectiveSuccessThreshold + 2500) { // Even higher roll = Complete Loss
            outcome = TunnelOutcome.CompleteLoss;
        } else if (outcomeRoll < effectiveSuccessThreshold + 2800 && tunnel.stability < 300) { // Low stability might cause collapse
             outcome = TunnelOutcome.TunnelCollapse;
        }
         else { // Default to Complete Loss if not specifically defined above
            outcome = TunnelOutcome.CompleteLoss;
         }


        // --- Execute Outcome Logic ---
        uint256 outputAmount = 0; // For ETH/ERC20
        address outputTokenAddress = address(0); // For ERC20/ERC721
        uint256 outputNFTId = 0; // For ERC721

        if (outcome == TunnelOutcome.Success) {
            // Return original input
            outputAmount = process.inputAmount;
            outputTokenAddress = process.inputTokenAddress; // Relevant for ERC20/ERC721 transfer back
            outputNFTId = process.inputNFTId;
        } else if (outcome == TunnelOutcome.PartialLoss) {
             // Return a percentage based on remaining randomness/purity
             uint256 remainingRoll = process.randomnessResult % 1000; // Use another part of randomness
             uint256 percentage = 20 + (remainingRoll % 60); // Return 20-80%
             outputAmount = process.inputAmount * percentage / 100;
             outputTokenAddress = process.inputTokenAddress;
             outputNFTId = process.inputNFTId; // If NFT, still return the NFT
        } else if (outcome == TunnelOutcome.TransformationERC20) {
            // Example: Transform into a fixed amount of a specific token
            // Requires the contract to *have* this token or the ability to mint it.
            // This is a placeholder; real transformation would require complex logic/ external tokens.
            outputAmount = 100 ether; // Example output amount
            outputTokenAddress = address(0xSomeTransformationTokenAddress); // TODO: Replace with actual address
             // Ensure this contract has the ability/tokens to make this transfer
        } else if (outcome == TunnelOutcome.TransformationERC721) {
             // Example: Transform into a new NFT (e.g., a 'Quantum Fragment')
            // Requires a separate NFT contract and the ability to mint/transfer from it.
            // This is a placeholder.
            outputTokenAddress = address(0xSomeNewNFTContractAddress); // TODO: Replace with actual address
             outputNFTId = 123; // Example new NFT ID (would likely be dynamic)
             // Ensure this contract has the ability/tokens to make this transfer
        } else if (outcome == TunnelOutcome.TunnelCollapse) {
            // Input is lost, tunnel is damaged
             tunnel.currentStatus = TunnelStatus.Damaged;
             emit TunnelDamaged(tokenId);
        }
        // CompleteLoss means input is lost, tunnel remains Idle (or Damaged based on collapse possibility)


        // --- Prepare Output for Claim ---
        // We store the output in the process struct, user calls claimTunnelOutput to retrieve
        // This prevents reentrancy on the complex outcome logic
        // Overwrite process data with outcome details for claiming
        process.inputAssetType = outcome == TunnelOutcome.TransformationERC20 ? AssetType.ERC20 : outcome == TunnelOutcome.TransformationERC721 ? AssetType.ERC721 : process.inputAssetType;
        process.inputTokenAddress = outputTokenAddress;
        process.inputNFTId = outputNFTId;
        process.inputAmount = outputAmount;
        // The rest of the process struct remains to record the history

        process.finalized = true; // Mark process as finalized

        // --- Apply Cooldown (Inversely related to speed) ---
        uint64 baseCooldown = 1 hours; // Base cooldown time
        uint64 effectiveCooldown = baseCooldown + (baseCooldown * (1000 - tunnel.speed) / 1000);
        if (effectiveCooldown < 30 minutes) effectiveCooldown = 30 minutes; // Minimum cooldown

        tunnel.cooldownEndTimestamp = uint64(block.timestamp) + effectiveCooldown;

        // Reset temporary modifier
        tunnel.successChanceModifier = 0;


        // If tunnel collapsed, burn it
        if (outcome == TunnelOutcome.TunnelCollapse) {
            _tunnelCollapse(tokenId);
        } else {
             // Reset status if not collapsed or damaged
             if (tunnel.currentStatus != TunnelStatus.Damaged) {
                tunnel.currentStatus = TunnelStatus.Idle;
             }
        }


        emit TunnelingFinalized(tokenId, outcome, process.randomnessResult);
    }

     /**
     * @dev Internal function to handle tunnel collapse (burning the NFT).
     * @param tokenId The ID of the tunnel NFT to collapse.
     */
    function _tunnelCollapse(uint256 tokenId) internal {
         address owner = ownerOf(tokenId); // Get owner before burning
        _burn(tokenId);
        delete _tunnelParameters[tokenId]; // Clean up parameters
        // Keep process data for history/auditing
        emit TunnelCollapsed(tokenId, owner);
    }


    /**
     * @dev Allows the initiator to cancel a tunneling process before finalization.
     * A percentage of the input asset is lost as a penalty.
     * @param tokenId The ID of the tunnel NFT.
     */
    function cancelTunneling(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyTunnelInStatus(tokenId, TunnelStatus.Tunneling)
    {
        TunnelProcess storage process = _tunnelProcesses[tokenId];
        TunnelParameters storage tunnel = _tunnelParameters[tokenId];

        if (_msgSender() != process.initiator) revert NotTunnelInitiator();
        if (process.finalized) revert ProcessAlreadyFinalized(); // Should be covered by status check, but safe.

        // Cannot cancel if randomness is already fulfilled and time is up
        if (process.randomnessFulfilled && block.timestamp >= process.expectedEndTime) {
             revert InvalidTunnelStatus(tunnel.currentStatus, TunnelStatus.ReadyToFinalize);
        }

        // Penalty: Example loss of 50% of input
        uint256 returnAmount = process.inputAmount * 50 / 100; // 50% returned

        // Reset VRF request mapping if randomness wasn't fulfilled yet
        if (!process.randomnessFulfilled) {
            delete _vrfRequests[process.vrfRequestId];
             // Note: The VRF request might still be processed later by Chainlink, but its mapping is removed.
        }

        // Transfer back the remaining input (if any)
        if (returnAmount > 0) {
             if (process.inputAssetType == AssetType.ETH) {
                 SafeTransferLib.safeTransferETH(payable(_msgSender()), returnAmount);
             } else if (process.inputAssetType == AssetType.ERC20) {
                 IERC20(process.inputTokenAddress).safeTransfer(process.initiator, returnAmount);
             }
             // ERC721 is tricky for partial return, usually not applicable. If cancelled, maybe return the whole NFT?
             // Let's assume ERC721 cancellation means the NFT comes back whole, but the associated ETH/ERC20 'fuel' might be lost.
        }
         if (process.inputAssetType == AssetType.ERC721) {
             IERC721(process.inputTokenAddress).safeTransfer(process.initiator, process.inputNFTId);
         }


        // Clean up process data and reset tunnel status
        delete _tunnelProcesses[tokenId];
        tunnel.currentStatus = TunnelStatus.Idle;
        tunnel.successChanceModifier = 0; // Reset temporary modifier

        // No event for cancellation outcome details, just cleanup

        emit TunnelingFinalized(tokenId, TunnelOutcome.PartialLoss, 0); // Indicate partial loss due to cancellation
    }


    /**
     * @dev Allows the initiator of a completed tunneling process to claim the output assets.
     * @param tokenId The ID of the tunnel NFT.
     */
    function claimTunnelOutput(uint256 tokenId)
        external
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId) // Allow owner or approved to claim on behalf of initiator
    {
        TunnelProcess storage process = _tunnelProcesses[tokenId];

        if (!process.finalized) revert ProcessNotFound(); // Only claim from finalized process
        if (process.inputAmount == 0 && process.inputNFTId == 0) revert NoInputAssetToClaim(); // Nothing to claim

        address claimant = process.initiator; // Output goes to the initiator, not necessarily the current owner/caller

        // Transfer the output asset(s)
        if (process.inputAssetType == AssetType.ETH) {
            SafeTransferLib.safeTransferETH(payable(claimant), process.inputAmount);
        } else if (process.inputAssetType == AssetType.ERC20) {
            IERC20(process.inputTokenAddress).safeTransfer(claimant, process.inputAmount);
        } else if (process.inputAssetType == AssetType.ERC721) {
             IERC721(process.inputTokenAddress).safeTransfer(claimant, process.inputNFTId);
        } else {
            // This should not happen if outcome logic is correct, but good safeguard
             revert InvalidInputAsset(); // Or InvalidOutputAsset?
        }

        emit AssetClaimed(
            tokenId,
            claimant,
            process.inputAssetType,
            process.inputTokenAddress,
            process.inputNFTId,
            process.inputAmount
        );

        // Clear the output details after claiming
        process.inputAssetType = AssetType.ETH; // Reset type
        process.inputTokenAddress = address(0);
        process.inputNFTId = 0;
        process.inputAmount = 0;
        // Keep the rest of the process struct for history (initiator, timestamps, outcome)
    }


    // --- Tunnel Management & Upgrades ---

    /**
     * @dev Upgrades the stability parameter of a tunnel. Costs ETH.
     * @param tokenId The ID of the tunnel NFT.
     */
    function upgradeTunnelStability(uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId)
        onlyTunnelInStatus(tokenId, TunnelStatus.Idle)
    {
         if (msg.value < _baseUpgradeCost) revert InsufficientFunds(_baseUpgradeCost, msg.value);

        TunnelParameters storage tunnel = _tunnelParameters[tokenId];
        // Simple linear increase, capped at 1000
        tunnel.stability = uint16(Math.min(1000, tunnel.stability + 50)); // Example increment

        // Refund excess ETH if any
        if (msg.value > _baseUpgradeCost) {
            SafeTransferLib.safeTransferETH(payable(_msgSender()), msg.value - _baseUpgradeCost);
        }

        emit TunnelUpgraded(tokenId, "stability", tunnel.stability, _baseUpgradeCost);
    }

    /**
     * @dev Upgrades the capacity parameter of a tunnel. Costs ETH.
     * @param tokenId The ID of the tunnel NFT.
     */
    function upgradeTunnelCapacity(uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId)
        onlyTunnelInStatus(tokenId, TunnelStatus.Idle)
    {
        if (msg.value < _baseUpgradeCost) revert InsufficientFunds(_baseUpgradeCost, msg.value);

        TunnelParameters storage tunnel = _tunnelParameters[tokenId];
        tunnel.capacity = uint16(Math.min(1000, tunnel.capacity + 100)); // Example increment

        if (msg.value > _baseUpgradeCost) {
            SafeTransferLib.safeTransferETH(payable(_msgSender()), msg.value - _baseUpgradeCost);
        }

        emit TunnelUpgraded(tokenId, "capacity", tunnel.capacity, _baseUpgradeCost);
    }

     /**
     * @dev Upgrades the speed parameter of a tunnel. Costs ETH.
     * @param tokenId The ID of the tunnel NFT.
     */
    function upgradeTunnelSpeed(uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId)
        onlyTunnelInStatus(tokenId, TunnelStatus.Idle)
    {
        if (msg.value < _baseUpgradeCost) revert InsufficientFunds(_baseUpgradeCost, msg.value);

        TunnelParameters storage tunnel = _tunnelParameters[tokenId];
        tunnel.speed = uint16(Math.min(1000, tunnel.speed + 50)); // Example increment

         if (msg.value > _baseUpgradeCost) {
            SafeTransferLib.safeTransferETH(payable(_msgSender()), msg.value - _baseUpgradeCost);
        }

        emit TunnelUpgraded(tokenId, "speed", tunnel.speed, _baseUpgradeCost);
    }

    /**
     * @dev Stabilizes the quantum field around the tunnel, temporarily boosting the success chance for the next journey.
     * Consumes ETH or a specific ERC20 (example using ETH). Must be called when Idle.
     * @param tokenId The ID of the tunnel NFT.
     */
    function stabilizeQuantumField(uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId)
        onlyTunnelInStatus(tokenId, TunnelStatus.Idle)
    {
         if (msg.value < _stabilizeCost) revert InsufficientFunds(_stabilizeCost, msg.value);

        TunnelParameters storage tunnel = _tunnelParameters[tokenId];
        tunnel.successChanceModifier = uint16(Math.min(100, tunnel.successChanceModifier + 20)); // Example boost (max 100)

         if (msg.value > _stabilizeCost) {
            SafeTransferLib.safeTransferETH(payable(_msgSender()), msg.value - _stabilizeCost);
        }

        emit FieldStabilized(tokenId, _msgSender(), _stabilizeCost);
    }

    /**
     * @dev Repairs a damaged tunnel. Costs ETH. Must be called when Damaged.
     * @param tokenId The ID of the tunnel NFT.
     */
    function repairTunnelStructure(uint256 tokenId)
        external
        payable
        nonReentrant
        whenNotPaused
        onlyTunnelOwnerOrApproved(tokenId)
        onlyTunnelInStatus(tokenId, TunnelStatus.Damaged)
    {
         if (msg.value < _repairCost) revert InsufficientFunds(_repairCost, msg.value);

        TunnelParameters storage tunnel = _tunnelParameters[tokenId];
        tunnel.currentStatus = TunnelStatus.Idle; // Set back to Idle
         // Could also reset some stats like stability decay etc.

         if (msg.value > _repairCost) {
            SafeTransferLib.safeTransferETH(payable(_msgSender()), msg.value - _repairCost);
        }

        emit TunnelRepaired(tokenId, _msgSender());
        emit RepairExecuted(tokenId, _msgSender(), _repairCost);
    }

    // --- Information & Getters ---

    /**
     * @dev Returns the parameters of a specific Quantum Tunnel.
     * @param tokenId The ID of the tunnel NFT.
     * @return struct TunnelParameters
     */
    function getTunnelParameters(uint256 tokenId)
        public
        view
        returns (TunnelParameters memory)
    {
        if (!_exists(tokenId)) revert TunnelNotFound();
        return _tunnelParameters[tokenId];
    }

     /**
     * @dev Returns the current operational status of a specific Quantum Tunnel.
     * @param tokenId The ID of the tunnel NFT.
     * @return TunnelStatus The current status.
     */
    function getTunnelStatus(uint256 tokenId)
        public
        view
        returns (TunnelStatus)
    {
         if (!_exists(tokenId)) revert TunnelNotFound();
        return _tunnelParameters[tokenId].currentStatus;
    }

     /**
     * @dev Returns details about the current or last tunneling process for a tunnel.
     * @param tokenId The ID of the tunnel NFT.
     * @return struct TunnelProcess
     */
    function getProcessDetails(uint256 tokenId)
        public
        view
        returns (TunnelProcess memory)
    {
        // Note: This will return default values if no process has ever run or it was explicitly deleted.
        // Could add a check if(_tunnelProcesses[tokenId].initiator == address(0)) revert NoProcessData();
        return _tunnelProcesses[tokenId];
    }


    /**
     * @dev Checks if a given ERC20 token address is allowed as input.
     * @param tokenAddress The address of the ERC20 contract.
     * @return bool True if allowed, false otherwise.
     */
    function getAllowedTokenInput(address tokenAddress) public view returns (bool) {
        return _allowedERC20Input[tokenAddress];
    }

    /**
     * @dev Checks if a given ERC721 token address is allowed as input.
     * @param nftAddress The address of the ERC721 contract.
     * @return bool True if allowed, false otherwise.
     */
    function getAllowedNFTInput(address nftAddress) public view returns (bool) {
        return _allowedERC721Input[nftAddress];
    }

    /**
     * @dev Gets the timestamp when a tunnel is out of its cooldown period.
     * @param tokenId The ID of the tunnel NFT.
     * @return uint64 Timestamp, 0 if no cooldown active.
     */
    function getTunnelCooldown(uint256 tokenId) public view returns (uint64) {
         if (!_exists(tokenId)) revert TunnelNotFound();
        return _tunnelParameters[tokenId].cooldownEndTimestamp;
    }


    // --- Admin Functions (Owner Only) ---

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     * @dev Only callable by the owner.
     */
    function pauseContract() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume.
     * @dev Only callable by the owner.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets whether a specific ERC20 token is allowed as input for tunneling.
     * @param tokenAddress The address of the ERC20 contract.
     * @param allowed True to allow, false to disallow.
     * @dev Only callable by the owner.
     */
    function setAllowedTokenInput(address tokenAddress, bool allowed) external onlyOwner {
        _allowedERC20Input[tokenAddress] = allowed;
        emit InputAssetConfigured(tokenAddress, AssetType.ERC20, allowed);
    }

    /**
     * @dev Sets whether a specific ERC721 token is allowed as input for tunneling.
     * @param nftAddress The address of the ERC721 contract.
     * @param allowed True to allow, false to disallow.
     * @dev Only callable by the owner.
     */
    function setAllowedNFTInput(address nftAddress, bool allowed) external onlyOwner {
        _allowedERC721Input[nftAddress] = allowed;
        emit InputAssetConfigured(nftAddress, AssetType.ERC721, allowed);
    }

    /**
     * @dev Sets the base minimum duration for a tunneling journey.
     * @param duration The minimum duration in seconds.
     * @dev Only callable by the owner.
     */
    function setMinTunnelDuration(uint64 duration) external onlyOwner {
        _minTunnelDuration = duration;
        emit ParametersUpdated("minTunnelDuration", duration);
    }

    /**
     * @dev Sets the base maximum duration for a tunneling journey.
     * @param duration The maximum duration in seconds.
     * @dev Only callable by the owner.
     */
    function setMaxTunnelDuration(uint64 duration) external onlyOwner {
        _maxTunnelDuration = duration;
         emit ParametersUpdated("maxTunnelDuration", duration);
    }

     /**
     * @dev Sets the base ETH cost for parameter upgrades.
     * @param cost The cost in Wei.
     * @dev Only callable by the owner.
     */
    function setBaseUpgradeCost(uint256 cost) external onlyOwner {
        _baseUpgradeCost = cost;
         emit ParametersUpdated("baseUpgradeCost", cost);
    }

    /**
     * @dev Sets the ETH cost to repair a damaged tunnel.
     * @param cost The cost in Wei.
     * @dev Only callable by the owner.
     */
    function setRepairCost(uint256 cost) external onlyOwner {
        _repairCost = cost;
         emit ParametersUpdated("repairCost", cost);
    }

    /**
     * @dev Sets the ETH cost to stabilize the quantum field.
     * @param cost The cost in Wei.
     * @dev Only callable by the owner.
     */
    function setStabilizeCost(uint256 cost) external onlyOwner {
        _stabilizeCost = cost;
         emit ParametersUpdated("stabilizeCost", cost);
    }

    /**
     * @dev Sets the address designated for recovering stuck assets.
     * @param recoveryAddress The address to send recovered assets to.
     * @dev Only callable by the owner.
     */
    function setCollateralRecoveryAddress(address payable recoveryAddress) external onlyOwner {
        _collateralRecoveryAddress = recoveryAddress;
    }

    /**
     * @dev Allows the owner or collateral recovery address to withdraw stuck ETH.
     * Useful if ETH is sent to the contract accidentally, *not* part of a tunneling process.
     * @dev Only callable by owner or collateral recovery address.
     */
    function withdrawStuckETH() external onlyCollateralRecoveryAddress {
         uint256 balance = address(this).balance;
         // Ensure we don't withdraw ETH currently locked in active ETH processes
         // This is complex; simpler version withdraws everything.
         // Advanced version would need to track locked ETH amounts per process.
         // For simplicity, this withdraws all available ETH. Exercise caution.

        SafeTransferLib.safeTransferETH(_collateralRecoveryAddress, balance);
    }

    /**
     * @dev Allows the owner or collateral recovery address to withdraw stuck ERC20 tokens.
     * Useful if tokens are sent to the contract accidentally, *not* part of a tunneling process.
     * @param tokenAddress The address of the ERC20 contract.
     * @dev Only callable by owner or collateral recovery address.
     */
    function withdrawStuckTokens(address tokenAddress) external onlyCollateralRecoveryAddress {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
         // Similar caution as withdrawStuckETH regarding tokens locked in active processes.

        token.safeTransfer(_collateralRecoveryAddress, balance);
    }

    /**
     * @dev Allows the owner or collateral recovery address to withdraw a stuck ERC721 token.
     * Useful if an NFT is sent to the contract accidentally, *not* part of a tunneling process.
     * @param nftAddress The address of the ERC721 contract.
     * @param nftId The ID of the stuck NFT.
     * @dev Only callable by owner or collateral recovery address.
     */
    function withdrawStuckNFT(address nftAddress, uint256 nftId) external onlyCollateralRecoveryAddress {
         IERC721 token = IERC721(nftAddress);
         // Check if the contract actually owns this specific NFT.
         if (token.ownerOf(nftId) != address(this)) {
            revert RecoveryFailed(); // Or specific error like NFTNotOwnedByContract
         }

        token.safeTransfer(_collateralRecoveryAddress, nftId);
    }


    /**
     * @dev Allows the owner to recover input assets from a specific tunneling process.
     * Use with caution, typically for stuck processes where VRF failed or similar issues.
     * This bypasses the normal claim process and outcome logic.
     * @param tokenId The ID of the tunnel NFT.
     * @dev Only callable by the owner.
     */
    function recoverFundsFromProcess(uint256 tokenId) external onlyOwner nonReentrant {
        TunnelProcess storage process = _tunnelProcesses[tokenId];

         if (process.initiator == address(0)) revert ProcessNotFound();
        // Do not allow recovery if the process has successfully finalized and outcome data is set
        if (process.finalized && (process.inputAmount > 0 || process.inputNFTId > 0)) {
             revert ProcessAlreadyFinalized(); // Or specific error like CannotRecoverFinalizedProcess
        }


        address recoveryDestination = _collateralRecoveryAddress; // Send to recovery address

        // Transfer the *original* input asset(s) back
        if (process.inputAmount > 0) {
             if (process.inputAssetType == AssetType.ETH) {
                 SafeTransferLib.safeTransferETH(payable(recoveryDestination), process.inputAmount);
             } else if (process.inputAssetType == AssetType.ERC20) {
                 IERC20(process.inputTokenAddress).safeTransfer(recoveryDestination, process.inputAmount);
             }
        }
         if (process.inputNFTId > 0) {
             if (process.inputAssetType == AssetType.ERC721) {
                 IERC721(process.inputTokenAddress).safeTransfer(recoveryDestination, process.inputNFTId);
             }
         }

        // Clean up the process data after recovery
        delete _tunnelProcesses[tokenId];

         // Reset tunnel status if it was stuck in Tunneling or ReadyToFinalize
         TunnelParameters storage tunnel = _tunnelParameters[tokenId];
        if (tunnel.currentStatus == TunnelStatus.Tunneling || tunnel.currentStatus == TunnelStatus.ReadyToFinalize) {
             tunnel.currentStatus = TunnelStatus.Idle;
        }

        emit AssetClaimed(tokenId, recoveryDestination, process.inputAssetType, process.inputTokenAddress, process.inputNFTId, process.inputAmount); // Use AssetClaimed event for tracking recovery too
    }


    /**
     * @dev Sets the base URI for token metadata.
     * @param baseURI The base URI string.
     * @dev Only callable by the owner.
     */
    function setTunnelMetadataURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    // --- Receive and Fallback ---

    receive() external payable {} // Allow receiving ETH for payments/input
    fallback() external payable {} // Also allow receiving ETH via fallback

    // --- Internal Helpers (Optional: Can be external getters if needed) ---

    /**
     * @dev Internal utility for getting the current token ID counter.
     */
    function _getCurrentTokenIdCounter() internal view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // Need a basic Math library for min/max used in upgrade caps etc.
     library Math {
        function min(uint256 a, uint256 b) internal pure returns (uint256) {
            return a < b ? a : b;
        }
         function max(uint256 a, uint256 b) internal pure returns (uint256) {
             return a > b ? a : b;
         }
     }
}

```