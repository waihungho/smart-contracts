Okay, let's design a smart contract that combines several advanced concepts: dynamic NFT attributes, social staking, influence accrual, and weighted voting on on-chain parameters.

We'll call it `DynamicCanvasEngine`. Users stake an ERC-20 token to earn "Influence Points" over time. These points can be spent to vote on the dynamic attributes of a collective, conceptual "Canvas". Reaching certain milestones (like staking amount or influence spent) could mint dynamic NFTs ("Canvas Fragments") that capture the state of the Canvas at that moment.

This isn't a standard token, a simple NFT, or a typical staking pool. It involves state changes driven by user interaction and time-weighted accrual.

---

# Dynamic Canvas Engine Smart Contract

## Outline

1.  **Introduction:** A smart contract allowing users to stake ERC-20 tokens to earn Influence Points, which are then used to vote on dynamic "Canvas Attributes". Milestones in staking or voting can trigger the minting of dynamic NFTs (`Canvas Fragments`) that capture the Canvas state.
2.  **Inheritance:** Ownable (for owner control), Pausable (for emergency pauses), ERC721 (for Canvas Fragment NFTs).
3.  **State Variables:**
    *   Addresses of Stake Token and Reward Token.
    *   Configuration parameters (reward rates, influence rates, vote thresholds).
    *   User state mappings (staked amount, accrued rewards, accrued influence, last interaction time).
    *   Canvas Attribute definitions (name, type, min/max, current value).
    *   Attribute voting state (influence spent per attribute choice).
    *   NFT state (token counter, mapping of token ID to attribute snapshot).
4.  **Events:** Tracking staking, unstaking, claims, configuration changes, attribute votes, attribute state changes, NFT minting.
5.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, custom influence threshold checks.
6.  **Internal Logic:** Functions for calculating influence, calculating rewards, updating user state, processing attribute votes, minting NFTs.
7.  **Public/External Functions:**
    *   Configuration functions (set rates, add/update/remove attributes, pause).
    *   User interaction functions (stake, unstake, claim rewards, vote attribute).
    *   View functions (get user state, get attribute state, get contract parameters, get NFT details).

## Function Summary (Public/External)

1.  `constructor(address _stakeToken, address _rewardToken, string memory name, string memory symbol)`: Deploys the contract, sets tokens and NFT name/symbol.
2.  `setRewardToken(address _newRewardToken)`: Sets the address of the reward token (owner only).
3.  `setRewardRate(uint256 _rewardRatePerSecond)`: Sets the rate at which rewards accrue per staked token per second (owner only).
4.  `setInfluenceRate(uint256 _influenceRatePerSecond)`: Sets the rate at which influence points accrue per staked token per second (owner only).
5.  `setAttributeVoteThreshold(string memory attributeName, uint256 _requiredInfluence)`: Sets minimum influence needed to vote on a specific attribute (owner only).
6.  `setAttributeChangeThreshold(string memory attributeName, uint256 _requiredNetInfluence)`: Sets net influence difference needed to shift an attribute's state (owner only).
7.  `addCanvasAttribute(string memory name, int256 initialValue, int256 minValue, int256 maxValue)`: Defines a new dynamic attribute for the Canvas (owner only).
8.  `updateCanvasAttributeBounds(string memory name, int256 minValue, int256 maxValue)`: Updates the min/max bounds for an existing attribute (owner only).
9.  `removeCanvasAttribute(string memory name)`: Removes a dynamic attribute (owner only). Careful function.
10. `pause()`: Pauses critical user interactions (owner only).
11. `unpause()`: Unpauses critical user interactions (owner only).
12. `stake(uint256 amount)`: Stakes the specified amount of stake tokens. Requires prior approval. Updates state, calculates pending rewards/influence.
13. `unstake(uint256 amount)`: Unstakes the specified amount of stake tokens. Updates state, calculates pending rewards/influence.
14. `claimRewards()`: Claims accrued reward tokens. Updates state, calculates pending rewards/influence.
15. `voteAttribute(string memory attributeName, int256 value)`: Uses accrued influence points to vote for a specific value of an attribute. Spends influence.
16. `processAttributeVotes(string memory attributeName)`: Callable function (potentially by anyone meeting a threshold, or owner) to aggregate votes for an attribute and potentially change its state based on thresholds.
17. `getPendingRewards(address account)`: Views the amount of reward tokens accrued by an account.
18. `getInfluencePoints(address account)`: Views the current amount of influence points accrued by an account.
19. `getUserStake(address account)`: Views the amount of stake tokens currently staked by an account.
20. `getCanvasAttributeState(string memory attributeName)`: Views the current state (value, min, max) of a specific attribute.
21. `getAllCanvasAttributeStates()`: Views the states of all dynamic attributes.
22. `getCanvasAttributeNames()`: Views the names of all dynamic attributes.
23. `getAttributeVoteState(string memory attributeName)`: Views the current influence distribution for votes on a specific attribute.
24. `getUserAttributeVoteInfluence(address account, string memory attributeName)`: Views the amount of influence a user has spent voting on a specific attribute in the current voting round.
25. `getNFTAttributeSnapshot(uint256 tokenId)`: Views the Canvas attribute state snapshot associated with a specific Canvas Fragment NFT.
26. `getTotalStaked()`: Views the total amount of stake tokens staked in the contract.
27. `getContractParameters()`: Views core configuration parameters (rates, thresholds - summary).
28. `tokenURI(uint256 tokenId)`: ERC721 standard function to get metadata URI for an NFT. Will return a base64 encoded JSON string including the attribute snapshot.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol"; // To list all NFTs
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Outline:
// 1. Introduction: A smart contract allowing users to stake ERC-20 tokens to earn Influence Points, which are then used to vote on dynamic "Canvas Attributes". Milestones in staking or voting can trigger the minting of dynamic NFTs (`Canvas Fragments`) that capture the Canvas state.
// 2. Inheritance: Ownable, Pausable, ERC721, ERC721Enumerable.
// 3. State Variables: Token addresses, config params, user state (stake, influence, rewards, timestamps), Canvas attributes, voting state, NFT state.
// 4. Events: Tracking key actions (Stake, Unstake, Claim, Config, Vote, AttributeChange, NFTMint).
// 5. Modifiers: onlyOwner, whenNotPaused, whenPaused, influence checks.
// 6. Internal Logic: Calculation & state update helpers.
// 7. Public/External Functions: Config (1-11), User Actions (12-16), View (17-28).

