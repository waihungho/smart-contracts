```solidity
/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Your Name/Organization (Replace with your info)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, enabling artists to submit artwork,
 *      the community to vote on submissions, and the collective to manage a treasury, mint NFTs of approved art,
 *      and govern the platform's parameters through decentralized voting.
 *
 * **Outline and Function Summary:**
 *
 * **DAO Governance Functions:**
 * 1. `proposeNewArtwork(string _title, string _description, string _ipfsHash)`: Allows members to propose new artwork submissions.
 * 2. `voteOnArtworkProposal(uint256 _proposalId, bool _vote)`: Allows members to vote on pending artwork proposals.
 * 3. `executeArtworkProposal(uint256 _proposalId)`: Executes an artwork proposal if it passes the voting threshold, minting an NFT for the artwork.
 * 4. `depositToTreasury()`: Allows anyone to deposit ETH into the DAO treasury.
 * 5. `proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string _reason)`: Allows members to propose withdrawals from the DAO treasury.
 * 6. `voteOnTreasuryWithdrawal(uint256 _withdrawalProposalId, bool _vote)`: Allows members to vote on treasury withdrawal proposals.
 * 7. `executeTreasuryWithdrawal(uint256 _withdrawalProposalId)`: Executes a treasury withdrawal proposal if it passes, sending ETH to the recipient.
 * 8. `setVotingPeriod(uint256 _newVotingPeriod)`: Allows the DAO to change the voting period for proposals (governed).
 * 9. `setQuorumPercentage(uint256 _newQuorumPercentage)`: Allows the DAO to change the quorum percentage for proposals (governed).
 * 10. `addMember(address _newMember)`: Allows the DAO to add new members to the collective (governed).
 * 11. `removeMember(address _memberToRemove)`: Allows the DAO to remove members from the collective (governed).
 *
 * **Art Management Functions:**
 * 12. `getArtworkProposalDetails(uint256 _proposalId)`: Retrieves details of a specific artwork proposal.
 * 13. `getArtworkDetails(uint256 _artworkId)`: Retrieves details of a minted artwork (NFT).
 * 14. `getPendingProposalCount()`: Returns the number of pending artwork proposals.
 * 15. `getApprovedArtworkCount()`: Returns the number of approved and minted artworks.
 * 16. `getAllPendingProposalIds()`: Returns an array of IDs of all pending artwork proposals.
 * 17. `getAllApprovedArtworkIds()`: Returns an array of IDs of all approved artwork IDs.
 *
 * **NFT Functionality & Advanced Features:**
 * 18. `purchaseArtworkNFT(uint256 _artworkId)`: Allows users to purchase artwork NFTs from the collective (if enabled, could be for treasury funding).
 * 19. `transferArtworkNFT(address _to, uint256 _artworkId)`: Allows owners to transfer artwork NFTs.
 * 20. `burnArtworkNFT(uint256 _artworkId)`: Allows the DAO to burn a specific artwork NFT (governed - e.g., for inappropriate content).
 * 21. `setArtworkMetadataURI(uint256 _artworkId, string _newMetadataURI)`: Allows the DAO to update the metadata URI of an artwork NFT (governed - e.g., to fix errors).
 * 22. `getNFTContractAddress()`: Returns the address of the deployed NFT contract.
 * 23. `getTreasuryBalance()`: Returns the current balance of the DAO treasury.
 *
 * **Events:**
 * - `ArtworkProposalCreated(uint256 proposalId, address proposer, string title)`: Emitted when a new artwork proposal is created.
 * - `ArtworkProposalVoted(uint256 proposalId, address voter, bool vote)`: Emitted when a member votes on an artwork proposal.
 * - `ArtworkProposalExecuted(uint256 proposalId, uint256 artworkId)`: Emitted when an artwork proposal is executed and an NFT is minted.
 * - `TreasuryDeposit(address depositor, uint256 amount)`: Emitted when ETH is deposited into the treasury.
 * - `TreasuryWithdrawalProposed(uint256 withdrawalProposalId, address proposer, address recipient, uint256 amount, string reason)`: Emitted when a treasury withdrawal proposal is created.
 * - `TreasuryWithdrawalVoted(uint256 withdrawalProposalId, address voter, bool vote)`: Emitted when a member votes on a treasury withdrawal proposal.
 * - `TreasuryWithdrawalExecuted(uint256 withdrawalProposalId, address recipient, uint256 amount)`: Emitted when a treasury withdrawal proposal is executed.
 * - `VotingPeriodUpdated(uint256 newVotingPeriod)`: Emitted when the voting period is updated.
 * - `QuorumPercentageUpdated(uint256 newQuorumPercentage)`: Emitted when the quorum percentage is updated.
 * - `MemberAdded(address newMember)`: Emitted when a new member is added to the collective.
 * - `MemberRemoved(address removedMember)`: Emitted when a member is removed from the collective.
 * - `ArtworkNFTPurchased(uint256 artworkId, address purchaser, uint256 price)`: Emitted when an artwork NFT is purchased.
 * - `ArtworkNFTTransferred(uint256 artworkId, address from, address to)`: Emitted when an artwork NFT is transferred.
 * - `ArtworkNFTBurned(uint256 artworkId)`: Emitted when an artwork NFT is burned.
 * - `ArtworkMetadataURIUpdated(uint256 artworkId, string newMetadataURI)`: Emitted when the metadata URI of an artwork NFT is updated.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _artworkProposalIds;
    Counters.Counter private _artworkIds;
    Counters.Counter private _withdrawalProposalIds;

    uint256 public votingPeriod = 7 days; // Default voting period
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)
    address[] public members;

    struct ArtworkProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 executionTimestamp;
        mapping(address => bool) voters; // Track who voted to prevent double voting
    }
    mapping(uint256 => ArtworkProposal) public artworkProposals;

    struct Artwork {
        uint256 id;
        string title;
        string description;
        string ipfsHash;
        string metadataURI;
        address artist; // Optional: Could track original artist if submitted by someone else
    }
    mapping(uint256 => Artwork) public artworks;

    struct TreasuryWithdrawalProposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        uint256 executionTimestamp;
        mapping(address => bool) voters; // Track who voted to prevent double voting
    }
    mapping(uint256 => TreasuryWithdrawalProposal) public withdrawalProposals;


    event ArtworkProposalCreated(uint256 proposalId, address proposer, string title);
    event ArtworkProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtworkProposalExecuted(uint256 proposalId, uint256 artworkId);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasuryWithdrawalProposed(uint256 withdrawalProposalId, address proposer, address recipient, uint256 amount, string reason);
    event TreasuryWithdrawalVoted(uint256 withdrawalProposalId, address voter, bool vote);
    event TreasuryWithdrawalExecuted(uint256 withdrawalProposalId, address recipient, uint256 amount);
    event VotingPeriodUpdated(uint256 newVotingPeriod);
    event QuorumPercentageUpdated(uint256 newQuorumPercentage);
    event MemberAdded(address newMember);
    event MemberRemoved(address removedMember);
    event ArtworkNFTPurchased(uint256 artworkId, address purchaser, uint256 price);
    event ArtworkNFTTransferred(uint256 artworkId, address from, address to);
    event ArtworkNFTBurned(uint256 artworkId);
    event ArtworkMetadataURIUpdated(uint256 artworkId, string newMetadataURI);


    modifier onlyMember() {
        bool isMember = false;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _msgSender()) {
                isMember = true;
                break;
            }
        }
        require(isMember, "Only members can perform this action.");
        _;
    }

    modifier onlyDAO() {
        require(_msgSender() == address(this), "Only the DAO contract can perform this action.");
        _;
    }

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        members.push(msg.sender); // Initial member is contract deployer
    }

    // -------- DAO Governance Functions --------

    /// @notice Proposes a new artwork submission to the collective.
    /// @param _title The title of the artwork.
    /// @param _description A description of the artwork.
    /// @param _ipfsHash The IPFS hash of the artwork's media.
    function proposeNewArtwork(string memory _title, string memory _description, string memory _ipfsHash) public onlyMember {
        _artworkProposalIds.increment();
        uint256 proposalId = _artworkProposalIds.current();
        artworkProposals[proposalId] = ArtworkProposal({
            id: proposalId,
            proposer: _msgSender(),
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            executionTimestamp: 0,
            voters: mapping(address => bool)()
        });
        emit ArtworkProposalCreated(proposalId, _msgSender(), _title);
    }

    /// @notice Allows members to vote on a pending artwork proposal.
    /// @param _proposalId The ID of the artwork proposal to vote on.
    /// @param _vote `true` to vote for, `false` to vote against.
    function voteOnArtworkProposal(uint256 _proposalId, bool _vote) public onlyMember {
        require(artworkProposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(!artworkProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp <= artworkProposals[_proposalId].executionTimestamp + votingPeriod || artworkProposals[_proposalId].executionTimestamp == 0, "Voting period ended."); // Allow voting if timestamp is 0 initially
        require(!artworkProposals[_proposalId].voters[_msgSender()], "Already voted on this proposal.");

        artworkProposals[_proposalId].voters[_msgSender()] = true;
        if (_vote) {
            artworkProposals[_proposalId].votesFor++;
        } else {
            artworkProposals[_proposalId].votesAgainst++;
        }
        emit ArtworkProposalVoted(_proposalId, _msgSender(), _vote);
    }

    /// @notice Executes an artwork proposal if it passes the voting threshold. Mints an NFT for the artwork.
    /// @param _proposalId The ID of the artwork proposal to execute.
    function executeArtworkProposal(uint256 _proposalId) public onlyMember {
        require(artworkProposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        require(!artworkProposals[_proposalId].executed, "Proposal already executed.");
        require(block.timestamp > artworkProposals[_proposalId].executionTimestamp + votingPeriod && artworkProposals[_proposalId].executionTimestamp != 0, "Voting period not ended yet."); //Voting period must be ended
        uint256 totalVotes = artworkProposals[_proposalId].votesFor + artworkProposals[_proposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast on this proposal."); // Ensure votes were cast to avoid division by zero
        uint256 quorum = (members.length * quorumPercentage) / 100; // Quorum based on member count
        require(totalVotes >= quorum, "Quorum not reached.");

        uint256 percentageFor = (artworkProposals[_proposalId].votesFor * 100) / totalVotes;
        require(percentageFor > 50, "Proposal did not pass voting threshold."); // Simple majority for now, could be configurable

        _artworkIds.increment();
        uint256 artworkId = _artworkIds.current();
        artworks[artworkId] = Artwork({
            id: artworkId,
            title: artworkProposals[_proposalId].title,
            description: artworkProposals[_proposalId].description,
            ipfsHash: artworkProposals[_proposalId].ipfsHash,
            metadataURI: "", // Initially empty, can be set later or derived from IPFS
            artist: artworkProposals[_proposalId].proposer // Assuming proposer is the artist, can be adjusted
        });
        _mint(address(this), artworkId); // Mint NFT to the contract itself, DAO owns it initially. Could be minted to artist or treasury directly.
        artworkProposals[_proposalId].executed = true;
        artworkProposals[_proposalId].executionTimestamp = block.timestamp;
        emit ArtworkProposalExecuted(_proposalId, artworkId);
    }


    /// @notice Allows anyone to deposit ETH into the DAO treasury.
    function depositToTreasury() public payable {
        emit TreasuryDeposit(_msgSender(), msg.value);
    }

    /// @notice Proposes a withdrawal from the DAO treasury.
    /// @param _recipient The address to receive the withdrawn ETH.
    /// @param _amount The amount of ETH to withdraw (in wei).
    /// @param _reason The reason for the withdrawal.
    function proposeTreasuryWithdrawal(address _recipient, uint256 _amount, string memory _reason) public onlyMember {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(address(this).balance >= _amount, "DAO treasury balance is insufficient.");

        _withdrawalProposalIds.increment();
        uint256 withdrawalProposalId = _withdrawalProposalIds.current();
        withdrawalProposals[withdrawalProposalId] = TreasuryWithdrawalProposal({
            id: withdrawalProposalId,
            proposer: _msgSender(),
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            votesFor: 0,
            votesAgainst: 0,
            executed: false,
            executionTimestamp: 0,
            voters: mapping(address => bool)()
        });
        emit TreasuryWithdrawalProposed(withdrawalProposalId, _msgSender(), _recipient, _amount, _reason);
    }

    /// @notice Allows members to vote on a treasury withdrawal proposal.
    /// @param _withdrawalProposalId The ID of the treasury withdrawal proposal to vote on.
    /// @param _vote `true` to vote for, `false` to vote against.
    function voteOnTreasuryWithdrawal(uint256 _withdrawalProposalId, bool _vote) public onlyMember {
        require(withdrawalProposals[_withdrawalProposalId].id == _withdrawalProposalId, "Withdrawal proposal does not exist.");
        require(!withdrawalProposals[_withdrawalProposalId].executed, "Withdrawal proposal already executed.");
        require(block.timestamp <= withdrawalProposals[_withdrawalProposalId].executionTimestamp + votingPeriod || withdrawalProposals[_withdrawalProposalId].executionTimestamp == 0, "Voting period ended.");
        require(!withdrawalProposals[_withdrawalProposalId].voters[_msgSender()], "Already voted on this proposal.");

        withdrawalProposals[_withdrawalProposalId].voters[_msgSender()] = true;
        if (_vote) {
            withdrawalProposals[_withdrawalProposalId].votesFor++;
        } else {
            withdrawalProposals[_withdrawalProposalId].votesAgainst++;
        }
        emit TreasuryWithdrawalVoted(_withdrawalProposalId, _msgSender(), _vote);
    }

    /// @notice Executes a treasury withdrawal proposal if it passes the voting threshold.
    /// @param _withdrawalProposalId The ID of the treasury withdrawal proposal to execute.
    function executeTreasuryWithdrawal(uint256 _withdrawalProposalId) public onlyMember {
        require(withdrawalProposals[_withdrawalProposalId].id == _withdrawalProposalId, "Withdrawal proposal does not exist.");
        require(!withdrawalProposals[_withdrawalProposalId].executed, "Withdrawal proposal already executed.");
        require(block.timestamp > withdrawalProposals[_withdrawalProposalId].executionTimestamp + votingPeriod && withdrawalProposals[_withdrawalProposalId].executionTimestamp != 0, "Voting period not ended yet.");
        uint256 totalVotes = withdrawalProposals[_withdrawalProposalId].votesFor + withdrawalProposals[_withdrawalProposalId].votesAgainst;
        require(totalVotes > 0, "No votes cast on this withdrawal proposal.");
        uint256 quorum = (members.length * quorumPercentage) / 100;
        require(totalVotes >= quorum, "Quorum not reached for withdrawal proposal.");

        uint256 percentageFor = (withdrawalProposals[_withdrawalProposalId].votesFor * 100) / totalVotes;
        require(percentageFor > 50, "Withdrawal proposal did not pass voting threshold.");

        uint256 amount = withdrawalProposals[_withdrawalProposalId].amount;
        address recipient = withdrawalProposals[_withdrawalProposalId].recipient;
        require(address(this).balance >= amount, "Insufficient DAO treasury balance for withdrawal.");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Treasury withdrawal failed.");

        withdrawalProposals[_withdrawalProposalId].executed = true;
        withdrawalProposals[_withdrawalProposalId].executionTimestamp = block.timestamp;
        emit TreasuryWithdrawalExecuted(_withdrawalProposalId, recipient, amount);
    }

    /// @notice Allows the DAO to change the voting period for proposals (governed).
    /// @param _newVotingPeriod The new voting period in seconds.
    function setVotingPeriod(uint256 _newVotingPeriod) public onlyMember {
        // Governance logic to propose and vote on parameter changes would be needed in a real DAO.
        // For simplicity, allowing any member to change it for now, but this should be governed.
        votingPeriod = _newVotingPeriod;
        emit VotingPeriodUpdated(_newVotingPeriod);
    }

    /// @notice Allows the DAO to change the quorum percentage for proposals (governed).
    /// @param _newQuorumPercentage The new quorum percentage (e.g., 50 for 50%).
    function setQuorumPercentage(uint256 _newQuorumPercentage) public onlyMember {
        // Governance logic needed, similar to setVotingPeriod.
        quorumPercentage = _newQuorumPercentage;
        emit QuorumPercentageUpdated(_newQuorumPercentage);
    }

    /// @notice Allows the DAO to add a new member to the collective (governed).
    /// @param _newMember The address of the new member to add.
    function addMember(address _newMember) public onlyMember {
        require(_newMember != address(0), "Invalid member address.");
        // Governance logic to propose and vote on adding members would be needed.
        // For simplicity, allowing any member to add for now, but this should be governed.
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _newMember) {
                revert("Member already exists.");
            }
        }
        members.push(_newMember);
        emit MemberAdded(_newMember);
    }

    /// @notice Allows the DAO to remove a member from the collective (governed).
    /// @param _memberToRemove The address of the member to remove.
    function removeMember(address _memberToRemove) public onlyMember {
        require(_memberToRemove != address(0), "Invalid member address.");
        // Governance logic to propose and vote on removing members would be needed.
        // For simplicity, allowing any member to remove for now, but should be governed.
        bool memberRemoved = false;
        for (uint i = 0; i < members.length; i++) {
            if (members[i] == _memberToRemove) {
                members[i] = members[members.length - 1]; // Replace with last member
                members.pop(); // Remove last member (effectively removing the target member)
                memberRemoved = true;
                break;
            }
        }
        require(memberRemoved, "Member not found.");
        emit MemberRemoved(_memberToRemove);
    }


    // -------- Art Management Functions --------

    /// @notice Retrieves details of a specific artwork proposal.
    /// @param _proposalId The ID of the artwork proposal.
    /// @return ArtworkProposal struct containing proposal details.
    function getArtworkProposalDetails(uint256 _proposalId) public view returns (ArtworkProposal memory) {
        require(artworkProposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        return artworkProposals[_proposalId];
    }

    /// @notice Retrieves details of a minted artwork (NFT).
    /// @param _artworkId The ID of the artwork.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) public view returns (Artwork memory) {
        require(artworks[_artworkId].id == _artworkId, "Artwork does not exist.");
        return artworks[_artworkId];
    }

    /// @notice Returns the number of pending artwork proposals.
    /// @return The count of pending artwork proposals.
    function getPendingProposalCount() public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i <= _artworkProposalIds.current(); i++) {
            if (!artworkProposals[i].executed) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns the number of approved and minted artworks.
    /// @return The count of approved artworks.
    function getApprovedArtworkCount() public view returns (uint256) {
        return _artworkIds.current();
    }

    /// @notice Returns an array of IDs of all pending artwork proposals.
    /// @return An array of proposal IDs.
    function getAllPendingProposalIds() public view returns (uint256[] memory) {
        uint256 pendingCount = getPendingProposalCount();
        uint256[] memory pendingIds = new uint256[](pendingCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= _artworkProposalIds.current(); i++) {
            if (!artworkProposals[i].executed) {
                pendingIds[index] = i;
                index++;
            }
        }
        return pendingIds;
    }

    /// @notice Returns an array of IDs of all approved artwork IDs.
    /// @return An array of artwork IDs.
    function getAllApprovedArtworkIds() public view returns (uint256[] memory) {
        uint256 approvedCount = getApprovedArtworkCount();
        uint256[] memory approvedIds = new uint256[](approvedCount);
        for (uint256 i = 1; i <= approvedCount; i++) {
            approvedIds[i - 1] = i;
        }
        return approvedIds;
    }


    // -------- NFT Functionality & Advanced Features --------

    /// @notice Allows users to purchase artwork NFTs from the collective (if enabled, could be for treasury funding).
    /// @param _artworkId The ID of the artwork NFT to purchase.
    function purchaseArtworkNFT(uint256 _artworkId) public payable {
        require(artworks[_artworkId].id == _artworkId, "Artwork does not exist.");
        require(ownerOf(_artworkId) == address(this), "Artwork is not available for purchase from DAO."); // Ensure DAO owns it

        uint256 purchasePrice = 0.05 ether; // Example price, could be dynamic/configurable.
        require(msg.value >= purchasePrice, "Insufficient purchase price.");

        _transfer(address(this), _msgSender(), _artworkId); // Transfer NFT to purchaser
        payable(address(this)).transfer(msg.value); // Send purchase price to DAO treasury (or royalty distribution logic)

        emit ArtworkNFTPurchased(_artworkId, _msgSender(), purchasePrice);
    }

    /// @notice Allows owners to transfer artwork NFTs. (Standard ERC721 transfer)
    /// @param _to The address to transfer the NFT to.
    /// @param _artworkId The ID of the artwork NFT to transfer.
    function transferArtworkNFT(address _to, uint256 _artworkId) public {
        safeTransferFrom(_msgSender(), _to, _artworkId);
        emit ArtworkNFTTransferred(_artworkId, _msgSender(), _to);
    }


    /// @notice Allows the DAO to burn a specific artwork NFT (governed - e.g., for inappropriate content).
    /// @param _artworkId The ID of the artwork NFT to burn.
    function burnArtworkNFT(uint256 _artworkId) public onlyMember {
        require(artworks[_artworkId].id == _artworkId, "Artwork does not exist.");
        require(ownerOf(_artworkId) == address(this), "DAO does not own this NFT."); // Ensure DAO owns it before burning
        // Governance logic to propose and vote on burning NFTs would be needed.
        // For simplicity, allowing any member to initiate burn for now, but this should be governed.

        _burn(_artworkId);
        emit ArtworkNFTBurned(_artworkId);
    }

    /// @notice Allows the DAO to update the metadata URI of an artwork NFT (governed - e.g., to fix errors).
    /// @param _artworkId The ID of the artwork NFT to update.
    /// @param _newMetadataURI The new metadata URI string.
    function setArtworkMetadataURI(uint256 _artworkId, string memory _newMetadataURI) public onlyMember {
        require(artworks[_artworkId].id == _artworkId, "Artwork does not exist.");
        // Governance logic to propose and vote on metadata updates would be needed.
        // For simplicity, allowing any member to update for now, but this should be governed.
        artworks[_artworkId].metadataURI = _newMetadataURI;
        emit ArtworkMetadataURIUpdated(_artworkId, _newMetadataURI);
    }

    /// @notice Returns the address of the deployed NFT contract (this contract itself).
    /// @return The contract address.
    function getNFTContractAddress() public view returns (address) {
        return address(this);
    }

    /// @notice Returns the current balance of the DAO treasury.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Override supportsInterface to indicate ERC721Metadata support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceId);
    }
}
```