```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * It enables artists to mint NFTs, community members to curate and vote on art,
 * manage a collective treasury, collaborate on art projects, and implement advanced features
 * like dynamic NFTs and generative art seed management.
 *
 * **Outline:**
 * 1.  **NFT Management:** Minting, burning, transferring, setting metadata, royalty management.
 * 2.  **Governance & Membership:** DAO membership, proposal system, voting mechanisms, role management.
 * 3.  **Art Curation & Exhibition:** Art submission, curation process, virtual exhibition functionality.
 * 4.  **Treasury Management:**  Collective treasury, funding proposals, artist grants, revenue distribution.
 * 5.  **Collaborative Art:**  Features for artists to collaborate on NFT projects.
 * 6.  **Dynamic NFTs:**  Functionality to update NFT metadata based on external factors or contract state.
 * 7.  **Generative Art Seed Management:**  Decentralized seed management for generative art NFTs.
 * 8.  **Reputation & Rewards:**  System to reward active community members and contributors.
 * 9.  **Utility & Helper Functions:**  Getter functions, admin functions, event emissions.
 *
 * **Function Summary:**
 * 1.  `mintArtNFT(string memory _title, string memory _description, string memory _ipfsHash, uint256 _royaltyPercentage, uint256 _generationSeed)`: Allows approved artists to mint new art NFTs with metadata, royalty, and optional generation seed.
 * 2.  `transferArtNFT(address _to, uint256 _tokenId)`: Allows NFT owners to transfer their NFTs.
 * 3.  `burnArtNFT(uint256 _tokenId)`: Allows the contract owner (DAO) to burn NFTs in specific cases (e.g., inappropriate content, with governance approval).
 * 4.  `setArtMetadata(uint256 _tokenId, string memory _ipfsHash)`: Allows the NFT owner to update the IPFS hash associated with an NFT, potentially for dynamic updates.
 * 5.  `setRoyaltyPercentage(uint256 _tokenId, uint256 _royaltyPercentage)`: Allows the original minter (artist) to adjust the royalty percentage on their NFT.
 * 6.  `addArtist(address _artistAddress)`: Allows the contract owner to add new artists to the approved artist list.
 * 7.  `removeArtist(address _artistAddress)`: Allows the contract owner to remove artists from the approved list.
 * 8.  `proposeNewMember(address _newMemberAddress)`: Allows members to propose new members to the DAAC.
 * 9.  `voteOnMembershipProposal(uint256 _proposalId, bool _vote)`: Allows existing members to vote on membership proposals.
 * 10. `submitArtForCuration(uint256 _tokenId)`: Allows NFT holders to submit their NFTs for curation in virtual exhibitions.
 * 11. `createCurationProposal(uint256 _tokenId)`: Allows members to propose NFTs for inclusion in a virtual exhibition.
 * 12. `voteOnCurationProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on curation proposals.
 * 13. `createTreasuryProposal(string memory _description, address payable _recipient, uint256 _amount)`: Allows members to create proposals for treasury spending.
 * 14. `voteOnTreasuryProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on treasury proposals.
 * 15. `executeProposal(uint256 _proposalId)`: Executes a proposal if it has reached the required quorum and majority.
 * 16. `depositToTreasury() payable`: Allows anyone to deposit ETH into the DAAC treasury.
 * 17. `withdrawFromTreasury(address payable _recipient, uint256 _amount)`: Allows the contract owner (DAO, after governance) to withdraw funds from the treasury.
 * 18. `collaborateOnArt(uint256 _tokenId, address _collaboratorAddress)`: Allows NFT owners to mark other artists as collaborators on their NFTs (metadata update).
 * 19. `triggerDynamicUpdate(uint256 _tokenId, string memory _newMetadataValue)`:  An example dynamic NFT function - updates NFT metadata based on an external trigger (can be extended for more complex logic).
 * 20. `setGenerativeSeed(uint256 _tokenId, uint256 _newSeed)`: Allows the NFT owner (or artist, depending on design) to update the generative seed associated with a generative art NFT.
 * 21. `getArtNFTMetadata(uint256 _tokenId)`:  Returns the metadata (IPFS hash) of an art NFT.
 * 22. `getRoyaltyInfo(uint256 _tokenId)`: Returns the royalty percentage for an NFT.
 * 23. `getApprovedArtists()`: Returns a list of approved artists.
 * 24. `getMemberCount()`: Returns the current number of DAAC members.
 * 25. `getTreasuryBalance()`: Returns the current balance of the DAAC treasury.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract DecentralizedArtCollective is ERC721, Ownable, IERC2981 {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _tokenIdCounter;

    // --- Data Structures ---
    struct ArtNFT {
        string title;
        string description;
        address artist;
        string ipfsHash;
        uint256 royaltyPercentage;
        uint256 generationSeed; // Optional seed for generative art
        address[] collaborators;
    }

    struct Proposal {
        enum ProposalType { MEMBERSHIP, CURATION, TREASURY }
        ProposalType proposalType;
        address proposer;
        uint256 timestamp;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        // Specific proposal data
        address targetAddress; // For membership proposals
        uint256 tokenId;       // For curation proposals
        address payable treasuryRecipient; // For treasury proposals
        uint256 treasuryAmount;        // For treasury proposals
    }

    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIdCounter;

    EnumerableSet.AddressSet private _approvedArtists;
    mapping(address => bool) public members;
    address[] public memberList; // Keep track of members in an array for easier iteration
    uint256 public membershipVoteQuorumPercentage = 50; // Percentage of members needed to vote for quorum
    uint256 public proposalVoteDuration = 7 days; // Duration for voting on proposals
    uint256 public curationVoteThresholdPercentage = 60; // Percentage to approve curation
    uint256 public treasuryVoteThresholdPercentage = 70; // Percentage to approve treasury spending

    // --- Events ---
    event ArtNFTMinted(uint256 tokenId, address artist, string title);
    event ArtNFTMetadataUpdated(uint256 tokenId, string ipfsHash);
    event ArtistAdded(address artistAddress);
    event ArtistRemoved(address artistAddress);
    event MembershipProposed(uint256 proposalId, address newMember);
    event ProposalVoted(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ArtCollaboratorAdded(uint256 tokenId, address collaborator);
    event DynamicNFTUpdated(uint256 tokenId, string newValue);
    event GenerativeSeedUpdated(uint256 tokenId, uint256 newSeed);

    // --- Modifiers ---
    modifier onlyArtist() {
        require(_approvedArtists.contains(_msgSender()), "Only approved artists can perform this action.");
        _;
    }

    modifier onlyMember() {
        require(members[_msgSender()], "Only DAAC members can perform this action.");
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId) {
        require(proposals[_proposalId].proposer == _msgSender(), "Only the proposal proposer can perform this action.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId < _proposalIdCounter.current(), "Invalid proposal ID.");
        require(!proposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp <= proposals[_proposalId].timestamp + proposalVoteDuration, "Voting period has ended.");
        _;
    }

    // --- Constructor ---
    constructor() ERC721("Decentralized Art Collective", "DAAC") {
        // Set the contract deployer as the initial owner and member
        _transferOwnership(_msgSender());
        _addMember(_msgSender());
    }

    // ------------------------ NFT Management Functions ------------------------

    /// @notice Allows approved artists to mint new art NFTs.
    /// @param _title Title of the art piece.
    /// @param _description Description of the art piece.
    /// @param _ipfsHash IPFS hash of the art's metadata.
    /// @param _royaltyPercentage Royalty percentage for secondary sales (0-100).
    /// @param _generationSeed Optional seed for generative art NFTs.
    function mintArtNFT(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _royaltyPercentage,
        uint256 _generationSeed
    ) external onlyArtist {
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_msgSender(), tokenId);

        artNFTs[tokenId] = ArtNFT({
            title: _title,
            description: _description,
            artist: _msgSender(),
            ipfsHash: _ipfsHash,
            royaltyPercentage: _royaltyPercentage,
            generationSeed: _generationSeed,
            collaborators: new address[](0)
        });

        _setTokenRoyalty(tokenId, _msgSender(), _royaltyPercentage);

        emit ArtNFTMinted(tokenId, _msgSender(), _title);
    }

    /// @notice Allows NFT owners to transfer their NFTs.
    /// @param _to Address to transfer the NFT to.
    /// @param _tokenId ID of the NFT to transfer.
    function transferArtNFT(address _to, uint256 _tokenId) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner.");
        safeTransferFrom(_msgSender(), _to, _tokenId);
    }

    /// @notice Allows the contract owner (DAO) to burn NFTs under specific circumstances (governance required in real scenario).
    /// @param _tokenId ID of the NFT to burn.
    function burnArtNFT(uint256 _tokenId) external onlyOwner { // In a real DAAC, this would be governance-controlled
        require(_exists(_tokenId), "NFT does not exist.");
        _burn(_tokenId);
    }

    /// @notice Allows the NFT owner to update the IPFS metadata hash of their NFT.
    /// @param _tokenId ID of the NFT to update.
    /// @param _ipfsHash New IPFS metadata hash.
    function setArtMetadata(uint256 _tokenId, string memory _ipfsHash) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner.");
        artNFTs[_tokenId].ipfsHash = _ipfsHash;
        emit ArtNFTMetadataUpdated(_tokenId, _ipfsHash);
    }

    /// @notice Allows the original artist (minter) to set the royalty percentage for their NFT.
    /// @param _tokenId ID of the NFT.
    /// @param _royaltyPercentage New royalty percentage (0-100).
    function setRoyaltyPercentage(uint256 _tokenId, uint256 _royaltyPercentage) external {
        require(artNFTs[_tokenId].artist == _msgSender(), "Only the original artist can set royalty.");
        require(_royaltyPercentage <= 100, "Royalty percentage must be between 0 and 100.");
        artNFTs[_tokenId].royaltyPercentage = _royaltyPercentage;
        _setTokenRoyalty(_tokenId, artNFTs[_tokenId].artist, _royaltyPercentage);
    }

    // ------------------------ Governance & Membership Functions ------------------------

    /// @notice Allows the contract owner to add a new artist to the approved artist list.
    /// @param _artistAddress Address of the artist to add.
    function addArtist(address _artistAddress) external onlyOwner {
        _approvedArtists.add(_artistAddress);
        emit ArtistAdded(_artistAddress);
    }

    /// @notice Allows the contract owner to remove an artist from the approved artist list.
    /// @param _artistAddress Address of the artist to remove.
    function removeArtist(address _artistAddress) external onlyOwner {
        _approvedArtists.remove(_artistAddress);
        emit ArtistRemoved(_artistAddress);
    }

    /// @notice Allows members to propose a new member to the DAAC.
    /// @param _newMemberAddress Address of the new member to propose.
    function proposeNewMember(address _newMemberAddress) external onlyMember {
        require(!members[_newMemberAddress], "Address is already a member.");
        uint256 proposalId = _createProposal(Proposal.ProposalType.MEMBERSHIP, "Propose new member", _newMemberAddress, 0);
        emit MembershipProposed(proposalId, _newMemberAddress);
    }

    /// @notice Allows members to vote on a membership proposal.
    /// @param _proposalId ID of the membership proposal.
    /// @param _vote True for approval, false for rejection.
    function voteOnMembershipProposal(uint256 _proposalId, bool _vote) external onlyMember validProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == Proposal.ProposalType.MEMBERSHIP, "Not a membership proposal.");
        _recordVote(_proposalId, _vote);
    }

    // ------------------------ Art Curation & Exhibition Functions ------------------------

    /// @notice Allows NFT holders to submit their NFTs for curation (example function - actual curation logic can be more complex).
    /// @param _tokenId ID of the NFT to submit for curation.
    function submitArtForCuration(uint256 _tokenId) external {
        require(_exists(_tokenId), "NFT does not exist.");
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner.");
        // In a real system, this might trigger a curation proposal automatically or add to a submission queue.
        // For this example, we just emit an event.
        // emit ArtSubmittedForCuration(_tokenId, _msgSender());
        // Placeholder - more complex curation process would be implemented here
    }

    /// @notice Allows members to create a proposal to curate an NFT for a virtual exhibition.
    /// @param _tokenId ID of the NFT to propose for curation.
    function createCurationProposal(uint256 _tokenId) external onlyMember {
        require(_exists(_tokenId), "NFT does not exist.");
        uint256 proposalId = _createProposal(Proposal.ProposalType.CURATION, "Propose art for curation", address(0), _tokenId);
    }

    /// @notice Allows members to vote on a curation proposal.
    /// @param _proposalId ID of the curation proposal.
    /// @param _vote True for approval, false for rejection.
    function voteOnCurationProposal(uint256 _proposalId, bool _vote) external onlyMember validProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == Proposal.ProposalType.CURATION, "Not a curation proposal.");
        _recordVote(_proposalId, _vote);
    }

    // ------------------------ Treasury Management Functions ------------------------

    /// @notice Allows members to create a proposal for treasury spending.
    /// @param _description Description of the treasury proposal.
    /// @param _recipient Address to receive the funds if the proposal passes.
    /// @param _amount Amount of ETH to spend (in wei).
    function createTreasuryProposal(string memory _description, address payable _recipient, uint256 _amount) external onlyMember {
        require(_amount > 0, "Amount must be greater than zero.");
        uint256 proposalId = _createProposal(Proposal.ProposalType.TREASURY, _description, address(0), 0);
        proposals[proposalId].treasuryRecipient = _recipient;
        proposals[proposalId].treasuryAmount = _amount;
    }

    /// @notice Allows members to vote on a treasury proposal.
    /// @param _proposalId ID of the treasury proposal.
    /// @param _vote True for approval, false for rejection.
    function voteOnTreasuryProposal(uint256 _proposalId, bool _vote) external onlyMember validProposal(_proposalId) {
        require(proposals[_proposalId].proposalType == Proposal.ProposalType.TREASURY, "Not a treasury proposal.");
        _recordVote(_proposalId, _vote);
    }

    /// @notice Executes a proposal if it has reached the required quorum and majority.
    /// @param _proposalId ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) external onlyMember validProposal(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalMembers = memberList.length;
        uint256 quorumNeeded = (totalMembers * membershipVoteQuorumPercentage) / 100;
        uint256 totalVotes = proposal.votesFor + proposal.votesAgainst;

        require(totalVotes >= quorumNeeded, "Proposal does not have quorum yet.");

        uint256 approvalPercentage;
        if (totalVotes > 0) {
            approvalPercentage = (proposal.votesFor * 100) / totalVotes;
        } else {
            approvalPercentage = 0; // Avoid division by zero if no votes yet (shouldn't happen with quorum check)
        }


        if (proposal.proposalType == Proposal.ProposalType.MEMBERSHIP) {
            if (approvalPercentage >= membershipVoteQuorumPercentage) { // Use membership quorum for membership proposals
                _addMember(proposal.targetAddress);
                proposal.executed = true;
                emit ProposalExecuted(_proposalId);
            }
        } else if (proposal.proposalType == Proposal.ProposalType.CURATION) {
            if (approvalPercentage >= curationVoteThresholdPercentage) {
                // Implement curation logic here - e.g., add to virtual exhibition list
                proposal.executed = true;
                emit ProposalExecuted(_proposalId);
            }
        } else if (proposal.proposalType == Proposal.ProposalType.TREASURY) {
            if (approvalPercentage >= treasuryVoteThresholdPercentage) {
                require(address(this).balance >= proposal.treasuryAmount, "Contract treasury balance is insufficient.");
                (bool success, ) = proposal.treasuryRecipient.call{value: proposal.treasuryAmount}("");
                require(success, "Treasury transfer failed.");
                proposal.executed = true;
                emit ProposalExecuted(_proposalId);
                emit TreasuryWithdrawal(proposal.treasuryRecipient, proposal.treasuryAmount);
            }
        } else {
            revert("Unknown proposal type.");
        }
    }

    /// @notice Allows anyone to deposit ETH into the DAAC treasury.
    function depositToTreasury() external payable {
        emit TreasuryDeposit(_msgSender(), msg.value);
    }

    /// @notice Allows the contract owner (DAO, after governance in a real scenario) to withdraw funds from the treasury.
    /// @param _recipient Address to receive the withdrawn funds.
    /// @param _amount Amount of ETH to withdraw (in wei).
    function withdrawFromTreasury(address payable _recipient, uint256 _amount) external onlyOwner { // In a real DAAC, this would be governance-controlled
        require(address(this).balance >= _amount, "Contract treasury balance is insufficient.");
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Treasury transfer failed.");
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    // ------------------------ Collaborative Art Functions ------------------------

    /// @notice Allows NFT owners to add collaborators to their art NFTs.
    /// @param _tokenId ID of the NFT.
    /// @param _collaboratorAddress Address of the collaborator to add.
    function collaborateOnArt(uint256 _tokenId, address _collaboratorAddress) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner.");
        artNFTs[_tokenId].collaborators.push(_collaboratorAddress);
        emit ArtCollaboratorAdded(_tokenId, _collaboratorAddress);
    }

    // ------------------------ Dynamic NFT Functions ------------------------

    /// @notice Example function to trigger a dynamic update of NFT metadata (can be expanded for more complex logic).
    /// @param _tokenId ID of the NFT to update.
    /// @param _newMetadataValue New metadata value (e.g., a status update, an image URL change).
    function triggerDynamicUpdate(uint256 _tokenId, string memory _newMetadataValue) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner.");
        // Example: Update a part of the IPFS metadata or point to a new metadata URL
        artNFTs[_tokenId].ipfsHash = _newMetadataValue; // Simplistic example - in reality, you might update a specific field in the JSON metadata
        emit DynamicNFTUpdated(_tokenId, _newMetadataValue);
        emit ArtNFTMetadataUpdated(_tokenId, _newMetadataValue); // Inform metadata has been updated
    }

    // ------------------------ Generative Art Seed Management Functions ------------------------

    /// @notice Allows the NFT owner (or artist, depending on design) to update the generative seed of a generative art NFT.
    /// @param _tokenId ID of the generative art NFT.
    /// @param _newSeed New generative seed value.
    function setGenerativeSeed(uint256 _tokenId, uint256 _newSeed) external {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "Not approved or owner.");
        artNFTs[_tokenId].generationSeed = _newSeed;
        emit GenerativeSeedUpdated(_tokenId, _newSeed);
    }

    // ------------------------ Utility & Getter Functions ------------------------

    /// @notice Returns the metadata (IPFS hash) of an art NFT.
    /// @param _tokenId ID of the NFT.
    /// @return IPFS hash of the NFT metadata.
    function getArtNFTMetadata(uint256 _tokenId) external view returns (string memory) {
        require(_exists(_tokenId), "NFT does not exist.");
        return artNFTs[_tokenId].ipfsHash;
    }

    /// @notice Returns the royalty information for an NFT (using IERC2981).
    /// @param _tokenId ID of the NFT.
    /// @param _salePrice The sale price of the NFT.
    /// @return receiver Address of the royalty receiver.
    /// @return royaltyAmount Royalty amount in wei.
    function getRoyaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "NFT does not exist.");
        receiver = artNFTs[_tokenId].artist;
        royaltyAmount = (_salePrice * artNFTs[_tokenId].royaltyPercentage) / 100;
    }

    /// @notice Returns the royalty percentage set for an NFT.
    /// @param _tokenId ID of the NFT.
    /// @return Royalty percentage (0-100).
    function getNFTRoyaltyPercentage(uint256 _tokenId) external view returns (uint256) {
        require(_exists(_tokenId), "NFT does not exist.");
        return artNFTs[_tokenId].royaltyPercentage;
    }

    /// @notice Returns a list of approved artists.
    /// @return Array of approved artist addresses.
    function getApprovedArtists() external view returns (address[] memory) {
        uint256 count = _approvedArtists.length();
        address[] memory artists = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            artists[i] = _approvedArtists.at(i);
        }
        return artists;
    }

    /// @notice Returns the current number of DAAC members.
    /// @return Number of members.
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }

    /// @notice Returns the current balance of the DAAC treasury.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- Internal Helper Functions ---

    function _addMember(address _memberAddress) internal {
        require(!members[_memberAddress], "Address is already a member.");
        members[_memberAddress] = true;
        memberList.push(_memberAddress);
    }

    function _createProposal(Proposal.ProposalType _proposalType, string memory _description, address _targetAddress, uint256 _tokenId) internal onlyMember returns (uint256) {
        uint256 proposalId = _proposalIdCounter.current();
        _proposalIdCounter.increment();
        proposals[proposalId] = Proposal({
            proposalType: _proposalType,
            proposer: _msgSender(),
            timestamp: block.timestamp,
            description: _description,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            targetAddress: _targetAddress,
            tokenId: _tokenId,
            treasuryRecipient: payable(address(0)), // Default values for treasury proposals, can be updated later
            treasuryAmount: 0
        });
        return proposalId;
    }

    function _recordVote(uint256 _proposalId, bool _vote) internal onlyMember validProposal(_proposalId) {
        // Prevent double voting (simple check - can be made more robust if needed)
        require(proposals[_proposalId].proposer != _msgSender(), "Proposer cannot vote."); // Proposer shouldn't vote in this simple example
        // In a real DAO, you'd track individual votes to prevent double voting from the same address.
        if (_vote) {
            proposals[_proposalId].votesFor++;
        } else {
            proposals[_proposalId].votesAgainst++;
        }
        emit ProposalVoted(_proposalId, _msgSender(), _vote);
    }

    function _setTokenRoyalty(uint256 _tokenId, address _artist, uint256 _royaltyPercentage) internal {
        _setDefaultRoyalty(address(this), 0); // Clear default royalty (if any)
        _setTokenRoyalty(_tokenId, _artist, _royaltyPercentage);
    }

    // The following functions are overrides required by Solidity when implementing ERC721 and IERC2981
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC2981) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}
```