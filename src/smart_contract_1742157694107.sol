```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Game Guild (DAG Guild) - Smart Contract
 * @author Bard (Example Implementation)
 * @dev A smart contract for managing a decentralized autonomous game guild, incorporating advanced concepts like dynamic NFTs, on-chain reputation,
 *      skill-based roles, decentralized quest management, and guild-owned metaverse land management.
 *
 * **Outline & Function Summary:**
 *
 * **1. Membership Management:**
 *    - `joinGuild(string _username)`: Allows users to join the guild, minting a base Guild Member NFT.
 *    - `leaveGuild()`: Allows members to leave the guild, burning their Member NFT.
 *    - `setUsername(string _newUsername)`: Allows members to update their username.
 *    - `getMemberDetails(address _member)`: Returns details of a guild member (username, reputation, role, etc.).
 *    - `isGuildMember(address _account)`: Checks if an address is a guild member.
 *
 * **2. Dynamic NFT & Reputation System:**
 *    - `upgradeMemberNFT()`: Allows members to upgrade their Guild Member NFT based on reputation and achievements.
 *    - `increaseReputation(address _member, uint256 _amount)`:  Admin/Contract function to increase member reputation.
 *    - `decreaseReputation(address _member, uint256 _amount)`: Admin/Contract function to decrease member reputation.
 *    - `getMemberReputation(address _member)`: Returns the reputation score of a member.
 *    - `setReputationThresholdForUpgrade(uint256 _threshold)`: Admin function to set the reputation needed for NFT upgrade.
 *
 * **3. Skill-Based Roles & Role Management:**
 *    - `assignRole(address _member, Role _role)`: Guild Leader function to assign roles to members.
 *    - `removeRole(address _member)`: Guild Leader function to remove roles from members.
 *    - `getMemberRole(address _member)`: Returns the role of a member.
 *    - `getMembersInRole(Role _role)`: Returns a list of members in a specific role.
 *    - `defineNewRole(string _roleName)`: Guild Leader function to define a new custom role.
 *
 * **4. Decentralized Quest Management:**
 *    - `createQuest(string _questName, string _questDescription, uint256 _rewardTokenAmount, uint256 _rewardReputation, Role _requiredRole)`: Guild Leader function to create a new quest with requirements and rewards.
 *    - `submitQuestCompletion(uint256 _questId)`: Member function to submit proof of quest completion (simplified in this example, could be extended with IPFS hashes).
 *    - `approveQuestCompletion(uint256 _questId, address _member)`: Guild Leader/Role-based function to approve quest completion and distribute rewards.
 *    - `getQuestDetails(uint256 _questId)`: Returns details of a specific quest.
 *    - `getActiveQuests()`: Returns a list of active quests.
 *
 * **5. Guild Treasury & Token Management:**
 *    - `depositGuildTokens(uint256 _amount)`: Allows anyone to deposit guild tokens into the treasury.
 *    - `withdrawGuildTokens(address _recipient, uint256 _amount)`: Guild Leader function to withdraw tokens from the treasury (potentially with DAO voting in a real-world scenario).
 *    - `getGuildTreasuryBalance()`: Returns the current balance of guild tokens in the treasury.
 *    - `setGuildTokenAddress(address _tokenAddress)`: Admin function to set the address of the guild's ERC20 token.
 *
 * **6. Metaverse Land Management (Conceptual):**
 *    - `registerGuildLand(uint256 _landId, string _metaversePlatform)`: Guild Leader function to register guild-owned metaverse land (conceptual, platform-agnostic).
 *    - `getGuildLandDetails(uint256 _landId)`: Returns details of registered guild land.
 *    - `getGuildLandsByPlatform(string _metaversePlatform)`: Returns a list of guild lands on a specific metaverse platform.
 *
 * **7. Guild Leader & Admin Functions:**
 *    - `setGuildLeader(address _newLeader)`: Admin function to change the Guild Leader.
 *    - `getGuildLeader()`: Returns the current Guild Leader address.
 *
 * **8. Events:**
 *    - Emits events for key actions like joining, leaving, role assignments, quest creation, etc., for off-chain monitoring and integration.
 */

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DAGGuild is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Enums
    enum Role {
        MEMBER,
        OFFICER,
        STRATEGIST,
        RECRUITER,
        TREASURER,
        CUSTOM // For future custom roles
    }

    // Structs
    struct Member {
        string username;
        uint256 reputation;
        Role role;
        uint256 nftTier; // Tier of Guild Member NFT
        bool isActive;
    }

    struct Quest {
        uint256 questId;
        string questName;
        string questDescription;
        uint256 rewardTokenAmount;
        uint256 rewardReputation;
        Role requiredRole;
        bool isActive;
        mapping(address => bool) completionSubmitted; // Track submissions
        mapping(address => bool) completionApproved;   // Track approvals
    }

    // State Variables
    mapping(address => Member) public guildMembers;
    mapping(uint256 => Quest) public quests;
    Counters.Counter private _questCounter;
    address public guildTokenAddress; // Address of the Guild's ERC20 token
    uint256 public reputationThresholdForUpgrade = 100; // Reputation needed to upgrade NFT
    mapping(Role => string) public roleNames; // Map Role enum to string names
    mapping(string => Role) public roleNameToEnum; // Map role name string to Role enum
    Role[] public customRoles; // Array to store custom roles (beyond predefined)
    mapping(uint256 => string) public guildLands; // Land ID to metaverse platform (conceptual)
    Counters.Counter private _landCounter;


    // Events
    event GuildJoined(address indexed member, string username);
    event GuildLeft(address indexed member);
    event UsernameUpdated(address indexed member, string newUsername);
    event ReputationIncreased(address indexed member, uint256 amount, uint256 newReputation);
    event ReputationDecreased(address indexed member, uint256 amount, uint256 newReputation);
    event RoleAssigned(address indexed member, Role role);
    event RoleRemoved(address indexed member, Role role);
    event QuestCreated(uint256 questId, string questName, Role requiredRole);
    event QuestCompletionSubmitted(uint256 questId, address indexed member);
    event QuestCompletionApproved(uint256 questId, address indexed member);
    event GuildTokensDeposited(address depositor, uint256 amount);
    event GuildTokensWithdrawn(address recipient, uint256 amount, address withdrawnBy);
    event GuildLandRegistered(uint256 landId, string metaversePlatform);
    event GuildLeaderChanged(address indexed newLeader, address indexed previousLeader);
    event MemberNFTUpgraded(address indexed member, uint256 newTier);
    event CustomRoleDefined(Role role, string roleName);

    // Modifiers
    modifier onlyGuildLeader() {
        require(msg.sender == owner(), "Only guild leader can perform this action.");
        _;
    }

    modifier onlyGuildMember() {
        require(isGuildMember(msg.sender), "Only guild members can perform this action.");
        _;
    }

    modifier onlyRole(Role _role) {
        require(guildMembers[msg.sender].role == _role, "Insufficient role permissions.");
        _;
    }

    // Constructor
    constructor() ERC721("DAG Guild Member", "DAGMEMBER") {
        _setRoleNames(); // Initialize default role names
        _setGuildLeader(_msgSender()); // Initial guild leader is contract deployer
    }

    function _setRoleNames() private {
        roleNames[Role.MEMBER] = "Member";
        roleNames[Role.OFFICER] = "Officer";
        roleNames[Role.STRATEGIST] = "Strategist";
        roleNames[Role.RECRUITER] = "Recruiter";
        roleNames[Role.TREASURER] = "Treasurer";
        roleNames[Role.CUSTOM] = "Custom"; // Placeholder for custom roles
        roleNameToEnum["Member"] = Role.MEMBER;
        roleNameToEnum["Officer"] = Role.OFFICER;
        roleNameToEnum["Strategist"] = Role.STRATEGIST;
        roleNameToEnum["Recruiter"] = Role.RECRUITER;
        roleNameToEnum["Treasurer"] = Role.TREASURER;
        roleNameToEnum["Custom"] = Role.CUSTOM; // Placeholder
    }

    function _setGuildLeader(address _leader) private {
        _transferOwnership(_leader);
        emit GuildLeaderChanged(_leader, address(0)); // Emitting 0 for previous leader at contract creation.
    }

    function setGuildLeader(address _newLeader) public onlyGuildLeader {
        address previousLeader = owner();
        _transferOwnership(_newLeader);
        emit GuildLeaderChanged(_newLeader, previousLeader);
    }

    function getGuildLeader() public view onlyGuildLeader returns (address) {
        return owner();
    }

    // 1. Membership Management
    function joinGuild(string memory _username) public {
        require(!isGuildMember(msg.sender), "Already a guild member.");
        guildMembers[msg.sender] = Member({
            username: _username,
            reputation: 0,
            role: Role.MEMBER,
            nftTier: 1, // Base tier upon joining
            isActive: true
        });
        _mint(msg.sender, totalSupply() + 1); // Mint a Guild Member NFT (tokenId is auto-incremented)
        _setTokenURI(totalSupply(), string(abi.encodePacked("ipfs://baseGuildMemberMetadata/", (totalSupply()).toString()))); // Example base metadata URI
        emit GuildJoined(msg.sender, _username);
    }

    function leaveGuild() public onlyGuildMember {
        require(guildMembers[msg.sender].isActive, "Not an active guild member.");
        guildMembers[msg.sender].isActive = false; // Mark as inactive instead of deleting for record keeping
        _burn(ERC721.tokenOfOwnerByIndex(msg.sender, 0)); // Burn the member's NFT (simplification - handling multiple NFTs could be more complex)
        emit GuildLeft(msg.sender);
    }

    function setUsername(string memory _newUsername) public onlyGuildMember {
        guildMembers[msg.sender].username = _newUsername;
        emit UsernameUpdated(msg.sender, _newUsername);
    }

    function getMemberDetails(address _member) public view returns (Member memory) {
        require(isGuildMember(_member), "Not a guild member.");
        return guildMembers[_member];
    }

    function isGuildMember(address _account) public view returns (bool) {
        return guildMembers[_account].isActive;
    }

    // 2. Dynamic NFT & Reputation System
    function upgradeMemberNFT() public onlyGuildMember {
        require(guildMembers[msg.sender].reputation >= reputationThresholdForUpgrade, "Insufficient reputation to upgrade NFT.");
        uint256 currentTier = guildMembers[msg.sender].nftTier;
        uint256 nextTier = currentTier + 1;
        guildMembers[msg.sender].nftTier = nextTier;

        // Burn the old NFT and mint a new one with upgraded metadata
        uint256 tokenIdToBurn = ERC721.tokenOfOwnerByIndex(msg.sender, 0);
        _burn(tokenIdToBurn);
        _mint(msg.sender, totalSupply() + 1); // Mint a new NFT with a new tokenId
        _setTokenURI(totalSupply(), string(abi.encodePacked("ipfs://upgradedGuildMemberMetadata/tier", nextTier.toString(), "/", (totalSupply()).toString()))); // Example upgraded metadata URI
        emit MemberNFTUpgraded(msg.sender, nextTier);
    }

    function increaseReputation(address _member, uint256 _amount) public onlyGuildLeader {
        require(isGuildMember(_member), "Not a guild member.");
        guildMembers[_member].reputation += _amount;
        emit ReputationIncreased(_member, _amount, guildMembers[_member].reputation);
    }

    function decreaseReputation(address _member, uint256 _amount) public onlyGuildLeader {
        require(isGuildMember(_member), "Not a guild member.");
        guildMembers[_member].reputation -= _amount;
        emit ReputationDecreased(_member, _amount, guildMembers[_member].reputation);
    }

    function getMemberReputation(address _member) public view returns (uint256) {
        require(isGuildMember(_member), "Not a guild member.");
        return guildMembers[_member].reputation;
    }

    function setReputationThresholdForUpgrade(uint256 _threshold) public onlyGuildLeader {
        reputationThresholdForUpgrade = _threshold;
    }

    // 3. Skill-Based Roles & Role Management
    function assignRole(address _member, Role _role) public onlyGuildLeader {
        require(isGuildMember(_member), "Not a guild member.");
        guildMembers[_member].role = _role;
        emit RoleAssigned(_member, _role);
    }

    function removeRole(address _member) public onlyGuildLeader {
        require(isGuildMember(_member), "Not a guild member.");
        guildMembers[_member].role = Role.MEMBER; // Default back to MEMBER role
        emit RoleRemoved(_member, guildMembers[_member].role);
    }

    function getMemberRole(address _member) public view returns (Role) {
        require(isGuildMember(_member), "Not a guild member.");
        return guildMembers[_member].role;
    }

    function getMembersInRole(Role _role) public view returns (address[] memory) {
        address[] memory membersWithRole = new address[](totalSupply()); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= totalSupply(); i++) { // Iterate through tokenIds (member NFTs)
            address memberAddress = ownerOf(i);
            if (guildMembers[memberAddress].isActive && guildMembers[memberAddress].role == _role) {
                membersWithRole[count] = memberAddress;
                count++;
            }
        }
        // Resize array to actual count
        address[] memory result = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = membersWithRole[i];
        }
        return result;
    }

    function defineNewRole(string memory _roleName) public onlyGuildLeader {
        require(bytes(_roleName).length > 0, "Role name cannot be empty.");
        require(roleNameToEnum[_roleName] == Role.CUSTOM, "Role name already exists or is a reserved role."); // Basic check to avoid duplicates and reserved names. More robust checks can be added.

        Role newCustomRole = Role(uint256(Role.CUSTOM) + customRoles.length + 1); // Assign a new enum value dynamically
        roleNames[newCustomRole] = _roleName;
        roleNameToEnum[_roleName] = newCustomRole;
        customRoles.push(newCustomRole);

        emit CustomRoleDefined(newCustomRole, _roleName);
    }


    // 4. Decentralized Quest Management
    function createQuest(
        string memory _questName,
        string memory _questDescription,
        uint256 _rewardTokenAmount,
        uint256 _rewardReputation,
        Role _requiredRole
    ) public onlyGuildLeader {
        _questCounter.increment();
        uint256 questId = _questCounter.current();
        quests[questId] = Quest({
            questId: questId,
            questName: _questName,
            questDescription: _questDescription,
            rewardTokenAmount: _rewardTokenAmount,
            rewardReputation: _rewardReputation,
            requiredRole: _requiredRole,
            isActive: true,
            completionSubmitted: mapping(address => bool)(),
            completionApproved: mapping(address => bool)()
        });
        emit QuestCreated(questId, _questName, _requiredRole);
    }

    function submitQuestCompletion(uint256 _questId) public onlyGuildMember {
        require(quests[_questId].isActive, "Quest is not active.");
        require(!quests[_questId].completionSubmitted[msg.sender], "Quest completion already submitted.");
        require(guildMembers[msg.sender].role == quests[_questId].requiredRole || quests[_questId].requiredRole == Role.MEMBER, "Incorrect role for quest."); // Example: Allow MEMBER role to also participate if required role is MEMBER
        quests[_questId].completionSubmitted[msg.sender] = true;
        emit QuestCompletionSubmitted(_questId, msg.sender);
    }

    function approveQuestCompletion(uint256 _questId, address _member) public onlyGuildLeader { // Guild leader approves, can be role-based or DAO in future
        require(quests[_questId].isActive, "Quest is not active.");
        require(quests[_questId].completionSubmitted[_member], "Quest completion not submitted by this member.");
        require(!quests[_questId].completionApproved[_member], "Quest completion already approved for this member.");

        quests[_questId].completionApproved[_member] = true;

        // Reward member
        if (quests[_questId].rewardTokenAmount > 0) {
            IERC20 guildToken = IERC20(guildTokenAddress);
            require(guildToken.balanceOf(address(this)) >= quests[_questId].rewardTokenAmount, "Insufficient guild tokens in treasury for reward.");
            guildToken.transfer(_member, quests[_questId].rewardTokenAmount);
        }
        increaseReputation(_member, quests[_questId].rewardReputation);

        emit QuestCompletionApproved(_questId, _member);
    }

    function getQuestDetails(uint256 _questId) public view returns (Quest memory) {
        require(quests[_questId].isActive, "Quest is not active or does not exist.");
        return quests[_questId];
    }

    function getActiveQuests() public view returns (Quest[] memory) {
        uint256 activeQuestCount = 0;
        for (uint256 i = 1; i <= _questCounter.current(); i++) {
            if (quests[i].isActive) {
                activeQuestCount++;
            }
        }
        Quest[] memory activeQuests = new Quest[](activeQuestCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _questCounter.current(); i++) {
            if (quests[i].isActive) {
                activeQuests[index] = quests[i];
                index++;
            }
        }
        return activeQuests;
    }

    // 5. Guild Treasury & Token Management
    function depositGuildTokens(uint256 _amount) public {
        require(guildTokenAddress != address(0), "Guild token address not set.");
        IERC20 guildToken = IERC20(guildTokenAddress);
        guildToken.transferFrom(msg.sender, address(this), _amount);
        emit GuildTokensDeposited(msg.sender, _amount);
    }

    function withdrawGuildTokens(address _recipient, uint256 _amount) public onlyGuildLeader {
        require(guildTokenAddress != address(0), "Guild token address not set.");
        IERC20 guildToken = IERC20(guildTokenAddress);
        guildToken.transfer(_recipient, _amount);
        emit GuildTokensWithdrawn(_recipient, _amount, msg.sender);
    }

    function getGuildTreasuryBalance() public view returns (uint256) {
        if (guildTokenAddress == address(0)) {
            return 0;
        }
        IERC20 guildToken = IERC20(guildTokenAddress);
        return guildToken.balanceOf(address(this));
    }

    function setGuildTokenAddress(address _tokenAddress) public onlyGuildLeader {
        guildTokenAddress = _tokenAddress;
    }

    // 6. Metaverse Land Management (Conceptual)
    function registerGuildLand(uint256 _landId, string memory _metaversePlatform) public onlyGuildLeader {
        _landCounter.increment();
        uint256 landId = _landCounter.current(); // Using internal counter for land IDs within the contract, not related to external metaverse land IDs necessarily
        guildLands[landId] = _metaversePlatform;
        emit GuildLandRegistered(landId, _metaversePlatform);
    }

    function getGuildLandDetails(uint256 _landId) public view returns (string memory) {
        require(bytes(guildLands[_landId]).length > 0, "Guild land not registered.");
        return guildLands[_landId];
    }

    function getGuildLandsByPlatform(string memory _metaversePlatform) public view returns (uint256[] memory) {
        uint256 platformLandCount = 0;
        for (uint256 i = 1; i <= _landCounter.current(); i++) {
            if (keccak256(bytes(guildLands[i])) == keccak256(bytes(_metaversePlatform))) {
                platformLandCount++;
            }
        }
        uint256[] memory platformLands = new uint256[](platformLandCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _landCounter.current(); i++) {
            if (keccak256(bytes(guildLands[i])) == keccak256(bytes(_metaversePlatform))) {
                platformLands[index] = i;
                index++;
            }
        }
        return platformLands;
    }

    // Function to retrieve role name from enum for UI display
    function getRoleName(Role _role) public view returns (string memory) {
        return roleNames[_role];
    }

    // Function to get enum from role name string for UI input handling
    function getRoleEnumFromName(string memory _roleName) public view returns (Role) {
        return roleNameToEnum[_roleName];
    }

    // Fallback function to receive ETH (if needed for guild operations - consider carefully for security)
    receive() external payable {}
    fallback() external payable {}
}
```