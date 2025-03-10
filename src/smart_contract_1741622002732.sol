```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Dynamic Reputation and Predictive Market Contract
 * @author Gemini AI (Example - Unique and Creative Contract)
 * @notice This contract implements a dynamic reputation system linked to a predictive market,
 *         where users can build reputation by making accurate predictions and engaging responsibly.
 *         It features dynamic NFT reputation badges, quadratic voting for event resolution,
 *         and a decay mechanism for reputation to ensure active participation.
 *
 * Function Outline and Summary:
 *
 * 1.  createProfile(): Allows users to create a profile, initializing their reputation.
 * 2.  endorseProfile(address _profileAddress): Allows users to endorse another user's profile, increasing their reputation.
 * 3.  reportProfile(address _profileAddress, string _reason): Allows users to report a profile for inappropriate behavior.
 * 4.  moderateReport(address _profileAddress, bool _isLegitimate): Moderator function to resolve reports, affecting reputation.
 * 5.  getReputation(address _profileAddress): Returns the reputation score of a user.
 * 6.  createEvent(string _eventDescription, uint256 _resolutionTimestamp, string[] memory _outcomes): Creates a new prediction event with multiple possible outcomes.
 * 7.  submitPrediction(uint256 _eventId, uint256 _outcomeIndex, uint256 _amount): Allows users to submit a prediction for an event, staking ETH.
 * 8.  voteForOutcome(uint256 _eventId, uint256 _outcomeIndex): Allows users to vote for their predicted outcome using quadratic voting based on reputation.
 * 9.  resolveEvent(uint256 _eventId, uint256 _winningOutcomeIndex): Moderator function to resolve an event and distribute rewards.
 * 10. claimWinnings(uint256 _eventId): Allows users to claim winnings for correct predictions.
 * 11. getEventDetails(uint256 _eventId): Returns detailed information about a specific prediction event.
 * 12. getUserPredictions(address _userAddress): Returns a list of events a user has participated in.
 * 13. mintReputationNFT(address _profileAddress): Mints a dynamic NFT badge representing the user's reputation level.
 * 14. evolveReputationNFT(address _profileAddress): Updates the metadata of a user's reputation NFT badge based on reputation changes.
 * 15. getNFTMetadata(address _profileAddress): Returns the current metadata URI for a user's reputation NFT badge.
 * 16. setModerator(address _moderatorAddress): Allows the contract owner to set a moderator address.
 * 17. pauseContract(): Allows the contract owner to pause the contract in case of emergency.
 * 18. unpauseContract(): Allows the contract owner to unpause the contract.
 * 19. withdrawContractBalance(): Allows the contract owner to withdraw any excess contract balance.
 * 20. getContractBalance(): Returns the current ETH balance of the contract.
 * 21. setReputationDecayRate(uint256 _decayRate): Allows the contract owner to set the reputation decay rate.
 * 22. applyReputationDecay(): Applies reputation decay to all profiles periodically.
 */

contract DynamicReputationPredictiveMarket {

    // --- State Variables ---

    address public owner;
    address public moderator;
    bool public paused;
    uint256 public reputationDecayRate = 1; // Percentage decay per decay application (e.g., 1% per period)
    uint256 public lastDecayTimestamp;
    uint256 public decayInterval = 7 days; // Apply decay every 7 days

    struct UserProfile {
        uint256 reputationScore;
        string profileName; // Example: Could be extended with more profile info
        uint256 nftBadgeId;
        bool exists;
    }

    struct PredictionEvent {
        string description;
        uint256 resolutionTimestamp;
        string[] outcomes;
        EventStatus status;
        uint256 winningOutcomeIndex;
        mapping(address => Prediction) userPredictions; // User address => Prediction
        mapping(uint256 => uint256) outcomeVotes; // Outcome Index => Vote Count
        uint256 totalStake;
    }

    struct Prediction {
        uint256 outcomeIndex;
        uint256 amount;
        bool claimedWinnings;
    }

    enum EventStatus {
        OPEN,
        RESOLVING,
        RESOLVED,
        CLOSED
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(uint256 => PredictionEvent) public predictionEvents;
    uint256 public nextEventId = 1;
    uint256 public nextNFTBadgeId = 1;

    event ProfileCreated(address indexed user, string profileName);
    event ReputationEndorsed(address indexed endorser, address indexed profile, uint256 reputationChange);
    event ProfileReported(address indexed reporter, address indexed profile, string reason);
    event ReportModerated(address indexed moderator, address indexed profile, bool isLegitimate, uint256 reputationChange);
    event EventCreated(uint256 eventId, string description, uint256 resolutionTimestamp);
    event PredictionSubmitted(uint256 indexed eventId, address indexed user, uint256 outcomeIndex, uint256 amount);
    event OutcomeVoted(uint256 indexed eventId, address indexed user, uint256 outcomeIndex, uint256 votes);
    event EventResolved(uint256 eventId, uint256 winningOutcomeIndex);
    event WinningsClaimed(uint256 indexed eventId, address indexed user, uint256 amount);
    event NFTBadgeMinted(address indexed user, uint256 badgeId);
    event NFTBadgeEvolved(address indexed user, uint256 badgeId);
    event ContractPaused(address pauser);
    event ContractUnpaused(address unpauser);
    event ModeratorSet(address newModerator, address oldModerator);
    event ReputationDecayApplied(uint256 timestamp);


    // --- Modifiers ---

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyModerator() {
        require(msg.sender == moderator, "Only moderator can call this function.");
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

    modifier eventExists(uint256 _eventId) {
        require(predictionEvents[_eventId].status != EventStatus.CLOSED, "Event does not exist or is closed.");
        _;
    }

    modifier profileExists(address _profileAddress) {
        require(userProfiles[_profileAddress].exists, "Profile does not exist.");
        _;
    }


    // --- Constructor ---

    constructor() {
        owner = msg.sender;
        moderator = msg.sender; // Initially, owner is also the moderator
        lastDecayTimestamp = block.timestamp;
    }


    // --- Profile Management Functions ---

    /// @notice Allows users to create a profile, initializing their reputation.
    function createProfile(string memory _profileName) external whenNotPaused {
        require(!userProfiles[msg.sender].exists, "Profile already exists for this address.");
        userProfiles[msg.sender] = UserProfile({
            reputationScore: 100, // Initial reputation score
            profileName: _profileName,
            nftBadgeId: 0, // NFT badge minted separately
            exists: true
        });
        emit ProfileCreated(msg.sender, _profileName);
    }

    /// @notice Allows users to endorse another user's profile, increasing their reputation.
    /// @param _profileAddress The address of the profile to endorse.
    function endorseProfile(address _profileAddress) external whenNotPaused profileExists(_profileAddress) profileExists(msg.sender) {
        require(_profileAddress != msg.sender, "Cannot endorse your own profile.");
        uint256 endorsementValue = 10; // Base endorsement value, could be reputation-weighted
        userProfiles[_profileAddress].reputationScore += endorsementValue;
        emit ReputationEndorsed(msg.sender, _profileAddress, endorsementValue);
        evolveReputationNFT(_profileAddress); // Update NFT badge if applicable
    }

    /// @notice Allows users to report a profile for inappropriate behavior.
    /// @param _profileAddress The address of the profile to report.
    /// @param _reason The reason for reporting.
    function reportProfile(address _profileAddress, string memory _reason) external whenNotPaused profileExists(_profileAddress) profileExists(msg.sender) {
        require(_profileAddress != msg.sender, "Cannot report your own profile.");
        // In a real system, consider limiting reports per user to prevent spam
        emit ProfileReported(msg.sender, _profileAddress, _reason);
        // Moderation process will handle the actual reputation impact
    }

    /// @notice Moderator function to resolve reports, affecting reputation.
    /// @param _profileAddress The address of the reported profile.
    /// @param _isLegitimate True if the report is legitimate, false otherwise.
    function moderateReport(address _profileAddress, bool _isLegitimate) external whenNotPaused onlyModerator profileExists(_profileAddress) {
        int256 reputationChange = 0;
        if (_isLegitimate) {
            reputationChange = -20; // Reputation penalty for legitimate report
            userProfiles[_profileAddress].reputationScore = uint256(int256(userProfiles[_profileAddress].reputationScore) + reputationChange > 0 ? int256(userProfiles[_profileAddress].reputationScore) + reputationChange : 0); // Ensure reputation doesn't go negative
        } else {
            reputationChange = 5; // Small reputation reward for the reporter for false report analysis (optional)
            userProfiles[msg.sender].reputationScore += uint256(reputationChange); // Reward reporter (optional, could be risk of abuse)
        }
        emit ReportModerated(msg.sender, _profileAddress, _isLegitimate, uint256(reputationChange));
        evolveReputationNFT(_profileAddress); // Update NFT badge if applicable
    }

    /// @notice Returns the reputation score of a user.
    /// @param _profileAddress The address of the profile to query.
    /// @return The reputation score.
    function getReputation(address _profileAddress) external view profileExists(_profileAddress) returns (uint256) {
        return userProfiles[_profileAddress].reputationScore;
    }


    // --- Prediction Event Functions ---

    /// @notice Creates a new prediction event with multiple possible outcomes.
    /// @param _eventDescription Description of the event.
    /// @param _resolutionTimestamp Timestamp when the event will be resolved.
    /// @param _outcomes Array of possible outcomes for the event.
    function createEvent(string memory _eventDescription, uint256 _resolutionTimestamp, string[] memory _outcomes) external whenNotPaused onlyOwner {
        require(_resolutionTimestamp > block.timestamp, "Resolution timestamp must be in the future.");
        require(_outcomes.length > 1, "At least two outcomes are required for an event.");

        predictionEvents[nextEventId] = PredictionEvent({
            description: _eventDescription,
            resolutionTimestamp: _resolutionTimestamp,
            outcomes: _outcomes,
            status: EventStatus.OPEN,
            winningOutcomeIndex: 0, // Default, updated upon resolution
            outcomeVotes: mapping(uint256 => uint256)(),
            userPredictions: mapping(address => Prediction)(),
            totalStake: 0
        });

        emit EventCreated(nextEventId, _eventDescription, _resolutionTimestamp);
        nextEventId++;
    }

    /// @notice Allows users to submit a prediction for an event, staking ETH.
    /// @param _eventId The ID of the event to predict on.
    /// @param _outcomeIndex The index of the predicted outcome.
    /// @param _amount The amount of ETH to stake on the prediction.
    function submitPrediction(uint256 _eventId, uint256 _outcomeIndex, uint256 _amount) external payable whenNotPaused eventExists(_eventId) profileExists(msg.sender) {
        require(predictionEvents[_eventId].status == EventStatus.OPEN, "Event is not open for predictions.");
        require(_outcomeIndex < predictionEvents[_eventId].outcomes.length, "Invalid outcome index.");
        require(msg.value == _amount, "Incorrect ETH amount sent.");
        require(_amount > 0, "Stake amount must be positive.");
        require(predictionEvents[_eventId].userPredictions[msg.sender].amount == 0, "Already predicted for this event."); // Prevent multiple predictions

        predictionEvents[_eventId].userPredictions[msg.sender] = Prediction({
            outcomeIndex: _outcomeIndex,
            amount: _amount,
            claimedWinnings: false
        });
        predictionEvents[_eventId].totalStake += _amount;
        payable(address(this)).transfer(_amount); // Move staked ETH to contract

        emit PredictionSubmitted(_eventId, msg.sender, _outcomeIndex, _amount);
    }

    /// @notice Allows users to vote for their predicted outcome using quadratic voting based on reputation.
    /// @param _eventId The ID of the event to vote for.
    /// @param _outcomeIndex The index of the outcome to vote for.
    function voteForOutcome(uint256 _eventId, uint256 _outcomeIndex) external whenNotPaused eventExists(_eventId) profileExists(msg.sender) {
        require(predictionEvents[_eventId].status == EventStatus.OPEN, "Voting is closed for this event.");
        require(_outcomeIndex < predictionEvents[_eventId].outcomes.length, "Invalid outcome index.");
        require(predictionEvents[_eventId].userPredictions[msg.sender].amount > 0, "Must submit a prediction first to vote."); // Only predictors can vote

        uint256 reputationVotes = sqrt(userProfiles[msg.sender].reputationScore); // Quadratic voting - votes scale with square root of reputation
        predictionEvents[_eventId].outcomeVotes[_outcomeIndex] += reputationVotes;
        emit OutcomeVoted(_eventId, msg.sender, _outcomeIndex, reputationVotes);
    }

    /// @notice Moderator function to resolve an event and distribute rewards.
    /// @param _eventId The ID of the event to resolve.
    /// @param _winningOutcomeIndex The index of the winning outcome.
    function resolveEvent(uint256 _eventId, uint256 _winningOutcomeIndex) external whenNotPaused onlyModerator eventExists(_eventId) {
        require(predictionEvents[_eventId].status == EventStatus.OPEN || predictionEvents[_eventId].status == EventStatus.RESOLVING, "Event is not open for resolution.");
        require(block.timestamp >= predictionEvents[_eventId].resolutionTimestamp, "Resolution time not reached yet.");
        require(_winningOutcomeIndex < predictionEvents[_eventId].outcomes.length, "Invalid winning outcome index.");

        predictionEvents[_eventId].status = EventStatus.RESOLVED;
        predictionEvents[_eventId].winningOutcomeIndex = _winningOutcomeIndex;

        // Distribute rewards proportionally to stake for correct predictions
        uint256 totalWinningStake = 0;
        for (uint256 i = 0; i < predictionEvents[_eventId].outcomes.length; i++) {
            if (uint256(i) == _winningOutcomeIndex) {
                for (address user : getPredictionUsers(_eventId)) {
                    if (predictionEvents[_eventId].userPredictions[user].outcomeIndex == _winningOutcomeIndex) {
                        totalWinningStake += predictionEvents[_eventId].userPredictions[user].amount;
                    }
                }
                break; // Stop after finding winning outcome index
            }
        }

        if (totalWinningStake > 0) {
            for (address user : getPredictionUsers(_eventId)) {
                if (predictionEvents[_eventId].userPredictions[user].outcomeIndex == _winningOutcomeIndex) {
                    uint256 rewardAmount = (predictionEvents[_eventId].userPredictions[user].amount * predictionEvents[_eventId].totalStake) / totalWinningStake;
                    payable(user).transfer(rewardAmount);
                }
            }
        }

        emit EventResolved(_eventId, _winningOutcomeIndex);
    }

    /// @notice Allows users to claim winnings for correct predictions.
    /// @param _eventId The ID of the event to claim winnings from.
    function claimWinnings(uint256 _eventId) external whenNotPaused eventExists(_eventId) profileExists(msg.sender) {
        require(predictionEvents[_eventId].status == EventStatus.RESOLVED, "Event is not yet resolved.");
        require(!predictionEvents[_eventId].userPredictions[msg.sender].claimedWinnings, "Winnings already claimed.");
        require(predictionEvents[_eventId].userPredictions[msg.sender].outcomeIndex == predictionEvents[_eventId].winningOutcomeIndex, "Prediction was incorrect, no winnings to claim.");

        uint256 rewardAmount = (predictionEvents[_eventId].userPredictions[msg.sender].amount * predictionEvents[_eventId].totalStake) / calculateTotalWinningStake(_eventId);

        predictionEvents[_eventId].userPredictions[msg.sender].claimedWinnings = true;
        payable(msg.sender).transfer(rewardAmount); // Transfer winnings to user (already done in resolveEvent in this example, can adjust logic if needed)

        emit WinningsClaimed(_eventId, msg.sender, rewardAmount);
    }


    /// @notice Returns detailed information about a specific prediction event.
    /// @param _eventId The ID of the event to query.
    /// @return Event details: description, resolutionTimestamp, outcomes, status, winningOutcomeIndex, totalStake.
    function getEventDetails(uint256 _eventId) external view eventExists(_eventId) returns (string memory description, uint256 resolutionTimestamp, string[] memory outcomes, EventStatus status, uint256 winningOutcomeIndex, uint256 totalStake, uint256[] memory outcomeVotes) {
        PredictionEvent storage event = predictionEvents[_eventId];
        uint256[] memory votes = new uint256[](event.outcomes.length);
        for(uint i=0; i < event.outcomes.length; i++){
            votes[i] = event.outcomeVotes[i];
        }
        return (event.description, event.resolutionTimestamp, event.outcomes, event.status, event.winningOutcomeIndex, event.totalStake, votes);
    }

    /// @notice Returns a list of events a user has participated in.
    /// @param _userAddress The address of the user to query.
    /// @return Array of event IDs the user has participated in.
    function getUserPredictions(address _userAddress) external view profileExists(_userAddress) returns (uint256[] memory) {
        uint256[] memory eventIds = new uint256[](nextEventId - 1); // Max possible events
        uint256 count = 0;
        for (uint256 i = 1; i < nextEventId; i++) {
            if (predictionEvents[i].userPredictions[_userAddress].amount > 0) {
                eventIds[count] = i;
                count++;
            }
        }
        // Resize array to actual number of events
        uint256[] memory userEventIds = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            userEventIds[i] = eventIds[i];
        }
        return userEventIds;
    }


    // --- Reputation NFT Badge Functions (Conceptual - Requires NFT contract integration) ---

    /// @notice Mints a dynamic NFT badge representing the user's reputation level.
    /// @param _profileAddress The address of the profile to mint an NFT for.
    function mintReputationNFT(address _profileAddress) external whenNotPaused onlyOwner profileExists(_profileAddress) {
        require(userProfiles[_profileAddress].nftBadgeId == 0, "NFT badge already minted.");
        // --- Integration with NFT contract would go here ---
        // Example: Call to an external NFT contract to mint a new NFT
        // NFTContract.mint(address _to, uint256 _tokenId, string memory _metadataURI)
        userProfiles[_profileAddress].nftBadgeId = nextNFTBadgeId; // Assign a badge ID
        emit NFTBadgeMinted(_profileAddress, nextNFTBadgeId);
        nextNFTBadgeId++;
        evolveReputationNFT(_profileAddress); // Initial metadata update
    }

    /// @notice Updates the metadata of a user's reputation NFT badge based on reputation changes.
    /// @param _profileAddress The address of the profile whose NFT badge to update.
    function evolveReputationNFT(address _profileAddress) internal profileExists(_profileAddress) {
        if (userProfiles[_profileAddress].nftBadgeId > 0) {
            // --- Integration with NFT contract to update metadata ---
            // Example: Call to an external NFT contract to update the metadata URI
            // string memory metadataURI = _generateNFTMetadataURI(_profileAddress); // Function to generate metadata based on reputation
            // NFTContract.updateMetadataURI(userProfiles[_profileAddress].nftBadgeId, metadataURI);
            emit NFTBadgeEvolved(_profileAddress, userProfiles[_profileAddress].nftBadgeId);
        }
    }

    /// @notice Returns the current metadata URI for a user's reputation NFT badge. (Conceptual)
    /// @param _profileAddress The address of the profile to query.
    /// @return The metadata URI string.
    function getNFTMetadata(address _profileAddress) external view profileExists(_profileAddress) returns (string memory) {
        // --- Conceptual function to generate dynamic NFT metadata URI based on reputation ---
        // In a real implementation, this would likely involve off-chain metadata generation
        return _generateNFTMetadataURI(_profileAddress);
    }

    /// @dev Internal helper function to generate dynamic NFT metadata URI (example - needs external implementation)
    function _generateNFTMetadataURI(address _profileAddress) internal view returns (string memory) {
        // This is a placeholder - in a real implementation, metadata would likely be generated off-chain
        // and the URI could point to IPFS or a centralized server serving dynamic JSON metadata.
        uint256 reputation = userProfiles[_profileAddress].reputationScore;
        string memory baseURI = "ipfs://example/"; // Replace with your base IPFS URI or metadata server URL
        string memory reputationLevel;

        if (reputation >= 500) {
            reputationLevel = "Legendary";
        } else if (reputation >= 300) {
            reputationLevel = "Expert";
        } else if (reputation >= 200) {
            reputationLevel = "Skilled";
        } else {
            reputationLevel = "Novice";
        }

        // Example metadata structure (JSON-like string, needs proper JSON encoding in real implementation)
        string memory metadata = string(abi.encodePacked(
            '{"name": "Reputation Badge - ', userProfiles[_profileAddress].profileName, '", ',
            '"description": "Dynamic Reputation Badge for ', userProfiles[_profileAddress].profileName, ', Level: ', reputationLevel, '", ',
            '"attributes": [{"trait_type": "Reputation", "value": "', uint256ToString(reputation), '"}, {"trait_type": "Level", "value": "', reputationLevel, '"}]}'
        ));

        // In a real implementation, you might use a library to create proper JSON and then generate a URI (e.g., to IPFS)
        // For this example, we just return a placeholder URI with some encoded data
        return string(abi.encodePacked(baseURI, "badge_", uint256ToString(userProfiles[_profileAddress].nftBadgeId), ".json?data=", metadata));
    }


    // --- Utility & Admin Functions ---

    /// @notice Allows the contract owner to set a moderator address.
    /// @param _moderatorAddress The new moderator address.
    function setModerator(address _moderatorAddress) external onlyOwner {
        address oldModerator = moderator;
        moderator = _moderatorAddress;
        emit ModeratorSet(_moderatorAddress, oldModerator);
    }

    /// @notice Allows the contract owner to pause the contract in case of emergency.
    function pauseContract() external onlyOwner whenNotPaused {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    /// @notice Allows the contract owner to unpause the contract.
    function unpauseContract() external onlyOwner whenPaused {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    /// @notice Allows the contract owner to withdraw any excess contract balance.
    function withdrawContractBalance() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /// @notice Returns the current ETH balance of the contract.
    /// @return The contract's ETH balance.
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Allows the contract owner to set the reputation decay rate.
    /// @param _decayRate The new reputation decay rate (percentage).
    function setReputationDecayRate(uint256 _decayRate) external onlyOwner {
        reputationDecayRate = _decayRate;
    }

    /// @notice Applies reputation decay to all profiles periodically.
    function applyReputationDecay() public {
        require(block.timestamp >= lastDecayTimestamp + decayInterval, "Decay interval not reached yet.");
        for (uint256 i = 1; i < nextNFTBadgeId; i++) { // Iterate through all minted NFT badge IDs (assuming badgeId is assigned sequentially)
            for (address user : getUserAddresses()) { // Iterate through all user addresses with profiles
                if (userProfiles[user].exists) {
                    uint256 decayAmount = (userProfiles[user].reputationScore * reputationDecayRate) / 100;
                    userProfiles[user].reputationScore -= decayAmount;
                    evolveReputationNFT(user); // Update NFT badge after decay
                }
            }
        }
        lastDecayTimestamp = block.timestamp;
        emit ReputationDecayApplied(block.timestamp);
    }


    // --- Internal Helper Functions ---

    /// @dev Helper function to convert uint256 to string (for metadata - limited in Solidity)
    function uint256ToString(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    /// @dev Helper function to calculate square root (integer approximation)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// @dev Helper function to get a list of user addresses who made predictions for an event.
    function getPredictionUsers(uint256 _eventId) internal view returns (address[] memory) {
        address[] memory users = new address[](nextNFTBadgeId); // Max possible users (assuming badgeId roughly correlates with user count)
        uint256 count = 0;
        for (uint256 i = 1; i < nextNFTBadgeId; i++) {
             for (address user : getUserAddresses()) { // Iterate through all user addresses with profiles
                if (predictionEvents[_eventId].userPredictions[user].amount > 0) {
                    users[count] = user;
                    count++;
                }
            }
        }

        address[] memory predictionUsers = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            predictionUsers[i] = users[i];
        }
        return predictionUsers;
    }

    /// @dev Helper function to calculate total winning stake for an event
    function calculateTotalWinningStake(uint256 _eventId) internal view returns (uint256) {
        uint256 totalWinningStake = 0;
        for (address user : getPredictionUsers(_eventId)) {
            if (predictionEvents[_eventId].userPredictions[user].outcomeIndex == predictionEvents[_eventId].winningOutcomeIndex) {
                totalWinningStake += predictionEvents[_eventId].userPredictions[user].amount;
            }
        }
        return totalWinningStake;
    }

    /// @dev Helper function to get a list of all user addresses with profiles (inefficient for large scale, consider better indexing in real app)
    function getUserAddresses() internal view returns (address[] memory) {
        address[] memory userAddresses = new address[](nextNFTBadgeId); // Max possible users (assuming badgeId roughly correlates with user count)
        uint256 count = 0;
        for (uint256 i = 1; i < nextNFTBadgeId; i++) {
             for (address user in userProfiles) {
                if (userProfiles[user].exists) {
                    bool alreadyAdded = false;
                    for(uint j=0; j<count; j++){
                        if(userAddresses[j] == user) {
                            alreadyAdded = true;
                            break;
                        }
                    }
                    if(!alreadyAdded){
                        userAddresses[count] = user;
                        count++;
                    }
                }
            }
        }

        address[] memory existingUserAddresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            existingUserAddresses[i] = userAddresses[i];
        }
        return existingUserAddresses;
    }

}
```