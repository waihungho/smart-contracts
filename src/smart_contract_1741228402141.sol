```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Influence Platform
 * @author Bard (Example Smart Contract)
 * @dev A smart contract implementing a decentralized platform for dynamic reputation and influence tracking.
 *      This contract introduces a novel concept of "Reputation Oracles" and a dynamic reputation decay mechanism.
 *      It aims to create a transparent and community-driven system for evaluating user influence based on verifiable on-chain actions and oracle-attested contributions.
 *
 * **Outline and Function Summary:**
 *
 * **Core Functionality:**
 * 1. `registerUser()`: Allows users to register on the platform and initialize their reputation.
 * 2. `getUserReputation(address _user)`: Retrieves the reputation score of a user.
 * 3. `performAction(ActionType _actionType, uint256 _actionValue)`:  Users perform actions on the platform, contributing to their reputation.
 * 4. `reportUser(address _targetUser, string memory _reportReason)`: Allows users to report malicious or inappropriate behavior.
 * 5. `resolveReport(address _targetUser, bool _isMalicious)`: Admin function to resolve user reports, impacting reputation.
 * 6. `addReputationOracle(address _oracleAddress)`: Admin function to add trusted reputation oracles.
 * 7. `removeReputationOracle(address _oracleAddress)`: Admin function to remove reputation oracles.
 * 8. `submitOracleAttestation(address _user, uint256 _reputationBoost, string memory _attestationDetails)`: Reputation oracles attest to off-chain contributions, boosting user reputation.
 * 9. `getOracleAttestations(address _user)`: Retrieves attestations made by oracles for a specific user.
 * 10. `setReputationDecayRate(uint256 _decayRate)`: Admin function to set the reputation decay rate.
 * 11. `getReputationDecayRate()`: Retrieves the current reputation decay rate.
 * 12. `applyReputationDecay()`:  Applies reputation decay to all users based on inactivity. (Automated or triggerable)
 * 13. `setReputationActionWeight(ActionType _actionType, uint256 _weight)`: Admin function to configure the reputation weight for different action types.
 * 14. `getReputationActionWeight(ActionType _actionType)`: Retrieves the reputation weight for a specific action type.
 * 15. `pauseContract()`: Admin function to pause the contract for maintenance or emergency.
 * 16. `unpauseContract()`: Admin function to unpause the contract.
 * 17. `isContractPaused()`: Checks if the contract is currently paused.
 * 18. `setAdmin(address _newAdmin)`: Admin function to transfer contract administration.
 * 19. `getAdmin()`: Retrieves the current contract administrator address.
 * 20. `emergencyWithdraw(address _tokenAddress, address _recipient, uint256 _amount)`: Admin function for emergency fund withdrawal in case of critical issues.
 * 21. `getUserProfile(address _user)`: Retrieves user profile information (extensible).
 * 22. `updateUserProfile(string memory _newProfileData)`: Allows users to update their profile information.
 * 23. `getPlatformBalance()`: Admin function to view the contract's ETH balance.
 * 24. `recoverStuckTokens(address _tokenAddress, address _recipient, uint256 _amount)`: Admin function to recover stuck tokens sent to the contract accidentally.

 * **Advanced Concepts:**
 * - **Reputation Oracles:** Introduces a decentralized oracle system for attesting to off-chain contributions, bridging the gap between on-chain actions and real-world influence.
 * - **Dynamic Reputation Decay:** Implements a reputation decay mechanism to ensure that reputation is actively maintained and reflects current contributions, preventing static and outdated scores.
 * - **Action-Based Reputation:**  Reputation is earned through verifiable actions within the platform, making it more objective and less susceptible to Sybil attacks compared to purely subjective systems.
 * - **Community Moderation:**  Incorporates a reporting and resolution system for managing user behavior and maintaining platform integrity.
 *
 * **Trendy Aspects:**
 * - **Decentralized Reputation:** Aligns with the Web3 ethos of decentralization and community ownership.
 * - **Influence Metrics:**  Provides a transparent and on-chain way to measure influence, which is increasingly relevant in decentralized communities and DAOs.
 * - **Oracle Integration:** Leverages oracles, a key component of many advanced blockchain applications.
 * - **Dynamic and Adaptive:** The reputation decay and configurable action weights make the system dynamic and adaptable to changing community needs.
 */

contract DynamicReputationPlatform {

    // --- State Variables ---

    address public admin;
    bool public paused;

    mapping(address => uint256) public userReputations; // User address => Reputation score
    mapping(address => string) public userProfiles;     // User address => Profile data (extensible)
    mapping(address => bool) public isUserRegistered;   // User address => Registration status

    mapping(address => bool) public isReputationOracle; // Oracle address => Oracle status
    mapping(address => Attestation[]) public oracleAttestations; // User address => Array of Oracle Attestations

    uint256 public reputationDecayRate = 1; // Percentage decay per decay period (e.g., per day)
    uint256 public lastDecayTimestamp;      // Timestamp of the last reputation decay application
    uint256 public decayPeriod = 1 days;     // Time interval for reputation decay

    enum ActionType {
        CONTENT_CREATION,
        POSITIVE_INTERACTION,
        COMMUNITY_CONTRIBUTION,
        PLATFORM_USAGE,
        REPORT_SUBMISSION // Example: Submitting a valid report
    }

    mapping(ActionType => uint256) public reputationActionWeights; // Action Type => Reputation Weight

    struct Report {
        address reporter;
        string reason;
        uint256 timestamp;
        bool resolved;
        bool isMalicious;
    }
    mapping(address => Report[]) public userReports; // User address => Array of reports against them

    struct Attestation {
        address oracleAddress;
        uint256 reputationBoost;
        string details;
        uint256 timestamp;
    }

    // --- Events ---

    event UserRegistered(address user);
    event ReputationUpdated(address user, uint256 newReputation, string reason);
    event UserReported(address targetUser, address reporter, string reason);
    event ReportResolved(address targetUser, bool isMalicious, address resolver);
    event ReputationOracleAdded(address oracleAddress, address admin);
    event ReputationOracleRemoved(address oracleAddress, address admin);
    event OracleAttestationSubmitted(address user, address oracleAddress, uint256 reputationBoost, string details);
    event ReputationDecayApplied(uint256 usersAffected, uint256 timestamp);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event AdminChanged(address oldAdmin, address newAdmin);
    event EmergencyWithdrawal(address tokenAddress, address recipient, uint256 amount, address admin);
    event UserProfileUpdated(address user, string profileData);
    event StuckTokensRecovered(address tokenAddress, address recipient, uint256 amount, address admin);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    modifier onlyRegisteredUser() {
        require(isUserRegistered[msg.sender], "User must be registered to perform this action.");
        _;
    }

    modifier onlyReputationOracle() {
        require(isReputationOracle[msg.sender], "Only reputation oracles can call this function.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        paused = false;

        // Initialize default reputation action weights
        reputationActionWeights[ActionType.CONTENT_CREATION] = 10;
        reputationActionWeights[ActionType.POSITIVE_INTERACTION] = 2;
        reputationActionWeights[ActionType.COMMUNITY_CONTRIBUTION] = 15;
        reputationActionWeights[ActionType.PLATFORM_USAGE] = 1;
        reputationActionWeights[ActionType.REPORT_SUBMISSION] = 5; // Awarded for valid reports

        lastDecayTimestamp = block.timestamp; // Initialize last decay timestamp
    }


    // --- User Registration and Profile Functions ---

    /**
     * @dev Allows a user to register on the platform.
     *      Initializes their reputation to 0 and sets registration status.
     */
    function registerUser() external whenNotPaused {
        require(!isUserRegistered[msg.sender], "User already registered.");
        userReputations[msg.sender] = 0;
        isUserRegistered[msg.sender] = true;
        emit UserRegistered(msg.sender);
    }

    /**
     * @dev Retrieves the reputation score of a user.
     * @param _user The address of the user.
     * @return The reputation score of the user.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        return userReputations[_user];
    }

    /**
     * @dev Retrieves user profile information.
     * @param _user The address of the user.
     * @return The profile data string of the user.
     */
    function getUserProfile(address _user) external view returns (string memory) {
        return userProfiles[_user];
    }

    /**
     * @dev Allows a registered user to update their profile information.
     * @param _newProfileData The new profile data string.
     */
    function updateUserProfile(string memory _newProfileData) external whenNotPaused onlyRegisteredUser {
        userProfiles[msg.sender] = _newProfileData;
        emit UserProfileUpdated(msg.sender, _newProfileData);
    }


    // --- Reputation Management Functions ---

    /**
     * @dev Allows registered users to perform actions on the platform, increasing their reputation.
     * @param _actionType The type of action performed (from the ActionType enum).
     * @param _actionValue An optional value associated with the action (e.g., content length, interaction strength).
     */
    function performAction(ActionType _actionType, uint256 _actionValue) external whenNotPaused onlyRegisteredUser {
        uint256 reputationGain = reputationActionWeights[_actionType] * _actionValue; // Simple weighted reputation gain

        // Example of action-specific logic (can be extended for each ActionType)
        if (_actionType == ActionType.CONTENT_CREATION) {
            // Add more sophisticated content quality checks or moderation here in a real application
            reputationGain = reputationGain > 0 ? reputationGain : reputationActionWeights[_actionType]; // Ensure minimum gain if value is 0
        } else if (_actionType == ActionType.POSITIVE_INTERACTION) {
            reputationGain = reputationGain > 0 ? reputationGain : reputationActionWeights[_actionType];
        } else if (_actionType == ActionType.COMMUNITY_CONTRIBUTION) {
            reputationGain = reputationGain > 0 ? reputationGain : reputationActionWeights[_actionType];
        } else if (_actionType == ActionType.PLATFORM_USAGE) {
             reputationGain = reputationGain > 0 ? reputationGain : reputationActionWeights[_actionType];
        } else if (_actionType == ActionType.REPORT_SUBMISSION) {
            reputationGain = reputationGain > 0 ? reputationGain : reputationActionWeights[_actionType]; // Awarded for submitting a report, resolved later if valid
        }


        userReputations[msg.sender] += reputationGain;
        emit ReputationUpdated(msg.sender, userReputations[msg.sender], string(abi.encodePacked("Action performed: ", actionTypeToString(_actionType))));
    }


    /**
     * @dev Allows users to report another user for malicious or inappropriate behavior.
     * @param _targetUser The address of the user being reported.
     * @param _reportReason A description of the reason for the report.
     */
    function reportUser(address _targetUser, string memory _reportReason) external whenNotPaused onlyRegisteredUser {
        require(_targetUser != msg.sender, "Cannot report yourself.");
        userReports[_targetUser].push(Report({
            reporter: msg.sender,
            reason: _reportReason,
            timestamp: block.timestamp,
            resolved: false,
            isMalicious: false
        }));
        emit UserReported(_targetUser, msg.sender, _reportReason);
        // Reward the reporter for submitting a report (incentivize community moderation)
        performAction(ActionType.REPORT_SUBMISSION, 1); // Simple reward for reporting, resolution determines if valid
    }

    /**
     * @dev Admin function to resolve a user report.
     *      Adjusts the reputation of the target user based on whether the report is deemed malicious.
     * @param _targetUser The address of the user who was reported.
     * @param _isMalicious True if the report is deemed malicious, false otherwise.
     */
    function resolveReport(address _targetUser, bool _isMalicious) external onlyAdmin whenNotPaused {
        require(userReports[_targetUser].length > 0, "No reports found for this user.");
        Report storage latestReport = userReports[_targetUser][userReports[_targetUser].length - 1]; // Resolve latest report for simplicity
        require(!latestReport.resolved, "Report already resolved.");

        latestReport.resolved = true;
        latestReport.isMalicious = _isMalicious;

        if (_isMalicious) {
            userReputations[_targetUser] = userReputations[_targetUser] > 10 ? userReputations[_targetUser] - 10 : 0; // Reduce reputation for malicious behavior
            emit ReputationUpdated(_targetUser, userReputations[_targetUser], "Reputation reduced due to malicious behavior report.");
        } else {
            // Optionally, reward the reporter further for a valid report resolution (if needed)
            // No reputation change for target user if not malicious
        }
        emit ReportResolved(_targetUser, _isMalicious, msg.sender);
    }


    // --- Reputation Oracle Functions ---

    /**
     * @dev Admin function to add a trusted reputation oracle.
     * @param _oracleAddress The address of the oracle to add.
     */
    function addReputationOracle(address _oracleAddress) external onlyAdmin whenNotPaused {
        isReputationOracle[_oracleAddress] = true;
        emit ReputationOracleAdded(_oracleAddress, msg.sender);
    }

    /**
     * @dev Admin function to remove a reputation oracle.
     * @param _oracleAddress The address of the oracle to remove.
     */
    function removeReputationOracle(address _oracleAddress) external onlyAdmin whenNotPaused {
        isReputationOracle[_oracleAddress] = false;
        emit ReputationOracleRemoved(_oracleAddress, msg.sender);
    }

    /**
     * @dev Reputation oracles can attest to off-chain contributions of users, boosting their reputation.
     * @param _user The address of the user being attested for.
     * @param _reputationBoost The amount of reputation boost to grant.
     * @param _attestationDetails Details about the off-chain contribution.
     */
    function submitOracleAttestation(address _user, uint256 _reputationBoost, string memory _attestationDetails) external whenNotPaused onlyReputationOracle {
        require(isUserRegistered[_user], "Target user is not registered.");
        require(_reputationBoost > 0, "Reputation boost must be positive.");

        oracleAttestations[_user].push(Attestation({
            oracleAddress: msg.sender,
            reputationBoost: _reputationBoost,
            details: _attestationDetails,
            timestamp: block.timestamp
        }));

        userReputations[_user] += _reputationBoost;
        emit ReputationUpdated(_user, userReputations[_user], string(abi.encodePacked("Oracle attestation: ", _attestationDetails)));
        emit OracleAttestationSubmitted(_user, msg.sender, _reputationBoost, _attestationDetails);
    }

    /**
     * @dev Retrieves the attestations made by oracles for a specific user.
     * @param _user The address of the user.
     * @return An array of Attestation structs for the user.
     */
    function getOracleAttestations(address _user) external view returns (Attestation[] memory) {
        return oracleAttestations[_user];
    }


    // --- Reputation Decay Functions ---

    /**
     * @dev Admin function to set the reputation decay rate.
     * @param _decayRate The new reputation decay rate (percentage).
     */
    function setReputationDecayRate(uint256 _decayRate) external onlyAdmin whenNotPaused {
        reputationDecayRate = _decayRate;
    }

    /**
     * @dev Retrieves the current reputation decay rate.
     * @return The reputation decay rate (percentage).
     */
    function getReputationDecayRate() external view returns (uint256) {
        return reputationDecayRate;
    }

    /**
     * @dev Applies reputation decay to all registered users if the decay period has passed.
     *      This function can be called automatically by a keeper/cron job or triggered manually.
     */
    function applyReputationDecay() external whenNotPaused {
        if (block.timestamp >= lastDecayTimestamp + decayPeriod) {
            uint256 usersAffected = 0;
            for (address user in getUserList()) { // Iterate through registered users (using helper function)
                if (isUserRegistered[user] && userReputations[user] > 0) {
                    uint256 decayAmount = (userReputations[user] * reputationDecayRate) / 100; // Calculate decay percentage
                    userReputations[user] = userReputations[user] > decayAmount ? userReputations[user] - decayAmount : 0;
                    usersAffected++;
                    emit ReputationUpdated(user, userReputations[user], "Reputation decay applied.");
                }
            }
            lastDecayTimestamp = block.timestamp; // Update last decay timestamp
            emit ReputationDecayApplied(usersAffected, lastDecayTimestamp);
        }
    }

    /**
     * @dev Helper function to get a list of registered users. (Simplified iteration - consider more efficient methods for large user bases)
     *      In a real-world scenario, consider using a more efficient data structure for iterating through users if the user base is very large.
     * @return An array of registered user addresses.
     */
    function getUserList() private view returns (address[] memory) {
        address[] memory userList = new address[](getUserCount());
        uint256 index = 0;
        for (address userAddress in isUserRegistered) { // Iterate through the mapping keys
            if (isUserRegistered[userAddress]) {
                userList[index] = userAddress;
                index++;
            }
        }
        return userList;
    }

    /**
     * @dev Helper function to count the number of registered users. (For demonstration, consider more efficient methods)
     * @return The count of registered users.
     */
    function getUserCount() private view returns (uint256) {
        uint256 count = 0;
        for (address userAddress in isUserRegistered) {
            if (isUserRegistered[userAddress]) {
                count++;
            }
        }
        return count;
    }


    // --- Action Weight Configuration ---

    /**
     * @dev Admin function to set the reputation weight for a specific action type.
     * @param _actionType The ActionType enum value.
     * @param _weight The new reputation weight for the action type.
     */
    function setReputationActionWeight(ActionType _actionType, uint256 _weight) external onlyAdmin whenNotPaused {
        reputationActionWeights[_actionType] = _weight;
    }

    /**
     * @dev Retrieves the reputation weight for a specific action type.
     * @param _actionType The ActionType enum value.
     * @return The reputation weight for the action type.
     */
    function getReputationActionWeight(ActionType _actionType) external view returns (uint256) {
        return reputationActionWeights[_actionType];
    }


    // --- Contract Pause and Admin Functions ---

    /**
     * @dev Pauses the contract, preventing most state-changing functions from being called.
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing normal functionality.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Checks if the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isContractPaused() external view returns (bool) {
        return paused;
    }

    /**
     * @dev Allows the current admin to transfer administrative control to a new address.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /**
     * @dev Retrieves the current contract administrator address.
     * @return The address of the contract administrator.
     */
    function getAdmin() external view returns (address) {
        return admin;
    }

    /**
     * @dev Allows the admin to withdraw ETH from the contract in case of emergency.
     * @param _recipient The address to send the ETH to.
     * @param _amount The amount of ETH to withdraw (in wei).
     */
    function emergencyWithdraw(address _recipient, uint256 _amount) external onlyAdmin whenPaused {
        require(_recipient != address(0), "Recipient address cannot be zero.");
        require(address(this).balance >= _amount, "Insufficient contract balance.");

        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "ETH withdrawal failed.");
        emit EmergencyWithdrawal(address(0), _recipient, _amount, msg.sender); // 0 address for ETH
    }

     /**
     * @dev Admin function to view the contract's ETH balance.
     * @return The contract's ETH balance in wei.
     */
    function getPlatformBalance() external view onlyAdmin returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Admin function to recover accidentally sent tokens to the contract.
     * @param _tokenAddress The address of the ERC20 token.
     * @param _recipient The address to send the tokens to.
     * @param _amount The amount of tokens to recover.
     */
    function recoverStuckTokens(address _tokenAddress, address _recipient, uint256 _amount) external onlyAdmin whenPaused {
        require(_tokenAddress != address(0) && _tokenAddress != address(this), "Invalid token address.");
        require(_recipient != address(0), "Recipient address cannot be zero.");

        IERC20 token = IERC20(_tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient token balance in contract.");

        bool success = token.transfer(_recipient, _amount);
        require(success, "Token transfer failed.");
        emit StuckTokensRecovered(_tokenAddress, _recipient, _amount, msg.sender);
    }


    // --- Helper Function to Convert ActionType to String for Events ---
    function actionTypeToString(ActionType _actionType) private pure returns (string memory) {
        if (_actionType == ActionType.CONTENT_CREATION) {
            return "Content Creation";
        } else if (_actionType == ActionType.POSITIVE_INTERACTION) {
            return "Positive Interaction";
        } else if (_actionType == ActionType.COMMUNITY_CONTRIBUTION) {
            return "Community Contribution";
        } else if (_actionType == ActionType.PLATFORM_USAGE) {
            return "Platform Usage";
        } else if (_actionType == ActionType.REPORT_SUBMISSION) {
            return "Report Submission";
        } else {
            return "Unknown Action Type";
        }
    }
}


// --- Interface for ERC20 Token for Token Recovery Function ---
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    // Add other ERC20 functions if needed for more advanced token handling
}
```