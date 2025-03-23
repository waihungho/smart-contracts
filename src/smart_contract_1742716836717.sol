```solidity
/**
 * @title Decentralized Creative Commons License Manager
 * @author Bard (AI Assistant)
 * @dev Smart Contract for managing Creative Commons-like licenses for digital assets.
 * This contract allows creators to register their works, define custom licenses or use predefined templates,
 * and manage permissions related to their creations in a decentralized manner.
 *
 * Function Summary:
 * 1. createLicenseTemplate:  Admin function to add predefined license templates (e.g., CC-BY-SA).
 * 2. removeLicenseTemplate: Admin function to remove predefined license templates.
 * 3. getLicenseTemplate:  View function to retrieve details of a license template by ID.
 * 4. listLicenseTemplates: View function to get a list of available license templates.
 * 5. createCustomLicense: Creator function to create a fully custom license with specific terms.
 * 6. registerWork: Creator function to register a digital work with metadata and IPFS hash.
 * 7. applyLicenseTemplateToWork: Creator function to apply a predefined license template to a registered work.
 * 8. applyCustomLicenseToWork: Creator function to apply a custom license to a registered work.
 * 9. getWorkLicenseDetails: View function to retrieve the license details applied to a specific work.
 * 10. getWorkMetadata: View function to retrieve the metadata of a registered work.
 * 11. verifyLicenseCompliance: View function to check if a specific action is permitted under a work's license.
 * 12. updateWorkMetadata: Creator function to update the metadata of a registered work.
 * 13. transferWorkOwnership: Creator function to transfer ownership of a registered work to another address.
 * 14. reportLicenseViolation: User function to report a potential license violation for a work.
 * 15. getWorkViolationReports: Admin/Creator function to view violation reports for a work.
 * 16. resolveViolationReport: Admin function to resolve a reported license violation.
 * 17. setLicenseTerm: Creator/Admin function to set specific terms within a license (e.g., allowed regions).
 * 18. getLicenseTerm: View function to retrieve a specific term of a license.
 * 19. revokeLicense: Creator function to revoke a license for a work (with limitations/conditions).
 * 20. extendLicense: Creator function to extend the duration of a time-limited license.
 * 21. listWorksByCreator: View function to list all works registered by a specific creator.
 * 22. searchWorksByKeyword: View function to search for works based on keywords in their metadata.
 * 23. getTotalRegisteredWorks: View function to get the total number of registered works in the contract.
 * 24. setContractAdmin: Admin function to change the contract administrator.
 */
pragma solidity ^0.8.0;

contract CreativeCommonsLicenseManager {

    // -------- Outline & Function Summary (Already Provided Above) --------

    // -------- State Variables --------

    address public admin; // Contract administrator
    uint256 public licenseTemplateCount;
    uint256 public workCount;

    struct LicenseTemplate {
        string name;
        string description;
        string permissions; // Representing permissions like "Attribution, NonCommercial, ShareAlike"
        bool exists;
    }

    struct CustomLicense {
        string name;
        string description;
        string terms; // Detailed custom terms of the license
        bool exists;
    }

    struct Work {
        address creator;
        string title;
        string description;
        string ipfsHash; // IPFS hash of the digital asset
        uint256 registrationTimestamp;
        uint256 licenseType; // 0: Template License, 1: Custom License, 2: No License
        uint256 licenseId;   // ID of the applied license (template or custom)
        bool exists;
    }

    struct ViolationReport {
        address reporter;
        uint256 workId;
        string description;
        uint256 reportTimestamp;
        bool resolved;
    }

    mapping(uint256 => LicenseTemplate) public licenseTemplates; // Template ID => LicenseTemplate
    mapping(uint256 => CustomLicense) public customLicenses; // Custom License ID => CustomLicense
    mapping(uint256 => Work) public works; // Work ID => Work
    mapping(uint256 => ViolationReport[]) public workViolationReports; // Work ID => Array of Violation Reports
    mapping(address => uint256[]) public creatorWorks; // Creator Address => Array of Work IDs

    // -------- Events --------

    event LicenseTemplateCreated(uint256 templateId, string name);
    event LicenseTemplateRemoved(uint256 templateId);
    event CustomLicenseCreated(uint256 licenseId, address creator, string name);
    event WorkRegistered(uint256 workId, address creator, string title);
    event LicenseTemplateApplied(uint256 workId, uint256 templateId);
    event CustomLicenseApplied(uint256 workId, uint256 licenseId);
    event WorkMetadataUpdated(uint256 workId);
    event WorkOwnershipTransferred(uint256 workId, address from, address to);
    event LicenseViolationReported(uint256 reportId, uint256 workId, address reporter);
    event LicenseViolationResolved(uint256 reportId, uint256 workId, address admin);
    event LicenseRevoked(uint256 workId);
    event LicenseExtended(uint256 workId, uint256 newDuration); // Example for time-limited licenses


    // -------- Modifiers --------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyCreator(uint256 _workId) {
        require(works[_workId].creator == msg.sender, "Only creator can perform this action.");
        _;
    }

    modifier workExists(uint256 _workId) {
        require(works[_workId].exists, "Work does not exist.");
        _;
    }

    modifier licenseTemplateExists(uint256 _templateId) {
        require(licenseTemplates[_templateId].exists, "License template does not exist.");
        _;
    }

    modifier customLicenseExists(uint256 _customLicenseId) {
        require(customLicenses[_customLicenseId].exists, "Custom license does not exist.");
        _;
    }


    // -------- Constructor --------

    constructor() {
        admin = msg.sender;
        licenseTemplateCount = 0;
        workCount = 0;
    }

    // -------- 1. Admin Functions: License Template Management --------

    function createLicenseTemplate(string memory _name, string memory _description, string memory _permissions) public onlyAdmin {
        licenseTemplateCount++;
        licenseTemplates[licenseTemplateCount] = LicenseTemplate({
            name: _name,
            description: _description,
            permissions: _permissions,
            exists: true
        });
        emit LicenseTemplateCreated(licenseTemplateCount, _name);
    }

    function removeLicenseTemplate(uint256 _templateId) public onlyAdmin licenseTemplateExists(_templateId) {
        delete licenseTemplates[_templateId];
        emit LicenseTemplateRemoved(_templateId);
    }

    function getLicenseTemplate(uint256 _templateId) public view licenseTemplateExists(_templateId) returns (string memory name, string memory description, string memory permissions) {
        LicenseTemplate storage template = licenseTemplates[_templateId];
        return (template.name, template.description, template.permissions);
    }

    function listLicenseTemplates() public view returns (uint256[] memory templateIds) {
        uint256[] memory ids = new uint256[](licenseTemplateCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= licenseTemplateCount; i++) {
            if (licenseTemplates[i].exists) {
                ids[index] = i;
                index++;
            }
        }
        // Resize array to remove empty slots if templates were deleted
        assembly {
            mstore(ids, index) // Adjust the length of the array
        }
        return ids;
    }

    // -------- 2. Creator Functions: License & Work Management --------

    function createCustomLicense(string memory _name, string memory _description, string memory _terms) public returns (uint256 licenseId) {
        licenseId = ++licenseTemplateCount; // Reuse template counter for simplicity, can be separate
        customLicenses[licenseId] = CustomLicense({
            name: _name,
            description: _description,
            terms: _terms,
            exists: true
        });
        emit CustomLicenseCreated(licenseId, msg.sender, _name);
        return licenseId;
    }

    function registerWork(string memory _title, string memory _description, string memory _ipfsHash) public returns (uint256 workId) {
        workId = ++workCount;
        works[workId] = Work({
            creator: msg.sender,
            title: _title,
            description: _description,
            ipfsHash: _ipfsHash,
            registrationTimestamp: block.timestamp,
            licenseType: 2, // Initially no license applied
            licenseId: 0,
            exists: true
        });
        creatorWorks[msg.sender].push(workId);
        emit WorkRegistered(workId, msg.sender, _title);
        return workId;
    }

    function applyLicenseTemplateToWork(uint256 _workId, uint256 _templateId) public onlyCreator(_workId) workExists(_workId) licenseTemplateExists(_templateId) {
        works[_workId].licenseType = 0; // Template License
        works[_workId].licenseId = _templateId;
        emit LicenseTemplateApplied(_workId, _templateId);
    }

    function applyCustomLicenseToWork(uint256 _workId, uint256 _customLicenseId) public onlyCreator(_workId) workExists(_workId) customLicenseExists(_customLicenseId) {
        works[_workId].licenseType = 1; // Custom License
        works[_workId].licenseId = _customLicenseId;
        emit CustomLicenseApplied(_workId, _customLicenseId);
    }

    function updateWorkMetadata(uint256 _workId, string memory _title, string memory _description, string memory _ipfsHash) public onlyCreator(_workId) workExists(_workId) {
        works[_workId].title = _title;
        works[_workId].description = _description;
        works[_workId].ipfsHash = _ipfsHash;
        emit WorkMetadataUpdated(_workId);
    }

    function transferWorkOwnership(uint256 _workId, address _newOwner) public onlyCreator(_workId) workExists(_workId) {
        address oldOwner = works[_workId].creator;
        works[_workId].creator = _newOwner;

        // Update creatorWorks mapping: remove from old owner, add to new owner (simplified, could be optimized)
        uint256[] storage oldOwnerWorks = creatorWorks[oldOwner];
        for (uint256 i = 0; i < oldOwnerWorks.length; i++) {
            if (oldOwnerWorks[i] == _workId) {
                oldOwnerWorks[i] = oldOwnerWorks[oldOwnerWorks.length - 1]; // Replace with last element
                oldOwnerWorks.pop(); // Remove last element (effectively removing the workId)
                break;
            }
        }
        creatorWorks[_newOwner].push(_workId);

        emit WorkOwnershipTransferred(_workId, oldOwner, _newOwner);
    }

    function revokeLicense(uint256 _workId) public onlyCreator(_workId) workExists(_workId) {
        works[_workId].licenseType = 2; // No License
        works[_workId].licenseId = 0; // Reset license ID
        emit LicenseRevoked(_workId);
        // In a real system, consider adding conditions for revocation and potential consequences.
    }

    // Example - Time limited license extension (more complex license terms can be added)
    function extendLicense(uint256 _workId, uint256 _extensionDurationInSeconds) public onlyCreator(_workId) workExists(_workId) {
        // Assuming you add a 'licenseExpiryTimestamp' to the Work struct and 'duration' to License structs
        // This is a simplified example and requires more complex license term management for real-world use.
        // Placeholder logic:  In a real implementation, you'd check if the license is time-limited,
        // and update an expiry timestamp based on _extensionDurationInSeconds.
        // For this example, we'll just emit an event.
        emit LicenseExtended(_workId, _extensionDurationInSeconds);
        // Placeholder:  In a real implementation, update works[_workId].licenseExpiryTimestamp += _extensionDurationInSeconds;
    }


    // -------- 3. User Functions: License Verification & Reporting --------

    function getWorkLicenseDetails(uint256 _workId) public view workExists(_workId) returns (uint256 licenseType, uint256 licenseId, string memory licenseName, string memory licenseDescription, string memory licenseTermsOrPermissions) {
        Work storage work = works[_workId];
        licenseType = work.licenseType;
        licenseId = work.licenseId;
        if (licenseType == 0) { // Template License
            LicenseTemplate storage template = licenseTemplates[licenseId];
            return (licenseType, licenseId, template.name, template.description, template.permissions);
        } else if (licenseType == 1) { // Custom License
            CustomLicense storage customLicense = customLicenses[licenseId];
            return (licenseType, licenseId, customLicense.name, customLicense.description, customLicense.terms);
        } else { // No License
            return (licenseType, 0, "No License Applied", "No license is currently applied to this work.", "");
        }
    }

    function getWorkMetadata(uint256 _workId) public view workExists(_workId) returns (address creator, string memory title, string memory description, string memory ipfsHash, uint256 registrationTimestamp) {
        Work storage work = works[_workId];
        return (work.creator, work.title, work.description, work.ipfsHash, work.registrationTimestamp);
    }

    function verifyLicenseCompliance(uint256 _workId, string memory _intendedAction) public view workExists(_workId) returns (bool isCompliant, string memory explanation) {
        // This is a simplified example. Real-world license verification is complex and often requires off-chain legal interpretation.
        // Here, we provide a basic check based on keywords in license permissions/terms.

        (uint256 licenseType, uint256 licenseId, , , string memory licenseTermsOrPermissions) = getWorkLicenseDetails(_workId);

        if (licenseType == 2) {
            return (false, "No license applied to this work. All rights reserved.");
        }

        string memory lowerCasePermissions = licenseTermsOrPermissions; // In real app, convert to lowercase for case-insensitive check
        string memory lowerCaseAction = _intendedAction; // In real app, convert to lowercase

        if (licenseType == 0) { // Template License - Example logic based on template permissions
            if (stringContains(lowerCasePermissions, "noncommercial") && stringContains(lowerCaseAction, "commercial")) {
                return (false, "License is NonCommercial and action is Commercial.");
            }
            if (stringContains(lowerCasePermissions, "no derivative works") && stringContains(lowerCaseAction, "derivative")) {
                return (false, "License prohibits Derivative Works and action is Derivative.");
            }
            // Add more checks based on different license permissions as needed.
            return (true, "Action appears to be compliant with the license.");

        } else if (licenseType == 1) { // Custom License - More complex, might require parsing terms
            // For custom licenses, more sophisticated parsing and interpretation of 'licenseTermsOrPermissions' would be needed.
            // This example provides a very basic placeholder.
            if (stringContains(lowerCaseTermsOrPermissions, "prohibited action keyword") && stringContains(lowerCaseAction, "prohibited action keyword")) {
                 return (false, "Custom license specifically prohibits this action.");
            }
            return (true, "Action appears to be compliant with the custom license (basic check).");
        }

        return (false, "License type not recognized."); // Should not reach here in normal flow
    }

    function reportLicenseViolation(uint256 _workId, string memory _description) public workExists(_workId) {
        uint256 reportId = workViolationReports[_workId].length;
        workViolationReports[_workId].push(ViolationReport({
            reporter: msg.sender,
            workId: _workId,
            description: _description,
            reportTimestamp: block.timestamp,
            resolved: false
        }));
        emit LicenseViolationReported(reportId, _workId, msg.sender);
    }


    // -------- 4. Admin/Creator Functions: Violation Handling & Admin --------

    function getWorkViolationReports(uint256 _workId) public view workExists(_workId) returns (ViolationReport[] memory reports) {
        require(msg.sender == admin || works[_workId].creator == msg.sender, "Only admin or creator can view violation reports.");
        return workViolationReports[_workId];
    }

    function resolveViolationReport(uint256 _workId, uint256 _reportId) public onlyAdmin workExists(_workId) {
        require(_reportId < workViolationReports[_workId].length, "Invalid report ID.");
        workViolationReports[_workId][_reportId].resolved = true;
        emit LicenseViolationResolved(_reportId, _workId, admin);
        // In a real system, resolution might involve further actions like notifying parties, logging actions, etc.
    }

    function setLicenseTerm(uint256 _workId, string memory _termName, string memory _termValue) public onlyCreator(_workId) workExists(_workId) {
        // This is a placeholder for setting more specific license terms.
        // For example, you could add a struct to store license terms in a more structured way.
        // In this simplified contract, we are not implementing detailed term setting for brevity,
        // but this function suggests the possibility of adding more granular license controls.
        // Example:  setLicenseTerm(_workId, "allowedRegions", "US,CA,EU");
        // In a real implementation, you would need to define how these terms are stored and used in `verifyLicenseCompliance`.
        // For now, we just emit an event to show the concept.
        emit TermSet(_workId, _termName, _termValue);
    }

    event TermSet(uint256 workId, string termName, string termValue); // Example event for setLicenseTerm

    function getLicenseTerm(uint256 _workId, string memory _termName) public view workExists(_workId) returns (string memory termValue) {
        // Placeholder to retrieve license terms.  Requires more structured term storage.
        // In this simplified example, we are not implementing detailed term retrieval for brevity.
        // This function suggests the possibility of retrieving specific terms set via `setLicenseTerm`.
        // Example: getLicenseTerm(_workId, "allowedRegions");
        // For now, it returns an empty string as a placeholder.
        return ""; // Placeholder - In real implementation, retrieve term value from storage.
    }


    function setContractAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin address cannot be zero.");
        admin = _newAdmin;
    }


    // -------- 5. View Functions: Listing & Searching --------

    function listWorksByCreator(address _creator) public view returns (uint256[] memory workIds) {
        return creatorWorks[_creator];
    }

    function searchWorksByKeyword(string memory _keyword) public view returns (uint256[] memory matchingWorkIds) {
        uint256[] memory ids = new uint256[](workCount); // Max possible size
        uint256 index = 0;
        for (uint256 i = 1; i <= workCount; i++) {
            if (works[i].exists) {
                string memory combinedText = string(abi.encodePacked(works[i].title, " ", works[i].description)); // Search in title and description
                if (stringContains(combinedText, _keyword)) {
                    ids[index] = i;
                    index++;
                }
            }
        }
         // Resize array to remove empty slots
        assembly {
            mstore(ids, index) // Adjust the length of the array
        }
        return ids;
    }

    function getTotalRegisteredWorks() public view returns (uint256) {
        return workCount;
    }


    // -------- Internal Helper Functions --------

    function stringContains(string memory _haystack, string memory _needle) internal pure returns (bool) {
        return (stringToBytes(lowerString(_haystack)).indexOf(stringToBytes(lowerString(_needle))) != -1);
    }

    function stringToBytes(string memory s) internal pure returns (bytes memory) {
        bytes memory b = bytes(s);
        return b;
    }

    function lowerString(string memory _base) internal pure returns (string memory) {
        bytes memory _bytesBase = bytes(_base);
        bytes memory _bytesLower = new bytes(_bytesBase.length);
        for (uint i = 0; i < _bytesBase.length; i++) {
            // Uppercase to lowercase
            if ((uint8(_bytesBase[i]) >= 65) && (uint8(_bytesBase[i]) <= 90)) {
                _bytesLower[i] = bytes1(uint8(_bytesBase[i]) + 32);
            } else {
                _bytesLower[i] = _bytesBase[i];
            }
        }
        return string(_bytesLower);
    }
}
```