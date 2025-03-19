```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery.
 *
 * Outline and Function Summary:
 *
 * I.  Gallery Setup and Configuration:
 *     1. initializeGallery(string _galleryName, address _daoAddress, uint256 _submissionFee, uint256 _galleryFeePercentage): Initialize gallery settings.
 *     2. setDAOAddress(address _newDAOAddress): Set the DAO address responsible for governance. (DAO-controlled)
 *     3. setSubmissionFee(uint256 _newSubmissionFee): Set the fee for submitting artwork. (DAO-controlled)
 *     4. setGalleryFeePercentage(uint256 _newGalleryFeePercentage): Set the gallery's commission percentage on sales. (DAO-controlled)
 *     5. setCuratorAddress(address _curatorAddress): Set the curator address responsible for managing displayed art. (DAO-controlled)
 *
 * II. Art Submission and Curation:
 *     6. submitArtwork(address _nftContractAddress, uint256 _tokenId, string _artworkTitle, string _artworkDescription): Artists submit their NFTs for gallery consideration. (Payable submission fee)
 *     7. approveArtwork(uint256 _submissionId): Curator approves a submitted artwork to be displayed in the gallery. (Curator-only)
 *     8. rejectArtwork(uint256 _submissionId): Curator rejects a submitted artwork. (Curator-only)
 *     9. listArtworkForSale(uint256 _artworkId, uint256 _price): List an approved artwork for sale in the gallery. (Artist-only, Artwork owner)
 *     10.unlistArtworkForSale(uint256 _artworkId): Unlist an artwork from sale. (Artist-only, Artwork owner)
 *     11. purchaseArtwork(uint256 _artworkId): Purchase an artwork listed for sale. (Payable, sends funds to artist and gallery)
 *     12. setArtworkMetadataURI(uint256 _artworkId, string _metadataURI): Set a custom metadata URI for an artwork within the gallery. (Curator-only, for gallery-specific info)
 *
 * III. Gallery Display and Features:
 *     13. featureArtwork(uint256 _artworkId): Curator marks an artwork as "featured" for prominent display. (Curator-only)
 *     14. unfeatureArtwork(uint256 _artworkId): Curator removes an artwork from the featured display. (Curator-only)
 *     15. getRandomFeaturedArtwork(): Returns a random featured artwork ID. (View function for frontend)
 *     16. getGalleryArtworkCount(): Returns the total number of artworks in the gallery. (View function)
 *     17. getFeaturedArtworkCount(): Returns the number of featured artworks. (View function)
 *     18. getArtworkDetails(uint256 _artworkId): Returns detailed information about an artwork in the gallery. (View function)
 *     19. getSubmissionsCount(): Returns the total number of artwork submissions. (View function)
 *     20. getSubmissionDetails(uint256 _submissionId): Returns details of a specific artwork submission. (View function)
 *
 * IV. Emergency and Utility Functions:
 *     21. emergencyWithdraw(address _recipient, uint256 _amount): DAO-controlled emergency withdrawal function. (DAO-only)
 *     22. getContractBalance(): Returns the contract's ETH balance. (View function)
 */

contract DecentralizedAutonomousArtGallery {

    string public galleryName;
    address public daoAddress;
    address public curatorAddress;
    uint256 public submissionFee;
    uint256 public galleryFeePercentage; // Percentage (out of 100) gallery takes on sales

    uint256 public artworkCount;
    uint256 public submissionCount;

    struct Artwork {
        address nftContractAddress;
        uint256 tokenId;
        string artworkTitle;
        string artworkDescription;
        address artistAddress;
        uint256 listPrice;
        bool isListedForSale;
        bool isApproved;
        bool isFeatured;
        string metadataURI; // Gallery-specific metadata URI
    }

    struct Submission {
        address nftContractAddress;
        uint256 tokenId;
        string artworkTitle;
        string artworkDescription;
        address artistAddress;
        uint256 submissionTimestamp;
        bool isApproved;
        bool isRejected;
    }

    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => Submission) public artworkSubmissions;
    mapping(address => bool) public isCurator; // Future use for multiple curators, currently using single curator address

    event GalleryInitialized(string galleryName, address daoAddress, address curatorAddress, uint256 submissionFee, uint256 galleryFeePercentage);
    event DAOAddressUpdated(address newDAOAddress, address oldDAOAddress);
    event SubmissionFeeUpdated(uint256 newSubmissionFee, uint256 oldSubmissionFee);
    event GalleryFeePercentageUpdated(uint256 newFeePercentage, uint256 oldFeePercentage);
    event CuratorAddressUpdated(address newCuratorAddress, address oldCuratorAddress);
    event ArtworkSubmitted(uint256 submissionId, address nftContractAddress, uint256 tokenId, address artistAddress);
    event ArtworkApproved(uint256 artworkId, uint256 submissionId);
    event ArtworkRejected(uint256 submissionId);
    event ArtworkListedForSale(uint256 artworkId, uint256 price, address artistAddress);
    event ArtworkUnlistedFromSale(uint256 artworkId, address artistAddress);
    event ArtworkPurchased(uint256 artworkId, address buyerAddress, address artistAddress, uint256 price, uint256 galleryFee);
    event ArtworkFeatured(uint256 artworkId);
    event ArtworkUnfeatured(uint256 artworkId);
    event ArtworkMetadataURISet(uint256 artworkId, string metadataURI);
    event EmergencyWithdrawal(address recipient, uint256 amount);

    modifier onlyDAO() {
        require(msg.sender == daoAddress, "Only DAO can call this function");
        _;
    }

    modifier onlyCurator() {
        require(msg.sender == curatorAddress, "Only curator can call this function");
        _;
    }

    modifier onlyArtist(uint256 _artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only artist of the artwork can call this function");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Artwork does not exist");
        _;
    }

    modifier submissionExists(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= submissionCount, "Submission does not exist");
        _;
    }


    /**
     * @dev Initializes the gallery with name, DAO address, submission fee and gallery fee percentage.
     * @param _galleryName Name of the art gallery.
     * @param _daoAddress Address of the DAO controlling the gallery.
     * @param _submissionFee Fee required for artwork submission.
     * @param _galleryFeePercentage Percentage of sale price taken as gallery fee.
     * @param _curatorAddress Address of the curator managing the gallery display.
     */
    function initializeGallery(
        string memory _galleryName,
        address _daoAddress,
        uint256 _submissionFee,
        uint256 _galleryFeePercentage,
        address _curatorAddress
    ) public {
        require(daoAddress == address(0), "Gallery already initialized"); // Prevent re-initialization
        galleryName = _galleryName;
        daoAddress = _daoAddress;
        submissionFee = _submissionFee;
        galleryFeePercentage = _galleryFeePercentage;
        curatorAddress = _curatorAddress;
        isCurator[_curatorAddress] = true; // Set initial curator as curator
        emit GalleryInitialized(_galleryName, _daoAddress, _curatorAddress, _submissionFee, _galleryFeePercentage);
    }

    /**
     * @dev Sets the DAO address. Can only be called by the current DAO.
     * @param _newDAOAddress Address of the new DAO.
     */
    function setDAOAddress(address _newDAOAddress) public onlyDAO {
        require(_newDAOAddress != address(0), "New DAO address cannot be zero address");
        address oldDAOAddress = daoAddress;
        daoAddress = _newDAOAddress;
        emit DAOAddressUpdated(_newDAOAddress, oldDAOAddress);
    }

    /**
     * @dev Sets the submission fee for artwork submission. Can only be called by the DAO.
     * @param _newSubmissionFee New submission fee amount.
     */
    function setSubmissionFee(uint256 _newSubmissionFee) public onlyDAO {
        uint256 oldSubmissionFee = submissionFee;
        submissionFee = _newSubmissionFee;
        emit SubmissionFeeUpdated(_newSubmissionFee, oldSubmissionFee);
    }

    /**
     * @dev Sets the gallery's commission percentage on artwork sales. Can only be called by the DAO.
     * @param _newGalleryFeePercentage New gallery fee percentage (out of 100).
     */
    function setGalleryFeePercentage(uint256 _newGalleryFeePercentage) public onlyDAO {
        require(_newGalleryFeePercentage <= 100, "Gallery fee percentage cannot exceed 100");
        uint256 oldFeePercentage = galleryFeePercentage;
        galleryFeePercentage = _newGalleryFeePercentage;
        emit GalleryFeePercentageUpdated(_newGalleryFeePercentage, oldFeePercentage);
    }

    /**
     * @dev Sets the curator address responsible for managing displayed art. Can only be called by the DAO.
     * @param _curatorAddress Address of the new curator.
     */
    function setCuratorAddress(address _curatorAddress) public onlyDAO {
        require(_curatorAddress != address(0), "Curator address cannot be zero address");
        address oldCuratorAddress = curatorAddress;
        curatorAddress = _curatorAddress;
        isCurator[curatorAddress] = true; // Ensure new curator is marked as curator
        isCurator[oldCuratorAddress] = false; // Remove old curator from curator mapping (if needed, depends on multi-curator logic)
        emit CuratorAddressUpdated(_curatorAddress, oldCuratorAddress);
    }

    /**
     * @dev Artists submit their NFTs for gallery consideration. Requires payment of submission fee.
     * @param _nftContractAddress Address of the NFT contract.
     * @param _tokenId Token ID of the NFT.
     * @param _artworkTitle Title of the artwork.
     * @param _artworkDescription Description of the artwork.
     */
    function submitArtwork(
        address _nftContractAddress,
        uint256 _tokenId,
        string memory _artworkTitle,
        string memory _artworkDescription
    ) public payable {
        require(msg.value >= submissionFee, "Insufficient submission fee");
        submissionCount++;
        artworkSubmissions[submissionCount] = Submission({
            nftContractAddress: _nftContractAddress,
            tokenId: _tokenId,
            artworkTitle: _artworkTitle,
            artworkDescription: _artworkDescription,
            artistAddress: msg.sender,
            submissionTimestamp: block.timestamp,
            isApproved: false,
            isRejected: false
        });
        emit ArtworkSubmitted(submissionCount, _nftContractAddress, _tokenId, msg.sender);
    }

    /**
     * @dev Curator approves a submitted artwork to be displayed in the gallery.
     * @param _submissionId ID of the artwork submission.
     */
    function approveArtwork(uint256 _submissionId) public onlyCurator submissionExists(_submissionId) {
        require(!artworkSubmissions[_submissionId].isApproved, "Submission already approved");
        require(!artworkSubmissions[_submissionId].isRejected, "Submission already rejected");

        artworkCount++;
        artworks[artworkCount] = Artwork({
            nftContractAddress: artworkSubmissions[_submissionId].nftContractAddress,
            tokenId: artworkSubmissions[_submissionId].tokenId,
            artworkTitle: artworkSubmissions[_submissionId].artworkTitle,
            artworkDescription: artworkSubmissions[_submissionId].artworkDescription,
            artistAddress: artworkSubmissions[_submissionId].artistAddress,
            listPrice: 0, // Initially not listed for sale
            isListedForSale: false,
            isApproved: true,
            isFeatured: false,
            metadataURI: "" // Default empty metadata URI
        });
        artworkSubmissions[_submissionId].isApproved = true;
        emit ArtworkApproved(artworkCount, _submissionId);
    }

    /**
     * @dev Curator rejects a submitted artwork.
     * @param _submissionId ID of the artwork submission.
     */
    function rejectArtwork(uint256 _submissionId) public onlyCurator submissionExists(_submissionId) {
        require(!artworkSubmissions[_submissionId].isApproved, "Submission already approved");
        require(!artworkSubmissions[_submissionId].isRejected, "Submission already rejected");
        artworkSubmissions[_submissionId].isRejected = true;
        emit ArtworkRejected(_submissionId);
    }

    /**
     * @dev Artist lists their approved artwork for sale in the gallery.
     * @param _artworkId ID of the artwork in the gallery.
     * @param _price Price at which the artwork is listed for sale (in wei).
     */
    function listArtworkForSale(uint256 _artworkId, uint256 _price) public onlyArtist(_artworkId) artworkExists(_artworkId) {
        require(artworks[_artworkId].isApproved, "Artwork must be approved to be listed for sale");
        require(!artworks[_artworkId].isListedForSale, "Artwork is already listed for sale");
        artworks[_artworkId].listPrice = _price;
        artworks[_artworkId].isListedForSale = true;
        emit ArtworkListedForSale(_artworkId, _price, msg.sender);
    }

    /**
     * @dev Artist unlists their artwork from sale in the gallery.
     * @param _artworkId ID of the artwork in the gallery.
     */
    function unlistArtworkForSale(uint256 _artworkId) public onlyArtist(_artworkId) artworkExists(_artworkId) {
        require(artworks[_artworkId].isListedForSale, "Artwork is not listed for sale");
        artworks[_artworkId].isListedForSale = false;
        artworks[_artworkId].listPrice = 0;
        emit ArtworkUnlistedFromSale(_artworkId, msg.sender);
    }

    /**
     * @dev Purchase an artwork listed for sale. Sends funds to artist and gallery (commission).
     * @param _artworkId ID of the artwork to purchase.
     */
    function purchaseArtwork(uint256 _artworkId) public payable artworkExists(_artworkId) {
        require(artworks[_artworkId].isListedForSale, "Artwork is not listed for sale");
        require(msg.value >= artworks[_artworkId].listPrice, "Insufficient payment");

        uint256 artworkPrice = artworks[_artworkId].listPrice;
        uint256 galleryFee = (artworkPrice * galleryFeePercentage) / 100;
        uint256 artistPayout = artworkPrice - galleryFee;

        artworks[_artworkId].isListedForSale = false; // Artwork is no longer for sale after purchase
        artworks[_artworkId].listPrice = 0;

        (bool artistTransferSuccess, ) = payable(artworks[_artworkId].artistAddress).call{value: artistPayout}("");
        require(artistTransferSuccess, "Artist payment failed");

        (bool galleryFeeTransferSuccess, ) = payable(address(this)).call{value: galleryFee}(""); // Gallery receives fee
        require(galleryFeeTransferSuccess, "Gallery fee transfer failed");


        emit ArtworkPurchased(_artworkId, msg.sender, artworks[_artworkId].artistAddress, artworkPrice, galleryFee);
    }

    /**
     * @dev Curator sets a custom metadata URI for an artwork within the gallery.
     * @param _artworkId ID of the artwork.
     * @param _metadataURI The metadata URI to set.
     */
    function setArtworkMetadataURI(uint256 _artworkId, string memory _metadataURI) public onlyCurator artworkExists(_artworkId) {
        artworks[_artworkId].metadataURI = _metadataURI;
        emit ArtworkMetadataURISet(_artworkId, _metadataURI);
    }


    /**
     * @dev Curator marks an artwork as "featured" for prominent display.
     * @param _artworkId ID of the artwork to feature.
     */
    function featureArtwork(uint256 _artworkId) public onlyCurator artworkExists(_artworkId) {
        artworks[_artworkId].isFeatured = true;
        emit ArtworkFeatured(_artworkId);
    }

    /**
     * @dev Curator removes an artwork from the featured display.
     * @param _artworkId ID of the artwork to unfeature.
     */
    function unfeatureArtwork(uint256 _artworkId) public onlyCurator artworkExists(_artworkId) {
        artworks[_artworkId].isFeatured = false;
        emit ArtworkUnfeatured(_artworkId);
    }

    /**
     * @dev Returns a random featured artwork ID. (Simple random - might be biased in early stages)
     * @return Random featured artwork ID, or 0 if no featured artworks.
     */
    function getRandomFeaturedArtwork() public view returns (uint256) {
        uint256 featuredCount = getFeaturedArtworkCount();
        if (featuredCount == 0) {
            return 0;
        }
        uint256 randomIndex = uint256(blockhash(block.number - 1)) % featuredCount; // Simple pseudo-randomness
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (artworks[i].isFeatured) {
                if (currentIndex == randomIndex) {
                    return i;
                }
                currentIndex++;
            }
        }
        return 0; // Should not reach here, but for safety
    }

    /**
     * @dev Returns the total number of artworks in the gallery.
     * @return Total artwork count.
     */
    function getGalleryArtworkCount() public view returns (uint256) {
        return artworkCount;
    }

    /**
     * @dev Returns the number of featured artworks.
     * @return Number of featured artworks.
     */
    function getFeaturedArtworkCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (artworks[i].isFeatured) {
                count++;
            }
        }
        return count;
    }

    /**
     * @dev Returns detailed information about an artwork in the gallery.
     * @param _artworkId ID of the artwork.
     * @return Artwork details struct.
     */
    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /**
     * @dev Returns the total number of artwork submissions.
     * @return Total submission count.
     */
    function getSubmissionsCount() public view returns (uint256) {
        return submissionCount;
    }

    /**
     * @dev Returns details of a specific artwork submission.
     * @param _submissionId ID of the artwork submission.
     * @return Submission details struct.
     */
    function getSubmissionDetails(uint256 _submissionId) public view submissionExists(_submissionId) returns (Submission memory) {
        return artworkSubmissions[_submissionId];
    }

    /**
     * @dev DAO-controlled emergency withdrawal function.
     * @param _recipient Address to receive the withdrawn ETH.
     * @param _amount Amount of ETH to withdraw.
     */
    function emergencyWithdraw(address _recipient, uint256 _amount) public onlyDAO {
        require(_recipient != address(0), "Recipient address cannot be zero address");
        require(_amount <= address(this).balance, "Insufficient contract balance");
        (bool success, ) = payable(_recipient).call{value: _amount}("");
        require(success, "Emergency withdrawal failed");
        emit EmergencyWithdrawal(_recipient, _amount);
    }

    /**
     * @dev Returns the contract's ETH balance.
     * @return Contract's ETH balance.
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive Ether
    receive() external payable {}
}
```