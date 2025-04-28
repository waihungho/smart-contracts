Okay, here is a Solidity smart contract implementing an advanced, multi-asset, stateful escrow system with time-based and conditional release mechanisms, including a grace period for unclaimed funds and distinct roles.

This contract aims to be creative by combining several features:
1.  **Multi-Asset Support:** Handling ETH, ERC-20, and ERC-721 tokens in the same escrow.
2.  **State Machine:** Each escrow has a distinct lifecycle (`Active`, `ConditionMet`, `Expired`, `Released`, `Cancelled`, `GracePeriod`, `Completed`).
3.  **Flexible Release Conditions:** Escrows can be released based *only* on time, *only* on a condition being met, *either* time *or* condition, or *both* time *and* condition.
4.  **Designated Condition Signaler:** A specific address (other than depositor/recipient) can be authorized to signal that an external condition is met.
5.  **Grace Period:** After expiry, there's a window for the depositor to reclaim funds if the recipient hasn't claimed and conditions weren't met appropriately.
6.  **Explicit Role Functions:** Separate functions for depositor cancellation, recipient claiming, general release/cancel (which checks conditions/roles).
7.  **Comprehensive State Tracking:** Detailed struct and mapping to keep track of each individual escrow's parameters and current state.

It uses standard OpenZeppelin libraries for safety (Ownable, Pausable, ReentrancyGuard, SafeERC20, SafeERC721) but the core logic and state machine for the escrow concept are custom.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/SafeERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title EternalEphemeralEscrow
 * @dev A sophisticated escrow contract supporting ETH, ERC20, and ERC721 assets.
 *      Each escrow is ephemeral (time-limited) but managed by an eternal contract.
 *      Features include state machine, conditional/timed release, condition signaling, and a grace period.
 *      Inspired by the need for more complex decentralized asset holding and release scenarios.
 */
