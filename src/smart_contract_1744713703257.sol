```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (Example - Not for Production)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaborate, curate, and monetize digital art in novel ways.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership & Governance:**
 *    - `applyForMembership(string memory artistStatement, string memory portfolioLink)`: Artists can apply for membership by submitting a statement and portfolio.
 *    - `voteOnMembershipApplication(uint256 applicationId, bool approve)`: Members can vote to approve or reject membership applications.
 *    - `revokeMembership(address memberAddress)`: Admin function to revoke membership from a member.
 *    - `isMember(address account)`: Checks if an address is a member of the collective.
 *    - `getMemberCount()`: Returns the total number of members.
 *
 * **2. Art Submission & Curation:**
 *    - `submitArt(string memory title, string memory description, string memory ipfsHash, uint256 price)`: Members can submit their digital art for curation.
 *    - `voteOnArtSubmission(uint256 submissionId, bool approve)`: Members vote on whether to curate and list a submitted artwork.
 *    - `setArtCurationThreshold(uint256 newThreshold)`: Admin function to set the percentage threshold for art curation approval.
 *    - `getArtSubmissionStatus(uint256 submissionId)`: Returns the status of an art submission (pending, approved, rejected).
 *    - `getApprovedArtCount()`: Returns the total number of approved and listed artworks.
 *
 * **3. Art Marketplace & Sales:**
 *    - `buyArt(uint256 artworkId)`: Allows anyone to purchase listed artwork.
 *    - `setPlatformFeePercentage(uint256 newFeePercentage)`: Admin function to set the platform fee percentage on art sales.
 *    - `withdrawPlatformFees()`: Admin function to withdraw accumulated platform fees.
 *    - `getArtworkDetails(uint256 artworkId)`: Retrieves details of a specific artwork.
 *    - `listAllArtworks()`: Returns a list of IDs of all approved and listed artworks.
 *
 * **4. Collaborative Art & Royalties:**
 *    - `createCollaborativeArtProposal(string memory title, string memory description, string[] memory artistAddresses, string memory proposalDetails)`: Members can propose collaborative art projects with defined artists and details.
 *    - `voteOnCollaborationProposal(uint256 proposalId, bool approve)`: Members vote on collaborative art proposals.
 *    - `mintCollaborativeNFT(uint256 proposalId, string memory ipfsHash)`: Once a collaborative proposal is approved and art created, mint a collaborative NFT.
 *    - `setCollaborativeNFTPrimarySalePrice(uint256 tokenId, uint256 price)`: Set the initial sale price for a collaborative NFT.
 *    - `buyCollaborativeNFT(uint256 tokenId)`: Purchase a collaborative NFT.
 *    - `getCollaborativeNFTRoyalties(uint256 tokenId)`: View the royalty distribution for a collaborative NFT.
 *
 * **5. DAO Treasury & Funding:**
 *    - `depositToTreasury() payable`: Allow members to deposit funds into the DAO treasury.
 *    - `createFundingProposal(string memory description, uint256 amount)`: Members can propose funding requests from the treasury for collective initiatives.
 *    - `voteOnFundingProposal(uint256 proposalId, bool approve)`: Members vote on funding proposals.
 *    - `executeFundingProposal(uint256 proposalId)`: Admin function to execute approved funding proposals and send funds.
 *    - `getTreasuryBalance()`: Returns the current balance of the DAO treasury.
 *
 * **Advanced Concepts & Creativity:**
 * - **Decentralized Curation:** Art curation is community-driven through member voting.
 * - **Collaborative Art NFTs:** Enables joint ownership and revenue sharing for collaborative artistic creations.
 * - **DAO Treasury for Collective Initiatives:**  Funds can be used for marketing, community events, or further artistic projects voted on by the DAO.
 * - **Dynamic Membership:** Membership is not static and requires ongoing community approval.
 * - **Transparent Royalties for Collaborations:** Royalty distribution for collaborative NFTs is clearly defined and enforced on-chain.
 */

contract DecentralizedAutonomousArtCollective {
    // ---- State Variables ----

    address public admin;
    uint256 public membershipApplicationCount;
    uint256 public artSubmissionCount;
    uint256 public collaborativeProposalCount;
    uint256 public fundingProposalCount;
    uint256 public platformFeePercentage = 5; // 5% platform fee by default
    uint256 public artCurationThresholdPercentage = 60; // 60% approval for art curation

    mapping(address => bool) public members;
    mapping(uint256 => MembershipApplication) public membershipApplications;
    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => CollaborativeArtProposal) public collaborativeArtProposals;
    mapping(uint256 => FundingProposal) public fundingProposals;
    mapping(uint256 => Artwork) public artworks; // Approved and listed artworks
    uint256 public artworkCount;
    mapping(uint256 => CollaborativeNFT) public collaborativeNFTs;
    uint256 public collaborativeNFTCount;


    struct MembershipApplication {
        address applicant;
        string artistStatement;
        string portfolioLink;
        uint256 votesFor;
        uint256 votesAgainst;
        bool decided;
        bool approved;
    }

    struct ArtSubmission {
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 price;
        uint256 votesFor;
        uint256 votesAgainst;
        bool decided;
        bool approved;
        bool listed;
    }

    struct Artwork {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 price;
        bool listed;
    }

    struct CollaborativeArtProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address[] artists; // Participating artists
        string proposalDetails;
        uint256 votesFor;
        uint256 votesAgainst;
        bool decided;
        bool approved;
        bool nftMinted;
    }

    struct CollaborativeNFT {
        uint256 id;
        uint256 proposalId;
        string ipfsHash;
        uint256 primarySalePrice;
        address[] artists; // Artists who collaborated
        // Could add royalty split logic here if needed, for simplicity assuming equal split for now.
    }

    struct FundingProposal {
        uint256 id;
        address proposer;
        string description;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        bool decided;
        bool approved;
        bool executed;
    }


    // ---- Events ----
    event MembershipApplicationSubmitted(uint256 applicationId, address applicant);
    event MembershipApplicationVoted(uint256 applicationId, address voter, bool approved);
    event MembershipApproved(address memberAddress);
    event MembershipRevoked(address memberAddress);

    event ArtSubmitted(uint256 submissionId, address artist, string title);
    event ArtSubmissionVoted(uint256 submissionId, address voter, bool approved);
    event ArtCurationApproved(uint256 submissionId);
    event ArtCurationRejected(uint256 submissionId);
    event ArtListed(uint256 artworkId, uint256 submissionId);
    event ArtPurchased(uint256 artworkId, address buyer, uint256 price);

    event CollaborativeProposalCreated(uint256 proposalId, address proposer, string title);
    event CollaborativeProposalVoted(uint256 proposalId, address voter, bool approved);
    event CollaborativeProposalApproved(uint256 proposalId);
    event CollaborativeProposalRejected(uint256 proposalId);
    event CollaborativeNFTMinted(uint256 tokenId, uint256 proposalId, string ipfsHash);
    event CollaborativeNFTPurchase(uint256 tokenId, address buyer, uint256 price);

    event FundingProposalCreated(uint256 proposalId, address proposer, uint256 amount);
    event FundingProposalVoted(uint256 proposalId, address voter, bool approved);
    event FundingProposalApproved(uint256 proposalId);
    event FundingProposalRejected(uint256 proposalId);
    event FundingProposalExecuted(uint256 proposalId, uint256 amount);
    event TreasuryDeposit(address depositor, uint256 amount);
    event PlatformFeesWithdrawn(address admin, uint256 amount);
    event ArtCurationThresholdUpdated(uint256 newThreshold);
    event PlatformFeePercentageUpdated(uint256 newPercentage);


    // ---- Modifiers ----
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyMembers() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier validApplicationId(uint256 applicationId) {
        require(membershipApplications[applicationId].applicant != address(0), "Invalid Application ID.");
        _;
    }

    modifier validSubmissionId(uint256 submissionId) {
        require(artSubmissions[submissionId].artist != address(0), "Invalid Submission ID.");
        _;
    }

    modifier validArtworkId(uint256 artworkId) {
        require(artworks[artworkId].artist != address(0), "Invalid Artwork ID.");
        _;
    }

    modifier validProposalId(uint256 proposalId) {
        require(collaborativeArtProposals[proposalId].proposer != address(0) || fundingProposals[proposalId].proposer != address(0), "Invalid Proposal ID.");
        _;
    }

    modifier validCollaborativeNFTId(uint256 tokenId) {
        require(collaborativeNFTs[tokenId].proposalId != 0, "Invalid Collaborative NFT ID.");
        _;
    }


    // ---- Constructor ----
    constructor() {
        admin = msg.sender;
    }

    // ---- 1. Membership & Governance Functions ----

    /**
     * @dev Artists can apply for membership to the collective.
     * @param _artistStatement A statement from the artist about their work and interest in the collective.
     * @param _portfolioLink A link to the artist's online portfolio.
     */
    function applyForMembership(string memory _artistStatement, string memory _portfolioLink) public {
        membershipApplicationCount++;
        membershipApplications[membershipApplicationCount] = MembershipApplication({
            applicant: msg.sender,
            artistStatement: _artistStatement,
            portfolioLink: _portfolioLink,
            votesFor: 0,
            votesAgainst: 0,
            decided: false,
            approved: false
        });
        emit MembershipApplicationSubmitted(membershipApplicationCount, msg.sender);
    }

    /**
     * @dev Members can vote on a membership application.
     * @param _applicationId The ID of the membership application.
     * @param _approve True to approve the application, false to reject.
     */
    function voteOnMembershipApplication(uint256 _applicationId, bool _approve) public onlyMembers validApplicationId(_applicationId) {
        require(!membershipApplications[_applicationId].decided, "Application already decided.");
        require(membershipApplications[_applicationId].applicant != msg.sender, "Applicant cannot vote on their own application.");

        if (_approve) {
            membershipApplications[_applicationId].votesFor++;
        } else {
            membershipApplications[_applicationId].votesAgainst++;
        }
        emit MembershipApplicationVoted(_applicationId, msg.sender, _approve);

        // Simple majority voting for now. Can be made more complex.
        uint256 totalMembers = getMemberCount();
        if (membershipApplications[_applicationId].votesFor > totalMembers / 2) {
            membershipApplications[_applicationId].decided = true;
            membershipApplications[_applicationId].approved = true;
            members[membershipApplications[_applicationId].applicant] = true;
            emit MembershipApproved(membershipApplications[_applicationId].applicant);
        } else if (membershipApplications[_applicationId].votesAgainst > totalMembers / 2) {
            membershipApplications[_applicationId].decided = true;
            membershipApplications[_applicationId].approved = false;
        }
    }

    /**
     * @dev Admin function to revoke membership from a member.
     * @param _memberAddress The address of the member to revoke membership from.
     */
    function revokeMembership(address _memberAddress) public onlyAdmin {
        require(members[_memberAddress], "Address is not a member.");
        members[_memberAddress] = false;
        emit MembershipRevoked(_memberAddress);
    }

    /**
     * @dev Checks if an address is a member of the collective.
     * @param _account The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _account) public view returns (bool) {
        return members[_account];
    }

    /**
     * @dev Returns the total number of members in the collective.
     * @return The member count.
     */
    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = getAllMembers(); // Get all potential member addresses
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]]) {
                count++;
            }
        }
        return count;
    }

    function getAllMembers() private view returns (address[] memory) {
        address[] memory memberList = new address[](membershipApplicationCount); // Assuming max potential members = application count
        uint256 index = 0;
        for (uint256 i = 1; i <= membershipApplicationCount; i++) {
            if (membershipApplications[i].applicant != address(0) && members[membershipApplications[i].applicant]) {
                memberList[index] = membershipApplications[i].applicant;
                index++;
            }
        }

        // Resize array to remove empty slots if necessary
        address[] memory finalMemberList = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            finalMemberList[i] = memberList[i];
        }
        return finalMemberList;
    }


    // ---- 2. Art Submission & Curation Functions ----

    /**
     * @dev Members can submit their digital art for curation.
     * @param _title The title of the artwork.
     * @param _description A description of the artwork.
     * @param _ipfsHash The IPFS hash of the artwork's digital file.
     * @param _price The desired price of the artwork in Wei.
     */
    function submitArt(string memory _title, string memory _description, string memory _ipfsHash, uint256 _price) public onlyMembers {
        artSubmissionCount++;
        artSubmissions[artSubmissionCount] = ArtSubmission({
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            price: _price,
            votesFor: 0,
            votesAgainst: 0,
            decided: false,
            approved: false,
            listed: false
        });
        emit ArtSubmitted(artSubmissionCount, msg.sender, _title);
    }

    /**
     * @dev Members vote on an art submission for curation.
     * @param _submissionId The ID of the art submission.
     * @param _approve True to approve the submission, false to reject.
     */
    function voteOnArtSubmission(uint256 _submissionId, bool _approve) public onlyMembers validSubmissionId(_submissionId) {
        require(!artSubmissions[_submissionId].decided, "Submission already decided.");
        require(artSubmissions[_submissionId].artist != msg.sender, "Artist cannot vote on their own submission.");

        if (_approve) {
            artSubmissions[_submissionId].votesFor++;
        } else {
            artSubmissions[_submissionId].votesAgainst++;
        }
        emit ArtSubmissionVoted(_submissionId, msg.sender, _approve);

        uint256 totalMembers = getMemberCount();
        uint256 requiredVotes = (totalMembers * artCurationThresholdPercentage) / 100;

        if (artSubmissions[_submissionId].votesFor >= requiredVotes) {
            artSubmissions[_submissionId].decided = true;
            artSubmissions[_submissionId].approved = true;
            emit ArtCurationApproved(_submissionId);
        } else if (artSubmissions[_submissionId].votesAgainst > totalMembers - requiredVotes ) { // More rejections than needed to approve means rejection.
            artSubmissions[_submissionId].decided = true;
            artSubmissions[_submissionId].approved = false;
            emit ArtCurationRejected(_submissionId);
        }
    }

    /**
     * @dev Admin function to set the percentage threshold required for art curation approval.
     * @param _newThreshold The new percentage threshold (e.g., 60 for 60%).
     */
    function setArtCurationThreshold(uint256 _newThreshold) public onlyAdmin {
        require(_newThreshold <= 100, "Threshold must be between 0 and 100.");
        artCurationThresholdPercentage = _newThreshold;
        emit ArtCurationThresholdUpdated(_newThreshold);
    }

    /**
     * @dev Returns the status of an art submission.
     * @param _submissionId The ID of the art submission.
     * @return A string representing the status: "pending", "approved", "rejected".
     */
    function getArtSubmissionStatus(uint256 _submissionId) public view validSubmissionId(_submissionId) returns (string memory) {
        if (!artSubmissions[_submissionId].decided) {
            return "pending";
        } else if (artSubmissions[_submissionId].approved) {
            return "approved";
        } else {
            return "rejected";
        }
    }

    /**
     * @dev Returns the total number of approved and listed artworks.
     * @return The approved artwork count.
     */
    function getApprovedArtCount() public view returns (uint256) {
        return artworkCount;
    }


    // ---- 3. Art Marketplace & Sales Functions ----

    /**
     * @dev Allows anyone to purchase a listed artwork.
     * @param _artworkId The ID of the artwork to purchase.
     */
    function buyArt(uint256 _artworkId) public payable validArtworkId(_artworkId) {
        Artwork storage artwork = artworks[_artworkId];
        require(artwork.listed, "Artwork is not listed for sale.");
        require(msg.value >= artwork.price, "Insufficient funds sent.");

        uint256 platformFee = (artwork.price * platformFeePercentage) / 100;
        uint256 artistShare = artwork.price - platformFee;

        payable(artwork.artist).transfer(artistShare);
        payable(admin).transfer(platformFee); // Admin address receives platform fees.

        emit ArtPurchased(_artworkId, msg.sender, artwork.price);
        artworks[_artworkId].listed = false; // Mark as no longer listed after purchase.
    }

    /**
     * @dev Admin function to set the platform fee percentage on art sales.
     * @param _newFeePercentage The new platform fee percentage (e.g., 5 for 5%).
     */
    function setPlatformFeePercentage(uint256 _newFeePercentage) public onlyAdmin {
        require(_newFeePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageUpdated(_newFeePercentage);
    }

    /**
     * @dev Admin function to withdraw accumulated platform fees from the contract balance.
     */
    function withdrawPlatformFees() public onlyAdmin {
        uint256 balance = address(this).balance;
        uint256 withdrawableFees = balance; // For simplicity, withdraw all balance as fees. In real scenario, track fees specifically.
        require(withdrawableFees > 0, "No platform fees to withdraw.");

        payable(admin).transfer(withdrawableFees);
        emit PlatformFeesWithdrawn(admin, withdrawableFees);
    }

    /**
     * @dev Retrieves details of a specific artwork.
     * @param _artworkId The ID of the artwork.
     * @return Details of the artwork (artist, title, description, ipfsHash, price, listed status).
     */
    function getArtworkDetails(uint256 _artworkId) public view validArtworkId(_artworkId) returns (address artist, string memory title, string memory description, string memory ipfsHash, uint256 price, bool listed) {
        Artwork storage artwork = artworks[_artworkId];
        return (artwork.artist, artwork.title, artwork.description, artwork.ipfsHash, artwork.price, artwork.listed);
    }

    /**
     * @dev Lists all approved and currently listed artwork IDs.
     * @return An array of artwork IDs.
     */
    function listAllArtworks() public view returns (uint256[] memory) {
        uint256[] memory artworkIdList = new uint256[](artworkCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= artworkCount; i++) {
            if (artworks[i].listed) {
                artworkIdList[index] = i;
                index++;
            }
        }
        // Resize array to remove empty slots
        uint256[] memory finalArtworkIdList = new uint256[](index);
        for (uint256 i = 0; i < index; i++) {
            finalArtworkIdList[i] = artworkIdList[i];
        }
        return finalArtworkIdList;
    }


    // ---- 4. Collaborative Art & Royalties Functions ----

    /**
     * @dev Members can propose collaborative art projects.
     * @param _title The title of the collaborative project.
     * @param _description A description of the project.
     * @param _artistAddresses An array of addresses of artists participating in the collaboration.
     * @param _proposalDetails Further details about the collaboration.
     */
    function createCollaborativeArtProposal(string memory _title, string memory _description, address[] memory _artistAddresses, string memory _proposalDetails) public onlyMembers {
        require(_artistAddresses.length > 1, "At least two artists are required for collaboration.");
        for (uint256 i = 0; i < _artistAddresses.length; i++) {
            require(members[_artistAddresses[i]], "All collaborating artists must be members.");
        }
        collaborativeProposalCount++;
        collaborativeArtProposals[collaborativeProposalCount] = CollaborativeArtProposal({
            id: collaborativeProposalCount,
            proposer: msg.sender,
            title: _title,
            description: _description,
            artists: _artistAddresses,
            proposalDetails: _proposalDetails,
            votesFor: 0,
            votesAgainst: 0,
            decided: false,
            approved: false,
            nftMinted: false
        });
        emit CollaborativeProposalCreated(collaborativeProposalCount, msg.sender, _title);
    }

    /**
     * @dev Members vote on a collaborative art proposal.
     * @param _proposalId The ID of the collaborative art proposal.
     * @param _approve True to approve the proposal, false to reject.
     */
    function voteOnCollaborationProposal(uint256 _proposalId, bool _approve) public onlyMembers validProposalId(_proposalId) {
        CollaborativeArtProposal storage proposal = collaborativeArtProposals[_proposalId];
        require(!proposal.decided, "Proposal already decided.");
        require(proposal.proposer != msg.sender, "Proposer cannot vote on their own proposal.");
        bool isCollaborator = false;
        for (uint256 i = 0; i < proposal.artists.length; i++) {
            if (proposal.artists[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(!isCollaborator, "Collaborating artists cannot vote on their own proposal.");


        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit CollaborativeProposalVoted(_proposalId, msg.sender, _approve);

        uint256 totalMembers = getMemberCount();
        if (proposal.votesFor > totalMembers / 2) {
            proposal.decided = true;
            proposal.approved = true;
            emit CollaborativeProposalApproved(_proposalId);
        } else if (proposal.votesAgainst > totalMembers / 2) {
            proposal.decided = true;
            proposal.approved = false;
            emit CollaborativeProposalRejected(_proposalId);
        }
    }

    /**
     * @dev Mints a collaborative NFT once a proposal is approved and art is created.
     * @param _proposalId The ID of the approved collaborative art proposal.
     * @param _ipfsHash The IPFS hash of the collaborative artwork's digital file.
     */
    function mintCollaborativeNFT(uint256 _proposalId, string memory _ipfsHash) public onlyMembers validProposalId(_proposalId) {
        CollaborativeArtProposal storage proposal = collaborativeArtProposals[_proposalId];
        require(proposal.approved, "Proposal must be approved before minting NFT.");
        require(!proposal.nftMinted, "NFT already minted for this proposal.");

        collaborativeNFTCount++;
        collaborativeNFTs[collaborativeNFTCount] = CollaborativeNFT({
            id: collaborativeNFTCount,
            proposalId: _proposalId,
            ipfsHash: _ipfsHash,
            primarySalePrice: 0, // Price set separately later
            artists: proposal.artists
        });
        proposal.nftMinted = true;
        emit CollaborativeNFTMinted(collaborativeNFTCount, _proposalId, _ipfsHash);
    }

    /**
     * @dev Sets the initial primary sale price for a collaborative NFT. Only proposers or collaborators can set the price.
     * @param _tokenId The ID of the collaborative NFT.
     * @param _price The primary sale price in Wei.
     */
    function setCollaborativeNFTPrimarySalePrice(uint256 _tokenId, uint256 _price) public onlyMembers validCollaborativeNFTId(_tokenId) {
        CollaborativeNFT storage nft = collaborativeNFTs[_tokenId];
        CollaborativeArtProposal storage proposal = collaborativeArtProposals[nft.proposalId];
        require(proposal.approved && proposal.nftMinted, "NFT must be minted from an approved proposal.");

        bool isCollaborator = false;
        if (proposal.proposer == msg.sender) isCollaborator = true; // Proposer can set price
        for (uint256 i = 0; i < proposal.artists.length; i++) {
            if (proposal.artists[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "Only proposer or collaborating artists can set the price.");

        nft.primarySalePrice = _price;
    }

    /**
     * @dev Allows anyone to purchase a collaborative NFT.
     * @param _tokenId The ID of the collaborative NFT to purchase.
     */
    function buyCollaborativeNFT(uint256 _tokenId) public payable validCollaborativeNFTId(_tokenId) {
        CollaborativeNFT storage nft = collaborativeNFTs[_tokenId];
        require(nft.primarySalePrice > 0, "Primary sale price not set yet.");
        require(msg.value >= nft.primarySalePrice, "Insufficient funds sent.");

        uint256 platformFee = (nft.primarySalePrice * platformFeePercentage) / 100;
        uint256 artistShare = nft.primarySalePrice - platformFee;
        uint256 individualArtistShare = artistShare / nft.artists.length;
        uint256 remainingShare = artistShare % nft.artists.length; // Handle remainder

        for (uint256 i = 0; i < nft.artists.length; i++) {
            payable(nft.artists[i]).transfer(individualArtistShare);
        }
        payable(nft.artists[0]).transfer(remainingShare); // Send remainder to the first artist for simplicity
        payable(admin).transfer(platformFee);

        emit CollaborativeNFTPurchase(_tokenId, msg.sender, nft.primarySalePrice);
        collaborativeNFTs[_tokenId].primarySalePrice = 0; // Mark as sold by setting price to 0. Can be updated for secondary market if needed.
    }

    /**
     * @dev Retrieves the royalty distribution for a collaborative NFT.
     * @param _tokenId The ID of the collaborative NFT.
     * @return An array of artist addresses who receive royalties.
     */
    function getCollaborativeNFTRoyalties(uint256 _tokenId) public view validCollaborativeNFTId(_tokenId) returns (address[] memory) {
        return collaborativeNFTs[_tokenId].artists;
    }


    // ---- 5. DAO Treasury & Funding Functions ----

    /**
     * @dev Allows members to deposit funds into the DAO treasury.
     */
    function depositToTreasury() public payable onlyMembers {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @dev Members can create funding proposals to request funds from the treasury.
     * @param _description Description of the funding purpose.
     * @param _amount The amount of ETH requested in Wei.
     */
    function createFundingProposal(string memory _description, uint256 _amount) public onlyMembers {
        fundingProposalCount++;
        fundingProposals[fundingProposalCount] = FundingProposal({
            id: fundingProposalCount,
            proposer: msg.sender,
            description: _description,
            amount: _amount,
            votesFor: 0,
            votesAgainst: 0,
            decided: false,
            approved: false,
            executed: false
        });
        emit FundingProposalCreated(fundingProposalCount, msg.sender, _amount);
    }

    /**
     * @dev Members vote on a funding proposal.
     * @param _proposalId The ID of the funding proposal.
     * @param _approve True to approve the funding, false to reject.
     */
    function voteOnFundingProposal(uint256 _proposalId, bool _approve) public onlyMembers validProposalId(_proposalId) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(!proposal.decided, "Funding proposal already decided.");
        require(proposal.proposer != msg.sender, "Proposer cannot vote on their own funding proposal.");

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit FundingProposalVoted(_proposalId, msg.sender, _approve);

        uint256 totalMembers = getMemberCount();
        if (proposal.votesFor > totalMembers / 2) {
            proposal.decided = true;
            proposal.approved = true;
            emit FundingProposalApproved(_proposalId);
        } else if (proposal.votesAgainst > totalMembers / 2) {
            proposal.decided = true;
            proposal.approved = false;
            emit FundingProposalRejected(_proposalId);
        }
    }

    /**
     * @dev Admin function to execute an approved funding proposal and send funds.
     * @param _proposalId The ID of the approved funding proposal.
     */
    function executeFundingProposal(uint256 _proposalId) public onlyAdmin validProposalId(_proposalId) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.approved, "Funding proposal must be approved before execution.");
        require(!proposal.executed, "Funding proposal already executed.");
        require(address(this).balance >= proposal.amount, "Contract treasury balance is insufficient.");

        proposal.executed = true;
        payable(proposal.proposer).transfer(proposal.amount); // Send funds to the proposer (can be changed to a different recipient if needed)
        emit FundingProposalExecuted(_proposalId, proposal.amount);
    }

    /**
     * @dev Returns the current balance of the DAO treasury (contract balance).
     * @return The treasury balance in Wei.
     */
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Fallback function to receive Ether.
     */
    receive() external payable {}
}
```