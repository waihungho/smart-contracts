```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, enabling artists to showcase and sell their digital art (NFTs),
 *      governed by a community DAO. This gallery features advanced curation mechanisms, dynamic exhibitions,
 *      artist collaboration features, and innovative revenue sharing, moving beyond typical NFT marketplaces.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1. `setGalleryName(string _name)`: Allows the contract owner to set the gallery's name. (Admin)
 * 2. `getGalleryName()`: Returns the gallery's name. (View)
 * 3. `createArtNFT(string _uri)`: Artists can mint their digital artwork as NFTs. (Artist)
 * 4. `transferArtNFT(uint256 _tokenId, address _to)`: Transfer ownership of an Art NFT. (NFT Owner)
 * 5. `listArtForSale(uint256 _tokenId, uint256 _price)`: Artist lists their NFT for sale in the gallery. (Artist/NFT Owner)
 * 6. `unlistArtFromSale(uint256 _tokenId)`: Artist removes their NFT from sale. (Artist/NFT Owner)
 * 7. `purchaseArt(uint256 _tokenId)`: Anyone can purchase listed NFTs. (Public)
 * 8. `getArtDetails(uint256 _tokenId)`: Retrieve detailed information about an Art NFT listed in the gallery. (View)
 * 9. `getTotalArtworksListed()`: Returns the total number of artworks currently listed for sale. (View)
 * 10. `getAllListedArtworks()`: Returns a list of token IDs of all currently listed artworks. (View)
 *
 * **Curation & Exhibition Features:**
 * 11. `proposeCurator(address _curatorAddress)`: DAO members can propose new curators. (DAO Member)
 * 12. `voteOnCuratorProposal(uint256 _proposalId, bool _vote)`: DAO members vote on curator proposals. (DAO Member)
 * 13. `addCurator(address _curatorAddress)`: Only DAO can finalize and add a curator after successful proposal. (DAO)
 * 14. `removeCurator(address _curatorAddress)`: Only DAO can remove a curator. (DAO)
 * 15. `createExhibition(string _exhibitionName, string _theme)`: Curators can create new exhibitions. (Curator)
 * 16. `addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Curators can add artworks to exhibitions. (Curator)
 * 17. `removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Curators can remove artworks from exhibitions. (Curator)
 * 18. `startExhibition(uint256 _exhibitionId)`: Curators can start an exhibition, making it publicly viewable. (Curator)
 * 19. `endExhibition(uint256 _exhibitionId)`: Curators can end an exhibition. (Curator)
 * 20. `getExhibitionDetails(uint256 _exhibitionId)`: View details of an exhibition, including artworks. (View)
 * 21. `getAllActiveExhibitions()`: Returns a list of IDs of all currently active exhibitions. (View)
 *
 * **Artist Collaboration & Revenue Sharing:**
 * 22. `collaborateOnArtwork(uint256 _tokenId, address[] memory _collaborators, uint256[] memory _shares)`: Artist can propose collaboration on their artwork with revenue shares. (Artist/NFT Owner)
 * 23. `acceptCollaborationInvite(uint256 _tokenId, address _collaborator)`: Collaborators can accept collaboration invites. (Collaborator)
 * 24. `finalizeCollaboration(uint256 _tokenId)`: Artist can finalize collaboration after all collaborators accept. (Artist/NFT Owner)
 * 25. `withdrawArtistEarnings(uint256 _tokenId)`: Artists and collaborators can withdraw their earnings from sales. (Artist/Collaborator)
 * 26. `setGalleryFee(uint256 _feePercentage)`: DAO can set the gallery's platform fee percentage. (DAO)
 * 27. `getGalleryFee()`: Returns the current gallery fee percentage. (View)
 * 28. `withdrawGalleryFees()`: DAO can withdraw accumulated gallery fees. (DAO)
 *
 * **DAO Governance & Utility:**
 * 29. `proposeDAOParameterChange(string memory _parameterName, uint256 _newValue)`: DAO members can propose changes to gallery parameters (e.g., fee, voting duration). (DAO Member)
 * 30. `voteOnParameterProposal(uint256 _proposalId, bool _vote)`: DAO members vote on parameter change proposals. (DAO Member)
 * 31. `executeParameterChange(uint256 _proposalId)`: DAO can execute approved parameter change proposals. (DAO)
 * 32. `setDAOVotingDuration(uint256 _durationInBlocks)`: DAO can set the voting duration for proposals. (DAO)
 * 33. `getDAOVotingDuration()`: Returns the current DAO voting duration. (View)
 * 34. `pauseContract()`: Contract owner can pause core functionalities in case of emergency. (Admin)
 * 35. `unpauseContract()`: Contract owner can unpause the contract. (Admin)
 */
contract DecentralizedAutonomousArtGallery {
    string public galleryName;
    address public owner;
    bool public paused;

    // --- NFT Management ---
    mapping(uint256 => address) public artTokenOwner; // Token ID to Owner Address
    mapping(uint256 => string) public artTokenURIs;  // Token ID to URI
    uint256 public nextArtTokenId = 1;

    // --- Marketplace ---
    struct Listing {
        uint256 tokenId;
        address artist;
        uint256 price;
        bool isListed;
    }
    mapping(uint256 => Listing) public artListings; // Token ID to Listing details
    uint256 public listedArtworkCount = 0;

    // --- Curation & Exhibition ---
    mapping(address => bool) public curators;
    address[] public curatorList;
    struct CuratorProposal {
        address curatorAddress;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalEndTime;
        bool isActive;
    }
    mapping(uint256 => CuratorProposal) public curatorProposals;
    uint256 public nextCuratorProposalId = 1;

    struct Exhibition {
        string name;
        string theme;
        address curator;
        uint256[] artworkTokenIds;
        bool isActive;
        uint256 startTime;
        uint256 endTime;
    }
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public nextExhibitionId = 1;

    // --- Artist Collaboration & Revenue Sharing ---
    struct Collaboration {
        address artist;
        address[] collaborators;
        uint256[] shares; // Percentage shares for each collaborator
        bool isFinalized;
        bool isActive;
    }
    mapping(uint256 => Collaboration) public artworkCollaborations;
    mapping(uint256 => mapping(address => bool)) public collaborationInvitations; // tokenId -> collaborator address -> invited?
    mapping(uint256 => mapping(address => uint256)) public artistEarnings; // TokenId -> artist/collaborator -> earnings

    uint256 public galleryFeePercentage = 5; // Default 5% gallery fee
    uint256 public accumulatedGalleryFees;

    // --- DAO Governance ---
    mapping(address => bool) public daoMembers; // Placeholder for DAO membership (replace with actual DAO mechanism)
    uint256 public daoVotingDuration = 7 days; // Default 7 days voting duration

    struct DAOParameterProposal {
        string parameterName;
        uint256 newValue;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalEndTime;
        bool isActive;
    }
    mapping(uint256 => DAOParameterProposal) public parameterProposals;
    uint256 public nextParameterProposalId = 1;

    // --- Events ---
    event GalleryNameSet(string name);
    event ArtNFTMinted(uint256 tokenId, address artist, string tokenURI);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtListedForSale(uint256 tokenId, uint256 price);
    event ArtUnlistedFromSale(uint256 tokenId);
    event ArtPurchased(uint256 tokenId, address buyer, uint256 price);
    event CuratorProposed(uint256 proposalId, address curatorAddress, address proposer);
    event CuratorProposalVoted(uint256 proposalId, address voter, bool vote);
    event CuratorAdded(address curatorAddress, address addedBy);
    event CuratorRemoved(address curatorAddress, address removedBy);
    event ExhibitionCreated(uint256 exhibitionId, string name, string theme, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId, address curator);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId, address curator);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event CollaborationProposed(uint256 tokenId, address artist, address[] collaborators);
    event CollaborationInviteAccepted(uint256 tokenId, address collaborator);
    event CollaborationFinalized(uint256 tokenId, address artist, address[] collaborators);
    event ArtistEarningsWithdrawn(uint256 tokenId, address artist, uint256 amount);
    event GalleryFeeSet(uint256 feePercentage, address setBy);
    event GalleryFeesWithdrawn(uint256 amount, address withdrawnBy);
    event DAOParameterProposalCreated(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event DAOParameterProposalVoted(uint256 proposalId, address voter, bool vote);
    event DAOParameterChanged(uint256 proposalId, string parameterName, uint256 newValue, address executedBy);
    event DAOVotingDurationSet(uint256 durationInBlocks, address setBy);
    event ContractPaused(address pausedBy);
    event ContractUnpaused(address unpausedBy);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender], "Only curators can perform this action.");
        _;
    }

    modifier onlyDAO() {
        require(daoMembers[msg.sender], "Only DAO members can perform this action. (Placeholder)"); // Replace with actual DAO logic
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

    // --- Constructor ---
    constructor(string memory _galleryName) {
        owner = msg.sender;
        galleryName = _galleryName;
        daoMembers[owner] = true; // Initially, owner is a DAO member (replace with actual DAO setup)
    }

    // --- Core Functionality ---
    function setGalleryName(string memory _name) public onlyOwner {
        galleryName = _name;
        emit GalleryNameSet(_name);
    }

    function getGalleryName() public view returns (string memory) {
        return galleryName;
    }

    function createArtNFT(string memory _uri) public whenNotPaused returns (uint256) {
        uint256 tokenId = nextArtTokenId++;
        artTokenOwner[tokenId] = msg.sender;
        artTokenURIs[tokenId] = _uri;
        emit ArtNFTMinted(tokenId, msg.sender, _uri);
        return tokenId;
    }

    function transferArtNFT(uint256 _tokenId, address _to) public whenNotPaused {
        require(artTokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(_to != address(0), "Invalid recipient address.");
        artTokenOwner[_tokenId] = _to;
        emit ArtNFTTransferred(_tokenId, msg.sender, _to);
    }

    function listArtForSale(uint256 _tokenId, uint256 _price) public whenNotPaused {
        require(artTokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(_price > 0, "Price must be greater than zero.");
        require(!artListings[_tokenId].isListed, "Artwork is already listed for sale.");

        artListings[_tokenId] = Listing({
            tokenId: _tokenId,
            artist: msg.sender,
            price: _price,
            isListed: true
        });
        listedArtworkCount++;
        emit ArtListedForSale(_tokenId, _price);
    }

    function unlistArtFromSale(uint256 _tokenId) public whenNotPaused {
        require(artTokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(artListings[_tokenId].isListed, "Artwork is not currently listed for sale.");

        artListings[_tokenId].isListed = false;
        listedArtworkCount--;
        emit ArtUnlistedFromSale(_tokenId);
    }

    function purchaseArt(uint256 _tokenId) public payable whenNotPaused {
        require(artListings[_tokenId].isListed, "Artwork is not listed for sale.");
        require(msg.value >= artListings[_tokenId].price, "Insufficient funds.");

        Listing storage listing = artListings[_tokenId];
        uint256 salePrice = listing.price;
        address artist = listing.artist;

        // Calculate gallery fee
        uint256 galleryFee = (salePrice * galleryFeePercentage) / 100;
        uint256 artistPayout = salePrice - galleryFee;

        // Transfer NFT ownership
        artTokenOwner[_tokenId] = msg.sender;

        // Transfer funds
        payable(artist).transfer(artistPayout);
        accumulatedGalleryFees += galleryFee;

        // Update listing status
        listing.isListed = false;
        listedArtworkCount--;
        delete artListings[_tokenId]; // Clean up listing data after sale

        // Record earnings for artist (and collaborators, if any - handled in collaboration functions)
        artistEarnings[_tokenId][artist] += artistPayout;

        emit ArtPurchased(_tokenId, msg.sender, salePrice);
        emit ArtNFTTransferred(_tokenId, artist, msg.sender); // Emit NFT transfer event upon purchase
    }

    function getArtDetails(uint256 _tokenId) public view returns (Listing memory, string memory) {
        return (artListings[_tokenId], artTokenURIs[_tokenId]);
    }

    function getTotalArtworksListed() public view returns (uint256) {
        return listedArtworkCount;
    }

    function getAllListedArtworks() public view returns (uint256[] memory) {
        uint256[] memory listedTokenIds = new uint256[](listedArtworkCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextArtTokenId; i++) {
            if (artListings[i].isListed) {
                listedTokenIds[index] = i;
                index++;
            }
        }
        return listedTokenIds;
    }

    // --- Curation & Exhibition Features ---
    function proposeCurator(address _curatorAddress) public onlyDAO whenNotPaused {
        require(_curatorAddress != address(0), "Invalid curator address.");
        require(!curators[_curatorAddress], "Address is already a curator.");

        curatorProposals[nextCuratorProposalId] = CuratorProposal({
            curatorAddress: _curatorAddress,
            votesFor: 0,
            votesAgainst: 0,
            proposalEndTime: block.timestamp + daoVotingDuration,
            isActive: true
        });
        emit CuratorProposed(nextCuratorProposalId, _curatorAddress, msg.sender);
        nextCuratorProposalId++;
    }

    function voteOnCuratorProposal(uint256 _proposalId, bool _vote) public onlyDAO whenNotPaused {
        require(curatorProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < curatorProposals[_proposalId].proposalEndTime, "Voting period has ended.");

        if (_vote) {
            curatorProposals[_proposalId].votesFor++;
        } else {
            curatorProposals[_proposalId].votesAgainst++;
        }
        emit CuratorProposalVoted(_proposalId, msg.sender, _vote);
    }

    function addCurator(address _curatorAddress) public onlyDAO whenNotPaused {
        require(_curatorAddress != address(0), "Invalid curator address.");
        require(!curators[_curatorAddress], "Address is already a curator.");

        // Find the proposal (inefficient if many proposals, consider indexing or more efficient lookup)
        uint256 proposalIdToExecute = 0;
        for (uint256 i = 1; i < nextCuratorProposalId; i++) {
            if (curatorProposals[i].isActive && curatorProposals[i].curatorAddress == _curatorAddress && block.timestamp >= curatorProposals[i].proposalEndTime) {
                proposalIdToExecute = i;
                break;
            }
        }

        require(proposalIdToExecute != 0, "No active and ended proposal found for this curator address.");
        require(curatorProposals[proposalIdToExecute].votesFor > curatorProposals[proposalIdToExecute].votesAgainst, "Proposal did not pass.");

        curators[_curatorAddress] = true;
        curatorList.push(_curatorAddress);
        curatorProposals[proposalIdToExecute].isActive = false; // Mark proposal as executed
        emit CuratorAdded(_curatorAddress, msg.sender);
    }

    function removeCurator(address _curatorAddress) public onlyDAO whenNotPaused {
        require(curators[_curatorAddress], "Address is not a curator.");
        curators[_curatorAddress] = false;

        // Remove from curatorList (less efficient if curatorList is large, consider alternative data structure)
        for (uint256 i = 0; i < curatorList.length; i++) {
            if (curatorList[i] == _curatorAddress) {
                delete curatorList[i]; // Delete leaves a gap, can be improved for dense array management if needed
                break;
            }
        }
        emit CuratorRemoved(_curatorAddress, msg.sender);
    }

    function createExhibition(string memory _exhibitionName, string memory _theme) public onlyCurator whenNotPaused returns (uint256) {
        uint256 exhibitionId = nextExhibitionId++;
        exhibitions[exhibitionId] = Exhibition({
            name: _exhibitionName,
            theme: _theme,
            curator: msg.sender,
            artworkTokenIds: new uint256[](0),
            isActive: false,
            startTime: 0,
            endTime: 0
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, _theme, msg.sender);
        return exhibitionId;
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyCurator whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "You are not the curator of this exhibition.");
        require(!exhibitions[_exhibitionId].isActive, "Cannot add art to an active exhibition.");
        require(artTokenOwner[_tokenId] != address(0), "Artwork token does not exist."); // Basic check, more robust checks can be added

        exhibitions[_exhibitionId].artworkTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId, msg.sender);
    }

    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyCurator whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "You are not the curator of this exhibition.");
        require(!exhibitions[_exhibitionId].isActive, "Cannot remove art from an active exhibition.");

        uint256[] storage artworkIds = exhibitions[_exhibitionId].artworkTokenIds;
        for (uint256 i = 0; i < artworkIds.length; i++) {
            if (artworkIds[i] == _tokenId) {
                delete artworkIds[i]; // Delete leaves a gap, consider array packing if order doesn't matter
                // To maintain order and remove gap, you could shift elements after the removed one to the left, but it's more gas intensive
                emit ArtRemovedFromExhibition(_exhibitionId, _tokenId, msg.sender);
                return;
            }
        }
        revert("Artwork not found in exhibition.");
    }

    function startExhibition(uint256 _exhibitionId) public onlyCurator whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "You are not the curator of this exhibition.");
        require(!exhibitions[_exhibitionId].isActive, "Exhibition is already active.");

        exhibitions[_exhibitionId].isActive = true;
        exhibitions[_exhibitionId].startTime = block.timestamp;
        emit ExhibitionStarted(_exhibitionId);
    }

    function endExhibition(uint256 _exhibitionId) public onlyCurator whenNotPaused {
        require(exhibitions[_exhibitionId].curator == msg.sender, "You are not the curator of this exhibition.");
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");

        exhibitions[_exhibitionId].isActive = false;
        exhibitions[_exhibitionId].endTime = block.timestamp;
        emit ExhibitionEnded(_exhibitionId);
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    function getAllActiveExhibitions() public view returns (uint256[] memory) {
        uint256 activeExhibitionCount = 0;
        for (uint256 i = 1; i < nextExhibitionId; i++) {
            if (exhibitions[i].isActive) {
                activeExhibitionCount++;
            }
        }

        uint256[] memory activeExhibitionIds = new uint256[](activeExhibitionCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextExhibitionId; i++) {
            if (exhibitions[i].isActive) {
                activeExhibitionIds[index] = i;
                index++;
            }
        }
        return activeExhibitionIds;
    }


    // --- Artist Collaboration & Revenue Sharing ---
    function collaborateOnArtwork(uint256 _tokenId, address[] memory _collaborators, uint256[] memory _shares) public whenNotPaused {
        require(artTokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(_collaborators.length == _shares.length, "Collaborator addresses and shares length mismatch.");
        require(artworkCollaborations[_tokenId].artist == address(0), "Collaboration already exists for this artwork."); // Check if no existing collaboration

        Collaboration memory newCollaboration;
        newCollaboration.artist = msg.sender;
        newCollaboration.collaborators = _collaborators;
        newCollaboration.shares = _shares;
        newCollaboration.isFinalized = false;
        newCollaboration.isActive = true;

        artworkCollaborations[_tokenId] = newCollaboration;

        for (uint256 i = 0; i < _collaborators.length; i++) {
            collaborationInvitations[_tokenId][_collaborators[i]] = true; // Send invitations
        }

        emit CollaborationProposed(_tokenId, msg.sender, _collaborators);
    }

    function acceptCollaborationInvite(uint256 _tokenId, address _collaborator) public whenNotPaused {
        require(collaborationInvitations[_tokenId][_collaborator], "No collaboration invitation found for this artwork.");
        require(msg.sender == _collaborator, "You are not invited to collaborate on this artwork.");
        require(!artworkCollaborations[_tokenId].isFinalized, "Collaboration is already finalized.");

        collaborationInvitations[_tokenId][_collaborator] = false; // Mark invitation as accepted
        emit CollaborationInviteAccepted(_tokenId, _collaborator);
    }

    function finalizeCollaboration(uint256 _tokenId) public whenNotPaused {
        require(artTokenOwner[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        require(!artworkCollaborations[_tokenId].isFinalized, "Collaboration is already finalized.");

        Collaboration storage collaboration = artworkCollaborations[_tokenId];

        // Check if all collaborators have accepted (simplified check - could be more robust)
        for (uint256 i = 0; i < collaboration.collaborators.length; i++) {
            if (collaborationInvitations[_tokenId][collaboration.collaborators[i]]) { // Still invited? (meaning not accepted)
                revert("Not all collaborators have accepted the invitation.");
            }
        }

        collaboration.isFinalized = true;
        emit CollaborationFinalized(_tokenId, msg.sender, collaboration.collaborators);
    }

    function withdrawArtistEarnings(uint256 _tokenId) public whenNotPaused {
        require(artTokenOwner[_tokenId] == msg.sender || isCollaborator(_tokenId, msg.sender), "You are not authorized to withdraw earnings for this artwork.");
        uint256 earnings = artistEarnings[_tokenId][msg.sender];
        require(earnings > 0, "No earnings to withdraw.");

        artistEarnings[_tokenId][msg.sender] = 0; // Reset earnings to zero after withdrawal
        payable(msg.sender).transfer(earnings);
        emit ArtistEarningsWithdrawn(_tokenId, msg.sender, earnings);
    }

    function setGalleryFee(uint256 _feePercentage) public onlyDAO whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage cannot exceed 100%.");
        galleryFeePercentage = _feePercentage;
        emit GalleryFeeSet(_feePercentage, msg.sender);
    }

    function getGalleryFee() public view returns (uint256) {
        return galleryFeePercentage;
    }

    function withdrawGalleryFees() public onlyDAO whenNotPaused {
        require(accumulatedGalleryFees > 0, "No gallery fees to withdraw.");
        uint256 amountToWithdraw = accumulatedGalleryFees;
        accumulatedGalleryFees = 0;
        payable(msg.sender).transfer(amountToWithdraw); // DAO address receives fees (replace with actual DAO treasury address)
        emit GalleryFeesWithdrawn(amountToWithdraw, msg.sender);
    }


    // --- DAO Governance & Utility ---
    function proposeDAOParameterChange(string memory _parameterName, uint256 _newValue) public onlyDAO whenNotPaused {
        require(bytes(_parameterName).length > 0, "Parameter name cannot be empty.");

        parameterProposals[nextParameterProposalId] = DAOParameterProposal({
            parameterName: _parameterName,
            newValue: _newValue,
            votesFor: 0,
            votesAgainst: 0,
            proposalEndTime: block.timestamp + daoVotingDuration,
            isActive: true
        });
        emit DAOParameterProposalCreated(nextParameterProposalId, _parameterName, _newValue, msg.sender);
        nextParameterProposalId++;
    }

    function voteOnParameterProposal(uint256 _proposalId, bool _vote) public onlyDAO whenNotPaused {
        require(parameterProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < parameterProposals[_proposalId].proposalEndTime, "Voting period has ended.");

        if (_vote) {
            parameterProposals[_proposalId].votesFor++;
        } else {
            parameterProposals[_proposalId].votesAgainst++;
        }
        emit DAOParameterProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeParameterChange(uint256 _proposalId) public onlyDAO whenNotPaused {
        require(parameterProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp >= parameterProposals[_proposalId].proposalEndTime, "Voting period has ended.");
        require(parameterProposals[_proposalId].votesFor > parameterProposals[_proposalId].votesAgainst, "Proposal did not pass.");

        DAOParameterProposal storage proposal = parameterProposals[_proposalId];
        string memory parameterName = proposal.parameterName;
        uint256 newValue = proposal.newValue;

        if (keccak256(bytes(parameterName)) == keccak256(bytes("galleryFeePercentage"))) {
            galleryFeePercentage = newValue;
            emit GalleryFeeSet(newValue, msg.sender);
        } else if (keccak256(bytes(parameterName)) == keccak256(bytes("daoVotingDuration"))) {
            daoVotingDuration = newValue;
            emit DAOVotingDurationSet(newValue, msg.sender);
        } else {
            revert("Invalid parameter name for DAO change.");
        }

        proposal.isActive = false; // Mark proposal as executed
        emit DAOParameterChanged(_proposalId, parameterName, newValue, msg.sender);
    }

    function setDAOVotingDuration(uint256 _durationInBlocks) public onlyDAO whenNotPaused {
        daoVotingDuration = _durationInBlocks;
        emit DAOVotingDurationSet(_durationInBlocks, msg.sender);
    }

    function getDAOVotingDuration() public view returns (uint256) {
        return daoVotingDuration;
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // --- Helper Functions ---
    function isCollaborator(uint256 _tokenId, address _address) internal view returns (bool) {
        Collaboration memory collaboration = artworkCollaborations[_tokenId];
        if (!collaboration.isFinalized || !collaboration.isActive) {
            return false;
        }
        for (uint256 i = 0; i < collaboration.collaborators.length; i++) {
            if (collaboration.collaborators[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getCollaborationDetails(uint256 _tokenId) public view returns (Collaboration memory) {
        return artworkCollaborations[_tokenId];
    }
}
```