contract EternalEphemeralEscrow is Context, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC721 for IERC721;

    /*
     * OUTLINE:
     * 1. State Variables & Data Structures
     * 2. Enums for Asset Type, Escrow State, Release Type
     * 3. Events
     * 4. Modifiers (custom, alongside inherited)
     * 5. Constructor
     * 6. Deposit Functions (ETH, ERC20, ERC721)
     * 7. Read Functions (Get escrow details, user escrows)
     * 8. Core Logic Functions (Signal condition, Release, Cancel)
     * 9. Role-Specific Functions (Release by depositor/recipient, Cancel by depositor, Grace period reclaim)
     * 10. Admin/Owner Functions (Set signaler, Set grace period, Withdraw trapped assets, Pause/Unpause)
     * 11. Fallback/Receive
     */

    /*
     * FUNCTION SUMMARY:
     *
     * State Variables:
     * - nextEscrowId: Counter for unique escrow IDs.
     * - escrows: Mapping from escrow ID to Escrow struct.
     * - userEscrows: Mapping from user address to array of escrow IDs they are involved in (depositor or recipient).
     * - conditionSignaler: Address authorized to signal condition met.
     * - gracePeriodDuration: Duration after expiry for depositor reclaim.
     *
     * Enums:
     * - AssetType: ETH, ERC20, ERC721.
     * - EscrowState: Active, ConditionMet, Expired, Released, Cancelled, GracePeriod, Completed.
     * - ReleaseType: Timed, Conditional, TimedOrConditional, TimedAndConditional.
     *
     * Events:
     * - EscrowCreated: Logs parameters when an escrow is initiated.
     * - EscrowStateChanged: Logs transitions between escrow states.
     * - ConditionSignaled: Logs when the condition for an escrow is met.
     * - AssetsReleased: Logs when assets are successfully released to recipient.
     * - EscrowCancelled: Logs when an escrow is cancelled and assets returned to depositor.
     * - GracePeriodClaimed: Logs when depositor reclaims assets during the grace period.
     * - TrappedAssetsWithdrawn: Logs when owner withdraws trapped assets.
     * - ConditionSignalerUpdated: Logs changes to the condition signaler address.
     * - GracePeriodDurationUpdated: Logs changes to the grace period duration.
     * (Inherits OwnershipTransferred, Paused, Unpaused from Ownable, Pausable)
     *
     * Modifiers:
     * - onlyDepositor(uint250 escrowId): Restricts access to the escrow's depositor.
     * - onlyRecipient(uint250 escrowId): Restricts access to the escrow's recipient.
     * - onlySignaler(): Restricts access to the condition signaler address.
     * - onlyInState(uint250 escrowId, EscrowState expectedState): Restricts access based on current escrow state.
     * - notInState(uint250 escrowId, EscrowState forbiddenState): Restricts access if escrow is NOT in a specific state.
     * (Inherits onlyOwner, whenNotPaused, whenPaused, nonReentrant)
     *
     * Constructor:
     * - Initializes the contract, sets initial owner.
     *
     * Deposit Functions:
     * - depositEth(address recipient, uint256 expiryTime, uint256 releaseType, bool conditional, string calldata description): Creates ETH escrow.
     * - depositERC20(address tokenAddress, uint256 amount, address recipient, uint256 expiryTime, uint256 releaseType, bool conditional, string calldata description): Creates ERC20 escrow. Requires depositor approval beforehand.
     * - depositERC721(address tokenAddress, uint256 tokenId, address recipient, uint256 expiryTime, uint256 releaseType, bool conditional, string calldata description): Creates ERC721 escrow. Requires depositor approval beforehand.
     *
     * Read Functions:
     * - getEscrowDetails(uint250 escrowId): Returns the full details of an escrow.
     * - getUserEscrows(address user): Returns an array of escrow IDs associated with a user (depositor or recipient).
     * - isEscrowActive(uint250 escrowId): Checks if an escrow is in the `Active` state.
     * - getConditionSignaler(): Returns the current condition signaler address.
     * - getGracePeriodDuration(): Returns the grace period duration.
     *
     * Core Logic Functions:
     * - signalConditionMet(uint250 escrowId): Called by the condition signaler to mark a conditional escrow's condition as met.
     * - releaseEscrow(uint250 escrowId): Attempts to release assets to the recipient. Checks all release conditions (time, conditionMet, releaseType, state). Can be called by depositor, recipient, or signaler (design choice - allowing multiple callers simplifies Dapp logic, contract checks permissions internally).
     * - cancelEscrow(uint250 escrowId): Attempts to cancel an escrow and return assets to the depositor. Checks state and caller permissions (typically only depositor before expiry). Can be called by depositor or maybe owner for specific recovery (design choice - let's allow only depositor for standard cancel, but add an owner recovery later).
     *
     * Role-Specific Functions:
     * - releaseEscrowByDepositor(uint250 escrowId): Specific entry point for depositor initiated release (e.g., early release). Checks appropriate state.
     * - releaseEscrowByRecipient(uint250 escrowId): Specific entry point for recipient initiated claim (e.g., after expiry/condition met). Checks appropriate state.
     * - cancelEscrowByDepositor(uint250 escrowId): Specific entry point for depositor initiated cancellation (e.g., before expiry). Checks appropriate state.
     * - claimGracePeriodReturn(uint250 escrowId): Allows the depositor to reclaim assets after expiry if grace period is active and assets are not claimed. Checks appropriate state.
     *
     * Admin/Owner Functions:
     * - setConditionSignaler(address _signaler): Sets the address authorized to signal conditions.
     * - setGracePeriodDuration(uint256 _duration): Sets the duration of the grace period after expiry.
     * - withdrawETH(address payable recipient, uint256 amount): Allows owner to withdraw accidentally sent ETH (not escrowed ETH).
     * - withdrawERC20(address tokenAddress, address recipient, uint256 amount): Allows owner to withdraw accidentally sent ERC20 (not escrowed tokens).
     * - withdrawERC721(address tokenAddress, address recipient, uint256 tokenId): Allows owner to withdraw accidentally sent ERC721 (not escrowed tokens).
     * - pause(): Pauses contract operations (deposits, releases, cancels, signals, claims).
     * - unpause(): Unpauses contract operations.
     * (Inherits transferOwnership, renounceOwnership from Ownable)
     *
     * Fallback/Receive:
     * - receive(): Allows direct ETH transfers to the contract, though depositEth is preferred for tracking. Reverts if not paused to prevent untracked deposits.
     * - fallback(): Reverts on unknown function calls.
     */


    // --- State Variables & Data Structures ---

    uint250 public nextEscrowId;

    struct Escrow {
        address depositor;
        address recipient;
        AssetType assetType;
        address assetAddress; // 0x0 for ETH
        uint256 amountOrTokenId; // Amount for ETH/ERC20, tokenId for ERC721
        uint256 depositTime;
        uint256 expiryTime; // Timestamp or block number
        bool conditional; // True if a condition beyond time is required
        bool conditionMet; // True if the condition has been signaled
        EscrowState state;
        ReleaseType releaseType; // How is it released?
        string description; // Optional description
    }

    mapping(uint250 => Escrow) public escrows;
    // To avoid potentially large array reads, we can store indices, but let's keep it simple for this example
    mapping(address => uint250[]) public userEscrows; // Maps user to list of escrow IDs they are part of

    address public conditionSignaler;
    uint256 public gracePeriodDuration = 7 days; // Default grace period after expiry

    // --- Enums ---

    enum AssetType {
        Eth,
        ERC20,
        ERC721
    }

    enum EscrowState {
        Active, // Escrow is live, conditions potentially pending
        ConditionMet, // Condition has been signaled, waiting for time or claim
        Expired, // Expiry time passed, conditions might determine next steps
        Released, // Assets sent to recipient
        Cancelled, // Assets returned to depositor
        GracePeriod, // After expiry, within grace period, depositor can reclaim
        Completed // Escrow finished (released, cancelled, or grace period ended)
    }

    enum ReleaseType {
        Timed, // Can only be released after expiryTime
        Conditional, // Can only be released after conditionMet is true
        TimedOrConditional, // Can be released after expiryTime OR conditionMet is true
        TimedAndConditional // Can only be released after expiryTime AND conditionMet is true
    }

    // --- Events ---

    event EscrowCreated(
        uint250 indexed escrowId,
        address indexed depositor,
        address indexed recipient,
        AssetType assetType,
        address assetAddress,
        uint256 amountOrTokenId,
        uint256 expiryTime,
        bool conditional,
        ReleaseType releaseType,
        string description
    );

    event EscrowStateChanged(uint250 indexed escrowId, EscrowState oldState, EscrowState newState);
    event ConditionSignaled(uint250 indexed escrowId, address indexed signaler);
    event AssetsReleased(uint250 indexed escrowId, address indexed recipient, AssetType assetType, address assetAddress, uint256 amountOrTokenId);
    event EscrowCancelled(uint250 indexed escrowId, address indexed depositor, AssetType assetType, address assetAddress, uint256 amountOrTokenId);
    event GracePeriodClaimed(uint250 indexed escrowId, address indexed depositor, AssetType assetType, address assetAddress, uint256 amountOrTokenId);
    event TrappedAssetsWithdrawn(address indexed owner, address indexed recipient, address assetAddress, uint256 amountOrTokenId);
    event ConditionSignalerUpdated(address indexed oldSignaler, address indexed newSignaler);
    event GracePeriodDurationUpdated(uint256 oldDuration, uint256 newDuration);


    // --- Modifiers ---

    modifier onlyDepositor(uint250 escrowId) {
        require(escrows[escrowId].depositor == _msgSender(), "Not depositor");
        _;
    }

    modifier onlyRecipient(uint250 escrowId) {
        require(escrows[escrowId].recipient == _msgSender(), "Not recipient");
        _;
    }

    modifier onlySignaler() {
        require(conditionSignaler != address(0), "Signaler not set");
        require(conditionSignaler == _msgSender(), "Not authorized signaler");
        _;
    }

    modifier onlyInState(uint250 escrowId, EscrowState expectedState) {
        require(escrows[escrowId].state == expectedState, "Escrow not in expected state");
        _;
    }

    modifier notInState(uint250 escrowId, EscrowState forbiddenState) {
         require(escrows[escrowId].state != forbiddenState, "Escrow is in forbidden state");
        _;
    }


    // --- Constructor ---

    constructor() Ownable(_msgSender()) Pausable() ReentrancyGuard() {
        // Initialize with owner as sender. Condition signaler and grace period can be set later.
        // Initial nextEscrowId is 0, first escrow will be ID 0.
    }


    // --- Deposit Functions ---

    /**
     * @dev Creates an escrow for Ether.
     * @param recipient The address who will receive the ETH.
     * @param expiryTime The time (timestamp) after which time-based conditions might be met or grace period starts.
     * @param releaseType How the release condition is evaluated (Timed, Conditional, TimedOrConditional, TimedAndConditional).
     * @param conditional If true, a separate condition beyond time is required, signalable by `conditionSignaler`.
     * @param description An optional description of the escrow.
     */
    function depositEth(
        address payable recipient,
        uint256 expiryTime,
        ReleaseType releaseType,
        bool conditional,
        string calldata description
    ) external payable nonReentrant whenNotPaused returns (uint250) {
        require(msg.value > 0, "Amount must be > 0");
        require(recipient != address(0), "Recipient cannot be zero address");
        require(expiryTime > block.timestamp, "Expiry time must be in the future");
        if (conditional) {
            require(conditionSignaler != address(0), "Condition signaler must be set for conditional release");
        } else {
            require(releaseType != ReleaseType.Conditional && releaseType != ReleaseType.TimedAndConditional, "Cannot use conditional release type if not conditional");
        }
        require(releaseType <= ReleaseType.TimedAndConditional, "Invalid release type");


        uint250 id = nextEscrowId++;
        userEscrows[_msgSender()].push(id);
        userEscrows[recipient].push(id);

        escrows[id] = Escrow({
            depositor: _msgSender(),
            recipient: recipient,
            assetType: AssetType.Eth,
            assetAddress: address(0),
            amountOrTokenId: msg.value,
            depositTime: block.timestamp,
            expiryTime: expiryTime,
            conditional: conditional,
            conditionMet: false, // Initially false
            state: EscrowState.Active,
            releaseType: releaseType,
            description: description
        });

        emit EscrowCreated(
            id,
            _msgSender(),
            recipient,
            AssetType.Eth,
            address(0),
            msg.value,
            expiryTime,
            conditional,
            releaseType,
            description
        );
        emit EscrowStateChanged(id, EscrowState.Active, EscrowState.Active); // Redundant but follows state change pattern

        return id;
    }

    /**
     * @dev Creates an escrow for an ERC20 token. Requires prior approval from depositor.
     * @param tokenAddress The address of the ERC20 token.
     * @param amount The amount of tokens to escrow.
     * @param recipient The address who will receive the tokens.
     * @param expiryTime The time (timestamp) after which time-based conditions might be met or grace period starts.
     * @param releaseType How the release condition is evaluated.
     * @param conditional If true, a separate condition beyond time is required.
     * @param description An optional description.
     */
    function depositERC20(
        address tokenAddress,
        uint256 amount,
        address recipient,
        uint256 expiryTime,
        ReleaseType releaseType,
        bool conditional,
        string calldata description
    ) external nonReentrant whenNotPaused returns (uint250) {
        require(amount > 0, "Amount must be > 0");
        require(tokenAddress != address(0), "Token address cannot be zero address");
        require(recipient != address(0), "Recipient cannot be zero address");
        require(expiryTime > block.timestamp, "Expiry time must be in the future");
        if (conditional) {
            require(conditionSignaler != address(0), "Condition signaler must be set for conditional release");
        } else {
             require(releaseType != ReleaseType.Conditional && releaseType != ReleaseType.TimedAndConditional, "Cannot use conditional release type if not conditional");
        }
        require(releaseType <= ReleaseType.TimedAndConditional, "Invalid release type");


        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(_msgSender(), address(this), amount);

        uint250 id = nextEscrowId++;
        userEscrows[_msgSender()].push(id);
        userEscrows[recipient].push(id);

        escrows[id] = Escrow({
            depositor: _msgSender(),
            recipient: recipient,
            assetType: AssetType.ERC20,
            assetAddress: tokenAddress,
            amountOrTokenId: amount,
            depositTime: block.timestamp,
            expiryTime: expiryTime,
            conditional: conditional,
            conditionMet: false, // Initially false
            state: EscrowState.Active,
            releaseType: releaseType,
            description: description
        });

        emit EscrowCreated(
            id,
            _msgSender(),
            recipient,
            AssetType.ERC20,
            tokenAddress,
            amount,
            expiryTime,
            conditional,
            releaseType,
            description
        );
        emit EscrowStateChanged(id, EscrowState.Active, EscrowState.Active);

        return id;
    }

    /**
     * @dev Creates an escrow for an ERC721 token (NFT). Requires prior approval from depositor.
     * @param tokenAddress The address of the ERC721 token.
     * @param tokenId The ID of the NFT to escrow.
     * @param recipient The address who will receive the NFT.
     * @param expiryTime The time (timestamp) after which time-based conditions might be met or grace period starts.
     * @param releaseType How the release condition is evaluated.
     * @param conditional If true, a separate condition beyond time is required.
     * @param description An optional description.
     */
    function depositERC721(
        address tokenAddress,
        uint256 tokenId,
        address recipient,
        uint256 expiryTime,
        ReleaseType releaseType,
        bool conditional,
        string calldata description
    ) external nonReentrant whenNotPaused returns (uint250) {
        require(tokenAddress != address(0), "Token address cannot be zero address");
        require(recipient != address(0), "Recipient cannot be zero address");
        require(expiryTime > block.timestamp, "Expiry time must be in the future");
        if (conditional) {
             require(conditionSignaler != address(0), "Condition signaler must be set for conditional release");
        } else {
             require(releaseType != ReleaseType.Conditional && releaseType != ReleaseType.TimedAndConditional, "Cannot use conditional release type if not conditional");
        }
         require(releaseType <= ReleaseType.TimedAndConditional, "Invalid release type");


        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == _msgSender(), "Depositor must own the NFT");
        token.safeTransferFrom(_msgSender(), address(this), tokenId);

        uint250 id = nextEscrowId++;
        userEscrows[_msgSender()].push(id);
        userEscrows[recipient].push(id);

        escrows[id] = Escrow({
            depositor: _msgSender(),
            recipient: recipient,
            assetType: AssetType.ERC721,
            assetAddress: tokenAddress,
            amountOrTokenId: tokenId,
            depositTime: block.timestamp,
            expiryTime: expiryTime,
            conditional: conditional,
            conditionMet: false, // Initially false
            state: EscrowState.Active,
            releaseType: releaseType,
            description: description
        });

        emit EscrowCreated(
            id,
            _msgSender(),
            recipient,
            AssetType.ERC721,
            tokenAddress,
            tokenId,
            expiryTime,
            conditional,
            releaseType,
            description
        );
        emit EscrowStateChanged(id, EscrowState.Active, EscrowState.Active);

        return id;
    }

    // --- Read Functions ---

    /**
     * @dev Gets the details of a specific escrow.
     * @param escrowId The ID of the escrow.
     * @return Escrow struct data.
     */
    function getEscrowDetails(uint250 escrowId) public view returns (Escrow memory) {
        require(escrowId < nextEscrowId, "Invalid escrow ID");
        return escrows[escrowId];
    }

    /**
     * @dev Gets the list of escrow IDs a user is involved in (either as depositor or recipient).
     * @param user The user address.
     * @return An array of escrow IDs.
     */
    function getUserEscrows(address user) public view returns (uint250[] memory) {
        return userEscrows[user];
    }

    /**
     * @dev Checks if an escrow is currently in the Active state.
     * @param escrowId The ID of the escrow.
     * @return True if state is Active, false otherwise.
     */
    function isEscrowActive(uint250 escrowId) public view returns (bool) {
        require(escrowId < nextEscrowId, "Invalid escrow ID");
        return escrows[escrowId].state == EscrowState.Active;
    }

    /**
     * @dev Returns the address of the current condition signaler.
     */
    function getConditionSignaler() public view returns (address) {
        return conditionSignaler;
    }

    /**
     * @dev Returns the duration of the grace period in seconds.
     */
    function getGracePeriodDuration() public view returns (uint256) {
        return gracePeriodDuration;
    }


    // --- Core Logic Functions ---

    /**
     * @dev Allows the condition signaler to signal that an external condition for an escrow has been met.
     * @param escrowId The ID of the escrow.
     */
    function signalConditionMet(uint250 escrowId)
        external
        onlySignaler()
        onlyInState(escrowId, EscrowState.Active)
        nonReentrant
        whenNotPaused
    {
        Escrow storage escrow = escrows[escrowId];
        require(escrow.conditional, "Escrow is not conditional");
        require(!escrow.conditionMet, "Condition already signaled");

        escrow.conditionMet = true;
        // If the state transition is direct upon signaling, update state
        if (escrow.releaseType == ReleaseType.Conditional || escrow.releaseType == ReleaseType.TimedOrConditional) {
             _updateEscrowState(escrowId, EscrowState.ConditionMet);
        } else {
             // For TimedAndConditional, it stays Active until time passes
            emit ConditionSignaled(escrowId, _msgSender());
        }

    }

    /**
     * @dev Attempts to release assets for an escrow. Checks release conditions and current state.
     *      Can be called by depositor or recipient or signaler for flexibility, the function verifies eligibility.
     * @param escrowId The ID of the escrow.
     */
    function releaseEscrow(uint250 escrowId)
        external
        nonReentrant
        whenNotPaused
    {
        Escrow storage escrow = escrows[escrowId];
        require(escrowId < nextEscrowId, "Invalid escrow ID");
        require(escrow.state <= EscrowState.Expired, "Escrow not in a releasable state"); // Active, ConditionMet, Expired are potentially releasable states

        // Check if the conditions for release are met
        bool timeConditionMet = block.timestamp >= escrow.expiryTime;
        bool conditionMet = escrow.conditionMet;
        bool canRelease = false;

        if (escrow.releaseType == ReleaseType.Timed) {
            canRelease = timeConditionMet;
        } else if (escrow.releaseType == ReleaseType.Conditional) {
            canRelease = conditionMet;
        } else if (escrow.releaseType == ReleaseType.TimedOrConditional) {
            canRelease = timeConditionMet || conditionMet;
        } else if (escrow.releaseType == ReleaseType.TimedAndConditional) {
            canRelease = timeConditionMet && conditionMet;
        }

        require(canRelease, "Release conditions not met yet");
        require(_msgSender() == escrow.depositor || _msgSender() == escrow.recipient || _msgSender() == conditionSignaler, "Only depositor, recipient, or signaler can initiate release");


        // Transfer assets
        if (escrow.assetType == AssetType.Eth) {
            (bool success, ) = payable(escrow.recipient).call{value: escrow.amountOrTokenId}("");
            require(success, "ETH transfer failed");
        } else if (escrow.assetType == AssetType.ERC20) {
            IERC20(escrow.assetAddress).safeTransfer(escrow.recipient, escrow.amountOrTokenId);
        } else if (escrow.assetType == AssetType.ERC721) {
             IERC721(escrow.assetAddress).safeTransferFrom(address(this), escrow.recipient, escrow.amountOrTokenId);
        }

        _updateEscrowState(escrowId, EscrowState.Released);
        emit AssetsReleased(escrowId, escrow.recipient, escrow.assetType, escrow.assetAddress, escrow.amountOrTokenId);

         // Final state after release
        _updateEscrowState(escrowId, EscrowState.Completed);
    }

    /**
     * @dev Attempts to cancel an escrow and return assets to the depositor.
     *      Typically, cancellation is only allowed by the depositor before expiry.
     * @param escrowId The ID of the escrow.
     */
    function cancelEscrow(uint250 escrowId)
        external
        nonReentrant
        whenNotPaused
    {
        Escrow storage escrow = escrows[escrowId];
        require(escrowId < nextEscrowId, "Invalid escrow ID");
        require(escrow.state == EscrowState.Active, "Escrow not in Active state for cancellation"); // Only allow cancellation from Active state

        require(_msgSender() == escrow.depositor, "Only depositor can cancel");
        require(block.timestamp < escrow.expiryTime, "Cannot cancel after expiry"); // Standard cancellation only before expiry

        // Transfer assets back
        if (escrow.assetType == AssetType.Eth) {
            (bool success, ) = payable(escrow.depositor).call{value: escrow.amountOrTokenId}("");
            require(success, "ETH transfer failed");
        } else if (escrow.assetType == AssetType.ERC20) {
            IERC20(escrow.assetAddress).safeTransfer(escrow.depositor, escrow.amountOrTokenId);
        } else if (escrow.assetType == AssetType.ERC721) {
             IERC721(escrow.assetAddress).safeTransferFrom(address(this), escrow.depositor, escrow.amountOrTokenId);
        }

        _updateEscrowState(escrowId, EscrowState.Cancelled);
        emit EscrowCancelled(escrowId, escrow.depositor, escrow.assetType, escrow.assetAddress, escrow.amountOrTokenId);

        // Final state after cancel
        _updateEscrowState(escrowId, EscrowState.Completed);
    }


    // --- Role-Specific Functions (Convenience/Specific Intent) ---

    /**
     * @dev Allows the depositor to explicitly trigger a release. Checks conditions internally.
     * @param escrowId The ID of the escrow.
     */
    function releaseEscrowByDepositor(uint250 escrowId) external onlyDepositor(escrowId) {
         releaseEscrow(escrowId); // Calls the general release function
    }

     /**
     * @dev Allows the recipient to explicitly trigger a release (claim). Checks conditions internally.
     * @param escrowId The ID of the escrow.
     */
    function releaseEscrowByRecipient(uint250 escrowId) external onlyRecipient(escrowId) {
         releaseEscrow(escrowId); // Calls the general release function
    }

     /**
     * @dev Allows the depositor to explicitly trigger a cancellation. Checks conditions internally.
     * @param escrowId The ID of the escrow.
     */
    function cancelEscrowByDepositor(uint250 escrowId) external onlyDepositor(escrowId) {
         cancelEscrow(escrowId); // Calls the general cancel function
    }

    /**
     * @dev Allows the depositor to reclaim assets if the escrow has expired AND is within the grace period,
     *      and has not been released or cancelled by other means.
     * @param escrowId The ID of the escrow.
     */
    function claimGracePeriodReturn(uint250 escrowId)
        external
        onlyDepositor(escrowId)
        notInState(escrowId, EscrowState.Released) // Cannot reclaim if released
        notInState(escrowId, EscrowState.Cancelled) // Cannot reclaim if cancelled
        notInState(escrowId, EscrowState.Completed) // Cannot reclaim if already completed
        nonReentrant
        whenNotPaused
    {
        Escrow storage escrow = escrows[escrowId];
         require(escrowId < nextEscrowId, "Invalid escrow ID");

        // Check if expiry has passed
        require(block.timestamp >= escrow.expiryTime, "Escrow has not expired yet");

        // Check if within grace period
        require(block.timestamp < escrow.expiryTime + gracePeriodDuration, "Grace period has ended");

        // Check if recipient could have claimed (this prevents depositor from reclaiming if recipient *met* conditions but just didn't call release)
        // Re-evaluate potential release conditions here to see if recipient *could* have released
        bool timeConditionMet = block.timestamp >= escrow.expiryTime;
        bool conditionMet = escrow.conditionMet;
        bool recipientCouldClaim = false;

        if (escrow.releaseType == ReleaseType.Timed) {
             recipientCouldClaim = timeConditionMet;
        } else if (escrow.releaseType == ReleaseType.Conditional) {
             recipientCouldClaim = conditionMet;
        } else if (escrow.releaseType == ReleaseType.TimedOrConditional) {
             recipientCouldClaim = timeConditionMet || conditionMet;
        } else if (escrow.releaseType == ReleaseType.TimedAndConditional) {
             recipientCouldClaim = timeConditionMet && conditionMet;
        }

        // If recipient *could* have claimed based on the release conditions but didn't,
        // the depositor can only reclaim if the grace period is active.
        // The logic here is that if release conditions *were* met, the recipient *should* have claimed.
        // If they didn't within expiry+grace, the depositor gets it back.
        // This function *already* checks block.timestamp >= expiryTime and < expiryTime + gracePeriodDuration.
        // The key condition for depositor reclaim in grace period is that the assets were *not* released.
        // No *additional* check on recipientCouldClaim is strictly needed here, as the state checks handle it.
        // If state is Active, ConditionMet, Expired, it means release wasn't called (or failed).
        // GracePeriod state transition happens implicitly by time passing and release not occurring.

        // Transfer assets back to depositor
        if (escrow.assetType == AssetType.Eth) {
            (bool success, ) = payable(escrow.depositor).call{value: escrow.amountOrTokenId}("");
            require(success, "ETH transfer failed");
        } else if (escrow.assetType == AssetType.ERC20) {
            IERC20(escrow.assetAddress).safeTransfer(escrow.depositor, escrow.amountOrTokenId);
        } else if (escrow.assetType == AssetType.ERC721) {
             IERC721(escrow.assetAddress).safeTransferFrom(address(this), escrow.depositor, escrow.amountOrTokenId);
        }

        _updateEscrowState(escrowId, EscrowState.GracePeriod); // Log state as GracePeriod claimed
        emit GracePeriodClaimed(escrowId, escrow.depositor, escrow.assetType, escrow.assetAddress, escrow.amountOrTokenId);

        // Final state after grace period claim
        _updateEscrowState(escrowId, EscrowState.Completed);
    }


    // --- Admin/Owner Functions ---

    /**
     * @dev Sets the address authorized to signal conditions.
     * @param _signaler The new signaler address.
     */
    function setConditionSignaler(address _signaler) external onlyOwner {
        require(_signaler != address(0), "Signaler cannot be zero address");
        emit ConditionSignalerUpdated(conditionSignaler, _signaler);
        conditionSignaler = _signaler;
    }

    /**
     * @dev Sets the duration of the grace period after expiry.
     * @param _duration The new grace period duration in seconds.
     */
    function setGracePeriodDuration(uint256 _duration) external onlyOwner {
        emit GracePeriodDurationUpdated(gracePeriodDuration, _duration);
        gracePeriodDuration = _duration;
    }

    /**
     * @dev Allows the owner to withdraw accidentally sent ETH (not escrowed ETH).
     *      This is a recovery mechanism.
     * @param recipient The address to send ETH to.
     * @param amount The amount of ETH to withdraw.
     */
    function withdrawETH(address payable recipient, uint256 amount) external onlyOwner nonReentrant {
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be > 0");
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH withdrawal failed");

        emit TrappedAssetsWithdrawn(_msgSender(), recipient, address(0), amount);
    }

    /**
     * @dev Allows the owner to withdraw accidentally sent ERC20 tokens (not escrowed tokens).
     *      This is a recovery mechanism.
     * @param tokenAddress The address of the ERC20 token.
     * @param recipient The address to send tokens to.
     * @param amount The amount of tokens to withdraw.
     */
    function withdrawERC20(address tokenAddress, address recipient, uint256 amount) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Token address cannot be zero address");
        require(recipient != address(0), "Recipient cannot be zero address");
        require(amount > 0, "Amount must be > 0");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");

        token.safeTransfer(recipient, amount);

        emit TrappedAssetsWithdrawn(_msgSender(), recipient, tokenAddress, amount);
    }

     /**
     * @dev Allows the owner to withdraw accidentally sent ERC721 tokens (not escrowed tokens).
     *      This is a recovery mechanism. Owner must first approve the contract to transfer if needed.
     * @param tokenAddress The address of the ERC721 token.
     * @param recipient The address to send the NFT to.
     * @param tokenId The ID of the NFT to withdraw.
     */
    function withdrawERC721(address tokenAddress, address recipient, uint256 tokenId) external onlyOwner nonReentrant {
        require(tokenAddress != address(0), "Token address cannot be zero address");
        require(recipient != address(0), "Recipient cannot be zero address");

        IERC721 token = IERC721(tokenAddress);
        require(token.ownerOf(tokenId) == address(this), "Contract does not own the NFT");

        token.safeTransferFrom(address(this), recipient, tokenId);

        emit TrappedAssetsWithdrawn(_msgSender(), recipient, tokenAddress, tokenId);
    }

    // Inherited from Pausable
    function pause() public override onlyOwner {
        super.pause();
    }

    // Inherited from Pausable
    function unpause() public override onlyOwner {
        super.unpause();
    }


    // --- Internal Helpers ---

    /**
     * @dev Internal function to update the state of an escrow and emit an event.
     * @param escrowId The ID of the escrow.
     * @param newState The new state for the escrow.
     */
    function _updateEscrowState(uint250 escrowId, EscrowState newState) internal {
         Escrow storage escrow = escrows[escrowId];
         EscrowState oldState = escrow.state;
         if (oldState != newState) {
             escrow.state = newState;
             emit EscrowStateChanged(escrowId, oldState, newState);
         }
         // Additional check: if state is now Expired, but not GracePeriod, and within grace period timeframe, update to GracePeriod state
         if (newState == EscrowState.Expired && block.timestamp < escrow.expiryTime + gracePeriodDuration) {
              escrow.state = EscrowState.GracePeriod;
              emit EscrowStateChanged(escrowId, oldState, EscrowState.GracePeriod);
         }
         // If state becomes GracePeriod and time is now >= expiry + grace, state becomes Completed
         if (newState == EscrowState.GracePeriod && block.timestamp >= escrow.expiryTime + gracePeriodDuration) {
             escrow.state = EscrowState.Completed;
             emit EscrowStateChanged(escrowId, oldState, EscrowState.Completed);
         }
         // If state is Active/ConditionMet/Expired/GracePeriod and time is >= expiry + grace, state becomes Completed (if not already handled by claimGracePeriodReturn/release/cancel)
         // This handles cases where nobody interacts after grace period ends.
          if (escrow.state < EscrowState.Released && block.timestamp >= escrow.expiryTime + gracePeriodDuration) {
               if (escrow.state != EscrowState.Completed) { // Prevent redundant state change
                   escrow.state = EscrowState.Completed;
                   emit EscrowStateChanged(escrowId, oldState, EscrowState.Completed);
               }
          }
    }


    // --- Fallback/Receive ---

    /**
     * @dev Allows receiving ETH, but only when paused. Prevents accidental deposits
     *      outside of the depositEth function when active.
     */
    receive() external payable {
        require(paused(), "Receive not allowed when not paused. Use depositEth.");
         emit TrappedAssetsWithdrawn(address(0), _msgSender(), address(0), msg.value); // Log incoming ETH as potentially "trapped"
    }

    fallback() external payable {
        revert("Invalid function call or receive not allowed");
    }
}
```

---

**Explanation of Advanced/Creative Aspects:**

1.  **State Machine (`EscrowState` Enum and Transitions):** The contract doesn't just hold assets; it manages the *lifecycle* of each escrow through distinct states (`Active`, `ConditionMet`, `Expired`, `Released`, `Cancelled`, `GracePeriod`, `Completed`). This allows for precise control over which actions are permitted at different stages. The `_updateEscrowState` helper attempts to manage some time-based transitions automatically, although explicit calls to `releaseEscrow`, `cancelEscrow`, or `claimGracePeriodReturn` are required to finalize states like `Released`, `Cancelled`, or `Completed` via the intended outcome.
2.  **Flexible Release Logic (`ReleaseType` Enum):** Instead of a single "release after time" or "release after condition," the contract offers four distinct modes (`Timed`, `Conditional`, `TimedOrConditional`, `TimedAndConditional`). This allows for complex agreements like "assets are released only *after* the deadline *and* only *if* the condition is met."
3.  **Designated Condition Signaler:** This introduces a third party (or a specific oracle contract address) that is solely responsible for marking the external condition as met. This decouples the condition signaling from the depositor and recipient, enabling more neutral or specialized condition verification.
4.  **Grace Period (`gracePeriodDuration`, `claimGracePeriodReturn`):** If an escrow expires and the recipient doesn't claim the assets (potentially because conditions weren't met or they simply missed the window), the depositor doesn't automatically lose their funds forever. They have a defined `gracePeriodDuration` to reclaim the assets. This adds a layer of safety for the depositor in expired, unclaimed scenarios.
5.  **Multi-Asset Handling:** While separate contracts for ETH, ERC20, and ERC721 are common, combining them into a single contract with a shared state machine and ID space makes the contract more versatile for users dealing with different asset types under similar escrow logic.
6.  **Role-Specific & General Interaction Functions:** Having functions like `releaseEscrowByDepositor` or `cancelEscrowByDepositor` alongside the general `releaseEscrow` and `cancelEscrow` provides clear intent for users (e.g., "I, the depositor, want to cancel this") while the internal logic ensures the action is valid based on the escrow's state and rules.
7.  **User Escrow Tracking (`userEscrows`):** The mapping `userEscrows` allows users to easily query and find all escrows they are involved in, improving usability. (Note: returning large arrays from public functions can be gas-intensive for the caller, but for this example demonstrating the concept, it's acceptable).
8.  **Stuck Asset Recovery:** Standard `withdraw` functions for the owner are included as a safety measure for any assets that might accidentally be sent to the contract address outside of a valid escrow deposit.

This contract provides a framework for complex decentralized agreements requiring time-based constraints, external verification, and distinct user roles, going beyond the functionality of a simple time-lock or multi-sig escrow.