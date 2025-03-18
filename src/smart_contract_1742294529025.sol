```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Knowledge Garden - A Collaborative Learning and Curation Platform
 * @author Bard (Example - Do not use in production without thorough audit)
 * @dev This smart contract implements a decentralized platform for collaborative learning and knowledge sharing.
 * It allows users to contribute, curate, and validate knowledge nodes, fostering a community-driven knowledge base.
 *
 * **Outline and Function Summary:**
 *
 * **1. Knowledge Node Management:**
 *    - `createKnowledgeNode(string _title, string _contentHash, string[] _tags)`: Allows registered users to create new knowledge nodes.
 *    - `viewKnowledgeNode(uint256 _nodeId)`: Allows anyone to view the details of a knowledge node.
 *    - `editKnowledgeNode(uint256 _nodeId, string _newContentHash)`: Allows the node creator to propose an edit to the content.
 *    - `voteOnEdit(uint256 _nodeId, bool _approve)`: Allows registered users to vote on proposed edits.
 *    - `flagKnowledgeNode(uint256 _nodeId, string _reason)`: Allows registered users to flag a node for review (e.g., misinformation, inappropriate content).
 *    - `resolveFlag(uint256 _nodeId, bool _remove)`: Admin/moderator function to resolve flags and potentially remove nodes.
 *    - `getNodeTags(uint256 _nodeId)`:  Returns the tags associated with a knowledge node.
 *    - `searchKnowledgeNodesByTag(string _tag)`: Returns a list of node IDs associated with a specific tag.
 *
 * **2. User and Profile Management:**
 *    - `registerUser(string _username, string _profileHash)`: Allows users to register with a unique username and profile information.
 *    - `updateUserProfile(string _newProfileHash)`: Allows registered users to update their profile information.
 *    - `getUserProfile(address _userAddress)`: Returns the profile information associated with a user address.
 *    - `getUsername(address _userAddress)`: Returns the username associated with a user address.
 *
 * **3. Reputation and Curation System:**
 *    - `upvoteKnowledgeNode(uint256 _nodeId)`: Allows registered users to upvote a knowledge node.
 *    - `downvoteKnowledgeNode(uint256 _nodeId)`: Allows registered users to downvote a knowledge node.
 *    - `getNodeReputation(uint256 _nodeId)`: Returns the reputation score of a knowledge node.
 *    - `getUserReputation(address _userAddress)`: Returns the reputation score of a user (based on contributions and curation).
 *    - `calculateUserReputation(address _userAddress)`: (Internal) Calculates and updates user reputation based on their actions.
 *
 * **4. Governance and Platform Parameters:**
 *    - `setPlatformFee(uint256 _newFee)`: Admin function to set a platform fee (example - could be used for future funding).
 *    - `getPlatformFee()`: Returns the current platform fee.
 *    - `pauseContract()`: Admin function to pause the contract for emergency maintenance.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 *    - `isAdmin(address _user)`:  Checks if an address is an admin.
 *
 * **5. Utility and Security Functions:**
 *    - `getContractBalance()`: Returns the contract's current ETH balance (for potential platform funding visibility).
 *    - `withdrawFunds(address payable _recipient, uint256 _amount)`: Admin function to withdraw funds from the contract.
 *    - `isRegisteredUser(address _userAddress)`: Checks if an address is a registered user.
 */

contract DecentralizedKnowledgeGarden {
    // State Variables

    // Knowledge Nodes
    struct KnowledgeNode {
        uint256 nodeId;
        address creator;
        string title;
        string contentHash; // IPFS hash or similar for content storage
        uint256 creationTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        bool isPendingEdit;
        string pendingEditContentHash;
        mapping(address => bool) editVotes; // Users who voted on the current edit
        uint256 editVotesCount;
        bool isFlagged;
        string flagReason;
        bool isRemoved;
        string[] tags;
    }
    mapping(uint256 => KnowledgeNode) public knowledgeNodes;
    uint256 public nextNodeId = 1;

    // Users and Profiles
    struct UserProfile {
        address userAddress;
        string username;
        string profileHash; // IPFS hash for profile details (bio, etc.)
        uint256 reputationScore;
        bool isRegistered;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(string => address) public usernameToAddress; // To ensure unique usernames

    // Platform Parameters
    uint256 public platformFee = 0; // Example platform fee (can be used for future funding)
    address public admin;
    bool public paused = false;

    // Events
    event NodeCreated(uint256 nodeId, address creator, string title);
    event NodeEdited(uint256 nodeId);
    event EditVoteCast(uint256 nodeId, address voter, bool approved);
    event NodeFlagged(uint256 nodeId, address flagger, string reason);
    event NodeFlagResolved(uint256 nodeId, bool removed);
    event UserRegistered(address userAddress, string username);
    event UserProfileUpdated(address userAddress);
    event NodeUpvoted(uint256 nodeId, address user);
    event NodeDownvoted(uint256 nodeId, address user);
    event PlatformFeeSet(uint256 newFee);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event FundsWithdrawn(address recipient, uint256 amount);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].isRegistered, "User must be registered to perform this action.");
        _;
    }

    modifier validNodeId(uint256 _nodeId) {
        require(knowledgeNodes[_nodeId].nodeId != 0, "Invalid Node ID.");
        _;
    }

    modifier onlyOwnerOrAdmin(uint256 _nodeId) {
        require(knowledgeNodes[_nodeId].creator == msg.sender || msg.sender == admin, "Only creator or admin can perform this action.");
        _;
    }


    // Constructor
    constructor() {
        admin = msg.sender;
    }

    // -------------------------------------------------------------------------
    // 1. Knowledge Node Management
    // -------------------------------------------------------------------------

    /// @notice Creates a new knowledge node.
    /// @param _title The title of the knowledge node.
    /// @param _contentHash IPFS hash (or similar) of the knowledge node content.
    /// @param _tags Array of tags associated with the knowledge node.
    function createKnowledgeNode(string memory _title, string memory _contentHash, string[] memory _tags)
        public
        whenNotPaused
        onlyRegisteredUser
    {
        require(bytes(_title).length > 0 && bytes(_contentHash).length > 0, "Title and content hash cannot be empty.");

        knowledgeNodes[nextNodeId] = KnowledgeNode({
            nodeId: nextNodeId,
            creator: msg.sender,
            title: _title,
            contentHash: _contentHash,
            creationTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            isPendingEdit: false,
            pendingEditContentHash: "",
            editVotesCount: 0,
            isFlagged: false,
            flagReason: "",
            isRemoved: false,
            tags: _tags
        });

        emit NodeCreated(nextNodeId, msg.sender, _title);
        nextNodeId++;
        calculateUserReputation(msg.sender); // Increase reputation for contribution
    }

    /// @notice Allows anyone to view the details of a knowledge node.
    /// @param _nodeId The ID of the knowledge node to view.
    /// @return KnowledgeNode struct containing node details.
    function viewKnowledgeNode(uint256 _nodeId)
        public
        view
        validNodeId(_nodeId)
        returns (KnowledgeNode memory)
    {
        require(!knowledgeNodes[_nodeId].isRemoved, "Node has been removed.");
        return knowledgeNodes[_nodeId];
    }

    /// @notice Allows the node creator to propose an edit to the content.
    /// @param _nodeId The ID of the knowledge node to edit.
    /// @param _newContentHash IPFS hash (or similar) of the new content.
    function editKnowledgeNode(uint256 _nodeId, string memory _newContentHash)
        public
        whenNotPaused
        validNodeId(_nodeId)
        onlyOwnerOrAdmin(_nodeId)
    {
        require(!knowledgeNodes[_nodeId].isRemoved, "Cannot edit a removed node.");
        require(bytes(_newContentHash).length > 0, "New content hash cannot be empty.");

        knowledgeNodes[_nodeId].isPendingEdit = true;
        knowledgeNodes[_nodeId].pendingEditContentHash = _newContentHash;
        // Reset edit votes for a new proposal
        delete knowledgeNodes[_nodeId].editVotes;
        knowledgeNodes[_nodeId].editVotesCount = 0;

        emit NodeEdited(_nodeId);
    }

    /// @notice Allows registered users to vote on proposed edits.
    /// @param _nodeId The ID of the knowledge node with a pending edit.
    /// @param _approve True to approve the edit, false to reject.
    function voteOnEdit(uint256 _nodeId, bool _approve)
        public
        whenNotPaused
        validNodeId(_nodeId)
        onlyRegisteredUser
    {
        require(knowledgeNodes[_nodeId].isPendingEdit, "No pending edit for this node.");
        require(!knowledgeNodes[_nodeId].editVotes[msg.sender], "User has already voted on this edit.");

        knowledgeNodes[_nodeId].editVotes[msg.sender] = true;
        knowledgeNodes[_nodeId].editVotesCount++;

        emit EditVoteCast(_nodeId, msg.sender, _approve);

        // Simple majority for approval (can be made more complex with quorum etc.)
        if (knowledgeNodes[_nodeId].editVotesCount > (getRegisteredUserCount() / 2)) { // Simplified majority
            if (_approve) {
                knowledgeNodes[_nodeId].contentHash = knowledgeNodes[_nodeId].pendingEditContentHash;
            }
            knowledgeNodes[_nodeId].isPendingEdit = false;
            knowledgeNodes[_nodeId].pendingEditContentHash = "";
            delete knowledgeNodes[_nodeId].editVotes; // Clear votes after resolution
            knowledgeNodes[_nodeId].editVotesCount = 0;
        }
    }

    /// @notice Allows registered users to flag a node for review.
    /// @param _nodeId The ID of the knowledge node to flag.
    /// @param _reason The reason for flagging the node.
    function flagKnowledgeNode(uint256 _nodeId, string memory _reason)
        public
        whenNotPaused
        validNodeId(_nodeId)
        onlyRegisteredUser
    {
        require(!knowledgeNodes[_nodeId].isRemoved, "Cannot flag a removed node.");
        require(!knowledgeNodes[_nodeId].isFlagged, "Node is already flagged.");
        require(bytes(_reason).length > 0, "Flag reason cannot be empty.");

        knowledgeNodes[_nodeId].isFlagged = true;
        knowledgeNodes[_nodeId].flagReason = _reason;

        emit NodeFlagged(_nodeId, msg.sender, _reason);
    }

    /// @notice Admin/moderator function to resolve flags and potentially remove nodes.
    /// @param _nodeId The ID of the flagged knowledge node.
    /// @param _remove True to remove the node, false to resolve the flag without removal.
    function resolveFlag(uint256 _nodeId, bool _remove)
        public
        whenNotPaused
        validNodeId(_nodeId)
        onlyAdmin
    {
        require(knowledgeNodes[_nodeId].isFlagged, "Node is not flagged.");

        knowledgeNodes[_nodeId].isFlagged = false;
        knowledgeNodes[_nodeId].flagReason = ""; // Clear flag reason

        if (_remove) {
            knowledgeNodes[_nodeId].isRemoved = true;
        }

        emit NodeFlagResolved(_nodeId, _remove);
    }

    /// @notice Returns the tags associated with a knowledge node.
    /// @param _nodeId The ID of the knowledge node.
    /// @return Array of tags.
    function getNodeTags(uint256 _nodeId)
        public
        view
        validNodeId(_nodeId)
        returns (string[] memory)
    {
        return knowledgeNodes[_nodeId].tags;
    }

    /// @notice Searches knowledge nodes by tag.
    /// @param _tag The tag to search for.
    /// @return Array of node IDs that have the given tag.
    function searchKnowledgeNodesByTag(string memory _tag)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory matchingNodeIds = new uint256[](nextNodeId - 1); // Max possible size
        uint256 matchCount = 0;
        for (uint256 i = 1; i < nextNodeId; i++) {
            if (knowledgeNodes[i].nodeId != 0 && !knowledgeNodes[i].isRemoved) { // Check if node exists and is not removed
                for (uint256 j = 0; j < knowledgeNodes[i].tags.length; j++) {
                    if (keccak256(bytes(knowledgeNodes[i].tags[j])) == keccak256(bytes(_tag))) {
                        matchingNodeIds[matchCount] = i;
                        matchCount++;
                        break; // Found tag, move to next node
                    }
                }
            }
        }

        // Resize array to actual number of matches
        uint256[] memory results = new uint256[](matchCount);
        for (uint256 i = 0; i < matchCount; i++) {
            results[i] = matchingNodeIds[i];
        }
        return results;
    }


    // -------------------------------------------------------------------------
    // 2. User and Profile Management
    // -------------------------------------------------------------------------

    /// @notice Registers a new user.
    /// @param _username The desired username. Must be unique.
    /// @param _profileHash IPFS hash (or similar) for user profile information.
    function registerUser(string memory _username, string memory _profileHash)
        public
        whenNotPaused
    {
        require(bytes(_username).length > 0 && bytes(_profileHash).length > 0, "Username and profile hash cannot be empty.");
        require(usernameToAddress[_username] == address(0), "Username already taken.");
        require(!userProfiles[msg.sender].isRegistered, "User is already registered.");

        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            username: _username,
            profileHash: _profileHash,
            reputationScore: 0,
            isRegistered: true
        });
        usernameToAddress[_username] = msg.sender;

        emit UserRegistered(msg.sender, _username);
    }

    /// @notice Updates the user's profile information.
    /// @param _newProfileHash IPFS hash (or similar) for the updated profile information.
    function updateUserProfile(string memory _newProfileHash)
        public
        whenNotPaused
        onlyRegisteredUser
    {
        require(bytes(_newProfileHash).length > 0, "Profile hash cannot be empty.");
        userProfiles[msg.sender].profileHash = _newProfileHash;
        emit UserProfileUpdated(msg.sender);
    }

    /// @notice Returns the profile information of a user.
    /// @param _userAddress The address of the user.
    /// @return UserProfile struct containing user details.
    function getUserProfile(address _userAddress)
        public
        view
        returns (UserProfile memory)
    {
        return userProfiles[_userAddress];
    }

    /// @notice Returns the username associated with a user address.
    /// @param _userAddress The address of the user.
    /// @return The username.
    function getUsername(address _userAddress)
        public
        view
        returns (string memory)
    {
        return userProfiles[_userAddress].username;
    }


    // -------------------------------------------------------------------------
    // 3. Reputation and Curation System
    // -------------------------------------------------------------------------

    /// @notice Allows registered users to upvote a knowledge node.
    /// @param _nodeId The ID of the knowledge node to upvote.
    function upvoteKnowledgeNode(uint256 _nodeId)
        public
        whenNotPaused
        validNodeId(_nodeId)
        onlyRegisteredUser
    {
        require(!knowledgeNodes[_nodeId].isRemoved, "Cannot upvote a removed node.");
        // Prevent double voting (optional - can be removed to allow changing vote)
        // require(!userVoteStatus[_nodeId][msg.sender], "User has already voted on this node.");

        knowledgeNodes[_nodeId].upvotes++;
        emit NodeUpvoted(_nodeId, msg.sender);
        calculateUserReputation(knowledgeNodes[_nodeId].creator); // Increase creator reputation
        calculateUserReputation(msg.sender); // Increase voter reputation (for curation)
    }

    /// @notice Allows registered users to downvote a knowledge node.
    /// @param _nodeId The ID of the knowledge node to downvote.
    function downvoteKnowledgeNode(uint256 _nodeId)
        public
        whenNotPaused
        validNodeId(_nodeId)
        onlyRegisteredUser
    {
        require(!knowledgeNodes[_nodeId].isRemoved, "Cannot downvote a removed node.");
        // Prevent double voting (optional - can be removed to allow changing vote)
        // require(!userVoteStatus[_nodeId][msg.sender], "User has already voted on this node.");

        knowledgeNodes[_nodeId].downvotes++;
        emit NodeDownvoted(_nodeId, msg.sender);
        calculateUserReputation(knowledgeNodes[_nodeId].creator); // Decrease creator reputation
        calculateUserReputation(msg.sender); // Increase voter reputation (for curation - even downvotes are curation)
    }

    /// @notice Returns the reputation score of a knowledge node.
    /// @param _nodeId The ID of the knowledge node.
    /// @return The reputation score.
    function getNodeReputation(uint256 _nodeId)
        public
        view
        validNodeId(_nodeId)
        returns (int256) // Using int256 to handle negative reputation
    {
        return int256(knowledgeNodes[_nodeId].upvotes) - int256(knowledgeNodes[_nodeId].downvotes);
    }

    /// @notice Returns the reputation score of a user.
    /// @param _userAddress The address of the user.
    /// @return The reputation score.
    function getUserReputation(address _userAddress)
        public
        view
        returns (uint256)
    {
        return userProfiles[_userAddress].reputationScore;
    }

    /// @dev (Internal) Calculates and updates user reputation based on their actions.
    /// @param _userAddress The address of the user to update reputation for.
    function calculateUserReputation(address _userAddress) internal {
        // Simple reputation calculation example:
        uint256 contributionPoints = 0;
        uint256 curationPoints = 0;

        // Contribution points: count nodes created (simplified)
        uint256 nodesCreated = 0;
        for (uint256 i = 1; i < nextNodeId; i++) {
            if (knowledgeNodes[i].creator == _userAddress) {
                nodesCreated++;
            }
        }
        contributionPoints = nodesCreated * 5; // Points per node created (example)

        // Curation points: count upvotes and downvotes given (simplified)
        uint256 votesGiven = 0;
        for (uint256 i = 1; i < nextNodeId; i++) {
            // In a real system, you might track user votes more explicitly for better calculation
            if (didUserVoteOnNode(_userAddress, i)) { // Placeholder - needs actual vote tracking
                votesGiven++;
            }
        }
        curationPoints = votesGiven * 1; // Points per vote (example)

        userProfiles[_userAddress].reputationScore = contributionPoints + curationPoints;
    }

    /// @dev Placeholder function - needs to be implemented for accurate reputation calculation based on votes given.
    function didUserVoteOnNode(address _userAddress, uint256 _nodeId) internal view returns (bool) {
        // In a real system, you would need to track user votes, possibly in a separate mapping
        // For now, this is a placeholder and always returns false (simplified example)
        return false;
    }


    // -------------------------------------------------------------------------
    // 4. Governance and Platform Parameters
    // -------------------------------------------------------------------------

    /// @notice Admin function to set the platform fee.
    /// @param _newFee The new platform fee amount.
    function setPlatformFee(uint256 _newFee) public onlyAdmin {
        platformFee = _newFee;
        emit PlatformFeeSet(_newFee);
    }

    /// @notice Returns the current platform fee.
    /// @return The platform fee amount.
    function getPlatformFee() public view returns (uint256) {
        return platformFee;
    }

    /// @notice Admin function to pause the contract.
    function pauseContract() public onlyAdmin {
        paused = true;
        emit ContractPaused(admin);
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() public onlyAdmin {
        paused = false;
        emit ContractUnpaused(admin);
    }

    /// @notice Checks if an address is an admin.
    /// @param _user The address to check.
    /// @return True if the address is an admin, false otherwise.
    function isAdmin(address _user) public view returns (bool) {
        return _user == admin;
    }


    // -------------------------------------------------------------------------
    // 5. Utility and Security Functions
    // -------------------------------------------------------------------------

    /// @notice Returns the contract's current ETH balance.
    /// @return The contract's ETH balance.
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Admin function to withdraw funds from the contract.
    /// @param _recipient The address to receive the withdrawn funds.
    /// @param _amount The amount of ETH to withdraw.
    function withdrawFunds(address payable _recipient, uint256 _amount) public onlyAdmin {
        require(_amount <= address(this).balance, "Insufficient contract balance.");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Withdrawal failed.");
        emit FundsWithdrawn(_recipient, _amount);
    }

    /// @notice Checks if an address is a registered user.
    /// @param _userAddress The address to check.
    /// @return True if the address is registered, false otherwise.
    function isRegisteredUser(address _userAddress) public view returns (bool) {
        return userProfiles[_userAddress].isRegistered;
    }

    /// @notice Returns the total count of registered users.
    /// @return The number of registered users.
    function getRegisteredUserCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextNodeId; i++) { // Iterate through node IDs as a proxy for user count (simplified - could be improved)
            if (userProfiles[knowledgeNodes[i].creator].isRegistered) { // Check if creator of each node is registered
                count++;
            }
        }
        return count; // This is a simplified estimation and might not be perfectly accurate
    }

    /// @notice Fallback function to prevent accidental sending of ETH to the contract.
    fallback() external payable {
        revert("This contract does not accept direct ETH transfers.");
    }

    /// @notice Receive function to prevent accidental sending of ETH to the contract.
    receive() external payable {
        revert("This contract does not accept direct ETH transfers.");
    }
}
```