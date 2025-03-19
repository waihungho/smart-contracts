```solidity
pragma solidity ^0.8.0;

/**
 * @title Decentralized Creative Commons - Advanced Licensing and Collaborative Platform
 * @author Bard (AI Assistant)
 * @dev This contract implements a decentralized platform for creative content management,
 * licensing, collaboration, and community governance, inspired by Creative Commons principles
 * but with advanced on-chain features and functionalities beyond basic open-source examples.
 *
 * **Outline and Function Summary:**
 *
 * **Core Work Management:**
 * 1. `registerWork(string memory _workHash, string memory _metadataURI)`: Allows creators to register their creative work with metadata.
 * 2. `updateWorkMetadata(uint256 _workId, string memory _metadataURI)`: Updates the metadata URI of a registered work.
 * 3. `setWorkLicense(uint256 _workId, LicenseType _licenseType)`: Sets the license type for a registered work.
 * 4. `getWorkDetails(uint256 _workId)`: Retrieves detailed information about a registered work.
 * 5. `transferWorkOwnership(uint256 _workId, address _newOwner)`: Transfers ownership of a registered work to another address.
 * 6. `reportInfringement(uint256 _workId, string memory _reportDetails)`: Allows users to report potential copyright infringements.
 *
 * **Advanced Licensing Features:**
 * 7. `createLicenseTemplate(string memory _templateName, LicenseTerms[] memory _terms)`: Allows platform admins to create reusable license templates.
 * 8. `applyLicenseTemplate(uint256 _workId, uint256 _templateId)`: Applies a predefined license template to a work.
 * 9. `customizeLicense(uint256 _workId, LicenseTerms[] memory _customTerms)`: Allows creators to define custom license terms for their work.
 * 10. `getLicenseDetails(uint256 _workId)`: Retrieves the current license details for a work.
 * 11. `verifyLicense(uint256 _workId, LicenseType _usageLicenseType)`: Checks if a specific usage license is compatible with the work's license.
 * 12. `revokeLicense(uint256 _workId)`: Revokes the current license of a work, reverting to default or requiring a new license.
 *
 * **Collaborative Creation & Revenue Sharing:**
 * 13. `addCollaborator(uint256 _workId, address _collaborator, uint256 _sharePercentage)`: Adds a collaborator to a work with a specified revenue share percentage.
 * 14. `removeCollaborator(uint256 _workId, address _collaborator)`: Removes a collaborator from a work.
 * 15. `updateCollaboratorShare(uint256 _workId, address _collaborator, uint256 _newSharePercentage)`: Updates the revenue share percentage for a collaborator.
 * 16. `distributeRevenue(uint256 _workId, uint256 _revenueAmount)`: Distributes revenue to the owner and collaborators based on their shares.
 *
 * **Community & Governance Features:**
 * 17. `supportCreator(uint256 _workId)`: Allows users to send support funds (ETH) to the creator of a work.
 * 18. `proposeGovernanceChange(string memory _proposalDescription)`: Allows community members to propose changes to platform parameters or features.
 * 19. `voteOnProposal(uint256 _proposalId, bool _vote)`: Allows community members to vote on governance proposals.
 * 20. `executeGovernanceChange(uint256 _proposalId)`: Executes a governance proposal if it passes a voting threshold.
 *
 * **Platform Administration:**
 * 21. `setPlatformFee(uint256 _feePercentage)`: Allows platform admin to set a platform fee percentage on revenue distribution.
 * 22. `withdrawPlatformFees()`: Allows platform admin to withdraw accumulated platform fees.
 * 23. `pauseContract()`: Allows platform admin to pause the contract for maintenance or emergency.
 * 24. `unpauseContract()`: Allows platform admin to unpause the contract.
 */

contract DecentralizedCreativeCommons {
    // --- Data Structures ---

    enum LicenseType {
        NONE,           // No license specified
        CC_BY,          // Attribution
        CC_BY_SA,       // Attribution-ShareAlike
        CC_BY_ND,       // Attribution-NoDerivatives
        CC_BY_NC,       // Attribution-NonCommercial
        CC_BY_NC_SA,    // Attribution-NonCommercial-ShareAlike
        CC_BY_NC_ND,    // Attribution-NonCommercial-NoDerivatives
        CUSTOM          // Custom license defined by creator
    }

    struct LicenseTerms {
        string termName;
        string termDescription;
        bool isAllowed;
    }

    struct LicenseTemplate {
        string templateName;
        LicenseTerms[] terms;
    }

    struct Work {
        uint256 id;
        address owner;
        string workHash;        // IPFS hash or similar identifier of the work
        string metadataURI;     // URI pointing to detailed metadata (JSON, etc.)
        LicenseType licenseType;
        LicenseTerms[] customLicenseTerms;
        uint256 registrationTimestamp;
        address[] collaborators;
        mapping(address => uint256) collaboratorShares; // Address to share percentage (out of 100)
        bool isActive;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    // --- State Variables ---

    address public platformAdmin;
    uint256 public platformFeePercentage; // Percentage of revenue taken as platform fee (out of 10000, e.g., 100 = 1%)
    uint256 public workCounter;
    uint256 public proposalCounter;
    bool public paused;

    mapping(uint256 => Work) public works;
    mapping(uint256 => LicenseTemplate) public licenseTemplates;
    mapping(uint256 => GovernanceProposal) public governanceProposals;
    mapping(uint256 => bool) public proposalVotes; // proposalId => voter => vote (true=yes, false=no)

    uint256 public constant VOTING_DURATION = 7 days; // Example voting duration
    uint256 public constant VOTING_THRESHOLD_PERCENTAGE = 60; // Example threshold for proposal to pass (60%)

    // --- Events ---

    event WorkRegistered(uint256 workId, address owner, string workHash, string metadataURI);
    event WorkMetadataUpdated(uint256 workId, string metadataURI);
    event LicenseSet(uint256 workId, LicenseType licenseType);
    event WorkOwnershipTransferred(uint256 workId, address oldOwner, address newOwner);
    event InfringementReported(uint256 workId, address reporter, string reportDetails);
    event LicenseTemplateCreated(uint256 templateId, string templateName);
    event LicenseTemplateApplied(uint256 workId, uint256 templateId);
    event CustomLicenseSet(uint256 workId);
    event LicenseRevoked(uint256 workId);
    event CollaboratorAdded(uint256 workId, address collaborator, uint256 sharePercentage);
    event CollaboratorRemoved(uint256 workId, address collaborator);
    event CollaboratorShareUpdated(uint256 workId, address collaborator, uint256 newSharePercentage);
    event RevenueDistributed(uint256 workId, uint256 revenueAmount);
    event CreatorSupported(uint256 workId, address supporter, uint256 amount);
    event GovernanceProposalCreated(uint256 proposalId, address proposer, string description);
    event GovernanceProposalVoted(uint256 proposalId, address voter, bool vote);
    event GovernanceProposalExecuted(uint256 proposalId);
    event PlatformFeeSet(uint256 feePercentage);
    event PlatformFeesWithdrawn(uint256 amount);
    event ContractPaused();
    event ContractUnpaused();


    // --- Modifiers ---

    modifier onlyOwner(uint256 _workId) {
        require(works[_workId].owner == msg.sender, "You are not the owner of this work.");
        _;
    }

    modifier onlyPlatformAdmin() {
        require(msg.sender == platformAdmin, "Only platform admin can perform this action.");
        _;
    }

    modifier workExists(uint256 _workId) {
        require(works[_workId].isActive, "Work does not exist or is inactive.");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    // --- Constructor ---

    constructor(uint256 _initialPlatformFeePercentage) {
        platformAdmin = msg.sender;
        platformFeePercentage = _initialPlatformFeePercentage;
        workCounter = 0;
        proposalCounter = 0;
        paused = false;
    }

    // --- Core Work Management Functions ---

    /// @notice Registers a new creative work on the platform.
    /// @param _workHash The hash of the creative work (e.g., IPFS hash).
    /// @param _metadataURI URI pointing to the metadata of the work (e.g., JSON file).
    function registerWork(string memory _workHash, string memory _metadataURI) external notPaused returns (uint256 workId) {
        workId = workCounter++;
        works[workId] = Work({
            id: workId,
            owner: msg.sender,
            workHash: _workHash,
            metadataURI: _metadataURI,
            licenseType: LicenseType.NONE, // Default license is NONE until set
            customLicenseTerms: new LicenseTerms[](0),
            registrationTimestamp: block.timestamp,
            collaborators: new address[](0),
            isActive: true
        });
        emit WorkRegistered(workId, msg.sender, _workHash, _metadataURI);
        return workId;
    }

    /// @notice Updates the metadata URI of an existing registered work.
    /// @param _workId The ID of the work to update.
    /// @param _metadataURI The new metadata URI.
    function updateWorkMetadata(uint256 _workId, string memory _metadataURI) external onlyOwner(_workId) notPaused workExists(_workId) {
        works[_workId].metadataURI = _metadataURI;
        emit WorkMetadataUpdated(_workId, _metadataURI);
    }

    /// @notice Sets the license type for a registered work using predefined LicenseType enum.
    /// @param _workId The ID of the work to set the license for.
    /// @param _licenseType The LicenseType enum value to set.
    function setWorkLicense(uint256 _workId, LicenseType _licenseType) external onlyOwner(_workId) notPaused workExists(_workId) {
        works[_workId].licenseType = _licenseType;
        delete works[_workId].customLicenseTerms; // Clear custom terms if switching to enum type
        emit LicenseSet(_workId, _licenseType);
    }

    /// @notice Retrieves detailed information about a registered work.
    /// @param _workId The ID of the work to query.
    /// @return Work struct containing work details.
    function getWorkDetails(uint256 _workId) external view workExists(_workId) returns (Work memory) {
        return works[_workId];
    }

    /// @notice Transfers ownership of a registered work to a new address.
    /// @param _workId The ID of the work to transfer.
    /// @param _newOwner The address of the new owner.
    function transferWorkOwnership(uint256 _workId, address _newOwner) external onlyOwner(_workId) notPaused workExists(_workId) {
        address oldOwner = works[_workId].owner;
        works[_workId].owner = _newOwner;
        emit WorkOwnershipTransferred(_workId, oldOwner, _newOwner);
    }

    /// @notice Allows users to report potential copyright infringement for a work.
    /// @param _workId The ID of the work being reported.
    /// @param _reportDetails Details of the infringement report.
    function reportInfringement(uint256 _workId, string memory _reportDetails) external notPaused workExists(_workId) {
        emit InfringementReported(_workId, msg.sender, _reportDetails);
        // In a real application, this would trigger an off-chain process for review.
    }

    // --- Advanced Licensing Features ---

    /// @notice Allows platform admins to create reusable license templates.
    /// @param _templateName Name of the license template.
    /// @param _terms Array of LicenseTerms defining the template.
    function createLicenseTemplate(string memory _templateName, LicenseTerms[] memory _terms) external onlyPlatformAdmin notPaused {
        uint256 templateId = licenseTemplates.length; // Simple incrementing ID
        licenseTemplates[templateId] = LicenseTemplate({
            templateName: _templateName,
            terms: _terms
        });
        emit LicenseTemplateCreated(templateId, _templateName);
    }

    /// @notice Applies a predefined license template to a work.
    /// @param _workId The ID of the work to apply the template to.
    /// @param _templateId The ID of the license template to apply.
    function applyLicenseTemplate(uint256 _workId, uint256 _templateId) external onlyOwner(_workId) notPaused workExists(_workId) {
        require(_templateId < licenseTemplates.length, "Invalid template ID.");
        works[_workId].licenseType = LicenseType.CUSTOM; // Set license type to custom when using template
        works[_workId].customLicenseTerms = licenseTemplates[_templateId].terms;
        emit LicenseTemplateApplied(_workId, _templateId);
    }

    /// @notice Allows creators to define custom license terms for their work.
    /// @param _workId The ID of the work to customize the license for.
    /// @param _customTerms Array of LicenseTerms defining the custom license.
    function customizeLicense(uint256 _workId, LicenseTerms[] memory _customTerms) external onlyOwner(_workId) notPaused workExists(_workId) {
        works[_workId].licenseType = LicenseType.CUSTOM;
        works[_workId].customLicenseTerms = _customTerms;
        emit CustomLicenseSet(_workId);
    }

    /// @notice Retrieves the current license details for a work, including type and terms.
    /// @param _workId The ID of the work to query.
    /// @return LicenseType The license type of the work.
    /// @return LicenseTerms[] Array of custom license terms if LicenseType is CUSTOM.
    function getLicenseDetails(uint256 _workId) external view workExists(_workId) returns (LicenseType, LicenseTerms[] memory) {
        return (works[_workId].licenseType, works[_workId].customLicenseTerms);
    }

    /// @notice Verifies if a specific usage license type is compatible with the work's license.
    /// @param _workId The ID of the work to check the license against.
    /// @param _usageLicenseType The LicenseType for intended usage.
    /// @return bool True if the usage license is compatible, false otherwise.
    function verifyLicense(uint256 _workId, LicenseType _usageLicenseType) external view workExists(_workId) returns (bool) {
        LicenseType workLicenseType = works[_workId].licenseType;

        if (workLicenseType == LicenseType.NONE) {
            return false; // No license, no usage allowed (or needs explicit permission)
        }

        if (workLicenseType == _usageLicenseType) {
            return true; // Exact license match
        }

        // Basic example logic - can be expanded for more complex compatibility checks
        if (workLicenseType == LicenseType.CC_BY && (_usageLicenseType == LicenseType.CC_BY || _usageLicenseType == LicenseType.CC_BY_SA || _usageLicenseType == LicenseType.CC_BY_ND || _usageLicenseType == LicenseType.CC_BY_NC || _usageLicenseType == LicenseType.CC_BY_NC_SA || _usageLicenseType == LicenseType.CC_BY_NC_ND)) {
            return true; // CC-BY is generally permissive
        }

        // Add more complex logic based on LicenseType and custom terms if needed

        return false; // Default to false if not explicitly allowed
    }


    /// @notice Revokes the current license of a work, reverting to LicenseType.NONE.
    /// @param _workId The ID of the work to revoke the license for.
    function revokeLicense(uint256 _workId) external onlyOwner(_workId) notPaused workExists(_workId) {
        works[_workId].licenseType = LicenseType.NONE;
        delete works[_workId].customLicenseTerms;
        emit LicenseRevoked(_workId);
    }


    // --- Collaborative Creation & Revenue Sharing ---

    /// @notice Adds a collaborator to a work with a specified revenue share percentage.
    /// @param _workId The ID of the work to add a collaborator to.
    /// @param _collaborator The address of the collaborator to add.
    /// @param _sharePercentage The revenue share percentage for the collaborator (out of 100).
    function addCollaborator(uint256 _workId, address _collaborator, uint256 _sharePercentage) external onlyOwner(_workId) notPaused workExists(_workId) {
        require(_sharePercentage <= 100, "Share percentage must be between 0 and 100.");
        require(works[_workId].collaboratorShares[_collaborator] == 0, "Collaborator already added."); // Prevent duplicate collaborators

        works[_workId].collaborators.push(_collaborator);
        works[_workId].collaboratorShares[_collaborator] = _sharePercentage;
        emit CollaboratorAdded(_workId, _collaborator, _sharePercentage);
    }

    /// @notice Removes a collaborator from a work.
    /// @param _workId The ID of the work to remove a collaborator from.
    /// @param _collaborator The address of the collaborator to remove.
    function removeCollaborator(uint256 _workId, address _collaborator) external onlyOwner(_workId) notPaused workExists(_workId) {
        require(works[_workId].collaboratorShares[_collaborator] > 0, "Collaborator not found.");

        // Efficiently remove from array (order doesn't matter)
        for (uint256 i = 0; i < works[_workId].collaborators.length; i++) {
            if (works[_workId].collaborators[i] == _collaborator) {
                works[_workId].collaborators[i] = works[_workId].collaborators[works[_workId].collaborators.length - 1];
                works[_workId].collaborators.pop();
                break;
            }
        }
        delete works[_workId].collaboratorShares[_collaborator];
        emit CollaboratorRemoved(_workId, _collaborator);
    }

    /// @notice Updates the revenue share percentage for an existing collaborator.
    /// @param _workId The ID of the work to update the collaborator share for.
    /// @param _collaborator The address of the collaborator to update.
    /// @param _newSharePercentage The new revenue share percentage (out of 100).
    function updateCollaboratorShare(uint256 _workId, address _collaborator, uint256 _newSharePercentage) external onlyOwner(_workId) notPaused workExists(_workId) {
        require(_newSharePercentage <= 100, "Share percentage must be between 0 and 100.");
        require(works[_workId].collaboratorShares[_collaborator] > 0, "Collaborator not found.");

        works[_workId].collaboratorShares[_collaborator] = _newSharePercentage;
        emit CollaboratorShareUpdated(_workId, _collaborator, _newSharePercentage);
    }

    /// @notice Distributes revenue (ETH) for a work to the owner and collaborators based on their shares.
    /// @param _workId The ID of the work for which to distribute revenue.
    /// @param _revenueAmount The total revenue amount in wei to distribute.
    function distributeRevenue(uint256 _workId, uint256 _revenueAmount) external onlyOwner(_workId) payable notPaused workExists(_workId) {
        require(msg.value == _revenueAmount, "Incorrect amount sent for revenue distribution.");

        uint256 totalShares = 100; // Owner implicitly has the remaining share if no collaborators

        // Calculate platform fee
        uint256 platformFee = (_revenueAmount * platformFeePercentage) / 10000;
        uint256 revenueAfterFee = _revenueAmount - platformFee;

        // Distribute to owner
        uint256 ownerShare = 100; // Default owner share if no collaborators
        if (works[_workId].collaborators.length > 0) {
            ownerShare = 100; // Initialize to 100, then subtract collaborator shares
            for (uint256 i = 0; i < works[_workId].collaborators.length; i++) {
                ownerShare -= works[_workId].collaboratorShares[works[_workId].collaborators[i]];
            }
            require(ownerShare >= 0, "Collaborator shares exceed 100%."); // Sanity check
            totalShares = 100; // Total shares is still 100%
        }

        uint256 ownerRevenue = (revenueAfterFee * ownerShare) / totalShares;
        payable(works[_workId].owner).transfer(ownerRevenue);

        // Distribute to collaborators
        for (uint256 i = 0; i < works[_workId].collaborators.length; i++) {
            address collaborator = works[_workId].collaborators[i];
            uint256 collaboratorShare = works[_workId].collaboratorShares[collaborator];
            uint256 collaboratorRevenue = (revenueAfterFee * collaboratorShare) / totalShares;
            payable(collaborator).transfer(collaboratorRevenue);
        }

        // Transfer platform fees to platform admin
        if (platformFee > 0) {
            payable(platformAdmin).transfer(platformFee);
            emit PlatformFeesWithdrawn(platformFee); // Potentially rename event for clarity
        }


        emit RevenueDistributed(_workId, _revenueAmount);
    }


    // --- Community & Governance Features ---

    /// @notice Allows users to send support funds (ETH) to the creator of a work.
    /// @param _workId The ID of the work to support.
    function supportCreator(uint256 _workId) external payable notPaused workExists(_workId) {
        require(msg.value > 0, "Support amount must be greater than zero.");
        payable(works[_workId].owner).transfer(msg.value);
        emit CreatorSupported(_workId, msg.sender, msg.value);
    }

    /// @notice Allows community members to propose changes to platform parameters or features.
    /// @param _proposalDescription Description of the governance proposal.
    function proposeGovernanceChange(string memory _proposalDescription) external notPaused {
        uint256 proposalId = proposalCounter++;
        governanceProposals[proposalId] = GovernanceProposal({
            id: proposalId,
            proposer: msg.sender,
            description: _proposalDescription,
            startTime: block.timestamp,
            endTime: block.timestamp + VOTING_DURATION,
            yesVotes: 0,
            noVotes: 0,
            executed: false
        });
        emit GovernanceProposalCreated(proposalId, msg.sender, _proposalDescription);
    }

    /// @notice Allows community members to vote on governance proposals.
    /// @param _proposalId The ID of the proposal to vote on.
    /// @param _vote True for yes vote, false for no vote.
    function voteOnProposal(uint256 _proposalId, bool _vote) external notPaused {
        require(governanceProposals[_proposalId].startTime > 0, "Proposal does not exist.");
        require(block.timestamp >= governanceProposals[_proposalId].startTime && block.timestamp <= governanceProposals[_proposalId].endTime, "Voting period expired.");
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted on this proposal.");

        proposalVotes[_proposalId][msg.sender] = true; // Record vote
        if (_vote) {
            governanceProposals[_proposalId].yesVotes++;
        } else {
            governanceProposals[_proposalId].noVotes++;
        }
        emit GovernanceProposalVoted(_proposalId, msg.sender, _vote);
    }

    /// @notice Executes a governance proposal if it passes the voting threshold.
    /// @param _proposalId The ID of the proposal to execute.
    function executeGovernanceChange(uint256 _proposalId) external onlyPlatformAdmin notPaused {
        require(governanceProposals[_proposalId].startTime > 0, "Proposal does not exist.");
        require(block.timestamp > governanceProposals[_proposalId].endTime, "Voting period not yet expired.");
        require(!governanceProposals[_proposalId].executed, "Proposal already executed.");

        uint256 totalVotes = governanceProposals[_proposalId].yesVotes + governanceProposals[_proposalId].noVotes;
        uint256 yesPercentage = (governanceProposals[_proposalId].yesVotes * 100) / totalVotes; // Avoid division by zero if no votes

        if (yesPercentage >= VOTING_THRESHOLD_PERCENTAGE) {
            governanceProposals[_proposalId].executed = true;
            emit GovernanceProposalExecuted(_proposalId);
            // Implement the actual governance change logic here based on proposal details.
            // Example: if proposal is to change platform fee:
            // if (keccak256(abi.encodePacked(governanceProposals[_proposalId].description)) == keccak256(abi.encodePacked("Change platform fee to X%"))) {
            //     // Parse X from description and update platformFeePercentage
            //     // ...
            // }
            //  This is a simplified example, real implementation needs robust proposal parsing and execution logic.
        } else {
            revert("Governance proposal failed to reach voting threshold.");
        }
    }


    // --- Platform Administration Functions ---

    /// @notice Sets the platform fee percentage for revenue distribution.
    /// @param _feePercentage The new platform fee percentage (out of 10000, e.g., 100 = 1%).
    function setPlatformFee(uint256 _feePercentage) external onlyPlatformAdmin notPaused {
        require(_feePercentage <= 10000, "Platform fee percentage cannot exceed 100%.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Allows the platform admin to withdraw accumulated platform fees.
    function withdrawPlatformFees() external onlyPlatformAdmin notPaused {
        uint256 balance = address(this).balance;
        payable(platformAdmin).transfer(balance);
        emit PlatformFeesWithdrawn(balance);
    }

    /// @notice Pauses the contract, preventing most functions from being executed.
    function pauseContract() external onlyPlatformAdmin notPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing normal functions to be executed again.
    function unpauseContract() external onlyPlatformAdmin {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Fallback and Receive Functions (Optional - for receiving ETH) ---

    receive() external payable {} // Allow contract to receive ETH directly for revenue distribution purposes.
    fallback() external payable {}
}
```