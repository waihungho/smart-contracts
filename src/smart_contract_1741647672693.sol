```solidity
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation & Influence NFT Contract - "Aetheria Score"
 * @author Bard (Example Smart Contract)
 * @dev This contract implements a dynamic reputation and influence system represented by NFTs.
 * It goes beyond simple reputation tracking and incorporates elements of influence,
 * gamification, and decentralized governance, all wrapped within a single NFT.
 *
 * **Outline & Function Summary:**
 *
 * **1. Core NFT Functionality (ERC721-like):**
 *    - `mintReputationNFT(address _to)`: Mints a new Reputation NFT to a user.
 *    - `transferNFT(address _from, address _to, uint256 _tokenId)`: Transfers an NFT (with access control).
 *    - `getOwnerOfNFT(uint256 _tokenId)`: Returns the owner of a specific NFT.
 *    - `getTotalNFTSupply()`: Returns the total number of Reputation NFTs minted.
 *    - `getNFTBalanceOf(address _owner)`: Returns the number of NFTs owned by an address.
 *
 * **2. Dynamic Reputation System:**
 *    - `increaseReputation(uint256 _tokenId, uint256 _amount)`: Increases the reputation score of an NFT.
 *    - `decreaseReputation(uint256 _tokenId, uint256 _amount)`: Decreases the reputation score of an NFT (with limits).
 *    - `getReputationScore(uint256 _tokenId)`: Returns the current reputation score of an NFT.
 *    - `getReputationLevel(uint256 _tokenId)`: Returns the reputation level based on the score (using tiered levels).
 *    - `setReputationThresholds(uint256[] memory _thresholds)`: Admin function to set reputation level thresholds.
 *
 * **3. Influence and Voting Power:**
 *    - `calculateInfluenceScore(uint256 _tokenId)`: Calculates an influence score based on reputation and potentially other factors (e.g., NFT age).
 *    - `getVotingPower(uint256 _tokenId)`: Returns the voting power of an NFT, derived from its influence score.
 *
 * **4. Skill-Based Reputation Tracks (Advanced Concept):**
 *    - `assignSkillTrack(uint256 _tokenId, string memory _skillTrack)`: Assigns a skill track (e.g., "Developer", "Designer", "Community Builder") to an NFT.
 *    - `getSkillTrack(uint256 _tokenId)`: Returns the assigned skill track of an NFT.
 *    - `increaseSkillReputation(uint256 _tokenId, string memory _skillTrack, uint256 _amount)`: Increases reputation within a specific skill track.
 *    - `getSkillReputationScore(uint256 _tokenId, string memory _skillTrack)`: Returns the reputation score for a specific skill track.
 *
 * **5. Reputation Decay and Activity Incentives:**
 *    - `applyReputationDecay(uint256 _tokenId)`: Applies a decay factor to reputation based on inactivity (configurable decay rate and period).
 *    - `setDecayParameters(uint256 _decayRate, uint256 _decayPeriod)`: Admin function to set reputation decay parameters.
 *
 * **6. Reputation Milestones and Achievements:**
 *    - `checkMilestones(uint256 _tokenId)`: Checks if an NFT has reached new reputation milestones and triggers achievement rewards (e.g., special NFT badges).
 *    - `addMilestoneReward(uint256 _threshold, string memory _rewardName)`: Admin function to add new reputation milestones and their rewards.
 *
 * **7. Reputation Boosting Events (Dynamic Events):**
 *    - `createReputationEvent(string memory _eventName, uint256 _boostFactor, uint256 _duration)`: Admin function to create temporary reputation boosting events.
 *    - `isEventActive()`: Checks if a reputation boosting event is currently active.
 *    - `getEventBoostFactor()`: Returns the current event boost factor (if active).
 *
 * **8. Reputation-Gated Access (Use Cases):**
 *    - `hasRequiredReputation(address _user, uint256 _requiredScore)`: Checks if a user's NFT has at least the required reputation score.
 *
 * **9. Admin & Utility Functions:**
 *    - `setBaseURI(string memory _uri)`: Admin function to set the base URI for NFT metadata.
 *    - `withdrawContractBalance()`: Admin function to withdraw contract's ETH balance.
 *    - `pauseContract()`: Admin function to pause core functionalities of the contract.
 *    - `unpauseContract()`: Admin function to unpause the contract.
 */

contract DynamicReputationNFT {
    // --- State Variables ---
    string public name = "Aetheria Score";
    string public symbol = "AES";
    string public baseURI;
    address public owner;
    uint256 public totalSupply;
    uint256 public reputationDecayRate = 1; // Percentage decay per decay period
    uint256 public reputationDecayPeriod = 30 days; // Period after which decay is applied
    uint256 public lastDecayTimestamp;

    bool public paused = false;

    mapping(uint256 => address) public nftOwner;
    mapping(address => uint256) public nftBalance;
    mapping(uint256 => uint256) public reputationScores;
    mapping(uint256 => string) public skillTracks; // Skill track assigned to NFT
    mapping(uint256 => mapping(string => uint256)) public skillReputationScores; // Reputation per skill track
    mapping(uint256 => uint256) public lastActivityTimestamp; // Track last activity for decay

    uint256[] public reputationLevelThresholds = [100, 500, 1000, 5000]; // Example levels
    string[] public reputationLevelNames = ["Beginner", "Initiate", "Adept", "Master", "Legend"];

    struct MilestoneReward {
        uint256 threshold;
        string rewardName;
    }
    MilestoneReward[] public milestoneRewards;

    struct ReputationEvent {
        string name;
        uint256 boostFactor;
        uint256 endTime;
        bool isActive;
    }
    ReputationEvent public currentEvent;

    // --- Events ---
    event NFTMinted(address indexed to, uint256 tokenId);
    event NFTTransfer(address indexed from, address indexed to, uint256 tokenId);
    event ReputationIncreased(uint256 indexed tokenId, uint256 amount, uint256 newScore);
    event ReputationDecreased(uint256 indexed tokenId, uint256 amount, uint256 newScore);
    event SkillTrackAssigned(uint256 indexed tokenId, string skillTrack);
    event SkillReputationIncreased(uint256 indexed tokenId, string skillTrack, uint256 amount, uint256 newScore);
    event ReputationDecayApplied(uint256 indexed tokenId, uint256 decayedAmount, uint256 newScore);
    event MilestoneReached(uint256 indexed tokenId, string rewardName);
    event ReputationEventCreated(string eventName, uint256 boostFactor, uint256 endTime);
    event ContractPaused();
    event ContractUnpaused();

    // --- Modifiers ---
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
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

    // --- Constructor ---
    constructor(string memory _baseURI) {
        owner = msg.sender;
        baseURI = _baseURI;
        lastDecayTimestamp = block.timestamp; // Initialize decay timestamp
    }

    // --- 1. Core NFT Functionality ---
    function mintReputationNFT(address _to) public onlyOwner whenNotPaused {
        totalSupply++;
        uint256 tokenId = totalSupply;
        nftOwner[tokenId] = _to;
        nftBalance[_to]++;
        lastActivityTimestamp[tokenId] = block.timestamp; // Set initial activity timestamp
        emit NFTMinted(_to, tokenId);
    }

    function transferNFT(address _from, address _to, uint256 _tokenId) public whenNotPaused {
        require(nftOwner[_tokenId] == _from, "Not owner of NFT.");
        nftOwner[_tokenId] = _to;
        nftBalance[_from]--;
        nftBalance[_to]++;
        lastActivityTimestamp[_tokenId] = block.timestamp; // Update activity on transfer
        emit NFTTransfer(_from, _to, _tokenId);
    }

    function getOwnerOfNFT(uint256 _tokenId) public view returns (address) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return nftOwner[_tokenId];
    }

    function getTotalNFTSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getNFTBalanceOf(address _owner) public view returns (uint256) {
        return nftBalance[_owner];
    }

    // --- 2. Dynamic Reputation System ---
    function increaseReputation(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        reputationScores[_tokenId] += _amount;

        // Apply event boost if active
        if (isEventActive()) {
            reputationScores[_tokenId] += (_amount * currentEvent.boostFactor) / 100; // Boost as percentage
        }

        lastActivityTimestamp[_tokenId] = block.timestamp; // Update activity timestamp
        checkMilestones(_tokenId); // Check for milestone achievements after reputation increase
        emit ReputationIncreased(_tokenId, _amount, reputationScores[_tokenId]);
    }

    function decreaseReputation(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        // Prevent reputation from going negative
        uint256 currentScore = reputationScores[_tokenId];
        uint256 newScore = currentScore > _amount ? currentScore - _amount : 0;
        reputationScores[_tokenId] = newScore;
        lastActivityTimestamp[_tokenId] = block.timestamp; // Update activity timestamp
        emit ReputationDecreased(_tokenId, _amount, reputationScores[_tokenId]);
    }

    function getReputationScore(uint256 _tokenId) public view returns (uint256) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return reputationScores[_tokenId];
    }

    function getReputationLevel(uint256 _tokenId) public view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        uint256 score = reputationScores[_tokenId];
        for (uint256 i = 0; i < reputationLevelThresholds.length; i++) {
            if (score <= reputationLevelThresholds[i]) {
                return reputationLevelNames[i];
            }
        }
        return reputationLevelNames[reputationLevelNames.length - 1]; // Highest level if score exceeds all thresholds
    }

    function setReputationThresholds(uint256[] memory _thresholds) public onlyOwner whenNotPaused {
        require(_thresholds.length == reputationLevelNames.length -1 , "Number of thresholds must be one less than level names."); // One less threshold than levels
        reputationLevelThresholds = _thresholds;
    }

    // --- 3. Influence and Voting Power ---
    function calculateInfluenceScore(uint256 _tokenId) public view returns (uint256) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        uint256 baseInfluence = reputationScores[_tokenId];
        // Example: Bonus for NFT age (longer held, more influence)
        uint256 nftAgeDays = (block.timestamp - lastActivityTimestamp[_tokenId]) / 1 days; // Using last activity as a proxy for 'age' held
        uint256 ageBonus = nftAgeDays / 30; // Bonus points per month held (example)
        return baseInfluence + ageBonus; // Combine reputation and age for influence
    }

    function getVotingPower(uint256 _tokenId) public view returns (uint256) {
        return calculateInfluenceScore(_tokenId); // Voting power directly derived from influence
        // Can be further customized: e.g., square root of influence, logarithmic scale, etc.
    }

    // --- 4. Skill-Based Reputation Tracks ---
    function assignSkillTrack(uint256 _tokenId, string memory _skillTrack) public onlyOwner whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        skillTracks[_tokenId] = _skillTrack;
        emit SkillTrackAssigned(_tokenId, _skillTrack);
    }

    function getSkillTrack(uint256 _tokenId) public view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return skillTracks[_tokenId];
    }

    function increaseSkillReputation(uint256 _tokenId, string memory _skillTrack, uint256 _amount) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        skillReputationScores[_tokenId][_skillTrack] += _amount;
        lastActivityTimestamp[_tokenId] = block.timestamp; // Update activity timestamp
        emit SkillReputationIncreased(_tokenId, _skillTrack, _amount, skillReputationScores[_tokenId][_skillTrack]);
    }

    function getSkillReputationScore(uint256 _tokenId, string memory _skillTrack) public view returns (uint256) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        return skillReputationScores[_tokenId][_skillTrack];
    }

    // --- 5. Reputation Decay and Activity Incentives ---
    function applyReputationDecay(uint256 _tokenId) public whenNotPaused {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        if (block.timestamp >= lastActivityTimestamp[_tokenId] + reputationDecayPeriod) {
            uint256 currentScore = reputationScores[_tokenId];
            uint256 decayAmount = (currentScore * reputationDecayRate) / 100;
            uint256 newScore = currentScore > decayAmount ? currentScore - decayAmount : 0;
            reputationScores[_tokenId] = newScore;
            lastActivityTimestamp[_tokenId] = block.timestamp; // Reset activity timestamp after decay
            emit ReputationDecayApplied(_tokenId, decayAmount, newScore);
        }
    }

    function setDecayParameters(uint256 _decayRate, uint256 _decayPeriod) public onlyOwner whenNotPaused {
        reputationDecayRate = _decayRate;
        reputationDecayPeriod = _decayPeriod;
    }

    function triggerGlobalReputationDecay() public onlyOwner whenNotPaused {
        require(block.timestamp >= lastDecayTimestamp + reputationDecayPeriod, "Decay period not elapsed yet.");
        for (uint256 i = 1; i <= totalSupply; i++) { // Iterate through all minted NFTs
            applyReputationDecay(i);
        }
        lastDecayTimestamp = block.timestamp; // Update global decay timestamp
    }


    // --- 6. Reputation Milestones and Achievements ---
    function checkMilestones(uint256 _tokenId) private {
        uint256 currentScore = reputationScores[_tokenId];
        for (uint256 i = 0; i < milestoneRewards.length; i++) {
            if (currentScore == milestoneRewards[i].threshold) {
                // Logic to award reward (e.g., a separate achievement NFT, on-chain badge, etc.)
                // For this example, we'll just emit an event
                emit MilestoneReached(_tokenId, milestoneRewards[i].rewardName);
            }
        }
    }

    function addMilestoneReward(uint256 _threshold, string memory _rewardName) public onlyOwner whenNotPaused {
        milestoneRewards.push(MilestoneReward({threshold: _threshold, rewardName: _rewardName}));
    }

    // --- 7. Reputation Boosting Events ---
    function createReputationEvent(string memory _eventName, uint256 _boostFactor, uint256 _duration) public onlyOwner whenNotPaused {
        require(!isEventActive(), "An event is already active.");
        currentEvent = ReputationEvent({
            name: _eventName,
            boostFactor: _boostFactor,
            endTime: block.timestamp + _duration,
            isActive: true
        });
        emit ReputationEventCreated(_eventName, _boostFactor, currentEvent.endTime);
    }

    function isEventActive() public view returns (bool) {
        return currentEvent.isActive && block.timestamp < currentEvent.endTime;
    }

    function getEventBoostFactor() public view returns (uint256) {
        if (isEventActive()) {
            return currentEvent.boostFactor;
        } else {
            return 0;
        }
    }

    function endReputationEvent() public onlyOwner whenNotPaused {
        if (isEventActive()) {
            currentEvent.isActive = false;
        }
    }

    // --- 8. Reputation-Gated Access ---
    function hasRequiredReputation(address _user, uint256 _requiredScore) public view returns (bool) {
        uint256 tokenId = 0;
        // Find the first NFT owned by the user (assuming 1 NFT per user for simplicity in this example)
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (nftOwner[i] == _user) {
                tokenId = i;
                break;
            }
        }
        if (tokenId == 0) {
            return false; // User doesn't own an NFT
        }
        return reputationScores[tokenId] >= _requiredScore;
    }

    // --- 9. Admin & Utility Functions ---
    function setBaseURI(string memory _uri) public onlyOwner whenNotPaused {
        baseURI = _uri;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(nftOwner[_tokenId] != address(0), "NFT does not exist.");
        // Example dynamic metadata - can be expanded significantly
        string memory level = getReputationLevel(_tokenId);
        string memory skill = getSkillTrack(_tokenId);
        return string(abi.encodePacked(baseURI, "/", Strings.toString(_tokenId),
                                      "?level=", level,
                                      "&skill=", skill));
    }

    function withdrawContractBalance() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function pauseContract() public onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused();
    }

    function unpauseContract() public onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused();
    }

    // --- Helper library for uint to string conversion (Solidity 0.8+ doesn't have built-in) ---
    library Strings {
        bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}
```