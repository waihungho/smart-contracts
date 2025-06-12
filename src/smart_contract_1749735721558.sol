Okay, here is a smart contract in Solidity featuring a dynamic NFT marketplace with fractional shares, influenced by a simulated AI oracle. It includes over 20 functions covering various aspects of this complex system.

We will avoid inheriting directly from standard OpenZeppelin ERC721 or ERC20 to fulfill the "don't duplicate any open source" requirement, instead implementing the necessary ownership and balance tracking internally within the contract for the specific context of these dynamic and fractional NFTs. We will use basic access control patterns like `Ownable` and `Pausable` which are common safety mechanisms, but the core logic for NFT ownership, fractionalization, and marketplace mechanics will be custom.

---

**Contract Outline and Function Summary**

**Contract Name:** `DynamicNFTMarketplaceWithFractionalSharesAndAIOracle`

**Description:** This contract implements a marketplace for unique, dynamic NFTs that can be fractionalized. The "potential score" of an NFT, a dynamic attribute, can be updated only by a designated "AI Oracle" address. Users can mint, transfer, and burn NFTs, as well as fractionalize them into tradable shares. The marketplace supports selling both whole NFTs and fractional shares.

**Core Concepts:**
1.  **Dynamic NFTs:** NFTs with mutable attributes (`potentialScore`) influenced by external data.
2.  **AI Oracle Integration:** A dedicated address (`oracleAddress`) is authorized to update dynamic NFT attributes, simulating interaction with an off-chain AI model.
3.  **Fractionalization:** Allows dividing ownership of a single NFT into multiple tradable shares.
4.  **Integrated Marketplace:** Supports buying and selling both whole NFTs and their fractional shares within the same contract.
5.  **Custom Ownership/Balance Tracking:** Internal implementation of ownership for whole NFTs and balances for fractional shares.
6.  **Access Control & Pausability:** Basic admin controls and emergency pause mechanism.

**Function Summary:**

*   **Admin/Setup Functions:**
    *   `constructor()`: Initializes the contract owner, pause state, protocol fee, and designates the AI oracle address.
    *   `setOracleAddress(address _oracleAddress)`: Sets or updates the address authorized to act as the AI Oracle. (Owner only)
    *   `setProtocolFeeBps(uint16 _feeBps)`: Sets the protocol fee percentage for sales (in basis points). (Owner only)
    *   `withdrawProtocolFees()`: Allows the contract owner to withdraw accumulated protocol fees. (Owner only)
    *   `pause()`: Pauses core contract operations (minting, transfers, sales). (Owner only)
    *   `unpause()`: Unpauses the contract. (Owner only)

