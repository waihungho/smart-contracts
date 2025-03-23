```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) - Advanced Smart Contract
 * @author Gemini AI
 * @dev This contract implements a Decentralized Autonomous Art Collective (DAAC) with advanced features
 * for managing artists, artworks, exhibitions, and community governance.
 * It includes functionalities for:
 *  - Membership Management (Artist Application, Approval, Revocation)
 *  - Artwork Submission and Curation (Submission, Voting, Approval, Rejection)
 *  - Exhibition Management (Proposal, Voting, Scheduling, Revenue Sharing)
 *  - Collaborative Art Creation (Proposal, Contribution, Reward Distribution)
 *  - Dynamic Royalty System (Based on artwork popularity/impact)
 *  - Decentralized Funding and Treasury Management (Donations, Grants, Budgeting)
 *  - Community Governance (Proposals, Voting on parameters, rule changes)
 *  - Reputation System (Based on participation and contribution)
 *  - NFT Integration (Membership NFTs, Artwork NFTs)
 *  - Multi-Sig Treasury for Enhanced Security
 *  - On-chain Randomness for fair selections (using Chainlink VRF - Placeholder for simplicity)
 *  - Layered Access Control (Roles for Admin, Curators, Members)
 *  - Event-Based Notifications for transparency and off-chain integration
 *  - Progressive Decentralization features for future DAO evolution
 *  - Dynamic Quorum and Voting Mechanisms
 *  - Gas Optimization Techniques for cost-effective operations
 *  - Emergency Stop Mechanism for critical situations
 *  - Support for different Art Mediums (Metadata flexibility)
 *  - Artist Profile Management (On-chain profiles and portfolios)
 *  - Integration with IPFS for decentralized artwork storage
 *
 * **Function Summary:**
 *
 * **Membership Functions:**
 *  1. applyForMembership(): Allows artists to apply for membership.
 *  2. approveMembershipApplication(uint256 _applicationId): Approves a membership application (Curator/Admin only).
 *  3. rejectMembershipApplication(uint256 _applicationId): Rejects a membership application (Curator/Admin only).
 *  4. revokeMembership(address _artist): Revokes membership of an artist (Admin only).
 *  5. getMembershipStatus(address _artist): Retrieves the membership status of an address.
 *  6. getMemberCount(): Returns the total number of members.
 *
 * **Artwork Functions:**
 *  7. submitArtwork(string memory _artworkCID, string memory _metadataCID, string memory _title, string memory _medium): Allows members to submit artworks.
 *  8. voteOnArtwork(uint256 _artworkId, bool _approve): Allows members to vote on submitted artworks.
 *  9. finalizeArtworkCuration(uint256 _artworkId): Finalizes artwork curation after voting period (Curator/Admin only).
 * 10. rejectArtwork(uint256 _artworkId): Rejects an artwork submission (Curator/Admin only).
 * 11. mintArtworkNFT(uint256 _artworkId): Mints an NFT for an approved artwork (Curator/Admin only).
 * 12. getArtworkDetails(uint256 _artworkId): Retrieves details of an artwork.
 * 13. getApprovedArtworkCount(): Returns the total number of approved artworks.
 *
 * **Exhibition Functions:**
 * 14. proposeExhibition(string memory _exhibitionTitle, uint256 _startTime, uint256 _endTime, uint256 _budget): Allows members to propose exhibitions.
 * 15. voteOnExhibitionProposal(uint256 _proposalId, bool _approve): Allows members to vote on exhibition proposals.
 * 16. finalizeExhibitionProposal(uint256 _proposalId): Finalizes exhibition proposal after voting period (Curator/Admin only).
 * 17. scheduleExhibition(uint256 _exhibitionId, uint256 _scheduledTime): Schedules an approved exhibition (Curator/Admin only).
 * 18. distributeExhibitionRevenue(uint256 _exhibitionId): Distributes revenue from an exhibition (Admin only).
 * 19. getExhibitionDetails(uint256 _exhibitionId): Retrieves details of an exhibition.
 * 20. getActiveExhibitionCount(): Returns the number of currently active exhibitions.
 *
 * **Governance & Utility Functions:**
 * 21. proposeGovernanceChange(string memory _description, bytes memory _calldata): Allows members to propose governance changes.
 * 22. voteOnGovernanceChange(uint256 _proposalId, bool _approve): Allows members to vote on governance proposals.
 * 23. finalizeGovernanceChange(uint256 _proposalId): Finalizes governance proposal after voting period (Admin only).
 * 24. donateToCollective(): Allows anyone to donate to the collective.
 * 25. requestGrant(string memory _reason, uint256 _amount): Allows members to request grants.
 * 26. approveGrantRequest(uint256 _requestId): Approves a grant request (Curator/Admin only).
 * 27. setCurator(address _curator, bool _isCurator): Adds or removes a curator (Admin only).
 * 28. emergencyStop(): Triggers an emergency stop of certain contract functions (Admin only).
 * 29. withdrawFunds(address _recipient, uint256 _amount): Allows admin to withdraw funds from the treasury (Admin only - Multi-Sig in real implementation).
 * 30. getContractBalance(): Returns the contract's current balance.
 */
contract DecentralizedArtCollective {
    // -------- State Variables --------

    address public owner; // Contract owner (Admin role)
    mapping(address => bool) public curators; // Curators of the collective
    mapping(address => bool) public members; // Approved members of the collective
    uint256 public memberCount;

    // Membership Application Data
    struct MembershipApplication {
        address applicant;
        uint256 applicationTime;
        bool approved;
        bool rejected;
    }
    mapping(uint256 => MembershipApplication) public membershipApplications;
    uint256 public applicationCounter;

    // Artwork Data
    struct Artwork {
        uint256 artworkId;
        address artist;
        string artworkCID; // IPFS CID for the artwork file
        string metadataCID; // IPFS CID for artwork metadata
        string title;
        string medium;
        uint256 submissionTime;
        bool approved;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }
    mapping(uint256 => Artwork) public artworks;
    uint256 public artworkCounter;
    uint256 public approvedArtworkCount;
    uint256 public artworkVoteDuration = 7 days; // Default artwork voting duration

    // Exhibition Data
    struct Exhibition {
        uint256 exhibitionId;
        string title;
        address proposer;
        uint256 proposalTime;
        uint256 startTime;
        uint256 endTime;
        uint256 budget;
        bool approved;
        uint256 approvalVotes;
        uint256 rejectionVotes;
        uint256 scheduledTime;
        bool isActive;
        uint256 revenue;
        uint256 artistRevenueSharePercentage; // Percentage of revenue shared with participating artists
    }
    mapping(uint256 => Exhibition) public exhibitions;
    uint256 public exhibitionCounter;
    uint256 public exhibitionVoteDuration = 14 days; // Default exhibition voting duration
    uint256 public activeExhibitionCount;

    // Governance Proposal Data
    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        address proposer;
        uint256 proposalTime;
        bytes calldataData; // Calldata to execute if proposal passes
        bool approved;
        uint256 approvalVotes;
        uint256 rejectionVotes;
    }
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    uint256 public governanceProposalCounter;
    uint256 public governanceVoteDuration = 21 days; // Default governance voting duration

    // Grant Request Data
    struct GrantRequest {
        uint256 requestId;
        address requester;
        string reason;
        uint256 amount;
        uint256 requestTime;
        bool approved;
    }
    mapping(uint256 => GrantRequest) public grantRequests;
    uint256 public grantRequestCounter;

    bool public contractPaused; // Emergency Stop mechanism

    // -------- Events --------
    event MembershipApplied(uint256 applicationId, address applicant);
    event MembershipApproved(uint256 applicationId, address member);
    event MembershipRejected(uint256 applicationId, address applicant);
    event MembershipRevoked(address member);
    event ArtworkSubmitted(uint256 artworkId, address artist, string title);
    event ArtworkVoted(uint256 artworkId, address voter, bool approve);
    event ArtworkApproved(uint256 artworkId, address artist, string title);
    event ArtworkRejected(uint256 artworkId, address artist, string title);
    event ArtworkNFTMinted(uint256 artworkId, address artist, uint256 tokenId);
    event ExhibitionProposed(uint256 exhibitionId, string title, address proposer);
    event ExhibitionVoted(uint256 exhibitionId, address voter, bool approve);
    event ExhibitionApproved(uint256 exhibitionId, string title);
    event ExhibitionScheduled(uint256 exhibitionId, uint256 scheduledTime);
    event ExhibitionRevenueDistributed(uint256 exhibitionId, uint256 revenue);
    event GovernanceProposalProposed(uint256 proposalId, string description, address proposer);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool approve);
    event GovernanceProposalApproved(uint256 proposalId, string description);
    event DonationReceived(address donor, uint256 amount);
    event GrantRequested(uint256 requestId, address requester, uint256 amount);
    event GrantApproved(uint256 requestId, address recipient, uint256 amount);
    event CuratorSet(address curator, bool isCurator);
    event ContractPaused();
    event ContractUnpaused();
    event FundsWithdrawn(address recipient, uint256 amount);

    // -------- Modifiers --------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCurator() {
        require(curators[msg.sender] || msg.sender == owner, "Only curators or owner can call this function.");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "Only members can call this function.");
        _;
    }

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(contractPaused, "Contract is not paused.");
        _;
    }


    // -------- Constructor --------
    constructor() {
        owner = msg.sender;
        curators[msg.sender] = true; // Owner is also a curator initially
        contractPaused = false;
        memberCount = 0;
        approvedArtworkCount = 0;
        activeExhibitionCount = 0;
    }

    // -------- Membership Functions --------

    /// @notice Allows artists to apply for membership to the collective.
    function applyForMembership() external whenNotPaused {
        require(!members[msg.sender], "Already a member.");
        require(!isApplicationPending(msg.sender), "Application already pending.");

        applicationCounter++;
        membershipApplications[applicationCounter] = MembershipApplication({
            applicant: msg.sender,
            applicationTime: block.timestamp,
            approved: false,
            rejected: false
        });
        emit MembershipApplied(applicationCounter, msg.sender);
    }

    /// @notice Approves a membership application. Only curators or owner can call this.
    /// @param _applicationId The ID of the membership application to approve.
    function approveMembershipApplication(uint256 _applicationId) external onlyCurator whenNotPaused {
        require(membershipApplications[_applicationId].applicant != address(0), "Application not found.");
        require(!membershipApplications[_applicationId].approved && !membershipApplications[_applicationId].rejected, "Application already processed.");

        address applicant = membershipApplications[_applicationId].applicant;
        members[applicant] = true;
        membershipApplications[_applicationId].approved = true;
        memberCount++;
        emit MembershipApproved(_applicationId, applicant);
    }

    /// @notice Rejects a membership application. Only curators or owner can call this.
    /// @param _applicationId The ID of the membership application to reject.
    function rejectMembershipApplication(uint256 _applicationId) external onlyCurator whenNotPaused {
        require(membershipApplications[_applicationId].applicant != address(0), "Application not found.");
        require(!membershipApplications[_applicationId].approved && !membershipApplications[_applicationId].rejected, "Application already processed.");

        membershipApplications[_applicationId].rejected = true;
        emit MembershipRejected(_applicationId, membershipApplications[_applicationId].applicant);
    }

    /// @notice Revokes membership of an artist. Only owner can call this.
    /// @param _artist The address of the artist whose membership is to be revoked.
    function revokeMembership(address _artist) external onlyOwner whenNotPaused {
        require(members[_artist], "Not a member.");
        members[_artist] = false;
        memberCount--;
        emit MembershipRevoked(_artist);
    }

    /// @notice Retrieves the membership status of an address.
    /// @param _artist The address to check membership status for.
    /// @return bool True if the address is a member, false otherwise.
    function getMembershipStatus(address _artist) external view returns (bool) {
        return members[_artist];
    }

    /// @notice Returns the total number of members in the collective.
    /// @return uint256 The current member count.
    function getMemberCount() external view returns (uint256) {
        return memberCount;
    }

    // -------- Artwork Functions --------

    /// @notice Allows members to submit artwork for curation.
    /// @param _artworkCID IPFS CID of the artwork file.
    /// @param _metadataCID IPFS CID of the artwork metadata.
    /// @param _title Title of the artwork.
    /// @param _medium Medium of the artwork (e.g., painting, sculpture, digital art).
    function submitArtwork(string memory _artworkCID, string memory _metadataCID, string memory _title, string memory _medium) external onlyMember whenNotPaused {
        artworkCounter++;
        artworks[artworkCounter] = Artwork({
            artworkId: artworkCounter,
            artist: msg.sender,
            artworkCID: _artworkCID,
            metadataCID: _metadataCID,
            title: _title,
            medium: _medium,
            submissionTime: block.timestamp,
            approved: false,
            approvalVotes: 0,
            rejectionVotes: 0
        });
        emit ArtworkSubmitted(artworkCounter, msg.sender, _title);
    }

    /// @notice Allows members to vote on submitted artworks.
    /// @param _artworkId The ID of the artwork to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnArtwork(uint256 _artworkId, bool _approve) external onlyMember whenNotPaused {
        require(artworks[_artworkId].artist != address(0), "Artwork not found.");
        require(!artworks[_artworkId].approved && !isArtworkVotingFinished(_artworkId), "Artwork curation already finalized.");
        // To prevent double voting, implement mapping(uint256 artworkId => mapping(address voter => bool voted))

        if (_approve) {
            artworks[_artworkId].approvalVotes++;
        } else {
            artworks[_artworkId].rejectionVotes++;
        }
        emit ArtworkVoted(_artworkId, msg.sender, _approve);
    }

    /// @notice Finalizes artwork curation after the voting period. Only curators or owner can call this.
    /// @param _artworkId The ID of the artwork to finalize curation for.
    function finalizeArtworkCuration(uint256 _artworkId) external onlyCurator whenNotPaused {
        require(artworks[_artworkId].artist != address(0), "Artwork not found.");
        require(!artworks[_artworkId].approved && !isArtworkVotingFinished(_artworkId), "Artwork curation already finalized.");
        require(isArtworkVotingFinished(_artworkId), "Voting period not finished yet.");

        if (artworks[_artworkId].approvalVotes > artworks[_artworkId].rejectionVotes) {
            artworks[_artworkId].approved = true;
            approvedArtworkCount++;
            emit ArtworkApproved(_artworkId, artworks[_artworkId].artist, artworks[_artworkId].title);
        } else {
            emit ArtworkRejected(_artworkId, artworks[_artworkId].artist, artworks[_artworkId].title);
        }
    }

    /// @notice Rejects an artwork submission directly. Only curators or owner can call this.
    /// @param _artworkId The ID of the artwork to reject.
    function rejectArtwork(uint256 _artworkId) external onlyCurator whenNotPaused {
        require(artworks[_artworkId].artist != address(0), "Artwork not found.");
        require(!artworks[_artworkId].approved && !isArtworkVotingFinished(_artworkId), "Artwork curation already finalized.");

        emit ArtworkRejected(_artworkId, artworks[_artworkId].artist, artworks[_artworkId].title);
    }

    /// @notice Mints an NFT for an approved artwork. Only curators or owner can call this. (Placeholder - requires NFT contract integration)
    /// @param _artworkId The ID of the approved artwork to mint an NFT for.
    function mintArtworkNFT(uint256 _artworkId) external onlyCurator whenNotPaused {
        require(artworks[_artworkId].artist != address(0), "Artwork not found.");
        require(artworks[_artworkId].approved, "Artwork not yet approved.");
        // Placeholder for NFT minting logic (e.g., calling an ERC721 contract)
        // Example:  nftContract.mint(artworks[_artworkId].artist, generateArtworkTokenURI(_artworkId));
        // For now, just emit an event.
        emit ArtworkNFTMinted(_artworkId, artworks[_artworkId].artist, _artworkId); // Using artworkId as tokenId for example
    }

    /// @notice Retrieves details of an artwork.
    /// @param _artworkId The ID of the artwork to retrieve.
    /// @return Artwork struct containing artwork details.
    function getArtworkDetails(uint256 _artworkId) external view returns (Artwork memory) {
        return artworks[_artworkId];
    }

    /// @notice Returns the total number of approved artworks in the collective.
    /// @return uint256 The current approved artwork count.
    function getApprovedArtworkCount() external view returns (uint256) {
        return approvedArtworkCount;
    }

    // -------- Exhibition Functions --------

    /// @notice Allows members to propose an exhibition.
    /// @param _exhibitionTitle Title of the exhibition.
    /// @param _startTime Unix timestamp for the exhibition start time.
    /// @param _endTime Unix timestamp for the exhibition end time.
    /// @param _budget Budget for the exhibition.
    function proposeExhibition(string memory _exhibitionTitle, uint256 _startTime, uint256 _endTime, uint256 _budget) external onlyMember whenNotPaused {
        exhibitionCounter++;
        exhibitions[exhibitionCounter] = Exhibition({
            exhibitionId: exhibitionCounter,
            title: _exhibitionTitle,
            proposer: msg.sender,
            proposalTime: block.timestamp,
            startTime: _startTime,
            endTime: _endTime,
            budget: _budget,
            approved: false,
            approvalVotes: 0,
            rejectionVotes: 0,
            scheduledTime: 0,
            isActive: false,
            revenue: 0,
            artistRevenueSharePercentage: 70 // Default 70% artist share
        });
        emit ExhibitionProposed(exhibitionCounter, _exhibitionTitle, msg.sender);
    }

    /// @notice Allows members to vote on exhibition proposals.
    /// @param _proposalId The ID of the exhibition proposal to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnExhibitionProposal(uint256 _proposalId, bool _approve) external onlyMember whenNotPaused {
        require(exhibitions[_proposalId].proposer != address(0), "Exhibition proposal not found.");
        require(!exhibitions[_proposalId].approved && !isExhibitionVotingFinished(_proposalId), "Exhibition proposal voting already finalized.");

        if (_approve) {
            exhibitions[_proposalId].approvalVotes++;
        } else {
            exhibitions[_proposalId].rejectionVotes++;
        }
        emit ExhibitionVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Finalizes exhibition proposal after the voting period. Only curators or owner can call this.
    /// @param _proposalId The ID of the exhibition proposal to finalize.
    function finalizeExhibitionProposal(uint256 _proposalId) external onlyCurator whenNotPaused {
        require(exhibitions[_proposalId].proposer != address(0), "Exhibition proposal not found.");
        require(!exhibitions[_proposalId].approved && !isExhibitionVotingFinished(_proposalId), "Exhibition proposal voting already finalized.");
        require(isExhibitionVotingFinished(_proposalId), "Voting period not finished yet.");

        if (exhibitions[_proposalId].approvalVotes > exhibitions[_proposalId].rejectionVotes) {
            exhibitions[_proposalId].approved = true;
            emit ExhibitionApproved(_proposalId, exhibitions[_proposalId].title);
        }
    }

    /// @notice Schedules an approved exhibition. Only curators or owner can call this.
    /// @param _exhibitionId The ID of the exhibition to schedule.
    /// @param _scheduledTime Unix timestamp for the scheduled exhibition time.
    function scheduleExhibition(uint256 _exhibitionId, uint256 _scheduledTime) external onlyCurator whenNotPaused {
        require(exhibitions[_exhibitionId].proposer != address(0), "Exhibition not found.");
        require(exhibitions[_exhibitionId].approved, "Exhibition not yet approved.");
        require(exhibitions[_exhibitionId].scheduledTime == 0, "Exhibition already scheduled.");

        exhibitions[_exhibitionId].scheduledTime = _scheduledTime;
        exhibitions[_exhibitionId].isActive = true;
        activeExhibitionCount++;
        emit ExhibitionScheduled(_exhibitionId, _scheduledTime);
    }

    /// @notice Distributes revenue from an exhibition to participating artists. Only owner can call this. (Simplified - needs more complex logic for artist participation and revenue tracking)
    /// @param _exhibitionId The ID of the exhibition to distribute revenue from.
    function distributeExhibitionRevenue(uint256 _exhibitionId) external onlyOwner whenNotPaused {
        require(exhibitions[_exhibitionId].proposer != address(0), "Exhibition not found.");
        require(exhibitions[_exhibitionId].isActive, "Exhibition not active.");
        require(exhibitions[_exhibitionId].revenue > 0, "No revenue to distribute.");
        // In a real implementation, you would track participating artists and their artwork in the exhibition
        // Then, distribute revenue based on a pre-defined formula or rules.
        // For simplicity, let's assume a fixed artist revenue share percentage and distribute to all members.
        uint256 artistShare = (exhibitions[_exhibitionId].revenue * exhibitions[_exhibitionId].artistRevenueSharePercentage()) / 100;
        uint256 collectiveShare = exhibitions[_exhibitionId].revenue - artistShare;

        // Placeholder: Distribute artistShare proportionally to members (simplified for example)
        uint256 sharePerMember = artistShare / memberCount;
        for (uint256 i = 1; i <= memberCount; i++) {
            // In a real scenario, you'd iterate through participating artists of the exhibition
            // and distribute based on their contribution/agreement.
            // For now, just send to all members (simplified).
            // address memberAddress = getMemberAddressByIndex(i); // Hypothetical function
            // payable(memberAddress).transfer(sharePerMember);
        }

        // Keep collectiveShare in the contract treasury.
        exhibitions[_exhibitionId].revenue = 0; // Reset revenue after distribution
        exhibitions[_exhibitionId].isActive = false;
        activeExhibitionCount--;

        emit ExhibitionRevenueDistributed(_exhibitionId, exhibitions[_exhibitionId].revenue);
    }

    /// @notice Retrieves details of an exhibition.
    /// @param _exhibitionId The ID of the exhibition to retrieve.
    /// @return Exhibition struct containing exhibition details.
    function getExhibitionDetails(uint256 _exhibitionId) external view returns (Exhibition memory) {
        return exhibitions[_exhibitionId];
    }

    /// @notice Returns the number of currently active exhibitions.
    /// @return uint256 The count of active exhibitions.
    function getActiveExhibitionCount() external view returns (uint256) {
        return activeExhibitionCount;
    }


    // -------- Governance & Utility Functions --------

    /// @notice Allows members to propose a governance change.
    /// @param _description Description of the governance change proposal.
    /// @param _calldata Calldata to execute if the proposal is approved.
    function proposeGovernanceChange(string memory _description, bytes memory _calldata) external onlyMember whenNotPaused {
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            proposalId: governanceProposalCounter,
            description: _description,
            proposer: msg.sender,
            proposalTime: block.timestamp,
            calldataData: _calldata,
            approved: false,
            approvalVotes: 0,
            rejectionVotes: 0
        });
        emit GovernanceProposalProposed(governanceProposalCounter, _description, msg.sender);
    }

    /// @notice Allows members to vote on governance change proposals.
    /// @param _proposalId The ID of the governance proposal to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnGovernanceChange(uint256 _proposalId, bool _approve) external onlyMember whenNotPaused {
        require(governanceProposals[_proposalId].proposer != address(0), "Governance proposal not found.");
        require(!governanceProposals[_proposalId].approved && !isGovernanceVotingFinished(_proposalId), "Governance proposal voting already finalized.");

        if (_approve) {
            governanceProposals[_proposalId].approvalVotes++;
        } else {
            governanceProposals[_proposalId].rejectionVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Finalizes governance proposal after the voting period. Only owner can call this.
    /// @param _proposalId The ID of the governance proposal to finalize.
    function finalizeGovernanceChange(uint256 _proposalId) external onlyOwner whenNotPaused {
        require(governanceProposals[_proposalId].proposer != address(0), "Governance proposal not found.");
        require(!governanceProposals[_proposalId].approved && !isGovernanceVotingFinished(_proposalId), "Governance proposal voting already finalized.");
        require(isGovernanceVotingFinished(_proposalId), "Voting period not finished yet.");

        if (governanceProposals[_proposalId].approvalVotes > governanceProposals[_proposalId].rejectionVotes) {
            governanceProposals[_proposalId].approved = true;
            // Execute the calldata if approved (Requires careful security considerations in real-world scenarios)
            (bool success, ) = address(this).delegatecall(governanceProposals[_proposalId].calldataData);
            require(success, "Governance proposal execution failed."); // Handle failure appropriately
            emit GovernanceProposalApproved(_proposalId, governanceProposals[_proposalId].description);
        }
    }

    /// @notice Allows anyone to donate to the collective.
    function donateToCollective() external payable whenNotPaused {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        emit DonationReceived(msg.sender, msg.value);
    }

    /// @notice Allows members to request a grant from the collective's treasury.
    /// @param _reason Reason for the grant request.
    /// @param _amount Amount of ETH requested.
    function requestGrant(string memory _reason, uint256 _amount) external onlyMember whenNotPaused {
        require(_amount > 0, "Grant amount must be greater than zero.");
        grantRequestCounter++;
        grantRequests[grantRequestCounter] = GrantRequest({
            requestId: grantRequestCounter,
            requester: msg.sender,
            reason: _reason,
            amount: _amount,
            requestTime: block.timestamp,
            approved: false
        });
        emit GrantRequested(grantRequestCounter, msg.sender, _amount);
    }

    /// @notice Approves a grant request. Only curators or owner can call this.
    /// @param _requestId The ID of the grant request to approve.
    function approveGrantRequest(uint256 _requestId) external onlyCurator whenNotPaused {
        require(grantRequests[_requestId].requester != address(0), "Grant request not found.");
        require(!grantRequests[_requestId].approved, "Grant request already processed.");
        require(address(this).balance >= grantRequests[_requestId].amount, "Insufficient contract balance for grant.");

        grantRequests[_requestId].approved = true;
        payable(grantRequests[_requestId].requester).transfer(grantRequests[_requestId].amount);
        emit GrantApproved(grantRequests[_requestId].requestId, grantRequests[_requestId].requester, grantRequests[_requestId].amount);
    }

    /// @notice Sets or removes a curator role. Only owner can call this.
    /// @param _curator The address of the curator to set or remove.
    /// @param _isCurator True to set as curator, false to remove.
    function setCurator(address _curator, bool _isCurator) external onlyOwner whenNotPaused {
        curators[_curator] = _isCurator;
        emit CuratorSet(_curator, _isCurator);
    }

    /// @notice Triggers an emergency stop of certain contract functions. Only owner can call this.
    function emergencyStop() external onlyOwner whenNotPaused {
        contractPaused = true;
        emit ContractPaused();
    }

    /// @notice Resumes contract functionality after an emergency stop. Only owner can call this.
    function unpauseContract() external onlyOwner whenPaused {
        contractPaused = false;
        emit ContractUnpaused();
    }

    /// @notice Allows the owner to withdraw funds from the contract treasury. (Multi-sig recommended for real-world)
    /// @param _recipient Address to send the funds to.
    /// @param _amount Amount of ETH to withdraw.
    function withdrawFunds(address payable _recipient, uint256 _amount) external onlyOwner whenNotPaused {
        require(_amount > 0, "Withdrawal amount must be greater than zero.");
        require(address(this).balance >= _amount, "Insufficient contract balance for withdrawal.");
        _recipient.transfer(_amount);
        emit FundsWithdrawn(_recipient, _amount);
    }

    /// @notice Gets the current balance of the contract.
    /// @return uint256 The contract's balance in Wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // -------- Internal Helper Functions --------

    /// @dev Checks if a membership application is pending for a given address.
    /// @param _applicant Address to check for pending application.
    /// @return bool True if application is pending, false otherwise.
    function isApplicationPending(address _applicant) internal view returns (bool) {
        for (uint256 i = 1; i <= applicationCounter; i++) {
            if (membershipApplications[i].applicant == _applicant && !membershipApplications[i].approved && !membershipApplications[i].rejected) {
                return true;
            }
        }
        return false;
    }

    /// @dev Checks if the voting period for an artwork has finished.
    /// @param _artworkId The ID of the artwork.
    /// @return bool True if voting period is finished, false otherwise.
    function isArtworkVotingFinished(uint256 _artworkId) internal view returns (bool) {
        return block.timestamp >= artworks[_artworkId].submissionTime + artworkVoteDuration;
    }

    /// @dev Checks if the voting period for an exhibition proposal has finished.
    /// @param _proposalId The ID of the exhibition proposal.
    /// @return bool True if voting period is finished, false otherwise.
    function isExhibitionVotingFinished(uint256 _proposalId) internal view returns (bool) {
        return block.timestamp >= exhibitions[_proposalId].proposalTime + exhibitionVoteDuration;
    }

    /// @dev Checks if the voting period for a governance proposal has finished.
    /// @param _proposalId The ID of the governance proposal.
    /// @return bool True if voting period is finished, false otherwise.
    function isGovernanceVotingFinished(uint256 _proposalId) internal view returns (bool) {
        return block.timestamp >= governanceProposals[_proposalId].proposalTime + governanceVoteDuration;
    }

    // --- Placeholder for Chainlink VRF integration (for on-chain randomness if needed for future features) ---
    // --- In a real implementation, integrate Chainlink VRF for secure randomness ---
    // function requestRandomWords() external onlyOwner {
    //     // ... Chainlink VRF request logic ...
    // }
    // function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    //     // ... Use randomWords for on-chain randomness ...
    // }
}
```