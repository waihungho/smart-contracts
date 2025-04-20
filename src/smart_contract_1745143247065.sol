```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaborate,
 * curate exhibitions, govern collectively, and manage art assets on-chain.
 *
 * **Outline:**
 * 1. **Membership and Roles:**
 *    - Tiered Membership (Artist, Curator, Patron, Community) with different privileges.
 *    - Reputation system based on contributions and participation.
 *    - Governance roles (Admin, Council) elected by members.
 *
 * 2. **Art Submission and Curation:**
 *    - Artists can submit art pieces (metadata URIs).
 *    - Curators can propose exhibitions and select art for them.
 *    - Voting mechanism for art acceptance into exhibitions and permanent collection.
 *    - On-chain art registry and metadata management.
 *
 * 3. **Exhibition Management:**
 *    - Create and manage digital art exhibitions.
 *    - Set exhibition themes, durations, and curator rewards.
 *    - Display art pieces within exhibitions (on-chain registry).
 *    - Allow members to "visit" and interact with exhibitions.
 *
 * 4. **Collective Governance:**
 *    - Proposal system for collective decisions (e.g., treasury spending, rule changes).
 *    - Different proposal types (e.g., simple majority, quorum-based).
 *    - Voting mechanisms for members based on their tier/reputation.
 *    - Treasury management (deposit, withdraw, allocate funds based on proposals).
 *
 * 5. **Art Asset Management:**
 *    - Minting NFTs representing art pieces submitted to the collective.
 *    - Royalty distribution to artists on secondary sales of collective NFTs.
 *    - Mechanisms for showcasing and promoting collective art.
 *    - Potential integration with decentralized storage (IPFS) for art data.
 *
 * 6. **Community Engagement and Incentives:**
 *    - Challenges and contests with on-chain rewards.
 *    - Reputation points for participation and contributions.
 *    - Staking mechanism for members to show commitment and earn rewards.
 *    - On-chain messaging/forum for collective communication.
 *
 * **Function Summary:**
 * 1. `joinCollective(string _artistName, MemberTier _tier)`: Allows a user to join the collective with a chosen tier and artist name.
 * 2. `leaveCollective()`: Allows a member to leave the collective.
 * 3. `setMemberTier(address _member, MemberTier _tier)`: (Admin/Council) Sets the tier of a member.
 * 4. `getMemberTier(address _member)`: Returns the tier of a given member.
 * 5. `submitArt(string _metadataURI, string _title, string _description)`: Allows an artist member to submit their art piece with metadata URI.
 * 6. `voteOnArtSubmission(uint256 _submissionId, bool _approve)`: Allows curator/council members to vote on an art submission.
 * 7. `mintArtNFT(uint256 _submissionId)`: (Admin/Council) Mints an NFT for an approved art submission.
 * 8. `rejectArtSubmission(uint256 _submissionId)`: (Admin/Council) Rejects an art submission.
 * 9. `createExhibition(string _exhibitionName, string _theme, uint256 _durationDays)`: (Curator/Council) Creates a new art exhibition proposal.
 * 10. `addArtToExhibition(uint256 _exhibitionId, uint256 _artId)`: (Curator/Council) Adds an approved art piece to a specific exhibition.
 * 11. `startExhibition(uint256 _exhibitionId)`: (Admin/Council) Starts a scheduled exhibition.
 * 12. `endExhibition(uint256 _exhibitionId)`: (Admin/Council) Ends an active exhibition.
 * 13. `createGovernanceProposal(string _title, string _description, bytes _calldata)`: Allows members to create governance proposals.
 * 14. `voteOnProposal(uint256 _proposalId, bool _support)`: Allows members to vote on a governance proposal.
 * 15. `executeProposal(uint256 _proposalId)`: (Admin/Council) Executes a passed governance proposal.
 * 16. `depositFunds()`: Allows anyone to deposit funds into the collective treasury.
 * 17. `withdrawFunds(uint256 _amount)`: (Admin/Council, Governance Proposal) Allows withdrawal of funds from the treasury.
 * 18. `stakeReputation(uint256 _amount)`: Allows members to stake reputation tokens to increase voting power or gain benefits.
 * 19. `unstakeReputation(uint256 _amount)`: Allows members to unstake reputation tokens.
 * 20. `createArtChallenge(string _challengeName, string _theme, uint256 _rewardAmount)`: (Admin/Council) Creates an art challenge with a reward for the winner.
 * 21. `submitArtForChallenge(uint256 _challengeId, string _metadataURI)`: Allows artist members to submit art for a challenge.
 * 22. `voteForChallengeWinner(uint256 _challengeId, uint256 _submissionId)`: (Members/Curators) Allows voting for the winner of an art challenge.
 * 23. `awardChallengeReward(uint256 _challengeId, uint256 _submissionId)`: (Admin/Council) Awards the reward to the winner of a challenge.
 * 24. `setCollectiveName(string _name)`: (Admin) Sets the name of the art collective.
 * 25. `getCollectiveName()`: Returns the name of the art collective.
 * 26. `getArtSubmissionCount()`: Returns the total number of art submissions.
 * 27. `getExhibitionCount()`: Returns the total number of exhibitions created.
 * 28. `getMemberCount()`: Returns the total number of members in the collective.
 * 29. `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 */
