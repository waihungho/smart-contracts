```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Art Gallery - "Chameleon Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art gallery where art pieces are dynamic NFTs,
 *      capable of evolving based on various on-chain events and interactions.
 *      This gallery introduces the concept of "Chameleon Art" - art that changes over time.
 *
 * Function Summary:
 *
 * 1.  setGalleryName(string _name): Allows the contract owner to set the name of the gallery.
 * 2.  setGalleryDescription(string _description): Allows the contract owner to set the gallery description.
 * 3.  mintArtPiece(string _title, string _initialDescription, string _initialDataURI, DynamicProperty[] _dynamicProperties): Artists can mint new dynamic art pieces.
 * 4.  setArtPieceDynamicProperties(uint256 _artPieceId, DynamicProperty[] _dynamicProperties): Allows the artist to update the dynamic properties of their art piece.
 * 5.  triggerDynamicUpdate(uint256 _artPieceId): Manually triggers a dynamic update for a specific art piece.
 * 6.  viewArtPieceDynamicState(uint256 _artPieceId): Allows anyone to view the current dynamic state of an art piece.
 * 7.  transferArtPiece(address _to, uint256 _artPieceId): Allows the owner of an art piece to transfer it.
 * 8.  listArtPieceForSale(uint256 _artPieceId, uint256 _price): Allows the owner to list their art piece for sale in the gallery.
 * 9.  buyArtPiece(uint256 _artPieceId): Allows anyone to buy a listed art piece.
 * 10. cancelArtPieceSale(uint256 _artPieceId): Allows the owner to cancel the sale of their art piece.
 * 11. setCurator(address _curator): Allows the contract owner to set a curator for the gallery.
 * 12. removeCurator(): Allows the contract owner to remove the curator.
 * 13. proposeExhibition(string _exhibitionName, uint256[] _artPieceIds): Allows the curator to propose a new exhibition.
 * 14. voteOnExhibitionProposal(uint256 _proposalId, bool _vote): Allows art piece owners to vote on exhibition proposals.
 * 15. finalizeExhibition(uint256 _proposalId): Allows the curator to finalize an exhibition proposal after voting.
 * 16. getExhibitionDetails(uint256 _exhibitionId): Allows anyone to get details of an exhibition.
 * 17. withdrawGalleryFunds(): Allows the contract owner to withdraw funds collected from sales.
 * 18. setRoyaltyPercentage(uint256 _percentage): Allows the contract owner to set a royalty percentage for secondary sales.
 * 19. getArtPieceOwner(uint256 _artPieceId): Returns the current owner of a specific art piece.
 * 20. getGalleryBalance(): Returns the current balance of the gallery contract.
 * 21. supportsInterface(bytes4 interfaceId): Standard ERC721 interface support.
 */

contract ChameleonCanvas {
    string public galleryName;
    string public galleryDescription;
    address public owner;
    address public curator;
    uint256 public artPieceCounter;
    uint256 public royaltyPercentage; // Percentage of secondary sale to artist
    uint256 public exhibitionProposalCounter;
    uint256 public exhibitionCounter;

    struct ArtPiece {
        uint256 id;
        string title;
        string description;
        string initialDataURI;
        address artist;
        uint256 creationTimestamp;
        DynamicProperty[] dynamicProperties;
        string currentDataURI; // Dynamically updated URI
        bool isForSale;
        uint256 salePrice;
    }

    struct DynamicProperty {
        DynamicType propertyType;
        uint256 updateInterval; // Time interval for automatic updates (e.g., seconds)
        uint256 lastUpdatedTimestamp;
        uint256 parameter1; // Example parameter (can be used differently based on propertyType)
        uint256 parameter2; // Example parameter
    }

    enum DynamicType {
        NONE,
        TIME_BASED_COLOR_SHIFT,
        INTERACTION_COUNT_MORPH,
        RANDOM_ELEMENT_GENERATION,
        BLOCK_HASH_DEPENDENT_TEXTURE
    }

    struct ExhibitionProposal {
        uint256 id;
        string name;
        address curator;
        uint256[] artPieceIds;
        mapping(address => bool) votes; // Art piece owner's vote
        uint256 voteCount;
        bool finalized;
    }

    struct Exhibition {
        uint256 id;
        string name;
        address curator;
        uint256[] artPieceIds;
        uint256 startTime;
    }

    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => address) public artPieceToOwner;
    mapping(address => uint256[]) public artistArtPieces;
    mapping(uint256 => bool) public isArtPieceListedForSale;

    event GalleryNameUpdated(string newName);
    event GalleryDescriptionUpdated(string newDescription);
    event ArtPieceMinted(uint256 artPieceId, address artist, string title);
    event DynamicPropertiesUpdated(uint256 artPieceId);
    event DynamicUpdateTriggered(uint256 artPieceId, string newDataURI);
    event ArtPieceTransferred(uint256 artPieceId, address from, address to);
    event ArtPieceListedForSale(uint256 artPieceId, uint256 price);
    event ArtPieceSold(uint256 artPieceId, address buyer, address artist, uint256 price);
    event ArtPieceSaleCancelled(uint256 artPieceId);
    event CuratorSet(address curatorAddress);
    event CuratorRemoved();
    event ExhibitionProposed(uint256 proposalId, string name, address curator, uint256[] artPieceIds);
    event ExhibitionVoteCast(uint256 proposalId, address voter, bool vote);
    event ExhibitionFinalized(uint256 exhibitionId, uint256 proposalId);
    event GalleryFundsWithdrawn(address owner, uint256 amount);
    event RoyaltyPercentageUpdated(uint256 percentage);

    constructor(string memory _galleryName, string memory _galleryDescription) {
        owner = msg.sender;
        galleryName = _galleryName;
        galleryDescription = _galleryDescription;
        artPieceCounter = 0;
        royaltyPercentage = 5; // Default 5% royalty
        exhibitionProposalCounter = 0;
        exhibitionCounter = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(msg.sender == curator, "Only curator can call this function.");
        _;
    }

    modifier onlyArtPieceOwner(uint256 _artPieceId) {
        require(artPieceToOwner[_artPieceId] == msg.sender, "You are not the owner of this art piece.");
        _;
    }

    modifier artPieceExists(uint256 _artPieceId) {
        require(artPieces[_artPieceId].id != 0, "Art piece does not exist.");
        _;
    }

    modifier artPieceNotForSale(uint256 _artPieceId) {
        require(!isArtPieceListedForSale[_artPieceId], "Art piece is already listed for sale.");
        _;
    }

    modifier artPieceIsForSale(uint256 _artPieceId) {
        require(isArtPieceListedForSale[_artPieceId], "Art piece is not listed for sale.");
        _;
    }

    modifier validRoyaltyPercentage(uint256 _percentage) {
        require(_percentage <= 100, "Royalty percentage must be less than or equal to 100.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(exhibitionProposals[_proposalId].id != 0, "Exhibition proposal does not exist.");
        _;
    }

    modifier proposalNotFinalized(uint256 _proposalId) {
        require(!exhibitionProposals[_proposalId].finalized, "Exhibition proposal is already finalized.");
        _;
    }

    modifier exhibitionExists(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].id != 0, "Exhibition does not exist.");
        _;
    }


    // 1. Set Gallery Name
    function setGalleryName(string memory _name) public onlyOwner {
        galleryName = _name;
        emit GalleryNameUpdated(_name);
    }

    // 2. Set Gallery Description
    function setGalleryDescription(string memory _description) public onlyOwner {
        galleryDescription = _description;
        emit GalleryDescriptionUpdated(_description);
    }

    // 3. Mint Art Piece
    function mintArtPiece(
        string memory _title,
        string memory _initialDescription,
        string memory _initialDataURI,
        DynamicProperty[] memory _dynamicProperties
    ) public {
        artPieceCounter++;
        ArtPiece storage newArtPiece = artPieces[artPieceCounter];
        newArtPiece.id = artPieceCounter;
        newArtPiece.title = _title;
        newArtPiece.description = _initialDescription;
        newArtPiece.initialDataURI = _initialDataURI;
        newArtPiece.artist = msg.sender;
        newArtPiece.creationTimestamp = block.timestamp;
        newArtPiece.dynamicProperties = _dynamicProperties;
        newArtPiece.currentDataURI = _initialDataURI; // Initially same as initial URI
        artPieceToOwner[artPieceCounter] = msg.sender;
        artistArtPieces[msg.sender].push(artPieceCounter);

        emit ArtPieceMinted(artPieceCounter, msg.sender, _title);
    }

    // 4. Set Art Piece Dynamic Properties
    function setArtPieceDynamicProperties(uint256 _artPieceId, DynamicProperty[] memory _dynamicProperties)
        public
        onlyArtPieceOwner(_artPieceId)
        artPieceExists(_artPieceId)
    {
        artPieces[_artPieceId].dynamicProperties = _dynamicProperties;
        emit DynamicPropertiesUpdated(_artPieceId);
    }

    // 5. Trigger Dynamic Update
    function triggerDynamicUpdate(uint256 _artPieceId) public artPieceExists(_artPieceId) {
        ArtPiece storage piece = artPieces[_artPieceId];
        string memory newDataURI = _applyDynamicUpdates(_artPieceId);
        piece.currentDataURI = newDataURI;
        emit DynamicUpdateTriggered(_artPieceId, newDataURI);
    }

    // 6. View Art Piece Dynamic State (returns currentDataURI for simplicity, can be extended)
    function viewArtPieceDynamicState(uint256 _artPieceId) public view artPieceExists(_artPieceId) returns (string memory) {
        return artPieces[_artPieceId].currentDataURI;
    }

    // 7. Transfer Art Piece
    function transferArtPiece(address _to, uint256 _artPieceId) public onlyArtPieceOwner(_artPieceId) artPieceExists(_artPieceId) {
        address from = msg.sender;
        artPieceToOwner[_artPieceId] = _to;
        isArtPieceListedForSale[_artPieceId] = false; // Cancel sale if transferred
        emit ArtPieceTransferred(_artPieceId, from, _to);
    }

    // 8. List Art Piece For Sale
    function listArtPieceForSale(uint256 _artPieceId, uint256 _price)
        public
        onlyArtPieceOwner(_artPieceId)
        artPieceExists(_artPieceId)
        artPieceNotForSale(_artPieceId)
    {
        ArtPiece storage piece = artPieces[_artPieceId];
        piece.isForSale = true;
        piece.salePrice = _price;
        isArtPieceListedForSale[_artPieceId] = true;
        emit ArtPieceListedForSale(_artPieceId, _price);
    }

    // 9. Buy Art Piece
    function buyArtPiece(uint256 _artPieceId) public payable artPieceExists(_artPieceId) artPieceIsForSale(_artPieceId) {
        ArtPiece storage piece = artPieces[_artPieceId];
        require(msg.value >= piece.salePrice, "Insufficient funds.");

        address artist = piece.artist;
        address seller = artPieceToOwner[_artPieceId];
        uint256 salePrice = piece.salePrice;

        // Transfer funds (with royalty to artist)
        uint256 royaltyAmount = (salePrice * royaltyPercentage) / 100;
        uint256 artistPayment = royaltyAmount;
        uint256 sellerPayment = salePrice - royaltyAmount;

        // Pay artist royalty
        payable(artist).transfer(artistPayment);
        // Pay seller
        payable(seller).transfer(sellerPayment);

        // Update ownership
        artPieceToOwner[_artPieceId] = msg.sender;
        piece.isForSale = false;
        piece.salePrice = 0;
        isArtPieceListedForSale[_artPieceId] = false;

        emit ArtPieceSold(_artPieceId, msg.sender, artist, salePrice);

        // Trigger dynamic update on sale (interaction based example)
        _applyDynamicUpdates(_artPieceId); // Can be expanded to interaction-specific updates
        emit DynamicUpdateTriggered(_artPieceId, piece.currentDataURI); // Re-emit after sale-based update
    }

    // 10. Cancel Art Piece Sale
    function cancelArtPieceSale(uint256 _artPieceId)
        public
        onlyArtPieceOwner(_artPieceId)
        artPieceExists(_artPieceId)
        artPieceIsForSale(_artPieceId)
    {
        ArtPiece storage piece = artPieces[_artPieceId];
        piece.isForSale = false;
        piece.salePrice = 0;
        isArtPieceListedForSale[_artPieceId] = false;
        emit ArtPieceSaleCancelled(_artPieceId);
    }

    // 11. Set Curator
    function setCurator(address _curator) public onlyOwner {
        curator = _curator;
        emit CuratorSet(_curator);
    }

    // 12. Remove Curator
    function removeCurator() public onlyOwner {
        curator = address(0); // Set curator to address 0
        emit CuratorRemoved();
    }

    // 13. Propose Exhibition
    function proposeExhibition(string memory _exhibitionName, uint256[] memory _artPieceIds) public onlyCurator {
        exhibitionProposalCounter++;
        ExhibitionProposal storage newProposal = exhibitionProposals[exhibitionProposalCounter];
        newProposal.id = exhibitionProposalCounter;
        newProposal.name = _exhibitionName;
        newProposal.curator = msg.sender;
        newProposal.artPieceIds = _artPieceIds;
        emit ExhibitionProposed(exhibitionProposalCounter, _exhibitionName, msg.sender, _artPieceIds);
    }

    // 14. Vote on Exhibition Proposal
    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote)
        public
        proposalExists(_proposalId)
        proposalNotFinalized(_proposalId)
    {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(!proposal.votes[msg.sender], "You have already voted on this proposal.");

        bool isOwnerOfArtPiece = false;
        for (uint256 i = 0; i < proposal.artPieceIds.length; i++) {
            if (artPieceToOwner[proposal.artPieceIds[i]] == msg.sender) {
                isOwnerOfArtPiece = true;
                break;
            }
        }
        require(isOwnerOfArtPiece, "You must own an art piece in this proposal to vote.");

        proposal.votes[msg.sender] = true;
        if (_vote) {
            proposal.voteCount++;
        }
        emit ExhibitionVoteCast(_proposalId, msg.sender, _vote);
    }

    // 15. Finalize Exhibition
    function finalizeExhibition(uint256 _proposalId) public onlyCurator proposalExists(_proposalId) proposalNotFinalized(_proposalId) {
        ExhibitionProposal storage proposal = exhibitionProposals[_proposalId];
        require(proposal.voteCount > (proposal.artPieceIds.length / 2), "Proposal does not have enough votes to finalize."); // Simple majority
        proposal.finalized = true;

        exhibitionCounter++;
        Exhibition storage newExhibition = exhibitions[exhibitionCounter];
        newExhibition.id = exhibitionCounter;
        newExhibition.name = proposal.name;
        newExhibition.curator = proposal.curator;
        newExhibition.artPieceIds = proposal.artPieceIds;
        newExhibition.startTime = block.timestamp;

        emit ExhibitionFinalized(exhibitionCounter, _proposalId);
    }

    // 16. Get Exhibition Details
    function getExhibitionDetails(uint256 _exhibitionId) public view exhibitionExists(_exhibitionId) returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    // 17. Withdraw Gallery Funds
    function withdrawGalleryFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit GalleryFundsWithdrawn(owner, balance);
    }

    // 18. Set Royalty Percentage
    function setRoyaltyPercentage(uint256 _percentage) public onlyOwner validRoyaltyPercentage(_percentage) {
        royaltyPercentage = _percentage;
        emit RoyaltyPercentageUpdated(_percentage);
    }

    // 19. Get Art Piece Owner
    function getArtPieceOwner(uint256 _artPieceId) public view artPieceExists(_artPieceId) returns (address) {
        return artPieceToOwner[_artPieceId];
    }

    // 20. Get Gallery Balance
    function getGalleryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 21. supportsInterface (ERC721 - minimal, extend as needed)
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x80ac58cd; // ERC721 interface ID
    }

    // -------------------- Internal Dynamic Update Logic --------------------
    function _applyDynamicUpdates(uint256 _artPieceId) internal returns (string memory newDataURI) {
        ArtPiece storage piece = artPieces[_artPieceId];
        newDataURI = piece.currentDataURI; // Start with current URI

        for (uint256 i = 0; i < piece.dynamicProperties.length; i++) {
            DynamicProperty storage prop = piece.dynamicProperties[i];

            if (prop.propertyType == DynamicType.TIME_BASED_COLOR_SHIFT) {
                if (block.timestamp >= prop.lastUpdatedTimestamp + prop.updateInterval) {
                    newDataURI = _applyTimeBasedColorShift(piece.initialDataURI, prop.parameter1, prop.parameter2); // Example parameters for color shift
                    prop.lastUpdatedTimestamp = block.timestamp;
                }
            } else if (prop.propertyType == DynamicType.INTERACTION_COUNT_MORPH) {
                // Example: Morph based on interaction count (e.g., sales count - simplified for on-chain example)
                uint256 interactionCount = _getSimplifiedInteractionCount(_artPieceId); // Replace with real interaction tracking if needed
                newDataURI = _applyInteractionCountMorph(piece.initialDataURI, interactionCount, prop.parameter1); // Example parameter for morph intensity
            } else if (prop.propertyType == DynamicType.RANDOM_ELEMENT_GENERATION) {
                if (block.timestamp >= prop.lastUpdatedTimestamp + prop.updateInterval) {
                    newDataURI = _applyRandomElementGeneration(piece.initialDataURI, prop.parameter1); // Example parameter for element complexity
                    prop.lastUpdatedTimestamp = block.timestamp;
                }
            } else if (prop.propertyType == DynamicType.BLOCK_HASH_DEPENDENT_TEXTURE) {
                newDataURI = _applyBlockHashDependentTexture(piece.initialDataURI, blockhash(block.number - 1)); // Use previous block hash for determinism
            }
            // Add more dynamic types here as needed
        }
        return newDataURI;
    }

    // --- Example Dynamic Effect Implementations (Simplified - for demonstration) ---

    function _applyTimeBasedColorShift(string memory _baseURI, uint256 _colorShiftValue, uint256 _timeFactor) internal pure returns (string memory) {
        // In a real application, this would involve more complex logic to modify the dataURI
        // For simplicity, we'll just append a timestamp-based value to the URI.
        // In a real-world dynamic NFT, you might use off-chain rendering services or IPFS
        // and update metadata based on the dynamic properties.
        uint256 shiftedValue = block.timestamp / _timeFactor * _colorShiftValue;
        return string(abi.encodePacked(_baseURI, "?colorShift=", uint2str(shiftedValue)));
    }

    function _applyInteractionCountMorph(string memory _baseURI, uint256 _interactionCount, uint256 _morphIntensity) internal pure returns (string memory) {
        // Simplified morph based on interaction count
        uint256 morphValue = _interactionCount * _morphIntensity;
        return string(abi.encodePacked(_baseURI, "?morph=", uint2str(morphValue)));
    }

    function _applyRandomElementGeneration(string memory _baseURI, uint256 _complexity) internal pure returns (string memory) {
        // Simplified random element generation
        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _complexity)));
        return string(abi.encodePacked(_baseURI, "?randomElement=", uint2str(randomValue)));
    }

    function _applyBlockHashDependentTexture(string memory _baseURI, bytes32 _blockHash) internal pure returns (string memory) {
        // Simplified block hash texture
        uint256 hashValue = uint256(_blockHash);
        return string(abi.encodePacked(_baseURI, "?blockHashTexture=", uint2str(hashValue)));
    }

    // --- Simplified Interaction Count (Replace with actual tracking if needed) ---
    function _getSimplifiedInteractionCount(uint256 _artPieceId) internal view returns (uint256) {
        // For demonstration, we'll just use a very basic "interaction" - number of transfers.
        // In a real application, you'd track views, likes, sales, etc., potentially off-chain and bring it on-chain.
        uint256 transferCount = 0; // In a real system, you would track transfer events or use a counter.
        // This is a placeholder for a more complex interaction tracking mechanism.
        return transferCount;
    }

    // --- Utility function to convert uint to string ---
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
```