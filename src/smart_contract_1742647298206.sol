```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Dynamic Content NFT (DDCNFT) with Adaptive Rarity and Community Curation
 * @author Bard (Inspired by user request)
 * @dev This contract implements a novel NFT concept where the NFT's content and rarity dynamically change based on community interaction, market conditions, and algorithmic factors.
 * It's designed to be engaging, interactive, and explore new dimensions of NFT utility and value.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1. `mintDDCNFT(string _initialContentURI, string _metadataURI)`: Mints a new DDCNFT with initial content and metadata.
 * 2. `setContentURI(uint256 _tokenId, string _newContentURI)`: Allows the NFT owner to propose a content update.
 * 3. `voteOnContentUpdate(uint256 _tokenId, string _proposedContentURI, bool _approve)`: Allows community members to vote on proposed content updates.
 * 4. `finalizeContentUpdate(uint256 _tokenId)`: Finalizes a content update if it reaches community approval.
 * 5. `reportInappropriateContent(uint256 _tokenId)`: Allows community members to report inappropriate content.
 * 6. `voteOnContentReport(uint256 _tokenId, bool _isInappropriate)`: Allows curators to vote on content reports.
 * 7. `removeInappropriateContent(uint256 _tokenId)`: Removes content based on curator vote and sets a default/placeholder content.
 * 8. `evolveRarity(uint256 _tokenId)`: Dynamically adjusts NFT rarity based on engagement metrics (views, votes, transfers).
 * 9. `setRarityAlgorithmParameters(...)`: Allows admin to adjust parameters for the rarity evolution algorithm.
 * 10. `viewNFTMetadata(uint256 _tokenId)`: Retrieves the current metadata URI for an NFT.
 * 11. `viewNFTContent(uint256 _tokenId)`: Retrieves the current content URI for an NFT.
 * 12. `getNFTActivityScore(uint256 _tokenId)`: Returns an activity score for an NFT based on interactions.
 *
 * **Community & Governance Features:**
 * 13. `becomeContentCurator()`: Allows users to apply to become content curators.
 * 14. `nominateCurator(address _candidate)`: Allows existing curators to nominate new curators.
 * 15. `voteOnCuratorNomination(address _candidate, bool _approve)`: Allows community to vote on curator nominations.
 * 16. `revokeCuratorRole(address _curator)`: Allows admin to revoke curator roles in extreme cases.
 * 17. `setContentUpdateThreshold(uint256 _threshold)`: Allows admin to set the community vote threshold for content updates.
 * 18. `setContentReportThreshold(uint256 _threshold)`: Allows admin to set the curator vote threshold for content reports.
 *
 * **Utility & Advanced Features:**
 * 19. `transferDDCNFT(address _to, uint256 _tokenId)`: Overrides standard transfer to potentially trigger rarity adjustments on transfer.
 * 20. `batchMintDDCNFT(string[] memory _initialContentURIs, string[] memory _metadataURIs)`: Mints multiple DDCNFTs in a batch.
 * 21. `burnDDCNFT(uint256 _tokenId)`: Allows the NFT owner to burn their DDCNFT.
 * 22. `pauseContract()`: Allows admin to pause the contract for maintenance or emergency.
 * 23. `unpauseContract()`: Allows admin to unpause the contract.
 * 24. `setDefaultContentURI(string _uri)`: Sets a default content URI for NFTs with removed content.
 * 25. `setBaseMetadataURI(string _baseURI)`: Allows setting a base URI for metadata for easier management.
 */

contract DecentralizedDynamicContentNFT {
    // --- State Variables ---

    string public name = "Decentralized Dynamic Content NFT";
    string public symbol = "DDCNFT";

    address public admin; // Contract administrator
    string public defaultContentURI; // Default content URI for removed content
    string public baseMetadataURI; // Base URI for metadata

    uint256 public totalSupply;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => string) public tokenContentURIs;
    mapping(uint256 => string) public tokenMetadataURIs;
    mapping(uint256 => RarityLevel) public tokenRarities;

    enum RarityLevel { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, MYTHIC }
    RarityLevel public initialRarity = RarityLevel.COMMON;

    uint256 public contentUpdateVoteThreshold = 50; // Percentage threshold for content update votes
    uint256 public contentReportVoteThreshold = 66; // Percentage threshold for content report votes

    mapping(uint256 => ContentUpdateProposal) public contentUpdateProposals;
    struct ContentUpdateProposal {
        string proposedContentURI;
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;
        uint256 proposalTimestamp;
    }

    mapping(uint256 => ContentReport) public contentReports;
    struct ContentReport {
        address reporter;
        bool isInappropriate;
        uint256 upvotes; // Curator votes for inappropriate
        uint256 downvotes; // Curator votes for appropriate
        bool isActive;
        uint256 reportTimestamp;
    }

    mapping(address => bool) public isContentCurator;
    mapping(address => CuratorNomination) public curatorNominations;
    struct CuratorNomination {
        bool isActive;
        uint256 upvotes;
        uint256 downvotes;
        uint256 nominationTimestamp;
    }
    address[] public curators;

    bool public paused = false;

    // --- Events ---
    event DDCNFTMinted(uint256 tokenId, address owner, string contentURI, string metadataURI);
    event ContentURIUpdated(uint256 tokenId, string newContentURI);
    event ContentUpdateProposed(uint256 tokenId, string proposedContentURI, address proposer);
    event ContentUpdateVoteCast(uint256 tokenId, string proposedContentURI, address voter, bool approve);
    event ContentUpdateFinalized(uint256 tokenId, string newContentURI);
    event ContentReported(uint256 tokenId, address reporter);
    event ContentReportVoteCast(uint256 tokenId, uint256 reportId, address curator, bool isInappropriate);
    event ContentRemoved(uint256 tokenId, address remover);
    event RarityEvolved(uint256 tokenId, RarityLevel newRarity);
    event CuratorNominated(address candidate, address nominator);
    event CuratorNominationVoteCast(address candidate, address voter, bool approve);
    event CuratorAdded(address curator);
    event CuratorRemoved(address curator);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event DefaultContentURISet(string newDefaultURI);
    event BaseMetadataURISet(string newBaseURI);


    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
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

    modifier validTokenId(uint256 _tokenId) {
        require(ownerOf[_tokenId] != address(0), "Invalid token ID.");
        _;
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
        require(ownerOf[_tokenId] == msg.sender, "You are not the owner of this NFT.");
        _;
    }

    modifier onlyContentCurator() {
        require(isContentCurator[msg.sender], "You are not a content curator.");
        _;
    }


    // --- Constructor ---
    constructor(string memory _defaultContentURI, string memory _baseMetadataURI) {
        admin = msg.sender;
        defaultContentURI = _defaultContentURI;
        baseMetadataURI = _baseMetadataURI;
    }


    // --- Core Functionality ---

    /// @notice Mints a new DDCNFT with initial content and metadata.
    /// @param _initialContentURI URI pointing to the initial content of the NFT.
    /// @param _metadataURI URI pointing to the metadata of the NFT.
    function mintDDCNFT(string memory _initialContentURI, string memory _metadataURI)
        public
        whenNotPaused
        returns (uint256 tokenId)
    {
        tokenId = ++totalSupply;
        ownerOf[tokenId] = msg.sender;
        balanceOf[msg.sender]++;
        tokenContentURIs[tokenId] = _initialContentURI;
        tokenMetadataURIs[tokenId] = string(abi.encodePacked(baseMetadataURI, _metadataURI)); // Combine base URI with specific metadata URI
        tokenRarities[tokenId] = initialRarity;

        emit DDCNFTMinted(tokenId, msg.sender, _initialContentURI, string(abi.encodePacked(baseMetadataURI, _metadataURI)));
        return tokenId;
    }

    /// @notice Allows the NFT owner to propose a content update.
    /// @param _tokenId The ID of the NFT to update.
    /// @param _newContentURI URI pointing to the proposed new content.
    function setContentURI(uint256 _tokenId, string memory _newContentURI)
        public
        validTokenId(_tokenId)
        onlyTokenOwner(_tokenId)
        whenNotPaused
    {
        require(contentUpdateProposals[_tokenId].isActive == false, "A content update proposal is already active for this NFT.");
        contentUpdateProposals[_tokenId] = ContentUpdateProposal({
            proposedContentURI: _newContentURI,
            upvotes: 1, // Owner implicitly upvotes their own proposal
            downvotes: 0,
            isActive: true,
            proposalTimestamp: block.timestamp
        });
        emit ContentUpdateProposed(_tokenId, _newContentURI, msg.sender);
    }

    /// @notice Allows community members to vote on proposed content updates.
    /// @param _tokenId The ID of the NFT being voted on.
    /// @param _proposedContentURI The content URI being voted on (for verification).
    /// @param _approve True to approve the content update, false to reject.
    function voteOnContentUpdate(uint256 _tokenId, string memory _proposedContentURI, bool _approve)
        public
        validTokenId(_tokenId)
        whenNotPaused
    {
        require(contentUpdateProposals[_tokenId].isActive, "No active content update proposal for this NFT.");
        require(keccak256(bytes(contentUpdateProposals[_tokenId].proposedContentURI)) == keccak256(bytes(_proposedContentURI)), "Proposed content URI mismatch.");
        require(ownerOf[_tokenId] != msg.sender, "Owner cannot vote on their own proposal (initial vote already counted)."); // To prevent double voting by owner

        if (_approve) {
            contentUpdateProposals[_tokenId].upvotes++;
        } else {
            contentUpdateProposals[_tokenId].downvotes++;
        }
        emit ContentUpdateVoteCast(_tokenId, _proposedContentURI, msg.sender, _approve);

        // Check if threshold reached after vote
        if (calculateVotePercentage(contentUpdateProposals[_tokenId].upvotes, contentUpdateProposals[_tokenId].upvotes + contentUpdateProposals[_tokenId].downvotes) >= contentUpdateVoteThreshold) {
            finalizeContentUpdate(_tokenId);
        }
    }

    /// @notice Finalizes a content update if it reaches community approval.
    /// @param _tokenId The ID of the NFT to finalize the content update for.
    function finalizeContentUpdate(uint256 _tokenId)
        private
        validTokenId(_tokenId)
        whenNotPaused
    {
        require(contentUpdateProposals[_tokenId].isActive, "No active content update proposal for this NFT.");
        require(calculateVotePercentage(contentUpdateProposals[_tokenId].upvotes, contentUpdateProposals[_tokenId].upvotes + contentUpdateProposals[_tokenId].downvotes) >= contentUpdateVoteThreshold, "Content update proposal not approved by community.");

        tokenContentURIs[_tokenId] = contentUpdateProposals[_tokenId].proposedContentURI;
        contentUpdateProposals[_tokenId].isActive = false; // Deactivate proposal
        emit ContentUpdateFinalized(_tokenId, tokenContentURIs[_tokenId]);
        evolveRarity(_tokenId); // Rarity might evolve after content update
    }

    /// @notice Allows community members to report inappropriate content for an NFT.
    /// @param _tokenId The ID of the NFT with potentially inappropriate content.
    function reportInappropriateContent(uint256 _tokenId)
        public
        validTokenId(_tokenId)
        whenNotPaused
    {
        require(contentReports[_tokenId].isActive == false, "A content report is already active for this NFT.");
        contentReports[_tokenId] = ContentReport({
            reporter: msg.sender,
            isInappropriate: true, // Initially assumed inappropriate
            upvotes: 0,
            downvotes: 0,
            isActive: true,
            reportTimestamp: block.timestamp
        });
        emit ContentReported(_tokenId, msg.sender);
    }

    /// @notice Allows curators to vote on content reports.
    /// @param _tokenId The ID of the NFT being reported.
    /// @param _isInappropriate True if curator votes the content is inappropriate, false otherwise.
    function voteOnContentReport(uint256 _tokenId, bool _isInappropriate)
        public
        validTokenId(_tokenId)
        onlyContentCurator()
        whenNotPaused
    {
        require(contentReports[_tokenId].isActive, "No active content report for this NFT.");

        if (_isInappropriate) {
            contentReports[_tokenId].upvotes++;
        } else {
            contentReports[_tokenId].downvotes++;
        }
        emit ContentReportVoteCast(_tokenId, _tokenId, msg.sender, _isInappropriate);

        // Check if threshold reached after vote
        if (calculateVotePercentage(contentReports[_tokenId].upvotes, curators.length) >= contentReportVoteThreshold) {
            removeInappropriateContent(_tokenId);
        }
    }

    /// @notice Removes content if it's deemed inappropriate by curator vote and sets default content.
    /// @param _tokenId The ID of the NFT to remove content from.
    function removeInappropriateContent(uint256 _tokenId)
        private
        validTokenId(_tokenId)
        whenNotPaused
    {
        require(contentReports[_tokenId].isActive, "No active content report for this NFT.");
        require(calculateVotePercentage(contentReports[_tokenId].upvotes, curators.length) >= contentReportVoteThreshold, "Content report not approved by curators.");

        tokenContentURIs[_tokenId] = defaultContentURI; // Set to default content
        contentReports[_tokenId].isActive = false; // Deactivate report
        emit ContentRemoved(_tokenId, msg.sender);
        evolveRarity(_tokenId); // Rarity might evolve after content removal (likely decrease)
    }


    /// @notice Dynamically adjusts NFT rarity based on engagement metrics (views, votes, transfers - simplified for example).
    /// @param _tokenId The ID of the NFT to evolve rarity for.
    function evolveRarity(uint256 _tokenId)
        private
        validTokenId(_tokenId)
        whenNotPaused
    {
        // --- Simplified Rarity Evolution Logic (Adapt and expand as needed) ---
        uint256 activityScore = getNFTActivityScore(_tokenId);
        RarityLevel currentRarity = tokenRarities[_tokenId];
        RarityLevel newRarity = currentRarity;

        if (activityScore > 100 && currentRarity < RarityLevel.UNCOMMON) {
            newRarity = RarityLevel.UNCOMMON;
        } else if (activityScore > 500 && currentRarity < RarityLevel.RARE) {
            newRarity = RarityLevel.RARE;
        } else if (activityScore > 1000 && currentRarity < RarityLevel.EPIC) {
            newRarity = RarityLevel.EPIC;
        } else if (activityScore > 5000 && currentRarity < RarityLevel.LEGENDARY) {
            newRarity = RarityLevel.LEGENDARY;
        } else if (activityScore > 10000 && currentRarity < RarityLevel.MYTHIC) {
            newRarity = RarityLevel.MYTHIC;
        }

        if (newRarity != currentRarity) {
            tokenRarities[_tokenId] = newRarity;
            emit RarityEvolved(_tokenId, newRarity);
            // You could also update metadata here to reflect the new rarity level
        }
    }

    /// @notice Placeholder function to set parameters for the rarity evolution algorithm (future expansion).
    function setRarityAlgorithmParameters(/* ... parameters ... */ )
        public
        onlyAdmin
        whenNotPaused
    {
        // Placeholder for future implementation:
        // Define parameters for activity score calculation, rarity thresholds, etc.
        // Example:  `rarityEvolutionThresholds[RarityLevel.UNCOMMON] = 100;`
        //          `activityScoreWeights = [voteWeight, transferWeight, viewWeight];`
    }

    /// @notice Retrieves the current metadata URI for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The metadata URI string.
    function viewNFTMetadata(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (string memory)
    {
        return tokenMetadataURIs[_tokenId];
    }

    /// @notice Retrieves the current content URI for an NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return The content URI string.
    function viewNFTContent(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (string memory)
    {
        return tokenContentURIs[_tokenId];
    }

    /// @notice Returns an activity score for an NFT based on interactions (simplified example).
    /// @param _tokenId The ID of the NFT.
    /// @return The activity score.
    function getNFTActivityScore(uint256 _tokenId)
        public
        view
        validTokenId(_tokenId)
        returns (uint256)
    {
        // --- Simplified Activity Score Calculation (Expand and refine) ---
        uint256 score = 0;
        if (contentUpdateProposals[_tokenId].isActive) {
            score += contentUpdateProposals[_tokenId].upvotes + contentUpdateProposals[_tokenId].downvotes;
        }
        if (contentReports[_tokenId].isActive) {
            score += contentReports[_tokenId].upvotes + contentReports[_tokenId].downvotes;
        }
        // Add more factors like transfer count, view count (if trackable off-chain), etc.
        return score;
    }


    // --- Community & Governance Features ---

    /// @notice Allows users to apply to become content curators.
    function becomeContentCurator()
        public
        whenNotPaused
    {
        require(!isContentCurator[msg.sender], "You are already a content curator.");
        require(!curatorNominations[msg.sender].isActive, "You already have an active curator nomination.");

        curatorNominations[msg.sender] = CuratorNomination({
            isActive: true,
            upvotes: 0,
            downvotes: 0,
            nominationTimestamp: block.timestamp
        });
        emit CuratorNominated(msg.sender, address(0)); // 0 address indicates self-nomination
    }

    /// @notice Allows existing curators to nominate new curators.
    /// @param _candidate Address of the user being nominated as a curator.
    function nominateCurator(address _candidate)
        public
        onlyContentCurator()
        whenNotPaused
    {
        require(!isContentCurator[_candidate], "Candidate is already a content curator.");
        require(!curatorNominations[_candidate].isActive, "Candidate already has an active curator nomination.");

        curatorNominations[_candidate] = CuratorNomination({
            isActive: true,
            upvotes: 1, // Curator nominator implicitly upvotes
            downvotes: 0,
            nominationTimestamp: block.timestamp
        });
        emit CuratorNominated(_candidate, msg.sender);
    }

    /// @notice Allows community to vote on curator nominations.
    /// @param _candidate Address of the curator candidate.
    /// @param _approve True to approve the nomination, false to reject.
    function voteOnCuratorNomination(address _candidate, bool _approve)
        public
        whenNotPaused
    {
        require(curatorNominations[_candidate].isActive, "No active curator nomination for this candidate.");
        require(!isContentCurator[msg.sender], "Curators cannot vote on nominations (to avoid self-selection bias, community votes only).");

        if (_approve) {
            curatorNominations[_candidate].upvotes++;
        } else {
            curatorNominations[_candidate].downvotes++;
        }
        emit CuratorNominationVoteCast(_candidate, msg.sender, _approve);

        // Simple threshold - can be made more sophisticated (quorum, etc.)
        if (curatorNominations[_candidate].upvotes > curatorNominations[_candidate].downvotes * 2) { // More upvotes than double downvotes
            addCurator(_candidate);
        }
    }

    /// @notice Adds a curator role to an address.
    /// @param _curator Address to be added as a curator.
    function addCurator(address _curator)
        private
        whenNotPaused
    {
        require(!isContentCurator[_curator], "Address is already a curator.");
        isContentCurator[_curator] = true;
        curators.push(_curator);
        curatorNominations[_curator].isActive = false; // Deactivate nomination
        emit CuratorAdded(_curator);
    }


    /// @notice Revokes curator role from an address (admin only, for extreme cases).
    /// @param _curator Address of the curator to revoke the role from.
    function revokeCuratorRole(address _curator)
        public
        onlyAdmin
        whenNotPaused
    {
        require(isContentCurator[_curator], "Address is not a curator.");
        isContentCurator[_curator] = false;
        // Remove from curators array (inefficient for large arrays, consider optimization if needed)
        for (uint256 i = 0; i < curators.length; i++) {
            if (curators[i] == _curator) {
                delete curators[i];
                // Option to compact the array if needed for gas optimization in very frequent removals
                // curators[i] = curators[curators.length - 1];
                curators.pop();
                break;
            }
        }
        emit CuratorRemoved(_curator);
    }

    /// @notice Allows admin to set the community vote threshold for content updates.
    /// @param _threshold Percentage threshold (0-100).
    function setContentUpdateThreshold(uint256 _threshold)
        public
        onlyAdmin
        whenNotPaused
    {
        require(_threshold <= 100, "Threshold must be between 0 and 100.");
        contentUpdateVoteThreshold = _threshold;
        emit ContentUpdateThresholdSet(_threshold); // Consider adding an event for this
    }

    event ContentUpdateThresholdSet(uint256 threshold);

    /// @notice Allows admin to set the curator vote threshold for content reports.
    /// @param _threshold Percentage threshold (0-100).
    function setContentReportThreshold(uint256 _threshold)
        public
        onlyAdmin
        whenNotPaused
    {
        require(_threshold <= 100, "Threshold must be between 0 and 100.");
        contentReportVoteThreshold = _threshold;
        emit ContentReportThresholdSet(_threshold); // Consider adding an event for this
    }
    event ContentReportThresholdSet(uint256 threshold);


    // --- Utility & Advanced Features ---

    /// @notice Overrides standard transfer to potentially trigger rarity adjustments on transfer.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId The ID of the NFT to transfer.
    function transferDDCNFT(address _to, uint256 _tokenId)
        public
        validTokenId(_tokenId)
        onlyTokenOwner(_tokenId)
        whenNotPaused
    {
        address from = msg.sender;
        balanceOf[from]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        emit Transfer(from, _to, _tokenId);
        evolveRarity(_tokenId); // Rarity might evolve after transfer (can be configured based on transfer frequency, etc.)
    }

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); // Standard ERC721 Transfer event

    /// @notice Mints multiple DDCNFTs in a batch.
    /// @param _initialContentURIs Array of URIs for initial content for each NFT.
    /// @param _metadataURIs Array of URIs for metadata for each NFT.
    function batchMintDDCNFT(string[] memory _initialContentURIs, string[] memory _metadataURIs)
        public
        whenNotPaused
        returns (uint256[] memory tokenIds)
    {
        require(_initialContentURIs.length == _metadataURIs.length, "Content and metadata URI arrays must be the same length.");
        uint256 numNFTs = _initialContentURIs.length;
        tokenIds = new uint256[](numNFTs);

        for (uint256 i = 0; i < numNFTs; i++) {
            tokenIds[i] = ++totalSupply;
            ownerOf[tokenIds[i]] = msg.sender;
            balanceOf[msg.sender]++;
            tokenContentURIs[tokenIds[i]] = _initialContentURIs[i];
            tokenMetadataURIs[tokenIds[i]] = string(abi.encodePacked(baseMetadataURI, _metadataURIs[i]));
            tokenRarities[tokenIds[i]] = initialRarity;
            emit DDCNFTMinted(tokenIds[i], msg.sender, _initialContentURIs[i], string(abi.encodePacked(baseMetadataURI, _metadataURIs[i])));
        }
        return tokenIds;
    }

    /// @notice Allows the NFT owner to burn their DDCNFT.
    /// @param _tokenId The ID of the NFT to burn.
    function burnDDCNFT(uint256 _tokenId)
        public
        validTokenId(_tokenId)
        onlyTokenOwner(_tokenId)
        whenNotPaused
    {
        balanceOf[msg.sender]--;
        delete ownerOf[_tokenId];
        delete tokenContentURIs[_tokenId];
        delete tokenMetadataURIs[_tokenId];
        delete tokenRarities[_tokenId];
        emit Burned(_tokenId);
    }
    event Burned(uint256 indexed tokenId);

    /// @notice Allows admin to pause the contract for maintenance or emergency.
    function pauseContract()
        public
        onlyAdmin
        whenNotPaused
    {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Allows admin to unpause the contract.
    function unpauseContract()
        public
        onlyAdmin
        whenPaused
    {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows admin to set the default content URI.
    /// @param _uri The new default content URI.
    function setDefaultContentURI(string memory _uri)
        public
        onlyAdmin
        whenNotPaused
    {
        defaultContentURI = _uri;
        emit DefaultContentURISet(_uri);
    }

    /// @notice Allows admin to set the base metadata URI.
    /// @param _baseURI The new base metadata URI.
    function setBaseMetadataURI(string memory _baseURI)
        public
        onlyAdmin
        whenNotPaused
    {
        baseMetadataURI = _baseURI;
        emit BaseMetadataURISet(_baseURI);
    }


    // --- Helper/Utility Functions ---

    /// @notice Calculates percentage given numerator and denominator.
    /// @param _numerator Numerator value.
    /// @param _denominator Denominator value.
    /// @return Percentage (0-100).
    function calculateVotePercentage(uint256 _numerator, uint256 _denominator)
        internal
        pure
        returns (uint256)
    {
        if (_denominator == 0) return 0; // Avoid division by zero
        return (_numerator * 100) / _denominator;
    }

    /// @notice Returns the number of curators.
    function getCuratorCount()
        public
        view
        returns (uint256)
    {
        return curators.length;
    }

    /// @notice Returns the list of curators.
    function getCurators()
        public
        view
        returns (address[] memory)
    {
        return curators;
    }

    /// @notice Checks if an address is a curator.
    function isCurator(address _address)
        public
        view
        returns (bool)
    {
        return isContentCurator[_address];
    }
}
```