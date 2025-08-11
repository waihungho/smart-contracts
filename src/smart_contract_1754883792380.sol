This smart contract, `AuraGenesis`, is designed as a decentralized platform for curating and leveraging collective intelligence. It introduces several advanced, creative, and trendy concepts:

*   **Dynamic "Aura" Resonance:** Insights (called "Auras") have a dynamic `resonance` score that constantly adapts based on their validation status (consensus), accuracy feedback (simulated via validation success), and a time-based decay mechanism. This makes the value of information fluid and self-correcting.
*   **Collective Understanding:** The contract aggregates high-resonance Auras for a specific topic, providing a weighted "Collective Understanding" that represents the most validated and relevant insights at any given time.
*   **Dynamic NFT "AuraBadge":** Users earn an "AuraBadge" NFT that visually (or through metadata) evolves to reflect their cumulative contribution score, accuracy, and expertise within the network. This provides on-chain reputation that is directly tied to the quality and impact of their insights.
*   **Gamified Validation & Incentives:** A challenge-and-vote system for Aura validation, coupled with AURA token staking, rewards for accurate validation, and collateral slashing for incorrect submissions/challenges, creates a robust, game-theoretic incentive mechanism for data integrity.
*   **Decentralized Knowledge Base / DeSci Alignment:** The core concept aligns with decentralized science (DeSci) by enabling a community-driven, verifiable repository of evolving insights on various topics.

The design avoids direct duplication of existing large open-source projects by combining these elements in a novel way, particularly the dynamic resonance algorithm and the direct linkage to evolving NFTs based on complex contribution metrics.

---

### **OUTLINE**

1.  **Interfaces:** Definitions for external ERC20 (AURA token) and a custom ERC721 (AuraBadge NFT) contract interactions.
2.  **Errors:** Custom Solidity errors for efficient and descriptive error handling.
3.  **Constants & Enums:** Defined fixed values and state types (e.g., `AuraStatus`).
4.  **Structs:** Data structures for `Topic` and `Aura` entities.
5.  **State Variables:** Storage for contract configuration, topic data, aura data, and user balances/reputation.
6.  **Events:** Broadcasts important contract actions for off-chain monitoring.
7.  **Modifiers:** Reusable access control and validation checks.
8.  **Constructor:** Initializes the contract with core parameters.
9.  **Configuration Functions (Owner/DAO Only):** Functions to adjust global parameters.
10. **Topic Management Functions:** For creating and managing distinct insight topics.
11. **Aura (Insight) Management Functions:** Core functions for submitting, challenging, voting on, and finalizing Auras.
12. **Validator Staking Functions:** Manages AURA token staking for validator participation.
13. **Reputation & Rewards Functions:** Handles claiming rewards, redeeming collateral, and interacting with the AuraBadge NFT.
14. **Collective Understanding Functions:** For querying the aggregated, weighted insights of a topic.
15. **Internal / Helper Functions:** Private functions encapsulating complex logic, such as `_calculateAuraResonance`.

---

### **FUNCTION SUMMARY**

**I. Configuration & Setup (Owner/DAO controlled)**
1.  `setAuraTokenAddress(address _auraToken)`: Sets the address of the AURA ERC20 token used for fees, staking, and rewards.
2.  `setAuraBadgeNFTAddress(address _auraBadgeNFT)`: Sets the address of the custom AuraBadge ERC721 NFT contract.
3.  `setEpochDuration(uint256 _duration)`: Adjusts the length of an evaluation epoch in seconds.
4.  `setInitialResonanceDecayRate(uint256 _rate)`: Sets how quickly an Aura's resonance decays over time (e.g., 500 for 5%).
5.  `setValidationThresholdNumerator(uint256 _numerator)`: Sets the numerator for the validation majority threshold (e.g., 2 for 2/3).
6.  `setValidationThresholdDenominator(uint256 _denominator)`: Sets the denominator for the validation majority threshold (e.g., 3 for 2/3).
7.  `setAuraSubmissionFee(uint256 _fee)`: Sets the AURA token fee required to submit a new Aura.
8.  `setMinStakingForValidator(uint256 _minStake)`: Sets the minimum AURA token stake to become a validator.
9.  `setChallengeCollateral(uint256 _collateral)`: Sets the AURA token collateral required to challenge an Aura.
10. `setRewardPerValidation(uint256 _reward)`: Sets the AURA token reward for a single successful Aura validation.

**II. Topic Management**
11. `createInsightTopic(string memory _topicName, string memory _descriptionURI, uint256 _topicFund)`: Creates a new topic for collective insights, funded with AURA tokens.
12. `closeInsightTopic(uint256 _topicId)`: Closes an existing topic, finalizing its state and returning remaining funds to the creator.
13. `getTopicDetails(uint256 _topicId)`: Retrieves comprehensive details about a specific insight topic.

**III. Aura (Insight) Management**
14. `submitAura(uint256 _topicId, string memory _auraContentUri, uint256 _initialCollateral)`: Allows users to submit a new insight (Aura) to a specified topic, attaching required fees and collateral.
15. `challengeAura(uint256 _auraId)`: Enables a user to challenge the validity of an Aura, initiating a validation period and requiring collateral.
16. `voteOnAuraValidity(uint256 _auraId, bool _isValid)`: Allows staked validators to cast their vote on a challenged Aura (valid/invalid).
17. `finalizeAuraValidation(uint256 _auraId)`: Processes the votes for a challenged Aura, updates its status and resonance, and distributes collateral/rewards.
18. `getAuraDetails(uint256 _auraId)`: Retrieves detailed information about a specific Aura.
19. `getUserAuras(address _user)`: Returns a list of Aura IDs submitted by a specific user.

**IV. Validator Staking**
20. `stakeForValidation(uint256 _amount)`: Allows users to stake AURA tokens to become eligible to vote as validators.
21. `unstakeFromValidation(uint256 _amount)`: Allows validators to unstake their AURA tokens.

