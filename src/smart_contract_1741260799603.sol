```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling artists to submit artwork proposals,
 *      community members to vote on them, mint NFTs of approved artworks, manage a treasury,
 *      collaborate on pieces, participate in art challenges, and more.
 *
 * Function Summary:
 *
 * **Membership & Roles:**
 * 1.  `requestMembership()`: Allows anyone to request membership in the collective.
 * 2.  `approveMembership(address _member)`:  Admin/Curator function to approve a membership request.
 * 3.  `revokeMembership(address _member)`: Admin/Curator function to revoke a member's membership.
 * 4.  `setCuratorRole(address _curator, bool _isCurator)`: Admin function to assign or remove curator roles.
 * 5.  `isMember(address _user)`:  View function to check if an address is a member.
 * 6.  `isCurator(address _user)`: View function to check if an address is a curator.
 *
 * **Artwork Submission & Management:**
 * 7.  `submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Members can submit artwork proposals.
 * 8.  `getArtworkProposal(uint256 _proposalId)`: View function to retrieve artwork proposal details.
 * 9.  `editArtworkProposal(uint256 _proposalId, string memory _title, string memory _description, string memory _ipfsHash)`: Members can edit their submitted proposals before voting starts.
 * 10. `removeArtworkProposal(uint256 _proposalId)`: Members can remove their proposals before voting starts.
 * 11. `startArtworkVoting(uint256 _proposalId, uint256 _votingDurationDays)`: Curator function to start voting on an artwork proposal.
 * 12. `voteOnArtwork(uint256 _proposalId, bool _approve)`: Members can vote on artwork proposals.
 * 13. `finalizeArtworkVoting(uint256 _proposalId)`: Curator function to finalize voting and determine proposal outcome.
 * 14. `mintApprovedArtworkNFT(uint256 _proposalId)`: Curator function to mint an NFT for an approved artwork.
 * 15. `setArtworkSalePrice(uint256 _nftTokenId, uint256 _priceInWei)`: Curator function to set the sale price for an artwork NFT.
 * 16. `purchaseArtworkNFT(uint256 _nftTokenId)`: Anyone can purchase an artwork NFT.
 *
 * **Collaboration & Challenges:**
 * 17. `createArtChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _submissionDeadlineDays)`: Curator function to create an art challenge.
 * 18. `submitChallengeEntry(uint256 _challengeId, string memory _title, string memory _description, string memory _ipfsHash)`: Members can submit entries to art challenges.
 * 19. `startChallengeVoting(uint256 _challengeId, uint256 _votingDurationDays)`: Curator function to start voting for challenge entries.
 * 20. `voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _approve)`: Members can vote on challenge entries.
 * 21. `finalizeChallengeVoting(uint256 _challengeId)`: Curator function to finalize challenge voting and reward winners (e.g., mint NFTs for winning entries, distribute treasury funds).
 *
 * **Treasury & Governance:**
 * 22. `depositToTreasury() payable`:  Anyone can deposit ETH into the collective's treasury.
 * 23. `withdrawFromTreasury(uint256 _amountInWei)`: Curator function to withdraw ETH from the treasury (governed by a future DAO vote could be added).
 * 24. `getTreasuryBalance()`: View function to get the current treasury balance.
 * 25. `setPlatformFeePercentage(uint256 _percentage)`: Admin function to set the platform fee percentage on NFT sales.
 *
 * **Utility & Information:**
 * 26. `getPlatformFeePercentage()`: View function to get the current platform fee percentage.
 * 27. `getNFTContractAddress()`: View function to get the address of the deployed NFT contract.
 * 28. `getProposalVotingStatus(uint256 _proposalId)`: View function to get the current voting status of an artwork proposal.
 * 29. `getChallengeVotingStatus(uint256 _challengeId)`: View function to get the current voting status of an art challenge.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedAutonomousArtCollective is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- State Variables ---

    // Membership Management
    mapping(address => bool) public members;
    mapping(address => bool) public curators;
    address[] public membershipRequests;

    // Artwork Proposals
    struct ArtworkProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 submissionTimestamp;
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool votingActive;
        bool votingFinalized;
        bool proposalApproved;
        bool nftMinted;
    }
    mapping(uint256 => ArtworkProposal) public artworkProposals;
    Counters.Counter private proposalCounter;

    // Voting
    mapping(uint256 => mapping(address => bool)) public hasVotedOnProposal; // proposalId => voter => hasVoted
    uint256 public votingDurationDays = 7 days; // Default voting duration

    // Art Challenges
    struct ArtChallenge {
        uint256 challengeId;
        string title;
        string description;
        uint256 submissionDeadline;
        uint256 votingStartTime;
        uint256 votingEndTime;
        bool votingActive;
        bool votingFinalized;
        mapping(uint256 => ChallengeEntry) challengeEntries; // entryId => ChallengeEntry
        Counters.Counter entryCounter;
    }
    mapping(uint256 => ArtChallenge) public artChallenges;
    Counters.Counter private challengeCounter;

    struct ChallengeEntry {
        uint256 entryId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 submissionTimestamp;
        uint256 yesVotes;
        uint256 noVotes;
        bool entryApproved; // For challenge winners, could be used to mark winners
    }
    mapping(uint256 => mapping(uint256 => bool)) public hasVotedOnChallengeEntry; // challengeId => entryId => voter => hasVoted

    // NFT Minting and Sales
    Counters.Counter private nftTokenCounter;
    mapping(uint256 => uint256) public artworkNFTPrice; // tokenId => price in wei
    uint256 public platformFeePercentage = 5; // Default platform fee percentage (5%)

    // Treasury
    address payable public treasuryAddress;

    // --- Events ---
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event CuratorRoleSet(address indexed curator, bool isCurator);
    event ArtworkProposalSubmitted(uint256 proposalId, address indexed proposer, string title);
    event ArtworkProposalEdited(uint256 proposalId, string title);
    event ArtworkProposalRemoved(uint256 proposalId);
    event ArtworkVotingStarted(uint256 proposalId);
    event ArtworkVoted(uint256 proposalId, address indexed voter, bool approve);
    event ArtworkVotingFinalized(uint256 proposalId, bool proposalApproved);
    event ArtworkNFTMinted(uint256 tokenId, uint256 proposalId, address indexed artist);
    event ArtworkNFTSalePriceSet(uint256 tokenId, uint256 priceInWei);
    event ArtworkNFTPurchased(uint256 tokenId, address indexed buyer, uint256 priceInWei, uint256 platformFee, uint256 artistPayout);
    event ArtChallengeCreated(uint256 challengeId, string title);
    event ChallengeEntrySubmitted(uint256 challengeId, uint256 entryId, address indexed artist, string title);
    event ChallengeVotingStarted(uint256 challengeId);
    event ChallengeEntryVoted(uint256 challengeId, uint256 entryId, address indexed voter, bool approve);
    event ChallengeVotingFinalized(uint256 challengeId);
    event TreasuryDeposit(address indexed depositor, uint256 amountInWei);
    event TreasuryWithdrawal(address indexed withdrawer, uint256 amountInWei);
    event PlatformFeePercentageSet(uint256 percentage);

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender] || msg.sender == owner(), "Only curators or owner can perform this action.");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId) {
        require(artworkProposals[_proposalId].proposer == msg.sender, "Only the proposal proposer can perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(artworkProposals[_proposalId].proposalId != 0, "Artwork proposal does not exist.");
        _;
    }

    modifier votingNotActive(uint256 _proposalId) {
        require(!artworkProposals[_proposalId].votingActive, "Voting is already active for this proposal.");
        _;
    }

    modifier votingActive(uint256 _proposalId) {
        require(artworkProposals[_proposalId].votingActive, "Voting is not active for this proposal.");
        _;
    }

    modifier votingNotFinalized(uint256 _proposalId) {
        require(!artworkProposals[_proposalId].votingFinalized, "Voting is already finalized for this proposal.");
        _;
    }

    modifier notYetMinted(uint256 _proposalId) {
        require(!artworkProposals[_proposalId].nftMinted, "NFT already minted for this proposal.");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(artChallenges[_challengeId].challengeId != 0, "Art challenge does not exist.");
        _;
    }

    modifier challengeVotingNotActive(uint256 _challengeId) {
        require(!artChallenges[_challengeId].votingActive, "Voting is already active for this challenge.");
        _;
    }

    modifier challengeVotingActive(uint256 _challengeId) {
        require(artChallenges[_challengeId].votingActive, "Voting is not active for this challenge.");
        _;
    }

    modifier challengeVotingNotFinalized(uint256 _challengeId) {
        require(!artChallenges[_challengeId].votingFinalized, "Voting is already finalized for this challenge.");
        _;
    }


    // --- Constructor ---
    constructor() ERC721("DAAC Artwork", "DAACART") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Owner is the initial admin
        treasuryAddress = payable(msg.sender); // Initially set treasury to contract deployer, can be changed via governance later
    }

    // --- Membership Management Functions ---

    function requestMembership() external {
        membershipRequests.push(msg.sender);
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyCurator {
        bool found = false;
        for (uint i = 0; i < membershipRequests.length; i++) {
            if (membershipRequests[i] == _member) {
                members[_member] = true;
                membershipRequests[i] = membershipRequests[membershipRequests.length - 1];
                membershipRequests.pop();
                found = true;
                emit MembershipApproved(_member);
                break;
            }
        }
        require(found, "Membership request not found for this address.");
    }

    function revokeMembership(address _member) external onlyCurator {
        require(members[_member], "Address is not a member.");
        members[_member] = false;
        emit MembershipRevoked(_member);
    }

    function setCuratorRole(address _curator, bool _isCurator) external onlyOwner {
        curators[_curator] = _isCurator;
        emit CuratorRoleSet(_curator, _isCurator);
    }

    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    function isCurator(address _user) external view returns (bool) {
        return curators[_user] || _isOwner();
    }


    // --- Artwork Proposal Functions ---

    function submitArtworkProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember {
        proposalCounter.increment();
        uint256 proposalId = proposalCounter.current();
        artworkProposals[proposalId] = ArtworkProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            submissionTimestamp: block.timestamp,
            votingStartTime: 0,
            votingEndTime: 0,
            yesVotes: 0,
            noVotes: 0,
            votingActive: false,
            votingFinalized: false,
            proposalApproved: false,
            nftMinted: false
        });
        emit ArtworkProposalSubmitted(proposalId, msg.sender, _title);
    }

    function getArtworkProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (ArtworkProposal memory) {
        return artworkProposals[_proposalId];
    }

    function editArtworkProposal(uint256 _proposalId, string memory _title, string memory _description, string memory _ipfsHash) external onlyMember onlyProposalProposer(_proposalId) proposalExists(_proposalId) votingNotActive(_proposalId) votingNotFinalized(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        proposal.title = _title;
        proposal.description = _description;
        proposal.ipfsHash = _ipfsHash;
        emit ArtworkProposalEdited(_proposalId, _title);
    }

    function removeArtworkProposal(uint256 _proposalId) external onlyMember onlyProposalProposer(_proposalId) proposalExists(_proposalId) votingNotActive(_proposalId) votingNotFinalized(_proposalId) {
        delete artworkProposals[_proposalId];
        emit ArtworkProposalRemoved(_proposalId);
    }

    function startArtworkVoting(uint256 _proposalId, uint256 _votingDurationDays) external onlyCurator proposalExists(_proposalId) votingNotActive(_proposalId) votingNotFinalized(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        proposal.votingActive = true;
        proposal.votingStartTime = block.timestamp;
        proposal.votingEndTime = block.timestamp + (_votingDurationDays * 1 days);
        emit ArtworkVotingStarted(_proposalId);
    }

    function voteOnArtwork(uint256 _proposalId, bool _approve) external onlyMember proposalExists(_proposalId) votingActive(_proposalId) votingNotFinalized(_proposalId) {
        require(!hasVotedOnProposal[_proposalId][msg.sender], "You have already voted on this proposal.");
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        hasVotedOnProposal[_proposalId][msg.sender] = true;
        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtworkVoted(_proposalId, msg.sender, _approve);
    }

    function finalizeArtworkVoting(uint256 _proposalId) external onlyCurator proposalExists(_proposalId) votingActive(_proposalId) votingNotFinalized(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(block.timestamp > proposal.votingEndTime, "Voting is not yet finished.");
        proposal.votingActive = false;
        proposal.votingFinalized = true;
        if (proposal.yesVotes > proposal.noVotes) {
            proposal.proposalApproved = true;
        } else {
            proposal.proposalApproved = false;
        }
        emit ArtworkVotingFinalized(_proposalId, proposal.proposalApproved);
    }

    function mintApprovedArtworkNFT(uint256 _proposalId) external onlyCurator proposalExists(_proposalId) votingFinalized(_proposalId) notYetMinted(_proposalId) {
        ArtworkProposal storage proposal = artworkProposals[_proposalId];
        require(proposal.proposalApproved, "Proposal was not approved.");
        nftTokenCounter.increment();
        uint256 tokenId = nftTokenCounter.current();
        _safeMint(proposal.proposer, tokenId);
        _setTokenURI(tokenId, proposal.ipfsHash); // Assuming IPFS hash is the URI
        proposal.nftMinted = true;
        emit ArtworkNFTMinted(tokenId, _proposalId, proposal.proposer);
    }

    function setArtworkSalePrice(uint256 _nftTokenId, uint256 _priceInWei) external onlyCurator {
        require(_exists(_nftTokenId), "NFT does not exist.");
        artworkNFTPrice[_nftTokenId] = _priceInWei;
        emit ArtworkNFTSalePriceSet(_nftTokenId, _priceInWei);
    }

    function purchaseArtworkNFT(uint256 _nftTokenId) external payable nonReentrant {
        require(_exists(_nftTokenId), "NFT does not exist.");
        uint256 price = artworkNFTPrice[_nftTokenId];
        require(msg.value >= price, "Insufficient funds sent.");
        require(ownerOf(_nftTokenId) != msg.sender, "Cannot purchase your own NFT.");

        address artist = ownerOf(_nftTokenId);
        uint256 platformFee = (price * platformFeePercentage) / 100;
        uint256 artistPayout = price - platformFee;

        // Transfer funds
        payable(treasuryAddress).transfer(platformFee);
        payable(artist).transfer(artistPayout);
        transferFrom(artist, msg.sender, _nftTokenId);

        emit ArtworkNFTPurchased(_nftTokenId, msg.sender, price, platformFee, artistPayout);
    }


    // --- Art Challenge Functions ---

    function createArtChallenge(string memory _challengeTitle, string memory _challengeDescription, uint256 _submissionDeadlineDays) external onlyCurator {
        challengeCounter.increment();
        uint256 challengeId = challengeCounter.current();
        artChallenges[challengeId] = ArtChallenge({
            challengeId: challengeId,
            title: _challengeTitle,
            description: _challengeDescription,
            submissionDeadline: block.timestamp + (_submissionDeadlineDays * 1 days),
            votingStartTime: 0,
            votingEndTime: 0,
            votingActive: false,
            votingFinalized: false,
            challengeEntries: ArtChallenge.challengeEntries,
            entryCounter: ArtChallenge.entryCounter
        });
        emit ArtChallengeCreated(challengeId, _challengeTitle);
    }

    function submitChallengeEntry(uint256 _challengeId, string memory _title, string memory _description, string memory _ipfsHash) external onlyMember challengeExists(_challengeId) challengeVotingNotActive(_challengeId) challengeVotingNotFinalized(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(block.timestamp < challenge.submissionDeadline, "Submission deadline has passed.");
        challenge.entryCounter.increment();
        uint256 entryId = challenge.entryCounter.current();
        challenge.challengeEntries[entryId] = ChallengeEntry({
            entryId: entryId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            submissionTimestamp: block.timestamp,
            yesVotes: 0,
            noVotes: 0,
            entryApproved: false
        });
        emit ChallengeEntrySubmitted(_challengeId, entryId, msg.sender, _title);
    }

    function startChallengeVoting(uint256 _challengeId, uint256 _votingDurationDays) external onlyCurator challengeExists(_challengeId) challengeVotingNotActive(_challengeId) challengeVotingNotFinalized(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(block.timestamp > challenge.submissionDeadline, "Voting can only start after submission deadline.");
        challenge.votingActive = true;
        challenge.votingStartTime = block.timestamp;
        challenge.votingEndTime = block.timestamp + (_votingDurationDays * 1 days);
        emit ChallengeVotingStarted(_challengeId);
    }

    function voteOnChallengeEntry(uint256 _challengeId, uint256 _entryId, bool _approve) external onlyMember challengeExists(_challengeId) challengeVotingActive(_challengeId) challengeVotingNotFinalized(_challengeId) {
        require(artChallenges[_challengeId].challengeEntries[_entryId].entryId != 0, "Challenge entry does not exist.");
        require(!hasVotedOnChallengeEntry[_challengeId][_entryId][msg.sender], "You have already voted on this entry.");
        ArtChallenge storage challenge = artChallenges[_challengeId];
        ChallengeEntry storage entry = challenge.challengeEntries[_entryId];
        hasVotedOnChallengeEntry[_challengeId][_entryId][msg.sender] = true;
        if (_approve) {
            entry.yesVotes++;
        } else {
            entry.noVotes++;
        }
        emit ChallengeEntryVoted(_challengeId, _entryId, msg.sender, _approve);
    }

    function finalizeChallengeVoting(uint256 _challengeId) external onlyCurator challengeExists(_challengeId) challengeVotingActive(_challengeId) challengeVotingNotFinalized(_challengeId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(block.timestamp > challenge.votingEndTime, "Challenge voting is not yet finished.");
        challenge.votingActive = false;
        challenge.votingFinalized = true;
        // Logic to determine winners (e.g., entries with most yesVotes) and reward them can be added here
        // For example, mint NFTs for top entries, distribute treasury funds, etc.
        emit ChallengeVotingFinalized(_challengeId);
    }


    // --- Treasury Functions ---

    function depositToTreasury() external payable {
        treasuryAddress.transfer(msg.value); // Send directly to treasury address
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function withdrawFromTreasury(uint256 _amountInWei) external onlyCurator {
        require(address(this).balance >= _amountInWei, "Insufficient treasury balance.");
        payable(msg.sender).transfer(_amountInWei);
        emit TreasuryWithdrawal(msg.sender, _amountInWei);
    }

    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setPlatformFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }


    // --- Utility & Information Functions ---

    function getPlatformFeePercentage() external view returns (uint256) {
        return platformFeePercentage;
    }

    function getNFTContractAddress() external view returns (address) {
        return address(this);
    }

    function getProposalVotingStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (bool votingActiveStatus, bool votingFinalizedStatus) {
        return (artworkProposals[_proposalId].votingActive, artworkProposals[_proposalId].votingFinalized);
    }

    function getChallengeVotingStatus(uint256 _challengeId) external view challengeExists(_challengeId) returns (bool votingActiveStatus, bool votingFinalizedStatus) {
        return (artChallenges[_challengeId].votingActive, artChallenges[_challengeId].votingFinalized);
    }

    // Function to get the list of membership requests (for admin/curator UI)
    function getMembershipRequests() external view onlyCurator returns (address[] memory) {
        return membershipRequests;
    }
}
```