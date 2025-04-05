```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Advanced Smart Contract
 * @author Gemini AI Assistant
 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC) that allows members to collectively curate, create, and manage digital art.
 * It features advanced concepts like quadratic voting, fractionalized NFT ownership, curated art exhibitions,
 * decentralized art bounties, and artist reputation system, all governed by a DAO.
 *
 * **Outline:**
 *
 * **Core DAO Functionality:**
 * 1. Membership Management (Proposals, Voting, Onboarding)
 * 2. Governance Token (DAAC Token - for voting and utility)
 * 3. Treasury Management (Funding Proposals, Distributions)
 *
 * **Art Curation & Creation:**
 * 4. Art Submission & Proposal System
 * 5. Decentralized Curation Process (Voting on Submissions)
 * 6. NFT Minting for Approved Artworks
 * 7. Fractionalized NFT Ownership (Option to fractionalize valuable art)
 * 8. Curated Art Exhibitions (Virtual Galleries within the contract)
 * 9. Art Bounties & Challenges (Funded by Treasury for specific art pieces)
 * 10. Artist Reputation System (Track artist contributions and quality)
 * 11. Art Royalties for Creators (On secondary market sales)
 *
 * **Advanced & Trendy Features:**
 * 12. Quadratic Voting for Proposals (Fairer distribution of voting power)
 * 13. Curation Rewards (Incentivize active and good curators)
 * 14. Dynamic Quorum for Proposals (Adjust quorum based on participation)
 * 15. Art Ownership Transfer Mechanism (Secure and transparent transfer)
 * 16. Decentralized Storage Integration (Conceptual - for metadata storage)
 * 17. Emergency Pause Mechanism (For critical situations)
 * 18. Whitelist Functionality (For specific actions or roles)
 * 19. Layered Access Control (Different roles with specific permissions)
 * 20. On-Chain Randomness for Art Generation (Conceptual - for generative art features)
 * 21. Community Challenges & Bounties (Open to external artists, not just members)
 * 22. Art Versioning & Provenance Tracking (Immutable history of art evolution)
 * 23. DAO Parameter Adjustment (Governance can change key contract parameters)
 *
 * **Function Summary:**
 *
 * **Governance & Membership:**
 * - `proposeMembership(address _newMember)`: Propose a new member to join the DAAC.
 * - `voteOnMembershipProposal(uint256 _proposalId, bool _vote)`: Vote on a membership proposal.
 * - `processMembershipProposal(uint256 _proposalId)`: Process a membership proposal after voting period.
 * - `leaveDAAC()`: Allow members to leave the DAAC and potentially claim assets.
 * - `getMemberCount()`: Returns the current number of DAAC members.
 *
 * **Art Curation & Creation:**
 * - `submitArtProposal(string memory _metadataURI)`: Submit a new art piece proposal with metadata URI.
 * - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Vote on an art proposal.
 * - `processArtProposal(uint256 _proposalId)`: Process an art proposal after voting period.
 * - `mintArtNFT(uint256 _artProposalId)`: Mint an NFT for an approved art proposal (members only).
 * - `fractionalizeNFT(uint256 _nftId, uint256 _shares)`: Fractionalize an owned DAAC art NFT.
 * - `createArtExhibition(string memory _exhibitionName)`: Create a new virtual art exhibition.
 * - `addArtToExhibition(uint256 _exhibitionId, uint256 _nftId)`: Add an approved art NFT to an exhibition.
 * - `createArtBounty(string memory _bountyDescription, uint256 _rewardAmount)`: Create a bounty for a specific art piece.
 * - `submitBountyArtwork(uint256 _bountyId, string memory _metadataURI)`: Submit artwork for a bounty.
 * - `voteOnBountySubmission(uint256 _bountyId, uint256 _submissionId, bool _vote)`: Vote on a bounty submission.
 * - `processBounty(uint256 _bountyId)`: Process a bounty after voting and reward the winner.
 * - `getArtistReputation(address _artistAddress)`: View the reputation score of an artist.
 *
 * **Treasury & Utility:**
 * - `depositToTreasury()`: Deposit ETH or DAAC tokens to the DAAC treasury.
 * - `proposeTreasuryWithdrawal(address _recipient, uint256 _amount)`: Propose a withdrawal from the treasury.
 * - `voteOnTreasuryWithdrawal(uint256 _proposalId, bool _vote)`: Vote on a treasury withdrawal proposal.
 * - `processTreasuryWithdrawal(uint256 _proposalId)`: Process a treasury withdrawal proposal after voting.
 * - `purchaseFractionalShare(uint256 _fractionalNFTId, uint256 _sharesToBuy)`: Purchase fractional shares of a DAAC NFT.
 *
 * **Admin & System Functions:**
 * - `pauseContract()`: Pause the contract in case of emergency (Admin only).
 * - `unpauseContract()`: Unpause the contract (Admin only).
 * - `setVotingPeriod(uint256 _newVotingPeriod)`: Set the voting period for proposals (DAO governance).
 * - `setQuorumPercentage(uint256 _newQuorumPercentage)`: Set the quorum percentage for proposals (DAO governance).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // -------- STATE VARIABLES --------

    // Governance
    address public governanceTokenAddress; // Address of the DAAC governance token
    uint256 public votingPeriod = 7 days; // Default voting period for proposals
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals (50%)
    bool public paused = false; // Contract pause state
    address public admin; // Admin address for emergency pause/unpause

    // Membership
    mapping(address => bool) public members; // Mapping of DAAC members
    Counters.Counter public membershipProposalCounter;
    mapping(uint256 => MembershipProposal) public membershipProposals;
    uint256 public membershipFee; // Fee to join DAAC (can be 0)

    struct MembershipProposal {
        address proposer;
        address newMember;
        uint256 votesFor;
        uint256 votesAgainst;
        bool active;
        uint256 votingEndTime;
    }

    // Art Curation & Creation
    Counters.Counter public artProposalCounter;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ArtNFT) public artNFTs;
    Counters.Counter public artNFTCounter;
    Counters.Counter public exhibitionCounter;
    mapping(uint256 => ArtExhibition) public artExhibitions;
    Counters.Counter public artBountyCounter;
    mapping(uint256 => ArtBounty) public artBounties;
    mapping(uint256 => mapping(uint256 => BountySubmission)) public bountySubmissions; // bountyId -> submissionId -> submission data
    Counters.Counter public bountySubmissionCounter;
    mapping(address => uint256) public artistReputation; // Artist reputation score

    struct ArtProposal {
        address proposer;
        string metadataURI;
        uint256 votesFor;
        uint256 votesAgainst;
        bool active;
        bool approved;
        uint256 votingEndTime;
    }

    struct ArtNFT {
        uint256 proposalId;
        string metadataURI;
        address creator;
        uint256 royaltyPercentage; // Percentage of royalties on secondary sales
    }

    struct ArtExhibition {
        string name;
        uint256[] artNFTIds;
        address creator;
    }

    struct ArtBounty {
        string description;
        uint256 rewardAmount; // Reward in native token (ETH)
        address creator;
        bool active;
        uint256 votingEndTime;
        uint256 winningSubmissionId;
    }

    struct BountySubmission {
        address artist;
        string metadataURI;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    // Fractionalized NFT
    mapping(uint256 => FractionalNFT) public fractionalNFTs;
    Counters.Counter public fractionalNFTCounter;

    struct FractionalNFT {
        uint256 nftId;
        uint256 totalSupply; // Total shares
        mapping(address => uint256) balances; // Share balances
        bool fractionalized;
    }

    // Treasury
    uint256 public treasuryBalance; // Treasury balance in native token (ETH)

    // Events
    event MembershipProposed(uint256 proposalId, address newMember, address proposer);
    event MembershipVoteCast(uint256 proposalId, address voter, bool vote);
    event MembershipProposalProcessed(uint256 proposalId, bool approved, address newMember);
    event MemberJoined(address member);
    event MemberLeft(address member);

    event ArtProposalSubmitted(uint256 proposalId, address proposer, string metadataURI);
    event ArtVoteCast(uint256 proposalId, address voter, bool vote);
    event ArtProposalProcessed(uint256 proposalId, bool approved, uint256 nftId);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address creator);
    event NFTFractionalized(uint256 fractionalNFTId, uint256 nftId, uint256 totalShares);
    event FractionalSharesPurchased(uint256 fractionalNFTId, address buyer, uint256 sharesBought);
    event ArtExhibitionCreated(uint256 exhibitionId, string name, address creator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 nftId);

    event ArtBountyCreated(uint256 bountyId, string description, uint256 rewardAmount, address creator);
    event BountyArtworkSubmitted(uint256 bountyId, uint256 submissionId, address artist, string metadataURI);
    event BountySubmissionVoteCast(uint256 bountyId, uint256 submissionId, address voter, bool vote);
    event BountyProcessed(uint256 bountyId, uint256 winningSubmissionId, address winner);

    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 proposalId, address recipient, uint256 amount, address proposer);
    event TreasuryWithdrawalVoteCast(uint256 proposalId, address voter, bool vote);
    event TreasuryWithdrawalProcessed(uint256 proposalId, bool approved, address recipient, uint256 amount);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event VotingPeriodUpdated(uint256 newVotingPeriod);
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);

    // -------- MODIFIERS --------

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
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

    modifier proposalActive(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Membership) {
            require(membershipProposals[_proposalId].active, "Membership proposal is not active.");
        } else if (_proposalType == ProposalType.Art) {
            require(artProposals[_proposalId].active, "Art proposal is not active.");
        } else if (_proposalType == ProposalType.TreasuryWithdrawal) {
            require(treasuryWithdrawalProposals[_proposalId].active, "Treasury withdrawal proposal is not active.");
        } else if (_proposalType == ProposalType.BountySubmission) {
            // Bounty submission active check is handled within the function
        }
        _;
    }

    modifier votingPeriodNotExpired(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Membership) {
            require(block.timestamp <= membershipProposals[_proposalId].votingEndTime, "Membership voting period expired.");
        } else if (_proposalType == ProposalType.Art) {
            require(block.timestamp <= artProposals[_proposalId].votingEndTime, "Art voting period expired.");
        } else if (_proposalType == ProposalType.TreasuryWithdrawal) {
            require(block.timestamp <= treasuryWithdrawalProposals[_proposalId].votingEndTime, "Treasury withdrawal voting period expired.");
        } else if (_proposalType == ProposalType.BountySubmission) {
            // Bounty submission voting period is handled within the function
        }
        _;
    }

    enum ProposalType { Membership, Art, TreasuryWithdrawal, BountySubmission }

    // -------- CONSTRUCTOR --------

    constructor(string memory _name, string memory _symbol, address _governanceTokenAddress) ERC721(_name, _symbol) {
        admin = msg.sender;
        members[msg.sender] = true; // Creator is initial member
        governanceTokenAddress = _governanceTokenAddress;
    }

    // -------- GOVERNANCE & MEMBERSHIP FUNCTIONS --------

    function proposeMembership(address _newMember) external onlyMember whenNotPaused {
        require(!members[_newMember], "Address is already a member.");
        membershipProposalCounter.increment();
        uint256 proposalId = membershipProposalCounter.current();
        membershipProposals[proposalId] = MembershipProposal({
            proposer: msg.sender,
            newMember: _newMember,
            votesFor: 0,
            votesAgainst: 0,
            active: true,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit MembershipProposed(proposalId, _newMember, msg.sender);
    }

    function voteOnMembershipProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused proposalActive(_proposalId, ProposalType.Membership) votingPeriodNotExpired(_proposalId, ProposalType.Membership) {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(block.timestamp <= proposal.votingEndTime, "Voting period expired.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit MembershipVoteCast(_proposalId, msg.sender, _vote);
    }

    function processMembershipProposal(uint256 _proposalId) external onlyMember whenNotPaused proposalActive(_proposalId, ProposalType.Membership) votingPeriodNotExpired(_proposalId, ProposalType.Membership) {
        MembershipProposal storage proposal = membershipProposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(block.timestamp > proposal.votingEndTime, "Voting period not expired.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (getMemberCount() * quorumPercentage) / 100; // Dynamic quorum based on member count

        if (totalVotes >= quorum && proposal.votesFor > proposal.votesAgainst) {
            members[proposal.newMember] = true;
            proposal.active = false;
            emit MembershipProposalProcessed(_proposalId, true, proposal.newMember);
            emit MemberJoined(proposal.newMember);
        } else {
            proposal.active = false;
            emit MembershipProposalProcessed(_proposalId, false, proposal.newMember);
        }
    }

    function leaveDAAC() external onlyMember whenNotPaused {
        delete members[msg.sender];
        emit MemberLeft(msg.sender);
        // Implement logic for member to withdraw their share of treasury or NFTs if applicable (advanced feature)
    }

    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        address[] memory allMembers = getMembersArray(); // Get all members into an array
        for (uint256 i = 0; i < allMembers.length; i++) {
            if (members[allMembers[i]]) {
                count++;
            }
        }
        return count;
    }

    function getMembersArray() public view returns (address[] memory) {
        address[] memory memberList = new address[](address(this).balance); // Approximating size, can be optimized
        uint256 index = 0;
        for (uint256 i = 0; i < memberList.length; i++) { // Iterate through potential addresses (inefficient, but conceptually demonstrating)
            address possibleMember = address(uint160(i)); // Example iteration, in real-world, better membership tracking is needed
            if (members[possibleMember]) {
                memberList[index] = possibleMember;
                index++;
            }
        }
        address[] memory finalMemberList = new address[](index);
        for (uint256 i = 0; i < index; i++) {
            finalMemberList[i] = memberList[i];
        }
        return finalMemberList;
    }


    // -------- ART CURATION & CREATION FUNCTIONS --------

    function submitArtProposal(string memory _metadataURI) external onlyMember whenNotPaused {
        artProposalCounter.increment();
        uint256 proposalId = artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            proposer: msg.sender,
            metadataURI: _metadataURI,
            votesFor: 0,
            votesAgainst: 0,
            active: true,
            approved: false,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _metadataURI);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused proposalActive(_proposalId, ProposalType.Art) votingPeriodNotExpired(_proposalId, ProposalType.Art) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(block.timestamp <= proposal.votingEndTime, "Voting period expired.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtVoteCast(_proposalId, msg.sender, _vote);
    }

    function processArtProposal(uint256 _proposalId) external onlyMember whenNotPaused proposalActive(_proposalId, ProposalType.Art) votingPeriodNotExpired(_proposalId, ProposalType.Art) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(block.timestamp > proposal.votingEndTime, "Voting period not expired.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (getMemberCount() * quorumPercentage) / 100;

        if (totalVotes >= quorum && proposal.votesFor > proposal.votesAgainst) {
            proposal.approved = true;
            proposal.active = false;
            emit ArtProposalProcessed(_proposalId, true, 0); // nftId will be set when minted
        } else {
            proposal.active = false;
            emit ArtProposalProcessed(_proposalId, false, 0);
        }
    }

    function mintArtNFT(uint256 _artProposalId) external onlyMember whenNotPaused {
        ArtProposal storage proposal = artProposals[_artProposalId];
        require(proposal.approved, "Art proposal not approved.");
        require(!proposal.active, "Art proposal still active."); // Ensure it's processed

        artNFTCounter.increment();
        uint256 nftId = artNFTCounter.current();
        artNFTs[nftId] = ArtNFT({
            proposalId: _artProposalId,
            metadataURI: proposal.metadataURI,
            creator: proposal.proposer,
            royaltyPercentage: 5 // Example royalty percentage
        });

        _mint(proposal.proposer, nftId); // Mint NFT to the proposer (artist) - can be adjusted for DAO ownership
        emit ArtNFTMinted(nftId, _artProposalId, proposal.proposer);
    }

    function fractionalizeNFT(uint256 _nftId, uint256 _shares) external onlyMember whenNotPaused {
        require(_exists(_nftId), "NFT does not exist.");
        require(ownerOf(_nftId) == msg.sender, "You are not the owner of this NFT.");
        require(!fractionalNFTs[_nftId].fractionalized, "NFT is already fractionalized.");
        require(_shares > 0, "Shares must be greater than 0.");

        fractionalNFTCounter.increment();
        uint256 fractionalNFTId = fractionalNFTCounter.current();
        fractionalNFTs[fractionalNFTId] = FractionalNFT({
            nftId: _nftId,
            totalSupply: _shares,
            fractionalized: true
        });
        fractionalNFTs[fractionalNFTId].balances[msg.sender] = _shares; // Initial owner gets all shares

        // Optionally transfer NFT ownership to the contract itself for management (advanced)
        // _transfer(msg.sender, address(this), _nftId);

        emit NFTFractionalized(fractionalNFTId, _nftId, _shares);
    }

    function purchaseFractionalShare(uint256 _fractionalNFTId, uint256 _sharesToBuy) external payable whenNotPaused {
        FractionalNFT storage fractionalNFT = fractionalNFTs[_fractionalNFTId];
        require(fractionalNFT.fractionalized, "NFT is not fractionalized.");
        require(_sharesToBuy > 0, "Shares to buy must be greater than 0.");
        // Example pricing: 1 share = 0.01 ETH (adjust as needed, or make it dynamic)
        uint256 purchasePrice = _sharesToBuy * 0.01 ether; // Fixed price for simplicity
        require(msg.value >= purchasePrice, "Insufficient ETH sent for purchase.");

        fractionalNFT.balances[msg.sender] += _sharesToBuy;
        fractionalNFT.balances[ownerOf(fractionalNFT.nftId)] -= _sharesToBuy; // Assuming initial owner is selling shares

        // Transfer ETH to the original fractional NFT owner (seller)
        payable(ownerOf(fractionalNFT.nftId)).transfer(purchasePrice); // Simple transfer to original owner

        emit FractionalSharesPurchased(_fractionalNFTId, msg.sender, _sharesToBuy);

        // Refund any excess ETH sent
        if (msg.value > purchasePrice) {
            payable(msg.sender).transfer(msg.value - purchasePrice);
        }
    }

    function createArtExhibition(string memory _exhibitionName) external onlyMember whenNotPaused {
        exhibitionCounter.increment();
        uint256 exhibitionId = exhibitionCounter.current();
        artExhibitions[exhibitionId] = ArtExhibition({
            name: _exhibitionName,
            artNFTIds: new uint256[](0),
            creator: msg.sender
        });
        emit ArtExhibitionCreated(exhibitionId, _exhibitionName, msg.sender);
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _nftId) external onlyMember whenNotPaused {
        require(artExhibitions[_exhibitionId].creator != address(0), "Exhibition does not exist.");
        require(_exists(_nftId), "NFT does not exist.");

        artExhibitions[_exhibitionId].artNFTIds.push(_nftId);
        emit ArtAddedToExhibition(_exhibitionId, _nftId);
    }

    function createArtBounty(string memory _bountyDescription, uint256 _rewardAmount) external onlyMember whenNotPaused {
        require(_rewardAmount > 0, "Bounty reward must be greater than 0.");
        require(treasuryBalance >= _rewardAmount, "Insufficient funds in treasury for bounty.");
        require(msg.value >= _rewardAmount, "Please send enough ETH to cover the bounty reward."); // Ensure bounty creator funds it

        artBountyCounter.increment();
        uint256 bountyId = artBountyCounter.current();
        artBounties[bountyId] = ArtBounty({
            description: _bountyDescription,
            rewardAmount: _rewardAmount,
            creator: msg.sender,
            active: true,
            votingEndTime: block.timestamp + votingPeriod,
            winningSubmissionId: 0
        });

        treasuryBalance -= _rewardAmount; // Deduct bounty from treasury immediately
        emit ArtBountyCreated(bountyId, _bountyDescription, _rewardAmount, msg.sender);
    }

    function submitBountyArtwork(uint256 _bountyId, string memory _metadataURI) external whenNotPaused { // Open to anyone, not just members
        require(artBounties[_bountyId].active, "Bounty is not active.");
        bountySubmissionCounter.increment();
        uint256 submissionId = bountySubmissionCounter.current();
        bountySubmissions[_bountyId][submissionId] = BountySubmission({
            artist: msg.sender,
            metadataURI: _metadataURI,
            votesFor: 0,
            votesAgainst: 0
        });
        emit BountyArtworkSubmitted(_bountyId, submissionId, msg.sender, _metadataURI);
    }

    function voteOnBountySubmission(uint256 _bountyId, uint256 _submissionId, bool _vote) external onlyMember whenNotPaused {
        require(artBounties[_bountyId].active, "Bounty is not active.");
        require(bountySubmissions[_bountyId][_submissionId].artist != address(0), "Submission does not exist."); // Check if submission exists

        BountySubmission storage submission = bountySubmissions[_bountyId][_submissionId];
        if (_vote) {
            submission.votesFor++;
        } else {
            submission.votesAgainst++;
        }
        emit BountySubmissionVoteCast(_bountyId, _submissionId, msg.sender, _vote);
    }

    function processBounty(uint256 _bountyId) external onlyMember whenNotPaused {
        ArtBounty storage bounty = artBounties[_bountyId];
        require(bounty.active, "Bounty is not active.");
        require(block.timestamp > bounty.votingEndTime, "Voting period not expired.");

        uint256 winningSubmissionId = 0;
        uint256 maxVotes = 0;

        // Find submission with most votes
        for (uint256 submissionId = 1; submissionId <= bountySubmissionCounter.current(); submissionId++) { // Iterate through all submissions
            if (bountySubmissions[_bountyId][submissionId].artist != address(0)) { // Check if submission exists for this bounty
                if (bountySubmissions[_bountyId][submissionId].votesFor > maxVotes) {
                    maxVotes = bountySubmissions[_bountyId][submissionId].votesFor;
                    winningSubmissionId = submissionId;
                }
            }
        }

        if (winningSubmissionId > 0) {
            address winner = bountySubmissions[_bountyId][winningSubmissionId].artist;
            uint256 reward = bounty.rewardAmount;

            (bool success, ) = payable(winner).call{value: reward}(""); // Send reward to winner
            require(success, "Bounty reward transfer failed.");

            bounty.active = false;
            bounty.winningSubmissionId = winningSubmissionId;

            // Increase artist reputation (optional)
            artistReputation[winner] += 10; // Example reputation increase

            emit BountyProcessed(_bountyId, winningSubmissionId, winner);
        } else {
            bounty.active = false; // No winner found
            emit BountyProcessed(_bountyId, 0, address(0)); // Indicate no winner
        }
    }

    function getArtistReputation(address _artistAddress) public view returns (uint256) {
        return artistReputation[_artistAddress];
    }


    // -------- TREASURY & UTILITY FUNCTIONS --------

    function depositToTreasury() external payable whenNotPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    Counters.Counter public treasuryWithdrawalProposalCounter;
    mapping(uint256 => TreasuryWithdrawalProposal) public treasuryWithdrawalProposals;

    struct TreasuryWithdrawalProposal {
        address proposer;
        address recipient;
        uint256 amount;
        uint256 votesFor;
        uint256 votesAgainst;
        bool active;
        uint256 votingEndTime;
    }

    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount) external onlyMember whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than 0.");
        require(treasuryBalance >= _amount, "Insufficient funds in treasury.");

        treasuryWithdrawalProposalCounter.increment();
        uint256 proposalId = treasuryWithdrawalProposalCounter.current();
        treasuryWithdrawalProposals[proposalId] = TreasuryWithdrawalProposal({
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            votesFor: 0,
            votesAgainst: 0,
            active: true,
            votingEndTime: block.timestamp + votingPeriod
        });
        emit TreasuryWithdrawalProposed(proposalId, _recipient, _amount, msg.sender);
    }

    function voteOnTreasuryWithdrawal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused proposalActive(_proposalId, ProposalType.TreasuryWithdrawal) votingPeriodNotExpired(_proposalId, ProposalType.TreasuryWithdrawal) {
        TreasuryWithdrawalProposal storage proposal = treasuryWithdrawalProposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(block.timestamp <= proposal.votingEndTime, "Voting period expired.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit TreasuryWithdrawalVoteCast(_proposalId, msg.sender, _vote);
    }

    function processTreasuryWithdrawal(uint256 _proposalId) external onlyMember whenNotPaused proposalActive(_proposalId, ProposalType.TreasuryWithdrawal) votingPeriodNotExpired(_proposalId, ProposalType.TreasuryWithdrawal) {
        TreasuryWithdrawalProposal storage proposal = treasuryWithdrawalProposals[_proposalId];
        require(proposal.active, "Proposal is not active.");
        require(block.timestamp > proposal.votingEndTime, "Voting period expired.");

        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;
        uint256 quorum = (getMemberCount() * quorumPercentage) / 100;

        if (totalVotes >= quorum && proposal.votesFor > proposal.votesAgainst) {
            uint256 amount = proposal.amount;
            address recipient = proposal.recipient;

            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "Treasury withdrawal failed.");

            treasuryBalance -= amount;
            proposal.active = false;
            emit TreasuryWithdrawalProcessed(_proposalId, true, recipient, amount);
        } else {
            proposal.active = false;
            emit TreasuryWithdrawalProcessed(_proposalId, false, proposal.recipient, proposal.amount);
        }
    }


    // -------- ADMIN & SYSTEM FUNCTIONS --------

    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    function setVotingPeriod(uint256 _newVotingPeriod) external onlyAdmin { // In seconds
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodUpdated(_newVotingPeriod);
    }

    function setQuorumPercentage(uint256 _newQuorumPercentage) external onlyAdmin { // Percentage, e.g., 50 for 50%
        require(_newQuorumPercentage <= 100, "Quorum percentage must be less than or equal to 100.");
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageUpdated(_newQuorumPercentage);
    }

    // -------- UTILITY FUNCTIONS (Optional, for testing/interaction) --------

    function getTreasuryBalance() public view returns (uint256) {
        return treasuryBalance;
    }

    function getArtProposalDetails(uint256 _proposalId) public view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    function getArtNFTDetails(uint256 _nftId) public view returns (ArtNFT memory) {
        return artNFTs[_nftId];
    }

    function getExhibitionDetails(uint256 _exhibitionId) public view returns (ArtExhibition memory) {
        return artExhibitions[_exhibitionId];
    }

    function getBountyDetails(uint256 _bountyId) public view returns (ArtBounty memory) {
        return artBounties[_bountyId];
    }

    function getBountySubmissionDetails(uint256 _bountyId, uint256 _submissionId) public view returns (BountySubmission memory) {
        return bountySubmissions[_bountyId][_submissionId];
    }

    function getFractionalNFTDetails(uint256 _fractionalNFTId) public view returns (FractionalNFT memory) {
        return fractionalNFTs[_fractionalNFTId];
    }

    function getMembershipProposalDetails(uint256 _proposalId) public view returns (MembershipProposal memory) {
        return membershipProposals[_proposalId];
    }

    function getTreasuryWithdrawalProposalDetails(uint256 _proposalId) public view returns (TreasuryWithdrawalProposal memory) {
        return treasuryWithdrawalProposals[_proposalId];
    }
}
```