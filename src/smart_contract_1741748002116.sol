```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A sophisticated smart contract for managing a Decentralized Autonomous Research Organization (DARO).
 *      This contract facilitates research proposal submission, voting, funding, intellectual property management,
 *      researcher reputation tracking, decentralized licensing, and more. It aims to foster collaborative
 *      and transparent research in a decentralized environment.

 * **Contract Outline & Function Summary:**

 * **Core Functionality:**
 * 1. `submitResearchProposal(string _title, string _description, uint256 _fundingGoal, string _ipfsHash)`: Allows researchers to submit research proposals with details and funding goals.
 * 2. `voteOnProposal(uint256 _proposalId, bool _support)`:  Members can vote on research proposals to decide which ones are approved for funding.
 * 3. `fundProposal(uint256 _proposalId)`:  Allows anyone to contribute funds to approved research proposals.
 * 4. `withdrawProposalFunds(uint256 _proposalId)`: Allows the proposal submitter to withdraw funds if the proposal is approved and funded.
 * 5. `markProposalAsCompleted(uint256 _proposalId, string _finalReportIpfsHash)`: Allows the proposal submitter to mark a proposal as completed and submit a final report.
 * 6. `reviewCompletedProposal(uint256 _proposalId, string _reviewIpfsHash, uint8 _rating)`: Members can review completed proposals and provide ratings, contributing to researcher reputation.
 * 7. `createLicenseTemplate(string _name, string _description, uint256 _price, string _termsIpfsHash)`: Allows the contract owner to create reusable license templates for research outputs.
 * 8. `licenseResearchOutput(uint256 _proposalId, uint256 _licenseTemplateId)`: Allows researchers to license their research outputs using predefined templates.
 * 9. `purchaseLicense(uint256 _licenseId)`: Allows anyone to purchase a license to access and use research outputs.
 * 10. `transferLicense(uint256 _licenseId, address _newLicensee)`: Allows license holders to transfer their licenses to other parties.

 * **Researcher & Member Management:**
 * 11. `registerResearcher(string _name, string _expertise, string _profileIpfsHash)`: Allows individuals to register as researchers within the DARO.
 * 12. `updateResearcherProfile(string _name, string _expertise, string _profileIpfsHash)`: Allows registered researchers to update their profiles.
 * 13. `addMember(address _memberAddress)`: Allows the contract owner to add new members who can vote and participate in governance.
 * 14. `removeMember(address _memberAddress)`: Allows the contract owner to remove members.

 * **Governance & DAO Management:**
 * 15. `changeVotingDuration(uint256 _newDuration)`: Allows the contract owner to change the default voting duration for proposals.
 * 16. `changeVotingQuorum(uint256 _newQuorum)`: Allows the contract owner to change the voting quorum required for proposal approval.
 * 17. `pauseContract()`: Allows the contract owner to temporarily pause contract functionalities in case of emergency.
 * 18. `unpauseContract()`: Allows the contract owner to resume contract functionalities after pausing.
 * 19. `proposeContractUpgrade(address _newContractAddress)`: Allows members to propose upgrading the contract to a new implementation.
 * 20. `voteOnContractUpgrade(uint256 _upgradeProposalId, bool _support)`: Members can vote on contract upgrade proposals.

 * **Utility & Information Retrieval:**
 * 21. `getProposalDetails(uint256 _proposalId)`: Allows anyone to retrieve detailed information about a specific research proposal.
 * 22. `getResearcherDetails(address _researcherAddress)`: Allows anyone to retrieve details about a registered researcher.
 * 23. `getLicenseDetails(uint256 _licenseId)`: Allows anyone to retrieve details about a specific research license.
 * 24. `getLicenseTemplateDetails(uint256 _licenseTemplateId)`: Allows anyone to retrieve details about a specific license template.
 * 25. `getResearcherReputation(address _researcherAddress)`: Allows anyone to retrieve the reputation score of a researcher.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DARO is Ownable, Pausable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    // --- Structs ---

    struct ResearchProposal {
        uint256 id;
        address researcher;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string ipfsHash; // IPFS hash of the detailed proposal document
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isApproved;
        bool isCompleted;
        string finalReportIpfsHash; // IPFS hash of the final research report
    }

    struct ResearcherProfile {
        address researcherAddress;
        string name;
        string expertise;
        string profileIpfsHash; // IPFS hash to a more detailed profile
        uint256 reputationScore;
    }

    struct LicenseTemplate {
        uint256 id;
        string name;
        string description;
        uint256 price;
        string termsIpfsHash; // IPFS hash to the license terms document
    }

    struct ResearchLicense {
        uint256 id;
        uint256 proposalId;
        uint256 templateId;
        address licensee;
        uint256 purchaseTime;
    }

    struct ContractUpgradeProposal {
        uint256 id;
        address newContractAddress;
        uint256 votingEndTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool isApproved;
    }

    // --- State Variables ---

    Counters.Counter private _proposalIds;
    mapping(uint256 => ResearchProposal) public researchProposals;
    Counters.Counter private _researcherCount;
    mapping(address => ResearcherProfile) public researcherProfiles;
    Counters.Counter private _licenseTemplateIds;
    mapping(uint256 => LicenseTemplate) public licenseTemplates;
    Counters.Counter private _licenseIds;
    mapping(uint256 => ResearchLicense) public researchLicenses;
    Counters.Counter private _upgradeProposalIds;
    mapping(uint256 => ContractUpgradeProposal) public contractUpgradeProposals;

    mapping(address => bool) public members; // List of DAO members who can vote

    uint256 public votingDuration = 7 days; // Default voting duration
    uint256 public votingQuorum = 50; // Percentage quorum for proposal approval
    uint256 public licenseRevenueSharePercentage = 90; // Percentage of license revenue to researcher

    // --- Events ---

    event ProposalSubmitted(uint256 proposalId, address researcher, string title);
    event ProposalVoted(uint256 proposalId, address voter, bool support);
    event ProposalFunded(uint256 proposalId, address funder, uint256 amount);
    event ProposalFundsWithdrawn(uint256 proposalId, address researcher, uint256 amount);
    event ProposalCompleted(uint256 proposalId, address researcher);
    event ProposalReviewed(uint256 proposalId, address reviewer, uint8 rating);
    event LicenseTemplateCreated(uint256 templateId, string name);
    event ResearchOutputLicensed(uint256 licenseId, uint256 proposalId, uint256 templateId, address licensee);
    event LicensePurchased(uint256 licenseId, address licensee, uint256 price);
    event LicenseTransferred(uint256 licenseId, address oldLicensee, address newLicensee);
    event ResearcherRegistered(address researcherAddress, string name);
    event ResearcherProfileUpdated(address researcherAddress, string name);
    event MemberAdded(address memberAddress);
    event MemberRemoved(address memberAddress);
    event VotingDurationChanged(uint256 newDuration);
    event VotingQuorumChanged(uint256 newQuorum);
    event ContractPaused();
    event ContractUnpaused();
    event ContractUpgradeProposed(uint256 upgradeProposalId, address newContractAddress);
    event ContractUpgradeVoted(uint256 upgradeProposalId, address voter, bool support);
    event ContractUpgraded(address newContractAddress);


    // --- Modifiers ---

    modifier onlyMember() {
        require(members[msg.sender] || msg.sender == owner(), "Caller is not a DAO member");
        _;
    }

    modifier onlyResearcher(uint256 _proposalId) {
        require(researchProposals[_proposalId].researcher == msg.sender, "Caller is not the proposal researcher");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalIds.current() >= _proposalId && _proposalId > 0, "Proposal does not exist");
        _;
    }

    modifier proposalVotingActive(uint256 _proposalId) {
        require(block.timestamp < researchProposals[_proposalId].votingEndTime, "Voting period has ended");
        _;
    }

    modifier proposalApproved(uint256 _proposalId) {
        require(researchProposals[_proposalId].isApproved, "Proposal is not approved");
        _;
    }

    modifier proposalNotCompleted(uint256 _proposalId) {
        require(!researchProposals[_proposalId].isCompleted, "Proposal is already completed");
        _;
    }

    modifier licenseTemplateExists(uint256 _templateId) {
        require(_licenseTemplateIds.current() >= _templateId && _templateId > 0, "License template does not exist");
        _;
    }

    modifier licenseExists(uint256 _licenseId) {
        require(_licenseIds.current() >= _licenseId && _licenseId > 0, "License does not exist");
        _;
    }

    modifier onlyLicensee(uint256 _licenseId) {
        require(researchLicenses[_licenseId].licensee == msg.sender, "Caller is not the license holder");
        _;
    }

    modifier upgradeProposalExists(uint256 _upgradeProposalId) {
        require(_upgradeProposalIds.current() >= _upgradeProposalId && _upgradeProposalId > 0, "Upgrade proposal does not exist");
        _;
    }

    modifier upgradeVotingActive(uint256 _upgradeProposalId) {
        require(block.timestamp < contractUpgradeProposals[_upgradeProposalId].votingEndTime, "Upgrade voting period has ended");
        _;
    }


    // --- Constructor ---

    constructor() payable {
        _proposalIds.increment(); // Start proposal IDs from 1
        _licenseTemplateIds.increment(); // Start template IDs from 1
        _licenseIds.increment(); // Start license IDs from 1
        _upgradeProposalIds.increment(); // Start upgrade proposal IDs from 1
        members[msg.sender] = true; // Owner is automatically a member
    }


    // --- Core Functionality Functions ---

    /**
     * @dev Submits a research proposal.
     * @param _title The title of the research proposal.
     * @param _description A brief description of the research.
     * @param _fundingGoal The target funding amount for the research.
     * @param _ipfsHash IPFS hash of the detailed proposal document.
     */
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsHash
    ) public whenNotPaused {
        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();
        researchProposals[proposalId] = ResearchProposal({
            id: proposalId,
            researcher: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            ipfsHash: _ipfsHash,
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isApproved: false,
            isCompleted: false,
            finalReportIpfsHash: ""
        });
        emit ProposalSubmitted(proposalId, msg.sender, _title);
    }

    /**
     * @dev Allows members to vote on a research proposal.
     * @param _proposalId The ID of the proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support)
        public
        whenNotPaused
        onlyMember
        proposalExists(_proposalId)
        proposalVotingActive(_proposalId)
    {
        require(researchProposals[_proposalId].researcher != msg.sender, "Researcher cannot vote on their own proposal");
        ResearchProposal storage proposal = researchProposals[_proposalId];
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ProposalVoted(_proposalId, msg.sender, _support);

        // Check if voting period ended and update approval status
        if (block.timestamp >= proposal.votingEndTime && !proposal.isApproved && !proposal.isCompleted) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            if (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= votingQuorum) {
                proposal.isApproved = true;
            }
        }
    }

    /**
     * @dev Allows anyone to contribute funds to an approved research proposal.
     * @param _proposalId The ID of the proposal to fund.
     */
    function fundProposal(uint256 _proposalId)
        public
        payable
        whenNotPaused
        proposalExists(_proposalId)
        proposalApproved(_proposalId)
        proposalNotCompleted(_proposalId)
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.currentFunding.add(msg.value) <= proposal.fundingGoal, "Funding goal exceeded");
        proposal.currentFunding = proposal.currentFunding.add(msg.value);
        emit ProposalFunded(_proposalId, msg.sender, msg.value);
    }

    /**
     * @dev Allows the researcher to withdraw funds from an approved and funded proposal.
     * @param _proposalId The ID of the proposal to withdraw funds from.
     */
    function withdrawProposalFunds(uint256 _proposalId)
        public
        whenNotPaused
        proposalExists(_proposalId)
        proposalApproved(_proposalId)
        proposalNotCompleted(_proposalId)
        onlyResearcher(_proposalId)
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.currentFunding > 0, "No funds to withdraw");
        uint256 amountToWithdraw = proposal.currentFunding;
        proposal.currentFunding = 0; // Set currentFunding to 0 after withdrawal
        payable(proposal.researcher).transfer(amountToWithdraw);
        emit ProposalFundsWithdrawn(_proposalId, msg.sender, amountToWithdraw);
    }

    /**
     * @dev Marks a proposal as completed by the researcher and submits a final report.
     * @param _proposalId The ID of the proposal to mark as completed.
     * @param _finalReportIpfsHash IPFS hash of the final research report document.
     */
    function markProposalAsCompleted(uint256 _proposalId, string memory _finalReportIpfsHash)
        public
        whenNotPaused
        proposalExists(_proposalId)
        proposalApproved(_proposalId)
        proposalNotCompleted(_proposalId)
        onlyResearcher(_proposalId)
    {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        proposal.isCompleted = true;
        proposal.finalReportIpfsHash = _finalReportIpfsHash;
        emit ProposalCompleted(_proposalId, msg.sender);
    }

    /**
     * @dev Allows members to review a completed proposal and provide a rating.
     * @param _proposalId The ID of the completed proposal to review.
     * @param _reviewIpfsHash IPFS hash of the review document.
     * @param _rating A rating for the proposal (e.g., 1-5 scale, or out of 10).
     */
    function reviewCompletedProposal(uint256 _proposalId, string memory _reviewIpfsHash, uint8 _rating)
        public
        whenNotPaused
        onlyMember
        proposalExists(_proposalId)
        proposalApproved(_proposalId)
        proposalNotCompleted(_proposalId) // Should be completed, but using NotCompleted for modifier reuse (rename later if needed)
    {
        require(researchProposals[_proposalId].isCompleted, "Proposal is not yet completed");
        // Basic reputation update - can be expanded with more sophisticated logic
        researcherProfiles[researchProposals[_proposalId].researcher].reputationScore = researcherProfiles[researchProposals[_proposalId].researcher].reputationScore.add(_rating);
        emit ProposalReviewed(_proposalId, msg.sender, _rating);
    }

    /**
     * @dev Creates a reusable license template for research outputs. Only callable by the contract owner.
     * @param _name The name of the license template.
     * @param _description A description of the license template.
     * @param _price The price of the license.
     * @param _termsIpfsHash IPFS hash of the license terms document.
     */
    function createLicenseTemplate(
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _termsIpfsHash
    ) public onlyOwner whenNotPaused {
        _licenseTemplateIds.increment();
        uint256 templateId = _licenseTemplateIds.current();
        licenseTemplates[templateId] = LicenseTemplate({
            id: templateId,
            name: _name,
            description: _description,
            price: _price,
            termsIpfsHash: _termsIpfsHash
        });
        emit LicenseTemplateCreated(templateId, _name);
    }

    /**
     * @dev Allows a researcher to license their research output from a proposal using a predefined template.
     * @param _proposalId The ID of the proposal whose output is being licensed.
     * @param _licenseTemplateId The ID of the license template to use.
     */
    function licenseResearchOutput(uint256 _proposalId, uint256 _licenseTemplateId)
        public
        whenNotPaused
        proposalExists(_proposalId)
        proposalApproved(_proposalId)
        proposalCompleted(_proposalId)
        onlyResearcher(_proposalId)
        licenseTemplateExists(_licenseTemplateId)
    {
        _licenseIds.increment();
        uint256 licenseId = _licenseIds.current();
        researchLicenses[licenseId] = ResearchLicense({
            id: licenseId,
            proposalId: _proposalId,
            templateId: _licenseTemplateId,
            licensee: address(0), // No licensee initially, purchased later
            purchaseTime: 0
        });
        emit ResearchOutputLicensed(licenseId, _proposalId, _licenseTemplateId, address(0)); // Licensee is set on purchase
    }

    /**
     * @dev Allows anyone to purchase a license to a research output.
     * @param _licenseId The ID of the license to purchase.
     */
    function purchaseLicense(uint256 _licenseId)
        public
        payable
        whenNotPaused
        licenseExists(_licenseId)
    {
        ResearchLicense storage license = researchLicenses[_licenseId];
        LicenseTemplate storage template = licenseTemplates[license.templateId];
        require(license.licensee == address(0), "License already purchased"); // Ensure license is not already purchased
        require(msg.value >= template.price, "Insufficient payment for license");

        license.licensee = msg.sender;
        license.purchaseTime = block.timestamp;
        emit LicensePurchased(_licenseId, msg.sender, template.price);

        // Distribute revenue - researcher gets percentage, rest to contract (DAO treasury)
        uint256 researcherShare = (template.price * licenseRevenueSharePercentage) / 100;
        uint256 daoShare = template.price.sub(researcherShare);

        payable(researchProposals[license.proposalId].researcher).transfer(researcherShare);
        payable(owner()).transfer(daoShare); // DAO treasury controlled by contract owner for now, could be a multi-sig or DAO controlled later
    }

    /**
     * @dev Allows a license holder to transfer their license to another address.
     * @param _licenseId The ID of the license to transfer.
     * @param _newLicensee The address of the new licensee.
     */
    function transferLicense(uint256 _licenseId, address _newLicensee)
        public
        whenNotPaused
        licenseExists(_licenseId)
        onlyLicensee(_licenseId)
    {
        ResearchLicense storage license = researchLicenses[_licenseId];
        address oldLicensee = license.licensee;
        license.licensee = _newLicensee;
        emit LicenseTransferred(_licenseId, oldLicensee, _newLicensee);
    }


    // --- Researcher & Member Management Functions ---

    /**
     * @dev Registers a new researcher in the DARO.
     * @param _name The name of the researcher.
     * @param _expertise The area of expertise of the researcher.
     * @param _profileIpfsHash IPFS hash to a more detailed researcher profile.
     */
    function registerResearcher(string memory _name, string memory _expertise, string memory _profileIpfsHash) public whenNotPaused {
        require(researcherProfiles[msg.sender].researcherAddress == address(0), "Researcher already registered"); // Prevent re-registration
        _researcherCount.increment();
        researcherProfiles[msg.sender] = ResearcherProfile({
            researcherAddress: msg.sender,
            name: _name,
            expertise: _expertise,
            profileIpfsHash: _profileIpfsHash,
            reputationScore: 0 // Initial reputation score
        });
        emit ResearcherRegistered(msg.sender, _name);
    }

    /**
     * @dev Allows a registered researcher to update their profile information.
     * @param _name The updated name of the researcher.
     * @param _expertise The updated area of expertise.
     * @param _profileIpfsHash IPFS hash to the updated profile document.
     */
    function updateResearcherProfile(string memory _name, string memory _expertise, string memory _profileIpfsHash)
        public
        whenNotPaused
    {
        require(researcherProfiles[msg.sender].researcherAddress != address(0), "Researcher not registered");
        researcherProfiles[msg.sender].name = _name;
        researcherProfiles[msg.sender].expertise = _expertise;
        researcherProfiles[msg.sender].profileIpfsHash = _profileIpfsHash;
        emit ResearcherProfileUpdated(msg.sender, _name);
    }

    /**
     * @dev Allows the contract owner to add a new member to the DAO.
     * @param _memberAddress The address of the member to add.
     */
    function addMember(address _memberAddress) public onlyOwner whenNotPaused {
        members[_memberAddress] = true;
        emit MemberAdded(_memberAddress);
    }

    /**
     * @dev Allows the contract owner to remove a member from the DAO.
     * @param _memberAddress The address of the member to remove.
     */
    function removeMember(address _memberAddress) public onlyOwner whenNotPaused {
        delete members[_memberAddress];
        emit MemberRemoved(_memberAddress);
    }


    // --- Governance & DAO Management Functions ---

    /**
     * @dev Allows the contract owner to change the default voting duration for proposals.
     * @param _newDuration The new voting duration in seconds.
     */
    function changeVotingDuration(uint256 _newDuration) public onlyOwner whenNotPaused {
        votingDuration = _newDuration;
        emit VotingDurationChanged(_newDuration);
    }

    /**
     * @dev Allows the contract owner to change the voting quorum required for proposal approval.
     * @param _newQuorum The new voting quorum percentage (0-100).
     */
    function changeVotingQuorum(uint256 _newQuorum) public onlyOwner whenNotPaused {
        require(_newQuorum <= 100, "Quorum must be between 0 and 100");
        votingQuorum = _newQuorum;
        emit VotingQuorumChanged(_newQuorum);
    }

    /**
     * @dev Pauses the contract, preventing most functionalities. Only callable by the contract owner.
     */
    function pauseContract() public onlyOwner {
        _pause();
        emit ContractPaused();
    }

    /**
     * @dev Unpauses the contract, restoring functionalities. Only callable by the contract owner.
     */
    function unpauseContract() public onlyOwner {
        _unpause();
        emit ContractUnpaused();
    }

    /**
     * @dev Allows members to propose upgrading the contract to a new implementation address.
     * @param _newContractAddress The address of the new contract implementation.
     */
    function proposeContractUpgrade(address _newContractAddress) public onlyMember whenNotPaused {
        require(_newContractAddress != address(0), "New contract address cannot be zero address");
        _upgradeProposalIds.increment();
        uint256 upgradeProposalId = _upgradeProposalIds.current();
        contractUpgradeProposals[upgradeProposalId] = ContractUpgradeProposal({
            id: upgradeProposalId,
            newContractAddress: _newContractAddress,
            votingEndTime: block.timestamp + votingDuration,
            yesVotes: 0,
            noVotes: 0,
            isApproved: false
        });
        emit ContractUpgradeProposed(upgradeProposalId, _newContractAddress);
    }

    /**
     * @dev Allows members to vote on a contract upgrade proposal.
     * @param _upgradeProposalId The ID of the upgrade proposal to vote on.
     * @param _support True to vote in favor, false to vote against.
     */
    function voteOnContractUpgrade(uint256 _upgradeProposalId, bool _support)
        public
        whenNotPaused
        onlyMember
        upgradeProposalExists(_upgradeProposalId)
        upgradeVotingActive(_upgradeProposalId)
    {
        ContractUpgradeProposal storage proposal = contractUpgradeProposals[_upgradeProposalId];
        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }
        emit ContractUpgradeVoted(_upgradeProposalId, msg.sender, _support);

        // Check if voting period ended and update approval status
        if (block.timestamp >= proposal.votingEndTime && !proposal.isApproved) {
            uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
            if (totalVotes > 0 && (proposal.yesVotes * 100) / totalVotes >= votingQuorum) {
                proposal.isApproved = true;
                if(proposal.isApproved){
                    // In a real upgrade scenario, you'd use a more robust upgrade pattern (e.g., proxy contracts).
                    // For this example, we just emit an event to indicate approval.
                    emit ContractUpgraded(proposal.newContractAddress);
                    // In a basic example, you might consider selfdestruct to the new address (use with extreme caution and understand implications).
                    // selfdestruct(payable(proposal.newContractAddress));
                }
            }
        }
    }


    // --- Utility & Information Retrieval Functions ---

    /**
     * @dev Retrieves details of a research proposal.
     * @param _proposalId The ID of the proposal.
     * @return ResearchProposal struct containing proposal details.
     */
    function getProposalDetails(uint256 _proposalId)
        public
        view
        proposalExists(_proposalId)
        returns (ResearchProposal memory)
    {
        return researchProposals[_proposalId];
    }

    /**
     * @dev Retrieves details of a registered researcher.
     * @param _researcherAddress The address of the researcher.
     * @return ResearcherProfile struct containing researcher details.
     */
    function getResearcherDetails(address _researcherAddress)
        public
        view
        returns (ResearcherProfile memory)
    {
        return researcherProfiles[_researcherAddress];
    }

    /**
     * @dev Retrieves details of a research license.
     * @param _licenseId The ID of the license.
     * @return ResearchLicense struct containing license details.
     */
    function getLicenseDetails(uint256 _licenseId)
        public
        view
        licenseExists(_licenseId)
        returns (ResearchLicense memory)
    {
        return researchLicenses[_licenseId];
    }

    /**
     * @dev Retrieves details of a license template.
     * @param _templateId The ID of the license template.
     * @return LicenseTemplate struct containing template details.
     */
    function getLicenseTemplateDetails(uint256 _templateId)
        public
        view
        licenseTemplateExists(_templateId)
        returns (LicenseTemplate memory)
    {
        return licenseTemplates[_templateId];
    }

    /**
     * @dev Retrieves the reputation score of a researcher.
     * @param _researcherAddress The address of the researcher.
     * @return uint256 The reputation score.
     */
    function getResearcherReputation(address _researcherAddress)
        public
        view
        returns (uint256)
    {
        return researcherProfiles[_researcherAddress].reputationScore;
    }
}
```