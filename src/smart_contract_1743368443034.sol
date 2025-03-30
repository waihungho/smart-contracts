```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title Decentralized Art Collective (DAC) - Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective, incorporating advanced concepts
 *      for art creation, ownership, governance, and community interaction.

 * **Outline and Function Summary:**

 * **Core Functionality:**
 * 1.  `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Artists propose new art pieces with metadata for community voting.
 * 2.  `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Community members vote on art proposals.
 * 3.  `finalizeArtProposal(uint256 _proposalId)`:  Admin finalizes approved art proposals, minting NFTs for successful creations.
 * 4.  `mintArtNFT(uint256 _artId, address _recipient)`: (Internal) Mints an NFT for a finalized art piece.
 * 5.  `transferArtNFT(uint256 _tokenId, address _to)`: Allows transferring ownership of Art NFTs.
 * 6.  `burnArtNFT(uint256 _tokenId)`: Allows burning/destroying Art NFTs (governance controlled).
 * 7.  `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 * 8.  `getApprovedArtProposals()`: Returns a list of IDs of approved art proposals.
 * 9.  `getAllArtProposals()`: Returns a list of IDs of all art proposals.
 * 10. `getArtistArtProposals(address _artist)`: Returns a list of art proposals submitted by a specific artist.

 * **Artist & Community Management:**
 * 11. `becomeArtist()`: Allows users to request artist status within the collective.
 * 12. `approveArtist(address _artist)`: Admin function to approve artist applications.
 * 13. `revokeArtist(address _artist)`: Admin function to revoke artist status.
 * 14. `isArtist(address _user)`: Checks if an address is a registered artist.
 * 15. `getArtistCount()`: Returns the total number of registered artists.

 * **Governance & Collective Management:**
 * 16. `createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata, address _targetContract)`:  Allows artists to create governance proposals for collective decisions.
 * 17. `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Artists vote on governance proposals.
 * 18. `executeGovernanceProposal(uint256 _proposalId)`:  Admin executes approved governance proposals, potentially calling functions on other contracts.
 * 19. `getGovernanceProposalDetails(uint256 _proposalId)`: Retrieves details of a specific governance proposal.
 * 20. `getApprovedGovernanceProposals()`: Returns a list of IDs of approved governance proposals.
 * 21. `depositToTreasury()`: Allows anyone to deposit funds into the collective's treasury.
 * 22. `withdrawFromTreasury(uint256 _amount, address _recipient)`: Admin function to withdraw funds from the treasury (governance controlled in real-world scenario).
 * 23. `getTreasuryBalance()`: Returns the current balance of the collective's treasury.
 * 24. `pauseContract()`: Admin function to pause core functionalities in case of emergency.
 * 25. `unpauseContract()`: Admin function to unpause the contract.
 * 26. `setVotingDuration(uint256 _durationInBlocks)`: Admin function to set the voting duration for proposals.
 * 27. `getVotingDuration()`: Returns the current voting duration.

 * **Events:**
 * - `ArtProposalSubmitted(uint256 proposalId, address artist, string title)`
 * - `ArtProposalVoted(uint256 proposalId, address voter, bool vote)`
 * - `ArtProposalFinalized(uint256 proposalId, uint256 artId)`
 * - `ArtNFTMinted(uint256 tokenId, uint256 artId, address recipient)`
 * - `GovernanceProposalCreated(uint256 proposalId, address proposer, string title)`
 * - `GovernanceProposalVoted(uint256 proposalId, address voter, bool vote)`
 * - `GovernanceProposalExecuted(uint256 proposalId)`
 * - `ArtistRequested(address artist)`
 * - `ArtistApproved(address artist)`
 * - `ArtistRevoked(address artist)`
 * - `TreasuryDeposit(address sender, uint256 amount)`
 * - `TreasuryWithdrawal(address recipient, uint256 amount)`
 * - `ContractPaused()`
 * - `ContractUnpaused()`
 */
contract DecentralizedArtCollective is ERC721, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter private _artProposalCounter;
    Counters.Counter private _artNFTCounter;
    Counters.Counter private _governanceProposalCounter;
    Counters.Counter private _artistCounter;

    uint256 public votingDuration = 100; // Voting duration in blocks (adjust as needed)

    struct ArtProposal {
        uint256 id;
        address artist;
        string title;
        string description;
        string ipfsHash;
        uint256 voteCount;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
        uint256 endTime; // Block number when voting ends
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        bytes calldata; // Function call data
        address targetContract; // Contract to call
        uint256 voteCount;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool approved;
        bool executed;
        uint256 endTime; // Block number when voting ends
    }

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => voter => voted
    mapping(uint256 => mapping(address => bool)) public governanceProposalVotes; // proposalId => voter => voted
    EnumerableSet.AddressSet private artists;
    mapping(address => bool) public artistRequested; // Track users who requested artist status

    uint256 public treasuryBalance;
    bool public paused;

    event ArtProposalSubmitted(uint256 proposalId, address artist, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalFinalized(uint256 proposalId, uint256 artId);
    event ArtNFTMinted(uint256 tokenId, uint256 artId, address recipient);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string title);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event ArtistRequested(address artist);
    event ArtistApproved(address artist);
    event ArtistRevoked(address artist);
    event TreasuryDeposit(address sender, uint256 amount);
    event TreasuryWithdrawal(address recipient, uint256 amount);
    event ContractPaused();
    event ContractUnpaused();

    modifier onlyArtist() {
        require(isArtist(msg.sender), "Only artists can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor() ERC721("DecentralizedArtCollective", "DAC") Ownable() {
        // Initialize contract - Admin is the deployer
    }

    // ------------------------ Art Proposal Functions ------------------------

    /// @notice Artists propose new art pieces for community voting.
    /// @param _title Title of the art proposal.
    /// @param _description Description of the art piece.
    /// @param _ipfsHash IPFS hash linking to the art's metadata.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyArtist notPaused {
        _artProposalCounter.increment();
        uint256 proposalId = _artProposalCounter.current();
        artProposals[proposalId] = ArtProposal({
            id: proposalId,
            artist: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            voteCount: 0,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false,
            endTime: block.number + votingDuration
        });
        emit ArtProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Community members vote on an active art proposal.
    /// @param _proposalId ID of the art proposal to vote on.
    /// @param _vote `true` for yes, `false` for no.
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external notPaused {
        require(artProposals[_proposalId].artist != address(0), "Proposal does not exist");
        require(!artProposals[_proposalId].finalized, "Proposal voting already finalized");
        require(block.number <= artProposals[_proposalId].endTime, "Voting period has ended");
        require(!artProposalVotes[_proposalId][msg.sender], "Already voted on this proposal");

        artProposalVotes[_proposalId][msg.sender] = true;
        artProposals[_proposalId].voteCount++;
        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Admin finalizes an art proposal after voting ends, minting an NFT if approved.
    /// @param _proposalId ID of the art proposal to finalize.
    function finalizeArtProposal(uint256 _proposalId) external onlyAdmin notPaused {
        require(artProposals[_proposalId].artist != address(0), "Proposal does not exist");
        require(!artProposals[_proposalId].finalized, "Proposal already finalized");
        require(block.number > artProposals[_proposalId].endTime, "Voting period has not ended");

        artProposals[_proposalId].finalized = true;
        if (artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
            artProposals[_proposalId].approved = true;
            _mintArtNFT(_proposalId, artProposals[_proposalId].artist); // Mint NFT to the artist
            emit ArtProposalFinalized(_proposalId, _artNFTCounter.current());
        }
    }

    /// @dev Internal function to mint an Art NFT.
    /// @param _artId ID of the art proposal (used as unique art identifier).
    /// @param _recipient Address to receive the NFT.
    function _mintArtNFT(uint256 _artId, address _recipient) internal {
        _artNFTCounter.increment();
        uint256 tokenId = _artNFTCounter.current();
        _safeMint(_recipient, tokenId);
        emit ArtNFTMinted(tokenId, _artId, _recipient);
    }

    /// @notice Allows transferring ownership of an Art NFT.
    /// @param _tokenId ID of the NFT to transfer.
    /// @param _to Address of the new owner.
    function transferArtNFT(uint256 _tokenId, address _to) external {
        safeTransferFrom(msg.sender, _to, _tokenId);
    }

    /// @notice Allows burning/destroying an Art NFT (governance controlled - example admin function).
    /// @param _tokenId ID of the NFT to burn.
    function burnArtNFT(uint256 _tokenId) external onlyAdmin {
        _burn(_tokenId);
    }

    /// @notice Retrieves details of a specific art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint256 _proposalId) external view returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Returns a list of IDs of approved art proposals.
    /// @return Array of proposal IDs.
    function getApprovedArtProposals() external view returns (uint256[] memory) {
        uint256[] memory approvedProposalIds = new uint256[](_artProposalCounter.current()); // Max size, could be optimized
        uint256 count = 0;
        for (uint256 i = 1; i <= _artProposalCounter.current(); i++) {
            if (artProposals[i].approved) {
                approvedProposalIds[count] = i;
                count++;
            }
        }
        // Resize to actual count
        assembly {
            mstore(approvedProposalIds, count)
        }
        return approvedProposalIds;
    }

    /// @notice Returns a list of IDs of all art proposals.
    /// @return Array of proposal IDs.
    function getAllArtProposals() external view returns (uint256[] memory) {
        uint256[] memory allProposalIds = new uint256[](_artProposalCounter.current());
        for (uint256 i = 1; i <= _artProposalCounter.current(); i++) {
            allProposalIds[i - 1] = i;
        }
        return allProposalIds;
    }

    /// @notice Returns a list of art proposal IDs submitted by a specific artist.
    /// @param _artist Address of the artist.
    /// @return Array of proposal IDs.
    function getArtistArtProposals(address _artist) external view returns (uint256[] memory) {
        uint256[] memory artistProposalIds = new uint256[](_artProposalCounter.current()); // Max size
        uint256 count = 0;
        for (uint256 i = 1; i <= _artProposalCounter.current(); i++) {
            if (artProposals[i].artist == _artist) {
                artistProposalIds[count] = i;
                count++;
            }
        }
        // Resize to actual count
        assembly {
            mstore(artistProposalIds, count)
        }
        return artistProposalIds;
    }

    // ------------------------ Artist Management Functions ------------------------

    /// @notice Allows users to request artist status within the collective.
    function becomeArtist() external notPaused {
        require(!isArtist(msg.sender), "Already an artist or artist status requested");
        require(!artistRequested[msg.sender], "Artist status already requested");
        artistRequested[msg.sender] = true;
        emit ArtistRequested(msg.sender);
    }

    /// @notice Admin function to approve artist applications.
    /// @param _artist Address of the artist to approve.
    function approveArtist(address _artist) external onlyAdmin notPaused {
        require(artistRequested[_artist], "Artist status not requested");
        require(!isArtist(_artist), "Artist already approved");
        artists.add(_artist);
        artistRequested[_artist] = false;
        _artistCounter.increment();
        emit ArtistApproved(_artist);
    }

    /// @notice Admin function to revoke artist status.
    /// @param _artist Address of the artist to revoke status from.
    function revokeArtist(address _artist) external onlyAdmin notPaused {
        require(isArtist(_artist), "Not an artist");
        artists.remove(_artist);
        _artistCounter.decrement();
        emit ArtistRevoked(_artist);
    }

    /// @notice Checks if an address is a registered artist.
    /// @param _user Address to check.
    /// @return `true` if the address is an artist, `false` otherwise.
    function isArtist(address _user) public view returns (bool) {
        return artists.contains(_user);
    }

    /// @notice Returns the total number of registered artists.
    /// @return Number of artists.
    function getArtistCount() external view returns (uint256) {
        return artists.length();
    }


    // ------------------------ Governance Proposal Functions ------------------------

    /// @notice Artists create governance proposals for collective decisions.
    /// @param _title Title of the governance proposal.
    /// @param _description Description of the proposal.
    /// @param _calldata Function call data to be executed if the proposal passes.
    /// @param _targetContract Address of the contract to call with the calldata.
    function createGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata, address _targetContract) external onlyArtist notPaused {
        _governanceProposalCounter.increment();
        uint256 proposalId = _governanceProposalCounter.current();
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldata: _calldata,
            targetContract: _targetContract,
            voteCount: 0,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            approved: false,
            executed: false,
            endTime: block.number + votingDuration
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _title);
    }

    /// @notice Artists vote on an active governance proposal.
    /// @param _proposalId ID of the governance proposal to vote on.
    /// @param _vote `true` for yes, `false` for no.
    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) external onlyArtist notPaused {
        require(governanceProposals[_proposalId].proposer != address(0), "Governance proposal does not exist");
        require(!governanceProposals[_proposalId].finalized, "Governance proposal voting already finalized");
        require(block.number <= governanceProposals[_proposalId].endTime, "Voting period has ended");
        require(!governanceProposalVotes[_proposalId][msg.sender], "Already voted on this governance proposal");

        governanceProposalVotes[_proposalId][msg.sender] = true;
        governanceProposals[_proposalId].voteCount++;
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Admin executes an approved governance proposal after voting ends.
    /// @param _proposalId ID of the governance proposal to execute.
    function executeGovernanceProposal(uint256 _proposalId) external onlyAdmin notPaused {
        require(governanceProposals[_proposalId].proposer != address(0), "Governance proposal does not exist");
        require(governanceProposals[_proposalId].approved, "Governance proposal not approved");
        require(!governanceProposals[_proposalId].executed, "Governance proposal already executed");
        require(governanceProposals[_proposalId].finalized, "Governance proposal voting not finalized yet");

        governanceProposals[_proposalId].executed = true;
        (bool success, ) = governanceProposals[_proposalId].targetContract.call(governanceProposals[_proposalId].calldata);
        require(success, "Governance proposal execution failed");
        emit GovernanceProposalExecuted(_proposalId);
    }

    /// @notice Admin finalizes a governance proposal after voting ends.
    /// @param _proposalId ID of the governance proposal to finalize.
    function finalizeGovernanceProposal(uint256 _proposalId) external onlyAdmin notPaused {
        require(governanceProposals[_proposalId].proposer != address(0), "Governance proposal does not exist");
        require(!governanceProposals[_proposalId].finalized, "Governance proposal already finalized");
        require(block.number > governanceProposals[_proposalId].endTime, "Voting period has not ended");

        governanceProposals[_proposalId].finalized = true;
        if (governanceProposals[_proposalId].yesVotes > governanceProposals[_proposalId].noVotes) {
            governanceProposals[_proposalId].approved = true;
        }
    }


    /// @notice Retrieves details of a specific governance proposal.
    /// @param _proposalId ID of the governance proposal.
    /// @return GovernanceProposal struct containing proposal details.
    function getGovernanceProposalDetails(uint256 _proposalId) external view returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    /// @notice Returns a list of IDs of approved governance proposals.
    /// @return Array of proposal IDs.
    function getApprovedGovernanceProposals() external view returns (uint256[] memory) {
        uint256[] memory approvedProposalIds = new uint256[](_governanceProposalCounter.current()); // Max size
        uint256 count = 0;
        for (uint256 i = 1; i <= _governanceProposalCounter.current(); i++) {
            if (governanceProposals[i].approved) {
                approvedProposalIds[count] = i;
                count++;
            }
        }
        // Resize to actual count
        assembly {
            mstore(approvedProposalIds, count)
        }
        return approvedProposalIds;
    }

    // ------------------------ Treasury Functions ------------------------

    /// @notice Allows anyone to deposit funds into the collective's treasury.
    function depositToTreasury() external payable notPaused {
        treasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Admin function to withdraw funds from the treasury.
    /// @param _amount Amount to withdraw.
    /// @param _recipient Address to receive the withdrawn funds.
    function withdrawFromTreasury(uint256 _amount, address _recipient) external onlyAdmin notPaused {
        require(treasuryBalance >= _amount, "Insufficient treasury balance");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /// @notice Returns the current balance of the collective's treasury.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }

    // ------------------------ Admin & Utility Functions ------------------------

    /// @notice Admin function to pause core functionalities in case of emergency.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Admin function to set the voting duration for proposals.
    /// @param _durationInBlocks Duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin {
        votingDuration = _durationInBlocks;
    }

    /// @notice Returns the current voting duration in blocks.
    /// @return Voting duration in blocks.
    function getVotingDuration() external view returns (uint256) {
        return votingDuration;
    }

    // Override supportsInterface to declare ERC721 interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Fallback function to accept ETH deposits
    receive() external payable {
        depositToTreasury();
    }
}
```