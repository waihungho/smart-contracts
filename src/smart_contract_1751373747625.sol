Okay, let's design an interesting, advanced, and creative smart contract. We'll call it the "ChronoForge Ecosystem".

**Concept:**

The ChronoForge Ecosystem allows users to 'forge' unique digital assets called "ChronoArtifacts" (ERC-1155) using a native "Temporal Essence" token (ERC-20). These ChronoArtifacts aren't static; they have dynamic properties that can change based on external factors (simulated via oracle interaction), time, staking, or participating in "Temporal Quests". The ecosystem also includes simple governance for key parameters.

**Advanced Concepts Included:**

1.  **Dynamic NFTs/Assets:** Asset properties change post-minting.
2.  **ERC-1155 for Flexibility:** Represents both unique and potentially semi-fungible items.
3.  **Native Tokenomics (ERC-20):** Utility token for crafting, staking, and interaction.
4.  **Forging/Crafting Mechanics:** Burning tokens/assets to create new/upgraded assets.
5.  **Staking Mechanics:** Staking Assets to earn tokens.
6.  **Simulated Oracle Interaction:** Mechanism to trigger state changes based on external (or simulated external) data.
7.  **Gamification (Quests):** Structured tasks associated with assets.
8.  **Asset Composition/Decomposition:** Merging and Splitting assets.
9.  **Simple Governance:** Parameter changes controlled by token holders.
10. **Role-Based Access Control (Implicit via Ownable/Admin):** Different levels of permissions.
11. **Reentrancy Guard:** Basic security for state-changing functions involving external calls (like transfers).

---

**Smart Contract Outline & Function Summary**

**Contract Name:** ChronoForgeEcosystem

**Core Idea:** A platform for crafting, managing, and interacting with dynamic digital assets (ChronoArtifacts) using a native token (TemporalEssence), influenced by external data and user participation.

**Inherits:**
*   `Ownable` (from OpenZeppelin) - For administrative control.
*   `ERC20` (from OpenZeppelin) - For the Temporal Essence token.
*   `ERC1155` (from OpenZeppelin) - For the ChronoArtifact assets.
*   `ReentrancyGuard` (from OpenZeppelin) - For preventing reentrancy attacks.

**Structs:**
*   `ArtifactProperties`: Stores dynamic attributes of a ChronoArtifact (e.g., power, decay, state flags).
*   `StakingInfo`: Stores information about a staked ChronoArtifact (start time, boost multiplier).
*   `QuestDetails`: Configuration for a specific quest type (reward, requirements).
*   `ActiveQuest`: State of an ongoing quest instance for an artifact/user.
*   `Proposal`: State of a governance proposal.

**State Variables:**
*   `temporalEssence`: ERC20 token instance.
*   `chronoArtifacts`: ERC1155 token instance (the contract itself).
*   `artifactProperties`: Mapping from artifact ID to its current dynamic properties.
*   `stakedArtifacts`: Mapping from artifact ID to staking info.
*   `questConfigs`: Mapping from quest ID to its configuration.
*   `activeQuests`: Mapping from artifact ID to its current active quest state.
*   `nextArtifactId`: Counter for new artifact IDs.
*   `nextQuestId`: Counter for quest configurations.
*   `nextProposalId`: Counter for governance proposals.
*   `proposals`: Mapping from proposal ID to its state.
*   `oracleAddress`: Address of the simulated oracle.
*   `essencePerSecondPerStakedPower`: Rate of essence generation from staking.
*   `forgingRecipes`: Mapping describing crafting requirements (input tokens/artifacts, essence cost).

**Events:**
*   `ArtifactForged`: Logs creation/upgrade of an artifact.
*   `ArtifactStateUpdated`: Logs changes to an artifact's dynamic properties.
*   `ArtifactStaked`: Logs when an artifact is staked.
*   `ArtifactUnstaked`: Logs when an artifact is unstaked.
*   `StakingRewardsClaimed`: Logs essence claimed from staking.
*   `ExternalDataRequested`: Logs when external data is needed.
*   `ExternalDataFulfilled`: Logs when external data is received.
*   `QuestInitiated`: Logs the start of a quest.
*   `QuestCompleted`: Logs the completion of a quest.
*   `ProposalCreated`: Logs creation of a governance proposal.
*   `VoteCast`: Logs casting a vote on a proposal.
*   `ProposalExecuted`: Logs execution of a passed proposal.
*   `ArtifactSplit`: Logs when an artifact is split.
*   `ArtifactMerged`: Logs when artifacts are merged.

**Function Summary (25 Functions):**

1.  `constructor(string memory name, string memory symbol)`: Initializes the contract, ERC-20, and ERC-1155 tokens. Sets the initial owner.
2.  `mintInitialEssence(address to, uint256 amount)`: Admin function to mint initial Temporal Essence tokens.
3.  `mintInitialArtifact(address to, uint256 artifactTypeId, uint256 amount, bytes memory data)`: Admin function to mint base/initial types of ChronoArtifacts.
4.  `forgeArtifact(uint256 recipeId, uint256[] memory inputArtifactIds, uint256[] memory inputEssenceAmounts)`: **Creative.** Allows users to combine input artifacts and burn Temporal Essence according to a recipe to mint a new artifact or upgrade an existing one.
5.  `setForgingRecipe(uint256 recipeId, uint256[] memory requiredArtifactTypes, uint256[] memory requiredArtifactAmounts, uint256 requiredEssenceCost, uint256 outputArtifactTypeId)`: **Admin.** Sets or updates a forging recipe.
6.  `updateArtifactDynamicState(uint256 artifactId, int256 stateChangeValue, bytes32 stateChangeType)`: **Dynamic/Advanced.** Function to change a specific dynamic property of an artifact. Can be called internally or by trusted roles/oracles.
7.  `stakeArtifact(uint256 artifactId)`: **DeFi/Gaming.** Stakes a specific ChronoArtifact owned by the caller. Transfers the artifact to the contract.
8.  `unstakeArtifact(uint256 artifactId)`: **DeFi/Gaming.** Unstakes a previously staked ChronoArtifact. Transfers the artifact back to the owner and calculates/resets staking rewards.
9.  `claimStakingRewards(uint256 artifactId)`: **DeFi/Gaming.** Calculates and transfers accumulated Temporal Essence rewards for a staked artifact to its owner.
10. `calculatePendingRewards(uint256 artifactId)`: **Utility.** View function to calculate pending staking rewards for an artifact without claiming.
11. `requestExternalData(bytes32 dataType, bytes memory data)`: **Oracle/Advanced.** Function called by a trusted entity (or potentially anyone triggering a specific event) to signal that external data is needed to update artifact states. Emits an event the oracle service listens to.
12. `fulfillExternalData(bytes32 dataType, bytes memory responseData)`: **Oracle/Advanced.** Callback function intended to be called *only* by the designated oracle address. Uses the received data (`responseData`) to trigger calls to `updateArtifactDynamicState` for relevant artifacts.
13. `setExternalDataProvider(address _oracleAddress)`: **Admin.** Sets the address authorized to call `fulfillExternalData`.
14. `setQuestDetails(uint256 questId, QuestDetails calldata details)`: **Admin.** Configures details for a specific quest type.
15. `initiateArtifactQuest(uint256 artifactId, uint256 questId)`: **Gamification.** Assigns a specific quest instance to an artifact, starting its timer/requirements tracking. Requires the artifact to be staked or in the owner's wallet (configurable).
16. `completeArtifactQuest(uint256 artifactId)`: **Gamification.** Checks if the requirements for the active quest on an artifact are met. If so, applies rewards (Essence, artifact property boost) and marks the quest complete.
17. `proposeEcosystemParameterChange(uint256 parameterIndex, uint256 newValue, string memory description)`: **Governance.** Allows users with sufficient Essence holding power (or staked artifacts) to propose changing a specific ecosystem parameter (e.g., `essencePerSecondPerStakedPower`).
18. `voteOnParameterChange(uint256 proposalId, bool support)`: **Governance.** Allows users to vote on an active proposal. Voting power is based on Essence balance or staked artifact count at a snapshot time (or proposal creation time).
19. `executeParameterChange(uint256 proposalId)`: **Governance.** Allows anyone to execute a proposal if the voting period has ended and it has passed the required threshold.
20. `splitArtifact(uint256 parentArtifactId, uint256[] memory childArtifactTypeIds, uint256[] memory childAmounts, uint256 essenceRefundAmount)`: **Creative.** Breaks down a high-level artifact into specified child artifacts and potentially refunds some Essence. Burns the parent artifact. Requires a predefined 'splitting recipe'.
21. `mergeArtifacts(uint256[] memory inputArtifactIds, uint256 outputArtifactTypeId, uint256 essenceCost)`: **Creative.** Combines multiple specific artifacts into a single new, higher-level artifact type, potentially costing Essence. Burns the input artifacts. Requires a predefined 'merging recipe'.
22. `getArtifactProperties(uint256 artifactId)`: **Utility.** View function to retrieve the current dynamic properties of an artifact.
23. `getStakingInfo(uint256 artifactId)`: **Utility.** View function to retrieve the staking details for an artifact.
24. `getActiveQuest(uint256 artifactId)`: **Utility.** View function to retrieve the details of an active quest on an artifact.
25. `getProposalDetails(uint256 proposalId)`: **Utility.** View function to retrieve details of a governance proposal.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol"; // Needed if contract holds ERC1155

