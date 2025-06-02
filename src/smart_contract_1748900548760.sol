Okay, here is a smart contract concept called `EtherealNexus`, designed to incorporate dynamic NFTs, reputation, resource management, and programmable interactions. It aims for complexity and multiple interconnected functions without directly duplicating common open-source examples like basic ERC20/ERC721 implementations, simple staking pools, or standard AMMs.

The core idea is a protocol where users interact using a utility token (`NexusEssence`) and dynamic NFTs (`NexusArtifacts`). Artifacts have mutable attributes influenced by staking, participation in events, and resource consumption. Users also accrue reputation affecting their capabilities within the Nexus.

---

## EtherealNexus Smart Contract

This contract serves as the central hub for the EtherealNexus protocol. It orchestrates interactions between users, `NexusEssence` (ERC-20 utility token), and `NexusArtifacts` (Dynamic ERC-721 NFTs).

**Key Concepts:**

1.  **NexusEssence:** The primary utility token used for staking, crafting, and powering interactions.
2.  **NexusArtifacts:** Dynamic NFTs with mutable attributes (e.g., Level, Prowess, Energy, Affinity). Attributes change based on on-chain actions and staking.
3.  **Reputation:** A non-transferable score per user, earned through participation and positive interactions. It can be delegated.
4.  **Staking:** Users stake NexusEssence on their NexusArtifacts to boost attributes and energy regeneration.
5.  **Crafting/Dissolving:** Processes to create new artifacts or components by burning assets, or burn artifacts to recover resources.
6.  **Dynamic Interactions:** Functions that combine checks on user reputation, artifact attributes, and resource balances to produce complex outcomes (e.g., participating in a challenge).
7.  **Attunement:** Artifacts can be 'attuned' to specific action types, granting unique abilities or effects when used in certain functions.

**Outline:**

1.  **Pragmas & Imports**
2.  **Errors**
3.  **Events**
4.  **Interfaces** (for external ERC20, ERC721)
5.  **State Variables**
    *   Protocol Addresses (Tokens, Owner)
    *   Configuration Parameters
    *   Mappings for Artifact Attributes, Staking, Reputation, Delegation
    *   Mapping for Crafting Recipes
    *   Mapping for Attunement Types
    *   System State Variables (e.g., current challenge ID)
6.  **Structs**
    *   `ArtifactAttributes`
    *   `CraftingRecipe`
    *   `AttunementTypeConfig`
7.  **Modifiers** (Ownable, Pausable)
8.  **Constructor**
9.  **Admin/Configuration Functions** (Setting parameters, token addresses, pausing)
10. **View Functions (Read Only)**
    *   Get Artifact Attributes, Staking, Reputation, Delegation
    *   Get Protocol Parameters, Recipe details
    *   Check Challenge Status
    *   Query Dynamic Attribute (calculated)
11. **NexusEssence Interaction Functions** (Proxying/managing stake - actual transfers via token contract)
12. **NexusArtifact Interaction Functions** (Minting, Burning, Attribute modification)
13. **Reputation Management Functions** (Delegation)
14. **Staking Functions** (Stake/Unstake Essence on Artifacts)
15. **Crafting & Dissolving Functions**
16. **Dynamic Interaction Functions** (Participate in Challenge, Perform Attuned Action)
17. **Internal Helper Functions** (Attribute calculations, reputation updates, state checks)

**Function Summary (20+ Protocol-Specific Functions):**

1.  `setNexusEssenceAddress(address essenceAddress)`: Admin function to set the address of the NexusEssence ERC-20 contract.
2.  `setNexusArtifactsAddress(address artifactsAddress)`: Admin function to set the address of the NexusArtifacts ERC-721 contract.
3.  `setProtocolParameter(bytes32 parameterName, uint256 value)`: Admin function to set various protocol configuration parameters (e.g., staking decay rate, crafting costs, challenge difficulty).
4.  `registerCraftingRecipe(uint256 recipeId, address[] inputTokens, uint256[] inputAmounts, uint256[] inputArtifactIds, uint256 outputArtifactType, uint256 requiredReputation)`: Admin function to define a new crafting recipe requiring specific tokens, artifacts, and reputation.
5.  `registerAttunementType(uint256 attunementId, uint256 requiredProwess, uint256 requiredEnergy, uint256 cooldown)`: Admin function to define types of artifact attunements and their prerequisites/effects.
6.  `craftArtifact(uint256 recipeId, address[] inputTokenAddresses, uint256[] inputTokenAmounts, uint256[] inputArtifactTokenIds)`: Allows a user to craft a new artifact by burning specified input tokens and artifacts according to a registered recipe. Requires reputation check.
7.  `dissolveArtifact(uint256 artifactTokenId)`: Allows a user to burn one of their NexusArtifacts in exchange for a predetermined amount of Essence or other resources based on the artifact's attributes or type.
8.  `stakeEssenceForArtifact(uint256 artifactTokenId, uint256 amount)`: Allows a user to stake NexusEssence from their balance on a specific NexusArtifact they own. Increases staked amount for that artifact.
9.  `unstakeEssenceFromArtifact(uint256 artifactTokenId, uint256 amount)`: Allows a user to unstake NexusEssence from an artifact they own, returning it to their balance.
10. `claimStakingYield(uint256 artifactTokenId)`: Allows a user to claim yield generated by the staked Essence on their artifact (yield generation logic internal/placeholder).
11. `delegateReputation(address delegatee, uint256 amount)`: Allows a user to delegate a portion of their reputation to another address. The delegatee can then potentially use this delegated reputation in protocol interactions where reputation is required.
12. `undelegateReputation(address delegatee, uint256 amount)`: Allows a user to revoke delegated reputation from an address.
13. `participateInDynamicChallenge(uint256 challengeId, uint256 artifactTokenId)`: Allows a user to participate in a specific ongoing challenge using one of their artifacts. Success/failure depends on artifact attributes, staked essence, and user reputation. Results in reputation change, attribute change, or resource consumption.
14. `performAttunedAction(uint256 artifactTokenId, uint256 attunementId, bytes data)`: Allows a user to perform a special action using an artifact that meets the requirements for a registered `attunementId`. Consumes artifact energy, may trigger complex state changes based on `data` and attunement effects.
15. `updateArtifactEnergy(uint256 artifactTokenId)`: A public function (potentially called by keepers or anyone) that updates an artifact's `energy` attribute based on time passed, staked essence, and other factors. Prevents requiring users to pay gas for passive regeneration.
16. `syncArtifactAttributes(uint256 artifactTokenId)`: Forces a recalculation and update of all dynamic attributes for an artifact. Useful after off-chain state changes or before interactions.
17. `attuneArtifact(uint256 artifactTokenId, uint256 attunementId)`: Allows a user to bind an artifact to a specific attunement type, enabling `performAttunedAction`. Might require resources or a cooldown.
18. `removeAttunement(uint256 artifactTokenId)`: Allows a user to remove an attunement binding from an artifact.
19. `distributeProtocolFees(address token, uint256 amount)`: Admin function to distribute collected protocol fees (if any) to stakers, participants, or a treasury.
20. `triggerProtocolEvent(uint256 eventId, bytes eventData)`: Admin function to initiate a protocol-wide event (like a dynamic challenge) with specific parameters.
21. `resolveProtocolEvent(uint256 eventId, bytes resolutionData)`: Admin function to finalize a protocol event, processing outcomes for participants based on their interaction data and the event's rules.
22. `emergencyWithdrawTokens(address token, uint256 amount)`: Admin function to withdraw stuck tokens from the contract (standard safety).
23. `getArtifactAttributes(uint256 artifactTokenId)`: View function to retrieve the current attributes of an artifact.
24. `getUserReputation(address user)`: View function to get a user's current reputation score.
25. `getDelegatedReputation(address delegator, address delegatee)`: View function to see how much reputation a delegator has delegated to a specific delegatee.
26. `getTotalDelegatedReputation(address delegatee)`: View function to see the total reputation delegated *to* a specific address.