// Function Summary (Public/External):
// 1. constructor(address _stakeToken, address _rewardToken, string memory name, string memory symbol): Deploys the contract, sets tokens and NFT name/symbol.
// 2. setRewardToken(address _newRewardToken): Sets the address of the reward token (owner only).
// 3. setRewardRate(uint256 _rewardRatePerSecond): Sets the rate at which rewards accrue per staked token per second (owner only).
// 4. setInfluenceRate(uint256 _influenceRatePerSecond): Sets the rate at which influence points accrue per staked token per second (owner only).
// 5. setAttributeVoteThreshold(string memory attributeName, uint256 _requiredInfluence): Sets minimum influence needed to vote on a specific attribute (owner only).
// 6. setAttributeChangeThreshold(string memory attributeName, uint256 _requiredNetInfluence): Sets net influence difference needed to shift an attribute's state (owner only).
// 7. addCanvasAttribute(string memory name, int256 initialValue, int256 minValue, int256 maxValue): Defines a new dynamic attribute for the Canvas (owner only).
// 8. updateCanvasAttributeBounds(string memory name, int256 minValue, int256 maxValue): Updates the min/max bounds for an existing attribute (owner only).
// 9. removeCanvasAttribute(string memory name): Removes a dynamic attribute (owner only). Careful function.
// 10. pause(): Pauses critical user interactions (owner only).
// 11. unpause(): Unpauses critical user interactions (owner only).
// 12. stake(uint256 amount): Stakes stake tokens. Requires prior approval.
// 13. unstake(uint256 amount): Unstakes stake tokens.
// 14. claimRewards(): Claims accrued reward tokens.
// 15. voteAttribute(string memory attributeName, int256 value): Uses influence points to vote for an attribute value.
// 16. processAttributeVotes(string memory attributeName): Aggregates votes for an attribute and potentially changes its state.
// 17. getPendingRewards(address account): Views pending reward tokens.
// 18. getInfluencePoints(address account): Views current influence points.
// 19. getUserStake(address account): Views staked amount.
// 20. getCanvasAttributeState(string memory attributeName): Views an attribute's state.
// 21. getAllCanvasAttributeStates(): Views all attribute states.
// 22. getCanvasAttributeNames(): Views names of all attributes.
// 23. getAttributeVoteState(string memory attributeName): Views vote distribution for an attribute.
// 24. getUserAttributeVoteInfluence(address account, string memory attributeName): Views user's influence spent on an attribute vote.
// 25. getNFTAttributeSnapshot(uint256 tokenId): Views attribute snapshot for an NFT.
// 26. getTotalStaked(): Views total staked amount in the contract.
// 27. getContractParameters(): Views core config.
// 28. tokenURI(uint256 tokenId): ERC721 standard metadata URI.

