```solidity
/**
 * @title Advanced Decentralized Community Platform Contract
 * @author Gemini AI Assistant
 * @dev A sophisticated smart contract for a decentralized community platform with advanced features.
 *      This contract incorporates user profiles, reputation system, content creation (posts),
 *      NFT-based memberships, decentralized voting, task/bounty system, and more.
 *      It aims to be a comprehensive and engaging community platform on the blockchain.
 *
 * **Outline and Function Summary:**
 *
 * **1. User Management:**
 *    - `registerUser(string _username, string _profileURI)`: Allows a user to register on the platform with a unique username and profile URI.
 *    - `updateProfile(string _newProfileURI)`: Allows a registered user to update their profile URI.
 *    - `getUserProfile(address _userAddress)`: Retrieves the profile URI and username of a user.
 *    - `isUserRegistered(address _userAddress)`: Checks if an address is registered as a user.
 *    - `getUsername(address _userAddress)`: Retrieves the username of a registered user.
 *
 * **2. Reputation and Points System:**
 *    - `upvotePost(uint256 _postId)`: Allows users to upvote a post, increasing the author's reputation.
 *    - `downvotePost(uint256 _postId)`: Allows users to downvote a post, potentially decreasing the author's reputation.
 *    - `getUserReputation(address _userAddress)`: Retrieves the reputation points of a user.
 *    - `awardReputationPoints(address _userAddress, uint256 _points)`: Admin function to manually award reputation points.
 *    - `deductReputationPoints(address _userAddress, uint256 _points)`: Admin function to manually deduct reputation points.
 *
 * **3. Content Creation (Posts):**
 *    - `createPost(string _title, string _contentURI, string[] memory _tags)`: Allows registered users to create a new post with a title, content URI, and tags.
 *    - `editPost(uint256 _postId, string _newContentURI)`: Allows the post author to edit the content URI of their post.
 *    - `getPost(uint256 _postId)`: Retrieves the details of a post, including author, title, content URI, tags, and upvotes/downvotes.
 *    - `deletePost(uint256 _postId)`: Allows the post author or admin to delete a post.
 *    - `getPostsByTag(string _tag)`: Retrieves a list of post IDs associated with a specific tag.
 *
 * **4. NFT Membership:**
 *    - `mintMembershipNFT(string _tokenURI)`: Allows users to mint a membership NFT, granting them special platform privileges.
 *    - `getMembershipNFTOfUser(address _userAddress)`: Retrieves the token ID of the membership NFT owned by a user (if any).
 *    - `transferMembershipNFT(address _recipient, uint256 _tokenId)`: Allows users to transfer their membership NFT.
 *    - `burnMembershipNFT(uint256 _tokenId)`: Allows a user to burn their membership NFT, revoking privileges.
 *
 * **5. Decentralized Voting (Simple Proposal System):**
 *    - `createProposal(string _title, string _descriptionURI, uint256 _durationBlocks)`: Allows users to create a proposal for community changes.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows registered users to vote on active proposals.
 *    - `getProposal(uint256 _proposalId)`: Retrieves details of a proposal, including votes and status.
 *    - `executeProposal(uint256 _proposalId)`: Allows the admin to execute a passed proposal (implementation logic needs to be added based on proposal type).
 *
 * **6. Task/Bounty System:**
 *    - `createTask(string _title, string _descriptionURI, uint256 _rewardPoints)`: Allows users to create tasks with reputation point rewards for completion.
 *    - `submitTask(uint256 _taskId, string _submissionURI)`: Allows users to submit their work for a task.
 *    - `approveTaskSubmission(uint256 _taskId, address _submissionAuthor)`: Allows the task creator or admin to approve a task submission and award the reward points.
 *    - `getTask(uint256 _taskId)`: Retrieves details of a task, including status, submissions, and reward.
 *
 * **7. Platform Administration and Utility:**
 *    - `setAdmin(address _newAdmin)`: Allows the current admin to change the platform administrator.
 *    - `pauseContract()`: Admin function to pause certain functionalities of the contract for maintenance.
 *    - `unpauseContract()`: Admin function to resume paused functionalities.
 *    - `withdrawContractBalance()`: Admin function to withdraw any Ether held by the contract.
 *
 * **Events:**
 *    - `UserRegistered(address userAddress, string username)`: Emitted when a user registers.
 *    - `ProfileUpdated(address userAddress)`: Emitted when a user updates their profile.
 *    - `PostCreated(uint256 postId, address author)`: Emitted when a new post is created.
 *    - `PostEdited(uint256 postId)`: Emitted when a post is edited.
 *    - `PostDeleted(uint256 postId)`: Emitted when a post is deleted.
 *    - `PostUpvoted(uint256 postId, address voter)`: Emitted when a post is upvoted.
 *    - `PostDownvoted(uint256 postId, address voter)`: Emitted when a post is downvoted.
 *    - `ReputationPointsAwarded(address userAddress, uint256 points)`: Emitted when reputation points are awarded.
 *    - `ReputationPointsDeducted(address userAddress, uint256 points)`: Emitted when reputation points are deducted.
 *    - `MembershipNFTMinted(address userAddress, uint256 tokenId)`: Emitted when a membership NFT is minted.
 *    - `MembershipNFTTransferred(uint256 tokenId, address from, address to)`: Emitted when a membership NFT is transferred.
 *    - `MembershipNFTBurned(uint256 tokenId, address burner)`: Emitted when a membership NFT is burned.
 *    - `ProposalCreated(uint256 proposalId, address proposer)`: Emitted when a proposal is created.
 *    - `ProposalVoted(uint256 proposalId, address voter, bool vote)`: Emitted when a user votes on a proposal.
 *    - `ProposalExecuted(uint256 proposalId)`: Emitted when a proposal is executed.
 *    - `TaskCreated(uint256 taskId, address creator)`: Emitted when a task is created.
 *    - `TaskSubmitted(uint256 taskId, address submitter)`: Emitted when a task is submitted.
 *    - `TaskSubmissionApproved(uint256 taskId, address submitter)`: Emitted when a task submission is approved.
 *    - `AdminChanged(address newAdmin)`: Emitted when the admin address is changed.
 *    - `ContractPaused()`: Emitted when the contract is paused.
 *    - `ContractUnpaused()`: Emitted when the contract is unpaused.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AdvancedCommunityPlatform is ERC721, Ownable, Pausable {
    using Strings for uint256;

    // --- Structs ---
    struct UserProfile {
        string username;
        string profileURI;
        uint256 reputationPoints;
        bool isRegistered;
    }

    struct Post {
        address author;
        string title;
        string contentURI;
        string[] tags;
        uint256 upvotes;
        uint256 downvotes;
        uint256 createdAt;
        bool exists;
    }

    struct Proposal {
        address proposer;
        string title;
        string descriptionURI;
        uint256 startTime;
        uint256 durationBlocks;
        uint256 upVotes;
        uint256 downVotes;
        bool isActive;
        bool passed;
        bool executed;
    }

    struct Task {
        address creator;
        string title;
        string descriptionURI;
        uint256 rewardPoints;
        bool isOpen;
        mapping(address => string) submissions; // submitter address => submission URI
        address approvedSubmitter;
        bool isApproved;
        bool exists;
    }

    // --- State Variables ---
    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public usernameToAddress;
    uint256 public nextPostId;
    mapping(uint256 => Post) public posts;
    mapping(string => uint256[]) public tagToPostIds; // Tag to list of post IDs
    uint256 public nextProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => voted (true/false)
    uint256 public nextTaskId;
    mapping(uint256 => Task) public tasks;
    mapping(address => uint256) public userMembershipNFT; // user address to token ID, 0 if no NFT
    uint256 public nextMembershipTokenId;
    uint256 public reputationPointsPerUpvote = 10;
    uint256 public reputationPointsPerDownvote = 5;
    address public platformAdmin;
    bool public contractPaused;

    // --- Events ---
    event UserRegistered(address indexed userAddress, string username);
    event ProfileUpdated(address indexed userAddress);
    event PostCreated(uint256 indexed postId, address indexed author);
    event PostEdited(uint256 indexed postId);
    event PostDeleted(uint256 indexed postId);
    event PostUpvoted(uint256 indexed postId, address indexed voter);
    event PostDownvoted(uint256 indexed postId, address indexed voter);
    event ReputationPointsAwarded(address indexed userAddress, uint256 points);
    event ReputationPointsDeducted(address indexed userAddress, uint256 points);
    event MembershipNFTMinted(address indexed userAddress, uint256 indexed tokenId);
    event MembershipNFTTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event MembershipNFTBurned(uint256 indexed tokenId, address indexed burner);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, bool vote);
    event ProposalExecuted(uint256 indexed proposalId);
    event TaskCreated(uint256 indexed taskId, address indexed creator);
    event TaskSubmitted(uint256 indexed taskId, address indexed submitter);
    event TaskSubmissionApproved(uint256 indexed taskId, address indexed submitter);
    event AdminChanged(address indexed newAdmin);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyRegisteredUser() {
        require(isUserRegistered(msg.sender), "User not registered");
        _;
    }

    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin allowed");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused");
        _;
    }

    modifier postExists(uint256 _postId) {
        require(posts[_postId].exists, "Post does not exist");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(proposals[_proposalId].isActive, "Proposal does not exist or is not active");
        _;
    }

    modifier taskExists(uint256 _taskId) {
        require(tasks[_taskId].exists, "Task does not exist");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("CommunityMembershipNFT", "CMNFT") {
        platformAdmin = msg.sender;
        emit AdminChanged(platformAdmin);
    }

    // --- 1. User Management Functions ---
    function registerUser(string memory _username, string memory _profileURI) public whenNotPaused {
        require(!isUserRegistered(msg.sender), "User already registered");
        require(usernameToAddress[_username] == address(0), "Username already taken");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileURI: _profileURI,
            reputationPoints: 0,
            isRegistered: true
        });
        usernameToAddress[_username] = msg.sender;
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _newProfileURI) public onlyRegisteredUser whenNotPaused {
        userProfiles[msg.sender].profileURI = _newProfileURI;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _userAddress) public view returns (string memory username, string memory profileURI, uint256 reputationPoints, bool registered) {
        UserProfile storage profile = userProfiles[_userAddress];
        return (profile.username, profile.profileURI, profile.reputationPoints, profile.isRegistered);
    }

    function isUserRegistered(address _userAddress) public view returns (bool) {
        return userProfiles[_userAddress].isRegistered;
    }

    function getUsername(address _userAddress) public view returns (string memory) {
        return userProfiles[_userAddress].username;
    }

    // --- 2. Reputation and Points System Functions ---
    function upvotePost(uint256 _postId) public onlyRegisteredUser whenNotPaused postExists(_postId) {
        require(posts[_postId].author != msg.sender, "Cannot upvote own post");
        posts[_postId].upvotes++;
        userProfiles[posts[_postId].author].reputationPoints += reputationPointsPerUpvote;
        emit PostUpvoted(_postId, msg.sender);
        emit ReputationPointsAwarded(posts[_postId].author, reputationPointsPerUpvote);
    }

    function downvotePost(uint256 _postId) public onlyRegisteredUser whenNotPaused postExists(_postId) {
        require(posts[_postId].author != msg.sender, "Cannot downvote own post");
        posts[_postId].downvotes++;
        if (userProfiles[posts[_postId].author].reputationPoints >= reputationPointsPerDownvote) {
            userProfiles[posts[_postId].author].reputationPoints -= reputationPointsPerDownvote;
            emit ReputationPointsDeducted(posts[_postId].author, reputationPointsPerDownvote);
        }
        emit PostDownvoted(_postId, msg.sender);
    }

    function getUserReputation(address _userAddress) public view returns (uint256) {
        return userProfiles[_userAddress].reputationPoints;
    }

    function awardReputationPoints(address _userAddress, uint256 _points) public onlyPlatformAdmin whenNotPaused {
        userProfiles[_userAddress].reputationPoints += _points;
        emit ReputationPointsAwarded(_userAddress, _points);
    }

    function deductReputationPoints(address _userAddress, uint256 _points) public onlyPlatformAdmin whenNotPaused {
        if (userProfiles[_userAddress].reputationPoints >= _points) {
            userProfiles[_userAddress].reputationPoints -= _points;
            emit ReputationPointsDeducted(_userAddress, _points);
        } else {
            userProfiles[_userAddress].reputationPoints = 0; // Set to 0 if points are less than deduction
            emit ReputationPointsDeducted(_userAddress, _points); // Still emit event, but deducted all points
        }
    }

    // --- 3. Content Creation (Posts) Functions ---
    function createPost(string memory _title, string memory _contentURI, string[] memory _tags) public onlyRegisteredUser whenNotPaused {
        uint256 postId = nextPostId++;
        posts[postId] = Post({
            author: msg.sender,
            title: _title,
            contentURI: _contentURI,
            tags: _tags,
            upvotes: 0,
            downvotes: 0,
            createdAt: block.timestamp,
            exists: true
        });
        for (uint256 i = 0; i < _tags.length; i++) {
            tagToPostIds[_tags[i]].push(postId);
        }
        emit PostCreated(postId, msg.sender);
    }

    function editPost(uint256 _postId, string memory _newContentURI) public onlyRegisteredUser whenNotPaused postExists(_postId) {
        require(posts[_postId].author == msg.sender, "Only author can edit post");
        posts[_postId].contentURI = _newContentURI;
        emit PostEdited(_postId);
    }

    function getPost(uint256 _postId) public view postExists(_postId) returns (Post memory) {
        return posts[_postId];
    }

    function deletePost(uint256 _postId) public onlyRegisteredUser whenNotPaused postExists(_postId) {
        require(posts[_postId].author == msg.sender || msg.sender == platformAdmin, "Only author or admin can delete post");
        posts[_postId].exists = false;
        emit PostDeleted(_postId);
    }

    function getPostsByTag(string memory _tag) public view returns (uint256[] memory) {
        return tagToPostIds[_tag];
    }

    // --- 4. NFT Membership Functions ---
    function mintMembershipNFT(string memory _tokenURI) public onlyRegisteredUser whenNotPaused {
        require(userMembershipNFT[msg.sender] == 0, "User already has membership NFT");
        uint256 tokenId = nextMembershipTokenId++;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        userMembershipNFT[msg.sender] = tokenId;
        emit MembershipNFTMinted(msg.sender, tokenId);
    }

    function getMembershipNFTOfUser(address _userAddress) public view returns (uint256) {
        return userMembershipNFT[_userAddress];
    }

    function transferMembershipNFT(address _recipient, uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        require(ownerOf(_tokenId) == msg.sender, "Sender is not the owner"); // Double check owner
        require(userMembershipNFT[_recipient] == 0, "Recipient already has membership NFT");
        _transfer(msg.sender, _recipient, _tokenId);
        userMembershipNFT[msg.sender] = 0;
        userMembershipNFT[_recipient] = _tokenId;
        emit MembershipNFTTransferred(_tokenId, msg.sender, _recipient);
    }

    function burnMembershipNFT(uint256 _tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(msg.sender, _tokenId), "Not NFT owner or approved");
        require(ownerOf(_tokenId) == msg.sender, "Sender is not the owner"); // Double check owner
        require(userMembershipNFT[msg.sender] == _tokenId, "Sender is not associated with this NFT");
        _burn(_tokenId);
        userMembershipNFT[msg.sender] = 0;
        emit MembershipNFTBurned(_tokenId, msg.sender);
    }


    // --- 5. Decentralized Voting (Simple Proposal System) Functions ---
    function createProposal(string memory _title, string memory _descriptionURI, uint256 _durationBlocks) public onlyRegisteredUser whenNotPaused {
        uint256 proposalId = nextProposalId++;
        proposals[proposalId] = Proposal({
            proposer: msg.sender,
            title: _title,
            descriptionURI: _descriptionURI,
            startTime: block.number,
            durationBlocks: _durationBlocks,
            upVotes: 0,
            downVotes: 0,
            isActive: true,
            passed: false,
            executed: false
        });
        emit ProposalCreated(proposalId, msg.sender);
    }

    function voteOnProposal(uint256 _proposalId, bool _vote) public onlyRegisteredUser whenNotPaused proposalExists(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "User already voted on this proposal");
        require(block.number <= proposals[_proposalId].startTime + proposals[_proposalId].durationBlocks, "Voting period ended");
        proposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            proposals[_proposalId].upVotes++;
        } else {
            proposals[_proposalId].downVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _vote);
    }

    function getProposal(uint256 _proposalId) public view proposalExists(_proposalId) returns (Proposal memory) {
        return proposals[_proposalId];
    }

    function executeProposal(uint256 _proposalId) public onlyPlatformAdmin whenNotPaused proposalExists(_proposalId) {
        require(!proposals[_proposalId].executed, "Proposal already executed");
        require(block.number > proposals[_proposalId].startTime + proposals[_proposalId].durationBlocks, "Voting period not ended");

        if (proposals[_proposalId].upVotes > proposals[_proposalId].downVotes) {
            proposals[_proposalId].passed = true;
            // --- Add logic to execute the proposal here based on proposal details ---
            // For example, if proposal is to change a contract parameter, implement it here
            // ... (Implementation logic based on proposal type) ...
            proposals[_proposalId].executed = true;
            emit ProposalExecuted(_proposalId);
        } else {
            proposals[_proposalId].passed = false; // Proposal failed
            proposals[_proposalId].executed = true; // Mark as executed even if failed (to prevent re-execution)
            emit ProposalExecuted(_proposalId); // Could emit a different event like ProposalFailed if needed
        }
        proposals[_proposalId].isActive = false; // Proposal is no longer active
    }

    // --- 6. Task/Bounty System Functions ---
    function createTask(string memory _title, string memory _descriptionURI, uint256 _rewardPoints) public onlyRegisteredUser whenNotPaused {
        uint256 taskId = nextTaskId++;
        tasks[taskId] = Task({
            creator: msg.sender,
            title: _title,
            descriptionURI: _descriptionURI,
            rewardPoints: _rewardPoints,
            isOpen: true,
            submissions: mapping(address => string)(),
            approvedSubmitter: address(0),
            isApproved: false,
            exists: true
        });
        emit TaskCreated(taskId, msg.sender);
    }

    function submitTask(uint256 _taskId, string memory _submissionURI) public onlyRegisteredUser whenNotPaused taskExists(_taskId) {
        require(tasks[_taskId].isOpen, "Task is not open for submissions");
        require(tasks[_taskId].creator != msg.sender, "Task creator cannot submit for their own task");
        tasks[_taskId].submissions[msg.sender] = _submissionURI;
        emit TaskSubmitted(_taskId, msg.sender);
    }

    function approveTaskSubmission(uint256 _taskId, address _submissionAuthor) public onlyRegisteredUser whenNotPaused taskExists(_taskId) {
        require(tasks[_taskId].creator == msg.sender || msg.sender == platformAdmin, "Only task creator or admin can approve submission");
        require(tasks[_taskId].isOpen, "Task is not open for approval");
        require(tasks[_taskId].submissions[_submissionAuthor].length > 0, "No submission from this author");
        require(!tasks[_taskId].isApproved, "Submission already approved for this task");

        tasks[_taskId].approvedSubmitter = _submissionAuthor;
        tasks[_taskId].isApproved = true;
        tasks[_taskId].isOpen = false; // Close the task after approval
        awardReputationPoints(_submissionAuthor, tasks[_taskId].rewardPoints); // Award points to submitter

        emit TaskSubmissionApproved(_taskId, _submissionAuthor);
    }

    function getTask(uint256 _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    // --- 7. Platform Administration and Utility Functions ---
    function setAdmin(address _newAdmin) public onlyPlatformAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address");
        platformAdmin = _newAdmin;
        emit AdminChanged(_newAdmin);
        transferOwnership(_newAdmin); // Optional: Transfer contract ownership as well
    }

    function pauseContract() public onlyPlatformAdmin {
        require(!contractPaused, "Contract is already paused");
        contractPaused = true;
        _pause(); // OpenZeppelin Pausable function
        emit ContractPaused();
    }

    function unpauseContract() public onlyPlatformAdmin whenPaused {
        contractPaused = false;
        _unpause(); // OpenZeppelin Pausable function
        emit ContractUnpaused();
    }

    function withdrawContractBalance() public onlyPlatformAdmin {
        uint256 balance = address(this).balance;
        payable(platformAdmin).transfer(balance);
    }

    // --- Override ERC721 tokenURI to point to dynamic metadata if needed ---
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // You can customize this to return dynamic metadata based on token properties
        // For now, it returns the baseURI set during minting.
        return super.tokenURI(tokenId);
    }

    // --- Fallback function to prevent accidental ether sent to contract ---
    receive() external payable {
        revert("Do not send Ether directly to this contract. Use platform features.");
    }
}
```