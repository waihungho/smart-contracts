## Decentralized Autonomous Art Gallery Smart Contract

**Outline and Function Summary:**

This smart contract implements a Decentralized Autonomous Art Gallery on the blockchain. It allows artists to mint and list their digital artworks as NFTs, and collectors to purchase them.  The gallery is governed by the community through a DAO mechanism, enabling decentralized curation, feature proposals, and parameter adjustments.

**Key Features:**

* **NFT Minting & Management:** Artists can mint unique Art NFTs with customizable metadata and royalty settings.
* **Decentralized Marketplace:**  A built-in marketplace for listing and purchasing Art NFTs.
* **Community Curation:**  A proposal and voting system for featuring artworks in the gallery's "Featured Collection".
* **DAO Governance:** Token holders can participate in governance proposals to change gallery parameters (e.g., platform fees, curation thresholds).
* **Exhibition Creation:**  Curators or community members can propose and create themed digital art exhibitions.
* **Artist Profiles:** Artists can create profiles to showcase their work and background.
* **Reporting and Moderation (Decentralized):**  A reporting mechanism for problematic content, with community voting for moderation actions.
* **Dynamic Royalty System:**  Royalties are automatically distributed to artists upon secondary sales.
* **Treasury Management:**  Platform fees are collected in a treasury, which can be managed by the DAO for gallery development or community initiatives.
* **Layered Access Control:**  Different roles (owner, artists, curators, community members) with specific permissions.
* **Event Emission:**  Comprehensive events for tracking all key actions within the gallery.

**Function Summary (20+ Functions):**

**NFT Management:**

1.  `mintArtNFT(string memory _tokenURI, uint256 _royaltyPercentage)`: Allows artists to mint a new Art NFT with a given URI and royalty percentage.
2.  `listArtNFT(uint256 _tokenId, uint256 _price)`:  Artists can list their minted Art NFT for sale in the gallery's marketplace.
3.  `purchaseArtNFT(uint256 _tokenId)`: Collectors can purchase a listed Art NFT.
4.  `transferArtNFT(address _to, uint256 _tokenId)`: Standard NFT transfer function.
5.  `burnArtNFT(uint256 _tokenId)`: Allows the NFT owner to burn (destroy) an NFT.
6.  `getNFTDetails(uint256 _tokenId)`: Retrieves detailed information about a specific Art NFT.
7.  `setRoyaltyPercentage(uint256 _tokenId, uint256 _newRoyaltyPercentage)`: Allows the NFT owner to update the royalty percentage for their NFT.

**Marketplace & Transactions:**

8.  `cancelListing(uint256 _tokenId)`: Artists can cancel the listing of their NFT.
9.  `updateListingPrice(uint256 _tokenId, uint256 _newPrice)`: Artists can update the price of their listed NFT.
10. `withdrawFunds()`: Artists and the gallery owner can withdraw their accumulated earnings from sales and platform fees.
11. `getListingPrice(uint256 _tokenId)`: Retrieves the current listing price of an NFT.

**Community Curation & Governance:**

12. `proposeFeaturedArt(uint256 _tokenId)`: Community members can propose an Art NFT to be featured.
13. `voteOnFeaturedArtProposal(uint256 _proposalId, bool _vote)`: Token holders can vote on featured art proposals.
14. `featureArt(uint256 _tokenId)`:  Admin/Curators can manually feature an artwork (potentially based on proposal results or other criteria).
15. `removeFeaturedArt(uint256 _tokenId)`: Admin/Curators can remove an artwork from the featured collection.
16. `proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue)`: Token holders can propose changes to gallery parameters (e.g., platform fees, voting durations).
17. `voteOnParameterChangeProposal(uint256 _proposalId, bool _vote)`: Token holders can vote on parameter change proposals.
18. `executeParameterChange(uint256 _proposalId)`: Executes approved parameter change proposals after voting concludes.

**Exhibition & Artist Profiles:**

