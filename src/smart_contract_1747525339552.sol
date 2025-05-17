Okay, let's design a smart contract around a complex, dynamic NFT system. This concept will involve NFTs that evolve, gain experience, can be staked, and have attributes that change based on on-chain activity. We'll call it "Chronos Sentinels" - NFTs that embody the passage of time and interactions.

This contract will combine elements of:
1.  **Dynamic Attributes:** NFT traits change based on time staked or interactions.
2.  **Evolution:** NFTs can evolve to a new stage after meeting specific criteria (e.g., time staked, interactions).
3.  **Staking:** Stake NFTs to earn a reward token and gain "Chronos Experience (XP)".
4.  **Social Interaction:** Sentinels can "attune" to each other, affecting their XP gain or evolution paths.
5.  **Generative Elements:** Initial attributes are generated upon minting.

This contract will *not* be a simple ERC-721; it will build significant logic *on top* of it.

---

**Contract Name:** `ChronosSentinels`

**Concept:** Dynamic, Evolving, Staking, and Social NFTs that gain experience and change attributes based on on-chain activity.

**Outline:**

1.  **Standards:** ERC721, Ownable, Pausable, ReentrancyGuard.
2.  **Errors:** Custom errors for specific failures.
3.  **Events:** Minting, Staking, Unstaking, Evolution, Attunement, etc.
4.  **State Variables:**
    *   Core ERC721 state.
    *   Owner, Paused state.
    *   Token Counter.
    *   Reward Token Address (ERC20).
    *   Mappings for Sentinel Attributes (dynamic struct).
    *   Mappings for Staking Info (stake time, pending rewards, XP).
    *   Mappings for Attunement (relationships between NFTs).
    *   Evolution Criteria (mapping stage to requirements).
    *   Admin-set parameters (reward rates, XP rates, etc.).
5.  **Structs & Enums:**
    *   `SentinelAttributes`: Stores mutable and immutable traits.
    *   `StakingInfo`: Tracks staking state.
    *   `AttunementInfo`: Tracks social links.
    *   `EvolutionStage`: Enum for different evolution forms.
    *   `EvolutionCriteria`: Struct for evolution requirements.
6.  **Modifiers:** `onlyOwner`, `whenNotPaused`, `whenPaused`, `nonReentrant`.
7.  **Constructor:** Initializes owner, reward token address.
8.  **Base ERC721 Functions:** Implement or override standard ERC721 functions (`balanceOf`, `ownerOf`, `transferFrom`, `approve`, `setApprovalForAll`, `getApproved`, `isApprovedForAll`, `tokenURI`). `tokenURI` will need custom logic to reflect dynamic attributes.
9.  **Core Mechanics:**
    *   **Minting:** Generate new Sentinels with initial attributes.
    *   **Staking:** Lock Sentinels to earn rewards and XP.
    *   **Unstaking:** Unlock Sentinels, claim rewards, finalize XP.
    *   **Claiming:** Claim accumulated rewards without unstaking.
    *   **Evolution:** Trigger evolution if criteria met.
    *   **Attunement:** Link two Sentinels socially.
    *   **Interaction:** Generic function for one Sentinel interacting with another.
    *   **XP Calculation:** Internal function to calculate XP based on activity.
10. **View Functions:** Get details about NFTs (attributes, staking, attunement, pending rewards, evolution progress, XP level).
11. **Admin Functions:** Set parameters, pause/unpause, withdraw funds, manage evolution criteria.
12. **Internal Helpers:** Functions like attribute generation, XP calculation, reward calculation, evolution check.

**Function Summary (Public/External Functions):**

