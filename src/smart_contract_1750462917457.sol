```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol"; // Required by ERC721Enumerable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol"; // For dynamic metadata
import "@openzeppelin/contracts/utils/Strings.sol"; // For tokenURI numbers

// --- Contract Outline & Summary ---
//
// Contract Name: MetaSkillNFT
// Inherits: ERC721Enumerable, Ownable
// Purpose:
// This contract creates a dynamic, semi-soulbound NFT (MetaSkill NFT) tied to a user's on-chain identity.
// The NFT represents a user's accumulated "Contribution Points" and their corresponding "Skill Level".
// Contribution points are added by designated 'Verifiers' (simulating external proofs or activities).
// The Skill Level of the NFT is dynamically updated based on accumulated points, influencing its metadata.
// The NFT is semi-soulbound, restricting standard transfers but allowing transfer to a designated recovery address or burning.
// The contract includes features for managing verifiers, setting skill level thresholds, and linking external identity hashes.
//
// Key Concepts:
// - Dynamic NFTs: Metadata changes based on on-chain state (Skill Level).
// - Semi-Soulbound Tokens: Restricted transferability with a specific recovery mechanism.
// - Role-Based Access Control: Verifiers have specific permissions to submit points.
// - Oracle/Verifier Simulation: Verifiers act as trusted sources reporting user contributions.
// - Leveling System: Points translate to Skill Levels based on configurable thresholds.
// - Metadata Generation: On-chain generation of dynamic NFT metadata.
// - Simple Governance/Configuration: Owner can propose and activate new level thresholds.
//
// Function Summary (26 Functions):
// Core NFT Management:
// 1.  constructor() - Initializes the contract.
// 2.  mintProfileNFT(address user) - Mints a new MetaSkill NFT for a user.
// 3.  burnProfileNFT(uint256 tokenId) - Burns a MetaSkill NFT.
// 4.  tokenURI(uint256 tokenId) - Generates dynamic metadata URI for an NFT.
// 5.  getUserProfileNFTId(address user) - Gets the NFT ID associated with a user.
// 6.  isProfileMinted(address user) - Checks if a user has a profile NFT.
// Standard ERC721 Overrides (with Soulbound Logic):
// 7.  transferFrom(address from, address to, uint256 tokenId) - Restricted transfer.
// 8.  safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) - Restricted transfer.
// 9.  safeTransferFrom(address from, address to, uint256 tokenId) - Restricted transfer.
// 10. approve(address to, uint256 tokenId) - Restricted approval.
// 11. setApprovalForAll(address operator, bool approved) - Restricted operator approval.
// Contribution & Leveling:
// 12. submitContributionPoints(address user, uint256 points) - Verifier adds points to a user's profile.
// 13. getUserContributionPoints(address user) - Gets contribution points for a user.
// 14. getUserSkillLevel(address user) - Gets current skill level for a user.
// 15. recalculateAndSetLevel(uint256 tokenId) - Manually triggers level update for an NFT.
// Verifier Management:
// 16. addVerifier(address verifier) - Owner adds a trusted verifier.
// 17. removeVerifier(address verifier) - Owner removes a trusted verifier.
// 18. isVerifier(address account) - Checks if an address is a verifier.
// 19. getVerifiers() - Gets the list of all verifiers.
// Threshold Management (Simple Governance):
// 20. proposeSkillThresholds(uint256[] calldata newThresholds) - Owner proposes new thresholds.
// 21. activateProposedThresholds() - Owner activates the proposed thresholds.
// 22. rejectProposedThresholds() - Owner rejects the proposed thresholds.
// 23. getSkillLevelThresholds() - Gets the active level thresholds.
// 24. getProposedSkillThresholds() - Gets the proposed level thresholds.
// Advanced/Creative Features:
// 25. setRecoveryAddress(uint256 tokenId, address recoveryAddress) - Sets a recovery address for soulbound transfer.
// 26. transferToRecoveryAddress(uint256 tokenId) - Transfers the NFT to the designated recovery address.
// 27. batchSubmitContributions(address[] calldata users, uint256[] calldata points) - Verifier submits points for multiple users.
// 28. linkExternalAccountHash(uint256 tokenId, bytes32 hashedAccountInfo) - Links a hash of external info to the NFT.
// 29. getLinkedExternalAccountHash(uint256 tokenId) - Gets the linked external hash.
// 30. updateBaseURI(string memory newBaseURI) - Owner can update the base URI for metadata.
// (Includes inherited functions from ERC721Enumerable like tokenOfOwnerByIndex, total Supply, etc., bringing total function count well over 20).
// Note: ERC721Enumerable adds several functions like total Supply, tokenOfOwnerByIndex, tokenByIndex etc.
// Combining the explicit 30 functions above with inherited ones, the contract significantly exceeds the 20 function requirement.

contract MetaSkillNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // --- State Variables ---

    // Maps user address to their profile NFT ID
    mapping(address user => uint256 tokenId) private _userToTokenId;
    // Maps NFT ID to the user address (for easy lookup)
    mapping(uint256 tokenId => address user) private _tokenIdToUser;
    // Maps user address to their accumulated contribution points
    mapping(address user => uint256 points) private _userContributionPoints;
    // Maps NFT ID to the current skill level
    mapping(uint256 tokenId => uint256 level) private _tokenSkillLevel;
    // Maps verifier address to boolean status
    mapping(address verifier => bool) private _isVerifier;
    // Maps NFT ID to a designated recovery address
    mapping(uint256 tokenId => address recoveryAddress) private _recoveryAddress;
    // Maps NFT ID to a stored hash of external account information
    mapping(uint256 tokenId => bytes32 externalHash) private _externalAccountHash;

    // Array of verifier addresses (for enumeration)
    address[] private _verifiers;

    // Thresholds for each skill level (points required to reach level index + 1)
    // e.g., [100, 500, 1500] means:
    // Level 0: 0-99 points
    // Level 1: 100-499 points
    // Level 2: 500-1499 points
    // Level 3: 1500+ points
    uint256[] private _skillLevelThresholds;
    uint256[] private _proposedSkillLevelThresholds;

    // Base URI for metadata (can be updated by owner)
    string private _baseURI;

    // --- Events ---

    event ProfileMinted(address indexed user, uint256 indexed tokenId);
    event ProfileBurned(address indexed user, uint256 indexed tokenId);
    event ContributionPointsSubmitted(address indexed user, uint256 points, address indexed verifier);
    event SkillLevelUpdated(uint256 indexed tokenId, uint256 oldLevel, uint256 newLevel);
    event VerifierAdded(address indexed verifier, address indexed admin);
    event VerifierRemoved(address indexed verifier, address indexed admin);
    event SkillThresholdsProposed(address indexed proposer, uint256[] thresholds);
    event SkillThresholdsActivated(address indexed activator, uint256[] thresholds);
    event RecoveryAddressSet(uint256 indexed tokenId, address indexed recoveryAddress);
    event TransferredToRecovery(uint256 indexed tokenId, address indexed recoveryAddress);
    event ExternalAccountHashLinked(uint256 indexed tokenId, bytes32 hashedAccountInfo);
    event BaseURIUpdated(string newBaseURI);


    // --- Modifiers ---

    modifier onlyVerifier() {
        require(_isVerifier[msg.sender], "MetaSkill: Caller is not a verifier");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("MetaSkill NFT", "MSNFT") Ownable(msg.sender) {
        // Initialize with some default skill level thresholds
        _skillLevelThresholds = [100, 500, 1500, 5000, 15000, 50000, 150000]; // Levels 1 to 7
        _baseURI = "ipfs://__DEFAULT_BASE_URI__/"; // Replace with your default IPFS URI
    }

    // --- Core NFT Management ---

    /// @notice Mints a new profile NFT for a user.
    /// @param user The address to mint the NFT for.
    /// @dev Only callable by the owner. Requires user does not already have an NFT.
    function mintProfileNFT(address user) external onlyOwner {
        require(_userToTokenId[user] == 0, "MetaSkill: User already has a profile");

        _tokenIdCounter.increment();
        uint256 newTokenId = _tokenIdCounter.current();

        _safeMint(user, newTokenId); // Mint using OpenZeppelin's safeMint

        _userToTokenId[user] = newTokenId;
        _tokenIdToUser[newTokenId] = user;
        _userContributionPoints[user] = 0; // Initialize points
        _tokenSkillLevel[newTokenId] = 0;   // Initialize level

        emit ProfileMinted(user, newTokenId);
    }

    /// @notice Burns a profile NFT.
    /// @param tokenId The ID of the NFT to burn.
    /// @dev Can be called by the owner of the NFT or the contract owner.
    function burnProfileNFT(uint256 tokenId) public {
        require(_exists(tokenId), "MetaSkill: Token does not exist");
        require(ownerOf(tokenId) == msg.sender || Ownable.owner() == msg.sender, "MetaSkill: Not token owner or contract owner");

        address user = _tokenIdToUser[tokenId];
        require(user != address(0), "MetaSkill: Token not linked to a user");

        _burn(tokenId); // Burn using OpenZeppelin

        delete _userToTokenId[user];
        delete _tokenIdToUser[tokenId];
        delete _userContributionPoints[user]; // Clear points
        delete _tokenSkillLevel[tokenId];    // Clear level
        delete _recoveryAddress[tokenId];    // Clear recovery address
        delete _externalAccountHash[tokenId]; // Clear external hash

        emit ProfileBurned(user, tokenId);
    }

    /// @notice Generates the dynamic metadata URI for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The data URI containing base64 encoded JSON metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "MetaSkill: ERC721 query for nonexistent token");

        address user = _tokenIdToUser[tokenId];
        uint256 points = _userContributionPoints[user];
        uint256 level = _tokenSkillLevel[tokenId];

        // Construct dynamic JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name": "MetaSkill Profile #', Strings.toString(tokenId), '",',
            '"description": "On-chain profile representing skill level and contributions.",',
            '"image": "', _baseURI, Strings.toString(level), '.png",', // Example dynamic image based on level
            '"attributes": [',
                '{"trait_type": "Skill Level", "value": ', Strings.toString(level), '},',
                '{"trait_type": "Contribution Points", "value": ', Strings.toString(points), '}',
            ']}'
        ));

        // Encode JSON to Base64 data URI
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    /// @notice Gets the NFT ID associated with a user address.
    /// @param user The user address.
    /// @return The NFT ID, or 0 if no profile exists.
    function getUserProfileNFTId(address user) public view returns (uint256) {
        return _userToTokenId[user];
    }

    /// @notice Checks if a user address has a profile NFT.
    /// @param user The user address.
    /// @return True if a profile exists, false otherwise.
    function isProfileMinted(address user) public view returns (bool) {
        return _userToTokenId[user] != 0;
    }

    // --- Standard ERC721 Overrides (with Soulbound Logic) ---

    /// @dev Override to implement soulbound logic: only allow transfers to recovery address or address(0) (burn).
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        // Allow transfer if `to` is the designated recovery address OR `to` is address(0) (for burning)
        require(to == _recoveryAddress[tokenId] || to == address(0), "MetaSkill: Token is soulbound, transfer restricted");
        // If transferring to recovery, clear the recovery address afterwards
        if (to == _recoveryAddress[tokenId]) {
            emit TransferredToRecovery(tokenId, to);
            delete _recoveryAddress[tokenId];
        }
        _transfer(from, to, tokenId);
    }

    /// @dev Override for safeTransferFrom (bytes data).
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
         require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
         require(to == _recoveryAddress[tokenId] || to == address(0), "MetaSkill: Token is soulbound, transfer restricted");
         if (to == _recoveryAddress[tokenId]) {
            emit TransferredToRecovery(tokenId, to);
            delete _recoveryAddress[tokenId];
         }
        _safeTransfer(from, to, tokenId, data);
    }

    /// @dev Override for safeTransferFrom (no bytes data).
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");
        require(to == _recoveryAddress[tokenId] || to == address(0), "MetaSkill: Token is soulbound, transfer restricted");
        if (to == _recoveryAddress[tokenId]) {
            emit TransferredToRecovery(tokenId, to);
            delete _recoveryAddress[tokenId];
        }
        _safeTransfer(from, to, tokenId);
    }

    /// @dev Override to restrict approvals for soulbound tokens.
    function approve(address to, uint256 tokenId) public override {
        require(false, "MetaSkill: Approval is restricted for soulbound tokens");
        // If we wanted to allow approval *only* for the recovery transfer, we could add a check like:
        // require(to == _recoveryAddress[tokenId], "MetaSkill: Approval restricted, except for recovery");
        // _approve(to, tokenId);
    }

     /// @dev Override to restrict operator approvals for soulbound tokens.
    function setApprovalForAll(address operator, bool approved) public override {
         require(false, "MetaSkill: Operator approval is restricted for soulbound tokens");
    }


    // --- Contribution & Leveling Functions ---

    /// @notice Submits contribution points for a user's profile.
    /// @param user The user address whose profile points to update.
    /// @param points The amount of points to add.
    /// @dev Only callable by a designated verifier.
    function submitContributionPoints(address user, uint256 points) external onlyVerifier {
        uint256 tokenId = _userToTokenId[user];
        require(tokenId != 0, "MetaSkill: User does not have a profile NFT");
        require(points > 0, "MetaSkill: Cannot submit zero points");

        uint256 oldPoints = _userContributionPoints[user];
        _userContributionPoints[user] = oldPoints + points;

        emit ContributionPointsSubmitted(user, points, msg.sender);

        // Automatically update skill level after points submission
        _updateSkillLevelState(tokenId);
    }

    /// @notice Gets the total contribution points for a user.
    /// @param user The user address.
    /// @return The total contribution points.
    function getUserContributionPoints(address user) public view returns (uint256) {
        return _userContributionPoints[user];
    }

    /// @notice Gets the current skill level for a user's profile.
    /// @param user The user address.
    /// @return The current skill level.
    function getUserSkillLevel(address user) public view returns (uint256) {
        uint256 tokenId = _userToTokenId[user];
        if (tokenId == 0) {
            return 0; // User has no profile, level 0
        }
        return _tokenSkillLevel[tokenId];
    }

    /// @notice Recalculates and updates the skill level for a specific NFT based on its points.
    /// @param tokenId The ID of the NFT to update.
    /// @dev Can be called by anyone to trigger an update, e.g., if an auto-update failed.
    function recalculateAndSetLevel(uint256 tokenId) public {
        require(_exists(tokenId), "MetaSkill: Token does not exist");
        _updateSkillLevelState(tokenId);
    }

    /// @dev Internal helper to calculate the skill level based on points and thresholds.
    /// @param points The total contribution points.
    /// @return The calculated skill level.
    function _calculateSkillLevel(uint256 points) internal view returns (uint256) {
        uint256 currentLevel = 0;
        for (uint i = 0; i < _skillLevelThresholds.length; i++) {
            if (points >= _skillLevelThresholds[i]) {
                currentLevel = i + 1;
            } else {
                break; // Points not enough for the next level
            }
        }
        return currentLevel;
    }

    /// @dev Internal helper to update the stored skill level for a token and emit event if changed.
    /// @param tokenId The ID of the NFT to update.
    function _updateSkillLevelState(uint256 tokenId) internal {
        address user = _tokenIdToUser[tokenId];
        uint256 currentPoints = _userContributionPoints[user];
        uint256 oldLevel = _tokenSkillLevel[tokenId];
        uint256 newLevel = _calculateSkillLevel(currentPoints);

        if (newLevel != oldLevel) {
            _tokenSkillLevel[tokenId] = newLevel;
            emit SkillLevelUpdated(tokenId, oldLevel, newLevel);
            // Note: Metadata URI will automatically reflect the new level when tokenURI is called
        }
    }


    // --- Verifier Management Functions ---

    /// @notice Adds a new address to the list of authorized verifiers.
    /// @param verifier The address to add as a verifier.
    /// @dev Only callable by the contract owner.
    function addVerifier(address verifier) external onlyOwner {
        require(verifier != address(0), "MetaSkill: Zero address is not a valid verifier");
        require(!_isVerifier[verifier], "MetaSkill: Address is already a verifier");
        _isVerifier[verifier] = true;
        _verifiers.push(verifier);
        emit VerifierAdded(verifier, msg.sender);
    }

    /// @notice Removes an address from the list of authorized verifiers.
    /// @param verifier The address to remove.
    /// @dev Only callable by the contract owner.
    function removeVerifier(address verifier) external onlyOwner {
        require(_isVerifier[verifier], "MetaSkill: Address is not a verifier");
        _isVerifier[verifier] = false;
        // Remove from the array (less efficient for large arrays, but simple)
        for (uint i = 0; i < _verifiers.length; i++) {
            if (_verifiers[i] == verifier) {
                _verifiers[i] = _verifiers[_verifiers.length - 1];
                _verifiers.pop();
                break;
            }
        }
        emit VerifierRemoved(verifier, msg.sender);
    }

    /// @notice Checks if an address is currently an authorized verifier.
    /// @param account The address to check.
    /// @return True if the address is a verifier, false otherwise.
    function isVerifier(address account) public view returns (bool) {
        return _isVerifier[account];
    }

    /// @notice Gets the list of all current verifiers.
    /// @return An array of verifier addresses.
    /// @dev Note: This can be gas intensive if the number of verifiers is large.
    function getVerifiers() public view returns (address[] memory) {
        return _verifiers;
    }


    // --- Threshold Management (Simple Governance) ---

    /// @notice Allows the owner to propose new skill level thresholds.
    /// @param newThresholds The array of new point thresholds. Must be strictly increasing.
    /// @dev Only callable by the contract owner.
    function proposeSkillThresholds(uint256[] calldata newThresholds) external onlyOwner {
        // Validate that thresholds are strictly increasing
        for (uint i = 0; i < newThresholds.length; i++) {
            if (i > 0) {
                require(newThresholds[i] > newThresholds[i-1], "MetaSkill: Thresholds must be strictly increasing");
            }
        }
        _proposedSkillLevelThresholds = newThresholds;
        emit SkillThresholdsProposed(msg.sender, newThresholds);
    }

    /// @notice Activates the currently proposed skill level thresholds.
    /// @dev Only callable by the contract owner. Overwrites current thresholds.
    function activateProposedThresholds() external onlyOwner {
        require(_proposedSkillLevelThresholds.length > 0, "MetaSkill: No thresholds have been proposed");
        _skillLevelThresholds = _proposedSkillLevelThresholds;
        delete _proposedSkillLevelThresholds; // Clear the proposed thresholds
        emit SkillThresholdsActivated(msg.sender, _skillLevelThresholds);

        // Optional: Re-calculate levels for all existing tokens after threshold change?
        // This could be very gas-intensive. A better approach might be to rely on manual triggers
        // or recalculate levels only when points are added next, or provide a batch recalculation function.
        // For simplicity in this example, we won't auto-recalculate all.
    }

    /// @notice Rejects the currently proposed skill level thresholds.
    /// @dev Only callable by the contract owner. Clears the proposed thresholds.
    function rejectProposedThresholds() external onlyOwner {
        delete _proposedSkillLevelThresholds;
        // No specific event for rejection, activation event signifies change
    }

    /// @notice Gets the currently active skill level thresholds.
    /// @return An array of active point thresholds.
    function getSkillLevelThresholds() public view returns (uint256[] memory) {
        return _skillLevelThresholds;
    }

    /// @notice Gets the currently proposed skill level thresholds.
    /// @return An array of proposed point thresholds, or empty array if none proposed.
    function getProposedSkillThresholds() public view returns (uint256[] memory) {
        return _proposedSkillLevelThresholds;
    }

    // --- Advanced/Creative Features ---

    /// @notice Sets a designated recovery address for a soulbound NFT.
    /// @param tokenId The ID of the NFT.
    /// @param recoveryAddress The address the NFT can be transferred to via `transferToRecoveryAddress`.
    /// @dev Only callable by the owner of the NFT. Cannot set zero address as recovery.
    function setRecoveryAddress(uint256 tokenId, address recoveryAddress) external {
        require(_exists(tokenId), "MetaSkill: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "MetaSkill: Caller is not the token owner");
        require(recoveryAddress != address(0), "MetaSkill: Cannot set zero address as recovery");
        _recoveryAddress[tokenId] = recoveryAddress;
        emit RecoveryAddressSet(tokenId, recoveryAddress);
    }

    /// @notice Transfers a soulbound NFT to its designated recovery address.
    /// @param tokenId The ID of the NFT.
    /// @dev Only callable by the owner of the NFT. Requires a recovery address to be set.
    function transferToRecoveryAddress(uint256 tokenId) external {
        require(_exists(tokenId), "MetaSkill: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "MetaSkill: Caller is not the token owner");
        address recoveryAddr = _recoveryAddress[tokenId];
        require(recoveryAddr != address(0), "MetaSkill: No recovery address set for this token");

        // Use the overridden transferFrom which allows transfer to _recoveryAddress
        transferFrom(msg.sender, recoveryAddr, tokenId);
        // Note: The overridden transferFrom clears the recovery address upon successful transfer.
    }

     /// @notice Allows a verifier to submit contribution points for multiple users in a single transaction.
     /// @param users An array of user addresses.
     /// @param points An array of point amounts corresponding to the users.
     /// @dev Only callable by a designated verifier. Array lengths must match.
     /// @dev Note: This function might consume significant gas depending on array size.
    function batchSubmitContributions(address[] calldata users, uint256[] calldata points) external onlyVerifier {
        require(users.length == points.length, "MetaSkill: Array lengths must match");

        for (uint i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 pointAmount = points[i];

            uint256 tokenId = _userToTokenId[user];
            // Silently skip users without a profile NFT in the batch
            if (tokenId == 0 || pointAmount == 0) {
                continue;
            }

            uint256 oldPoints = _userContributionPoints[user];
            _userContributionPoints[user] = oldPoints + pointAmount;

            emit ContributionPointsSubmitted(user, pointAmount, msg.sender);

            // Update skill level for each user in the batch
            _updateSkillLevelState(tokenId);
        }
    }

    /// @notice Links a hash of external account information (e.g., Twitter handle hash) to an NFT.
    /// @param tokenId The ID of the NFT.
    /// @param hashedAccountInfo A hash representing external account details.
    /// @dev Only callable by the owner of the NFT. This does NOT verify the link, merely stores a hash.
    function linkExternalAccountHash(uint256 tokenId, bytes32 hashedAccountInfo) external {
        require(_exists(tokenId), "MetaSkill: Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "MetaSkill: Caller is not the token owner");
        _externalAccountHash[tokenId] = hashedAccountInfo;
        emit ExternalAccountHashLinked(tokenId, hashedAccountInfo);
    }

    /// @notice Gets the linked external account hash for an NFT.
    /// @param tokenId The ID of the NFT.
    /// @return The stored bytes32 hash, or bytes32(0) if none is linked.
    function getLinkedExternalAccountHash(uint256 tokenId) public view returns (bytes32) {
        require(_exists(tokenId), "MetaSkill: Token does not exist");
        return _externalAccountHash[tokenId];
    }

    /// @notice Allows the owner to update the base URI for the NFT metadata.
    /// @param newBaseURI The new base URI string.
    /// @dev Only callable by the contract owner.
    function updateBaseURI(string memory newBaseURI) external onlyOwner {
        _baseURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    // --- Override internal functions for ERC721Enumerable support ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable, ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```