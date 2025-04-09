```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (Generated based on user request)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 * It enables artists to submit art proposals, community members to vote on them,
 * mint NFTs representing approved artworks, manage a treasury, distribute royalties,
 * and implement advanced governance mechanisms.
 *
 * Function Summary:
 * ------------------
 * **Artist Registration & Management:**
 * 1. registerArtist(): Allows artists to register with the collective.
 * 2. unregisterArtist(): Allows artists to unregister from the collective.
 * 3. isArtistRegistered(): Checks if an address is a registered artist.
 * 4. getArtistInfo(): Retrieves information about a registered artist.
 *
 * **Art Proposal Submission & Voting:**
 * 5. proposeArtPiece(): Artists can submit new art piece proposals.
 * 6. voteOnProposal(): Community members can vote on art proposals.
 * 7. getProposalDetails(): Retrieves details of a specific art proposal.
 * 8. executeProposal(): Executes a successful art proposal (mint NFT).
 * 9. cancelProposal(): Allows the proposer to cancel a proposal before voting ends.
 * 10. setVotingDuration(): Admin function to set the voting duration for proposals.
 *
 * **NFT Minting & Management:**
 * 11. mintArtNFT(): (Internal) Mints an NFT for an approved art piece.
 * 12. transferArtNFT(): Allows NFT holders to transfer their art NFTs.
 * 13. getArtPieceInfo(): Retrieves information about a minted art NFT.
 * 14. setBaseURI(): Admin function to set the base URI for NFT metadata.
 *
 * **Treasury & Royalty Management:**
 * 15. depositFunds(): Allows anyone to deposit funds into the DAAC treasury.
 * 16. withdrawFunds(): (Governance) Allows withdrawing funds from the treasury based on proposals.
 * 17. setArtistRoyaltyPercentage(): Admin function to set the royalty percentage for artists.
 * 18. claimArtistRoyalties(): Artists can claim their earned royalties from NFT sales.
 * 19. getTreasuryBalance(): Retrieves the current balance of the DAAC treasury.
 *
 * **Governance & Community Features:**
 * 20. delegateVotingPower(): Allows members to delegate their voting power to another address.
 * 21. getVotingPower(): Retrieves the voting power of an address.
 * 22. setQuorumPercentage(): Admin function to set the quorum percentage for voting.
 * 23. emergencyPauseContract(): Admin function to pause critical contract functions in case of emergency.
 * 24. emergencyUnpauseContract(): Admin function to unpause the contract after emergency resolution.
 */

contract DecentralizedArtCollective {
    // -------- State Variables --------

    // Artist Management
    mapping(address => Artist) public artists;
    address[] public registeredArtists;
    uint256 public artistCount;

    struct Artist {
        string artistName;
        string artistDescription;
        bool isRegistered;
    }

    // Art Proposals
    uint256 public proposalCount;
    mapping(uint256 => ArtProposal) public proposals;

    enum ProposalStatus { Pending, Active, Executed, Cancelled, Failed }

    struct ArtProposal {
        uint256 proposalId;
        address proposer;
        string artTitle;
        string artDescription;
        string artIPFSHash; // IPFS hash of the artwork
        uint256 votingStartTime;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
    }

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)

    // NFT Minting & Management
    string public baseURI = "ipfs://your-base-uri/"; // Base URI for NFT metadata
    mapping(uint256 => ArtNFT) public artNFTs;
    uint256 public nextNFTTokenId = 1;

    struct ArtNFT {
        uint256 tokenId;
        uint256 proposalId;
        address artist;
        string artTitle;
        string artDescription;
        string artIPFSHash;
    }

    // Treasury & Royalties
    uint256 public treasuryBalance;
    uint256 public artistRoyaltyPercentage = 10; // Default artist royalty percentage (10%)
    mapping(uint256 => uint256) public nftRoyaltiesEarned; // tokenId => amount of royalties earned

    // Governance & Community
    mapping(address => address) public votingDelegations; // Delegator => Delegate
    mapping(address => uint256) public stakedTokens; // Address => Staked Tokens (Placeholder for future staking mechanism)

    // Contract Administration & Control
    address public admin;
    bool public contractPaused = false;

    // -------- Events --------
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistUnregistered(address artistAddress);
    event ArtProposalCreated(uint256 proposalId, address proposer, string artTitle);
    event VoteCast(uint256 proposalId, address voter, bool vote);
    event ProposalExecuted(uint256 proposalId, uint256 tokenId);
    event ProposalCancelled(uint256 proposalId);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address recipient, uint256 amount);
    event NFTMinted(uint256 tokenId, uint256 proposalId, address artist);
    event RoyaltyClaimed(address artist, uint256 tokenId, uint256 amount);
    event VotingPowerDelegated(address delegator, address delegate);
    event ContractPaused(address admin);
    event ContractUnpaused(address admin);

    // -------- Modifiers --------
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyRegisteredArtist() {
        require(artists[msg.sender].isRegistered, "Only registered artists can perform this action.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount && proposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(proposals[_proposalId].status == _status, "Proposal is not in the required status.");
        _;
    }

    modifier votingInProgress(uint256 _proposalId) {
        require(proposals[_proposalId].status == ProposalStatus.Active && block.timestamp < proposals[_proposalId].votingEndTime, "Voting is not in progress or has ended.");
        _;
    }

    modifier contractNotPaused() {
        require(!contractPaused, "Contract is currently paused.");
        _;
    }


    // -------- Constructor --------
    constructor() {
        admin = msg.sender;
        artistCount = 0;
        proposalCount = 0;
        treasuryBalance = 0;
    }

    // -------- Artist Registration & Management Functions --------

    /// @notice Allows artists to register with the collective.
    /// @param _artistName The name of the artist.
    /// @param _artistDescription A brief description of the artist and their work.
    function registerArtist(string memory _artistName, string memory _artistDescription) external contractNotPaused {
        require(!artists[msg.sender].isRegistered, "Artist is already registered.");
        artists[msg.sender] = Artist({
            artistName: _artistName,
            artistDescription: _artistDescription,
            isRegistered: true
        });
        registeredArtists.push(msg.sender);
        artistCount++;
        emit ArtistRegistered(msg.sender, _artistName);
    }

    /// @notice Allows artists to unregister from the collective.
    function unregisterArtist() external onlyRegisteredArtist contractNotPaused {
        artists[msg.sender].isRegistered = false;
        // Remove from registeredArtists array (consider gas optimization for large arrays in production)
        for (uint i = 0; i < registeredArtists.length; i++) {
            if (registeredArtists[i] == msg.sender) {
                registeredArtists[i] = registeredArtists[registeredArtists.length - 1];
                registeredArtists.pop();
                break;
            }
        }
        artistCount--;
        emit ArtistUnregistered(msg.sender);
    }

    /// @notice Checks if an address is a registered artist.
    /// @param _artistAddress The address to check.
    /// @return True if the address is a registered artist, false otherwise.
    function isArtistRegistered(address _artistAddress) external view returns (bool) {
        return artists[_artistAddress].isRegistered;
    }

    /// @notice Retrieves information about a registered artist.
    /// @param _artistAddress The address of the artist.
    /// @return Artist struct containing artist information.
    function getArtistInfo(address _artistAddress) external view returns (Artist memory) {
        return artists[_artistAddress];
    }


    // -------- Art Proposal Submission & Voting Functions --------

    /// @notice Allows registered artists to submit a new art piece proposal.
    /// @param _artTitle The title of the art piece.
    /// @param _artDescription A description of the art piece.
    /// @param _artIPFSHash IPFS hash of the artwork.
    function proposeArtPiece(string memory _artTitle, string memory _artDescription, string memory _artIPFSHash) external onlyRegisteredArtist contractNotPaused {
        proposalCount++;
        ArtProposal storage newProposal = proposals[proposalCount];
        newProposal.proposalId = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.artTitle = _artTitle;
        newProposal.artDescription = _artDescription;
        newProposal.artIPFSHash = _artIPFSHash;
        newProposal.votingStartTime = block.timestamp;
        newProposal.votingEndTime = block.timestamp + votingDuration;
        newProposal.yesVotes = 0;
        newProposal.noVotes = 0;
        newProposal.status = ProposalStatus.Active; // Set status to Active immediately
        emit ArtProposalCreated(proposalCount, msg.sender, _artTitle);
    }

    /// @notice Allows community members to vote on an active art proposal.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external contractNotPaused proposalExists(_proposalId) votingInProgress(_proposalId) {
        require(proposals[_proposalId].proposer != msg.sender, "Proposer cannot vote on their own proposal."); // Optional: Prohibit proposer voting
        require(votingDelegations[msg.sender] == address(0) || votingDelegations[msg.sender] == msg.sender, "Cannot vote if voting power is delegated."); // Optional: Prevent voting if voting power is delegated (or allow delegate to vote instead)

        // In a real DAO, voting power would be determined by token staking or other mechanisms.
        // For simplicity, here every address has 1 unit of voting power.
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        emit VoteCast(_proposalId, msg.sender, _vote);

        // Check if voting period ended and potentially execute the proposal automatically (or trigger a separate execution function)
        if (block.timestamp >= proposals[_proposalId].votingEndTime) {
            _checkAndExecuteProposal(_proposalId);
        }
    }

    /// @notice Internal function to check if a proposal passed and execute it if conditions are met.
    /// @param _proposalId The ID of the proposal to check.
    function _checkAndExecuteProposal(uint256 _proposalId) internal proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Active) {
        if (proposals[_proposalId].status == ProposalStatus.Active && block.timestamp >= proposals[_proposalId].votingEndTime) {
            uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
            if (totalVotes > 0) { // Avoid division by zero
                uint256 yesPercentage = (proposals[_proposalId].yesVotes * 100) / totalVotes;
                if (yesPercentage >= quorumPercentage) {
                    executeProposal(_proposalId); // Execute automatically if voting period ends and quorum is met.
                } else {
                    proposals[_proposalId].status = ProposalStatus.Failed; // Mark as failed if quorum not reached
                }
            } else {
                proposals[_proposalId].status = ProposalStatus.Failed; // Mark as failed if no votes cast
            }
        }
    }


    /// @notice Retrieves details of a specific art proposal.
    /// @param _proposalId The ID of the proposal.
    /// @return ArtProposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (ArtProposal memory) {
        return proposals[_proposalId];
    }

    /// @notice Executes a successful art proposal by minting an NFT for the approved artwork.
    /// @param _proposalId The ID of the proposal to execute.
    function executeProposal(uint256 _proposalId) public contractNotPaused onlyAdmin proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Active) {
        require(block.timestamp >= proposals[_proposalId].votingEndTime, "Voting period has not ended yet.");

        uint256 totalVotes = proposals[_proposalId].yesVotes + proposals[_proposalId].noVotes;
        require(totalVotes > 0, "No votes were cast for this proposal."); // Avoid division by zero
        uint256 yesPercentage = (proposals[_proposalId].yesVotes * 100) / totalVotes;

        require(yesPercentage >= quorumPercentage, "Proposal did not reach quorum.");
        require(proposals[_proposalId].status == ProposalStatus.Active, "Proposal is not in active status."); // Double check status

        mintArtNFT(_proposalId);
        proposals[_proposalId].status = ProposalStatus.Executed;
        emit ProposalExecuted(_proposalId, nextNFTTokenId -1); // Emit event after minting
    }

    /// @notice Allows the proposer to cancel a proposal before the voting period ends.
    /// @param _proposalId The ID of the proposal to cancel.
    function cancelProposal(uint256 _proposalId) external contractNotPaused proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Active) {
        require(proposals[_proposalId].proposer == msg.sender, "Only the proposer can cancel the proposal.");
        require(block.timestamp < proposals[_proposalId].votingEndTime, "Voting period has already ended.");
        proposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ProposalCancelled(_proposalId);
    }

    /// @notice Admin function to set the voting duration for proposals.
    /// @param _durationInSeconds The new voting duration in seconds.
    function setVotingDuration(uint256 _durationInSeconds) external onlyAdmin contractNotPaused {
        votingDuration = _durationInSeconds;
    }


    // -------- NFT Minting & Management Functions --------

    /// @notice (Internal) Mints an NFT for an approved art piece.
    /// @param _proposalId The ID of the approved proposal.
    function mintArtNFT(uint256 _proposalId) internal {
        ArtProposal memory proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.Active || proposal.status == ProposalStatus.Executed, "Proposal must be active or executed to mint NFT."); // Ensure proposal is in correct state
        require(artists[proposal.proposer].isRegistered, "Proposer is not a registered artist.");

        artNFTs[nextNFTTokenId] = ArtNFT({
            tokenId: nextNFTTokenId,
            proposalId: _proposalId,
            artist: proposal.proposer,
            artTitle: proposal.artTitle,
            artDescription: proposal.artDescription,
            artIPFSHash: proposal.artIPFSHash
        });

        // In a real NFT contract, you would implement ERC721 logic here, including _mint and token metadata.
        // For this example, we'll just track the NFT data in the mapping.
        nftRoyaltiesEarned[nextNFTTokenId] = 0; // Initialize royalties earned for this NFT to 0.

        emit NFTMinted(nextNFTTokenId, _proposalId, proposal.proposer);
        nextNFTTokenId++;
    }

    /// @notice Allows NFT holders to transfer their art NFTs.
    /// @param _tokenId The ID of the NFT to transfer.
    /// @param _recipient The address to transfer the NFT to.
    function transferArtNFT(uint256 _tokenId, address _recipient) external contractNotPaused {
        require(artNFTs[_tokenId].tokenId == _tokenId, "NFT does not exist."); // Simple existence check
        // In a real ERC721 contract, you would implement transferFrom logic and ownership tracking.
        // Here, we are just simulating transfer for demonstration.

        // For this example, we are not implementing full ERC721 functionality.
        // In a real scenario, you would use a proper ERC721 implementation and handle ownership and approvals.
        // This function is a placeholder to indicate NFT transfer functionality.

        // In a real implementation, you would need to check msg.sender is the owner of the NFT.
        // For simplicity, we are skipping ownership check in this example.

        // Example of a basic transfer simulation (not actually changing ownership in this example)
        emit Transfer(msg.sender, _recipient, _tokenId); // ERC721 Transfer Event (example)
    }
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId); // Example ERC721 Transfer Event

    /// @notice Retrieves information about a minted art NFT.
    /// @param _tokenId The ID of the NFT.
    /// @return ArtNFT struct containing NFT details.
    function getArtPieceInfo(uint256 _tokenId) external view returns (ArtNFT memory) {
        return artNFTs[_tokenId];
    }

    /// @notice Admin function to set the base URI for NFT metadata.
    /// @param _newBaseURI The new base URI string.
    function setBaseURI(string memory _newBaseURI) external onlyAdmin contractNotPaused {
        baseURI = _newBaseURI;
    }


    // -------- Treasury & Royalty Management Functions --------

    /// @notice Allows anyone to deposit funds into the DAAC treasury.
    function depositFunds() external payable contractNotPaused {
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice (Governance) Allows withdrawing funds from the treasury based on proposals.
    /// @dev In a real DAO, withdrawals would be initiated and approved through governance proposals.
    /// @param _amount The amount to withdraw.
    /// @param _recipient The address to send the withdrawn funds to.
    function withdrawFunds(uint256 _amount, address _recipient) external onlyAdmin contractNotPaused {
        require(treasuryBalance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        treasuryBalance -= _amount;
        emit FundsWithdrawn(_recipient, _amount);
    }

    /// @notice Admin function to set the royalty percentage for artists on NFT sales.
    /// @param _percentage The new royalty percentage (e.g., 10 for 10%).
    function setArtistRoyaltyPercentage(uint256 _percentage) external onlyAdmin contractNotPaused {
        require(_percentage <= 100, "Royalty percentage cannot exceed 100.");
        artistRoyaltyPercentage = _percentage;
    }

    /// @notice Artists can claim their earned royalties from NFT sales.
    /// @dev In a real implementation, royalties would be calculated and accumulated upon NFT sales.
    ///      For this example, we are just demonstrating a royalty claiming mechanism.
    /// @param _tokenId The ID of the NFT for which to claim royalties.
    function claimArtistRoyalties(uint256 _tokenId) external onlyRegisteredArtist contractNotPaused {
        require(artNFTs[_tokenId].tokenId == _tokenId, "NFT does not exist.");
        require(artNFTs[_tokenId].artist == msg.sender, "Only the artist of this NFT can claim royalties.");

        uint256 earnedRoyalties = nftRoyaltiesEarned[_tokenId]; // Get earned royalties (in a real system, this would be calculated based on sales)
        require(earnedRoyalties > 0, "No royalties earned for this NFT yet.");

        nftRoyaltiesEarned[_tokenId] = 0; // Reset claimed royalties to 0 after claiming

        payable(msg.sender).transfer(earnedRoyalties);
        emit RoyaltyClaimed(msg.sender, _tokenId, earnedRoyalties);
    }

    /// @notice Retrieves the current balance of the DAAC treasury.
    /// @return The treasury balance in Wei.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }


    // -------- Governance & Community Features --------

    /// @notice Allows members to delegate their voting power to another address.
    /// @param _delegateAddress The address to delegate voting power to.
    function delegateVotingPower(address _delegateAddress) external contractNotPaused {
        require(_delegateAddress != address(0) && _delegateAddress != msg.sender, "Invalid delegate address.");
        votingDelegations[msg.sender] = _delegateAddress;
        emit VotingPowerDelegated(msg.sender, _delegateAddress);
    }

    /// @notice Retrieves the voting power of an address.
    /// @param _voterAddress The address to check voting power for.
    /// @return The voting power of the address (currently simplified to 1 per address, can be extended with staking).
    function getVotingPower(address _voterAddress) external view returns (uint256) {
        // In a more advanced DAO, voting power would be calculated based on staked tokens, NFT ownership, etc.
        // For this simplified example, each address has a voting power of 1, unless delegated.
        if (votingDelegations[_voterAddress] != address(0) && votingDelegations[_voterAddress] != _voterAddress) {
            return 0; // Delegated addresses lose their direct voting power. Delegate gets the power (in a real implementation, delegate's power would increase).
        }
        return 1;
    }

    /// @notice Admin function to set the quorum percentage required for proposals to pass.
    /// @param _percentage The new quorum percentage (e.g., 60 for 60%).
    function setQuorumPercentage(uint256 _percentage) external onlyAdmin contractNotPaused {
        require(_percentage <= 100, "Quorum percentage cannot exceed 100.");
        quorumPercentage = _percentage;
    }


    // -------- Emergency & Administration Functions --------

    /// @notice Admin function to pause critical contract functions in case of emergency.
    function emergencyPauseContract() external onlyAdmin {
        contractPaused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause the contract after emergency resolution.
    function emergencyUnpauseContract() external onlyAdmin {
        contractPaused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Fallback function to receive Ether.
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value); // Optionally emit event for direct Ether deposits.
    }
}
```