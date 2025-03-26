```solidity
/**
 * @title Personalized Learning Platform Smart Contract
 * @author Bard (Example - Not for Production)
 * @dev A smart contract for a decentralized personalized learning platform.
 *
 * **Outline & Function Summary:**
 *
 * **1. User Management:**
 *    - `registerLearner(string _username, string _profileHash)`: Allows learners to register on the platform.
 *    - `registerInstructor(string _username, string _profileHash)`: Allows instructors to register.
 *    - `updateLearnerProfile(string _profileHash)`: Learners can update their profile information.
 *    - `updateInstructorProfile(string _profileHash)`: Instructors can update their profile information.
 *    - `getUserProfile(address _userAddress)`: Retrieves user profile information (learner or instructor).
 *
 * **2. Course Management:**
 *    - `createCourse(string _title, string _description, string _metadataHash, uint256 _basePrice)`: Instructors can create new courses.
 *    - `addModuleToCourse(uint256 _courseId, string _moduleTitle, string _moduleDescription, string _moduleContentHash)`: Instructors can add modules to their courses.
 *    - `updateCourseMetadata(uint256 _courseId, string _metadataHash)`: Instructors can update course metadata.
 *    - `updateModuleContent(uint256 _courseId, uint256 _moduleId, string _contentHash)`: Instructors can update module content.
 *    - `setCoursePrice(uint256 _courseId, uint256 _newPrice)`: Instructors can change the price of their courses.
 *    - `getCourseDetails(uint256 _courseId)`: Retrieves detailed information about a specific course.
 *    - `getModuleDetails(uint256 _courseId, uint256 _moduleId)`: Retrieves details about a specific module within a course.
 *
 * **3. Learning & Enrollment:**
 *    - `enrollInCourse(uint256 _courseId)`: Learners can enroll in a course, paying the course price.
 *    - `completeModule(uint256 _courseId, uint256 _moduleId)`: Learners can mark a module as completed.
 *    - `getLearnerCourses(address _learnerAddress)`: Retrieves a list of courses a learner is enrolled in.
 *    - `getCourseLearners(uint256 _courseId)`: Retrieves a list of learners enrolled in a specific course.
 *    - `getLearnerProgress(uint256 _courseId, address _learnerAddress)`: Retrieves a learner's progress in a specific course (modules completed).
 *
 * **4. Reputation & Incentives (Advanced Concepts):**
 *    - `rateInstructor(address _instructorAddress, uint8 _rating, string _reviewHash)`: Learners can rate and review instructors.
 *    - `getInstructorRating(address _instructorAddress)`: Retrieves the average rating and review count for an instructor.
 *    - `awardCertificateNFT(uint256 _courseId, address _learnerAddress)`: Upon course completion, awards a unique NFT certificate to the learner.
 *
 * **5. Platform Features (Creative & Trendy):**
 *    - `recommendCourses(address _learnerAddress)`: (Conceptual - off-chain logic needed) Returns recommended courses based on learner profile/history.
 *    - `sponsorCourse(uint256 _courseId)`: Allows anyone to sponsor a course, reducing its price or offering scholarships.
 *    - `giftCourseEnrollment(uint256 _courseId, address _recipientAddress)`: Allows users to gift course enrollments to others.
 *    - `createLearningPath(string _pathName, string _pathDescription, uint256[] _courseIds)`: Instructors or platform admins can create curated learning paths from existing courses.
 *    - `getLearningPathCourses(uint256 _pathId)`: Retrieves the courses within a specific learning path.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PersonalizedLearningPlatform is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _courseIds;
    Counters.Counter private _moduleIds;
    Counters.Counter private _certificateIds;
    Counters.Counter private _learningPathIds;

    // --- Structs ---
    struct UserProfile {
        string username;
        string profileHash; // IPFS hash or similar for detailed profile
        bool isInstructor;
        bool registered;
    }

    struct Course {
        uint256 courseId;
        address instructor;
        string title;
        string description;
        string metadataHash; // IPFS hash for course details, syllabus, etc.
        uint256 basePrice;
        uint256 moduleCount;
        bool isActive;
    }

    struct Module {
        uint256 moduleId;
        string title;
        string description;
        string contentHash; // IPFS hash for module content
        bool isCompleted;
    }

    struct InstructorRating {
        uint256 ratingSum;
        uint256 ratingCount;
    }

    struct LearningPath {
        uint256 pathId;
        string name;
        string description;
        uint256[] courseIds;
    }

    // --- Mappings ---
    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => Course) public courses;
    mapping(uint256 => mapping(uint256 => Module)) public courseModules; // courseId => moduleId => Module
    mapping(uint256 => address[]) public courseLearners; // courseId => array of learner addresses
    mapping(address => mapping(uint256 => bool[])) public learnerCourseProgress; // learnerAddress => courseId => array of module completion statuses
    mapping(address => InstructorRating) public instructorRatings;
    mapping(uint256 => LearningPath) public learningPaths;

    // --- Events ---
    event LearnerRegistered(address learnerAddress, string username);
    event InstructorRegistered(address instructorAddress, string username);
    event ProfileUpdated(address userAddress);
    event CourseCreated(uint256 courseId, address instructor, string title);
    event ModuleAdded(uint256 courseId, uint256 moduleId, string moduleTitle);
    event CoursePriceUpdated(uint256 courseId, uint256 newPrice);
    event LearnerEnrolled(address learnerAddress, uint256 courseId);
    event ModuleCompleted(address learnerAddress, uint256 courseId, uint256 moduleId);
    event InstructorRated(address instructorAddress, address learnerAddress, uint8 rating);
    event CertificateAwarded(uint256 certificateId, uint256 courseId, address learnerAddress);
    event CourseSponsored(uint256 courseId, address sponsorAddress, uint256 sponsorshipAmount);
    event CourseGifted(uint256 courseId, address fromAddress, address toAddress);
    event LearningPathCreated(uint256 pathId, string pathName);

    constructor() ERC721("PersonalizedLearningCertificate", "PLCERT") Ownable() {
        // Initialize contract if needed
    }

    // --- 1. User Management ---

    function registerLearner(string memory _username, string memory _profileHash) public {
        require(!userProfiles[msg.sender].registered, "Learner already registered");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            isInstructor: false,
            registered: true
        });
        emit LearnerRegistered(msg.sender, _username);
    }

    function registerInstructor(string memory _username, string memory _profileHash) public {
        require(!userProfiles[msg.sender].registered, "Instructor already registered");
        userProfiles[msg.sender] = UserProfile({
            username: _username,
            profileHash: _profileHash,
            isInstructor: true,
            registered: true
        });
        emit InstructorRegistered(msg.sender, _username);
    }

    function updateLearnerProfile(string memory _profileHash) public {
        require(userProfiles[msg.sender].registered && !userProfiles[msg.sender].isInstructor, "Learner not registered or is instructor");
        userProfiles[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender);
    }

    function updateInstructorProfile(string memory _profileHash) public {
        require(userProfiles[msg.sender].registered && userProfiles[msg.sender].isInstructor, "Instructor not registered or is learner");
        userProfiles[msg.sender].profileHash = _profileHash;
        emit ProfileUpdated(msg.sender);
    }

    function getUserProfile(address _userAddress) public view returns (UserProfile memory) {
        return userProfiles[_userAddress];
    }

    // --- 2. Course Management ---

    function createCourse(
        string memory _title,
        string memory _description,
        string memory _metadataHash,
        uint256 _basePrice
    ) public onlyInstructor {
        _courseIds.increment();
        uint256 courseId = _courseIds.current();
        courses[courseId] = Course({
            courseId: courseId,
            instructor: msg.sender,
            title: _title,
            description: _description,
            metadataHash: _metadataHash,
            basePrice: _basePrice,
            moduleCount: 0,
            isActive: true
        });
        emit CourseCreated(courseId, msg.sender, _title);
    }

    function addModuleToCourse(
        uint256 _courseId,
        string memory _moduleTitle,
        string memory _moduleDescription,
        string memory _moduleContentHash
    ) public onlyInstructorOfCourse(_courseId) {
        require(courses[_courseId].isActive, "Course is not active");
        _moduleIds.increment();
        uint256 moduleId = _moduleIds.current();
        courseModules[_courseId][courses[_courseId].moduleCount] = Module({
            moduleId: moduleId,
            title: _moduleTitle,
            description: _moduleDescription,
            contentHash: _moduleContentHash,
            isCompleted: false
        });
        courses[_courseId].moduleCount++;
        emit ModuleAdded(_courseId, moduleId, _moduleTitle);
    }

    function updateCourseMetadata(uint256 _courseId, string memory _metadataHash) public onlyInstructorOfCourse(_courseId) {
        courses[_courseId].metadataHash = _metadataHash;
    }

    function updateModuleContent(uint256 _courseId, uint256 _moduleId, string memory _contentHash) public onlyInstructorOfCourse(_courseId) {
        require(_moduleId < courses[_courseId].moduleCount, "Invalid module ID");
        courseModules[_courseId][_moduleId].contentHash = _contentHash;
    }

    function setCoursePrice(uint256 _courseId, uint256 _newPrice) public onlyInstructorOfCourse(_courseId) {
        courses[_courseId].basePrice = _newPrice;
        emit CoursePriceUpdated(_courseId, _newPrice);
    }

    function getCourseDetails(uint256 _courseId) public view returns (Course memory) {
        require(courses[_courseId].courseId == _courseId, "Course does not exist"); // Basic existence check
        return courses[_courseId];
    }

    function getModuleDetails(uint256 _courseId, uint256 _moduleId) public view returns (Module memory) {
        require(_moduleId < courses[_courseId].moduleCount, "Invalid module ID");
        return courseModules[_courseId][_moduleId];
    }

    // --- 3. Learning & Enrollment ---

    function enrollInCourse(uint256 _courseId) public payable onlyLearner {
        require(courses[_courseId].isActive, "Course is not active");
        require(msg.value >= courses[_courseId].basePrice, "Insufficient payment");
        bool alreadyEnrolled = false;
        for (uint256 i = 0; i < courseLearners[_courseId].length; i++) {
            if (courseLearners[_courseId][i] == msg.sender) {
                alreadyEnrolled = true;
                break;
            }
        }
        require(!alreadyEnrolled, "Already enrolled in this course");

        courseLearners[_courseId].push(msg.sender);
        learnerCourseProgress[msg.sender][_courseId] = new bool[](courses[_courseId].moduleCount); // Initialize progress array
        payable(courses[_courseId].instructor).transfer(msg.value); // Transfer payment to instructor
        emit LearnerEnrolled(msg.sender, _courseId);
    }

    function completeModule(uint256 _courseId, uint256 _moduleId) public onlyLearnerEnrolledInCourse(_courseId) {
        require(_moduleId < courses[_courseId].moduleCount, "Invalid module ID");
        require(!learnerCourseProgress[msg.sender][_courseId][_moduleId], "Module already completed");
        learnerCourseProgress[msg.sender][_courseId][_moduleId] = true;
        emit ModuleCompleted(msg.sender, _courseId, _moduleId);

        // Check for course completion and award certificate NFT
        bool courseCompleted = true;
        for (uint256 i = 0; i < courses[_courseId].moduleCount; i++) {
            if (!learnerCourseProgress[msg.sender][_courseId][i]) {
                courseCompleted = false;
                break;
            }
        }
        if (courseCompleted) {
            awardCertificateNFT(_courseId, msg.sender);
        }
    }

    function getLearnerCourses(address _learnerAddress) public view onlyRegisteredUser returns (uint256[] memory) {
        uint256[] memory enrolledCourseIds = new uint256[](0);
        for (uint256 courseId = 1; courseId <= _courseIds.current(); courseId++) {
            bool enrolled = false;
            for (uint256 i = 0; i < courseLearners[courseId].length; i++) {
                if (courseLearners[courseId][i] == _learnerAddress) {
                    enrolled = true;
                    break;
                }
            }
            if (enrolled) {
                uint256[] memory tempArray = new uint256[](enrolledCourseIds.length + 1);
                for(uint256 i = 0; i < enrolledCourseIds.length; i++){
                    tempArray[i] = enrolledCourseIds[i];
                }
                tempArray[enrolledCourseIds.length] = courseId;
                enrolledCourseIds = tempArray;
            }
        }
        return enrolledCourseIds;
    }

    function getCourseLearners(uint256 _courseId) public view returns (address[] memory) {
        return courseLearners[_courseId];
    }

    function getLearnerProgress(uint256 _courseId, address _learnerAddress) public view onlyLearnerEnrolledInCourse(_courseId) returns (bool[] memory) {
        return learnerCourseProgress[_learnerAddress][_courseId];
    }

    // --- 4. Reputation & Incentives ---

    function rateInstructor(address _instructorAddress, uint8 _rating, string memory _reviewHash) public onlyLearner {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(userProfiles[_instructorAddress].isInstructor, "Target address is not an instructor");

        InstructorRating storage ratingData = instructorRatings[_instructorAddress];
        ratingData.ratingSum += _rating;
        ratingData.ratingCount++;
        emit InstructorRated(_instructorAddress, msg.sender, _rating);
        // Consider storing reviewHash for public reviews (optional)
    }

    function getInstructorRating(address _instructorAddress) public view returns (uint256 averageRating, uint256 reviewCount) {
        InstructorRating memory ratingData = instructorRatings[_instructorAddress];
        if (ratingData.ratingCount == 0) {
            return (0, 0);
        }
        averageRating = ratingData.ratingSum / ratingData.ratingCount;
        reviewCount = ratingData.ratingCount;
    }

    function awardCertificateNFT(uint256 _courseId, address _learnerAddress) internal {
        _certificateIds.increment();
        uint256 certificateId = _certificateIds.current();
        _mint(_learnerAddress, certificateId);
        _setTokenURI(certificateId, string(abi.encodePacked("ipfs://certificateMetadata_", Strings.toString(certificateId)))); // Example metadata URI
        emit CertificateAwarded(certificateId, _courseId, _learnerAddress);
    }


    // --- 5. Platform Features ---

    // Conceptual - Requires off-chain logic for recommendation engine based on user data
    function recommendCourses(address _learnerAddress) public view onlyLearner returns (uint256[] memory) {
        // In a real application, this would involve fetching learner profile data and using an off-chain service
        // to generate course recommendations based on skills, history, etc.
        // This is a placeholder - for demonstration, let's just return the first 3 courses if they exist.
        uint256[] memory recommendedCourseIds = new uint256[](0);
        uint256 count = 0;
        for (uint256 courseId = 1; courseId <= _courseIds.current() && count < 3; courseId++) {
            recommendedCourseIds = _arrayPush(recommendedCourseIds, courseId);
            count++;
        }
        return recommendedCourseIds;
    }

    function sponsorCourse(uint256 _courseId) public payable {
        require(courses[_courseId].isActive, "Course is not active");
        uint256 sponsorshipAmount = msg.value;
        // Logic to handle sponsorship - e.g., reduce course price, offer scholarships, etc.
        // For simplicity, let's just emit an event and potentially store sponsorship info (not implemented in detail here)
        emit CourseSponsored(_courseId, msg.sender, sponsorshipAmount);
        // In a real system, you might want to track sponsorships and adjust course prices dynamically.
    }

    function giftCourseEnrollment(uint256 _courseId, address _recipientAddress) public payable onlyLearner {
        require(courses[_courseId].isActive, "Course is not active");
        require(msg.value >= courses[_courseId].basePrice, "Insufficient payment for gift");
        require(userProfiles[_recipientAddress].registered && !userProfiles[_recipientAddress].isInstructor, "Recipient must be a registered learner");

        bool alreadyEnrolled = false;
        for (uint256 i = 0; i < courseLearners[_courseId].length; i++) {
            if (courseLearners[_courseId][i] == _recipientAddress) {
                alreadyEnrolled = true;
                break;
            }
        }
        require(!alreadyEnrolled, "Recipient already enrolled in this course");

        courseLearners[_courseId].push(_recipientAddress);
        learnerCourseProgress[_recipientAddress][_courseId] = new bool[](courses[_courseId].moduleCount); // Initialize progress array
        payable(courses[_courseId].instructor).transfer(msg.value);
        emit CourseGifted(_courseId, msg.sender, _recipientAddress);
        emit LearnerEnrolled(_recipientAddress, _courseId); // Recipient also gets LearnerEnrolled event
    }

    function createLearningPath(
        string memory _pathName,
        string memory _pathDescription,
        uint256[] memory _courseIds
    ) public onlyInstructor { // Or allow platform admins to create paths
        _learningPathIds.increment();
        uint256 pathId = _learningPathIds.current();
        learningPaths[pathId] = LearningPath({
            pathId: pathId,
            name: _pathName,
            description: _pathDescription,
            courseIds: _courseIds
        });
        emit LearningPathCreated(pathId, _pathName);
    }

    function getLearningPathCourses(uint256 _pathId) public view returns (uint256[] memory) {
        return learningPaths[_pathId].courseIds;
    }


    // --- Modifiers ---

    modifier onlyRegisteredUser() {
        require(userProfiles[msg.sender].registered, "User not registered");
        _;
    }

    modifier onlyLearner() {
        require(userProfiles[msg.sender].registered && !userProfiles[msg.sender].isInstructor, "Only learners allowed");
        _;
    }

    modifier onlyInstructor() {
        require(userProfiles[msg.sender].registered && userProfiles[msg.sender].isInstructor, "Only instructors allowed");
        _;
    }

    modifier onlyInstructorOfCourse(uint256 _courseId) {
        require(courses[_courseId].instructor == msg.sender, "Only course instructor allowed");
        _;
    }

    modifier onlyLearnerEnrolledInCourse(uint256 _courseId) {
        bool enrolled = false;
        for (uint256 i = 0; i < courseLearners[_courseId].length; i++) {
            if (courseLearners[_courseId][i] == msg.sender) {
                enrolled = true;
                break;
            }
        }
        require(enrolled, "Learner not enrolled in this course");
        _;
    }

    // --- Helper Functions ---

    function _arrayPush(uint256[] memory _array, uint256 _value) internal pure returns (uint256[] memory) {
        uint256[] memory tempArray = new uint256[](_array.length + 1);
        for(uint256 i = 0; i < _array.length; i++){
            tempArray[i] = _array[i];
        }
        tempArray[_array.length] = _value;
        return tempArray;
    }

    // Override isApprovedForAll to prevent blanket approvals for certificates (optional security measure)
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return (operator == owner()); // Only owner can be approved for all, or customize logic as needed.
    }

    // --- String conversion for NFT metadata (using OpenZeppelin Strings library - import required if you use it in metadata URI) ---
    // You might need to install: `npm install @openzeppelin/contracts`
    import "@openzeppelin/contracts/utils/Strings.sol";
    using Strings for uint256;
}
```