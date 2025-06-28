Okay, let's create a smart contract called `OmniForge`. This contract will combine several interesting, advanced, and creative concepts:

1.  **Dynamic NFTs:** Artifacts forged will have attributes that can change over time based on on-chain actions (like staking duration or successful forging attempts linked to the owner).
2.  **Multi-Asset Forging:** Users will combine multiple types of input tokens (ERC-20 "Essence" and ERC-721 "Components") to create a new ERC-721 "Artifact" NFT.
3.  **On-Chain Randomness:** Chainlink VRF will be used to determine the success rate of forging and potentially initial attributes of the forged Artifacts.
4.  **Staking with Dynamic Rewards:** Users can stake their forged Artifact NFTs to earn "Essence" tokens. The reward rate can depend on the Artifact's dynamic attributes.
5.  **Simple On-Chain Governance:** Holders of staked Artifacts will have voting power (weighted by staked quantity/rarity) to propose and vote on changes to forging parameters (costs, success rates, recipes) and staking reward rates.
6.  **Parameterizable & Extensible:** Forging recipes and global parameters are configurable, potentially via governance.

This contract is complex and demonstrates interaction between different token standards, on-chain logic, randomness, and a basic governance model.

---

## OmniForge Smart Contract

**Outline:**

1.  **State Variables:**
    *   Token Addresses (Essence ERC20, Component ERC721, Artifact ERC721, Scrap ERC20/ERC721 - optional fallback)
    *   Forging Recipes (mapping recipeId -> inputs, output probabilities, costs)
    *   Artifact Data (mapping artifactId -> attributes, dynamic state)
    *   Staking Data (mapping artifactId -> staking info)
    *   Governance Data (proposals, votes, state)
    *   Chainlink VRF Configuration and Request Tracking
    *   Ownership/Admin
    *   Pause Mechanism

2.  **Structs:**
    *   `ForgingRecipe`: Defines inputs (ERC20/ERC721 amounts/IDs), costs, success rate, potential output outcomes (e.g., Artifact type, Scrap).
    *   `ArtifactAttributes`: Static and dynamic attributes of an Artifact NFT.
    *   `StakingInfo`: Details about an staked Artifact (staker, start time, current reward multiplier).
    *   `Proposal`: Governance proposal details (description, actions, state, voting data).
    *   `ForgingRequest`: Tracks a pending VRF request for forging.

3.  **Events:**
    *   `ArtifactForged`
    *   `ForgingFailed`
    *   `ArtifactStaked`
    *   `ArtifactUnstaked`
    *   `RewardsClaimed`
    *   `ArtifactAttributesUpdated`
    *   `ForgingRecipeAdded/Removed/Updated`
    *   `ProposalCreated/Voted/Executed`
    *   `VRFRequested/Fulfilled`

4.  **Functions (20+):**

    *   **Initialization/Admin:**
        1.  `constructor`: Sets initial owner, token addresses, VRF config.
        2.  `pause`: Pauses core contract functionality.
        3.  `unpause`: Unpauses contract.
        4.  `setTokenAddresses`: Sets ERC20/ERC721 addresses (owner only).
        5.  `setVRFParameters`: Sets Chainlink VRF parameters (owner only).
        6.  `withdrawERC20`: Owner withdraws specified ERC20 (e.g., accumulated failed forge inputs).
        7.  `withdrawERC721`: Owner withdraws specified ERC721 (e.g., accumulated failed forge components or scrap NFTs).

    *   **Forging:**
        8.  `addForgingRecipe`: Adds a new crafting recipe (owner/governance).
        9.  `removeForgingRecipe`: Removes a recipe (owner/governance).
        10. `updateForgingRecipe`: Modifies an existing recipe (owner/governance).
        11. `forgeArtifact`: Initiates a forging attempt using a recipe. Transfers input tokens and requests VRF randomness.
        12. `fulfillRandomness`: Chainlink VRF callback. Determines forging outcome, mints/transfers output, assigns initial attributes. *Internal logic, called by VRF Coordinator.*

    *   **Artifact Management:**
        13. `updateArtifactDynamicAttributes`: Allows owner/governance/internal trigger to update an Artifact's attributes (e.g., based on staking time, successful forging count linked to owner).

    *   **Staking:**
        14. `stakeArtifact`: Locks an Artifact NFT in the contract to earn rewards.
        15. `unstakeArtifact`: Unlocks an Artifact NFT and claims accrued Essence rewards.
        16. `calculatePendingRewards`: View function to see pending Essence rewards for a staked Artifact or user's staked Artifacts.

    *   **Governance:**
        17. `getVotingPower`: View function to calculate a user's current voting power (based on staked Artifacts).
        18. `createProposal`: Allows users with sufficient voting power to create a governance proposal.
        19. `voteOnProposal`: Allows users with voting power to vote on an active proposal.
        20. `executeProposal`: Executes a successful proposal after the voting period ends.

    *   **View Functions (Public Getters):**
        21. `getForgingRecipe`: Retrieves details of a specific recipe.
        22. `getArtifactAttributes`: Retrieves current attributes of an Artifact.
        23. `getStakingInfo`: Retrieves staking details for an Artifact.
        24. `getUserStakedArtifacts`: Lists Artifacts currently staked by a user.
        25. `getProposalDetails`: Retrieves details of a governance proposal.
        26. `getCurrentProposalCount`: Gets the total number of proposals.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Chainlink VRF imports
