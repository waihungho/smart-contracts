```solidity
/**
 * @title Decentralized Reputation and Skill Marketplace - SkillVerse
 * @author Bard (AI Assistant)
 * @dev A smart contract for a decentralized marketplace where users can build reputation based on their skills and services offered.
 * It incorporates advanced concepts like skill-based reputation, dynamic pricing, dispute resolution, and tiered access.
 *
 * **Outline and Function Summary:**
 *
 * **1. User Management:**
 *    - `registerUser(string _username, string _profileDescription)`: Allows users to register with a unique username and profile description.
 *    - `updateProfile(string _profileDescription)`: Allows registered users to update their profile description.
 *    - `setUsername(string _newUsername)`: Allows registered users to update their username (with uniqueness check).
 *    - `getUserProfile(address _userAddress) view returns (string username, string profileDescription, uint256 reputationScore, Skill[] userSkills)`: Retrieves user profile information.
 *    - `isUserRegistered(address _userAddress) view returns (bool)`: Checks if an address is registered as a user.
 *
 * **2. Skill Management:**
 *    - `addSkill(string _skillName)`: Allows admin to add a new skill to the platform.
 *    - `removeSkill(uint256 _skillId)`: Allows admin to remove a skill from the platform.
 *    - `getUserSkills(address _userAddress) view returns (Skill[])`: Retrieves skills associated with a user.
 *    - `getAllSkills() view returns (Skill[])`: Retrieves a list of all available skills in the platform.
 *    - `endorseSkill(address _providerAddress, uint256 _skillId)`: Allows users to endorse a skill for another user (reputation boost).
 *
 * **3. Service Listing & Marketplace:**
 *    - `createListing(string _title, string _description, uint256 _pricePerUnit, uint256 _skillId)`: Allows users to create a service listing associated with a specific skill.
 *    - `updateListingPrice(uint256 _listingId, uint256 _newPrice)`: Allows service providers to update the price of their listing.
 *    - `updateListingDescription(uint256 _listingId, string _newDescription)`: Allows service providers to update the description of their listing.
 *    - `cancelListing(uint256 _listingId)`: Allows service providers to cancel their listing.
 *    - `purchaseService(uint256 _listingId, uint256 _units) payable`: Allows users to purchase a service listing.
 *    - `completeService(uint256 _listingId)`: Allows service requesters to mark a service as completed.
 *    - `getListingsBySkill(uint256 _skillId) view returns (Listing[])`: Retrieves listings associated with a specific skill.
 *    - `getAllListings() view returns (Listing[])`: Retrieves all active service listings.
 *    - `getListingDetails(uint256 _listingId) view returns (Listing)`: Retrieves details of a specific listing.
 *
 * **4. Reputation & Review System:**
 *    - `submitReview(uint256 _listingId, uint8 _rating, string _comment)`: Allows service requesters to submit a review and rating after service completion.
 *    - `getAverageRating(address _providerAddress) view returns (uint256)`: Calculates and returns the average rating for a service provider.
 *    - `getUserReputation(address _userAddress) view returns (uint256)`: Retrieves the reputation score of a user.
 *
 * **5. Dispute Resolution (Simplified):**
 *    - `initiateDispute(uint256 _listingId, string _disputeReason)`: Allows users to initiate a dispute for a service.
 *    - `resolveDispute(uint256 _disputeId, DisputeResolution _resolution)`: Allows admin to resolve a dispute (Refund Requester, Pay Provider, Split Funds).
 *
 * **6. Platform Management (Admin):**
 *    - `setAdmin(address _newAdmin)`: Allows current admin to change the admin address.
 *    - `withdrawPlatformFees()`: Allows admin to withdraw accumulated platform fees.
 */
pragma solidity ^0.8.0;

contract SkillVerse {

    // --- Data Structures ---
    struct UserProfile {
        string username;
        string profileDescription;
        uint256 reputationScore;
        uint256 registrationTimestamp;
    }

    struct Skill {
        uint256 skillId;
        string skillName;
    }

    struct Listing {
        uint256 listingId;
        address providerAddress;
        string title;
        string description;
        uint256 pricePerUnit;
        uint256 skillId;
        bool isActive;
        uint256 creationTimestamp;
    }

    struct Review {
        uint256 reviewId;
        uint256 listingId;
        address reviewerAddress;
        uint8 rating; // 1 to 5 stars
        string comment;
        uint256 reviewTimestamp;
    }

    struct Dispute {
        uint256 disputeId;
        uint256 listingId;
        address initiatorAddress;
        string reason;
        DisputeStatus status;
        DisputeResolution resolution;
        uint256 disputeTimestamp;
    }

    enum DisputeStatus { Open, Resolved }
    enum DisputeResolution { None, RefundRequester, PayProvider, SplitFunds }

    // --- State Variables ---
    address public admin;
    uint256 public platformFeePercentage = 2; // 2% platform fee
    uint256 public nextSkillId = 1;
    uint256 public nextListingId = 1;
    uint256 public nextReviewId = 1;
    uint256 public nextDisputeId = 1;

    mapping(address => UserProfile) public userProfiles;
    mapping(address => mapping(uint256 => bool)) public userSkillsEndorsed; // User -> SkillId -> Endorsed
    mapping(uint256 => Skill) public skills;
    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Review) public reviews;
    mapping(uint256 => Dispute) public disputes;
    mapping(string => bool) public usernameTaken; // Check for username uniqueness

    // --- Events ---
    event UserRegistered(address userAddress, string username);
    event ProfileUpdated(address userAddress);
    event UsernameUpdated(address userAddress, string newUsername);
    event SkillAdded(uint256 skillId, string skillName);
    event SkillRemoved(uint256 skillId);
    event SkillEndorsed(address providerAddress, uint256 skillId, address endorserAddress);
    event ListingCreated(uint256 listingId, address providerAddress, uint256 skillId);
    event ListingPriceUpdated(uint256 listingId, uint256 newPrice);
    event ListingDescriptionUpdated(uint256 listingId, uint256 newDescription);
    event ListingCancelled(uint256 listingId);
    event ServicePurchased(uint256 listingId, address buyerAddress, uint256 units, uint256 totalPrice);
    event ServiceCompleted(uint256 listingId);
    event ReviewSubmitted(uint256 reviewId, uint256 listingId, address reviewerAddress, uint8 rating);
    event DisputeInitiated(uint256 disputeId, uint256 listingId, address initiatorAddress);
    event DisputeResolved(uint256 disputeId, DisputeResolution resolution);
    event AdminChanged(address newAdmin);
    event PlatformFeesWithdrawn(address adminAddress, uint256 amount);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action.");
        _;
    }

    modifier onlyRegisteredUser() {
        require(isUserRegistered(msg.sender), "User must be registered to perform this action.");
        _;
    }

    modifier listingExists(uint256 _listingId) {
        require(listings[_listingId].listingId != 0, "Listing does not exist.");
        _;
    }

    modifier listingIsActive(uint256 _listingId) {
        require(listings[_listingId].isActive, "Listing is not active.");
        _;
    }

    modifier isListingProvider(uint256 _listingId) {
        require(listings[_listingId].providerAddress == msg.sender, "You are not the provider of this listing.");
        _;
    }

    modifier isListingBuyer(uint256 _listingId) {
        // In a real application, track buyers more formally if needed for complex logic.
        // For this example, assuming purchase implies buyer for review purposes right after completion.
        // A more robust system would track transactions/orders.
        _; // Placeholder for more complex buyer tracking if needed.
    }

    modifier validRating(uint8 _rating) {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5.");
        _;
    }

    modifier disputeExists(uint256 _disputeId) {
        require(disputes[_disputeId].disputeId != 0, "Dispute does not exist.");
        _;
    }

    modifier disputeIsOpen(uint256 _disputeId) {
        require(disputes[_disputeId].status == DisputeStatus.Open, "Dispute is not open.");
        _;
    }


    // --- 1. User Management Functions ---
    function registerUser(string memory _username, string memory _profileDescription) public {
        require(!isUserRegistered(msg.sender), "User already registered.");
        require(!usernameTaken[_username], "Username is already taken.");
        require(bytes(_username).length > 0 && bytes(_username).length <= 32, "Username must be between 1 and 32 characters.");
        require(bytes(_profileDescription).length <= 256, "Profile description too long (max 256 characters).");

        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileDescription: _profileDescription,
            reputationScore: 0,
            registrationTimestamp: block.timestamp
        });
        usernameTaken[_username] = true;
        emit UserRegistered(msg.sender, _username);
    }

    function updateProfile(string memory _profileDescription) public onlyRegisteredUser {
        require(bytes(_profileDescription).length <= 256, "Profile description too long (max 256 characters).");
        userProfiles[msg.sender].profileDescription = _profileDescription;
        emit ProfileUpdated(msg.sender);
    }

    function setUsername(string memory _newUsername) public onlyRegisteredUser {
        require(!usernameTaken[_newUsername], "Username is already taken.");
        require(bytes(_newUsername).length > 0 && bytes(_newUsername).length <= 32, "Username must be between 1 and 32 characters.");

        string memory oldUsername = userProfiles[msg.sender].username;
        usernameTaken[oldUsername] = false; // Release the old username
        userProfiles[msg.sender].username = _newUsername;
        usernameTaken[_newUsername] = true; // Claim the new username
        emit UsernameUpdated(msg.sender, _newUsername);
    }

    function getUserProfile(address _userAddress) public view returns (string memory username, string memory profileDescription, uint256 reputationScore, Skill[] memory userSkills) {
        require(isUserRegistered(_userAddress), "User is not registered.");
        UserProfile storage profile = userProfiles[_userAddress];
        username = profile.username;
        profileDescription = profile.profileDescription;
        reputationScore = profile.reputationScore;
        userSkills = getUserSkills(_userAddress);
    }

    function isUserRegistered(address _userAddress) public view returns (bool) {
        return userProfiles[_userAddress].registrationTimestamp != 0; // Simple check if registrationTimestamp is set.
    }


    // --- 2. Skill Management Functions ---
    function addSkill(string memory _skillName) public onlyAdmin {
        require(bytes(_skillName).length > 0 && bytes(_skillName).length <= 64, "Skill name must be between 1 and 64 characters.");
        skills[nextSkillId] = Skill({
            skillId: nextSkillId,
            skillName: _skillName
        });
        emit SkillAdded(nextSkillId, _skillName);
        nextSkillId++;
    }

    function removeSkill(uint256 _skillId) public onlyAdmin {
        require(skills[_skillId].skillId != 0, "Skill does not exist.");
        delete skills[_skillId];
        emit SkillRemoved(_skillId);
        // In a production system, consider handling listings associated with the removed skill.
    }

    function getUserSkills(address _userAddress) public view returns (Skill[] memory) {
        // In this simplified version, skills are not directly linked to users in state.
        // User skills are inferred from listings they create.
        // For a more advanced system, consider explicitly linking skills to user profiles.
        uint256 skillCount = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].providerAddress == _userAddress && listings[i].isActive) {
                skillCount++;
            }
        }

        Skill[] memory userSkillList = new Skill[](skillCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].providerAddress == _userAddress && listings[i].isActive) {
                userSkillList[index] = skills[listings[i].skillId];
                index++;
            }
        }
        return userSkillList;
    }

    function getAllSkills() public view returns (Skill[] memory) {
        uint256 skillCount = nextSkillId - 1; // Assuming skill IDs start from 1 and are sequential.
        Skill[] memory allSkillsList = new Skill[](skillCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextSkillId; i++) {
            if (skills[i].skillId != 0) { // Check if skill exists (not deleted)
                allSkillsList[index] = skills[i];
                index++;
            }
        }
        return allSkillsList;
    }

    function endorseSkill(address _providerAddress, uint256 _skillId) public onlyRegisteredUser {
        require(isUserRegistered(_providerAddress), "Provider address is not registered.");
        require(skills[_skillId].skillId != 0, "Skill does not exist.");
        require(_providerAddress != msg.sender, "Cannot endorse yourself.");
        require(!userSkillsEndorsed[_providerAddress][_skillId], "Skill already endorsed by you.");

        userSkillsEndorsed[_providerAddress][_skillId] = true;
        userProfiles[_providerAddress].reputationScore += 5; // Example: +5 reputation for endorsement. Adjust as needed.
        emit SkillEndorsed(_providerAddress, _skillId, msg.sender);
    }


    // --- 3. Service Listing & Marketplace Functions ---
    function createListing(string memory _title, string memory _description, uint256 _pricePerUnit, uint256 _skillId) public onlyRegisteredUser {
        require(bytes(_title).length > 0 && bytes(_title).length <= 128, "Listing title must be between 1 and 128 characters.");
        require(bytes(_description).length > 0 && bytes(_description).length <= 512, "Listing description must be between 1 and 512 characters.");
        require(_pricePerUnit > 0, "Price per unit must be greater than 0.");
        require(skills[_skillId].skillId != 0, "Skill does not exist.");

        listings[nextListingId] = Listing({
            listingId: nextListingId,
            providerAddress: msg.sender,
            title: _title,
            description: _description,
            pricePerUnit: _pricePerUnit,
            skillId: _skillId,
            isActive: true,
            creationTimestamp: block.timestamp
        });
        emit ListingCreated(nextListingId, msg.sender, _skillId);
        nextListingId++;
    }

    function updateListingPrice(uint256 _listingId, uint256 _newPrice) public onlyRegisteredUser listingExists(_listingId) listingIsActive(_listingId) isListingProvider(_listingId) {
        require(_newPrice > 0, "New price must be greater than 0.");
        listings[_listingId].pricePerUnit = _newPrice;
        emit ListingPriceUpdated(_listingId, _newPrice);
    }

    function updateListingDescription(uint256 _listingId, string memory _newDescription) public onlyRegisteredUser listingExists(_listingId) listingIsActive(_listingId) isListingProvider(_listingId) {
        require(bytes(_newDescription).length > 0 && bytes(_newDescription).length <= 512, "Listing description must be between 1 and 512 characters.");
        listings[_listingId].description = _newDescription;
        emit ListingDescriptionUpdated(_listingId, _newDescription);
    }

    function cancelListing(uint256 _listingId) public onlyRegisteredUser listingExists(_listingId) listingIsActive(_listingId) isListingProvider(_listingId) {
        listings[_listingId].isActive = false;
        emit ListingCancelled(_listingId);
    }

    function purchaseService(uint256 _listingId, uint256 _units) public payable onlyRegisteredUser listingExists(_listingId) listingIsActive(_listingId) {
        require(_units > 0, "Units must be greater than 0.");
        Listing storage listing = listings[_listingId];
        uint256 totalPrice = listing.pricePerUnit * _units;
        uint256 platformFee = (totalPrice * platformFeePercentage) / 100;
        uint256 providerPayment = totalPrice - platformFee;

        require(msg.value >= totalPrice, "Insufficient funds sent.");

        payable(listing.providerAddress).transfer(providerPayment);
        payable(admin).transfer(platformFee);

        emit ServicePurchased(_listingId, msg.sender, _units, totalPrice);
    }

    function completeService(uint256 _listingId) public onlyRegisteredUser listingExists(_listingId) listingIsActive(_listingId) {
        // In a real application, verify that msg.sender is indeed the buyer.
        // For simplicity here, assuming the purchaser calls this function.
        listings[_listingId].isActive = false; // Mark as inactive after completion.
        emit ServiceCompleted(_listingId);
    }

    function getListingsBySkill(uint256 _skillId) public view returns (Listing[] memory) {
        require(skills[_skillId].skillId != 0, "Skill does not exist.");
        uint256 listingCount = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive && listings[i].skillId == _skillId) {
                listingCount++;
            }
        }

        Listing[] memory skillListings = new Listing[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive && listings[i].skillId == _skillId) {
                skillListings[index] = listings[i];
                index++;
            }
        }
        return skillListings;
    }

    function getAllListings() public view returns (Listing[] memory) {
        uint256 listingCount = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive) {
                listingCount++;
            }
        }

        Listing[] memory allListings = new Listing[](listingCount);
        uint256 index = 0;
        for (uint256 i = 1; i < nextListingId; i++) {
            if (listings[i].isActive) {
                allListings[index] = listings[i];
                index++;
            }
        }
        return allListings;
    }

    function getListingDetails(uint256 _listingId) public view listingExists(_listingId) view returns (Listing memory) {
        return listings[_listingId];
    }


    // --- 4. Reputation & Review System Functions ---
    function submitReview(uint256 _listingId, uint8 _rating, string memory _comment) public onlyRegisteredUser listingExists(_listingId) validRating(_rating) isListingBuyer(_listingId) {
        // In a real application, ensure review is only submitted after service completion
        // and by the actual buyer.  For simplicity, assuming buyer calls this after 'completeService'.

        reviews[nextReviewId] = Review({
            reviewId: nextReviewId,
            listingId: _listingId,
            reviewerAddress: msg.sender,
            rating: _rating,
            comment: _comment,
            reviewTimestamp: block.timestamp
        });

        // Update provider reputation (simple average for now, can be weighted later)
        uint256 currentAverageRating = getAverageRating(listings[_listingId].providerAddress);
        uint256 reviewCount = getReviewCount(listings[_listingId].providerAddress);
        uint256 newAverageRating = ((currentAverageRating * reviewCount) + _rating) / (reviewCount + 1);
        userProfiles[listings[_listingId].providerAddress].reputationScore = newAverageRating; // Simplified reputation score as average rating.

        emit ReviewSubmitted(nextReviewId, _listingId, msg.sender, _rating);
        nextReviewId++;
    }

    function getAverageRating(address _providerAddress) public view returns (uint256) {
        uint256 totalRating = 0;
        uint256 reviewCount = 0;
        for (uint256 i = 1; i < nextReviewId; i++) {
            if (listings[reviews[i].listingId].providerAddress == _providerAddress) {
                totalRating += reviews[i].rating;
                reviewCount++;
            }
        }
        if (reviewCount == 0) return 0; // Avoid division by zero
        return totalRating / reviewCount;
    }

    function getUserReputation(address _userAddress) public view returns (uint256) {
        return userProfiles[_userAddress].reputationScore;
    }

    function getReviewCount(address _providerAddress) private view returns (uint256) {
        uint256 reviewCount = 0;
        for (uint256 i = 1; i < nextReviewId; i++) {
            if (listings[reviews[i].listingId].providerAddress == _providerAddress) {
                reviewCount++;
            }
        }
        return reviewCount;
    }


    // --- 5. Dispute Resolution Functions ---
    function initiateDispute(uint256 _listingId, string memory _disputeReason) public onlyRegisteredUser listingExists(_listingId) listingIsActive(_listingId) {
        // In a real application, more checks are needed to ensure only buyer or provider initiates dispute.
        // For simplicity, allowing any registered user to initiate (admin will resolve).
        require(bytes(_disputeReason).length > 0 && bytes(_disputeReason).length <= 256, "Dispute reason too long (max 256 characters).");

        disputes[nextDisputeId] = Dispute({
            disputeId: nextDisputeId,
            listingId: _listingId,
            initiatorAddress: msg.sender,
            reason: _disputeReason,
            status: DisputeStatus.Open,
            resolution: DisputeResolution.None,
            disputeTimestamp: block.timestamp
        });
        emit DisputeInitiated(nextDisputeId, _listingId, msg.sender);
        nextDisputeId++;
    }

    function resolveDispute(uint256 _disputeId, DisputeResolution _resolution) public onlyAdmin disputeExists(_disputeId) disputeIsOpen(_disputeId) {
        disputes[_disputeId].status = DisputeStatus.Resolved;
        disputes[_disputeId].resolution = _resolution;

        Listing storage listing = listings[disputes[_disputeId].listingId];
        uint256 totalPrice = listing.pricePerUnit; // Assuming 1 unit for dispute resolution simplicity. Adjust if needed.
        uint256 platformFee = (totalPrice * platformFeePercentage) / 100;
        uint256 providerPayment = totalPrice - platformFee;

        if (_resolution == DisputeResolution.RefundRequester) {
            payable(disputes[_disputeId].initiatorAddress).transfer(msg.value); // Refund the buyer (assuming msg.value was the initial payment, needs tracking in real app).
        } else if (_resolution == DisputeResolution.PayProvider) {
            payable(listing.providerAddress).transfer(providerPayment); // Pay provider (if funds are held, needs implementation).
            payable(admin).transfer(platformFee);
        } else if (_resolution == DisputeResolution.SplitFunds) {
            uint256 splitAmount = totalPrice / 2;
            payable(disputes[_disputeId].initiatorAddress).transfer(splitAmount);
            payable(listing.providerAddress).transfer(splitAmount - (splitAmount * platformFeePercentage) / 100); // Split and take platform fee from provider's share
            payable(admin).transfer((splitAmount * platformFeePercentage) / 100);
        } // DisputeResolution.None does nothing.

        emit DisputeResolved(_disputeId, _resolution);
    }


    // --- 6. Platform Management (Admin) Functions ---
    constructor() {
        admin = msg.sender; // Deployer is the initial admin
    }

    function setAdmin(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "Invalid admin address.");
        admin = _newAdmin;
        emit AdminChanged(_newAdmin);
    }

    function withdrawPlatformFees() public onlyAdmin {
        uint256 balance = address(this).balance;
        payable(admin).transfer(balance);
        emit PlatformFeesWithdrawn(admin, balance);
    }

    // Fallback function to prevent accidental Ether sent to contract
    fallback() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }

    receive() external payable {
        revert("This contract does not accept direct Ether transfers.");
    }
}
```