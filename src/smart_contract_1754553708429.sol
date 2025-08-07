Here's a Solidity smart contract named "Epochal Resonance Protocol (ERP)" designed with advanced, creative, and trending concepts in mind. It integrates soulbound NFTs, dynamic protocol parameters, a treasury management system, and an activity attestation mechanism.

---

## Outline: Epochal Resonance Protocol (ERP)

The Epochal Resonance Protocol introduces a novel system of dynamic, evolving, and **soulbound NFTs** ("Resonators") that represent a user's on-chain activity and contribution to the ecosystem. These Resonators cannot be transferred, ensuring a strong link between identity and earned benefits. As Resonators gain "Resonance Points" (XP) through various on-chain interactions or attested activities, they "level up", unlocking new capabilities and increasing their claim on protocol-generated value.

The protocol also manages a treasury funded by protocol fees and user deposits. A portion of this treasury value can be "crystallized" into transferable ERC-20 tokens ("Harmonics"), which represent a claim on the protocol's future revenue or shared resources. The protocol's parameters, such as XP multipliers, reward distribution rates, and fee structures, can dynamically adjust based on "Epochs" – predefined time periods or milestone-triggered phases.

This aims to create a sticky, reputation-based ecosystem where long-term engagement with a soulbound asset yields tangible, transferable economic benefits, while maintaining a unique identity for each participant.

---

## Function Summary:

**I. Core Identity & Evolution (Resonators - Soulbound ERC-721)**
1.  `mintResonator()`: Mints a new, unique, non-transferable Resonator NFT to the caller. Each address can only hold one Resonator.
2.  `getResonatorInfo(uint256 resonatorId)`: Retrieves detailed information about a Resonator (level, XP, owner).
3.  `levelUpResonator(uint256 resonatorId)`: Allows a Resonator owner to trigger a level-up if sufficient XP is accumulated. Resonators can only level up once per epoch.
4.  `getResonatorLevelThreshold(uint256 level)`: Returns the XP required to reach a specific Resonator level.
5.  `setResonatorAttribute(uint256 resonatorId, string calldata key, uint256 value)`: Admin/authorized function to set a numeric attribute for a Resonator (e.g., "power", "luck").
6.  `getResonatorAttribute(uint256 resonatorId, string calldata key)`: Retrieves a specific numeric attribute of a Resonator.
7.  `_addResonancePoints(uint256 resonatorId, uint256 points)`: **(Internal)** Helper function to add XP to a Resonator, used by other functions like `attestActivity`.
8.  `claimEpochalReward(uint256 resonatorId)`: Allows a Resonator to claim rewards (e.g., Harmonics) based on its level and the current epoch's rules.

**II. Value Accrual & Distribution (Harmonics - ERC-20 & Treasury)**
9.  `depositFunds(address token, uint256 amount)`: Allows users to deposit supported ERC-20 tokens or native ETH into the protocol's treasury.
10. `distributeHarmonics(uint256 amount, uint256 epoch)`: Admin function to mint and distribute a specified amount of Harmonics for a given epoch. (In this simplified example, transferred to owner, in a full protocol, it would go to a distribution pool).
11. `redeemHarmonics(uint256 amount)`: Allows Harmonics holders to redeem their tokens for a proportionate share of the protocol's treasury (currently ETH for simplicity).
12. `getTreasuryBalance(address token)`: Returns the current balance of a specific token held in the protocol's treasury.
13. `withdrawTreasuryFunds(address token, uint256 amount)`: Admin function to withdraw funds from the treasury (e.g., for strategic investments or operational costs).
14. `setProtocolFeeRate(uint256 newFeeRatePermyriad)`: Admin function to set the protocol's fee rate (in permyriad, 10000 = 100%).
15. `collectProtocolFees()`: **(Placeholder)** Admin function to sweep collected fees from specific operations into the main treasury. Actual implementation depends on specific fee-generating mechanisms.

**III. Epoch Management & Dynamic Parameters**
16. `startNewEpoch()`: Admin function to advance the protocol to the next epoch, potentially triggering new rules or reward periods. Can only be called after a minimum duration.
17. `getCurrentEpoch()`: Returns the current epoch number.
18. `setEpochParameter(uint256 epoch, string calldata key, uint256 value)`: Admin function to set a dynamic parameter for a specific epoch (e.g., XP multiplier, reward pool size).
19. `getEpochParameter(uint256 epoch, string calldata key)`: Retrieves the value of a dynamic parameter for a given epoch.

