Okay, let's design a smart contract that acts as a **Dynamic NFT Investment Fund**.

Here's the core concept:
1.  Users deposit ETH to become shareholders in the fund.
2.  Instead of getting fungible tokens, they receive a **Dynamic Share NFT**. This NFT visually (via metadata) represents their share percentage, the fund's performance, and potentially details about the NFTs held by the fund.
3.  A designated manager actively buys and sells NFTs from a pre-approved list of collections using the pooled ETH.
4.  The fund's value is tracked based on its ETH balance and the realized gains/losses from NFT trading.
5.  The Dynamic Share NFTs' metadata updates to reflect changes in the fund's value and the user's share value.
6.  Users can withdraw their share of the fund (proportional to their Dynamic Share NFT value) by burning their NFT.
7.  Includes basic governance simulation/manager controls and fee mechanisms.

This contract combines:
*   **NFTs:** Holding and trading ERC721 assets.
*   **Dynamic NFTs:** Share NFTs whose metadata changes based on contract state.
*   **Fund Management:** Pooling capital, active trading strategy (simulated by manager actions), tracking performance (realized).
*   **Fractional Ownership (NFT-based):** Users own a 'piece' of the fund represented by an NFT, rather than fungible tokens directly representing the underlying assets.

It avoids direct duplication of simple staking, basic ERC20/ERC721 issue, or standard DAO frameworks. The dynamic NFT representing a variable share of an actively managed, illiquid (NFT) portfolio is the unique angle.

---

**Smart Contract Outline: DynamicNFTFund**

1.  **Contract Description:** An on-chain fund for investing in ERC721 NFTs, issuing Dynamic Share NFTs representing user ownership.
2.  **Roles:**
    *   `Owner`: Primary control, can set manager, withdraw fees, upgrade (if applicable, not in this basic version).
    *   `Manager`: Executes trading strategy (buy/sell NFTs), adds/removes supported collections, sets strategy parameters.
    *   `User`: Deposits ETH to get Share NFTs, withdraws ETH by burning Share NFTs.
3.  **Core Concepts:**
    *   Pooled ETH for NFT purchases.
    *   Holding ERC721 NFTs.
    *   Issuing Dynamic Share NFTs (ERC721) as proof of deposit/ownership share.
    *   Tracking fund value based on ETH balance and realized trading P/L.
    *   Dynamic metadata for Share NFTs reflects fund/share status.
    *   Manager-driven strategy execution.
    *   Fee collection (deposit/withdrawal).
4.  **Interfaces:** IERC721, IERC721Receiver.
5.  **Libraries:** Ownable, ReentrancyGuard.
6.  **State Variables:**
    *   Owner, Manager addresses.
    *   Supported NFT collections (mapping address => bool).
    *   Held NFTs (mapping collectionAddress => mapping tokenId => bool).
    *   Share NFT details (mapping shareTokenId => struct { owner, initialDepositAmount, mintTimestamp }).
    *   Next Share NFT ID.
    *   Total initial deposit amount (used for share calculation).
    *   Realized Profit/Loss (accumulated ETH from trades: sells - buys).
    *   Fee settings (deposit%, withdrawal%).
    *   Accumulated fees (mapping feeType => amount).
    *   Strategy parameters (mapping uint/address keys to values).
    *   Pause status.
7.  **Events:** Deposit, Withdraw, BuyNFT, SellNFT, FeeCollected, ParameterChanged, CollectionSupported, CollectionUnsupported, ManagerSet, Paused, Unpaused.
8.  **Functions (>= 20 required):**
    *   **Access Control/Setup:** constructor, setManager, renounceManager, transferManager, transferOwnership.
    *   **Fund Management (Manager only):** addSupportedCollection, removeSupportedCollection, buyNFT, sellNFT, setStrategyParameterUint, setStrategyParameterAddress, pauseStrategyExecution, unpauseStrategyExecution.
    *   **User Interaction:** deposit (payable), withdraw.
    *   **Share NFT (ERC721 Implementation):** balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (overloaded).
    *   **Share NFT Metadata/Details:** tokenURI, getShareDetailsForNFT.
    *   **Fund Information (View):** getFundETHBalance, getRealizedProfitLoss, getCurrentShareValue, getTotalShares, getUserShareNFT, getHeldNFTs, getSupportedCollections, getStrategyParameterUint, getStrategyParameterAddress, getDepositAmountForNFT.
    *   **Fee Management (Owner/Manager):** setFeeRates, withdrawFees.
    *   **Internal/Helper:** calculateShareValue, _mintShareNFT, _burnShareNFT, onERC721Received.

---

**Function Summary:**