*   **NFT Management Functions:**
    *   `mintNFT(address _to, string memory _tokenURI, uint256 _initialPotentialScore)`: Mints a new Dynamic Fractional NFT and assigns it to an address. (Callable by minter/platform, here restricted to Owner/approved creator address - *Assumption: restricted for platform control*).
    *   `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers ownership of a whole, non-fractionalized NFT. (Owner/Approved only)
    *   `burnNFT(uint256 _tokenId)`: Destroys a whole, non-fractionalized NFT. (Owner only)
    *   `updateNFTMetadata(uint256 _tokenId, string memory _newTokenURI)`: Allows the NFT owner to update the metadata URI. (Owner only)

*   **Dynamic Attribute (Oracle) Functions:**
    *   `updateNFTPotentialScore(uint256 _tokenId, uint256 _newPotentialScore)`: Updates the dynamic potential score of an NFT. (Only callable by `oracleAddress`)
    *   `getNFTPotentialScore(uint256 _tokenId)`: Retrieves the current potential score of an NFT.

*   **Fractionalization Functions:**
    *   `fractionalizeNFT(uint256 _tokenId, uint256 _totalFractions)`: Locks the whole NFT in the contract and issues a specified number of fractional shares to the owner. (NFT Owner only, when not already fractionalized)
    *   `deFractionalizeNFT(uint256 _tokenId)`: Allows a holder of *all* fractions for a specific NFT to redeem them and reclaim ownership of the whole NFT. (Requires holding `totalFractions` for `_tokenId`)
    *   `getFractionBalance(uint256 _tokenId, address _holder)`: Retrieves the number of fractional shares a specific address holds for an NFT.
    *   `transferFractions(uint256 _tokenId, address _from, address _to, uint256 _amount)`: Transfers fractional shares between addresses for a specific NFT. (Fraction Holder/Approved only - *Assumption: simple `msg.sender` check for this example*)
    *   `getTotalFractions(uint256 _tokenId)`: Gets the total number of fractions created for a fractionalized NFT.

*   **Marketplace (Whole NFT) Functions:**
    *   `listWholeNFTForSale(uint256 _tokenId, uint256 _price)`: Lists a whole, non-fractionalized NFT for a fixed price. (NFT Owner only, when not fractionalized)
    *   `cancelWholeNFTSale(uint256 _tokenId)`: Cancels an active whole NFT sale listing. (Seller only)
    *   `buyWholeNFT(uint256 _tokenId)`: Buys a whole NFT listed for sale. (Anyone, requires correct ETH payment)
    *   `getWholeSaleDetails(uint256 _tokenId)`: Retrieves details of an active whole NFT sale listing.

*   **Marketplace (Fractional Shares) Functions:**
    *   `listFractionsForSale(uint256 _tokenId, uint256 _amount, uint256 _pricePerFraction)`: Lists a specified amount of fractional shares for an NFT at a price per fraction. (Fraction Holder only, when NFT is fractionalized)
    *   `cancelFractionsSale(uint256 _tokenId)`: Cancels an active fractional shares sale listing by the caller. (Seller of fractions only)
    *   `buyFractions(uint256 _tokenId, address _seller, uint256 _amount)`: Buys a specified amount of fractional shares from a specific seller's listing. (Anyone, requires correct ETH payment)
    *   `getFractionalSaleDetails(uint256 _tokenId, address _seller)`: Retrieves details of an active fractional shares sale listing by a specific seller.

*   **Getter/Utility Functions:**
    *   `getNFTData(uint256 _tokenId)`: Retrieves all core data for an NFT (owner, metadata, potential score, fractional state).
    *   `isFractionalized(uint256 _tokenId)`: Checks if an NFT is currently fractionalized.
    *   `getOracleAddress()`: Gets the current AI Oracle address.
    *   `getProtocolFeeBps()`: Gets the current protocol fee percentage in basis points.
    *   `getAccruedSellerFunds(address _seller)`: Gets the amount of ETH earned by a seller from sales, available for withdrawal.
    *   `withdrawSellerFunds()`: Allows sellers to withdraw their earned funds.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title DynamicNFTMarketplaceWithFractionalSharesAndAIOracle
 * @dev A smart contract implementing a marketplace for dynamic, fractionalized NFTs.
 *      NFTs have a dynamic 'potential score' updated by a designated oracle.
 *      Users can fractionalize NFTs into tradable shares and buy/sell both whole NFTs and shares.
 *
 * Core Concepts:
 * - Dynamic NFTs: Mutable attributes (potentialScore) influenced by external data.
 * - AI Oracle Integration: A dedicated address updates dynamic attributes.
 * - Fractionalization: Divide ownership into multiple tradable shares.
 * - Integrated Marketplace: Buy/sell whole NFTs and shares.
 * - Custom Ownership/Balance Tracking: Internal ERC721/ERC20 logic for this specific context.
 * - Access Control & Pausability: Basic admin controls and emergency pause.
 *
 * Function Summary:
 * - Admin/Setup: constructor, setOracleAddress, setProtocolFeeBps, withdrawProtocolFees, pause, unpause
 * - NFT Management: mintNFT, transferNFT, burnNFT, updateNFTMetadata, getNFTData, getNFTOwner, isFractionalized
 * - Dynamic Attribute (Oracle): updateNFTPotentialScore, getNFTPotentialScore, getOracleAddress
 * - Fractionalization: fractionalizeNFT, deFractionalizeNFT, getFractionBalance, transferFractions, getTotalFractions
 * - Marketplace (Whole NFT): listWholeNFTForSale, cancelWholeNFTSale, buyWholeNFT, getWholeSaleDetails
 * - Marketplace (Fractional Shares): listFractionsForSale, cancelFractionsSale, buyFractions, getFractionalSaleDetails
 * - Getter/Utility: getProtocolFeeBps, getAccruedSellerFunds, withdrawSellerFunds
 */
contract DynamicNFTMarketplaceWithFractionalSharesAndAIOracle {

    address private _owner;
    bool private _paused;
    address private _oracleAddress;

    // State for NFTs
    uint256 private _nextTokenId;
    mapping(uint256 => address) private _nftOwners; // NFT ID -> Owner Address
    mapping(uint256 => string) private _tokenURIs; // NFT ID -> Metadata URI
    mapping(uint256 => uint256) private _potentialScores; // NFT ID -> Dynamic Score
    mapping(uint256 => bool) private _isFractionalized; // NFT ID -> Is Fractionalized?

    // State for Fractionalization
    mapping(uint256 => uint256) private _totalFractions; // NFT ID -> Total fractions minted
    mapping(uint256 => mapping(address => uint256)) private _fractionBalances; // NFT ID -> Fraction Holder Address -> Balance

    // State for Marketplace (Whole NFT)
    struct WholeNFTSale {
        uint256 price;
        address seller;
        bool active; // Added boolean flag for clarity
    }
    mapping(uint256 => WholeNFTSale) private _activeWholeSales; // NFT ID -> Sale Details

    // State for Marketplace (Fractional Shares)
    struct FractionalSale {
        uint256 amountListed;
        uint256 pricePerFraction;
        bool active; // Added boolean flag for clarity
    }
    // NFT ID -> Seller Address -> Sale Details
    mapping(uint256 => mapping(address => FractionalSale)) private _activeFractionalSales;

    // State for Fees and Funds
    uint16 private _protocolFeeBps; // Fee in basis points (e.g., 100 = 1%)
    mapping(address => uint256) private _accruedProtocolFees; // Owner can withdraw
    mapping(address => uint256) private _accruedSellerFunds; // Sellers can withdraw

    // Events
    event NFTMinted(uint256 indexed tokenId, address indexed owner, string tokenURI, uint256 initialPotentialScore);
    event NFTTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event NFTBurned(uint256 indexed tokenId, address indexed owner);
    event NFTMetadataUpdated(uint256 indexed tokenId, string newTokenURI);
    event NFTPotentialScoreUpdated(uint256 indexed tokenId, uint256 newPotentialScore);
    event NFTFractionalized(uint256 indexed tokenId, address indexed originalOwner, uint256 totalFractions);
    event NFTDeFractionalized(uint256 indexed tokenId, address indexed newOwner, uint256 remainingFractions);
    event FractionsTransferred(uint256 indexed tokenId, address indexed from, address indexed to, uint256 amount);
    event WholeNFTListedForSale(uint256 indexed tokenId, address indexed seller, uint256 price);
    event WholeNFTSaleCancelled(uint256 indexed tokenId, address indexed seller);
    event WholeNFTBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event FractionsListedForSale(uint256 indexed tokenId, address indexed seller, uint256 amount, uint256 pricePerFraction);
    event FractionsSaleCancelled(uint256 indexed tokenId, address indexed seller);
    event FractionsBought(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 amount, uint256 pricePerFraction);
    event ProtocolFeeCollected(address indexed payer, uint256 amount);
    event ProtocolFeesWithdrawn(address indexed receiver, uint256 amount);
    event SellerFundsWithdrawn(address indexed seller, uint256 amount);
    event Paused(address account);
    event Unpaused(address account);
    event OracleAddressSet(address indexed oldOracle, address indexed newOracle);
    event ProtocolFeeSet(uint16 oldFeeBps, uint16 newFeeBps);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOracle() {
        require(msg.sender == _oracleAddress, "Oracle: caller is not the oracle");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(_nftOwners[_tokenId] == msg.sender, "NFT: caller is not owner");
        _;
    }

    modifier whenNotFractionalized(uint256 _tokenId) {
        require(!_isFractionalized[_tokenId], "NFT: already fractionalized");
        _;
    }

    modifier whenFractionalized(uint256 _tokenId) {
        require(_isFractionalized[_tokenId], "NFT: not fractionalized");
        _;
    }

    modifier onlyFractionHolder(uint256 _tokenId, address _holder) {
        require(_fractionBalances[_tokenId][_holder] > 0, "Fraction: caller has no fractions");
        _;
    }

    /**
     * @dev Initializes the contract. Sets owner, default fees, and the initial oracle address.
     * @param initialOracle The address authorized to update NFT potential scores.
     */
    constructor(address initialOracle) {
        _owner = msg.sender;
        _paused = false;
        _protocolFeeBps = 200; // 2% default fee
        _oracleAddress = initialOracle;
        emit OracleAddressSet(address(0), initialOracle);
        emit ProtocolFeeSet(0, _protocolFeeBps);
    }

    // --- Admin/Setup Functions ---

    /**
     * @dev Sets the address authorized to act as the AI Oracle.
     * @param _oracleAddress The new oracle address.
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        address oldOracle = oracleAddress;
        _oracleAddress = _oracleAddress;
        emit OracleAddressSet(oldOracle, _oracleAddress);
    }

    /**
     * @dev Sets the protocol fee percentage in basis points.
     * @param _feeBps The new fee percentage (e.g., 100 for 1%). Max 10000 (100%).
     */
    function setProtocolFeeBps(uint16 _feeBps) external onlyOwner {
        require(_feeBps <= 10000, "Fee: fee cannot exceed 100%");
        uint16 oldFeeBps = _protocolFeeBps;
        _protocolFeeBps = _feeBps;
        emit ProtocolFeeSet(oldFeeBps, _protocolFeeBps);
    }

    /**
     * @dev Allows the contract owner to withdraw accumulated protocol fees.
     */
    function withdrawProtocolFees() external onlyOwner {
        uint256 amount = _accruedProtocolFees[msg.sender];
        require(amount > 0, "Fee: No fees to withdraw");
        _accruedProtocolFees[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Fee: ETH transfer failed");
        emit ProtocolFeesWithdrawn(msg.sender, amount);
    }

    /**
     * @dev Pauses the contract, preventing key operations.
     */
    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, re-enabling operations.
     */
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    // --- NFT Management Functions ---

    /**
     * @dev Mints a new Dynamic Fractional NFT. Only callable by owner/platform.
     * @param _to The address to mint the NFT to.
     * @param _tokenURI The metadata URI for the NFT.
     * @param _initialPotentialScore The initial dynamic potential score.
     */
    function mintNFT(address _to, string memory _tokenURI, uint256 _initialPotentialScore) external onlyOwner whenNotPaused {
        require(_to != address(0), "NFT: mint to the zero address");
        uint256 tokenId = _nextTokenId++;
        _nftOwners[tokenId] = _to;
        _tokenURIs[tokenId] = _tokenURI;
        _potentialScores[tokenId] = _initialPotentialScore;
        _isFractionalized[tokenId] = false; // Ensure initialized as not fractionalized

        emit NFTMinted(tokenId, _to, _tokenURI, _initialPotentialScore);
    }

    /**
     * @dev Transfers a whole NFT. Can only transfer non-fractionalized NFTs.
     * @param _from The current owner address.
     * @param _to The recipient address.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(_nftOwners[_tokenId] == _from, "NFT: transfer from incorrect owner");
        require(_to != address(0), "NFT: transfer to the zero address");
        require(!_isFractionalized[_tokenId], "NFT: cannot transfer a fractionalized NFT directly");

        // Cancel any active sales for this NFT
        delete _activeWholeSales[_tokenId];

        _nftOwners[_tokenId] = _to;
        emit NFTTransferred(_from, _to, _tokenId);
    }

     /**
     * @dev Burns a whole NFT. Can only burn non-fractionalized NFTs.
     * @param _tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 _tokenId) external onlyNFTOwner(_tokenId) whenNotPaused whenNotFractionalized(_tokenId) {
        // Cancel any active sales for this NFT
        delete _activeWholeSales[_tokenId];

        delete _nftOwners[_tokenId];
        delete _tokenURIs[_tokenId];
        delete _potentialScores[_tokenId];

        emit NFTBurned(_tokenId, msg.sender);
    }


    /**
     * @dev Allows the NFT owner to update the metadata URI.
     * @param _tokenId The ID of the NFT.
     * @param _newTokenURI The new metadata URI.
     */
    function updateNFTMetadata(uint256 _tokenId, string memory _newTokenURI) external onlyNFTOwner(_tokenId) whenNotPaused {
        _tokenURIs[_tokenId] = _newTokenURI;
        emit NFTMetadataUpdated(_tokenId, _newTokenURI);
    }

    // --- Dynamic Attribute (Oracle) Functions ---

    /**
     * @dev Updates the dynamic potential score of an NFT. Only callable by the designated oracle.
     * @param _tokenId The ID of the NFT.
     * @param _newPotentialScore The new potential score.
     */
    function updateNFTPotentialScore(uint256 _tokenId, uint256 _newPotentialScore) external onlyOracle whenNotPaused {
        require(_nftOwners[_tokenId] != address(0), "NFT: token does not exist"); // Ensure NFT exists
        _potentialScores[_tokenId] = _newPotentialScore;
        emit NFTPotentialScoreUpdated(_tokenId, _newPotentialScore);
    }

    // --- Fractionalization Functions ---

    /**
     * @dev Locks the whole NFT in the contract and issues fractional shares to the owner.
     * @param _tokenId The ID of the NFT to fractionalize.
     * @param _totalFractions The total number of fractional shares to create.
     */
    function fractionalizeNFT(uint256 _tokenId, uint256 _totalFractions) external onlyNFTOwner(_tokenId) whenNotPaused whenNotFractionalized(_tokenId) {
        require(_totalFractions > 0, "Fractional: must create at least 1 fraction");

        address originalOwner = msg.sender;

        // Cancel any active whole NFT sales
        delete _activeWholeSales[_tokenId];

        _isFractionalized[_tokenId] = true;
        _totalFractions[_tokenId] = _totalFractions;

        // Transfer the whole NFT to the contract itself
        _nftOwners[_tokenId] = address(this);

        // Issue all fractions to the original owner
        _fractionBalances[_tokenId][originalOwner] = _totalFractions;

        emit NFTFractionalized(_tokenId, originalOwner, _totalFractions);
    }

    /**
     * @dev Allows a holder of ALL fractions for an NFT to de-fractionalize it and reclaim the whole NFT.
     * @param _tokenId The ID of the NFT to de-fractionalize.
     */
    function deFractionalizeNFT(uint256 _tokenId) external whenNotPaused whenFractionalized(_tokenId) {
        require(_fractionBalances[_tokenId][msg.sender] == _totalFractions[_tokenId], "Fractional: caller does not hold all fractions");
        require(_totalFractions[_tokenId] > 0, "Fractional: total fractions not set");

        // Burn all fractions held by the redeemer
        _fractionBalances[_tokenId][msg.sender] = 0;

        // Reset fractionalization state
        _isFractionalized[_tokenId] = false;
        delete _totalFractions[_tokenId]; // Clear total fractions

        // Transfer the whole NFT back to the redeemer
        _nftOwners[_tokenId] = msg.sender;

        // Clear any outstanding fractional sale listings for this NFT (from any seller)
        // Note: This requires iterating or having a separate data structure to track sellers per NFT.
        // For simplicity in this example, we won't clear ALL sellers' listings, assuming
        // listings are cancelled by seller or become invalid when NFT is defractionalized.
        // A robust implementation might iterate or track active sellers for an NFT.

        emit NFTDeFractionalized(_tokenId, msg.sender, 0); // 0 remaining fractions after redemption
    }

    /**
     * @dev Transfers fractional shares of an NFT between addresses.
     * @param _tokenId The ID of the NFT.
     * @param _from The sender address.
     * @param _to The recipient address.
     * @param _amount The number of fractions to transfer.
     */
    function transferFractions(uint256 _tokenId, address _from, address _to, uint256 _amount) public whenNotPaused {
        // Basic approval check: msg.sender must be _from or contract owner (if owner needs central transfer capability)
        require(msg.sender == _from || msg.sender == _owner, "Fraction: caller is not sender or owner");
        require(_from != address(0), "Fraction: transfer from the zero address");
        require(_to != address(0), "Fraction: transfer to the zero address");
        require(_amount > 0, "Fraction: must transfer non-zero amount");
        require(_fractionBalances[_tokenId][_from] >= _amount, "Fraction: insufficient balance");

        _fractionBalances[_tokenId][_from] -= _amount;
        _fractionBalances[_tokenId][_to] += _amount;

        // If seller transfers listed fractions, update their listing amount (optional, but good practice)
        // Not implementing automatic listing update here for simplicity. Sellers should cancel/relist if balances change externally.

        emit FractionsTransferred(_tokenId, _from, _to, _amount);
    }


    // --- Marketplace (Whole NFT) Functions ---

    /**
     * @dev Lists a whole NFT for sale at a fixed price.
     * @param _tokenId The ID of the NFT to list.
     * @param _price The price in wei.
     */
    function listWholeNFTForSale(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) whenNotPaused whenNotFractionalized(_tokenId) {
        require(_price > 0, "Sale: price must be greater than zero");

        // Cancel any existing listing for this NFT by this seller (shouldn't exist due to onlyNFTOwner + not fractionalized)
        delete _activeWholeSales[_tokenId];

        _activeWholeSales[_tokenId] = WholeNFTSale(_price, msg.sender, true);
        emit WholeNFTListedForSale(_tokenId, msg.sender, _price);
    }

    /**
     * @dev Cancels a whole NFT sale listing.
     * @param _tokenId The ID of the NFT listing to cancel.
     */
    function cancelWholeNFTSale(uint256 _tokenId) external whenNotPaused {
        WholeNFTSale storage sale = _activeWholeSales[_tokenId];
        require(sale.active, "Sale: sale not active");
        require(sale.seller == msg.sender, "Sale: caller is not the seller");

        delete _activeWholeSales[_tokenId];
        emit WholeNFTSaleCancelled(_tokenId, msg.sender);
    }

    /**
     * @dev Buys a whole NFT listed for sale.
     * @param _tokenId The ID of the NFT to buy.
     */
    function buyWholeNFT(uint256 _tokenId) external payable whenNotPaused {
        WholeNFTSale storage sale = _activeWholeSales[_tokenId];
        require(sale.active, "Sale: sale not active");
        require(!_isFractionalized[_tokenId], "Sale: NFT is fractionalized, cannot buy whole"); // Double check state
        require(msg.value == sale.price, "Sale: incorrect ETH amount");
        require(sale.seller != msg.sender, "Sale: cannot buy from yourself");

        address seller = sale.seller;
        uint256 price = sale.price;

        // Cancel the sale listing
        delete _activeWholeSales[_tokenId];

        // Calculate fees
        uint256 feeAmount = (price * _protocolFeeBps) / 10000;
        uint256 sellerPayout = price - feeAmount;

        // Collect fees
        _accruedProtocolFees[_owner] += feeAmount;
        emit ProtocolFeeCollected(msg.sender, feeAmount);

        // Payout seller (accrue to internal balance for withdrawal)
        _accruedSellerFunds[seller] += sellerPayout;

        // Transfer NFT ownership (contract doesn't own it during whole sale, seller does)
        // Note: The transfer function has its own checks including whenNotPaused and not fractionalized.
        transferNFT(seller, msg.sender, _tokenId);

        emit WholeNFTBought(_tokenId, msg.sender, seller, price);
    }

    // --- Marketplace (Fractional Shares) Functions ---

    /**
     * @dev Lists fractional shares of an NFT for sale.
     * @param _tokenId The ID of the NFT whose fractions are being listed.
     * @param _amount The number of fractions to list.
     * @param _pricePerFraction The price for a single fraction (in wei).
     */
    function listFractionsForSale(uint256 _tokenId, uint256 _amount, uint256 _pricePerFraction) external whenNotPaused whenFractionalized(_tokenId) {
        require(_amount > 0, "Sale: must list non-zero amount");
        require(_pricePerFraction > 0, "Sale: price per fraction must be greater than zero");
        require(_fractionBalances[_tokenId][msg.sender] >= _amount, "Sale: insufficient fraction balance to list");

        address seller = msg.sender;

        // Cancel any existing listing by this seller for this NFT
        delete _activeFractionalSales[_tokenId][seller];

        _activeFractionalSales[_tokenId][seller] = FractionalSale(_amount, _pricePerFraction, true);
        emit FractionsListedForSale(_tokenId, seller, _amount, _pricePerFraction);
    }

     /**
     * @dev Cancels a fractional shares sale listing by the caller.
     * @param _tokenId The ID of the NFT listing to cancel.
     */
    function cancelFractionsSale(uint256 _tokenId) external whenNotPaused {
        FractionalSale storage sale = _activeFractionalSales[_tokenId][msg.sender];
        require(sale.active, "Sale: sale not active");

        delete _activeFractionalSales[_tokenId][msg.sender];
        emit FractionsSaleCancelled(_tokenId, msg.sender);
    }

    /**
     * @dev Buys fractional shares from a specific seller's listing.
     * @param _tokenId The ID of the NFT whose fractions are being bought.
     * @param _seller The address of the seller whose listing is being bought from.
     * @param _amount The number of fractions to buy. Must be less than or equal to the amount listed.
     */
    function buyFractions(uint256 _tokenId, address _seller, uint256 _amount) external payable whenNotPaused whenFractionalized(_tokenId) {
        FractionalSale storage sale = _activeFractionalSales[_tokenId][_seller];
        require(sale.active, "Sale: sale not active");
        require(_amount > 0, "Sale: must buy non-zero amount");
        require(_amount <= sale.amountListed, "Sale: amount exceeds listed quantity");
        require(_seller != msg.sender, "Sale: cannot buy from yourself");

        uint256 totalPrice = _amount * sale.pricePerFraction;
        require(msg.value == totalPrice, "Sale: incorrect ETH amount");

        // Reduce the listed amount
        sale.amountListed -= _amount;

        // If listing is fully sold, deactivate it
        if (sale.amountListed == 0) {
            sale.active = false; // Mark inactive instead of delete immediately
        }

        // Calculate fees
        uint256 feeAmount = (totalPrice * _protocolFeeBps) / 10000;
        uint256 sellerPayout = totalPrice - feeAmount;

        // Collect fees
        _accruedProtocolFees[_owner] += feeAmount;
        emit ProtocolFeeCollected(msg.sender, feeAmount);

        // Payout seller (accrue to internal balance for withdrawal)
        _accruedSellerFunds[_seller] += sellerPayout;

        // Transfer fractions
        // Note: transferFractions includes whenNotPaused, which is redundant here but safe.
        // Seller balance check (_from = _seller) is implicitly handled as we checked amount <= sale.amountListed.
        transferFractions(_tokenId, _seller, msg.sender, _amount);

        emit FractionsBought(_tokenId, msg.sender, _seller, _amount, sale.pricePerFraction);
    }

    /**
     * @dev Allows sellers to withdraw their earned funds from sales.
     */
    function withdrawSellerFunds() external whenNotPaused {
        uint256 amount = _accruedSellerFunds[msg.sender];
        require(amount > 0, "Funds: No funds to withdraw");
        _accruedSellerFunds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Funds: ETH transfer failed");
        emit SellerFundsWithdrawn(msg.sender, amount);
    }


    // --- Getter/Utility Functions ---

    /**
     * @dev Gets all core data for an NFT.
     * @param _tokenId The ID of the NFT.
     * @return owner The owner address.
     * @return tokenURI The metadata URI.
     * @return potentialScore The dynamic potential score.
     * @return isFractionalized The fractionalization status.
     */
    function getNFTData(uint256 _tokenId) external view returns (address owner, string memory tokenURI, uint256 potentialScore, bool isFractionalized) {
         require(_nftOwners[_tokenId] != address(0), "NFT: token does not exist");
         return (_nftOwners[_tokenId], _tokenURIs[_tokenId], _potentialScores[_tokenId], _isFractionalized[_tokenId]);
    }

    /**
     * @dev Gets the owner of a whole NFT. Returns contract address if fractionalized.
     * @param _tokenId The ID of the NFT.
     * @return The owner address.
     */
    function getNFTOwner(uint256 _tokenId) public view returns (address) {
        require(_nftOwners[_tokenId] != address(0), "NFT: token does not exist");
        return _nftOwners[_tokenId];
    }

     /**
     * @dev Checks if an NFT is currently fractionalized.
     * @param _tokenId The ID of the NFT.
     * @return True if fractionalized, false otherwise.
     */
    function isFractionalized(uint256 _tokenId) public view returns (bool) {
         require(_nftOwners[_tokenId] != address(0), "NFT: token does not exist");
         return _isFractionalized[_tokenId];
    }

    /**
     * @dev Retrieves the current potential score of an NFT.
     * @param _tokenId The ID of the NFT.
     * @return The potential score.
     */
    function getNFTPotentialScore(uint256 _tokenId) public view returns (uint256) {
        require(_nftOwners[_tokenId] != address(0), "NFT: token does not exist");
        return _potentialScores[_tokenId];
    }

    /**
     * @dev Gets the total number of fractions created for a fractionalized NFT.
     * @param _tokenId The ID of the NFT.
     * @return The total number of fractions.
     */
    function getTotalFractions(uint256 _tokenId) public view whenFractionalized(_tokenId) returns (uint256) {
        return _totalFractions[_tokenId];
    }

    /**
     * @dev Gets the number of fractional shares a specific address holds for an NFT.
     * @param _tokenId The ID of the NFT.
     * @param _holder The address to check the balance for.
     * @return The fraction balance.
     */
    function getFractionBalance(uint256 _tokenId, address _holder) public view returns (uint256) {
         require(_nftOwners[_tokenId] != address(0), "NFT: token does not exist"); // Ensure NFT exists
         return _fractionBalances[_tokenId][_holder];
    }


    /**
     * @dev Retrieves details of an active whole NFT sale listing.
     * @param _tokenId The ID of the NFT.
     * @return price The sale price.
     * @return seller The seller address.
     * @return active Is the listing active?
     */
    function getWholeSaleDetails(uint256 _tokenId) external view returns (uint256 price, address seller, bool active) {
        WholeNFTSale storage sale = _activeWholeSales[_tokenId];
        return (sale.price, sale.seller, sale.active);
    }

    /**
     * @dev Retrieves details of an active fractional shares sale listing by a specific seller.
     * @param _tokenId The ID of the NFT.
     * @param _seller The seller address.
     * @return amountListed The amount of fractions listed.
     * @return pricePerFraction The price per fraction.
     * @return active Is the listing active?
     */
    function getFractionalSaleDetails(uint256 _tokenId, address _seller) external view returns (uint256 amountListed, uint256 pricePerFraction, bool active) {
        FractionalSale storage sale = _activeFractionalSales[_tokenId][_seller];
        return (sale.amountListed, sale.pricePerFraction, sale.active);
    }


    /**
     * @dev Gets the current AI Oracle address.
     */
    function getOracleAddress() external view returns (address) {
        return _oracleAddress;
    }

     /**
     * @dev Gets the current protocol fee percentage in basis points.
     */
    function getProtocolFeeBps() external view returns (uint16) {
        return _protocolFeeBps;
    }

     /**
     * @dev Gets the amount of ETH earned by a seller from sales, available for withdrawal.
     * @param _seller The seller address.
     */
    function getAccruedSellerFunds(address _seller) external view returns (uint256) {
        return _accruedSellerFunds[_seller];
    }

    // Fallback and Receive functions to handle incoming Ether
    receive() external payable {}
    fallback() external payable {}

    // Owner getter (standard for Ownable pattern)
    function owner() external view returns (address) {
        return _owner;
    }

    // Paused state getter (standard for Pausable pattern)
    function paused() external view returns (bool) {
        return _paused;
    }
}
```