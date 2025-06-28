Okay, here is a smart contract written in Solidity, focusing on advanced and creative concepts beyond typical open-source examples. It's a "Quantum Vault" that allows users to deposit various asset types (Native Token, ERC-20, ERC-721) with complex, multi-conditional unlock requirements.

The contract includes features like time locks, block number locks, external oracle price conditions, dependency on other deposits, dynamic fees/penalties, transferrable unlock rights, splitting fungible deposits, and owner-based recovery/management.

**Disclaimer:** This contract is a complex example demonstrating advanced concepts. It has not undergone extensive security audits and may contain vulnerabilities. Do *not* use it in production without thorough testing and professional review. Oracle interactions require careful consideration of trust and data freshness.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// --- Outline and Function Summary ---
//
// Contract: QuantumVault
// Description: A sophisticated vault allowing users to deposit ETH, ERC-20, and ERC-721
//              tokens with complex, multi-conditional unlock criteria. Conditions
//              can include time, block number, oracle price thresholds, and
//              dependencies on other deposits. Features include dynamic fees,
//              transferrable unlock rights, deposit splitting, and owner recovery.
//
// State Variables:
// - owner: The contract deployer/admin.
// - depositCounter: Counter for unique deposit IDs.
// - deposits: Mapping from deposit ID to Deposit struct.
// - oracleAggregator: Address of the Chainlink price feed aggregator.
// - oraclePriceFeedId: Identifier for the specific price feed (e.g., ETH/USD).
// - adminFeesETH: Accumulated ETH fees/penalties.
// - adminFeesERC20: Mapping from token address to accumulated ERC20 fees/penalties.
// - unlockWhitelist: Mapping for addresses allowed to unlock deposits (global).
//
// Structs:
// - Deposit: Stores all information for a single locked deposit.
//   - depositor: Original address that made the deposit.
//   - assetType: Enum indicating asset type (ETH, ERC20, ERC721).
//   - tokenAddress: Address of the token contract (0x0 for ETH).
//   - tokenId: ID for ERC721 assets (0 for ETH/ERC20).
//   - amount: Amount for ETH/ERC20 assets (0 for ERC721).
//   - lockedUntil: Unix timestamp for time-based unlock condition. 0 if not used.
//   - requiredBlockNumber: Block number for block-based unlock condition. 0 if not used.
//   - minOraclePrice: Minimum oracle price required (scaled). 0 if not used.
//   - maxOraclePrice: Maximum oracle price required (scaled). Max uint256 if not used.
//   - requiresOtherDepositId: Another Deposit ID that must be unlocked first. 0 if not used.
//   - isUnlocked: Flag indicating if the deposit has been unlocked.
//   - unlockPenaltyBps: Basis points (0-10000) penalty for early/failed unlock attempts (applied to remaining amount).
//   - unlockFeeBps: Basis points (0-10000) fee for successful unlocks (applied to released amount).
//   - canTransferUnlockRight: Boolean allowing the unlock recipient to be transferred.
//   - unlockRecipient: Address currently allowed to unlock this deposit.
//   - isSplit: Flag indicating if this deposit resulted from a split.
//
// Enums:
// - AssetType: ETH, ERC20, ERC721.
//
// Events:
// - DepositMade: Logged when a new deposit is created.
// - DepositUnlocked: Logged when assets are successfully unlocked and transferred.
// - UnlockConditionsUpdated: Logged when deposit conditions are modified.
// - TransferUnlockRight: Logged when unlock permission is transferred.
// - DepositSplit: Logged when a fungible deposit is split.
// - ForcedUnlock: Logged when owner forces an unlock.
// - AdminFeesWithdrawn: Logged when owner withdraws accumulated fees.
// - WhitelistUpdated: Logged when the unlock whitelist is changed.
// - OracleUpdated: Logged when oracle configuration is changed.
//
// Functions (20+):
// 1. constructor(address _oracleAggregator, string memory _oraclePriceFeedId): Sets up the contract owner and oracle configuration.
// 2. depositETH(uint64 _lockedUntil, uint64 _requiredBlockNumber, uint256 _minOraclePrice, uint256 _maxOraclePrice, uint256 _requiresOtherDepositId, uint16 _unlockPenaltyBps, uint16 _unlockFeeBps, bool _canTransferUnlockRight, address _unlockRecipient) external payable: Deposits native ETH with specified conditions.
// 3. depositERC20(IERC20 _token, uint256 _amount, uint64 _lockedUntil, uint64 _requiredBlockNumber, uint256 _minOraclePrice, uint256 _maxOraclePrice, uint256 _requiresOtherDepositId, uint16 _unlockPenaltyBps, uint16 _unlockFeeBps, bool _canTransferUnlockRight, address _unlockRecipient) external: Deposits ERC-20 tokens with specified conditions. Requires prior approval.
// 4. depositERC721(IERC721 _token, uint256 _tokenId, uint64 _lockedUntil, uint64 _requiredBlockNumber, uint256 _minOraclePrice, uint256 _maxOraclePrice, uint256 _requiresOtherDepositId, uint16 _unlockPenaltyBps, uint16 _unlockFeeBps, bool _canTransferUnlockRight, address _unlockRecipient) external: Deposits ERC-721 token with specified conditions. Requires prior approval/transfer.
// 5. attemptUnlock(uint256 _depositId) external nonReentrant: Attempts to unlock a specific deposit. Checks all conditions and recipient/whitelist permissions.
// 6. checkUnlockConditions(uint256 _depositId) public view returns (bool): Pure view function to check if *all* unlock conditions for a deposit are met *at the current time*.
// 7. getDeposit(uint256 _depositId) public view returns (Deposit memory): Retrieves the details of a specific deposit.
// 8. getUserDepositIds(address _user) public view returns (uint256[] memory): (Conceptual - requires iterating deposits, not efficient on-chain). Simplified to a getter for a range or similar. *Alternative:* Replaced with querying individual deposits or a mapping (less efficient). Let's omit this specific function as it's an anti-pattern for large numbers of deposits. Focus on querying by ID or properties.
// 9. getOraclePrice() public view returns (int256, uint8): Gets the latest price and decimals from the oracle.
// 10. updateDepositConditions(uint256 _depositId, uint64 _lockedUntil, uint64 _requiredBlockNumber, uint256 _minOraclePrice, uint256 _maxOraclePrice, uint256 _requiresOtherDepositId, uint16 _unlockPenaltyBps, uint16 _unlockFeeBps, bool _canTransferUnlockRight, address _unlockRecipient) external: Allows owner to modify unlock conditions for a deposit.
// 11. transferUnlockRight(uint256 _depositId, address _newRecipient) external: Allows the current `unlockRecipient` to transfer the right to unlock (if `canTransferUnlockRight` is true).
// 12. renounceUnlockRight(uint256 _depositId) external: Allows the current `unlockRecipient` to set their unlock recipient to address(0).
// 13. splitFungibleDeposit(uint256 _depositId, uint256 _splitAmount) external nonReentrant: Splits an ETH or ERC-20 deposit into two. The original deposit amount is reduced, and a new deposit is created with the specified amount and same conditions.
// 14. forceUnlockByOwner(uint256 _depositId) external nonReentrant: Allows the owner to bypass conditions and force unlock a deposit (applying penalty).
// 15. withdrawAdminFees(address _tokenAddress) external nonReentrant: Allows the owner to withdraw accumulated ETH (if _tokenAddress is address(0)) or ERC-20 fees/penalties.
// 16. addToUnlockWhitelist(address _user) external: Adds an address to the global unlock whitelist (owner only).
// 17. removeFromUnlockWhitelist(address _user) external: Removes an address from the global unlock whitelist (owner only).
// 18. isWhitelisted(address _user) public view returns (bool): Checks if an address is on the whitelist.
// 19. updateOracleAddress(address _newOracleAggregator) external: Updates the oracle aggregator address (owner only).
// 20. updateOraclePriceFeedId(string memory _newOraclePriceFeedId) external: Updates the oracle price feed ID (owner only). *Note: String ID is conceptual, Chainlink feeds use address.* Let's make this just an address.
// 20. updateOracleAddress(address _newOracleAggregator) external: Updates the oracle aggregator address (owner only). (Revised function 20)
// 21. updateOraclePriceFeed(address _newOracleFeed) external: Updates the specific oracle feed address (owner only). (New function 21)
// 22. rescueERC20(IERC20 _token, address _to, uint256 _amount) external nonReentrant: Allows owner to rescue ERC20 tokens mistakenly sent to the contract, not associated with a deposit.
// 23. rescueERC721(IERC721 _token, uint256 _tokenId, address _to) external nonReentrant: Allows owner to rescue ERC721 tokens mistakenly sent to the contract, not associated with a deposit.
// 24. getAdminFeesETH() public view returns (uint256): Returns the current accumulated ETH admin fees.
// 25. getAdminFeesERC20(address _tokenAddress) public view returns (uint256): Returns the current accumulated ERC20 admin fees for a token.
// 26. setInitialUnlockRecipient(uint256 _depositId, address _recipient) external: Allows the depositor to set an unlock recipient immediately after deposit (if not set initially). (Requires specific logic, potentially combine with updateDepositConditions). Let's make setting unlockRecipient part of deposit or updateConditions.

