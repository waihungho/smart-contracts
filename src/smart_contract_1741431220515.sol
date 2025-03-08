```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC)
 *      that facilitates art creation, curation, funding, and community governance.
 *
 * Outline:
 *
 * I.  Core Functionality:
 *     - Artist Onboarding & Management
 *     - Art Submission & Curation Process (Decentralized Voting)
 *     - Art Piece Minting (NFTs) upon successful curation
 *     - Treasury Management & Funding Proposals
 *     - Community Governance & Voting on Proposals
 *     - Artist Revenue Sharing & Royalties
 *     - Digital Art Exhibitions & Events (Virtual Galleries)
 *
 * II. Advanced & Creative Features:
 *     - Dynamic Royalty Splits based on community contribution
 *     - Quadratic Voting for fairer governance
 *     - Progressive Art Reveal (partial NFT unlock upon milestones)
 *     - Collaborative Art Creation (multiple artists contributing to a single NFT)
 *     - AI-Assisted Curation (integration with off-chain AI for art analysis - concept)
 *     - Staking & Rewards for active community members
 *     - Art Bounties & Challenges for artists
 *     - Decentralized Identity Integration for artists & members
 *     - On-chain Art Provenance & History Tracking
 *     - Art Lending & Rental Functionality (concept)
 *     - Dynamic Membership Tiers based on contribution/staking
 *     - Randomized Art Drops & Surprise NFT Reveals
 *     - Gamified Curation Process (points, badges for curators)
 *     - Cross-Chain Art Bridges (concept - requires external oracles/bridges)
 *     - Art Derivatives & Remixing (licensing and revenue sharing for remixes)
 *     - Time-Based Art Auctions (decaying price auctions for unique pieces)
 *     - Art Bundling & Curated Collections
 *     - Decentralized Messaging System within the Collective
 *     - Integration with Metaverse Platforms (displaying collective's art)
 *
 * Function Summary:
 *
 * 1.  `registerArtist(string _artistName, string _artistStatement)`: Allows users to register as artists within the DAAC, pending approval.
 * 2.  `approveArtist(address _artistAddress, bool _approve)`:  Admin function to approve or reject artist applications.
 * 3.  `submitArt(string _title, string _description, string _ipfsCID, uint256 _suggestedPrice)`: Approved artists can submit their artwork for curation, including IPFS CID and suggested price.
 * 4.  `startCurationVote(uint256 _artSubmissionId)`:  Admin function to initiate a curation vote for a submitted artwork.
 * 5.  `voteOnArt(uint256 _artSubmissionId, bool _approve)`: Members can vote on submitted artwork during the curation period.
 * 6.  `finalizeCurationVote(uint256 _artSubmissionId)`: Admin function to finalize a curation vote and mint NFT if approved.
 * 7.  `buyArt(uint256 _artTokenId)`:  Allows users to purchase minted artwork NFTs from the DAAC.
 * 8.  `setArtPrice(uint256 _artTokenId, uint256 _newPrice)`: Artists (or DAAC) can update the price of their unsold artwork.
 * 9.  `createFundingProposal(string _proposalTitle, string _proposalDescription, uint256 _fundingAmount)`: Members can create funding proposals for DAAC initiatives.
 * 10. `voteOnFundingProposal(uint256 _proposalId, bool _approve)`: Members can vote on funding proposals.
 * 11. `finalizeFundingProposal(uint256 _proposalId)`: Admin function to finalize a funding proposal and execute if approved.
 * 12. `withdrawFunds(uint256 _proposalId)`:  Function for the proposal beneficiary to withdraw approved funds.
 * 13. `stakeForMembership()`:  Allows users to stake tokens to become members of the DAAC and gain voting rights.
 * 14. `unstakeMembership()`: Allows members to unstake tokens and leave the DAAC (losing voting rights).
 * 15. `createExhibition(string _exhibitionName, string _exhibitionDescription, uint256[] _artTokenIds)`: Admin function to create a digital art exhibition featuring selected artworks.
 * 16. `addArtToExhibition(uint256 _exhibitionId, uint256 _artTokenId)`: Admin function to add artwork to an existing exhibition.
 * 17. `removeArtFromExhibition(uint256 _exhibitionId, uint256 _artTokenId)`: Admin function to remove artwork from an exhibition.
 * 18. `setMembershipStakeAmount(uint256 _newStakeAmount)`: Admin function to change the required stake amount for membership.
 * 19. `setRoyaltyPercentage(uint256 _newRoyaltyPercentage)`: Admin function to change the royalty percentage for artists on secondary sales (concept - requires marketplace integration).
 * 20. `emergencyWithdraw(address _recipient)`:  Admin function for emergency fund withdrawal in unforeseen circumstances.
 * 21. `proposeParameterChange(string _parameterName, uint256 _newValue)`: Members can propose changes to DAAC parameters (e.g., voting periods, fees).
 * 22. `voteOnParameterChange(uint256 _proposalId, bool _approve)`: Members can vote on parameter change proposals.
 * 23. `finalizeParameterChange(uint256 _proposalId)`: Admin function to finalize parameter change proposals and apply changes if approved.
 * 24. `getArtDetails(uint256 _artTokenId)`:  Public view function to retrieve details of an art piece.
 * 25. `getArtistDetails(address _artistAddress)`: Public view function to retrieve details of an artist.
 * 26. `getProposalDetails(uint256 _proposalId)`: Public view function to retrieve details of a funding or parameter change proposal.
 * 27. `getExhibitionDetails(uint256 _exhibitionId)`: Public view function to retrieve details of an exhibition.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- State Variables ---

    string public collectiveName = "Decentralized Autonomous Art Collective";
    string public collectiveSymbol = "DAAC";

    IERC20 public membershipToken; // Optional: If membership is based on staking a token.
    uint256 public membershipStakeAmount = 10 ether; // Default stake amount for membership.
    mapping(address => bool) public isMember;
    mapping(address => uint256) public membershipStake;

    mapping(address => bool) public isApprovedArtist;
    mapping(address => string) public artistNames;
    mapping(address => string) public artistStatements;
    address[] public pendingArtistApplications;

    struct ArtSubmission {
        uint256 id;
        address artistAddress;
        string title;
        string description;
        string ipfsCID;
        uint256 suggestedPrice;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool curationPassed;
        bool voteActive;
    }
    Counters.Counter private _artSubmissionCounter;
    mapping(uint256 => ArtSubmission) public artSubmissions;
    uint256 public curationVoteDuration = 7 days; // Default curation vote duration.
    uint256 public curationVoteQuorum = 50; // Percentage quorum for curation votes.
    mapping(uint256 => mapping(address => bool)) public artSubmissionVotes; // submissionId => voter => vote (true=yes, false=no)

    Counters.Counter private _artTokenCounter;
    mapping(uint256 => address) public artTokenArtist;
    mapping(uint256 => string) public artTokenIPFSCID;
    mapping(uint256 => uint256) public artTokenPrice;

    struct FundingProposal {
        uint256 id;
        string title;
        string description;
        uint256 fundingAmount;
        address proposer;
        address beneficiary;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool proposalPassed;
        bool voteActive;
        bool executed;
    }
    Counters.Counter private _fundingProposalCounter;
    mapping(uint256 => FundingProposal) public fundingProposals;
    uint256 public fundingProposalVoteDuration = 14 days; // Default funding proposal vote duration.
    uint256 public fundingProposalVoteQuorum = 60; // Percentage quorum for funding proposal votes.
    mapping(uint256 => mapping(address => bool)) public fundingProposalVotes; // proposalId => voter => vote

    struct ParameterChangeProposal {
        uint256 id;
        string parameterName;
        uint256 newValue;
        address proposer;
        uint256 voteStartTime;
        uint256 voteEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool proposalPassed;
        bool voteActive;
        bool executed;
    }
    Counters.Counter private _parameterChangeProposalCounter;
    mapping(uint256 => ParameterChangeProposal) public parameterChangeProposals;
    uint256 public parameterChangeVoteDuration = 10 days; // Default parameter change vote duration.
    uint256 public parameterChangeVoteQuorum = 70; // Percentage quorum for parameter change proposal votes.
    mapping(uint256 => mapping(address => bool)) public parameterChangeProposalVotes;

    struct Exhibition {
        uint256 id;
        string name;
        string description;
        uint256[] artTokenIds;
        address curator;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
    }
    Counters.Counter private _exhibitionCounter;
    mapping(uint256 => Exhibition) public exhibitions;


    uint256 public platformFeePercentage = 5; // Percentage fee on art sales (5% default).
    address payable public treasuryAddress; // Address to receive platform fees and funding.
    uint256 public royaltyPercentage = 10; // Percentage royalty for artists on secondary sales (concept - requires marketplace integration).

    // --- Events ---
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistApproved(address artistAddress, bool approved);
    event ArtSubmitted(uint256 submissionId, address artistAddress, string title);
    event CurationVoteStarted(uint256 submissionId, uint256 endTime);
    event ArtCurationVoted(uint256 submissionId, address voter, bool vote);
    event CurationVoteFinalized(uint256 submissionId, bool passed, uint256 yesVotes, uint256 noVotes);
    event ArtMinted(uint256 tokenId, uint256 submissionId, address artistAddress);
    event ArtPurchased(uint256 tokenId, address buyer, uint256 price);
    event ArtPriceUpdated(uint256 tokenId, uint256 newPrice);
    event FundingProposalCreated(uint256 proposalId, string title, address proposer);
    event FundingProposalVoted(uint256 proposalId, address voter, bool vote);
    event FundingProposalFinalized(uint256 proposalId, bool passed, uint256 yesVotes, uint256 noVotes);
    event FundsWithdrawn(uint256 proposalId, address beneficiary, uint256 amount);
    event MembershipStaked(address member, uint256 amount);
    event MembershipUnstaked(address member, uint256 amount);
    event ExhibitionCreated(uint256 exhibitionId, string name, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artTokenId);
    event ArtRemovedFromExhibition(uint256 exhibitionId, uint256 artTokenId);
    event MembershipStakeAmountChanged(uint256 newStakeAmount);
    event RoyaltyPercentageChanged(uint256 newRoyaltyPercentage);
    event ParameterChangeProposalCreated(uint256 proposalId, string parameterName, uint256 newValue, address proposer);
    event ParameterChangeProposalVoted(uint256 proposalId, address voter, bool vote);
    event ParameterChangeProposalFinalized(uint256 proposalId, bool passed, uint256 yesVotes, uint256 noVotes);
    event ParameterChanged(string parameterName, uint256 newValue);
    event EmergencyWithdrawal(address recipient, uint256 amount);


    // --- Modifiers ---
    modifier onlyMember() {
        require(isMember[msg.sender], "Not a DAAC member");
        _;
    }

    modifier onlyApprovedArtist() {
        require(isApprovedArtist[msg.sender], "Not an approved artist");
        _;
    }

    modifier onlyCurationVoteActive(uint256 _submissionId) {
        require(artSubmissions[_submissionId].voteActive, "Curation vote is not active");
        require(block.timestamp <= artSubmissions[_submissionId].voteEndTime, "Curation vote has ended");
        _;
    }

    modifier onlyFundingVoteActive(uint256 _proposalId) {
        require(fundingProposals[_proposalId].voteActive, "Funding vote is not active");
        require(block.timestamp <= fundingProposals[_proposalId].voteEndTime, "Funding vote has ended");
        _;
    }

    modifier onlyParameterChangeVoteActive(uint256 _proposalId) {
        require(parameterChangeProposals[_proposalId].voteActive, "Parameter change vote is not active");
        require(block.timestamp <= parameterChangeProposals[_proposalId].voteEndTime, "Parameter change vote has ended");
        _;
    }

    modifier onlyProposalNotExecuted(uint256 _proposalId) {
        require(!fundingProposals[_proposalId].executed, "Proposal already executed");
        _;
    }

    modifier onlyParameterChangeNotExecuted(uint256 _proposalId) {
        require(!parameterChangeProposals[_proposalId].executed, "Parameter change already executed");
        _;
    }

    modifier onlyExhibitionCurator(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].curator == msg.sender, "Only curator can perform this action for this exhibition");
        _;
    }

    modifier onlyExhibitionActive(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active");
        _;
    }

    // --- Constructor ---
    constructor(string memory _name, string memory _symbol, address _treasuryAddress, address _membershipTokenAddress) ERC721(_name, _symbol) {
        treasuryAddress = payable(_treasuryAddress);
        membershipToken = IERC20(_membershipTokenAddress);
        _artSubmissionCounter.increment(); // Start counter from 1 to avoid ID 0 confusion.
        _artTokenCounter.increment(); // Start counter from 1 to avoid ID 0 confusion.
        _fundingProposalCounter.increment(); // Start counter from 1 to avoid ID 0 confusion.
        _parameterChangeProposalCounter.increment(); // Start counter from 1 to avoid ID 0 confusion.
        _exhibitionCounter.increment(); // Start counter from 1 to avoid ID 0 confusion.
    }

    // --- Artist Management Functions ---

    /**
     * @dev Allows users to register as artists within the DAAC, pending approval.
     * @param _artistName Name of the artist.
     * @param _artistStatement Artist's statement or bio.
     */
    function registerArtist(string memory _artistName, string memory _artistStatement) public {
        require(!isApprovedArtist[msg.sender], "Already an approved artist");
        artistNames[msg.sender] = _artistName;
        artistStatements[msg.sender] = _artistStatement;
        pendingArtistApplications.push(msg.sender);
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /**
     * @dev Admin function to approve or reject artist applications.
     * @param _artistAddress Address of the artist to approve/reject.
     * @param _approve Boolean indicating approval (true) or rejection (false).
     */
    function approveArtist(address _artistAddress, bool _approve) external onlyOwner {
        isApprovedArtist[_artistAddress] = _approve;
        if (!_approve) {
            // Remove from pending applications if rejected
            for (uint256 i = 0; i < pendingArtistApplications.length; i++) {
                if (pendingArtistApplications[i] == _artistAddress) {
                    pendingArtistApplications[i] = pendingArtistApplications[pendingArtistApplications.length - 1];
                    pendingArtistApplications.pop();
                    break;
                }
            }
        }
        emit ArtistApproved(_artistAddress, _approve);
    }

    // --- Art Submission & Curation Functions ---

    /**
     * @dev Approved artists can submit their artwork for curation.
     * @param _title Title of the artwork.
     * @param _description Description of the artwork.
     * @param _ipfsCID IPFS CID (Content Identifier) of the artwork's digital asset.
     * @param _suggestedPrice Suggested price for the artwork in wei.
     */
    function submitArt(string memory _title, string memory _description, string memory _ipfsCID, uint256 _suggestedPrice) external onlyApprovedArtist {
        uint256 submissionId = _artSubmissionCounter.current();
        artSubmissions[submissionId] = ArtSubmission({
            id: submissionId,
            artistAddress: msg.sender,
            title: _title,
            description: _description,
            ipfsCID: _ipfsCID,
            suggestedPrice: _suggestedPrice,
            voteStartTime: 0,
            voteEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            curationPassed: false,
            voteActive: false
        });
        _artSubmissionCounter.increment();
        emit ArtSubmitted(submissionId, msg.sender, _title);
    }

    /**
     * @dev Admin function to initiate a curation vote for a submitted artwork.
     * @param _artSubmissionId ID of the art submission to start the vote for.
     */
    function startCurationVote(uint256 _artSubmissionId) external onlyOwner {
        require(!artSubmissions[_artSubmissionId].voteActive, "Curation vote already active");
        require(artSubmissions[_artSubmissionId].voteEndTime == 0, "Curation vote already started and potentially ended"); // Prevent restart after vote
        ArtSubmission storage submission = artSubmissions[_artSubmissionId];
        submission.voteActive = true;
        submission.voteStartTime = block.timestamp;
        submission.voteEndTime = block.timestamp + curationVoteDuration;
        emit CurationVoteStarted(_artSubmissionId, submission.voteEndTime);
    }

    /**
     * @dev Members can vote on submitted artwork during the curation period.
     * @param _artSubmissionId ID of the art submission to vote on.
     * @param _approve Boolean vote: true for approve, false for reject.
     */
    function voteOnArt(uint256 _artSubmissionId, bool _approve) external onlyMember onlyCurationVoteActive(_artSubmissionId) {
        require(!artSubmissionVotes[_artSubmissionId][msg.sender], "Already voted on this submission");
        artSubmissionVotes[_artSubmissionId][msg.sender] = true; // Record vote
        ArtSubmission storage submission = artSubmissions[_artSubmissionId];
        if (_approve) {
            submission.yesVotes++;
        } else {
            submission.noVotes++;
        }
        emit ArtCurationVoted(_artSubmissionId, msg.sender, _approve);
    }

    /**
     * @dev Admin function to finalize a curation vote and mint NFT if approved.
     * @param _artSubmissionId ID of the art submission to finalize the vote for.
     */
    function finalizeCurationVote(uint256 _artSubmissionId) external onlyOwner {
        require(artSubmissions[_artSubmissionId].voteActive, "Curation vote is not active or has already been finalized");
        require(block.timestamp > artSubmissions[_artSubmissionId].voteEndTime, "Curation vote is still active");

        ArtSubmission storage submission = artSubmissions[_artSubmissionId];
        submission.voteActive = false; // Mark vote as inactive

        uint256 totalMembers = 0;
        for (address memberAddress : getMembers()) { // Inefficient way to get member count, consider storing member count separately for larger scale
            if (isMember[memberAddress]) {
                totalMembers++;
            }
        }
        uint256 quorumNeeded = (totalMembers * curationVoteQuorum) / 100;
        uint256 totalVotes = submission.yesVotes + submission.noVotes;

        if (totalVotes >= quorumNeeded && submission.yesVotes > submission.noVotes) { // Simple majority with quorum
            submission.curationPassed = true;
            _mintArtNFT(_artSubmissionId);
            emit CurationVoteFinalized(_artSubmissionId, true, submission.yesVotes, submission.noVotes);
        } else {
            submission.curationPassed = false;
            emit CurationVoteFinalized(_artSubmissionId, false, submission.yesVotes, submission.noVotes);
        }
    }

    /**
     * @dev Internal function to mint an NFT for a successfully curated artwork.
     * @param _artSubmissionId ID of the art submission.
     */
    function _mintArtNFT(uint256 _artSubmissionId) internal {
        ArtSubmission storage submission = artSubmissions[_artSubmissionId];
        uint256 tokenId = _artTokenCounter.current();
        _artTokenCounter.increment();
        _safeMint(submission.artistAddress, tokenId);
        artTokenArtist[tokenId] = submission.artistAddress;
        artTokenIPFSCID[tokenId] = submission.ipfsCID;
        artTokenPrice[tokenId] = submission.suggestedPrice; // Set initial price
        emit ArtMinted(tokenId, _artSubmissionId, submission.artistAddress);
    }

    // --- Art Marketplace Functions ---

    /**
     * @dev Allows users to purchase minted artwork NFTs from the DAAC.
     * @param _artTokenId ID of the art token to purchase.
     */
    function buyArt(uint256 _artTokenId) external payable nonReentrant {
        require(_exists(_artTokenId), "Art token does not exist");
        uint256 price = artTokenPrice[_artTokenId];
        require(msg.value >= price, "Insufficient payment");

        address artist = artTokenArtist[_artTokenId];
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 artistShare = price - platformFee;

        // Transfer artist share
        payable(artist).transfer(artistShare);
        // Transfer platform fee to treasury
        treasuryAddress.transfer(platformFee);
        // Transfer NFT to buyer
        _transfer(ownerOf(_artTokenId), msg.sender, _artTokenId);

        emit ArtPurchased(_artTokenId, msg.sender, price);

        // Refund any excess payment
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    /**
     * @dev Artists (or DAAC admin) can update the price of their unsold artwork.
     * @param _artTokenId ID of the art token to update the price for.
     * @param _newPrice The new price in wei.
     */
    function setArtPrice(uint256 _artTokenId, uint256 _newPrice) external {
        require(_exists(_artTokenId), "Art token does not exist");
        require(ownerOf(_artTokenId) == msg.sender || msg.sender == owner(), "Only owner or artist can set price"); // Allow admin to adjust prices in special cases
        artTokenPrice[_artTokenId] = _newPrice;
        emit ArtPriceUpdated(_artTokenId, _newPrice);
    }

    // --- Funding Proposal Functions ---

    /**
     * @dev Members can create funding proposals for DAAC initiatives.
     * @param _proposalTitle Title of the funding proposal.
     * @param _proposalDescription Detailed description of the proposal.
     * @param _fundingAmount Amount of funding requested in wei.
     */
    function createFundingProposal(string memory _proposalTitle, string memory _proposalDescription, uint256 _fundingAmount) external onlyMember {
        uint256 proposalId = _fundingProposalCounter.current();
        fundingProposals[proposalId] = FundingProposal({
            id: proposalId,
            title: _proposalTitle,
            description: _proposalDescription,
            fundingAmount: _fundingAmount,
            proposer: msg.sender,
            beneficiary: msg.sender, // Default beneficiary is proposer, can be changed in proposal details or further functionality
            voteStartTime: 0,
            voteEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            proposalPassed: false,
            voteActive: false,
            executed: false
        });
        _fundingProposalCounter.increment();
        emit FundingProposalCreated(proposalId, _proposalTitle, msg.sender);
    }

    /**
     * @dev Admin function to start a vote for a funding proposal.
     * @param _proposalId ID of the funding proposal.
     */
    function startFundingProposalVote(uint256 _proposalId) external onlyOwner {
        require(!fundingProposals[_proposalId].voteActive, "Funding vote already active");
        require(fundingProposals[_proposalId].voteEndTime == 0, "Funding vote already started and potentially ended"); // Prevent restart after vote
        FundingProposal storage proposal = fundingProposals[_proposalId];
        proposal.voteActive = true;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + fundingProposalVoteDuration;
        emit FundingProposalCreated(_proposalId, proposal.title, proposal.proposer); // Re-emit event for clarity - consider different event
    }


    /**
     * @dev Members can vote on funding proposals during the voting period.
     * @param _proposalId ID of the funding proposal to vote on.
     * @param _approve Boolean vote: true for approve, false for reject.
     */
    function voteOnFundingProposal(uint256 _proposalId, bool _approve) external onlyMember onlyFundingVoteActive(_proposalId) {
        require(!fundingProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        fundingProposalVotes[_proposalId][msg.sender] = true;
        FundingProposal storage proposal = fundingProposals[_proposalId];
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit FundingProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Admin function to finalize a funding proposal vote and execute if approved.
     * @param _proposalId ID of the funding proposal to finalize.
     */
    function finalizeFundingProposal(uint256 _proposalId) external onlyOwner onlyProposalNotExecuted(_proposalId) {
        require(fundingProposals[_proposalId].voteActive, "Funding vote is not active or has already been finalized");
        require(block.timestamp > fundingProposals[_proposalId].voteEndTime, "Funding vote is still active");

        FundingProposal storage proposal = fundingProposals[_proposalId];
        proposal.voteActive = false; // Mark vote as inactive

        uint256 totalMembers = 0;
        for (address memberAddress : getMembers()) { // Inefficient way to get member count, consider storing member count separately for larger scale
            if (isMember[memberAddress]) {
                totalMembers++;
            }
        }
        uint256 quorumNeeded = (totalMembers * fundingProposalVoteQuorum) / 100;
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;

        if (totalVotes >= quorumNeeded && proposal.yesVotes > proposal.noVotes) { // Simple majority with quorum
            proposal.proposalPassed = true;
            emit FundingProposalFinalized(_proposalId, true, proposal.yesVotes, proposal.noVotes);
        } else {
            proposal.proposalPassed = false;
            emit FundingProposalFinalized(_proposalId, false, proposal.yesVotes, proposal.noVotes);
        }
    }

    /**
     * @dev Function for the proposal beneficiary to withdraw approved funds if proposal passed.
     * @param _proposalId ID of the funding proposal.
     */
    function withdrawFunds(uint256 _proposalId) external onlyProposalNotExecuted(_proposalId) {
        FundingProposal storage proposal = fundingProposals[_proposalId];
        require(proposal.proposalPassed, "Funding proposal not approved");
        require(proposal.beneficiary == msg.sender, "Only beneficiary can withdraw funds");

        uint256 amount = proposal.fundingAmount;
        proposal.executed = true; // Mark as executed before transfer to prevent reentrancy in simple case (consider more robust reentrancy guard for complex logic)
        payable(proposal.beneficiary).transfer(amount);
        emit FundsWithdrawn(_proposalId, proposal.beneficiary, amount);
    }

    // --- Membership Functions ---

    /**
     * @dev Allows users to stake tokens to become members of the DAAC.
     */
    function stakeForMembership() external nonReentrant {
        require(!isMember[msg.sender], "Already a member");
        require(membershipToken.allowance(msg.sender, address(this)) >= membershipStakeAmount, "Insufficient allowance for membership stake");
        require(membershipToken.transferFrom(msg.sender, address(this), membershipStakeAmount), "Membership token transfer failed");
        isMember[msg.sender] = true;
        membershipStake[msg.sender] = membershipStakeAmount;
        emit MembershipStaked(msg.sender, membershipStakeAmount);
    }

    /**
     * @dev Allows members to unstake tokens and leave the DAAC (losing voting rights).
     */
    function unstakeMembership() external nonReentrant onlyMember {
        require(isMember[msg.sender], "Not a member");
        uint256 stakedAmount = membershipStake[msg.sender];
        isMember[msg.sender] = false;
        delete membershipStake[msg.sender]; // Clear stake amount
        require(membershipToken.transfer(msg.sender, stakedAmount), "Membership token refund failed");
        emit MembershipUnstaked(msg.sender, stakedAmount);
    }

    // --- Digital Art Exhibition Functions ---

    /**
     * @dev Admin function to create a digital art exhibition featuring selected artworks.
     * @param _exhibitionName Name of the exhibition.
     * @param _exhibitionDescription Description of the exhibition.
     * @param _artTokenIds Array of art token IDs to include in the exhibition.
     */
    function createExhibition(string memory _exhibitionName, string memory _exhibitionDescription, uint256[] memory _artTokenIds) external onlyOwner {
        uint256 exhibitionId = _exhibitionCounter.current();
        exhibitions[exhibitionId] = Exhibition({
            id: exhibitionId,
            name: _exhibitionName,
            description: _exhibitionDescription,
            artTokenIds: _artTokenIds,
            curator: msg.sender,
            startTime: block.timestamp, // Exhibition starts immediately upon creation - adjust as needed
            endTime: 0, // Set to 0 for ongoing exhibition, or set a specific end time
            isActive: true
        });
        _exhibitionCounter.increment();
        emit ExhibitionCreated(exhibitionId, _exhibitionName, msg.sender);
    }

    /**
     * @dev Admin function to add artwork to an existing exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @param _artTokenId ID of the art token to add.
     */
    function addArtToExhibition(uint256 _exhibitionId, uint256 _artTokenId) external onlyOwner onlyExhibitionCurator(_exhibitionId) onlyExhibitionActive(_exhibitionId) {
        bool alreadyInExhibition = false;
        for (uint256 i = 0; i < exhibitions[_exhibitionId].artTokenIds.length; i++) {
            if (exhibitions[_exhibitionId].artTokenIds[i] == _artTokenId) {
                alreadyInExhibition = true;
                break;
            }
        }
        require(!alreadyInExhibition, "Art already in exhibition");
        exhibitions[_exhibitionId].artTokenIds.push(_artTokenId);
        emit ArtAddedToExhibition(_exhibitionId, _artTokenId);
    }

    /**
     * @dev Admin function to remove artwork from an exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @param _artTokenId ID of the art token to remove.
     */
    function removeArtFromExhibition(uint256 _exhibitionId, uint256 _artTokenId) external onlyOwner onlyExhibitionCurator(_exhibitionId) onlyExhibitionActive(_exhibitionId) {
        uint256[] storage artTokenIds = exhibitions[_exhibitionId].artTokenIds;
        for (uint256 i = 0; i < artTokenIds.length; i++) {
            if (artTokenIds[i] == _artTokenId) {
                artTokenIds[i] = artTokenIds[artTokenIds.length - 1];
                artTokenIds.pop();
                emit ArtRemovedFromExhibition(_exhibitionId, _artTokenId);
                return;
            }
        }
        revert("Art not found in exhibition");
    }

    // --- Governance & Parameter Setting Functions ---

    /**
     * @dev Admin function to change the required stake amount for membership.
     * @param _newStakeAmount The new stake amount in wei.
     */
    function setMembershipStakeAmount(uint256 _newStakeAmount) external onlyOwner {
        membershipStakeAmount = _newStakeAmount;
        emit MembershipStakeAmountChanged(_newStakeAmount);
    }

    /**
     * @dev Admin function to change the royalty percentage for artists on secondary sales (concept - requires marketplace integration).
     * @param _newRoyaltyPercentage The new royalty percentage (e.g., 10 for 10%).
     */
    function setRoyaltyPercentage(uint256 _newRoyaltyPercentage) external onlyOwner {
        royaltyPercentage = _newRoyaltyPercentage;
        emit RoyaltyPercentageChanged(_newRoyaltyPercentage);
    }

    /**
     * @dev Members can propose changes to DAAC parameters (e.g., voting periods, fees).
     * @param _parameterName Name of the parameter to change (e.g., "curationVoteDuration").
     * @param _newValue New value for the parameter.
     */
    function proposeParameterChange(string memory _parameterName, uint256 _newValue) external onlyMember {
        uint256 proposalId = _parameterChangeProposalCounter.current();
        parameterChangeProposals[proposalId] = ParameterChangeProposal({
            id: proposalId,
            parameterName: _parameterName,
            newValue: _newValue,
            proposer: msg.sender,
            voteStartTime: 0,
            voteEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            proposalPassed: false,
            voteActive: false,
            executed: false
        });
        _parameterChangeProposalCounter.increment();
        emit ParameterChangeProposalCreated(proposalId, _parameterName, _newValue, msg.sender);
    }

    /**
     * @dev Admin function to start a vote for a parameter change proposal.
     * @param _proposalId ID of the parameter change proposal.
     */
    function startParameterChangeVote(uint256 _proposalId) external onlyOwner {
        require(!parameterChangeProposals[_proposalId].voteActive, "Parameter change vote already active");
        require(parameterChangeProposals[_proposalId].voteEndTime == 0, "Parameter change vote already started and potentially ended"); // Prevent restart after vote
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.voteActive = true;
        proposal.voteStartTime = block.timestamp;
        proposal.voteEndTime = block.timestamp + parameterChangeVoteDuration;
        emit ParameterChangeProposalCreated(_proposalId, proposal.parameterName, proposal.newValue, proposal.proposer); // Re-emit for clarity - consider different event
    }


    /**
     * @dev Members can vote on parameter change proposals during the voting period.
     * @param _proposalId ID of the parameter change proposal to vote on.
     * @param _approve Boolean vote: true for approve, false for reject.
     */
    function voteOnParameterChange(uint256 _proposalId, bool _approve) external onlyMember onlyParameterChangeVoteActive(_proposalId) {
        require(!parameterChangeProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        parameterChangeProposalVotes[_proposalId][msg.sender] = true;
        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ParameterChangeProposalVoted(_proposalId, msg.sender, _approve);
    }

    /**
     * @dev Admin function to finalize a parameter change proposal vote and apply changes if approved.
     * @param _proposalId ID of the parameter change proposal to finalize.
     */
    function finalizeParameterChange(uint256 _proposalId) external onlyOwner onlyParameterChangeNotExecuted(_proposalId) {
        require(parameterChangeProposals[_proposalId].voteActive, "Parameter change vote is not active or has already been finalized");
        require(block.timestamp > parameterChangeProposals[_proposalId].voteEndTime, "Parameter change vote is still active");

        ParameterChangeProposal storage proposal = parameterChangeProposals[_proposalId];
        proposal.voteActive = false; // Mark vote as inactive

        uint256 totalMembers = 0;
        for (address memberAddress : getMembers()) { // Inefficient way to get member count, consider storing member count separately for larger scale
            if (isMember[memberAddress]) {
                totalMembers++;
            }
        }
        uint256 quorumNeeded = (totalMembers * parameterChangeVoteQuorum) / 100;
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;

        if (totalVotes >= quorumNeeded && proposal.yesVotes > proposal.noVotes) { // Simple majority with quorum
            proposal.proposalPassed = true;
            _applyParameterChange(proposal); // Apply the change if approved
            emit ParameterChangeProposalFinalized(_proposalId, true, proposal.yesVotes, proposal.noVotes);
        } else {
            proposal.proposalPassed = false;
            emit ParameterChangeProposalFinalized(_proposalId, false, proposal.yesVotes, proposal.noVotes);
        }
    }

    /**
     * @dev Internal function to apply the parameter change based on the proposal.
     * @param _proposal ParameterChangeProposal struct.
     */
    function _applyParameterChange(ParameterChangeProposal memory _proposal) internal {
        if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("curationVoteDuration"))) {
            curationVoteDuration = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("curationVoteQuorum"))) {
            curationVoteQuorum = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("fundingProposalVoteDuration"))) {
            fundingProposalVoteDuration = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("fundingProposalVoteQuorum"))) {
            fundingProposalVoteQuorum = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("parameterChangeVoteDuration"))) {
            parameterChangeVoteDuration = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("parameterChangeVoteQuorum"))) {
            parameterChangeVoteQuorum = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("platformFeePercentage"))) {
            platformFeePercentage = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("royaltyPercentage"))) {
            royaltyPercentage = _proposal.newValue;
        } else if (keccak256(abi.encodePacked(_proposal.parameterName)) == keccak256(abi.encodePacked("membershipStakeAmount"))) {
            membershipStakeAmount = _proposal.newValue;
        } else {
            revert("Invalid parameter name for change");
        }
        parameterChangeProposals[_proposal.id].executed = true; // Mark as executed
        emit ParameterChanged(_proposal.parameterName, _proposal.newValue);
    }


    // --- Utility & View Functions ---

    /**
     * @dev Admin function for emergency fund withdrawal in unforeseen circumstances.
     * @param _recipient Address to receive the funds.
     */
    function emergencyWithdraw(address _recipient) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_recipient).transfer(balance);
        emit EmergencyWithdrawal(_recipient, balance);
    }

    /**
     * @dev Public view function to retrieve details of an art piece.
     * @param _artTokenId ID of the art token.
     * @return Details of the art piece.
     */
    function getArtDetails(uint256 _artTokenId) public view returns (string memory title, string memory description, string memory ipfsCID, address artist, uint256 price) {
        uint256 submissionId;
        for (uint256 id = 1; id < _artSubmissionCounter.current(); id++) {
            if (artSubmissions[id].ipfsCID == artTokenIPFSCID[_artTokenId]) { // Basic matching - improve if needed based on CID uniqueness guarantee
                submissionId = id;
                break;
            }
        }
        return (artSubmissions[submissionId].title, artSubmissions[submissionId].description, artTokenIPFSCID[_artTokenId], artTokenArtist[_artTokenId], artTokenPrice[_artTokenId]);
    }

    /**
     * @dev Public view function to retrieve details of an artist.
     * @param _artistAddress Address of the artist.
     * @return Details of the artist.
     */
    function getArtistDetails(address _artistAddress) public view returns (string memory artistName, string memory artistStatement, bool approved) {
        return (artistNames[_artistAddress], artistStatements[_artistAddress], isApprovedArtist[_artistAddress]);
    }

    /**
     * @dev Public view function to retrieve details of a funding or parameter change proposal.
     * @param _proposalId ID of the proposal.
     * @return Details of the proposal.
     */
    function getProposalDetails(uint256 _proposalId) public view returns (string memory title, string memory description, uint256 fundingAmount, address proposer, bool passed, bool active, uint256 yesVotes, uint256 noVotes) {
        if (_proposalId < _fundingProposalCounter.current() && fundingProposals[_proposalId].id == _proposalId) { // Check if it's a funding proposal
            FundingProposal memory proposal = fundingProposals[_proposalId];
            return (proposal.title, proposal.description, proposal.fundingAmount, proposal.proposer, proposal.proposalPassed, proposal.voteActive, proposal.yesVotes, proposal.noVotes);
        } else if (_proposalId < _parameterChangeProposalCounter.current() && parameterChangeProposals[_proposalId].id == _proposalId) { // Check if it's a parameter change proposal
            ParameterChangeProposal memory proposal = parameterChangeProposals[_proposalId];
            return (proposal.parameterName, "Parameter Change Proposal: " , proposal.newValue, proposal.proposer, proposal.proposalPassed, proposal.voteActive, proposal.yesVotes, proposal.noVotes); // Modified to fit return type, adjust as needed
        } else {
            revert("Invalid proposal ID");
        }
    }

    /**
     * @dev Public view function to retrieve details of an exhibition.
     * @param _exhibitionId ID of the exhibition.
     * @return Details of the exhibition.
     */
    function getExhibitionDetails(uint256 _exhibitionId) public view returns (string memory name, string memory description, uint256[] memory artTokenIds, address curator, bool active) {
        Exhibition memory exhibition = exhibitions[_exhibitionId];
        return (exhibition.name, exhibition.description, exhibition.artTokenIds, exhibition.curator, exhibition.isActive);
    }

    /**
     * @dev Helper function to get a list of members (for iteration purposes - gas intensive for very large memberships).
     * @return Array of member addresses.
     */
    function getMembers() public view returns (address[] memory) {
        address[] memory members = new address[](getMemberCount());
        uint256 index = 0;
        for (uint256 i = 0; i < pendingArtistApplications.length + _artTokenCounter.current() + _fundingProposalCounter.current(); i++) { // Very rough upper bound - improve if needed
            if (isMember[address(uint160(uint256(keccak256(abi.encodePacked(i))))))]) { // Inefficient and not scalable - just for demonstration, replace with proper membership tracking for real use
                members[index] = address(uint160(uint256(keccak256(abi.encodePacked(i))))));
                index++;
            }
        }
        return members;
    }

    /**
     * @dev Helper function to get the count of members (inefficient for very large memberships).
     * @return Number of members.
     */
    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < pendingArtistApplications.length + _artTokenCounter.current() + _fundingProposalCounter.current(); i++) { // Very rough upper bound - improve if needed
             if (isMember[address(uint160(uint256(keccak256(abi.encodePacked(i))))))]) { // Inefficient and not scalable - just for demonstration, replace with proper membership tracking for real use
                count++;
            }
        }
        return count;
    }

    // --- Override ERC721 supportsInterface to declare royalty support (ERC2981 - concept, requires marketplace integration) ---
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == 0x298101bfa298101bf || super.supportsInterface(interfaceId); // ERC2981 interface ID
    }

    // --- ERC2981 Royalty Info (Concept - requires marketplace integration) ---
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        // In a real ERC2981 implementation, you would likely store royalty receiver per token or artist.
        // For simplicity here, we assume royalty goes to the original artist.
        return (artTokenArtist[_tokenId], (_salePrice * royaltyPercentage) / 100);
    }
}
```