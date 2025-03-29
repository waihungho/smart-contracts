```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Achievement System with On-Chain Governance
 * @author Bard (AI Assistant)
 * @dev This contract implements a dynamic reputation and achievement system,
 * coupled with a simple on-chain governance mechanism for community-driven evolution.
 * It's designed to be adaptable and engaging, offering a framework for decentralized
 * communities, platforms, or games to recognize and reward user contributions and participation.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core Reputation System:**
 *    - `earnReputation(uint256 points)`: Allows users to earn reputation points.
 *    - `loseReputation(uint256 points)`: Allows admins or specific mechanisms to reduce reputation points.
 *    - `getReputation(address user)`: Retrieves the reputation points of a user.
 *    - `getLevel(address user)`: Calculates the user's level based on reputation points.
 *    - `setReputationThresholdForLevel(uint256 level, uint256 threshold)` (Admin): Sets the reputation points required for each level.
 *    - `getReputationThresholdForLevel(uint256 level)`: Retrieves the reputation threshold for a specific level.
 *    - `reputationDecay(address user)` (Admin/Scheduled): Implements a reputation decay mechanism over time.
 *
 * **2. Achievement System (NFT-based):**
 *    - `mintAchievement(address recipient, string memory achievementName, string memory ipfsMetadataHash)` (Admin): Mints a unique achievement NFT to a user.
 *    - `transferAchievement(address from, address to, uint256 tokenId)`: Allows users to transfer achievement NFTs (standard ERC721 function).
 *    - `getAchievementCount(address user)`: Returns the number of achievements a user holds.
 *    - `getAchievementTokenIds(address user)`: Returns an array of achievement token IDs owned by a user.
 *    - `achievementExists(uint256 tokenId)`: Checks if an achievement token ID exists.
 *
 * **3. User Profile & Customization:**
 *    - `setUserProfileName(string memory name)`: Allows users to set a public profile name associated with their address.
 *    - `getUserProfileName(address user)`: Retrieves the profile name of a user.
 *
 * **4. On-Chain Governance (Simple Proposal & Voting):**
 *    - `createGovernanceProposal(string memory description, bytes memory data)`: Allows users with sufficient reputation to create governance proposals.
 *    - `voteOnProposal(uint256 proposalId, bool support)`: Allows users to vote on active governance proposals.
 *    - `executeProposal(uint256 proposalId)` (Admin/Timelock): Executes a passed governance proposal.
 *    - `getProposalState(uint256 proposalId)`: Retrieves the current state of a governance proposal.
 *    - `getProposalVoteCount(uint256 proposalId, bool support)`: Retrieves the vote count for a proposal (support or against).
 *    - `getProposalDetails(uint256 proposalId)`: Retrieves detailed information about a specific proposal.
 *
 * **5. Utility & Admin Functions:**
 *    - `isAdmin(address user)`: Checks if an address is an admin.
 *    - `addAdmin(address newAdmin)` (Admin): Adds a new admin address.
 *    - `removeAdmin(address adminToRemove)` (Admin): Removes an admin address.
 *    - `pauseContract()` (Admin): Pauses certain functionalities of the contract.
 *    - `unpauseContract()` (Admin): Resumes paused functionalities.
 *    - `isPaused()`: Checks if the contract is currently paused.
 *
 * **Advanced Concepts & Creativity:**
 * - **Dynamic Reputation Levels:** Reputation thresholds for levels can be adjusted through governance.
 * - **Achievement NFTs:**  Achievements are represented as NFTs, making them transferable and potentially interoperable.
 * - **Simple On-Chain Governance:**  Allows the community to participate in the evolution of the reputation and achievement system itself.
 * - **Profile Customization:**  Basic user profiles enhance community interaction.
 * - **Reputation Decay:**  Introduces dynamism and encourages continued participation.
 * - **Governance Proposals with Data Payload:** Proposals can include arbitrary data to execute complex contract interactions (e.g., changing parameters, upgrading contracts - simplified for this example).
 *
 * **Note:** This contract is a conceptual framework and would require further development and security audits for production use.  Governance is simplified for demonstration and would need more robust features in a real-world scenario.
 */
contract DynamicReputationAchievementSystem {
    // --- State Variables ---

    // Admin management
    address public admin;
    mapping(address => bool) public isAdminUser;

    // Reputation system
    mapping(address => uint256) public userReputation;
    mapping(uint256 => uint256) public levelThresholds; // Level => Reputation Threshold
    uint256 public constant MAX_LEVEL = 100; // Example max level

    // Achievement system (NFT-like, simplified ERC721 interface)
    mapping(uint256 => address) public achievementOwner; // TokenId => Owner Address
    uint256 public achievementSupply = 0;
    mapping(address => uint256[]) public userAchievements; // User Address => Array of TokenIds
    mapping(uint256 => string) public achievementMetadata; // TokenId => IPFS Metadata Hash

    // User profiles
    mapping(address => string) public userProfileNames;

    // Governance system
    struct Proposal {
        string description;
        bytes data; // Data payload for execution
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        ProposalState state;
        address proposer;
    }
    enum ProposalState { Active, Pending, Executed, Rejected }
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount = 0;
    uint256 public votingPeriod = 7 days; // Example voting period
    uint256 public minReputationForProposal = 1000; // Example reputation needed to propose

    bool public paused = false;

    // --- Events ---
    event ReputationEarned(address user, uint256 points, uint256 newReputation);
    event ReputationLost(address user, uint256 points, uint256 newReputation);
    event LevelUp(address user, uint256 newLevel);
    event AchievementMinted(address recipient, uint256 tokenId, string achievementName, string ipfsMetadataHash);
    event AchievementTransferred(address from, address to, uint256 tokenId);
    event ProfileNameSet(address user, string name);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event AdminAdded(address newAdmin);
    event AdminRemoved(address removedAdmin);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin || isAdminUser[msg.sender], "Only admin can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenContractNotPaused() { // For internal use when pausing some but not all functions
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validProposal(uint256 proposalId) {
        require(proposals[proposalId].proposer != address(0), "Invalid proposal ID.");
        _;
    }

    modifier onlyProposer(uint256 proposalId) {
        require(proposals[proposalId].proposer == msg.sender, "Only proposer can call this function.");
        _;
    }

    modifier onlyLevelThresholdAdmin() { // Example: Separate admin role for level thresholds
        require(msg.sender == admin || isAdminUser[msg.sender], "Only level threshold admin can call this.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
        isAdminUser[msg.sender] = true;
        // Initialize level thresholds (example)
        levelThresholds[1] = 100;
        levelThresholds[2] = 500;
        levelThresholds[3] = 1500;
        // ... more levels can be added via setReputationThresholdForLevel
    }

    // --- 1. Core Reputation System ---

    /// @notice Allows users to earn reputation points.
    /// @param points The number of reputation points to earn.
    function earnReputation(uint256 points) external whenContractNotPaused {
        require(points > 0, "Points to earn must be positive.");
        userReputation[msg.sender] += points;
        emit ReputationEarned(msg.sender, points, userReputation[msg.sender]);
        _checkLevelUp(msg.sender);
    }

    /// @notice Allows admins to reduce reputation points from a user.
    /// @param user The address of the user to lose reputation.
    /// @param points The number of reputation points to lose.
    function loseReputation(address user, uint256 points) external onlyAdmin whenContractNotPaused {
        require(points > 0, "Points to lose must be positive.");
        require(userReputation[user] >= points, "User does not have enough reputation to lose that many points.");
        userReputation[user] -= points;
        emit ReputationLost(user, points, userReputation[user]);
        _checkLevelUp(user); // Level might decrease
    }

    /// @notice Retrieves the reputation points of a user.
    /// @param user The address of the user.
    /// @return The reputation points of the user.
    function getReputation(address user) external view returns (uint256) {
        return userReputation[user];
    }

    /// @notice Calculates the user's level based on their reputation points.
    /// @param user The address of the user.
    /// @return The level of the user.
    function getLevel(address user) public view returns (uint256) {
        uint256 reputation = userReputation[user];
        for (uint256 level = MAX_LEVEL; level >= 1; level--) {
            if (reputation >= levelThresholds[level]) {
                return level;
            }
        }
        return 0; // Level 0 if reputation is below level 1 threshold
    }

    function _checkLevelUp(address user) private {
        uint256 currentLevel = getLevel(user);
        uint256 previousLevel = getLevel(user) -1; // Assuming level starts from 1

        if (previousLevel < currentLevel ) {
            emit LevelUp(user, currentLevel);
            // Potentially trigger other actions on level up (e.g., reward, access)
        }
    }

    /// @notice Sets the reputation points required for a specific level.
    /// @param level The level number.
    /// @param threshold The reputation points required for that level.
    function setReputationThresholdForLevel(uint256 level, uint256 threshold) external onlyLevelThresholdAdmin whenContractNotPaused {
        require(level > 0 && level <= MAX_LEVEL, "Invalid level.");
        require(threshold > 0, "Threshold must be positive.");
        levelThresholds[level] = threshold;
    }

    /// @notice Retrieves the reputation threshold for a specific level.
    /// @param level The level number.
    /// @return The reputation threshold for the level.
    function getReputationThresholdForLevel(uint256 level) external view returns (uint256) {
        require(level > 0 && level <= MAX_LEVEL, "Invalid level.");
        return levelThresholds[level];
    }

    /// @notice Implements a reputation decay mechanism (e.g., called periodically by admin or off-chain service).
    /// @param user The address of the user whose reputation should decay.
    function reputationDecay(address user) external onlyAdmin whenContractNotPaused {
        uint256 decayAmount = userReputation[user] / 10; // Example: 10% decay
        if (decayAmount > 0) {
            userReputation[user] -= decayAmount;
            emit ReputationLost(user, decayAmount, userReputation[user]);
            _checkLevelUp(user); // Level might decrease
        }
    }

    // --- 2. Achievement System (NFT-based) ---

    /// @notice Mints a unique achievement NFT to a user.
    /// @param recipient The address to receive the achievement NFT.
    /// @param achievementName A descriptive name for the achievement.
    /// @param ipfsMetadataHash The IPFS hash pointing to the achievement's metadata.
    function mintAchievement(address recipient, string memory achievementName, string memory ipfsMetadataHash) external onlyAdmin whenContractNotPaused {
        require(recipient != address(0), "Invalid recipient address.");
        require(bytes(achievementName).length > 0, "Achievement name cannot be empty.");
        require(bytes(ipfsMetadataHash).length > 0, "IPFS metadata hash cannot be empty.");

        achievementSupply++;
        uint256 tokenId = achievementSupply;
        achievementOwner[tokenId] = recipient;
        userAchievements[recipient].push(tokenId);
        achievementMetadata[tokenId] = ipfsMetadataHash;

        emit AchievementMinted(recipient, tokenId, achievementName, ipfsMetadataHash);
    }

    /// @notice Allows users to transfer achievement NFTs (standard ERC721 function - simplified).
    /// @param from The current owner of the achievement NFT.
    /// @param to The address to transfer the achievement NFT to.
    /// @param tokenId The ID of the achievement NFT to transfer.
    function transferAchievement(address from, address to, uint256 tokenId) external whenContractNotPaused {
        require(msg.sender == from, "You are not the owner of this achievement.");
        require(to != address(0), "Invalid recipient address.");
        require(achievementOwner[tokenId] == from, "Achievement does not exist or you are not the owner.");

        achievementOwner[tokenId] = to;
        // Remove from sender's list and add to receiver's list (less efficient, could be optimized for production)
        _removeAchievementFromUser(from, tokenId);
        userAchievements[to].push(tokenId);

        emit AchievementTransferred(from, to, tokenId);
    }

    function _removeAchievementFromUser(address user, uint256 tokenId) private {
        uint256[] storage achievements = userAchievements[user];
        for (uint256 i = 0; i < achievements.length; i++) {
            if (achievements[i] == tokenId) {
                achievements[i] = achievements[achievements.length - 1];
                achievements.pop();
                return;
            }
        }
    }

    /// @notice Returns the number of achievements a user holds.
    /// @param user The address of the user.
    /// @return The number of achievements the user holds.
    function getAchievementCount(address user) external view returns (uint256) {
        return userAchievements[user].length;
    }

    /// @notice Returns an array of achievement token IDs owned by a user.
    /// @param user The address of the user.
    /// @return An array of achievement token IDs.
    function getAchievementTokenIds(address user) external view returns (uint256[] memory) {
        return userAchievements[user];
    }

    /// @notice Checks if an achievement token ID exists.
    /// @param tokenId The ID of the achievement token.
    /// @return True if the achievement exists, false otherwise.
    function achievementExists(uint256 tokenId) external view returns (bool) {
        return achievementOwner[tokenId] != address(0);
    }

    // --- 3. User Profile & Customization ---

    /// @notice Allows users to set a public profile name associated with their address.
    /// @param name The profile name to set.
    function setUserProfileName(string memory name) external whenContractNotPaused {
        userProfileNames[msg.sender] = name;
        emit ProfileNameSet(msg.sender, name);
    }

    /// @notice Retrieves the profile name of a user.
    /// @param user The address of the user.
    /// @return The profile name of the user.
    function getUserProfileName(address user) external view returns (string memory) {
        return userProfileNames[user];
    }

    // --- 4. On-Chain Governance (Simple Proposal & Voting) ---

    /// @notice Allows users with sufficient reputation to create governance proposals.
    /// @param description A description of the governance proposal.
    /// @param data Data payload to be executed if proposal passes.
    function createGovernanceProposal(string memory description, bytes memory data) external whenContractNotPaused {
        require(bytes(description).length > 0, "Proposal description cannot be empty.");
        require(userReputation[msg.sender] >= minReputationForProposal, "Insufficient reputation to create proposal.");

        proposalCount++;
        uint256 proposalId = proposalCount;
        proposals[proposalId] = Proposal({
            description: description,
            data: data,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            state: ProposalState.Active,
            proposer: msg.sender
        });

        emit GovernanceProposalCreated(proposalId, msg.sender, description);
    }

    /// @notice Allows users to vote on active governance proposals.
    /// @param proposalId The ID of the proposal to vote on.
    /// @param support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 proposalId, bool support) external whenContractNotPaused validProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active.");
        require(block.timestamp <= proposal.endTime, "Voting period has ended.");

        if (support) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit GovernanceVoteCast(proposalId, msg.sender, support);
    }

    /// @notice Executes a passed governance proposal (Admin/Timelock - simplified for demo).
    /// @param proposalId The ID of the proposal to execute.
    function executeProposal(uint256 proposalId) external onlyAdmin whenContractNotPaused validProposal(proposalId) {
        Proposal storage proposal = proposals[proposalId];
        require(proposal.state == ProposalState.Active, "Proposal is not active.");
        require(block.timestamp > proposal.endTime, "Voting period has not ended."); // Ensure voting period is over
        require(!proposal.executed, "Proposal already executed.");

        if (proposal.votesFor > proposal.votesAgainst) {
            proposal.state = ProposalState.Executed;
            proposal.executed = true;
            // Execute the proposal logic here based on proposal.data
            // Example: Assume data is a function selector and parameters
            (bool success, ) = address(this).call(proposal.data); // Very basic and insecure in real-world - needs careful design
            require(success, "Proposal execution failed."); // Handle execution failures properly
            emit GovernanceProposalExecuted(proposalId);
        } else {
            proposal.state = ProposalState.Rejected;
        }
    }

    /// @notice Retrieves the current state of a governance proposal.
    /// @param proposalId The ID of the proposal.
    /// @return The state of the proposal (Active, Pending, Executed, Rejected).
    function getProposalState(uint256 proposalId) external view validProposal(proposalId) returns (ProposalState) {
        return proposals[proposalId].state;
    }

    /// @notice Retrieves the vote count for a proposal (support or against).
    /// @param proposalId The ID of the proposal.
    /// @param support True to get 'for' votes, false to get 'against' votes.
    /// @return The vote count.
    function getProposalVoteCount(uint256 proposalId, bool support) external view validProposal(proposalId) returns (uint256) {
        if (support) {
            return proposals[proposalId].votesFor;
        } else {
            return proposals[proposalId].votesAgainst;
        }
    }

    /// @notice Retrieves detailed information about a specific proposal.
    /// @param proposalId The ID of the proposal.
    /// @return Proposal struct containing proposal details.
    function getProposalDetails(uint256 proposalId) external view validProposal(proposalId) returns (Proposal memory) {
        return proposals[proposalId];
    }


    // --- 5. Utility & Admin Functions ---

    /// @notice Checks if an address is an admin.
    /// @param user The address to check.
    /// @return True if the address is an admin, false otherwise.
    function isAdmin(address user) external view returns (bool) {
        return (user == admin || isAdminUser[user]);
    }

    /// @notice Adds a new admin address.
    /// @param newAdmin The address to add as admin.
    function addAdmin(address newAdmin) external onlyAdmin whenContractNotPaused {
        require(newAdmin != address(0), "Invalid admin address.");
        isAdminUser[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    /// @notice Removes an admin address.
    /// @param adminToRemove The address to remove from admin status.
    function removeAdmin(address adminToRemove) external onlyAdmin whenContractNotPaused {
        require(adminToRemove != admin, "Cannot remove the primary admin.");
        isAdminUser[adminToRemove] = false;
        emit AdminRemoved(adminToRemove);
    }

    /// @notice Pauses certain functionalities of the contract (e.g., reputation earning, minting).
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Resumes paused functionalities.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isPaused() external view returns (bool) {
        return paused;
    }
}
```