```solidity
/**
 * @title Decentralized Dynamic Art Marketplace - "Chameleon Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a dynamic NFT art marketplace where art pieces can evolve based on various on-chain and off-chain factors,
 *      controlled by artists, influenced by owners, and shaped by community governance.

 * **Contract Outline and Function Summary:**

 * **1. NFT Core (DynamicArtNFT):**
 *    - `mintArtNFT(string _name, string _description, string _initialDNA, string _initialMetadataURI)`: Mints a new Dynamic Art NFT.
 *    - `transferArtNFT(address _to, uint256 _tokenId)`: Transfers ownership of an art NFT.
 *    - `getArtDNA(uint256 _tokenId)`: Returns the current DNA string of an art NFT.
 *    - `getArtMetadataURI(uint256 _tokenId)`: Returns the current metadata URI of an art NFT.
 *    - `setArtMetadataURI(uint256 _tokenId, string _newMetadataURI)`: Allows the artist/owner to update the metadata URI (e.g., for evolving art).
 *    - `getArtName(uint256 _tokenId)`: Returns the name of the art NFT.
 *    - `getArtDescription(uint256 _tokenId)`: Returns the description of the art NFT.

 * **2. Artist Management & Royalties:**
 *    - `registerArtist(string _artistName, string _artistProfileURI)`: Allows artists to register on the platform.
 *    - `isRegisteredArtist(address _artistAddress)`: Checks if an address is a registered artist.
 *    - `setArtistRoyalty(uint256 _tokenId, uint256 _royaltyPercentage)`: Sets the royalty percentage for an art NFT (for secondary sales).
 *    - `getArtistRoyalty(uint256 _tokenId)`: Returns the royalty percentage for an art NFT.

 * **3. Marketplace Functionality:**
 *    - `listArtForSale(uint256 _tokenId, uint256 _price)`: Lists an art NFT for sale on the marketplace.
 *    - `buyArt(uint256 _tokenId)`: Allows buying a listed art NFT.
 *    - `cancelArtListing(uint256 _tokenId)`: Allows the seller to cancel a listing.
 *    - `getArtListing(uint256 _tokenId)`: Returns listing details for an art NFT.

 * **4. Dynamic Evolution & Customization:**
 *    - `evolveArtDNA(uint256 _tokenId, string _evolutionSeed)`: Allows the artist/owner to trigger an evolution of the art's DNA based on a seed (e.g., external event, user input).
 *    - `customizeArt(uint256 _tokenId, string _customizationData)`: Allows the owner to apply specific customizations to the art (e.g., color palettes, filters - reflected in metadata).
 *    - `setEvolutionAlgorithm(address _newAlgorithmContract)`: Admin function to set a contract address containing the art evolution algorithm.
 *    - `getEvolutionAlgorithm()`: Returns the current evolution algorithm contract address.

 * **5. Community Governance (Basic Example - can be expanded):**
 *    - `proposeArtFeature(uint256 _tokenId, string _featureProposal)`: Allows NFT owners to propose new features or evolutions for a specific art piece.
 *    - `voteForFeatureProposal(uint256 _tokenId, uint256 _proposalId, bool _vote)`: Allows NFT owners to vote on feature proposals.
 *    - `getProposalVotes(uint256 _tokenId, uint256 _proposalId)`: Returns the vote count for a specific proposal.

 * **6. Platform Management & Fees:**
 *    - `setPlatformFeePercentage(uint256 _feePercentage)`: Admin function to set the platform fee percentage for sales.
 *    - `getPlatformFeePercentage()`: Returns the current platform fee percentage.
 *    - `withdrawPlatformFees()`: Admin function to withdraw accumulated platform fees.

 * **7. Utility & View Functions:**
 *    - `supportsInterface(bytes4 interfaceId)`: Standard ERC721 interface support.
 *    - `getTokenOwner(uint256 _tokenId)`: Returns the owner of a given token ID.
 *    - `isArtListed(uint256 _tokenId)`: Checks if an art NFT is currently listed for sale.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChameleonCanvas is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    // --- Structs and Enums ---
    struct ArtNFT {
        string name;
        string description;
        string dna; // Dynamic DNA string representing the core art attributes
        string metadataURI; // URI pointing to the current metadata (can be dynamic)
        address artist;
        uint256 royaltyPercentage;
    }

    struct Listing {
        uint256 price;
        address seller;
        bool isListed;
    }

    struct ArtistProfile {
        string artistName;
        string profileURI;
        bool isRegistered;
    }

    struct FeatureProposal {
        string proposalText;
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;
    }

    // --- State Variables ---
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => Listing) public artListings;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => mapping(uint256 => FeatureProposal)) public artFeatureProposals; // tokenId => proposalId => Proposal
    mapping(uint256 => Counters.Counter) private _proposalCounter; // tokenId => proposal counter

    address public evolutionAlgorithmContract; // Address of a contract that handles art evolution logic (can be external or internal)
    uint256 public platformFeePercentage = 2; // Default platform fee percentage (2%)
    address payable public platformFeeWallet;

    // --- Events ---
    event ArtNFTMinted(uint256 tokenId, address artist, string name);
    event ArtNFTListed(uint256 tokenId, uint256 price, address seller);
    event ArtNFTSold(uint256 tokenId, address buyer, uint256 price);
    event ArtListingCancelled(uint256 tokenId, address seller);
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtDNAEvolved(uint256 tokenId, string newDNA);
    event ArtMetadataURISet(uint256 tokenId, string newMetadataURI);
    event ArtCustomized(uint256 tokenId, string customizationData);
    event FeatureProposalCreated(uint256 tokenId, uint256 proposalId, string proposalText);
    event FeatureProposalVoted(uint256 tokenId, uint256 proposalId, address voter, bool vote);
    event PlatformFeePercentageSet(uint256 newFeePercentage);

    // --- Modifiers ---
    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Not a registered artist.");
        _;
    }

    modifier onlyArtOwner(uint256 _tokenId) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this art NFT.");
        _;
    }

    modifier onlyArtArtist(uint256 _tokenId) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        require(artNFTs[_tokenId].artist == msg.sender, "You are not the artist of this art NFT.");
        _;
    }

    modifier artNotListed(uint256 _tokenId) {
        require(!artListings[_tokenId].isListed, "Art NFT is already listed for sale.");
        _;
    }

    modifier artListed(uint256 _tokenId) {
        require(artListings[_tokenId].isListed, "Art NFT is not listed for sale.");
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, address payable _feeWallet) ERC721(_name, _symbol) {
        platformFeeWallet = _feeWallet;
    }

    // ------------------------------------------------------------------------
    // 1. NFT Core (DynamicArtNFT)
    // ------------------------------------------------------------------------

    /**
     * @dev Mints a new Dynamic Art NFT. Only callable by the contract owner (platform admin) or potentially designated minters.
     * @param _name The name of the art NFT.
     * @param _description The description of the art NFT.
     * @param _initialDNA Initial DNA string for the art piece.
     * @param _initialMetadataURI Initial metadata URI for the art piece.
     */
    function mintArtNFT(
        string memory _name,
        string memory _description,
        string memory _initialDNA,
        string memory _initialMetadataURI
    ) public onlyOwner returns (uint256) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        artNFTs[tokenId] = ArtNFT({
            name: _name,
            description: _description,
            dna: _initialDNA,
            metadataURI: _initialMetadataURI,
            artist: msg.sender, // Minter is considered the initial artist
            royaltyPercentage: 5 // Default royalty percentage (can be adjusted later)
        });

        _mint(msg.sender, tokenId);
        emit ArtNFTMinted(tokenId, msg.sender, _name);
        return tokenId;
    }

    /**
     * @dev Transfers ownership of an art NFT. Standard ERC721 transfer.
     * @param _to The address to transfer the NFT to.
     * @param _tokenId The ID of the NFT to transfer.
     */
    function transferArtNFT(address _to, uint256 _tokenId) public payable virtual {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /**
     * @dev Returns the current DNA string of an art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return string The DNA string.
     */
    function getArtDNA(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        return artNFTs[_tokenId].dna;
    }

    /**
     * @dev Returns the current metadata URI of an art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return string The metadata URI.
     */
    function getArtMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        return artNFTs[_tokenId].metadataURI;
    }

    /**
     * @dev Allows the artist/owner to update the metadata URI. This is crucial for dynamic art evolution.
     * @param _tokenId The ID of the art NFT.
     * @param _newMetadataURI The new metadata URI to set.
     */
    function setArtMetadataURI(uint256 _tokenId, string memory _newMetadataURI) public onlyArtOwner(_tokenId) {
        artNFTs[_tokenId].metadataURI = _newMetadataURI;
        emit ArtMetadataURISet(_tokenId, _newMetadataURI);
    }

    /**
     * @dev Returns the name of the art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return string The name.
     */
    function getArtName(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        return artNFTs[_tokenId].name;
    }

    /**
     * @dev Returns the description of the art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return string The description.
     */
    function getArtDescription(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        return artNFTs[_tokenId].description;
    }

    // ------------------------------------------------------------------------
    // 2. Artist Management & Royalties
    // ------------------------------------------------------------------------

    /**
     * @dev Allows artists to register themselves on the platform.
     * @param _artistName The name of the artist.
     * @param _artistProfileURI URI pointing to the artist's profile (e.g., website, social media).
     */
    function registerArtist(string memory _artistName, string memory _artistProfileURI) public {
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            profileURI: _artistProfileURI,
            isRegistered: true
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /**
     * @dev Checks if an address is a registered artist.
     * @param _artistAddress The address to check.
     * @return bool True if registered, false otherwise.
     */
    function isRegisteredArtist(address _artistAddress) public view returns (bool) {
        return artistProfiles[_artistAddress].isRegistered;
    }

    /**
     * @dev Sets the royalty percentage for an art NFT. Only callable by the original artist.
     * @param _tokenId The ID of the art NFT.
     * @param _royaltyPercentage The royalty percentage (e.g., 10 for 10%).
     */
    function setArtistRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) public onlyArtArtist(_tokenId) {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot exceed 50%."); // Example limit
        artNFTs[_tokenId].royaltyPercentage = _royaltyPercentage;
    }

    /**
     * @dev Returns the royalty percentage for an art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return uint256 The royalty percentage.
     */
    function getArtistRoyalty(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        return artNFTs[_tokenId].royaltyPercentage;
    }

    // ------------------------------------------------------------------------
    // 3. Marketplace Functionality
    // ------------------------------------------------------------------------

    /**
     * @dev Lists an art NFT for sale on the marketplace. Only callable by the NFT owner.
     * @param _tokenId The ID of the art NFT to list.
     * @param _price The listing price in wei.
     */
    function listArtForSale(uint256 _tokenId, uint256 _price) public onlyArtOwner(_tokenId) artNotListed(_tokenId) {
        approve(address(this), _tokenId); // Approve marketplace to handle the NFT
        artListings[_tokenId] = Listing({
            price: _price,
            seller: msg.sender,
            isListed: true
        });
        emit ArtNFTListed(_tokenId, _price, msg.sender);
    }

    /**
     * @dev Allows buying a listed art NFT.
     * @param _tokenId The ID of the art NFT to buy.
     */
    function buyArt(uint256 _tokenId) public payable artListed(_tokenId) {
        Listing storage listing = artListings[_tokenId];
        require(msg.value >= listing.price, "Insufficient funds to buy art.");

        uint256 platformFee = (listing.price * platformFeePercentage) / 100;
        uint256 artistRoyalty = (listing.price * artNFTs[_tokenId].royaltyPercentage) / 100;
        uint256 sellerPayout = listing.price - platformFee - artistRoyalty;

        // Transfer funds
        payable(listing.seller).transfer(sellerPayout);
        if (artistRoyalty > 0) {
            payable(artNFTs[_tokenId].artist).transfer(artistRoyalty);
        }
        platformFeeWallet.transfer(platformFee);

        // Transfer NFT ownership
        _transfer(listing.seller, msg.sender, _tokenId);

        // Reset listing
        delete artListings[_tokenId]; // or set listing.isListed = false if you want to keep listing history

        emit ArtNFTSold(_tokenId, msg.sender, listing.price);
    }

    /**
     * @dev Allows the seller to cancel a listing.
     * @param _tokenId The ID of the art NFT to cancel the listing for.
     */
    function cancelArtListing(uint256 _tokenId) public onlyArtOwner(_tokenId) artListed(_tokenId) {
        require(artListings[_tokenId].seller == msg.sender, "Only the seller can cancel the listing.");
        delete artListings[_tokenId]; // or set listing.isListed = false
        emit ArtListingCancelled(_tokenId, msg.sender);
    }

    /**
     * @dev Returns listing details for an art NFT.
     * @param _tokenId The ID of the art NFT.
     * @return Listing struct containing listing details.
     */
    function getArtListing(uint256 _tokenId) public view returns (Listing memory) {
        return artListings[_tokenId];
    }

    /**
     * @dev Checks if an art NFT is currently listed for sale.
     * @param _tokenId The ID of the art NFT.
     * @return bool True if listed, false otherwise.
     */
    function isArtListed(uint256 _tokenId) public view returns (bool) {
        return artListings[_tokenId].isListed;
    }

    // ------------------------------------------------------------------------
    // 4. Dynamic Evolution & Customization
    // ------------------------------------------------------------------------

    /**
     * @dev Allows the artist/owner to trigger an evolution of the art's DNA.
     *      This could be based on a seed, external event, or other logic.
     *      In a real-world scenario, `evolutionAlgorithmContract` would contain the actual evolution logic.
     *      For simplicity here, we'll just append the seed to the DNA string.
     * @param _tokenId The ID of the art NFT to evolve.
     * @param _evolutionSeed A seed string to influence the evolution.
     */
    function evolveArtDNA(uint256 _tokenId, string memory _evolutionSeed) public onlyArtOwner(_tokenId) {
        string memory currentDNA = artNFTs[_tokenId].dna;
        string memory newDNA = string(abi.encodePacked(currentDNA, "_evolved_", _evolutionSeed)); // Simple example evolution
        artNFTs[_tokenId].dna = newDNA;
        // In a more advanced implementation, call an external evolution algorithm contract:
        // (Requires setting `evolutionAlgorithmContract` address)
        // if (evolutionAlgorithmContract != address(0)) {
        //     newDNA = IEvolutionAlgorithm(evolutionAlgorithmContract).evolveDNA(currentDNA, _evolutionSeed);
        //     artNFTs[_tokenId].dna = newDNA;
        // }
        emit ArtDNAEvolved(_tokenId, newDNA);
    }

    /**
     * @dev Allows the owner to apply specific customizations to the art.
     *      This could trigger metadata updates or on-chain changes depending on the art's design.
     *      For now, we just store the customization data and emit an event.
     *      Metadata URI update would typically follow this to reflect the customization visually.
     * @param _tokenId The ID of the art NFT to customize.
     * @param _customizationData String representing the customization data (e.g., JSON, encoded parameters).
     */
    function customizeArt(uint256 _tokenId, string memory _customizationData) public onlyArtOwner(_tokenId) {
        // Example: You could decode _customizationData and update on-chain attributes
        // or trigger a metadata update based on this data.
        emit ArtCustomized(_tokenId, _customizationData);
        // Example: You might update metadata URI here to reflect customization
        // string memory newMetadataURI = generateCustomizedMetadataURI(_tokenId, _customizationData);
        // setArtMetadataURI(_tokenId, newMetadataURI);
    }

    /**
     * @dev Admin function to set the contract address containing the art evolution algorithm.
     * @param _newAlgorithmContract The address of the evolution algorithm contract.
     */
    function setEvolutionAlgorithm(address _newAlgorithmContract) public onlyOwner {
        evolutionAlgorithmContract = _newAlgorithmContract;
    }

    /**
     * @dev Returns the current evolution algorithm contract address.
     * @return address The evolution algorithm contract address.
     */
    function getEvolutionAlgorithm() public view returns (address) {
        return evolutionAlgorithmContract;
    }


    // ------------------------------------------------------------------------
    // 5. Community Governance (Basic Example)
    // ------------------------------------------------------------------------

    /**
     * @dev Allows NFT owners to propose new features or evolutions for a specific art piece.
     * @param _tokenId The ID of the art NFT for which the proposal is made.
     * @param _featureProposal Text describing the feature proposal.
     */
    function proposeArtFeature(uint256 _tokenId, string memory _featureProposal) public onlyArtOwner(_tokenId) {
        _proposalCounter[_tokenId].increment();
        uint256 proposalId = _proposalCounter[_tokenId].current();
        artFeatureProposals[_tokenId][proposalId] = FeatureProposal({
            proposalText: _featureProposal,
            upvotes: 0,
            downvotes: 0,
            isActive: true
        });
        emit FeatureProposalCreated(_tokenId, proposalId, _featureProposal);
    }

    /**
     * @dev Allows NFT owners to vote on feature proposals.
     * @param _tokenId The ID of the art NFT.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _vote True for upvote, false for downvote.
     */
    function voteForFeatureProposal(uint256 _tokenId, uint256 _proposalId, bool _vote) public onlyArtOwner(_tokenId) {
        require(artFeatureProposals[_tokenId][_proposalId].isActive, "Proposal is not active.");
        if (_vote) {
            artFeatureProposals[_tokenId][_proposalId].upvotes++;
        } else {
            artFeatureProposals[_tokenId][_proposalId].downvotes++;
        }
        emit FeatureProposalVoted(_tokenId, _proposalId, msg.sender, _vote);
    }

    /**
     * @dev Returns the vote count for a specific proposal.
     * @param _tokenId The ID of the art NFT.
     * @param _proposalId The ID of the proposal.
     * @return uint256[2] Array containing [upvotes, downvotes].
     */
    function getProposalVotes(uint256 _tokenId, uint256 _proposalId) public view returns (uint256[2] memory) {
        return [artFeatureProposals[_tokenId][_proposalId].upvotes, artFeatureProposals[_tokenId][_proposalId].downvotes];
    }


    // ------------------------------------------------------------------------
    // 6. Platform Management & Fees
    // ------------------------------------------------------------------------

    /**
     * @dev Admin function to set the platform fee percentage.
     * @param _feePercentage The new platform fee percentage (e.g., 5 for 5%).
     */
    function setPlatformFeePercentage(uint256 _feePercentage) public onlyOwner {
        require(_feePercentage <= 20, "Platform fee percentage cannot exceed 20%."); // Example limit
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageSet(_feePercentage);
    }

    /**
     * @dev Returns the current platform fee percentage.
     * @return uint256 The platform fee percentage.
     */
    function getPlatformFeePercentage() public view returns (uint256) {
        return platformFeePercentage;
    }

    /**
     * @dev Admin function to withdraw accumulated platform fees to the platform fee wallet.
     */
    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        uint256 contractBalance = balance - msg.value; // Exclude current transaction value
        require(contractBalance > 0, "No platform fees to withdraw.");
        platformFeeWallet.transfer(contractBalance);
    }


    // ------------------------------------------------------------------------
    // 7. Utility & View Functions
    // ------------------------------------------------------------------------

    /**
     * @dev Returns the owner of a given token ID.
     * @param _tokenId The ID of the art NFT.
     * @return address The owner address.
     */
    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "Art NFT does not exist.");
        return ownerOf(_tokenId);
    }

    /**
     * @dev @inheritdoc ERC721
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return artNFTs[_tokenId].metadataURI;
    }

    /**
     * @dev @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// --- Example External Evolution Algorithm Interface (for demonstration) ---
// interface IEvolutionAlgorithm {
//     function evolveDNA(string memory _currentDNA, string memory _seed) external returns (string memory);
// }
```