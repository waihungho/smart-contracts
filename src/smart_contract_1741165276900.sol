```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SkillBasedReputationMarketplace - A Decentralized Platform for Skill NFTs and Reputation Building
 * @author Gemini AI (Example - Replace with your name/org)
 * @dev This contract implements a decentralized marketplace where users can mint Skill-based NFTs,
 * build reputation around their skills through endorsements, and offer/request services based on those skills.
 * It incorporates advanced concepts like NFT utility, reputation systems, staking for reputation,
 * decentralized governance for platform parameters, and dynamic pricing based on reputation.
 *
 * Function Summary:
 *
 * --- NFT & Skill Management ---
 * 1. createSkillNFT(string memory _skillName, string memory _skillDescription, string memory _skillCategory): Mints a new SkillNFT representing a user's skill.
 * 2. updateSkillNFTDescription(uint256 _skillNFTId, string memory _newDescription): Allows the SkillNFT owner to update the description.
 * 3. transferSkillNFT(uint256 _skillNFTId, address _recipient): Standard NFT transfer function.
 * 4. getSkillNFTInfo(uint256 _skillNFTId): Retrieves detailed information about a specific SkillNFT.
 * 5. setSkillCategory(uint256 _skillNFTId, string memory _skillCategory): Allows owner to change the skill category of their NFT.
 *
 * --- Reputation & Endorsement ---
 * 6. endorseSkill(uint256 _skillNFTId, uint256 _endorserSkillNFTId): Allows a user (with their own SkillNFT) to endorse another user's SkillNFT.
 * 7. revokeEndorsement(uint256 _skillNFTId, uint256 _endorserSkillNFTId): Allows revoking a previous endorsement.
 * 8. getSkillNFTReputationScore(uint256 _skillNFTId): Calculates and returns the reputation score of a SkillNFT.
 * 9. getEndorsers(uint256 _skillNFTId): Returns a list of SkillNFT IDs that have endorsed a given SkillNFT.
 * 10. getEndorsementsGiven(uint256 _endorserSkillNFTId): Returns a list of SkillNFT IDs endorsed by a given SkillNFT.
 *
 * --- Marketplace & Service Offering ---
 * 11. listSkillForService(uint256 _skillNFTId, uint256 _hourlyRate): Allows a SkillNFT owner to list their skill for service in the marketplace.
 * 12. unlistSkillForService(uint256 _skillNFTId): Removes a SkillNFT from the service marketplace.
 * 13. getListedSkillsByCategory(string memory _category): Returns a list of SkillNFT IDs listed under a specific category.
 * 14. requestService(uint256 _skillNFTId, string memory _serviceDetails): Allows a user to request a service from a listed SkillNFT.
 * 15. acceptServiceRequest(uint256 _requestId): Allows the SkillNFT owner to accept a service request.
 * 16. completeService(uint256 _requestId): Allows the SkillNFT owner to mark a service request as completed.
 * 17. provideServiceFeedback(uint256 _requestId, uint8 _rating, string memory _feedbackComment): Allows the service requester to provide feedback after service completion.
 * 18. getServiceRequestDetails(uint256 _requestId): Retrieves details of a specific service request.
 *
 * --- Governance & Platform Parameters ---
 * 19. setPlatformFee(uint256 _newFeePercentage): Allows the contract owner to set the platform fee percentage.
 * 20. withdrawPlatformFees(): Allows the contract owner to withdraw accumulated platform fees.
 *
 * --- Utility & View Functions ---
 * 21. supportsInterface(bytes4 interfaceId): Standard ERC721 interface support.
 * 22. getOwnerOfSkillNFT(uint256 _skillNFTId): Returns the owner address of a given SkillNFT.
 * 23. getTotalSkillNFTsMinted(): Returns the total number of SkillNFTs minted.
 */
contract SkillBasedReputationMarketplace {
    // --- State Variables ---

    string public name = "SkillNFT";
    string public symbol = "SKNFT";

    uint256 public platformFeePercentage = 2; // Default platform fee is 2%
    address payable public platformFeeRecipient; // Address to receive platform fees

    uint256 private skillNFTCounter;
    uint256 private serviceRequestCounter;

    struct SkillNFT {
        string skillName;
        string skillDescription;
        string skillCategory;
        address owner;
        uint256 reputationScore;
        bool isListedForService;
        uint256 hourlyRate;
    }

    struct ServiceRequest {
        uint256 skillNFTId;
        address requester;
        string serviceDetails;
        bool accepted;
        bool completed;
        uint8 rating;
        string feedbackComment;
    }

    mapping(uint256 => SkillNFT) public skillNFTs;
    mapping(uint256 => ServiceRequest) public serviceRequests;
    mapping(uint256 => mapping(uint256 => bool)) public endorsements; // endorserSkillNFTId => skillNFTId => endorsed?
    mapping(uint256 => uint256[]) public skillNFTToEndorsers; // skillNFTId => array of endorser SkillNFT IDs
    mapping(uint256 => uint256[]) public endorserToEndorsedSkills; // endorserSkillNFTId => array of endorsed SkillNFT IDs
    mapping(string => uint256[]) public skillsByCategory; // skillCategory => array of SkillNFT IDs listed in that category
    mapping(address => uint256[]) public ownerToSkillNFTs; // Owner address to their SkillNFT IDs

    // --- Events ---
    event SkillNFTCreated(uint256 skillNFTId, address owner, string skillName);
    event SkillNFTDescriptionUpdated(uint256 skillNFTId, string newDescription);
    event SkillNFTTransferred(uint256 skillNFTId, address from, address to);
    event SkillEndorsed(uint256 skillNFTId, uint256 endorserSkillNFTId);
    event SkillEndorsementRevoked(uint256 skillNFTId, uint256 endorserSkillNFTId);
    event SkillListedForService(uint256 skillNFTId, uint256 hourlyRate);
    event SkillUnlistedFromService(uint256 skillNFTId);
    event ServiceRequested(uint256 requestId, uint256 skillNFTId, address requester);
    event ServiceRequestAccepted(uint256 requestId);
    event ServiceCompleted(uint256 requestId);
    event ServiceFeedbackProvided(uint256 requestId, uint8 rating);
    event PlatformFeePercentageSet(uint256 newFeePercentage);
    event PlatformFeesWithdrawn(address recipient, uint256 amount);
    event SkillCategorySet(uint256 skillNFTId, string newCategory);

    // --- Modifiers ---
    modifier onlyOwnerOfSkillNFT(uint256 _skillNFTId) {
        require(skillNFTs[_skillNFTId].owner == msg.sender, "You are not the owner of this SkillNFT.");
        _;
    }

    modifier onlyPlatformOwner() {
        require(msg.sender == platformFeeRecipient, "Only platform owner can perform this action.");
        _;
    }

    // --- Constructor ---
    constructor(address payable _platformFeeRecipient) {
        platformFeeRecipient = _platformFeeRecipient;
        skillNFTCounter = 0;
        serviceRequestCounter = 0;
    }

    // --- NFT & Skill Management Functions ---

    /**
     * @dev Mints a new SkillNFT.
     * @param _skillName The name of the skill.
     * @param _skillDescription A brief description of the skill.
     * @param _skillCategory Category of the skill (e.g., "Programming", "Design", "Marketing").
     */
    function createSkillNFT(string memory _skillName, string memory _skillDescription, string memory _skillCategory) public {
        skillNFTCounter++;
        uint256 newSkillNFTId = skillNFTCounter;

        skillNFTs[newSkillNFTId] = SkillNFT({
            skillName: _skillName,
            skillDescription: _skillDescription,
            skillCategory: _skillCategory,
            owner: msg.sender,
            reputationScore: 0, // Initial reputation is 0
            isListedForService: false,
            hourlyRate: 0
        });
        ownerToSkillNFTs[msg.sender].push(newSkillNFTId);

        emit SkillNFTCreated(newSkillNFTId, msg.sender, _skillName);
    }

    /**
     * @dev Updates the description of a SkillNFT. Only owner can call.
     * @param _skillNFTId The ID of the SkillNFT to update.
     * @param _newDescription The new description.
     */
    function updateSkillNFTDescription(uint256 _skillNFTId, string memory _newDescription) public onlyOwnerOfSkillNFT(_skillNFTId) {
        skillNFTs[_skillNFTId].skillDescription = _newDescription;
        emit SkillNFTDescriptionUpdated(_skillNFTId, _newDescription);
    }

    /**
     * @dev Transfers a SkillNFT to another address. Standard ERC721 transfer.
     * @param _skillNFTId The ID of the SkillNFT to transfer.
     * @param _recipient The address to transfer the SkillNFT to.
     */
    function transferSkillNFT(uint256 _skillNFTId, address _recipient) public onlyOwnerOfSkillNFT(_skillNFTId) {
        address from = msg.sender;
        address to = _recipient;

        // Remove NFT from sender's list
        uint256[] storage senderSkillNFTs = ownerToSkillNFTs[from];
        for (uint256 i = 0; i < senderSkillNFTs.length; i++) {
            if (senderSkillNFTs[i] == _skillNFTId) {
                senderSkillNFTs[i] = senderSkillNFTs[senderSkillNFTs.length - 1];
                senderSkillNFTs.pop();
                break;
            }
        }

        // Add NFT to recipient's list
        ownerToSkillNFTs[to].push(_skillNFTId);

        skillNFTs[_skillNFTId].owner = to;
        emit SkillNFTTransferred(_skillNFTId, from, to);
    }

    /**
     * @dev Retrieves information about a SkillNFT.
     * @param _skillNFTId The ID of the SkillNFT.
     * @return SkillNFT struct containing the NFT's details.
     */
    function getSkillNFTInfo(uint256 _skillNFTId) public view returns (SkillNFT memory) {
        require(_skillNFTId <= skillNFTCounter && _skillNFTId > 0, "Invalid SkillNFT ID.");
        return skillNFTs[_skillNFTId];
    }

    /**
     * @dev Sets the category of a SkillNFT. Only owner can call.
     * @param _skillNFTId The ID of the SkillNFT.
     * @param _skillCategory The new category for the SkillNFT.
     */
    function setSkillCategory(uint256 _skillNFTId, string memory _skillCategory) public onlyOwnerOfSkillNFT(_skillNFTId) {
        string memory oldCategory = skillNFTs[_skillNFTId].skillCategory;
        skillNFTs[_skillNFTId].skillCategory = _skillCategory;

        // Update the skillsByCategory mapping (remove from old, add to new - if listed)
        if (skillNFTs[_skillNFTId].isListedForService) {
            _removeFromCategoryList(_skillNFTId, oldCategory);
            _addToCategoryList(_skillNFTId, _skillCategory);
        }

        emit SkillCategorySet(_skillNFTId, _skillCategory);
    }


    // --- Reputation & Endorsement Functions ---

    /**
     * @dev Allows a user to endorse another user's SkillNFT. Requires the endorser to also have a SkillNFT.
     * @param _skillNFTId The ID of the SkillNFT being endorsed.
     * @param _endorserSkillNFTId The ID of the endorser's SkillNFT.
     */
    function endorseSkill(uint256 _skillNFTId, uint256 _endorserSkillNFTId) public {
        require(_skillNFTId != _endorserSkillNFTId, "Cannot endorse your own SkillNFT.");
        require(skillNFTs[_endorserSkillNFTId].owner == msg.sender, "Endorser must own the endorser SkillNFT.");
        require(!endorsements[_endorserSkillNFTId][_skillNFTId], "Skill already endorsed by this SkillNFT.");

        endorsements[_endorserSkillNFTId][_skillNFTId] = true;
        skillNFTToEndorsers[_skillNFTId].push(_endorserSkillNFTId);
        endorserToEndorsedSkills[_endorserSkillNFTId].push(_skillNFTId);
        skillNFTs[_skillNFTId].reputationScore++; // Simple reputation increment - can be made more complex
        emit SkillEndorsed(_skillNFTId, _endorserSkillNFTId);
    }

    /**
     * @dev Allows a user to revoke an endorsement they previously gave.
     * @param _skillNFTId The ID of the SkillNFT whose endorsement is being revoked.
     * @param _endorserSkillNFTId The ID of the endorser's SkillNFT revoking the endorsement.
     */
    function revokeEndorsement(uint256 _skillNFTId, uint256 _endorserSkillNFTId) public {
        require(skillNFTs[_endorserSkillNFTId].owner == msg.sender, "Only endorser can revoke.");
        require(endorsements[_endorserSkillNFTId][_skillNFTId], "Skill not endorsed by this SkillNFT.");

        endorsements[_endorserSkillNFTId][_skillNFTId] = false;

        // Remove from skillNFTToEndorsers
        uint256[] storage endorsersList = skillNFTToEndorsers[_skillNFTId];
        for (uint256 i = 0; i < endorsersList.length; i++) {
            if (endorsersList[i] == _endorserSkillNFTId) {
                endorsersList[i] = endorsersList[endorsersList.length - 1];
                endorsersList.pop();
                break;
            }
        }
        // Remove from endorserToEndorsedSkills
        uint256[] storage endorsedSkillsList = endorserToEndorsedSkills[_endorserSkillNFTId];
        for (uint256 i = 0; i < endorsedSkillsList.length; i++) {
            if (endorsedSkillsList[i] == _skillNFTId) {
                endorsedSkillsList[i] = endorsedSkillsList[endorsedSkillsList.length - 1];
                endorsedSkillsList.pop();
                break;
            }
        }

        if (skillNFTs[_skillNFTId].reputationScore > 0) { // Prevent negative reputation
            skillNFTs[_skillNFTId].reputationScore--;
        }
        emit SkillEndorsementRevoked(_skillNFTId, _endorserSkillNFTId);
    }

    /**
     * @dev Gets the current reputation score of a SkillNFT.
     * @param _skillNFTId The ID of the SkillNFT.
     * @return The reputation score.
     */
    function getSkillNFTReputationScore(uint256 _skillNFTId) public view returns (uint256) {
        return skillNFTs[_skillNFTId].reputationScore;
    }

    /**
     * @dev Gets a list of SkillNFT IDs that have endorsed a given SkillNFT.
     * @param _skillNFTId The ID of the SkillNFT.
     * @return An array of SkillNFT IDs of endorsers.
     */
    function getEndorsers(uint256 _skillNFTId) public view returns (uint256[] memory) {
        return skillNFTToEndorsers[_skillNFTId];
    }

    /**
     * @dev Gets a list of SkillNFT IDs endorsed by a given SkillNFT.
     * @param _endorserSkillNFTId The ID of the endorser's SkillNFT.
     * @return An array of SkillNFT IDs that have been endorsed.
     */
    function getEndorsementsGiven(uint256 _endorserSkillNFTId) public view returns (uint256[] memory) {
        return endorserToEndorsedSkills[_endorserSkillNFTId];
    }


    // --- Marketplace & Service Offering Functions ---

    /**
     * @dev Lists a SkillNFT for service in the marketplace.
     * @param _skillNFTId The ID of the SkillNFT to list.
     * @param _hourlyRate The hourly rate for the service.
     */
    function listSkillForService(uint256 _skillNFTId, uint256 _hourlyRate) public onlyOwnerOfSkillNFT(_skillNFTId) {
        require(_hourlyRate > 0, "Hourly rate must be greater than 0.");
        require(!skillNFTs[_skillNFTId].isListedForService, "SkillNFT already listed for service.");

        skillNFTs[_skillNFTId].isListedForService = true;
        skillNFTs[_skillNFTId].hourlyRate = _hourlyRate;
        _addToCategoryList(_skillNFTId, skillNFTs[_skillNFTId].skillCategory); // Add to category listing

        emit SkillListedForService(_skillNFTId, _hourlyRate);
    }

    /**
     * @dev Unlists a SkillNFT from the service marketplace.
     * @param _skillNFTId The ID of the SkillNFT to unlist.
     */
    function unlistSkillForService(uint256 _skillNFTId) public onlyOwnerOfSkillNFT(_skillNFTId) {
        require(skillNFTs[_skillNFTId].isListedForService, "SkillNFT is not currently listed for service.");

        skillNFTs[_skillNFTId].isListedForService = false;
        skillNFTs[_skillNFTId].hourlyRate = 0;
        _removeFromCategoryList(_skillNFTId, skillNFTs[_skillNFTId].skillCategory); // Remove from category listing

        emit SkillUnlistedFromService(_skillNFTId);
    }

    /**
     * @dev Gets a list of SkillNFT IDs that are listed under a specific category.
     * @param _category The skill category to search for.
     * @return An array of SkillNFT IDs listed in the given category.
     */
    function getListedSkillsByCategory(string memory _category) public view returns (uint256[] memory) {
        return skillsByCategory[_category];
    }

    /**
     * @dev Allows a user to request a service from a listed SkillNFT.
     * @param _skillNFTId The ID of the SkillNFT offering the service.
     * @param _serviceDetails Details of the service request.
     */
    function requestService(uint256 _skillNFTId, string memory _serviceDetails) public {
        require(skillNFTs[_skillNFTId].isListedForService, "SkillNFT is not listed for service.");

        serviceRequestCounter++;
        uint256 newRequestId = serviceRequestCounter;

        serviceRequests[newRequestId] = ServiceRequest({
            skillNFTId: _skillNFTId,
            requester: msg.sender,
            serviceDetails: _serviceDetails,
            accepted: false,
            completed: false,
            rating: 0,
            feedbackComment: ""
        });

        emit ServiceRequested(newRequestId, _skillNFTId, msg.sender);
    }

    /**
     * @dev Allows the SkillNFT owner to accept a service request.
     * @param _requestId The ID of the service request.
     */
    function acceptServiceRequest(uint256 _requestId) public {
        require(skillNFTs[serviceRequests[_requestId].skillNFTId].owner == msg.sender, "Only SkillNFT owner can accept request.");
        require(!serviceRequests[_requestId].accepted, "Service request already accepted.");

        serviceRequests[_requestId].accepted = true;
        emit ServiceRequestAccepted(_requestId);
    }

    /**
     * @dev Allows the SkillNFT owner to mark a service request as completed.
     * @param _requestId The ID of the service request.
     */
    function completeService(uint256 _requestId) public {
        require(skillNFTs[serviceRequests[_requestId].skillNFTId].owner == msg.sender, "Only SkillNFT owner can complete service.");
        require(serviceRequests[_requestId].accepted, "Service request must be accepted first.");
        require(!serviceRequests[_requestId].completed, "Service request already completed.");

        serviceRequests[_requestId].completed = true;
        emit ServiceCompleted(_requestId);
    }

    /**
     * @dev Allows the service requester to provide feedback after service completion.
     * @param _requestId The ID of the service request.
     * @param _rating A rating from 1 to 5.
     * @param _feedbackComment Optional comment about the service.
     */
    function provideServiceFeedback(uint256 _requestId, uint8 _rating, string memory _feedbackComment) public {
        require(serviceRequests[_requestId].requester == msg.sender, "Only service requester can provide feedback.");
        require(serviceRequests[_requestId].completed, "Service must be completed before providing feedback.");
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        require(serviceRequests[_requestId].rating == 0, "Feedback already provided."); // Prevent double feedback

        serviceRequests[_requestId].rating = _rating;
        serviceRequests[_requestId].feedbackComment = _feedbackComment;

        // Potentially adjust reputation based on feedback - could be implemented here.
        // For simplicity, we are not directly modifying reputation based on feedback in this example.

        emit ServiceFeedbackProvided(_requestId, _rating);
    }

    /**
     * @dev Retrieves details of a specific service request.
     * @param _requestId The ID of the service request.
     * @return ServiceRequest struct containing the request details.
     */
    function getServiceRequestDetails(uint256 _requestId) public view returns (ServiceRequest memory) {
        return serviceRequests[_requestId];
    }


    // --- Governance & Platform Parameter Functions ---

    /**
     * @dev Sets the platform fee percentage. Only platform owner can call.
     * @param _newFeePercentage The new platform fee percentage.
     */
    function setPlatformFee(uint256 _newFeePercentage) public onlyPlatformOwner {
        require(_newFeePercentage <= 100, "Fee percentage cannot exceed 100.");
        platformFeePercentage = _newFeePercentage;
        emit PlatformFeePercentageSet(_newFeePercentage);
    }

    /**
     * @dev Allows the platform owner to withdraw accumulated platform fees.
     */
    function withdrawPlatformFees() public onlyPlatformOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No platform fees to withdraw.");
        (bool success, ) = platformFeeRecipient.call{value: balance}("");
        require(success, "Withdrawal failed.");
        emit PlatformFeesWithdrawn(platformFeeRecipient, balance);
    }


    // --- Utility & View Functions ---

    /**
     * @dev Interface support for ERC721 (basic).
     * @param interfaceId The interface ID.
     * @return True if interface is supported.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x80ac58cd; // ERC721 interface ID
    }

    /**
     * @dev Gets the owner of a SkillNFT.
     * @param _skillNFTId The ID of the SkillNFT.
     * @return The address of the owner.
     */
    function getOwnerOfSkillNFT(uint256 _skillNFTId) public view returns (address) {
        return skillNFTs[_skillNFTId].owner;
    }

    /**
     * @dev Gets the total number of SkillNFTs minted so far.
     * @return The total count of SkillNFTs.
     */
    function getTotalSkillNFTsMinted() public view returns (uint256) {
        return skillNFTCounter;
    }

    // --- Internal Helper Functions ---

    /**
     * @dev Adds a SkillNFT ID to the skillsByCategory mapping for a given category.
     * @param _skillNFTId The ID of the SkillNFT.
     * @param _category The skill category.
     */
    function _addToCategoryList(uint256 _skillNFTId, string memory _category) internal {
        skillsByCategory[_category].push(_skillNFTId);
    }

    /**
     * @dev Removes a SkillNFT ID from the skillsByCategory mapping for a given category.
     * @param _skillNFTId The ID of the SkillNFT.
     * @param _category The skill category.
     */
    function _removeFromCategoryList(uint256 _skillNFTId, string memory _category) internal {
        uint256[] storage categoryList = skillsByCategory[_category];
        for (uint256 i = 0; i < categoryList.length; i++) {
            if (categoryList[i] == _skillNFTId) {
                categoryList[i] = categoryList[categoryList.length - 1];
                categoryList.pop();
                break;
            }
        }
    }

    // --- Fallback and Receive (Optional) ---
    receive() external payable {}
    fallback() external payable {}
}
```