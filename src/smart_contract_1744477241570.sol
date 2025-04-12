```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (Example Smart Contract - Educational Purposes)
 * @dev A sophisticated smart contract for a decentralized art gallery, 
 * incorporating advanced concepts like curated NFT collections, DAO governance for curation,
 * fractionalized NFT ownership, dynamic royalty splits, and community-driven features.
 *
 * Function Summary:
 * -----------------
 * **NFT Management & Marketplace:**
 * 1. mintArtNFT(string memory _uri, address[] memory _collaborators, uint256[] memory _collaboratorShares): Mint an Art NFT with optional collaborators and royalty splits.
 * 2. listArtNFTForSale(uint256 _tokenId, uint256 _price): List an Art NFT for sale in the gallery marketplace.
 * 3. buyArtNFT(uint256 _tokenId): Purchase an Art NFT listed for sale.
 * 4. cancelArtNFTListing(uint256 _tokenId): Cancel an NFT listing if the owner decides to remove it from sale.
 * 5. setArtNFTRoyalty(uint256 _tokenId, uint256 _royaltyPercentage): Set or update the royalty percentage for an Art NFT.
 * 6. transferArtNFT(address _to, uint256 _tokenId): Transfer ownership of an Art NFT.
 * 7. fractionalizeArtNFT(uint256 _tokenId, uint256 _fractionCount): Fractionalize an Art NFT into a specified number of fractional tokens.
 * 8. redeemFractionalizedNFT(uint256 _tokenId): Allow fractional token holders to collectively redeem and claim full NFT ownership (DAO voting required).
 *
 * **Curated Collections & Exhibitions:**
 * 9. createCuratedCollection(string memory _collectionName, string memory _collectionDescription): Create a curated art collection within the gallery.
 * 10. addArtNFTToCollection(uint256 _collectionId, uint256 _tokenId): Add an Art NFT to a specific curated collection.
 * 11. removeArtNFTFromCollection(uint256 _collectionId, uint256 _tokenId): Remove an Art NFT from a curated collection.
 * 12. proposeNewCollectionCurator(uint256 _collectionId, address _proposedCurator): Propose a new curator for a specific collection (DAO governance).
 * 13. voteOnCuratorProposal(uint256 _proposalId, bool _vote): Vote on a curator proposal (DAO governance).
 * 14. executeCuratorProposal(uint256 _proposalId): Execute a curator proposal if it passes (DAO governance).
 *
 * **DAO Governance & Gallery Management:**
 * 15. proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue): Propose changes to gallery parameters (fees, royalty percentages, etc.) (DAO governance).
 * 16. voteOnParameterProposal(uint256 _proposalId, bool _vote): Vote on a gallery parameter change proposal (DAO governance).
 * 17. executeParameterProposal(uint256 _proposalId): Execute a parameter change proposal if it passes (DAO governance).
 * 18. depositToGalleryTreasury(): Allow users to deposit funds to the gallery treasury (for community grants, development, etc.).
 * 19. proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string memory _reason): Propose a withdrawal from the gallery treasury (DAO governance).
 * 20. voteOnTreasuryWithdrawal(uint256 _proposalId, bool _vote): Vote on a treasury withdrawal proposal (DAO governance).
 * 21. executeTreasuryWithdrawal(uint256 _proposalId): Execute a treasury withdrawal proposal if it passes (DAO governance).
 * 22. supportArtist(uint256 _tokenId): Allow users to directly support an artist by sending a tip for their NFT.
 *
 * **Utility & Information:**
 * 23. getArtNFTDetails(uint256 _tokenId): Get detailed information about an Art NFT.
 * 24. getCollectionDetails(uint256 _collectionId): Get details about a curated collection.
 * 25. getGalleryTreasuryBalance(): Get the current balance of the gallery treasury.
 */

contract DecentralizedAutonomousArtGallery {
    // --- Data Structures ---
    struct ArtNFT {
        uint256 tokenId;
        address artist;
        string uri;
        uint256 royaltyPercentage;
        address[] collaborators;
        uint256[] collaboratorShares;
        bool isFractionalized;
        uint256 fractionalTokenSupply;
    }

    struct Collection {
        uint256 collectionId;
        string name;
        string description;
        address curator;
        uint256[] artNFTs; // Array of tokenIds in the collection
    }

    struct Listing {
        uint256 tokenId;
        uint256 price;
        address seller;
        bool isActive;
    }

    struct Proposal {
        uint256 proposalId;
        ProposalType proposalType;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        // Generic data field to store proposal-specific information (e.g., new curator address, parameter changes)
        bytes data;
    }

    enum ProposalType {
        CURATOR_CHANGE,
        PARAMETER_CHANGE,
        TREASURY_WITHDRAWAL,
        NFT_REDEEM
    }

    // --- State Variables ---
    mapping(uint256 => ArtNFT) public artNFTs; // tokenId => ArtNFT
    mapping(uint256 => Collection) public collections; // collectionId => Collection
    mapping(uint256 => Listing) public listings; // tokenId => Listing
    mapping(uint256 => Proposal) public proposals; // proposalId => Proposal
    mapping(uint256 => mapping(address => bool)) public hasVoted; // proposalId => voterAddress => hasVoted

    uint256 public nextTokenId = 1;
    uint256 public nextCollectionId = 1;
    uint256 public nextProposalId = 1;
    uint256 public galleryFeePercentage = 5; // Example gallery fee percentage
    uint256 public votingDuration = 7 days; // Example voting duration
    address public galleryOwner; // DAO/Multisig address could be set as owner

    // --- Events ---
    event ArtNFTMinted(uint256 tokenId, address artist, string uri);
    event ArtNFTListedForSale(uint256 tokenId, uint256 price, address seller);
    event ArtNFTBought(uint256 tokenId, address buyer, address seller, uint256 price);
    event ArtNFTListingCancelled(uint256 tokenId, address seller);
    event ArtNFTRoyaltySet(uint256 tokenId, uint256 royaltyPercentage);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtNFTFractionalized(uint256 tokenId, uint256 fractionCount);
    event ArtNFTRedeemed(uint256 tokenId);

    event CollectionCreated(uint256 collectionId, string name, address curator);
    event ArtNFTAddedToCollection(uint256 collectionId, uint256 tokenId);
    event ArtNFTRemovedFromCollection(uint256 collectionId, uint256 tokenId);
    event CuratorProposalCreated(uint256 proposalId, uint256 collectionId, address proposedCurator, address proposer);
    event ParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event TreasuryWithdrawalProposalCreated(uint256 proposalId, address recipient, uint256 amount, string reason, address proposer);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, ProposalType proposalType);
    event SupportGivenToArtist(uint256 tokenId, address supporter, uint256 amount);

    constructor() {
        galleryOwner = msg.sender; // In a real DAO, this would be initialized differently
    }

    // --- Modifiers ---
    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function");
        _;
    }

    modifier onlyArtist(uint256 _tokenId) {
        require(artNFTs[_tokenId].artist == msg.sender, "Only artist can call this function");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        address owner = ERC721Interface(address(this)).ownerOf(_tokenId); // Assuming ERC721 compliance
        require(owner == msg.sender, "Only NFT owner can call this function");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(proposals[_proposalId].proposalId == _proposalId, "Invalid proposal ID");
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period ended");
        _;
    }

    // --- Interfaces (Assuming ERC721 Compliance for ArtNFTs) ---
    interface ERC721Interface {
        function ownerOf(uint256 tokenId) external view returns (address owner);
        function transferFrom(address from, address to, uint256 tokenId) external;
        function balanceOf(address owner) external view returns (uint256 balance);
        function approve(address approved, uint256 tokenId) external;
        function getApproved(uint256 tokenId) external view returns (address operator);
    }

    // --- NFT Management & Marketplace Functions ---

    /// @dev Mints a new Art NFT. Allows setting collaborators and their royalty shares.
    /// @param _uri URI for the NFT metadata.
    /// @param _collaborators Array of addresses of collaborators.
    /// @param _collaboratorShares Array of royalty shares (percentages - sum should be <= 100).
    function mintArtNFT(string memory _uri, address[] memory _collaborators, uint256[] memory _collaboratorShares) external {
        require(_collaborators.length == _collaboratorShares.length, "Collaborators and shares arrays must have the same length");
        uint256 totalShares = 0;
        for (uint256 share : _collaboratorShares) {
            totalShares += share;
        }
        require(totalShares <= 100, "Total collaborator shares cannot exceed 100%");

        uint256 tokenId = nextTokenId++;
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            artist: msg.sender,
            uri: _uri,
            royaltyPercentage: 10, // Default royalty, can be changed later
            collaborators: _collaborators,
            collaboratorShares: _collaboratorShares,
            isFractionalized: false,
            fractionalTokenSupply: 0
        });

        // In a real implementation, you would mint the ERC721 token here.
        // For simplicity, this example assumes an internal token management.

        emit ArtNFTMinted(tokenId, msg.sender, _uri);
    }

    /// @dev Lists an Art NFT for sale in the gallery marketplace.
    /// @param _tokenId ID of the NFT to list.
    /// @param _price Price in wei.
    function listArtNFTForSale(uint256 _tokenId, uint256 _price) external onlyNFTOwner(_tokenId) {
        require(artNFTs[_tokenId].tokenId == _tokenId, "NFT does not exist");
        require(!listings[_tokenId].isActive, "NFT is already listed");

        listings[_tokenId] = Listing({
            tokenId: _tokenId,
            price: _price,
            seller: msg.sender,
            isActive: true
        });
        emit ArtNFTListedForSale(_tokenId, _price, msg.sender);
    }

    /// @dev Allows a user to buy an Art NFT listed for sale.
    /// @param _tokenId ID of the NFT to buy.
    function buyArtNFT(uint256 _tokenId) external payable {
        require(listings[_tokenId].isActive, "NFT is not listed for sale");
        require(msg.value >= listings[_tokenId].price, "Insufficient funds");

        Listing storage listing = listings[_tokenId];
        ArtNFT storage nft = artNFTs[_tokenId];
        uint256 price = listing.price;
        address seller = listing.seller;

        listing.isActive = false; // Deactivate listing

        // Transfer funds (with royalty and gallery fee)
        uint256 galleryFee = (price * galleryFeePercentage) / 100;
        uint256 artistRoyalty = (price * nft.royaltyPercentage) / 100;
        uint256 artistPayment = price - galleryFee - artistRoyalty;

        payable(seller).transfer(artistPayment); // Pay artist (and collaborators - needs further logic for splits)
        payable(nft.artist).transfer(artistRoyalty); // Pay artist royalty
        payable(galleryOwner).transfer(galleryFee); // Pay gallery fee

        // Transfer NFT ownership (ERC721 transfer)
        ERC721Interface(address(this)).transferFrom(seller, msg.sender, _tokenId);
        // In a real implementation, the contract would need to be approved to transfer on behalf of the seller.
        // For simplicity, assuming internal ownership management in this example.

        emit ArtNFTBought(_tokenId, msg.sender, seller, price);
    }

    /// @dev Cancels an NFT listing, only callable by the seller.
    /// @param _tokenId ID of the NFT listing to cancel.
    function cancelArtNFTListing(uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        require(listings[_tokenId].isActive, "NFT is not listed for sale");
        listings[_tokenId].isActive = false;
        emit ArtNFTListingCancelled(_tokenId, msg.sender);
    }

    /// @dev Sets or updates the royalty percentage for an Art NFT. Only callable by the artist.
    /// @param _tokenId ID of the NFT to set royalty for.
    /// @param _royaltyPercentage New royalty percentage.
    function setArtNFTRoyalty(uint256 _tokenId, uint256 _royaltyPercentage) external onlyArtist(_tokenId) {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot exceed 50%"); // Example limit
        artNFTs[_tokenId].royaltyPercentage = _royaltyPercentage;
        emit ArtNFTRoyaltySet(_tokenId, _royaltyPercentage);
    }

    /// @dev Transfers ownership of an Art NFT.
    /// @param _to Address of the recipient.
    /// @param _tokenId ID of the NFT to transfer.
    function transferArtNFT(address _to, uint256 _tokenId) external onlyNFTOwner(_tokenId) {
        ERC721Interface(address(this)).transferFrom(msg.sender, _to, _tokenId);
        emit ArtNFTTransferred(_tokenId, msg.sender, _to);
    }

    /// @dev Fractionalizes an Art NFT into a specified number of fractional tokens.
    /// @param _tokenId ID of the NFT to fractionalize.
    /// @param _fractionCount Number of fractional tokens to create.
    function fractionalizeArtNFT(uint256 _tokenId, uint256 _fractionCount) external onlyNFTOwner(_tokenId) {
        require(!artNFTs[_tokenId].isFractionalized, "NFT is already fractionalized");
        require(_fractionCount > 1, "Fraction count must be greater than 1");

        artNFTs[_tokenId].isFractionalized = true;
        artNFTs[_tokenId].fractionalTokenSupply = _fractionCount;

        // In a real implementation, you would mint fractional tokens (ERC20) associated with this NFT.
        // For simplicity, we are just marking it as fractionalized and tracking supply in this example.

        emit ArtNFTFractionalized(_tokenId, _fractionCount);
    }

    /// @dev Allows fractional token holders to propose redeeming the original NFT. Requires DAO voting.
    /// @param _tokenId ID of the fractionalized NFT to redeem.
    function redeemFractionalizedNFT(uint256 _tokenId) external {
        require(artNFTs[_tokenId].isFractionalized, "NFT is not fractionalized");
        require(ERC721Interface(address(this)).balanceOf(address(this)) > 0, "Contract does not hold the NFT"); // Simple check, more robust logic needed

        // Create a DAO proposal for NFT redemption
        bytes memory data = abi.encode(_tokenId);
        _createProposal(ProposalType.NFT_REDEEM, data);
    }


    // --- Curated Collections & Exhibitions Functions ---

    /// @dev Creates a new curated art collection. Only gallery owner can create collections initially,
    ///      later curator roles can be proposed and voted on via DAO.
    /// @param _collectionName Name of the collection.
    /// @param _collectionDescription Description of the collection.
    function createCuratedCollection(string memory _collectionName, string memory _collectionDescription) external onlyGalleryOwner {
        uint256 collectionId = nextCollectionId++;
        collections[collectionId] = Collection({
            collectionId: collectionId,
            name: _collectionName,
            description: _collectionDescription,
            curator: msg.sender, // Initially, creator is curator
            artNFTs: new uint256[](0)
        });
        emit CollectionCreated(collectionId, _collectionName, msg.sender);
    }

    /// @dev Adds an Art NFT to a specific curated collection. Only the collection curator can add NFTs.
    /// @param _collectionId ID of the collection to add to.
    /// @param _tokenId ID of the Art NFT to add.
    function addArtNFTToCollection(uint256 _collectionId, uint256 _tokenId) external {
        require(collections[_collectionId].collectionId == _collectionId, "Collection does not exist");
        require(collections[_collectionId].curator == msg.sender, "Only collection curator can add NFTs");
        require(artNFTs[_tokenId].tokenId == _tokenId, "NFT does not exist");

        collections[_collectionId].artNFTs.push(_tokenId);
        emit ArtNFTAddedToCollection(_collectionId, _tokenId);
    }

    /// @dev Removes an Art NFT from a curated collection. Only the collection curator can remove NFTs.
    /// @param _collectionId ID of the collection to remove from.
    /// @param _tokenId ID of the Art NFT to remove.
    function removeArtNFTFromCollection(uint256 _collectionId, uint256 _tokenId) external {
        require(collections[_collectionId].collectionId == _collectionId, "Collection does not exist");
        require(collections[_collectionId].curator == msg.sender, "Only collection curator can remove NFTs");

        uint256[] storage collectionNFTs = collections[_collectionId].artNFTs;
        for (uint256 i = 0; i < collectionNFTs.length; i++) {
            if (collectionNFTs[i] == _tokenId) {
                // Remove element by shifting elements to the left
                for (uint256 j = i; j < collectionNFTs.length - 1; j++) {
                    collectionNFTs[j] = collectionNFTs[j + 1];
                }
                collectionNFTs.pop();
                emit ArtNFTRemovedFromCollection(_collectionId, _tokenId);
                return;
            }
        }
        revert("NFT not found in collection");
    }

    /// @dev Proposes a new curator for a specific collection. Requires DAO voting.
    /// @param _collectionId ID of the collection to change curator for.
    /// @param _proposedCurator Address of the proposed new curator.
    function proposeNewCollectionCurator(uint256 _collectionId, address _proposedCurator) external {
        require(collections[_collectionId].collectionId == _collectionId, "Collection does not exist");
        bytes memory data = abi.encode(_collectionId, _proposedCurator);
        _createProposal(ProposalType.CURATOR_CHANGE, data);
        emit CuratorProposalCreated(nextProposalId - 1, _collectionId, _proposedCurator, msg.sender);
    }

    /// @dev Vote on a curator change proposal.
    /// @param _proposalId ID of the curator change proposal.
    /// @param _vote True to vote for, false to vote against.
    function voteOnCuratorProposal(uint256 _proposalId, bool _vote) external validProposal(_proposalId) {
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");
        proposals[_proposalId].endTime = block.timestamp + votingDuration; // Extend voting if needed
        hasVoted[_proposalId][msg.sender] = true;

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes a curator change proposal if it passes (more 'for' votes than 'against').
    /// @param _proposalId ID of the curator change proposal to execute.
    function executeCuratorProposal(uint256 _proposalId) external onlyGalleryOwner validProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.CURATOR_CHANGE, "Proposal type mismatch");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal did not pass");

        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;

        (uint256 collectionId, address newCurator) = abi.decode(proposal.data, (uint256, address));
        collections[collectionId].curator = newCurator;

        emit ProposalExecuted(_proposalId, ProposalType.CURATOR_CHANGE);
    }


    // --- DAO Governance & Gallery Management Functions ---

    /// @dev Proposes a change to a gallery parameter (e.g., fee percentage). Requires DAO voting.
    /// @param _parameterName Name of the parameter to change (string identifier).
    /// @param _newValue New value for the parameter.
    function proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue) external {
        bytes memory data = abi.encode(_parameterName, _newValue);
        _createProposal(ProposalType.PARAMETER_CHANGE, data);
        emit ParameterProposalCreated(nextProposalId - 1, _parameterName, _newValue, msg.sender);
    }

    /// @dev Vote on a gallery parameter change proposal.
    /// @param _proposalId ID of the parameter change proposal.
    /// @param _vote True to vote for, false to vote against.
    function voteOnParameterProposal(uint256 _proposalId, bool _vote) external validProposal(_proposalId) {
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");
        proposals[_proposalId].endTime = block.timestamp + votingDuration; // Extend voting if needed
        hasVoted[_proposalId][msg.sender] = true;

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes a gallery parameter change proposal if it passes (more 'for' votes than 'against').
    /// @param _proposalId ID of the parameter change proposal to execute.
    function executeParameterProposal(uint256 _proposalId) external onlyGalleryOwner validProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.PARAMETER_CHANGE, "Proposal type mismatch");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal did not pass");

        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;

        (string memory parameterName, uint256 newValue) = abi.decode(proposal.data, (string, uint256));

        if (keccak256(bytes(parameterName)) == keccak256(bytes("galleryFeePercentage"))) {
            galleryFeePercentage = newValue;
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("votingDuration"))) {
            votingDuration = newValue;
        } else {
            revert("Unknown parameter to change");
        }

        emit ProposalExecuted(_proposalId, ProposalType.PARAMETER_CHANGE);
    }

    /// @dev Allows users to deposit funds into the gallery treasury.
    function depositToGalleryTreasury() external payable {
        payable(galleryOwner).transfer(msg.value); // For simplicity, treasury is directly the owner address in this example
        emit DepositToTreasury(msg.sender, msg.value); // Add DepositToTreasury event if needed
    }

    event DepositToTreasury(address depositor, uint256 amount);


    /// @dev Proposes a withdrawal from the gallery treasury. Requires DAO voting.
    /// @param _recipient Address to receive the withdrawal.
    /// @param _amount Amount to withdraw in wei.
    /// @param _reason Reason for the withdrawal.
    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string memory _reason) external {
        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(getGalleryTreasuryBalance() >= _amount, "Insufficient treasury balance");

        bytes memory data = abi.encode(_recipient, _amount, _reason);
        _createProposal(ProposalType.TREASURY_WITHDRAWAL, data);
        emit TreasuryWithdrawalProposalCreated(nextProposalId - 1, _recipient, _amount, _reason, msg.sender);
    }

    /// @dev Vote on a treasury withdrawal proposal.
    /// @param _proposalId ID of the treasury withdrawal proposal.
    /// @param _vote True to vote for, false to vote against.
    function voteOnTreasuryWithdrawal(uint256 _proposalId, bool _vote) external validProposal(_proposalId) {
        require(!hasVoted[_proposalId][msg.sender], "Already voted on this proposal");
        proposals[_proposalId].endTime = block.timestamp + votingDuration; // Extend voting if needed
        hasVoted[_proposalId][msg.sender] = true;

        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes a treasury withdrawal proposal if it passes (more 'for' votes than 'against').
    /// @param _proposalId ID of the treasury withdrawal proposal to execute.
    function executeTreasuryWithdrawal(uint256 _proposalId) external onlyGalleryOwner validProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == ProposalType.TREASURY_WITHDRAWAL, "Proposal type mismatch");
        require(proposals[_proposalId].votesFor > proposals[_proposalId].votesAgainst, "Proposal did not pass");

        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;

        (address recipient, uint256 amount, string memory reason) = abi.decode(proposal.data, (address, uint256, string));
        payable(recipient).transfer(amount);

        emit ProposalExecuted(_proposalId, ProposalType.TREASURY_WITHDRAWAL);
    }

    /// @dev Allows users to directly support an artist by sending a tip for their NFT.
    /// @param _tokenId ID of the NFT to support.
    function supportArtist(uint256 _tokenId) external payable {
        require(artNFTs[_tokenId].tokenId == _tokenId, "NFT does not exist");
        require(msg.value > 0, "Support amount must be greater than zero");

        payable(artNFTs[_tokenId].artist).transfer(msg.value);
        emit SupportGivenToArtist(_tokenId, msg.sender, msg.value);
    }


    // --- Utility & Information Functions ---

    /// @dev Gets detailed information about an Art NFT.
    /// @param _tokenId ID of the NFT to query.
    /// @return ArtNFT struct containing NFT details.
    function getArtNFTDetails(uint256 _tokenId) external view returns (ArtNFT memory) {
        require(artNFTs[_tokenId].tokenId == _tokenId, "NFT does not exist");
        return artNFTs[_tokenId];
    }

    /// @dev Gets details about a curated collection.
    /// @param _collectionId ID of the collection to query.
    /// @return Collection struct containing collection details.
    function getCollectionDetails(uint256 _collectionId) external view returns (Collection memory) {
        require(collections[_collectionId].collectionId == _collectionId, "Collection does not exist");
        return collections[_collectionId];
    }

    /// @dev Gets the current balance of the gallery treasury.
    /// @return Treasury balance in wei.
    function getGalleryTreasuryBalance() public view returns (uint256) {
        return address(this).balance; // In this simplified example, treasury balance is contract balance.
                                      // In a real DAO, treasury might be managed separately.
    }


    // --- Internal Helper Functions ---
    function _createProposal(ProposalType _proposalType, bytes memory _data) internal {
        proposals[nextProposalId] = Proposal({
            proposalId: nextProposalId,
            proposalType: _proposalType,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            data: _data
        });
        nextProposalId++;
    }
}
```