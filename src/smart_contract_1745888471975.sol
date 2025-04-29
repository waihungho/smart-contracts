Okay, here is a Solidity smart contract implementing a "Decentralized Attestation & Reputation Network" (DARN) with Dynamic Soulbound NFTs. This concept focuses on on-chain identity, structured attestations between users, a reputation score derived from these attestations, and a Non-Fungible Token (NFT) whose metadata dynamically updates to reflect the user's current on-chain reputation. It avoids standard patterns like ERC20, AMMs, basic staking pools, or simple governance. It incorporates concepts like structured data, on-chain computation for reputation, and dynamic NFT metadata generation.

To meet the requirement of *not* duplicating open source, the ERC721 implementation and basic access control patterns are implemented manually in a simplified form, rather than importing OpenZeppelin. Similarly, Base64 encoding is included directly.

---

### Outline & Function Summary

**Concept:** Decentralized Attestation & Reputation Network (DARN) with Dynamic Reputation NFTs.
Users can register, issue structured attestations about other users, and their reputation score is calculated based on received attestations and configurable weights. A non-transferable NFT represents this dynamic score, with its metadata updated on-chain.

**Core Components:**
1.  **User Profiles:** Basic registration and profile data.
2.  **Attestations:** Structured data points issued by one user about another, including type, value, and context.
3.  **Reputation Score:** Calculated based on received, unrevoked attestations and configurable weights per attestation type.
4.  **Dynamic Reputation NFT:** A Soulbound (non-transferable) ERC721 token tied to a user's address, whose `tokenURI` dynamically generates metadata reflecting their current reputation score and attestation data.
5.  **Configuration:** Owner can set weights for different attestation types.
6.  **Pausability:** Standard admin pause functionality.

**State Variables:**
*   `owner`: Contract owner address.
*   `paused`: Paused state flag.
*   `userProfiles`: Mapping of user addresses to `UserProfile` struct.
*   `registeredUsers`: Mapping of user addresses to boolean indicating registration.
*   `userIds`: Array of registered user addresses (potentially gas-heavy for large user bases, simplified for function count).
*   `attestations`: Mapping of attestation ID to `Attestation` struct.
*   `attestationsIssued`: Mapping of attester address to array of attestation IDs they issued.
*   `attestationsReceived`: Mapping of recipient address to array of attestation IDs they received.
*   `attestationCount`: Counter for total attestations issued.
*   `attestationWeights`: Mapping of attestation type (uint256) to weight (uint256).
*   `userReputationScores`: Mapping of user address to their stored reputation score.
*   `userReputationNFT`: Mapping of user address to their NFT token ID.
*   `nftTokenIdToUser`: Mapping of NFT token ID back to user address.
*   `nftTotalSupply`: Counter for minted NFTs.

**Structs:**
*   `UserProfile`: Stores user's name, profile URI, and registration status.
*   `Attestation`: Stores attester, recipient, type, value, context, timestamp, and revocation status.

**Events:**
*   `UserProfileRegistered`: Emitted when a user registers.
*   `UserProfileUpdated`: Emitted when a user updates their profile.
*   `AttestationIssued`: Emitted when an attestation is created.
*   `AttestationRevoked`: Emitted when an attestation is revoked.
*   `ReputationScoreUpdated`: Emitted when a user's reputation score is recalculated.
*   `ReputationNFTMinted`: Emitted when a user mints their NFT.
*   `ReputationNFTMetadataUpdated`: Emitted when an NFT's associated metadata should be considered updated (e.g., after score change).
*   `Paused`: Emitted when the contract is paused.
*   `Unpaused`: Emitted when the contract is unpaused.
*   `AttestationWeightSet`: Emitted when an attestation weight is configured.

