```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @notice A smart contract for a Decentralized Autonomous Art Collective, enabling artists to submit, curate, and collectively own digital art.
 *
 * **Outline:**
 * 1. **Art Submission and Curation:**
 *    - `submitArt(string _ipfsHash, string _title, string _description)`: Artists submit art with IPFS hash, title, and description.
 *    - `getPendingArtSubmissions()`: View list of pending art submissions for curation.
 *    - `voteForArt(uint256 _submissionId, bool _approve)`: Members vote to approve or reject submitted art.
 *    - `tallyArtVotes(uint256 _submissionId)`: Owner tallies votes for a submission after voting period.
 *    - `getArtSubmissionStatus(uint256 _submissionId)`: View status of an art submission (pending, accepted, rejected).
 *    - `getApprovedArtworks()`: View list of approved artworks.
 *
 * 2. **Fractional Ownership and Shares:**
 *    - `mintArtShares(uint256 _artworkId, uint256 _amount)`: Owner mints shares representing fractional ownership of an approved artwork.
 *    - `transferArtShares(uint256 _artworkId, address _to, uint256 _amount)`: Members can transfer shares of an artwork.
 *    - `getArtSharesBalance(uint256 _artworkId, address _member)`: View a member's share balance for a specific artwork.
 *    - `getTotalArtShares(uint256 _artworkId)`: Get the total shares minted for an artwork.
 *
 * 3. **Dynamic Art Evolution (Community-Driven):**
 *    - `proposeArtEvolution(uint256 _artworkId, string _evolutionProposal)`: Members propose evolutions for accepted artworks (e.g., new color palette, minor changes).
 *    - `voteForEvolution(uint256 _artworkId, uint256 _proposalId, bool _approve)`: Share holders of an artwork vote on evolution proposals.
 *    - `tallyEvolutionVotes(uint256 _artworkId, uint256 _proposalId)`: Owner tallies votes for an evolution proposal.
 *    - `applyArtEvolution(uint256 _artworkId, uint256 _proposalId)`: Owner applies an approved evolution proposal to the artwork (updates metadata, IPFS hash - conceptually).
 *    - `getArtEvolutionProposals(uint256 _artworkId)`: View proposals for a specific artwork.
 *    - `getCurrentArtEvolution(uint256 _artworkId)`: Get the current evolution details of an artwork.
 *
 * 4. **Community Treasury and Revenue Sharing:**
 *    - `depositToTreasury()`: Members can deposit funds to the community treasury.
 *    - `proposeTreasurySpending(address _recipient, uint256 _amount, string _reason)`: Members propose spending from the treasury for collective purposes.
 *    - `voteOnTreasurySpending(uint256 _proposalId, bool _approve)`: Members vote on treasury spending proposals.
 *    - `tallyTreasuryVotes(uint256 _proposalId)`: Owner tallies votes for a treasury spending proposal.
 *    - `executeTreasurySpending(uint256 _proposalId)`: Owner executes approved treasury spending.
 *    - `getTreasuryBalance()`: View the current community treasury balance.
 *
 * 5. **Reputation and Governance:**
 *    - `earnReputation(address _member, uint256 _amount, string _reason)`: Owner can award reputation points to members for contributions.
 *    - `getMemberReputation(address _member)`: View a member's reputation points.
 *    - `setVotingPowerByReputation(bool _enabled)`: Owner can enable/disable voting power based on reputation.
 *    - `getVotingWeight(address _voter)`: Get the voting weight of a member based on shares and reputation (if enabled).
 *
 * 6. **Emergency and Admin Functions:**
 *    - `pauseContract()`: Owner can pause core functionalities in case of emergency.
 *    - `unpauseContract()`: Owner can unpause the contract.
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Owner can set the default voting duration.
 *    - `withdrawTreasuryFunds(address _recipient, uint256 _amount)`: Owner can withdraw treasury funds (for extreme emergency - use with caution).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DecentralizedArtCollective is Ownable, Pausable {
    using SafeMath for uint256;

    // -------- Structs and Enums --------

    enum ArtSubmissionStatus { Pending, Accepted, Rejected }
    enum EvolutionProposalStatus { Pending, Approved, Rejected }
    enum TreasuryProposalStatus { Pending, Approved, Rejected }

    struct ArtSubmission {
        string ipfsHash;
        string title;
        string description;
        address artist;
        ArtSubmissionStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 submissionTimestamp;
    }

    struct Artwork {
        string initialIpfsHash;
        string currentIpfsHash; // To track evolutions
        string title;
        string description;
        address artist;
        uint256 acceptanceTimestamp;
        uint256 totalShares;
    }

    struct EvolutionProposal {
        uint256 artworkId;
        string proposalDescription;
        address proposer;
        EvolutionProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalTimestamp;
    }

    struct TreasurySpendingProposal {
        address recipient;
        uint256 amount;
        string reason;
        address proposer;
        TreasuryProposalStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 proposalTimestamp;
    }

    // -------- State Variables --------

    uint256 public votingDuration = 100; // Default voting duration in blocks
    uint256 public submissionCounter = 0;
    uint256 public artworkCounter = 0;
    uint256 public evolutionProposalCounter = 0;
    uint256 public treasuryProposalCounter = 0;
    bool public reputationBasedVotingEnabled = false;

    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => Artwork) public artworks;
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    mapping(uint256 => mapping(address => bool)) public artSubmissionVotes; // submissionId => voter => vote (true=for, false=against)
    mapping(uint256 => mapping(address => bool)) public evolutionVotes; // artworkId => voter => vote (true=for, false=against)
    mapping(uint256 => mapping(address => bool)) public treasuryVotes; // proposalId => voter => vote (true=for, false=against)
    mapping(uint256 => mapping(address => uint256)) public artworkShares; // artworkId => member => share balance
    mapping(address => uint256) public memberReputation; // member address => reputation points

    // -------- Events --------

    event ArtSubmitted(uint256 submissionId, address artist, string ipfsHash, string title);
    event ArtVoteCast(uint256 submissionId, address voter, bool approve);
    event ArtAccepted(uint256 artworkId, uint256 submissionId, string ipfsHash, string title);
    event ArtRejected(uint256 submissionId);
    event ArtSharesMinted(uint256 artworkId, uint256 amount);
    event ArtSharesTransferred(uint256 artworkId, address from, address to, uint256 amount);
    event EvolutionProposed(uint256 artworkId, uint256 proposalId, string proposalDescription, address proposer);
    event EvolutionVoteCast(uint256 artworkId, uint256 proposalId, address voter, bool approve);
    event EvolutionApplied(uint256 artworkId, uint256 proposalId, string newIpfsHash);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address recipient, uint256 amount, string reason, address proposer);
    event TreasuryVoteCast(uint256 proposalId, address voter, bool approve);
    event TreasurySpendingExecuted(uint256 proposalId, address recipient, uint256 amount);
    event ReputationEarned(address member, uint256 amount, string reason);
    event ContractPaused();
    event ContractUnpaused();
    event VotingDurationChanged(uint256 newDuration);
    event TreasuryWithdrawal(address recipient, uint256 amount);

    // -------- Modifiers --------

    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    modifier onlyMember() {
        require(getVotingWeight(msg.sender) > 0, "You are not a member with voting power.");
        _;
    }

    modifier onlyArtist(uint256 _submissionId) {
        require(artSubmissions[_submissionId].artist == msg.sender, "You are not the artist of this submission.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= submissionCounter, "Invalid submission ID");
        _;
    }

    modifier validArtworkId(uint256 _artworkId) {
        require(_artworkId > 0 && _artworkId <= artworkCounter, "Invalid artwork ID");
        _;
    }

    modifier validEvolutionProposalId(uint256 _artworkId, uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= evolutionProposalCounter, "Invalid evolution proposal ID");
        require(evolutionProposals[_proposalId].artworkId == _artworkId, "Proposal ID does not belong to this artwork.");
        _;
    }

    modifier validTreasuryProposalId(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= treasuryProposalCounter, "Invalid treasury proposal ID");
        _;
    }

    modifier submissionVotingActive(uint256 _submissionId) {
        require(artSubmissions[_submissionId].status == ArtSubmissionStatus.Pending, "Submission voting is not active.");
        require(block.number < artSubmissions[_submissionId].submissionTimestamp + votingDuration, "Voting period has ended.");
        _;
    }

    modifier evolutionVotingActive(uint256 _artworkId, uint256 _proposalId) {
        require(evolutionProposals[_proposalId].status == EvolutionProposalStatus.Pending, "Evolution proposal voting is not active.");
        require(block.number < evolutionProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has ended.");
        _;
    }

    modifier treasuryVotingActive(uint256 _proposalId) {
        require(treasurySpendingProposals[_proposalId].status == TreasuryProposalStatus.Pending, "Treasury proposal voting is not active.");
        require(block.number < treasurySpendingProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has ended.");
        _;
    }

    modifier onlyShareholder(uint256 _artworkId) {
        require(artworkShares[_artworkId][msg.sender] > 0, "You are not a shareholder of this artwork.");
        _;
    }

    // -------- 1. Art Submission and Curation Functions --------

    /**
     * @notice Artists submit their digital art for consideration by the collective.
     * @param _ipfsHash IPFS hash of the artwork's metadata.
     * @param _title Title of the artwork.
     * @param _description Description of the artwork.
     */
    function submitArt(string memory _ipfsHash, string memory _title, string memory _description) external whenNotPaused {
        submissionCounter++;
        artSubmissions[submissionCounter] = ArtSubmission({
            ipfsHash: _ipfsHash,
            title: _title,
            description: _description,
            artist: msg.sender,
            status: ArtSubmissionStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            submissionTimestamp: block.number
        });
        emit ArtSubmitted(submissionCounter, msg.sender, _ipfsHash, _title);
    }

    /**
     * @notice Allows anyone to view a list of pending art submissions.
     * @return An array of submission IDs that are currently pending.
     */
    function getPendingArtSubmissions() external view returns (uint256[] memory) {
        uint256[] memory pendingSubmissions = new uint256[](submissionCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= submissionCounter; i++) {
            if (artSubmissions[i].status == ArtSubmissionStatus.Pending) {
                pendingSubmissions[count] = i;
                count++;
            }
        }
        // Resize array to actual number of pending submissions
        uint256[] memory resizedPendingSubmissions = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedPendingSubmissions[i] = pendingSubmissions[i];
        }
        return resizedPendingSubmissions;
    }

    /**
     * @notice Members vote to approve or reject a submitted artwork.
     * @param _submissionId ID of the art submission to vote on.
     * @param _approve True to approve, false to reject.
     */
    function voteForArt(uint256 _submissionId, bool _approve) external whenNotPaused onlyMember validSubmissionId(_submissionId) submissionVotingActive(_submissionId) {
        require(!artSubmissionVotes[_submissionId][msg.sender], "You have already voted on this submission.");
        artSubmissionVotes[_submissionId][msg.sender] = true; // Record vote to prevent double voting

        if (_approve) {
            artSubmissions[_submissionId].votesFor = artSubmissions[_submissionId].votesFor + getVotingWeight(msg.sender);
        } else {
            artSubmissions[_submissionId].votesAgainst = artSubmissions[_submissionId].votesAgainst + getVotingWeight(msg.sender);
        }
        emit ArtVoteCast(_submissionId, msg.sender, _approve);
    }

    /**
     * @notice Owner tallies the votes for an art submission and determines if it's accepted or rejected.
     * @param _submissionId ID of the art submission to tally votes for.
     */
    function tallyArtVotes(uint256 _submissionId) external onlyOwner validSubmissionId(_submissionId) {
        require(artSubmissions[_submissionId].status == ArtSubmissionStatus.Pending, "Votes have already been tallied for this submission.");
        require(block.number >= artSubmissions[_submissionId].submissionTimestamp + votingDuration, "Voting period has not ended yet.");

        if (artSubmissions[_submissionId].votesFor > artSubmissions[_submissionId].votesAgainst) {
            _acceptArtSubmission(_submissionId);
        } else {
            _rejectArtSubmission(_submissionId);
        }
    }

    /**
     * @notice Internal function to accept an art submission.
     * @param _submissionId ID of the art submission to accept.
     */
    function _acceptArtSubmission(uint256 _submissionId) internal {
        artworks[artworkCounter] = Artwork({
            initialIpfsHash: artSubmissions[_submissionId].ipfsHash,
            currentIpfsHash: artSubmissions[_submissionId].ipfsHash, // Initially same as initial
            title: artSubmissions[_submissionId].title,
            description: artSubmissions[_submissionId].description,
            artist: artSubmissions[_submissionId].artist,
            acceptanceTimestamp: block.timestamp,
            totalShares: 0 // Shares are minted separately
        });
        artSubmissions[_submissionId].status = ArtSubmissionStatus.Accepted;
        emit ArtAccepted(artworkCounter, _submissionId, artSubmissions[_submissionId].ipfsHash, artSubmissions[_submissionId].title);
        artworkCounter++;
    }

    /**
     * @notice Internal function to reject an art submission.
     * @param _submissionId ID of the art submission to reject.
     */
    function _rejectArtSubmission(uint256 _submissionId) internal {
        artSubmissions[_submissionId].status = ArtSubmissionStatus.Rejected;
        emit ArtRejected(_submissionId);
    }

    /**
     * @notice Get the status of an art submission.
     * @param _submissionId ID of the art submission.
     * @return The status of the submission (Pending, Accepted, Rejected).
     */
    function getArtSubmissionStatus(uint256 _submissionId) external view validSubmissionId(_submissionId) returns (ArtSubmissionStatus) {
        return artSubmissions[_submissionId].status;
    }

    /**
     * @notice Get a list of IDs of all approved artworks.
     * @return An array of artwork IDs that have been approved.
     */
    function getApprovedArtworks() external view returns (uint256[] memory) {
        uint256[] memory approvedArtworks = new uint256[](artworkCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= artworkCounter; i++) {
            if (artworks[i].acceptanceTimestamp > 0) { // Simple check for acceptance
                approvedArtworks[count] = i;
                count++;
            }
        }
        uint256[] memory resizedApprovedArtworks = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedApprovedArtworks[i] = approvedArtworks[i];
        }
        return resizedApprovedArtworks;
    }


    // -------- 2. Fractional Ownership and Shares Functions --------

    /**
     * @notice Owner mints shares for an approved artwork, representing fractional ownership.
     * @param _artworkId ID of the artwork to mint shares for.
     * @param _amount Number of shares to mint.
     */
    function mintArtShares(uint256 _artworkId, uint256 _amount) external onlyOwner validArtworkId(_artworkId) {
        artworks[_artworkId].totalShares = artworks[_artworkId].totalShares.add(_amount);
        artworkShares[_artworkId][owner()] = artworkShares[_artworkId][owner()].add(_amount); // Owner initially receives all shares
        emit ArtSharesMinted(_artworkId, _amount);
    }

    /**
     * @notice Allows members to transfer shares of an artwork to other members.
     * @param _artworkId ID of the artwork to transfer shares for.
     * @param _to Address of the recipient.
     * @param _amount Number of shares to transfer.
     */
    function transferArtShares(uint256 _artworkId, address _to, uint256 _amount) external whenNotPaused validArtworkId(_artworkId) {
        require(artworkShares[_artworkId][msg.sender] >= _amount, "Insufficient shares to transfer.");
        artworkShares[_artworkId][msg.sender] = artworkShares[_artworkId][msg.sender].sub(_amount);
        artworkShares[_artworkId][_to] = artworkShares[_artworkId][_to].add(_amount);
        emit ArtSharesTransferred(_artworkId, msg.sender, _to, _amount);
    }

    /**
     * @notice Get the share balance of a member for a specific artwork.
     * @param _artworkId ID of the artwork.
     * @param _member Address of the member.
     * @return The number of shares held by the member for the artwork.
     */
    function getArtSharesBalance(uint256 _artworkId, address _member) external view validArtworkId(_artworkId) returns (uint256) {
        return artworkShares[_artworkId][_member];
    }

    /**
     * @notice Get the total number of shares minted for an artwork.
     * @param _artworkId ID of the artwork.
     * @return The total number of shares.
     */
    function getTotalArtShares(uint256 _artworkId) external view validArtworkId(_artworkId) returns (uint256) {
        return artworks[_artworkId].totalShares;
    }


    // -------- 3. Dynamic Art Evolution (Community-Driven) Functions --------

    /**
     * @notice Share holders of an artwork can propose an evolution for the art.
     * @param _artworkId ID of the artwork to propose evolution for.
     * @param _evolutionProposal Description of the proposed evolution.
     */
    function proposeArtEvolution(uint256 _artworkId, string memory _evolutionProposal) external whenNotPaused onlyShareholder(_artworkId) validArtworkId(_artworkId) {
        evolutionProposalCounter++;
        evolutionProposals[evolutionProposalCounter] = EvolutionProposal({
            artworkId: _artworkId,
            proposalDescription: _evolutionProposal,
            proposer: msg.sender,
            status: EvolutionProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            proposalTimestamp: block.number
        });
        emit EvolutionProposed(_artworkId, evolutionProposalCounter, _evolutionProposal, msg.sender);
    }

    /**
     * @notice Share holders vote on an evolution proposal for an artwork.
     * @param _artworkId ID of the artwork.
     * @param _proposalId ID of the evolution proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteForEvolution(uint256 _artworkId, uint256 _proposalId, bool _approve) external whenNotPaused onlyShareholder(_artworkId) validArtworkId(_artworkId) validEvolutionProposalId(_artworkId, _proposalId) evolutionVotingActive(_artworkId, _proposalId) {
        require(!evolutionVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        evolutionVotes[_proposalId][msg.sender] = true; // Record vote to prevent double voting

        if (_approve) {
            evolutionProposals[_proposalId].votesFor = evolutionProposals[_proposalId].votesFor + getVotingWeight(msg.sender);
        } else {
            evolutionProposals[_proposalId].votesAgainst = evolutionProposals[_proposalId].votesAgainst + getVotingWeight(msg.sender);
        }
        emit EvolutionVoteCast(_artworkId, _proposalId, msg.sender, _approve);
    }

    /**
     * @notice Owner tallies votes for an evolution proposal and determines if it's approved or rejected.
     * @param _artworkId ID of the artwork.
     * @param _proposalId ID of the evolution proposal to tally votes for.
     */
    function tallyEvolutionVotes(uint256 _artworkId, uint256 _proposalId) external onlyOwner validArtworkId(_artworkId) validEvolutionProposalId(_artworkId, _proposalId) {
        require(evolutionProposals[_proposalId].status == EvolutionProposalStatus.Pending, "Votes have already been tallied for this proposal.");
        require(block.number >= evolutionProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has not ended yet.");

        if (evolutionProposals[_proposalId].votesFor > evolutionProposals[_proposalId].votesAgainst) {
            evolutionProposals[_proposalId].status = EvolutionProposalStatus.Approved;
        } else {
            evolutionProposals[_proposalId].status = EvolutionProposalStatus.Rejected;
        }
    }

    /**
     * @notice Owner applies an approved evolution proposal to the artwork (conceptually updates metadata, IPFS hash).
     * @param _artworkId ID of the artwork to evolve.
     * @param _proposalId ID of the approved evolution proposal.
     * @param _newIpfsHash The new IPFS hash of the evolved artwork metadata.
     */
    function applyArtEvolution(uint256 _artworkId, uint256 _proposalId, string memory _newIpfsHash) external onlyOwner validArtworkId(_artworkId) validEvolutionProposalId(_artworkId, _proposalId) {
        require(evolutionProposals[_proposalId].status == EvolutionProposalStatus.Approved, "Evolution proposal is not approved.");
        artworks[_artworkId].currentIpfsHash = _newIpfsHash; // Update the current IPFS hash
        emit EvolutionApplied(_artworkId, _proposalId, _newIpfsHash);
    }

    /**
     * @notice Get a list of evolution proposals for a specific artwork.
     * @param _artworkId ID of the artwork.
     * @return An array of evolution proposal IDs for the artwork.
     */
    function getArtEvolutionProposals(uint256 _artworkId) external view validArtworkId(_artworkId) returns (uint256[] memory) {
        uint256[] memory artworkProposals = new uint256[](evolutionProposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= evolutionProposalCounter; i++) {
            if (evolutionProposals[i].artworkId == _artworkId) {
                artworkProposals[count] = i;
                count++;
            }
        }
        uint256[] memory resizedArtworkProposals = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            resizedArtworkProposals[i] = artworkProposals[i];
        }
        return resizedArtworkProposals;
    }

    /**
     * @notice Get the current evolution details of an artwork.
     * @param _artworkId ID of the artwork.
     * @return The current IPFS hash and description of the artwork.
     */
    function getCurrentArtEvolution(uint256 _artworkId) external view validArtworkId(_artworkId) returns (string memory currentIpfsHash, string memory description) {
        return (artworks[_artworkId].currentIpfsHash, artworks[_artworkId].description);
    }


    // -------- 4. Community Treasury and Revenue Sharing Functions --------

    /**
     * @notice Members can deposit funds to the community treasury.
     */
    function depositToTreasury() external payable whenNotPaused {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /**
     * @notice Members can propose spending from the community treasury for collective purposes.
     * @param _recipient Address to receive the funds.
     * @param _amount Amount to spend.
     * @param _reason Reason for the spending proposal.
     */
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external whenNotPaused onlyMember {
        require(_amount > 0, "Spending amount must be greater than zero.");
        treasuryProposalCounter++;
        treasurySpendingProposals[treasuryProposalCounter] = TreasurySpendingProposal({
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            proposer: msg.sender,
            status: TreasuryProposalStatus.Pending,
            votesFor: 0,
            votesAgainst: 0,
            proposalTimestamp: block.number
        });
        emit TreasurySpendingProposed(treasuryProposalCounter, _recipient, _amount, _reason, msg.sender);
    }

    /**
     * @notice Members vote on a treasury spending proposal.
     * @param _proposalId ID of the treasury spending proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnTreasurySpending(uint256 _proposalId, bool _approve) external whenNotPaused onlyMember validTreasuryProposalId(_proposalId) treasuryVotingActive(_proposalId) {
        require(!treasuryVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        treasuryVotes[_proposalId][msg.sender] = true; // Record vote to prevent double voting

        if (_approve) {
            treasurySpendingProposals[_proposalId].votesFor = treasurySpendingProposals[_proposalId].votesFor + getVotingWeight(msg.sender);
        } else {
            treasurySpendingProposals[_proposalId].votesAgainst = treasurySpendingProposals[_proposalId].votesAgainst + getVotingWeight(msg.sender);
        }
        emit TreasuryVoteCast(_proposalId, msg.sender, _approve);
    }

    /**
     * @notice Owner tallies votes for a treasury spending proposal.
     * @param _proposalId ID of the treasury spending proposal to tally votes for.
     */
    function tallyTreasuryVotes(uint256 _proposalId) external onlyOwner validTreasuryProposalId(_proposalId) {
        require(treasurySpendingProposals[_proposalId].status == TreasuryProposalStatus.Pending, "Votes have already been tallied for this proposal.");
        require(block.number >= treasurySpendingProposals[_proposalId].proposalTimestamp + votingDuration, "Voting period has not ended yet.");

        if (treasurySpendingProposals[_proposalId].votesFor > treasurySpendingProposals[_proposalId].votesAgainst) {
            treasurySpendingProposals[_proposalId].status = TreasuryProposalStatus.Approved;
        } else {
            treasurySpendingProposals[_proposalId].status = TreasuryProposalStatus.Rejected;
        }
    }

    /**
     * @notice Owner executes an approved treasury spending proposal.
     * @param _proposalId ID of the approved treasury spending proposal.
     */
    function executeTreasurySpending(uint256 _proposalId) external onlyOwner validTreasuryProposalId(_proposalId) {
        require(treasurySpendingProposals[_proposalId].status == TreasuryProposalStatus.Approved, "Treasury proposal is not approved.");
        require(address(this).balance >= treasurySpendingProposals[_proposalId].amount, "Insufficient treasury balance.");

        address recipient = treasurySpendingProposals[_proposalId].recipient;
        uint256 amount = treasurySpendingProposals[_proposalId].amount;

        treasurySpendingProposals[_proposalId].status = TreasuryProposalStatus.Rejected; // Prevent re-execution
        payable(recipient).transfer(amount);
        emit TreasurySpendingExecuted(_proposalId, recipient, amount);
    }

    /**
     * @notice Get the current balance of the community treasury.
     * @return The treasury balance in Wei.
     */
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // -------- 5. Reputation and Governance Functions --------

    /**
     * @notice Owner can award reputation points to members for their contributions to the collective.
     * @param _member Address of the member to award reputation to.
     * @param _amount Amount of reputation points to award.
     * @param _reason Reason for awarding reputation.
     */
    function earnReputation(address _member, uint256 _amount, string memory _reason) external onlyOwner {
        memberReputation[_member] = memberReputation[_member].add(_amount);
        emit ReputationEarned(_member, _amount, _reason);
    }

    /**
     * @notice Get the reputation points of a member.
     * @param _member Address of the member.
     * @return The member's reputation points.
     */
    function getMemberReputation(address _member) external view returns (uint256) {
        return memberReputation[_member];
    }

    /**
     * @notice Owner can enable or disable voting power based on reputation points in addition to shares.
     * @param _enabled True to enable reputation-based voting weight, false to disable.
     */
    function setVotingPowerByReputation(bool _enabled) external onlyOwner {
        reputationBasedVotingEnabled = _enabled;
        // No event needed as it's a governance setting change.
    }

    /**
     * @notice Get the voting weight of a member. Voting weight is based on shares and optionally reputation.
     * @param _voter Address of the member.
     * @return The voting weight of the member.
     */
    function getVotingWeight(address _voter) public view returns (uint256) {
        uint256 totalWeight = 0;
        for (uint256 i = 1; i <= artworkCounter; i++) {
            totalWeight = totalWeight.add(artworkShares[i][_voter]);
        }
        if (reputationBasedVotingEnabled) {
            totalWeight = totalWeight.add(memberReputation[_voter]); // Could weigh reputation differently if needed
        }
        return totalWeight;
    }


    // -------- 6. Emergency and Admin Functions --------

    /**
     * @notice Pause the contract, preventing core functionalities from being used.
     */
    function pauseContract() external onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @notice Unpause the contract, restoring core functionalities.
     */
    function unpauseContract() external onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @notice Set the voting duration for submissions, evolutions and treasury proposals.
     * @param _durationInBlocks The new voting duration in blocks.
     */
    function setVotingDuration(uint256 _durationInBlocks) external onlyOwner {
        votingDuration = _durationInBlocks;
        emit VotingDurationChanged(_durationInBlocks);
    }

    /**
     * @notice Owner can withdraw treasury funds in emergency situations (use cautiously).
     * @param _recipient Address to receive the withdrawn funds.
     * @param _amount Amount to withdraw.
     */
    function withdrawTreasuryFunds(address _recipient, uint256 _amount) external onlyOwner {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    // Fallback function to receive Ether deposits
    receive() external payable {
        emit TreasuryDeposit(msg.sender, msg.value);
    }
}
```