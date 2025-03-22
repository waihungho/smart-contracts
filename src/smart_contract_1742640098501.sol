```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic NFT Marketplace with AI Art Generation & Fractionalization
 * @author Bard (AI Assistant)
 * @dev This contract implements a unique NFT marketplace that integrates dynamic NFTs,
 *      AI-assisted art generation suggestions, and fractionalization capabilities.
 *      It aims to provide a platform for artists to create evolving NFTs, leverage AI for
 *      creative inspiration, and offer fractional ownership to their communities.
 *
 * **Outline:**
 *
 * 1. **Core NFT Marketplace Functions:**
 *    - `createDynamicNFT`: Mints a new Dynamic NFT with initial metadata and AI suggestions.
 *    - `listNFTForSale`: Allows NFT owners to list their NFTs for sale at a fixed price.
 *    - `buyNFT`: Allows users to purchase listed NFTs.
 *    - `cancelNFTSale`: Allows owners to cancel their NFT listing.
 *    - `makeOfferForNFT`: Allows users to make offers on NFTs that are not listed.
 *    - `acceptOfferForNFT`: Allows NFT owners to accept a specific offer.
 *    - `updateNFTListingPrice`: Allows owners to update the listed price of their NFT.
 *
 * 2. **Dynamic NFT Evolution Functions:**
 *    - `evolveNFTMetadata`: Allows NFT owners to trigger a metadata evolution based on certain on-chain conditions or user interactions.
 *    - `addTraitToNFT`: Allows adding new traits or attributes to the NFT's metadata.
 *    - `removeTraitFromNFT`: Allows removing existing traits or attributes from the NFT's metadata.
 *    - `setNFTExternalURI`: Allows setting an external URI for more complex metadata updates.
 *
 * 3. **AI Art Suggestion Integration (Simulated):**
 *    - `requestAISuggestion`: Simulates requesting an AI to suggest art traits or ideas based on current NFT metadata. (Off-chain AI integration is assumed).
 *    - `applyAISuggestion`: Allows NFT owner to apply an AI-suggested trait or metadata update.
 *
 * 4. **NFT Fractionalization Functions:**
 *    - `fractionalizeNFT`: Allows NFT owners to fractionalize their NFT into ERC20 tokens.
 *    - `redeemFractionalNFT`: Allows holders of fractional tokens to redeem and collectively own the original NFT (requires reaching 100% ownership).
 *    - `transferFractionalTokens`: Standard ERC20 token transfer for fractional tokens.
 *    - `getFractionalTokenBalance`: Returns the balance of fractional tokens for a user.
 *    - `getTotalFractionalSupply`: Returns the total supply of fractional tokens for an NFT.
 *
 * 5. **Platform Utility Functions:**
 *    - `setPlatformFee`: Allows the contract owner to set the platform fee percentage.
 *    - `withdrawPlatformFees`: Allows the contract owner to withdraw accumulated platform fees.
 *    - `pauseContract`: Allows the contract owner to pause core marketplace functions.
 *    - `unpauseContract`: Allows the contract owner to unpause core marketplace functions.
 *
 * **Function Summary:**
 *
 * - `createDynamicNFT(string memory _name, string memory _description, string memory _initialMetadata)`: Mints a new Dynamic NFT.
 * - `listNFTForSale(uint256 _tokenId, uint256 _price)`: Lists an NFT for sale.
 * - `buyNFT(uint256 _tokenId)`: Buys a listed NFT.
 * - `cancelNFTSale(uint256 _tokenId)`: Cancels an NFT listing.
 * - `makeOfferForNFT(uint256 _tokenId)`: Makes an offer for an unlisted NFT.
 * - `acceptOfferForNFT(uint256 _tokenId, uint256 _offerIndex)`: Accepts a specific offer.
 * - `updateNFTListingPrice(uint256 _tokenId, uint256 _newPrice)`: Updates NFT listing price.
 * - `evolveNFTMetadata(uint256 _tokenId, string memory _evolutionData)`: Triggers NFT metadata evolution.
 * - `addTraitToNFT(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: Adds a trait to NFT metadata.
 * - `removeTraitFromNFT(uint256 _tokenId, string memory _traitName)`: Removes a trait from NFT metadata.
 * - `setNFTExternalURI(uint256 _tokenId, string memory _externalURI)`: Sets an external URI for NFT metadata.
 * - `requestAISuggestion(uint256 _tokenId)`: Requests AI art suggestions (simulated).
 * - `applyAISuggestion(uint256 _tokenId, string memory _suggestionData)`: Applies AI suggestions to NFT metadata.
 * - `fractionalizeNFT(uint256 _tokenId, uint256 _fractionalSupply)`: Fractionalizes an NFT.
 * - `redeemFractionalNFT(uint256 _tokenId)`: Redeems fractional tokens to claim NFT ownership.
 * - `transferFractionalTokens(uint256 _tokenId, address _recipient, uint256 _amount)`: Transfers fractional tokens.
 * - `getFractionalTokenBalance(uint256 _tokenId, address _account)`: Gets fractional token balance.
 * - `getTotalFractionalSupply(uint256 _tokenId)`: Gets total fractional token supply.
 * - `setPlatformFee(uint256 _feePercentage)`: Sets platform fee percentage.
 * - `withdrawPlatformFees()`: Withdraws platform fees.
 * - `pauseContract()`: Pauses contract functions.
 * - `unpauseContract()`: Unpauses contract functions.
 */

contract DynamicNFTMarketplace {
    // State Variables

    // Contract Owner
    address public owner;

    // NFT Contract Name and Symbol
    string public nftName = "DynamicArtNFT";
    string public nftSymbol = "DANFT";

    // NFT Token Counter
    uint256 public tokenCounter;

    // Mapping from Token ID to NFT details
    struct NFT {
        uint256 tokenId;
        address owner;
        string name;
        string description;
        string metadataURI; // Initial Metadata URI
        string dynamicMetadata; // Dynamic metadata (can be updated)
        bool isFractionalized;
        address fractionalTokenContract;
    }
    mapping(uint256 => NFT) public NFTs;
    mapping(uint256 => bool) public existsNFT;

    // Marketplace Listings
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public NFTListings;
    mapping(uint256 => bool) public isListed;

    // Offers for NFTs
    struct Offer {
        address offerer;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Offer[]) public NFTOffers;

    // Platform Fee
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public accumulatedPlatformFees;

    // Contract Paused State
    bool public paused = false;

    // Events
    event NFTCreated(uint256 tokenId, address owner, string name);
    event NFTListed(uint256 tokenId, address seller, uint256 price);
    event NFTBought(uint256 tokenId, address buyer, uint256 price);
    event NFTListingCancelled(uint256 tokenId);
    event OfferMade(uint256 tokenId, address offerer, uint256 price);
    event OfferAccepted(uint256 tokenId, address seller, address buyer, uint256 price);
    event NFTMetadataEvolved(uint256 tokenId, string evolutionData);
    event NFTFractionalized(uint256 tokenId, address fractionalTokenContract, uint256 totalSupply);
    event NFTFractionalRedeemed(uint256 tokenId, address redeemer);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(existsNFT[_tokenId], "NFT does not exist.");
        _;
    }

    modifier isNFTOwner(uint256 _tokenId) {
        require(NFTs[_tokenId].owner == msg.sender, "You are not the NFT owner.");
        _;
    }

    modifier isNFTNotFractionalized(uint256 _tokenId) {
        require(!NFTs[_tokenId].isFractionalized, "NFT is already fractionalized.");
        _;
    }

    modifier isNFTFractionalized(uint256 _tokenId) {
        require(NFTs[_tokenId].isFractionalized, "NFT is not fractionalized.");
        _;
    }

    modifier listingExists(uint256 _tokenId) {
        require(isListed[_tokenId] && NFTListings[_tokenId].isActive, "NFT is not listed for sale.");
        _;
    }

    modifier notListed(uint256 _tokenId) {
        require(!isListed[_tokenId] || !NFTListings[_tokenId].isActive, "NFT is already listed for sale.");
        _;
    }


    constructor() {
        owner = msg.sender;
        tokenCounter = 0;
    }

    // 1. Core NFT Marketplace Functions

    /// @dev Mints a new Dynamic NFT with initial metadata.
    /// @param _name The name of the NFT.
    /// @param _description The description of the NFT.
    /// @param _initialMetadata The initial metadata URI for the NFT.
    function createDynamicNFT(
        string memory _name,
        string memory _description,
        string memory _initialMetadata
    ) public whenNotPaused returns (uint256) {
        tokenCounter++;
        uint256 newTokenId = tokenCounter;

        NFTs[newTokenId] = NFT({
            tokenId: newTokenId,
            owner: msg.sender,
            name: _name,
            description: _description,
            metadataURI: _initialMetadata,
            dynamicMetadata: _initialMetadata, // Initially dynamic metadata is the same as initial
            isFractionalized: false,
            fractionalTokenContract: address(0)
        });
        existsNFT[newTokenId] = true;

        emit NFTCreated(newTokenId, msg.sender, _name);
        return newTokenId;
    }

    /// @dev Lists an NFT for sale at a fixed price.
    /// @param _tokenId The ID of the NFT to list.
    /// @param _price The listing price in wei.
    function listNFTForSale(uint256 _tokenId, uint256 _price)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
        notListed(_tokenId)
        isNFTNotFractionalized(_tokenId)
    {
        NFTListings[_tokenId] = Listing({
            tokenId: _tokenId,
            seller: msg.sender,
            price: _price,
            isActive: true
        });
        isListed[_tokenId] = true;
        emit NFTListed(_tokenId, msg.sender, _price);
    }

    /// @dev Allows a user to buy a listed NFT.
    /// @param _tokenId The ID of the NFT to buy.
    function buyNFT(uint256 _tokenId)
        public
        payable
        whenNotPaused
        listingExists(_tokenId)
    {
        Listing storage listing = NFTListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy NFT.");
        require(listing.seller != msg.sender, "Seller cannot buy their own NFT.");

        // Transfer NFT ownership
        NFTs[_tokenId].owner = msg.sender;
        NFTs[_tokenId].dynamicMetadata = NFTs[_tokenId].metadataURI; // Reset dynamic metadata on transfer (example behavior)

        // Transfer funds to seller and platform fee
        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 sellerPayout = listing.price - platformFee;

        (bool successSeller, ) = payable(listing.seller).call{value: sellerPayout}("");
        require(successSeller, "Seller payment failed.");

        accumulatedPlatformFees += platformFee;

        // Deactivate listing
        listing.isActive = false;
        isListed[_tokenId] = false;

        emit NFTBought(_tokenId, msg.sender, listing.price);
    }

    /// @dev Allows the NFT owner to cancel their NFT listing.
    /// @param _tokenId The ID of the NFT to cancel the listing for.
    function cancelNFTSale(uint256 _tokenId)
        public
        whenNotPaused
        listingExists(_tokenId)
        isNFTOwner(_tokenId)
    {
        NFTListings[_tokenId].isActive = false;
        isListed[_tokenId] = false;
        emit NFTListingCancelled(_tokenId);
    }

    /// @dev Allows users to make an offer on an NFT that is not listed for sale.
    /// @param _tokenId The ID of the NFT to make an offer on.
    function makeOfferForNFT(uint256 _tokenId)
        public
        payable
        whenNotPaused
        nftExists(_tokenId)
        notListed(_tokenId) // Only allow offers on unlisted NFTs (optional, can be removed to allow offers on listed as well)
    {
        NFTOffers[_tokenId].push(Offer({
            offerer: msg.sender,
            price: msg.value,
            isActive: true
        }));
        emit OfferMade(_tokenId, msg.sender, msg.value);
    }

    /// @dev Allows the NFT owner to accept a specific offer for their NFT.
    /// @param _tokenId The ID of the NFT for which to accept an offer.
    /// @param _offerIndex The index of the offer in the NFTOffers array.
    function acceptOfferForNFT(uint256 _tokenId, uint256 _offerIndex)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
    {
        require(_offerIndex < NFTOffers[_tokenId].length, "Invalid offer index.");
        Offer storage offer = NFTOffers[_tokenId][_offerIndex];
        require(offer.isActive, "Offer is not active.");

        // Transfer NFT ownership
        NFTs[_tokenId].owner = offer.offerer;
        NFTs[_tokenId].dynamicMetadata = NFTs[_tokenId].metadataURI; // Reset dynamic metadata on transfer (example behavior)

        // Transfer funds to seller and platform fee
        uint256 platformFee = (offer.price * platformFeePercentage) / 100;
        uint256 sellerPayout = offer.price - platformFee;

        (bool successSeller, ) = payable(msg.sender).call{value: sellerPayout}(""); // Seller is msg.sender here
        require(successSeller, "Seller payment failed.");

        accumulatedPlatformFees += platformFee;

        // Deactivate the accepted offer and all other offers for this NFT (optional, can keep other offers active)
        for (uint256 i = 0; i < NFTOffers[_tokenId].length; i++) {
            NFTOffers[_tokenId][i].isActive = false;
        }

        emit OfferAccepted(_tokenId, msg.sender, offer.offerer, offer.price);
    }

    /// @dev Allows the NFT owner to update the listed price of their NFT.
    /// @param _tokenId The ID of the NFT to update the price for.
    /// @param _newPrice The new listing price in wei.
    function updateNFTListingPrice(uint256 _tokenId, uint256 _newPrice)
        public
        whenNotPaused
        listingExists(_tokenId)
        isNFTOwner(_tokenId)
    {
        NFTListings[_tokenId].price = _newPrice;
        emit NFTListed(_tokenId, msg.sender, _newPrice); // Re-emit NFTListed event with new price for off-chain updates
    }


    // 2. Dynamic NFT Evolution Functions

    /// @dev Allows the NFT owner to evolve the NFT's metadata based on some data.
    /// @param _tokenId The ID of the NFT to evolve.
    /// @param _evolutionData Data describing the evolution (e.g., new traits, story progression, etc.).
    function evolveNFTMetadata(uint256 _tokenId, string memory _evolutionData)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
        isNFTNotFractionalized(_tokenId) // Prevent evolution of fractionalized NFTs for simplicity
    {
        // In a real application, this function would contain logic to update the NFT's dynamicMetadata
        // based on _evolutionData and potentially other on-chain factors (e.g., time, interactions, etc.).
        // This could involve updating a JSON structure stored in `dynamicMetadata` or pointing to a new metadata URI.

        // For this example, we simply append the _evolutionData to the dynamicMetadata.
        NFTs[_tokenId].dynamicMetadata = string(abi.encodePacked(NFTs[_tokenId].dynamicMetadata, " | Evolved: ", _evolutionData));

        emit NFTMetadataEvolved(_tokenId, _evolutionData);
    }

    /// @dev Adds a new trait or attribute to the NFT's metadata.
    /// @param _tokenId The ID of the NFT to add the trait to.
    /// @param _traitName The name of the trait.
    /// @param _traitValue The value of the trait.
    function addTraitToNFT(uint256 _tokenId, string memory _traitName, string memory _traitValue)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
        isNFTNotFractionalized(_tokenId)
    {
        // Example: Append to dynamicMetadata as key-value pair (simple text-based metadata for demonstration)
        NFTs[_tokenId].dynamicMetadata = string(abi.encodePacked(NFTs[_tokenId].dynamicMetadata, " | ", _traitName, ": ", _traitValue));
        emit NFTMetadataEvolved(_tokenId, string(abi.encodePacked("Trait Added: ", _traitName, ": ", _traitValue)));
    }

    /// @dev Removes a trait or attribute from the NFT's metadata.
    /// @param _tokenId The ID of the NFT to remove the trait from.
    /// @param _traitName The name of the trait to remove.
    function removeTraitFromNFT(uint256 _tokenId, string memory _traitName)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
        isNFTNotFractionalized(_tokenId)
    {
        // In a more robust implementation, you'd need to parse and modify a structured metadata format (e.g., JSON).
        // For this simple example, we'll just append a "Removed" note.
        NFTs[_tokenId].dynamicMetadata = string(abi.encodePacked(NFTs[_tokenId].dynamicMetadata, " | Trait Removed: ", _traitName));
        emit NFTMetadataEvolved(_tokenId, string(abi.encodePacked("Trait Removed: ", _traitName)));
    }

    /// @dev Sets an external URI as the metadata for the NFT. Useful for complex metadata updates.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _externalURI The new external URI for the NFT's metadata.
    function setNFTExternalURI(uint256 _tokenId, string memory _externalURI)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
        isNFTNotFractionalized(_tokenId)
    {
        NFTs[_tokenId].dynamicMetadata = _externalURI; // Set dynamicMetadata to the external URI
        NFTs[_tokenId].metadataURI = _externalURI; // Optionally update the base metadataURI as well
        emit NFTMetadataEvolved(_tokenId, string(abi.encodePacked("External URI Set: ", _externalURI)));
    }


    // 3. AI Art Suggestion Integration (Simulated)

    /// @dev Simulates requesting AI suggestions for the NFT based on its current metadata.
    /// @param _tokenId The ID of the NFT to request suggestions for.
    function requestAISuggestion(uint256 _tokenId)
        public
        view
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
    returns (string memory) {
        // In a real-world scenario, this function would likely trigger an off-chain AI service.
        // The AI service would analyze the NFT's `dynamicMetadata` and generate suggestions for new traits,
        // stylistic changes, or even new visual elements.

        // For this simulation, we return a placeholder suggestion based on the NFT's name.
        return string(abi.encodePacked("AI Suggestion for NFT '", NFTs[_tokenId].name, "': Consider adding a 'Futuristic' trait or changing the background to 'Neon Cityscape'."));
    }

    /// @dev Allows the NFT owner to apply an AI-suggested metadata update.
    /// @param _tokenId The ID of the NFT to apply the suggestion to.
    /// @param _suggestionData Data from the AI suggestion that should be applied.
    function applyAISuggestion(uint256 _tokenId, string memory _suggestionData)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
        isNFTNotFractionalized(_tokenId)
    {
        // This function takes the _suggestionData (which would ideally be structured data from the AI)
        // and applies it to the NFT's metadata.
        // For this example, we simply append the suggestion to the dynamicMetadata.

        NFTs[_tokenId].dynamicMetadata = string(abi.encodePacked(NFTs[_tokenId].dynamicMetadata, " | AI Suggested Update: ", _suggestionData));
        emit NFTMetadataEvolved(_tokenId, string(abi.encodePacked("AI Suggestion Applied: ", _suggestionData)));
    }


    // 4. NFT Fractionalization Functions

    /// @dev Allows the NFT owner to fractionalize their NFT into ERC20 tokens.
    /// @param _tokenId The ID of the NFT to fractionalize.
    /// @param _fractionalSupply The total supply of fractional tokens to create.
    function fractionalizeNFT(uint256 _tokenId, uint256 _fractionalSupply)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTOwner(_tokenId)
        isNFTNotFractionalized(_tokenId)
    {
        // In a real implementation, you would deploy a new ERC20 token contract specifically for this NFT.
        // For simplicity, we'll just simulate the fractionalization within this contract.

        require(_fractionalSupply > 0, "Fractional supply must be greater than zero.");

        // Mark NFT as fractionalized and store fractional token info (address would be ERC20 contract in real scenario)
        NFTs[_tokenId].isFractionalized = true;
        // In a real scenario, deploy a new ERC20 contract and store its address:
        // address fractionalTokenAddress = address(new FractionalToken(_fractionalSupply, nftName, nftSymbol));
        // NFTs[_tokenId].fractionalTokenContract = fractionalTokenAddress;

        // For simulation, we'll just use this contract's address as the "fractional token contract"
        NFTs[_tokenId].fractionalTokenContract = address(this); // Simulate fractional token address

        // Mint fractional tokens to the NFT owner.
        // In a real scenario, you'd call the ERC20 token contract's mint function.
        // Here, we just simulate this.
        _mintFractionalTokens(_tokenId, msg.sender, _fractionalSupply);

        emit NFTFractionalized(_tokenId, NFTs[_tokenId].fractionalTokenContract, _fractionalSupply);
    }

    // Simulated fractional token balances mapping (replace with ERC20 contract in real implementation)
    mapping(uint256 => mapping(address => uint256)) public fractionalTokenBalances;
    mapping(uint256 => uint256) public totalFractionalTokenSupplies;


    function _mintFractionalTokens(uint256 _tokenId, address _to, uint256 _amount) private {
        fractionalTokenBalances[_tokenId][_to] += _amount;
        totalFractionalTokenSupplies[_tokenId] += _amount;
    }

    function _burnFractionalTokens(uint256 _tokenId, address _from, uint256 _amount) private {
        fractionalTokenBalances[_tokenId][_from] -= _amount;
        totalFractionalTokenSupplies[_tokenId] -= _amount;
    }


    /// @dev Allows holders of fractional tokens to redeem and claim the original NFT ownership (requires 100% fractional ownership).
    /// @param _tokenId The ID of the fractionalized NFT to redeem.
    function redeemFractionalNFT(uint256 _tokenId)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTFractionalized(_tokenId)
    {
        uint256 userBalance = fractionalTokenBalances[_tokenId][msg.sender];
        uint256 totalSupply = totalFractionalTokenSupplies[_tokenId];

        require(userBalance == totalSupply, "You do not own 100% of the fractional tokens.");

        // Transfer NFT ownership to the redeemer
        NFTs[_tokenId].owner = msg.sender;
        NFTs[_tokenId].isFractionalized = false;
        NFTs[_tokenId].fractionalTokenContract = address(0); // Reset fractional token contract

        // Burn all fractional tokens (simulated)
        _burnFractionalTokens(_tokenId, msg.sender, userBalance);

        emit NFTFractionalRedeemed(_tokenId, msg.sender);
    }

    /// @dev Transfers fractional tokens to another address.
    /// @param _tokenId The ID of the fractionalized NFT.
    /// @param _recipient The address to transfer tokens to.
    /// @param _amount The amount of fractional tokens to transfer.
    function transferFractionalTokens(uint256 _tokenId, address _recipient, uint256 _amount)
        public
        whenNotPaused
        nftExists(_tokenId)
        isNFTFractionalized(_tokenId)
    {
        require(fractionalTokenBalances[_tokenId][msg.sender] >= _amount, "Insufficient fractional token balance.");
        fractionalTokenBalances[_tokenId][msg.sender] -= _amount;
        fractionalTokenBalances[_tokenId][_recipient] += _amount;
        // In a real ERC20 implementation, you would call the ERC20 contract's transfer function.
    }

    /// @dev Returns the fractional token balance of a user for a specific NFT.
    /// @param _tokenId The ID of the fractionalized NFT.
    /// @param _account The address to query the balance for.
    function getFractionalTokenBalance(uint256 _tokenId, address _account)
        public
        view
        nftExists(_tokenId)
        isNFTFractionalized(_tokenId)
    returns (uint256) {
        return fractionalTokenBalances[_tokenId][_account];
    }

    /// @dev Returns the total supply of fractional tokens for a specific NFT.
    /// @param _tokenId The ID of the fractionalized NFT.
    function getTotalFractionalSupply(uint256 _tokenId)
        public
        view
        nftExists(_tokenId)
        isNFTFractionalized(_tokenId)
    returns (uint256) {
        return totalFractionalTokenSupplies[_tokenId];
    }


    // 5. Platform Utility Functions

    /// @dev Allows the contract owner to set the platform fee percentage.
    /// @param _feePercentage The new platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @dev Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() public onlyOwner {
        uint256 amountToWithdraw = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        (bool success, ) = payable(owner).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed.");
        emit PlatformFeesWithdrawn(amountToWithdraw, owner);
    }

    /// @dev Allows the contract owner to pause core marketplace functions (e.g., buying, listing).
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(owner);
    }

    /// @dev Allows the contract owner to unpause core marketplace functions.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(owner);
    }

    // Fallback function to receive Ether
    receive() external payable {}
    fallback() external payable {}
}
```