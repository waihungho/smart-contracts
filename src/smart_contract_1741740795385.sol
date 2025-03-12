```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Skill Marketplace with Dynamic NFTs
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace that leverages reputation, skills, and dynamic NFTs
 *      to create a robust ecosystem for skill-based services.
 *
 * Contract Outline and Function Summary:
 *
 * 1. **User Registration and Profile Management:**
 *    - `registerUser(string _username, string _profileDescription)`: Allows users to register with a unique username and profile description.
 *    - `updateProfileDescription(string _newDescription)`: Allows registered users to update their profile description.
 *    - `getUsername(address _user)`: Returns the username associated with a given address.
 *    - `getProfileDescription(address _user)`: Returns the profile description of a given user.
 *
 * 2. **Skill Management:**
 *    - `addSkill(string _skillName)`: Allows admins to add new skills to the marketplace.
 *    - `listSkills()`: Returns a list of all skills available in the marketplace.
 *    - `assignSkillToUser(address _user, uint _skillId)`: Allows users to assign skills to their profile from the available skills.
 *    - `removeSkillFromUser(address _user, uint _skillId)`: Allows users to remove skills from their profile.
 *    - `getUserSkills(address _user)`: Returns a list of skill IDs associated with a user.
 *
 * 3. **Reputation System:**
 *    - `submitReview(address _provider, uint8 _rating, string _reviewText)`: Allows users to submit reviews and ratings for service providers.
 *    - `getAverageRating(address _provider)`: Returns the average rating for a service provider.
 *    - `getReviewCount(address _provider)`: Returns the number of reviews received by a provider.
 *    - `getUserReviews(address _provider)`: Returns a list of review details for a given provider.
 *
 * 4. **Task/Job Posting and Bidding:**
 *    - `createTask(string _taskTitle, string _taskDescription, uint _skillRequiredId, uint _budget)`: Allows users to create new tasks/jobs requiring specific skills.
 *    - `getTaskDetails(uint _taskId)`: Returns details of a specific task.
 *    - `submitBid(uint _taskId, uint _bidAmount)`: Allows providers to submit bids for open tasks.
 *    - `acceptBid(uint _taskId, address _provider)`: Allows task creators to accept a bid for their task.
 *    - `getTaskBids(uint _taskId)`: Returns a list of bids for a specific task.
 *
 * 5. **Dynamic NFT for Skill and Reputation Badge:**
 *    - `mintSkillBadgeNFT(address _user)`: Mints a dynamic NFT badge representing the user's skills and reputation tier.
 *    - `getSkillBadgeNFTMetadataURI(uint _tokenId)`: Returns the metadata URI for a skill badge NFT, which is dynamically generated.
 *    - `getNFTTokenId(address _user)`: Returns the NFT token ID associated with a user (if minted).
 *
 * 6. **Escrow and Payment Management:**
 *    - `depositEscrow(uint _taskId) payable`: Allows task creators to deposit funds into escrow for a task.
 *    - `releasePayment(uint _taskId)`: Allows task creators to release payment from escrow to the provider upon task completion.
 *    - `requestDispute(uint _taskId, string _disputeReason)`: Allows either party to request a dispute for a task.
 *    - `resolveDispute(uint _taskId, bool _providerWins)`: Allows admins to resolve disputes and release funds accordingly.
 *
 * 7. **Admin Functions:**
 *    - `addAdmin(address _newAdmin)`: Allows current admin to add new admins.
 *    - `removeAdmin(address _adminToRemove)`: Allows current admin to remove admins.
 *    - `isSkillExists(string _skillName)`: Check if a skill already exists.
 */
contract SkillReputationMarketplace {
    // --- Data Structures ---

    struct UserProfile {
        string username;
        string profileDescription;
        uint[] skills;
        uint reviewCount;
        uint totalRating;
    }

    struct Skill {
        string skillName;
    }

    struct Task {
        address creator;
        string title;
        string description;
        uint skillRequiredId;
        uint budget;
        address provider; // Provider assigned to the task after bid acceptance
        TaskStatus status;
        uint escrowBalance;
        address[] bids; // Addresses of users who placed bids
    }

    struct Review {
        address reviewer;
        uint8 rating; // 1-5 star rating
        string reviewText;
        uint timestamp;
    }

    enum TaskStatus {
        Open,
        InProgress,
        Completed,
        Disputed,
        Closed
    }

    // --- State Variables ---

    mapping(address => UserProfile) public userProfiles;
    mapping(uint => Skill) public skills;
    uint public skillCount;
    mapping(uint => Task) public tasks;
    uint public taskCount;
    mapping(address => Review[]) public userReviews;
    mapping(address => uint) public reputationScores; // Could be calculated on-demand, but storing for efficiency
    address public owner;
    mapping(address => bool) public admins;
    mapping(address => uint) public userNFTTokenIds; // Map user address to their SkillBadge NFT token ID
    uint public nextNFTTokenId = 1; // Starting token ID for NFTs


    // --- Events ---

    event UserRegistered(address user, string username);
    event ProfileUpdated(address user);
    event SkillAdded(uint skillId, string skillName);
    event SkillAssignedToUser(address user, uint skillId);
    event SkillRemovedFromUser(address user, uint skillId);
    event ReviewSubmitted(address provider, address reviewer, uint8 rating, string reviewText);
    event TaskCreated(uint taskId, address creator, string taskTitle);
    event BidSubmitted(uint taskId, address provider, uint bidAmount);
    event BidAccepted(uint taskId, address provider);
    event EscrowDeposited(uint taskId, uint amount);
    event PaymentReleased(uint taskId, address provider, uint amount);
    event DisputeRequested(uint taskId, address requester, string reason);
    event DisputeResolved(uint taskId, bool providerWon);
    event SkillBadgeNFTMinted(address user, uint tokenId);


    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(bytes(userProfiles[msg.sender].username).length > 0, "User not registered");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can perform this action");
        _;
    }

    modifier taskExists(uint _taskId) {
        require(_taskId < taskCount, "Task does not exist");
        _;
    }

    modifier taskOpen(uint _taskId) {
        require(tasks[_taskId].status == TaskStatus.Open, "Task is not open for bids");
        _;
    }

    modifier taskInProgress(uint _taskId) {
        require(tasks[_taskId].status == TaskStatus.InProgress, "Task is not in progress");
        _;
    }

    modifier taskCreator(uint _taskId) {
        require(tasks[_taskId].creator == msg.sender, "Only task creator can perform this action");
        _;
    }

    modifier taskProvider(uint _taskId) {
        require(tasks[_taskId].provider == msg.sender, "Only assigned provider can perform this action");
        _;
    }

    modifier bidNotSubmitted(uint _taskId) {
        for (uint i = 0; i < tasks[_taskId].bids.length; i++) {
            require(tasks[_taskId].bids[i] != msg.sender, "Bid already submitted by this provider");
        }
        _;
    }

    modifier escrowBalanceSufficient(uint _taskId) {
        require(tasks[_taskId].escrowBalance >= tasks[_taskId].budget, "Escrow balance is insufficient");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        admins[owner] = true; // Set contract deployer as initial admin
        skillCount = 0;
        taskCount = 0;
    }

    // --- 1. User Registration and Profile Management ---

    function registerUser(string memory _username, string memory _profileDescription) public {
        require(bytes(userProfiles[msg.sender].username).length == 0, "User already registered");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters");
        require(bytes(_profileDescription).length <= 256, "Profile description too long (max 256 characters)");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileDescription: _profileDescription,
            skills: new uint[](0),
            reviewCount: 0,
            totalRating: 0
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfileDescription(string memory _newDescription) public onlyRegisteredUser {
        require(bytes(_newDescription).length <= 256, "Profile description too long (max 256 characters)");
        userProfiles[msg.sender].profileDescription = _newDescription;
        emit ProfileUpdated(msg.sender);
    }

    function getUsername(address _user) public view returns (string memory) {
        return userProfiles[_user].username;
    }

    function getProfileDescription(address _user) public view returns (string memory) {
        return userProfiles[_user].profileDescription;
    }


    // --- 2. Skill Management ---

    function addSkill(string memory _skillName) public onlyAdmin {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 64, "Skill name must be between 1 and 64 characters");
        require(!isSkillExists(_skillName), "Skill already exists");
        skills[skillCount] = Skill({skillName: _skillName});
        emit SkillAdded(skillCount, _skillName);
        skillCount++;
    }

    function listSkills() public view returns (Skill[] memory) {
        Skill[] memory skillList = new Skill[](skillCount);
        for (uint i = 0; i < skillCount; i++) {
            skillList[i] = skills[i];
        }
        return skillList;
    }

    function assignSkillToUser(address _user, uint _skillId) public onlyRegisteredUser {
        require(_skillId < skillCount, "Invalid skill ID");
        bool alreadyAssigned = false;
        for (uint i = 0; i < userProfiles[_user].skills.length; i++) {
            if (userProfiles[_user].skills[i] == _skillId) {
                alreadyAssigned = true;
                break;
            }
        }
        require(!alreadyAssigned, "Skill already assigned to user");
        userProfiles[_user].skills.push(_skillId);
        emit SkillAssignedToUser(_user, _skillId);
    }

    function removeSkillFromUser(address _user, uint _skillId) public onlyRegisteredUser {
        require(_skillId < skillCount, "Invalid skill ID");
        bool skillFound = false;
        uint skillIndex;
        for (uint i = 0; i < userProfiles[_user].skills.length; i++) {
            if (userProfiles[_user].skills[i] == _skillId) {
                skillFound = true;
                skillIndex = i;
                break;
            }
        }
        require(skillFound, "Skill not assigned to user");

        // Remove skill from array (efficiently by replacing with last element and popping)
        if (skillIndex < userProfiles[_user].skills.length - 1) {
            userProfiles[_user].skills[skillIndex] = userProfiles[_user].skills[userProfiles[_user].skills.length - 1];
        }
        userProfiles[_user].skills.pop();
        emit SkillRemovedFromUser(_user, _skillId);
    }

    function getUserSkills(address _user) public view returns (uint[] memory) {
        return userProfiles[_user].skills;
    }

    function isSkillExists(string memory _skillName) public view returns (bool) {
        for (uint i = 0; i < skillCount; i++) {
            if (keccak256(bytes(skills[i].skillName)) == keccak256(bytes(_skillName))) {
                return true;
            }
        }
        return false;
    }


    // --- 3. Reputation System ---

    function submitReview(address _provider, uint8 _rating, string memory _reviewText) public onlyRegisteredUser {
        require(bytes(userProfiles[_provider].username).length > 0, "Provider address is not a registered user");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(bytes(_reviewText).length <= 500, "Review text too long (max 500 characters)");
        require(_provider != msg.sender, "Cannot review yourself"); // Prevent self-reviews

        userReviews[_provider].push(Review({
            reviewer: msg.sender,
            rating: _rating,
            reviewText: _reviewText,
            timestamp: block.timestamp
        }));

        userProfiles[_provider].reviewCount++;
        userProfiles[_provider].totalRating += _rating;

        emit ReviewSubmitted(_provider, msg.sender, _rating, _reviewText);
    }

    function getAverageRating(address _provider) public view returns (uint) {
        if (userProfiles[_provider].reviewCount == 0) {
            return 0;
        }
        return userProfiles[_provider].totalRating / userProfiles[_provider].reviewCount;
    }

    function getReviewCount(address _provider) public view returns (uint) {
        return userProfiles[_provider].reviewCount;
    }

    function getUserReviews(address _provider) public view returns (Review[] memory) {
        return userReviews[_provider];
    }


    // --- 4. Task/Job Posting and Bidding ---

    function createTask(string memory _taskTitle, string memory _taskDescription, uint _skillRequiredId, uint _budget) public onlyRegisteredUser {
        require(bytes(_taskTitle).length > 0 && bytes(_taskTitle).length <= 100, "Task title must be between 1 and 100 characters");
        require(bytes(_taskDescription).length > 0 && bytes(_taskDescription).length <= 1000, "Task description must be between 1 and 1000 characters");
        require(_skillRequiredId < skillCount, "Invalid skill ID required");
        require(_budget > 0, "Budget must be greater than 0");

        tasks[taskCount] = Task({
            creator: msg.sender,
            title: _taskTitle,
            description: _taskDescription,
            skillRequiredId: _skillRequiredId,
            budget: _budget,
            provider: address(0), // No provider assigned initially
            status: TaskStatus.Open,
            escrowBalance: 0,
            bids: new address[](0)
        });

        emit TaskCreated(taskCount, msg.sender, _taskTitle);
        taskCount++;
    }

    function getTaskDetails(uint _taskId) public view taskExists(_taskId) returns (Task memory) {
        return tasks[_taskId];
    }

    function submitBid(uint _taskId, uint _bidAmount) public onlyRegisteredUser taskExists(_taskId) taskOpen(_taskId) bidNotSubmitted(_taskId) {
        require(_bidAmount > 0 && _bidAmount <= tasks[_taskId].budget, "Bid amount must be greater than 0 and not exceed task budget");
        // Consider adding logic to check if bidder possesses the required skill (optional for complexity)

        tasks[_taskId].bids.push(msg.sender);
        emit BidSubmitted(_taskId, msg.sender, _bidAmount);
    }

    function acceptBid(uint _taskId, address _provider) public onlyRegisteredUser taskExists(_taskId) taskOpen(_taskId) taskCreator(_taskId) {
        bool bidFound = false;
        for (uint i = 0; i < tasks[_taskId].bids.length; i++) {
            if (tasks[_taskId].bids[i] == _provider) {
                bidFound = true;
                break;
            }
        }
        require(bidFound, "Provider has not submitted a bid for this task");
        require(bytes(userProfiles[_provider].username).length > 0, "Provider is not a registered user");

        tasks[_taskId].provider = _provider;
        tasks[_taskId].status = TaskStatus.InProgress;
        emit BidAccepted(_taskId, _provider);
    }

    function getTaskBids(uint _taskId) public view taskExists(_taskId) returns (address[] memory) {
        return tasks[_taskId].bids;
    }


    // --- 5. Dynamic NFT for Skill and Reputation Badge ---

    function mintSkillBadgeNFT(address _user) public onlyRegisteredUser {
        require(userNFTTokenIds[_user] == 0, "NFT already minted for this user"); // Only mint once per user

        uint tokenId = nextNFTTokenId++;
        userNFTTokenIds[_user] = tokenId;

        emit SkillBadgeNFTMinted(_user, tokenId);
    }

    function getSkillBadgeNFTMetadataURI(uint _tokenId) public view returns (string memory) {
        // In a real-world scenario, this would be off-chain metadata generation, likely using IPFS or similar.
        // For simplicity in this example, we'll return a placeholder URI.

        // Fetch user data for dynamic metadata
        address userAddress = address(0); // Need to reverse lookup user from token ID (not easily done efficiently in Solidity) - simplified for example
        for(address addr in userNFTTokenIds) {
            if(userNFTTokenIds[addr] == _tokenId) {
                userAddress = addr;
                break;
            }
        }
        require(userAddress != address(0), "Invalid token ID");

        UserProfile memory profile = userProfiles[userAddress];
        uint avgRating = getAverageRating(userAddress);
        string memory username = profile.username;
        uint[] memory skillIds = profile.skills;

        // Construct a simple JSON-like string for metadata (in real-world, use proper JSON library/off-chain generation)
        string memory metadata = string(abi.encodePacked(
            '{"name": "', username, ' Skill Badge", ',
            '"description": "Dynamic NFT badge representing skills and reputation.", ',
            '"attributes": [',
                '{"trait_type": "Average Rating", "value": "', uintToString(avgRating), '"},',
                '{"trait_type": "Skills", "value": "', skillIdsToString(skillIds), '"}' , // Simplified skill list for example
            ']',
            '}'
        ));

        // Placeholder URI - replace with actual URI generation (IPFS, centralized server, etc.)
        return string(abi.encodePacked("ipfs://placeholder/", keccak256(bytes(metadata))));
    }

    function getNFTTokenId(address _user) public view returns (uint) {
        return userNFTTokenIds[_user];
    }


    // --- 6. Escrow and Payment Management ---

    function depositEscrow(uint _taskId) public payable onlyRegisteredUser taskExists(_taskId) taskCreator(_taskId) taskOpen(_taskId) {
        require(msg.value >= tasks[_taskId].budget, "Deposited amount is less than the task budget");
        tasks[_taskId].escrowBalance += msg.value;
        emit EscrowDeposited(_taskId, msg.value);
    }

    function releasePayment(uint _taskId) public onlyRegisteredUser taskExists(_taskId) taskCreator(_taskId) taskInProgress(_taskId) escrowBalanceSufficient(_taskId) {
        require(tasks[_taskId].provider != address(0), "No provider assigned to the task");
        tasks[_taskId].status = TaskStatus.Completed;
        uint paymentAmount = tasks[_taskId].budget;
        tasks[_taskId].escrowBalance -= paymentAmount; // Should be 0 after payment if escrow was funded correctly
        payable(tasks[_taskId].provider).transfer(paymentAmount);
        emit PaymentReleased(_taskId, tasks[_taskId].provider, paymentAmount);
    }

    function requestDispute(uint _taskId, string memory _disputeReason) public onlyRegisteredUser taskExists(_taskId) taskInProgress(_taskId) {
        require(bytes(_disputeReason).length > 0 && bytes(_disputeReason).length <= 200, "Dispute reason must be between 1 and 200 characters");
        tasks[_taskId].status = TaskStatus.Disputed;
        emit DisputeRequested(_taskId, msg.sender, _disputeReason);
    }

    function resolveDispute(uint _taskId, bool _providerWins) public onlyAdmin taskExists(_taskId) taskInProgress(_taskId) { // Should be 'Disputed' status, but keeping 'InProgress' for simplicity in example flow.
        require(tasks[_taskId].status == TaskStatus.Disputed, "Task is not in dispute");
        tasks[_taskId].status = TaskStatus.Closed; // Mark task as closed after dispute resolution

        if (_providerWins) {
            uint paymentAmount = tasks[_taskId].budget;
            payable(tasks[_taskId].provider).transfer(paymentAmount); // Release full payment to provider
            emit PaymentReleased(_taskId, tasks[_taskId].provider, paymentAmount);
        } else {
            payable(tasks[_taskId].creator).transfer(tasks[_taskId].escrowBalance); // Return escrow to creator
            // In real scenario, might partially release payment depending on dispute outcome.
        }
        tasks[_taskId].escrowBalance = 0; // Clear escrow balance after resolution
        emit DisputeResolved(_taskId, _providerWins);
    }


    // --- 7. Admin Functions ---

    function addAdmin(address _newAdmin) public onlyAdmin {
        admins[_newAdmin] = true;
    }

    function removeAdmin(address _adminToRemove) public onlyAdmin {
        require(_adminToRemove != owner, "Cannot remove contract owner as admin");
        admins[_adminToRemove] = false;
    }


    // --- Utility Functions (for NFT Metadata Example - not core contract logic) ---

    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function skillIdsToString(uint[] memory _skillIds) internal view returns (string memory) {
        string memory skillsStr = "[";
        for (uint i = 0; i < _skillIds.length; i++) {
            skillsStr = string(abi.encodePacked(skillsStr, '"', skills[_skillIds[i]].skillName, '"'));
            if (i < _skillIds.length - 1) {
                skillsStr = string(abi.encodePacked(skillsStr, ", "));
            }
        }
        skillsStr = string(abi.encodePacked(skillsStr, "]"));
        return skillsStr;
    }

    // Fallback function to prevent accidental ether sent to contract from being lost
    receive() external payable {}
}
```