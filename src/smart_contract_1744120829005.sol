```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content Platform (DDCP)
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform where users can create, curate, and dynamically update content NFTs.
 *
 * **Outline and Function Summary:**
 *
 * **I. Core Functionality - Content NFT Management:**
 *     1. `createContentNFT(string memory _metadataURI, string memory _initialContentHash)`: Allows users to create a new Dynamic Content NFT with initial metadata and content hash.
 *     2. `updateContentHash(uint256 _contentNFTId, string memory _newContentHash)`:  Allows the NFT owner to update the content hash associated with their NFT.
 *     3. `getContentHash(uint256 _contentNFTId) view returns (string memory)`: Retrieves the current content hash for a given Content NFT.
 *     4. `getContentMetadataURI(uint256 _contentNFTId) view returns (string memory)`: Retrieves the metadata URI for a given Content NFT.
 *     5. `transferContentNFT(uint256 _contentNFTId, address _to)`: Transfers ownership of a Content NFT to a new address.
 *     6. `burnContentNFT(uint256 _contentNFTId)`: Allows the NFT owner to permanently destroy their Content NFT.
 *     7. `getContentNFTOwner(uint256 _contentNFTId) view returns (address)`: Retrieves the owner of a specific Content NFT.
 *     8. `getTotalContentNFTs() view returns (uint256)`: Returns the total number of Content NFTs created.
 *
 * **II. Advanced Features - Content Curation and Reputation:**
 *     9. `upvoteContent(uint256 _contentNFTId)`: Allows users to upvote a Content NFT, increasing its reputation score.
 *     10. `downvoteContent(uint256 _contentNFTId)`: Allows users to downvote a Content NFT, decreasing its reputation score.
 *     11. `getContentReputation(uint256 _contentNFTId) view returns (int256)`: Retrieves the current reputation score of a Content NFT.
 *     12. `setReputationThreshold(int256 _threshold)`: Allows the contract owner to set a reputation threshold for content visibility or features (e.g., featured content).
 *     13. `getReputationThreshold() view returns (int256)`: Retrieves the current reputation threshold.
 *
 * **III. Creative and Trendy Features - Dynamic Content Modules and Reactions:**
 *     14. `addContentModule(uint256 _contentNFTId, string memory _moduleIdentifier, string memory _moduleData)`: Allows the NFT owner to add dynamic content modules to their NFT (e.g., interactive elements, embedded widgets).
 *     15. `updateContentModuleData(uint256 _contentNFTId, string memory _moduleIdentifier, string memory _newModuleData)`: Allows updating the data for a specific content module.
 *     16. `getContentModuleData(uint256 _contentNFTId, string memory _moduleIdentifier) view returns (string memory)`: Retrieves the data for a specific content module.
 *     17. `removeContentModule(uint256 _contentNFTId, string memory _moduleIdentifier)`: Allows removing a content module from an NFT.
 *     18. `recordReaction(uint256 _contentNFTId, string memory _reactionType, string memory _reactionData)`: Allows users to record reactions to Content NFTs (e.g., "like", "comment", custom reactions).
 *     19. `getReactionsCount(uint256 _contentNFTId, string memory _reactionType) view returns (uint256)`: Retrieves the count of a specific reaction type for a Content NFT.
 *     20. `getContentNFTDetails(uint256 _contentNFTId) view returns (string memory metadataURI, string memory contentHash, int256 reputation, address owner)`: A function to retrieve comprehensive details about a Content NFT in one call.
 *
 * **IV. Ownership and Management:**
 *     21. `setContractOwner(address _newOwner)`: Allows the current contract owner to change the contract owner.
 *     22. `getContractOwner() view returns (address)`: Retrieves the address of the contract owner.
 */
contract DynamicContentPlatform {

    // **I. Core Functionality - Content NFT Management **

    struct ContentNFT {
        string metadataURI;       // URI pointing to NFT metadata (e.g., IPFS link)
        string contentHash;       // Hash of the current content (e.g., IPFS CID, URL, etc.)
        int256 reputationScore;   // Reputation score of the content
        address owner;            // Owner of the Content NFT
        uint256 creationTimestamp; // Timestamp when the NFT was created
    }

    mapping(uint256 => ContentNFT) public contentNFTs; // Mapping from NFT ID to ContentNFT struct
    uint256 public nextContentNFTId;                // Counter for generating unique NFT IDs

    event ContentNFTCreated(uint256 contentNFTId, address creator, string metadataURI, string initialContentHash);
    event ContentHashUpdated(uint256 contentNFTId, string newContentHash, address updater);
    event ContentNFTTransferred(uint256 contentNFTId, address from, address to);
    event ContentNFTBurned(uint256 contentNFTId, address burner);

    /**
     * @dev Creates a new Dynamic Content NFT.
     * @param _metadataURI URI pointing to the metadata of the NFT.
     * @param _initialContentHash Hash of the initial content associated with the NFT.
     */
    function createContentNFT(string memory _metadataURI, string memory _initialContentHash) public {
        uint256 nftId = nextContentNFTId++;
        contentNFTs[nftId] = ContentNFT({
            metadataURI: _metadataURI,
            contentHash: _initialContentHash,
            reputationScore: 0, // Initial reputation is 0
            owner: msg.sender,
            creationTimestamp: block.timestamp
        });
        emit ContentNFTCreated(nftId, msg.sender, _metadataURI, _initialContentHash);
    }

    /**
     * @dev Updates the content hash associated with a Content NFT. Only the owner can call this.
     * @param _contentNFTId ID of the Content NFT to update.
     * @param _newContentHash New hash of the content.
     */
    function updateContentHash(uint256 _contentNFTId, string memory _newContentHash) public {
        require(contentNFTs[_contentNFTId].owner == msg.sender, "Only NFT owner can update content hash.");
        contentNFTs[_contentNFTId].contentHash = _newContentHash;
        emit ContentHashUpdated(_contentNFTId, _newContentHash, msg.sender);
    }

    /**
     * @dev Retrieves the current content hash for a given Content NFT.
     * @param _contentNFTId ID of the Content NFT.
     * @return string The content hash.
     */
    function getContentHash(uint256 _contentNFTId) public view returns (string memory) {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        return contentNFTs[_contentNFTId].contentHash;
    }

    /**
     * @dev Retrieves the metadata URI for a given Content NFT.
     * @param _contentNFTId ID of the Content NFT.
     * @return string The metadata URI.
     */
    function getContentMetadataURI(uint256 _contentNFTId) public view returns (string memory) {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        return contentNFTs[_contentNFTId].metadataURI;
    }

    /**
     * @dev Transfers ownership of a Content NFT to a new address.
     * @param _contentNFTId ID of the Content NFT to transfer.
     * @param _to Address to transfer the NFT to.
     */
    function transferContentNFT(uint256 _contentNFTId, address _to) public {
        require(contentNFTs[_contentNFTId].owner == msg.sender, "Only NFT owner can transfer.");
        require(_to != address(0), "Invalid recipient address.");
        contentNFTs[_contentNFTId].owner = _to;
        emit ContentNFTTransferred(_contentNFTId, msg.sender, _to);
    }

    /**
     * @dev Allows the NFT owner to burn (permanently destroy) their Content NFT.
     * @param _contentNFTId ID of the Content NFT to burn.
     */
    function burnContentNFT(uint256 _contentNFTId) public {
        require(contentNFTs[_contentNFTId].owner == msg.sender, "Only NFT owner can burn.");
        delete contentNFTs[_contentNFTId]; // Remove the NFT from storage
        emit ContentNFTBurned(_contentNFTId, msg.sender);
    }

    /**
     * @dev Retrieves the owner of a specific Content NFT.
     * @param _contentNFTId ID of the Content NFT.
     * @return address The owner address.
     */
    function getContentNFTOwner(uint256 _contentNFTId) public view returns (address) {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        return contentNFTs[_contentNFTId].owner;
    }

    /**
     * @dev Returns the total number of Content NFTs created so far.
     * @return uint256 Total count of Content NFTs.
     */
    function getTotalContentNFTs() public view returns (uint256) {
        return nextContentNFTId;
    }


    // ** II. Advanced Features - Content Curation and Reputation **

    mapping(uint256 => mapping(address => int8)) public userVotes; // Track user votes to prevent double voting
    int256 public reputationThreshold = 10; // Default reputation threshold

    event ContentUpvoted(uint256 contentNFTId, address voter, int256 newReputation);
    event ContentDownvoted(uint256 contentNFTId, address voter, int256 newReputation);
    event ReputationThresholdUpdated(int256 newThreshold, address updater);


    /**
     * @dev Allows users to upvote a Content NFT, increasing its reputation score.
     * @param _contentNFTId ID of the Content NFT to upvote.
     */
    function upvoteContent(uint256 _contentNFTId) public {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        require(userVotes[_contentNFTId][msg.sender] == 0, "User has already voted on this content.");

        contentNFTs[_contentNFTId].reputationScore++;
        userVotes[_contentNFTId][msg.sender] = 1; // 1 for upvote
        emit ContentUpvoted(_contentNFTId, msg.sender, contentNFTs[_contentNFTId].reputationScore);
    }

    /**
     * @dev Allows users to downvote a Content NFT, decreasing its reputation score.
     * @param _contentNFTId ID of the Content NFT to downvote.
     */
    function downvoteContent(uint256 _contentNFTId) public {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        require(userVotes[_contentNFTId][msg.sender] == 0, "User has already voted on this content.");

        contentNFTs[_contentNFTId].reputationScore--;
        userVotes[_contentNFTId][msg.sender] = -1; // -1 for downvote
        emit ContentDownvoted(_contentNFTId, msg.sender, contentNFTs[_contentNFTId].reputationScore);
    }

    /**
     * @dev Retrieves the current reputation score of a Content NFT.
     * @param _contentNFTId ID of the Content NFT.
     * @return int256 The reputation score.
     */
    function getContentReputation(uint256 _contentNFTId) public view returns (int256) {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        return contentNFTs[_contentNFTId].reputationScore;
    }

    /**
     * @dev Sets the reputation threshold for content visibility or features. Only contract owner can set this.
     * @param _threshold The new reputation threshold value.
     */
    function setReputationThreshold(int256 _threshold) public onlyOwner {
        reputationThreshold = _threshold;
        emit ReputationThresholdUpdated(_threshold, msg.sender);
    }

    /**
     * @dev Retrieves the current reputation threshold.
     * @return int256 The current reputation threshold.
     */
    function getReputationThreshold() public view returns (int256) {
        return reputationThreshold;
    }


    // ** III. Creative and Trendy Features - Dynamic Content Modules and Reactions **

    mapping(uint256 => mapping(string => string)) public contentModules; // NFT ID -> Module Identifier -> Module Data
    mapping(uint256 => mapping(string => uint256)) public contentReactions; // NFT ID -> Reaction Type -> Count

    event ContentModuleAdded(uint256 contentNFTId, string moduleIdentifier, string moduleData, address adder);
    event ContentModuleUpdated(uint256 contentNFTId, string moduleIdentifier, string newModuleData, address updater);
    event ContentModuleRemoved(uint256 contentNFTId, string moduleIdentifier, address remover);
    event ReactionRecorded(uint256 contentNFTId, string reactionType, string reactionData, address reactor);


    /**
     * @dev Allows the NFT owner to add a dynamic content module to their NFT.
     * @param _contentNFTId ID of the Content NFT.
     * @param _moduleIdentifier Unique identifier for the module (e.g., "chat-widget", "interactive-poll").
     * @param _moduleData Initial data for the module (JSON string, URL, etc.).
     */
    function addContentModule(uint256 _contentNFTId, string memory _moduleIdentifier, string memory _moduleData) public {
        require(contentNFTs[_contentNFTId].owner == msg.sender, "Only NFT owner can add modules.");
        contentModules[_contentNFTId][_moduleIdentifier] = _moduleData;
        emit ContentModuleAdded(_contentNFTId, _moduleIdentifier, _moduleData, msg.sender);
    }

    /**
     * @dev Allows updating the data for a specific content module of an NFT. Only the owner can call this.
     * @param _contentNFTId ID of the Content NFT.
     * @param _moduleIdentifier Identifier of the module to update.
     * @param _newModuleData New data for the module.
     */
    function updateContentModuleData(uint256 _contentNFTId, string memory _moduleIdentifier, string memory _newModuleData) public {
        require(contentNFTs[_contentNFTId].owner == msg.sender, "Only NFT owner can update modules.");
        require(bytes(contentModules[_contentNFTId][_moduleIdentifier]).length > 0, "Module identifier does not exist.");
        contentModules[_contentNFTId][_moduleIdentifier] = _newModuleData;
        emit ContentModuleUpdated(_contentNFTId, _moduleIdentifier, _newModuleData, msg.sender);
    }

    /**
     * @dev Retrieves the data for a specific content module of an NFT.
     * @param _contentNFTId ID of the Content NFT.
     * @param _moduleIdentifier Identifier of the module.
     * @return string Module data.
     */
    function getContentModuleData(uint256 _contentNFTId, string memory _moduleIdentifier) public view returns (string memory) {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        return contentModules[_contentNFTId][_moduleIdentifier];
    }

    /**
     * @dev Allows removing a content module from an NFT. Only the owner can call this.
     * @param _contentNFTId ID of the Content NFT.
     * @param _moduleIdentifier Identifier of the module to remove.
     */
    function removeContentModule(uint256 _contentNFTId, string memory _moduleIdentifier) public {
        require(contentNFTs[_contentNFTId].owner == msg.sender, "Only NFT owner can remove modules.");
        delete contentModules[_contentNFTId][_moduleIdentifier];
        emit ContentModuleRemoved(_contentNFTId, _moduleIdentifier, msg.sender);
    }

    /**
     * @dev Allows users to record reactions to Content NFTs.
     * @param _contentNFTId ID of the Content NFT.
     * @param _reactionType Type of reaction (e.g., "like", "love", "comment").
     * @param _reactionData Optional data associated with the reaction (e.g., comment text).
     */
    function recordReaction(uint256 _contentNFTId, string memory _reactionType, string memory _reactionData) public {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        contentReactions[_contentNFTId][_reactionType]++;
        emit ReactionRecorded(_contentNFTId, _reactionType, _reactionData, msg.sender);
    }

    /**
     * @dev Retrieves the count of a specific reaction type for a Content NFT.
     * @param _contentNFTId ID of the Content NFT.
     * @param _reactionType Type of reaction to count.
     * @return uint256 Count of reactions of the given type.
     */
    function getReactionsCount(uint256 _contentNFTId, string memory _reactionType) public view returns (uint256) {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        return contentReactions[_contentNFTId][_reactionType];
    }

    /**
     * @dev Retrieves comprehensive details about a Content NFT in one call.
     * @param _contentNFTId ID of the Content NFT.
     * @return metadataURI, contentHash, reputation, owner.
     */
    function getContentNFTDetails(uint256 _contentNFTId) public view returns (string memory metadataURI, string memory contentHash, int256 reputation, address owner) {
        require(contentNFTs[_contentNFTId].owner != address(0), "Content NFT does not exist.");
        ContentNFT storage nft = contentNFTs[_contentNFTId];
        return (nft.metadataURI, nft.contentHash, nft.reputationScore, nft.owner);
    }


    // ** IV. Ownership and Management **

    address public contractOwner;

    event ContractOwnerChanged(address indexed previousOwner, address indexed newOwner);

    constructor() {
        contractOwner = msg.sender; // Set deployer as initial contract owner
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can perform this action.");
        _;
    }

    /**
     * @dev Allows the current contract owner to change the contract owner.
     * @param _newOwner Address of the new contract owner.
     */
    function setContractOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address.");
        emit ContractOwnerChanged(contractOwner, _newOwner);
        contractOwner = _newOwner;
    }

    /**
     * @dev Retrieves the address of the contract owner.
     * @return address The contract owner address.
     */
    function getContractOwner() public view returns (address) {
        return contractOwner;
    }
}
```