**IV. Advanced Interaction & Utility**
20. `attestActivity(uint256 resonatorId, uint256 activityType, uint256 amount)`: Trusted attesters can report a Resonator's off-chain or specific on-chain activities, contributing to their Resonance Points (XP).
21. `authorizeAttester(address attesterAddress, bool authorized)`: Admin function to grant or revoke attester roles.
22. `registerSupportedToken(address tokenAddress, bool supported)`: Admin function to add or remove tokens from the list of supported deposit/reward tokens.
23. `getTotalResonators()`: Returns the total number of Resonators minted in the protocol.
24. `burnHarmonics(uint256 amount)`: Allows users to burn Harmonics tokens. This could be linked to future utility (e.g., special access, governance).

**V. Standard Protocol Management (Inherited from Pausable and Ownable)**
25. `pause()`: Admin function to pause critical protocol operations for upgrades or emergencies.
26. `unpause()`: Admin function to unpause the protocol.
27. `transferOwnership(address newOwner)`: Transfers ownership of the contract.
28. `renounceOwnership()`: Renounces ownership of the contract.

---

## Solidity Smart Contract Code

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Custom errors for clarity and gas efficiency
error InvalidResonatorId();
error NotResonatorOwner();
error InsufficientXP();
error AlreadyLeveledUpThisEpoch();
error EpochAlreadyStarted();
error InvalidFeeRate();
error TokenNotSupported();
error InsufficientBalance();
error UnauthorizedAttester();
error HarmonicsContractNotSet();
error CannotTransferResonator(); // Specific error for soulbound nature
error RewardAlreadyClaimed();