**Functions (Total: 30+)**
1.  `constructor()`: Initializes contract with owner.
2.  `pause()`: Owner-only function to pause the contract.
3.  `unpause()`: Owner-only function to unpause the contract.
4.  `setAttestationWeight(uint256 _attestationType, uint256 _weight)`: Owner-only function to set weight for an attestation type.
5.  `getAttestationWeight(uint256 _attestationType) view`: Gets the weight for an attestation type.
6.  `registerUser(string calldata _name, string calldata _profileURI)`: Allows an address to register a user profile.
7.  `updateUserProfile(string calldata _name, string calldata _profileURI)`: Allows a registered user to update their profile.
8.  `getUserProfile(address _user) view`: Gets a user's profile details.
9.  `isUserRegistered(address _user) view`: Checks if an address is registered.
10. `issueAttestation(address _toUser, uint256 _attestationType, int256 _scoreValue, string calldata _context)`: Allows a registered user to issue an attestation about another registered user.
11. `revokeAttestation(uint256 _attestationId)`: Allows the original attester to revoke an attestation.
12. `getAttestationDetails(uint256 _attestationId) view`: Gets details of a specific attestation.
13. `getAttestationsIssuedBy(address _user) view`: Gets array of attestation IDs issued by a user.
14. `getAttestationsReceivedBy(address _user) view`: Gets array of attestation IDs received by a user.
15. `getAttestationCountByType(address _user, uint256 _attestationType) view`: Gets the count of unrevoked attestations of a specific type received by a user.
16. `getReputationScore(address _user) view`: Gets the stored reputation score for a user.
17. `calculateReputationScore(address _user) view`: *Calculates* the current reputation score based on live, unrevoked attestations (does not update state).
18. `mintReputationNFT()`: Allows a registered user to mint their unique Reputation NFT (only one per user).
19. `hasReputationNFT(address _user) view`: Checks if a user has minted their NFT.
20. `getTokenIdForUser(address _user) view`: Gets the NFT token ID for a user.
21. `getUserForTokenId(uint256 _tokenId) view`: Gets the user address associated with an NFT token ID.
22. `tokenURI(uint256 _tokenId) override view`: Generates the dynamic metadata URI for the NFT based on the associated user's current reputation score and profile.
23. `getTotalRegisteredUsers() view`: Gets the total count of registered users.
24. `getTotalAttestations() view`: Gets the total count of attestations issued (including revoked).
25. `name() view override`: ERC721 name getter.
26. `symbol() view override`: ERC721 symbol getter.
27. `balanceOf(address _owner) view override`: ERC721 balance getter (will be 0 or 1 for user).
28. `ownerOf(uint256 _tokenId) view override`: ERC721 owner getter.
29. `approve(address _to, uint256 _tokenId) override`: ERC721 approve (disabled for Soulbound).
30. `getApproved(uint256 _tokenId) view override`: ERC721 approved getter (will be address(0) for Soulbound).
31. `setApprovalForAll(address _operator, bool _approved) override`: ERC721 set approval for all (disabled for Soulbound).
32. `isApprovedForAll(address _owner, address _operator) view override`: ERC721 is approved for all getter (will be false for Soulbound).
33. `transferFrom(address _from, address _to, uint256 _tokenId) override`: ERC721 transfer (disabled for Soulbound).
34. `safeTransferFrom(address _from, address _to, uint256 _tokenId) override`: ERC721 safe transfer (disabled for Soulbound).
35. `safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) override`: ERC721 safe transfer with data (disabled for Soulbound).

*Note: Functions 29-35 are effectively disabled to make the NFT "Soulbound" or non-transferable, but included to override the standard ERC721 interface.*

---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Decentralized Attestation & Reputation Network (DARN) with Dynamic Soulbound NFTs
/// @dev This contract implements a system for users to register, issue structured attestations about
///      each other, maintain a reputation score based on these attestations, and mint a unique,
///      non-transferable NFT whose metadata dynamically reflects their current on-chain reputation.
///      It includes a manual, simplified implementation of ERC721 principles for the Soulbound NFT
///      and a basic Base64 encoder for dynamic tokenURI generation.
///      The contract avoids standard library imports (like OpenZeppelin) to meet the requirement
///      of not duplicating open source contract structures directly, while still adhering to
///      relevant standards (like the ERC721 interface).