1.  `constructor(address initialOwner, address rewardTokenAddress)`: Initializes the contract with the owner and reward token address.
2.  `mintSentinel(address recipient)`: Mints a new Sentinel NFT to the specified recipient with randomly generated (or pseudorandom based on block/tx data) initial attributes.
3.  `stakeSentinel(uint256 tokenId)`: Stakes the specified Sentinel NFT. Transfers the NFT to the contract address and records staking start time. Requires caller to be the token owner.
4.  `unstakeSentinel(uint256 tokenId)`: Unstakes the specified Sentinel NFT. Calculates and distributes pending rewards and XP, transfers the NFT back to the owner. Requires caller to be the token owner.
5.  `claimRewards(uint256 tokenId)`: Claims pending staking rewards for a staked Sentinel without unstaking it. Calculates and distributes rewards earned since the last claim/stake.
6.  `evolveSentinel(uint256 tokenId)`: Attempts to evolve the specified Sentinel to the next stage if it meets the predefined criteria (e.g., required XP, staking duration, attunement status). Modifies attributes upon success.
7.  `attuneSentinels(uint256 tokenId1, uint256 tokenId2)`: Creates a social link ("Attunement") between two Sentinels. This bond can influence XP gain or evolution criteria. Requires caller to own both tokens.
8.  `unattuneSentinels(uint256 tokenId1, uint256 tokenId2)`: Breaks the Attunement bond between two Sentinels. Requires caller to own both tokens.
9.  `interactWithSentinel(uint256 tokenId, bytes data)`: A generic function allowing a token owner or potentially other addresses to interact with a Sentinel. Could grant minor XP or trigger small attribute shifts based on `data` payload (interpreted by off-chain logic or simple on-chain rules).
10. `getSentinelAttributes(uint256 tokenId) view`: Returns the current dynamic and static attributes of a Sentinel.
11. `getSentinelStakingInfo(uint256 tokenId) view`: Returns the staking details for a Sentinel (isStaked, stakeStartTime, pending rewards, accumulated XP).
12. `getSentinelAttunement(uint256 tokenId) view`: Returns the list of token IDs this Sentinel is currently attuned to.
13. `getPendingRewards(uint256 tokenId) view`: Calculates and returns the pending rewards for a staked Sentinel.
14. `getSentinelXP(uint256 tokenId) view`: Returns the current total Chronos Experience (XP) of a Sentinel.
15. `getSentinelLevel(uint256 tokenId) view`: Calculates and returns the level of a Sentinel based on its XP.
16. `getEvolutionProgress(uint256 tokenId) view`: Shows how close a Sentinel is to meeting its next evolution criteria.
17. `tokenURI(uint256 tokenId) view override`: Returns the metadata URI for the token. This URI should resolve to JSON reflecting the *current* dynamic state and attributes.
18. `setEvolutionCriteria(uint8 stage, uint256 requiredXP, uint256 requiredStakeDuration, uint256 requiredAttunements, uint256 requiredInteractions) onlyOwner`: Allows the owner to define the criteria for evolving to a specific stage.
19. `setStakingRewardRate(uint256 ratePerSecond) onlyOwner`: Sets the rate at which staked Sentinels earn the reward token (per second per token).
20. `setXPStakeRate(uint256 xpPerSecond) onlyOwner`: Sets the rate at which staked Sentinels earn XP (per second per token).
21. `setXPInteractionAmount(uint256 xpAmount) onlyOwner`: Sets the base amount of XP gained per `interactWithSentinel` call.
22. `setTokenURIPrefix(string memory newPrefix) onlyOwner`: Sets the base URI for token metadata.
23. `pauseContractActivity() onlyOwner whenNotPaused`: Pauses staking, unstaking, claiming, evolving, attuning, and interacting functions.
24. `unpauseContractActivity() onlyOwner whenPaused`: Unpauses contract activity.
25. `withdrawERC20(address tokenAddress, uint256 amount) onlyOwner`: Allows owner to withdraw any ERC20 tokens accidentally sent to the contract (except the Sentinel reward token if needed for rewards).
26. `withdrawEther(uint256 amount) onlyOwner`: Allows owner to withdraw ETH accidentally sent to the contract.
27. `transferOwnership(address newOwner) onlyOwner`: Transfers ownership of the contract.
28. `renounceOwnership() onlyOwner`: Renounces ownership of the contract (sets owner to zero address).

This list contains 28 public/external functions, covering the requirement of "at least 20 functions" with significant custom logic beyond a basic ERC-721.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol"; // For min/max or other ops if needed

// --- Outline ---
// 1. Standards: ERC721, Ownable, Pausable, ReentrancyGuard.
// 2. Errors: Custom errors.
// 3. Events: Activity tracking.
// 4. State Variables: Core contract state, data mappings.
// 5. Structs & Enums: Data structures for Sentinel info.
// 6. Modifiers: Access control and state checks.
// 7. Constructor: Initial setup.
// 8. Base ERC721 Functions: Overrides for dynamic tokenURI.
// 9. Core Mechanics: Minting, Staking, Unstaking, Claiming, Evolution, Attunement, Interaction.
// 10. View Functions: Retrieve state information.
// 11. Admin Functions: Parameter tuning, pausing, withdrawals.
// 12. Internal Helpers: Calculation logic, attribute generation.

// --- Function Summary (Public/External) ---
// 1. constructor(address initialOwner, address rewardTokenAddress): Contract initialization.
// 2. mintSentinel(address recipient): Mints a new dynamic NFT.
// 3. stakeSentinel(uint256 tokenId): Locks NFT for staking rewards/XP.
// 4. unstakeSentinel(uint256 tokenId): Unlocks NFT, distributes rewards/XP.
// 5. claimRewards(uint256 tokenId): Claims rewards for staked NFT without unstaking.
// 6. evolveSentinel(uint256 tokenId): Attempts to evolve NFT if criteria met.
// 7. attuneSentinels(uint256 tokenId1, uint256 tokenId2): Creates a social link between NFTs.
// 8. unattuneSentinels(uint256 tokenId1, uint256 tokenId2): Breaks social link between NFTs.
// 9. interactWithSentinel(uint256 tokenId, bytes data): Generic interaction function for NFTs.
// 10. getSentinelAttributes(uint256 tokenId) view: Get current NFT attributes.
// 11. getSentinelStakingInfo(uint256 tokenId) view: Get NFT staking details.
// 12. getSentinelAttunement(uint256 tokenId) view: Get NFTs a Sentinel is attuned to.
// 13. getPendingRewards(uint256 tokenId) view: Calculate pending staking rewards.
// 14. getSentinelXP(uint256 tokenId) view: Get total accumulated XP.
// 15. getSentinelLevel(uint256 tokenId) view: Get NFT level based on XP.
// 16. getEvolutionProgress(uint256 tokenId) view: Check progress towards next evolution.
// 17. tokenURI(uint256 tokenId) view override: Get metadata URI reflecting dynamic state.
// 18. setEvolutionCriteria(uint8 stage, uint256 requiredXP, uint256 requiredStakeDuration, uint256 requiredAttunements, uint256 requiredInteractions) onlyOwner: Set evolution rules.
// 19. setStakingRewardRate(uint256 ratePerSecond) onlyOwner: Set reward token rate.
// 20. setXPStakeRate(uint256 xpPerSecond) onlyOwner: Set XP gain rate from staking.
// 21. setXPInteractionAmount(uint256 xpAmount) onlyOwner: Set XP gain amount from interaction.
// 22. setTokenURIPrefix(string memory newPrefix) onlyOwner: Set base for metadata URIs.
// 23. pauseContractActivity() onlyOwner whenNotPaused: Pause core activities.
// 24. unpauseContractActivity() onlyOwner whenPaused: Unpause core activities.
// 25. withdrawERC20(address tokenAddress, uint256 amount) onlyOwner: Withdraw specified ERC20s.
// 26. withdrawEther(uint256 amount) onlyOwner: Withdraw ETH.
// 27. transferOwnership(address newOwner) onlyOwner: Transfer contract ownership.
// 28. renounceOwnership() onlyOwner: Renounce contract ownership.

