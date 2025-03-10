```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation Oracle (DRO)
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a decentralized reputation system with advanced features.
 *
 * Outline and Function Summary:
 *
 * 1.  **Core Reputation Management:**
 *     - `addReputationType(string _typeName)`: Allows the contract owner to add new reputation types (e.g., "Coder", "CommunityModerator", "Trader").
 *     - `giveReputation(address _target, uint256 _reputationTypeId, uint256 _amount, string _feedback)`: Allows users to give reputation to other users, specifying the type, amount, and feedback.
 *     - `takeReputation(address _target, uint256 _reputationTypeId, uint256 _amount, string _feedback)`: Allows users to take away reputation from other users (with potential restrictions/governance).
 *     - `getReputation(address _user, uint256 _reputationTypeId)`: Retrieves the reputation score of a user for a specific reputation type.
 *     - `getAllReputationTypes()`: Returns a list of all registered reputation type names.
 *     - `getReputationTypeCount()`: Returns the total number of registered reputation types.
 *     - `getUserReputationTypes(address _user)`: Returns a list of reputation types for which a user has received reputation.
 *
 * 2.  **Reputation Decay and Dynamics:**
 *     - `setReputationDecayRate(uint256 _reputationTypeId, uint256 _decayRate)`: Sets the decay rate for a specific reputation type. Reputation decays over time to prevent stagnation.
 *     - `applyReputationDecay()`: An internal function (or can be triggered by an external oracle/keeper) to apply reputation decay to all users and reputation types.
 *     - `getLastReputationUpdate(address _user, uint256 _reputationTypeId)`: Returns the timestamp of the last reputation update for a user and type.
 *
 * 3.  **Reputation Thresholds and Tiers:**
 *     - `setReputationThreshold(uint256 _reputationTypeId, uint256 _threshold, string _tierName)`: Allows the owner to define reputation thresholds and associate tier names with them.
 *     - `getTierForReputation(address _user, uint256 _reputationTypeId)`: Returns the tier name associated with a user's reputation for a specific type.
 *     - `getThresholdForTier(uint256 _reputationTypeId, string _tierName)`: Returns the reputation threshold for a specific tier name and reputation type.
 *     - `getAllTiersForType(uint256 _reputationTypeId)`: Returns a list of all tier names defined for a reputation type.
 *
 * 4.  **Reputation-Gated Functions (Example - Placeholder):**
 *     - `gatedFunctionExample(uint256 _reputationTypeId, uint256 _minReputation)`: An example function demonstrating how to use reputation to gate access to certain functionalities.
 *
 * 5.  **Feedback and Reporting:**
 *     - `getFeedbackHistory(address _user, uint256 _reputationTypeId)`: Retrieves the history of feedback given to a user for a specific reputation type.
 *     - `reportUser(address _reportedUser, uint256 _reputationTypeId, string _reportReason)`: Allows users to report other users for negative behavior, potentially triggering reputation reduction (requires careful implementation and governance).
 *     - `resolveReport(address _reportedUser, uint256 _reputationTypeId, bool _punish)`: (Admin/Governance function) Resolves a user report, potentially reducing reputation if `_punish` is true.
 *
 * 6.  **Governance and Administration:**
 *     - `transferOwnership(address _newOwner)`: Standard contract ownership transfer.
 *     - `pauseContract()`: Pauses the contract, preventing reputation updates (emergency measure).
 *     - `unpauseContract()`: Unpauses the contract.
 *     - `isContractPaused()`: Returns whether the contract is currently paused.
 *
 * 7.  **Advanced Features (Conceptual - Can be expanded):**
 *     - `requestReputationBoost(uint256 _reputationTypeId, string _justification)`: Users can request a reputation boost for a specific type, subject to admin approval or voting (can be expanded with governance mechanisms).
 *     - `delegateReputation(uint256 _reputationTypeId, address _delegateTo)`: Allows users to delegate their reputation for a specific type to another address (for voting power, etc.).
 *     - `revokeDelegation(uint256 _reputationTypeId)`: Revokes reputation delegation.
 *     - `getDelegate(address _user, uint256 _reputationTypeId)`: Returns the address a user has delegated their reputation to for a specific type.
 */

contract DecentralizedReputationOracle {
    address public owner;
    bool public paused;

    // Struct to represent a reputation type
    struct ReputationType {
        string name;
        uint256 decayRate; // Percentage decay per time unit (e.g., per day)
        mapping(string => uint256) tiers; // Tier names to reputation thresholds
        string[] tierNames; // Array to store tier names in order
    }

    // Mapping of reputation type IDs to ReputationType structs
    mapping(uint256 => ReputationType) public reputationTypes;
    string[] public reputationTypeNames; // Array to store reputation type names in order
    uint256 public reputationTypeCount;

    // Mapping of user address to reputation type ID to reputation score
    mapping(address => mapping(uint256 => uint256)) public userReputations;
    mapping(address => mapping(uint256 => uint256)) public lastReputationUpdate; // Timestamp of last update

    // Mapping of user address to reputation type ID to feedback history (can be optimized for gas)
    mapping(address => mapping(uint256 => string[])) public feedbackHistory;

    // Mapping of user address to reputation type ID to reports
    mapping(address => mapping(uint256 => string[])) public reports;

    // Mapping of user address to reputation type ID to delegated address
    mapping(address => mapping(uint256 => address)) public reputationDelegations;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event ReputationTypeAdded(uint256 reputationTypeId, string typeName, address indexed addedBy);
    event ReputationGiven(address indexed targetUser, uint256 reputationTypeId, uint256 amount, address indexed giver, string feedback);
    event ReputationTaken(address indexed targetUser, uint256 reputationTypeId, uint256 amount, address indexed taker, string feedback);
    event ReputationDecayed(address indexed user, uint256 reputationTypeId, uint256 decayedAmount);
    event ReputationThresholdSet(uint256 reputationTypeId, uint256 threshold, string tierName, address indexed setter);
    event UserReported(address indexed reportedUser, uint256 reputationTypeId, address indexed reporter, string reportReason);
    event ReportResolved(address indexed reportedUser, uint256 reputationTypeId, bool punished, address indexed resolver);
    event ReputationDelegated(address indexed delegator, uint256 reputationTypeId, address indexed delegateTo);
    event ReputationDelegationRevoked(address indexed delegator, uint256 reputationTypeId);
    event ReputationBoostRequested(address indexed requester, uint256 reputationTypeId, string justification);


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

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
        paused = false;
        reputationTypeCount = 0;
    }

    /**
     * @dev Transfers contract ownership to a new address.
     * @param _newOwner The address of the new owner.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Pauses the contract, preventing most state-changing operations.
     */
    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Unpauses the contract, allowing normal operations.
     */
    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Returns whether the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isContractPaused() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Adds a new reputation type to the system. Only callable by the contract owner.
     * @param _typeName The name of the new reputation type (e.g., "Coder", "Trader").
     */
    function addReputationType(string memory _typeName) public onlyOwner whenNotPaused {
        require(bytes(_typeName).length > 0, "Reputation type name cannot be empty.");
        require(!_reputationTypeExists(_typeName), "Reputation type already exists.");

        reputationTypes[reputationTypeCount] = ReputationType({
            name: _typeName,
            decayRate: 0, // Default decay rate is 0
            tierNames: new string[](0) // Initialize empty tier names array
        });
        reputationTypeNames.push(_typeName);
        emit ReputationTypeAdded(reputationTypeCount, _typeName, msg.sender);
        reputationTypeCount++;
    }

    /**
     * @dev Internal helper function to check if a reputation type name already exists.
     * @param _typeName The name to check.
     * @return True if the type exists, false otherwise.
     */
    function _reputationTypeExists(string memory _typeName) internal view returns (bool) {
        for (uint256 i = 0; i < reputationTypeCount; i++) {
            if (keccak256(bytes(reputationTypes[i].name)) == keccak256(bytes(_typeName))) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Allows a user to give reputation to another user for a specific reputation type.
     * @param _target The address of the user receiving reputation.
     * @param _reputationTypeId The ID of the reputation type.
     * @param _amount The amount of reputation to give.
     * @param _feedback Optional feedback message.
     */
    function giveReputation(address _target, uint256 _reputationTypeId, uint256 _amount, string memory _feedback) public whenNotPaused {
        require(_target != address(0) && _target != msg.sender, "Invalid target address.");
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        require(_amount > 0, "Reputation amount must be positive.");

        userReputations[_target][_reputationTypeId] += _amount;
        lastReputationUpdate[_target][_reputationTypeId] = block.timestamp;
        if (bytes(_feedback).length > 0) {
            feedbackHistory[_target][_reputationTypeId].push(_feedback);
        }
        emit ReputationGiven(_target, _reputationTypeId, _amount, msg.sender, _feedback);
    }

    /**
     * @dev Allows a user to take away reputation from another user. Requires careful consideration of access control.
     *      For this example, any user can take reputation, but in a real application, this should be restricted.
     * @param _target The address of the user losing reputation.
     * @param _reputationTypeId The ID of the reputation type.
     * @param _amount The amount of reputation to take away.
     * @param _feedback Optional feedback message.
     */
    function takeReputation(address _target, uint256 _reputationTypeId, uint256 _amount, string memory _feedback) public whenNotPaused {
        require(_target != address(0) && _target != msg.sender, "Invalid target address.");
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        require(_amount > 0, "Reputation amount must be positive.");
        require(userReputations[_target][_reputationTypeId] >= _amount, "Not enough reputation to take.");

        userReputations[_target][_reputationTypeId] -= _amount;
        lastReputationUpdate[_target][_reputationTypeId] = block.timestamp;
        if (bytes(_feedback).length > 0) {
            feedbackHistory[_target][_reputationTypeId].push(_feedback);
        }
        emit ReputationTaken(_target, _reputationTypeId, _amount, msg.sender, _feedback);
    }

    /**
     * @dev Retrieves the reputation score of a user for a specific reputation type.
     * @param _user The address of the user.
     * @param _reputationTypeId The ID of the reputation type.
     * @return The reputation score.
     */
    function getReputation(address _user, uint256 _reputationTypeId) public view returns (uint256) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        return userReputations[_user][_reputationTypeId];
    }

    /**
     * @dev Retrieves the timestamp of the last reputation update for a user and type.
     * @param _user The address of the user.
     * @param _reputationTypeId The ID of the reputation type.
     * @return The timestamp of the last update.
     */
    function getLastReputationUpdate(address _user, uint256 _reputationTypeId) public view returns (uint256) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        return lastReputationUpdate[_user][_reputationTypeId];
    }

    /**
     * @dev Sets the decay rate for a specific reputation type. Only callable by the contract owner.
     * @param _reputationTypeId The ID of the reputation type.
     * @param _decayRate The new decay rate (percentage, e.g., 10 for 10% per decay period).
     */
    function setReputationDecayRate(uint256 _reputationTypeId, uint256 _decayRate) public onlyOwner whenNotPaused {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        reputationTypes[_reputationTypeId].decayRate = _decayRate;
    }

    /**
     * @dev Internal function to apply reputation decay to all users for all reputation types.
     *      Can be triggered by an external oracle/keeper or called periodically by the owner.
     */
    function applyReputationDecay() public whenNotPaused { // Make public for example, consider making it internal and trigger via keeper
        for (uint256 typeId = 0; typeId < reputationTypeCount; typeId++) {
            uint256 decayRate = reputationTypes[typeId].decayRate;
            if (decayRate > 0) {
                for (uint256 i = 0; i < reputationTypeNames.length; i++) { // Iterate through user addresses (inefficient in practice, needs optimization for real use)
                    // In a real system, you'd need a more efficient way to iterate through users with reputation
                    // This is just a placeholder for demonstration.
                    // A better approach would be to track users who have reputation and iterate over that list.
                    address userAddress; // Placeholder, needs actual user address iteration
                    if (userReputations[userAddress][typeId] > 0) { // Check if user has reputation for this type
                        uint256 lastUpdate = lastReputationUpdate[userAddress][typeId];
                        uint256 timeElapsed = block.timestamp - lastUpdate;
                        // Define a decay period (e.g., daily decay). For simplicity, assume decay is applied every block if decayRate > 0.
                        if (timeElapsed > 0) { // Apply decay if time has passed since last update
                            uint256 currentReputation = userReputations[userAddress][typeId];
                            uint256 decayAmount = (currentReputation * decayRate) / 100; // Calculate decay amount
                            if (decayAmount > currentReputation) {
                                decayAmount = currentReputation; // Don't let reputation go negative
                            }
                            userReputations[userAddress][typeId] -= decayAmount;
                            lastReputationUpdate[userAddress][typeId] = block.timestamp;
                            emit ReputationDecayed(userAddress, typeId, decayAmount);
                        }
                    }
                }
            }
        }
    }

    /**
     * @dev Sets a reputation threshold and associates a tier name with it for a specific reputation type.
     *      Only callable by the contract owner.
     * @param _reputationTypeId The ID of the reputation type.
     * @param _threshold The reputation threshold value.
     * @param _tierName The name of the tier associated with this threshold.
     */
    function setReputationThreshold(uint256 _reputationTypeId, uint256 _threshold, string memory _tierName) public onlyOwner whenNotPaused {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        require(bytes(_tierName).length > 0, "Tier name cannot be empty.");
        reputationTypes[_reputationTypeId].tiers[_tierName] = _threshold;
        reputationTypes[_reputationTypeId].tierNames.push(_tierName);
        emit ReputationThresholdSet(_reputationTypeId, _threshold, _tierName, msg.sender);
    }

    /**
     * @dev Gets the tier name for a user based on their reputation for a specific type.
     * @param _user The address of the user.
     * @param _reputationTypeId The ID of the reputation type.
     * @return The tier name, or an empty string if no tier is reached.
     */
    function getTierForReputation(address _user, uint256 _reputationTypeId) public view returns (string memory) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        uint256 reputation = userReputations[_user][_reputationTypeId];
        string[] memory tierNames = reputationTypes[_reputationTypeId].tierNames;
        for (uint256 i = tierNames.length; i > 0; i--) { // Iterate in reverse to find highest tier first
            string memory tierName = tierNames[i-1];
            if (reputation >= reputationTypes[_reputationTypeId].tiers[tierName]) {
                return tierName;
            }
        }
        return ""; // No tier reached
    }

    /**
     * @dev Gets the reputation threshold for a specific tier name and reputation type.
     * @param _reputationTypeId The ID of the reputation type.
     * @param _tierName The name of the tier.
     * @return The reputation threshold, or 0 if the tier is not found.
     */
    function getThresholdForTier(uint256 _reputationTypeId, string memory _tierName) public view returns (uint256) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        return reputationTypes[_reputationTypeId].tiers[_tierName];
    }

    /**
     * @dev Gets a list of all tier names defined for a reputation type.
     * @param _reputationTypeId The ID of the reputation type.
     * @return An array of tier names.
     */
    function getAllTiersForType(uint256 _reputationTypeId) public view returns (string[] memory) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        return reputationTypes[_reputationTypeId].tierNames;
    }

    /**
     * @dev Example function demonstrating reputation-gated access.
     *      Only users with at least `_minReputation` of `_reputationTypeId` can call this function.
     * @param _reputationTypeId The ID of the reputation type required.
     * @param _minReputation The minimum reputation score required.
     * @return A message indicating success if access is granted.
     */
    function gatedFunctionExample(uint256 _reputationTypeId, uint256 _minReputation) public view returns (string memory) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        require(userReputations[msg.sender][_reputationTypeId] >= _minReputation, "Insufficient reputation to access this function.");
        return "Access granted! Reputation sufficient.";
    }

    /**
     * @dev Retrieves the feedback history for a user and reputation type.
     * @param _user The address of the user.
     * @param _reputationTypeId The ID of the reputation type.
     * @return An array of feedback strings.
     */
    function getFeedbackHistory(address _user, uint256 _reputationTypeId) public view returns (string[] memory) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        return feedbackHistory[_user][_reputationTypeId];
    }

    /**
     * @dev Allows a user to report another user for negative behavior related to a reputation type.
     * @param _reportedUser The address of the user being reported.
     * @param _reputationTypeId The ID of the reputation type the report relates to.
     * @param _reportReason The reason for the report.
     */
    function reportUser(address _reportedUser, uint256 _reputationTypeId, string memory _reportReason) public whenNotPaused {
        require(_reportedUser != address(0) && _reportedUser != msg.sender, "Invalid reported user address.");
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        require(bytes(_reportReason).length > 0, "Report reason cannot be empty.");

        reports[_reportedUser][_reputationTypeId].push(_reportReason);
        emit UserReported(_reportedUser, _reputationTypeId, msg.sender, _reportReason);
    }

    /**
     * @dev Allows the contract owner to resolve a report against a user and potentially punish them by reducing reputation.
     * @param _reportedUser The address of the reported user.
     * @param _reputationTypeId The ID of the reputation type related to the report.
     * @param _punish True to reduce reputation, false otherwise.
     */
    function resolveReport(address _reportedUser, uint256 _reputationTypeId, bool _punish) public onlyOwner whenNotPaused {
        require(_reportedUser != address(0), "Invalid reported user address.");
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");

        if (_punish) {
            // Example: Reduce reputation by a fixed amount upon report resolution.
            uint256 reputationReduction = 10; // Define a fixed reduction amount
            if (userReputations[_reportedUser][_reputationTypeId] >= reputationReduction) {
                userReputations[_reportedUser][_reputationTypeId] -= reputationReduction;
            } else {
                userReputations[_reportedUser][_reputationTypeId] = 0; // Set to 0 if reputation is less than reduction
            }
        }
        // In a real application, you might want to clear the reports for this user and type after resolution.
        delete reports[_reportedUser][_reputationTypeId]; // Clear reports after resolution (optional)
        emit ReportResolved(_reportedUser, _reputationTypeId, _punish, msg.sender);
    }

    /**
     * @dev Gets a list of all registered reputation type names.
     * @return An array of reputation type names.
     */
    function getAllReputationTypes() public view returns (string[] memory) {
        return reputationTypeNames;
    }

    /**
     * @dev Gets the total number of registered reputation types.
     * @return The count of reputation types.
     */
    function getReputationTypeCount() public view returns (uint256) {
        return reputationTypeCount;
    }

    /**
     * @dev Gets a list of reputation types for which a user has received reputation.
     * @param _user The address of the user.
     * @return An array of reputation type IDs.
     */
    function getUserReputationTypes(address _user) public view returns (uint256[] memory) {
        uint256[] memory userTypes = new uint256[](reputationTypeCount); // Max possible types
        uint256 count = 0;
        for (uint256 typeId = 0; typeId < reputationTypeCount; typeId++) {
            if (userReputations[_user][typeId] > 0) {
                userTypes[count] = typeId;
                count++;
            }
        }
        // Resize array to actual count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userTypes[i];
        }
        return result;
    }

    /**
     * @dev Allows a user to request a reputation boost for a specific type.
     *      This is a conceptual function that could be expanded with governance or admin approval.
     * @param _reputationTypeId The ID of the reputation type.
     * @param _justification The reason for requesting a boost.
     */
    function requestReputationBoost(uint256 _reputationTypeId, string memory _justification) public whenNotPaused {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        require(bytes(_justification).length > 0, "Justification cannot be empty.");

        // In a real application, this would trigger a process for admin review or community voting.
        // For now, just emit an event.
        emit ReputationBoostRequested(msg.sender, _reputationTypeId, _justification);
        // To implement actual boost approval, you'd need to add admin/governance functions
        // to review requests and grant boosts (e.g., update userReputations[_requester][_reputationTypeId]).
    }

    /**
     * @dev Allows a user to delegate their reputation for a specific type to another address.
     *      This is useful for scenarios like voting power delegation.
     * @param _reputationTypeId The ID of the reputation type to delegate.
     * @param _delegateTo The address to delegate reputation to.
     */
    function delegateReputation(uint256 _reputationTypeId, address _delegateTo) public whenNotPaused {
        require(_delegateTo != address(0) && _delegateTo != msg.sender, "Invalid delegate address.");
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");

        reputationDelegations[msg.sender][_reputationTypeId] = _delegateTo;
        emit ReputationDelegated(msg.sender, _reputationTypeId, _delegateTo);
    }

    /**
     * @dev Revokes reputation delegation for a specific reputation type.
     * @param _reputationTypeId The ID of the reputation type to revoke delegation for.
     */
    function revokeDelegation(uint256 _reputationTypeId) public whenNotPaused {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");

        delete reputationDelegations[msg.sender][_reputationTypeId];
        emit ReputationDelegationRevoked(msg.sender, _reputationTypeId);
    }

    /**
     * @dev Gets the address a user has delegated their reputation to for a specific type.
     * @param _user The address of the delegator.
     * @param _reputationTypeId The ID of the reputation type.
     * @return The address of the delegate, or address(0) if no delegation exists.
     */
    function getDelegate(address _user, uint256 _reputationTypeId) public view returns (address) {
        require(_reputationTypeId < reputationTypeCount, "Invalid reputation type ID.");
        return reputationDelegations[_user][_reputationTypeId];
    }
}
```