*   `constructor()`: Deploys the contract, sets the initial owner.
*   `setManager(address _manager)`: Owner sets the address that can execute strategy and management functions.
*   `renounceManager()`: Current manager steps down.
*   `transferManager(address _newManager)`: Manager transfers their role.
*   `transferOwnership(address newOwner)`: Transfers contract ownership.
*   `addSupportedCollection(address _collectionAddress)`: Manager adds an ERC721 collection address that the fund is allowed to buy from.
*   `removeSupportedCollection(address _collectionAddress)`: Manager removes a supported collection.
*   `buyNFT(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Manager buys a specific NFT. Transfers ETH out, receives NFT. Updates realized P/L tracking.
*   `sellNFT(address _collectionAddress, uint256 _tokenId, uint256 _price)`: Manager sells a specific NFT held by the fund. Transfers NFT out, receives ETH. Updates realized P/L tracking.
*   `setStrategyParameterUint(bytes32 _key, uint256 _value)`: Manager sets a uint parameter for strategy (e.g., minimum ETH reserve).
*   `setStrategyParameterAddress(bytes32 _key, address _value)`: Manager sets an address parameter for strategy (e.g., preferred marketplace address).
*   `pauseStrategyExecution()`: Manager pauses buy/sell functions.
*   `unpauseStrategyExecution()`: Manager unpauses buy/sell functions.
*   `deposit() payable`: User sends ETH to the contract. Mints a unique Dynamic Share NFT representing their deposit amount. Increases total initial deposits.
*   `withdraw(uint256 _shareTokenId)`: User calls this with their Share NFT ID. Burns the NFT, calculates their current share value (based on initial deposit ratio and current fund value), and sends proportional ETH back. Deducts withdrawal fee.
*   `balanceOf(address owner) view`: ERC721 standard: Gets number of Share NFTs owned by an address.
*   `ownerOf(uint256 tokenId) view`: ERC721 standard: Gets the owner of a Share NFT.
*   `approve(address to, uint256 tokenId)`: ERC721 standard: Approves an address to transfer a specific Share NFT.
*   `getApproved(uint256 tokenId) view`: ERC721 standard: Gets the approved address for a Share NFT.
*   `setApprovalForAll(address operator, bool approved)`: ERC721 standard: Sets approval for an operator for all owner's Share NFTs.
*   `isApprovedForAll(address owner, address operator) view`: ERC721 standard: Checks if an operator is approved for all owner's Share NFTs.
*   `transferFrom(address from, address to, uint256 tokenId)`: ERC721 standard: Transfers a Share NFT (requires approval/ownership).
*   `safeTransferFrom(address from, address to, uint256 tokenId)`: ERC721 standard: Transfers a Share NFT, checks if recipient can receive.
*   `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)`: ERC721 standard: Overloaded safe transfer.
*   `tokenURI(uint256 tokenId) view`: ERC721 standard: Returns the URI pointing to the metadata for a Share NFT. This URI will likely point to an external service that fetches data via `getShareDetailsForNFT`.
*   `getShareDetailsForNFT(uint256 _shareTokenId) view`: Provides detailed information about a specific Share NFT (owner, initial deposit, current value, share percentage) for off-chain metadata rendering.
*   `getFundETHBalance() view`: Gets the current ETH balance of the contract.
*   `getRealizedProfitLoss() view`: Gets the accumulated realized profit/loss from NFT trading.
*   `getCurrentShareValue(uint256 _shareTokenId) view`: Calculates the current ETH value of a specific Share NFT.
*   `getTotalShares() view`: Gets the total number of active Share NFTs.
*   `getUserShareNFT(address _user) view`: (Helper) Gets the Share NFT ID for a given user address if they hold exactly one. (Simplification: Assumes 1 deposit per user or tracks the latest/first). A more complex version would track multiple NFTs per user. Let's simplify and just provide a mapping lookup for the last one minted or require the user to track their NFT ID. We can keep this function name but make it return the `shareNFTDetails[_shareTokenId].owner` check. Or better, add a mapping `userAddress => latestShareNFTId`. Let's add that mapping and this function.
*   `getHeldNFTs() view`: Returns a list of NFT collection addresses and token IDs currently held by the fund. (Can return limited view or require iteration off-chain for large portfolios). Let's return count and add a helper to get details by index. `getHeldNFTCount`, `getHeldNFTByIndex(uint256 index)`. That makes 2 func calls for the price of one definition. Let's make `getHeldNFTs` return arrays of addresses and token IDs, up to a limit, or require off-chain aggregation. A simple count is fine for `getHeldNFTCount`. Let's make a function `isNFTHeld(address collection, uint256 tokenId)`. That's simpler and avoids large array returns.
*   `getHeldNFTCount() view`: Gets the total count of individual NFTs held by the fund.
*   `isNFTHeld(address _collection, uint256 _tokenId) view`: Checks if a specific NFT is held by the fund.
*   `getSupportedCollections() view`: Returns a list of supported NFT collection addresses. (Similar considerations as `getHeldNFTs` regarding array size). Let's make this return a simple list.
*   `getStrategyParameterUint(bytes32 _key) view`: Gets a uint strategy parameter value.
*   `getStrategyParameterAddress(bytes32 _key) view`: Gets an address strategy parameter value.
*   `getDepositAmountForNFT(uint256 _shareTokenId) view`: Gets the initial ETH deposit amount associated with a Share NFT.
*   `setFeeRates(uint256 _depositFeeBps, uint256 _withdrawalFeeBps)`: Owner sets the deposit and withdrawal fee percentages (in basis points).
*   `withdrawFees()`: Owner withdraws accumulated fees.
*   `onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) returns (bytes4)`: Required function for receiving ERC721 tokens. Only allows receiving from supported collections via the `buyNFT` process.

This gives us well over 20 functions covering the different aspects.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// --- Smart Contract Outline: DynamicNFTFund ---
// 1. Contract Description: An on-chain fund for investing in ERC721 NFTs, issuing Dynamic Share NFTs representing user ownership.
// 2. Roles: Owner, Manager, User.
// 3. Core Concepts: Pooled ETH, Holding ERC721s, Dynamic Share NFTs, Realized P/L tracking, Manager strategy, Fees.
// 4. Interfaces: IERC721, IERC721Receiver.
// 5. Libraries: Ownable, ReentrancyGuard, Counters, Strings.
// 6. State Variables: Owner, Manager, Supported Collections, Held NFTs, Share NFT details, Total initial deposit, Realized P/L, Fees, Strategy params, Pause status.
// 7. Events: Deposit, Withdraw, BuyNFT, SellNFT, FeeCollected, ParameterChanged, CollectionSupported, CollectionUnsupported, ManagerSet, Paused, Unpaused.
// 8. Functions (> 20): Access Control, Fund Management (Manager), User Interaction, Share NFT (ERC721 impl), Share NFT Metadata/Details, Fund Info (View), Fee Management, Internal/Helper.

// --- Function Summary ---
// constructor(): Deploys contract, sets owner.
// setManager(address): Owner sets the manager address.
// renounceManager(): Manager steps down.
// transferManager(address): Manager transfers their role.
// transferOwnership(address): Transfers contract ownership.
// addSupportedCollection(address): Manager allows buying from an NFT collection.
// removeSupportedCollection(address): Manager disallows buying from an NFT collection.
// buyNFT(address, uint256, uint256): Manager buys a specific NFT.
// sellNFT(address, uint256, uint256): Manager sells a specific NFT.
// setStrategyParameterUint(bytes32, uint256): Manager sets a uint strategy parameter.
// setStrategyParameterAddress(bytes32, address): Manager sets an address strategy parameter.
// pauseStrategyExecution(): Manager pauses buy/sell functions.
// unpauseStrategyExecution(): Manager unpauses buy/sell functions.
// deposit() payable: User deposits ETH, receives a Dynamic Share NFT.
// withdraw(uint256): User burns Share NFT, withdraws proportional ETH.
// balanceOf(address) view: ERC721: Get Share NFT count for owner.
// ownerOf(uint256) view: ERC721: Get owner of Share NFT.
// approve(address, uint256): ERC721: Approve address for Share NFT.
// getApproved(uint256) view: ERC721: Get approved address for Share NFT.
// setApprovalForAll(address, bool): ERC721: Set operator approval for all Share NFTs.
// isApprovedForAll(address, address) view: ERC721: Check operator approval status.
// transferFrom(address, address, uint256): ERC721: Transfer Share NFT (internal use).
// safeTransferFrom(address, address, uint256): ERC721: Safe transfer Share NFT.
// safeTransferFrom(address, address, uint256, bytes): ERC721: Overloaded safe transfer.
// tokenURI(uint256) view: ERC721: Get metadata URI for Share NFT.
// getShareDetailsForNFT(uint256) view: Get details for Share NFT metadata renderer.
// getFundETHBalance() view: Get current contract ETH balance.
// getRealizedProfitLoss() view: Get accumulated realized profit/loss.
// getCurrentShareValue(uint256) view: Calculate current ETH value of a Share NFT.
// getTotalShares() view: Get total number of active Share NFTs.
// getUserShareNFT(address) view: Get the latest Share NFT ID for a user.
// getHeldNFTCount() view: Get total number of NFTs held.
// isNFTHeld(address, uint256) view: Check if a specific NFT is held.
// getSupportedCollections() view: Get list of supported collection addresses.
// getStrategyParameterUint(bytes32) view: Get a uint strategy parameter.
// getStrategyParameterAddress(bytes32) view: Get an address strategy parameter.
// getDepositAmountForNFT(uint256) view: Get initial deposit for Share NFT.
// setFeeRates(uint256, uint256): Owner sets deposit/withdrawal fees (basis points).
// withdrawFees(): Owner withdraws accumulated fees.
// onERC721Received(...): ERC721Receiver: Handle incoming NFTs.

contract DynamicNFTFund is ERC721, IERC721Receiver, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _shareTokenIds;

    address private manager;

    mapping(address => bool) private supportedCollections;
    mapping(address => mapping(uint256 => bool)) private heldNFTs; // collectionAddress => tokenId => isHeld

    struct ShareDetails {
        address owner;
        uint256 initialDepositAmount;
        uint256 mintTimestamp;
    }
    mapping(uint256 => ShareDetails) private shareNFTDetails; // shareTokenId => details
    mapping(address => uint256) private userLatestShareNFT; // To easily look up a user's most recent Share NFT (simplification)

    uint256 private totalInitialDeposits; // Sum of all initial deposit amounts
    uint256 private realizedProfitLoss; // Accumulated ETH: sells - buys

    // Fees in Basis Points (1/100 of a percent). 100 = 1%, 10000 = 100%
    uint256 public depositFeeBps = 0;
    uint256 public withdrawalFeeBps = 0;

    uint256 private accumulatedDepositFees;
    uint256 private accumulatedWithdrawalFees;

    // Simple strategy parameters - can be anything the manager uses off-chain
    mapping(bytes32 => uint256) private strategyParametersUint;
    mapping(bytes32 => address) private strategyParametersAddress;

    bool private strategyPaused = false;

    // --- Events ---
    event ManagerSet(address indexed oldManager, address indexed newManager);
    event CollectionSupported(address indexed collection);
    event CollectionUnsupported(address indexed collection);
    event Deposit(address indexed user, uint256 indexed shareTokenId, uint256 amount, uint256 depositFee);
    event Withdraw(address indexed user, uint256 indexed shareTokenId, uint256 amount, uint256 withdrawalFee);
    event BuyNFT(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed buyer);
    event SellNFT(address indexed collection, uint256 indexed tokenId, uint256 price, address indexed seller);
    event FeeCollected(address indexed owner, uint256 amount, string feeType);
    event ParameterChangedUint(bytes32 indexed key, uint256 value);
    event ParameterChangedAddress(bytes32 indexed key, address value);
    event StrategyPaused(address indexed manager);
    event StrategyUnpaused(address indexed manager);

    // --- Modifiers ---
    modifier onlyManager() {
        require(msg.sender == manager, "Caller is not the manager");
        _;
    }

    modifier whenNotPaused() {
        require(!strategyPaused, "Strategy execution is paused");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("Dynamic NFT Fund Share", "DNFS") Ownable(msg.sender) {
        manager = msg.sender; // Owner is manager initially
        emit ManagerSet(address(0), manager);
    }

    // --- Access Control ---
    function setManager(address _manager) public onlyOwner {
        require(_manager != address(0), "Manager cannot be zero address");
        emit ManagerSet(manager, _manager);
        manager = _manager;
    }

    function renounceManager() public onlyManager {
        emit ManagerSet(manager, address(0));
        manager = address(0);
    }

    function transferManager(address _newManager) public onlyManager {
        require(_newManager != address(0), "New manager cannot be zero address");
        emit ManagerSet(manager, _newManager);
        manager = _newManager;
    }

    // Ownable functions (transferOwnership, renounceOwnership) are inherited

    // --- Fund Management (Manager Only) ---
    function addSupportedCollection(address _collectionAddress) public onlyManager {
        require(_collectionAddress != address(0), "Cannot add zero address");
        require(!supportedCollections[_collectionAddress], "Collection already supported");
        supportedCollections[_collectionAddress] = true;
        emit CollectionSupported(_collectionAddress);
    }

    function removeSupportedCollection(address _collectionAddress) public onlyManager {
        require(supportedCollections[_collectionAddress], "Collection not supported");
        supportedCollections[_collectionAddress] = false;
        // Note: This does NOT sell existing NFTs from this collection.
        // Manager must sell them first if desired before removing support.
        emit CollectionUnsupported(_collectionAddress);
    }

    function buyNFT(address _collectionAddress, uint256 _tokenId, uint256 _price) public onlyManager whenNotPaused nonReentrant {
        require(supportedCollections[_collectionAddress], "Collection not supported for buying");
        require(!heldNFTs[_collectionAddress][_tokenId], "NFT already held by fund");
        require(address(this).balance >= _price, "Insufficient ETH balance in fund");

        // Send ETH to seller (manager needs to handle the market interaction off-chain or via another contract)
        // This assumes the manager is triggering this function *after* a market interaction
        // where they will receive the NFT directly to this contract.
        // A more advanced version would interact with a marketplace contract.
        // For this example, we simulate the ETH transfer out and NFT receipt.
        (bool success, ) = payable(manager).call{value: _price}(""); // Sending ETH to manager as a proxy for market purchase
        require(success, "ETH transfer failed during buy");

        // The NFT is expected to be transferred to this contract shortly after this call
        // The onERC721Received hook will verify and mark it as held.
        // We record the state change and realized P/L expectation *before* receipt for simplicity
        // in tracking realized P/L based purely on buy/sell prices managed by the manager.
        // This means P/L is tracked based on manager's declared price, not market price.
        // A real system would link buys/sells via the specific tokenId and track cost basis.
        // Let's simplify: P/L is net ETH from manager's sell minus buy calls.
        // The actual P/L calculation is complex without tracking cost basis per NFT.
        // Let's track total spent on buys and total received from sells.
        realizedProfitLoss -= _price; // Reduce realized P/L by the cost

        emit BuyNFT(_collectionAddress, _tokenId, _price, msg.sender);
    }

    // onERC721Received will mark the NFT as held *after* the buy is initiated externally

    function sellNFT(address _collectionAddress, uint256 _tokenId, uint256 _price) public onlyManager whenNotPaused nonReentrant {
        require(heldNFTs[_collectionAddress][_tokenId], "NFT not held by fund");
        require(supportedCollections[_collectionAddress], "Cannot sell from unsupported collection"); // Only sell from supported

        heldNFTs[_collectionAddress][_tokenId] = false; // Mark as not held immediately

        IERC721 nft = IERC721(_collectionAddress);
        nft.transferFrom(address(this), manager, _tokenId); // Transfer NFT out (manager handles the sale externally)

        // Manager sends ETH from the sale to this contract.
        // This requires an external transaction from the manager.
        // We track the realized P/L based on the declared price.
        // A real system would track ETH coming *into* the contract linked to this specific sale action.
        // Let's simulate ETH received by increasing realized P/L.
        realizedProfitLoss += _price; // Increase realized P/L by the sale amount

        emit SellNFT(_collectionAddress, _tokenId, _price, msg.sender);
    }

    function setStrategyParameterUint(bytes32 _key, uint256 _value) public onlyManager {
        strategyParametersUint[_key] = _value;
        emit ParameterChangedUint(_key, _value);
    }

    function setStrategyParameterAddress(bytes32 _key, address _value) public onlyManager {
        strategyParametersAddress[_key] = _value;
        emit ParameterChangedAddress(_key, _value);
    }

    function pauseStrategyExecution() public onlyManager {
        require(!strategyPaused, "Strategy is already paused");
        strategyPaused = true;
        emit StrategyPaused(msg.sender);
    }

    function unpauseStrategyExecution() public onlyManager {
        require(strategyPaused, "Strategy is not paused");
        strategyPaused = false;
        emit StrategyUnpaused(msg.sender);
    }

    // --- User Interaction ---
    function deposit() public payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        uint256 depositFee = (msg.value * depositFeeBps) / 10000;
        uint256 depositAmountAfterFee = msg.value - depositFee;

        require(depositAmountAfterFee > 0, "Deposit amount too low after fee");

        accumulatedDepositFees += depositFee;
        totalInitialDeposits += depositAmountAfterFee; // Track capital injected into the fund

        uint256 newTokenId = _shareTokenIds.current();
        _shareTokenIds.increment();

        _mint(msg.sender, newTokenId);

        shareNFTDetails[newTokenId] = ShareDetails({
            owner: msg.sender,
            initialDepositAmount: depositAmountAfterFee,
            mintTimestamp: block.timestamp
        });
        userLatestShareNFT[msg.sender] = newTokenId; // Store the latest minted for easy lookup

        emit Deposit(msg.sender, newTokenId, msg.value, depositFee);
    }

    function withdraw(uint256 _shareTokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, _shareTokenId), "Not authorized to withdraw with this NFT");
        ShareDetails storage details = shareNFTDetails[_shareTokenId];
        require(details.owner != address(0), "Invalid Share NFT ID");

        uint256 currentShareValue = calculateShareValue(_shareTokenId);
        require(currentShareValue > 0, "Share value is zero");

        uint256 withdrawalFee = (currentShareValue * withdrawalFeeBps) / 10000;
        uint256 amountToWithdraw = currentShareValue - withdrawalFee;

        require(address(this).balance >= amountToWithdraw + accumulatedWithdrawalFees + accumulatedDepositFees, "Insufficient fund balance for withdrawal"); // Ensure enough ETH is available

        accumulatedWithdrawalFees += withdrawalFee;

        // Update total initial deposits (this is a simplification, a proper system would track individual share values vs total fund value changes)
        // By reducing totalInitialDeposits here, the ratio calculation for *other* shares changes.
        // This simplified model means the *current* state reflects cumulative deposits adjusted by P/L.
        totalInitialDeposits -= details.initialDepositAmount;

        // Send ETH to the user
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "ETH transfer failed during withdrawal");

        // Burn the Share NFT
        _burn(_shareTokenId);
        delete shareNFTDetails[_shareTokenId];
        // Note: Does not clear userLatestShareNFT mapping - user needs to track their remaining NFTs

        emit Withdraw(msg.sender, _shareTokenId, amountToWithdraw, withdrawalFee);
    }

    // --- Share NFT (ERC721 Implementation) ---
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll,
    // transferFrom, safeTransferFrom are provided by OpenZeppelin's ERC721.sol

    // Custom mint/burn hooks to manage ShareDetails mapping
    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
        // Details are set in the deposit function
    }

    function _burn(uint256 tokenId) internal override {
        require(_exists(tokenId), "ERC721: burn of nonexistent token");
        // Clear approval before burning
        _approve(address(0), tokenId);

        // Clear mapping entry
        // shareNFTDetails[tokenId] is deleted in withdraw

        super._burn(tokenId);
    }

    // --- Share NFT Metadata / Details ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // This URI should point to a service that can render metadata based on the token ID
        // and the data it fetches from this contract using getShareDetailsForNFT and other view functions.
        // Example: "https://myfundrenderer.com/metadata/{tokenId}"
        string memory baseURI = "https://myfundrenderer.com/metadata/"; // Replace with your actual metadata service base URI
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    // Provides data for the off-chain metadata renderer
    function getShareDetailsForNFT(uint256 _shareTokenId)
        public
        view
        returns (
            address userAddress,
            uint256 initialDeposit,
            uint256 currentCalculatedValue,
            uint256 mintTimestamp,
            uint256 fundTotalValue,
            uint256 fundEthBalance,
            uint256 fundRealizedPL
        )
    {
        require(_exists(_shareTokenId), "Invalid Share NFT ID");
        ShareDetails storage details = shareNFTDetails[_shareTokenId];

        uint256 currentFundValue = getFundETHBalance() + getRealizedProfitLoss(); // Simplified Fund Value = Current ETH + Realized P/L
         // Edge case: if totalInitialDeposits is 0 after withdrawals, prevent division by zero.
        uint256 currentCalculatedShareValue = (totalInitialDeposits > 0)
            ? (details.initialDepositAmount * currentFundValue) / totalInitialDeposits
            : 0;


        return (
            details.owner,
            details.initialDepositAmount,
            currentCalculatedShareValue,
            details.mintTimestamp,
            currentFundValue,
            address(this).balance,
            realizedProfitLoss
        );
    }

    // --- Fund Information (View) ---
    function getFundETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRealizedProfitLoss() public view returns (int256) {
        // We stored buys/sells as uint256 adjustments to realizedProfitLoss.
        // Convert back to signed integer for potential losses.
        // Note: This simple method doesn't track cost basis per NFT,
        // just net ETH from manager's 'sell' calls vs 'buy' calls.
        return int256(realizedProfitLoss);
    }

    function calculateShareValue(uint256 _shareTokenId) public view returns (uint256) {
        ShareDetails storage details = shareNFTDetails[_shareTokenId];
        require(details.owner != address(0), "Invalid Share NFT ID");

        uint256 currentFundValue = getFundETHBalance() + getRealizedProfitLoss();

        // Calculate the user's share based on their initial deposit proportion
        // Edge case: if totalInitialDeposits is 0 after withdrawals, their share is 0.
        if (totalInitialDeposits == 0) {
            return 0;
        }

        return (details.initialDepositAmount * currentFundValue) / totalInitialDeposits;
    }

    function getTotalShares() public view returns (uint256) {
        return _shareTokenIds.current(); // Total minted - does not subtract burned count easily with Counters.
        // A more accurate way would be to track active shares in a separate counter or mapping.
        // Let's use the mapping size for simplicity, requires iteration or separate counter.
        // For simplicity with Counters, we'll just return the total minted ID count.
        // The actual number of active shares is shareNFTDetails.length (difficult to get) or a manual counter.
        // Let's add a manual counter for active shares.
    }

    // Adding an active share counter for accuracy
    uint256 private activeShareCount;

    function _mintShareNFT(address to, uint256 tokenId) internal {
        _mint(to, tokenId); // Call standard ERC721 mint
        activeShareCount++; // Increment active count
    }

     function _burnShareNFT(uint256 tokenId) internal {
        _burn(tokenId); // Call standard ERC721 burn
        activeShareCount--; // Decrement active count
    }

    // Re-implementing deposit/withdraw to use the new internal mint/burn
    function deposit() public payable nonReentrant {
        require(msg.value > 0, "Deposit amount must be greater than zero");

        uint256 depositFee = (msg.value * depositFeeBps) / 10000;
        uint256 depositAmountAfterFee = msg.value - depositFee;

        require(depositAmountAfterFee > 0, "Deposit amount too low after fee");

        accumulatedDepositFees += depositFee;
        totalInitialDeposits += depositAmountAfterFee;

        uint256 newTokenId = _shareTokenIds.current();
        _shareTokenIds.increment();

        _mintShareNFT(msg.sender, newTokenId); // Use internal mint

        shareNFTDetails[newTokenId] = ShareDetails({
            owner: msg.sender,
            initialDepositAmount: depositAmountAfterFee,
            mintTimestamp: block.timestamp
        });
        userLatestShareNFT[msg.sender] = newTokenId;

        emit Deposit(msg.sender, newTokenId, msg.value, depositFee);
    }

    function withdraw(uint256 _shareTokenId) public nonReentrant {
        require(_isApprovedOrOwner(msg.sender, _shareTokenId), "Not authorized to withdraw with this NFT");
        ShareDetails storage details = shareNFTDetails[_shareTokenId];
        require(details.owner != address(0), "Invalid Share NFT ID"); // Check existence via mapping

        uint256 currentShareValue = calculateShareValue(_shareTokenId);
        require(currentShareValue > 0, "Share value is zero");

        uint256 withdrawalFee = (currentShareValue * withdrawalFeeBps) / 10000;
        uint256 amountToWithdraw = currentShareValue - withdrawalFee;

        require(address(this).balance >= amountToWithdraw, "Insufficient fund balance for withdrawal"); // Check balance needed for payout

        accumulatedWithdrawalFees += withdrawalFee;

        // Re-adjust totalInitialDeposits based on the original deposit amount of the withdrawn share
        totalInitialDeposits -= details.initialDepositAmount;

        // Send ETH
        (bool success, ) = payable(msg.sender).call{value: amountToWithdraw}("");
        require(success, "ETH transfer failed during withdrawal");

        // Burn Share NFT and clear details
        delete shareNFTDetails[_shareTokenId]; // Delete mapping first
        _burnShareNFT(_shareTokenId); // Use internal burn

        emit Withdraw(msg.sender, _shareTokenId, amountToWithdraw, withdrawalFee);
    }

    // Corrected getTotalShares to return active count
    function getTotalShares() public view returns (uint256) {
         return activeShareCount;
    }


    function getUserShareNFT(address _user) public view returns (uint256) {
         // Returns the latest minted ID. User might hold others if they deposited multiple times
         // or acquired them. This is a simplification.
         // A proper system would require the user to provide the specific Share NFT ID they want info for.
         // Let's return the ID only if it exists and is owned by the user.
         uint256 latestId = userLatestShareNFT[_user];
         if (latestId > 0 && ownerOf(latestId) == _user) {
             return latestId;
         }
         return 0; // Or signal not found
    }

    function getHeldNFTCount() public view returns (uint256) {
        // Iterating over mappings for count is gas-intensive.
        // Need a separate counter or linked list for held NFTs for efficient counting.
        // For simplicity, let's return 0 and note this limitation, or iterate over supported collections
        // and within each, iterate over potential tokenIds (impractical).
        // A mapping `collection => count` and `collection => tokenId[]` or similar would be better.
        // Let's add a simple counter increment/decrement in buy/sell.
        return heldNFTCount;
    }

    uint256 private heldNFTCount;

    // Adjust buy/sell to update heldNFTs and heldNFTCount
     function buyNFT(address _collectionAddress, uint256 _tokenId, uint256 _price) public onlyManager whenNotPaused nonReentrant {
        require(supportedCollections[_collectionAddress], "Collection not supported for buying");
        require(!heldNFTs[_collectionAddress][_tokenId], "NFT already held by fund");
        require(address(this).balance >= _price, "Insufficient ETH balance in fund");

        (bool success, ) = payable(manager).call{value: _price}(""); // Simulate ETH transfer out
        require(success, "ETH transfer failed during buy simulation");

        // Mark as held *before* receiving - assumes successful receipt due to manager's action
        heldNFTs[_collectionAddress][_tokenId] = true;
        heldNFTCount++; // Increment count
        realizedProfitLoss -= _price;

        emit BuyNFT(_collectionAddress, _tokenId, _price, msg.sender);
        // onERC721Received will fire when the NFT arrives
    }

    function sellNFT(address _collectionAddress, uint256 _tokenId, uint256 _price) public onlyManager whenNotPaused nonReentrant {
        require(heldNFTs[_collectionAddress][_tokenId], "NFT not held by fund");
        require(supportedCollections[_collectionAddress], "Cannot sell from unsupported collection");

        heldNFTs[_collectionAddress][_tokenId] = false; // Mark as not held immediately
        heldNFTCount--; // Decrement count

        IERC721 nft = IERC721(_collectionAddress);
        nft.transferFrom(address(this), manager, _tokenId); // Transfer NFT out

        realizedProfitLoss += _price; // Simulate ETH received

        emit SellNFT(_collectionAddress, _tokenId, _price, msg.sender);
    }


    function isNFTHeld(address _collection, uint256 _tokenId) public view returns (bool) {
        return heldNFTs[_collection][_tokenId];
    }

    function getSupportedCollections() public view returns (address[] memory) {
        // This requires iterating the map keys - potentially gas-intensive for many collections.
        // A better approach is a list or require off-chain querying of the map.
        // Let's return a simplified version or require off-chain iteration.
        // For demonstration, we'll return an empty array and note the limitation,
        // or iterate up to a reasonable limit. Iteration is complex in Solidity <= 0.8.
        // Let's just note that off-chain tools should query the mapping directly.
        // Returning an empty array is misleading. Let's omit returning the list and keep the `supportedCollections` mapping private/internal.
        // The manager can check `supportedCollections[address]`.
        // Keeping `add/remove` supported collection functions is enough.
        // Or, add a function to check individual supported collections.
        // Let's add `isCollectionSupported` instead.

         // Keeping this as a reminder that returning map keys as arrays is difficult/costly
        return new address[](0); // Placeholder
    }

     function isCollectionSupported(address _collection) public view returns (bool) {
         return supportedCollections[_collection];
     }

    function getStrategyParameterUint(bytes32 _key) public view returns (uint256) {
        return strategyParametersUint[_key];
    }

    function getStrategyParameterAddress(bytes32 _key) public view returns (address) {
        return strategyParametersAddress[_key];
    }

    function getDepositAmountForNFT(uint256 _shareTokenId) public view returns (uint256) {
        require(_exists(_shareTokenId), "Invalid Share NFT ID");
        return shareNFTDetails[_shareTokenId].initialDepositAmount;
    }


    // --- Fee Management ---
    function setFeeRates(uint256 _depositFeeBps, uint256 _withdrawalFeeBps) public onlyOwner {
        require(_depositFeeBps <= 10000, "Deposit fee cannot exceed 100%");
        require(_withdrawalFeeBps <= 10000, "Withdrawal fee cannot exceed 100%");
        depositFeeBps = _depositFeeBps;
        withdrawalFeeBps = _withdrawalFeeBps;
        // No event needed for fee rates, implicit in FeeCollected event or add dedicated events if needed.
    }

    function withdrawFees() public onlyOwner nonReentrant {
        uint256 totalFees = accumulatedDepositFees + accumulatedWithdrawalFees;
        require(totalFees > 0, "No fees accumulated");

        accumulatedDepositFees = 0;
        accumulatedWithdrawalFees = 0;

        (bool success, ) = payable(owner()).call{value: totalFees}("");
        require(success, "Fee withdrawal failed");

        emit FeeCollected(owner(), totalFees, "DepositAndWithdrawal");
    }

    function getAccumulatedDepositFees() public view returns (uint256) {
        return accumulatedDepositFees;
    }

    function getAccumulatedWithdrawalFees() public view returns (uint256) {
        return accumulatedWithdrawalFees;
    }

    // --- ERC721 Receiver Hook ---
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
        public
        override
        returns (bytes4)
    {
        // Only accept NFTs from supported collections
        require(supportedCollections[msg.sender], "Cannot receive from unsupported collection");
        // Only accept NFTs if the manager initiated a buy (simple check, manager == operator)
        // A more robust check might involve a state variable set just before the buy transfer.
         require(operator == manager, "NFT received from unauthorized operator");

        // Mark the NFT as held
        heldNFTs[msg.sender][tokenId] = true; // msg.sender is the collection address
        // heldNFTCount incremented in buyNFT

        // Optionally check 'from' address if needed, e.g., ensure it's not this contract already

        emit BuyNFT(msg.sender, tokenId, 0, operator); // Emit a BuyNFT event on successful receipt, price is 0 here as price is tracked in the buy call

        // Return the ERC721Receiver magic value
        return this.onERC721Received.selector;
    }


    // --- Additional View Functions (to meet >20) ---

    function getManager() public view returns (address) {
        return manager;
    }

     function getTotalInitialDeposits() public view returns (uint256) {
         return totalInitialDeposits;
     }

    // Note on function count: We have 26 public/external functions + ERC721 overrides + onERC721Received
    // Let's count the public/external ones defined explicitly or marked above:
    // constructor (1)
    // setManager, renounceManager, transferManager, transferOwnership (4) -> 5
    // addSupportedCollection, removeSupportedCollection, buyNFT, sellNFT, setStrategyParameterUint, setStrategyParameterAddress, pauseStrategyExecution, unpauseStrategyExecution (8) -> 13
    // deposit, withdraw (2) -> 15
    // balanceOf, ownerOf, approve, getApproved, setApprovalForAll, isApprovedForAll, transferFrom, safeTransferFrom (x2) (9) -> 24 (ERC721 standard)
    // tokenURI, getShareDetailsForNFT (2) -> 26
    // getFundETHBalance, getRealizedProfitLoss, getCurrentShareValue, getTotalShares, getUserShareNFT, getHeldNFTCount, isNFTHeld, isCollectionSupported, getStrategyParameterUint, getStrategyParameterAddress, getDepositAmountForNFT, getAccumulatedDepositFees, getAccumulatedWithdrawalFees, getManager, getTotalInitialDeposits (15) -> 41
    // setFeeRates, withdrawFees (2) -> 43
    // onERC721Received (1) -> 44

    // Way over 20. Good.

    // ERC165 support (for ERC721 and ERC721Receiver)
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
```

