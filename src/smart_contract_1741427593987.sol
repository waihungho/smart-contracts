```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Art Collective (DAAC)
 * that allows artists to submit art proposals, members to vote on them,
 * and the collective to acquire and manage digital art pieces.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core Art Proposal and Voting:**
 *    - `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, uint256 _cost)`: Allows members to submit art proposals with details and a cost.
 *    - `voteOnArtProposal(uint256 _proposalId, bool _vote)`: Allows members to vote for or against an art proposal.
 *    - `getArtProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 *    - `getApprovedArtProposals()`: Returns a list of IDs of approved art proposals.
 *    - `getPendingArtProposals()`: Returns a list of IDs of pending art proposals.
 *    - `cancelArtProposal(uint256 _proposalId)`: Allows the proposer to cancel their art proposal before voting starts.
 *
 * **2. DAO Governance and Membership:**
 *    - `proposeDAOChange(string memory _description, bytes memory _data)`: Allows members to propose changes to the DAO (e.g., voting quorum, membership fee).
 *    - `voteOnDAOChange(uint256 _proposalId, bool _vote)`: Allows members to vote on DAO change proposals.
 *    - `executeDAOChange(uint256 _proposalId)`: Executes an approved DAO change proposal.
 *    - `getDAOProposalDetails(uint256 _proposalId)`: Retrieves details of a specific DAO change proposal.
 *    - `getDAOMembers()`: Returns a list of current DAO members.
 *    - `joinDAO()`: Allows users to join the DAAC by paying a membership fee.
 *    - `leaveDAO()`: Allows members to leave the DAAC and potentially withdraw funds (conditions apply).
 *    - `setMembershipFee(uint256 _newFee)`: Allows the admin to change the membership fee.
 *    - `getMembershipFee()`: Returns the current membership fee.
 *
 * **3. Artist Management and Rewards:**
 *    - `registerArtist(string memory _artistName, string memory _artistBio)`: Allows members to register as artists with a profile.
 *    - `getArtistProfile(address _artistAddress)`: Retrieves the profile of a registered artist.
 *    - `updateArtistProfile(string memory _artistBio)`: Allows artists to update their bio.
 *    - `distributeArtistRewards(uint256 _proposalId)`: Distributes rewards to the artist of an approved art proposal.
 *    - `setArtistRewardPercentage(uint256 _percentage)`: Allows the admin to set the percentage of proposal cost allocated as artist reward.
 *    - `getArtistRewardPercentage()`: Returns the current artist reward percentage.
 *
 * **4. Treasury and Funding:**
 *    - `depositFunds()`: Allows anyone to deposit funds into the DAAC treasury.
 *    - `withdrawFunds(uint256 _amount)`: Allows the admin (or DAO-governed) to withdraw funds from the treasury for collective purposes.
 *    - `getTreasuryBalance()`: Returns the current balance of the DAAC treasury.
 *
 * **5. Utility and Information:**
 *    - `getVersion()`: Returns the contract version.
 *    - `getContractName()`: Returns the name of the contract.
 */

