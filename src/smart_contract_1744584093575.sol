```solidity
/**
 * @title Decentralized Dynamic Content Platform - "ContentNexus"
 * @author Bard (Generated Example - Not for Production)
 * @dev A smart contract for a decentralized platform where creators can publish dynamic content NFTs,
 *      users can curate content, participate in governance, and earn rewards.
 *
 * **Outline & Function Summary:**
 *
 * **1. Content NFT Management:**
 *    - `createContentNFT(string _metadataURI, ContentCategory _category)`: Allows creators to mint new Content NFTs with metadata and category.
 *    - `setContentMetadata(uint256 _tokenId, string _newMetadataURI)`: Allows content creators to update the metadata URI of their content NFT.
 *    - `setContentCategory(uint256 _tokenId, ContentCategory _newCategory)`: Allows content creators to change the category of their content NFT.
 *    - `transferContentNFT(address _to, uint256 _tokenId)`: Allows NFT owners to transfer ownership of their content NFTs. (Standard ERC721 transfer)
 *    - `burnContentNFT(uint256 _tokenId)`: Allows content creators to burn (permanently remove) their content NFTs.
 *
 * **2. Content Curation & Categories:**
 *    - `defineContentCategory(string _categoryName)`: Allows the platform owner to define new content categories.
 *    - `getContentCategoryName(ContentCategory _category)`: Returns the name of a content category.
 *    - `reportContent(uint256 _tokenId, string _reportReason)`: Allows users to report content NFTs for violations.
 *    - `moderateContent(uint256 _tokenId, ModerationAction _action)`: Allows platform moderators (governance) to moderate reported content.
 *    - `getContentCategoryCount()`: Returns the total number of defined content categories.
 *
 * **3. User Reputation & Roles:**
 *    - `createUserProfile(string _username, string _profileBio)`: Allows users to create a profile with username and bio.
 *    - `updateUserProfile(string _newUsername, string _newProfileBio)`: Allows users to update their profile information.
 *    - `getUserProfile(address _userAddress)`: Retrieves the profile information of a user.
 *    - `assignModeratorRole(address _userAddress)`: Allows platform owner (or governance) to assign moderator roles.
 *    - `revokeModeratorRole(address _userAddress)`: Allows platform owner (or governance) to revoke moderator roles.
 *    - `isModerator(address _userAddress)`: Checks if an address has moderator role.
 *
 * **4. Platform Governance (Simplified):**
 *    - `submitPlatformProposal(string _proposalDescription)`: Allows users to submit proposals for platform improvements.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows users to vote on active platform proposals.
 *    - `executeProposal(uint256 _proposalId)`: Allows platform owner (or governance after consensus) to execute approved proposals.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a platform proposal.
 *    - `getProposalCount()`: Returns the total number of submitted platform proposals.
 *
 * **5. Platform Utility & Settings:**
 *    - `setPlatformFee(uint256 _newFeePercentage)`: Allows platform owner to set a platform fee percentage on content NFT creations.
 *    - `getPlatformFee()`: Returns the current platform fee percentage.
 *    - `withdrawPlatformFees()`: Allows platform owner to withdraw accumulated platform fees.
 *    - `pauseContract()`: Allows platform owner to pause the contract in case of emergency.
 *    - `unpauseContract()`: Allows platform owner to unpause the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ContentNexus is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _categoryIdCounter;
    Counters.Counter private _proposalIdCounter;

    // Enums
    enum ContentCategory { Undefined } // Undefined is the 0th category, others added dynamically
    enum ModerationAction { NoAction, Warning, Removal }

    // Structs
    struct ContentNFT {
        string metadataURI;
        ContentCategory category;
        address creator;
        uint256 createdAtTimestamp;
        bool isModerated;
        ModerationAction moderationStatus;
        string moderationReason;
    }

    struct UserProfile {
        string username;
        string profileBio;
        uint256 profileCreatedAt;
    }

    struct PlatformProposal {
        string description;
        address proposer;
        uint256 createdAtTimestamp;
        bool isActive;
        uint256 votesFor;
        uint256 votesAgainst;
    }

    // State Variables
    mapping(uint256 => ContentNFT) public contentNFTs;
    mapping(ContentCategory => string) public contentCategoryNames;
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => PlatformProposal) public platformProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => userAddress => voted?
    mapping(address => bool) public isModeratorRole;

    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    uint256 public accumulatedPlatformFees;
    bool public contractPaused = false;

    // Events
    event ContentNFTCreated(uint256 tokenId, address creator, string metadataURI, ContentCategory category);
    event ContentNFTMetadataUpdated(uint256 tokenId, string newMetadataURI);
    event ContentNFTCategoryUpdated(uint256 tokenId, ContentCategory newCategory);
    event ContentNFTBurned(uint256 tokenId);
    event ContentCategoryDefined(ContentCategory categoryId, string categoryName);
    event ContentReported(uint256 tokenId, address reporter, string reportReason);
    event ContentModerated(uint256 tokenId, ModerationAction action, string reason);
    event UserProfileCreated(address userAddress, string username);
    event UserProfileUpdated(address userAddress, string newUsername);
    event ModeratorRoleAssigned(address userAddress);
    event ModeratorRoleRevoked(address userAddress);
    event PlatformProposalSubmitted(uint256 proposalId, address proposer, string description);
    event PlatformProposalVoted(uint256 proposalId, address voter, bool vote);
    event PlatformProposalExecuted(uint256 proposalId);
    event PlatformFeeSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address withdrawnBy);
    event ContractPaused();
    event ContractUnpaused();

    // Modifiers
    modifier onlyModerator() {
        require(isModeratorRole[msg.sender] || owner() == msg.sender, "Caller is not a moderator or owner");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused");
        _;
    }

    // Constructor
    constructor() ERC721("ContentNexusNFT", "CNXNFT") Ownable() {
        _categoryIdCounter.increment(); // Reserve Undefined category at 0
        contentCategoryNames[ContentCategory(0)] = "Undefined";
    }

    // -----------------------------------------------------
    // 1. Content NFT Management
    // -----------------------------------------------------

    /// @notice Allows creators to mint new Content NFTs with metadata and category.
    /// @param _metadataURI URI pointing to the content metadata (e.g., IPFS).
    /// @param _category Content category from the defined categories.
    function createContentNFT(string memory _metadataURI, ContentCategory _category) external payable whenNotPaused {
        uint256 feeAmount = (msg.value * platformFeePercentage) / 100;
        require(msg.value >= feeAmount, "Insufficient fee provided.");
        accumulatedPlatformFees += feeAmount;

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        contentNFTs[tokenId] = ContentNFT({
            metadataURI: _metadataURI,
            category: _category,
            creator: msg.sender,
            createdAtTimestamp: block.timestamp,
            isModerated: false,
            moderationStatus: ModerationAction.NoAction,
            moderationReason: ""
        });

        _mint(msg.sender, tokenId);
        emit ContentNFTCreated(tokenId, msg.sender, _metadataURI, _category);
    }

    /// @notice Allows content creators to update the metadata URI of their content NFT.
    /// @param _tokenId ID of the Content NFT.
    /// @param _newMetadataURI New URI pointing to the updated metadata.
    function setContentMetadata(uint256 _tokenId, string memory _newMetadataURI) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(contentNFTs[_tokenId].creator == msg.sender, "Only creator can update metadata");
        contentNFTs[_tokenId].metadataURI = _newMetadataURI;
        emit ContentNFTMetadataUpdated(_tokenId, _newMetadataURI);
    }

    /// @notice Allows content creators to change the category of their content NFT.
    /// @param _tokenId ID of the Content NFT.
    /// @param _newCategory New content category.
    function setContentCategory(uint256 _tokenId, ContentCategory _newCategory) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(contentNFTs[_tokenId].creator == msg.sender, "Only creator can update category");
        contentNFTs[_tokenId].category = _newCategory;
        emit ContentNFTCategoryUpdated(_tokenId, _newCategory);
    }

    // Standard ERC721 transfer function is already included via ERC721 import

    /// @notice Allows content creators to burn (permanently remove) their content NFTs.
    /// @param _tokenId ID of the Content NFT to burn.
    function burnContentNFT(uint256 _tokenId) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(contentNFTs[_tokenId].creator == msg.sender, "Only creator can burn content");
        // Additional checks could be added here, e.g., cooldown period before burning
        _burn(_tokenId);
        delete contentNFTs[_tokenId]; // Clean up struct data
        emit ContentNFTBurned(_tokenId);
    }

    // -----------------------------------------------------
    // 2. Content Curation & Categories
    // -----------------------------------------------------

    /// @notice Allows the platform owner to define new content categories.
    /// @param _categoryName Name of the new category.
    function defineContentCategory(string memory _categoryName) external onlyOwner whenNotPaused {
        _categoryIdCounter.increment();
        ContentCategory newCategory = ContentCategory(_categoryIdCounter.current());
        contentCategoryNames[newCategory] = _categoryName;
        emit ContentCategoryDefined(newCategory, _categoryName);
    }

    /// @notice Returns the name of a content category.
    /// @param _category Content category enum.
    /// @return string Category name.
    function getContentCategoryName(ContentCategory _category) external view returns (string memory) {
        return contentCategoryNames[_category];
    }

    /// @notice Allows users to report content NFTs for violations.
    /// @param _tokenId ID of the Content NFT being reported.
    /// @param _reportReason Reason for reporting the content.
    function reportContent(uint256 _tokenId, string memory _reportReason) external whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(!contentNFTs[_tokenId].isModerated, "Content is already under moderation or moderated");
        // Consider adding rate limiting to prevent spam reporting

        // Mark content as reported (can add more detailed report tracking if needed)
        contentNFTs[_tokenId].isModerated = true;
        contentNFTs[_tokenId].moderationStatus = ModerationAction.Warning; // Default to warning initially, moderators can adjust
        contentNFTs[_tokenId].moderationReason = _reportReason;
        emit ContentReported(_tokenId, msg.sender, _reportReason);
    }

    /// @notice Allows platform moderators (governance) to moderate reported content.
    /// @param _tokenId ID of the Content NFT to moderate.
    /// @param _action Moderation action to take (Warning, Removal, NoAction).
    function moderateContent(uint256 _tokenId, ModerationAction _action) external onlyModerator whenNotPaused {
        require(_exists(_tokenId), "Token does not exist");
        require(contentNFTs[_tokenId].isModerated, "Content is not reported or under moderation");

        contentNFTs[_tokenId].moderationStatus = _action;
        if (_action == ModerationAction.Removal) {
            _burn(_tokenId); // Remove the content NFT if removed
            delete contentNFTs[_tokenId]; // Clean up struct data
        } else {
            contentNFTs[_tokenId].isModerated = false; // Mark as moderated, even if action is Warning or NoAction
        }
        emit ContentModerated(_tokenId, _action, "Moderation action taken");
    }

    /// @notice Returns the total number of defined content categories.
    /// @return uint256 Category count.
    function getContentCategoryCount() external view returns (uint256) {
        return _categoryIdCounter.current();
    }

    // -----------------------------------------------------
    // 3. User Reputation & Roles
    // -----------------------------------------------------

    /// @notice Allows users to create a profile with username and bio.
    /// @param _username Desired username.
    /// @param _profileBio User's profile bio/description.
    function createUserProfile(string memory _username, string memory _profileBio) external whenNotPaused {
        require(bytes(userProfiles[msg.sender].username).length == 0, "Profile already exists for this address");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileBio: _profileBio,
            profileCreatedAt: block.timestamp
        });
        emit UserProfileCreated(msg.sender, _username);
    }

    /// @notice Allows users to update their profile information.
    /// @param _newUsername New username.
    /// @param _newProfileBio New profile bio.
    function updateUserProfile(string memory _newUsername, string memory _newProfileBio) external whenNotPaused {
        require(bytes(userProfiles[msg.sender].username).length > 0, "No profile exists to update");
        userProfiles[msg.sender].username = _newUsername;
        userProfiles[msg.sender].profileBio = _newProfileBio;
        emit UserProfileUpdated(msg.sender, _newUsername);
    }

    /// @notice Retrieves the profile information of a user.
    /// @param _userAddress Address of the user.
    /// @return UserProfile struct containing profile data.
    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    /// @notice Allows platform owner (or governance) to assign moderator roles.
    /// @param _userAddress Address to assign moderator role to.
    function assignModeratorRole(address _userAddress) external onlyOwner whenNotPaused {
        isModeratorRole[_userAddress] = true;
        emit ModeratorRoleAssigned(_userAddress);
    }

    /// @notice Allows platform owner (or governance) to revoke moderator roles.
    /// @param _userAddress Address to revoke moderator role from.
    function revokeModeratorRole(address _userAddress) external onlyOwner whenNotPaused {
        isModeratorRole[_userAddress] = false;
        emit ModeratorRoleRevoked(_userAddress);
    }

    /// @notice Checks if an address has moderator role.
    /// @param _userAddress Address to check.
    /// @return bool True if address is a moderator, false otherwise.
    function isModerator(address _userAddress) external view returns (bool) {
        return isModeratorRole[_userAddress];
    }

    // -----------------------------------------------------
    // 4. Platform Governance (Simplified)
    // -----------------------------------------------------

    /// @notice Allows users to submit proposals for platform improvements.
    /// @param _proposalDescription Description of the platform proposal.
    function submitPlatformProposal(string memory _proposalDescription) external whenNotPaused {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();
        platformProposals[proposalId] = PlatformProposal({
            description: _proposalDescription,
            proposer: msg.sender,
            createdAtTimestamp: block.timestamp,
            isActive: true,
            votesFor: 0,
            votesAgainst: 0
        });
        emit PlatformProposalSubmitted(proposalId, msg.sender, _proposalDescription);
    }

    /// @notice Allows users to vote on active platform proposals.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _vote True for 'For' vote, false for 'Against' vote.
    function voteOnProposal(uint256 _proposalId, bool _vote) external whenNotPaused {
        require(platformProposals[_proposalId].isActive, "Proposal is not active");
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        proposalVotes[_proposalId][msg.sender] = true; // Mark voter as voted

        if (_vote) {
            platformProposals[_proposalId].votesFor++;
        } else {
            platformProposals[_proposalId].votesAgainst++;
        }
        emit PlatformProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Allows platform owner (or governance after consensus) to execute approved proposals.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(platformProposals[_proposalId].isActive, "Proposal is not active");
        // Simplified execution - in a real governance system, more complex logic would be needed
        // e.g., quorum, voting period, specific actions to execute based on proposal details

        platformProposals[_proposalId].isActive = false; // Mark proposal as executed
        emit PlatformProposalExecuted(_proposalId);
        // Implement actual proposal execution logic here based on proposal description (e.g., changing platform fee, etc.)
        // For this example, we're just marking it as executed.
    }

    /// @notice Retrieves details of a platform proposal.
    /// @param _proposalId ID of the proposal.
    /// @return PlatformProposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view returns (PlatformProposal memory) {
        return platformProposals[_proposalId];
    }

    /// @notice Returns the total number of submitted platform proposals.
    /// @return uint256 Proposal count.
    function getProposalCount() external view returns (uint256) {
        return _proposalIdCounter.current();
    }

    // -----------------------------------------------------
    // 5. Platform Utility & Settings
    // -----------------------------------------------------

    /// @notice Allows platform owner to set a platform fee percentage on content NFT creations.
    /// @param _newFeePercentage New platform fee percentage (e.g., 2 for 2%).
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner whenNotPaused {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /// @notice Returns the current platform fee percentage.
    /// @return uint256 Current platform fee percentage.
    function getPlatformFee() external view returns (uint256) {
        return platformFeePercentage;
    }

    /// @notice Allows platform owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner whenNotPaused {
        uint256 amountToWithdraw = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        payable(owner()).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, owner());
    }

    /// @notice Allows platform owner to pause the contract in case of emergency.
    function pauseContract() external onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Allows platform owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    // Fallback function to receive ether
    receive() external payable {}
}
```