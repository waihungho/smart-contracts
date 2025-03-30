```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC) for artists and art enthusiasts.
 * It features advanced concepts like generative art integration, dynamic NFT traits, community-driven curation,
 * decentralized governance over art exhibitions, and a unique royalty distribution mechanism.
 * This contract aims to be a comprehensive platform for managing and evolving a decentralized art ecosystem.
 *
 * Function Summary:
 *
 * **Art Proposal & Submission:**
 * 1. `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Allows artists to submit art proposals with title, description, and IPFS hash.
 * 2. `setProposalMetadata(uint256 _proposalId, string memory _title, string memory _description, string memory _ipfsHash)`: Artists can update their proposal metadata before curation.
 * 3. `getArtProposal(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 * 4. `getAllArtProposals()`: Returns a list of all art proposals.
 *
 * **Curation & Voting:**
 * 5. `voteForProposal(uint256 _proposalId, bool _approve)`: Community members can vote to approve or reject art proposals.
 * 6. `getCurationStatus(uint256 _proposalId)`: Returns the current curation status (pending, approved, rejected) of a proposal.
 * 7. `getProposalVotes(uint256 _proposalId)`: Retrieves the vote count for a specific proposal.
 * 8. `setCurationQuorum(uint256 _quorumPercentage)`: Admin function to set the quorum percentage for proposal approval.
 *
 * **NFT Minting & Distribution:**
 * 9. `mintArtNFT(uint256 _proposalId)`: Mints an NFT for an approved art proposal, callable by admin after curation.
 * 10. `getNFTMetadata(uint256 _tokenId)`: Retrieves metadata for a minted NFT.
 * 11. `transferNFT(uint256 _tokenId, address _to)`: Allows NFT owners to transfer their NFTs.
 * 12. `getNFTArtist(uint256 _tokenId)`: Returns the original artist of a specific NFT.
 *
 * **Dynamic NFT Traits & Generative Art (Conceptual):**
 * 13. `evolveNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue)`: Allows for dynamic evolution of NFT traits based on community votes or external factors (conceptual).
 * 14. `triggerGenerativeArtUpdate(uint256 _tokenId)`: Triggers a (conceptual) generative art update for an NFT, potentially changing its visual representation.
 *
 * **DAO Governance & Exhibition:**
 * 15. `submitExhibitionProposal(string memory _exhibitionName, string memory _description, uint256 _startDate, uint256 _endDate)`: Allows community members to propose art exhibitions.
 * 16. `voteForExhibition(uint256 _exhibitionProposalId, bool _approve)`: Community votes on exhibition proposals.
 * 17. `getExhibitionProposal(uint256 _exhibitionProposalId)`: Retrieves details of an exhibition proposal.
 * 18. `scheduleExhibition(uint256 _exhibitionProposalId)`: Admin function to schedule an approved exhibition.
 * 19. `cancelExhibition(uint256 _exhibitionProposalId)`: Admin function to cancel a scheduled exhibition.
 *
 * **Royalties & Revenue Sharing:**
 * 20. `setSecondaryMarketRoyalty(uint256 _royaltyPercentage)`: Admin function to set the secondary market royalty percentage for artists.
 * 21. `withdrawArtistRoyalties()`: Artists can withdraw their accumulated royalties.
 * 22. `getArtistRoyaltyBalance(address _artist)`: View function to check an artist's royalty balance.
 *
 * **Admin & Utility Functions:**
 * 23. `setAdmin(address _newAdmin)`: Admin function to change the contract admin.
 * 24. `pauseContract()`: Admin function to pause core functionalities of the contract.
 * 25. `unpauseContract()`: Admin function to unpause the contract.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _proposalIds;
    Counters.Counter private _nftTokenIds;
    Counters.Counter private _exhibitionProposalIds;

    // Structs
    struct ArtProposal {
        uint256 proposalId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 upvotes;
        uint256 downvotes;
        CurationStatus status;
        uint256 submissionTimestamp;
    }

    struct ExhibitionProposal {
        uint256 proposalId;
        address proposer;
        string name;
        string description;
        uint256 startDate;
        uint256 endDate;
        uint256 upvotes;
        uint256 downvotes;
        bool isApproved;
        bool isScheduled;
        uint256 submissionTimestamp;
    }

    // Enums
    enum CurationStatus { Pending, Approved, Rejected }

    // Mappings
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => CurationStatus) public proposalCurationStatus;
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId => voter => vote (true=upvote, false=downvote)
    mapping(uint256 => ExhibitionProposal) public exhibitionProposals;
    mapping(uint256 => string) public nftMetadataURIs;
    mapping(uint256 => address) public nftArtists;
    mapping(address => uint256) public artistRoyaltyBalances;

    // State Variables
    uint256 public curationQuorumPercentage = 51; // Default quorum for proposal approval
    uint256 public secondaryMarketRoyaltyPercentage = 5; // Default secondary market royalty for artists
    bool public contractPaused = false;

    // Events
    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ProposalMetadataUpdated(uint256 proposalId, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool approve);
    event ProposalCurationStatusUpdated(uint256 proposalId, CurationStatus status);
    event ArtNFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event NFTTraitEvolved(uint256 tokenId, string traitName, string traitValue);
    event GenerativeArtUpdateTriggered(uint256 tokenId);
    event ExhibitionProposalSubmitted(uint256 proposalId, address proposer, string name);
    event ExhibitionProposalVoted(uint256 proposalId, address voter, bool approve);
    event ExhibitionScheduled(uint256 proposalId, string name, uint256 startDate, uint256 endDate);
    event ExhibitionCancelled(uint256 proposalId, uint256 exhibitionProposalId);
    event SecondaryMarketRoyaltySet(uint256 royaltyPercentage);
    event RoyaltyWithdrawn(address artist, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    constructor() ERC721("DAAC NFT", "DAAC") Ownable() {
        // Initialize contract - can add any initial setup here
    }

    // Modifier to check if the contract is paused
    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    // Modifier to ensure proposal exists
    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Proposal does not exist");
        _;
    }

    // Modifier to ensure exhibition proposal exists
    modifier exhibitionProposalExists(uint256 _exhibitionProposalId) {
        require(_exhibitionProposalId > 0 && _exhibitionProposalId <= _exhibitionProposalIds.current(), "Exhibition proposal does not exist");
        _;
    }

    // Modifier to ensure NFT exists
    modifier nftExists(uint256 _tokenId) {
        require(_exists(_tokenId), "NFT does not exist");
        _;
    }

    // --------------------------------------------------
    //                  Art Proposal Functions
    // --------------------------------------------------

    /// @notice Allows artists to submit art proposals.
    /// @param _title Title of the art proposal.
    /// @param _description Description of the art proposal.
    /// @param _ipfsHash IPFS hash of the artwork.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            upvotes: 0,
            downvotes: 0,
            status: CurationStatus.Pending,
            submissionTimestamp: block.timestamp
        });
        proposalCurationStatus[proposalId] = CurationStatus.Pending;
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Allows artists to update their art proposal metadata before curation.
    /// @param _proposalId ID of the art proposal to update.
    /// @param _title New title of the art proposal.
    /// @param _description New description of the art proposal.
    /// @param _ipfsHash New IPFS hash of the artwork.
    function setProposalMetadata(uint256 _proposalId, string memory _title, string memory _description, string memory _ipfsHash) external whenNotPaused proposalExists(_proposalId) {
        require(artProposals[_proposalId].artist == msg.sender, "Only artist can update proposal metadata");
        require(proposalCurationStatus[_proposalId] == CurationStatus.Pending, "Cannot update metadata after curation started");
        artProposals[_proposalId].title = _title;
        artProposals[_proposalId].description = _description;
        artProposals[_proposalId].ipfsHash = _ipfsHash;
        emit ProposalMetadataUpdated(_proposalId, _title);
    }

    /// @notice Retrieves details of a specific art proposal.
    /// @param _proposalId ID of the art proposal to retrieve.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Returns a list of all art proposals (for demonstration, consider pagination in real-world).
    /// @return Array of ArtProposal structs.
    function getAllArtProposals() external view returns (ArtProposal[] memory) {
        uint256 proposalCount = _proposalIds.current();
        ArtProposal[] memory allProposals = new ArtProposal[](proposalCount);
        for (uint256 i = 1; i <= proposalCount; i++) {
            allProposals[i - 1] = artProposals[i];
        }
        return allProposals;
    }

    // --------------------------------------------------
    //                  Curation & Voting Functions
    // --------------------------------------------------

    /// @notice Allows community members to vote on an art proposal.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _approve True for approve (upvote), false for reject (downvote).
    function voteForProposal(uint256 _proposalId, bool _approve) external whenNotPaused proposalExists(_proposalId) {
        require(!proposalVotes[_proposalId][msg.sender], "Already voted on this proposal");
        require(proposalCurationStatus[_proposalId] == CurationStatus.Pending, "Curation already completed");

        proposalVotes[_proposalId][msg.sender] = true; // Mark voter as voted

        if (_approve) {
            artProposals[_proposalId].upvotes++;
        } else {
            artProposals[_proposalId].downvotes++;
        }

        emit ProposalVoted(_proposalId, msg.sender, _approve);
        _updateCurationStatus(_proposalId); // Check if curation status needs to be updated
    }

    /// @dev Internal function to update curation status based on quorum.
    /// @param _proposalId ID of the proposal to update status for.
    function _updateCurationStatus(uint256 _proposalId) internal {
        uint256 totalVotes = artProposals[_proposalId].upvotes + artProposals[_proposalId].downvotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (artProposals[_proposalId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= curationQuorumPercentage) {
                proposalCurationStatus[_proposalId] = CurationStatus.Approved;
                emit ProposalCurationStatusUpdated(_proposalId, CurationStatus.Approved);
            } else if ((100 - approvalPercentage) > (100 - curationQuorumPercentage)) { // More than quorum against
                proposalCurationStatus[_proposalId] = CurationStatus.Rejected;
                emit ProposalCurationStatusUpdated(_proposalId, CurationStatus.Rejected);
            }
        }
    }

    /// @notice Returns the current curation status of a proposal.
    /// @param _proposalId ID of the proposal to check.
    /// @return CurationStatus enum value (Pending, Approved, Rejected).
    function getCurationStatus(uint256 _proposalId) external view proposalExists(_proposalId) returns (CurationStatus) {
        return proposalCurationStatus[_proposalId];
    }

    /// @notice Retrieves the vote counts for a specific proposal.
    /// @param _proposalId ID of the proposal to check.
    /// @return upvotes, downvotes - Vote counts.
    function getProposalVotes(uint256 _proposalId) external view proposalExists(_proposalId) returns (uint256 upvotes, uint256 downvotes) {
        return (artProposals[_proposalId].upvotes, artProposals[_proposalId].downvotes);
    }

    /// @notice Admin function to set the quorum percentage for proposal approval.
    /// @param _quorumPercentage New quorum percentage (e.g., 51 for 51%).
    function setCurationQuorum(uint256 _quorumPercentage) external onlyOwner {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100");
        curationQuorumPercentage = _quorumPercentage;
    }

    // --------------------------------------------------
    //                  NFT Minting & Distribution
    // --------------------------------------------------

    /// @notice Admin function to mint an NFT for an approved art proposal.
    /// @param _proposalId ID of the approved art proposal.
    function mintArtNFT(uint256 _proposalId) external onlyOwner whenNotPaused proposalExists(_proposalId) {
        require(proposalCurationStatus[_proposalId] == CurationStatus.Approved, "Proposal must be approved to mint NFT");
        require(nftArtists[_proposalId] == address(0), "NFT already minted for this proposal"); // Ensure mint only once

        _nftTokenIds.increment();
        uint256 tokenId = _nftTokenIds.current();

        _safeMint(artProposals[_proposalId].artist, tokenId);
        nftMetadataURIs[tokenId] = artProposals[_proposalId].ipfsHash; // Use proposal IPFS hash as NFT metadata URI (basic)
        nftArtists[tokenId] = artProposals[_proposalId].artist;

        emit ArtNFTMinted(tokenId, _proposalId, artProposals[_proposalId].artist);
    }

    /// @override
    function tokenURI(uint256 _tokenId) public view override nftExists(_tokenId) returns (string memory) {
        return nftMetadataURIs[_tokenId];
    }

    /// @notice Retrieves metadata URI for a minted NFT.
    /// @param _tokenId ID of the NFT.
    /// @return Metadata URI string.
    function getNFTMetadata(uint256 _tokenId) external view nftExists(_tokenId) returns (string memory) {
        return tokenURI(_tokenId);
    }

    /// @notice Allows NFT owners to transfer their NFTs.
    /// @param _tokenId ID of the NFT to transfer.
    /// @param _to Address to transfer the NFT to.
    function transferNFT(uint256 _tokenId, address _to) external whenNotPaused nftExists(_tokenId) {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /// @notice Returns the original artist of a specific NFT.
    /// @param _tokenId ID of the NFT.
    /// @return Artist address.
    function getNFTArtist(uint256 _tokenId) external view nftExists(_tokenId) returns (address) {
        return nftArtists[_tokenId];
    }


    // --------------------------------------------------
    //         Dynamic NFT Traits & Generative Art (Conceptual)
    // --------------------------------------------------

    // !!! Conceptual functions -  Dynamic NFTs and Generative Art integration are complex and require external services/oracles in a real-world scenario !!!

    /// @notice (Conceptual) Allows for dynamic evolution of NFT traits based on community votes or external factors.
    /// @param _tokenId ID of the NFT to evolve.
    /// @param _traitName Name of the trait to evolve.
    /// @param _traitValue New value of the trait.
    function evolveNFTTrait(uint256 _tokenId, string memory _traitName, string memory _traitValue) external whenNotPaused nftExists(_tokenId) {
        // !!! In a real implementation, this would likely involve:
        // 1. Governance proposal and voting to decide on trait evolution.
        // 2. Off-chain service to update NFT metadata based on _traitName and _traitValue.
        // 3. Event emission to signal the trait evolution.

        // For conceptual example, just emit an event:
        emit NFTTraitEvolved(_tokenId, _traitName, _traitValue);
        // In a more advanced setup, you might update an on-chain data structure that points to dynamic metadata.
    }

    /// @notice (Conceptual) Triggers a generative art update for an NFT, potentially changing its visual representation.
    /// @param _tokenId ID of the NFT to update.
    function triggerGenerativeArtUpdate(uint256 _tokenId) external whenNotPaused nftExists(_tokenId) {
        // !!! In a real implementation, this would require:
        // 1. Integration with a generative art engine (likely off-chain).
        // 2. Logic to determine how the generative art changes (random, based on NFT history, etc.).
        // 3. Off-chain service to regenerate the artwork and update NFT metadata (e.g., IPFS hash).
        // 4. Event emission to signal the update.

        // For conceptual example, just emit an event:
        emit GenerativeArtUpdateTriggered(_tokenId);
        // In a real application, you'd need a system to actually perform the generative art update and link it to the NFT.
    }


    // --------------------------------------------------
    //              DAO Governance & Exhibition
    // --------------------------------------------------

    /// @notice Allows community members to propose art exhibitions.
    /// @param _exhibitionName Name of the exhibition.
    /// @param _description Description of the exhibition.
    /// @param _startDate Unix timestamp for exhibition start date.
    /// @param _endDate Unix timestamp for exhibition end date.
    function submitExhibitionProposal(string memory _exhibitionName, string memory _description, uint256 _startDate, uint256 _endDate) external whenNotPaused {
        _exhibitionProposalIds.increment();
        uint256 proposalId = _exhibitionProposalIds.current();
        exhibitionProposals[proposalId] = ExhibitionProposal({
            proposalId: proposalId,
            proposer: msg.sender,
            name: _exhibitionName,
            description: _description,
            startDate: _startDate,
            endDate: _endDate,
            upvotes: 0,
            downvotes: 0,
            isApproved: false,
            isScheduled: false,
            submissionTimestamp: block.timestamp
        });
        emit ExhibitionProposalSubmitted(proposalId, msg.sender, _exhibitionName);
    }

    /// @notice Allows community members to vote on an exhibition proposal.
    /// @param _exhibitionProposalId ID of the exhibition proposal to vote on.
    /// @param _approve True for approve (upvote), false for reject (downvote).
    function voteForExhibition(uint256 _exhibitionProposalId, bool _approve) external whenNotPaused exhibitionProposalExists(_exhibitionProposalId) {
        require(!proposalVotes[_exhibitionProposalId][msg.sender], "Already voted on this exhibition proposal");
        require(!exhibitionProposals[_exhibitionProposalId].isApproved, "Exhibition proposal already decided");

        proposalVotes[_exhibitionProposalId][msg.sender] = true; // Mark voter as voted

        if (_approve) {
            exhibitionProposals[_exhibitionProposalId].upvotes++;
        } else {
            exhibitionProposals[_exhibitionProposalId].downvotes++;
        }

        emit ExhibitionProposalVoted(_exhibitionProposalId, msg.sender, _approve);
        _updateExhibitionApprovalStatus(_exhibitionProposalId); // Check if exhibition proposal needs to be approved
    }

    /// @dev Internal function to update exhibition approval status based on quorum.
    /// @param _exhibitionProposalId ID of the exhibition proposal to update status for.
    function _updateExhibitionApprovalStatus(uint256 _exhibitionProposalId) internal {
        uint256 totalVotes = exhibitionProposals[_exhibitionProposalId].upvotes + exhibitionProposals[_exhibitionProposalId].downvotes;
        if (totalVotes > 0) {
            uint256 approvalPercentage = (exhibitionProposals[_exhibitionProposalId].upvotes * 100) / totalVotes;
            if (approvalPercentage >= curationQuorumPercentage) {
                exhibitionProposals[_exhibitionProposalId].isApproved = true;
            }
        }
    }

    /// @notice Retrieves details of an exhibition proposal.
    /// @param _exhibitionProposalId ID of the exhibition proposal to retrieve.
    /// @return ExhibitionProposal struct containing proposal details.
    function getExhibitionProposal(uint256 _exhibitionProposalId) external view exhibitionProposalExists(_exhibitionProposalId) returns (ExhibitionProposal memory) {
        return exhibitionProposals[_exhibitionProposalId];
    }

    /// @notice Admin function to schedule an approved exhibition.
    /// @param _exhibitionProposalId ID of the approved exhibition proposal.
    function scheduleExhibition(uint256 _exhibitionProposalId) external onlyOwner whenNotPaused exhibitionProposalExists(_exhibitionProposalId) {
        require(exhibitionProposals[_exhibitionProposalId].isApproved, "Exhibition proposal must be approved first");
        require(!exhibitionProposals[_exhibitionProposalId].isScheduled, "Exhibition already scheduled");
        exhibitionProposals[_exhibitionProposalId].isScheduled = true;
        emit ExhibitionScheduled(_exhibitionProposalId, exhibitionProposals[_exhibitionProposalId].name, exhibitionProposals[_exhibitionProposalId].startDate, exhibitionProposals[_exhibitionProposalId].endDate);
    }

    /// @notice Admin function to cancel a scheduled exhibition.
    /// @param _exhibitionProposalId ID of the exhibition proposal to cancel.
    function cancelExhibition(uint256 _exhibitionProposalId) external onlyOwner whenNotPaused exhibitionProposalExists(_exhibitionProposalId) {
        require(exhibitionProposals[_exhibitionProposalId].isScheduled, "Exhibition is not scheduled");
        exhibitionProposals[_exhibitionProposalId].isScheduled = false;
        emit ExhibitionCancelled(_exhibitionProposalId, _exhibitionProposalId);
    }


    // --------------------------------------------------
    //              Royalties & Revenue Sharing
    // --------------------------------------------------

    /// @notice Admin function to set the secondary market royalty percentage for artists.
    /// @param _royaltyPercentage New royalty percentage (e.g., 5 for 5%).
    function setSecondaryMarketRoyalty(uint256 _royaltyPercentage) external onlyOwner {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100");
        secondaryMarketRoyaltyPercentage = _royaltyPercentage;
        emit SecondaryMarketRoyaltySet(_royaltyPercentage);
    }

    /// @notice (Conceptual) Function to handle secondary sales and distribute royalties.
    /// @dev In a real-world scenario, marketplace integration is needed to automatically trigger this on secondary sales.
    /// @param _tokenId ID of the NFT sold on the secondary market.
    /// @param _salePrice Sale price of the NFT.
    function handleSecondarySale(uint256 _tokenId, uint256 _salePrice) external payable whenNotPaused nftExists(_tokenId) {
        // !!! This is a simplified conceptual example. Real-world implementation depends on marketplace integration.
        // Assume this function is called by the marketplace contract upon a secondary sale.
        uint256 royaltyAmount = (_salePrice * secondaryMarketRoyaltyPercentage) / 100;
        artistRoyaltyBalances[nftArtists[_tokenId]] += royaltyAmount;

        // Transfer sale price (minus royalty) to the seller (current owner)
        uint256 sellerShare = _salePrice - royaltyAmount;
        payable(ownerOf(_tokenId)).transfer(sellerShare); // Assuming ownerOf() returns current owner

        // In a real system, you might need more robust access control and marketplace integration.
    }

    /// @notice Artists can withdraw their accumulated royalties.
    function withdrawArtistRoyalties() external whenNotPaused {
        uint256 royaltyBalance = artistRoyaltyBalances[msg.sender];
        require(royaltyBalance > 0, "No royalty balance to withdraw");

        artistRoyaltyBalances[msg.sender] = 0; // Reset balance after withdrawal
        payable(msg.sender).transfer(royaltyBalance);
        emit RoyaltyWithdrawn(msg.sender, royaltyBalance);
    }

    /// @notice View function to check an artist's royalty balance.
    /// @param _artist Address of the artist.
    /// @return Royalty balance of the artist.
    function getArtistRoyaltyBalance(address _artist) external view returns (uint256) {
        return artistRoyaltyBalances[_artist];
    }


    // --------------------------------------------------
    //                  Admin & Utility Functions
    // --------------------------------------------------

    /// @notice Admin function to change the contract admin (owner).
    /// @param _newAdmin Address of the new admin.
    function setAdmin(address _newAdmin) external onlyOwner {
        transferOwnership(_newAdmin);
    }

    /// @notice Admin function to pause core functionalities of the contract.
    function pauseContract() external onlyOwner {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to unpause the contract, resuming functionalities.
    function unpauseContract() external onlyOwner {
        contractPaused = false;
        emit ContractUnpaused();
    }

    // Optional: Fallback function for receiving ETH (if needed for royalties or other purposes)
    receive() external payable {}

    // Optional: Function to retrieve contract balance (for admin monitoring)
    function getContractBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}
```