```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author [Your Name/Organization Name]
 * @dev A smart contract implementing a Decentralized Autonomous Research Organization (DARO)
 * with advanced features for managing research proposals, funding, peer review, and intellectual property,
 * leveraging blockchain for transparency and efficiency in scientific research.
 *
 * Function Summary:
 *
 * 1.  submitResearchProposal(string memory _title, string memory _description, uint256 _fundingGoal, string memory _keywords, string memory _ipfsDataHash): Allows researchers to submit research proposals with detailed information and IPFS data hash.
 * 2.  viewResearchProposal(uint256 _proposalId): Allows anyone to view the details of a research proposal by its ID.
 * 3.  donateToProposal(uint256 _proposalId): Allows anyone to donate ETH to a specific research proposal.
 * 4.  voteOnProposal(uint256 _proposalId, bool _support): Allows registered DARO members to vote on research proposals.
 * 5.  finalizeProposalFunding(uint256 _proposalId): Allows the contract owner to finalize funding for a proposal if it reaches its goal and is approved.
 * 6.  assignReviewer(uint256 _proposalId, address _reviewer): Allows the contract owner to assign a reviewer to a research proposal.
 * 7.  submitReview(uint256 _proposalId, string memory _reviewText, uint8 _rating): Allows assigned reviewers to submit their review for a proposal with text and a rating.
 * 8.  viewProposalReviews(uint256 _proposalId): Allows anyone to view the reviews submitted for a specific proposal.
 * 9.  registerResearcher(string memory _name, string memory _affiliation, string memory _expertise): Allows individuals to register as researchers within the DARO.
 * 10. getResearcherProfile(address _researcherAddress): Allows anyone to view the profile of a registered researcher.
 * 11. registerReviewer(string memory _name, string memory _expertise): Allows experts to register as reviewers within the DARO.
 * 12. getReviewerProfile(address _reviewerAddress): Allows anyone to view the profile of a registered reviewer.
 * 13. updateResearchProposalData(uint256 _proposalId, string memory _ipfsDataHash): Allows the proposer to update the IPFS data hash of their research proposal (e.g., for updates or results).
 * 14. withdrawProposalFunds(uint256 _proposalId): Allows the proposer of a funded and finalized proposal to withdraw the collected funds.
 * 15. recordIntellectualProperty(uint256 _proposalId, string memory _ipAssetName, string memory _ipDescription, string memory _ipfsIPHash): Allows researchers to record intellectual property associated with their research, linking it to IPFS.
 * 16. viewIntellectualProperty(uint256 _proposalId, uint256 _ipId): Allows anyone to view the details of recorded intellectual property for a proposal.
 * 17. transferIntellectualPropertyOwnership(uint256 _proposalId, uint256 _ipId, address _newOwner): Allows the current IP owner to transfer ownership of recorded intellectual property.
 * 18. proposeGovernanceChange(string memory _description, string memory _ipfsProposalHash): Allows DARO members to propose changes to the DARO governance parameters (e.g., voting thresholds, review criteria).
 * 19. voteOnGovernanceChange(uint256 _governanceProposalId, bool _support): Allows DARO members to vote on proposed governance changes.
 * 20. executeGovernanceChange(uint256 _governanceProposalId): Allows the contract owner to execute approved governance changes after voting.
 * 21. getContractBalance(): Allows anyone to view the current ETH balance of the smart contract.
 * 22. emergencyWithdraw(address payable _recipient): Allows the contract owner to withdraw all ETH from the contract in case of an emergency. (Owner-controlled safety function)
 */

contract DARO {
    address public owner;

    // Structs
    struct ResearchProposal {
        uint256 proposalId;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string keywords;
        string ipfsDataHash;
        ProposalStatus status;
        address[] reviewers;
        mapping(address => Review) reviews;
        uint256 reviewCount;
        uint256 upvotes;
        uint256 downvotes;
        uint256 ipCount; // Counter for intellectual properties
    }

    struct Review {
        address reviewer;
        string reviewText;
        uint8 rating; // Scale of 1-5, for example
        uint256 timestamp;
    }

    struct ResearcherProfile {
        address researcherAddress;
        string name;
        string affiliation;
        string expertise;
        uint256 registrationTimestamp;
    }

    struct ReviewerProfile {
        address reviewerAddress;
        string name;
        string expertise;
        uint256 registrationTimestamp;
    }

    struct IntellectualProperty {
        uint256 ipId;
        string ipAssetName;
        string ipDescription;
        string ipfsIPHash;
        address owner;
        uint256 recordTimestamp;
    }

    struct GovernanceProposal {
        uint256 proposalId;
        string description;
        string ipfsProposalHash;
        uint256 upvotes;
        uint256 downvotes;
        bool executed;
        uint256 proposalTimestamp;
    }

    // Enums
    enum ProposalStatus {
        Pending,
        Funded,
        InProgress,
        Completed,
        Rejected
    }

    // Mappings
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(address => ResearcherProfile) public researcherProfiles;
    mapping(address => ReviewerProfile) public reviewerProfiles;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => mapping(uint256 => IntellectualProperty)) public proposalIPs; // Nested mapping: proposalId -> ipId -> IP details
    mapping(uint256 => mapping(address => bool)) public proposalVotes; // proposalId -> voter -> vote (true=upvote, false=downvote)


    // Counters
    uint256 public proposalCounter;
    uint256 public governanceProposalCounter;

    // Events
    event ProposalSubmitted(uint256 proposalId, address proposer, string title);
    event DonationReceived(uint256 proposalId, address donor, uint256 amount);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalFunded(uint256 proposalId);
    event ReviewSubmitted(uint256 proposalId, address reviewer);
    event ResearcherRegistered(address researcherAddress, string name);
    event ReviewerRegistered(address reviewerAddress, string name);
    event ProposalDataUpdated(uint256 proposalId);
    event FundsWithdrawn(uint256 proposalId, address recipient, uint256 amount);
    event IPRecorded(uint256 proposalId, uint256 ipId, string ipAssetName, address owner);
    event IPOwnershipTransferred(uint256 proposalId, uint256 ipId, address oldOwner, address newOwner);
    event GovernanceProposalCreated(uint256 proposalId, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool support);
    event GovernanceChangeExecuted(uint256 proposalId);
    event EmergencyWithdrawal(address recipient, uint256 amount);


    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyRegisteredResearcher() {
        require(researcherProfiles[msg.sender].researcherAddress == msg.sender, "Only registered researchers can call this function.");
        _;
    }

    modifier onlyRegisteredReviewer() {
        require(reviewerProfiles[msg.sender].reviewerAddress == msg.sender, "Only registered reviewers can call this function.");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(researchProposals[_proposalId].proposalId == _proposalId, "Proposal does not exist.");
        _;
    }

    modifier validProposalStatus(uint256 _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Proposal status is not valid for this action.");
        _;
    }

    modifier validReviewer(uint256 _proposalId, address _reviewer) {
        bool isAssignedReviewer = false;
        for (uint256 i = 0; i < researchProposals[_proposalId].reviewers.length; i++) {
            if (researchProposals[_proposalId].reviewers[i] == _reviewer) {
                isAssignedReviewer = true;
                break;
            }
        }
        require(isAssignedReviewer, "You are not assigned as a reviewer for this proposal.");
        _;
    }

    modifier validIP(uint256 _proposalId, uint256 _ipId) {
        require(proposalIPs[_proposalId][_ipId].ipId == _ipId, "Intellectual Property not found for this proposal and IP ID.");
        _;
    }

    // Constructor
    constructor() {
        owner = msg.sender;
        proposalCounter = 0;
        governanceProposalCounter = 0;
    }

    // 1. Submit Research Proposal
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _keywords,
        string memory _ipfsDataHash
    ) public onlyRegisteredResearcher {
        proposalCounter++;
        researchProposals[proposalCounter] = ResearchProposal({
            proposalId: proposalCounter,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            keywords: _keywords,
            ipfsDataHash: _ipfsDataHash,
            status: ProposalStatus.Pending,
            reviewers: new address[](0),
            reviewCount: 0,
            upvotes: 0,
            downvotes: 0,
            ipCount: 0
        });
        emit ProposalSubmitted(proposalCounter, msg.sender, _title);
    }

    // 2. View Research Proposal
    function viewResearchProposal(uint256 _proposalId) public view proposalExists(_proposalId) returns (ResearchProposal memory) {
        return researchProposals[_proposalId];
    }

    // 3. Donate to Proposal
    function donateToProposal(uint256 _proposalId) public payable proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        require(msg.value > 0, "Donation amount must be greater than zero.");
        researchProposals[_proposalId].currentFunding += msg.value;
        emit DonationReceived(_proposalId, msg.sender, msg.value);
    }

    // 4. Vote on Proposal
    function voteOnProposal(uint256 _proposalId, bool _support) public onlyRegisteredResearcher proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");
        proposalVotes[_proposalId][msg.sender] = true; // Record vote to prevent double voting
        if (_support) {
            researchProposals[_proposalId].upvotes++;
        } else {
            researchProposals[_proposalId].downvotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);
    }

    // 5. Finalize Proposal Funding
    function finalizeProposalFunding(uint256 _proposalId) public onlyOwner proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Pending) {
        require(researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal, "Proposal funding goal not reached.");
        // Example simple approval logic: more upvotes than downvotes (can be customized based on governance)
        require(researchProposals[_proposalId].upvotes > researchProposals[_proposalId].downvotes, "Proposal not approved by voting.");

        researchProposals[_proposalId].status = ProposalStatus.Funded;
        emit ProposalFunded(_proposalId);
    }

    // 6. Assign Reviewer
    function assignReviewer(uint256 _proposalId, address _reviewer) public onlyOwner proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Funded) {
        require(reviewerProfiles[_reviewer].reviewerAddress == _reviewer, "Address is not a registered reviewer.");
        researchProposals[_proposalId].reviewers.push(_reviewer);
    }

    // 7. Submit Review
    function submitReview(uint256 _proposalId, string memory _reviewText, uint8 _rating) public onlyRegisteredReviewer proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Funded) validReviewer(_proposalId, msg.sender) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5."); // Example rating scale validation
        require(researchProposals[_proposalId].reviews[msg.sender].reviewer == address(0), "You have already submitted a review for this proposal."); // Prevent double reviews

        researchProposals[_proposalId].reviews[msg.sender] = Review({
            reviewer: msg.sender,
            reviewText: _reviewText,
            rating: _rating,
            timestamp: block.timestamp
        });
        researchProposals[_proposalId].reviewCount++;
        emit ReviewSubmitted(_proposalId, msg.sender);
    }

    // 8. View Proposal Reviews
    function viewProposalReviews(uint256 _proposalId) public view proposalExists(_proposalId) returns (Review[] memory) {
        Review[] memory reviewsArray = new Review[](researchProposals[_proposalId].reviewers.length);
        for (uint256 i = 0; i < researchProposals[_proposalId].reviewers.length; i++) {
            reviewsArray[i] = researchProposals[_proposalId].reviews[researchProposals[_proposalId].reviewers[i]];
        }
        return reviewsArray;
    }

    // 9. Register Researcher
    function registerResearcher(string memory _name, string memory _affiliation, string memory _expertise) public {
        require(researcherProfiles[msg.sender].researcherAddress == address(0), "Researcher already registered."); // Prevent re-registration
        researcherProfiles[msg.sender] = ResearcherProfile({
            researcherAddress: msg.sender,
            name: _name,
            affiliation: _affiliation,
            expertise: _expertise,
            registrationTimestamp: block.timestamp
        });
        emit ResearcherRegistered(msg.sender, _name);
    }

    // 10. Get Researcher Profile
    function getResearcherProfile(address _researcherAddress) public view returns (ResearcherProfile memory) {
        return researcherProfiles[_researcherAddress];
    }

    // 11. Register Reviewer
    function registerReviewer(string memory _name, string memory _expertise) public {
        require(reviewerProfiles[msg.sender].reviewerAddress == address(0), "Reviewer already registered."); // Prevent re-registration
        reviewerProfiles[msg.sender] = ReviewerProfile({
            reviewerAddress: msg.sender,
            name: _name,
            expertise: _expertise,
            registrationTimestamp: block.timestamp
        });
        emit ReviewerRegistered(msg.sender, _name);
    }

    // 12. Get Reviewer Profile
    function getReviewerProfile(address _reviewerAddress) public view returns (ReviewerProfile memory) {
        return reviewerProfiles[_reviewerAddress];
    }

    // 13. Update Research Proposal Data
    function updateResearchProposalData(uint256 _proposalId, string memory _ipfsDataHash) public onlyRegisteredResearcher proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Funded) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Only proposer can update proposal data.");
        researchProposals[_proposalId].ipfsDataHash = _ipfsDataHash;
        emit ProposalDataUpdated(_proposalId);
    }

    // 14. Withdraw Proposal Funds
    function withdrawProposalFunds(uint256 _proposalId) public onlyRegisteredResearcher proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.Funded) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Only proposer can withdraw funds.");
        uint256 amountToWithdraw = researchProposals[_proposalId].currentFunding;
        researchProposals[_proposalId].currentFunding = 0; // Set current funding to 0 after withdrawal
        payable(msg.sender).transfer(amountToWithdraw);
        researchProposals[_proposalId].status = ProposalStatus.InProgress; // Move to InProgress after withdrawal
        emit FundsWithdrawn(_proposalId, msg.sender, amountToWithdraw);
    }

    // 15. Record Intellectual Property
    function recordIntellectualProperty(
        uint256 _proposalId,
        string memory _ipAssetName,
        string memory _ipDescription,
        string memory _ipfsIPHash
    ) public onlyRegisteredResearcher proposalExists(_proposalId) validProposalStatus(_proposalId, ProposalStatus.InProgress) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Only proposer can record IP.");
        researchProposals[_proposalId].ipCount++;
        uint256 currentIpId = researchProposals[_proposalId].ipCount;
        proposalIPs[_proposalId][currentIpId] = IntellectualProperty({
            ipId: currentIpId,
            ipAssetName: _ipAssetName,
            ipDescription: _ipDescription,
            ipfsIPHash: _ipfsIPHash,
            owner: msg.sender,
            recordTimestamp: block.timestamp
        });
        emit IPRecorded(_proposalId, currentIpId, _ipAssetName, msg.sender);
    }

    // 16. View Intellectual Property
    function viewIntellectualProperty(uint256 _proposalId, uint256 _ipId) public view proposalExists(_proposalId) validIP(_proposalId, _ipId) returns (IntellectualProperty memory) {
        return proposalIPs[_proposalId][_ipId];
    }

    // 17. Transfer Intellectual Property Ownership
    function transferIntellectualPropertyOwnership(uint256 _proposalId, uint256 _ipId, address _newOwner) public onlyRegisteredResearcher proposalExists(_proposalId) validIP(_proposalId, _ipId) validProposalStatus(_proposalId, ProposalStatus.InProgress) {
        require(proposalIPs[_proposalId][_ipId].owner == msg.sender, "Only IP owner can transfer ownership.");
        address oldOwner = proposalIPs[_proposalId][_ipId].owner;
        proposalIPs[_proposalId][_ipId].owner = _newOwner;
        emit IPOwnershipTransferred(_proposalId, _ipId, oldOwner, _newOwner);
    }

    // 18. Propose Governance Change
    function proposeGovernanceChange(string memory _description, string memory _ipfsProposalHash) public onlyRegisteredResearcher {
        governanceProposalCounter++;
        governanceProposals[governanceProposalCounter] = GovernanceProposal({
            proposalId: governanceProposalCounter,
            description: _description,
            ipfsProposalHash: _ipfsProposalHash,
            upvotes: 0,
            downvotes: 0,
            executed: false,
            proposalTimestamp: block.timestamp
        });
        emit GovernanceProposalCreated(governanceProposalCounter, _description);
    }

    // 19. Vote on Governance Change
    function voteOnGovernanceChange(uint256 _governanceProposalId, bool _support) public onlyRegisteredResearcher {
        require(governanceProposals[_governanceProposalId].proposalId == _governanceProposalId, "Governance Proposal does not exist.");
        require(!governanceProposals[_governanceProposalId].executed, "Governance proposal already executed.");
        // Simple voting logic: first vote counts, no double voting for simplicity in this example
        if (!proposalVotes[governanceProposalCounter][msg.sender]) { // Reusing proposalVotes mapping for simplicity, ideally separate mapping for governance votes
            proposalVotes[governanceProposalCounter][msg.sender] = true; // Mark voter as voted (can be improved for proper voting count per proposal)
            if (_support) {
                governanceProposals[_governanceProposalId].upvotes++;
            } else {
                governanceProposals[_governanceProposalId].downvotes++;
            }
            emit GovernanceProposalVoted(_governanceProposalId, msg.sender, _support);
        }
    }

    // 20. Execute Governance Change
    function executeGovernanceChange(uint256 _governanceProposalId) public onlyOwner {
        require(governanceProposals[_governanceProposalId].proposalId == _governanceProposalId, "Governance Proposal does not exist.");
        require(!governanceProposals[_governanceProposalId].executed, "Governance proposal already executed.");
        // Example execution condition: More upvotes than downvotes (can be customized)
        require(governanceProposals[_governanceProposalId].upvotes > governanceProposals[_governanceProposalId].downvotes, "Governance proposal not approved by voting.");

        governanceProposals[_governanceProposalId].executed = true;
        emit GovernanceChangeExecuted(_governanceProposalId);
        // In a real-world scenario, this function would contain logic to actually apply the governance changes.
        // For example, updating voting thresholds, review criteria, etc., based on the proposal.
        // For this example, we are just marking it as executed.
    }

    // 21. Get Contract Balance
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 22. Emergency Withdraw
    function emergencyWithdraw(address payable _recipient) public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "Contract balance is zero.");
        _recipient.transfer(contractBalance);
        emit EmergencyWithdrawal(_recipient, contractBalance);
    }

    // Fallback function to reject direct ETH transfers without calling donateToProposal
    receive() external payable {
        revert("Direct ETH transfers are not allowed. Please use the donateToProposal function.");
    }
}
```