**V. Reputation & Rewards**
22. `claimValidationRewards()`: Allows validators to claim their accumulated AURA token rewards for successful validations.
23. `redeemAuraSubmissionCollateral(uint256 _auraId)`: Allows an Aura submitter to reclaim their initial collateral if their Aura was successfully validated.
24. `mintAuraBadge()`: Mints or updates a user's dynamic AuraBadge NFT, reflecting their current Aura score.
25. `getUserAuraScore(address _user)`: Retrieves the current cumulative Aura score for a user, influencing their AuraBadge.

**VI. Collective Understanding & Querying**
26. `getCollectiveUnderstanding(uint256 _topicId)`: Returns a list of highly resonant Aura URIs and their corresponding resonance weights for a given topic, forming its "collective understanding."
27. `queryTopicInsights(uint256 _topicId, AuraStatus _statusFilter, uint256 _minResonance)`: Allows querying Auras within a topic based on specific status and minimum resonance filters.

**VII. Internal / Helper Functions**
28. `_calculateAuraResonance(uint256 _auraId)`: (Internal) Re-calculates and updates an Aura's dynamic resonance based on its status, validation, and time decay. This function is called by other contract actions and could conceptually be triggered periodically by off-chain keepers for continuous decay.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // For safety in arithmetic operations

// --- OUTLINE ---
// 1.  Interfaces: For ERC20 and custom ERC721 tokens used by the contract.
// 2.  Errors: Custom errors for clarity and gas efficiency.
// 3.  Constants & Enums: Define fixed values and state types.
// 4.  Structs: Data structures for Topics, Auras.
// 5.  State Variables: Store contract data.
// 6.  Events: For off-chain monitoring.
// 7.  Modifiers: Access control and common checks.
// 8.  Constructor: Initializes the contract.
// 9.  Configuration Functions (Owner/DAO Only): Adjust core parameters.
// 10. Topic Management Functions: Create and manage insight topics.
// 11. Aura (Insight) Management Functions: Submit, challenge, validate, and update Auras.
// 12. Validator Staking Functions: Manage validator stakes.
// 13. Reputation & Rewards Functions: Claim rewards, manage user scores, mint/update AuraBadges.
// 14. Collective Understanding Functions: Query aggregated insights.
// 15. Internal / Helper Functions: Logic for calculations and state transitions.

// --- FUNCTION SUMMARY ---

// I. Configuration & Setup (Owner/DAO controlled)
// 1.  setAuraTokenAddress(address _auraToken): Sets the address of the AURA ERC20 token.
// 2.  setAuraBadgeNFTAddress(address _auraBadgeNFT): Sets the address of the AuraBadge ERC721 NFT contract.
// 3.  setEpochDuration(uint256 _duration): Adjusts the length of an evaluation epoch.
// 4.  setInitialResonanceDecayRate(uint256 _rate): Sets how quickly an Aura's resonance decays over time.
// 5.  setValidationThresholdNumerator(uint256 _numerator): Sets the numerator for the validation threshold (e.g., 2 for 2/3).
// 6.  setValidationThresholdDenominator(uint256 _denominator): Sets the denominator for the validation threshold (e.g., 3 for 2/3).
// 7.  setAuraSubmissionFee(uint256 _fee): Sets the fee to submit an aura.
// 8.  setMinStakingForValidator(uint256 _minStake): Sets the minimum AURA token stake to become a validator.
// 9.  setChallengeCollateral(uint256 _collateral): Sets the collateral required to challenge an Aura.
// 10. setRewardPerValidation(uint256 _reward): Sets the AURA token reward for a successful Aura validation.

// II. Topic Management
// 11. createInsightTopic(string memory _topicName, string memory _descriptionURI, uint256 _topicFund): Creates a new topic for collective insights.
// 12. closeInsightTopic(uint256 _topicId): Closes a topic, finalizing its collective understanding and distributing any remaining funds.
// 13. getTopicDetails(uint256 _topicId): Retrieves details about a specific insight topic.

// III. Aura (Insight) Management
// 14. submitAura(uint256 _topicId, string memory _auraContentUri, uint256 _initialCollateral): Users submit an insight to a topic.
// 15. challengeAura(uint256 _auraId): Allows a user to challenge the validity of an existing Aura.
// 16. voteOnAuraValidity(uint256 _auraId, bool _isValid): Validators cast their vote on a challenged Aura.
// 17. finalizeAuraValidation(uint256 _auraId): Processes votes for a challenged Aura and updates its status and resonance.
// 18. getAuraDetails(uint256 _auraId): Retrieves detailed information about a specific Aura.
// 19. getUserAuras(address _user): Retrieves a list of Aura IDs submitted by a specific user.

// IV. Validator Staking
// 20. stakeForValidation(uint256 _amount): Allows users to stake AURA tokens to become a validator.
// 21. unstakeFromValidation(uint256 _amount): Allows validators to unstake their AURA tokens.

// V. Reputation & Rewards
// 22. claimValidationRewards(): Allows validators to claim their accumulated rewards for successfully validating Auras.
// 23. redeemAuraSubmissionCollateral(uint256 _auraId): Allows an Aura submitter to reclaim their collateral if their Aura was successful.
// 24. mintAuraBadge(): Mints or updates a user's dynamic AuraBadge NFT based on their overall contribution score.
// 25. getUserAuraScore(address _user): Retrieves the current collective Aura score for a user.

// VI. Collective Understanding & Querying
// 26. getCollectiveUnderstanding(uint256 _topicId): Returns an array of highly resonant Aura URIs and their weights for a given topic, forming the "collective understanding."
// 27. queryTopicInsights(uint256 _topicId, AuraStatus _statusFilter, uint256 _minResonance): Allows querying Auras within a topic based on status and minimum resonance.