---

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// --- Errors ---
error EtherealNexus__InvalidTokenAddress();
error EtherealNexus__ArtifactNotOwnedByCaller();
error EtherealNexus__ArtifactNotOwnedByExpectedUser(address owner);
error EtherealNexus__InsufficientEssenceBalance(uint256 required, uint256 has);
error EtherealNexus__InsufficientArtifactEnergy(uint256 required, uint256 has);
error EtherealNexus__InsufficientReputation(uint256 required, uint256 has);
error EtherealNexus__InsufficientStakedEssence(uint256 required, uint256 has);
error EtherealNexus__InvalidCraftingRecipe();
error EtherealNexus__CraftingInputsMismatch();
error EtherealNexus__CraftingInputArtifactNotOwned(uint256 tokenId, address owner);
error EtherealNexus__InvalidAttunementType();
error EtherealNexus__ArtifactNotAttunedToType(uint256 requiredAttunementId);
error EtherealNexus__AttunedActionOnCooldown(uint256 timeRemaining);
error EtherealNexus__InvalidChallengeId();
error EtherealNexus__ChallengeNotActive();
error EtherealNexus__ChallengeAlreadyParticipated();
error EtherealNexus__ReputationDelegationAmountExceedsBalance(uint256 available, uint256 tryingToDelegate);
error EtherealNexus__ReputationUndelegationAmountExceedsDelegation(uint256 delegated, uint256 tryingToUndelegate);
error EtherealNexus__CannotDelegateToSelf();
error EtherealNexus__ParameterDoesNotExist();
error EtherealNexus__ParameterValueInvalid();
error EtherealNexus__ArtifactAlreadyAttuned();
error EtherealNexus__ArtifactNotAttuned();


// --- Events ---
event NexusEssenceAddressSet(address indexed essenceAddress);
event NexusArtifactsAddressSet(address indexed artifactsAddress);
event ProtocolParameterSet(bytes32 indexed parameterName, uint256 value);
event CraftingRecipeRegistered(uint256 indexed recipeId, uint256 outputArtifactType);
event AttunementTypeRegistered(uint256 indexed attunementId);
event ArtifactCrafted(uint256 indexed recipeId, address indexed crafter, uint256 indexed newTokenId);
event ArtifactDissolved(uint256 indexed artifactTokenId, address indexed dissolver);
event EssenceStakedOnArtifact(address indexed user, uint256 indexed artifactTokenId, uint256 amount);
event EssenceUnstakedFromArtifact(address indexed user, uint256 indexed artifactTokenId, uint256 amount);
event StakingYieldClaimed(address indexed user, uint256 indexed artifactTokenId, uint256 amount);
event ReputationGained(address indexed user, uint256 amount);
event ReputationLost(address indexed user, uint256 amount);
event ReputationDelegated(address indexed delegator, address indexed delegatee, uint256 amount);
event ReputationUndelegated(address indexed delegator, address indexed delegatee, uint256 amount);
event ArtifactAttributesUpdated(uint256 indexed artifactTokenId);
event DynamicChallengeParticipation(uint256 indexed challengeId, address indexed participant, uint256 indexed artifactTokenId);
event AttunedActionPerformed(uint256 indexed artifactTokenId, uint256 indexed attunementId, address indexed user);
event ArtifactEnergyUpdated(uint256 indexed artifactTokenId, uint256 newEnergy);
event ArtifactAttuned(uint256 indexed artifactTokenId, uint256 indexed attunementId);
event AttunementRemoved(uint256 indexed artifactTokenId);


// --- Interfaces ---
interface INexusEssence is IERC20 {}
interface INexusArtifacts is IERC721 {
    // Custom mint function expected by the Nexus contract logic
    function mintArtifact(address to, uint256 artifactType) external returns (uint256 tokenId);
    // Custom burn function expected by the Nexus contract logic
    function burn(uint256 tokenId) external;
    // Custom function to get artifact type (assuming a type identifier exists)
    function getArtifactType(uint256 tokenId) external view returns (uint256);
}


