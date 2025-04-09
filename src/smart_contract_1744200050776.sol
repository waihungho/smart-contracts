```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Gemini AI Assistant
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC) that enables collaborative art creation, curation, and management using NFTs and DAO governance.
 *
 * Outline and Function Summary:
 *
 * 1.  Membership Management:
 *     - proposeNewMember(address _newMember): Allows members to propose new members.
 *     - voteOnMembershipProposal(uint _proposalId, bool _approve): Members vote on membership proposals.
 *     - executeMembershipProposal(uint _proposalId): Executes membership proposals after reaching quorum.
 *     - renounceMembership(): Allows members to voluntarily leave the collective.
 *     - getMemberCount(): Returns the current number of members in the collective.
 *
 * 2.  Art Proposal & Curation:
 *     - submitArtProposal(string memory _ipfsHash, string memory _title, string memory _description): Members propose new art pieces (NFT metadata IPFS hash).
 *     - voteOnArtProposal(uint _proposalId, bool _approve): Members vote on art proposals.
 *     - executeArtProposal(uint _proposalId): Executes art proposals, minting NFTs for approved artworks.
 *     - rejectArtProposal(uint _proposalId): Allows rejection of an art proposal before execution.
 *     - getArtProposalState(uint _proposalId): Returns the state of an art proposal.
 *     - getApprovedArtNFTs(): Returns a list of IDs of approved Art NFTs.
 *
 * 3.  Collective Treasury & Funding:
 *     - depositFunds(): Allows members or external parties to deposit funds into the collective treasury.
 *     - createFundingProposal(address _recipient, uint _amount, string memory _reason): Members propose funding allocations from the treasury.
 *     - voteOnFundingProposal(uint _proposalId, bool _approve): Members vote on funding proposals.
 *     - executeFundingProposal(uint _proposalId): Executes funding proposals, transferring funds from the treasury.
 *     - getTreasuryBalance(): Returns the current balance of the collective treasury.
 *
 * 4.  NFT Management & Features:
 *     - burnArtNFT(uint _nftId): Allows the collective (via proposal) to burn an Art NFT.
 *     - transferArtNFT(uint _nftId, address _recipient): Allows the collective (via proposal) to transfer ownership of an Art NFT.
 *     - setArtMetadataURI(uint _nftId, string memory _newMetadataURI): Allows updating the metadata URI of an Art NFT (governed).
 *     - getArtNFTMetadataURI(uint _nftId): Returns the metadata URI of a specific Art NFT.
 *     - getArtNFTOwner(uint _nftId): Returns the owner of a specific Art NFT.
 *     - getTotalArtNFTsMinted(): Returns the total number of Art NFTs minted by the collective.
 *
 * 5.  DAO Parameters & Settings:
 *     - setMembershipQuorum(uint _newQuorum): Allows the DAO to change the quorum for membership proposals.
 *     - setArtQuorum(uint _newQuorum): Allows the DAO to change the quorum for art proposals.
 *     - setFundingQuorum(uint _newQuorum): Allows the DAO to change the quorum for funding proposals.
 *     - changeVotingDuration(uint _newDurationInBlocks): Allows the DAO to change the voting duration for proposals.
 *     - getDAOSettings(): Returns current DAO settings (quorums, voting duration).
 *
 * 6.  Utility & Information:
 *     - getProposalDetails(uint _proposalId): Returns detailed information about a proposal.
 *     - isMember(address _address): Checks if an address is a member of the collective.
 *     - getContractName(): Returns the name of the smart contract.
 */
contract DecentralizedAutonomousArtCollective {

    // -------- State Variables --------

    string public contractName = "Decentralized Autonomous Art Collective";

    address public daoGovernor; // Address that can change DAO settings

    mapping(address => bool) public members; // Mapping of members of the collective
    address[] public memberList; // List to easily iterate through members

    uint public membershipQuorum = 50; // Percentage quorum for membership proposals (e.g., 50 for 50%)
    uint public artQuorum = 60;       // Percentage quorum for art proposals
    uint public fundingQuorum = 70;    // Percentage quorum for funding proposals
    uint public votingDurationBlocks = 100; // Number of blocks for voting duration

    uint public proposalCounter = 0;

    enum ProposalState { Pending, Active, Executed, Rejected, Failed }
    enum ProposalType { Membership, Art, Funding }

    struct Proposal {
        uint id;
        ProposalType proposalType;
        address proposer;
        uint startTime;
        uint endTime;
        uint yesVotes;
        uint noVotes;
        ProposalState state;
        bytes data; // Encoded data specific to proposal type
        string description;
    }

    mapping(uint => Proposal) public proposals;
    uint public activeProposalCount = 0;

    struct ArtNFT {
        uint id;
        string metadataURI;
        address artist;
        bool exists;
    }
    mapping(uint => ArtNFT) public artNFTs;
    uint public artNFTCounter = 0;
    uint[] public approvedArtNFTIds; // List of approved Art NFT IDs

    uint public treasuryBalance = 0;


    // -------- Events --------

    event MembershipProposed(uint proposalId, address newMember, address proposer, string description);
    event MembershipVoteCast(uint proposalId, address voter, bool approve);
    event MembershipProposalExecuted(uint proposalId, address newMember);
    event MembershipRenounced(address member);

    event ArtProposalSubmitted(uint proposalId, string ipfsHash, string title, string description, address proposer);
    event ArtVoteCast(uint proposalId, address voter, bool approve);
    event ArtProposalExecuted(uint proposalId, uint nftId, string metadataURI);
    event ArtProposalRejected(uint proposalId);
    event ArtNFTBurned(uint nftId);
    event ArtNFTTransferred(uint nftId, address from, address to);
    event ArtMetadataURISet(uint nftId, string oldURI, string newURI);

    event FundingProposalCreated(uint proposalId, address recipient, uint amount, string reason, address proposer);
    event FundingVoteCast(uint proposalId, address voter, bool approve);
    event FundingProposalExecuted(uint proposalId, address recipient, uint amount);
    event FundsDeposited(address from, uint amount);

    event DAOSettingChanged(string settingName, uint oldValue, uint newValue);
    event ProposalStateUpdated(uint proposalId, ProposalState newState);


    // -------- Modifiers --------

    modifier onlyMember() {
        require(members[msg.sender], "Only members can perform this action.");
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == daoGovernor, "Only DAO Governor can perform this action.");
        _;
    }

    modifier proposalExists(uint _proposalId) {
        require(proposals[_proposalId].id == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier proposalPending(uint _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Pending || proposals[_proposalId].state == ProposalState.Active, "Proposal is not pending or active.");
        _;
    }

    modifier proposalActive(uint _proposalId) {
        require(proposals[_proposalId].state == ProposalState.Active, "Proposal is not active.");
        _;
    }

    modifier votingPeriodNotEnded(uint _proposalId) {
        require(block.number <= proposals[_proposalId].endTime, "Voting period has ended.");
        _;
    }

    modifier votingPeriodHasEnded(uint _proposalId) {
        require(block.number > proposals[_proposalId].endTime, "Voting period has not ended.");
        _;
    }


    // -------- Constructor --------

    constructor() payable {
        daoGovernor = msg.sender;
        members[msg.sender] = true; // Deployer is the first member
        memberList.push(msg.sender);
        treasuryBalance = msg.value; // Initial funds can be deposited during deployment
    }


    // -------- 1. Membership Management --------

    /**
     * @dev Proposes a new member to the collective.
     * @param _newMember The address of the new member to be proposed.
     */
    function proposeNewMember(address _newMember) external onlyMember {
        require(!members[_newMember], "Address is already a member or has been member before.");
        require(_newMember != address(0), "Invalid address for new member.");

        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposalType = ProposalType.Membership;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingDurationBlocks;
        newProposal.state = ProposalState.Active;
        newProposal.description = "Proposal to add new member: "  ;
        newProposal.data = abi.encode(_newMember); // Store new member address in data
        activeProposalCount++;

        emit MembershipProposed(proposalCounter, _newMember, msg.sender, "Propose new member to collective.");
        emit ProposalStateUpdated(proposalCounter, ProposalState.Active);
    }

    /**
     * @dev Allows members to vote on a membership proposal.
     * @param _proposalId The ID of the membership proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnMembershipProposal(uint _proposalId, bool _approve) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodNotEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Membership, "Invalid proposal type for membership vote.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit MembershipVoteCast(_proposalId, msg.sender, _approve);

        if (block.number >= proposal.endTime) {
            _updateProposalState(_proposalId);
        }
    }

    /**
     * @dev Executes a membership proposal if it has passed the quorum.
     * @param _proposalId The ID of the membership proposal.
     */
    function executeMembershipProposal(uint _proposalId) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodHasEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Membership, "Invalid proposal type for membership execution.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        _updateProposalState(_proposalId); // Ensure state is up to date based on votes and quorum

        if (proposal.state == ProposalState.Executed) {
            address newMember = abi.decode(proposal.data, (address));
            members[newMember] = true;
            memberList.push(newMember);
            activeProposalCount--;
            emit MembershipProposalExecuted(_proposalId, newMember);
        } else if (proposal.state == ProposalState.Failed || proposal.state == ProposalState.Rejected) {
            proposal.state = ProposalState.Rejected; // Explicitly set to rejected if failed quorum
            activeProposalCount--;
            emit ProposalStateUpdated(_proposalId, ProposalState.Rejected);
        } else {
            revert("Membership proposal failed to reach quorum."); // Should not happen if _updateProposalState is correct
        }
    }

    /**
     * @dev Allows a member to renounce their membership from the collective.
     */
    function renounceMembership() external onlyMember {
        require(memberList.length > 1, "Cannot renounce membership if you are the only member."); // Ensure at least one member remains
        members[msg.sender] = false;
        // Remove from memberList (more gas efficient to iterate backwards for removal)
        for (uint i = memberList.length; i > 0; i--) {
            if (memberList[i-1] == msg.sender) {
                memberList[i-1] = memberList[memberList.length-1];
                memberList.pop();
                break;
            }
        }
        emit MembershipRenounced(msg.sender);
    }

    /**
     * @dev Returns the current number of members in the collective.
     * @return The number of members.
     */
    function getMemberCount() external view returns (uint) {
        return memberList.length;
    }


    // -------- 2. Art Proposal & Curation --------

    /**
     * @dev Allows members to submit an art proposal.
     * @param _ipfsHash IPFS hash of the art's metadata.
     * @param _title Title of the artwork.
     * @param _description Description of the artwork.
     */
    function submitArtProposal(string memory _ipfsHash, string memory _title, string memory _description) external onlyMember {
        require(bytes(_ipfsHash).length > 0 && bytes(_title).length > 0, "IPFS Hash and Title are required.");

        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposalType = ProposalType.Art;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingDurationBlocks;
        newProposal.state = ProposalState.Active;
        newProposal.description = "Art proposal: " ;
        newProposal.data = abi.encode(_ipfsHash, _title, _description); // Store IPFS, title, description
        activeProposalCount++;

        emit ArtProposalSubmitted(proposalCounter, _ipfsHash, _title, _description, msg.sender);
        emit ProposalStateUpdated(proposalCounter, ProposalState.Active);
    }

    /**
     * @dev Allows members to vote on an art proposal.
     * @param _proposalId The ID of the art proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnArtProposal(uint _proposalId, bool _approve) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodNotEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Art, "Invalid proposal type for art vote.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ArtVoteCast(_proposalId, msg.sender, _approve);

        if (block.number >= proposal.endTime) {
            _updateProposalState(_proposalId);
        }
    }

    /**
     * @dev Executes an art proposal if it has passed the quorum, minting an NFT.
     * @param _proposalId The ID of the art proposal.
     */
    function executeArtProposal(uint _proposalId) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodHasEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Art, "Invalid proposal type for art execution.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        _updateProposalState(_proposalId);

        if (proposal.state == ProposalState.Executed) {
            (string memory ipfsHash, string memory title, string memory description) = abi.decode(proposal.data, (string, string, string));

            artNFTCounter++;
            artNFTs[artNFTCounter] = ArtNFT({
                id: artNFTCounter,
                metadataURI: ipfsHash,
                artist: proposal.proposer,
                exists: true
            });
            approvedArtNFTIds.push(artNFTCounter);
            activeProposalCount--;

            emit ArtProposalExecuted(_proposalId, artNFTCounter, ipfsHash);
        } else if (proposal.state == ProposalState.Failed || proposal.state == ProposalState.Rejected) {
             proposal.state = ProposalState.Rejected; // Explicitly set to rejected if failed quorum
            activeProposalCount--;
            emit ProposalStateUpdated(_proposalId, ProposalState.Rejected);
        } else {
            revert("Art proposal failed to reach quorum.");
        }
    }

    /**
     * @dev Allows rejection of an art proposal before execution (e.g., proposer withdraws).
     * @param _proposalId The ID of the art proposal.
     */
    function rejectArtProposal(uint _proposalId) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Art, "Invalid proposal type for art rejection.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        proposal.state = ProposalState.Rejected;
        activeProposalCount--;
        emit ArtProposalRejected(_proposalId);
        emit ProposalStateUpdated(_proposalId, ProposalState.Rejected);
    }


    /**
     * @dev Gets the state of an art proposal.
     * @param _proposalId The ID of the art proposal.
     * @return The state of the proposal (Pending, Active, Executed, Rejected, Failed).
     */
    function getArtProposalState(uint _proposalId) external view proposalExists(_proposalId) returns (ProposalState) {
        require(proposals[_proposalId].proposalType == ProposalType.Art, "Invalid proposal type for art state check.");
        return proposals[_proposalId].state;
    }

    /**
     * @dev Returns a list of IDs of approved Art NFTs.
     * @return Array of approved Art NFT IDs.
     */
    function getApprovedArtNFTs() external view returns (uint[] memory) {
        return approvedArtNFTIds;
    }


    // -------- 3. Collective Treasury & Funding --------

    /**
     * @dev Allows depositing funds into the collective treasury.
     */
    function depositFunds() external payable {
        treasuryBalance += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev Creates a funding proposal to allocate funds from the treasury.
     * @param _recipient The address to receive the funds.
     * @param _amount The amount of funds to allocate (in wei).
     * @param _reason The reason for the funding proposal.
     */
    function createFundingProposal(address _recipient, uint _amount, string memory _reason) external onlyMember {
        require(_recipient != address(0), "Invalid recipient address.");
        require(_amount > 0, "Funding amount must be greater than zero.");
        require(_amount <= treasuryBalance, "Insufficient funds in treasury for this proposal.");

        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposalType = ProposalType.Funding;
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingDurationBlocks;
        newProposal.state = ProposalState.Active;
        newProposal.description = "Funding proposal: " ;
        newProposal.data = abi.encode(_recipient, _amount); // Store recipient and amount
        activeProposalCount++;

        emit FundingProposalCreated(proposalCounter, _recipient, _amount, _reason, msg.sender);
        emit ProposalStateUpdated(proposalCounter, ProposalState.Active);
    }

    /**
     * @dev Allows members to vote on a funding proposal.
     * @param _proposalId The ID of the funding proposal.
     * @param _approve True to approve, false to reject.
     */
    function voteOnFundingProposal(uint _proposalId, bool _approve) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodNotEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Funding, "Invalid proposal type for funding vote.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        if (_approve) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit FundingVoteCast(_proposalId, msg.sender, _approve);

        if (block.number >= proposal.endTime) {
            _updateProposalState(_proposalId);
        }
    }

    /**
     * @dev Executes a funding proposal if it has passed the quorum, transferring funds.
     * @param _proposalId The ID of the funding proposal.
     */
    function executeFundingProposal(uint _proposalId) external onlyMember proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodHasEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Funding, "Invalid proposal type for funding execution.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        _updateProposalState(_proposalId);

        if (proposal.state == ProposalState.Executed) {
            (address recipient, uint amount) = abi.decode(proposal.data, (address, uint));
            payable(recipient).transfer(amount);
            treasuryBalance -= amount;
            activeProposalCount--;
            emit FundingProposalExecuted(_proposalId, recipient, amount);
        } else if (proposal.state == ProposalState.Failed || proposal.state == ProposalState.Rejected) {
            proposal.state = ProposalState.Rejected; // Explicitly set to rejected if failed quorum
            activeProposalCount--;
            emit ProposalStateUpdated(_proposalId, ProposalState.Rejected);
        } else {
            revert("Funding proposal failed to reach quorum.");
        }
    }

    /**
     * @dev Returns the current balance of the collective treasury.
     * @return The treasury balance in wei.
     */
    function getTreasuryBalance() external view returns (uint) {
        return treasuryBalance;
    }


    // -------- 4. NFT Management & Features --------

    /**
     * @dev Allows the collective to burn an Art NFT (requires proposal).
     * @param _nftId The ID of the Art NFT to burn.
     */
    function burnArtNFT(uint _nftId) external onlyMember {
        require(artNFTs[_nftId].exists, "Art NFT does not exist or has been burned.");

        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposalType = ProposalType.Art; // Reusing Art proposal type for NFT management proposals
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingDurationBlocks;
        newProposal.state = ProposalState.Active;
        newProposal.description = "Proposal to burn Art NFT ID: ";
        newProposal.data = abi.encode(_nftId); // Store NFT ID
        activeProposalCount++;

        emit ProposalStateUpdated(proposalCounter, ProposalState.Active);

        // Execute burn directly in the same function for simplicity after proposal creation.
        // In a more complex system, execution could be a separate function.
        _executeBurnArtNFTProposal(proposalCounter);
    }

    function _executeBurnArtNFTProposal(uint _proposalId) private proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodHasEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Art, "Invalid proposal type for burn NFT execution.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        _updateProposalState(_proposalId);

        if (proposal.state == ProposalState.Executed) {
            uint nftId = abi.decode(proposal.data, (uint));
            require(artNFTs[nftId].exists, "Art NFT does not exist or has already been burned.");
            artNFTs[nftId].exists = false; // Mark as not existing -  (In a real NFT contract, you'd use _burn)

            // Remove from approvedArtNFTIds list if present
            for (uint i = 0; i < approvedArtNFTIds.length; i++) {
                if (approvedArtNFTIds[i] == nftId) {
                    approvedArtNFTIds[i] = approvedArtNFTIds[approvedArtNFTIds.length - 1];
                    approvedArtNFTIds.pop();
                    break;
                }
            }
            activeProposalCount--;
            emit ArtNFTBurned(nftId);
        } else if (proposal.state == ProposalState.Failed || proposal.state == ProposalState.Rejected) {
            proposal.state = ProposalState.Rejected; // Explicitly set to rejected if failed quorum
            activeProposalCount--;
            emit ProposalStateUpdated(_proposalId, ProposalState.Rejected);
        } else {
            revert("Burn Art NFT proposal failed to reach quorum.");
        }
    }


    /**
     * @dev Allows the collective to transfer ownership of an Art NFT (requires proposal).
     * @param _nftId The ID of the Art NFT to transfer.
     * @param _recipient The address to transfer the NFT to.
     */
    function transferArtNFT(uint _nftId, address _recipient) external onlyMember {
        require(artNFTs[_nftId].exists, "Art NFT does not exist.");
        require(_recipient != address(0), "Invalid recipient address.");

        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposalType = ProposalType.Art; // Reusing Art proposal type for NFT management proposals
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingDurationBlocks;
        newProposal.state = ProposalState.Active;
        newProposal.description = "Proposal to transfer Art NFT ID: ";
        newProposal.data = abi.encode(_nftId, _recipient); // Store NFT ID and recipient
        activeProposalCount++;

        emit ProposalStateUpdated(proposalCounter, ProposalState.Active);

        _executeTransferArtNFTProposal(proposalCounter);
    }

     function _executeTransferArtNFTProposal(uint _proposalId) private proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodHasEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Art, "Invalid proposal type for transfer NFT execution.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        _updateProposalState(_proposalId);

        if (proposal.state == ProposalState.Executed) {
            (uint nftId, address recipient) = abi.decode(proposal.data, (uint, address));
            require(artNFTs[nftId].exists, "Art NFT does not exist.");

            address previousOwner = getArtNFTOwner(nftId); // Get current owner (in this case, contract itself)
            artNFTs[nftId].artist = recipient; // Update artist to new owner (Simulating ownership transfer)

            activeProposalCount--;
            emit ArtNFTTransferred(nftId, previousOwner, recipient);
        } else if (proposal.state == ProposalState.Failed || proposal.state == ProposalState.Rejected) {
            proposal.state = ProposalState.Rejected; // Explicitly set to rejected if failed quorum
            activeProposalCount--;
            emit ProposalStateUpdated(_proposalId, ProposalState.Rejected);
        } else {
            revert("Transfer Art NFT proposal failed to reach quorum.");
        }
    }


    /**
     * @dev Allows updating the metadata URI of an Art NFT (requires proposal).
     * @param _nftId The ID of the Art NFT.
     * @param _newMetadataURI The new metadata URI to set.
     */
    function setArtMetadataURI(uint _nftId, string memory _newMetadataURI) external onlyMember {
        require(artNFTs[_nftId].exists, "Art NFT does not exist.");
        require(bytes(_newMetadataURI).length > 0, "New metadata URI cannot be empty.");

        proposalCounter++;
        Proposal storage newProposal = proposals[proposalCounter];
        newProposal.id = proposalCounter;
        newProposal.proposalType = ProposalType.Art; // Reusing Art proposal type for NFT management proposals
        newProposal.proposer = msg.sender;
        newProposal.startTime = block.number;
        newProposal.endTime = block.number + votingDurationBlocks;
        newProposal.state = ProposalState.Active;
        newProposal.description = "Proposal to update Art NFT metadata URI for ID: ";
        newProposal.data = abi.encode(_nftId, _newMetadataURI); // Store NFT ID and new URI
        activeProposalCount++;

        emit ProposalStateUpdated(proposalCounter, ProposalState.Active);

        _executeSetArtMetadataURIProposal(proposalCounter);
    }

    function _executeSetArtMetadataURIProposal(uint _proposalId) private proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodHasEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposalType == ProposalType.Art, "Invalid proposal type for set metadata URI execution.");
        require(proposal.state == ProposalState.Active, "Proposal is not active.");

        _updateProposalState(_proposalId);

        if (proposal.state == ProposalState.Executed) {
            (uint nftId, string memory newMetadataURI) = abi.decode(proposal.data, (uint, string));
            require(artNFTs[nftId].exists, "Art NFT does not exist.");

            string memory oldURI = artNFTs[nftId].metadataURI;
            artNFTs[nftId].metadataURI = newMetadataURI;

            activeProposalCount--;
            emit ArtMetadataURISet(nftId, oldURI, newMetadataURI);
        } else if (proposal.state == ProposalState.Failed || proposal.state == ProposalState.Rejected) {
            proposal.state = ProposalState.Rejected; // Explicitly set to rejected if failed quorum
            activeProposalCount--;
            emit ProposalStateUpdated(_proposalId, ProposalState.Rejected);
        } else {
            revert("Set Art NFT metadata URI proposal failed to reach quorum.");
        }
    }

    /**
     * @dev Returns the metadata URI of a specific Art NFT.
     * @param _nftId The ID of the Art NFT.
     * @return The metadata URI.
     */
    function getArtNFTMetadataURI(uint _nftId) external view returns (string memory) {
        require(artNFTs[_nftId].exists, "Art NFT does not exist.");
        return artNFTs[_nftId].metadataURI;
    }

    /**
     * @dev Returns the owner (artist in this context - address who proposed it) of a specific Art NFT.
     * @param _nftId The ID of the Art NFT.
     * @return The owner address.
     */
    function getArtNFTOwner(uint _nftId) external view returns (address) {
        require(artNFTs[_nftId].exists, "Art NFT does not exist.");
        return artNFTs[_nftId].artist;
    }

    /**
     * @dev Returns the total number of Art NFTs minted by the collective.
     * @return The total count of Art NFTs.
     */
    function getTotalArtNFTsMinted() external view returns (uint) {
        return artNFTCounter;
    }


    // -------- 5. DAO Parameters & Settings --------

    /**
     * @dev Sets the quorum for membership proposals. Only DAO governor can call this.
     * @param _newQuorum The new membership quorum percentage (0-100).
     */
    function setMembershipQuorum(uint _newQuorum) external onlyGovernor {
        require(_newQuorum <= 100, "Quorum must be between 0 and 100.");
        emit DAOSettingChanged("membershipQuorum", membershipQuorum, _newQuorum);
        membershipQuorum = _newQuorum;
    }

    /**
     * @dev Sets the quorum for art proposals. Only DAO governor can call this.
     * @param _newQuorum The new art quorum percentage (0-100).
     */
    function setArtQuorum(uint _newQuorum) external onlyGovernor {
        require(_newQuorum <= 100, "Quorum must be between 0 and 100.");
        emit DAOSettingChanged("artQuorum", artQuorum, _newQuorum);
        artQuorum = _newQuorum;
    }

    /**
     * @dev Sets the quorum for funding proposals. Only DAO governor can call this.
     * @param _newQuorum The new funding quorum percentage (0-100).
     */
    function setFundingQuorum(uint _newQuorum) external onlyGovernor {
        require(_newQuorum <= 100, "Quorum must be between 0 and 100.");
        emit DAOSettingChanged("fundingQuorum", fundingQuorum, _newQuorum);
        fundingQuorum = _newQuorum;
    }

    /**
     * @dev Changes the voting duration for all types of proposals. Only DAO governor can call this.
     * @param _newDurationInBlocks The new voting duration in blocks.
     */
    function changeVotingDuration(uint _newDurationInBlocks) external onlyGovernor {
        require(_newDurationInBlocks > 0, "Voting duration must be greater than zero.");
        emit DAOSettingChanged("votingDurationBlocks", votingDurationBlocks, _newDurationInBlocks);
        votingDurationBlocks = _newDurationInBlocks;
    }

    /**
     * @dev Returns current DAO settings (quorums, voting duration).
     * @return Membership quorum, art quorum, funding quorum, voting duration.
     */
    function getDAOSettings() external view returns (uint membershipQ, uint artQ, uint fundingQ, uint votingDuration) {
        return (membershipQuorum, artQuorum, fundingQuorum, votingDurationBlocks);
    }


    // -------- 6. Utility & Information --------

    /**
     * @dev Returns detailed information about a proposal.
     * @param _proposalId The ID of the proposal.
     * @return Proposal details (ID, type, proposer, start time, end time, yes votes, no votes, state, description).
     */
    function getProposalDetails(uint _proposalId) external view proposalExists(_proposalId) returns (
        uint id,
        ProposalType proposalType,
        address proposer,
        uint startTime,
        uint endTime,
        uint yesVotes,
        uint noVotes,
        ProposalState state,
        string memory description
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.proposalType,
            proposal.proposer,
            proposal.startTime,
            proposal.endTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.state,
            proposal.description
        );
    }

    /**
     * @dev Checks if an address is a member of the collective.
     * @param _address The address to check.
     * @return True if the address is a member, false otherwise.
     */
    function isMember(address _address) external view returns (bool) {
        return members[_address];
    }

    /**
     * @dev Returns the name of the smart contract.
     * @return The contract name.
     */
    function getContractName() external pure returns (string memory) {
        return contractName;
    }


    // -------- Internal Helper Functions --------

    /**
     * @dev Updates the state of a proposal based on vote counts and quorum.
     * @param _proposalId The ID of the proposal to update.
     */
    function _updateProposalState(uint _proposalId) internal proposalExists(_proposalId) proposalActive(_proposalId) votingPeriodHasEnded(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state != ProposalState.Active) return; // Prevent state update if not active

        uint quorumPercentage;
        if (proposal.proposalType == ProposalType.Membership) {
            quorumPercentage = membershipQuorum;
        } else if (proposal.proposalType == ProposalType.Art) {
            quorumPercentage = artQuorum;
        } else if (proposal.proposalType == ProposalType.Funding) {
            quorumPercentage = fundingQuorum;
        } else {
            quorumPercentage = 50; // Default quorum if type is not recognized (shouldn't happen)
        }

        uint totalVotes = proposal.yesVotes + proposal.noVotes;
        uint quorumNeeded = (memberList.length * quorumPercentage) / 100;

        if (totalVotes >= quorumNeeded && proposal.yesVotes > proposal.noVotes) {
            proposal.state = ProposalState.Executed;
        } else if (totalVotes >= quorumNeeded && proposal.yesVotes <= proposal.noVotes) {
            proposal.state = ProposalState.Rejected;
        }
        else {
            proposal.state = ProposalState.Failed; // Failed to reach quorum
        }
        emit ProposalStateUpdated(_proposalId, proposal.state);
    }

    receive() external payable {
        depositFunds(); // Allow direct deposits to the contract
    }
}
```