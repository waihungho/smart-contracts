Okay, here is a Solidity smart contract implementing a "Soulbound Reputation System". This system allows users to mint a non-transferable Soulbound Token (SBT) which acts as their identity within the system. Various roles (like Reputation Managers and Attesters) can then build reputation for these identities by awarding achievements, updating scores for different reputation types, and issuing attestations (endorsements) that influence scores.

This design incorporates:
*   **Soulbound Tokens (SBTs):** Using ERC721 but explicitly disabling transfers.
*   **Role-Based Access Control:** Using OpenZeppelin's `AccessControl` for fine-grained permissions.
*   **Multi-faceted Reputation:** Tracking different categories of reputation (e.g., Developer, Community, Governance).
*   **Achievements:** On-chain recording of milestones.
*   **Attestations (Endorsements):** A mechanism for authorized parties to endorse users, with configurable impact on scores.
*   **On-chain Data Storage:** Keeping reputation data linked to the SBT identity.

It aims to be interesting by combining identity (SBTs) with dynamic reputation building through curated actions (achievements, score updates) and decentralized input (attestations from designated roles).

---

**Outline & Function Summary**

**Contract:** `SoulboundReputationSystem`

**Core Concept:** A decentralized system to build and manage non-transferable (Soulbound) reputation scores and achievements tied to user identities (represented by ERC721 SBTs). Access is controlled by roles.

**Roles:**
*   `DEFAULT_ADMIN_ROLE`: Can grant/revoke other roles.
*   `REPUTATION_MANAGER_ROLE`: Can update reputation scores directly and award/revoke achievements.
*   `ATTESTER_ROLE`: Can issue and revoke attestations (endorsements) which impact scores.

**Structs:**
*   `Achievement`: Represents a specific achievement awarded to a user.
*   `Attestation`: Represents an endorsement from an attester about a user's reputation.

**State Variables:**
*   `_tokenCounter`: Tracks the total number of SBTs minted.
*   `_attestationCounter`: Tracks the total number of attestations issued.
*   `_userTokenId`: Maps user address to their SBT token ID.
*   `_tokenIdUser`: Maps SBT token ID to user address (standard ERC721 requirement).
*   `_reputationScores`: Maps token ID -> reputation type (bytes32) -> score (uint256).
*   `_userAchievements`: Maps token ID -> array of Achievements.
*   `_attestations`: Maps attestation ID -> Attestation struct.
*   `_userReceivedAttestations`: Maps token ID -> array of attestation IDs received.
*   `_userIssuedAttestations`: Maps attester address -> array of attestation IDs issued.
*   `_registeredReputationTypes`: Set/mapping of valid reputation type hashes.
*   `_minAttestationScoreImpact`: Minimum score change an attestation can suggest.
*   `_maxAttestationScoreImpact`: Maximum score change an attestation can suggest.
*   `_allowAttestationRevocation`: Flag to enable/disable attestation revocation.
*   `_allowAchievementRevocation`: Flag to enable/disable achievement revocation.

**Events:**
*   `ReputationTokenMinted`: When an SBT is minted.
*   `ReputationScoreUpdated`: When a score is changed.
*   `AchievementAwarded`: When an achievement is granted.
*   `AchievementRevoked`: When an achievement is removed.
*   `AttestationIssued`: When an attestation is created.
*   `AttestationRevoked`: When an attestation is removed.
*   `ReputationTypeRegistered`: When a new reputation type is added.
*   `AttestationParamsUpdated`: When attestation configuration changes.

**Functions:**

