```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) Smart Contract
 * @author Gemini AI
 * @dev A sophisticated smart contract for a Decentralized Autonomous Art Gallery,
 * incorporating advanced concepts like dynamic NFTs, community curation,
 * fractional ownership, and metaverse integrations.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. **`mintArtNFT(string memory _metadataURI)`:** Artists can mint their digital art as NFTs.
 * 2. **`transferArtNFT(address _to, uint256 _tokenId)`:** Standard NFT transfer function.
 * 3. **`listArtForSale(uint256 _tokenId, uint256 _price)`:** Artists can list their NFTs for sale within the gallery.
 * 4. **`buyArtNFT(uint256 _tokenId)`:** Users can purchase listed NFTs.
 * 5. **`burnArtNFT(uint256 _tokenId)`:** Governance-controlled function to burn NFTs (e.g., for inappropriate content, with DAO approval).
 *
 * **Community Curation & Governance:**
 * 6. **`proposeArtForGallery(uint256 _tokenId)`:** Community members can propose NFTs to be featured in the main gallery.
 * 7. **`voteOnArtProposal(uint256 _proposalId, bool _vote)`:** Governance token holders can vote on art proposals.
 * 8. **`executeArtProposal(uint256 _proposalId)`:** Executes successful art proposals, adding the NFT to the curated gallery section.
 * 9. **`createExhibition(string memory _exhibitionName, uint256 _startTime, uint256 _endTime)`:** Curators can propose and create temporary art exhibitions.
 * 10. **`addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId)`:** Add approved NFTs to a specific exhibition.
 * 11. **`voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`:** Governance vote for exhibition proposals.
 * 12. **`executeExhibitionProposal(uint256 _proposalId)`:** Execute successful exhibition proposals.
 *
 * **Fractional Ownership & DeFi Integration:**
 * 13. **`fractionalizeArtNFT(uint256 _tokenId, uint256 _numberOfFractions)`:** Allows NFT owners to fractionalize their art into ERC20 tokens.
 * 14. **`redeemArtNFT(uint256 _tokenId)`:** Allows holders of all fractions to redeem the original NFT (requires 100% fraction ownership).
 * 15. **`listFractionsForSale(uint256 _tokenId, uint256 _fractionAmount, uint256 _pricePerFraction)`:** List fractions of an NFT for sale.
 * 16. **`buyFractions(uint256 _tokenId, uint256 _fractionAmount)`:** Purchase fractions of an NFT.
 *
 * **Metaverse & Dynamic Features:**
 * 17. **`setArtNFTLocation(uint256 _tokenId, string memory _metaverseLocation)`:**  Allows setting a metaverse location for an NFT (e.g., coordinates in a virtual world).
 * 18. **`updateArtNFTMetadata(uint256 _tokenId, string memory _newMetadataURI)`:** Allows updating the metadata URI of an NFT (dynamic NFTs - governance controlled).
 * 19. **`triggerDynamicNFTEvent(uint256 _tokenId, string memory _eventData)`:** Triggers a dynamic event for an NFT, potentially affecting its metadata or features based on external oracles/events (governance controlled).
 * 20. **`donateToArtist(uint256 _tokenId, uint256 _amount)`:** Allow users to directly donate to the artist of a specific NFT.
 * 21. **`setGovernanceToken(address _governanceTokenAddress)`:** Set the governance token address for voting and DAO functions.
 * 22. **`withdrawGalleryFees()`:** Allows the gallery owner/DAO to withdraw collected fees from sales.
 * 23. **`pauseContract()` / `unpauseContract()`:**  Pause/unpause the contract for emergency situations (owner/governance controlled).
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DecentralizedAutonomousArtGallery is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _exhibitionIdCounter;

    IERC20 public governanceToken;

    // Mapping from token ID to metadata URI
    mapping(uint256 => string) private _tokenMetadataURIs;

    // Mapping from token ID to sale price (0 if not for sale)
    mapping(uint256 => uint256) public artSalePrice;

    // Mapping from token ID to metaverse location (optional)
    mapping(uint256 => string) public artMetaverseLocation;

    // Mapping from token ID to artist address
    mapping(uint256 => address) public artArtist;

    // Curated Gallery Art Token IDs
    uint256[] public curatedGalleryArt;

    // Art Proposals
    struct ArtProposal {
        uint256 tokenId;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
    }
    mapping(uint256 => ArtProposal) public artProposals;

    // Exhibitions
    struct Exhibition {
        string name;
        uint256 startTime;
        uint256 endTime;
        uint256[] artTokenIds;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool active;
    }
    mapping(uint256 => Exhibition) public exhibitions;

    // Fractionalization Data
    mapping(uint256 => address) public fractionalTokenContract; // TokenId => Fractional Token Contract Address
    mapping(address => uint256) public originalNFTTokenId; // Fractional Token Contract Address => Original NFT TokenId

    // Gallery Fees (e.g., commission on sales) - can be DAO controlled later
    uint256 public galleryFeePercentage = 5; // 5% fee
    address public galleryFeeRecipient;

    event ArtNFTMinted(uint256 tokenId, address artist, string metadataURI);
    event ArtNFTListedForSale(uint256 tokenId, uint256 price);
    event ArtNFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event ArtNFTBurned(uint256 tokenId);
    event ArtProposedForGallery(uint256 proposalId, uint256 tokenId, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalExecuted(uint256 proposalId, uint256 tokenId);
    event ExhibitionCreated(uint256 exhibitionId, string name, uint256 startTime, uint256 endTime, address proposer);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionProposalExecuted(uint256 proposalId, uint256 exhibitionId);
    event ArtNFTFractionalized(uint256 tokenId, address fractionalTokenAddress, uint256 numberOfFractions);
    event FractionsListedForSale(uint256 tokenId, uint256 fractionAmount, uint256 pricePerFraction);
    event FractionsBought(uint256 tokenId, address buyer, uint256 fractionAmount, uint256 totalPrice);
    event ArtNFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event DynamicNFTEventTriggered(uint256 tokenId, string eventData);
    event DonationToArtist(uint256 tokenId, address donator, uint256 amount);
    event MetaverseLocationSet(uint256 tokenId, string location);
    event GovernanceTokenSet(address governanceTokenAddress);
    event GalleryFeesWithdrawn(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    constructor() ERC721("Decentralized Art Gallery NFT", "DAGNFT") {
        galleryFeeRecipient = owner(); // Initially set owner as fee recipient, DAO can change later
    }

    modifier onlyGovernanceTokenHolders() {
        require(governanceToken.balanceOf(_msgSender()) > 0, "Must hold governance tokens to perform this action.");
        _;
    }

    modifier onlyArtOwner(uint256 _tokenId) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Caller is not the owner nor approved.");
        _;
    }

    modifier onlyGalleryOwnerOrGovernance() {
        require(_msgSender() == owner() || governanceToken.balanceOf(_msgSender()) > 0, "Only gallery owner or governance token holders can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Contract is not paused.");
        _;
    }

    /**
     * @dev Sets the address of the governance token used for DAO functions.
     * @param _governanceTokenAddress Address of the governance token contract.
     */
    function setGovernanceToken(address _governanceTokenAddress) external onlyOwner {
        require(_governanceTokenAddress != address(0), "Governance token address cannot be zero.");
        governanceToken = IERC20(_governanceTokenAddress);
        emit GovernanceTokenSet(_governanceTokenAddress);
    }

    /**
     * @dev Mints a new art NFT.
     * @param _metadataURI URI pointing to the metadata of the art.
     */
    function mintArtNFT(string memory _metadataURI) external whenNotPaused returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(_msgSender(), tokenId);
        _tokenMetadataURIs[tokenId] = _metadataURI;
        artArtist[tokenId] = _msgSender();
        emit ArtNFTMinted(tokenId, _msgSender(), _metadataURI);
        return tokenId;
    }

    /**
     * @dev Returns the metadata URI for a given token ID.
     * @param _tokenId ID of the NFT.
     * @return Metadata URI string.
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenMetadataURIs[_tokenId];
    }

    /**
     * @dev Transfers an art NFT to another address.
     * @param _to Address to receive the NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    function transferArtNFT(address _to, uint256 _tokenId) external whenNotPaused onlyArtOwner(_tokenId) {
        safeTransferFrom(_msgSender(), _to, _tokenId);
    }

    /**
     * @dev Lists an art NFT for sale in the gallery.
     * @param _tokenId ID of the NFT to list.
     * @param _price Sale price in wei.
     */
    function listArtForSale(uint256 _tokenId, uint256 _price) external whenNotPaused onlyArtOwner(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        artSalePrice[_tokenId] = _price;
        emit ArtNFTListedForSale(_tokenId, _price);
    }

    /**
     * @dev Allows a user to buy an art NFT listed for sale.
     * @param _tokenId ID of the NFT to buy.
     */
    function buyArtNFT(uint256 _tokenId) external payable whenNotPaused {
        require(artSalePrice[_tokenId] > 0, "Art is not listed for sale.");
        require(msg.value >= artSalePrice[_tokenId], "Insufficient funds sent.");

        uint256 price = artSalePrice[_tokenId];
        address seller = ownerOf(_tokenId);

        // Calculate gallery fee
        uint256 galleryFee = (price * galleryFeePercentage) / 100;
        uint256 artistPayment = price - galleryFee;

        // Transfer funds
        payable(galleryFeeRecipient).transfer(galleryFee);
        payable(seller).transfer(artistPayment);

        // Transfer NFT
        safeTransferFrom(seller, _msgSender(), _tokenId);

        // Reset sale price
        artSalePrice[_tokenId] = 0;

        emit ArtNFTBought(_tokenId, _msgSender(), seller, price);
    }

    /**
     * @dev Burns an art NFT. Can be used for removing inappropriate content, etc.
     *      Requires governance approval or gallery owner authorization.
     * @param _tokenId ID of the NFT to burn.
     */
    function burnArtNFT(uint256 _tokenId) external onlyGalleryOwnerOrGovernance whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        _burn(_tokenId);
        delete _tokenMetadataURIs[_tokenId];
        delete artSalePrice[_tokenId];
        delete artMetaverseLocation[_tokenId];
        delete artArtist[_tokenId];

        // Remove from curated gallery if present
        for (uint256 i = 0; i < curatedGalleryArt.length; i++) {
            if (curatedGalleryArt[i] == _tokenId) {
                delete curatedGalleryArt[i];
                // To maintain array integrity, consider shifting elements or filtering in a real-world scenario
                break;
            }
        }
        emit ArtNFTBurned(_tokenId);
    }

    /**
     * @dev Proposes an art NFT to be featured in the curated gallery.
     * @param _tokenId ID of the NFT to propose.
     */
    function proposeArtForGallery(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(artProposals[_tokenId].executed == false, "Art already proposed or executed.");
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        artProposals[proposalId] = ArtProposal({
            tokenId: _tokenId,
            proposer: _msgSender(),
            votesFor: 0,
            votesAgainst: 0,
            executed: false
        });
        emit ArtProposedForGallery(proposalId, _tokenId, _msgSender());
    }

    /**
     * @dev Allows governance token holders to vote on an art proposal.
     * @param _proposalId ID of the art proposal.
     * @param _vote True for "for", false for "against".
     */
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyGovernanceTokenHolders whenNotPaused {
        require(artProposals[_proposalId].executed == false, "Proposal already executed.");
        require(artProposals[_proposalId].proposer != address(0), "Invalid proposal ID."); // Check proposal exists

        if (_vote) {
            artProposals[_proposalId].votesFor++;
        } else {
            artProposals[_proposalId].votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Executes an art proposal if it passes the voting threshold.
     *      Currently, a simple majority is used, but can be changed for more complex DAO logic.
     * @param _proposalId ID of the art proposal to execute.
     */
    function executeArtProposal(uint256 _proposalId) external onlyGovernanceTokenHolders whenNotPaused {
        require(artProposals[_proposalId].executed == false, "Proposal already executed.");
        require(artProposals[_proposalId].proposer != address(0), "Invalid proposal ID."); // Check proposal exists

        ArtProposal storage proposal = artProposals[_proposalId];
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        require(totalVotes > 0, "No votes cast yet."); // Prevent division by zero
        require(proposal.votesFor > proposal.votesAgainst, "Proposal did not pass."); // Simple majority

        curatedGalleryArt.push(proposal.tokenId);
        proposal.executed = true;
        emit ArtProposalExecuted(_proposalId, proposal.tokenId);
    }

    /**
     * @dev Creates a new art exhibition proposal.
     * @param _exhibitionName Name of the exhibition.
     * @param _startTime Unix timestamp for exhibition start time.
     * @param _endTime Unix timestamp for exhibition end time.
     */
    function createExhibition(string memory _exhibitionName, uint256 _startTime, uint256 _endTime) external onlyGovernanceTokenHolders whenNotPaused {
        require(_startTime < _endTime, "Start time must be before end time.");
        _exhibitionIdCounter.increment();
        uint256 exhibitionId = _exhibitionIdCounter.current();
        exhibitions[exhibitionId] = Exhibition({
            name: _exhibitionName,
            startTime: _startTime,
            endTime: _endTime,
            artTokenIds: new uint256[](0),
            proposer: _msgSender(),
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            active: false
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, _startTime, _endTime, _msgSender());
    }

    /**
     * @dev Allows governance token holders to vote on an exhibition proposal.
     * @param _proposalId ID of the exhibition proposal.
     * @param _vote True for "for", false for "against".
     */
    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) external onlyGovernanceTokenHolders whenNotPaused {
        require(exhibitions[_proposalId].executed == false, "Exhibition proposal already executed.");
        require(exhibitions[_proposalId].proposer != address(0), "Invalid exhibition proposal ID."); // Check proposal exists

        if (_vote) {
            exhibitions[_proposalId].votesFor++;
        } else {
            exhibitions[_proposalId].votesAgainst++;
        }
        emit ExhibitionProposalVoted(_proposalId, _msgSender(), _vote);
    }

    /**
     * @dev Executes an exhibition proposal, making it active and ready to add art.
     * @param _proposalId ID of the exhibition proposal to execute.
     */
    function executeExhibitionProposal(uint256 _proposalId) external onlyGovernanceTokenHolders whenNotPaused {
        require(exhibitions[_proposalId].executed == false, "Exhibition proposal already executed.");
        require(exhibitions[_proposalId].proposer != address(0), "Invalid exhibition proposal ID."); // Check proposal exists

        Exhibition storage exhibition = exhibitions[_proposalId];
        uint256 totalVotes = exhibition.votesFor + exhibition.votesAgainst;
        require(totalVotes > 0, "No votes cast yet."); // Prevent division by zero
        require(exhibition.votesFor > exhibition.votesAgainst, "Exhibition proposal did not pass."); // Simple majority

        exhibition.executed = true;
        exhibition.active = true; // Mark exhibition as active
        emit ExhibitionProposalExecuted(_proposalId, _proposalId);
    }

    /**
     * @dev Adds an approved art NFT to a specific exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @param _tokenId ID of the art NFT to add.
     */
    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) external onlyGovernanceTokenHolders whenNotPaused {
        require(exhibitions[_exhibitionId].active, "Exhibition is not active.");
        require(_exists(_tokenId), "Token does not exist.");

        exhibitions[_exhibitionId].artTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId);
    }

    // --- Fractional Ownership (Conceptual - Requires External ERC20 Token Contract Implementation) ---
    // Note: This is a simplified concept and would require a separate ERC20 token contract for fractions
    // and more complex logic for redemption in a real-world implementation.

    /**
     * @dev Allows the owner of an NFT to fractionalize it, creating ERC20 tokens representing fractions.
     *      (Conceptual - requires external ERC20 contract and more complex logic)
     * @param _tokenId ID of the NFT to fractionalize.
     * @param _numberOfFractions Number of fractions to create.
     */
    function fractionalizeArtNFT(uint256 _tokenId, uint256 _numberOfFractions) external onlyArtOwner(_tokenId) whenNotPaused {
        // --- Conceptual Implementation ---
        // 1. Deploy a new ERC20 fractional token contract linked to this NFT.
        // 2. Mint _numberOfFractions of ERC20 tokens to the NFT owner.
        // 3. Store the ERC20 token contract address and original NFT ID mapping.
        // 4. Optionally lock the original NFT in this contract or a separate vault.
        // --- In a real implementation, use a factory pattern to deploy fractional token contracts ---

        // For simplicity, let's assume we have a function to deploy a hypothetical FractionalToken contract.
        address fractionalTokenAddress = _deployFractionalToken(_tokenId, _numberOfFractions); // Hypothetical function

        fractionalTokenContract[_tokenId] = fractionalTokenAddress;
        originalNFTTokenId[fractionalTokenAddress] = _tokenId;

        emit ArtNFTFractionalized(_tokenId, fractionalTokenAddress, _numberOfFractions);
    }

    // Placeholder for a hypothetical function to deploy a fractional token contract (needs external implementation)
    function _deployFractionalToken(uint256 _tokenId, uint256 _numberOfFractions) private returns (address) {
        // In a real implementation, this would deploy a new ERC20 contract
        // specifically for fractionalizing the _tokenId NFT.
        // For this example, just returning a dummy address.
        return address(this); // Returning this contract address as a placeholder - NOT FUNCTIONAL
    }

    /**
     * @dev Allows listing fractions of an NFT for sale (conceptual).
     *      Would require integration with the fractional token contract.
     * @param _tokenId ID of the original NFT.
     * @param _fractionAmount Amount of fractions to list for sale.
     * @param _pricePerFraction Price per fraction.
     */
    function listFractionsForSale(uint256 _tokenId, uint256 _fractionAmount, uint256 _pricePerFraction) external whenNotPaused {
        // --- Conceptual Implementation ---
        // 1. Interact with the fractional token contract associated with _tokenId.
        // 2. Implement a marketplace or order book logic for fractional tokens.
        // 3. This function might need to call functions on the fractional token contract
        //    or a separate marketplace contract.
        // --- For simplicity, just emitting an event ---
        emit FractionsListedForSale(_tokenId, _fractionAmount, _pricePerFraction);
    }

    /**
     * @dev Allows buying fractions of an NFT (conceptual).
     *      Would require integration with the fractional token contract and marketplace.
     * @param _tokenId ID of the original NFT.
     * @param _fractionAmount Amount of fractions to buy.
     */
    function buyFractions(uint256 _tokenId, uint256 _fractionAmount) external payable whenNotPaused {
        // --- Conceptual Implementation ---
        // 1. Interact with the fractional token contract and marketplace.
        // 2. Calculate total price based on _fractionAmount and price per fraction.
        // 3. Transfer funds and fractional tokens.
        // --- For simplicity, just emitting an event ---
        uint256 totalPrice = _fractionAmount * 1 ether; // Example price calculation
        emit FractionsBought(_tokenId, _msgSender(), _fractionAmount, totalPrice);
    }

    /**
     * @dev Allows holders of 100% of the fractions to redeem the original NFT (conceptual).
     *      Requires complex logic to track fraction ownership and redeem the NFT.
     * @param _tokenId ID of the original NFT to redeem.
     */
    function redeemArtNFT(uint256 _tokenId) external whenNotPaused {
        // --- Conceptual Implementation ---
        // 1. Check if the caller holds 100% of the fractional tokens for _tokenId.
        // 2. Burn all fractional tokens held by the caller.
        // 3. Transfer the original NFT back to the caller.
        // 4. Potentially destroy or deactivate the fractional token contract.
        // --- Requires complex ERC20 token logic and ownership tracking ---
        require(false, "Redeem functionality not fully implemented in this conceptual example."); // Placeholder
    }

    // --- Metaverse & Dynamic NFT Features ---

    /**
     * @dev Sets the metaverse location for an art NFT.
     * @param _tokenId ID of the NFT.
     * @param _metaverseLocation String describing the metaverse location (e.g., coordinates, scene ID).
     */
    function setArtNFTLocation(uint256 _tokenId, string memory _metaverseLocation) external onlyArtOwner(_tokenId) whenNotPaused {
        artMetaverseLocation[_tokenId] = _metaverseLocation;
        emit MetaverseLocationSet(_tokenId, _metaverseLocation);
    }

    /**
     * @dev Updates the metadata URI of an art NFT (Dynamic NFT concept - governance controlled).
     * @param _tokenId ID of the NFT to update.
     * @param _newMetadataURI New metadata URI.
     */
    function updateArtNFTMetadata(uint256 _tokenId, string memory _newMetadataURI) external onlyGovernanceTokenHolders whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        _tokenMetadataURIs[_tokenId] = _newMetadataURI;
        emit ArtNFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Triggers a dynamic event for an NFT, potentially changing its metadata or features
     *      based on external oracles or contract logic (governance controlled).
     * @param _tokenId ID of the NFT to trigger the event for.
     * @param _eventData String data related to the event (e.g., oracle response, event type).
     */
    function triggerDynamicNFTEvent(uint256 _tokenId, string memory _eventData) external onlyGovernanceTokenHolders whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        // --- Example: Could update metadata based on _eventData or call external oracle ---
        // _tokenMetadataURIs[_tokenId] = _generateDynamicMetadata(_tokenId, _eventData); // Hypothetical function
        emit DynamicNFTEventTriggered(_tokenId, _eventData);
    }

    /**
     * @dev Allows users to donate to the artist of a specific NFT.
     * @param _tokenId ID of the NFT to donate to the artist of.
     */
    function donateToArtist(uint256 _tokenId, uint256 _amount) external payable whenNotPaused {
        require(_exists(_tokenId), "Token does not exist.");
        require(msg.value >= _amount, "Insufficient donation amount sent.");
        payable(artArtist[_tokenId]).transfer(_amount);
        emit DonationToArtist(_tokenId, _msgSender(), _amount);
    }

    /**
     * @dev Allows the gallery owner/DAO to withdraw collected fees.
     */
    function withdrawGalleryFees() external onlyGalleryOwnerOrGovernance whenNotPaused {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Subtract current tx value to avoid issues
        require(contractBalance > 0, "No gallery fees to withdraw.");
        payable(galleryFeeRecipient).transfer(contractBalance);
        emit GalleryFeesWithdrawn(galleryFeeRecipient, contractBalance);
    }

    /**
     * @dev Pauses the contract, preventing most functions from being executed.
     */
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, allowing functions to be executed again.
     */
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Gets the list of token IDs in the curated gallery.
     * @return Array of token IDs.
     */
    function getCuratedGalleryArt() external view returns (uint256[] memory) {
        return curatedGalleryArt;
    }

    /**
     * @dev Gets details of a specific art proposal.
     * @param _proposalId ID of the proposal.
     * @return ArtProposal struct.
     */
    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /**
     * @dev Gets details of a specific exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @return Exhibition struct.
     */
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /**
     * @dev Gets the list of token IDs in a specific exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @return Array of token IDs.
     */
    function getExhibitionArt(uint256 _exhibitionId) external view returns (uint256[] memory) {
        return exhibitions[_exhibitionId].artTokenIds;
    }

    /**
     * @dev Gets the current sale price of an art NFT.
     * @param _tokenId ID of the NFT.
     * @return Sale price in wei (0 if not for sale).
     */
    function getArtNFTPrice(uint256 _tokenId) external view returns (uint256) {
        return artSalePrice[_tokenId];
    }

    /**
     * @dev Gets the metaverse location of an art NFT.
     * @param _tokenId ID of the NFT.
     * @return Metaverse location string (empty if not set).
     */
    function getArtNFTMetaverseLocation(uint256 _tokenId) external view returns (string memory) {
        return artMetaverseLocation[_tokenId];
    }

    /**
     * @dev Gets the artist address of an art NFT.
     * @param _tokenId ID of the NFT.
     * @return Artist address.
     */
    function getArtNFTArtist(uint256 _tokenId) external view returns (address) {
        return artArtist[_tokenId];
    }
}
```