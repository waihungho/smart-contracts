```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * It enables artists to submit their artwork, community members to vote on artwork acquisition,
 * manage a treasury for art purchases, organize virtual exhibitions, issue collectible membership NFTs,
 * facilitate art piece fractionalization, implement a reputation system for members,
 * manage artist royalties, enable art insurance, handle dispute resolution, integrate with a decentralized storage,
 * and offer art-themed DeFi interactions.
 *
 * Function Summary:
 *
 * 1.  `joinCollective(string _artistStatement)`: Allows artists to apply to join the collective with an artist statement.
 * 2.  `approveArtist(address _artist)`: Admin function to approve a pending artist application.
 * 3.  `submitArtworkProposal(string _artworkTitle, string _artworkDescription, string _artworkCID, uint256 _proposedPrice)`: Artists propose their artwork for acquisition.
 * 4.  `voteOnArtworkProposal(uint256 _proposalId, bool _vote)`: Members vote on artwork proposals.
 * 5.  `executeArtworkAcquisition(uint256 _proposalId)`: Executes the acquisition of approved artwork if the vote passes and funds are available.
 * 6.  `createExhibition(string _exhibitionTitle, string _exhibitionDescription, uint256 _startTime, uint256 _endTime)`: Admin function to create a virtual exhibition.
 * 7.  `addArtToExhibition(uint256 _exhibitionId, uint256 _artworkId)`: Admin function to add artwork to an exhibition.
 * 8.  `mintMembershipNFT(string _nftMetadataURI)`: Allows approved artists and active members to mint a collectible Membership NFT.
 * 9.  `fractionalizeArtwork(uint256 _artworkId, uint256 _numberOfFractions)`: Allows the collective to fractionalize an owned artwork into ERC1155 tokens.
 * 10. `buyArtworkFraction(uint256 _fractionalArtworkId, uint256 _fractionId, uint256 _amount)`: Allows members to buy fractions of fractionalized artwork.
 * 11. `contributeToTreasury()`: Allows anyone to contribute ETH to the collective's treasury.
 * 12. `withdrawFromTreasury(address _recipient, uint256 _amount)`: Admin function to withdraw funds from the treasury.
 * 13. `setArtistRoyalty(uint256 _artworkId, uint256 _royaltyPercentage)`: Admin function to set a secondary sale royalty for an artwork.
 * 14. `payoutArtistRoyalty(uint256 _artworkId)`: Function to pay out accumulated royalties to the artist. (Triggered upon secondary sale - *Conceptual, requires external marketplace integration in real-world*)
 * 15. `reportDispute(uint256 _artworkId, string _disputeDescription)`: Allows members to report disputes related to artwork.
 * 16. `resolveDispute(uint256 _disputeId, string _resolutionDetails)`: Admin function to resolve reported disputes.
 * 17. `stakeMembershipNFT()`: Allows members to stake their Membership NFTs for potential rewards or governance power. (Conceptual staking)
 * 18. `unstakeMembershipNFT()`: Allows members to unstake their Membership NFTs.
 * 19. `getArtworkDetails(uint256 _artworkId)`:  View function to retrieve details of a specific artwork.
 * 20. `getExhibitionDetails(uint256 _exhibitionId)`: View function to retrieve details of a specific exhibition.
 * 21. `getMemberDetails(address _memberAddress)`: View function to retrieve details of a collective member.
 * 22. `proposeInsuranceForArtwork(uint256 _artworkId, uint256 _insuranceValue)`: Allows members to propose insurance for an artwork. (Conceptual - requires external insurance oracle/integration in real-world)
 * 23. `voteOnInsuranceProposal(uint256 _insuranceProposalId, bool _vote)`: Members vote on insurance proposals.
 * 24. `executeInsuranceAcquisition(uint256 _insuranceProposalId)`: Admin function to execute approved insurance if vote passes. (Conceptual - requires external insurance oracle/integration in real-world)
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedAutonomousArtCollective is Ownable, ERC721, ERC1155, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Enums
    enum ProposalStatus { Pending, Approved, Rejected }
    enum VoteStatus { Pending, Passed, Failed }
    enum DisputeStatus { Open, Resolved }

    // Structs
    struct ArtistApplication {
        address artistAddress;
        string artistStatement;
        bool approved;
    }

    struct Artwork {
        uint256 id;
        address artistAddress;
        string title;
        string description;
        string cid; // CID from decentralized storage (IPFS, Arweave, etc.)
        uint256 acquisitionPrice;
        ProposalStatus proposalStatus;
        uint256 royaltyPercentage;
        bool insured;
    }

    struct ArtworkProposal {
        uint256 id;
        uint256 artworkId;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct Exhibition {
        uint256 id;
        string title;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256[] artworkIds;
    }

    struct MembershipNFTMetadata {
        string name;
        string description;
        string image; // Link to image, potentially IPFS CID
        // Add more attributes as needed
    }

    struct Dispute {
        uint256 id;
        uint256 artworkId;
        string description;
        DisputeStatus status;
        string resolutionDetails;
    }

    struct InsuranceProposal {
        uint256 id;
        uint256 artworkId;
        uint256 insuranceValue;
        ProposalStatus status; // Using ProposalStatus enum for insurance proposals as well
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct Member {
        address memberAddress;
        bool isArtist;
        bool isActiveMember; // Example of activity status
        uint256 reputationScore;
    }


    // State Variables
    Counters.Counter private _artworkIdCounter;
    Counters.Counter private _proposalIdCounter;
    Counters.Counter private _exhibitionIdCounter;
    Counters.Counter private _membershipNftIdCounter;
    Counters.Counter private _fractionalArtworkIdCounter;
    Counters.Counter private _disputeIdCounter;
    Counters.Counter private _insuranceProposalIdCounter;

    mapping(address => ArtistApplication) public artistApplications;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => uint256[]) public exhibitionArtworks; // Mapping exhibitionId to array of artworkIds
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => InsuranceProposal) public insuranceProposals;
    mapping(address => Member) public members;
    mapping(uint256 => uint256) public fractionalArtworkToOriginalArtwork; // Map fractional artwork ID to original artwork ID

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public votingQuorumPercentage = 50; // Default quorum percentage for proposals (50%)
    uint256 public membershipNFTSupply = 0; // Total supply of Membership NFTs minted
    uint256 public membershipNFTPrice = 0.01 ether; // Price to mint Membership NFT (can be dynamic)

    // Events
    event ArtistApplicationSubmitted(address artistAddress, string artistStatement);
    event ArtistApproved(address artistAddress);
    event ArtworkProposed(uint256 proposalId, uint256 artworkId, address artistAddress, string artworkTitle);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ArtworkAcquired(uint256 artworkId, address artistAddress, uint256 price);
    event ExhibitionCreated(uint256 exhibitionId, string title);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artworkId);
    event MembershipNFTMinted(uint256 tokenId, address minter);
    event ArtworkFractionalized(uint256 fractionalArtworkId, uint256 originalArtworkId, uint256 numberOfFractions);
    event ArtworkFractionBought(uint256 fractionalArtworkId, uint256 fractionId, address buyer, uint256 amount);
    event TreasuryContribution(address contributor, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event RoyaltySet(uint256 artworkId, uint256 royaltyPercentage);
    event RoyaltyPaid(uint256 artworkId, address artistAddress, uint256 amount);
    event DisputeReported(uint256 disputeId, uint256 artworkId, address reporter, string description);
    event DisputeResolved(uint256 disputeId, string resolutionDetails);
    event InsuranceProposed(uint256 insuranceProposalId, uint256 artworkId, uint256 insuranceValue);
    event InsuranceVoteCast(uint256 insuranceProposalId, address voter, bool vote);
    event InsuranceAcquired(uint256 artworkId);
    event MembershipNFTStaked(uint256 tokenId, address staker);
    event MembershipNFTUnstaked(uint256 tokenId, address unstaker);


    constructor() ERC721("DAAC Membership NFT", "DAACNFT") ERC1155("ipfs://daac-fraction-metadata/{id}.json") {
        // Initialize contract, set owner in Ownable constructor
    }

    // --- Membership Functions ---

    /// @dev Allows artists to apply to join the collective.
    /// @param _artistStatement A statement from the artist about their work and why they want to join.
    function joinCollective(string memory _artistStatement) external {
        require(artistApplications[msg.sender].artistAddress == address(0), "Application already submitted.");
        artistApplications[msg.sender] = ArtistApplication({
            artistAddress: msg.sender,
            artistStatement: _artistStatement,
            approved: false
        });
        emit ArtistApplicationSubmitted(msg.sender, _artistStatement);
    }

    /// @dev Admin function to approve a pending artist application.
    /// @param _artist The address of the artist to approve.
    function approveArtist(address _artist) external onlyOwner {
        require(artistApplications[_artist].artistAddress != address(0), "No application found for this address.");
        require(!artistApplications[_artist].approved, "Artist already approved.");
        artistApplications[_artist].approved = true;
        members[_artist] = Member({
            memberAddress: _artist,
            isArtist: true,
            isActiveMember: true, // Initially set as active
            reputationScore: 0 // Starting reputation
        });
        emit ArtistApproved(_artist);
    }

    // --- Artwork Proposal and Acquisition ---

    /// @dev Artists propose their artwork for acquisition by the collective.
    /// @param _artworkTitle Title of the artwork.
    /// @param _artworkDescription Description of the artwork.
    /// @param _artworkCID CID (Content Identifier) of the artwork on decentralized storage.
    /// @param _proposedPrice Proposed acquisition price in ETH.
    function submitArtworkProposal(
        string memory _artworkTitle,
        string memory _artworkDescription,
        string memory _artworkCID,
        uint256 _proposedPrice
    ) external {
        require(members[msg.sender].isArtist, "Only approved artists can submit artwork proposals.");
        _artworkIdCounter.increment();
        uint256 artworkId = _artworkIdCounter.current();
        artworks[artworkId] = Artwork({
            id: artworkId,
            artistAddress: msg.sender,
            title: _artworkTitle,
            description: _artworkDescription,
            cid: _artworkCID,
            acquisitionPrice: _proposedPrice,
            proposalStatus: ProposalStatus.Pending,
            royaltyPercentage: 0, // Default royalty
            insured: false
        });

        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        artworkProposals[proposalId] = ArtworkProposal({
            id: proposalId,
            artworkId: artworkId,
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp + votingDuration
        });

        emit ArtworkProposed(proposalId, artworkId, msg.sender, _artworkTitle);
    }

    /// @dev Members vote on an artwork proposal.
    /// @param _proposalId ID of the artwork proposal.
    /// @param _vote True for yes, false for no.
    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) external {
        require(members[msg.sender].isActiveMember, "Only active members can vote.");
        require(artworkProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.timestamp < artworkProposals[_proposalId].votingEndTime, "Voting period has ended.");

        if (_vote) {
            artworkProposals[_proposalId].yesVotes++;
        } else {
            artworkProposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);
    }

    /// @dev Executes the acquisition of an artwork if the proposal is approved and funds are available.
    /// @param _proposalId ID of the artwork proposal.
    function executeArtworkAcquisition(uint256 _proposalId) external onlyOwner nonReentrant {
        require(artworkProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.timestamp >= artworkProposals[_proposalId].votingEndTime, "Voting period has not ended yet.");

        uint256 totalVotes = artworkProposals[_proposalId].yesVotes + artworkProposals[_proposalId].noVotes;
        uint256 quorum = (totalVotes * 100) / (getTotalActiveMembers() == 0 ? 1 : getTotalActiveMembers()); // Avoid division by zero
        require(quorum >= votingQuorumPercentage, "Quorum not reached.");

        if (artworkProposals[_proposalId].yesVotes > artworkProposals[_proposalId].noVotes) {
            uint256 artworkId = artworkProposals[_proposalId].artworkId;
            uint256 acquisitionPrice = artworks[artworkId].acquisitionPrice;

            require(address(this).balance >= acquisitionPrice, "Insufficient funds in treasury.");

            artworkProposals[_proposalId].status = ProposalStatus.Approved;
            artworks[artworkId].proposalStatus = ProposalStatus.Approved;

            payable(artworks[artworkId].artistAddress).transfer(acquisitionPrice);
            emit ArtworkAcquired(artworkId, artworks[artworkId].artistAddress, acquisitionPrice);
        } else {
            artworkProposals[_proposalId].status = ProposalStatus.Rejected;
            artworks[artworkProposal[_proposalId].artworkId].proposalStatus = ProposalStatus.Rejected;
        }
    }

    // --- Exhibition Functions ---

    /// @dev Admin function to create a virtual exhibition.
    /// @param _exhibitionTitle Title of the exhibition.
    /// @param _exhibitionDescription Description of the exhibition.
    /// @param _startTime Unix timestamp for exhibition start time.
    /// @param _endTime Unix timestamp for exhibition end time.
    function createExhibition(
        string memory _exhibitionTitle,
        string memory _exhibitionDescription,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        _exhibitionIdCounter.increment();
        uint256 exhibitionId = _exhibitionIdCounter.current();
        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            title: _exhibitionTitle,
            description: _exhibitionDescription,
            startTime: _startTime,
            endTime: _endTime,
            artworkIds: new uint256[](0) // Initialize with empty array
        });
        emit ExhibitionCreated(exhibitionId, _exhibitionTitle);
    }

    /// @dev Admin function to add artwork to an exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @param _artworkId ID of the artwork to add.
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artworkId) external onlyOwner {
        require(exhibitions[_exhibitionId].id != 0, "Exhibition not found.");
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].proposalStatus == ProposalStatus.Approved, "Artwork not found or not approved.");

        exhibitions[_exhibitionId].artworkIds.push(_artworkId);
        emit ArtAddedToExhibition(_exhibitionId, _artworkId);
    }

    // --- Membership NFT Functions ---

    /// @dev Allows approved artists and active members to mint a collectible Membership NFT.
    /// @param _nftMetadataURI URI pointing to the NFT metadata (e.g., IPFS).
    function mintMembershipNFT(string memory _nftMetadataURI) external payable {
        require(members[msg.sender].isActiveMember, "Only active members can mint Membership NFTs.");
        require(msg.value >= membershipNFTPrice, "Insufficient funds sent for Membership NFT minting.");

        _membershipNftIdCounter.increment();
        uint256 tokenId = _membershipNftIdCounter.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, _nftMetadataURI);
        membershipNFTSupply++;
        emit MembershipNFTMinted(tokenId, msg.sender);

        // Optionally, send minting fee to treasury
        if (membershipNFTPrice > 0) {
            payable(owner()).transfer(msg.value); // Or to a designated treasury address
        }
    }

    // --- Artwork Fractionalization Functions ---

    /// @dev Allows the collective to fractionalize an owned artwork into ERC1155 tokens.
    /// @param _artworkId ID of the original artwork to fractionalize.
    /// @param _numberOfFractions Number of fractions to create.
    function fractionalizeArtwork(uint256 _artworkId, uint256 _numberOfFractions) external onlyOwner {
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].proposalStatus == ProposalStatus.Approved, "Artwork not found or not owned by collective.");
        _fractionalArtworkIdCounter.increment();
        uint256 fractionalArtworkId = _fractionalArtworkIdCounter.current();
        fractionalArtworkToOriginalArtwork[fractionalArtworkId] = _artworkId;

        // Mint ERC1155 tokens representing fractions
        _mint(address(this), fractionalArtworkId, _numberOfFractions, ""); // Mint to contract itself initially

        emit ArtworkFractionalized(fractionalArtworkId, _artworkId, _numberOfFractions);
    }

    /// @dev Allows members to buy fractions of fractionalized artwork.
    /// @param _fractionalArtworkId ID of the fractionalized artwork (ERC1155 token ID).
    /// @param _fractionId (Conceptual - Not directly used in ERC1155 minting but can be used for metadata or tracking if needed).
    /// @param _amount Number of fractions to buy.
    function buyArtworkFraction(uint256 _fractionalArtworkId, uint256 _fractionId, uint256 _amount) external payable {
        // Conceptual - Price mechanism needs to be defined (e.g., fixed price, auction, bonding curve)
        uint256 pricePerFraction = 0.001 ether; // Example fixed price per fraction
        uint256 totalPrice = pricePerFraction * _amount;
        require(msg.value >= totalPrice, "Insufficient funds sent for fraction purchase.");

        // Transfer fractions from contract to buyer
        _safeTransferFrom(address(this), msg.sender, _fractionalArtworkId, _amount, "");

        emit ArtworkFractionBought(_fractionalArtworkId, _fractionId, msg.sender, _amount);

        // Send funds to treasury
        payable(owner()).transfer(msg.value); // Or to a designated treasury address
    }


    // --- Treasury Functions ---

    /// @dev Allows anyone to contribute ETH to the collective's treasury.
    function contributeToTreasury() external payable {
        emit TreasuryContribution(msg.sender, msg.value);
    }

    /// @dev Admin function to withdraw funds from the treasury.
    /// @param _recipient Address to send the funds to.
    /// @param _amount Amount of ETH to withdraw.
    function withdrawFromTreasury(address _recipient, uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient funds in treasury.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    // --- Royalty Functions ---

    /// @dev Admin function to set a secondary sale royalty percentage for an artwork.
    /// @param _artworkId ID of the artwork.
    /// @param _royaltyPercentage Royalty percentage (e.g., 5 for 5%).
    function setArtistRoyalty(uint256 _artworkId, uint256 _royaltyPercentage) external onlyOwner {
        require(artworks[_artworkId].id != 0, "Artwork not found.");
        require(_royaltyPercentage <= 100, "Royalty percentage cannot exceed 100.");
        artworks[_artworkId].royaltyPercentage = _royaltyPercentage;
        emit RoyaltySet(_artworkId, _royaltyPercentage);
    }

    /// @dev Function to pay out accumulated royalties to the artist. (Conceptual - Triggered upon secondary sale - requires external marketplace integration in real-world)
    /// @param _artworkId ID of the artwork.
    function payoutArtistRoyalty(uint256 _artworkId) external onlyOwner {
        // Conceptual - In a real-world scenario, this would be triggered by an event from an external NFT marketplace
        // indicating a secondary sale.  The marketplace would need to somehow interact with this contract
        // or provide data for verification.

        // For demonstration purposes, let's assume we have a way to track secondary sales and accumulated royalties.
        // In a real system, this would be significantly more complex and likely involve off-chain indexing and oracles.

        // Placeholder logic (simplified and conceptual):
        uint256 _secondarySalePrice = 1 ether; // Example secondary sale price - would come from external source
        uint256 royaltyPercentage = artworks[_artworkId].royaltyPercentage;
        uint256 royaltyAmount = (_secondarySalePrice * royaltyPercentage) / 100;

        require(address(this).balance >= royaltyAmount, "Insufficient funds in treasury for royalty payout.");

        payable(artworks[_artworkId].artistAddress).transfer(royaltyAmount);
        emit RoyaltyPaid(_artworkId, artworks[_artworkId].artistAddress, royaltyAmount);

        // In a real implementation, you would need to:
        // 1. Integrate with NFT marketplaces to track secondary sales.
        // 2. Securely verify secondary sale information (potentially using oracles or trusted data feeds).
        // 3. Manage accumulated royalty balances for each artwork (potentially in state variables).
    }

    // --- Dispute Resolution Functions ---

    /// @dev Allows members to report disputes related to artwork.
    /// @param _artworkId ID of the artwork in dispute.
    /// @param _disputeDescription Description of the dispute.
    function reportDispute(uint256 _artworkId, string memory _disputeDescription) external {
        require(artworks[_artworkId].id != 0, "Artwork not found.");
        _disputeIdCounter.increment();
        uint256 disputeId = _disputeIdCounter.current();
        disputes[disputeId] = Dispute({
            id: disputeId,
            artworkId: _artworkId,
            description: _disputeDescription,
            status: DisputeStatus.Open,
            resolutionDetails: ""
        });
        emit DisputeReported(disputeId, _artworkId, msg.sender, _disputeDescription);
    }

    /// @dev Admin function to resolve reported disputes.
    /// @param _disputeId ID of the dispute to resolve.
    /// @param _resolutionDetails Details of the dispute resolution.
    function resolveDispute(uint256 _disputeId, string memory _resolutionDetails) external onlyOwner {
        require(disputes[_disputeId].id != 0 && disputes[_disputeId].status == DisputeStatus.Open, "Dispute not found or already resolved.");
        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].resolutionDetails = _resolutionDetails;
        emit DisputeResolved(_disputeId, _resolutionDetails);
    }

    // --- Membership NFT Staking (Conceptual) ---

    /// @dev Allows members to stake their Membership NFTs for potential rewards or governance power. (Conceptual staking)
    function stakeMembershipNFT() external {
        // Conceptual staking - In a real system, you would need to manage staking state, rewards, etc.
        // For this example, we just record that the NFT is staked.
        uint256 tokenId = balanceOf(msg.sender); // Assuming 1 Membership NFT per member for simplicity
        require(tokenId > 0, "No Membership NFT found to stake.");
        // In a real staking implementation, you'd need to track which tokens are staked, for how long, etc.

        emit MembershipNFTStaked(tokenId, msg.sender);
    }

    /// @dev Allows members to unstake their Membership NFTs.
    function unstakeMembershipNFT() external {
        // Conceptual unstaking - Reverse of stakeMembershipNFT
        uint256 tokenId = balanceOf(msg.sender); // Assuming 1 Membership NFT per member for simplicity
        require(tokenId > 0, "No Membership NFT found to unstake.");

        emit MembershipNFTUnstaked(tokenId, msg.sender);
    }

    // --- Insurance Proposal Functions (Conceptual - Requires external oracle/integration) ---

    /// @dev Allows members to propose insurance for an artwork.
    /// @param _artworkId ID of the artwork to insure.
    /// @param _insuranceValue Value to insure the artwork for.
    function proposeInsuranceForArtwork(uint256 _artworkId, uint256 _insuranceValue) external {
        require(members[msg.sender].isActiveMember, "Only active members can propose insurance.");
        require(artworks[_artworkId].id != 0 && artworks[_artworkId].proposalStatus == ProposalStatus.Approved && !artworks[_artworkId].insured, "Artwork not found, not approved, or already insured.");

        _insuranceProposalIdCounter.increment();
        uint256 insuranceProposalId = _insuranceProposalIdCounter.current();
        insuranceProposals[insuranceProposalId] = InsuranceProposal({
            id: insuranceProposalId,
            artworkId: _artworkId,
            insuranceValue: _insuranceValue,
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.timestamp + votingDuration
        });
        emit InsuranceProposed(insuranceProposalId, _artworkId, _insuranceValue);
    }

    /// @dev Members vote on an insurance proposal.
    /// @param _insuranceProposalId ID of the insurance proposal.
    /// @param _vote True for yes, false for no.
    function voteOnInsuranceProposal(uint256 _insuranceProposalId, bool _vote) external {
        require(members[msg.sender].isActiveMember, "Only active members can vote.");
        require(insuranceProposals[_insuranceProposalId].status == ProposalStatus.Pending, "Insurance proposal is not pending.");
        require(block.timestamp < insuranceProposals[_insuranceProposalId].votingEndTime, "Voting period has ended.");

        if (_vote) {
            insuranceProposals[_insuranceProposalId].yesVotes++;
        } else {
            insuranceProposals[_insuranceProposalId].noVotes++;
        }
        emit InsuranceVoteCast(_insuranceProposalId, msg.sender, _vote);
    }

    /// @dev Admin function to execute approved insurance if vote passes. (Conceptual - requires external insurance oracle/integration in real-world)
    /// @param _insuranceProposalId ID of the insurance proposal.
    function executeInsuranceAcquisition(uint256 _insuranceProposalId) external onlyOwner nonReentrant {
        require(insuranceProposals[_insuranceProposalId].status == ProposalStatus.Pending, "Insurance proposal is not pending.");
        require(block.timestamp >= insuranceProposals[_insuranceProposalId].votingEndTime, "Voting period has not ended yet.");

        uint256 totalVotes = insuranceProposals[_insuranceProposalId].yesVotes + insuranceProposals[_insuranceProposalId].noVotes;
        uint256 quorum = (totalVotes * 100) / (getTotalActiveMembers() == 0 ? 1 : getTotalActiveMembers()); // Avoid division by zero
        require(quorum >= votingQuorumPercentage, "Quorum not reached for insurance proposal.");

        if (insuranceProposals[_insuranceProposalId].yesVotes > insuranceProposals[_insuranceProposalId].noVotes) {
            uint256 artworkId = insuranceProposals[_insuranceProposalId].artworkId;
            // In a real system, you would integrate with an insurance provider (oracle, API, etc.) here
            // to purchase insurance policy. This is a conceptual example, so we just mark it as insured.
            artworks[artworkId].insured = true;
            insuranceProposals[_insuranceProposalId].status = ProposalStatus.Approved;
            emit InsuranceAcquired(artworkId);
        } else {
            insuranceProposals[_insuranceProposalId].status = ProposalStatus.Rejected;
        }
    }


    // --- View Functions ---

    /// @dev View function to retrieve details of a specific artwork.
    /// @param _artworkId ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @dev View function to retrieve details of a specific exhibition.
    /// @param _exhibitionId ID of the exhibition.
    /// @return Exhibition struct containing exhibition details.
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// @dev View function to retrieve details of a collective member.
    /// @param _memberAddress Address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _memberAddress) external view returns (Member memory) {
        return members[_memberAddress];
    }

    /// @dev Get total active members count.
    function getTotalActiveMembers() public view returns (uint256) {
        uint256 activeMemberCount = 0;
        address[] memory allMembers = getMemberAddresses();
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]].isActiveMember) {
                activeMemberCount++;
            }
        }
        return activeMemberCount;
    }

    /// @dev Helper function to get all member addresses (for iteration purposes).
    function getMemberAddresses() public view returns (address[] memory) {
        address[] memory memberAddresses = new address[](membershipNFTSupply); // Approximation, might have gaps if membership is revoked
        uint256 index = 0;
        for (uint256 i = 1; i <= _membershipNftIdCounter.current(); i++) {
            address ownerAddress = ownerOf(i);
            if (ownerAddress != address(0)) { // Check if NFT exists and has an owner
                memberAddresses[index] = ownerAddress;
                index++;
            }
        }
        // Resize array to actual number of members (remove empty slots if any)
        assembly {
            mstore(memberAddresses, index) // Update length of the array
        }
        return memberAddresses;
    }

    // --- Admin Functions (already using Ownable modifier where applicable) ---
    // (Admin functions like approveArtist, createExhibition, addArtToExhibition, withdrawFromTreasury, setArtistRoyalty, resolveDispute, executeArtworkAcquisition, executeInsuranceAcquisition are already defined)

    // --- ERC721 and ERC1155 Support ---
    // Inherited from OpenZeppelin contracts, no need to redefine basic functions like transfer, balanceOf, etc.
    // _setTokenURI for ERC721 is used in mintMembershipNFT
    // _mint for ERC1155 is used in fractionalizeArtwork and _safeTransferFrom in buyArtworkFraction
}
```