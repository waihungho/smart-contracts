```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Art Collective (DAAC) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized art collective where members can submit art, vote on submissions,
 *      mint collective NFTs, manage a treasury, and participate in decentralized governance.
 *
 * Function Summary:
 *
 * **Membership & Governance:**
 * 1. applyForMembership(string memory artistStatement): Allows artists to apply for membership.
 * 2. voteOnMembershipApplication(uint256 applicationId, bool vote): Members can vote on membership applications.
 * 3. processMembershipApplication(uint256 applicationId): Processes membership applications after voting period.
 * 4. revokeMembership(address member): Allows admin to revoke membership (with governance in future iterations).
 * 5. proposeNewRule(string memory description, bytes memory executionData): Members can propose new rules for the collective.
 * 6. voteOnRuleProposal(uint256 ruleId, bool vote): Members can vote on proposed rules.
 * 7. executeRule(uint256 ruleId): Executes a rule proposal if it passes the voting.
 * 8. setVotingPeriod(uint256 _votingPeriodSeconds): Admin function to set the voting period for proposals.
 * 9. setMembershipFee(uint256 _membershipFee): Admin function to set the membership fee.
 * 10. withdrawMembershipFee(): Members can withdraw their membership fee if rejected.
 *
 * **Art Submission & NFT Minting:**
 * 11. submitArtwork(string memory title, string memory description, string memory ipfsHash): Members submit artwork proposals.
 * 12. voteOnArtworkSubmission(uint256 artworkId, bool vote): Members vote on submitted artwork.
 * 13. processArtworkSubmission(uint256 artworkId): Processes artwork submissions after voting.
 * 14. mintCollectiveNFT(uint256 artworkId): Mints a collective NFT for approved artwork.
 * 15. setArtworkPrice(uint256 artworkId, uint256 price): Artist sets the price for their approved artwork.
 *
 * **Treasury & Revenue Sharing:**
 * 16. purchaseArtwork(uint256 artworkId): Allows purchasing of collective NFTs, funds go to treasury and artist.
 * 17. withdrawArtistShare(uint256 artworkId): Artist can withdraw their share of NFT sale proceeds.
 * 18. withdrawTreasuryFunds(address recipient, uint256 amount): Admin function to withdraw funds from the treasury.
 * 19. depositFunds(): Allows anyone to deposit funds into the treasury (e.g., donations).
 *
 * **Utility & Information:**
 * 20. getMembershipApplication(uint256 applicationId): Retrieve details of a membership application.
 * 21. getArtworkSubmission(uint256 artworkId): Retrieve details of an artwork submission.
 * 22. getRuleProposal(uint256 ruleId): Retrieve details of a rule proposal.
 * 23. getMemberCount(): Returns the current number of members.
 * 24. getPendingApplicationsCount(): Returns the number of pending membership applications.
 * 25. getPendingArtworksCount(): Returns the number of pending artwork submissions.
 * 26. getPendingRulesCount(): Returns the number of pending rule proposals.
 * 27. getTreasuryBalance(): Returns the current treasury balance.
 */
contract DecentralizedArtCollective {

    // -------- State Variables --------

    address public admin; // Contract administrator
    uint256 public membershipFee = 0.1 ether; // Fee to apply for membership
    uint256 public votingPeriodSeconds = 7 days; // Default voting period for proposals
    uint256 public quorumPercentage = 50; // Percentage of members needed to vote for quorum

    uint256 public nextApplicationId = 1;
    uint256 public nextArtworkId = 1;
    uint256 public nextRuleId = 1;

    mapping(uint256 => MembershipApplication) public membershipApplications;
    mapping(uint256 => ArtworkSubmission) public artworkSubmissions;
    mapping(uint256 => RuleProposal) public ruleProposals;
    mapping(address => bool) public isMember;
    address[] public members;

    uint256 public treasuryBalance; // Contract treasury balance

    // -------- Enums --------

    enum ApplicationStatus { Pending, Approved, Rejected }
    enum ArtworkStatus { Pending, Approved, Rejected, Minted }
    enum RuleStatus { Pending, Passed, Rejected, Executed }

    // -------- Structs --------

    struct MembershipApplication {
        uint256 applicationId;
        address applicant;
        string artistStatement;
        ApplicationStatus status;
        uint256 applicationTimestamp;
        mapping(address => bool) votes; // Members who have voted
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    struct ArtworkSubmission {
        uint256 artworkId;
        address artist;
        string title;
        string description;
        string ipfsHash;
        ArtworkStatus status;
        uint256 submissionTimestamp;
        mapping(address => bool) votes; // Members who have voted
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
        uint256 price; // Price of the artwork NFT
        bool artistShareWithdrawn;
    }

    struct RuleProposal {
        uint256 ruleId;
        address proposer;
        string description;
        bytes executionData; // Data to execute if rule passes (e.g., function call, parameters)
        RuleStatus status;
        uint256 proposalTimestamp;
        mapping(address => bool) votes; // Members who have voted
        uint256 yesVotes;
        uint256 noVotes;
        uint256 votingEndTime;
    }

    // -------- Events --------

    event MembershipApplied(uint256 applicationId, address applicant);
    event MembershipVoteCast(uint256 applicationId, address voter, bool vote);
    event MembershipApproved(uint256 applicationId, address member);
    event MembershipRejected(uint256 applicationId, address applicant);
    event MembershipRevoked(address member, address revokedBy);

    event ArtworkSubmitted(uint256 artworkId, address artist, string title);
    event ArtworkVoteCast(uint256 artworkId, address voter, bool vote);
    event ArtworkApproved(uint256 artworkId, string title);
    event ArtworkRejected(uint256 artworkId, string title);
    event ArtworkMinted(uint256 artworkId, address minter, string title);
    event ArtworkPurchased(uint256 artworkId, address buyer, uint256 price);
    event ArtistShareWithdrawn(uint256 artworkId, address artist, uint256 amount);

    event RuleProposed(uint256 ruleId, address proposer, string description);
    event RuleVoteCast(uint256 ruleId, address voter, bool vote);
    event RulePassed(uint256 ruleId, string description);
    event RuleRejected(uint256 ruleId, string description);
    event RuleExecuted(uint256 ruleId, string description);

    event TreasuryFundsDeposited(address depositor, uint256 amount);
    event TreasuryFundsWithdrawn(address recipient, uint256 amount, address withdrawnBy);

    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function.");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only members can call this function.");
        _;
    }

    modifier validApplicationId(uint256 applicationId) {
        require(membershipApplications[applicationId].applicationId == applicationId, "Invalid application ID.");
        _;
    }

    modifier validArtworkId(uint256 artworkId) {
        require(artworkSubmissions[artworkId].artworkId == artworkId, "Invalid artwork ID.");
        _;
    }

    modifier validRuleId(uint256 ruleId) {
        require(ruleProposals[ruleId].ruleId == ruleId, "Invalid rule ID.");
        _;
    }

    modifier applicationVotingInProgress(uint256 applicationId) {
        require(membershipApplications[applicationId].status == ApplicationStatus.Pending, "Application voting not in progress.");
        require(block.timestamp < membershipApplications[applicationId].votingEndTime, "Voting period ended.");
        _;
    }

    modifier artworkVotingInProgress(uint256 artworkId) {
        require(artworkSubmissions[artworkId].status == ArtworkStatus.Pending, "Artwork voting not in progress.");
        require(block.timestamp < artworkSubmissions[artworkId].votingEndTime, "Voting period ended.");
        _;
    }

    modifier ruleVotingInProgress(uint256 ruleId) {
        require(ruleProposals[ruleId].status == RuleStatus.Pending, "Rule voting not in progress.");
        require(block.timestamp < ruleProposals[ruleId].votingEndTime, "Voting period ended.");
        _;
    }

    modifier applicationVotingEnded(uint256 applicationId) {
        require(membershipApplications[applicationId].status == ApplicationStatus.Pending, "Application voting not in progress.");
        require(block.timestamp >= membershipApplications[applicationId].votingEndTime, "Voting period not yet ended.");
        _;
    }

    modifier artworkVotingEnded(uint256 artworkId) {
        require(artworkSubmissions[artworkId].status == ArtworkStatus.Pending, "Artwork voting not in progress.");
        require(block.timestamp >= artworkSubmissions[artworkId].votingEndTime, "Voting period not yet ended.");
        _;
    }

    modifier ruleVotingEnded(uint256 ruleId) {
        require(ruleProposals[ruleId].status == RuleStatus.Pending, "Rule voting not in progress.");
        require(block.timestamp >= ruleProposals[ruleId].votingEndTime, "Voting period not yet ended.");
        _;
    }

    modifier artworkApproved(uint256 artworkId) {
        require(artworkSubmissions[artworkId].status == ArtworkStatus.Approved, "Artwork is not approved.");
        _;
    }

    modifier artworkMinted(uint256 artworkId) {
        require(artworkSubmissions[artworkId].status == ArtworkStatus.Minted, "Artwork is already minted.");
        _;
    }

    modifier artworkNotMinted(uint256 artworkId) {
        require(artworkSubmissions[artworkId].status != ArtworkStatus.Minted, "Artwork is already minted.");
        _;
    }

    modifier rulePassed(uint256 ruleId) {
        require(ruleProposals[ruleId].status == RuleStatus.Passed, "Rule is not passed.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
    }

    // -------- Membership & Governance Functions --------

    /// @notice Allows artists to apply for membership by paying a fee and submitting an artist statement.
    /// @param artistStatement A brief statement about the artist and their work.
    function applyForMembership(string memory artistStatement) external payable {
        require(msg.value >= membershipFee, "Membership fee is required.");
        require(!isMember[msg.sender], "You are already a member.");

        membershipApplications[nextApplicationId] = MembershipApplication({
            applicationId: nextApplicationId,
            applicant: msg.sender,
            artistStatement: artistStatement,
            status: ApplicationStatus.Pending,
            applicationTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingPeriodSeconds,
            yesVotes: 0,
            noVotes: 0
        });

        emit MembershipApplied(nextApplicationId, msg.sender);
        nextApplicationId++;
    }

    /// @notice Allows members to vote on a pending membership application.
    /// @param applicationId The ID of the membership application to vote on.
    /// @param vote 'true' for approve, 'false' for reject.
    function voteOnMembershipApplication(uint256 applicationId, bool vote) external onlyMember validApplicationId(applicationId) applicationVotingInProgress(applicationId) {
        require(!membershipApplications[applicationId].votes[msg.sender], "You have already voted on this application.");

        membershipApplications[applicationId].votes[msg.sender] = true;
        if (vote) {
            membershipApplications[applicationId].yesVotes++;
        } else {
            membershipApplications[applicationId].noVotes++;
        }

        emit MembershipVoteCast(applicationId, msg.sender, vote);
    }

    /// @notice Processes a membership application after the voting period, approving or rejecting based on votes.
    /// @param applicationId The ID of the membership application to process.
    function processMembershipApplication(uint256 applicationId) external validApplicationId(applicationId) applicationVotingEnded(applicationId) {
        require(membershipApplications[applicationId].status == ApplicationStatus.Pending, "Application already processed.");

        uint256 totalMembers = members.length;
        uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

        if (membershipApplications[applicationId].yesVotes >= requiredVotes && membershipApplications[applicationId].yesVotes > membershipApplications[applicationId].noVotes) {
            membershipApplications[applicationId].status = ApplicationStatus.Approved;
            isMember[membershipApplications[applicationId].applicant] = true;
            members.push(membershipApplications[applicationId].applicant);
            emit MembershipApproved(applicationId, membershipApplications[applicationId].applicant);
        } else {
            membershipApplications[applicationId].status = ApplicationStatus.Rejected;
            payable(membershipApplications[applicationId].applicant).transfer(membershipFee); // Refund membership fee
            emit MembershipRejected(applicationId, membershipApplications[applicationId].applicant);
        }
    }

    /// @notice Allows admin to revoke membership of a member. (Governance can be implemented in future versions)
    /// @param member The address of the member to revoke.
    function revokeMembership(address member) external onlyAdmin {
        require(isMember[member], "Address is not a member.");
        isMember[member] = false;

        // Remove member from members array (inefficient but works for example, optimize in production)
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }
        emit MembershipRevoked(member, msg.sender);
    }

    /// @notice Allows members to propose a new rule for the collective.
    /// @param description A description of the rule proposal.
    /// @param executionData Data to be executed if the rule passes.
    function proposeNewRule(string memory description, bytes memory executionData) external onlyMember {
        ruleProposals[nextRuleId] = RuleProposal({
            ruleId: nextRuleId,
            proposer: msg.sender,
            description: description,
            executionData: executionData,
            status: RuleStatus.Pending,
            proposalTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingPeriodSeconds,
            yesVotes: 0,
            noVotes: 0
        });
        emit RuleProposed(nextRuleId, msg.sender, description);
        nextRuleId++;
    }

    /// @notice Allows members to vote on a pending rule proposal.
    /// @param ruleId The ID of the rule proposal to vote on.
    /// @param vote 'true' for approve, 'false' for reject.
    function voteOnRuleProposal(uint256 ruleId, bool vote) external onlyMember validRuleId(ruleId) ruleVotingInProgress(ruleId) {
        require(!ruleProposals[ruleId].votes[msg.sender], "You have already voted on this rule proposal.");

        ruleProposals[ruleId].votes[msg.sender] = true;
        if (vote) {
            ruleProposals[ruleId].yesVotes++;
        } else {
            ruleProposals[ruleId].noVotes++;
        }

        emit RuleVoteCast(ruleId, msg.sender, vote);
    }

    /// @notice Executes a rule proposal if it has passed the voting period and quorum.
    /// @param ruleId The ID of the rule proposal to execute.
    function executeRule(uint256 ruleId) external validRuleId(ruleId) ruleVotingEnded(ruleId) {
        require(ruleProposals[ruleId].status == RuleStatus.Pending, "Rule already processed.");

        uint256 totalMembers = members.length;
        uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

        if (ruleProposals[ruleId].yesVotes >= requiredVotes && ruleProposals[ruleId].yesVotes > ruleProposals[ruleId].noVotes) {
            ruleProposals[ruleId].status = RuleStatus.Passed;
            emit RulePassed(ruleId, ruleProposals[ruleId].description);

            // Execute the rule's logic - Example: simple function call (more complex logic possible)
            (bool success, ) = address(this).call(ruleProposals[ruleId].executionData);
            require(success, "Rule execution failed.");

            ruleProposals[ruleId].status = RuleStatus.Executed;
            emit RuleExecuted(ruleId, ruleProposals[ruleId].description);
        } else {
            ruleProposals[ruleId].status = RuleStatus.Rejected;
            emit RuleRejected(ruleId, ruleProposals[ruleId].description);
        }
    }

    /// @notice Admin function to set the voting period for proposals (in seconds).
    /// @param _votingPeriodSeconds The new voting period in seconds.
    function setVotingPeriod(uint256 _votingPeriodSeconds) external onlyAdmin {
        votingPeriodSeconds = _votingPeriodSeconds;
    }

    /// @notice Admin function to set the membership application fee.
    /// @param _membershipFee The new membership fee in wei.
    function setMembershipFee(uint256 _membershipFee) external onlyAdmin {
        membershipFee = _membershipFee;
    }

    /// @notice Allows rejected applicants to withdraw their membership fee.
    function withdrawMembershipFee() external {
        uint256 applicationIdToWithdraw = 0;
        for (uint256 i = 1; i < nextApplicationId; i++) {
            if (membershipApplications[i].applicant == msg.sender && membershipApplications[i].status == ApplicationStatus.Rejected) {
                applicationIdToWithdraw = i;
                break;
            }
        }
        require(applicationIdToWithdraw > 0, "No rejected application found to withdraw fee.");
        require(membershipApplications[applicationIdToWithdraw].status == ApplicationStatus.Rejected, "Application is not rejected.");
        membershipApplications[applicationIdToWithdraw].status = ApplicationStatus.Approved; // Prevent double withdrawal
        payable(msg.sender).transfer(membershipFee);
    }


    // -------- Art Submission & NFT Minting Functions --------

    /// @notice Allows members to submit an artwork proposal.
    /// @param title Title of the artwork.
    /// @param description Description of the artwork.
    /// @param ipfsHash IPFS hash of the artwork's metadata.
    function submitArtwork(string memory title, string memory description, string memory ipfsHash) external onlyMember {
        artworkSubmissions[nextArtworkId] = ArtworkSubmission({
            artworkId: nextArtworkId,
            artist: msg.sender,
            title: title,
            description: description,
            ipfsHash: ipfsHash,
            status: ArtworkStatus.Pending,
            submissionTimestamp: block.timestamp,
            votingEndTime: block.timestamp + votingPeriodSeconds,
            yesVotes: 0,
            noVotes: 0,
            price: 0, // Price set later if approved
            artistShareWithdrawn: false
        });
        emit ArtworkSubmitted(nextArtworkId, msg.sender, title);
        nextArtworkId++;
    }

    /// @notice Allows members to vote on a pending artwork submission.
    /// @param artworkId The ID of the artwork submission to vote on.
    /// @param vote 'true' for approve, 'false' for reject.
    function voteOnArtworkSubmission(uint256 artworkId, bool vote) external onlyMember validArtworkId(artworkId) artworkVotingInProgress(artworkId) {
        require(!artworkSubmissions[artworkId].votes[msg.sender], "You have already voted on this artwork.");

        artworkSubmissions[artworkId].votes[msg.sender] = true;
        if (vote) {
            artworkSubmissions[artworkId].yesVotes++;
        } else {
            artworkSubmissions[artworkId].noVotes++;
        }

        emit ArtworkVoteCast(artworkId, msg.sender, vote);
    }

    /// @notice Processes an artwork submission after the voting period, approving or rejecting based on votes.
    /// @param artworkId The ID of the artwork submission to process.
    function processArtworkSubmission(uint256 artworkId) external validArtworkId(artworkId) artworkVotingEnded(artworkId) {
        require(artworkSubmissions[artworkId].status == ArtworkStatus.Pending, "Artwork already processed.");

        uint256 totalMembers = members.length;
        uint256 requiredVotes = (totalMembers * quorumPercentage) / 100;

        if (artworkSubmissions[artworkId].yesVotes >= requiredVotes && artworkSubmissions[artworkId].yesVotes > artworkSubmissions[artworkId].noVotes) {
            artworkSubmissions[artworkId].status = ArtworkStatus.Approved;
            emit ArtworkApproved(artworkId, artworkSubmissions[artworkId].title);
        } else {
            artworkSubmissions[artworkId].status = ArtworkStatus.Rejected;
            emit ArtworkRejected(artworkId, artworkSubmissions[artworkId].title);
        }
    }

    /// @notice Mints a collective NFT for an approved artwork. Only admin can mint (can be changed to governance later).
    /// @param artworkId The ID of the approved artwork to mint.
    function mintCollectiveNFT(uint256 artworkId) external onlyAdmin validArtworkId(artworkId) artworkApproved(artworkId) artworkNotMinted(artworkId) {
        artworkSubmissions[artworkId].status = ArtworkStatus.Minted;
        // In a real implementation, this function would integrate with an NFT contract
        // and mint an NFT representing the artwork. For simplicity, we just mark it as minted here.
        emit ArtworkMinted(artworkId, msg.sender, artworkSubmissions[artworkId].title);
    }

    /// @notice Allows the artist to set the price for their approved and minted artwork.
    /// @param artworkId The ID of the artwork.
    /// @param price The price in wei.
    function setArtworkPrice(uint256 artworkId, uint256 price) external onlyMember validArtworkId(artworkId) artworkApproved(artworkId) artworkMinted(artworkId) {
        require(artworkSubmissions[artworkId].artist == msg.sender, "Only the artist can set the price.");
        artworkSubmissions[artworkId].price = price;
    }


    // -------- Treasury & Revenue Sharing Functions --------

    /// @notice Allows anyone to purchase a collective NFT, sending funds to the treasury and artist.
    /// @param artworkId The ID of the artwork to purchase.
    function purchaseArtwork(uint256 artworkId) external payable validArtworkId(artworkId) artworkApproved(artworkId) artworkMinted(artworkId) {
        require(artworkSubmissions[artworkId].price > 0, "Artwork price not set yet.");
        require(msg.value >= artworkSubmissions[artworkId].price, "Insufficient funds sent.");

        uint256 artistShare = (artworkSubmissions[artworkId].price * 80) / 100; // Example: 80% to artist, 20% to treasury
        uint256 treasuryShare = artworkSubmissions[artworkId].price - artistShare;

        treasuryBalance += treasuryShare;
        payable(artworkSubmissions[artworkId].artist).transfer(artistShare); // Send artist share directly

        emit ArtworkPurchased(artworkId, msg.sender, artworkSubmissions[artworkId].price);
    }

    /// @notice Allows the artist to withdraw their share of the proceeds from an NFT sale.
    /// @param artworkId The ID of the artwork.
    function withdrawArtistShare(uint256 artworkId) external onlyMember validArtworkId(artworkId) artworkApproved(artworkId) artworkMinted(artworkId) {
        require(artworkSubmissions[artworkId].artist == msg.sender, "Only the artist can withdraw their share.");
        require(!artworkSubmissions[artworkId].artistShareWithdrawn, "Artist share already withdrawn.");
        require(artworkSubmissions[artworkId].price > 0, "Artwork has not been sold yet."); // Basic check, could be more robust

        uint256 artistShare = (artworkSubmissions[artworkId].price * 80) / 100; // Recalculate share for security

        artworkSubmissions[artworkId].artistShareWithdrawn = true; // Mark as withdrawn
        // payable(artworkSubmissions[artworkId].artist).transfer(artistShare); // Already sent during purchase, no need to transfer again in this simplified example.

        emit ArtistShareWithdrawn(artworkId, msg.sender, artistShare);
    }

    /// @notice Admin function to withdraw funds from the treasury.
    /// @param recipient The address to send funds to.
    /// @param amount The amount to withdraw in wei.
    function withdrawTreasuryFunds(address recipient, uint256 amount) external onlyAdmin {
        require(treasuryBalance >= amount, "Insufficient treasury balance.");
        treasuryBalance -= amount;
        payable(recipient).transfer(amount);
        emit TreasuryFundsWithdrawn(recipient, amount, msg.sender);
    }

    /// @notice Allows anyone to deposit funds into the treasury (e.g., donations).
    function depositFunds() external payable {
        treasuryBalance += msg.value;
        emit TreasuryFundsDeposited(msg.sender, msg.value);
    }


    // -------- Utility & Information Functions --------

    /// @notice Retrieves details of a membership application.
    /// @param applicationId The ID of the membership application.
    /// @return MembershipApplication struct.
    function getMembershipApplication(uint256 applicationId) external view validApplicationId(applicationId) returns (MembershipApplication memory) {
        return membershipApplications[applicationId];
    }

    /// @notice Retrieves details of an artwork submission.
    /// @param artworkId The ID of the artwork submission.
    /// @return ArtworkSubmission struct.
    function getArtworkSubmission(uint256 artworkId) external view validArtworkId(artworkId) returns (ArtworkSubmission memory) {
        return artworkSubmissions[artworkId];
    }

    /// @notice Retrieves details of a rule proposal.
    /// @param ruleId The ID of the rule proposal.
    /// @return RuleProposal struct.
    function getRuleProposal(uint256 ruleId) external view validRuleId(ruleId) returns (RuleProposal memory) {
        return ruleProposals[ruleId];
    }

    /// @notice Returns the current number of members in the collective.
    /// @return The number of members.
    function getMemberCount() external view returns (uint256) {
        return members.length;
    }

    /// @notice Returns the number of pending membership applications.
    /// @return The number of pending applications.
    function getPendingApplicationsCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextApplicationId; i++) {
            if (membershipApplications[i].status == ApplicationStatus.Pending) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns the number of pending artwork submissions.
    /// @return The number of pending artwork submissions.
    function getPendingArtworksCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextArtworkId; i++) {
            if (artworkSubmissions[i].status == ArtworkStatus.Pending) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns the number of pending rule proposals.
    /// @return The number of pending rule proposals.
    function getPendingRulesCount() external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 1; i < nextRuleId; i++) {
            if (ruleProposals[i].status == RuleStatus.Pending) {
                count++;
            }
        }
        return count;
    }

    /// @notice Returns the current treasury balance of the contract.
    /// @return The treasury balance in wei.
    function getTreasuryBalance() external view returns (uint256) {
        return treasuryBalance;
    }
}
```