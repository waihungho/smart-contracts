```solidity
/**
 * @title Decentralized Autonomous Organization for Idea Incubation (DAOII)
 * @author Gemini AI
 * @dev A smart contract for a DAO focused on idea incubation, leveraging advanced concepts like dynamic reputation, skill-based roles,
 *      milestone-based funding, and on-chain reputation-based voting. This DAO aims to foster innovation by allowing members to propose,
 *      evaluate, and fund promising ideas through a decentralized and transparent process.  It incorporates NFTs for recognition and achievement.
 *
 * **Outline & Function Summary:**
 *
 * **1. State Variables & Structs:**
 *    - `admin`: Address of the contract administrator.
 *    - `members`: Mapping of member address to member struct.
 *    - `ideas`: Mapping of idea ID to idea struct.
 *    - `votes`: Mapping of idea ID and voter address to vote struct.
 *    - `reputationLevels`: Mapping of reputation level to its name.
 *    - `roles`: Mapping of role ID to role struct.
 *    - `memberRoles`: Mapping of member address to array of role IDs.
 *    - `ideaCounter`: Counter for generating unique idea IDs.
 *    - `roleCounter`: Counter for generating unique role IDs.
 *    - `paused`: Boolean to control contract pausing.
 *    - `recognitionNFT`: Address of the RecognitionNFT contract (external).
 *    - `DAO_TREASURY`: Address to hold DAO funds.
 *    - `MINIMUM_REPUTATION_FOR_PROPOSAL`: Minimum reputation required to submit an idea.
 *    - `REPUTATION_INCREMENT_PER_VOTE`: Reputation increment for voting.
 *    - `REPUTATION_DECREMENT_FOR_NEGATIVE_ACTION`: Reputation decrement for negative actions.
 *    - `IDEA_PROPOSAL_FEE`: Fee required to submit an idea proposal.
 *
 * **2. Modifiers:**
 *    - `onlyAdmin`: Modifier to restrict function access to the contract administrator.
 *    - `onlyMember`: Modifier to restrict function access to DAO members.
 *    - `ideaExists`: Modifier to check if an idea with a given ID exists.
 *    - `validIdeaStage`: Modifier to check if the contract is in a specific idea stage.
 *    - `notPaused`: Modifier to ensure contract is not paused.
 *
 * **3. Membership Functions:**
 *    - `joinDAO()`: Allows anyone to request membership.
 *    - `approveMembership(address _member)`: Admin function to approve a pending membership request.
 *    - `revokeMembership(address _member)`: Admin function to revoke a member's membership.
 *    - `isMember(address _address)`: Public view function to check if an address is a member.
 *    - `getMemberDetails(address _member)`: Public view function to retrieve detailed information about a member.
 *    - `updateMemberProfile(string _profileDetails)`: Member function to update their profile details.
 *
 * **4. Idea Proposal Functions:**
 *    - `submitIdeaProposal(string _title, string _description, uint256 _fundingGoal, string[] memory _milestones)`: Member function to submit an idea proposal.
 *    - `updateIdeaProposal(uint256 _ideaId, string _title, string _description, uint256 _fundingGoal, string[] memory _milestones)`: Member function to update their idea proposal (only in 'Draft' stage).
 *    - `reviewIdeaProposal(uint256 _ideaId)`: Member function to mark an idea as ready for voting (moves to 'Voting' stage).
 *    - `markIdeaAsRejected(uint256 _ideaId, string _rejectionReason)`: Admin function to reject an idea proposal directly.
 *    - `markIdeaAsApproved(uint256 _ideaId)`: Admin function to directly approve an idea proposal (bypassing voting - for exceptional cases).
 *    - `getIdeaDetails(uint256 _ideaId)`: Public view function to retrieve detailed information about an idea.
 *    - `getAllIdeasByStage(IdeaStage _stage)`: Public view function to retrieve all ideas in a specific stage.
 *
 * **5. Voting Functions (Reputation-Weighted):**
 *    - `castVote(uint256 _ideaId, bool _support)`: Member function to cast a vote on an idea proposal. Voting power is based on reputation.
 *    - `tallyVotes(uint256 _ideaId)`: Admin/Automated function to tally votes after voting period and determine outcome.
 *    - `getVoteDetails(uint256 _ideaId, address _voter)`: Public view function to get details of a specific vote.
 *    - `getIdeaVotingSummary(uint256 _ideaId)`: Public view function to get a summary of votes for an idea.
 *
 * **6. Funding & Milestone Management:**
 *    - `fundIdea(uint256 _ideaId)`: Allow members to contribute funds to an approved idea.
 *    - `requestMilestoneFunding(uint256 _ideaId, uint256 _milestoneIndex)`: Idea proposer function to request funding for a specific milestone completion.
 *    - `approveMilestoneFunding(uint256 _ideaId, uint256 _milestoneIndex)`: Admin/Voting function to approve milestone funding release.
 *    - `rejectMilestoneFunding(uint256 _ideaId, uint256 _milestoneIndex, string _rejectionReason)`: Admin function to reject milestone funding request.
 *    - `getIdeaFundingStatus(uint256 _ideaId)`: Public view function to get the funding status of an idea.
 *
 * **7. Reputation System:**
 *    - `increaseReputation(address _member, uint256 _amount, string _reason)`: Admin function to manually increase member reputation.
 *    - `decreaseReputation(address _member, uint256 _amount, string _reason)`: Admin function to manually decrease member reputation.
 *    - `getMemberReputation(address _member)`: Public view function to get a member's current reputation.
 *    - `getReputationLevel(address _member)`: Public view function to get a member's reputation level based on their reputation score.
 *    - `defineReputationLevel(uint256 _level, string _levelName)`: Admin function to define a new reputation level.
 *
 * **8. Role Management (Skill-Based):**
 *    - `defineRole(string _roleName, string _roleDescription)`: Admin function to define a new role within the DAO.
 *    - `assignRole(address _member, uint256 _roleId)`: Admin function to assign a role to a member.
 *    - `removeRole(address _member, uint256 _roleId)`: Admin function to remove a role from a member.
 *    - `getMemberRoles(address _member)`: Public view function to get a list of roles assigned to a member.
 *    - `getRoleDetails(uint256 _roleId)`: Public view function to get details of a specific role.
 *
 * **9. Recognition NFTs (Optional - Requires external NFT Contract):**
 *    - `setRecognitionNFTContract(address _nftContract)`: Admin function to set the address of the Recognition NFT contract.
 *    - `mintRecognitionNFT(address _recipient, string _tokenURI)`: Admin function to mint a recognition NFT for a member.
 *
 * **10. Utility & Admin Functions:**
 *    - `setDAOTreasury(address _treasuryAddress)`: Admin function to set the DAO treasury address.
 *    - `pauseContract()`: Admin function to pause the contract.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `withdrawFunds(address _recipient, uint256 _amount)`: Admin function to withdraw funds from the contract treasury.
 *    - `getContractBalance()`: Public view function to get the contract's balance.
 *    - `getDAOStats()`: Public view function to retrieve overall DAO statistics (e.g., member count, idea count, funds raised).
 *
 * **Events:**
 *    - `MembershipRequested(address member)`
 *    - `MembershipApproved(address member)`
 *    - `MembershipRevoked(address member)`
 *    - `IdeaProposed(uint256 ideaId, address proposer, string title)`
 *    - `IdeaUpdated(uint256 ideaId, string title)`
 *    - `IdeaReviewed(uint256 ideaId)`
 *    - `IdeaRejected(uint256 ideaId, string reason)`
 *    - `IdeaApproved(uint256 ideaId)`
 *    - `VoteCast(uint256 ideaId, address voter, bool support)`
 *    - `VotesTallied(uint256 ideaId, bool ideaPassed)`
 *    - `FundingContributed(uint256 ideaId, address contributor, uint256 amount)`
 *    - `MilestoneFundingRequested(uint256 ideaId, uint256 milestoneIndex)`
 *    - `MilestoneFundingApproved(uint256 ideaId, uint256 milestoneIndex)`
 *    - `MilestoneFundingRejected(uint256 ideaId, uint256 milestoneIndex, string reason)`
 *    - `ReputationIncreased(address member, uint256 amount, string reason)`
 *    - `ReputationDecreased(address member, uint256 amount, string reason)`
 *    - `RoleDefined(uint256 roleId, string roleName)`
 *    - `RoleAssigned(address member, uint256 roleId)`
 *    - `RoleRemoved(address member, uint256 roleId)`
 *    - `RecognitionNFTContractSet(address nftContract)`
 *    - `RecognitionNFTMinted(address recipient, string tokenURI)`
 *    - `ContractPaused()`
 *    - `ContractUnpaused()`
 *    - `FundsWithdrawn(address recipient, uint256 amount)`
 */
pragma solidity ^0.8.0;

contract DAOII {
    // -------- State Variables --------

    address public admin;
    mapping(address => Member) public members;
    mapping(uint256 => Idea) public ideas;
    mapping(uint256 => mapping(address => Vote)) public votes;
    mapping(uint256 => string) public reputationLevels; // Level ID to Level Name
    mapping(uint256 => Role) public roles;
    mapping(address => uint256[]) public memberRoles; // Member address to array of role IDs
    uint256 public ideaCounter;
    uint256 public roleCounter;
    bool public paused;
    address public recognitionNFT; // Address of external Recognition NFT contract (if used)
    address public DAO_TREASURY;

    uint256 public MINIMUM_REPUTATION_FOR_PROPOSAL = 10;
    uint256 public REPUTATION_INCREMENT_PER_VOTE = 1;
    uint256 public REPUTATION_DECREMENT_FOR_NEGATIVE_ACTION = 5;
    uint256 public IDEA_PROPOSAL_FEE = 0.1 ether; // Example fee

    enum IdeaStage { Draft, Review, Voting, Approved, Rejected, Funding, InProgress, Completed, Failed }

    struct Member {
        address memberAddress;
        bool isApproved;
        uint256 reputation;
        string profileDetails;
        uint256 joinTimestamp;
    }

    struct Idea {
        uint256 ideaId;
        address proposer;
        string title;
        string description;
        IdeaStage stage;
        uint256 fundingGoal;
        uint256 fundingRaised;
        string[] milestones;
        bool votingActive;
        uint256 voteEndTime;
        string rejectionReason;
        uint256 approvalTimestamp;
    }

    struct Vote {
        address voter;
        bool support;
        uint256 voteWeight; // Based on reputation
        uint256 voteTimestamp;
    }

    struct Role {
        uint256 roleId;
        string roleName;
        string roleDescription;
        uint256 definitionTimestamp;
    }

    // -------- Events --------

    event MembershipRequested(address member);
    event MembershipApproved(address member);
    event MembershipRevoked(address member);
    event IdeaProposed(uint256 ideaId, address proposer, string title);
    event IdeaUpdated(uint256 ideaId, string title);
    event IdeaReviewed(uint256 ideaId);
    event IdeaRejected(uint256 ideaId, string reason);
    event IdeaApproved(uint256 ideaId);
    event VoteCast(uint256 ideaId, address voter, bool support);
    event VotesTallied(uint256 ideaId, uint256 positiveVotes, uint256 negativeVotes, bool ideaPassed);
    event FundingContributed(uint256 ideaId, address contributor, uint256 amount);
    event MilestoneFundingRequested(uint256 ideaId, uint256 milestoneIndex);
    event MilestoneFundingApproved(uint256 ideaId, uint256 milestoneIndex);
    event MilestoneFundingRejected(uint256 ideaId, uint256 milestoneIndex, string reason);
    event ReputationIncreased(address member, uint256 amount, string reason);
    event ReputationDecreased(address member, uint256 amount, string reason);
    event RoleDefined(uint256 roleId, string roleName);
    event RoleAssigned(address member, uint256 roleId);
    event RoleRemoved(address member, uint256 roleId);
    event RecognitionNFTContractSet(address nftContract);
    event RecognitionNFTMinted(address recipient, string tokenURI);
    event ContractPaused();
    event ContractUnpaused();
    event FundsWithdrawn(address recipient, uint256 amount);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Only members can call this function.");
        _;
    }

    modifier ideaExists(uint256 _ideaId) {
        require(ideas[_ideaId].ideaId == _ideaId, "Idea does not exist.");
        _;
    }

    modifier validIdeaStage(uint256 _ideaId, IdeaStage _stage) {
        require(ideas[_ideaId].stage == _stage, "Invalid idea stage for this action.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // -------- Constructor --------

    constructor(address _treasuryAddress) payable {
        admin = msg.sender;
        DAO_TREASURY = _treasuryAddress;
        paused = false;
        ideaCounter = 1;
        roleCounter = 1;
        reputationLevels[1] = "Newcomer";
        reputationLevels[10] = "Contributor";
        reputationLevels[50] = "Innovator";
        reputationLevels[100] = "Visionary";
    }

    // -------- 3. Membership Functions --------

    function joinDAO() external notPaused {
        require(!isMember(msg.sender), "Already a member or membership requested.");
        members[msg.sender] = Member({
            memberAddress: msg.sender,
            isApproved: false,
            reputation: 0,
            profileDetails: "",
            joinTimestamp: block.timestamp
        });
        emit MembershipRequested(msg.sender);
    }

    function approveMembership(address _member) external onlyAdmin notPaused {
        require(!members[_member].isApproved && members[_member].memberAddress != address(0), "Member not found or already approved.");
        members[_member].isApproved = true;
        emit MembershipApproved(_member);
    }

    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(members[_member].isApproved, "Address is not an approved member.");
        delete members[_member]; // Consider more graceful removal if needed (e.g., setting isApproved to false and keeping data)
        emit MembershipRevoked(_member);
    }

    function isMember(address _address) public view returns (bool) {
        return members[_address].isApproved;
    }

    function getMemberDetails(address _member) public view returns (Member memory) {
        return members[_member];
    }

    function updateMemberProfile(string memory _profileDetails) external onlyMember notPaused {
        members[msg.sender].profileDetails = _profileDetails;
    }

    // -------- 4. Idea Proposal Functions --------

    function submitIdeaProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string[] memory _milestones
    ) external payable onlyMember notPaused {
        require(members[msg.sender].reputation >= MINIMUM_REPUTATION_FOR_PROPOSAL, "Insufficient reputation to propose ideas.");
        require(msg.value >= IDEA_PROPOSAL_FEE, "Insufficient proposal fee.");

        ideas[ideaCounter] = Idea({
            ideaId: ideaCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            stage: IdeaStage.Draft,
            fundingGoal: _fundingGoal,
            fundingRaised: 0,
            milestones: _milestones,
            votingActive: false,
            voteEndTime: 0,
            rejectionReason: "",
            approvalTimestamp: 0
        });

        emit IdeaProposed(ideaCounter, msg.sender, _title);
        ideaCounter++;

        // Optionally transfer proposal fee to DAO Treasury
        payable(DAO_TREASURY).transfer(IDEA_PROPOSAL_FEE);
    }

    function updateIdeaProposal(
        uint256 _ideaId,
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string[] memory _milestones
    ) external onlyMember ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Draft) notPaused {
        require(ideas[_ideaId].proposer == msg.sender, "Only proposer can update the idea.");

        ideas[_ideaId].title = _title;
        ideas[_ideaId].description = _description;
        ideas[_ideaId].fundingGoal = _fundingGoal;
        ideas[_ideaId].milestones = _milestones;

        emit IdeaUpdated(_ideaId, _title);
    }

    function reviewIdeaProposal(uint256 _ideaId) external onlyMember ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Draft) notPaused {
        // Add logic for review process, potentially involving specific roles or reputation levels to initiate review.
        // For simplicity, any member can initiate review here.
        ideas[_ideaId].stage = IdeaStage.Review;
        emit IdeaReviewed(_ideaId);
    }

    function markIdeaAsRejected(uint256 _ideaId, string memory _rejectionReason) external onlyAdmin ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Review) notPaused {
        ideas[_ideaId].stage = IdeaStage.Rejected;
        ideas[_ideaId].rejectionReason = _rejectionReason;
        emit IdeaRejected(_ideaId, _rejectionReason);
    }

    function markIdeaAsApproved(uint256 _ideaId) external onlyAdmin ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Review) notPaused {
        ideas[_ideaId].stage = IdeaStage.Approved;
        ideas[_ideaId].approvalTimestamp = block.timestamp;
        emit IdeaApproved(_ideaId);
    }

    function getIdeaDetails(uint256 _ideaId) public view ideaExists(_ideaId) returns (Idea memory) {
        return ideas[_ideaId];
    }

    function getAllIdeasByStage(IdeaStage _stage) public view returns (uint256[] memory) {
        uint256[] memory ideaIds = new uint256[](ideaCounter - 1); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i < ideaCounter; i++) {
            if (ideas[i].ideaId == i && ideas[i].stage == _stage) { // Check if idea exists and is in the desired stage
                ideaIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of ideas found
        assembly {
            mstore(ideaIds, count) // Update the length of the array in memory directly
        }
        return ideaIds;
    }


    // -------- 5. Voting Functions (Reputation-Weighted) --------

    function castVote(uint256 _ideaId, bool _support) external onlyMember ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Voting) notPaused {
        require(ideas[_ideaId].votingActive, "Voting is not active for this idea.");
        require(block.timestamp <= ideas[_ideaId].voteEndTime, "Voting period has ended.");
        require(votes[_ideaId][msg.sender].voter == address(0), "Already voted on this idea."); // Prevent double voting

        uint256 voteWeight = members[msg.sender].reputation + 1; // Example: Reputation + 1 for a minimum weight of 1
        votes[_ideaId][msg.sender] = Vote({
            voter: msg.sender,
            support: _support,
            voteWeight: voteWeight,
            voteTimestamp: block.timestamp
        });

        increaseReputation(msg.sender, REPUTATION_INCREMENT_PER_VOTE, "Voting Participation"); // Reward for voting

        emit VoteCast(_ideaId, msg.sender, _support);
    }

    function startVoting(uint256 _ideaId, uint256 _votingDurationInSeconds) external onlyAdmin ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Review) notPaused {
        require(!ideas[_ideaId].votingActive, "Voting already active for this idea.");
        ideas[_ideaId].stage = IdeaStage.Voting;
        ideas[_ideaId].votingActive = true;
        ideas[_ideaId].voteEndTime = block.timestamp + _votingDurationInSeconds;
    }


    function tallyVotes(uint256 _ideaId) external onlyAdmin ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Voting) notPaused {
        require(ideas[_ideaId].votingActive && block.timestamp > ideas[_ideaId].voteEndTime, "Voting is not active or voting period not ended.");
        ideas[_ideaId].votingActive = false;

        uint256 positiveVotes = 0;
        uint256 negativeVotes = 0;
        uint256 totalPositiveWeight = 0;
        uint256 totalNegativeWeight = 0;

        for (uint256 i = 1; i < ideaCounter; i++) { // Iterate through potential voters (inefficient for large DAOs, consider better vote tracking)
            if (votes[_ideaId][address(uint160(i))].voter != address(0) && votes[_ideaId][address(uint160(i))].ideaId == _ideaId) { // Check if voter voted on this idea
                if (votes[_ideaId][address(uint160(i))].support) {
                    positiveVotes++;
                    totalPositiveWeight += votes[_ideaId][address(uint160(i))].voteWeight;
                } else {
                    negativeVotes++;
                    totalNegativeWeight += votes[_ideaId][address(uint160(i))].voteWeight;
                }
            }
        }

        bool ideaPassed = totalPositiveWeight > totalNegativeWeight; // Simple majority voting based on weighted votes

        if (ideaPassed) {
            ideas[_ideaId].stage = IdeaStage.Approved;
            ideas[_ideaId].approvalTimestamp = block.timestamp;
            emit IdeaApproved(_ideaId);
        } else {
            ideas[_ideaId].stage = IdeaStage.Rejected;
            ideas[_ideaId].rejectionReason = "Voting failed"; // Default rejection reason
            emit IdeaRejected(_ideaId, "Voting failed");
        }

        emit VotesTallied(_ideaId, positiveVotes, negativeVotes, ideaPassed);

        // Clean up votes after tallying (optional, to save storage if needed, but loses vote history)
        // delete votes[_ideaId];
    }


    function getVoteDetails(uint256 _ideaId, address _voter) public view ideaExists(_ideaId) returns (Vote memory) {
        return votes[_ideaId][_voter];
    }

    function getIdeaVotingSummary(uint256 _ideaId) public view ideaExists(_ideaId) returns (uint256 positiveVotes, uint256 negativeVotes, uint256 totalPositiveWeight, uint256 totalNegativeWeight) {
        positiveVotes = 0;
        negativeVotes = 0;
        totalPositiveWeight = 0;
        totalNegativeWeight = 0;

        for (uint256 i = 1; i < ideaCounter; i++) { // Iterate through potential voters (inefficient for large DAOs, consider better vote tracking)
            if (votes[_ideaId][address(uint160(i))].voter != address(0) && votes[_ideaId][address(uint160(i))].ideaId == _ideaId) { // Check if voter voted on this idea
                if (votes[_ideaId][address(uint160(i))].support) {
                    positiveVotes++;
                    totalPositiveWeight += votes[_ideaId][address(uint160(i))].voteWeight;
                } else {
                    negativeVotes++;
                    totalNegativeWeight += votes[_ideaId][address(uint160(i))].voteWeight;
                }
            }
        }
        return (positiveVotes, negativeVotes, totalPositiveWeight, totalNegativeWeight);
    }


    // -------- 6. Funding & Milestone Management --------

    function fundIdea(uint256 _ideaId) external payable ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Approved) notPaused {
        require(ideas[_ideaId].fundingRaised + msg.value <= ideas[_ideaId].fundingGoal, "Funding exceeds goal.");
        ideas[_ideaId].fundingRaised += msg.value;

        // Optionally transfer funds directly to idea proposer or a designated project wallet.
        // For now, funds are tracked in the contract.
        // payable(ideas[_ideaId].proposer).transfer(msg.value); // Direct transfer - be careful with security implications!
        emit FundingContributed(_ideaId, msg.sender, msg.value);

        if (ideas[_ideaId].fundingRaised == ideas[_ideaId].fundingGoal) {
            ideas[_ideaId].stage = IdeaStage.Funding; // Idea fully funded, move to Funding stage
        }
    }

    function requestMilestoneFunding(uint256 _ideaId, uint256 _milestoneIndex) external onlyMember ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Funding) notPaused {
        require(ideas[_ideaId].proposer == msg.sender, "Only idea proposer can request milestone funding.");
        require(_milestoneIndex < ideas[_ideaId].milestones.length, "Invalid milestone index.");
        // Add logic to check milestone completion (potentially using oracles or decentralized verification).

        emit MilestoneFundingRequested(_ideaId, _milestoneIndex);
    }

    function approveMilestoneFunding(uint256 _ideaId, uint256 _milestoneIndex) external onlyAdmin ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Funding) notPaused {
        // Add more robust approval mechanism, potentially involving voting or role-based approval.
        // For simplicity, admin approval is used here.

        // Calculate milestone funding amount (can be predefined or dynamically determined based on milestones).
        uint256 milestoneFundingAmount = ideas[_ideaId].fundingGoal / ideas[_ideaId].milestones.length; // Example: equal milestone funding

        require(address(this).balance >= milestoneFundingAmount, "Insufficient contract balance for milestone funding.");

        payable(ideas[_ideaId].proposer).transfer(milestoneFundingAmount); // Release milestone funding to proposer
        emit MilestoneFundingApproved(_ideaId, _milestoneIndex);

        if (_milestoneIndex == ideas[_ideaId].milestones.length - 1) {
            ideas[_ideaId].stage = IdeaStage.Completed; // Last milestone funded, mark idea as completed
        } else {
            ideas[_ideaId].stage = IdeaStage.InProgress; // Move to InProgress stage after first milestone funding
        }
    }

    function rejectMilestoneFunding(uint256 _ideaId, uint256 _milestoneIndex, string memory _rejectionReason) external onlyAdmin ideaExists(_ideaId) validIdeaStage(_ideaId, IdeaStage.Funding) notPaused {
        // Implement rejection logic, potentially with voting or review process.
        emit MilestoneFundingRejected(_ideaId, _milestoneIndex, _rejectionReason);
    }

    function getIdeaFundingStatus(uint256 _ideaId) public view ideaExists(_ideaId) returns (uint256 fundingRaised, uint256 fundingGoal) {
        return (ideas[_ideaId].fundingRaised, ideas[_ideaId].fundingGoal);
    }


    // -------- 7. Reputation System --------

    function increaseReputation(address _member, uint256 _amount, string memory _reason) internal { // Internal function, called by contract logic
        members[_member].reputation += _amount;
        emit ReputationIncreased(_member, _amount, _reason);
    }

    function decreaseReputation(address _member, uint256 _amount, string memory _reason) external onlyAdmin notPaused {
        members[_member].reputation -= _amount;
        emit ReputationDecreased(_member, _amount, _reason);
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        return members[_member].reputation;
    }

    function getReputationLevel(address _member) public view returns (string memory) {
        uint256 currentReputation = members[_member].reputation;
        string memory levelName = "Newcomer"; // Default level

        if (currentReputation >= 100) {
            levelName = reputationLevels[100];
        } else if (currentReputation >= 50) {
            levelName = reputationLevels[50];
        } else if (currentReputation >= 10) {
            levelName = reputationLevels[10];
        } // else it remains "Newcomer"

        return levelName;
    }

    function defineReputationLevel(uint256 _level, string memory _levelName) external onlyAdmin notPaused {
        reputationLevels[_level] = _levelName;
    }


    // -------- 8. Role Management (Skill-Based) --------

    function defineRole(string memory _roleName, string memory _roleDescription) external onlyAdmin notPaused {
        roles[roleCounter] = Role({
            roleId: roleCounter,
            roleName: _roleName,
            roleDescription: _roleDescription,
            definitionTimestamp: block.timestamp
        });
        emit RoleDefined(roleCounter, _roleName);
        roleCounter++;
    }

    function assignRole(address _member, uint256 _roleId) external onlyAdmin notPaused {
        require(roles[_roleId].roleId == _roleId, "Role does not exist."); // Role existence check
        memberRoles[_member].push(_roleId);
        emit RoleAssigned(_member, _roleId);
    }

    function removeRole(address _member, uint256 _roleId) external onlyAdmin notPaused {
        bool roleRemoved = false;
        uint256[] storage memberRoleList = memberRoles[_member];
        for (uint256 i = 0; i < memberRoleList.length; i++) {
            if (memberRoleList[i] == _roleId) {
                memberRoleList[i] = memberRoleList[memberRoleList.length - 1]; // Replace with last element
                memberRoleList.pop(); // Remove last element (now duplicate or removed element)
                roleRemoved = true;
                break;
            }
        }
        require(roleRemoved, "Member does not have this role.");
        emit RoleRemoved(_member, _roleId);
    }

    function getMemberRoles(address _member) public view returns (uint256[] memory) {
        return memberRoles[_member];
    }

    function getRoleDetails(uint256 _roleId) public view returns (Role memory) {
        return roles[_roleId];
    }


    // -------- 9. Recognition NFTs (Optional) --------

    function setRecognitionNFTContract(address _nftContract) external onlyAdmin notPaused {
        recognitionNFT = _nftContract;
        emit RecognitionNFTContractSet(_nftContract);
    }

    function mintRecognitionNFT(address _recipient, string memory _tokenURI) external onlyAdmin notPaused {
        require(recognitionNFT != address(0), "Recognition NFT contract not set.");
        // Assuming a simple function in the NFT contract: mint(address _to, string memory _uri)
        // Consider using interface for better type safety and interaction.
        (bool success, bytes memory data) = recognitionNFT.call(
            abi.encodeWithSignature("mint(address,string)", _recipient, _tokenURI)
        );
        require(success, "Recognition NFT minting failed.");
        emit RecognitionNFTMinted(_recipient, _tokenURI);
    }


    // -------- 10. Utility & Admin Functions --------

    function setDAOTreasury(address _treasuryAddress) external onlyAdmin notPaused {
        DAO_TREASURY = _treasuryAddress;
    }

    function pauseContract() external onlyAdmin notPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    function withdrawFunds(address _recipient, uint256 _amount) external onlyAdmin notPaused {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDAOStats() public view returns (uint256 memberCount, uint256 ideaCount, uint256 totalFundsRaised) {
        memberCount = 0;
        for (uint256 i = 1; i < ideaCounter; i++) {
             if (members[address(uint160(i))].memberAddress != address(0) && members[address(uint160(i))].isApproved) {
                memberCount++;
             }
        }
        ideaCount = ideaCounter - 1;
        totalFundsRaised = 0;
        for (uint256 i = 1; i < ideaCounter; i++) {
            if (ideas[i].ideaId == i) {
                totalFundsRaised += ideas[i].fundingRaised;
            }
        }
        return (memberCount, ideaCount, totalFundsRaised);
    }

    receive() external payable {} // Allow contract to receive Ether
}
```