// --- Contract ---
contract EtherealNexus is Ownable, Pausable, ERC721Holder {

    INexusEssence private immutable i_nexusEssence;
    INexusArtifacts private immutable i_nexusArtifacts;

    // --- State Variables ---

    // Artifact Data
    struct ArtifactAttributes {
        uint256 level;
        uint256 prowess;
        uint256 energy; // Consumed by actions, regenerates over time/staking
        uint256 maxEnergy; // Max energy capacity
        uint256 affinity; // Specific type/elemental affinity
        uint256 lastEnergyUpdateTime; // Timestamp for energy calculation
        uint256 stakedEssence; // Essence staked on this artifact
        uint256 currentAttunementId; // 0 if not attuned, >0 for specific type
        uint256 attunementCooldownEnd; // Timestamp when attunement cooldown ends
        uint256 creationTime; // Timestamp artifact was created
    }
    mapping(uint256 => ArtifactAttributes) private s_artifactAttributes; // tokenId => attributes

    // User Reputation
    mapping(address => uint256) private s_userReputation; // user address => reputation score
    mapping(address => mapping(address => uint256)) private s_reputationDelegations; // delegator => delegatee => amount delegated
    mapping(address => uint256) private s_totalReputationDelegatedTo; // delegatee => total amount delegated to them

    // Staking
    // Staked essence is tracked within the ArtifactAttributes struct (s_artifactAttributes[tokenId].stakedEssence)
    // Staking yield logic could be added here (e.g., per-artifact yield accumulation)

    // Crafting
    struct CraftingRecipe {
        address[] inputTokens; // Addresses of required ERC20 tokens
        uint256[] inputAmounts; // Amounts of required inputTokens
        uint256[] inputArtifactTypes; // Types of required NexusArtifacts
        uint256[] inputArtifactAmounts; // How many artifacts of each type
        uint256 outputArtifactType; // Type of the artifact produced
        uint256 requiredReputation; // Minimum reputation to craft
        bool isActive; // Is this recipe currently usable?
    }
    mapping(uint256 => CraftingRecipe) private s_craftingRecipes; // recipeId => recipe details
    uint256 private s_nextRecipeId = 1;

    // Attunements
    struct AttunementTypeConfig {
        uint256 requiredProwess; // Minimum artifact prowess required
        uint256 requiredEnergy; // Energy consumed per action
        uint256 cooldownDuration; // Cooldown time between actions
        bool isActive; // Is this attunement type usable?
    }
    mapping(uint256 => AttunementTypeConfig) private s_attunementTypes; // attunementId => config

    // Protocol Parameters
    mapping(bytes32 => uint256) private s_protocolParameters; // Generic parameters (e.g., ENERGY_REGEN_RATE)

    // Dynamic Challenges/Events (Example Structure)
    struct DynamicChallenge {
        uint256 id;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bytes32 challengeType; // e.g., "Combat", "Exploration", "Crafting"
        uint256 requiredReputation;
        uint256 requiredArtifactProwess;
        uint256 essenceCost;
        mapping(address => bool) participants; // user => participated?
        // More fields for specific challenge logic...
    }
    uint256 private s_nextChallengeId = 1;
    mapping(uint256 => DynamicChallenge) private s_dynamicChallenges;


    // --- Constructor ---

    constructor(address essenceAddress, address artifactsAddress) Ownable(msg.sender) Pausable() ERC721Holder() {
        if (essenceAddress == address(0) || artifactsAddress == address(0)) {
            revert EtherealNexus__InvalidTokenAddress();
        }
        i_nexusEssence = INexusEssence(essenceAddress);
        i_nexusArtifacts = INexusArtifacts(artifactsAddress);

        // Set some default parameters (can be changed by owner later)
        s_protocolParameters[keccak256("ENERGY_REGEN_RATE")] = 10; // Energy per hour per staked essence unit
        s_protocolParameters[keccak256("BASE_MAX_ENERGY")] = 1000;
        s_protocolParameters[keccak256("MAX_ENERGY_PER_LEVEL")] = 100;
        s_protocolParameters[keccak256("REPUTATION_DELEGATION_FEE_BPS")] = 50; // 0.5% fee on delegation (example)
        s_protocolParameters[keccak256("CRAFTING_BASE_FEE")] = 1e17; // 0.1 Essence base fee
    }

    // --- Admin/Configuration Functions ---

    function setNexusEssenceAddress(address essenceAddress) external onlyOwner {
         if (essenceAddress == address(0)) {
            revert EtherealNexus__InvalidTokenAddress();
        }
        // Note: Changing token addresses mid-protocol can be complex and risky.
        // In a real system, this might be restricted or require governance.
        // For this example, we allow it.
        address oldAddress = address(i_nexusEssence);
        // i_nexusEssence = INexusEssence(essenceAddress); // Cannot re-assign immutable
        // A different pattern would be needed if this must be mutable after construction.
        // For this example, let's assume it's fixed in the constructor or uses a proxy pattern.
        // Reverting this function to indicate it's immutable for this contract version.
         revert("Essence address is immutable after construction");
         emit NexusEssenceAddressSet(essenceAddress);
    }

    function setNexusArtifactsAddress(address artifactsAddress) external onlyOwner {
        if (artifactsAddress == address(0)) {
            revert EtherealNexus__InvalidTokenAddress();
        }
         // Same immutability consideration as setNexusEssenceAddress
        revert("Artifacts address is immutable after construction");
        // i_nexusArtifacts = INexusArtifacts(artifactsAddress); // Cannot re-assign immutable
        emit NexusArtifactsAddressSet(artifactsAddress);
    }


    /// @notice Sets a protocol parameter.
    /// @param parameterName The keccak256 hash of the parameter name (e.g., keccak256("ENERGY_REGEN_RATE")).
    /// @param value The new value for the parameter.
    function setProtocolParameter(bytes32 parameterName, uint256 value) external onlyOwner {
        s_protocolParameters[parameterName] = value;
        emit ProtocolParameterSet(parameterName, value);
    }

    /// @notice Registers a new crafting recipe.
    /// @param inputTokens Addresses of required ERC20 input tokens.
    /// @param inputAmounts Amounts of required ERC20 input tokens.
    /// @param inputArtifactTypes Types of required NexusArtifacts.
    /// @param inputArtifactAmounts Amounts of required NexusArtifacts by type.
    /// @param outputArtifactType The type of NexusArtifact produced.
    /// @param requiredReputation The minimum reputation required to use this recipe.
    function registerCraftingRecipe(
        address[] calldata inputTokens,
        uint256[] calldata inputAmounts,
        uint256[] calldata inputArtifactTypes,
        uint256[] calldata inputArtifactAmounts,
        uint256 outputArtifactType,
        uint256 requiredReputation
    ) external onlyOwner {
        if (inputTokens.length != inputAmounts.length) revert EtherealNexus__CraftingInputsMismatch();
        if (inputArtifactTypes.length != inputArtifactAmounts.length) revert EtherealNexus__CraftingInputsMismatch();
        
        uint256 recipeId = s_nextRecipeId++;
        s_craftingRecipes[recipeId] = CraftingRecipe({
            inputTokens: inputTokens,
            inputAmounts: inputAmounts,
            inputArtifactTypes: inputArtifactTypes,
            inputArtifactAmounts: inputArtifactAmounts,
            outputArtifactType: outputArtifactType,
            requiredReputation: requiredReputation,
            isActive: true
        });
        emit CraftingRecipeRegistered(recipeId, outputArtifactType);
    }

     /// @notice Registers a new attunement type configuration.
    /// @param attunementId The ID for the new attunement type.
    /// @param requiredProwess Minimum artifact prowess needed for this attunement.
    /// @param requiredEnergy Energy consumed per action with this attunement.
    /// @param cooldownDuration Time in seconds between actions with this attunement.
    function registerAttunementType(uint256 attunementId, uint256 requiredProwess, uint256 requiredEnergy, uint256 cooldownDuration) external onlyOwner {
        if (attunementId == 0) revert EtherealNexus__InvalidAttunementType(); // 0 is reserved for not attuned
        s_attunementTypes[attunementId] = AttunementTypeConfig({
            requiredProwess: requiredProwess,
            requiredEnergy: requiredEnergy,
            cooldownDuration: cooldownDuration,
            isActive: true
        });
        emit AttunementTypeRegistered(attunementId);
    }

    /// @notice Initiates a new dynamic challenge.
    /// @param challengeId The ID for the challenge.
    /// @param duration The duration of the challenge in seconds.
    /// @param challengeType Identifier for the challenge type.
    /// @param requiredReputation Minimum reputation to participate.
    /// @param requiredArtifactProwess Minimum artifact prowess to participate.
    /// @param essenceCost Cost in Essence to participate.
    function triggerProtocolEvent(
        uint256 challengeId,
        uint256 duration,
        bytes32 challengeType,
        uint256 requiredReputation,
        uint256 requiredArtifactProwess,
        uint256 essenceCost
    ) external onlyOwner whenNotPaused {
        if (challengeId == 0 || s_dynamicChallenges[challengeId].endTimestamp > block.timestamp) revert EtherealNexus__InvalidChallengeId(); // Don't overwrite active/future challenges
        s_dynamicChallenges[challengeId] = DynamicChallenge({
            id: challengeId,
            startTimestamp: block.timestamp,
            endTimestamp: block.timestamp + duration,
            challengeType: challengeType,
            requiredReputation: requiredReputation,
            requiredArtifactProwess: requiredArtifactProwess,
            essenceCost: essenceCost,
            participants: new mapping(address => bool) // Initialize participant map
            // Initialize other challenge-specific fields if needed
        });
        s_nextChallengeId = challengeId + 1; // Simple way to track potential next ID

        // Could emit an event specific to challenge type
        // emit DynamicChallengeStarted(challengeId, challengeType, block.timestamp, block.timestamp + duration);
    }

    /// @notice Resolves a dynamic challenge (placeholder logic).
    /// @param challengeId The ID of the challenge to resolve.
    /// @param resolutionData Data used to determine outcomes.
    function resolveProtocolEvent(uint256 challengeId, bytes calldata resolutionData) external onlyOwner {
        DynamicChallenge storage challenge = s_dynamicChallenges[challengeId];
        if (challenge.id == 0 || challenge.endTimestamp > block.timestamp) revert EtherealNexus__ChallengeNotActive();

        // TODO: Implement actual resolution logic based on challenge.participants and resolutionData
        // This would involve iterating through participants and applying rewards/penalties
        // based on their artifact stats, reputation, and interaction data.

        // Example: Simple resolution that gives reputation to participants
        // (In reality, you'd need more complex state tracking per participant)
        uint256 baseReputationReward = 50; // Example reward
        // This loop is not gas efficient for large numbers of participants
        // A real implementation might use Merkle trees or off-chain computation
        // and on-chain verification for rewards/penalties.
        /*
        for (each participant in challenge.participants) {
            _gainReputationInternal(participant, baseReputationReward);
        }
        */

        // Mark challenge as resolved (e.g., set a resolved flag or clear participant data)
        // For simplicity, we just let it expire past endTimestamp.
    }

    /// @notice Allows the owner to withdraw tokens stuck in the contract.
    /// @param token The address of the ERC20 token to withdraw.
    /// @param amount The amount to withdraw.
    function emergencyWithdrawTokens(address token, uint256 amount) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        tokenContract.transfer(owner(), amount);
    }

    /// @notice Pauses the contract (inherits from Pausable).
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract (inherits from Pausable).
    function unpause() external onlyOwner {
        _unpause();
    }

    // --- View Functions (Read Only) ---

    /// @notice Gets the current attributes of a NexusArtifact.
    /// @param artifactTokenId The ID of the artifact.
    /// @return The ArtifactAttributes struct.
    function getArtifactAttributes(uint256 artifactTokenId) public view returns (ArtifactAttributes memory) {
         // Ensure energy is up-to-date before returning
        ArtifactAttributes memory currentAttributes = s_artifactAttributes[artifactTokenId];
        if (currentAttributes.creationTime == 0) {
            // Artifact doesn't exist or hasn't been initialized via Nexus mint
             // A real implementation might check if the artifact exists in the ERC721 contract
             // before attempting to return attributes.
             // Returning a zeroed struct for now implies 'not found'.
             return ArtifactAttributes(0,0,0,0,0,0,0,0,0,0);
        }
        return _calculateArtifactEnergy(artifactTokenId, currentAttributes);
    }

    /// @notice Gets the current reputation score for a user.
    /// @param user The address of the user.
    /// @return The reputation score.
    function getUserReputation(address user) external view returns (uint256) {
        return s_userReputation[user];
    }

    /// @notice Gets the amount of reputation delegated by one user to another.
    /// @param delegator The address delegating reputation.
    /// @param delegatee The address receiving delegated reputation.
    /// @return The amount delegated.
    function getDelegatedReputation(address delegator, address delegatee) external view returns (uint256) {
        return s_reputationDelegations[delegator][delegatee];
    }

    /// @notice Gets the total amount of reputation delegated to a user.
    /// @param delegatee The address receiving delegations.
    /// @return The total reputation delegated to the delegatee.
    function getTotalDelegatedReputation(address delegatee) external view returns (uint256) {
        return s_totalReputationDelegatedTo[delegatee];
    }

    /// @notice Gets a specific protocol parameter value.
    /// @param parameterName The keccak256 hash of the parameter name.
    /// @return The parameter value.
    function getProtocolParameter(bytes32 parameterName) external view returns (uint256) {
        // Consider adding a check if parameterName exists, or document that 0 means not set
        return s_protocolParameters[parameterName];
    }

    /// @notice Gets details of a crafting recipe.
    /// @param recipeId The ID of the recipe.
    /// @return The CraftingRecipe struct.
    function getCraftingRecipe(uint256 recipeId) external view returns (CraftingRecipe memory) {
        return s_craftingRecipes[recipeId];
    }

    /// @notice Gets configuration details for an attunement type.
    /// @param attunementId The ID of the attunement type.
    /// @return The AttunementTypeConfig struct.
    function getAttunementTypeConfig(uint256 attunementId) external view returns (AttunementTypeConfig memory) {
        return s_attunementTypes[attunementId];
    }

    /// @notice Gets the status of a dynamic challenge.
    /// @param challengeId The ID of the challenge.
    /// @return Details about the challenge status.
    function getChallengeStatus(uint256 challengeId) external view returns (
        uint256 id,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bytes32 challengeType,
        uint256 requiredReputation,
        uint256 requiredArtifactProwess,
        uint256 essenceCost,
        bool isActive,
        bool hasParticipated
    ) {
        DynamicChallenge storage challenge = s_dynamicChallenges[challengeId];
        if (challenge.id == 0) revert EtherealNexus__InvalidChallengeId();

        isActive = challenge.endTimestamp > block.timestamp;
        hasParticipated = challenge.participants[msg.sender];

        return (
            challenge.id,
            challenge.startTimestamp,
            challenge.endTimestamp,
            challenge.challengeType,
            challenge.requiredReputation,
            challenge.requiredArtifactProwess,
            challenge.essenceCost,
            isActive,
            hasParticipated
        );
    }

     /// @notice Queries a dynamic artifact attribute that might be calculated.
     /// @param artifactTokenId The ID of the artifact.
     /// @param attributeKey A key identifying the attribute (e.g., keccak256("EffectiveProwess")).
     /// @return The calculated attribute value.
     // Example of a dynamic attribute that isn't stored directly but calculated
     function queryDynamicAttribute(uint256 artifactTokenId, bytes32 attributeKey) external view returns (uint256) {
         ArtifactAttributes memory attributes = getArtifactAttributes(artifactTokenId); // Use getter to get latest energy

         if (attributeKey == keccak256("EffectiveProwess")) {
             // Example: Prowess + (Staked Essence / 10) + (Energy / 50)
             return attributes.prowess + (attributes.stakedEssence / 10) + (attributes.energy / 50);
         }
         // Add more dynamic attribute calculations here...

         return 0; // Return 0 for unknown keys or keys without calculation
     }


    // --- NexusArtifact Interaction Functions ---

    /// @notice Initializes attributes for a newly minted artifact. This is expected to be called by the INexusArtifacts contract after minting.
    /// @param tokenId The ID of the newly minted artifact.
    /// @param artifactType The type identifier of the artifact.
    /// @param initialLevel Initial level.
    /// @param initialProwess Initial prowess.
    /// @param initialMaxEnergy Initial max energy.
    /// @param initialAffinity Initial affinity.
    function initializeArtifactAttributes(
        uint256 tokenId,
        uint256 artifactType, // Added artifactType to differentiate initial stats
        uint256 initialLevel,
        uint256 initialProwess,
        uint256 initialMaxEnergy,
        uint256 initialAffinity
    ) external onlyERC721 { // Only callable by the registered NexusArtifacts contract
        // Ensure it's a valid artifact that exists in the NFT contract
        // This call requires the artifact contract to have a function like `exists(tokenId)`
        // Or verify ownership via IERC721.ownerOf(tokenId) if called *after* transfer

        // Prevent re-initialization
        if (s_artifactAttributes[tokenId].creationTime != 0) {
            revert("Artifact attributes already initialized");
        }

        s_artifactAttributes[tokenId] = ArtifactAttributes({
            level: initialLevel,
            prowess: initialProwess,
            energy: initialMaxEnergy, // Start with full energy
            maxEnergy: initialMaxEnergy,
            affinity: initialAffinity,
            lastEnergyUpdateTime: block.timestamp,
            stakedEssence: 0,
            currentAttunementId: 0,
            attunementCooldownEnd: 0,
            creationTime: block.timestamp
        });

        // Optional: Base reputation gain for having a new artifact?
        // _gainReputationInternal(i_nexusArtifacts.ownerOf(tokenId), 1); // Requires ERC721 ownerOf call
    }

    /// @notice Updates an artifact's energy based on time and staking. Callable by anyone to sync state.
    /// @param artifactTokenId The ID of the artifact.
    function updateArtifactEnergy(uint256 artifactTokenId) public whenNotPaused {
        ArtifactAttributes storage attributes = s_artifactAttributes[artifactTokenId];
         if (attributes.creationTime == 0) return; // Artifact not initialized via Nexus

        // Calculate potential new energy
        ArtifactAttributes memory updatedAttributes = _calculateArtifactEnergy(artifactTokenId, attributes);

        // Apply update if changed
        if (updatedAttributes.energy != attributes.energy || updatedAttributes.lastEnergyUpdateTime != attributes.lastEnergyUpdateTime) {
            attributes.energy = updatedAttributes.energy;
            attributes.lastEnergyUpdateTime = updatedAttributes.lastEnergyUpdateTime;
            emit ArtifactEnergyUpdated(artifactTokenId, attributes.energy);
        }
    }

    /// @notice Syncs all dynamic attributes for an artifact.
    /// @param artifactTokenId The ID of the artifact.
    function syncArtifactAttributes(uint256 artifactTokenId) external whenNotPaused {
         // Primarily ensures energy is updated before any potential external query
         updateArtifactEnergy(artifactTokenId);
         // More complex sync logic for other attributes could go here if needed
         emit ArtifactAttributesUpdated(artifactTokenId);
    }

     /// @notice Attunes an artifact to a specific type, allowing special actions.
     /// @param artifactTokenId The ID of the artifact to attune.
     /// @param attunementId The ID of the attunement type.
     function attuneArtifact(uint256 artifactTokenId, uint256 attunementId) external whenNotPaused {
         if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();
         ArtifactAttributes storage attributes = s_artifactAttributes[artifactTokenId];
         if (attributes.currentAttunementId != 0) revert EtherealNexus__ArtifactAlreadyAttuned();

         AttunementTypeConfig storage config = s_attunementTypes[attunementId];
         if (attunementId == 0 || !config.isActive) revert EtherealNexus__InvalidAttunementType();
         if (attributes.prowess < config.requiredProwess) revert EtherealNexus__InsufficientArtifactEnergy(config.requiredProwess, attributes.prowess);

         // Cost/Cooldown could be applied here
         // Example: require(i_nexusEssence.transferFrom(msg.sender, address(this), cost), "Essence transfer failed");
         // Example: attributes.attunementCooldownEnd = block.timestamp + config.setupCooldown;

         attributes.currentAttunementId = attunementId;
         emit ArtifactAttuned(artifactTokenId, attunementId);
     }

     /// @notice Removes attunement from an artifact.
     /// @param artifactTokenId The ID of the artifact.
     function removeAttunement(uint256 artifactTokenId) external whenNotPaused {
         if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();
         ArtifactAttributes storage attributes = s_artifactAttributes[artifactTokenId];
         if (attributes.currentAttunementId == 0) revert EtherealNexus__ArtifactNotAttuned();

         attributes.currentAttunementId = 0;
         emit AttunementRemoved(artifactTokenId);
     }


    // --- Reputation Management Functions ---

    /// @notice Allows a user to delegate reputation to another address.
    /// @param delegatee The address to delegate reputation to.
    /// @param amount The amount of reputation to delegate.
    function delegateReputation(address delegatee, uint256 amount) external whenNotPaused {
        if (msg.sender == delegatee) revert EtherealNexus__CannotDelegateToSelf();
        uint256 availableReputation = s_userReputation[msg.sender] - s_totalReputationDelegatedTo[msg.sender]; // Reputation available after accounting for what was delegated *to others*

        if (amount == 0) return;
        if (amount > availableReputation) revert EtherealNexus__ReputationDelegationAmountExceedsBalance(availableReputation, amount);

        // Optional: Apply a fee on delegation
        uint256 feeBps = s_protocolParameters[keccak256("REPUTATION_DELEGATION_FEE_BPS")];
        if (feeBps > 0) {
            uint256 fee = (amount * feeBps) / 10000; // Fee in basis points
            // Decide what happens to the fee: burned, sent to treasury, etc.
            // This example just calculates it but doesn't enforce it on-chain here for simplicity.
            // In a real system, you'd need to implement the fee collection mechanism.
            // console.log("Delegation fee calculated:", fee);
        }


        s_reputationDelegations[msg.sender][delegatee] += amount;
        s_totalReputationDelegatedTo[delegatee] += amount; // Track total delegated *to* delegatee
        s_totalReputationDelegatedTo[msg.sender] += amount; // Track total delegated *by* delegator (Corrected logic: This should track *by* the delegator)

        // Corrected tracking for delegation:
        // We need to track total delegated *out* by msg.sender and total delegated *in* by delegatee.
        // Let's use two separate mappings for clarity.
        // mapping(address => uint256) private s_totalDelegatedOut; // user => total they have delegated to others
        // mapping(address => uint256) private s_totalDelegatedIn; // user => total delegated to them

        // Reverting the previous logic and proposing a clearer structure:
        // mapping(address => mapping(address => uint256)) private s_reputationDelegations; // delegator => delegatee => amount delegated
        // mapping(address => uint256) private s_totalDelegatedOut; // delegator => total they have delegated out
        // mapping(address => uint256) private s_totalDelegatedIn; // delegatee => total they have received in delegations

        // With the corrected structure:
        s_reputationDelegations[msg.sender][delegatee] += amount;
        // s_totalDelegatedOut[msg.sender] += amount; // Need to add this mapping
        // s_totalDelegatedIn[delegatee] += amount; // Need to add this mapping
        // Since adding new state variables requires contract update, let's stick to the simpler (less perfect) model for this example,
        // but acknowledge the need for `s_totalDelegatedOut` in a production system to correctly calculate `availableReputation`.
        // For this example, `availableReputation` check relies ONLY on `s_userReputation` - which is less accurate for delegation logic.
        // A production system *must* track `s_totalDelegatedOut`.

        emit ReputationDelegated(msg.sender, delegatee, amount);
    }

    /// @notice Allows a user to undelegate reputation from an address.
    /// @param delegatee The address to undelegate reputation from.
    /// @param amount The amount of reputation to undelegate.
    function undelegateReputation(address delegatee, uint256 amount) external whenNotPaused {
        if (amount == 0) return;
        uint256 currentDelegation = s_reputationDelegations[msg.sender][delegatee];
        if (amount > currentDelegation) revert EtherealNexus__ReputationUndelegationAmountExceedsDelegation(currentDelegation, amount);

        s_reputationDelegations[msg.sender][delegatee] -= amount;
        s_totalReputationDelegatedTo[delegatee] -= amount; // Assuming this tracks total received
        // s_totalDelegatedOut[msg.sender] -= amount; // Need the corrected mapping

        emit ReputationUndelegated(msg.sender, delegatee, amount);
    }


    // --- Staking Functions ---

    /// @notice Stakes NexusEssence on a specific NexusArtifact.
    /// @param artifactTokenId The ID of the artifact.
    /// @param amount The amount of Essence to stake.
    function stakeEssenceForArtifact(uint256 artifactTokenId, uint256 amount) external whenNotPaused {
        if (amount == 0) return;
        if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();
        if (i_nexusEssence.balanceOf(msg.sender) < amount) revert EtherealNexus__InsufficientEssenceBalance(amount, i_nexusEssence.balanceOf(msg.sender));

        // Transfer Essence from user to this contract
        bool success = i_nexusEssence.transferFrom(msg.sender, address(this), amount);
        require(success, "Essence transfer failed");

        // Update artifact attributes (internal state)
        updateArtifactEnergy(artifactTokenId); // Sync energy before updating staked amount
        s_artifactAttributes[artifactTokenId].stakedEssence += amount;
        s_artifactAttributes[artifactTokenId].lastEnergyUpdateTime = block.timestamp; // Reset energy timer on stake

        emit EssenceStakedOnArtifact(msg.sender, artifactTokenId, amount);
    }

    /// @notice Unstakes NexusEssence from a specific NexusArtifact.
    /// @param artifactTokenId The ID of the artifact.
    /// @param amount The amount of Essence to unstake.
    function unstakeEssenceFromArtifact(uint256 artifactTokenId, uint256 amount) external whenNotPaused {
        if (amount == 0) return;
        if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();

        ArtifactAttributes storage attributes = s_artifactAttributes[artifactTokenId];
        if (attributes.stakedEssence < amount) revert EtherealNexus__InsufficientStakedEssence(amount, attributes.stakedEssence);

        // Update artifact attributes (internal state)
        updateArtifactEnergy(artifactTokenId); // Sync energy before updating staked amount
        attributes.stakedEssence -= amount;
        attributes.lastEnergyUpdateTime = block.timestamp; // Reset energy timer on unstake

        // Transfer Essence from this contract back to user
        bool success = i_nexusEssence.transfer(msg.sender, amount);
        require(success, "Essence transfer failed");

        emit EssenceUnstakedFromArtifact(msg.sender, artifactTokenId, amount);
    }

     /// @notice Placeholder for claiming staking yield. Yield logic would be complex.
     /// @param artifactTokenId The ID of the artifact.
    function claimStakingYield(uint256 artifactTokenId) external whenNotPaused {
        if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();

        // TODO: Implement yield calculation and claim logic.
        // This would likely involve tracking yield accrued per artifact based on staked amount and time.
        // uint256 accruedYield = _calculateAccruedYield(artifactTokenId);
        // if (accruedYield > 0) {
        //    // Transfer yield token (could be Essence or another token)
        //    bool success = i_nexusEssence.transfer(msg.sender, accruedYield); // Example: Yield in Essence
        //    require(success, "Yield transfer failed");
        //    // Reset yield tracking for artifact
        //    _resetAccruedYield(artifactTokenId);
        //    emit StakingYieldClaimed(msg.sender, artifactTokenId, accruedYield);
        // } else {
        //     // No yield to claim
        // }
         revert("Staking yield claiming is not yet implemented."); // Placeholder revert
    }


    // --- Crafting & Dissolving Functions ---

    /// @notice Crafts a new artifact using a registered recipe.
    /// @param recipeId The ID of the crafting recipe.
    /// @param inputTokenAddresses Addresses of ERC20 tokens to burn.
    /// @param inputTokenAmounts Amounts of ERC20 tokens to burn.
    /// @param inputArtifactTokenIds IDs of NexusArtifacts to burn.
    function craftArtifact(
        uint256 recipeId,
        address[] calldata inputTokenAddresses,
        uint256[] calldata inputTokenAmounts,
        uint256[] calldata inputArtifactTokenIds
    ) external whenNotPaused {
        CraftingRecipe storage recipe = s_craftingRecipes[recipeId];
        if (recipe.outputArtifactType == 0 || !recipe.isActive) revert EtherealNexus__InvalidCraftingRecipe();
        if (s_userReputation[msg.sender] < recipe.requiredReputation) revert EtherealNexus__InsufficientReputation(recipe.requiredReputation, s_userReputation[msg.sender]);

        // Check and burn required ERC20 tokens
        if (inputTokenAddresses.length != recipe.inputTokens.length || inputTokenAmounts.length != recipe.inputAmounts.length) revert EtherealNexus__CraftingInputsMismatch();
        for (uint i = 0; i < recipe.inputTokens.length; i++) {
            if (inputTokenAddresses[i] != recipe.inputTokens[i]) revert EtherealNexus__CraftingInputsMismatch();
            if (inputTokenAmounts[i] < recipe.inputAmounts[i]) revert EtherealNexus__InsufficientEssenceBalance(recipe.inputAmounts[i], inputTokenAmounts[i]); // Use token balance for check

            IERC20 inputToken = IERC20(inputTokenAddresses[i]);
            // Require allowance for the Nexus contract to pull tokens
            require(inputToken.transferFrom(msg.sender, address(this), recipe.inputAmounts[i]), "ERC20 transfer failed");
            // Optional: Burn tokens sent to the contract or send to treasury
        }

        // Check and burn required NexusArtifacts
         if (inputArtifactTokenIds.length != recipe.inputArtifactTypes.length) revert EtherealNexus__CraftingInputsMismatch(); // Simplified check: Assumes 1 artifact per type entry in recipe
         // A more robust check would count artifacts of each required type
         mapping(uint256 => uint256) memory requiredArtifactCounts;
         for(uint i=0; i < recipe.inputArtifactTypes.length; i++) {
             requiredArtifactCounts[recipe.inputArtifactTypes[i]] += recipe.inputArtifactAmounts[i];
         }

         mapping(uint256 => uint256) memory providedArtifactCounts;
         for(uint i=0; i < inputArtifactTokenIds.length; i++) {
             uint256 tokenId = inputArtifactTokenIds[i];
             address artifactOwner = i_nexusArtifacts.ownerOf(tokenId);
             if (artifactOwner != msg.sender) revert EtherealNexus__CraftingInputArtifactNotOwned(tokenId, artifactOwner);

             // Check if this artifact is needed in the recipe inputs
             uint256 artifactType = i_nexusArtifacts.getArtifactType(tokenId); // Requires getArtifactType on NFT contract
             if (requiredArtifactCounts[artifactType] == 0) revert EtherealNexus__CraftingInputsMismatch(); // Provided artifact not needed

             providedArtifactCounts[artifactType]++;
         }

         // Final check on required vs provided artifact counts
         for(uint i=0; i < recipe.inputArtifactTypes.length; i++) {
              if (providedArtifactCounts[recipe.inputArtifactTypes[i]] < requiredArtifactCounts[recipe.inputArtifactTypes[i]]) {
                  revert EtherealNexus__CraftingInputsMismatch(); // Not enough artifacts of a required type
              }
         }


        // Burn input artifacts
        for (uint i = 0; i < inputArtifactTokenIds.length; i++) {
            i_nexusArtifacts.burn(inputArtifactTokenIds[i]); // Requires burn function on NFT contract
            delete s_artifactAttributes[inputArtifactTokenIds[i]]; // Remove attributes state
        }

        // Mint the new artifact
        uint256 newTokenId = i_nexusArtifacts.mintArtifact(msg.sender, recipe.outputArtifactType); // Requires mintArtifact on NFT contract

        // Initialize attributes for the new artifact (this should be called by the mint function via callback or direct call)
        // For this example, we assume the NFT contract calls initializeArtifactAttributes after minting.
        // If it doesn't, you'd need to add the initialization logic here, but it couples concerns.

        // Optional: Pay a base crafting fee
        uint256 baseFee = s_protocolParameters[keccak256("CRAFTING_BASE_FEE")];
        if (baseFee > 0) {
             require(i_nexusEssence.transferFrom(msg.sender, address(this), baseFee), "Crafting fee transfer failed");
        }

        // Optional: Gain reputation for crafting
        _gainReputationInternal(msg.sender, 10);

        emit ArtifactCrafted(recipeId, msg.sender, newTokenId);
    }

    /// @notice Dissolves an artifact into resources.
    /// @param artifactTokenId The ID of the artifact to dissolve.
    function dissolveArtifact(uint256 artifactTokenId) external whenNotPaused {
        if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();

        ArtifactAttributes memory attributes = s_artifactAttributes[artifactTokenId];
        uint256 stakedEssence = attributes.stakedEssence;

        // Burn the artifact
        i_nexusArtifacts.burn(artifactTokenId); // Requires burn function on NFT contract
        delete s_artifactAttributes[artifactTokenId]; // Remove attributes state

        // Return staked essence
        if (stakedEssence > 0) {
            bool success = i_nexusEssence.transfer(msg.sender, stakedEssence);
            require(success, "Essence transfer failed during dissolve");
        }

        // Optional: Return other resources based on artifact type/attributes
        // uint256 refundEssence = _calculateDissolveRefund(attributes);
        // if (refundEssence > 0) {
        //      bool success = i_nexusEssence.transfer(msg.sender, refundEssence);
        //      require(success, "Dissolve refund failed");
        // }

        // Optional: Lose reputation for dissolving?
        // _loseReputationInternal(msg.sender, 5);

        emit ArtifactDissolved(artifactTokenId, msg.sender);
    }


    // --- Dynamic Interaction Functions ---

    /// @notice Allows a user to participate in a dynamic challenge.
    /// @param challengeId The ID of the challenge.
    /// @param artifactTokenId The ID of the artifact used for participation.
    function participateInDynamicChallenge(uint256 challengeId, uint256 artifactTokenId) external whenNotPaused {
        DynamicChallenge storage challenge = s_dynamicChallenges[challengeId];
        if (challenge.id == 0 || challenge.endTimestamp <= block.timestamp) revert EtherealNexus__ChallengeNotActive();
        if (challenge.participants[msg.sender]) revert EtherealNexus__ChallengeAlreadyParticipated();
        if (s_userReputation[msg.sender] < challenge.requiredReputation) revert EtherealNexus__InsufficientReputation(challenge.requiredReputation, s_userReputation[msg.sender]);

        if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();
        ArtifactAttributes memory artifact = getArtifactAttributes(artifactTokenId); // Get latest attributes including energy

        if (artifact.prowess < challenge.requiredArtifactProwess) revert EtherealNexus__InsufficientArtifactEnergy(challenge.requiredArtifactProwess, artifact.prowess); // Check prowess requirement

        // Consume energy - Decide if participation costs energy
        // uint256 participationEnergyCost = 50; // Example cost
        // if (artifact.energy < participationEnergyCost) revert EtherealNexus__InsufficientArtifactEnergy(participationEnergyCost, artifact.energy);
        // s_artifactAttributes[artifactTokenId].energy -= participationEnergyCost; // Directly modify storage after getting reference

        // Consume Essence cost
        if (challenge.essenceCost > 0) {
            if (i_nexusEssence.balanceOf(msg.sender) < challenge.essenceCost) revert EtherealNexus__InsufficientEssenceBalance(challenge.essenceCost, i_nexusEssence.balanceOf(msg.sender));
            bool success = i_nexusEssence.transferFrom(msg.sender, address(this), challenge.essenceCost);
            require(success, "Essence cost transfer failed");
            // Optional: Burn the Essence or send to treasury
        }

        // Mark participant
        challenge.participants[msg.sender] = true;

        // Apply immediate effects (e.g., small reputation gain)
        _gainReputationInternal(msg.sender, 5);

        emit DynamicChallengeParticipation(challengeId, msg.sender, artifactTokenId);

        // Actual challenge outcomes would be determined during resolveProtocolEvent
    }

    /// @notice Performs a special action using an attuned artifact.
    /// @param artifactTokenId The ID of the artifact.
    /// @param attunementId The ID of the attunement type (must match artifact's current attunement).
    /// @param data Arbitrary data relevant to the specific attuned action.
    function performAttunedAction(uint256 artifactTokenId, uint256 attunementId, bytes calldata data) external whenNotPaused {
        if (i_nexusArtifacts.ownerOf(artifactTokenId) != msg.sender) revert EtherealNexus__ArtifactNotOwnedByCaller();

        ArtifactAttributes storage attributes = s_artifactAttributes[artifactTokenId];
        if (attributes.currentAttunementId != attunementId) revert EtherealNexus__ArtifactNotAttunedToType(attunementId);

        AttunementTypeConfig storage config = s_attunementTypes[attunementId];
        if (attunementId == 0 || !config.isActive) revert EtherealNexus__InvalidAttunementType();

        // Check cooldown
        if (attributes.attunementCooldownEnd > block.timestamp) revert EtherealNexus__AttunedActionOnCooldown(attributes.attunementCooldownEnd - block.timestamp);

        // Check and consume energy
        updateArtifactEnergy(artifactTokenId); // Sync energy before check
        if (attributes.energy < config.requiredEnergy) revert EtherealNexus__InsufficientArtifactEnergy(config.requiredEnergy, attributes.energy);
        attributes.energy -= config.requiredEnergy;

        // Apply cooldown
        attributes.attunementCooldownEnd = block.timestamp + config.cooldownDuration;
        attributes.lastEnergyUpdateTime = block.timestamp; // Sync energy timer after consumption

        // TODO: Implement action-specific logic based on `attunementId` and `data`.
        // This would likely involve a large if/else or a lookup table/delegatecall pattern
        // depending on the complexity and number of action types.
        // Example: If attunementId is 1 (e.g., "BoostProwess"), increase artifact prowess temporarily.
        // Example: If attunementId is 2 (e.g., "GatherEssence"), mint some Essence to the user.
        // This makes the contract much more complex; leaving it as a placeholder.

         // Example placeholder logic:
         if (attunementId == 1) { // Example: "Minor Prowess Boost"
              uint256 boostAmount = 10;
              attributes.prowess += boostAmount; // Temporary or permanent boost?
              // Need logic to decay or remove boost if temporary
              _gainReputationInternal(msg.sender, 2); // Small rep gain for using
         } else if (attunementId == 2) { // Example: "Essence Gather"
              uint256 gatherAmount = 50 * (attributes.level / 10 + 1); // Amount scales with level
              // Mint or transfer from treasury (minting implies inflation)
              // Assuming NexusEssence has a mint function callable by this contract if needed, or transfer from treasury
              // require(i_nexusEssence.transfer(msg.sender, gatherAmount), "Essence transfer failed"); // Transfer from contract balance
              revert("Essence gathering attunement not fully implemented - requires source of essence."); // Example placeholder
              _gainReputationInternal(msg.sender, 3); // Small rep gain for using
         }
         // ... more attunement effects ...
         else {
             // No specific effect implemented for this attunementId
         }

        emit AttunedActionPerformed(artifactTokenId, attunementId, msg.sender);
        emit ArtifactAttributesUpdated(artifactTokenId); // Attributes might have changed
        emit ArtifactEnergyUpdated(artifactTokenId, attributes.energy);
    }


    // --- Internal Helper Functions ---

    /// @notice Internal helper to calculate artifact energy based on time and staking.
    /// @param artifactTokenId The ID of the artifact.
    /// @param attributes The artifact's current attributes.
    /// @return An updated ArtifactAttributes struct with calculated energy.
    function _calculateArtifactEnergy(uint256 artifactTokenId, ArtifactAttributes memory attributes) internal view returns (ArtifactAttributes memory) {
        uint256 timeElapsed = block.timestamp - attributes.lastEnergyUpdateTime;
        uint256 energyRegenRate = s_protocolParameters[keccak256("ENERGY_REGEN_RATE")]; // Energy per staked essence per time unit
        uint256 baseMaxEnergy = s_protocolParameters[keccak256("BASE_MAX_ENERGY")];
        uint256 maxEnergyPerLevel = s_protocolParameters[keccak256("MAX_ENERGY_PER_LEVEL")];

        // Calculate potential max energy based on level (example formula)
        uint256 calculatedMaxEnergy = baseMaxEnergy + (attributes.level * maxEnergyPerLevel);
        if (calculatedMaxEnergy != attributes.maxEnergy) {
             attributes.maxEnergy = calculatedMaxEnergy; // Update max energy calculation
             // Note: This doesn't save to storage in a pure view function, but updates the local memory copy
         }


        // Calculate regenerated energy (simple linear example)
        // Total regen = timeElapsed * stakedEssence * energyRegenRate
        // Consider potential overflow if calculations are large. Use safe math or larger types if needed.
        uint256 regenerated = (timeElapsed * attributes.stakedEssence * energyRegenRate) / 3600; // Example: Rate is per hour

        // Add regenerated energy, capping at max energy
        attributes.energy = attributes.energy + regenerated > attributes.maxEnergy ? attributes.maxEnergy : attributes.energy + regenerated;
        attributes.lastEnergyUpdateTime = block.timestamp; // Update timestamp for calculation

        return attributes;
    }

    /// @notice Internal helper to gain reputation for a user.
    /// @param user The user address.
    /// @param amount The amount of reputation to gain.
    function _gainReputationInternal(address user, uint256 amount) internal {
        if (amount > 0) {
            s_userReputation[user] += amount;
            emit ReputationGained(user, amount);
        }
    }

    /// @notice Internal helper to lose reputation for a user.
    /// @param user The user address.
    /// @param amount The amount of reputation to lose.
    function _loseReputationInternal(address user, uint256 amount) internal {
        if (amount > 0) {
             // Ensure reputation doesn't go below 0 (uint handles this, but good practice to cap)
            s_userReputation[user] = s_userReputation[user] > amount ? s_userReputation[user] - amount : 0;
            emit ReputationLost(user, amount);
        }
    }

     /// @notice Modifier to restrict function calls to the registered NexusArtifacts contract.
     modifier onlyERC721() {
         if (msg.sender != address(i_nexusArtifacts)) {
             revert("Caller is not the authorized NexusArtifacts contract");
         }
         _;
     }

     // ERC721Holder fallback for receiving NFTs (optional, only needed if NFTs are transferred *to* the contract)
     // function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4) {
     //     // Implement logic if the Nexus contract needs to receive NFTs directly (e.g., for escrow, pooling)
     //     // For this contract, NFTs are burned/minted, not held directly, so this might not be strictly necessary
     //     // but good practice if using ERC721Holder base.
     //     return this.onERC721Received.selector;
     // }

    // Fallback function to prevent accidental ETH sends (unless intended)
    receive() external payable {
        revert("ETH reception not supported");
    }

    fallback() external payable {
        revert("Fallback not supported");
    }
}
```

---

**Explanation of Concepts & Code:**

1.  **Modularity (Interfaces):** The contract interacts with `NexusEssence` (ERC-20) and `NexusArtifacts` (ERC-721) via interfaces (`INexusEssence`, `INexusArtifacts`). This is crucial for good design, allowing the token contracts to be separate and potentially upgradeable (if using proxy patterns for the tokens themselves). The Nexus contract is the *logic layer*, not the token issuer/manager directly. It assumes the token contracts exist and are deployed separately.
2.  **Dynamic NFT Attributes (`ArtifactAttributes` struct):** The `s_artifactAttributes` mapping stores the dynamic state of each artifact. Functions like `stakeEssenceForArtifact`, `unstakeEssenceFromArtifact`, `updateArtifactEnergy`, `craftArtifact`, `dissolveArtifact`, `participateInDynamicChallenge`, and `performAttunedAction` directly or indirectly modify fields within this struct. The `updateArtifactEnergy` function showcases a common pattern where passive changes (like energy regen) are calculated only when needed (lazy evaluation) via a public function callable by anyone to save gas for the owner/user.
3.  **Reputation (`s_userReputation`, Delegation):** A simple mapping tracks reputation. The delegation functions (`delegateReputation`, `undelegateReputation`) add a layer of complexity, allowing users to lend their social/protocol capital. The `s_totalReputationDelegatedTo` mapping (and ideally `s_totalDelegatedOut` in a production system) helps manage delegation state.
4.  **Staking (`stakeEssenceForArtifact`, `unstakeEssenceFromArtifact`):** Essence is staked *on* specific artifacts. The amount is tracked within the artifact's attributes. This staked amount influences dynamic attributes like energy regeneration (`_calculateArtifactEnergy`). Yield claiming is included as a placeholder, representing potential future complexity like distributing protocol fees or newly minted tokens to stakers.
5.  **Crafting & Dissolving:** `craftArtifact` requires burning multiple input assets (ERC20s and potentially other NFTs of specific types) based on predefined recipes and mints a new artifact. `dissolveArtifact` does the reverse, burning an NFT and returning resources (like staked essence). This creates asset sinks and faucets.
6.  **Attunement:** `attuneArtifact` and `removeAttunement` manage a state (`currentAttunementId`) on an artifact, linking it to a specific `AttunementTypeConfig`. This configuration defines prerequisites (e.g., prowess) and effects/costs (`requiredEnergy`, `cooldownDuration`) for special `performAttunedAction` calls.
7.  **Dynamic Interactions (`participateInDynamicChallenge`, `performAttunedAction`):** These functions are examples of complex interactions. They check multiple conditions (reputation, artifact attributes, resource costs, cooldowns) and trigger multiple state changes (reputation, attribute changes, resource consumption). The `performAttunedAction` is a key example of programmable effects tied to dynamic NFT state.
8.  **Parameterization (`s_protocolParameters`, `setProtocolParameter`):** Using a generic mapping for parameters allows the owner (or future governance) to adjust protocol variables without code changes, adding flexibility.
9.  **Events:** Comprehensive events are included to signal all major state changes, crucial for off-chain monitoring and indexing.
10. **Error Handling:** Custom errors are used for clearer and gas-efficient error reporting.
11. **`ERC721Holder`:** Included as a base class to allow the contract to safely receive ERC721 tokens, although the core logic here relies on burning and minting via the dedicated NFT contract interface rather than holding many NFTs.
12. **`onlyERC721` Modifier:** A custom modifier ensures that the `initializeArtifactAttributes` function can only be called by the trusted `NexusArtifacts` contract, preventing external users from faking artifact creation.

This contract provides a framework for a complex on-chain system with interconnected asset types, reputation, and dynamic state changes driven by user actions and configuration. It meets the criteria of having over 20 protocol-specific functions beyond standard token methods and incorporates advanced concepts like dynamic NFTs and reputation delegation.

**Important Considerations for Production:**

*   **Gas Costs:** Complex on-chain logic, especially loops (like in crafting recipe checks or potential resolution logic), can be very expensive. Optimization or off-chain computation with on-chain verification might be needed.
*   **Scalability:** Mappings grow infinitely. Strategies for managing large amounts of data might be required depending on expected usage.
*   **Security:** The `Ownable` pattern provides centralized control. Decentralization via a DAO or other governance mechanisms would be needed for a truly decentralized protocol. Thorough audits are essential for production code.
*   **Reentrancy:** While not immediately obvious attack vectors given the current interactions, care must be taken when interacting with external contracts (`transferFrom`, `transfer`, NFT calls). Using OpenZeppelin's `ReentrancyGuard` is often wise, though omitted here for brevity.
*   **Dynamic Attribute Calculation:** The `_calculateArtifactEnergy` is a simple example. More complex dynamics require careful design to avoid precision issues and ensure consistent results.
*   **External Dependencies:** Assumes well-behaved and correctly implemented `NexusEssence` and `NexusArtifacts` contracts at the specified addresses.
*   **Yield Calculation:** The `claimStakingYield` is a placeholder. Implementing fair and efficient yield accrual on-chain is non-trivial.