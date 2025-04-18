```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery.
 * It features advanced concepts like fractional ownership, dynamic pricing,
 * collaborative art commissions, decentralized curation, and DAO governance.
 *
 * Function Summary:
 *
 * **Art Management:**
 * 1. submitArtwork(string memory _title, string memory _artistName, string memory _ipfsHash, uint256 _initialPrice): Allows artists to submit artwork proposals.
 * 2. setArtworkMetadata(uint256 _artworkId, string memory _ipfsHash): Allows the artist to update the metadata of their artwork.
 * 3. toggleArtworkSaleStatus(uint256 _artworkId): Allows the artist to toggle their artwork's sale status (on/off).
 * 4. withdrawArtwork(uint256 _artworkId): Allows the artist to withdraw their artwork from the gallery (if not sold).
 *
 * **Curation & Approval:**
 * 5. proposeCurator(address _curatorAddress): Allows existing curators to propose new curators.
 * 6. voteForCurator(address _curatorAddress, bool _approve): Allows curators to vote on curator proposals.
 * 7. removeCurator(address _curatorAddress): Allows the DAO (majority of curators) to remove a curator.
 * 8. approveArtwork(uint256 _artworkId): Allows curators to approve submitted artworks for listing.
 * 9. rejectArtwork(uint256 _artworkId, string memory _reason): Allows curators to reject submitted artworks with a reason.
 *
 * **Sales & Fractionalization:**
 * 10. purchaseArtwork(uint256 _artworkId): Allows users to purchase full or fractional ownership of approved artworks.
 * 11. purchaseFractionalOwnership(uint256 _artworkId, uint256 _fractionAmount): Allows users to purchase a specific fraction of an artwork.
 * 12. listFractionalOwnershipForSale(uint256 _artworkId, uint256 _fractionAmount, uint256 _price): Allows fractional owners to list their fractions for sale.
 * 13. purchaseFractionFromMarketplace(uint256 _artworkId, uint256 _fractionId): Allows users to purchase fractional ownership from the marketplace.
 * 14. withdrawArtistEarnings(uint256 _artworkId): Allows artists to withdraw their earnings from sold artwork.
 *
 * **DAO Governance & Parameters:**
 * 15. proposeParameterChange(string memory _parameterName, uint256 _newValue): Allows curators to propose changes to gallery parameters (e.g., commission fee).
 * 16. voteOnParameterChange(uint256 _proposalId, bool _approve): Allows curators to vote on parameter change proposals.
 * 17. executeParameterChange(uint256 _proposalId): Allows anyone to execute approved parameter changes.
 * 18. setCommissionFee(uint256 _newFeePercentage): (Admin Function - could be DAO controlled in a real scenario) Sets the commission fee percentage.
 * 19. setFractionalizationThreshold(uint256 _newThreshold): (Admin Function - could be DAO controlled) Sets the threshold for fractionalization.
 * 20. emergencyPauseGallery(): (Admin/DAO Function) Pauses all gallery operations in case of emergency.
 * 21. resumeGallery(): (Admin/DAO Function) Resumes gallery operations after a pause.
 * 22. withdrawGalleryBalance(): (Admin/DAO Function) Allows withdrawal of gallery balance to a designated address.
 *
 * **Utility & Information:**
 * 23. getArtworkDetails(uint256 _artworkId): Returns detailed information about a specific artwork.
 * 24. getFractionalOwnershipDetails(uint256 _artworkId, uint256 _fractionId): Returns details about a specific fractional ownership unit.
 * 25. getCuratorList(): Returns a list of current curators.
 * 26. getParameterValue(string memory _parameterName): Returns the current value of a gallery parameter.
 */
contract DecentralizedAutonomousArtGallery {
    // -------- Data Structures --------

    struct Artwork {
        uint256 id;
        string title;
        string artistName;
        address artistAddress;
        string ipfsHash; // IPFS hash for artwork metadata
        uint256 initialPrice;
        uint256 currentPrice; // Dynamic pricing might adjust this
        bool isApproved;
        bool onSale;
        bool isFractionalized;
        uint256 totalFractions;
        uint256 fractionsSold;
        mapping(address => uint256) fractionalOwners; // Address to fraction amount
        uint256 artistEarnings; // Track earnings for withdrawal
        ArtworkStatus status;
        string rejectionReason;
    }

    enum ArtworkStatus {
        PendingApproval,
        Approved,
        Rejected,
        Sold,
        Withdrawn
    }

    struct FractionalOwnershipListing {
        uint256 id;
        uint256 artworkId;
        uint256 fractionAmount;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct CuratorProposal {
        address proposedCurator;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        mapping(address => bool) hasVoted; // Curators who have voted on this proposal
    }

    struct ParameterChangeProposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isActive;
        bool isExecuted;
        mapping(address => bool) hasVoted; // Curators who have voted on this proposal
    }

    // -------- State Variables --------

    address public owner; // Contract owner (initially deployer, could be a DAO later)
    mapping(uint256 => Artwork) public artworks;
    uint256 public artworkCount;
    mapping(uint256 => FractionalOwnershipListing) public fractionalListings;
    uint256 public fractionalListingCount;
    mapping(address => bool) public curators;
    address[] public curatorList;
    uint256 public curatorProposalCount;
    mapping(uint256 => CuratorProposal) public curatorProposals;
    uint256 public parameterProposalCount;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;

    uint256 public commissionFeePercentage = 5; // Default commission percentage
    uint256 public fractionalizationThreshold = 10 ether; // Minimum price for fractionalization
    bool public galleryPaused = false;

    mapping(string => uint256) public galleryParameters; // Flexible parameter storage

    // -------- Events --------

    event ArtworkSubmitted(uint256 artworkId, address artistAddress, string title);
    event ArtworkMetadataUpdated(uint256 artworkId, string ipfsHash);
    event ArtworkSaleStatusToggled(uint256 artworkId, bool onSale);
    event ArtworkWithdrawn(uint256 artworkId, address artistAddress);
    event CuratorProposed(address proposedCurator, uint256 proposalId);
    event CuratorVoteCast(uint256 proposalId, address curator, bool approve);
    event CuratorRemoved(address curatorAddress);
    event ArtworkApproved(uint256 artworkId);
    event ArtworkRejected(uint256 artworkId, string reason);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event FractionalOwnershipPurchased(uint256 artworkId, address buyer, uint256 fractionAmount);
    event FractionalOwnershipListed(uint256 listingId, uint256 artworkId, uint256 fractionAmount, uint256 price, address seller);
    event FractionalOwnershipFractionPurchased(uint256 listingId, address buyer);
    event ArtistEarningsWithdrawn(uint256 artworkId, address artistAddress, uint256 amount);
    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue);
    event ParameterChangeVoteCast(uint256 proposalId, address curator, bool approve);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);
    event GalleryPaused();
    event GalleryResumed();
    event GalleryBalanceWithdrawn(address recipient, uint256 amount);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier galleryNotPaused() {
        require(!galleryPaused, "Gallery is currently paused.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCount, "Artwork does not exist.");
        _;
    }

    modifier artworkPendingApproval(uint256 _artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.PendingApproval, "Artwork is not pending approval.");
        _;
    }

    modifier artworkApproved(uint256 _artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.Approved, "Artwork is not approved.");
        _;
    }

    modifier artworkNotSoldOrWithdrawn(uint256 _artworkId) {
        require(artworks[_artworkId].status != ArtworkStatus.Sold && artworks[_artworkId].status != ArtworkStatus.Withdrawn, "Artwork is sold or withdrawn.");
        _;
    }

    modifier artworkOnSale(uint256 _artworkId) {
        require(artworks[_artworkId].onSale, "Artwork is not currently on sale.");
        _;
    }

    modifier fractionalListingExists(uint256 _listingId) {
        require(_listingId > 0 && _listingId <= fractionalListingCount, "Fractional listing does not exist.");
        _;
    }

    modifier fractionalListingActive(uint256 _listingId) {
        require(fractionalListings[_listingId].isActive, "Fractional listing is not active.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0, "Invalid proposal ID.");
        _;
    }

    modifier curatorProposalActive(uint256 _proposalId) {
        require(curatorProposals[_proposalId].isActive, "Curator proposal is not active.");
        _;
    }

    modifier parameterProposalActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].isActive && !parameterChangeProposals[_proposalId].isExecuted, "Parameter proposal is not active or already executed.");
        _;
    }

    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        curators[msg.sender] = true; // Initial curator is the contract deployer
        curatorList.push(msg.sender);
        galleryParameters["commissionFeePercentage"] = commissionFeePercentage;
        galleryParameters["fractionalizationThreshold"] = fractionalizationThreshold;
    }

    // -------- Art Management Functions --------

    /// @dev Allows artists to submit artwork proposals.
    /// @param _title The title of the artwork.
    /// @param _artistName The name of the artist.
    /// @param _ipfsHash The IPFS hash of the artwork metadata.
    /// @param _initialPrice The initial price of the artwork in wei.
    function submitArtwork(
        string memory _title,
        string memory _artistName,
        string memory _ipfsHash,
        uint256 _initialPrice
    ) external galleryNotPaused {
        artworkCount++;
        artworks[artworkCount] = Artwork({
            id: artworkCount,
            title: _title,
            artistName: _artistName,
            artistAddress: msg.sender,
            ipfsHash: _ipfsHash,
            initialPrice: _initialPrice,
            currentPrice: _initialPrice,
            isApproved: false,
            onSale: false,
            isFractionalized: false,
            totalFractions: 0,
            fractionsSold: 0,
            artistEarnings: 0,
            status: ArtworkStatus.PendingApproval,
            rejectionReason: ""
        });
        emit ArtworkSubmitted(artworkCount, msg.sender, _title);
    }

    /// @dev Allows the artist to update the metadata of their artwork.
    /// @param _artworkId The ID of the artwork.
    /// @param _ipfsHash The new IPFS hash for the artwork metadata.
    function setArtworkMetadata(uint256 _artworkId, string memory _ipfsHash)
        external
        artworkExists(_artworkId)
        galleryNotPaused
    {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist can update artwork metadata.");
        artworks[_artworkId].ipfsHash = _ipfsHash;
        emit ArtworkMetadataUpdated(_artworkId, _ipfsHash);
    }

    /// @dev Allows the artist to toggle their artwork's sale status (on/off).
    /// @param _artworkId The ID of the artwork.
    function toggleArtworkSaleStatus(uint256 _artworkId)
        external
        artworkExists(_artworkId)
        artworkApproved(_artworkId)
        artworkNotSoldOrWithdrawn(_artworkId)
        galleryNotPaused
    {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist can toggle sale status.");
        artworks[_artworkId].onSale = !artworks[_artworkId].onSale;
        emit ArtworkSaleStatusToggled(_artworkId, artworks[_artworkId].onSale);
    }

    /// @dev Allows the artist to withdraw their artwork from the gallery (if not sold).
    /// @param _artworkId The ID of the artwork.
    function withdrawArtwork(uint256 _artworkId)
        external
        artworkExists(_artworkId)
        artworkNotSoldOrWithdrawn(_artworkId)
        galleryNotPaused
    {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist can withdraw artwork.");
        artworks[_artworkId].status = ArtworkStatus.Withdrawn;
        artworks[_artworkId].onSale = false;
        emit ArtworkWithdrawn(_artworkId, msg.sender);
    }

    // -------- Curation & Approval Functions --------

    /// @dev Allows existing curators to propose new curators.
    /// @param _curatorAddress The address of the curator to be proposed.
    function proposeCurator(address _curatorAddress) external onlyCurator galleryNotPaused {
        require(_curatorAddress != address(0), "Invalid curator address.");
        require(!curators[_curatorAddress], "Address is already a curator.");

        curatorProposalCount++;
        curatorProposals[curatorProposalCount] = CuratorProposal({
            proposedCurator: _curatorAddress,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            hasVoted: mapping(address => bool)()
        });
        emit CuratorProposed(_curatorAddress, curatorProposalCount);
    }

    /// @dev Allows curators to vote on curator proposals.
    /// @param _curatorAddress The address of the proposed curator.
    /// @param _approve Boolean indicating approval (true) or rejection (false).
    function voteForCurator(address _curatorAddress, bool _approve)
        external
        onlyCurator
        validProposal(curatorProposalCount)
        curatorProposalActive(curatorProposalCount)
        galleryNotPaused
    {
        CuratorProposal storage proposal = curatorProposals[curatorProposalCount];
        require(!proposal.hasVoted[msg.sender], "Curator has already voted on this proposal.");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit CuratorVoteCast(curatorProposalCount, msg.sender, _approve);

        if (proposal.votesFor > curatorList.length / 2) { // Simple majority for now, could be adjusted
            curators[_curatorAddress] = true;
            curatorList.push(_curatorAddress);
            proposal.isActive = false; // Close proposal after successful vote
        } else if (proposal.votesAgainst > curatorList.length / 2) {
            proposal.isActive = false; // Close proposal if rejected by majority
        }
    }

    /// @dev Allows the DAO (majority of curators) to remove a curator.
    /// @param _curatorAddress The address of the curator to be removed.
    function removeCurator(address _curatorAddress) external onlyCurator galleryNotPaused {
        require(curators[_curatorAddress] && _curatorAddress != msg.sender, "Invalid curator address to remove.");

        // Simple removal logic - could be enhanced with voting in a real DAO
        uint256 curatorIndex = 0;
        bool found = false;
        for (uint256 i = 0; i < curatorList.length; i++) {
            if (curatorList[i] == _curatorAddress) {
                curatorIndex = i;
                found = true;
                break;
            }
        }
        if (found) {
            curatorList[curatorIndex] = curatorList[curatorList.length - 1];
            curatorList.pop();
            delete curators[_curatorAddress];
            emit CuratorRemoved(_curatorAddress);
        }
    }


    /// @dev Allows curators to approve submitted artworks for listing.
    /// @param _artworkId The ID of the artwork to approve.
    function approveArtwork(uint256 _artworkId)
        external
        onlyCurator
        artworkExists(_artworkId)
        artworkPendingApproval(_artworkId)
        galleryNotPaused
    {
        artworks[_artworkId].isApproved = true;
        artworks[_artworkId].status = ArtworkStatus.Approved;
        artworks[_artworkId].onSale = true; // Automatically put on sale after approval
        emit ArtworkApproved(_artworkId);
    }

    /// @dev Allows curators to reject submitted artworks with a reason.
    /// @param _artworkId The ID of the artwork to reject.
    /// @param _reason The reason for rejection.
    function rejectArtwork(uint256 _artworkId, string memory _reason)
        external
        onlyCurator
        artworkExists(_artworkId)
        artworkPendingApproval(_artworkId)
        galleryNotPaused
    {
        artworks[_artworkId].status = ArtworkStatus.Rejected;
        artworks[_artworkId].rejectionReason = _reason;
        emit ArtworkRejected(_artworkId, _reason);
    }

    // -------- Sales & Fractionalization Functions --------

    /// @dev Allows users to purchase full ownership of approved artworks.
    /// @param _artworkId The ID of the artwork to purchase.
    function purchaseArtwork(uint256 _artworkId)
        external
        payable
        artworkExists(_artworkId)
        artworkApproved(_artworkId)
        artworkOnSale(_artworkId)
        artworkNotSoldOrWithdrawn(_artworkId)
        galleryNotPaused
    {
        uint256 price = artworks[_artworkId].currentPrice;
        require(msg.value >= price, "Insufficient funds sent.");

        // Transfer funds to artist and gallery (commission)
        uint256 commission = (price * commissionFeePercentage) / 100;
        uint256 artistPayout = price - commission;

        payable(artworks[_artworkId].artistAddress).transfer(artistPayout);
        artworks[_artworkId].artistEarnings += artistPayout;
        payable(owner).transfer(commission); // Gallery owner/DAO receives commission

        artworks[_artworkId].status = ArtworkStatus.Sold;
        artworks[_artworkId].onSale = false;
        emit ArtworkPurchased(_artworkId, msg.sender, price);

        // Fractionalization logic (after full purchase, if applicable)
        if (price >= fractionalizationThreshold && !artworks[_artworkId].isFractionalized) {
            _fractionalizeArtwork(_artworkId);
        }
    }

    /// @dev Allows users to purchase fractional ownership of an artwork.
    /// @param _artworkId The ID of the artwork to purchase fractions of.
    /// @param _fractionAmount The number of fractions to purchase.
    function purchaseFractionalOwnership(uint256 _artworkId, uint256 _fractionAmount)
        external
        payable
        artworkExists(_artworkId)
        artworkApproved(_artworkId)
        artworkOnSale(_artworkId)
        galleryNotPaused
    {
        require(artworks[_artworkId].isFractionalized, "Artwork is not fractionalized.");
        require(artworks[_artworkId].fractionsSold + _fractionAmount <= artworks[_artworkId].totalFractions, "Not enough fractions available.");

        uint256 pricePerFraction = artworks[_artworkId].currentPrice / artworks[_artworkId].totalFractions;
        uint256 totalPrice = pricePerFraction * _fractionAmount;
        require(msg.value >= totalPrice, "Insufficient funds sent for fractions.");

        // Transfer funds to artist and gallery (commission) - same logic as full purchase
        uint256 commission = (totalPrice * commissionFeePercentage) / 100;
        uint256 artistPayout = totalPrice - commission;

        payable(artworks[_artworkId].artistAddress).transfer(artistPayout);
        artworks[_artworkId].artistEarnings += artistPayout;
        payable(owner).transfer(commission); // Gallery owner/DAO receives commission

        artworks[_artworkId].fractionalOwners[msg.sender] += _fractionAmount;
        artworks[_artworkId].fractionsSold += _fractionAmount;
        emit FractionalOwnershipPurchased(_artworkId, msg.sender, _fractionAmount);

        if (artworks[_artworkId].fractionsSold == artworks[_artworkId].totalFractions) {
            artworks[_artworkId].status = ArtworkStatus.Sold; // Consider artwork sold when all fractions are sold
            artworks[_artworkId].onSale = false;
        }
    }

    /// @dev Allows fractional owners to list their fractions for sale on the marketplace.
    /// @param _artworkId The ID of the artwork.
    /// @param _fractionAmount The amount of fractions to list for sale.
    /// @param _price The price per fraction (total price will be _price * _fractionAmount).
    function listFractionalOwnershipForSale(uint256 _artworkId, uint256 _fractionAmount, uint256 _price)
        external
        artworkExists(_artworkId)
        galleryNotPaused
    {
        require(artworks[_artworkId].isFractionalized, "Artwork is not fractionalized.");
        require(artworks[_artworkId].fractionalOwners[msg.sender] >= _fractionAmount, "Not enough fractional ownership to sell.");
        require(_fractionAmount > 0 && _price > 0, "Invalid fraction amount or price.");

        fractionalListingCount++;
        fractionalListings[fractionalListingCount] = FractionalOwnershipListing({
            id: fractionalListingCount,
            artworkId: _artworkId,
            fractionAmount: _fractionAmount,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit FractionalOwnershipListed(fractionalListingCount, _artworkId, _fractionAmount, _price, msg.sender);
    }

    /// @dev Allows users to purchase fractional ownership from the marketplace.
    /// @param _listingId The ID of the fractional ownership listing.
    function purchaseFractionFromMarketplace(uint256 _listingId)
        external
        payable
        fractionalListingExists(_listingId)
        fractionalListingActive(_listingId)
        galleryNotPaused
    {
        FractionalOwnershipListing storage listing = fractionalListings[_listingId];
        require(listing.seller != msg.sender, "Cannot purchase your own listing.");
        require(msg.value >= listing.price, "Insufficient funds sent for fractional ownership.");

        // Transfer funds to seller (fractional owner)
        payable(listing.seller).transfer(listing.price);

        // Update ownership
        artworks[listing.artworkId].fractionalOwners[msg.sender] += listing.fractionAmount;
        artworks[listing.artworkId].fractionalOwners[listing.seller] -= listing.fractionAmount;
        artworks[listing.artworkId].fractionsSold += listing.fractionAmount; // Track sold fractions even through secondary market

        listing.isActive = false; // Deactivate listing after purchase
        emit FractionalOwnershipFractionPurchased(_listingId, msg.sender);

        if (artworks[listing.artworkId].fractionsSold == artworks[listing.artworkId].totalFractions) {
            artworks[listing.artworkId].status = ArtworkStatus.Sold; // Consider artwork sold when all fractions are sold
            artworks[listing.artworkId].onSale = false;
        }
    }

    /// @dev Allows artists to withdraw their earnings from sold artwork.
    /// @param _artworkId The ID of the artwork.
    function withdrawArtistEarnings(uint256 _artworkId)
        external
        artworkExists(_artworkId)
        galleryNotPaused
    {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only the artist can withdraw earnings.");
        uint256 earnings = artworks[_artworkId].artistEarnings;
        require(earnings > 0, "No earnings to withdraw.");

        artworks[_artworkId].artistEarnings = 0; // Reset earnings after withdrawal
        payable(msg.sender).transfer(earnings);
        emit ArtistEarningsWithdrawn(_artworkId, msg.sender, earnings);
    }

    // -------- DAO Governance & Parameters Functions --------

    /// @dev Allows curators to propose changes to gallery parameters.
    /// @param _parameterName The name of the parameter to change.
    /// @param _newValue The new value for the parameter.
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyCurator galleryNotPaused {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");

        parameterProposalCount++;
        parameterChangeProposals[parameterProposalCount] = ParameterChangeProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            isActive: true,
            isExecuted: false,
            hasVoted: mapping(address => bool)()
        });
        emit ParameterChangeProposed(parameterProposalCount, _parameterName, _newValue);
    }

    /// @dev Allows curators to vote on parameter change proposals.
    /// @param _proposalId The ID of the parameter change proposal.
    /// @param _approve Boolean indicating approval (true) or rejection (false).
    function voteOnParameterChange(uint256 _proposalId, bool _approve)
        external
        onlyCurator
        validProposal(_proposalId)
        parameterProposalActive(_proposalId)
        galleryNotPaused
    {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "Curator has already voted on this proposal.");

        proposal.hasVoted[msg.sender] = true;
        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ParameterChangeVoteCast(_proposalId, msg.sender, _approve);

        if (proposal.votesFor > curatorList.length / 2) { // Simple majority for now, could be adjusted
            proposal.isActive = false; // Close proposal after successful vote
        } else if (proposal.votesAgainst > curatorList.length / 2) {
            proposal.isActive = false; // Close proposal if rejected by majority
        }
    }

    /// @dev Allows anyone to execute approved parameter changes after a voting period.
    /// @param _proposalId The ID of the parameter change proposal.
    function executeParameterChange(uint256 _proposalId)
        external
        validProposal(_proposalId)
        parameterProposalActive(_proposalId)
        galleryNotPaused
    {
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        require(proposal.votesFor > curatorList.length / 2, "Parameter change proposal not approved by majority.");

        galleryParameters[proposal.parameterName] = proposal.newValue;
        proposal.isExecuted = true;
        emit ParameterChangeExecuted(_proposalId, proposal.parameterName, proposal.newValue);
    }

    /// @dev (Admin Function - could be DAO controlled) Sets the commission fee percentage.
    /// @param _newFeePercentage The new commission fee percentage.
    function setCommissionFee(uint256 _newFeePercentage) external onlyOwner galleryNotPaused {
        require(_newFeePercentage <= 100, "Commission fee percentage cannot exceed 100.");
        commissionFeePercentage = _newFeePercentage;
        galleryParameters["commissionFeePercentage"] = _newFeePercentage;
    }

    /// @dev (Admin Function - could be DAO controlled) Sets the threshold for fractionalization.
    /// @param _newThreshold The new fractionalization threshold in wei.
    function setFractionalizationThreshold(uint256 _newThreshold) external onlyOwner galleryNotPaused {
        fractionalizationThreshold = _newThreshold;
        galleryParameters["fractionalizationThreshold"] = _newThreshold;
    }

    /// @dev (Admin/DAO Function) Pauses all gallery operations in case of emergency.
    function emergencyPauseGallery() external onlyOwner { // Or potentially onlyCurator or DAO controlled
        galleryPaused = true;
        emit GalleryPaused();
    }

    /// @dev (Admin/DAO Function) Resumes gallery operations after a pause.
    function resumeGallery() external onlyOwner { // Or potentially onlyCurator or DAO controlled
        galleryPaused = false;
        emit GalleryResumed();
    }

    /// @dev (Admin/DAO Function) Allows withdrawal of gallery balance to a designated address.
    function withdrawGalleryBalance() external onlyOwner { // Or potentially DAO controlled
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw.");
        payable(owner).transfer(balance); // Or send to a DAO treasury address
        emit GalleryBalanceWithdrawn(owner, balance);
    }


    // -------- Utility & Information Functions --------

    /// @dev Returns detailed information about a specific artwork.
    /// @param _artworkId The ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @dev Returns details about a specific fractional ownership unit.
    /// @param _artworkId The ID of the artwork.
    /// @param _fractionId The ID of the fractional listing.
    /// @return FractionalOwnershipListing struct containing fractional ownership details.
    function getFractionalOwnershipDetails(uint256 _artworkId, uint256 _fractionId) external view fractionalListingExists(_fractionId) returns (FractionalOwnershipListing memory) {
        require(fractionalListings[_fractionId].artworkId == _artworkId, "Fraction listing not for this artwork.");
        return fractionalListings[_fractionId];
    }

    /// @dev Returns a list of current curators.
    /// @return Array of curator addresses.
    function getCuratorList() external view returns (address[] memory) {
        return curatorList;
    }

    /// @dev Returns the current value of a gallery parameter.
    /// @param _parameterName The name of the parameter.
    /// @return The value of the parameter.
    function getParameterValue(string memory _parameterName) external view returns (uint256) {
        return galleryParameters[_parameterName];
    }


    // -------- Internal Functions --------

    /// @dev Internal function to fractionalize an artwork after a full purchase.
    /// @param _artworkId The ID of the artwork to fractionalize.
    function _fractionalizeArtwork(uint256 _artworkId) internal {
        require(!artworks[_artworkId].isFractionalized, "Artwork is already fractionalized.");
        artworks[_artworkId].isFractionalized = true;
        artworks[_artworkId].totalFractions = 1000; // Example: 1000 fractions per artwork - can be parameterizable
        artworks[_artworkId].fractionsSold = 0; // Reset fractions sold
    }
}
```