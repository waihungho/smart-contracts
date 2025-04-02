```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Influence Oracle (DDRIO)
 * @author Bard (Example Smart Contract)
 * @dev A smart contract for managing decentralized reputation and influence scores
 *      based on various on-chain and potentially off-chain interactions.
 *      This contract aims to be more than just a simple token or registry,
 *      offering dynamic reputation calculation, influence metrics, and
 *      integrations with external data sources (simulated for demonstration).
 *
 * Function Summary:
 * -----------------
 *
 * **Core Profile Management:**
 * 1. `registerProfile(string _handle, string _profileUri)`: Registers a new user profile.
 * 2. `updateProfileHandle(string _newHandle)`: Updates the user's profile handle.
 * 3. `updateProfileUri(string _newProfileUri)`: Updates the user's profile URI.
 * 4. `getProfile(address _user)`: Retrieves a user's profile information.
 * 5. `isProfileRegistered(address _user)`: Checks if an address has a registered profile.
 * 6. `resolveHandleToAddress(string _handle)`: Resolves a handle to an address.
 *
 * **Reputation & Influence System:**
 * 7. `endorseProfile(address _targetUser, string _reason)`: Allows users to endorse each other, increasing reputation.
 * 8. `reportProfile(address _targetUser, string _reason)`: Allows users to report profiles for negative reputation impact.
 * 9. `getReputationScore(address _user)`: Retrieves the reputation score of a user.
 * 10. `getInfluenceScore(address _user)`: Retrieves the influence score of a user.
 * 11. `updateReputationFromExternalOracle(address _user, int256 _externalScore)`: Simulates reputation update from an external oracle.
 *
 * **Community & Interaction Features:**
 * 12. `createCommunity(string _communityName, string _description)`: Allows users to create communities.
 * 13. `joinCommunity(uint256 _communityId)`: Allows users to join a community.
 * 14. `leaveCommunity(uint256 _communityId)`: Allows users to leave a community.
 * 15. `getCommunityMembers(uint256 _communityId)`: Retrieves members of a community.
 * 16. `postToCommunity(uint256 _communityId, string _contentUri)`: Allows members to post content to a community.
 *
 * **Governance & Administration (Basic):**
 * 17. `setReputationWeight(string _metricName, uint256 _weight)`: Allows admin to adjust weights for reputation metrics.
 * 18. `pauseContract()`: Allows admin to pause the contract in emergency.
 * 19. `unpauseContract()`: Allows admin to unpause the contract.
 * 20. `transferOwnership(address _newOwner)`: Allows admin to transfer contract ownership.
 *
 * **Events:**
 * - `ProfileRegistered(address user, string handle, string profileUri)`
 * - `ProfileUpdated(address user, string handle, string profileUri)`
 * - `ProfileEndorsed(address endorser, address endorsedUser, string reason)`
 * - `ProfileReported(address reporter, address reportedUser, string reason)`
 * - `ReputationScoreUpdated(address user, int256 newScore)`
 * - `InfluenceScoreUpdated(address user, int256 newScore)`
 * - `CommunityCreated(uint256 communityId, address creator, string communityName)`
 * - `CommunityJoined(uint256 communityId, address user)`
 * - `CommunityLeft(uint256 communityId, address user)`
 * - `CommunityPostCreated(uint256 communityId, address author, uint256 postId)`
 * - `ContractPaused(address admin)`
 * - `ContractUnpaused(address admin)`
 * - `OwnershipTransferred(address previousOwner, address newOwner)`
 */
contract DDRIO {
    // --- State Variables ---

    address public owner;
    bool public paused;

    struct Profile {
        string handle;          // Unique username/handle
        string profileUri;      // URI to profile metadata (IPFS, etc.)
        int256 reputationScore; // Overall reputation score
        int256 influenceScore; // Influence score (potentially based on interactions)
        uint256 registrationTimestamp;
    }

    struct Community {
        string name;
        string description;
        address creator;
        uint256 creationTimestamp;
        mapping(address => bool) members; // Members of the community
        uint256 memberCount;
        uint256 postCount;
        mapping(uint256 => Post) posts;
    }

    struct Post {
        address author;
        string contentUri;
        uint256 timestamp;
    }

    mapping(address => Profile) public profiles;
    mapping(string => address) public handleToAddress;
    mapping(address => bool) public isRegistered;
    mapping(uint256 => Community) public communities;
    uint256 public communityCount;

    // Reputation metric weights (can be adjusted by admin - for demonstration)
    mapping(string => uint256) public reputationWeights;

    // --- Events ---
    event ProfileRegistered(address indexed user, string handle, string profileUri);
    event ProfileUpdated(address indexed user, string handle, string profileUri);
    event ProfileEndorsed(address indexed endorser, address indexed endorsedUser, string reason);
    event ProfileReported(address indexed reporter, address indexed reportedUser, string reason);
    event ReputationScoreUpdated(address indexed user, int256 newScore);
    event InfluenceScoreUpdated(address indexed user, int256 newScore);

    event CommunityCreated(uint256 indexed communityId, address indexed creator, string communityName);
    event CommunityJoined(uint256 indexed communityId, address indexed user);
    event CommunityLeft(uint256 indexed communityId, address indexed user);
    event CommunityPostCreated(uint256 indexed communityId, address indexed author, uint256 postId);

    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    modifier onlyRegisteredProfile() {
        require(isRegistered[msg.sender], "Profile not registered.");
        _;
    }

    modifier profileNotRegistered() {
        require(!isRegistered[msg.sender], "Profile already registered.");
        _;
    }

    modifier communityExists(uint256 _communityId) {
        require(communities[_communityId].creationTimestamp != 0, "Community does not exist.");
        _;
    }

    modifier communityMember(uint256 _communityId) {
        require(communities[_communityId].members[msg.sender], "Not a member of this community.");
        _;
    }


    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;

        // Initialize default reputation weights (example)
        reputationWeights["endorsements"] = 5;
        reputationWeights["reports"] = 10;
        reputationWeights["communityActivity"] = 2; // Example weight for community participation
        reputationWeights["externalOracle"] = 15; // Example weight for external oracle data
    }


    // --- Core Profile Management Functions ---

    /// @notice Registers a new user profile.
    /// @param _handle The unique handle for the user.
    /// @param _profileUri URI pointing to the user's profile metadata.
    function registerProfile(string memory _handle, string memory _profileUri)
        public
        whenNotPaused
        profileNotRegistered
    {
        require(bytes(_handle).length > 0 && bytes(_handle).length <= 32, "Handle must be between 1 and 32 characters.");
        require(bytes(_profileUri).length > 0 && bytes(_profileUri).length <= 256, "Profile URI must be between 1 and 256 characters.");
        require(handleToAddress[_handle] == address(0), "Handle already taken.");

        profiles[msg.sender] = Profile({
            handle: _handle,
            profileUri: _profileUri,
            reputationScore: 0,
            influenceScore: 0,
            registrationTimestamp: block.timestamp
        });
        handleToAddress[_handle] = msg.sender;
        isRegistered[msg.sender] = true;

        emit ProfileRegistered(msg.sender, _handle, _profileUri);
    }

    /// @notice Updates the user's profile handle.
    /// @param _newHandle The new handle for the user.
    function updateProfileHandle(string memory _newHandle)
        public
        whenNotPaused
        onlyRegisteredProfile
    {
        require(bytes(_newHandle).length > 0 && bytes(_newHandle).length <= 32, "Handle must be between 1 and 32 characters.");
        require(handleToAddress[_newHandle] == address(0), "Handle already taken.");

        string memory oldHandle = profiles[msg.sender].handle;
        handleToAddress[oldHandle] = address(0); // Remove old handle mapping
        profiles[msg.sender].handle = _newHandle;
        handleToAddress[_newHandle] = msg.sender; // Update to new handle mapping

        emit ProfileUpdated(msg.sender, _newHandle, profiles[msg.sender].profileUri);
    }

    /// @notice Updates the user's profile URI.
    /// @param _newProfileUri The new URI pointing to the user's profile metadata.
    function updateProfileUri(string memory _newProfileUri)
        public
        whenNotPaused
        onlyRegisteredProfile
    {
        require(bytes(_newProfileUri).length > 0 && bytes(_newProfileUri).length <= 256, "Profile URI must be between 1 and 256 characters.");
        profiles[msg.sender].profileUri = _newProfileUri;
        emit ProfileUpdated(msg.sender, profiles[msg.sender].handle, _newProfileUri);
    }

    /// @notice Retrieves a user's profile information.
    /// @param _user The address of the user.
    /// @return The user's profile struct.
    function getProfile(address _user)
        public
        view
        returns (Profile memory)
    {
        return profiles[_user];
    }

    /// @notice Checks if an address has a registered profile.
    /// @param _user The address to check.
    /// @return True if the profile is registered, false otherwise.
    function isProfileRegistered(address _user)
        public
        view
        returns (bool)
    {
        return isRegistered[_user];
    }

    /// @notice Resolves a handle to an address.
    /// @param _handle The handle to resolve.
    /// @return The address associated with the handle, or address(0) if not found.
    function resolveHandleToAddress(string memory _handle)
        public
        view
        returns (address)
    {
        return handleToAddress[_handle];
    }


    // --- Reputation & Influence System Functions ---

    /// @notice Allows users to endorse another user's profile, increasing their reputation.
    /// @param _targetUser The address of the user being endorsed.
    /// @param _reason A reason for the endorsement.
    function endorseProfile(address _targetUser, string memory _reason)
        public
        whenNotPaused
        onlyRegisteredProfile
    {
        require(isRegistered[_targetUser], "Target user profile not registered.");
        require(_targetUser != msg.sender, "Cannot endorse yourself.");

        profiles[_targetUser].reputationScore += int256(reputationWeights["endorsements"]);
        emit ReputationScoreUpdated(_targetUser, profiles[_targetUser].reputationScore);
        emit ProfileEndorsed(msg.sender, _targetUser, _reason);

        // Example influence score update (can be more sophisticated)
        profiles[msg.sender].influenceScore += 1; // Endorsing shows engagement
        emit InfluenceScoreUpdated(msg.sender, profiles[msg.sender].influenceScore);
    }

    /// @notice Allows users to report a profile for negative behavior, potentially decreasing reputation.
    /// @param _targetUser The address of the user being reported.
    /// @param _reason A reason for the report.
    function reportProfile(address _targetUser, string memory _reason)
        public
        whenNotPaused
        onlyRegisteredProfile
    {
        require(isRegistered[_targetUser], "Target user profile not registered.");
        require(_targetUser != msg.sender, "Cannot report yourself.");

        profiles[_targetUser].reputationScore -= int256(reputationWeights["reports"]);
        emit ReputationScoreUpdated(_targetUser, profiles[_targetUser].reputationScore);
        emit ProfileReported(msg.sender, _targetUser, _reason);

        // Example influence score update (reporting might also show engagement)
        profiles[msg.sender].influenceScore += 1;
        emit InfluenceScoreUpdated(msg.sender, profiles[msg.sender].influenceScore);
    }

    /// @notice Retrieves the reputation score of a user.
    /// @param _user The address of the user.
    /// @return The reputation score.
    function getReputationScore(address _user)
        public
        view
        returns (int256)
    {
        return profiles[_user].reputationScore;
    }

    /// @notice Retrieves the influence score of a user.
    /// @param _user The address of the user.
    /// @return The influence score.
    function getInfluenceScore(address _user)
        public
        view
        returns (int256)
    {
        return profiles[_user].influenceScore;
    }

    /// @dev **Simulated Oracle Function:** Updates reputation based on data from an external oracle.
    /// @notice This is a simplified example and in a real-world scenario, oracle interaction would be more complex.
    /// @param _user The address of the user to update reputation for.
    /// @param _externalScore The score received from the external oracle.
    function updateReputationFromExternalOracle(address _user, int256 _externalScore)
        public
        onlyOwner // For demonstration, only owner can simulate oracle update
        whenNotPaused
    {
        require(isRegistered[_user], "Target user profile not registered.");
        profiles[_user].reputationScore += _externalScore * int256(reputationWeights["externalOracle"]);
        emit ReputationScoreUpdated(_user, profiles[_user].reputationScore);
    }


    // --- Community & Interaction Functions ---

    /// @notice Creates a new community.
    /// @param _communityName The name of the community.
    /// @param _description A description of the community.
    function createCommunity(string memory _communityName, string memory _description)
        public
        whenNotPaused
        onlyRegisteredProfile
    {
        require(bytes(_communityName).length > 0 && bytes(_communityName).length <= 64, "Community name must be between 1 and 64 characters.");
        require(bytes(_description).length <= 256, "Community description must be at most 256 characters.");

        communityCount++;
        communities[communityCount] = Community({
            name: _communityName,
            description: _description,
            creator: msg.sender,
            creationTimestamp: block.timestamp,
            memberCount: 1, // Creator is the first member
            postCount: 0
        });
        communities[communityCount].members[msg.sender] = true; // Creator automatically joins

        emit CommunityCreated(communityCount, msg.sender, _communityName);
        emit CommunityJoined(communityCount, msg.sender);

        // Example: Community creation boosts influence
        profiles[msg.sender].influenceScore += 5;
        emit InfluenceScoreUpdated(msg.sender, profiles[msg.sender].influenceScore);
    }

    /// @notice Allows a user to join a community.
    /// @param _communityId The ID of the community to join.
    function joinCommunity(uint256 _communityId)
        public
        whenNotPaused
        onlyRegisteredProfile
        communityExists(_communityId)
    {
        require(!communities[_communityId].members[msg.sender], "Already a member of this community.");

        communities[_communityId].members[msg.sender] = true;
        communities[_communityId].memberCount++;
        emit CommunityJoined(_communityId, msg.sender);

        // Example: Joining a community increases influence
        profiles[msg.sender].influenceScore += 2;
        emit InfluenceScoreUpdated(msg.sender, profiles[msg.sender].influenceScore);
    }

    /// @notice Allows a user to leave a community.
    /// @param _communityId The ID of the community to leave.
    function leaveCommunity(uint256 _communityId)
        public
        whenNotPaused
        onlyRegisteredProfile
        communityExists(_communityId)
        communityMember(_communityId)
    {
        delete communities[_communityId].members[msg.sender];
        communities[_communityId].memberCount--;
        emit CommunityLeft(_communityId, msg.sender);

        // Example: Leaving a community might decrease influence slightly
        profiles[msg.sender].influenceScore -= 1;
        emit InfluenceScoreUpdated(msg.sender, profiles[msg.sender].influenceScore);
    }

    /// @notice Retrieves the list of members in a community.
    /// @param _communityId The ID of the community.
    /// @return An array of member addresses.
    function getCommunityMembers(uint256 _communityId)
        public
        view
        communityExists(_communityId)
        returns (address[] memory)
    {
        address[] memory membersArray = new address[](communities[_communityId].memberCount);
        uint256 index = 0;
        for (address memberAddress : communities[_communityId].members) {
            if (communities[_communityId].members[memberAddress]) {
                membersArray[index] = memberAddress;
                index++;
            }
        }
        return membersArray;
    }

    /// @notice Allows a community member to post content to the community.
    /// @param _communityId The ID of the community to post to.
    /// @param _contentUri URI pointing to the content of the post (IPFS, etc.).
    function postToCommunity(uint256 _communityId, string memory _contentUri)
        public
        whenNotPaused
        onlyRegisteredProfile
        communityExists(_communityId)
        communityMember(_communityId)
    {
        require(bytes(_contentUri).length > 0 && bytes(_contentUri).length <= 256, "Content URI must be between 1 and 256 characters.");

        Community storage community = communities[_communityId];
        community.postCount++;
        community.posts[community.postCount] = Post({
            author: msg.sender,
            contentUri: _contentUri,
            timestamp: block.timestamp
        });

        emit CommunityPostCreated(_communityId, msg.sender, community.postCount);

        // Example: Posting in a community increases influence and reputation slightly
        profiles[msg.sender].influenceScore += 3;
        profiles[msg.sender].reputationScore += int256(reputationWeights["communityActivity"]);
        emit InfluenceScoreUpdated(msg.sender, profiles[msg.sender].influenceScore);
        emit ReputationScoreUpdated(msg.sender, profiles[msg.sender].reputationScore);
    }


    // --- Governance & Administration Functions ---

    /// @notice Allows the contract owner to set the weight for a specific reputation metric.
    /// @param _metricName The name of the reputation metric (e.g., "endorsements", "reports").
    /// @param _weight The new weight to assign to the metric.
    function setReputationWeight(string memory _metricName, uint256 _weight)
        public
        onlyOwner
        whenNotPaused
    {
        require(bytes(_metricName).length > 0 && bytes(_metricName).length <= 32, "Metric name must be between 1 and 32 characters.");
        reputationWeights[_metricName] = _weight;
    }

    /// @notice Pauses the contract, preventing most state-changing functions from being called.
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, restoring normal functionality.
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Transfers ownership of the contract to a new address.
    /// @param _newOwner The address of the new owner.
    function transferOwnership(address _newOwner) public onlyOwner whenNotPaused {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    // --- Fallback and Receive (Optional - for demonstration, not strictly needed here) ---
    receive() external payable {}
    fallback() external payable {}
}
```