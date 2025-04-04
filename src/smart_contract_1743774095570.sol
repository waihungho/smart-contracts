```solidity
/**
 * @title Dynamic Digital Identity & Reputation System (DID-Rep)
 * @author Bard (AI Assistant)
 * @dev A Smart Contract for managing decentralized digital identities and on-chain reputation.
 * It allows users to create, manage, and evolve their digital identities, and build reputation through various on-chain activities and interactions.
 * This contract introduces concepts like identity levels, reputation scores, verifiable achievements, dynamic profiles, and community endorsements,
 * going beyond simple token transfers and exploring advanced functionalities in the DID and reputation space.
 *
 * **Outline:**
 *
 * **1. Identity Management:**
 *    - `createIdentity()`:  Allows a user to create a unique digital identity.
 *    - `getIdentityOwner(identityId)`: Retrieves the owner of a specific identity.
 *    - `updateIdentityProfile(identityId, profileData)`:  Allows identity owners to update their profile information (off-chain data).
 *    - `getIdentityProfile(identityId)`: Retrieves the profile data associated with an identity.
 *    - `transferIdentityOwnership(identityId, newOwner)`: Allows transferring ownership of an identity.
 *    - `resolveIdentity(ownerAddress)`: Resolves an identity ID from an owner address (optional).
 *
 * **2. Reputation System:**
 *    - `increaseReputation(identityId, amount)`:  Increases the reputation score of an identity. (Admin/Contract controlled rewards)
 *    - `decreaseReputation(identityId, amount)`: Decreases the reputation score of an identity. (Admin/Contract controlled penalties)
 *    - `getReputationScore(identityId)`: Retrieves the reputation score of an identity.
 *    - `getLevelFromReputation(reputationScore)`:  Determines the identity level based on the reputation score.
 *    - `getIdentityLevel(identityId)`:  Retrieves the level of an identity based on reputation.
 *
 * **3. Verifiable Achievements (Badges):**
 *    - `issueAchievement(identityId, achievementName, achievementData)`: Issues a verifiable achievement to an identity. (Admin/Issuer role)
 *    - `revokeAchievement(identityId, achievementName)`: Revokes a previously issued achievement. (Admin/Issuer role)
 *    - `getAchievements(identityId)`: Retrieves a list of achievements earned by an identity.
 *    - `isAchievementValid(identityId, achievementName)`: Checks if an achievement is valid for an identity.
 *
 * **4. Dynamic Identity Features:**
 *    - `setIdentityStatus(identityId, statusMessage)`: Allows identity owners to set a status message for their identity.
 *    - `getIdentityStatus(identityId)`: Retrieves the current status message of an identity.
 *    - `endorseIdentity(endorsingIdentityId, endorsedIdentityId)`: Allows one identity to endorse another, contributing to reputation. (Community driven)
 *    - `getEndorsementCount(identityId)`: Retrieves the number of endorsements received by an identity.
 *
 * **5. Contract Administration & Utility:**
 *    - `setReputationThresholds(levelThresholds)`:  Sets the reputation score thresholds for different identity levels. (Admin)
 *    - `getReputationThresholds()`: Retrieves the current reputation level thresholds.
 *    - `pauseContract()`: Pauses the contract, disabling most functions. (Admin - Emergency stop)
 *    - `unpauseContract()`: Resumes contract functionality. (Admin)
 *    - `isContractPaused()`: Checks if the contract is currently paused.
 *    - `withdrawContractBalance()`: Allows the contract owner to withdraw any accumulated balance. (Admin - if contract collects fees)
 *
 * **Function Summary:**
 *
 * **Identity Management:**
 * - `createIdentity()`: Creates a new digital identity for the caller.
 * - `getIdentityOwner(identityId)`: Returns the address that owns the given identity ID.
 * - `updateIdentityProfile(identityId, profileData)`: Updates the off-chain profile data associated with an identity.
 * - `getIdentityProfile(identityId)`: Retrieves the off-chain profile data for a given identity ID.
 * - `transferIdentityOwnership(identityId, newOwner)`: Transfers ownership of an identity to a new address.
 * - `resolveIdentity(ownerAddress)`: (Optional) Returns the identity ID associated with a given address.
 *
 * **Reputation System:**
 * - `increaseReputation(identityId, amount)`: Increases the reputation score of an identity (admin/contract controlled).
 * - `decreaseReputation(identityId, amount)`: Decreases the reputation score of an identity (admin/contract controlled).
 * - `getReputationScore(identityId)`: Returns the current reputation score of an identity.
 * - `getLevelFromReputation(reputationScore)`: Calculates the identity level based on a reputation score.
 * - `getIdentityLevel(identityId)`: Returns the current level of an identity based on its reputation.
 *
 * **Verifiable Achievements (Badges):**
 * - `issueAchievement(identityId, achievementName, achievementData)`: Issues a new achievement to an identity (admin/issuer role).
 * - `revokeAchievement(identityId, achievementName)`: Revokes an achievement from an identity (admin/issuer role).
 * - `getAchievements(identityId)`: Returns a list of achievements earned by an identity.
 * - `isAchievementValid(identityId, achievementName)`: Checks if a specific achievement is valid for an identity.
 *
 * **Dynamic Identity Features:**
 * - `setIdentityStatus(identityId, statusMessage)`: Sets a status message for an identity.
 * - `getIdentityStatus(identityId)`: Retrieves the status message of an identity.
 * - `endorseIdentity(endorsingIdentityId, endorsedIdentityId)`: Allows identities to endorse each other, increasing reputation.
 * - `getEndorsementCount(identityId)`: Returns the number of endorsements received by an identity.
 *
 * **Contract Administration & Utility:**
 * - `setReputationThresholds(levelThresholds)`: Sets the reputation score thresholds for identity levels (admin).
 * - `getReputationThresholds()`: Returns the current reputation level thresholds.
 * - `pauseContract()`: Pauses the contract functionality (admin - emergency stop).
 * - `unpauseContract()`: Resumes contract functionality (admin).
 * - `isContractPaused()`: Returns whether the contract is currently paused.
 * - `withdrawContractBalance()`: Allows the contract owner to withdraw contract balance (admin).
 */
pragma solidity ^0.8.0;

contract DIDReputationSystem {
    // --- State Variables ---

    address public owner;
    uint256 public nextIdentityId;
    bool public paused;

    mapping(uint256 => address) public identityOwners; // Identity ID => Owner Address
    mapping(uint256 => string) public identityProfiles; // Identity ID => Profile Data (off-chain URI or JSON string)
    mapping(uint256 => uint256) public reputationScores; // Identity ID => Reputation Score
    mapping(uint256 => string) public identityStatuses; // Identity ID => Status Message
    mapping(uint256 => mapping(string => bool)) public identityAchievements; // Identity ID => (Achievement Name => Is Valid)
    mapping(uint256 => uint256) public endorsementCounts; // Identity ID => Endorsement Count
    mapping(uint256 => string[]) public identityAchievementList; // Identity ID => List of achievement names

    uint256[] public reputationThresholds; // Array of reputation scores for level progression

    // --- Events ---

    event IdentityCreated(uint256 identityId, address owner);
    event ProfileUpdated(uint256 identityId);
    event OwnershipTransferred(uint256 identityId, address oldOwner, address newOwner);
    event ReputationIncreased(uint256 identityId, uint256 amount, uint256 newScore);
    event ReputationDecreased(uint256 identityId, uint256 amount, uint256 newScore);
    event AchievementIssued(uint256 identityId, string achievementName, string achievementData);
    event AchievementRevoked(uint256 identityId, string achievementName);
    event StatusUpdated(uint256 identityId, string statusMessage);
    event IdentityEndorsed(uint256 endorsingIdentityId, uint256 endorsedIdentityId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ReputationThresholdsUpdated(uint256[] newThresholds);
    event BalanceWithdrawn(address admin, uint256 amount);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function.");
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

    modifier identityExists(uint256 identityId) {
        require(identityOwners[identityId] != address(0), "Identity does not exist.");
        _;
    }

    modifier onlyIdentityOwner(uint256 identityId) {
        require(identityOwners[identityId] == msg.sender, "You are not the owner of this identity.");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        nextIdentityId = 1; // Start identity IDs from 1
        paused = false;

        // Default reputation level thresholds (example: Level 1: 0, Level 2: 100, Level 3: 500, Level 4: 1000, Level 5: 2000...)
        reputationThresholds = [0, 100, 500, 1000, 2000];
    }

    // --- 1. Identity Management Functions ---

    /// @notice Creates a new digital identity for the caller.
    function createIdentity() external whenNotPaused {
        require(identityOwners[nextIdentityId] == address(0), "Identity ID collision, please try again."); // unlikely but as a safety
        identityOwners[nextIdentityId] = msg.sender;
        emit IdentityCreated(nextIdentityId, msg.sender);
        nextIdentityId++;
    }

    /// @notice Retrieves the owner of a specific identity.
    /// @param identityId The ID of the identity.
    /// @return The address of the identity owner.
    function getIdentityOwner(uint256 identityId) external view identityExists(identityId) returns (address) {
        return identityOwners[identityId];
    }

    /// @notice Allows identity owners to update their profile information (off-chain data).
    /// @param identityId The ID of the identity to update.
    /// @param profileData A string containing the profile data (e.g., URI or JSON string).
    function updateIdentityProfile(uint256 identityId, string memory profileData) external whenNotPaused identityExists(identityId) onlyIdentityOwner(identityId) {
        identityProfiles[identityId] = profileData;
        emit ProfileUpdated(identityId);
    }

    /// @notice Retrieves the profile data associated with an identity.
    /// @param identityId The ID of the identity.
    /// @return The profile data string.
    function getIdentityProfile(uint256 identityId) external view identityExists(identityId) returns (string memory) {
        return identityProfiles[identityId];
    }

    /// @notice Allows transferring ownership of an identity.
    /// @param identityId The ID of the identity to transfer.
    /// @param newOwner The address of the new owner.
    function transferIdentityOwnership(uint256 identityId, address newOwner) external whenNotPaused identityExists(identityId) onlyIdentityOwner(identityId) {
        require(newOwner != address(0), "New owner address cannot be zero.");
        address oldOwner = identityOwners[identityId];
        identityOwners[identityId] = newOwner;
        emit OwnershipTransferred(identityId, oldOwner, newOwner);
    }

    /// @notice (Optional) Resolves an identity ID from an owner address. (Simple linear search, consider indexing for efficiency in real-world)
    /// @param ownerAddress The address to resolve.
    /// @return The identity ID, or 0 if not found.
    function resolveIdentity(address ownerAddress) external view returns (uint256) {
        for (uint256 i = 1; i < nextIdentityId; i++) { // Iterate through existing IDs (not efficient for very large numbers, consider indexing)
            if (identityOwners[i] == ownerAddress) {
                return i;
            }
        }
        return 0; // Identity not found for this address
    }


    // --- 2. Reputation System Functions ---

    /// @notice Increases the reputation score of an identity. (Admin/Contract controlled rewards)
    /// @param identityId The ID of the identity to increase reputation for.
    /// @param amount The amount to increase the reputation by.
    function increaseReputation(uint256 identityId, uint256 amount) external onlyOwner whenNotPaused identityExists(identityId) {
        reputationScores[identityId] += amount;
        emit ReputationIncreased(identityId, amount, reputationScores[identityId]);
    }

    /// @notice Decreases the reputation score of an identity. (Admin/Contract controlled penalties)
    /// @param identityId The ID of the identity to decrease reputation for.
    /// @param amount The amount to decrease the reputation by.
    function decreaseReputation(uint256 identityId, uint256 amount) external onlyOwner whenNotPaused identityExists(identityId) {
        require(reputationScores[identityId] >= amount, "Reputation cannot be negative.");
        reputationScores[identityId] -= amount;
        emit ReputationDecreased(identityId, amount, reputationScores[identityId]);
    }

    /// @notice Retrieves the reputation score of an identity.
    /// @param identityId The ID of the identity.
    /// @return The reputation score.
    function getReputationScore(uint256 identityId) external view identityExists(identityId) returns (uint256) {
        return reputationScores[identityId];
    }

    /// @notice Determines the identity level based on the reputation score.
    /// @param reputationScore The reputation score to evaluate.
    /// @return The identity level (starting from 1).
    function getLevelFromReputation(uint256 reputationScore) public view returns (uint256) {
        for (uint256 i = reputationThresholds.length - 1; i >= 0; i--) {
            if (reputationScore >= reputationThresholds[i]) {
                return i + 1; // Level is index + 1 (Level 1 starts at index 0)
            }
            if (i == 0) break; // Prevent underflow in loop
        }
        return 1; // Default to level 1 if below lowest threshold
    }

    /// @notice Retrieves the level of an identity based on reputation.
    /// @param identityId The ID of the identity.
    /// @return The identity level.
    function getIdentityLevel(uint256 identityId) external view identityExists(identityId) returns (uint256) {
        return getLevelFromReputation(reputationScores[identityId]);
    }


    // --- 3. Verifiable Achievements (Badges) Functions ---

    /// @notice Issues a verifiable achievement to an identity. (Admin/Issuer role)
    /// @param identityId The ID of the identity to issue the achievement to.
    /// @param achievementName A unique name for the achievement.
    /// @param achievementData Optional data associated with the achievement (e.g., URI, JSON string).
    function issueAchievement(uint256 identityId, string memory achievementName, string memory achievementData) external onlyOwner whenNotPaused identityExists(identityId) {
        require(!identityAchievements[identityId][achievementName], "Achievement already issued.");
        identityAchievements[identityId][achievementName] = true;
        identityAchievementList[identityId].push(achievementName); // Keep track of achievement names for easy retrieval
        emit AchievementIssued(identityId, achievementName, achievementData);
    }

    /// @notice Revokes a previously issued achievement. (Admin/Issuer role)
    /// @param identityId The ID of the identity to revoke the achievement from.
    /// @param achievementName The name of the achievement to revoke.
    function revokeAchievement(uint256 identityId, string memory achievementName) external onlyOwner whenNotPaused identityExists(identityId) {
        require(identityAchievements[identityId][achievementName], "Achievement not issued or already revoked.");
        identityAchievements[identityId][achievementName] = false;

        // Remove from achievement list (less efficient - consider alternative if list operations become performance bottleneck)
        string[] memory currentAchievements = identityAchievementList[identityId];
        string[] memory newAchievements = new string[](currentAchievements.length - 1);
        uint256 newIndex = 0;
        for (uint256 i = 0; i < currentAchievements.length; i++) {
            if (keccak256(bytes(currentAchievements[i])) != keccak256(bytes(achievementName))) {
                newAchievements[newIndex++] = currentAchievements[i];
            }
        }
        identityAchievementList[identityId] = newAchievements; // Replace with the filtered list


        emit AchievementRevoked(identityId, achievementName);
    }

    /// @notice Retrieves a list of achievements earned by an identity.
    /// @param identityId The ID of the identity.
    /// @return An array of achievement names.
    function getAchievements(uint256 identityId) external view identityExists(identityId) returns (string[] memory) {
        return identityAchievementList[identityId];
    }

    /// @notice Checks if an achievement is valid for an identity.
    /// @param identityId The ID of the identity.
    /// @param achievementName The name of the achievement to check.
    /// @return True if the achievement is valid, false otherwise.
    function isAchievementValid(uint256 identityId, string memory achievementName) external view identityExists(identityId) returns (bool) {
        return identityAchievements[identityId][achievementName];
    }


    // --- 4. Dynamic Identity Features Functions ---

    /// @notice Allows identity owners to set a status message for their identity.
    /// @param identityId The ID of the identity to set status for.
    /// @param statusMessage The status message string.
    function setIdentityStatus(uint256 identityId, string memory statusMessage) external whenNotPaused identityExists(identityId) onlyIdentityOwner(identityId) {
        identityStatuses[identityId] = statusMessage;
        emit StatusUpdated(identityId, statusMessage);
    }

    /// @notice Retrieves the current status message of an identity.
    /// @param identityId The ID of the identity.
    /// @return The status message string.
    function getIdentityStatus(uint256 identityId) external view identityExists(identityId) returns (string memory) {
        return identityStatuses[identityId];
    }

    /// @notice Allows one identity to endorse another, contributing to reputation (community driven).
    /// @param endorsingIdentityId The ID of the identity doing the endorsement.
    /// @param endorsedIdentityId The ID of the identity being endorsed.
    function endorseIdentity(uint256 endorsingIdentityId, uint256 endorsedIdentityId) external whenNotPaused identityExists(endorsingIdentityId) identityExists(endorsedIdentityId) {
        require(endorsingIdentityId != endorsedIdentityId, "Cannot endorse yourself.");
        endorsementCounts[endorsedIdentityId]++; // Simple endorsement count for now, can be weighted or more complex in future
        emit IdentityEndorsed(endorsingIdentityId, endorsedIdentityId);
        // Consider adding reputation increase for endorsed identity based on endorsement count or level of endorser
        // Example: increaseReputation(endorsedIdentityId, 1); // Small reputation boost for endorsement
    }

    /// @notice Retrieves the number of endorsements received by an identity.
    /// @param identityId The ID of the identity.
    /// @return The endorsement count.
    function getEndorsementCount(uint256 identityId) external view identityExists(identityId) returns (uint256) {
        return endorsementCounts[identityId];
    }


    // --- 5. Contract Administration & Utility Functions ---

    /// @notice Sets the reputation score thresholds for different identity levels. (Admin)
    /// @param levelThresholds An array of reputation scores defining level boundaries. Must be sorted in ascending order.
    function setReputationThresholds(uint256[] memory levelThresholds) external onlyOwner whenNotPaused {
        // Consider adding validation to ensure thresholds are sorted and make sense
        reputationThresholds = levelThresholds;
        emit ReputationThresholdsUpdated(levelThresholds);
    }

    /// @notice Retrieves the current reputation level thresholds.
    /// @return An array of reputation score thresholds.
    function getReputationThresholds() external view onlyOwner returns (uint256[] memory) {
        return reputationThresholds;
    }

    /// @notice Pauses the contract, disabling most functions. (Admin - Emergency stop)
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Resumes contract functionality. (Admin)
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Checks if the contract is currently paused.
    /// @return True if the contract is paused, false otherwise.
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /// @notice Allows the contract owner to withdraw any accumulated balance. (Admin - if contract collects fees in future)
    function withdrawContractBalance() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
        emit BalanceWithdrawn(msg.sender, balance);
    }

    // Fallback function to prevent accidental sending of Ether to the contract
    fallback() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }

    receive() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }
}
```