import "@chainlink/contracts/src/v0.8/vrf/V2/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

/**
 * @title OmniForge
 * @dev A complex smart contract for forging dynamic NFTs using multiple asset types,
 *      featuring staking with dynamic rewards, on-chain randomness (Chainlink VRF),
 *      and simple governance based on staked NFTs.
 *
 * Outline:
 * - State Variables (Tokens, Recipes, Artifacts, Staking, Governance, VRF, Admin)
 * - Structs (ForgingRecipe, ArtifactAttributes, StakingInfo, Proposal, ForgingRequest)
 * - Events
 * - Modifiers
 * - Initialization/Admin Functions
 * - Forging Functions (including VRF callback)
 * - Artifact Management Functions
 * - Staking Functions
 * - Governance Functions
 * - View Functions
 */
contract OmniForge is Ownable, Pausable, ERC721Holder, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // --- State Variables ---

    // Token Addresses
    IERC20 public essenceToken; // ERC20 token required for forging costs and given as staking rewards
    IERC721 public componentToken; // ERC721 token required as an input component for forging
    ERC721 public artifactToken; // The output ERC721 token representing forged items

    // Forging Configuration
    struct ForgingRecipe {
        bool exists; // Flag to indicate if the recipe is active
        uint256 essenceCost; // Amount of essence required
        uint256 componentId; // Specific Component NFT ID required (0 for any/not required)
        uint256 baseSuccessRate; // Base chance of success (0-10000, representing 0-100%)
        uint256 minArtifactLevel; // Minimum level of forged artifact on success
        uint256 maxArtifactLevel; // Maximum level of forged artifact on success
        uint256 failedEssenceRefund; // Percentage of essence refunded on failure (0-10000)
        // Future: Add more complex inputs (multiple components, different ERC20s)
    }
    mapping(uint256 => ForgingRecipe) public forgingRecipes;
    Counters.Counter private _recipeIds;

    // Artifact Data (Stored separately as we own the Artifact contract)
    // Note: In a real scenario, artifactToken would likely be a separate contract
    // implementing its own storage for attributes, and this contract would
    // interact via external calls. For simplicity here, we'll store minimal data.
    struct ArtifactAttributes {
        uint256 level; // Affects staking rewards, governance power etc.
        uint256 dynamicModifier; // A modifier that can change over time/actions
        uint256 forgingAttemptsByOwner; // Count of successful forges by original owner (example dynamic attr)
        uint256 daysStaked; // Cumulative days staked (example dynamic attr)
        // Future: Add more attributes
    }
    mapping(uint256 => ArtifactAttributes) public artifactAttributes;

    // Staking Data
    struct StakingInfo {
        address staker; // Address who staked the artifact
        uint64 startTime; // Timestamp when staking started
        uint256 rewardMultiplier; // Current multiplier affecting reward rate (derived from attributes)
    }
    mapping(uint256 => StakingInfo) public stakedArtifacts; // artifactId -> StakingInfo
    mapping(address => uint256[]) public userStakedArtifacts; // user -> list of staked artifactIds

    // Staking Parameters
    uint256 public essencePerSecondPerMultiplier = 1e16; // Base reward rate (e.g., 0.01 Essence per second per multiplier point)

    // Governance
    enum ProposalState { Pending, Active, Canceled, Defeated, Succeeded, Queued, Executed, Expired }
    struct Proposal {
        Counters.Counter.CurrentId id;
        address proposer;
        string description;
        uint64 voteStartTime;
        uint64 voteEndTime;
        uint256 quorumVotes; // Minimum votes required for success
        uint256 againstVotes;
        uint256 forVotes;
        bool executed;
        mapping(address => bool) hasVoted; // User -> hasVoted
        ProposalState state;
        // TODO: Add action data (e.g., target address, function signature, calldata) for execution
        // For simplicity in this example, execution only updates state/parameters directly.
    }
    mapping(uint256 => Proposal) public proposals;
    Counters.Counter private _proposalIds;
    uint256 public minVotingPowerToPropose = 1; // Minimum staked artifacts required to propose
    uint64 public votingPeriodDuration = 3 days; // Duration proposals are open for voting

    // Chainlink VRF
    address private s_vrfCoordinator;
    bytes32 private s_keyHash;
    uint32 private s_callbackGasLimit;
    uint16 private s_requestConfirmations;
    uint32 private s_numWords;
    uint256 private s_subscriptionId;

    struct ForgingRequest {
        address requestingUser;
        uint256 recipeId;
        uint256 essencePaid; // Amount of essence paid for this attempt
        // Could store component ID paid here too
    }
    mapping(uint256 => ForgingRequest) private s_pendingForgingRequests; // requestId -> ForgingRequest

    // --- Events ---

    event ArtifactForged(uint256 indexed artifactId, address indexed owner, uint256 indexed recipeId, uint256 level, uint256 dynamicModifier);
    event ForgingFailed(address indexed user, uint256 indexed recipeId, uint256 refundedEssence);
    event ArtifactStaked(uint256 indexed artifactId, address indexed staker, uint64 startTime);
    event ArtifactUnstaked(uint256 indexed artifactId, address indexed staker, uint256 rewardsClaimed);
    event RewardsClaimed(uint256 indexed artifactId, address indexed staker, uint256 rewardsClaimed); // Might combine with unstake
    event ArtifactAttributesUpdated(uint256 indexed artifactId, uint256 newLevel, uint256 newDynamicModifier);
    event ForgingRecipeAdded(uint256 indexed recipeId, uint256 essenceCost, uint256 componentId, uint256 baseSuccessRate);
    event ForgingRecipeRemoved(uint256 indexed recipeId);
    event ForgingRecipeUpdated(uint256 indexed recipeId, uint256 essenceCost, uint256 componentId, uint256 baseSuccessRate);
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event Voted(uint256 indexed proposalId, address indexed voter, uint256 votingPower, bool support); // support: true for For, false for Against
    event ProposalExecuted(uint256 indexed proposalId);
    event VRFRequested(uint256 indexed requestId, uint256 indexed recipeId, address indexed user);
    event VRFFulfilled(uint256 indexed requestId, uint256 indexed artifactId, bool success);

    // --- Modifiers ---

    // Note: Ownable and Pausable modifiers are inherited

    modifier onlyStakedArtifactOwner(uint256 _artifactId) {
        require(stakedArtifacts[_artifactId].staker == msg.sender, "OmniForge: Not the staker");
        _;
    }

    modifier onlyProposalState(uint256 _proposalId, ProposalState _state) {
        require(proposals[_proposalId].state == _state, "OmniForge: Invalid proposal state");
        _;
    }

    // --- Constructor ---

    constructor(
        address _essenceToken,
        address _componentToken,
        address _artifactToken, // Should be the address of the deployed Artifact ERC721 contract
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        uint256 _subscriptionId
    ) Ownable(msg.sender) VRFConsumerBaseV2(_vrfCoordinator) {
        essenceToken = IERC20(_essenceToken);
        componentToken = IERC721(_componentToken);
        artifactToken = ERC721(_artifactToken); // Cast to ERC721 assuming it is your custom artifact contract

        s_vrfCoordinator = _vrfCoordinator;
        s_keyHash = _keyHash;
        s_callbackGasLimit = _callbackGasLimit;
        s_requestConfirmations = _requestConfirmations;
        s_numWords = _numWords;
        s_subscriptionId = _subscriptionId;
    }

    // --- Admin Functions ---

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function setTokenAddresses(
        address _essenceToken,
        address _componentToken,
        address _artifactToken // Set artifactToken *only if* it's a separate contract address
    ) external onlyOwner {
        essenceToken = IERC20(_essenceToken);
        componentToken = IERC721(_componentToken);
        // Check if artifactToken address is being updated - careful with this
        if (address(artifactToken) != _artifactToken && _artifactToken != address(0)) {
             artifactToken = ERC721(_artifactToken);
        }
    }

    function setVRFParameters(
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        uint256 _subscriptionId
    ) external onlyOwner {
        s_keyHash = _keyHash;
        s_callbackGasLimit = _callbackGasLimit;
        s_requestConfirmations = _requestConfirmations;
        s_numWords = _numWords;
        s_subscriptionId = _subscriptionId;
    }

    function withdrawERC20(address _tokenAddress, address _to) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(_to, balance), "OmniForge: ERC20 withdrawal failed");
    }

     function withdrawERC721(address _tokenAddress, uint256 _tokenId, address _to) external onlyOwner {
        IERC721 token = IERC721(_tokenAddress);
        require(token.ownerOf(_tokenId) == address(this), "OmniForge: Contract does not own token");
        token.safeTransferFrom(address(this), _to, _tokenId);
    }

    // --- Forging Configuration Functions ---

    function addForgingRecipe(
        uint256 _recipeId,
        uint256 _essenceCost,
        uint256 _componentId,
        uint256 _baseSuccessRate, // 0-10000
        uint256 _minArtifactLevel,
        uint256 _maxArtifactLevel,
        uint256 _failedEssenceRefund // 0-10000
    ) external onlyOwner { // Can be modified for governance access later
        require(!forgingRecipes[_recipeId].exists, "OmniForge: Recipe ID already exists");
        require(_baseSuccessRate <= 10000, "OmniForge: Success rate must be <= 10000");
         require(_failedEssenceRefund <= 10000, "OmniForge: Refund rate must be <= 10000");
         require(_minArtifactLevel > 0 && _minArtifactLevel <= _maxArtifactLevel, "OmniForge: Invalid artifact levels");

        forgingRecipes[_recipeId] = ForgingRecipe({
            exists: true,
            essenceCost: _essenceCost,
            componentId: _componentId,
            baseSuccessRate: _baseSuccessRate,
            minArtifactLevel: _minArtifactLevel,
            maxArtifactLevel: _maxArtifactLevel,
            failedEssenceRefund: _failedEssenceRefund
        });

        emit ForgingRecipeAdded(_recipeId, _essenceCost, _componentId, _baseSuccessRate);
        _recipeIds.increment(); // Keep track of total recipes added (optional counter)
    }

    function removeForgingRecipe(uint256 _recipeId) external onlyOwner { // Can be modified for governance access later
        require(forgingRecipes[_recipeId].exists, "OmniForge: Recipe ID does not exist");
        delete forgingRecipes[_recipeId];
        emit ForgingRecipeRemoved(_recipeId);
    }

    function updateForgingRecipe(
        uint256 _recipeId,
        uint256 _essenceCost,
        uint256 _componentId,
        uint256 _baseSuccessRate,
        uint256 _minArtifactLevel,
        uint256 _maxArtifactLevel,
        uint256 _failedEssenceRefund
    ) external onlyOwner { // Can be modified for governance access later
        require(forgingRecipes[_recipeId].exists, "OmniForge: Recipe ID does not exist");
        require(_baseSuccessRate <= 10000, "OmniForge: Success rate must be <= 10000");
        require(_failedEssenceRefund <= 10000, "OmniForge: Refund rate must be <= 10000");
        require(_minArtifactLevel > 0 && _minArtifactLevel <= _maxArtifactLevel, "OmniForge: Invalid artifact levels");

        forgingRecipes[_recipeId] = ForgingRecipe({
            exists: true, // Remains true
            essenceCost: _essenceCost,
            componentId: _componentId,
            baseSuccessRate: _baseSuccessRate,
            minArtifactLevel: _minArtifactLevel,
            maxArtifactLevel: _maxArtifactLevel,
            failedEssenceRefund: _failedEssenceRefund
        });

        emit ForgingRecipeUpdated(_recipeId, _essenceCost, _componentId, _baseSuccessRate);
    }


    // --- Forging Functions ---

    /**
     * @dev Initiates a forging attempt for a specific recipe.
     * Requires user to approve Essence and Component tokens to the contract.
     * Transfers inputs and requests VRF randomness for the outcome.
     * The actual result (success/failure, minting) happens in fulfillRandomness.
     */
    function forgeArtifact(uint256 _recipeId) external whenNotPaused {
        ForgingRecipe storage recipe = forgingRecipes[_recipeId];
        require(recipe.exists, "OmniForge: Recipe does not exist");

        // 1. Transfer Essence cost
        require(essenceToken.transferFrom(msg.sender, address(this), recipe.essenceCost), "OmniForge: Essence transfer failed");

        // 2. Transfer Component NFT (if required)
        if (recipe.componentId != 0) {
            require(componentToken.ownerOf(recipe.componentId) == msg.sender, "OmniForge: Caller does not own component");
            componentToken.transferFrom(msg.sender, address(this), recipe.componentId);
            // Note: Component NFT is *burned* or kept by contract? Let's say burned for this version.
            // In a real scenario, you might want to track it or have a separate burn function.
            // For now, it just stays in the contract until owner withdraws.
        }

        // 3. Request randomness
        uint256 requestId = requestRandomness();

        // 4. Store request context
        s_pendingForgingRequests[requestId] = ForgingRequest({
            requestingUser: msg.sender,
            recipeId: _recipeId,
            essencePaid: recipe.essenceCost
        });

        emit VRFRequested(requestId, _recipeId, msg.sender);
    }

    /**
     * @dev Callback function for Chainlink VRF. Determines forging outcome and mints/transfers.
     * @param _requestId The ID of the VRF request.
     * @param _randomWords The random words generated by Chainlink VRF.
     */
    function fulfillRandomness(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_pendingForgingRequests[_requestId].requestingUser != address(0), "OmniForge: Unknown VRF request ID");

        ForgingRequest memory request = s_pendingForgingRequests[_requestId];
        delete s_pendingForgingRequests[_requestId]; // Clean up the request

        ForgingRecipe storage recipe = forgingRecipes[request.recipeId];
        require(recipe.exists, "OmniForge: Recipe not found during fulfillment"); // Should not happen if request existed

        // Determine success based on randomness
        uint256 randomNumber = _randomWords[0] % 10000; // Get a number between 0 and 9999
        bool success = randomNumber < recipe.baseSuccessRate;

        if (success) {
            // Mint new Artifact NFT
            uint256 newTokenId = artifactToken.totalSupply() + 1; // Simple ID generation (adjust if Artifact has its own ID counter)
            artifactToken.safeMint(request.requestingUser, newTokenId);

            // Assign initial attributes based on recipe and maybe another random word
            uint256 levelRange = recipe.maxArtifactLevel - recipe.minArtifactLevel + 1;
            uint256 initialLevel = recipe.minArtifactLevel + (_randomWords.length > 1 ? (_randomWords[1] % levelRange) : 0); // Use second word if available
            initialLevel = (initialLevel == 0) ? recipe.minArtifactLevel : initialLevel; // Ensure minimum level is met

            // Initial dynamic modifier could be random too
            uint256 initialDynamicModifier = (_randomWords.length > 2 ? (_randomWords[2] % 100) + 1 : 1); // Example: 1-100

            artifactAttributes[newTokenId] = ArtifactAttributes({
                level: initialLevel,
                dynamicModifier: initialDynamicModifier,
                forgingAttemptsByOwner: 1, // First successful attempt
                daysStaked: 0
            });

            emit ArtifactForged(newTokenId, request.requestingUser, request.recipeId, initialLevel, initialDynamicModifier);
            emit VRFFulfilled(_requestId, newTokenId, true);

        } else {
            // Forging Failed
            uint256 refundAmount = (request.essencePaid * recipe.failedEssenceRefund) / 10000;
             if (refundAmount > 0) {
                require(essenceToken.transfer(request.requestingUser, refundAmount), "OmniForge: Failed forge essence refund failed");
            }

            // Optionally handle component token (e.g., refund, burn)
            // For now, it stays in contract address until owner withdraws

            emit ForgingFailed(request.requestingUser, request.recipeId, refundAmount);
            emit VRFFulfilled(_requestId, 0, false); // 0 for artifactId indicates failure
        }
    }

    // Helper function to request VRF randomness
    function requestRandomness() internal returns (uint256) {
         // Will revert if subscription is not funded sufficiently
        uint256 requestId = VRFConsumerBaseV2(s_vrfCoordinator).requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            s_requestConfirmations,
            s_callbackGasLimit,
            s_numWords
        );
        return requestId;
    }


    // --- Artifact Management ---

    /**
     * @dev Allows updating dynamic attributes of an artifact.
     * Could be triggered by owner, governance, or potentially internal logic.
     * For simplicity, let's make it owner-callable, but note governance could call this too.
     * @param _artifactId The ID of the artifact to update.
     * @param _newLevel The new level (can be same as current).
     * @param _newDynamicModifier The new dynamic modifier.
     * @param _forgingAttemptsByOwner The new forging attempts count.
     * @param _daysStaked The new cumulative days staked count.
     */
    function updateArtifactDynamicAttributes(
        uint256 _artifactId,
        uint256 _newLevel,
        uint256 _newDynamicModifier,
        uint256 _forgingAttemptsByOwner,
        uint256 _daysStaked
    ) external onlyOwner { // Consider making this governance/role-based
        require(_artifactId > 0 && _artifactId <= artifactToken.totalSupply(), "OmniForge: Invalid Artifact ID");
        // Could add more validation based on actual dynamic attribute logic

        artifactAttributes[_artifactId].level = _newLevel;
        artifactAttributes[_artifactId].dynamicModifier = _newDynamicModifier;
        artifactAttributes[_artifactId].forgingAttemptsByOwner = _forgingAttemptsByOwner;
        artifactAttributes[_artifactId].daysStaked = _daysStaked;

        // If staked, update its reward multiplier based on new attributes
        if (stakedArtifacts[_artifactId].staker != address(0)) {
             stakedArtifacts[_artifactId].rewardMultiplier = calculateRewardMultiplier(_artifactId);
        }


        emit ArtifactAttributesUpdated(_artifactId, _newLevel, _newDynamicModifier);
    }

    // Helper to calculate reward multiplier based on artifact attributes
    function calculateRewardMultiplier(uint256 _artifactId) internal view returns (uint256) {
        ArtifactAttributes storage attrs = artifactAttributes[_artifactId];
        // Example calculation: Level * DynamicModifier
        // Add logic here to factor in forgingAttemptsByOwner, daysStaked etc.
        // Be careful with multiplication to avoid overflow.
        return attrs.level * attrs.dynamicModifier; // Simple example
    }

    // --- Staking Functions ---

    /**
     * @dev Stakes an Artifact NFT. The user must own the NFT and approve the contract.
     * @param _artifactId The ID of the artifact to stake.
     */
    function stakeArtifact(uint256 _artifactId) external whenNotPaused {
        require(artifactToken.ownerOf(_artifactId) == msg.sender, "OmniForge: Caller does not own Artifact");
        require(stakedArtifacts[_artifactId].staker == address(0), "OmniForge: Artifact already staked");

        // Transfer NFT to the contract
        artifactToken.transferFrom(msg.sender, address(this), _artifactId);

        // Record staking info
        stakedArtifacts[_artifactId] = StakingInfo({
            staker: msg.sender,
            startTime: uint64(block.timestamp),
            rewardMultiplier: calculateRewardMultiplier(_artifactId)
        });

        // Add to user's staked list (simple append, removing is more complex/gas heavy)
        userStakedArtifacts[msg.sender].push(_artifactId);

        emit ArtifactStaked(_artifactId, msg.sender, stakedArtifacts[_artifactId].startTime);
    }

    /**
     * @dev Unstakes an Artifact NFT and claims accrued rewards.
     * @param _artifactId The ID of the artifact to unstake.
     */
    function unstakeArtifact(uint256 _artifactId) external whenNotPaused onlyStakedArtifactOwner(_artifactId) {
        StakingInfo storage stake = stakedArtifacts[_artifactId];

        // Calculate rewards before clearing stake info
        uint256 pendingRewards = calculatePendingRewards(_artifactId);

        // Transfer NFT back to staker
        artifactToken.transferFrom(address(this), msg.sender, _artifactId);

        // Transfer rewards
        if (pendingRewards > 0) {
            require(essenceToken.transfer(msg.sender, pendingRewards), "OmniForge: Reward transfer failed");
        }

        // Remove staking info
        delete stakedArtifacts[_artifactId];
        // Note: Removing from userStakedArtifacts array is complex/gas heavy.
        // A simple approach is to leave it and check if `stakedArtifacts[id].staker` is msg.sender.
        // A more gas-efficient approach requires tracking index or linked lists.
        // For this example, we accept potential "ghost" entries in the user array or add complex removal logic.
        // Let's add a note about array removal complexity and skip it for simplicity.

        emit ArtifactUnstaked(_artifactId, msg.sender, pendingRewards);
    }

    /**
     * @dev Calculates the pending Essence rewards for a specific staked Artifact.
     * @param _artifactId The ID of the artifact.
     * @return pending rewards amount.
     */
    function calculatePendingRewards(uint256 _artifactId) public view returns (uint256) {
        StakingInfo storage stake = stakedArtifacts[_artifactId];
        if (stake.staker == address(0)) {
            return 0; // Not staked
        }

        uint256 duration = block.timestamp - stake.startTime;
        uint256 rewards = duration * stake.rewardMultiplier * essencePerSecondPerMultiplier / 1e18; // Adjust for token decimals

        return rewards;
    }

     /**
     * @dev Calculates the pending Essence rewards for all staked Artifacts of a user.
     * Note: This can be gas-heavy for users with many staked artifacts.
     * @param _user The address of the user.
     * @return total pending rewards amount.
     */
    function calculateTotalPendingRewards(address _user) external view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] storage stakedIds = userStakedArtifacts[_user]; // Note: might contain unstaked IDs
        for (uint i = 0; i < stakedIds.length; i++) {
            uint256 artifactId = stakedIds[i];
             // Check if the artifact is actually still staked by this user
            if (stakedArtifacts[artifactId].staker == _user) {
                 totalRewards += calculatePendingRewards(artifactId);
            }
        }
        return totalRewards;
    }


    // --- Governance Functions ---

    /**
     * @dev Calculates a user's voting power based on their staked Artifacts.
     * Example: 1 voting power per staked artifact. Could be weighted by level/attributes.
     * @param _user The address of the user.
     * @return The user's voting power.
     */
    function getVotingPower(address _user) public view returns (uint256) {
        uint256 power = 0;
        uint256[] storage stakedIds = userStakedArtifacts[_user];
         for (uint i = 0; i < stakedIds.length; i++) {
            uint256 artifactId = stakedIds[i];
             // Check if the artifact is actually still staked by this user
            if (stakedArtifacts[artifactId].staker == _user) {
                // Example: 1 power per staked artifact + bonus based on level/dynamicModifier
                 power += 1 + (artifactAttributes[artifactId].level / 10) + (artifactAttributes[artifactId].dynamicModifier / 20); // Example weighting
            }
        }
        return power;
    }

    /**
     * @dev Creates a new governance proposal.
     * @param _description A description of the proposal.
     * @param _quorumVotes The minimum total 'For' votes required for the proposal to pass.
     * (Note: In a real system, execution data would be needed here too).
     */
    function createProposal(string calldata _description, uint256 _quorumVotes) external whenNotPaused {
        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower >= minVotingPowerToPropose, "OmniForge: Insufficient voting power to propose");

        _proposalIds.increment();
        uint256 proposalId = _proposalIds.current();

        proposals[proposalId] = Proposal({
            id: proposalId,
            proposer: msg.sender,
            description: _description,
            voteStartTime: uint64(block.timestamp),
            voteEndTime: uint64(block.timestamp) + votingPeriodDuration,
            quorumVotes: _quorumVotes,
            againstVotes: 0,
            forVotes: 0,
            executed: false,
            state: ProposalState.Active,
            hasVoted: new mapping(address => bool) // Initialize new mapping for this proposal
        });

        emit ProposalCreated(proposalId, msg.sender, _description);
    }

    /**
     * @dev Casts a vote on an active proposal.
     * @param _proposalId The ID of the proposal.
     * @param _support True for voting For, false for voting Against.
     */
    function voteOnProposal(uint256 _proposalId, bool _support) external whenNotPaused onlyProposalState(_proposalId, ProposalState.Active) {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.hasVoted[msg.sender], "OmniForge: Already voted on this proposal");
        require(block.timestamp <= proposal.voteEndTime, "OmniForge: Voting period has ended");

        uint256 votingPower = getVotingPower(msg.sender);
        require(votingPower > 0, "OmniForge: No voting power");

        proposal.hasVoted[msg.sender] = true;

        if (_support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }

        emit Voted(_proposalId, msg.sender, votingPower, _support);

        // Optionally update state if threshold reached early (less common)
    }

    /**
     * @dev Executes a successful proposal after the voting period.
     * Note: This version is simplified and doesn't include complex cross-contract execution.
     * A real DAO would use delegates or target/calldata. This version assumes the proposal
     * simply approves/disapproves a pending owner action or updates a parameter directly.
     * @param _proposalId The ID of the proposal.
     */
    function executeProposal(uint256 _proposalId) external whenNotPaused onlyProposalState(_proposalId, ProposalState.Succeeded) {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.voteEndTime, "OmniForge: Voting period not ended");
        require(!proposal.executed, "OmniForge: Proposal already executed");

        // In a real DAO, complex logic to call target contracts would go here.
        // Example (conceptual): call(proposal.target, proposal.calldata)

        // For this simplified example, assume proposal success allows some specific admin action,
        // or it directly updates a state variable defined by the proposal (not modeled fully here).
        // We just mark it as executed.
        proposal.executed = true;
        proposal.state = ProposalState.Executed;

        emit ProposalExecuted(_proposalId);
    }

    /**
     * @dev Helper function to update proposal state based on current conditions.
     * Can be called by anyone to push state forward after vote end.
     * @param _proposalId The ID of the proposal.
     */
    function updateProposalState(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
            if (proposal.forVotes >= proposal.quorumVotes && proposal.forVotes > proposal.againstVotes) {
                proposal.state = ProposalState.Succeeded;
            } else {
                proposal.state = ProposalState.Defeated;
            }
        }
        // Add logic for other state transitions (e.g., Queued -> Executed)
    }

    // --- View Functions ---

    function getForgingRecipe(uint256 _recipeId) external view returns (ForgingRecipe memory) {
        require(forgingRecipes[_recipeId].exists, "OmniForge: Recipe does not exist");
        return forgingRecipes[_recipeId];
    }

    function getArtifactAttributes(uint256 _artifactId) external view returns (ArtifactAttributes memory) {
         require(_artifactId > 0 && _artifactId <= artifactToken.totalSupply(), "OmniForge: Invalid Artifact ID");
        return artifactAttributes[_artifactId];
    }

    function getStakingInfo(uint256 _artifactId) external view returns (StakingInfo memory) {
        require(_artifactId > 0 && _artifactId <= artifactToken.totalSupply(), "OmniForge: Invalid Artifact ID");
        return stakedArtifacts[_artifactId];
    }

    // Returns the list of artifact IDs a user *might* have staked.
    // Use getStakingInfo for each ID to confirm it's still staked by them.
    function getUserStakedArtifacts(address _user) external view returns (uint256[] memory) {
        return userStakedArtifacts[_user];
    }

    function getProposalDetails(uint256 _proposalId) external view returns (Proposal memory) {
        require(_proposalIds.current() >= _proposalId, "OmniForge: Invalid proposal ID");
        // Note: proposal.hasVoted mapping is not returned by default in solidity external calls
        // You would need a separate getter for voted status for a specific user/proposal.
        Proposal storage p = proposals[_proposalId];
         return Proposal({
            id: p.id,
            proposer: p.proposer,
            description: p.description,
            voteStartTime: p.voteStartTime,
            voteEndTime: p.voteEndTime,
            quorumVotes: p.quorumVotes,
            againstVotes: p.againstVotes,
            forVotes: p.forVotes,
            executed: p.executed,
            state: p.state,
            hasVoted: new mapping(address => bool) // Cannot return mapping, returns empty
        });
    }

    function getProposalState(uint256 _proposalId) public view returns (ProposalState) {
         require(_proposalIds.current() >= _proposalId, "OmniForge: Invalid proposal ID");
         Proposal storage proposal = proposals[_proposalId];
         // Recalculate state if active and time is past end
         if (proposal.state == ProposalState.Active && block.timestamp > proposal.voteEndTime) {
            if (proposal.forVotes >= proposal.quorumVotes && proposal.forVotes > proposal.againstVotes) {
                return ProposalState.Succeeded;
            } else {
                return ProposalState.Defeated;
            }
        }
        return proposal.state;
    }

     function getCurrentProposalCount() external view returns (uint256) {
        return _proposalIds.current();
    }

    // --- ERC721Holder override ---
    // Required by ERC721Holder to accept safeTransferFrom calls
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
        // Can add checks here if needed, but default implementation just returns magic value
        return this.onERC721Received.selector;
    }

    // The received function is needed to accept LINK token transfers for VRF subscription
    receive() external payable {}
}
```

**Explanation of Advanced Concepts:**

1.  **Dynamic NFT Attributes:** The `ArtifactAttributes` struct stores values like `level`, `dynamicModifier`, `forgingAttemptsByOwner`, and `daysStaked`. The `updateArtifactDynamicAttributes` function (and potentially internal logic or triggers not fully modeled) allows changing these values *after* the NFT is minted. This makes the NFT non-static. The `calculateRewardMultiplier` and `getVotingPower` functions *use* these dynamic attributes, giving the changes tangible effects within the system.
2.  **Multi-Asset Forging:** The `forgeArtifact` function demonstrates requiring both an ERC-20 (`essenceToken`) and a specific ERC-721 (`componentToken`) as inputs, which are transferred to the contract (and conceptually consumed/burned) to produce a new output NFT (`artifactToken`). This is more complex than simple 1-to-1 minting.
3.  **On-Chain Randomness with VRF:** Instead of using unreliable pseudo-randomness (`block.timestamp`, `block.difficulty`), Chainlink VRF is integrated. `forgeArtifact` requests randomness, and `fulfillRandomness` is the callback where the *actual outcome* (success/failure, initial attributes) is determined using the verifiably random number. This requires a subscription ID and interaction with the Chainlink VRF Coordinator.
4.  **Staking with Dynamic Rewards:** The `stakeArtifact` and `unstakeArtifact` functions handle locking and unlocking the Artifact NFTs. The `calculatePendingRewards` uses a `rewardMultiplier` derived from the Artifact's *dynamic attributes*. This means as an Artifact's attributes change (e.g., leveling up by staying staked), its earning rate increases without needing to restake.
5.  **Simple On-Chain Governance:** The contract includes basic functions (`getVotingPower`, `createProposal`, `voteOnProposal`, `executeProposal`). Voting power is tied to staked NFTs, giving them utility beyond just earning rewards. The system allows proposing and voting on changes (conceptually; the execution part is simplified). The `updateProposalState` allows anyone to transition the state forward once the voting period ends, making it permissionless after the initial vote casting.

**Further Enhancements & Considerations (Beyond the 20 functions):**

*   **Artifact Token Contract:** In a real application, `artifactToken` would be a separate contract that this `OmniForge` contract interacts with. `OmniForge` would need the `MINTER_ROLE` or similar on the Artifact contract. The Artifact contract itself would store the `ArtifactAttributes` mapping.
*   **Governance Execution:** The `executeProposal` function is highly simplified. Real DAOs use patterns like the "Governor" contract from OpenZeppelin, which supports queueing proposals and executing arbitrary function calls on target contracts via calldata.
*   **Staked Artifact Array Removal:** The `userStakedArtifacts` array does not have a clean way to remove IDs on unstaking without high gas costs or complex linked lists. A more robust design would use a mapping of `user => mapping(uint256 => bool)` to track if an artifact is staked by a user, or iterate through the `stakedArtifacts` mapping to find a user's assets (potentially gas-heavy depending on the number of staked items).
*   **Error Handling & Input Validation:** Add more robust `require` messages and checks.
*   **Gas Optimization:** Complex loops or heavy storage operations (especially array manipulation) can be expensive. Consider gas costs for functions like `calculateTotalPendingRewards`.
*   **Security:** More advanced access control (role-based) beyond `onlyOwner` for functions like adding/updating recipes might be needed. Add reentrancy guards where necessary (unlikely in this specific structure but good practice).
*   **UI Interaction:** Frontend would need to handle the 2-step forging process (call `forgeArtifact`, then listen for `VRFFulfilled` event).
*   **Scrap Token:** The `failedEssenceRefund` is implemented, but a "Scrap" token for failed attempts could be an interesting addition, requiring minting/burning a third token type.
*   **Subscription Management:** The contract relies on a pre-funded Chainlink VRF subscription. Logic to add funds to the subscription might be needed (`VRFConsumerBaseV2` has `requestSubscriptionOwnerTransfer` and `acceptSubscriptionOwnerTransfer`).
*   **NFT Metadata:** The ERC721 contract would need `tokenURI` logic. Dynamic attributes stored here could influence the metadata returned, potentially via an API or on-chain generation.

This `OmniForge` contract provides a solid foundation incorporating multiple advanced concepts in a single system, going well beyond basic token or simple NFT contracts.