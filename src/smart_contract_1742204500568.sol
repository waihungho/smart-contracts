```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform with Advanced Features
 * @author Bard (AI Assistant)
 * @dev This contract implements a decentralized content platform with advanced features
 * including dynamic content NFTs, decentralized governance for content moderation,
 * customizable user roles, reputation system, content revenue sharing, feature proposals,
 * decentralized search, and more.
 *
 * ## Outline and Function Summary:
 *
 * **1. Platform Configuration & Ownership:**
 *    - `constructor(string _platformName)`: Initializes the platform name and sets contract owner.
 *    - `setPlatformName(string _newName)`: Allows the owner to update the platform name.
 *    - `owner()`: Returns the contract owner's address.
 *
 * **2. User Management:**
 *    - `registerUser(string _username, string _profileDescription)`: Registers a new user with a username and profile description.
 *    - `updateUserProfile(string _newDescription)`: Allows a user to update their profile description.
 *    - `getUserProfile(address _userAddress)`: Retrieves a user's profile information.
 *    - `banUser(address _userAddress)`: Allows moderators to ban a user from the platform.
 *    - `unbanUser(address _userAddress)`: Allows moderators to unban a user.
 *    - `isUserBanned(address _userAddress)`: Checks if a user is banned.
 *
 * **3. Content Creation & Management:**
 *    - `createContentNFT(string _contentHash, string _metadataURI)`: Creates a new Dynamic Content NFT.
 *    - `updateContentNFTMetadata(uint256 _nftId, string _newMetadataURI)`: Updates the metadata URI of a Content NFT.
 *    - `setContentNFTPublic(uint256 _nftId)`: Makes a Content NFT publically viewable.
 *    - `setContentNFTProtected(uint256 _nftId)`: Makes a Content NFT protected, requiring permissions.
 *    - `getContentNFTDetails(uint256 _nftId)`: Retrieves details of a Content NFT.
 *    - `likeContentNFT(uint256 _nftId)`: Allows users to like a Content NFT, increasing creator reputation.
 *    - `reportContentNFT(uint256 _nftId, string _reportReason)`: Allows users to report inappropriate Content NFTs.
 *    - `moderateContentNFT(uint256 _nftId, bool _isApproved)`: Allows moderators to approve or reject reported Content NFTs.
 *    - `getContentNFTLikeCount(uint256 _nftId)`: Returns the like count for a Content NFT.
 *    - `getContentNFTReportCount(uint256 _nftId)`: Returns the report count for a Content NFT.
 *
 * **4. Decentralized Governance & Moderation:**
 *    - `nominateModerator(address _moderatorAddress)`: Allows moderators to nominate new moderators.
 *    - `voteOnModeratorNomination(address _moderatorAddress, bool _approve)`: Allows existing moderators to vote on a moderator nomination.
 *    - `removeModerator(address _moderatorAddress)`: Allows the contract owner to remove a moderator.
 *    - `isModerator(address _userAddress)`: Checks if an address is a moderator.
 *
 * **5. Reputation & Rewards:**
 *    - `getUserReputation(address _userAddress)`: Retrieves a user's reputation score.
 *    - `distributeContentRevenue(uint256 _nftId)`: (Placeholder) Functionality for distributing revenue from content (e.g., via external integrations).
 *
 * **6. Feature Proposals & Voting:**
 *    - `submitFeatureProposal(string _proposalTitle, string _proposalDescription)`: Allows users to submit feature proposals for platform improvements.
 *    - `voteOnFeatureProposal(uint256 _proposalId, bool _approve)`: Allows users to vote on feature proposals.
 *    - `getFeatureProposalDetails(uint256 _proposalId)`: Retrieves details of a feature proposal.
 *
 * **7. Decentralized Search (Conceptual - Requires Off-Chain Indexing):**
 *    - `searchContentNFTs(string _searchTerm)`: (Conceptual - Requires Off-Chain Indexing) Functionality for searching Content NFTs based on metadata.
 *
 * **Events:**
 *    - `PlatformNameUpdated(string newName)`: Emitted when the platform name is updated.
 *    - `UserRegistered(address userAddress, string username)`: Emitted when a new user registers.
 *    - `UserProfileUpdated(address userAddress)`: Emitted when a user updates their profile.
 *    - `UserBanned(address userAddress)`: Emitted when a user is banned.
 *    - `UserUnbanned(address userAddress)`: Emitted when a user is unbanned.
 *    - `ContentNFTCreated(uint256 nftId, address creator, string contentHash)`: Emitted when a new Content NFT is created.
 *    - `ContentNFTMetadataUpdated(uint256 nftId, string newMetadataURI)`: Emitted when Content NFT metadata is updated.
 *    - `ContentNFTVisibilityUpdated(uint256 nftId, bool isPublic)`: Emitted when Content NFT visibility changes.
 *    - `ContentNFTLiked(uint256 nftId, address user)`: Emitted when a Content NFT is liked.
 *    - `ContentNFTReported(uint256 nftId, uint256 reportCount)`: Emitted when a Content NFT is reported.
 *    - `ContentNFTModerated(uint256 nftId, bool isApproved)`: Emitted when a Content NFT is moderated.
 *    - `ModeratorNominated(address moderatorAddress, address nominator)`: Emitted when a moderator is nominated.
 *    - `ModeratorVoteCast(address moderatorAddress, bool approve, uint256 voteCount)`: Emitted when a moderator vote is cast.
 *    - `ModeratorAdded(address moderatorAddress)`: Emitted when a new moderator is added.
 *    - `ModeratorRemoved(address moderatorAddress)`: Emitted when a moderator is removed.
 *    - `FeatureProposalSubmitted(uint256 proposalId, address proposer, string title)`: Emitted when a feature proposal is submitted.
 *    - `FeatureProposalVoteCast(uint256 proposalId, address voter, bool approve, uint256 voteCount)`: Emitted when a vote is cast on a feature proposal.
 */
contract DecentralizedContentPlatform {
    string public platformName;
    address public owner;

    // User Management
    struct UserProfile {
        string username;
        string profileDescription;
        uint256 reputation;
        uint256 registrationTimestamp;
        bool isBanned;
    }
    mapping(address => UserProfile) public userProfiles;
    mapping(address => bool) public moderators; // List of moderators
    address[] public moderatorCandidates; // List of nominated moderators awaiting votes
    mapping(address => uint256) public moderatorNominationVotes; // Count votes for each candidate

    // Content NFT Management
    struct ContentNFT {
        address creator;
        string contentHash; // IPFS hash or similar content identifier
        string metadataURI; // URI pointing to NFT metadata (can be dynamic)
        uint256 creationTimestamp;
        bool isPublic;
        uint256 likeCount;
        uint256 reportCount;
        bool isModerated; // Has it been reviewed by moderators?
        bool isApproved;  // Was it approved by moderators?
    }
    mapping(uint256 => ContentNFT) public contentNFTs;
    uint256 public nextNFTId = 1;
    mapping(uint256 => address[]) public nftLikes; // NFT ID to list of addresses that liked it
    mapping(uint256 => mapping(address => string)) public nftReports; // NFT ID to reporter address to report reason

    // Feature Proposals
    struct FeatureProposal {
        address proposer;
        string title;
        string description;
        uint256 creationTimestamp;
        uint256 voteCount;
        bool isApproved; // If proposal reaches consensus, owner can implement
    }
    mapping(uint256 => FeatureProposal) public featureProposals;
    uint256 public nextProposalId = 1;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // Proposal ID to voter address to vote status

    // Events
    event PlatformNameUpdated(string newName);
    event UserRegistered(address userAddress, string username);
    event UserProfileUpdated(address userAddress);
    event UserBanned(address userAddress);
    event UserUnbanned(address userAddress);
    event ContentNFTCreated(uint256 nftId, address creator, string contentHash);
    event ContentNFTMetadataUpdated(uint256 nftId, string newMetadataURI);
    event ContentNFTVisibilityUpdated(uint256 nftId, bool isPublic);
    event ContentNFTLiked(uint256 nftId, address user);
    event ContentNFTReported(uint256 nftId, uint256 reportCount);
    event ContentNFTModerated(uint256 nftId, bool isApproved);
    event ModeratorNominated(address moderatorAddress, address nominator);
    event ModeratorVoteCast(address moderatorAddress, bool approve, uint256 voteCount);
    event ModeratorAdded(address moderatorAddress);
    event ModeratorRemoved(address moderatorAddress);
    event FeatureProposalSubmitted(uint256 proposalId, address proposer, string title);
    event FeatureProposalVoteCast(uint256 proposalId, address voter, bool approve, uint256 voteCount);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(moderators[msg.sender], "Only moderators can call this function.");
        _;
    }

    modifier userExists(address _userAddress) {
        require(bytes(userProfiles[_userAddress].username).length > 0, "User profile does not exist.");
        _;
    }

    modifier nftExists(uint256 _nftId) {
        require(contentNFTs[_nftId].creator != address(0), "Content NFT does not exist.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(featureProposals[_proposalId].proposer != address(0), "Feature Proposal does not exist.");
        _;
    }

    // ------------------------------------------------------------------------
    // 1. Platform Configuration & Ownership
    // ------------------------------------------------------------------------

    constructor(string _platformName) {
        platformName = _platformName;
        owner = msg.sender;
        moderators[owner] = true; // Owner is initially a moderator
        emit PlatformNameUpdated(_platformName);
    }

    function setPlatformName(string _newName) external onlyOwner {
        platformName = _newName;
        emit PlatformNameUpdated(_newName);
    }

    function getOwner() external view returns (address) {
        return owner;
    }


    // ------------------------------------------------------------------------
    // 2. User Management
    // ------------------------------------------------------------------------

    function registerUser(string _username, string _profileDescription) external {
        require(bytes(userProfiles[msg.sender].username).length == 0, "User already registered.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileDescription: _profileDescription,
            reputation: 0,
            registrationTimestamp: block.timestamp,
            isBanned: false
        });
        emit UserRegistered(msg.sender, _username);
    }

    function updateUserProfile(string _newDescription) external userExists(msg.sender) {
        userProfiles[msg.sender].profileDescription = _newDescription;
        emit UserProfileUpdated(msg.sender);
    }

    function getUserProfile(address _userAddress) external view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    function banUser(address _userAddress) external onlyModerator userExists(_userAddress) {
        require(!userProfiles[_userAddress].isBanned, "User is already banned.");
        userProfiles[_userAddress].isBanned = true;
        emit UserBanned(_userAddress);
    }

    function unbanUser(address _userAddress) external onlyModerator userExists(_userAddress) {
        require(userProfiles[_userAddress].isBanned, "User is not banned.");
        userProfiles[_userAddress].isBanned = false;
        emit UserUnbanned(_userAddress);
    }

    function isUserBanned(address _userAddress) external view userExists(_userAddress) returns (bool) {
        return userProfiles[_userAddress].isBanned;
    }


    // ------------------------------------------------------------------------
    // 3. Content Creation & Management
    // ------------------------------------------------------------------------

    function createContentNFT(string _contentHash, string _metadataURI) external userExists(msg.sender) {
        require(bytes(_contentHash).length > 0, "Content hash cannot be empty.");
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");

        contentNFTs[nextNFTId] = ContentNFT({
            creator: msg.sender,
            contentHash: _contentHash,
            metadataURI: _metadataURI,
            creationTimestamp: block.timestamp,
            isPublic: false, // Initially protected by default
            likeCount: 0,
            reportCount: 0,
            isModerated: false, // Initially not moderated
            isApproved: true     // Assume approved initially, moderation can change later
        });
        emit ContentNFTCreated(nextNFTId, msg.sender, _contentHash);
        nextNFTId++;
    }

    function updateContentNFTMetadata(uint256 _nftId, string _newMetadataURI) external nftExists(_nftId) {
        require(msg.sender == contentNFTs[_nftId].creator || moderators[msg.sender], "Only creator or moderator can update metadata.");
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty.");
        contentNFTs[_nftId].metadataURI = _newMetadataURI;
        emit ContentNFTMetadataUpdated(_nftId, _newMetadataURI);
    }

    function setContentNFTPublic(uint256 _nftId) external nftExists(_nftId) {
        require(msg.sender == contentNFTs[_nftId].creator || moderators[msg.sender], "Only creator or moderator can change visibility.");
        contentNFTs[_nftId].isPublic = true;
        emit ContentNFTVisibilityUpdated(_nftId, true);
    }

    function setContentNFTProtected(uint256 _nftId) external nftExists(_nftId) {
        require(msg.sender == contentNFTs[_nftId].creator || moderators[msg.sender], "Only creator or moderator can change visibility.");
        contentNFTs[_nftId].isPublic = false;
        emit ContentNFTVisibilityUpdated(_nftId, false);
    }

    function getContentNFTDetails(uint256 _nftId) external view nftExists(_nftId) returns (ContentNFT memory) {
        return contentNFTs[_nftId];
    }

    function likeContentNFT(uint256 _nftId) external userExists(msg.sender) nftExists(_nftId) {
        require(!isUserBanned(msg.sender), "Banned users cannot like content.");
        bool alreadyLiked = false;
        for (uint256 i = 0; i < nftLikes[_nftId].length; i++) {
            if (nftLikes[_nftId][i] == msg.sender) {
                alreadyLiked = true;
                break;
            }
        }
        require(!alreadyLiked, "User already liked this NFT.");

        nftLikes[_nftId].push(msg.sender);
        contentNFTs[_nftId].likeCount++;
        userProfiles[contentNFTs[_nftId].creator].reputation++; // Increase creator reputation
        emit ContentNFTLiked(_nftId, msg.sender);
    }

    function reportContentNFT(uint256 _nftId, string _reportReason) external userExists(msg.sender) nftExists(_nftId) {
        require(!isUserBanned(msg.sender), "Banned users cannot report content.");
        require(bytes(_reportReason).length > 0 && bytes(_reportReason).length <= 256, "Report reason must be between 1 and 256 characters.");
        require(bytes(nftReports[_nftId][msg.sender]).length == 0, "User already reported this NFT.");

        nftReports[_nftId][msg.sender] = _reportReason;
        contentNFTs[_nftId].reportCount++;
        emit ContentNFTReported(_nftId, contentNFTs[_nftId].reportCount);
    }

    function moderateContentNFT(uint256 _nftId, bool _isApproved) external onlyModerator nftExists(_nftId) {
        require(!contentNFTs[_nftId].isModerated, "Content NFT is already moderated.");
        contentNFTs[_nftId].isModerated = true;
        contentNFTs[_nftId].isApproved = _isApproved;
        emit ContentNFTModerated(_nftId, _isApproved);
    }

    function getContentNFTLikeCount(uint256 _nftId) external view nftExists(_nftId) returns (uint256) {
        return contentNFTs[_nftId].likeCount;
    }

    function getContentNFTReportCount(uint256 _nftId) external view nftExists(_nftId) returns (uint256) {
        return contentNFTs[_nftId].reportCount;
    }


    // ------------------------------------------------------------------------
    // 4. Decentralized Governance & Moderation
    // ------------------------------------------------------------------------

    function nominateModerator(address _moderatorAddress) external onlyModerator {
        require(!moderators[_moderatorAddress], "Address is already a moderator.");
        bool alreadyCandidate = false;
        for (uint256 i = 0; i < moderatorCandidates.length; i++) {
            if (moderatorCandidates[i] == _moderatorAddress) {
                alreadyCandidate = true;
                break;
            }
        }
        require(!alreadyCandidate, "Address is already a moderator candidate.");

        moderatorCandidates.push(_moderatorAddress);
        moderatorNominationVotes[_moderatorAddress] = 0;
        emit ModeratorNominated(_moderatorAddress, msg.sender);
    }

    function voteOnModeratorNomination(address _moderatorAddress, bool _approve) external onlyModerator {
        require(moderatorNominationVotes[_moderatorAddress] != 0 || _moderatorAddress == moderatorCandidates[0], "Address is not a moderator candidate."); // Ensure it's a candidate
        require(!proposalVotes[nextProposalId][msg.sender], "Moderator already voted on this nomination."); // Prevent double voting

        proposalVotes[nextProposalId][msg.sender] = true; // Using proposalVotes mapping for simplicity, consider separate mapping if needed extensively.
        if (_approve) {
            moderatorNominationVotes[_moderatorAddress]++;
        } else {
            moderatorNominationVotes[_moderatorAddress]--;
        }
        uint256 currentVotes = moderatorNominationVotes[_moderatorAddress];
        emit ModeratorVoteCast(_moderatorAddress, _approve, currentVotes);

        // Simple majority for now, can adjust threshold
        if (currentVotes >= (getModeratorCount() / 2) + 1 ) {
            moderators[_moderatorAddress] = true;
            emit ModeratorAdded(_moderatorAddress);
            // Remove from candidates list (inefficient, consider better data structure if frequent nominations)
            for (uint256 i = 0; i < moderatorCandidates.length; i++) {
                if (moderatorCandidates[i] == _moderatorAddress) {
                    delete moderatorCandidates[i];
                    break;
                }
            }
        }
    }

    function removeModerator(address _moderatorAddress) external onlyOwner {
        require(moderators[_moderatorAddress], "Address is not a moderator.");
        require(_moderatorAddress != owner, "Cannot remove contract owner as moderator.");
        delete moderators[_moderatorAddress];
        emit ModeratorRemoved(_moderatorAddress);
    }

    function isModerator(address _userAddress) external view returns (bool) {
        return moderators[_userAddress];
    }

    function getModeratorCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < moderatorCandidates.length; i++) {
            if (moderatorCandidates[i] != address(0)) { // Skip deleted entries
                count++;
            }
        }
        // Count existing moderators (less efficient for large moderator sets)
        uint256 moderatorCount = 0;
        address[] memory allModerators = getAllModerators();
        moderatorCount = allModerators.length;

        return moderatorCount + count; // Candidates + current moderators for total count
    }

    function getAllModerators() public view returns (address[] memory) {
        address[] memory moderatorList = new address[](100); // Assuming max 100 moderators for now, dynamic array needed for scalability
        uint256 moderatorIndex = 0;
        // Iterate through users (inefficient, consider separate moderator list for large scale)
        address currentAddress;
        for (uint i=0; i < 1000; i++) { // Limit loop for gas safety, consider different iteration method for large user base
            currentAddress = address(uint160(uint256(keccak256(abi.encodePacked(i))))); // Generate pseudo-random addresses for iteration (not robust for real-world, just for demonstration)
            if (moderators[currentAddress]) {
                moderatorList[moderatorIndex] = currentAddress;
                moderatorIndex++;
                if (moderatorIndex >= moderatorList.length) { // Resize if needed (basic example, use dynamic array for production)
                    break; // Simple break for example, dynamic resize needed in real app
                }
            }
        }

        address[] memory finalModeratorList = new address[](moderatorIndex);
        for (uint i=0; i<moderatorIndex; i++) {
            finalModeratorList[i] = moderatorList[i];
        }
        return finalModeratorList;
    }


    // ------------------------------------------------------------------------
    // 5. Reputation & Rewards
    // ------------------------------------------------------------------------

    function getUserReputation(address _userAddress) external view userExists(_userAddress) returns (uint256) {
        return userProfiles[_userAddress].reputation;
    }

    function distributeContentRevenue(uint256 _nftId) external nftExists(_nftId) {
        // Placeholder for revenue distribution logic
        // This would typically involve:
        // 1. Receiving revenue (e.g., from a marketplace integration)
        // 2. Calculating creator share
        // 3. Transferring funds to creator's address
        // For simplicity, this function is left as a placeholder.
        revert("Revenue distribution logic not implemented in this example.");
    }


    // ------------------------------------------------------------------------
    // 6. Feature Proposals & Voting
    // ------------------------------------------------------------------------

    function submitFeatureProposal(string _proposalTitle, string _proposalDescription) external userExists(msg.sender) {
        require(bytes(_proposalTitle).length > 0 && bytes(_proposalTitle).length <= 128, "Proposal title must be between 1 and 128 characters.");
        require(bytes(_proposalDescription).length > 0 && bytes(_proposalDescription).length <= 1024, "Proposal description must be between 1 and 1024 characters.");

        featureProposals[nextProposalId] = FeatureProposal({
            proposer: msg.sender,
            title: _proposalTitle,
            description: _proposalDescription,
            creationTimestamp: block.timestamp,
            voteCount: 0,
            isApproved: false // Initially not approved
        });
        emit FeatureProposalSubmitted(nextProposalId, msg.sender, _proposalTitle);
        nextProposalId++;
    }

    function voteOnFeatureProposal(uint256 _proposalId, bool _approve) external userExists(msg.sender) proposalExists(_proposalId) {
        require(!isUserBanned(msg.sender), "Banned users cannot vote.");
        require(!proposalVotes[_proposalId][msg.sender], "User already voted on this proposal.");

        proposalVotes[_proposalId][_userAddress] = true;
        if (_approve) {
            featureProposals[_proposalId].voteCount++;
        } else {
            featureProposals[_proposalId].voteCount--;
        }
        emit FeatureProposalVoteCast(_proposalId, msg.sender, _approve, featureProposals[_proposalId].voteCount);

        // Basic example: if votes reach a threshold, mark as approved.
        if (featureProposals[_proposalId].voteCount >= 10) { // Example threshold, adjust as needed
            featureProposals[_proposalId].isApproved = true;
        }
    }

    function getFeatureProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (FeatureProposal memory) {
        return featureProposals[_proposalId];
    }


    // ------------------------------------------------------------------------
    // 7. Decentralized Search (Conceptual)
    // ------------------------------------------------------------------------

    function searchContentNFTs(string _searchTerm) external view returns (uint256[] memory) {
        // **Important Note:** Decentralized search directly within Solidity is highly inefficient and not scalable for real-world applications.
        // This function is a conceptual placeholder.

        // In a real application, you would typically use an off-chain indexing service (like The Graph, or a dedicated search index)
        // to index the metadata of Content NFTs.
        // Then, this Solidity function (or an off-chain service interacting with the contract) would query that index
        // and return the relevant NFT IDs.

        // This example provides a very basic, inefficient, and limited search for demonstration purposes ONLY.
        // DO NOT USE THIS APPROACH IN PRODUCTION.

        uint256[] memory results = new uint256[](10); // Limited result size for example
        uint256 resultCount = 0;
        for (uint256 i = 1; i < nextNFTId; i++) { // Iterate through all NFTs (very inefficient)
            if (contentNFTs[i].creator != address(0)) { // Check if NFT exists (to avoid errors if IDs are sparse)
                ContentNFT memory nft = contentNFTs[i];
                // Very basic string matching - rudimentary and not suitable for real search
                if (stringContains(nft.metadataURI, _searchTerm) || stringContains(nft.contentHash, _searchTerm)) {
                    results[resultCount] = i;
                    resultCount++;
                    if (resultCount >= results.length) { // Limit results
                        break;
                    }
                }
            }
        }
        // Resize results array to actual result count
        uint256[] memory finalResults = new uint256[](resultCount);
        for (uint256 i = 0; i < resultCount; i++) {
            finalResults[i] = results[i];
        }
        return finalResults;
    }

    // Very basic stringContains function (for demonstration only - not efficient or robust)
    function stringContains(string memory _str, string memory _substring) internal pure returns (bool) {
        if (bytes(_substring).length == 0) {
            return true; // Empty substring is always contained
        }
        for (uint256 i = 0; i <= bytes(_str).length - bytes(_substring).length; i++) {
            bool match = true;
            for (uint256 j = 0; j < bytes(_substring).length; j++) {
                if (bytes(_str)[i + j] != bytes(_substring)[j]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return true;
            }
        }
        return false;
    }
}
```