```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Content NFT Platform with On-Chain Governance and Personalized Experiences
 * @author Gemini AI (Example - Do not use in production without thorough audit)
 * @dev This contract implements a dynamic content NFT platform where NFTs represent access keys to personalized and evolving content.
 * It incorporates on-chain governance for platform features and allows for unique user experiences based on NFT ownership.
 *
 * Function Summary:
 * 1. initializePlatform(string _platformName, string _platformDescription, address _governanceTokenAddress): Initializes the platform with basic details and governance token.
 * 2. setPlatformOwner(address _newOwner): Allows the platform owner to be changed.
 * 3. createContentModule(string _moduleName, string _moduleDescription, uint256 _baseAccessPrice): Creates a new content module with a name, description, and base access price.
 * 4. updateContentModuleDetails(uint256 _moduleId, string _moduleName, string _moduleDescription, uint256 _baseAccessPrice): Updates the details of an existing content module.
 * 5. addContentToModule(uint256 _moduleId, string _contentURI, string _contentMetadata): Adds new content to a specific content module.
 * 6. updateContentInModule(uint256 _moduleId, uint256 _contentId, string _contentURI, string _contentMetadata): Updates existing content within a module.
 * 7. mintNFT(address _recipient, uint256 _moduleId, bytes32 _personalizedDataHash): Mints an NFT granting access to a specific content module with personalized data.
 * 8. transferNFT(address _from, address _to, uint256 _tokenId): Transfers ownership of an NFT.
 * 9. burnNFT(uint256 _tokenId): Burns (destroys) an NFT.
 * 10. getContentModuleDetails(uint256 _moduleId): Retrieves details of a specific content module.
 * 11. getContentDetails(uint256 _moduleId, uint256 _contentId): Retrieves details of specific content within a module.
 * 12. getNftModuleId(uint256 _tokenId): Retrieves the content module ID associated with an NFT.
 * 13. getNftPersonalizedDataHash(uint256 _tokenId): Retrieves the personalized data hash associated with an NFT.
 * 14. checkContentAccess(uint256 _tokenId, uint256 _moduleId, uint256 _contentId, bytes32 _providedDataHash): Checks if an NFT holder has access to specific content within a module, verifying personalized data.
 * 15. submitGovernanceProposal(string _proposalTitle, string _proposalDescription, bytes _proposalData): Allows governance token holders to submit proposals.
 * 16. voteOnProposal(uint256 _proposalId, bool _support): Allows governance token holders to vote on proposals.
 * 17. executeProposal(uint256 _proposalId): Executes a successful governance proposal (owner-controlled for simplicity in this example, could be timelock/DAO based).
 * 18. setPlatformFee(uint256 _newFeePercentage): Sets the platform fee percentage for NFT minting.
 * 19. withdrawPlatformFees(): Allows the platform owner to withdraw accumulated platform fees.
 * 20. getPlatformDetails(): Retrieves basic platform information.
 * 21. getContentCountInModule(uint256 _moduleId): Returns the number of content items in a specific module.
 * 22. getTokenContentModuleId(uint256 _tokenId):  An alias function for getNftModuleId for clarity.
 */
contract DynamicContentNFTPlatform {

    // State Variables

    string public platformName;
    string public platformDescription;
    address public platformOwner;
    address public governanceTokenAddress;
    uint256 public platformFeePercentage; // Percentage fee on NFT minting

    uint256 public nextContentModuleId;
    mapping(uint256 => ContentModule) public contentModules;

    uint256 public nextNFTTokenId;
    mapping(uint256 => NFTData) public nftData;
    mapping(uint256 => address) public nftOwner;
    mapping(address => uint256) public ownerNFTCount;

    uint256 public nextGovernanceProposalId;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => support

    uint256 public accumulatedPlatformFees;

    // Structs

    struct ContentModule {
        string moduleName;
        string moduleDescription;
        uint256 baseAccessPrice; // Price in platform's native token (e.g., ETH)
        uint256 nextContentId;
        mapping(uint256 => Content) contentItems;
        uint256 contentCount;
    }

    struct Content {
        string contentURI; // URI pointing to the actual content (IPFS, Arweave, etc.)
        string contentMetadata; // Metadata about the content (JSON, etc.)
        uint256 creationTimestamp;
    }

    struct NFTData {
        uint256 moduleId;
        bytes32 personalizedDataHash; // Hash of personalized data, can be used for content customization
    }

    struct GovernanceProposal {
        string title;
        string description;
        bytes proposalData; // Encoded data for proposal execution
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        address proposer;
    }

    // Events

    event PlatformInitialized(string platformName, address owner);
    event PlatformOwnerChanged(address newOwner, address previousOwner);
    event ContentModuleCreated(uint256 moduleId, string moduleName);
    event ContentModuleUpdated(uint256 moduleId, string moduleName);
    event ContentAddedToModule(uint256 moduleId, uint256 contentId, string contentURI);
    event ContentUpdatedInModule(uint256 moduleId, uint256 contentId, string contentURI);
    event NFTMinted(uint256 tokenId, address recipient, uint256 moduleId);
    event NFTTransferred(uint256 tokenId, address from, address to);
    event NFTBurned(uint256 tokenId);
    event GovernanceProposalSubmitted(uint256 proposalId, string title, address proposer);
    event GovernanceVoteCast(uint256 proposalId, address voter, bool support);
    event GovernanceProposalExecuted(uint256 proposalId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);

    // Modifiers

    modifier onlyOwner() {
        require(msg.sender == platformOwner, "Only platform owner can call this function.");
        _;
    }

    modifier validModuleId(uint256 _moduleId) {
        require(contentModules[_moduleId].moduleName.length > 0, "Invalid module ID.");
        _;
    }

    modifier validContentId(uint256 _moduleId, uint256 _contentId) {
        require(contentModules[_moduleId].contentItems[_contentId].contentURI.length > 0, "Invalid content ID.");
        _;
    }

    modifier validNFTTokenId(uint256 _tokenId) {
        require(nftOwner[_tokenId] != address(0), "Invalid NFT token ID.");
        _;
    }

    modifier onlyGovernanceTokenHolders() {
        // In a real scenario, you'd interact with the governance token contract to check balances.
        // For simplicity, we assume all addresses can participate in governance in this example.
        //  (e.g., require(GovernanceToken(governanceTokenAddress).balanceOf(msg.sender) > 0, "Not a governance token holder.");)
        _;
    }

    modifier validProposalId(uint256 _proposalId) {
        require(governanceProposals[_proposalId].proposer != address(0), "Invalid proposal ID.");
        _;
    }

    modifier proposalVotingActive(uint256 _proposalId) {
        require(block.timestamp >= governanceProposals[_proposalId].votingStartTime && block.timestamp <= governanceProposals[_proposalId].votingEndTime, "Voting is not active for this proposal.");
        _;
    }

    modifier proposalExecutable(uint256 _proposalId) {
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp > governanceProposals[_proposalId].votingEndTime, "Voting not yet ended.");
        require(governanceProposals[_proposalId].yesVotes > governanceProposals[_proposalId].noVotes, "Proposal failed to pass.");
        _;
    }


    // Functions

    /// @dev Initializes the platform. Can only be called once.
    /// @param _platformName Name of the platform.
    /// @param _platformDescription Description of the platform.
    /// @param _governanceTokenAddress Address of the governance token contract.
    constructor(string memory _platformName, string memory _platformDescription, address _governanceTokenAddress) payable {
        platformName = _platformName;
        platformDescription = _platformDescription;
        platformOwner = msg.sender;
        governanceTokenAddress = _governanceTokenAddress;
        platformFeePercentage = 5; // Default platform fee is 5%
        emit PlatformInitialized(_platformName, platformOwner);
    }

    /// @dev Allows the platform owner to change the owner address.
    /// @param _newOwner Address of the new platform owner.
    function setPlatformOwner(address _newOwner) external onlyOwner {
        address previousOwner = platformOwner;
        platformOwner = _newOwner;
        emit PlatformOwnerChanged(_newOwner, previousOwner);
    }

    /// @dev Creates a new content module.
    /// @param _moduleName Name of the content module.
    /// @param _moduleDescription Description of the content module.
    /// @param _baseAccessPrice Base price to access content in this module.
    function createContentModule(string memory _moduleName, string memory _moduleDescription, uint256 _baseAccessPrice) external onlyOwner {
        uint256 moduleId = nextContentModuleId++;
        contentModules[moduleId] = ContentModule({
            moduleName: _moduleName,
            moduleDescription: _moduleDescription,
            baseAccessPrice: _baseAccessPrice,
            nextContentId: 0,
            contentCount: 0
        });
        emit ContentModuleCreated(moduleId, _moduleName);
    }

    /// @dev Updates details of an existing content module.
    /// @param _moduleId ID of the content module to update.
    /// @param _moduleName New name for the content module.
    /// @param _moduleDescription New description for the content module.
    /// @param _baseAccessPrice New base access price for the content module.
    function updateContentModuleDetails(uint256 _moduleId, string memory _moduleName, string memory _moduleDescription, uint256 _baseAccessPrice) external onlyOwner validModuleId(_moduleId) {
        contentModules[_moduleId].moduleName = _moduleName;
        contentModules[_moduleId].moduleDescription = _moduleDescription;
        contentModules[_moduleId].baseAccessPrice = _baseAccessPrice;
        emit ContentModuleUpdated(_moduleId, _moduleName);
    }

    /// @dev Adds new content to a specific content module.
    /// @param _moduleId ID of the content module to add content to.
    /// @param _contentURI URI of the content (e.g., IPFS hash).
    /// @param _contentMetadata Metadata about the content.
    function addContentToModule(uint256 _moduleId, string memory _contentURI, string memory _contentMetadata) external onlyOwner validModuleId(_moduleId) {
        uint256 contentId = contentModules[_moduleId].nextContentId++;
        contentModules[_moduleId].contentItems[contentId] = Content({
            contentURI: _contentURI,
            contentMetadata: _contentMetadata,
            creationTimestamp: block.timestamp
        });
        contentModules[_moduleId].contentCount++;
        emit ContentAddedToModule(_moduleId, contentId, _contentURI);
    }

    /// @dev Updates existing content within a module.
    /// @param _moduleId ID of the content module.
    /// @param _contentId ID of the content to update.
    /// @param _contentURI New URI for the content.
    /// @param _contentMetadata New metadata for the content.
    function updateContentInModule(uint256 _moduleId, uint256 _contentId, string memory _contentURI, string memory _contentMetadata) external onlyOwner validModuleId(_moduleId) validContentId(_moduleId, _contentId) {
        contentModules[_moduleId].contentItems[_contentId].contentURI = _contentURI;
        contentModules[_moduleId].contentItems[_contentId].contentMetadata = _contentMetadata;
        emit ContentUpdatedInModule(_moduleId, _contentId, _contentURI);
    }

    /// @dev Mints an NFT granting access to a content module with personalized data.
    /// @param _recipient Address to receive the NFT.
    /// @param _moduleId ID of the content module to grant access to.
    /// @param _personalizedDataHash Hash of personalized data related to the NFT (e.g., user preferences, unique identifier).
    function mintNFT(address _recipient, uint256 _moduleId, bytes32 _personalizedDataHash) external payable validModuleId(_moduleId) {
        uint256 tokenId = nextNFTTokenId++;
        nftData[tokenId] = NFTData({
            moduleId: _moduleId,
            personalizedDataHash: _personalizedDataHash
        });
        nftOwner[tokenId] = _recipient;
        ownerNFTCount[_recipient]++;

        // Apply platform fee
        uint256 mintingFee = (contentModules[_moduleId].baseAccessPrice * platformFeePercentage) / 100;
        require(msg.value >= mintingFee, "Insufficient minting fee.");
        accumulatedPlatformFees += mintingFee;

        emit NFTMinted(tokenId, _recipient, _moduleId);
    }

    /// @dev Transfers NFT ownership.
    /// @param _from Current owner of the NFT.
    /// @param _to New owner of the NFT.
    /// @param _tokenId ID of the NFT to transfer.
    function transferNFT(address _from, address _to, uint256 _tokenId) external validNFTTokenId(_tokenId) {
        require(msg.sender == nftOwner[_tokenId] || msg.sender == platformOwner, "Not authorized to transfer this NFT."); // Only owner or platform owner can transfer

        require(nftOwner[_tokenId] == _from, "Incorrect sender.");
        nftOwner[_tokenId] = _to;
        ownerNFTCount[_from]--;
        ownerNFTCount[_to]++;
        emit NFTTransferred(_tokenId, _from, _to);
    }

    /// @dev Burns (destroys) an NFT.
    /// @param _tokenId ID of the NFT to burn.
    function burnNFT(uint256 _tokenId) external validNFTTokenId(_tokenId) {
        require(msg.sender == nftOwner[_tokenId] || msg.sender == platformOwner, "Not authorized to burn this NFT."); // Only owner or platform owner can burn

        address owner = nftOwner[_tokenId];
        delete nftData[_tokenId];
        delete nftOwner[_tokenId];
        ownerNFTCount[owner]--;
        emit NFTBurned(_tokenId);
    }

    /// @dev Retrieves details of a content module.
    /// @param _moduleId ID of the content module.
    /// @return moduleName, moduleDescription, baseAccessPrice.
    function getContentModuleDetails(uint256 _moduleId) external view validModuleId(_moduleId) returns (string memory moduleName, string memory moduleDescription, uint256 baseAccessPrice) {
        ContentModule storage module = contentModules[_moduleId];
        return (module.moduleName, module.moduleDescription, module.baseAccessPrice);
    }

    /// @dev Retrieves details of specific content within a module.
    /// @param _moduleId ID of the content module.
    /// @param _contentId ID of the content.
    /// @return contentURI, contentMetadata, creationTimestamp.
    function getContentDetails(uint256 _moduleId, uint256 _contentId) external view validModuleId(_moduleId) validContentId(_moduleId, _contentId) returns (string memory contentURI, string memory contentMetadata, uint256 creationTimestamp) {
        Content storage content = contentModules[_moduleId].contentItems[_contentId];
        return (content.contentURI, content.contentMetadata, content.creationTimestamp);
    }

    /// @dev Retrieves the content module ID associated with an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return moduleId.
    function getNftModuleId(uint256 _tokenId) external view validNFTTokenId(_tokenId) returns (uint256 moduleId) {
        return nftData[_tokenId].moduleId;
    }

    /// @dev Alias for getNftModuleId for better readability in some contexts.
    function getTokenContentModuleId(uint256 _tokenId) external view validNFTTokenId(_tokenId) returns (uint256 moduleId) {
        return getNftModuleId(_tokenId);
    }


    /// @dev Retrieves the personalized data hash associated with an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return personalizedDataHash.
    function getNftPersonalizedDataHash(uint256 _tokenId) external view validNFTTokenId(_tokenId) returns (bytes32 personalizedDataHash) {
        return nftData[_tokenId].personalizedDataHash;
    }

    /// @dev Checks if an NFT holder has access to specific content, verifying personalized data if needed.
    /// @param _tokenId ID of the NFT.
    /// @param _moduleId ID of the content module.
    /// @param _contentId ID of the content to access.
    /// @param _providedDataHash Hash of personalized data provided by the user for verification.
    /// @return bool True if access is granted, false otherwise.
    function checkContentAccess(uint256 _tokenId, uint256 _moduleId, uint256 _contentId, bytes32 _providedDataHash) external view validNFTTokenId(_tokenId) validModuleId(_moduleId) validContentId(_moduleId, _contentId) returns (bool) {
        require(nftData[_tokenId].moduleId == _moduleId, "NFT is not for the specified module.");
        // In a more advanced version, you could implement logic to compare _providedDataHash with nftData[_tokenId].personalizedDataHash
        // to enforce personalized access rules. For simplicity, in this example, NFT ownership grants access to any content in the module.
        return nftOwner[_tokenId] != address(0); // Basic access check: NFT ownership grants access.
    }

    /// @dev Submits a governance proposal.
    /// @param _proposalTitle Title of the proposal.
    /// @param _proposalDescription Description of the proposal.
    /// @param _proposalData Encoded data for the proposal to execute if successful.
    function submitGovernanceProposal(string memory _proposalTitle, string memory _proposalDescription, bytes memory _proposalData) external onlyGovernanceTokenHolders {
        uint256 proposalId = nextGovernanceProposalId++;
        governanceProposals[proposalId] = GovernanceProposal({
            title: _proposalTitle,
            description: _proposalDescription,
            proposalData: _proposalData,
            votingStartTime: block.timestamp + 1 days, // Voting starts in 1 day
            votingEndTime: block.timestamp + 7 days,  // Voting ends in 7 days
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            proposer: msg.sender
        });
        emit GovernanceProposalSubmitted(proposalId, _proposalTitle, msg.sender);
    }

    /// @dev Allows governance token holders to vote on a proposal.
    /// @param _proposalId ID of the proposal to vote on.
    /// @param _support True to vote in favor, false to vote against.
    function voteOnProposal(uint256 _proposalId, bool _support) external onlyGovernanceTokenHolders validProposalId(_proposalId) proposalVotingActive(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true;
        if (_support) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceVoteCast(_proposalId, msg.sender, _support);
    }

    /// @dev Executes a successful governance proposal. Only platform owner can execute in this simplified example.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyOwner validProposalId(_proposalId) proposalExecutable(_proposalId) {
        governanceProposals[_proposalId].executed = true;
        // In a real-world scenario, you would decode and execute the proposalData.
        // For this example, we'll just emit an event.
        emit GovernanceProposalExecuted(_proposalId);
        // Example of potential execution (requires careful security considerations and encoding/decoding):
        // (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].proposalData);
        // require(success, "Proposal execution failed.");
    }

    /// @dev Sets the platform fee percentage for NFT minting.
    /// @param _newFeePercentage New platform fee percentage.
    function setPlatformFee(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeSet(_newFeePercentage);
    }

    /// @dev Allows the platform owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        payable(platformOwner).transfer(balance);
        emit PlatformFeesWithdrawn(balance, platformOwner);
    }

    /// @dev Retrieves basic platform details.
    /// @return platformName, platformDescription, platformOwner, governanceTokenAddress, platformFeePercentage.
    function getPlatformDetails() external view returns (string memory, string memory, address, address, uint256) {
        return (platformName, platformDescription, platformOwner, governanceTokenAddress, platformFeePercentage);
    }

    /// @dev Returns the number of content items in a specific module.
    /// @param _moduleId ID of the content module.
    /// @return contentCount.
    function getContentCountInModule(uint256 _moduleId) external view validModuleId(_moduleId) returns (uint256 contentCount) {
        return contentModules[_moduleId].contentCount;
    }

    // Fallback function to receive ETH
    receive() external payable {
        accumulatedPlatformFees += msg.value;
    }
}
```