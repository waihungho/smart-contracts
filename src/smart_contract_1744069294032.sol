```solidity
/**
 * @title Decentralized Autonomous Organization for Collaborative Content Creation (DAO-CCC)
 * @author Bard (AI Assistant)
 * @dev A DAO smart contract enabling collaborative content creation, governance, and reward distribution.
 *
 * **Outline and Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinDAO()`: Allows users to become DAO members by staking governance tokens.
 *    - `leaveDAO()`: Allows members to exit the DAO and retrieve their staked tokens.
 *    - `getMemberDetails(address _member)`: Retrieves details of a DAO member.
 *    - `isMember(address _user)`: Checks if an address is a DAO member.
 *
 * **2. Governance & Proposal System:**
 *    - `proposeNewRule(string memory _ruleDescription, bytes memory _ruleData)`: Allows members to propose new DAO rules or changes.
 *    - `voteOnRuleProposal(uint256 _proposalId, bool _support)`: Allows members to vote on active rule proposals.
 *    - `executeRule(uint256 _proposalId)`: Executes a rule proposal if it passes the voting threshold.
 *    - `getRuleProposalDetails(uint256 _proposalId)`: Retrieves details of a specific rule proposal.
 *    - `cancelRuleProposal(uint256 _proposalId)`: Allows the proposer to cancel a rule proposal before voting ends.
 *
 * **3. Content Proposal & Creation System:**
 *    - `submitContentProposal(string memory _contentTitle, string memory _contentDescription, string memory _contentCID)`: Members propose content ideas with IPFS CID.
 *    - `voteOnContentProposal(uint256 _proposalId, bool _support)`: Members vote on content proposals.
 *    - `markContentProposalInProgress(uint256 _proposalId)`: Marks a content proposal as "in progress" after approval.
 *    - `submitContentForReview(uint256 _proposalId, string memory _finalContentCID)`: Creators submit final content for review after working on it.
 *    - `voteOnContentReview(uint256 _proposalId, bool _approve)`: Members vote to approve or reject submitted content.
 *    - `markContentProposalCompleted(uint256 _proposalId)`: Marks a content proposal as completed and content accepted.
 *    - `rejectContentProposal(uint256 _proposalId)`: Rejects a content proposal (either during initial proposal vote or content review).
 *    - `getContentProposalDetails(uint256 _proposalId)`: Retrieves details of a specific content proposal.
 *
 * **4. Reputation & Reward System:**
 *    - `contributeToProposal(uint256 _proposalId, string memory _contributionDetails)`: Members can contribute to content proposals (ideas, feedback) to gain reputation.
 *    - `distributeContentRewards(uint256 _proposalId)`: Distributes rewards to contributors and creators of accepted content.
 *    - `getMemberReputation(address _member)`: Retrieves the reputation score of a DAO member.
 *
 * **5. DAO Information & Utility:**
 *    - `getDAOInfo()`: Returns general information about the DAO (name, token address, etc.).
 *    - `emergencyPauseDAO()`: Owner function to pause critical functionalities in case of emergency.
 *    - `resumeDAO()`: Owner function to resume DAO functionalities after emergency pause.
 *    - `setGovernanceTokenAddress(address _tokenAddress)`: Owner function to set the governance token address.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DAOCreativeContent is Ownable {
    using Strings for uint256;

    // --- Structs & Enums ---

    enum ProposalState {
        Pending,
        Active,
        Passed,
        Rejected,
        Cancelled,
        InProgress,
        ContentSubmittedForReview,
        ContentAccepted,
        ContentRejected
    }

    struct RuleProposal {
        uint256 proposalId;
        string description;
        bytes ruleData; // Flexible data for rule implementation
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
    }

    struct ContentProposal {
        uint256 proposalId;
        string title;
        string description;
        string initialContentCID; // IPFS CID for initial proposal
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
        string finalContentCID; // IPFS CID for final submitted content
        address[] contributors; // Addresses of members who contributed
        string[] contributionDetails; // Details of contributions
    }

    struct Member {
        address memberAddress;
        uint256 joinTime;
        uint256 reputationScore;
        uint256 stakedTokens;
    }

    // --- State Variables ---

    string public daoName = "Creative Content DAO";
    address public governanceTokenAddress;
    uint256 public membershipStakeAmount = 100; // Amount of governance tokens to stake for membership
    uint256 public proposalVoteDuration = 7 days;
    uint256 public contentReviewVoteDuration = 3 days;
    uint256 public ruleProposalThreshold = 50; // Percentage of yes votes to pass rule proposals
    uint256 public contentProposalThreshold = 60; // Percentage of yes votes to pass content proposals
    uint256 public contentReviewThreshold = 70; // Percentage of yes votes to accept content review

    uint256 public nextRuleProposalId = 1;
    mapping(uint256 => RuleProposal) public ruleProposals;
    uint256 public nextContentProposalId = 1;
    mapping(uint256 => ContentProposal) public contentProposals;
    mapping(address => Member) public members;
    mapping(address => bool) public isDAOMember;
    address[] public memberList;

    bool public paused = false;

    // --- Events ---

    event MemberJoined(address indexed memberAddress, uint256 joinTime);
    event MemberLeft(address indexed memberAddress, uint256 exitTime);
    event RuleProposalCreated(uint256 proposalId, string description, address proposer);
    event RuleProposalVoted(uint256 proposalId, address voter, bool support);
    event RuleProposalExecuted(uint256 proposalId);
    event RuleProposalCancelled(uint256 proposalId);
    event ContentProposalCreated(uint256 proposalId, string title, address proposer);
    event ContentProposalVoted(uint256 proposalId, address voter, bool support);
    event ContentProposalInProgress(uint256 proposalId);
    event ContentSubmittedForReview(uint256 proposalId, string finalContentCID);
    event ContentReviewVoted(uint256 proposalId, uint256 votesFor, uint256 votesAgainst);
    event ContentProposalAccepted(uint256 proposalId, string finalContentCID);
    event ContentProposalRejected(uint256 proposalId);
    event ContentContributionMade(uint256 proposalId, address contributor, string details);
    event RewardsDistributed(uint256 proposalId, uint256 rewardAmount);
    event DAOPaused();
    event DAOResumed();
    event GovernanceTokenAddressSet(address tokenAddress);

    // --- Modifiers ---

    modifier onlyMember() {
        require(isDAOMember[msg.sender], "You are not a DAO member.");
        _;
    }

    modifier onlyProposalState(uint256 _proposalId, ProposalState _state) {
        require(ruleProposals[_proposalId].state == _state || contentProposals[_proposalId].state == _state, "Proposal is not in the required state.");
        _;
    }

    modifier onlyRuleProposalState(uint256 _proposalId, ProposalState _state) {
        require(ruleProposals[_proposalId].state == _state, "Rule proposal is not in the required state.");
        _;
    }

    modifier onlyContentProposalState(uint256 _proposalId, ProposalState _state) {
        require(contentProposals[_proposalId].state == _state, "Content proposal is not in the required state.");
        _;
    }

    modifier notPaused() {
        require(!paused, "DAO is currently paused.");
        _;
    }

    // --- Constructor ---
    constructor(address _governanceTokenAddress) payable {
        governanceTokenAddress = _governanceTokenAddress;
        _transferOwnership(msg.sender); // Deployer is the initial owner
    }

    // --- 1. Membership Management ---

    function joinDAO() external notPaused {
        require(!isDAOMember[msg.sender], "Already a DAO member.");
        IERC20 governanceToken = IERC20(governanceTokenAddress);
        require(governanceToken.transferFrom(msg.sender, address(this), membershipStakeAmount), "Token transfer failed. Ensure you have enough governance tokens and have approved this contract.");

        members[msg.sender] = Member({
            memberAddress: msg.sender,
            joinTime: block.timestamp,
            reputationScore: 0, // Initial reputation
            stakedTokens: membershipStakeAmount
        });
        isDAOMember[msg.sender] = true;
        memberList.push(msg.sender);

        emit MemberJoined(msg.sender, block.timestamp);
    }

    function leaveDAO() external onlyMember notPaused {
        require(isDAOMember[msg.sender], "Not a DAO member.");

        IERC20 governanceToken = IERC20(governanceTokenAddress);
        require(governanceToken.transfer(msg.sender, members[msg.sender].stakedTokens), "Token return failed.");

        delete members[msg.sender];
        isDAOMember[msg.sender] = false;
        // Remove from memberList (can optimize for gas if needed in production by using a mapping and swapping with last element)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == msg.sender) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }

        emit MemberLeft(msg.sender, block.timestamp);
    }

    function getMemberDetails(address _member) external view returns (Member memory) {
        require(isDAOMember[_member], "Address is not a DAO member.");
        return members[_member];
    }

    function isMember(address _user) external view returns (bool) {
        return isDAOMember[_user];
    }

    // --- 2. Governance & Proposal System ---

    function proposeNewRule(string memory _ruleDescription, bytes memory _ruleData) external onlyMember notPaused {
        RuleProposal storage proposal = ruleProposals[nextRuleProposalId];
        proposal.proposalId = nextRuleProposalId;
        proposal.description = _ruleDescription;
        proposal.ruleData = _ruleData;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + proposalVoteDuration;
        proposal.state = ProposalState.Active;

        emit RuleProposalCreated(nextRuleProposalId, _ruleDescription, msg.sender);
        nextRuleProposalId++;
    }

    function voteOnRuleProposal(uint256 _proposalId, bool _support) external onlyMember notPaused onlyRuleProposalState(_proposalId, ProposalState.Active) {
        require(block.timestamp <= ruleProposals[_proposalId].endTime, "Voting period has ended.");
        require(ruleProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal."); //Optional: Prohibit proposer voting

        if (_support) {
            ruleProposals[_proposalId].yesVotes++;
        } else {
            ruleProposals[_proposalId].noVotes++;
        }
        emit RuleProposalVoted(_proposalId, msg.sender, _support);
    }

    function executeRule(uint256 _proposalId) external onlyMember notPaused onlyRuleProposalState(_proposalId, ProposalState.Active) {
        require(block.timestamp > ruleProposals[_proposalId].endTime, "Voting period is not yet ended.");

        uint256 totalVotes = ruleProposals[_proposalId].yesVotes + ruleProposals[_proposalId].noVotes;
        uint256 yesPercentage = (ruleProposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= ruleProposalThreshold) {
            ruleProposals[_proposalId].state = ProposalState.Passed;
            // Implement rule execution logic here based on ruleProposals[_proposalId].ruleData
            // This is highly dependent on what kind of rules you want to implement.
            // For example, it could be changing DAO parameters, upgrading contract logic (proxy pattern), etc.
            // For simplicity in this example, we just emit an event.

            emit RuleProposalExecuted(_proposalId);
        } else {
            ruleProposals[_proposalId].state = ProposalState.Rejected;
        }
    }

    function getRuleProposalDetails(uint256 _proposalId) external view returns (RuleProposal memory) {
        return ruleProposals[_proposalId];
    }

    function cancelRuleProposal(uint256 _proposalId) external onlyMember notPaused onlyRuleProposalState(_proposalId, ProposalState.Active) {
        require(ruleProposals[_proposalId].proposer == msg.sender, "Only proposer can cancel the proposal.");
        ruleProposals[_proposalId].state = ProposalState.Cancelled;
        emit RuleProposalCancelled(_proposalId);
    }

    // --- 3. Content Proposal & Creation System ---

    function submitContentProposal(string memory _contentTitle, string memory _contentDescription, string memory _contentCID) external onlyMember notPaused {
        ContentProposal storage proposal = contentProposals[nextContentProposalId];
        proposal.proposalId = nextContentProposalId;
        proposal.title = _contentTitle;
        proposal.description = _contentDescription;
        proposal.initialContentCID = _contentCID;
        proposal.proposer = msg.sender;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + proposalVoteDuration;
        proposal.state = ProposalState.Active;

        emit ContentProposalCreated(nextContentProposalId, _contentTitle, msg.sender);
        nextContentProposalId++;
    }

    function voteOnContentProposal(uint256 _proposalId, bool _support) external onlyMember notPaused onlyContentProposalState(_proposalId, ProposalState.Active) {
        require(block.timestamp <= contentProposals[_proposalId].endTime, "Voting period has ended.");
        require(contentProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal."); //Optional: Prohibit proposer voting

        if (_support) {
            contentProposals[_proposalId].yesVotes++;
        } else {
            contentProposals[_proposalId].noVotes++;
        }
        emit ContentProposalVoted(_proposalId, msg.sender, _support);
    }

    function markContentProposalInProgress(uint256 _proposalId) external onlyMember notPaused onlyContentProposalState(_proposalId, ProposalState.Active) {
        require(block.timestamp > contentProposals[_proposalId].endTime, "Voting period is not yet ended.");

        uint256 totalVotes = contentProposals[_proposalId].yesVotes + contentProposals[_proposalId].noVotes;
        uint256 yesPercentage = (contentProposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= contentProposalThreshold) {
            contentProposals[_proposalId].state = ProposalState.InProgress;
            emit ContentProposalInProgress(_proposalId);
        } else {
            contentProposals[_proposalId].state = ProposalState.Rejected;
            emit ContentProposalRejected(_proposalId);
        }
    }

    function submitContentForReview(uint256 _proposalId, string memory _finalContentCID) external onlyMember notPaused onlyContentProposalState(_proposalId, ProposalState.InProgress) {
        require(contentProposals[_proposalId].proposer == msg.sender, "Only proposer can submit content for review.");
        contentProposals[_proposalId].finalContentCID = _finalContentCID;
        contentProposals[_proposalId].state = ProposalState.ContentSubmittedForReview;
        contentProposals[_proposalId].startTime = block.timestamp; // Reset start time for review period
        contentProposals[_proposalId].endTime = block.timestamp + contentReviewVoteDuration;
        emit ContentSubmittedForReview(_proposalId, _finalContentCID);
    }

    function voteOnContentReview(uint256 _proposalId, bool _approve) external onlyMember notPaused onlyContentProposalState(_proposalId, ProposalState.ContentSubmittedForReview) {
        require(block.timestamp <= contentProposals[_proposalId].endTime, "Content review voting period has ended.");
        require(contentProposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own content review."); //Optional: Prohibit proposer voting

        if (_approve) {
            contentProposals[_proposalId].yesVotes++;
        } else {
            contentProposals[_proposalId].noVotes++;
        }
        emit ContentReviewVoted(_proposalId, contentProposals[_proposalId].yesVotes, contentProposals[_proposalId].noVotes);
    }

    function markContentProposalCompleted(uint256 _proposalId) external onlyMember notPaused onlyContentProposalState(_proposalId, ProposalState.ContentSubmittedForReview) {
        require(block.timestamp > contentProposals[_proposalId].endTime, "Content review voting period is not yet ended.");

        uint256 totalVotes = contentProposals[_proposalId].yesVotes + contentProposals[_proposalId].noVotes;
        uint256 yesPercentage = (contentProposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage >= contentReviewThreshold) {
            contentProposals[_proposalId].state = ProposalState.ContentAccepted;
            emit ContentProposalAccepted(_proposalId, contentProposals[_proposalId].finalContentCID);
            // Here you would typically trigger reward distribution or further actions upon content acceptance.
            // Example: distributeContentRewards(_proposalId);
        } else {
            contentProposals[_proposalId].state = ProposalState.ContentRejected;
            emit ContentProposalRejected(_proposalId);
        }
    }

    function rejectContentProposal(uint256 _proposalId) external onlyMember notPaused onlyContentProposalState(_proposalId, ProposalState.Active) {
        require(block.timestamp > contentProposals[_proposalId].endTime, "Voting period is not yet ended.");
        uint256 totalVotes = contentProposals[_proposalId].yesVotes + contentProposals[_proposalId].noVotes;
        uint256 yesPercentage = (contentProposals[_proposalId].yesVotes * 100) / totalVotes;

        if (yesPercentage < contentProposalThreshold) { // If proposal failed initial vote
            contentProposals[_proposalId].state = ProposalState.Rejected;
            emit ContentProposalRejected(_proposalId);
        } else if (contentProposals[_proposalId].state == ProposalState.ContentSubmittedForReview) { // If content review failed
            require(block.timestamp > contentProposals[_proposalId].endTime, "Content review voting period is not yet ended.");
            uint256 reviewTotalVotes = contentProposals[_proposalId].yesVotes + contentProposals[_proposalId].noVotes;
            uint256 reviewYesPercentage = (contentProposals[_proposalId].yesVotes * 100) / reviewTotalVotes;
            if (reviewYesPercentage < contentReviewThreshold) {
                 contentProposals[_proposalId].state = ProposalState.ContentRejected;
                 emit ContentProposalRejected(_proposalId);
            }
        } else {
            revert("Proposal cannot be rejected in the current state.");
        }
    }


    function getContentProposalDetails(uint256 _proposalId) external view returns (ContentProposal memory) {
        return contentProposals[_proposalId];
    }

    // --- 4. Reputation & Reward System ---

    function contributeToProposal(uint256 _proposalId, string memory _contributionDetails) external onlyMember notPaused onlyContentProposalState(_proposalId, ProposalState.Active) {
        // Members can contribute ideas, feedback, etc., even if they didn't propose the content.
        ContentProposal storage proposal = contentProposals[_proposalId];
        proposal.contributors.push(msg.sender);
        proposal.contributionDetails.push(_contributionDetails);

        // Increase contributor's reputation (simple example, can be more complex)
        members[msg.sender].reputationScore += 1; // Small reputation increase for contributing

        emit ContentContributionMade(_proposalId, msg.sender, _contributionDetails);
    }

    function distributeContentRewards(uint256 _proposalId) internal { // Internal function called after content acceptance
        require(contentProposals[_proposalId].state == ProposalState.ContentAccepted, "Content proposal must be accepted to distribute rewards.");
        // --- Reward distribution logic ---
        // This is a placeholder.  Real implementation would be more complex.
        // Ideas:
        // 1. Fixed reward amount per accepted content.
        // 2. Reward pool funded by DAO treasury or content sales.
        // 3. Proportional rewards based on reputation or contribution level.

        uint256 rewardAmount = 100 ether; // Example reward amount (adjust based on your tokenomics)

        IERC20 governanceToken = IERC20(governanceTokenAddress);
        require(governanceToken.transfer(contentProposals[_proposalId].proposer, rewardAmount), "Reward transfer to proposer failed.");
        // Consider distributing smaller rewards to contributors as well based on contribution level.

        emit RewardsDistributed(_proposalId, rewardAmount);
    }

    function getMemberReputation(address _member) external view returns (uint256) {
        require(isDAOMember[_member], "Address is not a DAO member.");
        return members[_member].reputationScore;
    }

    // --- 5. DAO Information & Utility ---

    function getDAOInfo() external view returns (string memory _name, address _tokenAddress, uint256 _membershipStake) {
        return (daoName, governanceTokenAddress, membershipStakeAmount);
    }

    function emergencyPauseDAO() external onlyOwner {
        paused = true;
        emit DAOPaused();
    }

    function resumeDAO() external onlyOwner {
        paused = false;
        emit DAOResumed();
    }

    function setGovernanceTokenAddress(address _tokenAddress) external onlyOwner {
        governanceTokenAddress = _tokenAddress;
        emit GovernanceTokenAddressSet(_tokenAddress);
    }

    // Fallback function to receive ETH (optional - for example, for DAO treasury funding)
    receive() external payable {}
}
```