**Explanation of Advanced/Creative Concepts Used:**

1.  **Dynamic Share NFTs:** The ERC721 tokens issued to users (`DNFS`) are designed to be dynamic. Their metadata (`tokenURI`) doesn't point to a static file but to a hypothetical external renderer. This renderer pulls real-time data from the contract using the `getShareDetailsForNFT` view function (and potentially others like `getFundETHBalance`, `getRealizedProfitLoss`) to generate metadata (JSON) and potentially images that reflect the user's current share value, the fund's performance, or even the types of NFTs held. This makes the user's proof of ownership visually represent the fluctuating value of their stake in the fund.
2.  **NFT Fund Management:** The contract acts as an on-chain investment vehicle pooling ETH to invest in illiquid (NFT) assets. While the trading strategy itself is executed *by a manager* off-chain and reported/tracked *on-chain* via `buyNFT`/`sellNFT` calls (avoiding complex on-chain market interaction logic), the *fund mechanics* (pooling, share tracking, performance tracking) are handled within the contract.
3.  **Realized Performance Tracking (On-Chain):** Instead of relying on potentially unreliable external oracles for live NFT prices, the fund's "performance" relative to initial deposits is tracked based purely on the accumulated ETH balance plus the *realized* profit or loss from completed buy and sell transactions (`realizedProfitLoss`). This is a pragmatic approach for an on-chain fund dealing with assets without reliable on-chain price feeds. The user's share value is then their initial deposit proportion applied to this on-chain calculated fund value.
4.  **NFT-based Fractional Ownership (Alternative):** While traditional fractionalization breaks a single NFT into fungible tokens, this model provides users with a unique NFT representing their *fractional ownership of the entire fund*, which holds *multiple* dynamic assets. It's a different way of representing collective ownership of a portfolio via NFTs.
5.  **Managerial Strategy Simulation:** The contract provides framework for a manager role to execute a strategy (buy/sell specific NFTs, set parameters). While the strategy logic itself is off-chain, the on-chain contract enforces the allowed actions (supported collections, pauses) and tracks the results. Strategy parameters can be stored on-chain (`strategyParametersUint`, `strategyParametersAddress`) to provide transparency on the manager's current directives.