// --- Outline & Function Summary ---
// Concept: Decentralized Attestation & Reputation Network (DARN) with Dynamic Reputation NFTs.
// Core Components: User Profiles, Attestations, Reputation Score, Dynamic Reputation NFT, Configuration, Pausability.
// State Variables: owner, paused, userProfiles, registeredUsers, userIds (simplified), attestations,
//                  attestationsIssued, attestationsReceived, attestationCount, attestationWeights,
//                  userReputationScores, userReputationNFT, nftTokenIdToUser, nftTotalSupply.
// Structs: UserProfile, Attestation.
// Events: UserProfileRegistered, UserProfileUpdated, AttestationIssued, AttestationRevoked,
//         ReputationScoreUpdated, ReputationNFTMinted, ReputationNFTMetadataUpdated,
//         Paused, Unpaused, AttestationWeightSet.
// Functions (Total: 35+):
//  1. constructor(): Initializes contract.
//  2. pause(): Owner-only pause.
//  3. unpause(): Owner-only unpause.
//  4. setAttestationWeight(): Owner sets type weight.
//  5. getAttestationWeight(): Gets type weight.
//  6. registerUser(): Registers a user.
//  7. updateUserProfile(): Updates registered profile.
//  8. getUserProfile(): Gets user profile.
//  9. isUserRegistered(): Checks registration.
// 10. issueAttestation(): Issues attestation.
// 11. revokeAttestation(): Revokes attestation.
// 12. getAttestationDetails(): Gets attestation details.
// 13. getAttestationsIssuedBy(): Gets issued attestation IDs.
// 14. getAttestationsReceivedBy(): Gets received attestation IDs.
// 15. getAttestationCountByType(): Gets count of specific type received.
// 16. getReputationScore(): Gets stored reputation score.
// 17. calculateReputationScore(): Calculates current score (view).
// 18. mintReputationNFT(): Mints user's NFT.
// 19. hasReputationNFT(): Checks if user has NFT.
// 20. getTokenIdForUser(): Gets user's NFT ID.
// 21. getUserForTokenId(): Gets user from NFT ID.
// 22. tokenURI(): Generates dynamic NFT metadata.
// 23. getTotalRegisteredUsers(): Gets total users.
// 24. getTotalAttestations(): Gets total attestations.
// 25. name(): ERC721 name.
// 26. symbol(): ERC721 symbol.
// 27. balanceOf(): ERC721 balance.
// 28. ownerOf(): ERC721 owner.
// 29. approve(): ERC721 approve (disabled).
// 30. getApproved(): ERC721 approved (disabled).
// 31. setApprovalForAll(): ERC721 set approval for all (disabled).
// 32. isApprovedForAll(): ERC721 is approved for all (disabled).
// 33. transferFrom(): ERC721 transfer (disabled).
// 34. safeTransferFrom(): ERC721 safeTransfer (disabled).
// 35. safeTransferFrom() with data: ERC721 safeTransfer (disabled).
// + Internal helper functions.

// --- Custom Errors ---
error NotOwner();
error Paused();
error NotPaused();
error UserAlreadyRegistered();
error UserNotRegistered(address user);
error AttestationNotFound(uint256 attestationId);
error NotAttestationIssuer();
error AttestationAlreadyRevoked();
error AttestationWeightZero();
error NFTAlreadyMinted();
error NFTNotFoundForUser();
error TokenDoesNotExist();
error NotNFTOwner(); // For transfer functions, though disabled
error TransferToZeroAddress(); // For transfer functions, though disabled
error TransferBlocked(); // For soulbound property

