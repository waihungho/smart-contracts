```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized autonomous art collective.
 * It enables artists to submit artwork, community voting on submissions,
 * NFT minting for approved artworks, collaborative art projects,
 * fractional ownership, dynamic royalties, reputation system,
 * community treasury management, and more.
 *
 * Function Summary:
 * 1. submitArtwork(string memory _metadataURI, uint256 _submissionFee): Allows artists to submit artwork proposals with metadata and a fee.
 * 2. voteOnArtwork(uint256 _submissionId, bool _approve): Members can vote to approve or reject submitted artwork.
 * 3. mintNFT(uint256 _submissionId): Mints an NFT for an approved artwork after successful voting.
 * 4. createCollaborativeProject(string memory _projectName, string memory _projectDescription, uint256 _maxCollaborators): Initiates a collaborative art project proposal.
 * 5. joinCollaborativeProject(uint256 _projectId): Allows members to join an open collaborative project.
 * 6. contributeToProject(uint256 _projectId, string memory _contributionData): Members can contribute to a collaborative project.
 * 7. finalizeCollaborativeProject(uint256 _projectId, string memory _finalMetadataURI): Finalizes a collaborative project after completion.
 * 8. purchaseFractionalOwnership(uint256 _nftTokenId, uint256 _amount): Allows members to purchase fractional ownership of an NFT.
 * 9. sellFractionalOwnership(uint256 _nftTokenId, uint256 _amount): Allows members to sell fractional ownership of an NFT.
 * 10. setDynamicRoyalty(uint256 _nftTokenId, uint256 _newRoyaltyPercentage): Sets a dynamic royalty percentage for an NFT based on community vote (governance).
 * 11. reportInfringement(uint256 _nftTokenId, string memory _reportDetails): Allows members to report potential copyright infringement of an NFT.
 * 12. proposeReputationReward(address _member, uint256 _reputationPoints, string memory _reason): Proposes a reputation reward for a member.
 * 13. voteOnReputationReward(uint256 _proposalId, bool _approve): Members vote on reputation reward proposals.
 * 14. redeemReputationRewards(): Members can redeem accumulated reputation points for benefits (future features).
 * 15. depositToTreasury(): Allows members to deposit funds into the community treasury.
 * 16. proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason): Proposes spending funds from the community treasury.
 * 17. voteOnTreasurySpending(uint256 _proposalId, bool _approve): Members vote on treasury spending proposals.
 * 18. withdrawTreasuryFunds(uint256 _proposalId): Executes approved treasury spending proposals.
 * 19. setMembershipFee(uint256 _newFee): Admin function to set the membership fee.
 * 20. joinCollective(): Allows users to join the art collective by paying a membership fee.
 * 21. leaveCollective(): Allows members to leave the collective.
 * 22. pauseContract(): Admin function to pause the contract in case of emergency.
 * 23. unpauseContract(): Admin function to unpause the contract.
 * 24. setPlatformFee(uint256 _newFee): Admin function to set the platform fee for NFT sales.
 * 25. withdrawPlatformFees(): Admin function to withdraw accumulated platform fees.
 */

contract DecentralizedAutonomousArtCollective {
    // --- State Variables ---

    string public contractName = "Decentralized Autonomous Art Collective";
    address public admin;
    uint256 public membershipFee = 0.1 ether; // Initial membership fee
    uint256 public platformFeePercentage = 5; // Platform fee on NFT sales (5%)

    uint256 public submissionFee = 0.01 ether; // Fee to submit artwork proposals
    uint256 public submissionCounter = 0;
    mapping(uint256 => Submission) public submissions;

    uint256 public nftCounter = 0;
    mapping(uint256 => NFTArt) public nfts;
    mapping(uint256 => mapping(address => uint256)) public nftFractionalOwnership; // nftId => owner => amount

    uint256 public projectCounter = 0;
    mapping(uint256 => CollaborativeProject) public projects;

    uint256 public reputationRewardProposalCounter = 0;
    mapping(uint256 => ReputationRewardProposal) public reputationRewardProposals;
    mapping(address => uint256) public memberReputation;

    uint256 public treasurySpendingProposalCounter = 0;
    mapping(uint256 => TreasurySpendingProposal) public treasurySpendingProposals;
    uint256 public communityTreasuryBalance = 0;

    mapping(address => bool) public isMember;
    address[] public members;

    bool public paused = false;

    // --- Structs ---

    struct Submission {
        uint256 id;
        address artist;
        string metadataURI;
        uint256 submissionFee;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool finalized;
    }

    struct NFTArt {
        uint256 tokenId;
        address artist;
        string metadataURI;
        uint256 royaltyPercentage; // Dynamic royalty
        bool infringementReported;
    }

    struct CollaborativeProject {
        uint256 projectId;
        string projectName;
        string projectDescription;
        address creator;
        uint256 maxCollaborators;
        address[] collaborators;
        string finalMetadataURI;
        bool finalized;
    }

    struct ReputationRewardProposal {
        uint256 proposalId;
        address proposer;
        address member;
        uint256 reputationPoints;
        string reason;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool finalized;
    }

    struct TreasurySpendingProposal {
        uint256 proposalId;
        address proposer;
        address recipient;
        uint256 amount;
        string reason;
        uint256 upvotes;
        uint256 downvotes;
        bool approved;
        bool finalized;
    }

    // --- Events ---

    event ArtworkSubmitted(uint256 submissionId, address artist, string metadataURI);
    event ArtworkVoted(uint256 submissionId, address voter, bool approved);
    event ArtworkMinted(uint256 nftTokenId, uint256 submissionId, address artist);
    event CollaborativeProjectCreated(uint256 projectId, string projectName, address creator);
    event CollaborativeProjectJoined(uint256 projectId, address member);
    event CollaborativeProjectContribution(uint256 projectId, address contributor, string contributionData);
    event CollaborativeProjectFinalized(uint256 projectId, uint256 nftTokenId, string finalMetadataURI);
    event FractionalOwnershipPurchased(uint256 nftTokenId, address buyer, uint256 amount);
    event FractionalOwnershipSold(uint256 nftTokenId, address seller, uint256 amount);
    event DynamicRoyaltySet(uint256 nftTokenId, uint256 newRoyaltyPercentage);
    event InfringementReported(uint256 nftTokenId, address reporter, string reportDetails);
    event ReputationRewardProposed(uint256 proposalId, address proposer, address member, uint256 reputationPoints);
    event ReputationRewardVoted(uint256 proposalId, address voter, bool approved);
    event ReputationRewardRedeemed(address member, uint256 reputationPoints);
    event TreasuryDeposit(address depositor, uint256 amount);
    event TreasurySpendingProposed(uint256 proposalId, address proposer, address recipient, uint256 amount);
    event TreasurySpendingVoted(uint256 proposalId, address voter, bool approved);
    event TreasuryFundsWithdrawn(uint256 proposalId, address recipient, uint256 amount);
    event MembershipJoined(address member);
    event MembershipLeft(address member);
    event ContractPaused();
    event ContractUnpaused();
    event PlatformFeeSet(uint256 newFee);
    event PlatformFeesWithdrawn(address admin, uint256 amount);
    event MembershipFeeSet(uint256 newFee);

    // --- Modifiers ---

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier submissionExists(uint256 _submissionId) {
        require(_submissionId > 0 && _submissionId <= submissionCounter, "Submission does not exist.");
        _;
    }

    modifier nftExists(uint256 _nftTokenId) {
        require(_nftTokenId > 0 && _nftTokenId <= nftCounter, "NFT does not exist.");
        _;
    }

    modifier projectExists(uint256 _projectId) {
        require(_projectId > 0 && _projectId <= projectCounter, "Project does not exist.");
        _;
    }

    modifier reputationProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= reputationRewardProposalCounter, "Reputation proposal does not exist.");
        _;
    }

    modifier treasuryProposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= treasurySpendingProposalCounter, "Treasury proposal does not exist.");
        _;
    }


    // --- Constructor ---

    constructor() {
        admin = msg.sender;
    }

    // --- Core Functions ---

    /// @notice Allows artists to submit artwork proposals with metadata and a fee.
    /// @param _metadataURI URI pointing to the artwork's metadata.
    /// @param _submissionFee Fee required to submit the artwork.
    function submitArtwork(string memory _metadataURI, uint256 _submissionFee) external payable onlyMember notPaused {
        require(msg.value >= _submissionFee, "Insufficient submission fee paid.");
        submissionCounter++;
        submissions[submissionCounter] = Submission({
            id: submissionCounter,
            artist: msg.sender,
            metadataURI: _metadataURI,
            submissionFee: _submissionFee,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            finalized: false
        });
        emit ArtworkSubmitted(submissionCounter, msg.sender, _metadataURI);
    }

    /// @notice Members can vote to approve or reject submitted artwork.
    /// @param _submissionId ID of the artwork submission.
    /// @param _approve True to approve, false to reject.
    function voteOnArtwork(uint256 _submissionId, bool _approve) external onlyMember notPaused submissionExists(_submissionId) {
        require(!submissions[_submissionId].finalized, "Submission voting already finalized.");
        if (_approve) {
            submissions[_submissionId].upvotes++;
        } else {
            submissions[_submissionId].downvotes++;
        }
        emit ArtworkVoted(_submissionId, msg.sender, _approve);
    }

    /// @notice Mints an NFT for an approved artwork after successful voting.
    /// @dev Approval logic can be customized (e.g., majority vote, quorum).
    /// @param _submissionId ID of the approved artwork submission.
    function mintNFT(uint256 _submissionId) external onlyMember notPaused submissionExists(_submissionId) {
        require(!submissions[_submissionId].finalized, "Submission already finalized.");
        require(!submissions[_submissionId].approved, "Submission already approved, minting already done or pending.");

        // Simple approval logic: more upvotes than downvotes
        if (submissions[_submissionId].upvotes > submissions[_submissionId].downvotes) {
            submissions[_submissionId].approved = true;
            nftCounter++;
            nfts[nftCounter] = NFTArt({
                tokenId: nftCounter,
                artist: submissions[_submissionId].artist,
                metadataURI: submissions[_submissionId].metadataURI,
                royaltyPercentage: 5, // Initial royalty percentage
                infringementReported: false
            });
            submissions[_submissionId].finalized = true; // Mark submission as finalized after minting
            emit ArtworkMinted(nftCounter, _submissionId, submissions[_submissionId].artist);
        } else {
            submissions[_submissionId].finalized = true; // Mark as finalized even if rejected
            submissions[_submissionId].approved = false; // Explicitly mark as not approved.
            // Optionally, handle rejection logic here, like refunding submission fee (if applicable and defined in contract logic).
        }
    }

    /// @notice Initiates a collaborative art project proposal.
    /// @param _projectName Name of the project.
    /// @param _projectDescription Description of the project.
    /// @param _maxCollaborators Maximum number of collaborators allowed.
    function createCollaborativeProject(string memory _projectName, string memory _projectDescription, uint256 _maxCollaborators) external onlyMember notPaused {
        projectCounter++;
        projects[projectCounter] = CollaborativeProject({
            projectId: projectCounter,
            projectName: _projectName,
            projectDescription: _projectDescription,
            creator: msg.sender,
            maxCollaborators: _maxCollaborators,
            collaborators: new address[](0),
            finalMetadataURI: "",
            finalized: false
        });
        emit CollaborativeProjectCreated(projectCounter, _projectName, msg.sender);
    }

    /// @notice Allows members to join an open collaborative project.
    /// @param _projectId ID of the collaborative project.
    function joinCollaborativeProject(uint256 _projectId) external onlyMember notPaused projectExists(_projectId) {
        require(!projects[_projectId].finalized, "Project is finalized.");
        require(projects[_projectId].collaborators.length < projects[_projectId].maxCollaborators, "Project is full.");
        bool alreadyJoined = false;
        for (uint256 i = 0; i < projects[_projectId].collaborators.length; i++) {
            if (projects[_projectId].collaborators[i] == msg.sender) {
                alreadyJoined = true;
                break;
            }
        }
        require(!alreadyJoined, "Already joined this project.");

        projects[_projectId].collaborators.push(msg.sender);
        emit CollaborativeProjectJoined(_projectId, msg.sender);
    }

    /// @notice Members can contribute to a collaborative project.
    /// @param _projectId ID of the collaborative project.
    /// @param _contributionData Data representing the contribution (e.g., IPFS hash, text description).
    function contributeToProject(uint256 _projectId, string memory _contributionData) external onlyMember notPaused projectExists(_projectId) {
        require(!projects[_projectId].finalized, "Project is finalized.");
        bool isCollaborator = false;
        for (uint256 i = 0; i < projects[_projectId].collaborators.length; i++) {
            if (projects[_projectId].collaborators[i] == msg.sender) {
                isCollaborator = true;
                break;
            }
        }
        require(isCollaborator, "Must be a collaborator to contribute.");

        // Store or process contribution data here (e.g., off-chain storage, event emission)
        emit CollaborativeProjectContribution(_projectId, msg.sender, _contributionData);
    }

    /// @notice Finalizes a collaborative project after completion, minting an NFT for the result.
    /// @param _projectId ID of the collaborative project.
    /// @param _finalMetadataURI URI pointing to the final collaborative artwork's metadata.
    function finalizeCollaborativeProject(uint256 _projectId, string memory _finalMetadataURI) external onlyMember notPaused projectExists(_projectId) {
        require(!projects[_projectId].finalized, "Project already finalized.");
        require(projects[_projectId].creator == msg.sender, "Only project creator can finalize."); // Or governance based finalization

        projects[_projectId].finalized = true;
        projects[_projectId].finalMetadataURI = _finalMetadataURI;

        nftCounter++;
        nfts[nftCounter] = NFTArt({
            tokenId: nftCounter,
            artist: address(this), // Collective owns the collaborative NFT initially
            metadataURI: _finalMetadataURI,
            royaltyPercentage: 5, // Initial royalty
            infringementReported: false
        });
        emit CollaborativeProjectFinalized(_projectId, nftCounter, _finalMetadataURI);

        // Distribute ownership/rewards to collaborators (complex logic to be added here based on project design)
        // For simplicity, let's transfer NFT ownership to the project creator for now.
        // (In a real system, consider fractional NFTs, governance voting on distribution, etc.)
        // Transfer NFT ownership to project creator (example, can be more complex distribution logic)
        // NFT ownership transfer logic would be needed here (requires NFT standard implementation, e.g., ERC721 or ERC1155)
    }

    /// @notice Allows members to purchase fractional ownership of an NFT.
    /// @dev Simple fractional ownership - needs more sophisticated logic for real-world use cases (e.g., ERC1155 for fractional NFTs).
    /// @param _nftTokenId ID of the NFT.
    /// @param _amount Amount of fractional ownership to purchase.
    function purchaseFractionalOwnership(uint256 _nftTokenId, uint256 _amount) external payable onlyMember notPaused nftExists(_nftTokenId) {
        // Basic example - no price logic yet, assuming free fractional ownership for simplicity
        nftFractionalOwnership[_nftTokenId][msg.sender] += _amount;
        emit FractionalOwnershipPurchased(_nftTokenId, msg.sender, _amount);
    }

    /// @notice Allows members to sell fractional ownership of an NFT.
    /// @dev Simple fractional ownership - needs more sophisticated logic for real-world use cases.
    /// @param _nftTokenId ID of the NFT.
    /// @param _amount Amount of fractional ownership to sell.
    function sellFractionalOwnership(uint256 _nftTokenId, uint256 _amount) external onlyMember notPaused nftExists(_nftTokenId) {
        require(nftFractionalOwnership[_nftTokenId][msg.sender] >= _amount, "Insufficient fractional ownership to sell.");
        nftFractionalOwnership[_nftTokenId][msg.sender] -= _amount;
        emit FractionalOwnershipSold(_nftTokenId, msg.sender, _amount);
    }

    /// @notice Sets a dynamic royalty percentage for an NFT based on community vote (governance).
    /// @dev This is a placeholder - actual governance voting implementation needed.
    /// @param _nftTokenId ID of the NFT.
    /// @param _newRoyaltyPercentage New royalty percentage.
    function setDynamicRoyalty(uint256 _nftTokenId, uint256 _newRoyaltyPercentage) external onlyMember notPaused nftExists(_nftTokenId) {
        // Placeholder - In a real system, this would be triggered by a governance proposal and voting process.
        // For now, allow any member to "propose" a royalty change (for demonstration purposes).
        nfts[_nftTokenId].royaltyPercentage = _newRoyaltyPercentage;
        emit DynamicRoyaltySet(_nftTokenId, _newRoyaltyPercentage);
    }

    /// @notice Allows members to report potential copyright infringement of an NFT.
    /// @param _nftTokenId ID of the NFT.
    /// @param _reportDetails Details of the infringement report.
    function reportInfringement(uint256 _nftTokenId, string memory _reportDetails) external onlyMember notPaused nftExists(_nftTokenId) {
        nfts[_nftTokenId].infringementReported = true; // Simple flag for demonstration.
        // In a real system, trigger a review process, potentially involving admin or community voting to resolve infringement claims.
        emit InfringementReported(_nftTokenId, msg.sender, _reportDetails);
    }

    // --- Reputation System ---

    /// @notice Proposes a reputation reward for a member.
    /// @param _member Address of the member to reward.
    /// @param _reputationPoints Amount of reputation points to reward.
    /// @param _reason Reason for the reputation reward.
    function proposeReputationReward(address _member, uint256 _reputationPoints, string memory _reason) external onlyMember notPaused {
        reputationRewardProposalCounter++;
        reputationRewardProposals[reputationRewardProposalCounter] = ReputationRewardProposal({
            proposalId: reputationRewardProposalCounter,
            proposer: msg.sender,
            member: _member,
            reputationPoints: _reputationPoints,
            reason: _reason,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            finalized: false
        });
        emit ReputationRewardProposed(reputationRewardProposalCounter, msg.sender, _member, _reputationPoints);
    }

    /// @notice Members vote on reputation reward proposals.
    /// @param _proposalId ID of the reputation reward proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnReputationReward(uint256 _proposalId, bool _approve) external onlyMember notPaused reputationProposalExists(_proposalId) {
        require(!reputationRewardProposals[_proposalId].finalized, "Reputation proposal voting already finalized.");
        if (_approve) {
            reputationRewardProposals[_proposalId].upvotes++;
        } else {
            reputationRewardProposals[_proposalId].downvotes++;
        }
        emit ReputationRewardVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Members can redeem accumulated reputation points for benefits (future features).
    /// @dev Placeholder - actual rewards and redemption logic to be defined.
    function redeemReputationRewards() external onlyMember notPaused {
        uint256 reputationToRedeem = memberReputation[msg.sender]; // Get current reputation
        require(reputationToRedeem > 0, "No reputation points to redeem.");

        // Placeholder - Define actual reward/benefit redemption logic here
        // Example:  Discount on future membership, access to premium features, etc.
        // For now, just reset reputation points for demonstration.
        memberReputation[msg.sender] = 0; // Reset after redemption (or partial reset, or tiered system)
        emit ReputationRewardRedeemed(msg.sender, reputationToRedeem);
    }

    // --- Community Treasury Management ---

    /// @notice Allows members to deposit funds into the community treasury.
    function depositToTreasury() external payable onlyMember notPaused {
        communityTreasuryBalance += msg.value;
        emit TreasuryDeposit(msg.sender, msg.value);
    }

    /// @notice Proposes spending funds from the community treasury.
    /// @param _recipient Address to receive the funds.
    /// @param _amount Amount to spend.
    /// @param _reason Reason for spending.
    function proposeTreasurySpending(address _recipient, uint256 _amount, string memory _reason) external onlyMember notPaused {
        require(communityTreasuryBalance >= _amount, "Insufficient funds in treasury.");
        treasurySpendingProposalCounter++;
        treasurySpendingProposals[treasurySpendingProposalCounter] = TreasurySpendingProposal({
            proposalId: treasurySpendingProposalCounter,
            proposer: msg.sender,
            recipient: _recipient,
            amount: _amount,
            reason: _reason,
            upvotes: 0,
            downvotes: 0,
            approved: false,
            finalized: false
        });
        emit TreasurySpendingProposed(treasurySpendingProposalCounter, msg.sender, _recipient, _amount);
    }

    /// @notice Members vote on treasury spending proposals.
    /// @param _proposalId ID of the treasury spending proposal.
    /// @param _approve True to approve, false to reject.
    function voteOnTreasurySpending(uint256 _proposalId, bool _approve) external onlyMember notPaused treasuryProposalExists(_proposalId) {
        require(!treasurySpendingProposals[_proposalId].finalized, "Treasury proposal voting already finalized.");
        if (_approve) {
            treasurySpendingProposals[_proposalId].upvotes++;
        } else {
            treasurySpendingProposals[_proposalId].downvotes++;
        }
        emit TreasurySpendingVoted(_proposalId, msg.sender, _approve);
    }

    /// @notice Executes approved treasury spending proposals.
    /// @dev Approval logic (e.g., majority, quorum) needs to be implemented.
    /// @param _proposalId ID of the treasury spending proposal.
    function withdrawTreasuryFunds(uint256 _proposalId) external onlyMember notPaused treasuryProposalExists(_proposalId) {
        require(!treasurySpendingProposals[_proposalId].finalized, "Treasury proposal already finalized.");
        require(!treasurySpendingProposals[_proposalId].approved, "Treasury proposal already approved or pending.");

        // Simple approval logic: more upvotes than downvotes
        if (treasurySpendingProposals[_proposalId].upvotes > treasurySpendingProposals[_proposalId].downvotes) {
            treasurySpendingProposals[_proposalId].approved = true;
            payable(treasurySpendingProposals[_proposalId].recipient).transfer(treasurySpendingProposals[_proposalId].amount);
            communityTreasuryBalance -= treasurySpendingProposals[_proposalId].amount;
            treasurySpendingProposals[_proposalId].finalized = true; // Mark as finalized after execution
            emit TreasuryFundsWithdrawn(_proposalId, treasurySpendingProposals[_proposalId].recipient, treasurySpendingProposals[_proposalId].amount);
        } else {
            treasurySpendingProposals[_proposalId].finalized = true; // Mark as finalized even if rejected
            treasurySpendingProposals[_proposalId].approved = false; // Explicitly mark as not approved.
        }
    }


    // --- Membership Management ---

    /// @notice Admin function to set the membership fee.
    /// @param _newFee New membership fee in ether.
    function setMembershipFee(uint256 _newFee) external onlyAdmin notPaused {
        membershipFee = _newFee;
        emit MembershipFeeSet(_newFee);
    }

    /// @notice Allows users to join the art collective by paying a membership fee.
    function joinCollective() external payable notPaused {
        require(msg.value >= membershipFee, "Insufficient membership fee paid.");
        require(!isMember[msg.sender], "Already a member.");

        isMember[msg.sender] = true;
        members.push(msg.sender);
        emit MembershipJoined(msg.sender);
    }

    /// @notice Allows members to leave the collective.
    function leaveCollective() external onlyMember notPaused {
        require(isMember[msg.sender], "Not a member.");

        isMember[msg.sender] = false;
        // Remove from members array (more efficient removal in production if order doesn't matter)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == msg.sender) {
                delete members[i];
                // Shift elements to fill the gap (inefficient for large arrays, consider other data structures in production)
                for (uint256 j = i; j < members.length - 1; j++) {
                    members[j] = members[j + 1];
                }
                members.pop(); // Remove last element (duplicate or zero address if shifted)
                break;
            }
        }
        emit MembershipLeft(msg.sender);
    }

    // --- Emergency & Admin Functions ---

    /// @notice Admin function to pause the contract in case of emergency.
    function pauseContract() external onlyAdmin {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Admin function to unpause the contract.
    function unpauseContract() external onlyAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Admin function to set the platform fee percentage for NFT sales.
    /// @param _newFee New platform fee percentage (e.g., 5 for 5%).
    function setPlatformFee(uint256 _newFee) external onlyAdmin {
        platformFeePercentage = _newFee;
        emit PlatformFeeSet(_newFee);
    }

    /// @notice Admin function to withdraw accumulated platform fees.
    /// @dev In a real NFT marketplace, platform fees would be collected during NFT sales.
    /// This is a placeholder for demonstrating admin fee withdrawal.
    function withdrawPlatformFees() external onlyAdmin {
        // Placeholder - In a real NFT marketplace, track platform fees collected during sales.
        // For demonstration, assuming some fees have accumulated in the contract balance.
        uint256 platformFees = address(this).balance; // Example: Withdraw entire contract balance as fees
        payable(admin).transfer(platformFees);
        emit PlatformFeesWithdrawn(admin, platformFees);
    }

    // --- Fallback & Receive Functions (Optional) ---
    receive() external payable {} // To receive ether deposits
    fallback() external {}
}
```