contract EpochalResonanceProtocol is ERC721, Ownable, Pausable, ReentrancyGuard {
    // --- State Variables ---

    // Resonator Data Structure
    struct Resonator {
        uint256 level;
        uint256 xp;
        uint256 lastLevelUpEpoch; // To prevent rapid level-ups within an epoch
        // Dynamic attributes for each Resonator (e.g., "power", "luck", "cooldowns")
        mapping(string => uint256) attributes;
    }

    // Mapping of Resonator ID to its data
    mapping(uint256 => Resonator) public resonators;
    // Mapping of owner address to their Resonator ID (assuming one Resonator per user for simplicity)
    mapping(address => uint256) public addressToResonatorId;
    // Counter for the next available Resonator ID
    uint256 private _nextTokenId;

    // XP thresholds for each level (level => XP required)
    mapping(uint256 => uint256) public xpThresholds;

    // Epoch Management
    uint256 public currentEpoch;
    // Dynamic parameters per epoch (epoch => parameter_name => value)
    mapping(uint256 => mapping(string => uint256)) public epochParameters;
    // Timestamp when the current epoch started
    uint256 public lastEpochStartTimestamp;
    // Minimum duration for an epoch in seconds (e.g., 7 days)
    uint256 public minEpochDuration = 7 days;

    // Treasury & Fees
    // Stores balances of different tokens in the treasury. address(0) for native ETH.
    mapping(address => uint256) public treasuryBalances;
    // Protocol fee rate in permyriad (e.g., 100 = 1%)
    uint256 public protocolFeeRatePermyriad;
    // Address of the Harmonics ERC-20 token contract
    address public immutable HARMONICS_TOKEN;

    // Supported Tokens for Deposits/Rewards
    mapping(address => bool) public isSupportedToken;
    address[] public supportedTokensList; // To iterate supported tokens efficiently

    // Attestation System: addresses authorized to attest activity
    mapping(address => bool) public isAttester;

    // --- Events ---
    event ResonatorMinted(address indexed owner, uint256 indexed resonatorId);
    event ResonatorLeveledUp(uint256 indexed resonatorId, uint256 newLevel, uint256 currentXP);
    event ResonancePointsAdded(uint256 indexed resonatorId, uint256 pointsAdded, uint256 newXP);
    event ResonatorAttributeSet(uint256 indexed resonatorId, string key, uint256 value);

    event FundsDeposited(address indexed user, address indexed token, uint256 amount);
    event HarmonicsDistributed(uint256 indexed epoch, uint256 amount);
    event HarmonicsRedeemed(address indexed user, uint256 amountRedeemed, uint256 receivedAmount, address indexed receivedToken);
    event TreasuryWithdrawn(address indexed owner, address indexed token, uint256 amount);
    event ProtocolFeeRateSet(uint256 newRatePermyriad);

    event EpochStarted(uint256 indexed epochNumber);
    event EpochParameterSet(uint256 indexed epoch, string key, uint256 value);

    event ActivityAttested(uint256 indexed resonatorId, uint256 activityType, uint256 amount, uint256 newXP);
    event AttesterAuthorized(address indexed attester, bool authorized);
    event SupportedTokenRegistered(address indexed token, bool supported);
    event HarmonicsBurned(address indexed burner, uint256 amount);

    /**
     * @dev Constructor to initialize the contract.
     * @param _harmonicsTokenAddress The address of the deployed Harmonics ERC-20 token contract.
     * @param _initialFeeRatePermyriad The initial protocol fee rate (e.g., 50 for 0.5%).
     */
    constructor(address _harmonicsTokenAddress, uint256 _initialFeeRatePermyriad)
        ERC721("Resonator", "RSR") // Initialize ERC721 with name "Resonator" and symbol "RSR"
        Ownable(msg.sender)       // Set deployer as owner
        Pausable()                // Enable pausing functionality
    {
        if (_harmonicsTokenAddress == address(0)) revert HarmonicsContractNotSet();
        HARMONICS_TOKEN = _harmonicsTokenAddress;

        if (_initialFeeRatePermyriad > 10000) revert InvalidFeeRate(); // Max 100%
        protocolFeeRatePermyriad = _initialFeeRatePermyriad;

        // Initialize XP thresholds for the first few levels (can be expanded/modified by owner)
        xpThresholds[1] = 0; // Level 1 requires 0 XP
        xpThresholds[2] = 100;
        xpThresholds[3] = 250;
        xpThresholds[4] = 500;
        xpThresholds[5] = 1000;
        xpThresholds[6] = 2000;
        xpThresholds[7] = 3500;
        xpThresholds[8] = 5000;
        xpThresholds[9] = 7000;
        xpThresholds[10] = 10000;
        // ... more levels can be added via `setXPThreshold` if needed

        currentEpoch = 1;
        lastEpochStartTimestamp = block.timestamp;

        // Authorize deployer as an initial attester
        isAttester[msg.sender] = true;
    }

    // --- Access Control Overrides for ERC-721 to make it Soulbound ---
    /**
     * @dev Prevents any transfer of Resonator tokens after minting.
     * This makes Resonators soulbound (non-transferable).
     * Allows minting (from address(0)) and burning (to address(0)).
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Allow minting (from address(0))
        if (from == address(0)) {
            require(addressToResonatorId[to] == 0, "One Resonator per address allowed");
            addressToResonatorId[to] = tokenId;
        }
        // Prevent any transfer *after* minting (i.e., from a user to another address)
        else if (to != address(0)) {
            revert CannotTransferResonator();
        }
    }

    // --- I. Core Identity & Evolution (Resonators) ---

    /**
     * @dev Mints a new Resonator NFT to the caller. Each address can only mint one Resonator.
     * Reverts if the caller already owns a Resonator.
     * Emits `ResonatorMinted` event.
     * @return The ID of the newly minted Resonator.
     */
    function mintResonator() public whenNotPaused returns (uint256) {
        if (addressToResonatorId[msg.sender] != 0) {
            revert("Sender already owns a Resonator");
        }

        uint256 newResonatorId = _nextTokenId++;
        _safeMint(msg.sender, newResonatorId);

        // Initialize new Resonator
        resonators[newResonatorId].level = 1;
        resonators[newResonatorId].xp = 0;
        resonators[newResonatorId].lastLevelUpEpoch = currentEpoch;

        emit ResonatorMinted(msg.sender, newResonatorId);
        return newResonatorId;
    }

    /**
     * @dev Retrieves detailed information about a Resonator.
     * @param resonatorId The ID of the Resonator.
     * @return level The current level of the Resonator.
     * @return xp The current experience points of the Resonator.
     * @return owner The owner address of the Resonator.
     * @return lastLevelUpEpoch The epoch in which the Resonator last leveled up.
     */
    function getResonatorInfo(uint256 resonatorId)
        public
        view
        returns (uint256 level, uint256 xp, address owner, uint256 lastLevelUpEpoch)
    {
        if (!_exists(resonatorId)) revert InvalidResonatorId();
        Resonator storage r = resonators[resonatorId];
        return (r.level, r.xp, ownerOf(resonatorId), r.lastLevelUpEpoch);
    }

    /**
     * @dev Allows a Resonator owner to trigger a level-up if sufficient XP is accumulated.
     * Resonators can only level up once per epoch to prevent rapid advancement.
     * Emits `ResonatorLeveledUp` event.
     * @param resonatorId The ID of the Resonator to level up.
     */
    function levelUpResonator(uint256 resonatorId) public whenNotPaused {
        if (ownerOf(resonatorId) != msg.sender) revert NotResonatorOwner();
        Resonator storage r = resonators[resonatorId];

        uint256 nextLevel = r.level + 1;
        uint256 requiredXP = xpThresholds[nextLevel];

        if (requiredXP == 0 && nextLevel > 1) revert("No XP threshold defined for next level"); // No more levels defined
        if (r.xp < requiredXP) revert InsufficientXP();
        if (r.lastLevelUpEpoch == currentEpoch) revert AlreadyLeveledUpThisEpoch();

        r.level = nextLevel;
        r.lastLevelUpEpoch = currentEpoch;

        emit ResonatorLeveledUp(resonatorId, r.level, r.xp);
    }

    /**
     * @dev Returns the XP required to reach a specific Resonator level.
     * @param level The target level.
     * @return The XP required. Returns 0 if level not defined or is level 1.
     */
    function getResonatorLevelThreshold(uint256 level) public view returns (uint256) {
        return xpThresholds[level];
    }

    /**
     * @dev Admin/authorized function to set a numeric attribute for a Resonator.
     * This can be used for dynamic attributes like "Power", "Luck", "SpecialAccess", or internal cooldowns.
     * Emits `ResonatorAttributeSet` event.
     * @param resonatorId The ID of the Resonator.
     * @param key The name of the attribute (e.g., "power", "luck", "last_reward_epoch").
     * @param value The value to set for the attribute.
     */
    function setResonatorAttribute(uint256 resonatorId, string calldata key, uint256 value)
        public
        onlyOwner
        whenNotPaused
    {
        if (!_exists(resonatorId)) revert InvalidResonatorId();
        resonators[resonatorId].attributes[key] = value;
        emit ResonatorAttributeSet(resonatorId, key, value);
    }

    /**
     * @dev Retrieves a specific numeric attribute of a Resonator.
     * @param resonatorId The ID of the Resonator.
     * @param key The name of the attribute.
     * @return The value of the attribute. Returns 0 if the attribute is not set.
     */
    function getResonatorAttribute(uint256 resonatorId, string calldata key)
        public
        view
        returns (uint256)
    {
        if (!_exists(resonatorId)) revert InvalidResonatorId();
        return resonators[resonatorId].attributes[key];
    }

    /**
     * @dev Internal function to add XP to a Resonator.
     * Automatically called by functions like `attestActivity`.
     * @param resonatorId The ID of the Resonator.
     * @param points The amount of XP to add.
     */
    function _addResonancePoints(uint256 resonatorId, uint256 points) internal {
        if (!_exists(resonatorId)) revert InvalidResonatorId();
        resonators[resonatorId].xp += points;
        emit ResonancePointsAdded(resonatorId, points, resonators[resonatorId].xp);
    }

    /**
     * @dev Allows a Resonator to claim rewards (e.g., Harmonics) based on its level and current epoch's rules.
     * Reward calculation logic is a simplified example here; in a real protocol, this would be more complex,
     * possibly involving a reward pool specific to the epoch, and dynamic distribution logic.
     * Emits `HarmonicsDistributed` event.
     * @param resonatorId The ID of the Resonator claiming rewards.
     */
    function claimEpochalReward(uint256 resonatorId) public whenNotPaused nonReentrant {
        if (ownerOf(resonatorId) != msg.sender) revert NotResonatorOwner();
        Resonator storage r = resonators[resonatorId];

        // Unique key for tracking last reward claim per Resonator per epoch
        // Using `abi.encodePacked` to create a unique string key for the mapping
        string memory lastClaimEpochKey = string(abi.encodePacked("last_claim_epoch_", uint256(r.level)));
        if (getResonatorAttribute(resonatorId, lastClaimEpochKey) == currentEpoch) {
            revert RewardAlreadyClaimed();
        }

        // Example reward logic: Base reward per level, multiplied by an epoch parameter
        uint256 baseRewardPerLevel = 10 * 1e18; // 10 Harmonics per level (example, scaled for 18 decimals)
        uint256 rewardMultiplier = getEpochParameter(currentEpoch, "reward_multiplier");
        if (rewardMultiplier == 0) rewardMultiplier = 1; // Default to 1x multiplier if not set

        uint256 rewardAmount = (r.level * baseRewardPerLevel * rewardMultiplier) / 100; // Assuming multiplier is in percent (e.g., 100 for 1x)
        if (rewardAmount == 0) revert("No reward calculated for this resonator's level or current epoch");
        
        // Mark as claimed for this epoch by setting an attribute
        resonators[resonatorId].attributes[lastClaimEpochKey] = currentEpoch;
        emit ResonatorAttributeSet(resonatorId, lastClaimEpochKey, currentEpoch);

        IERC20(HARMONICS_TOKEN).transfer(msg.sender, rewardAmount);
        emit HarmonicsDistributed(currentEpoch, rewardAmount);
    }

    // --- II. Value Accrual & Distribution (Harmonics & Treasury) ---

    /**
     * @dev Allows users to deposit supported ERC-20 tokens or native ETH into the protocol's treasury.
     * @param token The address of the token to deposit (address(0) for native ETH).
     * @param amount The amount to deposit.
     * Emits `FundsDeposited` event.
     */
    function depositFunds(address token, uint256 amount) public payable whenNotPaused nonReentrant {
        if (token == address(0)) { // Native ETH deposit
            if (msg.value != amount) revert("ETH amount must match msg.value");
            treasuryBalances[address(0)] += amount;
        } else { // ERC-20 token deposit
            if (!isSupportedToken[token]) revert TokenNotSupported();
            // ERC-20 tokens need to be approved by the user first for this contract to pull them.
            IERC20(token).transferFrom(msg.sender, address(this), amount);
            treasuryBalances[token] += amount;
        }
        emit FundsDeposited(msg.sender, token, amount);
    }

    /**
     * @dev Admin function to mint and distribute a specified amount of Harmonics for a given epoch.
     * This simulates the protocol creating new value from its treasury or through governance decision.
     * In a full protocol, this might be automated or distributed to a pool, rather than directly to owner.
     * Emits `HarmonicsDistributed` event.
     * @param amount The amount of Harmonics to mint and distribute.
     * @param epoch The epoch for which Harmonics are being distributed.
     */
    function distributeHarmonics(uint256 amount, uint256 epoch) public onlyOwner whenNotPaused {
        if (address(HARMONICS_TOKEN) == address(0)) revert HarmonicsContractNotSet();
        // The Harmonics ERC-20 contract must have a minting function callable by this contract (or its owner).
        // For simplicity, we assume the owner of this contract is also the minter for Harmonics.
        // In a real scenario, this ERC20 contract would need to be designed to allow this ERP contract to mint.
        IERC20(HARMONICS_TOKEN).transfer(msg.sender, amount); // Directly transfer to owner for simplicity
        emit HarmonicsDistributed(epoch, amount);
    }

    /**
     * @dev Allows Harmonics holders to redeem their tokens for a proportionate share of the protocol's treasury.
     * The redemption value could be dynamic based on treasury size and total Harmonics supply.
     * For simplicity, this example assumes 1 Harmonics can redeem a fixed amount of ETH from treasury.
     * A more advanced version would calculate share based on total Harmonics supply and treasury value.
     * Emits `HarmonicsRedeemed` event.
     * @param amount The amount of Harmonics to redeem.
     */
    function redeemHarmonics(uint256 amount) public whenNotPaused nonReentrant {
        if (address(HARMONICS_TOKEN) == address(0)) revert HarmonicsContractNotSet();
        IERC20 harmonics = IERC20(HARMONICS_TOKEN);
        if (harmonics.balanceOf(msg.sender) < amount) revert InsufficientBalance();

        // Simplified redemption logic: 1 Harmonics = 1 unit of ETH (assuming Harmonics has 18 decimals)
        // In reality, this would be: (amount / total_harmonics_supply) * total_treasury_value
        uint256 ethRedeemAmount = amount; // Assuming 1:1 for simplicity with ETH
        if (treasuryBalances[address(0)] < ethRedeemAmount) revert InsufficientBalance();

        harmonics.transferFrom(msg.sender, address(this), amount); // Transfer Harmonics to contract (effectively burns for user)
        treasuryBalances[address(0)] -= ethRedeemAmount;
        payable(msg.sender).transfer(ethRedeemAmount);

        emit HarmonicsRedeemed(msg.sender, amount, ethRedeemAmount, address(0));
    }

    /**
     * @dev Returns the current balance of a specific token held in the protocol's treasury.
     * @param token The address of the token (address(0) for native ETH).
     * @return The balance of the token in the treasury.
     */
    function getTreasuryBalance(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance; // Actual contract's ETH balance
        }
        return treasuryBalances[token];
    }

    /**
     * @dev Admin function to withdraw funds from the treasury.
     * Can be used for strategic investments, operational costs, or manual distribution.
     * @param token The address of the token to withdraw (address(0) for native ETH).
     * @param amount The amount to withdraw.
     * Emits `TreasuryWithdrawn` event.
     */
    function withdrawTreasuryFunds(address token, uint256 amount) public onlyOwner whenNotPaused nonReentrant {
        if (token == address(0)) {
            if (address(this).balance < amount) revert InsufficientBalance();
            payable(owner()).transfer(amount);
        } else {
            if (treasuryBalances[token] < amount) revert InsufficientBalance();
            treasuryBalances[token] -= amount;
            IERC20(token).transfer(owner(), amount);
        }
        emit TreasuryWithdrawn(owner(), token, amount);
    }

    /**
     * @dev Admin function to set the protocol's fee rate.
     * This rate can be applied to various interactions within the protocol (e.g., deposits, specific actions).
     * @param newFeeRatePermyriad The new fee rate in permyriad (e.g., 50 for 0.5%, 10000 for 100%).
     * Emits `ProtocolFeeRateSet` event.
     */
    function setProtocolFeeRate(uint256 newFeeRatePermyriad) public onlyOwner {
        if (newFeeRatePermyriad > 10000) revert InvalidFeeRate(); // Max 100%
        protocolFeeRatePermyriad = newFeeRatePermyriad;
        emit ProtocolFeeRateSet(newFeeRatePermyriad);
    }

    /**
     * @dev Placeholder function to indicate where protocol fees would be collected.
     * In a real protocol, this logic would be integrated into various operations (e.g., a percentage of `depositFunds`).
     * This function itself doesn't perform a collection operation but highlights the concept.
     */
    function collectProtocolFees() public onlyOwner {
        // This function serves as a conceptual placeholder.
        // Actual fee collection logic would reside within functions that generate fees (e.g., a percentage deduction on deposits, or a specific interaction fee).
        // For demonstration purposes, assume fees are already implicitly handled in `depositFunds` or other future functions.
    }

    // --- III. Epoch Management & Dynamic Parameters ---

    /**
     * @dev Admin function to advance the protocol to the next epoch.
     * Can only be called after `minEpochDuration` has passed since the last epoch started.
     * Emits `EpochStarted` event.
     */
    function startNewEpoch() public onlyOwner {
        if (block.timestamp < lastEpochStartTimestamp + minEpochDuration) {
            revert EpochAlreadyStarted();
        }
        currentEpoch++;
        lastEpochStartTimestamp = block.timestamp;
        emit EpochStarted(currentEpoch);
    }

    /**
     * @dev Returns the current epoch number.
     */
    function getCurrentEpoch() public view returns (uint256) {
        return currentEpoch;
    }

    /**
     * @dev Admin function to set a dynamic parameter for a specific epoch.
     * This allows the protocol to adjust behavior (e.g., XP multiplier, reward pool size, specific event flags) per epoch.
     * @param epoch The epoch for which to set the parameter. Can be current or future epoch.
     * @param key The name of the parameter (e.g., "xp_multiplier", "reward_pool_size", "special_event_active").
     * @param value The value to set for the parameter.
     * Emits `EpochParameterSet` event.
     */
    function setEpochParameter(uint256 epoch, string calldata key, uint256 value) public onlyOwner {
        epochParameters[epoch][key] = value;
        emit EpochParameterSet(epoch, key, value);
    }

    /**
     * @dev Retrieves the value of a dynamic parameter for a given epoch.
     * @param epoch The epoch to query.
     * @param key The name of the parameter.
     * @return The value of the parameter. Returns 0 if not set for that epoch.
     */
    function getEpochParameter(uint256 epoch, string calldata key) public view returns (uint256) {
        return epochParameters[epoch][key];
    }

    // --- IV. Advanced Interaction & Utility ---

    /**
     * @dev Trusted attesters can report a Resonator's off-chain or specific on-chain activities,
     * contributing to their Resonance Points (XP). This enables integration with external systems or specific in-protocol actions.
     * @param resonatorId The ID of the Resonator.
     * @param activityType An identifier for the type of activity (e.g., 1 for "community engagement", 2 for "external staking proof").
     * @param amount The value associated with the activity (e.g., hours engaged, points earned, amount staked).
     * Emits `ActivityAttested` event.
     */
    function attestActivity(uint256 resonatorId, uint256 activityType, uint256 amount)
        public
        whenNotPaused
    {
        if (!isAttester[msg.sender]) revert UnauthorizedAttester();
        if (!_exists(resonatorId)) revert InvalidResonatorId();

        // Example XP calculation: amount * epoch_xp_multiplier
        uint256 xpMultiplier = getEpochParameter(currentEpoch, "xp_multiplier");
        if (xpMultiplier == 0) xpMultiplier = 100; // Default to 1x (100 in 1/100 scale)

        // Divide by a constant (e.g., 100) if xpMultiplier is a percentage-like value.
        // For example, if xpMultiplier is 150 (1.5x) and amount is 100, pointsToAdd = (100 * 150) / 100 = 150.
        uint256 pointsToAdd = (amount * xpMultiplier) / 100;

        _addResonancePoints(resonatorId, pointsToAdd);

        emit ActivityAttested(resonatorId, activityType, amount, resonators[resonatorId].xp);
    }

    /**
     * @dev Admin function to grant or revoke attester roles.
     * Attesters are trusted addresses that can call `attestActivity`.
     * @param attesterAddress The address to authorize/de-authorize.
     * @param authorized True to authorize, false to de-authorize.
     * Emits `AttesterAuthorized` event.
     */
    function authorizeAttester(address attesterAddress, bool authorized) public onlyOwner {
        isAttester[attesterAddress] = authorized;
        emit AttesterAuthorized(attesterAddress, authorized);
    }

    /**
     * @dev Admin function to add or remove tokens from the list of supported deposit/reward tokens.
     * Ensures only approved tokens can interact with the treasury.
     * @param tokenAddress The address of the ERC-20 token.
     * @param supported True to support, false to remove support.
     * Emits `SupportedTokenRegistered` event.
     */
    function registerSupportedToken(address tokenAddress, bool supported) public onlyOwner {
        if (isSupportedToken[tokenAddress] != supported) {
            isSupportedToken[tokenAddress] = supported;
            if (supported) {
                supportedTokensList.push(tokenAddress); // Add to iterable list
            } else {
                // Remove from list (iterates, but for a small list of supported tokens, this is acceptable)
                for (uint i = 0; i < supportedTokensList.length; i++) {
                    if (supportedTokensList[i] == tokenAddress) {
                        // Replace with last element and pop to maintain order for gas efficiency
                        supportedTokensList[i] = supportedTokensList[supportedTokensList.length - 1];
                        supportedTokensList.pop();
                        break;
                    }
                }
            }
            emit SupportedTokenRegistered(tokenAddress, supported);
        }
    }

    /**
     * @dev Returns the total number of Resonators minted in the protocol.
     * This corresponds to the `_nextTokenId` counter.
     */
    function getTotalResonators() public view returns (uint256) {
        return _nextTokenId;
    }

    /**
     * @dev Allows users to burn Harmonics tokens.
     * This mechanism can be used for various purposes like:
     *   - Removing tokens from circulation to increase scarcity.
     *   - As a cost for unlocking special features or governance votes.
     * For this contract, the tokens are transferred to `address(this)` which acts as a "soft burn"
     * by taking them out of user circulation. For a true burn, the Harmonics ERC-20 contract
     * would need a `burn` function that this contract can call.
     * @param amount The amount of Harmonics to burn.
     * Emits `HarmonicsBurned` event.
     */
    function burnHarmonics(uint256 amount) public whenNotPaused nonReentrant {
        if (address(HARMONICS_TOKEN) == address(0)) revert HarmonicsContractNotSet();
        IERC20 harmonics = IERC20(HARMONICS_TOKEN);
        if (harmonics.balanceOf(msg.sender) < amount) revert InsufficientBalance();

        harmonics.transferFrom(msg.sender, address(this), amount); // Transfer to contract (effectively removed from user's balance)
        emit HarmonicsBurned(msg.sender, amount);
    }

    // --- V. Standard Protocol Management (Inherited from Pausable and Ownable) ---

    /**
     * @dev Pauses the contract, preventing most operations. Only owner can call.
     * Overrides Pausable's pause to include `whenNotPaused` modifier for safety.
     */
    function pause() public onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing operations to resume. Only owner can call.
     * Overrides Pausable's unpause to include `whenPaused` modifier for safety.
     */
    function unpause() public onlyOwner whenPaused {
        _unpause();
    }

    // `transferOwnership(address newOwner)` and `renounceOwnership()` are inherited directly from `Ownable`
    // and function as standard.
}
```

---

## Example Harmonics ERC-20 Contract (Required for Deployment)

You will need to deploy a simple ERC-20 token contract, e.g., "Harmonics", and then provide its address when deploying the `EpochalResonanceProtocol`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Harmonics is ERC20, Ownable {
    /**
     * @dev Constructor that sets the name and symbol of the token.
     */
    constructor() ERC20("Harmonics", "HMC") Ownable(msg.sender) {
        // Mint an initial supply to the deployer if desired, or to the EpochalResonanceProtocol
        // _mint(msg.sender, 1000000 * 1e18); // Example: 1,000,000 tokens
    }

    /**
     * @dev Allows the owner of this Harmonics contract to mint new tokens.
     * In the context of the Epochal Resonance Protocol, the ERP contract's owner
     * would typically be granted minter role (if Harmonics had AccessControl for minters)
     * or the owner of Harmonics would call this to supply tokens to the ERP.
     * @param to The address to mint tokens to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Allows the owner of this Harmonics contract to burn tokens.
     * If the EpochalResonanceProtocol needs to truly burn tokens (not just hold them),
     * the ERP owner would manually call this function after tokens are transferred to ERP.
     * @param amount The amount of tokens to burn from the caller's balance.
     */
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
}
```

