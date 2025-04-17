```solidity
/**
 * @title Decentralized Autonomous Research Organization (DARO) Smart Contract
 * @author Bard (AI Assistant)
 * @dev A smart contract for a Decentralized Autonomous Research Organization (DARO).
 * It facilitates research proposal submission, funding, execution, and intellectual property management,
 * all governed by a decentralized community using advanced blockchain concepts.
 *
 * **Outline and Function Summary:**
 *
 * **I. Membership & Governance:**
 *   1. `requestMembership()`: Allows anyone to request membership in the DARO.
 *   2. `approveMembership(address _member)`:  Governance members approve pending membership requests.
 *   3. `revokeMembership(address _member)`: Governance members can revoke membership.
 *   4. `isMember(address _address)`: Checks if an address is a member of the DARO.
 *   5. `setGovernanceThreshold(uint256 _threshold)`: Sets the required approvals for governance actions.
 *   6. `addGovernanceMember(address _governanceMember)`: Adds a new address to the governance member list.
 *   7. `removeGovernanceMember(address _governanceMember)`: Removes an address from the governance member list.
 *   8. `isGovernanceMember(address _address)`: Checks if an address is a governance member.
 *
 * **II. Research Proposal Management:**
 *   9. `submitResearchProposal(string memory _title, string memory _description, uint256 _fundingGoal, string memory _ipfsHash)`: Members submit research proposals.
 *  10. `reviewResearchProposal(uint256 _proposalId, bool _approve, string memory _reviewComments)`: Governance members review and vote on research proposals.
 *  11. `fundResearchProposal(uint256 _proposalId)`: Members can contribute funds to approved research proposals.
 *  12. `withdrawProposalFunds(uint256 _proposalId)`: Researchers (proposal submitters) can withdraw funded amount after proposal is approved and funded.
 *  13. `markProposalInProgress(uint256 _proposalId)`: Researchers mark a funded proposal as "in progress".
 *  14. `submitResearchOutput(uint256 _proposalId, string memory _outputDescription, string memory _outputIpfsHash)`: Researchers submit research outputs for completed proposals.
 *  15. `reviewResearchOutput(uint256 _outputId, bool _approve, string memory _reviewComments)`: Governance members review and approve submitted research outputs.
 *  16. `finalizeResearchProposal(uint256 _proposalId)`:  Finalizes a proposal after output approval, releasing remaining funds and marking it as completed.
 *  17. `getProposalDetails(uint256 _proposalId)`: Retrieves detailed information about a research proposal.
 *  18. `getOutputDetails(uint256 _outputId)`: Retrieves details of a submitted research output.
 *
 * **III. Intellectual Property (IP) & Rewards (Advanced Concept - NFT based IP Licensing):**
 *  19. `mintResearchOutputNFT(uint256 _outputId)`: Mints an NFT representing the approved research output IP, owned by the DARO initially.
 *  20. `licenseResearchOutputIP(uint256 _outputId, address _licensee, uint256 _licenseFee, uint256 _licenseDurationDays)`: Allows the DARO to license the IP (represented by the NFT) to external entities.
 *  21. `revokeIPLicense(uint256 _licenseId)`: Governance can revoke an IP license if terms are violated.
 *  22. `transferIPOwnership(uint256 _outputId, address _newOwner)`: (Governance controlled) Potentially transfer IP ownership in exceptional cases.
 *
 * **IV. Utility & Security:**
 *  23. `pauseContract()`: Allows contract owner to pause core functionalities in case of emergency.
 *  24. `unpauseContract()`: Allows contract owner to unpause the contract.
 *  25. `setPlatformFee(uint256 _feePercentage)`: Sets a platform fee (percentage) on funded proposals (for DARO sustainability).
 *  26. `withdrawPlatformFees()`: Allows governance to withdraw accumulated platform fees.
 *  27. `getContractBalance()`: Returns the contract's current ETH balance.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DecentralizedAutonomousResearchOrganization is Ownable, ERC721, Pausable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _proposalIds;
    Counters.Counter private _outputIds;
    Counters.Counter private _licenseIds;

    // --- STRUCTS ---
    struct ResearchProposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        uint256 fundingGoal;
        uint256 currentFunding;
        string ipfsHash; // IPFS hash for detailed proposal document
        ProposalStatus status;
        uint256 approvalCount;
        mapping(address => bool) reviewersApproved;
        string[] reviewComments;
        uint256 outputId; // ID of the associated ResearchOutput (if any)
        uint256 submissionTimestamp;
        uint256 withdrawalTimestamp;
    }

    struct ResearchOutput {
        uint256 id;
        uint256 proposalId;
        address submitter;
        string description;
        string ipfsHash; // IPFS hash for research output document/data
        OutputStatus status;
        uint256 approvalCount;
        mapping(address => bool) reviewersApproved;
        string[] reviewComments;
        uint256 submissionTimestamp;
    }

    struct IPLicense {
        uint256 id;
        uint256 outputId;
        address licensee;
        uint256 licenseFee;
        uint256 licenseDurationDays;
        uint256 licenseStartTime;
        bool isActive;
    }

    // --- ENUMS ---
    enum ProposalStatus { Pending, Approved, Rejected, InProgress, Completed, Funded, Failed }
    enum OutputStatus { PendingReview, Approved, Rejected }

    // --- MAPPINGS & ARRAYS ---
    mapping(uint256 => ResearchProposal) public researchProposals;
    mapping(uint256 => ResearchOutput) public researchOutputs;
    mapping(uint256 => IPLicense) public ipLicenses;
    mapping(address => bool) public members;
    mapping(address => bool) public governanceMembers;
    mapping(address => bool) public pendingMemberships;
    uint256 public membershipApprovalThreshold = 2; // Number of governance members needed to approve membership
    uint256 public proposalReviewThreshold = 2; // Number of governance members needed to approve a proposal
    uint256 public outputReviewThreshold = 2; // Number of governance members needed to approve an output
    uint256 public platformFeePercentage = 5; // Platform fee percentage (e.g., 5%)

    // --- EVENTS ---
    event MembershipRequested(address indexed member);
    event MembershipApproved(address indexed member, address indexed approvedBy);
    event MembershipRevoked(address indexed member, address indexed revokedBy);
    event GovernanceMemberAdded(address indexed member, address indexed addedBy);
    event GovernanceMemberRemoved(address indexed member, address indexed removedBy);
    event GovernanceThresholdChanged(uint256 newThreshold, address indexed changedBy);
    event ResearchProposalSubmitted(uint256 proposalId, address indexed proposer, string title);
    event ResearchProposalReviewed(uint256 proposalId, address indexed reviewer, bool approved, string comments);
    event ResearchProposalFunded(uint256 proposalId, address indexed funder, uint256 amount);
    event ResearchProposalFundsWithdrawn(uint256 proposalId, address indexed researcher, uint256 amount);
    event ResearchProposalInProgress(uint256 proposalId, address indexed researcher);
    event ResearchOutputSubmitted(uint256 outputId, uint256 proposalId, address indexed submitter);
    event ResearchOutputReviewed(uint256 outputId, address indexed reviewer, bool approved, string comments);
    event ResearchProposalFinalized(uint256 proposalId);
    event ResearchOutputNFTMinted(uint256 outputId, uint256 tokenId);
    event IPLicenseCreated(uint256 licenseId, uint256 outputId, address indexed licensee, uint256 licenseFee, uint256 licenseDurationDays);
    event IPLicenseRevoked(uint256 licenseId, address indexed revoker);
    event IPTransfered(uint256 outputId, address indexed oldOwner, address indexed newOwner);
    event PlatformFeePercentageChanged(uint256 newPercentage, address indexed changedBy);
    event PlatformFeesWithdrawn(uint256 amount, address indexed withdrawnBy);
    event ContractPaused(address indexed pausedBy);
    event ContractUnpaused(address indexed unpausedBy);

    // --- MODIFIERS ---
    modifier onlyMember() {
        require(members[msg.sender], "Not a DARO member");
        _;
    }

    modifier onlyGovernance() {
        require(governanceMembers[msg.sender], "Not a governance member");
        _;
    }

    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= _proposalIds.current(), "Proposal does not exist");
        _;
    }

    modifier outputExists(uint256 _outputId) {
        require(_outputId > 0 && _outputId <= _outputIds.current(), "Output does not exist");
        _;
    }

    modifier licenseExists(uint256 _licenseId) {
        require(_licenseId > 0 && _licenseId <= _licenseIds.current(), "License does not exist");
        _;
    }

    modifier proposalInStatus(uint256 _proposalId, ProposalStatus _status) {
        require(researchProposals[_proposalId].status == _status, "Proposal status is not as expected");
        _;
    }

    modifier outputInStatus(uint256 _outputId, OutputStatus _status) {
        require(researchOutputs[_outputId].status == _status, "Output status is not as expected");
        _;
    }

    modifier notReviewerYetProposal(uint256 _proposalId) {
        require(!researchProposals[_proposalId].reviewersApproved[msg.sender], "Already reviewed this proposal");
        _;
    }

    modifier notReviewerYetOutput(uint256 _outputId) {
        require(!researchOutputs[_outputId].reviewersApproved[msg.sender], "Already reviewed this output");
        _;
    }

    modifier sufficientFunding(uint256 _proposalId) {
        require(researchProposals[_proposalId].currentFunding >= researchProposals[_proposalId].fundingGoal, "Insufficient funding");
        _;
    }

    modifier isProposer(uint256 _proposalId) {
        require(researchProposals[_proposalId].proposer == msg.sender, "Not the proposer of this research");
        _;
    }


    // --- CONSTRUCTOR ---
    constructor() ERC721("DARO Research Output IP", "DROIP") {
        // The contract deployer is initially the owner and a governance member
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        governanceMembers[msg.sender] = true;
    }

    // --- I. MEMBERSHIP & GOVERNANCE ---

    /// @notice Allows anyone to request membership in the DARO.
    function requestMembership() external whenNotPaused {
        require(!members[msg.sender], "Already a member");
        require(!pendingMemberships[msg.sender], "Membership request already pending");
        pendingMemberships[msg.sender] = true;
        emit MembershipRequested(msg.sender);
    }

    /// @notice Governance members approve pending membership requests.
    /// @param _member The address of the member to approve.
    function approveMembership(address _member) external onlyGovernance whenNotPaused {
        require(pendingMemberships[_member], "No pending membership request from this address");
        require(!members[_member], "Address is already a member");
        members[_member] = true;
        delete pendingMemberships[_member];
        emit MembershipApproved(_member, msg.sender);
    }

    /// @notice Governance members can revoke membership.
    /// @param _member The address of the member to revoke.
    function revokeMembership(address _member) external onlyGovernance whenNotPaused {
        require(members[_member], "Not a member");
        require(!governanceMembers[_member], "Cannot revoke governance member this way. Remove governance role first."); // Prevent accidental governance removal
        delete members[_member];
        emit MembershipRevoked(_member, msg.sender);
    }

    /// @notice Checks if an address is a member of the DARO.
    /// @param _address The address to check.
    /// @return True if the address is a member, false otherwise.
    function isMember(address _address) external view returns (bool) {
        return members[_address];
    }

    /// @notice Sets the required approvals for governance actions.
    /// @param _threshold The new governance threshold.
    function setGovernanceThreshold(uint256 _threshold) external onlyGovernance onlyOwner whenNotPaused {
        require(_threshold > 0, "Threshold must be greater than zero");
        membershipApprovalThreshold = _threshold;
        proposalReviewThreshold = _threshold;
        outputReviewThreshold = _threshold;
        emit GovernanceThresholdChanged(_threshold, msg.sender);
    }

    /// @notice Adds a new address to the governance member list.
    /// @param _governanceMember The address to add as a governance member.
    function addGovernanceMember(address _governanceMember) external onlyOwner whenNotPaused {
        require(!governanceMembers[_governanceMember], "Address is already a governance member");
        governanceMembers[_governanceMember] = true;
        emit GovernanceMemberAdded(_governanceMember, msg.sender);
    }

    /// @notice Removes an address from the governance member list.
    /// @param _governanceMember The address to remove from governance.
    function removeGovernanceMember(address _governanceMember) external onlyOwner whenNotPaused {
        require(governanceMembers[_governanceMember], "Address is not a governance member");
        require(_governanceMember != owner(), "Cannot remove contract owner from governance this way."); // Prevent removing owner accidentally
        delete governanceMembers[_governanceMember];
        emit GovernanceMemberRemoved(_governanceMember, msg.sender);
    }

    /// @notice Checks if an address is a governance member.
    /// @param _address The address to check.
    /// @return True if the address is a governance member, false otherwise.
    function isGovernanceMember(address _address) external view returns (bool) {
        return governanceMembers[_address];
    }


    // --- II. RESEARCH PROPOSAL MANAGEMENT ---

    /// @notice Members submit research proposals.
    /// @param _title The title of the research proposal.
    /// @param _description A brief description of the research.
    /// @param _fundingGoal The funding goal in wei for the proposal.
    /// @param _ipfsHash IPFS hash pointing to a detailed proposal document.
    function submitResearchProposal(
        string memory _title,
        string memory _description,
        uint256 _fundingGoal,
        string memory _ipfsHash
    ) external onlyMember whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_title).length <= 200, "Title must be between 1 and 200 characters");
        require(bytes(_description).length > 0 && bytes(_description).length <= 1000, "Description must be between 1 and 1000 characters");
        require(_fundingGoal > 0, "Funding goal must be greater than zero");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        researchProposals[proposalId] = ResearchProposal({
            id: proposalId,
            proposer: msg.sender,
            title: _title,
            description: _description,
            fundingGoal: _fundingGoal,
            currentFunding: 0,
            ipfsHash: _ipfsHash,
            status: ProposalStatus.Pending,
            approvalCount: 0,
            reviewComments: new string[](0),
            outputId: 0,
            submissionTimestamp: block.timestamp,
            withdrawalTimestamp: 0,
            reviewersApproved: mapping(address => bool)()
        });

        emit ResearchProposalSubmitted(proposalId, msg.sender, _title);
    }

    /// @notice Governance members review and vote on research proposals.
    /// @param _proposalId The ID of the research proposal to review.
    /// @param _approve True to approve, false to reject.
    /// @param _reviewComments Comments for the review.
    function reviewResearchProposal(
        uint256 _proposalId,
        bool _approve,
        string memory _reviewComments
    ) external onlyGovernance proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Pending) notReviewerYetProposal(_proposalId) whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        proposal.reviewersApproved[msg.sender] = true;
        proposal.reviewComments.push(_reviewComments);

        if (_approve) {
            proposal.approvalCount++;
            if (proposal.approvalCount >= proposalReviewThreshold) {
                proposal.status = ProposalStatus.Approved;
            }
        } else {
            proposal.status = ProposalStatus.Rejected; // If any governance member rejects, proposal is rejected immediately
        }

        emit ResearchProposalReviewed(_proposalId, msg.sender, _approve, _reviewComments);
    }

    /// @notice Members can contribute funds to approved research proposals.
    /// @param _proposalId The ID of the research proposal to fund.
    function fundResearchProposal(uint256 _proposalId) external payable proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Approved) whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.currentFunding < proposal.fundingGoal, "Proposal funding goal already reached");

        uint256 fundingAmount = msg.value;
        uint256 platformFee = (fundingAmount * platformFeePercentage) / 100;
        uint256 netFunding = fundingAmount - platformFee;

        proposal.currentFunding += netFunding;
        payable(owner()).transfer(platformFee); // Send platform fee to contract owner

        if (proposal.currentFunding >= proposal.fundingGoal) {
            proposal.status = ProposalStatus.Funded;
        }

        emit ResearchProposalFunded(_proposalId, msg.sender, fundingAmount);
    }


    /// @notice Researchers (proposal submitters) can withdraw funded amount after proposal is approved and funded.
    /// @param _proposalId The ID of the research proposal.
    function withdrawProposalFunds(uint256 _proposalId) external proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Funded) isProposer(_proposalId) whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        require(proposal.withdrawalTimestamp == 0, "Funds already withdrawn");

        uint256 amountToWithdraw = proposal.currentFunding;
        proposal.currentFunding = 0; // Set funding to 0 after withdrawal to prevent double withdrawal
        proposal.withdrawalTimestamp = block.timestamp;

        (bool success, ) = payable(proposal.proposer).call{value: amountToWithdraw}("");
        require(success, "Withdrawal failed");

        emit ResearchProposalFundsWithdrawn(_proposalId, msg.sender, amountToWithdraw);
    }

    /// @notice Researchers mark a funded proposal as "in progress".
    /// @param _proposalId The ID of the research proposal.
    function markProposalInProgress(uint256 _proposalId) external proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.Funded) isProposer(_proposalId) whenNotPaused {
        researchProposals[_proposalId].status = ProposalStatus.InProgress;
        emit ResearchProposalInProgress(_proposalId, msg.sender);
    }

    /// @notice Researchers submit research outputs for completed proposals.
    /// @param _proposalId The ID of the research proposal this output belongs to.
    /// @param _outputDescription A description of the research output.
    /// @param _outputIpfsHash IPFS hash pointing to the research output document/data.
    function submitResearchOutput(
        uint256 _proposalId,
        string memory _outputDescription,
        string memory _outputIpfsHash
    ) external proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.InProgress) isProposer(_proposalId) whenNotPaused {
        require(bytes(_outputDescription).length > 0 && bytes(_outputDescription).length <= 1000, "Output description must be between 1 and 1000 characters");
        require(bytes(_outputIpfsHash).length > 0, "Output IPFS hash cannot be empty");

        _outputIds.increment();
        uint256 outputId = _outputIds.current();

        researchOutputs[outputId] = ResearchOutput({
            id: outputId,
            proposalId: _proposalId,
            submitter: msg.sender,
            description: _outputDescription,
            ipfsHash: _outputIpfsHash,
            status: OutputStatus.PendingReview,
            approvalCount: 0,
            reviewComments: new string[](0),
            submissionTimestamp: block.timestamp,
            reviewersApproved: mapping(address => bool)()
        });
        researchProposals[_proposalId].outputId = outputId; // Link output to proposal

        emit ResearchOutputSubmitted(outputId, _proposalId, msg.sender);
    }

    /// @notice Governance members review and approve submitted research outputs.
    /// @param _outputId The ID of the research output to review.
    /// @param _approve True to approve, false to reject.
    /// @param _reviewComments Comments for the review.
    function reviewResearchOutput(
        uint256 _outputId,
        bool _approve,
        string memory _reviewComments
    ) external onlyGovernance outputExists(_outputId) outputInStatus(_outputId, OutputStatus.PendingReview) notReviewerYetOutput(_outputId) whenNotPaused {
        ResearchOutput storage output = researchOutputs[_outputId];
        output.reviewersApproved[msg.sender] = true;
        output.reviewComments.push(_reviewComments);

        if (_approve) {
            output.approvalCount++;
            if (output.approvalCount >= outputReviewThreshold) {
                output.status = OutputStatus.Approved;
            }
        } else {
            output.status = OutputStatus.Rejected; // If any governance member rejects, output is rejected immediately
        }

        emit ResearchOutputReviewed(_outputId, msg.sender, _approve, _reviewComments);
    }

    /// @notice Finalizes a proposal after output approval, releasing remaining funds and marking it as completed.
    /// @param _proposalId The ID of the research proposal.
    function finalizeResearchProposal(uint256 _proposalId) external onlyGovernance proposalExists(_proposalId) proposalInStatus(_proposalId, ProposalStatus.InProgress) whenNotPaused {
        ResearchProposal storage proposal = researchProposals[_proposalId];
        ResearchOutput storage output = researchOutputs[proposal.outputId]; // Assuming outputId is set when output is submitted
        require(output.status == OutputStatus.Approved, "Research output must be approved before finalizing proposal");

        proposal.status = ProposalStatus.Completed;

        // Potentially release any remaining funds (if any logic for partial funding was implemented, else this might be redundant)
        if (proposal.currentFunding > 0) {
            (bool success, ) = payable(proposal.proposer).call{value: proposal.currentFunding}("");
            require(success, "Remaining funds release failed");
            proposal.currentFunding = 0; // Set to 0 after release
        }

        emit ResearchProposalFinalized(_proposalId);
    }

    /// @notice Retrieves detailed information about a research proposal.
    /// @param _proposalId The ID of the research proposal.
    /// @return ResearchProposal struct containing proposal details.
    function getProposalDetails(uint256 _proposalId) external view proposalExists(_proposalId) returns (ResearchProposal memory) {
        return researchProposals[_proposalId];
    }

    /// @notice Retrieves details of a submitted research output.
    /// @param _outputId The ID of the research output.
    /// @return ResearchOutput struct containing output details.
    function getOutputDetails(uint256 _outputId) external view outputExists(_outputId) returns (ResearchOutput memory) {
        return researchOutputs[_outputId];
    }


    // --- III. INTELLECTUAL PROPERTY (IP) & REWARDS ---

    /// @notice Mints an NFT representing the approved research output IP, owned by the DARO initially.
    /// @param _outputId The ID of the research output.
    function mintResearchOutputNFT(uint256 _outputId) external onlyGovernance outputExists(_outputId) outputInStatus(_outputId, OutputStatus.Approved) whenNotPaused {
        ResearchOutput storage output = researchOutputs[_outputId];
        uint256 tokenId = _outputId; // Using outputId as tokenId for simplicity, can be improved.
        _mint(address(this), tokenId); // DARO (contract) initially owns the NFT
        _setTokenURI(tokenId, output.ipfsHash); // Set metadata URI to output IPFS hash
        output.status = OutputStatus.Approved; // Ensure status is Approved (already checked in modifier)

        emit ResearchOutputNFTMinted(_outputId, tokenId);
    }

    /// @notice Allows the DARO to license the IP (represented by the NFT) to external entities.
    /// @param _outputId The ID of the research output (and NFT).
    /// @param _licensee The address of the licensee.
    /// @param _licenseFee The fee for the license in wei.
    /// @param _licenseDurationDays The duration of the license in days.
    function licenseResearchOutputIP(
        uint256 _outputId,
        address _licensee,
        uint256 _licenseFee,
        uint256 _licenseDurationDays
    ) external onlyGovernance outputExists(_outputId) outputInStatus(_outputId, OutputStatus.Approved) whenNotPaused {
        require(_licenseFee >= 0, "License fee cannot be negative");
        require(_licenseDurationDays > 0, "License duration must be positive");
        require(ownerOf(_outputId) == address(this), "DARO must own the NFT to license it"); // Check DARO owns NFT

        _licenseIds.increment();
        uint256 licenseId = _licenseIds.current();

        ipLicenses[licenseId] = IPLicense({
            id: licenseId,
            outputId: _outputId,
            licensee: _licensee,
            licenseFee: _licenseFee,
            licenseDurationDays: _licenseDurationDays,
            licenseStartTime: block.timestamp,
            isActive: true
        });

        emit IPLicenseCreated(licenseId, _outputId, _licensee, _licenseFee, _licenseDurationDays);
    }

    /// @notice Governance can revoke an IP license if terms are violated.
    /// @param _licenseId The ID of the license to revoke.
    function revokeIPLicense(uint256 _licenseId) external onlyGovernance licenseExists(_licenseId) whenNotPaused {
        IPLicense storage license = ipLicenses[_licenseId];
        require(license.isActive, "License is not active");
        license.isActive = false;
        emit IPLicenseRevoked(_licenseId, msg.sender);
    }

    /// @notice (Governance controlled) Potentially transfer IP ownership in exceptional cases.
    /// @param _outputId The ID of the research output (and NFT).
    /// @param _newOwner The address of the new owner.
    function transferIPOwnership(uint256 _outputId, address _newOwner) external onlyGovernance outputExists(_outputId) outputInStatus(_outputId, OutputStatus.Approved) whenNotPaused {
        require(_newOwner != address(0), "Invalid new owner address");
        require(ownerOf(_outputId) == address(this), "DARO must own the NFT to transfer it"); // Check DARO owns NFT

        _transfer(address(this), _newOwner, _outputId); // Transfer NFT ownership
        emit IPTransfered(_outputId, address(this), _newOwner);
    }

    // --- IV. UTILITY & SECURITY ---

    /// @notice Allows contract owner to pause core functionalities in case of emergency.
    function pauseContract() external onlyOwner whenNotPaused {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Allows contract owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Sets a platform fee (percentage) on funded proposals (for DARO sustainability).
    /// @param _feePercentage The new platform fee percentage.
    function setPlatformFee(uint256 _feePercentage) external onlyOwner whenNotPaused {
        require(_feePercentage <= 100, "Platform fee percentage cannot exceed 100%");
        platformFeePercentage = _feePercentage;
        emit PlatformFeePercentageChanged(_feePercentage, msg.sender);
    }

    /// @notice Allows governance to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyGovernance onlyOwner whenNotPaused {
        uint256 contractBalance = address(this).balance;
        uint256 withdrawableFees = contractBalance; // Assuming all contract balance is platform fees for simplicity in this example. In a real-world scenario, more sophisticated tracking might be needed.
        require(withdrawableFees > 0, "No platform fees to withdraw");

        (bool success, ) = payable(owner()).call{value: withdrawableFees}("");
        require(success, "Platform fees withdrawal failed");

        emit PlatformFeesWithdrawn(withdrawableFees, msg.sender);
    }

    /// @notice Returns the contract's current ETH balance.
    /// @return The contract's ETH balance in wei.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // --- OVERRIDES for ERC721 ---
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return super.tokenURI(tokenId);
    }

    // Fallback function to receive Ether for funding proposals
    receive() external payable {}
}
```