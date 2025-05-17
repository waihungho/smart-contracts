Okay, here is a Solidity smart contract called `Ethluminate`.

This contract represents a decentralized system for "illuminating" or discovering insights, rewarding users based on their contributions and endorsements, and evolving through different phases ("Ages"). It incorporates concepts like a custom reputation/score system, dynamic parameters based on contract state (Ages), and a mechanism for endorsing data hashes with staked value.

It aims to be more complex than standard token/NFT contracts by introducing internal state transitions, a custom scoring mechanism, and multiple interaction points beyond simple transfers or minting.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Ethluminate
 * @dev A smart contract for a decentralized insight discovery and illumination platform.
 *      Users contribute insights (data hashes), stake ETH to endorse insights,
 *      and earn an 'Illumination Score' based on their activity. The contract
 *      evolves through different 'Ages', which can affect system parameters.
 *
 * Outline:
 * 1. State Variables & Data Structures
 *    - User profiles (illumination score, metadata)
 *    - Insight data (contributor, hashes, endorsements, state)
 *    - Contract Age and associated parameters
 *    - Mappings to store users, insights, and staking details
 *    - Counters for unique IDs
 * 2. Events
 *    - Notifications for key state changes (Insight Added, Staked, Unstaked, Validated, Age Advanced, Score Updated)
 * 3. Modifiers
 *    - Access control (onlyOwner)
 *    - State control (onlyDuringAge, notDuringAge)
 * 4. Core Logic (Functions)
 *    - User interactions (add insights, stake, unstake, update profile)
 *    - Insight management (get insight details, validation)
 *    - System state management (advance age, set age parameters, get state)
 *    - Querying functions (get total counts, lists of IDs, specific details)
 *    - Internal helper functions (score calculation)
 * 5. Owner/Admin Functions
 *    - Managing contract age and parameters
 *    - Emergency functions (optional, excluded for complexity focus)
 *    - Ownership transfer
 */

/**
 * Function Summary:
 *
 * User Interaction & Data:
 * 1.  `addInsight(bytes32 dataHash, bytes32 metadataHash)`: Allows a user to submit a new insight with associated data and metadata hashes.
 * 2.  `stakeForInsight(uint256 insightId)`: Allows a user to stake ETH on a specific insight, endorsing it and boosting its score potential. Payable function.
 * 3.  `unstakeFromInsight(uint256 insightId, uint256 amount)`: Allows a staker to withdraw a portion or all of their stake from an insight.
 * 4.  `updateUserProfileMetadata(string calldata newMetadataURI)`: Allows a user to update a link to their profile metadata (e.g., IPFS URI).
 * 5.  `claimIlluminationReward()`: Placeholder for a function users could call to claim rewards based on score (implementation TBD, kept simple here).
 *
 * Insight Management:
 * 6.  `validateInsight(uint256 insightId)`: Allows a privileged user (e.g., owner or high score holder) to 'validate' an insight, potentially increasing its score multiplier.
 * 7.  `deactivateInsight(uint256 insightId)`: Allows a privileged user to deactivate an insight, preventing new stakes and potentially reducing its score impact.
 *
 * System State & Age Management:
 * 8.  `advanceAge()`: Owner-only function to transition the contract to the next predefined Age.
 * 9.  `setAgeParameters(uint8 age, uint256 _stakeMultiplier, uint256 _validationBonus)`: Owner-only function to configure parameters for a specific Age.
 *
 * Querying Functions:
 * 10. `getUserProfile(address user)`: Returns the full profile data for a specific user address.
 * 11. `getUserIlluminationScore(address user)`: Returns only the illumination score of a user.
 * 12. `getInsight(uint256 insightId)`: Returns the full data for a specific insight ID.
 * 13. `getInsightEndorsements(uint256 insightId)`: Returns the total ETH staked on an insight and the count of unique stakers.
 * 14. `getInsightStakeAmount(uint256 insightId, address staker)`: Returns the specific amount staked by a user on an insight.
 * 15. `getTotalInsights()`: Returns the total number of insights ever added.
 * 16. `getInsightsByContributor(address contributor)`: Returns a list of insight IDs contributed by a specific address.
 * 17. `getAllInsightIds()`: Returns a list of all active insight IDs. (Note: Can be gas-intensive for large numbers).
 * 18. `getCurrentAge()`: Returns the current Age of the contract.
 * 19. `getAgeParameters(uint8 age)`: Returns the configurable parameters for a given Age.
 * 20. `getContractBalance()`: Returns the total ETH held by the contract (primarily from staking).
 * 21. `userExists(address user)`: Checks if a user profile exists for an address.
 * 22. `insightExists(uint256 insightId)`: Checks if an insight exists for a given ID.
 * 23. `getInsightContributors()`: Returns a list of unique addresses who have contributed insights. (Note: Can be gas-intensive).
 * 24. `getValidatedInsightIds()`: Returns a list of IDs for insights that have been validated.
 * 25. `getTopStakersForInsight(uint256 insightId, uint256 limit)`: Returns the addresses of the top N stakers for a given insight (simplified, potentially gas-intensive). *Complexity Note: Actual implementation of 'top' requires iterating or storing sorted data, simplified here.*
 */

