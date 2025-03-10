```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery - Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a Decentralized Autonomous Art Gallery, enabling artists to submit artwork,
 * curators to vote on submissions, dynamic pricing based on popularity, community-driven theme proposals,
 * decentralized copyright registry, fractionalized artwork ownership, and advanced features.
 *
 * Function Summary:
 * -----------------
 * **Core Art Gallery Functions:**
 * 1. submitArtwork(string memory _title, string memory _ipfsHash, uint256 _initialPrice): Allows artists to submit artwork with title, IPFS hash, and initial price.
 * 2. voteOnArtwork(uint256 _artworkId, bool _approve): Curators can vote to approve or reject submitted artwork.
 * 3. featureArtwork(uint256 _artworkId): Admin/Curators can manually feature an approved artwork in the gallery.
 * 4. purchaseArtwork(uint256 _artworkId): Users can purchase artwork, increasing its popularity and price.
 * 5. viewArtworkDetails(uint256 _artworkId): Retrieve detailed information about a specific artwork.
 * 6. listFeaturedArtworks(): View a list of IDs of currently featured artworks.
 * 7. getGalleryBalance(): View the contract's current balance.
 * 8. withdrawArtistEarnings(): Artists can withdraw their earnings from artwork sales.
 *
 * **Dynamic Pricing and Popularity:**
 * 9. calculateDynamicPrice(uint256 _artworkId): Calculates the current dynamic price of an artwork based on popularity (purchases).
 * 10. increaseArtworkPopularity(uint256 _artworkId): (Internal) Increases the popularity counter of an artwork.
 * 11. decreaseArtworkPopularity(uint256 _artworkId): (Admin/Curator) Manually decrease artwork popularity (e.g., for removal consideration).
 *
 * **Community & Governance Features:**
 * 12. proposeTheme(string memory _themeProposal, string memory _description): Community members can propose new gallery themes.
 * 13. voteOnThemeProposal(uint256 _proposalId, bool _approve): Community members can vote on proposed themes.
 * 14. executeThemeProposal(uint256 _proposalId): Admin/Curators can execute approved theme proposals (implementation not specified in detail here but could trigger events or contract state changes).
 * 15. registerCopyright(uint256 _artworkId, string memory _copyrightDetails): Artists can register copyright information for their artwork on-chain.
 * 16. transferArtworkOwnership(uint256 _artworkId, address _newOwner): Transfer full ownership of an artwork (if enabled).
 *
 * **Fractionalized Ownership (Conceptual):**
 * 17. fractionalizeArtwork(uint256 _artworkId, uint256 _numberOfFractions): (Conceptual - Basic outline) Allow artwork to be fractionalized into ERC-20 tokens.
 * 18. purchaseFraction(uint256 _artworkId, uint256 _fractionAmount): (Conceptual - Basic outline) Purchase fractions of an artwork.
 * 19. listFractionHolders(uint256 _artworkId): (Conceptual - Basic outline) View addresses holding fractions of an artwork.
 *
 * **Advanced & Utility Functions:**
 * 20. setCurator(address _curatorAddress, bool _isCurator): Admin function to add or remove curators.
 * 21. isCurator(address _address): Check if an address is a curator.
 * 22. setGalleryFeePercentage(uint256 _feePercentage): Admin function to set the gallery fee percentage on sales.
 * 23. getGalleryFeePercentage(): View the current gallery fee percentage.
 * 24. pauseContract(): Admin function to pause core contract functionalities in case of emergency.
 * 25. unpauseContract(): Admin function to unpause contract functionalities.
 * 26. emergencyWithdraw(address payable _recipient, uint256 _amount): Admin function for emergency withdrawal of funds.
 */

contract DecentralizedAutonomousArtGallery {

    // --- Data Structures ---
    struct Artwork {
        uint256 id;
        address artist;
        string title;
        string ipfsHash;
        uint256 initialPrice;
        uint256 currentPrice;
        uint256 popularity;
        bool isApproved;
        bool isFeatured;
        bool isCopyrightRegistered;
        string copyrightDetails;
        address currentOwner; // Initially artist, can be transferred fully or fractionally
    }

    struct ThemeProposal {
        uint256 id;
        string proposal;
        string description;
        address proposer;
        uint256 upvotes;
        uint256 downvotes;
        bool isExecuted;
    }

    // --- State Variables ---
    mapping(uint256 => Artwork) public artworks; // Artwork ID => Artwork Details
    mapping(uint256 => ThemeProposal) public themeProposals; // Proposal ID => Theme Proposal Details
    mapping(address => bool) public curators; // Address => Is Curator?
    address public galleryOwner; // Contract deployer
    uint256 public galleryFeePercentage = 5; // Default gallery fee percentage (5%)
    uint256 public artworkCounter;
    uint256 public proposalCounter;
    bool public paused = false;

    // --- Events ---
    event ArtworkSubmitted(uint256 artworkId, address artist, string title, string ipfsHash, uint256 initialPrice);
    event ArtworkVoted(uint256 artworkId, address curator, bool approved);
    event ArtworkFeatured(uint256 artworkId);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event ThemeProposed(uint256 proposalId, address proposer, string theme, string description);
    event ThemeVoted(uint256 proposalId, address voter, bool approved);
    event ThemeExecuted(uint256 proposalId);
    event CopyrightRegistered(uint256 artworkId);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);
    event CuratorSet(address curator, bool isCurator);
    event GalleryFeePercentageChanged(uint256 newPercentage);
    event ContractPaused();
    event ContractUnpaused();
    event EmergencyWithdrawal(address recipient, uint256 amount);

    // --- Modifiers ---
    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can perform this action.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender] || msg.sender == galleryOwner, "Only curators or gallery owner can perform this action.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(artworks[_artworkId].id != 0, "Artwork does not exist.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently paused.");
        _;
    }

    // --- Constructor ---
    constructor() {
        galleryOwner = msg.sender;
        curators[msg.sender] = true; // Deployer is the initial curator
        artworkCounter = 1;
        proposalCounter = 1;
    }

    // --- Core Art Gallery Functions ---

    /// @notice Allows artists to submit artwork to the gallery.
    /// @param _title The title of the artwork.
    /// @param _ipfsHash The IPFS hash of the artwork's digital asset.
    /// @param _initialPrice The initial price of the artwork in wei.
    function submitArtwork(string memory _title, string memory _ipfsHash, uint256 _initialPrice) external notPaused {
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0, "Title and IPFS hash cannot be empty.");
        require(_initialPrice > 0, "Initial price must be greater than zero.");

        artworks[artworkCounter] = Artwork({
            id: artworkCounter,
            artist: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            initialPrice: _initialPrice,
            currentPrice: _initialPrice,
            popularity: 0,
            isApproved: false,
            isFeatured: false,
            isCopyrightRegistered: false,
            copyrightDetails: "",
            currentOwner: msg.sender
        });

        emit ArtworkSubmitted(artworkCounter, msg.sender, _title, _ipfsHash, _initialPrice);
        artworkCounter++;
    }

    /// @notice Curators can vote to approve or reject a submitted artwork.
    /// @param _artworkId The ID of the artwork to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnArtwork(uint256 _artworkId, bool _approve) external onlyCurator notPaused artworkExists(_artworkId) {
        require(!artworks[_artworkId].isApproved, "Artwork already voted on.");

        artworks[_artworkId].isApproved = _approve;
        emit ArtworkVoted(_artworkId, msg.sender, _approve);
    }

    /// @notice Admin/Curators can manually feature an approved artwork in the gallery.
    /// @param _artworkId The ID of the artwork to feature.
    function featureArtwork(uint256 _artworkId) external onlyCurator notPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].isApproved, "Artwork must be approved before featuring.");
        require(!artworks[_artworkId].isFeatured, "Artwork is already featured.");

        artworks[_artworkId].isFeatured = true;
        emit ArtworkFeatured(_artworkId);
    }

    /// @notice Users can purchase artwork, increasing its popularity and price.
    /// @param _artworkId The ID of the artwork to purchase.
    function purchaseArtwork(uint256 _artworkId) external payable notPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].isFeatured, "Artwork must be featured to be purchased.");
        require(msg.value >= artworks[_artworkId].currentPrice, "Insufficient funds to purchase artwork.");

        uint256 galleryFee = (artworks[_artworkId].currentPrice * galleryFeePercentage) / 100;
        uint256 artistEarnings = artworks[_artworkId].currentPrice - galleryFee;

        // Transfer funds
        payable(artworks[_artworkId].artist).transfer(artistEarnings);
        payable(galleryOwner).transfer(galleryFee); // Gallery owner receives the fee

        increaseArtworkPopularity(_artworkId);
        artworks[_artworkId].currentOwner = msg.sender; // New owner after purchase

        emit ArtworkPurchased(_artworkId, msg.sender, artworks[_artworkId].currentPrice);
    }

    /// @notice Retrieve detailed information about a specific artwork.
    /// @param _artworkId The ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function viewArtworkDetails(uint256 _artworkId) external view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @notice View a list of IDs of currently featured artworks.
    /// @return Array of artwork IDs that are featured.
    function listFeaturedArtworks() external view returns (uint256[] memory) {
        uint256[] memory featuredArtworkIds = new uint256[](artworkCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < artworkCounter; i++) {
            if (artworks[i].isFeatured) {
                featuredArtworkIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of featured artworks
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = featuredArtworkIds[i];
        }
        return result;
    }

    /// @notice View the contract's current balance.
    /// @return The contract's balance in wei.
    function getGalleryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Artists can withdraw their earnings from artwork sales.
    //  In this simplified version, earnings are transferred directly during purchase.
    //  For a more complex system, we might track artist balances separately.
    function withdrawArtistEarnings() external {
        revert("Earnings are transferred to artists directly upon purchase in this version.");
    }


    // --- Dynamic Pricing and Popularity ---

    /// @notice Calculates the current dynamic price of an artwork based on popularity (purchases).
    /// @param _artworkId The ID of the artwork.
    /// @return The current dynamic price of the artwork.
    function calculateDynamicPrice(uint256 _artworkId) public view artworkExists(_artworkId) returns (uint256) {
        // Example dynamic pricing logic: Price increases by 1% for every purchase, capped at 10x initial price.
        uint256 priceIncreasePercentage = artworks[_artworkId].popularity; // Simplified for example
        uint256 priceIncrease = (artworks[_artworkId].initialPrice * priceIncreasePercentage) / 100;
        uint256 dynamicPrice = artworks[_artworkId].initialPrice + priceIncrease;

        // Cap the dynamic price to prevent excessive inflation
        uint256 maxPrice = artworks[_artworkId].initialPrice * 10;
        return dynamicPrice > maxPrice ? maxPrice : dynamicPrice;
    }

    /// @notice (Internal) Increases the popularity counter of an artwork and updates the current price.
    /// @param _artworkId The ID of the artwork.
    function increaseArtworkPopularity(uint256 _artworkId) internal artworkExists(_artworkId) {
        artworks[_artworkId].popularity++;
        artworks[_artworkId].currentPrice = calculateDynamicPrice(_artworkId);
    }

    /// @notice (Admin/Curator) Manually decrease artwork popularity (e.g., for removal consideration).
    /// @param _artworkId The ID of the artwork.
    function decreaseArtworkPopularity(uint256 _artworkId) external onlyCurator notPaused artworkExists(_artworkId) {
        if (artworks[_artworkId].popularity > 0) {
            artworks[_artworkId].popularity--;
            artworks[_artworkId].currentPrice = calculateDynamicPrice(_artworkId); // Recalculate price
        }
    }


    // --- Community & Governance Features ---

    /// @notice Community members can propose new gallery themes.
    /// @param _themeProposal The proposed theme name.
    /// @param _description A description of the theme proposal.
    function proposeTheme(string memory _themeProposal, string memory _description) external notPaused {
        require(bytes(_themeProposal).length > 0, "Theme proposal cannot be empty.");

        themeProposals[proposalCounter] = ThemeProposal({
            id: proposalCounter,
            proposal: _themeProposal,
            description: _description,
            proposer: msg.sender,
            upvotes: 0,
            downvotes: 0,
            isExecuted: false
        });

        emit ThemeProposed(proposalCounter, msg.sender, _themeProposal, _description);
        proposalCounter++;
    }

    /// @notice Community members can vote on proposed themes.
    /// @param _proposalId The ID of the theme proposal.
    /// @param _approve True to upvote, false to downvote.
    function voteOnThemeProposal(uint256 _proposalId, bool _approve) external notPaused {
        require(themeProposals[_proposalId].id != 0, "Theme proposal does not exist.");
        require(!themeProposals[_proposalId].isExecuted, "Theme proposal already executed.");

        if (_approve) {
            themeProposals[_proposalId].upvotes++;
        } else {
            themeProposals[_proposalId].downvotes++;
        }
        emit ThemeVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Admin/Curators can execute approved theme proposals (implementation is conceptual here).
    /// @param _proposalId The ID of the theme proposal to execute.
    function executeThemeProposal(uint256 _proposalId) external onlyCurator notPaused {
        require(themeProposals[_proposalId].id != 0, "Theme proposal does not exist.");
        require(!themeProposals[_proposalId].isExecuted, "Theme proposal already executed.");
        require(themeProposals[_proposalId].upvotes > themeProposals[_proposalId].downvotes, "Theme proposal not sufficiently upvoted.");

        themeProposals[_proposalId].isExecuted = true;
        // In a real implementation, this could trigger actions like:
        // - Filtering artworks displayed in the gallery based on the theme
        // - Updating the gallery's UI or description
        // - Triggering events for off-chain processes related to the theme

        emit ThemeExecuted(_proposalId);
    }

    /// @notice Artists can register copyright information for their artwork on-chain.
    /// @param _artworkId The ID of the artwork.
    /// @param _copyrightDetails String containing copyright details (e.g., license type, terms).
    function registerCopyright(uint256 _artworkId, string memory _copyrightDetails) external notPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].artist == msg.sender, "Only the artist can register copyright.");
        require(!artworks[_artworkId].isCopyrightRegistered, "Copyright already registered.");
        require(bytes(_copyrightDetails).length > 0, "Copyright details cannot be empty.");

        artworks[_artworkId].isCopyrightRegistered = true;
        artworks[_artworkId].copyrightDetails = _copyrightDetails;
        emit CopyrightRegistered(_artworkId);
    }

    /// @notice Transfer full ownership of an artwork to another address (optional, can be enabled/disabled).
    /// @param _artworkId The ID of the artwork.
    /// @param _newOwner The address of the new owner.
    function transferArtworkOwnership(uint256 _artworkId, address _newOwner) external notPaused artworkExists(_artworkId) {
        require(artworks[_artworkId].currentOwner == msg.sender, "You are not the current owner of this artwork.");
        require(_newOwner != address(0), "Invalid new owner address.");
        require(_newOwner != address(this), "Cannot transfer ownership to the contract.");
        require(_newOwner != artworks[_artworkId].artist, "Cannot transfer ownership back to the original artist using this function."); // Optional restriction

        artworks[_artworkId].currentOwner = _newOwner;
        // Consider emitting an event for ownership transfer
    }


    // --- Fractionalized Ownership (Conceptual - Basic Outline) ---
    // Note: This is a simplified conceptual outline. Full fractionalization requires ERC-20 token implementation,
    //       more complex logic for token distribution, and potentially external services.

    /// @notice (Conceptual) Allows artwork to be fractionalized into ERC-20 tokens.
    /// @param _artworkId The ID of the artwork to fractionalize.
    /// @param _numberOfFractions The number of fractions (ERC-20 tokens) to create.
    function fractionalizeArtwork(uint256 _artworkId, uint256 _numberOfFractions) external onlyGalleryOwner notPaused artworkExists(_artworkId) {
        revert("Fractionalization feature is conceptual and not fully implemented in this version.");
        // In a real implementation:
        // 1. Deploy an ERC-20 token contract specifically for this artwork.
        // 2. Mint _numberOfFractions tokens to the contract owner (or distribute as needed).
        // 3. Update artwork state to indicate it's fractionalized and link to the ERC-20 contract.
    }

    /// @notice (Conceptual) Purchase fractions of an artwork.
    /// @param _artworkId The ID of the artwork.
    /// @param _fractionAmount The number of fractions to purchase.
    function purchaseFraction(uint256 _artworkId, uint256 _fractionAmount) external payable notPaused artworkExists(_artworkId) {
        revert("Fractionalization feature is conceptual and not fully implemented in this version.");
        // In a real implementation:
        // 1. Check if artwork is fractionalized.
        // 2. Transfer funds for the fractions.
        // 3. Transfer ERC-20 tokens representing fractions to the buyer.
    }

    /// @notice (Conceptual) View addresses holding fractions of an artwork.
    /// @param _artworkId The ID of the artwork.
    /// @return Array of addresses holding fractions (conceptual).
    function listFractionHolders(uint256 _artworkId) external view artworkExists(_artworkId) returns (address[] memory) {
        revert("Fractionalization feature is conceptual and not fully implemented in this version.");
        // In a real implementation:
        // 1. Query the ERC-20 token contract associated with the artwork.
        // 2. Get a list of holders of that token.
        return new address[](0); // Placeholder
    }


    // --- Advanced & Utility Functions ---

    /// @notice Admin function to add or remove curators.
    /// @param _curatorAddress The address to set as curator.
    /// @param _isCurator True to add as curator, false to remove.
    function setCurator(address _curatorAddress, bool _isCurator) external onlyGalleryOwner notPaused {
        require(_curatorAddress != address(0), "Invalid curator address.");
        curators[_curatorAddress] = _isCurator;
        emit CuratorSet(_curatorAddress, _isCurator);
    }

    /// @notice Check if an address is a curator.
    /// @param _address The address to check.
    /// @return True if the address is a curator, false otherwise.
    function isCurator(address _address) external view returns (bool) {
        return curators[_address];
    }

    /// @notice Admin function to set the gallery fee percentage on sales.
    /// @param _feePercentage The new gallery fee percentage (0-100).
    function setGalleryFeePercentage(uint256 _feePercentage) external onlyGalleryOwner notPaused {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeePercentageChanged(_feePercentage);
    }

    /// @notice View the current gallery fee percentage.
    /// @return The current gallery fee percentage.
    function getGalleryFeePercentage() external view returns (uint256) {
        return galleryFeePercentage;
    }

    /// @notice Admin function to pause core contract functionalities in case of emergency.
    function pauseContract() external onlyGalleryOwner notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to unpause contract functionalities.
    function unpauseContract() external onlyGalleryOwner {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Admin function for emergency withdrawal of funds from the contract.
    /// @param _recipient The address to receive the withdrawn funds.
    /// @param _amount The amount to withdraw in wei.
    function emergencyWithdraw(address payable _recipient, uint256 _amount) external onlyGalleryOwner notPaused {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount <= address(this).balance, "Withdrawal amount exceeds contract balance.");

        _recipient.transfer(_amount);
        emit EmergencyWithdrawal(_recipient, _amount);
    }
}
```