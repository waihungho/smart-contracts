```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Reputation and Access Control System
 * @author Bard (AI Assistant)
 * @dev A smart contract implementing a dynamic reputation system with advanced features.
 * It allows for reputation accumulation based on various actions, reputation decay,
 * level-based access control, dynamic feature gating, reputation delegation,
 * and integrates with external NFTs for enhanced reputation and access management.
 *
 * Function Summary:
 * -----------------
 * **Core Reputation Management:**
 * 1. awardReputation(address _user, uint256 _amount, string memory _reason): Awards reputation points to a user.
 * 2. revokeReputation(address _user, uint256 _amount, string memory _reason): Revokes reputation points from a user.
 * 3. getUserReputation(address _user): Returns the current reputation points of a user.
 * 4. applyReputationDecay(): Applies reputation decay to all users based on time.
 * 5. setDecayRate(uint256 _newRate):  Sets the reputation decay rate (percentage per time period).
 * 6. getDecayRate(): Returns the current reputation decay rate.
 * 7. setDecayInterval(uint256 _newInterval): Sets the time interval for reputation decay application.
 * 8. getDecayInterval(): Returns the current reputation decay interval.
 *
 * **Reputation Levels and Access Control:**
 * 9. createReputationLevel(uint256 _threshold, string memory _levelName, string memory _description): Defines a new reputation level.
 * 10. editReputationLevel(uint256 _levelId, uint256 _newThreshold, string memory _newLevelName, string memory _newDescription): Edits an existing reputation level.
 * 11. getReputationLevelDetails(uint256 _levelId): Returns details of a specific reputation level.
 * 12. getLevelForReputation(address _user): Returns the reputation level name for a user based on their reputation points.
 * 13. isLevelMet(address _user, uint256 _levelId): Checks if a user meets the reputation threshold for a specific level.
 * 14. grantLevelBasedAccess(address _user, uint256 _levelId, string memory _featureName): Grants access to a feature for a user based on their reputation level.
 * 15. revokeLevelBasedAccess(address _user, uint256 _levelId, string memory _featureName): Revokes level-based access to a feature for a user.
 * 16. hasLevelBasedAccess(address _user, uint256 _levelId, string memory _featureName): Checks if a user has level-based access to a feature.
 *
 * **Dynamic Feature Gating & Reputation Delegation:**
 * 17. createDynamicFeatureGate(string memory _featureName, address _gatingLogicContract): Creates a dynamic feature gate controlled by an external contract.
 * 18. checkDynamicFeatureAccess(address _user, string memory _featureName): Checks if a user has access to a dynamically gated feature (queries external contract).
 * 19. delegateReputation(address _delegate, uint256 _amount, uint256 _durationSeconds): Allows a user to delegate a portion of their reputation to another user for a limited time.
 * 20. revokeDelegation(address _delegate): Revokes reputation delegation from a user.
 * 21. getDelegatedReputation(address _delegate): Returns the amount of reputation delegated to a user.
 * 22. getDelegationExpiration(address _delegate): Returns the expiration timestamp of reputation delegation for a user.
 *
 * **NFT Reputation Integration (Advanced):**
 * 23. bindNFTBoost(address _nftContract, uint256 _tokenId, uint256 _boostPercentage, uint256 _boostDurationSeconds): Binds an NFT to a reputation boost for the NFT owner.
 * 24. getNFTBoost(address _user): Returns the current reputation boost applied from NFTs for a user.
 * 25. isNFTBoostActive(address _user): Checks if an NFT reputation boost is currently active for a user.
 *
 * **Admin and Utility Functions:**
 * 26. setAdmin(address _newAdmin): Sets a new admin address.
 * 27. getAdmin(): Returns the current admin address.
 * 28. pauseContract(): Pauses the contract functionality (except admin functions).
 * 29. unpauseContract(): Unpauses the contract functionality.
 * 30. isPaused(): Returns whether the contract is currently paused.
 */
contract DynamicReputationSystem {
    // --- State Variables ---

    address public admin;
    bool public paused;

    // User reputation points
    mapping(address => uint256) public userReputation;

    // Reputation decay settings
    uint256 public decayRatePercentage = 5; // 5% decay per interval
    uint256 public decayIntervalSeconds = 86400; // 1 day
    uint256 public lastDecayApplicationTime;

    // Reputation Levels
    struct ReputationLevel {
        uint256 threshold;
        string name;
        string description;
    }
    mapping(uint256 => ReputationLevel) public reputationLevels;
    uint256 public levelCount;

    // Level-based access control
    mapping(address => mapping(uint256 => mapping(string => bool))) public levelBasedAccess; // user => levelId => featureName => hasAccess

    // Dynamic Feature Gates
    mapping(string => address) public dynamicFeatureGates; // featureName => gatingLogicContractAddress

    // Reputation Delegation
    struct Delegation {
        uint256 amount;
        uint256 expirationTime;
    }
    mapping(address => Delegation) public reputationDelegations; // delegateAddress => Delegation details

    // NFT Reputation Boost
    struct NFTBoost {
        uint256 boostPercentage;
        uint256 expirationTime;
    }
    mapping(address => NFTBoost) public nftBoosts; // userAddress => NFTBoost details


    // --- Events ---

    event ReputationAwarded(address indexed user, uint256 amount, string reason);
    event ReputationRevoked(address indexed user, uint256 amount, string reason);
    event ReputationDecayApplied();
    event DecayRateUpdated(uint256 newRate);
    event DecayIntervalUpdated(uint256 newInterval);
    event ReputationLevelCreated(uint256 levelId, uint256 threshold, string name, string description);
    event ReputationLevelEdited(uint256 levelId, uint256 newThreshold, string newName, string newDescription);
    event LevelBasedAccessGranted(address indexed user, uint256 levelId, string featureName);
    event LevelBasedAccessRevoked(address indexed user, uint256 levelId, string featureName);
    event DynamicFeatureGateCreated(string featureName, address gatingLogicContract);
    event ReputationDelegated(address indexed delegator, address indexed delegate, uint256 amount, uint256 expirationTime);
    event DelegationRevoked(address indexed delegate);
    event NFTBoostBound(address indexed user, address nftContract, uint256 tokenId, uint256 boostPercentage, uint256 boostDurationSeconds);
    event AdminChanged(address newAdmin);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
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


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
        lastDecayApplicationTime = block.timestamp;
    }


    // --- Core Reputation Management Functions ---

    /**
     * @dev Awards reputation points to a user.
     * @param _user The address of the user to award reputation to.
     * @param _amount The amount of reputation points to award.
     * @param _reason A string describing the reason for awarding reputation.
     */
    function awardReputation(address _user, uint256 _amount, string memory _reason) external onlyAdmin whenNotPaused {
        userReputation[_user] += _amount;
        emit ReputationAwarded(_user, _amount, _reason);
    }

    /**
     * @dev Revokes reputation points from a user.
     * @param _user The address of the user to revoke reputation from.
     * @param _amount The amount of reputation points to revoke.
     * @param _reason A string describing the reason for revoking reputation.
     */
    function revokeReputation(address _user, uint256 _amount, string memory _reason) external onlyAdmin whenNotPaused {
        require(userReputation[_user] >= _amount, "Insufficient reputation to revoke.");
        userReputation[_user] -= _amount;
        emit ReputationRevoked(_user, _amount, _reason);
    }

    /**
     * @dev Returns the current reputation points of a user.
     * @param _user The address of the user to query.
     * @return The reputation points of the user.
     */
    function getUserReputation(address _user) external view returns (uint256) {
        uint256 baseReputation = userReputation[_user];
        uint256 nftBoost = getNFTBoost(_user);
        return baseReputation + (baseReputation * nftBoost / 100); // Apply NFT boost
    }


    /**
     * @dev Applies reputation decay to all users based on time elapsed since the last decay application.
     */
    function applyReputationDecay() public whenNotPaused {
        if (block.timestamp >= lastDecayApplicationTime + decayIntervalSeconds) {
            for (uint256 i = 0; i < levelCount; i++) { // Iterate through levels as a proxy for users (can be optimized in a real-world scenario if needed)
                if (reputationLevels[i+1].threshold > 0) { // Basic check to iterate and find users with reputation
                    // In a real application, you might need a more efficient way to track active users.
                    // This is a simplified example for demonstration.
                    address userAddress;
                    for(uint j=0; j< 1000; j++){ // simple iteration over addresses, not scalable for large user base, improve in production
                        userAddress = address(uint160(uint256(keccak256(abi.encodePacked(i,j))))); // simple deterministic address generation for example
                        if(userReputation[userAddress] > 0){
                             uint256 decayAmount = (userReputation[userAddress] * decayRatePercentage) / 100;
                             userReputation[userAddress] -= decayAmount;
                        }
                    }
                }
            }
            lastDecayApplicationTime = block.timestamp;
            emit ReputationDecayApplied();
        }
    }

    /**
     * @dev Sets the reputation decay rate (percentage per time period).
     * @param _newRate The new decay rate percentage.
     */
    function setDecayRate(uint256 _newRate) external onlyAdmin whenNotPaused {
        decayRatePercentage = _newRate;
        emit DecayRateUpdated(_newRate);
    }

    /**
     * @dev Returns the current reputation decay rate.
     * @return The current decay rate percentage.
     */
    function getDecayRate() external view returns (uint256) {
        return decayRatePercentage;
    }

    /**
     * @dev Sets the time interval for reputation decay application.
     * @param _newInterval The new decay interval in seconds.
     */
    function setDecayInterval(uint256 _newInterval) external onlyAdmin whenNotPaused {
        decayIntervalSeconds = _newInterval;
        lastDecayApplicationTime = block.timestamp; // Reset last application time to avoid immediate decay
        emit DecayIntervalUpdated(_newInterval);
    }

    /**
     * @dev Returns the current reputation decay interval.
     * @return The current decay interval in seconds.
     */
    function getDecayInterval() external view returns (uint256) {
        return decayIntervalSeconds;
    }


    // --- Reputation Levels and Access Control Functions ---

    /**
     * @dev Defines a new reputation level.
     * @param _threshold The reputation points threshold for this level.
     * @param _levelName The name of the reputation level.
     * @param _description A description of the reputation level.
     */
    function createReputationLevel(uint256 _threshold, string memory _levelName, string memory _description) external onlyAdmin whenNotPaused {
        levelCount++;
        reputationLevels[levelCount] = ReputationLevel(_threshold, _levelName, _description);
        emit ReputationLevelCreated(levelCount, _threshold, _levelName, _description);
    }

    /**
     * @dev Edits an existing reputation level.
     * @param _levelId The ID of the reputation level to edit.
     * @param _newThreshold The new reputation points threshold.
     * @param _newLevelName The new name of the reputation level.
     * @param _newDescription The new description of the reputation level.
     */
    function editReputationLevel(uint256 _levelId, uint256 _newThreshold, string memory _newLevelName, string memory _newDescription) external onlyAdmin whenNotPaused {
        require(_levelId > 0 && _levelId <= levelCount, "Invalid level ID.");
        reputationLevels[_levelId] = ReputationLevel(_newThreshold, _newLevelName, _newDescription);
        emit ReputationLevelEdited(_levelId, _newThreshold, _newName, _newDescription);
    }

    /**
     * @dev Returns details of a specific reputation level.
     * @param _levelId The ID of the reputation level to query.
     * @return The details of the reputation level (threshold, name, description).
     */
    function getReputationLevelDetails(uint256 _levelId) external view returns (uint256 threshold, string memory name, string memory description) {
        require(_levelId > 0 && _levelId <= levelCount, "Invalid level ID.");
        ReputationLevel memory level = reputationLevels[_levelId];
        return (level.threshold, level.name, level.description);
    }

    /**
     * @dev Returns the reputation level name for a user based on their reputation points.
     * @param _user The address of the user to query.
     * @return The name of the reputation level or "None" if no level is reached.
     */
    function getLevelForReputation(address _user) external view returns (string memory) {
        uint256 reputation = getUserReputation(_user);
        for (uint256 i = levelCount; i >= 1; i--) {
            if (reputation >= reputationLevels[i].threshold) {
                return reputationLevels[i].name;
            }
        }
        return "None"; // No level reached
    }

    /**
     * @dev Checks if a user meets the reputation threshold for a specific level.
     * @param _user The address of the user to check.
     * @param _levelId The ID of the reputation level.
     * @return True if the user meets the level threshold, false otherwise.
     */
    function isLevelMet(address _user, uint256 _levelId) external view returns (bool) {
        require(_levelId > 0 && _levelId <= levelCount, "Invalid level ID.");
        return getUserReputation(_user) >= reputationLevels[_levelId].threshold;
    }

    /**
     * @dev Grants access to a feature for a user based on their reputation level.
     * @param _user The address of the user to grant access to.
     * @param _levelId The ID of the reputation level required for access.
     * @param _featureName The name of the feature to grant access to.
     */
    function grantLevelBasedAccess(address _user, uint256 _levelId, string memory _featureName) external onlyAdmin whenNotPaused {
        levelBasedAccess[_user][_levelId][_featureName] = true;
        emit LevelBasedAccessGranted(_user, _levelId, _featureName);
    }

    /**
     * @dev Revokes level-based access to a feature for a user.
     * @param _user The address of the user to revoke access from.
     * @param _levelId The ID of the reputation level associated with the access.
     * @param _featureName The name of the feature to revoke access from.
     */
    function revokeLevelBasedAccess(address _user, uint256 _levelId, string memory _featureName) external onlyAdmin whenNotPaused {
        levelBasedAccess[_user][_levelId][_featureName] = false;
        emit LevelBasedAccessRevoked(_user, _levelId, _featureName);
    }

    /**
     * @dev Checks if a user has level-based access to a feature.
     * @param _user The address of the user to check.
     * @param _levelId The ID of the reputation level.
     * @param _featureName The name of the feature to check access for.
     * @return True if the user has access, false otherwise.
     */
    function hasLevelBasedAccess(address _user, uint256 _levelId, string memory _featureName) external view returns (bool) {
        return levelBasedAccess[_user][_levelId][_featureName];
    }


    // --- Dynamic Feature Gating & Reputation Delegation Functions ---

    /**
     * @dev Creates a dynamic feature gate controlled by an external contract.
     * @param _featureName The name of the feature being gated.
     * @param _gatingLogicContract The address of the external contract that determines access.
     */
    function createDynamicFeatureGate(string memory _featureName, address _gatingLogicContract) external onlyAdmin whenNotPaused {
        dynamicFeatureGates[_featureName] = _gatingLogicContract;
        emit DynamicFeatureGateCreated(_featureName, _gatingLogicContract);
    }

    /**
     * @dev Checks if a user has access to a dynamically gated feature by querying the external gating logic contract.
     * @param _user The address of the user to check.
     * @param _featureName The name of the dynamically gated feature.
     * @return True if the user has access according to the external contract, false otherwise.
     */
    function checkDynamicFeatureAccess(address _user, string memory _featureName) external view returns (bool) {
        address gatingContract = dynamicFeatureGates[_featureName];
        require(gatingContract != address(0), "Dynamic feature gate not found.");

        // Assume external contract has a function `checkAccess(address _user) returns (bool)`
        (bool success, bytes memory returnData) = gatingContract.staticcall(
            abi.encodeWithSignature("checkAccess(address)", _user)
        );
        if (success) {
            return abi.decode(returnData, (bool));
        } else {
            return false; // Default to no access if external call fails
        }
    }

    /**
     * @dev Allows a user to delegate a portion of their reputation to another user for a limited time.
     * @param _delegate The address of the user to delegate reputation to.
     * @param _amount The amount of reputation points to delegate.
     * @param _durationSeconds The duration of the delegation in seconds.
     */
    function delegateReputation(address _delegate, uint256 _amount, uint256 _durationSeconds) external whenNotPaused {
        require(_amount > 0, "Delegation amount must be positive.");
        require(getUserReputation(msg.sender) >= _amount, "Insufficient reputation to delegate.");
        require(reputationDelegations[_delegate].expirationTime < block.timestamp, "Delegate already has an active delegation, revoke first."); // Prevent overwriting active delegations

        reputationDelegations[_delegate] = Delegation({
            amount: _amount,
            expirationTime: block.timestamp + _durationSeconds
        });
        emit ReputationDelegated(msg.sender, _delegate, _amount, block.timestamp + _durationSeconds);
    }

    /**
     * @dev Revokes reputation delegation from a user.
     * @param _delegate The address of the user to revoke delegation from.
     */
    function revokeDelegation(address _delegate) external whenNotPaused {
        require(reputationDelegations[_delegate].expirationTime > block.timestamp, "No active delegation to revoke.");
        delete reputationDelegations[_delegate];
        emit DelegationRevoked(_delegate);
    }

    /**
     * @dev Returns the amount of reputation delegated to a user.
     * @param _delegate The address of the user to query.
     * @return The amount of reputation delegated, or 0 if no active delegation.
     */
    function getDelegatedReputation(address _delegate) external view returns (uint256) {
        if (reputationDelegations[_delegate].expirationTime > block.timestamp) {
            return reputationDelegations[_delegate].amount;
        } else {
            return 0; // Delegation expired or not active
        }
    }

    /**
     * @dev Returns the expiration timestamp of reputation delegation for a user.
     * @param _delegate The address of the user to query.
     * @return The expiration timestamp, or 0 if no active delegation.
     */
    function getDelegationExpiration(address _delegate) external view returns (uint256) {
        return reputationDelegations[_delegate].expirationTime;
    }


    // --- NFT Reputation Integration Functions ---

    /**
     * @dev Binds an NFT to a reputation boost for the NFT owner.
     * @param _nftContract The address of the NFT contract.
     * @param _tokenId The token ID of the NFT.
     * @param _boostPercentage The percentage reputation boost to apply.
     * @param _boostDurationSeconds The duration of the boost in seconds.
     */
    function bindNFTBoost(address _nftContract, uint256 _tokenId, uint256 _boostPercentage, uint256 _boostDurationSeconds) external whenNotPaused {
        // Basic NFT ownership check (ERC721 interface assumption)
        try IERC721(_nftContract).ownerOf(_tokenId) == msg.sender {
            nftBoosts[msg.sender] = NFTBoost({
                boostPercentage: _boostPercentage,
                expirationTime: block.timestamp + _boostDurationSeconds
            });
            emit NFTBoostBound(msg.sender, _nftContract, _tokenId, _boostPercentage, block.timestamp + _boostDurationSeconds);
        } catch (bytes memory /*error*/) {
            revert("NFT ownership verification failed.");
        }
    }

    /**
     * @dev Returns the current reputation boost applied from NFTs for a user.
     * @param _user The address of the user to query.
     * @return The reputation boost percentage, or 0 if no active boost.
     */
    function getNFTBoost(address _user) public view returns (uint256) {
        if (nftBoosts[_user].expirationTime > block.timestamp) {
            return nftBoosts[_user].boostPercentage;
        } else {
            return 0; // Boost expired or not active
        }
    }

    /**
     * @dev Checks if an NFT reputation boost is currently active for a user.
     * @param _user The address of the user to check.
     * @return True if an NFT boost is active, false otherwise.
     */
    function isNFTBoostActive(address _user) external view returns (bool) {
        return nftBoosts[_user].expirationTime > block.timestamp;
    }


    // --- Admin and Utility Functions ---

    /**
     * @dev Sets a new admin address.
     * @param _newAdmin The address of the new admin.
     */
    function setAdmin(address _newAdmin) external onlyAdmin whenNotPaused {
        require(_newAdmin != address(0), "Admin address cannot be zero address.");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    /**
     * @dev Returns the current admin address.
     * @return The address of the current admin.
     */
    function getAdmin() external view returns (address) {
        return admin;
    }

    /**
     * @dev Pauses the contract functionality (except admin functions).
     */
    function pauseContract() external onlyAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract functionality.
     */
    function unpauseContract() external onlyAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /**
     * @dev Returns whether the contract is currently paused.
     * @return True if the contract is paused, false otherwise.
     */
    function isPaused() external view returns (bool) {
        return paused;
    }
}


// --- Interfaces ---

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}
```