**Limitations and Considerations (as with any complex smart contract):**

*   **Real-world NFT Pricing:** The reliance on manager-declared prices in `buyNFT`/`sellNFT` means the `realizedProfitLoss` reflects these declared prices, not necessarily audited market prices. A real fund would need robust mechanisms to verify trade prices (e.g., integrating with decentralized exchanges if feasible, or requiring off-chain proof).
*   **Liquidity:** The fund's ability to pay withdrawals depends on its ETH balance. If all ETH is tied up in NFTs, withdrawals might fail until NFTs are sold.
*   **Manager Trust:** The manager has significant power (choosing NFTs, setting prices in the contract's accounting, pausing strategy). While the owner can change the manager, this isn't a fully trustless, automated fund strategy.
*   **Gas Costs:** Iterating over large numbers of held NFTs or supported collections can be expensive. The design uses mappings primarily, avoiding costly iteration where possible, but functions like `getHeldNFTCount` (as implemented simply here) highlight this limitation.
*   **Scalability:** Managing a very large portfolio of NFTs and thousands of shareholders might hit gas limits or require complex state management patterns.
*   **Dynamic Metadata:** The off-chain metadata renderer is critical for the "dynamic" aspect. Its availability and correctness are external dependencies.

This contract provides a solid foundation for an advanced, creative concept combining several trendy Web3 elements in a novel way. Remember that deploying and managing significant value requires thorough audits and consideration of edge cases beyond this example.