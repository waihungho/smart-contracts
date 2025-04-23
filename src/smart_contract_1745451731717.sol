Okay, here is a Solidity smart contract incorporating several advanced, creative, and trendy concepts like dynamic NFTs, epoch-based mechanics, staking, event-driven state changes, a simplified prediction element, and tiered access/rewards. It avoids directly duplicating well-known open-source protocols by combining these elements in a unique "ChronoForge Epochs" system.

The contract manages dynamic ERC-1155 tokens whose properties change based on user activity within timed "Epochs," stake levels, and a simple on-chain prediction/outcome mechanism.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Using Ownable for simplicity, could expand to roles
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// --- Outline ---
// 1. State Variables & Constants: Define core parameters, mappings, and epoch state.
// 2. Enums & Structs: Define Epoch status and NFT property structure.
// 3. Events: Announce key actions and state changes.
// 4. Modifiers: Control access and contract state.
// 5. Constructor: Initialize contract with token addresses and base settings.
// 6. ERC-1155 Overrides: Implement required ERC-1155 functions (like uri).
// 7. Staking Functions: Handle user staking and unstaking of tokens.
// 8. NFT Management Functions: Handle minting and burning of Epoch NFTs (ERC-1155).
// 9. Epoch Management Functions: Admin functions to start, end, and reveal outcomes of epochs.
// 10. Epoch Participation Functions: User functions for contributing and predicting within an epoch.
// 11. Dynamic NFT & Scoring Functions: Internal logic to update NFT properties and calculate scores based on epoch activity/outcome. Exposed via view functions.
// 12. Reward & Claim Functions: Admin to deposit rewards, Users to claim based on epoch performance/NFT state.
// 13. Admin & Utility Functions: Control contract state, settings, and access.
// 14. View Functions: Public read-only functions to query contract state.

// --- Function Summary ---
// --- Staking ---
// 1. stakeTokens(uint256 amount): User stakes STAKE_TOKEN.
// 2. unstakeTokens(uint256 amount): User unstakes STAKE_TOKEN (subject to epoch status).
// --- NFT Management ---
// 3. mintEpochNFT(uint256 tokenId, uint256 amount): User mints a specific type/amount of Epoch NFT by meeting stake requirements or paying stake tokens.
// 4. burnEpochNFT(uint256 tokenId, uint256 amount): User burns a specific type/amount of Epoch NFT.
// 5. uri(uint256 tokenId): Standard ERC-1155 function overridden to potentially point to dynamic metadata.
// --- Epoch Management (Admin) ---
// 6. startNewEpoch(uint256 duration): Admin starts a new epoch with a specified duration.
// 7. endCurrentEpoch(): Admin ends the active epoch (transitions to OutcomePending).
// 8. revealEpochOutcome(uint256 outcome): Admin reveals the verifiable outcome for the ended epoch.
// --- Epoch Participation ---
// 9. submitEpochContribution(bytes memory data): User submits abstract contribution data during an active epoch.
// 10. submitEpochPrediction(uint256 prediction): User submits a prediction for the epoch outcome during an active epoch.
// --- Dynamic NFT & Scoring ---
// 11. _calculateUserEpochScore(uint256 epochId, address user): Internal helper to calculate a user's performance score for an epoch.
// 12. _updateUserNFTProperties(uint256 epochId, address user, uint256 tokenId): Internal helper to update dynamic NFT properties based on epoch results.
// --- Rewards & Claiming ---
// 13. depositRewardTokens(uint256 amount): Admin deposits REWARD_TOKEN into the contract's reward pool.
// 14. claimEpochRewards(uint256 epochId): User claims rewards for a specific past epoch based on their score and NFT properties.
// --- Admin & Utility ---
// 15. grantAdmin(address account): Owner grants admin role to an account.
// 16. revokeAdmin(address account): Owner revokes admin role from an account.
// 17. pauseContract(): Admin pauses key contract functions.
// 18. unpauseContract(): Admin unpauses the contract.
// 19. setEpochDuration(uint256 duration): Admin sets the default duration for future epochs.
// 20. setMinStakeRequirement(uint256 amount): Admin sets the minimum total stake required for certain actions (e.g., minting NFT type 1).
// 21. setNFTMintCost(uint256 tokenId, uint256 costInStakeTokens): Admin sets the cost in stake tokens to mint a specific NFT type.
// 22. setEpochScoreWeights(uint256 contributionWeight, uint256 predictionWeight, uint256 stakeWeight): Admin sets weights for score calculation.
// 23. withdrawAdminFees(address token, uint256 amount): Admin withdraws collected fees (if a fee mechanism is added). Placeholder for now.
// --- View Functions ---
// 24. getStakedBalance(address user): Get user's current staked balance.
// 25. getUserNFTProperties(address user, uint256 tokenId): Get current dynamic properties for a user's NFT type.
// 26. getEpochDetails(uint256 epochId): Get details about a specific epoch.
// 27. getCurrentEpochId(): Get the ID of the current or latest epoch.
// 28. getUserPrediction(uint256 epochId, address user): Get a user's prediction for an epoch.
// 29. viewUserEpochScore(uint256 epochId, address user): View calculated score for a user in a past epoch.
// 30. getEpochOutcome(uint256 epochId): Get the revealed outcome for an epoch.
// 31. getRewardPoolBalance(): Get the contract's REWARD_TOKEN balance.
// 32. isAdmin(address account): Check if an account has admin role.
// 33. getEpochScoreWeights(): Get the current epoch score calculation weights.
// (Inherited ERC-1155 functions like balanceOf, balanceOfBatch, setApprovalForAll, isApprovedForAll also exist but are standard).

