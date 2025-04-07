```solidity
/**
 * @title Decentralized Creative Commons (DCC) - Smart Contract
 * @author Gemini AI (Conceptual Example - Not for Production)
 * @dev This contract implements a decentralized system for registering, licensing, and managing creative works, inspired by Creative Commons principles but on-chain.
 * It provides functionalities for creators to register their works, define custom licenses or use pre-defined templates, manage rights, and potentially interact with users who want to utilize the creative works.
 *
 * **Outline and Function Summary:**
 *
 * **1. Content Registration & Management:**
 *    - `registerContent(string _title, string _ipfsHash, string _metadataURI)`: Allows creators to register new creative content.
 *    - `updateContentMetadata(uint256 _contentId, string _metadataURI)`: Allows creators to update the metadata URI of their content.
 *    - `setContentLicense(uint256 _contentId, uint256 _licenseId)`: Allows creators to set a specific license for their content.
 *    - `getContentDetails(uint256 _contentId)`: Retrieves detailed information about a registered content.
 *    - `getContentLicense(uint256 _contentId)`: Retrieves the license ID associated with a content.
 *    - `transferContentOwnership(uint256 _contentId, address _newOwner)`: Allows content owners to transfer ownership to another address.
 *    - `archiveContent(uint256 _contentId)`: Allows content owners to archive content, making it unavailable for new licenses.
 *    - `getActiveContentCount()`: Returns the total number of active registered content.
 *
 * **2. License Management:**
 *    - `createLicenseTemplate(string _name, string _description, string _termsURI)`: Allows platform admins to create new license templates.
 *    - `updateLicenseTemplate(uint256 _licenseId, string _name, string _description, string _termsURI)`: Allows platform admins to update existing license templates.
 *    - `getLicenseDetails(uint256 _licenseId)`: Retrieves details of a specific license template.
 *    - `getLicenseCount()`: Returns the total number of available license templates.
 *
 * **3. Creator Profile Management:**
 *    - `registerCreator(string _name, string _profileURI)`: Allows users to register as creators on the platform.
 *    - `updateCreatorProfile(string _name, string _profileURI)`: Allows creators to update their profile information.
 *    - `getCreatorProfile(address _creatorAddress)`: Retrieves the profile information of a creator.
 *    - `isRegisteredCreator(address _address)`: Checks if an address is registered as a creator.
 *
 * **4. Platform Governance & Utility:**
 *    - `setPlatformFee(uint256 _feePercentage)`: Allows platform admins to set a platform fee for certain actions (e.g., commercial license grants - *not implemented in this basic example*).
 *    - `pauseContract()`: Allows platform admins to pause the contract in case of emergency.
 *    - `unpauseContract()`: Allows platform admins to unpause the contract.
 *    - `addAdmin(address _newAdmin)`: Allows current admins to add new platform administrators.
 *    - `removeAdmin(address _adminToRemove)`: Allows current admins to remove platform administrators.
 *    - `getPlatformAdminCount()`: Returns the number of platform administrators.
 *    - `withdrawPlatformFees()`: Allows platform admins to withdraw accumulated platform fees (*not implemented in this basic example*).
 *
 * **5. Content Discovery (Basic):**
 *    - `getContentByCreator(address _creatorAddress)`: Retrieves a list of content IDs registered by a specific creator.
 */
pragma solidity ^0.8.0;

contract DecentralizedCreativeCommons {

    // Structs for data organization
    struct Content {
        uint256 id;
        address creator;
        string title;
        string ipfsHash; // IPFS hash of the content itself
        string metadataURI; // URI pointing to metadata (e.g., JSON file with more details)
        uint256 licenseId;
        uint256 registrationTimestamp;
        bool isActive;
    }

    struct LicenseTemplate {
        uint256 id;
        string name;
        string description;
        string termsURI; // URI pointing to the full license terms
        bool isActive;
    }

    struct CreatorProfile {
        string name;
        string profileURI; // URI pointing to creator's profile metadata
        bool isRegistered;
    }

    // State variables
    mapping(uint256 => Content) public contentRegistry;
    uint256 public contentCount;

    mapping(uint256 => LicenseTemplate) public licenseTemplates;
    uint256 public licenseCount;

    mapping(address => CreatorProfile) public creatorProfiles;
    address[] public registeredCreators;

    address[] public platformAdmins;
    uint256 public platformFeePercentage; // Percentage fee for platform actions (e.g., commercial licenses - not implemented in this basic example)
    bool public paused;

    // Events
    event ContentRegistered(uint256 contentId, address creator, string title);
    event ContentMetadataUpdated(uint256 contentId, string metadataURI);
    event ContentLicenseSet(uint256 contentId, uint256 licenseId);
    event ContentOwnershipTransferred(uint256 contentId, address oldOwner, address newOwner);
    event ContentArchived(uint256 contentId);
    event LicenseTemplateCreated(uint256 licenseId, string name);
    event LicenseTemplateUpdated(uint256 licenseId, string name);
    event CreatorRegistered(address creatorAddress, string name);
    event CreatorProfileUpdated(address creatorAddress, string name);
    event PlatformFeeSet(uint256 feePercentage);
    event ContractPaused();
    event ContractUnpaused();
    event AdminAdded(address newAdmin);
    event AdminRemoved(address removedAdmin);

    // Modifiers
    modifier onlyCreator(uint256 _contentId) {
        require(contentRegistry[_contentId].creator == msg.sender, "You are not the creator of this content.");
        _;
    }

    modifier onlyPlatformAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        require(isAdmin, "You are not a platform administrator.");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused.");
        _;
    }

    modifier whenPaused() {
        require(paused, "Contract is not paused.");
        _;
    }

    // Constructor - Set the contract deployer as the initial admin
    constructor() {
        platformAdmins.push(msg.sender);
        platformFeePercentage = 0; // Default to 0% fee
        paused = false;
        licenseCount = 0; // Initialize license count
        _createDefaultLicenseTemplates(); // Create some default license templates on deployment
    }

    // --------------------------------------------------------
    // 1. Content Registration & Management Functions
    // --------------------------------------------------------

    /// @notice Registers new creative content on the platform.
    /// @param _title The title of the content.
    /// @param _ipfsHash The IPFS hash of the content file.
    /// @param _metadataURI URI pointing to the content's metadata (e.g., JSON file).
    function registerContent(string memory _title, string memory _ipfsHash, string memory _metadataURI) external whenNotPaused {
        require(bytes(_title).length > 0 && bytes(_ipfsHash).length > 0 && bytes(_metadataURI).length > 0, "Content details cannot be empty.");
        require(creatorProfiles[msg.sender].isRegistered, "You must be registered as a creator to register content.");

        contentCount++;
        contentRegistry[contentCount] = Content({
            id: contentCount,
            creator: msg.sender,
            title: _title,
            ipfsHash: _ipfsHash,
            metadataURI: _metadataURI,
            licenseId: 0, // Default to no license initially (or could set a default license)
            registrationTimestamp: block.timestamp,
            isActive: true
        });

        emit ContentRegistered(contentCount, msg.sender, _title);
    }

    /// @notice Updates the metadata URI of a registered content.
    /// @param _contentId The ID of the content to update.
    /// @param _metadataURI The new metadata URI.
    function updateContentMetadata(uint256 _contentId, string memory _metadataURI) external onlyCreator(_contentId) whenNotPaused {
        require(bytes(_metadataURI).length > 0, "Metadata URI cannot be empty.");
        contentRegistry[_contentId].metadataURI = _metadataURI;
        emit ContentMetadataUpdated(_contentId, _metadataURI);
    }

    /// @notice Sets a specific license for a registered content.
    /// @param _contentId The ID of the content.
    /// @param _licenseId The ID of the license template to apply.
    function setContentLicense(uint256 _contentId, uint256 _licenseId) external onlyCreator(_contentId) whenNotPaused {
        require(licenseTemplates[_licenseId].isActive, "License template is not active or does not exist.");
        contentRegistry[_contentId].licenseId = _licenseId;
        emit ContentLicenseSet(_contentId, _licenseId);
    }

    /// @notice Retrieves detailed information about a registered content.
    /// @param _contentId The ID of the content.
    /// @return Content struct containing content details.
    function getContentDetails(uint256 _contentId) external view returns (Content memory) {
        require(contentRegistry[_contentId].id != 0, "Content not found.");
        return contentRegistry[_contentId];
    }

    /// @notice Retrieves the license ID associated with a content.
    /// @param _contentId The ID of the content.
    /// @return licenseId The ID of the applied license template.
    function getContentLicense(uint256 _contentId) external view returns (uint256) {
        require(contentRegistry[_contentId].id != 0, "Content not found.");
        return contentRegistry[_contentId].licenseId;
    }

    /// @notice Transfers ownership of content to a new address.
    /// @param _contentId The ID of the content to transfer.
    /// @param _newOwner The address of the new owner.
    function transferContentOwnership(uint256 _contentId, address _newOwner) external onlyCreator(_contentId) whenNotPaused {
        require(_newOwner != address(0) && _newOwner != msg.sender, "Invalid new owner address.");
        emit ContentOwnershipTransferred(_contentId, contentRegistry[_contentId].creator, _newOwner);
        contentRegistry[_contentId].creator = _newOwner;
    }

    /// @notice Archives content, making it unavailable for new licenses or modifications (except metadata updates perhaps).
    /// @param _contentId The ID of the content to archive.
    function archiveContent(uint256 _contentId) external onlyCreator(_contentId) whenNotPaused {
        require(contentRegistry[_contentId].isActive, "Content is already archived.");
        contentRegistry[_contentId].isActive = false;
        emit ContentArchived(_contentId);
    }

    /// @notice Returns the total number of active registered content.
    /// @return uint256 Total active content count.
    function getActiveContentCount() external view returns (uint256) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contentRegistry[i].isActive) {
                activeCount++;
            }
        }
        return activeCount;
    }


    // --------------------------------------------------------
    // 2. License Management Functions
    // --------------------------------------------------------

    /// @notice Creates a new license template (only admin).
    /// @param _name The name of the license template.
    /// @param _description A brief description of the license.
    /// @param _termsURI URI pointing to the full license terms document.
    function createLicenseTemplate(string memory _name, string memory _description, string memory _termsURI) external onlyPlatformAdmin whenNotPaused {
        require(bytes(_name).length > 0 && bytes(_description).length > 0 && bytes(_termsURI).length > 0, "License details cannot be empty.");
        licenseCount++;
        licenseTemplates[licenseCount] = LicenseTemplate({
            id: licenseCount,
            name: _name,
            description: _description,
            termsURI: _termsURI,
            isActive: true
        });
        emit LicenseTemplateCreated(licenseCount, _name);
    }

    /// @notice Updates an existing license template (only admin).
    /// @param _licenseId The ID of the license template to update.
    /// @param _name The new name of the license template.
    /// @param _description The new description.
    /// @param _termsURI The new URI to the license terms.
    function updateLicenseTemplate(uint256 _licenseId, string memory _name, string memory _description, string memory _termsURI) external onlyPlatformAdmin whenNotPaused {
        require(licenseTemplates[_licenseId].isActive, "License template is not active or does not exist.");
        require(bytes(_name).length > 0 && bytes(_description).length > 0 && bytes(_termsURI).length > 0, "License details cannot be empty.");
        licenseTemplates[_licenseId].name = _name;
        licenseTemplates[_licenseId].description = _description;
        licenseTemplates[_licenseId].termsURI = _termsURI;
        emit LicenseTemplateUpdated(_licenseId, _name);
    }

    /// @notice Retrieves details of a specific license template.
    /// @param _licenseId The ID of the license template.
    /// @return LicenseTemplate struct containing license details.
    function getLicenseDetails(uint256 _licenseId) external view returns (LicenseTemplate memory) {
        require(licenseTemplates[_licenseId].id != 0, "License template not found.");
        return licenseTemplates[_licenseId];
    }

    /// @notice Returns the total number of available license templates.
    /// @return uint256 Total license template count.
    function getLicenseCount() external view returns (uint256) {
        return licenseCount;
    }

    // --------------------------------------------------------
    // 3. Creator Profile Management Functions
    // --------------------------------------------------------

    /// @notice Registers a user as a creator on the platform.
    /// @param _name The name of the creator.
    /// @param _profileURI URI pointing to the creator's profile metadata (optional).
    function registerCreator(string memory _name, string memory _profileURI) external whenNotPaused {
        require(bytes(_name).length > 0, "Creator name cannot be empty.");
        require(!creatorProfiles[msg.sender].isRegistered, "Already registered as a creator.");

        creatorProfiles[msg.sender] = CreatorProfile({
            name: _name,
            profileURI: _profileURI,
            isRegistered: true
        });
        registeredCreators.push(msg.sender);
        emit CreatorRegistered(msg.sender, _name);
    }

    /// @notice Updates a creator's profile information.
    /// @param _name The new name of the creator.
    /// @param _profileURI The new profile metadata URI.
    function updateCreatorProfile(string memory _name, string memory _profileURI) external whenNotPaused {
        require(creatorProfiles[msg.sender].isRegistered, "You must be registered as a creator to update profile.");
        require(bytes(_name).length > 0, "Creator name cannot be empty.");
        creatorProfiles[msg.sender].name = _name;
        creatorProfiles[msg.sender].profileURI = _profileURI;
        emit CreatorProfileUpdated(msg.sender, _name);
    }

    /// @notice Retrieves the profile information of a creator.
    /// @param _creatorAddress The address of the creator.
    /// @return CreatorProfile struct containing creator profile details.
    function getCreatorProfile(address _creatorAddress) external view returns (CreatorProfile memory) {
        return creatorProfiles[_creatorAddress]; // Will return default values if not registered
    }

    /// @notice Checks if an address is registered as a creator.
    /// @param _address The address to check.
    /// @return bool True if registered, false otherwise.
    function isRegisteredCreator(address _address) external view returns (bool) {
        return creatorProfiles[_address].isRegistered;
    }

    // --------------------------------------------------------
    // 4. Platform Governance & Utility Functions
    // --------------------------------------------------------

    /// @notice Sets the platform fee percentage (only admin).
    /// @param _feePercentage The new platform fee percentage (0-100).
    function setPlatformFee(uint256 _feePercentage) external onlyPlatformAdmin whenNotPaused {
        require(_feePercentage <= 100, "Fee percentage must be between 0 and 100.");
        platformFeePercentage = _feePercentage;
        emit PlatformFeeSet(_feePercentage);
    }

    /// @notice Pauses the contract, preventing most functions from being called (only admin).
    function pauseContract() external onlyPlatformAdmin whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    /// @notice Unpauses the contract, allowing functions to be called again (only admin).
    function unpauseContract() external onlyPlatformAdmin whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    /// @notice Adds a new platform administrator (only admin).
    /// @param _newAdmin The address of the new admin.
    function addAdmin(address _newAdmin) external onlyPlatformAdmin whenNotPaused {
        require(_newAdmin != address(0), "Invalid admin address.");
        bool alreadyAdmin = false;
        for (uint256 i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == _newAdmin) {
                alreadyAdmin = true;
                break;
            }
        }
        require(!alreadyAdmin, "Address is already an admin.");
        platformAdmins.push(_newAdmin);
        emit AdminAdded(_newAdmin);
    }

    /// @notice Removes a platform administrator (only admin - cannot remove self in this basic example for simplicity).
    /// @param _adminToRemove The address of the admin to remove.
    function removeAdmin(address _adminToRemove) external onlyPlatformAdmin whenNotPaused {
        require(_adminToRemove != address(0) && _adminToRemove != msg.sender, "Cannot remove the zero address or yourself in this basic example.");
        bool isAdmin = false;
        uint256 adminIndex = 0;
        for (uint256 i = 0; i < platformAdmins.length; i++) {
            if (platformAdmins[i] == _adminToRemove) {
                isAdmin = true;
                adminIndex = i;
                break;
            }
        }
        require(isAdmin, "Address is not an admin.");

        // Remove admin from the array (more gas efficient way to remove in Solidity)
        platformAdmins[adminIndex] = platformAdmins[platformAdmins.length - 1];
        platformAdmins.pop();
        emit AdminRemoved(_adminToRemove);
    }

    /// @notice Gets the number of platform administrators.
    /// @return uint256 The number of admins.
    function getPlatformAdminCount() external view returns (uint256) {
        return platformAdmins.length;
    }

    // Placeholder for fee withdrawal - In a real application, you'd need to implement fee collection logic
    // function withdrawPlatformFees() external onlyPlatformAdmin { ... }


    // --------------------------------------------------------
    // 5. Content Discovery (Basic) Functions
    // --------------------------------------------------------

    /// @notice Retrieves a list of content IDs registered by a specific creator.
    /// @param _creatorAddress The address of the creator.
    /// @return uint256[] Array of content IDs.
    function getContentByCreator(address _creatorAddress) external view returns (uint256[] memory) {
        uint256[] memory creatorContentIds = new uint256[](contentCount); // Max possible size
        uint256 count = 0;
        for (uint256 i = 1; i <= contentCount; i++) {
            if (contentRegistry[i].creator == _creatorAddress && contentRegistry[i].isActive) {
                creatorContentIds[count] = contentRegistry[i].id;
                count++;
            }
        }

        // Resize the array to the actual number of content IDs found
        uint256[] memory finalContentIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            finalContentIds[i] = creatorContentIds[i];
        }
        return finalContentIds;
    }

    // --------------------------------------------------------
    // Internal Helper Functions
    // --------------------------------------------------------

    /// @dev Internal function to create default license templates on contract deployment.
    function _createDefaultLicenseTemplates() internal {
        createLicenseTemplate(
            "CC BY 4.0",
            "Attribution 4.0 International",
            "https://creativecommons.org/licenses/by/4.0/"
        );
        createLicenseTemplate(
            "CC BY-SA 4.0",
            "Attribution-ShareAlike 4.0 International",
            "https://creativecommons.org/licenses/by-sa/4.0/"
        );
        createLicenseTemplate(
            "CC BY-NC 4.0",
            "Attribution-NonCommercial 4.0 International",
            "https://creativecommons.org/licenses/by-nc/4.0/"
        );
        createLicenseTemplate(
            "CC BY-ND 4.0",
            "Attribution-NoDerivatives 4.0 International",
            "https://creativecommons.org/licenses/by-nd/4.0/"
        );
        createLicenseTemplate(
            "CC BY-NC-SA 4.0",
            "Attribution-NonCommercial-ShareAlike 4.0 International",
            "https://creativecommons.org/licenses/by-nc-sa/4.0/"
        );
        createLicenseTemplate(
            "CC BY-NC-ND 4.0",
            "Attribution-NonCommercial-NoDerivatives 4.0 International",
            "https://creativecommons.org/licenses/by-nc-nd/4.0/"
        );
        createLicenseTemplate(
            "CC0 1.0",
            "Public Domain Dedication",
            "https://creativecommons.org/publicdomain/zero/1.0/"
        );
        // Add more default licenses as needed
    }
}
```