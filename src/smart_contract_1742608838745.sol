```solidity
/**
 * @title Decentralized Reputation and Skill Marketplace
 * @author Bard (AI Assistant)
 * @dev A smart contract for managing decentralized reputation based on skills and facilitating a skill-based marketplace.
 *
 * **Contract Outline:**
 *
 * **1. Skill Management:**
 *    - addSkill(string _skillName, string _skillDescription): Allows admin to add new skills to the platform.
 *    - removeSkill(uint256 _skillId): Allows admin to remove skills from the platform.
 *    - updateSkillDescription(uint256 _skillId, string _newDescription): Allows admin to update skill descriptions.
 *    - getSkillById(uint256 _skillId): Retrieves skill details by ID.
 *    - getSkillCount(): Returns the total number of skills registered.
 *    - getAllSkills(): Returns a list of all registered skill IDs.
 *
 * **2. Reputation System:**
 *    - awardReputation(address _user, uint256 _skillId, uint256 _amount): Allows admin to award reputation points to users for specific skills.
 *    - revokeReputation(address _user, uint256 _skillId, uint256 _amount): Allows admin to revoke reputation points from users for specific skills.
 *    - getReputation(address _user, uint256 _skillId): Retrieves the reputation of a user for a specific skill.
 *    - getUserSkillReputation(address _user): Returns a mapping of skills and their reputation points for a user.
 *    - transferReputation(address _recipient, uint256 _skillId, uint256 _amount): Allows users to transfer reputation points to other users for specific skills.
 *
 * **3. Skill Badge (NFT) System:**
 *    - mintSkillBadge(address _user, uint256 _skillId): Allows admin to mint a SkillBadge NFT for a user upon reaching a certain reputation level in a skill.
 *    - transferSkillBadge(address _recipient, uint256 _tokenId): Allows SkillBadge NFT holders to transfer their badges.
 *    - getSkillBadgeOfUser(address _user, uint256 _skillId): Retrieves the tokenId of a SkillBadge NFT for a user and skill, if minted.
 *    - getSkillBadgeMetadataURI(uint256 _tokenId): Returns the metadata URI for a SkillBadge NFT (can be customized to include skill and reputation info).
 *
 * **4. Skill Marketplace (Basic):**
 *    - createOpportunity(string _title, string _description, uint256 _requiredSkillId, uint256 _rewardAmount): Allows users to create opportunities requiring specific skills and offering rewards.
 *    - applyForOpportunity(uint256 _opportunityId): Allows users to apply for opportunities if they possess the required skill and reputation.
 *    - selectApplicant(uint256 _opportunityId, address _applicant): Allows the opportunity creator to select an applicant.
 *    - completeOpportunity(uint256 _opportunityId, address _executor): Allows the opportunity creator to mark an opportunity as completed and reward the executor.
 *    - getOpportunityDetails(uint256 _opportunityId): Retrieves details of a specific opportunity.
 *    - getOpportunitiesBySkill(uint256 _skillId): Returns a list of opportunity IDs requiring a specific skill.
 *
 * **5. Reputation Endorsement (Advanced Concept):**
 *    - endorseSkill(address _user, uint256 _skillId): Allows users to endorse other users for specific skills (requires a minimum reputation in that skill to endorse).
 *    - getEndorsementsCount(address _user, uint256 _skillId): Retrieves the number of endorsements a user has received for a specific skill.
 *    - getEndorsers(address _user, uint256 _skillId): Returns a list of addresses that have endorsed a user for a skill.
 *
 * **6. Platform Utility:**
 *    - setReputationThresholdForBadge(uint256 _skillId, uint256 _threshold): Allows admin to set the reputation threshold required to mint a SkillBadge for a skill.
 *    - getReputationThresholdForBadge(uint256 _skillId): Retrieves the reputation threshold for a SkillBadge of a skill.
 *    - setPlatformFeePercentage(uint256 _percentage): Allows admin to set a platform fee percentage on opportunity rewards.
 *    - withdrawPlatformFees(): Allows admin to withdraw accumulated platform fees.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SkillReputationMarketplace is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _skillIds;
    Counters.Counter private _opportunityIds;
    Counters.Counter private _skillBadgeTokenIds;

    // Skill Data Structure
    struct Skill {
        string name;
        string description;
        uint256 badgeReputationThreshold; // Reputation needed to earn a badge for this skill
    }

    // Opportunity Data Structure
    struct Opportunity {
        string title;
        string description;
        uint256 requiredSkillId;
        address creator;
        uint256 rewardAmount;
        address executor; // Address of the user who completed the opportunity
        bool isCompleted;
    }

    // Mappings and Arrays for Data Storage
    mapping(uint256 => Skill) public skills; // Skill ID => Skill Data
    mapping(address => mapping(uint256 => uint256)) public userSkillReputation; // User Address => (Skill ID => Reputation Points)
    mapping(address => mapping(uint256 => uint256)) public userSkillBadges; // User Address => (Skill ID => SkillBadge Token ID)
    mapping(uint256 => Opportunity) public opportunities; // Opportunity ID => Opportunity Data
    mapping(uint256 => uint256[]) public skillOpportunities; // Skill ID => Array of Opportunity IDs
    mapping(address => mapping(uint256 => address[])) public skillEndorsements; // User Address => (Skill ID => Array of Endorser Addresses)
    mapping(uint256 => uint256) public reputationThresholdsForBadges; // Skill ID => Reputation Threshold for Badge

    uint256 public platformFeePercentage = 5; // Platform fee percentage (e.g., 5% of reward)
    uint256 public accumulatedPlatformFees;

    // Events
    event SkillAdded(uint256 skillId, string skillName);
    event SkillRemoved(uint256 skillId);
    event SkillDescriptionUpdated(uint256 skillId, string newDescription);
    event ReputationAwarded(address user, uint256 skillId, uint256 amount);
    event ReputationRevoked(address user, uint256 skillId, uint256 amount);
    event ReputationTransferred(address sender, address recipient, uint256 skillId, uint256 amount);
    event SkillBadgeMinted(address user, uint256 skillId, uint256 tokenId);
    event OpportunityCreated(uint256 opportunityId, string title, uint256 requiredSkillId, address creator, uint256 rewardAmount);
    event OpportunityApplied(uint256 opportunityId, address applicant);
    event ApplicantSelected(uint256 opportunityId, address applicant);
    event OpportunityCompleted(uint256 opportunityId, address executor, uint256 rewardAmount);
    event SkillEndorsed(address user, uint256 skillId, address endorser);
    event ReputationThresholdSet(uint256 skillId, uint256 threshold);
    event PlatformFeePercentageSet(uint256 percentage);
    event PlatformFeesWithdrawn(uint256 amount, address admin);

    constructor() ERC721("SkillBadge", "SKB") Ownable() {}

    modifier onlyAdmin() {
        require(msg.sender == owner(), "Only admin can perform this action");
        _;
    }

    modifier skillExists(uint256 _skillId) {
        require(_skillId > 0 && _skillId <= _skillIds.current, "Skill does not exist");
        _;
    }

    modifier opportunityExists(uint256 _opportunityId) {
        require(_opportunityId > 0 && _opportunityId <= _opportunityIds.current, "Opportunity does not exist");
        _;
    }

    modifier hasSkillReputation(address _user, uint256 _skillId, uint256 _minReputation) {
        require(userSkillReputation[_user][_skillId] >= _minReputation, "Insufficient reputation for this skill");
        _;
    }

    modifier opportunityNotCompleted(uint256 _opportunityId) {
        require(!opportunities[_opportunityId].isCompleted, "Opportunity is already completed");
        _;
    }

    // 1. Skill Management Functions

    function addSkill(string memory _skillName, string memory _skillDescription) public onlyAdmin {
        _skillIds.increment();
        uint256 skillId = _skillIds.current;
        skills[skillId] = Skill({
            name: _skillName,
            description: _skillDescription,
            badgeReputationThreshold: 100 // Default threshold, can be adjusted later
        });
        emit SkillAdded(skillId, _skillName);
    }

    function removeSkill(uint256 _skillId) public onlyAdmin skillExists(_skillId) {
        delete skills[_skillId];
        emit SkillRemoved(_skillId);
    }

    function updateSkillDescription(uint256 _skillId, string memory _newDescription) public onlyAdmin skillExists(_skillId) {
        skills[_skillId].description = _newDescription;
        emit SkillDescriptionUpdated(_skillId, _newDescription);
    }

    function getSkillById(uint256 _skillId) public view skillExists(_skillId) returns (Skill memory) {
        return skills[_skillId];
    }

    function getSkillCount() public view returns (uint256) {
        return _skillIds.current;
    }

    function getAllSkills() public view returns (uint256[] memory) {
        uint256 skillCount = getSkillCount();
        uint256[] memory allSkillIds = new uint256[](skillCount);
        for (uint256 i = 1; i <= skillCount; i++) {
            allSkillIds[i - 1] = i;
        }
        return allSkillIds;
    }

    // 2. Reputation System Functions

    function awardReputation(address _user, uint256 _skillId, uint256 _amount) public onlyAdmin skillExists(_skillId) {
        userSkillReputation[_user][_skillId] += _amount;
        emit ReputationAwarded(_user, _skillId, _amount);
        _checkAndMintSkillBadge(_user, _skillId); // Check if badge should be minted after awarding reputation
    }

    function revokeReputation(address _user, uint256 _skillId, uint256 _amount) public onlyAdmin skillExists(_skillId) {
        require(userSkillReputation[_user][_skillId] >= _amount, "Cannot revoke more reputation than user has");
        userSkillReputation[_user][_skillId] -= _amount;
        emit ReputationRevoked(_user, _skillId, _amount);
    }

    function getReputation(address _user, uint256 _skillId) public view skillExists(_skillId) returns (uint256) {
        return userSkillReputation[_user][_skillId];
    }

    function getUserSkillReputation(address _user) public view returns (mapping(uint256 => uint256) memory) {
        return userSkillReputation[_user];
    }

    function transferReputation(address _recipient, uint256 _skillId, uint256 _amount) public skillExists(_skillId) hasSkillReputation(msg.sender, _skillId, _amount) {
        userSkillReputation[msg.sender][_skillId] -= _amount;
        userSkillReputation[_recipient][_skillId] += _amount;
        emit ReputationTransferred(msg.sender, _recipient, _skillId, _amount);
        _checkAndMintSkillBadge(_recipient, _skillId); // Check if badge should be minted for recipient after transfer
    }

    // 3. Skill Badge (NFT) System Functions

    function mintSkillBadge(address _user, uint256 _skillId) public onlyAdmin skillExists(_skillId) {
        _mintSkillBadgeInternal(_user, _skillId);
    }

    function _mintSkillBadgeInternal(address _user, uint256 _skillId) internal {
        require(userSkillBadges[_user][_skillId] == 0, "SkillBadge already minted for this skill");
        _skillBadgeTokenIds.increment();
        uint256 tokenId = _skillBadgeTokenIds.current;
        _safeMint(_user, tokenId);
        userSkillBadges[_user][_skillId] = tokenId;
        _setTokenURI(tokenId, _generateSkillBadgeMetadataURI(tokenId, _skillId, _user)); // Set dynamic metadata URI
        emit SkillBadgeMinted(_user, _skillId, tokenId);
    }

    function transferSkillBadge(address _recipient, uint256 _tokenId) public {
        safeTransferFrom(msg.sender, _recipient, _tokenId);
    }

    function getSkillBadgeOfUser(address _user, uint256 _skillId) public view skillExists(_skillId) returns (uint256) {
        return userSkillBadges[_user][_skillId];
    }

    function getSkillBadgeMetadataURI(uint256 _tokenId) public view override returns (string memory) {
        return tokenURI(_tokenId);
    }

    function _generateSkillBadgeMetadataURI(uint256 _tokenId, uint256 _skillId, address _user) private view returns (string memory) {
        // In a real application, this would likely generate a URI pointing to IPFS or a similar decentralized storage.
        // For simplicity, here's a basic example of a data URI.
        string memory skillName = skills[_skillId].name;
        uint256 reputation = userSkillReputation[_user][_skillId];
        string memory jsonData = string(abi.encodePacked(
            '{"name": "SkillBadge #', Strings.toString(_tokenId), '",',
            '"description": "SkillBadge for ', skillName, ' skill. Reputation: ', Strings.toString(reputation), '",',
            '"attributes": [{"trait_type": "Skill", "value": "', skillName, '"}, {"trait_type": "Reputation", "value": "', Strings.toString(reputation), '"}]}'
        ));
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(jsonData))));
    }

    // 4. Skill Marketplace (Basic) Functions

    function createOpportunity(string memory _title, string memory _description, uint256 _requiredSkillId, uint256 _rewardAmount) public skillExists(_requiredSkillId) {
        require(_rewardAmount > 0, "Reward amount must be positive");
        _opportunityIds.increment();
        uint256 opportunityId = _opportunityIds.current;
        opportunities[opportunityId] = Opportunity({
            title: _title,
            description: _description,
            requiredSkillId: _requiredSkillId,
            creator: msg.sender,
            rewardAmount: _rewardAmount,
            executor: address(0),
            isCompleted: false
        });
        skillOpportunities[_requiredSkillId].push(opportunityId);
        emit OpportunityCreated(opportunityId, _title, _requiredSkillId, msg.sender, _rewardAmount);
    }

    function applyForOpportunity(uint256 _opportunityId) public opportunityExists(_opportunityId) opportunityNotCompleted(_opportunityId) skillExists(opportunities[_opportunityId].requiredSkillId) hasSkillReputation(msg.sender, opportunities[_opportunityId].requiredSkillId, 1) { // Minimum 1 reputation to apply, adjust as needed
        // In a more advanced version, you might have an application list and selection process.
        // For this basic version, application is just a notification of interest.
        emit OpportunityApplied(_opportunityId, msg.sender);
    }

    function selectApplicant(uint256 _opportunityId, address _applicant) public opportunityExists(_opportunityId) opportunityNotCompleted(_opportunityId) {
        require(msg.sender == opportunities[_opportunityId].creator, "Only opportunity creator can select applicant");
        opportunities[_opportunityId].executor = _applicant;
        emit ApplicantSelected(_opportunityId, _applicant);
    }

    function completeOpportunity(uint256 _opportunityId, address _executor) public payable opportunityExists(_opportunityId) opportunityNotCompleted(_opportunityId) {
        require(msg.sender == opportunities[_opportunityId].creator, "Only opportunity creator can complete opportunity");
        require(opportunities[_opportunityId].executor == _executor, "Executor address mismatch");
        require(msg.value >= opportunities[_opportunityId].rewardAmount, "Insufficient Ether sent for reward");

        uint256 rewardAmount = opportunities[_opportunityId].rewardAmount;
        uint256 platformFee = (rewardAmount * platformFeePercentage) / 100;
        uint256 executorReward = rewardAmount - platformFee;

        accumulatedPlatformFees += platformFee;

        payable(_executor).transfer(executorReward);
        opportunities[_opportunityId].isCompleted = true;
        emit OpportunityCompleted(_opportunityId, _executor, executorReward);
    }

    function getOpportunityDetails(uint256 _opportunityId) public view opportunityExists(_opportunityId) returns (Opportunity memory) {
        return opportunities[_opportunityId];
    }

    function getOpportunitiesBySkill(uint256 _skillId) public view skillExists(_skillId) returns (uint256[] memory) {
        return skillOpportunities[_skillId];
    }

    // 5. Reputation Endorsement (Advanced Concept)

    function endorseSkill(address _user, uint256 _skillId) public skillExists(_skillId) hasSkillReputation(msg.sender, _skillId, 50) { // Requires 50 reputation in the skill to endorse (adjustable)
        // Prevent self-endorsement
        require(msg.sender != _user, "Cannot endorse yourself");
        // Prevent duplicate endorsements from the same endorser
        bool alreadyEndorsed = false;
        address[] memory endorsers = skillEndorsements[_user][_skillId];
        for (uint256 i = 0; i < endorsers.length; i++) {
            if (endorsers[i] == msg.sender) {
                alreadyEndorsed = true;
                break;
            }
        }
        require(!alreadyEndorsed, "Already endorsed this user for this skill");

        skillEndorsements[_user][_skillId].push(msg.sender);
        emit SkillEndorsed(_user, _skillId, msg.sender);
    }

    function getEndorsementsCount(address _user, uint256 _skillId) public view skillExists(_skillId) returns (uint256) {
        return skillEndorsements[_user][_skillId].length;
    }

    function getEndorsers(address _user, uint256 _skillId) public view skillExists(_skillId) returns (address[] memory) {
        return skillEndorsements[_user][_skillId];
    }

    // 6. Platform Utility Functions

    function setReputationThresholdForBadge(uint256 _skillId, uint256 _threshold) public onlyAdmin skillExists(_skillId) {
        reputationThresholdsForBadges[_skillId] = _threshold;
        skills[_skillId].badgeReputationThreshold = _threshold; // Update in Skill struct as well for consistency
        emit ReputationThresholdSet(_skillId, _threshold);
    }

    function getReputationThresholdForBadge(uint256 _skillId) public view skillExists(_skillId) returns (uint256) {
        return reputationThresholdsForBadges[_skillId];
    }

    function setPlatformFeePercentage(uint256 _percentage) public onlyAdmin {
        require(_percentage <= 100, "Platform fee percentage cannot exceed 100%");
        platformFeePercentage = _percentage;
        emit PlatformFeePercentageSet(_percentage);
    }

    function withdrawPlatformFees() public onlyAdmin {
        uint256 amountToWithdraw = accumulatedPlatformFees;
        accumulatedPlatformFees = 0;
        payable(owner()).transfer(amountToWithdraw);
        emit PlatformFeesWithdrawn(amountToWithdraw, owner());
    }

    // Internal function to check reputation and mint SkillBadge if threshold is reached
    function _checkAndMintSkillBadge(address _user, uint256 _skillId) internal {
        if (userSkillReputation[_user][_skillId] >= reputationThresholdsForBadges[_skillId] && userSkillBadges[_user][_skillId] == 0) {
            _mintSkillBadgeInternal(_user, _skillId);
        }
    }

    // Override supportsInterface to declare ERC721 interface support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// --- Helper Libraries (Included for Completeness - For real deployment, consider using OpenZeppelin's Strings and Base64) ---

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

library Base64 {
    string private constant _BASE64_ENCODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes private constant _BASE64_DECODE_CHARS = "==================================================================="
    "=++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++==";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = _BASE64_ENCODE_CHARS;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare a pointer we can increment in assembly
            let dataPtr := add(data, 32)
            let endPtr := add(dataPtr, mload(data))

            // prepare a pointer to place encoded characters
            let destPtr := add(result, 32)

            // advance 32 bytes backwards so pointer writes first character
            destPtr := sub(destPtr, 1)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {
                dataPtr := add(dataPtr, 3)
            } {
                // copy 3 bytes into local working variables
                let input := mload(dataPtr)
                let input2 := mload(add(dataPtr, 1))
                let input3 := mload(add(dataPtr, 2))

                // ### can optimize with assembly
                // ### first character
                mstore(destPtr, byte(0, mload(add(table, mul(shr(18, input), 1)))))
                destPtr := add(destPtr, 1)
                // ### second character
                mstore(destPtr, byte(0, mload(add(table, mul(shr(12, input), 1) & 0x3F))))
                destPtr := add(destPtr, 1)
                // ### third character
                mstore(destPtr, byte(0, mload(add(table, mul(shr(6, input), 1) & 0x3F))))
                destPtr := add(destPtr, 1)
                // ### forth character
                mstore(destPtr, byte(0, mload(add(table, input & 0x3F))))
                destPtr := add(destPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 2 {
                mstore(destPtr, byte(0, mload(add(table, input & 0x3F))))
                destPtr := add(destPtr, 1)
            }
            case 1 {
                mstore(destPtr, byte(0, 61))
                destPtr := add(destPtr, 1)
            }
            case 0 {
                mstore(destPtr, byte(0, 61))
                destPtr := add(destPtr, 1)
                mstore(destPtr, byte(0, 61))
                destPtr := add(destPtr, 1)
            }
        }

        return result;
    }
}
```