contract DecentralizedAutonomousArtCollective {
    string public contractName = "DecentralizedAutonomousArtCollective";
    string public version = "1.0.0";

    // --- Structs and Enums ---
    enum ProposalStatus { Pending, Approved, Rejected, Cancelled }
    enum ProposalType { Art, DAOChange }

    struct ArtProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        string ipfsHash;
        uint256 cost;
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 voteEndTime;
    }

    struct DAOChangeProposal {
        uint256 id;
        address proposer;
        string description;
        bytes data; // Encoded function call data
        ProposalStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 voteEndTime;
        bool executed;
    }

    struct ArtistProfile {
        bool isRegistered;
        string artistName;
        string artistBio;
    }

    // --- State Variables ---
    uint256 public membershipFee = 0.1 ether; // Initial membership fee
    uint256 public artistRewardPercentage = 70; // Percentage of proposal cost for artist reward
    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public votingQuorumPercentage = 50; // Percentage of members needed to reach quorum
    uint256 public artProposalCounter = 0;
    uint256 public daoProposalCounter = 0;
    address public admin;

    mapping(uint256 => ArtProposal) public artProposals;
    mapping(uint256 => DAOChangeProposal) public daoChangeProposals;
    mapping(address => bool) public isDAOMember;
    mapping(address => ArtistProfile) public artistProfiles;
    address[] public daoMembers;

    // --- Events ---
    event ArtProposalSubmitted(uint256 proposalId, address proposer, string title);
    event ArtProposalVoted(uint256 proposalId, address voter, bool vote);
    event ArtProposalApproved(uint256 proposalId);
    event ArtProposalRejected(uint256 proposalId);
    event ArtProposalCancelled(uint256 proposalId);

    event DAOChangeProposed(uint256 proposalId, address proposer, string description);
    event DAOChangeVoted(uint256 proposalId, address voter, bool vote);
    event DAOChangeApproved(uint256 proposalId);
    event DAOChangeRejected(uint256 proposalId);
    event DAOChangeExecuted(uint256 proposalId);

    event DAOMemberJoined(address memberAddress);
    event DAOMemberLeft(address memberAddress);
    event ArtistRegistered(address artistAddress, string artistName);
    event ArtistProfileUpdated(address artistAddress);
    event FundsDeposited(address depositor, uint256 amount);
    event FundsWithdrawn(address withdrawer, uint256 amount);
    event MembershipFeeChanged(uint256 newFee);
    event ArtistRewardPercentageChanged(uint256 newPercentage);

    // --- Modifiers ---
    modifier onlyDAOMember() {
        require(isDAOMember[msg.sender], "You are not a DAO member.");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier validProposalId(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Art) {
            require(_proposalId > 0 && _proposalId <= artProposalCounter && artProposals[_proposalId].id == _proposalId, "Invalid Art proposal ID.");
        } else if (_proposalType == ProposalType.DAOChange) {
            require(_proposalId > 0 && _proposalId <= daoProposalCounter && daoChangeProposals[_proposalId].id == _proposalId, "Invalid DAO Change proposal ID.");
        } else {
            revert("Invalid proposal type.");
        }
        _;
    }

    modifier onlyProposalProposer(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Art) {
            require(artProposals[_proposalId].proposer == msg.sender, "Only proposer can perform this action.");
        } else if (_proposalType == ProposalType.DAOChange) {
            require(daoChangeProposals[_proposalId].proposer == msg.sender, "Only proposer can perform this action.");
        } else {
            revert("Invalid proposal type.");
        }
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalType _proposalType, ProposalStatus _status) {
        if (_proposalType == ProposalType.Art) {
            require(artProposals[_proposalId].status == _status, "Proposal is not in the required status.");
        } else if (_proposalType == ProposalType.DAOChange) {
            require(daoChangeProposals[_proposalId].status == _status, "Proposal is not in the required status.");
        } else {
            revert("Invalid proposal type.");
        }
        _;
    }

    modifier proposalVotingActive(uint256 _proposalId, ProposalType _proposalType) {
        if (_proposalType == ProposalType.Art) {
            require(block.timestamp <= artProposals[_proposalId].voteEndTime, "Voting period has ended.");
        } else if (_proposalType == ProposalType.DAOChange) {
            require(block.timestamp <= daoChangeProposals[_proposalId].voteEndTime, "Voting period has ended.");
        } else {
            revert("Invalid proposal type.");
        }
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- 1. Core Art Proposal and Voting ---

    function submitArtProposal(
        string memory _title,
        string memory _description,
        string memory _ipfsHash,
        uint256 _cost
    ) public onlyDAOMember {
        artProposalCounter++;
        ArtProposal storage newProposal = artProposals[artProposalCounter];
        newProposal.id = artProposalCounter;
        newProposal.proposer = msg.sender;
        newProposal.title = _title;
        newProposal.description = _description;
        newProposal.ipfsHash = _ipfsHash;
        newProposal.cost = _cost;
        newProposal.status = ProposalStatus.Pending;
        newProposal.voteEndTime = block.timestamp + votingDuration;

        emit ArtProposalSubmitted(artProposalCounter, msg.sender, _title);
    }

    function voteOnArtProposal(uint256 _proposalId, bool _vote)
        public
        onlyDAOMember
        validProposalId(_proposalId, ProposalType.Art)
        proposalInStatus(_proposalId, ProposalType.Art, ProposalStatus.Pending)
        proposalVotingActive(_proposalId, ProposalType.Art)
    {
        if (_vote) {
            artProposals[_proposalId].upVotes++;
        } else {
            artProposals[_proposalId].downVotes++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);
        _checkArtProposalOutcome(_proposalId);
    }

    function _checkArtProposalOutcome(uint256 _proposalId) private {
        if (block.timestamp > artProposals[_proposalId].voteEndTime && artProposals[_proposalId].status == ProposalStatus.Pending) {
            uint256 totalVotes = artProposals[_proposalId].upVotes + artProposals[_proposalId].downVotes;
            if (totalVotes * 100 / daoMembers.length >= votingQuorumPercentage && artProposals[_proposalId].upVotes > artProposals[_proposalId].downVotes) {
                artProposals[_proposalId].status = ProposalStatus.Approved;
                emit ArtProposalApproved(_proposalId);
                _purchaseArt(_proposalId); // Automatically purchase art if approved
            } else {
                artProposals[_proposalId].status = ProposalStatus.Rejected;
                emit ArtProposalRejected(_proposalId);
            }
        }
    }

    function _purchaseArt(uint256 _proposalId) private proposalInStatus(_proposalId, ProposalType.Art, ProposalStatus.Approved) {
        require(address(this).balance >= artProposals[_proposalId].cost, "Contract treasury balance is insufficient to purchase art.");
        payable(artProposals[_proposalId].proposer).transfer(artProposals[_proposalId].cost);
        distributeArtistRewards(_proposalId); // Distribute reward to artist upon purchase (assuming proposer is the artist for now, can be adjusted)
        // In a real application, you might mint an NFT here representing the artwork and manage its ownership within the DAAC.
    }

    function getArtProposalDetails(uint256 _proposalId)
        public
        view
        validProposalId(_proposalId, ProposalType.Art)
        returns (ArtProposal memory)
    {
        return artProposals[_proposalId];
    }

    function getApprovedArtProposals() public view returns (uint256[] memory) {
        uint256[] memory approvedProposals = new uint256[](artProposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= artProposalCounter; i++) {
            if (artProposals[i].status == ProposalStatus.Approved) {
                approvedProposals[count] = i;
                count++;
            }
        }
        // Resize the array to remove empty slots
        assembly {
            mstore(approvedProposals, count)
        }
        return approvedProposals;
    }

    function getPendingArtProposals() public view returns (uint256[] memory) {
        uint256[] memory pendingProposals = new uint256[](artProposalCounter);
        uint256 count = 0;
        for (uint256 i = 1; i <= artProposalCounter; i++) {
            if (artProposals[i].status == ProposalStatus.Pending) {
                pendingProposals[count] = i;
                count++;
            }
        }
        // Resize the array to remove empty slots
        assembly {
            mstore(pendingProposals, count)
        }
        return pendingProposals;
    }

    function cancelArtProposal(uint256 _proposalId)
        public
        onlyProposalProposer(_proposalId, ProposalType.Art)
        validProposalId(_proposalId, ProposalType.Art)
        proposalInStatus(_proposalId, ProposalType.Art, ProposalStatus.Pending)
    {
        artProposals[_proposalId].status = ProposalStatus.Cancelled;
        emit ArtProposalCancelled(_proposalId);
    }

    // --- 2. DAO Governance and Membership ---

    function proposeDAOChange(string memory _description, bytes memory _data) public onlyDAOMember {
        daoProposalCounter++;
        DAOChangeProposal storage newProposal = daoChangeProposals[daoProposalCounter];
        newProposal.id = daoProposalCounter;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.data = _data;
        newProposal.status = ProposalStatus.Pending;
        newProposal.voteEndTime = block.timestamp + votingDuration;
        newProposal.executed = false;

        emit DAOChangeProposed(daoProposalCounter, msg.sender, _description);
    }

    function voteOnDAOChange(uint256 _proposalId, bool _vote)
        public
        onlyDAOMember
        validProposalId(_proposalId, ProposalType.DAOChange)
        proposalInStatus(_proposalId, ProposalType.DAOChange, ProposalStatus.Pending)
        proposalVotingActive(_proposalId, ProposalType.DAOChange)
    {
        if (_vote) {
            daoChangeProposals[_proposalId].upVotes++;
        } else {
            daoChangeProposals[_proposalId].downVotes++;
        }
        emit DAOChangeVoted(_proposalId, msg.sender, _vote);
        _checkDAOChangeProposalOutcome(_proposalId);
    }

    function _checkDAOChangeProposalOutcome(uint256 _proposalId) private {
        if (block.timestamp > daoChangeProposals[_proposalId].voteEndTime && daoChangeProposals[_proposalId].status == ProposalStatus.Pending) {
            uint256 totalVotes = daoChangeProposals[_proposalId].upVotes + daoChangeProposals[_proposalId].downVotes;
            if (totalVotes * 100 / daoMembers.length >= votingQuorumPercentage && daoChangeProposals[_proposalId].upVotes > daoChangeProposals[_proposalId].downVotes) {
                daoChangeProposals[_proposalId].status = ProposalStatus.Approved;
                emit DAOChangeApproved(_proposalId);
            } else {
                daoChangeProposals[_proposalId].status = ProposalStatus.Rejected;
                emit DAOChangeRejected(_proposalId);
            }
        }
    }

    function executeDAOChange(uint256 _proposalId)
        public
        onlyAdmin // For simplicity, only admin can execute, can be DAO-governed in advanced version
        validProposalId(_proposalId, ProposalType.DAOChange)
        proposalInStatus(_proposalId, ProposalType.DAOChange, ProposalStatus.Approved)
    {
        require(!daoChangeProposals[_proposalId].executed, "DAO Change proposal already executed.");
        (bool success, ) = address(this).delegatecall(daoChangeProposals[_proposalId].data); // Delegatecall to execute the proposed change
        require(success, "DAO Change execution failed.");
        daoChangeProposals[_proposalId].executed = true;
        emit DAOChangeExecuted(_proposalId);
    }

    function getDAOProposalDetails(uint256 _proposalId)
        public
        view
        validProposalId(_proposalId, ProposalType.DAOChange)
        returns (DAOChangeProposal memory)
    {
        return daoChangeProposals[_proposalId];
    }

    function getDAOMembers() public view returns (address[] memory) {
        return daoMembers;
    }

    function joinDAO() public payable {
        require(!isDAOMember[msg.sender], "You are already a DAO member.");
        require(msg.value >= membershipFee, "Membership fee is required to join.");
        isDAOMember[msg.sender] = true;
        daoMembers.push(msg.sender);
        emit DAOMemberJoined(msg.sender);
    }

    function leaveDAO() public onlyDAOMember {
        isDAOMember[msg.sender] = false;
        // Remove member from daoMembers array (can be optimized for gas if needed for large member counts)
        for (uint256 i = 0; i < daoMembers.length; i++) {
            if (daoMembers[i] == msg.sender) {
                daoMembers[i] = daoMembers[daoMembers.length - 1];
                daoMembers.pop();
                break;
            }
        }
        emit DAOMemberLeft(msg.sender);
        // Potentially implement logic for partial refund of membership fee based on time in DAO.
    }

    function setMembershipFee(uint256 _newFee) public onlyAdmin {
        membershipFee = _newFee;
        emit MembershipFeeChanged(_newFee);
        // Example DAO Change proposal function: functionData = abi.encodeWithSignature("setMembershipFee(uint256)", _newFee);
    }

    function getMembershipFee() public view returns (uint256) {
        return membershipFee;
    }


    // --- 3. Artist Management and Rewards ---

    function registerArtist(string memory _artistName, string memory _artistBio) public onlyDAOMember {
        require(!artistProfiles[msg.sender].isRegistered, "You are already registered as an artist.");
        artistProfiles[msg.sender] = ArtistProfile({
            isRegistered: true,
            artistName: _artistName,
            artistBio: _artistBio
        });
        emit ArtistRegistered(msg.sender, _artistName);
    }

    function getArtistProfile(address _artistAddress) public view returns (ArtistProfile memory) {
        return artistProfiles[_artistAddress];
    }

    function updateArtistProfile(string memory _artistBio) public onlyDAOMember {
        require(artistProfiles[msg.sender].isRegistered, "You must be registered as an artist to update your profile.");
        artistProfiles[msg.sender].artistBio = _artistBio;
        emit ArtistProfileUpdated(msg.sender);
    }

    function distributeArtistRewards(uint256 _proposalId) internal proposalInStatus(_proposalId, ProposalType.Art, ProposalStatus.Approved) {
        uint256 rewardAmount = (artProposals[_proposalId].cost * artistRewardPercentage) / 100;
        payable(artProposals[_proposalId].proposer).transfer(rewardAmount); // Assuming proposer is artist in this example for simplicity, adjust logic if needed.
        // In a more complex system, artist could be a separate address and rewards distributed accordingly.
    }

    function setArtistRewardPercentage(uint256 _percentage) public onlyAdmin {
        require(_percentage <= 100, "Reward percentage cannot exceed 100.");
        artistRewardPercentage = _percentage;
        emit ArtistRewardPercentageChanged(_percentage);
        // Example DAO Change proposal function: functionData = abi.encodeWithSignature("setArtistRewardPercentage(uint256)", _percentage);
    }

    function getArtistRewardPercentage() public view returns (uint256) {
        return artistRewardPercentage;
    }


    // --- 4. Treasury and Funding ---

    function depositFunds() public payable {
        emit FundsDeposited(msg.sender, msg.value);
    }

    function withdrawFunds(uint256 _amount) public onlyAdmin {
        require(address(this).balance >= _amount, "Insufficient funds in treasury.");
        payable(admin).transfer(_amount); // Admin withdrawal for now, can be DAO-governed in advanced version.
        emit FundsWithdrawn(admin, _amount);
    }

    function getTreasuryBalance() public view returns (uint256) {
        return address(this).balance;
    }


    // --- 5. Utility and Information ---

    function getVersion() public view returns (string memory) {
        return version;
    }

    function getContractName() public view returns (string memory) {
        return contractName;
    }

    // --- Fallback Function (Optional, for receiving Ether directly) ---
    receive() external payable {
        emit FundsDeposited(msg.sender, msg.value);
    }
}
```