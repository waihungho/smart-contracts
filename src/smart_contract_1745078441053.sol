```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev This smart contract implements a Decentralized Autonomous Art Collective (DAAC)
 * with advanced features for art submission, curation, collaborative creation,
 * fractional ownership, dynamic pricing, AI-assisted art generation (conceptual),
 * and community governance.

 * Function Summary:
 * -----------------
 * **Membership & Governance:**
 * 1. joinCollective(): Allows users to request membership to the DAAC.
 * 2. approveMember(address _member): Allows curators to approve pending membership requests.
 * 3. revokeMembership(address _member): Allows curators to revoke membership.
 * 4. proposeNewCurator(address _newCurator): Allows members to propose a new curator.
 * 5. voteOnCuratorProposal(uint _proposalId, bool _vote): Allows members to vote on curator proposals.
 * 6. submitGovernanceProposal(string _title, string _description, bytes _calldata): Allows members to submit governance proposals.
 * 7. voteOnGovernanceProposal(uint _proposalId, bool _vote): Allows members to vote on governance proposals.
 * 8. executeGovernanceProposal(uint _proposalId): Allows curators to execute passed governance proposals.

 * **Art Submission & Curation:**
 * 9. submitArtProposal(string _title, string _description, string _ipfsHash, uint _creationCost): Allows members to submit art proposals.
 * 10. voteOnArtProposal(uint _proposalId, bool _vote): Allows curators to vote on art proposals.
 * 11. mintArtNFT(uint _proposalId): Mints an ArtNFT if the proposal is approved and paid for.
 * 12. setArtPrice(uint _artId, uint _newPrice): Allows the collective to set the price of an ArtNFT.
 * 13. purchaseArtNFT(uint _artId): Allows users to purchase ArtNFTs, splitting revenue.

 * **Collaborative Art & AI Integration (Conceptual):**
 * 14. requestCollaboration(uint _artId): Allows members to request to collaborate on an existing ArtNFT.
 * 15. voteOnCollaborationRequest(uint _requestId, bool _vote): Allows curators to vote on collaboration requests.
 * 16. submitCollaborationContribution(uint _requestId, string _contributionDescription, string _ipfsHash): Allows collaborators to submit contributions.
 * 17. finalizeCollaboration(uint _requestId): Allows curators to finalize a collaboration and update the ArtNFT (conceptual - IPFS update).
 * 18. requestAIArtInspiration(string _prompt): (Conceptual - Off-chain AI integration) Allows members to request AI-generated art inspiration based on a prompt. (Returns a string - for conceptual demonstration, actual AI integration is complex and off-chain).

 * **Treasury & Revenue Management:**
 * 19. depositToTreasury(): Allows anyone to deposit ETH into the DAAC treasury.
 * 20. withdrawFromTreasury(address _recipient, uint _amount): Allows curators to withdraw funds from the treasury for collective expenses (governance vote ideally).
 * 21. getTreasuryBalance(): Returns the current balance of the DAAC treasury.

 * **Utility & Info:**
 * 22. getArtProposalDetails(uint _proposalId): Returns details of an art proposal.
 * 23. getArtNFTDetails(uint _artId): Returns details of an ArtNFT.
 * 24. getMemberDetails(address _member): Returns details of a DAAC member.
 * 25. getGovernanceProposalDetails(uint _proposalId): Returns details of a governance proposal.
 * 26. getCuratorProposalDetails(uint _proposalId): Returns details of a curator proposal.
 * 27. getCollaborationRequestDetails(uint _requestId): Returns details of a collaboration request.
 */
contract DecentralizedAutonomousArtCollective {

    // -------- State Variables --------

    address public owner; // Contract owner (Deployer)
    address[] public curators; // List of curators (initially owner)
    mapping(address => bool) public isCurator; // Check if an address is a curator
    mapping(address => bool) public isMember; // Check if an address is a member
    address[] public members; // List of members

    uint public nextArtProposalId;
    uint public nextArtNFTId;
    uint public nextGovernanceProposalId;
    uint public nextCuratorProposalId;
    uint public nextCollaborationRequestId;

    uint public membershipFee = 0.1 ether; // Fee to join the collective (can be changed by governance)
    uint public artCreationCostBase = 0.05 ether; // Base cost for art creation (can be changed by governance)
    uint public curatorVoteThreshold = 2; // Number of curator votes required for approval (can be changed by governance)
    uint public memberVoteDuration = 7 days; // Duration for member voting (can be changed by governance)

    struct ArtProposal {
        uint id;
        address proposer;
        string title;
        string description;
        string ipfsHash; // IPFS hash of the art piece
        uint creationCost;
        uint votesFor;
        uint votesAgainst;
        bool approved;
        bool paid;
        bool exists;
    }
    mapping(uint => ArtProposal) public artProposals;

    struct ArtNFT {
        uint id;
        uint proposalId;
        address creator;
        string title;
        string description;
        string ipfsHash;
        uint price;
        address owner;
        address[] collaborators; // Addresses of members who collaborated
        bool exists;
    }
    mapping(uint => ArtNFT) public artNFTs;

    struct Member {
        address memberAddress;
        uint joinTimestamp;
        bool isActive;
        bool exists;
    }
    mapping(address => Member) public membersData;

    struct GovernanceProposal {
        uint id;
        address proposer;
        string title;
        string description;
        bytes calldataData; // Calldata to execute if proposal passes
        uint votesFor;
        uint votesAgainst;
        uint startTime;
        uint endTime;
        bool passed;
        bool executed;
        bool exists;
    }
    mapping(uint => GovernanceProposal) public governanceProposals;

    struct CuratorProposal {
        uint id;
        address proposer;
        address newCurator;
        uint votesFor;
        uint votesAgainst;
        uint startTime;
        uint endTime;
        bool passed;
        bool executed;
        bool exists;
    }
    mapping(uint => CuratorProposal) public curatorProposals;

    struct CollaborationRequest {
        uint id;
        uint artId;
        address requester;
        string requestDescription;
        address[] collaborators; // Potential collaborators proposed
        uint votesFor;
        uint votesAgainst;
        bool approved;
        bool finalized;
        bool exists;
    }
    mapping(uint => CollaborationRequest) public collaborationRequests;

    // -------- Events --------

    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member);
    event MembershipRevoked(address indexed member);
    event CuratorProposed(uint proposalId, address indexed proposer, address newCurator);
    event CuratorProposalVoted(uint proposalId, address indexed voter, bool vote);
    event CuratorProposalPassed(uint proposalId, address newCurator);
    event GovernanceProposalSubmitted(uint proposalId, address indexed proposer, string title);
    event GovernanceProposalVoted(uint proposalId, address indexed voter, bool vote);
    event GovernanceProposalPassed(uint proposalId, string title);
    event GovernanceProposalExecuted(uint proposalId, string title);
    event ArtProposalSubmitted(uint proposalId, address indexed proposer, string title);
    event ArtProposalVoted(uint proposalId, address indexed curator, bool vote);
    event ArtProposalApproved(uint proposalId, string title);
    event ArtNFTMinted(uint artId, uint proposalId, address indexed creator, string title);
    event ArtNFTPriceSet(uint artId, uint newPrice);
    event ArtNFTPurchased(uint artId, address indexed buyer, uint price);
    event CollaborationRequested(uint requestId, uint artId, address indexed requester);
    event CollaborationRequestVoted(uint requestId, address indexed curator, bool vote);
    event CollaborationApproved(uint requestId, uint artId);
    event CollaborationContributionSubmitted(uint requestId, address indexed contributor, string description);
    event CollaborationFinalized(uint requestId, uint artId);
    event TreasuryDeposit(address indexed sender, uint amount);
    event TreasuryWithdrawal(address indexed recipient, uint amount);

    // -------- Modifiers --------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Only curators can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier validArtProposal(uint _proposalId) {
        require(artProposals[_proposalId].exists, "Art proposal does not exist.");
        _;
    }

    modifier validArtNFT(uint _artId) {
        require(artNFTs[_artId].exists, "Art NFT does not exist.");
        _;
    }

    modifier validGovernanceProposal(uint _proposalId) {
        require(governanceProposals[_proposalId].exists, "Governance proposal does not exist.");
        _;
    }

    modifier validCuratorProposal(uint _proposalId) {
        require(curatorProposals[_proposalId].exists, "Curator proposal does not exist.");
        _;
    }

    modifier validCollaborationRequest(uint _requestId) {
        require(collaborationRequests[_requestId].exists, "Collaboration request does not exist.");
        _;
    }

    modifier proposalNotExpired(uint _proposalId, ProposalType _proposalType) {
        uint endTime;
        if (_proposalType == ProposalType.Governance) {
            endTime = governanceProposals[_proposalId].endTime;
        } else if (_proposalType == ProposalType.Curator) {
            endTime = curatorProposals[_proposalId].endTime;
        } else {
            revert("Invalid proposal type for expiration check.");
        }
        require(block.timestamp <= endTime, "Proposal voting period has expired.");
        _;
    }

    enum ProposalType { Governance, Curator }


    // -------- Constructor --------

    constructor() {
        owner = msg.sender;
        curators.push(owner);
        isCurator[owner] = true;
    }

    // -------- Membership & Governance Functions --------

    /// @notice Allows users to request membership to the DAAC.
    function joinCollective() external payable {
        require(!isMember[msg.sender], "Already a member.");
        require(msg.value >= membershipFee, "Membership fee not met.");

        membersData[msg.sender] = Member({
            memberAddress: msg.sender,
            joinTimestamp: block.timestamp,
            isActive: false,
            exists: true
        });
        emit MembershipRequested(msg.sender);
    }

    /// @notice Allows curators to approve pending membership requests.
    /// @param _member The address of the member to approve.
    function approveMember(address _member) external onlyCurator {
        require(membersData[_member].exists, "Member request not found.");
        require(!isMember[_member], "Already a member.");

        isMember[_member] = true;
        members.push(_member);
        membersData[_member].isActive = true;
        emit MembershipApproved(_member);
    }

    /// @notice Allows curators to revoke membership.
    /// @param _member The address of the member to revoke.
    function revokeMembership(address _member) external onlyCurator {
        require(isMember[_member], "Not a member.");
        require(_member != owner, "Cannot revoke owner's membership."); // Optional: Prevent revoking owner, or handle ownership transfer first

        isMember[_member] = false;
        membersData[_member].isActive = false;
        // Optional: Remove from members array for cleaner iteration if needed
        emit MembershipRevoked(_member);
    }

    /// @notice Allows members to propose a new curator.
    /// @param _newCurator The address of the proposed new curator.
    function proposeNewCurator(address _newCurator) external onlyMember {
        require(!isCurator[_newCurator], "Address is already a curator.");

        curatorProposals[nextCuratorProposalId] = CuratorProposal({
            id: nextCuratorProposalId,
            proposer: msg.sender,
            newCurator: _newCurator,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + memberVoteDuration,
            passed: false,
            executed: false,
            exists: true
        });
        emit CuratorProposed(nextCuratorProposalId, msg.sender, _newCurator);
        nextCuratorProposalId++;
    }

    /// @notice Allows members to vote on curator proposals.
    /// @param _proposalId The ID of the curator proposal.
    /// @param _vote True for yes, false for no.
    function voteOnCuratorProposal(uint _proposalId, bool _vote) external onlyMember validCuratorProposal(_proposalId) proposalNotExpired(_proposalId, ProposalType.Curator) {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        require(!proposal.passed && !proposal.executed, "Proposal already finalized."); // Prevent voting after finalized

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit CuratorProposalVoted(_proposalId, msg.sender, _vote);

        if (proposal.votesFor >= members.length / 2 + 1 && !proposal.passed) { // Simple majority, can be adjusted
            proposal.passed = true;
            emit CuratorProposalPassed(_proposalId, proposal.newCurator);
        }
    }

    /// @notice Allows curators to execute passed curator proposals.
    /// @param _proposalId The ID of the curator proposal to execute.
    function executeCuratorProposal(uint _proposalId) external onlyCurator validCuratorProposal(_proposalId) {
        CuratorProposal storage proposal = curatorProposals[_proposalId];
        require(proposal.passed && !proposal.executed, "Proposal not passed or already executed.");

        isCurator[proposal.newCurator] = true;
        curators.push(proposal.newCurator);
        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId, "Curator Proposal"); // Reusing event for execution
    }


    /// @notice Allows members to submit governance proposals.
    /// @param _title Title of the proposal.
    /// @param _description Description of the proposal.
    /// @param _calldata Calldata to execute if the proposal passes.
    function submitGovernanceProposal(string memory _title, string memory _description, bytes memory _calldata) external onlyMember {
        governanceProposals[nextGovernanceProposalId] = GovernanceProposal({
            id: nextGovernanceProposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            calldataData: _calldata,
            votesFor: 0,
            votesAgainst: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + memberVoteDuration,
            passed: false,
            executed: false,
            exists: true
        });
        emit GovernanceProposalSubmitted(nextGovernanceProposalId, msg.sender, _title);
        nextGovernanceProposalId++;
    }

    /// @notice Allows members to vote on governance proposals.
    /// @param _proposalId The ID of the governance proposal.
    /// @param _vote True for yes, false for no.
    function voteOnGovernanceProposal(uint _proposalId, bool _vote) external onlyMember validGovernanceProposal(_proposalId) proposalNotExpired(_proposalId, ProposalType.Governance) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(!proposal.passed && !proposal.executed, "Proposal already finalized."); // Prevent voting after finalized

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);

        if (proposal.votesFor >= members.length / 2 + 1 && !proposal.passed) { // Simple majority, can be adjusted
            proposal.passed = true;
            emit GovernanceProposalPassed(_proposalId, proposal.title);
        }
    }

    /// @notice Allows curators to execute passed governance proposals.
    /// @param _proposalId The ID of the governance proposal to execute.
    function executeGovernanceProposal(uint _proposalId) external onlyCurator validGovernanceProposal(_proposalId) {
        GovernanceProposal storage proposal = governanceProposals[_proposalId];
        require(proposal.passed && !proposal.executed, "Proposal not passed or already executed.");

        (bool success,) = address(this).call(proposal.calldataData); // Execute the calldata
        require(success, "Governance proposal execution failed.");

        proposal.executed = true;
        emit GovernanceProposalExecuted(_proposalId, proposal.title);
    }


    // -------- Art Submission & Curation Functions --------

    /// @notice Allows members to submit art proposals to the collective.
    /// @param _title Title of the art proposal.
    /// @param _description Description of the art proposal.
    /// @param _ipfsHash IPFS hash of the art piece.
    /// @param _creationCost Desired creation cost for the art (can be adjusted by curators).
    function submitArtProposal(string memory _title, string memory _description, string memory _ipfsHash, uint _creationCost) external onlyMember {
        artProposals[nextArtProposalId] = ArtProposal({
            id: nextArtProposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            creationCost: _creationCost,
            votesFor: 0,
            votesAgainst: 0,
            approved: false,
            paid: false,
            exists: true
        });
        emit ArtProposalSubmitted(nextArtProposalId, msg.sender, _title);
        nextArtProposalId++;
    }

    /// @notice Allows curators to vote on art proposals.
    /// @param _proposalId The ID of the art proposal.
    /// @param _vote True for approve, false for reject.
    function voteOnArtProposal(uint _proposalId, bool _vote) external onlyCurator validArtProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(!proposal.approved, "Art proposal already approved/rejected.");

        if (_vote) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }
        emit ArtProposalVoted(_proposalId, msg.sender, _vote);

        if (proposal.votesFor >= curatorVoteThreshold) {
            proposal.approved = true;
            emit ArtProposalApproved(_proposalId, proposal.title);
        }
    }

    /// @notice Mints an ArtNFT if the proposal is approved and the creation cost is paid.
    /// @param _proposalId The ID of the approved art proposal.
    function mintArtNFT(uint _proposalId) external payable validArtProposal(_proposalId) {
        ArtProposal storage proposal = artProposals[_proposalId];
        require(proposal.approved, "Art proposal not approved yet.");
        require(!proposal.paid, "Art proposal already paid and minted.");
        require(msg.value >= proposal.creationCost, "Insufficient payment for art creation.");

        artNFTs[nextArtNFTId] = ArtNFT({
            id: nextArtNFTId,
            proposalId: _proposalId,
            creator: proposal.proposer,
            title: proposal.title,
            description: proposal.description,
            ipfsHash: proposal.ipfsHash,
            price: 0, // Initial price set to 0, curators can set later
            owner: address(this), // Initially owned by the collective
            collaborators: new address[](0), // No collaborators initially
            exists: true
        });

        proposal.paid = true;
        // Transfer payment to treasury (or distribute to curators/collective as decided)
        payable(address(this)).transfer(msg.value); // Simplified treasury deposit

        emit ArtNFTMinted(nextArtNFTId, _proposalId, proposal.proposer, proposal.title);
        nextArtNFTId++;
    }

    /// @notice Allows the collective (curators) to set the price of an ArtNFT.
    /// @param _artId The ID of the ArtNFT.
    /// @param _newPrice The new price for the ArtNFT.
    function setArtPrice(uint _artId, uint _newPrice) external onlyCurator validArtNFT(_artId) {
        artNFTs[_artId].price = _newPrice;
        emit ArtNFTPriceSet(_artId, _newPrice);
    }

    /// @notice Allows users to purchase ArtNFTs from the collective. Revenue split can be implemented here.
    /// @param _artId The ID of the ArtNFT to purchase.
    function purchaseArtNFT(uint _artId) external payable validArtNFT(_artId) {
        ArtNFT storage art = artNFTs[_artId];
        require(art.owner == address(this), "Art NFT not available for sale from collective.");
        require(msg.value >= art.price, "Insufficient payment for Art NFT.");

        address previousOwner = art.owner;
        art.owner = msg.sender;

        // Revenue distribution logic (example: split between treasury and original creator if they are still member)
        uint creatorShare = art.price * 50 / 100; // Example: 50% to creator, 50% to treasury
        uint treasuryShare = art.price - creatorShare;

        if (isMember[art.creator]) {
            payable(art.creator).transfer(creatorShare); // Send share to creator
        }
        payable(address(this)).transfer(treasuryShare); // Send share to treasury

        emit ArtNFTPurchased(_artId, msg.sender, art.price);
    }


    // -------- Collaborative Art & AI Integration (Conceptual) Functions --------

    /// @notice Allows members to request to collaborate on an existing ArtNFT.
    /// @param _artId The ID of the ArtNFT to collaborate on.
    function requestCollaboration(uint _artId) external onlyMember validArtNFT(_artId) {
        require(artNFTs[_artId].owner == address(this), "Cannot collaborate on already owned ArtNFT."); // Or allow collaboration requests on owned NFTs, adjust logic

        collaborationRequests[nextCollaborationRequestId] = CollaborationRequest({
            id: nextCollaborationRequestId,
            artId: _artId,
            requester: msg.sender,
            requestDescription: "Member requested collaboration", // Can be extended to take description
            collaborators: new address[](0), // Initially no collaborators
            votesFor: 0,
            votesAgainst: 0,
            approved: false,
            finalized: false,
            exists: true
        });
        emit CollaborationRequested(nextCollaborationRequestId, _artId, msg.sender);
        nextCollaborationRequestId++;
    }

    /// @notice Allows curators to vote on collaboration requests.
    /// @param _requestId The ID of the collaboration request.
    /// @param _vote True for approve, false for reject.
    function voteOnCollaborationRequest(uint _requestId, bool _vote) external onlyCurator validCollaborationRequest(_requestId) {
        CollaborationRequest storage request = collaborationRequests[_requestId];
        require(!request.approved && !request.finalized, "Collaboration request already decided.");

        if (_vote) {
            request.votesFor++;
        } else {
            request.votesAgainst++;
        }
        emit CollaborationRequestVoted(_requestId, msg.sender, _vote);

        if (request.votesFor >= curatorVoteThreshold) {
            request.approved = true;
            emit CollaborationApproved(_requestId, request.artId);
        }
    }

    /// @notice Allows approved collaborators to submit their contributions to the ArtNFT.
    /// @param _requestId The ID of the collaboration request.
    /// @param _contributionDescription Description of the contribution.
    /// @param _ipfsHash IPFS hash of the contribution.
    function submitCollaborationContribution(uint _requestId, string memory _contributionDescription, string memory _ipfsHash) external onlyMember validCollaborationRequest(_requestId) {
        CollaborationRequest storage request = collaborationRequests[_requestId];
        require(request.approved, "Collaboration request not approved yet.");
        // Add logic to check if msg.sender is in the approved collaborators list (if implemented in request structure)

        // Here, ideally, you would store the contribution information, maybe in a separate mapping
        // For simplicity, we'll just emit an event in this example.
        emit CollaborationContributionSubmitted(_requestId, msg.sender, _contributionDescription);

        // (Conceptual) Update the ArtNFT IPFS hash to reflect the collaboration - This is complex and often done off-chain.
        // In a real-world scenario, you might need to manage versions of IPFS hashes or use a more sophisticated system.
    }

    /// @notice Allows curators to finalize a collaboration and update the ArtNFT (conceptual - IPFS update).
    /// @param _requestId The ID of the collaboration request.
    function finalizeCollaboration(uint _requestId) external onlyCurator validCollaborationRequest(_requestId) {
        CollaborationRequest storage request = collaborationRequests[_requestId];
        require(request.approved && !request.finalized, "Collaboration already finalized.");

        ArtNFT storage art = artNFTs[request.artId];
        // Add the collaborators to the ArtNFT's collaborators list (if tracking collaborators)
        // In this simplified example, we are not explicitly managing collaborators in the request object,
        // but in a real application, you would likely have a process for adding collaborators to the request and then to the ArtNFT.

        // (Conceptual) Update ArtNFT metadata (e.g., IPFS hash) to reflect collaboration.
        // This often involves off-chain processes to update metadata on NFT platforms or marketplaces.
        // For this example, we'll just emit an event.
        emit CollaborationFinalized(_requestId, request.artId);
        request.finalized = true;
    }

    /// @notice (Conceptual - Off-chain AI integration) Allows members to request AI-generated art inspiration based on a prompt.
    /// @param _prompt Text prompt for AI art generation.
    /// @return string A conceptual string representing AI-generated art inspiration (in real implementation, this would be handled off-chain).
    function requestAIArtInspiration(string memory _prompt) external onlyMember returns (string memory) {
        // In a real-world scenario, this would trigger an off-chain process:
        // 1. Send _prompt to an AI art generation service (e.g., DALL-E, Stable Diffusion API).
        // 2. AI service generates art based on the prompt.
        // 3. (Optional) Store the generated art IPFS hash or data off-chain.
        // 4. Return a placeholder or a description of the AI-generated inspiration.

        // For this smart contract example, we just return a conceptual string.
        string memory aiInspiration = string(abi.encodePacked("AI Inspiration based on prompt: '", _prompt, "' - (Conceptual Output)"));
        return aiInspiration;
    }


    // -------- Treasury & Revenue Management Functions --------

    /// @notice Allows anyone to deposit ETH into the DAAC treasury.
    function depositToTreasury() external payable {
        payable(address(this)).transfer(msg.value);
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Allows curators to withdraw funds from the treasury for collective expenses (governance vote ideally).
    /// @param _recipient Address to receive the withdrawn funds.
    /// @param _amount Amount to withdraw in wei.
    function withdrawFromTreasury(address _recipient, uint _amount) external onlyCurator {
        require(address(this).balance >= _amount, "Insufficient treasury balance.");
        payable(_recipient).transfer(_amount);
        emit TreasuryWithdrawal(_recipient, _amount);
    }

    /// @notice Returns the current balance of the DAAC treasury.
    /// @return uint The treasury balance in wei.
    function getTreasuryBalance() external view returns (uint) {
        return address(this).balance;
    }


    // -------- Utility & Info Functions --------

    /// @notice Returns details of an art proposal.
    /// @param _proposalId The ID of the art proposal.
    /// @return ArtProposal struct containing proposal details.
    function getArtProposalDetails(uint _proposalId) external view validArtProposal(_proposalId) returns (ArtProposal memory) {
        return artProposals[_proposalId];
    }

    /// @notice Returns details of an ArtNFT.
    /// @param _artId The ID of the ArtNFT.
    /// @return ArtNFT struct containing ArtNFT details.
    function getArtNFTDetails(uint _artId) external view validArtNFT(_artId) returns (ArtNFT memory) {
        return artNFTs[_artId];
    }

    /// @notice Returns details of a DAAC member.
    /// @param _member The address of the member.
    /// @return Member struct containing member details.
    function getMemberDetails(address _member) external view returns (Member memory) {
        return membersData[_member];
    }

    /// @notice Returns details of a governance proposal.
    /// @param _proposalId The ID of the governance proposal.
    /// @return GovernanceProposal struct containing proposal details.
    function getGovernanceProposalDetails(uint _proposalId) external view validGovernanceProposal(_proposalId) returns (GovernanceProposal memory) {
        return governanceProposals[_proposalId];
    }

    /// @notice Returns details of a curator proposal.
    /// @param _proposalId The ID of the curator proposal.
    /// @return CuratorProposal struct containing proposal details.
    function getCuratorProposalDetails(uint _proposalId) external view validCuratorProposal(_proposalId) returns (CuratorProposal memory) {
        return curatorProposals[_proposalId];
    }

    /// @notice Returns details of a collaboration request.
    /// @param _requestId The ID of the collaboration request.
    /// @return CollaborationRequest struct containing request details.
    function getCollaborationRequestDetails(uint _requestId) external view validCollaborationRequest(_requestId) returns (CollaborationRequest memory) {
        return collaborationRequests[_requestId];
    }
}
```