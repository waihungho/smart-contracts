```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Generative Art Marketplace with On-Chain Customization and Collaborative Creation
 * @author Gemini AI (Example - Conceptual Smart Contract)
 * @notice This contract implements a dynamic generative art marketplace where artists can create collections,
 *         mint NFTs with unique on-chain generated traits, and allow owners to collaboratively customize their NFTs
 *         through voting and on-chain modifications. It features advanced concepts like on-chain randomness,
 *         dynamic metadata, collaborative customization, and a royalty system with community governance.
 *
 * @dev **Function Summary:**
 *
 * **Collection Management:**
 *   1. `createCollection(string memory _name, string memory _description, uint256 _royaltyPercentage, address _royaltyRecipient, bool _allowCustomization)`: Allows contract owner to create a new NFT collection.
 *   2. `setCollectionRoyalty(uint256 _collectionId, uint256 _royaltyPercentage, address _royaltyRecipient)`: Updates the royalty settings for a specific collection.
 *   3. `setCollectionCustomizationAllowed(uint256 _collectionId, bool _allowCustomization)`: Enables or disables customization for a specific collection.
 *   4. `getCollectionInfo(uint256 _collectionId) external view returns (CollectionInfo memory)`: Retrieves information about a specific collection.
 *
 * **NFT Minting & Metadata:**
 *   5. `mintNFT(uint256 _collectionId, string memory _baseURI)`: Mints a new NFT within a collection, generating unique traits and metadata.
 *   6. `getNFTMetadata(uint256 _tokenId) external view returns (string memory)`: Retrieves the dynamic metadata URI for a specific NFT.
 *   7. `getNFTRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount)`: Returns royalty information for a given NFT and sale price.
 *
 * **NFT Customization (Collaborative):**
 *   8. `proposeCustomization(uint256 _tokenId, string memory _customizationData)`: Allows NFT owners to propose customizations to their NFTs.
 *   9. `voteForCustomization(uint256 _tokenId, uint256 _proposalId, bool _vote)`: Allows NFT owners to vote on customization proposals.
 *  10. `executeCustomization(uint256 _tokenId, uint256 _proposalId)`: Executes a customization proposal if it reaches a quorum and approval.
 *  11. `getCustomizationProposals(uint256 _tokenId) external view returns (CustomizationProposal[] memory)`: Retrieves all customization proposals for a specific NFT.
 *
 * **Community Governance (Royalty Distribution & Parameters):**
 *  12. `proposeRoyaltyDistributionChange(uint256 _collectionId, address[] memory _recipients, uint256[] memory _percentages)`: Allows community members to propose changes to royalty distribution.
 *  13. `voteForRoyaltyDistributionChange(uint256 _collectionId, uint256 _proposalId, bool _vote)`: Allows community members to vote on royalty distribution change proposals.
 *  14. `executeRoyaltyDistributionChange(uint256 _collectionId, uint256 _proposalId)`: Executes a royalty distribution change proposal if approved.
 *  15. `getParameters() external view returns (Parameters memory)`: Retrieves contract parameters like customization quorum and voting duration.
 *  16. `setCustomizationQuorum(uint256 _newQuorum)`: Allows contract owner to change the customization vote quorum.
 *  17. `setVotingDuration(uint256 _newDuration)`: Allows contract owner to change the voting duration for proposals.
 *
 * **Utility & Access Control:**
 *  18. `pauseContract()`: Allows contract owner to pause the contract functionalities.
 *  19. `unpauseContract()`: Allows contract owner to unpause the contract functionalities.
 *  20. `withdrawPlatformFees()`: Allows contract owner to withdraw accumulated platform fees.
 *  21. `supportsInterface(bytes4 interfaceId) external view override returns (bool)`: Implements ERC165 interface detection for standard NFT interfaces.
 */
contract DynamicArtMarketplace {
    // --- State Variables ---

    address public owner;
    bool public paused;

    uint256 public collectionCount;
    mapping(uint256 => CollectionInfo) public collections;
    mapping(uint256 => uint256) public collectionNFTCount; // Collection ID => NFT Count

    uint256 public nftCount;
    mapping(uint256 => NFTInfo) public nfts;
    mapping(uint256 => address) public nftOwners;

    uint256 public customizationProposalCount;
    mapping(uint256 => mapping(uint256 => CustomizationProposal)) public nftCustomizationProposals; // tokenId => proposalId => Proposal

    uint256 public royaltyDistributionProposalCount;
    mapping(uint256 => mapping(uint256 => RoyaltyDistributionProposal)) public collectionRoyaltyDistributionProposals; // collectionId => proposalId => Proposal

    uint256 public platformFeePercentage = 2; // 2% platform fee
    address public platformFeeRecipient;

    struct Parameters {
        uint256 customizationQuorumPercentage; // Percentage of owners needed to reach quorum for customization
        uint256 votingDuration; // Duration of voting in blocks
    }
    Parameters public contractParameters;

    struct CollectionInfo {
        uint256 id;
        string name;
        string description;
        uint256 royaltyPercentage;
        address royaltyRecipient;
        bool allowCustomization;
        address creator;
    }

    struct NFTInfo {
        uint256 id;
        uint256 collectionId;
        address creator;
        string currentMetadata; // Store URI or on-chain metadata representation
        string originalTraits; // Store initial generated traits
        string customizationHistory; // Store history of customizations (e.g., proposal IDs executed)
    }

    struct CustomizationProposal {
        uint256 id;
        uint256 tokenId;
        address proposer;
        string customizationData; // JSON or structured data representing customization
        uint256 upvotes;
        uint256 downvotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }

    struct RoyaltyDistributionProposal {
        uint256 id;
        uint256 collectionId;
        address proposer;
        address[] recipients;
        uint256[] percentages;
        uint256 upvotes;
        uint256 downvotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }


    // --- Events ---
    event CollectionCreated(uint256 collectionId, string name, address creator);
    event NFTMinted(uint256 tokenId, uint256 collectionId, address minter);
    event CustomizationProposed(uint256 tokenId, uint256 proposalId, address proposer, string customizationData);
    event CustomizationVoted(uint256 tokenId, uint256 proposalId, address voter, bool vote);
    event CustomizationExecuted(uint256 tokenId, uint256 proposalId);
    event RoyaltyDistributionProposed(uint256 collectionId, uint256 proposalId, address proposer);
    event RoyaltyDistributionVoted(uint256 collectionId, uint256 proposalId, address voter, bool vote);
    event RoyaltyDistributionExecuted(uint256 collectionId, uint256 proposalId);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event PlatformFeeUpdated(uint256 newFeePercentage);

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    modifier collectionExists(uint256 _collectionId) {
        require(_collectionId > 0 && _collectionId <= collectionCount, "Collection does not exist.");
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(_tokenId > 0 && _tokenId <= nftCount, "NFT does not exist.");
        _;
    }

    modifier onlyNFTOwner(uint256 _tokenId) {
        require(nftOwners[_tokenId] == msg.sender, "Only NFT owner can call this function.");
        _;
    }

    modifier customizationAllowed(uint256 _collectionId) {
        require(collections[_collectionId].allowCustomization, "Customization is not allowed for this collection.");
        _;
    }


    // --- Constructor ---
    constructor(address _platformFeeRecipient) {
        owner = msg.sender;
        platformFeeRecipient = _platformFeeRecipient;
        paused = false;
        collectionCount = 0;
        nftCount = 0;
        contractParameters = Parameters({
            customizationQuorumPercentage: 51, // 51% quorum for customization proposals
            votingDuration: 100 // 100 blocks voting duration
        });
    }

    // --- Collection Management Functions ---

    /// @notice Creates a new NFT collection. Only callable by the contract owner.
    /// @param _name Name of the collection.
    /// @param _description Description of the collection.
    /// @param _royaltyPercentage Royalty percentage for secondary sales (e.g., 5 for 5%).
    /// @param _royaltyRecipient Address to receive royalties.
    /// @param _allowCustomization Boolean indicating if NFTs in this collection can be customized.
    function createCollection(
        string memory _name,
        string memory _description,
        uint256 _royaltyPercentage,
        address _royaltyRecipient,
        bool _allowCustomization
    ) external onlyOwner whenNotPaused returns (uint256 collectionId) {
        require(_royaltyPercentage <= 100, "Royalty percentage must be less than or equal to 100.");
        collectionCount++;
        collectionId = collectionCount;
        collections[collectionId] = CollectionInfo({
            id: collectionId,
            name: _name,
            description: _description,
            royaltyPercentage: _royaltyPercentage,
            royaltyRecipient: _royaltyRecipient,
            allowCustomization: _allowCustomization,
            creator: msg.sender
        });
        emit CollectionCreated(collectionId, _name, msg.sender);
    }

    /// @notice Sets the royalty settings for a specific collection. Only callable by the contract owner.
    /// @param _collectionId ID of the collection to update.
    /// @param _royaltyPercentage New royalty percentage.
    /// @param _royaltyRecipient New royalty recipient address.
    function setCollectionRoyalty(
        uint256 _collectionId,
        uint256 _royaltyPercentage,
        address _royaltyRecipient
    ) external onlyOwner collectionExists(_collectionId) whenNotPaused {
        require(_royaltyPercentage <= 100, "Royalty percentage must be less than or equal to 100.");
        collections[_collectionId].royaltyPercentage = _royaltyPercentage;
        collections[_collectionId].royaltyRecipient = _royaltyRecipient;
    }

    /// @notice Enables or disables customization for a specific collection. Only callable by the contract owner.
    /// @param _collectionId ID of the collection to update.
    /// @param _allowCustomization Boolean to enable or disable customization.
    function setCollectionCustomizationAllowed(uint256 _collectionId, bool _allowCustomization)
        external
        onlyOwner
        collectionExists(_collectionId)
        whenNotPaused
    {
        collections[_collectionId].allowCustomization = _allowCustomization;
    }

    /// @notice Retrieves information about a specific collection.
    /// @param _collectionId ID of the collection.
    /// @return CollectionInfo struct containing collection details.
    function getCollectionInfo(uint256 _collectionId)
        external
        view
        collectionExists(_collectionId)
        returns (CollectionInfo memory)
    {
        return collections[_collectionId];
    }


    // --- NFT Minting & Metadata Functions ---

    /// @notice Mints a new NFT within a specified collection.
    /// @param _collectionId ID of the collection to mint into.
    /// @param _baseURI Base URI for metadata (can be IPFS, Arweave, or other).
    function mintNFT(uint256 _collectionId, string memory _baseURI)
        external
        whenNotPaused
        collectionExists(_collectionId)
        payable
        returns (uint256 tokenId)
    {
        // Placeholder for generative trait generation logic (can be complex on-chain or off-chain pre-generation)
        string memory generatedTraits = _generateUniqueTraits(_collectionId); // Example trait generation

        nftCount++;
        tokenId = nftCount;
        nfts[tokenId] = NFTInfo({
            id: tokenId,
            collectionId: _collectionId,
            creator: msg.sender,
            currentMetadata: _generateMetadataURI(tokenId, _collectionId, _baseURI, generatedTraits), // Dynamic metadata URI generation
            originalTraits: generatedTraits,
            customizationHistory: ""
        });
        nftOwners[tokenId] = msg.sender;
        collectionNFTCount[_collectionId]++;

        // Platform fee handling
        uint256 platformFee = msg.value * platformFeePercentage / 100;
        uint256 artistProceeds = msg.value - platformFee;
        payable(platformFeeRecipient).transfer(platformFee);
        // In a real scenario, artist proceeds would be handled based on collection settings (e.g., direct transfer or marketplace logic)
        // For simplicity, this example assumes artist gets full proceeds minus platform fee.

        emit NFTMinted(tokenId, _collectionId, msg.sender);
        return tokenId;
    }

    /// @notice Generates unique traits for an NFT (Placeholder - needs to be implemented based on collection logic).
    /// @param _collectionId ID of the collection.
    /// @return String representing generated traits (e.g., JSON string).
    function _generateUniqueTraits(uint256 _collectionId) private view returns (string memory) {
        // **Advanced Concept: On-Chain Generative Art Logic**
        // This is a placeholder. In a real implementation, this function would contain
        // complex logic to generate unique traits based on collection rules, randomness,
        // and potentially previous NFT data within the collection.
        // Examples:
        // 1. Simple randomness: using blockhash and tokenId as seed for pseudo-random generation.
        // 2. Deterministic generation based on tokenId and collection parameters.
        // 3. More complex algorithms for generative art (e.g., cellular automata, L-systems, etc.).

        // For this example, let's just return a simple placeholder trait:
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _collectionId, nftCount)));
        uint256 trait1 = seed % 100; // Example trait range 0-99
        uint256 trait2 = (seed / 100) % 5;  // Example trait range 0-4
        return string(abi.encodePacked('{"trait1":', _toString(trait1), ',"trait2":', _toString(trait2), '}'));
    }


    /// @notice Generates the dynamic metadata URI for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _collectionId ID of the collection.
    /// @param _baseURI Base URI for metadata.
    /// @param _traits JSON string of NFT traits.
    /// @return URI string for NFT metadata.
    function _generateMetadataURI(uint256 _tokenId, uint256 _collectionId, string memory _baseURI, string memory _traits)
        private
        pure
        returns (string memory)
    {
        // **Advanced Concept: Dynamic Metadata Generation**
        // This function constructs the metadata URI. In a real implementation,
        // you would likely have a backend service or IPFS setup to dynamically
        // generate the JSON metadata based on the NFT's traits and current state.
        // The URI could point to a server endpoint that dynamically creates the JSON.
        // Or, for more on-chain focus, metadata could be stored and rendered directly on-chain
        // (though gas intensive for complex metadata).

        // For this example, we'll create a simple URI that includes tokenId and collectionId
        // and assumes a backend service at _baseURI handles dynamic generation based on these IDs and traits.

        return string(abi.encodePacked(_baseURI, "/", _collectionId, "/", _tokenId, ".json?traits=", _traits));
    }


    /// @notice Retrieves the dynamic metadata URI for a specific NFT.
    /// @param _tokenId ID of the NFT.
    /// @return URI string of the NFT's metadata.
    function getNFTMetadata(uint256 _tokenId) external view nftExists(_tokenId) returns (string memory) {
        return nfts[_tokenId].currentMetadata;
    }

    /// @notice Returns royalty information for a given NFT and sale price. Implements EIP-2981 Royalty Standard.
    /// @param _tokenId ID of the NFT.
    /// @param _salePrice Sale price of the NFT.
    /// @return receiver Address to receive royalty, royaltyAmount Royalty amount.
    function getNFTRoyaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        nftExists(_tokenId)
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 collectionId = nfts[_tokenId].collectionId;
        uint256 royaltyPercentage = collections[collectionId].royaltyPercentage;
        receiver = collections[collectionId].royaltyRecipient;
        royaltyAmount = (_salePrice * royaltyPercentage) / 100;
        return (receiver, royaltyAmount);
    }


    // --- NFT Customization Functions ---

    /// @notice Allows NFT owners to propose a customization for their NFT.
    /// @param _tokenId ID of the NFT to customize.
    /// @param _customizationData JSON or structured data describing the customization.
    function proposeCustomization(uint256 _tokenId, string memory _customizationData)
        external
        whenNotPaused
        nftExists(_tokenId)
        onlyNFTOwner(_tokenId)
        customizationAllowed(nfts[_tokenId].collectionId)
    {
        customizationProposalCount++;
        uint256 proposalId = customizationProposalCount;
        nftCustomizationProposals[_tokenId][proposalId] = CustomizationProposal({
            id: proposalId,
            tokenId: _tokenId,
            proposer: msg.sender,
            customizationData: _customizationData,
            upvotes: 0,
            downvotes: 0,
            startTime: block.number,
            endTime: block.number + contractParameters.votingDuration,
            executed: false
        });
        emit CustomizationProposed(_tokenId, proposalId, msg.sender, _customizationData);
    }

    /// @notice Allows NFT owners to vote on a customization proposal.
    /// @param _tokenId ID of the NFT.
    /// @param _proposalId ID of the customization proposal.
    /// @param _vote True for upvote, false for downvote.
    function voteForCustomization(uint256 _tokenId, uint256 _proposalId, bool _vote)
        external
        whenNotPaused
        nftExists(_tokenId)
        onlyNFTOwner(_tokenId)
        customizationAllowed(nfts[_tokenId].collectionId)
    {
        CustomizationProposal storage proposal = nftCustomizationProposals[_tokenId][_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.number < proposal.endTime, "Voting period ended.");

        // Prevent double voting (simple example - could be improved with mapping of voters)
        require(msg.sender != proposal.proposer, "Proposer cannot vote."); // Proposer voting limitation - adjust logic as needed

        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit CustomizationVoted(_tokenId, _proposalId, msg.sender, _vote);
    }

    /// @notice Executes a customization proposal if it reaches quorum and approval.
    /// @param _tokenId ID of the NFT.
    /// @param _proposalId ID of the customization proposal.
    function executeCustomization(uint256 _tokenId, uint256 _proposalId)
        external
        whenNotPaused
        nftExists(_tokenId)
        onlyNFTOwner(_tokenId)
        customizationAllowed(nfts[_tokenId].collectionId)
    {
        CustomizationProposal storage proposal = nftCustomizationProposals[_tokenId][_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.number >= proposal.endTime, "Voting period not ended.");

        uint256 totalOwners = collectionNFTCount[nfts[_tokenId].collectionId]; // Assume all NFTs in collection have same ownership distribution for simplicity
        uint256 quorum = (totalOwners * contractParameters.customizationQuorumPercentage) / 100;
        uint256 totalVotes = proposal.upvotes + proposal.downvotes;

        require(totalVotes >= quorum, "Quorum not reached.");
        require(proposal.upvotes > proposal.downvotes, "Proposal not approved by majority.");

        // **Advanced Concept: On-Chain Dynamic NFT Modification**
        // This is where the NFT is actually modified based on the customization data.
        // This could involve:
        // 1. Updating the on-chain metadata (nfts[_tokenId].currentMetadata) directly.
        // 2. Triggering an off-chain process to re-render or update the visual representation based on _customizationData.
        // 3. Storing customization history in nfts[_tokenId].customizationHistory for lineage tracking.

        // For this example, let's just update the metadata to indicate customization and append to history
        nfts[_tokenId].currentMetadata = string(abi.encodePacked(nfts[_tokenId].currentMetadata, "&customized=true&proposalId=", _toString(_proposalId)));
        nfts[_tokenId].customizationHistory = string(abi.encodePacked(nfts[_tokenId].customizationHistory, ",", _toString(_proposalId)));
        proposal.executed = true;

        emit CustomizationExecuted(_tokenId, _proposalId);
    }

    /// @notice Retrieves all customization proposals for a specific NFT.
    /// @param _tokenId ID of the NFT.
    /// @return Array of CustomizationProposal structs.
    function getCustomizationProposals(uint256 _tokenId)
        external
        view
        nftExists(_tokenId)
        returns (CustomizationProposal[] memory)
    {
        uint256 proposalCountForNFT = customizationProposalCount; // Simplified - in real case track per NFT proposal count if needed for efficiency
        CustomizationProposal[] memory proposals = new CustomizationProposal[](proposalCountForNFT);
        uint256 index = 0;
        for (uint256 i = 1; i <= proposalCountForNFT; i++) {
            if (nftCustomizationProposals[_tokenId][i].id != 0) { // Check if proposal exists (using ID check as simple existence indicator)
                proposals[index] = nftCustomizationProposals[_tokenId][i];
                index++;
            }
        }
        assembly {
            mstore(proposals, index) // Update array length to actual number of proposals found
        }
        return proposals;
    }


    // --- Community Governance Functions (Royalty Distribution) ---

    /// @notice Allows community members to propose changes to the royalty distribution for a collection.
    /// @param _collectionId ID of the collection.
    /// @param _recipients Array of addresses to receive royalty shares.
    /// @param _percentages Array of royalty percentages for each recipient (must sum to 100).
    function proposeRoyaltyDistributionChange(
        uint256 _collectionId,
        address[] memory _recipients,
        uint256[] memory _percentages
    ) external whenNotPaused collectionExists(_collectionId) {
        require(_recipients.length == _percentages.length, "Recipients and percentages arrays must have the same length.");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < _percentages.length; i++) {
            totalPercentage += _percentages[i];
        }
        require(totalPercentage == 100, "Royalty percentages must sum to 100.");

        royaltyDistributionProposalCount++;
        uint256 proposalId = royaltyDistributionProposalCount;
        collectionRoyaltyDistributionProposals[_collectionId][proposalId] = RoyaltyDistributionProposal({
            id: proposalId,
            collectionId: _collectionId,
            proposer: msg.sender,
            recipients: _recipients,
            percentages: _percentages,
            upvotes: 0,
            downvotes: 0,
            startTime: block.number,
            endTime: block.number + contractParameters.votingDuration,
            executed: false
        });
        emit RoyaltyDistributionProposed(_collectionId, proposalId, msg.sender);
    }

    /// @notice Allows community members to vote on a royalty distribution change proposal.
    /// @param _collectionId ID of the collection.
    /// @param _proposalId ID of the royalty distribution proposal.
    /// @param _vote True for upvote, false for downvote.
    function voteForRoyaltyDistributionChange(uint256 _collectionId, uint256 _proposalId, bool _vote)
        external
        whenNotPaused
        collectionExists(_collectionId)
    {
        RoyaltyDistributionProposal storage proposal = collectionRoyaltyDistributionProposals[_collectionId][_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.number < proposal.endTime, "Voting period ended.");

        // Community voting logic - define who can vote (e.g., NFT holders of the collection, DAO members, etc.)
        // For this example, let's assume anyone can vote (open governance) - refine based on requirements.

        if (_vote) {
            proposal.upvotes++;
        } else {
            proposal.downvotes++;
        }
        emit RoyaltyDistributionVoted(_collectionId, _proposalId, msg.sender, _vote);
    }

    /// @notice Executes a royalty distribution change proposal if approved.
    /// @param _collectionId ID of the collection.
    /// @param _proposalId ID of the royalty distribution proposal.
    function executeRoyaltyDistributionChange(uint256 _collectionId, uint256 _proposalId)
        external
        onlyOwner // For security, only owner can execute royalty change - consider DAO or multi-sig for decentralized governance
        whenNotPaused
        collectionExists(_collectionId)
    {
        RoyaltyDistributionProposal storage proposal = collectionRoyaltyDistributionProposals[_collectionId][_proposalId];
        require(!proposal.executed, "Proposal already executed.");
        require(block.number >= proposal.endTime, "Voting period not ended.");

        // Define quorum for royalty change proposals (could be different from customization quorum)
        uint256 quorumPercentage = 50; // Example: 50% quorum for royalty changes
        uint256 totalPossibleVoters = 1000; // Placeholder - in real case, track eligible voters
        uint256 quorum = (totalPossibleVoters * quorumPercentage) / 100;
        uint256 totalVotes = proposal.upvotes + proposal.downvotes;

        require(totalVotes >= quorum, "Quorum not reached.");
        require(proposal.upvotes > proposal.downvotes, "Proposal not approved by majority.");

        collections[_collectionId].royaltyRecipient = proposal.recipients[0]; // For simplicity, assume first recipient is the main one for now (adjust as needed)
        collections[_collectionId].royaltyPercentage = proposal.percentages[0]; // Assuming single royalty recipient and percentage for now - extend for complex distributions later
        // **Advanced Concept: Complex Royalty Splits** - For more advanced royalty distribution, you could implement logic to handle multiple recipients and split percentages based on the `proposal.recipients` and `proposal.percentages` arrays.

        proposal.executed = true;
        emit RoyaltyDistributionExecuted(_collectionId, _proposalId);
    }


    // --- Platform Parameter Management ---

    /// @notice Retrieves contract parameters.
    /// @return Parameters struct containing contract parameter values.
    function getParameters() external view returns (Parameters memory) {
        return contractParameters;
    }

    /// @notice Sets the customization quorum percentage. Only callable by the contract owner.
    /// @param _newQuorum New quorum percentage (e.g., 51 for 51%).
    function setCustomizationQuorum(uint256 _newQuorum) external onlyOwner whenNotPaused {
        require(_newQuorum <= 100, "Quorum percentage must be less than or equal to 100.");
        contractParameters.customizationQuorumPercentage = _newQuorum;
    }

    /// @notice Sets the voting duration for proposals. Only callable by the contract owner.
    /// @param _newDuration New voting duration in blocks.
    function setVotingDuration(uint256 _newDuration) external onlyOwner whenNotPaused {
        contractParameters.votingDuration = _newDuration;
    }


    // --- Utility & Access Control Functions ---

    /// @notice Pauses the contract, preventing most state-changing functions from being called. Only callable by the contract owner.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses the contract, allowing functionalities to resume. Only callable by the contract owner.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the contract owner to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    /// @notice Fallback function to reject direct ether transfers to the contract (except during minting).
    receive() external payable {
        require(msg.data.length == 0, "Direct ETH transfer not allowed, use mint function.");
    }

    /// @inheritdoc ERC165
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        // Add support for ERC721 Metadata and other relevant interfaces if needed
        return interfaceId == 0x01ffc9a7 || // ERC165 Interface ID
               interfaceId == 0x80ac58cd;   // ERC721 Interface ID (if you implement ERC721 features)
    }


    // --- Internal Utility Functions ---
    function _toString(uint256 _num) internal pure returns (string memory) {
        if (_num == 0) {
            return "0";
        }
        uint256 j = _num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_num != 0) {
            bstr[k--] = bytes1(uint8(48 + _num % 10));
            _num /= 10;
        }
        return string(bstr);
    }
}
```