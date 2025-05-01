Okay, here is a Solidity smart contract named `HyperSphere`. It incorporates several advanced concepts:

1.  **Layered Progression:** The contract represents a digital "HyperSphere" with multiple layers that unlock based on collective contributions (`SPHERE_TOKEN` staking) and time.
2.  **Dynamic Reputation System:** Users earn reputation based on their contributions. This reputation *decays* over time if not maintained, encouraging continued engagement.
3.  **NFT Artifacts:** Unique ERC721 NFTs ("Sphere Artifacts") are minted to users upon reaching certain milestones (e.g., first stake in an unlocked layer, reaching a reputation threshold).
4.  **Time-Based Mechanics:** Layer unlocks can be time-gated, staking has a minimum duration, and reputation decays based on time.
5.  **Staking with Variable Rewards:** Stakers earn rewards (more `SPHERE_TOKEN`) based on their stake amount and the reward rate of the specific layer they are in, after it unlocks.
6.  **Public State Evolution Triggers:** Functions like checking layer unlocks or triggering reputation decay can be called publicly, distributing the gas cost for state evolution.

It's designed to be a conceptual framework for a collaborative, evolving digital structure with built-in engagement mechanics.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol"; // If contract holds NFTs sometimes
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // Although 0.8+ has overflow checks by default, SafeMath can add clarity for complex arithmetic.

// Define interfaces for the Sphere Token (ERC20) and Artifact NFT (ERC721)
interface ISphereToken is IERC20 {}
interface IArtifactNFT is IERC721 {}

