```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Achievement NFT Contract - "Aetheria Badges"
 * @author Bard (Example Smart Contract)
 * @dev A smart contract for issuing and managing Dynamic Achievement NFTs.
 *      This contract features a system for defining achievements, awarding them to users,
 *      and dynamically updating the NFT metadata based on user progress and community voting.
 *
 * **Outline and Function Summary:**
 *
 * **1. Admin Functions (Owner-Restricted):**
 *    - `setContractName(string _name)`: Sets the name of the NFT collection.
 *    - `setBaseURI(string _baseURI)`: Sets the base URI for NFT metadata.
 *    - `addAchievementType(uint256 _achievementTypeId, string _name, string _description, string _initialMetadataURI)`: Defines a new type of achievement.
 *    - `updateAchievementTypeMetadata(uint256 _achievementTypeId, string _newMetadataURI)`: Updates the metadata URI for an achievement type.
 *    - `setAchievementCriteriaSetter(address _criteriaSetter)`: Sets an address authorized to set achievement criteria.
 *    - `setMetadataUpdater(address _metadataUpdater)`: Sets an address authorized to update NFT metadata dynamically.
 *    - `toggleAchievementTypeActive(uint256 _achievementTypeId)`: Activates or deactivates an achievement type.
 *
 * **2. Achievement Criteria Management (CriteriaSetter-Restricted):**
 *    - `defineAchievementCriteria(uint256 _achievementTypeId, string _criteriaDescription, function(address) external view returns (bool) _criteriaFunction)`: Defines criteria for earning an achievement using a function selector (concept - not fully implementable directly in Solidity due to function pointers, but represents intent). *In practice, criteria would be checked off-chain or via oracles and then awarded.*
 *    - `updateAchievementCriteriaDescription(uint256 _achievementTypeId, string _newCriteriaDescription)`: Updates the description of achievement criteria.
 *
 * **3. User Achievement Functions:**
 *    - `awardAchievement(address _user, uint256 _achievementTypeId)`: Awards an achievement to a user (typically called by an authorized service/oracle after criteria are met).
 *    - `revokeAchievement(address _user, uint256 _achievementTypeId)`: Revokes an achievement from a user (admin function).
 *    - `hasAchievement(address _user, uint256 _achievementTypeId) view returns (bool)`: Checks if a user has earned a specific achievement.
 *    - `getAchievementsByUser(address _user) view returns (uint256[])`: Returns a list of achievement type IDs earned by a user.
 *    - `getAchievementHoldersByType(uint256 _achievementTypeId) view returns (address[])`: Returns a list of addresses that have earned a specific achievement type.
 *
 * **4. Dynamic Metadata & Community Features:**
 *    - `requestMetadataUpdate(uint256 _tokenId, string _reason)`: Allows users to request a metadata update for their NFT (triggering potential community voting or automated updates).
 *    - `voteForMetadataUpdate(uint256 _tokenId, string _proposedMetadataURI)`: Allows NFT holders to vote on proposed metadata updates for a specific NFT (DAO-lite feature).
 *    - `applyMetadataUpdate(uint256 _tokenId, string _newMetadataURI)`: Applies a metadata update to an NFT (typically after successful voting or by authorized metadata updater).
 *    - `getNFTMetadataURI(uint256 _tokenId) view returns (string)`: Retrieves the current metadata URI for a specific NFT.
 *
 * **5. Utility & Information Functions:**
 *    - `getAchievementTypeName(uint256 _achievementTypeId) view returns (string)`: Returns the name of an achievement type.
 *    - `getAchievementTypeDescription(uint256 _achievementTypeId) view returns (string)`: Returns the description of an achievement type.
 *    - `isAchievementTypeActive(uint256 _achievementTypeId) view returns (bool)`: Checks if an achievement type is currently active.
 *    - `getTotalAchievementsMinted() view returns (uint256)`: Returns the total number of achievement NFTs minted.
 */

contract AetheriaBadges {
    string public contractName = "Aetheria Badges";
    string public baseURI;
    address public owner;
    address public achievementCriteriaSetter;
    address public metadataUpdater;

    uint256 public totalAchievementsMinted = 0;

    struct AchievementType {
        string name;
        string description;
        string baseMetadataURI; // Initial/Default Metadata URI
        bool isActive;
    }

    mapping(uint256 => AchievementType) public achievementTypes;
    mapping(uint256 => mapping(address => bool)) public userAchievements; // achievementTypeId => user => hasAchievement
    mapping(uint256 => address[]) public achievementHoldersByType; // achievementTypeId => array of holder addresses
    mapping(uint256 => string) public nftMetadataURIs; // tokenId => current metadata URI
    mapping(uint256 => uint256) public tokenIdToAchievementType; // tokenId => achievementTypeId

    event ContractNameUpdated(string newName);
    event BaseURISet(string newBaseURI);
    event AchievementTypeAdded(uint256 achievementTypeId, string name);
    event AchievementTypeMetadataUpdated(uint256 achievementTypeId, string newMetadataURI);
    event AchievementCriteriaSetterUpdated(address newCriteriaSetter);
    event MetadataUpdaterUpdated(address newMetadataUpdater);
    event AchievementTypeToggled(uint256 achievementTypeId, bool isActive);
    event AchievementCriteriaDefined(uint256 achievementTypeId, string criteriaDescription);
    event AchievementAwarded(address user, uint256 achievementTypeId, uint256 tokenId);
    event AchievementRevoked(address user, uint256 achievementTypeId);
    event MetadataUpdateRequestRequested(uint256 tokenId, address requester, string reason);
    event MetadataUpdateVoteCast(uint256 tokenId, address voter, string proposedMetadataURI);
    event MetadataUpdateApplied(uint256 tokenId, string newMetadataURI);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCriteriaSetter() {
        require(msg.sender == achievementCriteriaSetter, "Only criteria setter can call this function.");
        _;
    }

    modifier onlyMetadataUpdater() {
        require(msg.sender == metadataUpdater, "Only metadata updater can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
        achievementCriteriaSetter = msg.sender; // Owner initially is also criteria setter
        metadataUpdater = msg.sender; // Owner initially is also metadata updater
    }

    // ------------------------------------------------------------------------
    // 1. Admin Functions (Owner-Restricted)
    // ------------------------------------------------------------------------

    function setContractName(string memory _name) public onlyOwner {
        contractName = _name;
        emit ContractNameUpdated(_name);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    function addAchievementType(
        uint256 _achievementTypeId,
        string memory _name,
        string memory _description,
        string memory _initialMetadataURI
    ) public onlyOwner {
        require(achievementTypes[_achievementTypeId].name == "", "Achievement type already exists.");
        achievementTypes[_achievementTypeId] = AchievementType({
            name: _name,
            description: _description,
            baseMetadataURI: _initialMetadataURI,
            isActive: true
        });
        emit AchievementTypeAdded(_achievementTypeId, _name);
    }

    function updateAchievementTypeMetadata(uint256 _achievementTypeId, string memory _newMetadataURI) public onlyOwner {
        require(achievementTypes[_achievementTypeId].name != "", "Achievement type does not exist.");
        achievementTypes[_achievementTypeId].baseMetadataURI = _newMetadataURI;
        emit AchievementTypeMetadataUpdated(_achievementTypeId, _newMetadataURI);
    }

    function setAchievementCriteriaSetter(address _criteriaSetter) public onlyOwner {
        achievementCriteriaSetter = _criteriaSetter;
        emit AchievementCriteriaSetterUpdated(_criteriaSetter);
    }

    function setMetadataUpdater(address _metadataUpdater) public onlyOwner {
        metadataUpdater = _metadataUpdater;
        emit MetadataUpdaterUpdated(_metadataUpdater);
    }

    function toggleAchievementTypeActive(uint256 _achievementTypeId) public onlyOwner {
        require(achievementTypes[_achievementTypeId].name != "", "Achievement type does not exist.");
        achievementTypes[_achievementTypeId].isActive = !achievementTypes[_achievementTypeId].isActive;
        emit AchievementTypeToggled(_achievementTypeId, achievementTypes[_achievementTypeId].isActive);
    }

    // ------------------------------------------------------------------------
    // 2. Achievement Criteria Management (CriteriaSetter-Restricted)
    // ------------------------------------------------------------------------

    // Example of defining criteria description (actual criteria check would be off-chain/oracle based)
    function defineAchievementCriteria(
        uint256 _achievementTypeId,
        string memory _criteriaDescription
        // function(address) external view returns (bool) _criteriaFunction  // Solidity doesn't directly support function pointers like this for external calls.
    ) public onlyCriteriaSetter {
        require(achievementTypes[_achievementTypeId].name != "", "Achievement type does not exist.");
        // In a real-world scenario, the criteria function would be handled externally (e.g., by an oracle or off-chain service).
        // This function primarily sets the *description* of the criteria.
        emit AchievementCriteriaDefined(_achievementTypeId, _criteriaDescription);
    }

    function updateAchievementCriteriaDescription(uint256 _achievementTypeId, string memory _newCriteriaDescription) public onlyCriteriaSetter {
        require(achievementTypes[_achievementTypeId].name != "", "Achievement type does not exist.");
        emit AchievementCriteriaDefined(_achievementTypeId, _newCriteriaDescription); // Re-use event for simplicity, could create a new one.
    }


    // ------------------------------------------------------------------------
    // 3. User Achievement Functions
    // ------------------------------------------------------------------------

    function awardAchievement(address _user, uint256 _achievementTypeId) public onlyCriteriaSetter { // In practice, authorization would be more robust.
        require(achievementTypes[_achievementTypeId].name != "", "Achievement type does not exist.");
        require(achievementTypes[_achievementTypeId].isActive, "Achievement type is not active.");
        require(!userAchievements[_achievementTypeId][_user], "User already has this achievement.");

        userAchievements[_achievementTypeId][_user] = true;
        achievementHoldersByType[_achievementTypeId].push(_user);

        totalAchievementsMinted++;
        uint256 tokenId = totalAchievementsMinted;
        tokenIdToAchievementType[tokenId] = _achievementTypeId;
        nftMetadataURIs[tokenId] = achievementTypes[_achievementTypeId].baseMetadataURI; // Initial metadata

        emit AchievementAwarded(_user, _achievementTypeId, tokenId);
    }

    function revokeAchievement(address _user, uint256 _achievementTypeId) public onlyOwner {
        require(achievementTypes[_achievementTypeId].name != "", "Achievement type does not exist.");
        require(userAchievements[_achievementTypeId][_user], "User does not have this achievement.");

        userAchievements[_achievementTypeId][_user] = false;

        // Remove user from achievementHoldersByType array (inefficient for large arrays in Solidity, consider alternative if performance critical)
        address[] storage holders = achievementHoldersByType[_achievementTypeId];
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == _user) {
                holders[i] = holders[holders.length - 1]; // Replace with last element
                holders.pop(); // Remove last element (effectively removing _user)
                break;
            }
        }

        // Note: Revoking doesn't decrement totalAchievementsMinted or remove tokenId mapping in this simplified example.
        // More complex revocation might involve burning the NFT or marking it as invalid.

        emit AchievementRevoked(_user, _achievementTypeId);
    }

    function hasAchievement(address _user, uint256 _achievementTypeId) public view returns (bool) {
        return userAchievements[_achievementTypeId][_user];
    }

    function getAchievementsByUser(address _user) public view returns (uint256[] memory) {
        uint256[] memory userAchievementTypes = new uint256[](0);
        uint256 count = 0;
        for (uint256 i = 1; i <= type(uint256).max; i++) { // Iterate through possible achievement type IDs (up to practical limit)
            if (achievementTypes[i].name != "" && userAchievements[i][_user]) {
                // Resize array to add new element
                uint256[] memory temp = new uint256[](count + 1);
                for (uint256 j = 0; j < count; j++) {
                    temp[j] = userAchievementTypes[j];
                }
                temp[count] = i;
                userAchievementTypes = temp;
                count++;
            }
            if (i > 100) break; // Simple limit to avoid excessive gas costs in view function (adjust as needed)
        }
        return userAchievementTypes;
    }


    function getAchievementHoldersByType(uint256 _achievementTypeId) public view returns (address[] memory) {
        return achievementHoldersByType[_achievementTypeId];
    }

    // ------------------------------------------------------------------------
    // 4. Dynamic Metadata & Community Features (Simplified Voting Example)
    // ------------------------------------------------------------------------

    // Simplified metadata update request (more advanced versions could involve voting, oracles, etc.)
    function requestMetadataUpdate(uint256 _tokenId, string memory _reason) public {
        require(tokenIdToAchievementType[_tokenId] != 0, "Invalid token ID.");
        emit MetadataUpdateRequestRequested(_tokenId, msg.sender, _reason);
        // In a real system, this would trigger a more complex process (voting, oracle check, etc.)
    }

    // Very basic "voting" - everyone can vote once, no weighting, just first to propose wins.
    mapping(uint256 => mapping(address => bool)) public hasVotedForUpdate; // tokenId => voter => hasVoted
    mapping(uint256 => string) public proposedMetadataURI; // tokenId => proposed URI

    function voteForMetadataUpdate(uint256 _tokenId, string memory _proposedMetadataURI) public {
        require(tokenIdToAchievementType[_tokenId] != 0, "Invalid token ID.");
        require(!hasVotedForUpdate[_tokenId][msg.sender], "You have already voted for this update.");

        hasVotedForUpdate[_tokenId][msg.sender] = true;
        proposedMetadataURI[_tokenId] = _proposedMetadataURI; // In a real voting system, you'd need consensus mechanisms

        emit MetadataUpdateVoteCast(_tokenId, msg.sender, _proposedMetadataURI);

        // Simplified auto-apply if first vote (for demonstration - real system would have proper voting logic)
        applyMetadataUpdate(_tokenId, _proposedMetadataURI);
    }

    function applyMetadataUpdate(uint256 _tokenId, string memory _newMetadataURI) public onlyMetadataUpdater { // Could be triggered by voting result in a real system
        require(tokenIdToAchievementType[_tokenId] != 0, "Invalid token ID.");
        nftMetadataURIs[_tokenId] = _newMetadataURI;
        emit MetadataUpdateApplied(_tokenId, _newMetadataURI);
    }

    function getNFTMetadataURI(uint256 _tokenId) public view returns (string memory) {
        require(tokenIdToAchievementType[_tokenId] != 0, "Invalid token ID.");
        return nftMetadataURIs[_tokenId];
    }

    // ------------------------------------------------------------------------
    // 5. Utility & Information Functions
    // ------------------------------------------------------------------------

    function getAchievementTypeName(uint256 _achievementTypeId) public view returns (string memory) {
        return achievementTypes[_achievementTypeId].name;
    }

    function getAchievementTypeDescription(uint256 _achievementTypeId) public view returns (string memory) {
        return achievementTypes[_achievementTypeId].description;
    }

    function isAchievementTypeActive(uint256 _achievementTypeId) public view returns (bool) {
        return achievementTypes[_achievementTypeId].isActive;
    }

    function getTotalAchievementsMinted() public view returns (uint256) {
        return totalAchievementsMinted;
    }
}
```