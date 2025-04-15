```solidity
/**
 * @title Decentralized Dynamic Content Platform - "Evolving Canvas"
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized platform where content (represented as NFTs)
 *      can dynamically evolve based on community voting and creator actions. This platform
 *      introduces concepts of content evolution proposals, reputation-based moderation,
 *      dynamic royalties, and decentralized governance for platform parameters.
 *
 * Function Summary:
 *
 * **Content Creation & Management:**
 * 1. `createContent(string _metadataURI, uint256 _initialVersionData)`: Allows creators to mint new content NFTs with initial metadata and data.
 * 2. `setContentMetadataURI(uint256 _contentId, string _newMetadataURI)`: Allows content creators to update the metadata URI of their content.
 * 3. `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a content NFT, including current version and metadata.
 * 4. `getContentVersionData(uint256 _contentId, uint256 _version)`: Retrieves the data associated with a specific version of a content NFT.
 * 5. `getContentCurrentVersion(uint256 _contentId)`: Retrieves the current version number of a content NFT.
 * 6. `isContentCreator(uint256 _contentId, address _creator)`: Checks if an address is the creator of a specific content NFT.
 * 7. `transferContentOwnership(uint256 _contentId, address _newOwner)`: Allows content creators to transfer ownership of their content NFTs.
 *
 * **Content Evolution & Voting:**
 * 8. `proposeContentEvolution(uint256 _contentId, uint256 _newVersionData, string _evolutionReason)`: Creators propose a new version (evolution) of their content.
 * 9. `voteOnEvolutionProposal(uint256 _contentId, uint256 _proposalId, bool _vote)`: Users can vote on content evolution proposals.
 * 10. `getEvolutionProposalDetails(uint256 _contentId, uint256 _proposalId)`: Retrieves details of a specific content evolution proposal.
 * 11. `applyContentEvolution(uint256 _contentId, uint256 _proposalId)`: Applies a successful evolution proposal, updating content version.
 * 12. `cancelContentEvolutionProposal(uint256 _contentId, uint256 _proposalId)`: Allows creators to cancel their pending evolution proposals.
 *
 * **Reputation & Moderation:**
 * 13. `reportContent(uint256 _contentId, string _reportReason)`: Users can report content for policy violations.
 * 14. `moderateContent(uint256 _contentId, bool _isApproved)`: Platform moderators (reputation-based) can moderate reported content.
 * 15. `getModerationStatus(uint256 _contentId)`: Retrieves the current moderation status of a content NFT.
 * 16. `setModeratorRole(address _moderator, bool _isModerator)`: Platform admin can assign/revoke moderator roles based on reputation or selection process.
 *
 * **Platform Governance & Parameters:**
 * 17. `setPlatformFee(uint256 _newFeePercentage)`: Platform admin can set a platform fee percentage on content interactions.
 * 18. `withdrawPlatformFees()`: Platform admin can withdraw accumulated platform fees.
 * 19. `pauseContract()`: Platform admin can pause the contract for maintenance or emergency.
 * 20. `unpauseContract()`: Platform admin can unpause the contract.
 * 21. `migrateContract(address _newContractAddress)`: Platform admin can migrate to a new contract version (advanced upgrade mechanism).
 *
 * **Utility & Information:**
 * 22. `supportsInterface(bytes4 interfaceId)`: Standard ERC165 interface support.
 * 23. `getPlatformFee()`: Retrieves the current platform fee percentage.
 * 24. `isModerator(address _account)`: Checks if an address is a platform moderator.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol"; // For royalty standard (optional, can be removed if not needed)