// --- Base64 Encoder (Simplified, Non-Optimized) ---
library Base64 {
    string internal constant alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // Load the alphabet into memory
        bytes memory table = bytes(alphabet);

        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory encoded = new bytes(encodedLen);

        uint256 i = 0;
        uint256 j = 0;
        while (i < data.length) {
            uint256 chunk;
            uint256 bytesLoaded = 0;
            for (uint256 k = 0; k < 3; ++k) {
                if (i + k < data.length) {
                    chunk = chunk | (uint256(data[i + k]) << (8 * (2 - k)));
                    bytesLoaded++;
                }
            }

            if (bytesLoaded == 3) {
                encoded[j + 0] = table[(chunk >> 18) & 0x3F];
                encoded[j + 1] = table[(chunk >> 12) & 0x3F];
                encoded[j + 2] = table[(chunk >> 6) & 0x3F];
                encoded[j + 3] = table[chunk & 0x3F];
            } else if (bytesLoaded == 2) {
                encoded[j + 0] = table[(chunk >> 18) & 0x3F];
                encoded[j + 1] = table[(chunk >> 12) & 0x3F];
                encoded[j + 2] = table[(chunk >> 6) & 0x3F];
                encoded[j + 3] = '=';
            } else if (bytesLoaded == 1) {
                encoded[j + 0] = table[(chunk >> 18) & 0x3F];
                encoded[j + 1] = table[(chunk >> 12) & 0x3F];
                encoded[j + 2] = '=';
                encoded[j + 3] = '=';
            }

            i += bytesLoaded;
            j += 4;
        }

        return string(encoded);
    }
}