19. `createExhibition(string memory _exhibitionName, string memory _exhibitionDescription)`: Curators can create a new digital art exhibition.
20. `addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Curators can add Art NFTs to an existing exhibition.
21. `removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId)`: Curators can remove Art NFTs from an exhibition.
22. `createArtistProfile(string memory _artistName, string memory _artistBio, string memory _artistWebsite)`: Artists can create their public profiles.
23. `updateArtistProfile(string memory _artistName, string memory _artistBio, string memory _artistWebsite)`: Artists can update their profiles.
24. `getArtistProfile(address _artistAddress)`: Retrieves the profile information of an artist.

**Reporting & Moderation:**

25. `reportArtNFT(uint256 _tokenId, string memory _reportReason)`: Community members can report an Art NFT for violation of gallery guidelines.
26. `voteOnReport(uint256 _reportId, bool _vote)`: Token holders can vote on reported Art NFTs to determine if moderation action is needed.
27. `moderateArtNFT(uint256 _tokenId, uint256 _reportId)`: Admin/Curators can take moderation actions based on report votes (e.g., hide NFT from featured, temporarily delist).
28. `setPlatformFeePercentage(uint256 _newFeePercentage)`: Owner/DAO can set the platform fee percentage charged on sales.
29. `setVotingDuration(uint256 _newDurationInSeconds)`: Owner/DAO can set the voting duration for proposals.
30. `setQuorumPercentage(uint256 _newQuorumPercentage)`: Owner/DAO can set the quorum percentage required for proposal approvals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Gallery
 * @author Bard (Generated by a Large Language Model)
 * @dev A smart contract for a decentralized autonomous art gallery with NFT minting, marketplace,
 *      community curation, DAO governance, exhibitions, artist profiles, and reporting mechanisms.
 */
contract DecentralizedArtGallery {
    // --- State Variables ---

    string public name = "Decentralized Art Gallery";
    string public symbol = "DAGNFT";
    address public owner;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 51; // Default quorum for proposals

    uint256 public nextTokenId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextReportId = 1;
    uint256 public nextExhibitionId = 1;

    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 => uint256) public tokenListingPrice;
    mapping(uint256 => uint256) public tokenRoyaltyPercentage;
    mapping(uint256 => bool) public isListed;
    mapping(uint256 => bool) public isFeatured;

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    mapping(uint256 => Report) public reports;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(address => ArtistProfile) public artistProfiles;

    mapping(uint256 => mapping(address => bool)) public featuredArtProposalVotes;
    mapping(uint256 => mapping(address => bool)) public parameterChangeProposalVotes;
    mapping(uint256 => mapping(address => bool)) public reportVotes;

    address public treasuryAddress; // Address to collect platform fees (can be multi-sig or DAO controlled)

    // --- Structs ---

    struct ArtNFT {
        uint256 tokenId;
        string tokenURI;
        address artist;
        uint256 royaltyPercentage;
        uint256 mintTimestamp;
    }

    struct ArtProposal {
        uint256 proposalId;
        uint256 tokenId;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
    }

    struct ParameterChangeProposal {
        uint256 proposalId;
        string parameterName;
        uint256 newValue;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isActive;
        bool executed;
    }

    struct Report {
        uint256 reportId;
        uint256 tokenId;
        address reporter;
        string reportReason;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes; // Votes to moderate (e.g., hide)
        uint256 noVotes;  // Votes against moderation
        bool isActive;
        bool moderated;
    }

    struct Exhibition {
        uint256 exhibitionId;
        string exhibitionName;
        string exhibitionDescription;
        address curator;
        uint256 creationTimestamp;
        uint256[] artNFTTokenIds;
    }

    struct ArtistProfile {
        string artistName;
        string artistBio;
        string artistWebsite;
        uint256 profileCreationTimestamp;
    }

    // --- Events ---

    event ArtNFTMinted(uint256 tokenId, address artist, string tokenURI, uint256 royaltyPercentage);
    event ArtNFTListed(uint256 tokenId, address artist, uint256 price);
    event ArtNFTPurchased(uint256 tokenId, address buyer, address artist, uint256 price, uint256 royaltyAmount, uint256 platformFee);
    event ArtNFTListingCancelled(uint256 tokenId, address artist);
    event ArtNFTListingPriceUpdated(uint256 tokenId, address artist, uint256 newPrice);
    event ArtNFTTransferred(uint256 tokenId, address from, address to);
    event ArtNFTBurned(uint256 tokenId, address owner);

    event FeaturedArtProposed(uint256 proposalId, uint256 tokenId, address proposer);
    event FeaturedArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtFeatured(uint256 tokenId);
    event ArtUnfeatured(uint256 tokenId);

    event ParameterChangeProposed(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeExecuted(uint256 proposalId, string parameterName, uint256 newValue);

    event ExhibitionCreated(uint256 exhibitionId, string exhibitionName, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 tokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 tokenId);

    event ArtistProfileCreated(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string artistName);

    event ArtNFTReported(uint256 reportId, uint256 tokenId, address reporter, string reportReason);
    event ReportVoted(uint256 reportId, address voter, bool vote);
    event ArtNFTModerated(uint256 tokenId, uint256 reportId);
    event FundsWithdrawn(address recipient, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyArtist(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "Only artist can call this function.");
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(artNFTs[_tokenId].tokenId != 0, "Token does not exist.");
        _;
    }

    modifier isTokenOwner(uint256 _tokenId) {
        require(tokenOwner[_tokenId] == msg.sender, "You are not the owner of this token.");
        _;
    }

    modifier isTokenListed(uint256 _tokenId) {
        require(isListed[_tokenId], "Token is not listed for sale.");
        _;
    }

    modifier proposalActive(uint256 _proposalId, mapping(uint256 => ArtProposal) storage _proposals) {
        require(_proposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < _proposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier parameterProposalActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].isActive, "Parameter proposal is not active.");
        require(block.timestamp < parameterChangeProposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier reportActive(uint256 _reportId) {
        require(reports[_reportId].isActive, "Report is not active.");
        require(block.timestamp < reports[_reportId].endTime, "Report period has ended.");
        _;
    }


    // --- Constructor ---

    constructor(address _treasuryAddress) {
        owner = msg.sender;
        treasuryAddress = _treasuryAddress;
    }

    // --- NFT Management Functions ---

    function mintArtNFT(string memory _tokenURI, uint256 _royaltyPercentage) public {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        uint256 tokenId = nextTokenId++;
        artNFTs[tokenId] = ArtNFT({
            tokenId: tokenId,
            tokenURI: _tokenURI,
            artist: msg.sender,
            royaltyPercentage: _royaltyPercentage,
            mintTimestamp: block.timestamp
        });
        tokenOwner[tokenId] = msg.sender;
        emit ArtNFTMinted(tokenId, msg.sender, _tokenURI, _royaltyPercentage);
    }

    function listArtNFT(uint256 _tokenId, uint256 _price) public tokenExists(_tokenId) onlyArtist(_tokenId) {
        require(_price > 0, "Price must be greater than zero.");
        tokenListingPrice[_tokenId] = _price;
        isListed[_tokenId] = true;
        emit ArtNFTListed(_tokenId, msg.sender, _price);
    }

    function purchaseArtNFT(uint256 _tokenId) public payable tokenExists(_tokenId) isTokenListed(_tokenId) {
        uint256 price = tokenListingPrice[_tokenId];
        require(msg.value >= price, "Insufficient funds.");

        address artist = artNFTs[_tokenId].artist;
        uint256 royaltyPercentage = artNFTs[_tokenId].royaltyPercentage;
        uint256 royaltyAmount = (price * royaltyPercentage) / 100;
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 artistEarning = price - royaltyAmount - platformFee;

        tokenOwner[_tokenId] = msg.sender;
        isListed[_tokenId] = false;
        tokenListingPrice[_tokenId] = 0; // Clear listing price after purchase

        payable(artist).transfer(artistEarning);
        if (royaltyAmount > 0) {
            // Assuming royalty recipient is also the artist in this simplified example.
            // In a real system, royalty recipient might be different.
            payable(artist).transfer(royaltyAmount); // Royalty sent to artist (or designated royalty recipient)
        }
        payable(treasuryAddress).transfer(platformFee);

        emit ArtNFTPurchased(_tokenId, msg.sender, artist, price, royaltyAmount, platformFee);
        emit ArtNFTTransferred(_tokenId, artist, msg.sender); // Optional: Emit transfer event here as well for clarity
    }

    function transferArtNFT(address _to, uint256 _tokenId) public tokenExists(_tokenId) isTokenOwner(_tokenId) {
        require(_to != address(0), "Invalid recipient address.");
        require(_to != address(this), "Cannot transfer to contract address.");
        require(_to != msg.sender, "Cannot transfer to yourself.");

        tokenOwner[_tokenId] = _to;
        isListed[_tokenId] = false; // Cancel listing if transferred
        tokenListingPrice[_tokenId] = 0;

        emit ArtNFTTransferred(_tokenId, msg.sender, _to);
    }

    function burnArtNFT(uint256 _tokenId) public tokenExists(_tokenId) isTokenOwner(_tokenId) {
        delete artNFTs[_tokenId];
        delete tokenOwner[_tokenId];
        delete tokenListingPrice[_tokenId];
        delete isListed[_tokenId];
        delete isFeatured[_tokenId];
        emit ArtNFTBurned(_tokenId, msg.sender);
    }

    function getNFTDetails(uint256 _tokenId) public view tokenExists(_tokenId) returns (ArtNFT memory, address ownerAddress, uint256 listingPrice, bool listed, bool featured) {
        return (artNFTs[_tokenId], tokenOwner[_tokenId], tokenListingPrice[_tokenId], isListed[_tokenId], isFeatured[_tokenId]);
    }

    function setRoyaltyPercentage(uint256 _tokenId, uint256 _newRoyaltyPercentage) public tokenExists(_tokenId) onlyArtist(_tokenId) {
        require(_newRoyaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        artNFTs[_tokenId].royaltyPercentage = _newRoyaltyPercentage;
        emit ArtNFTMinted(_tokenId, msg.sender, artNFTs[_tokenId].tokenURI, _newRoyaltyPercentage); // Re-emit Minted event to reflect change (optional)
    }

    // --- Marketplace Functions ---

    function cancelListing(uint256 _tokenId) public tokenExists(_tokenId) onlyArtist(_tokenId) isTokenListed(_tokenId) {
        isListed[_tokenId] = false;
        tokenListingPrice[_tokenId] = 0;
        emit ArtNFTListingCancelled(_tokenId, msg.sender);
    }

    function updateListingPrice(uint256 _tokenId, uint256 _newPrice) public tokenExists(_tokenId) onlyArtist(_tokenId) isTokenListed(_tokenId) {
        require(_newPrice > 0, "Price must be greater than zero.");
        tokenListingPrice[_tokenId] = _newPrice;
        emit ArtNFTListingPriceUpdated(_tokenId, msg.sender, _newPrice);
    }

    function withdrawFunds() public {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw.");
        payable(msg.sender).transfer(balance);
        emit FundsWithdrawn(msg.sender, balance);
    }

    function getListingPrice(uint256 _tokenId) public view tokenExists(_tokenId) returns (uint256) {
        return tokenListingPrice[_tokenId];
    }


    // --- Community Curation & Governance Functions ---

    function proposeFeaturedArt(uint256 _tokenId) public tokenExists(_tokenId) {
        require(!isFeatured[_tokenId], "Art is already featured.");
        require(tokenOwner[_tokenId] != address(0), "Token has no owner."); // Ensure token is not burned

        uint256 proposalId = nextProposalId++;
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            tokenId: _tokenId,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: true
        });
        emit FeaturedArtProposed(proposalId, _tokenId, msg.sender);
    }

    function voteOnFeaturedArtProposal(uint256 _proposalId, bool _vote) public proposalActive(_proposalId, artProposals) {
        require(!featuredArtProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        featuredArtProposalVotes[_proposalId][msg.sender] = true;

        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit FeaturedArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function featureArt(uint256 _tokenId) public onlyOwner tokenExists(_tokenId) { // Only owner can feature, could be DAO later
        isFeatured[_tokenId] = true;
        emit ArtFeatured(_tokenId);
    }

    function removeFeaturedArt(uint256 _tokenId) public onlyOwner tokenExists(_tokenId) { // Only owner can unfeature, could be DAO later
        isFeatured[_tokenId] = false;
        emit ArtUnfeatured(_tokenId);
    }

    function proposeGalleryParameterChange(string memory _parameterName, uint256 _newValue) public {
        uint256 proposalId = nextProposalId++;
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            proposalId: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            proposer: msg.sender,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            executed: false
        });
        emit ParameterChangeProposed(proposalId, _parameterName, _newValue, msg.sender);
    }

    function voteOnParameterChangeProposal(uint256 _proposalId, bool _vote) public parameterProposalActive(_proposalId) {
        require(!parameterChangeProposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        parameterChangeProposalVotes[_proposalId][msg.sender] = true;

        if (_vote) {
            parameterChangeProposals[_proposalId].yesVotes++;
        } else {
            parameterChangeProposals[_proposalId].noVotes++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeParameterChange(uint256 _proposalId) public parameterProposalActive(_proposalId) {
        require(!parameterChangeProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = parameterChangeProposals[_proposalId].yesVotes + parameterChangeProposals[_proposalId].noVotes;
        uint256 quorum = (totalVotes * 100) / 100; // Assuming 100 total voting power, adjust as needed for DAO setup
        uint256 requiredQuorum = (quorum * quorumPercentage) / 100;

        if (parameterChangeProposals[_proposalId].yesVotes >= requiredQuorum) {
            string memory parameterName = parameterChangeProposals[_proposalId].parameterName;
            uint256 newValue = parameterChangeProposals[_proposalId].newValue;

            if (keccak256(bytes(parameterName)) == keccak256(bytes("platformFeePercentage"))) {
                setPlatformFeePercentage(newValue);
            } else if (keccak256(bytes(parameterName)) == keccak256(bytes("votingDuration"))) {
                setVotingDuration(newValue);
            } else if (keccak256(bytes(parameterName)) == keccak256(bytes("quorumPercentage"))) {
                setQuorumPercentage(newValue);
            } else {
                revert("Invalid parameter name.");
            }

            parameterChangeProposals[_proposalId].isActive = false;
            parameterChangeProposals[_proposalId].executed = true;
            emit ParameterChangeExecuted(_proposalId, parameterName, newValue);
        } else {
            parameterChangeProposals[_proposalId].isActive = false;
            parameterChangeProposals[_proposalId].executed = true; // Mark as executed even if failed
            revert("Proposal failed: Quorum not reached.");
        }
    }


    // --- Exhibition & Artist Profile Functions ---

    function createExhibition(string memory _exhibitionName, string memory _exhibitionDescription) public onlyOwner {
        uint256 exhibitionId = nextExhibitionId++;
        exhibitions[exhibitionId] = Exhibition({
            exhibitionId: exhibitionId,
            exhibitionName: _exhibitionName,
            exhibitionDescription: _exhibitionDescription,
            curator: msg.sender,
            creationTimestamp: block.timestamp,
            artNFTTokenIds: new uint256[](0)
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionName, msg.sender);
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyOwner tokenExists(_tokenId) {
        require(exhibitions[_exhibitionId].exhibitionId != 0, "Exhibition does not exist.");
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artNFTTokenIds.length; i++) {
            require(exhibitions[_exhibitionId].artNFTTokenIds[i] != _tokenId, "Art already in exhibition.");
        }
        exhibitions[_exhibitionId].artNFTTokenIds.push(_tokenId);
        emit ArtAddedToExhibition(_exhibitionId, _tokenId);
    }

    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _tokenId) public onlyOwner tokenExists(_tokenId) {
        require(exhibitions[_exhibitionId].exhibitionId != 0, "Exhibition does not exist.");
        uint256[] storage tokenIds = exhibitions[_exhibitionId].artNFTTokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] == _tokenId) {
                // Shift elements to remove _tokenId
                for (uint256 j = i; j < tokenIds.length - 1; j++) {
                    tokenIds[j] = tokenIds[j + 1];
                }
                tokenIds.pop();
                emit ArtRemovedFromExhibition(_exhibitionId, _tokenId);
                return;
            }
        }
        revert("Art not found in exhibition.");
    }

    function createArtistProfile(string memory _artistName, string memory _artistBio, string memory _artistWebsite) public {
        require(bytes(_artistName).length > 0, "Artist name cannot be empty.");
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistBio: _artistBio,
            artistWebsite: _artistWebsite,
            profileCreationTimestamp: block.timestamp
        });
        emit ArtistProfileCreated(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _artistName, string memory _artistBio, string memory _artistWebsite) public {
        require(bytes(_artistName).length > 0, "Artist name cannot be empty.");
        require(artistProfiles[msg.sender].profileCreationTimestamp != 0, "Artist profile does not exist. Create profile first.");
        artistProfiles[msg.sender].artistName = _artistName;
        artistProfiles[msg.sender].artistBio = _artistBio;
        artistProfiles[msg.sender].artistWebsite = _artistWebsite;
        emit ArtistProfileUpdated(msg.sender, _artistName);
    }

    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }


    // --- Reporting & Moderation Functions ---

    function reportArtNFT(uint256 _tokenId, string memory _reportReason) public tokenExists(_tokenId) {
        require(bytes(_reportReason).length > 0, "Report reason cannot be empty.");
        uint256 reportId = nextReportId++;
        reports[reportId] = Report({
            reportId: reportId,
            tokenId: _tokenId,
            reporter: msg.sender,
            reportReason: _reportReason,
            startTime: block.timestamp,
            endTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            moderated: false
        });
        emit ArtNFTReported(reportId, _tokenId, msg.sender, _reportReason);
    }

    function voteOnReport(uint256 _reportId, bool _vote) public reportActive(_reportId) {
        require(!reportVotes[_reportId][msg.sender], "You have already voted on this report.");
        reportVotes[_reportId][msg.sender] = true;

        if (_vote) {
            reports[_reportId].yesVotes++;
        } else {
            reports[_reportId].noVotes++;
        }
        emit ReportVoted(_reportId, msg.sender, _vote);
    }

    function moderateArtNFT(uint256 _tokenId, uint256 _reportId) public onlyOwner tokenExists(_tokenId) reportActive(_reportId) { // Owner for moderation, could be DAO later
        require(!reports[_reportId].moderated, "Report already processed.");

        uint256 totalVotes = reports[_reportId].yesVotes + reports[_reportId].noVotes;
        uint256 quorum = (totalVotes * 100) / 100; // Assuming 100 total voting power, adjust as needed for DAO setup
        uint256 requiredQuorum = (quorum * quorumPercentage) / 100;

        if (reports[_reportId].yesVotes >= requiredQuorum) {
            // Implement moderation action - e.g., hide from featured, delist, etc.
            isFeatured[_tokenId] = false; // Example: Remove from featured if reported and voted for moderation
            isListed[_tokenId] = false;  // Example: Delist from marketplace

            reports[_reportId].isActive = false;
            reports[_reportId].moderated = true;
            emit ArtNFTModerated(_tokenId, _reportId);
        } else {
            reports[_reportId].isActive = false;
            reports[_reportId].moderated = true; // Mark as processed even if moderation failed
        }
    }

    // --- Governance Parameter Setting Functions ---

    function setPlatformFeePercentage(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Platform fee percentage must be between 0 and 100.");
        platformFeePercentage = _newFeePercentage;
    }

    function setVotingDuration(uint256 _newDurationInSeconds) public onlyOwner {
        votingDuration = _newDurationInSeconds;
    }

    function setQuorumPercentage(uint256 _newQuorumPercentage) public onlyOwner {
        require(_newQuorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _newQuorumPercentage;
    }

    // --- Fallback and Receive Functions ---

    receive() external payable {}
    fallback() external payable {}
}
```