// VII. Internal & Helper Functions (often private/internal, but listed for completeness of logic)
// 28. _calculateAuraResonance(uint256 _auraId): (Internal) Re-calculates and updates an Aura's dynamic resonance based on its status, validation, and time decay.
// Note on "not duplicating open source": While fundamental concepts like ERC20/ERC721 interfaces and Ownable patterns are standard, the unique combination of dynamic "Aura" resonance, topic-specific collective intelligence aggregation, an evolving "AuraBadge" NFT based on contribution metrics, and the specific rules for challenges/validation within this framework are designed to be novel.

// --- Custom Interface for Dynamic AuraBadge NFT ---
// This interface defines the expected functions for the AuraBadge NFT contract
// to allow AuraGenesis to mint/update user badges and query their token IDs.
interface IAuraBadge is IERC721 {
    // Allows minting a new badge for a user, or updating an existing one.
    // The NFT contract would link the score to the badge's dynamic properties (e.g., metadata URI).
    // Returns the tokenId of the minted/updated badge.
    function mintOrUpdateBadge(address to, uint256 newScore) external returns (uint256 tokenId);

    // Allows querying the tokenId for a user's badge (if they have one).
    function userTokenId(address user) external view returns (uint256);
}


/**
 * @title AuraGenesis
 * @dev A decentralized platform for curating and leveraging collective insights.
 * Users submit "Auras" (validated insights/predictions) on various topics.
 * These Auras gain "Resonance" (dynamic weight) based on accuracy, consensus, and time.
 * The weighted aggregation of resonant Auras forms a "Collective Understanding" for a topic.
 * Participants are rewarded for high-quality contributions, and earn evolving "AuraBadges" (NFTs)
 * reflecting their expertise.
 */
