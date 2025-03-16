```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Smart Contract
 * @author Bard (Hypothetical AI Model)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC).
 *      This contract allows artists to submit their digital art proposals, members to vote on them,
 *      and if approved, mints NFTs representing the collectively curated art.
 *      It incorporates advanced concepts like dynamic metadata updates based on community votes,
 *      treasury management, and a proposal-based governance system.
 *
 * **Outline:**
 * 1. **Membership Management:**
 *    - Request Membership, Approve/Reject Membership, Revoke Membership, Member List
 * 2. **Art Proposal Submission & Voting:**
 *    - Submit Art Proposal (metadata URI), Vote on Proposal, Proposal Status, Proposal Results
 * 3. **NFT Minting & Management:**
 *    - Mint Approved Art NFTs, Set Base Metadata URI, Get NFT Metadata URI, Dynamic Metadata Updates
 * 4. **DAO Governance & Proposals:**
 *    - Create General Proposals, Vote on Proposals, Proposal Execution, Quorum & Voting Periods
 * 5. **Treasury Management:**
 *    - Deposit Funds, Withdraw Funds Proposal, Get Treasury Balance
 * 6. **Utility & Admin Functions:**
 *    - Pause/Unpause Contract, Set Voting Period, Set Quorum, Get Contract Version
 *
 * **Function Summary:**
 * | Function Name             | Parameters                               | Return Values        | Description                                                                   |
 * |---------------------------|-------------------------------------------|----------------------|-------------------------------------------------------------------------------|
 * | requestMembership         |                                           |                      | Allows anyone to request membership to the DAAC.                             |
 * | approveMembership         | `address _member`                         |                      | Owner/Admin approves a pending membership request.                          |
 * | rejectMembership          | `address _member`                         |                      | Owner/Admin rejects a pending membership request.                           |
 * | revokeMembership          | `address _member`                         |                      | Owner/Admin revokes membership from an existing member.                      |
 * | getMemberCount            |                                           | `uint256`            | Returns the total number of members in the DAAC.                               |
 * | isMember                  | `address _address`                        | `bool`               | Checks if an address is a member of the DAAC.                                  |
 * | submitArtProposal         | `string memory _metadataURI`             | `uint256`            | Members submit art proposals with metadata URI. Returns proposal ID.           |
 * | voteOnArtProposal         | `uint256 _proposalId`, `bool _vote`       |                      | Members vote on an art proposal (true for approve, false for reject).         |
 * | getArtProposalStatus      | `uint256 _proposalId`                     | `ProposalStatus`     | Returns the current status of an art proposal (Pending, Approved, Rejected). |
 * | getArtProposalVotes       | `uint256 _proposalId`                     | `uint256, uint256`   | Returns the yes and no vote counts for an art proposal.                      |
 * | mintArtNFT                | `uint256 _proposalId`                     | `uint256`            | Mints an NFT for an approved art proposal. Returns NFT ID.                    |
 * | setBaseMetadataURI        | `string memory _baseURI`                 |                      | Owner/Admin sets the base URI for all minted NFTs.                            |
 * | getArtNFTMetadataURI      | `uint256 _nftId`                          | `string memory`      | Returns the metadata URI for a specific art NFT.                              |
 * | updateArtMetadataProposal | `uint256 _nftId`, `string memory _newMetadataURI` | `uint256`            | Members propose updates to an existing NFT's metadata. Returns proposal ID.   |
 * | voteOnMetadataProposal    | `uint256 _proposalId`, `bool _vote`       |                      | Members vote on a metadata update proposal.                                  |
 * | getMetadataProposalStatus | `uint256 _proposalId`                     | `ProposalStatus`     | Returns the status of a metadata update proposal.                             |
 * | createGeneralProposal     | `string memory _description`              | `uint256`            | Members create general governance proposals. Returns proposal ID.             |
 * | voteOnGeneralProposal     | `uint256 _proposalId`, `bool _vote`       |                      | Members vote on a general governance proposal.                               |
 * | getGeneralProposalStatus  | `uint256 _proposalId`                     | `ProposalStatus`     | Returns the status of a general governance proposal.                           |
 * | executeProposal           | `uint256 _proposalId`                     |                      | Owner/Admin executes an approved general governance proposal.                 |
 * | depositFunds              |                                           |                      | Allows anyone to deposit funds into the DAAC treasury.                        |
 * | createWithdrawalProposal  | `uint256 _amount`                         | `uint256`            | Members propose to withdraw funds from the treasury. Returns proposal ID.      |
 * | voteOnWithdrawalProposal  | `uint256 _proposalId`, `bool _vote`       |                      | Members vote on a withdrawal proposal.                                     |
 * | getWithdrawalProposalStatus| `uint256 _proposalId`                     | `ProposalStatus`     | Returns the status of a withdrawal proposal.                                 |
 * | getTreasuryBalance        |                                           | `uint256`            | Returns the current balance of the DAAC treasury.                             |
 * | pauseContract             |                                           |                      | Owner/Admin pauses the contract functionality.                               |
 * | unpauseContract           |                                           |                      | Owner/Admin unpauses the contract functionality.                             |
 * | setVotingPeriod           | `uint256 _votingPeriodBlocks`            |                      | Owner/Admin sets the voting period for proposals in blocks.                   |
 * | setQuorum                 | `uint256 _quorumPercentage`              |                      | Owner/Admin sets the quorum percentage for proposals to pass.                  |
 * | getContractVersion        |                                           | `string memory`      | Returns the version of the smart contract.                                    |
 */
contract DecentralizedAutonomousArtCollective {
    // Contract Version
    string public constant VERSION = "1.0.0";

    // Enums
    enum ProposalStatus { Pending, Approved, Rejected }

    // Structs
    struct ArtProposal {
        string metadataURI;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct MetadataUpdateProposal {
        uint256 nftId;
        string newMetadataURI;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct GeneralProposal {
        string description;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
        bool executed;
    }

    struct WithdrawalProposal {
        uint256 amount;
        ProposalStatus status;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    // State Variables
    address public owner;
    mapping(address => bool) public members;
    mapping(address => bool) public pendingMembers;
    address[] public memberList;

    mapping(uint256 => ArtProposal) public artProposals;
    uint256 public artProposalCount;

    mapping(uint256 => MetadataUpdateProposal) public metadataUpdateProposals;
    uint256 public metadataUpdateProposalCount;

    mapping(uint256 => GeneralProposal) public generalProposals;
    uint256 public generalProposalCount;

    mapping(uint256 => WithdrawalProposal) public withdrawalProposals;
    uint256 public withdrawalProposalCount;

    mapping(uint256 => string) public artNFTMetadataURIs;
    uint256 public artNFTCount;
    string public baseMetadataURI;

    uint256 public votingPeriodBlocks = 100; // Default voting period in blocks
    uint256 public quorumPercentage = 50; // Default quorum percentage (50%)

    bool public paused = false;

    // Events
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRejected(address indexed member);
    event MembershipRevoked(address indexed member);
    event ArtProposalSubmitted(uint256 proposalId, address indexed proposer, string metadataURI);
    event ArtProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event ArtProposalStatusUpdated(uint256 proposalId, ProposalStatus status);
    event ArtNFTMinted(uint256 nftId, uint256 proposalId, address indexed minter, string metadataURI);
    event BaseMetadataURISet(string baseURI);
    event MetadataUpdateProposalSubmitted(uint256 proposalId, uint256 nftId, address indexed proposer, string newMetadataURI);
    event MetadataUpdateProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event MetadataUpdateProposalStatusUpdated(uint256 proposalId, ProposalStatus status);
    event GeneralProposalCreated(uint256 proposalId, address indexed proposer, string description);
    event GeneralProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event GeneralProposalStatusUpdated(uint256 proposalId, ProposalStatus status);
    event GeneralProposalExecuted(uint256 proposalId);
    event FundsDeposited(address indexed depositor, uint256 amount);
    event WithdrawalProposalCreated(uint256 proposalId, address indexed proposer, uint256 amount);
    event WithdrawalProposalVoted(uint256 proposalId, address indexed voter, bool vote);
    event WithdrawalProposalStatusUpdated(uint256 proposalId, ProposalStatus status);
    event ContractPaused();
    event ContractUnpaused();
    event VotingPeriodSet(uint256 votingPeriodBlocks);
    event QuorumSet(uint256 quorumPercentage);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
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

    // Constructor
    constructor() {
        owner = msg.sender;
    }

    // ------------------------------------------------------------------------
    // 1. Membership Management
    // ------------------------------------------------------------------------

    /// @notice Allows anyone to request membership to the DAAC.
    function requestMembership() external whenNotPaused {
        require(!members[msg.sender], "Already a member.");
        require(!pendingMembers[msg.sender], "Membership request already pending.");
        pendingMembers[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Owner/Admin approves a pending membership request.
    /// @param _member Address of the member to approve.
    function approveMembership(address _member) external onlyOwner whenNotPaused {
        require(pendingMembers[_member], "No pending membership request.");
        require(!members[_member], "Already a member.");
        pendingMembers[_member] = false;
        members[_member] = true;
        memberList.push(_member);
        emit MembershipApproved(_member);
    }

    /// @notice Owner/Admin rejects a pending membership request.
    /// @param _member Address of the member to reject.
    function rejectMembership(address _member) external onlyOwner whenNotPaused {
        require(pendingMembers[_member], "No pending membership request.");
        pendingMembers[_member] = false;
        emit MembershipRejected(_member);
    }

    /// @notice Owner/Admin revokes membership from an existing member.
    /// @param _member Address of the member to revoke.
    function revokeMembership(address _member) external onlyOwner whenNotPaused {
        require(members[_member], "Not a member.");
        members[_member] = false;
        // Remove from memberList (more gas efficient to just set to address(0) and handle in iteration if needed)
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = address(0); // Mark for removal, doesn't reorder array
                break;
            }
        }
        emit MembershipRevoked(_member);
    }

    /// @notice Returns the total number of members in the DAAC.
    /// @return Total member count.
    function getMemberCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint i = 0; i < memberList.length; i++) {
            if (memberList[i] != address(0)) { // Count only active members
                count++;
            }
        }
        return count;
    }

    /// @notice Checks if an address is a member of the DAAC.
    /// @param _address Address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _address) external view returns (bool) {
        return members[_address];
    }

    // ------------------------------------------------------------------------
    // 2. Art Proposal Submission & Voting
    // ------------------------------------------------------------------------

    /// @notice Members submit art proposals with metadata URI. Returns proposal ID.
    /// @param _metadataURI URI pointing to the art metadata.
    /// @return Proposal ID.
    function submitArtProposal(string memory _metadataURI) external onlyMember whenNotPaused returns (uint256) {
        artProposalCount++;
        artProposals[artProposalCount] = ArtProposal({
            metadataURI: _metadataURI,
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.number + votingPeriodBlocks
        });
        emit ArtProposalSubmitted(artProposalCount, msg.sender, _metadataURI);
        return artProposalCount;
    }

    /// @notice Members vote on an art proposal (true for approve, false for reject).
    /// @param _proposalId ID of the art proposal.
    /// @param _vote Boolean vote (true for yes, false for no).
    function voteOnArtProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(artProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.number <= artProposals[_proposalId].votingEndTime, "Voting period has ended.");

        if (_vote) {
            artProposals[_proposalId].yesVotes++;
        } else {
            artProposals[_proposalId].noVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended or quorum reached for approval
        if (block.number >= artProposals[_proposalId].votingEndTime) {
            _finalizeArtProposal(_proposalId);
        } else {
            _checkQuorumArtProposal(_proposalId);
        }
    }

    /// @notice Returns the current status of an art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return Proposal status (Pending, Approved, Rejected).
    function getArtProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    /// @notice Returns the yes and no vote counts for an art proposal.
    /// @param _proposalId ID of the art proposal.
    /// @return Yes votes, No votes.
    function getArtProposalVotes(uint256 _proposalId) external view returns (uint256, uint256) {
        return (artProposals[_proposalId].yesVotes, artProposals[_proposalId].noVotes);
    }

    // ------------------------------------------------------------------------
    // 3. NFT Minting & Management
    // ------------------------------------------------------------------------

    /// @notice Mints an NFT for an approved art proposal. Returns NFT ID.
    /// @param _proposalId ID of the approved art proposal.
    /// @return NFT ID.
    function mintArtNFT(uint256 _proposalId) external onlyOwner whenNotPaused returns (uint256) {
        require(artProposals[_proposalId].status == ProposalStatus.Approved, "Proposal is not approved.");

        artNFTCount++;
        artNFTMetadataURIs[artNFTCount] = string(abi.encodePacked(baseMetadataURI, "/", Strings.toString(artNFTCount))); // Construct metadata URI
        emit ArtNFTMinted(artNFTCount, _proposalId, msg.sender, artNFTMetadataURIs[artNFTCount]);
        return artNFTCount;
    }

    /// @notice Owner/Admin sets the base URI for all minted NFTs.
    /// @param _baseURI Base URI string.
    function setBaseMetadataURI(string memory _baseURI) external onlyOwner whenNotPaused {
        baseMetadataURI = _baseURI;
        emit BaseMetadataURISet(_baseURI);
    }

    /// @notice Returns the metadata URI for a specific art NFT.
    /// @param _nftId ID of the art NFT.
    /// @return Metadata URI string.
    function getArtNFTMetadataURI(uint256 _nftId) external view returns (string memory) {
        return artNFTMetadataURIs[_nftId];
    }

    /// @notice Members propose updates to an existing NFT's metadata. Returns proposal ID.
    /// @param _nftId ID of the NFT to update.
    /// @param _newMetadataURI New metadata URI.
    /// @return Proposal ID.
    function updateArtMetadataProposal(uint256 _nftId, string memory _newMetadataURI) external onlyMember whenNotPaused returns (uint256) {
        require(artNFTMetadataURIs[_nftId].length > 0, "NFT ID does not exist."); // Simple check if NFT exists

        metadataUpdateProposalCount++;
        metadataUpdateProposals[metadataUpdateProposalCount] = MetadataUpdateProposal({
            nftId: _nftId,
            newMetadataURI: _newMetadataURI,
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.number + votingPeriodBlocks
        });
        emit MetadataUpdateProposalSubmitted(metadataUpdateProposalCount, _nftId, msg.sender, _newMetadataURI);
        return metadataUpdateProposalCount;
    }

    /// @notice Members vote on a metadata update proposal.
    /// @param _proposalId ID of the metadata update proposal.
    /// @param _vote Boolean vote (true for yes, false for no).
    function voteOnMetadataProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(metadataUpdateProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.number <= metadataUpdateProposals[_proposalId].votingEndTime, "Voting period has ended.");

        if (_vote) {
            metadataUpdateProposals[_proposalId].yesVotes++;
        } else {
            metadataUpdateProposals[_proposalId].noVotes++;
        }
        emit MetadataUpdateProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended or quorum reached for approval
        if (block.number >= metadataUpdateProposals[_proposalId].votingEndTime) {
            _finalizeMetadataUpdateProposal(_proposalId);
        } else {
            _checkQuorumMetadataUpdateProposal(_proposalId);
        }
    }

    /// @notice Returns the status of a metadata update proposal.
    /// @param _proposalId ID of the metadata update proposal.
    /// @return Proposal status (Pending, Approved, Rejected).
    function getMetadataProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        return metadataUpdateProposals[_proposalId].status;
    }


    // ------------------------------------------------------------------------
    // 4. DAO Governance & Proposals
    // ------------------------------------------------------------------------

    /// @notice Members create general governance proposals. Returns proposal ID.
    /// @param _description Description of the proposal.
    /// @return Proposal ID.
    function createGeneralProposal(string memory _description) external onlyMember whenNotPaused returns (uint256) {
        generalProposalCount++;
        generalProposals[generalProposalCount] = GeneralProposal({
            description: _description,
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.number + votingPeriodBlocks,
            executed: false
        });
        emit GeneralProposalCreated(generalProposalCount, msg.sender, _description);
        return generalProposalCount;
    }

    /// @notice Members vote on a general governance proposal.
    /// @param _proposalId ID of the general proposal.
    /// @param _vote Boolean vote (true for yes, false for no).
    function voteOnGeneralProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(generalProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.number <= generalProposals[_proposalId].votingEndTime, "Voting period has ended.");

        if (_vote) {
            generalProposals[_proposalId].yesVotes++;
        } else {
            generalProposals[_proposalId].noVotes++;
        }
        emit GeneralProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended or quorum reached for approval
        if (block.number >= generalProposals[_proposalId].votingEndTime) {
            _finalizeGeneralProposal(_proposalId);
        } else {
            _checkQuorumGeneralProposal(_proposalId);
        }
    }

    /// @notice Returns the status of a general governance proposal.
    /// @param _proposalId ID of the general proposal.
    /// @return Proposal status (Pending, Approved, Rejected).
    function getGeneralProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        return generalProposals[_proposalId].status;
    }

    /// @notice Owner/Admin executes an approved general governance proposal.
    /// @param _proposalId ID of the general proposal.
    function executeProposal(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(generalProposals[_proposalId].status == ProposalStatus.Approved, "Proposal is not approved.");
        require(!generalProposals[_proposalId].executed, "Proposal already executed.");
        generalProposals[_proposalId].executed = true;
        emit GeneralProposalExecuted(_proposalId);
        // Add logic here to execute the proposal's intent based on description if needed.
        // For complex proposals, consider using external execution mechanisms or delegates.
    }

    // ------------------------------------------------------------------------
    // 5. Treasury Management
    // ------------------------------------------------------------------------

    /// @notice Allows anyone to deposit funds into the DAAC treasury.
    function depositFunds() external payable whenNotPaused {
        emit FundsDeposited(msg.sender, msg.value);
    }

    /// @notice Members propose to withdraw funds from the treasury. Returns proposal ID.
    /// @param _amount Amount to withdraw in wei.
    /// @return Proposal ID.
    function createWithdrawalProposal(uint256 _amount) external onlyMember whenNotPaused returns (uint256) {
        require(_amount <= address(this).balance, "Insufficient treasury balance.");
        withdrawalProposalCount++;
        withdrawalProposals[withdrawalProposalCount] = WithdrawalProposal({
            amount: _amount,
            status: ProposalStatus.Pending,
            yesVotes: 0,
            noVotes: 0,
            votingEndTime: block.number + votingPeriodBlocks
        });
        emit WithdrawalProposalCreated(withdrawalProposalCount, msg.sender, _amount);
        return withdrawalProposalCount;
    }

    /// @notice Members vote on a withdrawal proposal.
    /// @param _proposalId ID of the withdrawal proposal.
    /// @param _vote Boolean vote (true for yes, false for no).
    function voteOnWithdrawalProposal(uint256 _proposalId, bool _vote) external onlyMember whenNotPaused {
        require(withdrawalProposals[_proposalId].status == ProposalStatus.Pending, "Proposal is not pending.");
        require(block.number <= withdrawalProposals[_proposalId].votingEndTime, "Voting period has ended.");

        if (_vote) {
            withdrawalProposals[_proposalId].yesVotes++;
        } else {
            withdrawalProposals[_proposalId].noVotes++;
        }
        emit WithdrawalProposalVoted(_proposalId, msg.sender, _vote);

        // Check if voting period ended or quorum reached for approval
        if (block.number >= withdrawalProposals[_proposalId].votingEndTime) {
            _finalizeWithdrawalProposal(_proposalId);
        } else {
            _checkQuorumWithdrawalProposal(_proposalId);
        }
    }

    /// @notice Returns the status of a withdrawal proposal.
    /// @param _proposalId ID of the withdrawal proposal.
    /// @return Proposal status (Pending, Approved, Rejected).
    function getWithdrawalProposalStatus(uint256 _proposalId) external view returns (ProposalStatus) {
        return withdrawalProposals[_proposalId].status;
    }

    /// @notice Returns the current balance of the DAAC treasury.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // ------------------------------------------------------------------------
    // 6. Utility & Admin Functions
    // ------------------------------------------------------------------------

    /// @notice Owner/Admin pauses the contract functionality.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Owner/Admin unpauses the contract functionality.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Owner/Admin sets the voting period for proposals in blocks.
    /// @param _votingPeriodBlocks Voting period in blocks.
    function setVotingPeriod(uint256 _votingPeriodBlocks) external onlyOwner whenNotPaused {
        require(_votingPeriodBlocks > 0, "Voting period must be greater than 0.");
        votingPeriodBlocks = _votingPeriodBlocks;
        emit VotingPeriodSet(_votingPeriodBlocks);
    }

    /// @notice Owner/Admin sets the quorum percentage for proposals to pass.
    /// @param _quorumPercentage Quorum percentage (e.g., 50 for 50%).
    function setQuorum(uint256 _quorumPercentage) external onlyOwner whenNotPaused {
        require(_quorumPercentage <= 100, "Quorum percentage must be <= 100.");
        quorumPercentage = _quorumPercentage;
        emit QuorumSet(_quorumPercentage);
    }

    /// @notice Returns the version of the smart contract.
    /// @return Contract version string.
    function getContractVersion() external pure returns (string memory) {
        return VERSION;
    }

    // ------------------------------------------------------------------------
    // Internal Helper Functions
    // ------------------------------------------------------------------------

    /// @dev Finalizes an art proposal after voting period ends or quorum is reached.
    /// @param _proposalId ID of the art proposal.
    function _finalizeArtProposal(uint256 _proposalId) internal {
        if (artProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (artProposals[_proposalId].yesVotes >= quorumVotesNeeded && artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
                artProposals[_proposalId].status = ProposalStatus.Approved;
            } else {
                artProposals[_proposalId].status = ProposalStatus.Rejected;
            }
            emit ArtProposalStatusUpdated(_proposalId, artProposals[_proposalId].status);
        }
    }

    /// @dev Checks if quorum is reached for an art proposal and finalizes if so.
    /// @param _proposalId ID of the art proposal.
    function _checkQuorumArtProposal(uint256 _proposalId) internal {
        if (artProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (artProposals[_proposalId].yesVotes >= quorumVotesNeeded && artProposals[_proposalId].yesVotes > artProposals[_proposalId].noVotes) {
                artProposals[_proposalId].status = ProposalStatus.Approved;
                emit ArtProposalStatusUpdated(_proposalId, artProposals[_proposalId].status);
            } else if (artProposals[_proposalId].yesVotes + artProposals[_proposalId].noVotes >= totalMembers) { // All members voted, reject if not approved
                artProposals[_proposalId].status = ProposalStatus.Rejected;
                emit ArtProposalStatusUpdated(_proposalId, artProposals[_proposalId].status);
            }
        }
    }

    /// @dev Finalizes a metadata update proposal after voting period ends or quorum is reached.
    /// @param _proposalId ID of the metadata update proposal.
    function _finalizeMetadataUpdateProposal(uint256 _proposalId) internal {
        if (metadataUpdateProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (metadataUpdateProposals[_proposalId].yesVotes >= quorumVotesNeeded && metadataUpdateProposals[_proposalId].yesVotes > metadataUpdateProposals[_proposalId].noVotes) {
                metadataUpdateProposals[_proposalId].status = ProposalStatus.Approved;
                artNFTMetadataURIs[metadataUpdateProposals[_proposalId].nftId] = metadataUpdateProposals[_proposalId].newMetadataURI; // Update metadata URI
            } else {
                metadataUpdateProposals[_proposalId].status = ProposalStatus.Rejected;
            }
            emit MetadataUpdateProposalStatusUpdated(_proposalId, metadataUpdateProposals[_proposalId].status);
        }
    }

    /// @dev Checks if quorum is reached for a metadata update proposal and finalizes if so.
    /// @param _proposalId ID of the metadata update proposal.
    function _checkQuorumMetadataUpdateProposal(uint256 _proposalId) internal {
        if (metadataUpdateProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (metadataUpdateProposals[_proposalId].yesVotes >= quorumVotesNeeded && metadataUpdateProposals[_proposalId].yesVotes > metadataUpdateProposals[_proposalId].noVotes) {
                metadataUpdateProposals[_proposalId].status = ProposalStatus.Approved;
                artNFTMetadataURIs[metadataUpdateProposals[_proposalId].nftId] = metadataUpdateProposals[_proposalId].newMetadataURI; // Update metadata URI
                emit MetadataUpdateProposalStatusUpdated(_proposalId, metadataUpdateProposals[_proposalId].status);
            } else if (metadataUpdateProposals[_proposalId].yesVotes + metadataUpdateProposals[_proposalId].noVotes >= totalMembers) { // All members voted, reject if not approved
                metadataUpdateProposals[_proposalId].status = ProposalStatus.Rejected;
                emit MetadataUpdateProposalStatusUpdated(_proposalId, metadataUpdateProposals[_proposalId].status);
            }
        }
    }

    /// @dev Finalizes a general proposal after voting period ends or quorum is reached.
    /// @param _proposalId ID of the general proposal.
    function _finalizeGeneralProposal(uint256 _proposalId) internal {
        if (generalProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (generalProposals[_proposalId].yesVotes >= quorumVotesNeeded && generalProposals[_proposalId].yesVotes > generalProposals[_proposalId].noVotes) {
                generalProposals[_proposalId].status = ProposalStatus.Approved;
            } else {
                generalProposals[_proposalId].status = ProposalStatus.Rejected;
            }
            emit GeneralProposalStatusUpdated(_proposalId, generalProposals[_proposalId].status);
        }
    }

    /// @dev Checks if quorum is reached for a general proposal and finalizes if so.
    /// @param _proposalId ID of the general proposal.
    function _checkQuorumGeneralProposal(uint256 _proposalId) internal {
        if (generalProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (generalProposals[_proposalId].yesVotes >= quorumVotesNeeded && generalProposals[_proposalId].yesVotes > generalProposals[_proposalId].noVotes) {
                generalProposals[_proposalId].status = ProposalStatus.Approved;
                emit GeneralProposalStatusUpdated(_proposalId, generalProposals[_proposalId].status);
            } else if (generalProposals[_proposalId].yesVotes + generalProposals[_proposalId].noVotes >= totalMembers) { // All members voted, reject if not approved
                generalProposals[_proposalId].status = ProposalStatus.Rejected;
                emit GeneralProposalStatusUpdated(_proposalId, generalProposals[_proposalId].status);
            }
        }
    }

     /// @dev Finalizes a withdrawal proposal after voting period ends or quorum is reached.
    /// @param _proposalId ID of the withdrawal proposal.
    function _finalizeWithdrawalProposal(uint256 _proposalId) internal {
        if (withdrawalProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (withdrawalProposals[_proposalId].yesVotes >= quorumVotesNeeded && withdrawalProposals[_proposalId].yesVotes > withdrawalProposals[_proposalId].noVotes) {
                withdrawalProposals[_proposalId].status = ProposalStatus.Approved;
                // Transfer funds only if approved and contract has enough balance (double check for security)
                if (address(this).balance >= withdrawalProposals[_proposalId].amount) {
                    payable(owner).transfer(withdrawalProposals[_proposalId].amount); // In real scenario, target address would be part of proposal
                } else {
                    withdrawalProposals[_proposalId].status = ProposalStatus.Rejected; // Reject if not enough balance at finalization
                }

            } else {
                withdrawalProposals[_proposalId].status = ProposalStatus.Rejected;
            }
            emit WithdrawalProposalStatusUpdated(_proposalId, withdrawalProposals[_proposalId].status);
        }
    }

    /// @dev Checks if quorum is reached for a withdrawal proposal and finalizes if so.
    /// @param _proposalId ID of the withdrawal proposal.
    function _checkQuorumWithdrawalProposal(uint256 _proposalId) internal {
        if (withdrawalProposals[_proposalId].status == ProposalStatus.Pending) { // Ensure it's still pending
            uint256 totalMembers = getMemberCount();
            uint256 quorumVotesNeeded = (totalMembers * quorumPercentage) / 100;

            if (withdrawalProposals[_proposalId].yesVotes >= quorumVotesNeeded && withdrawalProposals[_proposalId].yesVotes > withdrawalProposals[_proposalId].noVotes) {
                withdrawalProposals[_proposalId].status = ProposalStatus.Approved;
                 // Transfer funds only if approved and contract has enough balance (double check for security)
                if (address(this).balance >= withdrawalProposals[_proposalId].amount) {
                    payable(owner).transfer(withdrawalProposals[_proposalId].amount); // In real scenario, target address would be part of proposal
                } else {
                    withdrawalProposals[_proposalId].status = ProposalStatus.Rejected; // Reject if not enough balance during quorum check too
                }
                emit WithdrawalProposalStatusUpdated(_proposalId, withdrawalProposals[_proposalId].status);
            } else if (withdrawalProposals[_proposalId].yesVotes + withdrawalProposals[_proposalId].noVotes >= totalMembers) { // All members voted, reject if not approved
                withdrawalProposals[_proposalId].status = ProposalStatus.Rejected;
                emit WithdrawalProposalStatusUpdated(_proposalId, withdrawalProposals[_proposalId].status);
            }
        }
    }
}

// --- Library for uint256 to string conversion (optional, but helpful for metadata URI construction) ---
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x0";
        }
        bytes memory buffer = new bytes(64);
        uint256 cursor = 64;
        while (value != 0) {
            cursor--;
            buffer[cursor] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        while (cursor > 0 && buffer[cursor] == bytes1(uint8(48))) {
            cursor++;
        }
        bytes memory result = new bytes(66 - cursor);
        result[0] = '0';
        result[1] = 'x';
        for (uint256 i = 0; i < result.length - 2; i++) {
            result[i + 2] = buffer[cursor + i];
        }
        return string(result);
    }

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)));
    }
}
```