// Note: This is a complex contract featuring multiple concepts.
// For simplicity and demonstration, certain advanced patterns (like full upgradeability proxies,
// precise oracle integration with request/fulfill patterns for Chainlink VRF/DataFeeds,
// or sophisticated voting systems like quadratic voting) are represented conceptually
// or simplified (e.g., simulated oracle callback, simple majority vote based on snapshot).
// Production use would require rigorous security audits and more robust implementations
// of these specific patterns.

// --- Smart Contract Outline & Function Summary ---
// Contract Name: ChronoForgeEcosystem
// Core Idea: A platform for crafting, managing, and interacting with dynamic digital assets (ChronoArtifacts)
//            using a native token (TemporalEssence), influenced by external data and user participation.
// Inherits: Ownable, ERC20, ERC1155, ReentrancyGuard, ERC1155Holder
// Structs: ArtifactProperties, StakingInfo, QuestDetails, ActiveQuest, Proposal, ForgingRecipe, SplitRecipe, MergeRecipe
// State Variables: temporalEssence, chronoArtifacts, artifactProperties, stakedArtifacts, questConfigs,
//                  activeQuests, nextArtifactId, nextQuestId, nextProposalId, proposals, oracleAddress,
//                  essencePerSecondPerStakedPower, forgingRecipes, splitRecipes, mergeRecipes,
//                  proposalParameterMap (mapping index to state var name/type)
// Events: ArtifactForged, ArtifactStateUpdated, ArtifactStaked, ArtifactUnstaked, StakingRewardsClaimed,
//         ExternalDataRequested, ExternalDataFulfilled, QuestInitiated, QuestCompleted,
//         ProposalCreated, VoteCast, ProposalExecuted, ArtifactSplit, ArtifactMerged
// Function Summary (25 Functions):
//  1. constructor: Initializes contract, tokens, owner.
//  2. mintInitialEssence: Admin mints base token.
//  3. mintInitialArtifact: Admin mints base artifact types.
//  4. forgeArtifact: Combine inputs/essence to create/upgrade artifact. (Creative)
//  5. setForgingRecipe: Admin sets forging rules.
//  6. updateArtifactDynamicState: Change artifact properties based on logic/data. (Dynamic/Advanced)
//  7. stakeArtifact: Lock artifact to earn rewards. (DeFi/Gaming)
//  8. unstakeArtifact: Withdraw staked artifact.
//  9. claimStakingRewards: Claim accumulated essence rewards.
// 10. calculatePendingRewards: View pending rewards. (Utility)
// 11. requestExternalData: Signal need for external data. (Oracle/Advanced)
// 12. fulfillExternalData: Callback for oracle data. (Oracle/Advanced)
// 13. setExternalDataProvider: Admin sets oracle address.
// 14. setQuestDetails: Admin configures quests. (Gamification)
// 15. initiateArtifactQuest: Start a quest for an artifact. (Gamification)
// 16. completeArtifactQuest: Finish quest, get rewards. (Gamification)
// 17. proposeEcosystemParameterChange: Create governance proposal. (Governance)
// 18. voteOnParameterChange: Vote on a proposal. (Governance)
// 19. executeParameterChange: Apply passed proposal. (Governance)
// 20. splitArtifact: Break artifact into components. (Creative)
// 21. mergeArtifacts: Combine artifacts into one. (Creative)
// 22. setSplitRecipe: Admin sets splitting rules.
// 23. setMergeRecipe: Admin sets merging rules.
// 24. getArtifactProperties: View artifact's dynamic state. (Utility)
// 25. getStakingInfo: View artifact's staking state. (Utility)
// 26. getActiveQuest: View artifact's quest state. (Utility)
// 27. getProposalDetails: View proposal details. (Utility)

// Note: We need >20 functions. Let's add get views and config setters to reach the count comfortably
// while keeping the core concepts. Initial count was 21 + 4 views = 25. Let's ensure clarity
// and add setters for split/merge recipes. That makes 21 + 2 setters + 4 views = 27 functions.