contract DecentralizedAutonomousArtCollective {
    // -------- Enums and Structs --------

    enum MemberTier {
        COMMUNITY,
        PATRON,
        ARTIST,
        CURATOR,
        COUNCIL // Elected governance role with higher privileges
    }

    struct Member {
        MemberTier tier;
        string artistName;
        uint256 reputation;
        uint256 stakeAmount;
        bool isActive;
    }

    struct ArtSubmission {
        uint256 id;
        address artist;
        string metadataURI;
        string title;
        string description;
        uint256 voteCountApprove;
        uint256 voteCountReject;
        bool isApproved;
        bool isRejected;
        bool nftMinted;
        bool isActive;
    }

    struct Exhibition {
        uint256 id;
        string name;
        string theme;
        uint256 startTime;
        uint256 endTime;
        address curator; // Curator who proposed the exhibition
        uint256[] artPieceIds;
        bool isActive;
    }

    struct GovernanceProposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        bytes calldataData;
        uint256 voteCountSupport;
        uint256 voteCountAgainst;
        uint256 quorum; // Minimum votes required to pass
        uint256 votingDeadline;
        bool isExecuted;
        bool isActive;
    }

    struct ArtChallenge {
        uint256 id;
        string name;
        string theme;
        uint256 rewardAmount;
        uint256 votingDeadline;
        uint256 winnerSubmissionId;
        bool isActive;
    }

    // -------- State Variables --------

    string public collectiveName = "Genesis Art Collective";
    address public admin;
    uint256 public nextArtSubmissionId = 1;
    uint256 public nextExhibitionId = 1;
    uint256 public nextProposalId = 1;
    uint256 public nextChallengeId = 1;

    mapping(address => Member) public members;
    mapping(uint256 => ArtSubmission) public artSubmissions;
    mapping(uint256 => Exhibition) public exhibitions;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => ArtChallenge) public artChallenges;
    mapping(uint256 => mapping(address => bool)) public artSubmissionVotes; // submissionId => memberAddress => voted
    mapping(uint256 => mapping(address => bool)) public proposalVotes;      // proposalId => memberAddress => voted
    mapping(uint256 => mapping(address => bool)) public challengeVotes;     // challengeId => memberAddress => voted

    address[] public councilMembers; // Addresses of members in the Council role

    uint256 public reputationTokenSupply; // Placeholder for Reputation Token logic (can be expanded)
    // In a real-world scenario, you might integrate with an actual ERC20 token contract for reputation.

    // -------- Events --------

    event MemberJoined(address memberAddress, MemberTier tier, string artistName);
    event MemberLeft(address memberAddress);
    event MemberTierUpdated(address memberAddress, MemberTier newTier);
    event ArtSubmitted(uint256 submissionId, address artist, string metadataURI, string title);
    event ArtSubmissionVoted(uint256 submissionId, address voter, bool approve);
    event ArtMinted(uint256 submissionId, address artist);
    event ArtRejected(uint256 submissionId, address artist);
    event ExhibitionCreated(uint256 exhibitionId, string name, string theme, address curator);
    event ArtAddedToExhibition(uint256 exhibitionId, uint256 artId);
    event ExhibitionStarted(uint256 exhibitionId);
    event ExhibitionEnded(uint256 exhibitionId);
    event GovernanceProposalCreated(uint256 proposalId, string title, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);
    event ReputationStaked(address memberAddress, uint256 amount);
    event ReputationUnstaked(address memberAddress, uint256 amount);
    event ArtChallengeCreated(uint256 challengeId, string name, string theme, uint256 rewardAmount);
    event ArtSubmittedForChallenge(uint256 challengeId, uint256 submissionId, address artist);
    event ChallengeWinnerVoted(uint256 challengeId, uint256 submissionId, address voter);
    event ChallengeRewardAwarded(uint256 challengeId, uint256 submissionId, address winner);
    event CollectiveNameUpdated(string newName);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyCouncil() {
        bool isCouncilMember = false;
        for (uint256 i = 0; i < councilMembers.length; i++) {
            if (councilMembers[i] == msg.sender) {
                isCouncilMember = true;
                break;
            }
        }
        require(isCouncilMember || msg.sender == admin, "Only council members or admin can call this function.");
        _;
    }


    modifier onlyMembers() {
        require(members[msg.sender].isActive, "Only members can call this function.");
        _;
    }

    modifier onlyTier(MemberTier _tier) {
        require(members[msg.sender].tier >= _tier, "Insufficient member tier.");
        _;
    }

    modifier validSubmissionId(uint256 _submissionId) {
        require(artSubmissions[_submissionId].isActive, "Invalid or inactive art submission ID.");
        _;
    }

    modifier validExhibitionId(uint256 _exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Invalid or inactive exhibition ID.");
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(governanceProposals[_proposalId].isActive, "Invalid or inactive proposal ID.");
        _;
    }

    modifier validChallengeId(uint256 _challengeId) {
        require(artChallenges[_challengeId].isActive, "Invalid or inactive challenge ID.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
    }

    // -------- Membership Functions --------

    function joinCollective(string memory _artistName, MemberTier _tier) public {
        require(!members[msg.sender].isActive, "Already a member.");
        require(_tier <= MemberTier.ARTIST, "Initial tier cannot be Curator or Council. Start with COMMUNITY, PATRON or ARTIST and upgrade later."); // Example restriction
        members[msg.sender] = Member({
            tier: _tier,
            artistName: _artistName,
            reputation: 0,
            stakeAmount: 0,
            isActive: true
        });
        emit MemberJoined(msg.sender, _tier, _artistName);
    }

    function leaveCollective() public onlyMembers {
        require(members[msg.sender].isActive, "Not an active member.");
        members[msg.sender].isActive = false;
        emit MemberLeft(msg.sender);
    }

    function setMemberTier(address _member, MemberTier _tier) public onlyCouncil {
        require(members[_member].isActive, "Member is not active.");
        members[_member].tier = _tier;
        emit MemberTierUpdated(_member, _tier);
        if (_tier == MemberTier.COUNCIL) {
            bool alreadyCouncil = false;
            for (uint256 i = 0; i < councilMembers.length; i++) {
                if (councilMembers[i] == _member) {
                    alreadyCouncil = true;
                    break;
                }
            }
            if (!alreadyCouncil) {
                councilMembers.push(_member);
            }
        } else if (members[_member].tier < MemberTier.COUNCIL) {
            for (uint256 i = 0; i < councilMembers.length; i++) {
                if (councilMembers[i] == _member) {
                    delete councilMembers[i];
                    councilMembers[i] = councilMembers[councilMembers.length - 1];
                    councilMembers.pop();
                    break;
                }
            }
        }
    }


    function getMemberTier(address _member) public view returns (MemberTier) {
        return members[_member].tier;
    }

    // -------- Art Submission and Curation Functions --------

    function submitArt(string memory _metadataURI, string memory _title, string memory _description) public onlyMembers onlyTier(MemberTier.ARTIST) {
        ArtSubmission storage newSubmission = artSubmissions[nextArtSubmissionId];
        newSubmission.id = nextArtSubmissionId;
        newSubmission.artist = msg.sender;
        newSubmission.metadataURI = _metadataURI;
        newSubmission.title = _title;
        newSubmission.description = _description;
        newSubmission.isActive = true;
        nextArtSubmissionId++;
        emit ArtSubmitted(newSubmission.id, msg.sender, _metadataURI, _title);
    }

    function voteOnArtSubmission(uint256 _submissionId, bool _approve) public onlyMembers onlyTier(MemberTier.CURATOR) validSubmissionId(_submissionId) {
        require(!artSubmissionVotes[_submissionId][msg.sender], "Already voted on this submission.");
        require(!artSubmissions[_submissionId].isApproved && !artSubmissions[_submissionId].isRejected, "Submission already decided.");

        artSubmissionVotes[_submissionId][msg.sender] = true;
        if (_approve) {
            artSubmissions[_submissionId].voteCountApprove++;
        } else {
            artSubmissions[_submissionId].voteCountReject++;
        }
        emit ArtSubmissionVoted(_submissionId, msg.sender, _approve);

        // Simple approval logic - can be adjusted based on quorum, thresholds etc.
        if (artSubmissions[_submissionId].voteCountApprove >= 2) { // Example: Require 2 curator approvals
            mintArtNFT(_submissionId); // Auto-mint NFT if approved
        } else if (artSubmissions[_submissionId].voteCountReject >= 3) { // Example: Require 3 curator rejections
            rejectArtSubmission(_submissionId); // Auto-reject if rejected
        }
    }

    function mintArtNFT(uint256 _submissionId) public onlyCouncil validSubmissionId(_submissionId) {
        require(artSubmissions[_submissionId].isApproved == false && artSubmissions[_submissionId].isRejected == false, "Submission already decided.");
        require(!artSubmissions[_submissionId].nftMinted, "NFT already minted for this submission.");

        artSubmissions[_submissionId].isApproved = true;
        artSubmissions[_submissionId].nftMinted = true;
        emit ArtMinted(_submissionId, artSubmissions[_submissionId].artist);
        // ** In a real-world scenario, this is where you would integrate with an NFT contract
        //    to actually mint an NFT representing the art piece.
        //    For simplicity, this example just marks it as "minted" within the submission struct.**
    }

    function rejectArtSubmission(uint256 _submissionId) public onlyCouncil validSubmissionId(_submissionId) {
        require(artSubmissions[_submissionId].isApproved == false && artSubmissions[_submissionId].isRejected == false, "Submission already decided.");
        artSubmissions[_submissionId].isRejected = true;
        artSubmissions[_submissionId].isActive = false; // Mark as inactive so it's not processed further
        emit ArtRejected(_submissionId, artSubmissions[_submissionId].artist);
    }


    // -------- Exhibition Management Functions --------

    function createExhibition(string memory _exhibitionName, string memory _theme, uint256 _durationDays) public onlyMembers onlyTier(MemberTier.CURATOR) {
        Exhibition storage newExhibition = exhibitions[nextExhibitionId];
        newExhibition.id = nextExhibitionId;
        newExhibition.name = _exhibitionName;
        newExhibition.theme = _theme;
        newExhibition.curator = msg.sender;
        newExhibition.endTime = block.timestamp + (_durationDays * 1 days);
        newExhibition.isActive = true;
        nextExhibitionId++;
        emit ExhibitionCreated(newExhibition.id, _exhibitionName, _theme, msg.sender);
    }

    function addArtToExhibition(uint256 _exhibitionId, uint256 _artId) public onlyMembers onlyTier(MemberTier.CURATOR) validExhibitionId(_exhibitionId) validSubmissionId(_artId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(artSubmissions[_artId].isApproved, "Art piece is not approved for exhibitions.");
        require(!artSubmissions[_artId].nftMinted, "Art piece must be minted NFT to be added to exhibition."); // Example: Exhibition only for minted NFTs
        exhibitions[_exhibitionId].artPieceIds.push(_artId);
        emit ArtAddedToExhibition(_exhibitionId, _artId);
    }

    function startExhibition(uint256 _exhibitionId) public onlyCouncil validExhibitionId(_exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId].startTime == 0, "Exhibition already started.");
        exhibitions[_exhibitionId].startTime = block.timestamp;
        emit ExhibitionStarted(_exhibitionId);
    }

    function endExhibition(uint256 _exhibitionId) public onlyCouncil validExhibitionId(_exhibitionId) {
        require(exhibitions[_exhibitionId].isActive, "Exhibition is not active.");
        require(exhibitions[_exhibitionId].startTime != 0, "Exhibition not started yet.");
        exhibitions[_exhibitionId].endTime = block.timestamp; // Set current time as end time if not already set
        exhibitions[_exhibitionId].isActive = false; // Mark exhibition as ended
        emit ExhibitionEnded(_exhibitionId);
    }


    // -------- Governance Functions --------

    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) public onlyMembers {
        GovernanceProposal storage newProposal = governanceProposals[nextProposalId];
        newProposal.id = nextProposalId;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.calldataData = _calldata;
        newProposal.quorum = 5; // Example: Quorum of 5 votes
        newProposal.votingDeadline = block.timestamp + (7 days); // Example: 7 day voting period
        newProposal.isActive = true;
        nextProposalId++;
        emit GovernanceProposalCreated(newProposal.id, _title, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public onlyMembers validProposalId(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        require(!governanceProposals[_proposalId].isExecuted, "Proposal already executed.");
        require(block.timestamp < governanceProposals[_proposalId].votingDeadline, "Voting deadline passed.");

        proposalVotes[_proposalId][msg.sender] = true;
        if (_support) {
            governanceProposals[_proposalId].voteCountSupport++;
        } else {
            governanceProposals[_proposalId].voteCountAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _support);

        // Check if proposal passes quorum and deadline
        if (governanceProposals[_proposalId].voteCountSupport >= governanceProposals[_proposalId].quorum && block.timestamp >= governanceProposals[_proposalId].votingDeadline) {
            executeProposal(_proposalId); // Auto-execute if quorum reached and deadline passed
        }
    }

    function executeProposal(uint256 _proposalId) public onlyCouncil validProposalId(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.isExecuted, "Proposal already executed.");
        require(block.timestamp >= proposal.votingDeadline, "Voting deadline not yet passed.");
        require(proposal.voteCountSupport >= proposal.quorum, "Proposal did not reach quorum.");

        proposal.isExecuted = true;
        proposal.isActive = false; // Mark as inactive after execution
        (bool success, ) = address(this).call(proposal.calldataData); // Execute the proposal's calldata
        require(success, "Proposal execution failed.");
        emit GovernanceProposalExecuted(_proposalId);
    }

    // Example of a governance action - setting collective name
    function setCollectiveNameThroughGovernance(string memory _newName) public onlyMembers {
        bytes memory calldataPayload = abi.encodeWithSignature("setCollectiveName(string)", _newName);
        createGovernanceProposal("Change Collective Name", "Proposal to change the collective name to " + _newName, calldataPayload);
    }

    // -------- Treasury Functions --------

    function depositFunds() public payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 _amount) public onlyCouncil {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(admin).transfer(_amount); // Example: Only admin can withdraw in this basic example.
        emit FundsWithdrawn(admin, _amount);
        // In a real DAO, withdrawals would typically be governed by proposals.
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // -------- Reputation and Staking (Placeholder - can be expanded) --------

    function stakeReputation(uint256 _amount) public onlyMembers {
        // ** Placeholder - In a real system, you'd likely have a separate Reputation Token contract.
        //    This is a simplified example within this contract.
        require(_amount > 0, "Stake amount must be positive.");
        members[msg.sender].stakeAmount += _amount;
        reputationTokenSupply += _amount; // Increase "supply" (again, just a placeholder)
        emit ReputationStaked(msg.sender, _amount);
    }

    function unstakeReputation(uint256 _amount) public onlyMembers {
        require(_amount > 0, "Unstake amount must be positive.");
        require(members[msg.sender].stakeAmount >= _amount, "Insufficient staked reputation.");
        members[msg.sender].stakeAmount -= _amount;
        reputationTokenSupply -= _amount; // Decrease "supply"
        emit ReputationUnstaked(msg.sender, _amount);
    }

    // -------- Art Challenges --------

    function createArtChallenge(string memory _challengeName, string memory _theme, uint256 _rewardAmount) public onlyCouncil {
        ArtChallenge storage newChallenge = artChallenges[nextChallengeId];
        newChallenge.id = nextChallengeId;
        newChallenge.name = _challengeName;
        newChallenge.theme = _theme;
        newChallenge.rewardAmount = _rewardAmount;
        newChallenge.votingDeadline = block.timestamp + (14 days); // Example: 14 day voting period for challenges
        newChallenge.isActive = true;
        nextChallengeId++;
        emit ArtChallengeCreated(newChallenge.id, _challengeName, _theme, _rewardAmount);
    }

    function submitArtForChallenge(uint256 _challengeId, string memory _metadataURI) public onlyMembers onlyTier(MemberTier.ARTIST) validChallengeId(_challengeId) {
        require(artChallenges[_challengeId].isActive, "Art challenge is not active.");
        ArtSubmission storage newSubmission = artSubmissions[nextArtSubmissionId];
        newSubmission.id = nextArtSubmissionId;
        newSubmission.artist = msg.sender;
        newSubmission.metadataURI = _metadataURI;
        newSubmission.title = _metadataURI; // Using metadataURI as title for simplicity in challenge submissions
        newSubmission.description = "Submission for Challenge ID: " + Strings.toString(_challengeId);
        newSubmission.isActive = true;
        nextArtSubmissionId++;
        emit ArtSubmittedForChallenge(_challengeId, newSubmission.id, msg.sender);
    }

    function voteForChallengeWinner(uint256 _challengeId, uint256 _submissionId) public onlyMembers validChallengeId(_challengeId) validSubmissionId(_submissionId) {
        require(artSubmissions[_submissionId].artist != address(0), "Invalid submission ID.");
        require(block.timestamp < artChallenges[_challengeId].votingDeadline, "Challenge voting deadline passed.");
        require(!challengeVotes[_challengeId][msg.sender], "Already voted in this challenge.");

        challengeVotes[_challengeId][msg.sender] = true;
        artSubmissions[_submissionId].voteCountApprove++; // Reusing voteCountApprove for challenge votes for simplicity
        emit ChallengeWinnerVoted(_challengeId, _submissionId, msg.sender);

        // Basic winner determination - most votes by deadline
        if (block.timestamp >= artChallenges[_challengeId].votingDeadline) {
            awardChallengeReward(_challengeId, _submissionId); // Auto-award after deadline (simplistic)
        }
    }

    function awardChallengeReward(uint256 _challengeId, uint256 _submissionId) public onlyCouncil validChallengeId(_challengeId) validSubmissionId(_submissionId) {
        ArtChallenge storage challenge = artChallenges[_challengeId];
        require(challenge.winnerSubmissionId == 0, "Reward already awarded for this challenge.");
        require(artSubmissions[_submissionId].artist != address(0), "Invalid submission ID.");
        require(block.timestamp >= challenge.votingDeadline, "Challenge voting deadline not yet passed.");

        challenge.winnerSubmissionId = _submissionId;
        payable(artSubmissions[_submissionId].artist).transfer(challenge.rewardAmount); // Award reward to winner
        emit ChallengeRewardAwarded(_challengeId, _submissionId, _submissionId);
    }


    // -------- Utility/Info Functions --------

    function setCollectiveName(string memory _name) public onlyAdmin {
        collectiveName = _name;
        emit CollectiveNameUpdated(_name);
    }

    function getCollectiveName() public view returns (string memory) {
        return collectiveName;
    }

    function getArtSubmissionCount() public view returns (uint256) {
        return nextArtSubmissionId - 1;
    }

    function getExhibitionCount() public view returns (uint256) {
        return nextExhibitionId - 1;
    }

    function getMemberCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < councilMembers.length; i++) { // Iterate through council members to get a count (not ideal for large memberships - consider better tracking)
            if (members[councilMembers[i]].isActive) {
                count++;
            }
        }
        // ** This is a simplified count and may not be accurate if memberships are large and change frequently.
        //    For a real-world application, you'd likely need more robust member tracking.**
        return count;
    }
}

// --- Helper Library (Optional - for string conversions in challenges) ---
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Convert uint256 to string - basic implementation for challenge description
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
```