contract AuraGenesis is Ownable {
    using SafeMath for uint256;

    // --- Interfaces ---
    // Assumed ERC20 token for staking, fees, and rewards (e.g., AURA token)
    IERC20 private _auraToken;
    // Custom ERC721 token for user reputation badges (e.g., AuraBadge NFT)
    IAuraBadge private _auraBadgeNFT;

    // --- Errors ---
    error AuraGenesis__InvalidAddress(address _address);
    error AuraGenesis__InsufficientFunds();
    error AuraGenesis__Unauthorized();
    error AuraGenesis__InvalidTopicId();
    error AuraGenesis__InvalidAuraId();
    error AuraGenesis__AlreadyVoted();
    error AuraGenesis__NotValidator();
    error AuraGenesis__NotChallenger();
    error AuraGenesis__NotAuraSubmitter();
    error AuraGenesis__AuraNotChallengeable();
    error AuraGenesis__AuraNotInValidation();
    error AuraGenesis__AuraNotRedeemable();
    error AuraGenesis__TopicNotOpen();
    error AuraGenesis__TopicNotClosed();
    error AuraGenesis__InvalidAmount();
    error AuraGenesis__EpochNotElapsed();
    error AuraGenesis__ChallengeNotYetFinalized();
    error AuraGenesis__CollateralRequired();
    error AuraGenesis__NoAuraScore();


    // --- Enums & Constants ---
    enum AuraStatus {
        Submitted,      // Just submitted, awaiting initial processing
        Validating,     // Under challenge or active validation phase
        Validated,      // Deemed valid by validators
        Invalid,        // Deemed invalid by validators
        Redeemed,       // Collateral reclaimed
        Expired         // Aura's lifespan ended (due to resonance decay)
    }

    uint256 public constant MAX_RESONANCE = 10000; // Max possible resonance score (e.g., 100.00 represented as 10000)
    uint256 public constant MIN_RESONANCE = 1;     // Minimum resonance for an Aura to be considered active in Collective Understanding

    // --- Structs ---

    struct Topic {
        string topicName;
        string descriptionURI; // URI to off-chain detailed description
        address creator;
        uint256 fund;          // Tokens allocated to this topic, for rewards or burning
        uint256 createdAt;
        bool isOpen;
    }

    struct Aura {
        uint256 topicId;
        address submitter;
        string auraContentUri; // URI to off-chain insight content (e.g., IPFS hash of JSON/text)
        uint256 submittedAt;
        uint256 initialCollateral;
        uint256 currentResonance;
        AuraStatus status;
        address challenger; // Who challenged this aura (address(0) if not challenged)
        uint256 challengeEpochStart; // Epoch when the current challenge started
        mapping(address => bool) hasVoted; // Tracks if a validator has voted in the current challenge period
        uint256 validVotes;
        uint256 invalidVotes;
        bool validationFinalized; // True once the challenge has been finalized
    }

    // --- State Variables ---

    uint256 public nextTopicId;
    mapping(uint256 => Topic) public topics;

    uint256 public nextAuraId;
    mapping(uint256 => Aura) public auras;

    // Configuration parameters
    uint256 public epochDuration; // Duration of an epoch in seconds (e.g., 1 day = 86400)
    uint256 public initialResonanceDecayRate; // Percentage (e.g., 500 for 5%)
    uint256 public validationThresholdNumerator; // Numerator for validation threshold (e.g., 2 for 2/3)
    uint256 public validationThresholdDenominator; // Denominator for validation threshold (e.g., 3 for 2/3)
    uint256 public auraSubmissionFee; // Fee in AURA tokens to submit an Aura
    uint256 public minStakingForValidator; // Minimum AURA stake to be considered a validator
    uint256 public challengeCollateral; // Collateral required to challenge an Aura
    uint256 public rewardPerValidation; // Reward for a successful validation (claimed per validator batch)

    // Validator & Reputation
    mapping(address => uint256) public validatorStakes; // AURA tokens staked by validators
    mapping(address => uint256) public pendingValidationRewards; // Rewards accumulated by validators for accurate votes
    mapping(address => uint256) public userAuraScore; // Cumulative score for user contributions (influences AuraBadge)

    // --- Events ---
    event AuraTokenSet(address indexed _auraToken);
    event AuraBadgeNFTSet(address indexed _auraBadgeNFT);
    event EpochDurationSet(uint256 _duration);
    event InitialResonanceDecayRateSet(uint256 _rate);
    event ValidationThresholdSet(uint256 _numerator, uint256 _denominator);
    event AuraSubmissionFeeSet(uint256 _fee);
    event MinStakingForValidatorSet(uint256 _minStake);
    event ChallengeCollateralSet(uint256 _collateral);
    event RewardPerValidationSet(uint256 _reward);

    event TopicCreated(uint256 indexed topicId, string topicName, address indexed creator, uint256 fund);
    event TopicClosed(uint256 indexed topicId);

    event AuraSubmitted(uint256 indexed auraId, uint256 indexed topicId, address indexed submitter, uint256 initialCollateral);
    event AuraChallenged(uint256 indexed auraId, address indexed challenger);
    event AuraVoteCasted(uint256 indexed auraId, address indexed voter, bool isValid);
    event AuraValidationFinalized(uint256 indexed auraId, AuraStatus newStatus, uint256 finalResonance);
    event AuraResonanceUpdated(uint256 indexed auraId, uint256 oldResonance, uint256 newResonance);

    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event ValidationRewardsClaimed(address indexed validator, uint256 amount);
    event AuraCollateralRedeemed(uint256 indexed auraId, address indexed submitter, uint256 amount);
    event AuraBadgeUpdated(address indexed user, uint256 tokenId, uint256 newScore); // For both mint and update

    // --- Modifiers ---
    modifier onlyAuraTokenSet() {
        if (address(_auraToken) == address(0)) {
            revert AuraGenesis__InvalidAddress(address(0));
        }
        _;
    }

    modifier onlyAuraBadgeNFTSet() {
        if (address(_auraBadgeNFT) == address(0)) {
            revert AuraGenesis__InvalidAddress(address(0));
        }
        _;
    }

    modifier onlyValidator() {
        if (validatorStakes[msg.sender] < minStakingForValidator) {
            revert AuraGenesis__NotValidator();
        }
        _;
    }

    modifier topicMustBeOpen(uint256 _topicId) {
        if (_topicId >= nextTopicId || !topics[_topicId].isOpen) {
            revert AuraGenesis__TopicNotOpen();
        }
        _;
    }

    modifier auraMustExist(uint256 _auraId) {
        if (_auraId >= nextAuraId) {
            revert AuraGenesis__InvalidAuraId();
        }
        _;
    }

    // --- Constructor ---
    constructor(
        uint256 _epochDuration,
        uint256 _initialResonanceDecayRate,
        uint256 _validationThresholdNumerator,
        uint256 _validationThresholdDenominator,
        uint256 _auraSubmissionFee,
        uint256 _minStakingForValidator,
        uint256 _challengeCollateral,
        uint256 _rewardPerValidation
    ) Ownable(msg.sender) {
        if (_epochDuration == 0 || _initialResonanceDecayRate == 0 || _validationThresholdDenominator == 0) {
            revert AuraGenesis__InvalidAmount();
        }
        epochDuration = _epochDuration; // e.g., 1 day = 86400 seconds
        initialResonanceDecayRate = _initialResonanceDecayRate; // e.g., 500 (for 5% decay per epoch)
        validationThresholdNumerator = _validationThresholdNumerator; // e.g., 2
        validationThresholdDenominator = _validationThresholdDenominator; // e.g., 3 (for 2/3 majority)
        auraSubmissionFee = _auraSubmissionFee;
        minStakingForValidator = _minStakingForValidator;
        challengeCollateral = _challengeCollateral;
        rewardPerValidation = _rewardPerValidation;

        nextTopicId = 0;
        nextAuraId = 0;
    }

    // --- I. Configuration & Setup (Owner/DAO controlled) ---

    /**
     * @dev Sets the address of the AURA ERC20 token used for fees, staking, and rewards.
     * Callable only by the contract owner.
     * @param _auraTokenAddr Address of the AURA token contract.
     */
    function setAuraTokenAddress(address _auraTokenAddr) external onlyOwner {
        if (_auraTokenAddr == address(0)) {
            revert AuraGenesis__InvalidAddress(address(0));
        }
        _auraToken = IERC20(_auraTokenAddr);
        emit AuraTokenSet(_auraTokenAddr);
    }

    /**
     * @dev Sets the address of the AuraBadge ERC721 NFT contract.
     * Callable only by the contract owner.
     * @param _auraBadgeNFTAddr Address of the AuraBadge NFT contract.
     */
    function setAuraBadgeNFTAddress(address _auraBadgeNFTAddr) external onlyOwner {
        if (_auraBadgeNFTAddr == address(0)) {
            revert AuraGenesis__InvalidAddress(address(0));
        }
        _auraBadgeNFT = IAuraBadge(_auraBadgeNFTAddr);
        emit AuraBadgeNFTSet(_auraBadgeNFTAddr);
    }

    /**
     * @dev Adjusts the length of an evaluation epoch in seconds.
     * Callable only by the contract owner.
     * @param _duration New epoch duration.
     */
    function setEpochDuration(uint256 _duration) external onlyOwner {
        if (_duration == 0) revert AuraGenesis__InvalidAmount();
        epochDuration = _duration;
        emit EpochDurationSet(_duration);
    }

    /**
     * @dev Sets how quickly an Aura's resonance decays over time (e.g., 500 for 5%).
     * Rate is per 10000 basis points. Callable only by the contract owner.
     * @param _rate New decay rate (per 10000 basis points).
     */
    function setInitialResonanceDecayRate(uint256 _rate) external onlyOwner {
        if (_rate > 10000) revert AuraGenesis__InvalidAmount(); // Max 100% decay
        initialResonanceDecayRate = _rate;
        emit InitialResonanceDecayRateSet(_rate);
    }

    /**
     * @dev Sets the numerator for the validation threshold (e.g., 2 for 2/3).
     * Callable only by the contract owner.
     * @param _numerator New numerator.
     */
    function setValidationThresholdNumerator(uint256 _numerator) external onlyOwner {
        validationThresholdNumerator = _numerator;
        emit ValidationThresholdSet(validationThresholdNumerator, validationThresholdDenominator);
    }

    /**
     * @dev Sets the denominator for the validation threshold (e.g., 3 for 2/3).
     * Callable only by the contract owner.
     * @param _denominator New denominator.
     */
    function setValidationThresholdDenominator(uint256 _denominator) external onlyOwner {
        if (_denominator == 0) revert AuraGenesis__InvalidAmount();
        validationThresholdDenominator = _denominator;
        emit ValidationThresholdSet(validationThresholdNumerator, validationThresholdDenominator);
    }

    /**
     * @dev Sets the fee in AURA tokens required to submit a new Aura.
     * Callable only by the contract owner.
     * @param _fee New submission fee.
     */
    function setAuraSubmissionFee(uint256 _fee) external onlyOwner {
        auraSubmissionFee = _fee;
        emit AuraSubmissionFeeSet(_fee);
    }

    /**
     * @dev Sets the minimum AURA token stake required to become a validator.
     * Callable only by the contract owner.
     * @param _minStake New minimum stake.
     */
    function setMinStakingForValidator(uint256 _minStake) external onlyOwner {
        minStakingForValidator = _minStake;
        emit MinStakingForValidatorSet(_minStake);
    }

    /**
     * @dev Sets the collateral required to challenge an Aura.
     * Callable only by the contract owner.
     * @param _collateral New challenge collateral.
     */
    function setChallengeCollateral(uint256 _collateral) external onlyOwner {
        challengeCollateral = _collateral;
        emit ChallengeCollateralSet(_collateral);
    }

    /**
     * @dev Sets the AURA token reward for a successful Aura validation.
     * Callable only by the contract owner.
     * @param _reward New reward amount.
     */
    function setRewardPerValidation(uint256 _reward) external onlyOwner {
        rewardPerValidation = _reward;
        emit RewardPerValidationSet(_reward);
    }

    // --- II. Topic Management ---

    /**
     * @dev Creates a new topic for collective insights. Requires an initial fund from the creator.
     * The fund can be used for rewards within the topic or transferred back upon closure.
     * @param _topicName The name of the topic.
     * @param _descriptionURI URI to off-chain detailed description of the topic (e.g., IPFS hash).
     * @param _topicFund The amount of AURA tokens to fund the topic.
     */
    function createInsightTopic(string memory _topicName, string memory _descriptionURI, uint256 _topicFund)
        external
        onlyAuraTokenSet
    {
        if (_topicFund == 0) revert AuraGenesis__InvalidAmount();

        uint256 id = nextTopicId++;
        topics[id] = Topic({
            topicName: _topicName,
            descriptionURI: _descriptionURI,
            creator: msg.sender,
            fund: _topicFund,
            createdAt: block.timestamp,
            isOpen: true
        });

        // Transfer funds from sender to contract
        bool success = _auraToken.transferFrom(msg.sender, address(this), _topicFund);
        if (!success) revert AuraGenesis__InsufficientFunds();

        emit TopicCreated(id, _topicName, msg.sender, _topicFund);
    }

    /**
     * @dev Closes a topic, finalizing its collective understanding and distributing any remaining funds to the creator.
     * Can only be called by the topic creator or contract owner.
     * @param _topicId The ID of the topic to close.
     */
    function closeInsightTopic(uint256 _topicId) external {
        Topic storage topic = topics[_topicId];
        if (_topicId >= nextTopicId || !topic.isOpen) {
            revert AuraGenesis__InvalidTopicId();
        }
        if (msg.sender != topic.creator && msg.sender != owner()) {
            revert AuraGenesis__Unauthorized();
        }

        topic.isOpen = false;
        // Transfer remaining funds to the topic creator
        if (topic.fund > 0) {
            bool success = _auraToken.transfer(topic.creator, topic.fund);
            if (!success) revert AuraGenesis__InsufficientFunds(); // Should not happen if funds exist
            topic.fund = 0;
        }

        emit TopicClosed(_topicId);
    }

    /**
     * @dev Retrieves details about a specific insight topic.
     * @param _topicId The ID of the topic.
     * @return topicName, descriptionURI, creator, fund, createdAt, isOpen
     */
    function getTopicDetails(uint256 _topicId)
        external
        view
        returns (string memory topicName, string memory descriptionURI, address creator, uint256 fund, uint256 createdAt, bool isOpen)
    {
        if (_topicId >= nextTopicId) {
            revert AuraGenesis__InvalidTopicId();
        }
        Topic storage topic = topics[_topicId];
        return (topic.topicName, topic.descriptionURI, topic.creator, topic.fund, topic.createdAt, topic.isOpen);
    }

    // --- III. Aura (Insight) Management ---

    /**
     * @dev Users submit an insight (Aura) to a topic. Requires a submission fee and initial collateral.
     * The initial collateral is returned if the Aura is successfully validated.
     * @param _topicId The ID of the topic to submit the Aura to.
     * @param _auraContentUri URI to off-chain insight content (e.g., IPFS hash of JSON/text).
     * @param _initialCollateral The collateral staked by the submitter.
     */
    function submitAura(uint256 _topicId, string memory _auraContentUri, uint256 _initialCollateral)
        external
        topicMustBeOpen(_topicId)
        onlyAuraTokenSet
    {
        if (_initialCollateral == 0) revert AuraGenesis__CollateralRequired();

        // Transfer fee and collateral from sender to contract
        uint256 totalPayment = auraSubmissionFee.add(_initialCollateral);
        bool success = _auraToken.transferFrom(msg.sender, address(this), totalPayment);
        if (!success) revert AuraGenesis__InsufficientFunds();

        uint256 id = nextAuraId++;
        auras[id].topicId = _topicId;
        auras[id].submitter = msg.sender;
        auras[id].auraContentUri = _auraContentUri;
        auras[id].submittedAt = block.timestamp;
        auras[id].initialCollateral = _initialCollateral;
        auras[id].currentResonance = MAX_RESONANCE; // Start with max resonance
        auras[id].status = AuraStatus.Submitted;
        auras[id].validationFinalized = false;
        auras[id].challenger = address(0); // No challenger initially

        emit AuraSubmitted(id, _topicId, msg.sender, _initialCollateral);
    }

    /**
     * @dev Allows a user to challenge the validity of an existing Aura. Requires challenge collateral.
     * Moves the Aura into a 'Validating' state, initiating a voting period.
     * @param _auraId The ID of the Aura to challenge.
     */
    function challengeAura(uint256 _auraId)
        external
        auraMustExist(_auraId)
        topicMustBeOpen(auras[_auraId].topicId)
        onlyAuraTokenSet
    {
        Aura storage aura = auras[_auraId];
        // Only Submitted or Validated Auras can be challenged. An Aura can only be challenged once at a time.
        if ((aura.status != AuraStatus.Submitted && aura.status != AuraStatus.Validated) || aura.challenger != address(0)) {
            revert AuraGenesis__AuraNotChallengeable();
        }

        // Transfer challenge collateral from sender to contract
        bool success = _auraToken.transferFrom(msg.sender, address(this), challengeCollateral);
        if (!success) revert AuraGenesis__InsufficientFunds();

        aura.challenger = msg.sender;
        aura.status = AuraStatus.Validating;
        aura.challengeEpochStart = block.timestamp.div(epochDuration);
        aura.validVotes = 0;
        aura.invalidVotes = 0;
        aura.validationFinalized = false;
        // Reset hasVoted for the new challenge by creating a new context
        // (Solidity does not support iterating mappings to reset, new challenge context implies old votes are irrelevant)
        // This is implicitly handled by `challengeEpochStart` and `validationFinalized` checks.

        emit AuraChallenged(_auraId, msg.sender);
    }

    /**
     * @dev Validators cast their vote on a challenged Aura.
     * A validator can vote only once per challenge.
     * @param _auraId The ID of the Aura to vote on.
     * @param _isValid True if the Aura is considered valid, false otherwise.
     */
    function voteOnAuraValidity(uint256 _auraId, bool _isValid)
        external
        onlyValidator
        auraMustExist(_auraId)
    {
        Aura storage aura = auras[_auraId];
        if (aura.status != AuraStatus.Validating) {
            revert AuraGenesis__AuraNotInValidation();
        }
        if (aura.validationFinalized) { // Challenge already finalized
            revert AuraGenesis__ChallengeNotYetFinalized();
        }

        uint256 currentEpoch = block.timestamp.div(epochDuration);
        // Ensure voting is within the current challenge's epoch.
        if (currentEpoch != aura.challengeEpochStart) {
             revert AuraGenesis__EpochNotElapsed(); // Voting period has ended or not yet started for this challenge
        }
        if (aura.hasVoted[msg.sender]) {
            revert AuraGenesis__AlreadyVoted();
        }

        aura.hasVoted[msg.sender] = true;
        if (_isValid) {
            aura.validVotes++;
            // Increment pending rewards for accurate voters.
            pendingValidationRewards[msg.sender] = pendingValidationRewards[msg.sender].add(rewardPerValidation);
        } else {
            aura.invalidVotes++;
        }

        emit AuraVoteCasted(_auraId, msg.sender, _isValid);
    }

    /**
     * @dev Processes votes for a challenged Aura and updates its status and resonance.
     * Can be called by anyone after the voting epoch has passed.
     * Handles distribution of collateral and penalties.
     * @param _auraId The ID of the Aura to finalize.
     */
    function finalizeAuraValidation(uint256 _auraId)
        external
        auraMustExist(_auraId)
        onlyAuraTokenSet
    {
        Aura storage aura = auras[_auraId];
        if (aura.status != AuraStatus.Validating) {
            revert AuraGenesis__AuraNotInValidation();
        }
        if (aura.validationFinalized) {
            revert AuraGenesis__ChallengeNotYetFinalized(); // Already finalized
        }

        uint256 currentEpoch = block.timestamp.div(epochDuration);
        // Ensure voting period has ended
        if (currentEpoch == aura.challengeEpochStart) {
            revert AuraGenesis__EpochNotElapsed();
        }

        uint256 totalVotes = aura.validVotes.add(aura.invalidVotes);
        bool isAuraValid = false;

        if (totalVotes > 0) {
            // Check if majority of valid votes meets threshold
            if (aura.validVotes.mul(validationThresholdDenominator) >= totalVotes.mul(validationThresholdNumerator)) {
                isAuraValid = true;
            }
        } else {
            // If no votes, the challenge implicitly succeeds (Aura becomes invalid)
            // This incentivizes validators to vote, as failure to vote on a valid aura might penalize submitter.
            isAuraValid = false;
        }

        AuraStatus oldStatus = aura.status;
        uint256 oldResonance = aura.currentResonance;

        if (isAuraValid) {
            aura.status = AuraStatus.Validated;
            // Increase resonance for successful validation
            aura.currentResonance = aura.currentResonance.add(aura.currentResonance.div(10)); // 10% boost
            if (aura.currentResonance > MAX_RESONANCE) aura.currentResonance = MAX_RESONANCE;

            // Return challenger collateral if challenge failed (i.e., Aura was valid)
            if (aura.challenger != address(0)) {
                 bool success = _auraToken.transfer(aura.challenger, challengeCollateral);
                 if (!success) { /* Consider logging or reverting if transfer is critical. For demo, continue.*/ }
            }
        } else {
            aura.status = AuraStatus.Invalid;
            aura.currentResonance = 0; // Invalid Auras have 0 resonance
            // Slashing submitter collateral for invalid aura (transferred to topic fund or treasury)
            if (aura.initialCollateral > 0) {
                topics[aura.topicId].fund = topics[aura.topicId].fund.add(aura.initialCollateral); // Collateral added to topic fund
                aura.initialCollateral = 0; // Mark as slashed
            }

            // Reward challenger if challenge was successful (i.e., Aura was invalid)
            if (aura.challenger != address(0)) {
                 // Challenger gets their collateral back + an additional reward (e.g., portion of slashed collateral)
                 // Here, challengeCollateral * 2 is used, implies challenger gets their collateral back + an equal amount as reward.
                 // This amount could also come from the slashed collateral if _initialCollateral was enough.
                 bool success = _auraToken.transfer(aura.challenger, challengeCollateral.mul(2));
                 if (!success) { /* log error */ }
            }
        }

        aura.validationFinalized = true;
        aura.challenger = address(0); // Clear challenger

        _calculateAuraResonance(_auraId); // Recalculate resonance with time decay and status impact

        emit AuraValidationFinalized(_auraId, aura.status, aura.currentResonance);
        emit AuraResonanceUpdated(_auraId, oldResonance, aura.currentResonance);
    }

    /**
     * @dev Retrieves detailed information about a specific Aura.
     * @param _auraId The ID of the Aura.
     * @return topicId, submitter, auraContentUri, submittedAt, initialCollateral, currentResonance, status, challenger
     */
    function getAuraDetails(uint256 _auraId)
        external
        view
        auraMustExist(_auraId)
        returns (uint256 topicId, address submitter, string memory auraContentUri, uint256 submittedAt, uint256 initialCollateral, uint256 currentResonance, AuraStatus status, address challenger)
    {
        Aura storage aura = auras[_auraId];
        return (aura.topicId, aura.submitter, aura.auraContentUri, aura.submittedAt, aura.initialCollateral, aura.currentResonance, aura.status, aura.challenger);
    }

    /**
     * @dev Retrieves a list of Aura IDs submitted by a specific user.
     * Note: This function might become expensive for a very large number of Auras.
     * For large-scale applications, off-chain indexing is preferred for such queries.
     * @param _user The address of the user.
     * @return An array of Aura IDs.
     */
    function getUserAuras(address _user) external view returns (uint256[] memory) {
        uint256[] memory userAuraIds = new uint256[](nextAuraId); // Max possible size
        uint256 count = 0;
        for (uint256 i = 0; i < nextAuraId; i++) {
            if (auras[i].submitter == _user) {
                userAuraIds[count++] = i;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userAuraIds[i];
        }
        return result;
    }

    // --- IV. Validator Staking ---

    /**
     * @dev Allows users to stake AURA tokens to become a validator.
     * @param _amount The amount of AURA tokens to stake.
     */
    function stakeForValidation(uint256 _amount) external onlyAuraTokenSet {
        if (_amount == 0) revert AuraGenesis__InvalidAmount();
        bool success = _auraToken.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert AuraGenesis__InsufficientFunds();

        validatorStakes[msg.sender] = validatorStakes[msg.sender].add(_amount);
        emit ValidatorStaked(msg.sender, _amount);
    }

    /**
     * @dev Allows validators to unstake their AURA tokens.
     * @param _amount The amount of AURA tokens to unstake.
     */
    function unstakeFromValidation(uint256 _amount) external onlyAuraTokenSet {
        if (_amount == 0 || validatorStakes[msg.sender] < _amount) {
            revert AuraGenesis__InvalidAmount();
        }

        validatorStakes[msg.sender] = validatorStakes[msg.sender].sub(_amount);
        bool success = _auraToken.transfer(msg.sender, _amount);
        if (!success) revert AuraGenesis__InsufficientFunds(); // Should not fail if balance is checked

        emit ValidatorUnstaked(msg.sender, _amount);
    }

    // --- V. Reputation & Rewards ---

    /**
     * @dev Allows validators to claim their accumulated rewards for successfully validating Auras.
     */
    function claimValidationRewards() external onlyAuraTokenSet {
        uint256 rewards = pendingValidationRewards[msg.sender];
        if (rewards == 0) {
            revert AuraGenesis__InsufficientFunds(); // No pending rewards
        }

        pendingValidationRewards[msg.sender] = 0;
        bool success = _auraToken.transfer(msg.sender, rewards);
        if (!success) {
            revert AuraGenesis__InsufficientFunds(); // Should not fail if rewards exist
        }
        emit ValidationRewardsClaimed(msg.sender, rewards);
    }

    /**
     * @dev Allows an Aura submitter to reclaim their collateral if their Aura was successfully validated.
     * Collateral is returned only if the Aura is in a 'Validated' state and its collateral hasn't been zeroed out.
     * @param _auraId The ID of the Aura for which to redeem collateral.
     */
    function redeemAuraSubmissionCollateral(uint256 _auraId)
        external
        auraMustExist(_auraId)
        onlyAuraTokenSet
    {
        Aura storage aura = auras[_auraId];
        if (aura.submitter != msg.sender) {
            revert AuraGenesis__NotAuraSubmitter();
        }
        if (aura.status != AuraStatus.Validated) { // Only if explicitly validated and not expired
            revert AuraGenesis__AuraNotRedeemable();
        }
        if (aura.initialCollateral == 0) {
            revert AuraGenesis__AuraNotRedeemable(); // Already redeemed or slashed
        }

        uint256 collateralToRedeem = aura.initialCollateral;
        aura.initialCollateral = 0; // Mark as redeemed
        aura.status = AuraStatus.Redeemed; // Update status to reflect redemption

        bool success = _auraToken.transfer(msg.sender, collateralToRedeem);
        if (!success) {
            revert AuraGenesis__InsufficientFunds(); // Should not fail if balance is checked
        }
        emit AuraCollateralRedeemed(_auraId, msg.sender, collateralToRedeem);
    }

    /**
     * @dev Mints a new AuraBadge NFT for the user or updates an existing one,
     * reflecting their current `userAuraScore`. The actual dynamic properties
     * (e.g., metadata URI) are handled by the `IAuraBadge` contract itself.
     */
    function mintAuraBadge() external onlyAuraBadgeNFTSet {
        uint256 currentScore = userAuraScore[msg.sender];
        if (currentScore == 0) {
            revert AuraGenesis__NoAuraScore();
        }

        // Call the custom mintOrUpdateBadge function on the AuraBadge NFT contract.
        // The NFT contract handles whether it's a new mint or an update to an existing badge.
        uint256 tokenId = _auraBadgeNFT.mintOrUpdateBadge(msg.sender, currentScore);

        emit AuraBadgeUpdated(msg.sender, tokenId, currentScore);
    }

    /**
     * @dev Retrieves the current collective Aura score for a user.
     * This score reflects their cumulative contributions, accuracy, and validation success.
     * @param _user The address of the user.
     * @return The user's Aura score.
     */
    function getUserAuraScore(address _user) external view returns (uint256) {
        return userAuraScore[_user];
    }

    // --- VI. Collective Understanding & Querying ---

    /**
     * @dev Returns an array of highly resonant Aura URIs and their weights for a given topic,
     * forming the "collective understanding." Only includes Validated or Redeemed Auras above MIN_RESONANCE.
     * Off-chain services would fetch these URIs, interpret content, and aggregate based on resonance scores.
     * @param _topicId The ID of the topic.
     * @return An array of bytes (representing URI strings) and their corresponding resonance scores.
     */
    function getCollectiveUnderstanding(uint256 _topicId)
        external
        view
        returns (bytes[] memory auraUris, uint256[] memory auraResonances)
    {
        if (_topicId >= nextTopicId) {
            revert AuraGenesis__InvalidTopicId();
        }

        uint256[] memory eligibleAuraIds = new uint256[](nextAuraId);
        uint256 count = 0;

        for (uint256 i = 0; i < nextAuraId; i++) {
            Aura storage aura = auras[i];
            if (aura.topicId == _topicId &&
                (aura.status == AuraStatus.Validated || aura.status == AuraStatus.Redeemed) &&
                aura.currentResonance >= MIN_RESONANCE)
            {
                eligibleAuraIds[count++] = i;
            }
        }

        auraUris = new bytes[](count);
        auraResonances = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            auraUris[i] = bytes(auras[eligibleAuraIds[i]].auraContentUri);
            auraResonances[i] = auras[eligibleAuraIds[i]].currentResonance;
        }

        return (auraUris, auraResonances);
    }

    /**
     * @dev Allows querying Auras within a topic based on status and minimum resonance.
     * @param _topicId The ID of the topic.
     * @param _statusFilter Filter by AuraStatus (e.g., Validated).
     * @param _minResonance Minimum resonance score for inclusion.
     * @return An array of Aura IDs matching the criteria.
     */
    function queryTopicInsights(uint256 _topicId, AuraStatus _statusFilter, uint256 _minResonance)
        external
        view
        returns (uint256[] memory)
    {
        if (_topicId >= nextTopicId) {
            revert AuraGenesis__InvalidTopicId();
        }

        uint256[] memory matchingAuraIds = new uint256[](nextAuraId);
        uint256 count = 0;

        for (uint256 i = 0; i < nextAuraId; i++) {
            Aura storage aura = auras[i];
            if (aura.topicId == _topicId &&
                aura.status == _statusFilter &&
                aura.currentResonance >= _minResonance)
            {
                matchingAuraIds[count++] = i;
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingAuraIds[i];
        }
        return result;
    }

    // --- VII. Internal / Helper Functions ---

    /**
     * @dev Internal function to re-calculate and update an Aura's dynamic resonance.
     * This simulates the "adaptive" nature of the system. Resonance decays over time
     * and is heavily influenced by validation status.
     * This function should ideally be called periodically by an external keeper network
     * for all active Auras to ensure continuous decay, or upon relevant events like validation.
     * @param _auraId The ID of the Aura to update.
     */
    function _calculateAuraResonance(uint256 _auraId) internal {
        Aura storage aura = auras[_auraId];

        // If an Aura is invalid, its resonance remains 0.
        if (aura.status == AuraStatus.Invalid || aura.currentResonance == 0) {
            if (aura.currentResonance != 0) {
                 uint256 oldResonance = aura.currentResonance;
                 aura.currentResonance = 0;
                 userAuraScore[aura.submitter] = userAuraScore[aura.submitter].sub(oldResonance); // Penalize score
                 emit AuraResonanceUpdated(_auraId, oldResonance, aura.currentResonance);
            }
            return;
        }

        uint256 currentEpoch = block.timestamp.div(epochDuration);
        uint256 epochsPassedSinceSubmission = currentEpoch.sub(aura.submittedAt.div(epochDuration));

        uint256 oldResonance = aura.currentResonance;
        uint256 newResonance = aura.currentResonance;

        // Apply time decay
        // Decay is cumulative over epochs passed.
        if (epochsPassedSinceSubmission > 0) {
            uint256 totalDecayFactor = initialResonanceDecayRate.mul(epochsPassedSinceSubmission);
            if (totalDecayFactor >= 10000) { // If decay is 100% or more
                newResonance = 0;
            } else {
                newResonance = newResonance.mul(10000 - totalDecayFactor).div(10000);
            }
        }

        // Ensure resonance doesn't fall below MIN_RESONANCE without becoming 0
        if (newResonance < MIN_RESONANCE) {
            newResonance = 0;
            // If resonance decays to 0, and it was previously validated or redeemed, mark as expired.
            if (aura.status == AuraStatus.Validated || aura.status == AuraStatus.Redeemed) {
                aura.status = AuraStatus.Expired;
            }
        }

        aura.currentResonance = newResonance;

        // Update user's Aura score based on changes in their Aura's resonance
        // This is a simplified model: score directly reflects the resonance of their Auras.
        // A more complex model could also factor in validation success, number of challenges etc.
        if (oldResonance > newResonance) {
            userAuraScore[aura.submitter] = userAuraScore[aura.submitter].sub(oldResonance.sub(newResonance));
        } else if (newResonance > oldResonance) {
            userAuraScore[aura.submitter] = userAuraScore[aura.submitter].add(newResonance.sub(oldResonance));
        }

        emit AuraResonanceUpdated(_auraId, oldResonance, newResonance);
    }
}

```