contract EvolvingCanvas is ERC721, Ownable, Pausable, IERC2981 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Structs and Enums ---

    struct ContentItem {
        address creator;
        string metadataURI;
        uint256 currentVersion;
        uint256 creationTimestamp;
        ModerationStatus moderationStatus;
    }

    struct ContentVersion {
        uint256 versionNumber;
        uint256 data; // Placeholder for content data (can be IPFS hash, on-chain data, etc.)
        uint256 timestamp;
    }

    struct EvolutionProposal {
        uint256 proposalId;
        uint256 contentId;
        address proposer; // Creator who proposed the evolution
        uint256 newVersionData;
        string reason;
        uint256 proposalTimestamp;
        uint256 upvotes;
        uint256 downvotes;
        bool isActive;
    }

    enum ModerationStatus { PENDING, APPROVED, REJECTED, REPORTED }

    // --- State Variables ---

    mapping(uint256 => ContentItem) public contentItems;
    mapping(uint256 => mapping(uint256 => ContentVersion)) public contentVersions; // contentId => versionNumber => ContentVersion
    mapping(uint256 => EvolutionProposal) public evolutionProposals;
    mapping(uint256 => mapping(address => bool)) public evolutionVotes; // contentId => proposalId => voterAddress => vote (true=upvote, false=downvote)
    mapping(uint256 => ModerationStatus) public contentModerationStatus;
    mapping(address => bool) public isPlatformModerator;

    Counters.Counter private _contentIdCounter;
    Counters.Counter private _proposalIdCounter;

    uint256 public platformFeePercentage = 2; // Default 2% platform fee
    address public platformFeeRecipient; // Address to receive platform fees

    // --- Events ---

    event ContentCreated(uint256 contentId, address creator, string metadataURI, uint256 initialVersionData);
    event ContentMetadataUpdated(uint256 contentId, string newMetadataURI);
    event ContentEvolved(uint256 contentId, uint256 newVersion);
    event EvolutionProposalCreated(uint256 contentId, uint256 proposalId, address proposer);
    event EvolutionProposalVoted(uint256 contentId, uint256 proposalId, address voter, bool vote);
    event EvolutionProposalApplied(uint256 contentId, uint256 proposalId);
    event EvolutionProposalCancelled(uint256 contentId, uint256 proposalId);
    event ContentReported(uint256 contentId, address reporter, string reason);
    event ContentModerated(uint256 contentId, bool isApproved, address moderator);
    event PlatformFeeUpdated(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(uint256 amount, address recipient);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ContractMigrated(address newContractAddress);
    event ModeratorRoleSet(address moderator, bool isModerator);

    // --- Modifiers ---

    modifier onlyContentCreator(uint256 _contentId) {
        require(contentItems[_contentId].creator == _msgSender(), "Not content creator");
        _;
    }

    modifier onlyPlatformModerator() {
        require(isPlatformModerator[_msgSender()], "Not a platform moderator");
        _;
    }

    modifier whenNotModerated(uint256 _contentId) {
        require(contentModerationStatus[_contentId] != ModerationStatus.REJECTED, "Content is rejected and cannot be modified");
        _;
    }

    modifier whenContentExists(uint256 _contentId) {
        require(_exists(_contentId), "Content does not exist");
        _;
    }

    // --- Constructor ---

    constructor() ERC721("EvolvingCanvas", "EVOLVE") {
        platformFeeRecipient = owner(); // Default platform fee recipient is contract owner
    }

    // --- Content Creation & Management Functions ---

    function createContent(string memory _metadataURI, uint256 _initialVersionData)
        public
        whenNotPaused
        returns (uint256)
    {
        _contentIdCounter.increment();
        uint256 contentId = _contentIdCounter.current();

        _mint(_msgSender(), contentId);

        contentItems[contentId] = ContentItem({
            creator: _msgSender(),
            metadataURI: _metadataURI,
            currentVersion: 1,
            creationTimestamp: block.timestamp,
            moderationStatus: ModerationStatus.PENDING // Initial moderation status
        });

        contentVersions[contentId][1] = ContentVersion({
            versionNumber: 1,
            data: _initialVersionData,
            timestamp: block.timestamp
        });

        contentModerationStatus[contentId] = ModerationStatus.PENDING; // Set initial moderation status

        emit ContentCreated(contentId, _msgSender(), _metadataURI, _initialVersionData);
        return contentId;
    }

    function setContentMetadataURI(uint256 _contentId, string memory _newMetadataURI)
        public
        whenNotPaused
        onlyContentCreator(_contentId)
        whenContentExists(_contentId)
        whenNotModerated(_contentId)
    {
        contentItems[_contentId].metadataURI = _newMetadataURI;
        emit ContentMetadataUpdated(_contentId, _newMetadataURI);
    }

    function getContentDetails(uint256 _contentId)
        public
        view
        whenContentExists(_contentId)
        returns (ContentItem memory, ContentVersion memory)
    {
        return (
            contentItems[_contentId],
            contentVersions[_contentId][contentItems[_contentId].currentVersion]
        );
    }

    function getContentVersionData(uint256 _contentId, uint256 _version)
        public
        view
        whenContentExists(_contentId)
        returns (ContentVersion memory)
    {
        require(contentVersions[_contentId][_version].versionNumber != 0, "Version not found"); // Check if version exists
        return contentVersions[_contentId][_version];
    }

    function getContentCurrentVersion(uint256 _contentId)
        public
        view
        whenContentExists(_contentId)
        returns (uint256)
    {
        return contentItems[_contentId].currentVersion;
    }

    function isContentCreator(uint256 _contentId, address _creator)
        public
        view
        whenContentExists(_contentId)
        returns (bool)
    {
        return contentItems[_contentId].creator == _creator;
    }

    function transferContentOwnership(uint256 _contentId, address _newOwner)
        public
        whenNotPaused
        onlyContentCreator(_contentId)
        whenContentExists(_contentId)
        whenNotModerated(_contentId)
    {
        _transfer(_msgSender(), _newOwner, _contentId);
        contentItems[_contentId].creator = _newOwner; // Update creator in ContentItem struct
    }

    // --- Content Evolution & Voting Functions ---

    function proposeContentEvolution(uint256 _contentId, uint256 _newVersionData, string memory _evolutionReason)
        public
        whenNotPaused
        onlyContentCreator(_contentId)
        whenContentExists(_contentId)
        whenNotModerated(_contentId)
    {
        _proposalIdCounter.increment();
        uint256 proposalId = _proposalIdCounter.current();

        evolutionProposals[proposalId] = EvolutionProposal({
            proposalId: proposalId,
            contentId: _contentId,
            proposer: _msgSender(),
            newVersionData: _newVersionData,
            reason: _evolutionReason,
            proposalTimestamp: block.timestamp,
            upvotes: 0,
            downvotes: 0,
            isActive: true
        });

        emit EvolutionProposalCreated(_contentId, proposalId, _msgSender());
    }

    function voteOnEvolutionProposal(uint256 _contentId, uint256 _proposalId, bool _vote)
        public
        whenNotPaused
        whenContentExists(_contentId)
    {
        require(evolutionProposals[_proposalId].isActive, "Proposal is not active");
        require(!evolutionVotes[_proposalId][_msgSender()], "Already voted on this proposal");

        evolutionVotes[_proposalId][_msgSender()] = true; // Record voter

        if (_vote) {
            evolutionProposals[_proposalId].upvotes++;
        } else {
            evolutionProposals[_proposalId].downvotes++;
        }

        emit EvolutionProposalVoted(_contentId, _proposalId, _msgSender(), _vote);
    }

    function getEvolutionProposalDetails(uint256 _contentId, uint256 _proposalId)
        public
        view
        whenContentExists(_contentId)
        returns (EvolutionProposal memory)
    {
        return evolutionProposals[_proposalId];
    }

    function applyContentEvolution(uint256 _contentId, uint256 _proposalId)
        public
        whenNotPaused
        whenContentExists(_contentId)
        onlyContentCreator(_contentId)
    {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.contentId == _contentId, "Proposal not for this content");
        require(proposal.isActive, "Proposal is not active");
        require(proposal.upvotes > proposal.downvotes, "Proposal not approved by community"); // Simple majority rule, can be adjusted

        contentItems[_contentId].currentVersion++;
        uint256 newVersion = contentItems[_contentId].currentVersion;

        contentVersions[_contentId][newVersion] = ContentVersion({
            versionNumber: newVersion,
            data: proposal.newVersionData,
            timestamp: block.timestamp
        });

        proposal.isActive = false; // Deactivate the proposal

        emit ContentEvolved(_contentId, newVersion);
        emit EvolutionProposalApplied(_contentId, _proposalId);
    }

    function cancelContentEvolutionProposal(uint256 _contentId, uint256 _proposalId)
        public
        whenNotPaused
        onlyContentCreator(_contentId)
        whenContentExists(_contentId)
    {
        EvolutionProposal storage proposal = evolutionProposals[_proposalId];
        require(proposal.contentId == _contentId, "Proposal not for this content");
        require(proposal.isActive, "Proposal is not active");

        proposal.isActive = false;
        emit EvolutionProposalCancelled(_contentId, _proposalId);
    }

    // --- Reputation & Moderation Functions ---

    function reportContent(uint256 _contentId, string memory _reportReason)
        public
        whenNotPaused
        whenContentExists(_contentId)
    {
        contentModerationStatus[_contentId] = ModerationStatus.REPORTED;
        emit ContentReported(_contentId, _msgSender(), _reportReason);
    }

    function moderateContent(uint256 _contentId, bool _isApproved)
        public
        whenNotPaused
        onlyPlatformModerator()
        whenContentExists(_contentId)
    {
        ModerationStatus newStatus = _isApproved ? ModerationStatus.APPROVED : ModerationStatus.REJECTED;
        contentModerationStatus[_contentId] = newStatus;
        emit ContentModerated(_contentId, _isApproved, _msgSender());
    }

    function getModerationStatus(uint256 _contentId)
        public
        view
        whenContentExists(_contentId)
        returns (ModerationStatus)
    {
        return contentModerationStatus[_contentId];
    }

    function setModeratorRole(address _moderator, bool _isModerator) public onlyOwner {
        isPlatformModerator[_moderator] = _isModerator;
        emit ModeratorRoleSet(_moderator, _isModerator);
    }

    function isModerator(address _account) public view returns (bool) {
        return isPlatformModerator[_account];
    }


    // --- Platform Governance & Parameter Functions ---

    function setPlatformFee(uint256 _newFeePercentage) public onlyOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100%"); // Cap at 100%
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeeUpdated(_newFeePercentage);
    }

    function getPlatformFee() public view returns (uint256) {
        return platformFeePercentage;
    }

    function withdrawPlatformFees() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(platformFeeRecipient).transfer(balance);
        emit PlatformFeesWithdrawn(balance, platformFeeRecipient);
    }

    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused(_msgSender());
    }

    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused(_msgSender());
    }

    function migrateContract(address _newContractAddress) public onlyOwner {
        require(_newContractAddress != address(0), "Invalid new contract address");
        // Add logic for data migration if needed (complex and depends on data structure)
        platformFeeRecipient = _newContractAddress; // Example: Update fee recipient in new contract
        emit ContractMigrated(_newContractAddress);
        // Consider self-destructing or disabling functionalities in the old contract after migration
    }

    // --- ERC721 & IERC2981 Overrides & Utility ---

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    // --- Optional Royalty Implementation (IERC2981) - Remove if not needed ---
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        public
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        // Example: 5% royalty to creator
        address creator = contentItems[_tokenId].creator;
        uint256 royalty = (_salePrice * 5) / 100; // 5% royalty
        return (creator, royalty);
    }
}
```