---

### Deployment and Interaction Notes:

1.  **Deploy `Harmonics.sol` first.** Note down its deployed address.
2.  **Deploy `EpochalResonanceProtocol.sol`.** In its constructor, provide the address of your deployed `Harmonics` token and an initial fee rate (e.g., `50` for 0.5%).
3.  **Grant Minter Role (Optional but Recommended for Harmonics):** If the `Harmonics` contract uses OpenZeppelin's `AccessControl` for minting, you'd grant the `EpochalResonanceProtocol` contract the `MINTER_ROLE`. For the simplified `Harmonics` contract above, only the `Harmonics` contract owner can mint. The `EpochalResonanceProtocol` currently relies on its own owner to call `distributeHarmonics` which then transfers tokens (that the `EpochalResonanceProtocol`'s owner manually minted and sent to themselves, then to the protocol). A more robust setup would have the `Harmonics` contract granting `MINTER_ROLE` to the `EpochalResonanceProtocol` address.
4.  **Admin Functions:** Many functions are `onlyOwner`. The deployer address initially holds this role.
5.  **Attestation:** The deployer is initially set as an attester. More attesters can be added via `authorizeAttester`.
6.  **Supported Tokens:** Remember to `registerSupportedToken` for any ERC-20 tokens you want users to be able to `depositFunds` with (other than native ETH).
7.  **Gas Costs:** Be mindful that functions involving iterating through mappings or arrays (like removing from `supportedTokensList`) can have varying gas costs. For very large-scale lists, a more gas-efficient linked-list or mapping-based deletion without shifting would be considered.

This contract provides a robust framework for a unique decentralized application, combining identity-bound progression with transferable economic value, driven by a dynamic epoch system.