1.  `constructor()`: Initializes the contract, sets up AccessControl, grants admin role.
2.  `supportsInterface(bytes4 interfaceId) public view override returns (bool)`: Standard ERC165 interface support, including ERC721 and AccessControl.
3.  `registerReputationType(bytes32 reputationType) public onlyRole(DEFAULT_ADMIN_ROLE)`: Registers a new valid category of reputation.
4.  `getRegisteredReputationTypes() public view returns (bytes32[] memory)`: Returns all currently registered reputation types.
5.  `mintReputationToken(address user) public onlyRole(REPUTATION_MANAGER_ROLE)`: Mints a new SBT for a specific user. Fails if the user already has one.
6.  `burnReputationToken(uint256 tokenId) public onlyRole(REPUTATION_MANAGER_ROLE)`: Burns a user's SBT and potentially clears associated data.
7.  `tokenExistsForUser(address user) public view returns (bool)`: Checks if a user address has an associated SBT.
8.  `getTokenIdForUser(address user) public view returns (uint256)`: Gets the SBT token ID for a user address.
9.  `getOwnerOfTokenId(uint256 tokenId) public view returns (address)`: Gets the user address for a given SBT token ID (standard ERC721 ownerOf).
10. `updateReputationScore(uint256 tokenId, bytes32 reputationType, uint256 newScore) public onlyRole(REPUTATION_MANAGER_ROLE)`: Sets or updates the score for a specific reputation type for a user's SBT.
11. `getReputationScoreByType(uint256 tokenId, bytes32 reputationType) public view returns (uint256)`: Gets the score for a specific reputation type for a user's SBT.
12. `calculateTotalScore(uint256 tokenId) public view returns (uint256)`: Calculates a simple sum of all registered reputation scores for a user's SBT.
13. `awardAchievement(uint256 tokenId, string memory name, string memory description) public onlyRole(REPUTATION_MANAGER_ROLE)`: Awards a named achievement to a user's SBT.
14. `revokeAchievement(uint256 tokenId, uint256 achievementIndex) public onlyRole(REPUTATION_MANAGER_ROLE)`: Revokes an achievement from a user's SBT by its index in their achievement list. Requires `_allowAchievementRevocation` to be true.
15. `getUserAchievements(uint256 tokenId) public view returns (Achievement[] memory)`: Returns the list of achievements for a user's SBT.
16. `attestReputation(uint256 tokenId, bytes32 reputationType, int256 scoreImpact, string memory details) public onlyRole(ATTESTER_ROLE)`: An attester issues an attestation about a user's reputation, potentially influencing their score based on `scoreImpact`.
17. `revokeAttestation(uint256 attestationId) public onlyRole(ATTESTER_ROLE)`: The original attester revokes a previously issued attestation. Requires `_allowAttestationRevocation` to be true.
18. `getAttestationDetails(uint256 attestationId) public view returns (Attestation memory)`: Retrieves details of a specific attestation by ID.
19. `getUserReceivedAttestations(uint256 tokenId) public view returns (uint256[] memory)`: Returns a list of attestation IDs received by a user's SBT.
20. `getUserIssuedAttestations(address attester) public view returns (uint256[] memory)`: Returns a list of attestation IDs issued by an attester address.
21. `setMinAttestationScoreImpact(int256 minImpact) public onlyRole(DEFAULT_ADMIN_ROLE)`: Sets the minimum allowed score impact for attestations.
22. `setMaxAttestationScoreImpact(int256 maxImpact) public onlyRole(DEFAULT_ADMIN_ROLE)`: Sets the maximum allowed score impact for attestations.
23. `setAttestationRevocationAllowed(bool allowed) public onlyRole(DEFAULT_ADMIN_ROLE)`: Toggles whether attestations can be revoked.
24. `setAchievementRevocationAllowed(bool allowed) public onlyRole(DEFAULT_ADMIN_ROLE)`: Toggles whether achievements can be revoked.
25. `tokenURI(uint256 tokenId) public view override returns (string memory)`: Standard ERC721 function to return metadata URI (placeholder implementation).
26. `balanceOf(address owner) public view override returns (uint256)`: Standard ERC721 function to get the balance (will always be 0 or 1 for an SBT owner).
27. `transferFrom(address from, address to, uint256 tokenId) public pure override`: **OVERRIDDEN to prevent transfer.**
28. `safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override`: **OVERRIDDEN to prevent transfer.**
29. `safeTransferFrom(address from, address to, uint256 tokenId) public pure override`: **OVERRIDDEN to prevent transfer.**
30. `getRoleAdmin(bytes32 role) public view override returns (bytes32)`: Standard AccessControl function.
31. `hasRole(bytes32 role, address account) public view override returns (bool)`: Standard AccessControl function.
32. `grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE)`: Standard AccessControl function.
33. `revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE)`: Standard AccessControl function.
34. `renounceRole(bytes32 role, address account) public override`: Standard AccessControl function.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Soulbound Reputation System
/// @author Your Name/Alias (Adapt as needed)
/// @notice A smart contract for managing soulbound (non-transferable) reputation tokens,
/// achievements, and attestations tied to user identities.
/// Access and actions are controlled via predefined roles.

