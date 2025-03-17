```solidity
/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, showcasing advanced concepts like DAO governance,
 *      dynamic NFT exhibitions, fractional ownership, curated collections, artist royalties, and community engagement.
 *
 * Function Summary:
 * 1. mintArtNFT: Mints a unique Art NFT with metadata URI, artist, and initial price.
 * 2. setNFTMetadataURI: Updates the metadata URI of an Art NFT (artist only).
 * 3. transferArtNFT: Transfers ownership of an Art NFT.
 * 4. listArtForSale: Lists an Art NFT for sale in the gallery at a specific price.
 * 5. unlistArtFromSale: Removes an Art NFT from sale in the gallery.
 * 6. purchaseArt: Allows anyone to purchase an Art NFT listed for sale.
 * 7. createExhibition: Creates a new art exhibition with a title, description, and curator.
 * 8. proposeArtForExhibition: Allows DAO members to propose Art NFTs for an exhibition.
 * 9. voteOnExhibitionProposal: DAO members vote on proposed Art NFTs for exhibitions.
 * 10. addArtToExhibition: Curator adds approved Art NFTs to an exhibition.
 * 11. removeArtFromExhibition: Curator removes Art NFTs from an exhibition.
 * 12. startExhibition: Starts an exhibition, making displayed NFTs publicly viewable within the gallery context.
 * 13. endExhibition: Ends an exhibition, potentially updating NFT metadata to reflect exhibition history.
 * 14. createFractionalNFT: Allows NFT owners to create fractional ownership tokens for their Art NFTs.
 * 15. purchaseFractionalNFT: Allows users to purchase fractional ownership tokens of an Art NFT.
 * 16. redeemFractionalNFT: Allows majority fractional owners to trigger a vote to redeem the original NFT and distribute proceeds.
 * 17. proposeGalleryFeeUpdate: DAO members propose changes to the gallery commission fee.
 * 18. voteOnGalleryFeeUpdate: DAO members vote on proposed gallery fee updates.
 * 19. setGalleryFee: Executes approved gallery fee updates.
 * 20. becomeDAOMember: Allows users to become DAO members (e.g., by holding a specific token or paying a fee).
 * 21. revokeDAOMembership: DAO can revoke membership (governance action).
 * 22. withdrawArtistEarnings: Allows artists to withdraw their earnings from NFT sales.
 * 23. getExhibitionDetails: Retrieves details of a specific exhibition.
 * 24. getArtDetails: Retrieves details of a specific Art NFT.
 * 25. getGalleryBalance: Returns the current balance of the gallery contract.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract DecentralizedAutonomousArtGallery is ERC721, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _nftCounter;
    Counters.Counter private _exhibitionCounter;

    // Art NFT struct
    struct ArtNFT {
        uint256 tokenId;
        address artist;
        string metadataURI;
        uint256 price; // Price when listed for sale, 0 if not listed
        bool forSale;
        uint256 exhibitionId; // 0 if not in an exhibition
        bool isFractionalized;
    }

    // Exhibition struct
    struct Exhibition {
        uint256 exhibitionId;
        string title;
        string description;
        address curator;
        uint256[] artNFTIds; // Array of Art NFT token IDs in the exhibition
        bool isActive;
    }

    // Fractional NFT struct (Simplified example, can be expanded)
    struct FractionalNFT {
        uint256 originalNFTId;
        address[] fractionalTokenHolders; // Addresses holding fractional tokens (simplified)
        uint256 fractionalTokenSupply; // Total supply of fractional tokens
        uint256 fractionalTokenPrice; // Price per fractional token
        bool redemptionVoteActive;
        uint256 redemptionVoteDeadline;
        uint256 redemptionTargetPrice;
    }

    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => FractionalNFT) public fractionalNFTs;
    mapping(uint256 => mapping(address => uint256)) public fractionalTokenBalances; // NFT ID => Holder => Balance
    mapping(uint256 => EnumerableSet.AddressSet) public exhibitionProposalVotes; // Exhibition ID => Proposal Votes

    EnumerableSet.AddressSet private daoMembers;
    EnumerableSet.AddressSet private curators;
    uint256 public galleryFeePercentage = 5; // Default gallery fee percentage (5%)
    address payable public galleryWallet; // Address to receive gallery fees

    event ArtNFTMinted(uint256 tokenId, address artist, string metadataURI);
    event ArtNFTMetadataUpdated(uint256 tokenId, string metadataURI);
    event ArtNFTListedForSale(uint256 tokenId, uint256 price);
    event ArtNFTUnlistedFromSale(uint256 tokenId);
    event ArtNFTPurchased(uint256 tokenId, address buyer, uint256 price);
    event ExhibitionCreated(uint256 exhibitionId, string title, address curator);
    event ArtProposedForExhibition(uint256 exhibitionId, uint256 artNFTId, address proposer);
    event ExhibitionProposalVoteCast(uint256 exhibitionId, uint256 artNFTId, address voter, bool vote);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artNFTId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artNFTId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event FractionalNFTCreated(uint256 fractionalNFTId, uint256 originalNFTId, uint256 totalSupply);
    event FractionalNFTPurchased(uint256 fractionalNFTId, address buyer, uint256 amount);
    event GalleryFeeUpdated(uint256 newFeePercentage);
    event DAOMemberJoined(address member);
    event DAOMemberRevoked(address member);
    event ArtistEarningsWithdrawn(address artist, uint256 amount);

    modifier onlyArtist(uint256 _tokenId) {
        require(artNFTs[_tokenId].artist == _msgSender(), "Only artist can perform this action.");
        _;
    }

    modifier onlyDAOMembers() {
        require(isDAOMember(_msgSender()), "Only DAO members allowed.");
        _;
    }

    modifier onlyCurators() {
        require(isCurator(_msgSender()), "Only curators allowed.");
        _;
    }

    constructor(string memory _name, string memory _symbol, address payable _galleryWallet) ERC721(_name, _symbol) {
        galleryWallet = _galleryWallet;
    }

    // 1. mintArtNFT: Mints a unique Art NFT
    function mintArtNFT(address _artist, string memory _metadataURI, uint256 _initialPrice) public onlyDAOMembers returns (uint256) {
        _nftCounter.increment();
        uint256 tokenId = _nftCounter.current();
        _safeMint(_artist, tokenId);

        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            artist: _artist,
            metadataURI: _metadataURI,
            price: 0, // Initially not for sale
            forSale: false,
            exhibitionId: 0,
            isFractionalized: false
        });

        emit ArtNFTMinted(tokenId, _artist, _metadataURI);
        return tokenId;
    }

    // 2. setNFTMetadataURI: Updates the metadata URI of an Art NFT (artist only)
    function setNFTMetadataURI(uint256 _tokenId, string memory _metadataURI) public onlyArtist(_tokenId) {
        artNFTs[_tokenId].metadataURI = _metadataURI;
        emit ArtNFTMetadataUpdated(_tokenId, _metadataURI);
    }

    // 3. transferArtNFT: Transfers ownership of an Art NFT
    function transferArtNFT(address _to, uint256 _tokenId) public payable {
        transferFrom(_msgSender(), _to, _tokenId);
    }

    // 4. listArtForSale: Lists an Art NFT for sale in the gallery
    function listArtForSale(uint256 _tokenId, uint256 _price) public onlyArtist(_tokenId) {
        require(!artNFTs[_tokenId].forSale, "Art NFT is already for sale.");
        artNFTs[_tokenId].price = _price;
        artNFTs[_tokenId].forSale = true;
        emit ArtNFTListedForSale(_tokenId, _price);
    }

    // 5. unlistArtFromSale: Removes an Art NFT from sale
    function unlistArtFromSale(uint256 _tokenId) public onlyArtist(_tokenId) {
        require(artNFTs[_tokenId].forSale, "Art NFT is not for sale.");
        artNFTs[_tokenId].price = 0;
        artNFTs[_tokenId].forSale = false;
        emit ArtNFTUnlistedFromSale(_tokenId);
    }

    // 6. purchaseArt: Allows anyone to purchase an Art NFT listed for sale
    function purchaseArt(uint256 _tokenId) public payable {
        require(artNFTs[_tokenId].forSale, "Art NFT is not for sale.");
        require(msg.value >= artNFTs[_tokenId].price, "Insufficient funds to purchase.");

        uint256 artistShare = (artNFTs[_tokenId].price * (100 - galleryFeePercentage)) / 100;
        uint256 galleryFee = artNFTs[_tokenId].price - artistShare;

        // Transfer funds
        payable(artNFTs[_tokenId].artist).transfer(artistShare);
        galleryWallet.transfer(galleryFee);

        // Transfer NFT ownership
        transferArtNFT(_msgSender(), _tokenId);

        // Update NFT sale status
        artNFTs[_tokenId].forSale = false;
        artNFTs[_tokenId].price = 0;

        emit ArtNFTPurchased(_tokenId, _msgSender(), artNFTs[_tokenId].price);
    }

    // 7. createExhibition: Creates a new art exhibition
    function createExhibition(string memory _title, string memory _description) public onlyCurators returns (uint256) {
        _exhibitionCounter.increment();
        uint256 exhibitionId = _exhibitionCounter.current();

        exhibitions[exhibitionId] = Exhibition({
            exhibitionId: exhibitionId,
            title: _title,
            description: _description,
            curator: _msgSender(),
            artNFTIds: new uint256[](0),
            isActive: false
        });

        emit ExhibitionCreated(exhibitionId, _title, _msgSender());
        return exhibitionId;
    }

    // 8. proposeArtForExhibition: DAO members propose Art NFTs for an exhibition
    function proposeArtForExhibition(uint256 _exhibitionId, uint256 _artNFTId) public onlyDAOMembers {
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        require(artNFTs[_artNFTId].tokenId == _artNFTId, "Art NFT does not exist.");
        require(artNFTs[_artNFTId].exhibitionId == 0, "Art NFT is already in an exhibition.");

        // In a real DAO, you'd use a more robust voting mechanism.
        // Here, we're using a simple voting system for demonstration.
        exhibitionProposalVotes[_exhibitionId][_msgSender()] = true; // DAO member votes "yes"
        emit ArtProposedForExhibition(_exhibitionId, _artNFTId, _msgSender());
    }

    // 9. voteOnExhibitionProposal: DAO members vote on proposed Art NFTs for exhibitions (Simplified voting)
    function voteOnExhibitionProposal(uint256 _exhibitionId, uint256 _artNFTId, bool _vote) public onlyDAOMembers {
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        require(artNFTs[_artNFTId].tokenId == _artNFTId, "Art NFT does not exist.");
        require(artNFTs[_artNFTId].exhibitionId == 0, "Art NFT is already in an exhibition.");

        exhibitionProposalVotes[_exhibitionId][_msgSender()] = _vote; // Record vote
        emit ExhibitionProposalVoteCast(_exhibitionId, _artNFTId, _msgSender(), _vote);
    }

    // 10. addArtToExhibition: Curator adds approved Art NFTs to an exhibition
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artNFTId) public onlyCurators {
        require(exhibitions[_exhibitionId].curator == _msgSender(), "Only curator of this exhibition can add art.");
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        require(artNFTs[_artNFTId].tokenId == _artNFTId, "Art NFT does not exist.");
        require(artNFTs[_artNFTId].exhibitionId == 0, "Art NFT is already in an exhibition.");

        // Simple approval logic (in a real DAO, use more sophisticated voting/approval)
        uint256 yesVotes = 0;
        uint256 daoMemberCount = daoMembers.length();
        for(uint256 i = 0; i < daoMemberCount; i++){
            if(exhibitionProposalVotes[_exhibitionId][daoMembers.at(i)]){
                yesVotes++;
            }
        }

        require(yesVotes > (daoMemberCount / 2), "Proposal not approved by DAO."); // Simple majority approval

        exhibitions[_exhibitionId].artNFTIds.push(_artNFTId);
        artNFTs[_artNFTId].exhibitionId = _exhibitionId;
        emit ArtAddedToExhibition(_exhibitionId, _artNFTId);
    }

    // 11. removeArtFromExhibition: Curator removes Art NFTs from an exhibition
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artNFTId) public onlyCurators {
        require(exhibitions[_exhibitionId].curator == _msgSender(), "Only curator of this exhibition can remove art.");
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        require(artNFTs[_artNFTId].tokenId == _artNFTId, "Art NFT does not exist.");
        require(artNFTs[_artNFTId].exhibitionId == _exhibitionId, "Art NFT is not in this exhibition.");

        uint256[] storage artInExhibition = exhibitions[_exhibitionId].artNFTIds;
        for (uint256 i = 0; i < artInExhibition.length; i++) {
            if (artInExhibition[i] == _artNFTId) {
                artInExhibition[i] = artInExhibition[artInExhibition.length - 1];
                artInExhibition.pop();
                break;
            }
        }
        artNFTs[_artNFTId].exhibitionId = 0;
        emit ArtRemovedFromExhibition(_exhibitionId, _artNFTId);
    }

    // 12. startExhibition: Starts an exhibition
    function startExhibition(uint256 _exhibitionId) public onlyCurators {
        require(exhibitions[_exhibitionId].curator == _msgSender(), "Only curator of this exhibition can start it.");
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        require(!exhibitions[_exhibitionId].isActive, "Exhibition is already active.");

        exhibitions[_exhibitionId].isActive = true;
        emit ExhibitionStarted(_exhibitionId);
    }

    // 13. endExhibition: Ends an exhibition
    function endExhibition(uint256 _exhibitionId) public onlyCurators {
        require(exhibitions[_exhibitionId].curator == _msgSender(), "Only curator of this exhibition can end it.");
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");

        exhibitions[_exhibitionId].isActive = false;
        emit ExhibitionEnded(_exhibitionId);
    }

    // 14. createFractionalNFT: Allows NFT owners to create fractional ownership tokens
    function createFractionalNFT(uint256 _originalNFTId, uint256 _fractionalTokenSupply, uint256 _fractionalTokenPrice) public onlyArtist(_originalNFTId) {
        require(!artNFTs[_originalNFTId].isFractionalized, "Art NFT is already fractionalized.");
        require(_fractionalTokenSupply > 0 && _fractionalTokenPrice > 0, "Supply and price must be positive.");

        fractionalNFTs[_originalNFTId] = FractionalNFT({
            originalNFTId: _originalNFTId,
            fractionalTokenHolders: new address[](0), // In a real implementation, track holders more efficiently
            fractionalTokenSupply: _fractionalTokenSupply,
            fractionalTokenPrice: _fractionalTokenPrice,
            redemptionVoteActive: false,
            redemptionVoteDeadline: 0,
            redemptionTargetPrice: 0
        });
        artNFTs[_originalNFTId].isFractionalized = true;

        emit FractionalNFTCreated(_originalNFTId, _originalNFTId, _fractionalTokenSupply);
    }

    // 15. purchaseFractionalNFT: Allows users to purchase fractional ownership tokens
    function purchaseFractionalNFT(uint256 _originalNFTId, uint256 _amount) public payable {
        require(artNFTs[_originalNFTId].isFractionalized, "Art NFT is not fractionalized.");
        require(fractionalNFTs[_originalNFTId].fractionalTokenPrice > 0, "Fractional tokens are not for sale.");
        require(_amount > 0, "Amount must be positive.");
        require(msg.value >= (fractionalNFTs[_originalNFTId].fractionalTokenPrice * _amount), "Insufficient funds.");
        require(fractionalTokenBalances[_originalNFTId][_msgSender()] + _amount <= fractionalNFTs[_originalNFTId].fractionalTokenSupply, "Not enough fractional tokens available."); // Simplified supply check

        fractionalTokenBalances[_originalNFTId][_msgSender()] += _amount;
        payable(artNFTs[_originalNFTId].artist).transfer(msg.value); // Artist receives funds for fractional tokens (can be DAO governed in future)

        emit FractionalNFTPurchased(_originalNFTId, _msgSender(), _amount);
    }

    // 16. redeemFractionalNFT: Allows majority fractional owners to trigger a vote to redeem the original NFT
    function redeemFractionalNFT(uint256 _originalNFTId, uint256 _targetRedemptionPrice, uint256 _voteDurationInSeconds) public onlyDAOMembers {
        require(artNFTs[_originalNFTId].isFractionalized, "Art NFT is not fractionalized.");
        require(!fractionalNFTs[_originalNFTId].redemptionVoteActive, "Redemption vote already active.");
        require(_targetRedemptionPrice > 0 && _voteDurationInSeconds > 0, "Invalid redemption price or vote duration.");

        fractionalNFTs[_originalNFTId].redemptionVoteActive = true;
        fractionalNFTs[_originalNFTId].redemptionVoteDeadline = block.timestamp + _voteDurationInSeconds;
        fractionalNFTs[_originalNFTId].redemptionTargetPrice = _targetRedemptionPrice;

        // In a real DAO, implement a voting mechanism for fractional token holders
        // For simplicity, this example omits the detailed fractional token holder voting.
        // A more advanced implementation would involve a separate voting contract or system.

        // Placeholder: Assume vote passes if DAO member initiates (for simplicity in this example)
        _executeFractionalNFTRedemption(_originalNFTId, _targetRedemptionPrice);
    }

    function _executeFractionalNFTRedemption(uint256 _originalNFTId, uint256 _redemptionPrice) internal {
        require(fractionalNFTs[_originalNFTId].redemptionVoteActive, "Redemption vote is not active.");
        require(block.timestamp > fractionalNFTs[_originalNFTId].redemptionVoteDeadline, "Redemption vote is still active.");

        // In a real implementation, check if a majority of fractional token holders voted YES
        // For simplicity, we assume vote passes (as triggered by DAO member in this example)

        // Distribute redemption proceeds to fractional token holders proportionally
        uint256 totalFractionalTokens = fractionalNFTs[_originalNFTId].fractionalTokenSupply;
        uint256 galleryBalance = address(this).balance; // Get current contract balance for redistribution
        uint256 availableRedemptionAmount = _redemptionPrice <= galleryBalance ? _redemptionPrice : galleryBalance; // Limit to available balance

        for (uint256 i = 0; i < fractionalNFTs[_originalNFTId].fractionalTokenHolders.length; i++) { // Inefficient iteration, use better holder tracking
            address holder = fractionalNFTs[_originalNFTId].fractionalTokenHolders[i];
            uint256 holderTokens = fractionalTokenBalances[_originalNFTId][holder];
            uint256 holderShare = (availableRedemptionAmount * holderTokens) / totalFractionalTokens;
            payable(holder).transfer(holderShare);
        }

        // Transfer original NFT ownership back to the contract or a designated redemption address (DAO choice)
        _transfer(ownerOf(_originalNFTId), address(this), _originalNFTId); // Contract takes ownership for redistribution or further DAO action

        fractionalNFTs[_originalNFTId].redemptionVoteActive = false; // End redemption vote
        artNFTs[_originalNFTId].isFractionalized = false; // No longer fractionalized after redemption (optional)
    }

    // 17. proposeGalleryFeeUpdate: DAO members propose changes to the gallery commission fee
    function proposeGalleryFeeUpdate(uint256 _newFeePercentage) public onlyDAOMembers {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        // In a real DAO, implement proposal and voting mechanism
        // For simplicity, direct execution after DAO member proposal in this example
        setGalleryFee(_newFeePercentage); // Directly execute fee update after proposal (simplified DAO)
    }

    // 18. voteOnGalleryFeeUpdate: DAO members vote on proposed gallery fee updates (Placeholder - voting not implemented in this simplified example)
    // In a real DAO, this would involve voting logic and execution based on vote results.
    function voteOnGalleryFeeUpdate(uint256 _newFeePercentage, bool _vote) public onlyDAOMembers {
        // In a real DAO, implement voting logic and tallying
        // For simplicity, voting is skipped in this example, and fee update is directly executed upon proposal.
        if (_vote) { // Placeholder - assume vote passes if DAO member votes yes
            // In a real DAO, check quorum and majority
            setGalleryFee(_newFeePercentage);
        }
    }

    // 19. setGalleryFee: Executes approved gallery fee updates (Direct execution for simplicity in this example)
    function setGalleryFee(uint256 _newFeePercentage) internal onlyDAOMembers { // Internal function to be called by DAO governance
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        galleryFeePercentage = _newFeePercentage;
        emit GalleryFeeUpdated(_newFeePercentage);
    }

    // 20. becomeDAOMember: Allows users to become DAO members (e.g., by paying a fee or holding a token)
    function becomeDAOMember() public payable {
        // Example: Simple DAO membership based on paying a small fee
        uint256 membershipFee = 0.01 ether; // Example fee
        require(msg.value >= membershipFee, "Insufficient membership fee.");
        require(!isDAOMember(_msgSender()), "Already a DAO member.");

        daoMembers.add(_msgSender());
        galleryWallet.transfer(membershipFee); // Gallery receives membership fee
        emit DAOMemberJoined(_msgSender());
    }

    function isDAOMember(address _account) public view returns (bool) {
        return daoMembers.contains(_account);
    }

    function isCurator(address _account) public view returns (bool) {
        return curators.contains(_account);
    }

    // Function to add curators (Owner-controlled initially, could be DAO governed later)
    function addCurator(address _curator) public onlyOwner {
        curators.add(_curator);
    }

    // Function to remove curators (Owner-controlled initially, could be DAO governed later)
    function removeCurator(address _curator) public onlyOwner {
        curators.remove(_curator);
    }

    // 21. revokeDAOMembership: DAO can revoke membership (Governance action, simplified in this example)
    function revokeDAOMembership(address _member) public onlyDAOMembers {
        require(isDAOMember(_member), "Not a DAO member.");
        require(_member != owner(), "Cannot revoke owner's DAO membership."); // Prevent revoking owner

        daoMembers.remove(_member);
        emit DAOMemberRevoked(_member);
    }

    // 22. withdrawArtistEarnings: Allows artists to withdraw their earnings from NFT sales
    function withdrawArtistEarnings() public payable {
        // In this simplified example, artist earnings are directly transferred upon sale.
        // In a more complex system, you might track artist balances and allow withdrawal.
        // This function is a placeholder for potential future implementation if needed.
        // For now, artists receive funds immediately upon NFT sale.
        emit ArtistEarningsWithdrawn(_msgSender(), 0); // Amount is 0 as earnings are directly transferred in purchaseArt
    }

    // 23. getExhibitionDetails: Retrieves details of a specific exhibition
    function getExhibitionDetails(uint256 _exhibitionId) public view returns (Exhibition memory) {
        require(exhibitions[_exhibitionId].exhibitionId == _exhibitionId, "Exhibition does not exist.");
        return exhibitions[_exhibitionId];
    }

    // 24. getArtDetails: Retrieves details of a specific Art NFT
    function getArtDetails(uint256 _tokenId) public view returns (ArtNFT memory) {
        require(artNFTs[_tokenId].tokenId == _tokenId, "Art NFT does not exist.");
        return artNFTs[_tokenId];
    }

    // 25. getGalleryBalance: Returns the current balance of the gallery contract
    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Fallback function to receive Ether into the contract
    receive() external payable {}
}
```