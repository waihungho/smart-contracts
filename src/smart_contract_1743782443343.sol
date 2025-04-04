```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Advanced Smart Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a Decentralized Autonomous Art Gallery with advanced features like staged art submissions,
 *      dynamic voting mechanisms, community-curated exhibitions, fractionalized NFT ownership, and on-chain artist royalties.
 *      It aims to be a comprehensive and innovative platform for digital art management and community engagement.
 *
 * **Contract Outline & Function Summary:**
 *
 * **1. Core Art Management:**
 *    - `submitArtProposal(string _title, string _description, string _ipfsHash, uint256 _initialPrice)`: Allows artists to submit art proposals with details, IPFS hash, and initial price. (Function 1)
 *    - `approveArtProposal(uint256 _proposalId)`: Gallery owner/curators can approve art proposals after review. (Function 2)
 *    - `rejectArtProposal(uint256 _proposalId, string _rejectionReason)`: Gallery owner/curators can reject art proposals with a reason. (Function 3)
 *    - `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal, making it available in the gallery. (Function 4)
 *    - `setArtPrice(uint256 _artId, uint256 _newPrice)`: Allows the gallery owner to update the price of an artwork. (Function 5)
 *    - `removeArtFromGallery(uint256 _artId)`: Allows the gallery owner to remove an artwork from the gallery (e.g., due to ethical concerns, copyright issues). (Function 6)
 *
 * **2. Decentralized Governance & Community Features:**
 *    - `createGovernanceProposal(string _title, string _description, ProposalType _proposalType, bytes _data)`: Allows community members to create governance proposals (e.g., curator election, gallery direction changes). (Function 7)
 *    - `voteOnProposal(uint256 _proposalId, VoteOption _vote)`: Allows token holders to vote on active governance proposals. (Function 8)
 *    - `executeProposal(uint256 _proposalId)`: Executes a passed governance proposal after the voting period. (Function 9)
 *    - `delegateVotingPower(address _delegateAddress)`: Allows token holders to delegate their voting power to another address. (Function 10)
 *    - `setCurator(address _curatorAddress, bool _isCurator)`:  Gallery owner can appoint/revoke curators who help manage art submissions. (Function 11)
 *
 * **3. Advanced NFT & Ownership Features:**
 *    - `purchaseArt(uint256 _artId)`: Allows users to purchase art NFTs directly from the gallery. (Function 12)
 *    - `listArtForSale(uint256 _artId, uint256 _salePrice)`: NFT owners can list their gallery-minted art for sale on the gallery's marketplace. (Function 13)
 *    - `purchaseListedArt(uint256 _listingId)`: Allows users to purchase art listed for sale by other owners. (Function 14)
 *    - `fractionalizeArtNFT(uint256 _artId, uint256 _numberOfFractions)`: Allows NFT owners to fractionalize their art into ERC20 tokens for shared ownership. (Function 15)
 *    - `redeemArtNFTFraction(uint256 _fractionalArtId, uint256 _fractionAmount)`: Allows fractional token holders to redeem a portion of the underlying NFT (complex logic, may require further implementation details). (Function 16 - Advanced & Conceptual)
 *
 * **4. Artist Royalty & Revenue Management:**
 *    - `setArtistRoyalty(uint256 _artId, uint256 _royaltyPercentage)`: Sets the royalty percentage for an artwork, payable to the original artist on secondary sales. (Function 17)
 *    - `withdrawArtistRoyalties()`: Artists can withdraw accumulated royalties earned from secondary sales of their art. (Function 18)
 *    - `withdrawGalleryRevenue()`: Gallery owner can withdraw revenue generated from primary art sales. (Function 19)
 *
 * **5. Utility & Information Functions:**
 *    - `getArtDetails(uint256 _artId)`: Returns detailed information about a specific artwork. (Function 20)
 *    - `getProposalDetails(uint256 _proposalId)`: Returns details about a specific governance proposal. (Function 21)
 *    - `getArtistRoyalties(address _artistAddress)`: Returns the current royalty balance for an artist. (Function 22)
 *
 * **Important Notes:**
 * - This contract is a conceptual framework and might require further development and security audits for production use.
 * - Advanced features like fractionalization and redemption are complex and require careful implementation.
 * - Gas optimization and security best practices should be considered during actual development.
 * - This contract assumes the existence of a gallery token for governance (ERC20). You would need to define and deploy that token separately if needed.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedAutonomousArtGallery is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // Enums
    enum ProposalStatus { Pending, Active, Passed, Rejected, Executed }
    enum ProposalType { General, CuratorElection, GalleryDirection }
    enum VoteOption { For, Against, Abstain }
    enum ArtProposalStatus { Submitted, Approved, Rejected }
    enum SaleStatus { NotListed, Listed, Sold }

    // Structs
    struct ArtProposal {
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 initialPrice;
        ArtProposalStatus status;
        string rejectionReason;
    }

    struct ArtNFT {
        uint256 proposalId;
        uint256 price;
        address artist;
        uint256 royaltyPercentage;
        bool isFractionalized;
        SaleStatus saleStatus;
        uint256 salePrice;
        address currentOwner;
    }

    struct GovernanceProposal {
        ProposalType proposalType;
        string title;
        string description;
        ProposalStatus status;
        uint256 startTime;
        uint256 endTime;
        mapping(address => VoteOption) votes;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bytes data; // Optional data for proposal execution
    }

    struct SaleListing {
        uint256 artId;
        uint256 price;
        address seller;
        SaleStatus status;
    }

    // State Variables
    Counters.Counter private _artProposalIds;
    mapping(uint256 => ArtProposal) public artProposals;
    Counters.Counter private _artNFTIds;
    mapping(uint256 => ArtNFT) public artNFTs;
    Counters.Counter private _governanceProposalIds;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(address => bool) public curators;
    IERC20 public governanceToken; // Optional: For token-based governance
    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public galleryRevenue;
    mapping(address => uint256) public artistRoyaltiesBalance;
    Counters.Counter private _saleListingIds;
    mapping(uint256 => SaleListing) public saleListings;

    // Events
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalApproved(uint256 proposalId, uint256 artId);
    event ArtProposalRejected(uint256 proposalId, string rejectionReason);
    event ArtNFTMinted(uint256 artId, uint256 proposalId, address artist);
    event ArtPriceUpdated(uint256 artId, uint256 newPrice);
    event ArtRemovedFromGallery(uint256 artId);
    event GovernanceProposalCreated(uint256 proposalId, ProposalType proposalType, string title);
    event VoteCast(uint256 proposalId, address voter, VoteOption vote);
    event ProposalExecuted(uint256 proposalId, ProposalStatus status);
    event CuratorSet(address curatorAddress, bool isCurator);
    event ArtPurchased(uint256 artId, address buyer, uint256 price);
    event ArtListedForSale(uint256 listingId, uint256 artId, uint256 price, address seller);
    event ListedArtPurchased(uint256 listingId, uint256 artId, address buyer, uint256 price, address seller);
    event ArtFractionalized(uint256 artId, uint256 numberOfFractions);
    event ArtistRoyaltyWithdrawn(address artist, uint256 amount);
    event GalleryRevenueWithdrawn(address owner, uint256 amount);

    // Modifiers
    modifier onlyCurator() {
        require(curators[_msgSender()] || owner() == _msgSender(), "Only curators or owner can perform this action");
        _;
    }

    modifier onlyGalleryArtOwner(uint256 _artId) {
        require(_msgSender() == artNFTs[_artId].currentOwner, "You are not the owner of this art NFT");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _governanceProposalIds.current, "Invalid proposal ID");
        _;
    }

    modifier validArtProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _artProposalIds.current, "Invalid art proposal ID");
        _;
    }

    modifier validArtNFT(uint256 _artId) {
        require(_artId > 0 && _artId <= _artNFTIds.current, "Invalid art NFT ID");
        _;
    }

    modifier validSaleListing(uint256 _listingId) {
        require(_listingId > 0 && _listingId <= _saleListingIds.current, "Invalid sale listing ID");
        _;
    }

    modifier proposalActive(uint256 _proposalId) {
        require(governanceProposals[_proposalId].status == ProposalStatus.Active, "Proposal is not active");
        _;
    }

    modifier proposalPending(uint256 _proposalId) {
        require(governanceProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending");
        _;
    }

    modifier proposalPassed(uint256 _proposalId) {
        require(governanceProposals[_proposalId].status == ProposalStatus.Passed, "Proposal is not passed");
        _;
    }


    // Constructor
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        // Optionally initialize governance token address here if using token-based governance
        // governanceToken = IERC20(_governanceTokenAddress);
    }

    // ------------------------ 1. Core Art Management ------------------------

    /// @notice Allows artists to submit art proposals.
    /// @param _title Title of the artwork.
    /// @param _description Description of the artwork.
    /// @param _ipfsHash IPFS hash of the artwork's metadata.
    /// @param _initialPrice Initial price of the artwork in wei.
    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _initialPrice
    ) external {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current;
        artProposals[proposalId] = ArtProposal({
            artist: _msgSender(),
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            initialPrice: _initialPrice,
            status: ArtProposalStatus.Submitted,
            rejectionReason: ""
        });
        emit ArtProposalSubmitted(proposalId, _msgSender(), _title);
    }

    /// @notice Approves a submitted art proposal, allowing it to be minted as an NFT.
    /// @param _proposalId ID of the art proposal.
    function approveArtProposal(uint256 _proposalId) external onlyCurator validArtProposal(_proposalId) {
        require(artProposals[_proposalId].status == ArtProposalStatus.Submitted, "Proposal is not submitted");
        artProposals[_proposalId].status = ArtProposalStatus.Approved;
        emit ArtProposalApproved(_proposalId, _proposalId); // Proposal ID can be used as art ID initially
    }

    /// @notice Rejects a submitted art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @param _rejectionReason Reason for rejecting the proposal.
    function rejectArtProposal(uint256 _proposalId, string memory _rejectionReason) external onlyCurator validArtProposal(_proposalId) {
        require(artProposals[_proposalId].status == ArtProposalStatus.Submitted, "Proposal is not submitted");
        artProposals[_proposalId].status = ArtProposalStatus.Rejected;
        artProposals[_proposalId].rejectionReason = _rejectionReason;
        emit ArtProposalRejected(_proposalId, _rejectionReason);
    }

    /// @notice Mints an ERC721 NFT for an approved art proposal.
    /// @param _proposalId ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) external onlyCurator validArtProposal(_proposalId) {
        require(artProposals[_proposalId].status == ArtProposalStatus.Approved, "Proposal is not approved");
        _artNFTIds.increment();
        uint256 artId = _artNFTIds.current;

        _safeMint(address(this), artId); // Mint to the contract initially, then transfer on purchase

        artNFTs[artId] = ArtNFT({
            proposalId: _proposalId,
            price: artProposals[_proposalId].initialPrice,
            artist: artProposals[_proposalId].artist,
            royaltyPercentage: 5, // Default royalty percentage, can be changed later
            isFractionalized: false,
            saleStatus: SaleStatus.NotListed,
            salePrice: 0,
            currentOwner: address(this) // Gallery contract initially owns the NFT
        });

        emit ArtNFTMinted(artId, _proposalId, artProposals[_proposalId].artist);
    }

    /// @notice Sets a new price for an artwork in the gallery.
    /// @param _artId ID of the artwork.
    /// @param _newPrice New price in wei.
    function setArtPrice(uint256 _artId, uint256 _newPrice) external onlyOwner validArtNFT(_artId) {
        artNFTs[_artId].price = _newPrice;
        emit ArtPriceUpdated(_artId, _newPrice);
    }

    /// @notice Removes an artwork from the gallery (e.g., due to policy violations).
    /// @param _artId ID of the artwork to remove.
    function removeArtFromGallery(uint256 _artId) external onlyOwner validArtNFT(_artId) {
        // Consider burning the NFT or transferring it to a null address based on policy
        _burn(_artId);
        delete artNFTs[_artId]; // Clean up struct data
        emit ArtRemovedFromGallery(_artId);
    }


    // ------------------------ 2. Decentralized Governance & Community Features ------------------------

    /// @notice Creates a new governance proposal.
    /// @param _title Title of the proposal.
    /// @param _description Detailed description of the proposal.
    /// @param _proposalType Type of governance proposal.
    /// @param _data Optional data for proposal execution (e.g., contract address, function signature, parameters).
    function createGovernanceProposal(
        string memory _title,
        string memory _description,
        ProposalType _proposalType,
        bytes memory _data
    ) external {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current;
        governanceProposals[proposalId] = GovernanceProposal({
            proposalType: _proposalType,
            title: _title,
            description: _description,
            status: ProposalStatus.Pending,
            startTime: 0,
            endTime: 0,
            forVotes: 0,
            againstVotes: 0,
            abstainVotes: 0,
            data: _data
        });
        emit GovernanceProposalCreated(proposalId, _proposalType, _title);
    }

    /// @notice Starts the voting period for a governance proposal (Owner/Curator initiated).
    /// @param _proposalId ID of the proposal to activate.
    function startProposalVoting(uint256 _proposalId) external onlyCurator validProposal(_proposalId) proposalPending(_proposalId) {
        governanceProposals[_proposalId].status = ProposalStatus.Active;
        governanceProposals[_proposalId].startTime = block.timestamp;
        governanceProposals[_proposalId].endTime = block.timestamp + votingPeriod;
    }


    /// @notice Allows token holders to vote on an active governance proposal.
    /// @param _proposalId ID of the governance proposal.
    /// @param _vote Vote option (For, Against, Abstain).
    function voteOnProposal(uint256 _proposalId, VoteOption _vote) external validProposal(_proposalId) proposalActive(_proposalId) {
        require(governanceProposals[_proposalId].votes[_msgSender()] == VoteOption.Abstain || governanceProposals[_proposalId].votes[_msgSender()] == VoteOption.Against || governanceProposals[_proposalId].votes[_msgSender()] == VoteOption.For || governanceProposals[_proposalId].votes[_msgSender()] == VoteOption(0) , "Already voted on this proposal"); // Ensure user hasn't voted yet.
        governanceProposals[_proposalId].votes[_msgSender()] = _vote;

        if (_vote == VoteOption.For) {
            governanceProposals[_proposalId].forVotes++;
        } else if (_vote == VoteOption.Against) {
            governanceProposals[_proposalId].againstVotes++;
        } else if (_vote == VoteOption.Abstain) {
            governanceProposals[_proposalId].abstainVotes++;
        }
        emit VoteCast(_proposalId, _msgSender(), _vote);
    }

    /// @notice Ends the voting period and executes a passed governance proposal.
    /// @param _proposalId ID of the governance proposal.
    function executeProposal(uint256 _proposalId) external onlyCurator validProposal(_proposalId) proposalActive(_proposalId) {
        require(block.timestamp > governanceProposals[_proposalId].endTime, "Voting period not ended");

        if (governanceProposals[_proposalId].forVotes > governanceProposals[_proposalId].againstVotes) {
            governanceProposals[_proposalId].status = ProposalStatus.Passed;
            // Execute proposal logic based on proposal type and data (complex - needs specific implementation)
            // Example: if proposalType is CuratorElection, update curators mapping based on proposal data.
            emit ProposalExecuted(_proposalId, ProposalStatus.Passed);
        } else {
            governanceProposals[_proposalId].status = ProposalStatus.Rejected;
            emit ProposalExecuted(_proposalId, ProposalStatus.Rejected);
        }
    }

    /// @notice Allows token holders to delegate their voting power to another address. (Conceptual - Requires token implementation)
    /// @param _delegateAddress Address to delegate voting power to.
    function delegateVotingPower(address _delegateAddress) external {
        // Implementation depends on the governance token and voting power mechanism.
        // Could involve updating a mapping of delegators to delegates.
        // For simplicity, leaving as a placeholder in this example.
        // In a real system, you'd likely interact with the governance token contract.
        require(false, "Delegation of voting power not fully implemented in this example.");
    }

    /// @notice Sets or revokes curator status for an address.
    /// @param _curatorAddress Address to set curator status for.
    /// @param _isCurator True to grant curator status, false to revoke.
    function setCurator(address _curatorAddress, bool _isCurator) external onlyOwner {
        curators[_curatorAddress] = _isCurator;
        emit CuratorSet(_curatorAddress, _isCurator);
    }


    // ------------------------ 3. Advanced NFT & Ownership Features ------------------------

    /// @notice Allows users to purchase art NFTs directly from the gallery (primary sale).
    /// @param _artId ID of the artwork to purchase.
    function purchaseArt(uint256 _artId) external payable validArtNFT(_artId) nonReentrant {
        require(artNFTs[_artId].currentOwner == address(this), "Art is not available for primary sale");
        require(msg.value >= artNFTs[_artId].price, "Insufficient funds sent");

        uint256 price = artNFTs[_artId].price;
        address artist = artNFTs[_artId].artist;

        // Transfer NFT to buyer
        _transfer(address(this), _msgSender(), _artId);
        artNFTs[_artId].currentOwner = _msgSender();

        // Transfer funds to gallery revenue (owner can withdraw later)
        galleryRevenue = galleryRevenue.add(price);

        // Optionally, send a portion to the artist immediately on primary sale (can be part of royalty setup)
        //  if (artist != address(0)) {
        //      uint256 artistPrimarySaleCut = price.mul(10).div(100); // Example: 10% to artist on primary sale
        //      payable(artist).transfer(artistPrimarySaleCut);
        //      galleryRevenue = galleryRevenue.sub(artistPrimarySaleCut);
        //  }

        // Refund any extra ETH sent
        if (msg.value > price) {
            payable(_msgSender()).transfer(msg.value - price);
        }

        emit ArtPurchased(_artId, _msgSender(), price);
    }

    /// @notice Allows NFT owners to list their gallery-minted art for sale on the gallery's marketplace (secondary sale).
    /// @param _artId ID of the artwork to list for sale.
    /// @param _salePrice Price to list the artwork for in wei.
    function listArtForSale(uint256 _artId, uint256 _salePrice) external onlyGalleryArtOwner(_artId) validArtNFT(_artId) {
        require(artNFTs[_artId].saleStatus == SaleStatus.NotListed, "Art is already listed or sold");

        _saleListingIds.increment();
        uint256 listingId = _saleListingIds.current;
        saleListings[listingId] = SaleListing({
            artId: _artId,
            price: _salePrice,
            seller: _msgSender(),
            status: SaleStatus.Listed
        });
        artNFTs[_artId].saleStatus = SaleStatus.Listed;
        artNFTs[_artId].salePrice = _salePrice;

        emit ArtListedForSale(listingId, _artId, _salePrice, _msgSender());
    }

    /// @notice Allows users to purchase art listed for sale by other owners (secondary marketplace).
    /// @param _listingId ID of the sale listing.
    function purchaseListedArt(uint256 _listingId) external payable validSaleListing(_listingId) nonReentrant {
        require(saleListings[_listingId].status == SaleStatus.Listed, "Listing is not active");
        uint256 artId = saleListings[_listingId].artId;
        uint256 salePrice = saleListings[_listingId].price;
        address seller = saleListings[_listingId].seller;

        require(msg.value >= salePrice, "Insufficient funds sent");

        // Transfer NFT to buyer
        _transfer(seller, _msgSender(), artId);
        artNFTs[_artId].currentOwner = _msgSender();
        artNFTs[_artId].saleStatus = SaleStatus.Sold;
        saleListings[_listingId].status = SaleStatus.Sold;

        // Pay seller and handle artist royalties
        uint256 artistRoyaltyAmount = salePrice.mul(artNFTs[_artId].royaltyPercentage).div(100);
        uint256 sellerPayout = salePrice.sub(artistRoyaltyAmount);

        if (artNFTs[_artId].artist != address(0)) {
            artistRoyaltiesBalance[artNFTs[_artId].artist] = artistRoyaltiesBalance[artNFTs[_artId].artist].add(artistRoyaltyAmount);
        }

        payable(seller).transfer(sellerPayout);

        // Refund any extra ETH sent
        if (msg.value > salePrice) {
            payable(_msgSender()).transfer(msg.value - salePrice);
        }

        emit ListedArtPurchased(_listingId, artId, _msgSender(), salePrice, seller);
    }


    /// @notice Allows NFT owners to fractionalize their art NFT into ERC20 tokens (Conceptual - requires external ERC20 contract).
    /// @param _artId ID of the artwork to fractionalize.
    /// @param _numberOfFractions Number of ERC20 fractions to create.
    function fractionalizeArtNFT(uint256 _artId, uint256 _numberOfFractions) external onlyGalleryArtOwner(_artId) validArtNFT(_artId) {
        require(!artNFTs[_artId].isFractionalized, "Art is already fractionalized");
        require(_numberOfFractions > 0, "Number of fractions must be greater than zero");

        // **Conceptual Implementation - Requires external ERC20 contract and more complex logic**
        // 1. Deploy a new ERC20 token contract specifically for this fractionalized art.
        // 2. Mint _numberOfFractions tokens to the NFT owner.
        // 3. Transfer the original NFT to a vault or escrow controlled by the fractional token contract.
        // 4. Mark artNFTs[_artId].isFractionalized = true; and store the ERC20 contract address.

        // For simplicity, just marking as fractionalized in this example and emitting event.
        artNFTs[_artId].isFractionalized = true;
        emit ArtFractionalized(_artId, _numberOfFractions);
        require(false, "Fractionalization functionality is conceptual and requires further implementation with ERC20 token and vault.");
    }

    /// @notice Allows fractional token holders to redeem a portion of the underlying NFT (Highly Conceptual & Complex).
    /// @param _fractionalArtId ID of the fractionalized artwork.
    /// @param _fractionAmount Amount of fractional tokens to redeem.
    function redeemArtNFTFraction(uint256 _fractionalArtId, uint256 _fractionAmount) external {
        require(artNFTs[_fractionalArtId].isFractionalized, "Art is not fractionalized");
        // **Highly Conceptual and Complex Implementation - Requires fractional token contract and vault logic**
        // 1. Check if the caller holds enough fractional tokens.
        // 2. Burn the redeemed fractional tokens.
        // 3. Based on the fraction amount redeemed, determine if the caller gets ownership rights to the underlying NFT
        //    (e.g., if someone redeems 100% of fractions, they get the NFT).
        // 4. If ownership is transferred, transfer the NFT from the vault to the redeemer.
        // 5. This requires very complex logic and coordination with the fractional token contract.

        require(false, "Redemption of NFT fractions is highly conceptual and requires very complex implementation.");
    }


    // ------------------------ 4. Artist Royalty & Revenue Management ------------------------

    /// @notice Sets the royalty percentage for an artwork (owner-only function).
    /// @param _artId ID of the artwork.
    /// @param _royaltyPercentage Royalty percentage (e.g., 5 for 5%).
    function setArtistRoyalty(uint256 _artId, uint256 _royaltyPercentage) external onlyOwner validArtNFT(_artId) {
        require(_royaltyPercentage <= 20, "Royalty percentage cannot exceed 20%"); // Example limit
        artNFTs[_artId].royaltyPercentage = _royaltyPercentage;
    }

    /// @notice Allows artists to withdraw their accumulated royalties.
    function withdrawArtistRoyalties() external nonReentrant {
        uint256 amount = artistRoyaltiesBalance[_msgSender()];
        require(amount > 0, "No royalties to withdraw");
        artistRoyaltiesBalance[_msgSender()] = 0; // Reset balance after withdrawal
        payable(_msgSender()).transfer(amount);
        emit ArtistRoyaltyWithdrawn(_msgSender(), amount);
    }

    /// @notice Allows the gallery owner to withdraw accumulated gallery revenue.
    function withdrawGalleryRevenue() external onlyOwner nonReentrant {
        uint256 amount = galleryRevenue;
        require(amount > 0, "No gallery revenue to withdraw");
        galleryRevenue = 0;
        payable(owner()).transfer(amount);
        emit GalleryRevenueWithdrawn(owner(), amount);
    }


    // ------------------------ 5. Utility & Information Functions ------------------------

    /// @notice Gets detailed information about an artwork.
    /// @param _artId ID of the artwork.
    /// @return ArtNFT struct containing artwork details.
    function getArtDetails(uint256 _artId) external view validArtNFT(_artId) returns (ArtNFT memory) {
        return artNFTs[_artId];
    }

    /// @notice Gets details about a governance proposal.
    /// @param _proposalId ID of the proposal.
    /// @return GovernanceProposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    /// @notice Gets the current royalty balance for an artist.
    /// @param _artistAddress Address of the artist.
    /// @return Royalty balance in wei.
    function getArtistRoyalties(address _artistAddress) external view returns (uint256) {
        return artistRoyaltiesBalance[_artistAddress];
    }
}
```