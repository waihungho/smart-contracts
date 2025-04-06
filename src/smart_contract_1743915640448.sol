```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation Passport Smart Contract
 * @author Gemini AI (Example - Conceptual Contract)
 * @dev A smart contract for managing decentralized reputation passports.
 * This contract introduces a dynamic reputation system where users can earn reputation
 * through various on-chain activities, verifiable credentials, and community endorsements.
 * Reputation is not just a number but a multi-faceted profile with different dimensions and badges.
 *
 * **Contract Outline and Function Summary:**
 *
 * **1. Passport Management:**
 *    - `mintPassport(string _handle, string _profileURI)`: Mints a new Reputation Passport NFT for a user.
 *    - `transferPassport(address _to, uint256 _tokenId)`: Transfers a Reputation Passport NFT to another address.
 *    - `burnPassport(uint256 _tokenId)`: Burns (destroys) a Reputation Passport NFT. (Admin/Self-destruct)
 *    - `getPassportDetails(uint256 _tokenId)`: Retrieves detailed information about a specific passport.
 *    - `updateProfileURI(uint256 _tokenId, string _newProfileURI)`: Updates the profile URI associated with a passport.
 *    - `getPassportOwner(uint256 _tokenId)`: Returns the owner address of a given passport ID.
 *    - `exists(uint256 _tokenId)`: Checks if a passport with a given ID exists.
 *    - `passportOfOwnerByIndex(address _owner, uint256 _index)`: Returns a passport ID owned by an address at a given index.
 *    - `balanceOf(address _owner)`: Returns the number of passports owned by an address.
 *
 * **2. Reputation Management:**
 *    - `increaseReputation(uint256 _tokenId, string _dimension, uint256 _amount, string _reason)`: Increases a specific reputation dimension for a passport.
 *    - `decreaseReputation(uint256 _tokenId, string _dimension, uint256 _amount, string _reason)`: Decreases a specific reputation dimension for a passport.
 *    - `getReputationScore(uint256 _tokenId, string _dimension)`: Retrieves the reputation score for a specific dimension for a passport.
 *    - `getAllReputationDimensions(uint256 _tokenId)`: Returns a list of all reputation dimensions associated with a passport.
 *    - `recordAchievement(uint256 _tokenId, string _achievementName, string _achievementDetails)`: Records a specific achievement or milestone for a passport.
 *    - `getAchievements(uint256 _tokenId)`: Retrieves a list of achievements recorded for a passport.
 *
 * **3. Verifiable Credentials & Badges:**
 *    - `issueBadge(uint256 _tokenId, string _badgeName, string _badgeURI, address _issuer, string _evidenceURI)`: Issues a verifiable badge to a passport from a designated issuer.
 *    - `verifyBadge(uint256 _tokenId, string _badgeName)`: Checks if a passport holds a specific badge.
 *    - `getBadges(uint256 _tokenId)`: Retrieves a list of badges held by a passport.
 *    - `addTrustedIssuer(address _issuerAddress)`: Adds an address to the list of trusted badge issuers. (Admin Function)
 *    - `removeTrustedIssuer(address _issuerAddress)`: Removes an address from the list of trusted badge issuers. (Admin Function)
 *    - `isTrustedIssuer(address _issuerAddress)`: Checks if an address is a trusted badge issuer.
 *
 * **4. Community Endorsement & Trust Network:**
 *    - `endorsePassport(uint256 _endorsedTokenId, uint256 _endorserTokenId, string _dimension, string _endorsementMessage)`: Allows a passport holder to endorse another passport holder for a specific reputation dimension.
 *    - `getEndorsementsForPassport(uint256 _tokenId, string _dimension)`: Retrieves a list of endorsements received by a passport for a specific dimension.
 *    - `getEndorsementsGivenByPassport(uint256 _tokenId)`: Retrieves a list of endorsements given by a passport.
 *
 * **5. Utility & Advanced Features:**
 *    - `stakePassport(uint256 _tokenId, uint256 _durationInDays)`: Allows passport holders to stake their passports for potential benefits (e.g., access, rewards). (Conceptual - staking logic needs further definition)
 *    - `withdrawStakedPassport(uint256 _tokenId)`: Allows passport holders to withdraw their staked passports.
 *    - `setPassportUtility(uint256 _tokenId, string _utilityDescription, string _utilityData)`: Associates a specific utility or function with a passport (e.g., access control, voting rights). (Conceptual - utility framework)
 *    - `getPassportUtility(uint256 _tokenId)`: Retrieves the utility associated with a passport.
 *
 * **Note:** This is a conceptual example. Security, gas optimization, and specific implementation details would need to be carefully considered for a production-ready contract.
 */
contract ReputationPassport {
    // --- State Variables ---

    string public contractName = "ReputationPassport";
    string public contractSymbol = "RPP";

    // Passport NFT Data
    mapping(uint256 => address) public passportOwner; // Token ID to Owner Address
    mapping(uint256 => string) public passportProfileURI; // Token ID to Profile URI
    uint256 public nextPassportId = 1;
    mapping(address => uint256) public ownerPassportCount; // Owner Address to Passport Count
    mapping(uint256 => bool) public passportExists; // Token ID existence check

    // Reputation Data
    mapping(uint256 => mapping(string => uint256)) public reputationScores; // Token ID -> Dimension -> Score
    mapping(uint256 => mapping(string => bool)) public reputationDimensionExists; // Token ID -> Dimension -> Exists
    mapping(uint256 => mapping(string => string[])) public passportAchievements; // Token ID -> Achievement Name -> List of Details
    mapping(uint256 => mapping(string => Badge)) public passportBadges; // Token ID -> Badge Name -> Badge Details

    struct Badge {
        string badgeURI;
        address issuer;
        string evidenceURI;
        uint256 issueTimestamp;
    }

    // Trusted Badge Issuers
    mapping(address => bool) public trustedBadgeIssuers;

    // Endorsement Data
    struct Endorsement {
        uint256 endorserTokenId;
        string dimension;
        string message;
        uint256 timestamp;
    }
    mapping(uint256 => mapping(string => Endorsement[])) public passportEndorsementsReceived; // Token ID -> Dimension -> List of Endorsements
    mapping(uint256 => Endorsement[]) public passportEndorsementsGiven; // Token ID -> List of Endorsements Given

    // Passport Utility (Conceptual)
    mapping(uint256 => string) public passportUtilityDescription;
    mapping(uint256 => string) public passportUtilityData;

    // Staking Data (Conceptual)
    mapping(uint256 => uint256) public passportStakeEndTime; // Token ID -> Stake End Timestamp

    // Admin Role (Simple - Replace with proper access control in production)
    address public admin;

    // --- Events ---
    event PassportMinted(uint256 tokenId, address owner, string handle, string profileURI);
    event PassportTransferred(uint256 tokenId, address from, address to);
    event PassportBurned(uint256 tokenId, address owner);
    event ReputationIncreased(uint256 tokenId, string dimension, uint256 amount, string reason);
    event ReputationDecreased(uint256 tokenId, string dimension, uint256 amount, string reason);
    event AchievementRecorded(uint256 tokenId, string achievementName, string achievementDetails);
    event BadgeIssued(uint256 tokenId, string badgeName, string badgeURI, address issuer, string evidenceURI);
    event TrustedIssuerAdded(address issuerAddress);
    event TrustedIssuerRemoved(address issuerAddress);
    event PassportEndorsed(uint256 endorsedTokenId, uint256 endorserTokenId, string dimension, string message);
    event PassportStaked(uint256 tokenId, address owner, uint256 durationInDays);
    event PassportWithdrawn(uint256 tokenId, address owner);
    event PassportUtilitySet(uint256 tokenId, string utilityDescription, string utilityData);
    event ProfileUR updated(uint256 tokenId, string newProfileURI);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier passportExistsCheck(uint256 _tokenId) {
        require(passportExists[_tokenId], "Passport does not exist.");
        _;
    }

    modifier onlyPassportOwner(uint256 _tokenId) {
        require(passportOwner[_tokenId] == msg.sender, "You are not the passport owner.");
        _;
    }

    modifier onlyTrustedIssuer(address _issuerAddress) {
        require(trustedBadgeIssuers[_issuerAddress], "Issuer is not trusted.");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender; // Set contract deployer as admin
    }

    // --- 1. Passport Management Functions ---

    /**
     * @dev Mints a new Reputation Passport NFT.
     * @param _handle The handle or username associated with the passport.
     * @param _profileURI URI pointing to the profile metadata (e.g., IPFS link).
     */
    function mintPassport(string memory _handle, string memory _profileURI) public returns (uint256) {
        uint256 tokenId = nextPassportId++;
        passportOwner[tokenId] = msg.sender;
        passportProfileURI[tokenId] = _profileURI;
        ownerPassportCount[msg.sender]++;
        passportExists[tokenId] = true;
        emit PassportMinted(tokenId, msg.sender, _handle, _profileURI);
        return tokenId;
    }

    /**
     * @dev Transfers a Reputation Passport NFT to another address.
     * @param _to The address to transfer the passport to.
     * @param _tokenId The ID of the passport to transfer.
     */
    function transferPassport(address _to, uint256 _tokenId) public passportExistsCheck(_tokenId) onlyPassportOwner(_tokenId) {
        address from = msg.sender;
        address to = _to;
        require(to != address(0), "Transfer to the zero address.");
        require(to != from, "Transfer to self is not allowed.");

        ownerPassportCount[from]--;
        ownerPassportCount[to]++;
        passportOwner[_tokenId] = to;
        emit PassportTransferred(_tokenId, from, to);
    }

    /**
     * @dev Burns (destroys) a Reputation Passport NFT. Only admin or passport owner can burn.
     * @param _tokenId The ID of the passport to burn.
     */
    function burnPassport(uint256 _tokenId) public passportExistsCheck(_tokenId) {
        require(msg.sender == admin || passportOwner[_tokenId] == msg.sender, "Only admin or passport owner can burn.");
        address owner = passportOwner[_tokenId];

        ownerPassportCount[owner]--;
        delete passportOwner[_tokenId];
        delete passportProfileURI[_tokenId];
        passportExists[_tokenId] = false; // Mark as non-existent
        emit PassportBurned(_tokenId, owner);
    }

    /**
     * @dev Retrieves detailed information about a specific passport.
     * @param _tokenId The ID of the passport.
     * @return owner The owner address of the passport.
     * @return profileURI The profile URI of the passport.
     */
    function getPassportDetails(uint256 _tokenId) public view passportExistsCheck(_tokenId) returns (address owner, string memory profileURI) {
        return (passportOwner[_tokenId], passportProfileURI[_tokenId]);
    }

    /**
     * @dev Updates the profile URI associated with a passport.
     * @param _tokenId The ID of the passport to update.
     * @param _newProfileURI The new profile URI.
     */
    function updateProfileURI(uint256 _tokenId, string memory _newProfileURI) public passportExistsCheck(_tokenId) onlyPassportOwner(_tokenId) {
        passportProfileURI[_tokenId] = _newProfileURI;
        emit ProfileUR updated(_tokenId, _newProfileURI);
    }

    /**
     * @dev Returns the owner address of a given passport ID.
     * @param _tokenId The ID of the passport.
     * @return The owner address.
     */
    function getPassportOwner(uint256 _tokenId) public view passportExistsCheck(_tokenId) returns (address) {
        return passportOwner[_tokenId];
    }

    /**
     * @dev Checks if a passport with a given ID exists.
     * @param _tokenId The ID of the passport.
     * @return True if the passport exists, false otherwise.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return passportExists[_tokenId];
    }

    /**
     * @dev Returns a passport ID owned by an address at a given index. (For enumeration - basic example)
     * @param _owner The owner address.
     * @param _index The index (starting from 0).
     * @return The passport ID, or 0 if out of bounds.
     */
    function passportOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
        uint256 currentCount = 0;
        for (uint256 i = 1; i < nextPassportId; i++) {
            if (passportExists[i] && passportOwner[i] == _owner) {
                if (currentCount == _index) {
                    return i;
                }
                currentCount++;
            }
        }
        return 0; // Out of bounds
    }

    /**
     * @dev Returns the number of passports owned by an address.
     * @param _owner The owner address.
     * @return The balance of passports.
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return ownerPassportCount[_owner];
    }


    // --- 2. Reputation Management Functions ---

    /**
     * @dev Increases a specific reputation dimension for a passport.
     * @param _tokenId The ID of the passport to update.
     * @param _dimension The dimension of reputation to increase (e.g., "Skill", "Community", "Contribution").
     * @param _amount The amount to increase the reputation by.
     * @param _reason A brief reason for the reputation increase.
     */
    function increaseReputation(uint256 _tokenId, string memory _dimension, uint256 _amount, string memory _reason) public passportExistsCheck(_tokenId) onlyAdmin { // Admin or authorized entity can increase
        reputationScores[_tokenId][_dimension] += _amount;
        reputationDimensionExists[_tokenId][_dimension] = true;
        emit ReputationIncreased(_tokenId, _dimension, _amount, _reason);
    }

    /**
     * @dev Decreases a specific reputation dimension for a passport.
     * @param _tokenId The ID of the passport to update.
     * @param _dimension The dimension of reputation to decrease.
     * @param _amount The amount to decrease the reputation by.
     * @param _reason A brief reason for the reputation decrease.
     */
    function decreaseReputation(uint256 _tokenId, string memory _dimension, uint256 _amount, string memory _reason) public passportExistsCheck(_tokenId) onlyAdmin { // Admin or authorized entity can decrease
        require(reputationScores[_tokenId][_dimension] >= _amount, "Reputation cannot go below zero.");
        reputationScores[_tokenId][_dimension] -= _amount;
        reputationDimensionExists[_tokenId][_dimension] = true; // Ensure dimension exists even if score goes to 0
        emit ReputationDecreased(_tokenId, _dimension, _amount, _reason);
    }

    /**
     * @dev Retrieves the reputation score for a specific dimension for a passport.
     * @param _tokenId The ID of the passport.
     * @param _dimension The dimension to retrieve the score for.
     * @return The reputation score for the given dimension.
     */
    function getReputationScore(uint256 _tokenId, string memory _dimension) public view passportExistsCheck(_tokenId) returns (uint256) {
        return reputationScores[_tokenId][_dimension];
    }

    /**
     * @dev Returns a list of all reputation dimensions associated with a passport.
     * @param _tokenId The ID of the passport.
     * @return An array of reputation dimension names.
     */
    function getAllReputationDimensions(uint256 _tokenId) public view passportExistsCheck(_tokenId) returns (string[] memory) {
        string[] memory dimensions = new string[](0); // Initialize with empty array
        uint256 index = 0;
        for (uint256 i = 0; i < nextPassportId; i++) { // Iterate through potential token IDs (inefficient for large scale - consider alternative)
            if (i == _tokenId) {
                for (bytes32 keyBytes in reputationDimensionExists[_tokenId]) {
                    if (reputationDimensionExists[_tokenId][string(keyBytes)]) {
                        dimensions = _arrayPush(dimensions, string(keyBytes));
                        index++;
                    }
                }
                break; // Found the token, no need to continue iterating
            }
        }
        return dimensions;
    }

    // Helper function to push to dynamic array (Solidity < 0.8 needs this for memory arrays)
    function _arrayPush(string[] memory _arr, string memory _value) private pure returns (string[] memory) {
        string[] memory newArr = new string[](_arr.length + 1);
        for (uint256 i = 0; i < _arr.length; i++) {
            newArr[i] = _arr[i];
        }
        newArr[_arr.length] = _value;
        return newArr;
    }


    /**
     * @dev Records a specific achievement or milestone for a passport.
     * @param _tokenId The ID of the passport.
     * @param _achievementName The name of the achievement (e.g., "Completed Project X", "Presented at Conference Y").
     * @param _achievementDetails Detailed description or evidence of the achievement.
     */
    function recordAchievement(uint256 _tokenId, string memory _achievementName, string memory _achievementDetails) public passportExistsCheck(_tokenId) onlyAdmin { // Admin or authorized entity can record achievements
        passportAchievements[_tokenId][_achievementName].push(_achievementDetails);
        emit AchievementRecorded(_tokenId, _achievementName, _achievementDetails);
    }

    /**
     * @dev Retrieves a list of achievements recorded for a passport.
     * @param _tokenId The ID of the passport.
     * @return A mapping of achievement names to lists of achievement details.
     */
    function getAchievements(uint256 _tokenId) public view passportExistsCheck(_tokenId) returns (mapping(string => string[] memory) memory) {
        mapping(string => string[] memory) memory achievements = passportAchievements[_tokenId];
        return achievements; // Solidity mapping in memory can be returned
    }


    // --- 3. Verifiable Credentials & Badge Functions ---

    /**
     * @dev Issues a verifiable badge to a passport from a designated issuer.
     * @param _tokenId The ID of the passport to issue the badge to.
     * @param _badgeName The name of the badge (e.g., "Certified Solidity Developer").
     * @param _badgeURI URI pointing to the badge metadata (e.g., image, description).
     * @param _issuer The address of the badge issuer.
     * @param _evidenceURI URI pointing to evidence supporting the badge issuance (optional).
     */
    function issueBadge(
        uint256 _tokenId,
        string memory _badgeName,
        string memory _badgeURI,
        address _issuer,
        string memory _evidenceURI
    ) public passportExistsCheck(_tokenId) onlyTrustedIssuer(_issuer) { // Only trusted issuers can issue badges
        passportBadges[_tokenId][_badgeName] = Badge({
            badgeURI: _badgeURI,
            issuer: _issuer,
            evidenceURI: _evidenceURI,
            issueTimestamp: block.timestamp
        });
        emit BadgeIssued(_tokenId, _badgeName, _badgeURI, _issuer, _evidenceURI);
    }

    /**
     * @dev Verifies if a passport holds a specific badge.
     * @param _tokenId The ID of the passport.
     * @param _badgeName The name of the badge to verify.
     * @return True if the passport holds the badge, false otherwise.
     */
    function verifyBadge(uint256 _tokenId, string memory _badgeName) public view passportExistsCheck(_tokenId) returns (bool) {
        return bytes(passportBadges[_tokenId][_badgeName].badgeURI).length > 0; // Simple check if badgeURI is set, can be refined
    }

    /**
     * @dev Retrieves a list of badges held by a passport.
     * @param _tokenId The ID of the passport.
     * @return A mapping of badge names to Badge structs.
     */
    function getBadges(uint256 _tokenId) public view passportExistsCheck(_tokenId) returns (mapping(string => Badge) memory) {
        return passportBadges[_tokenId]; // Return badge mapping
    }

    /**
     * @dev Adds an address to the list of trusted badge issuers. Only admin can call this.
     * @param _issuerAddress The address to add as a trusted issuer.
     */
    function addTrustedIssuer(address _issuerAddress) public onlyAdmin {
        trustedBadgeIssuers[_issuerAddress] = true;
        emit TrustedIssuerAdded(_issuerAddress);
    }

    /**
     * @dev Removes an address from the list of trusted badge issuers. Only admin can call this.
     * @param _issuerAddress The address to remove as a trusted issuer.
     */
    function removeTrustedIssuer(address _issuerAddress) public onlyAdmin {
        trustedBadgeIssuers[_issuerAddress] = false;
        emit TrustedIssuerRemoved(_issuerAddress);
    }

    /**
     * @dev Checks if an address is a trusted badge issuer.
     * @param _issuerAddress The address to check.
     * @return True if the address is a trusted issuer, false otherwise.
     */
    function isTrustedIssuer(address _issuerAddress) public view returns (bool) {
        return trustedBadgeIssuers[_issuerAddress];
    }


    // --- 4. Community Endorsement & Trust Network Functions ---

    /**
     * @dev Allows a passport holder to endorse another passport holder for a specific reputation dimension.
     * @param _endorsedTokenId The ID of the passport being endorsed.
     * @param _endorserTokenId The ID of the passport endorsing.
     * @param _dimension The reputation dimension being endorsed (e.g., "Collaboration", "Leadership").
     * @param _endorsementMessage A message accompanying the endorsement.
     */
    function endorsePassport(
        uint256 _endorsedTokenId,
        uint256 _endorserTokenId,
        string memory _dimension,
        string memory _endorsementMessage
    ) public passportExistsCheck(_endorsedTokenId) passportExistsCheck(_endorserTokenId) onlyPassportOwner(_endorserTokenId) { // Endorser must be passport owner
        require(_endorsedTokenId != _endorserTokenId, "Cannot endorse yourself."); // Cannot endorse self
        passportEndorsementsReceived[_endorsedTokenId][_dimension].push(Endorsement({
            endorserTokenId: _endorserTokenId,
            dimension: _dimension,
            message: _endorsementMessage,
            timestamp: block.timestamp
        }));
        passportEndorsementsGiven[_endorserTokenId].push(Endorsement({
            endorserTokenId: _endorsedTokenId, // Storing the endorsed token ID here to track given endorsements
            dimension: _dimension,
            message: _endorsementMessage,
            timestamp: block.timestamp
        }));
        emit PassportEndorsed(_endorsedTokenId, _endorserTokenId, _dimension, _endorsementMessage);
    }

    /**
     * @dev Retrieves a list of endorsements received by a passport for a specific dimension.
     * @param _tokenId The ID of the passport.
     * @param _dimension The dimension to retrieve endorsements for.
     * @return An array of Endorsement structs received for the dimension.
     */
    function getEndorsementsForPassport(uint256 _tokenId, string memory _dimension) public view passportExistsCheck(_tokenId) returns (Endorsement[] memory) {
        return passportEndorsementsReceived[_tokenId][_dimension];
    }

    /**
     * @dev Retrieves a list of endorsements given by a passport.
     * @param _tokenId The ID of the passport.
     * @return An array of Endorsement structs given by the passport.
     */
    function getEndorsementsGivenByPassport(uint256 _tokenId) public view passportExistsCheck(_tokenId) returns (Endorsement[] memory) {
        return passportEndorsementsGiven[_tokenId];
    }


    // --- 5. Utility & Advanced Features Functions ---

    /**
     * @dev Allows passport holders to stake their passports for potential benefits. (Conceptual - staking logic needs further definition)
     * @param _tokenId The ID of the passport to stake.
     * @param _durationInDays The duration of staking in days.
     */
    function stakePassport(uint256 _tokenId, uint256 _durationInDays) public passportExistsCheck(_tokenId) onlyPassportOwner(_tokenId) {
        require(passportStakeEndTime[_tokenId] == 0 || block.timestamp > passportStakeEndTime[_tokenId], "Passport already staked or staking period not finished."); // Prevent re-staking before end
        uint256 stakeDurationSeconds = _durationInDays * 1 days; // Example duration calculation
        passportStakeEndTime[_tokenId] = block.timestamp + stakeDurationSeconds;
        emit PassportStaked(_tokenId, msg.sender, _durationInDays);
    }

    /**
     * @dev Allows passport holders to withdraw their staked passports after the staking period.
     * @param _tokenId The ID of the passport to withdraw.
     */
    function withdrawStakedPassport(uint256 _tokenId) public passportExistsCheck(_tokenId) onlyPassportOwner(_tokenId) {
        require(passportStakeEndTime[_tokenId] != 0 && block.timestamp > passportStakeEndTime[_tokenId], "Passport not staked or staking period not finished.");
        passportStakeEndTime[_tokenId] = 0; // Reset stake end time
        emit PassportWithdrawn(_tokenId, msg.sender);
    }

    /**
     * @dev Associates a specific utility or function with a passport (e.g., access control, voting rights). (Conceptual - utility framework)
     * @param _tokenId The ID of the passport.
     * @param _utilityDescription A description of the utility.
     * @param _utilityData Data related to the utility (e.g., role ID, access level).
     */
    function setPassportUtility(uint256 _tokenId, string memory _utilityDescription, string memory _utilityData) public passportExistsCheck(_tokenId) onlyAdmin { // Admin sets utility
        passportUtilityDescription[_tokenId] = _utilityDescription;
        passportUtilityData[_tokenId] = _utilityData;
        emit PassportUtilitySet(_tokenId, _utilityDescription, _utilityData);
    }

    /**
     * @dev Retrieves the utility associated with a passport.
     * @param _tokenId The ID of the passport.
     * @return utilityDescription The description of the utility.
     * @return utilityData The data related to the utility.
     */
    function getPassportUtility(uint256 _tokenId) public view passportExistsCheck(_tokenId) returns (string memory utilityDescription, string memory utilityData) {
        return (passportUtilityDescription[_tokenId], passportUtilityData[_tokenId]);
    }

    // --- Admin Functions ---
    // (More admin functions can be added as needed)
}
```