contract SoulboundReputationSystem is ERC721, AccessControl {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using Address for address;
    using Strings for uint256;

    // --- Roles ---
    bytes32 public constant REPUTATION_MANAGER_ROLE = keccak256("REPUTATION_MANAGER_ROLE");
    bytes32 public constant ATTESTER_ROLE = keccak256("ATTESTER_ROLE");

    // --- Counters ---
    Counters.Counter private _tokenCounter;
    Counters.Counter private _attestationCounter;

    // --- Data Structures ---
    struct Achievement {
        string name;
        string description;
        uint64 timestamp; // Using uint64 for potentially shorter timestamps
    }

    struct Attestation {
        uint256 id; // Redundant storage but useful for lookup
        address attester;
        uint256 tokenId; // Recipient token ID
        bytes32 reputationType;
        int256 scoreImpact; // Signed integer to allow positive or negative impact
        string details;
        uint64 timestamp;
        bool revoked; // Soft delete flag
    }

    // --- State Variables ---

    // User address <-> Token ID (for quick lookup if user has a token)
    mapping(address => uint256) private _userTokenId;

    // Token ID <-> User address (ERC721 requirement, inverse of above)
    mapping(uint256 => address) private _tokenIdUser;

    // Token ID <-> Reputation Type (bytes32) <-> Score
    mapping(uint256 => mapping(bytes32 => uint256)) private _reputationScores;

    // Token ID <-> Array of Achievements
    mapping(uint256 => Achievement[]) private _userAchievements;

    // Attestation ID <-> Attestation struct
    mapping(uint256 => Attestation) private _attestations;

    // Token ID <-> Array of received Attestation IDs
    mapping(uint256 => uint256[]) private _userReceivedAttestations;

    // Attester address <-> Array of issued Attestation IDs
    mapping(address => uint256[]) private _userIssuedAttestations;

    // Set of registered reputation types
    EnumerableSet.Bytes32Set private _registeredReputationTypes;

    // Attestation configuration
    int256 private _minAttestationScoreImpact;
    int256 private _maxAttestationScoreImpact;
    bool private _allowAttestationRevocation;
    bool private _allowAchievementRevocation;

    // --- Events ---
    event ReputationTokenMinted(address indexed user, uint256 indexed tokenId);
    event ReputationScoreUpdated(uint256 indexed tokenId, bytes32 indexed reputationType, uint256 oldScore, uint256 newScore);
    event AchievementAwarded(uint256 indexed tokenId, string name, uint64 timestamp);
    event AchievementRevoked(uint256 indexed tokenId, uint256 indexed achievementIndex);
    event AttestationIssued(uint256 indexed attestationId, address indexed attester, uint256 indexed tokenId, bytes32 reputationType, int256 scoreImpact);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker, uint256 indexed tokenId);
    event ReputationTypeRegistered(bytes32 indexed reputationType);
    event AttestationParamsUpdated(int256 minImpact, int256 maxImpact, bool allowAttestationRevocation, bool allowAchievementRevocation);


    // --- Constructor ---
    constructor() ERC721("SoulboundReputation", "SBR") {
        // Grant the deployer the default admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Initialize attestation parameters (example values)
        _minAttestationScoreImpact = -100; // Can decrease score
        _maxAttestationScoreImpact = 100;  // Can increase score
        _allowAttestationRevocation = true;
        _allowAchievementRevocation = true;

        emit AttestationParamsUpdated(_minAttestationScoreImpact, _maxAttestationScoreImpact, _allowAttestationRevocation, _allowAchievementRevocation);
    }

    // --- Standard ERC165 Support ---
    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
        return interfaceId == type(ERC721).interfaceId ||
               interfaceId == type(AccessControl).interfaceId ||
               super.supportsInterface(interfaceId);
    }

    // --- Reputation Type Management ---

    /// @notice Registers a new category of reputation that can be tracked.
    /// Only callable by accounts with the DEFAULT_ADMIN_ROLE.
    /// @param reputationType The bytes32 hash of the reputation type (e.g., keccak256("DEVELOPER_REP")).
    function registerReputationType(bytes32 reputationType) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(reputationType != 0, "Invalid reputation type");
        require(!_registeredReputationTypes.contains(reputationType), "Reputation type already registered");
        _registeredReputationTypes.add(reputationType);
        emit ReputationTypeRegistered(reputationType);
    }

    /// @notice Returns the list of currently registered reputation types.
    /// @return An array of bytes32 representing the registered reputation types.
    function getRegisteredReputationTypes() public view returns (bytes32[] memory) {
        return _registeredReputationTypes.values();
    }

    // --- SBT Core (Minting & Burning) ---

    /// @notice Mints a new Soulbound Reputation Token for a specific user.
    /// This token represents their identity in the system and is non-transferable.
    /// Only callable by accounts with the REPUTATION_MANAGER_ROLE.
    /// @param user The address of the user to mint the token for.
    function mintReputationToken(address user) public onlyRole(REPUTATION_MANAGER_ROLE) {
        require(user != address(0), "Cannot mint to the zero address");
        require(_userTokenId[user] == 0, "User already has a reputation token");

        _tokenCounter.increment();
        uint256 newTokenId = _tokenCounter.current();

        _safeMint(user, newTokenId); // SafeMint handles ERC721 standard checks

        _userTokenId[user] = newTokenId;
        _tokenIdUser[newTokenId] = user;

        emit ReputationTokenMinted(user, newTokenId);
    }

    /// @notice Burns a user's Soulbound Reputation Token.
    /// This effectively removes their identity and associated data from the system.
    /// Only callable by accounts with the REPUTATION_MANAGER_ROLE.
    /// @param tokenId The ID of the token to burn.
    function burnReputationToken(uint256 tokenId) public onlyRole(REPUTATION_MANAGER_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        address user = ownerOf(tokenId); // ownerOf check ensures token belongs to someone

        // Clear mappings (important to do before burning the token data)
        delete _userTokenId[user];
        delete _tokenIdUser[tokenId];
        delete _reputationScores[tokenId];
        delete _userAchievements[tokenId];

        // Soft delete attestations involving this token
        uint256[] storage receivedAttestations = _userReceivedAttestations[tokenId];
        for (uint i = 0; i < receivedAttestations.length; i++) {
            uint256 attId = receivedAttestations[i];
            if (_attestations[attId].id != 0) { // Check if attestation struct exists
                _attestations[attId].revoked = true; // Mark as revoked instead of deleting
            }
        }
        delete _userReceivedAttestations[tokenId];

        // Note: Issued attestations by this user remain, but point to a burned token

        _burn(tokenId); // ERC721 burn

        // No specific event for burn in this design, mint event is sufficient for lifecycle tracking
    }

    /// @notice Checks if a given user address has an associated Soulbound Reputation Token.
    /// @param user The address to check.
    /// @return True if the user has a token, false otherwise.
    function tokenExistsForUser(address user) public view returns (bool) {
        return _userTokenId[user] != 0;
    }

    /// @notice Gets the Soulbound Reputation Token ID for a given user address.
    /// @param user The address to get the token ID for.
    /// @return The token ID, or 0 if the user does not have a token.
    function getTokenIdForUser(address user) public view returns (uint256) {
        return _userTokenId[user];
    }

    /// @notice Gets the owner address for a given Soulbound Reputation Token ID.
    /// @param tokenId The token ID to get the owner for.
    /// @return The owner's address.
    function getOwnerOfTokenId(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId); // Uses the ERC721 internal ownerOf
    }

    // --- Soulbound Mechanism (Preventing Transfers) ---

    /// @notice Internal function called before any token transfer.
    /// Overridden to prevent any transfer from happening, enforcing soulbound nature.
    /// @param from The address the token is being transferred from.
    /// @param to The address the token is being transferred to.
    /// @param tokenId The ID of the token being transferred.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal pure override {
        // Prevent any transfers (except minting to non-zero address and burning from non-zero address)
        if (from != address(0) && to != address(0)) {
             revert("SBR: Token is soulbound and cannot be transferred");
        }
        // Allow minting (from address(0)) and burning (to address(0))
    }

    /// @notice Explicitly override ERC721 transfer functions to make them revert.
    /// This provides clarity that transfers are not allowed.
    function transferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBR: Token is soulbound and cannot be transferred");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public pure override {
        revert("SBR: Token is soulbound and cannot be transferred");
    }

     function safeTransferFrom(address from, address to, uint256 tokenId) public pure override {
        revert("SBR: Token is soulbound and cannot be transferred");
    }

    /// @notice Helper view function to confirm the soulbound nature.
    /// @return Always returns true.
    function isSoulbound() public pure returns (bool) {
        return true;
    }

    // --- Reputation Scoring ---

    /// @notice Updates the score for a specific reputation type for a user's SBT.
    /// Only callable by accounts with the REPUTATION_MANAGER_ROLE.
    /// The reputation type must be registered.
    /// @param tokenId The ID of the user's token.
    /// @param reputationType The bytes32 hash of the reputation type (e.g., keccak256("DEVELOPER_REP")).
    /// @param newScore The new score to set.
    function updateReputationScore(uint256 tokenId, bytes32 reputationType, uint256 newScore) public onlyRole(REPUTATION_MANAGER_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(_registeredReputationTypes.contains(reputationType), "Reputation type not registered");

        uint256 oldScore = _reputationScores[tokenId][reputationType];
        _reputationScores[tokenId][reputationType] = newScore;

        emit ReputationScoreUpdated(tokenId, reputationType, oldScore, newScore);
    }

    /// @notice Gets the score for a specific reputation type for a user's SBT.
    /// @param tokenId The ID of the user's token.
    /// @param reputationType The bytes32 hash of the reputation type.
    /// @return The score for the specified type, or 0 if not set.
    function getReputationScoreByType(uint256 tokenId, bytes32 reputationType) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        require(_registeredReputationTypes.contains(reputationType), "Reputation type not registered");
        return _reputationScores[tokenId][reputationType];
    }

    /// @notice Calculates a simple total score by summing up all registered reputation types for a user's SBT.
    /// @param tokenId The ID of the user's token.
    /// @return The total calculated score.
    function calculateTotalScore(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");

        uint256 totalScore = 0;
        bytes32[] memory registeredTypes = _registeredReputationTypes.values();
        for (uint i = 0; i < registeredTypes.length; i++) {
            totalScore += _reputationScores[tokenId][registeredTypes[i]];
        }
        return totalScore;
    }

    // --- Achievements ---

    /// @notice Awards an achievement to a user's SBT.
    /// Only callable by accounts with the REPUTATION_MANAGER_ROLE.
    /// @param tokenId The ID of the user's token.
    /// @param name The name of the achievement.
    /// @param description The description of the achievement.
    function awardAchievement(uint256 tokenId, string memory name, string memory description) public onlyRole(REPUTATION_MANAGER_ROLE) {
        require(_exists(tokenId), "Token does not exist");

        _userAchievements[tokenId].push(Achievement(name, description, uint64(block.timestamp)));

        emit AchievementAwarded(tokenId, name, uint64(block.timestamp));
    }

    /// @notice Revokes a specific achievement from a user's SBT by its index.
    /// Only callable by accounts with the REPUTATION_MANAGER_ROLE.
    /// Requires `_allowAchievementRevocation` to be true.
    /// Note: Revoking by index can be fragile if achievements are added/removed frequently.
    /// A more robust approach would use unique achievement IDs.
    /// @param tokenId The ID of the user's token.
    /// @param achievementIndex The index of the achievement in the user's list.
    function revokeAchievement(uint256 tokenId, uint256 achievementIndex) public onlyRole(REPUTATION_MANAGER_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(_allowAchievementRevocation, "Achievement revocation is not allowed");
        require(achievementIndex < _userAchievements[tokenId].length, "Invalid achievement index");

        // Simple removal by swapping with last and popping (order doesn't matter for this list)
        uint lastIndex = _userAchievements[tokenId].length - 1;
        Achievement memory revoked = _userAchievements[tokenId][achievementIndex];

        if (achievementIndex != lastIndex) {
            _userAchievements[tokenId][achievementIndex] = _userAchievements[tokenId][lastIndex];
        }
        _userAchievements[tokenId].pop();

        emit AchievementRevoked(tokenId, achievementIndex);
    }

    /// @notice Returns the list of achievements awarded to a user's SBT.
    /// @param tokenId The ID of the user's token.
    /// @return An array of Achievement structs.
    function getUserAchievements(uint256 tokenId) public view returns (Achievement[] memory) {
        require(_exists(tokenId), "Token does not exist");
        return _userAchievements[tokenId];
    }

    // --- Attestations (Endorsements) ---

    /// @notice An attester issues an attestation about a user's reputation in a specific category.
    /// This attestation can suggest a score impact, which is applied to the user's score.
    /// Only callable by accounts with the ATTESTER_ROLE.
    /// The reputation type must be registered.
    /// @param tokenId The ID of the user's token being attested.
    /// @param reputationType The bytes32 hash of the reputation type the attestation relates to.
    /// @param scoreImpact The signed integer value suggesting the change in score. Clamped between min/max allowed impact.
    /// @param details Additional details about the attestation.
    function attestReputation(uint256 tokenId, bytes32 reputationType, int256 scoreImpact, string memory details) public onlyRole(ATTESTER_ROLE) {
        require(_exists(tokenId), "Recipient token does not exist");
        require(_registeredReputationTypes.contains(reputationType), "Reputation type not registered");
        require(scoreImpact >= _minAttestationScoreImpact && scoreImpact <= _maxAttestationScoreImpact, "Score impact out of allowed range");
        address attester = msg.sender;

        _attestationCounter.increment();
        uint256 attestationId = _attestationCounter.current();

        _attestations[attestationId] = Attestation(
            attestationId,
            attester,
            tokenId,
            reputationType,
            scoreImpact,
            details,
            uint64(block.timestamp),
            false // not revoked initially
        );

        _userReceivedAttestations[tokenId].push(attestationId);
        _userIssuedAttestations[attester].push(attestationId);

        // Apply the score impact immediately
        _applyAttestationScoreImpact(tokenId, reputationType, scoreImpact);

        emit AttestationIssued(attestationId, attester, tokenId, reputationType, scoreImpact);
    }

    /// @notice The original attester revokes a previously issued attestation.
    /// Only callable by the ATTESTER_ROLE who issued the attestation.
    /// Requires `_allowAttestationRevocation` to be true.
    /// The score impact of the original attestation is reversed.
    /// @param attestationId The ID of the attestation to revoke.
    function revokeAttestation(uint256 attestationId) public onlyRole(ATTESTER_ROLE) {
        require(_allowAttestationRevocation, "Attestation revocation is not allowed");
        Attestation storage attestation = _attestations[attestationId];
        require(attestation.id != 0 && !attestation.revoked, "Attestation does not exist or is already revoked");
        require(attestation.attester == msg.sender, "Only the original attester can revoke");

        attestation.revoked = true; // Soft delete

        // Reverse the score impact
        // Note: Integer underflow/overflow is handled by default in Solidity 0.8+
        // but we need to be careful with potential negative results and casting.
        // Since scores are uint, we must ensure the resulting score is not negative.
        // A more sophisticated system might use a dedicated 'attested_score' mapping.
        // For this simple example, we'll just subtract the impact.
        // If scoreImpact was 10, we subtract 10. If it was -5, we subtract -5 (add 5).
        // This might lead to scores below 0 if not careful, but we assume scoreImpact logic is simple increment/decrement.
        // Let's update based on the *current* stored score, which might have been influenced by other things.
        // A better approach is to store the 'attestation_score' and only sum those up.
        // For this example, let's revert the *impact* itself.
        _applyAttestationScoreImpact(attestation.tokenId, attestation.reputationType, -attestation.scoreImpact); // Subtract the original impact

        emit AttestationRevoked(attestationId, msg.sender, attestation.tokenId);
    }

    /// @notice Internal function to apply or reverse the score impact of an attestation.
    /// Handles potential negative results safely.
    /// @param tokenId The token ID affected.
    /// @param reputationType The reputation type affected.
    /// @param impact The signed score impact (positive to add, negative to subtract).
    function _applyAttestationScoreImpact(uint256 tokenId, bytes32 reputationType, int256 impact) internal {
        uint256 currentScore = _reputationScores[tokenId][reputationType];
        uint256 newScore;

        if (impact >= 0) {
            newScore = currentScore + uint256(impact);
        } else {
            uint256 absImpact = uint256(-impact);
            // Prevent score from going below zero
            newScore = (currentScore > absImpact) ? currentScore - absImpact : 0;
        }

        _reputationScores[tokenId][reputationType] = newScore;

        // Emit event for score change (even if from internal attestation)
        emit ReputationScoreUpdated(tokenId, reputationType, currentScore, newScore);
    }


    /// @notice Retrieves the details of a specific attestation by its ID.
    /// @param attestationId The ID of the attestation.
    /// @return The Attestation struct.
    function getAttestationDetails(uint256 attestationId) public view returns (Attestation memory) {
        require(_attestations[attestationId].id != 0, "Attestation does not exist");
        return _attestations[attestationId];
    }

    /// @notice Returns a list of attestation IDs that a user's SBT has received.
    /// Does NOT filter revoked attestations.
    /// @param tokenId The ID of the user's token.
    /// @return An array of attestation IDs.
    function getUserReceivedAttestations(uint256 tokenId) public view returns (uint256[] memory) {
        require(_exists(tokenId), "Token does not exist");
        return _userReceivedAttestations[tokenId];
    }

    /// @notice Returns a list of attestation IDs that a specific attester address has issued.
    /// Does NOT filter revoked attestations.
    /// @param attester The address of the attester.
    /// @return An array of attestation IDs.
    function getUserIssuedAttestations(address attester) public view returns (uint256[] memory) {
        require(attester != address(0), "Invalid attester address");
        return _userIssuedAttestations[attester];
    }

    // --- Admin/Configuration Functions ---

    /// @notice Sets the minimum allowed score impact value for attestations.
    /// Only callable by accounts with the DEFAULT_ADMIN_ROLE.
    /// @param minImpact The new minimum impact value (can be negative).
    function setMinAttestationScoreImpact(int256 minImpact) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(minImpact <= _maxAttestationScoreImpact, "Min impact cannot be greater than max");
        _minAttestationScoreImpact = minImpact;
        emit AttestationParamsUpdated(_minAttestationScoreImpact, _maxAttestationScoreImpact, _allowAttestationRevocation, _allowAchievementRevocation);
    }

    /// @notice Sets the maximum allowed score impact value for attestations.
    /// Only callable by accounts with the DEFAULT_ADMIN_ROLE.
    /// @param maxImpact The new maximum impact value.
    function setMaxAttestationScoreImpact(int256 maxImpact) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(maxImpact >= _minAttestationScoreImpact, "Max impact cannot be less than min");
        _maxAttestationScoreImpact = maxImpact;
        emit AttestationParamsUpdated(_minAttestationScoreImpact, _maxAttestationScoreImpact, _allowAttestationRevocation, _allowAchievementRevocation);
    }

    /// @notice Toggles whether attestation revocation is allowed.
    /// Only callable by accounts with the DEFAULT_ADMIN_ROLE.
    /// @param allowed True to allow, false to disallow.
    function setAttestationRevocationAllowed(bool allowed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _allowAttestationRevocation = allowed;
        emit AttestationParamsUpdated(_minAttestationScoreImpact, _maxAttestationScoreImpact, _allowAttestationRevocation, _allowAchievementRevocation);
    }

     /// @notice Toggles whether achievement revocation is allowed.
    /// Only callable by accounts with the DEFAULT_ADMIN_ROLE.
    /// @param allowed True to allow, false to disallow.
    function setAchievementRevocationAllowed(bool allowed) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _allowAchievementRevocation = allowed;
        emit AttestationParamsUpdated(_minAttestationScoreImpact, _maxAttestationScoreImpact, _allowAttestationRevocation, _allowAchievementRevocation);
    }

    // --- Configuration View Functions ---

    /// @notice Gets the current minimum allowed attestation score impact.
    function getMinAttestationScoreImpact() public view returns (int256) {
        return _minAttestationScoreImpact;
    }

     /// @notice Gets the current maximum allowed attestation score impact.
    function getMaxAttestationScoreImpact() public view returns (int256) {
        return _maxAttestationScoreImpact;
    }

     /// @notice Checks if attestation revocation is currently allowed.
    function isAttestationRevocationAllowed() public view returns (bool) {
        return _allowAttestationRevocation;
    }

     /// @notice Checks if achievement revocation is currently allowed.
    function isAchievementRevocationAllowed() public view returns (bool) {
        return _allowAchievementRevocation;
    }


    // --- ERC721 Standard View Functions (Overrides/Placeholders) ---

    /// @notice Returns the number of tokens in the owner's account.
    /// For an SBT, this will always be 0 or 1.
    /// @param owner The address to query the balance of.
    /// @return The balance (0 or 1).
    function balanceOf(address owner) public view override returns (uint256) {
        // Simple check based on whether the user has a registered token ID
        return _userTokenId[owner] != 0 ? 1 : 0;
    }

    /// @notice Base URI for token metadata (placeholder).
    /// Implement this to return actual metadata JSON according to ERC721.
    /// @param tokenId The token ID.
    /// @return A placeholder string.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        // In a real implementation, generate a URL pointing to metadata for this token ID
        // For example: string(abi.encodePacked("https://myreputationsystem.io/metadata/", tokenId.toString()));
        return string(abi.encodePacked("ipfs://placeholder-metadata/", tokenId.toString()));
    }


    // --- AccessControl View Functions (Inherited but good to list for clarity) ---

    /// @notice Returns the admin role that can grant and revoke `role`.
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return super.getRoleAdmin(role);
    }

    /// @notice Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view override returns (bool) {
         return super.hasRole(role, account);
    }

    /// @notice Grants `role` to `account`. Only `DEFAULT_ADMIN_ROLE` can grant/revoke roles in this contract.
    /// Emits a {RoleGranted} event.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.grantRole(role, account);
    }

    /// @notice Revokes `role` from `account`. Only `DEFAULT_ADMIN_ROLE` can grant/revoke roles in this contract.
    /// Emits a {RoleRevoked} event.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        super.revokeRole(role, account);
    }

    /// @notice Renounces `role` from the calling account.
    /// Emits a {RoleRevoked} event.
    function renounceRole(bytes32 role, address account) public override {
        super.renounceRole(role, account);
    }
}
```