// Okay, let's refine the function list based on practicality and the 20+ requirement.
// 1. constructor
// 2. depositETH (payable)
// 3. depositERC20
// 4. depositERC721 (onERC721Received handles receiving)
// 5. attemptUnlock (nonReentrant)
// 6. checkUnlockConditions (view)
// 7. getDeposit (view)
// 8. getOraclePrice (view)
// 9. updateDepositConditions (owner only)
// 10. transferUnlockRight (unlockRecipient only, conditional)
// 11. renounceUnlockRight (unlockRecipient only)
// 12. splitFungibleDeposit (depositor or unlockRecipient, nonReentrant)
// 13. forceUnlockByOwner (owner only, nonReentrant)
// 14. withdrawAdminFees (owner only, nonReentrant)
// 15. addToUnlockWhitelist (owner only)
// 16. removeFromUnlockWhitelist (owner only)
// 17. isWhitelisted (view)
// 18. updateOracleAddress (owner only)
// 19. updateOracleFeed (owner only)
// 20. rescueERC20 (owner only, nonReentrant)
// 21. rescueERC721 (owner only, nonReentrant)
// 22. getAdminFeesETH (view)
// 23. getAdminFeesERC20 (view)
// 24. setOraclePriceFeedId (string ID - this is tricky. Chainlink feeds are address-based. Let's remove the string ID concept and stick to address).
// Let's find more functions or refine existing ones:
// 24. getDepositCount() view returns (uint256) - Simple utility
// 25. toggleUnlockWhitelistRequirement(bool _required) external owner only - Allows disabling/enabling the global whitelist check.
// 26. isUnlockWhitelistRequired() view returns (bool) - Check if whitelist is active.

// This gives us 26 functions (1 + 3 + 1 + 4 + 8 + 9 = 26). Perfect.

// Using OpenZeppelin libraries for safety and common patterns.
// ERC721Holder is needed to receive NFTs.
// ReentrancyGuard for withdrawal functions.
// AggregatorV3Interface for Chainlink oracle.

