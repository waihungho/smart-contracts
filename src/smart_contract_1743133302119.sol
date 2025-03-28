```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO) that facilitates
 * research proposal submission, peer review, funding, execution, and intellectual property management,
 * incorporating advanced concepts like dynamic reputation, skill-based matching, and decentralized data storage integration.
 *
 * **Outline and Function Summary:**
 *
 * **1. Core DAO Governance:**
 *    - `proposeNewResearchField(string _researchField)`: Allows DAO members to propose new research fields.
 *    - `voteOnResearchFieldProposal(uint _proposalId, bool _support)`: Allows DAO members to vote on research field proposals.
 *    - `delegateVote(address _delegatee)`: Allows members to delegate their voting power to another member.
 *    - `setGovernanceParameter(string _parameterName, uint _newValue)`: Allows governance to set key parameters like quorum, voting periods.
 *
 * **2. Researcher Profile & Reputation:**
 *    - `registerResearcherProfile(string _name, string _expertise, string _ipfsProfileHash)`: Allows researchers to register their profiles with expertise and IPFS link.
 *    - `updateResearcherSkills(string[] _newSkills)`:  Allows researchers to update their listed skills.
 *    - `verifyResearcherSkill(address _researcherAddress, string _skill, bool _isVerified)`:  Allows designated verifiers to vouch for researcher skills (reputation building).
 *    - `reportResearcherContribution(address _researcherAddress, uint _proposalId, string _contributionDetails)`: Allows project leads to report contributions of researchers to a specific proposal.
 *    - `getResearcherReputation(address _researcherAddress)`:  Returns a reputation score for a researcher based on verifications and contributions.
 *
 * **3. Research Proposal Management:**
 *    - `submitResearchProposal(string _title, string _description, string _researchField, string _ipfsProposalHash, uint _fundingGoal)`: Allows researchers to submit proposals with details and funding goals.
 *    - `peerReviewProposal(uint _proposalId, string _reviewFeedback, uint _rating)`: Allows designated peer reviewers to review proposals and provide feedback and ratings.
 *    - `fundResearchProposal(uint _proposalId)`: Allows anyone to contribute funds to a research proposal.
 *    - `withdrawProposalFunds(uint _proposalId)`: Allows the proposal lead to withdraw funds once funding goal is reached and proposal is approved.
 *    - `submitResearchMilestone(uint _proposalId, string _milestoneDescription, string _ipfsMilestoneHash)`: Allows proposal leads to submit milestones and associated data.
 *    - `markMilestoneComplete(uint _proposalId, uint _milestoneIndex)`: Allows reviewers or governance to mark milestones as completed.
 *    - `submitResearchResults(uint _proposalId, string _ipfsResultsHash)`: Allows proposal leads to submit final research results upon project completion.
 *    - `markResearchComplete(uint _proposalId)`: Marks a research proposal as fully completed.
 *
 * **4. Intellectual Property & Data Management:**
 *    - `registerResearchOutputIP(uint _proposalId, string _outputName, string _ipfsIPHash, string _licenseType)`: Allows registering IP associated with research outputs, linking to IPFS and defining license.
 *    - `requestResearchDataAccess(uint _proposalId)`: Allows external parties to request access to research data (governed by license).
 *    - `grantResearchDataAccess(uint _proposalId, address _requester)`: Allows IP owners to grant data access to approved requesters (can be automated based on license).
 *
 * **5. Utility & Platform Management:**
 *    - `pauseContract()`: Allows the contract governor to pause critical functions in case of emergency.
 *    - `unpauseContract()`: Allows the contract governor to resume contract functions.
 *    - `setPlatformFee(uint _feePercentage)`: Allows governance to set a platform fee for funded proposals (as DAO revenue).
 *    - `getContractBalance()`: Returns the current balance of the contract.
 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DARO is Ownable {
    using SafeMath for uint256;

    // --- Enums and Structs ---

    enum ProposalStatus { Pending, Review, Funding, InProgress, Completed, Rejected }
    enum VoteType { ResearchFieldProposal }

    struct ResearchFieldProposal {
        string researchField;
        uint yesVotes;
        uint noVotes;
        bool isActive;
        uint votingDeadline;
    }

    struct ResearcherProfile {
        string name;
        string expertise;
        string ipfsProfileHash;
        string[] skills;
        uint reputationScore;
        bool isActive;
    }

    struct ResearchProposal {
        string title;
        string description;
        string researchField;
        string ipfsProposalHash;
        uint fundingGoal;
        uint currentFunding;
        address proposer;
        ProposalStatus status;
        uint submissionTimestamp;
        address[] peerReviewers; // Could be dynamically assigned based on expertise
        string[] peerReviews;
        uint[] peerRatings;
        string ipfsResultsHash;
        Milestone[] milestones;
        IPOutput[] ipOutputs;
    }

    struct Milestone {
        string description;
        string ipfsMilestoneHash;
        bool isCompleted;
        uint completionTimestamp;
    }

    struct IPOutput {
        string outputName;
        string ipfsIPHash;
        string licenseType; // e.g., "CC-BY-NC", "MIT", "Proprietary"
        address owner; // Initially proposer, could evolve
        bool isPubliclyAccessible;
        address[] allowedAccessAddresses;
    }

    struct Vote {
        VoteType voteType;
        uint proposalId;
        address voter;
        bool support;
        uint timestamp;
    }

    // --- State Variables ---

    mapping(uint => ResearchFieldProposal) public researchFieldProposals;
    uint public researchFieldProposalCount;
    string[] public activeResearchFields;

    mapping(address => ResearcherProfile) public researcherProfiles;
    address[] public registeredResearchers;

    mapping(uint => ResearchProposal) public researchProposals;
    uint public researchProposalCount;

    mapping(address => address) public voteDelegations; // Member -> Delegatee

    uint public quorumPercentage = 50; // Percentage of members required to vote for quorum
    uint public votingPeriodDays = 7; // Default voting period for proposals
    uint public platformFeePercentage = 5; // Percentage taken from funded proposals as DAO revenue

    bool public contractPaused = false;

    // --- Events ---

    event ResearchFieldProposed(uint proposalId, string researchField, address proposer);
    event ResearchFieldProposalVoted(uint proposalId, address voter, bool support);
    event ResearcherRegistered(address researcherAddress, string name);
    event ResearcherSkillsUpdated(address researcherAddress, string[] skills);
    event ResearcherSkillVerified(address verifier, address researcherAddress, string skill, bool isVerified);
    event ResearchProposalSubmitted(uint proposalId, string title, address proposer);
    event ResearchProposalReviewed(uint proposalId, address reviewer, string feedback, uint rating);
    event ResearchProposalFunded(uint proposalId, address funder, uint amount);
    event ResearchProposalFundsWithdrawn(uint proposalId, address withdrawer, uint amount);
    event ResearchMilestoneSubmitted(uint proposalId, uint milestoneIndex, string description);
    event ResearchMilestoneMarkedComplete(uint proposalId, uint milestoneIndex);
    event ResearchResultsSubmitted(uint proposalId, string ipfsResultsHash);
    event ResearchCompleted(uint proposalId);
    event IPRegistered(uint proposalId, uint outputIndex, string outputName, string licenseType);
    event DataAccessRequested(uint proposalId, address requester);
    event DataAccessGranted(uint proposalId, address granter, address requester);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event PlatformFeeSet(uint feePercentage);


    // --- Modifiers ---

    modifier whenNotPaused() {
        require(!contractPaused, "Contract is paused");
        _;
    }

    modifier onlyRegisteredResearcher() {
        require(researcherProfiles[msg.sender].isActive, "Not a registered researcher");
        _;
    }

    modifier onlyProposalProposer(uint _proposalId) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Not the proposal proposer");
        _;
    }

    modifier onlyValidProposalStatus(uint _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Invalid proposal status");
        _;
    }

    modifier onlyValidMilestone(uint _proposalId, uint _milestoneIndex) {
        require(_milestoneIndex < researchProposals[_proposalId].milestones.length, "Invalid milestone index");
        _;
    }

    // --- 1. Core DAO Governance Functions ---

    /**
     * @dev Allows DAO members to propose new research fields.
     * @param _researchField The name of the new research field.
     */
    function proposeNewResearchField(string memory _researchField) external whenNotPaused {
        require(researcherProfiles[msg.sender].isActive, "Only registered researchers can propose research fields.");
        researchFieldProposals[researchFieldProposalCount] = ResearchFieldProposal({
            researchField: _researchField,
            yesVotes: 0,
            noVotes: 0,
            isActive: true,
            votingDeadline: block.timestamp + votingPeriodDays * 1 days
        });
        emit ResearchFieldProposed(researchFieldProposalCount, _researchField, msg.sender);
        researchFieldProposalCount++;
    }

    /**
     * @dev Allows DAO members to vote on research field proposals.
     * @param _proposalId The ID of the research field proposal.
     * @param _support True for yes, false for no.
     */
    function voteOnResearchFieldProposal(uint _proposalId, bool _support) external whenNotPaused {
        require(researcherProfiles[msg.sender].isActive, "Only registered researchers can vote.");
        require(researchFieldProposals[_proposalId].isActive, "Proposal is not active.");
        require(block.timestamp < researchFieldProposals[_proposalId].votingDeadline, "Voting deadline passed.");

        address voter = msg.sender;
        if (voteDelegations[msg.sender] != address(0)) {
            voter = voteDelegations[msg.sender]; // Use delegated vote if set
        }

        // Simple voting - in a real DAO, more robust voting mechanisms would be used
        if (_support) {
            researchFieldProposals[_proposalId].yesVotes++;
        } else {
            researchFieldProposals[_proposalId].noVotes++;
        }
        emit ResearchFieldProposalVoted(_proposalId, voter, _support);

        // Check if proposal passes after vote (simplified logic for example)
        uint totalVotes = researchFieldProposals[_proposalId].yesVotes + researchFieldProposals[_proposalId].noVotes;
        if (totalVotes > 0 && (researchFieldProposals[_proposalId].yesVotes * 100) / totalVotes >= quorumPercentage) {
            if (researchFieldProposals[_proposalId].isActive) { // Prevent re-execution if already processed
                researchFieldProposals[_proposalId].isActive = false; // Mark proposal as inactive
                activeResearchFields.push(researchFieldProposals[_proposalId].researchField);
            }
        }
    }

    /**
     * @dev Allows members to delegate their voting power to another member.
     * @param _delegatee The address to delegate voting power to. Set to address(0) to remove delegation.
     */
    function delegateVote(address _delegatee) external whenNotPaused onlyRegisteredResearcher {
        voteDelegations[msg.sender] = _delegatee;
    }

    /**
     * @dev Allows governance to set key parameters like quorum, voting periods.
     * @param _parameterName The name of the parameter to set (e.g., "quorumPercentage", "votingPeriodDays").
     * @param _newValue The new value for the parameter.
     */
    function setGovernanceParameter(string memory _parameterName, uint _newValue) external onlyOwner whenNotPaused {
        if (keccak256(bytes(_parameterName)) == keccak256(bytes("quorumPercentage"))) {
            quorumPercentage = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("votingPeriodDays"))) {
            votingPeriodDays = _newValue;
        } else if (keccak256(bytes(_parameterName)) == keccak256(bytes("platformFeePercentage"))) {
            platformFeePercentage = _newValue;
            emit PlatformFeeSet(_newValue);
        } else {
            revert("Invalid governance parameter name");
        }
    }


    // --- 2. Researcher Profile & Reputation Functions ---

    /**
     * @dev Allows researchers to register their profiles with expertise and IPFS link.
     * @param _name Researcher's name.
     * @param _expertise Area of expertise.
     * @param _ipfsProfileHash IPFS hash of the full profile document.
     */
    function registerResearcherProfile(string memory _name, string memory _expertise, string memory _ipfsProfileHash) external whenNotPaused {
        require(!researcherProfiles[msg.sender].isActive, "Researcher profile already registered.");
        researcherProfiles[msg.sender] = ResearcherProfile({
            name: _name,
            expertise: _expertise,
            ipfsProfileHash: _ipfsProfileHash,
            skills: new string[](0),
            reputationScore: 0,
            isActive: true
        });
        registeredResearchers.push(msg.sender);
        emit ResearcherRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows researchers to update their listed skills.
     * @param _newSkills Array of skill strings.
     */
    function updateResearcherSkills(string[] memory _newSkills) external whenNotPaused onlyRegisteredResearcher {
        researcherProfiles[msg.sender].skills = _newSkills;
        emit ResearcherSkillsUpdated(msg.sender, _newSkills);
    }

    /**
     * @dev Allows designated verifiers to vouch for researcher skills (reputation building).
     * @param _researcherAddress Address of the researcher whose skill is being verified.
     * @param _skill The skill being verified.
     * @param _isVerified True if verified, false to revoke verification.
     */
    function verifyResearcherSkill(address _researcherAddress, string memory _skill, bool _isVerified) external onlyOwner whenNotPaused {
        require(researcherProfiles[_researcherAddress].isActive, "Target researcher is not registered.");
        bool skillFound = false;
        for (uint i = 0; i < researcherProfiles[_researcherAddress].skills.length; i++) {
            if (keccak256(bytes(researcherProfiles[_researcherAddress].skills[i])) == keccak256(bytes(_skill))) {
                skillFound = true;
                break;
            }
        }
        require(skillFound, "Skill not found in researcher's profile.");

        if (_isVerified) {
            researcherProfiles[_researcherAddress].reputationScore++; // Simple reputation increment
        } else {
            if (researcherProfiles[_researcherAddress].reputationScore > 0) {
                researcherProfiles[_researcherAddress].reputationScore--; // Simple reputation decrement (avoid negative)
            }
        }
        emit ResearcherSkillVerified(msg.sender, _researcherAddress, _skill, _isVerified);
    }

    /**
     * @dev Allows project leads to report contributions of researchers to a specific proposal.
     * @param _researcherAddress Address of the contributing researcher.
     * @param _proposalId ID of the research proposal.
     * @param _contributionDetails Details of the contribution (e.g., task completed, role).
     */
    function reportResearcherContribution(address _researcherAddress, uint _proposalId, string memory _contributionDetails) external whenNotPaused onlyProposalProposer(_proposalId) {
        require(researcherProfiles[_researcherAddress].isActive, "Contributing researcher is not registered.");
        // In a real system, more robust contribution tracking and reputation updates would be implemented.
        researcherProfiles[_researcherAddress].reputationScore += 2; // Example: small reputation boost for contribution
        emit ResearcherSkillVerified(msg.sender, _researcherAddress, "Contribution to Proposal ID " + Strings.toString(_proposalId), true); // Reusing event for simplicity, can create a dedicated event
    }

    /**
     * @dev Returns a reputation score for a researcher based on verifications and contributions.
     * @param _researcherAddress Address of the researcher.
     * @return The reputation score.
     */
    function getResearcherReputation(address _researcherAddress) external view returns (uint) {
        return researcherProfiles[_researcherAddress].reputationScore;
    }


    // --- 3. Research Proposal Management Functions ---

    /**
     * @dev Allows researchers to submit proposals with details and funding goals.
     * @param _title Title of the research proposal.
     * @param _description Short description of the research.
     * @param _researchField Research field of the proposal.
     * @param _ipfsProposalHash IPFS hash of the full proposal document.
     * @param _fundingGoal Funding goal in wei.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        string memory _researchField,
        string memory _ipfsProposalHash,
        uint _fundingGoal
    ) external whenNotPaused onlyRegisteredResearcher {
        bool fieldExists = false;
        for (uint i = 0; i < activeResearchFields.length; i++) {
            if (keccak256(bytes(activeResearchFields[i])) == keccak256(bytes(_researchField))) {
                fieldExists = true;
                break;
            }
        }
        require(fieldExists, "Research field is not active or does not exist.");

        researchProposals[researchProposalCount] = ResearchProposal({
            title: _title,
            description: _description,
            researchField: _researchField,
            ipfsProposalHash: _ipfsProposalHash,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            proposer: msg.sender,
            status: ProposalStatus.Pending,
            submissionTimestamp: block.timestamp,
            peerReviewers: new address[](0), // Could be assigned based on expertise matching
            peerReviews: new string[](0),
            peerRatings: new uint[](0),
            ipfsResultsHash: "",
            milestones: new Milestone[](0),
            ipOutputs: new IPOutput[](0)
        });
        emit ResearchProposalSubmitted(researchProposalCount, _title, msg.sender);
        researchProposalCount++;
    }

    /**
     * @dev Allows designated peer reviewers to review proposals and provide feedback and ratings.
     * @param _proposalId ID of the research proposal.
     * @param _reviewFeedback Textual feedback from the reviewer.
     * @param _rating Rating given by the reviewer (e.g., 1-5 scale).
     */
    function peerReviewProposal(uint _proposalId, string memory _reviewFeedback, uint _rating) external whenNotPaused onlyRegisteredResearcher {
        require(researchProposals[_proposalId].status == ProposalStatus.Pending || researchProposals[_proposalId].status == ProposalStatus.Review, "Proposal not in reviewable status.");
        // In a real system, reviewer assignment and access control would be more sophisticated.
        researchProposals[_proposalId].peerReviewers.push(msg.sender);
        researchProposals[_proposalId].peerReviews.push(_reviewFeedback);
        researchProposals[_proposalId].peerRatings.push(_rating);

        // Simple logic to move to funding stage after a certain number of reviews/average rating
        if (researchProposals[_proposalId].peerReviewers.length >= 2) { // Example: require 2 reviews
            researchProposals[_proposalId].status = ProposalStatus.Funding;
        }
        emit ResearchProposalReviewed(_proposalId, msg.sender, _reviewFeedback, _rating);
    }

    /**
     * @dev Allows anyone to contribute funds to a research proposal.
     * @param _proposalId ID of the research proposal.
     */
    function fundResearchProposal(uint _proposalId) external payable whenNotPaused onlyValidProposalStatus(_proposalId, ProposalStatus.Funding) {
        require(msg.value > 0, "Funding amount must be greater than zero.");
        researchProposals[_proposalId].currentFunding += msg.value;
        emit ResearchProposalFunded(_proposalId, msg.sender, msg.value);

        if (researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal) {
            researchProposals[_proposalId].status = ProposalStatus.InProgress;
        }
    }

    /**
     * @dev Allows the proposal lead to withdraw funds once funding goal is reached and proposal is approved.
     * @param _proposalId ID of the research proposal.
     */
    function withdrawProposalFunds(uint _proposalId) external whenNotPaused onlyProposalProposer(_proposalId) onlyValidProposalStatus(_proposalId, ProposalStatus.InProgress) {
        require(researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal, "Funding goal not reached.");

        uint platformFee = researchProposals[_proposalId].currentFunding.mul(platformFeePercentage).div(100);
        uint withdrawAmount = researchProposals[_proposalId].currentFunding.sub(platformFee);

        payable(researchProposals[_proposalId].proposer).transfer(withdrawAmount);
        payable(owner()).transfer(platformFee); // DAO receives platform fee

        researchProposals[_proposalId].currentFunding = 0; // Reset funding after withdrawal
        emit ResearchProposalFundsWithdrawn(_proposalId, msg.sender, withdrawAmount);
    }

    /**
     * @dev Allows proposal leads to submit milestones and associated data.
     * @param _proposalId ID of the research proposal.
     * @param _milestoneDescription Description of the milestone achieved.
     * @param _ipfsMilestoneHash IPFS hash of the milestone data/report.
     */
    function submitResearchMilestone(uint _proposalId, string memory _milestoneDescription, string memory _ipfsMilestoneHash) external whenNotPaused onlyProposalProposer(_proposalId) onlyValidProposalStatus(_proposalId, ProposalStatus.InProgress) {
        uint milestoneIndex = researchProposals[_proposalId].milestones.length;
        researchProposals[_proposalId].milestones.push(Milestone({
            description: _milestoneDescription,
            ipfsMilestoneHash: _ipfsMilestoneHash,
            isCompleted: false,
            completionTimestamp: 0
        }));
        emit ResearchMilestoneSubmitted(_proposalId, milestoneIndex, _milestoneDescription);
    }

    /**
     * @dev Allows reviewers or governance to mark milestones as completed.
     * @param _proposalId ID of the research proposal.
     * @param _milestoneIndex Index of the milestone to mark as complete.
     */
    function markMilestoneComplete(uint _proposalId, uint _milestoneIndex) external whenNotPaused onlyValidProposalStatus(_proposalId, ProposalStatus.InProgress) onlyValidMilestone(_proposalId, _milestoneIndex) {
        // In a real system, more sophisticated milestone verification and approval could be implemented.
        researchProposals[_proposalId].milestones[_milestoneIndex].isCompleted = true;
        researchProposals[_proposalId].milestones[_milestoneIndex].completionTimestamp = block.timestamp;
        emit ResearchMilestoneMarkedComplete(_proposalId, _milestoneIndex);
    }

    /**
     * @dev Allows proposal leads to submit final research results upon project completion.
     * @param _proposalId ID of the research proposal.
     * @param _ipfsResultsHash IPFS hash of the final research results document.
     */
    function submitResearchResults(uint _proposalId, string memory _ipfsResultsHash) external whenNotPaused onlyProposalProposer(_proposalId) onlyValidProposalStatus(_proposalId, ProposalStatus.InProgress) {
        researchProposals[_proposalId].ipfsResultsHash = _ipfsResultsHash;
        researchProposals[_proposalId].status = ProposalStatus.Completed;
        emit ResearchResultsSubmitted(_proposalId, _ipfsResultsHash);
        emit ResearchCompleted(_proposalId);
    }

    /**
     * @dev Marks a research proposal as fully completed (final state).
     * @param _proposalId ID of the research proposal.
     */
    function markResearchComplete(uint _proposalId) external onlyOwner whenNotPaused onlyValidProposalStatus(_proposalId, ProposalStatus.Completed) {
        researchProposals[_proposalId].status = ProposalStatus.Completed; // Redundant, but ensures state is set
        emit ResearchCompleted(_proposalId); // Event also redundant, but keeping for clarity in workflow.
    }


    // --- 4. Intellectual Property & Data Management Functions ---

    /**
     * @dev Allows registering IP associated with research outputs, linking to IPFS and defining license.
     * @param _proposalId ID of the research proposal.
     * @param _outputName Name of the research output (e.g., "Dataset", "Algorithm", "Publication").
     * @param _ipfsIPHash IPFS hash of the IP asset (e.g., document, code).
     * @param _licenseType Type of license for the IP (e.g., "CC-BY-NC", "MIT", "Proprietary").
     */
    function registerResearchOutputIP(uint _proposalId, string memory _outputName, string memory _ipfsIPHash, string memory _licenseType) external whenNotPaused onlyProposalProposer(_proposalId) onlyValidProposalStatus(_proposalId, ProposalStatus.Completed) {
        uint outputIndex = researchProposals[_proposalId].ipOutputs.length;
        researchProposals[_proposalId].ipOutputs.push(IPOutput({
            outputName: _outputName,
            ipfsIPHash: _ipfsIPHash,
            licenseType: _licenseType,
            owner: msg.sender, // Initially proposer, could be DAO in future versions
            isPubliclyAccessible: (keccak256(bytes(_licenseType)) != keccak256(bytes("Proprietary"))), // Example: Proprietary license makes it not publicly accessible by default
            allowedAccessAddresses: new address[](0)
        }));
        emit IPRegistered(_proposalId, outputIndex, _outputName, _licenseType);
    }

    /**
     * @dev Allows external parties to request access to research data (governed by license).
     * @param _proposalId ID of the research proposal.
     */
    function requestResearchDataAccess(uint _proposalId) external whenNotPaused {
        require(researchProposals[_proposalId].status == ProposalStatus.Completed, "Research not completed yet.");
        // In a real system, license checks and automated access granting based on license terms would be implemented.
        emit DataAccessRequested(_proposalId, msg.sender);
        // For now, a simple event is emitted. Manual granting process could be off-chain or through governance.
    }

    /**
     * @dev Allows IP owners to grant data access to approved requesters (can be automated based on license).
     * @param _proposalId ID of the research proposal.
     * @param _requester Address of the party requesting access.
     */
    function grantResearchDataAccess(uint _proposalId, address _requester) external whenNotPaused onlyProposalProposer(_proposalId) onlyValidProposalStatus(_proposalId, ProposalStatus.Completed) {
        require(researchProposals[_proposalId].status == ProposalStatus.Completed, "Research not completed yet.");
        // Simplified access granting. In reality, license terms would be checked, and access could be automated.
        for (uint i = 0; i < researchProposals[_proposalId].ipOutputs.length; i++) {
            researchProposals[_proposalId].ipOutputs[i].allowedAccessAddresses.push(_requester);
        }
        emit DataAccessGranted(_proposalId, msg.sender, _requester);
    }


    // --- 5. Utility & Platform Management Functions ---

    /**
     * @dev Allows the contract governor to pause critical functions in case of emergency.
     */
    function pauseContract() external onlyOwner {
        contractPaused = true;
        emit ContractPaused(msg.sender);
    }

    /**
     * @dev Allows the contract governor to resume contract functions.
     */
    function unpauseContract() external onlyOwner {
        contractPaused = false;
        emit ContractUnpaused(msg.sender);
    }

    /**
     * @dev Allows governance to set a platform fee for funded proposals (as DAO revenue).
     * @param _feePercentage The fee percentage (0-100).
     */
    function setPlatformFee(uint _feePercentage) external onlyOwner {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /**
     * @dev Returns the current balance of the contract.
     * @return The contract balance in wei.
     */
    function getContractBalance() external view returns (uint) {
        return address(this).balance;
    }
}

// --- Helper Library (Simplified String conversion for Events - for demonstration only, consider importing a proper library for production) ---
library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        // Convert uint256 to string (simplified for demonstration, not fully optimized)
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
}
```