contract ChronoForgeEpochs is ERC1155, Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    // --- Constants & State Variables ---

    IERC20 public immutable STAKE_TOKEN;
    IERC20 public immutable REWARD_TOKEN;

    uint256 private _currentEpochId = 0;
    uint256 public defaultEpochDuration = 7 days; // Default duration for new epochs

    uint256 public minStakeRequirement = 100e18; // Example: 100 tokens

    // Mapping for user staked balances
    mapping(address => uint256) private _stakedBalances;

    // Mapping for tracking admin roles (beyond the owner)
    mapping(address => bool) private _admins;

    // --- Epoch State ---
    enum EpochStatus {
        Pending, // Before startNewEpoch
        Active, // Within start time and end time
        OutcomePending, // After end time, before outcome revealed
        Ended // After outcome revealed
    }

    struct EpochData {
        uint256 startTime;
        uint256 endTime;
        EpochStatus status;
        uint256 outcome; // Revealed outcome (e.g., 0, 1, 2...)
        bool outcomeRevealed;
        uint256 totalParticipants; // Count users who participated (contributed or predicted)
    }

    mapping(uint256 => EpochData) public epochs;

    // Mapping epochId -> user -> prediction (e.g., 0, 1, 2...)
    mapping(uint256 => mapping(address => uint256)) private _epochPredictions;

    // Mapping epochId -> user -> bool (true if contributed) - Simplified contribution
    mapping(uint256 => mapping(address => bool)) private _epochContributions;

    // Mapping epochId -> user -> bool (true if rewards claimed)
    mapping(uint256 => mapping(address => bool)) private _epochRewardsClaimed;

    // --- Dynamic NFT Properties ---
    // Example structure for dynamic properties per user per NFT type
    struct NFTProperties {
        uint256 lastEpochScore; // Score in the last epoch the user participated with this NFT type
        uint256 totalEpochsParticipated; // Total epochs user participated with this NFT type
        uint256 totalSuccessfulPredictions; // Count of successful predictions
        string dynamicTraitData; // Placeholder for dynamic traits (e.g., JSON IPFS hash)
    }

    // Mapping user -> tokenId -> NFTProperties
    mapping(address => mapping(uint256 => NFTProperties)) public userNFTProperties;

    // Mapping tokenId -> cost in STAKE_TOKEN to mint
    mapping(uint256 => uint256) public nftMintCost;

    // Score calculation weights
    uint256 public contributionScoreWeight = 1;
    uint256 public predictionScoreWeight = 5;
    uint256 public stakeScoreWeight = 1; // Applied per unit of relevant stake


    // --- Events ---
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event NFTMinted(address indexed user, uint256 tokenId, uint256 amount, uint256 costInStakeTokens);
    event NFTBurned(address indexed user, uint256 tokenId, uint256 amount);
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 endTime);
    event EpochEnded(uint256 indexed epochId, uint256 endTime);
    event EpochOutcomeRevealed(uint256 indexed epochId, uint256 outcome);
    event ContributionSubmitted(uint256 indexed epochId, address indexed user); // Simplified event
    event PredictionSubmitted(uint256 indexed epochId, address indexed user, uint256 prediction);
    event NFTPropertiesUpdated(address indexed user, uint256 indexed tokenId, uint256 epochId, uint256 score);
    event RewardsDeposited(address indexed depositor, uint256 amount);
    event RewardsClaimed(uint256 indexed epochId, address indexed user, uint256 amount);
    event AdminGranted(address indexed account);
    event AdminRevoked(address indexed account);
    event EpochDurationUpdated(uint256 newDuration);
    event MinStakeRequirementUpdated(uint256 newRequirement);
    event NFTMintCostUpdated(uint256 indexed tokenId, uint256 newCost);
    event EpochScoreWeightsUpdated(uint256 contribution, uint256 prediction, uint256 stake);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(_admins[msg.sender] || owner() == msg.sender, "Not authorized: Admin or Owner required");
        _;
    }

    modifier onlyEpochStatus(uint256 epochId, EpochStatus status) {
        require(epochs[epochId].status == status, "Invalid epoch status");
        _;
    }

    modifier onlyCurrentEpochStatus(EpochStatus status) {
        require(epochs[_currentEpochId].status == status, "Invalid current epoch status");
        _;
    }

    // --- Constructor ---
    constructor(address stakeTokenAddress, address rewardTokenAddress, string memory uri_)
        ERC1155(uri_)
        Ownable(msg.sender) // Sets the contract deployer as the initial owner
        Pausable()
    {
        STAKE_TOKEN = IERC20(stakeTokenAddress);
        REWARD_TOKEN = IERC20(rewardTokenAddress);

        // Initialize epoch 0 as ended or placeholder if needed
        epochs[0] = EpochData({
            startTime: 0,
            endTime: 0,
            status: EpochStatus.Ended,
            outcome: 0,
            outcomeRevealed: true,
            totalParticipants: 0
        });
    }

    // --- ERC-1155 Overrides ---

    // Override to provide dynamic metadata URI if needed, or static base URI
    // This implementation uses a simple base URI + token ID
    // For truly dynamic metadata, you'd need a separate service responding to tokenURI
    function uri(uint256 tokenId) override public view returns (string memory) {
        // Example: return base URI + tokenId (e.g., ipfs://.../{id}.json)
        // A more advanced version could check userNFTProperties[msg.sender][tokenId].dynamicTraitData
        // and return a different URI or data URL based on the dynamic state.
        return string(abi.encodePacked(super.uri(tokenId), toString(tokenId)));
    }

    // Override _beforeTokenTransfer to potentially add hooks based on transfer type
    // For this contract, let's disallow transfer of specific "soulbound" like tokens (optional)
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Example: Prevent transfer of NFT type 1 (like a reputation score)
        // for (uint i = 0; i < ids.length; ++i) {
        //     if (ids[i] == 1) { // Assuming tokenId 1 is soulbound
        //         require(from == address(0) || to == address(0), "Token ID 1 is not transferable");
        //     }
        // }

        // Note: For dynamic properties tracked per user per tokenId, transferring
        // the token means the new owner doesn't inherit the old owner's properties.
        // If properties should follow the NFT, the mapping would need to be
        // mapping(uint256 => NFTProperties) per specific token instance, which
        // is complex with ERC-1155 batching. Tracking per user/tokenId is simpler
        // and implies the properties are tied to the *user's engagement level*
        // associated with holding that token type.
    }

    // Helper function for uri override
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
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }
        return string(buffer);
    }

    // --- Staking Functions ---

    function stakeTokens(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Stake amount must be greater than 0");

        // Approve call must happen BEFORE calling stakeTokens
        IERC20(STAKE_TOKEN).transferFrom(msg.sender, address(this), amount);
        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].add(amount);

        emit Staked(msg.sender, amount);
    }

    function unstakeTokens(uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Unstake amount must be greater than 0");
        require(_stakedBalances[msg.sender] >= amount, "Insufficient staked balance");
        // Disallow unstaking during an active epoch to prevent gaming the system
        require(epochs[_currentEpochId].status != EpochStatus.Active, "Cannot unstake during active epoch");

        _stakedBalances[msg.sender] = _stakedBalances[msg.sender].sub(amount);
        IERC20(STAKE_TOKEN).transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    // --- NFT Management Functions ---

    // Mint an NFT of a specific type (tokenId)
    // Could require a minimum stake, or consume staked tokens as a cost
    function mintEpochNFT(uint256 tokenId, uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        // Optional: require epoch status allows minting (e.g., only between epochs)
        require(epochs[_currentEpochId].status != EpochStatus.Active, "Cannot mint NFTs during active epoch");

        uint256 cost = nftMintCost[tokenId];
        if (cost > 0) {
             uint256 totalCost = cost.mul(amount);
             require(_stakedBalances[msg.sender] >= totalCost, "Insufficient staked balance for minting cost");
             _stakedBalances[msg.sender] = _stakedBalances[msg.sender].sub(totalCost);
             // Note: Stake tokens are burned or re-pooled, not transferred back to contract owner here.
             // A fee withdrawal function for admin exists separately.
        } else {
             // If no specific cost set, maybe require a minimum total stake?
             require(_stakedBalances[msg.sender] >= minStakeRequirement, "Minimum stake requirement not met");
        }

        _mint(msg.sender, tokenId, amount, "");

        // Initialize or update dynamic properties for the user and token type
        // Initial properties could be based on current stake or epoch ID
        userNFTProperties[msg.sender][tokenId].totalEpochsParticipated = userNFTProperties[msg.sender][tokenId].totalEpochsParticipated.add(0); // Just ensuring struct exists

        emit NFTMinted(msg.sender, tokenId, amount, cost.mul(amount));
    }

    // Burn an NFT
    // Could potentially refund some staked tokens, or have other effects
    function burnEpochNFT(uint256 tokenId, uint256 amount) public whenNotPaused nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender, tokenId) >= amount, "Insufficient NFT balance");

        _burn(msg.sender, tokenId, amount);

        // Optional: Clean up/reset dynamic properties if burning should remove progress
        // userNFTProperties[msg.sender][tokenId] = NFTProperties(0, 0, 0, ""); // Reset properties

        emit NFTBurned(msg.sender, tokenId, amount);
    }

    // --- Epoch Management Functions (Admin) ---

    function startNewEpoch(uint256 duration) public onlyAdmin whenNotPaused {
        require(epochs[_currentEpochId].status == EpochStatus.Ended, "Previous epoch must be ended to start a new one");
        require(duration > 0, "Epoch duration must be greater than 0");

        _currentEpochId = _currentEpochId.add(1);
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime.add(duration);

        epochs[_currentEpochId] = EpochData({
            startTime: startTime,
            endTime: endTime,
            status: EpochStatus.Active,
            outcome: 0, // Outcome unknown initially
            outcomeRevealed: false,
            totalParticipants: 0
        });

        emit EpochStarted(_currentEpochId, startTime, endTime);
    }

    function endCurrentEpoch() public onlyAdmin whenNotPaused onlyCurrentEpochStatus(EpochStatus.Active) {
        // Ensure epoch duration has passed (or allow admin override)
        require(block.timestamp >= epochs[_currentEpochId].endTime, "Epoch duration not yet passed");

        epochs[_currentEpochId].status = EpochStatus.OutcomePending;

        emit EpochEnded(_currentEpochId, block.timestamp);
    }

    function revealEpochOutcome(uint256 outcome) public onlyAdmin whenNotPaused onlyCurrentEpochStatus(EpochStatus.OutcomePending) {
        EpochData storage currentEpoch = epochs[_currentEpochId];
        require(!currentEpoch.outcomeRevealed, "Outcome already revealed for this epoch");

        currentEpoch.outcome = outcome;
        currentEpoch.outcomeRevealed = true;
        currentEpoch.status = EpochStatus.Ended;

        // After outcome is revealed, scores and NFT properties can be calculated/updated
        // This might be triggered here, or left for users to trigger via a claim function
        // Let's make property update happen upon reward claim or view calculation.

        emit EpochOutcomeRevealed(_currentEpochId, outcome);
    }

    // --- Epoch Participation Functions ---

    function submitEpochContribution(bytes memory data) public whenNotPaused nonReentrant onlyCurrentEpochStatus(EpochStatus.Active) {
        uint256 currentId = _currentEpochId;
        // Basic check: has user already contributed this epoch?
        require(!_epochContributions[currentId][msg.sender], "Already contributed in this epoch");

        // Store simplified contribution status
        _epochContributions[currentId][msg.sender] = true;
        epochs[currentId].totalParticipants = epochs[currentId].totalParticipants.add(1); // Increment participation count (simple)

        // The actual 'data' isn't used in this simplified version but shows capability
        // Could be a ZK proof hash, a link to external activity, etc.

        emit ContributionSubmitted(currentId, msg.sender);
    }

    function submitEpochPrediction(uint256 prediction) public whenNotPaused nonReentrant onlyCurrentEpochStatus(EpochStatus.Active) {
        uint256 currentId = _currentEpochId;
        // Basic check: has user already predicted this epoch?
        require(_epochPredictions[currentId][msg.sender] == 0, "Already predicted in this epoch"); // Assuming 0 is an invalid prediction value

        _epochPredictions[currentId][msg.sender] = prediction;
        // Only count participation if they *didn't* contribute, otherwise count in contribution
        if (!_epochContributions[currentId][msg.sender]) {
             epochs[currentId].totalParticipants = epochs[currentId].totalParticipants.add(1);
        }


        emit PredictionSubmitted(currentId, msg.sender, prediction);
    }

    // --- Dynamic NFT & Scoring Functions ---

    // Internal function to calculate a user's score for a specific epoch
    // This logic is central to the dynamic properties and rewards
    function _calculateUserEpochScore(uint256 epochId, address user) internal view returns (uint256 score) {
        EpochData storage epoch = epochs[epochId];
        require(epoch.status == EpochStatus.Ended && epoch.outcomeRevealed, "Epoch outcome not revealed");

        uint256 baseScore = 100; // Everyone gets a base score for participating

        uint256 contributionBonus = 0;
        if (_epochContributions[epochId][user]) {
            contributionBonus = 50 * contributionScoreWeight; // Example bonus
        }

        uint256 predictionBonus = 0;
        if (_epochPredictions[epochId][user] > 0 && _epochPredictions[epochId][user] == epoch.outcome) {
            predictionBonus = 100 * predictionScoreWeight; // Example bonus for correct prediction
        }

        // Stake bonus based on user's staked balance *at the time of calculation*
        // A more complex system might snapshot stake at epoch start/end
        uint256 stakeBonus = _stakedBalances[user].div(1e18).mul(stakeScoreWeight); // Simplified: 1 bonus point per 1 token staked

        score = baseScore.add(contributionBonus).add(predictionBonus).add(stakeBonus);

        // Further logic could incorporate NFT properties held *during* that epoch,
        // e.g., "holders of NFT type X get 20% score boost"
        // This requires tracking which NFTs a user held during which epoch, which adds complexity.
        // For simplicity, let's only update *current* NFT properties based on *past* scores.
    }

    // Internal function to update NFT properties based on score and outcome
    function _updateUserNFTProperties(uint256 epochId, address user, uint256 score, uint256 outcome) internal {
        // Iterate over NFT types the user holds that are eligible for property updates
        // This would need to be explicit - which NFT types are dynamic? Let's assume tokenIds 1, 2, 3 are.
        uint256[] memory dynamicTokenIds = new uint256[](3); // Example dynamic token IDs
        dynamicTokenIds[0] = 1; dynamicTokenIds[1] = 2; dynamicTokenIds[2] = 3;

        for(uint i = 0; i < dynamicTokenIds.length; i++) {
            uint256 tokenId = dynamicTokenIds[i];
            if (balanceOf(user, tokenId) > 0) {
                NFTProperties storage props = userNFTProperties[user][tokenId];

                props.lastEpochScore = score;
                props.totalEpochsParticipated = props.totalEpochsParticipated.add(1);

                if (_epochPredictions[epochId][user] > 0 && _epochPredictions[epochId][user] == outcome) {
                     props.totalSuccessfulPredictions = props.totalSuccessfulPredictions.add(1);
                }

                // Example dynamic trait logic: Update a string based on performance
                if (score > 500) {
                    props.dynamicTraitData = "Rank: Elite";
                } else if (score > 200) {
                    props.dynamicTraitData = "Rank: Veteran";
                } else {
                    props.dynamicTraitData = "Rank: Novice";
                }
                 // More complex logic could evolve traits, merge NFTs, etc.

                emit NFTPropertiesUpdated(user, tokenId, epochId, score);
            }
        }
    }

    // --- Reward & Claim Functions ---

    function depositRewardTokens(uint256 amount) public onlyAdmin whenNotPaused nonReentrant {
         require(amount > 0, "Amount must be greater than 0");
         IERC20(REWARD_TOKEN).transferFrom(msg.sender, address(this), amount);
         emit RewardsDeposited(msg.sender, amount);
    }

    function claimEpochRewards(uint256 epochId) public whenNotPaused nonReentrant {
        EpochData storage epoch = epochs[epochId];
        require(epoch.status == EpochStatus.Ended && epoch.outcomeRevealed, "Epoch outcome not revealed or epoch not ended");
        require(!_epochRewardsClaimed[epochId][msg.sender], "Rewards already claimed for this epoch");

        // Ensure user held relevant NFTs or participated in this specific epoch?
        // For simplicity, let's allow claiming if they participated (contributed or predicted) OR held relevant NFTs.
        bool participated = _epochContributions[epochId][msg.sender] || _epochPredictions[epochId][msg.sender] > 0;
        bool heldNFTs = balanceOf(msg.sender, 1) > 0 || balanceOf(msg.sender, 2) > 0 || balanceOf(msg.sender, 3) > 0; // Check if they held dynamic NFTs

        require(participated || heldNFTs, "No participation or eligible NFTs found for this epoch");

        uint256 score = _calculateUserEpochScore(epochId, msg.sender);

        // Calculate reward amount based on score and potentially NFT properties at the time of claim
        uint256 rewardAmount = score.mul(1e16); // Example: 0.01 reward token per score point

        // Update dynamic NFT properties based on this epoch's performance upon claiming
        _updateUserNFTProperties(epochId, msg.sender, score, epoch.outcome);

        _epochRewardsClaimed[epochId][msg.sender] = true;

        require(IERC20(REWARD_TOKEN).balanceOf(address(this)) >= rewardAmount, "Insufficient reward token balance in contract");
        IERC20(REWARD_TOKEN).transfer(msg.sender, rewardAmount);

        emit RewardsClaimed(epochId, msg.sender, rewardAmount);
    }

    // --- Admin & Utility Functions ---

    function grantAdmin(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
        _admins[account] = true;
        emit AdminGranted(account);
    }

    function revokeAdmin(address account) public onlyOwner {
        require(account != address(0), "Invalid address");
        _admins[account] = false;
        emit AdminRevoked(account);
    }

    function pauseContract() public onlyAdmin {
        _pause();
    }

    function unpauseContract() public onlyAdmin {
        _unpause();
    }

    function setEpochDuration(uint256 duration) public onlyAdmin whenNotPaused {
        require(duration > 0, "Duration must be greater than 0");
        defaultEpochDuration = duration;
        emit EpochDurationUpdated(duration);
    }

    function setMinStakeRequirement(uint256 amount) public onlyAdmin whenNotPaused {
        minStakeRequirement = amount;
        emit MinStakeRequirementUpdated(amount);
    }

    function setNFTMintCost(uint256 tokenId, uint256 costInStakeTokens) public onlyAdmin whenNotPaused {
        nftMintCost[tokenId] = costInStakeTokens;
        emit NFTMintCostUpdated(tokenId, costInStakeTokens);
    }

    function setEpochScoreWeights(uint256 contributionWeight, uint256 predictionWeight, uint256 stakeWeight) public onlyAdmin whenNotPaused {
        contributionScoreWeight = contributionWeight;
        predictionScoreWeight = predictionWeight;
        stakeScoreWeight = stakeWeight;
        emit EpochScoreWeightsUpdated(contributionWeight, predictionWeight, stakeWeight);
    }

    // Admin function to withdraw potentially collected fees (if a fee mechanism was implemented)
    // Currently, stake tokens used for minting are not withdrawn as fees, but this function
    // could be used if a fee percentage was added to staking/unstaking/claiming etc.
    function withdrawAdminFees(address token, uint256 amount) public onlyAdmin nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        IERC20 feeToken = IERC20(token);
        require(feeToken.balanceOf(address(this)) >= amount, "Insufficient token balance");
        feeToken.transfer(msg.sender, amount);
    }

    // --- View Functions ---

    function getStakedBalance(address user) public view returns (uint256) {
        return _stakedBalances[user];
    }

    function getUserNFTProperties(address user, uint256 tokenId) public view returns (NFTProperties memory) {
        return userNFTProperties[user][tokenId];
    }

    function getEpochDetails(uint256 epochId) public view returns (EpochData memory) {
        require(epochId <= _currentEpochId, "Invalid epoch ID");
        return epochs[epochId];
    }

    function getCurrentEpochId() public view returns (uint256) {
        return _currentEpochId;
    }

     function getUserPrediction(uint256 epochId, address user) public view returns (uint256) {
        require(epochId <= _currentEpochId, "Invalid epoch ID");
        return _epochPredictions[epochId][user];
    }

    // View function to see calculated score for a past epoch without claiming
    function viewUserEpochScore(uint256 epochId, address user) public view returns (uint256) {
         EpochData storage epoch = epochs[epochId];
         require(epoch.status == EpochStatus.Ended && epoch.outcomeRevealed, "Epoch outcome not revealed or epoch not ended");
         return _calculateUserEpochScore(epochId, user);
    }

    function getEpochOutcome(uint256 epochId) public view returns (uint256) {
        require(epochId <= _currentEpochId, "Invalid epoch ID");
        require(epochs[epochId].outcomeRevealed, "Outcome not revealed");
        return epochs[epochId].outcome;
    }

    function getRewardPoolBalance() public view returns (uint256) {
        return IERC20(REWARD_TOKEN).balanceOf(address(this));
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account] || owner() == account;
    }

    function getEpochScoreWeights() public view returns (uint256 contribution, uint256 prediction, uint256 stake) {
        return (contributionScoreWeight, predictionScoreWeight, stakeScoreWeight);
    }

    // ERC165 support
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, Ownable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```