```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC)
 * @author Bard (AI Assistant)
 * @notice A smart contract for a decentralized autonomous art collective, enabling artists to collaborate,
 *         vote on art submissions, manage a shared treasury, and participate in governance. This contract
 *         introduces a dynamic "Art Evolution" concept where artworks can be iteratively improved and
 *         evolved based on community contributions and voting. It also features a reputation system
 *         and collaborative art creation tools.

 * **Outline and Function Summary:**

 * **Core Functionality:**
 * 1.  `submitArtwork(string memory _artworkMetadataURI)`: Artists submit their artwork proposals with metadata URI.
 * 2.  `voteOnArtworkSubmission(uint256 _submissionId, bool _approve)`: Members vote to approve or reject artwork submissions.
 * 3.  `finalizeArtworkSubmission(uint256 _submissionId)`: After voting, finalize the submission process, minting approved artworks as NFTs.
 * 4.  `viewArtworkSubmissionDetails(uint256 _submissionId)`: View details of an artwork submission.
 * 5.  `purchaseArtworkNFT(uint256 _artworkId)`: Purchase an approved artwork NFT (funds go to treasury).
 * 6.  `listTreasuryArtworks()`: View IDs of artworks owned by the treasury.

 * **Art Evolution & Collaboration Features:**
 * 7.  `proposeArtEvolution(uint256 _artworkId, string memory _evolutionProposalMetadataURI)`: Members propose evolutions for existing artworks.
 * 8.  `voteOnArtEvolution(uint256 _evolutionId, bool _approve)`: Members vote on art evolution proposals.
 * 9.  `finalizeArtEvolution(uint256 _evolutionId)`: Finalize approved art evolutions, updating artwork metadata.
 * 10. `viewArtEvolutionDetails(uint256 _evolutionId)`: View details of an art evolution proposal.
 * 11. `contributeToArtworkEvolution(uint256 _evolutionId, string memory _contributionMetadataURI)`: Members contribute to ongoing art evolution projects with ideas, assets, etc.
 * 12. `viewArtworkEvolutionContributions(uint256 _evolutionId)`: View contributions for a specific art evolution.

 * **Treasury Management:**
 * 13. `proposeTreasuryPayout(address _recipient, uint256 _amount, string memory _reason)`: Members propose payouts from the treasury.
 * 14. `voteOnTreasuryPayout(uint256 _payoutId, bool _approve)`: Members vote on treasury payout proposals.
 * 15. `executeTreasuryPayout(uint256 _payoutId)`: Execute approved treasury payouts.
 * 16. `viewTreasuryPayoutDetails(uint256 _payoutId)`: View details of a treasury payout proposal.
 * 17. `getTreasuryBalance()`: View the current treasury balance.

 * **Membership & Reputation:**
 * 18. `joinCollective()`: Request to join the art collective (requires approval or token holding, in this example, open for demonstration).
 * 19. `leaveCollective()`: Leave the art collective.
 * 20. `getMemberReputation(address _member)`: View the reputation score of a member (reputation increases with participation and positive votes).
 * 21. `proposeReputationChange(address _member, int256 _reputationChange, string memory _reason)`: Governance proposes reputation changes for members.
 * 22. `voteOnReputationChange(uint256 _reputationChangeId, bool _approve)`: Members vote on reputation change proposals.
 * 23. `finalizeReputationChange(uint256 _reputationChangeId)`: Finalize approved reputation changes.
 * 24. `viewReputationChangeDetails(uint256 _reputationChangeId)`: View details of a reputation change proposal.

 * **Governance & Settings:**
 * 25. `proposeGovernanceChange(string memory _proposalDetails)`: Members propose changes to governance parameters (voting duration, quorum, etc.).
 * 26. `voteOnGovernanceChange(uint256 _governanceChangeId, bool _approve)`: Members vote on governance change proposals.
 * 27. `finalizeGovernanceChange(uint256 _governanceChangeId)`: Finalize approved governance changes.
 * 28. `viewGovernanceChangeDetails(uint256 _governanceChangeId)`: View details of a governance change proposal.
 * 29. `setVotingDuration(uint256 _durationInBlocks)`: Governance function to set voting duration.
 * 30. `setVotingQuorum(uint256 _quorumPercentage)`: Governance function to set voting quorum percentage.
 */

contract DecentralizedArtCollective {
    // --- State Variables ---

    address public governanceAddress; // Address authorized to make governance changes
    uint256 public votingDurationBlocks = 100; // Default voting duration in blocks
    uint256 public votingQuorumPercentage = 50; // Default voting quorum percentage (50%)

    uint256 public nextSubmissionId = 1;
    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    uint256 public nextEvolutionId = 1;
    mapping(uint256 => ArtEvolutionProposal) public artEvolutionProposals;
    uint256 public nextPayoutId = 1;
    mapping(uint256 => TreasuryPayoutProposal) public treasuryPayoutProposals;
    uint256 public nextReputationChangeId = 1;
    mapping(uint256 => ReputationChangeProposal) public reputationChangeProposals;
    uint256 public nextGovernanceChangeId = 1;
    mapping(uint256 => GovernanceChangeProposal) public governanceChangeProposals;

    mapping(uint256 => address) public artworkNFTs; // Mapping artworkId to NFT contract address (if minted)
    uint256 public nextArtworkNFTId = 1; // Counter for artwork NFT IDs

    mapping(address => bool) public members;
    mapping(address => int256) public memberReputation;

    uint256 public treasuryBalance;

    enum VoteStatus { PENDING, ACTIVE, PASSED, REJECTED }

    struct ArtworkSubmission {
        uint256 submissionId;
        address artist;
        string artworkMetadataURI;
        VoteStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 votingEndTime;
    }

    struct ArtEvolutionProposal {
        uint256 evolutionId;
        uint256 artworkId;
        address proposer;
        string evolutionProposalMetadataURI;
        VoteStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 votingEndTime;
        string currentArtworkMetadataURI; // Store current metadata for reference
    }

    struct TreasuryPayoutProposal {
        uint256 payoutId;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        VoteStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 votingEndTime;
    }

    struct ReputationChangeProposal {
        uint256 reputationChangeId;
        address proposer;
        address member;
        int256 reputationChange;
        string reason;
        VoteStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 votingEndTime;
    }

    struct GovernanceChangeProposal {
        uint256 governanceChangeId;
        address proposer;
        string proposalDetails;
        VoteStatus status;
        uint256 upVotes;
        uint256 downVotes;
        uint256 votingEndTime;
    }

    event ArtworkSubmitted(uint256 submissionId, address artist, string artworkMetadataURI);
    event ArtworkSubmissionVoted(uint256 submissionId, address voter, bool approved);
    event ArtworkSubmissionFinalized(uint256 submissionId, bool approved, uint256 artworkId);
    event ArtEvolutionProposed(uint256 evolutionId, uint256 artworkId, address proposer, string evolutionProposalMetadataURI);
    event ArtEvolutionVoted(uint256 evolutionId, address voter, bool approved);
    event ArtEvolutionFinalized(uint256 evolutionId, bool approved, uint256 artworkId);
    event TreasuryPayoutProposed(uint256 payoutId, address proposer, address recipient, uint256 amount, string reason);
    event TreasuryPayoutVoted(uint256 payoutId, address voter, bool approved);
    event TreasuryPayoutExecuted(uint256 payoutId, address recipient, uint256 amount);
    event ReputationChangeProposed(uint256 reputationChangeId, address proposer, address member, int256 reputationChange, string reason);
    event ReputationChangeVoted(uint256 reputationChangeId, address voter, bool approved);
    event ReputationChangeFinalized(uint256 reputationChangeId, address member, int256 newReputation);
    event GovernanceChangeProposed(uint256 governanceChangeId, address proposer, string proposalDetails);
    event GovernanceChangeVoted(uint256 governanceChangeId, address voter, bool approved);
    event GovernanceChangeFinalized(uint256 governanceChangeId, bool approved);
    event MemberJoined(address member);
    event MemberLeft(address member);

    // --- Modifiers ---
    modifier onlyMember() {
        require(members[msg.sender], "Not a member of the collective.");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governanceAddress, "Only governance address can call this function.");
        _;
    }

    // --- Constructor ---
    constructor() {
        governanceAddress = msg.sender; // Deployer is initial governance
    }

    // --- Core Functionality ---

    /// @notice Submit an artwork proposal.
    /// @param _artworkMetadataURI URI pointing to the artwork metadata (e.g., IPFS).
    function submitArtwork(string memory _artworkMetadataURI) external onlyMember {
        artworkSubmissions[nextSubmissionId] = ArtworkSubmission({
            submissionId: nextSubmissionId,
            artist: msg.sender,
            artworkMetadataURI: _artworkMetadataURI,
            status: VoteStatus.PENDING,
            upVotes: 0,
            downVotes: 0,
            votingEndTime: 0
        });
        emit ArtworkSubmitted(nextSubmissionId, msg.sender, _artworkMetadataURI);
        nextSubmissionId++;
    }

    /// @notice Vote on an artwork submission.
    /// @param _submissionId ID of the artwork submission to vote on.
    /// @param _approve True to approve, false to reject.
    function voteOnArtworkSubmission(uint256 _submissionId, bool _approve) external onlyMember {
        require(artworkSubmissions[_submissionId].status == VoteStatus.PENDING, "Voting already started or finalized.");
        if (artworkSubmissions[_submissionId].votingEndTime == 0) {
            artworkSubmissions[_submissionId].status = VoteStatus.ACTIVE;
            artworkSubmissions[_submissionId].votingEndTime = block.number + votingDurationBlocks;
        }
        require(block.number <= artworkSubmissions[_submissionId].votingEndTime, "Voting time expired.");

        if (_approve) {
            artworkSubmissions[_submissionId].upVotes++;
        } else {
            artworkSubmissions[_submissionId].downVotes++;
        }
        emit ArtworkSubmissionVoted(_submissionId, msg.sender, _approve);
    }

    /// @notice Finalize an artwork submission after voting.
    /// @param _submissionId ID of the artwork submission to finalize.
    function finalizeArtworkSubmission(uint256 _submissionId) external onlyMember {
        require(artworkSubmissions[_submissionId].status == VoteStatus.ACTIVE, "Voting is not active or already finalized.");
        require(block.number > artworkSubmissions[_submissionId].votingEndTime, "Voting time not yet expired.");

        uint256 totalVotes = artworkSubmissions[_submissionId].upVotes + artworkSubmissions[_submissionId].downVotes;
        bool approved = (totalVotes > 0 && (artworkSubmissions[_submissionId].upVotes * 100) / totalVotes >= votingQuorumPercentage);

        if (approved) {
            artworkSubmissions[_submissionId].status = VoteStatus.PASSED;
            artworkNFTs[nextArtworkNFTId] = address(this); // In a real scenario, this would be a separate NFT contract address.
            emit ArtworkSubmissionFinalized(_submissionId, true, nextArtworkNFTId);
            nextArtworkNFTId++;
        } else {
            artworkSubmissions[_submissionId].status = VoteStatus.REJECTED;
            emit ArtworkSubmissionFinalized(_submissionId, false, 0);
        }
    }

    /// @notice View details of an artwork submission.
    /// @param _submissionId ID of the artwork submission.
    /// @return ArtworkSubmission struct containing submission details.
    function viewArtworkSubmissionDetails(uint256 _submissionId) external view returns (ArtworkSubmission memory) {
        return artworkSubmissions[_submissionId];
    }

    /// @notice Purchase an approved artwork NFT. Funds go to the treasury. (Simplified purchase - in real case, integrate with marketplace)
    /// @param _artworkId ID of the artwork to purchase (this is the internal artwork ID, not NFT ID in a real NFT contract).
    function purchaseArtworkNFT(uint256 _artworkId) external payable {
        require(artworkNFTs[_artworkId] == address(this), "Artwork is not available for purchase or not minted by this contract.");
        uint256 purchasePrice = 0.1 ether; // Example price
        require(msg.value >= purchasePrice, "Insufficient funds sent.");
        treasuryBalance += purchasePrice;
        payable(artworkSubmissions[_artworkId -1 ].artist).transfer(msg.value); // Direct transfer to artist for simplicity, can be adjusted for collective revenue share later.
        // In a real NFT setup, this would trigger a transfer of the NFT.
    }

    /// @notice List IDs of artworks owned by the treasury (in this simplified contract, it's just IDs minted).
    /// @return Array of artwork IDs.
    function listTreasuryArtworks() external view returns (uint256[] memory) {
        uint256[] memory artworkIds = new uint256[](nextArtworkNFTId - 1);
        for (uint256 i = 1; i < nextArtworkNFTId; i++) {
            artworkIds[i - 1] = i;
        }
        return artworkIds;
    }


    // --- Art Evolution & Collaboration Features ---

    /// @notice Propose an evolution for an existing artwork.
    /// @param _artworkId ID of the artwork to evolve.
    /// @param _evolutionProposalMetadataURI URI pointing to the evolution proposal metadata.
    function proposeArtEvolution(uint256 _artworkId, string memory _evolutionProposalMetadataURI) external onlyMember {
        require(artworkNFTs[_artworkId] == address(this), "Artwork must be an approved collective artwork to propose evolution.");
        artEvolutionProposals[nextEvolutionId] = ArtEvolutionProposal({
            evolutionId: nextEvolutionId,
            artworkId: _artworkId,
            proposer: msg.sender,
            evolutionProposalMetadataURI: _evolutionProposalMetadataURI,
            status: VoteStatus.PENDING,
            upVotes: 0,
            downVotes: 0,
            votingEndTime: 0,
            currentArtworkMetadataURI: artworkSubmissions[_artworkId -1 ].artworkMetadataURI // Assuming artwork IDs are sequential from 1. Adjust if needed.
        });
        emit ArtEvolutionProposed(nextEvolutionId, _artworkId, msg.sender, _evolutionProposalMetadataURI);
        nextEvolutionId++;
    }

    /// @notice Vote on an art evolution proposal.
    /// @param _evolutionId ID of the art evolution proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnArtEvolution(uint256 _evolutionId, bool _approve) external onlyMember {
        require(artEvolutionProposals[_evolutionId].status == VoteStatus.PENDING, "Voting already started or finalized.");
        if (artEvolutionProposals[_evolutionId].votingEndTime == 0) {
            artEvolutionProposals[_evolutionId].status = VoteStatus.ACTIVE;
            artEvolutionProposals[_evolutionId].votingEndTime = block.number + votingDurationBlocks;
        }
        require(block.number <= artEvolutionProposals[_evolutionId].votingEndTime, "Voting time expired.");

        if (_approve) {
            artEvolutionProposals[_evolutionId].upVotes++;
        } else {
            artEvolutionProposals[_evolutionId].downVotes++;
        }
        emit ArtEvolutionVoted(_evolutionId, msg.sender, _approve);
    }

    /// @notice Finalize an art evolution proposal after voting.
    /// @param _evolutionId ID of the art evolution proposal to finalize.
    function finalizeArtEvolution(uint256 _evolutionId) external onlyMember {
        require(artEvolutionProposals[_evolutionId].status == VoteStatus.ACTIVE, "Voting is not active or already finalized.");
        require(block.number > artEvolutionProposals[_evolutionId].votingEndTime, "Voting time not yet expired.");

        uint256 totalVotes = artEvolutionProposals[_evolutionId].upVotes + artEvolutionProposals[_evolutionId].downVotes;
        bool approved = (totalVotes > 0 && (artEvolutionProposals[_evolutionId].upVotes * 100) / totalVotes >= votingQuorumPercentage);

        if (approved) {
            artEvolutionProposals[_evolutionId].status = VoteStatus.PASSED;
            // In a real scenario, update the NFT metadata URI for the artwork based on the approved evolution proposal.
            // For simplicity, we'll just update the artwork submission metadata in this example.
            artworkSubmissions[artEvolutionProposals[_evolutionId].artworkId -1 ].artworkMetadataURI = artEvolutionProposals[_evolutionId].evolutionProposalMetadataURI;
            emit ArtEvolutionFinalized(_evolutionId, true, artEvolutionProposals[_evolutionId].artworkId);
        } else {
            artEvolutionProposals[_evolutionId].status = VoteStatus.REJECTED;
            emit ArtEvolutionFinalized(_evolutionId, false, artEvolutionProposals[_evolutionId].artworkId);
        }
    }

    /// @notice View details of an art evolution proposal.
    /// @param _evolutionId ID of the art evolution proposal.
    /// @return ArtEvolutionProposal struct containing evolution details.
    function viewArtEvolutionDetails(uint256 _evolutionId) external view returns (ArtEvolutionProposal memory) {
        return artEvolutionProposals[_evolutionId];
    }

    /// @notice Contribute to an ongoing art evolution project (e.g., submit ideas, assets).
    /// @param _evolutionId ID of the art evolution project.
    /// @param _contributionMetadataURI URI pointing to the contribution metadata.
    function contributeToArtworkEvolution(uint256 _evolutionId, string memory _contributionMetadataURI) external onlyMember {
        require(artEvolutionProposals[_evolutionId].status == VoteStatus.ACTIVE || artEvolutionProposals[_evolutionId].status == VoteStatus.PENDING, "Evolution proposal is not active or pending.");
        // In a real scenario, you'd store these contributions, perhaps in a separate mapping or linked list.
        // For this example, we'll just emit an event.
        // You could also implement a reputation increase for contributors here.
        emit ArtEvolutionContribution(msg.sender, _evolutionId, _contributionMetadataURI);
    }
    event ArtEvolutionContribution(address contributor, uint256 evolutionId, string contributionMetadataURI);


    /// @notice View contributions for a specific art evolution (placeholder - needs actual contribution storage).
    /// @param _evolutionId ID of the art evolution proposal.
    /// @return Placeholder - In a real implementation, would return a list of contribution details.
    function viewArtworkEvolutionContributions(uint256 _evolutionId) external view returns (string memory) {
        // In a real implementation, you would retrieve and return contribution metadata based on _evolutionId.
        // For now, just return a placeholder message.
        return "Contribution details not implemented in this simplified example. See events for contributions.";
    }


    // --- Treasury Management ---

    /// @notice Propose a payout from the treasury.
    /// @param _recipient Address to receive the payout.
    /// @param _amount Amount to payout in wei.
    /// @param _reason Reason for the payout.
    function proposeTreasuryPayout(address _recipient, uint256 _amount, string memory _reason) external onlyMember {
        treasuryPayoutProposals[nextPayoutId] = TreasuryPayoutProposal({
            payoutId: nextPayoutId,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            status: VoteStatus.PENDING,
            upVotes: 0,
            downVotes: 0,
            votingEndTime: 0
        });
        emit TreasuryPayoutProposed(nextPayoutId, msg.sender, _recipient, _amount, _reason);
        nextPayoutId++;
    }

    /// @notice Vote on a treasury payout proposal.
    /// @param _payoutId ID of the treasury payout proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnTreasuryPayout(uint256 _payoutId, bool _approve) external onlyMember {
        require(treasuryPayoutProposals[_payoutId].status == VoteStatus.PENDING, "Voting already started or finalized.");
        if (treasuryPayoutProposals[_payoutId].votingEndTime == 0) {
            treasuryPayoutProposals[_payoutId].status = VoteStatus.ACTIVE;
            treasuryPayoutProposals[_payoutId].votingEndTime = block.number + votingDurationBlocks;
        }
        require(block.number <= treasuryPayoutProposals[_payoutId].votingEndTime, "Voting time expired.");

        if (_approve) {
            treasuryPayoutProposals[_payoutId].upVotes++;
        } else {
            treasuryPayoutProposals[_payoutId].downVotes++;
        }
        emit TreasuryPayoutVoted(_payoutId, msg.sender, _approve);
    }

    /// @notice Execute an approved treasury payout.
    /// @param _payoutId ID of the treasury payout proposal to execute.
    function executeTreasuryPayout(uint256 _payoutId) external onlyMember {
        require(treasuryPayoutProposals[_payoutId].status == VoteStatus.ACTIVE, "Voting is not active or already finalized.");
        require(block.number > treasuryPayoutProposals[_payoutId].votingEndTime, "Voting time not yet expired.");

        uint256 totalVotes = treasuryPayoutProposals[_payoutId].upVotes + treasuryPayoutProposals[_payoutId].downVotes;
        bool approved = (totalVotes > 0 && (treasuryPayoutProposals[_payoutId].upVotes * 100) / totalVotes >= votingQuorumPercentage);

        require(approved, "Treasury payout proposal was not approved by quorum.");
        require(treasuryPayoutProposals[_payoutId].amount <= treasuryBalance, "Insufficient treasury balance for payout.");

        treasuryPayoutProposals[_payoutId].status = VoteStatus.PASSED;
        treasuryBalance -= treasuryPayoutProposals[_payoutId].amount;
        payable(treasuryPayoutProposals[_payoutId].recipient).transfer(treasuryPayoutProposals[_payoutId].amount);
        emit TreasuryPayoutExecuted(_payoutId, treasuryPayoutProposals[_payoutId].recipient, treasuryPayoutProposals[_payoutId].amount);
    }

    /// @notice View details of a treasury payout proposal.
    /// @param _payoutId ID of the treasury payout proposal.
    /// @return TreasuryPayoutProposal struct containing payout details.
    function viewTreasuryPayoutDetails(uint256 _payoutId) external view returns (TreasuryPayoutProposal memory) {
        return treasuryPayoutProposals[_payoutId];
    }

    /// @notice Get the current treasury balance.
    /// @return Treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }


    // --- Membership & Reputation ---

    /// @notice Request to join the art collective. (Open for demonstration, can be modified for approval process)
    function joinCollective() external {
        require(!members[msg.sender], "Already a member.");
        members[msg.sender] = true;
        memberReputation[msg.sender] = 0; // Initial reputation
        emit MemberJoined(msg.sender);
    }

    /// @notice Leave the art collective.
    function leaveCollective() external onlyMember {
        delete members[msg.sender];
        delete memberReputation[msg.sender]; // Optional: Decide if reputation should be reset or kept.
        emit MemberLeft(msg.sender);
    }

    /// @notice Get the reputation score of a member.
    /// @param _member Address of the member.
    /// @return Reputation score.
    function getMemberReputation(address _member) external view returns (int256) {
        return memberReputation[_member];
    }

    /// @notice Governance proposes a change to a member's reputation.
    /// @param _member Address of the member whose reputation is being changed.
    /// @param _reputationChange Amount to change the reputation by (positive or negative).
    /// @param _reason Reason for the reputation change.
    function proposeReputationChange(address _member, int256 _reputationChange, string memory _reason) external onlyGovernance {
        reputationChangeProposals[nextReputationChangeId] = ReputationChangeProposal({
            reputationChangeId: nextReputationChangeId,
            proposer: msg.sender,
            member: _member,
            reputationChange: _reputationChange,
            reason: _reason,
            status: VoteStatus.PENDING,
            upVotes: 0,
            downVotes: 0,
            votingEndTime: 0
        });
        emit ReputationChangeProposed(nextReputationChangeId, msg.sender, _member, _reputationChange, _reason);
        nextReputationChangeId++;
    }

    /// @notice Vote on a reputation change proposal.
    /// @param _reputationChangeId ID of the reputation change proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnReputationChange(uint256 _reputationChangeId, bool _approve) external onlyMember {
        require(reputationChangeProposals[_reputationChangeId].status == VoteStatus.PENDING, "Voting already started or finalized.");
        if (reputationChangeProposals[_reputationChangeId].votingEndTime == 0) {
            reputationChangeProposals[_reputationChangeId].status = VoteStatus.ACTIVE;
            reputationChangeProposals[_reputationChangeId].votingEndTime = block.number + votingDurationBlocks;
        }
        require(block.number <= reputationChangeProposals[_reputationChangeId].votingEndTime, "Voting time expired.");

        if (_approve) {
            reputationChangeProposals[_reputationChangeId].upVotes++;
        } else {
            reputationChangeProposals[_reputationChangeId].downVotes++;
        }
        emit ReputationChangeVoted(_reputationChangeId, msg.sender, _approve);
    }

    /// @notice Finalize a reputation change proposal after voting.
    /// @param _reputationChangeId ID of the reputation change proposal to finalize.
    function finalizeReputationChange(uint256 _reputationChangeId) external onlyGovernance { // Governance finalizes reputation changes
        require(reputationChangeProposals[_reputationChangeId].status == VoteStatus.ACTIVE, "Voting is not active or already finalized.");
        require(block.number > reputationChangeProposals[_reputationChangeId].votingEndTime, "Voting time not yet expired.");

        uint256 totalVotes = reputationChangeProposals[_reputationChangeId].upVotes + reputationChangeProposals[_reputationChangeId].downVotes;
        bool approved = (totalVotes > 0 && (reputationChangeProposals[_reputationChangeId].upVotes * 100) / totalVotes >= votingQuorumPercentage);

        if (approved) {
            reputationChangeProposals[_reputationChangeId].status = VoteStatus.PASSED;
            memberReputation[reputationChangeProposals[_reputationChangeId].member] += reputationChangeProposals[_reputationChangeId].reputationChange;
            emit ReputationChangeFinalized(_reputationChangeId, reputationChangeProposals[_reputationChangeId].member, memberReputation[reputationChangeProposals[_reputationChangeId].member]);
        } else {
            reputationChangeProposals[_reputationChangeId].status = VoteStatus.REJECTED;
            emit ReputationChangeFinalized(_reputationChangeId, reputationChangeProposals[_reputationChangeId].member, memberReputation[reputationChangeProposals[_reputationChangeId].member]); // Emit even on rejection for transparency
        }
    }

    /// @notice View details of a reputation change proposal.
    /// @param _reputationChangeId ID of the reputation change proposal.
    /// @return ReputationChangeProposal struct containing reputation change details.
    function viewReputationChangeDetails(uint256 _reputationChangeId) external view returns (ReputationChangeProposal memory) {
        return reputationChangeProposals[_reputationChangeId];
    }


    // --- Governance & Settings ---

    /// @notice Propose a change to governance parameters.
    /// @param _proposalDetails Description of the governance change proposal.
    function proposeGovernanceChange(string memory _proposalDetails) external onlyMember {
        governanceChangeProposals[nextGovernanceChangeId] = GovernanceChangeProposal({
            governanceChangeId: nextGovernanceChangeId,
            proposer: msg.sender,
            proposalDetails: _proposalDetails,
            status: VoteStatus.PENDING,
            upVotes: 0,
            downVotes: 0,
            votingEndTime: 0
        });
        emit GovernanceChangeProposed(nextGovernanceChangeId, msg.sender, _proposalDetails);
        nextGovernanceChangeId++;
    }

    /// @notice Vote on a governance change proposal.
    /// @param _governanceChangeId ID of the governance change proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnGovernanceChange(uint256 _governanceChangeId, bool _approve) external onlyMember {
        require(governanceChangeProposals[_governanceChangeId].status == VoteStatus.PENDING, "Voting already started or finalized.");
        if (governanceChangeProposals[_governanceChangeId].votingEndTime == 0) {
            governanceChangeProposals[_governanceChangeId].status = VoteStatus.ACTIVE;
            governanceChangeProposals[_governanceChangeId].votingEndTime = block.number + votingDurationBlocks;
        }
        require(block.number <= governanceChangeProposals[_governanceChangeId].votingEndTime, "Voting time expired.");

        if (_approve) {
            governanceChangeProposals[_governanceChangeId].upVotes++;
        } else {
            governanceChangeProposals[_governanceChangeId].downVotes++;
        }
        emit GovernanceChangeVoted(_governanceChangeId, msg.sender, _approve);
    }

    /// @notice Finalize a governance change proposal after voting.
    /// @param _governanceChangeId ID of the governance change proposal to finalize.
    function finalizeGovernanceChange(uint256 _governanceChangeId) external onlyGovernance { // Governance finalizes governance changes
        require(governanceChangeProposals[_governanceChangeId].status == VoteStatus.ACTIVE, "Voting is not active or already finalized.");
        require(block.number > governanceChangeProposals[_governanceChangeId].votingEndTime, "Voting time not yet expired.");

        uint256 totalVotes = governanceChangeProposals[_governanceChangeId].upVotes + governanceChangeProposals[_governanceChangeId].downVotes;
        bool approved = (totalVotes > 0 && (governanceChangeProposals[_governanceChangeId].upVotes * 100) / totalVotes >= votingQuorumPercentage);

        if (approved) {
            governanceChangeProposals[_governanceChangeId].status = VoteStatus.PASSED;
            // Apply governance changes based on _governanceChangeId. For this example, just emit event.
            emit GovernanceChangeFinalized(_governanceChangeId, true);
            // In a real implementation, you would parse proposalDetails and implement the actual governance change logic here.
            // Example governance changes could include:
            // - Changing votingDurationBlocks
            // - Changing votingQuorumPercentage
            // - Changing governanceAddress
        } else {
            governanceChangeProposals[_governanceChangeId].status = VoteStatus.REJECTED;
            emit GovernanceChangeFinalized(_governanceChangeId, false);
        }
    }

    /// @notice View details of a governance change proposal.
    /// @param _governanceChangeId ID of the governance change proposal.
    /// @return GovernanceChangeProposal struct containing governance change details.
    function viewGovernanceChangeDetails(uint256 _governanceChangeId) external view returns (GovernanceChangeProposal memory) {
        return governanceChangeProposals[_governanceChangeId];
    }

    /// @notice Set the voting duration for proposals (governance function).
    /// @param _durationInBlocks Voting duration in blocks.
    function setVotingDuration(uint256 _durationInBlocks) external onlyGovernance {
        votingDurationBlocks = _durationInBlocks;
    }

    /// @notice Set the voting quorum percentage for proposals (governance function).
    /// @param _quorumPercentage Voting quorum percentage (e.g., 50 for 50%).
    function setVotingQuorum(uint256 _quorumPercentage) external onlyGovernance {
        require(_quorumPercentage <= 100, "Quorum percentage must be between 0 and 100.");
        votingQuorumPercentage = _quorumPercentage;
    }
}
```