contract Ethluminate {

    address private owner;
    uint256 private nextInsightId;
    uint256 private totalInsightsCount; // Total insights ever created

    enum ContractAge {
        Dawn,     // Initial phase, low multipliers
        Ascension,// Growth phase, higher multipliers
        Zenith    // Peak phase, potentially different rules
        // Can add more ages like Decay, Renewal, etc.
    }

    ContractAge public currentAge;

    struct AgeParameters {
        uint256 stakeMultiplier; // Factor applied to staked amount for score calculation
        uint256 validationBonus; // Score bonus for validation
        // Add other age-specific parameters here
    }

    mapping(uint8 => AgeParameters) public ageConfigs;

    struct UserProfile {
        uint256 illuminationScore;
        string metadataURI; // Link to off-chain profile data (e.g., IPFS hash)
        // Add other user-specific data here
    }

    mapping(address => UserProfile) private userProfiles;
    mapping(address => bool) private userProfileExists; // To check existence easily

    struct Insight {
        uint256 id;
        address contributor;
        bytes32 dataHash;       // Hash of the core insight data
        bytes32 metadataHash;   // Hash of metadata related to the insight
        uint256 totalStake;
        uint256 uniqueStakerCount;
        bool isValidated;
        bool isActive; // Can be deactivated
        // Add other insight-specific data
    }

    mapping(uint256 => Insight) private insights;
    mapping(uint256 => mapping(address => uint256)) private insightStakes; // insightId => staker => amount
    mapping(address => uint256[]) private insightsByContributor; // contributor => list of insight IDs
    uint256[] private allInsightIds; // Simple array of all active insight IDs (gas concern!)
    address[] private insightContributorsList; // Simple list of unique contributors (gas concern!)
    mapping(address => bool) private isContributor; // To track unique contributors

    // Array to store IDs of validated insights
    uint256[] private validatedInsightIds;
    mapping(uint256 => bool) private isInsightValidated; // To check validation status easily

    // --- Events ---

    event InsightAdded(uint256 indexed insightId, address indexed contributor, bytes32 dataHash);
    event StakedForInsight(uint256 indexed insightId, address indexed staker, uint256 amount);
    event UnstakedFromInsight(uint256 indexed insightId, address indexed staker, uint256 amount);
    event InsightValidated(uint256 indexed insightId, address indexed validator);
    event InsightDeactivated(uint256 indexed insightId, address indexed admin);
    event AgeAdvanced(ContractAge indexed newAge, uint256 timestamp);
    event ScoreUpdated(address indexed user, uint256 newScore, uint256 pointsAdded);
    event ProfileMetadataUpdated(address indexed user, string newMetadataURI);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyDuringAge(ContractAge age) {
        require(currentAge == age, "Function not available in current age");
        _;
    }

    modifier notDuringAge(ContractAge age) {
        require(currentAge != age, "Function not available in current age");
        _;
    }

    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        nextInsightId = 1;
        totalInsightsCount = 0;
        currentAge = ContractAge.Dawn;

        // Set default parameters for initial ages
        ageConfigs[uint8(ContractAge.Dawn)] = AgeParameters({
            stakeMultiplier: 1,
            validationBonus: 100
        });
         ageConfigs[uint8(ContractAge.Ascension)] = AgeParameters({
            stakeMultiplier: 3,
            validationBonus: 300
        });
         ageConfigs[uint8(ContractAge.Zenith)] = AgeParameters({
            stakeMultiplier: 5,
            validationBonus: 500
        });
         // Initialize other age configs if needed
    }

    // --- Core Logic Functions ---

    /**
     * @dev Allows a user to submit a new insight.
     * @param dataHash The hash of the core data for the insight.
     * @param metadataHash The hash of metadata describing the insight.
     */
    function addInsight(bytes32 dataHash, bytes32 metadataHash) external {
        uint256 insightId = nextInsightId++;
        totalInsightsCount++;

        insights[insightId] = Insight({
            id: insightId,
            contributor: msg.sender,
            dataHash: dataHash,
            metadataHash: metadataHash,
            totalStake: 0,
            uniqueStakerCount: 0,
            isValidated: false,
            isActive: true
        });

        insightsByContributor[msg.sender].push(insightId);
        allInsightIds.push(insightId); // Add to global list

        if (!isContributor[msg.sender]) {
            isContributor[msg.sender] = true;
            insightContributorsList.push(msg.sender); // Add to contributors list
        }

        // Automatically create user profile if it doesn't exist
        if (!userProfileExists[msg.sender]) {
            userProfiles[msg.sender].illuminationScore = 0;
            userProfiles[msg.sender].metadataURI = ""; // Default empty
            userProfileExists[msg.sender] = true;
        }

        // Simple score boost for adding an insight
        _updateScore(msg.sender, 50); // Base points for adding

        emit InsightAdded(insightId, msg.sender, dataHash);
    }

    /**
     * @dev Allows a user to stake ETH on an insight to endorse it.
     *      Increases the staker's illumination score.
     * @param insightId The ID of the insight to stake on.
     */
    function stakeForInsight(uint256 insightId) external payable {
        require(msg.value > 0, "Must stake a non-zero amount of ETH");
        Insight storage insight = insights[insightId];
        require(insight.id != 0, "Insight does not exist"); // Check if insightId is valid
        require(insight.isActive, "Insight is not active");

        uint256 currentStake = insightStakes[insightId][msg.sender];
        bool isFirstStake = currentStake == 0;

        insightStakes[insightId][msg.sender] = currentStake + msg.value;
        insight.totalStake += msg.value;

        if (isFirstStake) {
            insight.uniqueStakerCount++;
        }

        // Automatically create user profile if it doesn't exist
        if (!userProfileExists[msg.sender]) {
             userProfiles[msg.sender].illuminationScore = 0;
             userProfiles[msg.sender].metadataURI = "";
             userProfileExists[msg.sender] = true;
        }

        // Calculate score increase based on staked amount and current age multiplier
        AgeParameters memory currentParams = ageConfigs[uint8(currentAge)];
        uint256 scoreIncrease = (msg.value * currentParams.stakeMultiplier) / 1 ether; // Scale by 1 ether if staking in wei

        _updateScore(msg.sender, scoreIncrease);

        emit StakedForInsight(insightId, msg.sender, msg.value);
    }

    /**
     * @dev Allows a user to unstake ETH from an insight.
     *      Note: Unstaking does NOT currently reduce illumination score in this simple model.
     * @param insightId The ID of the insight to unstake from.
     * @param amount The amount of ETH to unstake.
     */
    function unstakeFromInsight(uint256 insightId, uint256 amount) external {
        require(amount > 0, "Must unstake a non-zero amount");
        Insight storage insight = insights[insightId];
        require(insight.id != 0, "Insight does not exist");
        require(insightStakes[insightId][msg.sender] >= amount, "Not enough staked amount");

        insightStakes[insightId][msg.sender] -= amount;
        insight.totalStake -= amount;

        if (insightStakes[insightId][msg.sender] == 0) {
            insight.uniqueStakerCount--;
        }

        // Send ETH back to the user
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");

        emit UnstakedFromInsight(insightId, msg.sender, amount);
    }

     /**
     * @dev Allows a privileged user (owner) to 'validate' an insight.
     *      Adds a score bonus to the insight contributor.
     * @param insightId The ID of the insight to validate.
     */
    function validateInsight(uint256 insightId) external onlyOwner {
        Insight storage insight = insights[insightId];
        require(insight.id != 0, "Insight does not exist");
        require(!insight.isValidated, "Insight is already validated");

        insight.isValidated = true;
        isInsightValidated[insightId] = true;
        validatedInsightIds.push(insightId); // Add to validated list

        // Grant validation bonus to the contributor
        AgeParameters memory currentParams = ageConfigs[uint8(currentAge)];
        _updateScore(insight.contributor, currentParams.validationBonus);

        emit InsightValidated(insightId, msg.sender);
    }

    /**
     * @dev Allows a privileged user (owner) to deactivate an insight.
     *      Deactivated insights cannot receive new stakes. Existing stakes remain until unstaked.
     * @param insightId The ID of the insight to deactivate.
     */
    function deactivateInsight(uint256 insightId) external onlyOwner {
        Insight storage insight = insights[insightId];
        require(insight.id != 0, "Insight does not exist");
        require(insight.isActive, "Insight is already inactive");

        insight.isActive = false;

        // Remove from active list - this is complex and gas intensive for large arrays
        // A more gas-efficient way is to mark inactive and filter on retrieval,
        // or use a more complex data structure. For this example, we'll keep the
        // simple array but add a warning.
        uint256 len = allInsightIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (allInsightIds[i] == insightId) {
                // Swap with last element and pop (order doesn't matter)
                if (i != len - 1) {
                     allInsightIds[i] = allInsightIds[len - 1];
                }
                allInsightIds.pop();
                break;
            }
        }


        emit InsightDeactivated(insightId, msg.sender);
    }


    /**
     * @dev Allows a user to update their profile metadata URI.
     * @param newMetadataURI The new URI pointing to off-chain metadata.
     */
    function updateUserProfileMetadata(string calldata newMetadataURI) external {
         require(userProfileExists[msg.sender], "User profile does not exist");
         userProfiles[msg.sender].metadataURI = newMetadataURI;

         emit ProfileMetadataUpdated(msg.sender, newMetadataURI);
    }

    /**
     * @dev Placeholder function for users to claim potential rewards.
     *      Reward logic is not implemented here for simplicity, but this
     *      shows how a score-based claim could be structured.
     */
    function claimIlluminationReward() external {
        require(userProfileExists[msg.sender], "User profile does not exist");
        // In a real implementation, calculate claimable rewards based on score,
        // contract balance, reward pool, time, etc.
        // For example: uint256 rewardAmount = (userProfiles[msg.sender].illuminationScore * rewardPerScoreUnit) / someScalingFactor;
        // require(rewardAmount > 0, "No rewards to claim");

        // Transfer reward tokens or ETH
        // (bool success, ) = payable(msg.sender).call{value: rewardAmount}("");
        // require(success, "Reward transfer failed");

        // Decrement claimed score/reward balance
        // userProfiles[msg.sender].illuminationScore = 0; // Or decrement claimed amount

        // emit RewardClaimed(msg.sender, rewardAmount);
        revert("Reward claiming is not yet implemented"); // Indicate it's a placeholder
    }


    // --- System State & Age Management Functions ---

    /**
     * @dev Allows the owner to advance the contract to the next Age.
     *      Ages define different system parameters.
     */
    function advanceAge() external onlyOwner {
        uint8 currentAgeIndex = uint8(currentAge);
        uint8 nextAgeIndex = currentAgeIndex + 1;

        // Assuming ages are sequential (0, 1, 2, ...)
        // Check if the next age exists in configurations (simple check if params were set)
        // A more robust check might look at the enum bounds or a specific end state.
        if (nextAgeIndex < uint8(ContractAge.Zenith) + 1) { // Check against max defined enum value + 1
             currentAge = ContractAge(nextAgeIndex);
             emit AgeAdvanced(currentAge, block.timestamp);
        } else {
             // Optional: Revert or loop back to an earlier age
             revert("No further defined ages to advance to");
        }
    }

    /**
     * @dev Allows the owner to set parameters for a specific Age.
     *      These parameters influence score calculations.
     * @param age The Age index (0=Dawn, 1=Ascension, etc.) to configure.
     * @param _stakeMultiplier The multiplier for stake amount in score calculation.
     * @param _validationBonus The score bonus granted for validating an insight.
     */
    function setAgeParameters(uint8 age, uint256 _stakeMultiplier, uint256 _validationBonus) external onlyOwner {
         require(age < uint8(ContractAge.Zenith) + 1, "Invalid age index"); // Ensure age index is within enum bounds

         ageConfigs[age] = AgeParameters({
             stakeMultiplier: _stakeMultiplier,
             validationBonus: _validationBonus
         });
    }


    // --- Querying Functions ---

    /**
     * @dev Gets the profile details for a specific user.
     * @param user The address of the user.
     * @return UserProfile struct containing score and metadata URI.
     */
    function getUserProfile(address user) external view returns (UserProfile memory) {
        require(userProfileExists[user], "User profile does not exist");
        return userProfiles[user];
    }

    /**
     * @dev Gets the illumination score for a specific user.
     * @param user The address of the user.
     * @return The user's current illumination score.
     */
    function getUserIlluminationScore(address user) external view returns (uint256) {
        require(userProfileExists[user], "User profile does not exist");
        return userProfiles[user].illuminationScore;
    }

    /**
     * @dev Gets the details for a specific insight.
     * @param insightId The ID of the insight.
     * @return Insight struct containing all insight data.
     */
    function getInsight(uint256 insightId) external view returns (Insight memory) {
         require(insights[insightId].id != 0, "Insight does not exist");
         return insights[insightId];
    }

    /**
     * @dev Gets the total stake and unique staker count for an insight.
     * @param insightId The ID of the insight.
     * @return totalStake The total amount of ETH staked on the insight.
     * @return uniqueStakerCount The number of unique addresses that have staked.
     */
    function getInsightEndorsements(uint256 insightId) external view returns (uint256 totalStake, uint256 uniqueStakerCount) {
         require(insights[insightId].id != 0, "Insight does not exist");
         return (insights[insightId].totalStake, insights[insightId].uniqueStakerCount);
    }

     /**
     * @dev Gets the amount staked by a specific user on an insight.
     * @param insightId The ID of the insight.
     * @param staker The address of the staker.
     * @return The amount of ETH staked by the user on the insight.
     */
    function getInsightStakeAmount(uint256 insightId, address staker) external view returns (uint256) {
         require(insights[insightId].id != 0, "Insight does not exist");
         return insightStakes[insightId][staker];
    }

    /**
     * @dev Gets the total number of insights ever added to the contract.
     * @return The total count of insights.
     */
    function getTotalInsights() external view returns (uint256) {
        return totalInsightsCount;
    }

    /**
     * @dev Gets a list of insight IDs contributed by a specific address.
     * @param contributor The address of the contributor.
     * @return An array of insight IDs.
     */
    function getInsightsByContributor(address contributor) external view returns (uint256[] memory) {
        return insightsByContributor[contributor];
    }

    /**
     * @dev Gets a list of all active insight IDs.
     *      NOTE: This function can be very gas-intensive if there are many insights.
     *      Consider pagination or alternative query methods for production.
     * @return An array of all active insight IDs.
     */
    function getAllInsightIds() external view returns (uint256[] memory) {
        // Returns the dynamic array of active IDs. If deactivateInsight swaps/pops,
        // this list represents current active insights.
        return allInsightIds;
    }

    /**
     * @dev Gets the current Age of the contract.
     * @return The current ContractAge enum value.
     */
    function getCurrentAge() external view returns (ContractAge) {
        return currentAge;
    }

    /**
     * @dev Gets the configuration parameters for a specific Age.
     * @param age The Age index (0=Dawn, 1=Ascension, etc.).
     * @return AgeParameters struct.
     */
    function getAgeParameters(uint8 age) external view returns (AgeParameters memory) {
        require(age < uint8(ContractAge.Zenith) + 1, "Invalid age index");
        return ageConfigs[age];
    }

    /**
     * @dev Gets the total ETH balance held by the contract.
     * @return The contract's current balance in Wei.
     */
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Checks if a user profile exists for an address.
     * @param user The address to check.
     * @return True if a profile exists, false otherwise.
     */
    function userExists(address user) external view returns (bool) {
        return userProfileExists[user];
    }

     /**
     * @dev Checks if an insight exists for a given ID.
     * @param insightId The ID to check.
     * @return True if an insight exists, false otherwise.
     */
    function insightExists(uint256 insightId) external view returns (bool) {
        return insights[insightId].id != 0; // Check if id is initialized (default 0)
    }

     /**
     * @dev Gets a list of all unique addresses that have contributed insights.
     *      NOTE: This function can be very gas-intensive if there are many contributors.
     *      Consider alternative methods for production.
     * @return An array of contributor addresses.
     */
    function getInsightContributors() external view returns (address[] memory) {
         // Returns the simple dynamic array of unique contributors
         return insightContributorsList;
    }

     /**
     * @dev Gets a list of IDs for insights that have been validated.
     * @return An array of validated insight IDs.
     */
    function getValidatedInsightIds() external view returns (uint256[] memory) {
         return validatedInsightIds;
     }

    /**
     * @dev Attempts to get the addresses of the top N stakers for an insight.
     *      NOTE: This is a simplified implementation for demonstration. Determining
     *      "top stakers" efficiently on-chain for arbitrary N requires complex
     *      data structures or is gas-prohibitive for large sets. This version
     *      just returns the first 'limit' stakers it might find (not guaranteed
     *      to be the true top) or requires iterating, which is omitted to avoid
     *      excessive complexity/gas. A real implementation would need significant
     *      optimization or rely on off-chain processing.
     * @param insightId The ID of the insight.
     * @param limit The maximum number of staker addresses to return.
     * @return An array of staker addresses (order/correctness not guaranteed for "top" due to simplification).
     */
    function getTopStakersForInsight(uint256 insightId, uint256 limit) external view returns (address[] memory) {
        require(insights[insightId].id != 0, "Insight does not exist");
        require(limit > 0, "Limit must be greater than 0");

        // --- Simplified Implementation Warning ---
        // This cannot efficiently iterate through all stakers to find the 'top'
        // based on stake amount in a gas-conscious way.
        // A proper implementation would involve:
        // 1) Storing stakers in a list per insight.
        // 2) Sorting that list by stake amount (highly gas-intensive on-chain).
        // 3) Relying on off-chain services to determine and maybe cache top stakers.
        //
        // As a *very basic* placeholder demonstrating the *intent* of having such a query:
        // We cannot return the *actual* top N stakers efficiently from mappings alone.
        // Returning a blank array or reverting is safer than returning misleading data or using excessive gas.
        // Let's return a blank array and note the limitation.

        // Example of how one *might* store a list of stakers (still needs iteration/sorting for "top"):
        // mapping(uint256 => address[]) private insightStakerAddresses; // List of staker addresses per insight
        // Push msg.sender to insightStakerAddresses[insightId] on stake if first stake.

        // Returning a blank array as the "top" determination is complex and omitted.
        address[] memory topStakers = new address[](0);
        // In a real app, you'd query off-chain data indexed from events (StakedForInsight)
        // and insightStakes mapping to determine top stakers.

        return topStakers;
    }


    // --- Internal Helper Functions ---

    /**
     * @dev Internal function to update a user's illumination score.
     * @param user The address of the user.
     * @param points The amount of points to add to the score.
     */
    function _updateScore(address user, uint256 points) internal {
        // Ensure user profile exists before updating score
        if (!userProfileExists[user]) {
             userProfiles[user].illuminationScore = 0;
             userProfiles[user].metadataURI = "";
             userProfileExists[user] = true;
        }

        userProfiles[user].illuminationScore += points;
        emit ScoreUpdated(user, userProfiles[user].illuminationScore, points);
    }

    // --- Owner/Admin Functions (Standard Utility) ---

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
        // Optional: emit event for ownership transfer
    }
}
```