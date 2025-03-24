```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to collaboratively create, manage, and monetize digital art.
 *
 * **Outline & Function Summary:**
 *
 * **Core Functionality:**
 * 1.  `joinCollective(string _artistName, string _artistStatement)`: Allows artists to join the collective, requires approval.
 * 2.  `leaveCollective()`: Allows artists to leave the collective.
 * 3.  `submitArtProposal(string _title, string _description, string _ipfsHash)`: Artists propose new art pieces for collective creation and ownership.
 * 4.  `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Members vote on art proposals.
 * 5.  `finalizeArtProposal(uint256 _proposalId)`: Finalizes an approved art proposal, mints NFT representing shared ownership.
 * 6.  `mintIndividualArtistNFT(uint256 _artPieceId)`:  Allows contributing artists to mint individual NFTs representing their contribution to a collective piece (optional, for provenance).
 * 7.  `listArtForSale(uint256 _artPieceId, uint256 _price)`:  Collective lists a jointly owned art piece for sale.
 * 8.  `buyArtPiece(uint256 _artPieceId)`:  Allows anyone to purchase a listed art piece, revenue shared among contributors.
 * 9.  `withdrawArtistShare()`:  Artists can withdraw their share of collective sales revenue.
 * 10. `donateToCollective()`:  Allows anyone to donate ETH to the collective's treasury.
 *
 * **Governance & Management:**
 * 11. `proposeGovernanceChange(string _description, bytes _data)`: Members propose changes to collective rules or contract parameters.
 * 12. `voteOnGovernanceChange(uint256 _proposalId, bool _vote)`: Members vote on governance change proposals.
 * 13. `executeGovernanceChange(uint256 _proposalId)`: Executes approved governance changes (limited scope for safety, potentially admin controlled).
 * 14. `setAdmin(address _newAdmin)`:  Admin function to change the contract administrator.
 * 15. `pauseContract()`:  Admin function to pause core functionalities in case of emergency.
 * 16. `unpauseContract()`: Admin function to resume contract functionalities.
 * 17. `setProposalVotingDuration(uint256 _durationInBlocks)`: Admin function to set the voting duration for proposals.
 * 18. `setQuorumPercentage(uint256 _percentage)`: Admin function to set the quorum percentage for proposals.
 * 19. `setCollectiveCommission(uint256 _percentage)`: Admin function to set the commission taken by the collective from sales (for treasury/maintenance).
 *
 * **Utility & Information:**
 * 20. `getArtProposalDetails(uint256 _proposalId)`:  View details of an art proposal.
 * 21. `getArtPieceDetails(uint256 _artPieceId)`: View details of an approved art piece.
 * 22. `getArtistDetails(address _artistAddress)`: View details of a collective member artist.
 * 23. `isArtist(address _address)`: Checks if an address is a member artist.
 * 24. `getTreasuryBalance()`:  View the collective's treasury balance.
 * 25. `getVersion()`: Returns the contract version (for future upgrades).
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract DecentralizedArtCollective is ERC721, Ownable, Pausable {
    using Counters for Counters.Counter;
    Counters.Counter private _artProposalIds;
    Counters.Counter private _artPieceIds;
    Counters.Counter private _governanceProposalIds;

    // Structs
    struct Artist {
        string name;
        string statement;
        uint256 revenueShare;
        bool isActive;
    }

    struct ArtProposal {
        uint256 proposalId;
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        mapping(address => bool) votes; // Track votes per address to prevent double voting
    }

    struct ArtPiece {
        uint256 artPieceId;
        string title;
        string description;
        string ipfsHash;
        address[] contributors; // Addresses of artists who contributed (for revenue sharing)
        bool forSale;
        uint256 salePrice;
        address currentOwner; // Initially the collective, then the buyer
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        bytes data; // Encoded data for governance actions
        address proposer;
        uint256 votingDeadline;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) votes; // Track votes per address
    }

    // State Variables
    mapping(address => Artist) public artists;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => ArtPiece) public artPieces;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    address[] public artistList; // List of artist addresses for iteration
    uint256 public artistCount;

    uint256 public proposalVotingDurationBlocks = 100; // Default voting duration (blocks)
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposals
    uint256 public collectiveCommissionPercentage = 5; // Commission on sales, goes to treasury

    // Events
    event ArtistJoined(address artistAddress, string artistName);
    event ArtistLeft(address artistAddress);
    event ArtProposalSubmitted(uint256 proposalId, string title, address proposer);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, uint256 artPieceId);
    event ArtPieceMinted(uint256 artPieceId, address[] contributors);
    event ArtPieceListedForSale(uint256 artPieceId, uint256 price);
    event ArtPiecePurchased(uint256 artPieceId, address buyer, uint256 price);
    event RevenueWithdrawn(address artistAddress, uint256 amount);
    event DonationReceived(address donor, uint256 amount);
    event GovernanceProposalSubmitted(uint256 proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);
    event ProposalVotingDurationChanged(uint256 newDuration);
    event QuorumPercentageChanged(uint256 newPercentage);
    event CollectiveCommissionChanged(uint256 newPercentage);

    // Modifiers
    modifier onlyArtist() {
        require(isArtist(msg.sender), "Only artists can perform this action.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action.");
        _;
    }

    modifier whenNotPausedContract() {
        require(!paused(), "Contract is paused.");
        _;
    }

    modifier whenPausedContract() {
        require(paused(), "Contract is not paused.");
        _;
    }

    modifier validProposal(uint256 _proposalId, mapping(uint256 => ArtProposal) storage proposalType) {
        require(_proposalId > 0 && _proposalId <= proposalType.current(), "Invalid proposal ID.");
        require(!proposalType[_proposalId].finalized && !proposalType[_proposalId].executed, "Proposal already finalized or executed.");
        require(block.number <= proposalType[_proposalId].votingDeadline, "Voting deadline has passed.");
        _;
    }

    // Constructor
    constructor() ERC721("Decentralized Art Collective", "DAC") {
        // Admin is the contract deployer (Ownable)
    }

    // ------------------------ Core Functionality ------------------------

    /// @notice Allows artists to join the collective, requires approval (currently auto-approved for simplicity, could be governance based).
    /// @param _artistName Name of the artist.
    /// @param _artistStatement Artist's statement or bio.
    function joinCollective(string memory _artistName, string memory _artistStatement) external whenNotPausedContract {
        require(!isArtist(msg.sender), "Already a member artist.");
        artists[msg.sender] = Artist({
            name: _artistName,
            statement: _artistStatement,
            revenueShare: 0, // Initial share, can be adjusted through governance or based on contribution
            isActive: true
        });
        artistList.push(msg.sender);
        artistCount++;
        emit ArtistJoined(msg.sender, _artistName);
    }

    /// @notice Allows artists to leave the collective.
    function leaveCollective() external onlyArtist whenNotPausedContract {
        require(artists[msg.sender].isActive, "Not an active member artist.");
        artists[msg.sender].isActive = false;
        // Remove from artistList (inefficient for large lists, consider optimization for production)
        for (uint256 i = 0; i < artistList.length; i++) {
            if (artistList[i] == msg.sender) {
                artistList[i] = artistList[artistList.length - 1];
                artistList.pop();
                break;
            }
        }
        artistCount--;
        emit ArtistLeft(msg.sender);
    }

    /// @notice Artists propose new art pieces for collective creation and ownership.
    /// @param _title Title of the art proposal.
    /// @param _description Description of the art proposal.
    /// @param _ipfsHash IPFS hash pointing to the art proposal details (image, multimedia, etc.).
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyArtist whenNotPausedContract {
        _artProposalIds.increment();
        uint256 proposalId = _artProposalIds.current();
        artProposals[proposalId] = ArtProposal({
            proposalId: proposalId,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            votingDeadline: block.number + proposalVotingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            votes: mapping(address => bool)()
        });
        emit ArtProposalSubmitted(proposalId, _title, msg.sender);
    }

    /// @notice Members vote on art proposals.
    /// @param _proposalId ID of the art proposal.
    /// @param _vote True for yes, false for no.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyArtist validProposal(_proposalId, artProposals) whenNotPausedContract {
        require(!artProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        artProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Finalizes an approved art proposal if quorum is met and yes votes are greater than no votes. Mints NFT representing shared ownership.
    /// @param _proposalId ID of the art proposal to finalize.
    function finalizeArtProposal(uint256 _proposalId) external whenNotPausedContract {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.finalized, "Proposal already finalized.");
        require(block.number > proposal.votingDeadline, "Voting is still active.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorum = (artistCount * quorumPercentage) / 100; // Quorum based on total artists

        require(totalVotes >= quorum, "Quorum not reached.");
        require(proposal.yesVotes > proposal.noVotes, "Proposal rejected by vote.");

        proposal.finalized = true;
        _mintArtPiece(proposal);
        emit ArtProposalFinalized(_proposalId, _artPieceIds.current());
    }

    /// @dev Internal function to mint an ArtPiece NFT.
    /// @param _proposal ArtProposal struct.
    function _mintArtPiece(ArtProposal memory _proposal) internal {
        _artPieceIds.increment();
        uint256 artPieceId = _artPieceIds.current();
        artPieces[artPieceId] = ArtPiece({
            artPieceId: artPieceId,
            title: _proposal.title,
            description: _proposal.description,
            ipfsHash: _proposal.ipfsHash,
            contributors: artistList, // For simplicity, all active artists are contributors initially, refine logic if needed
            forSale: false,
            salePrice: 0,
            currentOwner: address(this) // Collective initially owns the NFT
        });
        _mint(address(this), artPieceId); // Mint NFT to the contract address (collective)
        emit ArtPieceMinted(artPieceId, artistList);
    }

    /// @notice Allows contributing artists to mint individual NFTs representing their contribution to a collective piece (optional, for provenance).
    /// @param _artPieceId ID of the approved art piece.
    function mintIndividualArtistNFT(uint256 _artPieceId) external onlyArtist whenNotPausedContract {
        require(artPieces[_artPieceId].artPieceId == _artPieceId, "Invalid art piece ID.");
        require(artPieces[_artPieceId].currentOwner == address(this), "Individual NFTs can only be minted before collective sale.");
        // Check if artist is a contributor (for simplicity, all artists are contributors in this example)
        bool isContributor = false;
        for(uint i=0; i < artPieces[_artPieceId].contributors.length; i++) {
            if(artPieces[_artPieceId].contributors[i] == msg.sender) {
                isContributor = true;
                break;
            }
        }
        require(isContributor, "Artist is not a contributor to this art piece.");

        _mint(msg.sender, _artPieceId); // Mint individual NFT to the artist
        // Consider adding metadata to distinguish individual artist NFTs (e.g., "Artist Contribution - ArtPiece Title")
    }


    /// @notice Collective lists a jointly owned art piece for sale. Only callable by the collective (contract itself).
    /// @param _artPieceId ID of the art piece to list for sale.
    /// @param _price Sale price in wei.
    function listArtForSale(uint256 _artPieceId, uint256 _price) external onlyAdmin whenNotPausedContract { // Admin lists on behalf of collective for simplicity
        require(artPieces[_artPieceId].artPieceId == _artPieceId, "Invalid art piece ID.");
        require(artPieces[_artPieceId].currentOwner == address(this), "Art piece not owned by the collective.");
        artPieces[_artPieceId].forSale = true;
        artPieces[_artPieceId].salePrice = _price;
        emit ArtPieceListedForSale(_artPieceId, _price);
    }

    /// @notice Allows anyone to purchase a listed art piece, revenue shared among contributors.
    /// @param _artPieceId ID of the art piece to purchase.
    function buyArtPiece(uint256 _artPieceId) external payable whenNotPausedContract {
        require(artPieces[_artPieceId].artPieceId == _artPieceId, "Invalid art piece ID.");
        require(artPieces[_artPieceId].forSale, "Art piece is not for sale.");
        require(msg.value >= artPieces[_artPieceId].salePrice, "Insufficient funds sent.");

        uint256 salePrice = artPieces[_artPieceId].salePrice;
        uint256 collectiveCommission = (salePrice * collectiveCommissionPercentage) / 100;
        uint256 artistRevenue = salePrice - collectiveCommission;

        // Distribute revenue to contributors (simplified equal share for now, can be more complex based on contribution)
        uint256 sharePerArtist = artistRevenue / artistCount; // Equal share for all active artists
        for (uint256 i = 0; i < artistList.length; i++) {
            if (artists[artistList[i]].isActive) {
                artists[artistList[i]].revenueShare += sharePerArtist;
            }
        }

        // Transfer commission to collective treasury
        payable(address(this)).transfer(collectiveCommission);

        // Transfer NFT ownership to buyer
        _transfer(address(this), msg.sender, _artPieceId);
        artPieces[_artPieceId].currentOwner = msg.sender;
        artPieces[_artPieceId].forSale = false;
        artPieces[_artPieceId].salePrice = 0;

        emit ArtPiecePurchased(_artPieceId, msg.sender, salePrice);

        // Refund any extra ETH sent
        if (msg.value > salePrice) {
            payable(msg.sender).transfer(msg.value - salePrice);
        }
    }

    /// @notice Artists can withdraw their share of collective sales revenue.
    function withdrawArtistShare() external onlyArtist whenNotPausedContract {
        uint256 withdrawableAmount = artists[msg.sender].revenueShare;
        require(withdrawableAmount > 0, "No revenue share to withdraw.");
        artists[msg.sender].revenueShare = 0; // Reset share after withdrawal
        payable(msg.sender).transfer(withdrawableAmount);
        emit RevenueWithdrawn(msg.sender, withdrawableAmount);
    }

    /// @notice Allows anyone to donate ETH to the collective's treasury.
    function donateToCollective() external payable whenNotPausedContract {
        emit DonationReceived(msg.sender, msg.value);
    }

    // ------------------------ Governance & Management ------------------------

    /// @notice Members propose changes to collective rules or contract parameters.
    /// @param _description Description of the governance change proposal.
    /// @param _data Encoded data for the governance action (e.g., function signature and parameters).
    function proposeGovernanceChange(string memory _description, bytes memory _data) external onlyArtist whenNotPausedContract {
        _governanceProposalIds.increment();
        uint256 proposalId = _governanceProposalIds.current();
        governanceProposals[proposalId] = GovernanceProposal({
            proposalId: proposalId,
            description: _description,
            data: _data,
            proposer: msg.sender,
            votingDeadline: block.number + proposalVotingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            executed: false,
            votes: mapping(address => bool)()
        });
        emit GovernanceProposalSubmitted(proposalId, _description, msg.sender);
    }

    /// @notice Members vote on governance change proposals.
    /// @param _proposalId ID of the governance proposal.
    /// @param _vote True for yes, false for no.
    function voteOnGovernanceChange(uint256 _proposalId, bool _vote) external onlyArtist validProposal(_proposalId, governanceProposals) whenNotPausedContract {
        require(!governanceProposals[_proposalId].votes[msg.sender], "Already voted on this proposal.");
        governanceProposals[_proposalId].votes[msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes approved governance changes (limited scope for safety, potentially admin controlled).
    /// @param _proposalId ID of the governance proposal to execute.
    function executeGovernanceChange(uint256 _proposalId) external onlyAdmin whenNotPausedContract { // Admin executes after approval for safety, consider timelock
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.executed, "Governance proposal already executed.");
        require(block.number > proposal.votingDeadline, "Voting is still active.");

        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorum = (artistCount * quorumPercentage) / 100;

        require(totalVotes >= quorum, "Quorum not reached for governance proposal.");
        require(proposal.yesVotes > proposal.noVotes, "Governance proposal rejected by vote.");

        proposal.executed = true;
        // Limited execution scope for safety - in a real system, more robust governance execution is needed
        // Example: if data is encoded function call to set a parameter, execute it.
        // For now, just emit event indicating execution.
        emit GovernanceProposalExecuted(_proposalId);
        // In a real-world scenario, use delegatecall or other mechanisms to execute complex changes safely.
    }

    /// @notice Admin function to change the contract administrator.
    /// @param _newAdmin Address of the new admin.
    function setAdmin(address _newAdmin) external onlyOwner whenNotPausedContract {
        transferOwnership(_newAdmin);
    }

    /// @notice Admin function to pause core functionalities in case of emergency.
    function pauseContract() external onlyAdmin whenNotPausedContract {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to resume contract functionalities.
    function unpauseContract() external onlyAdmin whenPausedContract {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Admin function to set the voting duration for proposals.
    /// @param _durationInBlocks New voting duration in blocks.
    function setProposalVotingDuration(uint256 _durationInBlocks) external onlyAdmin whenNotPausedContract {
        proposalVotingDurationBlocks = _durationInBlocks;
        emit ProposalVotingDurationChanged(_durationInBlocks);
    }

    /// @notice Admin function to set the quorum percentage for proposals.
    /// @param _percentage New quorum percentage (0-100).
    function setQuorumPercentage(uint256 _percentage) external onlyAdmin whenNotPausedContract {
        require(_percentage <= 100, "Quorum percentage must be between 0 and 100.");
        quorumPercentage = _percentage;
        emit QuorumPercentageChanged(_percentage);
    }

    /// @notice Admin function to set the commission taken by the collective from sales (for treasury/maintenance).
    /// @param _percentage New commission percentage (0-100).
    function setCollectiveCommission(uint256 _percentage) external onlyAdmin whenNotPausedContract {
        require(_percentage <= 100, "Commission percentage must be between 0 and 100.");
        collectiveCommissionPercentage = _percentage;
        emit CollectiveCommissionChanged(_percentage);
    }

    // ------------------------ Utility & Information ------------------------

    /// @notice View details of an art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposal struct.
    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice View details of an approved art piece.
    /// @param _artPieceId ID of the art piece.
    /// @return ArtPiece struct.
    function getArtPieceDetails(uint256 _artPieceId) external view returns (ArtPiece memory) {
        return artPieces[_artPieceId];
    }

    /// @notice View details of a collective member artist.
    /// @param _artistAddress Address of the artist.
    /// @return Artist struct.
    function getArtistDetails(address _artistAddress) external view returns (Artist memory) {
        return artists[_artistAddress];
    }

    /// @notice Checks if an address is a member artist.
    /// @param _address Address to check.
    /// @return True if address is an artist, false otherwise.
    function isArtist(address _address) public view returns (bool) {
        return artists[_address].isActive;
    }

    /// @notice View the collective's treasury balance.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Returns the contract version (for future upgrades).
    /// @return Contract version string.
    function getVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    // Override _beforeTokenTransfer to ensure paused state is respected for NFT transfers
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override whenNotPausedContract {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Override supportsInterface to declare ERC721 interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Fallback function to receive ETH donations
    receive() external payable {
        emit DonationReceived(msg.sender, msg.value);
    }
}
```