```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling collaborative art creation, curation, and management.
 *
 * **Outline & Function Summary:**
 *
 * **1. Artist Management:**
 *    - `registerArtist(string _artistName, string _artistDescription)`: Allows users to register as artists within the collective.
 *    - `updateArtistProfile(string _newArtistName, string _newArtistDescription)`: Artists can update their profile information.
 *    - `revokeArtistStatus(address _artistAddress)`: (Governance) Revokes artist status from a member.
 *    - `isArtist(address _userAddress) view returns (bool)`: Checks if an address is a registered artist.
 *    - `getArtistProfile(address _artistAddress) view returns (string, string)`: Retrieves an artist's name and description.
 *    - `getArtistCount() view returns (uint256)`: Returns the total number of registered artists.
 *
 * **2. Art Submission & Curation:**
 *    - `submitArtProposal(string _artTitle, string _artDescription, string _artIPFSHash)`: Artists submit art proposals with details and IPFS hash.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Registered artists can vote on art proposals (approval/rejection).
 *    - `finalizeArtProposal(uint256 _proposalId)`: (Governance) Finalizes an approved art proposal, making it official.
 *    - `rejectArtProposal(uint256 _proposalId)`: (Governance) Rejects an art proposal.
 *    - `getProposalDetails(uint256 _proposalId) view returns (string, string, string, address, uint256, uint256)`: Retrieves details of a specific art proposal.
 *    - `listPendingProposals() view returns (uint256[])`: Lists IDs of art proposals currently under voting.
 *    - `listApprovedProposals() view returns (uint256[])`: Lists IDs of finalized and approved art proposals.
 *
 * **3. NFT Minting & Management:**
 *    - `mintArtNFT(uint256 _proposalId)`: (Governance, after proposal finalization) Mints an NFT representing the approved artwork.
 *    - `transferArtNFT(uint256 _nftId, address _recipient)`: Allows the collective to transfer ownership of an Art NFT (e.g., for sale or distribution).
 *    - `burnArtNFT(uint256 _nftId)`: (Governance) Burns an Art NFT, removing it from circulation.
 *    - `setNFTMetadataURI(uint256 _nftId, string _metadataURI)`: (Governance) Sets or updates the metadata URI for an Art NFT.
 *    - `getNFTDetails(uint256 _nftId) view returns (uint256, uint256, string, address)`: Retrieves details of a specific Art NFT.
 *    - `getArtNFTCount() view returns (uint256)`: Returns the total number of Art NFTs minted by the collective.
 *
 * **4. Governance & Proposals (Beyond Art Curation):**
 *    - `createGovernanceProposal(string _proposalTitle, string _proposalDescription, bytes _calldata)`: Allows artists to create proposals for governance changes (e.g., rule changes, feature additions).
 *    - `voteOnGovernanceProposal(uint256 _proposalId, bool _vote)`: Registered artists vote on governance proposals.
 *    - `executeGovernanceProposal(uint256 _proposalId)`: (Governance, after approval) Executes a governance proposal if it's approved and executable.
 *    - `getGovernanceProposalDetails(uint256 _proposalId) view returns (string, string, bytes, uint256, uint256)`: Retrieves details of a governance proposal.
 *    - `listGovernanceProposals() view returns (uint256[])`: Lists IDs of all governance proposals.
 *
 * **5. Treasury & Funding (Basic):**
 *    - `depositFunds() payable`: Allows anyone to deposit funds into the collective's treasury.
 *    - `withdrawFunds(uint256 _amount, address _recipient)`: (Governance) Allows withdrawal of funds from the treasury to a specified recipient.
 *    - `getTreasuryBalance() view returns (uint256)`: Returns the current balance of the collective's treasury.
 *
 * **6. Utility & Information:**
 *    - `getVersion() pure returns (string)`: Returns the contract version.
 *    - `contractInfo() pure returns (string)`: Returns general information about the contract.
 */

contract DecentralizedArtCollective {

    // -------- State Variables --------

    address public governanceAddress; // Address authorized for governance actions
    uint256 public artistCount;
    mapping(address => ArtistProfile) public artistProfiles;
    mapping(address => bool) public isRegisteredArtist;

    uint256 public artProposalCount;
    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => mapping(address => bool)) public artProposalVotes; // proposalId => artistAddress => voted (true/false)

    uint256 public governanceProposalCount;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(address => bool)) public governanceProposalVotes; // proposalId => artistAddress => voted (true/false)

    uint256 public artNFTCount;
    mapping(uint256 => ArtNFT) public artNFTs;
    mapping(uint256 => uint256) public proposalIdToNftId; // Mapping proposal ID to minted NFT ID for tracking


    // -------- Enums & Structs --------

    enum ProposalStatus { Pending, Approved, Rejected, Finalized }

    struct ArtistProfile {
        string artistName;
        string artistDescription;
        uint256 registrationTimestamp;
    }

    struct ArtProposal {
        string artTitle;
        string artDescription;
        string artIPFSHash;
        address proposer;
        ProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
        uint256 proposalTimestamp;
    }

    struct GovernanceProposal {
        string proposalTitle;
        string proposalDescription;
        bytes calldataData; // Calldata to execute if approved
        ProposalStatus status;
        uint256 upvotes;
        uint256 downvotes;
        uint256 proposalTimestamp;
    }

    struct ArtNFT {
        uint256 proposalId;
        uint256 mintTimestamp;
        string metadataURI;
        address owner; // Initially owned by the contract/collective
    }


    // -------- Events --------

    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress, string newArtistName);
    event ArtistStatusRevoked(address artistAddress, address revokedBy);

    event ArtProposalSubmitted(uint256 proposalId, address proposer, string artTitle);
    event ArtProposalVoted(uint256 proposalId, address artistAddress, bool vote);
    event ArtProposalFinalized(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);

    event GovernanceProposalCreated(uint256 proposalId, address proposer, string proposalTitle);
    event GovernanceProposalVoted(uint256 proposalId, address artistAddress, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);

    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address minter);
    event ArtNFTTransferred(uint256 nftId, address from, address to);
    event ArtNFTBurned(uint256 nftId, address burner);
    event ArtNFTMetadataURISet(uint256 nftId, string metadataURI, address setter);

    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(uint256 amount, address recipient, address withdrawer);


    // -------- Modifiers --------

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance address can call this function.");
        _;
    }

    modifier onlyArtist() {
        require(isRegisteredArtist[msg.sender], "Only registered artists can call this function.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && (_proposalId <= artProposalCount || _proposalId <= governanceProposalCount), "Proposal does not exist.");
        _;
    }

    modifier artProposalPending(uint256 _proposalId) {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Art proposal is not pending.");
        _;
    }

    modifier governanceProposalPending(uint256 _proposalId) {
        require(governanceProposals[_proposalId].status == ProposalStatus.Pending, "Governance proposal is not pending.");
        _;
    }

    modifier nftExists(uint256 _nftId) {
        require(_nftId > 0 && _nftId <= artNFTCount, "NFT does not exist.");
        _;
    }


    // -------- Constructor --------

    constructor(address _governanceAddress) {
        governanceAddress = _governanceAddress;
        artistCount = 0;
        artProposalCount = 0;
        governanceProposalCount = 0;
        artNFTCount = 0;
    }


    // -------- 1. Artist Management Functions --------

    function registerArtist(string memory _artistName, string memory _artistDescription) public {
        require(!isRegisteredArtist[msg.sender], "Already registered as an artist.");
        artistCount++;
        isRegisteredArtist[msg.sender] = true;
        artistProfiles[msg.sender] = ArtistProfile({
            artistName: _artistName,
            artistDescription: _artistDescription,
            registrationTimestamp: block.timestamp
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function updateArtistProfile(string memory _newArtistName, string memory _newArtistDescription) public onlyArtist {
        artistProfiles[msg.sender].artistName = _newArtistName;
        artistProfiles[msg.sender].artistDescription = _newArtistDescription;
        emit ArtistProfileUpdated(msg.sender, _newArtistName);
    }

    function revokeArtistStatus(address _artistAddress) public onlyGovernance {
        require(isRegisteredArtist[_artistAddress], "Address is not a registered artist.");
        isRegisteredArtist[_artistAddress] = false;
        artistCount--; // Decrement artist count
        emit ArtistStatusRevoked(_artistAddress, msg.sender);
    }

    function isArtist(address _userAddress) public view returns (bool) {
        return isRegisteredArtist[_userAddress];
    }

    function getArtistProfile(address _artistAddress) public view returns (string memory, string memory) {
        require(isRegisteredArtist[_artistAddress], "Address is not a registered artist.");
        return (artistProfiles[_artistAddress].artistName, artistProfiles[_artistAddress].artistDescription);
    }

    function getArtistCount() public view returns (uint256) {
        return artistCount;
    }


    // -------- 2. Art Submission & Curation Functions --------

    function submitArtProposal(string memory _artTitle, string memory _artDescription, string memory _artIPFSHash) public onlyArtist {
        artProposalCount++;
        artProposals[artProposalCount] = ArtProposal({
            artTitle: _artTitle,
            artDescription: _artDescription,
            artIPFSHash: _artIPFSHash,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            upvotes: 0,
            downvotes: 0,
            proposalTimestamp: block.timestamp
        });
        emit ArtProposalSubmitted(artProposalCount, msg.sender, _artTitle);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote) public onlyArtist proposalExists(_proposalId) artProposalPending(_proposalId) {
        require(!artProposalVotes[_proposalId][msg.sender], "Artist has already voted on this proposal.");
        artProposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            artProposals[_proposalId].upvotes++;
        } else {
            artProposals[_proposalId].downvotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
    }

    function finalizeArtProposal(uint256 _proposalId) public onlyGovernance proposalExists(_proposalId) artProposalPending(_proposalId) {
        // Example: Require more upvotes than downvotes to finalize. Can adjust logic.
        require(artProposals[_proposalId].upvotes > artProposals[_proposalId].downvotes, "Proposal does not have enough upvotes to finalize.");
        artProposals[_proposalId].status = ProposalStatus.Finalized;
        emit ArtProposalFinalized(_proposalId);
    }

    function rejectArtProposal(uint256 _proposalId) public onlyGovernance proposalExists(_proposalId) artProposalPending(_proposalId) {
        artProposals[_proposalId].status = ProposalStatus.Rejected;
        emit ArtProposalRejected(_proposalId);
    }

    function getProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (string memory, string memory, string memory, address, uint256, uint256) {
        ArtProposal storage proposal = artProposals[_proposalId];
        return (proposal.artTitle, proposal.artDescription, proposal.artIPFSHash, proposal.proposer, proposal.upvotes, proposal.downvotes);
    }

    function listPendingProposals() public view returns (uint256[] memory) {
        uint256[] memory pendingProposalIds = new uint256[](artProposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= artProposalCount; i++) {
            if (artProposals[i].status == ProposalStatus.Pending) {
                pendingProposalIds[count] = i;
                count++;
            }
        }
        // Resize the array to remove extra empty slots
        assembly {
            mstore(pendingProposalIds, count) // Set the length of the array
        }
        return pendingProposalIds;
    }

    function listApprovedProposals() public view returns (uint256[] memory) {
        uint256[] memory approvedProposalIds = new uint256[](artProposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= artProposalCount; i++) {
            if (artProposals[i].status == ProposalStatus.Finalized) {
                approvedProposalIds[count] = i;
                count++;
            }
        }
        // Resize the array
        assembly {
            mstore(approvedProposalIds, count)
        }
        return approvedProposalIds;
    }


    // -------- 3. NFT Minting & Management Functions --------

    function mintArtNFT(uint256 _proposalId) public onlyGovernance proposalExists(_proposalId) {
        require(artProposals[_proposalId].status == ProposalStatus.Finalized, "Proposal must be finalized to mint NFT.");
        artNFTCount++;
        artNFTs[artNFTCount] = ArtNFT({
            proposalId: _proposalId,
            mintTimestamp: block.timestamp,
            metadataURI: "", // Initially empty, to be set later
            owner: address(this) // Collective initially owns the NFT
        });
        proposalIdToNftId[_proposalId] = artNFTCount;
        emit ArtNFTMinted(artNFTCount, _proposalId, msg.sender);
    }

    function transferArtNFT(uint256 _nftId, address _recipient) public onlyGovernance nftExists(_nftId) {
        artNFTs[_nftId].owner = _recipient;
        emit ArtNFTTransferred(_nftId, address(this), _recipient);
    }

    function burnArtNFT(uint256 _nftId) public onlyGovernance nftExists(_nftId) {
        delete artNFTs[_nftId]; // Remove NFT data. Solidity handles storage refunds for deletions.
        emit ArtNFTBurned(_nftId, msg.sender);
    }

    function setNFTMetadataURI(uint256 _nftId, string memory _metadataURI) public onlyGovernance nftExists(_nftId) {
        artNFTs[_nftId].metadataURI = _metadataURI;
        emit ArtNFTMetadataURISet(_nftId, _metadataURI, msg.sender);
    }

    function getNFTDetails(uint256 _nftId) public view nftExists(_nftId) returns (uint256, uint256, string memory, address) {
        ArtNFT storage nft = artNFTs[_nftId];
        return (nft.proposalId, nft.mintTimestamp, nft.metadataURI, nft.owner);
    }

    function getArtNFTCount() public view returns (uint256) {
        return artNFTCount;
    }


    // -------- 4. Governance & Proposals (Beyond Art Curation) --------

    function createGovernanceProposal(string memory _proposalTitle, string memory _proposalDescription, bytes memory _calldata) public onlyArtist {
        governanceProposalCount++;
        governanceProposals[governanceProposalCount] = GovernanceProposal({
            proposalTitle: _proposalTitle,
            proposalDescription: _proposalDescription,
            calldataData: _calldata,
            status: ProposalStatus.Pending,
            upvotes: 0,
            downvotes: 0,
            proposalTimestamp: block.timestamp
        });
        emit GovernanceProposalCreated(governanceProposalCount, msg.sender, _proposalTitle);
    }

    function voteOnGovernanceProposal(uint256 _proposalId, bool _vote) public onlyArtist proposalExists(_proposalId) governanceProposalPending(_proposalId) {
        require(!governanceProposalVotes[_proposalId][msg.sender], "Artist has already voted on this proposal.");
        governanceProposalVotes[_proposalId][msg.sender] = true;
        if (_vote) {
            governanceProposals[_proposalId].upvotes++;
        } else {
            governanceProposals[_proposalId].downvotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    function executeGovernanceProposal(uint256 _proposalId) public onlyGovernance proposalExists(_proposalId) governanceProposalPending(_proposalId) {
        require(governanceProposals[_proposalId].upvotes > governanceProposals[_proposalId].downvotes, "Governance proposal does not have enough upvotes to execute.");
        governanceProposals[_proposalId].status = ProposalStatus.Finalized; // Mark as finalized even if execution fails for tracking
        emit GovernanceProposalExecuted(_proposalId);

        // Attempt to execute the calldata. Revert if it fails.
        (bool success, ) = address(this).call(governanceProposals[_proposalId].calldataData);
        require(success, "Governance proposal execution failed.");
    }

    function getGovernanceProposalDetails(uint256 _proposalId) public view proposalExists(_proposalId) returns (string memory, string memory, bytes memory, uint256, uint256) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        return (proposal.proposalTitle, proposal.proposalDescription, proposal.calldataData, proposal.upvotes, proposal.downvotes);
    }

    function listGovernanceProposals() public view returns (uint256[] memory) {
        uint256[] memory proposalIds = new uint256[](governanceProposalCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= governanceProposalCount; i++) {
            proposalIds[count] = i;
            count++;
        }
        // Resize the array
        assembly {
            mstore(proposalIds, count)
        }
        return proposalIds;
    }


    // -------- 5. Treasury & Funding (Basic) --------

    function depositFunds() public payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 _amount, address _recipient) public onlyGovernance {
        require(address(this).balance >= _amount, "Insufficient contract balance.");
        payable(_recipient).transfer(_amount);
        emit FundsWithdrawn(_amount, _recipient, msg.sender);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // -------- 6. Utility & Information --------

    function getVersion() public pure returns (string memory) {
        return "DAAC Contract v1.0";
    }

    function contractInfo() public pure returns (string memory) {
        return "Decentralized Autonomous Art Collective - Empowering artists through blockchain.";
    }

    // -------- Fallback function (for receiving ETH if needed) --------
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```