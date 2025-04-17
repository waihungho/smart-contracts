```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Reputation and Identity Oracle - "CredibilityNexus"
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for managing decentralized reputation and verifiable identities.
 * It introduces concepts of dynamic reputation scoring, skill-based endorsements, on-chain identity verification,
 * reputation delegation, decentralized moderation, and reputation-gated access control.
 * This contract aims to provide a flexible and advanced framework for building trust and reputation within
 * decentralized ecosystems, going beyond simple token-based reputation systems.
 *
 * **Outline and Function Summary:**
 *
 * **1. Identity Management:**
 *    - `registerIdentity(string _handle, string _metadataURI)`: Registers a unique identity with a handle and metadata URI.
 *    - `updateIdentityMetadata(string _newMetadataURI)`: Updates the metadata URI associated with the caller's identity.
 *    - `resolveIdentity(address _identityAddress)`: Resolves an identity address to its handle and metadata URI.
 *    - `isIdentityRegistered(address _address)`: Checks if an address has registered an identity.
 *
 * **2. Skill-Based Endorsements:**
 *    - `addSkill(string _skillName)`: Adds a new skill to the list of recognized skills (Admin only).
 *    - `endorseSkill(address _targetIdentity, string _skillName, string _endorsementStatement)`: Endorses a target identity for a specific skill with a statement.
 *    - `getEndorsementsForSkill(address _identityAddress, string _skillName)`: Retrieves all endorsements for a skill for a given identity.
 *    - `revokeEndorsement(uint _endorsementId)`: Revokes a previously given endorsement (Endorser only, with cooldown).
 *
 * **3. Dynamic Reputation Scoring:**
 *    - `calculateReputationScore(address _identityAddress)`: Calculates a dynamic reputation score based on endorsements and other factors (internal).
 *    - `getReputationScore(address _identityAddress)`: Retrieves the current reputation score of an identity.
 *    - `setReputationWeight(string _skillName, uint _weight)`: Sets the weight of a specific skill in reputation calculation (Admin only).
 *    - `updateReputationScore(address _identityAddress)`: Manually trigger reputation score update (Admin/Oracle role).
 *
 * **4. Reputation Delegation:**
 *    - `delegateReputation(address _delegatee)`: Delegates reputation voting power to another identity.
 *    - `undelegateReputation()`: Cancels reputation delegation.
 *    - `getDelegatedReputation(address _identityAddress)`: Retrieves the address being delegated to (if any).
 *
 * **5. Decentralized Moderation (Reputation-Weighted):**
 *    - `reportIdentity(address _targetIdentity, string _reportReason)`: Allows identities to report other identities for misconduct.
 *    - `voteOnReport(uint _reportId, bool _vote)`: Reputation-weighted voting on reports (Reputation holders can vote).
 *    - `resolveReport(uint _reportId)`: Resolves a report based on voting results (Admin/Moderator role).
 *    - `getReportDetails(uint _reportId)`: Retrieves details of a specific report.
 *
 * **6. Reputation-Gated Access Control:**
 *    - `setReputationThreshold(string _functionName, uint _threshold)`: Sets a reputation threshold for accessing a specific function (Admin only).
 *    - `checkReputationAccess(address _identityAddress, string _functionName)`: Internal function to check if an identity meets the reputation threshold for a function.
 *    - `reputationRequired(string _functionName)`: Modifier to enforce reputation-gated access for functions.
 *
 * **7. Oracle Functions & Administration:**
 *    - `setAdminRole(address _adminAddress, bool _isAdmin)`: Assigns or revokes admin role (Contract Owner only).
 *    - `setModeratorRole(address _moderatorAddress, bool _isModerator)`: Assigns or revokes moderator role (Admin only).
 *    - `isAdministrator(address _address)`: Checks if an address is an administrator.
 *    - `isModerator(address _address)`: Checks if an address is a moderator.
 *
 * **8. Utility & View Functions:**
 *    - `getSkillList()`: Returns the list of registered skills.
 *    - `getContractOwner()`: Returns the contract owner's address.
 */
contract CredibilityNexus {

    // --- State Variables ---

    address public contractOwner;

    mapping(address => Identity) public identities;
    mapping(string => bool) public registeredHandles;
    mapping(uint => Endorsement) public endorsements;
    uint public endorsementCount;
    mapping(string => Skill) public skills;
    string[] public skillList;
    mapping(address => uint) public reputationScores;
    mapping(string => uint) public skillWeights; // Skill name to weight in reputation score
    mapping(address => address) public reputationDelegations;
    mapping(uint => Report) public reports;
    uint public reportCount;
    mapping(uint => mapping(address => bool)) public reportVotes; // reportId => voter => voted
    mapping(string => uint) public reputationThresholds; // Function name => reputation threshold
    mapping(address => bool) public administrators;
    mapping(address => bool) public moderators;

    uint public endorsementRevocationCooldown = 7 days; // Cooldown period for endorsement revocation

    struct Identity {
        string handle;
        string metadataURI;
        uint registrationTimestamp;
    }

    struct Endorsement {
        uint id;
        address endorser;
        address targetIdentity;
        string skillName;
        string endorsementStatement;
        uint endorsementTimestamp;
        bool isActive;
    }

    struct Skill {
        string name;
        uint weight; // Weight in reputation calculation
        bool isEnabled;
    }

    struct Report {
        uint id;
        address reporter;
        address targetIdentity;
        string reportReason;
        uint reportTimestamp;
        uint positiveVotes;
        uint negativeVotes;
        bool isResolved;
    }

    // --- Events ---

    event IdentityRegistered(address indexed identityAddress, string handle, string metadataURI);
    event IdentityMetadataUpdated(address indexed identityAddress, string newMetadataURI);
    event SkillAdded(string skillName);
    event SkillEndorsed(uint endorsementId, address indexed endorser, address indexed targetIdentity, string skillName);
    event EndorsementRevoked(uint endorsementId);
    event ReputationScoreUpdated(address indexed identityAddress, uint newScore);
    event ReputationDelegated(address indexed delegator, address indexed delegatee);
    event ReputationUndelegated(address indexed delegator);
    event IdentityReported(uint reportId, address indexed reporter, address indexed targetIdentity, string reportReason);
    event ReportVoteCast(uint reportId, address indexed voter, bool vote);
    event ReportResolved(uint reportId, bool resolutionOutcome);
    event ReputationThresholdSet(string functionName, uint threshold);
    event AdminRoleSet(address indexed adminAddress, bool isAdmin);
    event ModeratorRoleSet(address indexed moderatorAddress, bool isModerator);

    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function.");
        _;
    }

    modifier onlyAdmin() {
        require(administrators[msg.sender] || msg.sender == contractOwner, "Only administrators or contract owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender] || administrators[msg.sender] || msg.sender == contractOwner, "Only moderators, administrators, or contract owner can call this function.");
        _;
    }

    modifier identityExists() {
        require(isIdentityRegistered(msg.sender), "Identity not registered.");
        _;
    }

    modifier reputationRequired(string memory _functionName) {
        require(checkReputationAccess(msg.sender, _functionName), "Insufficient reputation to access this function.");
        _;
    }

    // --- Constructor ---

    constructor() {
        contractOwner = msg.sender;
        administrators[msg.sender] = true; // Owner is also an admin
    }

    // --- 1. Identity Management ---

    function registerIdentity(string memory _handle, string memory _metadataURI) public {
        require(!isIdentityRegistered(msg.sender), "Identity already registered for this address.");
        require(!registeredHandles[_handle], "Handle already taken.");
        require(bytes(_handle).length > 0 && bytes(_handle).length <= 32, "Handle must be between 1 and 32 characters.");
        require(bytes(_metadataURI).length <= 256, "Metadata URI too long.");

        identities[msg.sender] = Identity({
            handle: _handle,
            metadataURI: _metadataURI,
            registrationTimestamp: block.timestamp
        });
        registeredHandles[_handle] = true;

        emit IdentityRegistered(msg.sender, _handle, _metadataURI);
    }

    function updateIdentityMetadata(string memory _newMetadataURI) public identityExists {
        require(bytes(_newMetadataURI).length <= 256, "New metadata URI too long.");
        identities[msg.sender].metadataURI = _newMetadataURI;
        emit IdentityMetadataUpdated(msg.sender, _newMetadataURI);
    }

    function resolveIdentity(address _identityAddress) public view returns (string memory handle, string memory metadataURI, uint registrationTimestamp) {
        require(isIdentityRegistered(_identityAddress), "Identity not registered for this address.");
        Identity storage identity = identities[_identityAddress];
        return (identity.handle, identity.metadataURI, identity.registrationTimestamp);
    }

    function isIdentityRegistered(address _address) public view returns (bool) {
        return bytes(identities[_address].handle).length > 0;
    }

    // --- 2. Skill-Based Endorsements ---

    function addSkill(string memory _skillName) public onlyAdmin {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 64, "Skill name must be between 1 and 64 characters.");
        require(!skills[bytes32(_skillName)].isEnabled, "Skill already added."); // Using bytes32 for mapping key

        skills[bytes32(_skillName)] = Skill({
            name: _skillName,
            weight: 1, // Default weight
            isEnabled: true
        });
        skillList.push(_skillName);
        emit SkillAdded(_skillName);
    }

    function endorseSkill(address _targetIdentity, string memory _skillName, string memory _endorsementStatement) public identityExists {
        require(isIdentityRegistered(_targetIdentity), "Target identity not registered.");
        require(skills[bytes32(_skillName)].isEnabled, "Skill not recognized.");
        require(msg.sender != _targetIdentity, "Cannot endorse yourself.");
        require(bytes(_endorsementStatement).length <= 512, "Endorsement statement too long.");

        endorsementCount++;
        endorsements[endorsementCount] = Endorsement({
            id: endorsementCount,
            endorser: msg.sender,
            targetIdentity: _targetIdentity,
            skillName: _skillName,
            endorsementStatement: _endorsementStatement,
            endorsementTimestamp: block.timestamp,
            isActive: true
        });

        emit SkillEndorsed(endorsementCount, msg.sender, _targetIdentity, _skillName);
        updateReputationScore(_targetIdentity); // Update target's reputation
    }

    function getEndorsementsForSkill(address _identityAddress, string memory _skillName) public view returns (Endorsement[] memory) {
        require(isIdentityRegistered(_identityAddress), "Identity not registered.");
        require(skills[bytes32(_skillName)].isEnabled, "Skill not recognized.");

        Endorsement[] memory skillEndorsements = new Endorsement[](endorsementCount); // Over-allocating, will trim later
        uint count = 0;
        for (uint i = 1; i <= endorsementCount; i++) {
            if (endorsements[i].isActive && endorsements[i].targetIdentity == _identityAddress && keccak256(bytes(endorsements[i].skillName)) == keccak256(bytes(_skillName))) {
                skillEndorsements[count] = endorsements[i];
                count++;
            }
        }

        // Trim the array to the actual number of endorsements
        Endorsement[] memory trimmedEndorsements = new Endorsement[](count);
        for (uint i = 0; i < count; i++) {
            trimmedEndorsements[i] = skillEndorsements[i];
        }
        return trimmedEndorsements;
    }

    function revokeEndorsement(uint _endorsementId) public identityExists {
        require(endorsements[_endorsementId].endorser == msg.sender, "Only the endorser can revoke.");
        require(endorsements[_endorsementId].isActive, "Endorsement is already revoked or invalid.");
        require(block.timestamp >= endorsements[_endorsementId].endorsementTimestamp + endorsementRevocationCooldown, "Revocation cooldown period not yet passed.");

        endorsements[_endorsementId].isActive = false;
        emit EndorsementRevoked(_endorsementId);
        updateReputationScore(endorsements[_endorsementId].targetIdentity); // Update target's reputation
    }

    // --- 3. Dynamic Reputation Scoring ---

    function calculateReputationScore(address _identityAddress) internal view returns (uint) {
        uint score = 0;
        for (uint i = 1; i <= endorsementCount; i++) {
            if (endorsements[i].isActive && endorsements[i].targetIdentity == _identityAddress) {
                uint skillWeight = skillWeights[endorsements[i].skillName];
                if (skillWeight == 0) skillWeight = 1; // Default weight if not set
                score += skillWeight; // Simple sum of weights for now. Can be made more complex.
            }
        }
        return score;
    }

    function getReputationScore(address _identityAddress) public view returns (uint) {
        return reputationScores[_identityAddress];
    }

    function setReputationWeight(string memory _skillName, uint _weight) public onlyAdmin {
        require(skills[bytes32(_skillName)].isEnabled, "Skill not recognized.");
        skillWeights[_skillName] = _weight;
        // No event needed for weight change in this example, could be added.
    }

    function updateReputationScore(address _identityAddress) public onlyModerator { // Can be triggered by admin/moderator or an oracle
        uint newScore = calculateReputationScore(_identityAddress);
        reputationScores[_identityAddress] = newScore;
        emit ReputationScoreUpdated(_identityAddress, newScore);
    }

    // --- 4. Reputation Delegation ---

    function delegateReputation(address _delegatee) public identityExists {
        require(isIdentityRegistered(_delegatee), "Delegatee identity not registered.");
        require(_delegatee != msg.sender, "Cannot delegate to yourself.");
        reputationDelegations[msg.sender] = _delegatee;
        emit ReputationDelegated(msg.sender, _delegatee);
    }

    function undelegateReputation() public identityExists {
        delete reputationDelegations[msg.sender];
        emit ReputationUndelegated(msg.sender);
    }

    function getDelegatedReputation(address _identityAddress) public view returns (address) {
        return reputationDelegations[_identityAddress];
    }

    // --- 5. Decentralized Moderation (Reputation-Weighted) ---

    function reportIdentity(address _targetIdentity, string memory _reportReason) public identityExists {
        require(isIdentityRegistered(_targetIdentity), "Target identity not registered.");
        require(msg.sender != _targetIdentity, "Cannot report yourself.");
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 512, "Report reason must be between 1 and 512 characters.");

        reportCount++;
        reports[reportCount] = Report({
            id: reportCount,
            reporter: msg.sender,
            targetIdentity: _targetIdentity,
            reportReason: _reportReason,
            reportTimestamp: block.timestamp,
            positiveVotes: 0,
            negativeVotes: 0,
            isResolved: false
        });

        emit IdentityReported(reportCount, msg.sender, _targetIdentity, _reportReason);
    }

    function voteOnReport(uint _reportId, bool _vote) public identityExists {
        require(!reports[_reportId].isResolved, "Report is already resolved.");
        require(!reportVotes[_reportId][msg.sender], "Already voted on this report.");

        reportVotes[_reportId][msg.sender] = true;
        if (_vote) {
            reports[_reportId].positiveVotes += getReputationScore(msg.sender); // Reputation-weighted voting
        } else {
            reports[_reportId].negativeVotes += getReputationScore(msg.sender);
        }
        emit ReportVoteCast(_reportId, msg.sender, _vote);
    }

    function resolveReport(uint _reportId) public onlyModerator {
        require(!reports[_reportId].isResolved, "Report is already resolved.");

        reports[_reportId].isResolved = true;
        bool resolutionOutcome = reports[_reportId].positiveVotes > reports[_reportId].negativeVotes; // Simple majority based on reputation weight for now.
        emit ReportResolved(_reportId, resolutionOutcome);
        // In a real system, resolutionOutcome would trigger actions like temporary suspension, etc.
    }

    function getReportDetails(uint _reportId) public view returns (Report memory) {
        return reports[_reportId];
    }

    // --- 6. Reputation-Gated Access Control ---

    function setReputationThreshold(string memory _functionName, uint _threshold) public onlyAdmin {
        reputationThresholds[_functionName] = _threshold;
        emit ReputationThresholdSet(_functionName, _threshold);
    }

    function checkReputationAccess(address _identityAddress, string memory _functionName) internal view returns (bool) {
        uint threshold = reputationThresholds[_functionName];
        if (threshold == 0) return true; // No threshold set, access granted
        return getReputationScore(_identityAddress) >= threshold;
    }

    // Example function with reputation-gated access:
    function advancedFeature() public identityExists reputationRequired("advancedFeature") returns (string memory) {
        return "Access granted to advanced feature due to sufficient reputation.";
    }

    // --- 7. Oracle Functions & Administration ---

    function setAdminRole(address _adminAddress, bool _isAdmin) public onlyOwner {
        administrators[_adminAddress] = _isAdmin;
        emit AdminRoleSet(_adminAddress, _isAdmin);
    }

    function setModeratorRole(address _moderatorAddress, bool _isModerator) public onlyAdmin {
        moderators[_moderatorAddress] = _isModerator;
        emit ModeratorRoleSet(_moderatorAddress, _isModerator);
    }

    function isAdministrator(address _address) public view returns (bool) {
        return administrators[_address];
    }

    function isModerator(address _address) public view returns (bool) {
        return moderators[_address];
    }

    // --- 8. Utility & View Functions ---

    function getSkillList() public view returns (string[] memory) {
        return skillList;
    }

    function getContractOwner() public view returns (address) {
        return contractOwner;
    }

    // --- Fallback and Receive (Optional for this contract, but good practice for some) ---

    receive() external payable {
        // Optional: Handle ETH reception if needed, or revert if not intended.
        // For this reputation contract, probably not needed, so can leave empty to revert.
    }

    fallback() external payable {
        // Optional: Handle fallback calls if needed, or revert.
    }
}
```