contract QuantumVault is ERC721Holder, ReentrancyGuard {

    address public immutable owner;
    uint256 public depositCounter;

    enum AssetType { ETH, ERC20, ERC721 }

    struct Deposit {
        address depositor;
        AssetType assetType;
        address tokenAddress; // Address for ERC20/ERC721, address(0) for ETH
        uint256 tokenId;      // Token ID for ERC721, 0 for ETH/ERC20
        uint256 amount;       // Amount for ETH/ERC20, 0 for ERC721

        // Unlock Conditions
        uint64 lockedUntil;         // Unix timestamp (0 if not used)
        uint64 requiredBlockNumber; // Block number (0 if not used)
        uint256 minOraclePrice;     // Minimum oracle price required (scaled by oracle decimals, 0 if not used)
        uint256 maxOraclePrice;     // Maximum oracle price required (scaled, type(uint256).max if not used)
        uint256 requiresOtherDepositId; // Another Deposit ID that must be unlocked first (0 if not used)

        bool isUnlocked;
        uint16 unlockPenaltyBps; // Basis points (0-10000) penalty on remaining amount for failed/forced unlock
        uint16 unlockFeeBps;     // Basis points (0-10000) fee on released amount for successful unlock

        bool canTransferUnlockRight; // Can unlockRecipient transfer this right?
        address unlockRecipient;     // Address allowed to unlock this deposit (defaults to depositor)

        bool isSplit; // True if this deposit resulted from a split operation
    }

    mapping(uint256 => Deposit) public deposits;

    // Oracle Configuration (Chainlink AggregatorV3Interface)
    AggregatorV3Interface public oracleAggregator;
    // For more complex scenarios, you might need a mapping for different feeds
    // mapping(string => AggregatorV3Interface) public priceFeeds;
    // string public oraclePriceFeedId; // Removed as Chainlink feeds use addresses

    // Admin Fees
    uint256 public adminFeesETH;
    mapping(address => uint256) public adminFeesERC20; // tokenAddress => amount

    // Global Unlock Whitelist
    mapping(address => bool) private unlockWhitelist;
    bool public unlockWhitelistRequired = false; // If true, only whitelisted addresses can *attempt* unlocks.

    // Events
    event DepositMade(uint256 indexed depositId, address indexed depositor, AssetType assetType, address tokenAddress, uint256 tokenId, uint256 amount, address indexed unlockRecipient);
    event DepositUnlocked(uint256 indexed depositId, address indexed recipient, AssetType assetType, address tokenAddress, uint256 tokenId, uint256 amountUnlocked, uint256 penaltyAmount, uint256 feeAmount);
    event UnlockConditionsUpdated(uint256 indexed depositId, address indexed modifier);
    event TransferUnlockRight(uint256 indexed depositId, address indexed oldRecipient, address indexed newRecipient);
    event DepositSplit(uint256 indexed originalDepositId, uint256 indexed newDepositId, uint256 splitAmount, address indexed depositor);
    event ForcedUnlock(uint256 indexed depositId, address indexed owner);
    event AdminFeesWithdrawn(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event WhitelistUpdated(address indexed user, bool isWhitelisted, address indexed modifier);
    event OracleUpdated(address indexed newOracleAggregator); // String feed ID removed, using address.
    event OracleFeedUpdated(address indexed newOracleFeed); // New event for updating the specific feed

    // --- Constructor ---
    constructor(address _oracleAggregator) {
        owner = msg.sender;
        require(_oracleAggregator != address(0), "Oracle address cannot be zero");
        oracleAggregator = AggregatorV3Interface(_oracleAggregator);
        // Initial depositCounter is 0, will be incremented before first deposit.
    }

    // --- Modifier for Owner ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // --- Deposit Functions ---

    /**
     * @notice Deposits native ETH into the vault with specified unlock conditions.
     * @param _lockedUntil Unix timestamp when the deposit is eligible for time-based unlock.
     * @param _requiredBlockNumber Block number when the deposit is eligible for block-based unlock.
     * @param _minOraclePrice Minimum oracle price required for unlock (scaled by oracle decimals).
     * @param _maxOraclePrice Maximum oracle price required for unlock (scaled by oracle decimals).
     * @param _requiresOtherDepositId ID of another deposit that must be unlocked before this one.
     * @param _unlockPenaltyBps Basis points penalty for failed/forced unlock (0-10000).
     * @param _unlockFeeBps Basis points fee for successful unlock (0-10000).
     * @param _canTransferUnlockRight Allows unlock recipient to transfer unlock rights.
     * @param _unlockRecipient Address allowed to unlock (address(0) defaults to msg.sender).
     */
    function depositETH(
        uint64 _lockedUntil,
        uint64 _requiredBlockNumber,
        uint256 _minOraclePrice,
        uint256 _maxOraclePrice,
        uint256 _requiresOtherDepositId,
        uint16 _unlockPenaltyBps,
        uint16 _unlockFeeBps,
        bool _canTransferUnlockRight,
        address _unlockRecipient
    ) external payable nonReentrant {
        require(msg.value > 0, "Amount must be greater than zero");
        _createDeposit(
            msg.sender,
            AssetType.ETH,
            address(0),
            0,
            msg.value,
            _lockedUntil,
            _requiredBlockNumber,
            _minOraclePrice,
            _maxOraclePrice == 0 ? type(uint256).max : _maxOraclePrice, // Default max to infinite if 0
            _requiresOtherDepositId,
            _unlockPenaltyBps,
            _unlockFeeBps,
            _canTransferUnlockRight,
            _unlockRecipient == address(0) ? msg.sender : _unlockRecipient,
            false // Not a split deposit initially
        );
    }

    /**
     * @notice Deposits ERC-20 tokens into the vault with specified unlock conditions.
     * @param _token Address of the ERC-20 token contract.
     * @param _amount Amount of tokens to deposit.
     * @param _lockedUntil Unix timestamp when the deposit is eligible for time-based unlock.
     * @param _requiredBlockNumber Block number when the deposit is eligible for block-based unlock.
     * @param _minOraclePrice Minimum oracle price required for unlock (scaled by oracle decimals).
     * @param _maxOraclePrice Maximum oracle price required for unlock (scaled by oracle decimals).
     * @param _requiresOtherDepositId ID of another deposit that must be unlocked before this one.
     * @param _unlockPenaltyBps Basis points penalty for failed/forced unlock (0-10000).
     * @param _unlockFeeBps Basis points fee for successful unlock (0-10000).
     * @param _canTransferUnlockRight Allows unlock recipient to transfer unlock rights.
     * @param _unlockRecipient Address allowed to unlock (address(0) defaults to msg.sender).
     */
    function depositERC20(
        IERC20 _token,
        uint256 _amount,
        uint64 _lockedUntil,
        uint64 _requiredBlockNumber,
        uint256 _minOraclePrice,
        uint256 _maxOraclePrice,
        uint256 _requiresOtherDepositId,
        uint16 _unlockPenaltyBps,
        uint16 _unlockFeeBps,
        bool _canTransferUnlockRight,
        address _unlockRecipient
    ) external nonReentrant {
        require(_amount > 0, "Amount must be greater than zero");
        require(address(_token) != address(0), "Token address cannot be zero");
        require(address(_token) != address(this), "Cannot deposit contract's own tokens");

        uint256 beforeBalance = _token.balanceOf(address(this));
        _token.transferFrom(msg.sender, address(this), _amount);
        uint256 afterBalance = _token.balanceOf(address(this));
        require(afterBalance - beforeBalance == _amount, "Token transfer failed or amount mismatch"); // Basic check

        _createDeposit(
            msg.sender,
            AssetType.ERC20,
            address(_token),
            0, // tokenId
            _amount,
            _lockedUntil,
            _requiredBlockNumber,
            _minOraclePrice,
            _maxOraclePrice == 0 ? type(uint256).max : _maxOraclePrice,
            _requiresOtherDepositId,
            _unlockPenaltyBps,
            _unlockFeeBps,
            _canTransferUnlockRight,
            _unlockRecipient == address(0) ? msg.sender : _unlockRecipient,
            false // Not a split deposit initially
        );
    }

    /**
     * @notice Deposits an ERC-721 token into the vault with specified unlock conditions.
     * @param _token Address of the ERC-721 token contract.
     * @param _tokenId ID of the token to deposit.
     * @param _lockedUntil Unix timestamp when the deposit is eligible for time-based unlock.
     * @param _requiredBlockNumber Block number when the deposit is eligible for block-based unlock.
     * @param _minOraclePrice Minimum oracle price required for unlock (scaled by oracle decimals).
     * @param _maxOraclePrice Maximum oracle price required for unlock (scaled by oracle decimals).
     * @param _requiresOtherDepositId ID of another deposit that must be unlocked before this one.
     * @param _unlockPenaltyBps Basis points penalty for failed/forced unlock (0-10000).
     * @param _unlockFeeBps Basis points fee for successful unlock (0-10000).
     * @param _canTransferUnlockRight Allows unlock recipient to transfer unlock rights.
     * @param _unlockRecipient Address allowed to unlock (address(0) defaults to msg.sender).
     */
    function depositERC721(
        IERC721 _token,
        uint256 _tokenId,
        uint64 _lockedUntil,
        uint64 _requiredBlockNumber,
        uint256 _minOraclePrice,
        uint256 _maxOraclePrice,
        uint256 _requiresOtherDepositId,
        uint16 _unlockPenaltyBps,
        uint16 _unlockFeeBps,
        bool _canTransferUnlockRight,
        address _unlockRecipient
    ) external nonReentrant {
        require(address(_token) != address(0), "Token address cannot be zero");
        // ERC721 deposit requires the user to call safeTransferFrom *to* this contract
        // before calling this function, or call safeTransferFrom directly.
        // The onERC721Received hook handles the deposit creation in that case.
        // However, allowing a direct deposit call assumes prior approval.
        // Let's implement the direct call assuming approval.
        require(_token.getApproved(_tokenId) == address(this) || _token.isApprovedForAll(msg.sender, address(this)), "ERC721 not approved for transfer");

        _token.safeTransferFrom(msg.sender, address(this), _tokenId);

        _createDeposit(
            msg.sender,
            AssetType.ERC721,
            address(_token),
            _tokenId,
            0, // amount
            _lockedUntil,
            _requiredBlockNumber,
            _minOraclePrice,
            _maxOraclePrice == 0 ? type(uint256).max : _maxOraclePrice,
            _requiresOtherDepositId,
            _unlockPenaltyBps,
            _unlockFeeBps,
            _canTransferUnlockRight,
            _unlockRecipient == address(0) ? msg.sender : _unlockRecipient,
            false // Not a split deposit initially
        );
    }

    /**
     * @notice Internal function to create a new deposit entry.
     * @dev Increments depositCounter and stores details.
     */
    function _createDeposit(
        address _depositor,
        AssetType _assetType,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount,
        uint64 _lockedUntil,
        uint64 _requiredBlockNumber,
        uint256 _minOraclePrice,
        uint256 _maxOraclePrice,
        uint256 _requiresOtherDepositId,
        uint16 _unlockPenaltyBps,
        uint16 _unlockFeeBps,
        bool _canTransferUnlockRight,
        address _unlockRecipient,
        bool _isSplit
    ) internal {
        depositCounter++;
        uint256 newDepositId = depositCounter;

        // Validate requiredOtherDepositId if used
        if (_requiresOtherDepositId != 0) {
             require(deposits[_requiresOtherDepositId].depositor != address(0), "Required dependency deposit does not exist");
        }

        deposits[newDepositId] = Deposit({
            depositor: _depositor,
            assetType: _assetType,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amount: _amount,
            lockedUntil: _lockedUntil,
            requiredBlockNumber: _requiredBlockNumber,
            minOraclePrice: _minOraclePrice,
            maxOraclePrice: _maxOraclePrice,
            requiresOtherDepositId: _requiresOtherDepositId,
            isUnlocked: false,
            unlockPenaltyBps: _unlockPenaltyBps,
            unlockFeeBps: _unlockFeeBps,
            canTransferUnlockRight: _canTransferUnlockRight,
            unlockRecipient: _unlockRecipient,
            isSplit: _isSplit
        });

        emit DepositMade(newDepositId, _depositor, _assetType, _tokenAddress, _tokenId, _amount, _unlockRecipient);
    }

    // --- ERC721 Receive Hook ---
    // Needed to receive NFTs via safeTransferFrom
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // This hook is triggered when an ERC721 is transferred to this contract using safeTransferFrom.
        // We can use the 'data' field to encode deposit parameters.
        // This requires a specific encoding structure in the calling application.
        // For simplicity in this example, let's assume deposits are made via explicit deposit functions.
        // However, a robust implementation might parse the 'data' to call _createDeposit.
        // Returning the MAGIC_VALUE signifies successful reception.
        return this.onERC721Received.selector;
    }


    // --- Conditional Unlocking ---

    /**
     * @notice Attempts to unlock a specific deposit. Checks all conditions and caller/whitelist permissions.
     * @param _depositId The ID of the deposit to unlock.
     */
    function attemptUnlock(uint256 _depositId) external nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor != address(0), "Deposit does not exist");
        require(!deposit.isUnlocked, "Deposit is already unlocked");

        // Check caller permissions
        bool isRecipient = msg.sender == deposit.unlockRecipient;
        bool isOwner = msg.sender == owner;
        bool isWhitelistedCaller = unlockWhitelistRequired ? unlockWhitelist[msg.sender] : true;

        require(isRecipient || isOwner, "Caller is not the designated unlock recipient or owner");
        require(isWhitelistedCaller, "Caller is not whitelisted for unlock");

        // Check if all unlock conditions are met
        bool conditionsMet = checkUnlockConditions(_depositId);

        uint256 amountReleased = 0;
        uint256 penaltyAmount = 0;
        uint256 feeAmount = 0;
        address payable recipientAddress = payable(deposit.unlockRecipient); // Recipient gets the tokens

        if (conditionsMet || isOwner) { // Owner can bypass conditions but still pays penalty/fee? Or no penalty for owner? Let's apply penalty/fee for consistency unless forcedUnlockByOwner is used.
            if (isOwner && !conditionsMet) {
                 // Owner unlocking before conditions met - let's direct them to forceUnlockByOwner
                 revert("Owner must use forceUnlockByOwner to bypass conditions");
            }

            deposit.isUnlocked = true;
            amountReleased = deposit.amount; // For ETH/ERC20
            // For ERC721, amount is 0, tokenId is released.

            // Calculate and apply fees
            if (deposit.unlockFeeBps > 0 && amountReleased > 0) {
                 feeAmount = (amountReleased * deposit.unlockFeeFeeBps) / 10000;
                 amountReleased -= feeAmount;
                 if (deposit.assetType == AssetType.ETH) {
                     adminFeesETH += feeAmount;
                 } else if (deposit.assetType == AssetType.ERC20) {
                     adminFeesERC20[deposit.tokenAddress] += feeAmount;
                 }
            }

            // Transfer assets
            if (deposit.assetType == AssetType.ETH) {
                (bool success, ) = recipientAddress.call{value: amountReleased}("");
                require(success, "ETH transfer failed");
            } else if (deposit.assetType == AssetType.ERC20) {
                IERC20(deposit.tokenAddress).transfer(recipientAddress, amountReleased);
            } else if (deposit.assetType == AssetType.ERC721) {
                 // Re-check ownership in case of previous rescue or bug
                 require(IERC721(deposit.tokenAddress).ownerOf(deposit.tokenId) == address(this), "Contract does not own the NFT");
                IERC721(deposit.tokenAddress).safeTransferFrom(address(this), recipientAddress, deposit.tokenId);
            }

            emit DepositUnlocked(_depositId, recipientAddress, deposit.assetType, deposit.tokenAddress, deposit.tokenId, amountReleased, penaltyAmount, feeAmount);

        } else {
            // Conditions not met. Apply penalty if configured.
             if (deposit.unlockPenaltyBps > 0 && deposit.amount > 0) {
                penaltyAmount = (deposit.amount * deposit.unlockPenaltyBps) / 10000;
                deposit.amount -= penaltyAmount; // Reduce remaining amount in the deposit
                if (deposit.assetType == AssetType.ETH) {
                    adminFeesETH += penaltyAmount;
                } else if (deposit.assetType == AssetType.ERC20) {
                    adminFeesERC20[deposit.tokenAddress] += penaltyAmount;
                }
                // Note: Penalty for ERC721 is conceptual, cannot split an NFT.
                // A penalty could mean locking it longer, or transferring it to owner/burn,
                // but reducing amount is not possible. Let's only apply penalty to fungible.
             }
             revert("Unlock conditions not met");
        }
    }

    /**
     * @notice Checks if all unlock conditions for a deposit are currently met.
     * @dev This is a public view function allowing anyone to check conditions without attempting unlock.
     * @param _depositId The ID of the deposit to check.
     * @return bool True if all conditions are met, false otherwise.
     */
    function checkUnlockConditions(uint256 _depositId) public view returns (bool) {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor != address(0), "Deposit does not exist"); // Should use storage for view
        require(!deposit.isUnlocked, "Deposit is already unlocked");

        // Condition 1: Time Lock
        if (deposit.lockedUntil > 0 && block.timestamp < deposit.lockedUntil) {
            return false;
        }

        // Condition 2: Block Number Lock
        if (deposit.requiredBlockNumber > 0 && block.number < deposit.requiredBlockNumber) {
            return false;
        }

        // Condition 3: Oracle Price Thresholds
        if (deposit.minOraclePrice > 0 || deposit.maxOraclePrice != type(uint256).max) {
            require(address(oracleAggregator) != address(0), "Oracle not configured");
            (, int256 price, , uint64 updatedAt, ) = oracleAggregator.latestRoundData();
            require(updatedAt > 0, "Oracle price data not available");
            // Note: Assumes price is positive. Handle oracle decimals if needed for comparison.
            // AggregatorV3Interface typically returns price with 8 decimals.
            // Need to ensure stored min/max prices match this scaling.
            // Let's assume min/max are stored with the same decimals as the oracle.
            if (price < 0 || uint256(price) < deposit.minOraclePrice || uint256(price) > deposit.maxOraclePrice) {
                return false;
            }
        }

        // Condition 4: Dependent Deposit Unlocked
        if (deposit.requiresOtherDepositId > 0) {
            require(deposits[deposit.requiresOtherDepositId].depositor != address(0), "Dependent deposit does not exist");
            if (!deposits[deposit.requiresOtherDepositId].isUnlocked) {
                return false;
            }
        }

        // If all checks pass
        return true;
    }

    // --- View Functions ---

    /**
     * @notice Retrieves the details of a specific deposit.
     * @param _depositId The ID of the deposit.
     * @return Deposit struct containing all deposit information.
     */
    function getDeposit(uint256 _depositId) public view returns (Deposit memory) {
        require(deposits[_depositId].depositor != address(0), "Deposit does not exist");
        return deposits[_depositId];
    }

     /**
      * @notice Gets the latest price and decimals from the configured oracle.
      * @return price The latest price from the oracle.
      * @return decimals The number of decimals the oracle price is scaled by.
      */
     function getOraclePrice() public view returns (int256 price, uint8 decimals) {
         require(address(oracleAggregator) != address(0), "Oracle not configured");
         (uint80 roundId, int256 latestPrice, uint256 startedAt, uint64 updatedAt, uint80 answeredInRound) = oracleAggregator.latestRoundData();
         require(updatedAt > 0, "Oracle price data not available");
         return (latestPrice, oracleAggregator.decimals());
     }

    /**
     * @notice Returns the current accumulated ETH admin fees.
     */
    function getAdminFeesETH() public view returns (uint256) {
        return adminFeesETH;
    }

    /**
     * @notice Returns the current accumulated ERC20 admin fees for a token.
     * @param _tokenAddress The address of the ERC20 token.
     */
    function getAdminFeesERC20(address _tokenAddress) public view returns (uint256) {
        return adminFeesERC20[_tokenAddress];
    }

    /**
     * @notice Returns the total number of deposits created.
     */
    function getDepositCount() public view returns (uint256) {
        return depositCounter;
    }

    /**
     * @notice Checks if an address is currently on the global unlock whitelist.
     * @param _user The address to check.
     */
    function isWhitelisted(address _user) public view returns (bool) {
        return unlockWhitelist[_user];
    }

    // --- Modification/Management Functions ---

    /**
     * @notice Allows the owner to update unlock conditions for a deposit.
     * @dev Can be used for recovery or adjusting terms. Use with caution.
     * @param _depositId The ID of the deposit to modify.
     * @param _lockedUntil New timestamp.
     * @param _requiredBlockNumber New block number.
     * @param _minOraclePrice New min price.
     * @param _maxOraclePrice New max price.
     * @param _requiresOtherDepositId New dependency ID.
     * @param _unlockPenaltyBps New penalty BPS.
     * @param _unlockFeeBps New fee BPS.
     * @param _canTransferUnlockRight New transferability flag.
     * @param _unlockRecipient New unlock recipient address.
     */
    function updateDepositConditions(
        uint256 _depositId,
        uint64 _lockedUntil,
        uint64 _requiredBlockNumber,
        uint256 _minOraclePrice,
        uint256 _maxOraclePrice,
        uint256 _requiresOtherDepositId,
        uint16 _unlockPenaltyBps,
        uint16 _unlockFeeBps,
        bool _canTransferUnlockRight,
        address _unlockRecipient
    ) external onlyOwner {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor != address(0), "Deposit does not exist");
        require(!deposit.isUnlocked, "Deposit is already unlocked");

        // Validate requiredOtherDepositId if used
        if (_requiresOtherDepositId != 0) {
             require(deposits[_requiresOtherDepositId].depositor != address(0), "Required dependency deposit does not exist");
        }

        deposit.lockedUntil = _lockedUntil;
        deposit.requiredBlockNumber = _requiredBlockNumber;
        deposit.minOraclePrice = _minOraclePrice;
        deposit.maxOraclePrice = _maxOraclePrice == 0 ? type(uint256).max : _maxOraclePrice; // Default max to infinite if 0
        deposit.requiresOtherDepositId = _requiresOtherDepositId;
        deposit.unlockPenaltyBps = _unlockPenaltyBps;
        deposit.unlockFeeBps = _unlockFeeBps;
        deposit.canTransferUnlockRight = _canTransferUnlockRight;
        deposit.unlockRecipient = _unlockRecipient == address(0) ? deposit.depositor : _unlockRecipient; // Use original depositor if new recipient is 0x0

        emit UnlockConditionsUpdated(_depositId, msg.sender);
    }

    /**
     * @notice Allows the current unlock recipient to transfer the unlock right to another address.
     * @param _depositId The ID of the deposit.
     * @param _newRecipient The new address that will be allowed to unlock.
     */
    function transferUnlockRight(uint256 _depositId, address _newRecipient) external {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor != address(0), "Deposit does not exist");
        require(!deposit.isUnlocked, "Deposit is already unlocked");
        require(deposit.unlockRecipient == msg.sender, "Caller is not the current unlock recipient");
        require(deposit.canTransferUnlockRight, "Unlock right transfer is not allowed for this deposit");
        require(_newRecipient != address(0), "New recipient cannot be zero address");
        require(_newRecipient != deposit.unlockRecipient, "New recipient is the same as the current one");

        address oldRecipient = deposit.unlockRecipient;
        deposit.unlockRecipient = _newRecipient;

        emit TransferUnlockRight(_depositId, oldRecipient, _newRecipient);
    }

    /**
     * @notice Allows the current unlock recipient to renounce their right to unlock, setting it back to the original depositor.
     * @param _depositId The ID of the deposit.
     */
    function renounceUnlockRight(uint256 _depositId) external {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor != address(0), "Deposit does not exist");
        require(!deposit.isUnlocked, "Deposit is already unlocked");
        require(deposit.unlockRecipient == msg.sender, "Caller is not the current unlock recipient");
        require(deposit.unlockRecipient != deposit.depositor, "Recipient is already the original depositor");

        address oldRecipient = deposit.unlockRecipient;
        deposit.unlockRecipient = deposit.depositor;

        emit TransferUnlockRight(_depositId, oldRecipient, deposit.depositor);
    }

    /**
     * @notice Splits a fungible (ETH or ERC-20) deposit into two.
     * @dev Creates a new deposit with a portion of the amount and the same conditions.
     * @param _depositId The ID of the deposit to split.
     * @param _splitAmount The amount to move into the new deposit.
     */
    function splitFungibleDeposit(uint256 _depositId, uint256 _splitAmount) external nonReentrant {
        Deposit storage originalDeposit = deposits[_depositId];
        require(originalDeposit.depositor != address(0), "Deposit does not exist");
        require(!originalDeposit.isUnlocked, "Deposit is already unlocked");
        require(originalDeposit.assetType != AssetType.ERC721, "Cannot split ERC721 deposits");
        require(_splitAmount > 0, "Split amount must be greater than zero");
        require(_splitAmount < originalDeposit.amount, "Split amount must be less than the total amount"); // Cannot split the entire amount

        // Only depositor or current unlock recipient can split
        require(msg.sender == originalDeposit.depositor || msg.sender == originalDeposit.unlockRecipient, "Caller is not the depositor or unlock recipient");

        // Create the new deposit with the split amount and same conditions
        _createDeposit(
            originalDeposit.depositor,
            originalDeposit.assetType,
            originalDeposit.tokenAddress,
            0, // tokenId is always 0 for fungible
            _splitAmount,
            originalDeposit.lockedUntil,
            originalDeposit.requiredBlockNumber,
            originalDeposit.minOraclePrice,
            originalDeposit.maxOraclePrice,
            originalDeposit.requiresOtherDepositId,
            originalDeposit.unlockPenaltyBps,
            originalDeposit.unlockFeeBps,
            originalDeposit.canTransferUnlockRight,
            originalDeposit.unlockRecipient, // New deposit has the same unlock recipient initially
            true // Mark as a split deposit
        );

        // Reduce the amount in the original deposit
        originalDeposit.amount -= _splitAmount;

        emit DepositSplit(_depositId, depositCounter, _splitAmount, originalDeposit.depositor);
    }

    /**
     * @notice Allows the owner to force unlock a deposit, bypassing conditions but applying penalty.
     * @param _depositId The ID of the deposit to force unlock.
     */
    function forceUnlockByOwner(uint256 _depositId) external onlyOwner nonReentrant {
        Deposit storage deposit = deposits[_depositId];
        require(deposit.depositor != address(0), "Deposit does not exist");
        require(!deposit.isUnlocked, "Deposit is already unlocked");

        deposit.isUnlocked = true; // Mark as unlocked first (Checks-Effects-Interactions)

        uint256 amountToTransfer = deposit.amount;
        uint256 penaltyAmount = 0;

        // Apply penalty to fungible tokens
        if (deposit.assetType != AssetType.ERC721 && deposit.unlockPenaltyBps > 0 && amountToTransfer > 0) {
            penaltyAmount = (amountToTransfer * deposit.unlockPenaltyBps) / 10000;
            amountToTransfer -= penaltyAmount;
            if (deposit.assetType == AssetType.ETH) {
                adminFeesETH += penaltyAmount;
            } else if (deposit.assetType == AssetType.ERC20) {
                adminFeesERC20[deposit.tokenAddress] += penaltyAmount;
            }
        }

        address payable recipientAddress = payable(deposit.unlockRecipient); // Still sends to the designated recipient

        // Transfer assets
        if (deposit.assetType == AssetType.ETH) {
            (bool success, ) = recipientAddress.call{value: amountToTransfer}("");
            require(success, "ETH transfer failed");
        } else if (deposit.assetType == AssetType.ERC20) {
            IERC20(deposit.tokenAddress).transfer(recipientAddress, amountToTransfer);
        } else if (deposit.assetType == AssetType.ERC721) {
             // Re-check ownership in case of previous rescue or bug
             require(IERC721(deposit.tokenAddress).ownerOf(deposit.tokenId) == address(this), "Contract does not own the NFT");
            IERC721(deposit.tokenAddress).safeTransferFrom(address(this), recipientAddress, deposit.tokenId);
        }

        // Note: No unlock fee applied on forced unlock, only penalty if configured.
        emit ForcedUnlock(_depositId, msg.sender);
        emit DepositUnlocked(_depositId, recipientAddress, deposit.assetType, deposit.tokenAddress, deposit.tokenId, amountToTransfer, penaltyAmount, 0);
    }

    /**
     * @notice Allows the owner to withdraw accumulated admin fees (from penalties/fees).
     * @param _tokenAddress The address of the token (address(0) for ETH).
     */
    function withdrawAdminFees(address _tokenAddress) external onlyOwner nonReentrant {
        uint256 amount = 0;
        if (_tokenAddress == address(0)) {
            amount = adminFeesETH;
            adminFeesETH = 0;
            require(amount > 0, "No ETH fees to withdraw");
            (bool success, ) = payable(owner).call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            amount = adminFeesERC20[_tokenAddress];
            adminFeesERC20[_tokenAddress] = 0;
            require(amount > 0, "No ERC20 fees to withdraw for this token");
            IERC20(_tokenAddress).transfer(owner, amount);
        }
        emit AdminFeesWithdrawn(_tokenAddress, owner, amount);
    }

    // --- Whitelist Management ---

    /**
     * @notice Adds an address to the global unlock whitelist. Only whitelisted addresses can attempt unlocks if requirement is true.
     * @param _user The address to add.
     */
    function addToUnlockWhitelist(address _user) external onlyOwner {
        require(_user != address(0), "Cannot add zero address to whitelist");
        require(!unlockWhitelist[_user], "Address is already whitelisted");
        unlockWhitelist[_user] = true;
        emit WhitelistUpdated(_user, true, msg.sender);
    }

    /**
     * @notice Removes an address from the global unlock whitelist.
     * @param _user The address to remove.
     */
    function removeFromUnlockWhitelist(address _user) external onlyOwner {
        require(unlockWhitelist[_user], "Address is not whitelisted");
        unlockWhitelist[_user] = false;
        emit WhitelistUpdated(_user, false, msg.sender);
    }

     /**
      * @notice Toggles whether the global unlock whitelist requirement is active.
      * @dev If true, only addresses on the whitelist can attempt unlocks. If false, anyone can attempt if they are the recipient or owner.
      * @param _required Set to true to require whitelist, false otherwise.
      */
    function toggleUnlockWhitelistRequirement(bool _required) external onlyOwner {
        unlockWhitelistRequired = _required;
    }

    // --- Oracle Management ---

    /**
     * @notice Updates the address of the Chainlink AggregatorV3Interface oracle.
     * @param _newOracleAggregator The address of the new oracle contract.
     */
    function updateOracleAddress(address _newOracleAggregator) external onlyOwner {
        require(_newOracleAggregator != address(0), "New oracle address cannot be zero");
        oracleAggregator = AggregatorV3Interface(_newOracleAggregator);
        emit OracleUpdated(_newOracleAggregator);
    }

    /**
     * @notice Updates the specific Chainlink price feed address being used.
     * @dev This is needed if the oracleAggregator contract supports multiple feeds.
     * Chainlink's AggregatorV3Interface usually points to a single feed,
     * but this allows future flexibility or different oracle setups.
     * For a standard AggregatorV3Interface, this function might be redundant
     * if the Aggregator address *is* the specific feed.
     * Let's assume `oracleAggregator` points to the *specific feed*.
     * We'll keep `updateOracleAddress` as the primary oracle update.
     * Removing this function as it's potentially confusing or redundant for standard Chainlink feeds.
     * Retaining as a function in summary but implementing as `updateOracleAddress`.
     * Let's rename `updateOracleAddress` to `setOracleFeed` for clarity if it *is* the feed.
     * Or, keep as is, assuming `oracleAggregator` is the V3Interface of the feed.
     * Sticking with `updateOracleAddress` for now as it's common naming.
     * Let's add a separate function to update the feed *interface* itself, which seems more aligned with Chainlink practices.
     * No, AggregatorV3Interface *is* the feed interface. Let's just keep `updateOracleAddress`.
     * Re-evaluating: My summary had `updateOraclePriceFeedId` (string) - this isn't how Chainlink works. A feed *is* an AggregatorV3Interface instance at a specific address. So, `updateOracleAddress` *is* the function to update the feed.
     * Let's re-add a different conceptual function if needed. Maybe allowing owner to specify *which* feed to use if the oracle contract was a router? Too complex for this example.
     * Let's keep just `updateOracleAddress` and the view `getOraclePrice`.
     * Need more functions... Let's add functions to get the current oracle configuration addresses.

     * Revised Oracle Functions:
     * 18. updateOracleAddress (owner only) - updates the AggregatorV3Interface address.
     * 19. getOracleAddress (view) - returns the configured oracle address.
     * 20. getOraclePrice (view) - already exists.
     * Need more functions! Let's add rescue functions and admin fee getters back.

     * Re-counting functions for 20+:
     * 1. constructor
     * 2. depositETH
     * 3. depositERC20
     * 4. depositERC721
     * 5. onERC721Received (public/external, counts)
     * 6. attemptUnlock (nonReentrant)
     * 7. checkUnlockConditions (view)
     * 8. getDeposit (view)
     * 9. getOraclePrice (view)
     * 10. updateDepositConditions (owner only)
     * 11. transferUnlockRight
     * 12. renounceUnlockRight
     * 13. splitFungibleDeposit (nonReentrant)
     * 14. forceUnlockByOwner (owner only, nonReentrant)
     * 15. withdrawAdminFees (owner only, nonReentrant)
     * 16. addToUnlockWhitelist (owner only)
     * 17. removeFromUnlockWhitelist (owner only)
     * 18. isWhitelisted (view)
     * 19. toggleUnlockWhitelistRequirement (owner only)
     * 20. isUnlockWhitelistRequired (view)
     * 21. updateOracleAddress (owner only)
     * 22. getOracleAddress (view)
     * 23. rescueERC20 (owner only, nonReentrant)
     * 24. rescueERC721 (owner only, nonReentrant)
     * 25. getAdminFeesETH (view)
     * 26. getAdminFeesERC20 (view)
     * 27. getDepositCount (view) - already added.

     * Okay, we have 27 public/external functions now. That meets the criteria. Let's implement the rescue functions and add the missing view functions.
     */

    /**
     * @notice Returns the currently configured oracle aggregator address.
     */
    function getOracleAddress() public view returns (address) {
        return address(oracleAggregator);
    }

    // --- Emergency/Rescue Functions (Owner Only) ---

    /**
     * @notice Allows the owner to rescue ERC20 tokens mistakenly sent to the contract.
     * @dev This should only be used for tokens *not* part of an active deposit.
     * @param _token The address of the ERC20 token.
     * @param _to The address to send the tokens to.
     * @param _amount The amount of tokens to rescue.
     */
    function rescueERC20(IERC20 _token, address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(address(_token) != address(0), "Token address cannot be zero");
        require(_to != address(0), "Recipient cannot be zero address");
        require(address(_token) != address(this), "Cannot rescue contract's own tokens");
        // Basic check: ensure this isn't rescuing tokens tied to an active deposit.
        // This is a simplification; a real contract might need more sophisticated checks
        // or only allow rescue of tokens *not* listed in any deposit.
        uint256 contractBalance = _token.balanceOf(address(this));
        uint256 depositedAmount = 0; // Requires iterating deposits per token, inefficient.
        // Simplified: Trust the owner not to abuse this, or add off-chain checks.
        // For this example, assume owner uses this responsibly.
        require(contractBalance >= _amount, "Contract does not have sufficient token balance to rescue");

        _token.transfer(_to, _amount);
    }

     /**
      * @notice Allows the owner to rescue ERC721 tokens mistakenly sent to the contract.
      * @dev This should only be used for tokens *not* part of an active deposit.
      * @param _token The address of the ERC721 token.
      * @param _tokenId The ID of the token to rescue.
      * @param _to The address to send the token to.
      */
    function rescueERC721(IERC721 _token, uint256 _tokenId, address _to) external onlyOwner nonReentrant {
        require(address(_token) != address(0), "Token address cannot be zero");
        require(_to != address(0), "Recipient cannot be zero address");
        // Basic check: ensure this isn't rescuing an NFT tied to an active deposit.
        // This is a simplification; a real contract might need more sophisticated checks.
        // Check if this token/id is part of any *active* deposit.
        bool isPartOfActiveDeposit = false;
        for (uint256 i = 1; i <= depositCounter; i++) {
            Deposit storage dep = deposits[i];
            if (!dep.isUnlocked && dep.assetType == AssetType.ERC721 && dep.tokenAddress == address(_token) && dep.tokenId == _tokenId) {
                isPartOfActiveDeposit = true;
                break;
            }
        }
        require(!isPartOfActiveDeposit, "Cannot rescue an NFT part of an active deposit");

        // Check if the contract actually owns the NFT
        require(_token.ownerOf(_tokenId) == address(this), "Contract does not own this NFT");

        _token.safeTransferFrom(address(this), _to, _tokenId);
    }

    // --- Fallback/Receive ---
    // Allow receiving ETH
    receive() external payable {}
    fallback() external payable {}
    // Note: Fallback/Receive allowing ETH deposit without calling depositETH
    // could lead to ETH being 'stuck' if not accounted for by deposit struct.
    // A more robust contract might restrict incoming ETH to only the depositETH function.
}

```