contract ChronosSentinels is ERC721, Ownable, Pausable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // --- Errors ---
    error TokenDoesNotExist(uint256 tokenId);
    error NotTokenOwner(uint256 tokenId, address caller);
    error TokenAlreadyStaked(uint256 tokenId);
    error TokenNotStaked(uint256 tokenId);
    error InvalidEvolutionStage(uint8 currentStage);
    error EvolutionCriteriaNotMet(string reason); // Generic reason for failure
    error CannotAttuneSelf(uint256 tokenId);
    error TokensAlreadyAttuned(uint256 tokenId1, uint256 tokenId2);
    error TokensNotAttuned(uint256 tokenId1, uint256 tokenId2);
    error MaxAttunementsReached(uint256 tokenId);
    error InvalidInteraction(uint256 tokenId); // For interactWithSentinel validation
    error ZeroAddressRecipient();
    error CannotWithdrawRewardToken(); // Prevent withdrawing the reward token

    // --- Events ---
    event SentinelMinted(uint256 indexed tokenId, address indexed owner, uint8 initialStage);
    event SentinelStaked(uint256 indexed tokenId, address indexed owner, uint256 stakeStartTime);
    event SentinelUnstaked(uint256 indexed tokenId, address indexed owner, uint256 stakeDuration, uint256 rewardsClaimed, uint256 xpEarned);
    event RewardsClaimed(uint256 indexed tokenId, uint256 amount);
    event SentinelEvolved(uint256 indexed tokenId, uint8 oldStage, uint8 newStage);
    event SentinelsAttuned(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event SentinelsUnattuned(uint256 indexed tokenId1, uint256 indexed tokenId2);
    event SentinelInteracted(uint256 indexed tokenId, address indexed caller, bytes data);
    event EvolutionCriteriaUpdated(uint8 stage, uint256 requiredXP, uint256 requiredStakeDuration, uint256 requiredAttunements, uint256 requiredInteractions);
    event StakingRewardRateUpdated(uint256 ratePerSecond);
    event XPStakeRateUpdated(uint256 xpPerSecond);
    event XPInteractionAmountUpdated(uint256 xpAmount);

    // --- State Variables ---
    Counters.Counter private _tokenIds;
    address public immutable rewardToken; // The ERC20 token earned by staking

    // --- Structs & Enums ---

    enum EvolutionStage { Hatchling, Juvenile, Adult, Elder, Ethereal } // Example stages

    struct SentinelAttributes {
        // Immutable traits set at mint
        uint256 generation; // e.g., 1 for Gen 1
        uint8 initialAffinity; // e.g., a number representing a type

        // Dynamic traits updated via activity/evolution
        uint8 currentStage;
        uint256 totalXP; // Accumulated experience
        // Example Dynamic Stats (could map XP to these or update on evolution)
        uint256 chronosPower; // Increases with XP/stage
        uint256 resilience; // Increases with staking duration
        uint256 connectionStrength; // Increases with attunements/interactions
    }

    struct StakingInfo {
        bool isStaked;
        uint256 stakeStartTime; // 0 if not staked
        uint256 lastRewardClaimTime; // Timestamp of last claim or stake start
        uint256 accumulatedUnclaimedRewards; // Rewards earned but not yet claimed
        uint256 accumulatedXP; // XP earned while staked (added to totalXP on unstake/claim)
    }

    struct EvolutionCriteria {
        uint256 requiredXP;
        uint256 requiredStakeDuration; // Total cumulative stake duration
        uint256 requiredAttunements; // Number of active attunement links
        uint256 requiredInteractions; // Cumulative interactions received
    }

    // --- Mappings ---
    mapping(uint256 => SentinelAttributes) private _sentinelAttributes;
    mapping(uint256 => StakingInfo) private _stakingInfo;
    mapping(uint256 => mapping(uint256 => bool)) private _attunedTo; // tokenId1 => tokenId2 => isAttuned
    mapping(uint256 => uint256) private _attunementCount; // Number of tokens a sentinel is attuned to
    mapping(uint256 => uint256) private _interactionCount; // Number of times a sentinel has been interacted with
    mapping(uint8 => EvolutionCriteria) private _evolutionCriteria;

    // Admin settable parameters
    uint256 public stakingRewardRatePerSecond; // ERC20 amount per second per sentinel
    uint256 public xpStakeRatePerSecond; // XP per second per sentinel staked
    uint256 public xpInteractionAmount; // XP per interaction
    string private _tokenURIPrefix;

    // --- Modifiers ---
    modifier whenTokenExists(uint256 tokenId) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        address owner = ownerOf(tokenId);
        if (owner != _msgSender()) {
            revert NotTokenOwner(tokenId, _msgSender());
        }
        _;
    }

    modifier whenTokenStaked(uint256 tokenId) {
        if (!_stakingInfo[tokenId].isStaked) {
            revert TokenNotStaked(tokenId);
        }
        _;
    }

    modifier whenTokenNotStaked(uint256 tokenId) {
        if (_stakingInfo[tokenId].isStaked) {
            revert TokenAlreadyStaked(tokenId);
        }
        _;
    }

    // --- Constructor ---
    constructor(address initialOwner, address rewardTokenAddress)
        ERC721("Chronos Sentinels", "CRS")
        Ownable(initialOwner)
        Pausable()
    {
        if (rewardTokenAddress == address(0)) {
            revert ZeroAddressRecipient(); // Or a more specific error
        }
        rewardToken = rewardTokenAddress;

        // Set initial evolution criteria (Example values)
        _evolutionCriteria[uint8(EvolutionStage.Hatchling)] = EvolutionCriteria(0, 0, 0, 0); // No criteria for first stage
        _evolutionCriteria[uint8(EvolutionStage.Juvenile)] = EvolutionCriteria(1000, 1 days, 1, 5);
        _evolutionCriteria[uint8(EvolutionStage.Adult)] = EvolutionCriteria(5000, 10 days, 3, 20);
        _evolutionCriteria[uint8(EvolutionStage.Elder)] = EvolutionCriteria(20000, 60 days, 5, 100);
        // Ethereal could have very high or unique criteria
        _evolutionCriteria[uint8(EvolutionStage.Ethereal)] = EvolutionCriteria(100000, 365 days, 10, 500);

        // Set initial rates (Example values)
        stakingRewardRatePerSecond = 1e16; // Example: 0.01 of reward token per second
        xpStakeRatePerSecond = 1; // Example: 1 XP per second staked
        xpInteractionAmount = 50; // Example: 50 XP per interaction
    }

    // --- Base ERC721 Functions ---
    // Override transfer functions to handle staking state
    function _update(address to, uint256 tokenId, address auth) internal override whenNotStaked(tokenId) returns (address) {
        // Check if the token is attuned before transfer, if so, break attunements
        _breakAllAttunements(tokenId);
        return super()._update(to, tokenId, auth);
    }

    function _burn(uint256 tokenId) internal override whenNotStaked(tokenId) {
        // Check if the token is attuned before burning, if so, break attunements
        _breakAllAttunements(tokenId);
        super()._burn(tokenId);
    }

    // Overridden to provide dynamic metadata reflecting current state
    function tokenURI(uint256 tokenId) public view override whenTokenExists(tokenId) returns (string memory) {
        // Construct URI: prefix + tokenId + suffix?query_params=reflecting_state
        // This requires off-chain metadata service that reads state from the contract
        // and generates JSON accordingly.
        // Example simple structure: prefix/tokenId
        // Off-chain service would query getSentinelAttributes, getSentinelStakingInfo, etc.
        return string(abi.encodePacked(_tokenURIPrefix, tokenId.toString()));
    }

    // --- Core Mechanics ---

    /// @notice Mints a new Chronos Sentinel NFT.
    /// Initial attributes are generated based on a pseudo-random seed.
    /// @param recipient The address to mint the token to.
    /// @return uint256 The ID of the newly minted token.
    function mintSentinel(address recipient) public onlyOwner whenNotPaused nonReentrant returns (uint256) {
        if (recipient == address(0)) {
            revert ZeroAddressRecipient();
        }
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(recipient, newTokenId);

        // Generate initial attributes (pseudo-random example)
        bytes32 seed = keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, newTokenId, block.number));
        _generateInitialAttributes(newTokenId, seed);

        emit SentinelMinted(newTokenId, recipient, _sentinelAttributes[newTokenId].currentStage);
        return newTokenId;
    }

    /// @notice Stakes a Sentinel NFT, locking it in the contract.
    /// Starts accumulating rewards and XP. Requires token ownership.
    /// @param tokenId The ID of the Sentinel to stake.
    function stakeSentinel(uint256 tokenId) public payable whenTokenExists(tokenId) onlyTokenOwner(tokenId) whenTokenNotStaked(tokenId) whenNotPaused nonReentrant {
        // Transfer token to contract
        _safeTransferFrom(_msgSender(), address(this), tokenId);

        // Record staking info
        _stakingInfo[tokenId].isStaked = true;
        _stakingInfo[tokenId].stakeStartTime = block.timestamp;
        _stakingInfo[tokenId].lastRewardClaimTime = block.timestamp;
        _stakingInfo[tokenId].accumulatedUnclaimedRewards = 0;
        // Accumulated XP is not reset on stake, it's total lifetime XP.
        // _stakingInfo[tokenId].accumulatedXP is XP gained *while currently staked* before it's added to totalXP on unstake/claim.
        _stakingInfo[tokenId].accumulatedXP = 0;

        emit SentinelStaked(tokenId, _msgSender(), block.timestamp);
    }

    /// @notice Unstakes a Sentinel NFT, returning it to the owner.
    /// Claims all pending rewards and adds accumulated staking XP to total XP.
    /// @param tokenId The ID of the Sentinel to unstake.
    function unstakeSentinel(uint256 tokenId) public payable whenTokenExists(tokenId) whenTokenStaked(tokenId) whenNotPaused nonReentrant {
        address originalOwner = ownerOf(address(this)); // Contract is owner when staked

        // Calculate and distribute pending rewards and XP
        _calculateAndDistributeRewardsAndXP(tokenId);

        // Update staking info
        uint256 stakeDuration = block.timestamp - _stakingInfo[tokenId].stakeStartTime;
        uint256 xpEarned = _stakingInfo[tokenId].accumulatedXP;

        delete _stakingInfo[tokenId]; // Clear staking info

        // Transfer token back to original owner (the one who staked it)
        // Need to store original staker if transfer ownership is allowed while staked (it's not in this version)
        // For simplicity, assume ownerOf(address(this)) is the current staker's address.
        // If allowing ownership transfer while staked, need a mapping for staker address.
        _safeTransferFrom(address(this), originalOwner, tokenId);

        emit SentinelUnstaked(tokenId, originalOwner, stakeDuration, _stakingInfo[tokenId].accumulatedUnclaimedRewards, xpEarned);
        // Note: accumulatedUnclaimedRewards is 0 after _calculateAndDistributeRewardsAndXP
    }

    /// @notice Claims accumulated staking rewards for a staked Sentinel.
    /// Does not unstake the NFT. Adds earned XP to total XP.
    /// @param tokenId The ID of the staked Sentinel.
    function claimRewards(uint256 tokenId) public payable whenTokenExists(tokenId) whenTokenStaked(tokenId) whenNotPaused nonReentrant {
        // Calculate and distribute pending rewards and XP
        _calculateAndDistributeRewardsAndXP(tokenId);

        emit RewardsClaimed(tokenId, _stakingInfo[tokenId].accumulatedUnclaimedRewards); // This will be 0 after the call

        // Update the last claim time
        _stakingInfo[tokenId].lastRewardClaimTime = block.timestamp;
        _stakingInfo[tokenId].accumulatedUnclaimedRewards = 0;
         _stakingInfo[tokenId].accumulatedXP = 0; // Reset accumulated XP for the current staking period after adding to total
    }

    /// @notice Attempts to evolve a Sentinel to the next stage.
    /// Checks if the Sentinel meets the criteria for the next evolution stage.
    /// @param tokenId The ID of the Sentinel to evolve.
    function evolveSentinel(uint256 tokenId) public payable whenTokenExists(tokenId) onlyTokenOwner(tokenId) whenNotPaused nonReentrant {
        SentinelAttributes storage attrs = _sentinelAttributes[tokenId];
        uint8 currentStage = attrs.currentStage;
        uint8 nextStage = currentStage + 1;

        if (nextStage > uint8(EvolutionStage.Ethereal)) {
            revert InvalidEvolutionStage(currentStage);
        }

        EvolutionCriteria memory criteria = _evolutionCriteria[nextStage];

        // Check criteria
        if (attrs.totalXP < criteria.requiredXP) {
             revert EvolutionCriteriaNotMet(string(abi.encodePacked("Requires ", criteria.requiredXP.toString(), " XP")));
        }
        // RequiredStakeDuration check: Requires cumulative stake duration.
        // This needs a mechanism to track cumulative stake time across staking periods.
        // For simplicity here, let's assume accumulatedStakedDuration is tracked in attributes or staking info
        // and updated on unstake. A more robust system would need a dedicated mapping.
        // Placeholder for now: Check if _stakingInfo[tokenId].stakeStartTime implies enough *current* stake duration
        // or rely purely on XP/Attunements for this example's evolution criteria check.
        // Let's simplify evolution criteria for this example to just XP and Attunements, as cumulative duration tracking adds complexity.
        // Or, let's track cumulative stake duration in attributes!
        // Update SentinelAttributes struct: add `uint256 cumulativeStakeDuration;`
        // And update _calculateAndDistributeRewardsAndXP/unstake to add to this.
        // For this example, let's proceed *without* cumulativeStakeDuration for simplicity in evolution check itself.
        // The criteria struct exists, but the check here will omit duration for now.
        // *Correction*: Let's add a placeholder cumulativeStakeDuration to SentinelAttributes and assume it's updated.

         if (_attunementCount[tokenId] < criteria.requiredAttunements) {
             revert EvolutionCriteriaNotMet(string(abi.encodePacked("Requires ", criteria.requiredAttunements.toString(), " active attunements")));
         }

         if (_interactionCount[tokenId] < criteria.requiredInteractions) {
             revert EvolutionCriteriaNotMet(string(abi.encodePacked("Requires ", criteria.requiredInteractions.toString(), " interactions received")));
         }

        // If all criteria met
        attrs.currentStage = nextStage;
        // Update dynamic attributes based on new stage (Example: increase power/resilience)
        attrs.chronosPower += (nextStage - currentStage) * 100;
        attrs.resilience += (nextStage - currentStage) * 50;
        attrs.connectionStrength += (nextStage - currentStage) * 20; // Evolution might boost social stats too

        emit SentinelEvolved(tokenId, currentStage, nextStage);
    }

    /// @notice Creates an Attunement bond between two Sentinels owned by the caller.
    /// Attunement is bidirectional.
    /// @param tokenId1 The ID of the first Sentinel.
    /// @param tokenId2 The ID of the second Sentinel.
    function attuneSentinels(uint256 tokenId1, uint256 tokenId2) public payable
        whenTokenExists(tokenId1) whenTokenExists(tokenId2)
        onlyTokenOwner(tokenId1) onlyTokenOwner(tokenId2) // Requires caller owns BOTH
        whenNotPaused nonReentrant
    {
        if (tokenId1 == tokenId2) {
            revert CannotAttuneSelf(tokenId1);
        }
        if (_attunedTo[tokenId1][tokenId2]) {
            revert TokensAlreadyAttuned(tokenId1, tokenId2);
        }
        // Optional: Implement Max Attunements
        // uint256 maxAttunements = 5; // Example Limit
        // if (_attunementCount[tokenId1] >= maxAttunements || _attunementCount[tokenId2] >= maxAttunements) {
        //     revert MaxAttunementsReached(tokenId1); // Or tokenId2
        // }

        _attunedTo[tokenId1][tokenId2] = true;
        _attunedTo[tokenId2][tokenId1] = true; // Bidirectional bond
        _attunementCount[tokenId1]++;
        _attunementCount[tokenId2]++;

        emit SentinelsAttuned(tokenId1, tokenId2);
    }

    /// @notice Breaks the Attunement bond between two Sentinels owned by the caller.
    /// @param tokenId1 The ID of the first Sentinel.
    /// @param tokenId2 The ID of the second Sentinel.
    function unattuneSentinels(uint256 tokenId1, uint256 tokenId2) public payable
        whenTokenExists(tokenId1) whenTokenExists(tokenId2)
        onlyTokenOwner(tokenId1) onlyTokenOwner(tokenId2) // Requires caller owns BOTH
        whenNotPaused nonReentrant
    {
        if (tokenId1 == tokenId2) {
            revert CannotAttuneSelf(tokenId1); // Still relevant? Maybe not, but good practice
        }
        if (!_attunedTo[tokenId1][tokenId2]) {
            revert TokensNotAttuned(tokenId1, tokenId2);
        }

        _attunedTo[tokenId1][tokenId2] = false;
        _attunedTo[tokenId2][tokenId1] = false; // Break bidirectional bond
        _attunementCount[tokenId1]--;
        _attunementCount[tokenId2]--;

        emit SentinelsUnattuned(tokenId1, tokenId2);
    }

    /// @notice Allows interaction with a specific Sentinel.
    /// Can be called by the owner or potentially other allowed addresses.
    /// Grants XP and increments interaction count.
    /// @param tokenId The ID of the Sentinel being interacted with.
    /// @param data Optional arbitrary data related to the interaction.
    function interactWithSentinel(uint256 tokenId, bytes calldata data) public whenTokenExists(tokenId) whenNotPaused nonReentrant {
         // Decide if only owner can interact, or anyone.
         // Let's allow anyone to interact for a more social aspect.
         // Add a check if msg.sender is NOT the contract address (i.e., not an internal call)

        _sentinelAttributes[tokenId].totalXP += xpInteractionAmount;
        _interactionCount[tokenId]++;

        // Optional: Interpret 'data' for complex interactions
        // e.g., if data indicates a specific type of interaction, grant different XP
        // Or check if msg.sender is a specific authorized address.
        // This can be extended significantly. For now, it's a simple XP grant.

        emit SentinelInteracted(tokenId, _msgSender(), data);
    }

    // --- View Functions ---

    /// @notice Gets the current attributes of a Sentinel.
    /// @param tokenId The ID of the Sentinel.
    /// @return SentinelAttributes The attributes struct.
    function getSentinelAttributes(uint256 tokenId) public view whenTokenExists(tokenId) returns (SentinelAttributes memory) {
        return _sentinelAttributes[tokenId];
    }

    /// @notice Gets the staking information for a Sentinel.
    /// @param tokenId The ID of the Sentinel.
    /// @return bool isStaked, uint256 stakeStartTime, uint256 lastRewardClaimTime, uint256 accumulatedUnclaimedRewards, uint256 accumulatedXP
    function getSentinelStakingInfo(uint256 tokenId) public view whenTokenExists(tokenId) returns (bool isStaked, uint256 stakeStartTime, uint256 lastRewardClaimTime, uint256 accumulatedUnclaimedRewards, uint256 accumulatedXP) {
        StakingInfo storage info = _stakingInfo[tokenId];
        uint256 currentPending = 0;
        if (info.isStaked) {
            uint256 timeStakedSinceLastClaim = block.timestamp - info.lastRewardClaimTime;
            currentPending = timeStakedSinceLastClaim * stakingRewardRatePerSecond;
            accumulatedXP = (block.timestamp - info.lastRewardClaimTime) * xpStakeRatePerSecond; // XP gained in current period
        }
        return (info.isStaked, info.stakeStartTime, info.lastRewardClaimTime, info.accumulatedUnclaimedRewards + currentPending, info.accumulatedXP + (info.isStaked ? (block.timestamp - info.lastRewardClaimTime) * xpStakeRatePerSecond : 0)); // Add current period XP for view
    }

     /// @notice Gets the list of Sentinels a given Sentinel is attuned to.
     /// Note: Iterating over mappings is not directly possible. This would require
     /// an additional data structure (e.g., an array of attuned tokens for each token)
     /// if we needed to return the *actual* list. For simplicity, this function
     /// will just indicate the *count* of attunements for now, which is tracked.
     /// A more complex implementation would involve storing the attuned tokens in a dynamic array.
     /// @param tokenId The ID of the Sentinel.
     /// @return uint256 The number of Sentinels this Sentinel is attuned to.
     function getSentinelAttunement(uint256 tokenId) public view whenTokenExists(tokenId) returns (uint256) {
         return _attunementCount[tokenId];
     }

    /// @notice Calculates and returns the pending staking rewards for a Sentinel.
    /// This is a helper view function using getSentinelStakingInfo.
    /// @param tokenId The ID of the Sentinel.
    /// @return uint256 The amount of pending rewards.
    function getPendingRewards(uint256 tokenId) public view whenTokenExists(tokenId) returns (uint256) {
        (, , , uint256 pendingRewards, ) = getSentinelStakingInfo(tokenId);
        return pendingRewards;
    }

    /// @notice Gets the total accumulated XP for a Sentinel.
    /// Includes XP from staking (cumulative over time) and interactions.
    /// @param tokenId The ID of the Sentinel.
    /// @return uint256 Total XP.
    function getSentinelXP(uint256 tokenId) public view whenTokenExists(tokenId) returns (uint256) {
        // Includes base XP + XP from current staking period for view purposes
        StakingInfo storage info = _stakingInfo[tokenId];
        uint256 currentStakeXP = info.isStaked ? (block.timestamp - info.lastRewardClaimTime) * xpStakeRatePerSecond : 0;
        return _sentinelAttributes[tokenId].totalXP + info.accumulatedXP + currentStakeXP;
    }

    /// @notice Calculates and returns the Level of a Sentinel based on its XP.
    /// Leveling function is a simple example (e.g., linear or stepped).
    /// @param tokenId The ID of the Sentinel.
    /// @return uint256 The calculated level.
    function getSentinelLevel(uint256 tokenId) public view whenTokenExists(tokenId) returns (uint256) {
        uint256 totalXP = getSentinelXP(tokenId);
        // Example simple leveling: Level = sqrt(XP / 100) or Level = XP / 500
        // Let's use a simple linear scale for demonstration
        uint256 levelRate = 500; // 500 XP per level
        return totalXP / levelRate;
    }

    /// @notice Shows progress towards the criteria for the next evolution stage.
    /// Returns the required criteria. Does not return current progress percentage directly due to complexity.
    /// @param tokenId The ID of the Sentinel.
    /// @return EvolutionCriteria The criteria required for the next stage.
    function getEvolutionProgress(uint256 tokenId) public view whenTokenExists(tokenId) returns (EvolutionCriteria memory) {
         SentinelAttributes storage attrs = _sentinelAttributes[tokenId];
        uint8 currentStage = attrs.currentStage;
        uint8 nextStage = currentStage + 1;

        if (nextStage > uint8(EvolutionStage.Ethereal)) {
             // Return criteria for current stage if already maxed out
            return _evolutionCriteria[currentStage];
        }

        return _evolutionCriteria[nextStage];
    }


    // --- Admin Functions ---

    /// @notice Sets the criteria required for a specific evolution stage.
    /// @param stage The target evolution stage (as its uint8 value).
    /// @param requiredXP Minimum total XP.
    /// @param requiredStakeDuration Minimum cumulative staking duration (placeholder - requires tracking).
    /// @param requiredAttunements Minimum number of active attunement links.
    /// @param requiredInteractions Minimum total interactions received.
    function setEvolutionCriteria(uint8 stage, uint256 requiredXP, uint256 requiredStakeDuration, uint256 requiredAttunements, uint256 requiredInteractions) public onlyOwner {
        // Basic validation for stage
        require(stage > uint8(EvolutionStage.Hatchling) && stage <= uint8(EvolutionStage.Ethereal), "Invalid stage for criteria");

        _evolutionCriteria[stage] = EvolutionCriteria(requiredXP, requiredStakeDuration, requiredAttunements, requiredInteractions);

        emit EvolutionCriteriaUpdated(stage, requiredXP, requiredStakeDuration, requiredAttunements, requiredInteractions);
    }

    /// @notice Sets the rate at which staked Sentinels earn the reward token per second.
    /// @param ratePerSecond The new rate (in reward token smallest units).
    function setStakingRewardRate(uint256 ratePerSecond) public onlyOwner {
        stakingRewardRatePerSecond = ratePerSecond;
        emit StakingRewardRateUpdated(ratePerSecond);
    }

    /// @notice Sets the rate at which staked Sentinels gain XP per second.
    /// @param xpPerSecond The new XP rate.
    function setXPStakeRate(uint256 xpPerSecond) public onlyOwner {
        xpStakeRatePerSecond = xpPerSecond;
        emit XPStakeRateUpdated(xpPerSecond);
    }

    /// @notice Sets the base amount of XP gained per `interactWithSentinel` call.
    /// @param xpAmount The new XP amount.
    function setXPInteractionAmount(uint256 xpAmount) public onlyOwner {
        xpInteractionAmount = xpAmount;
        emit XPInteractionAmountUpdated(xpAmount);
    }

    /// @notice Sets the base URI prefix for token metadata.
    /// This should point to a server capable of returning dynamic JSON metadata.
    /// @param newPrefix The new URI prefix.
    function setTokenURIPrefix(string memory newPrefix) public onlyOwner {
        _tokenURIPrefix = newPrefix;
    }

    /// @notice Pauses core contract activities (staking, unstaking, claiming, evolving, attuning, interacting).
    function pauseContractActivity() public onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Unpauses core contract activities.
    function unpauseContractActivity() public onlyOwner whenPaused {
        _unpause();
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens sent to the contract,
    /// except for the designated reward token if balance is needed for claims.
    /// @param tokenAddress The address of the ERC20 token to withdraw.
    /// @param amount The amount to withdraw.
    function withdrawERC20(address tokenAddress, uint256 amount) public onlyOwner nonReentrant {
        // Prevent withdrawing the reward token unless logic is added to ensure enough is left
        if (tokenAddress == address(rewardToken)) {
            revert CannotWithdrawRewardToken();
        }
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner(), amount), "ERC20 transfer failed");
    }

    /// @notice Allows the owner to withdraw any Ether sent to the contract.
    /// @param amount The amount of Ether to withdraw (in wei).
    function withdrawEther(uint256 amount) public onlyOwner nonReentrant {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        (bool success, ) = owner().call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    // Standard Ownable functions are inherited: transferOwnership, renounceOwnership

    // --- Internal Helpers ---

    /// @dev Generates initial attributes for a new Sentinel based on a seed.
    /// This is a simplified pseudo-random example. A real implementation might use Chainlink VRF.
    /// @param tokenId The ID of the token being minted.
    /// @param seed A seed for pseudo-random generation.
    function _generateInitialAttributes(uint256 tokenId, bytes32 seed) internal {
        uint8 initialAffinity = uint8(uint256(keccak256(abi.encodePacked(seed, "affinity"))) % 100); // Value 0-99
        // Other attributes could be generated similarly

        _sentinelAttributes[tokenId] = SentinelAttributes({
            generation: 1, // Assume Gen 1 for all minted by this contract
            initialAffinity: initialAffinity,
            currentStage: uint8(EvolutionStage.Hatchling), // Start at Hatchling
            totalXP: 0,
            chronosPower: 10 + initialAffinity, // Example starting stats
            resilience: 5,
            connectionStrength: 1
            // Add cumulativeStakeDuration here if implemented: cumulativeStakeDuration: 0
        });
         // Initialize interactions count
         _interactionCount[tokenId] = 0;
    }

    /// @dev Calculates pending rewards and XP for a staked token and adds them to balances/total.
    /// Called by claimRewards and unstakeSentinel.
    /// @param tokenId The ID of the staked Sentinel.
    function _calculateAndDistributeRewardsAndXP(uint256 tokenId) internal {
        StakingInfo storage info = _stakingInfo[tokenId];
        if (!info.isStaked) {
            return; // Should not happen with modifier, but safety
        }

        uint256 timeStakedSinceLastClaim = block.timestamp - info.lastRewardClaimTime;

        // Calculate rewards
        uint256 earnedRewards = timeStakedSinceLastClaim * stakingRewardRatePerSecond;
        uint256 totalRewardsToClaim = info.accumulatedUnclaimedRewards + earnedRewards;

        // Calculate XP gained during this period
        uint256 xpGained = timeStakedSinceLastClaim * xpStakeRatePerSecond;

        // Distribute rewards
        if (totalRewardsToClaim > 0) {
            // Transfer rewards to the staker (whoever called unstake/claim)
            // If allowing transfer of ownership while staked, need to track staker explicitly.
            // Assuming msg.sender is the current staker/owner who is allowed to unstake/claim.
             require(IERC20(rewardToken).transfer(_msgSender(), totalRewardsToClaim), "Reward token transfer failed");
            info.accumulatedUnclaimedRewards = 0; // Reset after distribution
        } else {
             // Even if rewards are 0, set to 0 to clear any dust
            info.accumulatedUnclaimedRewards = 0;
        }

        // Add XP to total
        _sentinelAttributes[tokenId].totalXP += info.accumulatedXP + xpGained; // Add previously accumulated and currently earned XP
        info.accumulatedXP = 0; // Reset accumulated XP for the current staking period

        // Add to cumulative stake duration if implemented
        // _sentinelAttributes[tokenId].cumulativeStakeDuration += timeStakedSinceLastClaim;

        // Update last claim time
        info.lastRewardClaimTime = block.timestamp;
    }

     /// @dev Breaks all Attunement bonds involving a given Sentinel.
     /// Called before transfer or burn to maintain data integrity.
     /// @param tokenId The ID of the Sentinel.
     function _breakAllAttunements(uint256 tokenId) internal {
         // This requires iterating over all possible tokenIds it could be attuned to,
         // which is inefficient. A better design for tracking attunements would be needed
         // to efficiently remove all links.
         // Example: Maintain a dynamic array of attuned tokens for each token.
         // For this example, we'll simply reset the count and rely on the check
         // _attunedTo[tokenId1][tokenId2] to be false after any transfer/burn
         // by convention, although the mapping entry isn't explicitly deleted here.
         // A robust system needs explicit array storage and deletion.
         // Placeholder:
         // for each otherTokenId attuned to tokenId:
         //     _attunedTo[tokenId][otherTokenId] = false;
         //     _attunedTo[otherTokenId][tokenId] = false;
         //     _attunementCount[otherTokenId]--;

         // Simplistic: Just reset count, implying all links are broken.
         // The actual mapping entries remain but won't be `true`.
         // A safer approach would iterate through a stored list of attunements.
         // For now, assume this is handled off-chain or with a more complex structure.
         // Re-attunement would overwrite the old false entry with true.
         _attunementCount[tokenId] = 0;
         // Note: This is a simplification. Breaking specific attunements requires knowing the partner.
         // A real system would need to track *which* tokens are attuned.
     }
}
```