contract DARN is /* Manual ERC721 Interface */ {

    using Base64 for bytes; // Enable Base64.encode() on bytes

    // --- State Variables ---
    address private owner;
    bool private paused;

    struct UserProfile {
        address userAddress;
        string name;
        string profileURI; // URI to off-chain profile data/avatar
        bool isRegistered;
    }

    mapping(address => UserProfile) private userProfiles;
    mapping(address => bool) private registeredUsers; // Redundant check, but potentially faster lookup
    address[] private userIds; // Simplified: array for iteration, not scalable for huge user bases

    struct Attestation {
        uint256 id;
        address attester;
        address toUser;
        uint256 attestationType; // e.g., 1=Skill, 2=Reliability, 3=Contribution
        int256 scoreValue;      // e.g., +10 for good, -5 for bad
        string context;         // Short description or URI
        uint48 timestamp;
        bool isRevoked;
    }

    mapping(uint256 => Attestation) private attestations;
    mapping(address => uint256[]) private attestationsIssued;
    mapping(address => uint256[]) private attestationsReceived;
    uint256 private attestationCount;

    mapping(uint256 => uint256) private attestationWeights; // type => weight (multiplier)

    mapping(address => int256) private userReputationScores; // Stored calculated score

    // --- Dynamic Soulbound NFT (Manual ERC721 Implementation) ---
    mapping(address => uint256) private userReputationNFT; // user => tokenId
    mapping(uint256 => address) private nftTokenIdToUser; // tokenId => user
    mapping(uint256 => address) private _tokenApprovals; // Not used for soulbound, but part of interface
    mapping(address => mapping(address => bool)) private _operatorApprovals; // Not used for soulbound
    uint256 private nftTotalSupply; // Counter for token IDs

    string private constant _name = "DARN Reputation NFT";
    string private constant _symbol = "DARN.REP";

    // --- Events ---
    event UserProfileRegistered(address indexed user, string name, string profileURI);
    event UserProfileUpdated(address indexed user, string name, string profileURI);
    event AttestationIssued(uint256 indexed attestationId, address indexed attester, address indexed toUser, uint256 attestationType, int256 scoreValue, string context);
    event AttestationRevoked(uint256 indexed attestationId, address indexed revoker, address indexed toUser);
    event ReputationScoreUpdated(address indexed user, int256 newScore);
    event ReputationNFTMinted(address indexed user, uint256 indexed tokenId);
    event ReputationNFTMetadataUpdated(uint256 indexed tokenId, address indexed user, int256 reputationScore);
    event Paused(address account);
    event Unpaused(address account);
    event AttestationWeightSet(uint256 indexed attestationType, uint256 weight);

    // --- Modifiers (Manual Ownable & Pausable) ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!paused) revert NotPaused();
        _;
    }

    modifier userRegistered(address _user) {
        if (!registeredUsers[_user]) revert UserNotRegistered(_user);
        _;
    }

    // --- Constructor ---
    constructor() {
        owner = msg.sender;
        paused = false;
        attestationCount = 0;
        nftTotalSupply = 0;

        // Set some default weights (example)
        attestationWeights[1] = 1;   // Base weight for type 1
        attestationWeights[2] = 2;   // Double weight for type 2
        attestationWeights[3] = 5;   // High weight for type 3
        emit AttestationWeightSet(1, 1);
        emit AttestationWeightSet(2, 2);
        emit AttestationWeightSet(3, 5);
    }

    // --- Pausability (Manual) ---
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // --- Attestation Weight Configuration ---
    function setAttestationWeight(uint256 _attestationType, uint256 _weight) external onlyOwner {
        if (_weight == 0) revert AttestationWeightZero();
        attestationWeights[_attestationType] = _weight;
        emit AttestationWeightSet(_attestationType, _weight);
    }

    function getAttestationWeight(uint256 _attestationType) external view returns (uint256) {
        return attestationWeights[_attestationType];
    }

    // --- User Management ---
    function registerUser(string calldata _name, string calldata _profileURI) external whenNotPaused {
        if (registeredUsers[msg.sender]) revert UserAlreadyRegistered();

        userProfiles[msg.sender] = UserProfile({
            userAddress: msg.sender,
            name: _name,
            profileURI: _profileURI,
            isRegistered: true
        });
        registeredUsers[msg.sender] = true;
        userIds.push(msg.sender); // Add to list (simplified, beware of large arrays)

        emit UserProfileRegistered(msg.sender, _name, _profileURI);
    }

    function updateUserProfile(string calldata _name, string calldata _profileURI) external whenNotPaused userRegistered(msg.sender) {
        userProfiles[msg.sender].name = _name;
        userProfiles[msg.sender].profileURI = _profileURI;
        emit UserProfileUpdated(msg.sender, _name, _profileURI);
    }

    function getUserProfile(address _user) external view userRegistered(_user) returns (UserProfile memory) {
        return userProfiles[_user];
    }

    function isUserRegistered(address _user) external view returns (bool) {
        return registeredUsers[_user];
    }

    // --- Attestation Logic ---
    function issueAttestation(
        address _toUser,
        uint256 _attestationType,
        int256 _scoreValue,
        string calldata _context
    ) external whenNotPaused userRegistered(msg.sender) userRegistered(_toUser) {
        uint256 attestationId = ++attestationCount;

        attestations[attestationId] = Attestation({
            id: attestationId,
            attester: msg.sender,
            toUser: _toUser,
            attestationType: _attestationType,
            scoreValue: _scoreValue,
            context: _context,
            timestamp: uint48(block.timestamp),
            isRevoked: false
        });

        attestationsIssued[msg.sender].push(attestationId);
        attestationsReceived[_toUser].push(attestationId);

        _updateReputationScore(_toUser); // Update recipient's score

        emit AttestationIssued(attestationId, msg.sender, _toUser, _attestationType, _scoreValue, _context);
    }

    function revokeAttestation(uint256 _attestationId) external whenNotPaused {
        Attestation storage att = attestations[_attestationId];
        if (att.attester == address(0)) revert AttestationNotFound(_attestationId); // Check if attestation exists
        if (att.attester != msg.sender) revert NotAttestationIssuer();
        if (att.isRevoked) revert AttestationAlreadyRevoked();

        att.isRevoked = true;
        _updateReputationScore(att.toUser); // Update recipient's score

        emit AttestationRevoked(_attestationId, msg.sender, att.toUser);
    }

    function getAttestationDetails(uint256 _attestationId) external view returns (Attestation memory) {
        Attestation storage att = attestations[_attestationId];
        if (att.attester == address(0)) revert AttestationNotFound(_attestationId);
        return att;
    }

    function getAttestationsIssuedBy(address _user) external view userRegistered(_user) returns (uint256[] memory) {
        return attestationsIssued[_user];
    }

    function getAttestationsReceivedBy(address _user) external view userRegistered(_user) returns (uint256[] memory) {
        return attestationsReceived[_user];
    }

    function getAttestationCountByType(address _user, uint256 _attestationType) external view userRegistered(_user) returns (uint256) {
        uint256 count = 0;
        uint256[] memory receivedIds = attestationsReceived[_user];
        for (uint256 i = 0; i < receivedIds.length; i++) {
            Attestation storage att = attestations[receivedIds[i]];
            // Check if it's not revoked and matches the type
            if (!att.isRevoked && att.attestationType == _attestationType) {
                count++;
            }
        }
        return count;
    }

    // --- Reputation Score Logic ---
    function _updateReputationScore(address _user) internal {
        int256 totalScore = 0;
        uint256[] memory receivedIds = attestationsReceived[_user];

        // Calculate weighted sum of unrevoked attestations
        for (uint256 i = 0; i < receivedIds.length; i++) {
            Attestation storage att = attestations[receivedIds[i]];
            if (!att.isRevoked) {
                 uint256 weight = attestationWeights[att.attestationType];
                 // Default weight is 1 if not set
                 if (weight == 0) weight = 1;
                 totalScore += att.scoreValue * int256(weight);
            }
        }

        // Store the calculated score
        userReputationScores[_user] = totalScore;

        emit ReputationScoreUpdated(_user, totalScore);

        // If user has an NFT, signal metadata update
        if (hasReputationNFT(_user)) {
            uint256 tokenId = userReputationNFT[_user];
            emit ReputationNFTMetadataUpdated(tokenId, _user, totalScore);
        }
    }

    function getReputationScore(address _user) public view userRegistered(_user) returns (int256) {
        // Returns the last stored score
        return userReputationScores[_user];
    }

    function calculateReputationScore(address _user) public view userRegistered(_user) returns (int256) {
         // Calculates the current score without updating state
        int256 totalScore = 0;
        uint256[] memory receivedIds = attestationsReceived[_user];

        for (uint256 i = 0; i < receivedIds.length; i++) {
            Attestation storage att = attestations[receivedIds[i]];
            if (!att.isRevoked) {
                 uint256 weight = attestationWeights[att.attestationType];
                 if (weight == 0) weight = 1; // Default weight
                 totalScore += att.scoreValue * int256(weight);
            }
        }
        return totalScore;
    }

    // --- Dynamic Soulbound NFT (Manual ERC721 Implementation) ---

    // ERC721 Metadata
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    // ERC721 Basic Getters
    function balanceOf(address _owner) public view override returns (uint256) {
        if (_owner == address(0)) revert TransferToZeroAddress(); // Standard check
        // Since it's 1-per-user soulbound, balance is 1 if they have an NFT, 0 otherwise.
        return hasReputationNFT(_owner) ? 1 : 0;
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address ownerAddress = nftTokenIdToUser[_tokenId];
        if (ownerAddress == address(0)) revert TokenDoesNotExist();
        return ownerAddress;
    }

    // Soulbound ERC721 overrides (disabling transfers/approvals)
    function approve(address, uint256) public pure override {
        revert TransferBlocked(); // Soulbound: Approvals disabled
    }

    function getApproved(uint256) public pure override returns (address) {
         revert TransferBlocked(); // Soulbound: Approvals disabled
    }

    function setApprovalForAll(address, bool) public pure override {
         revert TransferBlocked(); // Soulbound: Approvals disabled
    }

    function isApprovedForAll(address, address) public pure override returns (bool) {
         revert TransferBlocked(); // Soulbound: Approvals disabled
    }

    function transferFrom(address, address, uint256) public pure override {
         revert TransferBlocked(); // Soulbound: Transfers disabled
    }

    function safeTransferFrom(address, address, uint256) public pure override {
         revert TransferBlocked(); // Soulbound: Transfers disabled
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) public pure override {
         revert TransferBlocked(); // Soulbound: Transfers disabled
    }

    // NFT Minting
    function mintReputationNFT() external whenNotPaused userRegistered(msg.sender) {
        if (hasReputationNFT(msg.sender)) revert NFTAlreadyMinted();

        uint256 newTokenId = ++nftTotalSupply;
        userReputationNFT[msg.sender] = newTokenId;
        nftTokenIdToUser[newTokenId] = msg.sender;

        // Note: ERC721 requires emitting Transfer event on minting from address(0)
        // We simulate this without a full ERC721 implementation base
        emit Transfer(address(0), msg.sender, newTokenId);
        emit ReputationNFTMinted(msg.sender, newTokenId);

        // Update the score and signal metadata update after minting
        _updateReputationScore(msg.sender);
    }

    // Helper check for NFT existence
    function hasReputationNFT(address _user) public view returns (bool) {
        return userReputationNFT[_user] != 0;
    }

    // Get NFT token ID for a user
    function getTokenIdForUser(address _user) public view userRegistered(_user) returns (uint256) {
        if (!hasReputationNFT(_user)) revert NFTNotFoundForUser();
        return userReputationNFT[_user];
    }

    // Get user address from NFT token ID
    function getUserForTokenId(uint256 _tokenId) public view returns (address) {
        address user = nftTokenIdToUser[_tokenId];
        if (user == address(0)) revert TokenDoesNotExist();
        return user;
    }

    // Dynamic Metadata Generation
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        address user = nftTokenIdToUser[_tokenId];
        if (user == address(0)) revert TokenDoesNotExist();

        UserProfile storage profile = userProfiles[user]; // Assume user is registered if they have an NFT
        int256 currentScore = userReputationScores[user]; // Get the stored score

        // Basic structure for the JSON metadata
        // Dynamically include profile name, description, current score, etc.
        // An image could be a data URI SVG generated based on score or a static image URI
        string memory json = string(abi.encodePacked(
            '{"name": "DARN Reputation NFT for ', profile.name, '",',
            '"description": "Represents the on-chain reputation score from DARN attestations.",',
            '"image": "data:image/svg+xml;base64,', // Placeholder for SVG image (can be more complex)
            Base64.encode(bytes(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="200">',
                '<rect width="100%" height="100%" fill="#1a1a1a"/>',
                '<text x="150" y="100" font-family="monospace" font-size="20" fill="#ffffff" text-anchor="middle">',
                'Reputation Score:',
                '</text>',
                 '<text x="150" y="130" font-family="monospace" font-size="30" fill="', _getScoreColor(currentScore), '" text-anchor="middle">',
                _int256ToString(currentScore),
                '</text>',
                '<text x="150" y="180" font-family="monospace" font-size="12" fill="#cccccc" text-anchor="middle">',
                 'Updated: ', _uint256ToString(uint256(block.timestamp)),
                 '</text>',
                '</svg>'
            ))), '",',
            '"attributes": [',
            '{"trait_type": "Reputation Score", "value": ', _int256ToString(currentScore), '},',
            '{"trait_type": "Attestations Received", "value": ', _uint256ToString(attestationsReceived[user].length), '}',
            // Add more attributes based on aggregated attestation data if needed
            ']}'
        ));

        // Prepend data URI scheme and base64 encoding
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // Internal helper for converting int256 to string (basic)
    function _int256ToString(int256 _value) internal pure returns (string memory) {
        if (_value == 0) return "0";
        bool negative = _value < 0;
        if (negative) _value = -_value;

        uint256 value = uint256(_value);
        bytes memory buffer = new bytes(32); // Max length for a 256-bit number string + sign
        uint256 i = buffer.length;

        while (value != 0) {
            i--;
            buffer[i] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }

        if (negative) {
            i--;
            buffer[i] = '-';
        }

        return string(buffer[i:]);
    }

     // Internal helper for converting uint256 to string (basic)
    function _uint256ToString(uint256 _value) internal pure returns (string memory) {
        if (_value == 0) return "0";
        uint256 temp = _value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (_value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + _value % 10));
            _value /= 10;
        }
        return string(buffer);
    }

    // Internal helper for getting color based on score (for SVG)
    function _getScoreColor(int256 _score) internal pure returns (string memory) {
        if (_score > 100) return "#00ff00"; // Green
        if (_score > 50) return "#ffff00"; // Yellow
        if (_score > 0) return "#ffa500"; // Orange
        if (_score < 0) return "#ff0000"; // Red
        return "#ffffff"; // White for 0 or neutral
    }


    // --- Public Query Functions ---
    function getTotalRegisteredUsers() external view returns (uint256) {
        return userIds.length; // Simplified count
    }

    function getTotalAttestations() external view returns (uint256) {
        return attestationCount;
    }

    // --- Minimal ERC721 Interface Compliance (for tools/explorers) ---
    // These events are required by ERC721 standard, emitted manually on minting.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}
```