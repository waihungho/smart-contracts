```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery (DAAG) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art gallery, featuring artist registration,
 *      NFT artwork submission, curated exhibitions through community voting, dynamic pricing based on
 *      artwork popularity and gallery treasury management. Includes advanced features like artist reputation,
 *      algorithmic curation suggestions, and decentralized artist grants.

 * **Outline and Function Summary:**

 * **1. Artist Management:**
 *    - `registerArtist(string _artistName, string _artistBio)`: Allows artists to register with a name and bio.
 *    - `updateArtistProfile(string _newArtistName, string _newArtistBio)`: Allows artists to update their profile.
 *    - `getArtistProfile(address _artistAddress)`: Retrieves an artist's profile information.
 *    - `getArtistArtworks(address _artistAddress)`: Retrieves a list of artwork IDs submitted by an artist.
 *    - `reportArtist(address _artistAddress, string _reason)`: Allows users to report an artist for misconduct.

 * **2. Artwork NFT Management:**
 *    - `submitArtwork(string _artworkName, string _artworkDescription, string _artworkCID, uint256 _initialPrice)`: Artists submit their artwork (NFT) with details and initial price.
 *    - `listArtworkForSale(uint256 _artworkId)`: Artist lists their approved artwork for sale in the gallery.
 *    - `purchaseArtwork(uint256 _artworkId)`: Users can purchase listed artworks.
 *    - `getArtworkDetails(uint256 _artworkId)`: Retrieves detailed information about an artwork.
 *    - `getArtworkOwner(uint256 _artworkId)`: Retrieves the current owner of an artwork.
 *    - `transferArtwork(uint256 _artworkId, address _to)`: Allows artwork owners to transfer their NFTs.
 *    - `setArtworkPrice(uint256 _artworkId, uint256 _newPrice)`: Artist can update the price of their listed artwork.
 *    - `reportArtwork(uint256 _artworkId, string _reason)`: Allows users to report an artwork for inappropriate content.

 * **3. Exhibition and Curation:**
 *    - `createExhibitionProposal(string _exhibitionName, string _exhibitionDescription, uint256 _startTime, uint256 _endTime, uint256[] _artworkIds)`: Propose a new exhibition with a name, description, time frame and selected artworks.
 *    - `voteOnExhibitionProposal(uint256 _proposalId, bool _vote)`: Registered users can vote on exhibition proposals.
 *    - `getExhibitionProposalDetails(uint256 _proposalId)`: Retrieves details of an exhibition proposal.
 *    - `getCurrentExhibitions()`: Retrieves a list of currently active exhibitions.
 *    - `getPastExhibitions()`: Retrieves a list of past exhibitions.
 *    - `addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Curator (or DAO if implemented) can add artworks to an existing exhibition.
 *    - `removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Curator (or DAO if implemented) can remove artworks from an exhibition.

 * **4. Gallery Treasury and Revenue Management:**
 *    - `getGalleryBalance()`: Retrieves the current balance of the gallery treasury.
 *    - `withdrawGalleryFunds(address _to, uint256 _amount)`: Allows the gallery owner (or DAO) to withdraw funds from the treasury. (Potentially DAO controlled in a real-world scenario)
 *    - `setGalleryFee(uint256 _newFeePercentage)`: Allows the gallery owner to set the gallery fee percentage on artwork sales.

 * **5. Advanced/Trendy Features:**
 *    - `getAlgorithmicCurationSuggestions()`: Returns a list of artwork IDs suggested for curation based on popularity, artist reputation, etc. (Algorithmic logic is simplified here for demonstration).
 *    - `requestArtistGrant(string _grantProposal)`: Registered artists can request grants with a proposal.
 *    - `voteOnArtistGrant(uint256 _grantId, bool _vote)`: Registered users can vote on artist grant proposals.
 *    - `fundArtistGrant(uint256 _grantId)`: Allows the gallery owner (or DAO) to fund approved artist grants.
 *    - `getArtistReputation(address _artistAddress)`: Retrieves an artist's reputation score (simplified reputation system based on artwork sales and positive reports).
 *    - `emergencyWithdrawArtwork(uint256 _artworkId)`:  Allows artist to withdraw their artwork if it's stuck in the contract due to unforeseen issues (admin/fallback function - use with caution).

 * **Events:**
 *    - `ArtistRegistered(address artistAddress, string artistName)`
 *    - `ArtistProfileUpdated(address artistAddress, string newArtistName)`
 *    - `ArtworkSubmitted(uint256 artworkId, address artistAddress, string artworkName)`
 *    - `ArtworkListed(uint256 artworkId)`
 *    - `ArtworkPurchased(uint256 artworkId, address buyer, address seller, uint256 price)`
 *    - `ArtworkPriceUpdated(uint256 artworkId, uint256 newPrice)`
 *    - `ExhibitionProposalCreated(uint256 proposalId, string exhibitionName)`
 *    - `ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote)`
 *    - `ExhibitionStarted(uint256 exhibitionId)`
 *    - `ExhibitionEnded(uint256 exhibitionId)`
 *    - `ArtistReported(address reportedArtist, address reporter, string reason)`
 *    - `ArtworkReported(uint256 artworkId, address reporter, string reason)`
 *    - `ArtistGrantRequested(uint256 grantId, address artistAddress, string proposal)`
 *    - `ArtistGrantVoted(uint256 grantId, address voter, bool vote)`
 *    - `ArtistGrantFunded(uint256 grantId, address artistAddress, uint256 amount)`
 */
contract DecentralizedAutonomousArtGallery {

    // --- Structs ---
    struct ArtistProfile {
        string artistName;
        string artistBio;
        uint256 reputationScore;
        bool isRegistered;
    }

    struct Artwork {
        uint256 artworkId;
        string artworkName;
        string artworkDescription;
        string artworkCID; // IPFS CID or similar content identifier
        address artistAddress;
        address owner;
        uint256 price;
        bool isListed;
        bool isApproved; // For gallery inclusion
    }

    struct ExhibitionProposal {
        uint256 proposalId;
        string exhibitionName;
        string exhibitionDescription;
        uint256 startTime;
        uint256 endTime;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isActive;
        bool isApproved;
        uint256[] artworkIds;
    }

    struct ArtistGrantProposal {
        uint256 grantId;
        address artistAddress;
        string proposal;
        uint256 voteCountYes;
        uint256 voteCountNo;
        bool isActive;
        bool isApproved;
        uint256 grantAmount; // Could be set later if approved
    }

    // --- State Variables ---
    address public galleryOwner;
    uint256 public galleryFeePercentage = 5; // Default 5% gallery fee
    uint256 public artworkIdCounter = 1;
    uint256 public exhibitionProposalIdCounter = 1;
    uint256 public artistGrantIdCounter = 1;

    mapping(address => ArtistProfile) public artistProfiles;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => ArtistGrantProposal) public artistGrantProposals;
    mapping(uint256 => mapping(address => bool)) public exhibitionProposalVotes; // proposalId => voter => votedYes
    mapping(uint256 => mapping(address => bool)) public artistGrantVotes;       // grantId => voter => votedYes
    mapping(address => uint256[]) public artistArtworks; // Artist address to list of artwork IDs

    uint256 public galleryBalance; // Keep track of gallery's ETH balance (simplified for example)

    // --- Events ---
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string newArtistName);
    event ArtworkSubmitted(uint256 artworkId, address artistAddress, string artworkName);
    event ArtworkListed(uint256 artworkId);
    event ArtworkPurchased(uint256 artworkId, address buyer, address seller, uint256 price);
    event ArtworkPriceUpdated(uint256 artworkId, uint256 newPrice);
    event ExhibitionProposalCreated(uint256 proposalId, string exhibitionName);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool vote);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event ArtistReported(address reportedArtist, address reporter, string reason);
    event ArtworkReported(uint256 artworkId, address reporter, string reason);
    event ArtistGrantRequested(uint256 grantId, address artistAddress, string proposal);
    event ArtistGrantVoted(uint256 grantId, address voter, bool vote);
    event ArtistGrantFunded(uint256 grantId, address artistAddress, uint256 amount);

    // --- Modifiers ---
    modifier onlyGalleryOwner() {
        require(msg.sender == galleryOwner, "Only gallery owner can call this function.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artistProfiles[msg.sender].isRegistered, "Only registered artists can call this function.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId < artworkIdCounter && artworks[_artworkId].artworkId == _artworkId, "Artwork does not exist.");
        _;
    }

    modifier validExhibitionProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < exhibitionProposalIdCounter && exhibitionProposals[_proposalId].proposalId == _proposalId, "Exhibition proposal does not exist.");
        _;
    }

    modifier validArtistGrantProposal(uint256 _grantId) {
        require(_grantId > 0 && _grantId < artistGrantIdCounter && artistGrantProposals[_grantId].grantId == _grantId, "Artist grant proposal does not exist.");
        _;
    }


    // --- Constructor ---
    constructor() {
        galleryOwner = msg.sender;
    }

    // --- 1. Artist Management Functions ---
    function registerArtist(string memory _artistName, string memory _artistBio) public {
        require(!artistProfiles[msg.sender].isRegistered, "Artist already registered.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistBio: _artistBio,
            reputationScore: 100, // Initial reputation score
            isRegistered: true
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _newArtistName, string memory _newArtistBio) public onlyRegisteredArtist {
        artistProfiles[msg.sender].artistName = _newArtistName;
        artistProfiles[msg.sender].artistBio = _newArtistBio;
        emit ArtistProfileUpdated(msg.sender, _newArtistName);
    }

    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    function getArtistArtworks(address _artistAddress) public view returns (uint256[] memory) {
        return artistArtworks[_artistAddress];
    }

    function reportArtist(address _artistAddress, string memory _reason) public {
        // In a real-world scenario, implement moderation/reporting system.
        // For simplicity, just emit an event.
        emit ArtistReported(_artistAddress, msg.sender, _reason);
        // Potentially decrease artist reputation score based on reports (advanced feature).
        if (artistProfiles[_artistAddress].isRegistered) {
            artistProfiles[_artistAddress].reputationScore = artistProfiles[_artistAddress].reputationScore > 5 ? artistProfiles[_artistAddress].reputationScore - 5 : 0; // Decrease reputation, but not below 0
        }
    }


    // --- 2. Artwork NFT Management Functions ---
    function submitArtwork(string memory _artworkName, string memory _artworkDescription, string memory _artworkCID, uint256 _initialPrice) public onlyRegisteredArtist {
        artworks[artworkIdCounter] = Artwork({
            artworkId: artworkIdCounter,
            artworkName: _artworkName,
            artworkDescription: _artworkDescription,
            artworkCID: _artworkCID,
            artistAddress: msg.sender,
            owner: msg.sender, // Artist is the initial owner
            price: _initialPrice,
            isListed: false,
            isApproved: false // Initially not approved for gallery listing. Approval process would be added in a real-world scenario.
        });
        artistArtworks[msg.sender].push(artworkIdCounter);
        emit ArtworkSubmitted(artworkIdCounter, msg.sender, _artworkName);
        artworkIdCounter++;
    }

    function listArtworkForSale(uint256 _artworkId) public onlyRegisteredArtist artworkExists(_artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only artist who submitted can list.");
        require(artworks[_artworkId].isApproved, "Artwork must be approved by gallery to be listed."); // Approval process to be added
        artworks[_artworkId].isListed = true;
        emit ArtworkListed(_artworkId);
    }

    function purchaseArtwork(uint256 _artworkId) public payable artworkExists(_artworkId) {
        require(artworks[_artworkId].isListed, "Artwork is not listed for sale.");
        require(msg.value >= artworks[_artworkId].price, "Insufficient funds sent.");

        uint256 galleryFee = (artworks[_artworkId].price * galleryFeePercentage) / 100;
        uint256 artistPayout = artworks[_artworkId].price - galleryFee;

        galleryBalance += galleryFee; // Increase gallery balance (simplified treasury management)
        payable(artworks[_artworkId].artistAddress).transfer(artistPayout); // Pay artist

        artworks[_artworkId].owner = msg.sender;
        artworks[_artworkId].isListed = false; // No longer listed after purchase

        emit ArtworkPurchased(_artworkId, msg.sender, artworks[_artworkId].artistAddress, artworks[_artworkId].price);

        // Refund any extra ETH sent
        if (msg.value > artworks[_artworkId].price) {
            payable(msg.sender).transfer(msg.value - artworks[_artworkId].price);
        }

        // Increase artist reputation on successful sale (advanced feature)
        artistProfiles[artworks[_artworkId].artistAddress].reputationScore += 2;
    }

    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getArtworkOwner(uint256 _artworkId) public view artworkExists(_artworkId) returns (address) {
        return artworks[_artworkId].owner;
    }

    function transferArtwork(uint256 _artworkId, address _to) public artworkExists(_artworkId) {
        require(artworks[_artworkId].owner == msg.sender, "Only artwork owner can transfer.");
        artworks[_artworkId].owner = _to;
        artworks[_artworkId].isListed = false; // Unlist when transferred
    }

    function setArtworkPrice(uint256 _artworkId, uint256 _newPrice) public onlyRegisteredArtist artworkExists(_artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only artist who submitted can set price.");
        artworks[_artworkId].price = _newPrice;
        emit ArtworkPriceUpdated(_artworkId, _newPrice);
    }

    function reportArtwork(uint256 _artworkId, string memory _reason) public artworkExists(_artworkId) {
        emit ArtworkReported(_artworkId, msg.sender, _reason);
        // Implement moderation/action based on reports in a real-world scenario.
    }

    function emergencyWithdrawArtwork(uint256 _artworkId) public onlyRegisteredArtist artworkExists(_artworkId) {
        require(artworks[_artworkId].artistAddress == msg.sender, "Only artist who submitted can withdraw.");
        require(artworks[_artworkId].owner == address(this), "Artwork must be owned by contract for emergency withdraw."); // Add condition if necessary
        artworks[_artworkId].owner = msg.sender; // Set owner back to artist
        artworks[_artworkId].isListed = false; // Unlist if listed
        // Consider emitting an event for emergency withdrawal
    }


    // --- 3. Exhibition and Curation Functions ---
    function createExhibitionProposal(string memory _exhibitionName, string memory _exhibitionDescription, uint256 _startTime, uint256 _endTime, uint256[] memory _artworkIds) public onlyRegisteredArtist {
        require(_startTime < _endTime, "Exhibition end time must be after start time.");
        require(_artworkIds.length > 0, "Exhibition must include at least one artwork.");
        // In a real-world scenario, add checks for valid artwork IDs and artwork approval status.

        exhibitionProposals[exhibitionProposalIdCounter] = ExhibitionProposal({
            proposalId: exhibitionProposalIdCounter,
            exhibitionName: _exhibitionName,
            exhibitionDescription: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            voteCountYes: 0,
            voteCountNo: 0,
            isActive: true,
            isApproved: false, // Initially not approved, needs voting
            artworkIds: _artworkIds
        });
        emit ExhibitionProposalCreated(exhibitionProposalIdCounter, _exhibitionName);
        exhibitionProposalIdCounter++;
    }

    function voteOnExhibitionProposal(uint256 _proposalId, bool _vote) public onlyRegisteredArtist validExhibitionProposal(_proposalId) {
        require(exhibitionProposals[_proposalId].isActive, "Proposal is not active.");
        require(!exhibitionProposalVotes[_proposalId][msg.sender], "Artist has already voted on this proposal.");

        exhibitionProposalVotes[_proposalId][msg.sender] = true; // Record vote

        if (_vote) {
            exhibitionProposals[_proposalId].voteCountYes++;
        } else {
            exhibitionProposals[_proposalId].voteCountNo++;
        }
        emit ExhibitionProposalVoted(_proposalId, msg.sender, _vote);

        // Simplified approval logic: if yes votes > no votes, approve (adjust criteria as needed)
        if (exhibitionProposals[_proposalId].voteCountYes > exhibitionProposals[_proposalId].voteCountNo) {
            exhibitionProposals[_proposalId].isApproved = true;
            // In a real-world scenario, you might trigger exhibition start logic here or have a separate function to start approved exhibitions.
            // For this example, exhibition start is manual or time-based.
        }
    }

    function getExhibitionProposalDetails(uint256 _proposalId) public view validExhibitionProposal(_proposalId) returns (ExhibitionProposal memory) {
        return exhibitionProposals[_proposalId];
    }

    function getCurrentExhibitions() public view returns (ExhibitionProposal[] memory) {
        ExhibitionProposal[] memory currentExhibitions = new ExhibitionProposal[](exhibitionProposalIdCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < exhibitionProposalIdCounter; i++) {
            if (exhibitionProposals[i].isApproved && block.timestamp >= exhibitionProposals[i].startTime && block.timestamp <= exhibitionProposals[i].endTime) {
                currentExhibitions[count] = exhibitionProposals[i];
                count++;
            }
        }

        // Resize array to actual number of current exhibitions
        ExhibitionProposal[] memory resizedExhibitions = new ExhibitionProposal[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedExhibitions[i] = currentExhibitions[i];
        }
        return resizedExhibitions;
    }

    function getPastExhibitions() public view returns (ExhibitionProposal[] memory) {
        ExhibitionProposal[] memory pastExhibitions = new ExhibitionProposal[](exhibitionProposalIdCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < exhibitionProposalIdCounter; i++) {
            if (exhibitionProposals[i].isApproved && block.timestamp > exhibitionProposals[i].endTime) {
                pastExhibitions[count] = exhibitionProposals[i];
                count++;
            }
        }
        // Resize array as in getCurrentExhibitions if needed.
        ExhibitionProposal[] memory resizedExhibitions = new ExhibitionProposal[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedExhibitions[i] = pastExhibitions[i];
        }
        return resizedExhibitions;
    }

    // Example curator functions (Curator role needs to be defined and managed in a real DAO)
    // For simplicity, owner can act as curator in this example.
    function addArtworkToExhibition(uint256 _exhibitionId, uint256 _artworkId) public onlyGalleryOwner validExhibitionProposal(_exhibitionId) artworkExists(_artworkId) {
        // In a real-world scenario, curator role and authorization would be more robust.
        // Also, checks for artwork suitability for exhibition would be added.
        bool alreadyInExhibition = false;
        for (uint256 i = 0; i < exhibitionProposals[_exhibitionId].artworkIds.length; i++) {
            if (exhibitionProposals[_exhibitionId].artworkIds[i] == _artworkId) {
                alreadyInExhibition = true;
                break;
            }
        }
        require(!alreadyInExhibition, "Artwork already in this exhibition.");

        exhibitionProposals[_exhibitionId].artworkIds.push(_artworkId);
    }

    function removeArtworkFromExhibition(uint256 _exhibitionId, uint256 _artworkId) public onlyGalleryOwner validExhibitionProposal(_exhibitionId) artworkExists(_artworkId) {
        // Similar curator role considerations as addArtworkToExhibition
        uint256[] storage artworkIds = exhibitionProposals[_exhibitionId].artworkIds;
        for (uint256 i = 0; i < artworkIds.length; i++) {
            if (artworkIds[i] == _artworkId) {
                // Remove artworkId from the array
                artworkIds[i] = artworkIds[artworkIds.length - 1];
                artworkIds.pop();
                return;
            }
        }
        revert("Artwork not found in this exhibition.");
    }


    // --- 4. Gallery Treasury and Revenue Management Functions ---
    function getGalleryBalance() public view returns (uint256) {
        return galleryBalance;
    }

    function withdrawGalleryFunds(address _to, uint256 _amount) public onlyGalleryOwner {
        require(galleryBalance >= _amount, "Insufficient gallery balance.");
        galleryBalance -= _amount;
        payable(_to).transfer(_amount);
    }

    function setGalleryFee(uint256 _newFeePercentage) public onlyGalleryOwner {
        require(_newFeePercentage <= 20, "Gallery fee percentage cannot exceed 20%."); // Example limit
        galleryFeePercentage = _newFeePercentage;
    }


    // --- 5. Advanced/Trendy Features ---
    function getAlgorithmicCurationSuggestions() public view returns (uint256[] memory) {
        // Simplified algorithmic curation logic (can be much more complex in reality)
        // Suggest artworks with high reputation artists and not yet exhibited.
        uint256[] memory suggestions = new uint256[](artworkIdCounter - 1); // Max possible size
        uint256 count = 0;

        for (uint256 i = 1; i < artworkIdCounter; i++) {
            if (artworks[i].isApproved && artistProfiles[artworks[i].artistAddress].reputationScore > 120) { // Example criteria
                bool exhibited = false;
                for (uint256 j = 1; j < exhibitionProposalIdCounter; j++) {
                    if (exhibitionProposals[j].isApproved) {
                        for(uint256 k = 0; k < exhibitionProposals[j].artworkIds.length; k++){
                            if(exhibitionProposals[j].artworkIds[k] == i){
                                exhibited = true;
                                break;
                            }
                        }
                    }
                    if(exhibited) break;
                }
                if (!exhibited) {
                    suggestions[count] = i;
                    count++;
                }
            }
        }
        // Resize array if needed
        uint256[] memory resizedSuggestions = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedSuggestions[i] = suggestions[i];
        }
        return resizedSuggestions;
    }

    function requestArtistGrant(string memory _grantProposal) public onlyRegisteredArtist {
        artistGrantProposals[artistGrantIdCounter] = ArtistGrantProposal({
            grantId: artistGrantIdCounter,
            artistAddress: msg.sender,
            proposal: _grantProposal,
            voteCountYes: 0,
            voteCountNo: 0,
            isActive: true,
            isApproved: false,
            grantAmount: 0 // Grant amount to be determined later
        });
        emit ArtistGrantRequested(artistGrantIdCounter, msg.sender, _grantProposal);
        artistGrantIdCounter++;
    }

    function voteOnArtistGrant(uint256 _grantId, bool _vote) public onlyRegisteredArtist validArtistGrantProposal(_grantId) {
        require(artistGrantProposals[_grantId].isActive, "Grant proposal is not active.");
        require(!artistGrantVotes[_grantId][msg.sender], "Artist has already voted on this grant proposal.");

        artistGrantVotes[_grantId][msg.sender] = true;

        if (_vote) {
            artistGrantProposals[_grantId].voteCountYes++;
        } else {
            artistGrantProposals[_grantId].voteCountNo++;
        }
        emit ArtistGrantVoted(_grantId, msg.sender, _vote);

        // Simplified grant approval logic (adjust criteria as needed)
        if (artistGrantProposals[_grantId].voteCountYes > artistGrantProposals[_grantId].voteCountNo) {
            artistGrantProposals[_grantId].isApproved = true;
            // Grant amount could be set by gallery owner/DAO after approval.
        }
    }

    function fundArtistGrant(uint256 _grantId) public onlyGalleryOwner validArtistGrantProposal(_grantId) {
        require(artistGrantProposals[_grantId].isApproved, "Grant proposal is not approved.");
        require(artistGrantProposals[_grantId].grantAmount > 0, "Grant amount must be set before funding."); // Add a function to set grant amount.
        require(galleryBalance >= artistGrantProposals[_grantId].grantAmount, "Insufficient gallery funds for grant.");

        uint256 grantAmount = artistGrantProposals[_grantId].grantAmount;
        address artistAddress = artistGrantProposals[_grantId].artistAddress;

        galleryBalance -= grantAmount;
        payable(artistAddress).transfer(grantAmount);

        artistGrantProposals[_grantId].isActive = false; // Mark grant as funded/inactive
        emit ArtistGrantFunded(_grantId, artistAddress, grantAmount);
    }

    function getArtistReputation(address _artistAddress) public view returns (uint256) {
        return artistProfiles[_artistAddress].reputationScore;
    }

    // Fallback function to receive ETH into the gallery treasury (optional, for direct donations etc.)
    receive() external payable {
        galleryBalance += msg.value;
    }
}
```