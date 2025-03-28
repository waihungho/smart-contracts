```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective, enabling collaborative art creation, ownership, and governance.
 *
 * Outline and Function Summary:
 *
 * 1. **Membership Management:**
 *    - `joinCollective()`: Allows users to request membership to the art collective.
 *    - `approveMembership(address _user)`: Admin function to approve a pending membership request.
 *    - `revokeMembership(address _member)`: Admin function to remove a member from the collective.
 *    - `isMember(address _user)`: Checks if an address is a member of the collective.
 *    - `getMemberCount()`: Returns the total number of members in the collective.
 *    - `getPendingMembers()`: Returns a list of addresses with pending membership requests (admin only).
 *
 * 2. **Art Proposal and Creation:**
 *    - `submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash)`: Members can submit proposals for new art pieces.
 *    - `voteOnProposal(uint256 _proposalId, bool _vote)`: Members can vote on active art proposals (simple yes/no).
 *    - `executeArtProposal(uint256 _proposalId)`: Admin/DAO function to execute an approved art proposal, minting an NFT.
 *    - `getProposalDetails(uint256 _proposalId)`: Retrieves details of a specific art proposal.
 *    - `getProposalStatus(uint256 _proposalId)`: Retrieves the status of a specific art proposal (pending, active, approved, rejected, executed).
 *    - `getActiveProposals()`: Returns a list of IDs of currently active art proposals.
 *
 * 3. **Art Management and Ownership:**
 *    - `mintCollaborativeNFT(string memory _metadataURI)`: (Internal, called after proposal execution) Mints a collaborative NFT for the collective.
 *    - `setArtPrice(uint256 _artId, uint256 _price)`: Admin/DAO function to set the price of a collective art piece for sale.
 *    - `buyArt(uint256 _artId)`: Allows users to purchase collective art pieces, funds go to the collective treasury.
 *    - `transferArtOwnership(uint256 _artId, address _newOwner)`: Admin/DAO function to transfer ownership of a collective art piece (e.g., for collaborations or special events).
 *    - `getArtDetails(uint256 _artId)`: Retrieves details of a specific collective art piece (metadata, price, owner).
 *    - `listAvailableArt()`: Returns a list of IDs of art pieces currently available for sale.
 *
 * 4. **Collective Treasury and Funding:**
 *    - `depositToTreasury()`: Allows members or anyone to deposit funds (ETH) into the collective treasury.
 *    - `withdrawFromTreasury(uint256 _amount)`: Admin/DAO function to withdraw funds from the treasury for collective purposes (requires DAO vote in a real-world scenario).
 *    - `getTreasuryBalance()`: Returns the current balance of the collective treasury.
 *
 * 5. **Governance and Settings:**
 *    - `setVotingDuration(uint256 _durationInBlocks)`: Admin function to set the voting duration for proposals.
 *    - `setQuorum(uint256 _quorumPercentage)`: Admin function to set the quorum percentage required for proposal approval.
 *    - `getVotingDuration()`: Returns the current voting duration.
 *    - `getQuorum()`: Returns the current quorum percentage.
 *    - `pauseContract()`: Admin function to pause all non-essential contract functions.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 */

contract DecentralizedArtCollective {
    // ** State Variables **

    address public admin; // Contract administrator
    mapping(address => bool) public members; // Mapping of members
    mapping(address => bool) public pendingMemberships; // Mapping of pending membership requests
    address[] public memberList; // List of members for iteration
    uint256 public memberCount;

    uint256 public proposalCount;
    mapping(uint256 => ArtProposal) public artProposals; // Mapping of art proposals
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public quorumPercentage = 50; // Default quorum percentage for proposal approval

    uint256 public artPieceCount;
    mapping(uint256 => CollectiveArt) public collectiveArtPieces; // Mapping of collective art pieces

    bool public paused = false; // Contract pause state

    // ** Structs **

    struct ArtProposal {
        string title;
        string description;
        string ipfsHash;
        address proposer;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalStatus status;
    }

    enum ProposalStatus {
        Pending,
        Active,
        Approved,
        Rejected,
        Executed
    }

    struct CollectiveArt {
        string metadataURI;
        address owner; // Initially the contract itself, transferable later
        uint256 price; // Price in wei, 0 if not for sale
        bool forSale;
    }

    // ** Events **

    event MembershipRequested(address indexed user);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event ArtProposalSubmitted(uint256 proposalId, address indexed proposer, string title);
    event ProposalVoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event ArtProposalExecuted(uint256 indexed proposalId, uint256 artId);
    event ArtPriceSet(uint256 indexed artId, uint256 price);
    event ArtPurchased(uint256 indexed artId, address indexed buyer, uint256 price);
    event ArtOwnershipTransferred(uint256 indexed artId, address indexed oldOwner, address indexed newOwner);
    event TreasuryDeposit(address indexed depositor, uint256 amount);
    event TreasuryWithdrawal(address indexed recipient, uint256 amount);
    event ContractPaused(address indexed admin);
    event ContractUnpaused(address indexed admin);

    // ** Modifiers **

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier validProposal(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID.");
        _;
    }

    modifier validArtId(uint256 _artId) {
        require(_artId > 0 && _artId <= artPieceCount, "Invalid art ID.");
        _;
    }


    // ** Constructor **

    constructor() {
        admin = msg.sender;
        memberCount = 0;
    }

    // ** 1. Membership Management Functions **

    /// @notice Allows users to request membership to the art collective.
    function joinCollective() external notPaused {
        require(!members[msg.sender], "Already a member.");
        require(!pendingMemberships[msg.sender], "Membership request already pending.");
        pendingMemberships[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Admin function to approve a pending membership request.
    /// @param _user The address to approve for membership.
    function approveMembership(address _user) external onlyAdmin notPaused {
        require(pendingMemberships[_user], "No pending membership request for this address.");
        require(!members[_user], "Address is already a member.");
        members[_user] = true;
        pendingMemberships[_user] = false;
        memberList.push(_user);
        memberCount++;
        emit MembershipApproved(_user);
    }

    /// @notice Admin function to remove a member from the collective.
    /// @param _member The address of the member to revoke membership from.
    function revokeMembership(address _member) external onlyAdmin notPaused {
        require(members[_member], "Address is not a member.");
        members[_member] = false;
        // Remove from memberList - inefficient for large lists, consider optimization if needed in real-world
        for (uint256 i = 0; i < memberList.length; i++) {
            if (memberList[i] == _member) {
                memberList[i] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
        memberCount--;
        emit MembershipRevoked(_member);
    }

    /// @notice Checks if an address is a member of the collective.
    /// @param _user The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _user) external view returns (bool) {
        return members[_user];
    }

    /// @notice Returns the total number of members in the collective.
    /// @return The member count.
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    /// @notice Returns a list of addresses with pending membership requests (admin only).
    /// @return An array of pending member addresses.
    function getPendingMembers() external view onlyAdmin returns (address[] memory) {
        address[] memory pending = new address[](countPendingMembers());
        uint256 index = 0;
        for (uint256 i = 0; i < memberList.length + countPendingMembers(); i++) { // Iterate through all potential users
            if (pendingMemberships[address(uint160(i))]) { // This is a placeholder iteration - improve in real use case
                pending[index] = address(uint160(i)); // Placeholder address assignment
                index++;
            }
        }
        return pending;
    }

    function countPendingMembers() private view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < memberList.length + 100; i++) { // Placeholder iteration range - improve in real use case
            if (pendingMemberships[address(uint160(i))]) {
                count++;
            }
        }
        return count;
    }


    // ** 2. Art Proposal and Creation Functions **

    /// @notice Members can submit proposals for new art pieces.
    /// @param _title The title of the art proposal.
    /// @param _description A brief description of the art proposal.
    /// @param _ipfsHash IPFS hash linking to a more detailed proposal description or art concept.
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash) external onlyMember notPaused {
        proposalCount++;
        artProposals[proposalCount] = ArtProposal({
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            proposer: msg.sender,
            startTime: block.number,
            endTime: block.number + votingDurationBlocks,
            yesVotes: 0,
            noVotes: 0,
            status: ProposalStatus.Active
        });
        emit ArtProposalSubmitted(proposalCount, msg.sender, _title);
    }

    /// @notice Members can vote on active art proposals (simple yes/no).
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes, false for no.
    function voteOnProposal(uint256 _proposalId, bool _vote) external onlyMember notPaused validProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Active, "Proposal is not active.");
        require(block.number <= proposal.endTime, "Voting period has ended.");

        // Simple voting - in a real DAO, consider more sophisticated voting mechanisms and preventing double voting
        if (_vote) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoteCast(_proposalId, msg.sender, _vote);

        // Check if voting period ended and update status
        if (block.number > proposal.endTime) {
            _finalizeProposal(_proposalId);
        }
    }

    /// @notice Admin/DAO function to execute an approved art proposal, minting an NFT.
    /// @param _proposalId The ID of the approved art proposal.
    function executeArtProposal(uint256 _proposalId) external onlyAdmin notPaused validProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.status == ProposalStatus.Approved, "Proposal is not approved.");
        proposal.status = ProposalStatus.Executed;

        // Mint the collaborative NFT
        uint256 artId = mintCollaborativeNFT(proposal.ipfsHash); // Use IPFS hash from proposal as metadata URI
        emit ArtProposalExecuted(_proposalId, artId);
    }

    /// @notice Retrieves details of a specific art proposal.
    /// @param _proposalId The ID of the proposal to retrieve.
    /// @return ArtProposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view validProposal(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Retrieves the status of a specific art proposal.
    /// @param _proposalId The ID of the proposal to check.
    /// @return The ProposalStatus enum value.
    function getProposalStatus(uint256 _proposalId) external view validProposal(_proposalId) returns (ProposalStatus) {
        return artProposals[_proposalId].status;
    }

    /// @notice Returns a list of IDs of currently active art proposals.
    /// @return An array of active proposal IDs.
    function getActiveProposals() external view returns (uint256[] memory) {
        uint256[] memory activeProposalIds = new uint256[](proposalCount); // Max size, will trim later
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (artProposals[i].status == ProposalStatus.Active) {
                activeProposalIds[activeCount] = i;
                activeCount++;
            }
        }
        // Trim array to actual active proposals
        assembly {
            mstore(activeProposalIds, activeCount)
        }
        return activeProposalIds;
    }


    // ** 3. Art Management and Ownership Functions **

    /// @notice (Internal, called after proposal execution) Mints a collaborative NFT for the collective.
    /// @param _metadataURI URI for the NFT metadata.
    /// @return The ID of the newly minted art piece.
    function mintCollaborativeNFT(string memory _metadataURI) private returns (uint256) {
        artPieceCount++;
        collectiveArtPieces[artPieceCount] = CollectiveArt({
            metadataURI: _metadataURI,
            owner: address(this), // Initially owned by the contract itself
            price: 0,
            forSale: false
        });
        return artPieceCount;
    }

    /// @notice Admin/DAO function to set the price of a collective art piece for sale.
    /// @param _artId The ID of the art piece.
    /// @param _price The price in wei.
    function setArtPrice(uint256 _artId, uint256 _price) external onlyAdmin notPaused validArtId(_artId) {
        collectiveArtPieces[_artId].price = _price;
        collectiveArtPieces[_artId].forSale = (_price > 0); // Automatically set forSale if price > 0
        emit ArtPriceSet(_artId, _price);
    }

    /// @notice Allows users to purchase collective art pieces, funds go to the collective treasury.
    /// @param _artId The ID of the art piece to purchase.
    function buyArt(uint256 _artId) external payable notPaused validArtId(_artId) {
        CollectiveArt storage art = collectiveArtPieces[_artId];
        require(art.forSale, "Art piece is not for sale.");
        require(msg.value >= art.price, "Insufficient funds sent.");

        payable(address(this)).transfer(msg.value); // Send funds to contract treasury
        art.owner = msg.sender; // Set new owner to the buyer
        art.forSale = false; // No longer for sale after purchase
        emit ArtPurchased(_artId, msg.sender, art.price);

        // Refund any extra ETH sent
        if (msg.value > art.price) {
            payable(msg.sender).transfer(msg.value - art.price);
        }
    }

    /// @notice Admin/DAO function to transfer ownership of a collective art piece.
    /// @param _artId The ID of the art piece to transfer.
    /// @param _newOwner The address of the new owner.
    function transferArtOwnership(uint256 _artId, address _newOwner) external onlyAdmin notPaused validArtId(_artId) {
        address oldOwner = collectiveArtPieces[_artId].owner;
        collectiveArtPieces[_artId].owner = _newOwner;
        collectiveArtPieces[_artId].forSale = false; // No longer for sale after transfer
        emit ArtOwnershipTransferred(_artId, oldOwner, _newOwner);
    }

    /// @notice Retrieves details of a specific collective art piece.
    /// @param _artId The ID of the art piece to retrieve.
    /// @return CollectiveArt struct containing art piece details.
    function getArtDetails(uint256 _artId) external view validArtId(_artId) returns (CollectiveArt memory) {
        return collectiveArtPieces[_artId];
    }

    /// @notice Returns a list of IDs of art pieces currently available for sale.
    /// @return An array of available art piece IDs.
    function listAvailableArt() external view returns (uint256[] memory) {
        uint256[] memory availableArtIds = new uint256[](artPieceCount); // Max size, will trim later
        uint256 availableCount = 0;
        for (uint256 i = 1; i <= artPieceCount; i++) {
            if (collectiveArtPieces[i].forSale) {
                availableArtIds[availableCount] = i;
                availableCount++;
            }
        }
        // Trim array to actual available art pieces
        assembly {
            mstore(availableArtIds, availableCount)
        }
        return availableArtIds;
    }


    // ** 4. Collective Treasury and Funding Functions **

    /// @notice Allows members or anyone to deposit funds (ETH) into the collective treasury.
    function depositToTreasury() external payable notPaused {
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Admin/DAO function to withdraw funds from the treasury for collective purposes (requires DAO vote in a real-world scenario).
    /// @param _amount The amount of ETH to withdraw in wei.
    function withdrawFromTreasury(uint256 _amount) external onlyAdmin notPaused {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(admin).transfer(_amount); // In a real DAO, this would be a more controlled withdrawal process
        emit TreasuryWithdrawal(admin, _amount);
    }

    /// @notice Returns the current balance of the collective treasury.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }


    // ** 5. Governance and Settings Functions **

    /// @notice Admin function to set the voting duration for proposals.
    /// @param _durationInBlocks The new voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyAdmin notPaused {
        votingDurationBlocks = _durationInBlocks;
    }

    /// @notice Admin function to set the quorum percentage required for proposal approval.
    /// @param _quorumPercentage The new quorum percentage (e.g., 51 for 51%).
    function setQuorum(uint256 _quorumPercentage) external onlyAdmin notPaused {
        require(_quorumPercentage <= 100, "Quorum percentage must be less than or equal to 100.");
        quorumPercentage = _quorumPercentage;
    }

    /// @notice Returns the current voting duration.
    /// @return The voting duration in blocks.
    function getVotingDuration() external view returns (uint256) {
        return votingDurationBlocks;
    }

    /// @notice Returns the current quorum percentage.
    /// @return The quorum percentage.
    function getQuorum() external view returns (uint256) {
        return quorumPercentage;
    }

    /// @notice Admin function to pause all non-essential contract functions.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }


    // ** Internal Helper Functions **

    /// @notice Finalizes a proposal after the voting period ends, determining its status (Approved or Rejected).
    /// @param _proposalId The ID of the proposal to finalize.
    function _finalizeProposal(uint256 _proposalId) private validProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        if (proposal.status == ProposalStatus.Active && block.number > proposal.endTime) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            uint256 quorum = (memberCount * quorumPercentage) / 100; // Calculate quorum based on member count and percentage

            if (totalVotes >= quorum && proposal.yesVotes > proposal.noVotes) {
                proposal.status = ProposalStatus.Approved;
            } else {
                proposal.status = ProposalStatus.Rejected;
            }
        }
    }
}
```