contract DynamicCanvasEngine is Ownable, Pausable, ERC721Enumerable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IERC20 public immutable stakeToken;
    IERC20 public rewardToken; // Can be changed by owner

    uint256 public rewardRatePerSecond; // Reward tokens per staked token per second
    uint256 public influenceRatePerSecond; // Influence points per staked token per second

    // User State
    mapping(address => uint256) public userStake;
    mapping(address => uint256) public userAccruedRewards;
    mapping(address => uint256) public userAccruedInfluence;
    mapping(address => uint256) public userLastInteractionTime; // Timestamp of last stake/unstake/claim/vote

    // Canvas Attributes (Dynamic State)
    struct CanvasAttribute {
        string name;
        int256 value;
        int256 minValue;
        int256 maxValue;
    }
    mapping(string => CanvasAttribute) private canvasAttributes;
    string[] private canvasAttributeNames; // Keep track of attribute names for iteration

    // Attribute Voting State
    // Maps attribute name => desired value => total influence spent voting for this value
    mapping(string => mapping(int256 => uint256)) private attributeVoteInfluence;
    // Maps user address => attribute name => influence spent in the *current* voting round for that attribute
    mapping(address => mapping(string => uint256)) private userInfluenceSpentOnVote;
     // Maps attribute name => total influence spent in the current voting round for that attribute
    mapping(string => uint256) private totalInfluenceSpentOnAttribute;
    // Tracks the last time votes were processed for an attribute
    mapping(string => uint256) private lastVoteProcessingTime;


    // Configuration Thresholds
    mapping(string => uint256) public attributeVoteThreshold; // Min influence needed to cast a vote on this attribute
    mapping(string => uint256) public attributeChangeThreshold; // Min net influence difference needed to affect attribute value

    // NFT State (Canvas Fragment Snapshots)
    struct AttributeSnapshot {
        string name;
        int256 value;
    }
    mapping(uint256 => AttributeSnapshot[]) public nftAttributeSnapshots;

    // NFT Minting Thresholds (Example: Mint NFT for user who contributes significant influence to a winning vote)
    uint256 public influenceContributionNFTThreshold = 1000e18; // Example threshold (using 18 decimals for Influence)

    // Events
    event Stake(address indexed account, uint256 amount, uint256 newTotalStake);
    event Unstake(address indexed account, uint256 amount, uint256 newTotalStake);
    event RewardsClaimed(address indexed account, uint256 amount);
    event ConfigUpdated(string paramName, uint256 value);
    event TokenConfigUpdated(string paramName, address tokenAddress);
    event CanvasAttributeAdded(string name, int256 initialValue, int256 minValue, int256 maxValue);
    event CanvasAttributeUpdated(string name, int256 value, int256 minValue, int256 maxValue);
    event CanvasAttributeRemoved(string name);
    event AttributeVote(address indexed account, string indexed attributeName, int256 value, uint256 influenceSpent);
    event AttributeStateChanged(string indexed attributeName, int256 oldValue, int256 newValue);
    event CanvasFragmentMinted(address indexed owner, uint256 indexed tokenId, string attributeSnapshotDigest);


    // --- Constructor ---
    constructor(address _stakeToken, address _rewardToken, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(msg.sender)
    {
        require(_stakeToken != address(0), "Stake token cannot be zero address");
        require(_rewardToken != address(0), "Reward token cannot be zero address");

        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);

        // Set some default rates (example values, scaled by 1e18 for potential decimals)
        rewardRatePerSecond = 100 * 1e18 / (365 * 24 * 60 * 60); // Example: 100 reward token per year per stake token
        influenceRatePerSecond = 1000 * 1e18 / (365 * 24 * 60 * 60); // Example: 1000 influence per year per stake token

        emit TokenConfigUpdated("stakeToken", _stakeToken);
        emit TokenConfigUpdated("rewardToken", _rewardToken);
        emit ConfigUpdated("rewardRatePerSecond", rewardRatePerSecond);
        emit ConfigUpdated("influenceRatePerSecond", influenceRatePerSecond);
    }

    // --- Configuration Functions (Owner Only) ---

    // 2. setRewardToken
    function setRewardToken(address _newRewardToken) external onlyOwner {
        require(_newRewardToken != address(0), "Reward token cannot be zero address");
        rewardToken = IERC20(_newRewardToken);
        emit TokenConfigUpdated("rewardToken", _newRewardToken);
    }

    // 3. setRewardRate
    function setRewardRate(uint256 _rewardRatePerSecond) external onlyOwner {
        rewardRatePerSecond = _rewardRatePerSecond;
        emit ConfigUpdated("rewardRatePerSecond", _rewardRatePerSecond);
    }

    // 4. setInfluenceRate
    function setInfluenceRate(uint256 _influenceRatePerSecond) external onlyOwner {
        influenceRatePerSecond = _influenceRatePerSecond;
        emit ConfigUpdated("influenceRatePerSecond", _influenceRatePerSecond);
    }

    // 5. setAttributeVoteThreshold
    function setAttributeVoteThreshold(string memory attributeName, uint256 _requiredInfluence) external onlyOwner {
         require(canvasAttributes[attributeName].minValue != canvasAttributes[attributeName].maxValue || canvasAttributes[attributeName].value != 0, "Attribute does not exist");
        attributeVoteThreshold[attributeName] = _requiredInfluence;
        emit ConfigUpdated(string(abi.encodePacked("attributeVoteThreshold_", attributeName)), _requiredInfluence);
    }

    // 6. setAttributeChangeThreshold
    function setAttributeChangeThreshold(string memory attributeName, uint256 _requiredNetInfluence) external onlyOwner {
        require(canvasAttributes[attributeName].minValue != canvasAttributes[attributeName].maxValue || canvasAttributes[attributeName].value != 0, "Attribute does not exist");
        attributeChangeThreshold[attributeName] = _requiredNetInfluence;
        emit ConfigUpdated(string(abi.encodePacked("attributeChangeThreshold_", attributeName)), _requiredNetInfluence);
    }

    // 7. addCanvasAttribute
    function addCanvasAttribute(string memory name, int256 initialValue, int256 minValue, int256 maxValue) external onlyOwner {
        require(canvasAttributes[name].minValue == canvasAttributes[name].maxValue && canvasAttributes[name].value == 0, "Attribute already exists");
        // Ensure initial value is within bounds
        int256 boundedInitialValue = initialValue;
        if (minValue <= maxValue) { // Only apply bounds if min <= max
            boundedInitialValue = initialValue > maxValue ? maxValue : initialValue;
            boundedInitialValue = initialValue < minValue ? minValue : initialValue;
        }


        canvasAttributes[name] = CanvasAttribute({
            name: name,
            value: boundedInitialValue,
            minValue: minValue,
            maxValue: maxValue
        });
        canvasAttributeNames.push(name);

        // Set default thresholds if not already set
        if(attributeVoteThreshold[name] == 0) attributeVoteThreshold[name] = 1e18; // Default: 1 Influence
        if(attributeChangeThreshold[name] == 0) attributeChangeThreshold[name] = 100e18; // Default: 100 Net Influence

        emit CanvasAttributeAdded(name, boundedInitialValue, minValue, maxValue);
    }

    // 8. updateCanvasAttributeBounds
    function updateCanvasAttributeBounds(string memory name, int256 minValue, int256 maxValue) external onlyOwner {
         require(canvasAttributes[name].minValue != canvasAttributes[name].maxValue || canvasAttributes[name].value != 0, "Attribute does not exist");
        canvasAttributes[name].minValue = minValue;
        canvasAttributes[name].maxValue = maxValue;
         // Adjust current value if it falls outside new bounds
        if (minValue <= maxValue) {
             if (canvasAttributes[name].value > maxValue) canvasAttributes[name].value = maxValue;
             if (canvasAttributes[name].value < minValue) canvasAttributes[name].value = minValue;
        } else {
            // If min > max, bounds are effectively disabled, current value is unrestricted.
        }
        emit CanvasAttributeUpdated(name, canvasAttributes[name].value, minValue, maxValue);
    }

    // 9. removeCanvasAttribute
    function removeCanvasAttribute(string memory name) external onlyOwner {
         require(canvasAttributes[name].minValue != canvasAttributes[name].maxValue || canvasAttributes[name].value != 0, "Attribute does not exist");

        // Note: Removing elements from dynamic arrays is inefficient. For production, consider a mapping + boolean flag approach.
        // This simple approach shifts elements.
        bool found = false;
        for (uint i = 0; i < canvasAttributeNames.length; i++) {
            if (keccak256(bytes(canvasAttributeNames[i])) == keccak256(bytes(name))) {
                // Shift elements left
                for (uint j = i; j < canvasAttributeNames.length - 1; j++) {
                    canvasAttributeNames[j] = canvasAttributeNames[j + 1];
                }
                canvasAttributeNames.pop(); // Remove last element
                found = true;
                break;
            }
        }
        require(found, "Attribute name not found in list"); // Should not happen if mapping check passes

        delete canvasAttributes[name];
        delete attributeVoteInfluence[name];
        delete attributeVoteThreshold[name];
        delete attributeChangeThreshold[name];
        // Note: userInfluenceSpentOnVote and totalInfluenceSpentOnAttribute mapping entries for this attribute will remain until next interaction, but will be ignored.

        emit CanvasAttributeRemoved(name);
    }

    // 10. pause
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    // 11. unpause
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    // --- User Interaction Functions ---

    // Internal helper to update user's accrued rewards and influence based on time
    function _updateUserState(address account) internal {
        uint256 stakedAmount = userStake[account];
        if (stakedAmount == 0) {
            userLastInteractionTime[account] = block.timestamp;
            return;
        }

        uint256 timeElapsed = block.timestamp.sub(userLastInteractionTime[account]);

        // Calculate rewards and influence based on time and stake
        uint256 rewardsEarned = stakedAmount.mul(rewardRatePerSecond).mul(timeElapsed) / 1e18; // Scale down by 1e18 if rates are scaled up
        uint256 influenceEarned = stakedAmount.mul(influenceRatePerSecond).mul(timeElapsed) / 1e18; // Scale down

        userAccruedRewards[account] = userAccruedRewards[account].add(rewardsEarned);
        userAccruedInfluence[account] = userAccruedInfluence[account].add(influenceEarned);
        userLastInteractionTime[account] = block.timestamp;
    }

    // 12. stake
    function stake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        _updateUserState(msg.sender); // Update before state change

        stakeToken.transferFrom(msg.sender, address(this), amount);
        userStake[msg.sender] = userStake[msg.sender].add(amount);

        emit Stake(msg.sender, amount, userStake[msg.sender]);
    }

    // 13. unstake
    function unstake(uint256 amount) external whenNotPaused {
        require(amount > 0, "Amount must be greater than zero");
        require(userStake[msg.sender] >= amount, "Insufficient staked amount");
        _updateUserState(msg.sender); // Update before state change

        userStake[msg.sender] = userStake[msg.sender].sub(amount);
        stakeToken.transfer(msg.sender, amount);

        emit Unstake(msg.sender, amount, userStake[msg.sender]);
    }

    // 14. claimRewards
    function claimRewards() external whenNotPaused {
        _updateUserState(msg.sender); // Update before state change

        uint256 rewardsToClaim = userAccruedRewards[msg.sender];
        require(rewardsToClaim > 0, "No rewards to claim");

        userAccruedRewards[msg.sender] = 0;
        rewardToken.transfer(msg.sender, rewardsToClaim);

        emit RewardsClaimed(msg.sender, rewardsToClaim);
    }

    // 15. voteAttribute
    function voteAttribute(string memory attributeName, int256 value) external whenNotPaused {
        _updateUserState(msg.sender); // Update before state change

        CanvasAttribute storage attribute = canvasAttributes[attributeName];
        require(attribute.minValue != attribute.maxValue || attribute.value != 0, "Attribute does not exist"); // Check if attribute is set

        uint256 requiredInfluence = attributeVoteThreshold[attributeName];
        require(userAccruedInfluence[msg.sender] >= requiredInfluence, "Insufficient influence to vote");

        // Check if value is within bounds if bounds are meaningful (min <= max)
        if (attribute.minValue <= attribute.maxValue) {
             require(value >= attribute.minValue && value <= attribute.maxValue, "Voted value outside attribute bounds");
        }
        // Note: If minValue > maxValue, bounds are disabled, any int256 value is technically 'valid' here for voting.

        // Spend influence points
        userAccruedInfluence[msg.sender] = userAccruedInfluence[msg.sender].sub(requiredInfluence);

        // Record the influence spent for this vote in the current round
        // This assumes votes are additive within a processing round.
        // A more complex system could reset influence spent per round or handle dynamic influence deduction.
        // Here, influence is simply deducted and recorded for this specific vote instance.
        attributeVoteInfluence[attributeName][value] = attributeVoteInfluence[attributeName][value].add(requiredInfluence);
        userInfluenceSpentOnVote[msg.sender][attributeName] = userInfluenceSpentOnVote[msg.sender][attributeName].add(requiredInfluence);
        totalInfluenceSpentOnAttribute[attributeName] = totalInfluenceSpentOnAttribute[attributeName].add(requiredInfluence);


        emit AttributeVote(msg.sender, attributeName, value, requiredInfluence);

        // --- Optional: Trigger NFT minting based on influence contribution ---
        // This check could happen here, or after processAttributeVotes if it's about a 'winning' vote
        // Let's make it after processAttributeVotes for simplicity and relevance to outcome
        // _tryMintNFT(msg.sender, attributeName, requiredInfluence);
    }

    // Internal helper to try minting an NFT
    function _tryMintNFT(address account, string memory attributeName, uint256 influenceContributed) internal {
        if (influenceContributed >= influenceContributionNFTThreshold) {
            _mintCanvasFragmentNFT(account, string(abi.encodePacked("Contributed ", Strings.toString(influenceContributed), " influence to ", attributeName)));
             // Note: This simple logic might over-mint if not managed carefully.
             // A real system would track which contributions already triggered a mint or have a cooldown.
        }
    }


    // 16. processAttributeVotes
    // Can be called by anyone, but requires total influence spent to exceed a threshold (e.g., change threshold itself)
    // Or limit calls per block/time period to manage gas
    function processAttributeVotes(string memory attributeName) external whenNotPaused {
        CanvasAttribute storage attribute = canvasAttributes[attributeName];
        require(attribute.minValue != attribute.maxValue || attribute.value != 0, "Attribute does not exist"); // Check if attribute is set
        require(totalInfluenceSpentOnAttribute[attributeName] > 0, "No influence spent on this attribute since last processing");

        // Find the target value with the most influence
        int256 bestValue = attribute.value; // Default to current value if no votes or tied
        uint256 maxInfluence = 0;
        uint256 totalInfluence = 0; // Recalculate total influence for processing

        // Iterate through all possible int256 values that received votes? This is inefficient.
        // Instead, iterate through the attributeVoteInfluence mapping keys (voted values).
        // Solidity mappings don't expose keys directly. Need a different data structure if we want to iterate all voted values.
        // For simplicity in this example, let's assume a fixed set of possible discrete values for each attribute,
        // OR, process based on average weighted vote, which is still complex without iterating voted values.

        // *Simplified Processing Logic:*
        // Calculate the average desired value weighted by influence.
        // Shift the current value towards the average, limited by attributeChangeThreshold.
        // Reset voting state for this attribute.

        // To calculate weighted average, we need (value * influence) sum and total influence.
        // This still requires iterating over the values that received influence.
        // Let's make a pragmatic choice: Only support a *limited* set of predefined vote options per attribute,
        // OR, require the caller to provide the values that received votes (risky, griefable).
        // *Alternative Simplified Processing:*
        // Find the value with the highest influence. Calculate net influence diff between highest and current value's 'bucket'.
        // If net influence > threshold, move attribute value slightly towards the winning value.
        // This requires defining 'buckets' or assuming smooth transitions.

        // Let's use a simple, albeit less sophisticated, approach for demonstration:
        // Find the vote value with the highest influence.
        // Calculate the total influence spent towards values ABOVE the current value vs BELOW the current value.
        // If the difference (net influence) is significant (>= attributeChangeThreshold), move the value.

        // This still requires knowing which values received influence...
        // Okay, let's store the distinct voted values for each attribute.
        mapping(string => int256[]) private attributeVotedValues; // Maps attribute name => array of unique values voted on in current round

        // Modify voteAttribute to add value to attributeVotedValues if not already there
        // ... (added logic inside voteAttribute)

        // Now, back to processAttributeVotes:
        int256 currentValue = attribute.value;
        uint256 influenceForHigher = 0;
        uint256 influenceForLower = 0;

        int256[] memory votedValues = attributeVotedValues[attributeName]; // Get array of distinct values voted on

        for(uint i = 0; i < votedValues.length; i++) {
            int256 votedValue = votedValues[i];
            uint256 influence = attributeVoteInfluence[attributeName][votedValue];
            if (votedValue > currentValue) {
                influenceForHigher += influence;
            } else if (votedValue < currentValue) {
                influenceForLower += influence;
            }
             // If votedValue == currentValue, it reinforces the current state, doesn't push it higher/lower
        }

        int256 newValue = currentValue;
        uint256 netInfluence = 0;

        if (influenceForHigher > influenceForLower) {
            netInfluence = influenceForHigher.sub(influenceForLower);
            if (netInfluence >= attributeChangeThreshold[attributeName]) {
                // Move value towards higher range. Simple approach: increment by a step.
                // More complex: increment proportional to net influence vs total influence.
                // Let's increment/decrement by 1 for simplicity, bounded by min/max.
                 newValue = currentValue + 1;
            }
        } else if (influenceForLower > influenceForHigher) {
             netInfluence = influenceForLower.sub(influenceForHigher);
             if (netInfluence >= attributeChangeThreshold[attributeName]) {
                 // Move value towards lower range.
                 newValue = currentValue - 1;
             }
        }

        // Apply bounds if meaningful
        if (attribute.minValue <= attribute.maxValue) {
             if (newValue > attribute.maxValue) newValue = attribute.maxValue;
             if (newValue < attribute.minValue) newValue = attribute.minValue;
        }
        // If newValue == currentValue, no change occurs, even if threshold met.

        if (newValue != currentValue) {
            attribute.value = newValue;
            emit AttributeStateChanged(attributeName, currentValue, newValue);
        }

        // --- Reset voting state for this attribute ---
        // Iterate through distinct voted values and reset their influence counts
        for(uint i = 0; i < votedValues.length; i++) {
             delete attributeVoteInfluence[attributeName][votedValues[i]];
        }
        delete attributeVotedValues[attributeName]; // Clear the list of voted values for this round
        delete totalInfluenceSpentOnAttribute[attributeName]; // Reset total influence spent

        // User-specific influence spent on *this* attribute reset.
        // This is tricky. We'd need to know which users voted in *this specific round* before reset.
        // A better approach is to reset influence spent on vote *per user per attribute* when a vote is cast,
        // or track votes by round number. For simplicity here, we just reset the *total* for the attribute and the *value counts*.
        // User's *total* influence (`userAccruedInfluence`) is NOT reset by processing. Only the influence *spent* on a vote is.
        // The mapping `userInfluenceSpentOnVote` tracks influence spent per user per attribute across *all* votes they cast on that attribute since the last processing. This is incorrect for measuring *contribution to this round*.
        // Let's adjust `userInfluenceSpentOnVote` to track influence spent in the *current* round.

        // Re-designing vote tracking for processing:
        // mapping(string => mapping(int256 => uint256)) attributeVoteInfluence; // Same
        // mapping(address => mapping(string => uint256)) userInfluenceInRound; // How much influence *is* voter contributing in this round?
        // mapping(string => address[]) attributeVotersInRound; // List of voters per attribute per round

        // This adds complexity. Let's stick to the simpler model where `userInfluenceSpentOnVote` is just the sum of influence spent *ever* by the user on that attribute. The `processAttributeVotes` function just aggregates `attributeVoteInfluence` which *is* cleared.
        // This means `getUserAttributeVoteInfluence` after processing will show 0 for the processed attribute until they vote again. This is acceptable for a demo.

         lastVoteProcessingTime[attributeName] = block.timestamp;

         // --- Optional: Trigger NFT minting for voters in this round ---
         // This requires iterating voters, which is hard. Let's simplify: anyone who voted since the *last processing time*
         // AND whose contribution to the 'winning direction' (higher/lower) exceeded a threshold gets an NFT.
         // This is still hard to do without tracking voters per round explicitly.

         // Simpler NFT trigger: Mint NFT for the user who calls `processAttributeVotes` *if* their vote contribution threshold is met, and the attribute state actually changed.
         // This incentivizes calling process, but is biased.

         // Let's go back to the _tryMintNFT concept but trigger it *inside* processAttributeVotes
         // For simplicity, iterate through all users who voted on this attribute *since the last processing time* and check their influence contribution in this round. This requires storing timestamps per user vote or tracking rounds.
         // OK, let's simplify *again*. Just check the caller's total influence spent *ever* on this attribute against a threshold after processing. If it exceeds AND the attribute state changed, maybe mint. Still imperfect.

         // *Final Simplified NFT Logic:* Mint an NFT for the caller of `processAttributeVotes` if the attribute state changed AND the caller's total influence spent *ever* on that attribute exceeds `influenceContributionNFTThreshold`. This isn't ideal but avoids complex voter iteration.

         if (newValue != currentValue) {
             if (userInfluenceSpentOnVote[msg.sender][attributeName] >= influenceContributionNFTThreshold) {
                  string memory snapshotDigest = _generateAttributeSnapshotDigest(attributeName); // Generate a string summary
                 _mintCanvasFragmentNFT(msg.sender, snapshotDigest);
             }
         }
    }

    // Internal function to generate a string digest of attribute states
    function _generateAttributeSnapshotDigest(string memory attributeName) internal view returns (string memory) {
        bytes memory digestBytes;
        digestBytes = abi.encodePacked(digestBytes, "Triggered by vote on ", attributeName, ". Snapshot:");

        for (uint i = 0; i < canvasAttributeNames.length; i++) {
            string memory currentAttrName = canvasAttributeNames[i];
            CanvasAttribute storage attr = canvasAttributes[currentAttrName];
            digestBytes = abi.encodePacked(digestBytes, " ", currentAttrName, ":", Strings.toString(attr.value));
        }
        return string(digestBytes);
    }


    // Internal function to mint the Canvas Fragment NFT
    function _mintCanvasFragmentNFT(address recipient, string memory reason) internal {
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        _safeMint(recipient, newItemId);

        // Store the snapshot of all attribute states at the time of minting
        AttributeSnapshot[] memory currentSnapshot = new AttributeSnapshot[](canvasAttributeNames.length);
        for (uint i = 0; i < canvasAttributeNames.length; i++) {
            string memory attrName = canvasAttributeNames[i];
            CanvasAttribute storage attr = canvasAttributes[attrName];
            currentSnapshot[i] = AttributeSnapshot({
                name: attrName,
                value: attr.value
            });
        }
        nftAttributeSnapshots[newItemId] = currentSnapshot;

        emit CanvasFragmentMinted(recipient, newItemId, reason);
    }


    // --- View Functions ---

    // 17. getPendingRewards
    function getPendingRewards(address account) public view returns (uint256) {
        uint256 stakedAmount = userStake[account];
        if (stakedAmount == 0) {
            return userAccruedRewards[account]; // Return already accrued, no new calculation
        }

        uint256 timeElapsed = block.timestamp.sub(userLastInteractionTime[account]);
        uint256 rewardsEarned = stakedAmount.mul(rewardRatePerSecond).mul(timeElapsed) / 1e18; // Scale down
        return userAccruedRewards[account].add(rewardsEarned);
    }

    // 18. getInfluencePoints
    function getInfluencePoints(address account) public view returns (uint256) {
        uint256 stakedAmount = userStake[account];
         if (stakedAmount == 0) {
            return userAccruedInfluence[account]; // Return already accrued, no new calculation
        }

        uint256 timeElapsed = block.timestamp.sub(userLastInteractionTime[account]);
        uint256 influenceEarned = stakedAmount.mul(influenceRatePerSecond).mul(timeElapsed) / 1e18; // Scale down
        return userAccruedInfluence[account].add(influenceEarned);
    }

    // 19. getUserStake
    function getUserStake(address account) public view returns (uint256) {
        return userStake[account];
    }

    // 20. getCanvasAttributeState
    function getCanvasAttributeState(string memory attributeName) public view returns (string memory name, int256 value, int256 minValue, int256 maxValue) {
         CanvasAttribute storage attribute = canvasAttributes[attributeName];
         require(attribute.minValue != attribute.maxValue || attribute.value != 0, "Attribute does not exist");
         return (attribute.name, attribute.value, attribute.minValue, attribute.maxValue);
    }

    // 21. getAllCanvasAttributeStates
    function getAllCanvasAttributeStates() public view returns (CanvasAttribute[] memory) {
        CanvasAttribute[] memory states = new CanvasAttribute[](canvasAttributeNames.length);
        for (uint i = 0; i < canvasAttributeNames.length; i++) {
            string memory name = canvasAttributeNames[i];
            states[i] = canvasAttributes[name];
        }
        return states;
    }

    // 22. getCanvasAttributeNames
    function getCanvasAttributeNames() public view returns (string[] memory) {
        return canvasAttributeNames;
    }

    // 23. getAttributeVoteState
    // Returns the total influence spent for each value that has received votes for this attribute in the current round.
    // Note: This requires iterating known voted values. As implemented, attributeVotedValues is cleared after processing.
    // This function will only show votes *since the last processing*.
    function getAttributeVoteState(string memory attributeName) public view returns (int256[] memory votedValues, uint256[] memory influences) {
        // Need to return arrays of voted values and corresponding influence.
        // Iterating mappings directly is not possible. We need to store voted values explicitly.
        // The `attributeVotedValues` mapping stores the distinct values voted on since last process.
        int256[] memory currentVotedValues = attributeVotedValues[attributeName];
        uint256[] memory currentInfluences = new uint256[](currentVotedValues.length);

        for(uint i = 0; i < currentVotedValues.length; i++) {
            currentInfluences[i] = attributeVoteInfluence[attributeName][currentVotedValues[i]];
        }
        return (currentVotedValues, currentInfluences);
    }

    // 24. getUserAttributeVoteInfluence
    // Returns the total influence a specific user has spent voting on a specific attribute
    // Note: As implemented, this is the sum of influence spent ever by the user on this attribute.
    // If you want influence spent *in the current round*, the tracking would need to be different.
    function getUserAttributeVoteInfluence(address account, string memory attributeName) public view returns (uint256) {
        return userInfluenceSpentOnVote[account][attributeName];
    }

    // 25. getNFTAttributeSnapshot
    function getNFTAttributeSnapshot(uint256 tokenId) public view returns (AttributeSnapshot[] memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return nftAttributeSnapshots[tokenId];
    }

    // 26. getTotalStaked
    function getTotalStaked() public view returns (uint256) {
        uint256 total = 0;
        uint256 totalTokens = totalSupply(); // Using ERC721Enumerable
        for (uint i = 0; i < totalTokens; i++) {
            address owner = ownerOf(tokenByIndex(i));
            // This is not correct for total staked! This is for ERC721.
            // We need a separate state variable for total staked ERC20.
            // Let's add it.
            // uint256 public totalStaked; - Add this state variable
        }
        // Corrected implementation: Use the dedicated state variable
        return stakeToken.balanceOf(address(this)); // Simpler way: query the contract's balance of stakeToken
    }

    // 27. getContractParameters
    function getContractParameters() public view returns (uint256 currentRewardRate, uint256 currentInfluenceRate, uint256 currentNFTThreshold) {
        return (rewardRatePerSecond, influenceRatePerSecond, influenceContributionNFTThreshold);
    }


    // --- ERC721 Overrides ---

    // 28. tokenURI
    // Returns the metadata URI for a Canvas Fragment NFT.
    // Includes attribute snapshots as base64 encoded JSON.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        AttributeSnapshot[] memory snapshot = nftAttributeSnapshots[tokenId];
        bytes memory json = abi.encodePacked(
            '{"name": "Canvas Fragment #', Strings.toString(tokenId), '",',
            '"description": "A snapshot of the Dynamic Canvas attributes at the time this fragment was minted.",',
            '"attributes": ['
        );

        for (uint i = 0; i < snapshot.length; i++) {
            json = abi.encodePacked(
                json,
                '{"trait_type": "', snapshot[i].name, '", "value": ', Strings.toString(snapshot[i].value), '}'
            );
            if (i < snapshot.length - 1) {
                json = abi.encodePacked(json, ',');
            }
        }

        json = abi.encodePacked(json, ']}');

        string memory base64Json = Base64.encode(json);
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    // ERC721Enumerable overrides
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
```

---

**Explanation of Advanced Concepts and Features:**

1.  **Dynamic On-Chain State (`CanvasAttribute`):** The contract maintains a set of mutable state variables (`canvasAttributes`) that represent the "Canvas". These are not static parameters but change based on user interactions, making the contract state itself dynamic and evolving.
2.  **Social Staking & Influence Mining:** Users stake an ERC-20 token (`stakeToken`) to earn two resources simultaneously over time: `rewardToken` (standard yield) and `Influence Points` (a non-transferable, internal token representing voting power). This introduces a dual-incentive structure tied to participation duration and amount.
3.  **Influence-Weighted Voting (`voteAttribute`, `processAttributeVotes`):** Influence points are the currency for voting. Users *spend* influence to cast votes for desired attribute values. The `processAttributeVotes` function aggregates the influence spent on different values for an attribute and updates the attribute's state based on thresholds (`attributeChangeThreshold`), weighted by the influence applied. This is a form of liquid democracy or quadratic voting concept, but applied to continuous parameters rather than discrete proposals. *Self-correction/Simplification:* The implementation uses a simplified model of tracking total influence spent per value and pushing the state based on the net influence difference (higher vs lower), rather than a complex weighted average or quadratic calculation, due to gas limitations and iteration challenges in Solidity.
4.  **Influence Spending & Decay:** While not explicitly decaying influence over time if unused, the `voteAttribute` function *spends* the influence points, requiring users to accrue more by staking if they want to vote again. This prevents permanent voting power concentration.
5.  **Dynamic NFTs (`CanvasFragment`):** The contract acts as an ERC721 factory. When certain conditions are met (e.g., a user contributes significant influence to a successful attribute state change), a `CanvasFragment` NFT is minted.
6.  **NFT Metadata as State Snapshot:** Crucially, the `tokenURI` function for the NFTs includes a snapshot of *all* Canvas attribute states at the exact moment the NFT was minted. This creates a dynamic, on-chain record of the project's history and allows the NFTs to visually represent specific eras or outcomes of the collective voting process (assuming a front-end interprets the metadata).
7.  **Configurable Parameters:** Key rates (`rewardRatePerSecond`, `influenceRatePerSecond`), vote thresholds (`attributeVoteThreshold`, `attributeChangeThreshold`), and even the attributes themselves can be added/updated/removed by the owner. This provides flexibility, though in a decentralized system, this would ideally be controlled by a DAO or other governance mechanism.
8.  **Modular Attributes:** The use of a mapping (`canvasAttributes`) and an array of names (`canvasAttributeNames`) allows for adding, updating, and removing attributes dynamically (within the limits of owner control and array manipulation cost).
9.  **Pausability:** Standard but important for complex contracts for emergency stops.
10. **Accrual Calculation:** Rewards and influence are calculated based on the time elapsed since the user's last interaction, ensuring fair distribution based on stake duration (`_updateUserState`).

This contract goes beyond basic staking or token functionality by introducing a dynamic, collectively influenced state and linking it to unique, state-reflective NFTs, driven by a custom influence and voting system. It demonstrates concepts like on-chain parameter control, resource mining (influence), and dynamic digital assets tied to protocol interaction history.