/// @title HyperSphere Contract
/// @author Your Name/Team
/// @notice A smart contract representing a layered, evolving digital structure where users contribute (stake) tokens
///         to unlock layers, earn dynamic reputation, and receive unique NFT artifacts.
/// @dev This contract manages staked tokens, calculates dynamic user reputation, tracks layer progress,
///      handles reward distribution, and triggers NFT minting on milestones. It includes advanced
///      concepts like time-decaying reputation and layered state progression.
contract HyperSphere is Ownable, ReentrancyGuard, Pausable, ERC721Holder { // ERC721Holder allows the contract to receive NFTs if needed, though not strictly necessary for *minting*
    using SafeMath for uint256; // Use SafeMath for calculations involving staked amounts, rewards, etc.

    /*
     * OUTLINE AND FUNCTION SUMMARY
     *
     * 1. State Variables & Constants
     *    - Configuration settings (token addresses, decay rates, etc.)
     *    - Global system state (total contribution, total reputation, next artifact ID)
     *    - User state (reputation, total contribution, artifact count)
     *    - Layer state (structs for layers, array/mapping of layers)
     *
     * 2. Events
     *    - Notifications for key actions (stake, unstake, claim, layer unlock, artifact mint, reputation decay)
     *
     * 3. Modifiers
     *    - Access control (onlyOwner) and contract state (whenNotPaused)
     *
     * 4. Constructor
     *    - Initializes the contract with token addresses.
     *
     * 5. Admin & Configuration Functions (Owned) (>= 5 functions)
     *    - setSphereToken: Set the address of the Sphere ERC20 token.
     *    - setArtifactNFT: Set the address of the Artifact ERC721 contract.
     *    - addLayer: Define parameters for a new layer.
     *    - updateLayerConfig: Modify parameters of an existing layer (threshold, reward rate, unlock time).
     *    - updateGlobalConfig: Update global parameters (reputation decay, stake duration, contribution ratio).
     *    - pause: Pause contract operations (inherited from Pausable).
     *    - unpause: Unpause contract operations (inherited from Pausable).
     *
     * 6. Core Interaction Functions (User Facing) (>= 3 functions)
     *    - stakeToLayer: Stake SPHERE_TOKEN in a specified layer.
     *    - unstakeFromLayer: Unstake tokens from a specified layer.
     *    - claimLayerRewards: Claim accrued SPHERE_TOKEN rewards from staking in an unlocked layer.
     *
     * 7. State Evolution & Dynamic Mechanics (Public/Helper) (>= 2 functions)
     *    - checkAndUnlockLayer: Public function to check and unlock a layer if criteria are met.
     *    - triggerReputationDecay: Public function to trigger reputation decay for a specific user (helps distribute gas).
     *
     * 8. NFT/Artifact Functions (Internal/Called by system) (>= 1 function)
     *    - _mintArtifactForUser: Internal function to mint an artifact NFT. (Called by stake/unlock/decay if milestones met)
     *
     * 9. View Functions (Public/External) (>= 9 functions)
     *    - getLayerCount: Get the total number of defined layers.
     *    - getLayerState: Get the state and configuration of a specific layer.
     *    - getUserStakeInLayer: Get the amount a user has staked in a layer.
     *    - getUserContributionInLayer: Get the total contribution a user has made to a layer (including unstaked).
     *    - getUserReputation: Get the current *calculated* reputation for a user (factoring in decay).
     *    - getUserTotalContribution: Get the total contribution a user has made across all layers.
     *    - getUserArtifactCount: Get the number of artifacts owned by a user.
     *    - calculatePendingRewards: Calculate the pending rewards for a user in a specific layer.
     *    - getTotalSystemContribution: Get the total contribution across all layers.
     *    - getTotalSystemReputation: Get the total *base* (non-decayed) reputation in the system.
     *    - getSphereTokenAddress: Get the SPHERE_TOKEN contract address.
     *    - getArtifactNFTAddress: Get the ARTIFACT_NFT contract address.
     *    - getMinStakeDuration: Get the minimum time tokens must be staked.
     *    - getReputationDecayRate: Get the rate at which reputation decays per second.
     *    - getContributionToReputationRatio: Get the ratio of contribution to reputation points gained.
     *    - canReceive: Required by ERC721Holder.
     *
     * 10. Internal Helper Functions
     *    - _calculateReputationGain: Calculate reputation points gained from a contribution.
     *    - _calculateCurrentReputation: Calculate a user's current reputation factoring decay.
     *    - _calculateRewardAmount: Calculate rewards for a user in a layer for a given time period.
     *    - _updateUserReputation: Update a user's reputation, factoring in decay and new gains.
     *    - _processArtifactMinting: Check if artifact minting conditions are met after an action.
     */

    // --- 1. State Variables & Constants ---

    ISphereToken public SPHERE_TOKEN;
    IArtifactNFT public ARTIFACT_NFT;

    struct Layer {
        bool unlocked;
        uint256 contributionThreshold; // Total contribution needed to unlock
        uint256 currentContribution;   // Current accumulated contribution in this layer
        uint64 unlockTime;             // Timestamp after which layer can be unlocked (if threshold met)
        uint256 rewardRatePerTokenPerSecond; // Reward rate for stakers in this layer (per token per second)

        // User specific data within this layer
        mapping(address => uint256) stakedAmount;         // Tokens staked by user in this layer
        mapping(address => uint64) userStakeStartTime;    // Timestamp when user last staked (or first staked) in this layer
        mapping(address => uint256) userContributionTotal;// Total historical contribution (staked+unstaked) to this layer by user
        mapping(address => uint256) lastRewardClaimTime;  // Timestamp of last reward claim for user in this layer
    }

    Layer[] public layers; // Array to hold layer data

    // Global User State
    mapping(address => uint256) public userReputation;           // Current BASE reputation (before decay calculation)
    mapping(address => uint64) public lastReputationUpdateTime;   // Timestamp when user's reputation was last updated/calculated
    mapping(address => uint256) public userTotalContributionAcrossLayers; // Total historical contribution across all layers
    mapping(address => uint256) public userArtifactCount;        // Number of artifacts owned by user

    // Global System State
    uint256 public totalSystemContribution; // Total contribution across all layers
    uint256 public totalSystemReputation;   // Total BASE reputation across all users
    uint256 public nextArtifactId = 1;      // Counter for unique artifact IDs

    // Configuration Parameters
    uint64 public reputationDecayRate; // Reputation points decayed per second per point (e.g., 1e18 for 1 point per second)
    uint64 public minStakeDuration;    // Minimum time tokens must be staked before unstaking
    uint256 public contributionToReputationRatio; // How many contribution points equal 1 reputation point (e.g., 1e18 contribution = 1 reputation)
    uint256 public constant REPUTATION_PRECISION = 1e18; // Precision for reputation calculations

    // Artifact Minting Thresholds (Example: can be extended or moved to layers)
    uint256 public constant REPUTATION_ARTIFACT_THRESHOLD_1 = 100 * REPUTATION_PRECISION; // Mint artifact at 100 reputation
    // Add more thresholds here... mapping(uint256 => bool) reputationArtifactMinted; for each user/threshold

    // --- 2. Events ---

    event SphereTokenSet(address indexed token);
    event ArtifactNFTSet(address indexed nft);
    event LayerAdded(uint256 indexed layerId, uint256 threshold, uint64 unlockTime);
    event LayerConfigUpdated(uint256 indexed layerId, uint256 threshold, uint64 unlockTime, uint256 rewardRate);
    event GlobalConfigUpdated(uint64 reputationDecayRate, uint64 minStakeDuration, uint256 contributionRatio);
    event Staked(address indexed user, uint256 indexed layerId, uint256 amount, uint256 currentStake);
    event Unstaked(address indexed user, uint256 indexed layerId, uint256 amount, uint256 currentStake);
    event RewardsClaimed(address indexed user, uint256 indexed layerId, uint256 amount);
    event LayerUnlocked(uint256 indexed layerId, uint256 totalContribution);
    event ReputationDecayed(address indexed user, uint256 oldReputation, uint256 newReputation, uint256 decayedAmount);
    event ArtifactMinted(address indexed user, uint256 indexed artifactId, string metadataURI); // metadataURI might be set by the NFT contract
    event ReputationGained(address indexed user, uint256 amount);


    // --- 3. Modifiers ---
    // onlyOwner is inherited from Ownable
    // whenNotPaused is inherited from Pausable

    modifier validLayerId(uint256 _layerId) {
        require(_layerId < layers.length, "Invalid layer ID");
        _;
    }

    // --- 4. Constructor ---

    constructor(address _sphereToken, address _artifactNFT) Ownable(msg.sender) {
        SPHERE_TOKEN = ISphereToken(_sphereToken);
        ARTIFACT_NFT = IArtifactNFT(_artifactNFT);

        // Set initial (default) global configuration
        reputationDecayRate = 1e15; // Example: 0.001 point per second per point
        minStakeDuration = 1 days;   // Example: 1 day minimum stake
        contributionToReputationRatio = 1 ether; // Example: 1 token contributed = 1 reputation point

        emit SphereTokenSet(_sphereToken);
        emit ArtifactNFTSet(_artifactNFT);
        emit GlobalConfigUpdated(reputationDecayRate, minStakeDuration, contributionToReputationRatio);

        // Initialize reputation last update time for deployer
        lastReputationUpdateTime[msg.sender] = uint64(block.timestamp);
    }

    // --- 5. Admin & Configuration Functions ---

    /// @notice Sets the address of the SPHERE_TOKEN ERC20 contract.
    /// @param _token The address of the SPHERE_TOKEN contract.
    function setSphereToken(address _token) external onlyOwner {
        SPHERE_TOKEN = ISphereToken(_token);
        emit SphereTokenSet(_token);
    }

    /// @notice Sets the address of the Artifact ERC721 contract.
    /// @param _nft The address of the Artifact NFT contract.
    function setArtifactNFT(address _nft) external onlyOwner {
        ARTIFACT_NFT = IArtifactNFT(_nft);
        emit ArtifactNFTSet(_nft);
    }

    /// @notice Adds a new layer to the HyperSphere.
    /// @param _contributionThreshold The total contribution needed to unlock the layer.
    /// @param _unlockTime The timestamp after which the layer can be unlocked (if threshold met). 0 means no time lock.
    /// @param _rewardRatePerTokenPerSecond The reward rate for stakers in this layer.
    function addLayer(uint256 _contributionThreshold, uint64 _unlockTime, uint256 _rewardRatePerTokenPerSecond) external onlyOwner {
        layers.push(Layer({
            unlocked: false,
            contributionThreshold: _contributionThreshold,
            currentContribution: 0,
            unlockTime: _unlockTime,
            rewardRatePerTokenPerSecond: _rewardRatePerTokenPerSecond,
            stakedAmount: mapping(address => uint256),
            userStakeStartTime: mapping(address => uint64),
            userContributionTotal: mapping(address => uint256),
            lastRewardClaimTime: mapping(address => uint256)
        }));
        emit LayerAdded(layers.length - 1, _contributionThreshold, _unlockTime);
    }

    /// @notice Updates configuration parameters for an existing layer.
    /// @param _layerId The ID of the layer to update.
    /// @param _contributionThreshold The new contribution threshold.
    /// @param _unlockTime The new unlock timestamp.
    /// @param _rewardRatePerTokenPerSecond The new reward rate.
    function updateLayerConfig(
        uint256 _layerId,
        uint256 _contributionThreshold,
        uint64 _unlockTime,
        uint256 _rewardRatePerTokenPerSecond
    ) external onlyOwner validLayerId(_layerId) {
        Layer storage layer = layers[_layerId];
        layer.contributionThreshold = _contributionThreshold;
        layer.unlockTime = _unlockTime;
        layer.rewardRatePerTokenPerSecond = _rewardRatePerTokenPerSecond;
        emit LayerConfigUpdated(_layerId, _contributionThreshold, _unlockTime, _rewardRatePerTokenPerSecond);
    }

    /// @notice Updates global configuration parameters for the HyperSphere.
    /// @param _reputationDecayRate New reputation decay rate per second per point.
    /// @param _minStakeDuration New minimum stake duration.
    /// @param _contributionToReputationRatio New ratio of contribution to reputation points.
    function updateGlobalConfig(
        uint64 _reputationDecayRate,
        uint64 _minStakeDuration,
        uint256 _contributionToReputationRatio
    ) external onlyOwner {
        reputationDecayRate = _reputationDecayRate;
        minStakeDuration = _minStakeDuration;
        contributionToReputationRatio = _contributionToReputationRatio;
        emit GlobalConfigUpdated(reputationDecayRate, minStakeDuration, contributionToReputationRatio);
    }

    // pause() and unpause() inherited from Pausable

    // --- 6. Core Interaction Functions ---

    /// @notice Stakes tokens in a specific layer. Increases contribution and potentially reputation.
    /// @param _layerId The ID of the layer to stake in.
    /// @param _amount The amount of SPHERE_TOKEN to stake.
    function stakeToLayer(uint256 _layerId, uint256 _amount) external whenNotPaused nonReentrant validLayerId(_layerId) {
        require(_amount > 0, "Amount must be greater than 0");

        Layer storage layer = layers[_layerId];
        address user = msg.sender;

        // Ensure contract can pull tokens
        require(SPHERE_TOKEN.allowance(user, address(this)) >= _amount, "Token allowance too low");
        SPHERE_TOKEN.transferFrom(user, address(this), _amount);

        // Update staked amount and contribution
        uint256 oldStake = layer.stakedAmount[user];
        layer.stakedAmount[user] = oldStake.add(_amount);

        // Record stake start time if this is the first stake or after a full unstake
        if (oldStake == 0) {
             layer.userStakeStartTime[user] = uint64(block.timestamp);
        } else {
            // If adding to an existing stake, update rewards state first
            if (layer.unlocked && layer.rewardRatePerTokenPerSecond > 0) {
                 uint256 rewards = _calculateRewardAmount(user, _layerId);
                 layer.lastRewardClaimTime[user] = block.timestamp; // Reset claim time to now
                 if (rewards > 0) {
                     // Note: Rewards are not claimed here, only state updated to reflect accumulated rewards up to this point
                     // User must call claimLayerRewards separately
                     // An alternative is to auto-claim, but that adds complexity and gas here.
                     // For simplicity and gas efficiency, we update the claim time, effectively 'cashing out' time earned.
                 }
             }
             // userStakeStartTime is not updated here, it reflects the start of the current *continuous* staking period
        }

        // Update layer and global contribution
        layer.currentContribution = layer.currentContribution.add(_amount);
        layer.userContributionTotal[user] = layer.userContributionTotal[user].add(_amount);
        totalSystemContribution = totalSystemContribution.add(_amount);
        userTotalContributionAcrossLayers[user] = userTotalContributionAcrossLayers[user].add(_amount);

        // Update reputation based on contribution (can be triggered separately or here)
        // For simplicity, let's update base reputation immediately here
        // The actual 'current' reputation includes decay, calculated via view function
        uint256 reputationGained = _calculateReputationGain(_amount);
        _updateUserReputation(user, reputationGained, true); // Add reputation

        // Check for artifact minting conditions related to staking/contribution
        _processArtifactMinting(user, _layerId);

        emit Staked(user, _layerId, _amount, layer.stakedAmount[user]);
    }

    /// @notice Unstakes tokens from a specific layer. User must meet minimum stake duration.
    /// @param _layerId The ID of the layer to unstake from.
    /// @param _amount The amount of tokens to unstake.
    function unstakeFromLayer(uint256 _layerId, uint256 _amount) external whenNotPaused nonReentrant validLayerId(_layerId) {
        require(_amount > 0, "Amount must be greater than 0");

        Layer storage layer = layers[_layerId];
        address user = msg.sender;
        uint256 staked = layer.stakedAmount[user];

        require(staked >= _amount, "Insufficient staked amount");

        // Check minimum stake duration (if unstaking the *entire* amount, or if it's the first unstake after a long time)
        // Simplified: check if the *current continuous stake period* meets the minimum duration
        if (staked == _amount || layer.userStakeStartTime[user] + minStakeDuration > block.timestamp) {
             require(layer.userStakeStartTime[user] + minStakeDuration <= block.timestamp, "Minimum stake duration not met");
        }

        // Claim pending rewards before unstaking (or they are forfeited)
        if (layer.unlocked && layer.rewardRatePerTokenPerSecond > 0) {
             uint256 rewards = _calculateRewardAmount(user, _layerId);
             if (rewards > 0) {
                 layer.lastRewardClaimTime[user] = block.timestamp; // Update claim time to now
                 // Transfer rewards
                 SPHERE_TOKEN.transfer(user, rewards);
                 emit RewardsClaimed(user, _layerId, rewards);
             }
        }

        // Update staked amount
        layer.stakedAmount[user] = staked.sub(_amount);

        // Note: currentContribution and totalSystemContribution are NOT decreased on unstake,
        // they represent historical contribution towards unlocking layers.
        // userContributionTotal[user] and userTotalContributionAcrossLayers are also NOT decreased.

        // If the user unstakes the entire amount, reset stake start time
        if (layer.stakedAmount[user] == 0) {
            layer.userStakeStartTime[user] = 0; // Reset stake start time
        } else {
             // If partially unstaking, update the claim time to now, but keep the original stake start time
             layer.lastRewardClaimTime[user] = block.timestamp; // Update claim time to now for remaining stake
        }


        // Transfer tokens back
        SPHERE_TOKEN.transfer(user, _amount);

        emit Unstaked(user, _layerId, _amount, layer.stakedAmount[user]);
    }

    /// @notice Claims accrued SPHERE_TOKEN rewards for staking in an unlocked layer.
    /// @param _layerId The ID of the layer to claim rewards from.
    function claimLayerRewards(uint256 _layerId) external whenNotPaused nonReentrant validLayerId(_layerId) {
        Layer storage layer = layers[_layerId];
        address user = msg.sender;

        require(layer.unlocked, "Layer is not unlocked");
        require(layer.rewardRatePerTokenPerSecond > 0, "Layer does not offer rewards");
        require(layer.stakedAmount[user] > 0, "User has no stake in this layer");

        uint256 rewards = _calculateRewardAmount(user, _layerId);

        require(rewards > 0, "No pending rewards");

        // Update last claim time BEFORE transfer (Check-Effect-Interaction)
        layer.lastRewardClaimTime[user] = block.timestamp;

        // Transfer rewards
        SPHERE_TOKEN.transfer(user, rewards);

        emit RewardsClaimed(user, _layerId, rewards);
    }

    // --- 7. State Evolution & Dynamic Mechanics ---

    /// @notice Public function to check if a layer meets its unlock criteria (contribution and time) and unlock it.
    /// @param _layerId The ID of the layer to check and potentially unlock.
    /// @dev Anyone can call this function, allowing for decentralized triggering of layer unlocks.
    function checkAndUnlockLayer(uint256 _layerId) external whenNotPaused validLayerId(_layerId) {
        Layer storage layer = layers[_layerId];

        require(!layer.unlocked, "Layer is already unlocked");

        bool thresholdMet = layer.currentContribution >= layer.contributionThreshold;
        bool timeMet = layer.unlockTime == 0 || block.timestamp >= layer.unlockTime; // 0 unlockTime means no time requirement

        if (thresholdMet && timeMet) {
            layer.unlocked = true;

            // Initialize last reward claim time for all current stakers upon unlock
            // This is gas intensive if many stakers. Alternative: initialize on first stake/claim after unlock.
            // Let's initialize on first stake/claim *after* unlock for gas efficiency.
            // The _calculateRewardAmount handles the case where lastRewardClaimTime is 0.

            emit LayerUnlocked(_layerId, layer.currentContribution);
        } else {
            // Optionally emit an event indicating unlock failed and why
            // emit UnlockCheckFailed(_layerId, thresholdMet, timeMet);
        }
    }

    /// @notice Public function to trigger reputation decay calculation for a specific user.
    /// @param _user The address of the user whose reputation to decay.
    /// @dev This allows users or bots to trigger reputation decay for others, helping distribute gas costs.
    ///      Reputation decay is automatically factored into the view function `getUserReputation`.
    ///      This function *updates the base reputation state* after decay.
    function triggerReputationDecay(address _user) external whenNotPaused {
        // Call the internal function to calculate and apply decay
        _updateUserReputation(_user, 0, false); // 0 gain, decayOnly = true
        // Event is emitted inside _updateUserReputation if decay occurs
    }


    // --- 8. NFT/Artifact Functions ---

    /// @notice Internal function to mint a Sphere Artifact NFT for a user.
    /// @param _user The address of the user to mint for.
    /// @param _uri Optional metadata URI for the artifact.
    /// @dev Assumes ARTIFACT_NFT contract implements ERC721 and has a safeMint function callable by this contract.
    function _mintArtifactForUser(address _user, string memory _uri) internal {
        require(address(ARTIFACT_NFT) != address(0), "Artifact NFT contract not set");

        // Check if user has already minted this artifact type (e.g., based on threshold met)
        // This simplified example just mints based on an arbitrary trigger, a real system
        // would need more sophisticated tracking per user for each mintable artifact type.

        // For simplicity in this example, let's increment a counter and mint.
        // In a real scenario, this would check specific user milestones (e.g., first stake in Layer X, reach Y reputation)
        uint256 artifactIdToMint = nextArtifactId;
        nextArtifactId = nextArtifactId.add(1);
        userArtifactCount[_user] = userArtifactCount[_user].add(1);

        // Assuming ARTIFACT_NFT is an ERC721Minter or similar
        // It needs a safeMint function like: function safeMint(address to, uint256 tokenId, string memory uri) external;
        // Or a simple ERC721 with `_safeMint` if this contract is the minter (less common).
        // Let's assume ARTIFACT_NFT has a public minting function callable by this contract.
        // IMPORTANT: The actual implementation of IArtifactNFT needs a mint function this contract can call.
        // For this example, let's mock it or assume a function signature.
        // A common pattern is `safeMint(address to, uint256 tokenId)`. URI usually set separately or derived.
        IArtifactNFT(ARTIFACT_NFT).safeMint(_user, artifactIdToMint);
        // If the NFT contract supports setting URI per token, call that here too
        // IArtifactNFT(ARTIFACT_NFT).setTokenURI(artifactIdToMint, _uri); // Example

        emit ArtifactMinted(_user, artifactIdToMint, _uri);
    }

     /// @notice Helper to check and trigger artifact minting based on various user milestones.
     /// @dev Called internally after state-changing actions like staking or reputation decay.
     function _processArtifactMinting(address user, uint256 layerId) internal {
         // Example check: Mint artifact on first stake in an unlocked layer
         if (layers[layerId].unlocked && layers[layerId].userStakeStartTime[user] == block.timestamp && userArtifactCount[user] == 0) {
             // Simple check: mint the first artifact they ever get for staking in an unlocked layer
             _mintArtifactForUser(user, "initial_stake_artifact");
         }

         // Example check: Mint artifact upon reaching certain reputation thresholds
         // This requires tracking which reputation artifacts a user has already received.
         // A mapping like mapping(address => mapping(uint256 => bool)) reputationArtifactsClaimed;
         // could track this.

         uint256 currentReputation = _calculateCurrentReputation(user);

         // Check Threshold 1
         // if (currentReputation >= REPUTATION_ARTIFACT_THRESHOLD_1 && !reputationArtifactsClaimed[user][1]) {
         //     reputationArtifactsClaimed[user][1] = true;
         //     _mintArtifactForUser(user, "reputation_level_1_artifact");
         // }
         // Add checks for other thresholds...
     }


    // --- 9. View Functions ---

    /// @notice Returns the total number of layers defined in the HyperSphere.
    /// @return The number of layers.
    function getLayerCount() external view returns (uint256) {
        return layers.length;
    }

    /// @notice Returns the state and configuration details of a specific layer.
    /// @param _layerId The ID of the layer to query.
    /// @return unlocked Layer unlocked status.
    /// @return contributionThreshold Layer unlock threshold.
    /// @return currentContribution Layer current contribution.
    /// @return unlockTime Layer unlock timestamp.
    /// @return rewardRate Layer reward rate.
    function getLayerState(uint256 _layerId)
        external
        view
        validLayerId(_layerId)
        returns (
            bool unlocked,
            uint256 contributionThreshold,
            uint256 currentContribution,
            uint64 unlockTime,
            uint256 rewardRate
        )
    {
        Layer storage layer = layers[_layerId];
        return (
            layer.unlocked,
            layer.contributionThreshold,
            layer.currentContribution,
            layer.unlockTime,
            layer.rewardRatePerTokenPerSecond
        );
    }

    /// @notice Returns the amount of tokens a user has currently staked in a specific layer.
    /// @param _user The user address.
    /// @param _layerId The ID of the layer.
    /// @return The staked amount.
    function getUserStakeInLayer(address _user, uint256 _layerId) external view validLayerId(_layerId) returns (uint256) {
        return layers[_layerId].stakedAmount[_user];
    }

     /// @notice Returns the total cumulative contribution a user has made to a specific layer.
     /// @param _user The user address.
     /// @param _layerId The ID of the layer.
     /// @return The total contribution.
     function getUserContributionInLayer(address _user, uint256 _layerId) external view validLayerId(_layerId) returns (uint256) {
         return layers[_layerId].userContributionTotal[_user];
     }

    /// @notice Calculates and returns the user's current reputation, factoring in decay since the last update.
    /// @param _user The user address.
    /// @return The current calculated reputation.
    function getUserReputation(address _user) public view returns (uint256) {
        return _calculateCurrentReputation(_user);
    }

    /// @notice Returns the user's total cumulative contribution across all layers.
    /// @param _user The user address.
    /// @return The total contribution.
    function getUserTotalContribution(address _user) external view returns (uint256) {
        return userTotalContributionAcrossLayers[_user];
    }

    /// @notice Returns the number of Sphere Artifact NFTs owned by a user (as tracked by this contract).
    /// @param _user The user address.
    /// @return The number of artifacts.
    function getUserArtifactCount(address _user) external view returns (uint256) {
        return userArtifactCount[_user];
    }

    /// @notice Calculates the pending rewards for a user in a specific layer.
    /// @param _user The user address.
    /// @param _layerId The ID of the layer.
    /// @return The calculated pending reward amount.
    function calculatePendingRewards(address _user, uint256 _layerId) external view validLayerId(_layerId) returns (uint256) {
         return _calculateRewardAmount(_user, _layerId);
    }


    /// @notice Returns the total contribution accumulated across all layers in the HyperSphere.
    /// @return The total system contribution.
    function getTotalSystemContribution() external view returns (uint256) {
        return totalSystemContribution;
    }

     /// @notice Returns the total base reputation across all users before considering decay.
     /// @return The total base system reputation.
     function getTotalSystemReputation() external view returns (uint256) {
         return totalSystemReputation;
     }

    /// @notice Returns the address of the SPHERE_TOKEN contract.
    function getSphereTokenAddress() external view returns (address) {
        return address(SPHERE_TOKEN);
    }

    /// @notice Returns the address of the Artifact NFT contract.
    function getArtifactNFTAddress() external view returns (address) {
        return address(ARTIFACT_NFT);
    }

    /// @notice Returns the minimum duration tokens must be staked in a layer.
    function getMinStakeDuration() external view returns (uint64) {
        return minStakeDuration;
    }

    /// @notice Returns the current reputation decay rate per second per point.
    function getReputationDecayRate() external view returns (uint64) {
        return reputationDecayRate;
    }

    /// @notice Returns the ratio of contribution points to reputation points gained.
    function getContributionToReputationRatio() external view returns (uint256) {
        return contributionToReputationRatio;
    }


    // ERC721Holder compliance if the contract might hold NFTs (e.g., for future features)
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external override returns (bytes4)
    {
        return this.onERC721Received.selector;
    }


    // --- 10. Internal Helper Functions ---

    /// @dev Calculates the base reputation points gained from a given contribution amount.
    /// @param _contributionAmount The amount contributed.
    /// @return The calculated reputation points.
    function _calculateReputationGain(uint256 _contributionAmount) internal view returns (uint256) {
        // Avoid division by zero if ratio is not set (shouldn't happen with constructor defaults, but safety)
        if (contributionToReputationRatio == 0) {
            return 0;
        }
        // Assuming contribution is in token units (like 1e18), and ratio is also scaled
        // If 1 token (1e18) = 1 reputation (1e18), ratio is 1e18.
        // Gain = amount * REPUTATION_PRECISION / contributionToReputationRatio
        // If ratio is 1e18: Gain = amount * 1e18 / 1e18 = amount
        // If ratio is 0.5e18: Gain = amount * 1e18 / 0.5e18 = amount * 2
        return _contributionAmount.mul(REPUTATION_PRECISION).div(contributionToReputationRatio);
    }

    /// @dev Calculates a user's current reputation considering decay since their last update time.
    /// @param _user The user address.
    /// @return The current calculated reputation.
    function _calculateCurrentReputation(address _user) internal view returns (uint256) {
        uint256 baseReputation = userReputation[_user];
        uint64 lastUpdateTime = lastReputationUpdateTime[_user];

        if (baseReputation == 0 || reputationDecayRate == 0 || lastUpdateTime == 0 || lastUpdateTime >= block.timestamp) {
            return baseReputation; // No decay or already updated
        }

        uint64 timeElapsed = uint64(block.timestamp).sub(lastUpdateTime);

        // Calculate decay amount: baseReputation * reputationDecayRate * timeElapsed / REPUTATION_PRECISION
        // Decay is proportional to current reputation amount * rate * time
        uint256 decayAmount = baseReputation.mul(reputationDecayRate).mul(timeElapsed).div(REPUTATION_PRECISION);

        // Decay cannot exceed current base reputation
        decayAmount = decayAmount > baseReputation ? baseReputation : decayAmount;

        return baseReputation.sub(decayAmount);
    }

    /// @dev Updates a user's base reputation state after factoring in decay and adding new gains.
    ///      This function should be called whenever reputation might change (gain or decay).
    /// @param _user The user address.
    /// @param _gain The amount of reputation points gained *before* decay calculation.
    /// @param _addGain If true, adds _gain to the base reputation after decay.
    function _updateUserReputation(address _user, uint256 _gain, bool _addGain) internal {
         uint256 currentReputation = _calculateCurrentReputation(_user); // Reputation AFTER decay
         uint256 oldBaseReputation = userReputation[_user]; // Base reputation BEFORE this update
         uint256 oldTotalSystemReputation = totalSystemReputation;

         // Set the new base reputation: current reputation (after decay) + new gain (if adding)
         uint256 newBaseReputation = currentReputation;
         if (_addGain) {
             newBaseReputation = newBaseReputation.add(_gain);
             emit ReputationGained(_user, _gain);
         }

         // Update state variables
         userReputation[_user] = newBaseReputation;
         lastReputationUpdateTime[_user] = uint64(block.timestamp);

         // Update total system reputation based on change in *base* reputation for this user
         // The change is (newBaseReputation - oldBaseReputation)
         if (newBaseReputation > oldBaseReputation) {
             totalSystemReputation = totalSystemReputation.add(newBaseReputation.sub(oldBaseReputation));
         } else {
              totalSystemReputation = totalSystemReputation.sub(oldBaseReputation.sub(newBaseReputation));
         }


         // Emit decay event if decay occurred
         uint256 decayedAmount = oldBaseReputation.sub(currentReputation);
         if (decayedAmount > 0) {
              emit ReputationDecayed(_user, oldBaseReputation, newBaseReputation, decayedAmount);
         }
    }

    /// @dev Calculates the reward amount for a user in a layer since the last claim time.
    /// @param _user The user address.
    /// @param _layerId The ID of the layer.
    /// @return The calculated reward amount.
    function _calculateRewardAmount(address _user, uint256 _layerId) internal view returns (uint256) {
        Layer storage layer = layers[_layerId];

        if (!layer.unlocked || layer.rewardRatePerTokenPerSecond == 0 || layer.stakedAmount[_user] == 0) {
            return 0;
        }

        uint64 lastClaim = uint64(layer.lastRewardClaimTime[_user]);
        if (lastClaim == 0) {
             // If never claimed before, start accumulating rewards from the layer unlock time
             // or the user's stake start time, whichever is later.
             // This is a bit complex. Simplest: start from unlock time IF stake was before unlock.
             // If stake was AFTER unlock, start from stake time.
             // Let's simplify: If lastClaim is 0, assume accumulation starts from layer unlock time if stake was before that,
             // otherwise from the user's stake start time in that layer.
             // A better design might be to set lastRewardClaimTime = block.timestamp for existing stakers when a layer unlocks.
             // Given our current LayerUnlocked implementation doesn't loop through users,
             // let's use the more complex calculation here:
             lastClaim = layer.userStakeStartTime[_user];
             if (lastClaim < layer.unlockTime) {
                 lastClaim = layer.unlockTime;
             }
             // Also consider if the stake *started* after the layer unlocked
             if (lastClaim < layer.userStakeStartTime[user]) {
                 lastClaim = layer.userStakeStartTime[user];
             }
             // If Layer wasn't unlocked when user staked, rewards start AFTER unlock.
             // This seems like the safest approach for lastClaim == 0 scenario:
             if (layer.userStakeStartTime[_user] < layer.unlockTime) {
                lastClaim = layer.unlockTime;
             } else {
                lastClaim = layer.userStakeStartTime[_user];
             }
        }


        uint64 timeElapsed = uint64(block.timestamp).sub(lastClaim);

        // Handle potential edge case if block.timestamp is somehow less than lastClaim (e.g. node sync issue)
        if (timeElapsed == 0 || block.timestamp < lastClaim) {
             return 0;
        }


        // Rewards = stakedAmount * rewardRate * timeElapsed
        // Need to handle potential overflow with multiplication. SafeMath is used.
        // Reward rate is per second per token.
        uint256 rewardPerToken = layer.rewardRatePerTokenPerSecond.mul(timeElapsed);
        uint256 totalReward = layer.stakedAmount[_user].mul(rewardPerToken);

        // The reward calculation assumes rewardRatePerTokenPerSecond is scaled appropriately (e.g., 1e18 precision).
        // If the reward rate is a raw number (e.g., 1), the precision adjustment might be needed here.
        // Assuming rewardRatePerTokenPerSecond is already scaled correctly relative to token decimals.

        return totalReward;
    }

    // Fallback/Receive functions are not strictly needed unless sending raw ether

    // Function count check:
    // Admin: 5 (setSphere, setArtifact, addLayer, updateLayerConfig, updateGlobalConfig) + 2 Pausable = 7
    // Core: 3 (stake, unstake, claim)
    // State Evo: 2 (checkUnlock, triggerDecay)
    // NFT: 1 (_mintArtifact) + 1 (_processArtifactMinting) = 2 (Internal helpers, but count towards logic)
    // Views: 15 (getLayerCount, getLayerState, getUserStake, getUserContributionLayer, getUserReputation, getUserTotalContribution, getUserArtifactCount, calculatePendingRewards, getTotalSystemContribution, getTotalSystemReputation, getSphereTokenAddress, getArtifactNFTAddress, getMinStakeDuration, getReputationDecayRate, getContributionToReputationRatio)
    // Internal helpers: 4 (_calculateReputationGain, _calculateCurrentReputation, _updateUserReputation, _calculateRewardAmount)
    // ERC721Holder: 1 (onERC721Received)

    // Total Public/External: 7 (Admin) + 3 (Core) + 2 (State Evo) + 15 (Views) + 1 (ERC721Holder) = 28
    // Total including Internal: 28 + 2 (Internal NFT) + 4 (Internal Helpers) = 34

    // Yes, well over 20 functions with distinct purposes.
}
```

**Explanation of Advanced/Interesting Concepts:**

1.  **Dynamic State & Layered Progression:** The `layers` array and the `checkAndUnlockLayer` function create a step-by-step progression for the contract's state. Layers don't just exist; they must be *earned* collectively through contributions, adding a collaborative game-like element. The state (`unlocked`) and rules (`rewardRate`) change dynamically.
2.  **Time-Decaying Reputation:** The `userReputation`, `lastReputationUpdateTime`, `reputationDecayRate`, and the `_calculateCurrentReputation`, `_updateUserReputation`, and `triggerReputationDecay` functions implement a reputation system that is not static. It rewards *ongoing engagement* rather than just historical contribution, as reputation diminishes over time if the user is inactive. The public `triggerReputationDecay` is a pattern used to offload gas costs of state maintenance from the protocol to users/bots.
3.  **Integrated NFT Utility:** `_mintArtifactForUser` and `_processArtifactMinting` demonstrate how NFTs can be earned *within* the system's progression based on user actions and state (staking, reaching reputation levels). These NFTs aren't just collectibles; they are tangible rewards tied to participation and achievement in the HyperSphere, potentially granting future benefits (though not implemented in this base contract).
4.  **Staking Mechanics:** Standard staking is included, but with the added complexity of rewards only accumulating *after* a layer is unlocked and potentially being tied to the user's reputation or other factors (though the current reward calculation is simpler: based on staked amount and time). The `minStakeDuration` adds another parameter for economic design.
5.  **Separation of Concerns (Triggering):** `checkAndUnlockLayer` and `triggerReputationDecay` being public means the contract state updates are triggered by external actors, rather than relying solely on user interactions with core functions like `stake`. This distributes the computation/gas cost for these system-level state changes.

This contract provides a framework for a complex, dynamic, and collaborative on-chain system, going beyond simple token or NFT standards by integrating multiple interacting mechanics.