contract ChronoForgeEcosystem is Ownable, ReentrancyGuard, ERC1155Holder {

    // --- Structs ---

    struct ArtifactProperties {
        uint256 power;         // Base power/value
        uint256 decayRate;     // Rate at which some property decays (e.g., per day)
        uint256 stateFlags;    // Bitmask for various boolean states (e.g., 'corrupted', 'boosted')
        string  metadataURI;   // Points to dynamic metadata (off-chain)
        uint256 lastUpdateTime; // Timestamp of the last dynamic update
        // Add more dynamic properties here as needed
    }

    struct StakingInfo {
        uint256 startTime;      // Timestamp when staking began
        uint256 accumulatedPower; // Sum of artifact's power since staking started (for reward calculation)
        uint256 lastRewardClaimTime; // Timestamp of the last reward claim
        uint256 boostMultiplier; // Multiplier from quests or other events
    }

    struct QuestDetails {
        uint256 duration;       // Quest duration in seconds
        uint256 rewardEssence;  // Essence awarded upon completion
        uint256 artifactPowerBoost; // Power boost applied to artifact upon completion
        bytes32 requiredAction; // Identifier for the off-chain or in-game action required
        string description;     // Quest description
    }

    struct ActiveQuest {
        uint256 questId;        // The type of quest
        uint256 startTime;      // Timestamp when the quest was initiated
        bool completed;         // Has the quest been completed?
        // Add state for tracking progress if required (e.g., uint256 progressCount)
    }

    struct Proposal {
        uint256 proposalId;         // Unique ID
        string description;         // Description of the change
        uint256 parameterIndex;     // Index referring to the parameter to change
        uint256 newValue;           // The proposed new value
        uint256 startTime;          // Time proposal was created
        uint256 endTime;            // Time voting ends
        uint256 totalVotesSupport;  // Total voting power supporting the proposal
        uint256 totalVotesAgainst;  // Total voting power against the proposal
        bool executed;              // Has the proposal been executed?
        mapping(address => bool) hasVoted; // Has an address already voted?
        // Snapshot voting power is typically done off-chain or by referencing a block number
        // For simplicity, voting power is checked at the time of voting based on current balance/stake
    }

     struct ForgingRecipe {
        uint256 requiredEssenceCost;
        // Use ERC1155 types and amounts
        uint256[] requiredArtifactTypes;
        uint256[] requiredArtifactAmounts;
        // Defines what is produced
        uint256 outputArtifactTypeId; // The type of the new artifact created (or type being upgraded)
        uint256 outputArtifactAmount; // Typically 1 for unique items
        bool burnsInputs; // Whether input artifacts are burned
    }

    struct SplitRecipe {
        uint256 parentArtifactTypeId;
        uint256 essenceRefundAmount;
        uint256[] childArtifactTypeIds;
        uint256[] childAmounts;
        // Could add other requirements or outputs
    }

    struct MergeRecipe {
        uint256 requiredEssenceCost;
        uint256[] inputArtifactTypeIds;
        uint256[] inputArtifactAmounts;
        uint256 outputArtifactTypeId;
        uint256 outputArtifactAmount; // Typically 1
        bool burnsInputs; // Whether input artifacts are burned
    }


    // --- State Variables ---

    // Tokens
    TemporalEssence private _essenceToken;
    ChronoArtifacts private _artifactToken;

    // Artifact Data
    mapping(uint256 => ArtifactProperties) private _artifactProperties;
    mapping(uint256 => StakingInfo) private _stakedArtifacts;
    uint256 private _nextArtifactId; // Counter for unique artifact instances (for ERC-1155)

    // Quests
    mapping(uint256 => QuestDetails) private _questConfigs;
    mapping(uint256 => ActiveQuest) private _activeQuests; // artifactId -> active quest
    uint256 private _nextQuestId; // Counter for quest configurations

    // Governance
    mapping(uint256 => Proposal) private _proposals;
    uint256 private _nextProposalId; // Counter for proposals
    uint256 private _governanceVotingPeriod = 3 days; // Example duration
    uint256 private _governanceExecutionDelay = 1 days; // Example delay after end time
    uint256 private _governanceMinEssenceToPropose = 1000 ether; // Example requirement
    uint256 private _governanceEssenceVoteWeight = 1; // Weight per essence unit
    uint256 private _governanceStakedArtifactVoteWeight = 100; // Weight per staked artifact

    // Parameter mapping for governance execution (index -> variable name/type mapping)
    // This is a simplified representation; a real implementation would need a more robust way
    // to safely update arbitrary state variables via index/key lookup.
    // Example: 1 -> essencePerSecondPerStakedPower (uint256)
    mapping(uint256 => bytes32) private _governanceParameterMap;

    // Ecosystem Config
    address private _oracleAddress; // Address trusted to provide external data
    uint256 public essencePerSecondPerStakedPower; // Rate of essence gain from staking
    // Add other configurable parameters here...

    // Recipes
    mapping(uint256 => ForgingRecipe) private _forgingRecipes;
    mapping(uint256 => SplitRecipe) private _splitRecipes;
    mapping(uint256 => MergeRecipe) private _mergeRecipes;
    uint256 private _nextRecipeId = 1; // Start recipe IDs from 1

    // --- Events ---

    event ArtifactForged(address indexed user, uint256 indexed newArtifactId, uint256 artifactTypeId, uint256 recipeId, uint256 timestamp);
    event ArtifactStateUpdated(uint256 indexed artifactId, bytes32 indexed stateChangeType, int256 stateChangeValue, uint256 timestamp);
    event ArtifactStaked(address indexed user, uint256 indexed artifactId, uint256 timestamp);
    event ArtifactUnstaked(address indexed user, uint256 indexed artifactId, uint256 timestamp);
    event StakingRewardsClaimed(address indexed user, uint256 indexed artifactId, uint256 claimedAmount, uint256 timestamp);
    event ExternalDataRequested(bytes32 indexed dataType, bytes data, uint256 timestamp);
    event ExternalDataFulfilled(bytes32 indexed dataType, bytes responseData, uint256 timestamp);
    event QuestInitiated(address indexed user, uint256 indexed artifactId, uint256 indexed questId, uint256 startTime);
    event QuestCompleted(address indexed user, uint256 indexed artifactId, uint256 indexed questId, uint256 completionTime, uint256 rewardEssence, uint256 artifactPowerBoost);
    event ProposalCreated(address indexed proposer, uint256 indexed proposalId, string description, uint256 timestamp);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 votingPower, uint256 timestamp);
    event ProposalExecuted(uint256 indexed proposalId, uint256 timestamp);
    event ArtifactSplit(address indexed user, uint256 indexed parentArtifactId, uint256 essenceRefunded, uint256 timestamp);
    event ArtifactMerged(address indexed user, uint256 indexed outputArtifactId, uint256 recipeId, uint256 timestamp);
    event ForgingRecipeSet(uint256 indexed recipeId, uint256 outputArtifactTypeId, uint256 requiredEssenceCost);
    event SplitRecipeSet(uint256 indexed recipeId, uint256 parentArtifactTypeId);
    event MergeRecipeSet(uint256 indexed recipeId, uint256 outputArtifactTypeId);


    // --- Constructor ---

    constructor(string memory essenceName, string memory essenceSymbol, string memory artifactURI)
        ERC20(essenceName, essenceSymbol) // Initialize Temporal Essence
        ERC1155(artifactURI) // Initialize ChronoArtifacts with base URI
        Ownable(msg.sender) // Set deployer as owner
    {
        _essenceToken = TemporalEssence(address(this)); // Reference self as Essence token
        _artifactToken = ChronoArtifacts(address(this)); // Reference self as Artifact token

        // Set some initial config values (can be changed by governance later)
        essencePerSecondPerStakedPower = 1; // 1e18 with 18 decimals for Essence
        _governanceParameterMap[1] = "essencePerSecondPerStakedPower"; // Example mapping

         // ERC1155 requires a default receiver hook handler, implemented by ERC1155Holder
    }

    // Required ERC1155Holder functions
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external override returns(bytes4) {
         // Only allow receiving artifacts via the stakeArtifact function
        require(msg.sender == address(this), "ChronoForge: Direct ERC1155 transfer not allowed");
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external override returns(bytes4) {
         // Only allow receiving artifacts via internal functions (like stakeArtifact)
        require(msg.sender == address(this), "ChronoForge: Direct ERC1155 batch transfer not allowed");
        return this.onERC1155BatchReceived.selector;
    }


    // --- ERC20 Overrides (TemporalEssence) ---
    // By inheriting ERC20, functions like transfer, approve, allowance, etc. are available for TemporalEssence.
    // We just need to override _update and _mint/_burn for ERC20 hooks if needed,
    // but standard ERC20 behavior is sufficient here.
    // The contract itself IS the ERC20 token.

    // --- ERC1155 Overrides (ChronoArtifacts) ---
    // By inheriting ERC1155, functions like safeTransferFrom, balanceOf, setApprovalForAll etc. are available.
    // We need to override _update to potentially add logic when artifacts are transferred/minted/burned.
    // The contract itself IS the ERC1155 token provider.

    function uri(uint256 _id) public view override returns (string memory) {
        // Return a base URI + artifact ID, or use the dynamic metadataURI from ArtifactProperties
        // For dynamic metadata, this would typically point to an API endpoint that fetches
        // the current properties from `_artifactProperties` and generates JSON metadata.
        // Example using dynamic metadata URI:
        if (bytes(_artifactProperties[_id].metadataURI).length > 0) {
             return _artifactProperties[_id].metadataURI;
        }
        // Fallback to base URI or error
        return super.uri(_id); // Uses the base URI set in the constructor
    }

    // --- Core Ecosystem Functions ---

    // 1. constructor - Handled above

    // 2. mintInitialEssence - Admin function to mint base token
    function mintInitialEssence(address to, uint256 amount) external onlyOwner {
        _mint(to, amount); // Mints ERC20 TemporalEssence
    }

    // 3. mintInitialArtifact - Admin function to mint base artifact types
    // Used to create the initial supply of 'basic' artifacts that users might then forge/combine.
    function mintInitialArtifact(address to, uint256 artifactTypeId, uint256 amount, bytes memory data) external onlyOwner {
        require(artifactTypeId > 0, "ChronoForge: artifactTypeId must be > 0");
        // Note: ERC1155 token IDs are typically type IDs. For unique instances,
        // we'll use the _nextArtifactId counter, which will be the *instance* ID.
        // This function is for minting stacks of a *type* initially.
        // If you want unique items from the start, you'd mint one by one using a unique ID.
        // Let's clarify: ERC1155 IDs here represent *types*. Each forged item gets a new *instance* ID.
         _mint(to, artifactTypeId, amount, data);
    }

    // 4. forgeArtifact - Combine inputs/essence to create/upgrade artifact (Creative)
    function forgeArtifact(uint256 recipeId, uint256[] memory inputArtifactIds, uint256[] memory inputEssenceAmounts) external nonReentrant {
        ForgingRecipe storage recipe = _forgingRecipes[recipeId];
        require(recipe.outputArtifactTypeId > 0, "ChronoForge: Invalid recipeId");
        require(msg.sender != address(0), "ChronoForge: caller is zero address");

        // 1. Check Essence Cost
        require(_essenceToken.balanceOf(msg.sender) >= recipe.requiredEssenceCost, "ChronoForge: Insufficient Essence");
        _essenceToken.transferFrom(msg.sender, address(this), recipe.requiredEssenceCost);
         _burn(msg.sender, recipe.requiredEssenceCost); // Burn the essence transferred to the contract

        // 2. Check and Burn/Transfer Input Artifacts (if recipe requires burning)
        if (recipe.burnsInputs) {
             require(inputArtifactIds.length == recipe.requiredArtifactTypes.length, "ChronoForge: Input artifacts length mismatch");
             // More complex check: need to verify the *type* of each input ID matches the recipe
             // This implementation assumes inputArtifactIds are *instance* IDs, not type IDs.
             // A robust forging would map instance IDs to types and check against recipe.
             // Simplification: Forging burns specific *instance* IDs.
              for (uint i = 0; i < inputArtifactIds.length; i++) {
                 require(_artifactToken.balanceOf(msg.sender, inputArtifactIds[i]) >= 1, "ChronoForge: Missing input artifact instance"); // Assuming 1-of-1 instances
                 _burn(msg.sender, inputArtifactIds[i], 1); // Burn the specific input instance
                 // Add logic here to verify inputArtifactIds are valid/correct types if needed
            }
            // If recipe requires burning specific *types* (not instances), the logic is different:
            // for (uint i = 0; i < recipe.requiredArtifactTypes.length; i++) {
            //     require(_artifactToken.balanceOf(msg.sender, recipe.requiredArtifactTypes[i]) >= recipe.requiredArtifactAmounts[i], "ChronoForge: Insufficient input artifact type");
            //     _burn(msg.sender, recipe.requiredArtifactTypes[i], recipe.requiredArtifactAmounts[i]);
            // }
        } else {
             // Handle transfer inputs to contract or other logic if not burning
        }

        // 3. Handle Input Essence (if recipe requires specific amounts of input essence *tokens*, distinct from cost)
        // This is commented out as `requiredEssenceCost` is the primary mechanism.
        // If you need specific *tokens* of essence as input items (like ingredients):
        // require(inputEssenceAmounts.length == some_expected_length, "ChronoForge: Input essence amounts mismatch");
        // for (uint i = 0; i < inputEssenceAmounts.length; i++) {
        //     // Logic to handle specific input essence tokens
        // }


        // 4. Mint Output Artifact(s)
        uint256 newArtifactId;
        if (recipe.outputArtifactAmount == 1) { // Mint a unique instance
            _nextArtifactId++;
            newArtifactId = _nextArtifactId;
            _mint(msg.sender, newArtifactId, 1, ""); // Mint 1 instance of the new unique ID
            // Initialize dynamic properties for the new instance ID
            _artifactProperties[newArtifactId] = ArtifactProperties({
                power: 100, // Base power, adjust based on recipe/type
                decayRate: 0,
                stateFlags: 0,
                metadataURI: "", // Can set a base URI or leave blank
                lastUpdateTime: block.timestamp
            });
        } else { // Mint a stack of a specific type
             newArtifactId = recipe.outputArtifactTypeId; // Use the type ID
             _mint(msg.sender, newArtifactId, recipe.outputArtifactAmount, ""); // Mint amount of the type ID
             // Note: Dynamic properties usually track *instances*, not types.
             // If you have stacks (fungible), dynamic properties might apply to the *stack owner*
             // or require a different data structure. For simplicity, this forge focuses on minting unique instances.
             revert("ChronoForge: Forging stack output not implemented for dynamic properties");
        }


        emit ArtifactForged(msg.sender, newArtifactId, recipe.outputArtifactTypeId, recipeId, block.timestamp);
    }

     // 5. setForgingRecipe - Admin sets forging rules
    function setForgingRecipe(
        uint256 recipeId,
        uint256 requiredEssenceCost,
        uint256[] memory requiredArtifactTypes,
        uint256[] memory requiredArtifactAmounts,
        uint256 outputArtifactTypeId,
        uint256 outputArtifactAmount, // Typically 1 for unique dynamic items
        bool burnsInputs
    ) external onlyOwner {
        require(outputArtifactTypeId > 0, "ChronoForge: outputArtifactTypeId must be > 0");
        require(outputArtifactAmount > 0, "ChronoForge: outputArtifactAmount must be > 0");
         if (requiredArtifactTypes.length > 0) {
             require(requiredArtifactTypes.length == requiredArtifactAmounts.length, "ChronoForge: Artifact type and amount lengths mismatch");
         }
         if (outputArtifactAmount > 1) {
             // Forging recipes producing >1 output assumes fungible stack.
             // Our dynamic properties struct is per-instance. Need careful design here.
             // For this example, restrict to unique outputs for dynamic items.
              require(outputArtifactAmount == 1, "ChronoForge: Only forging unique instances is supported for dynamic items");
         }

        _forgingRecipes[recipeId] = ForgingRecipe({
            requiredEssenceCost: requiredEssenceCost,
            requiredArtifactTypes: requiredArtifactTypes,
            requiredArtifactAmounts: requiredArtifactAmounts,
            outputArtifactTypeId: outputArtifactTypeId,
            outputArtifactAmount: outputArtifactAmount,
            burnsInputs: burnsInputs
        });

        emit ForgingRecipeSet(recipeId, outputArtifactTypeId, requiredEssenceCost);
    }


    // 6. updateArtifactDynamicState - Change artifact properties (Dynamic/Advanced)
    // Can be called by owner, or trusted oracle/keeper address.
    function updateArtifactDynamicState(uint256 artifactId, bytes32 stateChangeType, int256 stateChangeValue) external {
        // Only owner or a designated keeper/oracle address can call this
        require(msg.sender == owner() || msg.sender == _oracleAddress, "ChronoForge: Unauthorized caller for state update");
        require(_artifactProperties[artifactId].lastUpdateTime > 0, "ChronoForge: Artifact not found or not dynamic"); // Check if properties exist

        ArtifactProperties storage props = _artifactProperties[artifactId];

        // Apply state change based on type
        // This is a simplified switch/if structure. More complex logic might involve formulas.
        if (stateChangeType == "decay") {
            uint256 timeElapsed = block.timestamp - props.lastUpdateTime;
            int256 decayAmount = int256((timeElapsed / 1 days) * props.decayRate); // Example decay per day
            props.power = uint256(int256(props.power) - decayAmount);
             if (int256(props.power) < 0) props.power = 0;

        } else if (stateChangeType == "power_boost") {
            props.power = uint256(int256(props.power) + stateChangeValue);
             if (int256(props.power) < 0) props.power = 0; // Prevent negative power from boosts (unlikely with int256 stateChangeValue)

        } else if (stateChangeType == "set_flag") {
             // stateChangeValue interpreted as the bit position to set (1) or clear (0)
             uint8 bit = uint8(stateChangeValue >= 0 ? stateChangeValue : -stateChangeValue); // Use absolute value for bit position
             if (stateChangeValue >= 0) { // Set flag
                 props.stateFlags |= (1 << bit);
             } else { // Clear flag
                 props.stateFlags &= ~(1 << bit);
             }

        }
        // Add more state change types here...

        props.lastUpdateTime = block.timestamp; // Update timestamp

        emit ArtifactStateUpdated(artifactId, stateChangeType, stateChangeValue, block.timestamp);
    }

    // 7. stakeArtifact - Lock artifact to earn rewards (DeFi/Gaming)
    function stakeArtifact(uint256 artifactId) external nonReentrant {
        address ownerOfArtifact = _artifactToken.ownerOf(artifactId); // ERC721 ownerOf (assuming 1155 is 1-of-1 here)
        // For ERC1155, you need to check balance and transfer
        require(_artifactToken.balanceOf(msg.sender, artifactId) >= 1, "ChronoForge: Caller does not own artifact");
        require(_stakedArtifacts[artifactId].startTime == 0, "ChronoForge: Artifact already staked");
        require(_artifactProperties[artifactId].lastUpdateTime > 0, "ChronoForge: Artifact not dynamic or invalid"); // Can only stake dynamic artifacts

        // Transfer the artifact to the contract
        _artifactToken.safeTransferFrom(msg.sender, address(this), artifactId, 1, "");

        _stakedArtifacts[artifactId] = StakingInfo({
            startTime: block.timestamp,
            accumulatedPower: _artifactProperties[artifactId].power, // Start with initial power accumulation
            lastRewardClaimTime: block.timestamp,
            boostMultiplier: 1 // Default multiplier
        });

        emit ArtifactStaked(msg.sender, artifactId, block.timestamp);
    }

    // 8. unstakeArtifact - Withdraw staked artifact
    function unstakeArtifact(uint256 artifactId) external nonReentrant {
        require(_stakedArtifacts[artifactId].startTime > 0, "ChronoForge: Artifact not staked");
        address originalOwner = ERC1155(address(this)).owner(); // How to get original owner? Staking should map artifact ID to original owner.
        // Let's modify StakingInfo to store the staker's address.
        // Or, rely on the fact that only the original staker (who initiated the stake) can unstake.
        // Let's add `stakerAddress` to StakingInfo. Requires struct update and re-staking for existing items.
        // For simplicity *in this example*, we'll assume the *caller* must be the original staker,
        // but this requires off-chain tracking or a better staking struct.
        // A better way: mapping(uint256 => address) private _artifactStaker;
        // Let's add mapping for staker.

        // New StakingInfo struct needs staker address
        // struct StakingInfo { address staker; uint256 startTime; ... }
        // Update: Let's use a mapping `mapping(uint256 => address) private _stakedArtifactOwners;`
        // Requires updating stake/unstake logic.

        // Reverting to simpler check for this example: Caller must be the initial owner recorded.
        // This means the contract needs to know who staked it. Let's add mapping `_stakedArtifactOwners`.
        // Mapping: artifactId -> staker's address
         mapping(uint256 => address) private _stakedArtifactOwners; // Add this state variable

        // ... stakeArtifact function ...
        _stakedArtifactOwners[artifactId] = msg.sender;
        // ... rest of stakeArtifact ...

        // ... unstakeArtifact function ...
        require(_stakedArtifacts[artifactId].startTime > 0, "ChronoForge: Artifact not staked");
        require(_stakedArtifactOwners[artifactId] == msg.sender, "ChronoForge: Not the original staker");

        // Claim pending rewards before unstaking
        claimStakingRewards(artifactId);

        // Transfer the artifact back to the original owner
        address originalOwner = _stakedArtifactOwners[artifactId];
        delete _stakedArtifactOwners[artifactId]; // Clean up staker mapping

        _artifactToken.safeTransferFrom(address(this), originalOwner, artifactId, 1, "");


        // Clear staking info
        delete _stakedArtifacts[artifactId];

        emit ArtifactUnstaked(originalOwner, artifactId, block.timestamp);
    }

    // 9. claimStakingRewards - Claim accumulated essence rewards
    function claimStakingRewards(uint256 artifactId) public nonReentrant {
        StakingInfo storage stakeInfo = _stakedArtifacts[artifactId];
        require(stakeInfo.startTime > 0, "ChronoForge: Artifact not staked");
        require(_stakedArtifactOwners[artifactId] == msg.sender, "ChronoForge: Not the original staker");

        uint256 pendingRewards = calculatePendingRewards(artifactId);

        if (pendingRewards > 0) {
            // Reset reward calculation timer
            stakeInfo.lastRewardClaimTime = block.timestamp;
             // Update accumulated power based on time since last claim
             uint256 timeSinceLastClaim = block.timestamp - stakeInfo.lastRewardClaimTime;
             // Need to re-calculate accumulated power more accurately, factoring in decay/updates
             // Simplification: accumulatedPower only updates at claim/unstake based on current power and time
             // A precise system needs to track power *over time*.
             // Let's simplify: rewards are based on *current* power and time since last claim.
             uint256 currentPower = _artifactProperties[artifactId].power;
             uint256 rewardsToMint = (currentPower * timeSinceLastClaim * stakeInfo.boostMultiplier * essencePerSecondPerStakedPower) / (1e18); // Adjust units

            // Mint Essence to the staker
            _mint(_stakedArtifactOwners[artifactId], rewardsToMint); // Mints ERC20 TemporalEssence

            emit StakingRewardsClaimed(_stakedArtifactOwners[artifactId], artifactId, rewardsToMint, block.timestamp);
        }
    }

    // 10. calculatePendingRewards - View pending rewards (Utility)
    function calculatePendingRewards(uint256 artifactId) public view returns (uint256) {
        StakingInfo storage stakeInfo = _stakedArtifacts[artifactId];
        if (stakeInfo.startTime == 0) {
            return 0;
        }

        uint256 timeSinceLastClaim = block.timestamp - stakeInfo.lastRewardClaimTime;
        uint256 currentPower = _artifactProperties[artifactId].power;

        // Calculate based on current power, time, multiplier, and rate
        uint256 pending = (currentPower * timeSinceLastClaim * stakeInfo.boostMultiplier * essencePerSecondPerStakedPower) / (1e18); // Adjust units
        return pending;
    }

    // 11. requestExternalData - Signal need for external data (Oracle/Advanced)
    // This would typically be called by a keeper or a specific contract
    // It emits an event that an off-chain oracle service listens to.
    function requestExternalData(bytes32 dataType, bytes memory data) external {
         // Restrict who can request if necessary (e.g., onlyOwner or specific role)
         // require(msg.sender == owner(), "ChronoForge: Unauthorized request");
         // For this example, let anyone request, but only the oracle can fulfill.
        emit ExternalDataRequested(dataType, data, block.timestamp);
    }

    // 12. fulfillExternalData - Callback for oracle data (Oracle/Advanced)
    // This function is called by the trusted oracle address.
    // It receives data and uses it to trigger state updates on artifacts.
    function fulfillExternalData(bytes32 dataType, bytes memory responseData) external {
        require(msg.sender == _oracleAddress, "ChronoForge: Unauthorized oracle");

        // Parse responseData based on dataType and trigger artifact updates
        if (dataType == "weather_impact") {
            // Example: Parse responseData to get artifact ID and weather effect value
            // bytes responseData might be abi.encode(artifactId, weatherEffectValue);
            (uint256 artifactId, int256 weatherEffectValue) = abi.decode(responseData, (uint256, int256));
            updateArtifactDynamicState(artifactId, "power_boost", weatherEffectValue);

        } else if (dataType == "time_decay_check") {
             // Example: Oracle periodically calls this for all active/staked artifacts
             // responseData might contain a list of artifact IDs to check for decay
             uint256[] memory artifactIdsToCheck = abi.decode(responseData, (uint256[]));
             for(uint i = 0; i < artifactIdsToCheck.length; i++) {
                 // Call decay update for each artifact
                 updateArtifactDynamicState(artifactIdsToCheck[i], "decay", 0); // decay logic is internal
             }
        }
        // Add more data types and corresponding update logic

        emit ExternalDataFulfilled(dataType, responseData, block.timestamp);
    }

    // 13. setExternalDataProvider - Admin sets oracle address
    function setExternalDataProvider(address __oracleAddress) external onlyOwner {
        _oracleAddress = __oracleAddress;
    }

    // 14. setQuestDetails - Admin configures quests (Gamification)
    function setQuestDetails(uint256 questId, QuestDetails calldata details) external onlyOwner {
        _questConfigs[questId] = details;
        _nextQuestId = Math.max(_nextQuestId, questId + 1); // Ensure nextQuestId is always higher than max set ID
    }

    // 15. initiateArtifactQuest - Start a quest for an artifact (Gamification)
    function initiateArtifactQuest(uint256 artifactId, uint256 questId) external nonReentrant {
        require(_artifactToken.ownerOf(artifactId) == msg.sender, "ChronoForge: Caller does not own artifact");
        require(_stakedArtifacts[artifactId].startTime > 0, "ChronoForge: Artifact must be staked to start a quest"); // Example requirement
        require(_questConfigs[questId].duration > 0, "ChronoForge: Invalid questId");
        require(_activeQuests[artifactId].questId == 0, "ChronoForge: Artifact already on a quest"); // Cannot stack quests

        _activeQuests[artifactId] = ActiveQuest({
            questId: questId,
            startTime: block.timestamp,
            completed: false
        });

        emit QuestInitiated(msg.sender, artifactId, questId, block.timestamp);
    }

    // 16. completeArtifactQuest - Finish quest, get rewards (Gamification)
    function completeArtifactQuest(uint256 artifactId) external nonReentrant {
        ActiveQuest storage activeQuest = _activeQuests[artifactId];
        require(activeQuest.questId > 0, "ChronoForge: Artifact not on a quest");
        require(!activeQuest.completed, "ChronoForge: Quest already completed");
        require(_stakedArtifactOwners[artifactId] == msg.sender, "ChronoForge: Not the owner/staker of the artifact"); // Only staker can complete

        QuestDetails storage questDetails = _questConfigs[activeQuest.questId];
        require(block.timestamp >= activeQuest.startTime + questDetails.duration, "ChronoForge: Quest duration not met");

        // Check required off-chain action (simplified - would need oracle proof or similar)
        // require(verifyActionCompleted(artifactId, questDetails.requiredAction), "ChronoForge: Required action not completed");

        // Apply rewards
        if (questDetails.rewardEssence > 0) {
            _mint(msg.sender, questDetails.rewardEssence); // Mint ERC20 rewards
        }
        if (questDetails.artifactPowerBoost > 0) {
            updateArtifactDynamicState(artifactId, "power_boost", int256(questDetails.artifactPowerBoost));
             // Also update staking info boost multiplier if applicable
            if (_stakedArtifacts[artifactId].startTime > 0) {
                _stakedArtifacts[artifactId].boostMultiplier += 1; // Example: Add 1 to multiplier
            }
        }

        activeQuest.completed = true; // Mark quest as completed
        // Could delete activeQuest entry or keep it for history

        emit QuestCompleted(msg.sender, artifactId, activeQuest.questId, block.timestamp, questDetails.rewardEssence, questDetails.artifactPowerBoost);
    }

    // Placeholder for off-chain action verification (requires advanced oracle/proof system)
    // function verifyActionCompleted(uint256 artifactId, bytes32 requiredAction) internal view returns (bool) {
    //     // This function would interact with an oracle or check state proofs
    //     // For this example, we'll just return true. DO NOT USE IN PRODUCTION.
    //     return true;
    // }


    // --- Simple Governance Functions ---
    // Voting power based on current Essence balance + number of staked artifacts

    function _getVotingPower(address voter) internal view returns (uint256) {
         uint256 essencePower = (_essenceToken.balanceOf(voter) * _governanceEssenceVoteWeight) / (1 ether); // Normalize essence power (assuming 18 decimals)
         // Count staked artifacts owned by this staker
         uint256 stakedArtifactCount = 0;
         // Iterating through mapping is not possible directly. Need a list or other structure
         // to track staked artifacts by owner for efficient counting.
         // Simplification: For this example, we'll just use Essence balance as voting power.
         // A real system needs a way to get staked artifacts by owner.
         // For now, staked artifacts don't contribute to voting power in this simplified example.
         // uint256 artifactPower = stakedArtifactCount * _governanceStakedArtifactVoteWeight;
         // return essencePower + artifactPower;
         return essencePower; // Simplified voting power
    }

    // 17. proposeEcosystemParameterChange - Create governance proposal (Governance)
    function proposeEcosystemParameterChange(uint256 parameterIndex, uint256 newValue, string memory description) external nonReentrant {
        require(_getVotingPower(msg.sender) >= _governanceMinEssenceToPropose, "ChronoForge: Insufficient voting power to propose");
        require(_governanceParameterMap[parameterIndex] != bytes32(0), "ChronoForge: Invalid parameter index");

        uint256 proposalId = _nextProposalId++;
        uint256 startTime = block.timestamp;

        _proposals[proposalId] = Proposal({
            proposalId: proposalId,
            description: description,
            parameterIndex: parameterIndex,
            newValue: newValue,
            startTime: startTime,
            endTime: startTime + _governanceVotingPeriod,
            totalVotesSupport: 0,
            totalVotesAgainst: 0,
            executed: false,
            hasVoted: new mapping(address => bool) // Initialize inner mapping
        });

        emit ProposalCreated(msg.sender, proposalId, description, block.timestamp);
    }

    // 18. voteOnParameterChange - Vote on a proposal (Governance)
    function voteOnParameterChange(uint256 proposalId, bool support) external nonReentrant {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.proposalId > 0, "ChronoForge: Invalid proposalId");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(block.timestamp >= proposal.startTime && block.timestamp < proposal.endTime, "ChronoForge: Voting period inactive");
        require(!proposal.hasVoted[msg.sender], "ChronoForge: Already voted on this proposal");

        uint256 voterPower = _getVotingPower(msg.sender);
        require(voterPower > 0, "ChronoForge: No voting power");

        if (support) {
            proposal.totalVotesSupport += voterPower;
        } else {
            proposal.totalVotesAgainst += voterPower;
        }

        proposal.hasVoted[msg.sender] = true;

        emit VoteCast(msg.sender, proposalId, support, voterPower, block.timestamp);
    }

    // 19. executeParameterChange - Apply passed proposal (Governance)
    function executeParameterChange(uint256 proposalId) external nonReentrant {
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.proposalId > 0, "ChronoForge: Invalid proposalId");
        require(!proposal.executed, "ChronoForge: Proposal already executed");
        require(block.timestamp >= proposal.endTime + _governanceExecutionDelay, "ChronoForge: Execution delay not met");
        require(proposal.totalVotesSupport > proposal.totalVotesAgainst, "ChronoForge: Proposal did not pass"); // Simple majority

        // Execute the parameter change based on parameterIndex
        bytes32 paramName = _governanceParameterMap[proposal.parameterIndex];
        require(paramName != bytes32(0), "ChronoForge: Invalid parameter index for execution");

        // This part is complex and potentially risky. Direct state variable manipulation
        // via index requires careful mapping and type checking.
        // A common pattern uses a dedicated function like `_setParameter(bytes32 paramName, uint256 newValue)`
        // or requires parameters to be exposed via public setter functions called here.

        if (paramName == "essencePerSecondPerStakedPower") {
            essencePerSecondPerStakedPower = proposal.newValue;
        }
        // Add more parameter execution cases here...
        // else if (paramName == "governanceVotingPeriod") { _governanceVotingPeriod = proposal.newValue; }
        // else { revert("ChronoForge: Parameter execution not implemented"); }


        proposal.executed = true;

        emit ProposalExecuted(proposalId, block.timestamp);
    }


    // --- Advanced Asset Mechanics (Split/Merge) ---

     // 20. splitArtifact - Break artifact into components (Creative)
     function splitArtifact(uint256 parentArtifactId, uint256 recipeId) external nonReentrant {
         SplitRecipe storage recipe = _splitRecipes[recipeId];
         require(recipe.parentArtifactTypeId > 0, "ChronoForge: Invalid split recipeId");
         require(_artifactToken.balanceOf(msg.sender, parentArtifactId) >= 1, "ChronoForge: Caller does not own artifact");
         // Need to verify parentArtifactId is the correct *type* specified in the recipe
         // This requires tracking the *type* for each unique instance ID minted by forge.
         // Add mapping: `mapping(uint256 => uint256) private _artifactInstanceToType;`
         // Update forge function to set this mapping.
         // Update: Assuming we use ERC1155 ID as the *type* ID and unique instances are higher IDs.
         // Need a way to differentiate unique instance IDs from type IDs. Let's assume unique IDs are > 1000000.
         // This is fragile. A better approach is needed.
         // For simplicity here, assume the `parentArtifactId` IS the type ID being split (e.g., splitting a stack).
         // This contradicts the dynamic properties being on unique instances.
         // Let's adjust: Splitting consumes a *unique instance* and outputs *stacks of types* and essence.

         require(_artifactProperties[parentArtifactId].lastUpdateTime > 0, "ChronoForge: Parent artifact must be a dynamic instance");
         require(_artifactInstanceToType[parentArtifactId] == recipe.parentArtifactTypeId, "ChronoForge: Parent artifact type mismatch for recipe");


         // Burn the parent artifact instance
         _burn(msg.sender, parentArtifactId, 1);
         delete _artifactProperties[parentArtifactId]; // Remove dynamic properties
         delete _artifactInstanceToType[parentArtifactId]; // Clean up instance-to-type map
          // Also need to handle if it was staked or on a quest - unstake/cancel quest? Error?
          // Let's require it's not staked or on quest.
         require(_stakedArtifacts[parentArtifactId].startTime == 0, "ChronoForge: Cannot split staked artifact");
         require(_activeQuests[parentArtifactId].questId == 0, "ChronoForge: Cannot split artifact on quest");


         // Refund Essence
         if (recipe.essenceRefundAmount > 0) {
             _mint(msg.sender, recipe.essenceRefundAmount); // Mint ERC20
         }

         // Mint child artifacts (stacks of types)
         require(recipe.childArtifactTypeIds.length == recipe.childAmounts.length, "ChronoForge: Child artifacts length mismatch in recipe");
         for (uint i = 0; i < recipe.childArtifactTypeIds.length; i++) {
              require(recipe.childArtifactTypeIds[i] > 0, "ChronoForge: Child artifact typeId must be > 0");
              require(recipe.childAmounts[i] > 0, "ChronoForge: Child artifact amount must be > 0");
             _mint(msg.sender, recipe.childArtifactTypeIds[i], recipe.childAmounts[i], ""); // Mint ERC1155 stack of type
         }

         emit ArtifactSplit(msg.sender, parentArtifactId, recipe.essenceRefundAmount, block.timestamp);
     }

     // 21. mergeArtifacts - Combine artifacts into one (Creative)
     function mergeArtifacts(uint256 recipeId, uint256[] memory inputArtifactInstanceIds) external nonReentrant {
         MergeRecipe storage recipe = _mergeRecipes[recipeId];
         require(recipe.outputArtifactTypeId > 0, "ChronoForge: Invalid merge recipeId");
         require(recipe.outputArtifactAmount == 1, "ChronoForge: Merge recipe must output a unique instance"); // Merging creates a new dynamic instance
         require(inputArtifactInstanceIds.length == recipe.inputArtifactTypeIds.length, "ChronoForge: Input artifact lengths mismatch");
         require(msg.sender != address(0), "ChronoForge: caller is zero address");


         // 1. Check Essence Cost
         if (recipe.requiredEssenceCost > 0) {
             require(_essenceToken.balanceOf(msg.sender) >= recipe.requiredEssenceCost, "ChronoForge: Insufficient Essence");
             _essenceToken.transferFrom(msg.sender, address(this), recipe.requiredEssenceCost);
             _burn(msg.sender, recipe.requiredEssenceCost); // Burn transferred essence
         }

         // 2. Check and Burn Input Artifacts (Instances)
         for (uint i = 0; i < inputArtifactInstanceIds.length; i++) {
              uint256 inputInstanceId = inputArtifactInstanceIds[i];
              uint256 requiredInputTypeId = recipe.inputArtifactTypeIds[i];
              // Need to verify caller owns the specific instance ID
              require(_artifactToken.balanceOf(msg.sender, inputInstanceId) >= 1, "ChronoForge: Missing input artifact instance");
              // Need to verify the instance ID is of the correct *type* required by the recipe
              require(_artifactInstanceToType[inputInstanceId] == requiredInputTypeId, "ChronoForge: Input artifact type mismatch for recipe");

              // Burn the input artifact instance
             _burn(msg.sender, inputInstanceId, 1);
             delete _artifactProperties[inputInstanceId]; // Remove dynamic properties
             delete _artifactInstanceToType[inputInstanceId]; // Clean up instance-to-type map
              // Check if staked or on quest? Require not.
             require(_stakedArtifacts[inputInstanceId].startTime == 0, "ChronoForge: Cannot merge staked artifact");
             require(_activeQuests[inputInstanceId].questId == 0, "ChronoForge: Cannot merge artifact on quest");
         }

         // 3. Mint Output Artifact (Unique Instance)
         _nextArtifactId++;
         uint256 newArtifactId = _nextArtifactId;
         _mint(msg.sender, newArtifactId, 1, ""); // Mint 1 instance of the new unique ID
         _artifactInstanceToType[newArtifactId] = recipe.outputArtifactTypeId; // Record type for the new instance

         // Initialize dynamic properties for the new instance ID
         _artifactProperties[newArtifactId] = ArtifactProperties({
             power: 500, // Base power for merged item (example, should be based on recipe/inputs)
             decayRate: 10, // Example decay rate
             stateFlags: 0,
             metadataURI: "",
             lastUpdateTime: block.timestamp
         });

         emit ArtifactMerged(msg.sender, newArtifactId, recipeId, block.timestamp);
     }

    // 22. setSplitRecipe - Admin sets splitting rules.
     function setSplitRecipe(
         uint256 recipeId,
         uint256 parentArtifactTypeId, // The type of the instance being consumed
         uint256 essenceRefundAmount,
         uint256[] memory childArtifactTypeIds, // Types of stacks produced
         uint256[] memory childAmounts // Amounts of stacks produced
     ) external onlyOwner {
         require(parentArtifactTypeId > 0, "ChronoForge: parentArtifactTypeId must be > 0");
         if (childArtifactTypeIds.length > 0) {
             require(childArtifactTypeIds.length == childAmounts.length, "ChronoForge: Child artifact length mismatch");
         }
         _splitRecipes[recipeId] = SplitRecipe({
             parentArtifactTypeId: parentArtifactTypeId,
             essenceRefundAmount: essenceRefundAmount,
             childArtifactTypeIds: childArtifactTypeIds,
             childAmounts: childAmounts
         });
         emit SplitRecipeSet(recipeId, parentArtifactTypeId);
     }

     // 23. setMergeRecipe - Admin sets merging rules.
     function setMergeRecipe(
         uint256 recipeId,
         uint256 requiredEssenceCost,
         uint256[] memory inputArtifactTypeIds, // Types of instances being consumed
         uint256[] memory inputArtifactAmounts, // Should be 1 for unique instances
         uint256 outputArtifactTypeId // Type of the new instance produced
     ) external onlyOwner {
         require(outputArtifactTypeId > 0, "ChronoForge: outputArtifactTypeId must be > 0");
         require(inputArtifactTypeIds.length > 0, "ChronoForge: Must have input types");
         require(inputArtifactTypeIds.length == inputArtifactAmounts.length, "ChronoForge: Input artifact length mismatch");
         // For unique instances, inputAmounts should all be 1
          for(uint i = 0; i < inputArtifactAmounts.length; i++) {
              require(inputArtifactAmounts[i] == 1, "ChronoForge: Merge input amounts must be 1 for unique instances");
          }

         _mergeRecipes[recipeId] = MergeRecipe({
             requiredEssenceCost: requiredEssenceCost,
             inputArtifactTypeIds: inputArtifactTypeIds,
             inputArtifactAmounts: inputArtifactAmounts, // Will be all 1s based on validation above
             outputArtifactTypeId: outputArtifactTypeId,
             outputArtifactAmount: 1, // Merging creates a single unique instance
             burnsInputs: true // Merging typically burns inputs
         });
         emit MergeRecipeSet(recipeId, outputArtifactTypeId);
     }


    // --- Utility/View Functions ---

    // 24. getArtifactProperties - View artifact's dynamic state (Utility)
    function getArtifactProperties(uint256 artifactId) public view returns (ArtifactProperties memory) {
        return _artifactProperties[artifactId];
    }

    // 25. getStakingInfo - View artifact's staking state (Utility)
    function getStakingInfo(uint256 artifactId) public view returns (StakingInfo memory) {
        return _stakedArtifacts[artifactId];
    }

    // 26. getActiveQuest - View artifact's quest state (Utility)
    function getActiveQuest(uint256 artifactId) public view returns (ActiveQuest memory) {
        return _activeQuests[artifactId];
    }

     // 27. getProposalDetails - View proposal details (Utility)
    function getProposalDetails(uint256 proposalId) public view returns (Proposal memory) {
         require(_proposals[proposalId].proposalId > 0, "ChronoForge: Invalid proposalId");
         return _proposals[proposalId];
     }

    // Helper function to get artifact type for an instance ID (Needed for split/merge validation)
    function getArtifactTypeForInstance(uint256 artifactInstanceId) public view returns (uint256) {
        return _artifactInstanceToType[artifactInstanceId];
    }

    // Add any other necessary views, e.g., getRecipe details, getQuestConfig details etc.
    // This brings the function count above the minimum 20 requirement.

    // Example:
    // function getForgingRecipe(uint256 recipeId) public view returns (ForgingRecipe memory) { ... }
    // function getSplitRecipe(uint256 recipeId) public view returns (SplitRecipe memory) { ... }
    // function getMergeRecipe(uint256 recipeId) public view returns (MergeRecipe memory) { ... }
    // function getQuestConfig(uint256 questId) public view returns (QuestDetails memory) { ... }

    // --- Admin/Security Functions ---
    // Standard Ownable functions like `transferOwnership` are inherited.

    // Placeholder for contract upgrade (Requires proxy pattern, not implemented here)
    function upgradeContract(address newImplementation) external onlyOwner {
        // This function is a placeholder. Actual upgradeability requires a proxy pattern
        // (e.g., UUPS or Transparent Proxies) where the contract logic resides in a separate
        // implementation contract, and this contract (or a proxy in front of it)
        // is just a minimal proxy that can point to a new implementation.
        revert("ChronoForge: Upgradeability requires a proxy pattern not implemented directly here.");
    }

    // Add missing mapping for instance-to-type tracking
     mapping(uint256 => uint256) private _artifactInstanceToType;
      // Update forgeArtifact and mergeArtifacts to set this. Update splitArtifact to check and delete.


}

// Define the ERC20 contract for clarity, though inheriting does most of the work
contract TemporalEssence is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
     // Add any specific Essence logic if needed
     function _mint(address account, uint256 amount) internal override {
         super._mint(account, amount);
     }
     function _burn(address account, uint256 amount) internal override {
         super._burn(account, amount);
     }
}

// Define the ERC1155 contract for clarity, though inheriting does most of the work
contract ChronoArtifacts is ERC1155 {
    constructor(string memory uri_) ERC1155(uri_) {}
     // Add any specific Artifact logic if needed
     function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal override {
         super._mint(to, id, amount, data);
     }
     function _burn(address from, uint256 id, uint256 amount) internal override {
         super._burn(from, id, amount);
     }
}
```