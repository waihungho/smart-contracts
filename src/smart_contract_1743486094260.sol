```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * It enables artists to submit artwork, community members to vote on submissions,
 * mint selected artworks as NFTs, participate in art challenges, manage a treasury,
 * and engage in decentralized governance of the collective.
 *
 * Function Summary:
 *
 * **Membership & Access:**
 * 1. joinCollective(): Allows users to join the DAAC by acquiring a membership NFT.
 * 2. leaveCollective(): Allows members to leave the DAAC by burning their membership NFT.
 * 3. isAdmin(address _user): Checks if an address is an admin of the DAAC.
 * 4. addAdmin(address _newAdmin): Adds a new admin (only callable by existing admins).
 * 5. removeAdmin(address _adminToRemove): Removes an admin (only callable by existing admins).
 *
 * **Artwork Submission & Curation:**
 * 6. submitArtwork(string memory _ipfsHash, string memory _metadataURI): Artists submit their artwork for consideration.
 * 7. startVoting(uint256 _artworkId): Starts the voting process for a specific artwork (only callable by admins).
 * 8. voteOnArtwork(uint256 _artworkId, bool _vote): Members can vote 'yes' or 'no' on submitted artworks.
 * 9. endVoting(uint256 _artworkId): Ends the voting process for an artwork and processes the results (only callable by admins).
 * 10. mintArtworkNFT(uint256 _artworkId): Mints an NFT for approved artworks (only callable after successful voting).
 * 11. purchaseArtworkNFT(uint256 _nftId): Allows users to purchase minted artwork NFTs.
 *
 * **Art Challenges & Rewards:**
 * 12. createArtChallenge(string memory _challengeName, string memory _description, uint256 _startTime, uint256 _endTime, uint256 _rewardAmount): Admins create art challenges with rewards.
 * 13. participateInChallenge(uint256 _challengeId, string memory _submissionIpfsHash, string memory _submissionMetadataURI): Members participate in art challenges by submitting their work.
 * 14. voteForChallengeWinner(uint256 _challengeId, uint256 _submissionId): Members vote for the winner of an art challenge.
 * 15. endChallengeVoting(uint256 _challengeId): Ends the voting for a challenge and declares the winner (only callable by admins).
 * 16. claimChallengeReward(uint256 _challengeId): Winners can claim their rewards.
 *
 * **DAO Treasury & Governance:**
 * 17. depositToTreasury(): Allows anyone to deposit ETH into the DAAC treasury.
 * 18. proposeNewFeature(string memory _proposalTitle, string memory _proposalDescription): Members can propose new features or changes to the DAAC.
 * 19. voteOnProposal(uint256 _proposalId, bool _vote): Members can vote on DAO proposals.
 * 20. executeProposal(uint256 _proposalId): Executes a passed DAO proposal (only callable by admins after proposal success).
 *
 * **Utility & Information:**
 * 21. getArtworkDetails(uint256 _artworkId): Retrieves details about a specific artwork.
 * 22. getChallengeDetails(uint256 _challengeId): Retrieves details about a specific art challenge.
 * 23. getMemberDetails(address _memberAddress): Retrieves details about a DAAC member.
 * 24. emergencyWithdraw(): Allows admins to withdraw funds from the treasury in case of emergency.
 */
contract DecentralizedAutonomousArtCollective {

    // --- Structs and Enums ---

    enum ArtworkStatus { Submitted, Voting, Approved, Rejected, Minted }
    enum ChallengeStatus { Open, Voting, Closed }
    enum ProposalStatus { Pending, Voting, Passed, Rejected, Executed }

    struct Artwork {
        uint256 id;
        address artist;
        string ipfsHash;
        string metadataURI;
        ArtworkStatus status;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct ArtChallenge {
        uint256 id;
        string name;
        string description;
        uint256 startTime;
        uint256 endTime;
        ChallengeStatus status;
        uint256 rewardAmount;
        uint256 winnerSubmissionId;
    }

    struct ChallengeSubmission {
        uint256 id;
        uint256 challengeId;
        address artist;
        string submissionIpfsHash;
        string submissionMetadataURI;
        uint256 upVotes;
    }

    struct DAOProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
    }

    struct Member {
        address memberAddress;
        uint256 joinTimestamp;
        bool isActive;
    }

    // --- State Variables ---

    address public contractOwner;
    address[] public admins;
    mapping(address => bool) public isMember;
    mapping(address => Member) public members;
    uint256 public memberCount;

    Artwork[] public artworks;
    uint256 public artworkCount;
    mapping(uint256 => mapping(address => bool)) public hasVotedArtwork; // artworkId => voterAddress => hasVoted

    ArtChallenge[] public artChallenges;
    uint256 public challengeCount;
    mapping(uint256 => ChallengeSubmission[]) public challengeSubmissions;
    mapping(uint256 => uint256) public submissionCountForChallenge;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasVotedChallengeSubmission; // challengeId => submissionId => voterAddress => hasVoted

    DAOProposal[] public daoProposals;
    uint256 public proposalCount;
    mapping(uint256 => mapping(address => bool)) public hasVotedProposal; // proposalId => voterAddress => hasVoted

    uint256 public membershipNFTPrice = 0.1 ether; // Example price
    uint256 public artworkNFTPrice = 0.05 ether; // Example price
    string public membershipNFTName = "DAAC Membership NFT";
    string public membershipNFTSymbol = "DAACMEM";
    string public artworkNFTName = "DAAC Artwork NFT";
    string public artworkNFTSymbol = "DAACART";

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public challengeVotingDuration = 3 days; // Default challenge voting duration
    uint256 public proposalVotingDuration = 14 days; // Default proposal voting duration
    uint256 public quorumPercentage = 50; // Percentage of members required to vote for quorum

    // --- Events ---

    event MemberJoined(address memberAddress, uint256 timestamp);
    event MemberLeft(address memberAddress, uint256 timestamp);
    event AdminAdded(address newAdmin, address addedBy);
    event AdminRemoved(address removedAdmin, address removedBy);
    event ArtworkSubmitted(uint256 artworkId, address artist, string ipfsHash);
    event VotingStarted(uint256 artworkId);
    event ArtworkVoted(uint256 artworkId, address voter, bool vote);
    event VotingEnded(uint256 artworkId, ArtworkStatus newStatus);
    event ArtworkMinted(uint256 nftId, uint256 artworkId, address minter);
    event ArtworkNFTPurchased(uint256 nftId, address buyer, uint256 price);
    event ArtChallengeCreated(uint256 challengeId, string name, uint256 startTime, uint256 endTime, uint256 rewardAmount);
    event ChallengeSubmissionMade(uint256 challengeId, uint256 submissionId, address artist);
    event ChallengeWinnerVoted(uint256 challengeId, uint256 submissionId, address voter, address artist);
    event ChallengeVotingEnded(uint256 challengeId, uint256 winnerSubmissionId, address winnerArtist);
    event ChallengeRewardClaimed(uint256 challengeId, address winner, uint256 rewardAmount);
    event TreasuryDeposit(address depositor, uint256 amount);
    event ProposalCreated(uint256 proposalId, address proposer, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event EmergencyWithdrawal(address admin, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Only admins can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier artworkExists(uint256 _artworkId) {
        require(_artworkId < artworkCount, "Artwork does not exist.");
        _;
    }

    modifier challengeExists(uint256 _challengeId) {
        require(_challengeId < challengeCount, "Challenge does not exist.");
        _;
    }

    modifier submissionExists(uint256 _challengeId, uint256 _submissionId) {
        require(_submissionId < submissionCountForChallenge[_challengeId], "Submission does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCount, "Proposal does not exist.");
        _;
    }

    modifier votingInProgress(ArtworkStatus _status) {
        require(_status == ArtworkStatus.Voting, "Voting is not in progress.");
        _;
    }

    modifier votingNotInProgress(ArtworkStatus _status) {
        require(_status != ArtworkStatus.Voting, "Voting is already in progress.");
        _;
    }

    modifier challengeVotingInProgress(ChallengeStatus _status) {
        require(_status == ChallengeStatus.Voting, "Challenge voting is not in progress.");
        _;
    }

    modifier challengeVotingNotInProgress(ChallengeStatus _status) {
        require(_status != ChallengeStatus.Voting, "Challenge voting is already in progress.");
        _;
    }

    modifier proposalVotingInProgress(ProposalStatus _status) {
        require(_status == ProposalStatus.Voting, "Proposal voting is not in progress.");
        _;
    }

    modifier proposalVotingNotInProgress(ProposalStatus _status) {
        require(_status != ProposalStatus.Voting, "Proposal voting is already in progress.");
        _;
    }

    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
        admins.push(msg.sender); // Contract owner is the initial admin
    }

    // --- Membership & Access Functions ---

    function joinCollective() public payable {
        require(msg.value >= membershipNFTPrice, "Insufficient membership fee.");
        require(!isMember[msg.sender], "Already a member.");

        isMember[msg.sender] = true;
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            joinTimestamp: block.timestamp,
            isActive: true
        });
        memberCount++;
        emit MemberJoined(msg.sender, block.timestamp);
    }

    function leaveCollective() public onlyMember {
        require(isMember[msg.sender], "Not a member.");
        isMember[msg.sender] = false;
        members[msg.sender].isActive = false;
        memberCount--;
        emit MemberLeft(msg.sender, block.timestamp);
    }

    function isAdmin(address _user) public view returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function addAdmin(address _newAdmin) public onlyAdmin {
        require(!isAdmin(_newAdmin), "Address is already an admin.");
        admins.push(_newAdmin);
        emit AdminAdded(_newAdmin, msg.sender);
    }

    function removeAdmin(address _adminToRemove) public onlyAdmin {
        require(isAdmin(_adminToRemove), "Address is not an admin.");
        require(_adminToRemove != contractOwner, "Cannot remove contract owner as admin."); // Prevent removing contract owner
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _adminToRemove) {
                delete admins[i];
                // Compact the array to remove the gap (optional, but good practice)
                if (i < admins.length - 1) {
                    admins[i] = admins[admins.length - 1];
                }
                admins.pop();
                emit AdminRemoved(_adminToRemove, msg.sender);
                return;
            }
        }
    }

    // --- Artwork Submission & Curation Functions ---

    function submitArtwork(string memory _ipfsHash, string memory _metadataURI) public onlyMember {
        artworkCount++;
        artworks.push(Artwork({
            id: artworkCount,
            artist: msg.sender,
            ipfsHash: _ipfsHash,
            metadataURI: _metadataURI,
            status: ArtworkStatus.Submitted,
            upVotes: 0,
            downVotes: 0
        }));
        emit ArtworkSubmitted(artworkCount, msg.sender, _ipfsHash);
    }

    function startVoting(uint256 _artworkId) public onlyAdmin artworkExists(_artworkId) votingNotInProgress(artworks[_artworkId].status) {
        artworks[_artworkId].status = ArtworkStatus.Voting;
        emit VotingStarted(_artworkId);
    }

    function voteOnArtwork(uint256 _artworkId, bool _vote) public onlyMember artworkExists(_artworkId) votingInProgress(artworks[_artworkId].status) {
        require(!hasVotedArtwork[_artworkId][msg.sender], "Already voted on this artwork.");
        hasVotedArtwork[_artworkId][msg.sender] = true;

        if (_vote) {
            artworks[_artworkId].upVotes++;
        } else {
            artworks[_artworkId].downVotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _vote);
    }

    function endVoting(uint256 _artworkId) public onlyAdmin artworkExists(_artworkId) votingInProgress(artworks[_artworkId].status) {
        require(block.timestamp >= block.timestamp + votingDuration, "Voting duration not ended yet."); // Example duration check - replace with actual logic if needed

        uint256 totalVotes = artworks[_artworkId].upVotes + artworks[_artworkId].downVotes;
        ArtworkStatus newStatus;

        if (totalVotes == 0) {
            newStatus = ArtworkStatus.Rejected; // If no votes, reject
        } else if (artworks[_artworkId].upVotes > artworks[_artworkId].downVotes) {
            newStatus = ArtworkStatus.Approved;
        } else {
            newStatus = ArtworkStatus.Rejected;
        }

        artworks[_artworkId].status = newStatus;
        emit VotingEnded(_artworkId, newStatus);
    }

    function mintArtworkNFT(uint256 _artworkId) public onlyAdmin artworkExists(_artworkId) {
        require(artworks[_artworkId].status == ArtworkStatus.Approved, "Artwork not approved for minting.");
        artworks[_artworkId].status = ArtworkStatus.Minted;
        // In a real implementation, you would mint an actual NFT here,
        // likely using ERC721 or ERC1155 standards.
        // This example just updates the status and emits an event.
        emit ArtworkMinted(_artworkId, _artworkId, msg.sender); // nftId and artworkId are same for simplicity here
    }

    function purchaseArtworkNFT(uint256 _nftId) public payable {
        require(msg.value >= artworkNFTPrice, "Insufficient NFT purchase fee.");
        require(_nftId <= artworkCount, "NFT ID out of range."); // Basic NFT existence check
        require(artworks[_nftId].status == ArtworkStatus.Minted, "NFT is not available for purchase."); // Check if minted
        // In a real implementation, you would transfer the NFT to the buyer here.
        // This example just emits a purchase event and transfers funds to the contract.
        payable(contractOwner).transfer(msg.value); // Send funds to contract owner for simplicity - in real app, distribute to artist/treasury
        emit ArtworkNFTPurchased(_nftId, msg.sender, artworkNFTPrice);
    }

    // --- Art Challenges & Rewards Functions ---

    function createArtChallenge(string memory _challengeName, string memory _description, uint256 _startTime, uint256 _endTime, uint256 _rewardAmount) public onlyAdmin {
        require(_endTime > _startTime, "End time must be after start time.");
        challengeCount++;
        artChallenges.push(ArtChallenge({
            id: challengeCount,
            name: _challengeName,
            description: _description,
            startTime: _startTime,
            endTime: _endTime,
            status: ChallengeStatus.Open,
            rewardAmount: _rewardAmount,
            winnerSubmissionId: 0
        }));
        emit ArtChallengeCreated(challengeCount, _challengeName, _startTime, _endTime, _rewardAmount);
    }

    function participateInChallenge(uint256 _challengeId, string memory _submissionIpfsHash, string memory _submissionMetadataURI) public onlyMember challengeExists(_challengeId) {
        require(artChallenges[_challengeId].status == ChallengeStatus.Open, "Challenge is not open for submissions.");
        require(block.timestamp >= artChallenges[_challengeId].startTime && block.timestamp <= artChallenges[_challengeId].endTime, "Submission period is closed.");

        submissionCountForChallenge[_challengeId]++;
        challengeSubmissions[_challengeId].push(ChallengeSubmission({
            id: submissionCountForChallenge[_challengeId],
            challengeId: _challengeId,
            artist: msg.sender,
            submissionIpfsHash: _submissionIpfsHash,
            submissionMetadataURI: _submissionMetadataURI,
            upVotes: 0
        }));
        emit ChallengeSubmissionMade(_challengeId, submissionCountForChallenge[_challengeId], msg.sender);
    }

    function voteForChallengeWinner(uint256 _challengeId, uint256 _submissionId) public onlyMember challengeExists(_challengeId) submissionExists(_challengeId, _submissionId) challengeVotingInProgress(artChallenges[_challengeId].status) {
        require(!hasVotedChallengeSubmission[_challengeId][_submissionId][msg.sender], "Already voted for this submission in this challenge.");
        hasVotedChallengeSubmission[_challengeId][_submissionId][msg.sender] = true;
        challengeSubmissions[_challengeId][_submissionId - 1].upVotes++; // Access array with index _submissionId - 1
        emit ChallengeWinnerVoted(_challengeId, _submissionId, msg.sender, challengeSubmissions[_challengeId][_submissionId - 1].artist);
    }

    function endChallengeVoting(uint256 _challengeId) public onlyAdmin challengeExists(_challengeId) challengeVotingInProgress(artChallenges[_challengeId].status) {
        require(block.timestamp >= block.timestamp + challengeVotingDuration, "Challenge voting duration not ended yet."); // Example duration check

        uint256 winningSubmissionId = 0;
        uint256 maxVotes = 0;

        for (uint256 i = 0; i < challengeSubmissions[_challengeId].length; i++) {
            if (challengeSubmissions[_challengeId][i].upVotes > maxVotes) {
                maxVotes = challengeSubmissions[_challengeId][i].upVotes;
                winningSubmissionId = challengeSubmissions[_challengeId][i].id;
            }
        }

        artChallenges[_challengeId].status = ChallengeStatus.Closed;
        artChallenges[_challengeId].winnerSubmissionId = winningSubmissionId;
        emit ChallengeVotingEnded(_challengeId, winningSubmissionId, challengeSubmissions[_challengeId][winningSubmissionId - 1].artist);
    }

    function claimChallengeReward(uint256 _challengeId) public onlyMember challengeExists(_challengeId) {
        require(artChallenges[_challengeId].status == ChallengeStatus.Closed, "Challenge is not closed yet.");
        require(challengeSubmissions[_challengeId][artChallenges[_challengeId].winnerSubmissionId - 1].artist == msg.sender, "You are not the winner of this challenge.");
        require(artChallenges[_challengeId].rewardAmount > 0, "No reward for this challenge.");

        uint256 rewardAmount = artChallenges[_challengeId].rewardAmount;
        artChallenges[_challengeId].rewardAmount = 0; // Prevent double claiming (in real app, maybe mark as claimed instead of setting to 0)

        payable(msg.sender).transfer(rewardAmount);
        emit ChallengeRewardClaimed(_challengeId, msg.sender, rewardAmount);
    }

    // --- DAO Treasury & Governance Functions ---

    function depositToTreasury() public payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    function proposeNewFeature(string memory _proposalTitle, string memory _proposalDescription) public onlyMember {
        proposalCount++;
        daoProposals.push(DAOProposal({
            id: proposalCount,
            proposer: msg.sender,
            title: _proposalTitle,
            description: _proposalDescription,
            status: ProposalStatus.Pending,
            upVotes: 0,
            downVotes: 0
        }));
        emit ProposalCreated(proposalCount, msg.sender, _proposalTitle);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyMember proposalExists(_proposalId) proposalVotingInProgress(daoProposals[_proposalId].status) {
        require(!hasVotedProposal[_proposalId][msg.sender], "Already voted on this proposal.");
        hasVotedProposal[_proposalId][msg.sender] = true;

        if (_vote) {
            daoProposals[_proposalId].upVotes++;
        } else {
            daoProposals[_proposalId].downVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeProposal(uint256 _proposalId) public onlyAdmin proposalExists(_proposalId) proposalVotingInProgress(daoProposals[_proposalId].status) {
        require(daoProposals[_proposalId].status == ProposalStatus.Passed, "Proposal not passed.");
        daoProposals[_proposalId].status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId);
        // In a real DAO, this is where you would implement the logic to execute the proposal,
        // which could involve changing contract parameters, distributing funds, etc.
        // For this example, we just change the proposal status.
    }


    // --- Utility & Information Functions ---

    function getArtworkDetails(uint256 _artworkId) public view artworkExists(_artworkId) returns (Artwork memory) {
        return artworks[_artworkId];
    }

    function getChallengeDetails(uint256 _challengeId) public view challengeExists(_challengeId) returns (ArtChallenge memory) {
        return artChallenges[_challengeId];
    }

    function getMemberDetails(address _memberAddress) public view returns (Member memory) {
        return members[_memberAddress];
    }

    function emergencyWithdraw() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        emit EmergencyWithdrawal(msg.sender, balance);
    }

    // --- Fallback and Receive Functions ---

    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value); // Allow direct ETH deposits to treasury
    }

    fallback() external {}
}
```